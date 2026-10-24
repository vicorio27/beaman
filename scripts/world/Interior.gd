extends Location
## Adentro de los lugares que antes eran solo una conversación en la puerta: la iglesia, la
## veterinaria, la pensión, el baño público, la Defensoría, la Registraduría, el estudio de fotos y La
## Caverna del Gamer. Un cuarto que se camina, con sus muebles, la persona de siempre atendiendo (lo
## que dice es lo mismo de antes: Conversations, por su service_id) y gente haciendo su vida (Vecino).
## Cuál es: GameState.flags["interior"] = [id, escena de afuera, camino al Servicio de afuera].
## Se entra con ServiceSpot.interior (lo pone Vecindario) y se sale por la puerta de abajo, al mismo sitio.
## El colegio no: él no entra al colegio. Él es el de la reja.

const INK := Color(0.08, 0.06, 0.08)
## Cada lugar: tamaño, piso y pared, título (el letrero de adentro), los muebles [tipo, posición,
## tamaño], quién atiende [service_id o npc:<id>, posición, letrero, fila o personaje] y la gente.
const PLACES := {
	"iglesia": {"size": Vector2(224, 140), "floor": Color(0.62, 0.58, 0.54), "wall": Color(0.86, 0.82, 0.72),
		"title": "PARROQUIA SAN JUDAS", "tiles": true,
		"props": [["altar", Vector2(88, 18), Vector2(48, 20)], ["cross", Vector2(106, 2), Vector2(12, 16)],
			["window_glass", Vector2(28, 4), Vector2(20, 22)], ["window_glass", Vector2(176, 4), Vector2(20, 22)],
			["candles", Vector2(168, 40), Vector2(30, 10)],
			["pew", Vector2(24, 58), Vector2(68, 10)], ["pew", Vector2(132, 58), Vector2(68, 10)],
			["pew", Vector2(24, 80), Vector2(68, 10)], ["pew", Vector2(132, 80), Vector2(68, 10)],
			["pew", Vector2(24, 102), Vector2(68, 10)], ["pew", Vector2(132, 102), Vector2(68, 10)],
			["rug", Vector2(100, 40), Vector2(24, 96)]],
		"owner": ["iglesia", Vector2(112, 52), "SENTARSE", ""],
		"people": [
			{"row": 3, "path": [Vector2(40, 76)], "pose": "up", "say": ["(reza un rosario de afán, como quien cuenta plata)", "—... y líbranos de todo mal. Y de Gladys."],
				"talk": ["—Shh. Estoy hablando con Dios. Usted tampoco habla: ya somos dos que lo respetan.", "—Rece por mí, mijo. Yo rezo por usted. Así nos ahorramos el doble."]},
			{"row": 9, "id": "padre", "path": [Vector2(60, 48), Vector2(170, 48), Vector2(170, 124), Vector2(60, 124)], "wait": 3.0,
				"say": ["(barre el pasillo. El mismo polvo de ayer: es fiel)", "(cambia una vela que ya estaba bien)"],
				"talk": ["—Siga, siga. La casa de Dios no cobra. Las velas sí, pero eso es otra oficina.", "—Si se queda dormido en la banca, no ronque. Es lo único que pido."]},
			{"row": 12, "path": [Vector2(180, 120)], "pose": "up", "say": ["(dormido en la última banca, con la boca abierta)"],
				"talk": ["(No se despierta. Ronca en latín.)"]}]},
	"veterinaria": {"size": Vector2(208, 128), "floor": Color(0.82, 0.86, 0.84), "wall": Color(0.62, 0.8, 0.78),
		"title": "VETERINARIA PATITAS", "tiles": true,
		"props": [["counter", Vector2(120, 34), Vector2(70, 14)], ["shelf", Vector2(130, 6), Vector2(60, 20)],
			["cage", Vector2(14, 34), Vector2(22, 18)], ["cage", Vector2(40, 34), Vector2(22, 18)], ["cage", Vector2(14, 56), Vector2(22, 18)],
			["poster", Vector2(76, 6), Vector2(26, 20)], ["bench", Vector2(150, 96), Vector2(46, 10)], ["plant", Vector2(14, 100), Vector2(10, 14)]],
		"owner": ["veterinaria", Vector2(152, 56), "HABLAR", "fabiola"],
		"people": [
			{"row": 6, "path": [Vector2(162, 100)], "pose": "down", "say": ["(le habla al guacal del gato como a un hijo)", "—Ya, Michi. Es solo una vacuna. Yo también lloré con la mía."],
				"talk": ["—¿Y ese perro? Qué bonito. El mío es gato. No es lo mismo, pero tampoco me juzga.", "—Lleva tres horas aquí. El gato, no yo. Bueno, yo también."]},
			{"row": 15, "path": [Vector2(70, 70), Vector2(100, 90)], "wait": 5.0, "say": ["—¡Mamá, mire el hámster! ¡Se está comiendo la casa!"],
				"talk": ["—¿Ese perro es suyo? ¿Lo puedo tocar? ... ¡Me lamió! ¡MAMÁ!"]}]},
	"pension": {"size": Vector2(208, 128), "floor": Color(0.55, 0.38, 0.28), "wall": Color(0.76, 0.66, 0.5),
		"title": "PENSIÓN EL DESCANSO", "tiles": false,
		"props": [["counter", Vector2(126, 34), Vector2(62, 14)], ["keys", Vector2(140, 6), Vector2(36, 18)],
			["door", Vector2(16, 6), Vector2(16, 26)], ["door", Vector2(44, 6), Vector2(16, 26)], ["door", Vector2(72, 6), Vector2(16, 26)],
			["tv", Vector2(30, 70), Vector2(20, 16)], ["chair", Vector2(32, 96), Vector2(16, 12)], ["rug", Vector2(90, 60), Vector2(40, 40)]],
		"owner": ["pension", Vector2(156, 56), "PENSIÓN", ""],
		"people": [
			{"row": 0, "id": "viejo2", "path": [Vector2(40, 108)], "pose": "up", "say": ["(ve una novela. Le grita a la televisión: —¡Es su hermano, boba!)", "(se ríe con un comercial)"],
				"talk": ["—Shh. Ya casi le dicen que es adoptada. Llevo once años esperando ese capítulo."]},
			{"row": 3, "path": [Vector2(16, 40), Vector2(100, 40), Vector2(100, 110)], "wait": 4.0, "say": ["(lleva una canasta de ropa, la cuelga en la ventana)", "—¿Quién dejó la llave del agua abierta? ¡El del cuatro!"],
				"talk": ["—Usted no es de aquí. Se nota. Los de aquí no miran tanto."]}]},
	"bano": {"size": Vector2(176, 112), "floor": Color(0.78, 0.82, 0.84), "wall": Color(0.56, 0.7, 0.74),
		"title": "BAÑOS $1000", "tiles": true,
		"props": [["stall", Vector2(14, 6), Vector2(26, 34)], ["stall", Vector2(44, 6), Vector2(26, 34)], ["stall", Vector2(74, 6), Vector2(26, 34)],
			["sink", Vector2(120, 12), Vector2(16, 12)], ["sink", Vector2(144, 12), Vector2(16, 12)], ["counter", Vector2(120, 70), Vector2(42, 12)]],
		"owner": ["bano", Vector2(140, 90), "BAÑO $1000", ""],
		"people": [
			{"row": 9, "path": [Vector2(128, 32)], "pose": "up", "say": ["(se lava la cara tres veces. Se mira. Se lava otra vez)"],
				"talk": ["—No hay papel. Nunca hay papel. El papel es un mito, como el agua caliente."]},
			{"row": 12, "path": [Vector2(56, 56)], "pose": "up", "say": ["(espera turno con el periódico. Lo lee al revés)", "—¡Ocupado no es una respuesta, señor!"],
				"talk": ["—Si va a entrar, entre después de mí. Le recomiendo esperar un rato. Mucho rato."]}]},
	"defensoria": {"size": Vector2(224, 128), "floor": Color(0.74, 0.72, 0.68), "wall": Color(0.82, 0.84, 0.86),
		"title": "DEFENSORÍA DEL PUEBLO", "tiles": true,
		"props": [["desk", Vector2(128, 30), Vector2(40, 14)], ["desk", Vector2(176, 30), Vector2(36, 14)], ["screen", Vector2(20, 6), Vector2(40, 16)],
			["chairs", Vector2(16, 70), Vector2(80, 10)], ["chairs", Vector2(16, 96), Vector2(80, 10)], ["poster", Vector2(80, 6), Vector2(22, 20)], ["plant", Vector2(200, 96), Vector2(10, 14)]],
		"owner": ["defensoria", Vector2(148, 54), "VENTANILLA", ""],
		"people": [
			{"row": 6, "path": [Vector2(194, 46)], "pose": "down", "say": ["(teclea con dos dedos. Muy rápido. Con dos dedos)", "—¡Turno cuarenta y siete! ... ¿Cuarenta y siete? ... Cuarenta y ocho."],
				"talk": ["—Saque turno, señor. Sí, aunque no haya nadie. El sistema no sabe que no hay nadie."]},
			{"row": 3, "path": [Vector2(30, 84)], "pose": "down", "say": ["(abraza una carpeta llena de papeles con fotocopias de fotocopias)"],
				"talk": ["—Yo vengo por lo de mi pensión. Desde 2009. Ya me conocen. Me dicen \"la de la pensión\". Es algo."]},
			{"row": 15, "path": [Vector2(70, 110)], "pose": "down", "say": ["(dormido sentado, con el turno en la mano)"], "talk": ["(Se despierta, mira el turno, mira la pantalla, se vuelve a dormir.)"]}]},
	"registraduria": {"size": Vector2(224, 128), "floor": Color(0.7, 0.68, 0.62), "wall": Color(0.84, 0.82, 0.74),
		"title": "REGISTRADURÍA", "tiles": true,
		"props": [["desk", Vector2(120, 30), Vector2(48, 14)], ["photo_booth", Vector2(184, 8), Vector2(28, 36)], ["screen", Vector2(20, 6), Vector2(40, 16)],
			["rope", Vector2(30, 60), Vector2(80, 4)], ["rope", Vector2(30, 84), Vector2(80, 4)], ["poster", Vector2(80, 6), Vector2(22, 20)]],
		"owner": ["registraduria", Vector2(144, 54), "VENTANILLA", ""],
		"people": [
			{"row": 0, "path": [Vector2(40, 72), Vector2(60, 72), Vector2(80, 72)], "wait": 8.0, "say": ["(hace la fila. La fila no se mueve. Él tampoco)", "—¿Esta es la fila para la cédula o para el pasaporte? ... ¿Para las dos? ¿Y entonces?"],
				"talk": ["—No se cuele, que llevo desde las cinco. Bueno, usted no se cuela: usted ni habla. Pase, pues. No, mentira."]},
			{"row": 9, "path": [Vector2(100, 96)], "pose": "up", "say": ["—Señorita, ¿y si el bigote me salió en la foto? ... Era para la foto."],
				"talk": ["—Me hicieron repetir la foto porque sonreí. En la cédula no se sonríe. Ahí empieza todo."]}]},
	"fotos": {"size": Vector2(192, 120), "floor": Color(0.45, 0.4, 0.42), "wall": Color(0.3, 0.28, 0.34),
		"title": "FOTO ESTUDIO LUZ", "tiles": false,
		"props": [["backdrop", Vector2(70, 4), Vector2(56, 40)], ["camera", Vector2(92, 74), Vector2(12, 18)], ["frames", Vector2(10, 8), Vector2(46, 26)],
			["frames", Vector2(140, 8), Vector2(40, 26)], ["counter", Vector2(140, 76), Vector2(40, 12)], ["lamp_stand", Vector2(56, 40), Vector2(10, 30)]],
		"owner": ["fotos", Vector2(160, 98), "HABLAR", ""],
		"people": [
			{"row": 6, "path": [Vector2(88, 52)], "pose": "down", "say": ["(posa para la foto de grado de la hija, más tieso que el diploma)"],
				"talk": ["—Sonría, me dicen. Llevo cuarenta años sin hacerlo. No me lo van a sacar con un pajarito."]},
			{"row": 15, "path": [Vector2(108, 52)], "pose": "down", "say": ["—¡Papá, sonría! ... ¡Así no! ¡Así da miedo!"], "talk": ["—Es mi foto de grado. Mi papá vino. Eso ya es el regalo. No le diga."]}]},
	"caverna": {"size": Vector2(208, 128), "floor": Color(0.24, 0.2, 0.32), "wall": Color(0.28, 0.22, 0.4),
		"title": "LA CAVERNA DEL GAMER", "tiles": false, "dark": true,
		"props": [["arcade", Vector2(14, 6), Vector2(20, 34)], ["arcade", Vector2(40, 6), Vector2(20, 34)], ["arcade", Vector2(66, 6), Vector2(20, 34)],
			["arcade", Vector2(14, 70), Vector2(20, 34)], ["poster", Vector2(96, 6), Vector2(24, 22)], ["shelf_games", Vector2(126, 6), Vector2(70, 22)],
			["counter", Vector2(130, 46), Vector2(62, 14)], ["tv", Vector2(70, 72), Vector2(28, 20)], ["rug", Vector2(66, 96), Vector2(36, 18)]],
		"owner": ["npc:amigo", Vector2(160, 40), "", ""],
		"people": [
			{"row": 0, "path": [Vector2(176, 30)], "pose": "down", "id": "", "cat": true,
				"say": ["(el gato de Al duerme encima del televisor. Es el único cliente fijo)"], "talk": ["(El gato abre un ojo. Lo cierra. Clientela exigente.)"]}]},
}
## Horas: [abre, cierra]. Cerrado, no se entra (lo de afuera dice lo suyo).
const HOURS := {"iglesia": [6, 20], "veterinaria": [8, 19], "pension": [0, 24], "bano": [6, 22], "defensoria": [8, 17],
	"registraduria": [8, 16], "fotos": [9, 19], "caverna": [10, 20]}

var place := {}
var _t := 0.0
var _room: Node2D
var _art: Texture2D  # el cuarto dibujado (se guarda aquí: si no, se suelta antes de pintarse y sale blanco)


static func is_open(id: String) -> bool:
	var h := TimeManager.hour()
	var w: Array = HOURS.get(id, [0, 24])
	return h >= w[0] and h < w[1]


func _ready() -> void:
	var back: Array = GameState.flags.get("interior", ["iglesia", "res://scenes/world/Parque.tscn", ""])
	place = PLACES.get(back[0], PLACES["iglesia"])
	area_size = Vector2i(place["size"])
	get_node("Start").position = Vector2(area_size.x / 2.0, area_size.y - 14)
	_room = Node2D.new()
	_room.name = "Cuarto"
	_room.z_index = -5
	_room.draw.connect(_draw_room)
	add_child(_room)
	# Lo que no se atraviesa.
	var solid := StaticBody2D.new()
	for p in place["props"]:
		if p[0] in ["pew", "altar", "counter", "desk", "arcade", "stall", "bench", "cage", "photo_booth", "backdrop", "chairs", "tv", "camera", "sink", "shelf_games", "frames"]:
			var r := Rect2(p[1], p[2])
			if r.position.y < 30 and p[0] != "counter":  # (lo de la pared: solo el pie)
				r = Rect2(r.position.x, maxf(r.position.y, r.end.y - 8), r.size.x, minf(r.size.y, 8))
			var sh := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = r.size
			sh.shape = rect
			sh.position = r.position + r.size / 2.0
			solid.add_child(sh)
	add_child(solid)
	# Quien atiende.
	var o: Array = place["owner"]
	if str(o[0]).begins_with("npc:"):
		var npc := CharacterBody2D.new()
		npc.set_script(load("res://scripts/npc/NPC.gd"))
		npc.npc_id = str(o[0]).substr(4)
		npc.name = "Atiende"
		npc.sheet_row = 9
		npc.face = "down"
		npc.position = o[1]
		add_child(npc)
	else:
		var who := Vecino.new()
		who.spec = {"row": 9, "id": o[3], "path": [o[1] - Vector2(0, 18)], "pose": "down"}
		who.name = "Atiende"
		add_child(who)
		who.monitoring = false
		var spot := Area2D.new()
		spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
		spot.service_id = o[0]
		spot.hint = o[2]
		spot.area = Vector2(30, 16)
		spot.position = o[1]
		add_child(spot)
	for spec in place["people"]:
		if spec.get("cat", false):
			continue  # (el gato se dibuja con el cuarto)
		var v := Vecino.new()
		v.spec = spec
		add_child(v)
	# La puerta: se sale a donde estaba.
	var door := Area2D.new()
	door.set_script(load("res://scripts/world/Door.gd"))
	door.name = "Salida"
	door.target_scene = back[1]
	door.target_spawn = back[2]
	door.push_dir = Vector2.DOWN
	door.position = Vector2(area_size.x / 2.0, area_size.y - 4)
	var dsh := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(28, 10)
	dsh.shape = drect
	door.add_child(dsh)
	add_child(door)
	super._ready()


func _process(delta: float) -> void:
	_t += delta
	_room.queue_redraw()  # (las velas, las pantallas y las maquinitas se mueven)


func _draw_room() -> void:
	var w := float(area_size.x)
	var h := float(area_size.y)
	if _art == null:
		var art := "res://assets/interiores/%s.png" % GameState.flags.get("interior", ["iglesia"])[0]
		if ResourceLoader.exists(art):
			_art = load(art)
	if _art:  # el cuarto dibujado (tools/art/draw_interiores.py); encima, solo lo que se mueve
		_room.draw_texture(_art, Vector2.ZERO)
		for p in place["props"]:
			_moving(p[0], p[1], p[2])
		if place.get("dark", false):
			_room.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.02, 0.1, 0.12))  # (penumbra, no negro: con el filtro encima no se veía nada)
		return
	var fl: Color = place["floor"]
	var wl: Color = place["wall"]
	var r := _room
	r.draw_rect(Rect2(0, 0, w, h), fl)
	if place.get("tiles", false):
		for y in range(30, int(h), 12):
			for x in range(0, int(w), 12):
				if (x / 12 + y / 12) % 2 == 0:
					r.draw_rect(Rect2(x, y, minf(12, w - x), minf(12, h - y)), fl.darkened(0.06))
	else:
		for y in range(34, int(h), 8):
			r.draw_line(Vector2(0, y), Vector2(w, y), fl.darkened(0.12))
	r.draw_rect(Rect2(0, 0, w, 30), wl)
	r.draw_rect(Rect2(0, 28, w, 2), wl.darkened(0.35))
	r.draw_rect(Rect2(0, 0, 4, h), wl.darkened(0.3))
	r.draw_rect(Rect2(w - 4, 0, 4, h), wl.darkened(0.3))
	r.draw_rect(Rect2(0, h - 3, w, 3), INK)
	r.draw_rect(Rect2(w / 2.0 - 14, h - 5, 28, 5), Color(0.35, 0.25, 0.16))  # la puerta
	for p in place["props"]:
		_prop(p[0], p[1], p[2])
	if place.get("dark", false):
		r.draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.02, 0.1, 0.12))
	for spec in place["people"]:
		if spec.get("cat", false):  # el gato de Al, en el televisor de la pared
			var c: Vector2 = spec["path"][0]
			r.draw_rect(Rect2(c.x - 5, c.y - 4, 10, 5), Color(0.9, 0.55, 0.25))
			r.draw_rect(Rect2(c.x + 3, c.y - 7, 4, 4), Color(0.9, 0.55, 0.25))
			r.draw_line(Vector2(c.x - 5, c.y - 1), Vector2(c.x - 9, c.y + 3), Color(0.9, 0.55, 0.25))


## Lo que se mueve encima del cuarto dibujado: las llamas, el televisor, las maquinitas, el turno.
func _moving(kind: String, at: Vector2, size: Vector2) -> void:
	var r := _room
	match kind:
		"candles":
			for k in 6:
				var x := at.x + 2 + k * 5
				var fl := 1.0 + sin(_t * 9.0 + k) * 0.5
				r.draw_rect(Rect2(x, at.y - 1 - fl, 2, 2 + fl), Color(1, 0.75, 0.3))
				r.draw_rect(Rect2(x, at.y - fl * 0.5, 2, 1), Color(1, 0.95, 0.7))
		"tv":
			var tvc := Color.from_hsv(fmod(_t * 0.2, 1.0), 0.4, 0.8)
			r.draw_rect(Rect2(at + Vector2(2, 2), size - Vector2(4, 6)), tvc)
			r.draw_rect(Rect2(at + Vector2(2, 2 + fmod(_t * 12.0, size.y - 6)), Vector2(size.x - 4, 1)), tvc.lightened(0.3))
		"arcade":
			var sc := Color.from_hsv(fmod(_t * 0.35 + at.x * 0.01, 1.0), 0.7, 0.95)
			r.draw_rect(Rect2(at + Vector2(3, 5), Vector2(size.x - 6, 11)), sc.darkened(0.5))
			r.draw_rect(Rect2(at + Vector2(4 + fmod(_t * 20.0 + at.x, size.x - 9), 9), Vector2(2, 2)), sc)
		"screen":
			r.draw_string(load("res://assets/fonts/PressStart2P.ttf"), at + Vector2(3, 12), "T-%02d" % (47 + int(_t / 20.0) % 3), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.3, 0.25))


func _prop(kind: String, at: Vector2, size: Vector2) -> void:
	var r := _room
	var wood := Color(0.48, 0.32, 0.2)
	match kind:
		"pew", "bench", "chairs":
			r.draw_rect(Rect2(at, size), wood)
			r.draw_rect(Rect2(at, Vector2(size.x, 3)), wood.darkened(0.3))
			if kind == "chairs":
				for x in range(int(at.x) + 10, int(at.x + size.x), 12):
					r.draw_line(Vector2(x, at.y), Vector2(x, at.y + size.y), wood.darkened(0.4))
		"altar":
			r.draw_rect(Rect2(at, size), Color(0.95, 0.94, 0.9))
			r.draw_rect(Rect2(at + Vector2(0, size.y - 4), Vector2(size.x, 4)), Color(0.8, 0.7, 0.3))
		"cross":
			r.draw_rect(Rect2(at + Vector2(size.x / 2 - 1.5, 0), Vector2(3, size.y)), Color(0.55, 0.38, 0.2))
			r.draw_rect(Rect2(at + Vector2(0, 4), Vector2(size.x, 3)), Color(0.55, 0.38, 0.2))
		"window_glass":
			r.draw_rect(Rect2(at, size), Color(0.3, 0.3, 0.5))
			var cols := [Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9), Color(0.95, 0.8, 0.3), Color(0.4, 0.75, 0.4)]
			for k in 4:
				r.draw_rect(Rect2(at + Vector2(2 + (k % 2) * size.x / 2, 2 + (k / 2) * size.y / 2), Vector2(size.x / 2 - 3, size.y / 2 - 3)), cols[k])
		"candles":
			r.draw_rect(Rect2(at + Vector2(0, 6), Vector2(size.x, 4)), Color(0.3, 0.26, 0.2))
			for k in 6:
				var x := at.x + 2 + k * 5
				r.draw_rect(Rect2(x, at.y + 1, 2, 5), Color(0.96, 0.94, 0.86))
				var fl := 1.0 + sin(_t * 9.0 + k) * 0.5
				r.draw_rect(Rect2(x, at.y - 1 - fl, 2, 2 + fl), Color(1, 0.75, 0.3))
		"counter", "desk":
			r.draw_rect(Rect2(at, size), wood.lightened(0.1))
			r.draw_rect(Rect2(at, Vector2(size.x, 3)), wood.lightened(0.3))
			if kind == "desk":
				r.draw_rect(Rect2(at + Vector2(size.x / 2 - 7, -10), Vector2(14, 10)), Color(0.2, 0.22, 0.26))
				r.draw_rect(Rect2(at + Vector2(size.x / 2 - 5, -8), Vector2(10, 6)), Color(0.4, 0.7, 0.85))
		"shelf", "shelf_games":
			r.draw_rect(Rect2(at, size), wood.darkened(0.2))
			var cols := [Color(0.8, 0.3, 0.3), Color(0.3, 0.6, 0.8), Color(0.9, 0.75, 0.3), Color(0.4, 0.7, 0.4), Color(0.7, 0.4, 0.8)]
			for y in [at.y + 2, at.y + size.y / 2 + 1]:
				for x in range(int(at.x) + 2, int(at.x + size.x) - 4, 5 if kind == "shelf_games" else 8):
					r.draw_rect(Rect2(x, y, 4 if kind == "shelf_games" else 6, size.y / 2 - 3), cols[(x / 5) % cols.size()])
		"cage":
			r.draw_rect(Rect2(at, size), Color(0.35, 0.36, 0.4))
			r.draw_rect(Rect2(at + Vector2(6, size.y - 8), Vector2(10, 6)), Color(0.8, 0.6, 0.35) if int(at.x) % 2 == 0 else Color(0.3, 0.3, 0.3))
			for x in range(int(at.x) + 2, int(at.x + size.x), 4):
				r.draw_line(Vector2(x, at.y), Vector2(x, at.y + size.y), Color(0.75, 0.76, 0.8))
		"poster":
			r.draw_rect(Rect2(at, size), Color(0.95, 0.9, 0.7))
			r.draw_rect(Rect2(at + Vector2(3, 3), Vector2(size.x - 6, size.y / 2)), Color(0.9, 0.45, 0.3))
			for k in 2:
				r.draw_line(at + Vector2(3, size.y / 2 + 6 + k * 4), at + Vector2(size.x - 3, size.y / 2 + 6 + k * 4), INK)
		"keys":
			r.draw_rect(Rect2(at, size), wood)
			for k in 8:
				r.draw_rect(Rect2(at.x + 3 + (k % 4) * 8, at.y + 3 + (k / 4) * 8, 2, 4), Color(0.9, 0.8, 0.3))
		"door":
			r.draw_rect(Rect2(at, size), wood.darkened(0.15))
			r.draw_rect(Rect2(at + Vector2(size.x - 4, size.y / 2), Vector2(2, 2)), Color(0.9, 0.8, 0.3))
		"tv":
			r.draw_rect(Rect2(at, size), Color(0.15, 0.15, 0.18))
			var tvc := Color.from_hsv(fmod(_t * 0.2, 1.0), 0.4, 0.8)
			r.draw_rect(Rect2(at + Vector2(2, 2), size - Vector2(4, 6)), tvc)
		"chair":
			r.draw_rect(Rect2(at, size), Color(0.6, 0.3, 0.25))
		"rug":
			r.draw_rect(Rect2(at, size), Color(0.6, 0.18, 0.2, 0.85))
			r.draw_rect(Rect2(at + Vector2(2, 2), size - Vector2(4, 4)), Color(0.75, 0.6, 0.3), false, 1.0)
		"stall":
			r.draw_rect(Rect2(at, size), Color(0.5, 0.62, 0.66))
			r.draw_rect(Rect2(at + Vector2(3, 6), Vector2(size.x - 6, size.y - 6)), Color(0.42, 0.54, 0.6))
			r.draw_rect(Rect2(at + Vector2(size.x - 7, size.y / 2), Vector2(2, 3)), Color(0.85, 0.3, 0.3))
		"sink":
			r.draw_rect(Rect2(at, size), Color(0.95, 0.96, 0.98))
			r.draw_rect(Rect2(at + Vector2(size.x / 2 - 1, -4), Vector2(2, 4)), Color(0.7, 0.72, 0.78))
		"screen":
			r.draw_rect(Rect2(at, size), Color(0.1, 0.1, 0.12))
			r.draw_string(load("res://assets/fonts/PressStart2P.ttf"), at + Vector2(3, 12), "T-%02d" % (47 + int(_t / 20.0) % 3), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.3, 0.25))
		"rope":
			r.draw_rect(Rect2(at, size), Color(0.75, 0.15, 0.2))
			r.draw_rect(Rect2(at.x - 2, at.y - 8, 3, 12), Color(0.8, 0.75, 0.3))
			r.draw_rect(Rect2(at.x + size.x - 1, at.y - 8, 3, 12), Color(0.8, 0.75, 0.3))
		"photo_booth":
			r.draw_rect(Rect2(at, size), Color(0.3, 0.32, 0.4))
			r.draw_rect(Rect2(at + Vector2(3, 6), Vector2(size.x - 6, size.y - 10)), Color(0.75, 0.2, 0.25))
		"backdrop":
			r.draw_rect(Rect2(at, size), Color(0.36, 0.5, 0.75))
			r.draw_rect(Rect2(at + Vector2(0, size.y - 6), Vector2(size.x, 6)), Color(0.3, 0.42, 0.65))
		"camera":
			r.draw_line(at + Vector2(size.x / 2, 6), at + Vector2(0, size.y), INK)
			r.draw_line(at + Vector2(size.x / 2, 6), at + Vector2(size.x, size.y), INK)
			r.draw_rect(Rect2(at, Vector2(size.x, 7)), Color(0.15, 0.15, 0.18))
		"frames":
			for k in 4:
				var fr := Rect2(at + Vector2(k * size.x / 4 + 1, (k % 2) * 4), Vector2(size.x / 4 - 3, size.y - 6))
				r.draw_rect(fr, Color(0.8, 0.65, 0.3))
				r.draw_rect(fr.grow(-2), Color(0.6, 0.62, 0.66).lerp(Color(0.85, 0.7, 0.6), k / 3.0))
		"lamp_stand":
			r.draw_rect(Rect2(at + Vector2(size.x / 2 - 1, 8), Vector2(2, size.y - 8)), INK)
			r.draw_rect(Rect2(at, Vector2(size.x, 8)), Color(0.95, 0.95, 0.9))
		"plant":
			r.draw_rect(Rect2(at + Vector2(1, size.y - 5), Vector2(size.x - 2, 5)), Color(0.6, 0.35, 0.2))
			r.draw_circle(at + Vector2(size.x / 2, size.y - 8), 5.0, Color(0.3, 0.6, 0.3))
		"arcade":
			r.draw_rect(Rect2(at, size), Color(0.18, 0.14, 0.3))
			var sc := Color.from_hsv(fmod(_t * 0.35 + at.x * 0.01, 1.0), 0.7, 0.95)
			r.draw_rect(Rect2(at + Vector2(3, 5), Vector2(size.x - 6, 10)), sc)
			r.draw_rect(Rect2(at + Vector2(4, 19), Vector2(3, 3)), Color(0.9, 0.3, 0.3))
			r.draw_rect(Rect2(at + Vector2(10, 19), Vector2(3, 3)), Color(0.3, 0.5, 0.95))
			r.draw_rect(Rect2(at + Vector2(0, 0), Vector2(size.x, 3)), Color(0.95, 0.4, 0.7))
