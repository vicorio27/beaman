class_name DayTasks
## ENCARGOS DEL DÍA. Algunos días tienen algo propio, que se anuncia en la mañana y queda en la lista
## de misiones hasta la noche: ver a Zaida (cinco veces: ayuda que se cobra), llevar a Lukas a la
## veterinaria, una meta personal, o un favor para un amigo. Si no se cumple, a la mañana siguiente se nota.
## Estado: flags "hoy_tarea" (id), "hoy_ok" (bool), "hoy_base" (lo que había al empezar el día).

## día -> id del encargo
const CALENDAR := {
	4: "comer3", 5: "rosa", 7: "vet1", 8: "zaida1", 10: "alcancia", 12: "samuel", 14: "truco", 15: "zaida2",
	17: "wilson", 19: "no_pedir", 20: "german", 22: "zaida3", 24: "trabajar", 26: "mono", 27: "vet2",
	30: "zaida4", 31: "marta", 33: "vet3", 34: "bano", 37: "zaida5", 40: "efrain", 42: "tumba",
	# El tramo final: cada día algo, alrededor de lo que se viene (la tos, la bicicleta, el cumpleaños).
	35: "alcancia2", 36: "wilson2", 38: "pilar_tos", 39: "mono2", 41: "german2", 43: "samuel2",
	44: "rosa2", 45: "marta2", 46: "efrain2", 47: "afeitarse", 48: "meta_bici",
}

## id -> [con quién se habla ("" = se cumple solo), escena donde está, línea de la mañana]
const TASKS := {
	"comer3": ["", "", "Hoy: comer tres veces."],
	"alcancia": ["", "", "Hoy: $10.000 más en la alcancía."],
	"truco": ["", "", "Hoy: enseñarle algo a Lukas."],
	"no_pedir": ["", "", "Hoy: no pedir ni una moneda."],
	"trabajar": ["", "", "Hoy: trabajar. La obra, el reparto o la ruta."],
	"bano": ["", "", "Hoy: bañarse."],
	"tumba": ["", "Parque", "Hoy: el árbol amarillo del Parque."],
	"vet1": ["veterinaria", "Parque", "Hoy: las vacunas de Lukas. La Dra. Pilar, en el Parque, antes de las 6."],
	"vet2": ["veterinaria", "Parque", "Hoy: el control de Lukas. Tosió toda la noche. La Dra. Pilar, en el Parque."],
	"vet3": ["veterinaria", "Parque", "Hoy: se acabaron las gotas de Lukas. La Dra. Pilar, en el Parque."],
	"rosa": ["rosa", "City", "Doña Rosa mandó a decir que la busque en el puesto. Que es urgente."],
	"samuel": ["samuel", "City", "Samuel amaneció con fiebre. Tiembla."],
	"wilson": ["wilson", "City", "Wilson necesita brazos para llevar las latas a la chatarrería."],
	"german": ["german", "City", "Hoy cumple años Don Germán. No le gusta que se sepa. Doña Leonor vende flores en el Parque."],
	"mono": ["mono", "Parque", "El Mono tiene \"un show\" en el Parque. Necesita público."],
	"marta": ["marta", "City", "Marta no abrió la tienda esta mañana. El cobrador del gota a gota anda por el barrio."],
	"efrain": ["efrain", "Parque", "Don Efraín mandó a llamarlo al Parque."],
	"alcancia2": ["", "", "Hoy: $15.000 más en la alcancía. La bicicleta no se junta sola."],
	"afeitarse": ["", "", "Hoy: bañarse y arreglarse la barba. Faltan tres días."],
	"meta_bici": ["", "", "Hoy: completar la alcancía ($150.000). Mañana es la última visita."],
	"wilson2": ["wilson", "City", "Wilson consiguió un carrito con las cuatro ruedas. Necesita brazos, y que alguien lo vea."],
	"pilar_tos": ["veterinaria", "Parque", "La Dra. Pilar lo oyó toser desde la veterinaria. Mandó a decir que pase por el Parque."],
	"mono2": ["mono", "Parque", "El Mono anuncia \"segunda temporada\" en el Parque. Con coreografía."],
	"german2": ["german", "City", "A Don Germán se le pegó la puerta del garaje. Dice que no es urgente. Lo dijo tres veces."],
	"samuel2": ["samuel", "City", "Samuel lo anda buscando por el río. Trae algo envuelto en una bolsa."],
	"rosa2": ["rosa", "City", "Doña Rosa mandó a decir que pase por el puesto. Que tiene \"algo para lo del cumpleaños\"."],
	"marta2": ["marta", "City", "Marta abrió el café temprano. Mandó a decir que pase, \"pero rápido, que no es caridad\"."],
	"efrain2": ["efrain", "Parque", "Don Efraín mandó a decir que pase por el Parque. Que \"es de la bicicleta\"."],
	"zaida1": ["zaida_dia", "Centro", "En la ventana empañada del café alguien escribió: \"Z. Centro\"."],
	"zaida2": ["zaida_dia", "City", "Zaida está en la plaza."],
	"zaida3": ["zaida_dia", "Parque", "Un niño trae razón: Zaida lo espera en el Parque."],
	"zaida4": ["zaida_dia", "Centro", "Zaida tiene \"una buena noticia\". En el centro, cerca de la Defensoría."],
	"zaida5": ["zaida_dia", "City", "Zaida, en la plaza. Dice que es la última vez."],
}

const ZAIDA_POS := {"Centro": Vector2(236, 214), "City": Vector2(640, 430), "Parque": Vector2(440, 300)}
const ZAIDA_TINT := Color(0.86, 0.66, 0.96)


## Hoy (o "").
static func today() -> String:
	return str(GameState.flags.get("hoy_tarea", ""))


## La mañana: abre el encargo del día (si hay). Devuelve la línea para el resumen.
static func open_day() -> Array:
	var g := GameState
	var f := g.flags
	f.erase("hoy_tarea")
	f.erase("hoy_ok")
	var id: String = CALENDAR.get(g.day, "")
	if id == "":
		return []
	# Lo que ya no tiene sentido: Lukas ya no está, o la tumba con Lukas vivo.
	if id.begins_with("vet") and not g.lukas_alive():
		return []
	if id == "tumba" and g.lukas_alive():
		id = "bano"
	if id == "truco" and _tricks() >= g.LUKAS_TRICKS.size():
		id = "comer3"
	# La alcancía, si la bicicleta ya está (o ya alcanza, o no hay cambuche): que coma.
	if id in ["alcancia2", "meta_bici"] and (f.get("bici_comprada", false) or not g.has_cambuche()
			or (id == "meta_bici" and int(g.cambuche["alcancia"]) >= g.GIFT_GOAL)):
		id = "comer3"
	f["hoy_tarea"] = id
	f["hoy_ok"] = false
	f["hoy_base"] = {"alcancia": int(g.cambuche["alcancia"]) if g.has_cambuche() else 0, "trucos": _tricks()}
	g.quests.erase("hoy_" + id)
	g.start_quest("hoy_" + id)
	return [TASKS[id][2]]


## Lo que se cuenta en la mañana cuando él le quedó mal a alguien (rota: GameState.rota).
const FALLAS := {
	"rosa": ["Doña Rosa lo esperó ayer con el tinto servido. Se lo tomó ella, frío, para no botarlo.",
		"Doña Rosa le contó a toda la fila de la arepa que él no fue. Con nombre y apellido. El apellido se lo inventó."],
	"samuel": ["Samuel lo esperó ayer. Dice que no importa. Lo dice dos veces.",
		"Samuel le mandó razón con un pelado: que uno no deja botado a un viejo. Que el viejo es él."],
	"wilson": ["Wilson cargó solo ayer. Dice que le salió más barato: no tuvo que repartir.",
		"Wilson lo buscó ayer tres cuadras empujando el carrito. Ahora le duele la espalda a nombre de él."],
	"german": ["Don Germán le guardó el pan ayer. Hoy está duro. Se lo va a dar igual.",
		"Don Germán preguntó por él ayer. Dos veces. Después barrió lo que ya estaba barrido."],
	"mono": ["El Mono lo esperó ayer. Tocó solo. Dice que sonó mejor. Miente feo.",
		"El Mono le compuso una canción a la gente que no llega. Tiene tres estrofas y él sale en las tres."],
	"marta": ["Marta lo esperó ayer. Dice que no lo estaba esperando. Tenía dos tintos.",
		"Marta dice que ayer ni se acordó de él. Lo dice antes de que nadie le pregunte."],
	"efrain": ["Don Efraín lo esperó ayer. Gloria, la muñeca, también: sin parpadear, con su único ojo.",
		"Don Efraín le dejó una nota en la reja: Pase. Con mayúscula y punto. Es lo más bravo que escribe."],
	"veterinaria": ["La Dra. Pilar le guardó la cita ayer. Dice que la tos no espera.",
		"La Dra. Pilar le mandó razón: que la tos no se cura por no ir. Que ella ya probó."],
}


## La noche: cómo quedó el encargo. Devuelve líneas para el resumen.
static func close_day() -> Array:
	var g := GameState
	var f := g.flags
	var id := today()
	if id == "":
		return []
	var lines := []
	if id == "no_pedir" and int(f.get("pidio_dia", -1)) != g.day:
		_done(false)
		lines.append("No pidió ni una vez.")
		g.change_mood(8.0)
	if not f.get("hoy_ok", false):
		g.quests.erase("hoy_" + id)
		if id.begins_with("vet"):
			g.change_mood(-10.0)
			lines.append("La cita de Lukas era ayer. Pasó la noche tosiendo.")
		elif id.begins_with("zaida"):
			lines.append(g.rota("falla_zaida", ["Zaida lo esperó ayer.",
				"Zaida lo esperó ayer. Se fumó el cigarrillo de los dos.",
				"Ayer Zaida le guardó puesto en la banca. Se lo alquiló a otro.",
				"Zaida le mandó razón con el de los minutos: que ni se le ocurra volver. O sea que vuelva."]))
		elif TASKS[id][0] != "":
			g.change_mood(-5.0)
			var who := str(TASKS[id][0])
			lines.append(g.rota("falla_" + who, FALLAS.get(who, ["Ayer le falló a alguien."])))
		else:
			lines.append(g.rota("falla_meta", ["La meta de ayer quedó sin cumplir.",
				"Lo de ayer quedó para hoy. Lo de hoy, ya se verá.",
				"La meta de ayer sigue ahí, como el letrero de SE VENDE: nadie la compra.",
				"Lo de ayer no se hizo. El día no se enteró. Él sí."]))
	if f.get("zaida_chisme", false) and id == "zaida2":
		f.erase("zaida_chisme")
		lines.append("Anoche alguien preguntó por él en el puente. Por su nombre.")
	f.erase("hoy_tarea")
	return lines


## Cada tanto (desde QuestDirector): las metas que se cumplen solas, y Zaida donde toca.
static func tick(scene: Node) -> void:
	var g := GameState
	var f := g.flags
	var id := today()
	if id == "" or f.get("hoy_ok", false) or not TimeManager.running:
		return
	var base: Dictionary = f.get("hoy_base", {})
	var ok := false
	match id:
		"comer3":
			ok = int(g.stats["food_eaten"]) >= 3
		"alcancia":
			ok = g.has_cambuche() and int(g.cambuche["alcancia"]) >= int(base.get("alcancia", 0)) + 10000
		"alcancia2":
			ok = g.has_cambuche() and int(g.cambuche["alcancia"]) >= int(base.get("alcancia", 0)) + 15000
		"meta_bici":
			ok = f.get("bici_comprada", false) or (g.has_cambuche() and int(g.cambuche["alcancia"]) >= g.GIFT_GOAL)
		"truco":
			ok = _tricks() > int(base.get("trucos", 0))
		"trabajar":
			ok = int(f.get("trabajo_ultimo", -1)) == g.day
		"bano", "afeitarse":
			ok = g.hygiene >= 85.0
		"tumba":
			ok = scene != null and scene.name == "Parque"
	if ok:
		_done(true)
		return
	if id.begins_with("zaida") and scene and scene.name == TASKS[id][1] and scene.find_child("ZaidaDia", true, false) == null:
		var h := TimeManager.hour()
		if h >= 8 and h < 19:
			var z: Node2D = QuestDirector._spawn_npc(scene, "zaida_dia", "ZaidaDia", 3, ZAIDA_POS[scene.name], ZAIDA_TINT)
			z.name = "ZaidaDia"


## Las conversaciones del encargo. Devuelve true si se encargó de la charla.
static func talk(npc_id: String) -> bool:
	var id := today()
	if id == "" or GameState.flags.get("hoy_ok", false) or TASKS[id][0] != npc_id:
		return false
	match id:
		"vet1", "vet2", "vet3", "pilar_tos":
			var h := TimeManager.hour()
			if h < 8 or h >= 18:
				return false
			if id == "pilar_tos":
				await _pilar_tos()
			else:
				await _vet(id)
		"zaida1", "zaida2", "zaida3", "zaida4", "zaida5":
			await _zaida(int(id.right(1)))
		"rosa":
			await _rosa()
		"samuel":
			if not await _samuel():
				return true
		"wilson":
			await _wilson()
		"german":
			if not await _german():
				return true
		"mono":
			await _mono()
		"marta":
			await _marta()
		"efrain":
			await _efrain()
		"wilson2":
			await _wilson2()
		"mono2":
			await _mono2()
		"german2":
			await _german2()
		"samuel2":
			await _samuel2()
		"rosa2":
			await _rosa2()
		"marta2":
			await _marta2()
		"efrain2":
			await _efrain2()
	_done(true)
	return true


static func _done(say: bool) -> void:
	var id := today()
	GameState.flags["hoy_ok"] = true
	GameState.complete_quest("hoy_" + id)
	if say and TASKS[id][0] == "":
		GameState.change_mood(8.0)
		Narrator.say({"comer3": "(Tres comidas.)",
			"alcancia": "(Diez mil más en la alcancía.)",
			"truco": "(Lukas aprendió algo.)",
			"trabajar": "(Trabajó.)",
			"bano": "(Bañado.)",
			"alcancia2": "(Quince mil más en la alcancía. La bicicleta se acerca de a poquito, como el bus cuando uno va de afán.)",
			"afeitarse": "(Bañado. La barba, recortada: es lo único que le queda para peinar.)",
			"meta_bici": "(La bicicleta ya está.)" if GameState.flags.get("bici_comprada", false) else "(La alcancía ya da para la bicicleta. Don Efraín la tiene, en el Parque.)",
			"tumba": "(El árbol amarillo. Se sienta al lado de la tierra removida. No se mueve en un rato.)"}.get(id, "Hecho."))


static func _tricks() -> int:
	var n := 0
	for t in GameState.LUKAS_TRICKS:
		if GameState.lukas_knows(t):
			n += 1
	return n


# ---------------------------------------------------------------- Lukas a la veterinaria

static func _vet(id: String) -> void:
	var g := GameState
	match id:
		"vet1":
			await Dialogue.talk([
				["DRA. PILAR", "—A ver ese paciente. Lukas, mi amor, esto no duele. (Le duele.)"],
				["", "(Lukas lo mira con traición profunda. Le dan una galleta. Lo perdona.)"],
				["DRA. PILAR", "—Está muy bien para la vida que lleva. Ustedes dos se cuidan, se nota. Cuídelo más."],
			])
			g.change_mood(8.0)
		"vet2":
			await Dialogue.talk([
				["DRA. PILAR", "—Escúchelo usted mismo. (Le pone el estetoscopio.) ¿Oye ese ruido? Es el corazón haciendo fuerza."],
				["", "(Escucha. Aprieta la mandíbula.)"],
				["DRA. PILAR", "—Que no corra. Que coma poquito y seguido. Y que esté con usted. Eso es lo que más le sirve."],
				["", "(Asiente.)"],
			])
			g.change_mood(4.0)
		"vet3":
			var pay := g.money >= 8000
			await Dialogue.talk([
				["DRA. PILAR", "—Las gotas. Son ocho mil."],
				["", "(Pone ocho mil en el mostrador.)" if pay else "(Se voltea los bolsillos. Lukas pone cara de huérfano.)"],
				["DRA. PILAR", "—Gracias." if pay else "—Lléveselas. Me paga cuando se gane la lotería. Que juegue no es requisito."],
				["", "(Lukas se toma las gotas sin pelear. Ya no pelea por nada.)"],
			])
			if pay:
				g.add_money(-8000)


# ---------------------------------------------------------------- Los amigos

static func _rosa() -> void:
	await Dialogue.talk([
		["DOÑA ROSA", "—¡Por fin! Cuídeme el puesto, que tengo cita en el Seguro. No regale nada. Bueno, a los niños sí. A los policías no."]])
	GameState.flags["f_puesto_hecho"] = true
	SceneRouter.go("res://scenes/world/Puesto.tscn")  # el minijuego del puesto (antes solo se contaba)


static func _samuel() -> bool:
	if GameState.count("aguapanela") == 0:
		await Dialogue.talk([["SAMUEL", "—Estoy bien. (Tirita.) Si me trae algo calientico, no se lo desprecio. Doña Fabiola regala en el Parque."]])
		return false
	GameState.remove_item("aguapanela")
	await Dialogue.talk([
		["", "(Le da la aguapanela. Samuel la agarra con las dos manos, como si fuera un pájaro.)"],
		["SAMUEL", "—Once años en la calle. Nunca nadie me había traído nada caliente que no fuera una patrulla."],
		["SAMUEL", "—Si me muero, le dejo mi cobija. Si no, también. Es muy fea para mí."],
	])
	GameState.change_mood(8.0)
	return true


static func _wilson() -> void:
	await Dialogue.talk([
		["WILSON", "—Cuarenta kilos de latas. Usted carga y yo hablo. Es una división del trabajo muy moderna. La vi en un video."],
		["", "(Dos horas empujando un carrito con una rueda que va para otro lado.)"],
		["WILSON", "—Mitad y mitad. Bueno, sesenta y cuarenta. Yo puse el carrito. Y el carácter. Y la rueda, que es lo más difícil de poner."],
	])
	TimeManager.skip(2.0)
	GameState.add_money(8000)


static func _german() -> bool:
	if GameState.count("flor") == 0:
		await Dialogue.talk([["DON GERMAN", "—¿Qué me mira así? Hoy es un día como cualquiera. No me haga caso. (Hoy no es un día como cualquiera.)"]])
		return false
	GameState.remove_item("flor")
	await Dialogue.talk([
		["", "(Le da el clavel. Don Germán lo mira un rato largo.)"],
		["DON GERMAN", "—Mi señora me regalaba uno todos los años. Desde que se murió, nadie se acordaba."],
		["DON GERMAN", "—Usted no se acordó. Le contaron. ... Igual. Gracias, mijo. Sesenta y ocho. Ella decía que yo iba a llegar a cien por terco."],
		["", "(Le da un pan en una bolsa, como si fuera para llevar.)"],
	])
	GameState.add_item("pan")
	GameState.change_mood(10.0)
	return true


static func _mono() -> void:
	await Dialogue.talk([
		["EL MONO", "—¡Mi público! Siéntese ahí. Usted aplaude cuando yo le cierre el ojo."],
		["", "(Una hora de boleros desafinados. El Mono le cierra el ojo. Él aplaude hasta que le duelen las manos. Sin sonreír.)"],
		["", "(La gente se para a ver. No por el Mono: por el que aplaude con esa cara. Echan monedas.)"],
		["EL MONO", "—Mitad y mitad. Usted es el mejor público que he tenido. Bueno, el único que vino."],
	])
	TimeManager.skip(1.0)
	GameState.add_money(5000)
	GameState.change_mood(10.0)


static func _marta() -> void:
	var i := await Dialogue.talk([
		["", "(La tienda de Marta, con la reja a medio bajar. Adentro, un tipo con una libreta.)"],
		["COBRADOR", "—La señora debe el veinte por ciento diario. Hoy, o le quitamos la nevera."],
		["MARTA", "(bajito) —No se meta. Por favor."],
	], ["Hacerme el loco", "Pagarle $10.000 de lo de ella"])
	# Se meta como se meta, el cobrador le pasa la deuda: "el que se mete, responde" (el torneo de
	# tenis llega mañana: scripts/systems/Torneo.gd).
	if i == 1 and GameState.money >= 10000:
		GameState.add_money(-10000)
		await Dialogue.talk([
			["COBRADOR", "—Abono. (Se guarda la plata. Abre la libreta. Tacha a Marta. Escribe otra cosa.)"],
			["COBRADOR", "—El que abona, responde. Así es la cosa. La deuda de la señora ahora es suya: ochenta mil, en cuatro días."],
			["COBRADOR", "—Y si no, la mochila. Con lo que tenga adentro. (Mira la mochila. No le impresiona.) Bueno. La mochila."],
			["MARTA", "—Usted es un idiota. ... Me la quitó a mí y se la echó encima. Idiota. ... Gracias, idiota. Pero idiota."],
		])
	else:
		await Dialogue.talk([
			["", "(Se le acerca mucho. Demasiado. No dice nada. Lo mira sin parpadear.)"],
			["COBRADOR", "—¿Qué? ¿Qué me mira? ... Diga algo. ... DIGA ALGO."],
			["", "(Nada. Ni un parpadeo.)"],
			["COBRADOR", "—... Volvemos otro día. (Se va. Rápido.)"],
			["", "(Vuelve. Asoma la cabeza por la reja, sin entrar.)"],
			["COBRADOR", "—Y como usted se metió, la deuda de la señora ahora es suya. Ochenta mil. Cuatro días. O la mochila. (Se va otra vez. Más rápido.)"],
			["MARTA", "—Eso fue muy raro. Y muy útil. Y muy caro. ¿Usted está bien?"],
			["", "(...)"], ["MARTA", "—No me contestés. Mejor no me contestés."],
		])
		GameState.add_locura(1)
	Torneo.deuda()
	GameState.change_mood(6.0)


static func _efrain() -> void:
	var dead := not GameState.lukas_alive()
	await Dialogue.talk([
		["DON EFRAIN", "—Tome. Lo talle yo. Con una navaja y mucho tiempo, que es lo único que me sobra."],
		["", "(Un perrito de madera. Orejas largas. Cola parada. Una manchita quemada en el lomo.)"],
		["", "(Es Lukas. Lo aprieta en la mano. Le tiembla la mandíbula.)" if dead
			else "(Es Lukas. Lukas lo huele, lo mira y se aburre.)"],
		["DON EFRAIN", "—Gloria le manda saludes. Bueno, no. Pero si hablara, le mandaría."],
	])
	GameState.change_mood(10.0 if dead else 6.0)


# ---------------------------------------------------------------- El tramo final (días 35-48)

static func _yo(anim: String) -> void:
	Conversations._yo(anim)


static func _wilson2() -> void:
	await Dialogue.talk([
		["WILSON", "—Socio. Conseguí un carrito con las cuatro ruedas. Las cuatro van para el mismo lado. No sé qué hacer con tanta tecnología."],
		["WILSON", "—Hoy es cartón. El cartón no pesa, pero ocupa. Como mi cuñado."],
	])
	_yo("recoger")
	await Dialogue.talk([
		["", "(Dos horas apilando cartón en un carrito que, ahora sí, va derecho. Wilson extraña la rueda vieja: \"tenía personalidad\".)"],
		["WILSON", "—Sesenta y cuarenta, como siempre. Es tradición. Las tradiciones no se discuten: se cobran."],
	])
	TimeManager.skip(2.0)
	_yo("plata")
	GameState.add_money(8000)


static func _pilar_tos() -> void:
	await Dialogue.talk([["DRA. PILAR", "—Siéntese en la camilla. ... Sí, en la de los perros. Es la única que tengo."]])
	_yo("tos")
	var lines := [
		["", "(Le pone en la espalda el estetoscopio. El mismo de Lukas. Lo limpia antes. Lo piensa y lo limpia otra vez.)"],
		["DRA. PILAR", "—Respire. ... Otra vez. ... Yo soy de perros, ¿sabe? Pero eso suena a perro viejo que duerme en el patio."],
		["DRA. PILAR", "—Vaya al puesto de salud. ... Ya sé: sin papeles, sin EPS, sin dirección. Entonces tome esto. Es para perros grandes."],
		["", "(Un jarabe con un beagle sonriente en la etiqueta. Dos cucharadas en la noche. Sabe a hígado.)"],
	]
	if GameState.lukas_alive():
		lines.append(["", "(Lukas lo mira desde el piso, satisfecho: por fin le toca a otro.)"])
	await Dialogue.talk(lines)
	GameState.flags["tos"] = maxf(0.0, GameState.tos() - 5.0)
	GameState.change_mood(6.0)


static func _mono2() -> void:
	await Dialogue.talk([
		["EL MONO", "—¡Volvió mi público! Hoy hay coreografía. Usted no baila: usted es la coreografía. Se para ahí y no se mueve."],
		["", "(Una hora de pie en la glorieta, quieto, mientras el Mono le canta boleros alrededor, como a un poste.)"],
		["", "(La gente echa monedas. Al poste.)"],
		["EL MONO", "—Le iba a pedir que se peinara para el show. ... Ya no hace falta. Usted es moderno."],
		["EL MONO", "—Setenta y treinta. El poste no canta."],
	])
	TimeManager.skip(1.0)
	_yo("plata")
	GameState.add_money(6000)
	GameState.change_mood(8.0)


static func _german2() -> void:
	await Dialogue.talk([
		["DON GERMAN", "—La puerta del garaje. Usted empuja y yo opino. Es lo que hago desde que me pensioné: opinar."],
		["", "(Media hora empujando una puerta de lata. Cede de golpe, y él entra detrás, de jeta.)"],
	])
	_yo("sacudirse")
	await Dialogue.talk([
		["", "(Adentro hay un carro que no prende desde el 98, cajas con letra de mujer y un rincón seco, barrido, vacío.)"],
		["DON GERMAN", "—Ahí cabe de todo. Una moto, un mercado, una bicicleta. Lo que uno no quiera que le caiga el rocío."],
		["", "(Mira el rincón. Mira a Don Germán.)"],
		["DON GERMAN", "—No me mire así. Yo no pregunto nada. Pero tengo garaje. ... Y ahora tengo puerta."],
	])
	GameState.add_item("pan")
	GameState.change_mood(8.0)


static func _samuel2() -> void:
	var g := GameState
	await Dialogue.talk([
		["SAMUEL", "—Le traje la cobija. No, no me estoy muriendo. Conseguí otra más fea y a esta le da pena con la nueva."],
		["", "(Una cobija de tigre, con un hueco que tiene la forma de Venezuela.)"],
	])
	_yo("recoger")
	if g.has_cambuche() and not g.cambuche["cobija"]:
		g.cambuche["cobija"] = true
		await Dialogue.talk([["", "(Va derecho al cambuche. Con cobija se tose menos. Un poquito menos.)"]])
	elif g.has_cambuche():
		await Dialogue.talk([["SAMUEL", "—¿Ya tiene? Entonces es para el perro." if g.lukas_alive()
			else "—¿Ya tiene? Entonces se la pone en las piernas. Las piernas también son gente."]])
	else:
		await Dialogue.talk([["SAMUEL", "—Si no tiene dónde ponerla, se la pone encima. Así empecé yo. Once años y todavía funciona."]])
	g.change_mood(6.0)


static func _rosa2() -> void:
	await Dialogue.talk([["DOÑA ROSA", "—Venga le enseño a envolver. Un regalo sin papel es una compra."]])
	_yo("recoger")
	await Dialogue.talk([
		["", "(Le enseña con un periódico: tres dobleces, uno que nadie ve, y cinta. Él lo hace once veces.)"],
		["", "(La once queda bien. Doña Rosa le regala el papel bueno: de globos, un poco arrugado. \"Lo planché yo\".)"],
		["DOÑA ROSA", "—Y el moño. La gente mira el moño. Lo de adentro lo miran después, cuando ya dieron las gracias."],
	])
	GameState.flags["papel_regalo"] = true
	GameState.change_mood(6.0)


static func _marta2() -> void:
	var g := GameState
	await Dialogue.talk([["MARTA", "—Siéntese. No, no es caridad. Es un tinto que se me iba a enfriar. Y un pan que se me iba a... también."]])
	_yo("beber")
	await Dialogue.talk([
		["", "(Se toma el tinto de pie: sentado le da tos. Tose igual.)"],
		["MARTA", "—Me dijeron que anda juntando para una bicicleta. ... No me diga nada. Ya sé que no me va a decir nada."],
		["MARTA", "—Tome. Cinco mil. No es para usted, idiota: es para la bicicleta. Para el timbre, o lo que sea que tengan ahora las bicicletas."],
	])
	_yo("plata")
	if g.has_cambuche() and not g.flags.get("bici_comprada", false):
		g.cambuche["alcancia"] = int(g.cambuche["alcancia"]) + 5000
	else:
		g.add_money(5000)
	g.add_item("pan")
	g.change_mood(6.0)


static func _efrain2() -> void:
	if GameState.flags.get("bici_comprada", false):
		await Dialogue.talk([["DON EFRAIN", "—¿Y la bicicleta? ¿Bien tapada? A ver esas manos."]])
		_yo("asentir")
		await Dialogue.talk([
			["", "(Le muestra las manos. Grasa de cadena hasta las muñecas.)"],
			["DON EFRAIN", "—Bien. La está cuidando. Péguele una aceitadita al timbre, que el timbre es lo primero que se oxida y lo primero que uno quiere oír."],
		])
	else:
		await Dialogue.talk([
			["DON EFRAIN", "—La verde agua sigue aquí. Ya me la quisieron comprar tres. A los tres les dije que estaba vendida. Por terco."],
			["DON EFRAIN", "—No me afane. Yo se la guardo hasta el veintinueve. El treinta ya es otra bicicleta: es la de cualquiera."],
		])
		_yo("recoger")
		await Dialogue.talk([["", "(Debajo de un plástico, la bicicleta. Le pasa la mano al sillín sin quitarle el plástico.)"]])
	GameState.change_mood(6.0)


# ---------------------------------------------------------------- Zaida: cinco encuentros. Ayuda que se cobra.
## zaida_deuda: cuántas veces le aceptó. Con dos o más, el final se lo cobra; con menos, ella paga.

static func _zaida(n: int) -> void:
	var f := GameState.flags
	var debt := int(f.get("zaida_deuda", 0))
	var i := 0
	match n:
		1:
			i = await Dialogue.talk([
				["ZAIDA", "—Mirá quién apareció. Estás flaquito. Te queda bien. Pareces poeta."],
				["ZAIDA", "—Tomá, veinte mil. No es un préstamo. Bueno, sí es un préstamo, pero no te lo voy a cobrar. Bueno, ya veremos."],
			], ["Aceptar los $20.000", "No, gracias"])
			if i == 0:
				f["zaida_deuda"] = debt + 1
				GameState.add_money(20000)
				await Dialogue.talk([["ZAIDA", "—Así me gusta. Yo no anoto nada. (Saca una libreta. Anota.)"]])
			else:
				await Dialogue.talk([["ZAIDA", "—Orgulloso. Me encanta. Te dura poco, pero me encanta."]])
		2:
			i = await Dialogue.talk([
				["ZAIDA", "—Supe lo de la niña. Lorena y yo vamos al mismo salón de uñas. ¿Querés que le hable? Yo soy muy convincente."],
			], ["Asentir", "Negar con la cabeza"])
			if i == 0:
				f["zaida_deuda"] = debt + 1
				f["zaida_chisme"] = true
				f["lilato_avisos"] = int(f.get("lilato_avisos", 0)) + 1
				await Dialogue.talk([["ZAIDA", "—Dejámelo a mí. Le voy a decir cosas buenas. Y dónde dormís, para que vea que estás bien."],
					["", "(Niega con la cabeza. Fuerte.)"], ["ZAIDA", "—¿Que no le diga? Ay, ¿qué va a pasar? (Ya pasó.)"]])
			else:
				await Dialogue.talk([["ZAIDA", "—Como quieras. Yo solo quería ayudar. Es lo que siempre digo. Y siempre es verdad, a mi manera."]])
		3:
			i = await Dialogue.talk([
				["ZAIDA", "—Un favorcito. Este paquete, a un amigo en la avenida. Treinta mil. Ni lo abrás, que es una sorpresa."],
				["", "(Pesa como harina. Envuelto en un periódico viejo.)"],
			], ["Llevarlo ($30.000)", "No"])
			if i == 0:
				f["zaida_deuda"] = debt + 1
				f["violencia"] = true
				GameState.add_money(30000)
				GameState.add_locura(1)
				await Dialogue.talk([["", "(Lo entrega. El amigo no sonríe.)"],
					["", "(Anillo de oro en el meñique. Un Nissan negro encendido, sin nadie adentro. Lo del paquete no era harina.)"],
					["AMIGO DE ZAIDA", "—Zaida sí sabe escoger. Tome. Contados. Y no vuelva. Y si vuelve, no me conoce."]])
			else:
				await Dialogue.talk([["ZAIDA", "—Ya hablaremos. Yo siempre hablo. Es lo que mejor me sale. Lo segundo es esperar."]])
		4:
			i = await Dialogue.talk([
				["ZAIDA", "—Te tengo la solución: yo voy a la Defensoría como testigo. De buena conducta. Yo te conozco de antes."],
			], ["Asentir", "Negar con la cabeza"])
			if i == 0 and debt >= 2:
				f["lilato_avisos"] = int(f.get("lilato_avisos", 0)) + 1
				await Dialogue.talk([["DEFENSORA", "—(Al otro día.) Vino una señora a hablar de usted. Una hora. No sé si a favor o en contra. Creo que ella tampoco."],
					["ZAIDA", "—Salió perfecto. Le conté todo. Bueno, mi versión. La mía es más bonita."]])
			elif i == 0:
				await Dialogue.talk([["ZAIDA", "—Bueno, no voy. Pero te digo algo, ya que me dijiste que no tantas veces."],
					["ZAIDA", "—Esa vez, la de la policía, Lorena me pidió que dijera que vos tenías un arma. Yo no lo dije. ... Bueno, lo dije una vez."],
					["", "(Aprieta los puños. No se mueve.)"]])
				GameState.add_locura(1)
			else:
				await Dialogue.talk([["ZAIDA", "—Vos sabrás. Yo te ofrezco. Si no lo querés, no es mi culpa. Nunca es mi culpa. Es mi lema."]])
		5:
			if debt >= 2:
				var owed := 40000
				i = await Dialogue.talk([
					["ZAIDA", "—Bueno. Lo que te presté, lo que te ayudé, lo que te esperé. Cuarenta mil. Con intereses de cariño."],
					["", "(Saca la libreta. Hay muchas páginas con su nombre.)"],
				], ["Pagarle", "Darse la vuelta"])
				if i == 0:
					var from_pocket := mini(GameState.money, owed)
					GameState.add_money(-from_pocket)
					var rest := owed - from_pocket
					if rest > 0 and GameState.has_cambuche():
						GameState.cambuche["alcancia"] = maxi(0, int(GameState.cambuche["alcancia"]) - rest)
					await Dialogue.talk([["", "(Le paga. Lo que faltó, de la alcancía. De la bicicleta de Victoria.)"
						if rest > 0 else "(Le paga. Zaida cuenta los billetes dos veces.)"],
						["ZAIDA", "—Ves que no era tan difícil. Siempre te encuentro. Hoy es la última vez que te busco."]])
				else:
					f["intruso_dia"] = GameState.day
					f["lilato_avisos"] = int(f.get("lilato_avisos", 0)) + 1
					await Dialogue.talk([["ZAIDA", "—Ah, bueno. Yo sé dónde dormís. Y conozco gente que también quiere saber."],
						["", "(Lo dice sonriendo.)"]])
			else:
				await Dialogue.talk([
					["ZAIDA", "—Vos sí aprendiste. A decirme que no. Nadie me dice que no. Me cayó... raro. Bien raro."],
					["ZAIDA", "—Tomá. Para la niña. No es para vos. No me mirés así, que me arrepiento."],
					["", "(Veinticinco mil. Zaida se va sin despedirse.)"],
				])
				if GameState.has_cambuche():
					GameState.cambuche["alcancia"] = int(GameState.cambuche["alcancia"]) + 25000
				else:
					GameState.add_money(25000)
				GameState.change_mood(8.0)
