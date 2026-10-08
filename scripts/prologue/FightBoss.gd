class_name FightBoss
extends FightEnemy
## Jefe del sueño beat 'em up.
##   - Aguante: los golpes comunes casi nunca lo frenan (solo le bajan vida). Lo tiran los fuertes.
##   - Ataques: combo de piñas, patada que tira al piso y embestida corriendo por la calle.
##   - A veces se cubre (guardia): mientras tanto no le entra nada de frente.

signal life_changed(ratio: float)

const CHARGE_SPEED := 170.0
const CHARGE_TIME := 1.1
const GUARD_TIME := 0.9

var _charging := 0.0
var _guarding := 0.0
var _charge_hit := false


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.BOSS)


func _ready() -> void:
	super._ready()
	aggressive = true
	attack_range = 26.0


func tick(delta: float) -> void:
	if _guarding > 0.0:
		_guarding -= delta
		if _guarding <= 0.0:
			state = State.IDLE
			play("idle")
		return
	if _charging > 0.0:
		_charge(delta)
		return
	aggressive = true
	# A veces embiste en vez de acercarse caminando.
	var target: Node2D = arena.player
	if _cooldown <= 0.0 and state != State.ATTACK and absf(target.position.x - position.x) > 70.0 and randf() < 0.02:
		_start_charge()
		return
	super.tick(delta)


func choose_attack() -> Array:
	var r := randf()
	if r < 0.45:
		return ["punch", 2, 30.0, 6, false]
	if r < 0.75:
		return ["kick", 3, 34.0, 9, true]
	return ["uppercut", 1, 28.0, 8, true]


func _start_charge() -> void:
	_charging = CHARGE_TIME
	_charge_hit = false
	state = State.ATTACK
	set_facing(1 if arena.player.position.x > position.x else -1)
	# Se alinea con la profundidad del jugador antes de salir corriendo.
	position.y = lerpf(position.y, arena.player.position.y, 0.7)
	play("run")


func _charge(delta: float) -> void:
	_charging -= delta
	position.x += facing * CHARGE_SPEED * delta
	_clamp()
	var p: Brawler = arena.player
	if not _charge_hit and absf(p.position.y - position.y) < 8.0 and absf(p.position.x - position.x) < 14.0:
		_charge_hit = true
		p.take_hit(10, position.x, true)
		arena.on_hit_landed(p, true)
	if _charging <= 0.0:
		_cooldown = 1.2
		state = State.IDLE
		play("idle")


func take_hit(dmg: int, from_x: float, heavy := false) -> void:
	if state in [State.DOWN, State.GETUP, State.OUT]:
		return
	var from_front := signf(from_x - position.x) == facing
	if _guarding > 0.0 and from_front:
		arena.on_blocked(self)
		return
	# A veces levanta la guardia después de recibir.
	if not heavy and from_front and randf() < 0.18 and _charging <= 0.0:
		_guarding = GUARD_TIME
		state = State.ATTACK
		play("guard")
	if heavy or hp - dmg <= 0:
		_charging = 0.0
		super.take_hit(dmg, from_x, heavy)
	else:
		# Aguante: le baja la vida, parpadea, pero no se frena.
		hp -= dmg
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(1, 0.4, 0.4), 0.05)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	life_changed.emit(float(hp) / max_hp)


func _go_out() -> void:
	state = State.OUT
	life_changed.emit(0.0)
	knocked_out.emit(self)
	var t := create_tween()
	for i in 8:
		t.tween_property(self, "modulate:a", 0.2, 0.1)
		t.tween_property(self, "modulate:a", 1.0, 0.1)
	t.tween_callback(queue_free)
