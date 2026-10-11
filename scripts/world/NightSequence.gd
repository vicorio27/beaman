extends Control
## La noche del Día 1 (spec, secciones 24, 25 y 27):
##   1. Se acomoda donde eligió dormir (con Lukas).
##   2. Revisa la mochila: la fotografía. La da vuelta: "Para que nunca olvides de dónde vienes."
##   3. La primera memoria: jugable, en Memory1.tscn (vuelve acá al terminar).
##   4. Resumen del día y FIN DEL CAPITULO 1.
## Del Día 2 en adelante: acomodarse, resumen y la mañana siguiente (GameState.new_day: robos,
## lluvia, la policía). Después despierta en la ciudad, donde durmió ("Wake_<lugar>").
## Botón: avanzar.
## Algunos textos llevan una viñeta arriba (tools/art/draw_vinetas.py): acostarse con Lukas, despertar
## al amanecer debajo del puente (sin Lukas: el hueco y el collar), despertar golpeado (un sueño
## perdido, un robo, la defensa perdida).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CITY := "res://scenes/world/City.tscn"
const MEMORY := "res://scenes/world/Memory1.tscn"
## Los sueños: [id, escena, título (se calcula), cómo se duerme]. Ver el calendario en
## docs/DISENO_CIUDAD_Y_SISTEMAS.md. Se sueñan por hechos de la historia (_dream_when); entre uno y
## otro, como mínimo una noche libre (el torneo de lucha va en noches seguidas: deja expectativa).
## El último (\"final\"): la galería de revanchas y Lilato (ver FinalRush).
const DREAMS := [
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
const EVENT_DREAMS := ["final", "plomo_d1", "plomo_d2", "carrera1", "sigilo1", "callejon3", "lucha1", "lucha2", "lucha3", "lucha4"]
const CHAIN_DREAMS := ["lucha2", "lucha3", "lucha4", "carrera3", "plomo_d3", "carrera4", "final"]
## Al despertar de cada sueño: [si ganó, si perdió, lo que le queda].
const WAKE := {
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
const SETTLE := {
	"banco": "Banco de plaza. Espalda contra la pared. Lukas abajo, de guardia.",
	"kiosco": "El kiosco gotea en una esquina. Se acomoda en la otra. Lukas se le pega a la espalda.",
	"rio": "El cambuche. Huele a humedad. Lukas se le acuesta en los pies.",
	"callejon": "El callejón. Seco, oscuro, con ruidos. Lukas duerme con una oreja parada.",
	"parque": "El parque. Los columpios crujen solos con el viento.",
	"pension": "Una cama. Con colchón. Con sábanas. Lukas debajo, sin respirar.",
}
## Las mismas noches, sin Lukas.
const SETTLE_SOLO := {
	"banco": "Banco de plaza. Espalda contra la pared. Nadie abajo.",
	"kiosco": "El kiosco gotea en una esquina. Se acomoda en la otra. La espalda, fría.",
	"rio": "El cambuche. Huele a humedad. Los pies, sin peso encima.",
	"callejon": "El callejón. Ruidos. Nadie con la oreja parada.",
	"parque": "El parque. Desde aquí se ve el árbol de flores amarillas.",
	"pension": "Una cama. Debajo, nadie. Duerme en la mitad.",
}
const SPOT_NAMES := {"banco": "el banco de la plaza", "kiosco": "el kiosco viejo", "rio": "el cambuche del puente",
	"callejon": "el callejón", "parque": "el parque", "pension": "la pensión"}

var _bg: ColorRect
var _text: Label
var _photo: TextureRect
var _pic: TextureRect  # la viñeta de arriba
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
	_pic = TextureRect.new()
	_pic.position = Vector2(40, 10)
	_pic.pivot_offset = Vector2(120, 50)
	_pic.modulate.a = 0.0
	add_child(_pic)
	_text = Label.new()
	_text.add_theme_font_override("font", FONT)
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.position = Vector2(16, 118)
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


## La viñeta de arriba: entra despacio y se acerca un poquito mientras se lee (como una foto que se mira).
func _vignette(id: String) -> void:
	_pic.texture = load("res://assets/ui/vineta_%s.png" % id)
	_pic.scale = Vector2.ONE
	var t := create_tween()
	t.tween_property(_pic, "modulate:a", 1.0, 1.2)
	t.parallel().tween_property(_pic, "scale", Vector2(1.03, 1.03), 9.0)
	_text.position = Vector2(16, 118)
	_text.size = Vector2(_text_w(), 56)


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
			_vignette("golpeado")  # perdió: se despierta como si le hubieran pegado
		else:
			_vignette("despierta" if GameState.lukas_alive() else "despierta_solo")
		if not GameState.lukas_alive():
			for k in w.size():
				if str(w[k]).contains("Lukas"):
					w[k] = "Se despierta y busca a Lukas con la mano. No está."
		await _say(w[0] if GameState.flags.get("dream_won", true) else w[1])
		if w[2] != "":
			await _say(w[2])
		# Lo que aprendió soñando (le sirve en los dos mundos).
		var skill: String = Skills.DREAM_SKILL.get(back, "")
		_vignette_off()
		if skill != "" and GameState.learn(skill):
			GameState.flags.erase("skill_toast")
			_text.position = Vector2(16, 50)
			_text.size = Vector2(_text_w(), 120)
			await _say("Algo aprendió en el sueño.\nHABILIDAD: %s\n%s" % [Skills.name_of(skill).to_upper(), Skills.desc(skill)])
		await _summary(spot)
		return
	# Del Día 2 en adelante: corto.
	if GameState.day >= 2:
		var settle: Dictionary = SETTLE if GameState.lukas_alive() else SETTLE_SOLO
		if GameState.lukas_alive():
			_vignette("acostarse")
		await _say(settle.get(spot, settle["banco"]))
		_vignette_off()
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
			await _say(dream[3])
			if dream[0] == "final":
				FinalRush.begin()
				return
			SceneRouter.go(dream[1], "", "SUEÑO %d" % (seen.size() + 1))  # el 1 fue el del prólogo
			return
		await _summary(spot)
		return
	# Vuelve de la memoria jugable: sigue con el resumen.
	if GameState.flags.get("memory_1_seen", false):
		await _say("Cierra los ojos.")
		await _summary(spot)
		return
	await _say(SETTLE.get(spot, SETTLE["banco"]))
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


func _summary(spot: String) -> void:
	_vignette_off()
	var s := GameState.stats
	_text.position = Vector2(16, 40)
	_text.size = Vector2(_text_w(), 120)
	await _say("DIA %d\n\nDinero conseguido: $%d\nComida: %d\nDurmió en %s\nCabeza: en su sitio" % [
		GameState.day, s["money_earned"], s["food_eaten"], SPOT_NAMES.get(spot, "la calle")])
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
	_text.position = Vector2(16, 50)
	_text.size = Vector2(_text_w(), 110)
	MusicDirector.force("")
	var spot: String = GameState.flags.get("sleep_spot", "banco")
	for line in [
		"Esa noche, después del último sueño, no se despierta.",
		"Samuel lo encuentra al amanecer, en %s. Con el collar de Lukas en la mano, apretado." % SPOT_NAMES.get(spot, "la calle"),
		"Tiene cara de haber ganado algo. Nadie va a saber qué.",
	]:
		await _say(line)
	GameState.flags["murio"] = true
	SceneRouter.go("res://scenes/world/Epilogo.tscn")


## La noche en que se muere Lukas. Sin chistes: el narrador.
func _lukas_dies() -> void:
	var f := GameState.flags
	f["lukas_muerto"] = GameState.day
	_text.position = Vector2(16, 50)
	_text.size = Vector2(_text_w(), 110)
	MusicDirector.force("")
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
		await _say(line)
	GameState.add_item("collar_lukas")
	GameState.change_mood(-30.0)
	GameState.add_locura(3)
	for q in ["lukas_agua", "lukas_comida"]:
		GameState.quests.erase(q)


## Alguien se mete al cambuche mientras duerme: tres reacciones rápidas (la flecha que diga).
## La alarma da más tiempo; con Lukas de guardia, el primero ya está ganado; la trampa lo castiga.
func _defend(spot: String) -> void:
	_vignette_off()
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
	_text.position = Vector2(16, 118)
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
	if not first:
		_vignette("golpeado" if robbed else ("despierta_lluvia" if rained and GameState.lukas_alive()
			else ("despierta" if GameState.lukas_alive() else "despierta_solo")))
	for line in lines:
		await _say(line)
	if first:
		await _say("Victoria, su hija, cumple doce años el 29 de octubre. En mes y medio.\nMeta: $150.000 para un regalo. Tiene $%d." % GameState.money)
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
		"final":  # el día 44 sí o sí (la noche antes del cumpleaños); antes, solo si se cayó la mentira
			# y ya soñó todo lo demás (las revanchas son contra jefes que ya conoce)
			if GameState.day >= 44:
				return true
			# Unos días después de Lukas (y con todo lo demás soñado), también.
			if not GameState.lukas_alive() and GameState.day - int(f["lukas_muerto"]) >= 4:
				for d in DREAMS:
					if d[0] != "final" and not d[0] in seen:
						return false
				return true
			if not f.get("lilato_mentira_caida", false):
				return false
			for d in DREAMS:
				if d[0] != "final" and not d[0] in seen:
					return false
			return true
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
