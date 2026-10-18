class_name TenisAI
extends RefCounted
## La máquina: ve lo mismo que vería un jugador (dónde está la pelota, para dónde va, dónde está el
## otro) y juega con las mismas reglas y el mismo error. No lee lo que aprieta el humano.
##   TenisAI.setup(sim, 1, "normal")
##   var inp := TenisAI.think(sim, 1)      # cada paso
## Qué la hace distinta de un jugador a otro: los pesos de los golpes ("shots"), cuánto arriesga
## ("risk": qué tan cerca de las rayas apunta), dónde se para ("home_depth") y su habilidad (ver
## TenisAbilities: cada una dice cuándo la usa la máquina). La dificultad cambia la reacción, lo bien
## que decide y lo limpio que ejecuta; nunca los atributos.
## La contra: la máquina conoce la habilidad del otro (lo que todo el mundo sabe de ese jugador) y,
## cuando el medidor del otro está lleno o la habilidad prendida, le juega la contra con la
## probabilidad "counter" de su dificultad (se decide por punto). La contra es la regla de
## TenisAbilities.countered(): lo que hace aquí la máquina es lo que haría un jugador que la sabe.

const DT := TenisSim.DT
const TEMP := 0.05  # qué tan seguido escoge un golpe que no es el mejor (más alto, más variado)


static func setup(sim: TenisSim, idx: int, difficulty := "normal") -> void:
	var p = sim.players[idx]
	var d: Dictionary = TenisData.DIFFICULTY.get(difficulty, TenisData.DIFFICULTY["normal"])
	p.ai = {"react_base": d["react"], "noise": d["decide_noise"], "exec": d["exec"], "seen": -1, "react": 0.0,
		"plan": Vector2.ZERO, "serve_wait": 0.0, "on": true, "counter_p": d.get("counter", 0.5), "counter": false,
		"point": -1, "hit_t": 0.0, "curve_seen": false}


static func think(sim: TenisSim, idx: int) -> Dictionary:
	var p = sim.players[idx]
	var o = sim.players[1 - idx]
	var inp := {"move": Vector2.ZERO, "hit": "", "aim": Vector2.ZERO, "ability": false}
	var ai: Dictionary = p.ai
	var cfg: Dictionary = p.data["ai"]
	if sim.state == "serve":
		if int(ai["point"]) != sim.point_log.size():  # ¿le juega la contra este punto?
			ai["point"] = sim.point_log.size()
			ai["counter"] = sim.rng.randf() < float(ai["counter_p"])
		if sim.score.server == idx:
			ai["serve_wait"] = float(ai["serve_wait"]) + DT
			if ai["serve_wait"] > 0.7:
				ai["serve_wait"] = 0.0
				inp["hit"] = "drive"
				# Por abajo: si el que recibe está bien atrás y le gusta (Bublikov).
				var deep: bool = o.pos.y * o.sign > TenisData.HALF_L + 0.6
				if sim.serve_try == 1 and deep and sim.rng.randf() < p.trait_k("underarm"):
					inp["hit"] = "underarm"
				var risk := _risk(p, cfg)
				# Abierto, al cuerpo o a la T. El segundo saque, al medio del cuadro.
				var opts := [-1.0, 0.0, 1.0]
				var pick: float = opts[sim.rng.randi() % 3]
				inp["aim"] = Vector2(pick * (0.6 + 0.4 * risk) if sim.serve_try == 1 else pick * 0.3, 0)
				inp["ability"] = TenisAbilities.can_activate(sim, p, "serve") and _wants_ability(sim, p, o, "serve")
		elif _countering(sim, p, o, "serve_deep"):
			var back := TenisData.HALF_L + 1.8
			if p.pos.y * p.sign < back:
				inp["move"] = Vector2(0, p.sign)
		return inp
	if sim.state != "rally":
		return inp
	if sim.live and sim.last_hitter != idx:
		if int(ai["seen"]) != sim.hits:
			ai["seen"] = sim.hits
			ai["hit_t"] = sim.t
			ai["curve_seen"] = false
			ai["react"] = float(ai["react_base"]) + (0.15 if sim.last_shot.get("serve", false) else 0.0)  # leer el saque
			ai["plan"] = _plan(sim, p, false)
		# El amague se ve cuando ya se torció: ahí recalcula (como cualquiera que lo ve).
		if sim.bcurve != 0.0 and not ai["curve_seen"] and sim.t - float(ai["hit_t"]) > float(ai["react_base"]) + 0.22:
			ai["curve_seen"] = true
			ai["plan"] = _plan(sim, p, true)
		if float(ai["react"]) > 0.0:
			ai["react"] = float(ai["react"]) - DT
			return inp
		inp["move"] = _toward(p, ai["plan"])
		if sim._can_hit(p) and _hit_now(sim, p):
			_choose(sim, p, o, cfg, inp)
			inp["ability"] = TenisAbilities.can_activate(sim, p, "rally") and _wants_ability(sim, p, o, "hit")
		elif TenisAbilities.can_activate(sim, p, "reach") and _wants_ability(sim, p, o, "reach"):
			inp["ability"] = true
	else:
		var home := Vector2(clampf(sim.ball.x * 0.45, -2.0, 2.0), p.sign * (TenisData.HALF_L + 2.5 - float(cfg.get("home_depth", 0.5)) * 3.0))
		if _countering(sim, p, o, "stay_back"):
			home.y = p.sign * (TenisData.HALF_L + 1.9)
		# La contra del amague: quieto y al centro cuando el otro va a pegar con el medidor lleno.
		if _countering(sim, p, o, "balanced") and sim.live:
			if absf(p.pos.x) < 0.6:
				return inp  # ya está: quieto, esperando (el split-step)
			home = Vector2(0.0, p.pos.y)
		inp["move"] = _toward(p, home)
	return inp


## ¿Le está jugando la contra a la habilidad del otro (de ese tipo) ahora?
static func _countering(sim: TenisSim, p, o, type: String) -> bool:
	if not p.ai.get("counter", false):
		return false
	var d := TenisAbilities.def(o)
	if d.is_empty() or str(d.get("counter", {}).get("type", "")) != type:
		return false
	return not o.active.is_empty() or o.meter >= float(d["cost"]) * 0.6  # ya casi la tiene: se la ve venir


static func _toward(p, at: Vector2) -> Vector2:
	var d: Vector2 = at - p.pos
	if d.length() < 0.15:
		return Vector2.ZERO
	return d.normalized() * clampf(d.length() / 0.6, 0.2, 1.0)


## Dónde le conviene recibirla: el primer punto del vuelo (después del bote, a una altura cómoda) al
## que alcanza a llegar a tiempo. Simula la pelota hacia adelante con la misma física, sin azar.
static func _plan(sim: TenisSim, p, with_curve: bool) -> Vector2:
	var pos: Vector3 = sim.ball
	var vel: Vector3 = sim.bvel
	var spin: float = sim.bspin
	var curve: float = sim.bcurve if with_curve else 0.0
	var b: int = sim.bounces
	var g := TenisData.GRAVITY * (1.0 + 0.35 * spin)
	var best := Vector2(pos.x, pos.y)
	var best_late := INF
	var react: float = p.ai["react"]
	var side := 1.0 if p.pos.x >= pos.x else -1.0
	for k in 220:
		vel.z -= g * DT
		if b == 0:
			vel.x += curve * DT
		pos += vel * DT
		if pos.z <= 0.0 and vel.z < 0.0:
			pos.z = 0.0
			b += 1
			vel.z = -vel.z * (0.7 + 0.1 * spin)
			vel.x *= 0.8 + 0.07 * spin
			vel.y *= 0.8 + 0.07 * spin
			if b >= 2:
				break
		if pos.y * p.sign <= 0.0:
			continue
		var t := (k + 1) * DT
		var ok_height := pos.z >= 0.15 and pos.z <= 1.7
		if not ok_height or b != 1:
			continue
		var stand := Vector2(pos.x, pos.y) + Vector2(side * 0.45 * p.reach(), p.sign * 0.25)
		var need: float = (stand.distance_to(p.pos) - 0.1) / p.max_speed() + react
		var late := need - t
		if late <= 0.0:
			return stand
		if late < best_late:
			best_late = late
			best = stand
	return best


## Le pega ahora si le llega bien, o si ya se le va.
static func _hit_now(sim: TenisSim, p) -> bool:
	if sim.timing(p) >= 0.72:
		return true
	var nxt := Vector2(sim.ball.x + sim.bvel.x * DT * 3.0, sim.ball.y + sim.bvel.y * DT * 3.0)
	var leaving: bool = nxt.distance_to(p.pos) > p.reach() * 0.95
	var dropping: bool = sim.bounces == 1 and sim.ball.z < 0.3 and sim.bvel.z < 0.0
	return leaving or dropping


static func _risk(p, cfg: Dictionary) -> float:
	var r: float = cfg.get("risk", 0.5)
	match p.mental:
		"frustrated":
			r += 0.25
		"confident":
			r += 0.1
		"overexcited":
			r += 0.2
		"pressure":
			r -= 0.15 * p.a("composure") / 10.0
	return clampf(r, 0.0, 1.0)


static func _phi(x: float) -> float:
	return 0.5 * (1.0 + tanh(0.8 * x))


## Escoge golpe y a dónde: lo que más apura al otro, menos lo que arriesga, más su gusto (los pesos de
## su manera de jugar) y un poco de ruido según la dificultad.
static func _choose(sim: TenisSim, p, o, cfg: Dictionary, inp: Dictionary) -> void:
	var risk := _risk(p, cfg)
	var safe := _countering(sim, p, o, "safe_ball")
	var disrupt := _countering(sim, p, o, "disrupt")
	var pressure := _countering(sim, p, o, "pressure")
	var deep := _countering(sim, p, o, "deep_ball") or safe or pressure
	var margin := lerpf(1.4, 0.35, risk)
	var d: float = sim.difficulty(p)
	var weights: Dictionary = cfg.get("shots", {"drive": 1.0})
	var o_depth: float = o.pos.y * o.sign
	var awkward := _countering(sim, p, o, "awkward_ball")
	var alternate := _countering(sim, p, o, "alternating")
	var vary := _countering(sim, p, o, "variety")
	var last_side: float = signf(p.recent[-1][1]) if p.recent.size() > 0 else 0.0
	# Lo que le falta para volver a su sitio: si está muy corrido, le conviene un golpe que le dé tiempo.
	var home := Vector2(0.0, p.sign * (TenisData.HALF_L + 2.5 - float(cfg.get("home_depth", 0.5)) * 3.0))
	var t_rec: float = p.pos.distance_to(home) / p.max_speed()
	var by_kind := {}  # el mejor lado de cada golpe: [valor, lado]
	for kind in weights:
		var wk: float = weights[kind]
		if wk <= 0.0:
			continue
		var shot: Dictionary = TenisData.SHOTS[kind]
		var sigma := sim.sigma_for(p, kind, d)
		var v: float = shot["speed"] + shot["power_k"] * p.a("power")
		for lat in [-1.0, -0.4, 0.0, 0.4, 1.0]:
			var tx: float = lat * (TenisData.HALF_W - margin)
			var depth: float = shot["depth"]
			if kind in ["drive", "slice"]:
				depth = minf(depth + float(cfg.get("depth", 0.0)), 0.95)  # el que la manda más al fondo
			if deep and kind != "drop":
				depth = minf(depth + 0.12, 0.95)  # bien al fondo: que no tenga con qué lucirse
			var ty: float = -p.sign * clampf(TenisData.HALF_L * depth, 1.5, TenisData.HALF_L - margin * 0.8)
			var target := Vector2(tx, ty)
			var flight := Vector2(sim.ball.x, sim.ball.y).distance_to(target) / v
			var t_need: float = (target.distance_to(o.pos) - o.reach()) / o.max_speed()
			var press := clampf(t_need - flight + 0.3, -1.0, 1.5)
			var p_out := sim.risk_of(p, kind, target, d)
			# Lo que vale: la probabilidad de ganar el punto si entra (más si apura) por la de que entre.
			var val := (1.0 - p_out) * (0.5 + 0.4 * clampf(press / 1.5, -1.0, 1.0)) + 0.04 * log(wk)
			# Su estilo: lo que le gusta pegar (si entra). Es lo que lo hace reconocible.
			val += float(cfg.get("style", {}).get(kind, 0.0)) * (1.0 - p_out)
			if absf(lat) == 1.0:  # el que busca los ángulos (el zurdo)
				val += float(cfg.get("wide", 0.0)) * (1.0 - p_out)
			if kind == "lob" and o_depth < 6.0:
				val += 0.25  # el otro en la red: por encima
			val -= 0.22 * clampf(t_rec - (flight + 0.8), 0.0, 1.5)  # quedar vendido
			# Las contras: lo que le sirve contra ese jugador (si entra, que es lo que pesa primero).
			if awkward and kind in ["slice", "lob"]:
				val += 0.14 * (1.0 - p_out)
			if alternate and absf(lat) == 1.0 and signf(lat) != last_side:
				val += 0.25 * (1.0 - p_out)
			if vary:
				val += _variety(p, kind, lat) * (1.0 - p_out)
			if disrupt and (kind in ["slice", "lob", "drop"] or (absf(lat) >= 0.4 and signf(lat) != last_side)):
				val += 0.24 * (1.0 - p_out)
			if safe and lat == 0.0:
				val += 0.16 * (1.0 - p_out)  # al centro y al fondo: nada de regalos
			if pressure and kind != "drop":  # apurarlo desde el fondo, y a su revés (nada de dejadas)
				val += 0.6 * clampf(press / 1.5, -1.0, 1.0) * (1.0 - p_out)
				var hand := -1.0 if o.data.get("hand", "right") == "left" else 1.0
				if (tx - o.pos.x) * o.sign * hand < 0.0:
					val += 0.06 * (1.0 - p_out)
			val += sim.rng.randfn(0.0, 1.0) * float(p.ai["noise"]) * 0.15
			if not by_kind.has(kind) or val > float(by_kind[kind][0]):
				by_kind[kind] = [val, lat]
	# Entre los golpes, no siempre el mejor: uno parecido de bueno también sale (como en el tenis de
	# verdad). Los que valen mucho menos, casi nunca. Por eso el estilo se nota sin volverlo tonto.
	var top := -INF
	for kind in by_kind:
		top = maxf(top, float(by_kind[kind][0]))
	var total := 0.0
	var probs := {}
	for kind in by_kind:
		probs[kind] = exp((float(by_kind[kind][0]) - top) / TEMP)
		total += float(probs[kind])
	var roll := sim.rng.randf() * total
	var pick := "drive"
	for kind in by_kind:
		pick = kind
		roll -= float(probs[kind])
		if roll <= 0.0:
			break
	inp["hit"] = pick
	var aim_y := 1.0 if deep else float(cfg.get("depth", 0.0)) / 0.12
	inp["aim"] = Vector2(float(by_kind[pick][1]) * p.sign, aim_y)
	inp["margin"] = margin


## Cuánto suma variar: otro golpe que los dos últimos, y al otro lado que el último.
static func _variety(p, kind: String, side: float) -> float:
	var r: Array = p.recent.slice(-2)
	var k := 0.0
	var new_kind := true
	for s in r:
		if s[0] == kind:
			new_kind = false
	if new_kind:
		k += 0.14
	if r.size() > 0 and absf(side) >= 0.4 and signf(side) != signf(r[-1][1]):
		k += 0.1
	return k


## ¿La usa ahora? Lo decide la habilidad (TenisAbilities.ai_wants), si tiene.
static func _wants_ability(sim: TenisSim, p, o, moment: String) -> bool:
	return TenisAbilities.ai_wants(sim, p, o, moment)
