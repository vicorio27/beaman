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
## Algunas casas no se quedan calladas: abren y lo sacan a empujones (sale volando hacia atrás,
## cae sentado y se levanta). Solo unas pocas puertas del barrio.
@export var shove := false

## [fila de la hoja de transeúntes (quién abre), lo que grita]
const SHOVE_LINES := [
	[9, "SEÑOR: —¡Que no damos nada! ¡Fuera!"],
	[3, "SEÑORA: —¡Fuera de mi puerta, cochino!"],
	[9, "SEÑOR: —¡Lárguese o llamo a la policía!"],
	[3, "SEÑORA: —¡Otra vez usted! ¡Y con perro! ¡FUERA!"],
]
static var _shove_i := 0

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

var _player: Node2D
var _told := false
var _hint: Label


func _ready() -> void:
	add_to_group(Focus.GROUP)
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
	Focus.dim(self, _hint)
	if _player == null or SceneRouter.busy or GameState.input_blocked():
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var pushing := dir.dot(push_dir) > 0.6
	if Input.is_action_just_pressed("interact") and Focus.mine(self):
		_use(true)
	elif pushing:
		_use(false)


func _use(asked: bool) -> void:
	# Puertas con algo para entregar (el pedido de Marta, la carta de Samuel).
	if Conversations.door_hook(name):
		return
	if target_scene != "":
		SceneRouter.go(target_scene, target_spawn)
	elif shove and (asked or not _told):
		_told = true
		_shove()
	elif asked or not _told:
		# Empujando la puerta la línea sale una vez; con el botón, cada vez.
		_told = true
		Narrator.say(locked_text)


## Abre alguien y lo empuja: él sale para atrás, cae sentado y se levanta. La puerta se cierra de un golpe.
func _shove() -> void:
	var p := _player
	if p == null or not p.has_method("shoved"):
		Narrator.say(locked_text)
		return
	GameState.block_input(1.6)
	var dark := ColorRect.new()  # el hueco de la puerta abierta
	dark.color = Color(0.06, 0.05, 0.07)
	dark.size = Vector2(12, 22)
	dark.position = Vector2(-6, -26)
	add_child(dark)
	var who := AnimatedSprite2D.new()  # el de la casa, en el marco
	var shout: Array = SHOVE_LINES[_shove_i % SHOVE_LINES.size()]
	CharacterFrames.dress(who, shout[0])
	who.play("idle_down" if push_dir.y < 0 else "idle_up")
	who.offset = Vector2(0, -13)
	who.z_index = 1
	add_child(who)
	await get_tree().create_timer(0.25).timeout
	var arm := create_tween()  # el empujón
	arm.tween_property(who, "position", -push_dir * 5.0, 0.07)
	arm.tween_property(who, "position", Vector2.ZERO, 0.2)
	Narrator.say(shout[1])
	_shove_i += 1
	GameState.change_mood(-3.0)
	p.shoved(-push_dir)
	await get_tree().create_timer(0.55).timeout
	who.queue_free()
	dark.queue_free()  # ¡PUM!
