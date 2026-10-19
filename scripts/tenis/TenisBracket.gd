class_name TenisBracket
extends RefCounted
## El cuadro del torneo, sin dibujo: quién juega contra quién, quién pasa y quién sale. Lo dibuja
## TenisTorneo.gd; lo prueban las pruebas sin ventana (tools/tests/tenis_tests.gd).
##   var b := TenisBracket.new(TenisData.TOURNAMENT["entrants"])   # en orden de siembra (el 1 primero)
##   var m := b.next_match()          # {"round", "slot", "a", "b", ...} o {} si se acabó
##   b.report(m, ganador, "4-2")
##   b.champion()                     # "" mientras no haya
## Con cualquier número de jugadores: el cuadro es la potencia de 2 más grande que cabe, y los que
## sobran juegan una previa (los peores sembrados entre ellos). Con 10: del 7 al 10 juegan la previa
## (7 contra 10, 8 contra 9) y los ganadores entran a cuartos en el puesto del 7 y del 8.
## Se guarda y se carga con to_dict() / from_dict() (para GameState).

## El orden de los puestos en un cuadro (el 1 arriba, el 2 abajo, para que solo se crucen en la final).
static func seed_order(size: int) -> Array:
	var order := [1]
	while order.size() < size:
		var n := order.size() * 2
		var next := []
		for s in order:
			next.append(s)
			next.append(n + 1 - s)
		order = next
	# La mitad de abajo, al revés por parejas: así el 2 queda al fondo (como en los cuadros de verdad).
	var half := order.size() / 2
	if half >= 2:
		var bottom := []
		for k in range(order.size() - 2, half - 1, -2):
			bottom.append(order[k])
			bottom.append(order[k + 1])
		order = order.slice(0, half) + bottom
	return order


## El nombre de cada ronda, contando desde la final.
static func round_name(from_end: int) -> String:
	return ["Final", "Semifinal", "Cuartos", "Octavos", "Dieciseisavos"][mini(from_end, 4)]


var entrants: Array = []   # los ids, en orden de siembra
var rounds: Array = []     # cada ronda: {"name", "matches": [{"a", "b", "winner", "score", "slot"}]}


func _init(ids: Array = []) -> void:
	if ids.is_empty():
		return
	entrants = ids.duplicate()
	var n := ids.size()
	var size := 1
	while size * 2 <= n:
		size *= 2
	var playins := n - size
	# La previa: el que entra en el puesto de cada sembrado de abajo, sale de un partido.
	var feeds := {}   # sembrado (1..size) -> índice del partido de la previa que lo decide
	if playins > 0:
		var pre := []
		for i in playins:
			var hi := size - playins + 1 + i        # el sembrado de arriba de los que juegan la previa
			var lo := n - i                          # contra el peor que quede
			pre.append({"a": ids[hi - 1], "b": ids[lo - 1], "winner": "", "score": "", "slot": i})
			feeds[hi] = i
		rounds.append({"name": "Previa", "matches": pre})
	# La primera ronda del cuadro: los puestos según la siembra (los de la previa, por llenar).
	var order := seed_order(size)
	var first := []
	for k in size / 2:
		var sa: int = order[k * 2]
		var sb: int = order[k * 2 + 1]
		first.append({"a": "" if feeds.has(sa) else ids[sa - 1], "b": "" if feeds.has(sb) else ids[sb - 1],
			"winner": "", "score": "", "slot": k, "feed_a": feeds.get(sa, -1), "feed_b": feeds.get(sb, -1)})
	var levels := 0
	var s := size
	while s > 1:
		levels += 1
		s /= 2
	rounds.append({"name": round_name(levels - 1), "matches": first})
	# Las rondas que siguen: vacías, se llenan con los ganadores.
	var count := size / 4
	var lvl := levels - 2
	while count >= 1:
		var ms := []
		for k in count:
			ms.append({"a": "", "b": "", "winner": "", "score": "", "slot": k})
		rounds.append({"name": round_name(lvl), "matches": ms})
		count /= 2
		lvl -= 1


func has_playins() -> bool:
	return not rounds.is_empty() and rounds[0]["name"] == "Previa"


## El próximo partido por jugar (los dos ya conocidos), en orden: ronda por ronda, de arriba abajo.
func next_match() -> Dictionary:
	for r in rounds.size():
		for m in rounds[r]["matches"]:
			if m["winner"] == "" and m["a"] != "" and m["b"] != "":
				var out: Dictionary = m.duplicate()
				out["round"] = r
				return out
	return {}


## Los partidos de una ronda que faltan por jugar (para el día del torneo).
func pending(r: int) -> Array:
	var out := []
	for m in rounds[r]["matches"]:
		if m["winner"] == "" and m["a"] != "" and m["b"] != "":
			out.append(m)
	return out


## La ronda en que va el torneo (la primera con partidos por jugar), o -1 si se acabó.
func current_round() -> int:
	for r in rounds.size():
		for m in rounds[r]["matches"]:
			if m["winner"] == "":
				return r
	return -1


## Anota el resultado y pasa al ganador a la ronda que sigue. m: el de next_match() (con "round").
func report(m: Dictionary, winner: String, score := "") -> bool:
	var r: int = m["round"]
	var real: Dictionary = rounds[r]["matches"][m["slot"]]
	if real["winner"] != "" or not winner in [real["a"], real["b"]]:
		return false
	real["winner"] = winner
	real["score"] = score
	if r + 1 >= rounds.size():
		return true
	var nxt: Array = rounds[r + 1]["matches"]
	if rounds[r]["name"] == "Previa":
		for q in nxt:  # el ganador de la previa entra en el puesto que alimenta ese partido
			if q.get("feed_a", -1) == real["slot"]:
				q["a"] = winner
			if q.get("feed_b", -1) == real["slot"]:
				q["b"] = winner
	else:
		var q: Dictionary = nxt[int(real["slot"]) / 2]
		q["a" if int(real["slot"]) % 2 == 0 else "b"] = winner
	return true


func champion() -> String:
	if rounds.is_empty():
		return ""
	return rounds[-1]["matches"][0]["winner"]


## Hasta dónde llegó un jugador: el nombre de la última ronda que jugó, o "Campeón".
func reached(id: String) -> String:
	if champion() == id:
		return "Campeón"
	var last := ""
	for rd in rounds:
		for m in rd["matches"]:
			if id in [m["a"], m["b"]]:
				last = rd["name"]
	return last


## ¿Sigue vivo en el torneo?
func alive(id: String) -> bool:
	for rd in rounds:
		for m in rd["matches"]:
			if m["winner"] != "" and id in [m["a"], m["b"]] and m["winner"] != id:
				return false
	return id in entrants


## Juega un partido entre máquinas, rápido (sin dibujo), y lo anota. Devuelve la simulación.
func simulate(m: Dictionary, seed_: int, difficulty := "dificil") -> TenisSim:
	var fmt: Dictionary = TenisData.FORMATS[TenisData.TOURNAMENT["format"].get(rounds[m["round"]]["name"], "arcade")]
	var sim := TenisSim.new(m["a"], m["b"], fmt, seed_, seed_ % 2)
	sim.fast = true
	TenisAI.setup(sim, 0, difficulty)
	TenisAI.setup(sim, 1, difficulty)
	var steps := 0
	while sim.state != "match_over" and steps < 60 * 60 * 60:
		sim.step([TenisAI.think(sim, 0), TenisAI.think(sim, 1)])
		steps += 1
	if sim.score.winner < 0:  # no debería: por si acaso, gana el que va arriba en puntos
		sim.score.winner = 0 if sim.players[0].stats["points"] >= sim.players[1].stats["points"] else 1
	report(m, sim.players[sim.score.winner].id, score_text(sim.score, sim.score.winner))
	return sim


## Simula los partidos de los demás hasta que le toque a id (o hasta el final, si ya lo sacaron).
## Devuelve cuántos simuló.
func simulate_until(id: String, seed_: int) -> int:
	var n := 0
	var m := next_match()
	while not m.is_empty() and not id in [m["a"], m["b"]]:
		simulate(m, match_seed(m, seed_))
		if rounds[m["round"]]["matches"][m["slot"]]["winner"] == "":
			break  # no quedó anotado: para no dar vueltas
		n += 1
		m = next_match()
	return n


## La semilla de un partido: la del torneo más la ronda y el puesto (el mismo partido, el mismo juego).
static func match_seed(m: Dictionary, seed_: int) -> int:
	return seed_ + int(m["round"]) * 10 + int(m["slot"])


## El marcador como se anota en el cuadro, desde el ganador: "4-2" o "4-3(7-5)".
static func score_text(s: TenisScore, winner: int) -> String:
	var parts := []
	for h in s.set_history:
		parts.append("%d-%d" % [h[winner], h[1 - winner]])
	return " ".join(parts)


func to_dict() -> Dictionary:
	return {"entrants": entrants.duplicate(), "rounds": rounds.duplicate(true)}


static func from_dict(d: Dictionary) -> TenisBracket:
	var b := TenisBracket.new()
	b.entrants = d.get("entrants", []).duplicate()
	b.rounds = d.get("rounds", []).duplicate(true)
	return b
