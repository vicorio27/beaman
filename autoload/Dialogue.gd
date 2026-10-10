extends CanvasLayer
## Diálogos (spec, sección 32): nombre de quien habla, texto que se escribe solo, varias líneas
## y opciones al final.
##   var i := await Dialogue.talk([["DON GERMAN", "—¿Necesitás algo?"]], ["Trabajar", "Salir"])
## Devuelve el índice de la opción elegida (cancelar = la última), o -1 si no había opciones.
## Interactuar: avanza (o completa el texto). Arriba/abajo: elegir. Cancelar: la última opción.
## Lo que él piensa va con quien habla = INNER ("ÉL"): otro color, y la placa dice "por dentro".
## Estilo Dredge: el que habla, de pie, en el medio (retrato serio y gastado, SPEAKERS), detrás de
## un cuadro negro con letra blanca; el nombre centrado entre dos líneas finas, y comillas.
## Cara a cara (face_off = [retrato izq, retrato der]): los dos de pie, mirándose (el de la derecha,
## volteado); el que habla, con luz, el otro apagado. Una línea puede traer un tercer elemento (otro
## retrato para el que habla: "lukas_ladra") y un cuarto ("sacude": el retrato tiembla).

signal _finished(choice: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CHARS_PER_SECOND := 45.0
## Lo que él piensa (afuera es mudo: los demás no lo oyen). Se escribe ["ÉL", "..."], sin raya.
const INNER := "ÉL"
const INK := Color(0.93, 0.91, 0.87)
const INNER_COLOR := Color(0.62, 0.76, 0.96)
const NARRATION_COLOR := Color(0.7, 0.67, 0.62)
const NAME_COLOR := Color(0.95, 0.93, 0.88)
const SUB_COLOR := Color(0.58, 0.55, 0.52)
const SELECT_COLOR := Color(0.88, 0.36, 0.42)
const BOX := Rect2(34, 130, 252, 48)
## Lo que entra en el cuadro (4 renglones). Lo más largo se parte en páginas.
const PAGE_CHARS := 96  # 28 letras por renglón, 4 renglones
const PAGE_CHARS_WIDE := 96
## Quién habla -> [retrato (assets/portraits/<id>.png), lo que dice la placa abajo del nombre].
## Sin entrada: placa sin retrato. Los retratos salen de tools/art/draw_retratos.py.
const SPEAKERS := {
	"ÉL": ["el", "por dentro"], "YO": ["el", ""], "EL PELADO": ["el", ""],
	"DON GERMAN": ["german", "la panadería"], "MARTA": ["marta", "el café"], "SAMUEL": ["samuel", "bajo el puente"],
	"WILSON": ["wilson", "reciclador"], "DOÑA ROSA": ["rosa", "tintos y arepas"], "VICTORIA": ["victoria", "su hija"],
	"ZAIDA": ["zaida", ""], "DRA. PILAR": ["pilar", "veterinaria"], "DEFENSORA": ["defensora", "Defensoría"],
	"CELADOR": ["celador", ""], "LILATO": ["lilato", "su ex"], "BRENDA": ["brenda", "su mamá"],
	"MAURICIO": ["mauricio", "su papá"], "GUILLERMO": ["guillermo", ""], "CAMILA": ["camila", ""],
	"LISANDRO": ["lisandro", ""], "JOSE MARIO": ["josemario", "su jefe"], "WALTER": ["walter", ""],
	"NICOLAS": ["nicolas", ""], "EDDY": ["eddy", ""], "DIANA CAROLINA": ["diana", ""], "RAUL": ["raul", ""],
	"ALVARITO": ["alvarito", ""], "EL PECAS": ["pecas", ""], "PADRE HERNANDO": ["padre", "San Judas"],
	"DOÑA FABIOLA": ["fabiola", "la olla"], "DON AURELIO": ["aurelio", "La Esperanza"],
	"DOÑA LEONOR": ["leonor", "las flores"], "DON EFRAIN": ["efrain", "cachivaches"], "EL MONO": ["mono", "la glorieta"],
	"DON OCTAVIO": ["octavio", "el ajedrez"], "DON RAMIRO": ["ramiro", "el ajedrez"], "YEISON": ["yeison", ""],
	"EL DE LA CHAQUETA": ["chaqueta", ""], "FUNCIONARIA": ["funcionaria", ""], "FOTOGRAFO": ["fotografo", ""],
	"DON TITO": ["tito", ""], "LA MONA": ["mona", ""], "MAESTRO RAMIRO": ["maestro", ""],
	"LORENA": ["lilato", "su ex"], "ÉL, A LUKAS": ["el", "en voz alta, a Lukas"], "LUKAS": ["lukas", "beagle"],
}
## Los de la ciudad: a esos se les va apagando la cara (todos iguales, GameState.sameness), como a
## su muñeco en el mapa. Los de los sueños, no. Retrato -> id de la persona.
const CITY := {"german": "german", "marta": "marta", "samuel": "samuel", "wilson": "wilson", "rosa": "rosa",
	"padre": "padre", "fabiola": "fabiola", "aurelio": "aurelio", "leonor": "leonor", "efrain": "efrain",
	"mono": "mono", "octavio": "viejos", "ramiro": "viejo2", "celador": "celador", "yeison": "yeison",
	"pilar": "pilar", "defensora": "defensora", "funcionaria": "funcionaria", "fotografo": "fotografo"}
const SAME_SHADER := preload("res://assets/shaders/retrato_iguales.gdshader")

var active := false
## Cara a cara: [retrato de la izquierda, retrato de la derecha]. Se vacía al cerrar.
var face_off: Array = []
var _lines: Array = []
var _choices: Array = []
var _index := 0
var _shown := 0.0
var _cursor := 0
var _guard := 0.0

var _box: ColorRect
var _portrait: TextureRect
var _portrait2: TextureRect  # el de la derecha, en el cara a cara
var _plate: Control
var _name: Label
var _sub: Label
var _text: Label
var _more: TextureRect
var _quotes: Array[Label] = []
var _choice_panel: ColorRect
var _choice_bar: ColorRect
var _choice_labels: Array[Label] = []


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	# El que habla, de pie en el medio, detrás del cuadro (el cuadro le tapa la cintura).
	_portrait = TextureRect.new()
	_portrait.position = Vector2(112, 24)
	_portrait.visible = false
	add_child(_portrait)
	_portrait2 = TextureRect.new()
	_portrait2.flip_h = true
	_portrait2.visible = false
	add_child(_portrait2)
	_box = ColorRect.new()
	_box.color = Color(0.03, 0.03, 0.04, 1.0)  # opaca: lo que quede debajo no se lee a través
	_box.position = BOX.position
	_box.size = BOX.size
	_box.visible = false
	add_child(_box)
	var inner := ReferenceRect.new()
	inner.border_color = Color(0.55, 0.53, 0.5, 0.35)
	inner.editor_only = false
	inner.position = Vector2(2, 2)
	inner.size = BOX.size - Vector2(4, 4)
	_box.add_child(inner)
	_text = _label(Vector2(14, 5), INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_constant_override("line_spacing", 2)
	_text.size = Vector2(224, 40)
	_box.add_child(_text)
	for q in [["“", Vector2(2, -6)], ["”", BOX.size - Vector2(14, 10)]]:  # las comillas grandes
		var l := _label(q[1], Color(0.93, 0.91, 0.87))
		l.text = q[0]
		l.add_theme_font_size_override("font_size", 16)
		_box.add_child(l)
		_quotes.append(l)
	_more = TextureRect.new()
	_more.texture = load("res://assets/ui/dlg_more.png")
	_box.add_child(_more)
	# El nombre: centrado, entre dos líneas finas, sobre el borde de arriba del cuadro.
	_plate = Control.new()
	_plate.visible = false
	add_child(_plate)
	for side in [0, 1]:
		var ln := ColorRect.new()
		ln.color = Color(0.85, 0.83, 0.78, 0.8)
		ln.name = "Linea%d" % side
		_plate.add_child(ln)
	var name_bg := ColorRect.new()
	name_bg.name = "Fondo"
	name_bg.color = Color(0.03, 0.03, 0.04, 0.9)
	_plate.add_child(name_bg)
	_name = _label(Vector2.ZERO, NAME_COLOR)
	_plate.add_child(_name)
	_sub = _label(Vector2.ZERO, SUB_COLOR)
	_plate.add_child(_sub)
	_choice_panel = ColorRect.new()
	_choice_panel.color = Color(0.03, 0.03, 0.04, 0.9)
	_choice_panel.visible = false
	add_child(_choice_panel)
	_choice_bar = ColorRect.new()
	_choice_bar.color = Color(0.5, 0.12, 0.16, 0.6)
	_choice_panel.add_child(_choice_bar)


func _label(pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	return l


## Muestra las líneas ([quién, texto] o solo texto) y, al final, las opciones.
func talk(lines: Array, choices: Array = []) -> int:
	Narrator.hide_now()  # que no se mezclen dos textos
	# En el celular, "E: golpe" dice "A: golpe" (antes de partir en páginas: puede cambiar el largo).
	var shown := []
	for l in lines:
		shown.append([l[0], Controls.keys_in(str(l[1]))] + l.slice(2) if l is Array else Controls.keys_in(str(l)))
	_lines = _paginate(shown)
	_choices = choices
	_keep_company(lines)
	_index = 0
	_cursor = 0
	_guard = 0.15
	active = true
	GameState.ui_open = true
	_box.visible = true
	_hide_under(true)
	_show_line()
	var result: int = await _finished
	return result


## Si alguien le habla (no él por dentro, no la narración), baja la soledad. Una vez cada 20 minutos.
func _keep_company(lines: Array) -> void:
	for line in lines:
		if line is Array and line[0] != null and not str(line[0]) in ["", INNER, "YO", "EL PELADO"]:
			var f := GameState.flags
			if TimeManager.minutes - float(f.get("company_at", -999.0)) > 20.0:
				f["company_at"] = TimeManager.minutes
				GameState.company(10.0)
			return


## Parte las líneas que no entran en el cuadro, por oraciones (si una oración sola no entra, por
## palabras). Cada página conserva a quien habla. Con retrato entra menos (el cuadro es más angosto).
func _paginate(lines: Array) -> Array:
	var out := []
	for line in lines:
		var who = line[0] if line is Array else null
		var text: String = line[1] if line is Array else str(line)
		var page := PAGE_CHARS if who != null and SPEAKERS.has(who) else PAGE_CHARS_WIDE
		if text.length() <= page:
			out.append(line)
			continue
		var pages: Array[String] = []
		var cur := ""
		for piece in _pieces(text, page):
			if cur != "" and (cur + " " + piece).length() > page:
				pages.append(cur)
				cur = piece
			else:
				cur = piece if cur == "" else cur + " " + piece
		if cur != "":
			pages.append(cur)
		for pg in pages:
			out.append([who, pg] + line.slice(2) if who != null else pg)
	return out


## Oraciones (o palabras sueltas, si una oración no entra en una página).
func _pieces(text: String, page: int) -> Array[String]:
	var res: Array[String] = []
	var sentence := ""
	for word in text.split(" ", false):
		sentence = word if sentence == "" else sentence + " " + word
		if word.ends_with(".") or word.ends_with("?") or word.ends_with("!") or word.ends_with(":"):
			res.append(sentence)
			sentence = ""
	if sentence != "":
		res.append(sentence)
	var fit: Array[String] = []
	for sn in res:
		if sn.length() <= page:
			fit.append(sn)
		else:
			fit.append_array(Array(sn.split(" ", false)))
	return fit


func _show_line() -> void:
	var line = _lines[_index]
	var who: String = str(line[0]) if line is Array and line[0] != null else ""
	_text.text = line[1] if line is Array else str(line)
	var info: Array = SPEAKERS.get(who, [])
	var color := INK
	if who == "":
		color = NARRATION_COLOR
	elif who == INNER:
		color = INNER_COLOR
	_text.add_theme_color_override("font_color", color)
	_portrait.visible = not info.is_empty()
	if _portrait.visible:
		_portrait.texture = load("res://assets/portraits/%s.png" % info[0])
		_portrait.modulate = Color(0.8, 0.88, 1.0) if who == INNER else Color.WHITE
		_set_sameness(info[0])
	_portrait2.visible = false
	if face_off.size() == 2:
		_show_face_off(line, info)
	_more.position = BOX.size - Vector2(26, 9)
	# El nombre (y lo que es, más apagado), centrado entre dos líneas.
	_plate.visible = who != ""
	if _plate.visible:
		_name.text = who
		_sub.text = ("  " + info[1]) if info.size() > 1 and info[1] != "" else ""
		var w := (_name.text.length() + _sub.text.length()) * 8
		var x0 := 160.0 - w / 2.0
		var y := BOX.position.y - 12
		_name.position = Vector2(x0, y)
		_sub.position = Vector2(x0 + _name.text.length() * 8, y)
		var bg: ColorRect = _plate.get_node("Fondo")
		bg.position = Vector2(x0 - 6, y - 2)
		bg.size = Vector2(w + 12, 12)
		var l0: ColorRect = _plate.get_node("Linea0")
		var l1: ColorRect = _plate.get_node("Linea1")
		l0.position = Vector2(BOX.position.x + 6, y + 4)
		l0.size = Vector2(maxf(0.0, x0 - 10 - BOX.position.x - 6), 1)
		l1.position = Vector2(x0 + w + 10, y + 4)
		l1.size = Vector2(maxf(0.0, BOX.end.x - 6 - (x0 + w + 10)), 1)
	_shown = 0.0
	_text.visible_characters = 0
	_choice_panel.visible = false


## Cara a cara: los dos de pie, mirándose. El que habla, con luz (y su retrato de la línea, si trae).
func _show_face_off(line, info: Array) -> void:
	var speaker: String = info[0] if not info.is_empty() else ""
	var right: bool = speaker == face_off[1]
	var faces := [face_off[0], face_off[1]]
	if line is Array and line.size() > 2 and str(line[2]) != "":
		faces[1 if right else 0] = line[2]
	_portrait.material = null
	_portrait.texture = load("res://assets/portraits/%s.png" % faces[0])
	_portrait2.texture = load("res://assets/portraits/%s.png" % faces[1])
	_portrait.position = Vector2(46, 24)
	_portrait2.position = Vector2(178, 24)
	_portrait.visible = true
	_portrait2.visible = true
	var lit := Color.WHITE
	var dim := Color(0.42, 0.42, 0.5)
	var talking := speaker != ""
	_portrait.modulate = lit if talking and not right else dim
	_portrait2.modulate = lit if right else dim
	if talking and speaker == face_off[0] and line[0] == INNER:
		_portrait.modulate = Color(0.8, 0.88, 1.0)
	if line is Array and line.size() > 3 and line[3] == "sacude":
		var who: TextureRect = _portrait2 if right else _portrait
		var base := who.position
		var t := create_tween()
		for k in 6:
			t.tween_property(who, "position", base + Vector2(randf_range(-3, 3), randf_range(-2, 1)), 0.04)
		t.tween_property(who, "position", base, 0.04)


## Todos iguales: a la gente de la ciudad se le va apagando la cara.
func _set_sameness(portrait_id: String) -> void:
	_portrait.material = null
	if not CITY.has(portrait_id):
		return
	var id: String = CITY[portrait_id]
	var amount := GameState.sameness(id, not GameState.BOND_NAMES.has(id))
	if amount <= 0.0:
		return
	var m := ShaderMaterial.new()
	m.shader = SAME_SHADER
	m.set_shader_parameter("same_tex", load("res://assets/portraits/iguales.png"))
	m.set_shader_parameter("amount", amount)
	_portrait.material = m


func _process(delta: float) -> void:
	if not active:
		return
	_guard -= delta
	if _text.visible_characters < _text.text.length():
		_shown += delta * CHARS_PER_SECOND
		_text.visible_characters = int(_shown)
	var last := _index == _lines.size() - 1
	_more.visible = _text.visible_characters >= _text.text.length() and not (last and not _choices.is_empty())
	_more.position.y = _box.size.y - 9 + (1 if int(Time.get_ticks_msec() / 300) % 2 == 0 else 0)
	if last and not _choices.is_empty() and _text.visible_characters >= _text.text.length() and not _choice_panel.visible:
		_show_choices()


func _show_choices() -> void:
	for l in _choice_labels:
		l.queue_free()
	_choice_labels.clear()
	var w := 0
	for c in _choices:
		w = maxi(w, str(c).length())
	var width := w * 8 + 30
	_choice_panel.size = Vector2(width, _choices.size() * 11 + 12)
	_choice_panel.position = Vector2(BOX.end.x - width, BOX.position.y - 16 - _choice_panel.size.y)
	for i in _choices.size():
		var l := _label(Vector2(8, 7 + i * 11), INK)
		_choice_panel.add_child(l)
		_choice_labels.append(l)
	_choice_panel.visible = true
	_refresh_cursor()


func _refresh_cursor() -> void:
	_choice_bar.position = Vector2(4, 5 + _cursor * 11)
	_choice_bar.size = Vector2(_choice_panel.size.x - 8, 11)
	for i in _choice_labels.size():
		var sel := i == _cursor
		_choice_labels[i].text = ("> " if sel else "  ") + str(_choices[i])
		_choice_labels[i].add_theme_color_override("font_color", SELECT_COLOR.lightened(0.3) if sel else INK)


func _unhandled_input(event: InputEvent) -> void:
	if not active or _guard > 0.0:
		return
	var handled := true
	if _choice_panel.visible:
		if event.is_action_pressed("move_down"):
			_cursor = (_cursor + 1) % _choices.size()
			_refresh_cursor()
		elif event.is_action_pressed("move_up"):
			_cursor = (_cursor - 1 + _choices.size()) % _choices.size()
			_refresh_cursor()
		elif event.is_action_pressed("interact"):
			_close(_cursor)
		elif event.is_action_pressed("cancel"):
			_close(_choices.size() - 1)
		else:
			handled = false
	elif event.is_action_pressed("interact") or event.is_action_pressed("cancel"):
		if _text.visible_characters < _text.text.length():
			_text.visible_characters = _text.text.length()
			_shown = _text.text.length()
		elif _index < _lines.size() - 1:
			_index += 1
			_show_line()
		elif _choices.is_empty():
			_close(-1)
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


## Los textos de un minijuego que quedarían debajo de la caja (grupo "under_dialogue"): se esconden
## mientras dura el diálogo y vuelven como estaban.
func _hide_under(hide: bool) -> void:
	for n in get_tree().get_nodes_in_group("under_dialogue"):
		if hide:
			if not n.has_meta("dlg_vis"):
				n.set_meta("dlg_vis", n.visible)
			n.visible = false
		elif n.has_meta("dlg_vis"):
			n.visible = n.get_meta("dlg_vis")
			n.remove_meta("dlg_vis")


func _close(choice: int) -> void:
	_hide_under(false)
	active = false
	_box.visible = false
	_portrait.visible = false
	_portrait.position = Vector2(112, 24)
	_portrait2.visible = false
	face_off = []
	_plate.visible = false
	_choice_panel.visible = false
	GameState.ui_open = false
	GameState.block_input(0.2)
	_finished.emit(choice)
