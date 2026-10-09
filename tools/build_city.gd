extends "res://tools/map_builder.gd"
## Genera la ciudad del Día 1 (City.tscn): un barrio humilde estilo EarthBound que da mal rollo.
## Suelo en tiles; edificios y objetos como sprites en perspectiva oblicua dentro de un nodo
## con orden por profundidad (Y-sort), así el jugador pasa por detrás y por delante de las cosas.
## Correr desde la carpeta del proyecto:
##   Godot --headless --path . -s res://tools/build_city.gd
## OJO: sobrescribe scenes/world/City.tscn. El layout se edita acá.
## Arte: tools/art/draw_barrio.py.

const GROUND_SHEET := "res://assets/barrio/ground.png"
const DECALS := "res://assets/tilesets/decals.png"
const TILESET_PATH := "res://assets/barrio/barrio_tileset.tres"
const SCENE_PATH := "res://scenes/world/City.tscn"
const ART := "res://assets/barrio/%s.png"
const W := 64
const H := 48

# --- Tiles del suelo (índice en ground.png)
const GRASS := [0, 1, 2, 3]
const GRASS_DRY := [4, 5]
const DIRT := [6, 7]
const ASPHALT := [8, 8, 8, 9, 8, 10]
const DASH_H := 11
const DASH_V := 12
const WALK := [13, 13, 14, 15]
const CURB := 16
const CONCRETE := 17
const WATER := [18, 19]
const MUD := 20
const DECK := 21
const RAIL := 22
const PLAZA := 23

## Edificios: sprite -> [puerta x en el sprite (-1 = sin puerta), ancho de puerta, profundidad del techo]
const BUILDING_INFO := {
	"house_a": [18, 10, 20], "house_b": [22, 10, 18], "house_c": [24, 10, 22],
	"house_d": [6, 10, 16], "house_e": [17, 10, 20], "house_f": [30, 8, 22],
	"bakery": [37, 12, 22], "cafe": [23, 11, 20],
	"warehouse_a": [36, 26, 30], "warehouse_b": [30, 20, 26], "kiosk": [-1, 0, 12],
}
## Líneas de las puertas cerradas, en orden.
const LOCKED_LINES := [
	"Nadie contesta. Normal: si yo viera esta cara en mi puerta, tampoco abro.",
	"Adentro suena una telenovela. Por fin alguien en este barrio con un guión peor que el mío.",
	"Alguien corre la cortina, me mira y la cierra. Reseña: una estrella. No volvería.",
	"Cartel: NO DAMOS NADA. Por lo menos son honestos. Les dejaría propina.",
	"Un perro ladra adentro. Lukas le contesta. No traduzco: el juego es para todo público.",
	"Tres candados. Tranquilos, vecinos: no me llevo nada, no tengo dónde ponerlo.",
	"No vive nadie. Una casa sin gente y un tipo sin casa. Alguien en diseño se está riendo.",
	"Una voz detrás de la puerta: —Andate.",
]
const GATE_LINE := "Candado. Del otro lado, una radio con música de despecho. Ni a mí me va tan mal."

var ground: TileMapLayer
var details: TileMapLayer
var world: Node2D
var noise := FastNoiseLite.new()
var _locked_index := 0
var _poles: Array[Vector2] = []


func _initialize() -> void:
	ResourceSaver.save(build_tileset(), TILESET_PATH)
	build_scene(load(TILESET_PATH))
	quit()


func build_tileset() -> TileSet:
	var ts := new_tileset()
	var src := add_sheet(ts, GROUND_SHEET, 0)
	add_sheet(ts, DECALS, 1)
	for i in WATER + [RAIL]:
		set_collision(src, Vector2i(i, 0), FULL)
	# Baranda vertical (el puente va de norte a sur): la misma, rotada.
	var alt := src.create_alternative_tile(Vector2i(RAIL, 0))
	var td := src.get_tile_data(Vector2i(RAIL, 0), alt)
	td.transpose = true
	td.flip_h = true
	td.add_collision_polygon(0)
	td.set_collision_polygon_points(0, 0, PackedVector2Array(FULL))
	return ts


# ---------------------------------------------------------------- Helpers

func g(at: Vector2i, options, alt := 0) -> void:
	var i: int = options if options is int else options[rng.randi() % options.size()]
	ground.set_cell(at, 0, Vector2i(i, 0), alt)


func g_rect(r: Rect2i, options) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			g(Vector2i(x, y), options)


func _add_footprint(parent: Node, footprint: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Solido"
	add_node(parent, body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = footprint
	shape.shape = rect
	shape.position = Vector2(0, -footprint.y / 2.0)
	add_node(body, shape)


## Sprite con el origen al pie (abajo al centro), dentro del nodo con orden por profundidad.
func place(art: String, foot: Vector2, footprint := Vector2.ZERO, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "%s_%d_%d" % [art, foot.x, foot.y]
	s.texture = load(ART % art)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = foot
	s.flip_h = flip
	add_node(world, s)
	if footprint != Vector2.ZERO:
		_add_footprint(s, footprint)
	return s


## Animación chica (perro, farol que parpadea).
func place_anim(frames_list: Array, fps: float, foot: Vector2, footprint := Vector2.ZERO) -> AnimatedSprite2D:
	var f := SpriteFrames.new()
	f.set_animation_speed("default", fps)
	for art in frames_list:
		f.add_frame("default", load(ART % art))
	var a := AnimatedSprite2D.new()
	a.name = "%s_%d_%d" % [frames_list[0], foot.x, foot.y]
	a.sprite_frames = f
	a.autoplay = "default"
	a.centered = false
	var tex: Texture2D = load(ART % frames_list[0])
	a.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	a.position = foot
	add_node(world, a)
	if footprint != Vector2.ZERO:
		_add_footprint(a, footprint)
	return a


## Edificio: x = borde izquierdo, base = línea del piso de la fachada (px).
## enter = escena interior; si no, puerta cerrada con una línea.
func building(art: String, x: float, base: float, enter := "", door_text := "", service := "") -> void:
	var info: Array = BUILDING_INFO[art]
	var tex: Texture2D = load(ART % art)
	var w := tex.get_width()
	var depth: float = info[2] + 6.0
	place(art, Vector2(x + w / 2.0, base), Vector2(w, depth))
	shadow_rect(Rect2(x + 6, base - depth + 4, w, depth))
	if info[0] < 0:
		return
	var front := Vector2(x + info[0] + info[1] / 2.0, base)
	var door_name := "Puerta_%s_%d" % [art, x]
	if service != "":
		add_service(world, service, front + Vector2(0, 4), service.to_upper())
		add_spawn("Wake_" + service, front + Vector2(0, 18), "down")
		add_label(world, service.to_upper(), front + Vector2(0, -30))
	elif enter != "":
		var place_name := enter.get_file().get_basename()
		add_door(door_name, front + Vector2(0, 2), Vector2(18, 12), Vector2.UP, enter, "FromStreet")
		add_spawn("From" + place_name, front + Vector2(0, 18), "down")
	else:
		if door_text == "":
			door_text = LOCKED_LINES[_locked_index % LOCKED_LINES.size()]
			_locked_index += 1
		add_door(door_name, front + Vector2(0, 2), Vector2(18, 12), Vector2.UP, "", "", door_text)


## Objeto chico con colisión en la base y sombra.
func prop(art: String, foot: Vector2, solid := true, flip := false) -> void:
	var tex: Texture2D = load(ART % art)
	var w := tex.get_width()
	place(art, foot, Vector2(w - 4, 6) if solid else Vector2.ZERO, flip)
	shadow_ellipse(Rect2(foot.x - w / 2.0 + 3, foot.y - 4, w, 7))


func tree(art: String, foot: Vector2) -> void:
	place(art, foot, Vector2(8, 5))
	shadow_ellipse(Rect2(foot.x - 6, foot.y - 4, 26, 8))


## Poste de luz; los cables se tiran después entre postes vecinos.
func pole(foot: Vector2) -> void:
	place("pole", foot, Vector2(4, 4))
	shadow_rect(Rect2(foot.x, foot.y - 2, 22, 2))
	_poles.append(foot)


# ---------------------------------------------------------------- Mapa

func build_scene(ts: TileSet) -> void:
	new_location("City", Vector2i(W * 16, H * 16), "Start")
	noise.seed = 7
	noise.frequency = 0.035
	ground = new_layer(ts, "Ground")
	details = new_layer(ts, "Details")
	add_shadow_layer()
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_node(scene_root, world)

	paint_ground()
	paint_park()
	paint_industrial()
	paint_barrio()
	paint_commerce()
	paint_east()
	paint_river()
	paint_cables()
	scatter_details()
	place_pickups()

	add_spawn("Start", Vector2(25 * 16 + 4, 39 * 16 + 6), "down")
	add_spawn("Desmayo", Vector2(568, 516), "down")  # donde despierta si se desmaya de hambre
	var player: Node2D = load(PLAYER_SCENE).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_node(world, player)
	instance(MOOD_SCENE)
	save_scene(SCENE_PATH)


func paint_ground() -> void:
	# Pasto, pasto seco y tierra mezclados con ruido: un descampado mal cuidado.
	for y in H:
		for x in W:
			var n := noise.get_noise_2d(x, y)
			g(Vector2i(x, y), GRASS if n > 0.35 else (GRASS_DRY if n > -0.2 else DIRT))

	# Avenida (este-oeste) con veredas.
	g_rect(Rect2i(0, 14, W, 3), ASPHALT)
	for x in range(1, W, 2):
		g(Vector2i(x, 15), DASH_H)
	g_rect(Rect2i(0, 13, W, 1), CURB)
	g_rect(Rect2i(0, 17, W, 1), WALK)
	# Calle principal (norte-sur) hasta el puente, y calle del este.
	for col in [28, 50]:
		g_rect(Rect2i(col, 17, 3, 21 if col == 28 else 20), ASPHALT)
		for y in range(18, 37, 2):
			g(Vector2i(col + 1, y), DASH_V)
		g_rect(Rect2i(col - 1, 18, 1, 19), WALK)
		g_rect(Rect2i(col + 3, 18, 1, 19), WALK)
	# Caminos de tierra entre las casillas.
	g_rect(Rect2i(3, 26, 23, 2), DIRT)
	g_rect(Rect2i(12, 18, 2, 18), DIRT)


func paint_park() -> void:
	# Plaza abandonada: pasto seco, árboles muertos, una hamaca rota.
	g_rect(Rect2i(1, 1, 22, 11), GRASS_DRY)
	for p in [Vector2(70, 110), Vector2(250, 60), Vector2(330, 150)]:
		tree("tree_dead", p)
	for p in [Vector2(140, 60), Vector2(30, 170)]:
		tree("tree_sparse", p)
	prop("swing", Vector2(196, 118))
	prop("bench_broken", Vector2(120, 168))
	prop("mattress", Vector2(270, 176), false)
	prop("trash", Vector2(330, 182))
	for x in [16, 32, 48, 112, 128, 224, 240, 256, 304]:
		prop("fence_wood", Vector2(x, 196))
	place_anim(["dog_a", "dog_b"], 2.0, Vector2(176, 186), Vector2(14, 5))
	# Lo bueno del barrio, en el parquecito: los pelados del fútbol, la banca, el columpio, el perro.
	place_anim(["pelaos_a", "pelaos_b"], 3.0, Vector2(300, 100))
	add_service(world, "pelaos", Vector2(300, 106), "FÚTBOL", Vector2(64, 18))
	add_service(world, "banca_parquecito", Vector2(120, 174), "SENTARSE", Vector2(24, 14))
	add_service(world, "columpio", Vector2(196, 124), "COLUMPIO", Vector2(22, 14))
	add_service(world, "perro_barrio", Vector2(176, 194), "PERRO", Vector2(22, 12))


func paint_industrial() -> void:
	g_rect(Rect2i(36, 1, 27, 12), DIRT)
	building("warehouse_a", 590, 168, "", GATE_LINE)
	building("warehouse_b", 712, 160, "", GATE_LINE)
	building("warehouse_a", 816, 176, "", GATE_LINE)
	for x in range(584, 944, 16):
		if x < 690 or x > 720:
			prop("fence_chain", Vector2(x + 8, 206))
	prop("dumpster", Vector2(800, 200))
	prop("tires", Vector2(940, 196))
	prop("car_burnt", Vector2(660, 196))


func paint_barrio() -> void:
	building("house_a", 24, 336)
	building("house_b", 104, 336)
	building("house_c", 152, 400)
	building("house_d", 36, 448)
	building("house_e", 128, 470)
	building("house_f", 300, 380, "", "", "pension")
	building("house_a", 220, 560)
	building("kiosk", 380, 540)
	building("house_c", 40, 576)
	prop("trash", Vector2(96, 352))
	prop("cart", Vector2(260, 400))
	prop("tires", Vector2(196, 470))
	for x in [184, 200, 216]:
		prop("fence_chain", Vector2(x, 336))
	for x in [16, 32, 64, 80]:
		prop("fence_wood", Vector2(x, 600))
	tree("tree_dead", Vector2(270, 470))
	tree("tree_sparse", Vector2(400, 470))
	place_anim(["dog_a", "dog_b", "dog_a", "dog_a"], 3.0, Vector2(60, 360), Vector2(14, 5))
	for y in [300, 460, 600]:
		pole(Vector2(426, y))


func paint_commerce() -> void:
	# Panadería y café: lo único cálido del barrio.
	building("bakery", 520, 352, "res://scenes/world/Bakery.tscn")
	building("cafe", 616, 352, "res://scenes/world/Cafe.tscn")
	# TV RADIO (entre el café y la calle del este, en la vereda, no en la calle): electrodomésticos
	# con teles prendidas en la vitrina. Desde la vereda se ve la tele
	# (ver Conversations._vitrina_tv); de noche, la reja abajo (scripts/world/Vitrina.gd).
	var tv := place_anim(["electro_a", "electro_b", "electro_a", "electro_c"], 1.5, Vector2(712, 352), Vector2(76, 24))
	tv.sprite_frames.add_animation("noche")
	tv.sprite_frames.add_frame("noche", load(ART % "electro_noche"))
	tv.set_script(load("res://scripts/world/Vitrina.gd"))
	shadow_rect(Rect2(680, 328, 76, 24))
	add_service(world, "vitrina_tv", Vector2(712, 360), "VER TV", Vector2(40, 14))
	# Carros, buses, bicis y motos que pasan de vez en cuando (avenida y calle principal).
	var traffic := Node2D.new()
	traffic.name = "Trafico"
	traffic.set_script(load("res://scripts/world/Traffic.gd"))
	add_node(world, traffic)
	# Placita con baldosas rotas y una fuente seca.
	g_rect(Rect2i(33, 24, 14, 9), PLAZA)
	for i in 14:
		g(Vector2i(33 + rng.randi() % 14, 24 + rng.randi() % 9), DIRT)
	prop("fountain_dry", Vector2(640, 460))
	prop("bench_broken", Vector2(568, 500))
	prop("bench_broken", Vector2(712, 430), true, true)
	tree("tree_sparse", Vector2(560, 420))
	prop("bus_stop", Vector2(500, 400))
	add_service(world, "bus_barrio", Vector2(500, 408), "PARADERO", Vector2(28, 14))
	# El teléfono público (al lado del paradero).
	prop("telefono", Vector2(462, 400))
	add_service(world, "telefono", Vector2(462, 406), "TELEFONO", Vector2(18, 14))
	# Cuencos con agua: Lukas toma y se guarda la partida (solo acá).
	for c in [["cuenco_1", Vector2(536, 372)], ["cuenco_2", Vector2(424, 616)], ["cuenco_3", Vector2(214, 150)]]:
		prop("cuenco", c[1], false)
		add_service(world, c[0], c[1] + Vector2(0, 4), "AGUA", Vector2(18, 14))
		add_spawn("Spawn_" + c[0], c[1] + Vector2(0, 14), "down")
	# Para pedir: afuera de la panadería (la gente sale con pan y culpa).
	add_service(world, "pedir", Vector2(590, 372), "PEDIR", Vector2(18, 12))
	add_spawn("FromPedir", Vector2(590, 384), "down")
	add_spawn("FromBus", Vector2(500, 422), "down")
	prop("trash", Vector2(764, 374))
	place_anim(["lamp_on"], 1.0, Vector2(512, 300), Vector2(4, 4))
	place_anim(["lamp_on"], 1.0, Vector2(740, 300), Vector2(4, 4))


func paint_east() -> void:
	building("house_b", 862, 352)
	building("house_e", 936, 352)
	building("house_d", 870, 470)
	building("house_f", 940, 540)
	prop("car_burnt", Vector2(900, 580))
	prop("cart", Vector2(980, 600))
	for y in [300, 460, 600]:
		pole(Vector2(864, y))


func paint_river() -> void:
	# Orilla de barro y río turbio.
	g_rect(Rect2i(0, 38, W, 2), DIRT)
	g_rect(Rect2i(0, 40, W, 1), MUD)
	g_rect(Rect2i(0, 41, W, H - 41), WATER)
	# Puente: la calle principal sigue sobre el río (barandas a los costados).
	for y in range(38, H):
		g_rect(Rect2i(28, y, 3, 1), DECK)
		g(Vector2i(27, y), RAIL, 1)
		g(Vector2i(31, y), RAIL, 1)
	# Bajo el puente: el campamento, donde se despierta. Es el cambuche principal (el "rio" de
	# SleepSpot): sin armar, se ven los cartones de siempre; armado, el cambuche con sus mejoras.
	g_rect(Rect2i(23, 37, 4, 3), CONCRETE)
	shadow_ellipse(Rect2(386, 626, 34, 7))
	place("pillar", Vector2(426, 640), Vector2(20, 8))
	prop("trash", Vector2(374, 618))
	prop("cart", Vector2(350, 652), false)
	# El farol que parpadea, al lado del campamento.
	place_anim(["lamp_on", "lamp_on", "lamp_on", "lamp_off", "lamp_on", "lamp_off", "lamp_on", "lamp_on",
		"lamp_on", "lamp_on", "lamp_on", "lamp_off"], 8.0, Vector2(340, 612), Vector2(4, 4))
	tree("tree_dead", Vector2(560, 626))
	prop("mattress", Vector2(640, 634), false)
	# Lo bueno del barrio en el río: la línea de pesca que alguien deja, y el atardecer desde el puente.
	prop("pesca", Vector2(706, 640), false)
	add_service(world, "pescar", Vector2(706, 644), "PESCAR", Vector2(28, 14))
	add_service(world, "atardecer", Vector2(472, 704), "MIRAR", Vector2(40, 18))
	prop("trash", Vector2(760, 630))
	tree("tree_dead", Vector2(900, 622))


## Cables entre postes vecinos (combados) y algunos cuervos posados.
func paint_cables() -> void:
	for x in [16, 176, 336, 496, 656, 816, 976]:
		pole(Vector2(x, 210))
	var cables := Node2D.new()
	cables.name = "Cables"
	cables.z_index = 50
	add_node(scene_root, cables)
	var pairs := []
	for i in _poles.size():
		for j in range(i + 1, _poles.size()):
			var a := _poles[i]
			var b := _poles[j]
			if a.distance_to(b) <= 165.0 and (is_equal_approx(a.x, b.x) or is_equal_approx(a.y, b.y)):
				pairs.append([a, b])
	for k in pairs.size():
		var top_a: Vector2 = pairs[k][0] + Vector2(0, -50)
		var top_b: Vector2 = pairs[k][1] + Vector2(0, -50)
		var mid := (top_a + top_b) / 2.0 + Vector2(0, 10)
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color(0.15, 0.12, 0.17)
		for t in 9:
			var s := t / 8.0
			line.add_point(top_a.lerp(mid, s).lerp(mid.lerp(top_b, s), s))
		add_node(cables, line)
		if k % 2 == 0:
			var crow := AnimatedSprite2D.new()
			var f := SpriteFrames.new()
			f.set_animation_speed("default", 2.0)
			for art in ["crow_a", "crow_a", "crow_a", "crow_b"]:
				f.add_frame("default", load(ART % art))
			crow.sprite_frames = f
			crow.autoplay = "default"
			crow.position = mid + Vector2(-4, -4)
			add_node(cables, crow)


# ---------------------------------------------------------------- Cosas para agarrar

## Comida tirada, latas y botellas para vender, materiales para el cambuche.
func place_pickups() -> void:
	add_pickup(world, "pan", Vector2(690, 390), 1, "Un pan tirado al lado de la panadería. La regla de los cinco segundos es en días, ¿no?")
	add_pickup(world, "fruta", Vector2(150, 92), 1, "Media manzana. Alguien le dio un mordisco y siguió con su vida. Yo sigo con la mía.")
	for p in [Vector2(372, 640), Vector2(100, 372), Vector2(820, 222), Vector2(560, 648)]:
		add_pickup(world, "lata", p)
	for p in [Vector2(320, 192), Vector2(910, 612)]:
		add_pickup(world, "botella", p)
	add_pickup(world, "carton", Vector2(408, 556), 1, "Un cartón seco. Acá esto es finca raíz. Acabo de comprar terreno.")
	add_pickup(world, "carton", Vector2(786, 222))
	add_pickup(world, "carton", Vector2(726, 216))
	# Estibas: detrás de las bodegas (para las paredes del rancho).
	for p in [Vector2(604, 214), Vector2(842, 230), Vector2(668, 236)]:
		add_pickup(world, "estiba", p, 1, "Una estiba. Madera de bodega. Si junto cuatro, tengo paredes. Si junto ocho, tengo vecinos celosos.")
	add_pickup(world, "plastico", Vector2(640, 214), 1, "Un plástico grande. Techo, capa o vestido de gala. Lo decido después.")
	# Gente del Día 1.
	add_npc(world, "wilson", 9, Vector2(70, 424), "right", Vector2(26, 34), PackedVector2Array([Vector2(70, 424), Vector2(380, 424)]))
	add_npc(world, "samuel", 12, Vector2(652, 626), "left")
	# Lugares para pasar la noche.
	add_sleep_spot(world, "banco", Vector2(568, 514))
	add_sleep_spot(world, "kiosco", Vector2(394, 554))
	add_sleep_spot(world, "rio", Vector2(400, 626))  # bajo el puente, donde se despierta (Start)
	add_sleep_spot(world, "callejon", Vector2(700, 186))
	add_sleep_spot(world, "parque", Vector2(262, 138))
	# Plata: el puesto de Doña Rosa y el baño público, en la plaza.
	prop("food_cart", Vector2(612, 420))
	add_npc(world, "rosa", 15, Vector2(634, 418), "down")
	prop("bano", Vector2(742, 470))
	add_service(world, "bano", Vector2(742, 478), "BAÑO $1000")
	add_pickup(world, "cuerda", Vector2(762, 214), 1, "Una cuerda. Sirve para atar cosas. Y para ahorcar el aburrimiento. Solo eso.")
	# Los pedazos de la foto (el coleccionable): tres a la vista, uno que solo encuentra Lukas.
	for p in [[Vector2(392, 646), false], [Vector2(930, 612), false], [Vector2(340, 194), false], [Vector2(120, 372), true]]:
		add_pickup(world, "pedazo_foto", p[0], 1, "", p[1])
	# Pistas: el recorte del operativo (lo encuentra Lukas) y la carta frente a la casa de tejas.
	add_pickup(world, "recorte_1", Vector2(112, 368), 1, "", true)
	add_pickup(world, "carta_ines", Vector2(66, 594))
	# Escondidos: solo los encuentra Lukas olfateando.
	add_pickup(world, "sandwich", Vector2(336, 396), 1, "Un sándwich detrás de la casa. Casi entero. No voy a investigar el casi: soy un hombre de fe.", true)
	add_pickup(world, "pan", Vector2(574, 508), 1, "Medio pan debajo del banco. Blando. Hoy la suerte me quiere. Un poquito.", true)
	add_pickup(world, "fruta", Vector2(392, 482), 1, "Una manzana caída. La encontró Lukas. Ya le debo como cuarenta.", true)


# ---------------------------------------------------------------- Detalles

const D_CRACK := [Vector2i(0, 0), Vector2i(1, 0)]
const D_OIL := Vector2i(2, 0)
const D_LEAVES := Vector2i(3, 0)
const D_PAPER := Vector2i(4, 0)
const D_BUTTS := Vector2i(5, 0)
const D_WEED := Vector2i(6, 0)
const D_STONES := Vector2i(8, 0)
const D_TUFT := Vector2i(10, 0)
const D_CAN := Vector2i(18, 0)


## Basura y yuyos sueltos.
func scatter_details() -> void:
	var cells: Array = []
	for y in H:
		for x in W:
			cells.append(Vector2i(x, y))
	var on_ground := func(cell: Vector2i) -> Array:
		var t := ground.get_cell_atlas_coords(cell).x
		if t in ASPHALT:
			return [D_OIL, D_CRACK[0], D_CRACK[1]]
		if t in WALK or t == CURB:
			return [D_BUTTS, D_PAPER, D_WEED, D_CRACK[1]]
		if t in GRASS or t in GRASS_DRY or t in DIRT:
			return [D_TUFT, D_TUFT, D_PAPER, D_STONES, D_LEAVES]
		if t == CONCRETE:
			return [D_BUTTS, D_PAPER, D_CAN, D_OIL]
		return []
	scatter(details, cells, 0.045, on_ground, 1)
