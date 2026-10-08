extends "res://scripts/dreams/Plomo.gd"
## PLOMO: EL DEALER, en tres capítulos (escenas PlomoDealer1..3, chapter = 1..3). Un barrio de crayón,
## de noche y tachado; se juega siendo Lisandro.
##   1. LA ESQUINA: le quita la esquina a Don Lucho, el capo viejo (mini jefe: el Coronel, con la llave).
##   2. LA COCINA: el Químico (mini jefe, la llave) y el Coronel, que ya no quiere cobrarle a él.
##   3. EL QUE NO SE MUERE: la pelea bien Doom contra el protagonista (ráfagas de plasma, refuerzos) y el
##      giro de papeles (abajo). Cada capítulo termina con un gancho hacia el siguiente.
## Lisandro Es poderoso (doble vida, pega más) y lo que recoge son drogas: la bolsita lo
## pone "en subida" (más rápido, daño doble, la pantalla cambia de color) y después viene el bajón.
## Callejón → calle → la cocina (el Coronel, mini jefe, tiene la llave) → la casa → "el que no se
## muere": el protagonista, armado como un caballero del infierno.
## EL GIRO: cuando al que no se muere le queda un cuarto de vida, los papeles se cambian. Ahora uno
## es él, con la escopeta, y Lisandro es el jefe. A los dos tercios llama a Camila (La Devoradora) y a
## Guillermo (el marrano); a un tercio, como siempre en el peor momento, aparece Lilato.

const RUSH_TIME := 7.0
const CRASH_TIME := 3.0
const RUSH_LINES := [
	"Uff. El crayón se derrite. Los colores me gritan. Me encanta.",
	"Otra. Ahora sí veo todo. Todo es mío.",
	"Más rápido. Más fuerte. Más solo. Pero eso no lo pienso ahora.",
]
const CRASH_LINES := [
	"El bajón. Las piernas de plomo. El barrio se ve como es.",
	"Se acabó la subida. Quedé yo. No me gusto.",
]

var _twist := false
var _rush := 0.0
var _crash := 0.0
var _rush_i := 0
var _called_duo := false
var _called_lilato := false
var _white := 0.0
var _plasma_t := 3.0

@export var chapter := 3


func setup() -> void:
	dream_id = "plomo_d%d" % chapter
	title_text = "PLOMO"
	subtitle = "EPISODIO: EL DEALER\n(esta vez usted es Lisandro)"
	recap = [
		["", "Esta noche el sueño se equivoca de cuerpo."],
		["", "Las manos tienen anillos de oro. La camisa es blanca, de lino. La pistola, dorada."],
		["", "Ahora usted es Lisandro. Disfrútelo. Él lo disfrutaba."],
	]
	weapon_prefix = "dw_"
	face_prefix = "dface_"
	ceil_cols = [Color(0.02, 0.01, 0.04), Color(0.12, 0.04, 0.1)]
	floor_cols = [Color(0.06, 0.05, 0.07), Color(0.18, 0.14, 0.16)]
	wall_tex = {"#": "dl_ladrillo", "C": "dl_dibujos", "Z": "dl_azul", "W": "dl_cocina", "G": "dl_estrellas",
		"D": "dl_puerta", "L": "dl_puerta_llave", "E": "dl_salida"}
	kinds = {
		"rival": {"hp": 30, "speed": 1.8, "range": 0.9, "dmg": 10, "cd": 1.0, "attack": "melee", "h": 0.8, "sprite": "dl_rival"},
		"campanero": {"hp": 15, "speed": 2.3, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.78, "sprite": "dl_sapo"},
		"tombo": {"hp": 40, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.82, "sprite": "dl_tombo"},
		"motorizado": {"hp": 40, "speed": 2.4, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.8, "sprite": "kid_motorizado"},
		"coronel": {"hp": 220, "speed": 1.6, "range": 10.0, "dmg": 8, "cd": 1.5, "attack": "burst", "h": 1.1, "sprite": "dl_tombo"},
		"slayer": {"hp": 560, "speed": 1.3, "range": 12.0, "dmg": 9, "cd": 1.3, "attack": "burst", "h": 1.6, "sprite": "dl_slayer"},
		"lisandro": {"hp": 520, "speed": 1.4, "range": 12.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.35, "sprite": "kid_lisandro"},
		"devoradora": {"hp": 150, "speed": 1.1, "range": 9.0, "dmg": 9, "cd": 1.7, "attack": "fan:bolso_p", "h": 1.15, "sprite": "dl_devoradora"},
		"marrano": {"hp": 170, "speed": 1.6, "range": 8.0, "dmg": 10, "cd": 1.4, "attack": "throw:cadena_p", "h": 1.15, "sprite": "dl_marrano"},
		"lilato": {"hp": 150, "speed": 1.9, "range": 8.0, "dmg": 9, "cd": 1.7, "attack": "knives", "h": 0.95, "sprite": "kid_lilato"},
	}
	pickup_tex = {"balas": "balas", "cartuchos": "cartuchos", "empanada": "d_bolsita", "aguapanela": "d_pepas",
		"chaleco": "d_maletin", "llave": "llave", "escopeta": "escopeta", "caneca": "d_caneca"}
	projectile_tex = ["cuchillo", "bolso_p", "cadena_p", "plasma", "d_pepas"]
	mini_kind = "coronel"
	boss_kind = "slayer"
	summon_kind = "tombo"
	music = "plomo"
	music_boss = "plomo_boss"
	finish_note = "(el que no se muere sigue sin morirse)"
	# Lisandro: poderoso. Vida doble, pega más, ya tiene la escopeta.
	max_hp = 200.0
	dmg_mult = 1.5
	owned = [true, true, true]
	ammo = {"balas": 80, "cartuchos": 16}
	lines = {
		"start": "LISANDRO: —Mi barrio. Lo pinté yo. Con crayón y con la plata de otros. Camisa de lino. Italiana. Bueno, de Bello. Pero de lino.",
		"mini_wake": "EL CORONEL: —Lisandro. Usted me debe este mes. Y el pasado.",
		"mini_half": "EL CORONEL: —¡A mí nadie me deja de pagar!",
		"mini_die": "EL CORONEL: —Tome la llave... de todos modos ya era suya. Todo es suyo.",
		"boss_wake": "Al fondo hay alguien. Grande. Verde. No se mueve. Me está esperando.",
		"boss_p1": "LISANDRO: —¡Usted debería estar muerto! ¡Yo pagué para eso! ¡Tombos!",
		"boss_p2": "EL QUE NO SE MUERE: —... Usted pagó. Yo no cobré.",
		"boss_die": "LISANDRO: —Yo tenía todo... todo...",
		"boss_reply": "Tenía todo menos lo que importa. Eso no se vende. Ni en su esquina. Lo averigüé.",
		"key_use": "La llave del Coronel abre la casa. El Estado al servicio del barrio.",
		"locked": "Cerrada. El Coronel tiene la llave. Siempre hay un uniforme con la llave.",
		"exit_wait": "SALIDA. Todavía no: él sigue ahí.",
		"alert": "(Un sapo pita. El barrio sabe que llegué. Bien: que sepan.)",
		"vest": "Un maletín de plata. Samsonite. La mejor armadura: nadie le dispara al que paga.",
		"shotgun": "Otra escopeta. Uno nunca tiene suficientes.",
		"no_ammo": "Sin balas. A puño con anillos. Duele más.",
	}
	_chapter_setup()


## Lo que cambia en cada capítulo: subtítulo, el "anteriormente", jefes y lo que dicen.
func _chapter_setup() -> void:
	match chapter:
		1:
			subtitle = "CAPITULO 1: LA ESQUINA\n(esta noche usted es Lisandro)"
			kinds["capo"] = {"hp": 380, "speed": 1.3, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.4, "sprite": "dl_rival"}
			boss_kind = "capo"
			summon_kind = "rival"
			finish_note = "(la esquina es suya. Nadie aplaudió)"
			lines.merge({
				"boss_wake": "DON LUCHO: —Esta esquina era mía antes de que usted naciera, pelado.",
				"boss_p1": "DON LUCHO: —¡Muchachos! ¡Al de blanco!",
				"boss_p2": "DON LUCHO: —Usted no sabe lo que es esto. Esto se come a la gente. Primero a los que mandan.",
				"boss_die": "DON LUCHO: —Quédesela, la esquina. Ella sabe cobrar.",
				"boss_reply": "LISANDRO: —Mía. Todo esto es mío. (Nadie aplaude. Raro.)",
				"key_use": "La llave del Coronel abre la casa de Don Lucho. El Estado al servicio del barrio.",
				"exit_wait": "SALIDA. Todavía no: Don Lucho sigue en su esquina.",
			}, true)
		2:
			subtitle = "CAPITULO 2: LA COCINA"
			recap = [
				["", "ANTERIORMENTE EN PLOMO..."],
				["", "Lisandro se quedó con la esquina de Don Lucho. Los pelados le dicen patrón. Tienen doce años."],
				["", "Ahora quiere la cocina: el lugar donde se hace lo que se vende."],
			]
			wall_tex["Z"] = "dl_cocina"
			kinds["quimico"] = {"hp": 200, "speed": 1.4, "range": 9.0, "dmg": 9, "cd": 1.5, "attack": "fan:d_pepas", "h": 1.05, "sprite": "dl_sapo"}
			kinds["coronel"] = {"hp": 450, "speed": 1.4, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.35, "sprite": "dl_tombo"}
			mini_kind = "quimico"
			boss_kind = "coronel"
			summon_kind = "tombo"
			finish_note = "(la cocina es suya. El Coronel también)"
			lines.merge({
				"mini_wake": "EL QUIMICO: —No toque nada. Todo lo que hay aquí mata. Yo incluido.",
				"mini_half": "EL QUIMICO: —¡Usted no sabe ni hacer un huevo, y quiere la cocina!",
				"mini_die": "EL QUIMICO: —La llave... de donde el Coronel. Ahí va a ver quién manda de verdad.",
				"boss_wake": "EL CORONEL: —Lisandro. Llega tarde con la cuota. Llega tarde a todo.",
				"boss_p1": "EL CORONEL: —¡Refuerzos! ¡Que este se creyó dueño!",
				"boss_p2": "EL CORONEL: —El barrio no es suyo. Es del que le pone el uniforme.",
				"boss_die": "EL CORONEL: —Hay alguien preguntando por usted. Grande. Verde. Nosotros no lo mandamos.",
				"boss_reply": "LISANDRO: —¿Verde? ¿Quién? ... ¿Quién?",
				"key_use": "La llave del Químico abre la casa del Coronel. Huele a lo mismo que la cocina.",
				"locked": "Cerrada. El Químico tiene la llave. En la cocina.",
				"exit_wait": "SALIDA. Todavía no: el Coronel sigue cobrando.",
			}, true)
		3:
			if FinalRush.is_step("lisandro"):
				# Revancha: él ya es él (armadura); Lisandro, en subida para siempre. Camila y Guillermo vuelven.
				subtitle = "REVANCHA: LISANDRO\n(en subida, para siempre)"
				recap = [["", "Lisandro otra vez. Esta vez con la bolsita pegada a la nariz. No se le acaba nunca."]]
				weapon_prefix = "sw_"
				face_prefix = "sface_"
				max_hp = 100.0
				dmg_mult = 1.0
				armor = 100.0
				_twist = true
				_called_lilato = true  # ella va al final
				boss_kind = "lisandro"
				kinds["lisandro"]["speed"] = 2.2
				kinds["lisandro"]["cd"] = 0.8
				pickup_tex["empanada"] = "empanada"
				pickup_tex["aguapanela"] = "aguapanela"
				projectile_tex.append_array(["empanada", "aguapanela"])
				lines["boss_wake"] = "LISANDRO: —¡Volví! ¡Y no me baja! ¡Nunca me baja!"
				return
			subtitle = "CAPITULO 3: EL QUE NO SE MUERE"
			recap = [
				["", "ANTERIORMENTE EN PLOMO..."],
				["", "La esquina. La cocina. El Coronel. Todo es de Lisandro."],
				["", "Pero en el barrio alguien pregunta por él. Grande, verde, y no le entran las balas."],
				["", "Lisandro lo mandó a matar hace años. Lo sabe. Por eso ya no duerme."],
			]
			kinds["slayer"]["hp"] = 900
			lines["boss_p1"] = "Llegan tombos. No vienen a ayudar a nadie: vienen a ver quién gana."

func _place() -> void:
	var list := [
		["rival", 3.5, 14.5], ["rival", 6.5, 9.5], ["campanero", 2.5, 3.5],
		["tombo", 15.5, 3.5], ["motorizado", 19.5, 15.5], ["tombo", 11.5, 10.5], ["tombo", 19.5, 21.5],
		["campanero", 11.5, 19.5], ["rival", 16.5, 8.5], ["rival", 12.5, 13.5], ["rival", 15.5, 17.5],
		["rival", 23.5, 9.5], ["motorizado", 29.5, 2.5], ["tombo", 25.5, 1.5], ["coronel", 28.5, 5.5],
		["slayer", 27.5, 17.5],
	]
	# El mini jefe y el jefe de cada capítulo van en los mismos lugares.
	list[-2][0] = mini_kind
	list[-1][0] = boss_kind
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["empanada", 4.5, 19.5], ["balas", 7.5, 19.5], ["aguapanela", 1.5, 8.5], ["caneca", 7.5, 2.5],
			["empanada", 14.5, 12.5], ["cartuchos", 11.5, 2.5], ["aguapanela", 19.5, 2.5], ["chaleco", 12.5, 21.5],
			["balas", 19.5, 11.5], ["caneca", 15.5, 18.0], ["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5],
			["balas", 22.5, 13.5], ["cartuchos", 22.5, 21.5], ["empanada", 29.5, 21.5], ["aguapanela", 23.5, 21.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})


# ---------------------------------------------------------------- La subida y el bajón

## La bolsita: siempre se la toma (aunque tenga la vida llena). Así es esto.
func _pickups() -> void:
	if not _twist:
		for p in pickups.duplicate():
			if p["kind"] == "empanada" and p["pos"].distance_to(pos) <= 0.5:
				pickups.erase(p)
				hp = minf(max_hp, hp + 15.0)
				_rush = RUSH_TIME
				_crash = 0.0
				_bonus = 0.6
				_face_grin = 1.5
				_say(RUSH_LINES[_rush_i % RUSH_LINES.size()])
				_rush_i += 1
	super._pickups()


func _special(delta: float) -> void:
	_white = maxf(0.0, _white - delta * 1.4)
	if chapter == 3 and not _twist and boss_awake:
		_slayer_plasma(delta)
	if _twist:
		return
	if _rush > 0.0:
		_rush -= delta
		move_mult = 1.45
		dmg_mult = 3.0
		if _rush <= 0.0:
			_crash = CRASH_TIME
			_say(CRASH_LINES[_rush_i % CRASH_LINES.size()])
	elif _crash > 0.0:
		_crash -= delta
		move_mult = 0.7
		dmg_mult = 1.2
	else:
		move_mult = 1.0
		dmg_mult = 1.5


func _draw() -> void:
	super._draw()
	if state == "title" or state == "done":
		return
	if _rush > 0.0:  # los colores del crayón se vuelven locos
		var hue := fposmod(time * 0.35, 1.0)
		draw_rect(Rect2(0, 0, W, VIEW_H), Color.from_hsv(hue, 0.8, 1.0, 0.16))
	elif _crash > 0.0:
		draw_rect(Rect2(0, 0, W, VIEW_H), Color(0.1, 0.12, 0.2, 0.35))
	if _white > 0.0:
		draw_rect(Rect2(0, 0, W, 180), Color(1, 1, 1, minf(1.0, _white)))


# ---------------------------------------------------------------- El giro

func _damage(e: Ent, dmg: float) -> void:
	if e.kind == "slayer" and not _twist:
		var max_e: float = kinds["slayer"]["hp"] * (1.0 + dream_hard)
		if e.hp - dmg <= max_e * 0.25:
			e.hp = max_e * 0.25
			_role_swap(e)
			return
	super._damage(e, dmg)
	if e.kind == "lisandro" and e.state != "dead":
		var max_l: float = kinds["lisandro"]["hp"] * (1.0 + dream_hard)
		if not _called_duo and e.hp < max_l * 0.66:
			_called_duo = true
			for k in [["devoradora", summon_points[0]], ["marrano", summon_points[1]]]:
				var s := _spawn(k[0], k[1])
				s.alerted = true
				total += 1
			_say("LISANDRO: —¡Camila! ¡Guillermo! ¡Vengan, que este no se muere!")
		elif not _called_lilato and e.hp < max_l * 0.33:
			_called_lilato = true
			var l := _spawn("lilato", e.pos + Vector2(-2.0, 0.0) if walkable(e.pos + Vector2(-2.0, 0.0)) else summon_points[0])
			l.alerted = true
			total += 1
			_say("LILATO: —¿Me extrañaste? Vine en el peor momento. Siempre vengo en el peor momento.")


## Capítulo 3: el que no se muere tira ráfagas de plasma verde en abanico (además de la escopeta).
func _slayer_plasma(delta: float) -> void:
	_plasma_t -= delta
	if _plasma_t > 0.0:
		return
	_plasma_t = 3.2
	for e in enemies:
		if e.kind != "slayer" or e.state == "dead" or not los(e.pos, pos):
			continue
		var aim := (pos - e.pos).angle()
		for sp in [-0.32, -0.16, 0.0, 0.16, 0.32]:
			var dir := Vector2(cos(aim + sp), sin(aim + sp))
			projectiles.append({"tex": "plasma", "pos": e.pos + dir * 0.6, "vel": dir * 6.0, "dmg": 7.0})
		_shake_say()


func _shake_say() -> void:
	if randf() < 0.2:
		_say(["EL QUE NO SE MUERE: —...", "Plasma. Verde. Como en las películas que él veía de chiquito.",
			"EL QUE NO SE MUERE: —Usted pagó por esto, Lisandro."].pick_random())


## Al que no se muere le queda un cuarto de vida: el sueño se da vuelta.
func _role_swap(slayer: Ent) -> void:
	_twist = true
	state = "talk"
	projectiles.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicDirector.cut()
	await Dialogue.talk([
		["LISANDRO", "—¿Por qué no se muere? ¡Yo pagué para que lo mataran!"],
		["EL QUE NO SE MUERE", "—Ya sé. Y aquí sigo. Uno se acostumbra a no morirse."],
		["EL QUE NO SE MUERE", "—¿Sabe qué es lo peor de jugar con usted? Que se siente bien. Por eso nadie lo deja."],
		["", "Algo se da vuelta. El arma pesa distinto. Las manos ya no tienen anillos."],
		["", "El del otro lado ahora es Lisandro. Y el que tiene la escopeta..."],
		["", "... soy yo."],
	])
	_white = 1.0
	boss_awake = true
	mini_awake = true
	# Se cambian de lugar: uno queda donde estaba el otro.
	var mine := pos
	pos = slayer.pos
	enemies.erase(slayer)
	total -= 1
	var lis := _spawn("lisandro", mine)
	total += 1
	lis.alerted = true
	lis.state = "chase"
	ang = (lis.pos - pos).angle()
	boss_kind = "lisandro"
	summon_points = [Vector2(24.5, 15.5), Vector2(28.5, 19.5)]
	summon_kind = "tombo"
	lines["boss_p1"] = "LISANDRO: —¡Usted no era así! ¡Usted era el que corría!"
	lines["boss_p2"] = "LISANDRO: —¡Era envidia, sí! ¡¿Y qué?! ¡Usted también la tendría!"
	# Él: armadura, escopeta, sin drogas. Las bolsitas que quedaban ahora son empanadas.
	_load_kit("sw_", "sface_")
	max_hp = 100.0
	hp = 100.0
	armor = 100.0
	move_mult = 1.0
	dmg_mult = 1.0
	_rush = 0.0
	_crash = 0.0
	ammo["balas"] = maxi(ammo["balas"], 60)
	ammo["cartuchos"] = maxi(ammo["cartuchos"], 20)
	weapon = 2
	for k in ["empanada", "aguapanela"]:
		_tex[k] = load("res://assets/shooter/%s.png" % k)
		pickup_tex[k] = k
	checkpoints = checkpoints.duplicate()  # si se muere ahora, reaparece donde empezó a ser él
	checkpoints[3] = pos
	checkpoint = 3
	MusicDirector.force(music_boss)
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_say("Las bolsitas ahora son empanadas. No sé quién las cambió. Yo no fui. Creo.")


func _load_kit(wp: String, fp: String) -> void:
	for w in WEAPONS:
		_tex["w_" + w["tex"]] = load("res://assets/shooter/%s%s.png" % [wp, w["tex"]])
		_tex["w_%s_fire" % w["tex"]] = load("res://assets/shooter/%s%s_fire.png" % [wp, w["tex"]])
	for i in 5:
		_tex["face_%d" % i] = load("res://assets/shooter/%s%d.png" % [fp, i])
	_tex["face_hurt"] = load("res://assets/shooter/%shurt.png" % fp)
	_tex["face_grin"] = load("res://assets/shooter/%sgrin.png" % fp)


func _on_exit() -> void:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if FinalRush.is_step("lisandro"):
		await Dialogue.talk([["", "Lisandro, en el piso, temblando. La subida se le acabó de golpe. Como se acaban."]])
		FinalRush.next()
		return
	if chapter == 1:
		await Dialogue.talk([
			["", "La esquina es de Lisandro. Los pelados le dicen patrón."],
			["", "Al fondo de la calle, por un segundo, alguien lo mira. Grande. No se mueve."],
			["", "Cuando vuelve a mirar, no hay nadie."],
			["", "CAPITULO 1 COMPLETO. CONTINUARÁ."],
		])
		_finish()
		return
	if chapter == 2:
		await Dialogue.talk([
			["", "La cocina es de Lisandro. El Coronel ahora le cobra a otros para él."],
			["RADIO", "—Hay uno grande, verde, caminando hacia la casa. No le entran las balas. Repito: no le entran."],
			["", "Lisandro apaga la radio. Esa noche no duerme. Ni la siguiente."],
			["", "CAPITULO 2 COMPLETO. CONTINUARÁ."],
		])
		_finish()
		return
	await Dialogue.talk([
		["", "Lisandro está en el piso. Sin gafas. Sin cadenas. Más chiquito de lo que me acordaba."],
		["LISANDRO", "—Usted no sabe lo que es ser yo."],
		["", "—Ahora sí sé. Jugué un rato. Se siente poderoso."],
		["", "—Y cuando se acaba la bolsita, se siente como usted. Por eso mandó a matarme: para no sentirse así solo."],
		["", "EPISODIO COMPLETO."],
	])
	_finish()
