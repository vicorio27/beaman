extends Node2D
## La fila de la Registraduría (Día 3 en adelante): un minijuego corto.
## Cuantos tenés adelante depende de a qué hora llegaste. La fila avanza sola; el reloj corre
## hasta las 11:00 (cierran). De vez en cuando alguien se intenta colar delante tuyo: tenés un
## momento para reclamarle (interactuar). Si llegás a la ventanilla, la funcionaria revisa los
## requisitos (fotos, dirección, $55.000). Si vas "de parte de Zaida", entrás casi de primero.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CENTRO := "res://scenes/world/Centro.tscn"
const OPEN := 8 * 60
const CLOSE := 11 * 60
const MINUTES_PER_SECOND := 3.0
const ADVANCE_EVERY := 3.0       # segundos reales entre turno y turno
const SLOT_X := 92.0
const SLOT_GAP := 15.0
const LINE_Y := 120.0
const REACT := 1.6               # segundos para reclamarle al colado
const PRICE := 55000
const ROWS := [0, 3, 6, 9, 12, 15]
## Él no reclama: le toca el hombro al colado y señala el final de la fila. El colado se pone nervioso.
const CLAIMS := [
	"(Le toca el hombro. Señala el final de la fila.)",
	"(Se le para al lado. No dice nada. Lo mira.)",
	"(Señala la fila. Señala al colado. Señala la fila.)",
]
## Mientras espera (E sin colado): algo que mirar, con su comentario. La fila es larga; que no sea muda.
const WAIT_LINES := [
	"(Lee el cartel de requisitos. Por cuarta vez. Sigue sin decir dónde se consiguen los requisitos.)",
	"(La señora de adelante le muestra a Lukas una foto de su gato. Lukas la mira con respeto profesional.)",
	"(Cuenta las baldosas hasta la puerta. Cuarenta y tres. Mañana van a ser las mismas. Eso es estabilidad.)",
	"(El celador grita \"¡fotocopias aparte!\". Nadie sabe aparte de qué.)",
	"(Un señor ofrece \"agilizar el trámite\" por veinte mil. Lukas le gruñe. Lukas es incorruptible.)",
	"(Le da a Lukas el último pedazo de pan. Lukas lo recibe como si fuera la cédula.)",
	"(Mira el reloj de la entidad. Está parado en las 9:15. Desde 2019. Nadie lo arregla: no es su trámite.)",
]
const EXCUSES := ["—¿Qué? ¿Qué me señala? ... Ay, ya, ya, me voy.", "—Yo estaba aquí desde las cinco. Bueno, desde las siete. Bueno, me voy.",
	"—Es que yo solo venía a preg... Bueno. Bueno. Ya.", "—¿Y ese perro por qué me mira así? ... Ya, ya, al final."]

var minutes := 0.0
var ahead := 0
var state := "wait"              # wait, queue, colado, window, done
var _advance := ADVANCE_EVERY
var _next_colado := 6.0
var _react := 0.0
var _colado: AnimatedSprite2D
var _people: Array[AnimatedSprite2D] = []
var _me: AnimatedSprite2D
var _clock: Label
var _info: Label
var _prompt: Label
var _start_minutes := 0.0
var _claim_i := 0


func _ready() -> void:
	_build_street()
	minutes = maxf(TimeManager.minutes, OPEN)
	_start_minutes = TimeManager.minutes
	var arrival := TimeManager.minutes
	ahead = clampi(int((arrival - 6 * 60) / 15.0) + 4 + int(6 * GameState.difficulty()), 3, 36)
	var f := GameState.flags
	var vip: bool = f.get("fila_vip_day", -1) == GameState.day and (GameState.count("direccion_zaida") > 0 or f.get("vip_labia", false))
	if vip:
		ahead = 1
	for i in ahead:
		_people.append(_person(ROWS[i % ROWS.size()], i))
	_me = _sprite(CharacterFrames.protagonist())
	_me.position = _slot(ahead)
	add_child(_me)
	var lukas := Sprite2D.new()
	lukas.texture = Lukas.cell(3, 0)
	lukas.position = _slot(ahead) + Vector2(4, 12)
	lukas.name = "Lukas"
	add_child(lukas)
	_build_hud()
	_run(vip)


func _build_street() -> void:
	var ts: TileSet = load("res://assets/barrio/barrio_tileset.tres")
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	add_child(ground)
	for y in 12:
		for x in 20:
			var t := 17
			if y in [6, 7, 8]:
				t = 13
			elif y == 9:
				t = 16
			elif y >= 10:
				t = 11 if y == 11 and x % 2 == 0 else 8
			ground.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	for p in [["registraduria", Vector2(56, 100)], ["edificio_centro", Vector2(200, 100)], ["house_f", Vector2(290, 100)]]:
		var s := Sprite2D.new()
		s.texture = load("res://assets/barrio/%s.png" % p[0])
		s.centered = false
		s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
		s.position = p[1]
		add_child(s)


func _sprite(frames: SpriteFrames) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames
	a.play("idle_side")
	a.offset = Vector2(0, -8)
	return a


## Un desconocido de la fila, como lo ve él (ver CharacterFrames.dress).
func _stranger(row: int) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	CharacterFrames.dress(a, row)
	a.play("idle_side")
	a.offset = Vector2(0, -8)
	return a


func _person(row: int, i: int) -> AnimatedSprite2D:
	var a := _stranger(row)
	a.position = _slot(i)
	a.modulate = GameState.same_tint(Color.from_hsv(fmod(i * 0.137, 1.0), 0.18, 1.0))
	add_child(a)
	return a


func _slot(i: int) -> Vector2:
	var x := SLOT_X + i * SLOT_GAP
	var y := LINE_Y
	if x > 300.0:  # la fila dobla y sigue por la vereda de abajo
		x = 300.0 - (x - 300.0)
		y += 18.0
	return Vector2(x, y)


func _build_hud() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_clock = _label(ui, Vector2(6, 4))
	_info = _label(ui, Vector2(6, 16))
	_prompt = _label(ui, Vector2(0, 150))
	_prompt.size = Vector2(Controls.right_edge(), 10)
	_prompt.add_to_group("under_dialogue")
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_color_override("font_color", Color(1, 0.85, 0.3))


func _label(parent: Node, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	parent.add_child(l)
	return l


func _run(vip: bool) -> void:
	await get_tree().create_timer(0.8).timeout
	if vip and GameState.flags.get("vip_labia", false):
		await Dialogue.talk([["CELADOR", "—¡Sobrino! Pase, pase."], ["CELADOR", "—Mi sobrino favorito. El de Ibagué. Saludes a mi hermana."]])
	elif vip:
		await Dialogue.talk([["CELADOR", "—¿De parte de Zaida? ... Pase. Adelante. Casi de primero."],
			["SEÑORA DE LA FILA", "—¡Se coló! ¡Ese señor se coló! ... ¡Y ni pide perdón! ¡Y con perro!"]])
	elif ahead > 14:
		await Dialogue.talk([["", "(%d personas delante.)" % ahead]])
	else:
		await Dialogue.talk([["", "(%d personas delante.)" % ahead]])
	state = "queue"


func _process(delta: float) -> void:
	_clock.text = "%02d:%02d   CIERRAN 11:00" % [int(minutes) / 60, int(minutes) % 60]
	_info.text = "Delante tuyo: %d" % ahead
	if state != "queue" and state != "colado":
		return
	minutes += delta * MINUTES_PER_SECOND
	if minutes >= CLOSE:
		_closed()
		return
	if state == "colado":
		_react -= delta
		_colado.position = _colado.position.move_toward(_slot(ahead - 1) + Vector2(6, 6), delta * 30.0)
		if _react <= 0.0:
			_colado_wins()
		return
	_advance -= delta
	if _advance <= 0.0:
		_advance = ADVANCE_EVERY
		_step()
	_next_colado -= delta
	if _next_colado <= 0.0 and ahead > 1:
		_start_colado()


## Pasa uno a la ventanilla y todos corren un lugar.
func _step() -> void:
	if ahead <= 0:
		return
	var first: AnimatedSprite2D = _people.pop_front()
	var t := create_tween()
	t.tween_property(first, "modulate:a", 0.0, 0.4)
	t.tween_callback(first.queue_free)
	ahead -= 1
	for i in _people.size():
		_walk_to(_people[i], _slot(i))
	_walk_to(_me, _slot(ahead))
	_walk_to(get_node("Lukas"), _slot(ahead) + Vector2(4, 12))
	if ahead == 0:
		_window()


func _walk_to(n: Node2D, to: Vector2) -> void:
	if n is AnimatedSprite2D:
		n.play("walk_side")
	var t := create_tween()
	t.tween_property(n, "position", to, 0.5)
	if n is AnimatedSprite2D:
		t.tween_callback(n.play.bind("idle_side"))


func _start_colado() -> void:
	state = "colado"
	_react = REACT * (1.0 - 0.35 * GameState.diff("reflejos")) * (1.5 if GameState.has_skill("sangre_fria") else 1.0)
	_colado = _stranger(ROWS.pick_random())
	_colado.modulate = GameState.same_tint(Color(0.9, 0.85, 0.75))
	_colado.position = _slot(ahead) + Vector2(10, 40)
	_colado.play("walk_side")
	add_child(_colado)
	_prompt.text = Controls.keys_in("[E] ¡LA FILA!")


var _wait_i := 0
var _wait_cd := 0.0


func _unhandled_input(event: InputEvent) -> void:
	if state == "queue" and event.is_action_pressed("interact") and Time.get_ticks_msec() / 1000.0 > _wait_cd:
		get_viewport().set_input_as_handled()
		_wait_cd = Time.get_ticks_msec() / 1000.0 + 2.5
		Narrator.say(WAIT_LINES[_wait_i % WAIT_LINES.size()], true)
		_wait_i += 1
		return
	if state == "colado" and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_prompt.text = ""
		state = "queue"
		_next_colado = randf_range(5.0, 9.0)
		Narrator.say(CLAIMS[_claim_i % CLAIMS.size()] + " " + EXCUSES[_claim_i % EXCUSES.size()], true)
		_claim_i += 1
		var c := _colado
		c.flip_h = true
		var t := create_tween()
		t.tween_property(c, "position", c.position + Vector2(60, 50), 1.2)
		t.tween_callback(c.queue_free)


## No le reclamó a tiempo: se metió delante.
func _colado_wins() -> void:
	_prompt.text = ""
	state = "queue"
	_next_colado = randf_range(5.0, 9.0)
	_colado.play("idle_side")
	_people.insert(ahead - 1, _colado)
	ahead += 1
	for i in _people.size():
		_walk_to(_people[i], _slot(i))
	_walk_to(_me, _slot(ahead))
	_walk_to(get_node("Lukas"), _slot(ahead) + Vector2(4, 12))
	Narrator.say("(Se coló uno.)", true)


func _closed() -> void:
	state = "done"
	minutes = CLOSE
	_prompt.text = ""
	await Dialogue.talk([["CELADOR", "—¡Cerramos! Los que no alcanzaron, mañana. Temprano. Más temprano que hoy."],
		["", "(Horas parado. Lukas durmió una siesta.)"]])
	_leave()


## La ventanilla: la funcionaria revisa los requisitos.
func _window() -> void:
	state = "window"
	_prompt.text = ""
	var address := "carta_german" if GameState.count("carta_german") > 0 else ("direccion_zaida" if GameState.count("direccion_zaida") > 0 else "")
	var missing := []
	if GameState.count("foto_doc") == 0:
		missing.append("las fotos")
	if address == "":
		missing.append("una dirección")
	if GameState.money < PRICE:
		missing.append("la plata ($55.000)")
	await Dialogue.talk([["FUNCIONARIA", "—Siguiente. ¿Qué trámite?"], ["", "(...)"],
		["FUNCIONARIA", "—¿Qué trámite, señor? ... ¿Me escucha? ... Ay, un papel. Bueno, a ver el papel. ... Duplicado de cédula."]])
	if not missing.is_empty():
		await Dialogue.talk([
			["FUNCIONARIA", "—Le falta: %s. Siguiente." % ", y ".join(missing)],
			["", "(Horas de fila.)"],
		])
		_leave()
		return
	var addr_line := "—¿Calle 9 número 14-32? Bueno." if address == "carta_german" else \
		"—¿Esta dirección? ... Ah, de Zaida. Ella viene mucho por acá. Bueno."
	await Dialogue.talk([
		["FUNCIONARIA", "—Fotos... bien. Dirección..."],
		["FUNCIONARIA", addr_line],
		["FUNCIONARIA", "—Son cincuenta y cinco mil."],
		["", "(Cuenta los billetes uno por uno. Despacio.)"],
		["FUNCIONARIA", "—Listo. Vuelva en cinco días hábiles."],
		["FUNCIONARIA", "—... ¿Me entendió? Cinco días. Hábiles. Muéstreme cinco dedos. ... Eso. Siguiente."],
	])
	GameState.add_money(-PRICE)
	GameState.remove_item("foto_doc")
	GameState.remove_item(address)
	GameState.flags["cedula_day"] = GameState.day + 2
	GameState.complete_quest("cedula")
	for q in ["c_plata", "c_foto", "c_direccion"]:
		GameState.quests[q] = "done"
	GameState.start_quest("recoger_cedula")
	_leave()


func _leave() -> void:
	state = "done"
	TimeManager.skip((minutes - _start_minutes) / 60.0)
	SceneRouter.go(CENTRO, "FromRegistraduria")
