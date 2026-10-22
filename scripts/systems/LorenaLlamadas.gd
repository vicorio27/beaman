class_name LorenaLlamadas
## Las llamadas de Lorena (las usa autoload/Phone.gd). Todas distintas y todas para joderle la vida: pide
## plata, lo amenaza, le cuenta mentiras de él a Victoria, lo quema con el barrio. Nunca trae nada bueno.
## Van en orden (LLAMADAS, una por día como mucho) y nunca se repiten; cuando se acaban, Lorena deja de
## llamar. Lo que pasa en la vida real se cuela primero (EVENTOS: la cédula, Lukas, la bicicleta...).
## Cada llamada: "a" (lo que dice antes de que él escoja), "r1" (si respira), "r2" (si respira dos
## veces), "fin" (lo que dice al final, escoja lo que escoja), "animo" (cuánto le baja; -3 si no dice) y
## "efecto" (lo que hizo de verdad):
##   pedir_mal: lo quemó en el grupo del barrio: hoy pedir rinde la mitad (Pedir.gd).
##   policia:   llamó al cuadrante: hoy hay redada (QuestDirector._events).
##   german:    llamó a la panadería: hoy Germán no le da trabajo (Conversations._german_job).
##   visita:    el próximo domingo la visita es corta y con reglas de ella (Conversations._visita).
## El jugador solo puede respirar, respirar dos veces, colgar o (con Lukas vivo) ponerle el celular a
## Lukas: LUKAS son las reacciones de ella, en orden. Si cuelga, ella vuelve a llamar con una de VOLVIO.

const L := "LORENA"

const LLAMADAS := [
	{"id": "numero",
		"a": [[L, "—¿Aló? ¿Aló? ... Ah, sí es usted. Respira igualito. Como un perro con sinusitis."],
			[L, "—¿Que cómo conseguí el número? Tengo mis contactos. Bueno, un contacto. Bueno, se lo pregunté a don Efraín. Bueno, se lo pagué. Con plata suya, entonces técnicamente usted me lo dio."],
			[L, "—Lo llamaba para algo importantísimo. ... Ya se me olvidó. Usted me desconcentra con ese silencio tan agresivo."]],
		"fin": [[L, "—No me respire así, que yo me sé su repertorio. Ese es el respiro de 'no tengo plata'. Lo tengo catalogado. Tengo once."],
			[L, "—Ya me acordé: necesito cien mil. Para qué, no le digo, porque es mi vida privada. Artículo quince de la Constitución: el de la privacidad y el de las quinceañeras."],
			[L, "—Bueno, chao. Y no me vuelva a llamar."]]},
	{"id": "tenis",
		"a": [[L, "—Victoria necesita unos tenis para educación física. ... Física cuántica, ¿sí me entiende? Es un colegio bueno."],
			[L, "—Tienen que ser de los que prenden lucecitas, porque si no la profesora no la ve. Son doscientos mil. Bueno, ochenta. Bueno, lo que tenga."],
			[L, "—Mándeme una foto de lo que tiene y yo le digo cuánto es."]],
		"r1": [[L, "—Una sola respiración. Tacaño hasta para el aire. Por eso no tiene amigos. Bueno, tiene un perro. Eso no cuenta, el perro está por la comida."]],
		"r2": [[L, "—¿Dos veces? ¿Eso es un sí? Hagamos así: una vez es 'sí' y dos es 'sí, Lorena, ya mismo'."],
			[L, "—Perfecto. Se lo anoto en el cuaderno. El cuaderno de lo que me debe. Ya va en el tomo dos. El tomo uno lo perdí, así que cuenta doble."]]},
	{"id": "horoscopo",
		"a": [[L, "—Le leo el horóscopo. Escorpio: 'Hoy cobre lo que le deben'. Ese es el mío."],
			[L, "—Usted es Géminis, que son dos personas, o sea que me debe el doble. Eso no lo digo yo, lo dicen los astros. Y los astros no tienen por qué mentir: no tienen hijos."]],
		"fin": [[L, "—Y dice: 'Número de la suerte: cien mil'. ¿Ve? Hasta el horóscopo está de mi lado. El horóscopo y Dios. Y mi mamá. Usted solo tiene al perro y el perro no vota."]]},
	{"id": "tutela",
		"a": [[L, "—Le voy a poner una tutela. Una de esas con sello, notariada y apostillada. Apostillada viene de apóstol: es una tutela bendecida. Contra eso no puede ni el Papa."],
			[L, "—Mi abogado dice que su silencio es tácito. Que es como táctico pero sin tácticas. O sea que usted está perdido."]],
		"fin": [[L, "—Y no es mi primo. Es mi primo político. Que es diferente, porque vota."],
			[L, "—La tutela sale en tres días hábiles. Hábiles para mí. Para usted son días de estar asustado. Vaya preparando el pecho. Y la plata."]]},
	{"id": "coaching",
		"a": [[L, "—Me metí a un curso de coaching ontológico. Ontológico de ontología, que es lo de los dientes."],
			[L, "—Ya entiendo todo: usted es un hombre tóxico. Como el tóxico de las uñas. Yo soy un sistema, Victoria es un sistema, y usted es el virus del sistema. Como el de los computadores."]],
		"fin": [[L, "—El curso cuesta trescientos mil y me va a sanar. Si me sano yo, se sana Victoria. Somos como el sistema solar. Yo soy el sol, obvio."],
			[L, "—Así que en el fondo usted me debe el curso. Es una inversión en su hija. Y en el sol."]]},
	{"id": "grupo", "efecto": "pedir_mal", "animo": -5,
		"a": [[L, "—Le cuento que lo metí al grupo de WhatsApp de su barrio. 'Vecinos Alerta Lombardía'. Doscientos miembros. Bueno, lo metí a usted de tema."],
			[L, "—Puse su foto con un letrero: 'Si lo ven, no le den nada, que todo se lo gasta en el perro'. Ya tiene cuarenta y dos vistos."]],
		"r2": [[L, "—¿Respira dos veces? ¿Está nervioso? Debería. Una señora dijo que lo vio pidiendo en la panadería. Ya le mandé su foto a la señora, para que lo reconozca mejor."]],
		"fin": [[L, "—Una señora respondió 'Dios lo bendiga'. La saqué del grupo. Ese grupo es para alertar, no para bendecir."]]},
	{"id": "miami",
		"a": [[L, "—Me voy para Miami. Bueno, no me voy. Me estoy visualizando. El curso dice que uno se visualiza y el universo le paga los tiquetes."],
			[L, "—Miami no queda en Estados Unidos, queda en la Florida. Usted no sabe porque nunca ha ido a ningún lado."]],
		"fin": [[L, "—Si el universo no paga, paga usted. Usted es como el universo, pero con menos plata y más feo."]]},
	{"id": "perro",
		"a": [[L, "—¿Ese perro todavía está vivo? Victoria dice que se llama Lukas. Yo le digo que se llama 'el perro de su papá', que es como un apellido."],
			[L, "—Un perro come más que un niño. Eso lo leí. Así que si usted puede mantener un perro, puede mandar plata. Esa es la lógica. La lógica es lo de los números."]],
		"fin": [[L, "—Y si no puede mantenerlo, me lo manda. Yo lo vendo. Los beagles se venden bien. Los papás no, ya pregunté."]]},
	{"id": "aguacate",
		"a": [[L, "—Amor, ¿ya compraste el aguacate? Que esté maduro pero no tanto. Que esté maduro como yo: por dentro."],
			[L, "—... ¿Aló? ... Ay. Me equivoqué. Usted no es él. Él respira con más ganas."]],
		"fin": [[L, "—Bueno, ya que estoy aquí. ¿Tiene cien mil? Es para el aguacate. Están carísimos. Por culpa suya, seguramente."]]},
	{"id": "cuadrante", "efecto": "policia", "animo": -5,
		"a": [[L, "—Acabo de llamar al cuadrante. Dije que vi a un señor sospechoso cerca de la plaza. Barba, mochila, perro y cara de 'es él'."],
			[L, "—No dije que era usted. Dije la descripción. Si usted se parece, es problema suyo."]],
		"r1": [[L, "—No me respire con ese tonito. El policía me preguntó si estaba armado. Le dije que con el perro."]],
		"fin": [[L, "—El perro muerde. Eso es un arma blanca: es beagle. Ya van para allá. Pórtese bien, que lo están viendo. Yo también. Siempre."]]},
	{"id": "ansiedad",
		"a": [[L, "—Me dio un ataque de ansiedad. De esos que dan en las piernas. ... No, eso es la várice. Bueno, también me dio eso. Todo por culpa suya."],
			[L, "—La siquiatra, la de la P muda, me dijo que tengo que poner límites."]],
		"fin": [[L, "—Entonces le pongo un límite: me manda plata hasta el viernes. Ese es el límite. Después del viernes le pongo otro."]]},
	{"id": "cumple",
		"a": [[L, "—Para el cumpleaños de Victoria voy a hacer una fiesta temática. El tema es 'que el papá pague'. Va a quedar divina."],
			[L, "—Ella quiere una bicicleta. Yo quiero que ella quiera una bicicleta y que usted la compre. Todos queremos algo. Eso lo dijo Gandhi. O Shakira. Una de las dos."]],
		"fin": [[L, "—Y no se le ocurra venir. Bueno, sí venga, pero de lejos. Como el sol. ... No, el sol soy yo. Usted venga como una nube. Una nube con plata."]]},
	{"id": "novio",
		"a": [[L, "—Le cuento para que se entere por mí y no por chismes: tengo novio. Se llama Jhon Fredy. Es ingeniero."],
			[L, "—Ingeniero de sistemas. Bueno, arregla impresoras. Pero las impresoras son sistemas. Tienen tinta y todo."]],
		"r2": [[L, "—¿Dos respiradas? ¿Celos? Qué ternura. Ya se lo conté a Jhon Fredy. Se rió. Tiene una risa de hombre que paga arriendo."]],
		"fin": [[L, "—Victoria ya le dice tío. En un mes le dice papá. Yo no la obligo: le pago. Mil pesos por vez. Es pedagogía."],
			[L, "—Ah, y Jhon Fredy necesita una moto para ir a arreglar impresoras. Usted sabe de motos. Mándeme lo de la cuota inicial."]]},
	{"id": "german", "efecto": "german", "animo": -5,
		"a": [[L, "—Llamé a la panadería. Me contestó un señor muy amable. Germán. Le conté todo. Bueno, mi versión. La mía tiene más capítulos."]],
		"r1": [[L, "—No respire, que no he terminado. Le dije que usted roba. Que no es seguro tenerlo cerca de la caja registradora. Ni de la caja de nada."]],
		"fin": [[L, "—Me dijo que no me creía. Pero la esposa estaba en la extensión. La esposa sí me creyó. Las esposas siempre me creen. Somos un gremio."]]},
	{"id": "rifa",
		"a": [[L, "—Estoy rifando sus cosas. Las que dejó en el apartamento. La chaqueta, el casco, la colección de casetes de Diomedes."],
			[L, "—La boleta vale cinco mil. Juega con la lotería de Boyacá. ¿Me compra una? Se puede ganar su propia chaqueta."]],
		"r2": [[L, "—¿Dos veces? Dos boletas. Diez mil. Le aparto el 13 y el 66. El 13 por la mala suerte y el 66 porque es el 13 al revés, más o menos."]],
		"fin": [[L, "—Los casetes no se rifan. Esos los boté. Diomedes ya no se oye en esta casa. Ahora se oye a Jhon Fredy. Canta en la ducha. Mal, pero con ganas."]]},
	{"id": "dibujo", "animo": -5,
		"a": [[L, "—Victoria hizo un dibujo de la familia para el colegio. Usted no salió."],
			[L, "—Bueno, salió. Pero yo le pasé corrector. Quedó un fantasma blanco al lado del perro. La profesora dijo que era muy conceptual."]],
		"fin": [[L, "—Le pusieron diez. Gracias a mí. Usted ni en los dibujos aporta."]]},
	{"id": "cadena",
		"a": [[L, "—Le reenvío una cadena: 'Si en siete minutos no le manda cincuenta mil a la persona que más quiere, le va a ir muy mal'."],
			[L, "—Yo soy la persona que usted más quiere. No lo digo yo, lo dice la cadena. La cadena es de Brasil. En Brasil no mienten, bailan."]],
		"fin": [[L, "—Le quedan cinco minutos. Cuatro. ... Ya se le fueron. Ahora le va a ir muy mal. No me eche la culpa: yo le avisé."]]},
	{"id": "embargo",
		"a": [[L, "—Mi primo dice que le vamos a embargar el sueldo."]],
		"fin": [[L, "—¿No tiene sueldo? ... Entonces le embargamos el perro. Mi primo dice que es un bien mueble. Se mueve mucho, entonces es muy mueble."],
			[L, "—Era chiste. ... A medias. Mi primo ya imprimió el formulario. A color."]]},
	{"id": "firma",
		"a": [[L, "—Necesito que me firme un papelito. Es para un trámite. Dice que usted renuncia a... a varias cosas. No lo lea, que se aburre."],
			[L, "—Se lo dejo con Doña Rosa, la de las empanadas. Ella dijo que no se mete. Le pagué una empanada para que se meta."]],
		"fin": [[L, "—Si no lo firma, igual lo presento. Mi primo imita firmas. Lo aprendió en la universidad. Bueno, en la fila de la universidad."]]},
	{"id": "zumba",
		"a": [[L, "—(jadea) Estoy en zumba. (jadea) ¿Ve? Esto es respirar con propósito. Usted respira así sin hacer nada. Eso es pura pereza."]],
		"fin": [[L, "—(jadea) La instructora es la sobrina de la señora de la Defensoría. Le conté todo. En el estiramiento. Quedó estirada contra usted."]]},
	{"id": "profesora", "animo": -5,
		"a": [[L, "—La profesora me dijo que Victoria pregunta por usted en el recreo. Le dije que usted se fue a trabajar al exterior."],
			[L, "—Al exterior de la casa. No es mentira. Usted está al exterior de todo."]],
		"fin": [[L, "—Si se la encuentra en la reja, hágase el que va para Panamá. Póngase gafas. Con eso basta: usted ya tiene cara de extranjero en su propia vida."]]},
	{"id": "carta", "animo": -6,
		"a": [[L, "—Victoria le escribió una carta. Se la leo: 'Querido papá'..."],
			["", "(Aprieta el celular.)"],
			[L, "—... No, mejor no, que se le sube. Ya la boté. Bueno, la reciclé. Ahora es un cono de maní. Sigue siendo de ella, en cierta forma."]],
		"fin": [[L, "—Le cuento para que vea que la niña escribe bonito. Eso lo sacó de mí. Lo de botar las cosas, también."]]},
	{"id": "luz",
		"a": [[L, "—Me cortaron la luz. Lo llamo con la linterna del celular prendida. Estoy a oscuras por culpa suya. Y moralmente también."]],
		"fin": [[L, "—Si no paga el recibo, le voy a decir a Victoria que la luz se fue con usted. Que usted se la llevó en la mochila. Ella me cree todo. Tiene once."]]},
	{"id": "honorarios",
		"a": [[L, "—Mi primo me está cobrando por demandarlo a usted. Doscientos mil."],
			[L, "—Lógico que eso lo paga usted. El demandado paga. Es como en el parqués: el que pierde, recoge las fichas."]],
		"fin": [[L, "—Y no pregunte qué demanda es. Todavía no sabemos. Mi primo dice que primero se cobra y después se inventa. Así trabajan los buenos."]]},
	{"id": "dios",
		"a": [[L, "—Fui a misa y le pedí a Dios que usted me mandara plata. Dios dijo que sí."]],
		"r1": [[L, "—Bueno, no lo dijo. Pero hubo un silencio. Y el que calla otorga. Igual que usted: usted calla siempre, entonces otorga siempre."]],
		"fin": [[L, "—Si no manda, le está llevando la contraria a Dios. Y a mí. Somos un equipo. Él pone los milagros y yo pongo la cuenta."]]},
	{"id": "tiktok",
		"a": [[L, "—Abrí una cuenta en TikTok: 'Mamá Guerrera Real'. Ya tengo cuarenta seguidores. Treinta son de Jhon Fredy, que tiene muchos celulares."],
			[L, "—Voy a hacer un video sobre usted: 'Mi ex, el habitante de calle'. Con música triste y ese filtro que le pone orejitas de perro. Va a ser viral."]],
		"fin": [[L, "—Si llega a un millón de vistas le doy el diez por ciento. De las vistas, no de la plata. Cien mil vistas para usted. Gástelas bien."]]},
	{"id": "acta", "animo": -5,
		"a": [[L, "—Le recuerdo que mañana tenemos cita en la Defensoría. A las ocho. No llegue tarde, que eso queda en el acta."],
			["", "(...)"],
			[L, "—Ay, no, perdón. Era el jueves pasado. Usted no fue. Ya quedó en el acta: 'el señor no se presentó'. Con mi letra, que es más bonita."]],
		"fin": [[L, "—No se preocupe. Le anoté también que usted 'mostró desinterés'. Para que quede completo. Yo soy muy completa."]]},
	{"id": "alergia",
		"a": [[L, "—Victoria es alérgica a los perros. Desde hoy."],
			[L, "—Me lo dijo el doctor. Bueno, yo me lo dije, pero yo soy como doctora: tengo bata. De baño, pero bata."]],
		"fin": [[L, "—Así que el perro, lejos de ella. A cincuenta metros. Con bozal. Y ojalá con otro dueño."]]},
	{"id": "colegio",
		"a": [[L, "—Estoy pensando en cambiar a Victoria de colegio. A uno lejos. Bilingüe."],
			[L, "—Allá le enseñan a decir 'my father is a stranger'. Está en el pénsum. Es de primer grado."]],
		"fin": [[L, "—La matrícula vale un millón. Yo pongo la idea. Usted pone el millón. Así es la cooperación internacional."]]},
	{"id": "vip",
		"a": [[L, "—Ya alquilé el salón para el cumpleaños de Victoria. Salón Los Arcángeles. Con globos de helio y una señora que hace bombas en forma de animal."],
			[L, "—La entrada para usted vale cien mil. Para los demás es gratis. Es entrada VIP: Very Indigente Person."]],
		"fin": [[L, "—Y viene bañado. Y sin perro. Y sin usted, ojalá. Mande la plata y no venga: es la entrada más cara del mundo y la mejor."]]},
	{"id": "cuentas",
		"a": [[L, "—Hagamos cuentas, como gente madura. Doce años de cuota alimentaria. A ochocientos mil el mes."],
			[L, "—Doce por doce... ciento cuarenta y cuatro... por ochocientos... Me da algo con muchos ceros. Lo redondeo para arriba, que soy buena."]],
		"fin": [[L, "—Son ciento quince millones. Le acepto cuotas. Cómodas. De cien mil diarios. Empezamos ayer, así que ya va atrasado."]]},
	{"id": "jhon_fredy",
		"a": [[L, "—Jhon Fredy quiere hablar con usted. Hombre a hombre. Bueno, hombre a usted."],
			["JHON FREDY", "—Quiubo, hermano. Respete a la señora. Ella me contó todo. Todo. Usted es un monstruo. ... ¿Aló?"],
			[L, "—¿Vio? Ese sí es un hombre: habla. Usted respira. Hasta las impresoras hacen más ruido que usted."]],
		"fin": [["JHON FREDY", "—Y mándele lo de la moto, que la necesito para trabajar. Bendiciones, hermano. Sin rencor. Bueno, con poquito."]]},
	{"id": "nevera",
		"a": [[L, "—Se me dañó la nevera. Hace un ruido. Como usted cuando respira: un ruido que no sirve para nada."]],
		"fin": [[L, "—Usted sabe de neveras, que vivió en una casa con nevera. Mándeme ciento veinte para el técnico. Jhon Fredy dice que él la arregla, pero solo arregla impresoras. La nevera no tiene tinta."]]},
	{"id": "graduacion", "animo": -5,
		"a": [[L, "—Victoria se gradúa de quinto el viernes. Toga, birrete, todo. Usted no está invitado."]],
		"fin": [[L, "—Pero el regalo sí está invitado. Puede ser plata, que no se arruga. Y que no se note que es suya, que la niña se confunde."]]},
	{"id": "facebook",
		"a": [[L, "—Puse en Facebook que usted es peligroso. Con foto. La del pasaporte, que sale con cara de que se va a escapar."],
			[L, "—Ya tiene treinta reacciones. Nueve son de 'me divierte'. Usted siempre fue chistoso para los demás. Para mí nunca."]],
		"fin": [[L, "—Su tía Gloria comentó 'eso no es así'. La bloqueé. A su tía y a la verdad. Las dos me caían mal."]]},
	{"id": "presidente",
		"a": [[L, "—Le escribí una carta al presidente contándole lo suyo. A mano. Con letra cursiva y un sticker de unicornio."]],
		"fin": [[L, "—No ha contestado. Pero le dejé el número de usted para que lo llame a regañarlo. Si le timbra un número de Bogotá, conteste. Es el presidente. O un banco."]]},
	{"id": "terapia",
		"a": [[L, "—Mi terapeuta quiere que hagamos una sesión de pareja. Usted, yo y el cheque."],
			[L, "—Yo hablo, la terapeuta escucha y usted paga. Es el método. Se llama constelaciones familiares. Usted es la estrella que se apagó."]],
		"fin": [[L, "—Son ciento cincuenta la hora. La sesión dura tres horas, porque yo tengo mucho que decir."]]},
	{"id": "loteria",
		"a": [[L, "—Compré lotería con el número de su cédula. Lo saqué de una foto que tengo de su cédula. Tengo fotos de todo lo suyo. Por si acaso."]],
		"fin": [[L, "—No salió. Ni una cifra. Su número es salado. Me debe la boleta. Doce mil, con el seco."]]},
	{"id": "girardot",
		"a": [[L, "—Lo llamo para despedirme. Me voy. Para siempre."],
			["", "(...)"],
			[L, "—... Para Girardot. El fin de semana. El lunes vuelvo."]],
		"fin": [[L, "—Mándeme para el pasaje de regreso, que el de ida ya lo tengo. Me lo dio Jhon Fredy. Él sí me lleva a lugares."]]},
	{"id": "celular_victoria", "animo": -5,
		"a": [[L, "—Jhon Fredy le compró a Victoria un celular. Con cámara. Con internet. Con forro de gatico."],
			[L, "—Usted le compró... ¿qué le compró usted? ... ¿Ve? Ese silencio es el mismo de siempre. Es su único regalo."]],
		"fin": [[L, "—Bueno, el celular es a cuotas y las cuotas están a nombre suyo. Pero el regalo es de él. Así funciona el amor moderno."]]},
	{"id": "sicologa",
		"a": [[L, "—La sicóloga del colegio quiere saber si usted tiene antecedentes. Le dije que sí. De todo un poco. Como un corrientazo."]],
		"fin": [[L, "—Me preguntó cuáles. Le dije que eso era confidencial. Así suena peor. Lo aprendí de mi primo."]]},
	{"id": "foto",
		"a": [[L, "—Necesito una foto suya reciente para el expediente. Una donde se vea mal. ... Cualquiera sirve, entonces."]],
		"fin": [[L, "—No se preocupe si no tiene cómo mandarla. Le pedí a Doña Gladys que le tomara una de lejos. Salió muy bien. Muy mal, pues. Perfecta."]]},
	{"id": "aniversario",
		"a": [[L, "—Hoy hubiéramos cumplido trece años. ... ¿Se acordaba? ... Claro que no. Usted no se acuerda de nada importante. Solo del perro."]],
		"fin": [[L, "—Mándeme el regalo de aniversario. Yo a usted no le voy a dar nada, porque yo sí lo superé. Se nota, ¿cierto? Se me nota en la voz."]]},
	{"id": "gladys",
		"a": [["DOÑA GLADYS", "—¿Aló? Habla Gladys, la vecina de Lorena. Ella está aquí al lado. Me dijo que le dijera que usted es un irresponsable."],
			[L, "—(de lejos) ¡Y un tacaño!"],
			["DOÑA GLADYS", "—Y un tacaño. ... ¿Algo más, mija? ... Dice que eso es todo. Que le mande plata."]],
		"fin": [["DOÑA GLADYS", "—Bendiciones, mijo. Yo no pienso nada de usted. Ni bueno ni malo. Yo soy la que presta el celular."]]},
	{"id": "testamento",
		"a": [[L, "—Estuve pensando que usted debería hacer un testamento. Por nada. Uno nunca sabe. Vivir en la calle es como un deporte extremo, pero sin patrocinio."]],
		"fin": [[L, "—Me deja todo a mí. Yo le dejo a usted la tranquilidad de que me dejó todo. Es un buen negocio. Mi primo ya lo redactó. Falta la parte de 'todo'."]]},
	{"id": "encuesta",
		"a": [[L, "—Buenas tardes, le habla una encuesta. ¿Usted cree que Lorena es la mejor mamá del mundo? Si está de acuerdo, respire una vez. Si está muy de acuerdo, dos."]],
		"r1": [[L, "—Registramos: de acuerdo. Gracias por su honestidad. La encuesta se la voy a mostrar a la Defensora."]],
		"r2": [[L, "—Registramos: muy de acuerdo. Lo sabía. En el fondo usted me admira. En el fondo de la calle."]]},
	{"id": "presupuesto",
		"a": [[L, "—Hice el presupuesto del mes. Arriendo, mercado, uñas, zumba, el curso, el TikTok, la cuota de la moto de Jhon Fredy."],
			[L, "—Me faltan cuatrocientos mil. Casualmente es lo que usted no me ha mandado. Las cuentas no mienten. Yo sí, a veces, pero las cuentas no."]],
		"fin": [[L, "—Le mando el presupuesto por WhatsApp. ... No tiene WhatsApp. Se lo mando con Doña Gladys. En un papel. Con copia para la Defensoría."]]},
	{"id": "suegra",
		"a": [[L, "—Su mamá me llamó."],
			["", "(...)"],
			[L, "—Mentira. Pero vio cómo se quedó callado. Más callado. Eso es lo que yo quería. Ya tengo el día."]],
		"animo": -6},
	{"id": "mudanza",
		"a": [[L, "—Nos vamos a vivir con Jhon Fredy. A un conjunto cerrado. Con portería, piscina y un celador que no deja entrar gente como usted."],
			[L, "—Ya le di su foto al celador. La de Facebook. Dijo que cara así le llega una por semana, pero que a usted lo va a recordar."]],
		"fin": [[L, "—La piscina es para los residentes. Victoria es residente. Usted es... ¿cómo se dice? ... Ah, sí: usted es nadie."]]},
]

## Lo que pasa en la vida real y ella se entera (siempre se entera). Una vez cada uno; le gana a la
## llamada del orden. "si": [cómo se sabe que ya pasó] (ver LorenaLlamadas.pendiente).
const EVENTOS := {
	"cedula": {"a": [[L, "—Me dijeron que sacó la cédula. Felicitaciones: ya existe. Ahora sí lo puedo demandar con nombre y apellido."],
			[L, "—Antes era un fantasma, y los fantasmas no pagan. Ahora es un ciudadano. Los ciudadanos pagan. Bienvenido a la sociedad."]]},
	"trabajo": {"a": [[L, "—Supe que está trabajando. Cargando cosas, repartiendo. Mándeme la mitad. Es la ley. La ley de la gravedad: lo que usted levanta, a mí me cae."]],
		"fin": [[L, "—Y si le pagan en especie, mándeme la especie. Si es pan, pan. Si es ladrillo, ladrillo. Lo vendo. Todo se vende. Usted no, ya pregunté."]]},
	"visitas": {"efecto": "visita", "animo": -6,
		"a": [[L, "—Ya sé que la Defensora le dio visitas. Felicitaciones. Las supervisa una señora que va a mi zumba."],
			[L, "—El domingo Victoria tiene una piñata. Le doy veinte minutos. Y no la abrace, que usted huele a calle y después la piñata huele a calle."]],
		"fin": [[L, "—Ah, y la niña ya sabe lo que tiene que decirle. Lo ensayamos. Le quedó divino."]]},
	"denuncia": {"a": [[L, "—La boba de Diana Carolina retiró la denuncia. Así no es. Uno no retira las cosas: uno las sostiene. Sostener es de mujeres fuertes."],
			[L, "—No se ilusione. Yo tengo la mía. Bueno, todavía no. Pero mi primo ya tiene el título: 'Denuncia Dos: el regreso'."]]},
	"lukas_enfermo": {"a": [[L, "—Supe que el perro está enfermo. ¿Ve? Hasta el perro se enferma de estar con usted. Yo aguanté nueve años. Merezco una medalla. Y una pensión."]],
		"fin": [[L, "—No me pida para el veterinario. Pídale a Dios. Él tampoco contesta, pero por lo menos no cobra."]]},
	"torneo": {"a": [[L, "—Supe que hay un coliseo con tenistas en su barrio. Aposté plata. Contra el que usted quiera que gane. Para que aprenda a querer cosas."]],
		"fin": [[L, "—Si gana el que usted quiere, me debe lo que perdí. Si pierde, me debe la alegría. Igual me debe. Así es el deporte."]]},
	"tos": {"a": [[L, "—¿Y esa tos? Suena a tos de pobre. La de los ricos es más cortica, porque les dan jarabe."],
			[L, "—No se vaya a morir antes de pagarme. Si se va a morir, avíseme con tiempo. Para el seguro. ¿No tiene seguro? Entonces no se muera, que no da para nada."]]},
	"lukas_muerto": {"animo": -8,
		"a": [[L, "—Victoria me contó lo del perro. Lloró toda la tarde. Gracias. Ahora tengo que comprarle un hámster para que se calle."]],
		"fin": [[L, "—Mándeme lo del hámster. Y lo de la jaula. Y lo de la rueda, que el hámster no tiene la culpa de nada. Él no."]]},
	"bici": {"animo": -5,
		"a": [[L, "—Me contaron que compró una bicicleta. Verde agua, con canasta y timbre. En el barrio todo se sabe. Sobre todo lo que yo pregunto."],
			[L, "—Esa plata era de la cuota alimentaria, para que sepa. Pero bueno, hagamos algo: la bicicleta se la doy yo. De parte mía. Usted no aparezca, que la confunde."]],
		"fin": [[L, "—Déjela en la portería, a nombre mío. Con moño. Si no tiene moño, no la recibo. Una tiene estándares."]]},
	"ultima": {"animo": -6,
		"a": [[L, "—Mañana es el cumpleaños. Ya está todo listo: el salón, los globos, Jhon Fredy con camisa nueva. Rosada, como yo."],
			[L, "—Usted no venga. Y si viene, no entre. Y si entra, no hable. ... Ah, cierto, usted no habla. Por fin algo suyo que me sirve."]],
		"fin": [[L, "—Chao. Y le deseo lo mejor. ... Mentira. Pero suena bonito, ¿cierto? Lo aprendí en el curso."]]},
}
## El orden en que se revisan (el primero que ya pasó y no se ha dicho, va).
const EVENT_ORDER := ["ultima", "lukas_muerto", "bici", "tos", "lukas_enfermo", "visitas", "denuncia", "torneo", "trabajo", "cedula"]

## Cuando le cuelgan, vuelve a llamar. Cada vez con otra.
const VOLVIO := [
	"—¿ME COLGÓ? ¿A mí? ¿A la madre de su hija? Eso es violencia telefónica. Le voy a poner una tutela por cada pitido.",
	"—Se me cayó la llamada. Bueno, usted me la tumbó. Es igual. Eso es física: acción y reacción, como dijo Isaac Nielsen.",
	"—Le marco otra vez porque soy una persona madura. Mi coach dice que soy la más madura del grupo. El grupo es de WhatsApp, pero igual.",
	"—Colgarle a una mujer es lo mismo que pegarle, pero por cable. Eso lo dijo una actriz. De novela. Turca.",
	"—¿Se le acabó la batería? No, porque timbró. ¿Se le acabó la vergüenza? Eso sí, hace años.",
	"—Le cuento que cada vez que me cuelga, Victoria llora. Bueno, no, está en el colegio. Pero lloraría si supiera. Yo se lo voy a contar.",
	"—Anoté la hora en que me colgó. Las tengo todas en un cuaderno. Mi primo dice que con veinte colgadas ya es acoso. Usted va en diecinueve. Yo cuento rápido.",
	"—Usted me cuelga y yo le vuelvo a marcar. Así va a ser toda la vida. Es lo único que tenemos en común: no nos rendimos.",
	"—Me colgó justo cuando le iba a decir algo bonito. ... No era bonito. Pero me dejó con las ganas de decírselo.",
	"—Estoy grabando esta llamada. Para que conste que me volvió a contestar. Eso cuenta como que me quiere.",
	"—¿Sabe cuánto me cuesta marcarle otra vez? Doscientos pesos. Súmelos a la cuenta. Con intereses de mora: trescientos.",
	"—Si me vuelve a colgar, le marco del celular de Jhon Fredy. Él tiene plan ilimitado. Yo tengo rabia ilimitada. Hacemos buena pareja.",
	"—Mi terapeuta dice que cuando alguien me cuelga es porque no soporta mi luz. Usted es como un murciélago. Uno de calle.",
	"—Me colgó. Bueno. Respiro. ... ¿Ve? Yo también sé respirar. No es tan difícil. Lo difícil es pagar.",
	"—La próxima vez que me cuelgue le cuento al grupo de las mamás del colegio. Somos cuarenta. Cuarenta mamás contra usted. Ni en sus sueños.",
	"—Colgar es de cobardes. Contestar es de valientes. Pagar es de hombres. Usted no es ninguno de los tres. Es otra cosa. Un mueble.",
	"—Le aviso que tengo minutos para todo el día. Me los regaló el operador por cliente fiel. Fiel a molestarlo.",
	"—¡Qué falta de educación! Bueno, usted no terminó el bachillerato. Eso explica. Lo de no colgar viene con el diploma.",
	"—Me colgó y se me rayó el esmalte del susto. Me debe la manicura. Treinta mil. Con el diseño de florecitas.",
	"—Esto ya es personal. Bueno, siempre fue personal. Pero ahora es personal con tutela.",
	"—¿Sabe qué es lo bueno de que me cuelgue? Que me deja con la última palabra. Y la última palabra es: plata.",
	"—Usted cuelga como bota la basura: sin mirar. Así lo botaron a usted también. ... Uy. Me salió del alma. Del alma no: del curso.",
	"—Le marqué otra vez para decirle que no le voy a marcar más. ... Ya. Era eso. Mañana lo llamo para confirmar.",
]
## Si ya le había dicho lo de hoy y le colgó, cierra con una de estas.
const CIERRE := [
	"—Bueno, ya le dije todo lo que le tenía que decir. Es que usted no escucha. Chao. No me llame.",
	"—Era eso. Que me colgó. Ya quedó dicho. Ahora sí, chao.",
	"—No tengo nada más que decirle. Solo quería que supiera que me ofendió. Ya lo sabe. Chao.",
	"—Ya se me olvidó para qué lo llamaba otra vez. Por culpa suya. Chao.",
	"—Le dejo esta llamada como prueba. De qué, no sé. Pero como prueba. Chao, señor.",
	"—Chao. Y no me cuelgue la próxima, que me salen arrugas.",
	"—Eso era todo. Bendiciones. Mentira: bendiciones no. Chao.",
	"—Ya me desahogué. Gracias. Usted sirve para eso, por lo menos.",
	"—Chao, pues. Me voy a zumba a sacarme esta rabia. La rabia es suya, pero la sudo yo.",
	"—Listo. Quedamos en que usted es el malo. Chao.",
]
## Cuando llama de otro número (para que le conteste).
const OTRO_NUMERO := [
	"—¿Aló? Jajá. ¿Ve? Si le marco de mi número no me contesta. Este es el de mi vecina. Doña Gladys le manda saludos. Mentira, no lo quiere.",
	"—¿Aló? ¡Ja! Le marqué del celular de Jhon Fredy. ¿No reconoció el número? Es porque es de un hombre que sí trabaja.",
	"—Lo llamo de un teléfono público. Me tocó echar monedas. Me debe tres monedas de doscientos. Y la vergüenza de usar un público.",
	"—Este es el número de mi primo. El abogado. Si contestó este número, ya cuenta como citación. Mentira. Pero asústese igual.",
	"—Le hablo del taller de Jhon Fredy. Aquí todo huele a tinta. Usted debería oler a tinta: así parecería que trabaja.",
	"—Sí, soy yo, con otro número. Tengo cuatro: uno para mi mamá, uno para Jhon Fredy, uno para el curso y uno para joderlo a usted. Este.",
	"—Me prestó el celular la señora de la tienda. Le manda decir que usted le debe una gaseosa de 2015. Yo me encargo de cobrársela.",
	"—Le hablo desde el celular de Victoria. ... No, mentira, es el mío. Pero vio cómo se le paró el corazón. Eso es lo que yo siento siempre.",
]
## Cuando él le pone el celular a Lukas. [lo que hace Lukas, lo que dice ella].
const LUKAS := [
	["(Le acerca el celular a Lukas. Lukas lo huele. Ladra una vez, fuerte, directo al micrófono.)",
		"—¿ME LADRÓ? ¿Usted me puso al perro? Eso es violencia canina. Lo voy a denunciar en el ICBF, que es el de los perros."],
	["(Lukas le lame la pantalla al celular.)",
		"—¿Qué es ese ruido? ¿Me está besando? ... Ay, qué asco. Ay, qué tierno. Ay, qué asco. Mándeme plata."],
	["(Lukas gruñe bajito. Un gruñido largo, de motor viejo.)",
		"—Ese perro me tiene rabia. Usted le habla mal de mí. ... ¿No le habla? Entonces es instinto. Peor."],
	["(Lukas estornuda en el micrófono.)",
		"—¡Salud! ... Espere. ¿Ese fue el perro? ¿Usted me puso a decirle salud a un perro? Esto es humillación. Lo anoto."],
	["(Lukas aúlla. Ni él sabe por qué.)",
		"—¿Está llorando? ¿Así llora usted? ... Ah, es el perro. Igual suena a usted."],
	["(Lukas se acuesta encima del celular. La llamada sigue, ahogada.)",
		"—¿Aló? ¿Por qué se oye como desde un túnel? ¿Está en un túnel? ¿Ya lo echaron también del puente?"],
	["(Lukas ladra dos veces, cortito.)",
		"—Dos ladridos. ¿Eso es un sí? Lo tomo como sí. Ya se lo anoté: el perro aceptó la deuda."],
	["(Lukas mira el celular, lo mira a él y se va a echar lejos. No quiere saber nada.)",
		"—¿Aló? ... ¿Aló? ... Hasta su silencio está más silencioso hoy. Qué raro. Me preocupa. No. Ya se me pasó."],
	["(Lukas le muerde la antena al celular. Cruje.)",
		"—¡Se oye feo! ¡Se oye como si me mordieran! ... Eso es lo que siento cada vez que usted no paga."],
	["(Lukas ladra largo, con ganas, como cuando pasa el de la moto.)",
		"—¡Calle a ese animal! ... No, no lo calle. Grábelo. Me sirve para la demanda: 'ambiente hostil'."],
]
const LUKAS_CANSADO := ["(Le acerca el celular a Lukas. Lukas ya no se presta para eso. Lo mira con algo parecido a la lástima. A él, no a ella.)",
	"—¿Aló? ¿Otra vez el perro? Ya ni el perro le hace caso. Bienvenido a mi vida."]


## Lo que ya pasó en la vida real y ella todavía no le ha sacado en cara ("" = nada).
static func pendiente() -> String:
	var g := GameState
	var f := g.flags
	for id in EVENT_ORDER:
		if f.get("lorena_ev_" + id, false):
			continue
		var ok := false
		match id:
			"ultima": ok = g.day >= 49
			"lukas_muerto": ok = not g.lukas_alive()
			"bici": ok = f.get("bici_comprada", false)
			"tos": ok = g.tos_stage() >= 2
			"lukas_enfermo": ok = g.lukas_stage() >= 1 and g.lukas_alive()
			"visitas": ok = f.get("visitas", false)
			"denuncia": ok = f.get("denuncia_retirada", false)
			"torneo": ok = f.has("torneo")
			"trabajo": ok = int(f.get("trabajo_dias", 0)) >= 2
			"cedula": ok = g.count("cedula") > 0
		if ok:
			return id
	return ""


## ¿Le queda algo por decir? (si no, ya no llama: se le acabó el repertorio, que es lo mismo que el saldo).
static func le_queda() -> bool:
	return int(GameState.flags.get("lorena_llamada", 0)) < LLAMADAS.size() or (int(GameState.flags.get("lorena_llamada", 0)) > 0 and pendiente() != "")


## La llamada que toca (y la marca como dicha). La primera siempre es la del número.
static func siguiente() -> Dictionary:
	var f := GameState.flags
	var n := int(f.get("lorena_llamada", 0))
	if n > 0:
		var ev := pendiente()
		if ev != "":
			f["lorena_ev_" + ev] = true
			return EVENTOS[ev]
	if n >= LLAMADAS.size():
		return {}
	f["lorena_llamada"] = n + 1
	return LLAMADAS[n]


## La que sigue de una lista que no se repite (flag = dónde va). Al final se queda en la última.
static func turno(lista: Array, flag: String):
	var f := GameState.flags
	var i := int(f.get(flag, 0))
	f[flag] = i + 1
	return lista[mini(i, lista.size() - 1)]
