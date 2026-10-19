class_name PelotaLukas
extends CanvasLayer
## Después de los penaltis: Lukas se roba la pelota y sale con ella por el lote, conduciéndola con el
## hocico (la pelota rueda adelante de él, con su física: rebota en el muro y en las orillas, el pasto
## la frena). Hay que quitársela y meterla entre los dos morrales del arco (flechas / palanca para
## correr; tocar la pelota es pegarle, hacia donde va corriendo, o al arco si está quieto). Lukas es más
## rápido y, cuando lo tienen cerca, hace el quiebre; con los segundos se cansa. Los tres pelados
## corren detrás de la pelota y, si la alcanzan, le pegan para cualquier lado.
##   LA BARRA DEL PIQUE: se llena con el tiempo y con cada patadón. Llena, con [F]: sale corriendo como
##     un rayo un momento, y el patadón que pegue mientras tanto sale con fuego (y no hay quien lo pare).
## Si la mete (o si Lukas, de tanto empujarla, se la mete solo), se tiran todos al pasto encima de
## Lukas. Si no en 25 segundos, Lukas se queda con ella y la trae cuando él quiere.
##   var caught: bool = await PelotaLukas.play(self)

signal _done(caught: bool)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const PANEL := Rect2(0, 34, 320, 146)  # el lote de los penaltis, de lado a lado (debajo de la barra)
const FIELD := Rect2(12, 62, 262, 112)  # por donde se corre (ni el muro ni la franja de los botones)
const GOAL_L := 119.0   # entre los morrales (el de la izquierda termina aquí)
const GOAL_R := 196.0   # (y el de la derecha empieza aquí)
const GOAL_Y := 80.0    # la raya: la pelota que la pasa hacia arriba, entre los dos, es gol
const HIM_SPEED := 64.0
const DOG_SPEED := 80.0
const KICK := 150.0     # el patadón (px/s)
const FIRE_KICK := 230.0
const TIME := 25.0
const FULL := 3         # la barra del pique
const KID_COLORS := [Color(0.9, 0.75, 0.25), Color(0.5, 0.3, 0.7), Color(0.3, 0.6, 0.85)]
const SFX := {"patada": ["futbol", -4.0], "red": ["futbol", -6.0], "fuego": ["futbol", -4.0], "carga": ["tenis", -9.0]}

var _field: Node2D
var _over: Node2D
var _him: AnimatedSprite2D
var _dog: AnimatedSprite2D
var _kids: Array = []      # {spr, pos, speed, off, cool}
var _dog_pos := Vector2(200, 110)
var _dog_v := Vector2(-1, 0)
var _juke := 0.0
var _t := 0.0
var _state := "chase"      # "chase", "pile", "closed"
var _caught := false
var _hint: Label
var _dust: Array = []
var _ball := Vector2(190, 112)
var _bv := Vector2(-40, 0)
var _bz := 0.0             # la altura de la pelota (rebota)
var _bvz := 0.0
var _dog_stun := 0.0       # le acaban de pegar a la pelota: Lukas tarda un momentico en reaccionar
var _kick_cool := 0.0
var _bar := 0
var _bar_t := 0.0
var _rush := 0.0           # el pique: cuánto le queda
var _fire: Array = []      # la estela del patadón con fuego
var _fire_on := false
var _move := Vector2.ZERO
var _sfx := {}


static func play(parent: Node) -> bool:
	var ui := PelotaLukas.new()
	parent.get_tree().root.add_child(ui)
	var r: bool = await ui._done
	ui.queue_free()
	return r


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	Controls.minigame = true   # en el celular: los botones del minijuego (con la huella)
	_field = Node2D.new()
	_field.draw.connect(_draw_field)
	add_child(_field)
	for k in 3:
		var kid := AnimatedSprite2D.new()
		kid.sprite_frames = CharacterFrames.adult(CharacterFrames.STRANGERS[k + 1])
		kid.scale = Vector2(0.8, 0.8)  # pelados
		kid.modulate = KID_COLORS[k].lerp(Color.WHITE, 0.55)
		add_child(kid)
		_kids.append({"spr": kid, "pos": Vector2(150 + k * 22, 150), "speed": 52.0 + k * 5.0,
			"off": Vector2(-14 + k * 14, 10 - k * 8), "cool": 0.0})
	_dog = AnimatedSprite2D.new()
	_dog.sprite_frames = SpriteFrames.new()
	_dog.sprite_frames.remove_animation("default")
	var cols := {"side": 0, "down": 1, "up": 2}
	for dir in cols:
		_dog.sprite_frames.add_animation("run_" + dir)
		_dog.sprite_frames.set_animation_speed("run_" + dir, 12.0)
		_dog.sprite_frames.add_frame("run_" + dir, Lukas.cell(cols[dir], 1))
		_dog.sprite_frames.add_frame("run_" + dir, Lukas.cell(cols[dir], 2))
	_dog.sprite_frames.add_animation("lie")
	_dog.sprite_frames.add_frame("lie", Lukas.cell(2, 3))
	add_child(_dog)
	_him = AnimatedSprite2D.new()
	_him.sprite_frames = CharacterFrames.protagonist()
	_him.position = Vector2(110, 140)
	add_child(_him)
	_over = Node2D.new()  # la pelota, el polvo, el fuego
	_over.draw.connect(_draw_over)
	add_child(_over)
	_hint = Label.new()
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(1, 0.92, 0.55))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.08))
	_hint.position = Vector2(PANEL.position.x, 37)
	_hint.size = Vector2(Controls.right_edge(), 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "¡Quítesela y a los morrales!"
	add_child(_hint)
	for n in SFX:
		var a := AudioStreamPlayer.new()
		a.stream = load("res://assets/audio/%s/%s.wav" % [SFX[n][0], n])
		a.volume_db = SFX[n][1]
		a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(a)
		_sfx[n] = a


func _sound(n: String, pitch := 1.0) -> void:
	var a: AudioStreamPlayer = _sfx.get(n)
	if a != null:
		a.pitch_scale = pitch
		a.play()


func _process(delta: float) -> void:
	_t += delta
	for d in _dust:
		d["life"] -= delta
		d["p"] += Vector2(0, -6) * delta
	_dust = _dust.filter(func(d): return d["life"] > 0.0)
	if _state == "chase":
		_chase(delta)
	elif _state == "pile":
		_pile(delta)
	_place()
	_field.queue_redraw()
	_over.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _state == "chase" and event.is_action_pressed("sniff") and _bar >= FULL:
		get_viewport().set_input_as_handled()
		_bar = 0
		_rush = 1.4
		_sound("carga", 1.2)
		_hint.text = "¡PIQUE!"


func _chase(delta: float) -> void:
	# Él: con las flechas o la palanca (con el pique, como un rayo).
	_rush = maxf(0.0, _rush - delta)
	_move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := HIM_SPEED * (1.9 if _rush > 0.0 else 1.0)
	_him.position = (_him.position + _move * speed * delta).clamp(FIELD.position, FIELD.end)
	_animate(_him, _move, "walk_", "idle_")
	if _rush > 0.0 and _move.length() > 0.1 and fmod(_t, 0.06) < delta:
		_dust.append({"p": _him.position + Vector2(randf_range(-3, 3), 2), "life": 0.4})
	# La barra del pique: se llena sola, de a poquito.
	_bar_t += delta
	if _bar_t > 5.0:
		_bar_t = 0.0
		_fill()
	_kick_cool = maxf(0.0, _kick_cool - delta)
	# Tocar la pelota es pegarle: hacia donde va corriendo, o al arco si está quieto.
	if _kick_cool <= 0.0 and _him.position.distance_to(_ball) < 8.0 and _bz < 4.0:
		var aim := _move.normalized() if _move.length() > 0.2 else (Vector2((GOAL_L + GOAL_R) * 0.5, GOAL_Y - 6) - _ball).normalized()
		var fire := _rush > 0.0
		_bv = aim * (FIRE_KICK if fire else KICK)
		_bvz = 70.0 if not fire else 40.0
		_fire_on = fire
		_fire.clear()
		_kick_cool = 0.3
		_dog_stun = 0.35
		_sound("fuego" if fire else "patada", randf_range(0.95, 1.08))
		_fill()
		for k in 4:
			_dust.append({"p": _ball + Vector2(randf_range(-3, 3), 2), "life": 0.4})
	_dog_step(delta)
	_kids_step(delta)
	_ball_step(delta)
	if _state == "chase" and _t > TIME:
		_caught = false
		_end_chase("(Lukas se queda con ella. La trae cuando él quiere.)")


## Lukas: va a la pelota y la empuja con el hocico, lejos de él (dando vueltas por el lote). Cuando lo
## tienen cerca, el quiebre: se la lleva para un lado.
func _dog_step(delta: float) -> void:
	var tired := clampf(_t / TIME, 0.0, 1.0)
	var speed := lerpf(DOG_SPEED, HIM_SPEED * 0.82, tired)
	_dog_stun = maxf(0.0, _dog_stun - delta)
	_juke = maxf(0.0, _juke - delta)
	var to_ball := _ball - _dog_pos
	var away := (_ball - _him.position)
	var want := away.normalized() * 1.2 + Vector2(sin(_t * 1.3), cos(_t * 0.9)) * 0.8
	if not FIELD.grow(-24).has_point(_ball):  # contra el muro o la orilla: que vuelva al medio
		want += (FIELD.get_center() - _ball).normalized() * 1.6
	if _dog_stun <= 0.0:
		if to_ball.length() > 7.0:
			_dog_v = _dog_v.lerp(to_ball.normalized(), minf(1.0, delta * 6.0))
		else:  # la tiene: la empuja
			var push := want.normalized()
			if away.length() < 26.0 and _juke <= 0.0:  # el quiebre
				_juke = 1.0
				push = away.normalized().rotated(PI / 2.0 * (1.0 if randf() < 0.5 else -1.0))
				for k in 6:
					_dust.append({"p": _dog_pos + Vector2(randf_range(-4, 4), 2), "life": 0.5})
			if _bz < 3.0:
				_bv = _bv.lerp(push * speed * 1.12, 0.35)
			_dog_v = _dog_v.lerp(push, minf(1.0, delta * 5.0))
	_dog_pos = (_dog_pos + _dog_v.normalized() * speed * (0.5 if _dog_stun > 0.0 else 1.0) * delta).clamp(FIELD.position, FIELD.end)
	_animate_dog(_dog_v)


## Los pelados: detrás de la pelota, cada uno por su lado; si la alcanzan, le pegan para cualquier lado.
func _kids_step(delta: float) -> void:
	for k in _kids.size():
		var kid: Dictionary = _kids[k]
		kid["cool"] = maxf(0.0, float(kid["cool"]) - delta)
		var target: Vector2 = _ball + (kid["off"] as Vector2).rotated(sin(_t * 0.7 + k) * 0.6)
		var to: Vector2 = target - kid["pos"]
		var v := to.normalized() * float(kid["speed"]) if to.length() > 3.0 else Vector2.ZERO
		kid["pos"] = (kid["pos"] + v * delta).clamp(FIELD.position, FIELD.end)
		_animate(kid["spr"], v, "walk_", "idle_")
		if float(kid["cool"]) <= 0.0 and (kid["pos"] as Vector2).distance_to(_ball) < 6.0 and _bz < 3.0 and not _fire_on:
			kid["cool"] = 1.2
			_bv = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(70.0, 110.0)
			_bvz = 40.0
			_sound("patada", randf_range(1.1, 1.25))


## La pelota: rueda (el pasto la frena), brinca, rebota en el muro y en las orillas. Entre los morrales,
## gol.
func _ball_step(delta: float) -> void:
	var before := _ball
	_ball += _bv * delta
	_bv *= pow(0.35 if _bz <= 0.0 else 0.8, delta)
	_bvz -= 260.0 * delta
	_bz += _bvz * delta
	if _bz <= 0.0:
		_bz = 0.0
		_bvz = -_bvz * 0.45 if absf(_bvz) > 25.0 else 0.0
	if _fire_on:
		_fire.push_front(_ball - Vector2(0, _bz))
		if _fire.size() > 8:
			_fire.pop_back()
		if _bv.length() < 60.0:
			_fire_on = false
	elif not _fire.is_empty():
		_fire.pop_back()
	# Gol: cruzó la raya hacia arriba, entre los morrales.
	if before.y >= GOAL_Y and _ball.y < GOAL_Y and _ball.x > GOAL_L and _ball.x < GOAL_R:
		_caught = true
		_sound("red")
		var lukas := _dog_pos.distance_to(before) < 10.0 and _him.position.distance_to(before) > 14.0
		_end_chase("¡Gol de Lukas! Cuenta para los dos." if lukas else "¡GOL! Lukas lo mira ofendido.")
		return
	# Los morrales: la pelota rebota en ellos.
	for mx in [GOAL_L - 4.5, GOAL_R + 4.5]:
		if absf(_ball.x - mx) < 5.5 and _ball.y > 70.0 and _ball.y < 82.0:
			_bv.x = signf(_ball.x - mx) * absf(_bv.x) * 0.6
	# El muro y las orillas.
	if _ball.x < FIELD.position.x or _ball.x > FIELD.end.x:
		_bv.x = -_bv.x * 0.6
		_ball.x = clampf(_ball.x, FIELD.position.x, FIELD.end.x)
	if _ball.y < FIELD.position.y or _ball.y > FIELD.end.y:
		_bv.y = -_bv.y * 0.6
		_ball.y = clampf(_ball.y, FIELD.position.y, FIELD.end.y)


func _fill() -> void:
	if _bar >= FULL:
		return
	_bar += 1
	if _bar >= FULL:
		_sound("carga")
		_hint.text = Controls.keys_in("F: ¡PIQUE!")


## Se acabó: se tiran todos al pasto. Lukas, panza arriba, con la pelota encima.
func _end_chase(text: String) -> void:
	_state = "pile"
	_t = 0.0
	_hint.text = text
	_dog.play("lie")
	_fire.clear()
	_fire_on = false
	var spot := _dog_pos
	for k in _kids.size():
		var kid: Dictionary = _kids[k]
		var from: Vector2 = kid["pos"]
		create_tween().tween_method(func(v: Vector2) -> void: kid["pos"] = v, from,
			spot + Vector2(-18 + k * 14, -6 + (k % 2) * 12), 0.5)
	var h := create_tween()
	h.tween_property(_him, "position", spot + Vector2(10, 8), 0.4)
	h.tween_callback(func() -> void: _him.play("sit_down"))


func _pile(_delta: float) -> void:
	for kid in _kids:
		kid["spr"].play("idle_down")
	if _t > 3.0 and _state == "pile":
		_state = "closed"
		GameState.ui_open = false
		GameState.block_input(0.3)
		_done.emit(_caught)


func _animate(spr: AnimatedSprite2D, v: Vector2, walk: String, idle: String) -> void:
	if v.length() < 0.1:
		var a := spr.animation
		spr.play(idle + (a.trim_prefix("walk_").trim_prefix("idle_") if a.begins_with("walk_") or a.begins_with("idle_") else "down"))
		return
	if absf(v.x) > absf(v.y):
		spr.flip_h = v.x > 0
		spr.play(walk + "side")
	else:
		spr.play(walk + ("down" if v.y > 0 else "up"))


func _animate_dog(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		_dog.flip_h = v.x > 0  # la hoja mira a la izquierda
		_dog.play("run_side")
	else:
		_dog.play("run_down" if v.y > 0 else "run_up")


func _place() -> void:
	_dog.position = _dog_pos + Vector2(0, -7)
	for kid in _kids:
		var hop := absf(sin(_t * 9.0 + kid["speed"])) * 2.0 if _state == "chase" else 0.0
		kid["spr"].position = kid["pos"] + Vector2(0, -12 - hop)


func _exit_tree() -> void:
	Controls.minigame = false


func _draw_field() -> void:
	var f := _field
	var p := PANEL
	f.draw_rect(p, Color(0.13, 0.22, 0.13))
	for k in 7:  # el pasto, a franjas (lo que queda)
		if k % 2 == 0:
			f.draw_rect(Rect2(p.position.x, 52 + k * 21, p.size.x, 21), Color(0.15, 0.25, 0.14))
	for k in 9:  # los peladeros
		var h := hash(k * 7)
		f.draw_rect(Rect2(p.position.x + 10 + h % 290, 80 + (h / 7) % 80, 9 + h % 6, 3), Color(0.3, 0.26, 0.17, 0.7))
	f.draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 18), Color(0.3, 0.2, 0.18))  # el muro
	for k in 17:
		f.draw_rect(Rect2(p.position.x + k * 20, p.position.y + (9 if k % 2 == 0 else 0), 1, 9), Color(0.2, 0.13, 0.12))
	f.draw_rect(Rect2(p.position.x, p.position.y + 9, p.size.x, 1), Color(0.2, 0.13, 0.12))
	# El arco: los dos morrales, y la raya de cal entre ellos.
	f.draw_rect(Rect2(GOAL_L, GOAL_Y, GOAL_R - GOAL_L, 1), Color(0.85, 0.85, 0.8, 0.45))
	f.draw_rect(Rect2(GOAL_L - 9, 72, 9, 8), Color(0.75, 0.25, 0.25))
	f.draw_rect(Rect2(GOAL_R, 72, 9, 8), Color(0.25, 0.4, 0.75))
	# El tiempo: una raya que se acaba (arriba, en el muro). Y la barra del pique, debajo.
	if _state == "chase":
		var left := 1.0 - clampf(_t / TIME, 0.0, 1.0)
		f.draw_rect(Rect2(p.position.x + 8, p.position.y + 13, (p.size.x - 16) * left, 2), Color(1, 0.85, 0.4))
		var lit: bool = _bar >= FULL and fmod(_t * 4.0, 1.0) < 0.5
		for k in FULL:
			var r := Rect2(16 + k * 12, 64, 10, 3)
			f.draw_rect(r.grow(1), Color(0.05, 0.05, 0.05))
			if k < _bar:
				f.draw_rect(r, Color(0.6, 0.95, 1.0) if lit else Color(0.35, 0.7, 0.95))


func _draw_over() -> void:
	var n := _over
	for d in _dust:
		n.draw_circle(d["p"], 1.5 + (0.5 - float(d["life"])) * 3.0, Color(0.6, 0.55, 0.45, float(d["life"])))
	var m := _fire.size()
	for k in range(m - 1, 0, -1):  # el patadón con fuego
		var u := float(k) / m
		n.draw_circle(_fire[k], 3.0 * (1.0 - u) + 0.6, Color(Color(1.0, 0.75, 0.2).lerp(Color(0.9, 0.15, 0.1), u), 0.85 * (1.0 - u)))
	if _rush > 0.0:  # el pique: el rayo alrededor de él
		n.draw_circle(_him.position + Vector2(0, -8), 9.0, Color(0.6, 0.95, 1.0, 0.18 + 0.12 * sin(_t * 30.0)))
	# La pelota: con su sombra (brinca); al final, encima de Lukas.
	var ball := _ball - Vector2(0, _bz)
	if _state != "chase":
		ball = _dog_pos + Vector2(0, -10)
	else:
		n.draw_circle(_ball + Vector2(0, 2), 2.3, Color(0, 0, 0, 0.3))
	n.draw_circle(ball, 2.5, Color(0.95, 0.95, 0.92))
	n.draw_circle(ball + Vector2(cos(_t * 14.0), sin(_t * 14.0)) * 1.3, 0.9, Color(0.25, 0.25, 0.25))
	if _state == "pile":  # risas: los pelados se ríen panza arriba (sin letras: las rayitas)
		for kid in _kids:
			var at: Vector2 = kid["pos"] + Vector2(4, -26)
			if fmod(_t * 4.0 + kid["speed"], 1.0) < 0.6:
				n.draw_line(at, at + Vector2(3, -2), Color(1, 1, 1, 0.8))
				n.draw_line(at + Vector2(1, 2), at + Vector2(4, 1), Color(1, 1, 1, 0.8))
