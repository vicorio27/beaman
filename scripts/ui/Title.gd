extends Control
## Pantalla de título: CONTINUAR (si hay partida guardada en un cuenco), NUEVA PARTIDA (el sueño 1) o
## SUEÑOS: cada minijuego suelto, sin la historia alrededor (al terminar vuelve acá; ver SceneRouter.go).
## Arriba/abajo para elegir, interactuar para entrar. CONTROLES EN PANTALLA: interactuar (o izq/der)
## cambia entre AUTO (solo en el celular), SÍ y NO.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const PROLOGUE := "res://scenes/prologue/Fight.tscn"
## Los sueños sueltos: [nombre, escena].
const DREAMS := [
	["CALLEJON: LILATO", "res://scenes/prologue/Fight.tscn"],
	["PLOMO 1: LA ESQUINA", "res://scenes/dreams/PlomoDealer1.tscn"],
	["PLOMO 2: LA COCINA", "res://scenes/dreams/PlomoDealer2.tscn"],
	["PLOMO 3: EL QUE NO SE MUERE", "res://scenes/dreams/PlomoDealer3.tscn"],
	["SIGILO 1: WALTER", "res://scenes/dreams/Sigilo1.tscn"],
	["SIGILO 2: NICOLAS", "res://scenes/dreams/Sigilo2.tscn"],
	["SIGILO 3: EDDY", "res://scenes/dreams/Sigilo3.tscn"],
	["SIGILO 4: JOSE MARIO", "res://scenes/dreams/Sigilo4.tscn"],
	["CARRERA 1: CAMILA", "res://scenes/dreams/Carrera1.tscn"],
	["CARRERA 2: GUILLERMO", "res://scenes/dreams/Carrera2.tscn"],
	["CARRERA 3: LOS DOS", "res://scenes/dreams/Carrera3.tscn"],
	["CARRERA 4: LA HUIDA", "res://scenes/dreams/Carrera4.tscn"],
	["MANO A MANO: GUILLERMO", "res://scenes/dreams/PeleaGuillermo.tscn"],
	["CALLEJON: BRENDA", "res://scenes/dreams/Callejon3.tscn"],
	["LUCHA 1: RAUL", "res://scenes/dreams/Lucha1.tscn"],
	["LUCHA 2: ALVARITO", "res://scenes/dreams/Lucha2.tscn"],
	["LUCHA 3: EL PECAS", "res://scenes/dreams/Lucha3.tscn"],
	["LUCHA 4: MAURICIO", "res://scenes/dreams/Lucha4.tscn"],
	["RECUERDO: LA RENEGADE", "res://scenes/world/MotoRide.tscn"],
	["RECUERDO: LA PRIMERA VUELTA", "res://scenes/world/MotoLorena.tscn"],
	["FINAL: LA SERPIENTE", "final"],
	["EPILOGO", "res://scenes/world/Epilogo.tscn"],
	["< VOLVER", ""],
]

var _opts: Array[String] = []
var _labels: Array[Label] = []
var _cursor := 0
var _done := false
var _main_opts: Array[String] = []
var _in_dreams := false
var _head: Array[Control] = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.03, 0.06)
	bg.size = Vector2(320, 180)
	add_child(bg)
	var title := _label("BE A MAN", Vector2(0, 40), 16, Color(0.95, 0.85, 0.6))
	title.size = Vector2(320, 20)
	var sub := _label("una historia de calle, con perro", Vector2(0, 64), 8, Color(0.6, 0.58, 0.55))
	sub.size = Vector2(320, 10)
	_head.append(title)
	_head.append(sub)
	var lukas := TextureRect.new()
	lukas.texture = Lukas.cell(3, 0)
	lukas.position = Vector2(152, 80)
	add_child(lukas)
	_head.append(lukas)
	if GameState.has_save():
		_main_opts.append("CONTINUAR")
	_main_opts.append("NUEVA PARTIDA")
	_main_opts.append("SUEÑOS")
	_main_opts.append(TOUCH_OPT)
	for i in DREAMS.size():
		var l := _label("", Vector2(0, 4 + i * 10), 8, Color.WHITE)
		l.size = Vector2(320, 10)
		_labels.append(l)
	_show_main()
	MusicDirector.force("night")


func _label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _show_main() -> void:
	_in_dreams = false
	_opts = _main_opts.duplicate()
	_cursor = 0
	for h in _head:
		h.visible = true
	for i in _labels.size():
		_labels[i].position.y = 110 + i * 14
	_refresh()


func _show_dreams() -> void:
	_in_dreams = true
	_opts.clear()
	for d in DREAMS:
		_opts.append(d[0])
	_cursor = 0
	for h in _head:
		h.visible = false
	for i in _labels.size():
		_labels[i].position.y = 3 + i * 10
	_refresh()


const TOUCH_OPT := "CONTROLES"
const TOUCH_NAMES := {"auto": "AUTO", "si": "SI", "no": "NO"}  # (la fuente no tiene Í mayúscula)


func _opt_text(o: String) -> String:
	if o == TOUCH_OPT:
		return "CONTROLES EN PANTALLA: " + TOUCH_NAMES[Controls.touch_pref]
	return o


func _cycle_touch(step: int) -> void:
	var prefs := Controls.TOUCH_PREFS
	var i := (prefs.find(Controls.touch_pref) + step + prefs.size()) % prefs.size()
	Controls.set_touch_pref(prefs[i])
	_refresh()


## En la lista de sueños se ven 16 a la vez: la ventana sigue al cursor.
const ROWS := 16


func _refresh() -> void:
	var first := clampi(_cursor - ROWS / 2, 0, maxi(0, _opts.size() - ROWS)) if _in_dreams else 0
	for i in _labels.size():
		_labels[i].visible = i < _opts.size() and (not _in_dreams or (i >= first and i < first + ROWS))
		if _in_dreams:
			_labels[i].position.y = 12 + (i - first) * 10
		if i >= _opts.size():
			continue
		var sel := i == _cursor
		_labels[i].text = ("> " if sel else "") + _opt_text(_opts[i]) + (" <" if sel else "")
		_labels[i].add_theme_color_override("font_color", Color(0.95, 0.78, 0.4) if sel else Color(0.75, 0.72, 0.68))


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		_cursor = (_cursor + (1 if event.is_action_pressed("move_down") else -1) + _opts.size()) % _opts.size()
		_refresh()
	elif not _in_dreams and _opts[_cursor] == TOUCH_OPT and (event.is_action_pressed("interact")
			or event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		_cycle_touch(-1 if event.is_action_pressed("move_left") else 1)
	elif event.is_action_pressed("interact"):
		if _in_dreams:
			var scene: String = DREAMS[_cursor][1]
			if scene == "":
				_show_main()
				return
			# Un sueño suelto: partida limpia, y al despertar vuelve al título (SceneRouter.go).
			_done = true
			GameState.new_game()
			GameState.flags["arcade"] = true
			if scene == "final":
				FinalRush.begin()
				return
			SceneRouter.go(scene, "", DREAMS[_cursor][0])
			return
		if _opts[_cursor] == "SUEÑOS":
			_show_dreams()
			return
		_done = true
		if _opts[_cursor] == "CONTINUAR":
			var data := GameState.load_game()
			SceneRouter.go(data["scene"], data["spawn"], "DIA %d — %s" % [GameState.day, TimeManager.clock_text()],
				"Lukas se sacude el agua. Seguimos donde quedamos.")
		else:
			GameState.new_game()  # siempre limpia (aunque antes se haya jugado un sueño suelto)
			SceneRouter.go(PROLOGUE, "", "DIA 0 — 23:40")
