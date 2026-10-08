extends SceneTree
## Base de los generadores de mapas (build_city.gd, build_interiors.gd).
## Arma un Location con capas de tiles, jugador, puertas y puntos de entrada, y lo guarda como .tscn.

const FULL := [Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]
const BASE := [Vector2(-6, 0), Vector2(6, 0), Vector2(6, 8), Vector2(-6, 8)]
const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const MOOD_SCENE := "res://scenes/ui/MoodFilter.tscn"
const FONT := "res://assets/fonts/PressStart2P.ttf"

## Raíz de la escena que se está armando.
var scene_root: Node2D
var _shadow_rects: Array[Rect2] = []
var _shadow_ellipses: Array[Rect2] = []
## Generador de azar con semilla fija: el mapa sale igual cada vez que se regenera.
var rng := RandomNumberGenerator.new()


# ---------------------------------------------------------------- TileSet

func new_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer()
	return ts


## Agrega una hoja de tiles (todas las celdas) como fuente `id`.
func add_sheet(ts: TileSet, sheet: String, id: int) -> TileSetAtlasSource:
	var src := TileSetAtlasSource.new()
	src.texture = load(sheet)
	src.texture_region_size = Vector2i(16, 16)
	ts.add_source(src, id)
	var grid := src.get_atlas_grid_size()
	for y in grid.y:
		for x in grid.x:
			src.create_tile(Vector2i(x, y))
	return src


func set_collision(src: TileSetAtlasSource, coords: Vector2i, poly: Array) -> void:
	var td := src.get_tile_data(coords, 0)
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array(poly))


# ---------------------------------------------------------------- Pintar

func fill(layer: TileMapLayer, r: Rect2i, tile: Vector2i, source := 0) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			layer.set_cell(Vector2i(x, y), source, tile)


## Rellena un rectángulo usando un bloque 3x3 de la hoja (bordes + centro).
func nine(layer: TileMapLayer, r: Rect2i, origin: Vector2i, source := 0) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var cx := 0 if x == r.position.x else (2 if x == r.end.x - 1 else 1)
			var cy := 0 if y == r.position.y else (2 if y == r.end.y - 1 else 1)
			layer.set_cell(Vector2i(x, y), source, origin + Vector2i(cx, cy))


## Fila con pieza de inicio, del medio (repetida) y final.
func row(layer: TileMapLayer, from: Vector2i, length: int, parts: Array, source := 0) -> void:
	for i in length:
		var p: Vector2i = parts[0] if i == 0 else (parts[2] if i == length - 1 else parts[1])
		layer.set_cell(from + Vector2i(i, 0), source, p)


# ---------------------------------------------------------------- Nodos

func new_location(scene_name: String, size_px: Vector2i, default_spawn: String) -> void:
	scene_root = Node2D.new()
	scene_root.name = scene_name
	scene_root.set_script(load("res://scripts/world/Location.gd"))
	scene_root.area_size = size_px
	scene_root.default_spawn = default_spawn
	_shadow_rects = []
	_shadow_ellipses = []
	rng.seed = hash(scene_name)


func add_node(parent: Node, node: Node) -> Node:
	parent.add_child(node)
	node.owner = scene_root
	return node


func new_layer(ts: TileSet, layer_name: String) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.name = layer_name
	l.tile_set = ts
	add_node(scene_root, l)
	return l


## Capa de sombras: crear después del piso y antes de edificios/muebles.
func add_shadow_layer() -> Node2D:
	var s := Node2D.new()
	s.name = "Shadows"
	s.set_script(load("res://scripts/world/ShadowLayer.gd"))
	return add_node(scene_root, s)


func shadow_rect(r: Rect2) -> void:
	_shadow_rects.append(r)


func shadow_ellipse(r: Rect2) -> void:
	_shadow_ellipses.append(r)


## Salpica detalles (decals) en `target`: cada celda de `cells` tiene `chance` de recibir uno.
## accept(cell) devuelve los decals posibles para esa celda ([] = ninguno).
func scatter(target: TileMapLayer, cells: Array, chance: float, accept: Callable, source: int) -> void:
	for cell in cells:
		if rng.randf() >= chance:
			continue
		var options: Array = accept.call(cell)
		if options.is_empty():
			continue
		target.set_cell(cell, source, options[rng.randi() % options.size()])


func instance(path: String) -> Node:
	var node: Node = load(path).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	return add_node(scene_root, node)


## Agrega el jugador justo después de `below` (para que las capas siguientes lo tapen).
func add_player(below: Node) -> void:
	var player := instance(PLAYER_SCENE)
	scene_root.move_child(player, below.get_index() + 1)


## Punto de entrada. facing: "down", "up", "left" o "right".
func add_spawn(spawn_name: String, pos: Vector2, facing := "down") -> void:
	var m := Marker2D.new()
	m.name = spawn_name
	m.position = pos
	m.set_meta("facing", facing)
	add_node(scene_root, m)


## Puerta: un área en `center` (píxeles). Con target vacío es una puerta cerrada.
func add_door(door_name: String, center: Vector2, size: Vector2, push_dir: Vector2,
		target := "", spawn := "", locked_text := "") -> void:
	var door := Area2D.new()
	door.name = door_name
	door.set_script(load("res://scripts/world/Door.gd"))
	door.position = center
	door.target_scene = target
	door.target_spawn = spawn
	door.push_dir = push_dir
	if locked_text != "":
		door.locked_text = locked_text
	var parent := scene_root.get_node_or_null("Doors")
	if parent == null:
		parent = add_node(scene_root, Node2D.new())
		parent.name = "Doors"
	add_node(parent, door)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_node(door, shape)


## Algo tirado en el piso para agarrar (ver scripts/world/Pickup.gd).
func add_pickup(parent: Node, item_id: String, pos: Vector2, qty := 1, line := "", hidden := false) -> void:
	var p := Area2D.new()
	p.name = "Pickup_%s_%d_%d" % [item_id, pos.x, pos.y]
	p.set_script(load("res://scripts/world/Pickup.gd"))
	p.item_id = item_id
	p.qty = qty
	p.found_line = line
	p.concealed = hidden
	p.position = pos
	add_node(parent, p)


## Persona (ver scripts/npc/NPC.gd y autoload/Conversations.gd).
func add_npc(parent: Node, npc_id: String, sheet_row: int, pos: Vector2, face := "down",
		reach := Vector2(26, 34), route := PackedVector2Array()) -> void:
	var n := CharacterBody2D.new()
	n.name = npc_id.capitalize()
	n.set_script(load("res://scripts/npc/NPC.gd"))
	n.npc_id = npc_id
	n.sheet_row = sheet_row
	n.face = face
	n.talk_reach = reach
	n.route = route
	n.position = pos
	add_node(parent, n)


## Lugar para pasar la noche (ver scripts/world/SleepSpot.gd), con el punto donde despierta.
func add_sleep_spot(parent: Node, spot_id: String, pos: Vector2) -> void:
	var a := Area2D.new()
	a.name = "Dormir_" + spot_id
	a.set_script(load("res://scripts/world/SleepSpot.gd"))
	a.spot_id = spot_id
	a.position = pos
	add_node(parent, a)
	add_spawn("Wake_" + spot_id, pos + Vector2(0, 16), "down")


## Algo que se usa con el botón (baño, pensión; ver scripts/world/ServiceSpot.gd).
func add_service(parent: Node, service_id: String, pos: Vector2, hint: String, area := Vector2(20, 14)) -> void:
	var a := Area2D.new()
	a.name = "Servicio_" + service_id
	a.set_script(load("res://scripts/world/ServiceSpot.gd"))
	a.service_id = service_id
	a.hint = hint
	a.area = area
	a.position = pos
	add_node(parent, a)


func add_label(parent: Node, text: String, center: Vector2) -> void:
	var settings := LabelSettings.new()
	settings.font = load(FONT)
	settings.font_size = 8
	settings.font_color = Color(1, 0.95, 0.8)
	settings.outline_size = 3
	settings.outline_color = Color(0.15, 0.1, 0.1)
	var label := Label.new()
	label.name = "Cartel" + text.capitalize().replace(" ", "")
	label.text = text
	label.label_settings = settings
	label.size = Vector2(text.length() * 8 + 4, 10)
	label.position = center - Vector2(label.size.x / 2, 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_node(parent, label)


func save_scene(path: String) -> void:
	var shadows := scene_root.get_node_or_null("Shadows")
	if shadows:
		shadows.area_size = scene_root.area_size
		shadows.rects = _shadow_rects
		shadows.ellipses = _shadow_ellipses
	var packed := PackedScene.new()
	packed.pack(scene_root)
	var err := ResourceSaver.save(packed, path)
	print(path, ": ", error_string(err))
	scene_root.free()
