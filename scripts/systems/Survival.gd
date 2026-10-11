extends Node
## Efectos del hambre en la vida real (ver DISENO_CIUDAD_Y_SISTEMAS.md, sección 2).
##   < 60: comentarios sueltos.  < 40: camina más lento y se marea (la cámara se mece).
##   < 20: visión cerrada (lo hace el filtro).  0: SE VA A DESMAYAR: cuenta de 10 a 1 (un segundo
##   cada número). En la cuenta corre mucho más rápido (el cuerpo saca lo último que tiene): si llega
##   a su cambuche, se desmaya adentro, protegido, y no le falta nada. Si come algo, se le pasa.
##   Si la cuenta llega a cero en la calle, se desmaya ahí: despierta horas después en la plaza y le
##   robaron (una o dos cosas de la mochila y, a veces, la mitad de la plata del bolsillo).
##   No hay game over: hay consecuencia.

const CITY := "res://scenes/world/City.tscn"
const FAINT_SPAWN := "Desmayo"
const FAINT_HOURS := 3.0
const WAKE_HUNGER := 20.0
const COUNT_FROM := 10
const RUSH := 1.9          # cuánto más rápido corre en la cuenta
const SAFE_DIST := 30.0     # qué tan cerca del cambuche cuenta como "adentro"
## Umbral -> línea (se dice una vez cada vez que el hambre baja de ese valor).
const LINES := {
	60.0: "(Le suena la panza.)",
	40.0: "(Se marea. Si no come, se va a desmayar.)",
	20.0: "(Le tiemblan las piernas. Tiene que comer. Ya.)",
}

var _player: Node2D
var _camera: Camera2D
var _last := 100.0
var _last_mood := 55.0
var _count := -1.0          # la cuenta del desmayo (-1: no hay)
var _count_label: Label
var _count_layer: CanvasLayer
## Cuando el ánimo baja de estos valores, se le nota en el cuerpo (él no dice nada).
const MOOD_LINES := {
	35.0: "(Se sienta en el andén. Tarda en levantarse.)",
	15.0: "(Aprieta la mandíbula hasta que le duele. No se mueve.)",
}


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player:
		_camera = _player.get_node_or_null("Camera2D")
	_last = GameState.hunger
	GameState.hunger_changed.connect(_on_hunger)
	GameState.fainted.connect(_on_fainted)
	_last_mood = GameState.mood
	GameState.mood_changed.connect(_on_mood)


func _process(_delta: float) -> void:
	if _player == null:
		return
	var h := GameState.hunger
	if _count >= 0.0:
		_tick_count(_delta)
		return
	_player.speed_scale = 1.0 if h >= 40.0 else (0.8 if h >= 20.0 else 0.65)
	if GameState.mood < 15.0:  # sin ánimo, hasta caminar cuesta
		_player.speed_scale *= 0.85
	if _camera:
		var sway := 0.0 if h >= 40.0 else (1.0 if h >= 20.0 else 2.0)
		var t := Time.get_ticks_msec() / 1000.0
		_camera.offset = Vector2(sin(t * 0.9) * sway, sin(t * 1.3) * sway * 0.6)


func _on_hunger(value: float) -> void:
	for threshold in LINES:
		if _last >= threshold and value < threshold:
			Narrator.say(LINES[threshold])
	_last = value


func _on_fainted() -> void:
	if SceneRouter.busy or _count >= 0.0:
		return
	if _player == null:  # (en un minijuego no hay cómo correr: se desmaya y listo)
		_faint_street()
		return
	_count = float(COUNT_FROM)
	_count_layer = CanvasLayer.new()
	_count_layer.layer = 9
	add_child(_count_layer)
	_count_label = Label.new()
	_count_label.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	_count_label.add_theme_font_size_override("font_size", 24)
	_count_label.add_theme_constant_override("outline_size", 6)
	_count_label.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.04))
	_count_label.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.size = Vector2(Controls.right_edge(), 30)
	_count_label.position = Vector2(0, 76)  # debajo de los avisos de arriba
	_count_layer.add_child(_count_label)
	var near := _my_cambuche() != null
	Narrator.say("(Se le va el mundo. Se va a desmayar. %s)" % ("Al cambuche, ya. O comer algo." if near
		else "Comer algo, ya. O buscar dónde caer."), true)


## La cuenta: corre como nunca; si llega al cambuche o come, se salva. A cero, se cae en la calle.
func _tick_count(delta: float) -> void:
	if GameState.hunger > 0.0:  # comió: se le pasa
		_end_count()
		Narrator.say("(El primer mordisco le devuelve el piso.)", true)
		return
	if GameState.input_blocked():
		return  # (con un diálogo abierto, la cuenta espera)
	_player.speed_scale = RUSH
	var before := ceili(_count)
	_count -= delta
	var n := ceili(maxf(_count, 0.0))
	_count_label.text = str(n) if n > 0 else ""
	if n != before:  # el latido: cada número entra grande
		_count_label.scale = Vector2(1.3, 1.3)
		_count_label.pivot_offset = _count_label.size / 2.0
		create_tween().tween_property(_count_label, "scale", Vector2.ONE, 0.25)
	if _camera:
		var t := Time.get_ticks_msec() / 1000.0
		var sway := 2.0 + (COUNT_FROM - _count) * 0.4
		_camera.offset = Vector2(sin(t * 1.7) * sway, sin(t * 2.3) * sway * 0.6)
	var spot := _my_cambuche()
	if spot and spot.global_position.distance_to(_player.global_position) < SAFE_DIST:
		_end_count()
		_faint_safe(spot)
	elif _count <= 0.0:
		_end_count()
		_faint_street()


func _end_count() -> void:
	_count = -1.0
	if is_instance_valid(_count_layer):
		_count_layer.queue_free()


## Su cambuche, si está en esta escena.
func _my_cambuche() -> Node2D:
	if not GameState.has_cambuche():
		return null
	for n in get_tree().get_nodes_in_group("sleep_spots"):
		if n.has_method("is_cambuche_spot") and n.is_cambuche_spot() and GameState.has_cambuche(n.spot_id):
			return n
	return null


## Alcanzó a meterse: se desmaya adentro, protegido. No le falta nada.
func _faint_safe(_spot: Node2D) -> void:
	GameState.block_input(2.5)
	var layer := CanvasLayer.new()
	layer.layer = 11
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.size = Vector2(320, 180)
	layer.add_child(black)
	var t := create_tween()
	t.tween_property(black, "color:a", 1.0, 0.6)
	await t.finished
	TimeManager.skip(FAINT_HOURS)
	GameState.set_hunger(WAKE_HUNGER)
	GameState.change_mood(-3.0)
	await get_tree().create_timer(1.0).timeout
	var back := create_tween()
	back.tween_property(black, "color:a", 0.0, 1.0)
	back.tween_callback(layer.queue_free)
	Narrator.say("(Alcanzó a meterse al cambuche. Se desmayó adentro, protegido. %s Despierta horas después. No le falta nada.)" % (
		"Lukas se le acostó encima." if GameState.lukas_alive() else "Nadie lo vio."))


## Se cayó en la calle: horas después, en la plaza, y le robaron.
func _faint_street() -> void:
	TimeManager.skip(FAINT_HOURS)
	GameState.set_hunger(WAKE_HUNGER)
	var lost: Array = []
	for k in (2 if randf() < 0.5 else 1):
		var it := GameState.lose_random_item()
		if it != "":
			lost.append(it.to_lower())
	var line := "(Se desmayó en la calle. No se sabe cuánto tiempo pasó.)"
	if not lost.is_empty():
		line += " (Le robaron: %s.)" % ", ".join(lost)
	if GameState.money >= 2000 and randf() < 0.5:
		var gone := GameState.money / 2
		GameState.add_money(-gone)
		line += " (Y $%d del bolsillo.)" % gone
	GameState.change_mood(-6.0)
	SceneRouter.go(CITY, FAINT_SPAWN, "...", line)


func _on_mood(value: float) -> void:
	for threshold in MOOD_LINES:
		if _last_mood >= threshold and value < threshold:
			Narrator.say(MOOD_LINES[threshold])
	_last_mood = value
