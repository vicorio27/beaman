extends CanvasLayer
## La libreta: lo que va ganando y lo que falta. Se abre con L (o desde la mochila, o con el botón
## táctil del libro). Páginas (izquierda/derecha): HABILIDADES, SUEÑOS, EL CAMBUCHE, LUKAS, LA GENTE.
## Arriba/abajo elige; el detalle va abajo, en su caja. Atrás (o L) cierra.
## Todo el texto va en cajas fijas con un máximo de renglones (no se monta nada encima de nada), y
## la libreta no pasa de x=286: a la derecha quedan los botones táctiles.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const LEFT := 4.0
const RIGHT := 286.0
const GOLD := Color(0.95, 0.8, 0.45)
const CREAM := Color(0.93, 0.91, 0.87)
const DIM := Color(0.58, 0.55, 0.52)
const GOOD := Color(0.5, 0.88, 0.5)
const PAGES := ["HABILIDADES", "SUEÑOS", "EL CAMBUCHE", "LUKAS", "LA GENTE"]
const LINE := 10.0  # alto de un renglón (8 px de letra + 2)

## Dónde se aprende cada habilidad (pista, si todavía no la tiene).
const SKILL_HINT := {
	"aguante": "El primer sueño, el del camión.",
	"sangre_fria": "El sueño del dealer. Lo despierta volver a existir: ir por la cédula al centro.",
	"labia": "Las carreras. Las despierta tener la cédula en la mano.",
	"rebusque": "El sueño de la oficina. Lo despierta tener trabajo en la obra.",
	"cocinero": "El sueño de la mamá. Lo despierta llamarla desde el teléfono público.",
	"paso_firme": "El torneo de lucha. Lo despierta cruzarse con el papá en la plaza.",
	"lazo_lukas": "La tercera carrera.",
}
## Lo que hace cada una, corto (de día / soñando).
const SKILL_SHORT := {
	"aguante": "De día: el desprecio de la gente baja la mitad de ánimo. Soñando: más vida.",
	"sangre_fria": "De día: más tiempo para reaccionar. Soñando: mejor puntería.",
	"labia": "De día: pedir rinde más y todo sale 10% más barato. Soñando: los jefes dudan.",
	"rebusque": "De día: latas +50% y Lukas olfatea más lejos. Soñando: sueltan más cosas.",
	"cocinero": "De día: lo que cocina en el cambuche llena más. Soñando: la comida cura el doble.",
	"paso_firme": "De día: camina más rápido; el hambre no lo frena. Soñando: más rápido.",
	"lazo_lukas": "Lukas encuentra más cosas escondidas y su compañía levanta más el ánimo.",
}
## Las series de sueños: [nombre, ids, color].
const SERIES := [
	["Lisandro (el dealer)", ["plomo_d1", "plomo_d2", "plomo_d3"], Color(0.85, 0.35, 0.3)],
	["Las carreras", ["carrera1", "carrera2", "carrera3", "carrera4"], Color(0.9, 0.75, 0.3)],
	["La Empresa", ["sigilo1", "sigilo2", "sigilo3", "sigilo4"], Color(0.4, 0.6, 0.9)],
	["El torneo (el papá)", ["lucha1", "lucha2", "lucha3", "lucha4"], Color(0.45, 0.8, 0.45)],
	["La mamá", ["callejon3"], Color(0.75, 0.5, 0.85)],
	["El final", ["final"], Color(0.92, 0.92, 0.92)],
]
## Lo que despierta cada serie (si todavía no empezó).
const WAKE_HINT := {
	"plomo_d1": "Volver a existir: ir al centro por la cédula.",
	"carrera1": "Tener la cédula en la mano.",
	"sigilo1": "Que haya trabajo en la obra.",
	"callejon3": "Llamar a la mamá desde el teléfono público.",
	"lucha1": "Cruzarse con el papá en la plaza.",
	"final": "La verdad en la Defensoría. O el día 44.",
}
## Vínculos: [id, nombre, cómo se gana el favor, qué abre].
const PEOPLE := [
	["german", "Don Germán", "Desde el día 4 se le pierde algo detrás de las bodegas. Lukas lo puede buscar.", "Pan del día, gratis, todos los días."],
	["marta", "Marta", "Desde el día 3 se le pierde el gato. Lukas puede encontrar el collar.", "Le deja usar el baño del café, aunque esté sucio."],
	["samuel", "Samuel", "Desde el día 4 quiere escribirle una carta a su hija. No sabe escribir.", "Le avisa de la gente rara: le roban menos."],
	["rosa", "Doña Rosa", "Desde el día 3, de 8 a 16: ayudarle a despachar en el puesto.", "Le fía una empanada cuando no tiene plata."],
	["wilson", "Wilson", "Compra latas, botellas y cartón. Cuando necesita brazos, avisa.", "Es el que paga. Eso ya es bastante."],
]

var _open := false
var _page := 0
var _cursor := 0
var _root: Control
var _content: Control


func _ready() -> void:
	layer = 17
	add_to_group("libreta")
	_root = Control.new()
	_root.visible = false
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(320, 180)
	_root.add_child(dim)
	var panel := ColorRect.new()
	panel.color = Color(0.07, 0.06, 0.07, 0.97)
	panel.position = Vector2(LEFT, 4)
	panel.size = Vector2(RIGHT - LEFT, 172)
	_root.add_child(panel)
	var frame := ReferenceRect.new()
	frame.border_color = Color(0.85, 0.83, 0.78, 0.35)
	frame.editor_only = false
	frame.position = panel.position + Vector2(2, 2)
	frame.size = panel.size - Vector2(4, 4)
	_root.add_child(frame)
	_content = Control.new()
	_root.add_child(_content)


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		if event.is_action_pressed("libreta") and not GameState.ui_open and not SceneRouter.busy:
			get_viewport().set_input_as_handled()
			open()
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("libreta") or event.is_action_pressed("inventory"):
		close()
	elif event.is_action_pressed("move_right"):
		_page = (_page + 1) % PAGES.size()
		_cursor = 0
	elif event.is_action_pressed("move_left"):
		_page = (_page - 1 + PAGES.size()) % PAGES.size()
		_cursor = 0
	elif event.is_action_pressed("move_down"):
		_cursor += 1
	elif event.is_action_pressed("move_up"):
		_cursor -= 1
	else:
		return
	get_viewport().set_input_as_handled()
	if _open:
		_refresh()


func open() -> void:
	_open = true
	_root.visible = true
	GameState.ui_open = true
	_refresh()


func close() -> void:
	_open = false
	_root.visible = false
	GameState.ui_open = false
	GameState.block_input(0.2)


# ---------------------------------------------------------------- Dibujo

## Una caja de texto fija: nunca pasa de `lines` renglones ni de su ancho.
func _text(text: String, pos: Vector2, width: float, color: Color, lines := 1) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("line_spacing", 2)
	l.clip_text = true
	l.max_lines_visible = lines
	if lines > 1:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_content.add_child(l)
	l.custom_minimum_size = Vector2(width, lines * LINE)
	l.position = pos
	l.size = Vector2(width, lines * LINE)
	return l


func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	_content.add_child(r)
	return r


func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	# Encabezado: LIBRETA a la izquierda, la página a la derecha (cada uno en su mitad).
	_text("LIBRETA", Vector2(10, 9), 72, GOLD)
	var head := _text("%d/%d %s" % [_page + 1, PAGES.size(), PAGES[_page]], Vector2(90, 9), RIGHT - 100, CREAM)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rect(Vector2(10, 20), Vector2(RIGHT - 20, 1), Color(0.85, 0.83, 0.78, 0.3))
	# Pie.
	_rect(Vector2(10, 160), Vector2(RIGHT - 20, 1), Color(0.85, 0.83, 0.78, 0.3))
	_text("<> página  ^v elegir  Q/B cerrar", Vector2(10, 164), RIGHT - 20, DIM)
	match _page:
		0:
			_skills()
		1:
			_dreams()
		2:
			_cambuche()
		3:
			_lukas()
		4:
			_people()


## Lista arriba (renglones de 10) y el detalle abajo, en una caja fija de `detail_lines` renglones.
func _list(rows: Array, top: float) -> void:
	_cursor = clampi(_cursor, 0, rows.size() - 1)
	for i in rows.size():
		var y := top + i * LINE
		if i == _cursor:
			_rect(Vector2(8, y - 1), Vector2(RIGHT - 16, LINE), Color(0.5, 0.12, 0.16, 0.6))
		_text(rows[i][0], Vector2(12, y), 168, rows[i][1])
		if rows[i].size() > 2:
			var r := _text(rows[i][2], Vector2(184, y), RIGHT - 196, rows[i][1])
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _detail(title: String, body: String, top: float, lines: int) -> void:
	_rect(Vector2(10, top - 3), Vector2(RIGHT - 20, 1), Color(0.85, 0.83, 0.78, 0.15))
	var y := top
	if title != "":
		_text(title, Vector2(12, y), RIGHT - 24, GOLD)
		y += LINE + 2
		lines -= 1
	_text(body, Vector2(12, y), RIGHT - 24, CREAM, lines)


func _skills() -> void:
	var rows := []
	for id in Skills.ORDER:
		var has := GameState.has_skill(id)
		rows.append([Skills.name_of(id) if has else "???", GOOD if has else DIM, "OK" if has else ""])
	_text("Se aprenden soñando.", Vector2(12, 25), RIGHT - 24, DIM)
	_list(rows, 37)
	var id: String = Skills.ORDER[_cursor]
	if GameState.has_skill(id):
		_detail(Skills.name_of(id), SKILL_SHORT[id], 113, 4)
	else:
		_detail("Todavía no", "Se aprende en: " + SKILL_HINT[id], 113, 4)


func _dreams() -> void:
	var seen: Array = GameState.flags.get("dreams_seen", [])
	var total := 0
	var have := 0
	for s in SERIES:
		for id in s[1]:
			total += 1
			if id in seen:
				have += 1
	_text("Soñados: %d de %d" % [have, total], Vector2(12, 25), RIGHT - 24, CREAM)
	# Un cuadrito por sueño, del color de su serie.
	var x := 12.0
	for s in SERIES:
		for id in s[1]:
			_rect(Vector2(x, 37), Vector2(10, 7), s[2] if id in seen else Color(0.2, 0.19, 0.2))
			x += 13.0
		x += 4.0
	var rows := []
	for s in SERIES:
		var n := 0
		for id in s[1]:
			if id in seen:
				n += 1
		rows.append([s[0], s[2] if n > 0 else DIM, "%d/%d" % [n, s[1].size()]])
	_list(rows, 50)
	var serie: Array = SERIES[_cursor]
	var first: String = serie[1][0]
	var body := ""
	if first in seen:
		var left := 0
		for id in serie[1]:
			if not id in seen:
				left += 1
		body = "Ya empezó. Faltan %d: vuelven solos, unas noches después." % left if left > 0 else "Terminada."
	else:
		body = "Lo despierta: " + WAKE_HINT.get(first, "algo que todavía no pasó.")
	_detail("Qué la despierta", body, 115, 4)


func _cambuche() -> void:
	if not GameState.has_cambuche():
		_detail("Todavía no tiene", "Tres cartones (o una cama de cartón [C]) y armarlo debajo del puente, donde se despierta.", 30, 5)
		return
	var c := GameState.cambuche
	var lvl := GameState.cambuche_level()
	_text("Nivel %d: %s" % [lvl, GameState.CAMBUCHE_NAMES[lvl]], Vector2(12, 25), RIGHT - 24, CREAM)
	# El dibujo a la izquierda, los números a la derecha.
	_rect(Vector2(12, 38), Vector2(64, 52), Color(0.16, 0.14, 0.16))
	var tex: Texture2D = load("res://assets/barrio/%s.png" % CambucheUI.art_of(c))
	var img := TextureRect.new()
	img.texture = tex
	img.position = Vector2(44 - tex.get_width() / 2.0, 86 - tex.get_height())
	_content.add_child(img)
	var st := CambucheUI.stats(c)
	_text("Caja: %d lugares" % st["caja"], Vector2(86, 40), RIGHT - 96, CREAM)
	_text("Menos robos: %d%%" % roundi(st["seguridad"] * 100.0), Vector2(86, 52), RIGHT - 96, CREAM)
	_text("Animo de noche: +%d" % int(st["animo"]), Vector2(86, 64), RIGHT - 96, CREAM)
	# Lo puesto, con íconos (prendido si lo tiene).
	var x := 86.0
	for u in Items.UPGRADES:
		var ic := TextureRect.new()
		ic.texture = Items.icon(u)
		ic.position = Vector2(x, 76)
		ic.scale = Vector2(0.75, 0.75)
		ic.modulate.a = 1.0 if c.get(u, false) else 0.25
		_content.add_child(ic)
		x += 15.0
	var next := lvl + 1
	var body := ""
	if Items.EXPANSIONS.has(next):
		var need := []
		for id in Items.EXPANSIONS[next]["needs"]:
			need.append("%d %s" % [Items.EXPANSIONS[next]["needs"][id], Items.info(id)["name"].to_lower()])
		body = "%s: %s (Wilson las vende)." % [GameState.CAMBUCHE_NAMES[next], ", ".join(need)]
	elif next == 2:
		body = "Cambuche: toldo y cobija. Se ponen en Mejorar."
	else:
		body = "No hay más. Es un ranchito. Con radio."
	_detail("Siguiente nivel", body, 100, 5)


func _lukas() -> void:
	if not GameState.lukas_alive():
		_detail("Lukas", "Ya no está. Lo que aprendió se quedó con él. Lo que le enseñó a él, también.", 30, 5)
		return
	var state := "Sano."
	if GameState.lukas_sick():
		state = "Enfermo: veterinaria."
	if GameState.lukas_stage() >= 1:
		state = "Tose. Hay que cuidarlo."
	_text("Día %d juntos. %s" % [GameState.day, state], Vector2(12, 25), RIGHT - 24, CREAM)
	var rows := []
	for t in GameState.LUKAS_TRICKS:
		var knows := GameState.lukas_knows(t)
		var sessions := int(GameState.flags.get("truco_" + t, 0))
		rows.append([GameState.LUKAS_TRICKS[t][0], GOOD if knows else DIM, "OK" if knows else "%d/3" % mini(sessions, 3)])
	_list(rows, 37)
	var keys := GameState.LUKAS_TRICKS.keys()
	var t: String = keys[_cursor]
	var how := "Se enseña en su menú: Truco. Una sesión por día; con premio sale seguro."
	_detail(GameState.LUKAS_TRICKS[t][0], GameState.LUKAS_TRICKS[t][1] + ("" if GameState.lukas_knows(t) else " " + how), 85, 7)


func _people() -> void:
	_text("Un favor abre algo con cada uno.", Vector2(12, 25), RIGHT - 24, DIM)
	var rows := []
	for p in PEOPLE:
		var lvl := GameState.bond(p[0])
		rows.append([p[1], GOOD if lvl > 0 else CREAM, "OK" if lvl > 0 else "-"])
	_list(rows, 37)
	var p: Array = PEOPLE[_cursor]
	if GameState.bond(p[0]) > 0:
		_detail("Abierto", p[3], 95, 6)
	else:
		_detail("Cómo", p[2] + " Abre: " + p[3], 95, 6)
