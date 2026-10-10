extends Node
## Trabajo de cargar bultos (Don Germán): agarrar uno de la pila, llevarlo hasta el horno, repetir.
## Mientras carga camina más lento. Se agrega a la escena de la panadería al aceptar el trabajo.

signal finished

const PILE := Vector2(266, 96)
const DROP := Vector2(176, 82)
const TOTAL := 4
const SACK_REGION := Rect2(12 * 16, 0, 16, 16)  # bolsas de harina en interior_custom.png

var _done := 0
var _carrying := false
var _player: Node2D
var _sack: Sprite2D
var _pile: Area2D
var _drop: Area2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_pile = _zone(PILE, "CARGAR")
	_drop = _zone(DROP, "DEJAR")
	_sack = Sprite2D.new()
	var t := AtlasTexture.new()
	t.atlas = load("res://assets/tilesets/interior_custom.png")
	t.region = SACK_REGION
	_sack.texture = t
	_sack.position = Vector2(0, -26)
	_sack.visible = false
	_player.add_child(_sack)
	_update_hints()


func _zone(pos: Vector2, text: String) -> Area2D:
	var a := Area2D.new()
	a.position = pos
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(30, 22)
	s.shape = r
	a.add_child(s)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	l.position = Vector2(-24, -24)
	l.size = Vector2(48, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.name = "Hint"
	a.add_child(l)
	get_parent().add_child.call_deferred(a)
	return a


var _lifting := false
var _slow := 0.7  # con el bulto: así de rápido camina (alzado mal, más lento)


func _process(_delta: float) -> void:
	if _player == null or GameState.input_blocked() or _lifting:
		return
	_player.carry_factor = _slow if _carrying else 1.0
	if not Input.is_action_just_pressed("interact"):
		return
	var on_pile := _pile.overlaps_body(_player)
	var on_drop := _drop.overlaps_body(_player)
	if not _carrying and on_pile:
		# Alzarlo: con las piernas (a tiempo) o con la espalda (mal: camina más lento con ese).
		_lifting = true
		var ok: int = await Ritmo.play(self, "Alzarlo con las piernas", 1,
			{"zone": 40.0, "speed": 130.0, "hit": "Arriba. Con técnica.", "miss": "Uy. La espalda."})
		_lifting = false
		_slow = 0.75 if ok > 0 else 0.5
		_carrying = true
		_sack.visible = true
		Narrator.say("(Pesa como plomo.)" if ok > 0 else "(Lo alzó con la espalda. La espalda se va a acordar mañana.)")
	elif _carrying and on_pile:
		Narrator.say("(Ya lleva uno. Dos no: tiene cuarenta y pico, no veinte.)")
	elif _carrying and on_drop:
		_carrying = false
		_sack.visible = false
		_done += 1
		if _done >= TOTAL:
			_finish()
			return
		Narrator.say("%d de %d." % [_done, TOTAL])
	_update_hints()


func _update_hints() -> void:
	_pile.get_node("Hint").visible = not _carrying
	_drop.get_node("Hint").visible = _carrying


func _finish() -> void:
	_player.carry_factor = 1.0
	_sack.queue_free()
	_pile.queue_free()
	_drop.queue_free()
	finished.emit()
	queue_free()
