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


## La feria: el fondo quieto (tools/art/draw_feria_juegos.py lote: el cielo, el piso, la montaña de madera,
## el pabellón de los chocones, los puestos) y encima lo que se mueve: la rueda con sus cabinas, los
## caballitos, los carritos chocones, el carrito de la montaña y los bombillos.
const ART := "res://assets/feria/%s.png"
var _tex := {}


func _img(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load(ART % name)
	return _tex[name]


func _draw_fair() -> void:
	var r := _room
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.draw_texture(_img("lote_fondo"), Vector2.ZERO)
	for i in 30:  # las estrellas titilan
		r.draw_rect(Rect2(fmod(i * 97.0, W), fmod(i * 37.0, 40.0), 1, 1), Color(1, 1, 0.9, 0.3 + 0.7 * absf(sin(_t * 1.5 + i))))
	# El carrito de la montaña rusa, por la carrilera.
	var u := fmod(_t * 26.0, 112.0)
	var cx := 260.0 + u
	var cy := 70.0 - 26.0 * absf(sin((cx - 260.0) * 0.045))
	var slope := -26.0 * 0.045 * cos((cx - 260.0) * 0.045) * signf(sin((cx - 260.0) * 0.045))
	r.draw_set_transform(Vector2(cx, cy), atan(slope))
	r.draw_texture(_img("mini_vagon"), Vector2(-5, -7))
	r.draw_set_transform(Vector2.ZERO)
	# La rueda de Chicago: el aro, los rayos y las cabinas (que cuelgan derechas), girando despacio.
	var hub := Vector2(430, 64)
	r.draw_arc(hub, 53, 0, TAU, 48, Color(0.55, 0.56, 0.64), 2.0)
	r.draw_arc(hub, 48, 0, TAU, 48, Color(0.45, 0.46, 0.54), 1.0)
	for i in 12:
		var a := _t * 0.25 + i * TAU / 12.0
		var p := hub + Vector2(cos(a), sin(a)) * 53.0
		r.draw_line(hub, p, Color(0.62, 0.63, 0.72), 1.0)
		var on := int(_t * 3.0 + i) % 3 != 0
		r.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.92, 0.6) if on else Color(1, 0.4, 0.5))
		r.draw_texture(_img("gondola_%d" % (i % 6)), p + Vector2(-4, 2))
	r.draw_circle(hub, 4.0, Color(0.36, 0.36, 0.42))
	r.draw_circle(hub, 2.0, Color(0.9, 0.8, 0.4))
	# El carrusel: los caballitos que dan vuelta (atrás, después el techo tapa los tubos, adelante).
	var cc := Vector2(92, 104)
	for front in [false, true]:
		for i in 6:
			var a := _t * 1.2 + i * TAU / 6.0
			if (sin(a) >= 0.0) != front:
				continue
			var hx := cc.x + cos(a) * 26.0
			var hy := cc.y + sin(a) * 6.0 - 6.0 + sin(_t * 4.0 + i) * 2.0
			r.draw_line(Vector2(hx, cc.y - 18), Vector2(hx, hy - 4), Color(0.95, 0.82, 0.4))
			var horse := _img("mini_caballo_%d" % (i % 3))
			var tint := Color.WHITE if front else Color(0.6, 0.55, 0.7)
			if cos(a + PI * 0.5) > 0.0:
				r.draw_texture(horse, Vector2(hx - 6, hy - 6), tint)
			else:
				r.draw_texture_rect(horse, Rect2(hx + 6, hy - 6, -12, 9), false, tint)
	r.draw_texture(_img("mini_carrusel_techo"), cc + Vector2(-38, -40))
	for k in 12:  # los bombillos de la cenefa
		var on := (k + int(_t * 8.0)) % 3 != 0
		r.draw_rect(Rect2(cc.x - 34 + k * 6, cc.y - 22, 1, 1), Color(1, 0.94, 0.6) if on else Color(0.5, 0.4, 0.3))
	# Los chocones: los carritos dando vueltas (con su vara y sus chispas contra la malla).
	var names := ["rojo", "azul", "amarillo", "verde", "morado"]
	for i in 5:
		var p := Vector2(214 + cos(_t * (0.8 + i * 0.3) + i) * 28.0, 101 + sin(_t * (1.1 + i * 0.2) + i * 2.0) * 10.0)
		r.draw_line(p + Vector2(-3, -2), Vector2(p.x - 3, 66), Color(0.6, 0.6, 0.66), 1.0)
		r.draw_texture(_img("mini_chocon_" + names[i]), p - Vector2(5, 4))
		if randf() < 0.05:
			r.draw_rect(Rect2(p.x - 4 + randf_range(-1, 1), 65, 2, 2), Color(0.7, 0.9, 1.0))
	# Las guirnaldas de bombillos, de punta a punta.
	for row in [[Vector2(0, 66), Vector2(W, 70)], [Vector2(0, 134), Vector2(W, 132)]]:
		var a: Vector2 = row[0]
		var b: Vector2 = row[1]
		var prev := a
		for i in 41:
			var f := i / 40.0
			var p := a.lerp(b, f) + Vector2(0, sin(f * PI * 6.0) * 4.0)
			r.draw_line(prev, p, Color(0.22, 0.2, 0.24))
			prev = p
			var on := int(_t * 4.0 + i) % 3 != 0
			r.draw_rect(Rect2(p - Vector2(1, 0), Vector2(2, 2)), Color.from_hsv(fmod(i * 0.21, 1.0), 0.7, 1.0) if on else Color(0.3, 0.3, 0.3))
