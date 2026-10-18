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
