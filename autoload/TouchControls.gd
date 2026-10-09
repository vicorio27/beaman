extends CanvasLayer
## Controles táctiles para jugar desde el celular (la versión web). Solo aparecen con pantalla táctil.
## Izquierda: una palanca (cualquier dedo en la mitad izquierda de la pantalla la mueve).
## Derecha: A (acción), B (atrás), I (inventario), X (soltar), la huellita (Lukas: su menú), el librito
## (la libreta). Con una pantalla abierta (diálogo, mochila, libreta...): la palanca no se dibuja (sigue
## funcionando) y los botones se ponen en fila en la franja derecha (x > 286), que las pantallas dejan libre. Todo dispara las mismas acciones
## que el teclado (ver Controls.gd), así que el resto del juego no se entera.

const STICK_CENTER := Vector2(38, 140)
const STICK_RADIUS := 20.0
const DEADZONE := 0.3
const BUTTONS := [
	# acción, textura, posición jugando, posición con una pantalla abierta (null: se esconde)
	["interact", "touch_a", Vector2(286, 136), Vector2(292, 152)],
	["cancel", "touch_b", Vector2(260, 154), Vector2(294, 128)],
	["inventory", "touch_i", Vector2(296, 112), Vector2(298, 108)],
	["drop", "touch_x", Vector2(264, 128), Vector2(298, 88)],
	["sniff", "touch_l", Vector2(238, 132), null],
	["libreta", "touch_lib", Vector2(274, 106), Vector2(298, 68)],
]

var _stick_finger := -1
var _held := {}
var _knob: Sprite2D
var _base: Sprite2D
var _buttons: Array = []  # [TouchScreenButton, posición jugando, posición en pantalla]
var _ui_mode := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _has_touch():
		queue_free()
		return
	# Si no, cada dedo en la palanca también es un clic (y en PLOMO el clic dispara).
	Input.emulate_mouse_from_touch = false
	_base = Sprite2D.new()
	_base.texture = load("res://assets/ui/touch_stick_base.png")
	_base.position = STICK_CENTER
	add_child(_base)
	_knob = Sprite2D.new()
	_knob.texture = load("res://assets/ui/touch_stick_knob.png")
	_knob.position = STICK_CENTER
	add_child(_knob)
	for b in BUTTONS:
		var t := TouchScreenButton.new()
		t.texture_normal = load("res://assets/ui/%s.png" % b[1])
		t.action = b[0]
		t.position = b[2]
		t.passby_press = true
		var shape := CircleShape2D.new()
		shape.radius = t.texture_normal.get_width() * 0.5 + 3.0  # un poco más grande que el dibujo
		t.shape = shape
		t.shape_centered = true
		add_child(t)
		_buttons.append([t, b[2], b[3]])
	_apply_mode()


func _process(_delta: float) -> void:
	var ui: bool = GameState.ui_open or Dialogue.active
	if ui != _ui_mode:
		_ui_mode = ui
		_apply_mode()


## Jugando: todo en su lugar. Con una pantalla abierta: palanca invisible y botones a la franja derecha.
func _apply_mode() -> void:
	_base.visible = not _ui_mode
	_knob.visible = not _ui_mode
	for b in _buttons:
		var t: TouchScreenButton = b[0]
		var at = b[2] if _ui_mode else b[1]
		t.visible = at != null
		if at != null:
			t.position = at


func _has_touch() -> bool:
	return Controls.touch()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _stick_finger == -1 and event.position.x < 160.0:
			_stick_finger = event.index
			_move_stick(event.position)
		elif not event.pressed and event.index == _stick_finger:
			_stick_finger = -1
			_move_stick(STICK_CENTER)
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		_move_stick(event.position)


func _move_stick(at: Vector2) -> void:
	var v := (at - STICK_CENTER) / STICK_RADIUS
	if v.length() > 1.0:
		v = v.normalized()
	_knob.position = STICK_CENTER + v * STICK_RADIUS
	_axis("move_left", "move_right", v.x)
	_axis("move_up", "move_down", v.y)


## Manda eventos de acción (como TouchScreenButton), no solo Input.action_press: los menús y el
## diálogo escuchan eventos en _unhandled_input.
func _axis(neg: String, pos: String, value: float) -> void:
	for pair in [[neg, -value], [pos, value]]:
		var on: bool = pair[1] > DEADZONE
		if on == _held.has(pair[0]):
			continue
		if on:
			_held[pair[0]] = true
		else:
			_held.erase(pair[0])
		var e := InputEventAction.new()
		e.action = pair[0]
		e.pressed = on
		e.strength = 1.0 if on else 0.0
		Input.parse_input_event(e)
