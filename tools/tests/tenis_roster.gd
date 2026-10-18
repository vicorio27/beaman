extends SceneTree
## Las pruebas de los tenistas (sin ventana): las habilidades (activar, gastar, acabarse, esperar),
## las contras, y simulaciones repetibles de los cuatro de la tajada vertical:
##   ../Godot_v4.6.3-stable_win64_console.exe --headless --path . -s tools/tests/tenis_roster.gd
## Variable de entorno TENIS_N: partidos por cruce (por defecto 16). Tarda unos minutos.
## Lo que mide (los criterios que se pueden verificar):
##   - cada uno juega distinto: la mezcla de golpes de cada par difiere en 0.15 o más (distancia L1/2)
##   - la contra le baja a cada habilidad, al menos un 20%, los puntos que gana cuando la usa
##   - ninguno le gana a los demás más del 65% de los partidos (ni menos del 35%)


var _fails := 0
var _passes := 0
var N := 16


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
	var env := OS.get_environment("TENIS_N")
	if env != "":
		N = int(env)
	var only := OS.get_environment("TENIS_ONLY")
	if only == "" or only == "unit":
		_abilities()
		_abilities_six()
		_counters()
	if only == "" or only == "sim":
		_roster_sims()
	if only == "" or only == "counter":
		_counter_sims()
	if only == "rate":
		_rate()
	print("\n%d pasaron, %d fallaron" % [_passes, _fails])
	quit(1 if _fails > 0 else 0)


# ---------------------------------------------------------------- Habilidades

## Un partido parado en medio de un peloteo: la pelota viene hacia `who`, ya picó, cerca de él.
func _rally_at(id0: String, id1: String, who := 0) -> TenisSim:
	var sim := TenisSim.new(id0, id1, TenisData.FORMATS["arcade"], 4)
	sim.fast = true
	var p = sim.players[who]
	sim.state = "rally"
	sim.live = true
	sim.last_hitter = 1 - who
	sim.bounces = 1
	sim.last_shot = {"kind": "drive", "d": 0.2}
	p.pos = Vector2(0.0, p.sign * (TenisData.HALF_L - 0.5))
	sim.ball = Vector3(0.5, p.sign * (TenisData.HALF_L - 0.9), 0.9)
	sim.bvel = Vector3(0.0, p.sign * 12.0, -0.5)
	return sim


func _abilities() -> void:
	# Sin medidor no sale; con medidor sale, gasta, y no se puede prender dos veces.
	var sim := _rally_at("sabalenkova", "base")
	var p = sim.players[0]
	check("sin medidor no se activa", not TenisAbilities.try_activate(sim, p, "rally"))
	p.meter = 80.0
	check("con medidor se activa", TenisAbilities.try_activate(sim, p, "rally"))
	check("gasta lo que cuesta", is_equal_approx(p.meter, 80.0 - 55.0), str(p.meter))
	check("no se activa dos veces", not TenisAbilities.try_activate(sim, p, "rally"))
	check("activa: más potencia", TenisAbilities.mult(p, "power") > 1.0)
	# Dura tres golpes; después, espera.
	for k in 3:
		sim.state = "rally"
		sim.last_hitter = 1
		sim.live = true
		sim.ball = Vector3(0.5, TenisData.HALF_L - 0.9, 0.9)
		sim._hit(p, {"hit": "drive", "aim": Vector2.ZERO})
	check("se acaba a los tres golpes", p.active.is_empty())
	check("y queda esperando", p.cooldown == 3, str(p.cooldown))
	var info := {"kind": "winner", "winner": 0}
	TenisAbilities.on_point(sim, p, sim.players[1], info)
	check("la espera baja por punto", p.cooldown == 2)
	p.meter = 100.0
	check("en espera no se activa", not TenisAbilities.try_activate(sim, p, "rally"))
	# Se acaba al terminar el punto aunque no la haya usado (y se pierde el medidor).
	var s2 := _rally_at("yokovich", "base")
	var y = s2.players[0]
	y.meter = 50.0
	TenisAbilities.try_activate(s2, y, "rally")
	TenisAbilities.on_point(s2, s2.players[1], y, {"kind": "winner", "winner": 1})
	check("se acaba con el punto", y.active.is_empty() and y.cooldown > 0 and y.meter < 50.0)
	# La estirada: solo cuando la pelota viene de su lado; si no le pega, queda en el piso más rato.
	var s3 := _rally_at("monfiz", "base")
	var m = s3.players[0]
	m.meter = 100.0
	check("la estirada no se arma como golpe", not TenisAbilities.try_activate(s3, m, "rally"))
	s3.ball.y = -3.0
	check("la estirada no sale si la pelota está del otro lado", not TenisAbilities.try_activate(s3, m, "reach"))
	s3.ball.y = TenisData.HALF_L - 0.9
	var st0: float = m.stamina
	check("la estirada sale", TenisAbilities.try_activate(s3, m, "reach"))
	check("la estirada cansa", m.stamina < st0)
	check("estirado alcanza más", TenisAbilities.mult(m, "reach") > 1.5)
	for k in 60:
		TenisAbilities.tick(s3, m)
	check("si no le pega, queda en el piso", m.active.is_empty() and m.stuck >= 1.0)
	check("y en el piso no se activa", not TenisAbilities.try_activate(s3, m, "reach"))
	# El amague: la pelota sale para un lado y se tuerce al otro.
	var s4 := _rally_at("bublikov", "base")
	var b = s4.players[0]
	var o = s4.players[1]
	o.pos = Vector2(2.5, -TenisData.HALF_L)
	b.meter = 60.0
	TenisAbilities.try_activate(s4, b, "rally")
	s4._hit(b, {"hit": "drive", "aim": Vector2.ZERO})
	var vx0: float = s4.bvel.x
	check("el amague se tuerce", s4.bcurve != 0.0 and signf(s4.bcurve) != signf(vx0), "vx %.1f curva %.1f" % [vx0, s4.bcurve])
	var landed_x := 0.0
	for k in 300:
		s4._ball_step()
		if s4.bounces >= 1 or not s4.live:
			landed_x = s4.ball.x
			break
	check("y cae lejos de donde está el otro", landed_x < 0.0, "x %.1f" % landed_x)


## Las habilidades de los otros seis: lo que tienen de nuevo el marco.
func _abilities_six() -> void:
	# La queja le sube el error al otro mientras dura.
	var s1 := _rally_at("moutette", "base")
	var m = s1.players[0]
	var o = s1.players[1]
	var before := s1.sigma_for(o, "drive", 0.3)
	m.meter = 100.0
	TenisAbilities.try_activate(s1, m, "rally")
	check("la queja le sube el error al otro", s1.sigma_for(o, "drive", 0.3) > before * 1.2,
		"%.2f -> %.2f" % [before, s1.sigma_for(o, "drive", 0.3)])
	# El cañonazo sale en el saque y pesa.
	var s2 := TenisSim.new("sheltron", "base", TenisData.FORMATS["arcade"], 4, 0)
	var sh = s2.players[0]
	sh.meter = 100.0
	check("el cañonazo no se arma en el peloteo", not TenisAbilities.try_activate(s2, sh, "rally"))
	check("el cañonazo se arma en el saque", TenisAbilities.try_activate(s2, sh, "serve"))
	s2._serve(sh, {"hit": "drive", "aim": Vector2.ZERO})
	check("y sale con el saque (pesado)", sh.active.is_empty() and float(s2.last_shot.get("heavy", 0.0)) > 0.0)
	# El punto de firma: el primer golpe cambia el ritmo (más lento), el segundo remata.
	var s3 := _rally_at("fedorer", "base")
	var f = s3.players[0]
	f.meter = 100.0
	TenisAbilities.try_activate(s3, f, "rally")
	var c1 := {"d": 0.2}
	TenisAbilities.on_hit(s3, f, s3.players[1], "drive", c1)
	var c2 := {"d": 0.2}
	TenisAbilities.on_hit(s3, f, s3.players[1], "drive", c2)
	check("firma: primero el cambio de ritmo, después el remate", float(c1["power_k"]) < 1.0 and float(c2["power_k"]) > 1.0,
		"%.2f, %.2f" % [c1["power_k"], c2["power_k"]])
	# El modo Kyrgios: si pierde el punto en que lo usó, se calienta (y no le quita el control).
	var s4 := _rally_at("kyrgistan", "base")
	var k = s4.players[0]
	k.meter = 100.0
	TenisAbilities.try_activate(s4, k, "rally")
	s4._end_point(1, "winner")
	check("después del modo, si pierde, se calienta", k.mental == "frustrated" and k.active.is_empty())
	# La ejecución perfecta se juzga en cada golpe: le pueden cortar la racha a la mitad.
	var s5 := _rally_at("pecador", "base")
	var pe = s5.players[0]
	pe.meter = 100.0
	TenisAbilities.try_activate(s5, pe, "rally")
	TenisAbilities.on_hit(s5, pe, s5.players[1], "drive", {"d": 0.2})
	var clean: bool = not pe.active["countered"]
	s5.last_shot = {"kind": "slice"}
	TenisAbilities.on_hit(s5, pe, s5.players[1], "drive", {"d": 0.2})
	check("la racha se corta a la mitad con una cortada", clean and pe.active["countered"])


## Las contras como reglas: se prenden con lo que pasa en la cancha.
func _counters() -> void:
	var t1 := _rally_at("moutette", "base")
	t1.players[1].pos.y = -(TenisData.HALF_L + 1.8)
	check("contra de la queja: atrás y tranquilo", TenisAbilities.countered(t1, t1.players[0], t1.players[1]))
	t1.players[1].pos.y = -(TenisData.HALF_L - 2.0)
	check("adelante, no", not TenisAbilities.countered(t1, t1.players[0], t1.players[1]))
	var t2 := _rally_at("tiafuego", "base")
	t2.players[1].recent = [["drive", 0.1, 0.92]]
	check("contra del showman: la pelota al fondo", TenisAbilities.countered(t2, t2.players[0], t2.players[1]))
	t2.players[1].recent = [["drive", 0.1, 0.6]]
	check("corta, no", not TenisAbilities.countered(t2, t2.players[0], t2.players[1]))
	var t3 := TenisSim.new("sheltron", "base", TenisData.FORMATS["arcade"], 4, 0)
	t3.players[1].pos.y = -(TenisData.HALF_L + 1.6)
	check("contra del cañonazo: restar bien atrás", TenisAbilities.countered(t3, t3.players[0], t3.players[1]))
	var t4 := _rally_at("kyrgistan", "base")
	t4.players[1].recent = [["drive", 0.05, 0.9]]
	check("contra del modo: profunda y al centro", TenisAbilities.countered(t4, t4.players[0], t4.players[1]))
	t4.players[1].recent = [["drive", 0.8, 0.9]]
	check("abierta, no", not TenisAbilities.countered(t4, t4.players[0], t4.players[1]))
	var t5 := _rally_at("fedorer", "base")
	t5.players[1].recent = [["drive", 0.3, 0.9]]
	check("contra del artista: no darle una cómoda", TenisAbilities.countered(t5, t5.players[0], t5.players[1]))
	var s := _rally_at("bublikov", "base")
	var o = s.players[1]
	o.pos = Vector2(0.2, -TenisData.HALF_L)
	o.vel = Vector2.ZERO
	check("contra del amague: quieto al centro", TenisAbilities.countered(s, s.players[0], o))
	o.pos.x = 2.4
	check("corrido no la contrarresta", not TenisAbilities.countered(s, s.players[0], o))
	var s2 := _rally_at("sabalenkova", "base")
	s2.last_shot = {"kind": "slice"}
	check("contra de la artillería: le llega cortada", TenisAbilities.countered(s2, s2.players[0], s2.players[1]))
	s2.last_shot = {"kind": "drive"}
	check("plana y parada, no", not TenisAbilities.countered(s2, s2.players[0], s2.players[1]))
	s2.players[0].vel = Vector2(5.0, 0)
	check("corriendo de lado, sí", TenisAbilities.countered(s2, s2.players[0], s2.players[1]))
	var s3 := _rally_at("monfiz", "base")
	s3.players[1].recent = [["drive", 0.8], ["drive", -0.8]]
	check("contra del acróbata: de lado a lado", TenisAbilities.countered(s3, s3.players[0], s3.players[1]))
	s3.players[1].recent = [["drive", 0.8], ["drive", 0.7]]
	check("al mismo lado, no", not TenisAbilities.countered(s3, s3.players[0], s3.players[1]))
	var s4 := _rally_at("yokovich", "base")
	s4.players[1].recent = [["drive", 0.8], ["slice", -0.8], ["lob", 0.2]]
	check("contra del que no se rinde: variedad", TenisAbilities.countered(s4, s4.players[0], s4.players[1]))
	s4.players[1].recent = [["drive", 0.8], ["drive", 0.7], ["drive", 0.5]]
	check("repitiendo, no", not TenisAbilities.countered(s4, s4.players[0], s4.players[1]))
	# Contrarrestada, la habilidad hace menos: Sabalenkova pierde la potencia extra y erra más.
	var s5 := _rally_at("sabalenkova", "base")
	var p = s5.players[0]
	p.meter = 100.0
	TenisAbilities.try_activate(s5, p, "rally")
	var ctx_a := {"d": 0.2}
	TenisAbilities.on_hit(s5, p, s5.players[1], "drive", ctx_a)
	var pa := TenisAbilities.mult(p, "power")
	var s6 := _rally_at("sabalenkova", "base")
	var q = s6.players[0]
	q.meter = 100.0
	s6.last_shot = {"kind": "lob"}
	TenisAbilities.try_activate(s6, q, "rally")
	var ctx_b := {"d": 0.2}
	TenisAbilities.on_hit(s6, q, s6.players[1], "drive", ctx_b)
	check("contrarrestada: menos potencia y más error", TenisAbilities.mult(q, "power") < pa and float(ctx_b.get("sigma_k", 1.0)) > float(ctx_a.get("sigma_k", 1.0)),
		"potencia %.2f vs %.2f" % [TenisAbilities.mult(q, "power"), pa])


# ---------------------------------------------------------------- Simulaciones

func _match(id0: String, id1: String, seed_: int, c0 := -1.0, c1 := -1.0, force := -1, play := true) -> TenisSim:
	var sim := TenisSim.new(id0, id1, TenisData.FORMATS["arcade"], seed_, seed_ % 2)
	sim.fast = true
	sim.force_counter = force
	TenisAI.setup(sim, 0, "normal")
	TenisAI.setup(sim, 1, "normal")
	if c0 >= 0.0:
		sim.players[0].ai["counter_p"] = c0
	if c1 >= 0.0:
		sim.players[1].ai["counter_p"] = c1
	if not play:
		return sim
	var steps := 0
	while sim.state != "match_over" and steps < 60 * 60 * 40:
		sim.step([TenisAI.think(sim, 0), TenisAI.think(sim, 1)])
		steps += 1
	return sim


func _roster_sims() -> void:
	var t0 := Time.get_ticks_msec()
	var roster: Array = TenisData.ROSTER
	var wins := {}
	var played := {}
	var mix := {}
	var extra := {}
	for id in roster:
		wins[id] = 0
		played[id] = 0
		mix[id] = {}
		extra[id] = {"rally": 0, "pts": 0, "w": 0, "ue": 0, "ab": 0, "net": 0}
	var pair_lines := []
	# Repartido en varios procesos (tools/tests/tenis_balance.py): TENIS_SHARD="i/n" corre solo los cruces
	# i, i+n, i+2n... e imprime los números crudos (PAR, MIX) para que el script los junte.
	var shard := OS.get_environment("TENIS_SHARD")
	var sh_i := int(shard.split("/")[0]) if shard != "" else 0
	var sh_n := int(shard.split("/")[1]) if shard != "" else 1
	var pair_n := -1
	for i in roster.size():
		for j in range(i + 1, roster.size()):
			pair_n += 1
			if pair_n % sh_n != sh_i:
				continue
			var a: String = roster[i]
			var b: String = roster[j]
			var wa := 0
			for k in N:
				# Mitad y mitad de cada lado de la cancha.
				var flip := k % 2 == 1
				var sim := _match(b if flip else a, a if flip else b, 1000 + i * 100 + j * 10 + k)
				var ia := 1 if flip else 0
				if sim.score.winner == ia:
					wa += 1
				for side in 2:
					var p = sim.players[side]
					for kk in p.stats["shots"]:
						mix[p.id][kk] = mix[p.id].get(kk, 0) + p.stats["shots"][kk]
					for kk in HOW_KEYS + ["hits"]:
						mix[p.id][kk] = mix[p.id].get(kk, 0) + p.stats[kk]
					extra[p.id]["w"] += p.stats["winners"] + p.stats["aces"]
					extra[p.id]["ue"] += p.stats["ue"] + p.stats["df"]
					extra[p.id]["ab"] += p.stats["abilities"]
				for info in sim.point_log:
					for id in [sim.players[0].id, sim.players[1].id]:
						extra[id]["rally"] += int(info["rally"])
						extra[id]["pts"] += 1
			wins[a] += wa
			wins[b] += N - wa
			played[a] += N
			played[b] += N
			pair_lines.append("%s %d - %d %s" % [a, wa, N - wa, b])
			if shard != "":
				print("PAR %s %s %d %d" % [a, b, wa, N])
	if shard != "":
		for id in roster:
			var parts := []
			for k in MIX_KEYS + HOW_KEYS + ["hits"]:
				parts.append(str(mix[id].get(k, 0)))
			print("MIX %s %s" % [id, " ".join(parts)])
		return
	print("  cruces: ", ", ".join(pair_lines))
	var worst := 0.0
	var weakest := 1.0
	for id in roster:
		var pct: float = float(wins[id]) / played[id]
		worst = maxf(worst, pct)
		weakest = minf(weakest, pct)
		var e: Dictionary = extra[id]
		print("  %-12s gana %2.0f%%  golpes %s  ganadores %d  errores %d  habilidad %d  peloteo %.1f" % [id, pct * 100,
			_mix_text(mix[id]), e["w"], e["ue"], e["ab"], float(e["rally"]) / maxf(1, e["pts"])])
	check("ninguno gana más del 65%", worst <= 0.65, "el mejor: %.0f%%" % (worst * 100))
	check("ninguno gana menos del 35%", weakest >= 0.35, "el peor: %.0f%%" % (weakest * 100))
	var min_d := 9.0
	var min_pair := ""
	for i in roster.size():
		for j in range(i + 1, roster.size()):
			var dd := _mix_dist(mix[roster[i]], mix[roster[j]])
			if dd < min_d:
				min_d = dd
				min_pair = "%s/%s" % [roster[i], roster[j]]
	check("cada uno juega distinto (mezcla de golpes)", min_d >= 0.15, "la más parecida: %s %.2f" % [min_pair, min_d])
	print("  (%d partidos en %d s)" % [N * pair_lines.size(), (Time.get_ticks_msec() - t0) / 1000])


const MIX_KEYS := ["drive", "slice", "lob", "drop", "underarm", "trick"]
const HOW_KEYS := ["deep", "fast", "wide"]  # qué parte de sus golpes van al fondo, duros, abiertos


## Para ajustar rápido: cada uno (TENIS_IDS) contra el parejo ("base"), N partidos. Imprime RATE.
func _rate() -> void:
	for id in OS.get_environment("TENIS_IDS").split(","):
		var w := 0
		var pts := [0, 0]
		for k in N:
			var sim := _match(id, "base", 300 + k)
			w += int(sim.score.winner == 0)
			for info in sim.point_log:
				pts[info["winner"]] += 1
		print("RATE %s %d %d %d %d" % [id, w, N, pts[0], pts[0] + pts[1]])


func _mix_norm(m: Dictionary) -> Dictionary:
	var tot := 0.0
	for k in MIX_KEYS:
		tot += float(m.get(k, 0))
	var out := {}
	for k in MIX_KEYS:
		out[k] = float(m.get(k, 0)) / maxf(tot, 1.0)
	return out


func _mix_text(m: Dictionary) -> String:
	var n := _mix_norm(m)
	var parts := []
	for k in MIX_KEYS:
		parts.append("%s %.0f" % [k.substr(0, 3), n[k] * 100])
	return " ".join(parts)


func _mix_dist(a: Dictionary, b: Dictionary) -> float:
	var na := _mix_norm(a)
	var nb := _mix_norm(b)
	var d := 0.0
	for k in MIX_KEYS:
		d += absf(na[k] - nb[k])
	return d / 2.0


## La contra, en dos partes, cada uno contra un rival parejo ("base"):
##   1. Lo que hace: los mismos partidos con la contra forzada (siempre o nunca, en cada uso). La
##      habilidad tiene que ganar al menos un 20% menos de los puntos en que se usa.
##   2. Que se pueda jugar: cada vez que él tiene la habilidad lista y va a pegar, ¿se está dando la
##      contra? La máquina que la sabe jugar tiene que lograrla más seguido que la que no.
func _counter_sims() -> void:
	var only_ids := OS.get_environment("TENIS_IDS")
	for id in TenisData.ROSTER:
		if only_ids != "" and not id in only_ids.split(","):
			continue
		var name: String = TenisAbilities.DEFS[TenisData.player(id)["ability"]]["name"]
		var rate := []
		for force in [0, 1]:
			var used := 0
			var won := 0
			for k in N:
				var sim := _match(id, "base", 5000 + k, -1.0, 0.0, force)
				for info in sim.point_log:
					if int(info["used"][0]) > 0:
						used += 1
						if info["winner"] == 0:
							won += 1
			rate.append([float(won) / maxf(used, 1), used])
		var drop: float = 1.0 - rate[1][0] / maxf(rate[0][0], 0.001)
		check("la contra de %s le quita 20%% o más" % name, drop >= 0.2,
			"gana %.0f%% de los puntos en que la usa (%d); contrarrestada, %.0f%% (%d): %+.0f%%" % [
				rate[0][0] * 100, rate[0][1], rate[1][0] * 100, rate[1][1], -drop * 100])
		var seen := []
		for c in [0.0, 1.0]:
			var ready := 0
			var on := 0
			for k in maxi(N / 2, 4):
				var sim := _match(id, "base", 7000 + k, -1.0, c, -1, false)
				var p = sim.players[0]
				var o = sim.players[1]
				var steps := 0
				while sim.state != "match_over" and steps < 60 * 60 * 40:
					var i0 := TenisAI.think(sim, 0)
					var i1 := TenisAI.think(sim, 1)
					var ab := TenisAbilities.def(p)
					var chance: bool = sim.state == "rally" and sim._can_hit(p)
					if ab.get("when", "rally") == "serve":
						chance = sim.state == "serve" and sim.score.server == 0 and sim.serve_try == 1
					if chance and p.meter >= float(ab["cost"]) * 0.6:
						ready += 1
						if TenisAbilities.counter_rule(sim, p, o):
							on += 1
					sim.step([i0, i1])
					steps += 1
			seen.append(float(on) / maxf(ready, 1))
		check("la contra de %s se puede jugar" % name, seen[1] >= seen[0] * 1.3 and seen[1] >= 0.25,
			"sin saberla se da %.0f%% de las veces; sabiéndola, %.0f%%" % [seen[0] * 100, seen[1] * 100])
