extends Node2D
## SUEÑO 2: "PLOMO" — un shooter de los 90 (tipo Doom / Wolfenstein), soñado la noche del Día 3.
## En el episodio 1 él es un niño de diez años con una pistola, y los enemigos son demonios de
## dibujo infantil (paredes de crayón, cielo con estrellas dibujadas). Los episodios 2 y 3 ya lo
## encuentran adulto (la serie crece con él).
## Motor: raycasting clásico. Por cada columna de la pantalla se tira un rayo por la grilla del
## mapa (DDA); la distancia a la pared da el alto del trozo de pared, que se dibuja con su textura.
## Los enemigos y objetos son sprites de frente que se escalan con la distancia y se tapan con
## las paredes (z-buffer por columna).
## Nivel: callejón → calle → bodega (Lilato, mini jefe, tiene la llave) → mansión de Lisandro
## (jefe final) → SALIDA. Al terminar (o perder) se despierta y la noche sigue (Night.tscn).
##   Arriba/abajo: caminar. Izquierda/derecha o mouse: girar. E / espacio / clic: disparar.
##   X (o 1, 2, 3): cambiar de arma.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NIGHT := "res://scenes/world/Night.tscn"
const W := 320
const VIEW_H := 148.0
const FOV_PLANE := 0.66
const MOVE_SPEED := 3.4
const TURN_SPEED := 2.6
const MOUSE_SENS := 0.0035
const RADIUS := 0.22
const WALL_TEX := {"#": "kid_ladrillo", "C": "kid_dibujos", "Z": "kid_azul", "W": "kid_cafe", "G": "kid_estrellas",
	"D": "kid_puerta", "L": "kid_puerta_llave", "E": "kid_salida"}

## Enemigos: vida, velocidad, alcance, daño, espera entre ataques, tipo de ataque, alto en pantalla.
const KINDS := {
	"jibaro": {"hp": 30, "speed": 1.7, "range": 0.9, "dmg": 10, "cd": 1.0, "attack": "melee", "h": 0.8, "sprite": "kid_jibaro"},
	"campanero": {"hp": 15, "speed": 2.3, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.75, "sprite": "kid_campanero"},
	"motorizado": {"hp": 40, "speed": 2.4, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.8, "sprite": "kid_motorizado"},
	"rappi": {"hp": 35, "speed": 1.3, "range": 10.0, "dmg": 12, "cd": 2.0, "attack": "pedido", "h": 0.8, "sprite": "kid_rappi"},
	"lilato": {"hp": 170, "speed": 1.8, "range": 8.0, "dmg": 10, "cd": 1.7, "attack": "fan:saliva", "h": 0.8, "sprite": "kid_lilato"},
	"lisandro": {"hp": 420, "speed": 1.2, "range": 12.0, "dmg": 7, "cd": 1.4, "attack": "burst", "h": 1.05, "sprite": "kid_lisandro"},
}
## Armas: daño, espera, munición que usa, perdigones, dispersión.
const WEAPONS := [
	{"name": "PUÑO", "tex": "puno", "dmg": 15, "cd": 0.45, "ammo": "", "pellets": 1, "spread": 0.0, "reach": 1.2},
	{"name": "PISTOLA", "tex": "pistola", "dmg": 14, "cd": 0.32, "ammo": "balas", "pellets": 1, "spread": 0.01, "reach": 40.0},
	{"name": "ESCOPETA", "tex": "escopeta", "dmg": 9, "cd": 0.9, "ammo": "cartuchos", "pellets": 7, "spread": 0.09, "reach": 40.0},
]
const PICKUP_TEX := {"balas": "balas", "cartuchos": "cartuchos", "empanada": "empanada", "aguapanela": "aguapanela",
	"chaleco": "chaleco", "llave": "llave", "escopeta": "escopeta", "caneca": "caneca"}
const CHECKPOINTS := [Vector2(2.5, 21.5), Vector2(10.5, 3.5), Vector2(22.6, 5.5), Vector2(22.6, 17.5)]


class Ent:
	var kind := ""
	var pos := Vector2.ZERO
	var hp := 0.0
	var state := "idle"        # idle, chase, attack, pain, dead, flee
	var timer := 0.0
	var cd := 0.0
	var alerted := false
	var moving := false
	var phase := 0


var grid: Array = []
var doors := {}                 # Vector2i -> apertura 0..1
var pos := Vector2(2.5, 21.5)
var ang := -PI / 2.0
var hp := 100.0
var armor := 0.0
var ammo := {"balas": 40, "cartuchos": 0}
var owned := [true, true, false]
var weapon := 1
var has_key := false
var enemies: Array[Ent] = []
var pickups: Array = []         # {"kind", "pos"}
var projectiles: Array = []     # {"tex", "pos", "vel", "dmg"}
var state := "title"            # title, play, dead, done
var checkpoint := 0
var kills := 0
var total := 0
var time := 0.0
var boss_awake := false
var mini_awake := false

## Lo que define el episodio (PLOMO 2 y 3 lo cambian en setup()).
var dream_id := "plomo1"
var title_text := "PLOMO"
var subtitle := "EPISODIO 1: EL QUE ME MANDO A MATAR\n(cuando tenia diez años)"
## "Anteriormente en PLOMO...": se muestra antes de empezar (vacío en el episodio 1).
var recap: Array = []
var wall_tex: Dictionary = WALL_TEX
var kinds: Dictionary = KINDS
var pickup_tex: Dictionary = PICKUP_TEX
var projectile_tex := ["pedido", "cuchillo", "saliva"]
var checkpoints: Array = CHECKPOINTS
var mini_kind := "lilato"
var boss_kind := "lisandro"
var summon_kind := "motorizado"
var summon_points := [Vector2(24.5, 15.5), Vector2(28.5, 19.5)]
## Zonas (índice de checkpoint) donde se despiertan el mini jefe y el jefe.
var mini_zone := 2
var boss_zone := 3
var music := "plomo"
var music_boss := "plomo_boss"
var ceil_cols := [Color(0.06, 0.04, 0.1), Color(0.18, 0.1, 0.16)]
var floor_cols := [Color(0.12, 0.11, 0.12), Color(0.3, 0.27, 0.27)]
var finish_note := "(no hay secretos: los niños lo ven todo)"
## Armas y cara del HUD: de niño en el episodio 1 ("kw_", "kidface_"); de adulto después ("w_", "face_").
var weapon_prefix := "kw_"
var face_prefix := "kidface_"
## Cielo con estrellas y luna dibujadas (el episodio 1, el de niño).
var drawn_sky := true
## Cuánto más duro es este episodio (vida y daño de los enemigos).
var dream_hard := 0.0
## Quién es el jugador: vida máxima, y cuánto más rápido camina y más fuerte pega (Lisandro, drogado).
var max_hp := 100.0
var move_mult := 1.0
var dmg_mult := 1.0
## Color con el que se tiñen las paredes (blanco: como son).
var wall_tint := Color(1, 1, 1)
## A lo Doom (opcional; sin flats_tex queda como antes, con degradé): pisos y techos con textura
## (assets/shaders/plomo_piso.gdshader), luz por casilla (con faroles que titilan) y decorado.
##   floor_map / ceil_map: [y][x] índice en el atlas flats_tex (techo -1 = cielo abierto).
##   light_base: [y][x] 0..1; flicker: Vector2i -> velocidad (las que titilan).
##   props: {"tex", "pos", "h", "r" (si estorba: radio), "anim" (cuadros)}.
var flats_tex: Texture2D = null
var flats_n := 1
var floor_map: Array = []
var ceil_map: Array = []
var light_base: Array = []
var flicker := {}
var props: Array = []
var lines := {
	"start": "Tengo diez años, una pistola y el barrio lleno de demonios. Mi psicólogo estaría orgulloso. Si tuviera psicólogo. O diez años.",
	"mini_wake": "LILATO: —Otra vez vos. ¡Pptt! Perdón. No, no perdón.",
	"mini_half": "LILATO: —No la vas a ver nunca más.",
	"mini_die": "LILATO: —Tomá. Ya que te querés ir...",
	"boss_wake": "LISANDRO: —¿Usted? ¿Todavía vivo?",
	"boss_p1": "LISANDRO: —Yo mandé a que lo mataran. Por envidia, sí. ¿Y qué?",
	"boss_p2": "LISANDRO: —¿Qué tenía usted que no tuviera yo?",
	"boss_die": "LISANDRO: —La gente lo quería a usted. A mí me tenían miedo. No es lo mismo.",
	"boss_reply": "Respuesta a su pregunta: tenía amigos. Y un perro. Bueno, todavía no tengo perro: tengo diez años.",
	"key_use": "La llave de Lilato abre la puerta de Lisandro. Un sueño no tiene que tener sentido.",
	"locked": "Cerrada. La llave la tiene alguien en la bodega. Siempre hay alguien con la llave.",
	"exit_wait": "SALIDA. Todavía no: él sigue ahí.",
	"alert": "(Un pito. Un duende avisó que llegué.)",
	"vest": "Una chaqueta de superhéroe. Me queda grande. Todo me queda grande.",
	"shotgun": "Una escopeta. La agarro con las dos manos y todavía me pesa.",
	"no_ammo": "Sin balas. A puño limpio, como en el recreo.",
}


## Para sobreescribir: el episodio cambia las variables de arriba.
func setup() -> void:
	pass


## Para sobreescribir: cosas especiales del episodio (personajes que no pelean, etc.).
func _special(_delta: float) -> void:
	pass


## Para sobreescribir: sprites extra para dibujar ([posición, textura, alto, elevación]).
func extra_sprites() -> Array:
	return []


## Para sobreescribir: qué pasa al llegar a la SALIDA (con el jefe muerto).
func _on_exit() -> void:
	_finish()


## En qué zona está un punto (para los checkpoints y para despertar a los jefes).
func _zone_of(p: Vector2) -> int:
	if p.x >= 22.0:
		return 2 if p.y < 11.0 else 3
	if p.x >= 10.0:
		return 1
	return 0

var _zbuf := PackedFloat32Array()
var _tex := {}
var _fire_cd := 0.0
var _flash := 0.0
var _hurt := 0.0
var _bonus := 0.0
var _bob := 0.0
var _face_hurt := 0.0
var _face_grin := 0.0
var _msg_cd := 0.0
var _continue := 0.0
var _ui: CanvasLayer
var _big: Label
var _small: Label
var _hud_labels := {}
var _hud_heads: Array[Label] = []
var _face: TextureRect
var _light := PackedFloat32Array()
var _cells_img: Image
var _cells_tex: ImageTexture
var _floor: ColorRect
var _light_t := 0.0
## Los avisos de arriba, por turnos: el que está en pantalla se alcanza a leer antes del siguiente.
var _say_q: Array = []          # [texto, se vence]
var _say_hold := 0.0
## Al reaparecer, un momento sin que le entre nada (si no, lo matan en la puerta una y otra vez).
var _grace := 0.0


func _ready() -> void:
	setup()
	hp = max_hp
	Narrator.top_y = 2.0  # los mensajes, pegados arriba: el centro es para apuntar
	_zbuf.resize(W)
	for k in wall_tex:
		_tex["wall_" + wall_tex[k]] = load("res://assets/shooter/wall_%s.png" % wall_tex[k])
	for k in kinds:
		var spr: String = kinds[k].get("sprite", k)
		for p in ["walk1", "walk2", "attack", "hurt", "dead"]:
			_tex["%s_%s" % [k, p]] = load("res://assets/shooter/%s_%s.png" % [spr, p])
	for k in pickup_tex.values() + projectile_tex:
		_tex[k] = load("res://assets/shooter/%s.png" % k)
	for w in WEAPONS:
		_tex["w_" + w["tex"]] = load("res://assets/shooter/%s%s.png" % [weapon_prefix, w["tex"]])
		_tex["w_%s_fire" % w["tex"]] = load("res://assets/shooter/%s%s_fire.png" % [weapon_prefix, w["tex"]])
	for i in 5:
		_tex["face_%d" % i] = load("res://assets/shooter/%s%d.png" % [face_prefix, i])
	_tex["face_hurt"] = load("res://assets/shooter/%shurt.png" % face_prefix)
	_tex["face_grin"] = load("res://assets/shooter/%sgrin.png" % face_prefix)
	_build_map()
	_place()
	_setup_flats()
	_build_hud()
	MusicDirector.force("")
	_title()


func _exit_tree() -> void:
	Narrator.top_y = 40.0


# ---------------------------------------------------------------- El mapa

func _build_map() -> void:
	grid.clear()
	for y in 24:
		var row := []
		for x in 32:
			row.append("." if x > 0 and x < 31 and y > 0 and y < 23 else "#")
		grid.append(row)
	# Columnas que separan las zonas.
	for y in 24:
		grid[y][9] = "#"
		grid[y][21] = "C"
	for x in range(21, 32):
		grid[11][x] = "G"
	# A: el callejón (ladrillo), con muros en zigzag.
	for x in range(1, 6):
		grid[6][x] = "#"
		grid[17][x] = "#"
	for x in range(4, 9):
		grid[12][x] = "#"
	grid[3][9] = "D"
	# B: la calle (concreto con grafiti), con carros quemados / bloques.
	for p in [Vector2i(13, 5), Vector2i(17, 10), Vector2i(13, 15), Vector2i(17, 19)]:
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			grid[p.y + d.y][p.x + d.x] = "Z"
	for y in range(1, 23):
		grid[y][31] = "C" if y < 11 else "G"
	for x in range(22, 31):
		grid[0][x] = "W"
	# C: la bodega (madera), con pilas de cajas.
	for p in [Vector2i(24, 3), Vector2i(27, 3), Vector2i(24, 7), Vector2i(28, 7)]:
		grid[p.y][p.x] = "W"
	grid[5][21] = "D"
	# D: la mansión de Lisandro (oro), con columnas.
	for p in [Vector2i(24, 14), Vector2i(28, 14), Vector2i(24, 20), Vector2i(28, 20)]:
		grid[p.y][p.x] = "G"
	grid[17][21] = "L"
	grid[17][31] = "E"


func _place() -> void:
	var list := [
		["jibaro", 3.5, 14.5], ["jibaro", 6.5, 9.5], ["campanero", 2.5, 3.5],
		["motorizado", 15.5, 3.5], ["motorizado", 19.5, 15.5], ["rappi", 11.5, 10.5], ["rappi", 19.5, 21.5],
		["campanero", 11.5, 19.5], ["jibaro", 16.5, 8.5], ["jibaro", 12.5, 13.5],
		["jibaro", 23.5, 9.5], ["motorizado", 29.5, 2.5], ["rappi", 25.5, 1.5], ["lilato", 28.5, 5.5],
		["lisandro", 27.5, 17.5],
	]
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["balas", 7.5, 19.5], ["empanada", 1.5, 8.5], ["caneca", 7.5, 2.5], ["caneca", 1.5, 15.5],
			["escopeta", 15.5, 12.5], ["cartuchos", 11.5, 2.5], ["aguapanela", 19.5, 2.5], ["chaleco", 12.5, 21.5],
			["balas", 19.5, 11.5], ["caneca", 15.5, 18.0], ["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5],
			["balas", 22.5, 13.5], ["cartuchos", 22.5, 21.5], ["empanada", 29.5, 21.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})


func _spawn(kind: String, at: Vector2) -> Ent:
	var e := Ent.new()
	e.kind = kind
	e.pos = at
	e.hp = kinds[kind]["hp"] * (1.0 + dream_hard)
	enemies.append(e)
	return e


func cell(x: int, y: int) -> String:
	if y < 0 or y >= grid.size() or x < 0 or x >= 32:
		return "#"
	return grid[y][x]


func walkable(p: Vector2) -> bool:
	for pr in props:
		if pr.get("r", 0.0) > 0.0 and p.distance_to(pr["pos"]) < pr["r"] + RADIUS:
			return false
	for d in [Vector2(-RADIUS, -RADIUS), Vector2(RADIUS, -RADIUS), Vector2(-RADIUS, RADIUS), Vector2(RADIUS, RADIUS)]:
		var c := cell(int(floor(p.x + d.x)), int(floor(p.y + d.y)))
		if c != "." and c != "o":
			return false
	return true


## Distancia hasta la primera pared en esa dirección (DDA).
func cast(from: Vector2, dir: Vector2, max_d := 40.0) -> float:
	var mx := int(floor(from.x))
	var my := int(floor(from.y))
	var ddx := absf(1.0 / dir.x) if dir.x != 0.0 else 1e30
	var ddy := absf(1.0 / dir.y) if dir.y != 0.0 else 1e30
	var sx := -1 if dir.x < 0 else 1
	var sy := -1 if dir.y < 0 else 1
	var side_x := (from.x - mx) * ddx if dir.x < 0 else (mx + 1.0 - from.x) * ddx
	var side_y := (from.y - my) * ddy if dir.y < 0 else (my + 1.0 - from.y) * ddy
	for i in 64:
		var d: float
		if side_x < side_y:
			d = side_x
			side_x += ddx
			mx += sx
		else:
			d = side_y
			side_y += ddy
			my += sy
		if d > max_d:
			return max_d
		var c := cell(mx, my)
		if c != "." and c != "o":
			return d
	return max_d


## La luz de una casilla (1 si el episodio no tiene luces).
func light_at(x: int, y: int) -> float:
	if _light.is_empty():
		return 1.0
	return _light[clampi(y, 0, 23) * 32 + clampi(x, 0, 31)]


func _setup_flats() -> void:
	if light_base.is_empty() and flats_tex == null:
		return
	_light.resize(32 * 24)
	for y in 24:
		for x in 32:
			_light[y * 32 + x] = light_base[y][x] if not light_base.is_empty() else 1.0
	if flats_tex == null:
		return
	_cells_img = Image.create(32, 24, false, Image.FORMAT_RGBA8)
	_paint_cells()
	_cells_tex = ImageTexture.create_from_image(_cells_img)
	_floor = ColorRect.new()
	_floor.size = Vector2(W, VIEW_H)
	_floor.show_behind_parent = true
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/plomo_piso.gdshader")
	mat.set_shader_parameter("flats", flats_tex)
	mat.set_shader_parameter("cells", _cells_tex)
	mat.set_shader_parameter("n_flats", float(flats_n))
	mat.set_shader_parameter("view_h", VIEW_H)
	mat.set_shader_parameter("sky_top", ceil_cols[0])
	mat.set_shader_parameter("sky_bottom", ceil_cols[1])
	_floor.material = mat
	add_child(_floor)


func _paint_cells() -> void:
	for y in 24:
		for x in 32:
			var f: int = floor_map[y][x] if not floor_map.is_empty() else 0
			var c: int = ceil_map[y][x] if not ceil_map.is_empty() else -1
			_cells_img.set_pixel(x, y, Color8(f, 255 if c < 0 else c, int(clampf(light_at(x, y), 0.0, 1.0) * 255.0), 255))


## Las luces que titilan (un tubo de la cocina, un farol que se está muriendo).
func _update_light(delta: float) -> void:
	if flicker.is_empty() or _light.is_empty():
		return
	_light_t -= delta
	if _light_t > 0.0:
		return
	_light_t = 0.07
	for c in flicker:
		var base: float = light_base[c.y][c.x]
		var on := sin(time * flicker[c] + c.x * 1.7) + randf_range(-0.6, 0.6) > -0.2
		_light[c.y * 32 + c.x] = base if on else base * 0.35
		if _cells_img:  # solo las que titilan (repintar todo el mapa cada vez pesa en el celular)
			var px := _cells_img.get_pixel(c.x, c.y)
			px.b = clampf(_light[c.y * 32 + c.x], 0.0, 1.0)
			_cells_img.set_pixel(c.x, c.y, px)
	if _cells_img:
		_cells_tex.update(_cells_img)


func _is_outdoors() -> bool:
	return ceil_map.is_empty() or ceil_map[clampi(int(pos.y), 0, 23)][clampi(int(pos.x), 0, 31)] < 0


func _prop_tex(pr: Dictionary) -> Texture2D:
	var name: String = pr["tex"]
	if pr.has("anim"):
		var frames: Array = pr["anim"]
		name = frames[int(time * 6.0 + pr["pos"].x) % frames.size()]
	if not _tex.has(name):
		_tex[name] = load("res://assets/shooter/%s.png" % name)
	return _tex[name]


## Para sobreescribir: cada perdigón (o bala), por dónde pasó y hasta dónde llegó.
func _ray_hook(_from: Vector2, _dir: Vector2, _reach: float) -> void:
	pass


func los(a: Vector2, b: Vector2) -> bool:
	var d := a.distance_to(b)
	return cast(a, (b - a) / d, d + 0.1) >= d - 0.05


# ---------------------------------------------------------------- Bucle

func _title() -> void:
	state = "title"
	_big.text = title_text
	_small.text = subtitle + "\n\n" + ("[A] empezar" if Controls.touch() else "[E / clic] empezar")


func _start() -> void:
	state = "recap"
	_big.text = ""
	_small.text = ""
	MusicDirector.force(music)
	if not recap.is_empty():
		await Dialogue.talk(recap)
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Narrator.say(lines["start"], true)


func _unhandled_input(event: InputEvent) -> void:
	if state == "title" and (event.is_action_pressed("interact") or event is InputEventMouseButton and event.pressed):
		_start()
		return
	if state == "dead" and (event.is_action_pressed("interact") or event is InputEventMouseButton and event.pressed):
		_respawn()
		return
	if state == "done" and (event.is_action_pressed("interact") or event is InputEventMouseButton and event.pressed) and _continue <= 0.0:
		_wake(true)
		return
	if state != "play":
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		ang += event.relative.x * MOUSE_SENS
	elif event.is_action_pressed("drop"):
		_next_weapon()
	elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_1, KEY_2, KEY_3]:
		var w: int = event.physical_keycode - KEY_1
		if owned[w]:
			weapon = w


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_hurt = maxf(0.0, _hurt - delta * 2.0)
	_bonus = maxf(0.0, _bonus - delta * 2.0)
	_face_hurt -= delta
	_face_grin -= delta
	_msg_cd -= delta
	_say_hold -= delta
	while _say_hold <= 0.0 and not _say_q.is_empty():
		var q: Array = _say_q.pop_front()
		if q[1] > time:
			_show_say(q[0])
	match state:
		"play":
			time += delta
			_grace -= delta
			_update_light(delta)
			_player(delta)
			_doors(delta)
			_enemies(delta)
			_projectiles(delta)
			_pickups()
			_special(delta)
		"dead":
			_continue -= delta
			_small.text = Controls.keys_in("CONTINUE?  %d\n\n[E] seguir soñando" % maxi(0, ceili(_continue)))
			if _continue <= 0.0:
				_wake(false)
		"done":
			_continue -= delta
	_update_hud()
	queue_redraw()


func _player(delta: float) -> void:
	if Input.is_action_pressed("move_left"):
		ang -= TURN_SPEED * delta
	if Input.is_action_pressed("move_right"):
		ang += TURN_SPEED * delta
	var dir := Vector2(cos(ang), sin(ang))
	var move := 0.0
	if Input.is_action_pressed("move_up"):
		move += 1.0
	if Input.is_action_pressed("move_down"):
		move -= 0.7
	if move != 0.0:
		var step := dir * move * MOVE_SPEED * move_mult * delta
		if walkable(pos + Vector2(step.x, 0)):
			pos.x += step.x
		if walkable(pos + Vector2(0, step.y)):
			pos.y += step.y
		_bob += delta * 9.0
	_fire_cd -= delta
	if (Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and _fire_cd <= 0.0:
		_fire()
	# Zonas: el punto de reaparición avanza.
	var zone := _zone_of(pos)
	checkpoint = maxi(checkpoint, zone)
	if zone == mini_zone and not mini_awake:
		mini_awake = true
		_say(lines["mini_wake"])
	if zone == boss_zone and not boss_awake:
		boss_awake = true
		MusicDirector.force(music_boss)
		_say(lines["boss_wake"])
		for e in enemies:
			if e.kind == boss_kind:
				e.alerted = true
	# Puertas: se abren al acercarse de frente. La SALIDA, solo sin Lisandro.
	var ahead := pos + dir * 0.9
	var c := Vector2i(int(floor(ahead.x)), int(floor(ahead.y)))
	match cell(c.x, c.y):
		"D":
			if not doors.has(c):
				doors[c] = 0.0
		"L":
			if has_key and not doors.has(c):
				doors[c] = 0.0
				_say(lines["key_use"])
			elif not has_key and _msg_cd <= 0.0:
				_msg_cd = 4.0
				_say(lines["locked"])
		"E":
			if _boss_dead():
				_on_exit()
			elif _msg_cd <= 0.0:
				_msg_cd = 4.0
				_say(lines["exit_wait"])


func _doors(delta: float) -> void:
	for c in doors.keys():
		doors[c] = minf(1.0, doors[c] + delta * 1.6)
		if doors[c] >= 1.0:
			grid[c.y][c.x] = "o"
			doors.erase(c)


func _next_weapon() -> void:
	for k in range(1, 4):
		var w := (weapon + k) % 3
		if owned[w]:
			weapon = w
			return


func _fire() -> void:
	var w: Dictionary = WEAPONS[weapon]
	if w["ammo"] != "" and ammo[w["ammo"]] <= 0:
		# Sin munición: la mejor arma que todavía tenga (la pistola; si no, el puño).
		weapon = 1 if ammo["balas"] > 0 else 0
		if weapon == 0:
			_say(lines["no_ammo"])
		_fire_cd = 0.3
		return
	_fire_cd = w["cd"]
	_flash = 0.12
	if w["ammo"] != "":
		ammo[w["ammo"]] -= 1
		for e in enemies:  # el ruido despierta a los que están cerca
			if e.state != "dead" and e.pos.distance_to(pos) < 10.0:
				e.alerted = true
	# Ayuda para apuntar (como Doom): si un enemigo a la vista está casi en la mira, el tiro va a él.
	# En el celular (girar con la palanca es grueso) la ayuda es más generosa.
	var aim := ang
	var best_da: float = 0.13 if Controls.touch() else 0.06
	for e in enemies:
		if e.state == "dead":
			continue
		var rel := e.pos - pos
		if rel.length() > w["reach"]:
			continue
		var da := absf(wrapf(rel.angle() - ang, -PI, PI))
		if da < best_da and los(pos, e.pos):
			best_da = da
			aim = rel.angle()
	for p in w["pellets"]:
		var spread: float = w["spread"] * (0.5 if GameState.has_skill("sangre_fria") else 1.0)
		var a := aim + randf_range(-spread, spread)
		var rd := Vector2(cos(a), sin(a))
		var wall := cast(pos, rd)
		var best: Ent = null
		var best_t := minf(wall, w["reach"])
		for e in enemies:
			if e.state == "dead":
				continue
			var rel := e.pos - pos
			var t := rel.dot(rd)
			if t <= 0.0 or t > best_t:
				continue
			var radius := 0.5 if e.kind == boss_kind else 0.32
			if absf(rel.cross(rd)) < radius:
				best = e
				best_t = t
		_ray_hook(pos, rd, best_t)
		if best:
			_damage(best, w["dmg"] * dmg_mult * randf_range(0.8, 1.2) * (1.15 if GameState.has_skill("sangre_fria") else 1.0))


func _damage(e: Ent, dmg: float) -> void:
	e.hp -= dmg
	e.alerted = true
	if e.hp <= 0.0:
		_die(e)
		return
	if e.state != "attack" and randf() < (0.25 if e.kind in [mini_kind, boss_kind] else 0.6):
		e.state = "pain"
		e.timer = 0.25
	if e.kind == mini_kind and e.phase == 0 and e.hp < kinds[mini_kind]["hp"] * (1.0 + dream_hard) * 0.5:
		e.phase = 1
		_say(lines["mini_half"])
	if e.kind == boss_kind:
		var max_hp: float = kinds[boss_kind]["hp"] * (1.0 + dream_hard)
		if e.phase == 0 and e.hp < max_hp * 0.66:
			e.phase = 1
			_say(lines["boss_p1"])
			for p in summon_points:
				var s := _spawn(summon_kind, p)
				s.alerted = true
				total += 1
		elif e.phase == 1 and e.hp < max_hp * 0.33:
			e.phase = 2
			_say(lines["boss_p2"])


func _die(e: Ent) -> void:
	e.state = "dead"
	kills += 1
	if e.kind == mini_kind:
		pickups.append({"kind": "llave", "pos": e.pos})
		_say(lines["mini_die"])
	elif e.kind == boss_kind:
		MusicDirector.force(music)
		_say(lines["boss_die"])
		await get_tree().create_timer(4.5).timeout
		_say(lines["boss_reply"])
	else:
		if randf() < (0.55 if GameState.has_skill("rebusque") else 0.35):
			pickups.append({"kind": ["balas", "balas", "cartuchos", "empanada"].pick_random(), "pos": e.pos})


func _boss_dead() -> bool:
	for e in enemies:
		if e.kind == boss_kind:
			return e.state == "dead"
	return true


func _enemies(delta: float) -> void:
	for e in enemies:
		if e.state == "dead":
			continue
		var k: Dictionary = kinds[e.kind]
		var to := pos - e.pos
		var d := to.length()
		var sees := d < 14.0 and los(e.pos, pos)
		e.cd -= delta
		e.moving = false
		match e.state:
			"idle":
				if (sees and d < 11.0) or e.alerted:
					if e.kind == mini_kind and not mini_awake:
						continue
					if e.kind == boss_kind and not boss_awake:
						continue
					e.state = "chase"
			"pain":
				e.timer -= delta
				if e.timer <= 0.0:
					e.state = "chase"
			"attack":
				e.timer -= delta
				if e.timer <= 0.0:
					_enemy_attack(e, d, sees)
					e.state = "chase"
			"flee":
				_walk(e, -to.normalized(), k["speed"], delta)
			"chase":
				if e.kind == "campanero":
					if sees:
						_say(lines["alert"], 0)
						for o in enemies:
							if o.state != "dead" and o.pos.distance_to(e.pos) < 10.0 and o.kind != boss_kind:
								o.alerted = true
						e.state = "flee"
					else:
						_walk(e, to.normalized(), k["speed"], delta)
					continue
				var speed: float = k["speed"] * (1.5 if e.kind == boss_kind and e.phase == 2 else 1.0)
				if sees and d <= k["range"] and e.cd <= 0.0:
					e.state = "attack"
					e.timer = 0.35
					e.cd = k["cd"] * (0.6 if e.kind == boss_kind and e.phase == 2 else 1.0) \
						* (1.2 if e.kind in [boss_kind, mini_kind] and GameState.has_skill("labia") else 1.0)
				elif d > (0.7 if k["attack"] == "melee" else 2.5):
					_walk(e, to.normalized(), speed, delta)
	# Que no se amontonen.
	for i in enemies.size():
		for j in range(i + 1, enemies.size()):
			var a := enemies[i]
			var b := enemies[j]
			if a.state == "dead" or b.state == "dead":
				continue
			var dv := b.pos - a.pos
			if dv.length() < 0.5 and dv.length() > 0.001:
				var push := dv.normalized() * (0.5 - dv.length()) * 0.5
				if walkable(a.pos - push):
					a.pos -= push
				if walkable(b.pos + push):
					b.pos += push


func _walk(e: Ent, dir: Vector2, speed: float, delta: float) -> void:
	var step := dir * speed * delta
	var moved := false
	if walkable(e.pos + Vector2(step.x, 0)):
		e.pos.x += step.x
		moved = true
	if walkable(e.pos + Vector2(0, step.y)):
		e.pos.y += step.y
		moved = true
	e.moving = moved


func _enemy_attack(e: Ent, d: float, sees: bool) -> void:
	var k: Dictionary = kinds[e.kind]
	var atk: String = k["attack"]
	# "throw:<textura>" tira uno; "fan:<textura>" tira tres en abanico (tazas, chismes, papeles).
	if atk.begins_with("throw:") or atk.begins_with("fan:"):
		var aim := (pos - e.pos).angle()
		var spreads := [0.0] if atk.begins_with("throw:") else [-0.18, 0.0, 0.18]
		for sp in spreads:
			var dir := Vector2(cos(aim + sp), sin(aim + sp))
			projectiles.append({"tex": atk.get_slice(":", 1), "pos": e.pos + dir * 0.4, "vel": dir * 5.0, "dmg": k["dmg"]})
		return
	match atk:
		"melee":
			if d <= k["range"] + 0.2:
				_hit(k["dmg"])
		"hitscan":
			if sees and randf() < 0.65 * clampf(1.2 - d / k["range"], 0.3, 1.0):
				_hit(k["dmg"])
		"burst":
			for i in 3:
				if sees and randf() < 0.45:
					_hit(k["dmg"])
		"pedido":
			var dir := (pos - e.pos).normalized()
			projectiles.append({"tex": "pedido", "pos": e.pos + dir * 0.4, "vel": dir * 4.5, "dmg": k["dmg"]})
		"knives":
			var base := (pos - e.pos).angle()
			for s in [-0.15, 0.0, 0.15]:
				var dir := Vector2(cos(base + s), sin(base + s))
				projectiles.append({"tex": "cuchillo", "pos": e.pos + dir * 0.4, "vel": dir * 5.5, "dmg": k["dmg"]})


func _projectiles(delta: float) -> void:
	for p in projectiles.duplicate():
		p["pos"] += p["vel"] * delta
		var c := cell(int(floor(p["pos"].x)), int(floor(p["pos"].y)))
		if c != "." and c != "o":
			projectiles.erase(p)
		elif p["pos"].distance_to(pos) < 0.35:
			_hit(p["dmg"])
			projectiles.erase(p)


func _hit(dmg: float) -> void:
	if _grace > 0.0:
		return
	dmg *= 1.0 + 0.5 * dream_hard
	if GameState.has_skill("aguante"):
		dmg *= 0.8
	if armor > 0.0:
		var absorbed := minf(armor, dmg / 3.0)
		armor -= absorbed
		dmg -= absorbed
	hp -= dmg
	_hurt = 0.6
	_face_hurt = 0.5
	if hp <= 0.0:
		hp = 0.0
		_die_player()


func _pickups() -> void:
	for p in pickups.duplicate():
		if p["kind"] == "caneca" or p["pos"].distance_to(pos) > 0.5:
			continue
		var took := true
		match p["kind"]:
			"balas":
				ammo["balas"] = mini(200, ammo["balas"] + 12)
				if weapon == 0:  # estaba a puño porque no tenía: vuelve al arma solo (como Doom)
					weapon = 1
			"cartuchos":
				ammo["cartuchos"] = mini(50, ammo["cartuchos"] + 6)
				if weapon == 0 and owned[2]:
					weapon = 2
			"empanada", "aguapanela":
				if hp >= max_hp:
					took = false
				else:
					hp = minf(max_hp, hp + (20.0 if p["kind"] == "empanada" else 10.0))
			"chaleco":
				armor = 100.0
				_say(lines["vest"])
			"llave":
				has_key = true
				_face_grin = 1.5
			"escopeta":
				owned[2] = true
				weapon = 2
				ammo["cartuchos"] += 8
				_face_grin = 1.5
				_say(lines["shotgun"])
		if took:
			pickups.erase(p)
			_bonus = 0.4


## prio 0: un comentario (si hay otro aviso a la vista, se pierde); 1: normal (espera su turno,
## hasta 5 s); 2: urgente (pisa lo que haya).
func _say(text: String, prio := 1) -> void:
	if _say_hold > 0.0 and prio < 2:
		if prio == 1:
			_say_q.append([text, time + 5.0])
			if _say_q.size() > 3:
				_say_q.pop_front()
		return
	_show_say(text)


func _show_say(text: String) -> void:
	Narrator.say(text, true)
	_say_hold = clampf(text.length() * 0.035, 1.6, 3.2)


func _die_player() -> void:
	state = "dead"
	_continue = 9.99
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_big.text = "HAS MUERTO"
	projectiles.clear()
	_say_q.clear()
	Narrator.hide_now()  # que no quede un aviso viejo encima de HAS MUERTO


func _respawn() -> void:
	state = "play"
	hp = max_hp
	armor = 0.0
	ammo["balas"] = maxi(ammo["balas"], 30)
	if weapon == 0:
		weapon = 2 if owned[2] and ammo["cartuchos"] > 0 else 1
	pos = checkpoints[checkpoint]
	ang = 0.0 if checkpoint > 0 else -PI / 2.0
	_big.text = ""
	_small.text = ""
	_grace = 2.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for e in enemies:  # los que estaban encima se alejan un poco
		if e.state != "dead" and e.pos.distance_to(pos) < 5.0:
			for k in [4.0, 3.0, 2.0]:
				var away: Vector2 = e.pos + (e.pos - pos).normalized() * k
				if walkable(away) and los(e.pos, away):  # sin atravesar paredes
					e.pos = away
					break


func _finish() -> void:
	state = "done"
	_continue = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicDirector.force("")
	_big.text = "NIVEL COMPLETO"
	_small.text = Controls.keys_in("TIEMPO %02d:%02d\nBAJAS %d/%d\nSECRETOS 0/0\n%s\n\n[E] despertar") % [
		int(time) / 60, int(time) % 60, kills, total, finish_note]


func _wake(won: bool) -> void:
	if not won and FinalRush.active():
		FinalRush.retry()  # en el sueño final no se despierta: otra vez
		return
	state = "out"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var f := GameState.flags
	f["dream_won"] = won
	f["dream_return"] = dream_id
	while SceneRouter.busy:  # si todavía se está mostrando un título, esperar
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	if state == "title":
		draw_rect(Rect2(0, 0, W, 180), Color(0.05, 0.02, 0.04))
		return
	var dir := Vector2(cos(ang), sin(ang))
	var plane := Vector2(-dir.y, dir.x) * FOV_PLANE
	if _floor:  # pisos y techos: los pinta el shader (el nodo de atrás); acá solo se le dice dónde está uno
		var mat := _floor.material as ShaderMaterial
		mat.set_shader_parameter("cam_pos", pos)
		mat.set_shader_parameter("cam_dir", dir)
		mat.set_shader_parameter("cam_plane", plane)
		mat.set_shader_parameter("tint", wall_tint)
	# Cielo de noche y asfalto (más claro cerca).
	for i in (0 if _floor else 10):
		draw_rect(Rect2(0, i * VIEW_H / 20.0, W, VIEW_H / 20.0 + 1), ceil_cols[0].lerp(ceil_cols[1], i / 10.0))
		draw_rect(Rect2(0, VIEW_H / 2.0 + i * VIEW_H / 20.0, W, VIEW_H / 20.0 + 1), floor_cols[0].lerp(floor_cols[1], i / 10.0))
	if drawn_sky and _is_outdoors():  # estrellas de crayón y una luna con cara, que giran con la vista
		for k in 14:
			var sx := fposmod(k * 53.0 - ang * 160.0, W + 40.0) - 20.0
			var sy := 8.0 + (k * 37) % 46
			draw_line(Vector2(sx - 3, sy), Vector2(sx + 3, sy), Color(1, 0.9, 0.4))
			draw_line(Vector2(sx, sy - 3), Vector2(sx, sy + 3), Color(1, 0.9, 0.4))
		var mx := fposmod(240.0 - ang * 160.0, W + 80.0) - 40.0
		draw_circle(Vector2(mx, 22), 11.0, Color(1, 0.95, 0.75))
		draw_circle(Vector2(mx + 5, 19), 9.0, ceil_cols[0].lerp(ceil_cols[1], 0.2))
		draw_circle(Vector2(mx - 4, 20), 1.2, Color(0.2, 0.15, 0.2))
		draw_arc(Vector2(mx - 4, 25), 3.0, 0.3, 2.6, 6, Color(0.2, 0.15, 0.2))
	for x in W:
		var cam := 2.0 * x / W - 1.0
		var ray := dir + plane * cam
		var mx := int(floor(pos.x))
		var my := int(floor(pos.y))
		var ddx := absf(1.0 / ray.x) if ray.x != 0.0 else 1e30
		var ddy := absf(1.0 / ray.y) if ray.y != 0.0 else 1e30
		var sx := -1 if ray.x < 0 else 1
		var sy := -1 if ray.y < 0 else 1
		var side_x := (pos.x - mx) * ddx if ray.x < 0 else (mx + 1.0 - pos.x) * ddx
		var side_y := (pos.y - my) * ddy if ray.y < 0 else (my + 1.0 - pos.y) * ddy
		var side := 0
		var hit := "#"
		for i in 64:
			if side_x < side_y:
				side_x += ddx
				mx += sx
				side = 0
			else:
				side_y += ddy
				my += sy
				side = 1
			hit = cell(mx, my)
			if hit != "." and hit != "o":
				break
		var perp := (side_x - ddx) if side == 0 else (side_y - ddy)
		perp = maxf(perp, 0.05)
		_zbuf[x] = perp
		var lh := VIEW_H / perp
		var top := VIEW_H / 2.0 - lh / 2.0
		var wall_x := (pos.y + perp * ray.y) if side == 0 else (pos.x + perp * ray.x)
		wall_x -= floor(wall_x)
		var tex: Texture2D = _tex["wall_" + wall_tex.get(hit, "ladrillo")]
		var tw := tex.get_width()
		var th := float(tex.get_height())
		var tx := int(wall_x * tw)
		if (side == 0 and ray.x > 0) or (side == 1 and ray.y < 0):
			tx = tw - 1 - tx
		var shade := clampf(1.25 - perp * 0.085, 0.12, 1.0) * (0.72 if side == 1 else 1.0)
		if not _light.is_empty():  # la luz de la casilla desde donde se ve la pared
			shade *= light_at(mx - sx, my) if side == 0 else light_at(mx, my - sy)
		var col := Color(shade, shade * 0.93, shade * 1.02) * wall_tint
		var opening: float = doors.get(Vector2i(mx, my), 0.0)
		if opening > 0.0:  # la puerta sube
			draw_texture_rect_region(tex, Rect2(x, top, 1, lh * (1.0 - opening)), Rect2(tx, th * opening, 1, th * (1.0 - opening)), col)
		else:
			draw_texture_rect_region(tex, Rect2(x, top, 1, lh), Rect2(tx, 0, 1, th), col)
	_draw_sprites(dir, plane)
	_draw_weapon()
	if _hurt > 0.0:
		draw_rect(Rect2(0, 0, W, VIEW_H), Color(0.8, 0.0, 0.0, _hurt * 0.45))
	if _bonus > 0.0:
		draw_rect(Rect2(0, 0, W, VIEW_H), Color(1.0, 0.9, 0.3, _bonus * 0.3))
	if state == "dead":
		draw_rect(Rect2(0, 0, W, VIEW_H), Color(0.5, 0.0, 0.0, 0.55))
	if state == "done":
		draw_rect(Rect2(0, 0, W, 180), Color(0.05, 0.02, 0.04, 0.92))
	# La barra de abajo (estilo Doom).
	draw_rect(Rect2(0, VIEW_H, W, 180 - VIEW_H), Color(0.22, 0.2, 0.2))
	draw_rect(Rect2(0, VIEW_H, W, 1), Color(0.45, 0.42, 0.4))
	for xs in [64, 128, 192, 256]:
		draw_rect(Rect2(xs, VIEW_H + 2, 1, 180 - VIEW_H - 4), Color(0.12, 0.1, 0.1))


func _draw_sprites(dir: Vector2, plane: Vector2) -> void:
	var list := []
	for e in enemies:
		var frame := "dead"
		if e.state != "dead":
			frame = "attack" if e.state == "attack" else ("hurt" if e.state == "pain" else ("walk1" if not e.moving or int(time * 4.0) % 2 == 0 else "walk2"))
		list.append([e.pos, _tex["%s_%s" % [e.kind, frame]], kinds[e.kind]["h"] * (0.45 if e.state == "dead" else 1.0), 0.0])
	for p in pickups:
		list.append([p["pos"], _tex[pickup_tex[p["kind"]]], 0.45 if p["kind"] == "caneca" else 0.22, 0.0])
	for pr in props:
		list.append([pr["pos"], _prop_tex(pr), pr["h"], 0.0])
	list.append_array(extra_sprites())
	for p in projectiles:
		list.append([p["pos"], _tex[p["tex"]], 0.18, 0.35])
	list.sort_custom(func(a, b): return a[0].distance_squared_to(pos) > b[0].distance_squared_to(pos))
	var inv := 1.0 / (plane.x * dir.y - dir.x * plane.y)
	for s in list:
		var rel: Vector2 = s[0] - pos
		var tx := inv * (dir.y * rel.x - dir.x * rel.y)
		var ty := inv * (-plane.y * rel.x + plane.x * rel.y)
		if ty <= 0.15:
			continue
		var tex: Texture2D = s[1]
		var screen_x := W / 2.0 * (1.0 + tx / ty)
		var lh := VIEW_H / ty
		var h: float = lh * s[2]
		var w := h * tex.get_width() / float(tex.get_height())
		var bottom: float = VIEW_H / 2.0 + lh / 2.0 - s[3] * lh
		var left := screen_x - w / 2.0
		var shade := clampf(1.25 - ty * 0.085, 0.15, 1.0) * light_at(int(s[0].x), int(s[0].y))
		# Corridas de columnas visibles (delante de la pared).
		var run_start := -1
		var x0 := maxi(0, int(left))
		var x1 := mini(W - 1, int(left + w))
		for x in range(x0, x1 + 2):
			var visible := x <= x1 and ty < _zbuf[x]
			if visible and run_start < 0:
				run_start = x
			elif not visible and run_start >= 0:
				var u0 := (run_start - left) / w * tex.get_width()
				var u1 := (x - left) / w * tex.get_width()
				draw_texture_rect_region(tex, Rect2(run_start, bottom - h, x - run_start, h),
					Rect2(u0, 0, u1 - u0, tex.get_height()), Color(shade, shade, shade))
				run_start = -1


func _draw_weapon() -> void:
	var w: Dictionary = WEAPONS[weapon]
	var tex: Texture2D = _tex["w_%s%s" % [w["tex"], "_fire" if _flash > 0.0 else ""]]
	var bob := Vector2(sin(_bob) * 4.0, absf(cos(_bob)) * 3.0)
	var lit := 1.0 if _flash > 0.0 else maxf(0.5, light_at(int(pos.x), int(pos.y)))
	draw_texture(tex, Vector2(W / 2.0 - tex.get_width() / 2.0, VIEW_H + 2.0 - tex.get_height()) + bob + Vector2(0, -4 if _flash > 0.0 else 0), Color(lit, lit, lit))


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	# Con controles en pantalla, todo más a la izquierda: la franja derecha es de los botones.
	var xs := [4, 50, 132, 196] if Controls.touch() else [6, 70, 196, 260]
	for k in [["ammo", xs[0]], ["hp", xs[1]], ["armor", xs[2]], ["weapon", xs[3]]]:
		var head := _label(Vector2(k[1], 152), 8, Color(0.75, 0.7, 0.65))
		head.text = {"ammo": "BALAS", "hp": "VIDA", "armor": "CHALECO", "weapon": "ARMA"}[k[0]]
		_hud_heads.append(head)
		_hud_labels[k[0]] = _label(Vector2(k[1], 163), 8, Color(0.95, 0.25, 0.2))
	_face = TextureRect.new()
	_face.position = Vector2(100 if Controls.touch() else 148, 151)
	_ui.add_child(_face)
	_big = _label(Vector2(0, 40), 16, Color(0.95, 0.2, 0.15))
	_big.size = Vector2(W, 20)
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_small = _label(Vector2(0, 70), 8, Color(0.95, 0.9, 0.8))
	_small.size = Vector2(Controls.right_edge(), 70)
	_small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(at: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.02))
	l.add_theme_color_override("font_color", color)
	_ui.add_child(l)
	return l


func _update_hud() -> void:
	var w: Dictionary = WEAPONS[weapon]
	_hud_labels["ammo"].text = "--" if w["ammo"] == "" else str(ammo[w["ammo"]])
	_hud_labels["hp"].text = "%d%%" % int(hp)
	_hud_labels["armor"].text = "%d%%" % int(armor)
	_hud_labels["weapon"].text = w["name"].substr(0, 7) + (" *" if has_key else "")
	var face := "face_%d" % clampi(int(hp / max_hp * 5.0), 0, 4)
	if _face_hurt > 0.0:
		face = "face_hurt"
	elif _face_grin > 0.0:
		face = "face_grin"
	_face.texture = _tex[face]
	for l in _hud_labels.values() + _hud_heads:
		l.visible = state != "title"
	_face.visible = state != "title"
