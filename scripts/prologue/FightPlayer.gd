class_name FightPlayer
extends Brawler
## Protagonista en el sueño beat 'em up.
##   - Sin arma: golpe, golpe, patada (la patada tira al piso).
##   - Botón mantenido y soltado (sin arma): patada giratoria. Pega adelante y atrás, tira al piso
##     y rompe la guardia de los que se cubren. Machacando nunca se carga: pide calma.
##   - Parado sobre un arma + botón: la agarra.
##   - Cuchillo / caño: cada botón es un ataque con el arma; se gastan con el uso.
##   - Botella: si hay alguien al lado, se la rompe en la cabeza; si están lejos, se la tira.
##   - Si lo tiran al piso, suelta el arma.
##   - El botón hace lo que tiene sentido: si el único a tiro está atrás, se da vuelta y le pega;
##     con un matón encima, pega en vez de agarrar el arma del piso.
## Sin vida: queda tirado hasta que se machaca el botón (¡LEVANTATE!); pierde puntos y se levanta con
## media vida.

signal hurt(hp_ratio: float)

## Combo: animación, cuadro en que pega, alcance, daño, si tira al piso.
const COMBO := [
	["punch", 2, 26.0, 5, false],
	["punch2", 1, 26.0, 6, false],
	["kick", 3, 30.0, 9, true],
]
const COMBO_WINDOW := 0.45
## Cuánto hay que mantener el botón (sin pegar) para que salga la patada giratoria.
const CHARGE_TIME := 0.5
const SPIN := {"reach": 34.0, "damage": 9}

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
var _hold := 0.0
var _charged := false
var _spin_hits := 0
var _ko := false  # tirado sin vida: hay que machacar para levantarse
var _ko_presses := 0
var _ko_t := 0.0
var _ko_label: Label
const KO_PRESSES := 6
const KO_MAX := 4.0  # si no machaca, igual se levanta (más tarde)
const KO_PENALTY := 1000
const REACH_CHECK := 34.0


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
	_charge(delta)  # cuenta desde que aprieta (el primer golpe sale igual)
	if state == State.ATTACK:
		if attack:
			_queued = true
		return
	if _charged and not Input.is_action_pressed("interact"):  # soltó cargado
		_start_spin()
		return

	# Agacharse (solo donde la escena lo permite, p. ej. el techo del camión).
	crouching = arena.has_method("crouch_allowed") and arena.crouch_allowed() and Input.is_action_pressed("move_down")
	if crouching:
		state = State.IDLE
		play("crouch")
		return

	if attack:
		_face_threat()
		var busy_close := _foe_at(REACH_CHECK, facing) != null
		if weapon == "" and not busy_close and arena.has_method("try_pickup") and arena.try_pickup(self):
			return
		if weapon != "":
			_start_weapon_attack()
		else:
			var next := _step + 1 if _since_attack < COMBO_WINDOW and _step < COMBO.size() - 1 else 0
			_start_attack(next)
		return
	walk(Input.get_vector("move_left", "move_right", "move_up", "move_down"), delta)


## El matón más cercano a tiro hacia `dir` (alineado en la profundidad), o null.
func _foe_at(reach: float, dir: int) -> Brawler:
	if not arena.has_method("foes"):
		return null
	var best: Brawler = null
	var best_d := reach
	for f in arena.foes():
		if not is_instance_valid(f) or f.state in [State.OUT, State.DOWN, State.GETUP]:
			continue
		var dx: float = (f.position.x - position.x) * dir
		if absf(f.position.y - position.y) <= 10.0 and dx >= -4.0 and dx <= best_d:
			best = f
			best_d = dx
	return best


## Si adelante no hay nadie a tiro pero atrás sí: se da vuelta antes de pegar. (No donde pegarle
## al de atrás puede ser un error: las copias de Brenda.)
func _face_threat() -> void:
	if arena.has_method("auto_turn") and not arena.auto_turn():
		return
	if _foe_at(REACH_CHECK, facing) == null and _foe_at(REACH_CHECK, -facing) != null:
		set_facing(-facing)


## Botón mantenido: se carga (brilla). Al soltarlo cargado (y sin estar pegando), patada giratoria.
func _charge(delta: float) -> void:
	if weapon != "" or crouching:
		_hold = 0.0
		_charged = false
	elif Input.is_action_pressed("interact"):
		_hold += delta
		if _hold >= CHARGE_TIME and not _charged:
			_charged = true
			if arena.has_method("on_charged"):
				arena.on_charged(self)
	elif not _charged:
		_hold = 0.0
	sprite.modulate = Color(1.5, 1.3, 0.55) if _charged and int(Time.get_ticks_msec() / 90) % 2 == 0 else Color.WHITE


func _start_spin() -> void:
	_step = -3  # -3 = patada giratoria
	_queued = false
	_spin_hits = 0
	_charged = false
	_hold = 0.0
	sprite.modulate = Color.WHITE
	state = State.ATTACK
	_push = facing * 70.0  # sale hacia adelante
	sprite.stop()
	play("spin")


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
	if state != State.ATTACK:
		return
	if _step == -3:  # la giratoria pega dos veces: adelante y, en la vuelta, atrás
		if sprite.frame == 2 and _spin_hits == 0:
			_spin_hits = 1
			arena.resolve_attack(self, SPIN["reach"], SPIN["damage"], true, true)
		elif sprite.frame == 4 and _spin_hits == 1:
			_spin_hits = 2
			facing = -facing
			arena.resolve_attack(self, SPIN["reach"] - 6.0, SPIN["damage"], true, true)
			facing = -facing
		return
	if _hit_done:
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
		if _foe_at(28.0, facing) != null:
			# Pegado a él: no se la tira, se la rompe en la cabeza (eso no lo para ninguna guardia).
			arena.resolve_attack(self, 28.0, 12, true, true)
			if arena.has_method("break_item"):
				arena.break_item(weapon, position + Vector2(facing * 12, 0))
		else:
			arena.throw_item(self, weapon)
		unequip()
		return
	arena.resolve_attack(self, w["reach"], w["damage"], w["heavy"], weapon == "pipe")  # el caño rompe la guardia
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
		if _step == COMBO.size() - 1 or _step < -1:
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
	_hold = 0.0
	_charged = false
	sprite.modulate = Color.WHITE
	hurt.emit(clampf(float(hp) / max_hp, 0.0, 1.0))


## Sin vida: queda tirado. Machacar el botón lo levanta (si no, se levanta solo, tarde). Pierde puntos.
func _go_out() -> void:
	state = State.OUT
	_ko = true
	_ko_presses = 0
	_ko_t = 0.0
	Dream.score = maxi(0, Dream.score - KO_PENALTY)
	if _ko_label == null:
		_ko_label = Label.new()
		_ko_label.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
		_ko_label.add_theme_font_size_override("font_size", 8)
		_ko_label.add_theme_constant_override("outline_size", 3)
		_ko_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_ko_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		_ko_label.position = Vector2(-44, -52)
		_ko_label.z_index = 500
		add_child(_ko_label)
	_ko_label.visible = true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _ko:
		return
	_ko_t += delta
	var key := "A" if Controls.touch() else "E"
	_ko_label.text = "¡LEVANTATE! %s" % ("[%s]" % key if int(_ko_t * 6) % 2 == 0 else " %s " % key)
	# Que no se salga de la pantalla si cayó en un borde.
	var sx: float = get_global_transform_with_canvas().origin.x - 44.0
	var w := _ko_label.text.length() * 8.0
	_ko_label.position.x = -44.0 + (clampf(sx, 2.0, Controls.right_edge() - w) - sx)
	if Input.is_action_just_pressed("interact"):
		_ko_presses += 1
		sprite.position.x = randf_range(-1.5, 1.5)  # se sacude con cada intento
	if _ko_presses >= KO_PRESSES or _ko_t >= KO_MAX:
		_ko = false
		_ko_label.visible = false
		sprite.position.x = 0.0
		hp = max_hp / 2
		state = State.GETUP
		_timer = GETUP_TIME * 2
		play("crouch")
		hurt.emit(float(hp) / max_hp)
