class_name TenisPicker
extends Node2D
## El selector de tenistas: la lista (un nombre por fila), el apodo del marcado abajo y él, grande y
## de frente, a la derecha, sobre el coliseo apagado. Lo usan el partido suelto (tenista y rival) y
## el torneo (solo el tenista).
##   var p := TenisPicker.new()
##   p.titles = ["ESCOGE TU TENISTA", "ESCOGE EL RIVAL"]   # uno por cada escogida
##   p.picked.connect(func(ids): ...)                     # ids: Array de los escogidos, en orden
##   add_child(p)

signal picked(ids: Array)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const BG := preload("res://assets/tenis/coliseo.png")
const CELL := Vector2(32, 42)

var titles: Array = ["ESCOGE TU TENISTA"]
var roster: Array = TenisData.ROSTER
var _step := 0
var _cursor := 0
var _chosen: Array = []
var _hud: CanvasLayer
var _arrows: Array = []
var _head: Label
var _title: Label
var _sheets := {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 6
	add_child(_hud)
	for id in roster:
		var path := "res://assets/tenis/%s.png" % id
		if ResourceLoader.exists(path):
			_sheets[id] = load(path)
	_head = _label(Vector2(0, 10), Color(1, 0.9, 0.5), true)
	for i in roster.size():
		var d: Dictionary = TenisData.player(roster[i])
		_label(Vector2(30, 28 + i * 12), d["color"]).text = d["name"]
		_arrows.append(_label(Vector2(18, 28 + i * 12), Color(1, 0.95, 0.75)))
	_title = _label(Vector2(0, 154), Color(0.75, 0.78, 0.86), true)
	_label(Vector2(0, 168), Color(0.85, 0.9, 1.0), true).text = "FLECHAS: CAMBIAR   E: ESCOGER"
	_refresh()


func _label(at: Vector2, col: Color, centered := false) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	if centered:
		l.size = Vector2(Controls.right_edge(), 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(l)
	return l


func _refresh() -> void:
	_head.text = TenisData.caps(titles[_step])
	for i in roster.size():
		_arrows[i].text = ">" if i == _cursor else ("·" if roster[i] in _chosen else "")
	_title.text = TenisData.player(roster[_cursor])["title"]


func _process(_delta: float) -> void:
	var n := roster.size()
	if Input.is_action_just_pressed("move_down"):
		_cursor = (_cursor + 1) % n
	elif Input.is_action_just_pressed("move_up"):
		_cursor = (_cursor + n - 1) % n
	elif Input.is_action_just_pressed("interact") and not roster[_cursor] in _chosen:
		_chosen.append(roster[_cursor])
		_step += 1
		if _step >= titles.size():
			set_process(false)
			picked.emit(_chosen)
			return
		_cursor = (_cursor + 1) % n
	_refresh()
	queue_redraw()


func _draw() -> void:
	draw_texture(BG, Vector2.ZERO)
	draw_rect(Rect2(0, 0, 320, 180), Color(0.04, 0.04, 0.08, 0.72))  # el coliseo, apagado
	var tex: Texture2D = _sheets.get(roster[_cursor])
	if tex != null:  # el marcado, grande y de frente
		var t := Time.get_ticks_msec() / 1000.0
		var col := 0 if fmod(t, 0.8) < 0.4 else 1   # "listo" / "listo2"
		draw_texture_rect_region(tex, Rect2(Vector2(240, 40), CELL * 2), Rect2(Vector2(col * CELL.x, CELL.y), CELL))
