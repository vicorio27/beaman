extends CanvasLayer
## Muestra una línea corta abajo de la pantalla y la desvanece sola.
## Para pensamientos del protagonista y descripciones ("Está cerrado.").
## Los diálogos con personajes van a tener su propio sistema (Fase 2).

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const SECONDS_PER_CHAR := 0.06
const MIN_SECONDS := 2.0

## Altura de la caja "arriba" (las carreras la suben para no tapar la calle).
var top_y := 40.0
var _panel: PanelContainer
var _label: Label
var _tween: Tween
var _style_box: StyleBoxFlat   # abajo: la caja de siempre
var _style_thin: StyleBoxFlat  # arriba (en la acción): fina y transparente, para ver a través
var _pending: Array = []  # lo que llegó mientras había un diálogo o una llamada en pantalla
var _current: Array = []  # lo que se está mostrando (si se abre una pantalla, se guarda y vuelve)


func _ready() -> void:
	layer = 15
	_panel = PanelContainer.new()
	_style_box = StyleBoxFlat.new()
	_style_box.bg_color = Color(0.06, 0.05, 0.05, 0.82)
	_style_box.border_color = Color(0.85, 0.78, 0.62, 0.5)
	_style_box.set_border_width_all(1)
	_style_box.set_content_margin_all(5)
	_style_thin = StyleBoxFlat.new()
	_style_thin.bg_color = Color(0.04, 0.03, 0.04, 0.45)
	_style_thin.content_margin_left = 4
	_style_thin.content_margin_right = 4
	_style_thin.content_margin_top = 2
	_style_thin.content_margin_bottom = 2
	_panel.add_theme_stylebox_override("panel", _style_box)
	_panel.position = Vector2(20, 146)
	_panel.size = Vector2(280, 26)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0
	add_child(_panel)

	_label = Label.new()
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	_label.add_theme_constant_override("outline_size", 3)  # se lee aunque el fondo sea transparente
	_label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.03))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_panel.add_child(_label)


## top = mostrarla arriba de la pantalla (cuando la acción está abajo).
func say(text: String, top := false) -> void:
	if _busy():
		_pending = [text, top]
		return
	_current = [text, top]
	_label.text = text
	# Crece según el texto; abajo crece hacia arriba para no salirse de la pantalla.
	if top:
		# Arriba, en plena acción: fina, ancha (menos renglones) y casi transparente.
		_panel.add_theme_stylebox_override("panel", _style_thin)
		var th := FONT.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, 304, 8).y + 4.0
		_panel.size = Vector2(312, th)
		_panel.position = Vector2(4, top_y)
	else:
		_panel.add_theme_stylebox_override("panel", _style_box)
		# En el celular: entre la palanca (izquierda) y los botones (derecha).
		var w := 166.0 if Controls.touch() else 280.0
		var x := 66.0 if Controls.touch() else 20.0
		var h := maxf(26.0, FONT.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, w - 10.0, 8).y + 10.0)
		_panel.size = Vector2(w, h)
		_panel.position = Vector2(x, 172 - h)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_tween.tween_interval(maxf(MIN_SECONDS, text.length() * SECONDS_PER_CHAR))
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.4)


func _busy() -> bool:
	return Dialogue.active or Phone.ringing() or GameState.ui_open


func _process(_delta: float) -> void:
	# Se abrió una pantalla con el aviso a la vista: se esconde y vuelve a salir cuando se cierre.
	if _busy() and _panel.modulate.a > 0.0:
		if _pending.is_empty() and not _current.is_empty():
			_pending = _current
		hide_now()
		return
	if not _pending.is_empty() and not _busy():
		var p := _pending
		_pending = []
		say(p[0], p[1])


## Se calla de golpe (cuando empieza un diálogo).
func hide_now() -> void:
	if _tween:
		_tween.kill()
	_panel.modulate.a = 0.0
