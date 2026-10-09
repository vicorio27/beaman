class_name Pesca
extends CanvasLayer
## Pescar en la orilla del río (lo bueno del barrio): tres lanzadas. Se espera mirando el corcho;
## a veces mordisquea (no es nada); cuando PICA, hay que darle a la acción rápido.
##   var got: Array = await Pesca.fish(self)   # ["pescado", "lata", "bota", "nada", ...]
## Atrás: dejar de pescar.

signal _done(results: Array)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CASTS := 3
const WINDOW := 0.75  # cuánto dura el "¡PICA!"
## [qué sale, peso]
const CATCH := [["pescado", 40], ["lata", 18], ["botella", 14], ["bota", 16], ["nada", 12]]
const NAMES := {"pescado": "¡Un bocachico!", "lata": "Una lata. Algo es algo.", "botella": "Una botella. Wilson la paga.",
	"bota": "Una bota. Sin el pie, por suerte.", "nada": "Se soltó."}

var _results: Array = []
var _cast := 0
var _state := "wait"
var _t := 0.0
var _bite_at := 0.0
var _nibbles: Array = []
var _bob: ColorRect
var _line: Line2D
var _msg: Label
var _count: Label
var _guard := 0.3


static func fish(parent: Node) -> Array:
	var ui := Pesca.new()
	parent.get_tree().root.add_child(ui)
	var res: Array = await ui._done
	ui.queue_free()
	return res


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	var water := ColorRect.new()
	water.color = Color(0.1, 0.16, 0.18, 0.92)
	water.position = Vector2(40, 96)
	water.size = Vector2(240, 66)
	add_child(water)
	for i in 6:  # rayitas del río
		var r := ColorRect.new()
		r.color = Color(0.3, 0.42, 0.44, 0.6)
		r.position = Vector2(50 + (i * 37) % 210, 104 + i * 9)
		r.size = Vector2(14 + (i * 7) % 12, 1)
		add_child(r)
	_line = Line2D.new()
	_line.width = 1.0
	_line.default_color = Color(0.85, 0.85, 0.85, 0.7)
	add_child(_line)
	_bob = ColorRect.new()
	_bob.color = Color(0.9, 0.3, 0.25)
	_bob.size = Vector2(4, 4)
	add_child(_bob)
	_msg = _label(Vector2(40, 82), Color(0.93, 0.91, 0.87))
	_msg.size = Vector2(240, 10)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count = _label(Vector2(46, 150), Color(0.6, 0.58, 0.55))
	_new_cast()


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


func _new_cast() -> void:
	_state = "wait"
	_t = 0.0
	_bite_at = randf_range(2.0, 5.0)
	_nibbles = [randf_range(0.6, _bite_at - 0.4)] if randf() < 0.7 else []
	_msg.text = "Espera... [E] cuando pique"
	_count.text = "Lanzada %d de %d   [Q] dejar" % [_cast + 1, CASTS]


func _process(delta: float) -> void:
	_guard -= delta
	_t += delta
	var base := Vector2(160, 128)
	var dip := 0.0
	match _state:
		"wait":
			dip = sin(_t * 3.0) * 1.0
			for n in _nibbles:
				if absf(_t - n) < 0.15:
					dip = 2.0  # mordisquea: no es nada todavía
			if _t >= _bite_at:
				_state = "bite"
				_t = 0.0
				_msg.text = "¡PICA!"
		"bite":
			dip = 4.0
			if _t > WINDOW:
				_finish("nada")
		"show":
			if _t > 1.4:
				_cast += 1
				if _cast >= CASTS:
					_close()
				else:
					_new_cast()
	_bob.position = base + Vector2(0, dip)
	_line.points = PackedVector2Array([Vector2(300, 60), _bob.position + Vector2(2, 0)])


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _state == "bite":
			_finish(_roll())
		elif _state == "wait":
			_msg.text = "Muy pronto. Se espantó."
			_results.append("nada")
			_state = "show"
			_t = 0.0


func _roll() -> String:
	var total := 0
	for c in CATCH:
		total += c[1]
	var r := randi() % total
	for c in CATCH:
		r -= c[1]
		if r < 0:
			return c[0]
	return "nada"


func _finish(what: String) -> void:
	_results.append(what)
	_msg.text = NAMES[what]
	_state = "show"
	_t = 0.0


func _close() -> void:
	if _state == "closed":
		return
	_state = "closed"
	GameState.ui_open = false
	GameState.block_input(0.2)
	_done.emit(_results)
