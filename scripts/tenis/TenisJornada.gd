extends Node2D
## EL DÍA DE TRABAJO EN EL COLISEO (la historia del torneo: scripts/systems/Torneo.gd).
##   1. El cuadro del día, con el partido donde trabaja titilando ("E: A la cancha").
##   2. El partido, de recogebolas (TenisMatch con "ballboy"): agachado al lado de la red; cuando se
##      acaba el punto, corre por la pelota y la trae. Rápido: propina.
##   3. A la mitad, el de abajo abandona a su manera (TenisHistoria.ABANDONOS) y el organizador lo
##      manda a él a terminar el partido, con la raqueta del que se fue.
##   4. Al final: lo que pasó con los otros partidos del día, la paga (sueldo, propinas y lo del
##      profesional) y de vuelta al barrio, a la entrada del coliseo.
## El que abandona lo escoge TenisHistoria.quien_abandona (cada día uno distinto, si se puede).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const MATCH := preload("res://scenes/tenis/TenisMatch.tscn")
const CITY := "res://scenes/world/City.tscn"

var st: Dictionary
var bracket: TenisBracket
var r := -1
var rname := ""
var aband := {}       # {"slot", "id"}: el que se va hoy
var m := {}           # su partido (con "round")
var _step := ""       # "cuadro", "match", "pago", "fin"
var _t := 0.0
var _hud: CanvasLayer
var _labels: Array = []
var _cuadro: TenisCuadro
var _box: Node2D
var _match: Node = null
var _paga := {}
var _gano := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_hud = CanvasLayer.new()
	_hud.layer = 5
	add_child(_hud)
	MusicDirector.force("tenis_cuadro")
	st = GameState.flags.get("torneo", {})
	r = TenisHistoria.dia_torneo(GameState.day)
	if st.is_empty() or r < 0:
		_volver("")
		return
	bracket = TenisBracket.from_dict(st["bracket"])
	# Lo que haya quedado de días anteriores (no debería), se juega sin él.
	var left := bracket.next_match()
	while not left.is_empty() and int(left["round"]) < r:
		bracket.simulate(left, TenisBracket.match_seed(left, int(st["seed"])))
		left = bracket.next_match()
	rname = bracket.rounds[r]["name"]
	aband = TenisHistoria.quien_abandona(bracket, r, st.get("usados", []), int(st["seed"]) + GameState.day)
	if aband.is_empty():
		_volver("(Hoy no hay partidos. El organizador le grita a un teléfono.)")
		return
	m = bracket.rounds[r]["matches"][int(aband["slot"])].duplicate()
	m["round"] = r
	_cuadro = TenisCuadro.new()
	add_child(_cuadro)
	_box = Node2D.new()  # el recuadro de la paga, encima del cuadro
	_box.draw.connect(_draw_box)
	add_child(_box)
	_show_cuadro()


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


func _title() -> void:
	_label(Vector2(0, 6), "%s — DÍA %d: %s" % [TenisData.TOURNAMENT["name"].to_upper(), r + 1, rname.to_upper()],
		Color(1, 0.9, 0.5), true)


# ---------------------------------------------------------------- 1. El cuadro del día

func _show_cuadro() -> void:
	_step = "cuadro"
	_t = 0.0
	_clear()
	_cuadro.visible = true
	_cuadro.bracket = bracket
	_cuadro.mark = {"round": r, "slot": int(aband["slot"])}
	_cuadro.refresh()
	_title()
	var a: Dictionary = TenisData.player(m["a"])
	var b: Dictionary = TenisData.player(m["b"])
	_label(Vector2(0, 150), "HOY RECOGE BOLAS EN:", Color(0.75, 0.78, 0.86), true)
	_label(Vector2(0, 160), "%s  VS  %s" % [a["name"].to_upper(), b["name"].to_upper()], Color(1, 0.95, 0.8), true)
	_label(Vector2(0, 170), "E: A LA CANCHA", Color(0.85, 0.9, 1.0), true)


func _process(delta: float) -> void:
	_t += delta
	if _step == "cuadro" and _t > 0.4 and Input.is_action_just_pressed("interact") and not Dialogue.active:
		_play()
	elif _step == "pago" and _t > 0.6 and Input.is_action_just_pressed("interact") and not Dialogue.active:
		_step = "fin"
		_cobrar()


# ---------------------------------------------------------------- 2 y 3. El partido

func _play() -> void:
	_step = "match"
	_clear()
	_cuadro.visible = false
	var other: String = m["b"] if m["a"] == aband["id"] else m["a"]
	var fmt: String = TenisData.TOURNAMENT["format"].get(rname, "arcade")
	var TM = load("res://scripts/tenis/TenisMatch.gd")
	TM.setup = {"p0": aband["id"], "p1": other, "format": fmt, "difficulty": "normal",
		"seed": TenisBracket.match_seed(m, int(st["seed"])), "ai0": true, "ballboy": true,
		"abandon_games": TenisHistoria.juegos_para_abandonar(fmt)}
	_match = MATCH.instantiate()
	add_child(_match)
	_match.abandon_now.connect(_on_abandon)
	_match.closed.connect(_on_closed)
	if not st.get("visto_recoger", false):
		st["visto_recoger"] = true
		await Dialogue.talk([["", "(Agachado al lado de la red. Quieto mientras juegan. Cuando se acaba el punto, con las flechas, por la pelota, y de vuelta al puesto. Rápido, hay propina.)"]])


func _on_abandon() -> void:
	var id: String = aband["id"]
	var ab: Dictionary = TenisHistoria.ABANDONOS.get(id, {})
	await Dialogue.talk(ab.get("lines", []))
	# Que se vea cómo se va (TenisMatch.exit_pro), y después él, por la raqueta.
	_match.exit_pro(str(ab.get("salida", "camina")))
	await _match.exit_done
	var lines: Array = [["EL ORGANIZADOR", "—¡Recogebolas! ¡Usted, el mudo! Coja esa raqueta y termine el partido. El canal no espera, y yo no devuelvo boletas."]]
	lines.append(["", str(ab.get("raqueta", ""))])
	await Dialogue.talk(lines)
	_match.walk_in()
	await _match.exit_done
	if st.get("por", []).is_empty():
		await Dialogue.talk([["", "(E: plano. Q: cortado; con arriba, dejada. X: globo. F: lo de él, cuando titile la barra.)"]])
	var usados: Array = st.get("usados", [])
	usados.append(id)
	st["usados"] = usados
	var por: Array = st.get("por", [])
	por.append(id)
	st["por"] = por
	st["ultimo"] = id
	_match.take_over()


func _on_closed(w: int) -> void:
	var sim: TenisSim = _match.sim
	var played: bool = _match.is_taken_over()
	var fast: int = _match.bb_fast
	bracket.report(m, sim.players[w].id, TenisBracket.score_text(sim.score, w))
	_gano = w == 0 and played
	# Los otros partidos del día, sin él.
	var left := bracket.next_match()
	while not left.is_empty() and int(left["round"]) == r:
		bracket.simulate(left, TenisBracket.match_seed(left, int(st["seed"])))
		left = bracket.next_match()
	st["bracket"] = bracket.to_dict()
	if _gano:
		var salv: Array = st.get("salvados", [])
		salv.append(aband["id"])
		st["salvados"] = salv
	_paga = TenisHistoria.paga(rname, _gano, fast)
	if not played:  # (no alcanzó a abandonar: no hubo partido de él)
		_paga["pro"] = 0
		_paga["total"] = int(_paga["sueldo"]) + int(_paga["bolas"])
	_match.queue_free()
	_match = null
	MusicDirector.force("tenis_cuadro")
	_show_pago(fast, played)


# ---------------------------------------------------------------- 4. La paga

func _show_pago(fast: int, played: bool) -> void:
	_step = "pago"
	_t = 0.0
	_clear()
	_cuadro.visible = true
	_cuadro.mark = {}
	_cuadro.refresh()
	_title()
	_box.queue_redraw()
	var pro: Dictionary = TenisData.player(aband["id"])
	var x0 := 72.0
	var x1 := 200.0
	_label(Vector2(0, 50), "LA JORNADA", Color(1, 0.9, 0.5), true)
	var rows := [["SUELDO", int(_paga["sueldo"])], ["PELOTAS: %d" % fast, int(_paga["bolas"])]]
	if played:
		rows.append([("%s (GANÓ)" if _gano else "%s (PERDIÓ)") % pro["short"], int(_paga["pro"])])
	for i in rows.size():
		_label(Vector2(x0, 68 + i * 12), rows[i][0], Color(0.8, 0.82, 0.9))
		_label(Vector2(x1, 68 + i * 12), "$" + TenisData.money(rows[i][1]), Color(1, 0.95, 0.8))
	_label(Vector2(x0, 112), "TOTAL", Color(1, 0.9, 0.5))
	_label(Vector2(x1, 112), "$" + TenisData.money(int(_paga["total"])), Color(1, 0.9, 0.5))
	var owe := Torneo.debe()
	if owe > 0:  # lo del gota a gota (con lo que ya tenía en el bolsillo)
		var after := GameState.money + int(_paga["total"])
		_label(Vector2(x0, 126), "COBRADOR", Color(0.75, 0.78, 0.86))
		_label(Vector2(x1 - 8, 126), "LISTO" if after >= owe else "-$" + TenisData.money(owe - after),
			Color(0.5, 0.9, 0.55) if after >= owe else Color(1, 0.55, 0.45))
	_label(Vector2(0, 170), "E: SEGUIR", Color(0.85, 0.9, 1.0), true)


func _draw_box() -> void:
	if _step != "pago" and _step != "fin":
		return
	_box.draw_rect(Rect2(60, 42, 200, 100), Color(0.05, 0.05, 0.09, 0.96))  # (en _box: encima del cuadro)
	_box.draw_rect(Rect2(60, 42, 200, 100), Color(0.5, 0.42, 0.3), false, 1.0)


## Le pagan, pasa el día (la jornada son cuatro horas) y vuelve al barrio, a la entrada.
func _cobrar() -> void:
	var name: String = TenisData.player(aband["id"])["name"]
	var lines := []
	if _gano:
		lines.append(["", "(%s le da los $%s en billetes doblados en cuatro. Le da la mano. Después se mira la mano, por si acaso.)" % [name, TenisData.money(int(_paga["pro"]))]])
	elif int(_paga["pro"]) > 0:
		lines.append(["", "(%s le da $%s \"por la molestia\". La molestia fue de él.)" % [name, TenisData.money(int(_paga["pro"]))]])
	if not lines.is_empty():
		await Dialogue.talk(lines)
	var g := GameState
	g.add_money(int(_paga["total"]))
	st["trabajo"] = g.day
	st["ganado"] = int(st.get("ganado", 0)) + int(_paga["total"])
	var f := g.flags
	f["torneo"] = st
	if f.get("trabajo_ultimo", -1) != g.day:
		f["trabajo_ultimo"] = g.day
		f["trabajo_dias"] = int(f.get("trabajo_dias", 0)) + 1
	TimeManager.skip(4.0)
	g.set_hunger(g.hunger - 10.0)
	g.change_mood(6.0 if _gano else 2.0)
	_volver("(Sale del coliseo con las rodillas raspadas de tanto agacharse. Le suenan los billetes en el bolsillo. Suena bonito.)")


func _volver(line: String) -> void:
	var back: Array = GameState.flags.get("torneo_volver", [CITY, ""])
	SceneRouter.go(back[0], back[1], "", line)
