class_name TenisCuadro
extends Node2D
## El dibujo del cuadro del torneo (TenisBracket): el coliseo apagado de fondo, un recuadro por puesto
## con el nombre corto, las líneas hacia el puesto que decide cada partido, el marcador al lado del
## que ganó y la copa del campeón. El de "you" va en dorado; el que perdió, apagado; el partido
## "mark" (o, si no hay, el próximo) titila. Lo usan TenisTorneo (el torneo suelto) y TenisJornada
## (el día de trabajo en la historia). Lo de arriba (el título) y lo de abajo (y = 150 en adelante) lo
## pone cada uno: el cuadro cabe entre y = 22 y y = 148.
##   var c := TenisCuadro.new(); c.bracket = b; c.you = "fedorer"; add_child(c); c.refresh()

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const BG := preload("res://assets/tenis/coliseo.png")
const BOX := Vector2(48, 11)
const COL_X := {"Previa": 4, "Cuartos": 66, "Semifinal": 128, "Final": 190}
const CHAMP_X := 254
const TOP := 22.0      # la primera fila del cuadro
const ROW := 14.0      # entre puesto y puesto de la primera ronda del cuadro (todo cabe encima del texto de abajo)

var bracket: TenisBracket
var you := ""
var mark := {}         # {"round", "slot"}: el partido que titila (vacío: el próximo)
var _labels: Array = []
var _blink := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_blink += delta
	queue_redraw()


func _label(at: Vector2, text: String, col: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.text = TenisData.caps(text)
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	add_child(l)
	_labels.append(l)
	return l


## Vuelve a poner los nombres y los marcadores (después de anotar un resultado).
func refresh() -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()
	if bracket == null:
		return
	for r in bracket.rounds.size():
		for m in bracket.rounds[r]["matches"]:
			for side in 2:
				var id: String = m["a" if side == 0 else "b"]
				if id == "":
					continue
				var at := box_at(r, m["slot"], side) + Vector2(3, 2)
				_label(at, TenisData.player(id)["short"], _name_color(id, m))
				if m["winner"] == id and m["score"] != "":  # el marcador, al lado del que ganó
					_label(at + Vector2(27, 0), str(m["score"]).split(" ")[0], Color(0.75, 0.78, 0.86))
	var champ := bracket.champion()
	if champ != "":
		var y := slot_y(bracket.rounds.size() - 1, 0, 0) + ROW * 0.5
		_label(Vector2(CHAMP_X + 3, y - 3), TenisData.player(champ)["short"], Color(1, 0.85, 0.3))
	queue_redraw()


func _name_color(id: String, m: Dictionary) -> Color:
	if m["winner"] != "" and m["winner"] != id:
		return Color(0.42, 0.42, 0.5)                         # el que perdió, apagado
	var c: Color = TenisData.player(id)["color"]
	return c.lightened(0.25)


# ---------------------------------------------------------------- Dónde va cada puesto

## La y de un puesto: los de la primera ronda del cuadro, uno debajo del otro; los de las rondas que
## siguen, en el medio de los dos que los alimentan; los de la previa, pegados al puesto que deciden.
func slot_y(r: int, slot: int, side: int) -> float:
	var first := 1 if bracket.has_playins() else 0
	if r == 0 and bracket.has_playins():
		var feed := fed_slot(slot)  # [partido de cuartos, lado]
		var y := slot_y(first, feed[0], feed[1])
		return y - 6.0 + side * 12.0
	var level := r - first
	var span := ROW * pow(2.0, level)              # lo que ocupa cada puesto de esta ronda
	return TOP + (slot * 2 + side) * span + (span - ROW) * 0.5


## El puesto de cuartos que decide un partido de la previa.
func fed_slot(pre_slot: int) -> Array:
	for q in bracket.rounds[1]["matches"]:
		if q.get("feed_a", -1) == pre_slot:
			return [q["slot"], 0]
		if q.get("feed_b", -1) == pre_slot:
			return [q["slot"], 1]
	return [0, 0]


func box_at(r: int, slot: int, side: int) -> Vector2:
	return Vector2(COL_X[bracket.rounds[r]["name"]], slot_y(r, slot, side))


# ---------------------------------------------------------------- Dibujar

func _draw() -> void:
	if bracket == null:
		return
	draw_texture(BG, Vector2.ZERO)
	draw_rect(Rect2(0, 0, 320, 180), Color(0.04, 0.04, 0.08, 0.8))
	var nxt := mark if not mark.is_empty() else bracket.next_match()
	var line := Color(0.5, 0.48, 0.56)
	for r in bracket.rounds.size():
		for m in bracket.rounds[r]["matches"]:
			var is_next: bool = not nxt.is_empty() and int(nxt["round"]) == r and int(nxt["slot"]) == int(m["slot"])
			for side in 2:
				var at := box_at(r, m["slot"], side)
				var id: String = m["a" if side == 0 else "b"]
				var fill := Color(0.1, 0.1, 0.15, 0.95)
				if id == you and id != "":
					fill = Color(0.22, 0.18, 0.08, 0.95)            # el tuyo, dorado oscuro
				draw_rect(Rect2(at, BOX), fill)
				var edge := line
				if is_next and fmod(_blink, 0.8) < 0.5:
					edge = Color(1, 0.85, 0.3)                      # el que sigue, titilando
				draw_rect(Rect2(at, BOX), edge, false, 1.0)
			# La línea hacia el puesto que decide este partido.
			var a := box_at(r, m["slot"], 0)
			var b := box_at(r, m["slot"], 1)
			var mid_y := (a.y + b.y) * 0.5 + BOX.y * 0.5
			var x0 := a.x + BOX.x
			var target := Vector2.ZERO
			if r == 0 and bracket.has_playins():
				var f := fed_slot(m["slot"])
				target = box_at(1, f[0], f[1]) + Vector2(0, BOX.y * 0.5)
			elif r + 1 < bracket.rounds.size():
				target = box_at(r + 1, int(m["slot"]) / 2, int(m["slot"]) % 2) + Vector2(0, BOX.y * 0.5)
			else:
				target = Vector2(CHAMP_X, mid_y)
			draw_line(Vector2(x0, a.y + BOX.y * 0.5), Vector2(x0 + 4, a.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0, b.y + BOX.y * 0.5), Vector2(x0 + 4, b.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0 + 4, a.y + BOX.y * 0.5), Vector2(x0 + 4, b.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0 + 4, mid_y), Vector2(target.x - 4, mid_y), line, 1.0)
			draw_line(Vector2(target.x - 4, mid_y), Vector2(target.x - 4, target.y), line, 1.0)
			draw_line(Vector2(target.x - 4, target.y), Vector2(target.x, target.y), line, 1.0)
	# El puesto del campeón: la copa.
	var cy := slot_y(bracket.rounds.size() - 1, 0, 0) + ROW * 0.5 - BOX.y * 0.5
	draw_rect(Rect2(Vector2(CHAMP_X, cy), Vector2(40, BOX.y)), Color(0.22, 0.18, 0.08, 0.95))
	draw_rect(Rect2(Vector2(CHAMP_X, cy), Vector2(40, BOX.y)), Color(1, 0.85, 0.3), false, 1.0)
	_cup(Vector2(CHAMP_X + 46, cy - 4))


## La copita del campeón, a mano.
func _cup(at: Vector2) -> void:
	var gold := Color(1, 0.82, 0.3)
	var dark := Color(0.7, 0.5, 0.15)
	draw_rect(Rect2(at + Vector2(1, 0), Vector2(9, 6)), gold)
	draw_rect(Rect2(at + Vector2(2, 6), Vector2(7, 2)), gold)
	draw_rect(Rect2(at + Vector2(4, 8), Vector2(3, 3)), dark)
	draw_rect(Rect2(at + Vector2(2, 11), Vector2(7, 2)), gold)
	draw_rect(Rect2(at + Vector2(-1, 1), Vector2(2, 3)), gold)
	draw_rect(Rect2(at + Vector2(10, 1), Vector2(2, 3)), gold)
	draw_rect(Rect2(at + Vector2(3, 1), Vector2(1, 3)), Color(1, 0.95, 0.7))
