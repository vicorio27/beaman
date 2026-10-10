class_name NPC
extends CharacterBody2D
## Persona de la vida real (vista desde arriba). Se para, mira al jugador cuando le habla y
## muestra "HABLAR" cuando está cerca. Lo que dice está en scripts/npc/Conversations.gd
## (una función por npc_id). Puede tener una ruta para caminar (Wilson con su carro).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

@export var npc_id := "german"
## Fila del personaje en la hoja de Kenney (0, 3, 6, 9, 12, 15).
@export var sheet_row := 6
## Radio en el que se le puede hablar (más grande si está detrás de un mostrador).
@export var talk_reach := Vector2(26, 34)
@export var face := "down"
## Ruta opcional (puntos en coordenadas del padre) que recorre ida y vuelta.
@export var route: PackedVector2Array = []
@export var walk_speed := 18.0

var talking := false
var sprite: AnimatedSprite2D
var _player: Node2D
var _hint: Label
var _route_i := 0


func _plain() -> void:
	modulate = Color.WHITE
	scale = Vector2.ONE


func _ready() -> void:
	add_to_group("npcs")
	add_to_group(Focus.GROUP)
	collision_layer = 1
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 5)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	add_child(shape)
	var shadow := Polygon2D.new()
	shadow.color = Color(0.18, 0.13, 0.18, 0.35)
	shadow.polygon = PackedVector2Array([Vector2(-5, -1), Vector2(-3, -3), Vector2(1, -3), Vector2(5, -2), Vector2(7, 0), Vector2(5, 2), Vector2(1, 2), Vector2(-3, 1)])
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	CharacterFrames.dress(sprite, sheet_row, npc_id, false)
	_plain.call_deferred()  # quien lo creó lo tiñe después (era para los muñecos de Kenney): se le quita
	sprite.position = Vector2(0, -8)
	add_child(sprite)
	_look(face)
	var area := Area2D.new()
	var ashape := CollisionShape2D.new()
	var arect := RectangleShape2D.new()
	arect.size = talk_reach
	ashape.shape = arect
	ashape.position = Vector2(0, talk_reach.y / 2.0 - 8.0)
	area.add_child(ashape)
	add_child(area)
	area.body_entered.connect(_on_enter)
	area.body_exited.connect(_on_exit)
	_hint = Label.new()
	_hint.text = "HABLAR"
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	_hint.position = Vector2(-24, -34)
	_hint.size = Vector2(48, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.z_index = 5
	add_child(_hint)


func _on_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body


func _on_exit(body: Node2D) -> void:
	if body == _player:
		_player = null


func _physics_process(_delta: float) -> void:
	_hint.visible = _player != null and not talking and not GameState.input_blocked()
	Focus.dim(self, _hint)
	if talking:
		velocity = Vector2.ZERO
		return
	if route.size() >= 2:
		_walk_route()
	if _player and Input.is_action_just_pressed("interact") and not GameState.input_blocked() and Focus.mine(self):
		_talk()


func _walk_route() -> void:
	if _player:
		velocity = Vector2.ZERO
		sprite.play("idle_" + ("side" if face in ["left", "right"] else face))
		return
	var target := route[_route_i]
	var to := target - position
	if to.length() < 2.0:
		_route_i = (_route_i + 1) % route.size()
		return
	velocity = to.normalized() * walk_speed
	move_and_slide()
	if absf(to.x) > absf(to.y):
		face = "right" if to.x > 0 else "left"
	else:
		face = "down" if to.y > 0 else "up"
	var dir := "side" if face in ["left", "right"] else face
	sprite.flip_h = face == "right"
	sprite.play("walk_" + dir)


func _talk() -> void:
	talking = true
	var to: Vector2 = _player.global_position - global_position
	if absf(to.x) > absf(to.y):
		_look("right" if to.x > 0 else "left")
	else:
		_look("down" if to.y > 0 else "up")
	await Conversations.run(npc_id, self)
	talking = false


func _look(dir: String) -> void:
	face = dir
	sprite.flip_h = dir == "right"
	sprite.play("idle_" + ("side" if dir in ["left", "right"] else dir))
