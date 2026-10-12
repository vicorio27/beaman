extends Location
## BILLAR EL GUAYABO, por dentro. Solo de noche, y solo si el guardia de la puerta lo deja pasar
## (Conversations._billar_guardia: con Lukas hay que pagarle o hacerle un favor).
## Un sitio de mala muerte: una tarima con dos tubos y luces de colores, una barra con seis botellas
## de lo mismo, dos mesas de billar, un borracho. Todo dibujado por código.
##   noche_billar     el de las mesas: apostar una mesa (la misma apuesta de antes)
##   billar_barra     el de la barra: una cerveza
##   billar_baila     las de la tarima
##   billar_borracho  el de la mesa del rincón
## Son los vicios de él: los pelea y los quiere (vicio_si / vicio_no). Aquí no hay jíbaro: ese es de la calle.

const WALL_H := 40.0
const STAGE := Rect2(104, 40, 112, 30)
const BAR := Rect2(8, 44, 70, 14)
const TABLES := [Rect2(214, 86, 78, 34), Rect2(214, 138, 78, 34)]
const CORNER_TABLE := Rect2(26, 128, 30, 18)
## [npc_id, fila, posición, mira]
const PEOPLE := [
	["billar_barra", 9, Vector2(40, 46), "down"],
	["noche_billar", 6, Vector2(200, 112), "right"],
	["billar_borracho", 15, Vector2(40, 124), "down"],
]

var _t := 0.0
var _dancers: Array = []


func _ready() -> void:
	y_sort_enabled = true
	super._ready()
	for r in [Rect2(0, 0, 320, WALL_H), STAGE, BAR, TABLES[0], TABLES[1], CORNER_TABLE]:
		_solid(r)
	for spec in PEOPLE:
		_person(spec)
	# Las de la tarima: bailan arriba; se les habla desde abajo.
	for k in 2:
		var d := _person(["billar_baila", 3 if k == 0 else 12, Vector2(STAGE.position.x + 30 + k * 52, STAGE.end.y - 6), "down"])
		d.talk_reach = Vector2(30, 60)
		d.sprite.modulate = Color(1.0, 0.72, 0.9)  # la luz de la tarima
		_dancers.append(d)
	MusicDirector.force("bakery")  # boleros de despecho, en una radio vieja


func _solid(r: Rect2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	body.add_child(shape)
	add_child(body)


func _person(spec: Array) -> CharacterBody2D:
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = str(spec[0]).capitalize().replace(" ", "") + str(get_child_count())
	npc.npc_id = spec[0]
	npc.sheet_row = spec[1]
	npc.position = spec[2]
	npc.face = spec[3]
	add_child(npc)
	return npc


func _process(delta: float) -> void:
	_t += delta
	for k in _dancers.size():  # le dan la vuelta al tubo
		var d: Node2D = _dancers[k]
		if is_instance_valid(d) and d.get("sprite") != null and not d.talking:
			d.sprite.position.x = sin(_t * 3.0 + k * PI) * 4.0
			d.sprite.flip_h = cos(_t * 3.0 + k * PI) < 0.0
	queue_redraw()


func _draw() -> void:
	# El piso: baldosa de dos colores, pegajosa.
	draw_rect(Rect2(0, 0, 320, 192), Color(0.13, 0.09, 0.11))
	for y in range(int(WALL_H), 192, 16):
		for x in range(0, 320, 16):
			if (x / 16 + y / 16) % 2 == 0:
				draw_rect(Rect2(x, y, 16, 16), Color(0.17, 0.11, 0.13))
	for k in 7:  # manchas
		var h := hash(k * 13)
		draw_circle(Vector2(20 + h % 280, 70 + (h / 9) % 110), 3.0 + h % 3, Color(0.09, 0.06, 0.08, 0.6))
	# La pared: papel de colgadura vinotinto, y un zócalo.
	draw_rect(Rect2(0, 0, 320, WALL_H), Color(0.3, 0.09, 0.14))
	for x in range(6, 320, 12):
		draw_rect(Rect2(x, 4, 2, WALL_H - 10), Color(0.36, 0.12, 0.17))
	draw_rect(Rect2(0, WALL_H - 5, 320, 5), Color(0.14, 0.07, 0.09))
	# Cuadros torcidos: un caballo, una virgen, un almanaque de 2009.
	for spec in [[20, 0.06, Color(0.5, 0.4, 0.3)], [250, -0.08, Color(0.3, 0.4, 0.55)], [290, 0.04, Color(0.8, 0.75, 0.6)]]:
		draw_set_transform(Vector2(spec[0], 12), spec[1])
		draw_rect(Rect2(-8, -6, 16, 14), Color(0.55, 0.42, 0.2))
		draw_rect(Rect2(-6, -4, 12, 10), spec[2])
	draw_set_transform(Vector2.ZERO)
	# La barra: el mostrador, y atrás la repisa con seis botellas de lo mismo.
	for k in 6:
		draw_rect(Rect2(14 + k * 10, 22, 4, 11), [Color(0.3, 0.6, 0.35), Color(0.7, 0.55, 0.2), Color(0.5, 0.3, 0.2)][k % 3])
		draw_rect(Rect2(15 + k * 10, 19, 2, 3), Color(0.8, 0.8, 0.8))
	draw_rect(Rect2(10, 33, 64, 2), Color(0.4, 0.26, 0.14))
	draw_rect(BAR, Color(0.42, 0.26, 0.14))
	draw_rect(Rect2(BAR.position, Vector2(BAR.size.x, 3)), Color(0.58, 0.38, 0.2))
	# La tarima: madera, dos tubos y un borde de bombillos (la mitad fundidos).
	draw_rect(STAGE, Color(0.24, 0.14, 0.2))
	draw_rect(Rect2(STAGE.position.x, STAGE.end.y - 4, STAGE.size.x, 4), Color(0.16, 0.09, 0.14))
	for k in 14:
		var on := (k + int(_t * 4.0)) % 3 != 0 and k != 5 and k != 9
		draw_rect(Rect2(STAGE.position.x + 3 + k * 8, STAGE.end.y - 3, 2, 2), Color(1.0, 0.9, 0.5) if on else Color(0.3, 0.25, 0.2))
	for k in 2:
		var px := STAGE.position.x + 30 + k * 52
		draw_rect(Rect2(px - 1, 6, 2, STAGE.end.y - 12), Color(0.8, 0.8, 0.85))
	# Las luces de colores: tres conos que cambian.
	var cols := [Color(1.0, 0.2, 0.6), Color(0.3, 0.5, 1.0), Color(1.0, 0.8, 0.2)]
	for k in 3:
		var c: Color = cols[(k + int(_t * 1.5)) % 3]
		var cx := STAGE.position.x + 20 + k * 36 + sin(_t * 1.3 + k) * 8.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 2, 0), Vector2(cx + 2, 0), Vector2(cx + 18, STAGE.end.y), Vector2(cx - 18, STAGE.end.y)]),
			Color(c.r, c.g, c.b, 0.16))
	# Las mesas de billar: paño verde, seis troneras, las bolas donde quedaron.
	for i in TABLES.size():
		var r: Rect2 = TABLES[i]
		draw_rect(Rect2(r.position + Vector2(2, r.size.y), Vector2(r.size.x - 4, 5)), Color(0.08, 0.05, 0.06, 0.6))
		draw_rect(r, Color(0.36, 0.22, 0.12))
		draw_rect(r.grow(-4), Color(0.12, 0.42, 0.26))
		for cx in [r.position.x + 4, r.get_center().x, r.end.x - 4]:
			for cy in [r.position.y + 4, r.end.y - 4]:
				draw_circle(Vector2(cx, cy), 2.0, Color(0.03, 0.03, 0.03))
		for k in 5:
			var h := hash(i * 31 + k * 7)
			draw_circle(r.position + Vector2(12 + h % 54, 9 + (h / 5) % 16), 1.6,
				[Color.WHITE, Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.3, 0.8), Color(0.05, 0.05, 0.05)][k])
		draw_rect(Rect2(r.get_center().x - 12, r.position.y - 22, 24, 5), Color(0.2, 0.5, 0.3))  # la lámpara
		draw_colored_polygon(PackedVector2Array([Vector2(r.get_center().x - 10, r.position.y - 17), Vector2(r.get_center().x + 10, r.position.y - 17),
			Vector2(r.end.x - 6, r.end.y - 4), Vector2(r.position.x + 6, r.end.y - 4)]), Color(1.0, 0.95, 0.7, 0.07))
	# La mesa del rincón: una botella, tres vasos, ninguno de él.
	draw_rect(CORNER_TABLE, Color(0.36, 0.24, 0.14))
	draw_rect(Rect2(CORNER_TABLE.position + Vector2(6, 3), Vector2(3, 8)), Color(0.3, 0.6, 0.35))
	for k in 3:
		draw_rect(Rect2(CORNER_TABLE.position + Vector2(14 + k * 5, 6), Vector2(3, 4)), Color(0.8, 0.85, 0.9, 0.8))
	# La salida.
	draw_rect(Rect2(146, 186, 28, 6), Color(0.05, 0.04, 0.06))
