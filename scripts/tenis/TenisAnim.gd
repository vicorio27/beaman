class_name TenisAnim
extends RefCounted
## Qué cuadro del dibujo (tools/art/draw_tenistas.py, assets/tenis/tenistas.json) le toca a un jugador
## en cada momento. Sin pantallas: TenisMatch le cuenta lo que pasa (update cada cuadro, hit, el golpe
## del otro, el saque) y lee `pose`.
##   - Corriendo de lado (lo que más se corre): los primeros pasos son pasitos (sin dar la espalda a la
##     red); si sigue, ya corre de perfil, 8 cuadros por zancada doble. Hacia la red, de espaldas (o de
##     frente, el de arriba); para atrás, los mismos cuadros al revés y con pasos más cortos. El cuadro
##     sale de lo que lleva corrido (no del tiempo): los pies no patinan. Al frenar después de correr de
##     lado, un momento con el pie de afuera estirado.
##   - Cuando el otro le pega, el saltito (split step), si está quieto.
##   - La pelota viene: se gira, la raqueta atrás y abajo, según cuánto le falta (eta).
##   - Le pega: el contacto bajo, a la cintura o alto (según la altura de la pelota), y el final.
##   - El saque: mientras espera, bota la pelota; al sacar: bajan los brazos, la tira, el trofeo, la
##     raqueta detrás de la espalda y, a los CONTACT segundos, le pega (TenisMatch le aguanta el golpe
##     a la simulación hasta ese momento, con serve_tick).

const MOVING := 0.6        # m/s: menos que eso es estar quieto
const LADO_M := 0.27       # corriendo de perfil: metros por cuadro (8 cuadros: una zancada doble de ~2.2 m)
const PASO_M := 0.2        # los pasitos de lado (4 cuadros)
const CORRE_M := 0.3       # hacia la red (8 cuadros)
const ATRAS_M := 0.22      # para atrás: pasos más cortos
const PASOS_T := 0.18      # los primeros pasos de lado son pasitos; después corre de perfil
const BOTA := 0.9          # una botada de la pelota antes de sacar
const CONTACT := 0.52      # el saque: de que arranca el movimiento a que le pega
const CONTACT_ABAJO := 0.24
const TOSS := 0.15         # cuándo suelta la pelota (la tira para arriba)
const SERVE_KEYS := [[0.0, "saque_baja"], [0.1, "saque_lanza"], [0.24, "saque_trofeo"], [0.42, "saque_rasca"]]

var idx := 0
var pose := "listo"
var t := 0.0               # el reloj propio (respirar, botar la pelota)
var act := {}              # lo que está haciendo: {"seq", "cuts", "t", "len", "keep" (hasta ahí no lo corta correr)}
var mode := ""             # corriendo: "lado", "corre", "atras" o "" (quieto)
var dir := 1.0             # de lado: hacia dónde (+1: a la derecha de la pantalla)
var t_mode := 0.0
var dist := 0.0
var stop_t := 0.0          # frenando (después de correr de lado)
var stop_dir := 1.0
var serve_t := -1.0        # el saque en curso: cuánto lleva (-1: no hay)
var underarm := false


func _init(i: int) -> void:
	idx = i


## Empieza el movimiento del saque (el golpe sale a los serve_contact() segundos).
func start_serve(under: bool) -> void:
	serve_t = 0.0
	underarm = under


func serve_contact() -> float:
	return CONTACT_ABAJO if underarm else CONTACT


## Avanza el saque un paso de la simulación; true cuando ya toca pegarle.
func serve_tick(dt: float) -> bool:
	if serve_t < 0.0:
		return false
	serve_t += dt
	return serve_t >= serve_contact()


## Le pegó: el contacto (según el golpe, el lado y la altura de la pelota) y el final.
func hit(kind: String, fore: bool, z: float, serve: bool) -> void:
	serve_t = -1.0
	if serve:
		if kind == "underarm":
			act = {"seq": ["abajo", "listo"], "cuts": [0.3], "t": 0.0, "len": 0.45}
		else:
			# (el final del saque es el paso hacia adelante: aunque arranque a correr, se ve entero)
			act = {"seq": ["saque", "saque_fin1", "saque_fin"], "cuts": [0.07, 0.16], "t": 0.0, "len": 0.42, "keep": 0.42}
		return
	if kind == "drop":
		act = {"seq": ["dejada"], "cuts": [], "t": 0.0, "len": 0.32}
	elif kind == "slice" and not fore:
		act = {"seq": ["cortado", "cortado_fin"], "cuts": [0.07], "t": 0.0, "len": 0.34}
	else:
		var side := "drive" if fore else "reves"
		var contact := side + ("_bajo" if z < 0.45 else ("_alto" if z > 1.3 else ""))
		act = {"seq": [contact, side + "_fin1", side + "_fin"], "cuts": [0.06, 0.13], "t": 0.0, "len": 0.38}


## El otro le pegó: el saltito, si está quieto (corriendo no: patinaría).
func opponent_hit(speed: float) -> void:
	if act.is_empty() and serve_t < 0.0 and speed < MOVING:
		act = {"seq": ["split1", "split2"], "cuts": [0.1], "t": 0.0, "len": 0.24, "keep": 0.0}


func celebrate() -> void:
	act = {"seq": ["celebra"], "cuts": [], "t": 0.0, "len": 1.1}


func lament() -> void:
	act = {"seq": ["bravo"], "cuts": [], "t": 0.0, "len": 1.2}


## El primer cuadro de lo que está haciendo (el del contacto, justo después de hit).
func contact_pose() -> String:
	return str(act["seq"][0]) if not act.is_empty() else pose


func update(delta: float, p, sim: TenisSim) -> void:
	t += delta
	var v: Vector2 = p.vel
	var sp := v.length()
	if sp > MOVING:
		var lateral := absf(v.x) > absf(v.y) * 0.9
		var m := "lado" if lateral else ("corre" if v.y * p.sign < 0.0 else "atras")
		var d := signf(v.x) if lateral else 1.0
		if m != mode or d != dir:
			mode = m
			dir = d
			t_mode = 0.0
			dist = 0.0
		t_mode += delta
		dist += sp * delta
		stop_t = 0.0
	else:
		if mode == "lado" and t_mode > PASOS_T + 0.1:
			stop_t = 0.15
			stop_dir = dir
		mode = ""
		t_mode = 0.0
		dist = 0.0
		stop_t = maxf(0.0, stop_t - delta)
	if serve_t >= 0.0 and sim.state != "serve":
		serve_t = -1.0
	if not act.is_empty():
		act["t"] = float(act["t"]) + delta
		# Si arranca a correr, el final del golpe (o el saltito) se corta: si no, patina en esa pose.
		if float(act["t"]) > float(act["len"]) or (sp > 2.5 and float(act["t"]) >= float(act.get("keep", 0.16))):
			act = {}
	pose = _pick(p, sim)


func _pick(p, sim: TenisSim) -> String:
	if p.stuck > 0.0:
		return "piso"
	if not p.active.is_empty() and float(p.active.get("window", 0.0)) > 0.0:
		return "tirada"
	if serve_t >= 0.0:
		if underarm:
			return "abajo_atras"
		var at := "saque_baja"
		for k in SERVE_KEYS:
			if serve_t >= float(k[0]):
				at = k[1]
		return at
	if not act.is_empty():
		var i := 0
		for c in act["cuts"]:
			if float(act["t"]) >= float(c):
				i += 1
		return str(act["seq"][i])
	if sim.state == "serve" and sim.score.server == idx:
		return "saque_bota2" if bounce_u() < 0.15 or bounce_u() > 0.85 else "saque_bota1"
	var e := eta(p, sim)
	# Quieto, se prepara con tiempo; corriendo, sigue corriendo hasta el último momento (si se pone en
	# la pose de pegar mientras todavía se mueve, patina con las piernas quietas).
	var moving: bool = p.vel.length() > MOVING
	if e < (0.12 if moving else 0.5):
		var side := "drive" if sim.on_forehand(p) else "reves"
		if e < 0.06:
			return side + "_baja"
		if e < 0.28:
			return side + "_atras"
		return side + "_prep"
	var s := "_d" if dir > 0.0 else "_i"
	match mode:
		"lado":
			if t_mode < PASOS_T:
				return "paso%d%s" % [1 + int(dist / PASO_M) % 4, s]
			return "lado%d%s" % [1 + int(dist / LADO_M) % 8, s]
		"corre":
			return "corre%d" % (1 + int(dist / CORRE_M) % 8)
		"atras":
			return "corre%d" % (8 - int(dist / ATRAS_M) % 8)
	if stop_t > 0.0:
		return "frena_d" if stop_dir > 0.0 else "frena_i"
	return "listo" if fmod(t, 0.8) < 0.4 else "listo2"


## Botando la pelota antes de sacar: 0 y 1 en la mano, 0.5 en el piso.
func bounce_u() -> float:
	return fmod(t, BOTA) / BOTA


## El que saca apretó (inputs: los de este paso de la simulación): arranca el movimiento y el golpe le
## llega a la simulación cuando la raqueta encuentra la pelota, con lo que apretó al empezar (la
## dirección, por abajo...). `held` guarda eso entre un paso y otro.
static func hold_serve(anims: Array, sim: TenisSim, inputs: Array, held: Dictionary) -> void:
	var s: int = sim.score.server
	var a: TenisAnim = anims[s]
	var inp: Dictionary = inputs[s]
	if a.serve_t < 0.0:
		if str(inp.get("hit", "")) == "":
			return
		held["inp"] = inp.duplicate()
		held["inp"]["ability"] = false  # (la habilidad ya se pidió ahora)
		a.start_serve(str(inp["hit"]) == "underarm")
	if a.serve_tick(TenisSim.DT):
		inputs[s] = held["inp"]
	else:
		var wait := inp.duplicate()
		wait["hit"] = ""
		inputs[s] = wait


## Alguien le pegó (el evento "hit" de la simulación): el golpe del que pegó y el saltito del otro.
static func on_hit(anims: Array, sim: TenisSim, d: Dictionary) -> void:
	var p = sim.players[d["player"]]
	var o = sim.players[1 - p.idx]
	anims[p.idx].hit(str(d["kind"]), sim.on_forehand(p), sim.ball.z, sim.last_shot.get("serve", false))
	anims[o.idx].opponent_hit(o.vel.length())


## Cuánto le falta a la pelota para llegarle (s), o INF si no le viene (o no la alcanza).
static func eta(p, sim: TenisSim) -> float:
	if not sim.live or sim.last_hitter == p.idx or sim.last_hitter < 0:
		return INF
	var v := Vector2(sim.bvel.x, sim.bvel.y)
	if v.y * p.sign <= 0.1 or v.length() < 1.0:
		return INF
	var rel: Vector2 = p.pos - Vector2(sim.ball.x, sim.ball.y)
	var dirv := v.normalized()
	var along := rel.dot(dirv)
	if along < -0.3 or absf(rel.cross(dirv)) > p.reach() * 2.0:
		return INF
	return maxf(0.0, along - p.reach() * 0.4) / v.length()
