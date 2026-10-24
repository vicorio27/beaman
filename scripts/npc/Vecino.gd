class_name Vecino
extends Area2D
## Alguien que vive su vida adentro de un lugar (Interior.gd): va de un punto a otro de su rutina, se
## queda un rato haciendo lo suyo (rezar, barrer, esperar el turno, jugar maquinitas) y de vez en
## cuando dice algo solo. Si él se le acerca y le da [E], le dice una de las suyas (en una burbuja:
## no es una conversación, es la vida pasando al lado).
##   spec: {"row": int, "id": "" (un personaje con dibujo propio), "path": [Vector2...], "wait": seg,
##          "pose": "up"/"down"/"side" (cómo se queda en cada punto), "say": [lo que dice solo],
##          "talk": [lo que le dice a él]}

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

var spec := {}
var _player: Node2D
var _sprite: AnimatedSprite2D
var _bubble: Label
var _hint: Label
var _i := 0
var _wait := 0.0
var _say_t := 0.0
var _talk_i := 0


func _ready() -> void:
	add_to_group(Focus.GROUP)
	var path: Array = spec.get("path", [position])
	position = path[0]
	_wait = randf_range(0.5, float(spec.get("wait", 4.0)))
	_say_t = randf_range(6.0, 16.0)
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(26, 22)
	s.shape = r
	add_child(s)
	_sprite = AnimatedSprite2D.new()
	CharacterFrames.dress(_sprite, int(spec.get("row", 0)), str(spec.get("id", "")), str(spec.get("id", "")) == "")
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	_pose()
	_bubble = _label(Color(0.95, 0.92, 0.85))
	_bubble.size = Vector2(120, 20)
	_bubble.position = Vector2(-60, -42)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bg := StyleBoxFlat.new()  # (fondo oscuro: no se lee encima de letreros ni bombillos)
	bg.bg_color = Color(0.05, 0.04, 0.06, 0.72)
	bg.set_content_margin_all(2)
	_bubble.add_theme_stylebox_override("normal", bg)
	_bubble.visible = false
	_hint = _label(Color(1, 1, 1))
	_hint.text = "HABLAR"
	_hint.size = Vector2(60, 10)
	_hint.position = Vector2(-30, -30)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.visible = false
	body_entered.connect(func(b: Node2D) -> void:
		if b.is_in_group("player"):
			_player = b)
	body_exited.connect(func(b: Node2D) -> void:
		if b == _player:
			_player = null)


func _label(col: Color) -> Label:
	var l := Label.new()
	l.add_to_group("texto_mundo")  # (Hud: no se monta sobre otro texto)
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.06))
	l.z_index = 20
	add_child(l)
	return l


func _pose() -> void:
	var p: String = spec.get("pose", "down")
	_sprite.play("idle_" + p)
	_sprite.flip_h = bool(spec.get("flip", false))


## El globo crece para arriba (no tapa a quien habla) y nunca se sale de la pantalla.
func _place_bubble() -> void:
	_bubble.size = Vector2(120, 0)
	var h := _bubble.get_combined_minimum_size().y
	var view := get_viewport().get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	var x := clampf(global_position.x - 60.0, view.position.x + 2.0, view.position.x + Controls.right_edge() - 122.0)  # (en el celular, la franja de los botones queda libre)
	var y := maxf(global_position.y - 22.0 - h, view.position.y + 2.0)
	_bubble.global_position = Vector2(x, y)


func _process(delta: float) -> void:
	if _bubble.visible:
		_place_bubble()
	_hint.visible = _player != null and not GameState.input_blocked() and not _bubble.visible
	Focus.dim(self, _hint)
	if GameState.ui_open or Dialogue.active:
		return
	if _player and Input.is_action_just_pressed("interact") and not GameState.input_blocked() and Focus.mine(self):
		var talk: Array = spec.get("talk", [])
		if not talk.is_empty():
			_sprite.play("idle_down")
			say(talk[_talk_i % talk.size()])
			_talk_i += 1
			var lukas := get_tree().current_scene.find_child("Lukas", true, false)
			if lukas and lukas.has_method("greet"):
				lukas.greet(self, str(spec.get("id", name)))
			GameState.company(2.0)
			_wait = maxf(_wait, 2.5)
		return
	_say_t -= delta
	if _say_t <= 0.0:
		_say_t = randf_range(10.0, 22.0)
		var own: Array = spec.get("say", [])
		if not own.is_empty() and randf() < 0.6:
			say(own.pick_random())
	var path: Array = spec.get("path", [])
	if path.size() < 2:
		return
	if _wait > 0.0:
		_wait -= delta
		return
	var target: Vector2 = path[(_i + 1) % path.size()]
	var to := target - position
	if to.length() < 1.0:
		_i = (_i + 1) % path.size()
		_wait = float(spec.get("wait", 4.0)) * randf_range(0.7, 1.3)
		_pose()
		return
	position = position.move_toward(target, 18.0 * delta)
	if absf(to.x) > absf(to.y):
		_sprite.play("walk_side")
		_sprite.flip_h = to.x > 0
	else:
		_sprite.play("walk_down" if to.y > 0 else "walk_up")


func say(t: String) -> void:
	_bubble.text = t
	_bubble.modulate.a = 1.0
	_bubble.visible = true
	_place_bubble()
	var tw := create_tween()
	tw.tween_interval(maxf(2.2, t.length() * 0.06))
	tw.tween_property(_bubble, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: _bubble.visible = false)
