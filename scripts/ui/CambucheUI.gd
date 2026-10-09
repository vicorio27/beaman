class_name CambucheUI
extends CanvasLayer
## "Mejorar" el cambuche: la lista de todo lo que se le puede poner, con lo que hace falta (íconos,
## tiene/necesita) y lo que se gana, a la vista: el cambuche AHORA y CON ESTO, y barras de caja,
## seguridad y ánimo (lo que sube, en verde).
##   var id := await CambucheUI.choose(self)   # "" = salió; si no, la mejora lista para poner
## Arriba/abajo: elegir. Acción: poner (si está lista). Atrás: salir.

signal _closed(id: String)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const GOLD := Color(0.95, 0.78, 0.4)
const CREAM := Color(0.95, 0.92, 0.86)
const DIM := Color(0.55, 0.52, 0.5)
const GOOD := Color(0.45, 0.9, 0.45)
const BAD := Color(0.95, 0.4, 0.35)
const PANEL := Color(0.1, 0.08, 0.1, 0.96)
const ROW_H := 13
## [id, nombre corto, qué da]. Las ampliaciones van con su nivel ("nivel_3", "nivel_4").
const ENTRIES := [
	["toldo", "Toldo", "Techo: si llueve, no amanece mojado. Con la cobija: nivel 2."],
	["cobija", "Cobija", "Duerme mejor: menos hambre en la noche. Con el toldo: nivel 2."],
	["cocinita", "Cocinita", "Se puede cocinar: arroz y media hora = sopa caliente."],
	["candado", "Candado", "Si duerme en otro lado, nadie le abre la caja."],
	["alarma", "Alarma latas", "Las latas suenan: menos chance de que se metan de noche."],
	["trampa", "Trampa clavos", "El que entra sin avisar sale cojeando: menos robos."],
	["nivel_3", "-> Rancho", "Paredes de estiba: caja más grande, muchos menos robos, más ánimo."],
	["nivel_4", "-> Ranchito", "Techo de zinc y radio: la caja más grande y lo mejor para el ánimo."],
]
## Lo que se compra hecho (no tiene receta): quién lo vende.
const SELLER := "Wilson"

var _cursor := 0
var _root: Control
var _rows: Control
var _detail: Control
var _now: Control
var _after: Control
var _guard := 0.15


static func choose(parent: Node) -> String:
	var ui := CambucheUI.new()
	parent.get_tree().root.add_child(ui)
	var id: String = await ui._closed
	ui.queue_free()
	return id


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_root = Control.new()
	add_child(_root)
	_rect(Vector2.ZERO, Vector2(320, 180), Color(0, 0, 0, 0.5))
	_rect(Vector2(4, 4), Vector2(282, 172), PANEL)
	_frame(Vector2(4, 4), Vector2(282, 172))
	var lvl := GameState.cambuche_level()
	_label("MEJORAR EL CAMBUCHE", Vector2(10, 8), GOLD)
	_label("Nivel %d: %s" % [lvl, GameState.CAMBUCHE_NAMES[lvl]], Vector2(10, 19), DIM)
	_rows = Control.new()
	_root.add_child(_rows)
	_now = Control.new()
	_root.add_child(_now)
	_after = Control.new()
	_root.add_child(_after)
	_detail = Control.new()
	_root.add_child(_detail)
	_label("[E]poner [Q]salir", Vector2(10, 164), DIM)
	# Empieza en lo primero que se puede poner (si hay).
	for i in ENTRIES.size():
		if _state(ENTRIES[i][0]) == "listo":
			_cursor = i
			break
	_refresh()


func _process(delta: float) -> void:
	_guard -= delta


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0:
		return
	if event.is_action_pressed("move_down"):
		_cursor = (_cursor + 1) % ENTRIES.size()
	elif event.is_action_pressed("move_up"):
		_cursor = (_cursor - 1 + ENTRIES.size()) % ENTRIES.size()
	elif event.is_action_pressed("cancel") or event.is_action_pressed("inventory"):
		_close("")
	elif event.is_action_pressed("interact"):
		var id: String = ENTRIES[_cursor][0]
		if _state(id) == "listo":
			_close(id)
		else:
			_flash_detail()
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()


func _close(id: String) -> void:
	GameState.ui_open = false
	GameState.block_input(0.2)
	set_process_unhandled_input(false)
	_closed.emit(id)


# ---------------------------------------------------------------- Estado de cada mejora

## "puesto" (ya lo tiene), "listo" (se puede poner ya), "falta" (le faltan cosas), "bloqueado".
func _state(id: String) -> String:
	var c := GameState.cambuche
	if id.begins_with("nivel_"):
		var n := int(id.substr(6))
		if GameState.cambuche_level() >= n:
			return "puesto"
		if GameState.cambuche_level() < n - 1:
			return "bloqueado"
		for item in Items.EXPANSIONS[n]["needs"]:
			if GameState.count(item) < Items.EXPANSIONS[n]["needs"][item]:
				return "falta"
		return "listo"
	if c.get(id, false):
		return "puesto"
	return "listo" if GameState.count(id) > 0 else "falta"


## Lo que hace falta: [[item, tiene, necesita], ...]. Las mejoras con receta piden los ingredientes
## (se arma con [C] en la mochila); las que se compran, el objeto.
func _needs(id: String) -> Array:
	var out := []
	if id.begins_with("nivel_"):
		var plan: Dictionary = Items.EXPANSIONS[int(id.substr(6))]["needs"]
		for item in plan:
			out.append([item, GameState.count(item), plan[item]])
		return out
	if GameState.count(id) > 0 or not Items.RECIPES.has(id):
		return [[id, GameState.count(id), 1]]
	var rec: Dictionary = Items.RECIPES[id]
	for item in rec:
		out.append([item, GameState.count(item), rec[item]])
	return out


## Cómo queda el cambuche si se pone esto (una copia, para comparar).
func _with(id: String) -> Dictionary:
	var c := GameState.cambuche.duplicate()
	if id.begins_with("nivel_"):
		c[Items.EXPANSIONS[int(id.substr(6))]["flag"]] = true
	elif _state(id) != "puesto":
		c[id] = true
	return c


static func level_of(c: Dictionary) -> int:
	if c.get("zinc", false):
		return 4
	if c.get("paredes", false):
		return 3
	if c.get("toldo", false) and c.get("cobija", false):
		return 2
	return 1


## Caja (lugares), seguridad (0..1) y ánimo de la noche.
static func stats(c: Dictionary) -> Dictionary:
	var lvl := level_of(c)
	var guard := 1.0
	if c.get("alarma", false):
		guard *= 0.75
	if c.get("trampa", false):
		guard *= 0.75
	return {"caja": GameState.BOX_CAPACITY[lvl], "seguridad": 1.0 - GameState.LEVEL_THEFT[lvl] * guard,
		"animo": GameState.LEVEL_MOOD[lvl]}


static func art_of(c: Dictionary) -> String:
	var art: String = ["cambuche", "cambuche", "cambuche_toldo", "rancho", "ranchito"][level_of(c)]
	if art == "cambuche" and c.get("toldo", false):
		art = "cambuche_toldo"
	return art


# ---------------------------------------------------------------- Dibujo

func _refresh() -> void:
	for box in [_rows, _now, _after, _detail]:
		for ch in box.get_children():
			ch.queue_free()
	# La lista.
	for i in ENTRIES.size():
		var e: Array = ENTRIES[i]
		var st := _state(e[0])
		var y := 32 + i * ROW_H
		var sel := i == _cursor
		if sel:
			_rect(Vector2(8, y - 2), Vector2(132, ROW_H), Color(0.9, 0.74, 0.36, 0.25), _rows)
			_rect(Vector2(8, y - 2), Vector2(2, ROW_H), GOLD, _rows)
		var icon_id: String = e[0] if not e[0].begins_with("nivel_") else ("estiba" if e[0] == "nivel_3" else "zinc")
		_icon(icon_id, Vector2(13, y - 2), 0.7, _rows, 1.0 if st != "bloqueado" else 0.35)
		var col: Color = {"puesto": GOOD, "listo": GOLD, "falta": CREAM, "bloqueado": DIM}[st]
		_label(e[1], Vector2(27, y), col, _rows)
		var mark: String = {"puesto": "OK", "listo": "!", "falta": "", "bloqueado": "-"}[st]
		if mark != "":
			_label(mark, Vector2(124 if mark != "OK" else 120, y), col, _rows)
	# AHORA y CON ESTO.
	var id: String = ENTRIES[_cursor][0]
	var now := GameState.cambuche
	var after := _with(id)
	var changed := _state(id) != "puesto"
	_preview(now, Vector2(146, 30), "AHORA", _now)
	_label(">", Vector2(210, 52), GOLD if changed else DIM, _now)
	_preview(after, Vector2(218, 30), "CON ESTO" if changed else "(YA ESTÁ)", _after)
	# Barras: caja, seguridad, ánimo (lo que sube, en verde).
	var a := stats(now)
	var b := stats(after)
	_bar("CAJA", float(a["caja"]) / 10.0, float(b["caja"]) / 10.0, "%d" % b["caja"], Vector2(150, 86))
	_bar("SEGUR.", a["seguridad"], b["seguridad"], "%d%%" % roundi(b["seguridad"] * 100.0), Vector2(150, 98))
	_bar("ÁNIMO", a["animo"] / 10.0, b["animo"] / 10.0, "+%d" % int(b["animo"]), Vector2(150, 110))
	# Lo que se ve en el cambuche: techo, cocina, candado, cobija (prendido si lo tiene).
	var x := 150
	for f in ["toldo", "cocinita", "candado", "cobija", "alarma", "trampa"]:
		var has: bool = after.get(f, false)
		var new: bool = has and not now.get(f, false)
		if new:
			_rect(Vector2(x - 1, 121), Vector2(14, 14), Color(0.45, 0.9, 0.45, 0.5), _detail)
		_icon(f, Vector2(x, 122), 0.75, _detail, 1.0 if has else 0.25)
		x += 16
	# Qué da y qué hace falta.
	_rect(Vector2(8, 138), Vector2(304, 1), Color(0.85, 0.74, 0.5, 0.5), _detail)
	var gives := _label(ENTRIES[_cursor][2], Vector2(10, 141), CREAM, _detail)
	gives.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gives.custom_minimum_size = Vector2(272, 0)
	gives.size = Vector2(272, 20)
	gives.clip_text = true
	gives.max_lines_visible = 2
	gives.add_theme_constant_override("line_spacing", 1)
	_needs_row(id, Vector2(152, 162))


func _needs_row(id: String, at: Vector2) -> void:
	var st := _state(id)
	if st == "puesto":
		_label("PUESTO", at + Vector2(0, 2), GOOD, _detail)
		return
	if st == "bloqueado":
		_label("Antes: nivel %d" % (int(id.substr(6)) - 1), at + Vector2(0, 2), DIM, _detail)
		return
	var x := at.x
	for n in _needs(id):
		_icon(n[0], Vector2(x, at.y - 1), 0.75, _detail)
		var ok: bool = n[1] >= n[2]
		var t := _label("%d/%d" % [mini(n[1], n[2]), n[2]], Vector2(x + 13, at.y + 2), GOOD if ok else BAD, _detail)
		t.add_theme_font_size_override("font_size", 8)
		x += 13 + t.text.length() * 8 + 4
	if st == "falta" and not id.begins_with("nivel_") and Items.RECIPES.has(id):
		_label("[C]", Vector2(x, at.y + 2), DIM, _detail)
	elif st == "falta" and not id.begins_with("nivel_"):
		_label(SELLER, Vector2(x, at.y + 2), DIM, _detail)


func _preview(c: Dictionary, at: Vector2, title: String, parent: Control) -> void:
	_rect(at, Vector2(62, 50), Color(0.2, 0.17, 0.2), parent)
	var tex: Texture2D = load("res://assets/barrio/%s.png" % art_of(c))
	var bed := TextureRect.new()
	bed.texture = tex
	bed.position = at + Vector2(31 - tex.get_width() / 2.0, 46 - tex.get_height())
	parent.add_child(bed)
	# Lo que no cambia el dibujo del cambuche, encima: cobija, candado, latas, trampa.
	for spot in [["cobija", Vector2(30, 33)], ["candado", Vector2(56, 34)], ["alarma", Vector2(4, 6)], ["trampa", Vector2(54, 38)]]:
		if c.get(spot[0], false):
			_icon(spot[0], at + spot[1], 0.6, parent)
	if c.get("cocinita", false):
		var stove := TextureRect.new()
		stove.texture = load("res://assets/barrio/cocinita.png")
		stove.position = at + Vector2(4, 46 - stove.texture.get_height())
		parent.add_child(stove)
	var l := _label(title, at + Vector2(-4, -9), DIM, parent)
	l.size.x = 70
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _bar(title: String, now: float, after: float, value: String, at: Vector2) -> void:
	_label(title, at, DIM, _detail)
	var x := at.x + 52
	var w := 52.0
	_rect(Vector2(x, at.y + 1), Vector2(w, 6), Color(0.2, 0.17, 0.2), _detail)
	_rect(Vector2(x, at.y + 1), Vector2(w * clampf(after, 0, 1), 6), GOOD, _detail)
	_rect(Vector2(x, at.y + 1), Vector2(w * clampf(now, 0, 1), 6), Color(0.85, 0.74, 0.5), _detail)
	_label(value, Vector2(x + w + 4, at.y), GOOD if after > now else CREAM, _detail)


func _flash_detail() -> void:
	var t := create_tween()
	_detail.modulate = Color(1, 0.5, 0.5)
	t.tween_property(_detail, "modulate", Color.WHITE, 0.3)


func _icon(id: String, at: Vector2, scale: float, parent: Control, alpha := 1.0) -> void:
	var path := "res://assets/items/%s.png" % id
	if not ResourceLoader.exists(path):
		return
	var t := TextureRect.new()
	t.texture = load(path)
	t.position = at
	t.scale = Vector2(scale, scale)
	t.modulate.a = alpha
	parent.add_child(t)


func _rect(at: Vector2, size: Vector2, color: Color, parent: Control = null) -> ColorRect:
	var r := ColorRect.new()
	r.position = at
	r.size = size
	r.color = color
	(parent if parent else _root).add_child(r)
	return r


func _frame(at: Vector2, size: Vector2) -> void:
	var b := ReferenceRect.new()
	b.border_color = Color(0.85, 0.74, 0.5, 0.7)
	b.editor_only = false
	b.position = at
	b.size = size
	_root.add_child(b)


func _label(text: String, pos: Vector2, color: Color, parent: Control = null) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	(parent if parent else _root).add_child(l)
	return l
