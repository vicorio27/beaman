extends SceneTree
## Las pruebas del tenis (sin ventana):
##   ../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_tests.gd
## Imprime PASS / FAIL por prueba y, al final, un resumen; sale con código 1 si algo falló.
## (tools/ no va en la exportación.)

var _fails := 0
var _passes := 0


func _init() -> void:
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		_passes += 1
		print("PASS ", name, ("  " + detail) if detail != "" else "")
	else:
		_fails += 1
		print("FAIL ", name, ("  " + detail) if detail != "" else "")


func _run() -> void:
	_scoring()
	_error_bounds()
	_matches()
	_bracket()
	_historia()
	print("\n%d pasaron, %d fallaron" % [_passes, _fails])
	quit(1 if _fails > 0 else 0)


# ---------------------------------------------------------------- El conteo

func _points(s: TenisScore, seq: String) -> void:
	for c in seq:
		s.point_won(int(c))


func _scoring() -> void:
	var real: Dictionary = TenisData.FORMATS["real"]
	var s := TenisScore.new(real)
	_points(s, "0000")
	check("juego en cero", s.games == [1, 0] and s.points == [0, 0] and s.server == 1)
	s = TenisScore.new(real)
	_points(s, "000111")
	check("deuce", s.text() == "Deuce", s.text())
	_points(s, "0")
	check("ventaja", s.text() == "Ventaja saque", s.text())
	_points(s, "1")
	check("vuelve a deuce", s.text() == "Deuce")
	_points(s, "11")
	check("gana el que resta después de deuce", s.games == [0, 1])
	var na := TenisScore.new({"no_ad": true})
	_points(na, "0001110")
	check("sin ventaja: punto de oro", na.games == [1, 0])
	# Set del arcade: a 4 juegos, con dos de diferencia; desempate en 3-3, a 7 con dos de diferencia.
	var ar := TenisScore.new(TenisData.FORMATS["arcade"])
	for g in ["0000", "1111", "0000", "1111", "0000", "1111"]:
		_points(ar, g)
	check("arcade 3-3: desempate", ar.tiebreak and ar.games == [3, 3])
	var first_tb: int = ar.server
	var servers := [ar.server]
	for k in 6:  # 3-3 en el desempate
		_points(ar, str(k % 2))
		servers.append(ar.server)
	var pattern_ok: bool = servers[1] != servers[0] and servers[2] == servers[1] and servers[3] != servers[2] and servers[4] == servers[3]
	check("desempate: saca uno, después dos y dos", pattern_ok, str(servers))
	_points(ar, "01")
	check("desempate sigue con 4-4", not ar.over() and ar.tiebreak)
	_points(ar, "00")
	check("desempate 6-4 todavía no", not ar.over())
	_points(ar, "0")
	check("desempate 7-4: gana el set", ar.over() and ar.winner == 0 and ar.set_history == [[4, 3]], str(ar.set_history))
	var ar2 := TenisScore.new(TenisData.FORMATS["arcade"])
	for g in ["0000", "1111", "0000", "0000"]:
		_points(ar2, g)
	check("arcade 3-1 sigue", not ar2.over())
	_points(ar2, "1111")
	_points(ar2, "0000")
	check("arcade 4-2 gana el set y el partido", ar2.over() and ar2.set_history == [[4, 2]])
	# El saque se alterna juego a juego; en el set siguiente arranca quien recibió primero el desempate.
	var r2 := TenisScore.new(TenisData.FORMATS["real"])
	var alt := true
	var last: int = r2.server
	for g in 5:
		_points(r2, "0000" if g % 2 == 0 else "1111")
		if r2.server == last:
			alt = false
		last = r2.server
	check("el saque se alterna cada juego", alt)
	var r3 := TenisScore.new(TenisData.FORMATS["real"])
	for g in 12:
		_points(r3, "0000" if g % 2 == 0 else "1111")
	var tb_first: int = r3.server
	_points(r3, "0000000")
	check("después del desempate saca el que recibió primero", r3.server == 1 - tb_first and r3.sets == [1, 0])
	var r4 := TenisScore.new({"games_per_set": 6, "tiebreak_at": 6, "sets_to_win": 2})
	for st in 2:
		for g in 6:
			_points(r4, "0000")
	check("dos sets: partido", r4.over() and r4.winner == 0)
	# Ningún estado imposible en mil partidos al azar.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var bad := 0
	for m in 300:
		var x := TenisScore.new(TenisData.FORMATS["arcade"], rng.randi() % 2)
		var n := 0
		while not x.over() and n < 1000:
			x.point_won(rng.randi() % 2)
			n += 1
			if x.games[0] > 4 or x.games[1] > 4 or x.points[0] < 0 or (not x.tiebreak and x.points[0] > 30):
				bad += 1
		if not x.over():
			bad += 1
	check("300 partidos al azar: siempre terminan y sin estados raros", bad == 0)


# ---------------------------------------------------------------- El error

func _error_bounds() -> void:
	var sims := []
	var outs := []
	for prec in range(1, 11):
		var sim := TenisSim.new("base", "base", TenisData.FORMATS["arcade"], 3)
		var p = sim.players[0]
		p.attr = p.attr.duplicate()
		p.attr["precision"] = prec
		sims.append(sim.sigma_for(p, "drive", 0.3))
		# Monte Carlo: un golpe neutro desde el fondo, con margen normal.
		var out := 0
		for k in 400:
			sim.state = "rally"
			sim.ball = Vector3(0.5, TenisData.HALF_L - 0.5, 0.9)
			sim.bvel = Vector3(0, 15, -1)
			p.pos = Vector2(0.9, TenisData.HALF_L - 0.3)
			var target := Vector2(sim.rng.randf_range(-2.8, 2.8), -TenisData.HALF_L * 0.8)
			sim._shoot(p, "drive", target, 0.95, 0.3, {})
			# Volar sin rival: ¿cae adentro?
			var landed := false
			for st in 400:
				var before: Vector3 = sim.ball
				sim._ball_step()
				if not sim.live:
					out += 1
					landed = true
					break
				if sim.bounces >= 1:
					landed = true
					break
			if not landed:
				out += 1
			sim.state = "rally"
		outs.append(out / 400.0)
	var mono := true
	for i in range(1, 10):
		if sims[i] >= sims[i - 1]:
			mono = false
	check("el error baja con la precisión", mono, "sigma 1..10: %.2f .. %.2f" % [sims[0], sims[9]])
	var mono2 := true
	for i in range(1, 10):
		if outs[i] > outs[i - 1] + 0.04:
			mono2 = false
	check("la probabilidad de fallar no sube con la precisión", mono2, str(outs))
	check("falla un golpe neutro entre 1% y 60%", outs[9] >= 0.0 and outs[9] <= 0.25 and outs[0] <= 0.6, "prec 10: %.0f%%  prec 1: %.0f%%" % [outs[9] * 100, outs[0] * 100])


# ---------------------------------------------------------------- El cuadro

func _bracket() -> void:
	check("orden de siembra de 8", str(TenisBracket.seed_order(8)) == str([1, 8, 4, 5, 3, 6, 2, 7]), str(TenisBracket.seed_order(8)))
	var ids: Array = TenisData.TOURNAMENT["entrants"]
	var b := TenisBracket.new(ids)
	check("con 10: previa, cuartos, semifinal y final", b.rounds.size() == 4 and b.rounds[0]["name"] == "Previa"
		and b.rounds[1]["name"] == "Cuartos" and b.rounds[3]["name"] == "Final")
	var pre: Array = b.rounds[0]["matches"]
	check("la previa: 7 contra 10 y 8 contra 9", pre[0]["a"] == ids[6] and pre[0]["b"] == ids[9] and pre[1]["a"] == ids[7] and pre[1]["b"] == ids[8])
	var qf: Array = b.rounds[1]["matches"]
	check("el 1 espera al ganador de 8-9; el 2, al de 7-10", qf[0]["a"] == ids[0] and qf[0]["b"] == "" and qf[3]["a"] == ids[1] and qf[3]["b"] == "")
	check("el 4 contra el 5 y el 3 contra el 6", qf[1]["a"] == ids[3] and qf[1]["b"] == ids[4] and qf[2]["a"] == ids[2] and qf[2]["b"] == ids[5])
	var m := b.next_match()
	check("primero se juega la previa", m.get("round", -1) == 0)
	check("no se puede anotar a uno que no juega", not b.report(m, ids[0]))
	b.report(m, m["b"], "4-2")
	check("el ganador de la previa entra a cuartos en su puesto", qf[3]["b"] == ids[9])
	check("no se anota dos veces", not b.report(m, m["a"]))
	check("el que perdió sale", not b.alive(ids[6]) and b.alive(ids[9]))
	# Guardar y cargar a mitad de torneo.
	var copy := TenisBracket.from_dict(b.to_dict())
	check("se guarda y se carga igual", str(copy.to_dict()) == str(b.to_dict()) and copy.next_match()["slot"] == b.next_match()["slot"])
	# Todo el torneo: siempre termina con un campeón, y cada ronda tiene la mitad de vivos.
	var t0 := Time.get_ticks_msec()
	var champs := {}
	var ok := true
	for k in 3:
		var full := TenisBracket.new(ids)
		var guard := 0
		while not full.next_match().is_empty() and guard < 20:
			full.simulate(full.next_match(), 900 + k * 31 + guard)
			guard += 1
		ok = ok and guard == 9 and full.champion() != ""
		champs[full.champion()] = true
		var alive := 0
		for id in ids:
			alive += int(full.alive(id))
		ok = ok and alive == 1 and full.reached(full.champion()) == "Campeón"
	check("el torneo entero: 9 partidos, un campeón, nadie más vivo", ok, "campeones: %s (%d ms)" % [champs.keys(), Time.get_ticks_msec() - t0])
	# X en el cuadro: simula lo de los demás y para justo en el partido de uno.
	var sk := TenisBracket.new(ids)
	var n4 := sk.simulate_until(ids[3], 77)   # el 4 juega cuartos: antes, la previa y el del 1
	var m4 := sk.next_match()
	check("hasta tu partido: lo de antes y para en el tuyo", n4 == 3 and ids[3] in [m4["a"], m4["b"]], "simuló %d" % n4)
	sk.report(m4, m4["b"] if m4["a"] == ids[3] else m4["a"])
	var rest := sk.simulate_until(ids[3], 77)  # ya lo sacaron: hasta el final
	check("si ya lo sacaron, hasta el final", sk.champion() != "" and rest == 5, "simuló %d" % rest)
	var fm: Dictionary = TenisData.TOURNAMENT["format"]
	var known := true
	for rd in TenisBracket.new(ids).rounds:
		known = known and TenisData.FORMATS.has(fm.get(rd["name"], ""))
	check("cada ronda tiene un formato que existe", known)
	var prize: Dictionary = TenisData.TOURNAMENT["prize"]
	var r := TenisBracket.new(ids)
	r.report(r.next_match(), ids[9])
	check("la bolsa según hasta dónde llegó", prize[r.reached(ids[6])] == prize["Previa"] and prize[r.reached(ids[9])] == prize["Cuartos"])
	# Con otros números de inscritos también arma bien.
	var four := TenisBracket.new(["a", "b", "c", "d"])
	check("con 4: semifinal y final, sin previa", four.rounds.size() == 2 and not four.has_playins())
	var five := TenisBracket.new(["a", "b", "c", "d", "e"])
	check("con 5: una previa (4 contra 5)", five.has_playins() and five.rounds[0]["matches"].size() == 1 and five.rounds[0]["matches"][0]["a"] == "d")


# ---------------------------------------------------------------- La historia (TenisHistoria)

func _historia() -> void:
	var H := TenisHistoria
	check("los días del torneo: del 32 al 35", H.dia_torneo(31) == -1 and H.dia_torneo(32) == 0 and H.dia_torneo(35) == 3 and H.dia_torneo(36) == -1)
	var falta := []
	for id in TenisData.TOURNAMENT["entrants"]:
		if not H.ABANDONOS.has(id) or not ResourceLoader.exists("res://assets/tenis/el_%s.png" % id):
			falta.append(id)
	check("cada inscrito tiene cómo abandonar y él tiene su raqueta", falta.is_empty(), str(falta))
	var salidas := ["camina", "furia", "tel", "doblado", "silla", "toalla", "tribuna", "camilla", "tabla"]
	var mudas := []
	for id in H.ABANDONOS:
		if not str(H.ABANDONOS[id].get("salida", "")) in salidas:
			mudas.append(id)
	check("cada abandono dice cómo se va de la cancha", mudas.is_empty(), str(mudas))
	var b := TenisBracket.new(TenisData.TOURNAMENT["entrants"])
	var a1 := H.quien_abandona(b, 0, [], 5)
	var a2 := H.quien_abandona(b, 0, [], 5)
	var pre := []
	for m in b.pending(0):
		pre.append_array([m["a"], m["b"]])
	check("el que abandona juega hoy, y la misma semilla da el mismo", a1["id"] in pre and str(a1) == str(a2))
	var usados := pre.duplicate()
	usados.erase(pre[3])
	check("prefiere a uno que no haya abandonado", H.quien_abandona(b, 0, usados, 5)["id"] == pre[3])
	check("si ya abandonaron todos, igual abandona uno", not H.quien_abandona(b, 0, pre, 5).is_empty())
	check("sin partidos ese día, nadie", H.quien_abandona(b, 2, [], 5).is_empty())
	var p := H.paga("Final", true, 10)
	check("la paga: sueldo, pelotas y lo del profesional", int(p["total"]) == H.SUELDO + 10 * H.PROPINA_BOLA + H.PROPINA_GANA["Final"]
		and int(H.paga("Previa", false, 0)["total"]) == H.SUELDO + H.CONSUELO)
	var ok := true
	for f in TenisData.FORMATS:  # que abandone antes de que se pueda acabar el partido
		var fmt: Dictionary = TenisData.FORMATS[f]
		ok = ok and H.juegos_para_abandonar(f) < int(fmt["games_per_set"]) * int(fmt["sets_to_win"])
	check("abandona antes de que el partido se pueda acabar", ok)
	# Cuatro jornadas ganando todo, contra la deuda: alcanza, pero no sobra una fortuna.
	var best := 0
	for rn in ["Previa", "Cuartos", "Semifinal", "Final"]:
		best += int(H.paga(rn, true, 8)["total"])
	var worst := 4 * int(H.paga("Previa", false, 0)["total"])
	check("ganando todo, paga la deuda; perdiendo todo, no", best >= H.DEUDA and best < 3 * H.DEUDA and worst < H.DEUDA, "mejor $%d, peor $%d" % [best, worst])


# ---------------------------------------------------------------- Partidos enteros

static func run_match(id0: String, id1: String, seed_: int, diff := "normal") -> TenisSim:
	var sim := TenisSim.new(id0, id1, TenisData.FORMATS["arcade"], seed_, seed_ % 2)
	sim.fast = true
	TenisAI.setup(sim, 0, diff)
	TenisAI.setup(sim, 1, diff)
	var steps := 0
	while sim.state != "match_over" and steps < 60 * 60 * 40:
		sim.step([TenisAI.think(sim, 0), TenisAI.think(sim, 1)])
		steps += 1
	return sim


func _matches() -> void:
	var t0 := Time.get_ticks_msec()
	var a := run_match("base", "base", 11)
	var b := run_match("base", "base", 11)
	check("el partido termina", a.state == "match_over", "puntos: %d, %.0f s de juego" % [a.point_log.size(), a.t])
	var same := a.point_log.size() == b.point_log.size()
	if same:
		for i in a.point_log.size():
			if a.point_log[i]["winner"] != b.point_log[i]["winner"] or a.point_log[i]["kind"] != b.point_log[i]["kind"]:
				same = false
	check("misma semilla: el mismo partido", same)
	var c := run_match("base", "base", 12)
	check("otra semilla: otro partido", c.point_log.size() != a.point_log.size() or str(c.score.set_history) != str(a.score.set_history) or c.t != a.t)
	# Cómo se ven los puntos en 20 partidos.
	var kinds := {}
	var rallies := 0
	var pts := 0
	for k in 20:
		var m := run_match("base", "base", 100 + k)
		for info in m.point_log:
			kinds[info["kind"]] = kinds.get(info["kind"], 0) + 1
			rallies += int(info["rally"])
			pts += 1
	var avg := float(rallies) / maxf(1.0, pts)
	check("los peloteos duran algo (entre 3 y 10 golpes)", avg >= 3.0 and avg <= 10.0, "promedio %.1f" % avg)
	var win_pct := float(kinds.get("winner", 0) + kinds.get("ace", 0)) / pts
	var ue_pct := float(kinds.get("unforced", 0) + kinds.get("double_fault", 0)) / pts
	check("se ganan puntos de verdad: ganadores y aces, 15% o más", win_pct >= 0.15, "%.0f%%  %s" % [win_pct * 100, str(kinds)])
	check("los errores no forzados no pasan del 45%", ue_pct <= 0.45, "%.0f%%" % (ue_pct * 100))
	check("hay aces", kinds.get("ace", 0) > 0)
	print("  (20 partidos en %d ms)" % (Time.get_ticks_msec() - t0))
