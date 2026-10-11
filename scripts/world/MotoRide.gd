extends Node2D
## El recuerdo de la moto: la ruta hasta la casa de ella, vista desde atrás (pseudo-3D, como
## Road Rash / OutRun). Técnica clásica de carretera por segmentos: la pista es una lista de
## tramos cortos con curva y altura; cada cuadro se proyectan los ~160 tramos de adelante, se
## acumula la curva (así la ruta "dobla") y se dibuja de atrás para adelante. Los árboles,
## postes, vallas y casas van al costado; en la calle hay tráfico (taxi, buseta, camión), baches
## y conos.
##   Arriba / E: acelerar. Abajo: frenar. Izquierda / derecha: doblar.
##   (En las carreras de los sueños E no acelera: es la patada / la botella; ver Carrera.gd.)
## Al llegar: la imagen de la llegada, ella en la puerta, y de vuelta al presente.
## Hay que llegar a tiempo (TIME_LIMIT; la vuelta limpia, a fondo, son ~43 s): si no, ella ya no está en
## la puerta y el recuerdo se rebobina ("No. Así no fue.") y se vuelve a empezar desde la salida.
## (Las carreras de los sueños y Rapidito heredan de acá y no tienen este límite: time_limit = 0.)

const W := 320.0
const H := 180.0
const SEG_LEN := 200.0
const ROAD_W := 1800.0          # media calle, en unidades del mundo
const LANES := 3
const CAM_H := 900.0
const FOV := 100.0
const DRAW_DIST := 160
const MAX_SPEED := SEG_LEN * 60.0 * 0.85
const ACCEL := MAX_SPEED / 4.5
const BRAKE := -MAX_SPEED
const DECEL := -MAX_SPEED / 6.0
const OFFROAD_DECEL := -MAX_SPEED / 2.0
const OFFROAD_LIMIT := MAX_SPEED / 4.0
const CENTRIFUGAL := 0.3
const KMH := 112.0              # lo que da una 180 con viento a favor
const PLAYER_W := 0.22          # ancho de la moto, en medias calles
const PAR_TIME := 55.0
const TIME_LIMIT := 60.0
const LATE_LINES := [
	"(Llega tarde. La puerta está cerrada. Ella ya no salió.)",
	"(Llega tarde otra vez. En la ventana, la cortina se mueve y se queda quieta.)",
	"(Tarde. Siempre tarde. Ella ya se cansó de esperar en la puerta.)",
]
const REWIND_LINES := ["(No. Así no fue. Llegó a tiempo.)", "(No. Así no fue. Ese día llegó a tiempo. Ese día sí.)",
	"(No. Así no fue. Llegó a tiempo. Tiene que haber llegado a tiempo.)"]
const CITY := "res://scenes/world/City.tscn"
const MOTO_LORENA := "res://scenes/world/MotoLorena.tscn"

const SKY_TOP := Color(0.95, 0.55, 0.38)
const SKY_LOW := Color(1.0, 0.82, 0.55)
const HAZE := Color(1.0, 0.8, 0.6)
const GRASS := [Color(0.47, 0.6, 0.27), Color(0.42, 0.55, 0.24)]
const RUMBLE := [Color(0.85, 0.25, 0.2), Color(0.94, 0.92, 0.86)]
const ROAD := [Color(0.44, 0.41, 0.43), Color(0.41, 0.39, 0.41)]
const LANE := Color(0.94, 0.92, 0.86)

const LINES_CAR := [
	"El taxista pita. Él pita. Diálogo de iguales.",
	"Casi se come la buseta. Pasajero de primera fila.",
	"El camión ni se enteró. Él sí. Mucho.",
]
const LINES_HOLE := [
	"Bache. La carretera tiene más cráteres que la luna.",
	"¡Bache! El estómago, al casco.",
	"Otro bache. A este país le falta asfalto y le sobra fe.",
]
const LINES_CONE := ["Cono. Perdón, cono.", "Un cono de recuerdo. Literal."]
const LINES_OFF := [
	"Fuera de la carretera. La moto bien, él bien. El orgullo, en urgencias.",
	"Un árbol. Siempre hay un árbol. Los árboles no se mueven.",
]


class Seg:
	var index := 0
	var y1 := 0.0
	var y2 := 0.0
	var curve := 0.0
	var sprites: Array = []     # {"tex", "offset", "w", "solid"}
	var obstacles: Array = []   # {"kind", "tex", "offset", "w", "hit"}
	var clip := 0.0
	var fog := 0.0
	# proyección de este cuadro (p1 = cerca, p2 = lejos)
	var x1 := 0.0
	var sy1 := 0.0
	var w1 := 0.0
	var s1 := 0.0
	var x2 := 0.0
	var sy2 := 0.0
	var w2 := 0.0
	var s2 := 0.0
	var cz1 := 0.0


## Lo que cambia cada carrera (la serie CARRERAS lo cambia en setup()).
var accel_on_interact := true  # E acelera (en las carreras con rivales, E pega)
var sky_top := SKY_TOP
var sky_low := SKY_LOW
var haze := HAZE
var grass: Array = GRASS
var rumble: Array = RUMBLE
var road: Array = ROAD
var hills := [Color(0.62, 0.4, 0.48), Color(0.5, 0.36, 0.46)]
var sun := true
var start_line := "(Le da dos palmadas al tanque. Despacio: es el primer día de los dos.)"
var half_line := "(Ella la va a ver y se va a reír. Se ríe lindo.)"
var time_limit := 0.0  # 0 = sin límite (las carreras de los sueños, Rapidito)
var goal_label := "LA CASA DE ELLA"


## Para sobreescribir: la carrera cambia colores, frases y pista acá.
func setup() -> void:
	time_limit = TIME_LIMIT  # el recuerdo: hay que llegar antes de que ella se canse de esperar


var segments: Array[Seg] = []
var cars: Array = []            # {"tex", "offset", "z", "speed", "w"}
var track_len := 0.0
var finish_z := 0.0
var cam_depth := 0.0
var player_z := 0.0
var position_z := 0.0
var player_x := 0.0
var speed := 0.0
var sky_offset := 0.0
var state := "countdown"        # countdown, ride, finish, arrival
var time := 0.0
var crashes := 0
var _shake := 0.0
var _hit_cooldown := 0.0
var _said_half := false
var _vis: Array[Seg] = []
var _tex := {}
var _bike: Dictionary
var _lean := 0

var _hud_time: Label
var _hud_speed: Label
var _hud_center: Label
var _progress: ColorRect
var _progress_dot: ColorRect
var _engine: AudioStreamPlayer
var _fade: ColorRect


func _ready() -> void:
	setup()
	cam_depth = 1.0 / tan(deg_to_rad(FOV / 2.0))
	player_z = CAM_H * cam_depth
	for n in ["taxi", "buseta", "camion", "cono", "bache", "arbol", "poste", "valla", "meta", "casa_ella"]:
		_tex[n] = load("res://assets/moto/%s.png" % n)
	for n in ["house_a", "house_b", "house_c", "house_e", "tree_sparse", "kiosk"]:
		_tex[n] = load("res://assets/barrio/%s.png" % n)
	_bike = {-1: load("res://assets/moto/bike_l.png"), 0: load("res://assets/moto/bike_c.png"), 1: load("res://assets/moto/bike_r.png")}
	_build_track()
	_build_hud()
	_engine = AudioStreamPlayer.new()
	var e: AudioStreamWAV = load("res://assets/music/engine.wav")
	e.loop_mode = AudioStreamWAV.LOOP_FORWARD
	e.loop_end = int(e.get_length() * e.mix_rate)
	_engine.stream = e
	_engine.volume_db = -12.0
	add_child(_engine)
	_engine.play()
	_countdown()


# ---------------------------------------------------------------- La pista

func _last_y() -> float:
	return 0.0 if segments.is_empty() else segments[-1].y2


func _add_seg(curve: float, y: float) -> void:
	var s := Seg.new()
	s.index = segments.size()
	s.y1 = _last_y()
	s.y2 = y
	s.curve = curve
	segments.append(s)


static func _ease_in(a: float, b: float, p: float) -> float:
	return a + (b - a) * p * p


static func _ease_in_out(a: float, b: float, p: float) -> float:
	return a + (b - a) * (-cos(p * PI) / 2.0 + 0.5)


## Un tramo: entra a la curva/loma, se mantiene, sale. hill = cuánto sube (en tramos).
func _road(enter: int, hold: int, leave: int, curve: float, hill: float) -> void:
	var y0 := _last_y()
	var y1 := y0 + hill * SEG_LEN
	var total := float(enter + hold + leave)
	for n in enter:
		_add_seg(_ease_in(0.0, curve, n / float(enter)), _ease_in_out(y0, y1, n / total))
	for n in hold:
		_add_seg(curve, _ease_in_out(y0, y1, (n + enter) / total))
	for n in leave:
		_add_seg(_ease_in_out(curve, 0.0, n / float(leave)), _ease_in_out(y0, y1, (n + enter + hold) / total))


func _build_track() -> void:
	seed(1806)  # siempre la misma ruta: es un recuerdo
	_road(25, 25, 25, 0, 0)
	_road(50, 50, 50, 2, 20)
	_road(50, 50, 50, 0, -20)
	_road(40, 40, 40, -3, 0)
	_road(25, 25, 25, 3, 0)
	_road(25, 25, 25, -3, 0)
	_road(50, 100, 50, 0, 40)
	_road(50, 50, 50, 4, -40)
	_road(40, 40, 40, -2, 30)
	_road(30, 30, 30, 5, 0)
	_road(30, 30, 30, -5, 0)
	_road(60, 100, 60, 0, -30)
	_road(50, 50, 50, -4, 20)
	_road(50, 50, 50, 3, -20)
	_road(80, 80, 80, 0, 0)
	var finish_index := segments.size()
	_road(100, 100, 100, 0, 0)  # después de la meta (para que se vea lejos)
	track_len = segments.size() * SEG_LEN
	finish_z = finish_index * SEG_LEN

	var near_end := finish_index - 200
	for i in segments.size():
		var s := segments[i]
		# Al costado: árboles de guayacán y postes; vallas de vez en cuando; casas al llegar.
		if i % 8 == 0:
			_side(s, "arbol" if i % 16 == 0 else "poste", -1.35 - randf() * 0.3, 0.55 if i % 16 == 0 else 0.12)
			_side(s, "poste" if i % 16 == 0 else "arbol", 1.35 + randf() * 0.3, 0.12 if i % 16 == 0 else 0.55)
		if i % 90 == 45:
			_side(s, "valla", (1.0 if i % 180 == 45 else -1.0) * 1.9, 1.0)
		if i > near_end and i < finish_index and i % 14 == 0:
			var house: String = ["house_a", "house_b", "house_c", "house_e"].pick_random()
			_side(s, house, -2.3, 1.6)
			_side(s, ["house_a", "house_e", "kiosk", "tree_sparse"].pick_random(), 2.3, 1.4)
		# En la calle: baches y conos (ni al principio ni en la recta final).
		if i > 120 and i < near_end and i % 37 == 0:
			var kind := "bache" if randf() < 0.65 else "cono"
			s.obstacles.append({"kind": kind, "tex": _tex[kind], "offset": randf_range(-0.7, 0.7),
				"w": 0.38 if kind == "bache" else 0.12, "hit": false})
	segments[finish_index].sprites.append({"tex": _tex["meta"], "offset": 0.0, "w": 2.3, "solid": false})
	if goal_label == "LA CASA DE ELLA":  # la de ella: cuatro pisos, al lado de la meta
		_side(segments[finish_index + 2], "casa_ella", 2.0, 1.9)
	# El tráfico: van más despacio que vos, por su carril.
	for k in 26:
		var kind: String = ["taxi", "taxi", "buseta", "camion"].pick_random()
		var z := randf_range(40.0, finish_index - 100.0) * SEG_LEN
		cars.append({"tex": _tex[kind], "offset": [-0.66, 0.0, 0.66].pick_random() + randf_range(-0.1, 0.1),
			"z": z, "speed": MAX_SPEED * randf_range(0.25, 0.5),
			"w": {"taxi": 0.42, "buseta": 0.55, "camion": 0.6}[kind]})
	randomize()  # lo demás del juego vuelve a ser al azar


func _side(s: Seg, tex: String, offset: float, w: float) -> void:
	s.sprites.append({"tex": _tex[tex], "offset": offset, "w": w, "solid": true})


func _find(z: float) -> Seg:
	return segments[int(floor(z / SEG_LEN)) % segments.size()]


# ---------------------------------------------------------------- Juego

func _countdown() -> void:
	if time_limit > 0.0:  # el recuerdo de la moto (no Rapidito ni los sueños): la foto del primer día
		await Recuerdo.show("renegade")
	MusicDirector.force("")
	await get_tree().create_timer(0.8).timeout
	Narrator.say(start_line, true)
	for t in ["3", "2", "1"]:
		_hud_center.text = t
		await get_tree().create_timer(0.8).timeout
	_hud_center.text = "¡YA!"
	state = "ride"
	MusicDirector.force("moto_ride")
	await get_tree().create_timer(0.8).timeout
	if _hud_center.text == "¡YA!":
		_hud_center.text = ""


func _physics_process(dt: float) -> void:
	_engine.pitch_scale = 0.55 + 1.5 * speed / MAX_SPEED
	_shake = maxf(0.0, _shake - dt * 3.0)
	_hit_cooldown -= dt
	match state:
		"ride":
			time += dt
			_ride(dt)
			if time_limit > 0.0 and time > time_limit and state == "ride":
				_late()
		"late":
			speed = move_toward(speed, 0.0, MAX_SPEED * dt * 0.8)
			position_z += speed * dt
		"finish":
			speed = move_toward(speed, 0.0, MAX_SPEED * dt * 0.6)
			position_z += speed * dt
			if speed <= 1.0:
				state = "arrival"
				_arrival()
	_move_cars(dt)
	_update_hud()
	queue_redraw()


func _ride(dt: float) -> void:
	var pseg := _find(position_z + player_z)
	var pct := speed / MAX_SPEED
	var dx := dt * 2.0 * pct
	_lean = 0
	if Input.is_action_pressed("move_left"):
		player_x -= dx
		_lean = -1
	elif Input.is_action_pressed("move_right"):
		player_x += dx
		_lean = 1
	player_x -= dx * pct * pseg.curve * CENTRIFUGAL
	if Input.is_action_pressed("move_up") or (accel_on_interact and Input.is_action_pressed("interact")):
		speed += ACCEL * dt
	elif Input.is_action_pressed("move_down"):
		speed += BRAKE * dt
	else:
		speed += DECEL * dt
	sky_offset += pseg.curve * pct * dt * 60.0
	if absf(player_x) > 1.0:
		if speed > OFFROAD_LIMIT:
			speed += OFFROAD_DECEL * dt
		_shake = maxf(_shake, 0.3)
		for sp in pseg.sprites:
			if sp["solid"] and _overlap(player_x, PLAYER_W, sp["offset"], sp["w"] * 0.6):
				_crash(LINES_OFF, 0.0)
				player_x = signf(player_x) * 0.8
				position_z = maxf(0.0, position_z - SEG_LEN * 2.0)
				break
	for ob in pseg.obstacles:
		if not ob["hit"] and _overlap(player_x, PLAYER_W, ob["offset"], ob["w"]):
			ob["hit"] = true
			if ob["kind"] == "bache":
				_crash(LINES_HOLE, 0.5)
			elif ob["kind"] in ["zapato", "bolso", "cadena"]:
				ob["offset"] += 3.0 * signf(ob["offset"] - player_x + 0.01)
				_crash({"zapato": ["Un tacón en la cara. En el sueño no duele. Lo que duele es de quién es.", "Otro zapato. Esta mujer tiene más zapatos que escrúpulos, y no le sobran zapatos."],
					"bolso": ["Un bolso. Pesa. Adentro debe estar lo que le quitó a Guillermo.", "Bolsazo. Hasta dormido le pegan."],
					"cadena": ["Cadena de oro en la rueda. Lo único de oro que le han tirado.", "Otra cadena. Guillermo siempre pagó con oro lo que no podía pagar con nada más."]}[ob["kind"]], 0.55)
			elif ob["kind"] == "reten":
				_crash(["Retén. Se come la barrera. El ejército no se mueve.", "Otro retén. Ni en sueños lo dejan pasar."], 0.25)
			else:
				ob["offset"] += 3.0 * signf(ob["offset"] - player_x + 0.01)  # el cono sale volando
				_crash(LINES_CONE, 0.75)
	for car in cars:
		var cseg := _find(car["z"])
		if cseg.index == pseg.index and speed > car["speed"] and _overlap(player_x, PLAYER_W, car["offset"], car["w"] * 0.8):
			speed = car["speed"] * 0.6
			position_z = car["z"] - player_z - 10.0
			_crash(LINES_CAR, -1.0)
			break
	player_x = clampf(player_x, -2.5, 2.5)
	speed = clampf(speed, 0.0, MAX_SPEED)
	position_z += speed * dt
	if not _said_half and position_z > finish_z * 0.5:
		_said_half = true
		Narrator.say(half_line, true)
	if position_z + player_z >= finish_z:
		state = "finish"
		_hud_center.text = "LLEGASTE"


## keep = cuánto de la velocidad se conserva (-1: lo decide quien llama).
func _crash(lines: Array, keep: float) -> void:
	_shake = 1.0
	if keep >= 0.0:
		speed *= keep
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = 2.5
	crashes += 1
	Narrator.say(lines[crashes % lines.size()], true)


func _overlap(x1: float, w1: float, x2: float, w2: float) -> bool:
	return absf(x1 - x2) < (w1 + w2) / 2.0


func _move_cars(dt: float) -> void:
	for car in cars:
		car["z"] = fposmod(car["z"] + car["speed"] * dt, finish_z)


# ---------------------------------------------------------------- Dibujo

func _project(s: Seg, cam_x1: float, cam_x2: float, cam_y: float, cam_z: float) -> void:
	var cz1: float = s.index * SEG_LEN - cam_z
	var cz2 := cz1 + SEG_LEN
	s.cz1 = cz1
	s.s1 = cam_depth / maxf(cz1, 0.001)
	s.x1 = W / 2.0 + s.s1 * (-cam_x1) * W / 2.0
	s.sy1 = H / 2.0 - s.s1 * (s.y1 - cam_y) * H / 2.0
	s.w1 = s.s1 * ROAD_W * W / 2.0
	s.s2 = cam_depth / maxf(cz2, 0.001)
	s.x2 = W / 2.0 + s.s2 * (-cam_x2) * W / 2.0
	s.sy2 = H / 2.0 - s.s2 * (s.y2 - cam_y) * H / 2.0
	s.w2 = s.s2 * ROAD_W * W / 2.0


func _draw() -> void:
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 2.0
	draw_set_transform(shake)
	_draw_background()
	var base := _find(position_z)
	var base_pct := fposmod(position_z, SEG_LEN) / SEG_LEN
	var pseg := _find(position_z + player_z)
	var ppct := fposmod(position_z + player_z, SEG_LEN) / SEG_LEN
	var player_y := lerpf(pseg.y1, pseg.y2, ppct)
	var cam_y := player_y + CAM_H
	var maxy := H
	var x := 0.0
	var dx := -base.curve * base_pct
	_vis.clear()
	for n in DRAW_DIST:
		var s: Seg = segments[(base.index + n) % segments.size()]
		var cam_z := position_z - (track_len if s.index < base.index else 0.0)
		_project(s, player_x * ROAD_W - x, player_x * ROAD_W - x - dx, cam_y, cam_z)
		x += dx
		dx += s.curve
		s.fog = pow(n / float(DRAW_DIST), 2.0) * 0.85
		s.clip = maxy
		if s.cz1 <= cam_depth or s.sy2 >= s.sy1 or s.sy2 >= maxy:
			continue
		_vis.append(s)
		maxy = s.sy2
	# La calle, de atrás para adelante (lo cercano tapa a lo lejano).
	for k in range(_vis.size() - 1, -1, -1):
		_draw_segment(_vis[k])
	# Lo que está arriba de la calle, también de atrás para adelante.
	var cars_by_seg := {}
	for car in cars:
		var idx := _find(car["z"]).index
		if not cars_by_seg.has(idx):
			cars_by_seg[idx] = []
		cars_by_seg[idx].append(car)
	for k in range(_vis.size() - 1, -1, -1):
		var s: Seg = _vis[k]
		for ob in s.obstacles:
			_draw_sprite(ob["tex"], ob["w"], s.s1, s.x1, s.sy1, ob["offset"], s.clip, s.fog)
		for car in cars_by_seg.get(s.index, []):
			var p := fposmod(car["z"], SEG_LEN) / SEG_LEN
			_draw_sprite(car["tex"], car["w"], lerpf(s.s1, s.s2, p), lerpf(s.x1, s.x2, p), lerpf(s.sy1, s.sy2, p),
				car["offset"], s.clip, s.fog)
		for sp in s.sprites:
			_draw_sprite(sp["tex"], sp["w"], s.s1, s.x1, s.sy1, sp["offset"], s.clip, s.fog)
	# Él, en la moto.
	if state != "arrival":
		var tex: Texture2D = _bike[_lean]
		var bounce := sin(Time.get_ticks_msec() / 60.0) * (1.0 if absf(player_x) > 1.0 else 0.3) * (speed / MAX_SPEED)
		var at := Vector2(W / 2.0 - tex.get_width() / 2.0, H - tex.get_height() - 4 + bounce)
		draw_texture(tex, at)
		_draw_rider_extra(at, tex.get_size())
	draw_set_transform(Vector2.ZERO)


## Para sobreescribir: algo más del que maneja (la pierna de la patada en las carreras).
func _draw_rider_extra(_at: Vector2, _size: Vector2) -> void:
	pass


func _draw_background() -> void:
	for i in 24:  # cielo de atardecer
		var k := i / 23.0
		draw_rect(Rect2(0, i * 4.0, W, 4.0), sky_top.lerp(sky_low, k))
	if sun:
		draw_circle(Vector2(fposmod(230.0 - sky_offset * 0.2, W + 60.0) - 30.0, 62.0), 16.0, Color(1.0, 0.9, 0.62))
	for layer in 2:  # cerros, con paralaje
		var off := sky_offset * (0.4 + layer * 0.5)
		var pts := PackedVector2Array([Vector2(0, H / 2.0 + 20)])
		for xi in range(0, int(W) + 8, 8):
			var xx := float(xi)
			var h := 18.0 + sin((xx + off) * 0.021 + layer) * 10.0 + sin((xx + off) * 0.057 + layer * 3.0) * 5.0 - layer * 8.0
			pts.append(Vector2(xx, H / 2.0 + 4 - h))
		pts.append(Vector2(W + 8, H / 2.0 + 20))
		draw_colored_polygon(pts, hills[layer])


func _draw_segment(s: Seg) -> void:
	var alt := int(s.index / 3) % 2
	var fog := s.fog
	draw_rect(Rect2(0, s.sy2, W, s.sy1 - s.sy2 + 1), grass[alt].lerp(haze, fog))
	var r1 := s.w1 / 6.0
	var r2 := s.w2 / 6.0
	_quad(s.x1 - s.w1 - r1, s.x1 - s.w1, s.sy1, s.x2 - s.w2 - r2, s.x2 - s.w2, s.sy2, rumble[alt].lerp(haze, fog))
	_quad(s.x1 + s.w1, s.x1 + s.w1 + r1, s.sy1, s.x2 + s.w2, s.x2 + s.w2 + r2, s.sy2, rumble[alt].lerp(haze, fog))
	_quad(s.x1 - s.w1, s.x1 + s.w1, s.sy1, s.x2 - s.w2, s.x2 + s.w2, s.sy2, road[alt].lerp(haze, fog))
	if alt == 0:
		var l1 := s.w1 / 32.0
		var l2 := s.w2 / 32.0
		for lane in range(1, LANES):
			var lx1 := s.x1 - s.w1 + s.w1 * 2.0 / LANES * lane
			var lx2 := s.x2 - s.w2 + s.w2 * 2.0 / LANES * lane
			_quad(lx1 - l1, lx1 + l1, s.sy1, lx2 - l2, lx2 + l2, s.sy2, LANE.lerp(haze, fog))


func _quad(xa1: float, xb1: float, y1: float, xa2: float, xb2: float, y2: float, c: Color) -> void:
	# draw_primitive no triangula: no falla con tramos casi planos (lejos o en la cresta de una loma).
	draw_primitive(PackedVector2Array([Vector2(xa1, y1), Vector2(xb1, y1), Vector2(xb2, y2), Vector2(xa2, y2)]),
		PackedColorArray([c, c, c, c]), PackedVector2Array())


## Un objeto parado sobre la calle (o al costado), escalado por la distancia y recortado por las lomas.
func _draw_sprite(tex: Texture2D, w_frac: float, scale: float, sx: float, sy: float, offset: float, clip: float, fog: float) -> void:
	var dw := w_frac * ROAD_W * scale * W / 2.0
	if dw < 0.5:
		return
	var dh := dw * tex.get_height() / float(tex.get_width())
	var dx := sx + scale * offset * ROAD_W * W / 2.0 - dw / 2.0
	var dy := sy - dh
	var cut := maxf(0.0, dy + dh - clip)
	if cut >= dh:
		return
	var src := Rect2(0, 0, tex.get_width(), tex.get_height() * (dh - cut) / dh)
	draw_texture_rect_region(tex, Rect2(dx, dy, dw, dh - cut), src, Color(1, 1, 1).lerp(haze, fog * 0.7))


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_hud_time = _hud_label(ui, Vector2(6, 4), Color(1, 0.95, 0.8))
	_hud_speed = _hud_label(ui, Vector2(218, 4), Color(1, 0.95, 0.8))
	_hud_speed.size = Vector2(96, 10)
	_hud_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_center = _hud_label(ui, Vector2(0, 96), Color(1, 0.9, 0.4))
	_hud_center.size = Vector2(W, 16)
	_hud_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_center.add_theme_font_size_override("font_size", 16)
	var bar := ColorRect.new()
	bar.color = Color(0.15, 0.1, 0.12, 0.6)
	bar.position = Vector2(114, 8)
	bar.size = Vector2(96, 4)
	ui.add_child(bar)
	_progress = ColorRect.new()
	_progress.color = Color(1, 0.8, 0.35)
	_progress.position = bar.position
	_progress.size = Vector2(0, 4)
	ui.add_child(_progress)
	var home := _hud_label(ui, Vector2(90, 15), Color(1, 0.9, 0.8))
	home.text = goal_label
	home.size = Vector2(120, 10)
	home.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.size = Vector2(W, H)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)


func _hud_label(parent: Node, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.1))
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _update_hud() -> void:
	_hud_time.text = "TIEMPO %s" % _clock(time)
	if time_limit > 0.0:
		var left := maxf(0.0, time_limit - time)
		_hud_time.text = "QUEDAN %s" % _clock(ceilf(left))
		var hurry := left < 10.0 and state == "ride"
		var blink := hurry and int(time * 4.0) % 2 == 0
		_hud_time.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if blink else Color(1, 0.95, 0.8))
	_hud_speed.text = "%03d km/h" % int(speed / MAX_SPEED * KMH)
	_progress.size.x = 96.0 * clampf((position_z + player_z) / finish_z, 0.0, 1.0)


static func _clock(t: float) -> String:
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]


# ---------------------------------------------------------------- Tarde

## Se acabó el tiempo: ella ya no está. Se rebobina y se vuelve a empezar.
func _late() -> void:
	state = "late"
	var f := GameState.flags
	var n := int(f.get("moto_tarde", 0))
	f["moto_tarde"] = n + 1
	_hud_center.text = "TARDE"
	Narrator.say(LATE_LINES[n % LATE_LINES.size()], true)
	await get_tree().create_timer(2.2).timeout
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.6)
	await t.finished
	_engine.stop()
	_hud_center.text = ""
	Narrator.say(REWIND_LINES[n % REWIND_LINES.size()], true)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()  # desde la salida, otra vez


# ---------------------------------------------------------------- La llegada

func _arrival() -> void:
	var f := GameState.flags
	var best: float = f.get("moto_best", INF)
	f["moto_best"] = minf(best, time)
	var verdict := "Sin caídas. Un milagro con ruedas." if crashes == 0 else \
		("%d golpes. La moto tiene una hora y ya tiene historia." % crashes)
	if time <= PAR_TIME:
		verdict += " Y a tiempo."
	_hud_center.text = ""
	Narrator.say("TIEMPO %s. %s" % [_clock(time), verdict], true)
	await get_tree().create_timer(2.5).timeout
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 1.0)
	await t.finished
	_engine.stop()
	var pic := TextureRect.new()
	pic.texture = load("res://assets/moto/llegada.png")
	pic.modulate.a = 0.0
	_fade.get_parent().add_child(pic)
	create_tween().tween_property(pic, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(1.6).timeout
	# Lo que duele va sin chiste, y en tercera persona.
	await Dialogue.talk([
		["", "Frena frente a la casa: cuatro pisos de ladrillo, el tanque azul arriba. El motor hace tic, tic, tic, enfriándose."],
		["", "Ella sale a la puerta. Se queda mirando la moto. Después lo mira a él."],
		["LORENA", "—¡Está hermosa!"],
		["", "(Él le señala el puesto de atrás. Le ofrece el casco.)"],
		["LORENA", "—¿Y me despeino? ... Bueno. Una vuelta. Pero despacio, ¿oyó? DESPACIO."],
	])
	var out := create_tween()
	out.tween_property(pic, "modulate:a", 0.0, 1.5)
	await out.finished
	SceneRouter.go(MOTO_LORENA)  # la primera vuelta, con ella atrás


func _back_to_present() -> void:
	var f := GameState.flags
	f["flashback_moto_seen"] = true
	var memories: Array = f.get("memories", [])
	memories.append("moto")
	f["memories"] = memories
	GameState.complete_quest("moto_cafe")
	GameState.start_quest("sobrevivir")
	GameState.start_quest("lukas_comida")
	SceneRouter.go(CITY, "FromCafe", "", "(La café de enfrente arranca y se va. El dueño ni lo miró.)")
