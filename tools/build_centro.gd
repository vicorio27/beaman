extends "res://tools/build_city.gd"
## Genera el centro (Centro.tscn), la zona que se abre en el Día 3 con el trámite de la cédula:
## una avenida con la Registraduría, Foto Express y edificios; abajo, una plazoleta con el paradero
## del bus que vuelve al barrio. Usa el mismo TileSet y los mismos helpers que la ciudad.
## Correr desde la carpeta del proyecto (después de build_city.gd, que arma el TileSet):
##   Godot --headless --path . -s res://tools/build_centro.gd
## OJO: sobrescribe scenes/world/Centro.tscn.

const CENTRO_PATH := "res://scenes/world/Centro.tscn"
const CW := 40
const CH := 24
const FRONT := 180.0  # línea de las fachadas


func _initialize() -> void:
	build_centro(load(TILESET_PATH))
	quit()


func build_centro(ts: TileSet) -> void:
	new_location("Centro", Vector2i(CW * 16, CH * 16), "FromBus")
	ground = new_layer(ts, "Ground")
	details = new_layer(ts, "Details")
	add_shadow_layer()
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_node(scene_root, world)

	# Suelo: hormigón detrás de las fachadas, vereda, cordón, avenida, vereda y plazoleta.
	g_rect(Rect2i(0, 0, CW, 11), CONCRETE)
	g_rect(Rect2i(0, 11, CW, 2), WALK)
	g_rect(Rect2i(0, 13, CW, 1), CURB)
	g_rect(Rect2i(0, 14, CW, 3), ASPHALT)
	for x in range(0, CW, 2):
		g(Vector2i(x, 15), DASH_H)
	g_rect(Rect2i(0, 17, CW, 2), WALK)
	g_rect(Rect2i(0, 19, CW, CH - 19), PLAZA)
	for i in 20:
		g(Vector2i(rng.randi() % CW, 19 + rng.randi() % (CH - 19)), DIRT)

	# Fachadas.
	_front("edificio_centro", 50.0)
	_front("registraduria", 170.0)
	_front("foto_express", 290.0)
	_front("edificio_centro", 392.0)
	_front("house_f", 488.0)
	_front("colegio", 590.0)
	add_label(world, "REGISTRADURIA", Vector2(170, 94))
	add_label(world, "FOTO EXPRESS", Vector2(290, 120))
	add_label(world, "DEFENSORIA", Vector2(488, 116))
	# Victoria: la reja del colegio (a las 12 sale) y la Defensoría de Familia.
	add_service(world, "colegio", Vector2(556, 198), "LA REJA", Vector2(30, 14))
	add_spawn("FromColegio", Vector2(556, 210), "up")
	add_service(world, "defensoria", Vector2(488, 186), "ENTRAR")
	add_spawn("FromDefensoria", Vector2(488, 204), "down")
	add_service(world, "registraduria", Vector2(169, 186), "ENTRAR")
	add_spawn("FromRegistraduria", Vector2(169, 204), "down")
	add_service(world, "fotos", Vector2(303, 186), "FOTOS $8000")
	add_npc(world, "celador", 9, Vector2(200, 194), "down")
	pole(Vector2(110, 210))
	pole(Vector2(350, 210))
	place_anim(["lamp_on"], 1.0, Vector2(240, 290), Vector2(4, 4))
	place_anim(["lamp_on"], 1.0, Vector2(500, 290), Vector2(4, 4))

	# Plazoleta: bancos, un árbol, la fuente seca, el paradero.
	prop("bus_stop", Vector2(80, 312))
	add_service(world, "bus_centro", Vector2(80, 320), "PARADERO", Vector2(28, 14))
	add_spawn("FromBus", Vector2(80, 334), "down")
	prop("bench_broken", Vector2(200, 330))
	prop("bench_broken", Vector2(330, 360), true, true)
	tree("tree_sparse", Vector2(270, 320))
	tree("tree_dead", Vector2(560, 350))
	prop("fuente", Vector2(430, 340))
	add_service(world, "fuente", Vector2(430, 350), "FUENTE", Vector2(56, 16))
	add_spawn("FromFuente", Vector2(430, 362), "up")
	prop("cuenco", Vector2(486, 346), false)
	add_service(world, "cuenco_4", Vector2(486, 350), "AGUA", Vector2(18, 14))
	add_spawn("Spawn_cuenco_4", Vector2(486, 360), "down")
	# Para pedir: la vereda frente a Foto Express (pasa mucha gente).
	add_service(world, "pedir", Vector2(340, 204), "PEDIR", Vector2(20, 14))
	add_spawn("FromPedir", Vector2(340, 214), "down")
	prop("trash", Vector2(150, 300))
	prop("trash", Vector2(470, 300))

	# Lo que hay tirado en el centro: más latas que en el barrio (acá la gente bota más).
	for p in [Vector2(250, 334), Vector2(380, 206), Vector2(610, 330), Vector2(130, 352)]:
		add_pickup(world, "lata", p)
	for p in [Vector2(520, 300), Vector2(40, 210)]:
		add_pickup(world, "botella", p)
	add_pickup(world, "estiba", Vector2(560, 206))
	add_pickup(world, "pedazo_foto", Vector2(630, 334))  # el coleccionable
	add_pickup(world, "recorte_2", Vector2(164, 318))  # pista: el operativo
	add_pickup(world, "carton", Vector2(600, 204), 1, "Un cartón de nevera. En el centro hasta la basura es más grande.")

	var player: Node2D = load(PLAYER_SCENE).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_node(world, player)
	instance(MOOD_SCENE)
	save_scene(CENTRO_PATH)


## Una fachada con el pie en la línea del frente; la base es sólida.
func _front(art: String, center_x: float) -> void:
	var tex: Texture2D = load(ART % art)
	var w := tex.get_width()
	place(art, Vector2(center_x, FRONT), Vector2(w, 30))
	shadow_rect(Rect2(center_x - w / 2.0 + 6, FRONT - 26, w, 26))
