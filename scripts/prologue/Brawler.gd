class_name Brawler
extends Node2D
## Luchador de beat 'em up: se mueve en un plano (x = a lo largo de la calle, y = profundidad).
## No usa física: los golpes se resuelven por distancia (ver FightArena.resolve_attack).
## El origen del nodo está en los pies.

signal knocked_out(who: Brawler)

enum State { IDLE, WALK, ATTACK, HURT, DOWN, GETUP, OUT }

const HURT_TIME := 0.3
const DOWN_TIME := 1.1
const GETUP_TIME := 0.35
## Velocidad vertical relativa (la profundidad se recorre más lento, como en los beat 'em up clásicos).
const DEPTH_SPEED := 0.6

@export var sheet: Texture2D
@export var max_hp := 20
@export var speed := 50.0

var hp := 0
var state := State.IDLE
var facing := 1
var arena: Node
var _timer := 0.0
var _push := 0.0

var sprite: AnimatedSprite2D
## Para estirar el muñeco (Guillermo: gordo, muy gordo). Se pone antes de add_child.
var body_scale := Vector2.ONE
## Capa del arma (cuchillo, botella, caño): sigue la animación del cuerpo cuadro a cuadro.
var overlay: AnimatedSprite2D


func _ready() -> void:
	hp = max_hp
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.polygon = PackedVector2Array([Vector2(-8, 0), Vector2(-5, -2), Vector2(5, -2), Vector2(8, 0), Vector2(5, 2), Vector2(-5, 2)])
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.position = Vector2(0, -23)
	sprite.sprite_frames = build_frames()
	sprite.scale = body_scale
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)
	overlay = AnimatedSprite2D.new()
	overlay.position = sprite.position
	overlay.scale = body_scale
	overlay.visible = false
	add_child(overlay)
	play("idle")


## Pone (o saca, con null) la capa de un arma.
func set_overlay(frames: SpriteFrames) -> void:
	overlay.sprite_frames = frames
	overlay.visible = frames != null


func _process(_delta: float) -> void:
	if overlay.visible and overlay.sprite_frames.has_animation(sprite.animation):
		overlay.animation = sprite.animation
		overlay.frame = sprite.frame
		overlay.flip_h = sprite.flip_h


## Para sobreescribir: las animaciones de este personaje.
func build_frames() -> SpriteFrames:
	return SpriteFrames.new()


func play(anim: String) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func set_facing(dir: int) -> void:
	if dir != 0:
		facing = dir
		sprite.flip_h = dir < 0


func can_act() -> bool:
	return state == State.IDLE or state == State.WALK


## Mueve en el plano de la calle, sin salirse de la franja ni de la pantalla.
func walk(dir: Vector2, delta: float) -> void:
	if dir == Vector2.ZERO:
		state = State.IDLE
		play("idle")
		return
	state = State.WALK
	play("walk")
	if absf(dir.x) > 0.1:
		set_facing(signi(int(signf(dir.x))))
	position += Vector2(dir.x, dir.y * DEPTH_SPEED) * speed * delta
	_clamp()


func _clamp() -> void:
	if arena:
		var b: Rect2 = arena.walk_bounds(self)
		position = position.clamp(b.position, b.end)


## Recibe un golpe desde from_x. heavy = lo tira al piso.
func take_hit(damage: int, from_x: float, heavy := false) -> void:
	if state in [State.DOWN, State.GETUP, State.OUT]:
		return
	hp -= damage
	set_facing(1 if from_x > position.x else -1)
	_on_hurt(damage)
	if hp <= 0 or heavy:
		state = State.DOWN
		_timer = DOWN_TIME
		_push = -facing * 140.0
		play("fall")
	else:
		state = State.HURT
		_timer = HURT_TIME
		_push = -facing * 50.0
		sprite.stop()
		play("hurt")


func _physics_process(delta: float) -> void:
	if _push != 0.0:
		position.x += _push * delta
		_push = move_toward(_push, 0.0, 420.0 * delta)
		_clamp()
	_timer -= delta
	match state:
		State.HURT:
			if _timer <= 0.0:
				state = State.IDLE
				play("idle")
		State.DOWN:
			if _timer <= 0.0:
				if hp <= 0:
					_go_out()
				else:
					state = State.GETUP
					_timer = GETUP_TIME
					play(getup_anim())
		State.GETUP:
			if _timer <= 0.0:
				state = State.IDLE
				play("idle")
		State.OUT:
			pass
		_:
			tick(delta)
	# Los de más abajo se dibujan adelante.
	z_index = int(position.y)


## Para sobreescribir: lógica propia cuando puede actuar o está atacando.
func tick(_delta: float) -> void:
	pass


func getup_anim() -> String:
	return "getup"


## Para sobreescribir: qué hacer al quedar fuera de combate.
func _go_out() -> void:
	state = State.OUT
	knocked_out.emit(self)


## Para sobreescribir.
func _on_hurt(_damage: int) -> void:
	pass


func _on_frame_changed() -> void:
	pass


func _on_animation_finished() -> void:
	pass
