extends "res://tools/build_city.gd"
## Genera el Parque de San Judas (Parque.tscn): el lugar menos lúgubre del juego. Llega el bus desde
## el barrio y desde el centro. Acá se pierde el tiempo (escuchar al músico, las palomas, el ajedrez,
## una banca) y, si hace falta, se gana plata ayudando: en la iglesia (barrer, la olla comunitaria),
## en la tienda (descargar el camión), con las flores o cuidándole el puesto al de los cachivaches.
## Correr desde la carpeta del proyecto (después de build_city.gd, que arma el TileSet):
##   Godot --headless --path . -s res://tools/build_parque.gd
## OJO: sobrescribe scenes/world/Parque.tscn.

const PARQUE_PATH := "res://scenes/world/Parque.tscn"
const PW := 48
const PH := 30


func _initialize() -> void:
	build_parque(load(TILESET_PATH))
	quit()


func build_parque(ts: TileSet) -> void:
	new_location("Parque", Vector2i(PW * 16, PH * 16), "FromBus")
	ground = new_layer(ts, "Ground")
	details = new_layer(ts, "Details")
	add_shadow_layer()
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_node(scene_root, world)

	# Suelo: pasto verde (acá lo riegan), caminos de baldosa en cruz, atrio frente a la iglesia,
	# calle abajo con el paradero.
	g_rect(Rect2i(0, 0, PW, PH), GRASS)
	g_rect(Rect2i(0, 0, PW, 10), GRASS)
	g_rect(Rect2i(0, 10, PW, 3), PLAZA)
	g_rect(Rect2i(22, 13, 4, 13), PLAZA)
	g_rect(Rect2i(2, 18, 44, 3), PLAZA)
	g_rect(Rect2i(0, 26, PW, 1), WALK)
	g_rect(Rect2i(0, 27, PW, 3), ASPHALT)
	for x in range(0, PW, 2):
		g(Vector2i(x, 28), DASH_H)

	# Arriba: la iglesia, el comedor al lado, la tienda y las flores.
	_front("iglesia", 120.0, 160.0)
	add_label(world, "PARROQUIA SAN JUDAS TADEO", Vector2(120, 24))
	add_service(world, "iglesia", Vector2(120, 166), "ENTRAR")
	add_spawn("FromIglesia", Vector2(120, 182), "down")
	add_npc(world, "padre", 6, Vector2(150, 176), "down")
	_tint(Color(0.32, 0.3, 0.36))  # sotana negra
	prop("bench_green", Vector2(270, 170))
	add_npc(world, "fabiola", 3, Vector2(270, 160), "down")
	_tint(Color(1.0, 0.86, 0.72))
	add_label(world, "OLLA COMUNITARIA", Vector2(272, 138))
	# Detrás de los edificios: árboles (que no se vea un vacío).
	for x in [210, 330, 660, 740]:
		tree("tree_green" if x % 20 == 10 else "tree_green2", Vector2(x, 100))
	_front("veterinaria", 410.0, 160.0)
	add_service(world, "veterinaria", Vector2(418, 166), "VETERINARIA", Vector2(24, 14))
	add_spawn("FromVeterinaria", Vector2(418, 182), "down")
	_front("tienda", 560.0, 160.0)
	add_npc(world, "aurelio", 12, Vector2(600, 176), "down")
	_tint(Color(0.9, 0.95, 0.8))
	prop("flores", Vector2(680, 178))
	add_npc(world, "leonor", 15, Vector2(704, 176), "left")
	_tint(Color(1.0, 0.8, 0.86))

	# El parque: estatua con palomas, glorieta con el músico, ajedrez, bancas, árboles con hojas.
	prop("estatua", Vector2(384, 236))
	place_anim(["palomas_a", "palomas_b"], 3.0, Vector2(352, 252), Vector2.ZERO)
	place_anim(["palomas_b", "palomas_a"], 2.0, Vector2(420, 256), Vector2.ZERO)
	add_service(world, "palomas", Vector2(384, 254), "PALOMAS", Vector2(60, 14))
	prop("glorieta", Vector2(560, 360))
	add_npc(world, "mono", 0, Vector2(560, 340), "down")
	_tint(Color(0.86, 0.76, 0.62))
	prop("ajedrez", Vector2(176, 360))
	add_npc(world, "viejos", 12, Vector2(160, 356), "right")
	_tint(Color(0.82, 0.82, 0.86))
	add_npc(world, "viejo2", 6, Vector2(194, 356), "left")
	_tint(Color(0.9, 0.84, 0.8))
	for b in [[Vector2(260, 280), false], [Vector2(500, 280), true], [Vector2(300, 400), false], [Vector2(460, 400), true]]:
		prop("bench_green", b[0], true, b[1])
	add_service(world, "banca", Vector2(260, 290), "SENTARSE", Vector2(30, 12))
	add_service(world, "banca", Vector2(460, 410), "SENTARSE", Vector2(30, 12))
	prop("cachivaches", Vector2(660, 300), false)
	add_npc(world, "efrain", 9, Vector2(700, 290), "left")
	_tint(Color(0.78, 0.7, 0.62))
	for t in [[Vector2(40, 260), "tree_green"], [Vector2(120, 300), "tree_green2"], [Vector2(30, 372), "tree_green"],
			[Vector2(640, 420), "tree_green2"], [Vector2(740, 380), "tree_green"], [Vector2(720, 250), "tree_green2"],
			[Vector2(300, 330), "tree_green"], [Vector2(470, 330), "tree_green2"]]:
		tree(t[1], t[0])
	place_anim(["lamp_on"], 1.0, Vector2(340, 300), Vector2(4, 4))
	place_anim(["lamp_on"], 1.0, Vector2(430, 300), Vector2(4, 4))

	# Para pedir: las gradas de la iglesia (la gente sale de misa con culpa y monedas).
	add_service(world, "pedir", Vector2(88, 176), "PEDIR", Vector2(20, 12))
	add_spawn("FromPedir", Vector2(88, 188), "down")
	# Agua para Lukas (y guardar).
	prop("cuenco", Vector2(330, 438), false)
	add_service(world, "cuenco_5", Vector2(330, 442), "AGUA", Vector2(18, 14))
	add_spawn("Spawn_cuenco_5", Vector2(330, 452), "down")
	# El paradero.
	prop("bus_stop", Vector2(80, 424))
	add_service(world, "bus_parque", Vector2(80, 432), "PARADERO", Vector2(28, 14))
	add_spawn("FromBus", Vector2(80, 446), "down")
	prop("trash", Vector2(200, 418))
	prop("trash", Vector2(620, 196))

	for p in [Vector2(250, 440), Vector2(700, 440), Vector2(420, 200)]:
		add_pickup(world, "lata", p)
	add_pickup(world, "botella", Vector2(150, 230))
	add_pickup(world, "recorte_3", Vector2(42, 188), 1, "En la cartelera de la iglesia, entre avisos de bautizos, una esquina de periódico. Página 14.")
	# Los pedazos de la foto (el coleccionable): uno a la vista, uno que solo encuentra Lukas.
	add_pickup(world, "pedazo_foto", Vector2(724, 444))
	add_pickup(world, "pedazo_foto", Vector2(160, 250), 1, "", true)

	var player: Node2D = load(PLAYER_SCENE).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_node(world, player)
	instance(MOOD_SCENE)
	save_scene(PARQUE_PATH)


## Una fachada con el pie en la línea indicada; la base es sólida.
func _front(art: String, center_x: float, foot_y: float) -> void:
	var tex: Texture2D = load(ART % art)
	var w := tex.get_width()
	place(art, Vector2(center_x, foot_y), Vector2(w, 30))
	shadow_rect(Rect2(center_x - w / 2.0 + 6, foot_y - 26, w, 26))


## Tiñe al último NPC agregado (la hoja de Kenney tiene pocas personas: la ropa la cambia el tinte).
func _tint(c: Color) -> void:
	world.get_child(world.get_child_count() - 1).modulate = c
