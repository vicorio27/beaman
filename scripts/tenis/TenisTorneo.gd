extends Node2D
## El torneo (Highway to Hell) de principio a fin, suelto (fuera de la historia): se escoge con quién
## jugar, se ve el cuadro, se juegan los partidos propios, los de los demás se ven o se simulan, y al
## final el campeón. En la historia, el torneo se vive de recogebolas: TenisJornada.gd.
## El cuadro es TenisBracket (dibujado por TenisCuadro); los partidos, TenisMatch. Se guarda en
## TenisTorneo.saved (to_dict).
## Controles en el cuadro: E jugar o ver el próximo partido; X simular todo hasta el próximo partido
## propio (o hasta el final, si ya lo sacaron); en el final, E otra vez.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const MATCH := preload("res://scenes/tenis/TenisMatch.tscn")

static var saved := {}  # {"you": id, "bracket": dict, "seed": n}

var you := ""
var bracket: TenisBracket
var _seed := 1
var _hud: CanvasLayer
var _labels: Array = []
var _match: Node = null
var _cuadro: TenisCuadro


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	MusicDirector.force("tenis_cuadro")
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
	l.text = TenisData.caps(Controls.keys_in(text))  # en el celular, "E" es "A"
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


# ---------------------------------------------------------------- El cuadro

func _show_bracket() -> void:
	_clear()
	if _cuadro == null:
		_cuadro = TenisCuadro.new()
		add_child(_cuadro)
	_cuadro.visible = true
	_cuadro.bracket = bracket
	_cuadro.you = you
	_cuadro.refresh()
	var cr := bracket.current_round()
	var day := cr + 1 if cr >= 0 else bracket.rounds.size()
	var title := "%s — DÍA %d: %s" % [TenisData.TOURNAMENT["name"].to_upper(), day,
		bracket.rounds[maxi(cr, 0)]["name"].to_upper() if cr >= 0 else "FINAL"]
	_label(Vector2(0, 6), title, Color(1, 0.9, 0.5), true)
	# Abajo: el próximo partido y qué se puede hacer.
	var m := bracket.next_match()
	if m.is_empty():
		var champ := bracket.champion()
		var c: Dictionary = TenisData.player(champ)
		_label(Vector2(0, 150), "¡%s, CAMPEÓN!" % c["name"].to_upper(), Color(1, 0.85, 0.3), true)
		var pz: int = TenisData.TOURNAMENT["prize"]["Campeón"]
		var mine := "" if you == champ else "  TÚ: %s" % bracket.reached(you).to_upper()
		_label(Vector2(0, 160), "BOLSA $%s%s" % [TenisData.money(pz), mine], Color(0.85, 0.9, 1.0), true)
		_label(Vector2(0, 170), "E: OTRO TORNEO", Color(0.85, 0.9, 1.0), true)
		return
	var a: Dictionary = TenisData.player(m["a"])
	var b: Dictionary = TenisData.player(m["b"])
	_label(Vector2(0, 156), TenisData.versus(a["name"], b["name"], Controls.right_edge()), Color(1, 0.95, 0.8), true)
	var hint := "E: JUGAR"
	if not you in [m["a"], m["b"]]:
		hint = "E: VER   X: HASTA TU PARTIDO" if bracket.alive(you) else "E: VER   X: HASTA EL FINAL"
	_label(Vector2(0, 168), hint, Color(0.85, 0.9, 1.0), true)


func _process(_delta: float) -> void:
	if bracket == null or _match != null:
		return
	var m := bracket.next_match()
	if m.is_empty():
		if Input.is_action_just_pressed("interact"):
			saved = {}
			get_tree().reload_current_scene()
		return
	if Input.is_action_just_pressed("interact"):
		_play(m, not you in [m["a"], m["b"]])
	elif Input.is_action_just_pressed("drop") and not you in [m["a"], m["b"]]:
		bracket.simulate_until(you, _seed)
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
		"difficulty": "dificil" if watch else "normal", "seed": TenisBracket.match_seed(m, _seed),
		"ai0": watch, "auto_close": 5.0 if watch else 0.0}
	_clear()
	_cuadro.visible = false
	_match = MATCH.instantiate()
	add_child(_match)
	_match.closed.connect(func(w: int) -> void:
		var sim: TenisSim = _match.sim
		bracket.report(m, sim.players[w].id, TenisBracket.score_text(sim.score, w))
		_save()
		_match.queue_free()
		_match = null
		MusicDirector.force("tenis_cuadro")
		_show_bracket())
