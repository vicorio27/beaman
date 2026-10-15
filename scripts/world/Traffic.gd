extends Node2D
## Lo que pasa por la calle, de vez en cuando: carros, taxis, la buseta, bicicletas y motos.
## Por la avenida (este-oeste, dos carriles) y por la calle principal (norte-sur, hasta el puente).
## No chocan: si él (o Lukas) está parado en el carril, frenan y pitan hasta que se quite.
## De noche pasan menos. Dibujos: tools/art/draw_trafico.py.
## Si él se queda parado mucho rato en un carril con carros esperando (JAM_SECONDS), llega un agente:
## lo saca al andén y le cobra el comparendo ($2.000, o "pedagógico" si no tiene). Una vez por hora.

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
const JAM_SECONDS := 12.0
const FINE := 2000

var _timers := [2.0, 4.0, 6.0, 9.0]
var _movers: Array = []  # [{node, lane, speed, stopped, honked}]
var _jam := 0.0          # cuánto lleva él parando el tráfico
var _jam_now := false    # este cuadro, ¿alguien frenó por él?
var _jam_lane := 0
var _busted := false
## El semáforo de la esquina (la avenida con la calle): verde para uno, amarillo, rojo; el otro al revés.
## Los carros frenan en la raya; el que viene detrás frena por el de adelante.
const CYCLE := [["avenida", 9.0], ["amarillo_a", 2.0], ["calle", 7.0], ["amarillo_c", 2.0]]
var _light := 0
var _light_t := 0.0
var _lamps: Array = []


func _ready() -> void:
	# Las cebras: dos cruzando la avenida (a los lados de la calle) y una cruzando la calle.
	var zebra := Node2D.new()
	zebra.name = "Cebras"
	zebra.z_index = 0  # (en el World ordenado por altura, en y = 0: debajo de todo lo que camina)
	zebra.draw.connect(func() -> void:
		var white := Color(0.92, 0.92, 0.88, 0.85)
		for x0 in [428.0, 502.0]:
			for k in 7:
				zebra.draw_rect(Rect2(x0, 226.0 + k * 9.0, 16.0, 5.0), white)
		for k in 6:
			zebra.draw_rect(Rect2(451.0 + k * 8.0, 296.0, 4.0, 14.0), white))
	add_child(zebra)
	# Los semáforos, en las esquinas.
	for spec in [[Vector2(442, 214), "calle"], [Vector2(508, 214), "avenida"], [Vector2(442, 302), "avenida"], [Vector2(508, 302), "calle"]]:
		var lamp := Node2D.new()
		lamp.position = spec[0]
		lamp.set_meta("for", spec[1])
		lamp.draw.connect(_draw_lamp.bind(lamp))
		get_parent().add_child.call_deferred(lamp)
		_lamps.append(lamp)


func _draw_lamp(lamp: Node2D) -> void:
	var dark := Color(0.16, 0.16, 0.2)
	lamp.draw_rect(Rect2(-1, -30, 2, 30), dark)
	lamp.draw_rect(Rect2(-3, -42, 6, 13), Color(0.1, 0.1, 0.12))
	var st := _state_for(str(lamp.get_meta("for")))
	var cols := [Color(1, 0.2, 0.2), Color(1, 0.8, 0.2), Color(0.3, 1, 0.4)]
	for k in 3:
		var on: bool = (st == "rojo" and k == 0) or (st == "amarillo" and k == 1) or (st == "verde" and k == 2)
		lamp.draw_rect(Rect2(-1.5, -40.5 + k * 4, 3, 3), cols[k] if on else cols[k].darkened(0.75))


## "verde", "amarillo" o "rojo" para la avenida o para la calle.
func _state_for(road: String) -> String:
	var st: String = CYCLE[_light][0]
	if st == road:
		return "verde"
	if st == "amarillo_" + road.left(1):
		return "amarillo"
	return "rojo"


## ¿Este carro tiene que frenar en la raya?
func _red_light(lane_i: int, s: Node2D) -> bool:
	match lane_i:
		0:
			return _state_for("avenida") != "verde" and s.position.x > 532.0 and s.position.x < 546.0
		1:
			return _state_for("avenida") != "verde" and s.position.x > 398.0 and s.position.x < 412.0
		3:
			return _state_for("calle") != "verde" and s.position.y > 332.0 and s.position.y < 346.0
	return false


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
	_light_t += delta
	if _light_t >= CYCLE[_light][1]:
		_light_t = 0.0
		_light = (_light + 1) % CYCLE.size()
		for lamp in _lamps:
			if is_instance_valid(lamp):
				lamp.queue_redraw()
	_jam_now = false
	for m in _movers.duplicate():
		_move(m, delta)
	_jam = _jam + delta if _jam_now else maxf(0.0, _jam - delta * 2.0)
	if _jam >= JAM_SECONDS and not _busted and not Dialogue.active and not GameState.ui_open and not SceneRouter.busy:
		_bust()


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
	if _red_light(m["lane"], s):  # el semáforo
		s.pause()
		return
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
		if (n.is_in_group("player") or str(n.name) == "Lukas") and d.dot(dir) > 0.0 and d.dot(dir) < STOP_DIST and absf(d.dot(Vector2(-dir.y, dir.x))) < 12.0:
			_jam_now = true
			for i in LANES.size():
				if LANES[i][0] == dir:
					_jam_lane = i
		var ahead := d.dot(dir)
		var side := absf(d.dot(Vector2(-dir.y, dir.x)))
		# El largo de los dos (una buseta ocupa más), más un espacio.
		var gap: float = (s.get_meta("length", 20.0) + float(n.get_meta("length", 10.0))) / 2.0 + 6.0
		if ahead > 0.0 and ahead < maxf(gap, STOP_DIST) and side < 12.0:
			return true
	return false


## Llevaba mucho rato parando el tráfico: el agente lo saca al andén y le cobra.
func _bust() -> void:
	_busted = true
	_jam = 0.0
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var f := GameState.flags
	if TimeManager.minutes - float(f.get("trafico_multa_at", -999.0)) < 60.0:
		_busted = false
		return
	f["trafico_multa_at"] = TimeManager.minutes
	f["trafico_multas"] = int(f.get("trafico_multas", 0)) + 1
	var lines := [["AGENTE", "—¡Oiga! ¡El del saco! ¿Usted es un reductor de velocidad o qué?"],
		["", "(El agente lo saca de la calle del brazo. Atrás quedan catorce carros, una buseta y un señor en bicicleta que lleva tres minutos insultándolo con mucho cariño.)"]]
	var pays: bool = GameState.money >= FINE
	if pays:
		lines.append(["AGENTE", "—Comparendo por obstruir la vía: dos mil. El resto del comparendo se lo debe a la ciudad. La ciudad le debe más a usted, pero eso no lo cobro yo."])
	else:
		lines.append(["AGENTE", "—No tiene con qué. Entonces el comparendo es pedagógico: repita conmigo... Ah, no habla. Entonces míreme a los ojos y arrepiéntase."])
		lines.append(["", "(Lo mira a los ojos. El agente es el primero en quitar la vista.)"])
	# Al andén más cercano.
	var lane: Array = LANES[_jam_lane]
	var to := p.global_position
	if lane[0].y == 0.0:
		to.y = 300.0 if p.global_position.y > 256.0 else 208.0
	else:
		to.x = 436.0 if p.global_position.x < 473.0 else 512.0
	GameState.block_input(0.6)
	await create_tween().tween_property(p, "global_position", to, 0.5).finished
	await Dialogue.talk(lines)
	if pays:
		GameState.add_money(-FINE)
	GameState.change_mood(-4.0)
	_busted = false


func _honk(s: Node2D) -> void:
	if not s.is_inside_tree():
		return
	var l := Label.new()
	l.text = ["¡PIIIP!", "¡QUÍTESE, GÜEVÓN!", "¡ABRA, PIROBO!", "¡¿SE VA A MATAR O QUÉ?!", "¡MUÉVASE, HP!", "¡LA CALLE NO ES SUYA!", "¡ÑERO, ABRA!"].pick_random()
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
