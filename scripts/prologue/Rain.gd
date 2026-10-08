extends Node2D
## Lluvia fina de pantalla (líneas diagonales). Se dibuja en coordenadas de pantalla:
## ponerla dentro de un CanvasLayer.

@export var drops := 90
@export var speed := 260.0
@export var wind := -60.0
@export var color := Color(0.75, 0.8, 0.9, 0.35)

var _pos: PackedVector2Array = []
var _size := Vector2(320, 180)


func _ready() -> void:
	_size = get_viewport_rect().size
	for i in drops:
		_pos.append(Vector2(randf() * _size.x, randf() * _size.y))


func _process(delta: float) -> void:
	var step := Vector2(wind, speed) * delta
	for i in _pos.size():
		var p := _pos[i] + step
		if p.y > _size.y:
			p = Vector2(randf() * (_size.x + 60), -4)
		if p.x < -8:
			p.x += _size.x + 16
		_pos[i] = p
	queue_redraw()


func _draw() -> void:
	var tail := Vector2(wind, speed).normalized() * 5.0
	for p in _pos:
		draw_line(p, p - tail, color, 1.0)
