extends "res://tools/map_builder.gd"
## Genera los interiores (panadería y café) y su TileSet.
## Correr desde la carpeta del proyecto:
##   Godot --headless --path . -s res://tools/build_interiors.gd
## OJO: sobrescribe Bakery.tscn y Cafe.tscn.
## Arte: Kenney Roguelike Indoors (CC0) + tiles propios (tools/art/draw_interior_tiles.py).

const KENNEY := "res://assets/tilesets/kenney_indoor.png"
const CUSTOM := "res://assets/tilesets/interior_custom.png"
const DECALS := "res://assets/tilesets/decals.png"
const D_FLOUR := Vector2i(19, 0)
const D_CRUMBS := Vector2i(20, 0)
const D_PAPER := Vector2i(4, 0)
const TILESET_PATH := "res://assets/tilesets/interior_tileset.tres"
const W := 20
const H := 12
const DOOR_COLS := [9, 10]

# Fuente 1: tiles propios (una fila).
const CAP := Vector2i(0, 0)
const FACE_UP := Vector2i(1, 0)
const FACE_LOW := Vector2i(2, 0)
const WOOD := Vector2i(3, 0)
const CHECKER := Vector2i(4, 0)
const MAT := Vector2i(5, 0)
const BREAD_SHELF := Vector2i(6, 0)
const BREAD_TRAY := Vector2i(7, 0)
const WINDOW := Vector2i(8, 0)
const BOARD := Vector2i(9, 0)
const ESPRESSO := Vector2i(10, 0)
const CUPS := Vector2i(11, 0)
const FLOUR := Vector2i(12, 0)
const BOXES := Vector2i(13, 0)
const BASKET := Vector2i(14, 0)

# Fuente 0: Kenney Roguelike Indoors.
const COUNTER := [Vector2i(8, 15), Vector2i(9, 15), Vector2i(10, 15)]
const DRAWERS := Vector2i(1, 13)
const SINK := Vector2i(8, 13)
const BOTTLES := Vector2i(5, 13)
const JARS := Vector2i(6, 13)
const PLATES := Vector2i(4, 13)
const STOVE := Vector2i(14, 14)
const OVEN := Vector2i(14, 15)
const FRIDGE := Vector2i(11, 15)
const TABLE := Vector2i(7, 0)
const CHAIR_FACING_RIGHT := Vector2i(2, 2)
const CHAIR_FACING_LEFT := Vector2i(3, 2)
const PLANT := Vector2i(16, 0)

var floor_layer: TileMapLayer
var details: TileMapLayer
var walls: TileMapLayer
var furniture: TileMapLayer
var items: TileMapLayer


func _initialize() -> void:
	ResourceSaver.save(build_tileset(), TILESET_PATH)
	var ts: TileSet = load(TILESET_PATH)
	build_bakery(ts)
	build_cafe(ts)
	quit()


func build_tileset() -> TileSet:
	var ts := new_tileset()
	var kenney := add_sheet(ts, KENNEY, 0)
	var custom := add_sheet(ts, CUSTOM, 1)
	add_sheet(ts, DECALS, 2)
	for c in [CAP, FACE_UP, FACE_LOW, BREAD_SHELF, WINDOW, BOARD]:
		set_collision(custom, c, FULL)
	for c in [FLOUR, BOXES, BASKET]:
		set_collision(custom, c, BASE)
	var full_k: Array = [DRAWERS, SINK, BOTTLES, JARS, PLATES, STOVE, OVEN, FRIDGE, TABLE]
	full_k.append_array(COUNTER)
	for c in full_k:
		set_collision(kenney, c, FULL)
	for c in [CHAIR_FACING_RIGHT, CHAIR_FACING_LEFT, PLANT]:
		set_collision(kenney, c, BASE)
	return ts


# ---------------------------------------------------------------- Helpers

func start_room(scene_name: String, ts: TileSet, floor_tile: Vector2i) -> void:
	new_location(scene_name, Vector2i(W * 16, H * 16), "FromStreet")
	scene_root.outdoor = false
	floor_layer = new_layer(ts, "Floor")
	details = new_layer(ts, "Details")
	add_shadow_layer()
	walls = new_layer(ts, "Walls")
	furniture = new_layer(ts, "Furniture")
	items = new_layer(ts, "Items")

	fill(floor_layer, Rect2i(1, 3, W - 2, H - 4), floor_tile, 1)
	fill(walls, Rect2i(0, 0, W, 1), CAP, 1)
	fill(walls, Rect2i(0, 0, 1, H), CAP, 1)
	fill(walls, Rect2i(W - 1, 0, 1, H), CAP, 1)
	for x in W:
		if not x in DOOR_COLS:
			walls.set_cell(Vector2i(x, H - 1), 1, CAP)
	fill(walls, Rect2i(1, 1, W - 2, 1), FACE_UP, 1)
	fill(walls, Rect2i(1, 2, W - 2, 1), FACE_LOW, 1)
	for x in DOOR_COLS:
		floor_layer.set_cell(Vector2i(x, H - 2), 1, MAT)
		floor_layer.set_cell(Vector2i(x, H - 1), 1, MAT)
	# Las paredes de arriba y de la izquierda tiran sombra sobre el piso.
	shadow_rect(Rect2(16, 48, (W - 2) * 16, 5))
	shadow_rect(Rect2(16, 48, 5, (H - 4) * 16))


func finish_room(path: String) -> void:
	var door_x := (DOOR_COLS[0] + 1) * 16
	add_spawn("FromStreet", Vector2(door_x, (H - 2) * 16 + 12), "up")
	add_door("Salida", Vector2(door_x, (H - 1) * 16 + 8), Vector2(28, 14), Vector2.DOWN,
		"res://scenes/world/City.tscn", "From" + path.get_file().get_basename())
	add_player(items)
	instance(MOOD_SCENE)
	save_scene(path)


func k(at: Vector2i, tile: Vector2i, layer: TileMapLayer = null) -> void:
	(layer if layer else furniture).set_cell(at, 0, tile)
	if layer == null:
		furniture_shadow(at, tile in [CHAIR_FACING_RIGHT, CHAIR_FACING_LEFT, PLANT])


func c(at: Vector2i, tile: Vector2i, layer: TileMapLayer = null) -> void:
	(layer if layer else furniture).set_cell(at, 1, tile)
	if layer == null:
		furniture_shadow(at, true)


## Muebles grandes: el bloque corrido hacia abajo a la derecha. Chicos: una elipse en la base.
func furniture_shadow(at: Vector2i, small: bool) -> void:
	if small:
		shadow_ellipse(Rect2(at.x * 16 + 3, at.y * 16 + 10, 15, 6))
	else:
		shadow_rect(Rect2(at.x * 16 + 3, at.y * 16 + 3, 16, 16))


## Salpica decals sobre el piso libre del rectángulo.
func floor_decals(r: Rect2i, chance: float, options: Array) -> void:
	var cells: Array = []
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			cells.append(Vector2i(x, y))
	var on_floor := func(cell: Vector2i) -> Array:
		return options if furniture.get_cell_source_id(cell) == -1 else []
	scatter(details, cells, chance, on_floor, 2)


func table_with_chairs(at: Vector2i, cups := false) -> void:
	k(at, TABLE)
	k(at + Vector2i.LEFT, CHAIR_FACING_RIGHT)
	k(at + Vector2i.RIGHT, CHAIR_FACING_LEFT)
	if cups:
		c(at, CUPS, items)


# ---------------------------------------------------------------- Lugares

## Panadería de Don Germán: mostrador con pan, horno y zona de trabajo con bolsas y cajas.
func build_bakery(ts: TileSet) -> void:
	start_room("Bakery", ts, WOOD)
	for x in [13, 16]:
		c(Vector2i(x, 1), WINDOW, walls)
	for x in range(2, 8):
		c(Vector2i(x, 2), BREAD_SHELF, walls)

	# Zona de trabajo (detrás del mostrador).
	k(Vector2i(9, 3), STOVE)
	k(Vector2i(10, 3), OVEN)
	k(Vector2i(11, 3), STOVE)
	k(Vector2i(12, 3), DRAWERS)
	k(Vector2i(13, 3), SINK)
	k(Vector2i(14, 3), DRAWERS)
	c(Vector2i(16, 3), FLOUR)
	c(Vector2i(17, 3), FLOUR)
	c(Vector2i(18, 3), BOXES)
	c(Vector2i(18, 4), BOXES)
	c(Vector2i(17, 5), BOXES)

	# Mostrador con bandejas de pan.
	row(furniture, Vector2i(1, 6), 8, COUNTER)
	shadow_rect(Rect2(1 * 16 + 3, 6 * 16 + 3, 8 * 16, 16))
	for x in [2, 4, 6]:
		c(Vector2i(x, 6), BREAD_TRAY, items)

	# Lado de los clientes.
	c(Vector2i(2, 9), BASKET)
	c(Vector2i(4, 9), BASKET)
	table_with_chairs(Vector2i(14, 8), true)
	k(Vector2i(1, 7), PLANT)
	k(Vector2i(18, 7), PLANT)
	k(Vector2i(18, 10), PLANT)
	floor_decals(Rect2i(9, 4, 10, 2), 0.5, [D_FLOUR])  # harina en la zona de trabajo
	floor_decals(Rect2i(1, 7, 9, 2), 0.3, [D_CRUMBS])  # migas frente al mostrador
	floor_decals(Rect2i(1, 9, 17, 2), 0.06, [D_CRUMBS, D_PAPER])
	# Don Germán, detrás del mostrador (se le habla desde el lado de los clientes).
	add_npc(scene_root, "german", 6, Vector2(4 * 16 + 8, 5 * 16 + 8), "down", Vector2(36, 60))
	finish_room("res://scenes/world/Bakery.tscn")


## Café donde trabaja Marta: barra con cafetera, pizarrón y mesitas.
func build_cafe(ts: TileSet) -> void:
	start_room("Cafe", ts, CHECKER)
	c(Vector2i(3, 1), BOARD, walls)
	c(Vector2i(4, 1), BOARD, walls)
	for x in [10, 13, 16]:
		c(Vector2i(x, 1), WINDOW, walls)

	# Detrás de la barra.
	k(Vector2i(1, 3), BOTTLES)
	k(Vector2i(2, 3), JARS)
	k(Vector2i(3, 3), PLATES)
	k(Vector2i(4, 3), DRAWERS)
	k(Vector2i(5, 3), SINK)
	k(Vector2i(6, 3), DRAWERS)
	k(Vector2i(7, 3), FRIDGE)

	# Barra.
	row(furniture, Vector2i(1, 5), 7, COUNTER)
	shadow_rect(Rect2(1 * 16 + 3, 5 * 16 + 3, 7 * 16, 16))
	c(Vector2i(2, 5), ESPRESSO, items)
	c(Vector2i(5, 5), CUPS, items)

	# Mesitas.
	table_with_chairs(Vector2i(12, 5), true)
	table_with_chairs(Vector2i(16, 5))
	table_with_chairs(Vector2i(12, 8))
	table_with_chairs(Vector2i(16, 8), true)
	k(Vector2i(18, 3), PLANT)
	k(Vector2i(1, 10), PLANT)
	k(Vector2i(18, 10), PLANT)
	floor_decals(Rect2i(9, 4, 10, 6), 0.07, [D_CRUMBS])
	# Marta, detrás de la barra.
	add_npc(scene_root, "marta", 3, Vector2(3 * 16 + 8, 4 * 16 + 10), "down", Vector2(36, 56))
	finish_room("res://scenes/world/Cafe.tscn")
