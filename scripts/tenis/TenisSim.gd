class_name TenisSim
extends RefCounted
## El partido, sin dibujo: la pelota (con altura, efecto y bote), los dos jugadores, los golpes, los
## puntos y el ánimo. Lo dibuja TenisMatch.gd; las pruebas lo corren solo (tools/tests/tenis_tests.gd).
## Se avanza con step(inputs): un paso fijo de DT. Los mismos datos + la misma semilla = el mismo partido.
##   var sim := TenisSim.new("base", "base", TenisData.FORMATS["arcade"], 7)
##   sim.step([{"move": Vector2.ZERO, "hit": ""}, TenisAI.think(sim, 1)])
## Unidades: metros y segundos. El jugador 0 está abajo (y > 0); el 1, arriba. La red en y = 0.
## Cada golpe se resuelve con los atributos, la dificultad del momento (lo rápido que viene, lo estirado
## que está, la altura, la carrera, el cansancio, el ánimo, la habilidad activa) y un error acotado
## (gaussiano, cortado a 2.5 sigmas): el azar nunca da vuelta una ventaja clara.

signal event(kind: String, data: Dictionary)

const DT := 1.0 / 60.0
const H := TenisData.HALF_L
const W := TenisData.HALF_W

## Un jugador en la cancha.
class P:
	var idx := 0
	var id := ""
	var data := {}
	var attr := {}
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var stamina := 100.0
	var meter := 0.0            # el recurso de la habilidad (0..100)
	var mental := "focused"     # focused, confident, frustrated, pressure, overexcited
	var mental_left := 0        # cuántos puntos le quedan a ese ánimo
	var won_streak := 0
	var lost_streak := 0
	var ue_streak := 0
	var stuck := 0.0            # en el piso (después de tirarse): no se mueve
	var active := {}            # la habilidad activa: {"id", "shots" (golpes que le quedan), ...}
	var cooldown := 0           # puntos que faltan para poder volver a usarla
	var trick_streak := 0       # golpes raros seguidos (el del caos: cada uno, más riesgo)
	var last_kinds: Array = []  # los últimos golpes que le llegaron (para el ritmo)
	var rhythm := 0.0           # 0..1: qué tan acomodado está a lo que le llega
	var used := 0               # 1: usó la habilidad este punto; 2: y se la contrarrestaron
	var recent: Array = []      # sus últimos golpes: [tipo, lado (-1..1, en x de la cancha)]
	var ai := {}
	var stats := {"winners": 0, "ue": 0, "fe": 0, "aces": 0, "df": 0, "points": 0, "abilities": 0,
		"shots": {"drive": 0, "slice": 0, "lob": 0, "drop": 0, "serve": 0, "underarm": 0, "trick": 0}}
	var sign := 1.0             # +1 abajo, -1 arriba

	func a(k: String) -> float:
		return float(attr.get(k, 5))

	func max_speed() -> float:
		var s := 3.9 + 0.15 * a("defense")
		if stamina < 30.0:
			s *= 0.82
		return s * TenisAbilities.mult(self, "speed")

	func trait_k(k: String) -> float:
		return float(data.get("traits", {}).get(k, 0.0))

	func reach() -> float:
		return 0.9 + 0.04 * a("defense")


var players: Array = []
var score: TenisScore
var rng := RandomNumberGenerator.new()
var ball := Vector3.ZERO
var bvel := Vector3.ZERO
var bspin := 0.0
var bcurve := 0.0          # la curva del amague (m/s² de lado), solo hasta el primer bote
var live := false
var bounces := 0           # botes desde el último golpe
var last_hitter := -1
var last_shot := {}        # {kind, d (dificultad), deceive, trick, ability}
var state := "serve"       # serve, rally, point_over, match_over
var serve_try := 1
var rally := 0
var hits := 0              # cuántos golpes van en el partido (la máquina ve cuándo hay uno nuevo)
var t := 0.0
var wait := 0.0            # pausa entre puntos (0 en simulación rápida)
var fast := false
var force_counter := -1    # solo para las pruebas: 0 o 1 fuerza la contra de las habilidades
var point_log: Array = []
var _missed_reach := [99.0, 99.0]   # lo más cerca que estuvo cada uno de la pelota que no devolvió
var _retry_serve := false           # hubo falta: el que sigue es el segundo saque


func _init(id0: String, id1: String, fmt: Dictionary, seed_ := 1, first_server := 0) -> void:
	rng.seed = seed_
	score = TenisScore.new(fmt, first_server)
	for i in 2:
		var p := P.new()
		p.idx = i
		p.id = [id0, id1][i]
		p.data = TenisData.player(p.id)
		p.attr = p.data["attr"]
		p.sign = 1.0 if i == 0 else -1.0
		players.append(p)
	_setup_serve()


# ---------------------------------------------------------------- El paso

## inputs: por jugador {"move": Vector2 (-1..1), "hit": "" | "drive" | "slice" | "lob" | "drop",
## "aim": Vector2 (x: -1 izquierda .. 1 derecha, vista desde él; y: -1 corto .. 1 profundo),
## "ability": bool}.
func step(inputs: Array) -> void:
	t += DT
	match state:
		"match_over":
			return
		"point_over":
			wait -= DT
			for p in players:
				p.vel = Vector2.ZERO
			if wait <= 0.0:
				if score.over():
					state = "match_over"
					event.emit("match", {"winner": score.winner})
				else:
					_setup_serve()
			return
		"serve":
			_move_players(inputs, true)
			var s: P = players[score.server]
			var inp: Dictionary = inputs[score.server]
			if inp.get("ability", false):
				TenisAbilities.try_activate(self, s, "serve")
			if str(inp.get("hit", "")) != "":
				_serve(s, inp)
			return
	_move_players(inputs, false)
	for p in players:
		var inp: Dictionary = inputs[p.idx]
		TenisAbilities.tick(self, p)
		if inp.get("ability", false):
			if not TenisAbilities.try_activate(self, p, "rally"):
				TenisAbilities.try_activate(self, p, "reach")
		if str(inp.get("hit", "")) != "" and _can_hit(p):
			_hit(p, inp)
	_ball_step()


func _move_players(inputs: Array, serving: bool) -> void:
	for p in players:
		if p.stuck > 0.0:
			p.stuck -= DT
			p.vel = Vector2.ZERO
			continue
		var dir: Vector2 = inputs[p.idx].get("move", Vector2.ZERO)
		if serving:
			dir = Vector2(dir.x, 0) if p.idx != score.server else Vector2.ZERO  # el que saca, quieto
		if dir.length() > 1.0:
			dir = dir.normalized()
		var target: Vector2 = dir * p.max_speed()
		p.vel = p.vel.move_toward(target, 34.0 * DT)
		p.pos += p.vel * DT
		var ymin := 0.4
		p.pos.x = clampf(p.pos.x, -W - 3.5, W + 3.5)
		var depth := clampf(p.pos.y * p.sign, ymin, H + 4.5)
		p.pos.y = depth * p.sign
		var effort: float = p.vel.length() / p.max_speed()
		if effort > 0.6:
			p.stamina = maxf(0.0, p.stamina - effort * effort * 5.0 * DT * (1.0 + p.trait_k("drain")))
		else:
			p.stamina = minf(100.0, p.stamina + 3.5 * DT)


# ---------------------------------------------------------------- El saque

func _setup_serve() -> void:
	state = "serve"
	live = false
	bounces = 0
	last_hitter = -1
	rally = 0
	_missed_reach = [99.0, 99.0]
	for p in players:
		p.used = 0
	var s: P = players[score.server]
	var r: P = players[1 - score.server]
	var xs := _serve_x_sign(s)
	s.pos = Vector2(xs * 0.8, s.sign * (H + 0.3))
	s.vel = Vector2.ZERO
	r.pos = Vector2(-xs * 2.4, r.sign * (H - 0.2 + float(r.data["ai"].get("return_depth", 0.0))))  # cada uno resta desde donde le gusta
	r.vel = Vector2.ZERO
	ball = Vector3(s.pos.x, s.pos.y, 1.0)
	bvel = Vector3.ZERO
	for p in players:
		p.stamina = minf(100.0, p.stamina + 12.0)
		if score.pressure_on(p.idx):
			_set_mental(p, "pressure", 1)
		elif p.mental == "pressure":
			_set_mental(p, "focused", 0)


## La x del que saca: el lado "deuce" es su derecha.
func _serve_x_sign(s: P) -> float:
	var right := 1.0 if s.idx == 0 else -1.0
	return right if score.serve_side() == "deuce" else -right


## El cuadro de saque al que tiene que entrar (en diagonal).
func service_box(s: P) -> Rect2:
	var xs := -_serve_x_sign(s)  # al otro lado, en diagonal
	var x0 := 0.0 if xs > 0 else -W
	var y0 := 0.0 if s.sign < 0 else -TenisData.SERVICE_L
	return Rect2(x0, y0, W, TenisData.SERVICE_L)


func _serve(s: P, inp: Dictionary) -> void:
	state = "rally"
	live = true
	ball = Vector3(s.pos.x, s.pos.y, 2.7)
	var box := service_box(s)
	var aim: Vector2 = inp.get("aim", Vector2.ZERO)
	# Abierto, al cuerpo o a la T: aim.x desde el que saca (para el de arriba, se invierte).
	var lateral := clampf(aim.x * s.sign, -1.0, 1.0)
	var tx := lerpf(box.position.x + 0.45, box.end.x - 0.45, (lateral + 1.0) / 2.0)
	var ty := -s.sign * (TenisData.SERVICE_L - 0.7)
	var second := serve_try == 2
	var kind := "serve"
	var power := 1.0 if not second else 0.72
	if second:
		ty = -s.sign * (TenisData.SERVICE_L - 1.4)
	if inp.get("hit", "") == "underarm":  # por abajo: cortico, pegado a la red (al que está atrás lo deja)
		kind = "underarm"
		power = 1.0
		ty = -s.sign * 1.6
		tx = lerpf(box.position.x + 0.8, box.end.x - 0.8, (lateral + 1.0) / 2.0)
		s.trick_streak += 1
	else:
		s.trick_streak = 0
	s.stats["shots"][kind] += 1
	_shoot(s, kind, Vector2(tx, ty), power, 0.0, {"serve": true, "second": second, "trick": kind == "underarm"})


# ---------------------------------------------------------------- Pegarle

func _can_hit(p: P) -> bool:
	if not live or last_hitter == p.idx or p.stuck > 0.0:
		return false
	if ball.y * p.sign <= 0.0:
		return false
	if bounces == 0 and last_shot.get("serve", false):
		return false  # el saque hay que dejarlo picar
	if bounces > 1:
		return false
	var d := Vector2(ball.x, ball.y).distance_to(p.pos)
	return d <= p.reach() * TenisAbilities.mult(p, "reach") and ball.z <= 2.6


## Qué tan bien le llega (0..1): ni muy encima ni muy estirado, a una altura cómoda.
func timing(p: P) -> float:
	var d := Vector2(ball.x, ball.y).distance_to(p.pos)
	var q := 1.0 - clampf(absf(d - 0.45 * p.reach()) / p.reach(), 0.0, 1.0)
	if ball.z > 1.8:
		q -= (ball.z - 1.8) * 0.35
	if ball.z < 0.25:
		q -= 0.25
	return clampf(q, 0.15, 1.0)


## La dificultad del golpe que va a dar ahora (0..1.5).
func difficulty(p: P) -> float:
	var hv := Vector2(bvel.x, bvel.y).length()
	var d := Vector2(ball.x, ball.y).distance_to(p.pos)
	var dd := clampf(hv / 30.0, 0.0, 1.2) * 0.6
	if last_hitter >= 0 and last_hitter != p.idx:
		dd += 0.015 * players[last_hitter].a("chaos")  # al que varía no se le lee el golpe
	dd += maxf(0.0, d / p.reach() - 0.55) * 0.7
	if ball.z > 1.7:
		dd += (ball.z - 1.7) * 0.3
	if ball.z < 0.3:
		dd += 0.25
	dd += p.vel.length() / p.max_speed() * 0.25
	dd += (1.0 - p.stamina / 100.0) * 0.3
	dd += absf(bspin) * 0.15
	dd += (1.0 - timing(p)) * 0.35
	dd -= p.rhythm * 0.2  # lo que ya le viene acomodado, lo devuelve más fácil
	dd += float(last_shot.get("heavy", 0.0))  # la que viene pesada (Demolición)
	return clampf(dd, 0.0, 1.5)


func _hit(p: P, inp: Dictionary) -> void:
	var kind: String = inp.get("hit", "drive")
	var aim: Vector2 = inp.get("aim", Vector2.ZERO)
	var o: P = players[1 - p.idx]
	# El ritmo: si le llega lo mismo que antes, se acomoda; si le cambian, se descompone.
	var incoming: String = last_shot.get("kind", "drive")
	p.last_kinds.append(incoming)
	if p.last_kinds.size() > 3:
		p.last_kinds.pop_front()
	var same := p.last_kinds.count(incoming)
	p.rhythm = clampf(p.rhythm + (0.25 if same >= 2 else -0.35), 0.0, 1.0)
	var d := difficulty(p)
	rally += 1
	# A dónde: aim.x desde él (para el de arriba, se invierte); profundidad según el golpe.
	var margin := float(inp.get("margin", 0.9))
	var lateral := clampf(aim.x * p.sign, -1.0, 1.0)
	var tx := lateral * (W - margin)
	var depth: float = TenisData.SHOTS[kind]["depth"]
	if kind != "drop":
		depth = clampf(depth + aim.y * 0.12, 0.45, 0.95)
	var ty := -p.sign * clampf(H * depth, 1.5, H - margin * 0.8)
	var ctx := {"d": d, "q": timing(p), "trick": inp.get("trick", false)}
	TenisAbilities.on_hit(self, p, o, kind, ctx)
	var wf: float = ctx.get("wrong_foot", 0.0)
	if wf > 0.0:  # a contrapié: al lado contrario de para donde va (o está) el otro
		var lean := o.pos.x + o.vel.x * 0.35
		var away := -signf(lean) if absf(lean) > 0.1 else signf(tx)
		tx = lerpf(tx, away * (W - margin), wf)
	if ctx.has("push"):
		var push: Dictionary = ctx["push"]
		ty = -p.sign * clampf(absf(ty) + H * float(push["depth"]), 1.5, maxf(absf(ty), H - margin * 0.8))
		ctx["spin_add"] = float(ctx.get("spin_add", 0.0)) + float(push["spin"])
		ctx["heavy"] = push["heavy"]
	var target: Vector2 = Vector2(tx, ty) + ctx.get("target_shift", Vector2.ZERO)
	# El que insiste en lo raro: cada golpe raro seguido, más riesgo (Bublikov).
	if kind == "drop" or ctx.get("trick", false):
		p.trick_streak += 1
	else:
		p.trick_streak = 0
	p.stats["shots"]["trick" if ctx.get("curve", 0.0) > 0.0 else kind] += 1
	_shoot(p, kind, target, 0.75 + 0.25 * timing(p), d, ctx)


## Lanza la pelota hacia target con ese golpe, con el error que le toca.
func _shoot(p: P, kind: String, target: Vector2, power: float, d: float, ctx: Dictionary) -> void:
	var shot: Dictionary = TenisData.SHOTS[kind]
	var v: float = (shot["speed"] + shot["power_k"] * p.a("power")) * power * TenisAbilities.mult(p, "power") \
		* float(ctx.get("power_k", 1.0))
	var sigma := sigma_for(p, kind, d, v) * float(ctx.get("sigma_k", 1.0))
	var err := Vector2(_gauss() * sigma, _gauss() * sigma * 1.25)
	var aim_at := target + err
	var spin: float = shot["spin"] + float(ctx.get("spin_add", 0.0))
	var z0 := ball.z if not ctx.get("serve", false) else (0.8 if kind == "underarm" else 2.7)
	var from := Vector2(ball.x, ball.y)
	var sol := solve(from, z0, aim_at, v, spin, shot["net_margin"])
	var vh: float = sol.x
	var vz: float = sol.y + _gauss() * sigma * VZ_ERR  # el error vertical: a la red o larga
	# El amague: sale hacia un lado (fake) y se tuerce en el aire hasta donde iba de verdad.
	var curve: float = ctx.get("curve", 0.0)
	bcurve = 0.0
	if curve > 0.0:
		var fake_x := aim_at.x - signf(aim_at.x if absf(aim_at.x) > 0.2 else 1.0) * curve
		var T := (vz + sqrt(maxf(vz * vz + 2.0 * TenisData.GRAVITY * (1.0 + 0.35 * spin) * z0, 0.0))) \
			/ (TenisData.GRAVITY * (1.0 + 0.35 * spin))
		bcurve = 2.0 * (aim_at.x - fake_x) / maxf(T * T, 0.05)
		aim_at.x = fake_x
	var dir := (aim_at - from).normalized()
	bvel = Vector3(dir.x * vh, dir.y * vh, vz)
	bspin = spin
	live = true
	bounces = 0
	last_hitter = p.idx
	hits += 1
	_missed_reach = [99.0, 99.0]
	p.recent.append([kind, target.x / W])
	if p.recent.size() > 4:
		p.recent.pop_front()
	last_shot = {"kind": kind, "d": d, "serve": ctx.get("serve", false), "second": ctx.get("second", false),
		"trick": ctx.get("trick", false), "ability": ctx.get("ability", ""), "countered": ctx.get("countered", false),
		"curve": curve, "heavy": float(ctx.get("heavy", 0.0)), "target": target, "speed": vh, "sigma": sigma}
	event.emit("hit", {"player": p.idx, "kind": kind, "d": d, "speed": vh, "trick": last_shot["trick"],
		"ability": last_shot["ability"]})


const VZ_ERR := 0.38  # cuánto del error se va en la altura (m/s por metro de sigma)
## Las muestras fijas con que se estima el riesgo de un golpe (no gastan el azar del partido).
const SAMPLES := [[0.0, 0.0, 0.0], [1.0, 0.3, -0.5], [-1.0, -0.4, 0.6], [0.4, 1.1, 0.2], [-0.5, -1.0, -0.3],
	[1.6, -0.6, 1.0], [-1.6, 0.7, -1.1], [0.2, 1.8, -1.6], [-0.3, -1.7, 1.5], [0.9, -0.2, 2.0], [-0.8, 0.5, -2.0],
	[2.1, 1.4, 0.4], [-2.1, -1.3, -0.4], [0.6, 2.3, 0.9], [-0.6, -2.3, -0.9], [1.2, -1.9, -1.4]]


## La velocidad horizontal y vertical para caer en `to`: la más alta que pasa la red con su margen.
static func solve(from: Vector2, z0: float, to: Vector2, v: float, spin: float, margin: float) -> Vector2:
	var g := TenisData.GRAVITY * (1.0 + 0.35 * spin)
	var dist := from.distance_to(to)
	var vh := v
	var vz := 0.0
	for k in 40:
		var T := maxf(dist / vh, 0.25)
		vz = (0.5 * g * T * T - z0) / T
		var t_net := absf(from.y) / maxf(absf(to.y - from.y) / T, 0.01)
		var z_net := z0 + vz * t_net - 0.5 * g * t_net * t_net
		if z_net >= TenisData.NET_H + margin or vh < 6.0:
			break
		vh *= 0.94
	return Vector2(vh, vz)


## Qué tan probable es que ese golpe no entre (red o afuera), con el mismo error que el golpe de verdad,
## en muestras fijas. Es lo que sabe un jugador de sí mismo: lo usa la máquina para decidir.
func risk_of(p: P, kind: String, target: Vector2, d: float) -> float:
	var shot: Dictionary = TenisData.SHOTS[kind]
	var v: float = shot["speed"] + shot["power_k"] * p.a("power")
	var sigma := sigma_for(p, kind, d, v)
	var from := Vector2(ball.x, ball.y)
	var z0 := ball.z
	var spin: float = shot["spin"]
	var g := TenisData.GRAVITY * (1.0 + 0.35 * spin)
	var o: P = players[1 - p.idx]
	var bad := 0
	for s in SAMPLES:
		var to: Vector2 = target + Vector2(s[0] * sigma, s[1] * sigma * 1.25)
		var sol := solve(from, z0, to, v, spin, shot["net_margin"])
		var vz: float = sol.y + s[2] * sigma * VZ_ERR
		var dir := (to - from).normalized()
		var vy: float = dir.y * sol.x
		var t_net := absf(from.y) / maxf(absf(vy), 0.01)
		if z0 + vz * t_net - 0.5 * g * t_net * t_net < TenisData.NET_H:
			bad += 1
			continue
		var T := (vz + sqrt(maxf(vz * vz + 2.0 * g * z0, 0.0))) / g
		var land := from + dir * sol.x * T
		if absf(land.x) > TenisData.HALF_W or land.y * o.sign < 0.0 or land.y * o.sign > TenisData.HALF_L:
			bad += 1
	return float(bad) / SAMPLES.size()


## El error (en metros) de un golpe: la habilidad base, la dificultad, la potencia, el ánimo, el caos,
## la habilidad activa. Es lo mismo para la máquina y para el jugador.
func sigma_for(p: P, kind: String, d: float, v := -1.0) -> float:
	var shot: Dictionary = TenisData.SHOTS[kind]
	var skill := p.a(shot["skill"])
	if shot["skill"] == "touch":
		skill = skill * 0.75 + p.a("precision") * 0.25
	var e0 := 0.23 + (10.0 - skill) * 0.035
	var v_nat: float = shot["speed"] + shot["power_k"] * p.a("power")
	if v < 0.0:
		v = v_nat
	# Pegarle más duro de lo que le sale natural cuesta mucho; la pegada natural (el atributo), poco.
	var pf := pow(maxf(v, 1.0) / v_nat, 1.6) * pow(v_nat / (float(shot["speed"]) + 6.0), 0.4)
	var mental: float = {"focused": 1.0, "confident": 0.85, "overexcited": 1.2}.get(p.mental, 1.0)
	if p.mental == "frustrated":
		mental = 1.1 + (10.0 - p.a("composure")) * 0.04
	if p.mental == "pressure":
		mental = 1.0 + (10.0 - p.a("composure")) * 0.08
	var chaos := 1.0 + p.a("chaos") * 0.02
	var exec := float(p.ai.get("exec", 1.0))
	if kind == "drop":  # la dejada desde el fondo es un riesgo: más lejos de la red, más error
		e0 *= 1.0 + absf(p.pos.y) / 8.0
	var hands := 1.3 - 0.04 * p.a("touch")  # las manos: cuánto le pesa la difícil
	return e0 * (1.0 + hands * d) * pf * mental * chaos * exec * TenisAbilities.mult(p, "sigma") * traits_k(p, kind)


## Los rasgos (TenisData "traits"): lo que cada uno hace mejor o peor, como regla de la cancha.
##   trick_tax   cada golpe raro seguido sube el error (el que vive del show)
##   boredom     en peloteos largos de lo mismo se aburre: más error por golpe pasado el sexto
##   lateral_tax pegarle corriendo de lado le cuesta (la que está hecha para pararse y pegar)
##   return_k    el resto: menos error devolviendo el saque (menos de 1)
func traits_k(p: P, kind: String) -> float:
	var k := 1.0
	var tt := p.trait_k("trick_tax")
	if tt > 0.0 and (kind == "drop" or kind == "underarm"):
		k *= 1.0 + tt * maxf(0.0, p.trick_streak - 1)
	var bo := p.trait_k("boredom")
	if bo > 0.0 and rally > 6:
		k *= minf(1.0 + bo * (rally - 6), 1.5)
	var lt := p.trait_k("lateral_tax")
	if lt > 0.0:
		k *= 1.0 + lt * clampf(absf(p.vel.x) / p.max_speed(), 0.0, 1.0)
	var rk := p.trait_k("return_k")
	if rk > 0.0 and last_shot.get("serve", false) and last_hitter != p.idx:
		k *= rk
	return k


func _gauss() -> float:
	return clampf(rng.randfn(0.0, 1.0), -2.5, 2.5)


# ---------------------------------------------------------------- La pelota

func _ball_step() -> void:
	if not live:
		return
	var before := ball
	var g := TenisData.GRAVITY * (1.0 + 0.35 * bspin)
	bvel.z -= g * DT
	if bounces == 0:
		bvel.x += bcurve * DT
	ball += bvel * DT
	# La red.
	if before.y * ball.y < 0.0 and bounces == 0:
		var k := before.y / (before.y - ball.y)
		var zn := lerpf(before.z, ball.z, k)
		if zn < TenisData.NET_H:
			_end_by_error(last_hitter, "net")
			return
	# El bote.
	if ball.z <= 0.0 and bvel.z < 0.0:
		ball.z = 0.0
		bounces += 1
		var e := 0.7 + 0.1 * bspin
		bvel.z = -bvel.z * e
		var keep := 0.8 + 0.07 * bspin
		bvel.x *= keep
		bvel.y *= keep
		event.emit("bounce", {"pos": Vector2(ball.x, ball.y), "n": bounces})
		if bounces == 1:
			if not _landed_in():
				_end_by_error(last_hitter, "out")
				return
		elif bounces >= 2:
			_end_point(last_hitter, "winner")
			return
	# El que tenía que devolverla: qué tan cerca estuvo (para saber si fue ganador o error forzado).
	var r: P = players[1 - last_hitter]
	if ball.y * r.sign > 0.0:
		_missed_reach[r.idx] = minf(_missed_reach[r.idx], Vector2(ball.x, ball.y).distance_to(r.pos) / r.reach())
	if absf(ball.y) > H + 14.0 or absf(ball.x) > W + 14.0:
		_end_point(last_hitter, "winner")


func _landed_in() -> bool:
	var x := ball.x
	var y := ball.y
	if last_shot.get("serve", false):
		return service_box(players[last_hitter]).grow(0.02).has_point(Vector2(x, y))
	var o: P = players[1 - last_hitter]
	return absf(x) <= W + 0.02 and y * o.sign >= 0.0 and y * o.sign <= H + 0.02


## El que pegó la mandó afuera o a la red. En el saque: falta (y doble falta).
func _end_by_error(hitter: int, how: String) -> void:
	live = false
	var p: P = players[hitter]
	if last_shot.get("serve", false) and serve_try == 1:
		serve_try = 2
		event.emit("fault", {"player": hitter, "how": how})
		state = "point_over"
		wait = 0.0 if fast else 0.8
		# El segundo saque: mismo punto (no se toca el marcador).
		_retry_serve = true
		return
	var forced: bool = float(last_shot.get("d", 0.0)) >= 0.65
	var kind := "double_fault" if last_shot.get("serve", false) else ("forced" if forced else "unforced")
	_end_point(1 - hitter, kind, how)


func _end_point(winner: int, kind: String, how := "") -> void:
	live = false
	var loser := 1 - winner
	var w: P = players[winner]
	var l: P = players[loser]
	# Ganador o error forzado del que no la devolvió.
	if kind == "winner":
		if last_shot.get("serve", false) and rally <= 0:
			kind = "ace"
		elif _missed_reach[loser] <= 1.0:
			kind = "forced_missed"  # llegó y no le pegó (o no supo cómo)
	match kind:
		"winner", "ace":
			w.stats["winners" if kind == "winner" else "aces"] += 1
		"unforced":
			l.stats["ue"] += 1
		"forced", "forced_missed":
			l.stats["fe"] += 1
		"double_fault":
			l.stats["df"] += 1
	w.stats["points"] += 1
	var info := {"winner": winner, "kind": kind, "how": how, "rally": rally, "last": last_shot.duplicate(),
		"used": [players[0].used, players[1].used]}
	point_log.append(info)
	_mental_after(w, l, kind)
	TenisAbilities.on_point(self, w, l, info)
	serve_try = 1
	_retry_serve = false
	var closed := score.point_won(winner)
	info["closed"] = closed
	event.emit("point", info)
	state = "point_over"
	wait = 0.0 if fast else 1.3


# ---------------------------------------------------------------- El ánimo

func _set_mental(p: P, m: String, points: int) -> void:
	if p.mental != m:
		p.mental = m
		event.emit("mental", {"player": p.idx, "state": m})
	p.mental_left = points


## Después de cada punto. Entra y sale según rachas; la compostura aguanta más antes de frustrarse.
func _mental_after(w: P, l: P, kind: String) -> void:
	w.won_streak += 1
	w.lost_streak = 0
	w.ue_streak = 0
	l.lost_streak += 1
	l.won_streak = 0
	if kind == "unforced" or kind == "double_fault":
		l.ue_streak += 1
	for p in [w, l]:
		if p.mental_left > 0:
			p.mental_left -= 1
			if p.mental_left == 0 and p.mental != "focused":
				_set_mental(p, "focused", 0)
	var big_winner: bool = kind == "winner" and (float(last_shot.get("d", 0.0)) >= 0.9 or str(last_shot.get("ability", "")) != "")
	if big_winner:
		_set_mental(w, "overexcited", 1)
	elif w.won_streak >= 3 and w.mental != "overexcited":
		_set_mental(w, "confident", 3)
	elif w.mental == "frustrated":
		_set_mental(w, "focused", 0)
	var need := 2 + int(l.a("composure") / 5.0)  # compostura 10: tres errores seguidos
	if l.ue_streak >= need or l.lost_streak >= need + 2:
		_set_mental(l, "frustrated", 3)
	elif l.mental == "confident" and l.lost_streak >= 2:
		_set_mental(l, "focused", 0)
