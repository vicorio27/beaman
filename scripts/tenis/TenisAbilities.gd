class_name TenisAbilities
extends RefCounted
## Las habilidades: un solo marco para todas (nada de lógica pegada a un jugador en el motor).
## Cada una es una entrada en DEFS con:
##   name         el nombre que sale en pantalla
##   cost         cuánto medidor gasta (0..100)
##   when         "rally" (se arma y sale en el golpe siguiente) o "reach" (cuando la pelota se le va)
##   shots        cuántos golpes dura; "window": o cuántos segundos (la estirada)
##   cooldown     puntos de espera después de usarla. Todas se acaban al terminar el punto (si no se
##                alcanzaron a usar, se pierde el medidor: es el fallo)
##   gain         cómo se carga el medidor: {evento: cantidad}. Eventos: rally (cada golpe), winner,
##                trick (golpe raro), defense (devolver una difícil), run (pegarle corriendo)
##   mods         multiplicadores mientras está activa: sigma (error), power, reach, speed
##   first        lo que cambia solo el primer golpe: sigma, power, curve (el golpe que engaña: sale
##                para un lado y se tuerce al otro, en metros), wrong_foot (0..1: a contrapié),
##                push {depth, spin, heavy} (la empuja al fondo, pica alto y le pesa al otro)
##   each         lo mismo que first, pero en cada golpe mientras dure
##   seq          o golpe por golpe: una lista (el primero, el segundo...), en vez de first
##   o_mods       lo que le hace al otro mientras está activa (sigma: el error del otro)
##   judge        "first" (la contra se juzga al arrancar) o "each" (en cada golpe: se le puede
##                acabar a la mitad)
##   tilt         puntos de frustración si pierde el punto en que la usó (el bajón después)
##   stamina_cost, stuck_hit, stuck_miss, mental   (la estirada cansa y deja en el piso; el ánimo que da)
##   counter      la contra: {type, k (cuánto le quita: 1 = todo), sigma (castigo al error), stuck
##                (más tiempo en el piso), ease (la que sigue le queda fácil al otro), text}.
##                Tipos (cada uno es una regla del motor, no del jugador; ver countered()):
##                  balanced      el otro está quieto y al centro cuando le pega: no se deja engañar
##                  awkward_ball  le llega cortada, globo o dejada, o le pega corriendo de lado
##                  alternating   la que la hizo estirarse fue al otro lado que la anterior
##                  variety       los últimos tres golpes del otro fueron todos distintos
##                  stay_back     el otro está atrás (no se viene a buscar todo) y no está frustrado
##                  deep_ball     la pelota que le llega cayó profunda: no hay pelota para atacar
##                  serve_deep    el que resta se paró bien atrás para el saque
##                  safe_ball     la que le llega es profunda y al centro (no le regalan nada)
##                  disrupt       le llega cortada, globo o dejada, o el otro cambió de lado
##                  pressure      le llega difícil, o al fondo (no le dan una cómoda para atacar)
##   ai           cuándo la usa la máquina: hit_open, hit_good, hit_hard, escaping
## El motor llama: mult(p, k), try_activate, tick, on_hit, on_point. La máquina: ai_wants.

const DEFS := {
	"por_que_no": {"name": "¿Por qué no?", "cost": 45.0, "when": "rally", "shots": 1, "cooldown": 2,
		"gain": {"rally": 3.0, "winner": 10.0, "trick": 9.0},
		"first": {"curve": 4.6, "wrong_foot": 1.0, "sigma": 1.1},
		"counter": {"type": "balanced", "k": 0.9, "sigma": 1.3, "text": "Quieto y al centro: el amague no engaña."},
		"ai": "hit_open"},
	"demolicion": {"name": "Demolición controlada", "cost": 55.0, "when": "rally", "shots": 3, "cooldown": 3,
		"gain": {"rally": 3.0, "winner": 14.0},
		"mods": {"power": 1.12, "sigma": 0.7},
		"each": {"push": {"depth": 0.0, "spin": 0.4, "heavy": 0.45}},
		"counter": {"type": "awkward_ball", "k": 0.9, "sigma": 1.6, "text": "Cortada, globo o hacerla correr: se le descuadra."},
		"ai": "hit_good"},
	"gravedad": {"name": "La gravedad es opcional", "cost": 35.0, "when": "reach", "window": 0.45, "cooldown": 2,
		"gain": {"rally": 3.0, "winner": 10.0, "run": 5.0},
		"mods": {"reach": 1.9, "speed": 1.5},
		"first": {"power": 1.15, "wrong_foot": 1.0},
		"stamina_cost": 14.0, "stuck_hit": 0.7, "stuck_miss": 1.3,
		"counter": {"type": "alternating", "k": 1.0, "sigma": 1.5, "stuck": 0.7, "text": "Hacerlo correr de lado a lado: se tira sin piso."},
		"ai": "escaping"},
	"queja": {"name": "Queja formal", "cost": 45.0, "when": "rally", "shots": 3, "cooldown": 3,
		"gain": {"rally": 2.0, "change": 7.0, "winner": 8.0},
		"o_mods": {"sigma": 1.45},
		"counter": {"type": "stay_back", "k": 1.0, "sigma": 1.3, "text": "Quedarse atrás y tranquilo: la queja no le llega."},
		"ai": "hit_good"},
	"vamos": {"name": "¡Vamos!", "cost": 50.0, "when": "rally", "shots": 2, "cooldown": 3,
		"gain": {"rally": 2.0, "winner": 12.0},
		"mods": {"power": 1.15, "sigma": 0.65},
		"counter": {"type": "deep_ball", "k": 1.0, "sigma": 1.8, "text": "Devolverle profundo: no hay pelota para lucirse."},
		"ai": "hit_good"},
	"llamada": {"name": "Llamada de larga distancia", "cost": 60.0, "when": "serve", "shots": 1, "cooldown": 2,
		"gain": {"rally": 2.0, "winner": 9.0},
		"first": {"power": 1.25, "sigma": 0.7, "heavy": 0.3},
		"counter": {"type": "serve_deep", "k": 1.0, "sigma": 1.8, "ease": 1.0, "text": "Pararse bien atrás para el saque: le da tiempo."},
		"ai": "serve_big"},
	"modo_k": {"name": "Modo Kyrgios", "cost": 45.0, "when": "rally", "shots": 3, "cooldown": 3,
		"gain": {"rally": 3.0, "winner": 10.0},
		"mods": {"power": 1.08, "sigma": 0.6}, "tilt": 2,
		"counter": {"type": "safe_ball", "k": 1.0, "sigma": 1.5, "text": "Nada de regalos: profunda y al centro, y que se caliente solo."},
		"ai": "hit_good"},
	"ejecucion": {"name": "Ejecución perfecta", "cost": 45.0, "when": "rally", "shots": 4, "cooldown": 3, "judge": "each",
		"gain": {"rally": 1.0, "clean": 5.0, "winner": 6.0},
		"mods": {"sigma": 0.65},
		"counter": {"type": "disrupt", "k": 1.0, "sigma": 1.5, "text": "Romperle la secuencia: cortadas, globos, cambios de lado."},
		"ai": "hit_good"},
	"firma": {"name": "Punto de firma", "cost": 50.0, "when": "rally", "shots": 2, "cooldown": 3,
		"gain": {"rally": 3.0, "winner": 10.0, "trick": 6.0},
		"seq": [{"power": 0.78, "wrong_foot": 0.8, "curve": 2.6, "sigma": 0.85}, {"power": 1.2, "sigma": 0.7, "wrong_foot": 1.0}],
		"counter": {"type": "pressure", "k": 0.9, "sigma": 1.4, "text": "Apurarlo siempre: no darle una cómoda."},
		"ai": "hit_any"},
	"todavia_no": {"name": "Todavía no", "cost": 50.0, "when": "rally", "shots": 3, "cooldown": 3,
		"gain": {"rally": 3.0, "defense": 11.0, "winner": 8.0},
		"mods": {"sigma": 0.9, "power": 1.08}, "first": {"sigma": 0.78}, "mental": "confident",
		"counter": {"type": "variety", "k": 1.0, "sigma": 1.45, "text": "No repetir: cada golpe distinto, y se le acaba."},
		"ai": "hit_hard"},
}


static func def(p) -> Dictionary:
	var id: String = p.data.get("ability", "")
	return DEFS.get(id, {})


## Multiplicador de lo que esté activo (1.0 si nada). La contra lo acerca a 1.
static func mult(p, key: String) -> float:
	if p.active.is_empty():
		return 1.0
	var m := float(def(p).get("mods", {}).get(key, 1.0))
	if p.active.get("countered", false):
		m = lerpf(m, 1.0, float(def(p)["counter"].get("k", 1.0)))
	return m


## Lo que la habilidad activa de `o` le hace al otro (1.0 si nada).
static func o_mult(o, key: String) -> float:
	if o.active.is_empty():
		return 1.0
	var m := float(def(o).get("o_mods", {}).get(key, 1.0))
	if o.active.get("countered", false):
		m = lerpf(m, 1.0, float(def(o)["counter"].get("k", 1.0)))
	return m


static func can_activate(sim, p, moment: String) -> bool:
	var d := def(p)
	if d.is_empty() or not p.active.is_empty() or p.cooldown > 0 or p.stuck > 0.0:
		return false
	if p.meter < float(d["cost"]) or d.get("when", "rally") != moment:
		return false
	if moment == "reach":  # la pelota tiene que venir hacia él y estar de su lado
		return sim.live and sim.last_hitter != p.idx and sim.ball.y * p.sign > 0.0
	return true


static func try_activate(sim, p, moment: String) -> bool:
	if not can_activate(sim, p, moment):
		return false
	var d := def(p)
	p.meter -= float(d["cost"])
	p.active = {"id": p.data["ability"], "shots": int(d.get("shots", 1)), "window": float(d.get("window", 0.0)),
		"countered": false, "used": false, "n": 0}
	p.stamina = maxf(0.0, p.stamina - float(d.get("stamina_cost", 0.0)))
	p.stats["abilities"] += 1
	p.used = 1
	sim.event.emit("ability", {"player": p.idx, "id": p.active["id"], "name": d.get("name", "")})
	return true


## Cada paso: la que dura un rato (la estirada) se acaba sola; si no le pegó, queda en el piso más rato.
static func tick(sim, p) -> void:
	if p.active.is_empty() or float(p.active.get("window", 0.0)) <= 0.0:
		return
	p.active["window"] = float(p.active["window"]) - TenisSim.DT
	if float(p.active["window"]) <= 0.0:
		_finish(sim, p, false)


static func _finish(sim, p, hit: bool) -> void:
	var d := def(p)
	if d.has("stuck_hit"):
		p.stuck = float(d["stuck_hit"] if hit else d["stuck_miss"])
		if p.active.get("countered", false):
			p.stuck += float(d["counter"].get("stuck", 0.0))  # se tiró sin piso: le cuesta más pararse
	if not hit:
		sim.event.emit("ability_fail", {"player": p.idx, "id": p.active["id"]})
	p.active = {}
	p.cooldown = int(d.get("cooldown", 0))


## ¿La contra está funcionando ahora? (Las pruebas pueden forzarla con sim.force_counter: 0 o 1.)
static func countered(sim, p, o) -> bool:
	if sim.force_counter >= 0:
		return sim.force_counter == 1
	return counter_rule(sim, p, o)


## La regla de la contra: lo que se ve en la cancha (dónde está el otro, qué le llegó, qué ha venido
## pegando), igual para la máquina y para el humano.
static func counter_rule(sim, p, o) -> bool:
	var c: Dictionary = def(p).get("counter", {})
	match str(c.get("type", "")):
		"balanced":
			return absf(o.pos.x) < 0.9 and o.vel.length() < 1.6
		"awkward_ball":
			var incoming: String = sim.last_shot.get("kind", "drive")
			return incoming in ["slice", "lob", "drop", "underarm"] or absf(p.vel.x) > 0.75 * p.max_speed()
		"alternating":  # las dos últimas, abiertas y cada una a un lado
			var r: Array = o.recent
			return r.size() >= 2 and absf(r[-1][1]) >= 0.5 and absf(r[-2][1]) >= 0.5 and signf(r[-1][1]) != signf(r[-2][1])
		"variety":  # en las tres últimas, por lo menos dos golpes distintos y a los dos lados
			var r: Array = o.recent.slice(-3)
			if r.size() < 3:
				return false
			var kinds := {}
			var sides := {}
			for s in r:
				kinds[s[0]] = true
				if absf(s[1]) >= 0.2:
					sides[signf(s[1])] = true
			return kinds.size() >= 2 and sides.size() >= 2
		"stay_back":
			return o.pos.y * o.sign >= TenisData.HALF_L + 1.3 and o.mental != "frustrated"
		"deep_ball":
			var r2: Array = o.recent
			return r2.size() > 0 and r2[-1].size() > 2 and float(r2[-1][2]) >= 0.86
		"serve_deep":
			return o.pos.y * o.sign >= TenisData.HALF_L + 1.2
		"disrupt":
			var incoming2: String = sim.last_shot.get("kind", "drive")
			var r3: Array = o.recent
			var side_change: bool = r3.size() >= 2 and absf(r3[-1][1]) >= 0.25 and signf(r3[-1][1]) != signf(r3[-2][1])
			return incoming2 in ["slice", "lob", "drop", "underarm"] or side_change
		"pressure":  # apurado, o sin una pelota cómoda para atacar (le llegó al fondo)
			var r5: Array = o.recent
			var deep5: bool = r5.size() > 0 and r5[-1].size() > 2 and float(r5[-1][2]) >= 0.86
			return deep5 or sim.difficulty(p) >= 0.95
		"safe_ball":  # la que le llega es profunda y por el centro: nada para inventar
			var r4: Array = o.recent
			return r4.size() > 0 and r4[-1].size() > 2 and float(r4[-1][2]) >= 0.84 and absf(r4[-1][1]) <= 0.2
	return false


## Antes de cada golpe: carga el medidor y, si hay habilidad activa, cambia el golpe (ctx: sigma_k,
## power_k, curve, wrong_foot, push, ability, trick). Y se va gastando.
static func on_hit(sim, p, o, kind: String, ctx: Dictionary) -> void:
	_gain(p, "rally", 1.0)
	if float(ctx.get("d", 0.0)) >= 0.7:
		_gain(p, "defense", 1.0)
	if p.vel.length() > 0.8 * p.max_speed():
		_gain(p, "run", 1.0)
	if kind == "drop" or ctx.get("trick", false):
		_gain(p, "trick", 1.0)
	if p.recent.size() > 0 and str(p.recent[-1][0]) != kind:
		_gain(p, "change", 1.0)
	if float(ctx.get("d", 0.0)) < 0.45:
		_gain(p, "clean", 1.0)
	if p.active.is_empty():
		return
	var d := def(p)
	var first: bool = not p.active["used"]
	p.active["used"] = true
	if first or d.get("judge", "first") == "each":  # la contra: al arrancar (o en cada golpe)
		p.active["countered"] = countered(sim, p, o)
	var n: int = p.active["n"]
	p.active["n"] = n + 1
	var cnt: bool = p.active["countered"]
	var c: Dictionary = d.get("counter", {})
	var k: float = float(c.get("k", 1.0)) if cnt else 0.0
	ctx["ability"] = p.active["id"]
	ctx["countered"] = cnt
	if cnt:
		p.used = 2
		ctx["sigma_k"] = float(ctx.get("sigma_k", 1.0)) * float(c.get("sigma", 1.0))
		if first:
			sim.event.emit("countered", {"player": p.idx, "id": p.active["id"]})
	var f: Dictionary = {}
	if d.has("seq"):
		var seq: Array = d["seq"]
		f = seq[mini(n, seq.size() - 1)]
	elif first:
		f = d.get("first", {})
	if not f.is_empty():
		ctx["sigma_k"] = float(ctx.get("sigma_k", 1.0)) * lerpf(float(f.get("sigma", 1.0)), 1.0, k)
		ctx["power_k"] = float(ctx.get("power_k", 1.0)) * lerpf(float(f.get("power", 1.0)), 1.0, k)
		ctx["curve"] = float(f.get("curve", 0.0)) * (1.0 - k)
		ctx["wrong_foot"] = float(f.get("wrong_foot", 0.0)) * (1.0 - k)
		if f.has("push"):
			var push: Dictionary = f["push"]
			ctx["push"] = {"depth": float(push["depth"]) * (1.0 - k), "spin": float(push["spin"]) * (1.0 - k),
				"heavy": float(push["heavy"]) * (1.0 - k)}
		if f.has("curve"):
			ctx["trick"] = true
		if f.has("heavy"):  # la pelota pesa (el cañonazo)
			ctx["heavy"] = float(f["heavy"]) * (1.0 - k)
	if cnt and c.has("ease"):  # contrarrestada: al otro le queda fácil (lo vio venir)
		ctx["heavy"] = -float(c["ease"])
	if first and d.has("mental") and not cnt:
		sim._set_mental(p, d["mental"], 2)
	var e: Dictionary = d.get("each", {})
	if e.has("push"):
		var ep: Dictionary = e["push"]
		ctx["push"] = {"depth": float(ep["depth"]) * (1.0 - k), "spin": float(ep["spin"]) * (1.0 - k),
			"heavy": float(ep["heavy"]) * (1.0 - k)}
	if float(p.active.get("window", 0.0)) > 0.0:
		_finish(sim, p, true)
		return
	p.active["shots"] = int(p.active["shots"]) - 1
	if int(p.active["shots"]) <= 0:
		_finish(sim, p, true)


## Al final de cada punto: corren los tiempos de espera y lo que quedó activo se acaba.
static func on_point(sim, w, l, info: Dictionary) -> void:
	var tilt := int(def(l).get("tilt", 0))
	if tilt > 0 and l.used > 0:
		sim._set_mental(l, "frustrated", tilt)
	for p in [w, l]:
		if not p.active.is_empty():
			_finish(sim, p, p.active.get("used", false))
		elif p.cooldown > 0:
			p.cooldown -= 1
	if info["kind"] in ["winner", "ace"]:
		_gain(w, "winner", 1.0)


static func _gain(p, ev: String, k: float) -> void:
	var d := def(p)
	if d.is_empty() or not p.active.is_empty():
		return
	var add := float(d.get("gain", {}).get(ev, 0.0)) * k
	if p.mental == "frustrated":
		add *= 0.5
	elif p.mental == "confident":
		add *= 1.25
	p.meter = clampf(p.meter + add, 0.0, 100.0)


## ¿La máquina la usa ahora? Cada habilidad dice su momento en "ai" (la máquina ve lo mismo que
## vería cualquiera: dónde está la pelota y qué tan difícil le llega).
static func ai_wants(sim, p, o, moment: String) -> bool:
	var d := def(p)
	if moment in ["hit", "serve"] and counter_rule(sim, p, o):
		return false  # sabe cuál es su contra: si se la están jugando, se la guarda
	match str(d.get("ai", "")):
		"hit_open":   # el amague, cuando le llega cómoda y el otro está corrido
			return moment == "hit" and sim.difficulty(p) < 0.8 and absf(o.pos.x) > 0.6
		"hit_good":   # la artillería, cuando está bien parada
			return moment == "hit" and sim.difficulty(p) < 0.55
		"hit_any":    # cuando no se la están contrarrestando (eso ya se miró arriba)
			return moment == "hit"
		"hit_hard":   # el que no se rinde, cuando le llega la difícil
			return moment == "hit" and sim.difficulty(p) >= 0.6
		"serve_big":  # el cañonazo, en el primer saque
			return moment == "serve" and sim.serve_try == 1
		"escaping":   # tirarse, cuando ya no alcanza corriendo
			if moment != "reach" or sim.bounces != 1:
				return false
			var dist: float = Vector2(sim.ball.x, sim.ball.y).distance_to(p.pos)
			return dist > p.reach() and dist < p.reach() * 1.75 and sim.ball.z < 1.8
	return false
