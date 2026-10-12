extends Node2D
## EL PRÓLOGO: la huida. Lo que pasó de verdad, la noche del operativo (y lo que él sueña siempre).
## Diana Carolina lo denunció por lo del aborto; Lorena dio la dirección, la foto y el "está armado".
## Llegaron a matarlo. Él salió por la ventana de atrás con Lukas y la mochila.
##   Tramo 1, LOS TECHOS: corre solo. [E] o arriba: saltar (muros, huecos). Abajo: agacharse (la ropa
##     tendida) y, cerca de un tanque, esconderse de la luz del helicóptero.
##   Tramo 2, EL PUENTE: más rápido, las patrullas atrás. Conos (saltar), ráfagas (agacharse). Al final,
##     el retén: saltar la baranda, al río.
## Las balas: avisan en el borde (atrás o al frente) y pasan volando. Las altas, agacharse; las
##   bajas, saltar.
## Lukas: la primera vez que lo van a agarrar, se devuelve bravo y los muerde: la ventaja vuelve a la
##   mitad. Una sola vez en toda la huida (el perrito al lado de la barra).
## Una sola barra: la VENTAJA. Tropezar, caerse o que lo alumbren la baja. En cero lo agarran... y el
## narrador se corrige ("así no fue"): se repite desde el último tanque. No hay game over: es un recuerdo.
## Después del río: negro, y despierta debajo del puente. Día 1.
## Antes de correr, lo que pasó se cuenta sobre negro: cada texto trae su lámina (Laminas.gd), que se
## dibuja sola, y la música del miedo ("panico") se acelera con cada uno. Al correr entra "huida".

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NEXT_SCENE := "res://scenes/world/City.tscn"
const NEXT_TITLE := "DIA 1 — 06:17"
const WAKE_LINE := "(Otra vez ese sueño. Siempre termina igual: él salta. El río lo deja debajo del mismo puente. El desayuno no aparece.)"
const GROUND := 140.0
const PX := 100.0
const GRAVITY := 560.0
const JUMP := -205.0
const POLICE := Color(0.5, 0.65, 1.0)
const LAMINAS := preload("res://scripts/prologue/Laminas.gd")
## Lo que pasó, texto por texto: el número de cada uno es el de su lámina.
const INTRO := [
	["", "ANTES. Un apartamento con todo pago: la nevera, el sofá, la moto. Él, sin barba. Lukas, con cama propia y dos cobijas."],
	["", "A las cuatro de la tarde, Diana Carolina entró a una estación de policía. Salió a las cinco y media, con copia."],
	["", "La denuncia dice: aborto. Dice que él la obligó. Dice: armado y peligroso."],
	["", "Lorena confirmó la dirección por teléfono. Mandó una foto. Agregó lo del arma, de su cosecha."],
	["", "De todo ese papel, lo único cierto es la dirección."],
	["", "21:40. Él está haciendo arroz."],
	["UNA VOZ", "—¡POLICIA! ¡ABRA! ¡SABEMOS QUE ESTA ARMADO!"],
	["", "(Tiene un cucharón.)"],
	["UN VECINO", "—¡Es ese! ¡El del 302! ¡Yo siempre dije que ese era raro! ¡Saluda mucho!"],
	["", "(El primer tiro entra por la ventana de la sala. Nadie preguntó nada antes. El arroz se quema solo.)"],
	["", "(La mochila. La foto. El perro. La ventana de atrás. En ese orden.)"],
]

## [x, tipo]. muro/cono: saltar. hueco: saltar (ancho 46). ropa/rafaga: agacharse. luz: viene el
## helicóptero; hay que estar agachado detrás del tanque que sigue. tanque: donde esconderse.
## tiro_a / tiro_ab: una bala de atrás, alta (agacharse) / baja (saltar). tiro_f / tiro_fb: de frente.
## (La bala sale ahí y llega como un segundo después: unos 100 px más adelante.)
const STAGES := {
	1: {"speed": 92.0, "end": 4000.0, "drain": -2.5, "obs": [
		[320, "muro"], [540, "ropa"], [620, "tiro_a"], [780, "hueco"], [1000, "muro"], [1140, "luz"], [1300, "tanque"],
		[1360, "tiro_ab"], [1540, "ropa"], [1720, "muro"], [1900, "hueco"], [1990, "tiro_a"], [2120, "ropa"],
		[2250, "luz"], [2410, "tanque"], [2500, "tiro_ab"], [2640, "muro"], [2790, "muro"], [2980, "hueco"],
		[3170, "luz"], [3330, "tanque"], [3380, "tiro_a"], [3540, "ropa"], [3720, "hueco"], [3800, "tiro_ab"]]},
	2: {"speed": 114.0, "end": 1760.0, "drain": 1.6, "obs": [
		[60, "tiro_f"], [260, "cono"], [450, "rafaga"], [500, "tiro_fb"], [640, "cono"], [790, "cono"],
		[840, "tiro_a"], [980, "rafaga"], [1010, "tiro_fb"], [1160, "cono"], [1200, "tiro_a"], [1320, "rafaga"],
		[1470, "cono"]]},
}
const SHOT_SPEED := 300.0
const JUMP_FROM := 1590.0  # la baranda: desde aquí se puede saltar al río
const JUMP_TO := 1700.0
const RETCON := [
	"(Lo agarran. ... No. Así no fue. Si lo hubieran agarrado, no habría Día 1. Otra vez.)",
	"(Lo alcanzan en la esquina. ... Tampoco. Él se acuerda de haber corrido mejor. Otra vez.)",
	"(Ahí quedó. ... No, no quedó. La memoria a veces lo deja mal parado a propósito. Otra vez.)",
]

var stage := 0
var _run := false
var _x := 0.0
var _y := 0.0          # altura sobre el piso
var _vy := 0.0
var _slide := 0.0
var _crouch := false
var _stun := 0.0
var _lead := 100.0
var _obs: Array = []
var _beam := ""        # "", "warn", "on"
var _beam_t := 0.0
var _beam_hit := false
var _cover_x := 0.0
var _seen := {}
var _tries := 0
var _t := 0.0
var _jumped_off := false
var _check_x := 0.0    # hasta dónde llegó seguro (cada tanque): desde ahí se repite
var _me: AnimatedSprite2D
var _dog: AnimatedSprite2D
var _cops: Array = []
var _fx: Node2D
var _hint: Label
var _bar: ColorRect
var _bar_bg: ColorRect
var _black: ColorRect
var _skyline: Texture2D
var _sfx := {}
var _intro := true
var _shots: Array = []      # las balas: {x (en pantalla), dir, high, warn, hit}
var _lukas_used := false    # Lukas ya los mordió: solo una vez
var _dog_busy := false
var _dog_icon: TextureRect
var _laminas: Node2D
var _panic: AudioStreamPlayer


func _ready() -> void:
	_skyline = load("res://assets/prologue/skyline.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 2:
		var c := AnimatedSprite2D.new()
		c.sprite_frames = SideFrames.build(load("res://assets/prologue/enemy_%s.png" % ["goon", "thug"][i]), SideFrames.ENEMY)
		c.modulate = POLICE
		c.play("walk")
		c.speed_scale = 1.5
		add_child(c)
		_cops.append(c)
	_dog = AnimatedSprite2D.new()
	var df := SpriteFrames.new()
	df.remove_animation("default")
	df.add_animation("run")
	df.set_animation_speed("run", 10.0)
	df.add_frame("run", Lukas.cell(0, 1))
	df.add_frame("run", Lukas.cell(0, 2))
	_dog.sprite_frames = df
	_dog.flip_h = true
	_dog.play("run")
	add_child(_dog)
	_me = AnimatedSprite2D.new()
	_me.sprite_frames = SideFrames.build(load("res://assets/prologue/player.png"), SideFrames.PLAYER)
	_me.play("idle")
	add_child(_me)
	_fx = Node2D.new()
	_fx.draw.connect(_draw_fx)
	add_child(_fx)
	for n in ["hit-1", "miss", "grunt", "gogogo"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/%s.wav" % n)
		p.volume_db = -6.0
		add_child(p)
		_sfx[n] = p
	var ui := CanvasLayer.new()
	ui.layer = 4
	add_child(ui)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.08, 0.06, 0.1, 0.85)
	_bar_bg.position = Vector2(8, 8)
	_bar_bg.size = Vector2(84, 9)
	ui.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.position = Vector2(10, 10)
	_bar.size = Vector2(80, 5)
	ui.add_child(_bar)
	var cap := _label("VENTAJA", Vector2(96, 8), Color(0.85, 0.85, 0.9))
	cap.size = Vector2(80, 10)
	ui.add_child(cap)
	_dog_icon = TextureRect.new()  # Lukas todavía no ha mordido a nadie
	_dog_icon.texture = Lukas.cell(3, 0)
	_dog_icon.position = Vector2(158, 3)
	ui.add_child(_dog_icon)
	_hint = _label("", Vector2(0, 26), Color(1, 0.9, 0.5))
	_hint.size = Vector2(Controls.right_edge(), 22)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(_hint)
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 1)
	_black.size = Vector2(320, 180)
	ui.add_child(_black)
	_laminas = LAMINAS.new()
	ui.add_child(_laminas)
	_panic = AudioStreamPlayer.new()
	var loop: AudioStreamWAV = load("res://assets/music/panico.wav")
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	_panic.stream = loop
	_panic.bus = MusicDirector.BUS  # es música: la apaga la misma opción
	_panic.volume_db = -4.0
	add_child(_panic)
	_place()
	_story.call_deferred()


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.08))
	return l


func _fade(to: float, secs: float) -> void:
	await create_tween().tween_property(_black, "color:a", to, secs).finished


# ---------------------------------------------------------------- La historia

func _story() -> void:
	Dream.reset()
	stage = 1
	_load_stage()
	MusicDirector.force("")
	_panic.pitch_scale = 0.8
	_panic.play()
	await get_tree().create_timer(0.8).timeout
	for i in INTRO.size():
		# Cada texto, su lámina; y el corazón, un poco más rápido.
		_laminas.show_page(i)
		create_tween().tween_property(_panic, "pitch_scale", lerpf(0.8, 1.45, float(i) / (INTRO.size() - 1)), 0.6)
		if i == 9:  # el tiro
			_sfx["hit-1"].play()
			var shake := create_tween()
			for k in 5:
				shake.tween_property(_laminas, "position", Vector2(randf_range(-4, 4), randf_range(-3, 3)), 0.04)
			shake.tween_property(_laminas, "position", Vector2.ZERO, 0.04)
		await Dialogue.talk([INTRO[i]])
	_laminas.clear()
	_panic.stop()
	_intro = false
	MusicDirector.force("huida")
	await _fade(0.0, 0.8)
	await _go("LOS TECHOS")
	_run = true


func _go(title: String) -> void:
	_hint.text = title
	_sfx["gogogo"].play()
	await get_tree().create_timer(1.2).timeout
	_hint.text = ""


func _load_stage() -> void:
	var s: Dictionary = STAGES[stage]
	_obs.clear()
	for o in s["obs"]:
		_obs.append({"x": float(o[0]), "kind": o[1], "done": float(o[0]) < _check_x})
	_x = _check_x
	_y = 0.0
	_vy = 0.0
	_slide = 0.0
	_stun = 0.0
	_crouch = false
	_beam = ""
	_shots.clear()
	_lead = 100.0
	_jumped_off = false
	if not _intro:
		MusicDirector.force("huida")
	_place()


## Lo agarraron: el narrador se corrige y el tramo empieza otra vez.
func _caught() -> void:
	_run = false
	_me.play("fall")
	_sfx["grunt"].play()
	await get_tree().create_timer(0.7).timeout
	await _fade(1.0, 0.4)
	_laminas.show_page(13)
	await Dialogue.talk([["", RETCON[_tries % RETCON.size()]]])
	_laminas.clear()
	_tries += 1
	_load_stage()
	await _fade(0.0, 0.4)
	_run = true


func _stage_done() -> void:
	_run = false
	if stage == 1:
		_me.play("idle")
		await _fade(1.0, 0.5)
		_laminas.show_page(11)
		await Dialogue.talk([
			["", "(Catorce techos. Él no sabía que sabía saltar. Lukas sí sabía: lleva años practicando con el sofá.)"],
			["", "(Abajo, el megáfono sigue hablándole a un apartamento vacío. Le piden que salga con las manos arriba. Sale el humo del arroz.)"],
			["", "(Queda una sola salida del barrio. El puente.)"]])
		_laminas.clear()
		stage = 2
		_check_x = 0.0
		_load_stage()
		await _fade(0.0, 0.5)
		await _go("EL PUENTE")
		_run = true
		return
	await _ending()


## Saltó la baranda. El río. Y despierta.
func _ending() -> void:
	MusicDirector.force("")
	_me.play("kick")
	var t := create_tween()
	t.tween_property(_me, "position", _me.position + Vector2(46, -34), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(_me, "position", _me.position + Vector2(80, 70), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var d := create_tween()
	d.tween_interval(0.2)
	d.tween_property(_dog, "position", _dog.position + Vector2(50, -30), 0.4)
	d.tween_property(_dog, "position", _dog.position + Vector2(84, 74), 0.6)
	await t.finished
	_sfx["miss"].play()
	await _fade(1.0, 0.25)
	await get_tree().create_timer(1.0).timeout
	_laminas.show_page(12)
	await Dialogue.talk([
		["", "(El agua está fría. El río no pide documentos.)"],
		["", "(Arriba, alguien dice por radio que el sujeto se ahogó. Lo anotan. Les sirve más ahogado.)"],
		["", "(No se ahogó. Lukas tampoco: nada mejor que él, y se lo hace saber.)"],
		["", "(La denuncia la retiraron meses después. Página 14. La casa ya tenía otro candado. La cédula, otro cajón.)"],
		["", "(Sale del agua debajo del puente. Se queda ahí. Uno se queda donde lo deja el río.)"],
	])
	if GameState.flags.get("arcade", false):  # suelto, desde el menú SUEÑOS: vuelve al título
		SceneRouter.go(NEXT_SCENE)
		return
	GameState.new_game()
	GameState.learn("aguante")  # la huida enseña a aguantar
	TimeManager.set_time(6, 17)
	SceneRouter.go(NEXT_SCENE, "Start", NEXT_TITLE, WAKE_LINE)


# ---------------------------------------------------------------- Correr

func _process(delta: float) -> void:
	_t += delta
	if _run:
		_tick(delta)
	_place()
	queue_redraw()
	_fx.queue_redraw()


func _tick(delta: float) -> void:
	var s: Dictionary = STAGES[stage]
	var speed: float = s["speed"]
	var down := Input.is_action_pressed("move_down")
	var jump := Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("move_up")
	_stun = maxf(0.0, _stun - delta)
	# La baranda del puente: saltar al río.
	if stage == 2 and _x >= JUMP_FROM and _x <= JUMP_TO and jump and _stun <= 0.0:
		_jumped_off = true
		_stage_done()
		return
	if _y <= 0.0 and _stun <= 0.0:
		if jump and not _crouch:
			_vy = JUMP
			_y = 0.01
			_slide = 0.0
			_sfx["miss"].play()
		elif down:
			if not _crouch and _slide <= 0.0:
				var cover := _near_cover()
				if cover >= 0.0:
					_x = cover  # se mete detrás del tanque
					_crouch = true
				else:
					_slide = 0.55
			elif _slide <= 0.0:
				_crouch = true
		else:
			_crouch = false
	if _slide > 0.0:
		_slide -= delta
		if _slide <= 0.0 and down:
			_crouch = true
	if _y > 0.0:
		_vy += GRAVITY * delta
		_y -= _vy * delta
		if _y <= 0.0:
			_y = 0.0
			_vy = 0.0
	if _stun <= 0.0 and not _crouch:
		_x += speed * delta
	_lead = clampf(_lead - float(s["drain"]) * delta, 0.0, 100.0)
	_obstacles()
	_shots_tick(delta)
	_beam_tick(delta)
	_hints()
	if _lead <= 0.0 and not _lukas_used and not (stage == 2 and _x > JUMP_TO + 30.0):
		_lukas_saves()
	elif _lead <= 0.0 or (stage == 2 and _x > JUMP_TO + 30.0):
		_caught()
	elif _x >= float(s["end"]) and stage == 1:
		_stage_done()


## Lo iban a agarrar: Lukas se devuelve y los muerde. Una sola vez.
func _lukas_saves() -> void:
	_lukas_used = true
	_run = false
	_dog_busy = true
	_dog_icon.visible = false
	_shots.clear()
	_beam = ""
	_hint.text = "¡LUKAS!"
	_me.play("idle")
	_lead = 12.0  # (los tiene encima)
	_place()
	var home := _dog.position
	var at: Vector2 = _cops[0].position + Vector2(6, 15)
	_dog.flip_h = false
	_dog.speed_scale = 2.4
	await create_tween().tween_property(_dog, "position", at, 0.22).finished
	for k in 4:
		_sfx["hit-1"].play()
		for c in _cops:
			c.play("hurt")
		var bite := create_tween()
		bite.tween_property(_dog, "position", at + Vector2(-12 if k % 2 == 0 else -2, -9), 0.07)
		bite.tween_property(_dog, "position", at, 0.07)
		var cam := create_tween()
		cam.tween_property(self, "position:y", 2.0, 0.04)
		cam.tween_property(self, "position:y", 0.0, 0.06)
		await bite.finished
		await get_tree().create_timer(0.06).timeout
	for c in _cops:
		c.play("fall")
	_dog.flip_h = true
	await create_tween().tween_property(_dog, "position", home, 0.25).finished
	_hint.text = ""
	await Dialogue.talk([
		["", "(Lukas se devolvió. Mordió dos pantalones reglamentarios y un radio. El radio sabía mejor.)"],
		["", "(Eso lo hace una sola vez. Después le da pena, y además se cansa.)"]])
	_lead = 55.0
	_stun = 0.0
	for c in _cops:
		c.play("walk")
	_dog_busy = false
	_run = true


func _near_cover() -> float:
	for o in _obs:
		if o["kind"] == "tanque" and absf(o["x"] - _x) < 38.0:
			return o["x"]
	return -1.0


func _obstacles() -> void:
	for o in _obs:
		if o["done"]:
			continue
		var dx: float = _x - o["x"]
		match o["kind"]:
			"muro", "cono":
				if absf(dx) < 7.0:
					o["done"] = true
					if _y < 13.0:
						_trip(25.0)
			"ropa", "rafaga":
				if absf(dx) < 6.0:
					o["done"] = true
					if not (_slide > 0.0 or _crouch) or _y > 0.0:
						_trip(25.0 if o["kind"] == "ropa" else 34.0)
			"hueco":
				if dx > 8.0 and dx < 38.0 and _y <= 0.0:
					o["done"] = true
					_x = o["x"] + 58.0  # se cuelga del borde y sube como puede
					_trip(30.0)
				elif dx >= 46.0:
					o["done"] = true
			"luz":
				if dx >= 0.0:
					o["done"] = true
					_beam = "warn"
					_beam_t = 1.7
					_beam_hit = false
					_cover_x = o["x"] + 160.0  # (el tanque que sigue)
			"tanque":
				if dx > 40.0:
					o["done"] = true
					_check_x = o["x"] + 40.0
			"tiro_a", "tiro_ab", "tiro_f", "tiro_fb":
				if dx >= 0.0:
					o["done"] = true
					var back: bool = o["kind"] in ["tiro_a", "tiro_ab"]
					_shots.append({"x": -8.0 if back else 328.0, "dir": 1.0 if back else -1.0,
						"high": o["kind"] in ["tiro_a", "tiro_f"], "warn": 0.75 if back else 0.4, "hit": false})


## Las balas: primero el aviso en el borde, después pasan. Alta: agachado. Baja: en el aire.
func _shots_tick(delta: float) -> void:
	var keep: Array = []
	for s in _shots:
		if s["warn"] > 0.0:
			s["warn"] -= delta
			if s["warn"] <= 0.0:
				_sfx["miss"].play()
			keep.append(s)
			continue
		var before: float = s["x"]
		var now: float = before + float(s["dir"]) * SHOT_SPEED * delta
		s["x"] = now
		if not s["hit"] and (before - PX) * (now - PX) <= 0.0:
			s["hit"] = true
			var safe: bool = ((_crouch or _slide > 0.0) and _y <= 0.0) if s["high"] else _y > 7.0
			if not safe:
				_trip(22.0)
				continue  # (le dio: la bala no sigue)
		if now > -30.0 and now < 350.0:
			keep.append(s)
	_shots = keep


func _trip(cost: float) -> void:
	_lead -= cost
	_stun = 0.55
	_slide = 0.0
	_crouch = false
	_vy = 0.0
	_y = 0.0
	_sfx["hit-1"].play()
	_me.play("hurt")
	var cam := create_tween()
	cam.tween_property(self, "position:y", 3.0, 0.04)
	cam.tween_property(self, "position:y", 0.0, 0.08)


## La luz del helicóptero: avisa, barre, y al que encuentra parado le disparan.
func _beam_tick(delta: float) -> void:
	if _beam == "":
		return
	_beam_t -= delta
	if _beam == "warn" and _beam_t <= 0.0:
		_beam = "on"
		_beam_t = 1.7
	elif _beam == "on":
		var hidden: bool = _crouch and absf(_x - _cover_x) < 28.0
		if not hidden and not _beam_hit and _beam_t < 1.45:
			_beam_hit = true
			_trip(35.0)
		if _beam_t <= 0.0:
			_beam = ""


func _hints() -> void:
	var text := ""
	if _beam == "warn":
		text = "¡EL HELICOPTERO! Abajo, detrás del tanque"
	elif _beam == "on":
		text = "(quieto)" if _crouch else ""
	elif stage == 2 and _x >= JUMP_FROM - 40.0 and _x <= JUMP_TO:
		text = Controls.keys_in("¡E! ¡AL RIO!")
	elif not _shots.is_empty() and not _shots[0]["hit"]:
		text = ("¡BALA ATRAS! " if _shots[0]["dir"] > 0.0 else "¡BALA AL FRENTE! ") \
			+ ("¡Abajo!" if _shots[0]["high"] else Controls.keys_in("¡E, salta!"))
	else:
		for o in _obs:
			var ahead: float = o["x"] - _x
			if o["done"] or ahead < 0.0 or ahead > 110.0 or _seen.get(o["kind"], 0) >= 2:
				continue
			match o["kind"]:
				"muro", "cono", "hueco":
					text = Controls.keys_in("E: saltar")
				"ropa":
					text = "Abajo: agacharse"
				"rafaga":
					text = "¡Abajo!"
			if text != "":
				if ahead < 12.0 and not o.has("hinted"):
					o["hinted"] = true
					_seen[o["kind"]] = int(_seen.get(o["kind"], 0)) + 1
				break
	_hint.text = text


# ---------------------------------------------------------------- Dibujar

func _place() -> void:
	if _jumped_off:
		return
	_me.position = Vector2(PX, GROUND - 22.0 - _y)
	if _run:
		var anim := "walk"
		if _stun > 0.0:
			anim = "hurt"
		elif _crouch or _slide > 0.0:
			anim = "crouch"
		if _me.animation != anim:
			_me.play(anim)
		_me.speed_scale = 1.5
	if not _dog_busy:
		_dog.position = Vector2(PX - 24.0, GROUND - 7.0 - _y * 0.7)
		_dog.speed_scale = 0.0 if (_crouch or not _run) else 1.6
	for i in _cops.size():
		var c: AnimatedSprite2D = _cops[i]
		c.position = Vector2(PX - 46.0 - _lead * 0.9 - i * 18.0, GROUND - 22.0)
	_bar.size.x = 80.0 * _lead / 100.0
	_bar.color = Color(0.4, 0.9, 0.5) if _lead > 50.0 else (Color(1.0, 0.8, 0.3) if _lead > 25.0 else Color(1.0, 0.35, 0.3))


func _sx(wx: float) -> float:
	return wx - _x + PX


func _draw() -> void:
	# El cielo, la luna, la ciudad lejos.
	draw_rect(Rect2(0, 0, 320, 180), Color(0.05, 0.05, 0.11))
	draw_rect(Rect2(0, 70, 320, 110), Color(0.09, 0.07, 0.14))
	draw_circle(Vector2(250, 30), 9.0, Color(0.85, 0.85, 0.75))
	draw_circle(Vector2(254, 28), 8.0, Color(0.05, 0.05, 0.11))
	var off := fposmod(_x * 0.18, 640.0)
	for k in 2:
		draw_texture(_skyline, Vector2(-off + k * 640.0, 44), Color(0.5, 0.5, 0.7))
	if stage == 2:
		_draw_bridge()
	else:
		_draw_roofs()
	# Atrás, las sirenas: rojo y azul, más fuertes cuanto más cerca.
	var near := 1.0 - _lead / 100.0
	var red := fmod(_t * 3.0, 1.0) < 0.5
	draw_rect(Rect2(0, 0, 26.0 + near * 40.0, 180), Color(1.0, 0.15, 0.15, 0.06 + 0.2 * near) if red else Color(0.2, 0.35, 1.0, 0.06 + 0.2 * near))


func _draw_roofs() -> void:
	var roof := Color(0.24, 0.16, 0.16)
	var edge := Color(0.42, 0.3, 0.26)
	# Los techos: una losa seguida, menos en los huecos.
	draw_rect(Rect2(0, GROUND, 320, 180 - GROUND), roof)
	draw_rect(Rect2(0, GROUND, 320, 2), edge)
	var first := int(floor((_x - PX) / 90.0))
	for k in range(first, first + 6):
		var bx := _sx(k * 90.0)
		var h := hash(k)
		draw_rect(Rect2(bx + 8, GROUND + 8, 10, 8), Color(1.0, 0.8, 0.4, 0.7) if h % 3 == 0 else Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(bx + 50, GROUND + 14, 10, 8), Color(1.0, 0.8, 0.4, 0.7) if h % 5 == 0 else Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(bx, GROUND, 1, 40), Color(0.16, 0.1, 0.12))
		if h % 4 == 1:  # una antena
			draw_line(Vector2(bx + 34, GROUND), Vector2(bx + 34, GROUND - 26), Color(0.3, 0.3, 0.34))
			draw_line(Vector2(bx + 28, GROUND - 22), Vector2(bx + 40, GROUND - 22), Color(0.3, 0.3, 0.34))
			draw_line(Vector2(bx + 30, GROUND - 17), Vector2(bx + 38, GROUND - 17), Color(0.3, 0.3, 0.34))
	for o in _obs:
		var sx := _sx(o["x"])
		if sx < -80.0 or sx > 400.0:
			continue
		match o["kind"]:
			"muro":
				draw_rect(Rect2(sx - 5, GROUND - 15, 10, 15), Color(0.5, 0.34, 0.28))
				draw_rect(Rect2(sx - 6, GROUND - 16, 12, 2), Color(0.66, 0.5, 0.4))
				draw_line(Vector2(sx - 5, GROUND - 8), Vector2(sx + 5, GROUND - 8), Color(0.36, 0.24, 0.2))
			"hueco":
				draw_rect(Rect2(sx, GROUND, 46, 180 - GROUND), Color(0.03, 0.03, 0.06))
				draw_rect(Rect2(sx + 20, 172, 3, 2), Color(1.0, 0.85, 0.5, 0.8))  # un farol, allá abajo
				draw_rect(Rect2(sx - 1, GROUND, 2, 40), edge)
				draw_rect(Rect2(sx + 45, GROUND, 2, 40), edge)
			"ropa":
				draw_line(Vector2(sx - 30, GROUND - 33), Vector2(sx + 30, GROUND - 33), Color(0.7, 0.7, 0.7))
				draw_line(Vector2(sx - 30, GROUND), Vector2(sx - 30, GROUND - 34), Color(0.3, 0.3, 0.34))
				draw_line(Vector2(sx + 30, GROUND), Vector2(sx + 30, GROUND - 34), Color(0.3, 0.3, 0.34))
				draw_rect(Rect2(sx - 20, GROUND - 32, 9, 12), Color(0.85, 0.85, 0.9))
				draw_rect(Rect2(sx - 6, GROUND - 32, 11, 14), Color(0.8, 0.35, 0.35))
				draw_rect(Rect2(sx + 10, GROUND - 32, 8, 10), Color(0.4, 0.6, 0.85))
			"tanque":
				draw_rect(Rect2(sx - 13, GROUND - 26, 26, 26), Color(0.2, 0.24, 0.3))
				draw_rect(Rect2(sx - 15, GROUND - 28, 30, 3), Color(0.32, 0.36, 0.44))
				draw_rect(Rect2(sx - 9, GROUND - 20, 3, 14), Color(0.28, 0.32, 0.4))


func _draw_bridge() -> void:
	# El río abajo, la calzada, la baranda atrás.
	draw_rect(Rect2(0, GROUND + 14, 320, 40), Color(0.05, 0.08, 0.14))
	for k in 6:
		var rx := fposmod(k * 61.0 - _x * 0.5, 340.0) - 10.0
		draw_rect(Rect2(rx, GROUND + 22 + (k % 3) * 5, 14, 1), Color(0.3, 0.4, 0.55, 0.6))
	draw_rect(Rect2(0, GROUND, 320, 14), Color(0.2, 0.2, 0.24))
	draw_rect(Rect2(0, GROUND, 320, 2), Color(0.4, 0.4, 0.46))
	var first := int(floor((_x - PX) / 40.0))
	for k in range(first, first + 10):
		var bx := _sx(k * 40.0)
		draw_rect(Rect2(bx, GROUND - 16, 3, 16), Color(0.34, 0.34, 0.4))
		draw_rect(Rect2(bx + 10, GROUND + 6, 14, 2), Color(0.8, 0.75, 0.4, 0.7))
	draw_rect(Rect2(0, GROUND - 17, 320, 2), Color(0.44, 0.44, 0.5))
	draw_rect(Rect2(0, GROUND - 9, 320, 1), Color(0.34, 0.34, 0.4))
	for o in _obs:
		var sx := _sx(o["x"])
		if sx < -80.0 or sx > 400.0:
			continue
		match o["kind"]:
			"cono":
				draw_colored_polygon(PackedVector2Array([Vector2(sx - 5, GROUND), Vector2(sx + 5, GROUND), Vector2(sx + 1, GROUND - 14), Vector2(sx - 1, GROUND - 14)]), Color(1.0, 0.5, 0.15))
				draw_rect(Rect2(sx - 3, GROUND - 8, 6, 2), Color(0.95, 0.95, 0.95))
			"rafaga":
				for j in 3:  # las trazadoras, a la altura de la cabeza
					draw_line(Vector2(sx - 40 + j * 22, GROUND - 31 - j * 2), Vector2(sx - 24 + j * 22, GROUND - 31 - j * 2), Color(1.0, 0.95, 0.5), 1.0)
	# El retén, al fondo del puente.
	var gate := _sx(JUMP_TO + 60.0)
	if gate < 420.0:
		var red := fmod(_t * 4.0, 1.0) < 0.5
		for j in 2:
			draw_rect(Rect2(gate + j * 34, GROUND - 16, 30, 16), Color(0.85, 0.85, 0.9))
			draw_rect(Rect2(gate + j * 34, GROUND - 9, 30, 4), Color(0.15, 0.3, 0.6))
			draw_rect(Rect2(gate + j * 34 + 10, GROUND - 20, 5, 4), Color(1, 0.2, 0.2) if red else Color(0.4, 0.1, 0.1))
			draw_rect(Rect2(gate + j * 34 + 16, GROUND - 20, 5, 4), Color(0.1, 0.15, 0.5) if red else Color(0.3, 0.5, 1.0))
		draw_rect(Rect2(gate - 18, 0, 200, 180), Color(1.0, 0.2, 0.2, 0.1) if red else Color(0.2, 0.35, 1.0, 0.1))
	var from := _sx(JUMP_FROM)
	if from < 340.0:  # el pedazo de baranda roto: por aquí
		draw_rect(Rect2(from, GROUND - 18, JUMP_TO - JUMP_FROM, 4), Color(0.09, 0.07, 0.14))
		draw_rect(Rect2(from, GROUND - 9, JUMP_TO - JUMP_FROM, 1), Color(1.0, 0.85, 0.3))


## Encima de todo: las balas y la luz del helicóptero.
func _draw_fx() -> void:
	for s in _shots:
		var y := GROUND - (31.0 if s["high"] else 5.0)
		var dir: float = s["dir"]
		if s["warn"] > 0.0:  # el aviso, en el borde por donde viene
			if fmod(_t * 10.0, 1.0) < 0.6:
				var ex := 5.0 if dir > 0.0 else 315.0
				_fx.draw_colored_polygon(PackedVector2Array([Vector2(ex - 4 * dir, y - 5), Vector2(ex + 5 * dir, y), Vector2(ex - 4 * dir, y + 5)]), Color(1.0, 0.3, 0.25))
		else:
			var x: float = s["x"]
			_fx.draw_line(Vector2(x - 26.0 * dir, y), Vector2(x - 8.0 * dir, y), Color(1.0, 0.9, 0.5, 0.35), 1.0)
			_fx.draw_line(Vector2(x - 8.0 * dir, y), Vector2(x, y), Color(1.0, 0.95, 0.6), 2.0)
	if _beam == "":
		return
	var cx := _sx(_cover_x)
	if _beam == "warn":
		# Viene barriendo desde adelante.
		cx += 220.0 * (_beam_t / 1.7)
		_cone(cx, Color(1.0, 1.0, 0.85, 0.12))
	else:
		cx += sin(_t * 5.0) * 26.0
		_cone(cx, Color(1.0, 1.0, 0.85, 0.3))


func _cone(cx: float, col: Color) -> void:
	_fx.draw_colored_polygon(PackedVector2Array([Vector2(cx - 30, -4), Vector2(cx - 22, -4), Vector2(cx + 46, GROUND + 2), Vector2(cx - 46, GROUND + 2)]), col)
	_fx.draw_rect(Rect2(cx - 46, GROUND, 92, 3), Color(col.r, col.g, col.b, col.a * 1.5))
