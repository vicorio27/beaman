extends Node2D
## Minijuego: sentado en la vereda con un vaso, pidiendo. Pasa la gente de a uno; arriba de cada
## uno se ve qué tipo de persona es. Mientras está cerca hay que elegir cómo acercarse:
##   arriba = pedir, derecha = un chiste, abajo = el truco de Lukas, izquierda = quedarse callado.
## A cada tipo le funciona otra cosa (aprenderlo es el juego). Equivocarse trae desprecio
## (baja el ánimo). Sin ánimo, los chistes no salen. Con Lukas sin comer, no hay truco.
## La segunda vez en el mismo día y lugar, la compasión rinde la mitad.
## Qué tipo es cada uno no está escrito: se lee por cómo se ve y cómo camina (el apurado va rápido).
## El cartelito con el tipo aparece cuando ya se lo conoce (después de la primera vez con ese tipo).
## Lukas se cansa: después del segundo truco seguido rinde menos (hay que alternar).
## Para que el día 5 no sea una tabla aprendida de memoria:
##   - Cada vez pasa UN especial (el gringo, el colega, la influencer, el predicador, el borracho, el
##     del banco). No sigue la tabla: anuncia lo que es con una frase al entrar y hay que leerla.
##     Los seis primeros salen en orden; después, al azar.
##   - El día cambia la calle: quincena (todo paga el doble), domingo (salen de misa: señoras),
##     lunes (nadie tiene plata ni ganas).
##   - Racha: tres aciertos seguidos dan $1.000 de más.

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
## Los especiales: uno por sesión. [fila, tinte, paso, frase al entrar, {acción: [chance, plata, sí, no]}]
## y opcional: lo que hace él si se queda callado, y el ánimo que eso le da.
const SPECIALS := {
	"GRINGO": {"row": 0, "tint": Color(1.0, 0.95, 0.7), "pace": 0.8,
		"hint": "—Oh my God, a beagle! Is he famous?",
		"rules": {"lukas": [1.0, 5000, "—Photo! ... Thank you, amigo. Here.", ""],
			"pedir": [0.3, 1000, "—Ehh... okay? Here.", "—Sorry, only Apple Pay."],
			"chiste": [0.0, 0, "", "—No Spanish. But I feel judged."],
			"nada": [1.0, 0, "", ""]}},
	"COLEGA": {"row": 9, "tint": Color(0.7, 0.68, 0.62), "pace": 0.9,
		"hint": "(Viene uno con un vaso igualito al suyo.)",
		"rules": {"chiste": [1.0, 1000, "—¡Ja! Buen cartel. Tome, colega. Me lo copio.", ""],
			"pedir": [0.0, 0, "", "—¿Me pide a mí? Somos competencia."],
			"lukas": [0.5, 500, "—Yo tenía uno así. Tome, por él.", "—Perro yo no tengo. Ni nada."],
			"nada": [1.0, 0, "", ""]}},
	"INFLUENCER": {"row": 15, "tint": Color(1.0, 0.75, 0.95), "pace": 0.9,
		"hint": "—¡Hola, mi gente! Aquí en la calle, re real...",
		"rules": {"chiste": [1.0, 3000, "—¡Eso! ¡Para el video! Tome. #humildad", ""],
			"pedir": [0.0, 0, "", "—Bro, pedir así directo no da views."],
			"lukas": [0.7, 2000, "—¡El perrito! Esto se hace viral.", "—El perro no mira a cámara. Next."],
			"nada": [0.0, 0, "", "—Ni para contenido sirve. Next."]}},
	"PREDICADOR": {"row": 6, "tint": Color(1.0, 1.0, 0.95), "pace": 0.7,
		"hint": "—¡Hermano! ¿Usted ya conoce la Palabra?",
		"me_nada": "(Lo escucha. Veinte minutos. Asiente en las partes tristes.)",
		"rules": {"nada": [1.0, 2000, "—Me escuchó todo. Nadie me escucha. Tome.", ""],
			"pedir": [0.0, 0, "", "—Pedir es fácil. ¿Y la fe, hermano?"],
			"chiste": [0.0, 0, "", "—¡El diablo también hace chistes!"],
			"lukas": [0.3, 500, "—Los animalitos son de Dios. Tome.", "—Ese animal tiene cara de pecado."]}},
	"BORRACHO": {"row": 9, "tint": Color(1.0, 0.7, 0.65), "pace": 0.6,
		"hint": "—¡Feliz cumpleaños! ... ¿No es? ¡Igual!",
		"rules": {"pedir": [0.7, 3000, "—¡Tome! ¡Tome todo! ... No, todo no. Esto.", "—¿Plata? Me robaron. Fui yo."],
			"chiste": [0.6, 1000, "—¡JAJAJA! No lo leí. Tome.", "—No leo así de borroso."],
			"lukas": [0.3, 500, "—¡Se parece a mi suegra! Tome.", "—Ese perro me está juzgando."],
			"nada": [1.0, 0, "", ""]}},
	"EL DEL BANCO": {"row": 6, "tint": Color(0.75, 0.78, 0.85), "pace": 1.0,
		"hint": "(Es el del banco. El que le negó el crédito.)",
		"me_nada": "(No le pide nada. Frente en alto. Panza en el piso.)", "mood_nada": 3.0,
		"rules": {"pedir": [0.6, 2000, "—... tome. No me mire así.", "—No tiene historial, señor."],
			"chiste": [0.0, 0, "", "—Su puntaje tampoco da risa."],
			"lukas": [0.4, 1000, "—El perro sí parece buen pagador.", "—Los perros no son garantía."],
			"nada": [1.0, 0, "", ""]}},
}
const SPECIAL_ORDER := ["GRINGO", "COLEGA", "INFLUENCER", "PREDICADOR", "BORRACHO", "EL DEL BANCO"]
const DAY_LINES := {
	"quincena": "(Es quincena. La gente anda con plata y con culpa. La mejor combinación.)",
	"domingo": "(Domingo. Salen de misa con la conciencia recién lavada. Y las señoras, en manada.)",
	"lunes": "(Lunes. Nadie tiene plata ni ganas. Yo tampoco, pero yo no tengo opción.)",
}
const STREAK_LINES := ["(Racha de tres. Leo a la gente como la DIAN: y les cobro.)",
	"(Otra racha. Si esto fuera un trabajo, me ascendían. A pedir más.)"]

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
var _lukas_uses := 0  # trucos seguidos (se cansa)
var _people_left := PEOPLE
var _line_i := 0
var _day_mod := ""  # "quincena", "domingo", "lunes" o nada
var _streak := 0
var _streaks := 0


## La regla de un tipo (de la tabla o de los especiales): [fila, tinte, {acción: regla}].
func _data(type: String) -> Array:
	if SPECIALS.has(type):
		var sp: Dictionary = SPECIALS[type]
		return [sp["row"], sp["tint"], sp["rules"]]
	return TYPES[type]


func _ready() -> void:
	var back: Array = GameState.flags.get("pedir_return", ["res://scenes/world/City.tscn", "FromPedir"])
	_place = back[0]
	var key := "pedir_%s" % _place.get_file()
	_half = GameState.flags.get(key, -1) == GameState.day
	GameState.flags[key] = GameState.day
	_build()
	var d := GameState.day
	_day_mod = "quincena" if d % 15 == 0 else ("domingo" if d % 7 == 0 else ("lunes" if d % 7 == 1 and d > 1 else ""))
	for i in PEOPLE:
		var t: String = TYPES.keys().pick_random()
		if _day_mod == "domingo" and t != "SEÑORA" and randf() < 0.4:
			t = "SEÑORA"
		queue.append(t)
	var n := int(GameState.flags.get("pedir_esp_n", 0))
	GameState.flags["pedir_esp_n"] = n + 1
	queue.insert(randi_range(2, 6), SPECIAL_ORDER[n] if n < SPECIAL_ORDER.size() else SPECIAL_ORDER.pick_random())
	queue.resize(PEOPLE)
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
	_legend.size = Vector2(Controls.right_edge(), 20)  # a la derecha, los botones táctiles
	_legend.add_to_group("under_dialogue")
	_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend.text = "ARRIBA vaso  DER cartel\nABAJO %s  IZQ nada" % ("Lukas" if GameState.lukas_alive() else "-----")
	_legend.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	_type_label = _label(ui, Vector2(0, 0))
	_type_label.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_bubble = _label(ui, Vector2(0, 0))
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size = Vector2(150, 30)
	var bg := StyleBoxFlat.new()  # fondo oscuro: que se lea encima de los letreros de las casas
	bg.bg_color = Color(0.05, 0.04, 0.06, 0.6)
	bg.set_content_margin_all(2)
	_bubble.add_theme_stylebox_override("normal", bg)
	_me_line = _label(ui, Vector2(0, 116))
	_me_line.size = Vector2(Controls.right_edge(), 20)
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
	if DAY_LINES.has(_day_mod):
		lines.append(["", DAY_LINES[_day_mod]])
	await Dialogue.talk(lines)
	state = "play"
	_next()


func _next() -> void:
	if queue.is_empty():
		_finish()
		return
	var type: String = queue.pop_front()
	var spr := AnimatedSprite2D.new()
	CharacterFrames.dress(spr, _data(type)[0])
	spr.modulate = GameState.same_tint(_data(type)[1])
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
	var special := SPECIALS.has(current["type"])
	var pace: float = SPECIALS[current["type"]]["pace"] if special else \
		(1.8 if current["type"] == "APURADO" else (0.8 if current["type"] == "SEÑORA" else 1.0))
	if special and not current["done"] and not current.get("hinted", false) and spr.position.x > 24.0:
		current["hinted"] = true  # el especial se anuncia: hay que leerlo
		_say(SPECIALS[current["type"]]["hint"], Color(0.9, 0.9, 0.95))
	spr.position.x += WALK_SPEED * pace * delta * (0.4 if current["done"] and spr.position.x < ZONE.y else 1.0)
	var known: Array = GameState.flags.get("pedir_conocidos", [])
	_type_label.text = current["type"] if current["type"] in known or special else "?"
	_type_label.position = spr.position + Vector2(-_type_label.text.length() * 4.0, -34)
	# Que no se salgan de la pantalla ("BRERO") ni se metan debajo de los botones táctiles.
	_type_label.position.x = clampf(_type_label.position.x, 2.0, Controls.right_edge() - _type_label.text.length() * 8.0)
	_bubble.visible = _bubble.text != ""
	# El globo crece hacia arriba desde el cartelito del tipo: nunca se le monta encima.
	_bubble.position = spr.position + Vector2(-75, -36.0 - maxi(1, _bubble.get_line_count()) * 10.0)
	_bubble.position.x = clampf(_bubble.position.x, 2.0, Controls.right_edge() - _bubble.size.x)
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
	var known: Array = GameState.flags.get("pedir_conocidos", [])
	var sp: Dictionary = SPECIALS.get(current["type"], {})
	if sp.is_empty() and not current["type"] in known:
		known.append(current["type"])  # después de verlo reaccionar, ya sabe qué tipo de persona es
		GameState.flags["pedir_conocidos"] = known
	if action == "lukas":
		_lukas_uses += 1
	else:
		_lukas_uses = 0
	var rule: Array = _data(current["type"])[2][action]
	var chance: float = rule[0]
	if action != "nada":
		var mine: Array = MY_LINES[action]
		_me_line.text = mine[_line_i % mine.size()]
		_line_i += 1
	elif sp.has("me_nada"):
		_me_line.text = sp["me_nada"]
	if action == "nada" and sp.has("mood_nada"):
		GameState.change_mood(sp["mood_nada"])
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
	if action == "lukas" and _lukas_uses > 2 and GameState.lukas_alive():
		chance *= maxf(0.3, 1.0 - 0.25 * (_lukas_uses - 2))  # cansado de hacer lo mismo
		_me_line.text = "(Lukas hace el truco bostezando. Ya lo hizo %d veces seguidas.)" % _lukas_uses
	if _day_mod == "lunes":
		chance *= 0.75
	if randf() < chance:
		var amount: int = rule[1] / (2 if _half else 1) * (2 if _day_mod == "quincena" else 1)
		if action == "lukas" and GameState.lukas_knows("sentarse"):
			amount = int(amount * 1.5)
		got += amount
		if amount > 0:
			_streak += 1
			if _streak % 3 == 0:
				got += 1000
				_me_line.text = STREAK_LINES[_streaks % STREAK_LINES.size()]
				_streaks += 1
		if rule[2] != "":
			_say(rule[2], Color(0.7, 0.95, 0.7))
			GameState.change_mood(1.0)
	else:
		_streak = 0
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
