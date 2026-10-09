extends Node
## Lo que dice cada persona (una función por npc_id). Las líneas sin nombre son del protagonista.
## Precios en pesos colombianos.

const PRICE_BREAD := 1500
const PRICE_TINTO := 1000
const PRICE_SANDWICH := 6000
const PAY_JOB := 20000
const PAY_ERRAND := 8000
const PAY_CAN := 300
const PAY_BOTTLE := 200
const PRICE_BATH := 1000
const PRICE_PENSION := 15000
## Lo que vende cada uno: [id, precio, línea al comprar].
const SHOP_EFRAIN := [
	["reloj_sin_agujas", 1500, "—Era de un señor que tenía todo el tiempo del mundo. Literal. Se murió. Ahora el tiempo es suyo."],
	["estampita", 500, "—San Judas. Causas perdidas. No lo digo por usted. Bueno, un poquito."],
	["muneca", 800, "—Gloria. No la deje mirando a la pared, que se ofende. Y cuando se ofende, mira."],
	["dentadura", 300, "—Completa. Bueno, le falta un colmillo. Como a todos nosotros."],
	["casete", 1000, "—Boleros. Lado B. El lado A es para la gente feliz, y esa gente no compra casetes."],
	["celular", 9000, "—Celular de flecha, con chip y saldo. Indestructible: se cae de un cuarto piso y el que se rompe es el piso. Ah, y una señora preguntó por usted. Le di el número. Me pagó. Yo vendo historias, mijo."],
]
const SHOP_GERMAN := [
	["pan", 1500, "—Mil quinientos. El de hoy. El de ayer se lo regalo, pero no le diga a nadie."],
	["arroz", 2000, "—Una libra. Rinde. Mi señora sacaba cuatro almuerzos de una libra. Yo saco dos y medio."],
	["vela", 500, "—Cuidado con el fuego, mijo. El cartón no avisa."],
	["concentrado", 2000, "—Para el perrito. Dígale que es de parte de Germán. Que me debe un ladrido."],
]
const SHOP_MARTA := [
	["tinto", 1000, "—Quema. Te lo digo porque todos dicen \"no quema\" y después me piden servilleta."],
	["sandwich", 6000, "—Jamón, queso, y mi paciencia. Es el último. No te acostumbres."],
]
const SHOP_ROSA := [
	["empanada", 1500, "—Con ají, mijito. El ají es gratis. La empanada no. El ají no es empanada."],
	["arepa", 3000, "—Con harto queso. Usted está muy flaco. Flaco no se consigue novia. Ni trabajo. Ni nada."],
	["aguapanela", 1000, "—Calientica. Para el frío. Para la tristeza no sirve, pero la tristeza tampoco paga."],
]
const SHOP_WILSON := [
	["cuerda", 1000, "—De un trasteo. La señora se fue con todo menos la cuerda. Aguanta lo que le echen."],
	["plastico", 2500, "—Lona de una valla de un concejal. Ya no es concejal. La lona sí sigue siendo lona."],
	["candado", 4000, "—Dos llaves. Pierda una, le queda la otra. Pierda las dos y el problema ya no es el candado."],
	["cobija", 5000, "—Lavadita. Bueno. Lavadita en el sentido de que llovió."],
	["estiba", 2000, "—De la bodega de atrás. Nadie la extraña. Aquí nadie extraña nada. Es una política."],
	["clavos", 1500, "—Oxidados, pero con experiencia. Como uno."],
	["zinc", 6000, "—De un techo que ya no lo necesitaba. No pregunte cuál. Esa casa ya tampoco pregunta."],
	["radio", 8000, "—Funciona. Coge una emisora y media. La media es de boleros, la otra es de un pastor que grita."],
]
## Puerta donde se entrega el mandado de Marta (la casa de "—Andate").
const ERRAND_DOOR := "Puerta_house_c_40"
## Donde vivía la hija de Samuel (la casa del fondo, al este).
const LETTER_DOOR := "Puerta_house_e_936"

var _ask_german := 0
var _ask_wilson := 0


func run(id: String, npc: Node) -> void:
	if await DayTasks.talk(id):  # el encargo del día, si es con esta persona
		return
	if id == "zaida_dia":
		await Dialogue.talk([["ZAIDA", "—Ya nos vimos hoy. Mañana, quién sabe. Yo sí sé."]])
		return
	if id.begins_with("cuenco"):
		await _cuenco(id)
		return
	match id:
		"german":
			await _german(npc)
		"marta":
			await _marta()
		"wilson":
			await _wilson()
		"samuel":
			await _samuel()
		"stranger":
			await _stranger()
		"rosa":
			await _rosa()
		"bano":
			await _bano()
		"pension":
			await _pension()
		"moto_cafe":
			await _moto_cafe()
		"chaqueta":
			await _chaqueta()
		"fb_moto":
			await _fb_moto()
		"bus_barrio":
			await _bus_from("barrio")
		"bus_centro":
			await _bus_from("centro")
		"bus_parque":
			await _bus_from("parque")
		"iglesia":
			await _iglesia()
		"padre":
			await _padre()
		"fabiola":
			await _fabiola()
		"aurelio":
			await _aurelio()
		"leonor":
			await _leonor()
		"efrain":
			await _efrain()
		"mono":
			await _mono()
		"viejos", "viejo2":
			await _viejos()
		"banca":
			await _banca()
		"palomas":
			await _palomas()
		"yeison":
			await _yeison()
		"veterinaria":
			await _veterinaria()
		"tablero":
			await _tablero()
		"evento_redada":
			await _ev_redada()
		"evento_pelea":
			await _ev_pelea()
		"evento_ayuda":
			await _ev_ayuda()
		"colegio":
			await _colegio()
		"defensoria":
			await _defensoria()
		"victoria":
			await _victoria_npc()
		"lilato_madre":
			await _lilato_ve()
		"supervisora":
			await Dialogue.talk([["SUPERVISORA", "—Hasta las doce. Yo no estoy aquí. Bueno, sí estoy. Pero hagan de cuenta. Yo hago de cuenta todo el día. Me pagan por eso."]])
		"celador":
			await _celador()
		"registraduria":
			await _registraduria()
		"fotos":
			await _fotos()
		"zaida":
			await _zaida(npc)
		"fuente":
			await _fuente()
		"telefono":
			await _telefono()
		"mauricio":
			await _mauricio_plaza(npc)
		"pedir":
			await _pedir()
		"vitrina_tv":
			await _vitrina_tv()
		"pescar":
			await _pescar()
		"atardecer":
			await _atardecer()
		"pelaos":
			await _pelaos()
		"banca_parquecito":
			await _banca_parquecito()
		"columpio":
			await _columpio()
		"perro_barrio":
			await _perro_barrio()


# ---------------------------------------------------------------- Don Germán (tienda-panadería)

func _german(npc: Node) -> void:
	await _friend("german")
	var f := GameState.flags
	if not f.get("met_german", false):
		f["met_german"] = true
		await Dialogue.talk([
			["DON GERMAN", "—Buenos días, mijo. ¿Cómo amaneció?"],
			["ÉL", "Debajo de un puente, con un beagle encima. Cinco estrellas. Volvería."],
			["", "(...)"],
			["DON GERMAN", "—Eso. Ni bien ni mal. Como el pan de ayer."],
			["DON GERMAN", "—Mi señora decía que el pan de ayer es el más honesto. Ya no se hace el bonito. Ya no tiene que impresionar a nadie."],
			["ÉL", "Delantal con más harina que delantal. Uñas cortadas al ras. Me mira la cara, no los zapatos. Primera persona en tres días que hace eso."],
			["DON GERMAN", "—Usted no habla, ¿no? Bueno. Mi señora hablaba por los dos. Desde que se fue, hablo yo por los dos."],
			["DON GERMAN", "—Con usted, por los tres. Tranquilo, tengo práctica."],
		])
	if GameState.is_dirty() and not f.get("german_bath_hint", false):
		f["german_bath_hint"] = true
		await Dialogue.talk([["DON GERMAN", "—Mijo, con todo el cariño del mundo: en la plaza hay un baño público. Igual siga, que aquí se atiende a todo el mundo."],
			["DON GERMAN", "—Pero no se me acerque al pan. El pan coge olor."],
			["ÉL", "Tiene razón. El pan es lo único en este barrio que todavía tiene estándares."]])
	await _german_story()
	await _german_favor()
	if f.get("german_mood_day", -1) != GameState.day:  # hablar con Germán hace bien
		f["german_mood_day"] = GameState.day
		GameState.change_mood(3.0)
	while true:
		var opts := ["Señalar los bultos", "Comprar", "Quedarse ahí"]
		if _obra_open():
			opts.push_front("La obra (turno)")
		if GameState.bond("german") >= 1 and f.get("pan_dia", -1) != GameState.day:
			opts.push_front("Pan del día")
		if _needs_address():
			opts.append("La dirección")
		opts.append("Salir")
		var i := await Dialogue.talk([["DON GERMAN", "—¿Qué necesita?"]], opts)
		match opts[i]:
			"Señalar los bultos":
				await _german_job(npc)
				return
			"La obra (turno)":
				await Dialogue.talk([["DON GERMAN", "—Váyase ya, mijo, que mi cuñado no espera. Y coma algo antes: el ladrillo no perdona. Mi cuñado tampoco, pero él por lo menos es familia."]])
				SceneRouter.go("res://scenes/world/Obra.tscn")
				return
			"Comprar":
				if GameState.money < PRICE_BREAD:
					await Dialogue.talk([["DON GERMAN", "—No le alcanza, mijo. Tranquilo. A mí tampoco me alcanza y aquí estoy, vendiendo."],
						["DON GERMAN", "—Tome. Es de ayer. El de ayer es el honesto, ya le dije. No me debe nada."]])
					if not f.get("german_gift", false):
						f["german_gift"] = true
						GameState.add_item("pan")
					else:
						await Dialogue.talk([["DON GERMAN", "—Hoy ya no me queda del de ayer. Se lo llevó una señora para las palomas. Las palomas comen mejor que usted. Ayúdeme con los bultos y le pago."]])
				else:
					await _shop("DON GERMAN", SHOP_GERMAN)
			"La dirección":
				await _german_address()
			"Pan del día":
				f["pan_dia"] = GameState.day
				GameState.add_item("pan")
				await Dialogue.talk([["DON GERMAN", "—El suyo, mijo. Recién salido. Con el anillo puesto. Ya sabe."]])
			"Quedarse ahí":
				var lines := [
					[["DON GERMAN", "—¿Sabe por qué el camión de Harinas El Sol llega a las siete y cuarto y no a las siete?"], ["", "(...)"],
						["DON GERMAN", "—Porque el chofer para a desayunar en la panadería de la esquina. La de la competencia. Treinta años y nunca le he dicho nada."],
						["DON GERMAN", "—Uno no le reclama a un hombre dónde desayuna. Eso es sagrado. Como la misa. Como el clásico."],
						["ÉL", "Siete y cuarto. Lo anoto. Uno nunca sabe cuándo va a necesitar saber a qué hora pasa un camión que no frena."]],
					[["DON GERMAN", "—Antes este barrio era distinto. La gente se saludaba. Se prestaba la escalera."],
						["DON GERMAN", "—Ahora se presta plata. Al veinte por ciento. Diario."],
						["ÉL", "El gota a gota. Lo dice como quien dice que va a llover. Aquí el clima tiene moto y cobra los lunes."]],
					[["DON GERMAN", "—Usted no es de por acá. Se le nota."], ["", "(...)"],
						["DON GERMAN", "—Camina como los de oficina. Mira el reloj a cada rato. Y no tiene reloj."],
						["ÉL", "Lo vendí en marzo. Todavía me miro la muñeca a las doce. El cuerpo es el último en enterarse."]],
				]
				await Dialogue.talk(lines[_ask_german % lines.size()])
				_ask_german += 1
			_:
				return


func _german_job(npc: Node) -> void:
	var f := GameState.flags
	if f.get("job_german_done", false):
		await Dialogue.talk([["DON GERMAN", "—Por hoy ya está, mijo. Mañana vienen más bultos. Siempre vienen más bultos. Es lo único seguro en esta vida, además de la muerte y el IVA."]])
		return
	if f.get("job_german_active", false):
		await Dialogue.talk([["DON GERMAN", "—Atrás, mijo, al lado de las cajas. Al lado del horno. Doble las rodillas."]])
		return
	await Dialogue.talk([
		["", "(Señala los bultos. Se señala a sí mismo.)"],
		["DON GERMAN", "—¿Qué? ¿Los bultos? ¿Usted?"],
		["DON GERMAN", "—Ah, que me ayuda. Mijo, usted es el primero que se ofrece sin decir nada. Los demás dicen mucho y no se ofrecen."],
		["ÉL", "Y aquí es donde el juego me enseña a cargar cosas. Aguanten. Después hay disparos."],
		["DON GERMAN", "—Están atrás, al lado de las cajas. Cuatro. Me los deja al lado del horno. Y doble las rodillas, que la espalda no se repone. Pregúntele a la mía."],
	])
	f["job_german_active"] = true
	GameState.start_quest("bultos_german")
	var job := Node.new()
	job.set_script(load("res://scripts/world/CarryJob.gd"))
	job.finished.connect(_german_paid)
	npc.get_parent().add_child(job)


func _german_paid() -> void:
	var f := GameState.flags
	f["job_german_active"] = false
	f["job_german_done"] = true
	_worked()
	TimeManager.skip(1.0)
	GameState.complete_quest("bultos_german")
	GameState.add_money(PAY_JOB)
	GameState.add_item("pan")
	await Dialogue.talk([
		["DON GERMAN", "—Listo, mijo. Usted trabaja como si alguien lo estuviera mirando."],
		["ÉL", "Alguien siempre está mirando. Ese es el problema."],
		["DON GERMAN", "—Veinte mil. Y este pan, que no me lo voy a vender. Ni se le ocurra devolvérmelo."],
	])


# ---------------------------------------------------------------- Marta (café)

func _marta() -> void:
	await _friend("marta")
	var f := GameState.flags
	if not f.get("met_marta", false):
		f["met_marta"] = true
		await Dialogue.talk([
			["MARTA", "—¿Ya desayunaste?"],
			["", "(...)"],
			["MARTA", "—¿Hola? Te pregunté si ya desayunaste. Es una pregunta de sí o no. Hasta mi hijo la contesta, y tiene nueve."],
			["ÉL", "Delantal negro con una mancha de café en forma de Italia. Ojeras de dos turnos. Le vibra el celular cada minuto y no lo mira."],
			["", "(...)"],
			["MARTA", "—Bueno. Callado y con hambre. El cliente ideal: no se queja, no pide la clave del wifi. Sentate."],
		])
	if f.get("errand_delivered", false) and not f.get("errand_paid", false):
		f["errand_paid"] = true
		GameState.complete_quest("mandado_marta")
		GameState.add_money(PAY_ERRAND)
		await Dialogue.talk([["MARTA", "—¿Te abrieron? ¿Viste a alguien?"], ["", "(...)"],
			["MARTA", "—Una mano. Siempre es una mano. Tres años llevando pedidos a esa casa y lo único que he visto es una mano."],
			["MARTA", "—Tomá: ocho mil. Y no me contés más de la mano, que esta noche cierro yo sola."]])
	await _marta_favor()
	if GameState.is_dirty() and GameState.bond("marta") >= 1 and f.get("marta_bano_day", -1) != GameState.day:
		f["marta_bano_day"] = GameState.day
		GameState.set_hygiene(100.0)
		GameState.flags["bathed"] = GameState.day
		await Dialogue.talk([["MARTA", "—Uy, no. Pasá al baño de atrás. Ya. Antes de que llegue la del banco, que ella sí se queja."],
			["", "(Agua tibia. Jabón de verdad. Jabón con olor a algo que no es jabón.)"],
			["ÉL", "Lavanda. Hace un año que no olía a lavanda. En la oficina olía a lavanda. No me acuerdo de nada más de la oficina. Mentira."],
			["MARTA", "—Y no me des las gracias. Bueno, igual no ibas a dar nada. Por eso me caés bien."]])
	if GameState.is_dirty():
		await Dialogue.talk([["MARTA", "—Perdoná, pero así no. Tengo dos clientes y los dos tienen nariz."],
			["MARTA", "—En la plaza hay un baño público. Mil pesos. Volvé limpio y te sirvo lo que quieras. Bueno, lo que alcances."],
			["", "(Se huele la manga.)"],
			["MARTA", "—Sí. Eso. Exactamente eso. Qué bueno que estemos de acuerdo."]])
		return
	while true:
		var opts := ["Comprar", "Mirar los pedidos"]
		if GameState.has_skill("labia") and f.get("marta_fiado_day", -1) != GameState.day:
			opts.append("[MIRADA] Mirar el tinto")
		opts.append("Salir")
		var i := await Dialogue.talk([["MARTA", "—¿Qué te sirvo? Rápido, que se me quema la arepa de la señora del banco."]], opts)
		match opts[i]:
			"[MIRADA] Mirar el tinto":
				f["marta_fiado_day"] = GameState.day
				GameState.add_item("tinto")
				await Dialogue.talk([["", "(Mira el tinto. Mira a Marta. Mira el tinto.)"],
					["MARTA", "—No."], ["", "(Mira el tinto.)"], ["MARTA", "—Que no."], ["", "(Mira a Marta. Muy despacio.)"],
					["MARTA", "—Ay, ya, tomá. Sos un descarado y ni siquiera tenés que abrir la boca. Eso es talento. Eso en mi casa se llama \"tu papá\"."]])
			"Comprar":
				await _shop("MARTA", SHOP_MARTA)
			"Mirar los pedidos":
				if f.get("errand_given", false):
					var msg := "—Ya hiciste bastante hoy. Andá, descansá. O lo que sea que hacés vos." if f.get("errand_paid", false) else "—La de la esquina, la de tejas. Lo dejás en la puerta. No toqués dos veces. Nunca toqués dos veces."
					await Dialogue.talk([["MARTA", msg]])
				elif not GameState.has_space_for("pedido"):
					await Dialogue.talk([["MARTA", "—Te iba a pedir un favor, pero esa mochila está más llena que mi agenda. Vaciala y volvé."]])
				else:
					f["errand_given"] = true
					GameState.add_item("pedido")
					GameState.start_quest("mandado_marta")
					await Dialogue.talk([
						["MARTA", "—¿Pedidos? Sí. Uno. El mismo de todas las semanas."],
						["MARTA", "—Un caldo de costilla, dos panes, una gaseosa de naranja. Pagado por la app. Para la casa de tejas de la esquina."],
						["MARTA", "—Nunca abren. Pero alguien se toma la gaseosa. La de naranja. Nadie toma de naranja."],
						["ÉL", "Caldo, dos panes, naranja. Mismo pedido todas las semanas. O es una persona muy ordenada o es alguien que no sabe que ya no tiene que pedir."],
						["MARTA", "—Lo dejás en la puerta y volvés. Te pago cuando vuelvas. No antes. No soy tu mamá."],
					])
			_:
				return


## Lista de cosas para comprar (con precio); vuelve cuando elige "Nada".
func _shop(who: String, items: Array) -> void:
	# Lo que es uno solo (el celular), si ya lo tiene, no se vende otra vez.
	items = items.filter(func(it): return not (Items.info(it[0]).get("fixed", false) and GameState.count(it[0]) > 0))
	while true:
		var opts := []
		for it in items:
			opts.append("%s $%d" % [Items.info(it[0])["name"], _price(it[1])])
		opts.append("Nada")
		var i := await Dialogue.talk([[who, "—¿Qué va a ser?"]], opts)
		if i >= items.size():
			return
		await _buy(items[i][0], items[i][1], who, items[i][2])


## El precio de hoy (con la inflación y la labia).
func _price(base: int) -> int:
	var p := int(round(base * (1.0 + 0.25 * GameState.diff("precios")) / 100.0)) * 100
	if GameState.has_skill("labia"):
		p = int(round(p * 0.9 / 100.0)) * 100
	return p


func _buy(id: String, price: int, who: String, line: String) -> void:
	price = _price(price)  # la inflación también llega a la calle (y la labia la regatea)
	if GameState.money < price:
		await Dialogue.talk([[who, "—No le alcanza."], ["ÉL", "Eso ya lo sabía. Lo que no sabía es que se notaba desde afuera."]])
	elif not GameState.has_space_for(id):
		await Dialogue.talk([[who, "—¿Y dónde lo va a meter? Esa mochila ya está a reventar."]])
	else:
		GameState.add_money(-price)
		GameState.add_item(id)
		await Dialogue.talk([[who, line]])


## Las puertas con algo que entregar. Devuelve true si se encargó (Door.gd no hace lo de siempre).
func door_hook(door_name: String) -> bool:
	if door_name == ERRAND_DOOR and GameState.count("pedido") > 0:
		deliver_errand()
		return true
	if door_name == LETTER_DOOR and GameState.count("carta_samuel") > 0 and GameState.is_active("f_carta"):
		_deliver_letter()
		return true
	return false


## La puerta del mandado: la llama Door.gd cuando el jugador la toca con el pedido.
func deliver_errand() -> void:
	GameState.remove_item("pedido")
	GameState.flags["errand_delivered"] = true
	await Dialogue.talk([
		["", "(Toca. Una vez. Nadie abre.)"],
		["ÉL", "No toqués dos veces. Marta lo dijo como quien da una instrucción de seguridad de avión."],
		["", "(Deja la bolsa en el piso. Al rato, la puerta se abre una rendija y una mano la entra. Una mano muy blanca.)"],
		["", "(Nadie dice nada. Por una vez, no es él el que no dice nada.)"],
		["ÉL", "Ahora somos dos. Deberíamos fundar algo."],
	])


# ---------------------------------------------------------------- Wilson (reciclador)

func _wilson() -> void:
	await _friend("wilson")
	var f := GameState.flags
	if not f.get("met_wilson", false):
		f["met_wilson"] = true
		await Dialogue.talk([
			["WILSON", "—¿Qué más, parce? ¿Bien o qué?"], ["", "(...)"], ["WILSON", "—¿Bien o qué? ... Listo: qué. Respeto."],
			["ÉL", "Carro de supermercado sin el supermercado. Gorra verde. Guantes de jardinería y ni una mata. Este hombre tiene un sistema."],
			["WILSON", "—Wilson. Reciclador. Ingeniero ambiental sin cartón, como quien dice. Bueno, cartón sí tengo. Mucho."],
			["WILSON", "—Usted me trae latas y botellas y yo le pago. Usted no habla y yo no paro. La sociedad perfecta. Como Pimpinela."],
		])
	while true:
		var w_opts := ["Vender latas y botellas", "Comprar"]
		if _ruta_open():
			w_opts.append("Hacer la ruta (latas contra reloj)")
		w_opts.append_array(["Quedarse ahí", "Salir"])
		var i := await Dialogue.talk([["WILSON", "—¿Trae algo?"]], w_opts)
		# Las opciones viejas siguen con su número (0 vender, 1 comprar, 2 preguntar, 3 salir).
		if w_opts[i] == "Quedarse ahí":
			i = 2
		elif w_opts[i] == "Salir":
			i = 3
		elif w_opts[i] == "Hacer la ruta (latas contra reloj)":
			await _wilson_ruta()
			return
		match i:
			0:
				var cans := GameState.count("lata")
				var bottles := GameState.count("botella")
				if cans + bottles == 0:
					await Dialogue.talk([["WILSON", "—¿Nada? Mire en las canecas del colegio. Los profesores toman más que los alumnos."]])
				else:
					var pay := cans * PAY_CAN + bottles * PAY_BOTTLE
					pay = int(pay * (1.0 - 0.3 * GameState.diff("buscar")))
					if GameState.has_skill("rebusque"):
						pay = int(pay * 1.5)
					GameState.remove_item("lata", cans)
					GameState.remove_item("botella", bottles)
					GameState.add_money(pay)
					await Dialogue.talk([["WILSON", "—$%d. Cuéntelos. Yo no me ofendo. Me ofendo si no los cuenta." % pay]])
			1:
				await _shop("WILSON", SHOP_WILSON)
			2:
				var lines := [
					[["WILSON", "—¿Sabe cuál es la mejor lata? No la de cerveza. Todo el mundo cree que la de cerveza."],
						["WILSON", "—La de Pony Malta. Más gruesa. Pesa más. Trescientos pesos."],
						["WILSON", "—La de cerveza, doscientos ochenta. Usted dirá: Wilson, son veinte pesos. Y yo le digo: multiplique."],
						["ÉL", "Multipliqué. Sigue siendo poquito. No se lo dije. Wilson tiene fe en la multiplicación, y la fe aquí no se toca."]],
					[["WILSON", "—Esos de las motos de Rapidito pasan y pasan. Con la caja en la espalda."],
						["WILSON", "—Una vez le pregunté a uno qué llevaba. Me dijo: sushi."],
						["WILSON", "—Sushi, parce. En este barrio. ¿Quién pide sushi aquí?"],
						["ÉL", "Nadie. Por eso la caja pesa lo mismo de ida que de vuelta."]],
					[["WILSON", "—Lindo el perro. ¿Cómo se llama?"], ["", "(...)"],
						["WILSON", "—Bueno, le digo Perro. Hola, Perro."],
						["", "(Lukas le huele el carro entero. Se demora en las botellas de aguardiente.)"],
						["WILSON", "—Ese perro sabe. Ese perro ha vivido. Mándelo a buscar comida, que esa nariz vale más que mi carro."]],
				]
				await Dialogue.talk(lines[_ask_wilson % lines.size()])
				_ask_wilson += 1
			_:
				return


# ---------------------------------------------------------------- Samuel (vive en la calle)

func _samuel() -> void:
	var f := GameState.flags
	if GameState.is_active("donde_dormir"):
		await Dialogue.talk([
			["SAMUEL", "—¿Le quitaron el puesto? Pasa. La calle no es de nadie. Bueno, es de todos los que llegaron primero."],
			["SAMUEL", "—Hay un banco en la plaza: duro, pero con luz. El kiosco viejo: tiene techito y un señor que ronca los jueves."],
			["SAMUEL", "—O ármese bien el cambuche de debajo del puente, donde se despertó, si tiene cartones. Con tres alcanza. Con cuatro, ya es estrato dos."],
		])
		return
	if not f.get("met_samuel", false):
		f["met_samuel"] = true
		await Dialogue.talk([
			["SAMUEL", "—¿Usted durmió ahí, debajo del puente?"],
			["", "(...)"],
			["SAMUEL", "—Mal sitio. El río sube a las tres de la mañana. No mucho. Lo suficiente para que uno sueñe que se ahoga y tenga razón."],
			["ÉL", "Gorro rojo tejido a mano. No por él: esos puntos son de alguien que sabía. Once años en la calle, calculo. La barba también."],
			["SAMUEL", "—Yo no hablé el primer año. El segundo hablé solo. Ahora hablo con usted, que viene siendo lo mismo pero con público."],
			["SAMUEL", "—Ármese algo. Cartones, mínimo tres. El piso le chupa el calor como un cobrador."],
			["SAMUEL", "—Y cuide a ese perro. Aquí los perros desaparecen. La gente también, pero a la gente nadie la busca."],
		])
		return
	await _friend("samuel")
	if await _samuel_favor():
		return
	var opts := ["Sentarse con él"]
	if GameState.has_cambuche() and f.get("samuel_cuida_day", -1) != GameState.day:
		opts.append("Señalar el cambuche")
	opts.append("Seguir")
	var i := await Dialogue.talk([["SAMUEL", "—Once años en esto. Uno aprende a no esperar nada."],
		["SAMUEL", "—Mentira. Uno espera todo el tiempo. Lo que aprende es a no decirlo."]],
		opts)
	if opts[i] == "Señalar el cambuche":
		var food := ""
		for id in ["arepa", "empanada", "sandwich", "pan", "fruta"]:
			if GameState.count(id) > 0:
				food = id
				break
		if food == "":
			await Dialogue.talk([["SAMUEL", "—¿Que se lo cuide? Con gusto, compa. Pero de noche el estómago vigila más que los ojos. Tráigame algo de comer. Lo que sea. Menos sardinas, que me recuerdan a alguien."]])
			return
		GameState.remove_item(food)
		f["samuel_cuida_day"] = GameState.day
		await Dialogue.talk([
			["SAMUEL", "—(%s.) Hecho. Esta noche duermo cerca de su cambuche. Con un ojo." % Items.info(food)["name"]],
			["SAMUEL", "—Si alguien se acerca, va a escuchar un silbido. Ese silbido soy yo. El otro ruido también."],
		])
		return
	if i == 0:
		if TimeManager.hour() >= 18:
			await Dialogue.talk([["SAMUEL", "—Ya es de noche, compa. Vaya a buscar dónde quedarse. De noche el río cambia de dueño."]])
		else:
			var hours := (18 * 60.0 - TimeManager.minutes) / 60.0
			await Dialogue.talk([["", "(Se sientan a mirar el río. Samuel tampoco habla. Es la única conversación que le sale bien.)"]])
			TimeManager.skip(hours)
			await Dialogue.talk([["SAMUEL", "—Ya está oscureciendo. Vaya, vaya a su puente."], ["ÉL", "Mi puente. Dicho así suena a propiedad. Tengo un puente. Y un perro. Eso es más de lo que tiene mucha gente con casa."]])


# ---------------------------------------------------------------- El que le ocupó el lugar

func _stranger() -> void:
	await Dialogue.talk([
		["DESCONOCIDO", "—Llegué primero, hermano. Ley de la calle. Artículo uno."],
		["", "(...)"],
		["DESCONOCIDO", "—¿Me va a pelear? ¿No? ¿Va a decir algo? ¿Nada?"],
		["ÉL", "Cuchillo en la bota izquierda, la mano en la rodilla derecha. Zurdo que se cree diestro. Podría. No por un cartón."],
		["ÉL", "La mano ya se me había ido sola a la cintura. Buscando algo que no está ahí. Que nunca estuvo. Seguro."],
		["DESCONOCIDO", "—Uy, no. Los callados son los peores. Quédese con el cartón de la esquina. Y no me mire más, que me da mala suerte."],
	])
	if GameState.is_active("pasar_el_dia"):
		GameState.complete_quest("pasar_el_dia")
		GameState.start_quest("donde_dormir")


# ---------------------------------------------------------------- Doña Rosa (puesto de la plaza)

func _rosa() -> void:
	await _friend("rosa")
	var f := GameState.flags
	if not f.get("met_rosa", false):
		f["met_rosa"] = true
		await Dialogue.talk([
			["DOÑA ROSA", "—¡Empanada, arepa, aguapanela! ¡La empanada viene con ají, el ají sale gratis, la vida no!"],
			["", "(Mira las empanadas. Mucho rato.)"],
			["DOÑA ROSA", "—Mijito, mirar es gratis. Oler también. Comer, mil quinientos."],
			["DOÑA ROSA", "—¿No habla o le da pena?"],
			["", "(...)"],
			["DOÑA ROSA", "—Ay, qué maravilla. El primer cliente en veinte años que no me regatea."],
			["ÉL", "Mil quinientos. Tengo cero. Matemáticamente, la empanada y yo no tenemos futuro. Emocionalmente, tampoco."],
		])
	if await _rosa_favor():
		return
	if GameState.bond("rosa") >= 1 and GameState.money < 1500 and f.get("rosa_fiado_day", -1) != GameState.day \
			and GameState.has_space_for("empanada"):
		f["rosa_fiado_day"] = GameState.day
		GameState.add_item("empanada")
		await Dialogue.talk([["DOÑA ROSA", "—¿Sin plata? Tome, mijito. Me la paga cuando pueda. O nunca. Nunca también es una fecha."]])
	if GameState.is_dirty():
		await Dialogue.talk([["DOÑA ROSA", "—Ay, mijito... así no. La gente pasa, lo huele y se va. Y a mí me deja la empanada fría y la clientela tibia."],
			["DOÑA ROSA", "—Báñese en la plaza y vuelve. Yo lo espero. La empanada no."]])
		if GameState.money < 1500 and not f.get("rosa_fiado", false):
			f["rosa_fiado"] = true
			GameState.add_item("empanada")
			await Dialogue.talk([["DOÑA ROSA", "—Tome, una. Pero cómasela lejos. Allá. Más allá. Ahí."]])
		return
	await _shop("DOÑA ROSA", SHOP_ROSA)


# ---------------------------------------------------------------- Baño público y pensión

func _bano() -> void:
	var i := await Dialogue.talk([["", "BAÑO PUBLICO. Ducha y sanitario: $%d. Papel: traiga." % PRICE_BATH]],
		["Bañarme ($%d)" % PRICE_BATH, "Ahora no"])
	if i != 0:
		return
	if GameState.money < PRICE_BATH:
		await Dialogue.talk([["", "(No le alcanza.)"], ["CELADOR DEL BAÑO", "—Mil pesos, señor. El agua no se cae del cielo."],
			["CELADOR DEL BAÑO", "—Bueno, sí se cae. Martes y jueves, por el techo del fondo. Esos días cobro la mitad y le presto el balde."]])
		return
	GameState.add_money(-PRICE_BATH)
	GameState.set_hygiene(100.0)
	GameState.flags["bathed"] = GameState.day
	GameState.change_mood(5.0)
	TimeManager.skip(0.33)
	await Dialogue.talk([["", "(Agua fría. Muy fría. Sale negra, después gris, después clara.)"],
		["ÉL", "Tres colores. Como la bandera de un país donde nadie quiere vivir."]])


func _pension() -> void:
	var f := GameState.flags
	await Dialogue.talk([["PENSION", "—Pieza con baño: $%d la noche. Por adelantado. Toalla aparte. Perros no. Visitas no. Lágrimas, en la pieza." % PRICE_PENSION]])
	if not f.get("pension_lukas", false):
		f["pension_lukas"] = true
		await Dialogue.talk([["", "(Señala a Lukas. Después, debajo de la cama. Lukas contiene la respiración.)"],
			["ÉL", "Lukas sabe hacerse el tapete. Lo practicamos. Dos semanas. Es su mejor truco y nadie se lo aplaude."],
			["PENSION", "—... No me haga esos números de circo. ... Bueno. Pero si ladra, se van los dos. Y si se orina, se va usted y el perro se queda, que el perro no tiene la culpa."]])
	if not GameState.is_active("donde_dormir"):
		await Dialogue.talk([["PENSION", "—Se entra después de las seis. De día esto es una pensión decente. De noche también, pero más cara."]])
		return
	var price := PRICE_PENSION
	var opts := ["Pagar ($%d)" % price, "No"]
	if GameState.has_skill("labia"):
		opts.push_front("[MIRADA] Quedarse mirando")
	var i := await Dialogue.talk([["PENSION", "—¿Va a querer la pieza o vino a conocer?"]], opts)
	if opts[i] == "[MIRADA] Quedarse mirando":
		price = 12000
		await Dialogue.talk([["", "(Se queda mirándola. Sin parpadear. Lukas también.)"],
			["PENSION", "—... ¿Qué? ¿Qué me mira? ... ¿Y el perro por qué me mira?"],
			["PENSION", "—Doce mil. Doce, y dejen de mirarme así los dos. Y no le cuente a nadie. Bueno, usted no le cuenta nada a nadie. Por eso."]])
	elif opts[i] == "No":
		return
	if GameState.money < price:
		await Dialogue.talk([["PENSION", "—No le alcanza. La calle es gratis, joven. Tiene buena vista y nunca cierra."]])
		return
	GameState.add_money(-price)
	GameState.flags["sleep_spot"] = "pension"
	GameState.complete_quest("donde_dormir")
	SceneRouter.go("res://scenes/world/Night.tscn")


# ---------------------------------------------------------------- El recuerdo de la moto

const FLASHBACK_MOTO := "res://scenes/world/FlashbackMoto.tscn"
const MOTO_RIDE := "res://scenes/world/MotoRide.tscn"


## En el presente: una café racer igual a la que tuvo, parqueada frente al café.
func _moto_cafe() -> void:
	await Dialogue.talk([
		["", "(Una UM Renegade café. Negra mate, farola redonda, manubrio bajo. Un rayón en el tanque.)"],
		["ÉL", "Ciento ochenta centímetros cúbicos. Rin de rayos. El rayón va de izquierda a derecha, con una curva al final, como una firma."],
		["", "(Le pasa la mano por el rayón. Se queda quieto. Mucho rato.)"],
		["ÉL", "Conozco ese rayón. Lo hice yo. No sé cuándo. Sí sé cuándo."],
	])
	SceneRouter.go(FLASHBACK_MOTO, "", "ANTES")


## El señor de la chaqueta de cuero, en el taller de motos usadas.
func _chaqueta() -> void:
	var f := GameState.flags
	if f.get("fb_paid", false):
		await Dialogue.talk([["EL DE LA CHAQUETA", "—¿Qué hace ahí parado? Súbase, pelado. La vida no espera. La moto sí, pero la vida no."]])
		return
	if not f.get("fb_met", false):
		f["fb_met"] = true
		await Dialogue.talk([
			["EL DE LA CHAQUETA", "—¿Usted es el pelado de la Renegade? ¿La café?"],
			["", "(Asiente. Saca la plata. Le tiemblan las manos.)"],
			["EL DE LA CHAQUETA", "—Tan callado como por teléfono. Me llamó tres veces y no dijo nada. Yo supe que era usted por la respiración. Usted respira como alguien que ahorra."],
			["EL DE LA CHAQUETA", "—Un señor me ofreció trescientos mil más. Le dije que no. Me miró como si yo estuviera loco. Puede ser."],
			["EL DE LA CHAQUETA", "—Pero esa moto ya tenía dueño. Solo que el dueño todavía estaba juntando."],
			["EL DE LA CHAQUETA", "—Ciento ochenta. Asiento de joroba. Tiene un rayón en el tanque. No se lo quité. Un rayón así no se le quita a una moto. Es como quitarle el apellido."],
			["ÉL", "Tiene ochenta y siete billetes de veinte en el bolsillo. Los conté anoche. Y esta mañana. Y en el bus."],
		])
	while true:
		var i := await Dialogue.talk([["EL DE LA CHAQUETA", "—¿Entonces?"]], ["Pagar", "Mirarla un rato más"])
		if i == 1:
			await Dialogue.talk([["", "(La mira. Negra mate. Farola redonda.)"],
				["EL DE LA CHAQUETA", "—Mírela todo lo que quiera. Las motos no se quejan de que uno no hable."],
				["EL DE LA CHAQUETA", "—Mi primera mujer sí se quejaba. Mi segunda moto, no. Saque usted la conclusión. Yo ya la saqué y vivo solo."]])
			continue
		f["fb_paid"] = true
		await Dialogue.talk([
			["", "(Saca el fajo. Billetes de veinte, doblados, contados cuarenta veces. Un año entero metido en un bolsillo.)"],
			["EL DE LA CHAQUETA", "—... dieciocho, diecinueve, veinte. Completa. Y huelen a bolsillo. Eso no se falsifica."],
			["EL DE LA CHAQUETA", "—Tome las llaves. El casco se lo regalo. No por bueno: para que no me la devuelva en una bolsa."],
			["EL DE LA CHAQUETA", "—¿Ni un \"gracias\"? ... Bueno. Arránquela. Eso es un gracias. El mejor que hay."],
		])
		return


## La moto en el recuerdo: subirse.
func _fb_moto() -> void:
	if not GameState.flags.get("fb_paid", false):
		await Dialogue.talk([["EL DE LA CHAQUETA", "—Ey, ey. Primero se paga, después se toca. Así funcionan las motos, las casas y casi todo lo demás."]])
		return
	var i := await Dialogue.talk([["", "(Su moto.)"]], ["Subirse", "Todavía no"])
	if i != 0:
		return
	SceneRouter.go(MOTO_RIDE)


# ---------------------------------------------------------------- Día 3: la cédula

const PRICE_BUS := 2500
const PRICE_PHOTO := 8000
const PRICE_CEDULA := 55000
const CENTRO := "res://scenes/world/Centro.tscn"
const CITY_SCENE := "res://scenes/world/City.tscn"
const FILA := "res://scenes/world/Fila.tscn"


func _needs_address() -> bool:
	return GameState.is_active("c_direccion") and GameState.count("carta_german") == 0 \
		and GameState.count("direccion_zaida") == 0


## Lo que Germán tiene para contar según el momento de la historia.
func _german_story() -> void:
	var f := GameState.flags
	if GameState.is_active("hablar_german"):
		await Dialogue.talk([
			["DON GERMAN", "—Mijo, venga. Siéntese. No, mejor párese. Esto se recibe parado."],
			["DON GERMAN", "—Mi cuñado tiene una obra aquí cerca. Un edificio de cinco pisos que va a tener cuatro, porque se le acabó la plata. Necesita un ayudante."],
			["DON GERMAN", "—Fijo. Con sueldo. Con quincena. Con día de pago escrito en un papel."],
			["", "(Abre mucho los ojos.)"],
			["ÉL", "Quincena. Hace un año que no oía esa palabra. Suena a idioma muerto. Suena a latín."],
			["DON GERMAN", "—Sí, existe todavía, aunque no lo crea. Pero piden cédula. ¿Usted tiene?"],
			["", "(Niega con la cabeza.)"],
			["DON GERMAN", "—Pues saque el duplicado. En el centro, en la Registraduría. El bus sale de la plaza."],
			["DON GERMAN", "—Y en la ventanilla no se quede callado, que allá al que no habla lo dan por muerto. Y una vez que lo dan por muerto, sacar el certificado de vivo cuesta más."],
		])
		GameState.complete_quest("hablar_german")
		for q in ["cedula", "c_plata", "c_foto", "c_direccion"]:
			GameState.start_quest(q)
		f["centro_open"] = true
	elif GameState.count("cedula") > 0 and not f.get("german_cedula_seen", false):
		f["german_cedula_seen"] = true
		await Dialogue.talk([
			["", "(Pone la cédula en el mostrador. No dice nada. No hace falta.)"],
			["DON GERMAN", "—¿La sacó? ¡Eso, mijo! ¡Eso! ... Diga algo, hombre. ¿No? Bueno, yo grito por los dos: ¡ESO!"],
			["", "(Dos señoras se voltean. Una se persigna.)"],
			["ÉL", "La foto salió horrible. Parezco un hombre al que acaban de devolver de algún lado. Que es lo que soy."],
			["DON GERMAN", "—Ya mismo le aviso a mi cuñado. Prepárese, que la obra no es panadería: allá se suda. Y allá nadie habla tampoco. Va a estar en su salsa."],
		])
		f["obra_ready"] = true


func _german_address() -> void:
	var f := GameState.flags
	if not f.has("german_dir_day"):
		f["german_dir_day"] = GameState.day
		await Dialogue.talk([
			["", "(Le muestra el papel de los requisitos. Señala \"DIRECCIÓN\". No levanta la vista.)"],
			["DON GERMAN", "—¿Qué? ¿Qué me señala? ... ¿Dirección? ... ¿Mi dirección?"],
			["DON GERMAN", "—Uy, mijo. Déjeme hablarlo con mi señora. Ella es la que manda en los papeles. Venga mañana."],
			["ÉL", "Su señora. La que se fue hace seis años. Lo dice en presente. No lo corrijo. Yo también tengo verbos que no conjugo en pasado."],
		])
	elif GameState.day > f["german_dir_day"]:
		if not GameState.has_space_for("carta_german"):
			await Dialogue.talk([["DON GERMAN", "—Haga espacio en esa mochila. Esto no se dobla. Hay cosas que no se doblan."]])
			return
		GameState.add_item("carta_german")
		await Dialogue.talk([
			["DON GERMAN", "—Ponga la mía: calle 9 número 14-32. Se la anoté en una bolsa de pan. La Mercedes dijo que sí."],
			["DON GERMAN", "—Si le llega correspondencia, se la guardo con el pan. Si es de un banco, la boto. Así hacía ella."],
			["", "(Le aprieta la mano. Mucho rato. No la suelta.)"],
			["DON GERMAN", "—Ya, ya, suélteme, que me va a sacar lágrimas y la harina se pega. Tráigame esa cédula, que mi cuñado no espera."],
		])
	else:
		await Dialogue.talk([["DON GERMAN", "—Mañana, mijo, mañana. Mi señora todavía no se decide. Ella es así. Le tomó cuatro años decidir casarse conmigo."]])


## El bus entre el barrio y el centro (o caminar).
func _bus(to_centro: bool) -> void:
	if to_centro and not GameState.flags.get("centro_open", false):
		await Dialogue.talk([["CONDUCTOR", "—¿Va a subir o va a seguir mirando? ... No. Bueno. Siga mirando, que es gratis. Lo único gratis en esta ruta."]])
		return
	var where := "al centro" if to_centro else "al barrio"
	var i := await Dialogue.talk([["", "(Paradero. Buses %s.)" % where]],
		["Bus ($%d, 20 min)" % PRICE_BUS, "Caminar (1 hora)", "Nada"])
	if i == 2:
		return
	if i == 0:
		if GameState.money < PRICE_BUS:
			await Dialogue.talk([["CONDUCTOR", "—Dos mil quinientos. ¿No tiene? ¿Y me va a mirar así hasta que se los regale?"],
				["CONDUCTOR", "—Yo tengo tres hijos, una exesposa y una cuota de este bus. Ninguno me mira así. Bájese."]])
			return
		GameState.add_money(-PRICE_BUS)
		TimeManager.skip(0.33)
	else:
		TimeManager.skip(1.0)
	var line := "Una hora caminando." if i == 1 else ""
	SceneRouter.go(CENTRO if to_centro else CITY_SCENE, "FromBus", "", line)


func _celador() -> void:
	await Dialogue.talk([
		["CELADOR", "—Registraduría. Atendemos de ocho a once. La fila empieza a las seis. La esperanza, más temprano."],
		["CELADOR", "—Para el duplicado: fotos, una dirección y cincuenta y cinco mil. Sin eso, ni haga la fila. Con eso, tampoco garantizo."],
		["", "(...)"],
		["CELADOR", "—¿Entendió? ... ¿Me entendió? Hágame una seña. Una. ... Eso. Y si le falta algo, vuelve a hacer la fila. Es como la vida, pero con número."],
		["ÉL", "Fotos, dirección, cincuenta y cinco mil. Tengo cero de tres. En la oficina eso se llamaba \"un reto\" y te daban una galleta."],
	])
	var f := GameState.flags
	if GameState.has_skill("labia") and not f.get("vip_labia", false) and not f.has("cedula_day") and GameState.count("cedula") == 0:
		var i := await Dialogue.talk([["", "(El celador está aburrido.)"]],
			["[MIRADA] Quedarse mirándolo", "Nada"])
		if i == 0:
			f["vip_labia"] = true
			f["fila_vip_day"] = GameState.day if TimeManager.hour() < 11 else GameState.day + 1
			await Dialogue.talk([
				["", "(Se le queda mirando. Sin parpadear. Diez segundos. Veinte.)"],
				["CELADOR", "—... ¿Qué? ... ¿QUÉ? ... ¿Usted es de la Procuraduría?"],
				["CELADOR", "—Ay, ya. Mañana temprano. Por la puerta de al lado. Si alguien pregunta, usted es mi sobrino. El callado. Todas las familias tienen uno."],
			])


func _registraduria() -> void:
	var f := GameState.flags
	if f.has("cedula_day"):
		if GameState.day >= f["cedula_day"]:
			GameState.add_item("cedula")
			f.erase("cedula_day")
			GameState.complete_quest("recoger_cedula")
			GameState.start_quest("sobrevivir")
			await Dialogue.talk([
				["FUNCIONARIA", "—¿Nombre? ... Aquí está. Firme aquí. Y aquí. Y aquí. Y aquí no, que ahí firmo yo."],
				["", "(Una tarjeta plastificada. Su cara, su nombre, su número.)"],
				["ÉL", "Diez dígitos. Los mismos de antes. El Estado me borró y me volvió a escribir igualito. Ni una mejora. Ni una errata."],
				["FUNCIONARIA", "—Ya existe, señor. Felicitaciones. ¿No dice nada? ... Nadie dice nada. Siguiente."],
			])
		else:
			await Dialogue.talk([["CELADOR", "—¿Duplicado? Todavía no ha llegado. Vuelva el día %d." % f["cedula_day"]],
				["CELADOR", "—Y no me mire así, que yo no hago las cédulas. Yo solo las espero. Llevo veintidós años esperándolas. Usted lleva dos días."]])
		return
	if GameState.count("cedula") > 0:
		await Dialogue.talk([["CELADOR", "—¿Otra vez usted? Ya tiene cédula. ¿Qué quiere, otra? ¿Una de repuesto? ¿Para la casa de campo?"]])
		return
	var h := TimeManager.hour()
	if h >= 11:
		await Dialogue.talk([["CELADOR", "—Cerrado. Vuelva mañana. A las ocho abrimos, pero a las ocho ya no hay nada. A las seis. A las cinco. Traiga cobija."]])
		return
	var i := await Dialogue.talk([["", "(La fila sale por la puerta y dobla la esquina. Abren a las ocho y cierran a las once.)"]],
		["Hacer la fila", "Ahora no"])
	if i == 0:
		SceneRouter.go(FILA)


func _fotos() -> void:
	if GameState.count("foto_doc") > 0 or GameState.count("cedula") > 0 or GameState.flags.has("cedula_day"):
		await Dialogue.talk([["FOTOGRAFO", "—¿Otra vez? Ya le tomé la foto. La cara no le cambió. Créame, la estudié."]])
		return
	if GameState.is_dirty():
		await Dialogue.talk([["FOTOGRAFO", "—Así no, joven. Báñese primero. La cámara es una Canon del noventa y ocho. Ha visto cosas. No la haga ver más."]])
		return
	var i := await Dialogue.talk([["FOTOGRAFO", "—Fotos tipo documento: $%d. Fondo blanco, cara seria. La cara seria la pone usted." % PRICE_PHOTO]],
		["Tomarse la foto", "Ahora no"])
	if i != 0:
		return
	if GameState.money < PRICE_PHOTO:
		await Dialogue.talk([["FOTOGRAFO", "—No le alcanza. Y fiado no. Yo me acuerdo de las caras, pero las caras no se acuerdan de mí."]])
		return
	if not GameState.has_space_for("foto_doc"):
		await Dialogue.talk([["FOTOGRAFO", "—¿Y dónde se las va a llevar? ¿En la mano? Se le doblan. Desocupe esa mochila."]])
		return
	GameState.add_money(-PRICE_PHOTO)
	GameState.add_item("foto_doc")
	await Dialogue.talk([
		["FOTOGRAFO", "—Mire aquí. No sonría, que es para la cédula."],
		["FOTOGRAFO", "—... Bueno, no hacía falta decírselo."],
		["", "(Flash.)"],
		["FOTOGRAFO", "—Salió con cara de sospechoso. Es la foto más honesta que he tomado en mi vida. Y le he tomado a tres concejales."],
	])


# ---------------------------------------------------------------- Zaida

func _zaida(npc: Node) -> void:
	var f := GameState.flags
	if f.get("zaida_met", false):
		var line := "—Te dije, mi amor: siempre te encuentro. Es mi talento. El otro es no olvidar." if f.get("zaida_favor", false) else "—¿Ya te decidiste? La oferta sigue. Yo sigo. Las dos somos muy constantes."
		await Dialogue.talk([["ZAIDA", line]])
		if not f.get("zaida_favor", false) and _needs_address():
			var j := await Dialogue.talk([["ZAIDA", "—Mi dirección. Turno para mañana, sin fila. Gratis. Bueno, gratis hoy."]], ["Aceptar", "No"])
			if j == 0:
				await _zaida_accept()
		return
	f["zaida_met"] = true
	await Dialogue.talk([
		["ZAIDA", "—¿...? ¡No! ¿Sos vos? Qué casualidad tan grande."],
		["ÉL", "No es casualidad. Las casualidades no llevan tacones nuevos un martes. Perfume de los caros, del que se compra para que alguien lo note."],
		["", "(...)"],
		["ZAIDA", "—Igualito. Callado como una tumba. Me encanta: así hablo yo por los dos, que es como me gusta."],
		["ZAIDA", "—Te ves... bueno, te ves. Me contaron que estuviste en la Clínica Irene. No me mirés así, la gente habla. Vos no, pero la gente sí."],
		["ÉL", "La Clínica Irene. Nadie sabe eso. Nadie que no haya ido a preguntar."],
		["ZAIDA", "—¿Y qué hacés por acá? ¿La cédula? Necesitás una dirección, ¿cierto? No me contestés, ya sé que sí."],
		["ZAIDA", "—Poné la mía. Y conozco a alguien adentro: te consigo turno para mañana a primera hora. Sin fila."],
		["ZAIDA", "—No me tenés que dar nada. Bueno... ya hablaremos. Yo hablo, vos asentís. Como antes."],
	])
	if not _needs_address():
		await Dialogue.talk([["", "(Le muestra la bolsa de pan con la dirección de Don Germán.)"],
			["ZAIDA", "—Ah. Una bolsa de pan. Qué bien. Qué... bien. Qué tierno. Qué... harinoso."]])
		return
	var i := await Dialogue.talk([["ZAIDA", "—¿Entonces? ¿Sí? Asentí, mi amor, que eso sí lo sabés hacer."]],
		["Asentir", "Darse la vuelta"])
	if i == 0:
		await _zaida_accept()
	else:
		await Dialogue.talk([
			["ZAIDA", "—Germán. El de la panadería. Qué bonito que tengas a alguien."],
			["ZAIDA", "—Igual aquí voy a estar. Siempre estoy. Preguntale a cualquiera."],
			["ÉL", "No conozco a ningún Germán, le dije con la espalda. Ella dijo su nombre igual. Eso no es saber cosas. Eso es seguir a alguien."],
		])


func _zaida_accept() -> void:
	var f := GameState.flags
	if not GameState.has_space_for("direccion_zaida"):
		await Dialogue.talk([["ZAIDA", "—Hacé espacio en esa mochila, mi amor. Yo espero. Soy buenísima esperando. Preguntale a mi exmarido. Bueno, no podés."]])
		return
	f["zaida_favor"] = true
	f["fila_vip_day"] = GameState.day + 1
	GameState.add_item("direccion_zaida")
	await Dialogue.talk([
		["ZAIDA", "—Así me gusta. Mañana a las ocho, entrás directo. Decí que vas de mi parte."],
		["ZAIDA", "—Te escribo. ... Ah, no tenés celular. Ni voz. Qué hombre tan cómodo. Si fueras mudo y rico, me casaba."],
		["ZAIDA", "—Yo te encuentro. Siempre te encuentro."],
		["ÉL", "Eso, mi amor, no es una promesa. Es una amenaza con labial."],
	])


# ---------------------------------------------------------------- Minijuegos de plata

func _fuente() -> void:
	var h := TimeManager.hour()
	if GameState.flags.get("fuente_day", -1) == GameState.day:
		await Dialogue.talk([["", "(La fuente está vacía. Ni un deseo.)"], ["ÉL", "Me los llevé todos. Ninguno era mío. Ninguno se cumplió. Por algo los habían tirado."]])
		return
	if h < 7 or h >= 20:
		await Dialogue.talk([["CELADOR", "—(Desde la caseta, medio dormido.) Ni lo piense. Lo estoy viendo. Con un ojo. El otro está en su turno de descanso."]])
		return
	var i := await Dialogue.talk([["", "(Una fuente. En el fondo, monedas.)"]],
		["Pescar monedas", "Dejarles los deseos"])
	if i == 0:
		SceneRouter.go("res://scenes/world/Fuente.tscn")


func _pedir() -> void:
	var h := TimeManager.hour()
	if h < 7 or h >= 19:
		await Dialogue.talk([["", "(A esta hora no pasa nadie.)"], ["ÉL", "Y los que pasan no dan. A esta hora la caridad está durmiendo. Como la gente decente."]])
		return
	var i := await Dialogue.talk([["", "(Una vereda con gente. Un vaso. Un cartón para escribir.)"]],
		["Sentarse a pedir (1 hora)", "Todavía no"])
	if i != 0:
		return
	GameState.flags["pidio_dia"] = GameState.day
	var scene := get_tree().current_scene
	GameState.flags["pedir_return"] = [scene.scene_file_path, "FromPedir"]
	SceneRouter.go("res://scenes/world/Pedir.tscn")


# ---------------------------------------------------------------- Favores (vínculos)

## Don Germán: el anillo de matrimonio (lo encuentra Lukas detrás de las bodegas).
func _german_favor() -> void:
	var f := GameState.flags
	if GameState.is_active("f_anillo_volver") and GameState.count("anillo") > 0:
		GameState.remove_item("anillo")
		GameState.complete_quest("f_anillo_volver")
		await Dialogue.talk([
			["", "(Pone el anillo en el mostrador. Lukas mueve la cola, orgulloso.)"],
			["DON GERMAN", "—..."],
			["DON GERMAN", "—Era de Mercedes. Mi señora. Hace seis años que se fue. Se murió, digo. Ve, ya lo dije. Seis años y es la primera vez que lo digo así."],
			["DON GERMAN", "—Yo todavía me lo pongo para abrir la panadería. Ella decía que el pan sale mejor si uno lo amasa con algo que quiere puesto."],
			["ÉL", "Iba a hacer un chiste. Tenía uno sobre la levadura. No lo hice. Hay chistes que uno se guarda por respeto a la levadura."],
			["", "(...)"],
			["DON GERMAN", "—Gracias, mijo. Desde hoy el pan del día es suyo. Todos los días. No me discuta. Bueno, usted no discute. Por eso me cae bien."],
		])
		GameState.raise_bond("german")
		return
	if GameState.day >= 4 and not f.get("f_anillo_ofrecido", false) and not GameState.is_active("hablar_german"):
		f["f_anillo_ofrecido"] = true
		await Dialogue.talk([
			["DON GERMAN", "—Mijo... ¿le puedo pedir un favor? Es una bobada."],
			["DON GERMAN", "—Se me cayó el anillo. El de matrimonio. Detrás de las bodegas, cuando fui a buscar estibas."],
			["DON GERMAN", "—Ya lo busqué tres veces. Con linterna. Con lupa. Con la ayuda de una señora que pasaba. Estos ojos ya no ven, y los de ella tampoco."],
			["", "(Señala a Lukas. Lukas olfatea el aire, muy profesional.)"],
			["DON GERMAN", "—¿El perro? ¿Usted me está ofreciendo al perro? ... Bueno. Peor que yo no lo va a buscar."],
		])
		GameState.start_quest("f_anillo")
		Narrator.say("Detrás de las bodegas. Lukas: F, y que busque.")


## Marta: Michi, el gato. Está en la casa de tejas. La que nunca abre.
func _marta_favor() -> void:
	var f := GameState.flags
	if GameState.is_active("f_gato_volver"):
		GameState.remove_item("collar_michi")
		GameState.complete_quest("f_gato_volver")
		await Dialogue.talk([
			["MARTA", "—¡Michi volvió! Llegó solito, todo asustado. ¿Dónde estaba?"],
			["", "(Señala hacia la esquina. Hacia la casa de tejas.)"],
			["MARTA", "—..."],
			["MARTA", "—¿En esa casa? Ahí no vive nadie. Doña Inés murió en el 2019. La encontraron a los tres días."],
			["", "(Hace el gesto de una mano que se asoma y entra una bolsa.)"],
			["MARTA", "—¿Una mano? ¿Te recibieron el pedido? ... Llegan por la app. Pagados. Siempre a nombre de ella."],
			["ÉL", "La mano muy blanca. La gaseosa de naranja. Tres años de pedidos. Debería tener miedo. Tengo hambre. Prioridades."],
			["MARTA", "—Tomá. Ocho mil. Y no me preguntes más de esa casa. Por favor. Yo cierro sola."],
		])
		GameState.add_money(8000)
		GameState.raise_bond("marta")
		f["casa_tejas_misterio"] = true
		return
	if GameState.day >= 3 and not f.get("f_gato_ofrecido", false) and f.get("met_marta", false):
		f["f_gato_ofrecido"] = true
		await Dialogue.talk([
			["MARTA", "—¿Has visto un gato negro con un collar rojo? Michi. Se fue hace dos días."],
			["MARTA", "—Siempre vuelve a las cuatro, cuando sale el pan de Germán. Siempre. Es más puntual que el papá de mi hijo. Bueno, eso no es difícil."],
			["MARTA", "—Sin él el café está muy callado. Bueno, con vos también. Pero vos no me botás las tazas."],
		])
		GameState.start_quest("f_gato")


## Samuel: una carta para su hija. Él no sabe escribir. Devuelve true si la conversación fue esto.
func _samuel_favor() -> bool:
	var f := GameState.flags
	if GameState.is_active("f_carta_volver"):
		var i := await Dialogue.talk([["SAMUEL", "—¿Y? ¿Se la dio?"]], ["Asentir", "Devolverle la carta"])
		GameState.complete_quest("f_carta_volver")
		if i == 0:
			GameState.remove_item("carta_samuel")
			f["samuel_mentira"] = true
			await Dialogue.talk([
				["", "(Asiente.)"],
				["ÉL", "Mentí. Con la cabeza, que es la forma más barata de mentir. No sale en ningún expediente."],
				["SAMUEL", "—... ¿Y cómo estaba?"],
				["", "(Le señala la cara a Samuel. Igualita.)"],
				["SAMUEL", "—¿Se parece a mí? Pobrecita."],
				["", "(Se ríe. Se le quiebra la risa en la mitad.)"],
			])
		else:
			await Dialogue.talk([
				["", "(Le devuelve la carta. Sin abrir.)"],
				["SAMUEL", "(Mira la carta. Mira el río un rato largo.)"],
				["SAMUEL", "—Once años. Uno cree que el tiempo espera. El tiempo es como el bus de la 9: pasa lleno y no para."],
				["SAMUEL", "—Guárdela usted. Algún día tal vez tenga a quién dársela."],
				["ÉL", "Tengo a quién. Ese es el problema. Tener a quién y no tener cómo."],
			])
		GameState.raise_bond("samuel")
		return true
	if GameState.day >= 4 and not f.get("f_carta_ofrecido", false) and f.get("met_samuel", false):
		f["f_carta_ofrecido"] = true
		await Dialogue.talk([
			["SAMUEL", "—Oiga... usted sabe escribir, ¿cierto? Tiene cara de haber terminado el colegio. Y de haber hecho las tareas de otros."],
			["", "(Asiente.)"],
			["SAMUEL", "—Usted no habla, pero escribe. Yo hablo, pero no escribo. Entre los dos somos una persona. Una persona bien rara."],
			["SAMUEL", "—Tengo una hija. Diana. No la veo hace once años. Quiero mandarle una carta. Yo no sé escribir."],
			["SAMUEL", "—Firmo con una equis. Durante años creí que la equis era mi inicial. No. Me llamo Samuel."],
		])
		var a := ["Querida Diana:", "Mija:", "No sé si te acordás de mí:"]
		var b := ["Estoy bien.", "No estoy bien, pero estoy.", "Perdón."]
		var c := ["Tu papá, Samuel.", "Si querés, contestame.", "Te quiero. Siempre te quise."]
		var i1 := await Dialogue.talk([["SAMUEL", "—¿Cómo empiezan esas cosas?"]], a)
		var i2 := await Dialogue.talk([["SAMUEL", "—¿Y qué le digo?"]], b)
		if i2 == 1:
			await Dialogue.talk([["SAMUEL", "—Ponga esa. Esa es la verdad."]])
		var i3 := await Dialogue.talk([["SAMUEL", "—¿Y cómo se termina?"]], c)
		f["carta_texto"] = "%s %s %s" % [a[i1], b[i2], c[i3]]
		GameState.add_item("carta_samuel")
		await Dialogue.talk([
			["", "(Lo escribe con letra grande, para que se entienda. Samuel lo mira como si fuera un cuadro.)"],
			["SAMUEL", "—La última dirección que tengo es la casa del fondo, al este. Pasando la avenida."],
		])
		GameState.start_quest("f_carta")
		return true
	return false


func _deliver_letter() -> void:
	GameState.complete_quest("f_carta")
	GameState.start_quest("f_carta_volver")
	await Dialogue.talk([
		["", "(Toca. Abre una señora mayor, con la cadena puesta.)"],
		["SEÑORA", "—¿Diana? Diana se fue hace años. A Bogotá, o a España. No sé. A uno de esos lugares de donde la gente no vuelve."],
		["SEÑORA", "—¿Usted quién es? ¿El papá?"],
		["", "(Le muestra la carta.)"],
		["SEÑORA", "—Si es el papá, dígale que ella lo esperó. Mucho tiempo. En esta ventana. Después ya no."],
		["", "(La puerta se cierra. La carta sigue en su mano.)"],
		["ÉL", "Tengo un chiste sobre el correo. Lo tenía. Se me fue."],
	])


## Doña Rosa: cuidarle el puesto una hora. Devuelve true si se fue a cuidarlo.
func _rosa_favor() -> bool:
	var f := GameState.flags
	var h := TimeManager.hour()
	if GameState.day >= 3 and not f.get("f_puesto_hecho", false) and h >= 8 and h < 16 and f.get("met_rosa", false) \
			and not GameState.is_dirty():
		var i := await Dialogue.talk([
			["DOÑA ROSA", "—Mijito, ¿me cuida el puesto una horita? Tengo cita en el médico. Del azúcar. Vendo empanadas y tengo el azúcar alto. La vida tiene sentido del humor."],
		], ["Cuidar el puesto", "Ahora no"])
		if i == 0:
			f["f_puesto_hecho"] = true
			SceneRouter.go("res://scenes/world/Puesto.tscn")
			return true
	return false


# ---------------------------------------------------------------- Los cuencos (Lukas toma agua; se guarda)

func _cuenco(id: String) -> void:
	var f := GameState.flags
	var scene := get_tree().current_scene
	if not f.get("cuenco_visto", false):
		f["cuenco_visto"] = true
		await Dialogue.talk([["", "(Un cuenco abollado con agua limpia. Alguien lo llena para los perros de la calle.)"],
			["ÉL", "Nadie sabe quién. Nadie ha visto a nadie llenarlo. Siempre está lleno. Es lo único en esta ciudad que funciona y nadie lo cobra."]])
	if not GameState.lukas_alive():
		var k := await Dialogue.talk([["", "(El cuenco con agua limpia. Alguien lo sigue llenando. Se sienta un rato al lado.)"],
			["ÉL", "..."]],
			["Guardar partida", "Seguir"])
		if k == 0:
			GameState.save_game(scene.scene_file_path, "Spawn_" + id)
			await Dialogue.talk([["", "PARTIDA GUARDADA."]])
		return
	var lukas := scene.find_child("Lukas", true, false)
	var spot := scene.find_child("Servicio_" + id, true, false)
	if lukas and spot:
		# Va hasta el cuenco y toma de verdad (el pie del dibujo está 4 px arriba del servicio).
		await lukas.drink(spot.global_position - Vector2(0, 4))
	var drank: bool = f.get("lukas_water_day", -1) == GameState.day
	f["lukas_water_day"] = GameState.day
	GameState.complete_quest("lukas_agua")
	GameState.calm_until = maxf(GameState.calm_until, TimeManager.minutes + 30.0)
	var line := "(Lukas mete el hocico hasta los ojos. Lame y lame, como si fuera la última agua del mundo. Lo salpica todo.)" \
		if not drank else "(Lukas toma un poquito más. Lame tres veces y se relame.)"
	var i := await Dialogue.talk([["", line]], ["Guardar partida", "Seguir"])
	if i == 0:
		GameState.save_game(scene.scene_file_path, "Spawn_" + id)
		await Dialogue.talk([["", "PARTIDA GUARDADA."]])


# ---------------------------------------------------------------- La familia (sin chistes)

const PRICE_CALL := 500


## El teléfono público: llamar a la mamá. Dispara el sueño 6 (Brenda).
func _telefono() -> void:
	var f := GameState.flags
	if not GameState.is_active("llamar_mama"):
		var line := "(Un teléfono público. Le falta el directorio. Le sobra un chicle.)"
		await Dialogue.talk([["", line]])
		return
	var i := await Dialogue.talk([["", "(Un teléfono público. Marca un número sin mirar el teclado.)"]],
		["Llamar ($%d)" % PRICE_CALL, "Todavía no"])
	if i != 0:
		return
	if GameState.money < PRICE_CALL:
		await Dialogue.talk([["", "(No le alcanza. Cuelga antes de marcar.)"]])
		return
	GameState.add_money(-PRICE_CALL)
	MusicDirector.force("")
	await Dialogue.talk([
		["", "(Tuuu... tuuu... tuuu...)"],
		["", "(Va a colgar. Está a punto de colgar.)"],
		["BRENDA", "—¿Aló?"],
		["BRENDA", "—¿Aló? ¿Quién es?"],
	])
	var j := await Dialogue.talk([["", "(...)"]], ["Quedarse en la línea", "Colgar"])
	if j == 0:
		f["llamada_mama"] = "hablo"
		await Dialogue.talk([
			["BRENDA", "—¿Aló? ... ¿Mijo? ... ¿Es usted? Le oigo la respiración."],
			["ÉL", "Bueno. Aquí es donde yo digo algo gracioso y ella se ríe y todo..."],
			["", "(Aprieta el teléfono.)"],
			["BRENDA", "—¿Está bien? ¿Está comiendo? ... Diga algo. Lo que sea. Una palabra."],
			["", "(Abre la boca. No sale nada. Por dentro tampoco.)"],
			["", "(Lukas ladra.)"],
			["BRENDA", "—¿Eso es un perro? ¿Tiene un perro? ... Mijo... no me llame a este número. Aquí no saben de usted. Aquí estoy empezando otra vez."],
			["BRENDA", "—Cuídese. Por favor."],
			["", "(Clic.)"],
		])
	else:
		f["llamada_mama"] = "colgo"
		await Dialogue.talk([
			["BRENDA", "—¿Aló? ... ¿Es usted?"],
			["BRENDA", "—Si es usted... yo..."],
			["", "(Cuelga.)"],
		])
	f["llamo_mama"] = true
	f["llamo_mama_dia"] = GameState.day
	GameState.complete_quest("llamar_mama")
	GameState.change_mood(-8.0)


## El hombre de la moto, en la plaza: Mauricio. No lo reconoce. Dispara el sueño 7.
func _mauricio_plaza(npc: Node) -> void:
	var f := GameState.flags
	if f.get("papa_encuentro", false):
		return
	f["papa_encuentro"] = true
	f["papa_encuentro_dia"] = GameState.day
	MusicDirector.force("")
	await Dialogue.talk([
		["", "(Un señor con chaleco de cuero y bigote. Una mano en la cintura.)"],
		["", "(Él se para igual. Exactamente igual.)"],
		["SEÑOR", "—¿Qué me mira, joven? ¿Tiene hambre?"],
		["SEÑOR", "—Tome. Pa' un tinto."],
		["", "(Le pone una moneda en la mano. La mano es la misma. Más vieja.)"],
	])
	GameState.add_money(1000)
	var i := await Dialogue.talk([["", "(...)"]], ["No soltarle la mano", "Recibir la moneda"])
	if i == 0:
		f["papa_respuesta"] = "dijo"
		await Dialogue.talk([
			["", "(No le suelta la mano. Lo mira. Abre la boca. No sale nada.)"],
			["SEÑOR", "—..."],
			["SEÑOR", "—¿Qué le pasa? ¿Me conoce? ... No, joven. Se confundió. Yo tengo dos hijos y están muy bien."],
			["SEÑOR", "—Los veo todos los domingos."],
			["", "(Se sube a la moto. La moto suena igual que hace quince años, cuando se fue.)"],
			["ÉL", "Todos los domingos. Yo me acuerdo de los domingos. Eran los días en que más se le notaba que no estaba."],
		])
	else:
		f["papa_respuesta"] = "callo"
		await Dialogue.talk([
			["", "(Cierra la mano con la moneda.)"],
			["SEÑOR", "—¿Ni las gracias? Así está la juventud. Y ese perro, cuídelo, que es buen perro."],
			["ÉL", "Mil pesos. Quince años de pensión alimenticia y me llegan en una moneda. Por lo menos es de las nuevas."],
			["", "(Se sube a la moto. La moto suena igual que hace quince años, cuando se fue.)"],
		])
	GameState.complete_quest("papa_plaza")
	GameState.change_mood(-10.0)
	var t := create_tween()
	t.tween_property(npc, "modulate:a", 0.0, 1.2)
	t.tween_callback(npc.queue_free)
	var moto := get_tree().current_scene.find_child("MotoPapa", true, false)
	if moto:
		var t2 := create_tween()
		t2.tween_property(moto, "position:x", moto.position.x + 260.0, 1.6)
		t2.tween_callback(moto.queue_free)


# ---------------------------------------------------------------- El Parque de San Judas
# El lugar menos lúgubre del juego: acá se pierde el tiempo y, si hace falta, se gana plata
# ayudando. Cada trabajo, una vez por día. Lo que él ve cambia con la locura (GameState.locura_level).

const PARQUE := "res://scenes/world/Parque.tscn"


## ¿Ya hizo este trabajo hoy?
func _job_today(id: String) -> bool:
	return GameState.flags.get("job_" + id, -1) == GameState.day


func _job_done(id: String) -> void:
	GameState.flags["job_" + id] = GameState.day
	_worked()


## Un día con trabajo cuenta para la Defensoría ("tiene trabajo").
func _worked() -> void:
	var f := GameState.flags
	if f.get("trabajo_ultimo", -1) != GameState.day:
		f["trabajo_ultimo"] = GameState.day
		f["trabajo_dias"] = int(f.get("trabajo_dias", 0)) + 1


## Una de tres opciones según la locura (0: está bien, 1: raro, 2: ya habla con las cosas).
func _by_locura(options: Array):
	return options[mini(GameState.locura_level(), options.size() - 1)]


func _iglesia() -> void:
	var h := TimeManager.hour()
	if h < 6 or h >= 20:
		await Dialogue.talk([["", "(Cerrada.)"]])
		return
	var ig_opts := ["Sentarse un rato (1 hora)", "Prender una vela ($500)", "Nada"]
	if GameState.flags.get("agente_aviso", false) and not GameState.flags.get("testigo", false):
		ig_opts.push_front("El de la última banca")
	var i := await Dialogue.talk([["", "(La puerta está abierta. Adentro hace fresco y huele a cera.)"]], ig_opts)
	if ig_opts[i] == "El de la última banca":
		await _agente()
		return
	if ig_opts.size() == 4:
		i -= 1
	match i:
		0:
			TimeManager.skip(1.0)
			GameState.change_mood(6.0)
			GameState.add_locura(1)
			await Dialogue.talk(_by_locura([
				[["", "(Se sienta en la última banca. Nadie le pide que se vaya.)"],
					["ÉL", "Primer lugar en la ciudad donde nadie me pide que me vaya. Y es la casa de alguien que tampoco habla."]],
				[["", "(Se queda mirando a San Judas. Mucho rato. Mueve los labios, sin sonido.)"],
					["ÉL", "San Judas, patrono de las causas perdidas. Colega."],
					["BEATA", "—¿Está rezando o le está hablando al santo? ... No me conteste. Mejor no me conteste."]],
				[["", "(Le hace una venia a San Judas. Espera. Se ríe solo, bajito.)"],
					["ÉL", "Me dijo que el de la tercera banca no se ha confesado desde el Mundial del noventa. Tiene buen humor, el santo. Nadie lo sabe."],
					["", "(Una señora se cambia de banca.)"]],
			]))
		1:
			if GameState.money < 500:
				await Dialogue.talk([["", "(No le alcanza para la vela.)"]])
				return
			GameState.add_money(-500)
			GameState.change_mood(4.0)
			await Dialogue.talk([
				["", "(Prende una vela. Por Victoria. La mira hasta que se le secan los ojos.)"],
				["ÉL", "Quinientos pesos la vela. Dura cuarenta minutos. Doce pesos con cincuenta el minuto de fe. Lo he pagado más caro."],
			])


func _padre() -> void:
	await _friend("padre")
	var fp := GameState.flags
	if fp.get("m_el_resuelto", false) and not fp.get("agente_aviso", false):
		fp["agente_aviso"] = true
		await Dialogue.talk([["PADRE HERNANDO", "—Hijo. Hay alguien que quiere hablar con usted. Un policía. Viene a la iglesia y se sienta en la última banca."],
			["PADRE HERNANDO", "—Dice que estuvo en un operativo. Que no duerme bien desde entonces. Yo no le pregunté más. El secreto de confesión también aplica a lo que uno no quiere saber."],
			["ÉL", "Un policía que no duerme. Por fin alguien en este caso con el mismo horario que yo."]])
		return
	var h := TimeManager.hour()
	if _job_today("padre"):
		await Dialogue.talk([["PADRE HERNANDO", "—Ya me ayudó hoy, hijo. Vaya, descanse. El descanso también es oración. La única que Dios contesta siempre."]])
		return
	if h < 7 or h >= 12:
		await Dialogue.talk([["PADRE HERNANDO", "—Venga por la mañana y me ayuda con el atrio. Por la tarde confieso. Y usted, hijo, tiene cara de confesión de dos horas. Esas las agendo."]])
		return
	var i := await Dialogue.talk([["PADRE HERNANDO", "—¿Me ayuda? Las bancas no se limpian solas. Le pedí un milagro al Señor y me mandó a usted. El Señor tiene un presupuesto apretado."]],
		["Barrer y limpiar (2 horas)", "Otro día"])
	if i != 0:
		return
	_job_done("padre")
	TimeManager.skip(2.0)
	GameState.set_hunger(GameState.hunger - 10.0)
	GameState.add_money(6000)
	if GameState.has_space_for("pan"):
		GameState.add_item("pan")
	GameState.change_mood(4.0)
	await Dialogue.talk([
		["", "(Barre el atrio. Dos horas. Encuentra: tres colillas, una estampita de otro santo, un diente.)"],
		["ÉL", "Un diente. En el atrio. Nadie va a reclamar un diente en una iglesia. Ni el dueño. Sobre todo el dueño."],
		["PADRE HERNANDO", "—Tome. Seis mil y un pan. No le pregunto en qué se los gasta. San Pablo trabajaba haciendo carpas y nadie le preguntaba."],
		["PADRE HERNANDO", "—Usted es el único que viene a la iglesia y no le pide nada a nadie. Ni a mí ni a Él. Eso me preocupa más que los que piden."],
	])


func _fabiola() -> void:
	await _friend("fabiola")
	var h := TimeManager.hour()
	if h < 11 or h >= 14:
		await Dialogue.talk([["DOÑA FABIOLA", "—La olla es de once a dos, mijo. Fuera de ese horario el hambre es problema de cada quien. Y la mía es de las dos y cuarto."]])
		return
	var opts := []
	if not _job_today("plato"):
		opts.append("Hacer la fila")
	if not _job_today("fabiola"):
		opts.append("Ayudar a servir (1 hora)")
	opts.append("Nada")
	var i := await Dialogue.talk([["DOÑA FABIOLA", "—Fila, mijo. Aquí el que se cuela come de último. El que se cuela dos veces, no come. Hay reglamento."]], opts)
	match opts[i]:
		"Hacer la fila":
			_job_done("plato")
			GameState.set_hunger(GameState.hunger + 45.0)
			GameState.change_mood(3.0)
			await Dialogue.talk([["DOÑA FABIOLA", "—Sopa de verduras. Hoy tiene ahuyama, papa, zanahoria y un hueso que ya pasó por tres ollas. Tiene experiencia, el hueso."],
				["ÉL", "Mejor sopa que he comido en un año. No es mucho decir. Pero tampoco es poco."]])
		"Ayudar a servir (1 hora)":
			_job_done("fabiola")
			_job_done("plato")
			TimeManager.skip(1.0)
			GameState.add_money(3000)
			GameState.set_hunger(GameState.hunger + 45.0)
			GameState.change_mood(5.0)
			await Dialogue.talk([
				["", "(Sirve sopa a cuarenta personas. Ninguna lo mira a la cara. Él tampoco.)"],
				["ÉL", "Cuarenta platos. Doce zapatos sin cordones, nueve chaquetas de otro, tres anillos de matrimonio sin matrimonio. Uno tiene corbata. Lo saludo con la cabeza. Gremio."],
				["DOÑA FABIOLA", "—Tome lo suyo. Tres mil, y su plato. Y un hueso para el perro, que también hizo fila. Y no se coló. Más de lo que puedo decir de algunos."],
			])


func _aurelio() -> void:
	await _friend("aurelio")
	var h := TimeManager.hour()
	if _job_today("aurelio"):
		await Dialogue.talk([["DON AURELIO", "—Mañana llega otro camión. Y otro. Esto no se acaba. Como la deuda con el proveedor, que va en cuatro millones trescientos."]])
		return
	if h < 7 or h >= 11:
		await Dialogue.talk([["DON AURELIO", "—El camión llega a las siete. Si quiere camello, antes de las once. Después de las once solo vendo, y vendiendo no le pago a nadie. Me pagan."]])
		return
	var hours := 1.5 if GameState.has_skill("paso_firme") else 2.0
	var i := await Dialogue.talk([["DON AURELIO", "—Llegó el camión. Cuarenta bultos de arroz Diana. Le pago ocho mil. Si se le cae uno, se lo cobro. A precio de venta, no de compra."]],
		["Descargar (%s horas)" % ("1,5" if hours < 2.0 else "2"), "No"])
	if i != 0:
		return
	_job_done("aurelio")
	TimeManager.skip(hours)
	GameState.set_hunger(GameState.hunger - 15.0)
	GameState.add_money(8000)
	await Dialogue.talk([
		["", "(Cuarenta bultos de arroz. No para. No suda. No dice nada.)"],
		["DON AURELIO", "—Ocho mil. Usted trabaja como si alguien lo estuviera persiguiendo."],
		["", "(Mira para atrás.)"],
		["ÉL", "Nadie. Calle vacía. Un perro, una moto parqueada, una señora con un mercado. Nadie. Lo reviso igual. Siempre lo reviso igual."],
		["DON AURELIO", "—... Bueno. Vuelva mañana. Y no mire así para atrás, que me pone nervioso. Yo tengo deudas, y las deudas también persiguen."],
	])


func _leonor() -> void:
	await _friend("leonor")
	var h := TimeManager.hour()
	if h < 8 or h >= 18:
		await Dialogue.talk([["", "(El carrito de flores está tapado con un plástico. Como un muerto en la calle.)"], ["ÉL", "Mala comparación. Muy específica. No sé de dónde la saqué."]])
		return
	var opts := []
	if not _job_today("leonor"):
		opts.append("Ayudar con los ramos (1 hora)")
	opts.append("Comprar una flor")
	opts.append("Nada")
	var i := await Dialogue.talk([["DOÑA LEONOR", "—Flores para el amor, para el perdón y para el muerto. Son las mismas. Lo que cambia es la cinta. Y el precio, el del muerto es más caro. El muerto no regatea."]], opts)
	match opts[i]:
		"Ayudar con los ramos (1 hora)":
			_job_done("leonor")
			TimeManager.skip(1.0)
			GameState.add_money(3000)
			GameState.change_mood(4.0)
			await Dialogue.talk([
				["", "(Arma un ramo de matrimonio, uno de cumpleaños y tres de entierro.)"],
				["DOÑA LEONOR", "—Los de entierro le quedan mejor. Muy bien amarrados. Como quien ya ha ido a varios."],
				["ÉL", "A tres. Uno de verdad. Dos en los que yo era el que no estaba."],
				["DOÑA LEONOR", "—Tome, tres mil. Usted tiene manos de florista. Y cara de entierro, pero eso se le quita. A mí se me quitó a los setenta."],
			])
		"Comprar una flor":
			await _buy("flor", 1000, "DOÑA LEONOR", "—Un clavel. Rojo. El blanco es para pedir perdón y usted no tiene cara de pedir perdón. ¿Para quién es?")
			if GameState.count("flor") > 0:
				await Dialogue.talk([["", "(...)"], ["DOÑA LEONOR", "—¿No sabe? ¿O no me quiere decir? ... Las dos cosas. Llévelo igual. Los claveles saben solos para quién son."],
					["ÉL", "Sé para quién es. Tiene once años; doce el 29 de octubre. Le gustan los girasoles. No había girasoles."]])


func _efrain() -> void:
	await _friend("efrain")
	var opts := ["Ver qué vende"]
	if not _job_today("efrain"):
		opts.append("Cuidarle el puesto (2 horas)")
	opts.append("Nada")
	var i := await Dialogue.talk([["DON EFRAIN", "—Todo tiene historia, mijo. Yo le vendo la historia. El objeto se lo regalo. Hoy la historia está en promoción."]], opts)
	match opts[i]:
		"Ver qué vende":
			GameState.add_locura(1)
			await _shop("DON EFRAIN", SHOP_EFRAIN)
		"Cuidarle el puesto (2 horas)":
			_job_done("efrain")
			TimeManager.skip(2.0)
			GameState.add_money(4000)
			GameState.add_locura(1)
			var gift: String = ["reloj_sin_agujas", "estampita", "muneca", "dentadura", "casete"].pick_random()
			var got := GameState.has_space_for(gift)
			if got:
				GameState.add_item(gift)
			await Dialogue.talk([
				["", "(Cuida el puesto dos horas. No vende nada.)"],
				["SEÑORA", "—¿La muñeca está a la venta o es suya? ... ¿Señor? ... ¿Es suya? Ay, Dios mío. Perdón."],
				["ÉL", "Gloria no está a la venta. Gloria opina que la señora tiene cara de no cuidar las cosas. Gloria es muy directa."],
				["DON EFRAIN", "—Cuatro mil. Y llévese algo: a usted las cosas le hablan. Lo vi. Yo también las oigo, pero yo ya no les contesto. Me metí en problemas con un reloj."],
				["", "(%s.)" % Items.info(gift)["name"] if got else "(No le cabe nada más en la mochila.)"],
			])


func _mono() -> void:
	await _friend("mono")
	var h := TimeManager.hour()
	if h < 9 or h >= 19:
		await Dialogue.talk([["", "(La glorieta, vacía.)"]])
		return
	var i := await Dialogue.talk([["EL MONO", "—¿Le toco una? Las tristes me salen mejor. Tres divorcios de práctica. Y un perro que se me fue con el vecino."]],
		["Escuchar (1 hora)", "Darle $500", "Nada"])
	match i:
		0:
			TimeManager.skip(1.0)
			GameState.change_mood(8.0)
			GameState.add_locura(1)
			await Dialogue.talk(_by_locura([
				[["", "(Una hora de boleros mal tocados.)"],
					["EL MONO", "—¿Sabe por qué los boleros tienen tres minutos? Porque el despecho de verdad dura tres minutos. Lo demás es orgullo."],
					["EL MONO", "—Lo leí en una servilleta de una cantina en Girardot. La había escrito yo. Borracho. Pero tenía razón."]],
				[["", "(Una de despecho. Él mueve los labios con el coro. Sin sonido.)"],
					["ÉL", "Me la sé. Sonaba en un carro. Un carro con olor a ambientador de vainilla y alguien al lado. No me acuerdo de la cara. Me acuerdo de la vainilla."],
					["EL MONO", "—¿Se la sabe? ¡Cántela, hombre! ... No. Bueno. Yo la canto por los dos. Desafinado por los dos."]],
				[["", "(Una hora entera. Él no se mueve. Al final tiene la cara mojada.)"],
					["EL MONO", "—¿Le gustó? Es un bolero viejito, de los setenta."],
					["", "(...)"],
					["EL MONO", "—Ya. Ya. No me diga nada. Nadie me había llorado un bolero sin decirme nada. Es lo más bonito que me han dicho."],
					["ÉL", "No estaba llorando. El bolero me estaba llorando a mí. Es distinto. El Mono no entendería. El bolero sí."]],
			]))
		1:
			if GameState.money < 500:
				await Dialogue.talk([["EL MONO", "—Tranquilo, colega. Entre artistas no se cobra. Entre artistas se presta y no se devuelve."]])
				return
			GameState.add_money(-500)
			GameState.change_mood(2.0)
			await Dialogue.talk([["EL MONO", "—Quinientos. Gracias, hermano. Con esto ya llevo para las cuerdas. La sol. La sol siempre se revienta primero."],
				["EL MONO", "—Esta va por usted. Se llama \"El que no habla\". La acabo de inventar. Rima con \"el que no se calla\", que soy yo."]])


func _viejos() -> void:
	await Dialogue.talk([
		["DON OCTAVIO", "—Siéntese, pero no opine. El último que opinó se murió."],
		["DON RAMIRO", "—De viejo, Octavio. Se murió de viejo."],
		["DON OCTAVIO", "—Opinando."],
		["DON RAMIRO", "—Tenía noventa y dos años."],
		["DON OCTAVIO", "—Noventa y dos años opinando. Eso mata a cualquiera."],
	])
	var opts := ["Mirar (media hora)"]
	if GameState.money >= 1000:
		opts.append("Apostar $1000 a Don Ramiro")
	opts.append("Nada")
	var i := await Dialogue.talk([["DON RAMIRO", "—Este sí es buen público, Octavio. Mire cómo mira el tablero. Ese ve tres jugadas."],
		["DON OCTAVIO", "—Ese ve el pan que usted tiene en el bolsillo, Ramiro."]], opts)
	match opts[i]:
		"Mirar (media hora)":
			TimeManager.skip(0.5)
			GameState.change_mood(3.0)
			await Dialogue.talk([["DON OCTAVIO", "—Treinta años jugando. Ramiro abre siempre con el caballo del rey. Siempre. Treinta años."],
				["DON RAMIRO", "—Y treinta años usted sin saber qué hacer con eso."],
				["ÉL", "El alfil de Octavio lleva media hora amenazando a la dama. Nadie lo ve. Lo dejo así. A veces el que sabe se queda callado por cariño."]])
		"Apostar $1000 a Don Ramiro":
			TimeManager.skip(0.5)
			if randf() < (0.6 if GameState.has_skill("labia") else 0.45):  # labia = la mirada: Octavio se pone nervioso
				GameState.add_money(1000)
				await Dialogue.talk([["DON RAMIRO", "—¡Jaque mate, Octavio! ¡Treinta años esperando!"],
					["DON OCTAVIO", "—Fueron veintiocho."],
					["DON RAMIRO", "—¡Veintiocho años esperando!"],
					["DON OCTAVIO", "—Tome sus mil. Y deje de mirarme así, que me desconcentró. Eso es trampa. Trampa muda."]])
			else:
				GameState.add_money(-1000)
				await Dialogue.talk([["DON OCTAVIO", "—Mate. Treinta años y nunca aprende. El caballo del rey, Ramiro. Siempre el caballo del rey."],
					["DON RAMIRO", "—Perdimos, mijo. Mañana abro con otro."],
					["ÉL", "Va a abrir con el caballo del rey. Los dos lo saben. Por eso siguen viniendo."]])


func _banca() -> void:
	var i := await Dialogue.talk([["", "(Una banca verde.)"]], ["Sentarse (1 hora)", "Nada"])
	if i != 0:
		return
	TimeManager.skip(1.0)
	GameState.change_mood(3.0)
	GameState.add_locura(1)
	var lines: Array = _by_locura([
		[[["", "(Una pareja se besa en la banca de enfrente. Él y Lukas los miran fijo. Se van.)"],
				["ÉL", "Ella tenía la mano en el bolsillo de atrás de él. No por amor. Por la billetera. Le doy dos meses. A él, no a la relación."]],
			[["SEÑOR", "—¿Tiene la hora? ... ¿La hora? ... ¿Me escucha? ... Qué gente, por Dios."],
				["ÉL", "Las tres y diez. Lo sé por la sombra del poste. No se lo dije. La gente que pregunta la hora en realidad quiere hablar, y yo no doy ese servicio."]]],
		[[["", "(Cuenta las baldosas con el dedo. Las vuelve a contar. Las vuelve a contar.)"],
				["ÉL", "Ciento cuarenta y dos. Ayer eran ciento cuarenta. Alguien está poniendo baldosas de noche. Lo voy a averiguar."]],
			[["NIÑO", "—Mamá, ese señor está contando el piso."], ["MAMÁ", "—No lo mire, mijo. Camine."],
				["ÉL", "Ciento cuarenta y tres."]]],
		[[["", "(Se queda mirando la estatua. Asiente, como si la estatua hubiera dicho algo.)"],
				["ÉL", "Dice que el alcalde no le ha limpiado las palomas desde el 2011. Tiene razón. Se nota en el hombro."],
				["SEÑORA", "—¿Con quién habla ese? Si no dice nada. Peor."]],
			[["", "(Se duerme sentado. Se despierta. Mira la banca como si fuera otra.)"],
				["ÉL", "Esta banca era verde. Ahora es verde. Algo cambió. No sé qué. La banca tampoco me lo quiere decir."]]],
	])
	await Dialogue.talk(lines.pick_random())


# ---------------------------------------------------------------- Lo bueno del barrio
# Lo agradable de estar despierto (el Día 1 sobre todo): pescar, el atardecer en el puente, los
# pelados del fútbol, la banca y el columpio del parquecito, el perro del barrio. Cada una cuenta
# para "Lo bueno del barrio" (opcional): la vida de verdad también tiene cosas buenas.

const BUENO := ["pescar", "atardecer", "pelaos", "banca", "columpio", "perro"]


func bueno_count() -> int:
	var n := 0
	for b in BUENO:
		if GameState.flags.get("bueno_" + b, false):
			n += 1
	return n


func _bueno(id: String) -> void:
	var f := GameState.flags
	if f.get("bueno_" + id, false):
		return
	f["bueno_" + id] = true
	if bueno_count() < BUENO.size():
		Narrator.say("Lo bueno del barrio: %d de %d." % [bueno_count(), BUENO.size()])
	if bueno_count() >= BUENO.size() and GameState.is_active("lo_bueno"):
		GameState.complete_quest("lo_bueno")
		await Dialogue.talk([["ÉL", "Pesqué. Vi el atardecer. Tapé un penalti. Me mecí. Un perro me eligió. Nadie me pagó por nada de eso. Fue un buen día. No sabía que todavía se podía."]])
		GameState.change_mood(10.0)


func _pescar() -> void:
	var f := GameState.flags
	if not f.get("pesca_vista", false):
		f["pesca_vista"] = true
		await Dialogue.talk([["", "(En la orilla, amarrada a una piedra: una línea de nylon enrollada en una lata, un anzuelo y un balde azul. Un papel con letra torcida: \"PARA EL QUE LLEGUE. DEVUÉLVALA\".)"],
			["ÉL", "Alguien dejó una caña para cualquiera. En esta ciudad. Debe ser un fantasma. Uno bueno."]])
	var h := TimeManager.hour()
	if h >= 20 or h < 5:
		await Dialogue.talk([["", "(De noche el río es negro y suena más fuerte. Mejor de día.)"]])
		return
	var i := await Dialogue.talk([["", "(El río pasa lento, color café con leche. Huele a barro y a algo que fue un pescado.)"]],
		["Pescar un rato", "Seguir"])
	if i != 0:
		return
	if GameState.lukas_alive():
		await Dialogue.talk([["", "(Lukas se echa al lado del balde. Vigila el corcho como si fuera a robárselo alguien.)"]])
	var got: Array = await Pesca.fish(self)
	TimeManager.skip(0.33 * maxi(1, got.size()))
	var lines := []
	for g in got:
		match g:
			"pescado":
				if GameState.has_space_for("pescado"):
					GameState.add_item("pescado")
			"lata", "botella":
				if GameState.has_space_for(g):
					GameState.add_item(g)
			"bota":
				lines.append(["ÉL", "Una bota. La devuelvo al río. Era de alguien. Que la venga a buscar."])
	if "pescado" in got:
		lines.append(["ÉL", "Un bocachico. Lo saqué yo. Con un nylon, una lata y paciencia. Nadie me lo dio. Me lo gané. Hace rato no me ganaba nada."])
		if GameState.lukas_alive():
			lines.append(["", "(Lukas le huele el pescado y estornuda. Aprobado.)"])
	elif got.is_empty():
		return
	else:
		lines.append(["ÉL", "No picó nada que se coma. Pero estuve una hora sin pensar. Eso también se pesca."])
	GameState.change_mood(4.0)
	GameState.calm_until = maxf(GameState.calm_until, TimeManager.minutes + 60.0)
	await Dialogue.talk(lines)
	await _bueno("pescar")


func _atardecer() -> void:
	var h := TimeManager.hour()
	if h < 17 or h >= 19:
		await Dialogue.talk([["", "(Desde el puente se ve el río entero, y al fondo los cerros. A esta hora no tiene nada de especial.)"],
			["ÉL", "Samuel dice que al atardecer este puente es lo más bonito del barrio. Dice. Él dice muchas cosas. Pero esa se la creo."]])
		return
	var sky := CanvasLayer.new()
	sky.layer = 10
	var tint := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0.45, 0.25, 0.55, 0.45))
	grad.add_point(0.5, Color(0.98, 0.55, 0.25, 0.4))
	grad.set_color(1, Color(0.85, 0.3, 0.25, 0.25))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	tint.texture = tex
	tint.size = Vector2(320, 180)
	tint.stretch_mode = TextureRect.STRETCH_SCALE
	tint.modulate.a = 0.0
	sky.add_child(tint)
	get_tree().root.add_child(sky)
	create_tween().tween_property(tint, "modulate:a", 1.0, 1.5)
	var lines := [["", "(El sol se mete detrás de los cerros. El río se pone naranja, después rosado, después de un color que no tiene nombre.)"],
		["", "(Los carros siguen pasando por detrás. Nadie más se detiene. Él sí.)"],
		["ÉL", "Gratis. Esto es gratis. Lo único bonito de la ciudad que no cobra, y nadie lo mira."]]
	if GameState.lukas_alive():
		lines.append(["", "(Lukas se sienta a su lado, de cara al sol, con los ojos entrecerrados. Los dos igual de quietos.)"])
	if GameState.day >= 3:
		lines.append(["ÉL", "A Victoria le gustaban los atardeceres. Decía que el sol se iba a dormir a otra casa. Ojalá tenga razón. Ojalá sea una casa buena."])
	await Dialogue.talk(lines)
	TimeManager.skip(maxf(0.0, 19.0 - TimeManager.minutes / 60.0))
	GameState.change_mood(8.0)
	GameState.company(5.0)
	var out := create_tween()
	out.tween_property(tint, "modulate:a", 0.0, 1.5)
	out.tween_callback(sky.queue_free)
	await _bueno("atardecer")


const PELAOS_SHOTS := [
	["EL CHINO", "—¡Este va al ángulo!"],
	["LA FLACA", "—¡Mire pa'l otro lado, señor!"],
	["BRAYAN", "—¡Rabona! ... No, normal. Rabona no me sale."],
	["EL CHINO", "—¡El último! ¡El que pierde compra gaseosa!"],
	["LA FLACA", "—¡Penalti a lo Panenka!"],
]


func _pelaos() -> void:
	var h := TimeManager.hour()
	if h < 9 or h >= 18:
		await Dialogue.talk([["", "(El lote está vacío. Quedaron los dos morrales que hacen de arco, olvidados. Mañana vuelven.)"]])
		return
	var f := GameState.flags
	var first: bool = not f.get("pelaos_jugo", false)
	var lines := [["", "(Tres pelados juegan fútbol en el lote, con dos morrales de arco y una pelota pelada.)"]]
	if first:
		lines.append(["EL CHINO", "—¡Señor! ¡Señor del saco! ¿Tapa? Nos falta arquero. El último se fue a almorzar hace dos años."])
		lines.append(["LA FLACA", "—No habla. Mejor. Los arqueros que hablan se creen Higuita."])
	else:
		lines.append(["BRAYAN", "—¡Volvió el arquero mudo! ¡El muro! ¡El muro sin boca!"])
	var i := await Dialogue.talk(lines, ["Tapar", "Ahora no"])
	if i != 0:
		return
	f["pelaos_jugo"] = true
	var saved := 0
	for k in 5:
		var shot: Array = PELAOS_SHOTS[k]
		var j := await Dialogue.talk([shot], ["Tirarse a la izquierda", "Quedarse en el medio", "Tirarse a la derecha"])
		var aim := randi() % 3
		if j == aim:
			saved += 1
			await Dialogue.talk([["", ["(¡La ataja! Con la panza, pero la ataja.)", "(¡La saca con la punta de los dedos!)",
				"(La pelota le pega en la cara y sale. Cuenta.)"].pick_random()]])
		else:
			await Dialogue.talk([["", ["(Gol. Por el otro lado. Él sigue tirado en el piso mirando el cielo.)", "(Gol. Por entre las piernas. Los pelados lo celebran como un Mundial.)",
				"(Gol. Le pasó por encima. Él no salta: ya no salta.)"].pick_random()]])
	var end := []
	if saved >= 3:
		end = [["EL CHINO", "—¡%d de 5! ¡Usted es una pared, señor! ¿Viene mañana?" % saved],
			["LA FLACA", "—Tome, le guardamos un bombón. No es gaseosa, pero es dulce."],
			["ÉL", "Me tiré al piso por unos pelados que no conozco y me dolió todo. Hace años no me dolía algo tan bonito."]]
		if GameState.has_space_for("bombon"):
			GameState.add_item("bombon")
	else:
		end = [["BRAYAN", "—%d de 5. Bueno, peor era nada. Peor era el portero de antes, que era una caneca." % saved],
			["ÉL", "Me metieron goles unos niños de nueve años. Y me reí. Por dentro, pero me reí. Cuenta."]]
	if GameState.lukas_alive():
		end.append(["", "(Lukas se roba la pelota y sale corriendo. Los tres pelados detrás. Nadie la recupera en diez minutos. Nadie quiere.)"])
	await Dialogue.talk(end)
	TimeManager.skip(1.0)
	GameState.change_mood(6.0)
	GameState.company(25.0)
	await _bueno("pelaos")


const BANCA_VIEW := [
	[["", "(Una señora barre el andén de su casa, después el de la vecina, después el de la otra. Llega hasta la esquina barriendo.)"],
		["ÉL", "Empezó por lo suyo y terminó barriendo la cuadra. Así debería funcionar todo."]],
	[["", "(Un señor en bicicleta lleva un colchón amarrado a la espalda. Pedalea muy despacio y muy digno.)"],
		["ÉL", "Se está mudando en bicicleta. Con toda la dignidad del mundo. Le aplaudiría si supiera aplaudir sin que me miren."]],
	[["", "(Dos viejitos discuten de fútbol en la tienda. Uno grita, el otro le da la razón para que se calle. Siguen así una hora.)"],
		["ÉL", "Se quieren. Se nota en lo mal que se escuchan."]],
	[["", "(Una niña le enseña a leer a su hermanito con el aviso de la droguería: \"DRO-GUE-RÍ-A\". Él lo repite mal. Ella se ríe. Él también.)"],
		["ÉL", "Así aprende uno: equivocándose delante de alguien que lo quiere."]],
	[["", "(Pasa el carrito de los helados con su musiquita. Nadie compra. La musiquita sigue, contenta, como si nada.)"],
		["ÉL", "Esa musiquita no se rinde. Le voy a copiar la actitud."]],
]


func _banca_parquecito() -> void:
	var f := GameState.flags
	var idx := int(f.get("banca_vista", 0))
	f["banca_vista"] = idx + 1
	var view: Array = BANCA_VIEW[idx % BANCA_VIEW.size()]
	var i := await Dialogue.talk([["", "(Una banca vieja en el parquecito. Se sienta. Desde acá se ve medio barrio.)"]] + view,
		["Quedarse un rato (1 hora)", "Seguir"])
	if i != 0:
		return
	TimeManager.skip(1.0)
	GameState.change_mood(3.0)
	GameState.company(5.0)
	var lines := [["", "(Pasa una hora. Nadie lo echa. En el parquecito no hay vigilante: es de todos y de nadie.)"]]
	if GameState.lukas_alive():
		lines.append(["", "(Lukas duerme debajo de la banca, con una oreja afuera por si acaso.)"])
	await Dialogue.talk(lines)
	await _bueno("banca")


func _columpio() -> void:
	var f := GameState.flags
	var first: bool = not f.get("columpio", false)
	f["columpio"] = true
	var lines := [["", "(Un columpio de cadena oxidada. El asiento es una tabla. Se sienta. Cruje, pero aguanta.)"]]
	if first:
		lines += [["", "(Se impulsa con los pies. Una vez. Dos. A la tercera, el estómago se le sube como cuando era niño.)"],
			["ÉL", "La última vez que me subí a un columpio tenía ocho años y mi papá me empujaba. Bueno, me empujó tres veces y se fue a comprar cigarrillos."],
			["ÉL", "Volvió. Esa vez sí volvió. Me acuerdo porque fue la única."]]
	else:
		lines += [["", ["(Se mece despacio. Las cadenas suenan como una canción que nadie terminó.)",
			"(Se mece. Un pelado pasa y lo mira raro. Él se mece más alto.)",
			"(Se mece con los ojos cerrados. Por un rato no es nadie. Es descansado no ser nadie.)"].pick_random()]]
	if GameState.lukas_alive():
		lines.append(["", "(Lukas le ladra al columpio cada vez que va para adelante. Cada vez. No se cansa.)"])
	await Dialogue.talk(lines)
	TimeManager.skip(0.5)
	GameState.change_mood(4.0)
	await _bueno("columpio")


func _perro_barrio() -> void:
	var f := GameState.flags
	var name: String = f.get("perro_barrio_nombre", "")
	if name == "":
		var lines := [["", "(Un perro flaco, color canela, con una oreja parada y la otra no. Es de la cuadra: de todos y de nadie.)"]]
		if GameState.lukas_alive():
			lines += [["", "(Lukas y el perro se huelen. Por todos lados. Mucho rato. Es su forma de leerse el currículum.)"],
				["", "(El perro canela mueve la cola. Lukas también. Contratados.)"]]
		var i := await Dialogue.talk(lines + [["ÉL", "No tiene nombre. Nadie le puso. Le puedo poner uno. Es lo único que puedo regalar."]],
			["Canelo", "Mechas", "Firulais (no, eso no)", "Don Perro"])
		name = ["Canelo", "Mechas", "Firulais", "Don Perro"][i]
		f["perro_barrio_nombre"] = name
		var tail := "(Le dice %s. El perro no reacciona. Se lo dice otra vez. Mueve la cola. Ya está: se llama %s.)" % [name, name]
		if name == "Firulais":
			tail = "(Le dice Firulais. El perro lo mira con lástima. Pero mueve la cola. Se queda Firulais.)"
		await Dialogue.talk([["", tail]])
	else:
		var lines := [["", ["(%s le pone la cabeza en la rodilla. Huele a calle, a lluvia, a perro feliz.)" % name,
			"(%s le trae un palo. No se lo suelta. El juego es ese: no soltarlo.)" % name,
			"(%s se le echa a los pies, panza arriba. Exige. Él obedece.)" % name].pick_random()]]
		if GameState.lukas_alive():
			lines.append(["", "(Lukas y %s se persiguen alrededor de un poste. Gana el poste.)" % name])
		await Dialogue.talk(lines)
	GameState.change_mood(4.0)
	GameState.company(10.0)
	GameState.calm_until = maxf(GameState.calm_until, TimeManager.minutes + 45.0)
	await _bueno("perro")


# ---------------------------------------------------------------- La vitrina de TV RADIO (ver tele desde la calle)

## Lo que dan según la hora (sin sonido: se ve desde la vereda, a través del vidrio).
const TV_SHOWS := {
	"mañana": [
		[["", "(Un programa de la mañana. Una señora sonríe demasiado y le enseña a otra a hacer arroz con pollo en cuatro minutos.)"],
			["ÉL", "Sin sonido, la receta es más honesta: echa cosas, revuelve, sonríe. Así cocino yo. Menos la parte de la olla."]],
		[["", "(El horóscopo. Una mujer de turbante señala un cartel de Géminis con mucha seriedad.)"],
			["ÉL", "Lorena debe estar viendo esto. Está anotando cuánto le debo según Mercurio."]],
		[["", "(Aeróbicos. Cinco personas en licra saltan en un set que parece una piscina sin agua.)"],
			["ÉL", "Saltan para quemar calorías. Yo las quemo de otra manera: no comiéndolas. Es más barato y nadie lo transmite."]],
	],
	"noticias": [
		[["", "(El noticiero. Un señor de corbata habla con cara de que se murió alguien. Abajo, en rojo: ÚLTIMA HORA.)"],
			["ÉL", "Siempre es última hora. Nunca es la penúltima. Uno nunca se entera de la penúltima."]],
		[["", "(Noticias. Muestran un trancón de dos horas. Muestran un perro que se subió solo a un bus. Muestran el dólar.)"],
			["ÉL", "El perro del bus tuvo más cobertura que yo en toda mi vida. Bien por él. Se veía decidido."]],
		[["", "(Noticias. Un experto en algo habla delante de una biblioteca. Abajo dice: \"LA ECONOMÍA CRECE\".)"],
			["ÉL", "Crece. No dicen para dónde. A esta cuadra no ha llegado. Debe venir en bus, con el perro."]],
	],
	"novela": [
		[["", "(Una telenovela. Una mujer le tira un vaso de agua en la cara a un hombre. El hombre no reacciona. Ella llora.)"],
			["ÉL", "Sin sonido se entiende todo: ella lo quiere, él tiene un gemelo, alguien es hija de alguien. En el capítulo cien se casan todos."]],
		[["", "(La telenovela. La villana: pelo largo y negro, moño rosado, boca pintada. Grita por teléfono.)"],
			["ÉL", "Se parece a Lorena. No: Lorena grita más, y sin guion. Esta por lo menos tiene guionistas."]],
		[["", "(La telenovela. Un señor despierta de un coma de veinte años y lo primero que hace es preguntar por la herencia.)"],
			["ÉL", "Veinte años en coma y se despierta con las prioridades claras. Yo llevo semanas despierto y todavía no sé las mías."]],
	],
	# La Fórmula 1: los domingos en la mañana (en vivo) y a veces la repetición en la tarde.
	"f1": [
		[["", "(Fórmula 1. Veinte carros dando vueltas a la misma pista. Uno se sale y los señores de la vereda dicen \"¡uy!\" al tiempo.)"],
			["ÉL", "Dan vueltas y vueltas para llegar al mismo lugar del que salieron. Yo hago lo mismo todos los días, pero a pie y sin patrocinio."]],
		[["", "(Fórmula 1. Una parada en pits: cuatro llantas en dos segundos. Veinte mecánicos para un solo carro.)"],
			["ÉL", "Dos segundos. La Registraduría me cambia un papel en tres semanas. Debería mandar la cédula con esos mecánicos."]],
		[["", "(Fórmula 1. Llueve en la pista. Un carro da un trompo, queda mirando para atrás, y sigue como si nada.)"],
			["ÉL", "Dio un trompo y siguió. Sin mirar atrás. Ese tipo no necesita terapia. O sí, pero no lo dejan parar."]],
		[["", "(Fórmula 1. En el podio, tres pilotos se bañan en champaña. Botan la botella entera.)"],
			["ÉL", "La botan. Entera. Wilson me paga doscientos pesos por esa botella vacía. Ellos no saben lo que tienen."]],
		[["", "(Fórmula 1. Un señor de la vereda le explica a otro qué es el DRS. El otro asiente. Ninguno de los dos sabe.)"],
			["ÉL", "Yo tampoco sé qué es el DRS. Pero asiento. Así funciona la amistad entre hombres: asentir juntos frente a algo que no entendemos."]],
	],
	"futbol": [
		[["", "(Fútbol. Se juntan tres señores y un muchacho en la vereda. Gol. Los cuatro gritan. Él no grita, pero levanta un brazo.)"],
			["ÉL", "Un gol. Por un segundo, cinco desconocidos frente a una vitrina somos un equipo. Después cada uno vuelve a lo suyo. Yo vuelvo al poste."]],
		[["", "(Fútbol. Penalti. El arquero adivina el lado. La cuadra entera dice \"uuuh\". Un señor le pasa la gaseosa sin mirarlo.)"],
			["ÉL", "Me pasó la gaseosa. Sin preguntar nada. El fútbol es la única religión que no pide el diezmo."]],
		[["", "(Fútbol. Pierde el equipo de todos. Un señor patea un poste. El poste gana.)"],
			["ÉL", "Perder en grupo duele menos. Lo dice la ciencia. Bueno, lo digo yo, que estoy en el grupo."]],
	],
}
const TV_OWNER := [
	["DON JAIRO", "—Hermano, esto no es cine. ... Bueno, quédese. Pero no se me recueste en el vidrio, que lo acabé de limpiar."],
	["DON JAIRO", "—¿Va a comprar el televisor? ... Ya sé que no. Pregunto para que se sienta incluido."],
	["DON JAIRO", "—Si se va a quedar, por lo menos ponga cara de cliente. Así, no. Esa es cara de testigo."],
]


## Ver tele desde la calle: el tiempo pasa más rápido, y un poco de ánimo (hasta 6 por día).
func _vitrina_tv() -> void:
	var h := TimeManager.hour()
	if h < 8 or h >= 20:
		await Dialogue.talk([["", "(La reja está abajo. En el vidrio de atrás se ve su reflejo.)"],
			["ÉL", "El único programa que dan a esta hora. Mala actuación, poco presupuesto. Lo cancelan pronto."]])
		return
	var band := "mañana" if h < 12 else ("noticias" if h < 14 else ("novela" if h < 18 else "futbol"))
	if (GameState.day % 7 == 0 and h < 12) or (band == "futbol" and randf() < 0.3):
		band = "f1"  # domingo en la mañana, en vivo; en la tarde, la repetición
	var show: Array = TV_SHOWS[band].pick_random()
	var i := await Dialogue.talk([["", "(La vitrina de TV RADIO: nueve televisores, el mismo canal, sin sonido.)"]] + show,
		["Ver un rato (1 hora)", "Quedarse la tarde (3 horas)", "Seguir"])
	if i == 2:
		return
	var hours := 1.0 if i == 0 else 3.0
	if i == 1 and randf() < 0.35:
		await Dialogue.talk([TV_OWNER.pick_random()])
		hours = 2.0
	TimeManager.skip(hours)
	if band in ["futbol", "f1"]:
		GameState.company(12.0)  # gritar un gol con desconocidos también es compañía
	var f := GameState.flags
	if int(f.get("tv_dia", -1)) != GameState.day:
		f["tv_dia"] = GameState.day
		f["tv_animo"] = 0.0
	var gain := minf(2.0 * hours, 6.0 - float(f["tv_animo"]))
	if gain > 0.0:
		f["tv_animo"] = float(f["tv_animo"]) + gain
		GameState.change_mood(gain)
	var end: String = ["(Pasa el tiempo. Eso era lo que había que hacer con él.)",
		"(Se le duermen las piernas. El tiempo, en cambio, se fue rapidito.)",
		"(Cuando mira el reloj de la vitrina, ya pasó. Eso es lo bueno de la tele: se come las horas y no deja platos.)"].pick_random()
	var lines := [["", end]]
	if GameState.lukas_alive():
		lines.push_front(["", "(Lukas se echa a sus pies y se duerme. A Lukas la tele le da igual: él ve todo en olores.)"])
	await Dialogue.talk(lines)


func _palomas() -> void:
	var opts := ["Mirarlas (media hora)"]
	if GameState.count("pan") > 0:
		opts.push_front("Darles pan")
	opts.append("Nada")
	var i := await Dialogue.talk([["", "(Palomas.)"]], opts)
	match opts[i]:
		"Darles pan":
			GameState.remove_item("pan")
			GameState.change_mood(5.0)
			await Dialogue.talk([["", "(Les tira el pan. Se matan por las migas. Él las mira sin parpadear.)"],
				["ÉL", "Igualito que en la oficina cuando sobraba torta de un cumpleaños. La gorda se queda con todo. Siempre hay una gorda. Siempre se llama Nicolás."]])
		"Mirarlas (media hora)":
			TimeManager.skip(0.5)
			GameState.add_locura(1)
			await Dialogue.talk(_by_locura([
				[["", "(Una cojea. Las otras no la esperan.)"], ["ÉL", "Yo la esperaría. Pero no soy paloma. Todavía."]],
				[["", "(Le hace una venia a la paloma más gorda. La paloma no le devuelve el saludo.)"],
					["ÉL", "Grosera. Las palomas del centro son más educadas. Estas son de parque, se creen mejores."]],
				[["", "(Se agacha y les habla. Sin sonido. Las palomas lo escuchan más que la gente.)"],
					["ÉL", "Les expliqué lo de Victoria. La gris entendió. La blanca no estaba de acuerdo con la Defensoría. Tiene sus razones."],
					["SEÑOR", "—Uy, el loco de las palomas. Y mudo. Combo completo."]],
			]))


## Los buses: del barrio, del centro y del parque, a cualquiera de los otros dos.
func _bus_from(here: String) -> void:
	var dests := []
	for d in [["barrio", CITY_SCENE], ["centro", CENTRO], ["parque", PARQUE]]:
		if d[0] == here:
			continue
		if d[0] == "centro" and not GameState.flags.get("centro_open", false):
			continue
		dests.append(d)
	var opts := []
	for d in dests:
		opts.append("Bus al %s ($%d)" % [d[0], PRICE_BUS])
		opts.append("Caminar al %s (1 hora)" % d[0])
	opts.append("Nada")
	var i := await Dialogue.talk([["", "(Paradero.)"]], opts)
	if i >= dests.size() * 2:
		return
	var d: Array = dests[i / 2]
	if i % 2 == 0:
		if GameState.money < PRICE_BUS:
			await Dialogue.talk([["CONDUCTOR", "—Dos mil quinientos. ¿No tiene? ¿Y me va a mirar así hasta que se los regale? Bájese."]])
			return
		GameState.add_money(-PRICE_BUS)
		TimeManager.skip(0.33)
	else:
		TimeManager.skip(1.0)
	var walk_line := "Una hora caminando."
	SceneRouter.go(d[1], "FromBus", "", walk_line if i % 2 == 1 else "")


# ---------------------------------------------------------------- Los que lo conocen
# La gente con la que trata todos los días lo quiere: le avisan cosas, le siguen el humor negro, y
# cuando la calle dice "es él", ellos no preguntan. Una línea por persona por día.

const FRIEND_LINES := {
	"german": [
		"—Mijo, hoy anda la policía pidiendo papeles en la plaza. Camine como si fuera a trabajar. Con prisa y con cara de que le deben plata.",
		"—La gente habla de usted. Yo no les paro bolas. La gente también hablaba de la Mercedes, que porque se reía muy duro. Se reía muy duro. ¿Y qué?",
		"—¿Durmió? Tiene cara de haber peleado con el colchón. Y perdido. Y el colchón ni siquiera era suyo.",
	],
	"marta": [
		"—Te ves horrible. Me gusta: los de buena presencia piden factura electrónica.",
		"—Mi hijo te vio ayer y me preguntó si eras un superhéroe. Por la corbata. Le dije que sí. Que tu poder es no decir nada. Le pareció un poder malísimo.",
		"—Anoche alguien preguntó por vos. Un man de chaqueta. Le dije que no te conocía. Me caés bien, pero no al nivel de mentirle a uno de chaqueta.",
	],
	"rosa": [
		"—Mijito, no se siente hoy en la esquina de la iglesia. Pasa el de negro. Los martes pasa el de negro. Los martes yo rezo más.",
		"—¿Otra vez con esa cara? Tome, huela una empanada. Eso cura de todo menos de la pobreza y el azúcar.",
		"—No escuche lo que dice la gente, mijito. La gente habla de lo que no sabe. Yo sé, y me callo. Por eso vendo empanadas y no chismes. Los chismes no dan.",
	],
	"wilson": [
		"—Parce, no duerma cerca de las bodegas esta semana. Andan unos raros. Raros de los que cobran, no de los que cantan.",
		"—Usted y yo vivimos de lo que los demás botan. Somos ecologistas, parce. En Europa nos darían un premio. Aquí nos dan doscientos ochenta la lata.",
		"—Si alguien le pregunta por mí, usted no me conoce. Le debo plata a un man de la 30. Bueno, a dos.",
	],
	"samuel": [
		"—Anoche vi a uno rondando su cambuche. Le silbé. Se fue. Silbo bonito. Es lo único que me quedó de la banda del colegio.",
		"—Se le ve todo en la cara, compa. Un día de estos va a reventar. Avíseme antes. Para estar lejos. O cerca. Todavía no decido.",
		"—La calle dice cosas de usted. La calle también dice cosas de mí. La calle es una vieja chismosa con muy buena memoria y muy mala ortografía.",
	],
	"padre": [
		"—Hijo, hoy hay olla. Venga antes de que se acabe el caldo y empiece la caridad de palabra, que es la que no llena.",
		"—Anoche soñé con usted. No le voy a decir qué. Los curas también tenemos derecho a la reserva del sumario.",
		"—No sé qué dice la gente de usted. Y no quiero saber. Aquí se entra sin historia. La historia se deja en la puerta, con los zapatos mojados.",
	],
	"fabiola": [
		"—Le guardé el hueso grande, mijo. No le diga a nadie. Aquí hay celos. La señora del gorro morado mataría por ese hueso. Literal. Ha estado presa.",
		"—Usted es el único que no se queja de la sopa. Me preocupa, mijo. Quéjese un día. Yo le guardo la queja y la sirvo con arroz.",
	],
	"aurelio": [
		"—Hoy no cargue tanto. Tiene la espalda torcida. Un quiropráctico vale ochenta mil. Yo le pago ocho. Haga cuentas.",
		"—Si la policía pregunta, usted es mi sobrino. Uno feo. De Ibagué. Todos los de Ibagué son primos, nadie va a verificar.",
	],
	"leonor": [
		"—Las flores también se marchitan, y nadie les dice nada. Se les cambia el agua y ya. A usted alguien debería cambiarle el agua.",
		"—Le guardé un clavel medio caído. Como usted: medio caído pero rojo. Lo rojo aguanta más de lo que parece.",
	],
	"efrain": [
		"—Llegó una cosa nueva. Una caja de música sin bailarina. La bailarina se fue. Como todas. La música se quedó. Como siempre.",
		"—No compre la muñeca otra vez. Ya la vendí tres veces. Siempre vuelve. La última vez volvió sola. No me pregunte cómo. No sé. No quiero saber.",
	],
	"mono": [
		"—Le compuse una canción. Se llama \"El del perro\". Es un éxito en la glorieta. Bueno, en la glorieta la escucharon dos palomas y un borracho. El borracho lloró.",
		"—Si un día no me ve acá, no pregunte. Los artistas desaparecemos. Es parte del show. A veces es la policía, pero también es parte del show.",
	],
}


## Lo que le dice hoy alguien que lo conoce (una vez por día; desde el Día 2).
func _friend(id: String) -> void:
	await _clue(id)
	var f := GameState.flags
	if GameState.day < 2 or f.get("friend_" + id, -1) == GameState.day or not FRIEND_LINES.has(id):
		return
	f["friend_" + id] = GameState.day
	var lines: Array = FRIEND_LINES[id]
	var who: String = {"german": "DON GERMAN", "marta": "MARTA", "rosa": "DOÑA ROSA", "wilson": "WILSON", "samuel": "SAMUEL",
		"padre": "PADRE HERNANDO", "fabiola": "DOÑA FABIOLA", "aurelio": "DON AURELIO", "leonor": "DOÑA LEONOR",
		"efrain": "DON EFRAIN", "mono": "EL MONO"}[id]
	await Dialogue.talk([[who, lines[GameState.day % lines.size()]]])


# ---------------------------------------------------------------- Victoria
# Sin chistes en lo de ella: el narrador en tercera persona, cuando hace falta. Él intenta, no le sale.

const GIFTS := {
	"flor": "(Deja el clavel en la reja, metido entre dos barrotes.)",
	"pelota_trapo": "(Deja la pelota de trapo en la reja. Lukas la mira irse.)",
	"estampita": "(Deja la estampita de San Judas en la reja.)",
	"muneca": "(Deja a Gloria, la muñeca sin un ojo, sentada en la reja.)",
	"casete": "(Deja el casete de boleros en la reja. Lado B.)",
}


func _kid_here() -> bool:
	return get_tree().current_scene.find_child("Victoria", true, false) != null


func _lilato_here() -> bool:
	return get_tree().current_scene.find_child("LilatoMadre", true, false) != null


func _v_bond(n: int) -> void:
	var f := GameState.flags
	f["victoria"] = clampi(int(f.get("victoria", 0)) + n, 0, 5)


## La reja del colegio.
func _colegio() -> void:
	var f := GameState.flags
	var day := GameState.day
	if day >= 45 and _kid_here() and not f.get("cumple_hecho", false):
		await _cumpleanos(false)
		return
	# Lo que ella dejó en la reja (si él le dejó algo un día antes).
	if f.has("victoria_regalo_dia") and int(f["victoria_regalo_dia"]) < day:
		f.erase("victoria_regalo_dia")
		if GameState.has_space_for("dibujo_victoria"):
			GameState.add_item("dibujo_victoria")
		_v_bond(1)
		await Dialogue.talk([
			["", "(En la reja, doblado en cuatro, hay un papel. Un dibujo de crayón.)"],
			["", "(Un señor de palitos con barba y corbata roja. Un perro café de orejas largas. Abajo dice: EL DEL PERRO.)"],
			["", "(Lo dobla otra vez, igual, en cuatro. Lo guarda. Le tiemblan las manos.)"],
			["ÉL", "La corbata me quedó bien. Le salió bien la corbata. Ella..."],
		])
	if not _kid_here():
		await Dialogue.talk([["", "(El colegio. Por la reja se ven dibujos pegados en las ventanas. Uno es un perro.)"],
			["CELADOR DEL COLEGIO", "—Salen a las doce, señor. Todos los días menos el domingo. Y no se pare tan pegado a la reja, que las mamás se asustan."],
			["CELADOR DEL COLEGIO", "—Y cuando las mamás se asustan, me llaman a mí. Y yo no sé hacer nada. Tengo un pito. Es todo lo que tengo."]])
		return
	if int(f.get("victoria_veda", -1)) > day and _lilato_here():
		GameState.change_mood(-2.0)
		await Dialogue.talk([["", "(Lorena está en la puerta, mirando para todos lados. Él se queda en la esquina. La mira irse.)"]])
		return
	if not f.get("victoria_vista", false):
		f["victoria_vista"] = true
		_v_bond(1)
		MusicDirector.force("")
		await Dialogue.talk([
			["", "(Doce y cuarto. Los niños salen en fila, gritando.)"],
			["", "(Ella sale de última. Mochila rosada. Una media más abajo que la otra.)"],
			["", "(Es la única cara que él ve. Las demás, nada.)"],
			["ÉL", "La última vez me llegaba a la rodilla. Ahora me llegaría a..."],
			["", "(No se mueve. Aprieta la reja hasta que se le ponen blancos los nudillos.)"],
		])
		MusicDirector.release()
	var opts := ["Mirarla de lejos", "Saludarla con la mano"]
	var gift := ""
	for id in GIFTS:
		if GameState.count(id) > 0:
			gift = id
			break
	if gift != "" and not f.has("victoria_regalo_dia"):
		opts.append("Dejarle algo en la reja")
	if not _lilato_here() and int(f.get("victoria", 0)) >= 3:
		opts.append("Acercarse (Lorena no ha llegado)")
	opts.append("Irse")
	var i := await Dialogue.talk([["", "(Victoria espera en la puerta. %s)" % ("Lorena está con ella." if _lilato_here() else "Lorena todavía no llega.")]], opts)
	match opts[i]:
		"Mirarla de lejos":
			if f.get("victoria_mira_dia", -1) != day:
				f["victoria_mira_dia"] = day
				GameState.change_mood(5.0)
				f["victoria_miradas"] = int(f.get("victoria_miradas", 0)) + 1
				if int(f["victoria_miradas"]) % 2 == 0 and int(f.get("victoria", 0)) < 2:
					_v_bond(1)
			await Dialogue.talk([["", ["(Ella le cuenta algo a una amiga, con las manos.)",
				"(Se le cae el borrador. Lo recoge. Lo sopla. Lo guarda.)",
				"(Se ríe de algo.)"].pick_random()]])
		"Saludarla con la mano":
			if _lilato_here() and randf() < 0.55:
				await _lilato_ve()
			else:
				if f.get("victoria_saludo_dia", -1) != day:
					f["victoria_saludo_dia"] = day
					_v_bond(1)
				GameState.change_mood(8.0)
				await Dialogue.talk([["", "(Levanta la mano. Ella se queda mirando. Mira a Lukas. Lo mira a él.)"],
					["", "(Levanta la suya. Chiquita. Rápido.)"]])
		"Dejarle algo en la reja":
			GameState.remove_item(gift)
			f["victoria_regalo_dia"] = day
			await Dialogue.talk([["", GIFTS[gift]]])
		"Acercarse (Lorena no ha llegado)":
			await _victoria_talk()


## Lorena lo vio. Amenaza; unos días sin poder acercarse.
func _lilato_ve() -> void:
	var f := GameState.flags
	f["lilato_avisos"] = int(f.get("lilato_avisos", 0)) + 1
	f["victoria_veda"] = GameState.day + 3
	GameState.change_mood(-8.0)
	await Dialogue.talk([
		["LORENA", "—¿Usted qué hace aquí?"],
		["ÉL", "Uñas rojas. Las mismas. El mismo tono. Se llama Rojo Pasión, me dijo una vez. Yo le dije que sonaba a telenovela. Se rio. Eso fue en otra vida."],
		["LORENA", "—La próxima vez llamo a la policía. Y no va a ser la primera vez que vienen por usted."],
		["ÉL", "Uno cincuenta. Cara de muñeca de vitrina. Abre la boca y llueve: la saliva llega antes que la idea. A veces la idea no llega."],
		["LORENA", "—Usted tiene una orden de alejamiento. Bueno, casi. Mi abogado dice que es de facto. Eso es en latín. Busque."],
		["LORENA", "—¿No me va a decir nada? Claro que no. Nunca dice nada. Por eso da miedo."],
		["", "(Victoria lo mira desde atrás de la mamá.)"],
	])
	if int(f["lilato_avisos"]) >= 3:
		await Dialogue.talk([["", "(Tercera queja de la mamá. En la Defensoría va a pesar.)"]])


func _victoria_npc() -> void:
	var f := GameState.flags
	if get_tree().current_scene.name == "Parque":
		await _visita()
		return
	if _lilato_here():
		await _lilato_ve()
	elif int(f.get("victoria", 0)) >= 3:
		await _victoria_talk()
	else:
		await Dialogue.talk([["", "(Ella lo mira y da un paso atrás.)"]])


func _victoria_talk() -> void:
	var f := GameState.flags
	if not f.get("victoria_hablo", false) and not GameState.lukas_alive():
		f["victoria_hablo"] = true
		_v_bond(1)
		await Dialogue.talk([
			["VICTORIA", "—¿Usted es el señor del perro? ¿Y el perro?"],
			["", "(...)"],
			["ÉL", "Tengo una forma bonita de decir esto. La tenía preparada. Para..."],
			["", "(Mira la reja. Aprieta la mandíbula.)"],
			["VICTORIA", "—... ¿Se murió? ... Yo lo dibujé. Ahora vive en el dibujo. Los dibujos no se mueren."],
			["VICTORIA", "—Mi mamá dice que usted es un señor malo. Yo no le creo. Ya viene."],
		])
		return
	if not f.get("victoria_hablo", false):
		f["victoria_hablo"] = true
		_v_bond(1)
		await Dialogue.talk([
			["VICTORIA", "—¿Ese perro es suyo?"],
			["", "(Lukas le lame la mano. Ella lee la plaquita del collar.)"],
			["VICTORIA", "—Lukas. ... Mi mamá dice que usted es un señor malo."],
			["", "(...)"],
			["VICTORIA", "—¿Usted no habla? ... Yo tampoco hablo cuando mi mamá grita. Yo digo que los señores malos no tienen perros así de contentos."],
			["ÉL", "Es más inteligente que todos los adultos de este juego juntos. No lo sacó de mí. No sé de dónde. Ojalá de nadie."],
			["VICTORIA", "—¿Usted me dejó cosas en la reja?"],
			["", "(...)"],
			["", "(Asiente.)"],
			["VICTORIA", "—Me gustaron. Ya viene mi mamá."],
		])
		return
	await Dialogue.talk([["VICTORIA", ["—Lukas, ¡dame la pata! ... No sabe. Enséñele. A mí me enseñaron a dar la mano y me tomó como dos años.",
		"—Hoy dibujé un río. Con un puente. ¿Usted vive cerca de un río? ... Asienta, que así hablamos.",
		"—Mi mamá dice que no le hable. Yo le hablo bajito. Usted me contesta bajito también: con nada.",
		"—¿Sabe cuál es el mejor color? El verde agua. No el verde. El verde agua. Casi nadie sabe que existe."].pick_random()]])
	GameState.change_mood(6.0)


## La Defensoría de Familia: los requisitos, la solicitud y la audiencia.
const PRICE_DEFENSORIA := 50000


func _defensoria() -> void:
	var f := GameState.flags
	var day := GameState.day
	if f.get("visitas", false):
		if f.get("testigo", false) and f.get("m_el_resuelto", false) and not f.get("lilato_mentira_caida", false):
			var k := await Dialogue.talk([["DEFENSORA", "—¿Otra vez por aquí? ¿Pasó algo?"]], ["Presentar las pruebas", "Nada"])
			if k == 0:
				await _verdad()
				return
		await Dialogue.talk([["DEFENSORA", "—Sus visitas: los domingos, de diez a doce, en el Parque de San Judas. %s" % ("Sin supervisión." if f.get("lilato_mentira_caida", false) else "Con supervisión. No llegue tarde.")]])
		return
	if f.has("audiencia_dia"):
		if day < int(f["audiencia_dia"]):
			await Dialogue.talk([["DEFENSORA", "—Su audiencia es el día %d. Venga bañado. No es por usted: es por la jueza. La jueza tiene alergia a casi todo, incluida la gente." % int(f["audiencia_dia"])]])
			return
		await _audiencia()
		return
	var reqs := [
		["Cédula", GameState.count("cedula") > 0],
		["Una dirección", GameState.count("carta_german") > 0 or GameState.count("direccion_zaida") > 0],
		["$50.000 del trámite", GameState.money >= PRICE_DEFENSORIA],
		["Trabajo (3 días trabajados)", int(f.get("trabajo_dias", 0)) >= 3],
		["Estar bien (dormir, no recaer)", GameState.locura_level() < 2 and not f.get("recaida", false)],
		["Que la niña lo conozca", int(f.get("victoria", 0)) >= 2],
		["Sin quejas de la mamá", int(f.get("lilato_avisos", 0)) < 3 or int(f.get("victoria_veda", -1)) < day - 5],
	]
	var lines := []
	var ok := true
	for r in reqs:
		lines.append("[%s] %s" % ["X" if r[1] else " ", r[0]])
		ok = ok and r[1]
	await Dialogue.talk([["DEFENSORA", "—Defensoría de Familia. ¿Visitas? Siéntese. No en esa, que tiene una pata floja y una demanda. En la otra."],
		["DEFENSORA", "—Para pedir visitas necesita:"],
		["", "\n".join(lines.slice(0, 4))], ["", "\n".join(lines.slice(4))]])
	if not ok:
		await Dialogue.talk([["DEFENSORA", "—Cuando tenga todo, vuelva. Aquí no se le cierra la puerta a nadie. Se le cierra a la falta de papeles."],
			["ÉL", "Siete requisitos. En la oficina, para despedirme, necesitaron uno: un correo."]])
		return
	var i := await Dialogue.talk([["DEFENSORA", "—Tiene todo. Raro. Casi nadie tiene todo. La última que tuvo todo era abogada y venía por el perro."]], ["Radicar la solicitud ($50.000)", "Todavía no"])
	if i != 0:
		return
	GameState.add_money(-PRICE_DEFENSORIA)
	f["audiencia_dia"] = day + 3
	GameState.complete_quest("v_defensoria")
	GameState.start_quest("v_audiencia")
	await Dialogue.talk([["DEFENSORA", "—Audiencia el día %d. Van a estar usted, la mamá y yo. Y lo que dicen de usted, que siempre llega primero y se sienta en la mejor silla." % (day + 3)]])


func _audiencia() -> void:
	var f := GameState.flags
	f.erase("audiencia_dia")
	MusicDirector.force("")
	await Dialogue.talk([
		["", "(Una oficina chiquita. Un ventilador que no ventila. Lorena, del otro lado de la mesa, sin mirarlo.)"],
		["ÉL", "Ventilador Samurai, tres velocidades, la tres quemada. Un calendario de una ferretería del 2021. Un helecho de plástico con polvo de verdad. Me concentro en el helecho."],
		["DEFENSORA", "—La mamá dice que usted es peligroso."],
		["", "(...)"],
		["DEFENSORA", "—¿No va a decir nada? ¿Nada? ... Señor, así no lo puedo ayudar. Aquí dice que estuvo en la Clínica Irene."],
		["", "(Pone sobre la mesa un papel doblado mil veces: un certificado de la Clínica Irene. Dos años limpio. Lukas apoya la cabeza en el escritorio.)"],
		["LORENA", "—¿Y qué? ¿Eso qué cambia?"],
		["DEFENSORA", "—La niña dibuja a un señor con un perro. Me lo trajo la profesora. Dice que lo ve a la salida."],
		["", "(Lorena no contesta. Por primera vez, no tiene nada que decir.)"],
		["ÉL", "Ahora somos dos. No se siente como pensé que se iba a sentir. No se siente como nada. Se siente como el helecho."],
		["DEFENSORA", "—Visitas supervisadas. Los domingos, de diez a doce, en el Parque de San Judas. Empezamos por ahí."],
	])
	f["visitas"] = true
	GameState.complete_quest("v_audiencia")
	GameState.start_quest("v_visita")
	GameState.change_mood(20.0)
	MusicDirector.release()


## La visita del domingo, en el Parque.
func _visita() -> void:
	var f := GameState.flags
	if GameState.day >= 45 and not f.get("cumple_hecho", false):
		await _cumpleanos(true)
		return
	if f.get("visita_dia", -1) == GameState.day:
		await Dialogue.talk([["VICTORIA", "—El domingo que viene trae a Lukas otra vez. Sin Lukas no vengo." if GameState.lukas_alive()
			else "—El domingo que viene le traigo otro dibujo de Lukas. Para que tenga dónde estar."]])
		return
	f["visita_dia"] = GameState.day
	_v_bond(1)
	GameState.complete_quest("v_visita")
	GameState.change_mood(15.0)
	var n := int(f.get("visitas_hechas", 0)) + 1
	f["visitas_hechas"] = n
	var talks := [
		[["VICTORIA", "—¿Usted es mi papá?"], ["", "(...)"], ["", "(Asiente. Despacio.)"],
			["VICTORIA", "—Ah. Mi mamá dice que no. Pero mi mamá dice muchas cosas. Usted no dice ninguna. Le creo más a usted."],
			["", "(Ella le enseña a Lukas a dar la pata. Lukas no aprende. Ella se ríe. Él casi.)"],
			["ÉL", "Casi. Casi cuenta."]],
		[["VICTORIA", "—Hoy le traje una arepa a Lukas. Usted se puede comer el borde. El borde es lo mejor. Nadie lo sabe."],
			["", "(Dan de comer a las palomas. Ella le pone nombre a cada una. A la más gritona le dice mamá.)"],
			["ÉL", "No me río. No me río. No me..."],
			["", "(Aprieta la mandíbula. Ella lo mira. Se ríen los dos.)"]],
		[["VICTORIA", "—¿Por qué usted vive en la calle?"], ["", "(...)"],
			["VICTORIA", "—¿No sabe? Yo tampoco sé por qué vivo donde vivo. Si encuentra una casa con patio, Lukas puede tener una casa de perro."],
			["VICTORIA", "—Azul. La casa de perro. No, verde agua. Ya le expliqué el verde agua."]],
	]
	if not GameState.lukas_alive():
		talks = [[["VICTORIA", "—¿Dónde está enterrado Lukas?"], ["", "(La lleva al árbol de flores amarillas. Ella deja un dibujo debajo de una piedra.)"],
			["VICTORIA", "—Para que no se aburra."]],
			[["VICTORIA", "—¿Usted está triste?"], ["", "(...)"], ["VICTORIA", "—No me diga nada. Ya sé. Yo también. Pero estamos juntos. Eso cuenta."]]]
	await Dialogue.talk(talks[(n - 1) % talks.size()])


# ---------------------------------------------------------------- Trabajos con minijuego

## La obra: de 6 a 10 se puede empezar el turno (una vez por día, menos los domingos).
func _obra_open() -> bool:
	var f := GameState.flags
	var h := TimeManager.hour()
	return f.get("obra_ready", false) and f.get("obra_dia", -1) != GameState.day and h >= 6 and h < 10 and GameState.day % 7 != 0


## Rapidito: Yeison alquila la bicicleta. Hasta tres pedidos por día.
const PRICE_BICI := 2000


func _yeison() -> void:
	var f := GameState.flags
	if not f.get("met_yeison", false):
		f["met_yeison"] = true
		await Dialogue.talk([
			["YEISON", "—¿Quiere camello, parce? Rapidito. Uno pedalea, la app manda, el cliente califica. Uno es un número con piernas. Yo soy el 4471. Cuatro punto ocho estrellas."],
			["ÉL", "Gorra al revés, dos celulares, uno con la pantalla rota y el otro con la pantalla más rota. Tenis Nike de los que dicen Nikke."],
			["YEISON", "—Le alquilo la bici: dos mil por pedido. Pagan cinco mil, más propina si llega rápido. Si se demora, cancelan. Si cancelan, usted le debe a la app."],
			["YEISON", "—Y si lo roban, le descuentan la bici. Y el pedido. ¿Preguntas? ¿No? Perfecto. La app ama a los que no preguntan. A mí me tiene en lista negra."],
		])
	var today: int = int(f.get("reparto_hoy", 0)) if f.get("reparto_dia", -1) == GameState.day else 0
	if today >= 3:
		await Dialogue.talk([["YEISON", "—Ya hizo tres hoy, parce. La app dice que descanse. La app nunca dice eso. Algo le pasa a la app. Es la primera vez que la veo humana. Me asusta."]])
		return
	var i := await Dialogue.talk([["YEISON", "—¿Un pedido? (%d de 3 hoy)" % today]], ["Repartir ($%d la bici)" % PRICE_BICI, "Hoy no"])
	if i != 0:
		return
	if GameState.money < PRICE_BICI:
		await Dialogue.talk([["YEISON", "—Sin los dos mil no hay bici. La app no fía. Yo tampoco: soy parte de la app. Por dentro soy puro algoritmo, parce."]])
		return
	GameState.add_money(-PRICE_BICI)
	SceneRouter.go("res://scenes/world/Reparto.tscn")


## La ruta con Wilson: una vez por día, de 8 a 16.
func _ruta_open() -> bool:
	var h := TimeManager.hour()
	return GameState.flags.get("ruta_dia", -1) != GameState.day and h >= 8 and h < 16 and GameState.day >= 2


func _wilson_ruta() -> void:
	await Dialogue.talk([
		["WILSON", "—Hoy pasa el camión de la basura. Martes y viernes, a las once y media. Llega, recoge, se va. Como un ex."],
		["WILSON", "—Lo que recojamos antes, es plata. Noventa segundos, parce. Latas por todo el barrio. Se las pago al doble. Al doble. Eso no lo digo nunca."],
		["ÉL", "Noventa segundos. Esto es un minijuego. Wilson no lo sabe. Wilson cree que es su vida. Bueno, también."],
	])
	GameState.flags["ruta_dia"] = GameState.day
	QuestDirector.start_ruta()


# ---------------------------------------------------------------- La veterinaria (Parque de San Judas)
const PRICE_VET := 20000


func _veterinaria() -> void:
	var f := GameState.flags
	var h := TimeManager.hour()
	var sunday := GameState.day % 7 == 0
	if h < 8 or h >= 18:
		await Dialogue.talk([["", "(La veterinaria, cerrada. En la puerta: \"Urgencias: llame\".)"]])
		return
	if not GameState.lukas_alive():
		await Dialogue.talk([["DRA. PILAR", "—... Me contó Leonor. Lo siento mucho, mijo."], ["", "(Le da un abrazo. Él no lo devuelve. Tampoco se suelta.)"], ["ÉL", "..."]])
		return
	if GameState.lukas_stage() >= 1:
		await _vet_cronico()
		return
	if not GameState.lukas_sick():
		await Dialogue.talk([["DRA. PILAR", "—¿Y este muchacho tan lindo? Beagle. Tricolor. Unos ocho años, por los dientes. Sano, gordito... bueno, gordito no."],
			["DRA. PILAR", "—Los domingos en la mañana hay jornada gratis. Para los de la calle. Los perros, digo. Y los dueños, si se dejan. Usted no se va a dejar."],
			["ÉL", "Ocho años, por los dientes. Yo sé exactamente cuántos. Me acuerdo de la caja de zapatos en la que llegó."]])
		return
	var free: bool = sunday and h >= 9 and h < 12
	var price: int = 0 if free else PRICE_VET
	var i := await Dialogue.talk([["DRA. PILAR", "—Uy, este perrito está con fiebre. ¿Desde cuándo?"],
		["", "(Cuenta con los dedos. Desde el día %d.)" % int(f["lukas_enfermo"])],
		["DRA. PILAR", "—Lo reviso y le pongo la inyección. %s" % ("Hoy es jornada: gratis." if free else "Son veinte mil. Lo siento, mijo.")]],
		["Que lo atienda" + ("" if free else " ($20.000)"), "Ahora no"])
	if i != 0:
		return
	if GameState.money < price:
		await Dialogue.talk([["DRA. PILAR", "—No le alcanza. ... Mire: tráigamelo el domingo en la mañana. Jornada gratis. Mientras tanto, agua y comida blanda."]])
		return
	GameState.add_money(-price)
	f.erase("lukas_enfermo")
	f["lukas_curado"] = GameState.day
	TimeManager.skip(1.0)
	GameState.change_mood(12.0)
	await Dialogue.talk([
		["", "(La doctora lo sube a la mesa. Lukas lo mira todo el tiempo. Él no le suelta la pata.)"],
		["DRA. PILAR", "—Listo. Mañana ya va a estar molestando. Usted también coma algo, que la fiebre la tiene usted en la cara."],
		["ÉL", "Veinte mil pesos. Lo más caro que he pagado este año. Lo mejor que he pagado en diez."],
		["", "(Lukas mueve la cola. Despacio, pero la mueve.)"],
	])


# ---------------------------------------------------------------- Misterios: las pistas y el tablero

## Cada caso: el título, la misión, las pistas ([id, de dónde]) y lo que se entiende al conectarlas.
const CASES := {
	"el": {"title": "¿QUIEN ES \"EL\"?", "quest": "m_el", "start": "es_el_oido",
		"clues": [["recorte_1", "Recorte: el operativo"], ["recorte_2", "Recorte: la foto"], ["recorte_3", "Página 14"],
			["npc:marta", "Lo que sabe Marta"], ["npc:wilson", "Lo que dice la calle (Wilson)"]],
		"reveal": [["", "(Pega los recortes en el cartón, en orden.)"],
			["", "(Un operativo en el sur. Policía y ejército. Por una denuncia de Diana Carolina. Un hombre huyó por el río.)"],
			["", "(Página 14, meses después: la denuncia fue retirada. No hubo cargos.)"],
			["", "(Todo el barrio vio la portada. Nadie leyó la página 14.)"],
			["", "(Se queda mirando el cartón. Una hora. No se mueve.)"]]},
	"tejas": {"title": "LA CASA DE TEJAS", "quest": "m_tejas", "start": "casa_tejas_misterio",
		"clues": [["carta_ines", "La carta de Madrid"], ["npc:samuel", "Lo que sabe Samuel"], ["npc:german", "Lo que sabe Germán"]],
		"reveal": [["", "(El hijo de doña Inés volvió tarde: para el entierro. Se encerró en la casa. Pide comida a nombre de ella.)"],
			["", "(Escribe en un cartón: \"Michi está bien. Usted también puede salir.\")"],
			["", "(Lo deja en la puerta de la casa de tejas.)"]]},
	"negro": {"title": "EL SEÑOR DE NEGRO", "quest": "m_negro", "start": "senor_negro",
		"clues": [["npc:rosa", "Lo que sabe Rosa"], ["npc:aurelio", "Lo que sabe Don Aurelio"], ["npc:padre", "Lo que sabe el Padre"]],
		"reveal": [["", "(Fercho le cobra a toda la plaza. Cada uno paga solo, sin decirle a nadie.)"],
			["", "(Escribe en un cartón: FERCHO NOS COBRA A TODOS. Lo pega en la puerta de la iglesia.)"],
			["", "(El domingo, después de misa, Fercho encuentra a cinco personas en la primera banca. No le dicen nada. Lo miran.)"],
			["", "(No vuelve a cobrar.)"]]},
}
## Lo que cuenta cada uno cuando el caso está abierto (una vez).
const CLUE_TALKS := {
	"marta": ["el", [["MARTA", "—¿Vos no sabés por qué te miran así? ... Hace como un año salió un operativo en las noticias. Policía, ejército, un helicóptero. Por un solo man. Un helicóptero."],
		["MARTA", "—Mostraron una foto borrosa. Dicen que eras vos. Yo no les creo. Bueno, no del todo. Pero te sirvo el café igual. El café no juzga. Yo un poquito."],
		["ÉL", "Un helicóptero. Por mí. Nunca me habían dedicado tanto presupuesto. Ni cuando me ascendieron."]]],
	"wilson": ["el", [["WILSON", "—Parce, la gente dice \"el del operativo\". Que usted era peligroso para su hija. Eso dicen. Lo dice la señora del chance. Y la señora del chance no se equivoca, solo con los números."],
		["WILSON", "—Yo vi cómo mira a ese perro. No le creo a nadie que no haya visto eso."]]],
	"samuel": ["tejas", [["SAMUEL", "—¿La casa de tejas? El hijo de doña Inés volvió de España cuando ella murió. Llegó tarde. Dos días tarde. No ha vuelto a salir."],
		["SAMUEL", "—Hay gente que se queda afuera para no llegar tarde a nada. Y gente que se queda adentro porque ya llegó tarde a todo."]]],
	"german": ["tejas", [["DON GERMAN", "—Doña Inés me compraba el pan. Dos de queso, todos los días, a las cuatro. Hablaba de un hijo en Madrid. Decía que iba a volver."],
		["DON GERMAN", "—Volvió, creo. Para el entierro. Y se quedó adentro. Hay que ver. Uno se va lejos para no estar, y vuelve para no estar más cerca."]]],
	"rosa": ["negro", [["DOÑA ROSA", "—El de negro se llama Fercho. Cobra para unos que no se nombran. A todos los de la plaza. A todos, mijito."],
		["DOÑA ROSA", "—Yo le pago en billetes de dos mil. Para que se demore contando. Es mi forma de resistir."]]],
	"aurelio": ["negro", [["DON AURELIO", "—A mí también me cobra. Cincuenta mil. Los lunes. El que no paga, un día amanece sin vidrios. O sin tienda. O sin lunes."]]],
	"padre": ["negro", [["PADRE HERNANDO", "—Fercho viene a misa los domingos. Primera banca. Reza mucho. Echa billetes de cincuenta en la canasta."],
		["PADRE HERNANDO", "—No le puedo decir lo que confiesa. Le puedo decir que la canasta los domingos tiene más plata que la plaza el lunes. Usted haga la cuenta."]]],
}


func _case_open(c: String) -> bool:
	return GameState.flags.get(CASES[c]["start"], false) and not GameState.flags.get("m_%s_resuelto" % c, false)


func _has_clue(clue: String) -> bool:
	if clue.begins_with("npc:"):
		return GameState.flags.get("pista_" + clue.substr(4), false)
	return GameState.count(clue) > 0 or GameState.flags.get("pista_" + clue, false)


## Si esta persona sabe algo de un caso abierto, lo cuenta (una vez).
func _clue(id: String) -> void:
	if not CLUE_TALKS.has(id):
		return
	var c: String = CLUE_TALKS[id][0]
	if not _case_open(c) or GameState.flags.get("pista_" + id, false):
		return
	GameState.flags["pista_" + id] = true
	await Dialogue.talk(CLUE_TALKS[id][1])
	Narrator.say("Pista nueva para el tablero: %s." % CASES[c]["title"].capitalize())


## El tablero del cambuche: qué se sabe de cada caso; con todo, se conectan las pistas.
func _tablero() -> void:
	var opts := []
	var ids := []
	for c in CASES:
		if not GameState.flags.get(CASES[c]["start"], false):
			continue
		var have := 0
		for cl in CASES[c]["clues"]:
			if _has_clue(cl[0]):
				have += 1
		var done: bool = GameState.flags.get("m_%s_resuelto" % c, false)
		opts.append("%s %s" % [CASES[c]["title"], "(RESUELTO)" if done else "%d/%d" % [have, CASES[c]["clues"].size()]])
		ids.append(c)
	if ids.is_empty():
		await Dialogue.talk([["", "(Un cartón pegado a la pared del cambuche. Vacío.)"], ["ÉL", "Todo buen detective tiene un tablero. Yo tengo un cartón. Es lo mismo pero con menos presupuesto y más humedad."]])
		return
	opts.append("Nada")
	var i := await Dialogue.talk([["", "(El tablero: un cartón, tres puntillas y un pedazo de lana roja.)"],
		["ÉL", "La lana roja es fundamental. Sin lana roja es solo un hombre pegando papeles en la pared. Con lana roja es una investigación."]], opts)
	if i >= ids.size():
		return
	var c: String = ids[i]
	var lines := []
	var all := true
	for cl in CASES[c]["clues"]:
		var got := _has_clue(cl[0])
		all = all and got
		lines.append("[%s] %s" % ["X" if got else " ", cl[1]])
	await Dialogue.talk([["", "\n".join(lines)]])
	if GameState.flags.get("m_%s_resuelto" % c, false) or not all:
		return
	var j := await Dialogue.talk([["", "(Están todas.)"]], ["Conectar las pistas", "Todavía no"])
	if j != 0:
		return
	GameState.flags["m_%s_resuelto" % c] = true
	for cl in CASES[c]["clues"]:
		if not cl[0].begins_with("npc:") and GameState.count(cl[0]) > 0:
			GameState.flags["pista_" + cl[0]] = true
			GameState.remove_item(cl[0])
	MusicDirector.force("")
	await Dialogue.talk(CASES[c]["reveal"])
	MusicDirector.release()
	GameState.complete_quest(CASES[c]["quest"])
	match c:
		"el":
			GameState.flags["locura"] = maxi(0, int(GameState.flags.get("locura", 0)) - 4)  # saber aclara
			GameState.change_mood(5.0)
		"tejas":
			GameState.change_mood(8.0)
		"negro":
			GameState.flags["vacuna_fin"] = true
			GameState.raise_bond("rosa")
			GameState.change_mood(10.0)


# ---------------------------------------------------------------- Eventos del día

func _ev_done() -> void:
	GameState.flags["evento_estado"] = "fin"
	var n: Node = get_tree().current_scene.find_child("Evento", true, false)
	if n:
		n.queue_free()


func _ev_redada() -> void:
	_ev_done()
	await Dialogue.talk([["POLICIA", "—Documentos. ... Usted. Sí, usted, el del perro. El perro no, usted."]])
	if GameState.count("cedula") > 0:
		GameState.change_mood(-3.0)
		await Dialogue.talk([["", "(Le pasa la cédula. El policía la mira. Lo mira. Mira la cédula otra vez.)"],
			["POLICIA", "—Usted es... ¿el del operativo? ... ¿No va a decir nada? ¿Nada? ... Circule. Y no me mire así."],
			["ÉL", "Patrullero. Treinta años, cara de cuarenta. Botas lustradas, el resto no. Es de los que revisan la cédula para no tener que revisar a la persona."]])
	else:
		var lost := GameState.lose_random_item()
		GameState.change_mood(-8.0)
		await Dialogue.talk([["", "(Se toca los bolsillos. No tiene cédula.)"],
			["POLICIA", "—¿No tiene? ¿Y tampoco habla? Entonces no existe. Y lo que no existe no tiene cosas."],
			["ÉL", "Filosofía de patrullero. Descartes con bolillo."],
			["", "(Se lleva %s. Para verificar.)" % (lost.to_lower() if lost != "" else "nada: no había nada")]])


func _ev_pelea() -> void:
	_ev_done()
	GameState.flags["violencia"] = true
	var i := await Dialogue.talk([["", "(Dos tipos se dan en el piso, frente a la panadería. Uno ya sangra. La gente graba.)"],
		["ÉL", "El de buzo rojo es diestro y está cansado. El otro tiene algo en el bolsillo. Lo protege con la cadera. Tres segundos y lo saca."],
		["", "(Le tiemblan las manos. No de miedo. Ese es el problema.)"]], ["Separarlos", "Mirar", "Irse"])
	match i:
		0:
			if randf() < 0.4:
				GameState.change_mood(-4.0)
				GameState.set_hunger(GameState.hunger - 5.0)
				await Dialogue.talk([["", "(Se mete en la mitad. Le cae uno en la oreja. Igual los separa.)"],
					["UNO", "—¡¿Y usted quién es?! ... ¡¿Quién es?! ¡Hable, loco!"], ["", "(...)"],
					["UNO", "—Este man está loco. Ni grita. Vámonos, vámonos."],
					["ÉL", "Me dolió la oreja. Bien. Por un segundo pensé que ya no me dolía nada."]])
			else:
				GameState.change_mood(5.0)
				await Dialogue.talk([["", "(Los separa con los brazos abiertos. Lukas ladra en el medio. Los dos se van, insultándose.)"],
					["DON GERMAN", "—(desde la puerta) Eso, mijo. Eso."]])
		1:
			GameState.change_mood(-2.0)
			await Dialogue.talk([["", "(Mira. Como todos.)"], ["ÉL", "Ochenta y tres visualizaciones antes de que llegue la policía. Lo sé porque la señora de al lado lo va narrando."]])
		_:
			await Dialogue.talk([["", "(Se va.)"]])


func _ev_ayuda() -> void:
	_ev_done()
	var kid: bool = GameState.day % 2 == 0
	if kid:
		var i := await Dialogue.talk([["", "(Una niña de unos seis años llora en la esquina. La gente pasa y no la ve.)"],
			["NIÑA", "—No encuentro a mi mamá."]], ["Ayudarla a buscar (1 hora)", "Llevarla donde un policía", "Seguir"])
		match i:
			0:
				TimeManager.skip(1.0)
				GameState.change_mood(12.0)
				await Dialogue.talk([["", "(Le da la mano. Recorren la plaza. Lukas la hace reír.)"],
					["NIÑA", "—¿Usted no habla? ... Mi tío tampoco hablaba. Ahora está en el cielo. Allá tampoco habla."],
					["ÉL", "Seis años. Medias de distinto color. Le falta un diente de arriba. Victoria, a esa edad, tenía ese mismo diente flojo. Se lo... no. Busquemos a la mamá."],
					["", "(La mamá aparece corriendo. Lo mira a él, al perro, a la niña. Duda un segundo.)"],
					["MAMÁ", "—... Gracias. De verdad."]])
			1:
				GameState.change_mood(3.0)
				await Dialogue.talk([["", "(La lleva donde un policía.)"], ["POLICIA", "—¿Y usted qué hace con esta niña? ... ¿No me va a contestar? ... Váyase. Yo me encargo."],
					["ÉL", "Le acaban de agradecer con sospecha. En este barrio es la forma más alta de agradecimiento."]])
			_:
				GameState.change_mood(-6.0)
				await Dialogue.talk([["", "(Sigue. Mira para atrás dos veces.)"], ["ÉL", "Dos veces. Como si mirar contara. No cuenta. Lo sé porque llevo un año siendo el que miran dos veces."]])
		return
	var food := ""
	for id in ["aguapanela", "tinto", "pan", "empanada", "arepa", "fruta", "sandwich"]:
		if GameState.count(id) > 0:
			food = id
			break
	var opts := ["Quedarse con él hasta que llegue la ambulancia"]
	if food != "":
		opts.push_front("Darle algo de tomar o comer (%s)" % Items.info(food)["name"].to_lower())
	opts.append("Seguir")
	var j := await Dialogue.talk([["", "(Un señor en el piso, pálido, sudando. Diabético, dice el carné que lleva colgado. La gente mira.)"]], opts)
	if opts[j].begins_with("Darle"):
		GameState.remove_item(food)
		GameState.change_mood(12.0)
		GameState.flags["ayuda_senor"] = GameState.day
		await Dialogue.talk([["", "(Le da %s. El señor recupera el color de a poquito.)" % Items.info(food)["name"].to_lower()],
			["SEÑOR", "—Usted... gracias. Usted es el... ¿Diga algo, que me asusta? ... No. Bueno. No importa quién sea usted. Gracias."],
			["ÉL", "Glucosa baja. Lo supe por el temblor, antes del carné. No sé cómo lo supe. Sí sé. No quiero saber que sé."]])
	elif opts[j].begins_with("Quedarse"):
		TimeManager.skip(1.0)
		GameState.change_mood(6.0)
		await Dialogue.talk([["", "(Se queda con él una hora, apretándole la mano para que no se duerma. La ambulancia llega tarde.)"],
			["PARAMÉDICO", "—¿Usted es familiar?"], ["", "(Niega.)"], ["PARAMÉDICO", "—Pues parecía."]])
	else:
		GameState.change_mood(-6.0)
		await Dialogue.talk([["", "(Sigue de largo.)"]])


# ---------------------------------------------------------------- El final de la vida real

## El policía de la última banca: confiesa (es el testigo).
func _agente() -> void:
	GameState.flags["testigo"] = true
	if not GameState.quests.has("v_verdad"):
		GameState.start_quest("v_verdad")
	await Dialogue.talk([
		["", "(Un hombre de civil, con las manos juntas. No reza. Espera.)"],
		["ÉL", "Corte de pelo reglamentario que dejó de ser reglamentario hace dos meses. Uña del pulgar mordida hasta la carne. Este hombre no duerme desde hace un año. Exactamente un año."],
		["AGENTE", "—Usted no se acuerda de mí. Yo sí de usted. Yo estaba en el operativo."],
		["AGENTE", "—La mamá de la niña nos dio la dirección. Y la foto. Y nos dijo que usted estaba armado. Que iba a hacerle algo a la niña."],
		["AGENTE", "—No era cierto. Lo supimos esa misma noche. Nadie lo escribió. La denuncia la retiraron meses después. En silencio."],
		["", "(...)"],
		["AGENTE", "—Usted no me pregunta por qué se lo cuento ahora. Se le ve en la cara. Porque yo tengo una hija. Y porque no duermo. Si me necesita, declaro. Donde sea."],
		["ÉL", "Tengo algo que decir. Algo con gracia, sobre los helicópteros. Lo tenía listo hace un año. Ya no..."],
	])
	Narrator.say("Testigo y página 14: la Defensoría.")


## En la Defensoría: con la página 14 y el testigo, la mentira de Lorena se cae.
func _verdad() -> void:
	var f := GameState.flags
	MusicDirector.force("")
	await Dialogue.talk([
		["", "(La misma oficina. El mismo ventilador. Lorena, del otro lado de la mesa. Esta vez también está el agente.)"],
		["", "(Pone en la mesa la esquina del periódico. Página 14: \"La denuncia fue retirada. No hubo cargos.\")"],
		["AGENTE", "—Ella nos dio la dirección y la foto. Dijo que él estaba armado. No lo estaba. Lo puedo jurar."],
		["LORENA", "—Eso es mentira. Él... él es peligroso. Todo el mundo lo sabe. Es de dominio púbico."],
		["DEFENSORA", "—Público, señora."],
		["ÉL", "Le cayó una gota en el expediente. La defensora la secó con la manga, sin mirar. Lleva años en esto."],
		["DEFENSORA", "—Todo el mundo vio la portada, señora. Yo estoy leyendo la página 14."],
		["ÉL", "Página 14. Entre un aviso de colchones y el horóscopo. Libra: \"hoy alguien le devuelve algo que creía perdido\". Ni el horóscopo lo leyó."],
		["LORENA", "—..."],
		["DEFENSORA", "—Visitas sin supervisión. Y el cumpleaños de la niña, con el papá. La custodia la revisamos con otra audiencia. Y con otra actitud."],
		["", "(Lorena no lo mira. No tiene a quién llamar.)"],
		["DEFENSORA", "—¿Quiere decir algo, señor? ... ¿Algo? ... Bueno. Usted ya habló con esa página. Mejor que cualquier abogado."],
		["ÉL", "Un año preparando el chiste perfecto para este momento. El de la portada y la página 14. Tenía remate y todo. No me acuerdo del remate. No importa. Ya no hace falta."],
		["", "(Sale de la oficina. Afuera, Lukas mueve la cola.)" if GameState.lukas_alive() else "(Sale de la oficina. Afuera no lo espera nadie. Toca el collar en la mochila.)"],
	])
	f["lilato_mentira_caida"] = true
	GameState.complete_quest("v_verdad")
	GameState.change_mood(25.0)
	MusicDirector.release()


## El cumpleaños (día 45). Con visitas: en el Parque, en persona. Sin visitas: de lejos, en la reja.
func _cumpleanos(in_person: bool) -> void:
	var f := GameState.flags
	f["cumple_hecho"] = true
	GameState.complete_quest("v_cumple")
	var saved: int = GameState.cambuche.get("alcancia", 0) if GameState.has_cambuche() else 0
	var gift := "una bicicleta rosada, con canasta y timbre" if saved >= GameState.GIFT_GOAL else \
		("una caja de colores de cuarenta y ocho" if saved >= 40000 else "un clavel y un dibujo de él mismo, de palitos, con Lukas")
	MusicDirector.force("")
	if in_person:
		await Dialogue.talk([
			["", "(El Parque de San Judas. Una torta chiquita en la banca verde. Doce velas. Doña Fabiola la hizo. No quiso cobrar.)"],
			["VICTORIA", "—¡Vino Lukas!" if GameState.lukas_alive() else "—¿Y Lukas?"],
			["", "(Primero el perro. Después él.)" if GameState.lukas_alive()
				else "(No contesta. Ella entiende. Le pone una vela más a la torta: trece. Una es de Lukas.)"],
			["", "(Le da el regalo: %s.)" % gift],
			["VICTORIA", "—... ¿Esto es para mí?"],
			["", "(Asiente. Le tiemblan las manos.)"],
			["", "(Germán, Rosa, Samuel, Marta, el Mono con la guitarra. Llegaron sin que nadie los invitara. Cantan mal. Cantan.)"],
			["VICTORIA", "—Papá. ... ¿Puedo decirle papá?"],
			["", "(Abre la boca. Esta vez casi sale algo.)"],
			["ÉL", "Sí."],
			["", "(Asiente.)"],
		])
	else:
		await Dialogue.talk([
			["", "(Doce y cuarto. Ella sale con un gorro de cumpleaños de papel. Las amigas le cantan en la puerta.)"],
			["", "(Deja %s en la reja, con una tarjeta: \"Feliz cumpleaños. El del perro.\")" % gift],
			["", "(Ella lo ve desde lejos. Levanta la mano, chiquita.)"],
			["ÉL", "Feliz cumpleaños, Victoria."],
		])
	await Dialogue.talk([
		["", "BE A MAN"],
		["", "FIN."],
	])
	f["juego_terminado"] = true
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go("res://scenes/ui/Title.tscn", "", "FIN")


## La enfermedad larga de Lukas: la doctora dice la verdad. Hay algo para que no le duela; no hay cura.
const PRICE_REMEDIO := 15000


func _vet_cronico() -> void:
	var f := GameState.flags
	if not f.get("lukas_diagnostico", false):
		f["lukas_diagnostico"] = true
		await Dialogue.talk([
			["DRA. PILAR", "—Déjeme oírlo... (Escucha mucho rato. Demasiado rato.)"],
			["ÉL", "Uno aprende a leer a los médicos. Si hablan rápido, es nada. Si hablan despacio, es algo. Si no hablan..."],
			["DRA. PILAR", "—Es el corazón, mijo. Lo tiene grande, cansado. Está viejito. Más viejito de lo que parece."],
			["", "(...)"],
			["DRA. PILAR", "—¿Me entendió, mijo? ... Le puedo dar algo para que no le duela. Para que respire mejor. Curarlo... no. Lo siento."],
			["DRA. PILAR", "—Quiéralo mucho estos días. Eso también es remedio. El mejor que hay."],
			["ÉL", "Lukas me lame la mano. Él no sabe. Él cree que vinimos por la galleta que le dan al salir. Le voy a comprar todas las galletas."],
		])
	if f.get("lukas_remedio", false):
		await Dialogue.talk([["DRA. PILAR", "—Siga con las gotas. Y llévelo al parque: le gusta el sol. A todos nos gusta el sol al final."]])
		return
	var i := await Dialogue.talk([["DRA. PILAR", "—Las gotas son quince mil. Le alcanzan para lo que... para lo que haga falta."]],
		["Comprar las gotas ($15.000)", "Ahora no"])
	if i != 0:
		return
	if GameState.money < PRICE_REMEDIO:
		await Dialogue.talk([["DRA. PILAR", "—... Lléveselas. Me las paga cuando pueda. O no me las paga. Lléveselas."]])
	else:
		GameState.add_money(-PRICE_REMEDIO)
	f["lukas_remedio"] = true
	GameState.change_mood(5.0)
	await Dialogue.talk([["", "(Le da las primeras gotas en el hocico. Lukas se relame. Respira un poquito mejor.)"]])
