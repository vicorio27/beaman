extends CanvasLayer
## Diálogos (spec, sección 32): nombre de quien habla, texto que se escribe solo, varias líneas
## y opciones al final.
##   var i := await Dialogue.talk([["DON GERMAN", "—¿Necesitás algo?"]], ["Trabajar", "Salir"])
## Devuelve el índice de la opción elegida (cancelar = la última), o -1 si no había opciones.
## Interactuar: avanza (o completa el texto). Arriba/abajo: elegir. Cancelar: la última opción.
## Lo que él piensa va con quien habla = INNER ("ÉL"): otro color, y el nombre dice "por dentro".

signal _finished(choice: int)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const CHARS_PER_SECOND := 45.0
## Lo que él piensa (afuera es mudo: los demás no lo oyen). Se escribe ["ÉL", "..."], sin raya.
const INNER := "ÉL"
const TEXT_COLOR := Color(0.95, 0.92, 0.86)
const INNER_COLOR := Color(0.66, 0.8, 0.96)
## Lo que entra en el cuadro (3 renglones de ~36 letras). Lo más largo se parte en páginas.
const PAGE_CHARS := 94

var active := false
var _lines: Array = []
var _choices: Array = []
var _index := 0
var _shown := 0.0
var _cursor := 0
var _guard := 0.0

var _panel: ColorRect
var _name: Label
var _text: Label
var _more: Label
var _choice_panel: ColorRect
var _choice_labels: Array[Label] = []


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0.07, 0.05, 0.08, 0.94)
	_panel.position = Vector2(6, 124)
	_panel.size = Vector2(308, 52)
	_panel.visible = false
	add_child(_panel)
	var border := ReferenceRect.new()
	border.border_color = Color(0.85, 0.74, 0.5, 0.7)
	border.editor_only = false
	border.size = _panel.size
	_panel.add_child(border)
	_name = _label(Vector2(8, 5), Color(0.95, 0.78, 0.4))
	_panel.add_child(_name)
	_text = _label(Vector2(8, 18), TEXT_COLOR)
	_text.size = Vector2(292, 32)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_text)
	_more = _label(Vector2(296, 41), Color(0.95, 0.78, 0.4))
	_more.text = "v"
	_panel.add_child(_more)
	_choice_panel = ColorRect.new()
	_choice_panel.color = _panel.color
	_choice_panel.visible = false
	add_child(_choice_panel)


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
	_panel.visible = true
	_show_line()
	var result: int = await _finished
	return result


## Parte las líneas que no entran en el cuadro, por oraciones (si una oración sola no entra, por
## palabras). Cada página conserva a quien habla.
func _paginate(lines: Array) -> Array:
	var out := []
	for line in lines:
		var who = line[0] if line is Array else null
		var text: String = line[1] if line is Array else str(line)
		if text.length() <= PAGE_CHARS:
			out.append(line)
			continue
		var pages: Array[String] = []
		var cur := ""
		for piece in _pieces(text):
			if cur != "" and (cur + " " + piece).length() > PAGE_CHARS:
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
func _pieces(text: String) -> Array[String]:
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
		if sn.length() <= PAGE_CHARS:
			fit.append(sn)
		else:
			fit.append_array(Array(sn.split(" ", false)))
	return fit


func _show_line() -> void:
	var line = _lines[_index]
	_text.add_theme_color_override("font_color", TEXT_COLOR)
	if line is Array:
		_name.text = line[0]
		_text.text = line[1]
		if line[0] == INNER:
			_name.text = "ÉL (POR DENTRO)"
			_text.add_theme_color_override("font_color", INNER_COLOR)
	else:
		_name.text = ""
		_text.text = line
	_shown = 0.0
	_text.visible_characters = 0
	_choice_panel.visible = false


func _process(delta: float) -> void:
	if not active:
		return
	_guard -= delta
	if _text.visible_characters < _text.text.length():
		_shown += delta * CHARS_PER_SECOND
		_text.visible_characters = int(_shown)
	var last := _index == _lines.size() - 1
	_more.visible = _text.visible_characters >= _text.text.length() and not (last and not _choices.is_empty())
	_more.position.y = 41 + (1 if int(Time.get_ticks_msec() / 300) % 2 == 0 else 0)
	if last and not _choices.is_empty() and _text.visible_characters >= _text.text.length() and not _choice_panel.visible:
		_show_choices()


func _show_choices() -> void:
	for l in _choice_labels:
		l.queue_free()
	_choice_labels.clear()
	var w := 0
	for c in _choices:
		w = maxi(w, str(c).length())
	var width := w * 8 + 24
	_choice_panel.size = Vector2(width, _choices.size() * 11 + 8)
	_choice_panel.position = Vector2(314 - width, 120 - _choice_panel.size.y)
	for i in _choices.size():
		var l := _label(Vector2(14, 5 + i * 11), Color.WHITE)
		l.text = str(_choices[i])
		_choice_panel.add_child(l)
		_choice_labels.append(l)
	_choice_panel.visible = true
	_refresh_cursor()


func _refresh_cursor() -> void:
	for i in _choice_labels.size():
		var sel := i == _cursor
		_choice_labels[i].text = ("> " if sel else "  ") + str(_choices[i])
		_choice_labels[i].position.x = 4
		_choice_labels[i].add_theme_color_override("font_color", Color(0.95, 0.78, 0.4) if sel else Color(0.85, 0.82, 0.78))


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
	_panel.visible = false
	_choice_panel.visible = false
	GameState.ui_open = false
	GameState.block_input(0.2)
	_finished.emit(choice)
