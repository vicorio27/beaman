class_name Ajedrez
extends CanvasLayer
## El ajedrez de Don Ramiro (blancas: abre siempre con el caballo del rey) y Don Octavio (negras), en el
## parque. Una partida de verdad (las reglas completas menos la captura al paso), que sigue corriendo
## aunque él no esté: cuando llega, la partida va por donde va (una jugada cada MINUTES_PER_MOVE
## minutos del juego desde la última vez). Se guarda en GameState.flags["ajedrez"].
##   await Ajedrez.open(self, false)   # mirar: juegan solos, una jugada cada rato; B se va
##   await Ajedrez.open(self, true)    # jugar: Don Ramiro se va al baño y él toma las blancas
## Mirar: [E] apura la jugada. Jugar: flechas mueven el cursor, [E] elige la pieza y la casilla,
## [Q] suelta la pieza (o, sin pieza, devuelve el puesto a Don Ramiro).
## Devuelve "blancas", "negras", "tablas" o "" (se fue antes del final).

signal _closed(result: String)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CELL := 18
const BOARD_AT := Vector2(12, 14)
const MINUTES_PER_MOVE := 4.0
const VALUE := {"p": 100, "n": 300, "b": 315, "r": 500, "q": 900, "k": 0}
const KNIGHT := [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]]
const KING := [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]]
const ROOK_DIRS := [[-1, 0], [1, 0], [0, -1], [0, 1]]
const BISHOP_DIRS := [[-1, -1], [-1, 1], [1, -1], [1, 1]]
const START := ["r", "n", "b", "q", "k", "b", "n", "r", "p", "p", "p", "p", "p", "p", "p", "p",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "",
	"P", "P", "P", "P", "P", "P", "P", "P", "R", "N", "B", "Q", "K", "B", "N", "R"]
## Lo que dicen mientras juegan.
const TALK_CAPTURE := [
	["DON OCTAVIO", "—Gracias. Ese no lo estaba usando, ¿cierto?"],
	["DON RAMIRO", "—Se lo cambio por el pan. ... No, por el pan no."],
	["DON OCTAVIO", "—Eso le pasa por pensar en la novia."],
	["DON RAMIRO", "—¡Tome! Treinta años esperando eso."],
	["DON OCTAVIO", "—¿Usted vio eso, mijo? Así se juega. Aprenda, que es gratis."],
]
const TALK_CHECK := [
	["DON RAMIRO", "—Jaque. Diga algo, Octavio. Lo que sea."],
	["DON OCTAVIO", "—Jaque, Ramiro. Respire. Así, por la nariz."],
	["DON RAMIRO", "—¡Jaque! ... Perdón: jaque. Sin gritar. Estamos en un parque."],
]
const TALK_IDLE := [
	["DON OCTAVIO", "—Mueva, Ramiro. Que la vida es corta y usted es lento."],
	["DON RAMIRO", "—Estoy pensando. ¿Usted sabe lo que es eso? No, claro."],
	["DON OCTAVIO", "—En 1974 le gané a un ruso. Bueno, era de Bucaramanga. Pero tenía cara de ruso."],
	["DON RAMIRO", "—Esta jugada la vi en la tele. En un documental de leones."],
	["DON OCTAVIO", "—Las palomas saben más ajedrez que usted. Y cagan mejor."],
]

var playing := false
var _st := {}        # {board, white, castle, plies, moves (notación), result}
var _cursor := 52
var _sel := -1
var _targets: Array = []
var _last := [-1, -1]
var _t := 0.0
var _root: Control
var _board: Control
var _info: Label
var _say: Label
var _say_t := 0.0
var _busy := false


static func open(parent: Node, play: bool) -> String:
	var ui := Ajedrez.new()
	ui.playing = play
	parent.get_tree().root.add_child(ui)
	var r: String = await ui._closed
	ui.queue_free()
	return r


# ---------------------------------------------------------------- La partida guardada

## La partida de hoy (una nueva cada día; si ya terminó, empiezan otra).
static func game_today() -> Dictionary:
	var f := GameState.flags
	var g: Dictionary = f.get("ajedrez", {})
	if g.is_empty() or int(g.get("day", -1)) != GameState.day or g.get("result", "") != "":
		g = {"day": GameState.day, "board": START.duplicate(), "white": true,
			"castle": {"K": true, "Q": true, "k": true, "q": true}, "plies": 0, "moves": [], "result": "",
			"at": TimeManager.minutes}
		f["ajedrez"] = g
	return g


## Lo que jugaron mientras él no estaba.
static func catch_up(g: Dictionary) -> void:
	var due := int((TimeManager.minutes - float(g.get("at", TimeManager.minutes))) / MINUTES_PER_MOVE)
	for i in mini(due, 60):
		if g["result"] != "":
			break
		var m: Array = best_move(g, 1)
		if m.is_empty():
			break
		apply(g, m)
	g["at"] = TimeManager.minutes


# ---------------------------------------------------------------- Las reglas

static func white_piece(p: String) -> bool:
	return p != "" and p == p.to_upper()


static func _on(r: int, c: int) -> bool:
	return r >= 0 and r < 8 and c >= 0 and c < 8


## ¿La casilla sq la ataca alguien del color by_white?
static func attacked(b: Array, sq: int, by_white: bool) -> bool:
	var r := sq / 8
	var c := sq % 8
	var pr := r + 1 if by_white else r - 1  # de dónde vendría un peón
	for dc in [-1, 1]:
		if _on(pr, c + dc) and b[pr * 8 + c + dc] == ("P" if by_white else "p"):
			return true
	for o in KNIGHT:
		if _on(r + o[0], c + o[1]) and b[(r + o[0]) * 8 + c + o[1]] == ("N" if by_white else "n"):
			return true
	for o in KING:
		if _on(r + o[0], c + o[1]) and b[(r + o[0]) * 8 + c + o[1]] == ("K" if by_white else "k"):
			return true
	for dirs in [[ROOK_DIRS, ["r", "q"]], [BISHOP_DIRS, ["b", "q"]]]:
		for d in dirs[0]:
			var rr: int = r + d[0]
			var cc: int = c + d[1]
			while _on(rr, cc):
				var p: String = b[rr * 8 + cc]
				if p != "":
					if white_piece(p) == by_white and p.to_lower() in dirs[1]:
						return true
					break
				rr += d[0]
				cc += d[1]
	return false


static func king_sq(b: Array, white: bool) -> int:
	return b.find("K" if white else "k")


static func in_check(g: Dictionary, white: bool) -> bool:
	return attacked(g["board"], king_sq(g["board"], white), not white)


## Las jugadas legales: [desde, hasta].
static func legal(g: Dictionary) -> Array:
	var b: Array = g["board"]
	var w: bool = g["white"]
	var out := []
	for sq in 64:
		var p: String = b[sq]
		if p == "" or white_piece(p) != w:
			continue
		var r := sq / 8
		var c := sq % 8
		match p.to_lower():
			"p":
				var dr := -1 if w else 1
				if _on(r + dr, c) and b[(r + dr) * 8 + c] == "":
					out.append([sq, (r + dr) * 8 + c])
					if r == (6 if w else 1) and b[(r + 2 * dr) * 8 + c] == "":
						out.append([sq, (r + 2 * dr) * 8 + c])
				for dc in [-1, 1]:
					if _on(r + dr, c + dc):
						var t: String = b[(r + dr) * 8 + c + dc]
						if t != "" and white_piece(t) != w:
							out.append([sq, (r + dr) * 8 + c + dc])
			"n", "k":
				for o in (KNIGHT if p.to_lower() == "n" else KING):
					if _on(r + o[0], c + o[1]):
						var t: String = b[(r + o[0]) * 8 + c + o[1]]
						if t == "" or white_piece(t) != w:
							out.append([sq, (r + o[0]) * 8 + c + o[1]])
			_:
				var dirs: Array = ROOK_DIRS if p.to_lower() == "r" else (BISHOP_DIRS if p.to_lower() == "b" else ROOK_DIRS + BISHOP_DIRS)
				for d in dirs:
					var rr: int = r + d[0]
					var cc: int = c + d[1]
					while _on(rr, cc):
						var t: String = b[rr * 8 + cc]
						if t != "" and white_piece(t) == w:
							break
						out.append([sq, rr * 8 + cc])
						if t != "":
							break
						rr += d[0]
						cc += d[1]
	# El enroque.
	var home := 60 if w else 4
	var cs: Dictionary = g["castle"]
	if b[home] == ("K" if w else "k") and not attacked(b, home, not w):
		if cs["K" if w else "k"] and b[home + 1] == "" and b[home + 2] == "" and b[home + 3] == ("R" if w else "r") \
				and not attacked(b, home + 1, not w) and not attacked(b, home + 2, not w):
			out.append([home, home + 2])
		if cs["Q" if w else "q"] and b[home - 1] == "" and b[home - 2] == "" and b[home - 3] == "" and b[home - 4] == ("R" if w else "r") \
				and not attacked(b, home - 1, not w) and not attacked(b, home - 2, not w):
			out.append([home, home - 2])
	# Que no deje al rey en jaque.
	var ok := []
	for m in out:
		var g2 := _copy(g)
		apply(g2, m, false)
		if not attacked(g2["board"], king_sq(g2["board"], w), not w):
			ok.append(m)
	return ok


static func _copy(g: Dictionary) -> Dictionary:
	return {"board": (g["board"] as Array).duplicate(), "white": g["white"], "castle": (g["castle"] as Dictionary).duplicate(),
		"plies": g["plies"], "moves": [], "result": ""}


## Hace la jugada (y, si record, la anota y mira si se acabó).
static func apply(g: Dictionary, m: Array, record := true) -> void:
	var b: Array = g["board"]
	var p: String = b[m[0]]
	var note := ""
	if record:
		note = _notation(g, m)
	b[m[1]] = p
	b[m[0]] = ""
	if p.to_lower() == "k" and absi(m[1] - m[0]) == 2:  # el enroque: la torre salta
		var rook_from: int = m[0] + (3 if m[1] > m[0] else -4)
		var rook_to: int = m[0] + (1 if m[1] > m[0] else -1)
		b[rook_to] = b[rook_from]
		b[rook_from] = ""
	if p.to_lower() == "p" and (m[1] / 8 == 0 or m[1] / 8 == 7):
		b[m[1]] = "Q" if white_piece(p) else "q"  # corona: dama, siempre (son viejos, no se complican)
	var cs: Dictionary = g["castle"]
	for k in [[60, "K"], [60, "Q"], [63, "K"], [56, "Q"], [4, "k"], [4, "q"], [7, "k"], [0, "q"]]:
		if m[0] == k[0] or m[1] == k[0]:
			cs[k[1]] = false
	g["white"] = not g["white"]
	g["plies"] = int(g["plies"]) + 1
	if not record:
		return
	(g["moves"] as Array).append(note)
	var next := legal(g)
	if next.is_empty():
		g["result"] = ("negras" if g["white"] else "blancas") if in_check(g, g["white"]) else "tablas"
	elif int(g["plies"]) >= 160:
		g["result"] = "tablas"


static func _notation(g: Dictionary, m: Array) -> String:
	var p: String = g["board"][m[0]]
	if p.to_lower() == "k" and absi(m[1] - m[0]) == 2:
		return "O-O" if m[1] > m[0] else "O-O-O"
	var letter: String = {"p": "", "n": "C", "b": "A", "r": "T", "q": "D", "k": "R"}[p.to_lower()]
	var takes: bool = g["board"][m[1]] != ""
	if takes and letter == "":
		letter = "abcdefgh"[m[0] % 8]  # el peón que come dice de qué columna viene
	return letter + ("x" if takes else "") + "abcdefgh"[m[1] % 8] + str(8 - m[1] / 8)


static func evaluate(g: Dictionary) -> float:
	var s := 0.0
	var b: Array = g["board"]
	for sq in 64:
		var p: String = b[sq]
		if p == "":
			continue
		var v: float = VALUE[p.to_lower()]
		var r := sq / 8
		var c := sq % 8
		if p.to_lower() in ["n", "b", "p"]:
			v += 12.0 - (absf(3.5 - r) + absf(3.5 - c)) * 3.0  # el centro
		if p.to_lower() == "p":
			v += (6 - r if white_piece(p) else r - 1) * 4.0  # avanzar
		s += v if white_piece(p) else -v
	return s if g["white"] else -s


static func _search(g: Dictionary, depth: int, alpha: float, beta: float) -> float:
	var moves := legal(g)
	if moves.is_empty():
		return -99999.0 if in_check(g, g["white"]) else 0.0
	if depth == 0:
		return evaluate(g)
	for m in moves:
		var g2 := _copy(g)
		apply(g2, m, false)
		var v := -_search(g2, depth - 1, -beta, -alpha)
		if v > alpha:
			alpha = v
		if alpha >= beta:
			break
	return alpha


## La jugada de un viejo: mira dos jugadas (o una, si está apurado) y le pone su gusto (un poco al azar).
static func best_move(g: Dictionary, depth := 2) -> Array:
	var moves := legal(g)
	if moves.is_empty():
		return []
	if g["white"] and int(g["plies"]) == 0:
		return [62, 45]  # Don Ramiro: el caballo del rey. Siempre. Treinta años.
	var best: Array = moves[0]
	var best_v := -INF
	for m in moves:
		var g2 := _copy(g)
		apply(g2, m, false)
		var v := -_search(g2, depth - 1, -INF, INF) + randf_range(-18.0, 18.0)
		if v > best_v:
			best_v = v
			best = m
	return best


# ---------------------------------------------------------------- La pantalla

func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_st = game_today()
	catch_up(_st)
	_root = Control.new()
	add_child(_root)
	var dim := ColorRect.new()
	dim.size = Vector2(320, 180)
	dim.color = Color(0.08, 0.1, 0.08, 0.92)
	_root.add_child(dim)
	_board = Control.new()
	_board.position = BOARD_AT
	_board.size = Vector2(CELL * 8, CELL * 8)
	_board.draw.connect(_draw_board)
	_root.add_child(_board)
	_info = _label(Vector2(164, 12), Color(0.95, 0.9, 0.78))
	_info.size = Vector2(118, 80)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say = _label(Vector2(164, 92), Color(0.8, 0.95, 0.75))
	_say.size = Vector2(118, 70)
	_say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_say.add_theme_constant_override("line_spacing", 1)
	var keys := _label(Vector2(12, 170), Color(0.55, 0.6, 0.5))
	keys.text = Controls.keys_in("[E] elegir  [Q] soltar / irse" if playing else "[E] que muevan  [Q] irse")
	if playing:
		_chat(["DON RAMIRO", "—Juegue usted, mijo, que me anda la próstata. Vuelvo en diez. No me la pierda."])
	elif int(_st["plies"]) > 0:
		_chat(["DON OCTAVIO", "—Llegó tarde, mijo: van %d jugadas. Siéntese, que lo bueno apenas empieza." % (int(_st["plies"]) / 2 + 1)])
	_refresh()


func _label(at: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	_root.add_child(l)
	return l


func _chat(line: Array) -> void:
	_say.text = "%s\n%s" % [line[0], line[1]]
	_say_t = 6.0


func _refresh() -> void:
	var moves: Array = _st["moves"]
	var lines := []  # las últimas cuatro jugadas: "7. Cf3 d5"
	var from := maxi(0, (moves.size() - 1) / 2 - 3)
	for n in range(from, (moves.size() + 1) / 2):
		lines.append("%d. %s %s" % [n + 1, moves[n * 2], moves[n * 2 + 1] if n * 2 + 1 < moves.size() else ""])
	var turn: String = "RAMIRO (blancas)" if _st["white"] else "OCTAVIO (negras)"
	if playing and _st["white"]:
		turn = "USTED (blancas)"
	var head: String = "TURNO: %s" % turn if _st["result"] == "" else {"blancas": "GANAN LAS BLANCAS", "negras": "GANAN LAS NEGRAS", "tablas": "TABLAS"}[_st["result"]]
	if _st["result"] == "" and in_check(_st, _st["white"]):
		head += "  ¡JAQUE!"
	_info.text = head + "\n" + "\n".join(lines)
	_board.queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_say_t -= delta
	if _say_t <= 0.0 and _say.text != "":
		_say.text = ""
	if _busy:
		return
	if Input.is_action_just_pressed("cancel"):
		if playing and _sel >= 0:
			_sel = -1
			_targets = []
			_board.queue_redraw()
			return
		_close("" if _st["result"] == "" else str(_st["result"]))
		return
	if _st["result"] != "":
		if Input.is_action_just_pressed("interact"):
			_close(str(_st["result"]))
		return
	var my_turn: bool = playing and _st["white"]
	if my_turn:
		_player_input()
	elif _t >= (1.4 if not playing else 0.6) or (not playing and Input.is_action_just_pressed("interact")):
		_t = 0.0
		_old_moves()


func _old_moves() -> void:
	_busy = true
	await get_tree().process_frame
	var m := best_move(_st, 2 if playing else 1)  # (mirando, más ligero: en el celular no se traba)
	_move(m)
	TimeManager.skip(MINUTES_PER_MOVE / 60.0)
	_st["at"] = TimeManager.minutes
	_busy = false


func _move(m: Array) -> void:
	if m.is_empty():
		return
	var cap: bool = _st["board"][m[1]] != ""
	apply(_st, m)
	_last = m
	if _st["result"] != "":
		_finale()
	elif in_check(_st, _st["white"]) and randf() < 0.7:
		_chat(TALK_CHECK.pick_random())
	elif cap and randf() < 0.5:
		_chat(TALK_CAPTURE.pick_random())
	elif randf() < 0.12:
		_chat(TALK_IDLE.pick_random())
	_refresh()


func _finale() -> void:
	match _st["result"]:
		"blancas":
			_chat(["DON RAMIRO" if not playing else "DON OCTAVIO", "—¡Jaque mate, Octavio! ¡Treinta años!" if not playing
				else "—... Mate. Me ganó un mudo. No le cuente a Ramiro. ... Ramiro, ¡no oiga!"])
		"negras":
			_chat(["DON OCTAVIO", "—Mate. El caballo del rey, Ramiro. Siempre el caballo del rey." if not playing
				else "—Mate, mijo. Juega como Ramiro: con fe y sin plan."])
		"tablas":
			_chat(["DON RAMIRO", "—Tablas. Como siempre. Treinta años de empates. Eso también es un matrimonio."])
	_say_t = 999.0


func _player_input() -> void:
	var moved := false
	if Input.is_action_just_pressed("move_left") and _cursor % 8 > 0:
		_cursor -= 1
		moved = true
	elif Input.is_action_just_pressed("move_right") and _cursor % 8 < 7:
		_cursor += 1
		moved = true
	elif Input.is_action_just_pressed("move_up") and _cursor >= 8:
		_cursor -= 8
		moved = true
	elif Input.is_action_just_pressed("move_down") and _cursor < 56:
		_cursor += 8
		moved = true
	elif Input.is_action_just_pressed("interact"):
		var p: String = _st["board"][_cursor]
		if _sel >= 0 and _targets.has(_cursor):
			_move([_sel, _cursor])
			_sel = -1
			_targets = []
			_t = 0.0
		elif p != "" and white_piece(p):
			_sel = _cursor
			_targets = []
			for m in legal(_st):
				if m[0] == _sel:
					_targets.append(m[1])
			if _targets.is_empty():
				_chat(["DON OCTAVIO", "—Esa no se puede mover, mijo. Está más quieta que Ramiro."])
				_sel = -1
		moved = true
	if moved:
		_board.queue_redraw()


func _close(r: String) -> void:
	GameState.ui_open = false
	GameState.block_input(0.3)
	set_process(false)
	_closed.emit(r)


# ---------------------------------------------------------------- El dibujo

func _draw_board() -> void:
	var light := Color(0.86, 0.8, 0.62)
	var dark := Color(0.42, 0.56, 0.36)
	_board.draw_rect(Rect2(-3, -3, CELL * 8 + 6, CELL * 8 + 6), Color(0.3, 0.2, 0.12))
	for sq in 64:
		var r := sq / 8
		var c := sq % 8
		var rect := Rect2(c * CELL, r * CELL, CELL, CELL)
		_board.draw_rect(rect, light if (r + c) % 2 == 0 else dark)
		if sq == _last[0] or sq == _last[1]:
			_board.draw_rect(rect, Color(0.95, 0.85, 0.3, 0.35))
		if _targets.has(sq):
			_board.draw_circle(rect.get_center(), 3.0, Color(0.15, 0.3, 0.15, 0.6))
		var p: String = _st["board"][sq]
		if p != "":
			_piece(p, Vector2(c * CELL + CELL / 2.0, r * CELL + CELL - 3))
	if playing:
		var cr := Rect2((_cursor % 8) * CELL, (_cursor / 8) * CELL, CELL, CELL)
		_board.draw_rect(cr, Color(1, 0.3, 0.3) if int(_t * 4) % 2 == 0 else Color(1, 0.8, 0.3), false, 2.0)
		if _sel >= 0:
			_board.draw_rect(Rect2((_sel % 8) * CELL, (_sel / 8) * CELL, CELL, CELL), Color(0.3, 0.6, 1.0), false, 2.0)
	for c in 8:  # las letras y los números
		_board.draw_string(FONT, Vector2(c * CELL + 5, CELL * 8 + 11), "abcdefgh"[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.6, 0.5))


## Una pieza, de pixeles: base, cuerpo y lo que la distingue. b = el pie (abajo, al centro).
func _piece(p: String, b: Vector2) -> void:
	var w := white_piece(p)
	var fill := Color(0.97, 0.94, 0.86) if w else Color(0.16, 0.13, 0.15)
	var line := Color(0.15, 0.1, 0.1) if w else Color(0.8, 0.76, 0.7)
	var pts: PackedVector2Array
	match p.to_lower():
		"p":
			pts = PackedVector2Array([b + Vector2(-5, 0), b + Vector2(5, 0), b + Vector2(3, -3), b + Vector2(2, -6), b + Vector2(-2, -6), b + Vector2(-3, -3)])
		"r":
			pts = PackedVector2Array([b + Vector2(-6, 0), b + Vector2(6, 0), b + Vector2(4, -3), b + Vector2(4, -9), b + Vector2(6, -9), b + Vector2(6, -12),
				b + Vector2(3, -12), b + Vector2(3, -10), b + Vector2(1, -10), b + Vector2(1, -12), b + Vector2(-1, -12), b + Vector2(-1, -10),
				b + Vector2(-3, -10), b + Vector2(-3, -12), b + Vector2(-6, -12), b + Vector2(-6, -9), b + Vector2(-4, -9), b + Vector2(-4, -3)])
		"n":
			pts = PackedVector2Array([b + Vector2(-6, 0), b + Vector2(6, 0), b + Vector2(4, -4), b + Vector2(4, -10), b + Vector2(1, -13), b + Vector2(-2, -12),
				b + Vector2(-6, -8), b + Vector2(-5, -6), b + Vector2(-1, -7), b + Vector2(-4, -3)])
		"b":
			pts = PackedVector2Array([b + Vector2(-5, 0), b + Vector2(5, 0), b + Vector2(3, -3), b + Vector2(4, -8), b + Vector2(0, -13), b + Vector2(-4, -8), b + Vector2(-3, -3)])
		"q":
			pts = PackedVector2Array([b + Vector2(-6, 0), b + Vector2(6, 0), b + Vector2(4, -4), b + Vector2(6, -12), b + Vector2(3, -8), b + Vector2(0, -13),
				b + Vector2(-3, -8), b + Vector2(-6, -12), b + Vector2(-4, -4)])
		"k":
			pts = PackedVector2Array([b + Vector2(-6, 0), b + Vector2(6, 0), b + Vector2(4, -4), b + Vector2(5, -10), b + Vector2(1, -10), b + Vector2(1, -12),
				b + Vector2(3, -12), b + Vector2(3, -14), b + Vector2(1, -14), b + Vector2(1, -16), b + Vector2(-1, -16), b + Vector2(-1, -14),
				b + Vector2(-3, -14), b + Vector2(-3, -12), b + Vector2(-1, -12), b + Vector2(-1, -10), b + Vector2(-5, -10), b + Vector2(-4, -4)])
	_board.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	_board.draw_polyline(closed, line, 1.0)
	if p.to_lower() == "n":
		_board.draw_rect(Rect2(b + Vector2(0, -10), Vector2(1, 1)), line)  # el ojo del caballo
	if p.to_lower() == "p":
		_board.draw_circle(b + Vector2(0, -8), 2.6, fill)
		_board.draw_arc(b + Vector2(0, -8), 2.6, 0, TAU, 10, line, 1.0)
