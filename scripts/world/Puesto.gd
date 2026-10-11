extends Node2D
## Favor de Doña Rosa: cuidarle el puesto una hora mientras va al médico.
## Llegan clientes de a uno y piden algo; hay que darles lo que pidieron a tiempo:
##   izquierda = empanada, arriba = arepa, derecha = aguapanela.
## A la mitad aparece un señor de negro preguntando por ella. La vacuna (la extorsión).
## Después del señor de negro se pone más difícil (una cosa nueva por mitad):
##   - pedidos dobles ("una empanada y una aguapanela"): las dos, en orden;
##   - Wilmer, el que pide fiado ("soy amigo de Rosa"): abajo = no fiar (señalar el letrero).
##     Si se le da algo, no lo paga.
## Al final vuelve Rosa: paga, y queda el miedo. Vínculo con Rosa +1.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CITY := "res://scenes/world/City.tscn"
const CUSTOMERS := 10
const PATIENCE := 3.5
const STALL := Vector2(160, 104)
const ROWS := [0, 3, 6, 9, 12, 15]
const ORDERS := {
	"empanada": ["move_left", "—Una empanada, porfa.", 1500],
	"arepa": ["move_up", "—Una arepa con queso.", 3000],
	"aguapanela": ["move_right", "—Una aguapanela, que hace frío.", 1000],
}
const DOUBLES := {
	"empanada": "una empanada", "arepa": "una arepa", "aguapanela": "una aguapanela",
}
## Los que piden fiado (en qué cliente llegan, contando desde el último).
const MOOCHERS := [3, 1]
const MOOCH_LINES := [
	["WILMER", "—Fíeme una arepa, mijo, que mañana le pago. Soy amigo de Rosa."],
	["WILMER", "—Otra vez yo. Lo de ahorita y una empanada, todo junto, el viernes. Rosa sabe."],
]
const COMPLAINTS := ["—¡Yo pedí otra cosa!", "—¿Usted es nuevo? Se le nota.", "—Doña Rosa no se equivoca nunca."]

var state := "intro"
var served := 0
var tips := 0
var sales := 0
var _left := CUSTOMERS
var _current: AnimatedSprite2D
var _want := ""
var _timer := 0.0
var _icon: Sprite2D
var _hud: Label
var _bubble: Label
var _legend: Label
var _brave := false
var _want2 := ""       # pedido doble: lo segundo (después de _want)
var _mooch := false     # este es Wilmer
var _mooch_n := 0
var _fiado := 0         # lo que se le fió a Wilmer
var _icon2: Sprite2D


func _ready() -> void:
	var ts: TileSet = load("res://assets/barrio/barrio_tileset.tres")
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	add_child(ground)
	for y in 12:
		for x in 20:
			ground.set_cell(Vector2i(x, y), 0, Vector2i(23 if y > 4 else 13, 0))
	for p in [["cafe", Vector2(70, 72)], ["bakery", Vector2(250, 72)]]:
		_prop(p[0], p[1])
	var me := AnimatedSprite2D.new()
	me.sprite_frames = CharacterFrames.protagonist()
	me.play("idle_down")
	me.position = STALL + Vector2(0, -12)
	add_child(me)
	_prop("food_cart", STALL + Vector2(0, 12))
	var lukas := Sprite2D.new()
	lukas.texture = Lukas.cell(3, 0)
	lukas.position = STALL + Vector2(26, 4)
	add_child(lukas)
	_icon = Sprite2D.new()
	_icon.visible = false
	add_child(_icon)
	_icon2 = Sprite2D.new()
	_icon2.visible = false
	add_child(_icon2)
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_hud = _label(ui, Vector2(6, 4))
	_bubble = _label(ui, Vector2(0, 0))
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size = Vector2(146, 10)
	_legend = _label(ui, Vector2(0, 158))
	_legend.size = Vector2(Controls.right_edge(), 20)  # a la derecha, los botones táctiles
	_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend.text = "IZQ empanada  ARRIBA arepa\nDER aguapanela"
	_legend.add_to_group("under_dialogue")
	_legend.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	_intro()


func _prop(art: String, foot: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/barrio/%s.png" % art)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = foot
	add_child(s)


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
	await Dialogue.talk([["DOÑA ROSA", "—Ya vengo, mijito. Las empanadas a mil quinientos, las arepas a tres mil, la aguapanela a mil."],
		["DOÑA ROSA", "—Y si alguien pregunta por mí... dígale que no estoy."],
		["DOÑA ROSA", "—Y señale el letrero. La gente entiende señas. Bueno, la gente buena. La mala entiende otras cosas."]])
	state = "play"
	_next()


func _next() -> void:
	if _left <= 0:
		_end()
		return
	if _left == CUSTOMERS / 2 and not GameState.flags.get("vacuna_vista", false):
		await _man_in_black()
	_left -= 1
	_want = ORDERS.keys().pick_random()
	_want2 = ""
	var second_half: bool = _left < CUSTOMERS / 2
	_mooch = second_half and _mooch_n < MOOCHERS.size() and _left == MOOCHERS[_mooch_n]
	if _mooch:
		_mooch_n += 1
	elif second_half and randf() < 0.55:
		_want2 = ORDERS.keys().pick_random()
	_current = AnimatedSprite2D.new()
	CharacterFrames.dress(_current, ROWS.pick_random())
	_current.modulate = GameState.same_tint(Color.from_hsv(randf(), 0.2, 1.0))
	_current.position = Vector2(-12, STALL.y + 44)
	_current.play("walk_side")
	_current.flip_h = true
	add_child(_current)
	var t := create_tween()
	t.tween_property(_current, "position:x", STALL.x - 2, 1.0)
	await t.finished
	if not is_instance_valid(_current):
		return
	_current.play("idle_up")
	_icon.texture = Items.icon(_want)
	_icon.position = _current.position + Vector2(-9 if _want2 != "" else 0, -30)
	_icon.visible = true
	_icon2.visible = _want2 != ""
	if _want2 != "":
		_icon2.texture = Items.icon(_want2)
		_icon2.position = _current.position + Vector2(9, -30)
		_icon2.modulate = Color(1, 1, 1, 0.55)  # lo segundo, más clarito hasta que se entregue lo primero
		var first: String = DOUBLES[_want]
		if _want == _want2:  # "dos arepas", no "una arepa y una arepa"
			_say("—Dos %ss, porfa." % _want, Color(0.95, 0.92, 0.85))
		else:
			_say("—%s y %s." % [first.left(1).to_upper() + first.substr(1), DOUBLES[_want2]], Color(0.95, 0.92, 0.85))
	elif _mooch:
		_current.modulate = Color(0.85, 0.75, 0.6)
		var line: Array = MOOCH_LINES[_mooch_n - 1]
		_say(line[1], Color(0.95, 0.92, 0.85))
		_legend.text = "IZQ empanada  ARRIBA arepa\nDER aguapanela  ABAJO no fiar"
	else:
		_say(ORDERS[_want][1], Color(0.95, 0.92, 0.85))
	_timer = PATIENCE * (1.0 - 0.35 * GameState.diff("reflejos")) * (1.5 if GameState.has_skill("sangre_fria") else 1.0)
	if _want2 != "":
		_timer *= 1.6
	state = "order"


func _process(delta: float) -> void:
	_hud.text = "VENDIDO %d   PROPINAS $%d   QUEDAN %d" % [served, tips, _left]
	if state != "order":
		return
	_timer -= delta
	if _timer <= 0.0:
		_serve("")


func _unhandled_input(event: InputEvent) -> void:
	if state != "order":
		return
	if _mooch and event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		_refuse()
		return
	for id in ORDERS:
		if event.is_action_pressed(ORDERS[id][0]):
			get_viewport().set_input_as_handled()
			if _want2 != "" and id == _want:  # lo primero del pedido doble: falta lo segundo
				_want = _want2
				_want2 = ""
				_icon.visible = false
				_icon2.modulate = Color.WHITE
				sales += ORDERS[id][2]
				return
			_serve(id)
			return


func _serve(id: String) -> void:
	state = "leaving"
	_icon.visible = false
	_icon2.visible = false
	if _mooch:
		_legend.text = "IZQ empanada  ARRIBA arepa\nDER aguapanela"
		if id == "":  # se cansó de esperar
			_say("—Bueno, mañana vuelvo. Mañana sí.", Color(0.95, 0.92, 0.85))
		else:  # se lo fió
			_fiado += ORDERS[id][2]
			_say("—¡Gracias, papito! El viernes sin falta. (No dice de qué año.)", Color(1, 0.75, 0.7))
			GameState.change_mood(-1.0)
		_leave()
		return
	if id == _want:
		served += 1
		sales += ORDERS[id][2]
		var tip := 500 if randf() < 0.35 else 0
		tips += tip
		_say("—Gracias, mijo." + (" Tome, para usted." if tip > 0 else ""), Color(0.7, 0.95, 0.7))
	else:
		_say(COMPLAINTS.pick_random() if id != "" else "—Ay, no, qué demora. Me voy.", Color(1, 0.75, 0.7))
		GameState.change_mood(-1.0)
	_leave()


## Wilmer: abajo = no fiar. Señala el letrero.
func _refuse() -> void:
	state = "leaving"
	_icon.visible = false
	_icon2.visible = false
	_legend.text = "IZQ empanada  ARRIBA arepa\nDER aguapanela"
	_say(["(Señala el letrero: \"HOY NO SE FÍA, MAÑANA SÍ\". Wilmer lee \"mañana sí\" y se va feliz.)",
		"(Señala el letrero otra vez. Wilmer: —Ya sé, ya sé. Mañana. Usted es igualito a Rosa.)"][mini(_mooch_n - 1, 1)],
		Color(0.7, 0.95, 0.7))
	_leave()


func _leave() -> void:
	var c := _current
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_callback(c.play.bind("walk_side"))
	t.tween_property(c, "position:x", 340.0, 1.4)
	t.tween_callback(c.queue_free)
	await get_tree().create_timer(1.2).timeout
	_bubble.text = ""
	_next()


func _say(text: String, color: Color) -> void:
	_bubble.text = text
	_bubble.add_theme_color_override("font_color", color)
	if is_instance_valid(_current):
		# Que termine justo encima del ícono del pedido (lo largo crece para arriba, no lo tapa).
		_bubble.size = Vector2(146, 10)
		var lines := _bubble.get_line_count()
		var h := lines * _bubble.get_line_height() + (lines - 1) * _bubble.get_theme_constant("line_spacing")
		# A la izquierda del cliente (no encima del carrito ni de él); lo largo crece para arriba.
		_bubble.position = Vector2(4.0, _current.position.y - 24.0 - h)
		_bubble.position.y = maxf(_bubble.position.y, 16.0)  # debajo de la barra de arriba


## El señor de negro. No compra nada.
func _man_in_black() -> void:
	GameState.flags["vacuna_vista"] = true
	var m := AnimatedSprite2D.new()
	CharacterFrames.dress(m, 0)  # como todos, pero de negro: eso sí lo ve
	m.modulate = Color(0.25, 0.22, 0.28)
	m.position = Vector2(-12, STALL.y + 44)
	m.play("walk_side")
	m.flip_h = true
	add_child(m)
	var t := create_tween()
	t.tween_property(m, "position:x", STALL.x - 2, 1.6)
	await t.finished
	m.play("idle_up")
	MusicDirector.force("")
	await Dialogue.talk([
		["SEÑOR", "—¿Y Doña Rosa?"],
		["", "(Señala la silla vacía de Rosa. Señala las empanadas.)"],
		["SEÑOR", "—No quiero empanadas. Dígale a Doña Rosa que esta semana son cincuenta. Hágale una seña, si no le salen las palabras. Que no se le olvide."],
	])
	var opts := ["Asentir"]
	if GameState.has_skill("sangre_fria"):
		opts.append("[SANGRE FRIA] Mirarlo a los ojos")
	GameState.flags["violencia"] = true  # el señor de negro: lo violento despierta a PLOMO
	GameState.flags["senor_negro"] = true
	var i := await Dialogue.talk([["", "(Lukas gruñe bajito. No le había oído ese ruido nunca.)"]], opts)
	if i == 1:
		_brave = true
		await Dialogue.talk([["SEÑOR", "—... Usted tiene ojos de haber visto cosas. Bueno. Dígale igual."]])
	else:
		await Dialogue.talk([["SEÑOR", "—Buen muchacho."]])
	GameState.change_mood(-5.0)
	var t2 := create_tween()
	t2.tween_callback(m.play.bind("walk_side"))
	t2.tween_property(m, "position:x", 340.0, 2.0)
	t2.tween_callback(m.queue_free)
	await t2.finished
	MusicDirector.force("city_day")


func _end() -> void:
	state = "done"
	var lines := [
		["DOÑA ROSA", "—Ya volví. ¿Cómo le fue? ¿Vendió?"],
		["", "(Le entrega la plata de %d empanadas. Después señala hacia donde se fue el señor de negro.)" % served],
		["DOÑA ROSA", "—... ¿Vino? ¿Qué le dijo?"],
		["", "(Le muestra cinco dedos. Después, el puño: un cero.)"],
		["DOÑA ROSA", "—Esta semana. La semana pasada eran treinta."],
		["DOÑA ROSA", "—No le cuente a nadie, mijito. Aquí el que cuenta, no cuenta más."],
	]
	if _brave:
		lines.append(["DOÑA ROSA", "—¿Lo miró a los ojos? Ay, mijito. Usted no sabe con quién se mete. Pero gracias."])
	if _fiado > 0:
		lines.append(["DOÑA ROSA", "—¿Y esto que falta? ... ¿Le fió a Wilmer? Ay, mijito. Wilmer no paga ni el bus. Eso se lo descuento, ¿sí? Con cariño."])
	elif _mooch_n > 0:
		lines.append(["DOÑA ROSA", "—¿Vino Wilmer y no le fió? ¡Usted sí aprende rápido! Wilmer me debe desde el Mundial. El de Brasil. El primero."])
	# Paga por lo que vendió (dos mil por cuidarle el carrito, mil por venta), menos lo fiado.
	var pay := maxi(0, 2000 + served * 1000 - _fiado)
	if served == 0:
		lines.append(["DOÑA ROSA", "—¿No vendió nada? ... Bueno. Por lo menos no se robaron el carrito. Tome dos mil, por vigilante."])
	else:
		lines.append(["DOÑA ROSA", "—Tome lo suyo: $%d, mil por cada venta. Las propinas también son suyas." % pay])
	await Dialogue.talk(lines)
	GameState.add_money(pay + tips)
	GameState.raise_bond("rosa")
	GameState.flags["vacuna_rosa"] = true
	TimeManager.skip(1.0)
	SceneRouter.go(CITY, "FromCafe", "", "(Cincuenta mil por semana por un carrito de empanadas. En este barrio no manda la policía.)")
