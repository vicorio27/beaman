extends Node2D
## Las láminas del prólogo: mientras se cuenta lo que pasó (Huida.gd, INTRO), sobre el negro se va
## dibujando, raya por raya, lo que dice cada texto. Tiza sobre tablero: pocas líneas, sin caras.
##   show_page(i)  empieza a dibujar la lámina del texto i.
##   clear()       borra.
## Caben arriba del cuadro de diálogo (y < 114) y a la izquierda de los botones del celular (x < 286).
## Cada lámina (_page_N) es una lista de trazos; se dibujan en orden, el último a medias.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const INK := Color(0.86, 0.83, 0.76)
const DIM := Color(0.42, 0.4, 0.44)
const RED := Color(0.88, 0.26, 0.26)
const BLUE := Color(0.35, 0.5, 0.95)
const GOLD := Color(0.95, 0.8, 0.4)
const SECONDS := 1.3  # lo que tarda en dibujarse una lámina

var _ops: Array = []
var _p := 0.0  # trazos ya dibujados (con fracción)
var _t := 0.0


func show_page(i: int) -> void:
	_ops.clear()
	_p = 0.0
	if has_method("_page_%d" % i):
		call("_page_%d" % i)
	queue_redraw()


func clear() -> void:
	_ops.clear()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _ops.is_empty():
		return
	_p = minf(_p + _ops.size() / SECONDS * delta, float(_ops.size()))
	queue_redraw()


func _draw() -> void:
	for i in _ops.size():
		var k := clampf(_p - i, 0.0, 1.0)
		if k <= 0.0:
			break
		var o: Array = _ops[i]
		match o[0]:
			"p":  # una raya (o varias seguidas)
				_poly(o[1], k, o[2], o[3])
			"f":  # relleno
				var r: Rect2 = o[1]
				draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), o[2])
			"c":
				draw_arc(o[1], o[2], o[4], o[4] + (o[5] - o[4]) * k, 20, o[3], 1.0)
			"d":  # un punto lleno
				draw_circle(o[1], o[2] * k, o[3])
			"t":
				var s: String = o[2]
				draw_string(FONT, o[1], s.substr(0, int(ceil(s.length() * k))), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, o[3])
			"b":  # las sirenas: rojo, azul, rojo
				if k >= 1.0:
					draw_rect(o[1], o[2] if fmod(_t * 3.0, 1.0) < 0.5 else o[3])


func _poly(pts: PackedVector2Array, k: float, col: Color, w: float) -> void:
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var left := total * k
	for i in pts.size() - 1:
		var d := pts[i].distance_to(pts[i + 1])
		if left <= 0.0 or d <= 0.0:
			break
		draw_line(pts[i], pts[i].lerp(pts[i + 1], minf(1.0, left / d)), col, w)
		left -= d


# ---------------------------------------------------------------- Trazos

func _l(pts: Array, col := INK, w := 1.0) -> void:
	_ops.append(["p", PackedVector2Array(pts), col, w])


func _r(x: float, y: float, w: float, h: float, col := INK) -> void:
	_l([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h), Vector2(x, y)], col)


func _f(x: float, y: float, w: float, h: float, col: Color) -> void:
	_ops.append(["f", Rect2(x, y, w, h), col])


func _c(at: Vector2, radius: float, col := INK, from := 0.0, to := TAU) -> void:
	_ops.append(["c", at, radius, col, from, to])


func _d(at: Vector2, radius: float, col := INK) -> void:
	_ops.append(["d", at, radius, col])


func _txt(x: float, y: float, text: String, col := INK) -> void:
	_ops.append(["t", Vector2(x, y), text, col])


func _blink(x: float, y: float, w: float, h: float, a: Color, b: Color) -> void:
	_ops.append(["b", Rect2(x, y, w, h), a, b])


## Alguien, sin cara. Los pies en (x, y).
func _person(x: float, y: float, col := INK, dress := false) -> void:
	_c(Vector2(x, y - 22), 3.5, col)
	if dress:
		_l([Vector2(x, y - 18), Vector2(x - 6, y - 5), Vector2(x + 6, y - 5), Vector2(x, y - 18)], col)
		_l([Vector2(x - 2, y - 5), Vector2(x - 2, y)], col)
		_l([Vector2(x + 2, y - 5), Vector2(x + 2, y)], col)
	else:
		_l([Vector2(x, y - 18), Vector2(x, y - 8), Vector2(x - 4, y)], col)
		_l([Vector2(x, y - 8), Vector2(x + 4, y)], col)
	_l([Vector2(x - 5, y - 10), Vector2(x, y - 16), Vector2(x + 6, y - 12)], col)


func _door(x: float, y: float, number: String, col: Color) -> void:
	_r(x, y, 50, 76)
	_r(x + 11, y + 9, 28, 12, DIM)
	_txt(x + 13, y + 19, number, col)
	_d(Vector2(x + 43, y + 42), 2.0)


# ---------------------------------------------------------------- Las láminas

## El apartamento con todo pago: la nevera, el sofá, la moto, la cama de Lukas con dos cobijas.
func _page_0() -> void:
	_l([Vector2(56, 100), Vector2(266, 100)], DIM)
	_l([Vector2(160, 6), Vector2(160, 20)], DIM)
	_l([Vector2(152, 28), Vector2(160, 20), Vector2(168, 28), Vector2(152, 28)], GOLD)
	_r(66, 56, 22, 44)
	_l([Vector2(66, 72), Vector2(88, 72)])
	_l([Vector2(84, 60), Vector2(84, 68)], DIM)
	_l([Vector2(84, 77), Vector2(84, 90)], DIM)
	_r(102, 68, 50, 14)
	_r(102, 82, 50, 18)
	_r(96, 76, 6, 24)
	_r(152, 76, 6, 24)
	_c(Vector2(182, 91), 8.0)
	_c(Vector2(218, 91), 8.0)
	_l([Vector2(182, 91), Vector2(194, 77), Vector2(210, 77), Vector2(218, 91)])
	_f(196, 72, 13, 5, INK)  # el tanque
	_l([Vector2(186, 74), Vector2(196, 74)], INK, 2.0)  # el sillín
	_r(195, 80, 10, 8)  # el motor
	_l([Vector2(195, 90), Vector2(174, 90)], DIM, 2.0)  # el exosto
	_l([Vector2(210, 77), Vector2(214, 64), Vector2(208, 62)])
	_d(Vector2(216, 70), 2.0, GOLD)  # la farola
	_r(236, 93, 26, 7, GOLD)
	_l([Vector2(238, 91), Vector2(260, 91)], RED, 2.0)
	_l([Vector2(238, 88), Vector2(260, 88)], BLUE, 2.0)
	_r(242, 80, 11, 6)
	_r(253, 77, 6, 6)
	_l([Vector2(254, 77), Vector2(252, 83)])


## La estación. Ella sale, con copia.
func _page_1() -> void:
	_l([Vector2(56, 100), Vector2(266, 100)], DIM)
	_r(96, 40, 128, 60)
	_r(128, 26, 64, 14, BLUE)
	_txt(132, 37, "POLICIA", BLUE)
	_r(108, 52, 16, 14, DIM)
	_r(196, 52, 16, 14, DIM)
	_r(150, 68, 20, 32)
	_c(Vector2(72, 26), 10.0, GOLD)
	_l([Vector2(72, 26), Vector2(72, 19)], GOLD)
	_l([Vector2(72, 26), Vector2(68, 31)], GOLD)
	_txt(52, 52, "17:30", GOLD)
	_person(240, 100, INK, true)
	_r(247, 82, 7, 9, GOLD)


## La denuncia.
func _page_2() -> void:
	_r(110, 12, 100, 96)
	_txt(128, 26, "DENUNCIA")
	_l([Vector2(120, 32), Vector2(200, 32)], DIM)
	_txt(120, 46, "ABORTO")
	_l([Vector2(120, 54), Vector2(200, 54)], DIM)
	_l([Vector2(120, 61), Vector2(190, 61)], DIM)
	_l([Vector2(120, 68), Vector2(196, 68)], DIM)
	_r(116, 76, 88, 26, RED)
	_txt(128, 88, "ARMADO Y", RED)
	_txt(124, 98, "PELIGROSO", RED)


## Lorena, por teléfono: la dirección, la foto... y un arma que no hay.
func _page_3() -> void:
	_r(72, 22, 44, 80)
	_r(76, 30, 36, 56, DIM)
	_c(Vector2(94, 50), 6.0)
	_l([Vector2(82, 78), Vector2(84, 62), Vector2(104, 62), Vector2(106, 78)])
	_c(Vector2(94, 94), 3.0, DIM)
	for k in 3:
		_c(Vector2(118, 58), 10.0 + k * 8.0, DIM, -0.7, 0.7)
	_c(Vector2(176, 46), 8.0, GOLD)
	_d(Vector2(176, 46), 2.5, GOLD)
	_l([Vector2(169, 51), Vector2(176, 68), Vector2(183, 51)], GOLD)
	_l([Vector2(200, 58), Vector2(210, 58)], RED, 2.0)
	_l([Vector2(205, 53), Vector2(205, 63)], RED, 2.0)
	_l([Vector2(222, 48), Vector2(260, 48), Vector2(260, 57), Vector2(238, 57), Vector2(236, 72),
		Vector2(224, 72), Vector2(226, 57), Vector2(222, 57), Vector2(222, 48)], RED)
	_c(Vector2(243, 61), 4.0, RED, 0.0, PI)
	_txt(224, 90, "¿...?", RED)


## Lo único cierto: la dirección.
func _page_4() -> void:
	_l([Vector2(56, 104), Vector2(266, 104)], DIM)
	_door(135, 28, "302", GOLD)
	_l([Vector2(128, 107), Vector2(192, 107)], DIM, 2.0)
	_c(Vector2(98, 44), 9.0, RED)
	_d(Vector2(98, 44), 3.0, RED)
	_l([Vector2(90, 49), Vector2(98, 68), Vector2(106, 49)], RED)
	_l([Vector2(110, 60), Vector2(130, 60)], RED)
	_l([Vector2(125, 56), Vector2(130, 60), Vector2(125, 64)], RED)


## 21:40. El arroz.
func _page_5() -> void:
	_r(112, 76, 96, 30)
	_c(Vector2(130, 92), 4.0, DIM)
	_c(Vector2(190, 92), 4.0, DIM)
	_r(138, 50, 44, 22)
	_l([Vector2(135, 50), Vector2(185, 50)], INK, 2.0)
	_l([Vector2(156, 46), Vector2(164, 46)])
	_l([Vector2(131, 57), Vector2(138, 57)])
	_l([Vector2(182, 57), Vector2(189, 57)])
	for k in 4:
		_l([Vector2(144 + k * 10, 76), Vector2(147 + k * 10, 72), Vector2(150 + k * 10, 76)], BLUE)
	for k in 3:
		var x := 150.0 + k * 10.0
		_l([Vector2(x, 42), Vector2(x + 3, 36), Vector2(x - 3, 30), Vector2(x + 3, 24), Vector2(x, 18)], DIM)
	_txt(60, 40, "21:40", GOLD)


## ¡POLICIA! ¡ABRA!
func _page_6() -> void:
	_blink(60, 14, 34, 94, Color(1, 0.15, 0.15, 0.22), Color(0.2, 0.35, 1.0, 0.22))
	_blink(226, 14, 34, 94, Color(0.2, 0.35, 1.0, 0.22), Color(1, 0.15, 0.15, 0.22))
	_door(135, 28, "302", GOLD)
	_blink(131, 105, 58, 3, RED, BLUE)
	for k in 8:
		var dir := Vector2.RIGHT.rotated(TAU * k / 8.0 + 0.2)
		_l([Vector2(160, 70) + dir * 6.0, Vector2(160, 70) + dir * 15.0], RED, 2.0)
	for k in 6:
		var dir := Vector2.RIGHT.rotated(TAU * k / 6.0)
		_l([Vector2(148, 90) + dir * 4.0, Vector2(148, 90) + dir * 9.0], RED)


## Tiene un cucharón.
func _page_7() -> void:
	_r(108, 10, 16, 13)
	_l([Vector2(108, 14), Vector2(124, 14)], DIM)
	_l([Vector2(108, 18), Vector2(124, 18)], DIM)
	_l([Vector2(120, 20), Vector2(170, 80)], INK, 2.0)
	_l([Vector2(160, 82), Vector2(190, 82)])
	_c(Vector2(175, 82), 15.0, INK, 0.0, PI)
	_txt(204, 50, "¿ARMA?", RED)
	_l([Vector2(214, 56), Vector2(196, 72)], RED)
	_l([Vector2(196, 65), Vector2(196, 72), Vector2(203, 72)], RED)


## El vecino del 301.
func _page_8() -> void:
	_l([Vector2(56, 106), Vector2(266, 106)], DIM)
	_door(78, 30, "301", DIM)
	_door(196, 30, "302", GOLD)
	_c(Vector2(138, 54), 6.0)
	_l([Vector2(134, 60), Vector2(134, 84)])
	_l([Vector2(136, 64), Vector2(176, 60)], INK, 2.0)
	_l([Vector2(176, 60), Vector2(186, 59)])
	for k in 3:
		_l([Vector2(148 + k * 7, 44), Vector2(152 + k * 7, 38)], RED)


## El primer tiro, por la ventana. El arroz se quema solo.
func _page_9() -> void:
	_blink(112, 22, 116, 72, Color(1, 0.15, 0.15, 0.14), Color(0.2, 0.35, 1.0, 0.14))
	_r(110, 20, 120, 76)
	_l([Vector2(170, 20), Vector2(170, 96)], DIM)
	_l([Vector2(110, 58), Vector2(230, 58)], DIM)
	_l([Vector2(272, 26), Vector2(192, 44)], GOLD, 2.0)
	_d(Vector2(192, 44), 3.0)
	for k in 7:
		var dir := Vector2.RIGHT.rotated(TAU * k / 7.0 + 0.4)
		_l([Vector2(192, 44) + dir * 4.0, Vector2(192, 44) + dir * 11.0, Vector2(192, 44) + dir.rotated(0.35) * 19.0])
	_l([Vector2(184, 46), Vector2(150, 54)], GOLD)
	_l([Vector2(142, 56), Vector2(122, 61)], GOLD)
	_r(62, 92, 26, 14)
	_l([Vector2(59, 92), Vector2(91, 92)], INK, 2.0)
	for k in 3:
		var x := 68.0 + k * 7.0
		_l([Vector2(x, 86), Vector2(x + 3, 78), Vector2(x - 3, 70), Vector2(x + 3, 62), Vector2(x, 54)], DIM)


## La mochila. La foto. El perro. La ventana de atrás. En ese orden.
func _page_10() -> void:
	var xs := [76.0, 130.0, 184.0, 238.0]
	# 1: la mochila
	_r(xs[0] - 12, 48, 24, 30)
	_c(Vector2(xs[0], 48), 7.0, INK, PI, TAU)
	_l([Vector2(xs[0] - 12, 58), Vector2(xs[0] + 12, 58)])
	_r(xs[0] - 6, 63, 12, 9, DIM)
	_txt(xs[0] - 4, 98, "1", GOLD)
	# 2: la foto
	_r(xs[1] - 12, 46, 24, 32, GOLD)
	_r(xs[1] - 9, 49, 18, 19, DIM)
	_c(Vector2(xs[1] - 3, 56), 2.5)
	_c(Vector2(xs[1] + 4, 59), 1.8)
	_txt(xs[1] - 4, 98, "2", GOLD)
	# 3: el perro
	_r(xs[2] - 13, 60, 20, 10)
	_r(xs[2] + 5, 52, 10, 9)
	_l([Vector2(xs[2] + 7, 52), Vector2(xs[2] + 5, 60)])
	_l([Vector2(xs[2] - 13, 60), Vector2(xs[2] - 17, 52)])
	_l([Vector2(xs[2] - 10, 70), Vector2(xs[2] - 10, 78)])
	_l([Vector2(xs[2] + 4, 70), Vector2(xs[2] + 4, 78)])
	_txt(xs[2] - 4, 98, "3", GOLD)
	# 4: la ventana de atrás
	_r(xs[3] - 13, 42, 26, 36)
	_l([Vector2(xs[3], 42), Vector2(xs[3], 78)], DIM)
	_l([Vector2(xs[3] + 2, 60), Vector2(xs[3] + 24, 60)], RED, 2.0)
	_l([Vector2(xs[3] + 19, 55), Vector2(xs[3] + 24, 60), Vector2(xs[3] + 19, 65)], RED, 2.0)
	_txt(xs[3] - 4, 98, "4", GOLD)
	for k in 3:
		_l([Vector2(xs[k] + 19, 62), Vector2(xs[k + 1] - 21, 62)], DIM)
