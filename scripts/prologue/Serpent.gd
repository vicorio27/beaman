class_name Serpent
extends Node2D
## Segunda fase de Lilato: la serpiente. Se mueve por el piso de la arena (x = a lo largo,
## y = profundidad) y el cuerpo sigue a la cabeza como una cadena.
##   - EMBESTIDA: avisa (echa la cabeza atrás y se pone roja), cruza la pantalla en la línea del
##     jugador. Después queda TRABADA con la cabeza en el piso: es el momento de pegarle.
##   - VENENO: escupe charcos que quedan en el piso y lastiman si se pisan.
##   - COLETAZO: la cola barre la zona donde está.
## Solo el súper cuchillo la lastima; lo demás rebota.

signal life_changed(ratio: float)
signal died
signal hint(text: String)

const SEGMENTS := 9
const SEG_GAP := 11.0
const SPEED := 46.0
const LUNGE_SPEED := 270.0
const WINDUP := 0.8
const STUCK_TIME := 2.2
const MAX_HP := 20
const VENOM_LIFE := 5.0
const VENOM_DAMAGE := 3
const LUNGE_DAMAGE := 10
const TAIL_DAMAGE := 8
const TAIL_REACH := 70.0

var arena: Node
var hp := MAX_HP
var state := "slither"
var _timer := 2.0
var _dir := Vector2.LEFT
var _lane := 150.0
var _lunge_dir := 1.0
var _wander := Vector2.ZERO
var _hit_this_lunge := false
var _told_knife := false
var _told_stuck := false
var _t := 0.0
## A la mitad de la vida se enoja: embiste más rápido, avisa menos y escupe más veneno.
var angry := false

var _head: Sprite2D
var _segs: Array[Sprite2D] = []
var _venom: Array = []  # [{node, life, cooldown}]
var _tex_head: Texture2D
var _tex_open: Texture2D


func _ready() -> void:
	# Un poco más clara que el fondo: con el filtro frío se tiene que leer bien.
	modulate = Color(1.35, 1.3, 1.35)
	_tex_head = load("res://assets/prologue/serpent_head.png")
	_tex_open = load("res://assets/prologue/serpent_head_open.png")
	for i in SEGMENTS:
		var s := Sprite2D.new()
		s.texture = load("res://assets/prologue/serpent_tail.png" if i >= SEGMENTS - 2 else "res://assets/prologue/serpent_body.png")
		s.position = position + Vector2((i + 1) * SEG_GAP, 0)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0)
		s.top_level = true
		add_child(s)
		_segs.append(s)
	_head = Sprite2D.new()
	_head.texture = _tex_head
	_head.offset = Vector2(0, -14)
	_head.top_level = true
	_head.global_position = global_position
	add_child(_head)
	_pick_wander()


func head_pos() -> Vector2:
	return _head.global_position


func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	_t += delta
	_timer -= delta
	var p: Node2D = arena.player
	match state:
		"slither":
			var to := _wander - _head.global_position
			if to.length() < 8.0:
				_pick_wander()
			_move_head(to.normalized() * SPEED * delta)
			if _timer <= 0.0:
				_choose_attack(p)
		"windup":
			# Se echa para atrás, temblando, roja.
			_move_head(Vector2(-_lunge_dir * 18.0 * delta, (_lane - _head.global_position.y) * 4.0 * delta))
			_head.texture = _tex_open
			_head.modulate = Color(1, 0.5, 0.5) if int(_t * 12) % 2 == 0 else Color.WHITE
			if _timer <= 0.0:
				state = "lunge"
				_hit_this_lunge = false
				_head.modulate = Color.WHITE
		"lunge":
			_move_head(Vector2(_lunge_dir * LUNGE_SPEED * (1.25 if angry else 1.0) * delta, 0))
			if not _hit_this_lunge and absf(p.position.y - _lane) < 10.0 and absf(p.position.x - _head.global_position.x) < 16.0:
				_hit_this_lunge = true
				p.take_hit(LUNGE_DAMAGE, _head.global_position.x - _lunge_dir * 10.0, true)
				arena.on_hit_landed(p, true)
			var b: Rect2 = arena.walk_bounds(null)
			if _head.global_position.x < b.position.x + 10.0 or _head.global_position.x > b.end.x - 10.0:
				state = "stuck"
				_timer = STUCK_TIME
				_head.texture = _tex_head
				_head.rotation = _lunge_dir * 0.35
				arena.shake(3.0)
				if not _told_stuck:
					_told_stuck = true
					hint.emit("¡AHORA! ¡La cabeza!")
		"stuck":
			_head.position.y += sin(_t * 30.0) * 0.3
			if _timer <= 0.0:
				_head.rotation = 0.0
				state = "slither"
				_timer = randf_range(1.8, 3.0)
				_pick_wander()
		"spit":
			if _timer <= 0.0:
				_head.texture = _tex_head
				for i in (5 if angry else 3):
					_spawn_venom(p.position + Vector2(randf_range(-40, 40), randf_range(-12, 12)))
				state = "slither"
				_timer = randf_range(2.0, 3.2)
		"tail_windup":
			var tail := _segs[_segs.size() - 1]
			tail.modulate = Color(1, 0.4, 0.4) if int(_t * 14) % 2 == 0 else Color.WHITE
			tail.position.y += sin(_t * 40.0) * 0.6
			if _timer <= 0.0:
				tail.modulate = Color.WHITE
				_tail_sweep(p)
				state = "slither"
				_timer = randf_range(2.0, 3.0)
	_update_venom(delta, p)
	_update_z()


func _choose_attack(p: Node2D) -> void:
	var r := randf()
	if r < 0.55:
		state = "windup"
		_timer = WINDUP * (0.7 if angry else 1.0)
		_lane = p.position.y
		_lunge_dir = 1.0 if p.position.x > _head.global_position.x else -1.0
	elif r < 0.8:
		state = "spit"
		_timer = 0.6
		_head.texture = _tex_open
	else:
		state = "tail_windup"
		_timer = 0.8


func _pick_wander() -> void:
	var b: Rect2 = arena.walk_bounds(null)
	_wander = Vector2(randf_range(b.position.x + 30, b.end.x - 30), randf_range(b.position.y + 4, b.end.y - 4))


## Mueve la cabeza y arrastra el cuerpo (cada segmento sigue al anterior a distancia fija).
func _move_head(step: Vector2) -> void:
	var b: Rect2 = arena.walk_bounds(null)
	var np := _head.global_position + step
	np.x = clampf(np.x, b.position.x, b.end.x)
	np.y = clampf(np.y, b.position.y, b.end.y)
	if step.x != 0.0:
		_head.flip_h = step.x < 0
	_head.global_position = np
	var prev := np
	for s in _segs:
		var d := s.global_position - prev
		if d.length() > SEG_GAP:
			s.global_position = prev + d.normalized() * SEG_GAP
		prev = s.global_position


func _update_z() -> void:
	_head.z_index = int(_head.global_position.y) + 1
	for s in _segs:
		s.z_index = int(s.global_position.y)


## Le pegaron en la cabeza. Solo cuenta con el súper cuchillo (y mejor cuando está trabada).
func hit(with_superknife: bool) -> bool:
	if state == "dead":
		return false
	if not with_superknife:
		if not _told_knife:
			_told_knife = true
			hint.emit("Rebota. Clásico jefe final: inmune a todo menos al cuchillo brillante.")
		return false
	hp -= 2 if state == "stuck" else 1
	life_changed.emit(float(maxi(hp, 0)) / MAX_HP)
	if not angry and hp <= MAX_HP / 2 and hp > 0:
		angry = true
		hint.emit("—¡¿Me vas a dejar?!")
		arena.shake(4.0)
	var t := create_tween()
	t.tween_property(_head, "modulate", Color(1, 0.3, 0.3), 0.05)
	t.tween_property(_head, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		_die()
	return true


func can_be_hit_from(attacker: Node2D, reach: float) -> bool:
	var hp_pos := _head.global_position
	var dx: float = (hp_pos.x - attacker.position.x) * attacker.facing
	return absf(hp_pos.y - attacker.position.y) <= 14.0 and dx >= -6.0 and dx <= reach + 10.0


func _spawn_venom(at: Vector2) -> void:
	var b: Rect2 = arena.walk_bounds(null)
	at.x = clampf(at.x, b.position.x, b.end.x)
	at.y = clampf(at.y, b.position.y, b.end.y)
	var a := AnimatedSprite2D.new()
	var f := SpriteFrames.new()
	f.set_animation_speed("default", 3.0)
	f.add_frame("default", load("res://assets/prologue/venom_0.png"))
	f.add_frame("default", load("res://assets/prologue/venom_1.png"))
	a.sprite_frames = f
	a.play()
	a.top_level = true
	a.global_position = at
	a.z_index = int(at.y) - 2
	add_child(a)
	_venom.append({"node": a, "life": VENOM_LIFE, "cooldown": 0.0})


func _update_venom(delta: float, p: Node2D) -> void:
	for v in _venom.duplicate():
		v["life"] -= delta
		v["cooldown"] -= delta
		var n: AnimatedSprite2D = v["node"]
		n.modulate.a = clampf(v["life"], 0.0, 1.0)
		if v["life"] <= 0.0:
			n.queue_free()
			_venom.erase(v)
			continue
		if v["cooldown"] <= 0.0 and absf(p.position.x - n.global_position.x) < 12.0 and absf(p.position.y - n.global_position.y) < 5.0:
			v["cooldown"] = 0.7
			p.take_hit(VENOM_DAMAGE, n.global_position.x, false)


func _tail_sweep(p: Node2D) -> void:
	var tail := _segs[_segs.size() - 1].global_position
	arena.shake(2.0)
	if absf(p.position.x - tail.x) < TAIL_REACH and absf(p.position.y - tail.y) < 16.0:
		p.take_hit(TAIL_DAMAGE, tail.x, true)
		arena.on_hit_landed(p, true)


## Muere: los segmentos revientan uno por uno, la cabeza al final.
func _die() -> void:
	state = "dead"
	for v in _venom:
		v["node"].queue_free()
	_venom.clear()
	var parts: Array = _segs.duplicate()
	parts.reverse()
	parts.append(_head)
	for s in parts:
		arena.burst(s.global_position + Vector2(0, -8))
		var t := create_tween()
		t.tween_property(s, "scale", Vector2(1.6, 1.6), 0.08)
		t.tween_property(s, "modulate:a", 0.0, 0.08)
		await get_tree().create_timer(0.14, true, false, true).timeout
	died.emit()
	queue_free()
