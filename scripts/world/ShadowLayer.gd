@tool
class_name ShadowLayer
extends Node2D
## Sombras proyectadas (la luz viene de arriba a la izquierda).
## Las formas se pintan juntas en una sola imagen al cargar, así dos sombras que se
## superponen no se oscurecen el doble. Va debajo de los edificios y objetos.

@export var area_size := Vector2i(960, 992):
	set(value):
		area_size = value
		_rebuild()
@export var color := Color(0.18, 0.13, 0.18, 0.3):
	set(value):
		color = value
		queue_redraw()
@export var rects: Array[Rect2] = []:
	set(value):
		rects = value
		_rebuild()
@export var ellipses: Array[Rect2] = []:
	set(value):
		ellipses = value
		_rebuild()

var _tex: ImageTexture


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree() or area_size.x <= 0 or area_size.y <= 0:
		return
	var img := Image.create(area_size.x, area_size.y, false, Image.FORMAT_RGBA8)
	var solid := Color(color.r, color.g, color.b, 1.0)
	var bounds := Rect2i(Vector2i.ZERO, area_size)
	for r in rects:
		var ri := Rect2i(r).intersection(bounds)
		if ri.has_area():
			img.fill_rect(ri, solid)
	for e in ellipses:
		_fill_ellipse(img, Rect2i(e), solid)
	_tex = ImageTexture.create_from_image(img)
	queue_redraw()


func _fill_ellipse(img: Image, r: Rect2i, c: Color) -> void:
	var rx := r.size.x / 2.0
	var ry := r.size.y / 2.0
	var center := Vector2(r.position) + Vector2(rx, ry)
	for y in range(r.position.y, r.end.y):
		if y < 0 or y >= area_size.y:
			continue
		var t := (y + 0.5 - center.y) / ry
		var half := rx * sqrt(maxf(0.0, 1.0 - t * t))
		var x0 := maxi(0, int(round(center.x - half)))
		var x1 := mini(area_size.x, int(round(center.x + half)))
		if x1 > x0:
			img.fill_rect(Rect2i(x0, y, x1 - x0, 1), c)


func _draw() -> void:
	if _tex:
		draw_texture(_tex, Vector2.ZERO, Color(1, 1, 1, color.a))
