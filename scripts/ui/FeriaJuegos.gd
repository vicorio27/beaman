class_name FeriaJuegos
extends CanvasLayer
## Los juegos de la feria (scripts/world/Feria.gd). Cada uno es una pantalla que se abre encima, se
## juega y devuelve cómo le fue. El dibujo es de tools/art/draw_feria_juegos.py (assets/feria/).
##   await FeriaJuegos.play(self, "chocones")  -> choques (30 segundos manejando un carrito; los otros
##                                                manejan solos y el niño de la cachucha lo persigue)
##   "carrusel"  -> sortijas (cuando su caballito pasa por el brazo de la sortija, [E] la agarra; Lukas
##                  le ladra cada vez que pasa)
##   "montana"   -> veces que levantó las manos ([E] en las bajadas)
##   "dardos"    -> globos reventados (3 dardos; la mira se mueve sola)
##   "garra"     -> 1 si sacó peluche (la garra va y viene; [E] la deja caer; a veces se le resbala)
##   "rueda"     -> 0 (sube; arriba, el recuerdo de una fiesta: aguardiente al ritmo y un cigarrillo
##                  aguantando el humo. Y baja.)

signal _done(result: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const ART := "res://assets/feria/%s.png"
const SFX := "res://assets/audio/cuerpo/%s.wav"

var game := ""
var _t := 0.0
var _canvas: Control
var _label: Label
var _result := 0
var _state := {}
var _tex := {}
var _meta: Dictionary = {}
var _shake := 0.0
var _sfx: Array[AudioStreamPlayer] = []
var _motor: AudioStreamPlayer


static func play(parent: Node, which: String) -> int:
	var ui := FeriaJuegos.new()
	ui.game = which
	parent.get_tree().root.add_child(ui)
	var r: int = await ui._done
	ui.queue_free()
	return r


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_meta = (load("res://assets/feria/feria.json") as JSON).data
	_canvas = Control.new()
	_canvas.size = Vector2(320, 180)
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_draw)
	add_child(_canvas)
	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.position = Vector2(8, 4)
	_label.size = Vector2(Controls.right_edge() - 12, 12)
	add_child(_label)
	for k in 3:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_sfx.append(p)
	match game:
		"chocones":
			_state = {"pos": Vector2(160, 110), "ang": 0.0, "v": 0.0, "time": 30.0, "cars": [], "pums": []}
			var names := ["azul", "amarillo", "verde", "morado"]
			for i in 4:
				_state["cars"].append({"pos": Vector2(60 + i * 64, 50 + (i % 2) * 80), "ang": randf() * TAU, "v": 40.0,
					"hit": 0.0, "name": names[i], "goal": Vector2(randf_range(40, 280), randf_range(40, 150))})
		"carrusel":
			_state = {"time": 16.0, "barks": 0, "ring": true, "ring_back": 0.0, "miss": 0.0, "got_flash": 0.0}
		"montana":
			_state = {"x": 0.0, "v": 28.0, "hands": false, "count": 0, "clack": 0.0}
		"dardos":
			_state = {"darts": 3, "balloons": [], "flying": -1.0, "stuck": [], "pops": []}
			for i in 9:
				_state["balloons"].append({"pos": Vector2(104 + (i % 3) * 50, 60 + (i / 3) * 26), "alive": true, "col": i % 6})
		"garra":
			_state = {"x": 160.0, "dir": 1.0, "phase": "mueve", "y": 44.0, "prizes": [["oso", 112.0], ["conejo", 152.0], ["beagle", 196.0], ["unicornio", 236.0]],
				"held": "", "won": false, "slip_at": -1.0, "drop_x": 0.0, "fall": []}
			_motor = AudioStreamPlayer.new()
			var m: AudioStreamWAV = load(SFX % "feria_motor")
			m.loop_mode = AudioStreamWAV.LOOP_FORWARD
			m.loop_end = int(m.get_length() * m.mix_rate)
			_motor.stream = m
			_motor.volume_db = -16.0
			add_child(_motor)
	if game == "rueda":
		_rueda()


func _img(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = Calvicie.tex(ART % name)  # (las que lo tienen a él: según el día, con menos pelo)
	return _tex[name]


func _play_sfx(name: String, db := -6.0) -> void:
	var path := SFX % name if ResourceLoader.exists(SFX % name) else "res://assets/audio/%s.wav" % name
	for p in _sfx:
		if not p.playing:
			p.stream = load(path)
			p.volume_db = db
			p.play()
			return


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta * 6.0)
	_canvas.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 3.0
	_canvas.queue_redraw()
	match game:
		"chocones":
			_chocones(delta)
		"carrusel":
			_carrusel(delta)
		"montana":
			_montana(delta)
		"dardos":
			_dardos(delta)
		"garra":
			_garra(delta)


func _finish(r: int) -> void:
	if not is_processing():
		return
	set_process(false)
	if _motor:
		_motor.stop()
	GameState.ui_open = false
	GameState.block_input(0.3)
	_done.emit(r)


# ---------------------------------------------------------------- Los chocones

const ARENA := Rect2(26, 30, 268, 132)  # por donde andan los centros de los carros


func _chocones(delta: float) -> void:
	var s := _state
	s["time"] -= delta
	_label.text = "CHOCONES  %ds   CHOQUES: %d" % [maxi(0, ceili(s["time"])), _result]
	if Input.is_action_pressed("move_left"):
		s["ang"] -= 3.2 * delta
	if Input.is_action_pressed("move_right"):
		s["ang"] += 3.2 * delta
	var accel := 0.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("interact"):
		accel = 150.0
	elif Input.is_action_pressed("move_down"):
		accel = -90.0
	s["v"] = clampf(s["v"] + accel * delta - s["v"] * 1.4 * delta, -50.0, 95.0)
	s["pos"] = _drive(s["pos"], s, delta)
	for c in s["cars"]:
		c["hit"] -= delta
		# Manejan solos: van a un punto y cambian; el niño de la cachucha (el azul) lo persigue a él.
		var goal: Vector2 = s["pos"] if c["name"] == "azul" and fmod(_t, 9.0) < 5.0 else c["goal"]
		if c["pos"].distance_to(c["goal"]) < 16.0 or randf() < 0.004:
			c["goal"] = Vector2(randf_range(ARENA.position.x, ARENA.end.x), randf_range(ARENA.position.y, ARENA.end.y))
		var want: float = (goal - c["pos"]).angle()
		c["ang"] = rotate_toward(c["ang"], want, 2.2 * delta)
		c["v"] = move_toward(c["v"], 62.0 if c["hit"] < 0.3 else 10.0, 60.0 * delta)
		c["pos"] = _drive(c["pos"], c, delta)
	# Los choques: él contra ellos, y ellos entre ellos.
	var all: Array = [s] + s["cars"]
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: Dictionary = all[i]
			var b: Dictionary = all[j]
			var d: Vector2 = b["pos"] - a["pos"]
			if d.length() < 17.0 and d.length() > 0.01:
				var n := d.normalized()
				var push := (17.0 - d.length()) * 0.5
				a["pos"] -= n * push
				b["pos"] += n * push
				var hard: float = absf(a["v"]) + absf(b["v"])
				if hard > 50.0:
					_pum((a["pos"] + b["pos"]) * 0.5, hard)
					if i == 0 and float(b["hit"]) <= 0.0 and absf(s["v"]) > 25.0:
						_result += 1
					b["hit"] = 0.6
				var va: float = a["v"]
				a["v"] = -absf(b["v"]) * 0.45 if i == 0 else -40.0
				b["v"] = -absf(va) * 0.5
				b["ang"] = n.angle() + randf_range(-0.4, 0.4)
	var keep: Array = []
	for p in s["pums"]:
		p["t"] -= delta
		if p["t"] > 0.0:
			keep.append(p)
	s["pums"] = keep
	if s["time"] <= 0.0:
		_finish(_result)


func _drive(pos: Vector2, car: Dictionary, delta: float) -> Vector2:
	var p: Vector2 = pos + Vector2.from_angle(car["ang"]) * car["v"] * delta
	if p.x < ARENA.position.x or p.x > ARENA.end.x or p.y < ARENA.position.y or p.y > ARENA.end.y:
		car["v"] *= -0.5  # el caucho de la baranda
		if absf(car["v"]) > 25.0:
			_pum(p.clamp(ARENA.position, ARENA.end), absf(car["v"]) * 0.6)
	return p.clamp(ARENA.position, ARENA.end)


func _pum(at: Vector2, hard: float) -> void:
	if _state["pums"].size() > 4:
		return
	_state["pums"].append({"pos": at, "t": 0.25})
	_shake = minf(1.0, _shake + hard / 160.0)
	_play_sfx("feria_pum", -4.0)


func _draw_chocones(c: Control) -> void:
	c.draw_texture(_img("chocones_pista"), Vector2.ZERO)
	var i := 0
	for b in _meta["chocones"]["bombillos"]:  # los bombillos, en carrerita
		var on := (i + int(_t * 8.0)) % 4 != 0
		var col: Color = [Color(1, 0.4, 0.4), Color(1, 0.85, 0.4), Color(0.5, 0.85, 1), Color(0.6, 1, 0.6)][i % 4]
		c.draw_rect(Rect2(b[0] - 1, b[1] - 1, 2, 2), col if on else col.darkened(0.7))
		i += 1
	for car in _state["cars"]:
		_draw_car(c, car["pos"], car["ang"], "chocon_" + car["name"], car["hit"] > 0.3)
	_draw_car(c, _state["pos"], _state["ang"], "chocon_rojo", false)
	for p in _state["pums"]:
		var k: float = 1.0 + (0.25 - float(p["t"])) * 3.0
		c.draw_set_transform(p["pos"], 0.0, Vector2(k, k))
		c.draw_texture(_img("chocon_pum"), Vector2(-7, -7))
		c.draw_set_transform(Vector2.ZERO)


func _draw_car(c: Control, pos: Vector2, ang: float, tex: String, flash: bool) -> void:
	c.draw_set_transform(pos, ang)
	c.draw_texture(_img(tex), Vector2(-13, -10), Color(1.6, 1.6, 1.6) if flash else Color.WHITE)
	c.draw_set_transform(Vector2.ZERO)
	if randf() < 0.18:  # la chispa de la vara contra la malla del techo
		var tip := pos - Vector2.from_angle(ang) * 9.0
		c.draw_rect(Rect2(tip + Vector2(randf_range(-2, 2), randf_range(-2, 2)), Vector2(1, 1)), Color(0.75, 0.9, 1.0))


# ---------------------------------------------------------------- El carrusel (y la sortija)

const C_CENTER := Vector2(160, 104)
const C_RADIUS := 96.0
const C_SPEED := 1.25
const HORSES := ["dorado_el", "blanco_nino", "negro_nadie", "gris_nino", "blanco_nadie", "dorado_nino", "gris_nadie", "negro_nino"]
const RING_AT := Vector2(264, 70)


func _horse_angle(i: int) -> float:
	return _t * C_SPEED + i * TAU / HORSES.size() - PI * 0.5


func _horse_pos(i: int) -> Vector2:
	var a := _horse_angle(i)
	var bob := sin(_t * 3.0 + i * 1.7) * 4.0
	return Vector2(C_CENTER.x + cos(a) * C_RADIUS, C_CENTER.y + sin(a) * 8.0 + bob)


func _carrusel(delta: float) -> void:
	var s := _state
	s["time"] -= delta
	s["miss"] = maxf(0.0, s["miss"] - delta)
	s["got_flash"] = maxf(0.0, s["got_flash"] - delta)
	_label.text = "CARRUSEL   [E] LA SORTIJA: %d" % _result
	if not s["ring"]:
		s["ring_back"] -= delta
		if s["ring_back"] <= 0.0:
			s["ring"] = true
	if Input.is_action_just_pressed("interact"):
		var hand := _horse_pos(0) + Vector2(2, -26)
		if s["ring"] and hand.distance_to(RING_AT) < 14.0 and sin(_horse_angle(0)) > -0.2:
			_result += 1
			s["ring"] = false
			s["ring_back"] = 2.0
			s["got_flash"] = 0.6
			_play_sfx("feria_campanita", -4.0)
		else:
			s["miss"] = 0.4
	# Lukas ladra cada vez que él pasa por delante.
	if GameState.lukas_alive() and sin(_horse_angle(0)) > 0.9 and not s.get("barked", false):
		s["barked"] = true
		s["barks"] += 1
	elif sin(_horse_angle(0)) < 0.5:
		s["barked"] = false
	if s["time"] <= 0.0:
		_finish(_result)


func _draw_carrusel(c: Control) -> void:
	c.draw_texture(_img("carrusel_fondo"), Vector2.ZERO)
	var base := _img("carrusel_base")
	c.draw_texture(base, Vector2(C_CENTER.x - base.get_width() / 2.0, 118))
	var order := range(HORSES.size())
	order.sort_custom(func(a, b): return sin(_horse_angle(a)) < sin(_horse_angle(b)))
	var col := _img("carrusel_columna")
	var drew_col := false
	for i in order:
		var front := sin(_horse_angle(i)) > 0.0
		if front and not drew_col:
			c.draw_texture(col, Vector2(C_CENTER.x - col.get_width() / 2.0, 40))
			drew_col = true
		_draw_horse(c, i, front)
	if not drew_col:
		c.draw_texture(col, Vector2(C_CENTER.x - col.get_width() / 2.0, 40))
	var roof := _img("carrusel_techo")
	c.draw_texture(roof, Vector2(C_CENTER.x - roof.get_width() / 2.0, 8))
	for k in 34:  # los bombillos de la cenefa, en carrerita
		var x := C_CENTER.x - 116 + k * 7
		var on := (k + int(_t * 10.0)) % 3 != 0
		c.draw_rect(Rect2(x, 60, 1, 1), Color(1, 0.92, 0.6) if on else Color(0.5, 0.4, 0.3))
	# El brazo de la sortija y el aro (si no lo han agarrado).
	c.draw_texture(_img("sortija_brazo"), Vector2(256, 50))
	if _state["ring"]:
		var sway := sin(_t * 2.0) * 1.0
		c.draw_line(Vector2(268, 61), RING_AT + Vector2(sway, -4), Color(0.6, 0.6, 0.65))
		c.draw_texture(_img("sortija"), RING_AT + Vector2(-4 + sway, -4))
	if _state["got_flash"] > 0.0:
		var h := _horse_pos(0) + Vector2(2, -30)
		c.draw_texture(_img("sortija"), h + Vector2(-4, -4))
		c.draw_string(FONT, h + Vector2(-20, -8), "¡LA SORTIJA!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.4))
	if GameState.lukas_alive():  # Lukas, abajo, ladrándole cada vez que pasa
		var lk := Lukas.cell(3, 0)
		var barking := sin(_horse_angle(0)) > 0.75
		c.draw_texture(lk, Vector2(150, 150 - (2 if barking and int(_t * 8.0) % 2 == 0 else 0)))
		if barking:
			c.draw_string(FONT, Vector2(170, 152), "¡GUAU!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))


func _draw_horse(c: Control, i: int, front: bool) -> void:
	var p := _horse_pos(i)
	var tex := _img("caballo_" + HORSES[i])
	var tint := Color.WHITE if front else Color(0.55, 0.5, 0.65)
	# El tubo de bronce, del techo al caballo, con su franja que gira.
	var top_y := 60.0
	for y in range(int(top_y), int(p.y) - 2, 2):
		var stripe := (y + int(_t * 20.0)) % 6 < 2
		c.draw_rect(Rect2(p.x + (0 if front else 0), y, 2, 2), (Color(1, 0.92, 0.6) if stripe else Color(0.86, 0.68, 0.28)) * tint)
	var dir_right := cos(_horse_angle(i) + PI * 0.5) > 0.0  # para dónde va: adelante a la derecha, atrás a la izquierda
	var at := p - Vector2(tex.get_width() / 2.0, tex.get_height() - 6.0)
	if dir_right:
		c.draw_texture(tex, at, tint)
	else:
		c.draw_texture_rect(tex, Rect2(at + Vector2(tex.get_width(), 0), Vector2(-tex.get_width(), tex.get_height())), false, tint)


# ---------------------------------------------------------------- La montaña rusa

func _track_y(x: float) -> float:
	if x < 160.0:  # la subida de la cadena, al principio: empalma con la pista
		return lerpf(150.0, _ride_y(160.0), x / 160.0)
	return _ride_y(x)


func _ride_y(x: float) -> float:
	return 120.0 - 70.0 * absf(sin(x * 0.012)) * (0.6 + 0.4 * sin(x * 0.004))


func _montana(delta: float) -> void:
	var s := _state
	var slope := (_track_y(s["x"] + 2.0) - _track_y(s["x"])) / 2.0
	if s["x"] < 160.0:
		s["v"] = 28.0  # la cadena lo sube despacio: clac, clac, clac
		s["clack"] -= delta
		if s["clack"] <= 0.0:
			s["clack"] = 1.0
			_play_sfx("feria_carraca", -10.0)
	else:
		s["v"] = clampf(s["v"] + slope * 160.0 * delta, 25.0, 175.0)
	s["x"] += s["v"] * delta
	var hands_now: bool = Input.is_action_pressed("interact")
	if hands_now and not s["hands"] and slope > 0.3:
		s["count"] += 1
	s["hands"] = hands_now
	if slope > 0.6 and s["v"] > 120.0:
		_shake = maxf(_shake, 0.35)
	_label.text = "MONTAÑA RUSA   [E] MANOS ARRIBA: %d" % s["count"]
	if s["x"] > 1500.0:
		_finish(s["count"])


func _draw_montana(c: Control) -> void:
	var x: float = _state["x"]
	var sky := _img("montana_cielo")
	var off := fmod(x * 0.05, 640.0)
	c.draw_texture(sky, Vector2(-off, 0))
	c.draw_texture(sky, Vector2(640 - off, 0))
	var far := _img("montana_barrio")
	var off2 := fmod(x * 0.25, 640.0)
	c.draw_texture(far, Vector2(-off2, 92))
	c.draw_texture(far, Vector2(640 - off2, 92))
	c.draw_rect(Rect2(0, 170, 320, 10), Color(0.12, 0.1, 0.12))  # el piso de la feria
	for k in 40:
		var bx := fposmod(k * 23.0 - x * 0.9, 330.0) - 5
		c.draw_rect(Rect2(bx, 171, 1, 1), [Color(1, 0.4, 0.4), Color(1, 0.85, 0.4), Color(0.5, 0.85, 1)][k % 3])
	var x0 := x - 120.0
	# Los soportes de madera: postes cada 14 y las crucetas.
	var first := ceilf(x0 / 14.0) * 14.0
	var prev := Vector2(-1, -1)
	var wx := first
	while wx < x0 + 340.0:
		var sx := wx - x0
		var ty := _track_y(wx) + 3.0
		c.draw_line(Vector2(sx, ty), Vector2(sx, 172), Color(0.42, 0.28, 0.18), 2.0)
		c.draw_line(Vector2(sx + 1, ty), Vector2(sx + 1, 172), Color(0.56, 0.4, 0.26), 1.0)
		if prev.x >= 0.0:
			c.draw_line(prev, Vector2(sx, 172), Color(0.36, 0.24, 0.16))
			c.draw_line(Vector2(prev.x, 172), Vector2(sx, maxf(ty, prev.y)), Color(0.36, 0.24, 0.16))
		prev = Vector2(sx, ty)
		wx += 14.0
	# La carrilera: los durmientes y los dos rieles rojos.
	for sx in range(0, 322, 4):
		var ty := _track_y(x0 + sx)
		c.draw_line(Vector2(sx, ty), Vector2(sx, ty + 4), Color(0.25, 0.18, 0.14))
	var last := Vector2(-1, -1)
	for sx in range(0, 324, 2):
		var p := Vector2(sx, _track_y(x0 + sx))
		if last.x >= 0.0:
			c.draw_line(last, p, Color(0.9, 0.24, 0.26), 2.0)
			c.draw_line(last + Vector2(0, 4), p + Vector2(0, 4), Color(0.6, 0.14, 0.18), 1.0)
		last = p
	# El tren: dos vagones sobre la carrilera, inclinados con la pendiente.
	var hands: bool = _state["hands"]
	for car in [["vagon_atras", -34.0], ["vagon_adelante", 0.0]]:
		var cx: float = x + float(car[1])
		var p := Vector2(120.0 + float(car[1]), _track_y(cx))
		var ang := atan((_track_y(cx + 2.0) - _track_y(cx)) / 2.0)
		c.draw_set_transform(p, ang)
		c.draw_texture(_img(str(car[0]) + ("_manos" if hands else "")), Vector2(-18, -28))
		c.draw_set_transform(Vector2.ZERO)
	if _state["v"] > 125.0:  # rayas de velocidad
		for k in 6:
			var ly := 40.0 + fmod(k * 37.0 + _t * 50.0, 120.0)
			var lx := fposmod(-_t * 400.0 + k * 61.0, 360.0) - 20.0
			c.draw_line(Vector2(lx, ly), Vector2(lx + 18, ly), Color(1, 1, 1, 0.35))
	if hands and _state["v"] > 90.0:
		c.draw_string(FONT, Vector2(134, _track_y(x) - 34), "¡AAAH!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))


# ---------------------------------------------------------------- Los dardos

func _aim() -> Vector2:
	return Vector2(160 + sin(_t * 1.7) * 62.0 + sin(_t * 4.3) * 12.0, 84 + sin(_t * 2.3 + 1.0) * 30.0)


func _dardos(delta: float) -> void:
	var s := _state
	_label.text = "DARDOS   QUEDAN: %d   GLOBOS: %d" % [s["darts"], _result]
	var keep: Array = []
	for p in s["pops"]:
		p["t"] += delta
		if p["t"] < 0.3:
			keep.append(p)
	s["pops"] = keep
	if s["flying"] >= 0.0:
		s["flying"] -= delta
		if s["flying"] < 0.0:
			var at: Vector2 = s["at"]
			var popped := false
			for b in s["balloons"]:
				var bp: Vector2 = b["pos"] + Vector2(0, sin(_t * 2.0 + b["pos"].x) * 1.5)
				if b["alive"] and at.distance_to(bp + Vector2(0, 7)) < 9.0:
					b["alive"] = false
					_result += 1
					s["pops"].append({"pos": bp + Vector2(0, 7), "t": 0.0})
					_play_sfx("feria_pop", -2.0)
					popped = true
					break
			s["stuck"].append(at)
			if not popped:
				_play_sfx("click", -10.0)
			if s["darts"] <= 0:
				await get_tree().create_timer(0.7).timeout
				_finish(_result)
		return
	if Input.is_action_just_pressed("interact") and s["darts"] > 0:
		s["darts"] -= 1
		s["at"] = _aim()
		s["flying"] = 0.28


func _draw_dardos(c: Control) -> void:
	c.draw_texture(_img("dardos_puesto"), Vector2.ZERO)
	for k in 40:  # los bombillos del cable de arriba
		var x := k * 8 + 2
		var on := (k + int(_t * 6.0)) % 3 != 0
		c.draw_rect(Rect2(x, 16 + int(3 * sin(x / 40.0)), 2, 2), [Color(1, 0.45, 0.45), Color(1, 0.86, 0.4), Color(0.55, 0.85, 1)][k % 3] * (1.0 if on else 0.4))
	for st in _state["stuck"]:
		c.draw_texture(_img("dardo_clavado"), st - Vector2(2, 5))
	for b in _state["balloons"]:
		if b["alive"]:
			var bp: Vector2 = b["pos"] + Vector2(0, sin(_t * 2.0 + b["pos"].x) * 1.5)
			c.draw_texture(_img("globo_%d" % int(b["col"])), bp - Vector2(8, 0))
	for p in _state["pops"]:
		var f := mini(2, int(float(p["t"]) / 0.1))
		c.draw_texture(_img("globo_pop_%d" % f), p["pos"] - Vector2(11, 11))
	var a := _aim()
	if _state["darts"] > 0 or _state["flying"] >= 0.0:
		c.draw_arc(a, 6.0, 0, TAU, 14, Color(1, 0.3, 0.3), 1.0)
		c.draw_line(a + Vector2(-9, 0), a + Vector2(-3, 0), Color(1, 0.3, 0.3))
		c.draw_line(a + Vector2(3, 0), a + Vector2(9, 0), Color(1, 0.3, 0.3))
		c.draw_line(a + Vector2(0, -9), a + Vector2(0, -3), Color(1, 0.3, 0.3))
		c.draw_line(a + Vector2(0, 3), a + Vector2(0, 9), Color(1, 0.3, 0.3))
	if _state["flying"] >= 0.0:  # el dardo vuela hacia adentro: se achica
		var k: float = 1.0 - float(_state["flying"]) / 0.28
		var from := Vector2(150, 150)
		var to: Vector2 = _state["at"]
		var p := from.lerp(to, k) - Vector2(0, sin(k * PI) * 14.0)
		var sc := lerpf(2.2, 0.9, k)
		c.draw_set_transform(p, 0.0, Vector2(sc, sc))
		c.draw_texture(_img("dardo"), Vector2(-3, -3))
		c.draw_set_transform(Vector2.ZERO)
	elif _state["darts"] > 0:  # la mano con el dardo, abajo, siguiendo un poquito la mira
		c.draw_texture(_img("mano_dardo"), Vector2(140 + (a.x - 160) * 0.15, 148))


# ---------------------------------------------------------------- La garra

const CLAW_TOP := 44.0
const CLAW_DOWN := 96.0
const CHUTE_X := 66.0


func _garra(delta: float) -> void:
	var s := _state
	match s["phase"]:
		"mueve":
			_label.text = "LA GARRA   [E] SOLTAR"
			s["x"] += s["dir"] * 66.0 * delta
			if s["x"] > 258.0 or s["x"] < 96.0:
				s["dir"] *= -1.0
			if not _motor.playing:
				_motor.play()
			if Input.is_action_just_pressed("interact"):
				s["phase"] = "baja"
				_motor.stop()
		"baja":
			s["y"] = move_toward(s["y"], CLAW_DOWN, 70.0 * delta)
			if s["y"] >= CLAW_DOWN:
				s["phase"] = "cierra"
				s["t"] = 0.0
		"cierra":
			s["t"] += delta
			if s["t"] > 0.45:
				for pz in s["prizes"]:
					if absf(float(pz[1]) - s["x"]) < 9.0:
						s["held"] = pz[0]
						s["prizes"].erase(pz)
						# La garra de feria: floja por ley. A veces se resbala subiendo.
						s["slip_at"] = randf_range(60.0, 80.0) if randf() < 0.35 else -1.0
						break
				s["phase"] = "sube"
		"sube":
			s["y"] = move_toward(s["y"], CLAW_TOP, 55.0 * delta)
			if s["held"] != "" and s["slip_at"] > 0.0 and s["y"] <= s["slip_at"]:
				s["fall"].append({"kind": s["held"], "pos": Vector2(s["x"], s["y"] + 14.0), "v": 0.0, "home": 114.0})
				s["held"] = ""
				s["slip_at"] = -1.0
				_play_sfx("miss", -6.0)
				s["plop"] = 0.8
			if s["y"] <= CLAW_TOP:
				s["phase"] = "lleva" if s["held"] != "" else "fin"
				s["t"] = 0.0
				if s["held"] != "":
					_motor.play()
		"lleva":
			s["x"] = move_toward(s["x"], CHUTE_X, 60.0 * delta)
			if s["x"] <= CHUTE_X:
				_motor.stop()
				s["fall"].append({"kind": s["held"], "pos": Vector2(s["x"], s["y"] + 14.0), "v": 0.0, "home": 150.0})
				s["held"] = ""
				s["won"] = true
				s["phase"] = "fin"
				s["t"] = 0.0
		"fin":
			s["t"] = float(s.get("t", 0.0)) + delta
			if s["t"] > 1.6:
				_finish(1 if s["won"] else 0)
	s["plop"] = maxf(0.0, float(s.get("plop", 0.0)) - delta)
	for f in s["fall"]:
		f["v"] += 260.0 * delta
		f["pos"].y = minf(f["pos"].y + f["v"] * delta, f["home"])


func _draw_garra(c: Control) -> void:
	c.draw_texture(_img("garra_maquina"), Vector2.ZERO)
	for k in 39:  # los bombillos de la marquesina, en carrerita
		var on := (k + int(_t * 9.0)) % 4 != 0
		for yy in [19, 33]:
			c.draw_rect(Rect2(46 + k * 6, yy, 1, 1), Color(1, 0.94, 0.7) if on else Color(0.5, 0.3, 0.3))
	for pz in _state["prizes"]:
		c.draw_texture(_img("premio_" + pz[0]), Vector2(float(pz[1]) - 11, 104))
	for f in _state["fall"]:
		c.draw_texture(_img("premio_" + f["kind"]), f["pos"] - Vector2(11, 0))
	var x: float = _state["x"]
	var y: float = _state["y"]
	c.draw_line(Vector2(x, 36), Vector2(x, y), Color(0.75, 0.75, 0.8))
	c.draw_rect(Rect2(x - 6, 36, 12, 3), Color(0.55, 0.55, 0.6))  # el carrito de arriba
	var closed: bool = _state["phase"] in ["sube", "lleva"] or (_state["phase"] == "cierra" and float(_state.get("t", 0.0)) > 0.2)
	if _state["phase"] == "fin" and _state["won"]:
		closed = false
	if _state["held"] != "":
		c.draw_texture(_img("premio_" + _state["held"]), Vector2(x - 11, y + 12))
	c.draw_texture(_img("garra_cerrada" if closed else "garra_abierta"), Vector2(x - 11, y))
	c.draw_texture(_img("garra_vidrio"), Vector2.ZERO)
	if _state.get("plop", 0.0) > 0.0:
		c.draw_string(FONT, Vector2(x - 20, y - 4), "¡PLOP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))


# ---------------------------------------------------------------- La rueda de Chicago (y el recuerdo)

func _rueda() -> void:
	_state = {"rise": 0.0, "scene": "rueda"}
	_label.text = "RUEDA DE CHICAGO"
	await _go_up(4.0)
	await Dialogue.talk([["", "(Arriba. Se ve todo el barrio: el billar, el puente, el río, la calle donde duerme. De aquí arriba, todo cabe en una mano.)"],
		["", "(Abajo suena una cumbia. La misma. Una vez él también bailó esa.)"]])
	_state["scene"] = "fiesta"
	_label.text = "ANTES"
	MusicDirector.force("flashback")
	await Dialogue.talk([["", "(Antes. Una terraza con bombillos de colores, como estos. Una fiesta de diciembre.)"],
		["", "(Él, sin barba, con una camisa planchada. En una mano, un aguardiente. En la otra, un cigarrillo. Las dos cosas, en ese entonces, eran de adulto.)"],
		["UN AMIGO", "—¡Fondo blanco! ¡Fondo blanco! ¡Al ritmo, hermano, al ritmo!"]])
	var shots: int = await Ritmo.play(self, "Fondo blanco (al golpe del tambor)", 3,
		{"zone": 16.0, "speed": 90.0, "color": Color(0.95, 0.85, 0.5), "hit": "¡Adentro!", "miss": "Se le regó en la camisa."})
	_state["shots"] = shots
	await Dialogue.talk([["", ["(Se le riega todo. Los amigos aplauden igual: en diciembre se aplaude todo.)",
		"(Uno de tres. Hace cara de que quema. Quema.)", "(Dos de tres. Ya le brillan los ojos. Ya baila mejor de lo que baila.)",
		"(Los tres, sin respirar. Lo cargan en hombros. Es el rey de la terraza por una noche.)"][shots]]])
	_state["scene"] = "humo"
	_label.text = "CALADA: [E] MANTENER, SOLTAR EN VERDE"
	var puffs := 0
	for k in 3:
		puffs += 1 if await _puff() else 0
	_state["scene"] = "fiesta"
	await Dialogue.talk([["", ["(Tose las tres veces. Una señora le da agua y le dice que eso no es para él. Tenía razón. Él siguió igual.)",
		"(Tose. Se ríe. Se hace el que no tosió.)", "(El humo sale por la nariz, como en las películas. Se siente actor.)",
		"(Tres caladas perfectas. El humo le hace rueda. Se siente invencible. Era joven: era mentira.)"][puffs]]])
	MusicDirector.release()
	_state["scene"] = "rueda"
	_label.text = "RUEDA DE CHICAGO"
	await Dialogue.talk([["", "(La rueda se mueve y el recuerdo se va. Abajo, Lukas lo espera sentado, mirando para arriba.)" if GameState.lukas_alive()
		else "(La rueda se mueve y el recuerdo se va. Abajo no lo espera nadie.)"],
		["", "(Se baja con ganas de un trago y de un cigarrillo. No se toma el trago. Del cigarrillo, mejor no hablemos.)"]])
	await _go_up(-3.0)
	_finish(shots + puffs)


func _go_up(secs: float) -> void:
	var t := create_tween()
	t.tween_property(self, "_rise", 1.0 if secs > 0 else 0.0, absf(secs)).set_trans(Tween.TRANS_SINE)
	await t.finished


var _rise := 0.0
var _hold := 0.0


## Una calada: mantener [E] llena la barra; soltar en lo verde. Pasarse, tos.
func _puff() -> bool:
	_hold = 0.0
	while not Input.is_action_pressed("interact"):
		await get_tree().process_frame
	while Input.is_action_pressed("interact"):
		await get_tree().process_frame
		_hold += get_process_delta_time() * 0.6
		if _hold > 1.0:
			break
	var ok := _hold > 0.55 and _hold < 0.8
	_state["puff"] = 1.0 if ok else -1.0
	await get_tree().create_timer(0.7).timeout
	_state["puff"] = 0.0
	_hold = 0.0
	return ok


func _draw_rueda(c: Control) -> void:
	var scene: String = _state.get("scene", "rueda")
	if scene == "rueda":
		# El barrio de noche desde la cabina: subiendo se ve más arriba (el horizonte); la cabina se mece.
		var view := _img("rueda_barrio")
		var sway := sin(_t * 1.3) * 2.0
		c.draw_texture(view, Vector2(sway, -(view.get_height() - 180) * _rise))
		c.draw_texture(_img("rueda_cabina"), Vector2.ZERO)
		return
	# La fiesta de antes: la terraza, los bombillos en zigzag, la gente sin cara, él joven.
	c.draw_texture(_img("fiesta_terraza"), Vector2.ZERO)
	for k in 54:
		var x := k * 6.0
		var y := 24.0 + absf(fmod(x, 80.0) - 40.0) * 0.35
		c.draw_rect(Rect2(x, y, 1, 1), Color(0.3, 0.26, 0.3))
		if k % 2 == 0:
			var on := (k / 2 + int(_t * 3.0)) % 3 != 0
			c.draw_rect(Rect2(x, y + 1, 2, 2), Color.from_hsv(fmod(k * 0.13, 1.0), 0.6, 1.0) if on else Color(0.3, 0.3, 0.3))
	c.draw_texture(_img("fiesta_gente_%d" % (int(_t * 3.0) % 2)), Vector2(44, 82))
	var me := "joven_humo" if scene == "humo" else "joven_baila_%d" % (int(_t * 3.0) % 2)
	c.draw_texture(_img(me), Vector2(176, 94))
	if scene == "humo":
		# La barra de la calada: lo verde es la buena.
		c.draw_rect(Rect2(60, 150, 200, 8), Color(0.2, 0.2, 0.22))
		c.draw_rect(Rect2(60 + 200 * 0.55, 150, 200 * 0.25, 8), Color(0.3, 0.75, 0.35))
		c.draw_rect(Rect2(60 + 200 * 0.8, 150, 200 * 0.2, 8), Color(0.8, 0.25, 0.25))
		c.draw_rect(Rect2(60, 151, 200 * clampf(_hold, 0, 1), 6), Color(0.95, 0.95, 0.9, 0.85))
		var puff: float = _state.get("puff", 0.0)
		if puff > 0.0:
			for k in 4:
				c.draw_circle(Vector2(196 + k * 5, 98 - k * 9 - fmod(_t * 8.0, 9.0)), 3.0 + k, Color(0.85, 0.85, 0.9, 0.5))
		elif puff < 0.0:
			c.draw_string(FONT, Vector2(150, 84), "¡COF COF!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.6, 0.5))


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	var c := _canvas
	match game:
		"chocones":
			_draw_chocones(c)
		"carrusel":
			_draw_carrusel(c)
		"montana":
			_draw_montana(c)
		"dardos":
			_draw_dardos(c)
		"garra":
			_draw_garra(c)
		"rueda":
			_draw_rueda(c)
