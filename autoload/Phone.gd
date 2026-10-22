extends CanvasLayer
## El celular de flecha (se lo vende Don Efraín: Items "celular"). Con el celular en la mochila, en la
## ciudad, cada tanto entra una llamada: el celular salta abajo a la derecha, vibra y suena, con el
## nombre en la pantallita. Acción: contestar. Atrás: colgar (si no contesta, también cuelga).
##   LORENA (Lilato, en los sueños): todas distintas y todas para joderle la vida (lo que dice está en
##   scripts/systems/LorenaLlamadas.gd). Son los diálogos más chistosos del juego (él es mudo: solo
##   puede respirar). Una por día como mucho; si le cuelga, vuelve a llamar. Cuando se le acaba el
##   repertorio, deja de llamar.
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
	if not f["lorena_hoy"] and randf() < 0.75 and LorenaLlamadas.le_queda():
		call_in("lorena")
	else:
		call_in("desconocido")


## Entra una llamada. kind: "lorena", "lorena_otra_vez" (le colgaron), "desconocido" o "carolina"
## (Diana Carolina, desde un número que no tiene guardado: Carolina.gd decide qué dice).
func call_in(kind: String) -> void:
	var f := GameState.flags
	f["llamadas_hoy"] = int(f.get("llamadas_hoy", 0)) + 1
	# Lorena a veces llama de otro número ("si le marco del mío no me contesta").
	var hidden := kind == "lorena" and int(f.get("lorena_llamada", 0)) > 1 and randf() < 0.3
	if kind == "desconocido" and int(f.get("lorena_llamada", 0)) > 1 and randf() < 0.25 and LorenaLlamadas.le_queda():
		kind = "lorena"
		hidden = true
	_caller.text = "DESCONOCIDO" if (kind in ["desconocido", "carolina"] or hidden) else "LORENA"
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
	# Saca el celular de flecha y se lo pone en la oreja (y ahí se queda mientras le hablan).
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("act"):
		await p.act("celular")
		p.act("celular_hablando")
	if kind == "carolina":
		await Carolina.llamada()
	elif kind.begins_with("lorena"):
		f["lorena_hoy"] = true
		await _lorena(kind == "lorena_otra_vez", hidden)
	else:
		await _unknown()
	if is_instance_valid(p) and p.has_method("act_stop"):
		p.act_stop()


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

const LUKAS_OPT := "(Ponerle el celular a Lukas)"


func _lorena(again: bool, hidden: bool) -> void:
	var f := GameState.flags
	if again and f.get("lorena_colgada", false):
		f.erase("lorena_colgada")
		await Dialogue.talk([["LORENA", LorenaLlamadas.turno(LorenaLlamadas.VOLVIO, "lorena_volvio")]])
		if f.get("lorena_hoy_hecha", -1) == GameState.day:
			await Dialogue.talk([["LORENA", LorenaLlamadas.turno(LorenaLlamadas.CIERRE, "lorena_cierre")]])
			return
	if hidden:
		await Dialogue.talk([["LORENA", LorenaLlamadas.turno(LorenaLlamadas.OTRO_NUMERO, "lorena_otro_numero")]])
	var call: Dictionary = LorenaLlamadas.siguiente()
	if call.is_empty():
		await Dialogue.talk([["LORENA", "—... Ya no tengo nada más que decirle. Eso nunca me había pasado. Es culpa suya."]])
		return
	f["lorena_hoy_hecha"] = GameState.day
	_efecto(str(call.get("efecto", "")))
	GameState.change_mood(float(call.get("animo", -3)))
	var opts := [BREATHE, BREATHE_2]
	if GameState.lukas_alive():
		opts.append(LUKAS_OPT)
	opts.append(HANG)
	var pick: String = opts[await Dialogue.talk(call["a"], opts)]
	if pick == HANG:
		await Dialogue.talk([["", "(Cuelga.)"]])
		f["lorena_colgada"] = true
		_callback = randf_range(10.0, 20.0)
		return
	if pick == LUKAS_OPT:
		var used := int(f.get("lorena_lukas", 0))
		var r: Array = LorenaLlamadas.LUKAS[used] if used < LorenaLlamadas.LUKAS.size() else LorenaLlamadas.LUKAS_CANSADO
		f["lorena_lukas"] = used + 1
		await Dialogue.talk([["", r[0]], ["LORENA", r[1]]])
		GameState.change_mood(3.0)  # la venganza chiquita de los dos
	elif pick == BREATHE and call.has("r1"):
		await Dialogue.talk(call["r1"])
	elif pick == BREATHE_2 and call.has("r2"):
		await Dialogue.talk(call["r2"])
	if call.has("fin"):
		await Dialogue.talk(call["fin"])


## Lo que hizo de verdad (no solo lo que dijo).
func _efecto(efecto: String) -> void:
	var f := GameState.flags
	match efecto:
		"pedir_mal":  # la foto en el grupo del barrio: hoy pedir rinde la mitad (Pedir.gd)
			f["lorena_grupo_dia"] = GameState.day
		"german":  # la llamada a la panadería: hoy Germán no le da trabajo
			f["lorena_german_dia"] = GameState.day
		"visita":  # el próximo domingo la visita es corta (Conversations._visita)
			f["lorena_visita"] = true
		"policia":  # el cuadrante: hoy hay redada en la plaza (si no hubo ya)
			if GameState.day >= 3 and not (f.get("evento_dia", -1) == GameState.day and f.get("evento_estado", "") == "activo"):
				f["evento_dia"] = GameState.day
				f["evento_hoy"] = "redada"
				f["evento_hora"] = mini(TimeManager.hour() + 1, 20)
				f["evento_estado"] = "espera"


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
