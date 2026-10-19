extends Node2D
## Un partido de tenis jugable: dibuja lo que pasa en TenisSim (que no sabe de pantallas).
## La cancha se ve de arriba (un poquito achatada a lo largo); la pelota, con su sombra en el piso, para
## que se lea la altura. El jugador 0 (abajo) lo maneja el humano; el 1, la máquina (TenisAI).
## Controles: flechas: moverse (y, al pegarle, a qué lado va). E: golpe plano. Q: cortado (con arriba,
## dejada). X: globo. F: la habilidad. Se puede apretar un poquito antes: el golpe sale cuando llega.
## Configurar antes de entrar: TenisMatch.setup = {"p0": id, "p1": id, "format": "arcade", "difficulty": "normal",
## "seed": n, "ai0": false}. Al terminar emite finished(winner) y, si setup["back"] dice, vuelve.
## Si se abre sin setup (F6 en el editor), primero se escoge tenista y rival (TenisPicker).
## Al final del partido sale el resumen (ganadores, errores, aces...); con E (o solo, si
## setup["auto_close"] dice cuántos segundos) se cierra y emite closed(winner).
##
## En la historia (TenisJornada): setup["ballboy"] = true: los dos juegan solos y uno es el
## recogebolas, agachado al lado de la red. No se puede mover mientras juegan; cuando se acaba el
## punto, corre por la pelota (flechas) y la trae: el saque que sigue espera a que vuelva. Traerla
## rápido da propina (bb_fast). Con setup["abandon_games"] = n, después de n juegos el de abajo
## abandona: se emite abandon_now() y todo se queda quieto hasta take_over(), que le pasa a él la
## raqueta (lo maneja el humano, con el dibujo de él: assets/tenis/el_<id>.png).

signal finished(winner: int)
signal closed(winner: int)
signal abandon_now()

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
## La cancha en perspectiva (la misma cuenta que tools/art/draw_tenis_coliseo.py, que pinta el fondo):
## a lo ancho, de 10.5 px por metro en el fondo a 13.5 en el frente; a lo largo, 4.6.
const KX_FAR := 10.5
const KX_NEAR := 13.5
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
	"celebra", "bravo", "dejada", "agachado", "recoge"]
const CELL := Vector2(32, 42)
const FEET := Vector2(16, 40)
var _sheets := {}   # id -> Texture2D (los que no tienen dibujo, como "base", van con el muñeco)
var _anim := [{}, {}]  # por jugador: {"pose", "t"} lo que está haciendo (un golpe, celebrar...)
var _run_d := [0.0, 0.0]  # lo que lleva corrido (para el paso)
var _summary_t := -1.0  # desde cuándo se ve el resumen del final (-1: no hay)

# El recogebolas (setup["ballboy"]).
const BB_HOME := Vector2(TenisData.HALF_W + 2.1, 0.7)  # agachado al lado del poste de la red (abajo, a la derecha)
const BB_SPEED := 5.2
const EL_SHEET := preload("res://assets/tenis/el.png")
var bb_fast := 0           # pelotas traídas rápido (cada una, propina)
var bb_slow := 0
var _bb_pos := BB_HOME
var _bb_vel := Vector2.ZERO
var _bb_ball = null        # Vector2: la pelota tirada que falta traer (null: ninguna)
var _bb_has := false       # ya la recogió: va de vuelta
var _bb_t := 0.0           # cuánto lleva desde que se acabó el punto
var _bb_pick := 0.0        # agachándose a recogerla
var _bb_scold := false     # ya le gritaron "¡quieto!" en este punto
var _bb_d := 0.0           # lo que lleva corrido (para el paso)
var _abandon := 0          # 0: no; 1: ya toca (cuando traiga la pelota); 2: esperando take_over; 3: ya juega él

# Los sonidos (tools/audio/tenis_audio.py): la raqueta, el bote, la red y el público.
const SFX := ["golpe", "golpe_duro", "bote", "red", "aplauso", "ovacion", "uy"]
const SFX_DB := {"golpe": -4.0, "golpe_duro": -2.0, "bote": -12.0, "red": -6.0, "aplauso": -10.0, "ovacion": -7.0, "uy": -8.0}
var _sfx := {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	MusicDirector.force("tenis_partido")
	_load_sfx()
	if setup.is_empty():
		var picker := TenisPicker.new()
		picker.titles = ["ESCOGE TU TENISTA", "ESCOGE EL RIVAL"]
		picker.picked.connect(func(ids: Array) -> void:
			picker.queue_free()
			setup = {"p0": ids[0], "p1": ids[1], "format": "arcade", "difficulty": "normal"}
			_start())
		add_child(picker)
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


# ---------------------------------------------------------------- El recogebolas

func _ballboy(delta: float) -> void:
	_bb_pick = maxf(0.0, _bb_pick - delta)
	var mv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if sim.live or (_bb_ball == null and not _bb_has):
		# Mientras juegan: quieto, agachado. Si se mueve, le gritan (y esa pelota no tiene propina).
		_bb_vel = Vector2.ZERO
		_bb_pos = _bb_pos.move_toward(BB_HOME, BB_SPEED * delta)
		if sim.live and mv.length() > 0.3 and not _bb_scold:
			_bb_scold = true
			_pop("¡QUIETO, RECOGEBOLAS!")
		if _abandon == 1 and not sim.live and _bb_pos.distance_to(BB_HOME) < 0.1:
			_abandon = 2
			_pop(TenisHistoria.ABANDONOS.get(sim.players[0].id, {}).get("pop", ""))
			abandon_now.emit()
		return
	_bb_t += delta
	if _bb_pick > 0.0:
		_bb_vel = Vector2.ZERO
		return
	_bb_vel = Vector2(mv.x, mv.y).limit_length(1.0) * BB_SPEED
	_bb_pos += _bb_vel * delta
	_bb_d += _bb_vel.length() * delta
	var hw := TenisData.HALF_W + 3.5
	var hl := TenisData.HALF_L + 3.0
	_bb_pos = Vector2(clampf(_bb_pos.x, -hw, hw), clampf(_bb_pos.y, -hl, hl))
	if _bb_ball != null and _bb_pos.distance_to(_bb_ball) < 0.8:
		_bb_ball = null
		_bb_has = true
		_bb_pick = 0.3
	elif _bb_has and _bb_pos.distance_to(BB_HOME) < 0.7:
		_bb_has = false
		_bb_pos = BB_HOME
		if _bb_t < TenisHistoria.RAPIDO and not _bb_scold:
			bb_fast += 1
			_pop("+$%d" % TenisHistoria.PROPINA_BOLA)
		elif _bb_t > TenisHistoria.LENTO:
			bb_slow += 1
			_pop("¡LA PELOTA, MUDO!")
		_bb_scold = false


## Le pasa la raqueta: desde ahora lo maneja el humano, con el dibujo de él.
func take_over() -> void:
	setup["ai0"] = false
	setup["ballboy"] = false
	_bb_ball = null
	_bb_has = false
	_abandon = 3
	var pid: String = sim.players[0].id
	var path := "res://assets/tenis/el_%s.png" % pid
	if ResourceLoader.exists(path):
		_sheets[pid] = load(path)
	_anim[0] = {}
	_buffer = ""
	MusicDirector.force("tenis_el")  # él con la raqueta: el mismo tema, más rápido y un tono arriba


## Juega él (el de abajo) desde que tomó la raqueta.
func is_taken_over() -> bool:
	return _abandon == 3


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


func _process(delta: float) -> void:
	if sim == null:
		return
	if _summary_t >= 0.0:
		_summary_t += delta
		var auto: float = setup.get("auto_close", 0.0)
		if (_summary_t > 0.6 and Input.is_action_just_pressed("interact")) or (auto > 0.0 and _summary_t > auto):
			_summary_t = -2.0
			closed.emit(sim.score.winner)
		queue_redraw()
		return
	_read_human(delta)
	if setup.get("ballboy", false):
		_ballboy(delta)
	_acc += minf(delta, 0.1)
	while _acc >= TenisSim.DT:
		_acc -= TenisSim.DT
		if _abandon == 2 or (_bb_ball != null or _bb_has) and sim.state == "point_over" and sim.wait < 0.1:
			_acc = 0.0  # el saque que sigue espera la pelota (o al que va a terminar el partido)
			break
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


func _load_sfx() -> void:
	for n in SFX:
		var a := AudioStreamPlayer.new()
		a.stream = load("res://assets/audio/tenis/%s.wav" % n)
		a.volume_db = SFX_DB[n]
		a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(a)
		_sfx[n] = a


func _sound(n: String, pitch := 1.0) -> void:
	var a: AudioStreamPlayer = _sfx.get(n)
	if a != null:
		a.pitch_scale = pitch
		a.play()


func _on_event(kind: String, d: Dictionary) -> void:
	match kind:
		"bounce":
			_sound("bote", randf_range(0.92, 1.08))
		"hit":
			var hard: bool = float(d["speed"]) >= 22.0 or str(d.get("ability", "")) != ""
			_sound("golpe_duro" if hard else "golpe", randf_range(0.94, 1.06))
			var p = sim.players[d["player"]]
			var k: String = d["kind"]
			if sim.last_shot.get("serve", false):
				_anim[p.idx] = {"seq": ["saque", "saque_fin"], "cuts": [0.1], "t": 0.0, "len": 0.4}
			elif k == "drop":
				_anim[p.idx] = {"seq": ["dejada"], "cuts": [], "t": 0.0, "len": 0.35}
			else:
				var fore: bool = sim.on_forehand(p) and k != "slice"
				var a := "drive" if fore else "reves"
				_anim[p.idx] = {"seq": [a, a + "_fin"], "cuts": [0.09], "t": 0.0, "len": 0.38}
		"point":
			var w: int = d["winner"]
			if setup.get("ballboy", false):  # la pelota quedó tirada: a traerla
				var hl := TenisData.HALF_L
				var hw := TenisData.HALF_W
				_bb_ball = Vector2(clampf(sim.ball.x, -hw - 3.0, hw + 3.0), clampf(sim.ball.y, -hl - 1.5, hl + 2.5))
				_bb_t = 0.0
				_bb_has = false
			var ag: int = int(setup.get("abandon_games", 0))
			if ag > 0 and _abandon == 0 and sim.score.games[0] + sim.score.games[1] >= ag and not sim.score.over():
				_abandon = 1
			if d["kind"] in ["winner", "ace"]:
				_anim[w] = {"seq": ["celebra"], "cuts": [], "t": 0.0, "len": 1.1}
			if d["kind"] in ["winner", "ace"] or int(d["rally"]) >= 12 or d.get("closed", "") != "":
				_cheer = 1.3  # la gente se para
			if d["kind"] in ["unforced", "double_fault"]:
				_anim[1 - w] = {"seq": ["bravo"], "cuts": [], "t": 0.0, "len": 1.2}
			# El público: el "uuuy" con el error fácil, el estadio de pie con el ganador bueno, aplausos con el resto.
			if d.get("how", "") == "net":
				_sound("red")
			if d["kind"] in ["unforced", "double_fault"]:
				_sound("uy", randf_range(0.95, 1.05))
			elif d["kind"] == "ace" or (d["kind"] == "winner" and int(d["rally"]) >= 8) or d.get("closed", "") != "":
				_sound("ovacion")
			else:
				_sound("aplauso", randf_range(0.95, 1.05))
			var names := {"ace": "¡ACE!", "winner": "GANADOR", "unforced": "ERROR", "forced": "ERROR FORZADO",
				"forced_missed": "NO ALCANZÓ", "double_fault": "DOBLE FALTA"}
			_pop(names.get(d["kind"], ""))
		"fault":
			_pop("FALTA")
			if d.get("how", "") == "net":
				_sound("red")
		"countered":
			_pop("¡LE LEYERON LA JUGADA!")
		"ability_fail":
			_pop("SE TIRÓ Y NO LLEGÓ")
		"ability":
			_flash[d["player"]] = 1.0
			_pop(str(d.get("name", "")).to_upper())
		"match":
			_pop("")
			_show_summary(d["winner"])
			finished.emit(d["winner"])


# ---------------------------------------------------------------- El resumen del final

## Lo que pasó en el partido, lado a lado: quién ganó, el marcador y los números de cada uno.
func _show_summary(w: int) -> void:
	_summary_t = 0.0
	var a = sim.players[0]
	var b = sim.players[1]
	var longest := 0
	for info in sim.point_log:
		longest = maxi(longest, int(info["rally"]))
	var head := _label(Vector2(88, 40), Color(1, 0.9, 0.4))
	head.size = Vector2(224, 10)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.text = "¡GANA %s!  %s" % [TenisData.player(sim.players[w].id)["short"], TenisBracket.score_text(sim.score, w)]
	_label(Vector2(212, 56), TenisData.player(a.id)["color"].lightened(0.3)).text = TenisData.player(a.id)["short"]
	_label(Vector2(268, 56), TenisData.player(b.id)["color"].lightened(0.3)).text = TenisData.player(b.id)["short"]
	var rows := [["GANADORES", a.stats["winners"], b.stats["winners"]], ["ACES", a.stats["aces"], b.stats["aces"]],
		["ERRORES", a.stats["ue"], b.stats["ue"]], ["DOBLE FALTA", a.stats["df"], b.stats["df"]],
		["HABILIDAD", a.stats["abilities"], b.stats["abilities"]], ["PUNTOS", a.stats["points"], b.stats["points"]]]
	for i in rows.size():
		var y := 70 + i * 12
		_label(Vector2(98, y), Color(0.8, 0.82, 0.9)).text = rows[i][0]
		_label(Vector2(216, y), Color(1, 0.95, 0.8)).text = str(rows[i][1])
		_label(Vector2(272, y), Color(1, 0.95, 0.8)).text = str(rows[i][2])
	_label(Vector2(98, 146), Color(0.8, 0.82, 0.9)).text = TenisData.caps("peloteo más largo: %d" % longest)
	var foot := _label(Vector2(88, 162), Color(0.85, 0.9, 1.0))
	foot.size = Vector2(224, 10)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.text = "E: SEGUIR"


func _pop(t: String) -> void:
	if t == "":
		_pop_l.text = ""
		return
	_pop_l.text = TenisData.caps(t)
	_pop_t = 1.4


func _update_hud() -> void:
	var s := sim.score
	var n0: String = TenisData.player(sim.players[0].id)["short"]
	var n1: String = TenisData.player(sim.players[1].id)["short"]
	var sets := ""
	for h in s.set_history:
		sets += " %d-%d" % [h[0], h[1]]
	if _abandon == 3:
		n0 = "EL"
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
	# De atrás para adelante: los jugadores, la red, la pelota y el recogebolas, cada uno en su fondo.
	var things := [[sim.players[1].pos.y, func() -> void: _draw_player(sim.players[1])],
		[minf(sim.players[0].pos.y - 0.01, 0.0), func() -> void: _draw_net()],
		[sim.players[0].pos.y, func() -> void: _draw_player(sim.players[0])],
		[sim.ball.y, func() -> void: _draw_ball()]]
	if setup.get("ballboy", false):
		things.append([_bb_pos.y, func() -> void: _draw_ballboy()])
		if _bb_ball != null:
			things.append([_bb_ball.y - 0.01, func() -> void: _draw_dead_ball()])
	things.sort_custom(func(a, b): return a[0] < b[0])
	for th in things:
		th[1].call()
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
	if _summary_t != -1.0:  # el resumen: un recuadro oscuro en el centro (los textos son Labels)
		draw_rect(Rect2(88, 34, 224, 140), Color(0.05, 0.05, 0.09, 0.93))  # a la derecha del tablero
		draw_rect(Rect2(88, 34, 224, 140), Color(0.5, 0.42, 0.3), false, 1.0)


func _draw_net() -> void:
	var dw := TenisData.HALF_W + 1.37
	var a := w2s(Vector2(-dw - 0.3, 0))
	var b := w2s(Vector2(dw + 0.3, 0))
	draw_line(a + Vector2(0, -5), b + Vector2(0, -5), Color(0.95, 0.95, 0.92), 1.0)
	for x in range(int(a.x), int(b.x), 2):
		draw_line(Vector2(x, a.y - 4), Vector2(x, a.y), Color(0.1, 0.1, 0.12, 0.6), 1.0)
	draw_rect(Rect2(a + Vector2(-1, -6), Vector2(2, 7)), Color(0.4, 0.4, 0.44))
	draw_rect(Rect2(b + Vector2(-1, -6), Vector2(2, 7)), Color(0.4, 0.4, 0.44))


func _draw_ballboy() -> void:
	var feet := w2s(_bb_pos).round()
	var pose := "agachado"
	if _bb_pick > 0.0:
		pose = "recoge"
	elif _bb_vel.length() > 0.5:
		pose = "corre%d" % (1 + int(_bb_d / 0.5) % 4)
	elif _bb_ball != null or _bb_has:
		pose = "listo"
	var row := 0 if _bb_vel.y < -0.1 else 1   # de espaldas si va para arriba
	draw_circle(feet + Vector2(0, 0.5), 3.0, Color(0, 0, 0, 0.28))
	var src := Rect2(Vector2(POSES.find(pose) * CELL.x, row * CELL.y), CELL)
	draw_texture_rect_region(EL_SHEET, Rect2(feet - FEET, CELL), src)
	if _bb_has and _bb_pick <= 0.0:  # la pelota en la mano
		draw_circle(feet + Vector2(5, -14), 1.5, Color(0.85, 0.95, 0.25))


func _draw_dead_ball() -> void:
	var g := w2s(_bb_ball)
	draw_circle(g + Vector2(0.5, 0.5), 1.6, Color(0, 0, 0, 0.3))
	draw_circle(g, 1.7, Color(0.85, 0.95, 0.25))
	if fmod(sim.t * 2.0, 1.0) < 0.5:  # titila un poquito: por aquí
		draw_rect(Rect2(g + Vector2(-0.5, -1.5), Vector2(1, 1)), Color(1, 1, 0.8))


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
			return "drive_atras" if sim.on_forehand(p) else "reves_atras"
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
