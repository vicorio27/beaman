class_name Ritmo
extends CanvasLayer
## Un toque de tiempo, corto (las cosas buenas del barrio no son solo leer): una barra con una zona
## verde y una marca que va y viene. Apretar la acción cuando la marca está en lo verde.
##   var hits: int = await Ritmo.play(self, "Empujarse", 5)
##   opts: "zone" (ancho de lo verde, px), "speed" (px/s al empezar), "speedup" (cuánto acelera por
##   vuelta), "hit" / "miss" (lo que dice), "color" (la zona).
## Atrás: dejarlo (devuelve lo que llevaba).

signal _done(hits: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const TRACK := Rect2(56, 112, 208, 6)

var _title := ""
var _rounds := 3
var _opts := {}
var _round := 0
var _hits := 0
var _x := 0.0
var _dir := 1.0
var _speed := 120.0
var _state := "run"
var _t := 0.0
var _guard := 0.3
var _zone: ColorRect
var _marker: ColorRect
var _msg: Label
var _count: Label


static func play(parent: Node, title: String, rounds: int, opts := {}) -> int:
	var ui := Ritmo.new()
	ui._title = title
	ui._rounds = rounds
	ui._opts = opts
	parent.get_tree().root.add_child(ui)
	var res: int = await ui._done
	ui.queue_free()
	return res


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.05, 0.07)
	panel.position = Vector2(40, 78)
	panel.size = Vector2(240, 66)
	add_child(panel)
	var title := _label(Vector2(44, 84), Color(0.95, 0.85, 0.55))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(232, 10)
	title.size = Vector2(232, 10)
	title.text = _title  # cabe en 29 letras; si no, se corta con "..."
	var track := ColorRect.new()
	track.color = Color(0.25, 0.22, 0.26)
	track.position = TRACK.position
	track.size = TRACK.size
	add_child(track)
	_zone = ColorRect.new()
	_zone.color = _opts.get("color", Color(0.4, 0.8, 0.45))
	_zone.size = Vector2(_opts.get("zone", 34.0), TRACK.size.y)
	add_child(_zone)
	_marker = ColorRect.new()
	_marker.color = Color(0.98, 0.96, 0.9)
	_marker.size = Vector2(3, 14)
	add_child(_marker)
	_msg = _label(Vector2(44, 96), Color(0.93, 0.91, 0.87))
	_msg.size = Vector2(232, 10)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count = _label(Vector2(44, 128), Color(0.6, 0.58, 0.55))
	_count.size = Vector2(232, 10)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed = _opts.get("speed", 110.0)
	_new_round()


func _label(pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(l)
	return l


func _new_round() -> void:
	_state = "run"
	_x = 0.0
	_dir = 1.0
	var zw: float = _zone.size.x
	_zone.position = Vector2(TRACK.position.x + randf_range(TRACK.size.x * 0.35, TRACK.size.x - zw), TRACK.position.y)
	_zone.color = _opts.get("color", Color(0.4, 0.8, 0.45))
	_msg.text = "[%s] en lo verde" % Controls.key_name("interact")
	_count.text = "%d de %d   [%s] dejar" % [_round + 1, _rounds, Controls.key_name("cancel")]


func _process(delta: float) -> void:
	_guard -= delta
	_t += delta
	if _state == "run":
		_x += _dir * _speed * delta
		if _x >= TRACK.size.x:
			_x = TRACK.size.x
			_dir = -1.0
		elif _x <= 0.0:
			_x = 0.0
			_dir = 1.0
	elif _state == "show" and _t > 0.7:
		_round += 1
		if _round >= _rounds:
			_close()
			return
		_speed += _opts.get("speedup", 18.0)
		_new_round()
	_marker.position = Vector2(TRACK.position.x + _x - 1.0, TRACK.position.y - 4.0)


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0 or _state == "closed":
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif event.is_action_pressed("interact") and _state == "run":
		get_viewport().set_input_as_handled()
		var mx := TRACK.position.x + _x
		var inside := mx >= _zone.position.x - 1.0 and mx <= _zone.position.x + _zone.size.x + 1.0
		if inside:
			_hits += 1
			_zone.color = Color(0.98, 0.96, 0.9)
		else:
			_zone.color = Color(0.8, 0.3, 0.25)
		_msg.text = _opts.get("hit", "¡Eso!") if inside else _opts.get("miss", "Casi.")
		_state = "show"
		_t = 0.0


func _close() -> void:
	if _state == "closed":
		return
	_state = "closed"
	GameState.ui_open = false
	GameState.block_input(0.2)
	_done.emit(_hits)
