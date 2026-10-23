extends Node
## El relleno del barrio: lo que llena los espacios que estaban vacíos en la calle (City). La cancha de cal
## del lote, el caballo del zorrero, los caminitos y la ropa colgada de las casas, los puestos de la
## esquina (el chance, los minutos, las arepas), los juncos y la garza del río, y la plaza viva (el
## agua de la fuente, las palomas, el lustrabotas, el paletero, el busto con su paloma).
## Arte: tools/art/draw_relleno.py. Lo que dice cada cosa: tocar() (lo llama Conversations con "relleno_*").
## Los animales responden: las palomas y las gallinas se espantan cuando él (o Lukas) se les acerca.

const ART := "res://assets/relleno/%s.png"
## Los puestos solo están de día (de 6 de la mañana a 7 de la noche).
const VENDE_DESDE := 6
const VENDE_HASTA := 19

var _scene: Node
var _world: Node2D
var _player: Node2D
var _vendedores: Array[Node2D] = []
var _palomas: Array[Dictionary] = []
var _gallinas: Array[Dictionary] = []
var _flota: Array[Node2D] = []
var _rio: Node2D
var _patos: Array[Dictionary] = []
var _cometa: AnimatedSprite2D
var _hilo: Line2D
var _t := 0.0
var _tick := 0.0


func _ready() -> void:
	name = "Relleno"
	_scene = get_parent()
	_setup.call_deferred()


func _setup() -> void:
	_world = _scene.get_node_or_null("World") as Node2D
	if _world == null or not _scene.name in ["City", "Centro", "Parque"]:
		set_process(false)
		return
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _scene.name == "Centro":
		_centro()
		_vendedores_a_la_hora()
		return
	if _scene.name == "Parque":
		_parque()
		_vendedores_a_la_hora()
		return
	_lote()
	_potrero()
	_casas()
	_esquina()
	_rio_vivo()
	_plaza()
	_vendedores_a_la_hora()


# ---------------------------------------------------------------- poner cosas

func _tex(n: String) -> Texture2D:
	return load(ART % n)


## Un dibujo parado en el piso: pie = la base. solid = ancho de la base que no se atraviesa.
func _prop(n: String, pie: Vector2, solid := 0.0, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "relleno_%s_%d_%d" % [n, pie.x, pie.y]
	s.texture = _tex(n)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = pie
	s.flip_h = flip
	_world.add_child(s)
	if solid > 0.0:
		_solido(s, Vector2(solid, 6))
	return s


func _anim(frames: Array, fps: float, pie: Vector2, solid := 0.0) -> AnimatedSprite2D:
	var f := SpriteFrames.new()
	f.set_animation_speed("default", fps)
	for n in frames:
		f.add_frame("default", _tex(n))
	var a := AnimatedSprite2D.new()
	a.name = "relleno_%s_%d_%d" % [frames[0], pie.x, pie.y]
	a.sprite_frames = f
	a.centered = false
	var tex := _tex(frames[0])
	a.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	a.position = pie
	a.play("default")
	a.frame = randi() % frames.size()
	_world.add_child(a)
	if solid > 0.0:
		_solido(a, Vector2(solid, 6))
	return a


func _solido(n: Node2D, size: Vector2) -> void:
	var b := StaticBody2D.new()
	var c := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	c.shape = r
	c.position = Vector2(0, -size.y / 2.0)
	b.add_child(c)
	n.add_child(b)


## Lo que va pintado en el piso (la cancha, los caminitos): debajo de todo lo que tiene altura.
func _piso(n: String, at: Vector2) -> void:
	var s := Sprite2D.new()
	s.name = "relleno_piso_" + n
	s.texture = _tex(n)
	s.centered = false
	s.position = at
	_scene.add_child(s)
	var details := _scene.get_node_or_null("Details")
	_scene.move_child(s, details.get_index() + 1 if details else 1)


## Se toca con el botón: Conversations.run("relleno_<id>") → tocar().
func _tocable(id: String, pos: Vector2, hint: String, area := Vector2(22, 14)) -> Area2D:
	var spot := Area2D.new()
	spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
	spot.name = "Servicio_relleno_" + id
	spot.service_id = "relleno_" + id
	spot.hint = hint
	spot.area = area
	spot.position = pos
	_world.add_child(spot)
	return spot


# ---------------------------------------------------------------- las zonas

func _lote() -> void:
	# La cancha de cal donde juegan los pelados; el columpio se corre a la esquina del lote.
	_piso("cancha_cal", Vector2(164, 70))
	for n in _world.get_children():
		var nm := str(n.name)
		if nm.begins_with("swing_") and n is Node2D:
			(n as Node2D).position = Vector2(62, 56)
		elif nm == "Servicio_columpio" and n is Node2D:
			(n as Node2D).position = Vector2(62, 62)
	# Los arcos: dos morrales de cada lado (y una chancla, que el otro morral se fue a almorzar).
	_prop("morral_0", Vector2(168, 92))
	_prop("morral_1", Vector2(168, 120))
	_prop("morral_2", Vector2(310, 92))
	_prop("chancla", Vector2(310, 119))
	# La gradería: llantas pintadas medio enterradas, y la silla rota del que siempre pita.
	for k in 3:
		_prop("llanta_%d" % k, Vector2(196 + k * 22, 150), 14.0)
	_prop("silla_rota", Vector2(268, 152), 10.0)
	# NO BOTE BASURA, encima de la caneca.
	_prop("letrero_basura", Vector2(312, 182), 4.0)
	_tocable("letrero", Vector2(312, 188), "LEER")
	# Las gallinas sueltas del lote.
	for p in [Vector2(70, 150), Vector2(92, 160), Vector2(40, 132), Vector2(118, 140)]:
		var g := _anim(["gallina_0", "gallina_1", "gallina_0", "gallina_2"], 2.0 + randf(), p)
		g.speed_scale = randf_range(0.6, 1.2)
		_gallinas.append({"n": g, "casa": p, "meta": p, "huye": 0.0, "espera": randf() * 3.0})


func _potrero() -> void:
	# Arriba, entre el lote y la feria: el caballo del zorrero, su zorra, la maleza. Si ya hay coliseo, el
	# lote se vendió: el caballo se corre al pedazo que queda.
	var hay_coliseo := _world.get_node_or_null("coliseo_afuera") != null
	var caballo := Vector2(648, 104) if hay_coliseo else Vector2(470, 82)
	_prop("poste_lazo", caballo + Vector2(-22, 2), 3.0)
	_anim(["caballo_0", "caballo_0", "caballo_0", "caballo_1", "caballo_1"], 0.6, caballo, 18.0)
	_tocable("caballo", caballo + Vector2(0, 6), "CABALLO", Vector2(30, 14))
	if hay_coliseo:
		return
	_prop("zorra", Vector2(548, 72), 34.0)
	_prop("se_vende", Vector2(626, 52), 4.0)
	_tocable("se_vende", Vector2(626, 58), "LEER")
	for p in [Vector2(410, 40), Vector2(440, 108), Vector2(520, 30), Vector2(590, 100), Vector2(660, 66), Vector2(400, 90),
			Vector2(560, 112), Vector2(620, 24)]:
		_prop("maleza_%d" % (int(p.x) % 3), p)


func _casas() -> void:
	# Los caminitos que hizo la gente de tanto pisar: de cada puerta al callejón.
	_piso("senderos_casas", Vector2(0, 280))
	# La ropa colgada (el viento la mueve), las matas en tarros, las pipetas, el plátano.
	_anim(["tendedero_0", "tendedero_1"], 0.8, Vector2(250, 330))
	_tocable("tendedero", Vector2(250, 336), "MIRAR", Vector2(40, 12))
	_anim(["tendedero_1", "tendedero_0"], 0.7, Vector2(968, 420))
	for p in [Vector2(28, 340), Vector2(112, 340), Vector2(190, 404), Vector2(56, 452), Vector2(160, 474), Vector2(226, 564)]:
		_prop("mata_%d" % (int(p.x / 7) % 3), p, 8.0)
	_prop("pipetas", Vector2(92, 340), 14.0)
	_prop("pipetas", Vector2(206, 404), 14.0)
	_prop("platano", Vector2(14, 410), 6.0)
	_prop("platano", Vector2(272, 556), 6.0)
	_prop("platano", Vector2(1012, 500), 6.0)
	_prop("tanque", Vector2(116, 470), 14.0)
	_prop("tanque", Vector2(1008, 352), 14.0)
	# La tienda: el kiosco tiene mesa afuera, con las botellas de anoche.
	_prop("tienda_mesa", Vector2(344, 548), 36.0)
	_tocable("tienda", Vector2(344, 554), "MIRAR", Vector2(36, 14))


func _esquina() -> void:
	# Debajo de la plaza, la esquina de los puestos: el chance y el de los minutos.
	var chance := _prop("chance", Vector2(552, 584), 28.0)
	_vendedores.append(chance)
	_vendedores.append(_tocable("chance", Vector2(552, 590), "CHANCE"))
	var minutos := _anim(["minutos_0", "minutos_1"], 1.2, Vector2(752, 572), 30.0)
	_vendedores.append(minutos)
	_vendedores.append(_tocable("minutos", Vector2(752, 578), "MINUTOS"))
	# A la derecha, las arepas en la parrilla (humea).
	var arepas := _anim(["arepas_0", "arepas_1"], 3.0, Vector2(990, 448), 26.0)
	_vendedores.append(arepas)
	_vendedores.append(_tocable("arepas", Vector2(990, 454), "AREPAS"))


func _rio_vivo() -> void:
	# Juncos en la orilla, la garza que pesca, el carrito hundido y lo que el río se lleva.
	for x in [24, 60, 150, 236, 300, 540, 600, 790, 860, 948, 1000]:
		_prop("junco_%d" % (x % 2), Vector2(x, 660 + (x % 3) * 3))
	_anim(["garza_0", "garza_0", "garza_0", "garza_1", "garza_1", "garza_0"], 0.7, Vector2(830, 700))
	_prop("carrito_hundido", Vector2(268, 716))
	_rio = Node2D.new()
	_rio.name = "relleno_corriente"
	_rio.draw.connect(_draw_rio)
	_scene.add_child(_rio)
	_scene.move_child(_rio, _scene.get_node("World").get_index())
	for k in 6:
		var b := Sprite2D.new()
		b.texture = _tex("flota_%d" % (k % 3))
		b.position = Vector2(randf_range(0, 1024), randf_range(674, 752))
		b.set_meta("v", randf_range(4.0, 9.0))
		_rio.add_child(b)
		_flota.append(b)


func _draw_rio() -> void:
	# La corriente: rayitas claras que bajan con el agua (la pasada del sol, en el puente se cortan).
	for k in 60:
		var y := 668.0 + float((k * 37) % 92)
		var x := fmod(float(k * 131) + _t * (10.0 + float(k % 5) * 2.0), 1060.0) - 30.0
		if x > 432.0 and x < 516.0:
			continue
		var w := 6.0 + float(k % 4) * 3.0
		var a := 0.45 + 0.25 * sin(_t * 1.7 + k)
		_rio.draw_line(Vector2(x, y), Vector2(x + w, y), Color(0.70, 0.82, 0.78, a), 1.0)
		_rio.draw_line(Vector2(x + w * 0.3, y + 1.0), Vector2(x + w * 0.8, y + 1.0), Color(0.30, 0.42, 0.40, a * 0.8), 1.0)


func _plaza() -> void:
	# La fuente vuelve a echar agua (un chorrito): encima de la taza seca.
	for n in _world.get_children():
		if str(n.name).begins_with("fountain_dry") and n is Node2D:
			var f := SpriteFrames.new()
			f.set_animation_speed("default", 6.0)
			for k in [0, 1, 2, 1]:
				f.add_frame("default", _tex("fuente_agua_%d" % k))
			var a := AnimatedSprite2D.new()
			a.sprite_frames = f
			a.centered = false
			a.offset = Vector2(-20, -34)
			a.play("default")
			n.add_child(a)
			_tocable("fuente", (n as Node2D).position + Vector2(0, 6), "FUENTE", Vector2(40, 14))
			break
	_prop("matera", Vector2(540, 396), 20.0)
	_prop("matera", Vector2(540, 524), 20.0)
	_prop("matera", Vector2(744, 524), 20.0)
	_prop("busto", Vector2(696, 512), 14.0)
	_tocable("busto", Vector2(696, 518), "LEER")
	var lus := _anim(["lustrabotas_0", "lustrabotas_1"], 3.0, Vector2(588, 476), 16.0)
	_vendedores.append(lus)
	_vendedores.append(_tocable("lustrabotas", Vector2(588, 482), "LUSTRADA"))
	var pal := _prop("paletero", Vector2(690, 404), 20.0)
	_vendedores.append(pal)
	_vendedores.append(_tocable("paletero", Vector2(690, 410), "PALETAS"))
	_bandada(Vector2(624, 480), Vector2(50, 20), 8)


## Palomas que picotean alrededor de `centro` (y se espantan).
func _bandada(centro: Vector2, radio: Vector2, n: int) -> void:
	for k in n:
		var casa := centro + Vector2(randf_range(-radio.x, radio.x), randf_range(-radio.y, radio.y))
		var p := Sprite2D.new()
		p.texture = _tex("paloma_0")
		p.centered = false
		p.offset = Vector2(-5, -9)
		p.position = casa
		p.flip_h = randf() < 0.5
		_world.add_child(p)
		_palomas.append({"n": p, "casa": casa, "vuela": 0.0, "dir": Vector2.ZERO, "paso": randf() * 2.0})


func _centro() -> void:
	# Arriba, la otra fila de edificios: la ciudad sigue (con la valla del abogado).
	_piso("centro_fondo", Vector2(0, 0))
	# El andén de arriba: la dulcera sentada. Abajo, la plaza: el tintero, el lustrabotas, el de los
	# minutos, las materas y las palomas de la fuente.
	_vendedores.append(_prop("dulcera", Vector2(236, 206), 20.0))
	_vendedores.append(_tocable("dulcera", Vector2(236, 212), "DULCES"))
	_vendedores.append(_anim(["tintero_0", "tintero_1"], 2.5, Vector2(372, 306), 22.0))
	_vendedores.append(_tocable("tintero", Vector2(372, 312), "TINTO"))
	_vendedores.append(_anim(["lustrabotas_0", "lustrabotas_1"], 3.0, Vector2(150, 356), 16.0))
	_vendedores.append(_tocable("lustrabotas", Vector2(150, 362), "LUSTRADA"))
	_vendedores.append(_anim(["minutos_0", "minutos_1"], 1.2, Vector2(612, 316), 30.0))
	_vendedores.append(_tocable("minutos", Vector2(612, 322), "MINUTOS"))
	for p in [Vector2(34, 372), Vector2(530, 376), Vector2(600, 372)]:
		_prop("matera", p, 20.0)
	_bandada(Vector2(420, 368), Vector2(44, 10), 7)


func _parque() -> void:
	# La Olla Comunitaria por fin tiene olla: la carpa azul detrás de Fabiola (y el letrero va en la lona).
	var olla := _anim(["olla_0", "olla_1"], 3.0, Vector2(276, 154))
	_solido(olla, Vector2(60, 6))
	var cartel := _world.get_node_or_null("CartelOllaComunitaria")
	if cartel:
		cartel.visible = false
	# Arriba, en el pasto: el gimnasio del parque, el pelado de la cometa.
	_anim(["biosaludable_0", "biosaludable_1"], 2.2, Vector2(480, 84), 36.0)
	_tocable("gimnasio", Vector2(480, 90), "MIRAR", Vector2(40, 14))
	_prop("nino_cometa", Vector2(600, 92), 6.0)
	_tocable("cometa", Vector2(600, 98), "COMETA")
	_cometa = _anim(["cometa_0", "cometa_1", "cometa_2", "cometa_1"], 3.0, Vector2(560, 34))
	_cometa.z_index = 6
	_hilo = Line2D.new()
	_hilo.width = 1.0
	_hilo.default_color = Color(0.92, 0.92, 0.88, 0.8)
	_hilo.z_index = 5
	_world.add_child(_hilo)
	# Abajo a la derecha: el laguito con sus patos.
	_prop("laguito", Vector2(690, 404))
	var agua := StaticBody2D.new()  # sobre el agua no se camina
	var c := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 24)
	c.shape = shape
	c.position = Vector2(690, 386)
	agua.add_child(c)
	_world.add_child(agua)
	_tocable("patos", Vector2(690, 408), "PATOS", Vector2(60, 12))
	for k in 3:
		var d := _anim(["pato_%d" % (k % 2)], 1.0, Vector2(690, 386))
		d.z_index = 1  # (encima del agua del laguito)
		_patos.append({"n": d, "a": randf() * TAU, "v": randf_range(0.25, 0.45)})


# ---------------------------------------------------------------- lo que se mueve

func _process(delta: float) -> void:
	_t += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return
	if _rio:
		_rio.queue_redraw()
		for b in _flota:
			b.position.x += float(b.get_meta("v")) * delta
			if b.position.x > 1040.0:
				b.position = Vector2(-16.0, randf_range(674, 752))
	var lukas := _scene.get_node_or_null("World/Lukas") as Node2D
	_mover_palomas(delta, lukas)
	_mover_gallinas(delta, lukas)
	for d in _patos:  # los patos le dan la vuelta al laguito; si él se acerca, se van rápido al otro lado
		var pn: AnimatedSprite2D = d["n"]
		var lejos := _player.position.distance_to(pn.position) > 40.0
		d["a"] = float(d["a"]) + float(d["v"]) * delta * (1.0 if lejos else 4.0)
		var a: float = d["a"]
		pn.position = Vector2(690 + cos(a) * 30.0, 388 + sin(a) * 8.0)
		pn.flip_h = sin(a) > 0.0
	if _cometa:
		_cometa.position = Vector2(560 + sin(_t * 0.7) * 10.0, 34 + sin(_t * 1.3) * 4.0)
		_hilo.points = PackedVector2Array([Vector2(604, 76), _cometa.position + Vector2(0, -14)])
	_tick -= delta
	if _tick <= 0.0:
		_tick = 2.0
		_vendedores_a_la_hora()


func _cerca(p: Vector2, lukas: Node2D, r: float) -> Vector2:
	## De dónde viene el susto (Vector2.INF si nada está cerca).
	if _player.position.distance_to(p) < r:
		return _player.position
	if lukas and lukas.position.distance_to(p) < r * 1.3:
		return lukas.position
	return Vector2.INF


func _mover_palomas(delta: float, lukas: Node2D) -> void:
	for d in _palomas:
		var p: Sprite2D = d["n"]
		if float(d["vuela"]) > 0.0:
			d["vuela"] = float(d["vuela"]) - delta
			p.position += (d["dir"] as Vector2) * 70.0 * delta
			p.texture = _tex("paloma_3" if int(_t * 10.0) % 2 == 0 else "paloma_4")
			p.z_index = 5
			if float(d["vuela"]) <= 0.0:  # se fueron lejos; vuelven después, de a una, cuando no hay nadie
				p.visible = false
				d["vuela"] = -randf_range(6.0, 14.0)
			continue
		if float(d["vuela"]) < 0.0:
			d["vuela"] = float(d["vuela"]) + delta
			if float(d["vuela"]) >= 0.0:
				if _cerca(d["casa"], lukas, 60.0) != Vector2.INF:
					d["vuela"] = -3.0
					continue
				p.position = d["casa"]
				p.visible = true
				p.z_index = 0
				d["vuela"] = 0.0
			continue
		var susto := _cerca(p.position, lukas, 26.0)
		if susto != Vector2.INF:  # se espantan todas las de cerca, como pasa
			for o in _palomas:
				var op: Sprite2D = o["n"]
				if float(o["vuela"]) == 0.0 and op.position.distance_to(p.position) < 48.0:
					o["vuela"] = 1.6
					o["dir"] = ((op.position - susto).normalized() + Vector2(0, -1.4)).normalized()
					op.flip_h = (o["dir"] as Vector2).x < 0.0
			continue
		d["paso"] = float(d["paso"]) - delta
		if float(d["paso"]) <= 0.0:  # picotear, caminar un pasito, mirar
			d["paso"] = randf_range(0.4, 1.6)
			var k := randi() % 4
			p.texture = _tex("paloma_%d" % mini(k, 2))
			if k == 2:
				var step := Vector2(randf_range(-5, 5), randf_range(-3, 3))
				if (p.position + step).distance_to(d["casa"]) < 22.0:
					p.position += step
					p.flip_h = step.x < 0.0


func _mover_gallinas(delta: float, lukas: Node2D) -> void:
	for d in _gallinas:
		var g: AnimatedSprite2D = d["n"]
		var susto := _cerca(g.position, lukas, 30.0)
		if susto != Vector2.INF:
			d["huye"] = 1.0
			var lejos: Vector2 = g.position + (g.position - susto).normalized() * 50.0
			d["meta"] = Vector2(clampf(lejos.x, 20, 150), clampf(lejos.y, 116, 186))
		var meta: Vector2 = d["meta"]
		var v := 55.0 if float(d["huye"]) > 0.0 else 9.0
		d["huye"] = maxf(0.0, float(d["huye"]) - delta)
		if g.position.distance_to(meta) > 1.5:
			var step := (meta - g.position).normalized() * v * delta
			g.position += step
			g.flip_h = step.x < 0.0
			g.speed_scale = 4.0 if v > 20.0 else 1.0
		else:
			d["espera"] = float(d["espera"]) - delta
			g.speed_scale = 1.0
			if float(d["espera"]) <= 0.0:
				d["espera"] = randf_range(1.5, 5.0)
				var c: Vector2 = d["casa"]
				d["meta"] = c + Vector2(randf_range(-24, 24), randf_range(-12, 12))


func _vendedores_a_la_hora() -> void:
	var h := TimeManager.hour()
	var hay := h >= VENDE_DESDE and h < VENDE_HASTA
	for v in _vendedores:
		if is_instance_valid(v):
			v.visible = hay
			if v is Area2D:
				(v as Area2D).monitoring = hay
				v.process_mode = Node.PROCESS_MODE_INHERIT if hay else Node.PROCESS_MODE_DISABLED


# ---------------------------------------------------------------- lo que dice cada cosa

const LETRERO := [
	"(NO BOTE BASURA, en rojo. Debajo, la caneca rebosada y tres bolsas al lado. La gente sí lee: la bota justo debajo, para que el letrero tenga sentido.)",
	"(Alguien le agregó con marcador: \"NI SU EX\". La letra es de mujer. La caneca no opina.)",
	"(El letrero lleva tantos años que ya tiene su propia basura de confianza.)",
]
const SE_VENDE := [
	"(SE VENDE. El teléfono empieza por 310 y lo demás se lo llevó la lluvia. El que quiera el lote tiene que adivinar siete números. Es un lote y una lotería.)",
	"(Debajo del SE VENDE, en otro cartón: \"NO SE ACEPTAN CARROS COMO PARTE DE PAGO\". Alguien lo intentó.)",
]
const BUSTO := [
	"(La placa dice: AL PRÓCER, CON GRATITUD. No dice cuál. El prócer tampoco se acuerda: tiene una paloma en la cabeza y cara de no haber mandado a nadie a nada.)",
	"(La paloma de la cabeza del prócer es siempre la misma. Ya tiene más años en el cargo que el alcalde.)",
	"(Debajo de la placa, con navaja: \"WILMER Y YURANI 2009\". Es el único dato histórico verificable de la plaza.)",
]
const TENDEDERO := [
	"(Un jean, una toalla con la cara de un pato, una camisa de la Selección del 2014. La camisa todavía cree que vamos para la final.)",
	"(Las medias se secan de a una. La otra de cada par está en otro tendedero, en otro barrio, viviendo otra vida.)",
]
const TIENDA := [
	"(Mesa plástica, parasol rojo, cuatro botellas vacías. Los que se las tomaron se fueron; las botellas se quedaron cuidando la mesa, que es lo que hace la gente seria.)",
	"(En la canasta roja, las vacías de anoche. En una tiene metida una colilla y un papelito: \"le debo 2 a la mona\". La mona sabe.)",
]


func _turno(key: String, lista: Array) -> String:
	var f := GameState.flags
	var i := int(f.get("relleno_" + key, 0))
	f["relleno_" + key] = i + 1
	return lista[i % lista.size()]


func _yo(anim: String, sound := "") -> void:
	if _player and _player.has_method("act"):
		await _player.act(anim, false, sound)


func tocar(id: String) -> void:
	match id:
		"relleno_letrero":
			await Dialogue.talk([["", _turno("letrero", LETRERO)]])
		"relleno_se_vende":
			await Dialogue.talk([["", _turno("se_vende", SE_VENDE)]])
		"relleno_busto":
			await Dialogue.talk([["", _turno("busto", BUSTO)]])
		"relleno_tendedero":
			var lines := [["", _turno("tendedero", TENDEDERO)]]
			if GameState.lukas_alive():
				lines.append(["", "(Lukas le huele las medias al tendedero con mucho interés profesional.)"])
			await Dialogue.talk(lines)
		"relleno_tienda":
			await Dialogue.talk([["", _turno("tienda", TIENDA)]])
		"relleno_fuente":
			await _fuente()
		"relleno_caballo":
			await _caballo()
		"relleno_chance":
			await _chance()
		"relleno_minutos":
			await _minutos()
		"relleno_arepas":
			await _arepas()
		"relleno_lustrabotas":
			await _lustrabotas()
		"relleno_paletero":
			await _paletero()
		"relleno_dulcera":
			await Dialogue.talk([["LA DE LOS DULCES", _turno("dulcera", [
				"—Bombombum, chicles, cigarrillo suelto. ¿Nada? Bueno. Si se arrepiente, aquí estoy desde 1987.",
				"—Aquí paso doce horas. Vi entrar a la Registraduría a uno con bigote y salir sin bigote. Ahí no le arreglan la cédula: le arreglan la cara.",
				"—A usted lo vi en la Defensoría. Tranquilo, yo no digo nada. Aquí nadie dice nada. Por eso nos va como nos va.",
			])]])
		"relleno_tintero":
			await _tintero()
		"relleno_gimnasio":
			await Dialogue.talk([["EL DE LA SUDADERA", _turno("gimnasio", [
				"—Treinta años en esta máquina y la barriga no se va. Pero la máquina ya está más flaca. Algo es algo.",
				"—Esto lo puso la alcaldía. Verde y amarillo, para que uno se acuerde de quién lo puso. Uno se acuerda. Y no vota.",
				"—Súbase a la de al lado. Es lo único gratis de esta ciudad, y nadie la usa. Eso dice mucho de la ciudad.",
			])]])
		"relleno_cometa":
			var lines := [["EL PELADO", _turno("cometa", [
				"—La hice yo. Con palitos de chuzo, bolsa de basura y cola de trapo. Vuela más alto que la de los ricos. El truco es la rabia.",
				"—No la toque, ni la mire mucho. Se pone nerviosa.",
				"—Mi papá me iba a enseñar. Estaba ocupado. Aprendí mirando. (Templa el hilo.) Igual vuela.",
			])]]
			if GameState.lukas_alive():
				lines.append(["", "(Lukas le ladra a la cometa. La cometa no baja. Lukas lo da por empate.)"])
			await Dialogue.talk(lines)
		"relleno_patos":
			await _patos_pan()


func _fuente() -> void:
	var lines := [["", ["(La fuente volvió a echar agua. Un chorrito flaco, de próstata. Las palomas se bañan por turnos y nadie se cuela.)",
		"(Al fondo de la fuente: monedas de cincuenta, una tapa, un chupo. Los deseos de este barrio son de cincuenta pesos.)",
		"(Mete las manos al agua. Está tibia, verde y con opinión. Se las seca en el pantalón.)"].pick_random()]]
	await Dialogue.talk(lines)


func _caballo() -> void:
	var f := GameState.flags
	if not f.get("caballo_visto", false):
		f["caballo_visto"] = true
		await Dialogue.talk([["", "(El caballo del zorrero, amarrado a un palo. Se le cuentan las costillas: once por lado. Alguien le puso nombre con pintura en la zorra: RELÁMPAGO.)"],
			["", "(Relámpago lo mira con la paciencia del que ya cargó neveras por todo Lombardía.)"]])
	await _yo("acariciar")
	var lines := [["", ["(Le acaricia el cuello. Relámpago le busca en el bolsillo. No hay nada. Se miran. Colegas.)",
		"(Relámpago le resopla en la cara. Huele a pasto, a llanta y a lunes.)",
		"(Le rasca entre los ojos. Relámpago cierra los ojos. Y se le recuesta encima: trescientos kilos de confianza.)"].pick_random()]]
	if GameState.lukas_alive():
		lines.append(["", "(Lukas le ladra a Relámpago desde lejos. Relámpago ni voltea: ha visto perros más grandes.)"])
	await Dialogue.talk(lines)
	GameState.change_mood(2.0)


func _chance() -> void:
	var who := "LA DEL CHANCE"
	var f := GameState.flags
	if int(f.get("chance_dia", -1)) == GameState.day:
		await Dialogue.talk([[who, "—Ya jugó hoy. La suerte también tiene horario, mijo."]])
		return
	var price := 1000
	var i := await Dialogue.talk([[who, "—Chance, a mil. ¿Qué número le juega? Dicen que el que más sale es la placa de la última moto que a uno lo tumbó."]],
		["29 (el día del cumpleaños)", "%02d (el día de hoy)" % GameState.day, "07 (el de la suerte)", "No jugar"])
	if i == 3:
		await Dialogue.talk([[who, "—Muy bien. El que no juega no pierde. Tampoco gana, pero eso ya es otro tema."]])
		return
	if GameState.money < price:
		await Dialogue.talk([[who, "—Sin plata no hay chance. Ahí está la vida, resumida en un letrero."]])
		return
	f["chance_dia"] = GameState.day
	GameState.add_money(-price)  # (Player anima el pago solo)
	var num: int = [29, GameState.day, 7][i]
	var sale := randi() % 100
	if randf() < 0.12:
		sale = num
	await Dialogue.talk([[who, "—Juega el %02d. Sale a las tres con el sorteo de la Cafeterita. Venga y mire." % num]])
	if sale == num:
		GameState.add_money(6000)
		await Dialogue.talk([[who, "—¡Ay, no! ¡Le salió! El %02d, en las dos últimas. Tome sus seis mil. Y no me vuelva a jugar ese número, que me arruina." % num],
			["", "(Seis mil pesos. Mira el papelito un rato largo. Nunca nadie le había dado la razón tan rápido.)"]])
		GameState.change_mood(6.0)
	else:
		await Dialogue.talk([[who, "—Cayó el %02d. Estuvo cerquita. Bueno, no: estuvo lejísimos. Pero se siente cerquita, que es lo que vendemos." % sale]])


func _minutos() -> void:
	var who := "EL DE LOS MINUTOS"
	await Dialogue.talk([[who, _turno("minutos", [
		"—Minuto a doscientos, a todo operador. ¿Va a llamar? ... (Él señala su propio celular.) Ah. De los que tienen celular pero no saldo. Como mi yerno. Siéntese, que acá hay de todo.",
		"—Si es para una ex, le cobro doble. Esas llamadas nunca duran un minuto, y al final siempre cuelga el que paga.",
		"—Hoy llamó una señora y estuvo cuarenta minutos callada. Pagó cuarenta minutos de silencio. Usted y ella se entenderían.",
		"—El negocio está malo. Todo el mundo tiene plan. Antes uno vendía minutos; ahora vende sombra. (Señala la sombrilla.) Esa sí no tiene competencia.",
	])]])


func _arepas() -> void:
	var who := "LA DE LAS AREPAS"
	var i := await Dialogue.talk([[who, "—Arepa con queso, a dos mil. Asadita. ¿Le doy?"]], ["Una arepa ($2000)", "Solo oler"])
	if i == 0:
		await Conversations._buy("arepa", 2000, who, "—Tome. Con mantequilla de la que unta uno con el dedo. No pregunte.")
	else:
		var lines := [[who, "—Oler es gratis. Pero si se queda ahí oliendo media hora, le cobro el arriendo del humo."]]
		if GameState.lukas_alive():
			lines.append(["", "(Lukas se sienta frente a la parrilla con cara de examen final. La señora le tira la orillita quemada. Lukas aprueba.)"])
		await Dialogue.talk(lines)


func _lustrabotas() -> void:
	var who := "EL LUSTRABOTAS"
	await Dialogue.talk([[who, _turno("lustrabotas", [
		"—¿Lustrada? ... (Le mira los zapatos un rato.) No. Eso ya no es lustrar. Eso es restaurar. Y restaurar vale más que el zapato.",
		"—Yo le lustré los zapatos al concejal. Ahora va en camioneta. A mí me dejó el betún. Cada quien con lo suyo.",
		"—Vea: usted me deja lustrarle esos zapatos de gratis y yo los pongo en una foto de \"antes y después\". Me hago famoso. (Lo piensa.) No, mejor no. Asusto a la clientela.",
	])]])


func _tintero() -> void:
	var who := "EL DE LOS TINTOS"
	var i := await Dialogue.talk([[who, "—¡Tinto, aromática, agüita de panela! Calientica, para el que madrugó o para el que no ha dormido."]],
		["Un tinto", "No"])
	if i == 0:
		if GameState.money < 500:
			await Dialogue.talk([[who, "—No le alcanza. Tome, el concho de la jarra. Es tinto igual, nada más que con experiencia."]])
		else:
			GameState.add_money(-500)
		# Se lo toma ahí, de pie junto al carrito (Player anima "beber" con la señal ate).
		GameState.set_hunger(GameState.hunger + 5.0)
		GameState.change_mood(3.0)
		GameState.flags["caliente_dia"] = GameState.day  # (la tos: algo caliente la frena un poquito)
		GameState.ate.emit("tinto")
		await Dialogue.talk([[who, "—Con dos de azúcar, que la vida ya es bastante amarga sola."]])
	else:
		await Dialogue.talk([[who, "—A un tinto no se le dice que no. Se le dice \"más tarde\". Lo espero."]])


func _patos_pan() -> void:
	var lines := [["", "(Tres patos en un laguito del tamaño de una sala. Uno verde, dos blancos, y los tres convencidos de que el lago es de ellos.)"]]
	if GameState.count("pan") > 0:
		var i := await Dialogue.talk(lines, ["Darles pan", "Solo mirar"])
		if i != 0:
			return
		GameState.remove_item("pan")
		await _yo("dar_comida")
		var after := [["", "(Les tira el pan en pedacitos. Los tres patos se pelean como si fuera la herencia de la abuela.)"]]
		if GameState.lukas_alive():
			after.append(["", "(Lukas mira irse al agua los pedazos de pan, uno por uno. Es lo más duro que le ha pasado en la semana.)"])
		await Dialogue.talk(after)
		GameState.change_mood(4.0)
		return
	lines.append(["", "(Los patos ven que no trae pan y se van nadando al otro lado. Sin rencor. Pero se van.)"])
	await Dialogue.talk(lines)


func _paletero() -> void:
	var who := "EL PALETERO"
	var price := 1000
	var i := await Dialogue.talk([[who, "—¡Paletas! De mora, de leche, de mango biche. A mil. Hace calor, mijo: el calor no perdona y la paleta sí."]],
		["Una de mora ($1000)", "No"])
	if i != 0:
		await Dialogue.talk([[who, "—Cuando se le derrita el orgullo, aquí estoy."]])
		return
	if GameState.money < price:
		await Dialogue.talk([[who, "—Ay, no le alcanza. Tome, una que se me partió. Partida sabe igual, nada más que en dos."]])
	else:
		GameState.add_money(-price)
	await _yo("comer")
	var lines := [["", "(Una paleta de mora. Se le chorrea por la muñeca. Se lame la muñeca. No hay testigos, salvo el prócer.)"]]
	if GameState.lukas_alive():
		lines.append(["", "(El palito se lo deja a Lukas. Lukas lo lame con tanto respeto que parece que rezara.)"])
	await Dialogue.talk(lines)
	GameState.change_mood(3.0)
