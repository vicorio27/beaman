extends Node
## Efectos del hambre en la vida real (ver DISENO_CIUDAD_Y_SISTEMAS.md, sección 2).
##   < 60: comentarios sueltos.  < 40: camina más lento y se marea (la cámara se mece).
##   < 20: visión cerrada (lo hace el filtro).  0: se desmaya, despierta horas después en la
##   plaza y le falta algo de la mochila. No hay game over: hay consecuencia.

const CITY := "res://scenes/world/City.tscn"
const FAINT_SPAWN := "Desmayo"
const FAINT_HOURS := 3.0
const WAKE_HUNGER := 20.0
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
	if SceneRouter.busy:
		return
	TimeManager.skip(FAINT_HOURS)
	GameState.set_hunger(WAKE_HUNGER)
	var lost := GameState.lose_random_item()
	var line := "Me desmayé. No sé cuánto tiempo pasó."
	if lost != "":
		line += " Me falta: %s." % lost.to_lower()
	SceneRouter.go(CITY, FAINT_SPAWN, "...", line)


func _on_mood(value: float) -> void:
	for threshold in MOOD_LINES:
		if _last_mood >= threshold and value < threshold:
			Narrator.say(MOOD_LINES[threshold])
	_last_mood = value
