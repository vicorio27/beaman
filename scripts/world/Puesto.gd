extends Node2D
## Favor de Doña Rosa: cuidarle el puesto una hora mientras va al médico.
## Llegan clientes de a uno y piden algo; hay que darles lo que pidieron a tiempo:
##   izquierda = empanada, arriba = arepa, derecha = aguapanela.
## A la mitad aparece un señor de negro preguntando por ella. La vacuna (la extorsión).
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
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_hud = _label(ui, Vector2(6, 4))
	_bubble = _label(ui, Vector2(0, 0))
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size = Vector2(140, 30)
	_legend = _label(ui, Vector2(0, 166))
	_legend.size = Vector2(320, 10)
	_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_legend.text = "IZQ empanada  ARRIBA arepa  DER aguapanela"
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
		["DOÑA ROSA", "—Y señale el letrero. La gente entiende señas. Bueno, la gente buena. La mala entiende otras cosas."],
		["ÉL", "Me dejó a cargo de un negocio con flujo de caja, inventario perecedero y riesgo de extorsión. Es lo más parecido a mi antiguo cargo."]])
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
	_icon.position = _current.position + Vector2(0, -30)
	_icon.visible = true
	_say(ORDERS[_want][1], Color(0.95, 0.92, 0.85))
	_timer = PATIENCE * (1.0 - 0.35 * GameState.diff("reflejos")) * (1.5 if GameState.has_skill("sangre_fria") else 1.0)
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
	for id in ORDERS:
		if event.is_action_pressed(ORDERS[id][0]):
			get_viewport().set_input_as_handled()
			_serve(id)
			return


func _serve(id: String) -> void:
	state = "leaving"
	_icon.visible = false
	if id == _want:
		served += 1
		sales += ORDERS[id][2]
		var tip := 500 if randf() < 0.35 else 0
		tips += tip
		_say("—Gracias, mijo." + (" Tome, para usted." if tip > 0 else ""), Color(0.7, 0.95, 0.7))
	else:
		_say(COMPLAINTS.pick_random() if id != "" else "—Ay, no, qué demora. Me voy.", Color(1, 0.75, 0.7))
		GameState.change_mood(-1.0)
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
		_bubble.position = _current.position + Vector2(-70, -64)


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
		["ÉL", "Chaqueta negra en un día de sol. Reloj de oro con la correa floja. Nadie en la fila lo mira. Todos lo están mirando."],
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
		await Dialogue.talk([["SEÑOR", "—... Usted tiene ojos de haber visto cosas. Bueno. Dígale igual."],
			["ÉL", "Le sostuve la mirada cuatro segundos. Él parpadeó en el tres. En otra vida eso habría sido el final de la conversación. En esta es el principio de un problema."]])
	else:
		await Dialogue.talk([["SEÑOR", "—Buen muchacho."], ["ÉL", "Me dijo buen muchacho. Como a un perro. Lukas lo miró como a una persona. Lukas fue más generoso."]])
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
	lines.append(["DOÑA ROSA", "—Tome lo suyo: diez mil. Las propinas también son suyas."])
	await Dialogue.talk(lines)
	GameState.add_money(10000 + tips)
	GameState.raise_bond("rosa")
	GameState.flags["vacuna_rosa"] = true
	TimeManager.skip(1.0)
	SceneRouter.go(CITY, "FromCafe", "", "Cincuenta mil por semana por un carrito de empanadas. Ya sé quién manda en este barrio. Y no es la policía.")
