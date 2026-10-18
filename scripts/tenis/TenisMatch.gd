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
const SX := 8.0    # pixeles por metro, a lo ancho
const SY := 5.4    # y a lo largo (la cancha se ve un poco achatada)
const CENTER := Vector2(160, 96)
const BUFFER := 0.2

static var setup := {}

var sim: TenisSim
var _acc := 0.0
var _buffer := ""
var _buffer_t := 0.0
var _hud: CanvasLayer
var _score_l: Label
var _call_l: Label
var _pop_l: Label
var _pop_t := 0.0
var _flash := {}  # golpes que brillan un momento (habilidad): player -> tiempo
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
	_score_l = _label(Vector2(4, 3), Color(1, 0.95, 0.75))
	_call_l = _label(Vector2(4, 13), Color(0.85, 0.9, 1.0))
	_pop_l = _label(Vector2(0, 160), Color(1, 0.9, 0.4))
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
	if _pop_t <= 0.0:
		_pop_l.text = ""
	for k in _flash.keys():
		_flash[k] -= delta
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
		"point":
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
	_score_l.text = "%s %d  %s %d%s" % [n0, s.games[0], n1, s.games[1], sets]
	_call_l.text = s.text()


# ---------------------------------------------------------------- Dibujar

func w2s(p: Vector2) -> Vector2:
	return CENTER + Vector2(p.x * SX, p.y * SY)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.22, 0.35, 0.55))           # la cancha de cemento azul (el fondo)
	if sim == null:
		return
	var hw := TenisData.HALF_W
	var hl := TenisData.HALF_L
	var dw := hw + 1.37                                                  # los pasillos de dobles
	var court := Rect2(w2s(Vector2(-dw - 1.5, -hl - 2.5)), Vector2((dw + 1.5) * 2 * SX, (hl + 2.5) * 2 * SY))
	draw_rect(court, Color(0.28, 0.45, 0.66))
	draw_rect(Rect2(w2s(Vector2(-dw, -hl)), Vector2(dw * 2 * SX, hl * 2 * SY)), Color(0.26, 0.5, 0.42))
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
	# El medidor de la habilidad y el cansancio (debajo del nombre de cada uno).
	for p in sim.players:
		var at := Vector2(4 if p.idx == 0 else 250, 170 if p.idx == 0 else 24)
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
	var up := g - Vector2(0, sim.ball.z * 5.0)
	draw_circle(up, 1.7, Color(0.85, 0.95, 0.25))
	draw_rect(Rect2(up - Vector2(0.5, 1), Vector2(1, 1)), Color(1, 1, 0.8))


## Un muñeco provisional (hasta que tengan su dibujo): las piernas, el cuerpo de su color, la cabeza y
## la raqueta del lado de la mano. Brilla cuando usa la habilidad.
func _draw_player(p) -> void:
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
