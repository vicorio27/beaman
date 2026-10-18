class_name PelotaLukas
extends CanvasLayer
## Después de los penaltis: Lukas se roba la pelota y sale corriendo por el lote. Hay que ir tras él
## (flechas / palanca); los tres pelados corren también, detrás de Lukas y al lado de él, gritando.
## Lukas es más rápido, pero cuando lo tienen cerca hace el quiebre; con los segundos se cansa (y la
## pelota le pesa). Si lo alcanza, se la quita... o Lukas la suelta y se le tira encima. Si no lo
## alcanza en 25 segundos, Lukas la trae solo, cuando él quiere. Al final se tiran todos al pasto.
##   var caught: bool = await PelotaLukas.play(self)

signal _done(caught: bool)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const PANEL := Rect2(0, 34, 320, 146)  # el lote de los penaltis, de lado a lado (debajo de la barra)
const FIELD := Rect2(12, 62, 262, 112)  # por donde se corre (ni el muro ni la franja de los botones)
const HIM_SPEED := 64.0
const DOG_SPEED := 80.0
const TIME := 25.0
const KID_COLORS := [Color(0.9, 0.75, 0.25), Color(0.5, 0.3, 0.7), Color(0.3, 0.6, 0.85)]

var _field: Node2D
var _over: Node2D
var _him: AnimatedSprite2D
var _dog: AnimatedSprite2D
var _kids: Array = []      # {pos, speed, off}
var _dog_pos := Vector2(200, 110)
var _dog_v := Vector2(-1, 0)
var _juke := 0.0
var _t := 0.0
var _state := "chase"      # "chase", "pile", "closed"
var _caught := false
var _hint: Label
var _dust: Array = []


static func play(parent: Node) -> bool:
	var ui := PelotaLukas.new()
	parent.get_tree().root.add_child(ui)
	var r: bool = await ui._done
	ui.queue_free()
	return r


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_field = Node2D.new()
	_field.draw.connect(_draw_field)
	add_child(_field)
	for k in 3:
		var kid := AnimatedSprite2D.new()
		kid.sprite_frames = CharacterFrames.adult(CharacterFrames.STRANGERS[k + 1])
		kid.scale = Vector2(0.8, 0.8)  # pelados
		kid.modulate = KID_COLORS[k].lerp(Color.WHITE, 0.55)
		add_child(kid)
		_kids.append({"spr": kid, "pos": Vector2(150 + k * 22, 150), "speed": 52.0 + k * 5.0, "off": Vector2(-14 + k * 14, 10 - k * 8)})
	_dog = AnimatedSprite2D.new()
	_dog.sprite_frames = SpriteFrames.new()
	_dog.sprite_frames.remove_animation("default")
	var cols := {"side": 0, "down": 1, "up": 2}
	for dir in cols:
		_dog.sprite_frames.add_animation("run_" + dir)
		_dog.sprite_frames.set_animation_speed("run_" + dir, 12.0)
		_dog.sprite_frames.add_frame("run_" + dir, Lukas.cell(cols[dir], 1))
		_dog.sprite_frames.add_frame("run_" + dir, Lukas.cell(cols[dir], 2))
	_dog.sprite_frames.add_animation("lie")
	_dog.sprite_frames.add_frame("lie", Lukas.cell(2, 3))
	add_child(_dog)
	_him = AnimatedSprite2D.new()
	_him.sprite_frames = CharacterFrames.protagonist()
	_him.position = Vector2(110, 140)
	add_child(_him)
	_over = Node2D.new()  # la pelota en la boca, el polvo
	_over.draw.connect(_draw_over)
	add_child(_over)
	_hint = Label.new()
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(1, 0.92, 0.55))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.08))
	_hint.position = Vector2(PANEL.position.x, 37)
	_hint.size = Vector2(PANEL.size.x, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "¡Se llevó la pelota! ¡Cójalo!"
	add_child(_hint)


func _process(delta: float) -> void:
	_t += delta
	for d in _dust:
		d["life"] -= delta
		d["p"] += Vector2(0, -6) * delta
	_dust = _dust.filter(func(d): return d["life"] > 0.0)
	if _state == "chase":
		_chase(delta)
	elif _state == "pile":
		_pile(delta)
	_place()
	_field.queue_redraw()
	_over.queue_redraw()


func _chase(delta: float) -> void:
	# Él: con las flechas o la palanca.
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_him.position = (_him.position + move * HIM_SPEED * delta).clamp(FIELD.position, FIELD.end)
	_animate(_him, move, "walk_", "idle_")
	# Lukas: se le aleja, da vueltas por el lote, y cuando lo tiene encima hace el quiebre.
	var tired := clampf(_t / TIME, 0.0, 1.0)
	var away := _dog_pos - _him.position
	var want := away.normalized() * 1.2 + Vector2(sin(_t * 1.3), cos(_t * 0.9)) * 0.8
	var center := FIELD.get_center()
	var edge := 0.0  # contra el muro o la orilla: que vuelva al medio
	if not FIELD.grow(-18).has_point(_dog_pos):
		edge = 1.6
		want += (center - _dog_pos).normalized() * edge
	_juke = maxf(0.0, _juke - delta)
	if away.length() < 24.0 and _juke <= 0.0:
		_juke = 1.0
		_dog_v = away.normalized().rotated(PI / 2.0 * (1.0 if randf() < 0.5 else -1.0))  # el quiebre
		for k in 6:
			_dust.append({"p": _dog_pos + Vector2(randf_range(-4, 4), 2), "life": 0.5})
	if _juke < 0.7:
		_dog_v = _dog_v.lerp(want.normalized(), minf(1.0, delta * 4.0))
	var speed := lerpf(DOG_SPEED, HIM_SPEED * 0.82, tired)
	_dog_pos = (_dog_pos + _dog_v.normalized() * speed * delta).clamp(FIELD.position, FIELD.end)
	_animate_dog(_dog_v)
	# Los pelados: detrás de Lukas, cada uno por su lado; saltan, gritan, se ríen.
	for k in _kids.size():
		var kid: Dictionary = _kids[k]
		var target: Vector2 = _dog_pos + (kid["off"] as Vector2).rotated(sin(_t * 0.7 + k) * 0.6)
		var to: Vector2 = target - kid["pos"]
		var v := to.normalized() * float(kid["speed"]) if to.length() > 3.0 else Vector2.ZERO
		kid["pos"] = (kid["pos"] + v * delta).clamp(FIELD.position, FIELD.end)
		_animate(kid["spr"], v, "walk_", "idle_")
	if _him.position.distance_to(_dog_pos) < 9.0 and _juke < 0.6:
		_caught = true
		_end_chase()
	elif _t > TIME:
		_caught = false
		_end_chase()


## Se acabó: se tiran todos al pasto. Lukas, panza arriba, con la pelota encima (o la trae solo).
func _end_chase() -> void:
	_state = "pile"
	_t = 0.0
	_hint.text = "¡La recuperó! (más o menos)" if _caught else "(Lukas la trae solo. Cuando él quiere.)"
	_dog.play("lie")
	var spot := _dog_pos
	for k in _kids.size():
		var kid: Dictionary = _kids[k]
		var from: Vector2 = kid["pos"]
		create_tween().tween_method(func(v: Vector2) -> void: kid["pos"] = v, from,
			spot + Vector2(-18 + k * 14, -6 + (k % 2) * 12), 0.5)
	var h := create_tween()
	h.tween_property(_him, "position", spot + Vector2(10, 8), 0.4)
	h.tween_callback(func() -> void: _him.play("sit_down"))


func _pile(_delta: float) -> void:
	for kid in _kids:
		kid["spr"].play("idle_down")
	if _t > 3.0 and _state == "pile":
		_state = "closed"
		GameState.ui_open = false
		GameState.block_input(0.3)
		_done.emit(_caught)


func _animate(spr: AnimatedSprite2D, v: Vector2, walk: String, idle: String) -> void:
	if v.length() < 0.1:
		var a := spr.animation
		spr.play(idle + (a.trim_prefix("walk_").trim_prefix("idle_") if a.begins_with("walk_") or a.begins_with("idle_") else "down"))
		return
	if absf(v.x) > absf(v.y):
		spr.flip_h = v.x > 0
		spr.play(walk + "side")
	else:
		spr.play(walk + ("down" if v.y > 0 else "up"))


func _animate_dog(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		_dog.flip_h = v.x > 0  # la hoja mira a la izquierda
		_dog.play("run_side")
	else:
		_dog.play("run_down" if v.y > 0 else "run_up")


func _place() -> void:
	_dog.position = _dog_pos + Vector2(0, -7)
	for kid in _kids:
		var hop := absf(sin(_t * 9.0 + kid["speed"])) * 2.0 if _state == "chase" else 0.0
		kid["spr"].position = kid["pos"] + Vector2(0, -12 - hop)


func _draw_field() -> void:
	var f := _field
	var p := PANEL
	f.draw_rect(p, Color(0.13, 0.22, 0.13))
	for k in 7:  # el pasto, a franjas (lo que queda)
		if k % 2 == 0:
			f.draw_rect(Rect2(p.position.x, 52 + k * 21, p.size.x, 21), Color(0.15, 0.25, 0.14))
	for k in 9:  # los peladeros
		var h := hash(k * 7)
		f.draw_rect(Rect2(p.position.x + 10 + h % 290, 80 + (h / 7) % 80, 9 + h % 6, 3), Color(0.3, 0.26, 0.17, 0.7))
	f.draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 18), Color(0.3, 0.2, 0.18))  # el muro
	for k in 17:
		f.draw_rect(Rect2(p.position.x + k * 20, p.position.y + (9 if k % 2 == 0 else 0), 1, 9), Color(0.2, 0.13, 0.12))
	f.draw_rect(Rect2(p.position.x, p.position.y + 9, p.size.x, 1), Color(0.2, 0.13, 0.12))
	# Los morrales del arco, tirados donde quedaron.
	f.draw_rect(Rect2(110, 72, 9, 8), Color(0.75, 0.25, 0.25))
	f.draw_rect(Rect2(196, 72, 9, 8), Color(0.25, 0.4, 0.75))
	# El tiempo: una raya que se acaba (arriba, en el muro).
	if _state == "chase":
		var left := 1.0 - clampf(_t / TIME, 0.0, 1.0)
		f.draw_rect(Rect2(p.position.x + 8, p.position.y + 13, (p.size.x - 16) * left, 2), Color(1, 0.85, 0.4))


func _draw_over() -> void:
	var n := _over
	for d in _dust:
		n.draw_circle(d["p"], 1.5 + (0.5 - float(d["life"])) * 3.0, Color(0.6, 0.55, 0.45, float(d["life"])))
	# La pelota: en la boca de Lukas mientras corre; al final, encima de él.
	var ball := _dog_pos + Vector2(-6 if not _dog.flip_h else 6, -6)
	if _state != "chase":
		ball = _dog_pos + Vector2(0, -10)
	n.draw_circle(ball, 2.5, Color(0.95, 0.95, 0.92))
	n.draw_circle(ball + Vector2(cos(_t * 14.0), sin(_t * 14.0)) * 1.3, 0.9, Color(0.25, 0.25, 0.25))
	if _state == "pile":  # risas: los pelados se ríen panza arriba (sin letras: las rayitas)
		for kid in _kids:
			var at: Vector2 = kid["pos"] + Vector2(4, -26)
			if fmod(_t * 4.0 + kid["speed"], 1.0) < 0.6:
				n.draw_line(at, at + Vector2(3, -2), Color(1, 1, 1, 0.8))
				n.draw_line(at + Vector2(1, 2), at + Vector2(4, 1), Color(1, 1, 1, 0.8))
