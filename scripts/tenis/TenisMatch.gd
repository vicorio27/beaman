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
## raqueta (lo maneja el humano, con el dibujo de él: assets/tenis/el_<id>.png). Antes, exit_pro(how)
## muestra cómo se va (y deja la raqueta en el piso) y walk_in() lo lleva a él a recogerla; los dos
## avisan con exit_done().

signal finished(winner: int)
signal closed(winner: int)
signal abandon_now()
signal exit_done()

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
## La cancha en perspectiva (la misma cuenta que tools/art/draw_tenis_coliseo.py, que pinta el fondo):
## a lo ancho, de 10.5 px por metro en el fondo a 13.5 en el frente; a lo largo, 4.6.
const KX_FAR := 10.5
const KX_NEAR := 13.5
const SY := 4.6
const CENTER := Vector2(160, 104)
const BUFFER := 0.2

static var setup := {}

var sim: TenisSim
var _acc := 0.0
var _buffer := ""
var _buffer_t := 0.0
var _hud: CanvasLayer
var _rows: Array = []      # el tablero: una fila por jugador (nombre, juegos, puntos)
var _crowd: TenisPublico   # el fondo y la gente de las tribunas (se para, aplaude, hace la ola)
var _pop_l: Label
var _pop_t := 0.0
var _flash := {}  # golpes que brillan un momento (habilidad): player -> tiempo
## Los dibujos de los tenistas (tools/art/draw_tenistas.py): celdas de CELL, los pies en FEET; fila 0 de
## espaldas (el de abajo), fila 1 de frente (el de arriba). El orden de las columnas, y dónde queda la
## cabeza de la raqueta y la mano de la pelota en cada pose, vienen de assets/tenis/tenistas.json.
## Qué cuadro toca en cada momento lo decide TenisAnim (uno por jugador).
const CELL := Vector2(50, 48)
const FEET := Vector2(25, 46)
const BALL := Color(0.85, 0.95, 0.25)
const SNAP_T := 0.12       # al pegarle, la pelota sale de la raqueta y en este tiempo llega a donde va
static var _info := {}
static var _cols := {}
var _sheets := {}   # id -> Texture2D (los que no tienen dibujo, como "base", van con el muñeco)
var _key := {}      # id -> la hoja que tiene puesta ("monfiz"; después de take_over, "el_monfiz")
var _ta := [TenisAnim.new(0), TenisAnim.new(1)]
var _serve_held := {}      # lo que apretó el que saca al empezar el movimiento (TenisAnim.hold_serve)
var _snap := {}            # la pelota recién golpeada: {"off": de dónde sale (la raqueta), "t"}
# La estela del raquetazo: por dónde pasó la cabeza de la raqueta en el golpe (un arco claro que se
# apaga en TRAIL_T), y la de la pelota cuando va muy rápido.
const SWING := ["drive_baja", "drive_bajo", "drive", "drive_alto", "drive_fin1", "drive_fin",
	"reves_baja", "reves_bajo", "reves", "reves_alto", "reves_fin1", "reves_fin", "cortado", "cortado_fin",
	"saque_rasca", "saque", "saque_fin1", "saque_fin", "abajo", "dejada"]
const TRAIL_T := 0.13
const FAST := 17.0         # m/s: de ahí para arriba, la pelota deja estela
var _trail := [[], []]     # por jugador: [punto en la pantalla, edad] de la cabeza de la raqueta
var _trail_pose := ["", ""]  # (un punto por cuadro del golpe: si corre en la misma pose, no deja estela)
var _ball_trail := []      # dónde se vio la pelota los últimos cuadros
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

# El que se va (exit_pro). Cómo, según TenisHistoria.ABANDONOS[id]["salida"]:
#   camina, furia, tel, doblado: se va caminando hacia abajo (hacia nosotros), cada uno a su manera;
#   silla: se queda parado al lado de la silla del juez; toalla: se acuesta en una toalla, afuera;
#   tribuna: se mete en la tribuna, y la raqueta baja después; camilla / tabla: entran dos camilleros
#   y se lo llevan (en la camilla, o tieso como una tabla).
const CAMILLERO := preload("res://assets/tenis/camillero.png")
const OFF_Y := 26.0                                  # ya fuera de la pantalla, por abajo
const CHAIR := Vector2(TenisData.HALF_W + 3.2, -1.2)  # al pie de la silla del juez
var _exit := {}            # el que se va: {"how", "pos", "path", "i", "speed", "walk", "phase"...}
var _gone := false         # ya no se dibuja el de abajo (se fue y él no ha cogido la raqueta)
var _stay := {}            # el que se quedó mirando (Bublikov, Yokovich): {"pos", "pose", "towel"}
var _racket = null         # Vector2: la raqueta en el piso
var _broken := []          # las rotas de Kyrgistán
var _fly := {}             # la raqueta que baja de la tribuna: {"from", "to", "t"}
var _walking := false      # él, yendo por la raqueta
var _pro_tex: Texture2D    # el dibujo del que se fue (después de take_over, su hoja es la de él)

# Los sonidos (tools/audio/tenis_audio.py): la raqueta, el bote, la red y el público.
const SFX := ["golpe", "golpe_duro", "bote", "red", "aplauso", "ovacion", "uy"]
const SFX_DB := {"golpe": -4.0, "golpe_duro": -2.0, "bote": -12.0, "red": -6.0, "aplauso": -10.0, "ovacion": -7.0, "uy": -8.0}
var _sfx := {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_crowd = TenisPublico.new()
	add_child(_crowd)
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
			_key[p.id] = p.id
		_ta[p.idx].persona = p.id
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


## Que se vea cómo se va el de abajo (ver _exit). Cuando ya no está (y la raqueta quedó en el piso),
## emite exit_done().
func exit_pro(how: String) -> void:
	var p0: Vector2 = sim.players[0].pos
	var dw := TenisData.HALF_W + 1.37
	_gone = true
	_racket = p0
	_pro_tex = _sheets.get(sim.players[0].id)
	_exit = {"how": how, "pos": p0, "path": [p0 + Vector2(0.6, 2.0), Vector2(p0.x * 0.4 + 1.5, OFF_Y)],
		"i": 0, "speed": 1.8, "walk": ["camina1", "camina2", "camina3", "camina4"], "d": 0.0, "vel": Vector2.ZERO,
		"phase": "va", "t": 0.0, "lift": 0.0, "fade": 1.0, "pose": "parado"}
	match how:
		"furia":  # las dos rotas, tiradas; la tercera, entera. Y se va rápido.
			_broken = [p0 + Vector2(-1.0, 0.5), p0 + Vector2(0.9, -0.6)]
			_exit["speed"] = 3.4
		"tel":
			_exit["walk"] = ["tel1", "tel2"]
			_exit["speed"] = 1.5
		"doblado":
			_exit["walk"] = ["doblado", "doblado"]
			_exit["speed"] = 1.1
		"silla":
			_exit["path"] = [Vector2(p0.x * 0.5 + 3.0, 6.0), CHAIR]
			_exit["speed"] = 2.0
		"toalla":
			_exit["path"] = [Vector2(-dw - 1.1, 7.5)]
			_exit["speed"] = 1.3
		"tribuna":
			_exit["path"] = [Vector2(-dw - 4.2, p0.y - 4.5)]
			_exit["speed"] = 3.2
			_racket = null
		"camilla", "tabla":  # entran los dos camilleros por abajo
			_exit["phase"] = "vienen"
			_exit["pose"] = "acostado" if how == "camilla" else "parado"
			_exit["c"] = [Vector2(p0.x - 1.2, OFF_Y), Vector2(p0.x + 1.2, OFF_Y + 0.8)]
			_exit["speed"] = 2.6
			_exit["cd"] = 0.0
			_racket = p0 + Vector2(0.4, 1.4)


func _exit_step(delta: float) -> void:
	var e := _exit
	e["t"] = float(e["t"]) + delta
	match str(e["phase"]):
		"va":
			if _follow(e, delta):
				_exit_arrived()
		"vienen":  # los camilleros, hasta la cabeza y los pies
			var p0: Vector2 = e["pos"]
			var home := [p0 + Vector2(-1.2, 0.1), p0 + Vector2(1.2, 0.1)]
			var ok := true
			for k in 2:
				var c: Vector2 = e["c"][k]
				e["c"][k] = c.move_toward(home[k], 3.2 * delta)
				ok = ok and c.distance_to(home[k]) < 0.05
			e["cd"] = float(e["cd"]) + 3.2 * delta
			if ok:
				e["phase"] = "alza"
				e["t"] = 0.0
		"alza":  # lo acuestan (Pecador: tieso) y lo levantan
			e["pose"] = "acostado"
			e["lift"] = minf(11.0, float(e["t"]) * 22.0)
			if float(e["t"]) > 0.8:
				var p0: Vector2 = e["pos"]
				e["path"] = [Vector2(p0.x, OFF_Y)]
				e["i"] = 0
				e["phase"] = "llevan"
		"llevan":
			var done := _follow(e, delta)
			var at: Vector2 = e["pos"]
			e["c"] = [at + Vector2(-1.2, 0.1), at + Vector2(1.2, 0.1)]
			e["cd"] = float(e["d"])
			if done:
				_exit_finish()
		"sube":  # Tiafuego, cargado por la tribuna: sube y se pierde entre la gente
			e["pose"] = "brazos"
			e["lift"] = float(e["t"]) * 16.0
			e["fade"] = clampf(1.0 - (float(e["t"]) - 0.6) / 1.2, 0.0, 1.0)
			if float(e["fade"]) <= 0.0:
				_fly = {"from": e["pos"], "to": sim.players[0].pos, "t": 0.0}
				_exit = {}


func _exit_arrived() -> void:
	var e := _exit
	match str(e["how"]):
		"silla":
			_stay = {"pos": e["pos"], "pose": "parado", "towel": false}
			_exit_finish()
		"toalla":
			_stay = {"pos": e["pos"], "pose": "acostado", "towel": true}
			_exit_finish()
		"tribuna":
			e["phase"] = "sube"
			e["t"] = 0.0
		_:
			_exit_finish()


func _exit_finish() -> void:
	_exit = {}
	exit_done.emit()


## Sigue el camino de `e` (e["path"] desde e["i"]); true cuando llegó al final.
func _follow(e: Dictionary, delta: float) -> bool:
	var path: Array = e["path"]
	var i: int = e["i"]
	if i >= path.size():
		e["vel"] = Vector2.ZERO
		return true
	var pos: Vector2 = e["pos"]
	var tgt: Vector2 = path[i]
	var step := float(e["speed"]) * delta
	e["vel"] = (tgt - pos).normalized() * float(e["speed"])
	if pos.distance_to(tgt) <= step:
		e["pos"] = tgt
		e["i"] = i + 1
	else:
		e["pos"] = pos + (tgt - pos).normalized() * step
	e["d"] = float(e["d"]) + step
	return false


## La raqueta que baja de la tribuna, de mano en mano (un arco), hasta el puesto del que se fue.
func _fly_step(delta: float) -> void:
	_fly["t"] = float(_fly["t"]) + delta / 1.3
	if float(_fly["t"]) >= 1.0:
		_racket = _fly["to"]
		_fly = {}
		exit_done.emit()


## Él va por la raqueta (desde donde esté), se agacha, la coge y queda en ese puesto. Emite exit_done().
func walk_in() -> void:
	_walking = true
	_bb_ball = null
	_bb_has = false
	_bb_pick = 0.0
	if _racket == null:
		_racket = sim.players[0].pos


func _walk_step(delta: float) -> void:
	var tgt: Vector2 = _racket if _racket != null else _bb_pos
	if _bb_pick > 0.0:
		_bb_pick -= delta
		_bb_vel = Vector2.ZERO
		if _bb_pick <= 0.25:
			_racket = null
		if _bb_pick <= 0.0:
			_bb_pick = 0.0
			_walking = false
			sim.players[0].pos = _bb_pos   # juega desde ahí
			exit_done.emit()
		return
	var to := tgt + Vector2(-0.35, -0.15) - _bb_pos  # se para al lado, no encima
	var step := BB_SPEED * 0.55 * delta
	if to.length() <= step:
		_bb_pos += to
		_bb_vel = Vector2.ZERO
		_bb_pick = 0.6
	else:
		_bb_vel = to.normalized() * BB_SPEED * 0.55
		_bb_pos += _bb_vel * delta
		_bb_d += step


## Le pasa la raqueta: desde ahora lo maneja el humano, con el dibujo de él.
func take_over() -> void:
	_gone = false
	_racket = null
	setup["ai0"] = false
	setup["ballboy"] = false
	_bb_ball = null
	_bb_has = false
	_abandon = 3
	var pid: String = sim.players[0].id
	var path := "res://assets/tenis/el_%s.png" % pid
	if ResourceLoader.exists(path):
		_sheets[pid] = load(path)
		_key[pid] = "el_" + pid
	_ta[0] = TenisAnim.new(0)
	_ta[0].persona = "el"   # con la raqueta de otro, pero los gestos son los de él
	_buffer = ""
	MusicDirector.force("tenis_el")  # él con la raqueta: el mismo tema, más rápido y un tono arriba
	_crowd.ola()                     # y el público, que no sabe quién es, le hace la ola


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
	if not _exit.is_empty():
		_exit_step(delta)
	if not _fly.is_empty():
		_fly_step(delta)
	if _walking:
		_walk_step(delta)
	elif setup.get("ballboy", false):
		_ballboy(delta)
	_acc += minf(delta, 0.1)
	while _acc >= TenisSim.DT:
		_acc -= TenisSim.DT
		if _abandon == 2 or (_bb_ball != null or _bb_has) and sim.state == "point_over" and sim.wait < 0.1:
			_acc = 0.0  # el saque que sigue espera la pelota (o al que va a terminar el partido)
			break
		var i0: Dictionary = TenisAI.think(sim, 0) if setup.get("ai0", false) else _human_input()
		var inputs := [i0, TenisAI.think(sim, 1)]
		if sim.state == "serve":
			TenisAnim.hold_serve(_ta, sim, inputs, _serve_held)
		sim.step(inputs)
	_pop_t -= delta
	if _pop_t <= 0.0:
		_pop_l.text = ""
	for k in _flash.keys():
		_flash[k] -= delta
	for i in 2:
		_ta[i].update(delta, sim.players[i], sim)
		_track_swing(i, delta)
	_track_ball()
	if not _snap.is_empty():
		_snap["t"] = float(_snap["t"]) + delta
		if float(_snap["t"]) > SNAP_T:
			_snap = {}
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
			TenisAnim.on_hit(_ta, sim, d)
			# La pelota sale de la cabeza de la raqueta (donde quedó en el cuadro del contacto).
			var rk = _meta_at(p, "rk", _ta[p.idx].contact_pose())
			if rk != null:
				_snap = {"off": rk - _ball_screen(), "t": 0.0}
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
				_ta[w].celebrate()
			if d["kind"] in ["unforced", "double_fault"]:
				_ta[1 - w].lament()
			# El público: el "uuuy" con el error fácil, el estadio de pie con el ganador bueno, aplausos con el resto.
			if d.get("how", "") == "net":
				_sound("red")
			# Y la gente: los que estaban cerca del punto se paran primero.
			var at := w2s(Vector2(sim.ball.x, sim.ball.y)).x
			if d["kind"] in ["unforced", "double_fault"]:
				_sound("uy", randf_range(0.95, 1.05))
				_crowd.uy()
			elif d["kind"] == "ace" or (d["kind"] == "winner" and int(d["rally"]) >= 8) or d.get("closed", "") != "":
				_sound("ovacion")
				_crowd.cheer(0.9, at)
			else:
				_sound("aplauso", randf_range(0.95, 1.05))
				if d["kind"] == "winner" or int(d["rally"]) >= 12:
					_crowd.cheer(0.45, at)
				else:
					_crowd.clap()
			if d.get("closed", "") in ["set", "match"]:
				_crowd.ola()
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
	var first := _hud.get_child_count()
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
	foot.text = Controls.keys_in("E: SEGUIR")
	# En el celular, la franja de la derecha es de los botones: el resumen se corre a la izquierda,
	# encima de donde estaba el tablero (que se esconde: el marcador ya va en el título).
	for i in range(first, _hud.get_child_count()):
		(_hud.get_child(i) as Control).position.x += _summary_dx()
	if Controls.touch():
		for r in _rows:
			r.visible = false


func _summary_dx() -> float:
	return -26.0 if Controls.touch() else 0.0


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
	# (El fondo y la gente los pinta _crowd, detrás.)
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
		[sim.players[1].pos.y + 0.001, func() -> void: _draw_trail(1)],
		[sim.players[0].pos.y + 0.001, func() -> void: _draw_trail(0)],
		[minf(sim.players[0].pos.y - 0.01, 0.0), func() -> void: _draw_net()],
		[sim.ball.y, func() -> void: _draw_ball()]]
	if not _gone:
		things.append([sim.players[0].pos.y, func() -> void: _draw_player(sim.players[0])])
	_exit_things(things)
	if setup.get("ballboy", false):
		things.append([_bb_pos.y, func() -> void: _draw_ballboy()])
		if _bb_ball != null:
			things.append([_bb_ball.y - 0.01, func() -> void: _draw_dead_ball()])
	things.sort_custom(func(a, b): return a[0] < b[0])
	for th in things:
		th[1].call()
	# El tablero (arriba a la izquierda): el recuadro; los nombres y puntos son Labels encima. Debajo de
	# cada nombre, el cansancio (verde) y el medidor de la habilidad (naranja).
	if _summary_t != -1.0 and Controls.touch():
		_draw_summary_box()
		return
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
	if _summary_t != -1.0:
		_draw_summary_box()


## El resumen: un recuadro oscuro a la derecha del tablero (los textos son Labels).
func _draw_summary_box() -> void:
	var box := Rect2(88 + _summary_dx(), 34, 224, 140)
	draw_rect(box, Color(0.05, 0.05, 0.09, 0.93))
	draw_rect(box, Color(0.5, 0.42, 0.3), false, 1.0)


## Lo de la salida, en el orden de fondo: el que se va, los camilleros, el que se quedó y las raquetas.
func _exit_things(things: Array) -> void:
	var tex := _pro_tex
	if tex == null:
		return
	if _racket != null:
		things.append([float(_racket.y) - 0.02, func() -> void: _cell(tex, _racket, "suelta", 1)])
	for b in _broken:
		things.append([float(b.y) - 0.02, func() -> void: _cell(tex, b, "rota", 1)])
	if not _fly.is_empty():
		var f := float(_fly["t"])
		var at: Vector2 = Vector2(_fly["from"]).lerp(_fly["to"], f)
		things.append([99.0, func() -> void: _cell(tex, at, "suelta", 1, sin(f * PI) * 26.0, 1.0, false)])
	if not _stay.is_empty():
		things.append([float(_stay["pos"].y), func() -> void: _draw_stay(tex)])
	if _exit.is_empty():
		return
	var pos: Vector2 = _exit["pos"]
	things.append([pos.y, func() -> void: _draw_exit(tex)])
	if _exit.has("c"):
		for k in 2:
			var c: Vector2 = _exit["c"][k]
			things.append([c.y + 0.01 * k, func() -> void: _draw_carrier(k)])


func _draw_stay(tex: Texture2D) -> void:
	if _stay["towel"]:  # la toalla blanca, con la raya del torneo
		var g := w2s(_stay["pos"]).round()
		draw_rect(Rect2(g + Vector2(-15, -6), Vector2(30, 7)), Color(0.94, 0.94, 0.9))
		draw_rect(Rect2(g + Vector2(-15, -2), Vector2(30, 1)), Color(0.6, 0.15, 0.17))
		draw_rect(Rect2(g + Vector2(-15, -6), Vector2(30, 7)), Color(0.16, 0.13, 0.17), false, 1.0)
	_cell(tex, _stay["pos"], _stay["pose"], 1, 0.0, 1.0, not _stay["towel"])


## Un camillero (k = 0: el de la cabeza; 1: el de los pies). De espaldas mientras entra.
func _draw_carrier(k: int) -> void:
	var e := _exit
	var phase := str(e["phase"])
	var pose := "parado" if phase == "alza" else "camina%d" % (1 + (int(float(e["cd"]) / 0.3) + 2 * k) % 4)
	_cell(CAMILLERO, e["c"][k], pose, 0 if phase == "vienen" else 1)


func _draw_exit(tex: Texture2D) -> void:
	var e := _exit
	var pose := str(e["pose"])
	var moving: bool = Vector2(e["vel"]).length() > 0.1 and str(e["phase"]) == "va"
	var v := Vector2(e["vel"])
	if moving and absf(v.x) > absf(v.y) and e["walk"].size() == 4:  # de lado: caminando de perfil
		pose = "caminal%d_%s" % [1 + int(float(e["d"]) / 0.18) % 8, "d" if v.x > 0.0 else "i"]
	elif moving:
		var walk: Array = e["walk"]
		pose = walk[int(float(e["d"]) / (0.3 if walk.size() == 4 else 0.45)) % walk.size()]
	var row := 0 if moving and v.y < -0.1 else 1
	var lift := float(e["lift"])
	if e.has("c") and lift > 0.0 and str(e["how"]) == "camilla":  # la camilla: los palos y la lona
		var g := w2s(e["pos"]).round()
		draw_line(g + Vector2(-17, -13), g + Vector2(17, -13), Color(0.55, 0.42, 0.3), 1.0)
		draw_rect(Rect2(g + Vector2(-12, -15), Vector2(24, 3)), Color(0.86, 0.88, 0.9))
		draw_rect(Rect2(g + Vector2(-12, -15), Vector2(24, 3)), Color(0.16, 0.13, 0.17), false, 1.0)
	if str(e["how"]) == "doblado":  # Fedorer: cada paso, un quejidito (se sacude un pixel)
		lift += 1.0 if int(float(e["d"]) / 0.3) % 2 == 0 else 0.0
	_cell(tex, e["pos"], pose, row, lift, float(e["fade"]), lift == 0.0)


## Una celda de una hoja (pose y fila) con los pies en `at` (metros), `lift` px más arriba.
func _cell(tex: Texture2D, at: Vector2, pose: String, row: int, lift := 0.0, alpha := 1.0, shadow := true) -> void:
	var feet := w2s(at).round()
	if shadow:
		draw_circle(feet + Vector2(0, 0.5), 3.5, Color(0, 0, 0, 0.28 * alpha))
	var src := Rect2(Vector2(col(pose) * CELL.x, row * CELL.y), CELL)
	draw_texture_rect_region(tex, Rect2(feet - FEET - Vector2(0, roundf(lift)), CELL), src, Color(1, 1, 1, alpha))


func _draw_net() -> void:
	var dw := TenisData.HALF_W + 1.37
	var a := w2s(Vector2(-dw - 0.3, 0))
	var b := w2s(Vector2(dw + 0.3, 0))
	var nh := roundf(zh(0.914))   # la red, en la misma escala que la altura de la pelota: a la cadera
	for x in range(int(a.x), int(b.x), 2):  # la malla
		draw_line(Vector2(x, a.y - nh + 1), Vector2(x, a.y), Color(0.08, 0.08, 0.1, 0.38), 1.0)
	for k in range(3, int(nh), 3):
		draw_line(Vector2(a.x, a.y - k), Vector2(b.x, a.y - k), Color(0.08, 0.08, 0.1, 0.22), 1.0)
	draw_line(a + Vector2(0, -nh), b + Vector2(0, -nh), Color(0.95, 0.95, 0.92), 1.0)  # la cinta
	draw_rect(Rect2(a + Vector2(-1, -nh - 1), Vector2(2, nh + 2)), Color(0.4, 0.4, 0.44))
	draw_rect(Rect2(b + Vector2(-1, -nh - 1), Vector2(2, nh + 2)), Color(0.4, 0.4, 0.44))


func _draw_ballboy() -> void:
	var feet := w2s(_bb_pos).round()
	var pose := "agachado"
	if _bb_pick > 0.0:
		pose = "recoge"
	elif _bb_vel.length() > 0.5:
		if absf(_bb_vel.x) > absf(_bb_vel.y) * 0.9:
			pose = "lado%d_%s" % [1 + int(_bb_d / TenisAnim.LADO_M) % 8, "d" if _bb_vel.x > 0.0 else "i"]
		else:
			pose = "corre%d" % (1 + int(_bb_d / TenisAnim.CORRE_M) % 8)
	elif _bb_ball != null or _bb_has:
		pose = "listo"
	var row := 0 if _bb_vel.y < -0.1 else 1   # de espaldas si va para arriba
	draw_circle(feet + Vector2(0, 0.5), 3.0, Color(0, 0, 0, 0.28))
	var src := Rect2(Vector2(col(pose) * CELL.x, row * CELL.y), CELL)
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
	if _gone:
		return
	if sim.state == "serve":
		_draw_toss()
		return
	if not sim.live:
		return
	draw_circle(w2s(Vector2(sim.ball.x, sim.ball.y)), 1.6, Color(0, 0, 0, 0.35))  # la sombra: dónde está de verdad
	var up := _ball_screen()
	if not _snap.is_empty():
		up += Vector2(_snap["off"]) * clampf(1.0 - float(_snap["t"]) / SNAP_T, 0.0, 1.0)
	if Vector2(sim.bvel.x, sim.bvel.y).length() > FAST:  # rápida: deja estela
		for k in range(_ball_trail.size() - 1, 0, -1):
			draw_circle(_ball_trail[k], 1.5 - k * 0.2, Color(BALL, 0.36 - k * 0.09))
	_ball_at(up)


## La cabeza de la raqueta mientras pega (de que baja a que termina): se guarda por dónde va pasando.
func _track_swing(i: int, delta: float) -> void:
	var tr: Array = _trail[i]
	for e in tr:
		e[1] = float(e[1]) + delta
	while not tr.is_empty() and float(tr[0][1]) > TRAIL_T:
		tr.pop_front()
	var a: TenisAnim = _ta[i]
	if a.pose == _trail_pose[i]:
		return
	_trail_pose[i] = a.pose
	if not a.pose in SWING:
		return
	var at = _meta_at(sim.players[i], "rk", a.pose)
	if at != null:
		tr.append([at, 0.0])


## El arco: una curva suave (Catmull-Rom) por los puntos, más clara hacia la raqueta, que se apaga.
func _draw_trail(i: int) -> void:
	var tr: Array = _trail[i]
	if tr.size() < 2:
		return
	var n := tr.size()
	var prev: Vector2 = tr[0][0]
	for k in n - 1:
		var p0: Vector2 = tr[maxi(k - 1, 0)][0]
		var p1: Vector2 = tr[k][0]
		var p2: Vector2 = tr[k + 1][0]
		var p3: Vector2 = tr[mini(k + 2, n - 1)][0]
		var fade := 1.0 - float(tr[k + 1][1]) / TRAIL_T
		for s in range(1, 5):
			var u := s / 4.0
			var q := 0.5 * (2.0 * p1 + (p2 - p0) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * u * u * u)
			var along := (k + u) / float(n - 1)
			draw_line(prev, q, Color(1, 1, 0.9, 0.5 * fade * along), 2.0 if along > 0.5 else 1.0)
			prev = q


## Dónde se vio la pelota (para la estela, si va rápido).
func _track_ball() -> void:
	if not sim.live or sim.state != "rally" or _gone:
		_ball_trail.clear()
		return
	var up := _ball_screen()
	if not _snap.is_empty():
		up += Vector2(_snap["off"]) * clampf(1.0 - float(_snap["t"]) / SNAP_T, 0.0, 1.0)
	_ball_trail.push_front(up)
	if _ball_trail.size() > 4:
		_ball_trail.pop_back()


func _ball_at(at: Vector2) -> void:
	draw_circle(at, 1.7, BALL)
	draw_rect(Rect2(at - Vector2(0.5, 1), Vector2(1, 1)), Color(1, 1, 0.8))


## Dónde se ve la pelota de la simulación: sobre su sombra, zh(z) más arriba.
func _ball_screen() -> Vector2:
	return w2s(Vector2(sim.ball.x, sim.ball.y)) - Vector2(0, zh(sim.ball.z))


## La pelota del saque, en la mano del que saca: botándola mientras espera; al sacar, en la mano hasta
## que la tira, y por el aire (sube y baja) hasta donde la encuentra la raqueta.
func _draw_toss() -> void:
	var s = sim.players[sim.score.server]
	var a: TenisAnim = _ta[s.idx]
	var feet := w2s(s.pos).round()
	var at = null
	if a.serve_t < 0.0:
		var hand = _meta_at(s, "hl", "saque_bota1")
		if hand != null:
			var u := a.bounce_u()
			at = Vector2(hand.x, feet.y - 1.0).lerp(hand, pow(2.0 * u - 1.0, 2.0))
	elif a.underarm or a.serve_t < TenisAnim.TOSS:
		at = _meta_at(s, "hl", a.pose)
	else:
		var from = _meta_at(s, "hl", "saque_lanza")
		var to = _meta_at(s, "rk", "saque")
		if from != null and to != null:
			var u := clampf((a.serve_t - TenisAnim.TOSS) / (TenisAnim.CONTACT - TenisAnim.TOSS), 0.0, 1.0)
			at = Vector2(from).lerp(to, u) - Vector2(0, 26.0 * 4.0 * u * (1.0 - u))
	if at == null:  # (sin dibujo: la pelota de la simulación)
		at = _ball_screen()
	draw_circle(Vector2(at.x, feet.y), 1.4, Color(0, 0, 0, 0.3))
	_ball_at(at)


## Un punto del cuadro `pose` del jugador (kind: "rk" la cabeza de la raqueta, "hl" la mano de la pelota),
## en la pantalla; null si esa hoja no lo tiene.
func _meta_at(p, kind: String, pose: String):
	var m = info()["sheets"].get(_key.get(p.id, ""), {}).get(kind, {}).get(pose)
	if m == null:
		return null
	var r := 0 if p.idx == 0 else 1
	return w2s(p.pos).round() - FEET + Vector2(float(m[2 * r]), float(m[2 * r + 1]))


## La altura en la pantalla (px) de algo a z metros del piso: 16 px por metro abajo (los jugadores miden
## unos 30), cada vez menos arriba (si no, un globo se sale de la pantalla).
static func zh(z: float) -> float:
	return 16.0 * z / (1.0 + z / 8.0)


static func info() -> Dictionary:
	if _info.is_empty():
		_info = (load("res://assets/tenis/tenistas.json") as JSON).data
		var poses: Array = _info["poses"]
		for i in poses.size():
			_cols[poses[i]] = i
	return _info


## La columna de una pose en las hojas.
static func col(pose: String) -> int:
	info()
	return int(_cols.get(pose, 0))


func _draw_player(p) -> void:
	var tex: Texture2D = _sheets.get(p.id)
	if tex != null:
		var feet := w2s(p.pos).round()
		if _flash.get(p.idx, 0.0) > 0.0:
			draw_circle(feet - Vector2(0, 10), 11.0, Color(1, 0.8, 0.3, 0.28))
		draw_circle(feet + Vector2(0, 0.5), 3.5, Color(0, 0, 0, 0.28))
		var src := Rect2(Vector2(col(_ta[p.idx].pose) * CELL.x, (0 if p.idx == 0 else 1) * CELL.y), CELL)
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
