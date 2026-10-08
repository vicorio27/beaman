class_name Lukas
extends CharacterBody2D
## Lukas, el beagle. El único que se quedó con él.
##   - Lo sigue a todos lados (no choca con él; sí con las paredes).
##   - Si se queda quieto un rato, se sienta.
##   - F / RB abre su menú:
##     · Buscá: sale a olfatear. Va hasta la cosa más cercana (prefiere comida), ladra y, si estaba
##       escondida, la deja a la vista. Con hambre, a veces no trabaja.
##     · Acariciar: un rato de calma (el filtro de angustia baja; GameState.calm_until).
##     · Comida: concentrado o compartir lo que haya. Una vez por día (flags.lukas_fed_day).
##     · Jugar: con la pelota de trapo; se la tira, la va a buscar y (casi siempre) la trae.

signal found_something(item_id: String)

const SHEET := preload("res://assets/characters/lukas.png")
## Celdas de la hoja (ver tools/art/draw_lukas.py).
const CELL := Vector2(20, 16)
const FOLLOW_DIST := 22.0
const TELEPORT_DIST := 200.0
const SNIFF_RADIUS := 300.0
const SNIFF_COOLDOWN := 6.0
const SEEK_SPEED := 90.0
const SIT_AFTER := 3.0
const THROW_DIST := 70.0
const CALM_MINUTES := 90.0
const PET_LINES := [
	"(Lo rasca detrás de la oreja. Lukas patea con la pata de atrás.)",
	"(Lukas le lame la cara. Mucho. Como revisando que siga ahí.)",
	"(Lukas se pone panza arriba.)",
	"(Lukas le apoya la cabeza en la rodilla. Se quedan así.)",
]
const FETCH_LINES := [
	"(La trae. La suelta a medio metro.)",
	"(La trae toda babeada.)",
	"(Vuelve corriendo con las orejas al viento.)",
]

var player: CharacterBody2D
var state := "follow"
var facing := "side"
var _target: Node2D
var _idle := 0.0
var _cooldown := 0.0
var _found_time := 0.0
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _ball: Sprite2D
var _pet_index := 0
var _fetch_index := 0

var sprite: AnimatedSprite2D
var _bubble: Label


func _ready() -> void:
	collision_layer = 0  # el jugador lo atraviesa
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 4)
	shape.shape = rect
	shape.position = Vector2(0, -2)
	add_child(shape)
	var shadow := Polygon2D.new()
	shadow.color = Color(0.18, 0.13, 0.18, 0.35)
	shadow.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(-4, -2), Vector2(4, -2), Vector2(6, 0), Vector2(4, 2), Vector2(-4, 2)])
	add_child(shadow)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = _frames()
	sprite.position = Vector2(0, -7)
	sprite.play("idle_side")
	add_child(sprite)
	_bubble = Label.new()
	_bubble.text = "!"
	_bubble.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	_bubble.add_theme_font_size_override("font_size", 8)
	_bubble.add_theme_constant_override("outline_size", 3)
	_bubble.add_theme_color_override("font_outline_color", Color.BLACK)
	_bubble.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_bubble.position = Vector2(-3, -26)
	_bubble.visible = false
	add_child(_bubble)


func _frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	var cols := {"side": 0, "down": 1, "up": 2}
	for dir in cols:
		_add(f, "idle_" + dir, [[cols[dir], 0]], 1.0)
		_add(f, "walk_" + dir, [[cols[dir], 1], [cols[dir], 2]], 8.0)
	_add(f, "sit", [[3, 0]], 1.0)
	_add(f, "sniff", [[3, 1], [0, 0]], 4.0)
	_add(f, "bark", [[3, 2], [3, 0]], 5.0)
	return f


func _add(f: SpriteFrames, anim: String, cells: Array, fps: float) -> void:
	f.add_animation(anim)
	f.set_animation_speed(anim, fps)
	for c in cells:
		f.add_frame(anim, cell(c[0], c[1]))


## Un cuadro de la hoja (columna, fila). La columna 3, fila 0: sentado.
static func cell(col: int, row: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = SHEET
	t.region = Rect2(Vector2(col, row) * CELL, CELL)
	return t


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sniff") and not GameState.input_blocked() and not SceneRouter.busy:
		get_viewport().set_input_as_handled()
		menu()


## El menú de Lukas (F).
func menu() -> void:
	var opts := ["Buscá", "Acariciar", "Comida", "Jugar", "Truco", "Nada"]
	var head := "(Me mira. Mueve la cola. Espera instrucciones, o comida, o las dos.)"
	if GameState.lukas_sick():
		head = "(Me mira desde el piso. La cola apenas se mueve. Está enfermo.)"
	if GameState.lukas_stage() == 1:
		head = "(Me mira. Mueve la cola. Tose una vez, como pidiendo perdón.)"
	elif GameState.lukas_stage() == 3:
		head = "(Respira rápido. Me mira largo, como si me estuviera aprendiendo de memoria.)"
	var i := await Dialogue.talk([["LUKAS", head]], opts)
	if i == 4:
		await tricks()
		return
	match i:
		0:
			sniff()
		1:
			pet()
		2:
			await feed()
		3:
			fetch()


## Los trucos: hacer uno que ya sabe, o enseñarle uno nuevo (una sesión por día).
func tricks() -> void:
	var f := GameState.flags
	var known: Array = []
	var learning: Array = []
	for t in GameState.LUKAS_TRICKS:
		if GameState.lukas_knows(t):
			known.append(t)
		else:
			learning.append(t)
	var opts: Array = []
	for t in known:
		opts.append(GameState.LUKAS_TRICKS[t][0])
	var can_teach: bool = not learning.is_empty() and f.get("truco_dia", -1) != GameState.day and not GameState.lukas_sick() \
		and GameState.lukas_stage() < 2
	if can_teach:
		opts.append("Enseñarle uno nuevo")
	opts.append("Nada")
	var i := await Dialogue.talk([["", "Trucos: %d de %d." % [known.size(), GameState.LUKAS_TRICKS.size()]]], opts)
	if i < known.size():
		_do_trick(known[i])
	elif can_teach and opts[i] == "Enseñarle uno nuevo":
		await _teach(learning)


func _do_trick(t: String) -> void:
	state = "found"
	_found_time = 2.5
	sprite.play("sit")
	_bubble.text = {"sentarse": "...", "pata": "*pata*", "muerto": "x_x", "saludar": "!"}[t]
	_bubble.visible = true
	if TimeManager.minutes - GameState.flags.get("truco_mood_at", -999.0) > 60.0:
		GameState.flags["truco_mood_at"] = TimeManager.minutes
		GameState.change_mood(4.0)
	Narrator.say({"sentarse": "(Palma hacia abajo. Lukas se sienta.)",
		"pata": "(Mano abierta. Lukas le da la pata. La izquierda.)",
		"muerto": "(Dedo en forma de pistola. Lukas se tira de lado. Abre un ojo para ver si lo están mirando.)",
		"saludar": "(Levanta la mano. Lukas se para en dos patas y mueve las de adelante. Una señora que pasa se ríe.)"}[t])


func _teach(learning: Array) -> void:
	var f := GameState.flags
	var names: Array = []
	for t in learning:
		names.append(GameState.LUKAS_TRICKS[t][0])
	names.append("Nada")
	var i := await Dialogue.talk([["", "(Lukas mira las manos, esperando la seña.)"]], names)
	if i >= learning.size():
		return
	var t: String = learning[i]
	var treat := ""
	for id in ["concentrado", "pan", "empanada", "arepa", "fruta"]:
		if GameState.count(id) > 0:
			treat = id
			break
	var how := ["Con paciencia (gratis, a veces no sale)"]
	if treat != "":
		how.push_front("Con premio (%s)" % Items.info(treat)["name"].to_lower())
	var j := await Dialogue.talk([["", "%s. %s" % [GameState.LUKAS_TRICKS[t][0], GameState.LUKAS_TRICKS[t][1]]]], how)
	var with_treat: bool = treat != "" and j == 0
	if with_treat:
		GameState.remove_item(treat)
	f["truco_dia"] = GameState.day
	TimeManager.skip(0.5)
	if with_treat or randf() < 0.5:
		f["truco_" + t] = int(f.get("truco_" + t, 0)) + 1
		var n := int(f["truco_" + t])
		if n >= 3:
			_do_trick(t)
			Narrator.say("¡Aprendió: %s! %s" % [GameState.LUKAS_TRICKS[t][0], GameState.LUKAS_TRICKS[t][1]])
		else:
			Narrator.say("(Sesión %d de 3. Lukas casi entiende la seña.)" % n)
	else:
		Narrator.say("(Lukas se acuesta y lo mira. Hoy no.)")


func pet() -> void:
	state = "found"
	_found_time = 6.0
	sprite.play("sit")
	_bubble.text = "<3"
	_bubble.visible = true
	GameState.calm_until = TimeManager.minutes + CALM_MINUTES
	GameState.flags["lukas_pets"] = GameState.flags.get("lukas_pets", 0) + 1
	if TimeManager.minutes - GameState.flags.get("lukas_pet_at", -999.0) > 60.0:  # no es una máquina
		GameState.flags["lukas_pet_at"] = TimeManager.minutes
		GameState.change_mood(6.0)
	Narrator.say(PET_LINES[_pet_index % PET_LINES.size()])
	_pet_index += 1


func feed() -> void:
	var f := GameState.flags
	if f.get("lukas_fed_day", -1) == GameState.day:
		Narrator.say("(Ya comió hoy. Lukas lo mira como si no.)")
		return
	if GameState.count("concentrado") > 0:
		GameState.remove_item("concentrado")
		Narrator.say("(Se come el concentrado en cuatro segundos.)")
	else:
		var food := ""
		for s in GameState.inventory:
			if s != null and Items.info(s["id"])["type"] == "comida":
				food = s["id"]
				break
		if food == "":
			Narrator.say("(No tiene nada para darle.)")
			return
		var name: String = Items.info(food)["name"].to_lower()
		var i := await Dialogue.talk([["", "(No tiene concentrado. ¿Compartirle: %s?)" % name]], ["Compartir", "No"])
		if i != 0:
			return
		GameState.remove_item(food)
		Narrator.say("(Le da la mitad. Después, el resto.)")
	f["lukas_fed_day"] = GameState.day
	f.erase("lukas_hungry")
	state = "found"
	_found_time = 1.5
	sprite.play("bark")


func fetch() -> void:
	if GameState.count("pelota_trapo") == 0:
		Narrator.say("(No tiene con qué jugar. Una pelota de trapo: camiseta + cuerda [C].)")
		return
	var dir := Vector2.DOWN
	match player.facing:
		"side":
			dir = Vector2.RIGHT if player.sprite.flip_h else Vector2.LEFT
		"up":
			dir = Vector2.UP
	if _ball == null:
		_ball = Sprite2D.new()
		_ball.texture = Items.icon("pelota_trapo")
		_ball.scale = Vector2(0.6, 0.6)
		get_parent().add_child(_ball)
	_ball.visible = true
	_ball.global_position = player.global_position + Vector2(0, -10)
	var land := player.global_position + dir * THROW_DIST
	var t := create_tween().set_parallel()
	t.tween_property(_ball, "global_position:x", land.x, 0.6)
	t.tween_method(func(k: float): _ball.global_position.y = lerpf(player.global_position.y - 10, land.y - 4, k) - sin(k * PI) * 26.0,
		0.0, 1.0, 0.6)
	Narrator.say("(Le muestra la pelota. La tira.)")
	state = "fetch_go"
	_stuck = 0.0


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_cooldown -= delta
	var to_player := player.global_position - global_position
	if to_player.length() > TELEPORT_DIST and state != "seek":
		_teleport_behind()
		return
	match state:
		"follow", "sit":
			if to_player.length() > FOLLOW_DIST:
				state = "follow"
				_idle = 0.0
				var spd: float = player.speed * player.speed_scale * 1.15
				_walk(to_player.normalized() * spd)
			else:
				_walk(Vector2.ZERO)
				_idle += delta
				if _idle > SIT_AFTER:
					state = "sit"
					sprite.play("sit")
		"seek":
			if not is_instance_valid(_target):
				state = "follow"
				return
			var to_t := _target.global_position + Vector2(10, 0) - global_position
			if to_t.length() < 6.0:
				_arrive()
			else:
				_walk(to_t.normalized() * SEEK_SPEED)
				_check_stuck(delta)
		"fetch_go":
			var to_b := _ball.global_position + Vector2(0, 4) - global_position
			if to_b.length() < 5.0:
				_ball.visible = false
				state = "fetch_back"
			else:
				_walk(to_b.normalized() * SEEK_SPEED)
				_check_stuck_at(delta, _ball.global_position)
		"fetch_back":
			if to_player.length() < 16.0:
				_fetch_done()
			else:
				_walk(to_player.normalized() * SEEK_SPEED)
				_check_stuck_at(delta, player.global_position + Vector2(-12, 4))
		"found":
			_walk(Vector2.ZERO)
			_found_time -= delta
			if _found_time <= 0.0 or (to_player.length() < 18.0 and _found_time < 2.5):
				_bubble.visible = false
				state = "follow"
	z_index = 0


func _walk(v: Vector2) -> void:
	v *= [1.0, 0.9, 0.75, 0.55, 0.5][GameState.lukas_stage()]  # la enfermedad larga lo cansa
	velocity = v
	move_and_slide()
	if v == Vector2.ZERO:
		if state != "sit" and state != "found":
			sprite.play("idle_" + facing)
		return
	if absf(v.x) > absf(v.y):
		facing = "side"
		sprite.flip_h = v.x > 0  # la hoja mira a la izquierda
	else:
		facing = "down" if v.y > 0 else "up"
	sprite.play("walk_" + facing)


func _check_stuck(delta: float) -> void:
	_check_stuck_at(delta, _target.global_position + Vector2(10, 2))


func _check_stuck_at(delta: float, unstuck_to: Vector2) -> void:
	if global_position.distance_to(_last_pos) < 0.3:
		_stuck += delta
		if _stuck > 1.2:
			# Trabado contra una pared: aparece al lado de lo que buscaba.
			global_position = unstuck_to
			_stuck = 0.0
	else:
		_stuck = 0.0
	_last_pos = global_position


func _teleport_behind() -> void:
	global_position = player.global_position + Vector2(-14, 4)
	state = "follow"


## Sale a olfatear. Devuelve true si encontró algo para ir a buscar.
func sniff() -> bool:
	if _cooldown > 0.0 or state == "seek":
		return false
	_cooldown = SNIFF_COOLDOWN * (1.0 + GameState.diff("olfato"))
	if GameState.lukas_sick():
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas no quiere buscar. Tiene la nariz caliente: veterinaria.)")
		return false
	if thirsty() and randf() < 0.4:
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas tiene la lengua afuera. Con sed no huele nada: un cuenco con agua.)")
		return false
	if GameState.flags.get("lukas_hungry", false) and randf() < 0.5:
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas olfatea... y se sienta. Con hambre no busca.)")
		return false
	_target = _nearest_pickup()
	if _target == null:
		state = "found"
		_found_time = 1.5
		sprite.play("sniff")
		Narrator.say("(Lukas olfatea... nada.)")
		return false
	state = "seek"
	_stuck = 0.0
	sprite.play("sniff")
	Narrator.say("(Chasquea los dedos y señala el piso. Lukas pega la nariz al suelo.)")
	return true


func _nearest_pickup() -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for p in get_tree().get_nodes_in_group("pickups"):
		var d: float = p.global_position.distance_to(global_position)
		if d > SNIFF_RADIUS * (1.0 - 0.4 * GameState.diff("olfato")) * (1.5 if GameState.has_skill("rebusque") else 1.0):
			continue
		# Prefiere comida y lo escondido (lo que el jugador no puede ver solo).
		var score := d
		if Items.info(p.item_id)["type"] == "comida":
			score *= 0.5
		if Items.info(p.item_id)["type"] == "especial":  # lo que busca para alguien, primero
			score *= 0.2
		if p.concealed:
			score *= 0.7
		if score < best_score:
			best_score = score
			best = p
	return best


func _arrive() -> void:
	state = "found"
	_found_time = 5.0
	sprite.flip_h = _target.global_position.x > global_position.x
	sprite.play("bark")
	_bubble.text = "!"
	_bubble.visible = true
	if _target.concealed:
		_target.reveal()
		Narrator.say("(¡Guau! Lukas encontró algo.)")
	else:
		Narrator.say("¡Guau!")
	GameState.flags["lukas_sniffed"] = true
	found_something.emit(_target.item_id)


func _fetch_done() -> void:
	state = "found"
	_found_time = 4.5
	sprite.flip_h = player.global_position.x > global_position.x
	GameState.calm_until = maxf(GameState.calm_until, TimeManager.minutes + CALM_MINUTES / 2.0)
	GameState.change_mood(4.0)
	if randf() < 0.25:
		sprite.play("sit")
		Narrator.say("(No se la da. Se acuesta encima.)")
	else:
		sprite.play("bark")
		Narrator.say(FETCH_LINES[_fetch_index % FETCH_LINES.size()])
		_fetch_index += 1


## Sed: si a la tarde todavía no tomó agua en un cuenco.
static func thirsty() -> bool:
	return GameState.day >= 2 and TimeManager.hour() >= 14 and GameState.flags.get("lukas_water_day", -1) != GameState.day
