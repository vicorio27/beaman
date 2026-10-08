class_name ServiceSpot
extends Area2D
## Un lugar que se usa con el botón (el baño público, la pensión). Lo que pasa está en
## Conversations (mismo registro que las personas: Conversations.run(service_id)).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

@export var service_id := "bano"
@export var hint := "USAR"
@export var area := Vector2(20, 14)

var _player: Node2D
var _hint: Label


func _ready() -> void:
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = area
	s.shape = r
	add_child(s)
	_hint = Label.new()
	_hint.text = hint
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	_hint.position = Vector2(-36, -40)
	_hint.size = Vector2(72, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.z_index = 5
	_hint.visible = false
	add_child(_hint)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(b: Node2D) -> void:
	if b.is_in_group("player"):
		_player = b
		_hint.visible = true


func _on_exit(b: Node2D) -> void:
	if b == _player:
		_player = null
		_hint.visible = false


func _process(_delta: float) -> void:
	_hint.visible = _player != null and not GameState.input_blocked()
	if _player == null or GameState.input_blocked() or SceneRouter.busy:
		return
	if Input.is_action_just_pressed("interact"):
		Conversations.run(service_id, self)
