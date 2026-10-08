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
	f["hoy_tarea"] = id
	f["hoy_ok"] = false
	f["hoy_base"] = {"alcancia": int(g.cambuche["alcancia"]) if g.has_cambuche() else 0, "trucos": _tricks()}
	g.quests.erase("hoy_" + id)
	g.start_quest("hoy_" + id)
	return [TASKS[id][2]]


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
			lines.append("Zaida lo esperó ayer.")
		elif TASKS[id][0] != "":
			g.change_mood(-5.0)
			lines.append("Ayer le falló a alguien.")
		else:
			lines.append("La meta de ayer quedó sin cumplir.")
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
		"truco":
			ok = _tricks() > int(base.get("trucos", 0))
		"trabajar":
			ok = int(f.get("trabajo_ultimo", -1)) == g.day
		"bano":
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
		"vet1", "vet2", "vet3":
			var h := TimeManager.hour()
			if h < 8 or h >= 18:
				return false
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
			["ÉL", "Vacunas al día. Las mías no. Pero las de él sí. Prioridades."],
			])
			g.change_mood(8.0)
		"vet2":
			await Dialogue.talk([
				["DRA. PILAR", "—Escúchelo usted mismo. (Le pone el estetoscopio.) ¿Oye ese ruido? Es el corazón haciendo fuerza."],
				["", "(Escucha. Aprieta la mandíbula.)"],
			["ÉL", "Suena como una lavadora vieja. Una lavadora que no quiere parar. Buen chico."],
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
		["DOÑA ROSA", "—¡Por fin! Cuídeme el puesto dos horas, que tengo cita en el Seguro. No regale nada. Bueno, a los niños sí. A los policías no."],
		["", "(Dos horas vendiendo empanadas. Sin decir el precio: señalando el letrero.)"],
		["DOÑA ROSA", "—¿Vendió? ¿Cuántas? ... Hágame la seña. ... ¿Veinte? ¿Veinte? Yo vendo quince gritando desde las seis."],
		["ÉL", "Técnica de ventas: mirar a la gente fijo hasta que compra para que uno deje de mirarla. En la oficina lo llamaban \"cierre consultivo\"."],
		["DOÑA ROSA", "—Tome, para usted y para el perro. Y no vuelva a vender así, que me deja mal parada."],
	])
	TimeManager.skip(2.0)
	GameState.add_money(6000)
	GameState.add_item("empanada", 2)


static func _samuel() -> bool:
	if GameState.count("aguapanela") == 0:
		await Dialogue.talk([["SAMUEL", "—Estoy bien. (Tirita.) Si me trae algo calientico, no se lo desprecio. Doña Fabiola regala en el Parque."]])
		return false
	GameState.remove_item("aguapanela")
	await Dialogue.talk([
		["", "(Le da la aguapanela. Samuel la agarra con las dos manos, como si fuera un pájaro.)"],
		["SAMUEL", "—Once años en la calle. Nunca nadie me había traído nada caliente que no fuera una patrulla."],
		["SAMUEL", "—Si me muero, le dejo mi cobija. Si no, también. Es muy fea para mí."],
		["ÉL", "La cobija es de un equipo de fútbol que descendió en el 2008. No se la voy a recibir. Tengo principios. Pocos, pero ese sí."],
	])
	GameState.change_mood(8.0)
	return true


static func _wilson() -> void:
	await Dialogue.talk([
		["WILSON", "—Cuarenta kilos de latas. Usted carga y yo hablo. Es una división del trabajo muy moderna. La vi en un video."],
		["", "(Dos horas empujando un carrito con una rueda que va para otro lado.)"],
		["WILSON", "—Mitad y mitad. Bueno, sesenta y cuarenta. Yo puse el carrito. Y el carácter. Y la rueda, que es lo más difícil de poner."],
		["ÉL", "La rueda iba hacia la izquierda. Toda la ruta. Llevo dos horas corrigiendo un carrito de supermercado. Ahora entiendo a Wilson."],
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
		["ÉL", "Feliz cumpleaños, Germán. Se lo dije por dentro. Por dentro me salió muy bonito. Tuvo hasta música."],
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
		["ÉL", "Doce mil cuatrocientos pesos en monedas. Tres botones. Un tiquete de bus usado. Una nota que dice \"ánimo\". El arte no paga, pero opina."],
	])
	TimeManager.skip(1.0)
	GameState.add_money(5000)
	GameState.change_mood(10.0)


static func _marta() -> void:
	var i := await Dialogue.talk([
		["", "(La tienda de Marta, con la reja a medio bajar. Adentro, un tipo con una libreta.)"],
		["COBRADOR", "—La señora debe el veinte por ciento diario. Hoy, o le quitamos la nevera."],
		["ÉL", "Libreta Norma de cien hojas. Lapicero de hotel. Mocasines sin medias. Gota a gota de nivel medio: el que todavía cobra él mismo."],
		["MARTA", "(bajito) —No se meta. Por favor."],
	], ["Hacerme el loco", "Pagarle $10.000 de lo de ella"])
	if i == 1 and GameState.money >= 10000:
		GameState.add_money(-10000)
		await Dialogue.talk([["COBRADOR", "—Abono. Volvemos el lunes."], ["MARTA", "—Usted es un idiota. ... Gracias, idiota. Pero idiota."],
			["ÉL", "Me lo dijo dos veces. La segunda con cariño. Distingo las dos. Llevo años de práctica."]])
	else:
		await Dialogue.talk([
			["", "(Se le acerca mucho. Demasiado. No dice nada. Lo mira sin parpadear.)"],
			["COBRADOR", "—¿Qué? ¿Qué me mira? ... Diga algo. ... DIGA ALGO."],
			["", "(Nada. Ni un parpadeo.)"],
			["COBRADOR", "—... Volvemos otro día. (Se va. Rápido.)"],
			["MARTA", "—Eso fue muy raro. Y muy útil. ¿Usted está bien?"],
			["", "(...)"], ["MARTA", "—No me contestés. Mejor no me contestés."],
			["ÉL", "Estoy bien. La mano izquierda me tiembla. Iba a algún lado. Ya volvió."],
		])
		GameState.add_locura(1)
	GameState.change_mood(6.0)


static func _efrain() -> void:
	var dead := not GameState.lukas_alive()
	await Dialogue.talk([
		["DON EFRAIN", "—Tome. Lo talle yo. Con una navaja y mucho tiempo, que es lo único que me sobra."],
		["", "(Un perrito de madera. Orejas largas. Cola parada. Una manchita quemada en el lomo.)"],
		["", "(Es Lukas. Lo aprieta en la mano. Le tiembla la mandíbula.)" if dead
			else "(Es Lukas. Lukas lo huele, lo mira y se aburre.)"],
		["DON EFRAIN", "—Gloria le manda saludes. Bueno, no. Pero si hablara, le mandaría."],
		["ÉL", "Gloria manda saludes. Las oí. No se lo digo a Efraín. Él ya tiene suficiente con el reloj."],
	])
	GameState.change_mood(10.0 if dead else 6.0)


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
				["ZAIDA", "—Supe lo de la niña. Lilato y yo vamos al mismo salón de uñas. ¿Querés que le hable? Yo soy muy convincente."],
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
					["ÉL", "Anillo de oro en el meñique. Tatuaje de una fecha. Un Nissan negro con vidrios polarizados encendido sin nadie adentro. Esto no es harina."],
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
					["ZAIDA", "—Esa vez, la de la policía, Lilato me pidió que dijera que vos tenías un arma. Yo no lo dije. ... Bueno, lo dije una vez."],
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
