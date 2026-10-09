extends Node2D
## LA OBRA: el trabajo fijo (lo consigue Germán con el cuñado, cuando hay cédula). Un turno = tres
## viajes subiendo ladrillos al andamio con la pila en la cabeza. Él camina solo; la pila se ladea:
## flechas izquierda/derecha = equilibrar; E = afirmarse (se para y la pila se calma, pero pierde tiempo).
## Si se ladea demasiado, se caen ladrillos. Paga según lo que llegó arriba. Paso firme ayuda.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CITY := "res://scenes/world/City.tscn"
const PAY_FULL := 25000
const TRIPS := 3
const BRICKS := 6
const START_X := 40.0
const END_X := 262.0
const LIMIT := 0.62

var trip := 0
var stack := BRICKS
var delivered := 0
var x := START_X
var tilt := 0.0
var spin := 0.0
var state := "intro"   # intro, walk, drop, back, end
var _t := 0.0
var _say_t := 3.0
var _me: AnimatedSprite2D
var _top: Label
var _msg: Label
var _falling: Array = []

const FOREMAN := [
	"MAESTRO RAMIRO: —¡Derechito, cédula! ¡Que esos ladrillos cuestan más que usted!",
	"MAESTRO RAMIRO: —Aquí el que se cae, se levanta. El que no se levanta, se descuenta.",
	"MAESTRO RAMIRO: —¿Usted tiembla o es la obra? ... La obra no tiembla, mijo.",
	"UN OBRERO: —Tranquilo, hermano. El primer día todos botamos. El último también.",
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
	_msg.size = Vector2(Controls.right_edge() - 8, 30)  # a la derecha, los botones táctiles
	_msg.clip_text = true
	_msg.max_lines_visible = 3
	_msg.add_to_group("under_dialogue")
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MusicDirector.force("city_day")
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
	if not GameState.flags.get("obra_tutorial", false):
		GameState.flags["obra_tutorial"] = true
		lines.append(["", "Camina solo. Flechas: equilibrar la pila. E: afirmarse (se para y se calma). Si se ladea mucho, se caen."])
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
				state = "walk"
	for b in _falling.duplicate():
		b["v"].y += 300.0 * delta
		b["p"] += b["v"] * delta
		if b["p"].y > 150:
			_falling.erase(b)
	_me.position = Vector2(x, 140)
	if _me.animation != ("walk" if state in ["walk", "back"] and not Input.is_action_pressed("interact") else "idle"):
		_me.play("walk" if state in ["walk", "back"] and not Input.is_action_pressed("interact") else "idle")
	_top.text = "VIAJE %d/%d   ARRIBA %d/%d   PILA %d" % [mini(trip + 1, TRIPS), TRIPS, delivered, TRIPS * BRICKS, stack]
	queue_redraw()


func _walk(delta: float) -> void:
	var steady := Input.is_action_pressed("interact")
	var hard := 1.0 + 0.6 * GameState.diff("cuerpo")
	if GameState.has_skill("paso_firme"):
		hard *= 0.6
	# La pila es inestable: se va para donde ya está ladeada, más rápido mientras camina.
	spin += (tilt * 2.2 + randf_range(-1.0, 1.0) * (0.25 if steady else 1.1)) * hard * delta
	if Input.is_action_pressed("move_left"):
		spin -= 2.6 * delta
	if Input.is_action_pressed("move_right"):
		spin += 2.6 * delta
	spin *= 0.92 if not steady else 0.8
	tilt += spin * delta * 2.0
	if steady:
		tilt = move_toward(tilt, 0.0, delta * 0.15)
	else:
		x += 38.0 * delta
	if absf(tilt) > LIMIT:
		_drop()
		return
	_say_t -= delta
	if _say_t <= 0.0:
		_say_t = randf_range(5.0, 8.0)
		_say(FOREMAN.pick_random())
	if x >= END_X:
		delivered += stack
		trip += 1
		_say("(Arriba. %d ladrillos.)" % stack)
		if trip >= TRIPS:
			_end()
		else:
			state = "back"


## Se ladeó demasiado: se caen la mitad (y él se queda quieto un rato).
func _drop() -> void:
	var lost := maxi(1, stack / 2)
	stack -= lost
	for i in lost:
		_falling.append({"p": Vector2(x, 140 - 26 - i * 4), "v": Vector2(signf(tilt) * randf_range(40, 90), -randf_range(20, 80))})
	tilt = 0.0
	spin = 0.0
	_say(["(Se caen %d. El maestro anota algo.)" % lost,
		"MAESTRO RAMIRO: —¡%d al piso! ¿No va a decir ni \"uy\"? Nada. Este man no se queja ni cuando se le cae la obra encima." % lost][randi() % 2])
	state = "drop"
	await get_tree().create_timer(0.8).timeout
	if stack <= 0:
		trip += 1
		state = "back" if trip < TRIPS else "end"
		if trip >= TRIPS:
			_end()
	else:
		state = "walk"


func _end() -> void:
	state = "end"
	var pay := int(round(PAY_FULL * float(delivered) / (TRIPS * BRICKS) / 500.0)) * 500
	GameState.add_money(pay)
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
		["MAESTRO RAMIRO", "—Tome: $%d. Contados. No me los gaste en bobadas. Bueno, sí: en comida." % pay],
		["MAESTRO RAMIRO", "—Y firme el recibo. ... Uy, qué firma tan bonita. Firma de gerente. ¿Usted qué hacía antes?"],
		["ÉL", "Firmaba. Eso hacía. Firmaba cosas que otros cargaban. Ahora cargo cosas que otros firman. El universo tiene sentido de la simetría."],
	])
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(CITY, "FromCafe", "", "Seis horas de ladrillo. La espalda me odia. Yo, por primera vez en meses, no me odio tanto.")


func _say(line: String) -> void:
	_msg.text = line
	_msg.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(_msg, "modulate:a", 0.0, 0.4)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.62, 0.74, 0.86))
	draw_rect(Rect2(0, 100, 320, 80), Color(0.55, 0.46, 0.36))     # tierra
	draw_rect(Rect2(0, 140, 320, 40), Color(0.48, 0.4, 0.32))
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
	# La pila en la cabeza, ladeada.
	if state != "end":
		var base := Vector2(x, 140 - 26)  # encima de la cabeza
		var up := Vector2.UP.rotated(tilt)
		var side := Vector2.RIGHT.rotated(tilt)
		for i in stack:
			var c := base + up * (i * 5.0) + side * (tilt * i * 6.0)
			draw_colored_polygon(PackedVector2Array([c - side * 6, c + side * 6, c + side * 6 + up * 4, c - side * 6 + up * 4]),
				Color(0.75, 0.33, 0.22))
		# El indicador: verde, amarillo, rojo.
		var r := absf(tilt) / LIMIT
		draw_rect(Rect2(110, 16, 100, 5), Color(0.2, 0.2, 0.2))
		draw_rect(Rect2(160 + tilt / LIMIT * 50 - 2, 14, 4, 9), Color(0.3, 0.9, 0.3).lerp(Color(1, 0.2, 0.2), r))
	for b in _falling:
		draw_rect(Rect2(b["p"], Vector2(8, 4)), Color(0.75, 0.33, 0.22))
