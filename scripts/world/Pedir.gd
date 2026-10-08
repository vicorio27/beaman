extends Node2D
## Minijuego: sentado en la vereda con un vaso, pidiendo. Pasa la gente de a uno; arriba de cada
## uno se ve qué tipo de persona es. Mientras está cerca hay que elegir cómo acercarse:
##   arriba = pedir, derecha = un chiste, abajo = el truco de Lukas, izquierda = quedarse callado.
## A cada tipo le funciona otra cosa (aprenderlo es el juego). Equivocarse trae desprecio
## (baja el ánimo). Sin ánimo, los chistes no salen. Con Lukas sin comer, no hay truco.
## La segunda vez en el mismo día y lugar, la compasión rinde la mitad.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const W := 320.0
const PEOPLE := 10
const WALK_SPEED := 46.0
const ZONE := Vector2(110, 210)    # x donde se le puede hablar
const LINE_Y := 104.0
const SEAT := Vector2(160, 136)

## tipo -> [fila de la hoja, tinte, {acción: [chance, plata, línea si sale, línea si no]}]
## Acciones: "pedir", "chiste", "lukas", "nada".
const TYPES := {
	"APURADO": [6, Color(0.8, 0.85, 1.0), {
		"nada": [1.0, 0, "", ""],
		"pedir": [0.0, 0, "", "—¡No tengo tiempo!"],
		"chiste": [0.0, 0, "", "—¡No tengo tiempo!"],
		"lukas": [0.1, 500, "—... bueno, por el perro.", "—¡No tengo tiempo!"]}],
	"SEÑORA": [3, Color(1.0, 0.85, 0.9), {
		"pedir": [0.6, 500, "—Tome, mijo. Que Dios le ayude.", "—Hoy no, mijo."],
		"chiste": [0.3, 200, "—Ay, qué tan bobo. Tome.", "—Ay, no, qué falta de respeto."],
		"lukas": [0.85, 1000, "—¡Ay, qué perrito tan lindo! Tome, para los dos.", "—Ay, no, los perros me dan miedo."],
		"nada": [1.0, 0, "", ""]}],
	"ESTUDIANTE": [0, Color(0.85, 1.0, 0.85), {
		"pedir": [0.2, 300, "—Tome lo del bus. Camino.", "—Parce, no tengo ni pa'l pasaje."],
		"chiste": [0.8, 500, "—Jajaja, buenísimo. Tome, se lo ganó.", "—... no entendí."],
		"lukas": [0.6, 300, "—¡Qué crack el perro! Tome.", "—Uy, qué boleta."],
		"nada": [1.0, 0, "", ""]}],
	"OBRERO": [9, Color(1.0, 0.9, 0.75), {
		"pedir": [0.8, 1000, "—Tome, parcero. Yo sé cómo es.", "—Hoy no hubo pago, hermano."],
		"chiste": [0.6, 500, "—¡Ja! Tome, pa' un tinto.", "—Muy chistoso. Siga."],
		"lukas": [0.5, 500, "—Ese perro trabaja más que mi jefe. Tome.", "—Guarde ese perro, que muerde."],
		"nada": [1.0, 0, "", ""]}],
	"PAREJA": [15, Color(1.0, 0.8, 0.8), {
		"pedir": [0.3, 500, "—Tome. Amor, vamos.", "—Amor, vamos, vamos."],
		"chiste": [0.5, 500, "—Jaja, es simpático. Dele algo, amor.", "—Qué incómodo, amor. Vamos."],
		"lukas": [0.9, 2000, "—¡Amor, mirá el perrito! ¡Dale algo!", "—Amor, ese perro está sucio."],
		"nada": [1.0, 0, "", ""]}],
	"POLICIA": [12, Color(0.6, 0.75, 0.6), {
		"nada": [1.0, 0, "", ""],
		"pedir": [0.0, 0, "", "—Circule, circule. Aquí no se puede pedir."],
		"chiste": [0.0, 0, "", "—¿Muy chistoso? ¿Quiere ir a la estación a contar chistes?"],
		"lukas": [0.0, 0, "", "—¿Ese perro tiene vacunas? Circule."]}],
	"CORBATA": [6, Color(0.7, 0.7, 0.75), {
		"pedir": [0.15, 2000, "—... tome. No le cuente a nadie.", "—Trabaje."],
		"chiste": [0.05, 1000, "—Bueno, ese estuvo bueno.", "—Trabaje."],
		"lukas": [0.1, 1000, "—Tuve un beagle. Tome.", "—Trabaje."],
		"nada": [1.0, 0, "", ""]}],
}
const MY_LINES := {
	"pedir": ["(Levanta el vaso.)", "(Levanta el vaso. Lo mira fijo.)"],
	"chiste": ["(Cartel: \"¿TIENE UN MINUTO PARA HABLAR DE MI HAMBRE?\")", "(Cartel: \"ACEPTO EFECTIVO. LÁSTIMA NO.\")",
		"(Cartel: \"NO HABLO. NO MUERDO. EL PERRO TAMPOCO. CASI.\")"],
	"lukas": ["(Lukas se sienta, da la pata y pone cara de comercial de Navidad.)"],
}

var queue: Array = []
var current: Dictionary = {}
var state := "intro"
var got := 0
var _place := ""
var _half := false
var _hud: Label
var _legend: Label
var _type_label: Label
var _bubble: Label
var _me_line: Label
var _people_left := PEOPLE
var _line_i := 0


func _ready() -> void:
	var back: Array = GameState.flags.get("pedir_return", ["res://scenes/world/City.tscn", "FromPedir"])
	_place = back[0]
	var key := "pedir_%s" % _place.get_file()
	_half = GameState.flags.get(key, -1) == GameState.day
	GameState.flags[key] = GameState.day
	_build()
	for i in PEOPLE:
		queue.append(TYPES.keys().pick_random())
	_intro()


func _build() -> void:
	var ts: TileSet = load("res://assets/barrio/barrio_tileset.tres")
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	add_child(ground)
	for y in 12:
		for x in 20:
			var t := 17
			if y in [5, 6, 7, 8]:
				t = 13
			elif y == 9:
				t = 16
			elif y >= 10:
				t = 11 if y == 11 and x % 2 == 0 else 8
			ground.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	var sets := {"Centro": ["foto_express", "edificio_centro", "house_f"], "Parque": ["iglesia", "tree_green", "tree_green2"]}
	var set: Array = ["bakery", "house_e", "house_b"]
	for k in sets:
		if _place.ends_with(k + ".tscn"):
			set = sets[k]
	for p in [[set[0], Vector2(170, 82)], [set[1], Vector2(40, 82)], [set[2], Vector2(290, 82)]]:
		var s := Sprite2D.new()
		s.texture = load("res://assets/barrio/%s.png" % p[0])
		s.centered = false
		s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
		s.position = p[1]
		add_child(s)
	var me := AnimatedSprite2D.new()
	me.sprite_frames = CharacterFrames.protagonist()
	me.play("idle_down")
	me.position = SEAT + Vector2(0, -8)
	add_child(me)
	var cup := Sprite2D.new()
	cup.texture = load("res://assets/items/vaso.png")
	cup.position = SEAT + Vector2(14, 0)
	cup.scale = Vector2(0.7, 0.7)
	add_child(cup)
	var lukas := Sprite2D.new()
	lukas.texture = Lukas.cell(3, 0)
	lukas.position = SEAT + Vector2(-16, -2)
	add_child(lukas)
	lukas.visible = GameState.lukas_alive()
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_hud = _label(ui, Vector2(6, 4))
	_legend = _label(ui, Vector2(0, 160))
	_legend.size = Vector2(W, 20)
	_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend.text = "ARRIBA vaso  DER cartel\nABAJO %s  IZQ nada" % ("Lukas" if GameState.lukas_alive() else "-----")
	_legend.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	_type_label = _label(ui, Vector2(0, 0))
	_type_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_bubble = _label(ui, Vector2(0, 0))
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size = Vector2(150, 30)
	_me_line = _label(ui, Vector2(0, 116))
	_me_line.size = Vector2(W, 20)
	_me_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_me_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_me_line.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))


func _label(parent: Node, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	parent.add_child(l)
	return l


func _intro() -> void:
	await get_tree().create_timer(0.4).timeout
	var lines := [["", "(Se sienta en la vereda con un vaso y un cartón escrito.)"],
		["", "(A cada uno le funciona algo distinto.)"]]
	if _half:
		lines.append(["", "(Ya lo vieron hoy por aquí.)"])
	await Dialogue.talk(lines)
	state = "play"
	_next()


func _next() -> void:
	if queue.is_empty():
		_finish()
		return
	var type: String = queue.pop_front()
	var spr := AnimatedSprite2D.new()
	CharacterFrames.dress(spr, TYPES[type][0])
	spr.modulate = GameState.same_tint(TYPES[type][1])
	spr.play("walk_side")
	spr.flip_h = true
	spr.position = Vector2(-12, LINE_Y)
	add_child(spr)
	current = {"type": type, "sprite": spr, "done": false}
	_people_left -= 1


func _process(delta: float) -> void:
	_hud.text = "$%d   QUEDAN %d" % [got, _people_left]
	if state != "play" or current.is_empty():
		return
	var spr: AnimatedSprite2D = current["sprite"]
	spr.position.x += WALK_SPEED * delta * (0.4 if current["done"] and spr.position.x < ZONE.y else 1.0)
	_type_label.text = current["type"]
	_type_label.position = spr.position + Vector2(-_type_label.text.length() * 4.0, -34)
	_bubble.position = spr.position + Vector2(-75, -60)
	if not current["done"] and spr.position.x > ZONE.y:
		_choose("nada")
	if spr.position.x > W + 16:
		spr.queue_free()
		_bubble.text = ""
		_me_line.text = ""
		current = {}
		_next()


func _unhandled_input(event: InputEvent) -> void:
	if state != "play" or current.is_empty() or current["done"]:
		return
	var spr: AnimatedSprite2D = current["sprite"]
	if spr.position.x < ZONE.x:
		return
	var action := ""
	if event.is_action_pressed("move_up"):
		action = "pedir"
	elif event.is_action_pressed("move_right"):
		action = "chiste"
	elif event.is_action_pressed("move_down"):
		action = "lukas"
	elif event.is_action_pressed("move_left"):
		action = "nada"
	if action != "":
		get_viewport().set_input_as_handled()
		_choose(action)


func _choose(action: String) -> void:
	current["done"] = true
	var rule: Array = TYPES[current["type"]][2][action]
	var chance: float = rule[0]
	if action != "nada":
		var mine: Array = MY_LINES[action]
		_me_line.text = mine[_line_i % mine.size()]
		_line_i += 1
	if action in ["pedir", "chiste"] and GameState.has_skill("labia") and chance > 0.0:
		chance = minf(1.0, chance + 0.15)
	chance *= 1.0 - 0.35 * GameState.diff("pedir")
	if action == "chiste" and GameState.mood < 15.0:
		chance = 0.0
		_me_line.text = "(Tiene el cartel al revés. No se da cuenta.)"
	if action == "lukas" and not GameState.lukas_alive():
		chance = 0.0
		_me_line.text = "(Mira al lado, para hacer el truco. No hay nadie.)"
	if action == "lukas" and GameState.flags.get("lukas_hungry", false):
		chance *= 0.5
	if action == "lukas" and GameState.lukas_sick():
		chance *= 0.3
	if action == "lukas" and GameState.lukas_knows("pata") and current["type"] == "SEÑORA":
		chance = 1.0  # las señoras no se resisten
	if randf() < chance:
		var amount: int = rule[1] / (2 if _half else 1)
		if action == "lukas" and GameState.lukas_knows("sentarse"):
			amount = int(amount * 1.5)
		got += amount
		if rule[2] != "":
			_say(rule[2], Color(0.7, 0.95, 0.7))
			GameState.change_mood(1.0)
	else:
		if rule[3] != "":
			_say(rule[3], Color(1, 0.75, 0.7))
			GameState.change_mood((-2.0 if current["type"] != "POLICIA" else -4.0) * (0.5 if GameState.has_skill("aguante") else 1.0))


func _say(text: String, c: Color) -> void:
	_bubble.text = text
	_bubble.add_theme_color_override("font_color", c)


func _finish() -> void:
	state = "done"
	_type_label.text = ""
	var line := "$%d. Leí bien a la gente. Casi siempre leo bien a la gente. Casi." % got if got > 0 else \
		"Cero pesos. Hoy la gente venía blindada. Mañana cambio de táctica."
	await Dialogue.talk([["", line]])
	GameState.add_money(got)
	TimeManager.skip(1.0)
	var back: Array = GameState.flags.get("pedir_return", ["res://scenes/world/City.tscn", "FromPedir"])
	SceneRouter.go(back[0], back[1])
