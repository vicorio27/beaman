extends Node2D
## Primera memoria (spec, sección 25), jugable: él de chico en un patio, en sepia.
## Patea una pelota (caminando contra ella o con el botón), la pelota rueda hacia la luz del fondo.
## A mitad de camino entra la sombra larga de un adulto (no se ve quién es) y una voz:
## "—¡Vamos, campeón!". Él sigue corriendo; la memoria se corta antes de explicar nada.
## Vuelve a la noche (Night.tscn), que sigue con el resumen.

const NIGHT := "res://scenes/world/Night.tscn"
const W := 30  # tiles
const H := 12
const VOICE_AT := 250.0  # cuando la pelota pasa este x, aparece la sombra y la voz
const EXIT_X := 452.0
const FRICTION := 70.0
const KICK := 150.0

var _player: CharacterBody2D
var _ball: Node2D
var _ball_v := Vector2.ZERO
var _spin := 0.0
var _voice_done := false
var _voice_since := -1.0  # cuándo apareció la voz (para que se alcance a leer)
var _ending := false
var _shadow: Polygon2D
var _text: Label
var _flash: ColorRect


func _ready() -> void:
	var ts: TileSet = load("res://assets/barrio/barrio_tileset.tres")
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	add_child(ground)
	for y in H:
		for x in W:
			ground.set_cell(Vector2i(x, y), 0, Vector2i([0, 1, 2, 3][(x * 7 + y * 3) % 4], 0))
	var world := Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	# La casa a la izquierda (de donde sale), cerco arriba y abajo, algunos árboles.
	_prop(world, "house_d", Vector2(40, 64))
	for x in range(8, W * 16, 16):
		_prop(world, "fence_wood", Vector2(x, 18))
		_prop(world, "fence_wood", Vector2(x, H * 16 + 2))
	for p in [Vector2(150, 90), Vector2(300, 60), Vector2(380, 150)]:
		_prop(world, "tree_sparse", p)
	# Al fondo a la derecha, una luz: hacia ahí se va la pelota.
	var light := ColorRect.new()
	light.color = Color(1, 0.97, 0.88, 0.55)
	light.position = Vector2(EXIT_X, 20)
	light.size = Vector2(60, H * 16 - 20)
	add_child(light)

	_player = load("res://scenes/player/Player.tscn").instantiate()
	_player.position = Vector2(70, 110)
	world.add_child(_player)
	_player.get_node("Sprite").scale = Vector2(0.8, 0.8)  # chico
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * 16
	cam.limit_bottom = H * 16 + 8
	_walls()

	_ball = Node2D.new()
	_ball.position = Vector2(92, 112)
	world.add_child(_ball)
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(-2, -1), Vector2(2, -1), Vector2(4, 0), Vector2(2, 1), Vector2(-2, 1)])
	_ball.add_child(shadow)
	var ball := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 10:
		pts.append(Vector2.from_angle(TAU * i / 10.0) * 4.0)
	ball.polygon = pts
	ball.color = Color(0.96, 0.94, 0.88)
	ball.position = Vector2(0, -4)
	ball.name = "Ball"
	_ball.add_child(ball)
	var patch := Polygon2D.new()
	patch.polygon = PackedVector2Array([Vector2(-1, -2), Vector2(1, -2), Vector2(2, 0), Vector2(0, 2), Vector2(-2, 0)])
	patch.color = Color(0.3, 0.26, 0.24)
	ball.add_child(patch)

	# La sombra del adulto: larga, entra desde la derecha (nunca se ve la persona).
	_shadow = Polygon2D.new()
	_shadow.color = Color(0.1, 0.08, 0.1, 0.0)
	_shadow.polygon = PackedVector2Array([Vector2(0, -2), Vector2(180, -14), Vector2(200, -6), Vector2(200, 10), Vector2(180, 14), Vector2(2, 4)])
	_shadow.position = Vector2(W * 16 + 10, 120)
	world.add_child(_shadow)

	var ui := CanvasLayer.new()
	ui.layer = 12
	add_child(ui)
	_text = Label.new()
	_text.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	_text.add_theme_font_size_override("font_size", 8)
	_text.add_theme_constant_override("outline_size", 3)
	_text.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.1))
	_text.add_theme_color_override("font_color", Color(1, 0.96, 0.86))
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.position = Vector2(0, 150)
	_text.size = Vector2(320, 12)
	_text.text = "E: patear"
	ui.add_child(_text)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 1)
	_flash.size = Vector2(320, 180)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_flash)
	create_tween().tween_property(_flash, "color:a", 0.0, 1.5)
	$MoodFilter.memory_on = true


func _prop(parent: Node, art: String, foot: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/barrio/%s.png" % art)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = foot
	parent.add_child(s)


func _walls() -> void:
	var body := StaticBody2D.new()
	for r in [Rect2(0, 0, W * 16, 22), Rect2(0, H * 16, W * 16, 20), Rect2(-10, 0, 10, H * 16)]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size / 2.0
		body.add_child(cs)
	add_child(body)


func _physics_process(delta: float) -> void:
	if _ending:
		return
	# Patear: caminando contra la pelota, o con el botón si está cerca.
	var to_ball := _ball.position - _player.position
	var near := to_ball.length() < 12.0
	var pushing := near and _player.velocity.length() > 5.0 and _player.velocity.dot(to_ball) > 0.0
	if near and (pushing or Input.is_action_just_pressed("interact")):
		var dir := to_ball.normalized() if to_ball.length() > 0.1 else Vector2.RIGHT
		dir = (dir + Vector2(0.8, 0)).normalized()  # siempre tiende a irse hacia la luz
		_ball_v = dir * KICK
		if not _voice_done:
			_text.text = ""  # solo borra la ayuda "E: patear", nunca la voz
	_ball.position += _ball_v * delta
	_ball.position.y = clampf(_ball.position.y, 30.0, H * 16 - 6.0)
	_ball_v = _ball_v.move_toward(Vector2.ZERO, FRICTION * delta)
	_spin += _ball_v.x * delta * 0.4
	_ball.get_node("Ball").rotation = _spin
	if not _voice_done and _ball.position.x > VOICE_AT:
		_voice()
	var reached := _player.position.x > EXIT_X - 10.0 or _ball.position.x > EXIT_X + 30.0 and _player.position.x > EXIT_X - 60.0
	if reached and _voice_since >= 0.0 and Time.get_ticks_msec() / 1000.0 - _voice_since > 2.5:
		_end()


func _voice() -> void:
	_voice_done = true
	var t := create_tween().set_parallel()
	# Se estira desde fuera de cuadro hasta los pies del chico (la persona nunca entra).
	_shadow.position = Vector2(_player.position.x + 200.0, _player.position.y + 2.0)
	t.tween_property(_shadow, "position:x", _player.position.x + 14.0, 1.2)
	t.tween_property(_shadow, "color:a", 0.45, 1.2)
	await get_tree().create_timer(0.6).timeout
	_text.text = "—¡Vamos, campeón!"
	_voice_since = Time.get_ticks_msec() / 1000.0


## Se corta antes de explicar nada: blanco, y vuelve a la noche.
func _end() -> void:
	_ending = true
	MusicDirector.cut()  # la cajita se corta de golpe
	GameState.flags["memory_1_seen"] = true
	var memories: Array = GameState.flags.get("memories", [])
	memories.append("pelota")
	GameState.flags["memories"] = memories
	var t := create_tween()
	t.tween_property(_flash, "color:a", 1.0, 0.8)
	await t.finished
	SceneRouter.go(NIGHT)
