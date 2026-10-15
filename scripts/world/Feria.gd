extends Location
## La feria del lote, detrás del billar (de cuatro de la tarde a medianoche). Un pueblo de fierros y
## bombillos: los carros chocones, el carrusel, la montaña rusa, los dardos, la garra de los peluches y
## la rueda de Chicago. Cada cosa es un juego (scripts/ui/FeriaJuegos.gd) y cuesta lo que cuesta.
## Arriba de la rueda, él se acuerda de una fiesta de antes (FeriaJuegos.rueda).
## Se entra por el arco de la calle (Vecindario: Servicio_feria) y se sale por el mismo arco.

const W := 512
const H := 200
## [service_id, letrero, posición, tamaño del letrero]
const RIDES := [
	["feria_carrusel", "CARRUSEL $1000", Vector2(92, 126), Vector2(40, 18)],
	["feria_chocones", "CHOCONES $2000", Vector2(214, 126), Vector2(40, 18)],
	["feria_montana", "MONTAÑA $3000", Vector2(310, 92), Vector2(40, 18)],
	["feria_dardos", "DARDOS $1000", Vector2(150, 178), Vector2(30, 14)],
	["feria_garra", "GARRA $500", Vector2(262, 178), Vector2(24, 14)],
	["feria_rueda", "RUEDA $2000", Vector2(430, 150), Vector2(36, 18)],
]
const PEOPLE := [
	{"row": 15, "path": [Vector2(60, 160), Vector2(180, 164), Vector2(120, 186)], "wait": 3.0,
		"say": ["—¡Mamá, la montaña! ¡La montaña! ... ¿Y si vomito? ... ¡La montaña!", "(se come el algodón de azúcar con la cara entera)"],
		"talk": ["—¿Usted se monta en la rueda? Mi papá dice que da miedo. Mi papá le tiene miedo a todo. Hasta a mi mamá."]},
	{"row": 6, "path": [Vector2(360, 170), Vector2(400, 176)], "wait": 6.0,
		"say": ["—¿Me ganas un peluche? ... ¿Otro? Ya llevamos cuarenta mil en peluches.", "(se toman una foto con el celular. Salen borrosos. Se ríen)"],
		"talk": ["—Estamos de novios. Tres semanas. No le cuente a nadie. Bueno, cuéntele a todo el mundo."]},
	{"row": 12, "path": [Vector2(470, 132)], "pose": "down",
		"say": ["—¡Rueda de Chicago! ¡Se ve hasta la casa de su ex!", "(aceita la rueda con una aceitera de mano. La rueda chilla igual)"],
		"talk": ["—Dos mil, y le doy dos vueltas. Arriba se ve todo el barrio. Lo bueno y lo otro."]},
	{"row": 9, "path": [Vector2(20, 120), Vector2(40, 118)], "wait": 8.0,
		"say": ["(se tambalea con una pola en la mano. La feria le da vueltas sin montarse en nada)", "—¡Esta feria era mejor en el noventa y ocho!"],
		"talk": ["—¿Quiere una? ... ¿No? Usted se lo pierde. Yo también me lo pierdo, pero de otra forma."]},
]

var _t := 0.0
var _room: Node2D


static func is_open() -> bool:
	return TimeManager.hour() >= 16


func _ready() -> void:
	area_size = Vector2i(W, H)
	get_node("Start").position = Vector2(40, H - 14)
	_room = Node2D.new()
	_room.name = "Feria"
	_room.z_index = -5
	_room.draw.connect(_draw_fair)
	add_child(_room)
	# Lo que no se atraviesa: el carrusel, la pista de los chocones, la montaña, los puestos, la rueda.
	var solid := StaticBody2D.new()
	for r in [Rect2(62, 88, 60, 30), Rect2(176, 84, 76, 34), Rect2(280, 40, 60, 44), Rect2(130, 156, 40, 12), Rect2(246, 156, 32, 12), Rect2(404, 120, 52, 20)]:
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		sh.shape = rect
		sh.position = r.position + r.size / 2.0
		solid.add_child(sh)
	add_child(solid)
	for ride in RIDES:
		var a := Area2D.new()
		a.set_script(load("res://scripts/world/ServiceSpot.gd"))
		a.name = ride[0]
		a.service_id = ride[0]
		a.hint = ride[1]
		a.position = ride[2]
		a.area = ride[3]
		add_child(a)
	for spec in PEOPLE:
		var v := Vecino.new()
		v.spec = spec
		add_child(v)
	var back: Array = GameState.flags.get("feria_volver", ["res://scenes/world/City.tscn", ""])
	var door := Area2D.new()
	door.set_script(load("res://scripts/world/Door.gd"))
	door.name = "Salida"
	door.target_scene = back[0]
	door.target_spawn = back[1]
	door.push_dir = Vector2.DOWN
	door.position = Vector2(40, H - 4)
	var dsh := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(28, 10)
	dsh.shape = drect
	door.add_child(dsh)
	add_child(door)
	super._ready()
	if not GameState.flags.get("feria_vista", false):
		GameState.flags["feria_vista"] = true
		Narrator.say("(La feria. Huele a fritanga y a gasolina. Los bombillos de colores hacen que todo el mundo se vea más bonito. Hasta él.)")


func _process(delta: float) -> void:
	_t += delta
	_room.queue_redraw()


## Toda la feria, a mano: el cielo de noche, los bombillos, y cada atracción moviéndose.
func _draw_fair() -> void:
	var r := _room
	# El cielo (arriba, detrás de todo) y el piso de tierra.
	r.draw_rect(Rect2(0, 0, W, 60), Color(0.08, 0.06, 0.18))
	for i in 30:
		r.draw_rect(Rect2(fmod(i * 97.0, W), fmod(i * 37.0, 50.0), 1, 1), Color(1, 1, 0.9, 0.5 + 0.5 * sin(_t * 2.0 + i)))
	r.draw_rect(Rect2(0, 60, W, H - 60), Color(0.36, 0.28, 0.22))
	for i in 60:  # papelitos en el piso
		var c := Color.from_hsv(fmod(i * 0.13, 1.0), 0.6, 0.9)
		r.draw_rect(Rect2(fmod(i * 53.0, W), 64 + fmod(i * 31.0, H - 66), 2, 1), c)
	# La montaña rusa: la carrilera al fondo y el carrito.
	var track := PackedVector2Array()
	for x in range(260, 372, 4):
		track.append(Vector2(x, 70 - 26 * absf(sin((x - 260) * 0.045))))
	for i in range(0, track.size(), 3):
		r.draw_line(track[i], Vector2(track[i].x, 84), Color(0.55, 0.55, 0.6), 1.0)
	r.draw_polyline(track, Color(0.85, 0.3, 0.3), 2.0)
	var k := int(fmod(_t * 14.0, track.size()))
	r.draw_rect(Rect2(track[k] + Vector2(-4, -5), Vector2(8, 5)), Color(0.95, 0.85, 0.3))
	# La rueda de Chicago: grande, a la derecha, girando despacio.
	var hub := Vector2(430, 64)
	r.draw_line(hub, Vector2(412, 132), Color(0.6, 0.6, 0.66), 2.0)
	r.draw_line(hub, Vector2(448, 132), Color(0.6, 0.6, 0.66), 2.0)
	r.draw_arc(hub, 52, 0, TAU, 40, Color(0.75, 0.75, 0.82), 2.0)
	for i in 10:
		var a := _t * 0.25 + i * TAU / 10.0
		var p := hub + Vector2(cos(a), sin(a)) * 52.0
		r.draw_line(hub, p, Color(0.7, 0.7, 0.78), 1.0)
		r.draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 6)), Color.from_hsv(i / 10.0, 0.7, 0.9))
		r.draw_circle(p, 1.5, Color(1, 0.95, 0.6) if int(_t * 3.0 + i) % 2 == 0 else Color(1, 0.4, 0.5))
	r.draw_rect(Rect2(404, 128, 52, 12), Color(0.45, 0.3, 0.2))  # la plataforma y la boletería
	# El carrusel: techo de rayas, caballitos que suben y bajan.
	var cc := Vector2(92, 104)
	r.draw_rect(Rect2(cc + Vector2(-30, -2), Vector2(60, 14)), Color(0.55, 0.36, 0.24))
	for i in 6:
		var a := _t * 1.2 + i * TAU / 6.0
		var hx := cc.x + cos(a) * 24.0
		var hy := cc.y + sin(a) * 6.0 - 6.0 + sin(_t * 4.0 + i) * 2.0
		if sin(a) < 0.0:
			r.draw_line(Vector2(hx, cc.y - 22), Vector2(hx, hy), Color(0.9, 0.85, 0.5))
			r.draw_rect(Rect2(hx - 4, hy - 3, 8, 5), Color.from_hsv(i / 6.0, 0.4, 0.95))
	for i in 6:
		var a := _t * 1.2 + i * TAU / 6.0
		var hx := cc.x + cos(a) * 24.0
		var hy := cc.y + sin(a) * 6.0 - 6.0 + sin(_t * 4.0 + i) * 2.0
		if sin(a) >= 0.0:
			r.draw_line(Vector2(hx, cc.y - 22), Vector2(hx, hy), Color(0.9, 0.85, 0.5))
			r.draw_rect(Rect2(hx - 4, hy - 3, 8, 5), Color.from_hsv(i / 6.0, 0.4, 0.95))
	var roof := PackedVector2Array([cc + Vector2(-34, -20), cc + Vector2(0, -34), cc + Vector2(34, -20)])
	r.draw_colored_polygon(roof, Color(0.9, 0.3, 0.35))
	for i in 5:
		r.draw_line(cc + Vector2(0, -34), cc + Vector2(-34 + i * 17, -20), Color(0.98, 0.95, 0.9), 1.0)
	# Los chocones: la pista con la malla de chispas arriba y los carritos.
	r.draw_rect(Rect2(176, 84, 76, 34), Color(0.2, 0.2, 0.26))
	r.draw_rect(Rect2(176, 84, 76, 34), Color(0.9, 0.8, 0.3), false, 1.0)
	for i in 4:
		var p := Vector2(214 + cos(_t * (0.8 + i * 0.3) + i) * 28.0, 101 + sin(_t * (1.1 + i * 0.2) + i * 2.0) * 10.0)
		r.draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 6)), Color.from_hsv(i * 0.27, 0.8, 0.9))
		r.draw_line(p, Vector2(p.x, 80), Color(0.6, 0.6, 0.6), 1.0)
	if int(_t * 7.0) % 5 == 0:
		r.draw_circle(Vector2(214 + sin(_t * 13.0) * 30.0, 80), 2.0, Color(0.7, 0.85, 1.0))
	# Los puestos: dardos (globos en la pared) y la garra (la vitrina con peluches).
	r.draw_rect(Rect2(130, 140, 40, 22), Color(0.3, 0.5, 0.75))
	r.draw_rect(Rect2(130, 136, 40, 5), Color(0.95, 0.95, 0.9))
	for i in 6:
		r.draw_circle(Vector2(136 + (i % 3) * 13, 146 + (i / 3) * 8), 3.0, Color.from_hsv(i * 0.17, 0.75, 0.95))
	r.draw_rect(Rect2(246, 136, 32, 26), Color(0.85, 0.2, 0.4))
	r.draw_rect(Rect2(250, 140, 24, 14), Color(0.7, 0.85, 0.95, 0.6))
	for i in 5:
		r.draw_circle(Vector2(254 + i * 4, 151), 2.0, Color.from_hsv(0.75 + i * 0.05, 0.6, 0.9))
	r.draw_line(Vector2(262 + sin(_t) * 8, 140), Vector2(262 + sin(_t) * 8, 146), Color(0.8, 0.8, 0.8))
	# Las guirnaldas de bombillos, de punta a punta.
	for row in [[Vector2(0, 66), Vector2(W, 70)], [Vector2(0, 134), Vector2(W, 132)]]:
		var a: Vector2 = row[0]
		var b: Vector2 = row[1]
		for i in 40:
			var f := i / 40.0
			var p := a.lerp(b, f) + Vector2(0, sin(f * PI * 6.0) * 4.0)
			var on := int(_t * 4.0 + i) % 3 != 0
			r.draw_circle(p, 1.2, Color.from_hsv(fmod(i * 0.21, 1.0), 0.7, 1.0) if on else Color(0.3, 0.3, 0.3))
	# El arco de la entrada, abajo a la izquierda.
	r.draw_rect(Rect2(22, H - 30, 3, 28), Color(0.85, 0.75, 0.3))
	r.draw_rect(Rect2(56, H - 30, 3, 28), Color(0.85, 0.75, 0.3))
	r.draw_rect(Rect2(18, H - 36, 46, 8), Color(0.85, 0.2, 0.25))
	r.draw_string(load("res://assets/fonts/PressStart2P.ttf"), Vector2(21, H - 29), "FERIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.95, 0.7))
