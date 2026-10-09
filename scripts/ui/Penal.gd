class_name Penal
extends CanvasLayer
## Atajar penaltis con los pelados del lote. El que patea toma carrera y, justo antes, se le va el
## cuerpo para un lado (casi siempre es para donde patea; a veces engaña). Hay que tirarse a tiempo:
## izquierda, arriba (quedarse en el medio) o derecha, antes de que llegue la pelota.
##   var saves: int = await Penal.play(self, [[nombre, frase], ...])

signal _done(saves: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const GOAL := Rect2(112, 62, 96, 40)
const SPOT_Y := 128.0  # donde está la pelota (el punto penal)
const RUNUP := 1.1  # la carrera; a los 0.6 se le va el cuerpo
const TELL_AT := 0.6
const FLY := 0.5  # lo que tarda la pelota en llegar
const TRUTH := 0.72  # qué tanto el cuerpo dice la verdad

var _shots: Array = []
var _i := 0
var _saves := 0
var _state := "runup"
var _t := 0.0
var _aim := 1  # 0 izquierda, 1 medio, 2 derecha
var _tell := 1
var _dive := -1
var _guard := 0.3
var _ball: ColorRect
var _keeper: ColorRect
var _kicker: ColorRect
var _arrow: Label
var _who: Label
var _msg: Label
var _count: Label


static func play(parent: Node, shots: Array) -> int:
	var ui := Penal.new()
	ui._shots = shots
	parent.get_tree().root.add_child(ui)
	var res: int = await ui._done
	ui.queue_free()
	return res


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.2, 0.12)  # el lote; debajo de la barra de arriba (no la tapa)
	panel.position = Vector2(40, 34)
	panel.size = Vector2(240, 144)
	add_child(panel)
	for r in [Rect2(GOAL.position.x - 2, GOAL.position.y - 2, GOAL.size.x + 4, 2),  # travesaño y palos (dos morrales)
			Rect2(GOAL.position.x - 2, GOAL.position.y, 3, GOAL.size.y), Rect2(GOAL.end.x - 1, GOAL.position.y, 3, GOAL.size.y)]:
		var c := ColorRect.new()
		c.color = Color(0.85, 0.82, 0.75)
		c.position = r.position
		c.size = r.size
		add_child(c)
	_keeper = ColorRect.new()  # él: saco gris
	_keeper.color = Color(0.32, 0.34, 0.42)
	_keeper.size = Vector2(10, 22)
	add_child(_keeper)
	_kicker = ColorRect.new()  # el pelado
	_kicker.color = Color(0.85, 0.45, 0.3)
	_kicker.size = Vector2(8, 14)
	add_child(_kicker)
	_ball = ColorRect.new()
	_ball.color = Color(0.95, 0.95, 0.92)
	_ball.size = Vector2(5, 5)
	add_child(_ball)
	_arrow = _label(Vector2(0, 0), Color(1, 0.85, 0.3))
	_who = _label(Vector2(44, 38), Color(0.95, 0.85, 0.55))
	_who.size = Vector2(232, 20)
	_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg = _label(Vector2(44, 150), Color(0.93, 0.91, 0.87))
	_msg.size = Vector2(232, 10)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count = _label(Vector2(44, 164), Color(0.6, 0.58, 0.55))
	_count.size = Vector2(232, 10)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_new_shot()


func _label(pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(l)
	return l


func _zone_x(z: int) -> float:
	return GOAL.position.x + GOAL.size.x * (0.17 + z * 0.33)


func _new_shot() -> void:
	_state = "runup"
	_t = 0.0
	_dive = -1
	_aim = randi() % 3
	_tell = _aim if randf() < TRUTH else [0, 1, 2].filter(func(z): return z != _aim).pick_random()
	var s: Array = _shots[_i % _shots.size()]
	_who.text = "%s: %s" % [s[0], s[1]]
	_msg.text = "Mírale el cuerpo.  <-  ^  ->"
	_count.text = "Penal %d de %d   atajados %d" % [_i + 1, _shots.size(), _saves]
	_arrow.text = ""
	_keeper.position = Vector2(_zone_x(1) - 5, GOAL.end.y - 22)
	_ball.position = Vector2(_zone_x(1) - 2, SPOT_Y)
	_kicker.position = Vector2(_zone_x(1) - 4 + 30, SPOT_Y - 6)


func _process(delta: float) -> void:
	_guard -= delta
	_t += delta
	match _state:
		"runup":
			_kicker.position.x = lerpf(_zone_x(1) + 26, _zone_x(1) + 2, minf(1.0, _t / RUNUP))
			if _t >= TELL_AT and _arrow.text == "":
				_arrow.text = ["<", "^", ">"][_tell]  # se le va el cuerpo
				_arrow.position = _kicker.position + Vector2(-14 + _tell * 10, -14)
				_kicker.position.x += (_tell - 1) * 3.0
			if _t >= RUNUP:
				_state = "fly"
				_t = 0.0
		"fly":
			var k := minf(1.0, _t / FLY)
			var to := Vector2(_zone_x(_aim) - 2, GOAL.position.y + 14 + (6 if _aim == 1 else 0))
			_ball.position = Vector2(_zone_x(1) - 2, SPOT_Y).lerp(to, k) - Vector2(0, sin(k * PI) * 10.0)
			if k >= 1.0:
				_resolve()
		"show":
			if _t > 1.1:
				_i += 1
				if _i >= _shots.size():
					_close()
				else:
					_new_shot()


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0 or _state in ["show", "closed"] or _dive != -1:
		return
	var z := -1
	if event.is_action_pressed("move_left"):
		z = 0
	elif event.is_action_pressed("move_up") or event.is_action_pressed("interact"):
		z = 1
	elif event.is_action_pressed("move_right"):
		z = 2
	if z == -1:
		return
	get_viewport().set_input_as_handled()
	_dive = z
	_keeper.position.x = _zone_x(z) - 5
	if z != 1:
		_keeper.size = Vector2(22, 10)  # tirado, a lo largo
		_keeper.position = Vector2(_zone_x(z) - 11, GOAL.end.y - 14)


func _resolve() -> void:
	_state = "show"
	_t = 0.0
	var saved := _dive == _aim
	if saved:
		_saves += 1
		_msg.text = ["¡ATAJADA! Con la panza.", "¡La saca con la punta de los dedos!", "¡Le pega en la cara y sale! Cuenta."].pick_random()
	elif _dive == -1:
		_msg.text = "Gol. Ni se movió. Llegó tarde."
	else:
		_msg.text = ["Gol. Por el otro lado.", "Gol. Lo engañó con el cuerpo.", "Gol. Los pelados lo celebran como un Mundial."].pick_random()
	_count.text = "Penal %d de %d   atajados %d" % [_i + 1, _shots.size(), _saves]
	_keeper.size = Vector2(10, 22)


func _close() -> void:
	if _state == "closed":
		return
	_state = "closed"
	GameState.ui_open = false
	GameState.block_input(0.2)
	_done.emit(_saves)
