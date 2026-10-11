extends CanvasLayer
## El celular de flecha (se lo vende Don Efraín: Items "celular"). Con el celular en la mochila, en la
## ciudad, cada tanto entra una llamada: el celular salta abajo a la derecha, vibra y suena, con el
## nombre en la pantallita. Acción: contestar. Atrás: colgar (si no contesta, también cuelga).
##   LORENA (Lilato, en los sueños): pide plata o molesta. Son los diálogos más chistosos del juego
##   (él es mudo: solo puede respirar). Una por día como mucho; si le cuelga, vuelve a llamar.
##   DESCONOCIDO: a veces es ella desde otro número; si no, créditos, equivocados, encuestas.
## El chiste es la expectativa: cuando suena, uno quiere que sea Lorena.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const RING_TIME := 7.0
const WORLD_SCENES := ["City", "Centro", "Parque"]
const BREATHE := "(Respirar)"
const BREATHE_2 := "(Respirar dos veces)"
const HANG := "(Colgar)"

var _timer := 40.0
var _ringing := false
var _answered := -1  # -1 esperando, 1 contestó, 0 colgó
var _callback := -1.0  # segundos para que Lorena vuelva a llamar (le colgaron)
var _root: Control
var _phone: TextureRect
var _caller: Label
var _hint: Label
var _ring: AudioStreamPlayer


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.visible = false
	add_child(_root)
	var panel := ColorRect.new()
	panel.color = Color(0.07, 0.05, 0.08, 0.92)
	panel.position = Vector2(180, 118)
	panel.size = Vector2(106, 40)
	_root.add_child(panel)
	_label("LLAMADA", Vector2(186, 122), Color(0.6, 0.85, 0.55))
	_caller = _label("", Vector2(186, 133), Color(0.95, 0.8, 0.45))
	_hint = _label(Controls.keys_in("[E]sí [Q]no"), Vector2(186, 145), Color(0.6, 0.57, 0.55))
	_phone = TextureRect.new()
	_phone.texture = load("res://assets/ui/phone.png")
	_phone.position = Vector2(148, 112)
	_root.add_child(_phone)
	_ring = AudioStreamPlayer.new()
	_ring.stream = load("res://assets/audio/ring.wav")
	_ring.volume_db = -6.0
	add_child(_ring)


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	_root.add_child(l)
	return l


func ringing() -> bool:
	return _ringing


func has_phone() -> bool:
	return GameState.count("celular") > 0


func _can_ring() -> bool:
	var scene := get_tree().current_scene
	return has_phone() and scene != null and scene.name in WORLD_SCENES and TimeManager.running \
		and not GameState.input_blocked() and not SceneRouter.busy and not Dialogue.active


func _process(delta: float) -> void:
	if _ringing:
		_phone.position = Vector2(148, 112) + Vector2(randf_range(-1, 1), randf_range(-1, 1))
		return
	if not _can_ring():
		return
	if _callback > 0.0:
		_callback -= delta
		if _callback <= 0.0:
			_callback = -1.0
			call_in("lorena_otra_vez")
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(45.0, 100.0)
	var f := GameState.flags
	if int(f.get("llamadas_dia", -1)) != GameState.day:
		f["llamadas_dia"] = GameState.day
		f["llamadas_hoy"] = 0
		f["lorena_hoy"] = false
	if int(f["llamadas_hoy"]) >= 3 or randf() < 0.35:
		return
	if not f["lorena_hoy"] and randf() < 0.75:
		call_in("lorena")
	else:
		call_in("desconocido")


## Entra una llamada. kind: "lorena", "lorena_otra_vez" (le colgaron) o "desconocido".
func call_in(kind: String) -> void:
	var f := GameState.flags
	f["llamadas_hoy"] = int(f.get("llamadas_hoy", 0)) + 1
	# Lorena a veces llama de otro número ("si le marco del mío no me contesta").
	var hidden := kind == "lorena" and int(f.get("lorena_llamada", 0)) > 1 and randf() < 0.3
	if kind == "desconocido" and int(f.get("lorena_llamada", 0)) > 1 and randf() < 0.25:
		kind = "lorena"
		hidden = true
	_caller.text = "DESCONOCIDO" if (kind == "desconocido" or hidden) else "LORENA"
	if int(f.get("lorena_llamada", 0)) == 0 and kind == "lorena":
		_caller.text = "DESCONOCIDO"  # la primera vez, todavía no tiene el número guardado
	_ringing = true
	_answered = -1
	_root.visible = true
	GameState.ui_open = true
	_ring.play()
	var t := 0.0
	while _answered == -1 and t < RING_TIME:
		await get_tree().process_frame
		t += get_process_delta_time()
		if not _ring.playing:
			_ring.play()
	_ring.stop()
	_ringing = false
	_root.visible = false
	GameState.ui_open = false
	GameState.block_input(0.2)
	if _answered != 1:
		if kind.begins_with("lorena"):
			f["lorena_colgada"] = true
			if int(f["llamadas_hoy"]) < 5:
				_callback = randf_range(12.0, 25.0)  # ella vuelve a llamar. Siempre vuelve.
				Narrator.say("(Deja de sonar. Por ahora.)")
			else:
				Narrator.say("(Deja de sonar. Se le acabó el saldo. A ella. Por fin una buena noticia.)")
		return
	if kind.begins_with("lorena"):
		f["lorena_hoy"] = true
		await _lorena(kind == "lorena_otra_vez", hidden)
	else:
		await _unknown()


func _unhandled_input(event: InputEvent) -> void:
	if not _ringing:
		return
	if event.is_action_pressed("interact"):
		_answered = 1
	elif event.is_action_pressed("cancel"):
		_answered = 0
	else:
		return
	get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- Lorena

func _lorena(again: bool, hidden: bool) -> void:
	var f := GameState.flags
	if again and f.get("lorena_colgada", false):
		f.erase("lorena_colgada")
		await Dialogue.talk([[["LORENA", "—¿ME COLGÓ? ¿A mí? ¿A la madre de su hija? Eso es violencia telefónica. Le voy a poner una tutela por cada pitido."],
			["LORENA", "—Se me cayó la llamada. Bueno, usted me la tumbó. Es igual. Eso es física: acción y reacción, como dijo Isaac Nielsen."],
			["LORENA", "—Le marco otra vez porque soy una persona madura. Mi coach dice que soy la más madura del grupo. El grupo es de WhatsApp, pero igual."]].pick_random()])
		if f.get("lorena_hoy_hecha", -1) == GameState.day:
			await Dialogue.talk([["LORENA", "—Bueno, ya le dije todo lo que le tenía que decir. Es que usted no escucha. Chao. No me llame."]])
			return
	if hidden:
		await Dialogue.talk([["LORENA", "—¿Aló? Jajá. ¿Ve? Si le marco de mi número no me contesta. Este es el de mi vecina. Doña Gladys le manda saludos. Mentira, no lo quiere."]])
	f["lorena_hoy_hecha"] = GameState.day
	var n := int(f.get("lorena_llamada", 0))
	f["lorena_llamada"] = n + 1
	var calls := [_l_numero, _l_tenis, _l_horoscopo, _l_tutela, _l_coaching, _l_miami, _l_perro, _l_aguacate,
		_l_ansiedad, _l_cumple]
	if n < calls.size():
		await calls[n].call()
	else:
		await _l_cualquiera()


## Una ronda de respiración: devuelve qué hizo él (0 respirar, 1 dos veces, 2 colgar).
func _breath(lines: Array) -> int:
	var i := await Dialogue.talk(lines, [BREATHE, BREATHE_2, HANG])
	if i == 2:
		await Dialogue.talk([["", "(Cuelga.)"]])
		GameState.flags["lorena_colgada"] = true
		_callback = randf_range(10.0, 20.0)
	return i


func _l_numero() -> void:
	var i := await _breath([
		["LORENA", "—¿Aló? ¿Aló? ... Ah, sí es usted. Respira igualito. Como un perro con sinusitis."],
		["LORENA", "—¿Que cómo conseguí el número? Tengo mis contactos. Bueno, un contacto. Bueno, se lo pregunté a don Efraín. Bueno, se lo pagué. Con plata suya, entonces técnicamente usted me lo dio."],
		["LORENA", "—Lo llamaba para algo importantísimo. ... Ya se me olvidó. Usted me desconcentra con ese silencio tan agresivo."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—No me respire así, que yo me sé su repertorio. Ese es el respiro de 'no tengo plata'. Lo tengo catalogado. Tengo once."],
		["LORENA", "—Ya me acordé: necesito cien mil. Para qué, no le digo, porque es mi vida privada. Artículo quince de la Constitución: el de la privacidad y el de las quinceañeras."],
		["LORENA", "—Bueno, chao. Y no me vuelva a llamar."]])


func _l_tenis() -> void:
	var i := await _breath([
		["LORENA", "—Victoria necesita unos tenis para educación física. ... Física cuántica, ¿sí me entiende? Es un colegio bueno."],
		["LORENA", "—Tienen que ser de los que prenden lucecitas, porque si no la profesora no la ve. Son doscientos mil. Bueno, ochenta. Bueno, lo que tenga."],
		["LORENA", "—Mándeme una foto de lo que tiene y yo le digo cuánto es."]])
	if i == 2:
		return
	if i == 1:
		await Dialogue.talk([
			["LORENA", "—¿Dos veces? ¿Eso es un sí? Hagamos así: una vez es 'sí' y dos es 'sí, Lorena, ya mismo'."],
			["LORENA", "—Perfecto. Se lo anoto en el cuaderno. El cuaderno de lo que me debe. Ya va en el tomo dos. El tomo uno lo perdí, así que cuenta doble."]])
	else:
		await Dialogue.talk([
			["LORENA", "—Una sola respiración. Tacaño hasta para el aire. Por eso no tiene amigos. Bueno, tiene un perro. Eso no cuenta, el perro está por la comida."]])


func _l_horoscopo() -> void:
	var i := await _breath([
		["LORENA", "—Le leo el horóscopo. Escorpio: 'Hoy cobre lo que le deben'. Ese es el mío."],
		["LORENA", "—Usted es Géminis, que son dos personas, o sea que me debe el doble. Eso no lo digo yo, lo dicen los astros. Y los astros no tienen por qué mentir: no tienen hijos."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—Y dice: 'Número de la suerte: cien mil'. ¿Ve? Hasta el horóscopo está de mi lado. El horóscopo y Dios. Y mi mamá. Usted solo tiene al perro y el perro no vota."]])


func _l_tutela() -> void:
	var i := await _breath([
		["LORENA", "—Le voy a poner una tutela. Una de esas con sello, notariada y apostillada. Apostillada viene de apóstol: es una tutela bendecida. Contra eso no puede ni el Papa."],
		["LORENA", "—Mi abogado dice que su silencio es tácito. Que es como táctico pero sin tácticas. O sea que usted está perdido."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—Y no es mi primo. Es mi primo político. Que es diferente, porque vota."],
		["LORENA", "—La tutela sale en tres días hábiles. Hábiles para mí. Para usted son días de estar asustado. Vaya preparando el pecho. Y la plata."]])


func _l_coaching() -> void:
	var i := await _breath([
		["LORENA", "—Me metí a un curso de coaching ontológico. Ontológico de ontología, que es lo de los dientes."],
		["LORENA", "—Ya entiendo todo: usted es un hombre tóxico. Como el tóxico de las uñas. Yo soy un sistema, Victoria es un sistema, y usted es el virus del sistema. Como el de los computadores."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—El curso cuesta trescientos mil y me va a sanar. Si me sano yo, se sana Victoria. Somos como el sistema solar. Yo soy el sol, obvio."],
		["LORENA", "—Así que en el fondo usted me debe el curso. Es una inversión en su hija. Y en el sol."]])


func _l_miami() -> void:
	var i := await _breath([
		["LORENA", "—Me voy para Miami. Bueno, no me voy. Me estoy visualizando. El curso dice que uno se visualiza y el universo le paga los tiquetes."],
		["LORENA", "—Miami no queda en Estados Unidos, queda en la Florida. Usted no sabe porque nunca ha ido a ningún lado."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—Si el universo no paga, paga usted. Usted es como el universo, pero con menos plata y más feo."]])


func _l_perro() -> void:
	var opts := [BREATHE, BREATHE_2, HANG]
	if GameState.lukas_alive():
		opts.insert(2, "(Ponerle el celular a Lukas)")
	var i := await Dialogue.talk([
		["LORENA", "—¿Ese perro todavía está vivo? Victoria dice que se llama Lukas. Yo le digo que se llama 'el perro de su papá', que es como un apellido."],
		["LORENA", "—Un perro come más que un niño. Eso lo leí. Así que si usted puede mantener un perro, puede mandar plata. Esa es la lógica. La lógica es lo de los números."]], opts)
	if opts[i] == HANG:
		await Dialogue.talk([["", "(Cuelga.)"]])
		GameState.flags["lorena_colgada"] = true
		_callback = randf_range(10.0, 20.0)
		return
	if opts[i] == "(Ponerle el celular a Lukas)":
		await Dialogue.talk([
			["", "(Le acerca el celular a Lukas. Lukas lo huele. Ladra una vez, fuerte, directo al micrófono.)"],
			["LORENA", "—¿ME LADRÓ? ¿Usted me puso al perro? Eso es violencia canina. Lo voy a denunciar en el ICBF, que es el de los perros."],
			["", "(Lukas mueve la cola. Sabe lo que hizo. Lo volvería a hacer.)"]])
		GameState.change_mood(4.0)
		return


func _l_aguacate() -> void:
	await Dialogue.talk([
		["LORENA", "—Amor, ¿ya compraste el aguacate? Que esté maduro pero no tanto. Que esté maduro como yo: por dentro."],
		["LORENA", "—... ¿Aló? ... Ay. Me equivoqué. Usted no es él. Él respira con más ganas."]])
	await _breath([["LORENA", "—Bueno, ya que estoy aquí. ¿Tiene cien mil? Es para el aguacate. Están carísimos. Por culpa suya, seguramente."]])


func _l_ansiedad() -> void:
	var i := await _breath([
		["LORENA", "—Me dio un ataque de ansiedad. De esos que dan en las piernas. ... No, eso es la várice. Bueno, también me dio eso. Todo por culpa suya."],
		["LORENA", "—La siquiatra, la de la P muda, me dijo que tengo que poner límites."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—Entonces le pongo un límite: me manda plata hasta el viernes. Ese es el límite. Después del viernes le pongo otro."]])


func _l_cumple() -> void:
	var i := await _breath([
		["LORENA", "—Para el cumpleaños de Victoria voy a hacer una fiesta temática. El tema es 'que el papá pague'. Va a quedar divina."],
		["LORENA", "—Ella quiere una bicicleta. Yo quiero que ella quiera una bicicleta y que usted la compre. Todos queremos algo. Eso lo dijo Gandhi. O Shakira. Una de las dos."]])
	if i == 2:
		return
	await Dialogue.talk([
		["LORENA", "—Y no se le ocurra venir. Bueno, sí venga, pero de lejos. Como el sol. ... No, el sol soy yo. Usted venga como una nube. Una nube con plata."]])


## Después de las diez: una al azar (las de siempre, para que siga dando gusto contestar).
func _l_cualquiera() -> void:
	var lines: Array = [
		[["LORENA", "—Necesito plata para el gas. El gas no se paga solo. Bueno, se paga con el recibo, pero el recibo no se paga solo."]],
		[["LORENA", "—Le cuento que Victoria sacó cinco en matemáticas. Eso lo sacó de mí. Lo de que no le gusta la sopa, de usted."]],
		[["LORENA", "—Estoy en el centro comercial y me acordé de usted. Estaba viendo unos zapatos que no me puedo comprar. Igualito."]],
		[["LORENA", "—Le aviso que voy a demandarlo por daños y perjurios. ... Perjuicios. Bueno, las dos. Por si acaso."]],
		[["LORENA", "—¿Usted me bloqueó en Facebook? ... Ah, no tiene Facebook. ¿Y entonces dónde lo bloqueo yo?"]],
		[["LORENA", "—Me dijeron que usted anda con un perro y una mochila. Que parece un mochilero. Que eso es muy de moda en Europa. Allá por lo menos le darían limosna en euros."]],
	]
	var pick: Array = lines.pick_random()
	await _breath([pick[0]])
	await Dialogue.talk([pick[1], ["LORENA", "—Bueno, chao. No me llame. Yo lo llamo."]])


# ---------------------------------------------------------------- Desconocidos

func _unknown() -> void:
	var calls := [
		[["CREDITOS YA", "—Buenas tardes, le habla Yésica de Créditos Ya. Usted está preaprobado para un crédito de tres millones."],
			["CREDITOS YA", "—¿Señor? ... Bueno, lo dejo preaprobado. Eso ya no se lo quita nadie. Que tenga buen día."]],
		[["DESCONOCIDO", "—¿Pollos Mario? Me manda dos pollos asados, una gaseosa de litro y mucha salsa de ajo."],
			["DESCONOCIDO", "—¿Aló? ¿Pollos? ... Este pollo respira raro. Voy a pedir pizza."]],
		[["RAPIDITO", "—Hola. Su pedido va en camino. Su domiciliario lo está viendo en el mapa. Gracias por usar Rapidito."],
			["", "(Mira para todos lados. Pasa una moto. No se detiene. Esta vez.)"]],
		[["ENCUESTA", "—Encuesta de satisfacción. Del uno al diez, ¿qué tan satisfecho está con su vida? Marque después del tono."],
			["", "(Tono. No marca nada.)"],
			["ENCUESTA", "—Registramos: cero. Gracias por su honestidad. Su opinión es muy importante para nosotros."]],
		[["DESCONOCIDO", "—Mami, soy yo, se me perdió el celular, me están prestando este, mándeme cincuenta mil a este número que..."],
			["DESCONOCIDO", "—... ¿Mami? ... Usted no es mi mamá. Usted respira como un señor."]],
	]
	var i := randi() % calls.size()
	await Dialogue.talk(calls[i])
