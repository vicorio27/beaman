class_name PeleaPerros
extends CanvasLayer
## Cuando Lukas y un perro de la calle se agarran: una pelea por turnos, como las de Pokémon.
## Arriba a la derecha el otro perro (su nombre, su nivel, su vida); abajo a la izquierda Lukas (su
## nivel, su vida y su experiencia). Él no pelea: le hace señas a Lukas (los ataques), como con los trucos.
##   var r := await PeleaPerros.fight(self, "dog_a_176_186", textura)   # "amigo", "enemigo" o "huyo"
## Cómo termina decide qué es ese perro de ahí en adelante:
##   - AMIGO: si Lukas se lo gana (Ojitos, la pata, saludar: la barra de AMISTAD llena). Cuando lo vea,
##     juegan y Lukas se pone contento.
##   - ENEMIGO: si lo vence a mordiscos, o si pierde. De ahí en adelante le gruñe y no los deja pasar.
##   - Huir (o hacerse el muerto): no pasa nada; otro día se vuelven a ver.
## Lukas gana experiencia y sube de nivel (flags lukas_xp; nivel: lukas_level()); con el nivel aprende
## ataques. Los trucos que ya sabe también sirven aquí. Si le dan duro, sale herido (cojea ese día).

signal _done(result: String)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const INK := Color(0.1, 0.08, 0.1)
const PAPER := Color(0.96, 0.94, 0.88)
const GOLD := Color(0.95, 0.78, 0.4)
const NAMES := ["Firulais", "Canelo", "Tyson", "La Niña", "Pecas", "Rocky", "Mechas", "Lupe", "Sultán", "Paquita",
	"Chester", "Manchas", "El Negro", "Princesa", "Bruno"]
## Experiencia para cada nivel (nivel 1 = 0).
const LEVELS := [0, 20, 50, 90, 140]
## Los ataques: [nombre, desde qué nivel (o truco), qué hace, valor, puntería, lo que dice].
const MOVES := {
	"mordisco": ["Mordisco", 1, "dano", 7, 0.92, "(Le hace la seña: los dientes. Lukas muerde.)"],
	"ladrido": ["Ladrido", 1, "asusta", 0.25, 1.0, "(Lukas ladra con todo el pecho. El otro baja las orejas.)"],
	"revolcon": ["Revolcón", 2, "fuerte", 13, 0.72, "(Lukas se le tira encima y ruedan. En la tierra, gana el que se ensucia más.)"],
	"ojitos": ["Ojitos", 3, "amistad", 30, 1.0, "(Lukas se sienta y lo mira con esos ojos. Los de la caja de zapatos.)"],
	"aullido": ["Aullido", 4, "cura", 9, 1.0, "(Lukas aúlla. Él también, por dentro. Algo se le pasa a los dos.)"],
	"sentarse": ["Sentarse", "sentarse", "defensa", 0.5, 1.0, "(Palma abajo: Lukas se sienta. El otro no sabe qué hacer con un perro sentado.)"],
	"pata": ["La pata", "pata", "amistad", 25, 1.0, "(Mano abierta: Lukas le da la pata. Al otro perro. El otro la huele, desconfiado.)"],
	"saludar": ["Saludar", "saludar", "amistad", 35, 1.0, "(Lukas se para en dos patas y le mueve las de adelante. Al otro se le escapa la cola.)"],
	"muerto": ["Muerto", "muerto", "huir", 0, 1.0, "(Dedo en pistola: Lukas se tira de lado. El otro lo olfatea, pierde el interés y se va.)"],
}
## Lo del otro perro: [nombre, qué hace, valor, puntería, lo que dice (%s: su nombre)].
const FOE_MOVES := [
	["muerde", "dano", 6, 0.85, "(%s muerde.)"],
	["ladra", "asusta", 0.2, 1.0, "(%s ladra. Lukas da un paso atrás, sin querer.)"],
	["embiste", "fuerte", 10, 0.6, "(%s se le tira encima con todo.)"],
]

var dog_id := ""
var dog_tex: Texture2D
var _foe_name := ""
var _foe_level := 1
var _foe_hp := 0.0
var _foe_max := 0.0
var _foe_atk := 1.0     # baja con los ladridos
var _my_hp := 0.0
var _my_max := 0.0
var _my_atk := 1.0
var _my_def := 1.0
var _amistad := 0.0
var _hurt := false      # le dieron duro: sale cojeando
var _cursor := 0
var _moves: Array = []
var _choosing := false
var _root: Control
var _text: Label
var _menu: Control
var _foe_bar: ColorRect
var _my_bar: ColorRect
var _xp_bar: ColorRect
var _love_bar: ColorRect
var _foe_hp_label: Label
var _my_hp_label: Label
var _foe_spr: TextureRect
var _me_spr: TextureRect


## El nivel de Lukas (1..5), por la experiencia.
static func lukas_level() -> int:
	var xp := int(GameState.flags.get("lukas_xp", 0))
	var lv := 1
	for i in LEVELS.size():
		if xp >= LEVELS[i]:
			lv = i + 1
	return lv


static func dog_name(id: String) -> String:
	return NAMES[absi(hash(id)) % NAMES.size()]


static func fight(parent: Node, id: String, tex: Texture2D) -> String:
	var ui := PeleaPerros.new()
	ui.dog_id = id
	ui.dog_tex = tex
	parent.get_tree().root.add_child(ui)
	var r: String = await ui._done
	ui.queue_free()
	return r


func _ready() -> void:
	layer = 16
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_foe_name = dog_name(dog_id)
	_foe_level = clampi(1 + absi(hash(dog_id + "nv")) % 3 + GameState.day / 18, 1, 5)
	_foe_max = 16.0 + _foe_level * 6.0
	_foe_hp = _foe_max
	var lv := lukas_level()
	_my_max = 18.0 + lv * 6.0
	_my_hp = _my_max
	_my_atk = 1.0 + (lv - 1) * 0.15
	if GameState.flags.get("lukas_fed_day", -1) != GameState.day:
		_my_atk *= 0.75  # con hambre pelea peor
	for id in MOVES:
		var need = MOVES[id][1]
		if (need is int and lv >= need) or (need is String and GameState.lukas_knows(need)):
			_moves.append(id)
	_moves.append("huir")
	_build()
	_run()


func _build() -> void:
	_root = Control.new()
	add_child(_root)
	# El fondo: el andén de la pelea (cielo arriba, la calle abajo).
	var sky := ColorRect.new()
	sky.size = Vector2(320, 180)
	sky.color = Color(0.62, 0.74, 0.82)
	_root.add_child(sky)
	var ground := ColorRect.new()
	ground.position = Vector2(0, 70)
	ground.size = Vector2(320, 110)
	ground.color = Color(0.56, 0.5, 0.42)
	_root.add_child(ground)
	for spot in [[Vector2(206, 74), Vector2(84, 14)], [Vector2(22, 118), Vector2(110, 16)]]:  # las tarimas
		var e := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.46, 0.4, 0.33)
		sb.set_corner_radius_all(8)
		e.add_theme_stylebox_override("panel", sb)
		e.position = spot[0]
		e.size = spot[1]
		_root.add_child(e)
	# El otro perro (arriba a la derecha) y Lukas (abajo a la izquierda, su retrato).
	_foe_spr = TextureRect.new()
	_foe_spr.texture = dog_tex
	_foe_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_foe_spr.scale = Vector2(3, 3)
	_foe_spr.flip_h = true
	_foe_spr.position = Vector2(218, 40)
	_root.add_child(_foe_spr)
	_me_spr = TextureRect.new()
	_me_spr.texture = _face("lukas_ladra")
	_me_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_me_spr.position = Vector2(30, 46)
	_me_spr.scale = Vector2(0.8, 0.8)
	_root.add_child(_me_spr)
	# Las cajitas: nombre, nivel, vida (y la experiencia y la amistad).
	_box(Vector2(8, 6), Vector2(150, 40))
	_label("%s  Nv%d" % [_foe_name.to_upper(), _foe_level], Vector2(14, 10), INK)
	_foe_bar = _bar(Vector2(14, 22), 136, Color(0.3, 0.75, 0.35))
	_foe_hp_label = _label("", Vector2(14, 28), INK)
	_love_bar = _bar(Vector2(14, 40), 136, Color(0.9, 0.45, 0.6), 2)
	_box(Vector2(170, 92), Vector2(142, 40))
	_label("LUKAS  Nv%d" % lukas_level(), Vector2(176, 96), INK)
	_my_bar = _bar(Vector2(176, 108), 128, Color(0.3, 0.75, 0.35))
	_my_hp_label = _label("", Vector2(176, 114), INK)
	_xp_bar = _bar(Vector2(176, 126), 128, Color(0.35, 0.55, 0.95), 2)
	# Abajo: lo que pasa, o el menú.
	_box(Vector2(4, 136), Vector2(312, 42))
	_text = _label("", Vector2(10, 141), INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size = Vector2(300, 34)
	_menu = Control.new()
	_root.add_child(_menu)
	_refresh_bars()


func _face(id: String) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/portraits/%s.png" % id)
	at.region = Rect2(0, 0, 96, 90)
	return at


func _box(at: Vector2, size: Vector2) -> void:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", sb)
	p.position = at
	p.size = size
	_root.add_child(p)


func _bar(at: Vector2, w: float, col: Color, h := 4) -> ColorRect:
	var back := ColorRect.new()
	back.position = at
	back.size = Vector2(w, h)
	back.color = Color(0.3, 0.28, 0.3)
	_root.add_child(back)
	var b := ColorRect.new()
	b.position = at
	b.size = Vector2(w, h)
	b.color = col
	b.set_meta("w", w)
	_root.add_child(b)
	return b


func _label(t: String, at: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	_root.add_child(l)
	return l


func _refresh_bars() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(_foe_bar, "size:x", float(_foe_bar.get_meta("w")) * clampf(_foe_hp / _foe_max, 0, 1), 0.35)
	tw.tween_property(_my_bar, "size:x", float(_my_bar.get_meta("w")) * clampf(_my_hp / _my_max, 0, 1), 0.35)
	tw.tween_property(_love_bar, "size:x", float(_love_bar.get_meta("w")) * clampf(_amistad / 100.0, 0, 1), 0.35)
	var lv := lukas_level()
	var xp := int(GameState.flags.get("lukas_xp", 0))
	var lo: int = LEVELS[lv - 1]
	var hi: int = LEVELS[lv] if lv < LEVELS.size() else lo + 1
	tw.tween_property(_xp_bar, "size:x", float(_xp_bar.get_meta("w")) * clampf(float(xp - lo) / (hi - lo), 0, 1), 0.35)
	_foe_hp_label.text = "VIDA %d/%d" % [ceili(_foe_hp), int(_foe_max)]
	_my_hp_label.text = "VIDA %d/%d" % [ceili(_my_hp), int(_my_max)]


## Escribe una línea y espera el botón.
func _say(t: String) -> void:
	_menu.visible = false
	_text.text = t
	_text.visible_characters = 0
	var tw := create_tween()
	tw.tween_property(_text, "visible_characters", t.length(), t.length() * 0.018)
	await tw.finished
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("cancel"):
			break


func _run() -> void:
	await _say("(¡%s, el perro de esta cuadra, no deja pasar a Lukas!)" % _foe_name)
	await _say("(Él no pelea. Le hace señas a Lukas, como con los trucos. ¿Qué le pide?)")
	while true:
		var id := await _choose()
		var r := await _turn(id)
		if r != "":
			await _end(r)
			return
		r = await _foe_turn()
		if r != "":
			await _end(r)
			return


## El menú: dos columnas. Devuelve el ataque elegido.
func _choose() -> String:
	for c in _menu.get_children():
		c.queue_free()
	_text.text = ""
	_menu.visible = true
	var labels := []
	for i in _moves.size():
		var id: String = _moves[i]
		var l := Label.new()
		l.position = Vector2(14 + (i % 3) * 102, 141 + (i / 3) * 12)
		l.add_theme_font_override("font", FONT)
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", INK)
		_menu.add_child(l)
		labels.append([l, "Huir" if id == "huir" else MOVES[id][0]])
	_choosing = true
	while true:
		for i in labels.size():
			labels[i][0].text = ("> " if i == _cursor else "  ") + labels[i][1]
			labels[i][0].add_theme_color_override("font_color", Color(0.65, 0.15, 0.2) if i == _cursor else INK)
		await get_tree().process_frame
		var n := _moves.size()
		if Input.is_action_just_pressed("move_right"):
			_cursor = (_cursor + 1) % n
		elif Input.is_action_just_pressed("move_left"):
			_cursor = (_cursor - 1 + n) % n
		elif Input.is_action_just_pressed("move_down"):
			_cursor = mini(_cursor + 3, n - 1)
		elif Input.is_action_just_pressed("move_up"):
			_cursor = maxi(_cursor - 3, 0)
		elif Input.is_action_just_pressed("interact"):
			break
	_choosing = false
	return _moves[_cursor]


func _lunge(spr: TextureRect, dir: Vector2) -> void:
	var p0 := spr.position
	var t := create_tween()
	t.tween_property(spr, "position", p0 + dir * 18.0, 0.1)
	t.tween_property(spr, "position", p0, 0.15)
	await t.finished


func _flash(spr: TextureRect) -> void:
	var t := create_tween()
	for k in 3:
		t.tween_property(spr, "modulate:a", 0.2, 0.06)
		t.tween_property(spr, "modulate:a", 1.0, 0.06)
	await t.finished


## El turno de Lukas. Devuelve "" (sigue), o cómo terminó.
func _turn(id: String) -> String:
	if id == "huir":
		if randf() < 0.7:
			await _say("(Silbido. Lukas da media vuelta y se viene. El otro le ladra a la espalda, por orgullo.)")
			return "huyo"
		await _say("(Silbido. Lukas no lo oye: está ocupado. Los perros también tienen orgullo.)")
		return ""
	var m: Array = MOVES[id]
	_me_spr.texture = _face("lukas_truco" if m[1] is String else ("lukas_escucha" if m[2] == "amistad" else "lukas_ladra"))
	await _say(m[5])
	match m[2]:
		"dano", "fuerte":
			await _lunge(_me_spr, Vector2(1, -0.5))
			if randf() > m[4]:
				await _say("(Muerde aire. El aire no se queja.)")
				return ""
			var dmg: float = m[3] * _my_atk * randf_range(0.85, 1.15)
			_foe_hp -= dmg
			await _flash(_foe_spr)
			_refresh_bars()
			if m[2] == "fuerte":
				_my_hp -= 2.0
				_refresh_bars()
			if _foe_hp <= 0.0:
				return "vencio"
		"asusta":
			_foe_atk = maxf(0.4, _foe_atk - m[3])
			await _lunge(_me_spr, Vector2(0.5, 0))
		"amistad":
			var gain: float = m[3] * (1.4 - _foe_hp / _foe_max * 0.6)  # cansado, se deja querer más
			_amistad += gain
			_refresh_bars()
			if _amistad >= 100.0:
				return "amigo"
			await _say("(A %s se le mueve la cola. Poquito. Él lo nota. Lukas también.)" % _foe_name)
		"cura":
			_my_hp = minf(_my_max, _my_hp + m[3])
			_my_def = 0.8
			_refresh_bars()
		"defensa":
			_my_def = m[3]
		"huir":
			return "huyo"
	return ""


func _foe_turn() -> String:
	var mv: Array = FOE_MOVES.pick_random()
	if _amistad > 50.0 and randf() < 0.35:
		await _say("(%s lo mira. Ya no sabe si pelear o jugar. Se rasca una oreja para pensar.)" % _foe_name)
		return ""
	await _say(mv[4] % _foe_name)
	if mv[1] == "asusta":
		_my_atk = maxf(0.5, _my_atk - mv[2])
		return ""
	await _lunge(_foe_spr, Vector2(-1, 0.5))
	if randf() > mv[3]:
		await _say("(Lukas lo esquiva. De viejo, pero lo esquiva.)")
		return ""
	var dmg: float = mv[2] * (1.0 + (_foe_level - 1) * 0.15) * _foe_atk * _my_def * randf_range(0.85, 1.15)
	var crit := randf() < 0.12
	if crit:
		dmg *= 1.7
		_hurt = true
	_my_hp -= dmg
	_my_def = 1.0
	_me_spr.texture = _face("lukas_triste")
	await _flash(_me_spr)
	_refresh_bars()
	if crit:
		await _say("(¡Le dio duro! Lukas se queja. Ese aullido se lo va a acordar él toda la noche.)")
	if _my_hp <= 0.0:
		return "perdio"
	return ""


func _end(how: String) -> void:
	var f := GameState.flags
	var gain := 0
	var result := "huyo"
	match how:
		"amigo":
			_me_spr.texture = _face("lukas_feliz")
			await _say("(%s y Lukas se huelen la cola. Ya está: son amigos. Así de fácil es, para ellos.)" % _foe_name)
			gain = 8 + _foe_level * 6
			result = "amigo"
		"vencio":
			_me_spr.texture = _face("lukas_ladra")
			await _say("(%s se va con la cola entre las patas. Se va, pero se acuerda. Los perros se acuerdan.)" % _foe_name)
			gain = 6 + _foe_level * 5
			result = "enemigo"
		"perdio":
			_me_spr.texture = _face("lukas_triste")
			_hurt = true
			await _say("(Lukas pierde. Se le esconde detrás de las piernas. Él lo carga. %s se queda con la cuadra.)" % _foe_name)
			gain = 3
			result = "enemigo"
		"huyo":
			gain = 1
	var lv0 := lukas_level()
	f["lukas_xp"] = int(f.get("lukas_xp", 0)) + gain
	_refresh_bars()
	await _say("(Lukas gana %d de experiencia.)" % gain)
	var lv := lukas_level()
	if lv > lv0:
		_me_spr.texture = _face("lukas_truco")
		var learned := []
		for id in MOVES:
			if MOVES[id][1] is int and MOVES[id][1] == lv:
				learned.append(MOVES[id][0])
		await _say("(¡Lukas sube a nivel %d!%s)" % [lv, (" Aprende: %s." % ", ".join(learned)) if not learned.is_empty() else ""])
	if _hurt:
		f["lukas_herido"] = GameState.day
		GameState.change_mood(-3.0)
	GameState.ui_open = false
	GameState.block_input(0.3)
	_done.emit(result)
