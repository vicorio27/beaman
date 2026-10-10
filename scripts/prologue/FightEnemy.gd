class_name FightEnemy
extends Brawler
## Matón: se acerca, se alinea con el protagonista y pega. Solo algunos atacan a la vez
## (los demás esperan a distancia), como en los beat 'em up clásicos.
## Con cuchillo pega más fuerte y, al quedar fuera de combate, lo suelta en el piso.
## GUARDIA (según guard_chance): después de guard_after golpes seguidos se cubre la cara. De frente ya no le
## entra nada salvo lo que rompe la guardia (la patada giratoria, una botella, el caño); por la
## espalda, sí. Si le siguen pegando contra la guardia (machacando), contragolpea y lo tira al piso.

const WAIT_DISTANCE := 70.0
const KNIFE_SHEET := "res://assets/prologue/enemy_knife.png"

@export var damage := 4
@export var cooldown_range := Vector2(0.9, 1.7)
@export var has_knife := false
## Puntos que da al quedar fuera de combate.
@export var points := 500
## Probabilidad de cubrirse después de dos golpes seguidos (0 = nunca).
@export var guard_chance := 0.0
## Después de cuántos golpes seguidos se cubre.
@export var guard_after := 2
const ENEMY_GUARD_TIME := 1.4
## Golpes contra la guardia antes de contragolpear.
const BLOCKS_TO_COUNTER := 3
## El último golpe lo paró la guardia (la arena no lo cuenta como golpe).
var blocked_last := false
var _guard := 0.0
var _streak := 0
var _streak_t := 0.0
var _blocks := 0

## Lo decide la arena: si puede ir a pegar o tiene que esperar.
var aggressive := false
var attack_range := 24.0
var _cooldown := 0.6
var _hit_done := false
## Ataque en curso: animación, cuadro en que pega, alcance, daño, si tira al piso.
var _attack := ["punch", 2, 28.0, 4, false]


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.ENEMY)


func _ready() -> void:
	super._ready()
	if has_knife:
		set_overlay(SideFrames.build(load(KNIFE_SHEET), SideFrames.ENEMY))


func tick(delta: float) -> void:
	_cooldown -= delta
	_streak_t -= delta
	if _streak_t <= 0.0:
		_streak = 0
	if _guard > 0.0:
		_guard -= delta
		set_facing(1 if arena.player.position.x > position.x else -1)
		if _guard <= 0.0:
			_blocks = 0
			state = State.IDLE
			play("idle")
		return
	if state == State.ATTACK:
		return
	var target: Node2D = arena.player
	if target == null:
		return
	var side := -1.0 if position.x < target.position.x else 1.0
	var want := Vector2(target.position.x + side * (attack_range - 4.0 if aggressive else WAIT_DISTANCE), target.position.y)
	var to := want - position
	var aligned := absf(target.position.y - position.y) < 5.0 and absf(target.position.x - position.x) <= attack_range + 2.0
	if aggressive and aligned and _cooldown <= 0.0:
		set_facing(1 if target.position.x > position.x else -1)
		_attack = choose_attack()
		_begin_attack()
	elif to.length() > 3.0:
		walk(to.normalized(), delta)
		set_facing(1 if target.position.x > position.x else -1)
	else:
		walk(Vector2.ZERO, delta)
		set_facing(1 if target.position.x > position.x else -1)


## Para sobreescribir (el jefe tiene varios ataques).
func choose_attack() -> Array:
	if has_knife:
		return ["stab", 2, attack_range + 6.0, damage + 4, false]
	return ["punch", 2, attack_range + 4.0, damage, false]


func take_hit(damage: int, from_x: float, heavy := false) -> void:
	if state in [State.DOWN, State.GETUP, State.OUT]:
		return
	var from_front := signf(from_x - position.x) == facing
	if _guard > 0.0 and from_front:
		blocked_last = true
		_blocks += 1
		if _blocks >= BLOCKS_TO_COUNTER:
			_counter()
		return
	super.take_hit(damage, from_x, heavy)
	if guard_chance <= 0.0 or state != State.HURT:
		return
	_streak += 1
	_streak_t = 0.9
	if _streak >= guard_after and randf() < guard_chance:
		_raise_guard()


func _raise_guard() -> void:
	_guard = ENEMY_GUARD_TIME
	_blocks = 0
	_streak = 0
	state = State.ATTACK  # quieto (tick maneja la guardia)
	sprite.stop()
	play("guard")
	if arena.has_method("on_guard"):
		arena.on_guard(self)


## Lo que rompe la guardia (patada giratoria, botella, caño): se le abre y el golpe entra entero.
func break_guard() -> void:
	if _guard <= 0.0:
		return
	_guard = 0.0
	_blocks = 0
	state = State.IDLE
	if arena.has_method("on_guard_broken"):
		arena.on_guard_broken(self)


func _counter() -> void:
	_guard = 0.0
	_blocks = 0
	set_facing(1 if arena.player.position.x > position.x else -1)
	_attack = ["counter", 1, attack_range + 8.0, damage + 5, true]
	_begin_attack()
	if arena.has_method("on_counter"):
		arena.on_counter(self)


func _begin_attack() -> void:
	state = State.ATTACK
	_hit_done = false
	sprite.stop()
	play(_attack[0])


func _on_frame_changed() -> void:
	if state == State.ATTACK and not _hit_done and sprite.animation == _attack[0] and sprite.frame == _attack[1]:
		_hit_done = true
		arena.resolve_attack(self, _attack[2], _attack[3], _attack[4])


func _on_animation_finished() -> void:
	if state == State.ATTACK:
		_cooldown = randf_range(cooldown_range.x, cooldown_range.y)
		state = State.IDLE
		play("idle")


## Fuera de combate: suelta el cuchillo, parpadea y desaparece.
func _go_out() -> void:
	state = State.OUT
	if has_knife and arena.has_method("drop_item"):
		arena.drop_item("knife", position)
		set_overlay(null)
	knocked_out.emit(self)
	var t := create_tween()
	for i in 4:
		t.tween_property(self, "modulate:a", 0.2, 0.08)
		t.tween_property(self, "modulate:a", 1.0, 0.08)
	t.tween_callback(queue_free)
