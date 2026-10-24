extends Control
## La noche del Día 1 (spec, secciones 24, 25 y 27):
##   1. Se acomoda donde eligió dormir (con Lukas).
##   2. Revisa la mochila: la fotografía. La da vuelta: "Para que nunca olvides de dónde vienes."
##   3. La primera memoria: jugable, en Memory1.tscn (vuelve acá al terminar).
##   4. Resumen del día y FIN DEL CAPITULO 1.
## Del Día 2 en adelante: acomodarse, resumen y la mañana siguiente (GameState.new_day: robos,
## lluvia, la policía). Después despierta en la ciudad, donde durmió ("Wake_<lugar>").
## Botón: avanzar.
## Ningún texto va sobre negro solo: todos llevan su viñeta arriba, animada (cuatro cuadros que se pasan
## despacio: respiran, llueve, gotea, titila). Salen de tools/art/draw_vinetas.py:
##   - una hoja por lugar donde duerme, con una fila por momento: cómo quedó dormido, el sueño que le
##     sale de la cabeza, cómo despierta (al alba, o de noche por un sueño), golpeado (lo robaron, o
##     perdió), y el último amanecer. Cada una, con y sin lluvia, con y sin Lukas;
##   - una hoja de momentos: el que se mete al cambuche, la noche de Lukas, el entierro, el collar.
## Si llueve esa noche se decide al acostarse (_rain_tonight), para que se vea llover en la viñeta.
## Cuando el texto va en el centro (el resumen, la pelea), la viñeta queda detrás, apagada.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CITY := "res://scenes/world/City.tscn"
const MEMORY := "res://scenes/world/Memory1.tscn"
## Los sueños: [id, escena, título (se calcula), cómo se duerme]. Ver el calendario en
## docs/DISENO_CIUDAD_Y_SISTEMAS.md. Se sueñan por hechos de la historia (_dream_when); entre uno y
## otro, como mínimo una noche libre (el torneo de lucha va en noches seguidas: deja expectativa).
## El último (\"final\"): la galería de revanchas y Lilato (ver FinalRush).
const DREAMS := [
	# El beat 'em up (antes era el prólogo): tres sueños. Cada uno es una escena sola: al salir de ella
	# vuelve a la noche (SceneRouter.go la desvía, ver flags.sueno_suelto).
	["callejon1", "res://scenes/prologue/Fight.tscn", "",
		"Se queda dormido. Un callejón con luces de neón. Alguien lo espera con los puños cerrados. Suena una moneda al caer."],
	["camion", "res://scenes/prologue/Truck.tscn", "",
		"Se queda dormido. Un camión de harina arranca. Él va colgado atrás. Vienen motos."],
	["lilato1", "res://scenes/prologue/Lilato.tscn", "",
		"Se queda dormido. Un puente. Llueve. Ella lo espera con un vestido rosado y dos cuchillos."],
	["plomo_d1", "res://scenes/dreams/PlomoDealer1.tscn", "",
		"Se queda dormido. Las manos le pesan. Tienen anillos."],
	["plomo_d2", "res://scenes/dreams/PlomoDealer2.tscn", "",
		"Se queda dormido. Huele a ollas, a químico y a plata."],
	["carrera1", "res://scenes/dreams/Carrera1.tscn", "",
		"Se queda dormido. Suena música de fiesta. Huele a perfume caro."],
	["sigilo1", "res://scenes/dreams/Sigilo1.tscn", "",
		"Se queda dormido. Suena un teléfono de oficina. Nadie contesta. Huele a arepa."],
	["sigilo2", "res://scenes/dreams/Sigilo2.tscn", "",
		"Se queda dormido. Alguien grita en una oficina. Grita su nombre. Mal pronunciado."],
	["sigilo3", "res://scenes/dreams/Sigilo3.tscn", "",
		"Se queda dormido. Un clic de bolígrafo. Alguien anota todo lo que hace."],
	["sigilo4", "res://scenes/dreams/Sigilo4.tscn", "",
		"Se queda dormido. Un ascensor. Último piso. Nadie más adentro."],
	["carrera2", "res://scenes/dreams/Carrera2.tscn", "",
		"Se queda dormido. Una camioneta acelera en algún lado. Con rabia."],
	["callejon3", "res://scenes/dreams/Callejon3.tscn", "",
		"Se queda dormido. Un bus arranca. Esta vez no sabe si correr detrás o tirarle una piedra."],
	["lucha1", "res://scenes/dreams/Lucha1.tscn", "",
		"Se queda dormido. Suena una moto que se va. Es domingo. Hay un ring en el coliseo del barrio."],
	["lucha2", "res://scenes/dreams/Lucha2.tscn", "",
		"Se queda dormido. Otro domingo. Alguien le amarra las botas de lucha."],
	["lucha3", "res://scenes/dreams/Lucha3.tscn", "",
		"Se queda dormido. Huele a gasolina y a chaqueta de cuero."],
	["lucha4", "res://scenes/dreams/Lucha4.tscn", "",
		"Se queda dormido. El garaje está en silencio. Hay uno solo esperando en el ring."],
	["carrera3", "res://scenes/dreams/Carrera3.tscn", "",
		"Se queda dormido. Dos motos lo esperan en la esquina. Las conoce."],
	["plomo_d3", "res://scenes/dreams/PlomoDealer3.tscn", "",
		"Se queda dormido. Alguien grande y verde pregunta en el barrio por Lisandro, al que le dicen el Gato."],
	["carrera4", "res://scenes/dreams/Carrera4.tscn", "",
		"Se queda dormido. Sirenas. Esta vez no son de la calle."],
	["final", "res://scenes/dreams/Callejon3.tscn", "",
		"Se queda dormido. Llueve. Huele a ladrillo mojado, como la primera noche. Esta vez sabe todo."],
]
const DREAM_GAP := 3
## Los que dispara un hecho de la vida real (tienen prioridad sobre los que solo siguen su serie).
## El torneo también va primero, y en noches seguidas (CHAIN_DREAMS): para que no se enfríe.
const EVENT_DREAMS := ["final", "callejon1", "plomo_d1", "plomo_d2", "carrera1", "sigilo1", "callejon3", "lucha1", "lucha2", "lucha3", "lucha4"]
const CHAIN_DREAMS := ["lucha2", "lucha3", "lucha4", "carrera3", "plomo_d3", "carrera4", "final"]
## Al despertar de cada sueño: [si ganó, si perdió, lo que le queda].
const WAKE := {
	"callejon1": ["Se despierta con los nudillos calientes.", "Se despierta con los nudillos calientes.", "Ganó. En los sueños siempre gana. Para eso los tiene."],
	"camion": ["Se despierta agarrado del cartón, con las dos manos.", "Se despierta agarrado del cartón, con las dos manos.", ""],
	"lilato1": ["Se despierta. Llueve de verdad.", "Se despierta. Llueve de verdad.", "CONTINUE? No hay monedas. Nunca hubo."],
	"plomo1": ["Se despierta empapado en sudor.", "Se despierta con la mano buscando un arma que no existe.", "Nunca tuvo un arma. La mano no se ha enterado."],
	"plomo_d1": ["Se despierta mirándose las manos. Las cuenta. Diez dedos, ningún anillo.", "Se despierta con sabor a metal en la boca.", ""],
	"plomo_d2": ["Se despierta con la nariz ardiendo.", "Se despierta con ganas de algo que no va a comprar.", ""],
	"plomo_d3": ["Se despierta de pie. No sabe cuándo se paró. Lukas lo mira desde el cartón.", "Se despierta con las manos cerradas sobre una escopeta que no está.", ""],
	"sigilo1": ["Se despierta y se busca algo en la espalda.", "Se despierta con la sensación de que lo están mirando.", ""],
	"sigilo2": ["Se despierta en silencio.", "Se despierta con gritos en la cabeza.", ""],
	"sigilo3": ["Se despierta y se mira la mano, como si tuviera algo escrito.", "Se despierta tapándose la cara.", ""],
	"sigilo4": ["Se despierta tocándose el cuello. No hay carné.", "Se despierta con el ascensor todavía bajando en el estómago.", "Lunes, 7:58. El cuerpo todavía marca tarjeta."],
	"final": ["Se despierta.", "Se despierta empapado.", ""],
	"carrera1": ["Se despierta y se lava la cara dos veces.", "Se despierta tocándose la frente.", ""],
	"carrera2": ["Se despierta con el ruido de una camioneta que no está.", "Se despierta con el ruido de una camioneta que no está.", ""],
	"carrera3": ["Se despierta con los nudillos rojos.", "Se despierta con los puños apretados.", "Huele a Carolina Herrera. No hay nadie. Es la memoria, que es muy cara."],
	"plomo_dealer": ["Se despierta mirándose las manos. Las cuenta.", "Se despierta con la boca seca.", ""],
	"carrera4": ["Se despierta. Lukas le lame la mano.", "Se despierta tapándose los oídos. Lukas le gruñe a la nada.", ""],
	"plomo2": ["Se despierta tocándose el cuello.", "Se despierta tocándose el cuello.", ""],
	"plomo3": ["Se despierta. Busca a Lukas con la mano. Está ahí.", "Se despierta. Busca a Lukas con la mano. Está ahí.", ""],
	"callejon3": ["Se despierta con hambre.", "Se despierta con hambre.", "Sopa de pasta con papa y mucho cilantro. No hay. Nunca hay lo que uno sueña."],
	"lucha1": ["Se despierta con la espalda doblada.", "Se despierta con la mandíbula floja.", "Le duele un músculo que no sabía que tenía. Probablemente el de los domingos."],
	"lucha2": ["Se despierta sentado de golpe.", "Se despierta con la cabeza dando vueltas.", ""],
	"lucha3": ["Se despierta sentado de golpe.", "Se despierta con una moto sonando en la cabeza.", ""],
	"lucha4": ["Se despierta con los puños cerrados. Le duelen.", "Se despierta con la mandíbula apretada.", ""],
}
## Cómo se acomoda en cada sitio (cambia cada noche: GameState.rota).
const SETTLE := {
	"banco": ["Banco de plaza. Espalda contra la pared. Lukas abajo, de guardia.",
		"Banco de plaza. El de la tinta roja que dice CAMILO + YURI. Camilo y Yuri ya no se hablan. El banco sigue.",
		"Banco de plaza. La paloma de siempre ya le tiene confianza: se le duerme en el espaldar. Lukas la vigila.",
		"Banco de plaza. Un borracho le pide permiso para la otra punta. Ronca en la otra punta. Lukas, en la mitad."],
	"kiosco": ["El kiosco gotea en una esquina. Se acomoda en la otra. Lukas se le pega a la espalda.",
		"El kiosco. Todavía dice MINUTOS A 200. Hace años que nadie vende minutos. Él tampoco tiene a quién llamar.",
		"El kiosco. Lukas le gana la esquina seca. Él se queda con la que gotea: el que manda, manda.",
		"El kiosco. Alguien escribió AQUÍ VIVO YO en la pared de adentro. Por si acaso, duerme mirando la puerta."],
	"rio": ["El cambuche. Huele a humedad. Lukas se le acuesta en los pies.",
		"El cambuche. El río suena a carretera. Lukas da tres vueltas antes de echarse. Siempre tres.",
		"El cambuche. Una rata pasa por el techo de plástico. Lukas la oye. Decide que hoy no.",
		"El cambuche. Arregla una esquina del plástico. Mañana se va a volver a soltar. Es el trato."],
	"callejon": ["El callejón. Seco, oscuro. Del billar salen de a tres. Lukas duerme con una oreja parada.",
		"El callejón. Del billar sale una ranchera y un tipo que la canta peor. Lukas aúlla con él. Le pagan con un pan.",
		"El callejón. Una gata pasa por encima de los dos sin pedir permiso. Lukas finge que no la vio.",
		"El callejón. Se acuesta debajo del aviso de NO ORINAR. Es el pedazo más seco: nadie le hace caso al aviso."],
	"lote": ["El lote. Nadie pasa. Se oye el río y, a ratos, el carro quemado, que cruje solo. Lukas se le pega.",
		"El lote. Los cocuyos prenden y apagan. Lukas les ladra a todos, uno por uno.",
		"El lote. El carro quemado todavía tiene el ambientador de pino colgado. Huele a pino quemado.",
		"El lote. Una lechuza en el poste. Lo mira toda la noche. Él la mira. Gana la lechuza."],
	"parque": ["El parque. Los columpios crujen solos con el viento.",
		"El parque. El celador de la tienda de enfrente lo saluda con la linterna. Es lo más parecido a un buenas noches.",
		"El parque. Lukas se mete debajo del rodadero. Él, al lado. El rodadero hace de techo y de cobija.",
		"El parque. Riegan el pasto a las dos de la mañana. A los dos, también."],
	"pension": ["Una cama. Con colchón. Con sábanas. Lukas debajo, sin respirar.",
		"Una cama. Lukas debajo, quieto: la de la pensión no puede saber. Lukas lo sabe.",
		"Una cama. El de la pieza de al lado ve novela con el volumen a todo. Él se queda con el final.",
		"Una cama. No se acuerda de cómo se duerme en una. Lo resuelve en el piso, al lado de Lukas."],
}
## Las mismas noches, sin Lukas.
const SETTLE_SOLO := {
	"banco": ["Banco de plaza. Espalda contra la pared. Nadie abajo.",
		"Banco de plaza. Pone la mochila donde se echaba Lukas. La mochila no cuida.",
		"Banco de plaza. La paloma de siempre baja al piso, al puesto de Lukas. No le dura."],
	"kiosco": ["El kiosco gotea en una esquina. Se acomoda en la otra. La espalda, fría.",
		"El kiosco. Le sobra la esquina seca. Duerme en la que gotea, por costumbre.",
		"El kiosco. Se despierta a las tres buscando con la mano. Sigue durmiendo con la mano ahí."],
	"rio": ["El cambuche. Huele a humedad. Los pies, sin peso encima.",
		"El cambuche. La rata del techo pasa tranquila. Ya nadie la oye.",
		"El cambuche. Da tres vueltas antes de acostarse. No sabe de quién lo aprendió. Sí sabe."],
	"callejon": ["El callejón. Del billar salen de a tres. Nadie con la oreja parada.",
		"El callejón. La gata pasa por encima. Esta vez nadie finge no verla.",
		"El callejón. Del billar sale una ranchera. Nadie aúlla. Le queda mal la ranchera."],
	"lote": ["El lote. Nadie pasa. Se oye el río. Eso es todo lo que se oye.",
		"El lote. Los cocuyos prenden y apagan. Nadie les ladra. Siguen igual, sin público.",
		"El lote. La lechuza del poste. Ahora le gana más rápido."],
	"parque": ["El parque. Desde aquí se ve el árbol de flores amarillas.",
		"El parque. Duerme debajo del rodadero. Le sobra rodadero.",
		"El parque. El celador lo saluda con la linterna. Alumbra al lado, buscando al perro. Apaga."],
	"pension": ["Una cama. Debajo, nadie. Duerme en la mitad.",
		"Una cama. Ya no tiene a quién esconder. Igual cierra la puerta despacito.",
		"Una cama. Duerme en el piso igual. El piso es donde está la costumbre."],
}
const SPOT_NAMES := {"banco": "el banco de la plaza", "kiosco": "el kiosco viejo", "rio": "el cambuche del puente",
	"callejon": "el callejón", "parque": "el parque", "pension": "la pensión", "lote": "el lote del fondo"}

var _bg: ColorRect
var _text: Label
var _photo: TextureRect
var _pic: Vineta  # la viñeta de arriba
var _go := false


func _ready() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.03, 0.03, 0.05)
	_bg.size = Vector2(320, 180)
	add_child(_bg)
	_photo = TextureRect.new()
	_photo.position = Vector2(100, 30)
	_photo.pivot_offset = Vector2(60, 44)  # se da vuelta desde el centro
	_photo.modulate.a = 0.0
	add_child(_photo)
	_pic = Vineta.new()
	_pic.position = Vector2(40, 10)  # (agrandada 1.2 alrededor de su centro: ocupa de 16 a 304, de 0 a 120)
	_pic.pivot_offset = Vector2(120, 50)
	_pic.scale = Vector2(PIC_SCALE, PIC_SCALE)
	_pic.modulate.a = 0.0
	add_child(_pic)
	_text = Label.new()
	_text.add_theme_font_override("font", FONT)
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	_text.add_theme_constant_override("outline_size", 3)  # se lee también encima de una viñeta apagada
	_text.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04))
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(16, 123)
	_text.size = Vector2(_text_w(), 56)
	add_child(_text)
	_text.add_to_group("under_dialogue")
	_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
		_go = true


func _wait() -> void:
	_go = false
	while not _go:
		if not is_inside_tree():
			return
		await get_tree().process_frame


## Muestra la fila `row` de la hoja `sheet` (ver scripts/ui/Vineta.gd): entra despacio y se acerca un
## poquito mientras se lee. dim < 1: queda de fondo, apagada (el texto va encima, en el centro; no lo mueve).
const PIC_SCALE := 1.2  # las viñetas, grandes: casi toda la pantalla


func _show_pic(sheet: String, row: int, dim := 1.0) -> void:
	_pic.show_row(sheet, row)
	_pic.scale = Vector2(PIC_SCALE, PIC_SCALE)
	var t := create_tween()
	t.tween_property(_pic, "modulate", Color(dim, dim, dim, 1.0), 1.2 if _pic.modulate.a < 0.5 else 0.5)
	t.parallel().tween_property(_pic, "scale", Vector2(PIC_SCALE * 1.03, PIC_SCALE * 1.03), 9.0)
	if dim >= 1.0:
		_text.position = Vector2(16, 123)
		_text.size = Vector2(_text_w(), 56)


## La viñeta del lugar donde durmió. kind: "dormir", "sueno", "despierta" o "golpeado"; time: "noche"
## o "alba"; con o sin lluvia. Sin Lukas, la misma, sin él.
func _spot_pic(spot: String, kind: String, time: String, rain: bool, dim := 1.0) -> void:
	_show_pic(spot if spot in Vineta.SPOTS else "banco", Vineta.spot_row(kind, time, rain, not GameState.lukas_alive()), dim)


func _moment(row: int, dim := 1.0) -> void:
	_show_pic("momentos", row, dim)


## ¿Llueve esta noche? Se decide al acostarse (para que se vea); GameState.new_day usa lo mismo.
func _rain_tonight() -> bool:
	var f := GameState.flags
	if f.get("lluvia_noche_dia", -1) != GameState.day:
		f["lluvia_noche_dia"] = GameState.day
		f["lluvia_noche"] = randf() < 0.3
	return f["lluvia_noche"]


func _vignette_off() -> void:
	if _pic.modulate.a > 0.0:
		create_tween().tween_property(_pic, "modulate:a", 0.0, 0.6)


func _say(line: String) -> void:
	_text.text = line
	_text.visible_ratio = 0.0
	var t := create_tween()
	t.tween_property(_text, "visible_ratio", 1.0, line.length() / 40.0)
	await t.finished
	await _wait()


func _run() -> void:
	var spot: String = GameState.flags.get("sleep_spot", "banco")
	await get_tree().create_timer(0.8).timeout
	# Vuelve de un sueño: se despierta y sigue la noche.
	var back: String = str(GameState.flags.get("dream_return", ""))
	if back != "":
		GameState.flags.erase("dream_return")
		# Después del último sueño, no se despierta.
		if back == "final" and GameState.flags.get("lilato_destruida", false):
			await _he_dies()
			return
		# Una pelea del torneo perdida: la revancha vuelve otra noche (el torneo no sigue sin ella).
		# Si la perdió, la revancha espera dos noches (si no, una pelea perdida tapaba todos los otros sueños).
		if back.begins_with("lucha") and not GameState.flags.get("dream_won", true):
			var seen_b: Array = GameState.flags.get("dreams_seen", [])
			seen_b.erase(back)
			GameState.flags["lucha_revancha_dia"] = GameState.day + 3
		var w: Array = WAKE.get(back, ["Se despierta.", "Se despierta.", ""]).duplicate()
		if not GameState.flags.get("dream_won", true):
			_spot_pic(spot, "golpeado", "noche", _rain_tonight())  # perdió: se despierta como si le hubieran pegado
		else:
			_spot_pic(spot, "despierta", "noche", _rain_tonight())
		if not GameState.lukas_alive():
			for k in w.size():
				if str(w[k]).contains("Lukas"):
					w[k] = "Se despierta y busca a Lukas con la mano. No está."
		await _say(w[0] if GameState.flags.get("dream_won", true) else w[1])
		if w[2] != "":
			await _say(w[2])
		# Lo que aprendió soñando (le sirve en los dos mundos).
		var skill: String = Skills.DREAM_SKILL.get(back, "")
		if skill != "" and GameState.learn(skill):
			_spot_pic(spot, "sueno", "noche", _rain_tonight(), 0.3)
			GameState.flags.erase("skill_toast")
			_text.position = Vector2(16, 50)
			_text.size = Vector2(_text_w(), 120)
			await _say("Algo aprendió en el sueño.\nHABILIDAD: %s\n%s" % [Skills.name_of(skill).to_upper(), Skills.desc(skill)])
		await _summary(spot)
		return
	# Del Día 2 en adelante: corto.
	if GameState.day >= 2:
		var settle: Dictionary = SETTLE if GameState.lukas_alive() else SETTLE_SOLO
		_spot_pic(spot, "dormir", "noche", _rain_tonight())
		await _say(GameState.rota("settle_" + spot, settle.get(spot, settle["banco"])))
		if _rain_tonight():
			await _say(GameState.rota("llueve_techo", ["Empieza a llover. Aquí, por una vez, no.",
				"Empieza a llover. Él oye el agua desde adentro, como la gente de casa.",
				"Empieza a llover. El techo suena a aplauso. No es para él, pero lo coge."])
				if GameState.roofed(spot) else GameState.rota("llueve", ["Empieza a llover. No hay para dónde correrse.",
				"Empieza a llover. Se tapa con el cartón. El cartón dura veinte minutos. Él, el resto.",
				"Empieza a llover. Lukas se le mete debajo de la chaqueta. Quedan mojados los dos, pero juntos." if GameState.lukas_alive()
					else "Empieza a llover. Se mete la mano al bolsillo, donde tiene el collar. Que eso no se moje.",
				"Empieza a llover. Primero gotas gordas, después de todas. El cielo no tiene término medio.",
				"Empieza a llover. Alguien en un segundo piso cierra la ventana. Suena como una puerta en la cara."]))
		# Volvió a acostarse después de buscar a Lukas por el barrio: sigue la misma noche.
		if GameState.flags.get("lombardia_vuelta", false):
			GameState.flags.erase("lombardia_vuelta")
			await _say("Vuelve a acostarse. Lukas se le echa encima, con olor a salchicha. A él no le importa.")
			await _summary(spot)
			return
		# Una noche, Lukas se le va: lo despierta el frío y sale a buscarlo (Lombardía de noche).
		if _lombardia_tonight():
			await _lombardia(spot)
			return
		# La noche en que Lukas se muere (no hay sueño esa noche).
		if GameState.lukas_dies_tonight():
			await _lukas_dies()
			await _summary(spot)
			return
		# Algunas noches, un sueño (otro juego).
		var dream := _dream_tonight()
		if not dream.is_empty():
			var seen: Array = GameState.flags.get("dreams_seen", [])
			seen.append(dream[0])
			GameState.flags["dreams_seen"] = seen
			GameState.flags["last_dream_day"] = GameState.day
			GameState.flags["dream_day_" + dream[0]] = GameState.day
			_spot_pic(spot, "sueno", "noche", _rain_tonight())
			await _say(dream[3])
			if dream[0] == "final":
				FinalRush.begin()
				return
			if dream[0] in ["callejon1", "camion", "lilato1"]:
				GameState.flags["sueno_suelto"] = [dream[0], dream[1]]
				Dream.reset()
			SceneRouter.go(dream[1])  # sin "SUEÑO 1": que sea una sorpresa
			return
		await _summary(spot)
		return
	# Vuelve de la memoria jugable: sigue con el resumen.
	if GameState.flags.get("memory_1_seen", false):
		_spot_pic(spot, "dormir", "noche", _rain_tonight())
		await _say("Cierra los ojos.")
		await _summary(spot)
		return
	_spot_pic(spot, "dormir", "noche", _rain_tonight())
	await _say(str(SETTLE.get(spot, SETTLE["banco"])[0]))
	_vignette_off()
	# La fotografía.
	_photo.texture = load("res://assets/items/foto_frente.png")
	create_tween().tween_property(_photo, "modulate:a", 1.0, 1.0)
	await _say("La fotografía. Él de chico, con una pelota. Alguien le tiene la mano en el hombro.")
	await _say("La cara de esa persona no está. La foto está rota justo ahí.")
	var flip := create_tween()
	flip.tween_property(_photo, "scale:x", 0.0, 0.25)
	flip.tween_callback(_show_back)
	flip.tween_property(_photo, "scale:x", 1.0, 0.25)
	await flip.finished
	await _say("Atrás, con letra de alguien:\n\"Para que nunca olvides de dónde vienes.\"")
	create_tween().tween_property(_photo, "modulate:a", 0.0, 0.8)
	await _say("Mira la foto un rato largo.")
	# La primera memoria, jugable (Memory1.tscn); al terminar vuelve acá.
	SceneRouter.go(MEMORY)


## El dorso: la frase escrita a mano sobre el papel.
func _show_back() -> void:
	_photo.texture = load("res://assets/items/foto_dorso.png")
	var ink := Label.new()
	ink.text = "Para que nunca olvides de donde vienes."
	ink.add_theme_font_override("font", FONT)
	ink.add_theme_font_size_override("font_size", 8)
	ink.add_theme_color_override("font_color", Color(0.25, 0.2, 0.3))
	ink.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ink.position = Vector2(8, 38)
	ink.size = Vector2(106, 48)
	ink.rotation = -0.04
	_photo.add_child(ink)


## La noche de Lombardía: una sola vez, desde el día 8, con Lukas sano. Él se despierta solo.
func _lombardia_tonight() -> bool:
	var f := GameState.flags
	return GameState.day >= 8 and not f.get("lombardia_hecha", false) and GameState.lukas_alive() \
		and GameState.lukas_stage() == 0


func _lombardia(spot: String) -> void:
	var f := GameState.flags
	f["lombardia_hecha"] = true
	f["lombardia_activa"] = true
	_show_pic(spot if spot in Vineta.SPOTS else "banco", Vineta.spot_row("despierta", "noche", _rain_tonight(), true))
	await _say("A la una y diez lo despierta el frío del lado izquierdo. El lado de Lukas.")
	await _say("Lukas no está.")
	await _say("Lejos, para el lado de la avenida, un ladrido. Ese ladrido lo reconoce hasta dormido.")
	GameState.start_quest("noche_lukas")
	TimeManager.set_time(1, 10)
	SceneRouter.go(CITY, "Wake_" + spot, "LOMBARDIA — 01:10", "(Lombardía de noche es otro barrio. El mismo, pero con el volumen al revés.)")


func _summary(spot: String) -> void:
	_spot_pic(spot, "dormir", "noche", _rain_tonight(), 0.3)
	var s := GameState.stats
	_text.position = Vector2(16, 40)
	_text.size = Vector2(_text_w(), 120)
	await _say("DIA %d\n\nDinero conseguido: $%d\nComida: %d\nDurmió en %s\nPecho: %s" % [
		GameState.day, s["money_earned"], s["food_eaten"], SPOT_NAMES.get(spot, "la calle"),
		GameState.TOS_PECHO[GameState.tos_stage()]])
	if GameState.has_cambuche():
		await _say("Cambuche: %s (nivel %d)" % [GameState.CAMBUCHE_NAMES[GameState.cambuche_level()], GameState.cambuche_level()])
	var first := GameState.day == 1
	if first:
		await _say("FIN DEL CAPITULO 1")
	if not first and GameState.intruder_tonight(spot):
		await _defend(spot)
	await _morning(spot, first)


## La mañana siguiente: lo que pasó de noche, y a la ciudad.
## Después del último sueño. No se despierta. (El epílogo: los que lo querían, y los demás.)
func _he_dies() -> void:
	MusicDirector.force("")
	var spot: String = GameState.flags.get("sleep_spot", "banco")
	_show_pic(spot if spot in Vineta.SPOTS else "banco", Vineta.FINAL)
	var lines := ["Esa noche, después del último sueño, no se despierta."]
	if GameState.tos_stage() >= 1:
		lines.append("A las cuatro de la mañana se le calla la tos. Nadie la oye callarse.")
	lines.append("Samuel lo encuentra al amanecer, en %s. Con el collar de Lukas en la mano, apretado." % SPOT_NAMES.get(spot, "la calle"))
	if GameState.flags.get("bici_comprada", false):
		lines.append("Al lado, una bicicleta envuelta en papel de globos. Los dobleces, como le enseñaron: uno que nadie ve. Tiene un moño hecho con la cinta de un casete."
			if GameState.flags.get("papel_regalo", false)
			else "Al lado, envuelta en bolsas negras, una bicicleta verde agua. Tiene un moño hecho con la cinta de un casete.")
	lines.append("Tiene cara de haber ganado algo. Nadie va a saber qué.")
	for line in lines:
		await _say(line)
	GameState.flags["murio"] = true
	SceneRouter.go("res://scenes/world/Epilogo.tscn")


## La noche en que se muere Lukas. Sin chistes: el narrador.
func _lukas_dies() -> void:
	var f := GameState.flags
	f["lukas_muerto"] = GameState.day
	MusicDirector.force("")
	var pics := [Vineta.M.LUKAS_PECHO, -1, -1, Vineta.M.LUKAS_QUIETO, -1, Vineta.M.ENTIERRO, -1, Vineta.M.COLLAR]
	var n := 0
	for line in [
		"Esa noche Lukas no se acuesta en los pies. Se acuesta en el pecho. Nunca hacía eso.",
		"Respira rápido. Después despacio. Él le pone la mano en el lomo. No le dice nada. Nunca le dijo nada. Lukas entendía igual.",
		"Lukas mueve la cola una vez.",
		"Antes de que aclare, ya no respira.",
		"Él no llora. Se queda quieto, con la mano en el lomo tibio, hasta que el lomo deja de estar tibio.",
		"Samuel llega con una pala que nadie sabe de dónde sacó. No dice nada. No hace falta.",
		"Lo entierran en el Parque de San Judas, debajo del árbol de flores amarillas. Doña Leonor deja un clavel. El Padre no pregunta si los perros tienen alma: dice que sí.",
		"Él se queda con el collar. Lo amarra a la mochila.",
	]:
		if pics[n] >= 0:
			_moment(pics[n])
		n += 1
		await _say(line)
	GameState.add_item("collar_lukas")
	GameState.change_mood(-30.0)
	GameState.add_locura(3)
	for q in ["lukas_agua", "lukas_comida"]:
		GameState.quests.erase(q)


## Alguien se mete al cambuche mientras duerme: tres reacciones rápidas (la flecha que diga).
## La alarma da más tiempo; con Lukas de guardia, el primero ya está ganado; la trampa lo castiga.
func _defend(spot: String) -> void:
	_moment(Vineta.M.INTRUSO if GameState.lukas_alive() else Vineta.M.INTRUSO_SOLO, 0.45)
	var c := GameState.cambuche
	_text.position = Vector2(16, 60)
	_text.size = Vector2(_text_w(), 80)
	MusicDirector.force("")
	await _say("Un ruido. Alguien está revolviendo la caja del cambuche.")
	if c.get("alarma", false):
		await _say("Las latas suenan. La alarma. Se despierta antes de que el otro se dé cuenta.")
	if GameState.flags.get("samuel_cuida_day", -1) == GameState.day:
		await _say("Un silbido en la oscuridad. Samuel.")
	var window := 1.0 + (0.45 if c.get("alarma", false) else 0.0) + (0.3 if GameState.flags.get("samuel_cuida_day", -1) == GameState.day else 0.0)
	var keys := {"move_left": "IZQUIERDA", "move_right": "DERECHA", "move_up": "ARRIBA", "move_down": "ABAJO"}
	var hits := 0
	for r in 3:
		if r == 0 and GameState.lukas_on_guard():
			await _say("Lukas ya está encima de él, gruñendo. Le muerde el pantalón.")
			hits += 1
			continue
		if r == 1 and GameState.lukas_knows("muerto") and not GameState.lukas_sick():
			await _say("Lukas se tira de lado, quieto, con la lengua afuera. El ladrón se congela: \"¿Lo maté?\". Se le cae lo que llevaba.")
			hits += 1
			continue
		var want: String = keys.keys().pick_random()
		_text.text = "¡%s!" % keys[want]
		_text.visible_ratio = 1.0
		_text.modulate = Color(1.0, 0.35, 0.3)
		var base := _text.position
		var t := 0.0
		var ok := false
		await get_tree().process_frame
		while t < window:
			if not is_inside_tree():
				return
			await get_tree().process_frame
			t += get_process_delta_time()
			_text.position = base + Vector2(randf_range(-2, 2), randf_range(-1, 1))  # tiembla
			var pressed := ""
			for k in keys:
				if Input.is_action_just_pressed(k):
					pressed = k
			if pressed != "":
				ok = pressed == want
				break
		_text.position = base
		_text.modulate = Color(1, 1, 1)
		if ok:
			hits += 1
		_text.text = ["Le da con el palo.", "Lo empuja contra el cartón.", "Se le para enfrente. No dice nada. Eso asusta más que un grito."][r] if ok \
			else ["Lo empuja.", "Se le escapa por un lado.", "Le pega en la cara."][r]
		await get_tree().create_timer(0.7).timeout
	var won := hits >= 2
	GameState.flags["defense_result"] = "won" if won else "lost"
	if won:
		var line := "Se va corriendo. Dejó una chancla."
		if c.get("trampa", false):
			line = "Sale corriendo y pisa la tabla con clavos. El grito se oye hasta el puente."
		elif GameState.lukas_on_guard():
			line = "Lukas lo persigue hasta la esquina y vuelve moviendo la cola."
		GameState.change_mood(4.0)
		await _say(line)
	else:
		await _say("Se fue con lo que alcanzó a agarrar.")
	await _say("No vuelve a dormir. Se queda mirando la oscuridad hasta que aclara.")


func _morning(spot: String, first: bool) -> void:
	_text.position = Vector2(16, 123)
	_text.size = Vector2(_text_w(), 56)
	var lost_fight: bool = str(GameState.flags.get("defense_result", "")) == "lost"
	var lines: Array = GameState.new_day(spot)
	var robbed := lost_fight
	var rained := false
	for line in lines:
		if str(line).contains("menos") or str(line).contains("Se llevaron") or str(line).contains("Abrieron"):
			robbed = true
		if str(line).contains("Llovió"):
			rained = true
	_spot_pic(spot, "golpeado" if robbed else "despierta", "alba", rained)
	for line in lines:
		await _say(line)
	if first:
		await _say("Victoria, su hija, cumple doce años el 29 de octubre. En siete semanas.\nMeta: $150.000 para un regalo. Tiene $%d." % GameState.money)
	TimeManager.set_time(6, 30)
	SceneRouter.go(CITY, "Wake_" + spot, "DIA %d — 06:30" % GameState.day)


## El próximo sueño de la lista, si ya pasó lo que lo dispara (y pasaron dos noches del último).
func _dream_tonight() -> Array:
	var f := GameState.flags
	var since := GameState.day - int(f.get("last_dream_day", -99))
	if since < 1:
		return []
	var seen: Array = f.get("dreams_seen", [])
	# El último sueño le gana a todo (también a una revancha pendiente del torneo): si no, una pelea
	# perdida noche tras noche lo tapaba y el juego no terminaba nunca.
	if not "final" in seen and _dream_when("final"):
		return DREAMS[DREAMS.size() - 1]
	# Primero los que dispara un hecho de la vida real (la llamada, el papá, la cédula...): se sueñan
	# esa misma noche o la siguiente libre. Después, los que solo siguen su serie.
	for pass_events in [true, false]:
		for d in DREAMS:
			if d[0] in seen or (d[0] in EVENT_DREAMS) != pass_events:
				continue
			if since < DREAM_GAP and not d[0] in CHAIN_DREAMS:
				continue
			if _dream_when(d[0]):
				return d
	return []


## Lo que dispara cada sueño.
func _dream_when(id: String) -> bool:
	var f := GameState.flags
	var seen: Array = f.get("dreams_seen", [])
	if id.begins_with("lucha") and GameState.day < int(f.get("lucha_revancha_dia", 0)):
		return false  # revancha: todavía no
	match id:
		"callejon1":  # la segunda noche: el primer sueño
			return GameState.day >= 2
		"camion":  # tres días después
			return "callejon1" in seen and _days_since("callejon1") >= 3
		"lilato1":
			return "camion" in seen and _days_since("camion") >= 3
		"plomo_d1":  # se abre el centro (la cédula): volver a "existir" despierta al que lo quiso borrar
			return f.get("centro_open", false)
		"plomo_d2":  # algo violento en la vida real (el señor de negro, un robo de noche); si no, a los 4 días
			return "plomo_d1" in seen and (f.get("violencia", false) or _days_since("plomo_d1") >= 4)
		"carrera1":  # ya tiene la cédula: aparecen los que lo traicionaron
			return GameState.count("cedula") > 0
		"carrera2", "carrera3", "carrera4":  # tres días después del anterior (la 3, la noche siguiente a la 2)
			var prev := "carrera%d" % (int(id.right(1)) - 1)
			return prev in seen and _days_since(prev) >= (1 if id == "carrera3" else 3)
		"plomo_d3":  # después de ganarles a Camila y Guillermo juntos, vuelve el que los juntó
			return "carrera3" in seen and _days_since("carrera3") >= 1
		"sigilo1":  # la obra está lista: el miedo a que se repita lo de la empresa
			return f.get("obra_ready", false)
		"sigilo2", "sigilo3", "sigilo4":  # tres días después del anterior
			var prev_s := "sigilo%d" % (int(id.right(1)) - 1)
			return prev_s in seen and _days_since(prev_s) >= 3
		"final":  # la noche del día 49, siempre: la víspera del cumpleaños. Esa noche no se despierta (el
			# final que escogió el usuario: alcanza a comprar la bicicleta y no a entregarla).
			return GameState.day >= 49
		"callejon3":  # llamó a la mamá
			return f.get("llamo_mama", false)
		"lucha1":  # el papá no lo reconoció en la plaza
			return f.get("papa_encuentro", false)
		"lucha2", "lucha3", "lucha4":  # la noche siguiente (si perdió, la misma pelea, dos noches después)
			return "lucha%d" % (int(id.right(1)) - 1) in seen
	return false


func _days_since(id: String) -> int:
	return GameState.day - int(GameState.flags.get("dream_day_" + id, 999))


## Ancho del texto: con controles en pantalla, no llega a la franja de los botones.
func _text_w() -> float:
	return Controls.right_edge() - 32.0
