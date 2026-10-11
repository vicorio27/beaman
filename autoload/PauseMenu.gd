extends CanvasLayer
## El menú de pausa: Start (P / Esc en el teclado, la rayita doble en el celular). Para todo el juego.
##   CONTINUAR
##   CONTROLES EN PANTALLA: AUTO / SÍ / NO   (los mismos del título; se guardan)
##   SALIR POR AHORA   (al título). En la vida real (un lugar con Location) guarda ahí mismo y se sigue
##                     en la entrada de ese lugar; en un sueño o un minijuego no se puede guardar a
##                     mitad: se sigue desde el último cuenco de agua.
## Arriba/abajo elige; acción (o izquierda/derecha en los controles) confirma; atrás o Start, sigue.
## Solo se abre con el juego andando: no en el título, ni con un diálogo, la mochila o una pantalla abierta.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const TITLE := "res://scenes/ui/Title.tscn"
const TOUCH_NAMES := {"auto": "AUTO", "si": "SI", "no": "NO"}  # (la fuente no tiene Í mayúscula)

var _open := false
var _cursor := 0
var _confirm := false  # salir pide confirmación
var _root: Control
var _opts: Array[Label] = []
var _note: Label


func _ready() -> void:
	layer = 115  # encima de todo menos los controles táctiles (120)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.size = Vector2(320, 180)
	_root.add_child(dim)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.09, 0.12, 0.96)
	panel.position = Vector2(40, 40)
	panel.size = Vector2(220, 108)
	_root.add_child(panel)
	_label("PAUSA", Vector2(40, 48), Color(0.9, 0.74, 0.36), 220, true)
	for i in 3:
		_opts.append(_label("", Vector2(52, 70 + i * 14), Color.WHITE, 200, false))
	_note = _label("", Vector2(44, 118), Color(0.6, 0.57, 0.55), 212, true)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _label(text: String, pos: Vector2, color: Color, w: float, center: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(w, 10)
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 2)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(l)
	return l


func _can_open() -> bool:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path == TITLE:
		return false
	return not (GameState.ui_open or Dialogue.active or SceneRouter.busy)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if event.is_action_pressed("pause") and _can_open():
			get_viewport().set_input_as_handled()
			_set_open(true)
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause") or event.is_action_pressed("cancel"):
		_set_open(false)
	elif event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % _opts.size()
		_confirm = false
	elif event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + _opts.size()) % _opts.size()
		_confirm = false
	elif _cursor == 1 and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right") or event.is_action_pressed("interact")):
		var prefs := Controls.TOUCH_PREFS
		var step := -1 if event.is_action_pressed("move_left") else 1
		Controls.set_touch_pref(prefs[(prefs.find(Controls.touch_pref) + step + prefs.size()) % prefs.size()])
	elif event.is_action_pressed("interact"):
		if _cursor == 0:
			_set_open(false)
		elif not _confirm:
			_confirm = true
		else:
			if _can_save():
				var scene := get_tree().current_scene
				GameState.save_game(scene.scene_file_path, "")
			_set_open(false)
			SceneRouter.go(TITLE)
	_refresh()


## ¿Se puede guardar acá? Solo en la vida real (los lugares hechos con Location).
func _can_save() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.get("default_spawn") != null and GameState.day >= 1


func _set_open(open: bool) -> void:
	_open = open
	_cursor = 0
	_confirm = false
	_root.visible = open
	get_tree().paused = open
	_refresh()


func _refresh() -> void:
	var texts := ["CONTINUAR", "CONTROLES: " + TOUCH_NAMES.get(Controls.touch_pref, "AUTO"),
		"¿SEGURO? OTRA VEZ" if _confirm else "SALIR POR AHORA"]
	for i in _opts.size():
		_opts[i].text = ("> " if i == _cursor else "  ") + texts[i]
		_opts[i].add_theme_color_override("font_color", Color(0.95, 0.82, 0.45) if i == _cursor else Color(0.92, 0.9, 0.86))
	if _cursor == 2:
		_note.text = "Se guarda aquí; se sigue en la entrada." if _can_save() 			else "En un sueño no se guarda: se sigue del último cuenco."
	elif _cursor == 1:
		_note.text = "Los botones en pantalla: AUTO, SI o NO."
	else:
		_note.text = ""
