extends CanvasLayer
## HUD de arcade del sueño: retrato, vida, puntaje, contador y barra del jefe.
## El sueño es un videojuego, así que acá sí hay HUD clásico (en la vida real, no).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const BAR_W := 60.0

var _life: ColorRect
var _score: Label
var _counter: Label
var _boss_box: Control
var _boss_life: ColorRect
var _boss_name: Label


func _ready() -> void:
	layer = 12
	var avatar := TextureRect.new()
	avatar.texture = load("res://assets/prologue/avatar_player.png")
	avatar.position = Vector2(4, 4)
	add_child(avatar)
	_add_label("1P", Vector2(18, 4))
	_life = _add_bar(Vector2(18, 14), Color(0.95, 0.8, 0.3))
	_score = _add_label("000000", Vector2(40, 4))
	_counter = _add_label("", Vector2(262, 4))

	_boss_box = Control.new()
	_boss_box.visible = false
	add_child(_boss_box)
	var boss_avatar := TextureRect.new()
	boss_avatar.texture = load("res://assets/prologue/avatar_boss.png")
	boss_avatar.position = Vector2(4, 24)
	_boss_box.add_child(boss_avatar)
	_boss_name = _add_label("", Vector2(18, 24), _boss_box)
	_boss_life = _add_bar(Vector2(18, 34), Color(0.85, 0.2, 0.2), _boss_box, 120.0)


func _add_label(text: String, pos: Vector2, parent: Node = self) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	parent.add_child(l)
	return l


func _add_bar(pos: Vector2, color: Color, parent: Node = self, width := BAR_W) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.1)
	bg.position = pos - Vector2(1, 1)
	bg.size = Vector2(width + 2, 5)
	parent.add_child(bg)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = pos
	fill.size = Vector2(width, 3)
	fill.set_meta("full", width)
	parent.add_child(fill)
	return fill


func set_life(ratio: float) -> void:
	_life.size.x = _life.get_meta("full") * clampf(ratio, 0.0, 1.0)


func set_score(points: int) -> void:
	_score.text = "%06d" % points


func set_counter(text: String) -> void:
	_counter.text = text


func show_boss(boss_name: String) -> void:
	_boss_name.text = boss_name
	_boss_box.visible = true


func set_boss(ratio: float) -> void:
	_boss_life.size.x = _boss_life.get_meta("full") * clampf(ratio, 0.0, 1.0)
	if ratio <= 0.0:
		_boss_box.visible = false
