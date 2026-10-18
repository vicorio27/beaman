extends Location
## Adentro del cambuche (con toldo ya hay un adentro): un cuartico donde se camina, con lo suyo puesto.
## La cama, la caja (y encima, en la repisa, lo que guarda), la alcancía debajo de la tabla floja, la
## cocinita, el tablero y una tabla con una piedra para armar.
## Mientras es solo toldo (niveles 1 y 2), adentro es un decir: el plástico tapa el cielo, no la calle.
## Los lados abiertos, el toldo que el viento sacude y que gotea, la calle ahí detrás (la gente pasa,
## se para a mirar, un perro olfatea) y la luz de la hora, la misma de afuera. Con paredes de estiba
## (3) ya se cierra; con zinc (4), por fin, es una casita.
## Lo que hace cada cosa es lo mismo que el menú del cambuche (SleepSpot): aquí hay uno escondido.
## Se sale por la cortina, al mismo lugar por donde entró (GameState.flags["casa_volver"]).

const PLASTIC := Color(0.22, 0.38, 0.62)
const CARTON := Color(0.58, 0.43, 0.27)
const WOOD := Color(0.5, 0.36, 0.22)
const INK := Color(0.08, 0.06, 0.08)
## Lo que se cuelga en la pared, si lo tiene (en la mochila o en la caja).
const KEEPSAKES := ["foto", "foto_entera", "dibujo_victoria", "estampita", "carta_ines"]

var spot: SleepSpot  # el del menú (escondido): Caja, Alcancía, Cocinar, Mejorar, Armar...
var _open := false   # solo toldo: a la intemperie
var _outside: Node2D
var _t := 0.0
var _walkers: Array = []  # los que pasan por la calle de atrás: {x, v, pants, dog, stop, wait}


func _ready() -> void:
	var c := GameState.cambuche
	spot = SleepSpot.new()
	spot.name = "Cambuche"
	spot.spot_id = str(c.get("spot", "rio"))
	spot.position = Vector2(-500, -500)
	spot.visible = false
	add_child(spot)
	spot.monitoring = false
	var room := Node2D.new()
	room.name = "Cuarto"
	room.z_index = -5
	room.draw.connect(_draw_room.bind(room))
	add_child(room)
	GameState.cambuche_changed.connect(room.queue_redraw)
	# Lo que se usa: [id, letrero, posición, tamaño].
	var spots := [["casa_cama", "ACOSTARSE", Vector2(44, 64), Vector2(56, 22)],
		["casa_caja", "CAJA", Vector2(160, 58), Vector2(26, 18)],
		["casa_alcancia", "ALCANCÍA", Vector2(36, 106), Vector2(20, 14)],
		["casa_tablero", "TABLERO", Vector2(96, 44), Vector2(26, 14)],
		["casa_armar", "ARMAR", Vector2(126, 98), Vector2(22, 16)]]
	if c.get("cocinita", false):
		spots.append(["casa_cocina", "COCINAR", Vector2(166, 104), Vector2(18, 16)])
	for s in spots:
		var a := Area2D.new()
		a.set_script(load("res://scripts/world/ServiceSpot.gd"))
		a.name = s[0]
		a.service_id = s[0]
		a.hint = s[1]
		a.position = s[2]
		a.area = s[3]
		add_child(a)
	# Lo que no se atraviesa: la cama y la caja.
	var solid := StaticBody2D.new()
	for r in [Rect2(18, 44, 56, 12), Rect2(150, 40, 24, 10)]:
		var sh := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		sh.shape = rect
		sh.position = r.position + r.size / 2.0
		solid.add_child(sh)
	add_child(solid)
	# La cortina: se sale por donde entró.
	var back: Array = GameState.flags.get("casa_volver", ["res://scenes/world/City.tscn", ""])
	var door := Area2D.new()
	door.set_script(load("res://scripts/world/Door.gd"))
	door.name = "Cortina"
	door.target_scene = back[0]
	door.target_spawn = back[1]
	door.push_dir = Vector2.DOWN
	door.position = Vector2(96, 124)
	var dsh := CollisionShape2D.new()
	var drect := RectangleShape2D.new()
	drect.size = Vector2(28, 10)
	dsh.shape = drect
	door.add_child(dsh)
	add_child(door)
	_open = GameState.cambuche_level() < 3
	if _open:  # lo de afuera se mueve: la calle de atrás, el toldo, la lluvia
		_outside = Node2D.new()
		_outside.name = "Afuera"
		_outside.z_index = -4
		_outside.draw.connect(_draw_outside)
		add_child(_outside)
	super._ready()
	if _open:
		var light := Node.new()  # la luz de afuera: aquí no hay techo que valga
		light.set_script(load("res://scripts/systems/DayNight.gd"))
		add_child(light)
		if not GameState.flags.get("casa_vista_abierta", false):
			GameState.flags["casa_vista_abierta"] = true
			Narrator.say("(Adentro es un decir. El toldo tapa el cielo, no la calle. Los que pasan miran; él hace como que no.)")
	elif not GameState.flags.get("casa_vista", false):
		GameState.flags["casa_vista"] = true
		Narrator.say("(Ahora sí: adentro no se ve la calle. La calle tampoco lo ve a él. Es lo primero con puerta que tiene, aunque la puerta sea de plástico.)")


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	# La gente que pasa por la calle de atrás: cada tanto alguien; a veces se para a mirar para adentro.
	if randf() < delta * 0.25 and _walkers.size() < 2:
		var right := randf() < 0.5
		_walkers.append({"x": -110.0 if right else area_size.x + 110.0, "v": (16.0 + randf() * 10.0) * (1.0 if right else -1.0),
			"pants": [Color(0.25, 0.3, 0.45), Color(0.3, 0.28, 0.24), Color(0.5, 0.48, 0.44)].pick_random(),
			"dog": randf() < 0.15, "stop": randf() < 0.35, "wait": 0.0})
	for wk in _walkers:
		if wk["stop"] and absf(wk["x"] - area_size.x / 2.0) < 6.0 and wk["wait"] < 2.5:
			wk["wait"] += delta
			continue
		wk["x"] += wk["v"] * delta
	_walkers = _walkers.filter(func(wk): return wk["x"] > -120.0 and wk["x"] < area_size.x + 120.0)
	_outside.queue_redraw()


## Solo toldo: la calle de atrás, por encima del borde del cartón; los lados abiertos; el toldo encima,
## que se mueve con el viento (y, si llueve, gotea por los huecos).
func _draw_outside() -> void:
	var r := _outside
	var w := float(area_size.x)
	var h := float(area_size.y)
	var spot_id := str(GameState.cambuche.get("spot", "rio"))
	var L := -100.0  # lo de afuera llega hasta el borde de la pantalla (el cuarto es más chico)
	var R := w + 100.0
	var walk := Color(0.55, 0.53, 0.5) if spot_id != "rio" else Color(0.4, 0.38, 0.34)
	# Alrededor (los lados abiertos y lo de adelante): andén, o la orilla en el río. Nunca negro.
	r.draw_rect(Rect2(L, 30, 8 - L, h + 40), walk)
	r.draw_rect(Rect2(w - 8, 30, R - w + 8, h + 40), walk)
	r.draw_rect(Rect2(L, h, R - L, 40), walk)
	for x in range(int(L), int(R), 24):  # las juntas del andén
		r.draw_line(Vector2(x, 30), Vector2(x, h + 40), walk.darkened(0.12))
	r.draw_rect(Rect2(-60, 70, 14, 10), Color(0.12, 0.12, 0.14))       # una bolsa de basura
	r.draw_rect(Rect2(-58, 66, 10, 5), Color(0.16, 0.16, 0.18))
	r.draw_rect(Rect2(w + 50, 40, 3, 90), Color(0.3, 0.3, 0.34))        # el poste de la luz
	r.draw_rect(Rect2(w + 44, 38, 14, 4), Color(0.3, 0.3, 0.34))
	var hour := TimeManager.hour()
	if hour >= 18 or hour < 6:
		r.draw_circle(Vector2(w + 46, 44), 40.0, Color(1.0, 0.85, 0.55, 0.12))
		r.draw_circle(Vector2(w + 46, 44), 18.0, Color(1.0, 0.85, 0.55, 0.16))
		r.draw_rect(Rect2(w + 44, 42, 5, 2), Color(1.0, 0.92, 0.7))
	# Atrás: la calle y el andén (o el estribo del puente y el camino de la orilla, en el río).
	if spot_id == "rio":
		r.draw_rect(Rect2(L, -60, R - L, 90), Color(0.42, 0.42, 0.46))
		for x in range(int(L), int(R), 32):
			r.draw_line(Vector2(x, -60), Vector2(x + 6, 30), Color(0.34, 0.34, 0.38))
		r.draw_rect(Rect2(L, 22, R - L, 8), Color(0.32, 0.3, 0.28))
	else:
		r.draw_rect(Rect2(L, -60, R - L, 74), Color(0.3, 0.3, 0.34))
		for x in range(int(L) + 6, int(R), 26):
			r.draw_rect(Rect2(x, 2, 10, 1), Color(0.8, 0.75, 0.4))
		r.draw_rect(Rect2(L, 14, R - L, 16), walk)
		r.draw_rect(Rect2(L, 14, R - L, 1), Color(0.7, 0.68, 0.64))
	# Los que pasan: las piernas (es lo que se ve desde el piso), y a veces un perro.
	for wk in _walkers:
		var x: float = wk["x"]
		var still: bool = wk["wait"] > 0.0 and wk["wait"] < 2.5
		var step: float = 0.0 if still else sin(_t * 10.0 + x) * 2.0
		var pants: Color = wk["pants"]
		r.draw_rect(Rect2(x - 3 + step, 16, 2, 12), pants)
		r.draw_rect(Rect2(x + 1 - step, 16, 2, 12), pants.darkened(0.15))
		r.draw_rect(Rect2(x - 4 + step, 28, 3, 2), INK)
		r.draw_rect(Rect2(x + 1 - step, 28, 3, 2), INK)
		if wk["dog"]:
			r.draw_rect(Rect2(x - 12, 24, 7, 4), Color(0.6, 0.5, 0.36))
			r.draw_rect(Rect2(x - 5 if wk["v"] > 0 else x - 14, 22, 3, 3), Color(0.6, 0.5, 0.36))
	# Un papel que trae el viento, por el piso.
	var paper := fposmod(_t * 18.0, w + 40.0) - 20.0
	r.draw_rect(Rect2(paper, h - 20 + sin(_t * 3.0) * 3.0, 4, 3), Color(0.9, 0.88, 0.8))
	# El toldo: amarrado a dos palos, combado, con el viento que lo levanta de un lado.
	var flap := sin(_t * 2.3) * 3.0 + sin(_t * 5.1) * 1.0
	for x in [10.0, w - 12.0]:
		r.draw_rect(Rect2(x, 0, 2, 40), WOOD)
	var pts := PackedVector2Array()
	for i in 13:
		var x := 10.0 + (w - 22.0) * i / 12.0
		pts.append(Vector2(x, 2.0 + sin(PI * i / 12.0) * 6.0 + (flap if i > 8 else flap * 0.3) * sin(PI * i / 12.0)))
	for i in range(12, -1, -1):
		var x := 10.0 + (w - 22.0) * i / 12.0
		pts.append(Vector2(x, 12.0 + sin(PI * i / 12.0) * 6.0 + flap * 0.5))
	r.draw_colored_polygon(pts, Color(PLASTIC, 0.85))
	for i in 3:  # los huecos del toldo
		r.draw_rect(Rect2(40.0 + i * 52.0, 8 + i * 2, 3, 2), Color(0.12, 0.12, 0.16))
	r.draw_line(Vector2(0, 2), Vector2(w, 2), Color(0.85, 0.82, 0.7), 1.0)  # la cuerda
	# Si llueve: gotea por los huecos, el cartón se empapa debajo, y llueve en la calle de atrás.
	if Weather.raining():
		for i in 3:
			var hx := 41.0 + i * 52.0
			var drop := fmod(_t * 1.6 + i * 0.37, 1.0)
			r.draw_rect(Rect2(hx, 12 + i * 2 + drop * 60.0, 1, 3), Color(0.6, 0.75, 0.95, 0.9))
			r.draw_circle(Vector2(hx, 78 + i * 2), 6.0, Color(0.3, 0.32, 0.4, 0.35))
		for k in 30:
			var rx := fposmod(k * 47.0 + _t * 30.0, w)
			var ry := fposmod(k * 23.0 + _t * 140.0, 34.0)
			r.draw_line(Vector2(rx, ry), Vector2(rx - 1, ry + 3), Color(0.7, 0.78, 0.95, 0.6))


func _draw_room(r: Node2D) -> void:
	var c := GameState.cambuche
	var lvl := GameState.cambuche_level()
	var w := float(area_size.x)
	var h := float(area_size.y)
	# El piso: cartón (doble y con las esquinas metidas, si ya tiene piso).
	r.draw_rect(Rect2(0, 0, w, h), CARTON.darkened(0.25))
	var neat: bool = c.get("piso", false)
	var tw := 24 if neat else 19
	var th := 16 if neat else 13
	for y in range(34, int(h), th):
		for x in range(-10, int(w), tw):
			var off := 0 if neat or (y / th) % 2 == 0 else 9
			var shade := 0.0 if neat else float((x + y) % 3) * 0.05
			r.draw_rect(Rect2(x + off + 1, y + 1, tw - 2, th - 2), CARTON.lightened(0.06 if neat else 0.0).darkened(shade))
	# La pared de atrás: toldo (plástico azul), estibas (rancho) o estibas con zinc arriba (ranchito).
	if lvl >= 3:
		for x in range(0, int(w), 12):
			r.draw_rect(Rect2(x, 0, 11, 34), WOOD.darkened(float(x % 36) / 120.0))
			r.draw_line(Vector2(x + 11, 0), Vector2(x + 11, 34), INK.lightened(0.1))
		if lvl >= 4:
			r.draw_rect(Rect2(0, 0, w, 8), Color(0.55, 0.57, 0.6))
			for x in range(0, int(w), 6):
				r.draw_line(Vector2(x, 0), Vector2(x, 8), Color(0.4, 0.42, 0.46))
			r.draw_rect(Rect2(122, 16, 14, 9), Color(0.2, 0.2, 0.22))  # el radio
			r.draw_circle(Vector2(126, 21), 2.5, Color(0.5, 0.5, 0.5))
			r.draw_line(Vector2(134, 16), Vector2(140, 6), Color(0.7, 0.7, 0.72))
	r.draw_rect(Rect2(0, 33, w, 2), INK if lvl >= 3 else Color(0.3, 0.24, 0.18))
	# Los lados: con paredes, cerrado y más oscuro. Con solo toldo no hay lados (los dibuja el afuera).
	if lvl >= 3:
		r.draw_rect(Rect2(0, 0, 6, h), WOOD.darkened(0.45))
		r.draw_rect(Rect2(w - 6, 0, 6, h), WOOD.darkened(0.45))
	# La cortina de la puerta, abajo (con solo toldo no hay: por ahí se sale y ya).
	if lvl >= 3:
		r.draw_rect(Rect2(0, h - 4, w, 4), INK)
		r.draw_rect(Rect2(82, h - 6, 28, 6), Color(0.62, 0.2, 0.22))
	# El tablero: en la pared; con solo toldo, recostado contra el palo.
	var board := Vector2(84, 10) if lvl >= 3 else Vector2(84, 36)
	r.draw_rect(Rect2(board, Vector2(24, 18)), Color(0.62, 0.45, 0.3))
	r.draw_rect(Rect2(board + Vector2(2, 2), Vector2(8, 6)), Color(0.95, 0.93, 0.86))
	r.draw_rect(Rect2(board + Vector2(13, 3), Vector2(8, 9)), Color(0.92, 0.88, 0.62))
	r.draw_rect(Rect2(board + Vector2(4, 10), Vector2(7, 6)), Color(0.86, 0.92, 0.96))
	# Lo de colgar: la foto, el dibujo de Victoria... en la pared, al lado del tablero. Sin pared,
	# recostado en el piso, al otro lado del tablero.
	var wall_x := 46.0 if lvl >= 3 else 112.0
	var box: Array = c.get("box", [])
	for keep in KEEPSAKES:
		if GameState.count(keep) > 0 or box.any(func(b): return b["id"] == keep):
			r.draw_texture_rect(Items.icon(keep), Rect2(wall_x, 12 if lvl >= 3 else 40, 12, 12), false)
			wall_x += 14
			if wall_x > (74.0 if lvl >= 3 else 136.0):
				break
	# La cama: cartón, o estibas con el cartón encima. Y la cobija.
	var raised: bool = c.get("cama_estiba", false)
	if raised:
		r.draw_rect(Rect2(18, 48, 56, 10), WOOD)
		for x in range(20, 74, 9):
			r.draw_line(Vector2(x, 48), Vector2(x, 58), INK)
	r.draw_rect(Rect2(18, 40, 56, 10 if raised else 14), CARTON.lightened(0.12))
	if c.get("cobija", false):
		r.draw_rect(Rect2(34, 40, 40, 10), Color(0.72, 0.24, 0.26))
		for x in range(36, 74, 6):
			r.draw_line(Vector2(x, 40), Vector2(x, 50), Color(0.82, 0.68, 0.3))
	r.draw_rect(Rect2(20, 41, 12, 7), Color(0.85, 0.85, 0.8))  # la almohada (una chaqueta doblada)
	# La caja, con candado si lo tiene. Y la repisa encima, con lo que hay guardado.
	r.draw_rect(Rect2(150, 36, 24, 14), WOOD.lightened(0.1))
	r.draw_line(Vector2(150, 42), Vector2(174, 42), INK)
	if c.get("candado", false):
		r.draw_rect(Rect2(160, 42, 4, 4), Color(0.95, 0.8, 0.3))
	if c.get("repisa", false):
		r.draw_rect(Rect2(140, 26, 46, 3), WOOD)
		var x := 142.0
		for b in box.slice(0, 3):
			r.draw_texture_rect(Items.icon(b["id"]), Rect2(x, 15, 11, 11), false)
			x += 14
	# La alcancía: una tabla floja en el piso.
	r.draw_rect(Rect2(28, 100, 16, 6), WOOD.darkened(0.2))
	r.draw_line(Vector2(28, 100), Vector2(44, 99), INK)
	# La tabla con la piedra: donde se arma.
	r.draw_rect(Rect2(114, 88, 24, 8), WOOD.lightened(0.05))
	r.draw_circle(Vector2(133, 86), 3.5, Color(0.55, 0.55, 0.58))
	# La cocinita.
	if c.get("cocinita", false):
		r.draw_texture(load("res://assets/barrio/cocinita.png"), Vector2(162, 90))
	# Las alarmas de latas, colgadas de la cuerda.
	if c.get("alarma", false):
		for x in [20.0, 70.0, 120.0, 170.0]:
			r.draw_line(Vector2(x, 2), Vector2(x, 8), Color(0.8, 0.78, 0.7))
			r.draw_rect(Rect2(x - 2, 8, 4, 5), Color(0.75, 0.76, 0.8))
