class_name Door
extends Area2D
## Puerta. Se usa caminando hacia ella (push_dir) o con el botón de interactuar.
## Con target_scene vacío es una puerta cerrada: muestra locked_text.

@export_file("*.tscn") var target_scene := ""
## Marker2D de la escena destino donde aparece el jugador.
@export var target_spawn := ""
## Dirección en la que hay que caminar para atravesarla.
@export var push_dir := Vector2.UP
@export_multiline var locked_text := "Está cerrado."

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

var _player: Node2D
var _told := false
var _hint: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_hint = Label.new()
	_hint.text = "TOCAR" if target_scene == "" else ("SALIR" if push_dir.y > 0 else "ENTRAR")
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.size = Vector2(56, 10)
	# Arriba de la puerta si se entra desde abajo; abajo si se sale hacia abajo.
	_hint.position = Vector2(-28, -36) if push_dir.y < 0 else Vector2(-28, -40)
	_hint.z_index = 5
	_hint.visible = false
	add_child(_hint)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_hint.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_told = false
		_hint.visible = false


func _physics_process(_delta: float) -> void:
	if _player == null or SceneRouter.busy or GameState.input_blocked():
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var pushing := dir.dot(push_dir) > 0.6
	if Input.is_action_just_pressed("interact"):
		_use(true)
	elif pushing:
		_use(false)


func _use(asked: bool) -> void:
	# Puertas con algo para entregar (el pedido de Marta, la carta de Samuel).
	if Conversations.door_hook(name):
		return
	if target_scene != "":
		SceneRouter.go(target_scene, target_spawn)
	elif asked or not _told:
		# Empujando la puerta la línea sale una vez; con el botón, cada vez.
		_told = true
		Narrator.say(locked_text)
