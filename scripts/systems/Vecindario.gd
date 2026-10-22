extends Node
## Cosas del barrio que se ponen por código (lo agrega Location en los lugares de afuera):
##   - LA CAVERNA DEL GAMER, la tienda de videojuegos (City, al lado del billar), y Álvaro, "Al", que la
##     atiende: el único amigo que tiene. Abre de 10 a 8. Lo que dice: Conversations._amigo.
##   - Las canecas (trash_*, dumpster_*): se pueden esculcar (Conversations._caneca).
##   - En la esquina de la avenida, sin postes en la mitad: los semáforos y las cebras son de Traffic.gd.
##   - José Mario Camilo, en el centro, en la puerta de La Empresa: su jefe de antes. Sale después de
##     que muere Lukas (de 7 a 6) y le ofrece el último trabajo que él hace (Conversations._ultimo_trabajo).
##   - Tom Queen, el padrino (el buhonero; no habla): alguien que solo ve él. Alto,
##     bigote blanco, sombrero negro, todo de negro. Sale algunos días (más seguido entre más
##     lo busca), parado donde no hay nada. Soluciona problemas y no cobra plata: cobra en locura, y con
##     la locura se le van borrando las caras a los demás (Conversations._buhonero).
##   - El coliseo del torneo de tenis (días 32 a 35), en el potrero de arriba: por fuera, el andamio de
##     la tribuna, el pasacalle, la entrada (Torneo.puerta) y la última fila del público, que se para
##     cuando hay un punto bueno (scripts/systems/Torneo.gd, tools/art/draw_tenis_afuera.py). De 8 a 6,
##     cerca, se oye el partido desde la calle (assets/music/tenis_afuera.wav).
##   - Los otros perros. Cuando Lukas pasa cerca de un perro de la calle, se encuentran: si Lukas no
##     ha comido hoy, casi siempre pelean; si ya comió, casi siempre juegan. A veces es al revés,
##     porque sí. Una vez al día por perro.
##   - El palo de guayaba (el primer árbol con hojas de cada lugar): comida gratis. Quita poquita
##     hambre, cada una menos que la anterior, y a la tercera se hostiga (Conversations._frutas).
##     Cuando pelean, es por turnos (scripts/ui/PeleaPerros.gd). Si terminan de AMIGOS, cada vez que
##     se ven juegan y a Lukas se le alegra el día. Si terminan de ENEMIGOS, ese perro les gruñe y no
##     los deja pasar cerca: toca dar la vuelta.
## Flags: perro_visto_<nombre> (día), perros_jugo / perros_peleo (cuántas veces),
##   perro_<nombre> ("amigo" / "enemigo"), gruñido_<nombre> (día del aviso).

const SHOP_AT := Vector2(440, 200)   # el pie de la fachada
const SHOP_OPEN := 10.0
const SHOP_CLOSE := 20.0
const MEET_DIST := 30.0
const JOSE_MARIO_AT := Vector2(392, 208)  # en la puerta del edificio de vidrio
## Donde se para el buhonero: sitios donde no hay nadie.
const BUHONERO_AT := {"City": [Vector2(70, 70), Vector2(520, 130), Vector2(840, 566)]}
## Perros que no están en el mapa y salen por aquí: [nombre, textura, posición].
const STRAYS := {
	"Parque": [["dog_parque", "res://assets/barrio/dog_b.png", Vector2(388, 356)]],
}
const PLAY := [
	"(Lukas y el otro se huelen el currículum. Aprobados. Corren en círculos alrededor de nada.)",
	"(Juegan a que uno persigue y el otro también. No hay reglas ni árbitro. Funciona mejor que el fútbol.)",
	"(Se revuelcan en la tierra. Lukas sale más sucio y más contento. Las dos cosas le lucen.)",
]
const FIGHT_HUNGRY := [
	"(Lukas no ha comido. Con hambre no conoce a nadie. Se van a los dientes por un hueso que ninguno de los dos tiene.)",
	"(El otro perro olía a almuerzo. Lukas no ha almorzado. Hubo un malentendido con colmillos.)",
]
const FIGHT_RANDOM := [
	"(Se miran. Algo se dijeron, en perro. Fue grave. Se agarran.)",
	"(Ayer se caían bien. Hoy no. Los perros tampoco explican.)",
]

var _scene: Node
var _world: Node
var _dogs: Array = []
var _friend: Node2D
var _check := 0.0
var _busy := false
var _hit: AudioStreamPlayer


func _ready() -> void:
	_scene = get_parent()
	_world = _scene.get_node_or_null("World")
	if _world == null:
		_world = _scene
	_hit = AudioStreamPlayer.new()
	_hit.stream = load("res://assets/audio/hit-1.wav")
	_hit.volume_db = -10.0
	add_child(_hit)
	_setup.call_deferred()


func _setup() -> void:
	if _scene.name == "City":
		_add_shop()
		_add_feria()
		if Torneo.visible():
			_add_coliseo()
		for pole in ["pole_426_300", "pole_864_300"]:  # (estaban metidos en la avenida)
			var pn := _world.find_child(pole, false, false)
			if pn:
				pn.queue_free()
	# Los lugares con adentro (Interior.gd): la puerta entra (abierto) y adentro está quien atendía.
	for id in ["iglesia", "veterinaria", "pension", "bano", "defensoria", "registraduria", "fotos"]:
		var sp := _world.get_node_or_null("Servicio_" + id)
		if sp:
			sp.interior = id
			sp.hint = "ENTRAR"
	for n in _world.find_children("*", "", false, false):  # las canecas: esculcar
		var nm := str(n.name)
		if (nm.begins_with("trash_") or nm.begins_with("dumpster_")) and n is Node2D:
			var spot := Area2D.new()
			spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
			spot.name = "Caneca_" + nm
			spot.service_id = "caneca"
			spot.hint = "ESCULCAR"
			spot.area = Vector2(22, 16)
			spot.position = (n as Node2D).position + Vector2(0, 8)
			_world.add_child(spot)
	var f := GameState.flags
	var h := fmod(TimeManager.minutes / 60.0, 24.0)
	if _scene.name == "Centro" and not GameState.lukas_alive() and GameState.day > int(f.get("lukas_muerto", GameState.day)) \
			and not f.has("ultimo_trabajo") and h >= 7.0 and h < 18.0:
		var jm := CharacterBody2D.new()
		jm.set_script(load("res://scripts/npc/NPC.gd"))
		jm.name = "JoseMario"
		jm.npc_id = "josemario"
		jm.sheet_row = 6
		jm.face = "down"
		jm.position = JOSE_MARIO_AT
		_world.add_child(jm)
	for spec in STRAYS.get(_scene.name, []):
		var d := Sprite2D.new()
		d.name = spec[0]
		d.texture = load(spec[1])
		d.centered = false
		d.offset = Vector2(-10, -14)
		d.position = spec[2]
		_world.add_child(d)
	_add_buhonero()
	_respawn()
	var tree := _world.find_child("tree_sparse*", false, false) as Node2D
	if tree:
		for at in [Vector2(-9, -34), Vector2(6, -40), Vector2(11, -28), Vector2(-3, -26)]:  # las guayabas
			var g := ColorRect.new()
			g.size = Vector2(2, 2)
			g.color = Color(0.95, 0.82, 0.3)
			g.position = at
			tree.add_child(g)
		var spot := Area2D.new()
		spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
		spot.name = "Servicio_frutas"
		spot.service_id = "frutas"
		spot.hint = "GUAYABAS"
		spot.area = Vector2(30, 16)
		spot.position = tree.position + Vector2(0, 8)
		_world.add_child(spot)
	for n in _world.find_children("dog_*", "", false, false):
		if n is Node2D:
			_dogs.append(n)


## El buhonero: algunos días, en un sitio solo. Un día sí lo sacó la suerte, otro no (la misma todo el día).
## Lo que se pone aquí (la puerta de La Caverna, la de la feria) llega después de que Location ubicó al
## jugador: si venía de salir por una de esas puertas, quedó en el puente. Se le pone en su puerta.
func _respawn() -> void:
	var sp := SceneRouter.spawn_point
	if sp == "" or not (_scene is Location):
		return
	var at := _scene.get_node_or_null(sp) as Node2D
	var player: Node2D = _scene.player
	if at == null or player == null or player.global_position.distance_to(at.global_position) < 1.0:
		return
	player.global_position = at.global_position
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.reset_smoothing()


func _add_buhonero() -> void:
	var spots: Array = BUHONERO_AT.get(_scene.name, [])
	var f := GameState.flags
	if spots.is_empty() or GameState.day < 3 or f.get("buhonero_dia", -1) == GameState.day:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("buhonero%d" % GameState.day)
	if rng.randf() > minf(0.3 + 0.05 * int(f.get("buhonero_n", 0)), 0.75):
		return
	var b := CharacterBody2D.new()
	b.set_script(load("res://scripts/npc/NPC.gd"))
	b.name = "Buhonero"
	b.npc_id = "buhonero"
	b.sheet_row = 9
	b.face = "down"
	b.position = spots[rng.randi() % spots.size()]
	_world.add_child(b)
	_haunt.call_deferred(b)


## No es de aquí: más alto que todos, y titila un poco.
func _haunt(b: Node2D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(b):
		return
	var sp: Node2D = b.get("sprite")
	sp.scale = Vector2(1.0, 1.08)
	sp.position.y -= 1.0
	var t := sp.create_tween().set_loops()
	t.tween_property(sp, "modulate:a", 0.55, 0.9)
	t.tween_property(sp, "modulate:a", 1.0, 0.9)


func _add_shop() -> void:
	var shop := Sprite2D.new()
	shop.name = "videojuegos"
	shop.texture = load("res://assets/barrio/videojuegos.png")
	shop.centered = false
	shop.offset = Vector2(-55, -70)
	shop.position = SHOP_AT
	_world.add_child(shop)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(108, 26)
	shape.shape = rect
	shape.position = Vector2(0, -14)
	body.add_child(shape)
	shop.add_child(body)
	# La puerta: Al está adentro (Interior.gd, "caverna"). Cerrado, la puerta dice que está cerrado.
	var door := Area2D.new()
	door.set_script(load("res://scripts/world/ServiceSpot.gd"))
	door.name = "Servicio_caverna"
	door.service_id = "caverna_cerrada"
	door.hint = "ENTRAR"
	door.area = Vector2(24, 16)
	door.position = SHOP_AT + Vector2(32, 8)
	door.interior = "caverna"
	_world.add_child(door)
	_shop_hours()


## La feria del lote de atrás del billar: el arco con bombillos, la rueda de Chicago y, por encima de
## la reja, todo lo de adentro (tools/art/draw_feria_lote.py): la montaña rusa con su carrito, el
## carrusel con los caballitos, los chocones, la garra, los dardos, las obleas. Abierta (de 16 a 24),
## todo se mueve; de noche, los bombillos. Cerrada, quieto. La feria por dentro: scenes/world/Feria.tscn.
const FERIA_AT := Vector2(790, 100)
const RUEDA_AT := Vector2(890, 78)
const FERIA_LOTE := Vector2(690, 0)
const CHOCONES := [Color(0.85, 0.2, 0.25), Color(0.25, 0.55, 0.9), Color(0.95, 0.8, 0.2), Color(0.3, 0.75, 0.4), Color(0.85, 0.4, 0.8)]


func _add_feria() -> void:
	var info: Dictionary = (load("res://assets/barrio/feria_lote.json") as JSON).data  # (como recurso: así va en la versión web)
	var back := Sprite2D.new()
	back.name = "feria_lote"
	back.texture = load("res://assets/barrio/feria_lote.png")
	back.centered = false
	back.position = FERIA_LOTE
	_world.add_child(back)
	var rides := Node2D.new()  # lo que se mueve, entre las dos capas
	rides.name = "feria_juegos"
	rides.position = FERIA_LOTE
	var cars: Array = []
	for i in CHOCONES.size():
		cars.append({"p": Vector2(info["rink"][0] + 6 + i * 13, info["rink"][1] + 4 + (i % 2) * 10),
			"v": Vector2.from_angle(i * 1.7) * 18.0})
	rides.draw.connect(func() -> void: _draw_rides(rides, info, cars))
	_world.add_child(rides)
	var front := Sprite2D.new()
	front.name = "feria_frente"
	front.texture = load("res://assets/barrio/feria_frente.png")
	front.centered = false
	front.position = FERIA_LOTE
	_world.add_child(front)
	var body := StaticBody2D.new()  # adentro se entra por el arco, no por encima de la reja
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(330, 90)
	shape.shape = rect
	shape.position = FERIA_LOTE + Vector2(165, 45)
	body.add_child(shape)
	_world.add_child(body)
	var anim := Timer.new()
	anim.wait_time = 1.0 / 30.0
	anim.autostart = true
	anim.timeout.connect(func() -> void:
		if Feria_open():
			for c in cars:
				var r: Array = info["rink"]
				c["p"] += c["v"] * anim.wait_time
				if c["p"].x < r[0] + 3 or c["p"].x > r[2] - 3:
					c["v"].x *= -1.0
				if c["p"].y < r[1] + 2 or c["p"].y > r[3] - 2:
					c["v"].y *= -1.0
				c["p"] = c["p"].clamp(Vector2(r[0] + 3, r[1] + 2), Vector2(r[2] - 3, r[3] - 2))
				if randf() < 0.01:
					c["v"] = c["v"].rotated(randf_range(-1.2, 1.2))
		rides.queue_redraw())
	add_child(anim)
	var wheel := Node2D.new()
	wheel.name = "rueda_feria"
	wheel.position = RUEDA_AT
	wheel.draw.connect(func() -> void:
		var on := Feria_open()
		var t := Time.get_ticks_msec() / 1000.0
		var hub := Vector2(0, -44)
		wheel.draw_line(hub, Vector2(-14, 0), Color(0.5, 0.5, 0.56), 2.0)
		wheel.draw_line(hub, Vector2(14, 0), Color(0.5, 0.5, 0.56), 2.0)
		wheel.draw_arc(hub, 36, 0, TAU, 32, Color(0.62, 0.62, 0.7), 2.0)
		for i in 8:
			var a := (t * 0.25 if on else 0.3) + i * TAU / 8.0
			var p := hub + Vector2(cos(a), sin(a)) * 36.0
			wheel.draw_line(hub, p, Color(0.55, 0.55, 0.62), 1.0)
			wheel.draw_rect(Rect2(p + Vector2(-3, 0), Vector2(6, 4)), Color.from_hsv(i / 8.0, 0.6, 0.85 if on else 0.45))
			if on:
				wheel.draw_circle(p, 1.3, Color(1, 0.95, 0.6) if int(t * 3.0 + i) % 2 == 0 else Color(1, 0.4, 0.5)))
	_world.add_child(wheel)
	var arch := Node2D.new()
	arch.name = "arco_feria"
	arch.position = FERIA_AT
	arch.draw.connect(func() -> void:
		var on := Feria_open()
		var t := Time.get_ticks_msec() / 1000.0
		arch.draw_rect(Rect2(-24, -30, 3, 30), Color(0.8, 0.7, 0.3))
		arch.draw_rect(Rect2(21, -30, 3, 30), Color(0.8, 0.7, 0.3))
		arch.draw_rect(Rect2(-28, -38, 56, 10), Color(0.8, 0.2, 0.25) if on else Color(0.45, 0.2, 0.22))
		arch.draw_string(load("res://assets/fonts/PressStart2P.ttf"), Vector2(-20, -30), "FERIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.95, 0.7) if on else Color(0.6, 0.55, 0.5))
		for i in 12:
			var lit := on and int(t * 4.0 + i) % 3 != 0
			arch.draw_circle(Vector2(-26 + i * 4.7, -40), 1.1, Color.from_hsv(fmod(i * 0.21, 1.0), 0.7, 1.0) if lit else Color(0.35, 0.33, 0.3)))
	_world.add_child(arch)
	var spot := Area2D.new()
	spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
	spot.name = "Servicio_feria"
	spot.service_id = "feria"
	spot.hint = "FERIA"
	spot.area = Vector2(40, 18)
	spot.position = FERIA_AT + Vector2(0, 4)
	_world.add_child(spot)
	var redraw := Timer.new()  # los bombillos titilan
	redraw.wait_time = 0.15
	redraw.autostart = true
	redraw.timeout.connect(func() -> void:
		wheel.queue_redraw()
		arch.queue_redraw())
	add_child(redraw)


func _draw_rides(n: Node2D, info: Dictionary, cars: Array) -> void:
	var on := Feria_open()
	var t := Time.get_ticks_msec() / 1000.0
	var ink := Color(0.13, 0.1, 0.14)
	# La montaña rusa: el carrito recorre el riel (sube despacio, baja rápido) y espera en la estación.
	var track: Array = info["track"]
	var pos := Vector2(track[0][0] + 6, track[0][1])
	if on:
		var total := 0.0
		for i in track.size() - 1:
			total += Vector2(track[i][0], track[i][1]).distance_to(Vector2(track[i + 1][0], track[i + 1][1]))
		var lap := fmod(t, 9.0)
		var d := 0.0 if lap > 6.5 else total * ease(lap / 6.5, 1.8)
		for i in track.size() - 1:
			var a := Vector2(track[i][0], track[i][1])
			var b := Vector2(track[i + 1][0], track[i + 1][1])
			var seg := a.distance_to(b)
			if d <= seg:
				pos = a.lerp(b, d / seg)
				break
			d -= seg
	n.draw_rect(Rect2(pos + Vector2(-4, -4), Vector2(9, 4)), ink)
	n.draw_rect(Rect2(pos + Vector2(-3, -3), Vector2(7, 2)), Color(0.95, 0.8, 0.2))
	if on:  # los de adentro, con los brazos arriba
		for k in [-2, 2]:
			n.draw_rect(Rect2(pos + Vector2(k, -6), Vector2(1, 2)), Color(0.85, 0.62, 0.5))
			n.draw_rect(Rect2(pos + Vector2(k, -8), Vector2(1, 1)), Color(0.85, 0.62, 0.5))
	# El carrusel: seis caballitos alrededor del eje, subiendo y bajando en sus tubos.
	var cc: Array = info["carrusel"]
	var turn := t * 0.7 if on else 0.4
	var horses: Array = []
	for i in 6:
		var a := turn + i * TAU / 6.0
		horses.append([sin(a), a, i])
	horses.sort_custom(func(p, q): return p[0] < q[0])  # los de atrás primero
	for hz in horses:
		var a: float = hz[1]
		var x: float = float(cc[0]) + cos(a) * (float(cc[2]) - 6.0)
		var y: float = float(cc[1]) - 12.0 + sin(a) * 3.0 + (sin(t * 3.0 + hz[2]) * 2.0 if on else 0.0)
		var dim := 0.75 if hz[0] < 0.0 else 1.0
		n.draw_line(Vector2(x, float(cc[1]) - 27.0), Vector2(x, float(cc[1]) - 3.0 + sin(a) * 3.0), Color(0.85, 0.7, 0.3) * dim, 1.0)
		var face := 1.0 if cos(a + PI / 2.0) > 0.0 else -1.0
		var col: Color = [Color(0.95, 0.94, 0.9), Color(0.55, 0.35, 0.25), Color(0.95, 0.94, 0.9)][int(hz[2]) % 3] * dim
		n.draw_rect(Rect2(x - 3, y - 1, 6, 3), ink)
		n.draw_rect(Rect2(x - 2, y, 4, 1), col)
		n.draw_rect(Rect2(x + 2.0 * face - (1.0 if face < 0 else 0.0), y - 3, 2, 3), col)    # el cuello y la cabeza
		n.draw_rect(Rect2(x - 2, y + 2, 1, 2), col)                                           # las patas
		n.draw_rect(Rect2(x + 1, y + 2, 1, 2), col)
		n.draw_rect(Rect2(x - 1, y - 1, 2, 1), Color(0.85, 0.2, 0.3) * dim)                   # la silla
	# Los chocones: cada carrito con su tubo a la malla; abierto, chispas arriba.
	var rink: Array = info["rink"]
	for i in cars.size():
		var p: Vector2 = cars[i]["p"] if on else Vector2(rink[0] + 6 + i * 13, rink[3] - 4)
		n.draw_rect(Rect2(p + Vector2(-4, -2), Vector2(8, 5)), ink)
		n.draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 3)), CHOCONES[i])
		n.draw_rect(Rect2(p + Vector2(-1, -2), Vector2(2, 1)), Color(0.85, 0.62, 0.5))
		n.draw_line(p + Vector2(2, -2), Vector2(p.x + 2, float(rink[1]) - 10.0), Color(0.4, 0.4, 0.45), 1.0)
		if on and int(t * 10.0 + i * 3) % 7 == 0:
			n.draw_rect(Rect2(p.x + 1, float(rink[1]) - 11.0, 3, 2), Color(0.7, 0.9, 1.0))
	# Los bombillos: de noche (abierta), titilando en tandas.
	if on and (TimeManager.hour() >= 17 or TimeManager.hour() < 1):
		var bulbs: Array = info["bulbs"]
		for i in bulbs.size():
			var lit := int(t * 4.0 + i) % 3 != 0
			var c := Color.from_hsv(fmod(i * 0.17, 1.0), 0.6, 1.0) if lit else Color(0.4, 0.36, 0.3)
			n.draw_rect(Rect2(float(bulbs[i][0]), float(bulbs[i][1]), 1, 1), c)
			if lit:
				n.draw_rect(Rect2(float(bulbs[i][0]) - 1, float(bulbs[i][1]) - 1, 3, 3), Color(c.r, c.g, c.b, 0.25))


## El coliseo (solo los días del torneo). En el potrero de arriba, entre la Caverna y el billar.
const COLISEO_AT := Vector2(318, 0)
const PUBLICO := [Color(0.85, 0.25, 0.3), Color(0.95, 0.85, 0.3), Color(0.3, 0.5, 0.85), Color(0.92, 0.92, 0.88),
	Color(0.35, 0.7, 0.45), Color(0.95, 0.55, 0.25), Color(0.6, 0.4, 0.75)]


func _add_coliseo() -> void:
	var info: Dictionary = (load("res://assets/barrio/coliseo_afuera.json") as JSON).data
	var back := Sprite2D.new()
	back.name = "coliseo_afuera"
	back.texture = load("res://assets/barrio/coliseo_afuera.png")
	back.centered = false
	back.position = COLISEO_AT
	_world.add_child(back)
	# Lo que se mueve: el público de la última fila (de espaldas, con las cabezas), los banderines y los
	# reflectores de noche.
	var top := Node2D.new()
	top.name = "coliseo_vivo"
	top.position = COLISEO_AT
	top.draw.connect(func() -> void: _draw_coliseo(top, info))
	_world.add_child(top)
	var body := StaticBody2D.new()  # se entra por la entrada, no por el andamio
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var blk: Array = info["block"]
	rect.size = Vector2(float(blk[2]) - float(blk[0]), float(blk[3]) - float(blk[1]))
	shape.shape = rect
	shape.position = COLISEO_AT + Vector2(float(blk[0]), float(blk[1])) + rect.size * 0.5
	body.add_child(shape)
	_world.add_child(body)
	var spot := Area2D.new()
	spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
	spot.name = "Servicio_torneo"
	spot.service_id = "torneo"
	spot.hint = "COLISEO"
	spot.area = Vector2(30, 16)
	spot.position = COLISEO_AT + Vector2(float(info["gate"][0]), float(info["gate"][1]) + 4.0)
	_world.add_child(spot)
	var redraw := Timer.new()
	redraw.wait_time = 0.1
	redraw.autostart = true
	redraw.timeout.connect(func() -> void: top.queue_redraw())
	add_child(redraw)
	# El partido, como se oye desde la calle (sin agudos, con el público): solo cerca, y solo cuando juegan.
	var rock := AudioStreamPlayer2D.new()
	var stream: AudioStreamWAV = load("res://assets/music/tenis_afuera.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	rock.stream = stream
	rock.bus = MusicDirector.BUS
	rock.volume_db = -4.0
	rock.max_distance = 260.0
	rock.attenuation = 1.6
	rock.position = COLISEO_AT + Vector2(140, 60)
	_world.add_child(rock)
	var on_air := func() -> void:
		var h := TimeManager.hour()
		var want := h >= TenisHistoria.ABRE and h < TenisHistoria.CIERRA
		if want and not rock.playing:
			rock.play()
		elif not want and rock.playing:
			rock.stop()
	on_air.call()
	var air := Timer.new()
	air.wait_time = 2.0
	air.autostart = true
	air.timeout.connect(on_air)
	add_child(air)
	# Cerca del coliseo manda el partido: el tema del barrio se va apartando (dos músicas a la vez, no).
	var near := Timer.new()
	near.wait_time = 0.25
	near.autostart = true
	near.timeout.connect(func() -> void:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var k := 0.0
		if rock.playing and player:
			k = clampf(1.0 - player.global_position.distance_to(rock.global_position) / rock.max_distance, 0.0, 1.0)
		MusicDirector.duck(pow(k, 0.7)))
	add_child(near)


func _draw_coliseo(n: Node2D, info: Dictionary) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var h := TimeManager.hour()
	var playing := h >= TenisHistoria.ABRE and h < TenisHistoria.CIERRA
	# El público de la última fila: cabezas de espaldas (pelo), y cada tanto se paran con los brazos arriba.
	var crowd: Array = info["crowd"]
	var cheer := playing and fmod(t, 7.0) < 1.2
	if playing:
		var x := float(crowd[0])
		var i := 0
		while x < float(crowd[2]):
			if (i * 7) % 11 != 3:  # algún puesto vacío
				var up := 2.0 if cheer and (i % 3 != 1) else 0.0
				var bob := 1.0 if fmod(t * 2.0 + i * 0.37, 2.0) < 0.15 else 0.0
				var y := float(crowd[1]) - up - bob
				var shirt: Color = PUBLICO[(i * 5) % PUBLICO.size()]
				n.draw_rect(Rect2(x - 1, y - 2, 3, 2), shirt)                                  # los hombros
				n.draw_rect(Rect2(x - 0.5, y - 4, 2, 2), [Color(0.2, 0.16, 0.14), Color(0.45, 0.3, 0.2), Color(0.8, 0.7, 0.45)][i % 3])
				if cheer and i % 3 == 0:  # los brazos arriba
					n.draw_rect(Rect2(x - 2, y - 6, 1, 3), Color(0.85, 0.62, 0.5))
					n.draw_rect(Rect2(x + 2, y - 6, 1, 3), Color(0.85, 0.62, 0.5))
			x += 4.0
			i += 1
	# Los banderines: de torre a torre, colgando, moviéndose con el viento.
	var fl: Array = info["flags"]
	var a := Vector2(float(fl[0][0]), 3.0)
	var b := Vector2(float(fl[1][0]), 3.0)
	var count := 34
	for k in count:
		var u := (k + 0.5) / count
		var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * 5.0)
		var wave := sin(t * 3.0 + k * 0.8) * 0.8
		var c: Color = [Color(0.85, 0.2, 0.25), Color(0.98, 0.84, 0.3), Color(0.12, 0.1, 0.14)][k % 3]
		n.draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(wave, 3.5)]), c)
	n.draw_polyline(PackedVector2Array([a, a.lerp(b, 0.25) + Vector2(0, sin(0.25 * PI) * 5.0), a.lerp(b, 0.5) + Vector2(0, 5.0),
		a.lerp(b, 0.75) + Vector2(0, sin(0.75 * PI) * 5.0), b]), Color(0.3, 0.28, 0.32), 1.0)
	# Los reflectores: prendidos al atardecer y de noche (la feria de al lado también).
	if h >= 17 or h < 1:
		for l in info["lamps"]:
			var c := Vector2(float(l[0]) + 1.0, float(l[1]) + 1.0)
			n.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.98, 0.85))
			n.draw_circle(c, 4.0, Color(1, 0.95, 0.7, 0.18))


static func Feria_open() -> bool:
	return TimeManager.hour() >= 16


func _shop_hours() -> void:
	if _world == null:
		return
	var h := fmod(TimeManager.minutes / 60.0, 24.0)
	var open := h >= SHOP_OPEN and h < SHOP_CLOSE
	var shop := _world.get_node_or_null("videojuegos") as CanvasItem
	if shop:
		shop.self_modulate = Color.WHITE if open else Color(0.55, 0.55, 0.65)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.3
	_shop_hours()
	if _busy or Dialogue.active or GameState.ui_open or SceneRouter.busy or GameState.input_blocked():
		return
	var lukas := _scene.find_child("Lukas", true, false) as Node2D
	if lukas == null or not GameState.lukas_alive() or not str(lukas.get("state")) in ["follow", "sit"]:
		return
	var player := _scene.get("player") as Node2D
	for d in _dogs:
		if not is_instance_valid(d) or not d.visible:
			continue
		if GameState.flags.get("perro_" + str(d.name), "") == "enemigo":
			if player and d.global_position.distance_to(player.global_position) < 26.0:
				_growl(d, player)
				return
			continue
		var key := "perro_visto_" + str(d.name)
		if GameState.flags.get(key, -1) == GameState.day:
			continue
		if d.global_position.distance_to(lukas.global_position) < MEET_DIST:
			GameState.flags[key] = GameState.day
			_meet(lukas, d)
			return


## Un perro enemigo: gruñe y los saca de ahí (un empujoncito para atrás). Que den la vuelta.
func _growl(dog: Node2D, player: Node2D) -> void:
	var away := (player.global_position - dog.global_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.DOWN
	player.global_position += away * 10.0
	GameState.block_input(0.4)
	_hit.play()
	var l := Label.new()
	l.add_to_group("texto_mundo")  # (Hud: no se monta sobre otro texto)
	l.text = "GRRR"
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.position = Vector2(-16, -26)
	l.z_index = 50
	dog.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", -36.0, 0.8)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)
	var key := "gruñido_" + str(dog.name)
	if GameState.flags.get(key, -1) != GameState.day:
		GameState.flags[key] = GameState.day
		Narrator.say("(%s les gruñe. Se acuerda. No los deja pasar por ahí: toca dar la vuelta.)" % PeleaPerros.dog_name(str(dog.name)), false, "lukas_triste")


## Lukas y otro perro: juegan o pelean. Con hambre, casi siempre pelean. Si ya son amigos, juegan.
## La pelea empieza con el agarrón de siempre y sigue por turnos (PeleaPerros).
func _meet(lukas: Node2D, dog: Node2D) -> void:
	_busy = true
	var f := GameState.flags
	var hungry: bool = f.get("lukas_fed_day", -1) != GameState.day
	var friends: bool = f.get("perro_" + str(dog.name), "") == "amigo"
	var fight: bool = not friends and randf() < (0.65 if hungry else 0.15)
	GameState.block_input(2.2)
	lukas.set_physics_process(false)
	var l0 := lukas.position
	var d0 := dog.position
	var mid := (l0 + d0) / 2.0
	if fight:
		for k in 2:  # se van encima, se sueltan, otra vez
			var t := create_tween().set_parallel()
			t.tween_property(lukas, "position", mid + Vector2(-3, 0), 0.08)
			t.tween_property(dog, "position", mid + Vector2(3, 0), 0.08)
			await t.finished
			_hit.play()
			lukas.modulate = Color(1.0, 0.6, 0.6)
			dog.modulate = Color(1.0, 0.6, 0.6)
			var back := create_tween().set_parallel()
			back.tween_property(lukas, "position", mid + Vector2(-11, randf_range(-3, 3)), 0.1)
			back.tween_property(dog, "position", mid + Vector2(11, randf_range(-3, 3)), 0.1)
			await back.finished
			lukas.modulate = Color.WHITE
			dog.modulate = Color.WHITE
	else:
		var spin := create_tween()  # se persiguen en círculo
		spin.tween_method(func(a: float) -> void:
			lukas.position = mid + Vector2(cos(a), sin(a) * 0.6) * 13.0
			dog.position = mid - Vector2(cos(a), sin(a) * 0.6) * 13.0, 0.0, TAU * 2.5, 1.8)
		await spin.finished
	var home := create_tween().set_parallel()
	home.tween_property(lukas, "position", l0, 0.2)
	home.tween_property(dog, "position", d0, 0.2)
	await home.finished
	lukas.set_physics_process(true)
	if fight:
		f["perros_peleo"] = int(f.get("perros_peleo", 0)) + 1
		await Dialogue.talk([["", (FIGHT_HUNGRY if hungry else FIGHT_RANDOM).pick_random()]])
		var tex: Texture2D = dog.texture if dog is Sprite2D else load("res://assets/barrio/dog_a.png")
		var r := await PeleaPerros.fight(self, str(dog.name), tex)
		if r in ["amigo", "enemigo"]:
			f["perro_" + str(dog.name)] = r
		if r == "amigo":
			GameState.change_mood(5.0)
			GameState.company(6.0)
		elif r == "enemigo":
			GameState.change_mood(-3.0)
	else:
		f["perros_jugo"] = int(f.get("perros_jugo", 0)) + 1
		if friends:  # su amigo: Lukas lo ve de lejos y se le alegra todo
			Narrator.say("(Lukas ve a %s de lejos y sale corriendo. Su amigo. Juegan hasta que se les acaba el aire.)" % PeleaPerros.dog_name(str(dog.name)), false, "lukas_feliz")
			GameState.change_mood(6.0)
		else:
			await Dialogue.talk([["", PLAY.pick_random()]])
			GameState.change_mood(4.0)
		GameState.company(6.0)
	_busy = false
