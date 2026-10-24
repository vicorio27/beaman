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

## Las acciones: lo que antes solo contaba el narrador (recibir plata, pagar, el golpe, caerse, toser,
## recoger, comer, el celular, las manos arriba...). Van en otro sprite, encima del de caminar (celdas de
## 32x32: CharacterFrames.acciones(), dibujadas por tools/art/draw_protagonist_acciones.py). Mientras
## dura una, no camina.
var acting := false
var _act: AnimatedSprite2D
var _sfx: AudioStreamPlayer2D
## La tos (GameState.tos_stage): cada tanto le da un ataque y se tiene que parar.
var _tos_t := 25.0
## La lluvia: mientras se moja, escurre; cuando escampa (o se mete debajo de algo), se sacude.
var _wet := false
var _drip_t := 0.0
const SFX := {
	"monedas": preload("res://assets/audio/cuerpo/monedas.wav"),
	"billete": preload("res://assets/audio/cuerpo/billete.wav"),
	"tos_1": preload("res://assets/audio/cuerpo/tos_1.wav"),
	"tos_2": preload("res://assets/audio/cuerpo/tos_2.wav"),
	"tos_3": preload("res://assets/audio/cuerpo/tos_3.wav"),
	"caida": preload("res://assets/audio/cuerpo/caida.wav"),
	"golpe": preload("res://assets/audio/hit-2.wav"),
	"mastica": preload("res://assets/audio/cuerpo/mastica.wav"),
	"traga": preload("res://assets/audio/cuerpo/traga.wav"),
	"sacude": preload("res://assets/audio/cuerpo/sacude.wav"),
	"timbre": preload("res://assets/audio/cuerpo/timbre.wav"),
}

## Él conserva un poco de color cuando el mundo se pone gris (el ánimo, el luto): una copia suya, a todo
## color y medio transparente, por encima del filtro (MoodFilter, capa 10). Así no se pierde en la pantalla.
const COLOR_LAYER := 11
const COLOR_MAX := 0.5
var _color_layer: CanvasLayer
var _color_copy: AnimatedSprite2D
var _mood_mat: ShaderMaterial

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	add_to_group("player")
	sprite.sprite_frames = CharacterFrames.protagonist()
	sprite.play("idle_" + facing)
	_act = AnimatedSprite2D.new()
	_act.name = "Acciones"
	_act.sprite_frames = CharacterFrames.acciones()
	_act.position = sprite.position
	_act.visible = false
	add_child(_act)
	_sfx = AudioStreamPlayer2D.new()
	_sfx.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(_sfx)
	GameState.money_delta.connect(_on_money)
	GameState.ate.connect(_on_ate)
	_color_layer = CanvasLayer.new()
	_color_layer.layer = COLOR_LAYER
	_color_layer.follow_viewport_enabled = true  # (va con la cámara, como el mundo)
	add_child(_color_layer)
	_color_copy = AnimatedSprite2D.new()
	_color_copy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_color_copy.visible = false
	_color_layer.add_child(_color_copy)


## Cuánto gris le pone el filtro a la pantalla ahora (0: nada).
func _grey_amount() -> float:
	if _mood_mat == null:
		var scene := get_tree().current_scene
		var mf := scene.find_child("MoodFilter", true, false) if scene else null
		var screen := mf.get_node_or_null("Screen") as ColorRect if mf else null
		if screen == null:
			return 0.0
		_mood_mat = screen.material as ShaderMaterial
	var d: float = float(_mood_mat.get_shader_parameter("distress"))
	var g = _mood_mat.get_shader_parameter("grief")
	var m: float = float(_mood_mat.get_shader_parameter("memory"))
	if m > 0.1:
		return 0.0  # en los recuerdos, sepia como todo
	return clampf(maxf(smoothstep(0.3, 1.0, d), float(g) if g != null else 0.0), 0.0, 1.0)


func _process(_delta: float) -> void:
	var k := _grey_amount()
	var src: AnimatedSprite2D = _act if _act.visible else sprite
	var show := k > 0.05 and is_visible_in_tree() and src.visible and not SceneRouter.busy and not GameState.input_blocked()
	_color_copy.visible = show
	if not show:
		return
	if _color_copy.sprite_frames != src.sprite_frames:
		_color_copy.sprite_frames = src.sprite_frames
	_color_copy.animation = src.animation
	_color_copy.frame = src.frame
	_color_copy.flip_h = src.flip_h
	_color_copy.offset = src.offset
	_color_copy.centered = src.centered
	_color_copy.global_transform = src.global_transform
	_color_copy.modulate = Color(1, 1, 1, COLOR_MAX * k)


func _physics_process(_delta: float) -> void:
	if acting:
		velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if not SceneRouter.busy and not GameState.input_blocked():
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if seated != "":
		_seated_tick(_delta, dir)
		return
	_tos_tick(_delta)
	_rain_tick(_delta)
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


## Vuelve de una alucinación (la moto, el padrino): desconcertado. Del piso (from_ground) se incorpora;
## mira para un lado, para el otro, otra vez; sacude la cabeza; un "?" encima. Un par de segundos quieto.
func wake_confused(from_ground := true) -> void:
	if seated != "":
		return
	seated = "-"
	_quirk = ""
	GameState.block_input(3.2)
	sprite.flip_h = false
	if from_ground:
		sprite.play("sit_down")  # quedó sentado en el piso, donde estaba
		sprite.position.y = -8.0
		await get_tree().create_timer(0.9).timeout
		sprite.play("sit_crouch")
		await get_tree().create_timer(0.3).timeout
	var mark := Node2D.new()  # el "?", dibujado (no es letra: no se monta sobre los avisos), al lado de la cabeza
	mark.position = Vector2(9, -24)
	mark.draw.connect(func() -> void:
		for p in [[0, 0], [1, 0], [2, 0], [-1, 1], [3, 1], [3, 2], [2, 3], [1, 4], [1, 6]]:
			mark.draw_rect(Rect2(p[0] - 1, p[1] - 1, 3, 3), Color(0.08, 0.06, 0.1))
		for p in [[0, 0], [1, 0], [2, 0], [-1, 1], [3, 1], [3, 2], [2, 3], [1, 4], [1, 6]]:
			mark.draw_rect(Rect2(p[0], p[1], 1, 1), Color(1, 0.9, 0.5)))
	add_child(mark)
	facing = "side"
	for look in [false, true, false]:  # para un lado, para el otro
		sprite.flip_h = look
		sprite.play("idle_side")
		await get_tree().create_timer(0.45).timeout
	var shake := sprite.create_tween()  # sacude la cabeza
	for k in 3:
		shake.tween_property(sprite, "rotation", 0.12, 0.06)
		shake.tween_property(sprite, "rotation", -0.12, 0.06)
	shake.tween_property(sprite, "rotation", 0.0, 0.05)
	await shake.finished
	facing = "down"
	sprite.play("idle_down")
	var fade := mark.create_tween()
	fade.tween_property(mark, "position:y", -28.0, 0.6)
	fade.parallel().tween_property(mark, "modulate:a", 0.0, 0.6)
	fade.tween_callback(mark.queue_free)
	seated = ""


# ---------------------------------------------------------------- Acciones

## Hace la acción `anim` (ver draw_protagonist_acciones.py: "plata", "pagar", "golpe", "caer", "tos",
## "recoger", "comer", "beber", "dar_comida", "celular", "manos_arriba", "sacudirse", "bici"...) y espera
## a que termine. Las que se repiten (el celular, las manos arriba, la bici) siguen hasta act_stop().
## flip: mirando para el otro lado (las de costado miran a la izquierda).
func act(anim: String, flip := false, sound := "") -> void:
	if seated != "" or _act == null or not is_inside_tree() or not _act.sprite_frames.has_animation(anim):
		return
	acting = true
	_quirk = ""
	velocity = Vector2.ZERO
	_act.flip_h = flip
	_act.modulate = sprite.modulate
	_act.visible = true
	sprite.visible = false
	if sound != "":
		play_sfx(sound)
	_act.play(anim)
	if _act.sprite_frames.get_animation_loop(anim):
		return
	await _act.animation_finished
	if _act.animation == anim:
		act_stop()


func act_stop() -> void:
	if _act == null:
		return
	_act.stop()
	_act.visible = false
	sprite.visible = true
	acting = false
	sprite.play("idle_" + facing)


func play_sfx(id: String, db := -4.0) -> void:
	if _sfx and SFX.has(id):
		_sfx.stream = SFX[id]
		_sfx.volume_db = db
		_sfx.play()


## Lo tumban (la moto, el empujón del policía, el cobrador): sale para atrás, cae, se queda un momento
## en el piso y se levanta. from: de dónde viene el golpe.
func knocked_down(from: Vector2, push := 22.0) -> void:
	if seated != "" or acting:
		return
	var dir := (global_position - from).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	play_sfx("golpe", -2.0)
	act("caer", dir.x > 0)
	var last := [0.0]
	var fly := create_tween()
	fly.tween_method(func(t: float):
		move_and_collide(dir * (t - last[0]))
		last[0] = t, 0.0, push, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.35).timeout
	play_sfx("caida", 0.0)
	await _act.animation_finished


## La plata que entra y la que sale, se ve: la mano, el billete, el bolsillo; y arriba, cuánto.
func _on_money(amount: int) -> void:
	if not is_inside_tree() or not visible or amount == 0:
		return
	if amount > 0:
		act("plata" if amount >= 1000 else "plata_moneda", false, "monedas" if amount < 5000 else "billete")
	else:
		act("pagar", false, "billete")
	_float_amount(amount)


## "+$5.000" en dorado (o "-$2.000" en rojo) sube y se apaga sobre la cabeza. No sale si hay un aviso
## arriba (ningún texto encima de otro).
func _float_amount(amount: int) -> void:
	if Narrator._panel and Narrator._panel.visible:
		return
	var l := Label.new()
	l.add_to_group("texto_mundo")  # (Hud: no se monta sobre otro texto)
	l.text = ("+$" if amount > 0 else "-$") + _miles(absi(amount))
	l.add_theme_font_override("font", preload("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.08))
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if amount > 0 else Color(1.0, 0.45, 0.4))
	l.z_index = 60
	l.position = Vector2(-l.text.length() * 4.0, -44)
	add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", -54.0, 1.1).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.7)
	t.tween_callback(l.queue_free)


static func _miles(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return s + out


## Come o toma: la comida a la boca. Lo caliente de tomar (tinto, aguapanela), de a sorbos.
func _on_ate(id: String) -> void:
	if not is_inside_tree() or not visible:
		return
	if id in ["tinto", "aguapanela"]:
		act("beber", false, "traga")
	else:
		act("comer", false, "mastica")


## La tos: cada tanto (más seguido entre peor esté), se para, se dobla y tose. Lukas lo mira.
func _tos_tick(delta: float) -> void:
	var st := GameState.tos_stage()
	if st == 0 or SceneRouter.busy or GameState.input_blocked() or Dialogue.active or GameState.ui_open 			or not TimeManager.running:
		return
	_tos_t -= delta
	if _tos_t > 0.0:
		return
	_tos_t = [0.0, randf_range(70.0, 120.0), randf_range(35.0, 65.0), randf_range(18.0, 32.0)][st]
	act("tos_corta" if st == 1 else "tos", false, ["", "tos_1", "tos_2", "tos_3"][st])
	var scene := get_tree().current_scene
	var lukas: Node = scene.find_child("Lukas", true, false) if scene else null
	if lukas and lukas.has_method("mirar"):
		lukas.mirar()


## Mojado: gotas que le caen del saco y del pelo. Al salir del agua, se sacude.
func _rain_tick(delta: float) -> void:
	var now: bool = TimeManager.minutes < float(GameState.flags.get("bajo_lluvia_hasta", -1.0))
	if _wet and not now and not SceneRouter.busy:
		_wet = false
		act("sacudirse", false, "sacude")
		return
	_wet = now
	if not _wet:
		return
	_drip_t -= delta
	if _drip_t > 0.0:
		return
	_drip_t = randf_range(0.12, 0.3)
	var d := ColorRect.new()
	d.size = Vector2(1, 2)
	d.color = Color(0.62, 0.78, 0.98, 0.9)
	d.position = Vector2(randf_range(-6, 6), randf_range(-26, -8))
	d.z_index = 5
	add_child(d)
	var t := d.create_tween()
	t.tween_property(d, "position:y", d.position.y + randf_range(6, 12), 0.35)
	t.parallel().tween_property(d, "modulate:a", 0.0, 0.35)
	t.tween_callback(d.queue_free)


## Mirar hacia "down", "up", "left" o "right".
func face(direction: String) -> void:
	if direction in ["left", "right"]:
		facing = "side"
		sprite.flip_h = direction == "right"
	else:
		facing = direction
