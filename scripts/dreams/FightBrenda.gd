class_name FightBrenda
extends FightEnemy
## Brenda, la jefa del sueño 6. No pelea como los demás: se escapa.
##   - Si él se acerca, sale corriendo para el otro lado.
##   - De lejos le tira maletas (la arena las hace volar por su carril).
##   - Si queda acorralada contra el borde, empuja para zafarse.
## Al quedar sin fuerzas no desaparece: se sienta en el piso (la arena sigue con la escena).
## Fase 2, "La de mil caras": ella y tres copias con caras de gente que lo quiere. Las copias (fake)
## no tiran nada: se acercan despacio, diciendo cosas lindas. Pegarle a una copia la deshace (y duele).

signal life_changed(ratio: float)
signal spoke(line: String)

const FLEE_DISTANCE := 70.0
const THROW_EVERY := Vector2(2.0, 3.2)
const LINES := {
	0.75: "BRENDA: —¡No me siga! ¡Váyase!",
	0.5: "BRENDA: —Yo no podía quedarme. Me iban a matar a mí también.",
	0.25: "BRENDA: —Usted ya era grande. Yo pensé que usted podía solo.",
}

var _said := {}
var fake := false
var phase2 := false
var face_label: Label
var _throw_in := 2.0


func build_frames() -> SpriteFrames:
	return SideFrames.build(sheet, SideFrames.LILATO)


func _ready() -> void:
	super._ready()
	attack_range = 24.0


func tick(delta: float) -> void:
	if state == State.ATTACK:
		return
	if fake:
		# La copia se acerca despacio, con la cara de alguien que lo quiere.
		var tp: Vector2 = arena.player.position - position
		set_facing(1 if tp.x > 0 else -1)
		if tp.length() > 30.0:
			walk(tp.normalized() * 0.5, delta)
		return
	var p: Node2D = arena.player
	var to := p.position - position
	var bounds: Rect2 = arena.walk_bounds(self)
	var cornered := position.x < bounds.position.x + 70.0 or position.x > bounds.end.x - 70.0
	set_facing(1 if to.x > 0 else -1)
	_throw_in -= delta
	if to.length() < (40.0 if phase2 else FLEE_DISTANCE):
		if cornered and absf(to.y) < 8.0:
			# Acorralada: empuja para zafarse.
			_attack = ["slash", 1, 28.0, damage, true]
			_begin_attack()
			return
		# Se escapa: corre para el lado contrario (y cambia de carril).
		var away := Vector2(-signf(to.x) if to.x != 0.0 else 1.0, -signf(to.y) * 0.6)
		walk(away.normalized() * 1.4, delta)
		set_facing(1 if to.x > 0 else -1)
		return
	if _throw_in <= 0.0:
		_throw_in = randf_range(THROW_EVERY.x, THROW_EVERY.y)
		# Se alinea con él y le tira una maleta.
		position.y = lerpf(position.y, p.position.y, 0.6)
		_attack = ["slash", 1, 0.0, 0, false]
		_begin_attack()
		arena.enemy_throw(self, "maleta")
		return
	walk(Vector2(0, signf(to.y) * 0.5), delta)


func take_hit(dmg: int, from_x: float, heavy := false) -> void:
	if fake:
		arena.fake_hit(self)
		return
	super.take_hit(dmg, from_x, heavy)
	var ratio := float(maxi(hp, 0)) / max_hp
	life_changed.emit(ratio)
	for threshold in LINES:
		if ratio <= threshold and not _said.has(threshold) and hp > 0:
			_said[threshold] = true
			spoke.emit(LINES[threshold])


## No se desmaya ni desaparece: se sienta en el piso.
func _go_out() -> void:
	state = State.OUT
	play("fall")
	knocked_out.emit(self)
