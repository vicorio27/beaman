extends CanvasLayer
## Controles táctiles para jugar desde el celular (la versión web). Aparecen según Controls.touch():
## solos con pantalla táctil, o siempre / nunca si se eligió en el título (CONTROLES EN PANTALLA).
## Tres disposiciones: caminando (la ciudad), minijuego (botones en la franja derecha, la palanca solo
## se ve mientras se toca) y pantalla abierta (diálogo, mochila...: palanca invisible).
## Izquierda: una palanca que nace donde cae el dedo (en cualquier parte de la mitad izquierda: así el
## pulgar no tapa al protagonista) y lo sigue si se va lejos.
## Derecha: A (acción), B (atrás), I (inventario), X (soltar), la huellita (Lukas: su menú), el librito
## (la libreta). En un minijuego o sueño, tocar la mitad derecha donde no hay botón trae los botones al
## pulgar: A debajo y los otros alrededor (salvo en PLOMO, que gira arrastrando por esa mitad).
## Con una pantalla abierta (diálogo, mochila, libreta...): la palanca no se dibuja (sigue
## funcionando) y los botones se ponen en fila en la franja derecha (x > 286), que las pantallas dejan libre. Todo dispara las mismas acciones
## que el teclado (ver Controls.gd), así que el resto del juego no se entera.

const STICK_HOME := Vector2(38, 140)  # donde se ve caminando mientras nadie la toca
const STICK_RADIUS := 20.0
const DEADZONE := 0.3
## Los botones del minijuego alrededor del pulgar (el centro de cada uno respecto al de A).
const CLUSTER := {"interact": Vector2.ZERO, "cancel": Vector2(-30, 6), "drop": Vector2(-2, -30),
	"sniff": Vector2(-28, -26)}
## Hasta dónde se dejan llevar (el centro de A): que ninguno se salga ni caiga en la mitad de la palanca.
const CLUSTER_MIN := Vector2(200, 42)
const CLUSTER_MAX := Vector2(305, 165)
const BUTTONS := [
	# acción, textura, posición caminando, con una pantalla abierta, en un minijuego (null: se esconde)
	["interact", "touch_a", Vector2(286, 136), Vector2(292, 152), Vector2(292, 152)],
	["cancel", "touch_b", Vector2(260, 154), Vector2(294, 128), Vector2(294, 128)],
	["inventory", "touch_i", Vector2(296, 112), Vector2(298, 108), null],
	["drop", "touch_x", Vector2(264, 128), Vector2(298, 88), Vector2(298, 108)],
	["sniff", "touch_l", Vector2(238, 132), null, Vector2(298, 88)],
	["libreta", "touch_lib", Vector2(274, 106), Vector2(298, 68), null],
	["craft", "touch_c", null, Vector2(298, 48), null],  # armar: solo con una pantalla abierta (la mochila)
	["pause", "touch_pausa", Vector2(304, 40), null, Vector2(304, 40)],  # pausa (como Start)
]

var _stick_finger := -1
var _stick_origin := STICK_HOME
var _cluster_at = null  # Vector2: donde el pulgar dejó los botones del minijuego (null: en la franja)
var _cluster_scene: Node
var _cluster_finger := -1
var _held := {}
var _knob: Sprite2D
var _base: Sprite2D
var _buttons: Array = []  # [TouchScreenButton, caminando, pantalla abierta, minijuego]
var _mode := ""  # world, ui, mini, off


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Si no, cada dedo en la palanca también es un clic (y en PLOMO el clic dispara).
	Input.emulate_mouse_from_touch = false
	_base = Sprite2D.new()
	_base.texture = load("res://assets/ui/touch_stick_base.png")
	_base.position = STICK_HOME
	add_child(_base)
	_knob = Sprite2D.new()
	_knob.texture = load("res://assets/ui/touch_stick_knob.png")
	_knob.position = STICK_HOME
	add_child(_knob)
	for b in BUTTONS:
		var t := TouchScreenButton.new()
		t.texture_normal = load("res://assets/ui/%s.png" % b[1])
		t.action = b[0]
		t.position = b[2] if b[2] != null else Vector2.ZERO
		t.passby_press = true
		var shape := CircleShape2D.new()
		shape.radius = t.texture_normal.get_width() * 0.5 + 3.0  # un poco más grande que el dibujo
		t.shape = shape
		t.shape_centered = true
		add_child(t)
		_buttons.append([t, b[2], b[3], b[4]])
	_apply_mode()


func _process(_delta: float) -> void:
	var m := _current_mode()
	if _cluster_at != null and (m == "world" or get_tree().current_scene != _cluster_scene):
		_cluster_at = null  # otro minijuego (o de vuelta a la calle): los botones arrancan en la franja
		_mode = ""
	if m != _mode:
		_mode = m
		_apply_mode()
	if _mode == "mini":  # la palanca del minijuego solo se ve mientras se toca
		_base.visible = _stick_finger != -1
		_knob.visible = _base.visible


func _current_mode() -> String:
	if not _has_touch():
		return "off"
	if Dialogue.active:
		return "ui"
	if Controls.minigame:  # (un minijuego encima del mundo: los penaltis, la pelota de Lukas)
		return "mini"
	if GameState.ui_open:
		return "ui"
	var scene := get_tree().current_scene
	if scene and scene.get_script() == preload("res://scripts/world/Location.gd"):
		return "world"
	return "mini"


## Caminando: todo en su lugar. Pantalla abierta: palanca invisible, botones a la franja derecha.
## Minijuego: botones a la franja derecha (solo los que sirven), palanca solo mientras se toca.
func _apply_mode() -> void:
	if _mode == "off":
		_release_all()
	_base.visible = _mode == "world"
	_knob.visible = _base.visible
	var col: int = {"world": 1, "ui": 2, "mini": 3}.get(_mode, -1)
	for b in _buttons:
		var t: TouchScreenButton = b[0]
		var at = b[col] if col > 0 else null
		t.visible = at != null
		if at != null:
			t.position = at
	if _mode == "mini" and _cluster_at != null:
		_layout_cluster()


func _layout_cluster() -> void:
	for b in _buttons:
		var t: TouchScreenButton = b[0]
		if t.visible and CLUSTER.has(t.action):
			t.position = _cluster_at + CLUSTER[t.action] - t.texture_normal.get_size() * 0.5


## El pulgar cayó en la mitad derecha, lejos de los botones: se vienen a él. No aprietan nada todavía
## (un toque perdido no dispara ni salta un menú); el siguiente toque ya cae en A.
func _place_cluster(at: Vector2, finger: int) -> void:
	_cluster_at = at.clamp(CLUSTER_MIN, CLUSTER_MAX)
	_cluster_scene = get_tree().current_scene
	_cluster_finger = finger
	_set_passby(false)  # el dedo que los trajo queda encima de A: que no la apriete al moverse
	_layout_cluster()


func _set_passby(on: bool) -> void:
	for b in _buttons:
		(b[0] as TouchScreenButton).passby_press = on


func _on_button(at: Vector2) -> bool:
	for b in _buttons:
		var t: TouchScreenButton = b[0]
		var r: float = (t.shape as CircleShape2D).radius
		if t.visible and at.distance_to(t.position + t.texture_normal.get_size() * 0.5) <= r:
			return true
	return false


## Solo en minijuegos y sueños (caminando, los botones son muchos y tienen su lugar), y no donde la
## escena usa la mitad derecha (PLOMO: arrastrar gira).
func _floats() -> bool:
	var scene := get_tree().current_scene
	return _mode == "mini" and not (scene and scene.get("touch_drag_right") == true)


## Al apagar los controles: que no quede una dirección apretada.
func _release_all() -> void:
	_stick_finger = -1
	_cluster_finger = -1
	_cluster_at = null
	if _buttons:
		_set_passby(true)
	if _knob:
		_stick_origin = STICK_HOME
		_move_stick(STICK_HOME)


func _has_touch() -> bool:
	return Controls.touch()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not _has_touch():
		Controls.touch_seen()  # ese toque solo los prende
		get_tree().call_group("ajustes", "_refresh")  # (el título y la pausa dicen cómo quedó)
		return
	if _mode == "off" or _mode == "":
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _on_button(event.position):
				return
			if event.position.x < 160.0:
				if _stick_finger == -1:  # la palanca nace debajo del dedo
					_stick_finger = event.index
					_stick_origin = event.position
					_move_stick(event.position)
			elif _floats():
				_place_cluster(event.position, event.index)
		elif event.index == _stick_finger:
			_stick_finger = -1
			_stick_origin = STICK_HOME
			_move_stick(STICK_HOME)
		elif event.index == _cluster_finger:
			_cluster_finger = -1
			_set_passby(true)
	elif event is InputEventScreenDrag and event.index == _stick_finger:
		_move_stick(event.position)


func _move_stick(at: Vector2) -> void:
	var d := at - _stick_origin
	if d.length() > STICK_RADIUS:  # la base sigue al dedo: para devolverse no hay que recorrer media pantalla
		_stick_origin = at - d.normalized() * STICK_RADIUS
	var v := (at - _stick_origin) / STICK_RADIUS
	_base.position = _stick_origin
	_knob.position = _stick_origin + v * STICK_RADIUS
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
