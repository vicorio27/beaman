class_name TenisScore
extends RefCounted
## El conteo del tenis: puntos (0, 15, 30, 40, ventaja / deuce, o "punto de oro" sin ventaja), juegos,
## desempate, sets y quién saca. Sin dibujo: lo usan la simulación (TenisSim) y las pruebas.
##   var s := TenisScore.new(TenisData.FORMATS["arcade"])
##   s.point_won(0)        # punto para el jugador 0
##   s.text()              # "15-0", "Deuce", "Ventaja ...", "Desempate 3-2"
## El formato es configurable (TenisData.FORMATS): juegos por set, en cuánto hay desempate, a cuántos
## puntos el desempate, sets para ganar, con o sin ventaja.

signal game_won(player: int)
signal set_won(player: int)
signal match_won(player: int)

var games_per_set := 6
var tiebreak_at := 6
var tiebreak_points := 7
var sets_to_win := 2
var no_ad := false

var points := [0, 0]        # puntos del juego (o del desempate) en curso
var games := [0, 0]         # juegos del set en curso
var sets := [0, 0]
var set_history: Array = [] # [[juegos 0, juegos 1], ...] de los sets terminados
var server := 0             # quién saca este punto
var tiebreak := false
var winner := -1            # -1: sigue el partido
var _set_first_server := 0  # quién sacó primero en este set (para el desempate y el set siguiente)
var _tb_first_server := 0


func _init(fmt: Dictionary = {}, first_server := 0) -> void:
	games_per_set = int(fmt.get("games_per_set", games_per_set))
	tiebreak_at = int(fmt.get("tiebreak_at", tiebreak_at))
	tiebreak_points = int(fmt.get("tiebreak_points", tiebreak_points))
	sets_to_win = int(fmt.get("sets_to_win", sets_to_win))
	no_ad = bool(fmt.get("no_ad", no_ad))
	server = first_server
	_set_first_server = first_server


func over() -> bool:
	return winner >= 0


## Gana el punto `p`. Devuelve qué cerró: "", "game", "set" o "match".
func point_won(p: int) -> String:
	assert(p == 0 or p == 1)
	if over():
		return "match"
	var o := 1 - p
	points[p] += 1
	if tiebreak:
		var total: int = points[0] + points[1]
		if points[p] >= tiebreak_points and points[p] - points[o] >= 2:
			return _win_game(p)
		# En el desempate: el primero saca uno, después cada uno saca dos.
		if total % 2 == 1:
			server = 1 - server
		return ""
	var done := false
	if no_ad:
		done = points[p] >= 4
	else:
		done = points[p] >= 4 and points[p] - points[o] >= 2
	if done:
		return _win_game(p)
	return ""


func _win_game(p: int) -> String:
	var was_tiebreak := tiebreak
	points = [0, 0]
	games[p] += 1
	game_won.emit(p)
	var o := 1 - p
	var set_done := false
	if was_tiebreak:
		set_done = true
	elif games[p] >= games_per_set and games[p] - games[o] >= 2:
		set_done = true
	if set_done:
		set_history.append([games[0], games[1]])
		sets[p] += 1
		games = [0, 0]
		tiebreak = false
		set_won.emit(p)
		if sets[p] >= sets_to_win:
			winner = p
			match_won.emit(p)
			return "match"
		# El set siguiente lo empieza quien recibió primero en el anterior (alternando, como siempre).
		var next := 1 - (_tb_first_server if was_tiebreak else _set_first_server)
		if not was_tiebreak:
			# Sin desempate, el saque simplemente sigue alternando juego a juego.
			next = 1 - server
		server = next
		_set_first_server = next
		return "set"
	if games[0] == tiebreak_at and games[1] == tiebreak_at:
		tiebreak = true
		server = 1 - server
		_tb_first_server = server
		return "game"
	server = 1 - server
	return "game"


## El lado desde donde se saca: "deuce" (derecha del que saca) o "ventaja" (izquierda).
func serve_side() -> String:
	var n: int = points[0] + points[1]
	return "deuce" if n % 2 == 0 else "ad"


## Punto de quiebre, de set o de partido para el que recibe (lo usa el estado de ánimo: presión).
func pressure_on(p: int) -> bool:
	var o := 1 - p
	if tiebreak:
		return points[o] >= tiebreak_points - 1 and points[o] > points[p]
	var game_point_o: bool = points[o] >= 3 and (no_ad or points[o] > points[p])
	return game_point_o and (server == p or games[o] >= games_per_set - 1)


func _call(n: int) -> String:
	return ["0", "15", "30", "40"][mini(n, 3)]


## El marcador del juego, como lo canta el juez (desde el que saca).
func text() -> String:
	if over():
		return "Partido"
	if tiebreak:
		return "Desempate %d-%d" % [points[server], points[1 - server]]
	var a: int = points[server]
	var b: int = points[1 - server]
	if a >= 3 and b >= 3 and not no_ad:
		if a == b:
			return "Deuce"
		return "Ventaja " + ("saque" if a > b else "resto")
	if no_ad and a == 3 and b == 3:
		return "Punto de oro"
	return "%s-%s" % [_call(a), _call(b)]
