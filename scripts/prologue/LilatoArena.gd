extends Node2D
## Sueño 1 (beat 'em up), parte 3 — Bajo el puente: la jefa final.
##   1. LILATO: pelea de beat 'em up contra ella (rápida, aparece detrás).
##   2. Al vencerla deja el SÚPER CUCHILLO. Hay que agarrarlo.
##   3. Se transforma en SERPIENTE: solo el súper cuchillo la lastima (ver Serpent.gd).
##   4. FINAL STAGE CLEAR → INSERT COIN → no hay créditos (CONTINUE?).

const NEXT_SCENE := "res://scenes/prologue/Continue.tscn"
const BAND := Vector2(128.0, 174.0)
const BOSS_NAME := "LILATO"

enum Phase { INTRO, LILATO, KNIFE, TRANSFORM, SERPENT, CLEAR, DONE }

var player: FightPlayer
var phase := Phase.INTRO
var lilato: FightLilato
var serpent: Serpent
var _items: Array = []  # [{kind, node, pos}]
var _shake := 0.0

@onready var mood: CanvasLayer = $MoodFilter
var hud: CanvasLayer
var _camera: Camera2D
var _banner: Label
var _hint: Label
var _flash: ColorRect
var _sfx := {}
var _spark_frames: SpriteFrames


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_camera.make_current()

	var bg := Sprite2D.new()
	bg.texture = load("res://assets/prologue/bridge_bg.png")
	bg.centered = false
	bg.z_index = -10
	add_child(bg)

	player = FightPlayer.new()
	player.sheet = load("res://assets/prologue/player.png")
	player.max_hp = 50
	player.speed = 62.0
	player.position = Vector2(50, 156)
	player.arena = self
	add_child(player)
	player.hurt.connect(_on_player_hurt)

	lilato = FightLilato.new()
	lilato.sheet = load("res://assets/prologue/lilato.png")
	lilato.max_hp = 180
	lilato.speed = 52.0
	lilato.damage = 6
	lilato.position = Vector2(250, 150)
	lilato.arena = self
	add_child(lilato)
	lilato.set_facing(-1)
	lilato.set_physics_process(false)
	lilato.knocked_out.connect(_on_lilato_down)
	lilato.spoke.connect(func(line): Narrator.say(line, true))

	_build_ui()
	_spark_frames = _make_spark_frames()
	_intro()


func _build_ui() -> void:
	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 5
	var rain := Node2D.new()
	rain.set_script(load("res://scripts/prologue/Rain.gd"))
	rain_layer.add_child(rain)
	add_child(rain_layer)

	hud = CanvasLayer.new()
	hud.set_script(load("res://scripts/prologue/ArcadeHud.gd"))
	add_child(hud)
	hud.set_score(Dream.score)
	hud.set_counter("")
	_banner = _make_label(Color(1, 0.85, 0.3), Vector2(0, 66))
	_hint = _make_label(Color(1, 1, 1), Vector2(0, 104))
	_flash = ColorRect.new()
	_flash.color = Color(0.6, 0.05, 0.05, 0.0)
	_flash.size = Vector2(320, 180)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_flash)
	for n in ["hit-1", "hit-2", "miss", "grunt", "gogogo", "click"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/%s.wav" % n)
		p.volume_db = -6.0
		add_child(p)
		_sfx[n] = p


func _make_label(color: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = Vector2(320, 12)
	l.visible = false
	hud.add_child(l)
	return l


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


func _intro() -> void:
	mood.forced_distress = 0.5
	await get_tree().create_timer(0.6).timeout
	Narrator.say("—Otra vez vos.", true)
	await get_tree().create_timer(1.6).timeout
	hud.show_boss(BOSS_NAME)
	hud.set_boss(1.0)
	lilato.life_changed.connect(hud.set_boss)
	lilato.set_physics_process(true)
	phase = Phase.LILATO
	_sfx["gogogo"].play()


func _process(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, delta * 8.0)
	_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	hud.set_score(Dream.score)
	if phase == Phase.KNIFE:
		_hint.visible = int(Time.get_ticks_msec() / 300) % 2 == 0
		if player.weapon == "superknife":
			_hint.visible = false
			_transform()


# ---------------------------------------------------------------- Interfaz de arena (luchadores)

func walk_bounds(who: Node = null) -> Rect2:
	var margin := 8.0 if who == player else 4.0
	return Rect2(margin, BAND.x, 320.0 - margin * 2.0, BAND.y - BAND.x)


func resolve_attack(attacker: Brawler, reach: float, damage: int, heavy: bool) -> void:
	var landed := false
	if attacker == player:
		if lilato and is_instance_valid(lilato) and phase == Phase.LILATO \
				and lilato.state not in [Brawler.State.OUT, Brawler.State.DOWN, Brawler.State.GETUP]:
			var dx: float = (lilato.position.x - player.position.x) * player.facing
			if absf(lilato.position.y - player.position.y) <= 8.0 and dx >= -4.0 and dx <= reach:
				lilato.take_hit(damage, player.position.x, heavy)
				on_hit_landed(lilato, heavy)
				landed = true
		if serpent and is_instance_valid(serpent) and serpent.can_be_hit_from(player, reach):
			landed = true
			if serpent.hit(player.weapon == "superknife"):
				Dream.add(300)
				on_hit_landed(null, true, serpent.head_pos() + Vector2(0, -14))
			else:
				_sfx["miss"].play()
				burst(serpent.head_pos() + Vector2(0, -14))
	elif player.state not in [Brawler.State.OUT, Brawler.State.DOWN, Brawler.State.GETUP]:
		var dx: float = (player.position.x - attacker.position.x) * attacker.facing
		if absf(player.position.y - attacker.position.y) <= 8.0 and dx >= -4.0 and dx <= reach:
			player.take_hit(damage, attacker.position.x, heavy)
			on_hit_landed(player, heavy)
			landed = true
	if not landed and attacker == player:
		_sfx["miss"].play()


func on_hit_landed(target: Node2D, heavy: bool, at := Vector2.INF) -> void:
	_sfx["hit-2" if heavy else ["hit-1", "hit-2"].pick_random()].play()
	burst(at if at != Vector2.INF else target.position + Vector2(0, -20))
	if target != null and target != player:
		Dream.add(100)
	_hit_stop(0.08 if heavy else 0.05)


func burst(pos: Vector2) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = _spark_frames
	s.position = pos
	s.z_index = 400
	add_child(s)
	s.play()
	s.animation_finished.connect(s.queue_free)


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _hit_stop(seconds: float) -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- Armas en el piso

func drop_item(kind: String, pos: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/prologue/item_%s.png" % kind)
	s.position = pos + Vector2(0, -6)
	s.z_index = int(pos.y) - 1
	add_child(s)
	_items.append({"kind": kind, "node": s, "pos": pos})
	if kind == "superknife":
		var t := s.create_tween().set_loops()
		t.tween_property(s, "modulate", Color(1.4, 1.2, 1.6), 0.4)
		t.tween_property(s, "modulate", Color.WHITE, 0.4)


func try_pickup(p: FightPlayer) -> bool:
	for it in _items:
		var pos: Vector2 = it["pos"]
		if absf(pos.x - p.position.x) < 16.0 and absf(pos.y - p.position.y) < 10.0:
			it["node"].queue_free()
			_items.erase(it)
			p.equip(it["kind"])
			_sfx["click"].play()
			return true
	return false


func break_item(_kind: String, _pos: Vector2) -> void:
	pass


func throw_item(p: FightPlayer, _kind: String) -> void:
	p.unequip()


# ---------------------------------------------------------------- Fases

## Lilato cae: deja el súper cuchillo.
func _on_lilato_down(_e: Brawler) -> void:
	phase = Phase.KNIFE
	Dream.add(5000)
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	Narrator.say("—Tomá. Ya que te querés ir...", true)
	drop_item("superknife", lilato.position + Vector2(-lilato.facing * 18.0, 0))
	_hint.text = "AGARRA EL CUCHILLO"


## Se levanta y se transforma en serpiente.
func _transform() -> void:
	phase = Phase.TRANSFORM
	lilato.state = Brawler.State.OUT
	lilato.play("transform")
	mood.forced_distress = 0.6
	shake(4.0)
	Narrator.say("—...", true)
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(lilato, "modulate:a", 0.0, 0.4)
	await t.finished
	var at := lilato.position
	lilato.queue_free()
	MusicDirector.force("lilato_serpent")
	serpent = Serpent.new()
	serpent.arena = self
	serpent.position = at
	add_child(serpent)
	serpent.life_changed.connect(hud.set_boss)
	serpent.died.connect(_on_serpent_died)
	serpent.hint.connect(func(text): Narrator.say(text, true))
	hud.show_boss(BOSS_NAME)
	hud.set_boss(1.0)
	burst(at + Vector2(0, -16))
	_sfx["hit-2"].play()
	phase = Phase.SERPENT
	mood.forced_distress = 0.45


func _on_serpent_died() -> void:
	phase = Phase.CLEAR
	Dream.add(10000)
	mood.forced_distress = 0.4
	_sfx["gogogo"].play()
	_banner.text = "FINAL STAGE CLEAR"
	_banner.visible = true
	await get_tree().create_timer(2.5).timeout
	_banner.text = "INSERT COIN"
	await get_tree().create_timer(1.5).timeout
	phase = Phase.DONE
	SceneRouter.go(NEXT_SCENE)


func _on_player_hurt(ratio: float) -> void:
	_sfx["grunt"].play()
	mood.forced_distress = 0.45 + 0.5 * (1.0 - ratio)
	hud.set_life(ratio)
	_flash.color.a = 0.35
	create_tween().tween_property(_flash, "color:a", 0.0, 0.35)


func debug_skip() -> void:
	SceneRouter.go(NEXT_SCENE)
