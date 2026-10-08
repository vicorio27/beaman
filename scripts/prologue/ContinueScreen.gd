extends Control
## Fin del sueño: pantalla de arcade "CONTINUE?" con cuenta regresiva.
## Apretar el botón no sirve: no hay créditos (en la vida real tampoco hay plata).
## Al llegar a 0: GAME OVER, y despierta bajo el puente.

const NEXT_SCENE := "res://scenes/world/City.tscn"
const NEXT_TITLE := "DIA 1 — 06:17"
const WAKE_LINE := "Otra vez ese sueño. Siempre termina igual: yo quedo de pie. Los demás, no. Desayuno, tampoco."
const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const TICK := 0.9

var _count := 9
var _title: Label
var _number: Label
var _credits: Label
var _score: Label
var _done := false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_score = _label("SCORE %06d" % Dream.score, 30, Color(0.8, 0.8, 0.8))
	_title = _label("CONTINUE?", 64, Color(1, 0.85, 0.3))
	_number = _label("9", 88, Color.WHITE, 16)
	_credits = _label("CREDITS 0", 150, Color(0.7, 0.7, 0.7))
	_countdown()


func _label(text: String, y: float, color: Color, size := 8) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(320, 20)
	add_child(l)
	return l


func _unhandled_input(event: InputEvent) -> void:
	if _done or not event.is_action_pressed("interact"):
		return
	# No hay monedas.
	_credits.text = "INSERT COIN"
	_credits.modulate = Color(1, 0.4, 0.4)
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_callback(func():
		_credits.text = "CREDITS 0"
		_credits.modulate = Color.WHITE)


func _countdown() -> void:
	while _count >= 0:
		_number.text = str(_count)
		await get_tree().create_timer(TICK).timeout
		_count -= 1
	_done = true
	_title.text = "GAME OVER"
	_number.text = ""
	_credits.text = ""
	await get_tree().create_timer(2.0).timeout
	# Empieza la vida real: Día 1, 06:17, mochila con la foto y la camiseta.
	GameState.new_game()
	GameState.learn("aguante")  # el primer sueño enseña a aguantar
	TimeManager.set_time(6, 17)
	SceneRouter.go(NEXT_SCENE, "Start", NEXT_TITLE, WAKE_LINE)


func debug_skip() -> void:
	_count = 0
