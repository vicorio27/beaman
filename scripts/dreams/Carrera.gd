extends "res://scripts/world/MotoRide.gd"
## Serie CARRERAS (sueños): Camila, Guillermo y Lisandro se unieron para joderle la vida; Diana
## Carolina mandó a la policía y al ejército a matarlo. Mismo motor que el recuerdo de la moto.
## Guillermo lo odia porque cree que él se acostó con Camila. No: ella lo buscó y él le dijo que no.
## Ella, furiosa, le contó a Guillermo al revés.
##   Ep. 1: Camila, de copiloto en la moto de otro, tirándole cosas. (Antes: la escena de la fiesta.)
##   Ep. 2: Guillermo en su camioneta, furioso; Camila atrás, en el platón, tirando cosas.
##   Ep. 3: los dos en moto ("la camioneta era lenta, por eso nos ganó"). Al ganar: pelea a mano
##          limpia con Guillermo (PeleaGuillermo, beat 'em up) para terminar con todo.
##   Ep. 4: Diana Carolina — no es una carrera: es una huida de la policía y del ejército.
## A mitad de pista los rivales pasan a su segunda fase:
##   Camila → La Devoradora (se infla, tira carteras y estira los brazos: si te agarra, te frena).
##   Guillermo → el marrano con gafas y cadenas de oro: tira cadenas de oro al camino.
## Ganar: llegar primero. Perder: revancha o despertarse. La huida: tres veces alcanzado = atrapado.

const NIGHT := "res://scenes/world/Night.tscn"
const FIST_FIGHT := "res://scenes/dreams/PeleaGuillermo.tscn"
const EPISODES := {
	1: {"id": "carrera1", "title": "1: CAMILA", "rivals": ["camila_copiloto"], "traffic": 14,
		"sky": [Color(0.12, 0.08, 0.2), Color(0.45, 0.2, 0.4)], "grass": [Color(0.18, 0.16, 0.22), Color(0.15, 0.13, 0.19)],
		"intro": [
			["", "ANTES. Una fiesta en la casa de Guillermo. Vallenato a todo volumen, un pernil que nadie ha tocado. Guillermo salió a comprar hielo."],
			["ÉL", "Camila. Uno cincuenta con tacones. Honguito rubio, raíz negra de tres semanas. Escote que llega a la reunión cinco minutos antes que ella."],
			["CAMILA", "—Siéntese aquí, que no muerdo. Bueno... a veces. Los martes."],
			["CAMILA", "—Guillermo se demora. Siempre se demora. Fue por hielo y vuelve con hielo, cerveza, un perro caliente y un amigo nuevo. ¿Usted también es así de lento?"],
			["", "Se le sienta al lado. Muy al lado. Huele a perfume caro, pagado con la tarjeta de Guillermo."],
			["ÉL", "Carolina Herrera. El de la botella dorada. Ciento ochenta mil pesos. Lo sé porque Guillermo me pidió prestado para comprárselo."]],
		"choices": ["—Camila, no.", "—Soy alérgico. A usted."],
		"after": [
			["CAMILA", "—¿Me está diciendo que no? ¿A mí? ¿Usted sabe cuántos me han dicho que sí esta semana?"],
			["YO", "—Le estoy diciendo que Guillermo es mi amigo. Y que ese perfume pica. Y que me debe ciento ochenta mil."],
			["CAMILA", "—Se va a arrepentir. Le voy a decir a Guillermo que usted se me tiró encima."],
			["", "Y se lo dijo. Llorando. Con rímel corrido y todo, que es más difícil de lo que parece. Le creyó en dos segundos."],
			["ÉL", "A mí, que lo conocía desde los quince, que le presté la plata del perfume, no me preguntó. Dos segundos. Ni tres."],
			["", "Ahora, en el sueño, ella va de copiloto en la moto de otro. Y tiene una bolsa llena de cosas para tirarme."]],
		"start": "CAMILA: —¡Aquí está su alergia, mi amor! ¡Carolina Herrera! ¡Original!",
		"half": "CAMILA: —¿Sabe qué es lo bueno de tener todo? Que uno lo puede perder. Bueno, usted ya no.",
		"goal": "LA META", "win": [["CAMILA", "—... Hice trampa y igual me ganó. Eso no se hace. Eso es de mal gusto."],
			["YO", "—Usted le hace trampa a Guillermo hace cinco años. Esto fue una carrera."],
			["CAMILA", "—Lo de Guillermo no es trampa, mi amor. Es administración."]]},
	2: {"id": "carrera2", "title": "2: GUILLERMO", "rivals": ["guillermo_camioneta"], "traffic": 16,
		"sky": [Color(0.5, 0.25, 0.2), Color(0.95, 0.6, 0.35)], "grass": [Color(0.4, 0.42, 0.2), Color(0.36, 0.38, 0.18)],
		"intro": [
			["", "Guillermo le creyó a ella. Claro que le creyó. Ella llora mejor de lo que yo digo la verdad."],
			["ÉL", "Guillermo. Ciento veinte kilos de amigo. Gafas Ray-Ban de las de verdad, cadena de oro de las de mentira. Lloró con Titanic. Dos veces. En cine."],
			["GUILLERMO", "—¿CON MI MUJER, PARCE? ¿CON MI MUJER? ¿EN MI CUMPLEAÑOS? ¿CON MI PERNIL SIN SERVIR?"],
			["YO", "—Yo le dije que no, Guillermo. Ella fue la que..."],
			["GUILLERMO", "—¡Mentiroso! ¡Súbase a esa moto, que lo voy a pasar por encima! ¡Con la Hilux! ¡Que es financiada, pero pasa!"],
			["", "Él trae la camioneta. Ella va atrás, en el platón, con otra bolsa de cosas. Pareja que tira unida..."]],
		"start": "GUILLERMO: —¡Usted era mi hermano! ¡Mi hermano de otra mamá! ¡De una mamá peor!",
		"half": "GUILLERMO: —¡Yo los cambié a todos por ella! ¡A todos! ¡Hasta al equipo de microfútbol!",
		"goal": "LA META", "win": [["GUILLERMO", "—... Me ganó otra vez."],
			["YO", "—Le gano porque usted maneja con rabia. Y la rabia no frena en las curvas."],
			["GUILLERMO", "—La Hilux tampoco frena en las curvas, parce. Le faltan las pastillas. Ella dijo que eso era de pobres."]]},
	3: {"id": "carrera3", "title": "3: LOS DOS", "rivals": ["camila", "guillermo"], "traffic": 18,
		"sky": [Color(0.05, 0.05, 0.1), Color(0.3, 0.12, 0.22)], "grass": [Color(0.14, 0.1, 0.16), Color(0.11, 0.08, 0.13)],
		"intro": [
			["CAMILA", "—La camioneta era muy lenta. Por eso nos ganó. Ahora vamos en moto, igualitos. Las compré a crédito. A nombre de Guillermo."],
			["GUILLERMO", "—Sí, mi amor. Así no tiene excusa."],
			["", "Perdieron dos veces con ventaja, entonces se la quitan. Así piensa la gente que nunca perdió nada de verdad."],
			["CAMILA", "—Y Lisandro manda saludos. Dice que se acuerda de usted. Con cariño. Con mucho cariño."],
			["ÉL", "Lisandro no se acuerda de nadie con cariño. Lisandro se acuerda de la gente como de una cuenta por cobrar."]],
		"start": "CAMILA: —¡Juntos somos más! ¡Más kilos, por lo menos!",
		"half": "GUILLERMO: —¡Ahora, mi amor! ¡Ahora! ... ¿Mi amor? ¿Ahora qué?",
		"goal": "LA META", "win": [["CAMILA", "—Esto no se termina acá. Lisandro todavía no jugó."],
			["GUILLERMO", "—Bájese de la moto."],
			["GUILLERMO", "—A mano limpia. Como hombres. Usted y yo. Como en el colegio, detrás de la cancha."],
			["YO", "—En el colegio le gané."], ["GUILLERMO", "—Yo le dejé ganar."], ["YO", "—... Bueno. Pero si le gano, me escucha."]]},
	4: {"id": "carrera4", "title": "4: DIANA CAROLINA", "rivals": [], "traffic": 0, "chase": true,
		"sky": [Color(0.02, 0.02, 0.06), Color(0.12, 0.1, 0.2)], "grass": [Color(0.12, 0.16, 0.12), Color(0.1, 0.13, 0.1)],
		"intro": [
			["", "Esto no lo sueño con chistes. Esto pasó."],
			["ÉL", "Iba a hacer uno sobre el helicóptero. Lo tengo. Está bueno. No..."],
			["", "Diana Carolina. Lo que perdimos los dos. Y después, la llamada."],
			["", "Ella llamó a la policía. Y la policía llamó al ejército. Por mí. Como si yo fuera una guerra."]],
		"start": "RADIO: —Es él. Es peligroso. Disparen si corre.",
		"half": "RADIO: —No lo dejen llegar al río. (Es la voz de ella.)",
		"goal": "EL RIO", "win": []},
}
## Cómo va cada rival. throw: lo que tira en la primera fase (en la segunda: bolsos o cadenas).
const RIVALS := {
	"camila_copiloto": {"name": "Camila", "tex": "camila_copiloto", "tex2": "camila_monstruo", "w": 0.34, "w2": 1.1,
		"pace": 0.93, "throw": "zapato", "monster": "camila"},
	"guillermo_camioneta": {"name": "Guillermo", "tex": "camioneta", "tex2": "camioneta_marrano", "w": 0.62, "w2": 0.62,
		"pace": 0.92, "throw": "bolso", "monster": "guillermo"},
	"camila": {"name": "Camila", "tex": "camila_moto", "tex2": "camila_monstruo", "w": 0.34, "w2": 1.1,
		"pace": 0.92, "throw": "", "monster": "camila"},
	"guillermo": {"name": "Guillermo", "tex": "guillermo_moto", "tex2": "guillermo_marrano", "w": 0.4, "w2": 0.8,
		"pace": 0.93, "throw": "", "monster": "guillermo"},
}
const THROWN := {"zapato": 0.12, "bolso": 0.12, "cadena": 0.28}
const RADIO := [
	"RADIO: —Retén en el kilómetro cuatro. Que no pase.",
	"RADIO: —Él no tiene a nadie. Nadie va a preguntar.",
	"Ella sabe que no hice nada. Por eso manda tanta gente.",
]

@export var episode := 1

var ep: Dictionary = {}
var strikes := 0
var lost := false
var _phase2 := false
var _grab_t := 3.0
var _grab_lane := 0.0
var _grab_warn := 0.0
var _radio_t := 8.0
var _radio_i := 0
var _caught_cd := 0.0
var _hud_extra: Label


func setup() -> void:
	ep = EPISODES[episode]
	sky_top = ep["sky"][0]
	sky_low = ep["sky"][1]
	haze = ep["sky"][1].lerp(Color(0.5, 0.4, 0.5), 0.3)
	grass = ep["grass"]
	hills = [ep["sky"][0].lightened(0.15), ep["sky"][0].lightened(0.08)]
	sun = false
	start_line = ep["start"]
	half_line = ep["half"]
	goal_label = ep["goal"]


func _ready() -> void:
	Narrator.top_y = 26.0  # que los textos no tapen la calle
	super._ready()
	for n in ["camila_moto", "camila_monstruo", "camila_copiloto", "guillermo_moto", "guillermo_marrano",
			"camioneta", "camioneta_marrano", "patrulla", "camion_ejercito", "reten", "cadena", "bolso", "zapato"]:
		_tex[n] = load("res://assets/moto/%s.png" % n)
	_hud_extra = _hud_label(_hud_time.get_parent(), Vector2(6, 15), Color(1, 0.6, 0.5))
	_setup_race()
	_hud_center.text = ep["title"]


func _exit_tree() -> void:
	Narrator.top_y = 40.0


## La pista de la carrera: misma ruta que el recuerdo, de noche; tráfico y rivales según el episodio.
func _setup_race() -> void:
	cars.clear()
	for s in segments:
		s.obstacles.clear()
	seed(4000 + episode)
	for k in ep["traffic"]:
		var kind: String = ["taxi", "taxi", "buseta", "camion"].pick_random()
		cars.append({"tex": _tex[kind], "offset": [-0.66, 0.0, 0.66].pick_random(), "z": randf_range(60.0, finish_z / SEG_LEN - 60.0) * SEG_LEN,
			"speed": MAX_SPEED * randf_range(0.25, 0.45), "w": {"taxi": 0.42, "buseta": 0.55, "camion": 0.6}[kind]})
	var start_z := player_z + SEG_LEN * 3.0
	var i := 0
	for r in ep["rivals"]:
		var d: Dictionary = RIVALS[r]
		cars.append({"tex": _tex[d["tex"]], "offset": -0.5 + i * 1.0, "z": start_z + i * SEG_LEN * 2.0, "speed": 0.0,
			"w": d["w"], "rival": r, "done": false, "throw_t": 3.0 + i})
		i += 1
	if ep.get("chase", false):
		# Retenes del ejército (dejan un solo carril libre) y camiones lentos.
		for k in range(160, int(finish_z / SEG_LEN) - 60, 110):
			var gap: float = [-0.66, 0.0, 0.66].pick_random()
			for lane in [-0.66, 0.0, 0.66]:
				if lane != gap:
					segments[k].obstacles.append({"kind": "reten", "tex": _tex["reten"], "offset": lane, "w": 0.6, "hit": false})
		for k in 8:
			cars.append({"tex": _tex["camion_ejercito"], "offset": [-0.66, 0.66].pick_random(),
				"z": randf_range(100.0, finish_z / SEG_LEN - 80.0) * SEG_LEN, "speed": MAX_SPEED * 0.3, "w": 0.62})
		for k in 3:  # patrullas: arrancan atrás y vienen más rápido
			cars.append({"tex": _tex["patrulla"], "offset": [-0.66, 0.0, 0.66][k], "z": -SEG_LEN * (25.0 + k * 30.0),
				"speed": MAX_SPEED * 1.03, "w": 0.42, "police": true})
	randomize()


## Antes de la cuenta regresiva: la escena del episodio (en la de Camila, él la rechaza).
func _countdown() -> void:
	MusicDirector.force("")
	await get_tree().create_timer(1.2).timeout
	_hud_center.text = ""
	if FinalRush.is_step("carrera"):
		await Dialogue.talk([["CAMILA", "—Esta vez venimos como somos de verdad. Sin filtro. Bueno, con un poquito."], ["", "Ya vienen transformados desde la largada."]])
	else:
		await Dialogue.talk(ep["intro"], ep.get("choices", []))
		if ep.has("after"):
			await Dialogue.talk(ep["after"])
	_hud_center.text = ep["title"]
	await get_tree().create_timer(0.6).timeout
	await super._countdown()
	if FinalRush.is_step("carrera") and not _phase2:
		_start_phase2()


# ---------------------------------------------------------------- Rivales, segundas fases, persecución

func _move_cars(dt: float) -> void:
	var me := position_z + player_z
	for car in cars:
		if car.has("rival"):
			_move_rival(car, dt, me)
		elif car.get("police", false):
			_move_police(car, dt, me)
		else:
			car["z"] = fposmod(car["z"] + car["speed"] * dt, finish_z)


func _move_rival(car: Dictionary, dt: float, me: float) -> void:
	if state != "ride" or car["done"]:
		return
	var d: Dictionary = RIVALS[car["rival"]]
	var gap: float = (car["z"] - me) / SEG_LEN  # >0: va adelante
	# Van pegados a él: si se queda atrás, lo pasan; si se alejan mucho, aflojan. En la recta final
	# (último 12%) ya no hay ayuda: gana el que no se cayó.
	var target: float = MAX_SPEED * d["pace"]
	if me < finish_z * 0.88:
		if gap > 12.0:
			target *= 0.85
		elif gap < -3.0:
			target = MAX_SPEED * 1.05
	target *= 1.0 + 0.05 * GameState.difficulty()  # más adelante en la historia, corren más
	if ep["rivals"].size() > 1:
		target *= 0.97  # dos rivales ya son bastante castigo
	car["speed"] = move_toward(car["speed"], target, MAX_SPEED * 0.5 * dt)
	car["z"] += car["speed"] * dt
	# Se le cruza delante cuando lo tiene cerca.
	if gap > 0.0 and gap < 12.0:
		car["offset"] = move_toward(car["offset"], clampf(player_x, -0.7, 0.7), dt * 0.45)
	# Tira cosas al camino (en la primera fase, lo que tenga a mano; en la segunda, su monstruo).
	var kind: String = d["throw"]
	if _phase2:
		kind = "bolso" if d["monster"] == "camila" else "cadena"
	if kind != "":
		car["throw_t"] -= dt
		if car["throw_t"] <= 0.0 and gap > 4.0 and gap < 40.0:
			car["throw_t"] = (1.6 if kind == "cadena" else 2.4) * (1.25 if ep["rivals"].size() > 1 else 1.0)
			var k := int(car["z"] / SEG_LEN) - 2
			if k > 0 and k < segments.size():
				segments[k].obstacles.append({"kind": kind, "tex": _tex[kind], "offset": clampf(car["offset"] + randf_range(-0.3, 0.3), -0.8, 0.8),
					"w": THROWN[kind], "hit": false})
	if car["z"] >= finish_z and not car["done"]:
		car["done"] = true
		if not lost and me < finish_z:
			_lose("%s llegó primero." % d["name"])


func _move_police(car: Dictionary, dt: float, me: float) -> void:
	if state != "ride":
		return
	car["z"] += car["speed"] * dt
	var behind: float = me - car["z"]
	if behind > 0.0 and behind < SEG_LEN * 1.5 and speed < MAX_SPEED * 0.85 and _caught_cd <= 0.0:
		strikes += 1
		_caught_cd = 2.0
		_shake = 1.0
		speed *= 0.5
		car["z"] -= SEG_LEN * 20.0
		Narrator.say(["¡Una patrulla me alcanza! Me empuja. Sigo.", "¡Otra vez! Las sirenas me taladran la cabeza.", "..."][mini(strikes - 1, 2)], true)
		if strikes >= 3:
			_lose("Lo atraparon.")
	elif behind < -SEG_LEN * 6.0:
		car["speed"] = MAX_SPEED * 0.55  # se le adelantó: ahora lo tapa por delante


func _ride(dt: float) -> void:
	super._ride(dt)
	_caught_cd -= dt
	var me := position_z + player_z
	if not _phase2 and me > finish_z * 0.5 and not ep["rivals"].is_empty():
		_start_phase2()
	if _phase2:
		_camila_arms(dt, me)
	if ep.get("chase", false):
		_radio_t -= dt
		if _radio_t <= 0.0:
			_radio_t = 9.0
			Narrator.say(RADIO[_radio_i % RADIO.size()], true)
			_radio_i += 1


func _start_phase2() -> void:
	_phase2 = true
	var msgs: Array[String] = []
	for car in cars:
		if car.has("rival"):
			var d: Dictionary = RIVALS[car["rival"]]
			car["tex"] = _tex[d["tex2"]]
			car["w"] = d["w2"]
			if d["monster"] == "camila":
				msgs.append("Camila se infla. Le revienta el vestido. Es La Devoradora.")
			else:
				msgs.append("Guillermo es un marrano. Con gafas y cadenas de oro.")
	MusicDirector.force("plomo_boss")
	_shake = 1.0
	Narrator.say(" ".join(msgs), true)


## La Devoradora estira los brazos hacia un carril (avisa antes): si lo agarra, lo frena.
func _camila_arms(dt: float, me: float) -> void:
	for car in cars:
		if not car.has("rival") or car["done"] or RIVALS[car["rival"]]["monster"] != "camila":
			continue
		var gap: float = (car["z"] - me) / SEG_LEN
		_grab_t -= dt
		if _grab_t <= 0.0 and _grab_warn <= 0.0 and gap > 0.0 and gap < 30.0:
			_grab_t = 3.4
			_grab_lane = [-0.66, 0.0, 0.66].pick_random()
			_grab_warn = 1.1
			_hud_center.text = "¡BRAZOS! " + ["IZQ", "CENTRO", "DER"][int(round(_grab_lane / 0.66)) + 1]
		if _grab_warn > 0.0:
			_grab_warn -= dt
			if _grab_warn <= 0.0:
				_hud_center.text = ""
				if absf(player_x - _grab_lane) < 0.4:
					speed *= 0.5
					_shake = 1.0
					Narrator.say("Me agarra. Me saca todo de los bolsillos. Así le hizo a Guillermo.", true)


# ---------------------------------------------------------------- Resultado

func _lose(why: String) -> void:
	if lost:
		return
	lost = true
	state = "arrival"
	speed = 0.0
	_hud_center.text = "PERDISTE"
	await get_tree().create_timer(1.2).timeout
	var i := 0 if FinalRush.active() else await Dialogue.talk([["", why]], ["Revancha", "Despertarse"])
	if i == 0:
		get_tree().reload_current_scene()
	else:
		_wake(false)


func _arrival() -> void:
	if lost:
		return
	_engine.stop()
	if ep.get("chase", false):
		await _diana()
		_wake(true)
		return
	if FinalRush.is_step("carrera"):
		await Dialogue.talk([["GUILLERMO", "—... Ya no tiene gracia perder con usted, parce. Nunca tuvo. Pero antes perdía y después nos tomábamos una."]])
		FinalRush.next()
		return
	await Dialogue.talk(ep["win"])
	if episode == 3:
		# A mano limpia con Guillermo, para terminar con todo.
		while SceneRouter.busy:
			if not is_inside_tree():
				return
			await get_tree().process_frame
		SceneRouter.go(FIST_FIGHT)
		return
	await Dialogue.talk([["", "EPISODIO %d COMPLETO." % episode]])
	_wake(true)


## El río: ella en la orilla, con el celular todavía prendido.
func _diana() -> void:
	var pic := TextureRect.new()
	pic.texture = load("res://assets/moto/diana_rio.png")
	pic.modulate.a = 0.0
	_fade.get_parent().add_child(pic)
	await create_tween().tween_property(pic, "modulate:a", 1.0, 1.2).finished
	await Dialogue.talk([
		["", "El río. Las sirenas se quedan del otro lado del puente."],
		["", "En la orilla, Diana Carolina. Con el celular prendido. Fue ella la que llamó."],
		["DIANA CAROLINA", "—Usted me quitó algo. Yo le quito todo."],
		["YO", "—Los dos perdimos algo, Diana. Pero usted además llamó al ejército."],
		["DIANA CAROLINA", "—..."],
		["YO", "—Un helicóptero, Diana. Un Black Hawk. Por un hombre con una mochila y un beagle."],
		["DIANA CAROLINA", "—Yo no pedí el helicóptero. Eso lo puso el Estado."],
		["", "Ella guarda el celular. Las sirenas se apagan. Después, el sueño también."],
		["", "EPISODIO 4 COMPLETO."],
	])


func _wake(won: bool) -> void:
	GameState.flags["dream_won"] = won
	GameState.flags["dream_return"] = ep["id"]
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


## Arriba a la izquierda, corto (no se cruza con la barra): posición o sirenas; abajo, el tiempo o las vidas.
func _update_hud() -> void:
	super._update_hud()
	if ep.is_empty() or _hud_extra == null:
		return
	if ep.get("chase", false):
		var nearest := 999.0
		for car in cars:
			if car.get("police", false):
				var b: float = (position_z + player_z - car["z"]) / SEG_LEN
				if b > 0.0:
					nearest = minf(nearest, b)
		_hud_time.text = "SIRENA %s" % ("!!!" if nearest < 8.0 else ("!!" if nearest < 20.0 else "!"))
		_hud_extra.text = "VIDAS %d" % (3 - strikes)
	else:
		var pos := 1
		for car in cars:
			if car.has("rival") and (car["z"] > position_z + player_z or car["done"]):
				pos += 1
		_hud_time.text = "POS %d/%d" % [pos, ep["rivals"].size() + 1]
		_hud_extra.text = _clock(time)
