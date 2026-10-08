extends Node2D
## Sueño 1 (beat 'em up), parte 2 — La avenida y el camión en movimiento (de costado).
##   0. AVENIDA: sale del callejón; el camión de "Harinas El Sol" arranca; vienen más matones.
##      Correr detrás del camión y saltar (botón) para agarrarse.
##   1. COLGADO: el cuerpo cuelga de las manos y se balancea. El camión lo desequilibra (viento,
##      vaivén, baches, curvas); izquierda/derecha corrige. Si se pasa, se suelta una mano:
##      apretar el botón rápido para volver a agarrarse.
##      Los matones vienen en moto: se ponen al lado y pegan (desequilibra y quita vida).
##      Botón = patada hacia atrás: hay que tirarlos de la moto.
##   2. GANÓ: STAGE CLEAR, el camión frena en el puente: abajo lo espera Lilato (jefa final).
##      PERDIÓ (sin vida): se cae del camión y rueda hasta el puente: también va a Lilato.

const NEXT_SCENE := "res://scenes/prologue/Lilato.tscn"
const SPEED := 240.0  # velocidad del mundo con el camión lanzado (px/s)
const SKY_FACTOR := 0.09
const ROAD_Y := 136.0
const GROUND_Y := 168.0  # pies de los que corren por la calle
const BIKE_Y := 176.0  # ruedas de las motos
const RIG := Vector2(180, 176)
const TRUCK_REAR := 110.0
const ROOF_Y := 110.0

# --- Avenida
const RUN_SPEED := 98.0
const CHASER_SPEED := 96.0
const BOARD_TRUCK_SPEED := 72.0
const CHASERS := ["goon", "punk", "thug", "punk", "goon"]

# --- Colgado
const HAND := Vector2(110, 135)  # dónde se agarra (coordenadas de pantalla)
const HANG_GRIP := Vector2(20, 3)  # punto de agarre dentro de cada cuadro de player_hang.png
const HANG_CELL := Vector2(32, 40)
const INSTABILITY := 5.0
const DAMPING := 1.6
const CONTROL := 10.0
const SLIP_ANGLE := 1.0
const REGRAB_PRESSES := 3
const REGRAB_TIME := 1.4
const CURVE_TIME := 2.4
const CURVE_FORCE := 4.5
const MAX_LIFE := 50
const HIT_DAMAGE := 5

# --- Motos
const BIKERS := ["punk", "goon", "punk", "thug", "goon", "punk", "thug"]
const BIKER_HP := {"punk": 1, "goon": 2, "thug": 3}
const MAX_BIKERS := 2
## Alcance de la patada hacia atrás: dónde tiene que estar el que maneja (x de pantalla).
const KICK_RANGE := Vector2(HAND.x - 64, HAND.x - 14)
const BIKER_SLOT_X := [HAND.x - 44, HAND.x - 70]

enum Phase { BOARD, HANG, CLEAR, FALL, DONE }

var phase := Phase.BOARD
var life := MAX_LIFE
var _t := 0.0
var _speed := 45.0  # el camión ya está arrancando cuando sale del callejón
var _target_speed := 0.0
var _shake := 0.0

var _runner: AnimatedSprite2D
var _chasers: Array = []
var _truck_started := false

var _theta := 0.0
var _omega := 0.0
var _slip := 0.0
var _presses := 0
var _kick := 0.0
var _kick_done := false
var _next_bump := 1.5
var _next_curve := 4.0
var _curve_dir := 0
var _curve_left := 0.0

var _to_spawn: Array = []
var _bikers: Array = []  # [{node, rider, kind, hp, state, timer, slot}]
var _next_biker := 3.0
var _movers: Array = []  # [{node, kind, hit}]
var _streaks: Array = []
var _standing: AnimatedSprite2D

@onready var mood: CanvasLayer = $MoodFilter
var hud: CanvasLayer
var _camera: Camera2D
var _sky: Array[Sprite2D] = []
var _road: Array[Sprite2D] = []
var _rig: Node2D
var _hands: Node2D
var _hanging: AnimatedSprite2D
var _meter: Node2D
var _prompt: Label
var _banner: Label
var _flash: ColorRect
var _sfx := {}
var _back: Node2D
var _front: Node2D
var _fx: Node2D
var _player_frames: SpriteFrames


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_camera.make_current()

	var sky := ColorRect.new()
	sky.color = Color(0.09, 0.08, 0.13)
	sky.position = Vector2(-20, -20)
	sky.size = Vector2(360, 220)
	sky.z_index = -20
	add_child(sky)
	var skyline: Texture2D = load("res://assets/prologue/skyline.png")
	for i in 2:
		var s := Sprite2D.new()
		s.texture = skyline
		s.centered = false
		s.position = Vector2(i * skyline.get_width(), ROAD_Y - skyline.get_height() + 2)
		s.z_index = -15
		add_child(s)
		_sky.append(s)
	var road: Texture2D = load("res://assets/prologue/road_strip.png")
	for i in 3:
		var r := Sprite2D.new()
		r.texture = road
		r.centered = false
		r.position = Vector2(i * road.get_width(), ROAD_Y)
		r.z_index = -12
		add_child(r)
		_road.append(r)

	_back = Node2D.new()  # faroles, árboles, carteles (detrás de todo)
	_back.z_index = -5
	add_child(_back)
	for x in [20.0, 150.0, 280.0]:
		_spawn("lamp", "res://assets/prologue/lamp.png", ROAD_Y + 8 - 96, _back, false, x)

	_rig = Node2D.new()  # camión + jugador colgado: se inclina en las curvas
	_rig.position = RIG
	add_child(_rig)
	var truck := Sprite2D.new()
	truck.texture = load("res://assets/prologue/truck.png")
	truck.centered = false
	truck.position = Vector2(-70, -70)
	_rig.add_child(truck)

	# Colgado: el cuerpo cuelga de un punto en las manos y rota alrededor de él (péndulo).
	_hands = Node2D.new()
	_hands.position = HAND - RIG
	_hands.visible = false
	_rig.add_child(_hands)
	_hanging = AnimatedSprite2D.new()
	_hanging.sprite_frames = _build_hang_frames()
	_hanging.centered = false
	_hanging.position = -HANG_GRIP
	_hanging.play("hang")
	_hands.add_child(_hanging)

	_player_frames = SideFrames.build(load("res://assets/prologue/player.png"), SideFrames.PLAYER)
	_runner = AnimatedSprite2D.new()
	_runner.sprite_frames = _player_frames
	_runner.position = Vector2(-60, GROUND_Y - 23)
	_runner.play("walk")
	_runner.z_index = 10
	add_child(_runner)

	_fx = Node2D.new()  # humo del escape
	_fx.z_index = 5
	add_child(_fx)
	_front = Node2D.new()  # puente final, líneas de viento (delante de todo)
	_front.z_index = 300
	_front.draw.connect(_draw_streaks)
	add_child(_front)

	_build_ui()
	_meter = Node2D.new()  # en el HUD (sin filtro), para que se lea siempre
	_meter.visible = false
	_meter.draw.connect(_draw_meter)
	hud.add_child(_meter)
	Narrator.say("—¡Allá va! ¡Agárrenlo!", true)


func _build_hang_frames() -> SpriteFrames:
	var sheet: Texture2D = load("res://assets/prologue/player_hang.png")
	var anims := {
		"hang": [[0, 1], 3.0, true],
		"swing_l": [[2], 1.0, true],
		"swing_r": [[3], 1.0, true],
		"kick": [[4, 5, 5, 4], 16.0, false],
		"slip": [[6, 7], 8.0, true],
	}
	var f := SpriteFrames.new()
	f.remove_animation("default")
	for a in anims:
		f.add_animation(a)
		f.set_animation_speed(a, anims[a][1])
		f.set_animation_loop(a, anims[a][2])
		for i in anims[a][0]:
			var t := AtlasTexture.new()
			t.atlas = sheet
			t.region = Rect2(i * HANG_CELL.x, 0, HANG_CELL.x, HANG_CELL.y)
			f.add_frame(a, t)
	return f


func _build_ui() -> void:
	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 5
	var rain := Node2D.new()
	rain.set_script(load("res://scripts/prologue/Rain.gd"))
	rain.wind = -160.0
	rain_layer.add_child(rain)
	add_child(rain_layer)

	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/prologue/ArcadeHud.gd"))
	add_child(hud)
	hud.set_score(Dream.score)
	hud.set_counter("")
	_prompt = _make_label(Color(1, 1, 1))
	_banner = _make_label(Color(1, 0.85, 0.3))
	_banner.text = "STAGE CLEAR"
	_banner.position = Vector2(116, 60)
	_flash = ColorRect.new()
	_flash.color = Color(0.6, 0.05, 0.05, 0.0)
	_flash.size = Vector2(320, 180)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_flash)
	for n in ["hit-1", "hit-2", "miss", "grunt", "gogogo", "click"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/%s.wav" % n)
		p.volume_db = -6.0
		add_child(p)
		_sfx[n] = p


func _make_label(color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_color_override("font_color", color)
	l.visible = false
	hud.add_child(l)
	return l


func _process(delta: float) -> void:
	if phase == Phase.DONE:
		return
	_t += delta
	_speed = move_toward(_speed, _target_speed, delta * (70.0 if phase == Phase.BOARD else 90.0))
	_scroll(delta)
	_decor()
	_update_fx(delta)
	match phase:
		Phase.BOARD:
			_board(delta)
		Phase.HANG:
			_hang(delta)
			_update_bikers(delta)
		Phase.CLEAR:
			_clear()
	hud.set_score(Dream.score)
	_shake = move_toward(_shake, 0.0, delta * 8.0)
	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	if _meter.visible:
		_meter.queue_redraw()


# ---------------------------------------------------------------- Mundo

func _scroll(delta: float) -> void:
	for s in _sky:
		s.position.x -= _speed * SKY_FACTOR * delta
		if s.position.x <= -s.texture.get_width():
			s.position.x += s.texture.get_width() * 2
	for r in _road:
		r.position.x -= _speed * delta
		if r.position.x <= -r.texture.get_width():
			r.position.x += r.texture.get_width() * 3
	for m in _movers.duplicate():
		var n: Node2D = m["node"]
		n.position.x -= _speed * delta
		if n.position.x < -140:
			n.queue_free()
			_movers.erase(m)
	# El camión salta con el empedrado: más fuerte cuanto más rápido va.
	var bounce := 1.0 if fmod(_t, 0.2) < 0.1 else 0.0
	_rig.position.y = RIG.y + bounce * clampf(_speed / SPEED, 0.0, 1.0) * 1.5


func _decor() -> void:
	if _speed < 20.0:
		return
	if not _has_recent("lamp", 0.9) and randf() < 0.05:
		var tex := "res://assets/prologue/lamp.png" if randf() < 0.6 else "res://assets/prologue/tree_side.png"
		_spawn("lamp", tex, ROAD_Y + 8 - load(tex).get_height(), _back)


func _has_recent(kind: String, seconds: float) -> bool:
	for m in _movers:
		if m["kind"] == kind and m["node"].position.x > 340 - maxf(_speed, 60.0) * seconds:
			return true
	return false


func _spawn(kind: String, tex_path: String, y: float, parent: Node2D, flip := false, x := 340.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(tex_path)
	s.centered = false
	s.flip_h = flip
	s.position = Vector2(x, y)
	parent.add_child(s)
	_movers.append({"node": s, "kind": kind, "hit": false})
	return s


## Humo del escape y líneas de viento (sensación de velocidad).
func _update_fx(delta: float) -> void:
	if randf() < 0.35:
		var puff := Polygon2D.new()
		puff.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)])
		puff.color = Color(0.6, 0.6, 0.65, 0.6)
		puff.position = Vector2(TRUCK_REAR + 2, RIG.y - 8)
		_fx.add_child(puff)
		var t := create_tween().set_parallel()
		t.tween_property(puff, "position", puff.position + Vector2(-20 - _speed * 0.3, -10), 0.8)
		t.tween_property(puff, "scale", Vector2(3, 3), 0.8)
		t.tween_property(puff, "modulate:a", 0.0, 0.8)
		t.chain().tween_callback(puff.queue_free)
	if _speed > 120.0 and randf() < _speed / SPEED * 0.6:
		_streaks.append(Vector3(330, randf_range(10, 170), randf_range(10, 30)))
	for i in range(_streaks.size() - 1, -1, -1):
		var s: Vector3 = _streaks[i]
		s.x -= _speed * 2.2 * delta
		_streaks[i] = s
		if s.x < -40:
			_streaks.remove_at(i)
	_front.queue_redraw()


func _draw_streaks() -> void:
	for s in _streaks:
		_front.draw_line(Vector2(s.x, s.y), Vector2(s.x + s.z, s.y), Color(0.85, 0.88, 0.95, 0.35), 1.0)


# ---------------------------------------------------------------- 0. Avenida

func _board(delta: float) -> void:
	if not _truck_started:
		_truck_started = true
		_target_speed = BOARD_TRUCK_SPEED
		for i in CHASERS.size():
			_add_chaser(CHASERS[i], -40.0 - i * 26.0)

	var dir := Input.get_axis("move_left", "move_right")
	_runner.position.x += (dir * RUN_SPEED - _speed) * delta
	_runner.position.x = clampf(_runner.position.x, 4.0, TRUCK_REAR - 6.0)
	_runner.flip_h = dir < 0
	_runner.play("walk" if dir != 0.0 or _speed > 5.0 else "idle")

	for c in _chasers.duplicate():
		var s: AnimatedSprite2D = c
		s.position.x += (CHASER_SPEED - _speed) * delta
		if absf(s.position.x - _runner.position.x) < 8.0:
			# Lo alcanzan: lo tiran para atrás (no hay game over).
			_runner.position.x = maxf(4.0, _runner.position.x - 26.0)
			s.position.x -= 30.0
			_sfx["grunt"].play()
			_hurt()

	var in_range := _runner.position.x > TRUCK_REAR - 22.0
	_prompt.visible = in_range and int(_t * 5) % 2 == 0
	_prompt.text = "¡E! SALTA"
	_prompt.position = Vector2(_runner.position.x - 30, 96)
	if in_range and Input.is_action_just_pressed("interact"):
		_grab_truck()


func _add_chaser(kind: String, x: float) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SideFrames.build(load("res://assets/prologue/enemy_%s.png" % kind), SideFrames.ENEMY)
	s.position = Vector2(x, GROUND_Y - 23 + randf_range(-2, 3))
	s.play("walk")
	s.speed_scale = 1.6
	s.z_index = 9
	add_child(s)
	_chasers.append(s)


func _grab_truck() -> void:
	phase = Phase.HANG
	_prompt.visible = false
	_sfx["click"].play()
	_runner.play("kick")
	var t := create_tween()
	t.tween_property(_runner, "position", HAND + Vector2(-6, 18), 0.25).set_ease(Tween.EASE_OUT)
	await t.finished
	_runner.visible = false
	_hands.visible = true
	_meter.visible = true
	_target_speed = SPEED
	_shake = 2.0
	_theta = 0.3
	_to_spawn = BIKERS.duplicate()
	hud.set_counter("0/%d" % BIKERS.size())
	for c in _chasers:
		var s: AnimatedSprite2D = c
		create_tween().tween_property(s, "modulate:a", 0.0, 2.0).finished.connect(s.queue_free)
	_chasers.clear()


# ---------------------------------------------------------------- 1. Colgado

func _hang(delta: float) -> void:
	var lean := Input.get_axis("move_left", "move_right")
	mood.forced_distress = 0.45 + 0.35 * clampf(absf(_theta) / SLIP_ANGLE, 0.0, 1.0)

	# Fuerzas del camión: viento/vaivén, curvas (el camión se inclina) y baches.
	var force := sin(_t * 1.7) * 1.1 + sin(_t * 3.3 + 1.0) * 0.7
	_next_curve -= delta
	if _next_curve <= 0.0 and _curve_left <= 0.0:
		_curve_dir = 1 if randf() < 0.5 else -1
		_curve_left = CURVE_TIME
		_next_curve = randf_range(5.0, 8.0)
		_spawn("sign", "res://assets/prologue/sign_curve.png", ROAD_Y - 64, _back, _curve_dir < 0, 200.0)
	var tilt := 0.0
	if _curve_left > 0.0:
		_curve_left -= delta
		tilt = -_curve_dir * 0.05
		force += -_curve_dir * CURVE_FORCE
	_rig.rotation = lerpf(_rig.rotation, tilt, 6.0 * delta)
	_next_bump -= delta
	if _next_bump <= 0.0:
		_next_bump = randf_range(1.2, 2.6)
		_omega += randf_range(-2.4, 2.4)
		_shake = 2.5
		_rig.position.y -= 3.0

	if _slip > 0.0:
		_slipping(delta)
		return

	# Patada hacia atrás (a la izquierda, donde vienen las motos).
	if _kick > 0.0:
		_kick -= delta
		if not _kick_done and _kick < 0.16:
			_kick_done = true
			_kick_hit()
	elif Input.is_action_just_pressed("interact"):
		_kick = 0.25
		_kick_done = false
		_hanging.play("kick")
		_omega -= 0.8  # patear para atrás empuja el cuerpo para el otro lado

	# Equilibrio: tiende a irse para un lado; izquierda/derecha corrige.
	var acc := INSTABILITY * _theta - DAMPING * _omega + CONTROL * lean + force
	_omega += acc * delta
	_theta = clampf(_theta + _omega * delta, -1.4, 1.4)
	_hands.rotation = _theta * 0.8
	if _kick <= 0.0:
		# Las piernas quedan atrás del movimiento del cuerpo.
		_hanging.play("swing_r" if _omega > 1.2 else ("swing_l" if _omega < -1.2 else "hang"))
	if absf(_theta) > SLIP_ANGLE:
		_start_slip()


func _start_slip() -> void:
	_slip = REGRAB_TIME
	_presses = 0
	_kick = 0.0
	_hanging.play("slip")
	_sfx["grunt"].play()
	_prompt.text = "¡E!"


## Se le soltó una mano: cuelga de la otra y se sacude. Apretar rápido para volver a agarrarse.
func _slipping(delta: float) -> void:
	_slip -= delta
	_hands.rotation = signf(_theta) * 0.9 + sin(_t * 10.0) * 0.25
	_prompt.visible = int(_t * 8) % 2 == 0
	_prompt.position = Vector2(HAND.x - 18, HAND.y - 52)
	if Input.is_action_just_pressed("interact"):
		_presses += 1
	if _presses >= REGRAB_PRESSES or _slip <= 0.0:
		if _presses < REGRAB_PRESSES:
			_lose_life(HIT_DAMAGE)
		_slip = 0.0
		_prompt.visible = false
		_theta = 0.0
		_omega = 0.0
		_hanging.play("hang")


func _lose_life(amount: int) -> void:
	life = maxi(0, life - amount)
	hud.set_life(float(life) / MAX_LIFE)
	_hurt()
	_sfx["grunt"].play()
	if life <= 0 and phase == Phase.HANG:
		_fall_off()


func _draw_meter() -> void:
	# Arco de equilibrio sobre la cabeza: verde al centro, rojo en los extremos.
	var c: Vector2 = HAND + Vector2(-6, -44)
	_meter.draw_arc(c, 17, deg_to_rad(-152), deg_to_rad(-28), 24, Color(0.05, 0.05, 0.08, 0.85), 6.0)
	_meter.draw_arc(c, 17, deg_to_rad(-150), deg_to_rad(-30), 24, Color(0.95, 0.75, 0.25), 3.0)
	_meter.draw_arc(c, 17, deg_to_rad(-108), deg_to_rad(-72), 12, Color(0.35, 0.85, 0.4), 3.0)
	_meter.draw_arc(c, 17, deg_to_rad(-150), deg_to_rad(-132), 6, Color(0.95, 0.2, 0.15), 3.0)
	_meter.draw_arc(c, 17, deg_to_rad(-48), deg_to_rad(-30), 6, Color(0.95, 0.2, 0.15), 3.0)
	# La aguja sigue hacia dónde se va el cuerpo (theta > 0 = hacia la izquierda).
	var a := deg_to_rad(-90.0 - clampf(_theta / SLIP_ANGLE, -1.0, 1.0) * 60.0)
	_meter.draw_line(c, c + Vector2.from_angle(a) * 20.0, Color.BLACK, 3.0)
	_meter.draw_line(c, c + Vector2.from_angle(a) * 20.0, Color.WHITE, 1.0)
	_meter.draw_circle(c, 2.0, Color.WHITE)


# ---------------------------------------------------------------- Motos

func _update_bikers(delta: float) -> void:
	_next_biker -= delta
	if _next_biker <= 0.0 and not _to_spawn.is_empty() and _bikers.size() < MAX_BIKERS:
		_next_biker = randf_range(2.0, 3.2)
		_spawn_biker(_to_spawn.pop_front())
	for b in _bikers.duplicate():
		_biker_tick(b, delta)


func _spawn_biker(kind: String) -> void:
	var node := Node2D.new()
	node.position = Vector2(-50, BIKE_Y)
	node.z_index = 20
	add_child(node)
	var rider := AnimatedSprite2D.new()
	rider.sprite_frames = SideFrames.build(load("res://assets/prologue/enemy_%s.png" % kind), SideFrames.ENEMY)
	rider.position = Vector2(12, -31)
	rider.play("idle")
	node.add_child(rider)
	var bike := Sprite2D.new()
	bike.texture = load("res://assets/prologue/bike.png")
	bike.centered = false
	bike.position = Vector2(0, -22)
	node.add_child(bike)
	var used: Array = _bikers.map(func(x): return x["slot"])
	var slot := 0 if not 0 in used else 1
	_bikers.append({"node": node, "rider": rider, "kind": kind, "hp": BIKER_HP[kind], "state": "approach", "timer": 0.0, "slot": slot})
	if _to_spawn.size() == BIKERS.size() - 1:
		Narrator.say("—¡Las motos! ¡No lo dejen ir!", true)


func _biker_tick(b: Dictionary, delta: float) -> void:
	var node: Node2D = b["node"]
	var rider: AnimatedSprite2D = b["rider"]
	var target: float = BIKER_SLOT_X[b["slot"]]
	b["timer"] -= delta
	# Las motos zigzaguean un poco al lado del camión.
	var wobble := sin(_t * 3.0 + b["slot"] * 2.0) * 3.0
	match b["state"]:
		"approach":
			node.position.x = move_toward(node.position.x, target, 70.0 * delta)
			if absf(node.position.x - target) < 2.0:
				b["state"] = "ride"
				b["timer"] = randf_range(1.0, 2.0)
		"ride":
			node.position.x = target + wobble
			if b["timer"] <= 0.0 and b["slot"] == 0:
				# Se tira encima para pegar (avisa poniéndose rojo).
				b["state"] = "windup"
				b["timer"] = 0.6
				create_tween().tween_property(rider, "modulate", Color(1, 0.4, 0.4), 0.3)
			elif b["timer"] <= 0.0:
				b["timer"] = 0.5
				# El de atrás espera turno; si el de adelante cayó, pasa adelante.
				if _bikers.filter(func(x): return x["slot"] == 0).is_empty():
					b["slot"] = 0
					b["state"] = "approach"
		"windup":
			node.position.x = move_toward(node.position.x, target + 10.0, 30.0 * delta)
			if b["timer"] <= 0.0:
				b["state"] = "punch"
				b["timer"] = 0.3
				rider.stop()
				rider.play("punch")
		"punch":
			if b["timer"] <= 0.0:
				rider.modulate = Color.WHITE
				_omega -= 2.8  # el golpe lo empuja contra el camión
				_lose_life(HIT_DAMAGE)
				_sfx["hit-1"].play()
				b["state"] = "ride"
				b["timer"] = randf_range(1.4, 2.4)
				rider.play("idle")
		"stagger":
			node.position.x = move_toward(node.position.x, target, 50.0 * delta)
			node.rotation = lerpf(node.rotation, 0.0, 6.0 * delta)
			if b["timer"] <= 0.0:
				b["state"] = "ride"
				b["timer"] = randf_range(1.0, 1.8)
				rider.play("idle")


## La patada pega al que esté más cerca dentro del alcance (y le corta el golpe si lo estaba cargando).
func _kick_hit() -> void:
	var best = null
	for b in _bikers:
		var rx: float = b["node"].position.x + 12.0
		if b["state"] != "crash" and rx >= KICK_RANGE.x and rx <= KICK_RANGE.y:
			if best == null or rx > best["node"].position.x + 12.0:
				best = b
	if best == null:
		_sfx["miss"].play()
		return
	best["hp"] -= 1
	Dream.add(100)
	_sfx["hit-2"].play()
	_shake = 2.0
	var rider: AnimatedSprite2D = best["rider"]
	rider.modulate = Color.WHITE
	if best["hp"] <= 0:
		_crash(best)
	else:
		best["state"] = "stagger"
		best["timer"] = 0.6
		best["node"].position.x -= 26.0
		best["node"].rotation = -0.3
		rider.stop()
		rider.play("hurt")


## Se cae de la moto: la moto da vueltas hacia atrás y el que manejaba sale volando.
func _crash(b: Dictionary) -> void:
	b["state"] = "crash"
	_bikers.erase(b)
	Dream.add(500)
	var node: Node2D = b["node"]
	var rider: AnimatedSprite2D = b["rider"]
	rider.play("fall")
	rider.reparent(self)
	var t := create_tween().set_parallel()
	t.tween_property(node, "position", node.position + Vector2(-160, 0), 0.9).set_ease(Tween.EASE_IN)
	t.tween_property(node, "rotation", -6.0, 0.9)
	t.tween_property(rider, "position", rider.position + Vector2(-120, -30), 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property(rider, "rotation", -4.0, 0.9)
	t.chain().tween_callback(func():
		node.queue_free()
		rider.queue_free())
	var done := BIKERS.size() - _to_spawn.size() - _bikers.size()
	hud.set_counter("%d/%d" % [done, BIKERS.size()])
	if _to_spawn.is_empty() and _bikers.is_empty():
		_stage_clear()


# ---------------------------------------------------------------- 2. Final

## Ganó: STAGE CLEAR; el camión frena en el puente y él se baja. Abajo lo espera Lilato.
func _stage_clear() -> void:
	phase = Phase.CLEAR
	_meter.visible = false
	_prompt.visible = false
	_banner.visible = true
	_sfx["gogogo"].play()
	Dream.add(3000)
	mood.forced_distress = 0.4
	_hands.rotation = 0.0
	_hanging.play("hang")
	_target_speed = 0.0
	Narrator.say("El camión frena en el puente.", true)
	await get_tree().create_timer(2.8).timeout
	phase = Phase.DONE
	SceneRouter.go(NEXT_SCENE)


func _clear() -> void:
	pass


## Perdió: se suelta y cae a la calle (rueda hasta el puente: igual lo espera Lilato).
func _fall_off() -> void:
	phase = Phase.FALL
	_meter.visible = false
	_prompt.visible = false
	mood.forced_distress = 1.0
	Engine.time_scale = 0.4
	_hanging.play("slip")
	_hands.reparent(self)
	var t := create_tween().set_parallel()
	t.tween_property(_hands, "position", _hands.position + Vector2(-70, 50), 0.7).set_ease(Tween.EASE_IN)
	t.tween_property(_hands, "rotation", 2.5, 0.7)
	await t.finished
	phase = Phase.DONE
	_flash.color = Color(0, 0, 0, 1)
	SceneRouter.go(NEXT_SCENE)


func _hurt() -> void:
	_shake = 3.0
	_flash.color = Color(0.6, 0.05, 0.05, 0.35)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.3)


func debug_skip() -> void:
	SceneRouter.go(NEXT_SCENE)
