class_name FightPlayer
extends Brawler
## Protagonista en el sueño beat 'em up.
##   - Sin arma: golpe, golpe, patada (la patada tira al piso).
##   - Parado sobre un arma + botón: la agarra.
##   - Cuchillo / caño: cada botón es un ataque con el arma; se gastan con el uso.
##   - Botella: se tira hacia adelante y se rompe contra el primero que agarra.
##   - Si lo tiran al piso, suelta el arma.
## Si se queda sin vida no hay game over: cae y se levanta con media vida.

signal hurt(hp_ratio: float)

## Combo: animación, cuadro en que pega, alcance, daño, si tira al piso.
const COMBO := [
	["punch", 2, 26.0, 5, false],
	["punch2", 1, 26.0, 6, false],
	["kick", 3, 30.0, 9, true],
]
const COMBO_WINDOW := 0.45

const WEAPONS := {
	"knife": {"sheet": "res://assets/prologue/player_knife.png", "reach": 32.0, "damage": 9, "heavy": false, "uses": 12},
	"pipe": {"sheet": "res://assets/prologue/player_pipe.png", "reach": 38.0, "damage": 11, "heavy": true, "uses": 6},
	"bottle": {"sheet": "res://assets/prologue/player_bottle.png", "throw": true, "uses": 1},
	# El que deja Lilato: no se gasta y es lo único que lastima a la serpiente.
	"superknife": {"sheet": "res://assets/prologue/player_superknife.png", "reach": 36.0, "damage": 14, "heavy": false, "uses": 9999},
}
const WEAPON_ANIM := "punch2"
const WEAPON_HIT_FRAME := 1

var weapon := ""
var crouching := false
var _uses := 0
var _step := -1
var _queued := false
var _since_attack := 99.0
var _hit_done := false
var _weapon_frames := {}


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.PLAYER)


func equip(kind: String) -> void:
	weapon = kind
	_uses = WEAPONS[kind]["uses"]
	if not _weapon_frames.has(kind):
		_weapon_frames[kind] = SideFrames.build(load(WEAPONS[kind]["sheet"]), SideFrames.PLAYER)
	set_overlay(_weapon_frames[kind])


func unequip() -> void:
	weapon = ""
	set_overlay(null)


func tick(delta: float) -> void:
	_since_attack += delta
	if SceneRouter.busy:
		walk(Vector2.ZERO, delta)
		return
	var attack := Input.is_action_just_pressed("interact")
	if state == State.ATTACK:
		if attack:
			_queued = true
		return

	# Agacharse (solo donde la escena lo permite, p. ej. el techo del camión).
	crouching = arena.has_method("crouch_allowed") and arena.crouch_allowed() and Input.is_action_pressed("move_down")
	if crouching:
		state = State.IDLE
		play("crouch")
		return

	if attack:
		if weapon == "" and arena.has_method("try_pickup") and arena.try_pickup(self):
			return
		if weapon != "":
			_start_weapon_attack()
		else:
			var next := _step + 1 if _since_attack < COMBO_WINDOW and _step < COMBO.size() - 1 else 0
			_start_attack(next)
		return
	walk(Input.get_vector("move_left", "move_right", "move_up", "move_down"), delta)


func _start_attack(step: int) -> void:
	_step = step
	_queued = false
	_hit_done = false
	state = State.ATTACK
	sprite.stop()
	play(COMBO[step][0])


func _start_weapon_attack() -> void:
	_step = -2  # -2 = ataque con arma
	_queued = false
	_hit_done = false
	state = State.ATTACK
	sprite.stop()
	play(WEAPON_ANIM)


func _on_frame_changed() -> void:
	if state != State.ATTACK or _hit_done:
		return
	if _step == -2:
		if sprite.frame == WEAPON_HIT_FRAME:
			_hit_done = true
			_use_weapon()
		return
	var c: Array = COMBO[_step]
	if sprite.animation == c[0] and sprite.frame == c[1]:
		_hit_done = true
		arena.resolve_attack(self, c[2], c[3], c[4])


func _use_weapon() -> void:
	var w: Dictionary = WEAPONS[weapon]
	if w.get("throw", false):
		arena.throw_item(self, weapon)
		unequip()
		return
	arena.resolve_attack(self, w["reach"], w["damage"], w["heavy"])
	_uses -= 1
	if _uses <= 0:
		if arena.has_method("break_item"):
			arena.break_item(weapon, position)
		unequip()


func _on_animation_finished() -> void:
	if state != State.ATTACK:
		return
	_since_attack = 0.0
	if _step >= 0 and _queued and _step < COMBO.size() - 1:
		_start_attack(_step + 1)
	else:
		if _step == COMBO.size() - 1 or _step == -2:
			_step = -1
		state = State.IDLE
		play("idle")


func take_hit(damage: int, from_x: float, heavy := false) -> void:
	super.take_hit(damage, from_x, heavy)
	if state == State.DOWN and weapon != "":
		if arena.has_method("drop_item"):
			arena.drop_item(weapon, position + Vector2(-facing * 10, 0))
		unequip()


func getup_anim() -> String:
	return "crouch"


func _on_hurt(_damage: int) -> void:
	_step = -1
	_queued = false
	hurt.emit(clampf(float(hp) / max_hp, 0.0, 1.0))


## Sin game over: se levanta con media vida.
func _go_out() -> void:
	hp = max_hp / 2
	state = State.GETUP
	_timer = GETUP_TIME * 2
	play("crouch")
	hurt.emit(float(hp) / max_hp)
