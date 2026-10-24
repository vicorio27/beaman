class_name Lukas
extends CharacterBody2D
## Lukas, el beagle. El único que se quedó con él.
##   - Lo sigue a todos lados (no choca con él; sí con las paredes).
##   - Si se queda quieto un rato, se sienta.
##   - F / RB (o la acción parado al lado de él; en el celular, la huellita) abre su menú:
##     · Buscá: sale a olfatear. Va hasta la cosa más cercana (prefiere comida), ladra y, si estaba
##       escondida, la deja a la vista. Con hambre, a veces no trabaja.
##     · Acariciar: un rato de calma (el filtro de angustia baja; GameState.calm_until).
##     · Comida: concentrado o compartir lo que haya. Una vez por día (flags.lukas_fed_day).
##     · Jugar: con la pelota de trapo; se la tira, la va a buscar y (casi siempre) la trae.
##     · Hablarle: a Lukas sí le habla, en voz alta. Baja la soledad (barra de compañía del HUD).
##     · Juego de miradas: cara a cara (Dialogue.face_off). Él, Lukas, él... y Lukas ladra: "dame algo".
##   - Cuando él le habla a alguien, Lukas va y lo huele (greet). Según quién (GREET): se queda a que lo
##     consientan, con corazoncitos, o se devuelve donde él, bravo (resopla) y se le sienta de espaldas.

signal found_something(item_id: String)
signal at_bowl

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
## Tomando agua: el nodo queda a este lado del cuenco (el hocico adentro; ver draw_lukas.py).
const BOWL_SIDE := 9.0
const DRINK_TIME := 4.0
const PET_LINES := [
	"(Lo rasca detrás de la oreja. Lukas patea con la pata de atrás.)",
	"(Lukas le lame la cara. Mucho. Como revisando que siga ahí.)",
	"(Lukas se pone panza arriba.)",
	"(Lukas le apoya la cabeza en la rodilla. Se quedan así.)",
]
## A quién quiere Lukas (true: se queda a que lo consientan; false: se devuelve bravo). Los demás, según
## cómo le huelan (siempre lo mismo para la misma persona).
const GREET := {"german": true, "rosa": true, "marta": true, "wilson": true, "samuel": true, "padre": true,
	"viejos": true, "viejo2": true, "leonor": true, "fabiola": true, "aurelio": true, "al": true, "brenda": true,
	"ramiro": true, "mono": false, "celador": false, "efrain": false, "lisandro": false, "lilato": false,
	"lorena": false, "policia": false, "camila": false, "guillermo": false, "zaida": false}
const FETCH_LINES := [
	"(La trae. La suelta a medio metro.)",
	"(La trae toda babeada.)",
	"(Vuelve corriendo con las orejas al viento.)",
]

var player: CharacterBody2D
var state := "follow"
## El día que él no se levanta, el jugador maneja a Lukas (LukasManda).
var manda := false
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
var _bowl_spot := Vector2.ZERO
var _bowl_right := false
var _settle_spot := Vector2.ZERO
var _settle_t := 0.0
var _greet_who: Node2D
var _greet_likes := false
var _greet_t := 0.0


## Acomodarse en `at` mientras él está sentado: va, se sienta, da una vuelta, se echa y al rato se
## duerme. Se levanta solo cuando él se para.
func settle(at: Vector2) -> void:
	if state in ["seek", "fetch_go", "fetch_back", "drink_go", "drinking"]:
		return  # está ocupado en lo suyo
	_bubble.visible = false
	_settle_spot = at
	_settle_t = 0.0
	state = "settle_go"

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
	_bubble.add_to_group("texto_mundo")  # (Hud: no se monta sobre otro texto)
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
	_add(f, "drink", [[0, 3], [1, 3]], 4.0)
	_add(f, "lie", [[2, 3]], 1.0)
	_add(f, "sleep", [[3, 3]], 1.0)
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
	if GameState.input_blocked() or SceneRouter.busy:
		return
	if event.is_action_pressed("sniff"):
		get_viewport().set_input_as_handled()
		menu()
	elif event.is_action_pressed("interact") and _player_near() and _player_facing_me() and not _other_interactable():
		# Hablarle (acción al lado de él) también abre su menú: en el celular no hay F.
		get_viewport().set_input_as_handled()
		menu()


const TALK_DIST := 22.0


func _player_near() -> bool:
	return player != null and global_position.distance_to(player.global_position) < TALK_DIST


## ¿El protagonista está mirando hacia Lukas? (Solo así la acción es para él.)
func _player_facing_me() -> bool:
	var to := global_position - player.global_position
	match player.facing:
		"side":
			return absf(to.y) < 14.0 and (to.x > 0) == player.sprite.flip_h
		"up":
			return to.y < 0 and absf(to.x) < 16.0
		_:
			return to.y > 0 and absf(to.x) < 16.0


## ¿El jugador está parado en otra cosa que se usa con la acción (persona, puerta, servicio...)?
## Esas tienen prioridad sobre Lukas. (Las personas son CharacterBody2D, no Area2D: se miran todos.)
func _other_interactable() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for n in scene.find_children("*", "", true, false):
		if n != self and n.get("_player") == player:
			return true
	return false


## El menú de Lukas (F).
func menu() -> void:
	var opts := ["Buscá", "Acariciar", "Comida", "Jugar", "Truco", "Hablarle", "Juego de miradas", "Nada"]
	var head := "(Lo mira. Mueve la cola. Espera instrucciones, o comida, o las dos.)"
	if GameState.lukas_sick():
		head = "(Lo mira desde el piso. La cola apenas se mueve. Está enfermo.)"
	if GameState.lukas_stage() == 1:
		head = "(Lo mira. Mueve la cola. Tose una vez, como pidiendo perdón.)"
	elif GameState.lukas_stage() == 3:
		head = "(Respira rápido. Lo mira largo, como si se lo estuviera aprendiendo de memoria.)"
	elif GameState.is_lonely():
		head = "(Hace horas que no habla con nadie. Lukas se le sienta enfrente, como esperando que diga algo.)"
	var i := await Dialogue.talk([["LUKAS", head]], opts)
	if i == 4:
		await tricks()
		return
	if i == 5:
		await talk_to()
		return
	if i == 6:
		await stare()
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
		"saludar": "(Levanta la mano. Lukas se para en dos patas y mueve las de adelante. Una señora que pasa se ríe.)"}[t], false, "lukas_truco")


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
			Narrator.say("¡Aprendió: %s! %s" % [GameState.LUKAS_TRICKS[t][0], GameState.LUKAS_TRICKS[t][1]], false, "lukas_truco")
		else:
			Narrator.say("(Sesión %d de 3. Lukas casi entiende la seña.)" % n, false, "lukas_escucha")
	else:
		Narrator.say("(Lukas se acuesta y lo mira. Hoy no.)", false, "lukas_triste")


## Hablarle a Lukas: afuera es mudo, pero a Lukas sí le habla (en voz alta, bajito). Baja la soledad.
const TALK_NARRATION := [
	"(Se agacha y le habla a Lukas, bajito. Lo que le dice es entre ellos dos.)",
	"(Le cuenta algo a Lukas al oído. Lukas mueve una oreja, la que escucha.)",
	"(Le habla a Lukas un rato largo. Nadie más lo oye. Nadie más tiene por qué.)",
	"(Le dice algo a Lukas y se ríe. Sin sonido, pero se ríe.)",
]
## Lo que antes le decía en voz alta (ya no se muestra; queda por si vuelve a hablar).
const TALKS := [
	"—Vos sí entendés. No decís nada, pero entendés. Somos dos mudos con buena actitud.",
	"—Hoy un señor me dio una moneda sin mirarme. Yo tampoco lo miré. Empate.",
	"—¿Te acordás de la casa? Tenía sofá. Vos no te podías subir. Ahora dormimos en el piso los dos. Ganaste vos.",
	"—Gracias por quedarte. No tenías por qué. Los perros no firman nada.",
	"—Si algún día hablás, no le contés a nadie lo de la sopa. Ni lo del primer día.",
	"—Lorena dice que comés más que un niño. Mentira. Comés más que dos.",
	"—Victoria cumple doce el 29 de octubre. Doce, Lukas. Cuando nació, le cabía la mano entera alrededor de mi dedo.",
	"—Mañana va a ser mejor. No sé por qué lo digo. Vos me mirás como si fuera verdad, y eso ya ayuda.",
	"—Si te encuentro algo bueno en la basura, es tuyo. Si es muy bueno, lo partimos. Si es pizza, ya veremos.",
	"—A veces se me olvida cómo suena mi voz. Por eso te hablo. Para que no se me pierda.",
]
const LUKAS_ANSWERS := [
	"(Lukas ladea la cabeza. Mueve la cola dos veces: una es sí, la otra es comida.)",
	"(Lukas le pone la pata en la rodilla. Se quedan así un rato.)",
	"(Lukas suspira, con ese suspiro de perro que suena a persona cansada.)",
	"(Lukas le lame la mano. Es su forma de decir \"ya, ya\".)",
	"(Lukas se echa encima de sus pies. No lo va a dejar ir a ningún lado.)",
]


func talk_to() -> void:
	var f := GameState.flags
	var lines: Array = []
	# Lo que le dice no se lee: es entre ellos dos (él no tiene diálogos, ni siquiera con Lukas).
	if not f.get("le_hablo_a_lukas", false):
		f["le_hablo_a_lukas"] = true
		lines.append(["", "(Afuera no le sale la voz. Con Lukas sí: se agacha y le habla bajito, al oído.)"])
	else:
		var idx := int(f.get("lukas_charla", 0))
		lines.append(["", TALK_NARRATION[idx % TALK_NARRATION.size()]])
	f["lukas_charla"] = int(f.get("lukas_charla", 0)) + 1
	lines.append(["", LUKAS_ANSWERS.pick_random()])
	state = "found"
	_found_time = 4.0
	sprite.play("sit")
	_bubble.text = "<3"
	_bubble.visible = true
	await Dialogue.talk(lines)
	# Mucho mejor si de verdad estaba solo; si acaba de hablarle, un poco menos.
	var fresh: bool = TimeManager.minutes - float(f.get("lukas_charla_at", -999.0)) > 60.0
	f["lukas_charla_at"] = TimeManager.minutes
	GameState.company(30.0 if fresh else 10.0)
	if fresh:
		GameState.change_mood(3.0)


## Juego de miradas: los dos cara a cara. Él mira, Lukas mira, él aguanta... y Lukas ladra.
## (Traducción del ladrido: no me jodás, ¿para qué juego de miradas? Dame algo.)
const STARES := [
	["(Juego de miradas. El que parpadee primero, pierde. Lo mira fijo. Es una piedra.)",
		"(Humano mirándome. Sin comida en la mano. Raro. Sigo mirando: así es como llega la comida.)",
		"(Le arden los ojos. Se le aguan. Perdió casa, trabajo y familia. Esto no lo pierde.)"],
	["(Revancha. Se acomoda. Lo mira como lo miraba el jefe cuando él pedía aumento.)",
		"(Otra vez el humano. Ladeo la cabeza. Esto le funciona a los perros de los comerciales.)",
		"(Le tiembla un ojo. Piensa en cosas secas: el desierto, una galleta de soda, su vida.)"],
	["(Tercera vez. Hoy entrenó: estuvo mirando un poste toda la mañana.)",
		"(Lo miro como miro la nevera de la panadería. Con fe. Con hambre. Él no es una nevera.)",
		"(Ya no siente la cara. Si gana, se lo merece. Si pierde, también.)"],
]
const BARK_MEANING := [
	"(Traducción: «No me jodás. ¿Juego de miradas? ¿Para qué? Dame algo.»)",
	"(Traducción: «Otra vez con esto. Yo miro por comida, no por deporte. Dame algo.»)",
	"(Traducción: «Usted parpadea o no parpadea, igual tengo hambre. DAME ALGO.»)",
]


func stare() -> void:
	var f := GameState.flags
	var n := int(f.get("miradas", 0))
	f["miradas"] = n + 1
	var s: Array = STARES[n % STARES.size()]
	# En el mundo: se sienta enfrente, mirándolo.
	state = "found"
	_found_time = 30.0
	sprite.flip_h = player.global_position.x > global_position.x
	sprite.play("sit")
	_bubble.text = "o_o"
	_bubble.visible = true
	Dialogue.face_off = ["el", "lukas"]
	await Dialogue.talk([["", s[0], "el"], ["LUKAS", s[1]], ["", s[2], "el"]])
	# Y ladra.
	sprite.play("bark")
	_bubble.text = "!!"
	Dialogue.face_off = ["el", "lukas"]
	var i := await Dialogue.talk([
		["LUKAS", "¡GUAU!", "lukas_ladra", "sacude"],
		["LUKAS", BARK_MEANING[n % BARK_MEANING.size()], "lukas_ladra"],
		["", "(Parpadea. Perdió contra un perro. Otra vez.)" if n > 0 else "(Parpadea del susto. Perdió contra un perro.)", "el"],
	], ["Darle algo", "Sostenerle la mirada"])
	_bubble.visible = false
	_found_time = 1.0
	if TimeManager.minutes - float(f.get("miradas_at", -999.0)) > 60.0:
		f["miradas_at"] = TimeManager.minutes
		GameState.change_mood(3.0)
		GameState.company(10.0)
	if i == 0:
		var has_food: bool = GameState.count("concentrado") > 0
		for st in GameState.inventory:
			if st != null and Items.info(st["id"])["type"] == "comida":
				has_food = true
		if has_food or f.get("lukas_fed_day", -1) == GameState.day:
			await feed()
		else:
			sprite.play("sit")
			Narrator.say("(Se revisa los bolsillos. Nada. Le muestra las manos vacías. Lukas lo mira como lo miró el banco.)", false, "lukas_triste")
	else:
		sprite.play("sit")
		Narrator.say("(Lo vuelve a mirar. Lukas se da vuelta y se echa de espaldas. Ofendido. Gana Lukas, por abandono.)", false, "lukas_triste")


func pet() -> void:
	state = "found"
	_found_time = 6.0
	sprite.play("sit")
	if player.has_method("act"):
		player.act("acariciar", global_position.x > player.global_position.x)
	_bubble.text = "<3"
	_bubble.visible = true
	GameState.calm_until = TimeManager.minutes + CALM_MINUTES
	GameState.company(8.0)
	GameState.flags["lukas_pets"] = GameState.flags.get("lukas_pets", 0) + 1
	if TimeManager.minutes - GameState.flags.get("lukas_pet_at", -999.0) > 60.0:  # no es una máquina
		GameState.flags["lukas_pet_at"] = TimeManager.minutes
		GameState.change_mood(6.0)
	Narrator.say(PET_LINES[_pet_index % PET_LINES.size()], false, "lukas_feliz")
	_pet_index += 1


## Él tose: Lukas se sienta y lo mira hasta que se le pasa.
func mirar() -> void:
	if not state in ["follow", "sit"]:
		return
	state = "found"
	_found_time = 1.8
	sprite.play("sit")
	sprite.flip_h = player.global_position.x > global_position.x


func feed() -> void:
	var f := GameState.flags
	if f.get("lukas_fed_day", -1) == GameState.day:
		Narrator.say("(Ya comió hoy. Lukas lo mira como si no.)", false, "lukas_triste")
		return
	if GameState.count("concentrado") > 0:
		GameState.remove_item("concentrado")
		Narrator.say("(Se come el concentrado en cuatro segundos.)", false, "lukas_come")
	else:
		var food := ""
		for s in GameState.inventory:
			if s != null and Items.info(s["id"])["type"] == "comida":
				food = s["id"]
				break
		if food == "":
			Narrator.say("(No tiene nada para darle.)", false, "lukas_triste")
			return
		var name: String = Items.info(food)["name"].to_lower()
		var i := await Dialogue.talk([["", "(No tiene concentrado. ¿Compartirle: %s?)" % name]], ["Compartir", "No"])
		if i != 0:
			return
		GameState.remove_item(food)
		Narrator.say("(Le da la mitad. Después, el resto.)", false, "lukas_come")
	f["lukas_fed_day"] = GameState.day
	f.erase("lukas_hungry")
	if player.has_method("act"):
		player.act("dar_comida")
	state = "found"
	_found_time = 1.5
	sprite.play("bark")


func fetch() -> void:
	if GameState.count("pelota_trapo") == 0:
		Narrator.say("(No tiene con qué jugar. Una pelota de trapo: camiseta + cuerda, en el cambuche.)", false, "lukas_triste")
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
	Narrator.say("(Le muestra la pelota. La tira.)", false, "lukas_escucha")
	state = "fetch_go"
	_stuck = 0.0


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if manda:
		var dir := Vector2.ZERO
		if not Dialogue.active and not SceneRouter.busy:
			dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir == Vector2.ZERO and sprite.animation in ["sit", "bark"]:
			velocity = Vector2.ZERO
			return  # (sentado pidiendo: que se quede así)
		_walk(dir * LukasManda.SPEED)
		return
	_cooldown -= delta
	var to_player := player.global_position - global_position
	if to_player.length() > TELEPORT_DIST and not state in ["seek", "settle_go", "settled", "lost"]:
		_teleport_behind()
		return
	match state:
		"follow", "sit":
			if to_player.length() > FOLLOW_DIST:
				state = "follow"
				_idle = 0.0
				var spd: float = player.speed * player.speed_scale * 1.15
				if GameState.flags.get("lukas_herido", -1) == GameState.day:
					spd *= 0.8  # le dieron duro un perro: cojea (hoy)
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
		"drink_go":
			var to_bowl := _bowl_spot - global_position
			if to_bowl.length() < 2.0:
				_start_drinking()
			else:
				_walk(to_bowl.normalized() * minf(SEEK_SPEED, to_bowl.length() * 8.0))
				_check_stuck_at(delta, _bowl_spot)
		"settle_go":
			var to_s := _settle_spot - global_position
			_settle_t += delta
			if to_s.length() < 2.0 or _settle_t > 3.0:
				global_position = _settle_spot  # (si se trabó en la banca, igual llega)
				state = "settled"
				_settle_t = 0.0
				_walk(Vector2.ZERO)
				facing = "side"
				sprite.flip_h = player.global_position.x > global_position.x  # mirándolo a él
				sprite.play("sit")
			else:
				_walk(to_s.normalized() * minf(SEEK_SPEED, to_s.length() * 8.0))
		"settled":
			velocity = Vector2.ZERO
			_settle_t += delta
			if player.get("seated") == "" and _settle_t > 1.0:  # (él tarda un poco en llegar al asiento)
				state = "follow"  # se paró: arriba
				sprite.play("idle_" + facing)
			elif _settle_t > 1.2 and _settle_t < 1.9:
				# La vuelta antes de echarse (como todos los perros): se voltea dos veces.
				sprite.flip_h = int(_settle_t * 6.0) % 2 == 0
				if sprite.animation != "idle_side":
					sprite.play("idle_side")
			elif _settle_t >= 1.9 and sprite.animation in ["idle_side", "sit"]:
				sprite.flip_h = player.global_position.x > global_position.x
				sprite.play("lie")
			elif _settle_t > 9.0 and sprite.animation == "lie":
				sprite.play("sleep")
		"greet_go", "greet_sniff", "greet_stay", "greet_back":
			_greet_tick(delta)
		"lost":  # se fue solo de noche: está donde está, sentado, esperando que lo encuentren
			velocity = Vector2.ZERO
		"drinking":
			_found_time -= delta
			if _found_time <= 0.0:
				state = "follow"
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
		if not state in ["sit", "found", "settle_go", "settled", "greet_sniff", "greet_stay", "greet_back"]:
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
	if state == "drink_go":  # alguien espera a que llegue al cuenco
		_start_drinking()
		return
	global_position = player.global_position + Vector2(-14, 4)
	state = "follow"


## Se le fue (la noche de Lombardía): queda sentado en `at` hasta que él lo encuentre (QuestDirector).
func wait_at(at: Vector2) -> void:
	state = "lost"
	global_position = at
	facing = "side"
	sprite.flip_h = true
	sprite.play("sit")


## Él le habla a alguien: Lukas va a olerlo.
func greet(who: Node2D, id: String) -> void:
	if manda:
		return
	if not state in ["follow", "sit"] or who == null or not GameState.lukas_alive():
		return
	_greet_who = who
	_greet_likes = GREET.get(id, absi(hash(id)) % 3 != 0)
	_greet_t = 0.0
	state = "greet_go"


## Un dibujito que sube y se borra encima de él: "corazon" o "bravo" (el resoplido).
func _float(kind: String) -> void:
	var n := Node2D.new()
	n.position = Vector2(randf_range(-3, 3), -18)
	n.z_index = 5
	n.draw.connect(func() -> void:
		if kind == "corazon":
			for p in [[1, 0], [3, 0], [0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [1, 2], [2, 2], [3, 2], [2, 3]]:
				n.draw_rect(Rect2(p[0] - 2, p[1] - 2, 1, 1), Color(0.95, 0.3, 0.45))
		else:
			for p in [[-3, 0, 2.0], [0, -1, 2.5], [3, 0, 2.0]]:
				n.draw_circle(Vector2(p[0], p[1]), p[2], Color(0.85, 0.85, 0.9, 0.85)))
	add_child(n)
	var t := n.create_tween()
	t.set_parallel(true)
	t.tween_property(n, "position:y", n.position.y - 10.0, 0.9)
	t.tween_property(n, "modulate:a", 0.0, 0.9).set_delay(0.3)
	t.chain().tween_callback(n.queue_free)


func _greet_tick(delta: float) -> void:
	_greet_t += delta
	if not is_instance_valid(_greet_who):
		state = "follow"
		return
	var talking := Dialogue.active or _greet_t < 3.5
	match state:
		"greet_go":
			var side := -1.0 if global_position.x < _greet_who.global_position.x else 1.0
			var to := _greet_who.global_position + Vector2(side * 10.0, 3.0) - global_position
			if to.length() < 3.0 or _greet_t > 3.0:
				state = "greet_sniff"
				_greet_t = 0.0
				_walk(Vector2.ZERO)
				facing = "side"
				sprite.flip_h = _greet_who.global_position.x > global_position.x
				sprite.play("sniff")
			else:
				_walk(to.normalized() * SEEK_SPEED)
		"greet_sniff":
			velocity = Vector2.ZERO
			if _greet_t > 1.3:
				_greet_t = 0.0
				if _greet_likes:
					state = "greet_stay"
					sprite.play("sit")
				else:
					state = "greet_back"
					sprite.play("bark")
					_float("bravo")
		"greet_stay":  # lo consienten: la cola, los corazones
			velocity = Vector2.ZERO
			if fmod(_greet_t, 1.1) < delta:
				_float("corazon")
			if fmod(_greet_t, 0.5) < 0.25:
				sprite.flip_h = _greet_who.global_position.x > global_position.x
			if not talking:
				state = "follow"
		"greet_back":  # se devuelve, bravo, y se le sienta de espaldas un rato
			var to_p := player.global_position + Vector2(-12, 4) - global_position
			if _greet_t < 0.6:
				velocity = Vector2.ZERO
			elif to_p.length() > 4.0 and _greet_t < 4.0:
				_walk(to_p.normalized() * SEEK_SPEED)
			else:
				_walk(Vector2.ZERO)
				facing = "side"
				sprite.flip_h = _greet_who.global_position.x < global_position.x  # de espaldas a esa persona
				sprite.play("sit")
				if fmod(_greet_t, 1.6) < delta:
					_float("bravo")
				if not talking and _greet_t > 5.0:
					state = "sit"


## Sale a olfatear. Devuelve true si encontró algo para ir a buscar.
func sniff() -> bool:
	if _cooldown > 0.0 or state == "seek":
		return false
	_cooldown = SNIFF_COOLDOWN * (1.0 + GameState.diff("olfato"))
	if GameState.lukas_sick():
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas no quiere buscar. Tiene la nariz caliente: veterinaria.)", false, "lukas_enfermo")
		return false
	if thirsty() and randf() < 0.4:
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas tiene la lengua afuera. Con sed no huele nada: un cuenco con agua.)", false, "lukas_triste")
		return false
	if GameState.flags.get("lukas_hungry", false) and randf() < 0.5:
		state = "found"
		_found_time = 1.5
		sprite.play("sit")
		Narrator.say("(Lukas olfatea... y se sienta. Con hambre no busca.)", false, "lukas_triste")
		return false
	_target = _nearest_pickup()
	if _target == null:
		state = "found"
		_found_time = 1.5
		sprite.play("sniff")
		Narrator.say("(Lukas olfatea... nada.)", false, "lukas_huele")
		return false
	state = "seek"
	_stuck = 0.0
	sprite.play("sniff")
	Narrator.say("(Chasquea los dedos y señala el piso. Lukas pega la nariz al suelo.)", false, "lukas_huele")
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
		Narrator.say("(¡Guau! Lukas encontró algo.)", false, "lukas_ladra")
	else:
		Narrator.say("¡Guau!", false, "lukas_ladra")
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
		Narrator.say("(No se la da. Se acuesta encima.)", false, "lukas_pelota")
	else:
		sprite.play("bark")
		Narrator.say(FETCH_LINES[_fetch_index % FETCH_LINES.size()], false, "lukas_pelota")
		_fetch_index += 1


## Va hasta el cuenco (bowl_foot: el pie del dibujo) y toma agua: mete el hocico y lame.
## Vuelve cuando ya está tomando (sigue tomando un rato solo, mientras corre el diálogo).
func drink(bowl_foot: Vector2) -> void:
	# Se pone del lado del cuenco por donde viene, un píxel más abajo (se dibuja delante).
	_bowl_right = global_position.x > bowl_foot.x
	_bowl_spot = bowl_foot + Vector2(BOWL_SIDE if _bowl_right else -BOWL_SIDE, 1)
	_bubble.visible = false
	state = "drink_go"
	_stuck = 0.0
	if global_position.distance_to(_bowl_spot) > 120.0:  # lejos o detrás de algo: aparece al lado
		global_position = _bowl_spot + Vector2(10 if _bowl_right else -10, 0)
	if player == null:  # sin jugador no camina (_physics_process no corre): toma ahí mismo
		_start_drinking.call_deferred()
	await at_bowl


func _start_drinking() -> void:
	global_position = _bowl_spot
	velocity = Vector2.ZERO
	facing = "side"
	sprite.flip_h = not _bowl_right  # la hoja mira a la izquierda: voltea para mirar a la derecha
	sprite.play("drink")
	state = "drinking"
	_found_time = DRINK_TIME
	at_bowl.emit()


## Sed: si a la tarde todavía no tomó agua en un cuenco.
static func thirsty() -> bool:
	return GameState.day >= 2 and TimeManager.hour() >= 14 and GameState.flags.get("lukas_water_day", -1) != GameState.day
