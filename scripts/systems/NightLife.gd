extends Node
## La ciudad de noche (de 20:00 a 5:30). Lo agrega Location en los lugares de afuera, al lado de DayNight.
##   - Lo de día se va: los pelados del fútbol, las palomas, los vendedores, los del ajedrez.
##   - Sale la gente de noche (npc_id "noche_*", lo que dicen está en Conversations._noche):
##     el celador con la linterna, el de los perros calientes, los de la cerveza en el kiosco,
##     la pareja de la banca, el que fuma en la puerta del billar, la señora del tinto.
##   - Se apagan las cosas: la panadería y el café cierran (se apaga la vidriera), la tele de TV RADIO.
##   - Se prenden otras: ventanas en las casas (y se van apagando hacia la una), el letrero del billar
##     (de día es un letrero gris que nadie mira), el bombillo del carrito de los perros.

const NIGHT_FROM := 20.0
const NIGHT_TO := 5.5

## Lo que solo está de día (por el comienzo del nombre del nodo).
const DAY_ONLY := {
	"City": ["pelaos_"],
	"Parque": ["palomas_", "Servicio_palomas", "Fabiola", "Leonor", "Efrain", "Viejos", "Viejo 2", "Aurelio"],
}
## Gente de noche: [npc_id, fila, posición, mira, ruta (opcional)].
const NIGHT_PEOPLE := {
	"City": [
		["noche_celador", 12, Vector2(430, 282), "down", [Vector2(430, 282), Vector2(780, 282)]],
		["noche_perros", 9, Vector2(628, 424), "down", []],
		["noche_kiosco", 9, Vector2(380, 556), "right", []],
		["noche_kiosco2", 15, Vector2(408, 556), "left", []],
		["noche_pareja", 15, Vector2(562, 501), "down", []],
		["noche_billar", 6, Vector2(792, 200), "down", []],
	],
	"Parque": [
		["noche_tinto", 3, Vector2(530, 380), "down", []],
		["noche_pareja", 15, Vector2(254, 281), "down", []],
		["noche_celador", 12, Vector2(150, 312), "down", [Vector2(150, 312), Vector2(700, 312)]],
	],
}
## Negocios que cierran: prefijo -> hora en que se apaga. Cerrado, la vidriera queda oscura.
const CLOSES := {"bakery": 21.0, "cafe": 22.0, "electro_a": 20.0, "tienda": 22.0, "flores": 19.0, "foto_express": 19.0}
## Letreros que se prenden de noche: [texto, posición, color].
const NEON := {
	"City": [["BILLAR EL GUAYABO", Vector2(752, 148), Color(1.0, 0.35, 0.75)]],
	"Parque": [],
}

var _scene: Node
var _world: Node
var _night := false
var _first := true
var _hidden: Array = []      # [nodo, capa de colisión] de lo que se fue
var _people: Array = []      # la gente de noche que está afuera
var _windows: Array = []     # [luz, hora en que se apaga]
var _shops: Array = []       # [nodo, hora de cierre, luces que tenía]
var _neon: Array = []        # [letrero, luz]
var _bulb: PointLight2D
var _check := 0.0
var _glow: GradientTexture2D


func _ready() -> void:
	_scene = get_parent()
	_world = _scene.get_node_or_null("World")
	if _world == null:
		_world = _scene
	_glow = _glow_texture()
	_setup.call_deferred()


func _setup() -> void:
	var rng := RandomNumberGenerator.new()
	for n in _world.find_children("*", "", false, false):
		var nm := str(n.name)
		if nm.begins_with("house_") and n is Sprite2D:
			# La ventana: una luz chiquita y tibia. Cada casa se apaga a su hora (siempre la misma).
			rng.seed = hash(nm)
			if rng.randf() < 0.75:
				var l := PointLight2D.new()
				l.texture = _glow
				l.texture_scale = 0.45
				l.color = Color(1.0, 0.78, 0.42)
				l.position = Vector2(rng.randf_range(-8, 8), -14)
				l.enabled = false
				n.add_child(l)
				_windows.append([l, rng.randf_range(22.5, 25.5)])
		for prefix in CLOSES:
			if nm.begins_with(prefix) and n is CanvasItem:
				_shops.append([n, CLOSES[prefix]])
	for spec in NEON.get(_scene.name, []):
		var lab := Label.new()
		lab.text = spec[0]
		lab.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
		lab.add_theme_font_size_override("font_size", 8)
		lab.add_theme_constant_override("outline_size", 2)
		lab.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.08))
		lab.size = Vector2(spec[0].length() * 8, 10)
		lab.position = spec[1] - Vector2(lab.size.x / 2.0, 0)
		lab.z_index = 3
		_world.add_child(lab)
		var l := PointLight2D.new()
		l.texture = _glow
		l.texture_scale = 1.4
		l.color = spec[2]
		l.position = spec[1] + Vector2(0, 4)
		l.enabled = false
		_world.add_child(l)
		_neon.append([lab, l, spec[2]])
	var cart := _world.find_child("food_cart*", false, false) as Node2D
	if cart:
		_bulb = PointLight2D.new()  # el bombillo del carrito de los perros calientes
		_bulb.texture = _glow
		_bulb.texture_scale = 0.9
		_bulb.color = Color(1.0, 0.9, 0.6)
		_bulb.position = Vector2(0, -26)
		_bulb.enabled = false
		cart.add_child(_bulb)
	_apply()


func _process(delta: float) -> void:
	_check -= delta
	if _neon.size() > 0 and _night:
		# El neón titila (una letra del billar está mala, como debe ser).
		var t := Time.get_ticks_msec() / 1000.0
		var on := fmod(t, 4.3) > 0.25 and fmod(t, 4.3) < 4.0 or fmod(t * 7.0, 1.0) > 0.5
		for nn in _neon:
			nn[0].add_theme_color_override("font_color", nn[2] if on else nn[2].darkened(0.6))
			nn[1].energy = 1.3 if on else 0.4
	if _check > 0.0:
		return
	_check = 0.5
	_apply()


func _hour() -> float:
	return fmod(TimeManager.minutes / 60.0, 24.0)


func _apply() -> void:
	var h := _hour()
	var night := h >= NIGHT_FROM or h < NIGHT_TO
	if night != _night or _first:
		_night = night
		_first = false
		_switch(night)
	# Las ventanas: de noche, prendidas hasta la hora de cada casa (pasada la medianoche, h + 24).
	var hh := h + (24.0 if h < 12.0 else 0.0)
	var dark := h >= 19.0 or h < 6.0
	for w in _windows:
		w[0].enabled = dark and hh < w[1]
		w[0].energy = 0.8
	# Los negocios: abiertos de 6 a su hora; cerrados, la vidriera apagada.
	for s in _shops:
		var node: CanvasItem = s[0]
		if not is_instance_valid(node):
			continue
		var closed: bool = h >= s[1] or h < 6.0
		node.self_modulate = Color(0.55, 0.55, 0.65) if closed else Color.WHITE
		for c in node.get_children():
			if c is PointLight2D:
				c.visible = not closed
		if node is AnimatedSprite2D:
			if closed:
				node.pause()
			elif not node.is_playing():
				node.play()
	for nn in _neon:
		nn[1].enabled = night
		if not night:
			nn[0].add_theme_color_override("font_color", Color(0.45, 0.42, 0.45))  # de día: un letrero viejo
	if _bulb:
		_bulb.enabled = night
		_bulb.energy = 1.0


## Cambia de día a noche (o al revés): se va la gente de día, sale la de noche.
func _switch(night: bool) -> void:
	if night:
		for prefix in DAY_ONLY.get(_scene.name, []):
			for n in _world.find_children(prefix + "*", "", false, false):
				_hide(n)
		for spec in NIGHT_PEOPLE.get(_scene.name, []):
			_people.append(_spawn(spec))
		GameState.flags["noche_vista"] = true
	else:
		for e in _hidden:
			var n: Node = e[0]
			if is_instance_valid(n):
				n.visible = true
				n.process_mode = Node.PROCESS_MODE_INHERIT
				if n is CollisionObject2D:
					n.collision_layer = e[1]
				if n is Area2D:
					n.set_deferred("monitoring", true)
		_hidden.clear()
		for p in _people:
			if is_instance_valid(p):
				p.queue_free()
		_people.clear()


func _hide(n: Node) -> void:
	var layer: int = n.collision_layer if n is CollisionObject2D else 0
	_hidden.append([n, layer])
	n.visible = false
	n.process_mode = Node.PROCESS_MODE_DISABLED
	if n is CollisionObject2D:
		n.collision_layer = 0
	if n is Area2D:
		n.set_deferred("monitoring", false)
	for c in n.find_children("*", "StaticBody2D", true, false):
		c.collision_layer = 0  # (lo sólido de los de día no se queda estorbando)


func _spawn(spec: Array) -> Node2D:
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = spec[0].capitalize().replace(" ", "")
	npc.npc_id = spec[0]
	npc.sheet_row = spec[1]
	npc.position = spec[2]
	npc.face = spec[3]
	if spec[4].size() >= 2:
		npc.route = PackedVector2Array(spec[4])
		npc.walk_speed = 14.0
	_world.add_child(npc)
	if spec[0] == "noche_celador":
		var torch := PointLight2D.new()  # la linterna
		torch.texture = _glow
		torch.texture_scale = 0.6
		torch.color = Color(1.0, 0.95, 0.8)
		torch.energy = 0.9
		torch.position = Vector2(0, 6)
		npc.add_child(torch)
	if spec[0].begins_with("noche_kiosco"):
		var notes := Label.new()  # la música del parlante
		notes.text = "~ ~"
		notes.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
		notes.add_theme_font_size_override("font_size", 8)
		notes.add_theme_color_override("font_color", Color(0.75, 0.95, 1.0))
		notes.position = Vector2(-10, -44)
		npc.add_child(notes)
		var tw := notes.create_tween().set_loops()
		tw.tween_property(notes, "position:y", -48.0, 0.5)
		tw.tween_property(notes, "position:y", -44.0, 0.5)
	return npc


func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 96
	t.height = 96
	return t
