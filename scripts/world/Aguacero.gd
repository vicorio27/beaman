extends Node2D
## La lluvia del aguacero (evento del día): rayas que caen sobre toda la pantalla.

var _drops: Array = []


func _ready() -> void:
	for i in 90:
		_drops.append(Vector2(randf_range(0, 340), randf_range(0, 180)))


func _process(delta: float) -> void:
	for i in _drops.size():
		var d: Vector2 = _drops[i] + Vector2(-60, 260) * delta
		if d.y > 182:
			d = Vector2(randf_range(0, 360), -4)
		_drops[i] = d
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.1, 0.12, 0.2, 0.25))
	for d in _drops:
		draw_line(d, d + Vector2(-2, 7), Color(0.75, 0.82, 0.95, 0.6))
