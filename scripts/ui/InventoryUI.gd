extends CanvasLayer
## Tab: arriba las MISIONES (principal, secundarias, opcionales); abajo la MOCHILA
## (8 casilleros, nombre y descripción del elegido).
##   Abrir/cerrar: inventario (Tab / I / Y del joystick). Moverse: flechas.
##   Usar / comer: interactuar. Tirar: tirar (X). Cerrar: cancelar.
##   Armar (C): recetas para combinar (Items.RECIPES); arriba/abajo elige, interactuar arma.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const COLS := 4
const CELL := 22
const ORIGIN := Vector2(16, 84)
const TEXT_X := 110.0
const TEXT_W := 170.0  # el panel termina en x=286: a la derecha quedan los botones táctiles

var _open := false
var _cursor := 0
var _root: Control
var _cells: Array[ColorRect] = []
var _icons: Array[TextureRect] = []
var _qty: Array[Label] = []
var _name: Label
var _desc: Label
var _quest_lines: Array[Label] = []
var _crafting := false
var _recipe := 0


func _ready() -> void:
	layer = 14
	_root = Control.new()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(320, 180)
	_root.add_child(dim)
	var qpanel := ColorRect.new()
	qpanel.color = Color(0.12, 0.09, 0.12, 0.95)
	qpanel.position = Vector2(ORIGIN.x - 10, 4)
	qpanel.size = Vector2(TEXT_X + TEXT_W - ORIGIN.x + 16, 54)
	_root.add_child(qpanel)
	_label("MISIONES", Vector2(ORIGIN.x - 2, 8), Color(0.9, 0.74, 0.36))
	for i in 4:
		var q := _label("", Vector2(ORIGIN.x - 2, 19 + i * 10), Color.WHITE)
		q.size = Vector2(TEXT_X + TEXT_W - ORIGIN.x, 10)  # no se sale del panel
		q.clip_text = true
		q.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_quest_lines.append(q)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.09, 0.12, 0.95)
	panel.position = ORIGIN - Vector2(10, 22)
	panel.size = Vector2(TEXT_X + TEXT_W - ORIGIN.x + 16, 2 * CELL + 66)
	_root.add_child(panel)
	_label("MOCHILA", ORIGIN - Vector2(2, 16), Color(0.9, 0.74, 0.36))
	for i in GameState.SLOTS:
		var pos := ORIGIN + Vector2((i % COLS) * CELL, (i / COLS) * CELL)
		var c := ColorRect.new()
		c.position = pos
		c.size = Vector2(CELL - 2, CELL - 2)
		_root.add_child(c)
		_cells.append(c)
		var ic := TextureRect.new()
		ic.position = pos + Vector2(2, 2)
		_root.add_child(ic)
		_icons.append(ic)
		var q := _label("", pos + Vector2(11, 12), Color.WHITE)
		_qty.append(q)
	_name = _label("", Vector2(TEXT_X, ORIGIN.y), Color(0.95, 0.92, 0.85))
	_desc = _label("", Vector2(TEXT_X, ORIGIN.y + 14), Color(0.75, 0.72, 0.68))
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.size = Vector2(TEXT_W, 60)
	_desc.clip_text = true
	_desc.max_lines_visible = 6
	_name.size = Vector2(TEXT_W, 10)
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label(Controls.keys_in("[E]usar [X]tirar [C]armar"), Vector2(ORIGIN.x - 2, ORIGIN.y + 2 * CELL + 6), Color(0.55, 0.52, 0.5))
	_label(Controls.keys_in("[L]libreta [Q]salir"), Vector2(ORIGIN.x - 2, ORIGIN.y + 2 * CELL + 18), Color(0.55, 0.52, 0.5))
	_desc.add_theme_font_size_override("font_size", 8)
	GameState.inventory_changed.connect(_refresh)


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 2)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	_root.add_child(l)
	return l


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle(not _open)
		get_viewport().set_input_as_handled()
		return
	if not _open:
		return
	if event.is_action_pressed("libreta"):  # de la mochila a la libreta
		get_viewport().set_input_as_handled()
		_toggle(false)
		var lib := get_tree().get_first_node_in_group("libreta")
		if lib:
			lib.open()
		return
	if _crafting:
		_craft_input(event)
		return
	if event.is_action_pressed("craft"):
		_crafting = true
	elif event.is_action_pressed("cancel"):
		_toggle(false)
	elif event.is_action_pressed("move_right"):
		_cursor = (_cursor + 1) % GameState.SLOTS
	elif event.is_action_pressed("move_left"):
		_cursor = (_cursor - 1 + GameState.SLOTS) % GameState.SLOTS
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_up"):
		_cursor = (_cursor + COLS) % GameState.SLOTS
	elif event.is_action_pressed("interact"):
		var line := GameState.use_slot(_cursor)
		if line != "":
			_say(line)
	elif event.is_action_pressed("drop"):
		var s = GameState.inventory[_cursor]
		if s != null:
			if Items.info(s["id"]).get("fixed", false):
				_say("(Esto no se tira.)")
			else:
				_say("(Tira: %s.)" % Items.info(s["id"])["name"].to_lower())
				GameState.remove_slot(_cursor, s["qty"])
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _craft_input(event: InputEvent) -> void:
	var n := Items.RECIPES.size()
	if event.is_action_pressed("cancel") or event.is_action_pressed("craft") or event.is_action_pressed("inventory"):
		_crafting = false
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		_recipe = (_recipe + 1) % n
	elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		_recipe = (_recipe - 1 + n) % n
	elif event.is_action_pressed("interact"):
		_say(GameState.craft(Items.RECIPES.keys()[_recipe]))
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _toggle(open: bool) -> void:
	if open and (SceneRouter.busy or GameState.ui_open):
		return
	_open = open
	_crafting = false
	_root.visible = open
	GameState.ui_open = open
	_refresh()


var _note := ""  # lo último que pasó (comió, tiró, armó): se muestra en la caja de la descripción


func _say(line: String) -> void:
	_note = line


func _refresh() -> void:
	for i in GameState.SLOTS:
		var s = GameState.inventory[i]
		_cells[i].color = Color(0.9, 0.74, 0.36, 0.9) if i == _cursor else Color(0.24, 0.2, 0.24)
		_icons[i].texture = Items.icon(s["id"]) if s != null else null
		_qty[i].text = str(s["qty"]) if s != null and s["qty"] > 1 else ""
	_refresh_quests()
	if _note != "":
		_name.text = ""
		_desc.text = _note
		_desc.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		_note = ""
		return
	if _crafting:
		var id: String = Items.RECIPES.keys()[_recipe]
		var ok := Items.can_craft(id)
		_name.text = "ARMAR %d/%d: %s" % [_recipe + 1, Items.RECIPES.size(), Items.info(id)["name"]]
		_desc.text = "Con: %s.\n%s\n[arriba/abajo] otra receta" % [Items.recipe_text(id),
			Controls.keys_in("[E] armar") if ok else "Me falta algo."]
		_desc.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6) if ok else Color(0.75, 0.72, 0.68))
		return
	_desc.add_theme_color_override("font_color", Color(0.75, 0.72, 0.68))
	var sel = GameState.inventory[_cursor]
	if sel == null:
		_name.text = "—"
		_desc.text = ""
	else:
		var it := Items.info(sel["id"])
		_name.text = it["name"]
		_desc.text = Controls.keys_in(it["desc"])


## Principal primero (amarilla), después secundarias (blancas) y opcionales (grises).
func _refresh_quests() -> void:
	var lines := []
	var main := GameState.main_quest()
	if main != "":
		lines.append(["> " + Quests.title(main) + Quests.progress_text(main), Color(0.95, 0.82, 0.45)])
	for id in GameState.active_quests("side"):
		lines.append(["- " + Quests.title(id) + Quests.progress_text(id), Color(0.92, 0.9, 0.86)])
	for id in GameState.active_quests("optional"):
		lines.append(["· " + Quests.title(id) + Quests.progress_text(id), Color(0.62, 0.6, 0.58)])
	for i in _quest_lines.size():
		_quest_lines[i].text = lines[i][0] if i < lines.size() else ""
		if i < lines.size():
			_quest_lines[i].add_theme_color_override("font_color", lines[i][1])
