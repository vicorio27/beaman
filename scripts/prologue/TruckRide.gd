extends Node2D
## Sueño 1 (beat 'em up), parte 2 — La avenida y el camión en movimiento (de costado).
##   0. AVENIDA: sale del callejón; el camión de "Harinas El Sol" arranca; vienen más matones.
##      Correr detrás del camión y saltar (botón) para agarrarse.
##   1. COLGADO: cuelga del borde del techo de la caja y se balancea (péndulo). Izquierda/derecha:
##      se mueve a lo largo de la caja, mano sobre mano (moverse también lo hace balancear).
##      Arriba: encoge las piernas (se estabiliza, y así pasan por debajo las carretillas y canecas
##      parqueadas; no se puede mover ni pegar). Si se balancea demasiado se suelta una mano:
##      apretar el botón rápido para volver a agarrarse.
##      Los matones vienen en moto por los dos lados: se le acercan, cargan (se ponen rojos) y pegan.
##      Botón = patada hacia donde mira; dos seguidas = patada y puño. Si el más cercano está lejos
##      (pasado el umbral de la patada), le tira una bolsa de harina del camión. Cuando cruza el
##      umbral, la patada (o el puño) le llega justo: el golpeado se acomoda al pie / al puño.
##      Los que tiran botellas se quedan lejos: moverse esquiva la botella, y un golpe a tiempo
##      la devuelve.
##      Largo y frenético: 22 motos, curvas, baches y cosas parqueadas.
##   2. GANÓ: STAGE CLEAR, el camión frena en el puente: abajo lo espera Lilato (jefa final).
##      PERDIÓ (sin vida): se cae del camión y rueda hasta el puente: también va a Lilato.

const NEXT_SCENE := "res://scenes/prologue/Lilato.tscn"
const SPEED := 330.0  # velocidad del mundo con el camión lanzado (px/s)
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

# --- Colgado (del borde del techo de la caja)
const GRIP_Y := ROOF_Y + 1.0
const RAIL := Vector2(TRUCK_REAR + 8.0, TRUCK_REAR + 104.0)  # hasta dónde se mueve (x de pantalla)
const SHIMMY := 54.0  # mano sobre mano (px/s)
const HANG_GRIP := Vector2(20, 2)  # las manos dentro de cada cuadro de player_hang.png
const HANG_CELL := Vector2(40, 48)
const STIFF := 5.0  # el péndulo vuelve solo al centro...
const STIFF_TUCK := 10.0  # ...y encogido, más rápido
const DAMPING := 1.2
const DAMPING_TUCK := 4.5
const CONTROL := 3.0  # moverse lo balancea para el otro lado
const SLIP_ANGLE := 1.0
const REGRAB_PRESSES := 3
const REGRAB_TIME := 1.4
const CURVE_TIME := 2.4
const CURVE_FORCE := 4.0
const MAX_LIFE := 80
const HIT_DAMAGE := 5

# --- Golpes (desde él, hacia donde mira)
const KICK_REACH := Vector2(4, 42)  # el umbral: más cerca que esto, la patada llega
const PUNCH_REACH := Vector2(0, 36)
const KICK_TIME := 0.28
const PUNCH_TIME := 0.26
const COMBO_WINDOW := 0.4
const THROW_RANGE := 190.0  # hasta dónde tira la bolsa de harina
const THROW_SPEED := 230.0
const THROW_COOLDOWN := 0.55
## Dónde quedan el pie (patada estirada) y el puño (pegando abajo), desde las manos, mirando a la izquierda.
const FOOT := Vector2(-17, 39)
const FIST := Vector2(-16, 34)

# --- Motos
const BIKERS := ["punk", "goon", "punk", "punk", "thug", "goon", "punk", "goon", "punk", "thug",
	"punk", "goon", "punk", "thug", "goon", "punk", "goon", "thug", "punk", "goon", "thug", "thug"]
const BIKER_HP := {"punk": 1, "goon": 2, "thug": 3}
const MAX_BIKERS := 3
const HOVER := 48.0  # a esta distancia esperan (fuera del alcance de la patada)
const THROW_HOVER := 84.0  # los que tiran botellas, más lejos
const BIKER_FOLLOW := 42.0  # lo siguen más despacio de lo que él se mueve
const BOTTLE_TIME := 0.6
const BIKE_W := 36.0

# --- Cosas parqueadas en el carril de afuera (encoger las piernas)
const OBSTACLE_EVERY := Vector2(6.5, 10.0)
const OBSTACLE_WARN := 1.2
const OBSTACLES := {"carretilla": 24.0, "caneca": 22.0}  # alto de cada una

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
var _px := RAIL.x  # dónde está agarrado (x de pantalla)
var _face := -1.0  # hacia dónde mira: -1 izquierda, 1 derecha
var _tuck := false
var _attack := 0.0  # lo que le falta al golpe en curso
var _attack_kind := ""
var _hit_done := false
var _combo := 0.0
var _throw_cd := 0.0
var _throw_target = null  # la moto a la que va la bolsa
var _next_obstacle := 9.0
var _warned := false
var _obstacles: Array = []  # [{node, h, hit}]
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
	_hands.position = Vector2(_px, GRIP_Y) - RIG
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
		"kick": [[4, 5, 5, 4], 14.0, false],
		"slip": [[6, 7], 8.0, true],
		"shimmy": [[8, 9], 7.0, true],
		"punch": [[10, 11, 11, 10], 15.0, false],
		"tuck": [[12], 1.0, true],
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
	_prompt.text = Controls.keys_in("¡E! SALTA")
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
	t.tween_property(_runner, "position", Vector2(_px, GRIP_Y + 20), 0.25).set_ease(Tween.EASE_OUT)
	await t.finished
	_runner.visible = false
	_hands.visible = true
	_meter.visible = true
	_target_speed = SPEED
	_shake = 2.0
	_theta = 0.3
	_to_spawn = BIKERS.duplicate()
	hud.set_counter("0/%d" % BIKERS.size())
	var keys := "A" if Controls.touch() else "E"
	Narrator.say("<- -> moverse   %s patada (dos: puño)   ^ encoger las piernas" % keys, true)
	for c in _chasers:
		var s: AnimatedSprite2D = c
		create_tween().tween_property(s, "modulate:a", 0.0, 2.0).finished.connect(s.queue_free)
	_chasers.clear()


# ---------------------------------------------------------------- 1. Colgado

func _hang(delta: float) -> void:
	var lean := Input.get_axis("move_left", "move_right")
	_tuck = Input.is_action_pressed("move_up") and _slip <= 0.0
	mood.forced_distress = 0.45 + 0.35 * clampf(absf(_theta) / SLIP_ANGLE, 0.0, 1.0)

	# Fuerzas del camión: viento/vaivén, curvas (el camión se inclina) y baches.
	var force := sin(_t * 1.7) * 1.1 + sin(_t * 3.3 + 1.0) * 0.7
	_next_curve -= delta
	if _next_curve <= 0.0 and _curve_left <= 0.0:
		_curve_dir = 1 if randf() < 0.5 else -1
		_curve_left = CURVE_TIME
		_next_curve = randf_range(3.0, 5.5)
		_spawn("sign", "res://assets/prologue/sign_curve.png", ROAD_Y - 64, _back, _curve_dir < 0, 200.0)
	var tilt := 0.0
	if _curve_left > 0.0:
		_curve_left -= delta
		tilt = -_curve_dir * 0.05
		force += -_curve_dir * CURVE_FORCE
	_rig.rotation = lerpf(_rig.rotation, tilt, 6.0 * delta)
	_next_bump -= delta
	if _next_bump <= 0.0:
		_next_bump = randf_range(0.7, 1.6)
		_omega += randf_range(-1.5, 1.5)
		_shake = 3.5
		_rig.position.y -= 3.0
	_update_obstacles(delta)

	if _slip > 0.0:
		_slipping(delta)
		_place_hands()
		return

	# Mano sobre mano a lo largo de la caja. No mientras pega ni encogido.
	var moving := lean != 0.0 and _attack <= 0.0 and not _tuck
	if moving:
		_face = signf(lean)
		_px = clampf(_px + lean * SHIMMY * delta, RAIL.x, RAIL.y)
		force += sin(_t * 9.0) * 2.0  # cada mano que suelta lo sacude
	_hanging.flip_h = _face > 0.0

	# Golpes: patada; otra vez enseguida = puño.
	_combo -= delta
	if _attack > 0.0:
		_attack -= delta
		if not _hit_done and _attack < (KICK_TIME if _attack_kind == "kick" else PUNCH_TIME) * 0.55:
			_hit_done = true
			if _attack_kind == "throw":
				_throw_flour()
			else:
				_attack_hit()
	_throw_cd -= delta
	if Input.is_action_just_pressed("interact") and not _tuck and _attack < 0.08:
		# Si adelante no hay nadie y atrás sí: se da vuelta (el botón es para el que está).
		if _nearest_ahead(THROW_RANGE) == null:
			_face = -_face
			if _nearest_ahead(THROW_RANGE) == null:
				_face = -_face  # no hay nadie en ningún lado: patea al aire, para donde miraba
			_hanging.flip_h = _face > 0.0
		# Si nadie pasó el umbral de la patada pero hay alguien más lejos: harina.
		var far = _nearest_ahead(THROW_RANGE)
		if _nearest_ahead(KICK_REACH.y) == null and far != null:
			if _throw_cd <= 0.0:
				_throw_target = far
				_start_attack("throw")
			# recién tiró: espera a sacar otra bolsa (no patea al aire)
		else:
			_start_attack("punch" if _combo > 0.0 and _attack_kind == "kick" else "kick")

	# El péndulo: vuelve solo al centro; las fuerzas lo sacan. Encogido, se estabiliza.
	var k := STIFF_TUCK if _tuck else STIFF
	var d := DAMPING_TUCK if _tuck else DAMPING
	var acc := -k * _theta - d * _omega + CONTROL * (lean if moving else 0.0) + force
	_omega += acc * delta
	_theta = clampf(_theta + _omega * delta, -1.4, 1.4)
	_hands.rotation = _theta * 0.8
	_place_hands()
	if _attack <= 0.0:
		if _tuck:
			_hanging.play("tuck")
		elif moving:
			_hanging.play("shimmy")
		else:
			_hanging.play("swing_r" if _omega > 1.2 else ("swing_l" if _omega < -1.2 else "hang"))
	if absf(_theta) > SLIP_ANGLE:
		_start_slip()


func _place_hands() -> void:
	_hands.position = Vector2(_px, GRIP_Y) - RIG


func _start_attack(kind: String) -> void:
	_attack_kind = kind
	_attack = KICK_TIME if kind == "kick" else PUNCH_TIME
	_hit_done = false
	_combo = COMBO_WINDOW + _attack if kind != "throw" else 0.0
	_hanging.stop()
	_hanging.play("punch" if kind == "throw" else kind)  # tirar: el mismo brazo, soltando la bolsa
	_omega += -_face * (0.8 if kind == "kick" else 0.4)  # pegar para un lado empuja el cuerpo al otro


## Dónde están los pies (o el puño) en la pantalla, más o menos: para los golpes y las cosas parqueadas.
func _feet_y() -> float:
	return GRIP_Y + (36.0 if _tuck else 46.0)


func _start_slip() -> void:
	_slip = REGRAB_TIME
	_presses = 0
	_attack = 0.0
	_hanging.play("slip")
	_sfx["grunt"].play()
	_prompt.text = "¡%s!" % ("A" if Controls.touch() else "E")


## Se le soltó una mano: cuelga de la otra y se sacude. Apretar rápido para volver a agarrarse.
func _slipping(delta: float) -> void:
	_slip -= delta
	_hands.rotation = signf(_theta) * 0.9 + sin(_t * 10.0) * 0.25
	_prompt.visible = int(_t * 8) % 2 == 0
	_prompt.position = Vector2(_px - 12, GRIP_Y - 46)  # encima del medidor (no sobre el letrero del camión)
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
	var c := Vector2(_px, GRIP_Y - 14)
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
	# Aviso de lo parqueado que viene: flecha arriba titilando.
	if _warned and int(_t * 6) % 2 == 0:
		var w := Vector2(_px + 22, GRIP_Y + 10)
		_meter.draw_colored_polygon(PackedVector2Array([w + Vector2(0, -8), w + Vector2(-6, 0), w + Vector2(6, 0)]), Color(1, 0.85, 0.3))
		_meter.draw_rect(Rect2(w + Vector2(-2, 0), Vector2(4, 6)), Color(1, 0.85, 0.3))


# ---------------------------------------------------------------- Cosas parqueadas

## Cada tanto, una carretilla o una caneca en el carril de afuera: pasa a la altura de los pies.
## Avisa antes (flecha arriba). Si no encoge las piernas, se la lleva. A las motos también.
func _update_obstacles(delta: float) -> void:
	_next_obstacle -= delta
	if not _warned and _next_obstacle <= OBSTACLE_WARN and not _to_spawn.is_empty():
		_warned = true
		_sfx["click"].play()
	if _next_obstacle <= 0.0:
		_next_obstacle = randf_range(OBSTACLE_EVERY.x, OBSTACLE_EVERY.y)
		_warned = false
		var kind: String = OBSTACLES.keys().pick_random()
		var h: float = OBSTACLES[kind]
		var node := _spawn("obstacle", "res://assets/prologue/%s.png" % kind, BIKE_Y - h, self, false, 340.0)
		node.z_index = 22
		_obstacles.append({"node": node, "h": h, "hit": false})
	for o in _obstacles.duplicate():
		if not is_instance_valid(o["node"]):  # ya pasó (la soltó _scroll)
			_obstacles.erase(o)
			continue
		var node: Sprite2D = o["node"]
		var x0 := node.position.x
		var x1 := x0 + node.texture.get_width()
		# Se lleva a las motos que estén en el camino.
		for b in _bikers.duplicate():
			var bx: float = b["node"].position.x
			if bx + BIKE_W > x0 + 4.0 and bx < x1 - 4.0:
				_crash(b, true)
		# Y a él, si cuelga con las piernas abajo.
		if not o["hit"] and phase == Phase.HANG and _px + 6.0 > x0 and _px - 6.0 < x1:
			if _feet_y() > BIKE_Y - o["h"] + 2.0:
				o["hit"] = true
				_omega += 3.2
				_lose_life(HIT_DAMAGE * 2)
				_sfx["hit-1"].play()
				_pop_text("¡PUM!", Vector2(_px + 20, GRIP_Y - 14))


# ---------------------------------------------------------------- Motos

func _update_bikers(delta: float) -> void:
	_next_biker -= delta
	if _next_biker <= 0.0 and not _to_spawn.is_empty() and _bikers.size() < MAX_BIKERS:
		_next_biker = randf_range(1.2, 2.4)
		_spawn_biker(_to_spawn.pop_front())
	for b in _bikers.duplicate():
		_biker_tick(b, delta)


func _spawn_biker(kind: String) -> void:
	# La mayoría vienen de atrás (lo alcanzan); algunos se quedan desde adelante.
	var side := -1.0 if randf() < 0.7 else 1.0
	var node := Node2D.new()
	node.position = Vector2(-50 if side < 0 else 340, BIKE_Y)
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
	# Uno de cada tres se queda lejos tirando botellas (si no hay ya otro haciéndolo).
	var throwers := _bikers.filter(func(x): return x["thrower"]).size()
	var thrower := throwers == 0 and (BIKERS.size() - _to_spawn.size()) % 3 == 0
	_bikers.append({"node": node, "rider": rider, "kind": kind, "hp": BIKER_HP[kind], "state": "approach",
		"timer": 0.0, "side": side, "thrower": thrower})
	if _to_spawn.size() == BIKERS.size() - 1:
		Narrator.say("—¡Las motos! ¡No lo dejen ir!", true)


## El centro de la moto (x de pantalla).
func _bx(b: Dictionary) -> float:
	return b["node"].position.x + BIKE_W * 0.5


func _biker_tick(b: Dictionary, delta: float) -> void:
	var node: Node2D = b["node"]
	var rider: AnimatedSprite2D = b["rider"]
	b["timer"] -= delta
	# Se quedan de su lado: si él se pasa, cambian de lado.
	var side: float = signf(_bx(b) - _px)
	if side == 0.0:
		side = b["side"]
	b["side"] = side
	rider.flip_h = side > 0.0  # miran hacia él
	var hover: float = THROW_HOVER if b["thrower"] else HOVER
	var target := clampf(_px + side * hover, -20.0, 300.0) - BIKE_W * 0.5
	var wobble := sin(_t * 3.0 + node.get_instance_id() % 7) * 3.0
	match b["state"]:
		"approach":
			node.position.x = move_toward(node.position.x, target, 120.0 * delta)
			if absf(node.position.x - target) < 3.0:
				b["state"] = "ride"
				b["timer"] = randf_range(0.6, 1.4)
		"ride":
			node.position.x = move_toward(node.position.x, target + wobble, BIKER_FOLLOW * delta)
			if b["timer"] <= 0.0:
				if b["thrower"]:
					b["timer"] = randf_range(1.6, 2.6)
					_throw_bottle(b)
				else:
					# Se le tira encima para pegar (avisa poniéndose rojo).
					b["state"] = "windup"
					b["timer"] = 0.65
					create_tween().tween_property(rider, "modulate", Color(1, 0.4, 0.4), 0.3)
		"windup":
			node.position.x = move_toward(node.position.x, _px + side * 14.0 - BIKE_W * 0.5, 70.0 * delta)
			if b["timer"] <= 0.0:
				b["state"] = "punch"
				b["timer"] = 0.3
				rider.stop()
				rider.play("punch")
		"punch":
			if b["timer"] <= 0.0:
				rider.modulate = Color.WHITE
				if absf(_bx(b) - _px) < 26.0 and _slip <= 0.0:
					_omega += -side * 2.6  # el golpe lo empuja para el otro lado
					_lose_life(HIT_DAMAGE)
					_sfx["hit-1"].play()
				else:
					_sfx["miss"].play()  # se movió a tiempo
				b["state"] = "ride"
				b["timer"] = randf_range(1.3, 2.3)
				rider.play("idle")
		"stagger":
			node.position.x = move_toward(node.position.x, target, 50.0 * delta)
			node.rotation = lerpf(node.rotation, 0.0, 6.0 * delta)
			if b["timer"] <= 0.0:
				b["state"] = "ride"
				b["timer"] = randf_range(0.7, 1.3)
				rider.play("idle")
				rider.modulate = Color.WHITE


## Tira una botella (en arco) a donde está él ahora. Si se movió, la esquiva; si le pega justo
## cuando llega (patada o puño), la devuelve.
func _throw_bottle(b: Dictionary) -> void:
	var rider: AnimatedSprite2D = b["rider"]
	rider.play("punch")
	var bottle := Sprite2D.new()
	bottle.texture = load("res://assets/prologue/item_bottle.png")
	bottle.z_index = 25
	bottle.position = b["node"].position + Vector2(14, -40)
	add_child(bottle)
	var from := bottle.position
	var to := Vector2(_px, GRIP_Y + 20)
	var t := create_tween().set_parallel()
	t.tween_method(func(k: float): bottle.position = from.lerp(to, k) - Vector2(0, sin(k * PI) * 30.0), 0.0, 1.0, BOTTLE_TIME)
	t.tween_property(bottle, "rotation", 9.0, BOTTLE_TIME)
	await t.finished
	if is_instance_valid(rider):
		rider.play("idle")
	if phase != Phase.HANG:
		bottle.queue_free()
		return
	if absf(_px - to.x) > 12.0:  # se movió: la botella se revienta contra la caja
		bottle.queue_free()
		_sfx["miss"].play()
		_pop_text("¡CRASH!", Vector2(to.x + 20, GRIP_Y - 14))
		return
	if _attack > 0.0 and _attack_kind != "throw":  # la devolvió de un golpe
		Dream.add(150)
		_sfx["hit-2"].play()
		var back := create_tween().set_parallel()
		back.tween_property(bottle, "position", bottle.position + Vector2(-_face * -140.0, 40), 0.5)
		back.tween_property(bottle, "rotation", -12.0, 0.5)
		back.chain().tween_callback(bottle.queue_free)
		return
	bottle.queue_free()
	_omega += 1.8 * signf(_px - from.x)
	_lose_life(HIT_DAMAGE)
	_sfx["hit-1"].play()
	_pop_text("¡CRASH!", Vector2(to.x + 20, GRIP_Y - 14))


## Un "¡TOMA!" / "¡PUF!" corto. Va en la franja libre entre el medidor y el techo del camión (no sobre
## el letrero), sin subir: se agranda y se desvanece ahí mismo.
func _pop_text(text: String, at: Vector2) -> void:
	at.y = GRIP_Y - 13.0
	var w := text.length() * 8.0
	if at.x + w > _px - 20.0 and at.x < _px + 20.0:  # no encima del medidor: a un lado
		at.x = _px + 22.0 if at.x + w * 0.5 >= _px else _px - 22.0 - w
	at.x = clampf(at.x, 2.0, Controls.right_edge() - w)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.position = at
	l.z_index = 40
	add_child(l)
	var g := create_tween()
	g.tween_interval(0.35)
	g.tween_property(l, "modulate:a", 0.0, 0.3)
	g.tween_callback(l.queue_free)


## La moto más cercana hacia donde mira, a menos de `limit` (null si no hay).
func _nearest_ahead(limit: float):
	var best = null
	var best_d := limit
	for b in _bikers:
		var d := (_bx(b) - _px) * _face
		if b["state"] != "crash" and d >= 0.0 and d <= best_d:
			best = b
			best_d = d
	return best


## Dónde queda (en la pantalla) un punto del cuerpo colgado: las manos + el balanceo.
func _body_point(p: Vector2) -> Vector2:
	var local := Vector2(p.x * -_face, p.y)  # los cuadros miran a la izquierda; espejado si mira a la derecha
	return Vector2(_px, GRIP_Y) + local.rotated(_hands.rotation + _rig.rotation)


## El golpe pega al que esté más cerca hacia donde mira, dentro del alcance (patada más larga que el
## puño). Si lo estaba cargando, se lo corta. El golpeado se acomoda para que el pie (o el puño) le
## llegue justo al cuerpo, y después sale para atrás.
func _attack_hit() -> void:
	var reach := KICK_REACH if _attack_kind == "kick" else PUNCH_REACH
	var best = null
	var best_d := 999.0
	for b in _bikers:
		var d := (_bx(b) - _px) * _face
		if b["state"] != "crash" and d >= reach.x and d <= reach.y and d < best_d:
			best = b
			best_d = d
	if best == null:
		_sfx["miss"].play()
		return
	var contact := _body_point(FOOT if _attack_kind == "kick" else FIST)
	best["contact_x"] = contact.x + _face * 5.0 - 12.0  # el cuerpo del que maneja (rider en x+12) contra el pie
	best["hp"] -= 1
	Dream.add(100)
	_sfx["hit-2"].play()
	_shake = 2.0
	var rider: AnimatedSprite2D = best["rider"]
	rider.modulate = Color(1, 1, 1)
	_pop_text("¡PAF!" if _attack_kind == "punch" else "¡TOMA!", Vector2(_bx(best) - 20, BIKE_Y - 62))
	_knock(best)


## Le pegaron (patada, puño o harina): pierde vida; se tambalea para atrás, o se cae de la moto.
func _knock(b: Dictionary) -> void:
	var rider: AnimatedSprite2D = b["rider"]
	if b["hp"] <= 0:
		_crash(b)
		return
	var away: float = signf(_bx(b) - _px)
	if away == 0.0:
		away = _face
	b["state"] = "stagger"
	b["timer"] = 0.7
	var node: Node2D = b["node"]
	var k := create_tween()
	var x0: float = node.position.x
	if b.has("contact_x"):  # primero se acomoda contra el pie / el puño...
		x0 = b["contact_x"]
		b.erase("contact_x")
		k.tween_property(node, "position:x", x0, 0.04)
	k.tween_interval(0.04)
	k.tween_property(node, "position:x", x0 + away * 28.0, 0.16).set_ease(Tween.EASE_OUT)  # ...y sale para atrás
	node.rotation = 0.3 * away
	rider.stop()
	rider.play("hurt")
	rider.modulate = Color(3, 3, 3)  # el que recibe se pone blanco un instante
	create_tween().tween_property(rider, "modulate", Color.WHITE, 0.2)


## Le tira una bolsa de harina del camión al que está lejos. Va siguiéndolo; si le llega, ¡PUF!
func _throw_flour() -> void:
	var b = _throw_target
	_throw_target = null
	_throw_cd = THROW_COOLDOWN
	if b == null or b["state"] == "crash":
		return
	var bag := Sprite2D.new()
	bag.texture = load("res://assets/prologue/bolsa_harina.png")
	bag.z_index = 26
	bag.position = _body_point(FIST)
	add_child(bag)
	_sfx["click"].play()
	var from := bag.position
	var dist := absf(_bx(b) - from.x)
	var time := maxf(0.2, dist / THROW_SPEED)
	var face := _face
	var fly := func(k: float) -> void:
		if not is_instance_valid(bag):
			return
		var to: Vector2 = Vector2(_bx(b), BIKE_Y - 34) if b["state"] != "crash" else from + Vector2(face * dist, 20)
		bag.position = from.lerp(to, k) - Vector2(0, sin(k * PI) * 14.0)
	var t := create_tween().set_parallel()
	t.tween_method(fly, 0.0, 1.0, time)
	t.tween_property(bag, "rotation", _face * 8.0, time)
	await t.finished
	var at := bag.position
	bag.queue_free()
	_flour_puff(at)
	if phase != Phase.HANG or b["state"] == "crash" or not _bikers.has(b):
		return
	b["hp"] -= 1
	Dream.add(80)
	_sfx["hit-2"].play()
	_pop_text("¡PUF!", Vector2(_bx(b) - 14, BIKE_Y - 62))
	b["rider"].modulate = Color.WHITE
	_knock(b)


## La nube de harina donde revienta la bolsa.
func _flour_puff(at: Vector2) -> void:
	for i in 8:
		var p := Polygon2D.new()
		p.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -2), Vector2(2, 0), Vector2(0, 2)])
		p.color = Color(0.96, 0.94, 0.88, 0.9)
		p.position = at
		p.z_index = 27
		add_child(p)
		var dir := Vector2.from_angle(i * TAU / 8.0 + randf_range(-0.3, 0.3))
		var t := create_tween().set_parallel()
		t.tween_property(p, "position", at + dir * randf_range(8, 16) + Vector2(-_speed * 0.05, -4), 0.5)
		t.tween_property(p, "scale", Vector2(2.5, 2.5), 0.5)
		t.tween_property(p, "modulate:a", 0.0, 0.5)
		t.chain().tween_callback(p.queue_free)


## Se cae de la moto: la moto da vueltas hacia atrás y el que manejaba sale volando.
## by_obstacle: se la llevó una carretilla (también cuenta).
func _crash(b: Dictionary, by_obstacle := false) -> void:
	if b["state"] == "crash":
		return
	b["state"] = "crash"
	_bikers.erase(b)
	Dream.add(500)
	var node: Node2D = b["node"]
	var rider: AnimatedSprite2D = b["rider"]
	rider.play("fall")
	rider.reparent(self)
	var away := -1.0 if by_obstacle else signf(_bx(b) - _px)
	if away == 0.0:
		away = -1.0
	var t := create_tween().set_parallel()
	t.tween_property(node, "position", node.position + Vector2(-160, 0), 0.9).set_ease(Tween.EASE_IN)
	t.tween_property(node, "rotation", -6.0, 0.9)
	t.tween_property(rider, "position", rider.position + Vector2(away * 60.0 - 70.0, -34), 0.5).set_ease(Tween.EASE_OUT)
	t.tween_property(rider, "rotation", away * 4.0, 0.9)
	t.chain().tween_callback(func():
		node.queue_free()
		rider.queue_free())
	if by_obstacle:
		_pop_text("¡JA!", Vector2(_bx(b) - 10, BIKE_Y - 60))
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
	_warned = false
	_banner.visible = true
	_sfx["gogogo"].play()
	Dream.add(3000)
	mood.forced_distress = 0.4
	_hands.rotation = 0.0
	_hanging.flip_h = false
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
