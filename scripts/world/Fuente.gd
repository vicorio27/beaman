extends Node2D
## Minijuego: sacar monedas de la fuente del centro (los deseos de la gente).
## Vista desde arriba del agua. La mano se mueve con las flechas; interactuar = agarrar.
## El agua engaña: las monedas se ven corridas de donde están de verdad (refracción), y la
## diferencia cambia con las ondas. El celador da vueltas por el borde: cuando se gira ("!"),
## hay que quedarse quieto. Si te ve agarrando, te echa (te quedás con la mitad).
## Una vez por día (los deseos se reponen).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CENTRO := "res://scenes/world/Centro.tscn"
const W := 320.0
const H := 180.0
const POOL_C := Vector2(160, 98)
const POOL_R := Vector2(130, 62)
const DURATION := 40.0
const HAND_SPEED := 75.0
const GRAB_DIST := 7.0
const COINS := [100, 100, 100, 100, 100, 100, 100, 100, 200, 200, 200, 200, 500, 500, 1000]

var coins: Array = []           # {"pos", "value", "phase"}
var hand := Vector2(160, 150)
var time_left := DURATION
var got := 0
var state := "intro"            # intro, play, done
var guard := "away"             # away, turning, looking
var _guard_t := 3.0
var _t := 0.0
var _splashes: Array = []       # {"pos", "t"}
var _guard_sprite: AnimatedSprite2D
var _guard_mark: Label
var _hud: Label
var _hint: Label


func _ready() -> void:
	seed(GameState.day * 7919)
	for v in COINS:
		var a := randf() * TAU
		var r := sqrt(randf()) * 0.82
		coins.append({"pos": POOL_C + Vector2(cos(a) * POOL_R.x * r, sin(a) * POOL_R.y * r), "value": v, "phase": randf() * TAU})
	randomize()
	_guard_sprite = AnimatedSprite2D.new()
	CharacterFrames.dress(_guard_sprite, 9)
	_guard_sprite.modulate = GameState.same_tint(Color(0.7, 0.8, 1.0))
	_guard_sprite.position = Vector2(160, 26)
	_guard_sprite.play("idle_up")
	_guard_sprite.scale = Vector2(1.5, 1.5)
	add_child(_guard_sprite)
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_hud = _label(ui, Vector2(6, 4))
	_hint = _label(ui, Vector2(0, 168))
	_hint.size = Vector2(W, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "[E] agarrar  -  ¡que no te vea!"
	_guard_mark = _label(ui, Vector2(156, 2))
	_guard_mark.add_theme_color_override("font_color", Color(1, 0.4, 0.3))
	_guard_mark.add_theme_font_size_override("font_size", 16)
	_intro()


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


func _intro() -> void:
	await get_tree().create_timer(0.5).timeout
	await Dialogue.talk([["", "(El agua engaña: las monedas no están donde se ven.)"]])
	state = "play"


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if state != "play":
		return
	time_left -= delta
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	hand += dir * HAND_SPEED * delta
	hand.x = clampf(hand.x, 20, W - 20)
	hand.y = clampf(hand.y, 36, H - 14)
	_update_guard(delta)
	_hud.text = "TIEMPO %02d   $%d" % [ceili(time_left), got]
	for s in _splashes:
		s["t"] += delta
	_splashes = _splashes.filter(func(s): return s["t"] < 0.5)
	if time_left <= 0.0 or coins.is_empty():
		_finish(false)


func _update_guard(delta: float) -> void:
	_guard_t -= delta
	if _guard_t > 0.0:
		return
	match guard:
		"away":
			guard = "turning"
			_guard_t = (1.5 if GameState.has_skill("sangre_fria") else 0.9) * (1.0 - 0.4 * GameState.diff("reflejos"))
			_guard_mark.text = "!"
		"turning":
			guard = "looking"
			_guard_t = randf_range(1.8, 3.0) * (1.0 + 0.5 * GameState.diff("reflejos"))
			_guard_sprite.play("idle_down")
		"looking":
			guard = "away"
			_guard_t = randf_range(2.5, 5.0) * (1.0 - 0.35 * GameState.diff("reflejos"))
			_guard_mark.text = ""
			_guard_sprite.play("idle_up")


func _unhandled_input(event: InputEvent) -> void:
	if state != "play" or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	_splashes.append({"pos": hand, "t": 0.0})
	if guard == "looking":
		_finish(true)
		return
	for c in coins:
		if c["pos"].distance_to(hand) < GRAB_DIST:
			got += c["value"]
			coins.erase(c)
			return


## Donde se ve la moneda (no donde está): la onda la corre.
func _apparent(c: Dictionary) -> Vector2:
	var p: float = c["phase"]
	return c["pos"] + Vector2(sin(_t * 1.3 + p) * 5.0, cos(_t * 1.1 + p * 1.7) * 3.0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.55, 0.52, 0.5))           # baldosas de la plaza
	for x in range(0, int(W), 16):
		draw_line(Vector2(x, 0), Vector2(x, H), Color(0.5, 0.47, 0.45))
	for y in range(0, int(H), 16):
		draw_line(Vector2(0, y), Vector2(W, y), Color(0.5, 0.47, 0.45))
	_ellipse(POOL_C, POOL_R + Vector2(12, 10), Color(0.72, 0.7, 0.66))  # borde de piedra
	_ellipse(POOL_C, POOL_R, Color(0.24, 0.42, 0.5))                # agua
	for c in coins:
		var p := _apparent(c)
		var big: bool = c["value"] >= 500
		var col := Color(0.95, 0.8, 0.35) if big else Color(0.78, 0.78, 0.8)
		draw_circle(p, 3.5 if c["value"] == 1000 else 2.5, col.darkened(0.25))
		if int(_t * 4.0 + c["phase"] * 3.0) % 5 == 0:
			draw_circle(p + Vector2(-1, -1), 1.0, Color(1, 1, 0.9))     # brillo
	for i in 7:  # ondas
		var y := POOL_C.y - POOL_R.y + 10 + i * 16 + sin(_t * 2.0 + i) * 3.0
		var half := POOL_R.x * sqrt(maxf(0.0, 1.0 - pow((y - POOL_C.y) / POOL_R.y, 2.0))) * 0.8
		draw_line(Vector2(POOL_C.x - half, y), Vector2(POOL_C.x + half, y), Color(0.45, 0.65, 0.75, 0.5))
	draw_rect(Rect2(POOL_C.x - 8, POOL_C.y - 18, 16, 22), Color(0.78, 0.76, 0.72))  # la columna
	draw_circle(POOL_C + Vector2(0, -20), 9.0, Color(0.82, 0.8, 0.76))
	for s in _splashes:
		draw_arc(s["pos"], 4.0 + s["t"] * 16.0, 0, TAU, 16, Color(0.85, 0.95, 1.0, 1.0 - s["t"] * 2.0), 1.0)
	# La mano (piel, con la manga blanca).
	draw_rect(Rect2(hand.x - 3, hand.y + 4, 6, 14), Color(0.86, 0.84, 0.8))
	draw_circle(hand, 4.5, Color(0.86, 0.6, 0.5))
	for k in 4:
		draw_line(hand + Vector2(-3 + k * 2, -2), hand + Vector2(-3 + k * 2, -6), Color(0.86, 0.6, 0.5), 1.5)


func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)


func _finish(caught: bool) -> void:
	state = "done"
	var f := GameState.flags
	f["fuente_day"] = GameState.day
	if caught:
		got /= 2
		GameState.change_mood(-6.0)
		await Dialogue.talk([
			["CELADOR", "—¡Oiga! ¡Esas monedas son los deseos de la gente!"],
			["", "(Lo mira. Sigue sacando monedas.)"],
			["CELADOR", "—¡Fuera! ¡Fuera de aquí!"],
			["", "(Sale con la mitad. La otra mitad se le cayó corriendo.)"],
		])
	else:
		GameState.change_mood(2.0)
		await Dialogue.talk([["", "($%d en monedas mojadas.)" % got],
			["", "(Lukas lo mira desde el borde.)"]])
	GameState.add_money(got)
	TimeManager.skip(0.5)
	SceneRouter.go(CENTRO, "FromFuente")
