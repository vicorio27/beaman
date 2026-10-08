extends Node2D
## Sueño 1 (beat 'em up), parte 1 — El callejón.
## Oleadas de matones: la cámara se traba en cada una hasta que no queda ninguno en pie.
## Armas en el piso (botella, caño) y cuchillos que sueltan los matones armados.
## La última oleada es el jefe. Al ganarle, "GO" y salida hacia la avenida (el camión).

const NEXT_SCENE := "res://scenes/prologue/Truck.tscn"
const LEVEL_WIDTH := 1280.0
## Franja de la calle donde se pueden parar los pies (y mínima, y máxima).
const BAND := Vector2(128.0, 174.0)
const VIEW_W := 320.0
## Cuántos matones pueden pegar a la vez.
const MAX_AGGRESSIVE := 2
const BOTTLE_SPEED := 230.0

## Oleadas: posición de la cámara (borde izquierdo) y quiénes aparecen.
## "+knife" = viene con cuchillo (y lo suelta al caer).
const WAVES := [
	{"at": 0.0, "enemies": ["goon", "goon", "punk"]},
	{"at": 320.0, "enemies": ["goon", "punk+knife", "punk", "thug"]},
	{"at": 640.0, "enemies": ["thug", "goon+knife", "punk"]},
	{"at": 960.0, "enemies": ["boss"]},
]
const TYPES := {
	"goon": {"sheet": "res://assets/prologue/enemy_goon.png", "hp": 20, "speed": 42.0, "damage": 4},
	"punk": {"sheet": "res://assets/prologue/enemy_punk.png", "hp": 15, "speed": 58.0, "damage": 3},
	"thug": {"sheet": "res://assets/prologue/enemy_thug.png", "hp": 34, "speed": 34.0, "damage": 6},
	"boss": {"sheet": "res://assets/prologue/enemy_boss.png", "hp": 150, "speed": 40.0, "damage": 6},
}
const BOSS_NAME := "EL TUERTO"
## Armas tiradas en el piso al empezar: tipo y posición.
const ITEMS := [
	["bottle", Vector2(150, 160)],
	["bottle", Vector2(420, 138)],
	["pipe", Vector2(560, 166)],
	["bottle", Vector2(760, 150)],
	["bottle", Vector2(1010, 140)],
	["pipe", Vector2(1080, 168)],
]
const LINES := ["—Dámela y listo.", "—¿Qué cargás ahí, la herencia?", "—¡Agarralo!", "—Esa mochila vale más que vos."]

enum Phase { INTRO, FIGHT, ADVANCE, EXIT, DONE }

## Lo que define el episodio (los episodios siguientes lo cambian en setup()).
var waves: Array = WAVES
var types: Dictionary = TYPES
var items: Array = ITEMS
var lines: Array = LINES
var boss_name := BOSS_NAME
var next_scene := NEXT_SCENE
var bg_path := "res://assets/prologue/alley_bg.png"
var intro_title := "DIA 0 — 23:40"
var player_hp := 50
var lilato_cameo := true
var rain := true

var player: FightPlayer
var phase := Phase.INTRO
var defeated := 0
var total := 0
var _wave := -1
var _alive: Array = []
var _items: Array = []  # [{kind, node, pos}]
var _cam_left := 0.0
var _aggro_timer := 0.0

@onready var mood: CanvasLayer = $MoodFilter
var camera: Camera2D
var hud: CanvasLayer
var _go: Sprite2D
var _flash: ColorRect
var _sfx := {}
var _spark_frames: SpriteFrames


## Para sobreescribir: los episodios siguientes cambian oleadas, fondo, jefes, etc.
func setup() -> void:
	pass


func _ready() -> void:
	setup()
	Dream.reset()
	if GameState.has_skill("aguante"):  # lo aprendió en el primer sueño: aguanta más
		player_hp = int(player_hp * 1.25)
	for w in waves:
		for e in w["enemies"]:
			if e != "boss":
				total += 1

	var bg := Sprite2D.new()
	bg.texture = load(bg_path)
	bg.centered = false
	bg.z_index = -10
	add_child(bg)

	player = FightPlayer.new()
	player.sheet = load("res://assets/prologue/player.png")
	player.max_hp = player_hp
	player.speed = 62.0
	player.position = Vector2(60, 152)
	player.arena = self
	add_child(player)
	player.hurt.connect(_on_player_hurt)

	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(camera)
	camera.make_current()

	for it in items:
		drop_item(it[0], it[1])
	_build_ui()
	_build_sfx()
	_spark_frames = _make_spark_frames()

	if not SceneRouter.busy:
		await SceneRouter.intro(intro_title)
	await before_start()
	_start_wave(0)
	Narrator.say(lines[0], true)


## Para sobreescribir: algo antes de la primera oleada (el "anteriormente...").
func before_start() -> void:
	pass


func _build_ui() -> void:
	if not rain:
		hud = CanvasLayer.new()
		hud.set_script(load("res://scripts/prologue/ArcadeHud.gd"))
		add_child(hud)
		_build_hud_extras()
		return
	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 5
	var rain := Node2D.new()
	rain.set_script(load("res://scripts/prologue/Rain.gd"))
	rain_layer.add_child(rain)
	add_child(rain_layer)

	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/prologue/ArcadeHud.gd"))
	add_child(hud)
	_build_hud_extras()


func _build_hud_extras() -> void:
	_go = Sprite2D.new()
	_go.texture = load("res://assets/prologue/go.png")
	_go.position = Vector2(296, 60)
	_go.scale = Vector2(2, 2)
	_go.visible = false
	hud.add_child(_go)
	_flash = ColorRect.new()
	_flash.color = Color(0.6, 0.05, 0.05, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.size = Vector2(320, 180)
	hud.add_child(_flash)
	_update_hud()


func _build_sfx() -> void:
	for n in ["hit-1", "hit-2", "miss", "grunt", "gogogo"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/%s.wav" % n)
		p.volume_db = -6.0
		add_child(p)
		_sfx[n] = p


func _make_spark_frames() -> SpriteFrames:
	var f := SpriteFrames.new()
	f.set_animation_loop("default", false)
	f.set_animation_speed("default", 20.0)
	var tex: Texture2D = load("res://assets/prologue/spark.png")
	for i in 4:
		var t := AtlasTexture.new()
		t.atlas = tex
		t.region = Rect2(i * 48, 0, 48, 48)
		f.add_frame("default", t)
	return f


func _update_hud() -> void:
	hud.set_counter("%d/%d" % [defeated, total])
	hud.set_score(Dream.score)
	hud.set_life(float(player.hp) / player.max_hp)


## Dónde se puede parar alguien. Los matones pueden estar un poco fuera de pantalla (entrando).
func walk_bounds(who: Node = null) -> Rect2:
	var is_player := who == player
	var margin := 8.0 if is_player else 48.0
	var left := _cam_left + margin if is_player else _cam_left - margin
	var right := _cam_left + VIEW_W - margin if is_player else _cam_left + VIEW_W + margin
	if phase in [Phase.ADVANCE, Phase.EXIT] and is_player:
		right = LEVEL_WIDTH - 4.0
	return Rect2(left, BAND.x, right - left, BAND.y - BAND.x)


func _physics_process(delta: float) -> void:
	# La cámara sigue al jugador hacia adelante, nunca vuelve atrás.
	if phase in [Phase.ADVANCE, Phase.EXIT]:
		_cam_left = clampf(maxf(_cam_left, player.position.x - VIEW_W * 0.45), 0.0, LEVEL_WIDTH - VIEW_W)
	camera.position.x = roundf(_cam_left)

	match phase:
		Phase.FIGHT:
			_aggro_timer -= delta
			if _aggro_timer <= 0.0:
				_aggro_timer = 0.5
				_pick_aggressive()
		Phase.ADVANCE:
			var next_at: float = waves[_wave + 1]["at"]
			if _cam_left >= next_at - 1.0:
				_cam_left = next_at
				_start_wave(_wave + 1)
		Phase.EXIT:
			if player.position.x >= LEVEL_WIDTH - 12.0:
				phase = Phase.DONE
				_level_done()
	_go.visible = phase in [Phase.ADVANCE, Phase.EXIT] and int(Time.get_ticks_msec() / 300) % 2 == 0


func _start_wave(i: int) -> void:
	_wave = i
	phase = Phase.FIGHT
	var list: Array = waves[i]["enemies"]
	for n in list.size():
		var from_right := n % 3 != 2
		var x := _cam_left + (VIEW_W + 20.0 + n * 18.0 if from_right else -20.0 - n * 10.0)
		var y := randf_range(BAND.x + 4.0, BAND.y - 4.0)
		_spawn(list[n], Vector2(x, y))
	if i > 0:
		Narrator.say(lines[mini(i, lines.size() - 1)], true)


func _spawn(kind_spec: String, pos: Vector2) -> void:
	var kind := kind_spec.get_slice("+", 0)
	var t: Dictionary = types[kind]
	var e: FightEnemy = FightBoss.new() if kind == "boss" else FightEnemy.new()
	e.sheet = load(t["sheet"])
	e.max_hp = t["hp"]
	e.speed = t["speed"]
	e.damage = t["damage"]
	e.has_knife = kind_spec.ends_with("+knife")
	e.body_scale = t.get("scale", Vector2.ONE)
	e.position = pos
	e.arena = self
	add_child(e)
	e.knocked_out.connect(_on_enemy_out)
	_alive.append(e)
	if e is FightBoss:
		e.points = 5000
		hud.show_boss(boss_name)
		hud.set_boss(1.0)
		e.life_changed.connect(hud.set_boss)


func _pick_aggressive() -> void:
	var standing := _alive.filter(func(e): return is_instance_valid(e) and e.state != Brawler.State.OUT)
	standing.sort_custom(func(a, b): return a.position.distance_to(player.position) < b.position.distance_to(player.position))
	for i in standing.size():
		standing[i].aggressive = i < MAX_AGGRESSIVE or standing[i] is FightBoss


## Resuelve un golpe: pega a quien esté adelante del atacante, a la misma profundidad y al alcance.
func resolve_attack(attacker: Brawler, reach: float, damage: int, heavy: bool) -> void:
	var targets: Array = _alive if attacker == player else [player]
	var landed := false
	for t in targets:
		if not is_instance_valid(t) or t.state in [Brawler.State.OUT, Brawler.State.DOWN, Brawler.State.GETUP]:
			continue
		var dx: float = (t.position.x - attacker.position.x) * attacker.facing
		if absf(t.position.y - attacker.position.y) <= 8.0 and dx >= -4.0 and dx <= reach:
			t.take_hit(damage, attacker.position.x, heavy)
			on_hit_landed(t, heavy)
			landed = true
	if not landed and attacker == player:
		_sfx["miss"].play()


## Chispa, sonido, congelado breve y puntos.
func on_hit_landed(target: Brawler, heavy: bool) -> void:
	_sfx["hit-2" if heavy else ["hit-1", "hit-2"].pick_random()].play()
	_spark(target.position + Vector2(0, -20))
	if target != player:
		Dream.add(100)
		_update_hud()
	_hit_stop(0.09 if heavy else 0.05)


func on_blocked(target: Brawler) -> void:
	_sfx["miss"].play()
	_spark(target.position + Vector2(target.facing * 8, -20))


func _spark(pos: Vector2) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _spark_frames
	s.position = pos
	s.z_index = 400
	add_child(s)
	s.play()
	s.animation_finished.connect(s.queue_free)


## Congela un instante el juego al pegar: le da peso al golpe.
func _hit_stop(seconds: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- Armas

func drop_item(kind: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/prologue/item_%s.png" % kind)
	s.position = pos + Vector2(0, -6)
	s.z_index = int(pos.y) - 1
	add_child(s)
	_items.append({"kind": kind, "node": s, "pos": pos})


## El jugador agarra el arma más cercana a sus pies, si hay una.
func try_pickup(p: FightPlayer) -> bool:
	for it in _items:
		var pos: Vector2 = it["pos"]
		if absf(pos.x - p.position.x) < 16.0 and absf(pos.y - p.position.y) < 10.0:
			it["node"].queue_free()
			_items.erase(it)
			p.equip(it["kind"])
			return true
	return false


## Botella tirada: vuela recto y se rompe contra el primero que agarra (o se pierde por el borde).
func throw_item(p: FightPlayer, kind: String) -> void:
	var b := Sprite2D.new()
	b.texture = load("res://assets/prologue/item_%s.png" % kind)
	b.position = p.position + Vector2(p.facing * 14, -18)
	b.z_index = 400
	add_child(b)
	var dir := float(p.facing)
	var lane := p.position.y
	while is_instance_valid(b):
		if not is_inside_tree():
			return
		await get_tree().physics_frame
		if not is_instance_valid(b):
			return
		b.position.x += dir * BOTTLE_SPEED * get_physics_process_delta_time()
		b.rotation += dir * 0.4
		for e in _alive:
			if is_instance_valid(e) and e.state not in [Brawler.State.OUT, Brawler.State.DOWN] \
					and absf(e.position.y - lane) <= 9.0 and absf(e.position.x - b.position.x) < 10.0:
				e.take_hit(12, b.position.x - dir * 10.0, true)
				on_hit_landed(e, true)
				break_item(kind, Vector2(b.position.x, lane))
				b.queue_free()
				return
		if b.position.x < _cam_left - 10.0 or b.position.x > _cam_left + VIEW_W + 10.0:
			b.queue_free()


## Arma rota: la botella deja vidrios; el caño se dobla y se pierde.
func break_item(kind: String, pos: Vector2) -> void:
	if kind != "bottle":
		return
	var s := Sprite2D.new()
	s.texture = load("res://assets/prologue/shards.png")
	s.position = pos + Vector2(0, -3)
	s.z_index = int(pos.y) - 1
	add_child(s)
	_sfx["miss"].play()
	create_tween().tween_interval(4.0).finished.connect(s.queue_free)


func _on_enemy_out(e: Brawler) -> void:
	_alive.erase(e)
	Dream.add(e.points)
	if e is FightBoss:
		# Golpe final al jefe en cámara lenta.
		Engine.time_scale = 0.3
		await get_tree().create_timer(0.6, true, false, true).timeout
		Engine.time_scale = 1.0
	else:
		defeated += 1
	_update_hud()
	if _alive.is_empty() and phase == Phase.FIGHT:
		_sfx["gogogo"].play()
		phase = Phase.EXIT if _wave == waves.size() - 1 else Phase.ADVANCE
		if _wave == 1 and lilato_cameo:
			_lilato_cameo()


## Lilato vuelve en todos los sueños: acá solo se asoma al fondo, mira, se ríe y se va.
func _lilato_cameo() -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SideFrames.build(load("res://assets/prologue/lilato.png"), SideFrames.LILATO)
	s.play("idle")
	s.flip_h = true
	s.position = Vector2(_cam_left + VIEW_W - 34.0, BAND.x - 4.0)
	s.z_index = int(BAND.x) - 1
	s.modulate = Color(0.7, 0.6, 0.8, 0.0)
	add_child(s)
	var t := create_tween()
	t.tween_property(s, "modulate:a", 0.85, 0.6)
	t.tween_callback(func(): Narrator.say("—...", true))
	t.tween_interval(1.6)
	t.tween_callback(func(): Narrator.say("—Jaja. Seguí corriendo.", true))
	t.tween_interval(1.2)
	t.tween_property(s, "modulate:a", 0.0, 0.5)
	t.tween_callback(s.queue_free)


func _on_player_hurt(ratio: float) -> void:
	_sfx["grunt"].play()
	mood.forced_distress = 0.45 + 0.5 * (1.0 - ratio)
	hud.set_life(ratio)
	_flash.color.a = 0.35
	create_tween().tween_property(_flash, "color:a", 0.0, 0.35)


## Para sobreescribir: qué pasa al salir por la derecha.
func _level_done() -> void:
	SceneRouter.go(next_scene)


func debug_skip() -> void:
	_level_done()
