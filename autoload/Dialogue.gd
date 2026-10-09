extends CanvasLayer
## Diálogos (spec, sección 32): nombre de quien habla, texto que se escribe solo, varias líneas
## y opciones al final.
##   var i := await Dialogue.talk([["DON GERMAN", "—¿Necesitás algo?"]], ["Trabajar", "Salir"])
## Devuelve el índice de la opción elegida (cancelar = la última), o -1 si no había opciones.
## Interactuar: avanza (o completa el texto). Arriba/abajo: elegir. Cancelar: la última opción.
## Lo que él piensa va con quien habla = INNER ("ÉL"): otro color, y la placa dice "por dentro".
## Estilo Hades: el retrato grande del que habla a la izquierda (SPEAKERS), la placa con el nombre
## montada sobre el cuadro, y el cuadro de papel con marco dorado (tools/art/draw_dialogo.py).

signal _finished(choice: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CHARS_PER_SECOND := 45.0
## Lo que él piensa (afuera es mudo: los demás no lo oyen). Se escribe ["ÉL", "..."], sin raya.
const INNER := "ÉL"
const INK := Color(0.2, 0.14, 0.12)
const INNER_COLOR := Color(0.16, 0.26, 0.52)
const NARRATION_COLOR := Color(0.42, 0.32, 0.26)
const NAME_COLOR := Color(0.95, 0.8, 0.45)
const SUB_COLOR := Color(0.86, 0.5, 0.46)
## Lo que entra en el cuadro (4 renglones). Lo más largo se parte en páginas.
const PAGE_CHARS := 88  # con retrato (27 letras por renglón)
const PAGE_CHARS_WIDE := 124  # sin retrato (36 por renglón)
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
	"LORENA": ["lilato", "su ex"],
}
## Los de la ciudad: a esos se les va apagando la cara (todos iguales, GameState.sameness), como a
## su muñeco en el mapa. Los de los sueños, no. Retrato -> id de la persona.
const CITY := {"german": "german", "marta": "marta", "samuel": "samuel", "wilson": "wilson", "rosa": "rosa",
	"padre": "padre", "fabiola": "fabiola", "aurelio": "aurelio", "leonor": "leonor", "efrain": "efrain",
	"mono": "mono", "octavio": "viejos", "ramiro": "viejo2", "celador": "celador", "yeison": "yeison",
	"pilar": "pilar", "defensora": "defensora", "funcionaria": "funcionaria", "fotografo": "fotografo"}
const SAME_SHADER := preload("res://assets/shaders/retrato_iguales.gdshader")

var active := false
var _lines: Array = []
var _choices: Array = []
var _index := 0
var _shown := 0.0
var _cursor := 0
var _guard := 0.0

var _box: NinePatchRect
var _portrait: TextureRect
var _plate: NinePatchRect
var _name: Label
var _sub: Label
var _text: Label
var _more: TextureRect
var _choice_panel: NinePatchRect
var _choice_bar: ColorRect
var _choice_labels: Array[Label] = []


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	_box = _nine("res://assets/ui/dlg_box.png", 6)
	_box.visible = false
	add_child(_box)
	_text = _label(Vector2.ZERO, INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_constant_override("line_spacing", 2)
	_box.add_child(_text)
	_more = TextureRect.new()
	_more.texture = load("res://assets/ui/dlg_more.png")
	_box.add_child(_more)
	# El retrato va encima del borde del cuadro (como en Hades), la placa encima de los dos.
	_portrait = TextureRect.new()
	_portrait.position = Vector2(-4, 68)  # retratos de 96x112, abajo a la izquierda
	_portrait.visible = false
	add_child(_portrait)
	_plate = _nine("res://assets/ui/dlg_plate.png", 5)
	_plate.visible = false
	add_child(_plate)
	_name = _label(Vector2(6, 4), NAME_COLOR)
	_plate.add_child(_name)
	_sub = _label(Vector2(6, 13), SUB_COLOR)
	_plate.add_child(_sub)
	_choice_panel = _nine("res://assets/ui/dlg_box.png", 6)
	_choice_panel.visible = false
	add_child(_choice_panel)
	_choice_bar = ColorRect.new()
	_choice_bar.color = Color(0.87, 0.7, 0.33, 0.45)
	_choice_panel.add_child(_choice_bar)


func _nine(path: String, margin: int) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = load(path)
	n.patch_margin_left = margin
	n.patch_margin_right = margin
	n.patch_margin_top = margin
	n.patch_margin_bottom = margin
	return n


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
	_lines = _paginate(lines)
	_choices = choices
	_index = 0
	_cursor = 0
	_guard = 0.15
	active = true
	GameState.ui_open = true
	_box.visible = true
	_show_line()
	var result: int = await _finished
	return result


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
			out.append([who, pg] if who != null else pg)
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
	# El retrato (si tiene) y el cuadro: con retrato, el cuadro empieza a su derecha.
	_portrait.visible = not info.is_empty()
	if _portrait.visible:
		_portrait.texture = load("res://assets/portraits/%s.png" % info[0])
		_portrait.modulate = Color(0.78, 0.86, 1.0) if who == INNER else Color.WHITE
		_set_sameness(info[0])
		_box.position = Vector2(60, 126)
		_box.size = Vector2(258, 52)
		_text.position = Vector2(34, 7)
		_text.size = Vector2(216, 40)
	else:
		_box.position = Vector2(2, 126)
		_box.size = Vector2(316, 52)
		_text.position = Vector2(10, 7)
		_text.size = Vector2(298, 40)
	_more.position = _box.size - Vector2(14, 9)
	# La placa del nombre, montada sobre el borde de arriba del cuadro.
	_plate.visible = who != ""
	if _plate.visible:
		_name.text = who
		_sub.text = info[1] if info.size() > 1 else ""
		var w := maxi(_name.text.length(), _sub.text.length()) * 8 + 12
		var h := 24 if _sub.text != "" else 16
		_plate.size = Vector2(w, h)
		_plate.position = Vector2(_box.position.x + (30 if _portrait.visible else 6), _box.position.y - h + 3)
	_shown = 0.0
	_text.visible_characters = 0
	_choice_panel.visible = false


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
	var top := (_plate.position.y if _plate.visible else _box.position.y) - 2
	_choice_panel.position = Vector2(318 - width, top - _choice_panel.size.y)
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
		_choice_labels[i].add_theme_color_override("font_color", Color(0.5, 0.12, 0.1) if sel else INK)


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


func _close(choice: int) -> void:
	active = false
	_box.visible = false
	_portrait.visible = false
	_plate.visible = false
	_choice_panel.visible = false
	GameState.ui_open = false
	GameState.block_input(0.2)
	_finished.emit(choice)
