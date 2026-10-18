extends Node2D
## Un partido de tenis jugable: dibuja lo que pasa en TenisSim (que no sabe de pantallas).
## La cancha se ve de arriba (un poquito achatada a lo largo); la pelota, con su sombra en el piso, para
## que se lea la altura. El jugador 0 (abajo) lo maneja el humano; el 1, la máquina (TenisAI).
## Controles: flechas: moverse (y, al pegarle, a qué lado va). E: golpe plano. Q: cortado (con arriba,
## dejada). X: globo. F: la habilidad. Se puede apretar un poquito antes: el golpe sale cuando llega.
## Configurar antes de entrar: TenisMatch.setup = {"p0": id, "p1": id, "format": "arcade", "difficulty": "normal",
## "seed": n, "ai0": false}. Al terminar emite finished(winner) y, si setup["back"] dice, vuelve.
## Si se abre sin setup (F6 en el editor), primero se escoge tenista y rival.

signal finished(winner: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
## La cancha en perspectiva (la misma cuenta que tools/art/draw_tenis_coliseo.py, que pinta el fondo):
## a lo ancho, de 6.6 px por metro en el fondo a 8.6 en el frente; a lo largo, 4.6.
const KX_FAR := 6.6
const KX_NEAR := 8.6
const SY := 4.6
const CENTER := Vector2(160, 104)
const BG := preload("res://assets/tenis/coliseo.png")
const BG_GRITA := preload("res://assets/tenis/coliseo_grita.png")
const BUFFER := 0.2

static var setup := {}

var sim: TenisSim
var _acc := 0.0
var _buffer := ""
var _buffer_t := 0.0
var _hud: CanvasLayer
var _rows: Array = []      # el tablero: una fila por jugador (nombre, juegos, puntos)
var _cheer := 0.0          # la gente de pie (después de un punto bueno)
var _pop_l: Label
var _pop_t := 0.0
var _flash := {}  # golpes que brillan un momento (habilidad): player -> tiempo
## Los dibujos de los tenistas (tools/art/draw_tenistas.py): celdas de 32x42, los pies en (16, 40);
## fila 0 de espaldas (el de abajo), fila 1 de frente (el de arriba). Las columnas, en este orden:
const POSES := ["listo", "listo2", "corre1", "corre2", "corre3", "corre4", "drive_atras", "drive", "drive_fin",
	"reves_atras", "reves", "reves_fin", "saque_lanza", "saque", "saque_fin", "tirada", "piso",
	"celebra", "bravo", "dejada"]
const CELL := Vector2(32, 42)
const FEET := Vector2(16, 40)
var _sheets := {}   # id -> Texture2D (los que no tienen dibujo, como "base", van con el muñeco)
var _anim := [{}, {}]  # por jugador: {"pose", "t"} lo que está haciendo (un golpe, celebrar...)
var _run_d := [0.0, 0.0]  # lo que lleva corrido (para el paso)
var _picking := -1  # escogiendo: 0 el tenista, 1 el rival (-1: jugando)
var _pick := [0, 1]
var _pick_ls: Array = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	MusicDirector.force("")
	if setup.is_empty():
		_picking = 0
		_build_picker()
		return
	_start()


func _start() -> void:
	var s := setup
	sim = TenisSim.new(s.get("p0", "base"), s.get("p1", "base"), TenisData.FORMATS[s.get("format", "arcade")],
		int(s.get("seed", Time.get_ticks_msec())), int(s.get("first_server", 0)))
	TenisAI.setup(sim, 1, s.get("difficulty", "normal"))
	if s.get("ai0", false):
		TenisAI.setup(sim, 0, s.get("difficulty", "normal"))
	sim.event.connect(_on_event)
	for p in sim.players:
		var path := "res://assets/tenis/%s.png" % p.id
		if ResourceLoader.exists(path):
			_sheets[p.id] = load(path)
	for i in 2:  # el de abajo (el que maneja uno) arriba en el tablero
		_rows.append(_label(Vector2(8, 6 + i * 19), Color(1, 0.95, 0.75)))
	_pop_l = _label(Vector2(0, 171), Color(1, 0.9, 0.4))
	_pop_l.size = Vector2(Controls.right_edge(), 10)
	_pop_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(at: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_hud.add_child(l)
	return l


# ---------------------------------------------------------------- Escoger

## La lista de los que hay: nombre y apodo, uno debajo del otro; la flecha marca el escogido.
func _build_picker() -> void:
	for id in TenisData.ROSTER:
		var path := "res://assets/tenis/%s.png" % id
		if ResourceLoader.exists(path):
			_sheets[id] = load(path)
	var head := _label(Vector2(0, 14), Color(1, 0.9, 0.5))
	head.size = Vector2(Controls.right_edge(), 10)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pick_ls.append(head)
	for i in TenisData.ROSTER.size():
		var d: Dictionary = TenisData.player(TenisData.ROSTER[i])
		var n := _label(Vector2(40, 38 + i * 28), d["color"])
		n.text = d["name"]
		var t := _label(Vector2(40, 48 + i * 28), Color(0.7, 0.72, 0.8))
		t.text = d["title"]
		var arrow := _label(Vector2(26, 38 + i * 28), Color(1, 0.95, 0.75))
		_pick_ls.append(arrow)
	var foot := _label(Vector2(0, 160), Color(0.85, 0.9, 1.0))
	foot.size = Vector2(Controls.right_edge(), 10)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "FLECHAS: CAMBIAR   E: ESCOGER"
	_update_picker()


func _update_picker() -> void:
	_pick_ls[0].text = "ESCOGE TU TENISTA" if _picking == 0 else "ESCOGE EL RIVAL"
	for i in TenisData.ROSTER.size():
		var a: Label = _pick_ls[1 + i]
		a.text = ">" if i == _pick[_picking] else ("·" if _picking == 1 and i == _pick[0] else "")


func _picker_input() -> void:
	var n: int = TenisData.ROSTER.size()
	if Input.is_action_just_pressed("move_down"):
		_pick[_picking] = (_pick[_picking] + 1) % n
	elif Input.is_action_just_pressed("move_up"):
		_pick[_picking] = (_pick[_picking] + n - 1) % n
	elif Input.is_action_just_pressed("interact"):
		if _picking == 0:
			_picking = 1
			if _pick[1] == _pick[0]:
				_pick[1] = (_pick[0] + 1) % n
		else:
			for l in _hud.get_children():
				l.queue_free()
			setup = {"p0": TenisData.ROSTER[_pick[0]], "p1": TenisData.ROSTER[_pick[1]], "format": "arcade",
				"difficulty": "normal"}
			_picking = -1
			_start()
			return
	_update_picker()


func _process(delta: float) -> void:
	if _picking >= 0:
		_picker_input()
		queue_redraw()
		return
	_read_human(delta)
	_acc += minf(delta, 0.1)
	while _acc >= TenisSim.DT:
		_acc -= TenisSim.DT
		var i0: Dictionary = TenisAI.think(sim, 0) if setup.get("ai0", false) else _human_input()
		sim.step([i0, TenisAI.think(sim, 1)])
	_pop_t -= delta
	_cheer -= delta
	if _pop_t <= 0.0:
		_pop_l.text = ""
	for k in _flash.keys():
		_flash[k] -= delta
	for i in 2:
		if not _anim[i].is_empty():
			_anim[i]["t"] = float(_anim[i]["t"]) + delta
			if float(_anim[i]["t"]) > float(_anim[i]["len"]):
				_anim[i] = {}
		_run_d[i] += sim.players[i].vel.length() * delta
	_update_hud()
	queue_redraw()


func _read_human(delta: float) -> void:
	_buffer_t -= delta
	if _buffer_t <= 0.0:
		_buffer = ""
	if Input.is_action_just_pressed("interact"):
		_buffer = "drive"
		_buffer_t = BUFFER
	elif Input.is_action_just_pressed("cancel"):
		_buffer = "drop" if Input.is_action_pressed("move_up") else "slice"
		_buffer_t = BUFFER
	elif Input.is_action_just_pressed("drop"):
		_buffer = "lob"
		_buffer_t = BUFFER


func _human_input() -> Dictionary:
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var inp := {"move": mv, "hit": "", "aim": Vector2(mv.x, -mv.y), "ability": Input.is_action_just_pressed("sniff")}
	var p = sim.players[0]
	if _buffer != "" and (sim.state == "serve" and sim.score.server == 0 or sim._can_hit(p)):
		inp["hit"] = _buffer
		_buffer = ""
	return inp


func _on_event(kind: String, d: Dictionary) -> void:
	match kind:
		"hit":
			var p = sim.players[d["player"]]
			var k: String = d["kind"]
			if sim.last_shot.get("serve", false):
				_anim[p.idx] = {"seq": ["saque", "saque_fin"], "cuts": [0.1], "t": 0.0, "len": 0.4}
			elif k == "drop":
				_anim[p.idx] = {"seq": ["dejada"], "cuts": [], "t": 0.0, "len": 0.35}
			else:
				var fore: bool = (sim.ball.x - p.pos.x) * p.sign >= 0.0 and k != "slice"
				var a := "drive" if fore else "reves"
				_anim[p.idx] = {"seq": [a, a + "_fin"], "cuts": [0.09], "t": 0.0, "len": 0.38}
		"point":
			var w: int = d["winner"]
			if d["kind"] in ["winner", "ace"]:
				_anim[w] = {"seq": ["celebra"], "cuts": [], "t": 0.0, "len": 1.1}
			if d["kind"] in ["winner", "ace"] or int(d["rally"]) >= 12 or d.get("closed", "") != "":
				_cheer = 1.3  # la gente se para
			if d["kind"] in ["unforced", "double_fault"]:
				_anim[1 - w] = {"seq": ["bravo"], "cuts": [], "t": 0.0, "len": 1.2}
			var names := {"ace": "¡ACE!", "winner": "GANADOR", "unforced": "ERROR", "forced": "ERROR FORZADO",
				"forced_missed": "NO ALCANZÓ", "double_fault": "DOBLE FALTA"}
			_pop(names.get(d["kind"], ""))
		"fault":
			_pop("FALTA")
		"countered":
			_pop("¡LE LEYERON LA JUGADA!")
		"ability_fail":
			_pop("SE TIRÓ Y NO LLEGÓ")
		"ability":
			_flash[d["player"]] = 1.0
			_pop(str(d.get("name", "")).to_upper())
		"match":
			_pop("¡GANA %s!" % TenisData.player(sim.players[d["winner"]].id)["name"].to_upper())
			finished.emit(d["winner"])


func _pop(t: String) -> void:
	if t == "":
		return
	_pop_l.text = t
	_pop_t = 1.4


func _update_hud() -> void:
	var s := sim.score
	var n0: String = TenisData.player(sim.players[0].id)["short"]
	var n1: String = TenisData.player(sim.players[1].id)["short"]
	var sets := ""
	for h in s.set_history:
		sets += " %d-%d" % [h[0], h[1]]
	var names := [n0, n1]
	for i in 2:
		_rows[i].text = "%s %d %s" % [names[i], s.games[i], _points_text(i)]
		_rows[i].add_theme_color_override("font_color", TenisData.player(sim.players[i].id)["color"].lightened(0.35))


## Los puntos de uno en el tablero: 0 15 30 40, AD, o el número en el desempate.
func _points_text(i: int) -> String:
	var s := sim.score
	var a: int = s.points[i]
	var b: int = s.points[1 - i]
	if s.over():
		return ""
	if s.tiebreak:
		return str(a)
	if a >= 3 and b >= 3 and not s.no_ad:
		return "AD" if a > b else "40"
	return ["0", "15", "30", "40"][mini(a, 3)]


# ---------------------------------------------------------------- Dibujar

func w2s(p: Vector2) -> Vector2:
	var t := (p.y + TenisData.HALF_L) / (2.0 * TenisData.HALF_L)
	return CENTER + Vector2(p.x * lerpf(KX_FAR, KX_NEAR, t), p.y * SY)


func _draw() -> void:
	if sim == null:
		draw_texture(BG, Vector2.ZERO)
		draw_rect(Rect2(0, 0, 320, 180), Color(0.04, 0.04, 0.08, 0.72))  # escogiendo: el coliseo, apagado
		if _picking >= 0:  # el que está marcado, grande y de frente, a la derecha de la lista
			var tex: Texture2D = _sheets.get(TenisData.ROSTER[_pick[_picking]])
			if tex != null:
				var t := Time.get_ticks_msec() / 1000.0
				var col := POSES.find("listo" if fmod(t, 0.8) < 0.4 else "listo2")
				draw_texture_rect_region(tex, Rect2(Vector2(254, 52), CELL * 2), Rect2(Vector2(col * CELL.x, CELL.y), CELL))
		return
	var hw := TenisData.HALF_W
	var hl := TenisData.HALF_L
	var dw := hw + 1.37                                                  # los pasillos de dobles
	draw_texture(BG_GRITA if _cheer > 0.0 else BG, Vector2.ZERO)
	var line := Color(0.95, 0.95, 0.92)
	for x in [-dw, -hw, hw, dw]:
		draw_line(w2s(Vector2(x, -hl)), w2s(Vector2(x, hl)), line, 1.0)
	for y in [-hl, hl]:
		draw_line(w2s(Vector2(-dw, y)), w2s(Vector2(dw, y)), line, 1.0)
	for y in [-TenisData.SERVICE_L, TenisData.SERVICE_L]:
		draw_line(w2s(Vector2(-hw, y)), w2s(Vector2(hw, y)), line, 1.0)
	draw_line(w2s(Vector2(0, -TenisData.SERVICE_L)), w2s(Vector2(0, TenisData.SERVICE_L)), line, 1.0)
	# Los jugadores, de atrás para adelante (el de arriba primero), y la pelota en su lugar.
	var order := [1, 0]
	var ball_drawn := false
	for i in order:
		var p = sim.players[i]
		if not ball_drawn and sim.ball.y < p.pos.y:
			_draw_ball()
			ball_drawn = true
		if i == 0:
			_draw_net()
		_draw_player(p)
	if not ball_drawn:
		_draw_ball()
	# El tablero (arriba a la izquierda): el recuadro; los nombres y puntos son Labels encima. Debajo de
	# cada nombre, el cansancio (verde) y el medidor de la habilidad (naranja).
	draw_rect(Rect2(3, 3, 78, 40), Color(0.06, 0.06, 0.1, 0.92))
	draw_rect(Rect2(3, 3, 78, 40), Color(0.5, 0.42, 0.3), false, 1.0)
	var srv := Vector2(5, 9 + sim.score.server * 19)
	draw_circle(srv, 1.5, Color(0.85, 0.95, 0.25))  # quién saca
	for p in sim.players:
		var at := Vector2(8, 16 + p.idx * 19)
		draw_rect(Rect2(at, Vector2(64, 3)), Color(0.1, 0.1, 0.14))
		draw_rect(Rect2(at, Vector2(64 * p.stamina / 100.0, 3)), Color(0.4, 0.85, 0.5))
		draw_rect(Rect2(at + Vector2(0, 4), Vector2(64, 3)), Color(0.1, 0.1, 0.14))
		var ab := TenisAbilities.def(p)
		var ready: bool = not ab.is_empty() and p.meter >= float(ab["cost"]) and p.cooldown == 0 and p.active.is_empty()
		var mcol := Color(1.0, 0.7, 0.2)
		if ready and fmod(sim.t, 0.5) < 0.25:
			mcol = Color(1.0, 0.95, 0.6)  # lista: titila (el otro también lo ve)
		draw_rect(Rect2(at + Vector2(0, 4), Vector2(64 * p.meter / 100.0, 3)), mcol)
		if not ab.is_empty():  # la marca de cuánto cuesta
			draw_rect(Rect2(at + Vector2(64 * float(ab["cost"]) / 100.0, 3), Vector2(1, 5)), Color(1, 1, 1, 0.7))


func _draw_net() -> void:
	var dw := TenisData.HALF_W + 1.37
	var a := w2s(Vector2(-dw - 0.3, 0))
	var b := w2s(Vector2(dw + 0.3, 0))
	draw_line(a + Vector2(0, -5), b + Vector2(0, -5), Color(0.95, 0.95, 0.92), 1.0)
	for x in range(int(a.x), int(b.x), 2):
		draw_line(Vector2(x, a.y - 4), Vector2(x, a.y), Color(0.1, 0.1, 0.12, 0.6), 1.0)
	draw_rect(Rect2(a + Vector2(-1, -6), Vector2(2, 7)), Color(0.4, 0.4, 0.44))
	draw_rect(Rect2(b + Vector2(-1, -6), Vector2(2, 7)), Color(0.4, 0.4, 0.44))


func _draw_ball() -> void:
	if not sim.live and sim.state != "serve":
		return
	var g := w2s(Vector2(sim.ball.x, sim.ball.y))
	draw_circle(g, 1.6, Color(0, 0, 0, 0.35))                            # la sombra: dónde está de verdad
	var up := g - Vector2(0, sim.ball.z * SY)
	draw_circle(up, 1.7, Color(0.85, 0.95, 0.25))
	draw_rect(Rect2(up - Vector2(0.5, 1), Vector2(1, 1)), Color(1, 1, 0.8))


## La pose de ahora: lo que esté haciendo (golpe, celebrar) o, si no, lo que pide la cancha.
func _pose(p) -> String:
	if p.stuck > 0.0:
		return "piso"
	if not p.active.is_empty() and float(p.active.get("window", 0.0)) > 0.0:
		return "tirada"
	var a: Dictionary = _anim[p.idx]
	if not a.is_empty():
		var i := 0
		for c in a["cuts"]:
			if float(a["t"]) >= float(c):
				i += 1
		return a["seq"][i]
	if sim.state == "serve" and sim.score.server == p.idx:
		return "saque_lanza" if fmod(sim.t, 1.2) > 0.5 else "listo"
	# Preparando: la pelota viene hacia él y ya casi le llega.
	if sim.live and sim.last_hitter != p.idx and sim.ball.y * p.sign > 0.0:
		var dist := Vector2(sim.ball.x, sim.ball.y).distance_to(p.pos)
		if dist < p.reach() * 2.6:
			return "drive_atras" if (sim.ball.x - p.pos.x) * p.sign >= 0.0 else "reves_atras"
	if p.vel.length() > 0.7:
		return "corre%d" % (1 + int(_run_d[p.idx] / 0.55) % 4)
	return "listo" if fmod(sim.t, 0.8) < 0.4 else "listo2"


func _draw_player(p) -> void:
	var tex: Texture2D = _sheets.get(p.id)
	if tex != null:
		var feet := w2s(p.pos).round()
		if _flash.get(p.idx, 0.0) > 0.0:
			draw_circle(feet - Vector2(0, 10), 11.0, Color(1, 0.8, 0.3, 0.28))
		draw_circle(feet + Vector2(0, 0.5), 3.5, Color(0, 0, 0, 0.28))
		var col := POSES.find(_pose(p))
		var src := Rect2(Vector2(col * CELL.x, (0 if p.idx == 0 else 1) * CELL.y), CELL)
		draw_texture_rect_region(tex, Rect2(feet - FEET, CELL), src)
		return
	_draw_placeholder(p)


## Un muñeco provisional (para los que no tienen dibujo todavía, como "base").
func _draw_placeholder(p) -> void:
	var data: Dictionary = TenisData.player(p.id)
	var feet := w2s(p.pos)
	var col: Color = data["color"]
	if _flash.get(p.idx, 0.0) > 0.0:
		draw_circle(feet - Vector2(0, 8), 9.0, Color(1, 0.8, 0.3, 0.3))
	draw_circle(feet, 3.0, Color(0, 0, 0, 0.3))
	if p.stuck > 0.0:  # en el piso, después de tirarse
		draw_rect(Rect2(feet + Vector2(-7, -3), Vector2(10, 3)), col)
		draw_rect(Rect2(feet + Vector2(-7, -2), Vector2(4, 2)), Color(0.2, 0.2, 0.24))
		draw_circle(feet + Vector2(5, -2), 2.3, Color(0.86, 0.66, 0.52))
		return
	var step := sin(sim.t * 18.0) * 1.5 if p.vel.length() > 0.5 else 0.0
	draw_rect(Rect2(feet + Vector2(-2, -5 + step * 0.3), Vector2(1, 5)), Color(0.2, 0.2, 0.24))
	draw_rect(Rect2(feet + Vector2(1, -5 - step * 0.3), Vector2(1, 5)), Color(0.2, 0.2, 0.24))
	draw_rect(Rect2(feet + Vector2(-3, -12), Vector2(6, 7)), col)
	draw_circle(feet + Vector2(0, -14), 2.5, Color(0.86, 0.66, 0.52))
	var hand := 1.0 if data.get("hand", "right") == "right" else -1.0
	if p.idx == 1:
		hand = -hand  # el de arriba nos da la cara
	draw_line(feet + Vector2(3 * hand, -10), feet + Vector2(6 * hand, -14), Color(0.3, 0.3, 0.32), 1.0)
	draw_circle(feet + Vector2(7 * hand, -15), 1.8, Color(0.9, 0.9, 0.9, 0.7))
