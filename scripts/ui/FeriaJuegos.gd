class_name FeriaJuegos
extends CanvasLayer
## Los juegos de la feria (scripts/world/Feria.gd). Cada uno es una pantalla que se abre encima, se
## juega y devuelve cómo le fue:
##   await FeriaJuegos.play(self, "chocones")  -> choques (30 segundos manejando un carrito)
##   "carrusel"  -> 0 (una vuelta; Lukas le ladra cada vez que pasa)
##   "montana"   -> veces que levantó las manos ([E] en las bajadas)
##   "dardos"    -> globos reventados (3 dardos; la mira se mueve sola)
##   "garra"     -> 1 si sacó peluche (la garra va y viene; [E] la deja caer)
##   "rueda"     -> 0 (sube; arriba, el recuerdo de una fiesta: aguardiente al ritmo y un cigarrillo
##                  aguantando el humo. Y baja.)

signal _done(result: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

var game := ""
var _t := 0.0
var _canvas: Control
var _label: Label
var _result := 0
var _state := {}


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
	_canvas = Control.new()
	_canvas.size = Vector2(320, 180)
	_canvas.draw.connect(_draw)
	add_child(_canvas)
	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	_label.add_theme_constant_override("outline_size", 3)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.position = Vector2(8, 4)
	_label.size = Vector2(300, 12)
	add_child(_label)
	match game:
		"chocones":
			_state = {"pos": Vector2(160, 100), "ang": 0.0, "v": 0.0, "time": 30.0, "cars": [], "cd": 0.0}
			for i in 4:
				_state["cars"].append({"pos": Vector2(60 + i * 60, 60 + (i % 2) * 70), "vel": Vector2.from_angle(randf() * TAU) * 40.0, "hit": 0.0})
		"carrusel":
			_state = {"time": 9.0, "barks": 0}
		"montana":
			_state = {"x": 0.0, "v": 30.0, "hands": false, "count": 0}
		"dardos":
			_state = {"darts": 3, "balloons": [], "flying": -1.0}
			for i in 9:
				_state["balloons"].append({"pos": Vector2(110 + (i % 3) * 50, 50 + (i / 3) * 34), "alive": true, "col": Color.from_hsv(i * 0.11, 0.7, 0.95)})
		"garra":
			_state = {"x": 60.0, "dir": 1.0, "drop": -1.0, "prizes": [90.0, 150.0, 205.0, 250.0], "won": false}
	if game == "rueda":
		_rueda()


func _process(delta: float) -> void:
	_t += delta
	_canvas.queue_redraw()
	match game:
		"chocones":
			_chocones(delta)
		"carrusel":
			_state["time"] -= delta
			_label.text = "CARRUSEL"
			if int(_t * 2.0) % 3 == 0 and int((_t - delta) * 2.0) % 3 != 0:
				_state["barks"] += 1
			if _state["time"] <= 0.0:
				_finish(0)
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
	GameState.ui_open = false
	GameState.block_input(0.3)
	_done.emit(r)


# ---------------------------------------------------------------- Los chocones

func _chocones(delta: float) -> void:
	var s := _state
	s["time"] -= delta
	s["cd"] -= delta
	_label.text = "CHOCONES  %ds   CHOQUES: %d" % [maxi(0, ceili(s["time"])), _result]
	if Input.is_action_pressed("move_left"):
		s["ang"] -= 3.2 * delta
	if Input.is_action_pressed("move_right"):
		s["ang"] += 3.2 * delta
	var accel := 0.0
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("interact"):
		accel = 140.0
	elif Input.is_action_pressed("move_down"):
		accel = -90.0
	s["v"] = clampf(s["v"] + accel * delta - s["v"] * 1.4 * delta, -50.0, 90.0)
	var p: Vector2 = s["pos"] + Vector2.from_angle(s["ang"]) * s["v"] * delta
	if p.x < 26 or p.x > 294:
		s["v"] *= -0.5
	if p.y < 30 or p.y > 162:
		s["v"] *= -0.5
	s["pos"] = Vector2(clampf(p.x, 26, 294), clampf(p.y, 30, 162))
	for c in s["cars"]:
		c["pos"] += c["vel"] * delta
		c["hit"] -= delta
		if c["pos"].x < 26 or c["pos"].x > 294:
			c["vel"].x *= -1
		if c["pos"].y < 30 or c["pos"].y > 162:
			c["vel"].y *= -1
		c["pos"] = Vector2(clampf(c["pos"].x, 26, 294), clampf(c["pos"].y, 30, 162))
		var d: Vector2 = c["pos"] - s["pos"]
		if d.length() < 12.0:
			if absf(s["v"]) > 25.0 and c["hit"] <= 0.0:
				_result += 1
				c["hit"] = 0.8
			c["vel"] = d.normalized() * maxf(50.0, absf(s["v"]))
			s["v"] *= -0.4
			s["pos"] -= d.normalized() * 3.0
	if s["time"] <= 0.0:
		_finish(_result)


# ---------------------------------------------------------------- La montaña rusa

func _track_y(x: float) -> float:
	return 120.0 - 70.0 * absf(sin(x * 0.012)) * (0.6 + 0.4 * sin(x * 0.004))


func _montana(delta: float) -> void:
	var s := _state
	var slope := (_track_y(s["x"] + 2.0) - _track_y(s["x"])) / 2.0
	s["v"] = clampf(s["v"] + slope * 160.0 * delta, 25.0, 170.0)
	s["x"] += s["v"] * delta
	var hands_now: bool = Input.is_action_pressed("interact")
	if hands_now and not s["hands"] and slope > 0.3:
		s["count"] += 1
	s["hands"] = hands_now
	_label.text = "MONTAÑA RUSA   [E] MANOS ARRIBA: %d" % s["count"]
	if s["x"] > 1400.0:
		_finish(s["count"])


# ---------------------------------------------------------------- Los dardos

func _aim() -> Vector2:
	return Vector2(160 + sin(_t * 1.7) * 60.0 + sin(_t * 4.3) * 12.0, 84 + sin(_t * 2.3 + 1.0) * 34.0)


func _dardos(delta: float) -> void:
	var s := _state
	_label.text = "DARDOS   QUEDAN: %d   GLOBOS: %d" % [s["darts"], _result]
	if s["flying"] >= 0.0:
		s["flying"] -= delta
		if s["flying"] < 0.0:
			var at: Vector2 = s["at"]
			for b in s["balloons"]:
				if b["alive"] and at.distance_to(b["pos"]) < 9.0:
					b["alive"] = false
					_result += 1
					break
			if s["darts"] <= 0:
				await get_tree().create_timer(0.6).timeout
				_finish(_result)
		return
	if Input.is_action_just_pressed("interact") and s["darts"] > 0:
		s["darts"] -= 1
		s["at"] = _aim()
		s["flying"] = 0.25


# ---------------------------------------------------------------- La garra

func _garra(delta: float) -> void:
	var s := _state
	_label.text = "LA GARRA   [E] SOLTAR"
	if s["drop"] < 0.0:
		s["x"] += s["dir"] * 70.0 * delta
		if s["x"] > 270.0 or s["x"] < 50.0:
			s["dir"] *= -1.0
		if Input.is_action_just_pressed("interact"):
			s["drop"] = 0.0
		return
	s["drop"] += delta
	if s["drop"] > 0.9 and not s.has("tried"):
		s["tried"] = true
		for px in s["prizes"]:
			if absf(px - s["x"]) < 7.0:
				s["won"] = randf() < 0.65  # la garra de feria: floja por ley
				if not s["won"]:
					s["slip"] = px
				else:
					s["prizes"].erase(px)
				break
	if s["drop"] > 2.2:
		_finish(1 if s["won"] else 0)


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
	t.tween_property(self, "_rise", 1.0 if secs > 0 else 0.0, absf(secs))
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


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	var c := _canvas
	match game:
		"chocones":
			c.draw_rect(Rect2(0, 0, 320, 180), Color(0.08, 0.07, 0.12))
			c.draw_rect(Rect2(18, 22, 284, 148), Color(0.2, 0.2, 0.26))
			c.draw_rect(Rect2(18, 22, 284, 148), Color(0.95, 0.8, 0.3), false, 2.0)
			for car in _state["cars"]:
				var p: Vector2 = car["pos"]
				c.draw_rect(Rect2(p - Vector2(7, 5), Vector2(14, 10)), Color(1, 1, 1) if car["hit"] > 0.6 else Color.from_hsv(fmod(p.x * 0.003 + 0.1, 1.0), 0.7, 0.9))
				c.draw_line(p, Vector2(p.x, 22), Color(0.5, 0.5, 0.55))
			var me: Vector2 = _state["pos"]
			var f := Vector2.from_angle(_state["ang"])
			var side := f.orthogonal()
			var pts := PackedVector2Array([me + f * 9 + side * 5, me + f * 9 - side * 5, me - f * 7 - side * 6, me - f * 7 + side * 6])
			c.draw_colored_polygon(pts, Color(0.85, 0.15, 0.2))
			c.draw_circle(me, 3.0, Color(0.2, 0.18, 0.2))  # él, con el saco
			c.draw_line(me, Vector2(me.x, 22), Color(0.5, 0.5, 0.55))
			if int(_t * 8.0) % 4 == 0:
				c.draw_circle(Vector2(me.x, 22), 2.0, Color(0.7, 0.85, 1.0))
		"carrusel":
			c.draw_rect(Rect2(0, 0, 320, 180), Color(0.08, 0.06, 0.18))
			var cc := Vector2(160, 100)
			c.draw_colored_polygon(PackedVector2Array([cc + Vector2(-90, -40), cc + Vector2(0, -80), cc + Vector2(90, -40)]), Color(0.9, 0.3, 0.35))
			c.draw_rect(Rect2(cc + Vector2(-92, 20), Vector2(184, 14)), Color(0.55, 0.36, 0.24))
			for i in 8:
				var a := _t * 1.0 + i * TAU / 8.0
				var hp := cc + Vector2(cos(a) * 76.0, sin(a) * 14.0 + sin(_t * 3.0 + i) * 5.0)
				c.draw_line(Vector2(hp.x, cc.y - 40), hp, Color(0.95, 0.85, 0.5), 2.0)
				var mine := i == 0
				c.draw_rect(Rect2(hp - Vector2(10, 4), Vector2(20, 9)), Color(0.98, 0.96, 0.9) if not mine else Color(0.95, 0.75, 0.4))
				if mine:  # él, en el caballito: saco gris, corbata roja, las rodillas en las orejas
					c.draw_rect(Rect2(hp + Vector2(-3, -16), Vector2(7, 12)), Color(0.4, 0.42, 0.5))
					c.draw_rect(Rect2(hp + Vector2(0, -14), Vector2(1, 6)), Color(0.85, 0.2, 0.2))
					c.draw_circle(hp + Vector2(0, -19), 3.5, Color(0.2, 0.15, 0.15))
			if GameState.lukas_alive():  # Lukas, abajo, ladrándole cada vez que pasa
				c.draw_rect(Rect2(150, 150, 16, 8), Color(0.84, 0.54, 0.3))
				c.draw_rect(Rect2(162, 145, 7, 7), Color(0.84, 0.54, 0.3))
				if int(_t * 2.0) % 3 == 0:
					c.draw_string(FONT, Vector2(172, 146), "¡GUAU!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))
		"montana":
			c.draw_rect(Rect2(0, 0, 320, 180), Color(0.1, 0.08, 0.2))
			var x0: float = _state["x"] - 100.0
			var prev := Vector2.ZERO
			for sx in range(0, 330, 6):
				var p := Vector2(sx, _track_y(x0 + sx))
				if sx > 0:
					c.draw_line(prev, p, Color(0.9, 0.3, 0.3), 2.0)
				c.draw_line(p, Vector2(p.x, 180), Color(0.4, 0.4, 0.45), 1.0)
				prev = p
			var cart := Vector2(100, _track_y(_state["x"]))
			c.draw_rect(Rect2(cart + Vector2(-9, -8), Vector2(18, 8)), Color(0.95, 0.85, 0.3))
			c.draw_circle(cart + Vector2(-2, -12), 3.5, Color(0.2, 0.15, 0.15))
			if _state["hands"]:
				c.draw_line(cart + Vector2(-5, -12), cart + Vector2(-7, -22), Color(0.4, 0.42, 0.5), 2.0)
				c.draw_line(cart + Vector2(1, -12), cart + Vector2(3, -22), Color(0.4, 0.42, 0.5), 2.0)
				c.draw_string(FONT, cart + Vector2(10, -20), "¡AAAH!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))
		"dardos":
			c.draw_rect(Rect2(0, 0, 320, 180), Color(0.12, 0.1, 0.16))
			c.draw_rect(Rect2(86, 26, 148, 110), Color(0.3, 0.5, 0.75))
			for b in _state["balloons"]:
				if b["alive"]:
					c.draw_circle(b["pos"], 8.0, b["col"])
					c.draw_line(b["pos"] + Vector2(0, 8), b["pos"] + Vector2(0, 14), Color(0.9, 0.9, 0.9))
			var a := _aim()
			c.draw_arc(a, 6.0, 0, TAU, 12, Color(1, 0.3, 0.3), 1.0)
			c.draw_line(a + Vector2(-9, 0), a + Vector2(9, 0), Color(1, 0.3, 0.3))
			c.draw_line(a + Vector2(0, -9), a + Vector2(0, 9), Color(1, 0.3, 0.3))
			if _state["flying"] >= 0.0:
				var to: Vector2 = _state["at"]
				var k: float = 1.0 - float(_state["flying"]) / 0.25
				c.draw_line(Vector2(160, 178).lerp(to, k), Vector2(160, 178).lerp(to, k) + Vector2(0, 6), Color(0.95, 0.95, 0.9), 2.0)
		"garra":
			c.draw_rect(Rect2(0, 0, 320, 180), Color(0.12, 0.08, 0.14))
			c.draw_rect(Rect2(40, 22, 240, 140), Color(0.85, 0.2, 0.4))
			c.draw_rect(Rect2(48, 30, 224, 116), Color(0.7, 0.85, 0.95, 0.35))
			for px in _state["prizes"]:
				_bear(c, Vector2(px, 132), Color(0.55, 0.3, 0.75))
			var y := 40.0
			if _state["drop"] >= 0.0:
				var d: float = _state["drop"]
				y = 40.0 + (minf(d, 0.9) / 0.9) * 82.0 - (maxf(0.0, d - 0.9) / 1.3) * 82.0
			var x: float = _state["x"]
			c.draw_line(Vector2(x, 30), Vector2(x, y), Color(0.8, 0.8, 0.85))
			c.draw_line(Vector2(x, y), Vector2(x - 6, y + 8), Color(0.8, 0.8, 0.85), 2.0)
			c.draw_line(Vector2(x, y), Vector2(x + 6, y + 8), Color(0.8, 0.8, 0.85), 2.0)
			if _state.get("won", false) and _state["drop"] > 0.9:
				_bear(c, Vector2(x, y + 14), Color(0.55, 0.3, 0.75))
			if _state.has("slip") and _state["drop"] > 0.9 and _state["drop"] < 1.5:
				c.draw_string(FONT, Vector2(x - 20, y - 6), "¡PLOP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.5))
		"rueda":
			_draw_rueda(c)


func _bear(c: Control, at: Vector2, col: Color) -> void:
	c.draw_circle(at + Vector2(0, -6), 5.0, col)
	c.draw_circle(at + Vector2(-4, -11), 2.0, col)
	c.draw_circle(at + Vector2(4, -11), 2.0, col)
	c.draw_circle(at + Vector2(0, 2), 6.0, col)
	c.draw_circle(at + Vector2(0, 2), 2.0, Color(0.1, 0.08, 0.1))  # el corazón negro


func _draw_rueda(c: Control) -> void:
	var scene: String = _state.get("scene", "rueda")
	if scene == "rueda":
		# El barrio de noche, desde la cabina que sube.
		c.draw_rect(Rect2(0, 0, 320, 180), Color(0.06, 0.05, 0.16))
		for i in 40:
			c.draw_rect(Rect2(fmod(i * 83.0, 320.0), fmod(i * 29.0, 70.0), 1, 1), Color(1, 1, 0.9, 0.6))
		var ground := 180.0 - (1.0 - _rise) * 0.0 + _rise * 60.0
		for i in 16:  # las casas y sus ventanas
			var bx := i * 22.0 - 10.0
			var bh := 20.0 + fmod(i * 17.0, 30.0)
			c.draw_rect(Rect2(bx, ground - bh - 40.0 * (1.0 - _rise), 20, bh + 80), Color(0.12, 0.1, 0.18))
			if i % 3 != 0:
				c.draw_rect(Rect2(bx + 6, ground - bh + 6 - 40.0 * (1.0 - _rise), 4, 4), Color(1, 0.85, 0.45))
		c.draw_line(Vector2(0, 150 - _rise * 20.0), Vector2(320, 140 - _rise * 20.0), Color(0.3, 0.45, 0.7), 3.0)  # el río
		# La cabina.
		c.draw_rect(Rect2(110, 96, 100, 6), Color(0.85, 0.75, 0.3))
		c.draw_line(Vector2(160, 0), Vector2(160, 96), Color(0.7, 0.7, 0.75), 2.0)
		c.draw_rect(Rect2(140, 70, 12, 26), Color(0.4, 0.42, 0.5))
		c.draw_circle(Vector2(146, 64), 6.0, Color(0.2, 0.15, 0.15))
	else:
		# La fiesta de antes: terraza, bombillos, gente bailando (sin cara: es un recuerdo).
		c.draw_rect(Rect2(0, 0, 320, 180), Color(0.12, 0.06, 0.12))
		for i in 30:
			var p := Vector2(i * 11.0, 30 + sin(i * 0.6) * 6.0)
			c.draw_circle(p, 2.0, Color.from_hsv(fmod(i * 0.17, 1.0), 0.6, 1.0) if int(_t * 3.0 + i) % 3 != 0 else Color(0.3, 0.3, 0.3))
		c.draw_rect(Rect2(0, 130, 320, 50), Color(0.5, 0.32, 0.26))
		for i in 7:
			var bx := 30 + i * 40 + sin(_t * 3.0 + i) * 4.0
			var col := Color.from_hsv(fmod(i * 0.23, 1.0), 0.4, 0.6)
			c.draw_rect(Rect2(bx, 100 + absf(sin(_t * 4.0 + i)) * -4.0, 10, 30), col)
			c.draw_circle(Vector2(bx + 5, 94 + absf(sin(_t * 4.0 + i)) * -4.0), 5.0, col.darkened(0.3))
		# Él, joven, en el centro: camisa planchada, una copa y un cigarrillo.
		c.draw_rect(Rect2(152, 96, 14, 34), Color(0.92, 0.92, 0.95))
		c.draw_circle(Vector2(159, 88), 6.0, Color(0.15, 0.1, 0.1))
		c.draw_rect(Rect2(168, 104, 4, 6), Color(0.95, 0.95, 1.0, 0.7))
		if scene == "humo":
			c.draw_line(Vector2(150, 106), Vector2(144, 104), Color(0.95, 0.95, 0.9), 2.0)
			c.draw_circle(Vector2(143, 104), 1.5, Color(1, 0.5, 0.2))
			# La barra de la calada: lo verde es la buena.
			c.draw_rect(Rect2(60, 150, 200, 8), Color(0.2, 0.2, 0.22))
			c.draw_rect(Rect2(60 + 200 * 0.55, 150, 200 * 0.25, 8), Color(0.3, 0.75, 0.35))
			c.draw_rect(Rect2(60 + 200 * 0.8, 150, 200 * 0.2, 8), Color(0.8, 0.25, 0.25))
			c.draw_rect(Rect2(60, 151, 200 * clampf(_hold, 0, 1), 6), Color(0.95, 0.95, 0.9, 0.85))
			var puff: float = _state.get("puff", 0.0)
			if puff > 0.0:
				for k in 4:
					c.draw_circle(Vector2(150 - k * 8, 92 - k * 10 - _t * 4.0 + floor(_t * 4.0)), 4.0 + k, Color(0.85, 0.85, 0.9, 0.5))
			elif puff < 0.0:
				c.draw_string(FONT, Vector2(120, 80), "¡COF COF!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.6, 0.5))
