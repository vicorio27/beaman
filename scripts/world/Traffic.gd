extends Node2D
## Lo que pasa por la calle, de vez en cuando: carros, taxis, la buseta, bicicletas y motos.
## Por la avenida (este-oeste, dos carriles) y por la calle principal (norte-sur, hasta el puente).
## No chocan: si él (o Lukas) está parado en el carril, frenan y pitan hasta que se quite.
## De noche pasan menos. Dibujos: tools/art/draw_trafico.py.

const ART := "res://assets/barrio/trafico/%s_%s_%s.png"
const MAP_W := 1024.0
const MAP_H := 768.0
## Carriles: [dirección, posición fija (y en la avenida, x en la calle), desde, hasta].
const LANES := [
	[Vector2.LEFT, 246.0, MAP_W + 60.0, -60.0],
	[Vector2.RIGHT, 266.0, -60.0, MAP_W + 60.0],
	[Vector2.DOWN, 462.0, 230.0, MAP_H + 40.0],
	[Vector2.UP, 484.0, MAP_H + 40.0, 230.0],
]
## [tipo, peso, velocidad]
const KINDS := [
	["car_rojo", 3, 120.0], ["car_azul", 3, 115.0], ["car_blanco", 3, 110.0], ["car_gris", 3, 125.0],
	["car_taxi", 3, 135.0], ["car_buseta", 1, 85.0], ["bici", 2, 45.0], ["moto", 2, 150.0],
]
const STOP_DIST := 34.0

var _timers := [2.0, 4.0, 6.0, 9.0]
var _movers: Array = []  # [{node, lane, speed, stopped, honked}]


func _process(delta: float) -> void:
	var night: bool = TimeManager.hour() >= 22 or TimeManager.hour() < 5
	for i in LANES.size():
		_timers[i] -= delta
		if _timers[i] <= 0.0:
			var avenue: bool = i < 2
			_timers[i] = randf_range(4.0, 9.0) if avenue else randf_range(8.0, 16.0)
			if night:
				_timers[i] *= 3.0
			_spawn(i)
	for m in _movers.duplicate():
		_move(m, delta)


func _spawn(lane_i: int) -> void:
	var lane: Array = LANES[lane_i]
	var start := Vector2(lane[2], lane[1]) if lane[0].y == 0 else Vector2(lane[1], lane[2])
	for m in _movers:  # trancón hasta la esquina: no aparece uno encima del otro
		if m["lane"] == lane_i and m["node"].position.distance_to(start) < 80.0:
			return
	var total := 0
	for k in KINDS:
		total += k[1]
	var r := randi() % total
	var kind: Array = KINDS[0]
	for k in KINDS:
		r -= k[1]
		if r < 0:
			kind = k
			break
	var dir: Vector2 = lane[0]
	var view := "side" if dir.y == 0 else ("down" if dir.y > 0 else "up")
	var f := SpriteFrames.new()
	for tag in ["a", "b"]:
		f.add_frame("default", load(ART % [kind[0], view, tag]))
	f.set_animation_speed("default", 6.0)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = f
	s.centered = false
	var tex: Texture2D = f.get_frame_texture("default", 0)
	s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	s.flip_h = dir.x < 0
	s.position = Vector2(lane[2], lane[1]) if dir.y == 0 else Vector2(lane[1], lane[2])
	s.play()
	get_parent().add_child(s)
	var length := tex.get_width() if dir.y == 0 else tex.get_height()
	s.set_meta("length", float(length))
	_movers.append({"node": s, "lane": lane_i, "speed": kind[2] * randf_range(0.9, 1.1), "honked": false})


func _move(m: Dictionary, delta: float) -> void:
	var s: AnimatedSprite2D = m["node"]
	var lane: Array = LANES[m["lane"]]
	var dir: Vector2 = lane[0]
	if _blocked(s, dir):
		s.pause()
		if not m["honked"]:
			m["honked"] = true
			_honk(s)
		return
	m["honked"] = false
	if not s.is_playing():
		s.play()
	s.position += dir * m["speed"] * delta
	var past: bool = (dir.x < 0 and s.position.x < lane[3]) or (dir.x > 0 and s.position.x > lane[3]) \
		or (dir.y > 0 and s.position.y > lane[3]) or (dir.y < 0 and s.position.y < lane[3])
	if past:
		s.queue_free()
		_movers.erase(m)


## ¿Hay alguien parado adelante, en el carril? (él, Lukas, u otro que frenó)
func _blocked(s: Node2D, dir: Vector2) -> bool:
	var who: Array = get_tree().get_nodes_in_group("player")
	var lukas := get_parent().find_child("Lukas", false, false)
	if lukas:
		who.append(lukas)
	for m in _movers:
		if m["node"] != s:
			who.append(m["node"])
	for n in who:
		var d: Vector2 = n.global_position - s.global_position
		var ahead := d.dot(dir)
		var side := absf(d.dot(Vector2(-dir.y, dir.x)))
		# El largo de los dos (una buseta ocupa más), más un espacio.
		var gap: float = (s.get_meta("length", 20.0) + float(n.get_meta("length", 10.0))) / 2.0 + 6.0
		if ahead > 0.0 and ahead < maxf(gap, STOP_DIST) and side < 12.0:
			return true
	return false


func _honk(s: Node2D) -> void:
	if not s.is_inside_tree():
		return
	var l := Label.new()
	l.text = ["¡PIIIP!", "¡PIP PIP!", "¡MUÉVASE!"].pick_random()
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.position = Vector2(-24, -40)
	l.z_index = 20
	s.add_child(l)
	var t := create_tween()
	t.tween_property(l, "position:y", -52.0, 0.8)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.tween_callback(l.queue_free)
