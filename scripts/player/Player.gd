extends CharacterBody2D
## Protagonista: movimiento top-down en 8 direcciones.
## El origen del nodo está en los pies (la colisión es solo la base del cuerpo).

@export var speed := 60.0
## Lo baja el hambre (Survival.gd): con hambre camina más lento.
var speed_scale := 1.0
## Lo baja cargar cosas pesadas (CarryJob.gd).
var carry_factor := 1.0

var facing := "down"
## Gestos de quieto (se arregla la corbata, hace la venia, se ríe solo, le habla a Lukas).
var _still := 0.0
var _next_quirk := 6.0
var _blink := 3.0
var _quirk := ""

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = CharacterFrames.protagonist()
	sprite.play("idle_" + facing)


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not SceneRouter.busy and not GameState.input_blocked():
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed * speed_scale * carry_factor * GameState.walk_factor()
	move_and_slide()
	sprite.speed_scale = speed_scale
	var gr := GameState.grief()
	if gr > 0.0:  # se va apagando
		sprite.modulate = Color(1, 1, 1).lerp(Color(0.72, 0.76, 0.86), gr)
		sprite.modulate.a = 1.0 - 0.35 * gr

	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = "side"
			sprite.flip_h = dir.x > 0
		else:
			facing = "down" if dir.y > 0 else "up"
	if dir != Vector2.ZERO or SceneRouter.busy or GameState.input_blocked():
		_still = 0.0
		_quirk = ""
	if _quirk != "" and (sprite.animation != _quirk or not sprite.is_playing()):
		_quirk = ""  # terminó el gesto
	if _quirk != "":
		return  # está haciendo un gesto
	sprite.play(("walk_" if dir != Vector2.ZERO else "idle_") + facing)
	if dir == Vector2.ZERO and not SceneRouter.busy and not GameState.input_blocked():
		_idle_quirks(_delta)


## Quieto un rato, hace algo. Lo que hace depende de cómo está la cabeza (locura) y de si Lukas está.
func _idle_quirks(delta: float) -> void:
	_still += delta
	_blink -= delta
	if _blink <= 0.0 and facing == "down":
		_blink = randf_range(2.5, 5.0)
		_play_quirk("blink")
		return
	if _still < _next_quirk:
		return
	_still = 0.0
	_next_quirk = randf_range(5.0, 9.0)
	var loco := GameState.locura_level()
	var lukas: Node2D = null
	var scene := get_tree().current_scene
	var l: Node = scene.find_child("Lukas", true, false) if scene else null
	if l is Node2D and l.visible and l.global_position.distance_to(global_position) < 48.0:
		lukas = l
	var options := ["quirk_tie", "quirk_tie", "quirk_salute"]
	if lukas:
		options += ["quirk_talk", "quirk_talk"]
	if loco >= 1:
		options += ["quirk_laugh", "quirk_talk"]  # habla solo
	if loco >= 2:
		options += ["quirk_laugh", "quirk_laugh", "quirk_salute"]
	if not GameState.lukas_alive():
		options += ["quirk_talk", "quirk_talk"]  # le sigue hablando
	var q: String = options.pick_random()
	if q == "quirk_talk":
		var to_right: bool = lukas.global_position.x > global_position.x if lukas else randf() < 0.5
		sprite.flip_h = to_right
		facing = "side"
	else:
		facing = "down"
		sprite.flip_h = false
	_play_quirk(q)


func _play_quirk(q: String) -> void:
	_quirk = q
	sprite.play(q)


## Mirar hacia "down", "up", "left" o "right".
func face(direction: String) -> void:
	if direction in ["left", "right"]:
		facing = "side"
		sprite.flip_h = direction == "right"
	else:
		facing = direction
