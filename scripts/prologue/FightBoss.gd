class_name FightBoss
extends FightEnemy
## Jefe del sueño beat 'em up.
##   - Aguante: los golpes comunes casi nunca lo frenan (solo le bajan vida). Lo tiran los fuertes.
##   - Ataques: combo de piñas, patada que tira al piso y embestida corriendo por la calle.
##   - A veces se cubre (guardia): mientras tanto no le entra nada de frente.
##   - Si la embestida no le pega a nadie y se estrella contra el borde: queda mareado (estrellitas)
##     un rato; ahí no se cubre y los golpes le entran doble. Esquivarlo es la forma de ganarle.

signal life_changed(ratio: float)

const CHARGE_SPEED := 170.0
const CHARGE_TIME := 3.0  # corre hasta pegarle a alguien o estrellarse (tope por si acaso)
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
	var before := position.x
	position.x += facing * CHARGE_SPEED * delta
	_clamp()
	if not _charge_hit and absf(position.x - before) < 0.5:
		_crash_wall()
		return
	var p: Brawler = arena.player
	if not _charge_hit and absf(p.position.y - position.y) < 8.0 and absf(p.position.x - position.x) < 14.0:
		_charge_hit = true
		p.take_hit(10, position.x, true)
		arena.on_hit_landed(p, true)
	if _charging <= 0.0:
		_cooldown = 1.2
		state = State.IDLE
		play("idle")


const DAZE_TIME := 1.8
var _dazed := 0.0


## Se estrelló contra el borde (la embestida no le pegó a nadie): mareado.
func _crash_wall() -> void:
	_charging = 0.0
	_cooldown = 2.0
	_dazed = DAZE_TIME
	state = State.HURT
	_timer = DAZE_TIME
	sprite.stop()
	play("hurt")
	if arena.has_method("shake"):
		arena.shake(3.0)
	Narrator.say(["¡PUM! Se estrelló. Está viendo estrellitas.", "Se comió el poste. Ahora es cuando."].pick_random(), true)
	var t := create_tween().set_loops(int(DAZE_TIME / 0.3))
	t.tween_property(sprite, "rotation", 0.08, 0.15)
	t.tween_property(sprite, "rotation", -0.08, 0.15)
	t.finished.connect(func(): sprite.rotation = 0.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _dazed > 0.0:
		_dazed -= delta
		if _dazed <= 0.0:
			sprite.rotation = 0.0


func take_hit(dmg: int, from_x: float, heavy := false) -> void:
	if state in [State.DOWN, State.GETUP, State.OUT]:
		return
	if _dazed > 0.0:
		dmg *= 2  # mareado: le entra todo, y doble
		_guarding = 0.0
	var from_front := signf(from_x - position.x) == facing
	if _guarding > 0.0 and from_front:
		arena.on_blocked(self)
		return
	# A veces levanta la guardia después de recibir.
	if not heavy and from_front and randf() < 0.18 and _charging <= 0.0 and _dazed <= 0.0:
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
