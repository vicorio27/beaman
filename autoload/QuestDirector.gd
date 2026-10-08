extends Node
## Reglas de las misiones: cuándo empiezan y cuándo se cumplen (las definiciones están en
## scripts/systems/Quests.gd y el estado en GameState.quests). También los eventos del Día 1:
## al atardecer avisa que vuelva al puente, y de noche alguien le ocupó el lugar.

const CAMP := Vector2(400, 628)
const DUSK_HOUR := 18
## Donde aparece la café racer (en la vereda, a la derecha del café).
const MOTO_POS := Vector2(664, 382)
## Donde espera Zaida en el centro (cerca de la Registraduría, "por casualidad").
const ZAIDA_POS := Vector2(236, 214)
## Favores: dónde está escondido lo que hay que encontrar (solo lo encuentra Lukas).
const ANILLO_POS := Vector2(560, 120)
const COLLAR_POS := Vector2(69, 596)
## Mauricio en la plaza (con su moto), al lado del puesto de Rosa.
const PAPA_POS := Vector2(690, 452)

var _check := 0.0


func _ready() -> void:
	GameState.ate.connect(_on_ate)
	GameState.inventory_changed.connect(_check_collect)


func _process(delta: float) -> void:
	if GameState.is_active("lukas_olfato") and GameState.flags.get("lukas_sniffed", false):
		GameState.complete_quest("lukas_olfato")
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.25
	_day1_evening()
	_day2_tutorial()
	_cedula()
	_favors()
	_family()
	_photo()
	_victoria()
	_mysteries()
	_events()
	_jobs()
	_ruta()
	_daily()
	DayTasks.tick(get_tree().current_scene)


## Victoria: a las 12 sale del colegio (menos los domingos) y Lilato la viene a buscar. A veces
## (con el vínculo alto) Lilato llega tarde. Los domingos, con visitas, está en el Parque.
const VICTORIA_POS := Vector2(612, 202)
const VISITA_POS := Vector2(470, 300)


func _victoria() -> void:
	var g := GameState
	var f := g.flags
	if f.get("centro_open", false) and not g.quests.has("v_colegio"):
		g.start_quest("v_colegio")
	if int(f.get("victoria", 0)) >= 2 and not g.quests.has("v_defensoria"):
		g.start_quest("v_defensoria")
	if g.day >= 45 and not g.quests.has("v_cumple"):
		g.start_quest("v_cumple")
		Narrator.say("Hoy cumple años Victoria. %s" % ("Visita en el Parque, de diez a dos." if f.get("visitas", false) else "Sale del colegio a las doce."))
	var scene := get_tree().current_scene
	if scene == null or not TimeManager.running:
		return
	var h := TimeManager.hour()
	var sunday := g.day % 7 == 0
	var here: Node = scene.find_child("Victoria", true, false)
	var birthday: bool = g.day == 45
	var school: bool = scene.name == "Centro" and h == 12 and not sunday and not (birthday and f.get("visitas", false))
	var visit: bool = scene.name == "Parque" and (sunday or birthday) and f.get("visitas", false) and h >= 10 and h < (14 if birthday else 12)
	if (school or visit) and here == null:
		var at := VICTORIA_POS if school else VISITA_POS
		_spawn_kid(scene, at)
		var late: bool = school and int(f.get("victoria", 0)) >= 3 and randf() < 0.4 and f.get("lilato_tarde_dia", -1) != g.day
		if late:
			f["lilato_tarde_dia"] = g.day
		elif school:
			_spawn_npc(scene, "lilato_madre", "LilatoMadre", 3, at + Vector2(16, -2), Color(0.85, 0.45, 0.5))
		else:
			_spawn_npc(scene, "supervisora", "Supervisora", 15, at + Vector2(22, -4), Color(0.8, 0.85, 0.95))
	elif not (school or visit) and here != null:
		for n in ["Victoria", "LilatoMadre", "Supervisora"]:
			var node: Node = scene.find_child(n, true, false)
			if node:
				node.queue_free()


func _spawn_kid(scene: Node, at: Vector2) -> void:
	var v := _spawn_npc(scene, "victoria", "Victoria", 3, at, Color(1.0, 0.8, 0.9))
	v.scale = Vector2(0.72, 0.72)  # tiene siete años


func _spawn_npc(scene: Node, id: String, node_name: String, row: int, at: Vector2, tint: Color) -> Node2D:
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = node_name
	npc.npc_id = id
	npc.sheet_row = row
	npc.face = "down"
	npc.position = at
	var world := scene.get_node_or_null("World")
	(world if world else scene).add_child(npc)
	npc.modulate = tint
	return npc


## Los misterios empiezan solos: al oír "es él", al saber de la casa de tejas, al ver al de negro.
func _mysteries() -> void:
	var g := GameState
	for m in [["m_el", "es_el_oido"], ["m_tejas", "casa_tejas_misterio"], ["m_negro", "senor_negro"]]:
		if g.flags.get(m[1], false) and not g.quests.has(m[0]):
			g.start_quest(m[0])


## Eventos del día: uno por día (a veces ninguno), a una hora al azar, en el barrio. Duran hora y media.
##   redada: la policía pide papeles en la plaza.   aguacero: llueve duro (bajo techo, a salvo).
##   pelea: dos se agarran en la avenida (separarlos o no; es algo violento).
##   ayuda: un señor desmayado o una niña perdida (ayudar cuesta comida o tiempo).
const EVENTS := ["redada", "aguacero", "pelea", "ayuda"]
const EVENT_POS := {"redada": Vector2(566, 470), "pelea": Vector2(420, 250), "ayuda": Vector2(660, 400)}
var _rain_layer: CanvasLayer


func _events() -> void:
	var g := GameState
	var f := g.flags
	if g.day < 3 or not TimeManager.running:
		return
	if f.get("evento_dia", -1) != g.day:
		f["evento_dia"] = g.day
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("evento" + str(g.day))
		f["evento_hoy"] = EVENTS[rng.randi() % EVENTS.size()] if rng.randf() < 0.7 else ""
		f["evento_hora"] = rng.randi_range(9, 16)
		f["evento_estado"] = "espera"
	var ev: String = f.get("evento_hoy", "")
	if ev == "":
		return
	var now := TimeManager.minutes
	var start: float = float(f["evento_hora"]) * 60.0
	var scene := get_tree().current_scene
	if f["evento_estado"] == "espera" and now >= start and now < start + 90.0:
		f["evento_estado"] = "activo"
		_event_start(ev, scene)
	elif f["evento_estado"] == "activo" and now >= start + 90.0:
		f["evento_estado"] = "fin"
		_event_end(ev, scene)
	# Lo que se ve mientras dura (si cambia de escena, se vuelve a poner).
	if f["evento_estado"] == "activo" and scene:
		if ev == "aguacero":
			_rain_tick(scene)
		elif scene.name == "City" and scene.find_child("Evento", true, false) == null and EVENT_POS.has(ev):
			_event_npc(ev, scene)


func _event_start(ev: String, scene: Node) -> void:
	var outdoor: bool = scene != null and scene.name in ["City", "Centro", "Parque"]
	if ev != "aguacero" and (scene == null or scene.name != "City"):
		return  # pasa en el barrio: si no está ahí, no se entera
	match ev:
		"redada":
			Narrator.say("(Sirenas cerca de la plaza. Están pidiendo papeles.)")
		"aguacero":
			Narrator.say("(Se pone negro el cielo. Va a caer un aguacero. Bajo techo: iglesia, panadería, café, pensión.)" if outdoor
				else "Afuera empieza a llover duro. Aquí adentro, por ahora, no.")
		"pelea":
			Narrator.say("(Gritos en la avenida. Dos se están agarrando.)")
		"ayuda":
			Narrator.say("(Alguien grita en la plaza: \"¡Ayuda!\". Nadie se mueve.)")


func _event_end(ev: String, scene: Node) -> void:
	if scene:
		var n: Node = scene.find_child("Evento", true, false)
		if n:
			n.queue_free()
	if is_instance_valid(_rain_layer):
		_rain_layer.queue_free()
	if ev == "aguacero" and GameState.flags.get("aguacero_mojado", false):
		GameState.flags.erase("aguacero_mojado")
		Narrator.say("(Escampa. Quedó ensopado. Lukas se le sacude encima.)" if GameState.lukas_alive()
			else "(Escampa. Quedó ensopado.)")


func _event_npc(ev: String, scene: Node) -> void:
	var row: int = {"redada": 9, "pelea": 6, "ayuda": 12}[ev]
	var tint: Color = {"redada": Color(0.45, 0.6, 0.45), "pelea": Color(0.9, 0.7, 0.6), "ayuda": Color(0.85, 0.85, 0.95)}[ev]
	var npc := _spawn_npc(scene, "evento_" + ev, "Evento", row, EVENT_POS[ev], tint)
	if ev == "ayuda":
		npc.rotation = PI / 2  # en el piso


## El aguacero: lluvia dibujada; afuera y sin techo, se moja (una vez).
func _rain_tick(scene: Node) -> void:
	var outdoor: bool = scene.name in ["City", "Centro", "Parque"]
	if outdoor and not is_instance_valid(_rain_layer):
		_rain_layer = CanvasLayer.new()
		_rain_layer.layer = 5
		var rain := Node2D.new()
		rain.set_script(load("res://scripts/world/Aguacero.gd"))
		_rain_layer.add_child(rain)
		scene.add_child(_rain_layer)
	var grace: bool = TimeManager.minutes < float(GameState.flags.get("evento_hora", 0)) * 60.0 + 20.0  # 20 min para buscar techo
	if outdoor and not grace and not GameState.flags.get("aguacero_mojado", false):
		GameState.flags["aguacero_mojado"] = true
		GameState.change_mood(-6.0)
		GameState.set_hygiene(GameState.hygiene - 10.0)
		if randf() < 0.2 and not GameState.lukas_sick() and GameState.lukas_alive():
			GameState.flags["lukas_enfermo"] = GameState.day


## Yeison, el de Rapidito: en la plaza, desde el Día 4, de 9 a 18.
const YEISON_POS := Vector2(560, 446)


func _jobs() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.name != "City" or not TimeManager.running:
		return
	var h := TimeManager.hour()
	var here: Node = scene.find_child("Yeison", true, false)
	var on: bool = GameState.day >= 4 and h >= 9 and h < 18
	if on and here == null:
		var y := _spawn_npc(scene, "yeison", "Yeison", 12, YEISON_POS, Color(1.0, 0.75, 0.5))
		y.face = "left"
	elif not on and here != null:
		here.queue_free()


## La ruta de reciclaje: latas por el barrio, contra reloj. Al final Wilson las compra al doble.
const RUTA_POINTS := [Vector2(80, 250), Vector2(200, 250), Vector2(320, 250), Vector2(560, 250), Vector2(680, 250),
	Vector2(900, 250), Vector2(470, 330), Vector2(470, 430), Vector2(470, 520), Vector2(820, 330), Vector2(820, 430),
	Vector2(820, 520), Vector2(600, 452), Vector2(700, 500), Vector2(100, 432), Vector2(250, 432)]
const RUTA_SECONDS := 90.0
var _ruta_end := 0.0
var _ruta_label: Label


func start_ruta() -> void:
	var scene := get_tree().current_scene
	var world := scene.get_node_or_null("World")
	var pts := RUTA_POINTS.duplicate()
	pts.shuffle()
	for i in 12:
		var p := Area2D.new()
		p.name = "Ruta_%d_%d" % [GameState.day, i]
		p.set_script(load("res://scripts/world/Pickup.gd"))
		p.item_id = "lata"
		p.found_line = "Una lata. ¡Otra! Esto es la bolsa de valores del barrio."
		p.position = pts[i]
		p.add_to_group("ruta")
		(world if world else scene).add_child(p)
	GameState.flags["ruta_latas_antes"] = GameState.count("lata") + GameState.count("botella")
	_ruta_end = Time.get_ticks_msec() / 1000.0 + RUTA_SECONDS
	var layer := CanvasLayer.new()
	layer.layer = 11
	scene.add_child(layer)
	_ruta_label = Label.new()
	_ruta_label.position = Vector2(96, 46)
	_ruta_label.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	_ruta_label.add_theme_font_size_override("font_size", 8)
	_ruta_label.add_theme_constant_override("outline_size", 3)
	_ruta_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	_ruta_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	layer.add_child(_ruta_label)


func _ruta() -> void:
	if _ruta_end <= 0.0:
		return
	var left := _ruta_end - Time.get_ticks_msec() / 1000.0
	var got: int = GameState.count("lata") + GameState.count("botella") - int(GameState.flags.get("ruta_latas_antes", 0))
	if is_instance_valid(_ruta_label):
		_ruta_label.text = "RUTA %02d s   LATAS %d" % [maxi(0, int(left)), got]
	if left > 0.0:
		return
	_ruta_end = 0.0
	for n in get_tree().get_nodes_in_group("ruta"):
		n.queue_free()
	if is_instance_valid(_ruta_label):
		_ruta_label.get_parent().queue_free()
	var cans: int = GameState.count("lata")
	var bottles: int = GameState.count("botella")
	var pay: int = (cans * 300 + bottles * 200) * 2
	GameState.remove_item("lata", cans)
	GameState.remove_item("botella", bottles)
	GameState.add_money(pay)
	var f := GameState.flags
	if f.get("trabajo_ultimo", -1) != GameState.day:
		f["trabajo_ultimo"] = GameState.day
		f["trabajo_dias"] = int(f.get("trabajo_dias", 0)) + 1
	TimeManager.skip(1.0)
	await Dialogue.talk([["", "(Pasa el camión de la basura.)"],
		["WILSON", "—%d latas y %d botellas. Al doble: $%d. Usted corre como si lo persiguieran, parce. ... ¿Lo persiguen? No me diga. No me diga nada, mejor." % [cans, bottles, pay]],
		["ÉL", "Nadie me persigue. Reviso igual. Esquina, poste, moto. Nadie. Es un hábito. Como lavarse los dientes, pero con la nuca."]])


## Los siete pedazos de la foto: la arma (y se ve la cara).
func _photo() -> void:
	var g := GameState
	if g.flags.get("foto_armada", false) or g.count("pedazo_foto") < g.PHOTO_PIECES or g.input_blocked() or SceneRouter.busy:
		return
	g.flags["foto_armada"] = true
	g.remove_item("pedazo_foto", g.PHOTO_PIECES)
	g.add_item("foto_entera")
	MusicDirector.force("")
	await Dialogue.talk([["", "(Siete pedazos. Los pone en el piso, como un rompecabezas. %s)" % ("Lukas se sienta a mirar." if g.lukas_alive() else "Nadie se sienta a mirar.")],
		["", "(Les pone cinta. Encajan.)"]])
	var layer := CanvasLayer.new()
	layer.layer = 12
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.size = Vector2(320, 180)
	layer.add_child(dim)
	var pic := TextureRect.new()
	pic.texture = load("res://assets/items/foto_armada.png")
	pic.position = Vector2(100, 22)
	pic.modulate.a = 0.0
	layer.add_child(pic)
	get_tree().current_scene.add_child(layer)
	await create_tween().tween_property(pic, "modulate:a", 1.0, 1.5).finished
	await Dialogue.talk([
		["", "(Un hombre de bigote negro y camisa a cuadros. Tiene la mano en el hombro de un niño. Se está riendo.)"],
		["", "(Atrás, una frase: \"Para que nunca olvides de dónde vienes.\")"],
		["", "(La mira mucho rato. Después la guarda.)"],
		["ÉL", "Tengo su misma mano. La que se le va a la cintura. Ahora sé de quién la saqué."],
	])
	await create_tween().tween_property(layer.get_child(1), "modulate:a", 0.0, 1.0).finished
	layer.queue_free()
	g.change_mood(6.0)
	MusicDirector.release()


func _on_ate(_id: String) -> void:
	if GameState.is_active("conseguir_comida"):
		GameState.complete_quest("conseguir_comida")
		GameState.start_quest("pasar_el_dia")


func _check_collect() -> void:
	if GameState.is_active("latas") and GameState.count("lata") + GameState.count("botella") >= 5:
		GameState.complete_quest("latas")
	if GameState.is_active("cartones") and GameState.count("carton") >= 3:
		GameState.complete_quest("cartones")


## Día 1, al atardecer: aviso, y bajo el puente aparece alguien durmiendo en su lugar.
func _day1_evening() -> void:
	if GameState.day != 1 or TimeManager.hour() < DUSK_HOUR or not TimeManager.running:
		return
	var f := GameState.flags
	if not f.get("dusk_warned", false):
		f["dusk_warned"] = true
		if not GameState.is_active("conseguir_comida"):
			Narrator.say("(Oscurece. Hay que buscar dónde pasar la noche.)")
		else:
			# Si todavía no comió, igual sigue la historia: la noche llega.
			GameState.complete_quest("conseguir_comida")
			GameState.start_quest("pasar_el_dia")
	var scene := get_tree().current_scene
	if scene == null or scene.name != "City":
		return
	var stranger := scene.find_child("Stranger", true, false)
	if stranger == null:
		stranger = _spawn_stranger(scene)
	var player := scene.find_child("Player", true, false)
	if player and not f.get("stranger_talked", false) and GameState.is_active("pasar_el_dia") \
			and player.global_position.distance_to(CAMP) < 40.0 and not GameState.input_blocked():
		f["stranger_talked"] = true
		Conversations.run("stranger", stranger)


func _spawn_stranger(scene: Node) -> Node:
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = "Stranger"
	npc.npc_id = "stranger"
	npc.sheet_row = 0
	npc.face = "down"
	npc.position = CAMP
	var world := scene.get_node_or_null("World")
	(world if world else scene).add_child(npc)
	npc.modulate = Color(0.75, 0.72, 0.8)
	return npc


## Del Día 2 en adelante: la noche llega sola, y las misiones que se cumplen mirando el estado.
func _daily() -> void:
	var f := GameState.flags
	if GameState.day >= 2 and TimeManager.running and TimeManager.hour() >= DUSK_HOUR 			and not f.get("dusk_warned", false):
		f["dusk_warned"] = true
		GameState.complete_quest("sobrevivir")
		GameState.start_quest("donde_dormir")
		Narrator.say("(Oscurece. Hay que buscar dónde pasar la noche.)")
	if TimeManager.running and GameState.day >= 2 and TimeManager.hour() >= 14 \
			and f.get("lukas_water_day", -1) != GameState.day and f.get("sed_aviso", -1) != GameState.day and GameState.lukas_alive():
		f["sed_aviso"] = GameState.day
		Narrator.say("(Lukas jadea con la lengua afuera. Hay cuencos con agua por el barrio.)")
	if GameState.is_dirty() and not GameState.quests.has("banarse") and not GameState.quests.has("t_bano") \
			and TimeManager.running and GameState.day >= 3:
		GameState.start_quest("banarse")
		Narrator.say("(La gente se aparta al pasar. Huele a calle. Hay baño público en la plaza.)")
	if GameState.is_active("banarse") and not GameState.is_dirty():
		GameState.complete_quest("banarse")
	if GameState.is_active("armar_cambuche") and GameState.has_cambuche():
		GameState.complete_quest("armar_cambuche")
	if GameState.is_active("lukas_comida") and f.get("lukas_fed_day", -1) == GameState.day:
		GameState.complete_quest("lukas_comida")
	if GameState.is_active("regalo_hija") and GameState.cambuche.get("alcancia", 0) >= GameState.GIFT_GOAL:
		GameState.complete_quest("regalo_hija")
		f["regalo_listo"] = true
		Narrator.say("(Ciento cincuenta mil en la alcancía.)")


## Día 2: lo básico en orden (cambuche, Lukas, baño). Cuando lo aprendió, aparece la moto.
func _day2_tutorial() -> void:
	var f := GameState.flags
	if GameState.is_active("t_cambuche") and GameState.has_cambuche():
		GameState.complete_quest("t_cambuche")
		GameState.start_quest("t_lukas")
	if GameState.is_active("t_lukas") and f.get("lukas_fed_day", -1) == GameState.day:
		GameState.complete_quest("t_lukas")
		GameState.start_quest("t_bano")
	if GameState.is_active("t_bano") and f.get("bathed", -1) == GameState.day:
		GameState.complete_quest("t_bano")
		GameState.start_quest("moto_cafe")
		Narrator.say("(Huele a jabón.)")
	if GameState.is_active("moto_cafe"):
		var scene := get_tree().current_scene
		if scene and scene.name == "City" and scene.find_child("MotoCafe", true, false) == null:
			_spawn_moto(scene)


## Una café racer parqueada frente al café. Tocarla dispara el recuerdo.
func _spawn_moto(scene: Node) -> void:
	var world := scene.get_node_or_null("World")
	var moto := Sprite2D.new()
	moto.name = "MotoCafe"
	moto.texture = load("res://assets/barrio/moto_parked.png")
	moto.centered = false
	moto.offset = Vector2(-moto.texture.get_width() / 2.0, -moto.texture.get_height())
	moto.position = MOTO_POS
	(world if world else scene).add_child(moto)
	var spot := Area2D.new()
	spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
	spot.service_id = "moto_cafe"
	spot.hint = "MIRAR"
	spot.area = Vector2(30, 16)
	spot.position = MOTO_POS + Vector2(0, 4)
	(world if world else scene).add_child(spot)


## La cédula: los requisitos se marcan solos mirando la mochila y la plata; Zaida aparece en el
## centro cuando hace falta una dirección.
func _cedula() -> void:
	var g := GameState
	if g.is_active("cedula"):
		_toggle("c_plata", g.money >= 55000)
		_toggle("c_foto", g.count("foto_doc") > 0)
		_toggle("c_direccion", g.count("carta_german") > 0 or g.count("direccion_zaida") > 0)
	var scene := get_tree().current_scene
	if scene and scene.name == "Centro" and g.is_active("c_direccion") and not g.flags.get("zaida_favor", false) \
			and g.count("carta_german") == 0 and scene.find_child("Zaida", true, false) == null:
		_spawn_zaida(scene)


## Una secundaria que se cumple o se "descumple" según el estado (la plata va y viene).
func _toggle(id: String, ok: bool) -> void:
	var q: String = GameState.quests.get(id, "")
	if ok and q == "active":
		GameState.complete_quest(id)
	elif not ok and q == "done":
		GameState.quests[id] = "active"
		GameState.quest_changed.emit(id, "active")


func _spawn_zaida(scene: Node) -> void:
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = "Zaida"
	npc.npc_id = "zaida"
	npc.sheet_row = 3
	npc.face = "down"
	npc.position = ZAIDA_POS
	var world := scene.get_node_or_null("World")
	(world if world else scene).add_child(npc)
	npc.modulate = Color(0.86, 0.66, 0.96)  # violeta: no es Marta, aunque se parezca


## Favores: lo escondido aparece en la ciudad mientras haga falta; al encontrarlo, sigue el favor.
func _favors() -> void:
	var g := GameState
	var scene := get_tree().current_scene
	var in_city := scene != null and scene.name == "City"
	if g.is_active("f_anillo"):
		if g.count("anillo") > 0:
			g.complete_quest("f_anillo")
			g.start_quest("f_anillo_volver")
		elif in_city and scene.find_child("Pickup_anillo", true, false) == null:
			_hide(scene, "anillo", ANILLO_POS,
				"Algo brilla entre la tierra. Un anillo de oro, finito. Adentro dice: G y M, 1979.")
	if g.is_active("f_gato"):
		if g.count("collar_michi") > 0 and not g.flags.get("gato_escena", false) and not g.input_blocked():
			g.flags["gato_escena"] = true
			_cat_scene()
		elif g.count("collar_michi") == 0 and in_city and scene.find_child("Pickup_collar_michi", true, false) == null:
			_hide(scene, "collar_michi", COLLAR_POS, "Un collar rojo con una campanita. Dice MICHI.")


func _hide(scene: Node, item: String, at: Vector2, line: String) -> void:
	var p := Area2D.new()
	p.set_script(load("res://scripts/world/Pickup.gd"))
	p.name = "Pickup_" + item
	p.item_id = item
	p.found_line = line
	p.concealed = true
	p.position = at
	var world := scene.get_node_or_null("World")
	(world if world else scene).add_child(p)


## Lo que pasa frente a la casa de tejas. Sin chistes.
func _cat_scene() -> void:
	await get_tree().create_timer(1.2).timeout
	await Dialogue.talk([
		["", "(El collar de Michi, tirado frente a la casa de tejas.)"],
		["", "(Lukas le ladra a la puerta. Como no le ladra a nada.)"],
		["", "(La puerta se abre una rendija. Adentro está oscuro. Huele a encierro y a flores viejas.)"],
		["", "(Una mano muy blanca empuja al gato afuera. Michi sale corriendo hacia el café.)"],
		["VOZ", "—Ya no lo necesito."],
		["", "(La puerta se cierra. Despacio. Sin hacer ruido.)"],
		["", "(Lukas se le esconde detrás de las piernas.)"],
		["ÉL", "Lukas no se esconde de nada. Se esconde de esa puerta. Yo también me escondería detrás de mis piernas, si pudiera."],
	])
	GameState.change_mood(-6.0)
	GameState.complete_quest("f_gato")
	GameState.start_quest("f_gato_volver")


## La familia: la llamada a la mamá (después de la carta de Samuel, o desde el Día 8) y, después
## del sueño de Brenda, Mauricio en la plaza. Cada cosa dispara su sueño (NightSequence).
func _family() -> void:
	var g := GameState
	var f := g.flags
	if not f.get("llamo_mama", false) and not g.quests.has("llamar_mama") and TimeManager.running \
			and (g.quests.get("f_carta_volver", "") == "done" or g.day >= 12):
		g.start_quest("llamar_mama")
		Narrator.say("(Hay un teléfono público en la plaza.)")
	var seen: Array = f.get("dreams_seen", [])
	var scene := get_tree().current_scene
	if "callejon3" in seen and not f.get("papa_encuentro", false) and scene and scene.name == "City" \
			and g.day > int(f.get("dream_day_callejon3", 0)) and TimeManager.hour() >= 9 and TimeManager.hour() < 17:
		if not g.quests.has("papa_plaza"):
			g.start_quest("papa_plaza")
			Narrator.say("(En la plaza hay una moto grande parqueada.)")
		if scene.find_child("Mauricio", true, false) == null:
			_spawn_papa(scene)


func _spawn_papa(scene: Node) -> void:
	var world := scene.get_node_or_null("World")
	var parent: Node = world if world else scene
	var moto := Sprite2D.new()
	moto.name = "MotoPapa"
	moto.texture = load("res://assets/barrio/moto_parked.png")
	moto.centered = false
	moto.offset = Vector2(-moto.texture.get_width() / 2.0, -moto.texture.get_height())
	moto.position = PAPA_POS + Vector2(28, 4)
	moto.scale = Vector2(1.2, 1.2)
	moto.modulate = Color(0.8, 0.5, 0.4)
	parent.add_child(moto)
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = "Mauricio"
	npc.npc_id = "mauricio"
	npc.sheet_row = 6
	npc.face = "left"
	npc.position = PAPA_POS
	parent.add_child(npc)
	npc.modulate = Color(0.62, 0.48, 0.42)
