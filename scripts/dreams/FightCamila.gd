class_name FightCamila
extends FightEnemy
## Camila, jefa del sueño 3 (con Guillermo). Rápida, pega y se aleja; cuando la golpean,
## Guillermo sale a defenderla (lo maneja la arena con la señal got_hit).
## Usa las animaciones de Lilato (mismo cuerpo, otro vestido).

signal life_changed(ratio: float)
signal got_hit
signal spoke(line: String)

const LINES := {
	0.66: "CAMILA: —Le quité todo y todavía me daba las gracias.",
	0.33: "CAMILA: —Usted también me hubiera elegido. No se haga.",
}

var _said := {}
var _retreat := 0.0


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.LILATO)


func _ready() -> void:
	super._ready()
	aggressive = true
	attack_range = 26.0


func tick(delta: float) -> void:
	aggressive = true
	if _retreat > 0.0 and state != State.ATTACK:
		# Pega y se va: deja que Guillermo haga el trabajo pesado.
		_retreat -= delta
		var away := signf(position.x - arena.player.position.x)
		walk(Vector2(away if away != 0.0 else 1.0, 0.0), delta)
		return
	super.tick(delta)


func choose_attack() -> Array:
	_retreat = 0.9
	if randf() < 0.75:
		return ["slash", 1, 30.0, damage, false]
	return ["spin", 1, 30.0, damage + 2, true]


func take_hit(dmg: int, from_x: float, heavy := false) -> void:
	super.take_hit(dmg, from_x, heavy)
	got_hit.emit()
	var ratio := float(maxi(hp, 0)) / max_hp
	life_changed.emit(ratio)
	for threshold in LINES:
		if ratio <= threshold and not _said.has(threshold) and hp > 0:
			_said[threshold] = true
			spoke.emit(LINES[threshold])


func _go_out() -> void:
	state = State.OUT
	play("fall")
	knocked_out.emit(self)
	var t := create_tween()
	t.tween_interval(1.5)
	for i in 4:
		t.tween_property(self, "modulate:a", 0.2, 0.08)
		t.tween_property(self, "modulate:a", 1.0, 0.08)
	t.tween_callback(queue_free)
