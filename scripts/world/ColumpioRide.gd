class_name ColumpioRide
extends Node2D
## Columpiarse de verdad (el columpio del parquecito, en City): él sentado en la tabla y el columpio se
## mece como un péndulo. Se ve de frente: cuando va para adelante la tabla baja y se agranda (viene
## hacia uno); para atrás, sube y se achica. Las cadenas y la tabla se dibujan aquí, meciéndose (al
## dibujo del columpio se le quitan las suyas mientras tanto).
##   ↓ cuando va para adelante, ↑ cuando va para atrás: se impulsa (como con las piernas). E: bajarse.
##   Lukas, echado al lado, le ladra cada vez que llega adelante.
##   var alto: float = await ColumpioRide.ride(swing, player)   # lo más alto que llegó (0..1)

signal finished(top: float)

const G_OVER_L := 8.2      # (el período, unos dos segundos)
const DAMP := 0.18
const PUMP := 3.4
const MAX := 1.15
const PIVOT := Vector2(-3, -33)   # en el dibujo del columpio: de donde cuelgan las cadenas
const LENGTH := 23.0

var _swing: Sprite2D
var _player: Node2D
var _sprite: Node2D
var _orig_tex: Texture2D
var _base_pos := Vector2.ZERO
var _base_scale := Vector2.ONE
var _theta := 0.0
var _omega := 0.0
var _top := 0.0
var _leaving := false
var _t := 0.0
var _hint: Label
var _layer: CanvasLayer


static func ride(swing: Sprite2D, player: Node2D) -> float:
	var r := ColumpioRide.new()
	r._swing = swing
	r._player = player
	swing.add_child(r)
	var top: float = await r.finished
	r.queue_free()
	return top


func _ready() -> void:
	_sprite = _player.get_node("Sprite")
	_base_pos = _sprite.position
	_base_scale = _sprite.scale
	# El columpio sin su tabla ni sus cadenas (las de aquí se mecen).
	_orig_tex = _swing.texture
	var img := _orig_tex.get_image()
	img.fill_rect(Rect2i(11, 4, 13, 27), Color(0, 0, 0, 0))
	_swing.texture = ImageTexture.create_from_image(img)
	GameState.ui_open = true
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	_hint = Label.new()
	_hint.add_to_group("texto_mundo")  # (Hud: no se monta sobre otro texto)
	_hint.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.08))
	_hint.position = Vector2(0, 150)
	_hint.size = Vector2(Controls.right_edge(), 24)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.text = Controls.keys_in("Abajo cuando va adelante, arriba cuando va atrás. E: bajarse")
	_layer.add_child(_hint)
	_theta = -0.15  # se echa para atrás con los pies, para arrancar


func _process(delta: float) -> void:
	_t += delta
	var before := _omega
	var acc := -G_OVER_L * sin(_theta) - DAMP * _omega
	if _leaving:
		acc -= 2.2 * _omega  # frena con los pies, arrastrándolos
	elif absf(_omega) > 0.05:
		var fwd := _omega > 0.0
		if (fwd and Input.is_action_pressed("move_down")) or (not fwd and Input.is_action_pressed("move_up")):
			acc += PUMP * signf(_omega) * cos(_theta)
	_omega += acc * delta
	_theta = clampf(_theta + _omega * delta, -MAX, MAX)
	_top = maxf(_top, absf(_theta) / MAX)
	# Lukas le ladra cada vez que llega adelante.
	if before > 0.0 and _omega <= 0.0 and _theta > 0.35:
		var lukas := get_tree().current_scene.find_child("Lukas", true, false)
		if lukas and lukas.get("sprite"):
			lukas.sprite.play("bark")
			get_tree().create_timer(0.4).timeout.connect(func() -> void:
				if is_instance_valid(lukas) and lukas.sprite.animation == "bark":
					lukas.sprite.play("lie"))
	if not _leaving and Input.is_action_just_pressed("interact") and _t > 0.6:
		_leaving = true
		_hint.text = "(Frena con los pies.)"
	_place()
	queue_redraw()
	if _leaving and absf(_omega) < 0.12 and absf(_theta) < 0.08:
		_finish()


## Dónde queda la tabla (en el dibujo del columpio) y qué tan grande se ve, según el ángulo.
func _seat() -> Array:
	var s := sin(_theta)
	var y := PIVOT.y + LENGTH * cos(_theta) + 7.0 * s
	return [Vector2(PIVOT.x, y), 1.0 + 0.16 * s]


func _place() -> void:
	var seat: Array = _seat()
	var dy: float = seat[0].y - (PIVOT.y + LENGTH)
	_sprite.position = _base_pos + Vector2(0, dy)
	_sprite.scale = _base_scale * float(seat[1])


func _draw() -> void:
	var seat: Array = _seat()
	var at: Vector2 = seat[0]
	var k: float = seat[1]
	var half := 6.0 * k
	var ink := Color(0.13, 0.1, 0.14)
	for side in [-1.0, 1.0]:  # las cadenas: de la barra a las puntas de la tabla
		var top := PIVOT + Vector2(side * 3.0, 0)
		var bottom := at + Vector2(side * (half - 1.0), -1)
		draw_line(top, bottom, ink, 2.0)
		draw_line(top, bottom, Color(0.55, 0.56, 0.62), 1.0)
		var n := int(top.distance_to(bottom) / 3.0)
		for i in n:  # los eslabones
			var p := top.lerp(bottom, (i + 0.5) / n)
			draw_rect(Rect2(p.x, p.y, 1, 1), Color(0.75, 0.76, 0.8))
	draw_rect(Rect2(at.x - half - 1, at.y - 1, half * 2 + 2, 4 * k), ink)  # la tabla
	draw_rect(Rect2(at.x - half, at.y, half * 2, 2 * k), Color(0.5, 0.36, 0.22))


func _finish() -> void:
	set_process(false)
	_sprite.position = _base_pos
	_sprite.scale = _base_scale
	_swing.texture = _orig_tex
	GameState.ui_open = false
	GameState.block_input(0.3)
	finished.emit(_top)
