extends Location
## Adentro del cambuche (con toldo ya hay un adentro): un cuartico donde se camina, con lo suyo puesto.
## La cama, la caja (y encima, en la repisa, lo que guarda), la alcancía debajo de la tabla floja, la
## cocinita, el tablero y una tabla con una piedra para armar. Desde la calle no se ve nada: es lo
## primero que tiene con puerta, aunque la puerta sea una cortina.
## Lo que hace cada cosa es lo mismo que el menú del cambuche (SleepSpot): aquí hay uno escondido.
## Se sale por la cortina, al mismo lugar por donde entró (GameState.flags["casa_volver"]).

const PLASTIC := Color(0.22, 0.38, 0.62)
const CARTON := Color(0.58, 0.43, 0.27)
const WOOD := Color(0.5, 0.36, 0.22)
const INK := Color(0.08, 0.06, 0.08)
## Lo que se cuelga en la pared, si lo tiene (en la mochila o en la caja).
const KEEPSAKES := ["foto", "foto_entera", "dibujo_victoria", "estampita", "carta_ines"]

var spot: SleepSpot  # el del menú (escondido): Caja, Alcancía, Cocinar, Mejorar, Armar...


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
	super._ready()
	if not GameState.flags.get("casa_vista", false):
		GameState.flags["casa_vista"] = true
		Narrator.say("(Adentro no se ve la calle. La calle tampoco lo ve a él. Es lo primero con puerta que tiene, aunque la puerta sea de plástico.)")


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
	else:
		r.draw_rect(Rect2(0, 0, w, 34), PLASTIC)
		for x in range(8, int(w), 22):  # los pliegues del plástico
			r.draw_line(Vector2(x, 0), Vector2(x - 4, 34), PLASTIC.darkened(0.25))
			r.draw_line(Vector2(x + 2, 0), Vector2(x - 2, 34), PLASTIC.lightened(0.15))
		r.draw_line(Vector2(0, 2), Vector2(w, 2), Color(0.85, 0.82, 0.7), 1.0)  # la cuerda que lo sostiene
	r.draw_rect(Rect2(0, 33, w, 2), INK)
	# Los lados, más oscuros: se siente cerrado.
	var side := PLASTIC.darkened(0.45) if lvl < 3 else WOOD.darkened(0.45)
	r.draw_rect(Rect2(0, 0, 6, h), side)
	r.draw_rect(Rect2(w - 6, 0, 6, h), side)
	# La cortina de la puerta, abajo.
	r.draw_rect(Rect2(0, h - 4, w, 4), INK)
	r.draw_rect(Rect2(82, h - 6, 28, 6), Color(0.62, 0.2, 0.22))
	# El tablero, en la pared.
	r.draw_rect(Rect2(84, 10, 24, 18), Color(0.62, 0.45, 0.3))
	r.draw_rect(Rect2(86, 12, 8, 6), Color(0.95, 0.93, 0.86))
	r.draw_rect(Rect2(97, 13, 8, 9), Color(0.92, 0.88, 0.62))
	r.draw_rect(Rect2(88, 20, 7, 6), Color(0.86, 0.92, 0.96))
	# Lo de colgar: la foto, el dibujo de Victoria... en la pared, al lado del tablero.
	var wall_x := 46.0
	var box: Array = c.get("box", [])
	for keep in KEEPSAKES:
		if GameState.count(keep) > 0 or box.any(func(b): return b["id"] == keep):
			r.draw_texture_rect(Items.icon(keep), Rect2(wall_x, 12, 12, 12), false)
			wall_x += 14
			if wall_x > 74:
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
