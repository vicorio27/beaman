extends Node2D
## El torneo (Highway to Hell) de principio a fin: se escoge con quién jugar, se ve el cuadro, se
## juegan los partidos propios, los de los demás se ven o se simulan, y al final el campeón.
## (Así se prueba el torneo solo; cómo entra él en la historia está por definir: ver docs/TENIS.md.)
## El cuadro es TenisBracket; los partidos, TenisMatch. Se guarda en TenisTorneo.saved (to_dict).
## Controles en el cuadro: E jugar o ver el próximo partido; X simularlo; en el final, E otra vez.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const BG := preload("res://assets/tenis/coliseo.png")
const MATCH := preload("res://scenes/tenis/TenisMatch.tscn")
const BOX := Vector2(48, 11)
const COL_X := {"Previa": 4, "Cuartos": 66, "Semifinal": 128, "Final": 190}
const CHAMP_X := 254
const TOP := 22.0      # la primera fila del cuadro
const ROW := 14.0      # entre puesto y puesto de la primera ronda del cuadro (todo cabe encima del texto de abajo)

static var saved := {}  # {"you": id, "bracket": dict, "seed": n}

var you := ""
var bracket: TenisBracket
var _seed := 1
var _hud: CanvasLayer
var _labels: Array = []
var _match: Node = null
var _blink := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	MusicDirector.force("")
	if not saved.is_empty():
		you = saved["you"]
		_seed = int(saved.get("seed", 1))
		bracket = TenisBracket.from_dict(saved["bracket"])
		_show_bracket()
		return
	var picker := TenisPicker.new()
	picker.titles = ["¿CON QUIÉN JUEGAS EL TORNEO?"]
	picker.picked.connect(func(ids: Array) -> void:
		picker.queue_free()
		you = ids[0]
		_seed = Time.get_ticks_msec()
		bracket = TenisBracket.new(TenisData.TOURNAMENT["entrants"])
		_save()
		_show_bracket())
	add_child(picker)


func _save() -> void:
	saved = {"you": you, "bracket": bracket.to_dict(), "seed": _seed}


func _label(at: Vector2, text: String, col: Color, centered := false) -> Label:
	var l := Label.new()
	l.position = at
	l.text = TenisData.caps(text)
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	if centered:
		l.size = Vector2(Controls.right_edge(), 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(l)
	_labels.append(l)
	return l


func _clear() -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()


# ---------------------------------------------------------------- Dónde va cada puesto

## La y de un puesto: los de la primera ronda del cuadro, uno debajo del otro; los de las rondas que
## siguen, en el medio de los dos que los alimentan; los de la previa, pegados al puesto que deciden.
func _slot_y(r: int, slot: int, side: int) -> float:
	var first := 1 if bracket.has_playins() else 0
	if r == 0 and bracket.has_playins():
		var feed := _fed_slot(slot)  # [partido de cuartos, lado]
		var y := _slot_y(first, feed[0], feed[1])
		return y - 6.0 + side * 12.0
	var level := r - first
	var span := ROW * pow(2.0, level)              # lo que ocupa cada puesto de esta ronda
	return TOP + (slot * 2 + side) * span + (span - ROW) * 0.5


## El puesto de cuartos que decide un partido de la previa.
func _fed_slot(pre_slot: int) -> Array:
	for q in bracket.rounds[1]["matches"]:
		if q.get("feed_a", -1) == pre_slot:
			return [q["slot"], 0]
		if q.get("feed_b", -1) == pre_slot:
			return [q["slot"], 1]
	return [0, 0]


func _box_at(r: int, slot: int, side: int) -> Vector2:
	return Vector2(COL_X[bracket.rounds[r]["name"]], _slot_y(r, slot, side))


# ---------------------------------------------------------------- El cuadro

func _show_bracket() -> void:
	_clear()
	var cr := bracket.current_round()
	var day := cr + 1 if cr >= 0 else bracket.rounds.size()
	var title := "%s — DÍA %d: %s" % [TenisData.TOURNAMENT["name"].to_upper(), day,
		bracket.rounds[maxi(cr, 0)]["name"].to_upper() if cr >= 0 else "FINAL"]
	_label(Vector2(0, 6), title, Color(1, 0.9, 0.5), true)
	for r in bracket.rounds.size():
		for m in bracket.rounds[r]["matches"]:
			for side in 2:
				var id: String = m["a" if side == 0 else "b"]
				if id == "":
					continue
				var at := _box_at(r, m["slot"], side) + Vector2(3, 2)
				var col := _name_color(id, m)
				_label(at, TenisData.player(id)["short"], col)
				if m["winner"] == id and m["score"] != "":  # el marcador, al lado del que ganó
					_label(at + Vector2(27, 0), str(m["score"]).split(" ")[0], Color(0.75, 0.78, 0.86))
	var champ := bracket.champion()
	if champ != "":
		var y := _slot_y(bracket.rounds.size() - 1, 0, 0) + ROW * 0.5
		_label(Vector2(CHAMP_X + 3, y - 3), TenisData.player(champ)["short"], Color(1, 0.85, 0.3))
	# Abajo: el próximo partido y qué se puede hacer.
	var m := bracket.next_match()
	if m.is_empty():
		var c: Dictionary = TenisData.player(champ)
		_label(Vector2(0, 150), "¡%s, CAMPEÓN!" % c["name"].to_upper(), Color(1, 0.85, 0.3), true)
		var pz: int = TenisData.TOURNAMENT["prize"]["Campeón"]
		var mine := "" if you == champ else "  TÚ: %s" % bracket.reached(you).to_upper()
		_label(Vector2(0, 160), "BOLSA $%s%s" % [_money(pz), mine], Color(0.85, 0.9, 1.0), true)
		_label(Vector2(0, 170), "E: OTRO TORNEO", Color(0.85, 0.9, 1.0), true)
		return
	var a: Dictionary = TenisData.player(m["a"])
	var b: Dictionary = TenisData.player(m["b"])
	_label(Vector2(0, 156), "%s  VS  %s" % [a["name"].to_upper(), b["name"].to_upper()], Color(1, 0.95, 0.8), true)
	var mine2: bool = you in [m["a"], m["b"]]
	_label(Vector2(0, 168), "E: JUGAR" if mine2 else "E: VER   X: SIMULAR", Color(0.85, 0.9, 1.0), true)


func _name_color(id: String, m: Dictionary) -> Color:
	if m["winner"] != "" and m["winner"] != id:
		return Color(0.42, 0.42, 0.5)                         # el que perdió, apagado
	var c: Color = TenisData.player(id)["color"]
	return c.lightened(0.25)


func _money(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func _process(delta: float) -> void:
	_blink += delta
	if bracket == null or _match != null:
		return
	queue_redraw()
	var m := bracket.next_match()
	if m.is_empty():
		if Input.is_action_just_pressed("interact"):
			saved = {}
			get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("interact"):
		_play(m, not you in [m["a"], m["b"]])
	elif Input.is_action_just_pressed("drop") and not you in [m["a"], m["b"]]:
		bracket.simulate(m, _seed + bracket.current_round() * 10 + int(m["slot"]))
		_save()
		_show_bracket()


## Un partido en la cancha: el propio (uno abajo, contra la máquina) o el de otros (máquina contra
## máquina, para verlo). Al cerrar el resumen, se anota y se vuelve al cuadro.
func _play(m: Dictionary, watch: bool) -> void:
	var rname: String = bracket.rounds[m["round"]]["name"]
	var mine_a: bool = m["a"] == you
	var p0: String = m["a"] if (watch or mine_a) else m["b"]
	var p1: String = m["b"] if p0 == m["a"] else m["a"]
	var TM = load("res://scripts/tenis/TenisMatch.gd")
	TM.setup = {"p0": p0, "p1": p1, "format": TenisData.TOURNAMENT["format"].get(rname, "arcade"),
		"difficulty": "dificil" if watch else "normal", "seed": _seed + m["round"] * 10 + int(m["slot"]),
		"ai0": watch, "auto_close": 5.0 if watch else 0.0}
	_clear()
	_match = MATCH.instantiate()
	add_child(_match)
	queue_redraw()
	_match.closed.connect(func(w: int) -> void:
		var sim: TenisSim = _match.sim
		bracket.report(m, sim.players[w].id, TenisBracket.score_text(sim.score, w))
		_save()
		_match.queue_free()
		_match = null
		_show_bracket())


func _draw() -> void:
	if bracket == null or _match != null:
		return
	draw_texture(BG, Vector2.ZERO)
	draw_rect(Rect2(0, 0, 320, 180), Color(0.04, 0.04, 0.08, 0.8))
	var nxt := bracket.next_match()
	var line := Color(0.5, 0.48, 0.56)
	for r in bracket.rounds.size():
		for m in bracket.rounds[r]["matches"]:
			var is_next: bool = not nxt.is_empty() and nxt["round"] == r and nxt["slot"] == m["slot"]
			for side in 2:
				var at := _box_at(r, m["slot"], side)
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
			var a := _box_at(r, m["slot"], 0)
			var b := _box_at(r, m["slot"], 1)
			var mid_y := (a.y + b.y) * 0.5 + BOX.y * 0.5
			var x0 := a.x + BOX.x
			var target := Vector2.ZERO
			if r == 0 and bracket.has_playins():
				var f := _fed_slot(m["slot"])
				target = _box_at(1, f[0], f[1]) + Vector2(0, BOX.y * 0.5)
			elif r + 1 < bracket.rounds.size():
				target = _box_at(r + 1, int(m["slot"]) / 2, int(m["slot"]) % 2) + Vector2(0, BOX.y * 0.5)
			else:
				target = Vector2(CHAMP_X, mid_y)
			draw_line(Vector2(x0, a.y + BOX.y * 0.5), Vector2(x0 + 4, a.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0, b.y + BOX.y * 0.5), Vector2(x0 + 4, b.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0 + 4, a.y + BOX.y * 0.5), Vector2(x0 + 4, b.y + BOX.y * 0.5), line, 1.0)
			draw_line(Vector2(x0 + 4, mid_y), Vector2(target.x - 4, mid_y), line, 1.0)
			draw_line(Vector2(target.x - 4, mid_y), Vector2(target.x - 4, target.y), line, 1.0)
			draw_line(Vector2(target.x - 4, target.y), Vector2(target.x, target.y), line, 1.0)
	# El puesto del campeón: la copa.
	var cy := _slot_y(bracket.rounds.size() - 1, 0, 0) + ROW * 0.5 - BOX.y * 0.5
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
