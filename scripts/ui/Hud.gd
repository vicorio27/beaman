extends CanvasLayer
## HUD mínimo de la vida real (spec, sección 9): hambre, plata, ánimo, compañía (soledad) y hora.
## Debajo, la misión principal (siempre a la vista) y cuántas secundarias/opcionales hay (Tab las muestra).
## Aviso en el medio cuando empieza o se cumple una misión.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const SEGMENTS := 10

var _segs: Array[ColorRect] = []
var _company: Array[ColorRect] = []
var _company_bg: ColorRect
var _money: Label
var _dirty: Label
var _mood: TextureRect
const MOOD_ICONS := [preload("res://assets/ui/mood_0.png"), preload("res://assets/ui/mood_1.png"),
	preload("res://assets/ui/mood_2.png"), preload("res://assets/ui/mood_3.png")]
var _dirty_bg: ColorRect
var _clock: Label
var _quest_bg: ColorRect
var _quest: Label
var _others: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 12
	var panel := ColorRect.new()
	panel.color = Color(0.08, 0.06, 0.09, 0.55)
	panel.position = Vector2(2, 2)
	panel.size = Vector2(156, 14)
	add_child(panel)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/items/pan.png")
	icon.position = Vector2(3, 1)
	add_child(icon)
	for i in SEGMENTS:
		var s := ColorRect.new()
		s.position = Vector2(21 + i * 6, 5)
		s.size = Vector2(5, 6)
		add_child(s)
		_segs.append(s)
	_money = _label(Vector2(84, 5))
	_mood = TextureRect.new()
	_mood.position = Vector2(143, 3)
	add_child(_mood)
	# Aviso de higiene: aparece cuando está sucio (algunos negocios no lo atienden).
	_dirty_bg = ColorRect.new()
	_dirty_bg.color = Color(0.08, 0.06, 0.09, 0.55)
	_dirty_bg.position = Vector2(160, 2)
	_dirty_bg.size = Vector2(46, 14)
	add_child(_dirty_bg)
	_dirty = _label(Vector2(163, 5))
	_dirty.text = "SUCIO"
	_dirty.add_theme_color_override("font_color", Color(0.62, 0.7, 0.36))
	# Compañía (lo contrario de la soledad): baja sola; sube hablando con gente o con Lukas.
	_company_bg = ColorRect.new()
	_company_bg.color = panel.color
	_company_bg.position = Vector2(208, 2)
	_company_bg.size = Vector2(64, 14)
	add_child(_company_bg)
	var cicon := TextureRect.new()
	cicon.texture = load("res://assets/ui/compania.png")
	cicon.position = Vector2(210, 3)
	add_child(cicon)
	for i in 8:
		var c := ColorRect.new()
		c.position = Vector2(226 + i * 5, 5)
		c.size = Vector2(4, 6)
		add_child(c)
		_company.append(c)
	var clock_bg := ColorRect.new()
	clock_bg.color = panel.color
	clock_bg.position = Vector2(274, 2)
	clock_bg.size = Vector2(44, 14)
	add_child(clock_bg)
	_clock = _label(Vector2(277, 5))
	_quest_bg = ColorRect.new()
	_quest_bg.color = Color(0.08, 0.06, 0.09, 0.55)
	_quest_bg.position = Vector2(2, 18)
	_quest_bg.size = Vector2(316, 12)
	add_child(_quest_bg)
	_quest = _label(Vector2(5, 20))
	_quest.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	_others = _label(Vector2(250, 20))
	_others.size = Vector2(66, 10)
	_others.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_others.add_theme_color_override("font_color", Color(0.7, 0.68, 0.64))
	_toast = _label(Vector2(0, 40))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.size = Vector2(Controls.right_edge(), 24)  # la franja derecha: botones táctiles
	_toast.add_theme_constant_override("outline_size", 3)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	# Con fondo: así no se mezcla con los letreros del mapa ("ARMAR", "PESCAR") que queden detrás.
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.05, 0.85)
	bg.content_margin_top = 2
	bg.content_margin_bottom = 2
	_toast.add_theme_stylebox_override("normal", bg)
	_toast.modulate.a = 0.0
	_toast.add_to_group("under_dialogue")  # con un diálogo abierto, la cara del que habla le quedaba encima
	GameState.quest_changed.connect(_on_quest_changed)
	GameState.skill_learned.connect(_show_skill)
	GameState.bond_changed.connect(_show_bond)
	if GameState.flags.has("skill_toast"):
		_show_skill.call_deferred(GameState.flags["skill_toast"])
	GameState.inventory_changed.connect(_refresh)
	GameState.hunger_changed.connect(func(_v): _refresh())
	GameState.money_changed.connect(func(_v): _refresh())
	GameState.hygiene_changed.connect(func(_v): _refresh())
	GameState.mood_changed.connect(func(_v): _refresh())
	GameState.loneliness_changed.connect(func(_v): _refresh())
	_refresh()


func _label(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	add_child(l)
	return l


## La plata no salta: rueda hasta el número nuevo, dorada si entró y roja si salió.
var _shown_money := -1.0
var _money_tween: Tween


func _roll_money(to: int) -> void:
	if _shown_money < 0.0:
		_shown_money = float(to)
		_money.text = "$%d" % to
		return
	if int(_shown_money) == to:
		return
	if _money_tween:
		_money_tween.kill()
	var up := float(to) > _shown_money
	_money.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if up else Color(1.0, 0.5, 0.45))
	_money_tween = create_tween()
	_money_tween.tween_method(func(v: float) -> void:
		_shown_money = v
		_money.text = "$%d" % int(round(v)), _shown_money, float(to), 0.7).set_ease(Tween.EASE_OUT)
	_money_tween.tween_callback(func() -> void: _money.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))).set_delay(0.25)


func _process(_delta: float) -> void:
	_clock.text = TimeManager.clock_text()
	_hide_world_texts()


## Ningún texto encima de otro: lo que se escribe en la calle (lo que dice la gente, los avisos de
## HABLAR, el pito de los carros, "+$5.000": el grupo "texto_mundo") no se ve mientras quede debajo de la
## barra de arriba, del aviso del centro, del narrador, del diálogo o del celular.
func _hide_world_texts() -> void:
	var busy: Array[Rect2] = [Rect2(0, 0, 320, 31)]
	if _toast.modulate.a > 0.02:
		busy.append(Rect2(_toast.position, _toast.size))
	if Narrator._panel and Narrator._panel.visible:
		busy.append(Narrator._panel.get_global_rect())
	if Dialogue.active and Dialogue._box:
		busy.append(Dialogue._box.get_global_rect().grow_side(SIDE_TOP, 14.0))
	if Phone.ringing():
		busy.append(Rect2(176, 108, 112, 52))
	for n in get_tree().get_nodes_in_group("texto_mundo"):
		var lab := n as Label
		if lab == null or not lab.is_inside_tree():
			continue
		var xf := lab.get_global_transform_with_canvas()
		var r := Rect2(xf.origin, lab.size * xf.get_scale())
		var hit := false
		for b in busy:
			if b.intersects(r):
				hit = true
				break
		lab.self_modulate.a = 0.0 if hit else 1.0


func _refresh() -> void:
	var filled := ceili(GameState.hunger / (100.0 / SEGMENTS))
	var low := GameState.hunger < 40.0
	for i in SEGMENTS:
		_segs[i].color = (Color(0.86, 0.36, 0.26) if low else Color(0.9, 0.74, 0.36)) if i < filled else Color(0.25, 0.22, 0.24)
	_roll_money(GameState.money)
	_mood.texture = MOOD_ICONS[GameState.mood_level()]
	var company := 100.0 - GameState.loneliness
	var lit := ceili(company / (100.0 / 8))
	var lonely := GameState.is_lonely()
	for i in 8:
		_company[i].color = (Color(0.5, 0.62, 0.9) if lonely else Color(0.62, 0.82, 0.96)) if i < lit else Color(0.25, 0.22, 0.24)
	_dirty.visible = GameState.is_dirty()
	_dirty_bg.visible = _dirty.visible
	var main := GameState.main_quest()
	var others := GameState.active_quests("side").size() + GameState.active_quests("optional").size()
	_quest.text = ("> " + Quests.title(main) + Quests.progress_text(main)) if main != "" else ""
	_others.text = ("+%d Tab" % others) if others > 0 else ""
	_quest_bg.visible = _quest.text != "" or _others.text != ""


func _on_quest_changed(id: String, status: String) -> void:
	_refresh()
	var head: String = "MISION CUMPLIDA" if status == "done" else ("NUEVA MISION" if Quests.kind(id) == "main" else "NUEVA " + Quests.KIND_LABEL[Quests.kind(id)])
	_toast.text = head + "\n" + Quests.title(id)
	_toast.add_theme_color_override("font_color", Color(0.6, 0.95, 0.6) if status == "done" else Color(1, 0.85, 0.4))
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


## Habilidad nueva: el aviso grande y, abajo, qué hace.
func _show_skill(id: String) -> void:
	GameState.flags.erase("skill_toast")
	await get_tree().create_timer(2.5).timeout
	_toast.text = "HABILIDAD NUEVA\n" + Skills.name_of(id).to_upper()
	_toast.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(3.5)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
	Narrator.say(Skills.desc(id) + " (Libreta: L)")


## Vínculo más fuerte con alguien.
func _show_bond(id: String, level: int) -> void:
	await get_tree().create_timer(1.0).timeout
	var who: String = GameState.BOND_NAMES.get(id, id)
	for a in [["Á", "A"], ["É", "E"], ["Í", "I"], ["Ó", "O"], ["Ú", "U"]]:  # la fuente no tiene mayúsculas con tilde
		who = who.to_upper().replace(a[0], a[1])
	_toast.text = "LAZO MAS FUERTE\n%s %d/3" % [who.to_upper(), level]
	_toast.add_theme_color_override("font_color", Color(1.0, 0.7, 0.8))
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(3.0)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
