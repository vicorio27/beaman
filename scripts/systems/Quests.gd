class_name Quests
## Definición de las misiones. Tipos: "main" (principal, en orden), "side" (secundaria),
## "optional" (opcional, chiquita). El estado vive en GameState.quests; las reglas de cuándo
## se cumplen, en QuestDirector.

const DEFS := {
	# Día 1 — principales
	"conseguir_comida": {"title": "Conseguí algo para comer", "kind": "main",
		"detail": "Hay que comer algo antes de que oscurezca. Pan en la panadería de Don Germán (plaza, $1.500), algo tirado por el barrio, o que Lukas busque [F]. Se cumple al comer cualquier cosa."},
	"pasar_el_dia": {"title": "Al anochecer, volvé al puente", "kind": "main",
		"detail": "Cuando caiga la tarde (desde las 6), volver al puente del río, donde duerme. Alguien está ocupando el lugar."},
	"donde_dormir": {"title": "Encontrá dónde pasar la noche", "kind": "main",
		"detail": "Elegir dónde pasar la noche: el cambuche, el banco de la plaza, el techito del kiosco o la pensión ($15.000). Afuera roban más; en el cambuche, menos. Se duerme con [E] en el lugar."},
	# Día 1 — secundarias
	"latas": {"title": "Juntá 5 latas o botellas", "kind": "side", "goal": 5,
		"detail": "Recoger latas o botellas tiradas por el barrio (brillan en el piso). Wilson, el del carro de supermercado, las compra en la plaza."},
	"cartones": {"title": "Juntá 3 cartones para dormir", "kind": "side", "goal": 3,
		"detail": "Juntar tres cartones (están tirados por el barrio, cerca de las bodegas y la basura). Sirven para armar el cambuche."},
	"bultos_german": {"title": "Cargá los bultos de Don Germán", "kind": "side",
		"detail": "Don Germán, en la panadería de la plaza, necesita que le carguen los bultos de harina. Paga con plata y pan."},
	"mandado_marta": {"title": "Llevá el pedido de Marta", "kind": "side",
		"detail": "Marta, la del café, mandó un pedido a una casa del barrio. Llevarlo a la puerta que dice ella y tocar una sola vez."},
	# Día 1 — opcionales
	"lukas_olfato": {"title": "Que Lukas busque comida [F]", "kind": "optional",
		"detail": "Abrir el menú de Lukas [F] y elegir \"Buscá\": va olfateando hasta lo más cercano (prefiere comida) y ladra donde está."},
	"lo_bueno": {"title": "Lo bueno del barrio", "kind": "optional",
		"detail": "Seis cosas buenas del barrio, sin plata: pescar en la orilla del río, el atardecer en el puente (de 5 a 7 de la tarde), tapar penaltis con los pelados del lote (de 9 a 6), la banca del parquecito, el columpio y el perro del barrio."},
	# Día 2 — principales: aprender lo básico, en orden (y después, el recuerdo de la moto)
	"t_cambuche": {"title": "Armá el cambuche: 3 cartones [C]", "kind": "main",
		"detail": "Armar el cambuche con tres cartones: abrir la mochila (Tab) y [C] armar, parado en un lugar que sirva (el río, el callejón o el Parque)."},
	"t_lukas": {"title": "Dale de comer a Lukas [F]", "kind": "main",
		"detail": "Darle de comer a Lukas: menú de Lukas [F] > Comida. Concentrado, o compartir algo de comida de la mochila. Una vez al día."},
	"t_bano": {"title": "Bañate: baño de la plaza, $1.000", "kind": "main",
		"detail": "Bañarse en el baño público de la plaza: $1.000. Sucio, la gente se aparta y el fotógrafo no le toma la foto."},
	"moto_cafe": {"title": "Esa moto frente al café...", "kind": "main",
		"detail": "Frente al café de Marta hay una moto parqueada. Acercarse y mirarla [E]."},
	# Día 3 en adelante — la cédula (varios días)
	"hablar_german": {"title": "Don Germán te quiere decir algo", "kind": "main",
		"detail": "Don Germán, en la panadería de la plaza, tiene algo que decirle. Hablarle."},
	"cedula": {"title": "Sacá la cédula en el centro", "kind": "main",
		"detail": "Sacar el duplicado de la cédula en la Registraduría del centro (bus en la plaza, $2.500). Se hace fila: abren de 8 a 11 de la mañana; hay que llegar temprano."},
	"c_plata": {"title": "Juntá $55.000 para el trámite", "kind": "side",
		"detail": "Juntar $55.000 para el trámite de la cédula. Trabajos: la obra (de 6 a 10, menos domingos), Rapidito (desde el día 4), la ruta de Wilson, pedir."},
	"c_foto": {"title": "Fotos tipo documento (centro)", "kind": "side",
		"detail": "Fotos tipo documento en Foto Express, en el centro: $8.000. Hay que ir bañado: si no, el fotógrafo no la toma."},
	"c_direccion": {"title": "Conseguí una dirección", "kind": "side",
		"detail": "Para la cédula hace falta una dirección. Don Germán puede dar la suya (hablarle, y volver al otro día). En el centro hay alguien que también ofrece la suya, pero cobra después."},
	"recoger_cedula": {"title": "Recogé la cédula", "kind": "main",
		"detail": "La cédula ya está en trámite. Volver a la Registraduría del centro el día que dijeron y recogerla."},
	# Favores (vínculos)
	"f_anillo": {"title": "El anillo de Germán (bodegas)", "kind": "side",
		"detail": "Don Germán perdió el anillo de matrimonio detrás de las bodegas (al norte del barrio). No se ve a simple vista: que Lukas busque [F] por ahí."},
	"f_anillo_volver": {"title": "Llevale el anillo a Germán", "kind": "side",
		"detail": "Llevarle el anillo a Don Germán, a la panadería de la plaza."},
	"f_carta": {"title": "La carta de Samuel (casa del este)", "kind": "side",
		"detail": "Samuel escribió una carta para su hija. La última dirección que tiene es la casa del fondo, al este, pasando la avenida. Tocar esa puerta con la carta en la mochila."},
	"f_carta_volver": {"title": "Volvé con Samuel", "kind": "side",
		"detail": "Volver donde Samuel, en la orilla del río, y contarle cómo le fue a la carta."},
	"f_gato": {"title": "Encontrá a Michi, el gato de Marta", "kind": "side",
		"detail": "Michi, el gato negro de Marta (collar rojo con campanita), se perdió. Siempre volvía a las 4, cuando sale el pan. Buscar con Lukas [F] por el barrio: algo suyo quedó tirado."},
	"f_gato_volver": {"title": "Contale a Marta", "kind": "side",
		"detail": "Volver al café y contarle a Marta lo que pasó con Michi."},
	# La familia (disparan los sueños 6 y 7)
	"llamar_mama": {"title": "Llamá a mamá (teléfono, $500)", "kind": "side",
		"detail": "Llamar a la mamá desde el teléfono público de la plaza: $500."},
	"papa_plaza": {"title": "Ese hombre de la moto, en la plaza", "kind": "side",
		"detail": "En la plaza hay una moto grande parqueada y un hombre al lado (de 9 a 5). Ir a verlo."},
	# Del Día 2 en adelante (se repiten cada día)
	"sobrevivir": {"title": "Sobreviví hasta la noche", "kind": "main",
		"detail": "Pasar el día: comer, que Lukas coma y tome agua, no quedarse sin ánimo. A las 6 oscurece y hay que buscar dónde dormir."},
	"lukas_comida": {"title": "Dale de comer a Lukas [F]", "kind": "optional",
		"detail": "Darle de comer a Lukas hoy: menú de Lukas [F] > Comida. Si no come, busca peor y se enferma."},
	"lukas_agua": {"title": "Dale agua a Lukas (cuenco: guarda)", "kind": "optional",
		"detail": "Que Lukas tome agua: hay cuencos con agua limpia por el barrio (alguien los llena). Pararse al lado y él toma solo."},
	"banarse": {"title": "Bañate: baño de la plaza, $1.000", "kind": "optional",
		"detail": "Bañarse en el baño público de la plaza: $1.000. Sucio, la gente se aparta y da menos al pedir."},
	# Victoria: verla, que lo vea, y pedir visitas en la Defensoría de Familia
	"v_colegio": {"title": "Victoria sale a las 12 (centro)", "kind": "main",
		"detail": "Victoria sale del colegio del centro a las 12 del día (menos los domingos). Lorena la recoge. Ir a la reja: verla, dejarle algo, que ella lo vea. De a poco lo va a reconocer."},
	"v_defensoria": {"title": "Pedí visitas: Defensoría (centro)", "kind": "main",
		"detail": "Pedir visitas en la Defensoría de Familia, en el centro. Hay que llevar todo lo que piden (abajo)."},
	"v_audiencia": {"title": "La audiencia en la Defensoría", "kind": "main",
		"detail": "La audiencia es en la Defensoría del centro. Ir ese día, bañado."},
	"v_visita": {"title": "Visita: domingo 10-12, Parque", "kind": "main",
		"detail": "Visita con Victoria los domingos de 10 a 12, en el Parque de San Judas. No llegar tarde. Si Lukas está, que vaya: ella pidió."},
	# El final: que se sepa la verdad, y el cumpleaños
	"v_verdad": {"title": "La verdad: Defensoría (pruebas)", "kind": "main",
		"detail": "Para que se caiga la mentira de Lorena: la página 14 del periódico (que no hubo cargos) y el testigo (el policía que estuvo en el operativo). Con las dos cosas, a la Defensoría."},
	"v_cumple": {"title": "El cumpleaños de Victoria", "kind": "main",
		"detail": "El 29 de octubre Victoria cumple doce. Con visitas: en el Parque, de 10 a 2. Sin visitas: sale del colegio a las 12. Llevarle el regalo."},
	# Misterios (las pistas van al tablero del cambuche)
	"m_el": {"title": "¿Quién es \"él\"? (tablero)", "kind": "side",
		"detail": "¿Quién es \"él\", del que habla la gente? Pistas: tres recortes de periódico (el barrio, el centro, el Parque), Marta y Wilson. Se ponen en el tablero del cambuche."},
	"m_tejas": {"title": "La casa de tejas (tablero)", "kind": "side",
		"detail": "¿Quién vive en la casa de tejas? Pistas: una carta vieja de Madrid, Samuel y Don Germán. Al tablero del cambuche."},
	"m_negro": {"title": "El señor de negro (tablero)", "kind": "side",
		"detail": "El señor de negro que cobra en el barrio. Pistas: Doña Rosa, Don Aurelio (Parque) y el Padre. Al tablero del cambuche."},
	# Del Día 2 en adelante (una vez)
	"regalo_hija": {"title": "Regalo para Victoria", "kind": "side",
		"detail": "Juntar $150.000 en la alcancía del cambuche para el regalo de Victoria (cambuche > Alcancía > meter). Lo que está en la alcancía no se gasta ni se lo roban dormido."},
	"armar_cambuche": {"title": "Armá tu cambuche [C en la mochila]", "kind": "side",
		"detail": "Armar un cambuche con tres cartones: abrir la mochila (Tab) y [C] armar, en el río, el callejón o el Parque. Con cambuche se duerme mejor y hay dónde guardar cosas."},
	# Encargos del día (DayTasks): uno por día marcado, hasta la noche
	"hoy_comer3": {"title": "Hoy: comer tres veces", "kind": "side",
		"detail": "Comer tres veces hoy, cualquier cosa. Se cumple sola. Si no se cumple, mañana pesa."},
	"hoy_alcancia": {"title": "Hoy: $10.000 más en la alcancía", "kind": "side",
		"detail": "Meter $10.000 más en la alcancía del cambuche hoy (cambuche > Alcancía)."},
	"hoy_truco": {"title": "Hoy: enseñarle algo a Lukas", "kind": "side",
		"detail": "Enseñarle un truco a Lukas hoy: menú de Lukas [F] > Truco > Enseñarle uno nuevo. Con premio sale seguro."},
	"hoy_no_pedir": {"title": "Hoy: no pedir ni una moneda", "kind": "side",
		"detail": "Hoy no pedir ni una moneda: nada de sentarse con el vaso. Se cumple sola si llega la noche sin pedir."},
	"hoy_trabajar": {"title": "Hoy: trabajar (obra, reparto, ruta)", "kind": "side",
		"detail": "Trabajar hoy: la obra (de 6 a 10, menos domingos), un pedido de Rapidito o la ruta de Wilson."},
	"hoy_bano": {"title": "Hoy: verme decente (bañado)", "kind": "side",
		"detail": "Bañarse hoy en el baño público de la plaza: $1.000."},
	"hoy_tumba": {"title": "Hoy: el árbol amarillo (Parque)", "kind": "side",
		"detail": "Ir al árbol amarillo del Parque de San Judas."},
	"hoy_vet1": {"title": "Hoy: vacunas de Lukas (veterinaria)", "kind": "side",
		"detail": "Las vacunas de Lukas: la veterinaria de la Dra. Pilar, en el Parque, antes de las 6. Si no alcanza la plata, ella fía."},
	"hoy_vet2": {"title": "Hoy: control de Lukas (veterinaria)", "kind": "side",
		"detail": "El control de Lukas, que tosió toda la noche: la veterinaria de la Dra. Pilar, en el Parque."},
	"hoy_vet3": {"title": "Hoy: las gotas de Lukas (veterinaria)", "kind": "side",
		"detail": "Se acabaron las gotas de Lukas: la Dra. Pilar, en el Parque. Cuestan $8.000 (o ella fía)."},
	"hoy_rosa": {"title": "Hoy: Doña Rosa te necesita (puesto)", "kind": "side",
		"detail": "Doña Rosa mandó a decir que es urgente: buscarla en su puesto de empanadas."},
	"hoy_samuel": {"title": "Hoy: aguapanela para Samuel", "kind": "side",
		"detail": "Samuel amaneció con fiebre. Llevarle una aguapanela caliente a la orilla del río."},
	"hoy_wilson": {"title": "Hoy: ayudale a Wilson con las latas", "kind": "side",
		"detail": "Wilson necesita brazos para llevar las latas a la chatarrería. Hablarle en la plaza."},
	"hoy_german": {"title": "Hoy: una flor para Don Germán", "kind": "side",
		"detail": "Hoy cumple años Don Germán (no le gusta que se sepa). Doña Leonor vende flores en el Parque: llevarle una a la panadería."},
	"hoy_mono": {"title": "Hoy: el show del Mono (Parque)", "kind": "side",
		"detail": "El Mono tiene \"un show\" en la glorieta del Parque. Necesita público."},
	"hoy_marta": {"title": "Hoy: el cobrador, donde Marta", "kind": "side",
		"detail": "Marta no abrió el café: el cobrador del gota a gota anda por el barrio. Ir al café."},
	"hoy_efrain": {"title": "Hoy: Don Efraín te busca (Parque)", "kind": "side",
		"detail": "Don Efraín, el de los cachivaches, mandó a llamarlo al Parque."},
	"hoy_zaida1": {"title": "Hoy: Zaida (centro)", "kind": "side",
		"detail": "Zaida está en el centro. Ofrece ayuda. Todo lo que da, lo cobra después."},
	"hoy_zaida2": {"title": "Hoy: Zaida (plaza)", "kind": "side",
		"detail": "Zaida está en la plaza. Ofrece algo. Ojo: lo cobra."},
	"hoy_zaida3": {"title": "Hoy: Zaida (Parque)", "kind": "side",
		"detail": "Zaida lo espera en el Parque. Ofrece algo. Ojo: lo cobra."},
	"hoy_zaida4": {"title": "Hoy: Zaida (centro)", "kind": "side",
		"detail": "Zaida tiene \"una buena noticia\". En el centro, cerca de la Defensoría."},
	"hoy_zaida5": {"title": "Hoy: Zaida, la última vez (plaza)", "kind": "side",
		"detail": "Zaida, en la plaza. Dice que es la última vez. Viene a cobrar."},
}

const KIND_LABEL := {"main": "PRINCIPAL", "side": "SECUNDARIA", "optional": "OPCIONAL"}


## El título que se muestra (en el celular, "[F]" dice el botón de la huella).
static func title(id: String) -> String:
	return Controls.keys_in(_title_raw(id))


static func _title_raw(id: String) -> String:
	if id == "sobrevivir":
		return "Día %d: llegá a la noche" % GameState.day
	if id == "recoger_cedula" and GameState.flags.has("cedula_day"):
		return "Recogé la cédula (desde el día %d)" % GameState.flags["cedula_day"]
	return DEFS.get(id, {"title": id})["title"]


## El detalle de la misión (lo que se ve al elegirla en la mochila): qué hacer, dónde, a qué hora,
## qué se gana. Algunas suman lo que falta, en vivo.
static func detail(id: String) -> String:
	var d: String = DEFS.get(id, {}).get("detail", "")
	var g := GameState
	match id:
		"cedula":
			d += "\n[%s] $55.000  [%s] fotos  [%s] dirección" % ["X" if g.money >= 55000 else " ",
				"X" if g.count("foto_doc") > 0 else " ", "X" if g.count("carta_german") > 0 or g.count("direccion_zaida") > 0 else " "]
		"recoger_cedula":
			if g.flags.has("cedula_day"):
				d += " Desde el día %d (hoy es el %d)." % [int(g.flags["cedula_day"]), g.day]
		"v_defensoria":
			var f := g.flags
			var reqs := [["Cédula", g.count("cedula") > 0],
				["Dirección", g.count("carta_german") > 0 or g.count("direccion_zaida") > 0],
				["$50.000", g.money >= 50000],
				["3 días trabajados", int(f.get("trabajo_dias", 0)) >= 3],
				["Estar bien", g.locura_level() < 2 and not f.get("recaida", false)],
				["Que la niña lo conozca", int(f.get("victoria", 0)) >= 2]]
			for r in reqs:
				d += "\n[%s] %s" % ["X" if r[1] else " ", r[0]]
		"v_audiencia":
			if g.flags.has("audiencia_dia"):
				d += " Es el día %d (hoy es el %d)." % [int(g.flags["audiencia_dia"]), g.day]
		"regalo_hija":
			d += " Van $%d." % int(g.cambuche.get("alcancia", 0))
	return Controls.keys_in(d)


static func kind(id: String) -> String:
	return DEFS.get(id, {"kind": "side"})["kind"]


## Progreso "(3/5)" para las que juntan cosas; "" para las demás.
static func progress_text(id: String) -> String:
	match id:
		"latas":
			return " (%d/5)" % mini(5, GameState.count("lata") + GameState.count("botella"))
		"cartones":
			return " (%d/3)" % mini(3, GameState.count("carton"))
		"lo_bueno":
			return " (%d/%d)" % [Conversations.bueno_count(), Conversations.BUENO.size()]
		"c_plata":
			return " ($%dk/55k)" % mini(55, GameState.money / 1000)
		"regalo_hija":
			var have: int = GameState.cambuche.get("alcancia", 0)
			return " ($%dk/%dk)" % [have / 1000, GameState.GIFT_GOAL / 1000]
	return ""
