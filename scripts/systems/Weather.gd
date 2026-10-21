class_name Weather
extends Node
## El aguacero de día (afuera). Cada día se decide, con la semilla del día, si llueve y de qué hora a qué
## hora (window): así es el mismo en la ciudad, el parque y el centro.
## Mientras llueve:
##   - la lluvia, encima de todo (menos el HUD), y el cielo se pone gris;
##   - los charcos en las veredas y la calle: crecen mientras llueve y se secan despacio después;
##   - rayos: un fogonazo blanco y, un rato después, el trueno;
##   - la gente corre a escamparse donde no se moja (la parada del bus, los aleros, el kiosco)
##     y espera ahí hasta que escampe (Passerby.gd pregunta shelter_for);
##   - él no tiene a dónde correr: se moja (el ánimo baja de a poquito).
## La lluvia de la noche (la que se ve al dormir) es otra cosa: NightSequence.

const CHANCE := 0.25
## Lo que tapa: el alero queda debajo (adelante) del techo de cada uno.
const SHELTER_NAMES := ["bus_stop_", "kiosk_", "bakery_", "cafe_", "electro_", "house_", "warehouse_"]

static var _shelters: Array = []

var _layer: CanvasLayer
var _sky: ColorRect
var _drops: Control
var _flash: ColorRect
var _puddles: Node2D
var _rain_sound: AudioStreamPlayer
var _thunder: AudioStreamPlayer
var _bolt := 12.0
var _wet_t := 0.0
var _told := false
var _t := 0.0


## [desde, hasta] en horas del día `day`, o [-1, -1] si ese día no llueve.
static func window(day: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("aguacero%d" % day)
	if day < 2 or rng.randf() >= CHANCE:
		return Vector2(-1, -1)
	var start := 9.0 + rng.randi() % 9 + rng.randf()
	return Vector2(start, start + 1.0 + rng.randf() * 2.0)


static func _hour() -> float:
	return fmod(TimeManager.minutes / 60.0, 24.0)


static func raining() -> bool:
	var w := window(GameState.day)
	var h := _hour()
	return h >= w.x and h < w.y


## Cuánta agua hay en el piso (0..1): sube en media hora de lluvia y se seca en hora y media.
static func wetness() -> float:
	var w := window(GameState.day)
	if w.x < 0.0:
		return 0.0
	var h := _hour()
	if h < w.x:
		return 0.0
	if h < w.y:
		return minf(1.0, (h - w.x) / 0.5)
	return maxf(0.0, 1.0 - (h - w.y) / 1.5)


## El alero más cercano (para los que corren a escampar). Vector2.INF si no hay.
static func shelter_for(at: Vector2) -> Vector2:
	var best := Vector2.INF
	for s in _shelters:
		if at.distance_to(s) < at.distance_to(best):
			best = s
	return best


func _ready() -> void:
	var scene := get_parent()
	var world := scene.get_node_or_null("World")
	_shelters.clear()
	if world:
		for n in world.get_children():
			var nm := str(n.name)
			if n is Node2D and SHELTER_NAMES.any(func(p): return nm.begins_with(p)):
				_shelters.append((n as Node2D).position + Vector2(randf_range(-6, 6), 10))
	_layer = CanvasLayer.new()
	_layer.layer = 3
	add_child(_layer)
	_sky = ColorRect.new()
	_sky.size = Vector2(320, 180)
	_sky.color = Color(0.12, 0.16, 0.24, 0.0)
	_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_sky)
	_drops = Control.new()
	_drops.size = Vector2(320, 180)
	_drops.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drops.draw.connect(_draw_drops)
	_layer.add_child(_drops)
	_flash = ColorRect.new()
	_flash.size = Vector2(320, 180)
	_flash.color = Color(0.92, 0.95, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_flash)
	if world:
		_puddles = Node2D.new()
		_puddles.name = "Charcos"
		_puddles.z_index = 0  # (en el World ordenado por altura, en y = 0: debajo de todo lo que camina)
		_puddles.draw.connect(_draw_puddles)
		world.add_child(_puddles)
	_rain_sound = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = load("res://assets/audio/lluvia.wav")
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	_rain_sound.stream = loop
	_rain_sound.volume_db = -80.0
	add_child(_rain_sound)
	_thunder = AudioStreamPlayer.new()
	add_child(_thunder)


func _process(delta: float) -> void:
	_t += delta
	var on := raining()
	var wet := wetness()
	_sky.color.a = move_toward(_sky.color.a, 0.28 if on else 0.0, delta * 0.2)
	_drops.visible = _sky.color.a > 0.02
	if _drops.visible:
		_drops.queue_redraw()
	if _puddles:
		_puddles.visible = wet > 0.02
		if _puddles.visible:
			_puddles.queue_redraw()
	# El sonido: sube y baja con la lluvia.
	var want_db := -10.0 if on else -80.0  # (de fondo: que no tape la música)
	if on and not _rain_sound.playing:
		_rain_sound.play()
	_rain_sound.volume_db = move_toward(_rain_sound.volume_db, want_db, delta * 20.0)
	if not on and _rain_sound.volume_db <= -79.0:
		_rain_sound.stop()
	if not on:
		return
	if not _told and not Dialogue.active:
		_told = true
		Narrator.say("(Se larga el aguacero. La gente corre a los aleros. Él no tiene a dónde correr. Bueno: tiene, pero no lo dejan.)")
	# Rayos.
	_bolt -= delta
	if _bolt <= 0.0:
		_bolt = randf_range(14.0, 40.0)
		_lightning()
	# Él, mojándose (si no está debajo de algo).
	_wet_t += delta
	if _wet_t >= 12.0:
		_wet_t = 0.0
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p and shelter_for(p.position).distance_to(p.position) > 16.0:
			GameState.change_mood(-0.5)


func _lightning() -> void:
	var t := create_tween()
	t.tween_property(_flash, "color:a", 0.75, 0.04)
	t.tween_property(_flash, "color:a", 0.1, 0.08)
	t.tween_property(_flash, "color:a", 0.55, 0.04)
	t.tween_property(_flash, "color:a", 0.0, 0.5)
	await get_tree().create_timer(randf_range(0.5, 2.0)).timeout
	if not is_inside_tree():
		return
	_thunder.stream = load("res://assets/audio/trueno_%d.wav" % randi_range(1, 3))
	_thunder.volume_db = randf_range(-6.0, 0.0)
	_thunder.play()


## Las gotas: rayitas en diagonal que caen rápido (la pantalla, no el mundo: así llueve igual en todo).
func _draw_drops() -> void:
	var a := _sky.color.a / 0.28
	var col := Color(0.75, 0.82, 0.95, 0.5 * a)
	for i in 140:
		var seed_x := fmod(i * 73.13, 340.0)
		var speed := 260.0 + fmod(i * 17.7, 90.0)
		var y := fmod(_t * speed + i * 37.0, 200.0) - 10.0
		var x := fmod(seed_x - y * 0.25 + 340.0, 340.0) - 10.0
		var l := 5.0 + fmod(i * 3.3, 4.0)
		_drops.draw_line(Vector2(x, y), Vector2(x - l * 0.25, y + l), col, 1.0)
	# Salpicaduras en el piso (cerca de abajo de la pantalla y por todos lados).
	for i in 18:
		var k := fmod(_t * 3.0 + i * 0.37, 1.0)
		var sx := fmod(i * 97.0 + floor(_t * 3.0 + i * 0.37) * 53.0, 320.0)
		var sy := 40.0 + fmod(i * 41.0 + floor(_t * 3.0 + i * 0.37) * 29.0, 140.0)
		if k < 0.3:
			_drops.draw_arc(Vector2(sx, sy), 1.0 + k * 6.0, PI, TAU, 6, Color(0.8, 0.86, 0.95, 0.5 * a * (1.0 - k / 0.3)), 1.0)


## Los charcos: en los carriles de la gente y en la calle; con anillos cuando todavía llueve.
func _draw_puddles() -> void:
	var wet := wetness()
	var lanes: Array = load("res://scripts/world/PasserbySpawner.gd").LANES.get(get_parent().name, [])
	var on := raining()
	var k := 0
	for lane in lanes:
		var a: Vector2 = lane[0]
		var b: Vector2 = lane[1]
		var n := int(a.distance_to(b) / 70.0)
		for i in n:
			k += 1
			var f := (i + 0.5 + fmod(k * 0.37, 0.4)) / float(n)
			var p := a.lerp(b, f) + Vector2(fmod(k * 13.0, 14.0) - 7.0, fmod(k * 7.0, 10.0) - 5.0)
			var w := (6.0 + fmod(k * 5.0, 9.0)) * wet
			if w < 1.0:
				continue
			_ellipse(p, w, w * 0.4, Color(0.32, 0.38, 0.5, 0.55))
			_ellipse(p + Vector2(-w * 0.3, -w * 0.1), w * 0.4, w * 0.12, Color(0.7, 0.78, 0.9, 0.35))
			if on:
				var r := fmod(_t * 1.3 + k * 0.29, 1.0)
				_puddles.draw_arc(p, w * 0.8 * r, 0.0, TAU, 10, Color(0.8, 0.86, 0.95, 0.5 * (1.0 - r)), 1.0)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 12:
		var ang := TAU * i / 12.0
		pts.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	_puddles.draw_colored_polygon(pts, col)
