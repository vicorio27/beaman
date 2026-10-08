extends Node2D
## SUEÑO 7: torneo de boxeo (tipo Punch-Out!!). Él tiene quince años: la edad que tenía cuando
## Mauricio, el papá, se fue. Un torneo de domingo en un garaje. Para llegar a Mauricio hay que
## pasar por sus amigos de trago, y cada uno, sin querer, cuenta una verdad sobre él:
##   1. Raúl: el primer borracho, el que tiene plata. Cadena de oro. Ganchos pesados.
##   2. Alvarito: el segundo borracho, el de gran corazón. Pelea casi sin ganas. El único que lo quiere.
##   3. El Pecas: el tercer borracho, el de las motos, lambón con Mauricio. Finta: amaga y remata.
##   4. Mauricio: motos y trago, bajito y ancho. Dos fases: en la segunda se saca el chaleco, se le
##      pasa la borrachera, deja de mentir y pega "la arrancada" (dos ganchos seguidos).
## Están borrachos: se tambalean y sus tiempos no son exactos (cuesta leerlos).
## Entre peleas, los piques: Mauricio desde el costado del ring.
##   Izquierda / derecha: esquivar. Abajo (mantener): cubrirse. E: golpe. Arriba + E: golpe fuerte.
## Los golpes se avisan (se echan para atrás). Cuando mienten, fallan o quedan mareados, están
## abiertos: el contragolpe pega doble. Corazones: se gastan al pegarle a la guardia y al recibir.
## Perder una pelea: revancha o despertarse. A los puntos contra Mauricio, gana él: le creen a él.
## Deja la habilidad Paso firme (el papá se fue; él aprendió a caminar solo).
## Cada pelea es un sueño aparte (fight = 0..3, escenas Boxeo1..4): empieza con un "anteriormente" y
## termina con un gancho hacia el próximo domingo. fight = -1: el torneo entero de corrido.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NIGHT := "res://scenes/world/Night.tscn"
const SKIN := Color(0.86, 0.64, 0.5)
const BOY_SKIN := Color(0.9, 0.7, 0.55)
const COMEBACKS := ["—¿Qué domingo? Nombre uno.", "—Igualito no. Yo me quedé.", "—Usted no estaba. Yo sí me acuerdo."]

## Los rivales. Golpes: jab, hook_l, hook_r, upper (no se cubre), double (dos jabs),
## feint (amaga: si esquivás antes, remata), rush (gancho izquierdo y derecho seguidos).
const OPPONENTS := [
	{"id": "raul", "name": "RAUL", "hp": 90.0, "rounds": 1, "downs": 2, "speed": 1.15, "dmg": 1.2, "drunk": 1.0,
		"attacks": ["jab", "hook_l", "hook_r", "hook_l", "hook_r", "upper"],
		"body": Color(0.85, 0.75, 0.3), "hair": Color(0.15, 0.12, 0.12), "width": 56.0, "mustache": true, "gold": true,
		"taunts": ["—Yo invito la próxima ronda. A usted no.", "—¡Salud, compadre! (Toma aguardiente en pleno round.)",
			"—Con lo que me gasto en trago le pago la vida a usted. Y no lo hago."]},
	{"id": "alvarito", "name": "ALVARITO", "hp": 80.0, "rounds": 1, "downs": 2, "speed": 1.05, "dmg": 0.8, "drunk": 0.8,
		"attacks": ["jab", "jab", "double", "hook_l", "hook_r"],
		"body": Color(0.45, 0.55, 0.7), "hair": Color(0.3, 0.24, 0.2), "width": 44.0, "kind": true,
		"taunts": ["—Perdóneme, mijo. Yo no quiero pegarle. Me tocó.", "—Su papá hablaba de ustedes. Borracho, pero hablaba.",
			"—Usted tiene los ojos de su mamá. Ella sí era buena gente."]},
	{"id": "pecas", "name": "EL PECAS", "hp": 100.0, "rounds": 1, "downs": 2, "speed": 0.85, "dmg": 1.0, "drunk": 0.6,
		"attacks": ["jab", "feint", "feint", "upper", "hook_l", "hook_r"],
		"body": Color(0.15, 0.14, 0.16), "hair": Color(0.75, 0.35, 0.15), "width": 44.0, "freckles": true, "jacket": true,
		"taunts": ["—¡Lo que usted diga, don Mauricio! ¡Usted es el mejor!", "—Los domingos salíamos en moto. Él y yo. A Melgar.",
			"—¿Usted es el hijo? Nunca habló de usted. De la moto sí."]},
	{"id": "mauricio", "name": "MAURICIO", "hp": 150.0, "rounds": 3, "downs": 3, "speed": 1.0, "dmg": 1.0, "drunk": 0.5,
		"attacks": ["jab", "jab", "hook_l", "hook_r", "upper"],
		"body": Color(0.85, 0.82, 0.76), "hair": Color(0.22, 0.2, 0.22), "width": 64.0, "mustache": true, "vest": true, "short": true,
		"taunts": ["—Yo los veo todos los domingos. Pregúntele a cualquiera.", "—Yo siempre estuve. Usted no se acuerda bien.",
			"—Su mamá me alejó de ustedes.", "—Le mandaba plata. Todos los meses.", "—¡Hip! Mírese: igualito a mí."],
		"taunts2": ["—Me fui porque no sabía ser papá. Y no aprendí.", "—Los domingos me iba en la moto con el Pecas. Era más fácil.",
			"—Tomaba para no pensar en ustedes. Y funcionaba. Eso es lo peor."]},
]
## Los piques: lo que pasa antes de cada pelea y después de ganarla.
const BEFORE := [
	[["", "Tiene quince años. Guantes prestados. Un torneo de domingo armado en el garaje de una cantina."],
		["", "En primera fila, con chaleco de motociclista y una cerveza: Mauricio. Bajito, ancho. Hace un año que se fue."],
		["MAURICIO", "—¡Miren! ¡Mi hijo! Yo lo veo todos los domingos, ¿cierto, mijo?"],
		["MAURICIO", "—Si quiere pelear conmigo, gánele primero a mis amigos. Raúl es el que paga."],
		["", "Izquierda y derecha esquivan. Abajo cubre. E pega. Arriba + E pega duro."],
		["", "Están borrachos: se tambalean y no pegan siempre al mismo tiempo. Mirá bien."]],
	[["MAURICIO", "—Suerte de principiante. Raúl ya está muy prendido."],
		["MAURICIO", "—Ahora Alvarito. Ese es blandito. Llora con las rancheras."],
		["ALVARITO", "—Hola, mijo. Usted no se acuerda de mí. Yo lo cargué cuando nació."]],
	[["MAURICIO", "—El Pecas sí es bravo. Ese me sigue a todas partes."],
		["EL PECAS", "—¡A donde vaya don Mauricio, voy yo! ¡En moto, a pie, a donde sea!"],
		["", "—Qué suerte. A nosotros no nos dejó ni la dirección."]],
	[["", "Mauricio se sube al ring. Se acomoda el chaleco. Se toma el último trago de la botella."],
		["MAURICIO", "—Bueno, mijo. Aquí estamos. Como los domingos."],
		["", "—Nunca estuvimos así. Ni un domingo."]],
]
## Al empezar un sueño que no es el primero: lo que pasó el domingo anterior.
const RECAP := {
	1: [["", "ANTERIORMENTE..."],
		["", "El domingo pasado tumbó a Raúl, el de la plata. Mauricio lo miró. Una sola vez, pero lo miró."],
		["", "El mismo garaje. El mismo olor a aguardiente. Otro domingo."]],
	2: [["", "ANTERIORMENTE..."],
		["", "Alvarito perdió limpio. Y le dijo algo que nadie le había dicho: que el papá los quería. A su manera."],
		["", "El Pecas lo espera calentando, con una chaqueta de cuero igualita a la de Mauricio."]],
	3: [["", "ANTERIORMENTE..."],
		["", "Raúl. Alvarito. El Pecas. Los tres en la lona."],
		["", "Queda uno. Quince años esperando este domingo."]],
}
## Al ganar (menos la final): el gancho hacia el próximo sueño.
const TEASE := [
	[["", "Mauricio levanta la cerveza hacia el ring. Es la primera vez que lo mira en quince años."],
		["MAURICIO", "—El próximo domingo, Alvarito. Si es que vuelve."],
		["", "Va a volver."]],
	[["ALVARITO", "—Mijo... el Pecas sabe cosas de su papá. De los domingos en la moto."],
		["ALVARITO", "—Pregúntele. Con los guantes puestos: así sí contesta."]],
	[["", "Mauricio se quita la chaqueta. Se arremanga despacio. Sonríe con todos los dientes."],
		["MAURICIO", "—Ahora sí, mijo. Usted y yo. El próximo domingo."],
		["", "Quince años esperando un domingo. Puede esperar uno más."],
		["", "Uno solo."]],
]
const AFTER := [
	[["RAUL", "—Uy... el pelado pega. Ya me bajó la borrachera. Y eso me cuesta plata."],
		["MAURICIO", "—Raúl ya está viejo. No cuenta."]],
	[["ALVARITO", "—Me ganó limpio. Así me gusta."],
		["ALVARITO", "—Mijo... su papá los quería. A su manera. Una manera muy mala, pero los quería."],
		["", "—Gracias, Alvarito. Usted sí vino a verme. Hoy."]],
	[["EL PECAS", "—... Usted pega como él."],
		["", "—No. Yo pego como yo. Él pega como se va."]],
]

## Qué pelea es este sueño (0: Raúl ... 3: Mauricio). -1: todas seguidas.
@export var fight := -1

var op := 0
var o: Dictionary = {}
var phase2 := false
var p_hp := 100.0
var m_max := 100.0
var m_hp := 100.0
var hearts := 20
var round_n := 1
var round_t := 60.0
var knockdowns := 0
var p_downs := 0
var dealt := 0.0
var taken := 0.0
var state := "intro"         # intro, fight, m_down, p_down, between, end
var m_state := "idle"        # idle, wind, recover, taunt, guard, hurt, dizzy
var m_attack := ""
var m_t := 1.0
var _combo := 0
var p_state := "idle"        # idle, dodge_l, dodge_r, block, punch, hook, hurt, tired
var p_t := 0.0
var _count := 0
var _count_t := 0.0
var _mash := 0
var _jab_side := 1
var _flash := 0.0
var _contra := 0.0
var _boo := 0.0
var _lie_i := 0
var _t := 0.0
var _result := ""
var _top: Label
var _center: Label
var _msg: Label
var _sfx := {}


func _ready() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_top = _label(ui, Vector2(0, 2), 8)
	_top.size = Vector2(320, 10)
	_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center = _label(ui, Vector2(0, 60), 16)
	_center.size = Vector2(320, 20)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_msg = _label(ui, Vector2(10, 31), 8)
	_msg.size = Vector2(300, 20)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for n in ["hit-1", "hit-2", "miss", "grunt"]:
		var pl := AudioStreamPlayer.new()
		pl.stream = load("res://assets/audio/%s.wav" % n)
		pl.volume_db = -6.0
		add_child(pl)
		_sfx[n] = pl
	MusicDirector.force("")
	_tournament()


func _label(parent: Node, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	parent.add_child(l)
	return l


# ---------------------------------------------------------------- El torneo

func _tournament() -> void:
	await get_tree().create_timer(0.8).timeout
	var last := OPPONENTS.size()
	if fight >= 0:
		op = fight
		last = fight + 1
		if RECAP.has(fight):
			await Dialogue.talk(RECAP[fight])
	while op < last:
		o = OPPONENTS[op]
		state = "intro"
		await Dialogue.talk(BEFORE[op])
		while true:
			_reset_fight()
			_result = ""
			await _start_round()
			while _result == "":
				if not is_inside_tree():
					return
				await get_tree().process_frame
			if _result == "win":
				break
			var i := await Dialogue.talk([["", "Queda en la lona. El garaje da vueltas."]], ["Revancha", "Despertarse"])
			if i == 1:
				_wake(false)
				return
		if op < AFTER.size():
			await Dialogue.talk(AFTER[op])
		if fight >= 0 and op < TEASE.size():
			# Un sueño, una pelea: el gancho y a despertarse.
			await Dialogue.talk(TEASE[op] + [["", "CONTINUARÁ EL PRÓXIMO DOMINGO."]])
			_wake(true)
			return
		op += 1
	await _final_scene()


func _reset_fight() -> void:
	phase2 = false
	m_max = o["hp"]
	m_hp = m_max
	p_hp = 100.0
	hearts = 20
	round_n = 1
	round_t = 60.0
	knockdowns = 0
	p_downs = 0
	dealt = 0.0
	taken = 0.0
	m_state = "idle"
	m_t = 1.0
	p_state = "idle"


func _start_round() -> void:
	state = "between"
	_center.text = "%s  R%d" % [o["name"], round_n]
	await get_tree().create_timer(1.2).timeout
	_center.text = "¡PELEEN!"
	MusicDirector.force("boxeo")
	await get_tree().create_timer(0.6).timeout
	_center.text = ""
	state = "fight"
	m_state = "idle"
	m_t = 1.0


# ---------------------------------------------------------------- Bucle

func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 3.0)
	_contra = maxf(0.0, _contra - delta)
	_boo = maxf(0.0, _boo - delta)
	match state:
		"fight":
			round_t -= delta
			_player(delta)
			_opponent(delta)
			if round_t <= 0.0:
				_end_round()
		"m_down", "p_down":
			_counting(delta)
	if not o.is_empty():
		_top.text = "YO %s  R%d %02d  %s %s" % [_bar(p_hp / 100.0), round_n, ceili(maxf(round_t, 0.0)),
			o["name"], _bar(m_hp / o["hp"])]
	queue_redraw()


func _bar(r: float) -> String:
	var n := clampi(ceili(r * 6.0), 0, 6)
	return "|".repeat(n) + ".".repeat(6 - n)


func _player(delta: float) -> void:
	if p_t > 0.0:
		p_t -= delta
		if p_t <= 0.0:
			if p_state == "tired":
				hearts = 6
			p_state = "idle"
	if p_state in ["idle", "block"]:
		p_state = "block" if Input.is_action_pressed("move_down") else "idle"


func _unhandled_input(event: InputEvent) -> void:
	if state == "p_down" and event.is_action_pressed("interact"):
		_mash += 1
		return
	if state != "fight" or p_state not in ["idle", "block"]:
		return
	if event.is_action_pressed("move_left"):
		p_state = "dodge_l"
		p_t = 0.45
		_feint_check()
	elif event.is_action_pressed("move_right"):
		p_state = "dodge_r"
		p_t = 0.45
		_feint_check()
	elif event.is_action_pressed("interact"):
		if hearts <= 0:
			return
		var hook := Input.is_action_pressed("move_up")
		p_state = "hook" if hook else "punch"
		p_t = 0.35 if hook else 0.2
		_jab_side = -_jab_side
		_punch(hook)


## La finta del Pecas: si esquivás mientras amaga, te remata enseguida.
func _feint_check() -> void:
	if m_state == "wind" and m_attack == "feint":
		m_attack = "jab"
		m_t = 0.5


func _punch(hook: bool) -> void:
	var dmg := 6.0 if hook else 3.0
	match m_state:
		"guard":
			_blocked()
		"recover", "taunt", "dizzy":
			_land(dmg * 2.0, true)
		"wind":
			if randf() < (0.45 if hook else 0.25):
				_land(dmg * 1.5, true)
			else:
				_blocked()
		_:
			if randf() < (0.5 if hook else 0.3):
				m_state = "guard"
				m_t = 0.6
				_blocked()
			else:
				_land(dmg, false)


func _land(dmg: float, counter: bool) -> void:
	m_hp -= dmg
	dealt += dmg
	_sfx["hit-2" if counter else "hit-1"].play()
	if counter:
		_contra = 0.6
		if o["id"] == "mauricio" and not phase2 and randf() < 0.25:
			_msg.text = COMEBACKS.pick_random()
	if m_hp <= 0.0:
		_knockdown()
		return
	m_state = "hurt"
	m_t = 0.25
	_combo = 0


func _blocked() -> void:
	hearts -= 1
	_sfx["miss"].play()
	if hearts <= 0:
		p_state = "tired"
		p_t = 3.0
		_msg.text = "(Cansado. Los brazos no le responden.)"


## Qué tan borracho está (en la fase 2, a Mauricio se le pasa: se pone serio).
func _drunk() -> float:
	return 0.0 if phase2 else float(o.get("drunk", 0.0))


func _speed() -> float:
	var s: float = o["speed"] * (0.8 if round_n >= 3 else (0.9 if round_n == 2 else 1.0))
	return s * (0.8 if phase2 else 1.0)


func _opponent(delta: float) -> void:
	m_t -= delta
	if m_t > 0.0:
		return
	match m_state:
		"idle", "hurt", "guard", "recover", "dizzy":
			_choose()
		"taunt":
			m_state = "idle"
			m_t = 0.4
		"wind":
			_strike()


func _choose() -> void:
	var fast := _speed()
	var r := randf()
	if r < 0.62:
		var opts: Array = o["attacks"].duplicate()
		if phase2:
			opts.append_array(["rush", "rush", "upper"])
		m_attack = opts.pick_random()
		_combo = 0
		m_state = "wind"
		m_t = {"jab": 0.5, "double": 0.45, "feint": 0.55, "hook_l": 0.65, "hook_r": 0.65, "upper": 1.0, "rush": 0.8}[m_attack] * fast
		m_t *= randf_range(1.0 - 0.3 * _drunk(), 1.0 + 0.4 * _drunk())  # borracho: no siempre al mismo tiempo
		if m_attack == "upper" and o["id"] == "mauricio":
			_msg.text = "MAURICIO: —El domingo voy. Se lo juro." if not phase2 else "MAURICIO: —¡Esta sí se la cumplo!"
		elif m_attack == "rush":
			_msg.text = "(Ya no se tambalea. Ruge como la moto. Viene la arrancada: dos ganchos.)"
	elif r < 0.78:
		m_state = "guard"
		m_t = 1.1
	elif r < 0.92:
		m_state = "taunt"
		m_t = 1.6
		var lines: Array = o["taunts2"] if phase2 else o["taunts"]
		_msg.text = "%s: %s" % [o["name"], lines[_lie_i % lines.size()]]
		_lie_i += 1
		if o["id"] == "mauricio" and not phase2:
			_boo = 1.2  # el público le cree
	else:
		m_state = "idle"
		m_t = randf_range(0.5, 1.0) * fast


func _strike() -> void:
	var fast := _speed()
	if m_attack == "feint":  # amagó y él no se movió: no pasa nada, queda abierto un instante
		m_state = "recover"
		m_t = 0.4
		return
	var side := m_attack
	if m_attack == "rush":
		side = "hook_l" if _combo == 0 else "hook_r"
	elif m_attack == "double":
		side = "jab"
	var dodged := false
	var blocked := false
	match side:
		"jab":
			dodged = p_state in ["dodge_l", "dodge_r"]
			blocked = p_state == "block"
		"hook_l":
			dodged = p_state == "dodge_r"
			blocked = p_state == "block"
		"hook_r":
			dodged = p_state == "dodge_l"
			blocked = p_state == "block"
		"upper":
			dodged = p_state in ["dodge_l", "dodge_r"]
	var dmg: float = {"jab": 8.0, "hook_l": 12.0, "hook_r": 12.0, "upper": 22.0}[side] * o["dmg"] * (1.2 if phase2 else 1.0)
	if dodged:
		_sfx["miss"].play()
	else:
		if blocked:
			dmg *= 0.3
			hearts -= 1
		else:
			hearts -= 2
			_sfx["grunt"].play()
			p_state = "hurt"
			p_t = 0.35
		p_hp -= dmg
		taken += dmg
		_flash = 1.0
		if hearts <= 0 and p_state != "tired":
			p_state = "tired"
			p_t = 3.0
		if p_hp <= 0.0:
			_player_down()
			return
	# Combos: el doble jab y la arrancada pegan dos veces.
	if m_attack in ["double", "rush"] and _combo == 0:
		_combo = 1
		m_state = "wind"
		m_t = (0.3 if m_attack == "double" else 0.45) * fast
		return
	if dodged:
		m_state = "dizzy" if side == "upper" or m_attack == "rush" else "recover"
		m_t = (1.0 if m_state == "dizzy" else 0.6) / fast
	else:
		m_state = "recover"
		m_t = 0.5


# ---------------------------------------------------------------- Caídas, rounds y resultado

func _knockdown() -> void:
	knockdowns += 1
	m_hp = 0.0
	state = "m_down"
	_count = 0
	_count_t = 0.0
	_msg.text = ""
	if o["id"] == "mauricio" and knockdowns == 2:
		_msg.text = "MAURICIO: —Está bien. Está bien. Ya no más chaleco. Ya no más trago."


func _player_down() -> void:
	p_downs += 1
	p_hp = 0.0
	state = "p_down"
	_count = 0
	_count_t = 0.0
	_mash = 0
	_msg.text = "¡Arriba! (E, E, E...)"


func _counting(delta: float) -> void:
	_count_t += delta
	if _count_t < 0.6:
		return
	_count_t = 0.0
	_count += 1
	_center.text = str(_count)
	if state == "m_down":
		if knockdowns >= o["downs"]:
			if _count >= 3:
				_center.text = "K.O."
				state = "end"
				await get_tree().create_timer(1.2).timeout
				_center.text = ""
				_result = "win"
			return
		var gets_up: int = [4, 6, 8][knockdowns - 1]
		if _count >= gets_up:
			var left: float = [0.7, 0.5, 0.3][knockdowns - 1]
			if o["id"] == "mauricio" and knockdowns == 2:
				phase2 = true  # segunda fase: sin chaleco, más rápido, sin mentiras
				_lie_i = 0
				left = 0.8
			m_max = o["hp"] * left
			m_hp = m_max
			_resume()
	else:
		var need := 6 + p_downs * 3
		if _mash >= need:
			p_hp = [45.0, 35.0, 25.0][mini(p_downs - 1, 2)]
			hearts = maxi(hearts, 8)
			_resume()
		elif _count >= 10:
			_center.text = "K.O."
			state = "end"
			await get_tree().create_timer(1.2).timeout
			_center.text = ""
			_result = "lose"


func _resume() -> void:
	_center.text = ""
	_msg.text = ""
	state = "fight"
	m_state = "idle"
	m_t = 0.8
	p_state = "idle"


func _end_round() -> void:
	state = "between"
	_center.text = "FIN DEL ROUND %d" % round_n
	MusicDirector.force("")
	await get_tree().create_timer(1.2).timeout
	_center.text = ""
	if round_n >= o["rounds"]:
		await _decision()
		return
	var corner := [
		["", "En la esquina, un beagle con una toalla en la boca. No tiene sentido. Es perfecto."],
		["", "Lukas le lame la mano. Los guantes huelen a sangre y a domingo."],
	]
	await Dialogue.talk([corner[(round_n - 1) % corner.size()]])
	p_hp = minf(100.0, p_hp + 25.0)
	hearts = 20
	round_n += 1
	round_t = 60.0
	_start_round()


## A los puntos: contra los amigos, gana el que pegó más. Contra Mauricio, gana él: le creen a él.
func _decision() -> void:
	state = "end"
	if o["id"] != "mauricio":
		var won := dealt > taken
		await Dialogue.talk([["", "Deciden los jueces..."],
			["", "Gana el pelado, por puntos." if won else "Gana %s, por puntos." % o["name"].capitalize()]])
		_result = "win" if won else "lose"
		return
	await Dialogue.talk([
		["", "Tres rounds. Nadie se cayó del todo. Deciden los jueces."],
		["", "Por puntos... gana Mauricio. El jurado le creyó. Como todos."],
		["MAURICIO", "—¡Ese es mi hijo! ¡Lo veo todos los domingos!"],
	])
	_result = "lose"


func _final_scene() -> void:
	state = "end"
	await Dialogue.talk([
		["", "Mauricio queda en la lona. Sin chaleco. Nadie cuenta hasta diez."],
		["MAURICIO", "—Yo... los veía. Desde lejos. Desde la moto, con el Pecas. Los domingos."],
		["", "—Ya sé, pa. Desde lejos."],
		["", "Raúl pide otra ronda. El Pecas mira para otro lado. Alvarito es el único que aplaude, despacio."],
		["", "Él se baja del ring solo. Camina derecho. Por primera vez, sin mirar atrás."],
	])
	_wake(true)


func _wake(won: bool) -> void:
	state = "out"
	GameState.flags["dream_won"] = won
	GameState.flags["dream_return"] = "mauricio1" if fight < 0 else "boxeo%d" % (fight + 1)
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.08, 0.06, 0.09))
	for x in [60, 160, 260]:
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x + 50, 120), Vector2(x - 50, 120)]),
			Color(1, 0.95, 0.75, 0.06))
	draw_rect(Rect2(90, 16, 140, 12), Color(0.5, 0.12, 0.12))
	draw_string(FONT, Vector2(96, 26), "TORNEO DE DOMINGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.6))
	for row in 3:
		for k in 22:
			var x := 6.0 + k * 14.6 + (row % 2) * 7.0
			var y := 44.0 + row * 12.0 + sin(_t * 6.0 + k + row) * (2.0 if _boo > 0.0 else 0.6)
			draw_circle(Vector2(x, y), 5.0, Color(0.16, 0.13, 0.18).lightened(row * 0.05))
	if _boo > 0.0:
		draw_string(FONT, Vector2(20, 40), "¡UUUH!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.5, 0.5))
		draw_string(FONT, Vector2(250, 40), "¡UUUH!", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.5, 0.5))
	draw_rect(Rect2(0, 118, 320, 62), Color(0.32, 0.36, 0.48))
	if not o.is_empty():
		_draw_opp()
	for i in 3:
		var y := 92.0 + i * 11.0
		draw_line(Vector2(0, y), Vector2(320, y), [Color(0.8, 0.2, 0.2), Color(0.9, 0.9, 0.9), Color(0.2, 0.3, 0.8)][i], 2.0)
	_draw_boy()
	draw_string(FONT, Vector2(6, 176), "<3 %d" % hearts, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1, 0.4, 0.5) if hearts > 0 else Color(0.5, 0.5, 0.5))
	if _contra > 0.0:
		draw_string(FONT, Vector2(118, 50), "¡CONTRA!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.9, 0.3, _contra / 0.6))
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, 320, 180), Color(1, 0.2, 0.2, _flash * 0.35))


func _glove(c: Vector2, r: float) -> void:
	draw_circle(c, r, Color(0.45, 0.25, 0.15))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(0.6, 0.38, 0.24))


func _draw_opp() -> void:
	var w: float = o["width"]
	if state == "m_down" or (state == "end" and _result != "lose" and m_hp <= 0.0):
		draw_rect(Rect2(160 - w, 128, w * 2, 16), o["body"].darkened(0.4))
		draw_circle(Vector2(160 - w - 2, 134), 10.0, SKIN)
		for k in 3:
			var a := _t * 3.0 + k * TAU / 3.0
			draw_string(FONT, Vector2(156 - w + cos(a) * 14, 120 + sin(a) * 6), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.3))
		return
	var cx := 160.0 + sin(_t * 2.2) * (3.0 + 6.0 * _drunk())  # se tambalea
	var dy := 8.0 if m_state == "wind" and m_attack == "upper" else 0.0
	if o.get("short", false):
		dy += 10.0  # bajito
	var head := Vector2(cx, 56 + dy)
	if m_state == "hurt":
		head.x += 6.0 * sin(_t * 40.0)
	var flash := m_state == "wind" and int(_t * 12.0) % 2 == 0
	var hw := w / 2.0
	# Torso (la musculosa / la camiseta) y, si tiene, el chaleco de motociclista.
	draw_rect(Rect2(cx - hw, 70 + dy, w, 42), o["body"])
	if o.get("vest", false) and not phase2:
		draw_rect(Rect2(cx - hw, 70 + dy, 12, 42), Color(0.28, 0.18, 0.12))
		draw_rect(Rect2(cx + hw - 12, 70 + dy, 12, 42), Color(0.28, 0.18, 0.12))
		draw_circle(Vector2(cx + hw - 6, 82 + dy), 4.0, Color(0.85, 0.65, 0.2))
	if phase2:  # sin chaleco: se le ven los brazos y un tatuaje de una moto, viejo
		draw_rect(Rect2(cx - hw, 70 + dy, w, 42), SKIN.darkened(0.05))
		draw_circle(Vector2(cx - 10, 86 + dy), 5.0, Color(0.25, 0.35, 0.5))
	if o.get("gold", false):
		draw_line(Vector2(cx - 10, 72 + dy), Vector2(cx, 84 + dy), Color(1, 0.85, 0.3), 2.0)
		draw_line(Vector2(cx + 10, 72 + dy), Vector2(cx, 84 + dy), Color(1, 0.85, 0.3), 2.0)
	if o.get("jacket", false):
		draw_rect(Rect2(cx - 4, 70 + dy, 8, 42), Color(0.75, 0.2, 0.15))
		draw_circle(Vector2(cx - hw + 8, 80 + dy), 3.0, Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(cx - hw + 2, 112 + dy, w - 4, 14), Color(0.7, 0.12, 0.14))
	var hc := SKIN.lerp(Color.WHITE, 0.5) if flash else SKIN
	draw_circle(head, 14.0, hc)
	if o.has("cap"):
		draw_rect(Rect2(head.x - 15, head.y - 15, 30, 7), o["cap"])
		draw_rect(Rect2(head.x - 15, head.y - 9, 36, 2), o["cap"].darkened(0.2))
	else:
		draw_rect(Rect2(head.x - 14, head.y - 14, 28, 8), o["hair"])
	if o.get("mustache", false):
		draw_rect(Rect2(head.x - 8, head.y + 4, 16, 3), Color(0.2, 0.16, 0.16))
	if o.get("freckles", false):
		for p in [Vector2(-7, 2), Vector2(-4, 4), Vector2(5, 3), Vector2(8, 1)]:
			draw_rect(Rect2(head + p, Vector2(1, 1)), Color(0.6, 0.3, 0.15))
	draw_circle(head + Vector2(-5, -1), 1.5, Color.BLACK)
	draw_circle(head + Vector2(5, -1), 1.5, Color.BLACK)
	if o.get("kind", false) and m_state != "taunt":
		draw_arc(head + Vector2(0, 6), 4.0, 0.3, 2.8, 6, Color(0.3, 0.1, 0.1))  # cara buena
	if _drunk() > 0.0:
		draw_circle(head + Vector2(-8, 4), 2.5, Color(0.9, 0.4, 0.4, 0.6))  # cachetes de trago
		draw_circle(head + Vector2(8, 4), 2.5, Color(0.9, 0.4, 0.4, 0.6))
	if m_state == "taunt":
		draw_rect(Rect2(head.x - 3, head.y + 8, 6, 4), Color(0.3, 0.05, 0.08))
	if m_state == "dizzy":
		for k in 3:
			var a := _t * 4.0 + k * TAU / 3.0
			draw_string(FONT, head + Vector2(cos(a) * 18 - 3, -16 + sin(a) * 5), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.3))
	var l := Vector2(cx - hw + 4, 94 + dy)
	var r := Vector2(cx + hw - 4, 94 + dy)
	var lr := 10.0
	var rr := 10.0
	var att := m_attack
	if att == "rush":
		att = "hook_l" if _combo == 0 else "hook_r"
	elif att in ["double", "feint"]:
		att = "jab"
	match m_state:
		"guard":
			l = Vector2(cx - 8, 62)
			r = Vector2(cx + 8, 62)
		"taunt":
			l = Vector2(cx - hw - 6, 110)
			r = Vector2(cx + hw + 2, 70)
		"wind":
			match att:
				"jab":
					r = Vector2(cx + hw + 6, 86)
					rr = 8.0
				"hook_l":
					l = Vector2(cx - hw - 26, 70)
				"hook_r":
					r = Vector2(cx + hw + 26, 70)
				"upper":
					r = Vector2(cx + 16, 124)
		"recover":
			match att:
				"jab":
					r = Vector2(cx + 6, 110)
					rr = 18.0
				"hook_l":
					l = Vector2(cx + 10, 104)
					lr = 16.0
				"hook_r":
					r = Vector2(cx - 10, 104)
					rr = 16.0
				"upper":
					r = Vector2(cx, 70)
					rr = 18.0
	draw_line(Vector2(cx - hw + 2, 76 + dy), l, SKIN, 7.0)
	draw_line(Vector2(cx + hw - 2, 76 + dy), r, SKIN, 7.0)
	_glove(l, lr)
	_glove(r, rr)


func _draw_boy() -> void:
	var x := 160.0
	var y := 150.0
	match p_state:
		"dodge_l":
			x -= 46.0
		"dodge_r":
			x += 46.0
		"hurt":
			x += 4.0 * sin(_t * 50.0)
	if state == "p_down" or (state == "end" and p_hp <= 0.0):
		y += 30.0
	var tint := Color(1, 0.6, 0.6) if p_state == "hurt" else (Color(0.8, 0.8, 1.0) if p_state == "tired" else Color.WHITE)
	draw_rect(Rect2(x - 22, y, 44, 40), Color(0.92, 0.92, 0.88) * tint)
	draw_rect(Rect2(x - 28, y + 4, 8, 20), BOY_SKIN * tint)
	draw_rect(Rect2(x + 20, y + 4, 8, 20), BOY_SKIN * tint)
	draw_circle(Vector2(x, y - 6), 13.0, Color(0.14, 0.12, 0.16))
	draw_rect(Rect2(x - 4, y + 4, 8, 4), BOY_SKIN * tint)
	var l := Vector2(x - 26, y)
	var r := Vector2(x + 26, y)
	var lr := 10.0
	var rr := 10.0
	match p_state:
		"block":
			l = Vector2(x - 9, y - 20)
			r = Vector2(x + 9, y - 20)
		"punch":
			if _jab_side > 0:
				r = Vector2(x + 8, y - 38)
				rr = 7.0
			else:
				l = Vector2(x - 8, y - 38)
				lr = 7.0
		"hook":
			r = Vector2(x - 6, y - 44)
			rr = 8.0
	var red := Color(0.8, 0.15, 0.15) * tint
	draw_circle(l, lr, red)
	draw_circle(r, rr, red)
