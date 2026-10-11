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
## Sentado: "" (parado), "down" (de frente: bancas, columpio) o "up" (de espalda, en el piso: la tele,
## el atardecer). Se para solo cuando el jugador lo mueve.
var seated := ""
var _sit_home := Vector2.ZERO
var _sit_lift := 0.0
var _sit_t := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = CharacterFrames.protagonist()
	sprite.play("idle_" + facing)


func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if not SceneRouter.busy and not GameState.input_blocked():
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if seated != "":
		_seated_tick(_delta, dir)
		return
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


## Sentarse en `at` (los pies del nodo). view: "down" (de frente, en una banca o el columpio) o "up"
## (de espalda, en el piso). lift: cuánto sube el dibujo para quedar sobre el asiento (el nodo queda
## delante de la banca, para que se dibuje encima de ella). Camina hasta ahí, se agacha y se sienta.
func sit(at: Vector2, view := "down", lift := 0.0) -> void:
	if seated != "":
		return
	_sit_home = global_position
	_quirk = ""
	var to := at - global_position
	if to.length() > 1.0:
		if absf(to.x) > absf(to.y):
			facing = "side"
			sprite.flip_h = to.x > 0
		else:
			facing = "down" if to.y > 0 else "up"
		sprite.play("walk_" + facing)
		var walk := create_tween()
		walk.tween_property(self, "global_position", at, clampf(to.length() / speed, 0.1, 0.6))
		await walk.finished
	seated = view  # desde acá _physics_process no lo mueve
	sprite.flip_h = false
	sprite.play("sit_crouch")
	var down := create_tween()
	down.tween_property(sprite, "position:y", -8.0 - lift * 0.5, 0.15)
	await down.finished
	_sit_lift = lift
	sprite.position.y = -8.0 - lift
	sprite.play("sit_" + view)
	_sit_t = 0.0


## Pararse (se agacha un instante y vuelve a donde estaba antes de sentarse).
func stand_up() -> void:
	if seated == "":
		return
	var view := seated
	seated = "-"  # parándose: todavía no camina
	sprite.play("sit_crouch")
	sprite.position.y = -8.0 - _sit_lift * 0.5
	await get_tree().create_timer(0.15).timeout
	sprite.position.y = -8.0
	global_position = _sit_home
	facing = "down" if view == "down" else "up"
	sprite.play("idle_" + facing)
	seated = ""


## Sentado: respira (de vez en cuando baja la cabeza), parpadea; si el jugador lo mueve, se para.
func _seated_tick(delta: float, dir: Vector2) -> void:
	velocity = Vector2.ZERO
	if seated == "-":
		return
	if dir != Vector2.ZERO:
		stand_up()
		return
	_sit_t += delta
	var cycle := fmod(_sit_t, 6.0)
	var anim := "sit_" + seated
	if cycle > 4.6:
		anim += "_bow"  # baja la cabeza un rato
	elif seated == "down" and fmod(_sit_t, 3.1) > 2.95:
		anim += "_blink"
	if sprite.animation != anim:
		sprite.play(anim)


## Lo sacan a empujones (las puertas que no se quedan calladas): sale volando para atrás, cae
## sentado, se queda un momento en el piso y se levanta.
func shoved(dir: Vector2) -> void:
	if seated != "":
		return
	seated = "-"
	_quirk = ""
	sprite.flip_h = false
	sprite.play("sit_crouch")
	var last := [0.0]
	var fly := create_tween()
	fly.tween_method(func(t: float):
		move_and_collide(dir * (t - last[0]))
		last[0] = t, 0.0, 26.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fly.finished
	sprite.play("sit_down")  # en el piso, de nalgas
	var bump := create_tween()
	bump.tween_property(sprite, "position:y", -5.0, 0.06)
	bump.tween_property(sprite, "position:y", -8.0, 0.08)
	await get_tree().create_timer(0.9).timeout
	sprite.play("sit_crouch")
	await get_tree().create_timer(0.18).timeout
	facing = "down" if dir.y > 0 else ("up" if dir.y < 0 else "side")
	sprite.play("idle_" + facing)
	seated = ""


## Mirar hacia "down", "up", "left" o "right".
func face(direction: String) -> void:
	if direction in ["left", "right"]:
		facing = "side"
		sprite.flip_h = direction == "right"
	else:
		facing = direction
