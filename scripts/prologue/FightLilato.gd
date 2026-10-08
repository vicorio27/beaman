class_name FightLilato
extends FightEnemy
## Lilato, jefa final del sueño 1. Rápida, habla entre ataques.
##   - Zarpazo (combo corto) y giro que pega a los dos lados (tira al piso).
##   - Cada tanto desaparece y reaparece detrás de él.
##   - A la mitad de la vida se enoja: más rápida, aparece detrás más seguido.
## Al quedar fuera de combate no desaparece: se queda tirada (después viene la serpiente).

signal life_changed(ratio: float)
signal spoke(line: String)

const TELEPORT_EVERY := Vector2(4.5, 7.0)
const TELEPORT_EVERY_ANGRY := Vector2(2.4, 3.8)
const ANGRY_AT := 0.5
const LINES := {
	0.75: "—Yo te cuidaba. ¿Te acordás?",
	0.5: "—No la vas a ver nunca más.",
	0.25: "—Todos se van. Vos también.",
}

var angry := false

var _teleport_in := 5.0
var _said := {}
var _spin_second_hit := false


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.LILATO)


func _ready() -> void:
	super._ready()
	aggressive = true
	attack_range = 26.0


func tick(delta: float) -> void:
	aggressive = true
	if state != State.ATTACK:
		_teleport_in -= delta
		if _teleport_in <= 0.0:
			var every := TELEPORT_EVERY_ANGRY if angry else TELEPORT_EVERY
			_teleport_in = randf_range(every.x, every.y)
			_teleport()
			return
	super.tick(delta)


func choose_attack() -> Array:
	if randf() < 0.7:
		return ["slash", 1, 32.0, 6, false]
	_spin_second_hit = false
	return ["spin", 1, 30.0, 8, true]


## Desaparece y aparece detrás de él, y ataca enseguida.
func _teleport() -> void:
	state = State.ATTACK
	var p: Node2D = arena.player
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func():
		var behind: float = -p.facing
		position = Vector2(p.position.x + behind * 22.0, p.position.y)
		_clamp()
		set_facing(1 if p.position.x > position.x else -1))
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	t.tween_callback(func():
		_attack = ["slash", 1, 32.0, 7, false]
		_begin_attack())


func _on_frame_changed() -> void:
	super._on_frame_changed()
	# El giro pega una segunda vez para el otro lado.
	if state == State.ATTACK and sprite.animation == "spin" and sprite.frame == 3 and not _spin_second_hit:
		_spin_second_hit = true
		set_facing(-facing)
		arena.resolve_attack(self, 30.0, 8, true)
		set_facing(-facing)


func take_hit(dmg: int, from_x: float, heavy := false) -> void:
	super.take_hit(dmg, from_x, heavy)
	var ratio := float(maxi(hp, 0)) / max_hp
	life_changed.emit(ratio)
	if not angry and ratio <= ANGRY_AT and hp > 0:
		_get_angry()
	for threshold in LINES:
		if ratio <= threshold and not _said.has(threshold):
			_said[threshold] = true
			spoke.emit(LINES[threshold])


## Se enoja: más rápida, ataca más seguido, se pone roja un instante.
func _get_angry() -> void:
	angry = true
	speed *= 1.35
	cooldown_range = Vector2(0.5, 1.0)
	var t := create_tween()
	for i in 3:
		t.tween_property(sprite, "modulate", Color(1.6, 0.5, 0.6), 0.1)
		t.tween_property(sprite, "modulate", Color.WHITE, 0.1)


## Queda tirada en el piso (la arena se encarga de lo que sigue).
func _go_out() -> void:
	state = State.OUT
	play("fall")
	knocked_out.emit(self)
