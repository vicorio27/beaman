extends Node2D
## LA OBRA: el trabajo fijo (lo consigue Germán con el cuñado, cuando hay cédula). Un turno = tres
## viajes subiendo ladrillos al andamio con la pila en la cabeza.
## E mantenido = caminar (caminando la pila se mueve más); soltarlo = afirmarse (se para y la pila
## se calma). Flechas izquierda/derecha = equilibrar. Si se ladea demasiado, se caen ladrillos.
## El turno tiene reloj: sin caminar no se sube nada (y se paga por ladrillo que llega arriba).
## Más ladrillos = más alta = más inestable. Paso firme ayuda.
## Cada viaje trae algo distinto (una cosa nueva por viaje):
##   1. EL LADRILLO DE MÁS: el maestro tira uno; ARRIBA a tiempo = atajarlo (pila más alta, paga más).
##      Si no, le cae en la cabeza.
##   2. VENTARRÓN: se avisa de qué lado viene; empuja la pila un rato (afirmarse o contrapesar).
##   3. LA PALOMA y EL CHARCO: una paloma se le para encima (la pila baila; se va si él se queda
##      quieto un rato); en el charco de mezcla se resbala (no frena en seco).
## Y cada TURNO trae su giro (para que el día 5 no se juegue igual que el día 1):
##   turno 1: normal.  turno 2: LLUVIA (todo resbala; bono si sube bastante).
##   turno 3: EL INGENIERO (casco blanco: cuando mira, botar ladrillos o quedarse quieto se descuenta;
##            cuando está en el celular, afirmarse es gratis).
##   turno 4: WÍLINTON, el cuñado de Germán, camina adelante con su pila y se para de golpe a contestar
##            el celular: soltar E a tiempo o se lo lleva por delante.
##   del 5 en adelante: los giros se turnan.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CITY := "res://scenes/world/City.tscn"
const PAY_FULL := 25000
const TRIPS := 3
const BRICKS := 6
const START_X := 40.0
const END_X := 262.0
const LIMIT := 0.62
const WALK := 27.0
const SHIFT := 110.0                  # segundos de turno
const DROP_X := 236.0                 # al llegar al andamio
const PUDDLE := Vector2(150.0, 196.0)   # dónde está el charco de mezcla (x)

var trip := 0
var stack := BRICKS
var delivered := 0
var x := START_X
var v := 0.0
var tilt := 0.0
var spin := 0.0
var state := "intro"   # intro, walk, drop, back, end
var _t := 0.0
var _say_t := 4.0
var _me: AnimatedSprite2D
var _top: Label
var _msg: Label
var _prompt: Label
var _falling: Array = []
var _idle := 0.0
var shift := SHIFT
## El evento del viaje: "", "brick" (viene el ladrillo), "wind" (avisando / soplando), "pigeon".
var _event := ""
var _event_t := 0.0
var _event_done := false
var _wind_dir := 0.0
var _brick: Dictionary = {}          # el ladrillo que viene volando: {"p", "v"}
var _pigeon := false
## El giro del turno: "", "lluvia", "ingeniero", "cunado".
var twist := ""
var _penalty := 0
var _eng_look := false
var _eng_t := 3.0
var _eng_idle_t := 0.0
var _eng_idle_said := false
var _cx := 0.0          # Wílinton (x); se para a contestar
var _c_stop := 0.0
var _c_next := 3.0
var _c_bumped := false
var _cunado: AnimatedSprite2D
var _eng: AnimatedSprite2D
var _eng_label: Label
const TWISTS := ["", "lluvia", "ingeniero", "cunado"]
const TWIST_INTRO := {
	"lluvia": ["MAESTRO RAMIRO", "—Hoy llueve. El piso es jabón. El que suba catorce o más se gana un bono de lluvia. El que se caiga, se gana un chiste."],
	"ingeniero": ["MAESTRO RAMIRO", "—Hoy viene el ingeniero. Casco blanco. Cuando mira, nadie bota nada y nadie se queda quieto. Cuando está en el celular... bueno. Siempre está en el celular."],
	"cunado": ["MAESTRO RAMIRO", "—Hoy sube con Wílinton, el cuñado de Germán. Camina adelante y se para a contestar el celular. No lo vaya a tumbar."],
}
const CUNADO_CALLS := ["WÍLINTON: —¿Aló? ¿Mor? No, aquí trabajando...", "WÍLINTON: —¿Aló? No, no tengo plata. ¿Quién habla?",
	"WÍLINTON: —¿Aló? ¡Mamá! Sí, sí comí.", "WÍLINTON: —¿Aló? ... Colgaron. Igual paro."]

const FOREMAN := [
	"MAESTRO RAMIRO: —¡Derechito, cédula! ¡Que esos ladrillos cuestan más que usted!",
	"MAESTRO RAMIRO: —Aquí el que se cae, se levanta. El que no se levanta, se descuenta.",
	"MAESTRO RAMIRO: —¿Usted tiembla o es la obra? ... La obra no tiembla, mijo.",
	"UN OBRERO: —Tranquilo, hermano. El primer día todos botamos. El último también.",
]
const IDLE_LINES := [
	"MAESTRO RAMIRO: —¡Eso no se sube solo, cédula! ¡Camine!",
	"MAESTRO RAMIRO: —¿Está meditando? Medite caminando, que la hora se paga igual.",
]


func _ready() -> void:
	_me = AnimatedSprite2D.new()
	_me.sprite_frames = SideFrames.build(load("res://assets/prologue/player.png"), SideFrames.PLAYER)
	_me.offset = Vector2(0, -22)
	add_child(_me)
	var ui := CanvasLayer.new()
	add_child(ui)
	_top = _lab(ui, Vector2(4, 3))
	_msg = _lab(ui, Vector2(4, 150))
	_msg.size = Vector2(Controls.right_edge() - 8, 10)  # a la derecha, los botones táctiles
	_msg.add_to_group("under_dialogue")
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# El aviso de la acción ("¡ARRIBA: ATAJAR!", "¡VIENTO →!"): debajo de la barra de equilibrio.
	_prompt = _lab(ui, Vector2(0, 28))
	_prompt.size = Vector2(320, 10)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_prompt.add_to_group("under_dialogue")
	MusicDirector.force("city_day")
	var n := int(GameState.flags.get("obra_turnos", 0))
	twist = TWISTS[n] if n < TWISTS.size() else TWISTS[1 + (n - TWISTS.size()) % (TWISTS.size() - 1)]
	if twist == "cunado":
		_cunado = AnimatedSprite2D.new()
		_cunado.sprite_frames = _me.sprite_frames
		_cunado.offset = Vector2(0, -22)
		_cunado.modulate = Color(0.75, 0.9, 0.7)
		add_child(_cunado)
		move_child(_cunado, 0)
		_cx = START_X + 40.0
	if twist == "ingeniero":
		_eng = AnimatedSprite2D.new()
		_eng.sprite_frames = _me.sprite_frames
		_eng.offset = Vector2(0, -22)
		_eng.modulate = Color(0.85, 0.85, 1.0)
		_eng.position = Vector2(196, 104)
		_eng.scale = Vector2(0.8, 0.8)
		_eng.play("idle")
		add_child(_eng)
		move_child(_eng, 0)
		_eng_label = _lab(self, Vector2(182, 62))
		_eng_label.z_index = 5
	_intro()


func _lab(parent: Node, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	parent.add_child(l)
	return l


func _intro() -> void:
	await get_tree().create_timer(0.5).timeout
	var lines := [["MAESTRO RAMIRO", "—¿Usted es el de Germán? Ladrillos al andamio. Tres viajes. Seis por viaje. En la cabeza, como los de antes."]]
	if not GameState.flags.get("obra_tutorial2", false):
		GameState.flags["obra_tutorial2"] = true
		lines.append(["", "E mantenido: caminar. Soltarlo: afirmarse (se para y la pila se calma). Flechas: equilibrar la pila."])
		lines.append(["", "El turno tiene reloj. Lo que no sube, no se paga."])
	if TWIST_INTRO.has(twist):
		lines.append(TWIST_INTRO[twist])
	await Dialogue.talk(lines)
	state = "walk"


func _process(delta: float) -> void:
	_t += delta
	match state:
		"walk":
			_walk(delta)
		"back":
			x = move_toward(x, START_X, 160.0 * delta)
			_me.flip_h = true
			if x <= START_X:
				_me.flip_h = false
				stack = BRICKS
				tilt = 0.0
				spin = 0.0
				v = 0.0
				_event = ""
				_event_done = false
				_pigeon = false
				_cx = START_X + 40.0
				_c_stop = 0.0
				_c_next = randf_range(1.5, 3.0)
				state = "walk"
	for b in _falling.duplicate():
		b["v"].y += 300.0 * delta
		b["p"] += b["v"] * delta
		if b["p"].y > 150:
			_falling.erase(b)
	_me.position = Vector2(x, 140)
	if _cunado:
		_cunado.visible = state in ["walk", "drop"] and _cx < DROP_X
		_cunado.position = Vector2(_cx, 140)
		var cw := _c_stop <= 0.0 and state == "walk"
		if _cunado.animation != ("walk" if cw else "idle"):
			_cunado.play("walk" if cw else "idle")
	if _eng:
		_eng.flip_h = _eng_look  # mirando al jugador (a la izquierda) o de espaldas con el celular
		_eng_label.text = "o_o" if _eng_look else "(cel)"
		_eng_label.add_theme_color_override("font_color", Color(1, 0.5, 0.4) if _eng_look else Color(0.75, 0.8, 0.9))
	var walking := (state == "walk" and absf(v) > 6.0) or state == "back"
	if _me.animation != ("walk" if walking else "idle"):
		_me.play("walk" if walking else "idle")
	_top.text = "VIAJE %d/%d  ARRIBA %d  PILA %d  %d:%02d" % [mini(trip + 1, TRIPS), TRIPS, delivered, stack,
		int(maxf(shift, 0.0)) / 60, int(maxf(shift, 0.0)) % 60]
	queue_redraw()


func _walk(delta: float) -> void:
	var going := Input.is_action_pressed("interact")  # E mantenido: camina; suelto: se afirma
	var hard := 1.0 + 0.6 * GameState.diff("cuerpo")
	if GameState.has_skill("paso_firme"):
		hard *= 0.6
	var slip := x > PUDDLE.x and x < PUDDLE.y and trip == 2  # el charco: no frena en seco
	var rain := twist == "lluvia"
	v = move_toward(v, WALK if going else 0.0, (30.0 if slip else (60.0 if rain else 140.0)) * delta)
	x += v * delta
	var moving := v > 8.0
	# La pila es inestable: se va para donde ya está ladeada (más alta = más rápido), y caminando más.
	var g := (3.4 + 0.25 * stack) * (1.0 if moving else 0.45)
	var noise := randf_range(-1.0, 1.0) * (2.8 if moving else 0.25) * (2.0 if _pigeon else 1.0) * (1.5 if slip else 1.0) * (1.25 if rain else 1.0)
	spin += (tilt * g + noise * hard + _wind()) * delta
	if Input.is_action_pressed("move_left"):
		spin -= 1.9 * delta
	if Input.is_action_pressed("move_right"):
		spin += 1.9 * delta
	spin *= 0.92 if moving else 0.8
	if not moving:
		tilt = move_toward(tilt, 0.0, delta * 0.15)
	tilt += spin * delta * 2.0
	# Quieto mucho rato: el maestro se queja (el turno corre igual).
	_idle = _idle + delta if not moving else 0.0
	if _idle > 4.0:
		_idle = -5.0
		_say(IDLE_LINES.pick_random())
	_twist_tick(delta, moving)
	if state != "walk":
		return
	shift -= delta
	if shift <= 0.0:
		_say("MAESTRO RAMIRO: —¡Se acabó el turno! Lo que no subió, no subió.")
		_end()
		return
	_events(delta)
	if absf(tilt) > LIMIT:
		_drop()
		return
	_say_t -= delta
	if _say_t <= 0.0 and _event == "":
		_say_t = randf_range(7.0, 10.0)
		_say(FOREMAN.pick_random())
	if x >= DROP_X:
		delivered += stack
		trip += 1
		_say("(Arriba. %d ladrillos%s.)" % [stack, " y una paloma. El maestro descuenta la paloma" if _pigeon else ""])
		_prompt.text = ""
		_brick = {}
		if trip >= TRIPS:
			_end()
		else:
			state = "back"


## El giro del turno: el ingeniero que mira, Wílinton que se para.
func _twist_tick(delta: float, moving: bool) -> void:
	if twist == "ingeniero":
		_eng_t -= delta
		if _eng_t <= 0.0:
			_eng_look = not _eng_look
			_eng_t = randf_range(2.5, 4.0) if _eng_look else randf_range(2.5, 4.5)
			_eng_idle_said = false
		if _eng_look and not moving and v < 2.0:
			_eng_idle_t += delta
			if _eng_idle_t > 1.2 and not _eng_idle_said:
				_eng_idle_said = true
				_penalty += 1000
				_say(["INGENIERO: —¿Y ese por qué está quieto? ¿Le pagamos por posar? Mil pesos menos.",
					"INGENIERO: —Quieto no se construye nada. Anote, maestro: mil.",
					"INGENIERO: —Otro que medita. Mil."].pick_random())
		else:
			_eng_idle_t = 0.0
	elif twist == "cunado" and _cx < DROP_X:
		if _c_stop > 0.0:
			_c_stop -= delta
		else:
			_cx += 31.0 * delta
			_c_next -= delta
			if _c_next <= 0.0 and _cx < DROP_X - 30.0:
				_c_stop = randf_range(1.4, 2.4)
				_c_next = randf_range(2.5, 4.5)
				_say(CUNADO_CALLS.pick_random())
		if not _c_bumped and x > _cx - 12.0:
			_c_bumped = true
			x = _cx - 14.0
			_say(["WÍLINTON: —¡Ey! ¡Mor, se me cayó todo! ... Ah, no, se le cayó a usted.",
				"WÍLINTON: —Hermano, ¿no ve que estoy en una llamada?"].pick_random())
			_drop()
		elif x < _cx - 20.0:
			_c_bumped = false
		if _c_bumped:
			x = minf(x, _cx - 12.0)  # no lo atraviesa


## El empujón del ventarrón (cuando sopla).
func _wind() -> float:
	return _wind_dir * 0.9 if _event == "wind" and _event_t < 0.0 else 0.0


## Lo de cada viaje.
func _events(delta: float) -> void:
	if not _event_done and _event == "" and x > 90.0:
		_event_done = true
		match trip:
			0:  # el ladrillo de más
				_event = "brick"
				_brick = {"p": Vector2(END_X + 20.0, 60.0), "v": Vector2((x - END_X - 20.0) / 1.1, -40.0)}
				_say("MAESTRO RAMIRO: —¡Uno más, que usted puede! ¡Atájelo!")
			1:  # el ventarrón: se avisa, después sopla
				_event = "wind"
				_wind_dir = [-1.0, 1.0].pick_random()
				_event_t = 1.3
				_say("MAESTRO RAMIRO: —¡Viento! ¡Agárrese de su dignidad, que es lo único que no se vuela!")
			2:  # la paloma
				_event = "pigeon"
				_pigeon = true
				_event_t = 0.0
				_say("(Una paloma se le para encima de la pila. No paga pasaje. Mira para todos lados menos para abajo.)")
	match _event:
		"brick":
			_brick["v"].y += 110.0 * delta
			_brick["p"].y += _brick["v"].y * delta
			_brick["p"].x = move_toward(_brick["p"].x, x, 200.0 * delta)  # se lo tiran a él
			var top := Vector2(x, 140 - 26 - stack * 5.0)
			var near: bool = _brick["p"].distance_to(top) < 26.0
			_prompt.text = Controls.keys_in("¡ARRIBA: ATAJAR!") if near else ""
			if near and Input.is_action_just_pressed("move_up"):
				stack += 1
				_event = ""
				_prompt.text = ""
				spin += randf_range(-0.4, 0.4)
				_say("(Lo ataja con una mano. Siete. El maestro aplaude con la boca: \"eso, cédula\".)")
			elif _brick["p"].y > top.y + 6.0 and absf(_brick["p"].x - x) < 14.0 or _brick["p"].y > 150.0:
				_event = ""
				_prompt.text = ""
				if absf(_brick["p"].x - x) < 18.0:
					spin += signf(randf() - 0.5) * 0.9
					_say("(¡TOC! Le cae en la cabeza. No dice nada. El casco sí: el casco suena.)")
				else:
					_say("(El ladrillo se revienta en el piso. El maestro anota algo en la libreta de las cosas que anota.)")
				_falling.append({"p": _brick["p"], "v": Vector2(20, -40)})
		"wind":
			_event_t -= delta
			if _event_t > 0.0:
				_prompt.text = "VIENTO %s" % ("<<<" if _wind_dir < 0.0 else ">>>") if int(_t * 5) % 2 == 0 else ""
			else:
				_prompt.text = "~ ~ ~" if int(_t * 6) % 2 == 0 else ""
				if _event_t < -2.4:
					_event = ""
					_prompt.text = ""
		"pigeon":
			_event_t += delta
			if v < 4.0:  # quieto un rato: se aburre y se va
				_event_t += delta * 2.0
				if _event_t > 3.0:
					_event = ""
					_pigeon = false
					_say("(La paloma se aburre de que no pase nada y se va. Típico.)")


## Se ladeó demasiado: se caen la mitad (y él se queda quieto un rato).
func _drop() -> void:
	var lost := maxi(1, stack / 2)
	stack -= lost
	var seen: bool = _eng != null and _eng_look
	if seen:
		_penalty += 2000
	for i in lost:
		_falling.append({"p": Vector2(x, 140 - 26 - i * 4), "v": Vector2(signf(tilt) * randf_range(40, 90), -randf_range(20, 80))})
	tilt = 0.0
	spin = 0.0
	v = 0.0
	if _pigeon:
		_pigeon = false
		_event = ""
	if seen:
		_say("INGENIERO: —¡Eso lo vi! Dos mil. Los ladrillos no rebotan, joven.")
	elif not _c_bumped or x < _cx - 20.0:
		_say(["(Se caen %d. El maestro anota algo.)" % lost,
			"MAESTRO RAMIRO: —¡%d al piso! ¿No va a decir ni \"uy\"? Nada. Este man no se queja ni cuando se le cae la obra encima." % lost][randi() % 2])
	state = "drop"
	await get_tree().create_timer(0.8).timeout
	if stack <= 0:
		trip += 1
		_prompt.text = ""
		state = "back" if trip < TRIPS else "end"
		if trip >= TRIPS:
			_end()
	else:
		state = "walk"


func _end() -> void:
	state = "end"
	_prompt.text = ""
	var pay := int(round(PAY_FULL * float(delivered) / (TRIPS * BRICKS) / 500.0)) * 500
	var bonus := 3000 if twist == "lluvia" and delivered >= 14 else 0
	var base_pay := pay
	pay = maxi(0, pay + bonus - _penalty)
	GameState.add_money(pay)
	GameState.flags["obra_turnos"] = int(GameState.flags.get("obra_turnos", 0)) + 1
	GameState.set_hunger(GameState.hunger - 22.0)
	GameState.flags["obra_dia"] = GameState.day
	var f := GameState.flags
	if f.get("trabajo_ultimo", -1) != GameState.day:
		f["trabajo_ultimo"] = GameState.day
		f["trabajo_dias"] = int(f.get("trabajo_dias", 0)) + 1
	TimeManager.skip(6.0)
	GameState.change_mood(6.0 if delivered >= 14 else 1.0)
	await Dialogue.talk([
		["MAESTRO RAMIRO", "—%d de %d. %s" % [delivered, TRIPS * BRICKS, "Bien, cédula. Mañana a las siete." if delivered >= 14 else "Algo es algo. Mañana, mejor."]],
		["MAESTRO RAMIRO", _pay_line(base_pay, bonus, pay)],
		["MAESTRO RAMIRO", "—Y firme el recibo. ... Uy, qué firma tan bonita. Firma de gerente. ¿Usted qué hacía antes?"],
	])
	await Recuerdo.show("oficina")  # lo que hacía antes (una vez)
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(CITY, "FromCafe", "", "(Seis horas de ladrillo. La espalda le duele. Por primera vez en meses, eso se siente bien.)")


func _pay_line(base_pay: int, bonus: int, pay: int) -> String:
	if bonus > 0:
		return "—Tome: $%d, más $%d de bono de lluvia. La plata no se mojó. Usted sí." % [base_pay, bonus]
	if _penalty > 0:
		return "—Eran $%d. El ingeniero le descontó $%d. Quedan $%d. Él gana en un día lo que usted en un mes. Y descuenta." % [base_pay, _penalty, pay]
	return "—Tome: $%d. Contados. No me los gaste en bobadas. Bueno, sí: en comida." % pay


func _say(line: String) -> void:
	_msg.text = line
	# Crece para arriba: lo largo no se corta (y en el celular la franja es más angosta).
	_msg.size = Vector2(Controls.right_edge() - 8, 10)
	_msg.position.y = 178.0 - _msg.get_line_count() * 10.0
	_msg.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(maxf(2.8, line.length() * 0.05))
	tw.tween_property(_msg, "modulate:a", 0.0, 0.4)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.62, 0.74, 0.86))
	draw_rect(Rect2(0, 100, 320, 80), Color(0.55, 0.46, 0.36))     # tierra
	draw_rect(Rect2(0, 140, 320, 40), Color(0.48, 0.4, 0.32))
	if twist == "lluvia":
		draw_rect(Rect2(0, 0, 320, 180), Color(0.2, 0.25, 0.35, 0.25))
		draw_rect(Rect2(0, 139, 320, 2), Color(0.7, 0.75, 0.8, 0.6))  # el piso mojado brilla
		for k in 40:
			var rx := fposmod(k * 37.0 + _t * 40.0, 330.0)
			var ry := fposmod(k * 53.0 + _t * 260.0, 180.0)
			draw_line(Vector2(rx, ry), Vector2(rx - 2, ry + 7), Color(0.8, 0.85, 0.95, 0.5), 1.0)
	if trip == 2:  # el charco de mezcla del tercer viaje
		draw_rect(Rect2(PUDDLE.x, 139, PUDDLE.y - PUDDLE.x, 4), Color(0.62, 0.62, 0.6))
		draw_rect(Rect2(PUDDLE.x + 4, 138, PUDDLE.y - PUDDLE.x - 8, 2), Color(0.75, 0.75, 0.72))
	# El edificio a medio hacer y el andamio.
	draw_rect(Rect2(250, 30, 70, 110), Color(0.7, 0.66, 0.6))
	for y in range(36, 140, 18):
		draw_rect(Rect2(256, y, 14, 10), Color(0.35, 0.38, 0.45))
		draw_rect(Rect2(290, y, 14, 10), Color(0.35, 0.38, 0.45))
	for xx in [244.0, 276.0]:
		draw_line(Vector2(xx, 30), Vector2(xx, 140), Color(0.3, 0.3, 0.32), 2.0)
	for y in range(40, 140, 25):
		draw_line(Vector2(244, y), Vector2(276, y), Color(0.3, 0.3, 0.32), 2.0)
	# La pila de ladrillos de abajo.
	for i in 5:
		for j in 3 - i % 2:
			draw_rect(Rect2(8 + j * 9 + (i % 2) * 4, 132 - i * 5, 8, 4), Color(0.72, 0.32, 0.22))
	# El viento: rayitas que cruzan.
	if _event == "wind" and _event_t < 0.0:
		for k in 6:
			var yy := 40.0 + k * 15.0
			var xx := fposmod(_t * 260.0 * _wind_dir + k * 57.0, 340.0) - 10.0
			draw_line(Vector2(xx, yy), Vector2(xx + 18.0 * _wind_dir, yy), Color(1, 1, 1, 0.6), 1.0)
	# La pila en la cabeza, ladeada.
	if state != "end":
		var base := Vector2(x, 140 - 26)  # encima de la cabeza
		var up := Vector2.UP.rotated(tilt)
		var side := Vector2.RIGHT.rotated(tilt)
		for i in stack:
			var c := base + up * (i * 5.0) + side * (tilt * i * 6.0)
			draw_colored_polygon(PackedVector2Array([c - side * 6, c + side * 6, c + side * 6 + up * 4, c - side * 6 + up * 4]),
				Color(0.75, 0.33, 0.22))
		if _pigeon:  # la paloma, arriba de todo
			var c := base + up * (stack * 5.0 + 2.0) + side * (tilt * stack * 6.0)
			draw_circle(c, 3.0, Color(0.6, 0.62, 0.68))
			draw_circle(c + side * 3.0 + up * 2.0, 1.6, Color(0.5, 0.52, 0.58))
			draw_line(c + side * 4.5 + up * 2.0, c + side * 6.0 + up * 1.5, Color(0.9, 0.7, 0.3))
		# El indicador: verde, amarillo, rojo.
		var r := absf(tilt) / LIMIT
		draw_rect(Rect2(110, 16, 100, 5), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(160 + tilt / LIMIT * 50 - 2, 14, 4, 9), Color(0.3, 0.9, 0.3).lerp(Color(1, 0.2, 0.2), r))
	if _eng:  # el casco blanco del ingeniero
		draw_rect(Rect2(_eng.position.x - 4, _eng.position.y - 24, 8, 3), Color(0.97, 0.97, 0.95))
	if _cunado and _cunado.visible:  # la pila de Wílinton (derechita, el desgraciado)
		for i in 5:
			draw_rect(Rect2(_cx - 6, 140 - 26 - i * 5 - 4, 12, 4), Color(0.7, 0.3, 0.2))
	if not _brick.is_empty() and _event == "brick":
		draw_rect(Rect2(_brick["p"] - Vector2(4, 2), Vector2(8, 4)), Color(0.75, 0.33, 0.22))
	for b in _falling:
		draw_rect(Rect2(b["p"], Vector2(8, 4)), Color(0.75, 0.33, 0.22))
