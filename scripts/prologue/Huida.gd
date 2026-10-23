extends Node2D
## EL PRÓLOGO: la huida. Lo que pasó de verdad, la noche del operativo (y lo que él sueña siempre).
## Diana Carolina lo denunció por lo del aborto; Lorena dio la dirección, la foto y el "está armado".
## Llegaron a matarlo. Él salió por la ventana de atrás con Lukas y la mochila.
##   Tramo 1, LOS TECHOS: corre solo, techo por techo (unos más altos que otros). [E] o arriba: saltar
##     (el muro con vidrios, la pipeta, los ladrillos, los huecos, el techo de al lado). Abajo: tirarse
##     y pasar apretado por debajo (el tanque elevado, el palomar, la mesa del cumpleaños, la placa
##     apuntalada; lo largo, manteniendo abajo). Cerca de un tanque, abajo: esconderse de la luz del
##     helicóptero. En la calle que Lukas no alcanza a saltar, [E]: alzarlo; un rato corre con él en
##     brazos (y así no hay cómo tirarse al piso).
##   Tramo 2, EL PUENTE: más rápido, el trancón. Conos y taxis (saltar), el tráiler de la mula y el
##     poste caído (por debajo). Al final, el retén: saltar la baranda, al río.
## Lo que le disparan: las patrullas (la bala avisa en el borde: alta, al piso; baja, saltar) y el
##   helicóptero: la ráfaga que barre el techo (saltarla) y la mira (tirarse: se pasa de largo).
## Los vecinos, desde sus terrazas: lo que gritan (lo del aborto, sin piedad) y lo que tiran (chancla,
##   huevo, matera, biblia: al piso).
## Lukas: la primera vez que lo van a agarrar, se devuelve bravo y los muerde: la ventaja vuelve a la
##   mitad. Una sola vez en toda la huida (el perrito al lado de la barra).
## Una sola barra: la VENTAJA. Tropezar, caerse o que lo alumbren la baja. En cero lo agarran... y el
## narrador se corrige ("así no fue"): se repite desde el último tanque. No hay game over: es un recuerdo.
## Después del río: negro, y despierta debajo del puente. Día 1.
## Antes de correr, lo que pasó se cuenta: cada texto trae su lámina (Laminas.gd), que se dibuja sola,
## y la música del miedo ("panico") se acelera con cada uno. Al correr entra "huida".
## El arte: tools/art/draw_huida.py. Los sonidos: tools/audio/huida_sfx.py.

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

const ART := "res://assets/prologue/huida/"
const SLIDE_TIME := 0.6
const SLIDE_BOOST := 1.5   # tirarse lo adelanta: así se le sale a la mira
## Lo que se pasa por debajo: [la hoja (<hoja>_atras y _frente), dónde empieza el paso dentro del dibujo,
## el largo del paso]. Debajo quedan 13 píxeles: él pasa acostado, apretado (mide 11).
const DUCK := {"elevado": ["tanque", 3, 33], "palomar": ["palomar", 3, 44], "cumple": ["cumple", 0, 64],
	"placa": ["placa", 0, 96], "mula": ["mula", 4, 142], "poste": ["poste", 12, 58]}
## Lo que se salta: [medio ancho, alto]. Se dibuja salta_<tipo>.png (el cono, aquí mismo).
const JUMPS := {"muro": [5.0, 17.0], "pipeta": [5.0, 17.0], "ladrillos": [9.0, 13.0], "cono": [5.0, 14.0],
	"taxi": [19.0, 19.0]}
const ITEMS := ["¡UNA CHANCLA!", "¡UN HUEVO!", "¡UNA MATERA!", "¡UNA BIBLIA!"]
## Lo que gritan. Por quién: 0 la de los rulos, 1 el de la barriga, 2 la rezandera, 3 el pelado del
## celular, 4 los taxistas del trancón, 5 la tía del cumpleaños. Cada uno dice lo suyo y no repite.
const GRITOS := [
	["¡Asesino! ¡Mató a su propio hijo!", "¡Lo vi en el grupo del barrio! ¡Es él, el del aborto!",
		"¡Pobre muchacha! ¡Y usted corriendo, cobarde!", "¡Que lo maten como él mató a ese bebé!"],
	["¡Dispárenle a las patas! ¡Pero no a mi teja!", "¡Abortero hijueputa! ¡Que se pudra!",
		"¡Bájenlo de ahí! ¡Un tiro y listo!", "¡Venga, que aquí lo esperamos, matabebés!"],
	["¡Ave María Purísima! ¡Mató a un angelito!", "¡Ese bebé lo está viendo desde el cielo!",
		"¡El infierno tiene una silla con su nombre!", "¡Que Dios lo castigue! ¡Y que no lo perdone!"],
	["¡Estoy en vivo! ¡Salude, asesino!", "¡Cien likes y lo cogen!",
		"¡Un matabebés corriendo por mi techo, parce!", "¡Esto se va pa' noticias!"],
	["¡Asesino! ¡Y encima se me mete al carril!", "¡Que lo atropellen! ¡Yo no, que el carro es arrendado!",
		"¡Eso, a la cárcel, matando bebés!"],
	["¡Ay! ¡El del aborto, debajo de la torta!", "¡Cójanlo! ¡Nos daña el cumpleaños!"],
]

## Cada tramo: [x, tipo, ...]. Saltar (JUMPS): muro, pipeta, ladrillos, cono, taxi (el taxi, con true:
## el taxista grita). Por debajo (DUCK). hueco: saltar (46 de ancho). calle: la que Lukas no salta (60):
## hay que alzarlo; suelta: lo pone en el piso. nivel, h: desde ahí el techo queda a h de alto (los
## techos no son parejos). luz: viene el helicóptero; agacharse detrás del tanque que sigue. tanque:
## donde esconderse (y desde donde se repite). check: desde donde se repite, sin tanque.
## tiro_a / tiro_ab: bala de atrás, alta (al piso) / baja (saltar). tiro_f / tiro_fb: de frente.
## barrido / barrido_b: la ráfaga del helicóptero, de frente / de atrás (saltarla). mira: lo tienen en
## la mira (tirarse). vecino, quién (0-3), lo que tira (-1: nada; 0-3: ITEMS), la baranda (0-1).
const STAGES := {
	1: {"speed": 92.0, "ramp": 20.0, "end": 7560.0, "drain": -2.5, "obs": [
		[150, "vecino", 0, -1, 0], [330, "muro"], [520, "elevado"], [680, "vecino", 2, -1, 1], [740, "tiro_a"],
		[1000, "hueco"], [1200, "vecino", 1, 1, 0], [1260, "nivel", 12], [1340, "ladrillos"], [1440, "barrido"],
		[1560, "nivel", 0], [1720, "palomar"], [1860, "luz"], [2020, "tanque"], [2120, "vecino", 3, -1, 1],
		[2160, "tiro_ab"], [2380, "pipeta"], [2460, "mira"], [2780, "hueco"], [3000, "vecino", 2, 3, 0],
		[3060, "nivel", 14], [3140, "cumple"], [3280, "nivel", 26], [3360, "muro"], [3460, "barrido_b"],
		[3640, "nivel", 0], [3760, "calle"], [3940, "muro"], [4060, "barrido"], [4330, "ladrillos"],
		[4420, "tiro_ab"], [4620, "suelta"], [4700, "luz"], [4860, "tanque"], [5150, "vecino", 0, 2, 1],
		[5200, "placa"], [5420, "tiro_a"], [5640, "hueco"], [5760, "mira"], [6080, "vecino", 1, 1, 0],
		[6130, "vecino", 3, -1, 1], [6200, "nivel", 12], [6270, "pipeta"], [6360, "barrido"], [6620, "nivel", 0],
		[6720, "hueco"], [6840, "tiro_ab"], [7020, "tiro_a"], [7260, "muro"], [7340, "barrido_b"]]},
	2: {"speed": 114.0, "ramp": 12.0, "end": 3290.0, "drain": 1.2, "obs": [
		[60, "tiro_f"], [300, "cono"], [440, "taxi", true], [560, "tiro_fb"], [760, "mula"], [1000, "barrido"],
		[1300, "cono"], [1380, "tiro_a"], [1620, "taxi", true], [1700, "check"], [1760, "poste"], [1900, "mira"],
		[2200, "tiro_fb"], [2400, "cono"], [2480, "barrido_b"], [2770, "taxi", false], [2840, "tiro_f"],
		[3040, "cono"]]},
}
const SHOT_SPEED := 300.0
const JUMP_FROM := 3150.0  # la baranda: desde aquí se puede saltar al río
const JUMP_TO := 3260.0
const RETCON := [
	"(Lo agarran. ... No. Así no fue. Si lo hubieran agarrado, no habría Día 1. Otra vez.)",
	"(Lo alcanzan en la esquina. ... Tampoco. Él se acuerda de haber corrido mejor. Otra vez.)",
	"(Ahí quedó. ... No, no quedó. La memoria a veces lo deja mal parado a propósito. Otra vez.)",
]

var stage := 0
var _run := false
var _x := 0.0
var _y := 0.0          # altura sobre la calle (el techo de cada parte está a _floor_at(x))
var _vy := 0.0
var _speed := 0.0
var _slide := 0.0
var _crouch := false
var _in_pass := false  # debajo de algo: va acostado
var _stun := 0.0
var _lead := 100.0
var _obs: Array = []
var _levels: Array = []  # [x, alto]: los techos, de izquierda a derecha
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
var _strafe := {}           # la ráfaga del helicóptero: {x (en pantalla), dir, v, warn, hit}
var _aim := {}              # la mira: {phase ("track", "lock"), t, lx (dónde va a dar)}
var _throws: Array = []     # lo que tiran: {from, to (en pantalla), t, T, item, done, hit}
var _parts: Array = []      # polvo, agua, astillas, chispas: {x (mundo), y, vx, vy, life, col, size, g}
var _birds: Array = []      # las palomas que salen: {x (mundo), y, vx, vy}
var _splat := 0.0           # el huevo, en la cabeza
var _carry := false         # Lukas, alzado
var _lift_wait := false     # parado en el borde de la calle, esperando a que lo alce
var _carry_note := 0.0
var _heli := Vector2(340, 52)
var _tex := {}
var _grito_n := [0, 0, 0, 0, 0, 0]
var _bubble: Label
var _bubble_t := 0.0
var _bubble_lift := 0.0
var _bubble_at := Vector2.ZERO  # x en el mundo, y en pantalla (el pie del globo)
var _lukas_used := false    # Lukas ya los mordió: solo una vez
var _dog_busy := false
var _dog_icon: TextureRect
var _laminas: Node2D
var _panic: AudioStreamPlayer
var _rotor: AudioStreamPlayer


func _ready() -> void:
	_skyline = load("res://assets/prologue/skyline.png")
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # las fachadas de los techos se repiten
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
	# Tirado (deslizándose) y apretado (debajo de algo, boca arriba): tools/art/draw_huida.py.
	var slide_sheet: Texture2D = load(ART + "player_slide.png")
	for anim in [["slide", [1, 2], 9.0], ["flat", [3, 4], 5.0]]:
		_me.sprite_frames.add_animation(anim[0])
		_me.sprite_frames.set_animation_speed(anim[0], anim[2])
		for k in anim[1]:
			var at := AtlasTexture.new()
			at.atlas = slide_sheet
			at.region = Rect2(k * 48, 0, 48, 48)
			_me.sprite_frames.add_frame(anim[0], at)
	for d in DUCK.values():
		for side in ["_atras", "_frente"]:
			_tex[d[0] + side] = load(ART + d[0] + side + ".png")
	for n in ["salta_muro", "salta_pipeta", "salta_ladrillos", "salta_taxi", "heli", "vecinos", "terraza_0",
			"terraza_1", "tiran", "paloma"]:
		_tex[n] = load(ART + n + ".png")
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
	for n in ["rafaga", "aleteo", "ploc", "chispa"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/huida/%s.wav" % n)
		p.volume_db = -8.0
		add_child(p)
		_sfx[n] = p
	_rotor = AudioStreamPlayer.new()  # el helicóptero, todo el tiempo encima
	var rot: AudioStreamWAV = load("res://assets/audio/huida/rotor.wav")
	rot.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rot.loop_begin = 0
	rot.loop_end = int(rot.get_length() * rot.mix_rate)
	_rotor.stream = rot
	_rotor.volume_db = -14.0
	add_child(_rotor)
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
	_bubble = Label.new()  # lo que gritan: un globo blanco, letra oscura
	_bubble.add_theme_font_override("font", FONT)
	_bubble.add_theme_font_size_override("font_size", 8)
	_bubble.add_theme_color_override("font_color", Color(0.25, 0.04, 0.06))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.97, 0.95, 0.9)
	box.border_color = Color(0.1, 0.06, 0.1)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 4
	box.content_margin_right = 4
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	_bubble.add_theme_stylebox_override("normal", box)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.visible = false
	ui.add_child(_bubble)
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
	_rotor.play()
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
	_levels.clear()
	for o in s["obs"]:
		var d := {"x": float(o[0]), "kind": o[1], "done": float(o[0]) < _check_x}
		for k in range(2, o.size()):
			d[["a", "b", "c"][k - 2]] = o[k]
		_obs.append(d)
		if o[1] == "nivel":
			_levels.append([float(o[0]), float(o[2])])
	_x = _check_x
	_y = _floor_at(_x)
	_vy = 0.0
	_slide = 0.0
	_stun = 0.0
	_crouch = false
	_in_pass = false
	_beam = ""
	_shots.clear()
	_strafe = {}
	_aim = {}
	_throws.clear()
	_parts.clear()
	_birds.clear()
	_splat = 0.0
	_carry = false
	_lift_wait = false
	_bubble_t = 0.0
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
	_rotor.stop()
	_bubble_t = 0.0
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
	_particles(delta)
	_heli_tick(delta)
	_bubble_tick(delta)
	_place()
	queue_redraw()
	_fx.queue_redraw()


## El techo a la altura de x (0: el de la calle de referencia; más: un piso más arriba).
func _floor_at(wx: float) -> float:
	var h := 0.0
	for l in _levels:
		if wx >= l[0]:
			h = l[1]
		else:
			break
	return h


func _air() -> float:
	return _y - _floor_at(_x)


## Al piso: tirado, agachado o, debajo de algo, con abajo apretado. Con Lukas alzado, nunca.
func _low() -> bool:
	return (_slide > 0.0 or _crouch or (_in_pass and Input.is_action_pressed("move_down"))) and _air() <= 0.01 and not _carry


func _tick(delta: float) -> void:
	var s: Dictionary = STAGES[stage]
	_speed = float(s["speed"]) + float(s["ramp"]) * clampf(_x / float(s["end"]), 0.0, 1.0)
	var down := Input.is_action_pressed("move_down")
	var jump := Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("move_up")
	_stun = maxf(0.0, _stun - delta)
	_carry_note = maxf(0.0, _carry_note - delta)
	_splat = maxf(0.0, _splat - delta)
	var fl := _floor_at(_x)
	var ground := _y <= fl + 0.01
	if _lift_wait:
		# Lukas mira la calle, mira para atrás, lo mira a él. Las patrullas vienen.
		_lead = maxf(0.0, _lead - 6.0 * delta)
		if jump:
			_lift_wait = false
			_carry = true
			_stun = 0.3
			_sfx["grunt"].play()
		jump = false
	# La baranda del puente: saltar al río.
	if stage == 2 and _x >= JUMP_FROM and _x <= JUMP_TO and jump and _stun <= 0.0:
		_jumped_off = true
		_stage_done()
		return
	if ground and _stun <= 0.0 and not _lift_wait:
		if jump and not _crouch:
			_vy = JUMP
			_y = fl + 0.01
			_slide = 0.0
			_sfx["miss"].play()
		elif down and _carry:
			_carry_note = 1.6
		elif down:
			if not _crouch and _slide <= 0.0 and not _in_pass:
				var cover := _near_cover()
				if cover >= 0.0:
					_x = cover  # se mete detrás del tanque
					_crouch = true
				else:
					_slide = SLIDE_TIME
					_sfx["miss"].play()
			elif _slide <= 0.0 and not _in_pass:
				_crouch = true
		else:
			_crouch = false
	if _slide > 0.0:
		_slide -= delta * (0.5 if down else 1.0)  # mantener abajo lo alarga
		if randf() < 0.6:
			_parts.append({"x": _x - 4.0 + randf_range(-3, 3), "y": GROUND - fl - 1.0, "vx": -10.0, "vy": -10.0,
				"life": 0.5, "col": Color(0.62, 0.56, 0.5, 0.55), "size": 1.0, "g": 0.0, "grow": true})
		if _slide <= 0.0 and down and not _in_pass:
			_crouch = true
	# Arriba y abajo: la gravedad, los techos más bajos (se cae) y los más altos (se estrella si no saltó).
	if _y > fl or _vy < 0.0:
		_vy += GRAVITY * delta
		_y -= _vy * delta
		if _y <= fl and _vy >= 0.0:
			if _y < fl - 8.0:
				_trip(20.0)
			_y = fl
			_vy = 0.0
	elif _y < fl - 0.5:
		if fl - _y > 5.0:
			_trip(20.0)
		_y = fl
	var moving := _stun <= 0.0 and not _lift_wait and (not _crouch or _in_pass)
	if moving:
		_x += _speed * delta * (SLIDE_BOOST if _slide > 0.0 else 1.0)
	_lead = clampf(_lead - float(s["drain"]) * delta, 0.0, 100.0)
	_obstacles()
	_shots_tick(delta)
	_beam_tick(delta)
	_strafe_tick(delta)
	_aim_tick(delta)
	_throws_tick(delta)
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
	_carry = false
	_lift_wait = false
	_shots.clear()
	_strafe = {}
	_aim = {}
	_throws.clear()
	_beam = ""
	_hint.text = "¡LUKAS!"
	_me.play("idle")
	_lead = 12.0  # (los tiene encima)
	_place()
	var home := Vector2(PX - 24.0, GROUND - 7.0 - _floor_at(_x - 24.0))
	var at: Vector2 = _cops[0].position + Vector2(6, 15)
	_dog.flip_h = false
	_dog.z_index = 0
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
	_bubble_t = 0.0
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
	var fl := _floor_at(_x)
	var air := _y - fl
	var low := _low()
	_in_pass = false
	for o in _obs:
		if o["done"]:
			continue
		var dx: float = _x - o["x"]
		var kind: String = o["kind"]
		if kind == "taxi" and o["a"] == true and not o.has("yelled") and dx >= -200.0:
			o["yelled"] = true
			_say(_grito(4), Vector2(o["x"] + 6.0, GROUND - 15.0), -40.0)  # (arriba: no lo tapa a él)
		if JUMPS.has(kind):
			var jw: Array = JUMPS[kind]
			if absf(dx) < float(jw[0]) + 2.0:
				if air < float(jw[1]) - 3.0:
					o["done"] = true
					_trip(25.0)
					_x = maxf(_x, o["x"] + float(jw[0]) + 3.0)  # (se va de jeta por encima)
			elif dx > float(jw[0]) + 2.0:
				o["done"] = true
			continue
		if DUCK.has(kind):
			var x1: float = o["x"] + float(DUCK[kind][2])
			if _x >= o["x"] and _x <= x1:
				_in_pass = true
				if not o.has("in"):
					o["in"] = true
					if not low:
						# Se da en la frente; pasa igual, arrastrado, pero le costó.
						o["forced"] = true
						_trip(28.0)
					_react(o)
				elif not (low or o.has("forced")) and _stun <= 0.0:
					o["forced"] = true  # se paró debajo: otro golpe
					_trip(18.0)
				if o.has("forced"):
					_slide = maxf(_slide, 0.1)
			elif _x > x1:
				o["done"] = true
			continue
		match kind:
			"hueco", "calle":
				var wdt := 46.0 if kind == "hueco" else 60.0
				if kind == "calle" and not _carry and not o.has("lift") and dx >= -24.0:
					o["lift"] = true
					_lift_wait = true
					_x = o["x"] - 24.0
					_slide = 0.0
					_crouch = false
				elif dx > 8.0 and dx < wdt - 8.0 and air <= 0.01:
					o["done"] = true
					_x = o["x"] + wdt + 12.0  # se cuelga del borde y sube como puede
					_trip(30.0)
				elif dx >= wdt:
					o["done"] = true
			"suelta":
				if dx >= 0.0:
					o["done"] = true
					_carry = false
					_check_x = o["x"]
			"check":
				if dx >= 0.0:
					o["done"] = true
					_check_x = o["x"]
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
					var back: bool = kind in ["tiro_a", "tiro_ab"]
					_shots.append({"x": -8.0 if back else 328.0, "dir": 1.0 if back else -1.0,
						"high": kind in ["tiro_a", "tiro_f"], "warn": 0.75 if back else 0.4, "hit": false})
			"barrido", "barrido_b":
				if dx >= 0.0:
					o["done"] = true
					var behind := kind == "barrido_b"
					_strafe = {"x": -14.0 if behind else 334.0, "dir": 1.0 if behind else -1.0,
						"v": 330.0 if behind else 240.0, "warn": 0.9, "hit": false}
			"mira":
				if dx >= 0.0:
					o["done"] = true
					_aim = {"phase": "track", "t": 1.0, "lx": 0.0}
			"vecino":
				if not o.has("yelled") and dx >= -200.0:
					o["yelled"] = true
					_say(_grito(int(o["a"])), Vector2(o["x"], GROUND - _floor_at(o["x"]) - 62.0))
				if int(o["b"]) >= 0 and not o.has("thrown") and dx >= -150.0:
					o["thrown"] = true
					var base := GROUND - _floor_at(o["x"])
					_throws.append({"from": Vector2(_sx(o["x"]) + 8.0, base - 65.0),
						"to": Vector2(PX + 2.0, GROUND - fl - 25.0), "t": 0.0, "T": 0.85,
						"item": int(o["b"]), "done": false, "hit": false})
				if dx > 80.0:
					o["done"] = true


## Lo que pasa cuando se mete por debajo de algo.
func _react(o: Dictionary) -> void:
	var x0: float = o["x"]
	var base := GROUND - _floor_at(x0)
	match o["kind"]:
		"elevado":  # el tanque se mueve y le cae el agua del rebose encima
			for k in 14:
				_parts.append({"x": x0 + randf_range(0, 34), "y": base - 16.0 - randf() * 4.0, "vx": randf_range(-10, 10),
					"vy": randf_range(-20, 10), "life": 0.7, "col": Color(0.55, 0.75, 0.95, 0.9), "size": 1.0, "g": 300.0})
		"palomar":
			_sfx["aleteo"].play()
			for k in 7:
				_birds.append({"x": x0 + 8.0 + k * 5.0, "y": base - 26.0 - randf() * 8.0,
					"vx": randf_range(-50, 70), "vy": randf_range(-90, -50)})
			for k in 10:  # las plumas
				_parts.append({"x": x0 + randf_range(0, 44), "y": base - 14.0, "vx": randf_range(-12, 12), "vy": randf_range(-6, 4),
					"life": 1.6, "col": Color(0.85, 0.85, 0.9), "size": 1.0, "g": 18.0})
		"cumple":
			_say(_grito(5), Vector2(x0 + 18.0, base - 36.0))
		"placa":
			for k in 24:
				_parts.append({"x": x0 + randf_range(0, 96), "y": base - 14.0, "vx": randf_range(-4, 4), "vy": randf_range(0, 20),
					"life": 1.2, "col": Color(0.7, 0.66, 0.62, 0.8), "size": 1.0, "g": 40.0})
		"poste":
			_sfx["chispa"].play()
			for k in 12:
				_parts.append({"x": x0 - 12.0 + randf_range(-2, 4), "y": base - 22.0, "vx": randf_range(-40, 60),
					"vy": randf_range(-70, -10), "life": 0.5, "col": Color(1.0, 0.9, 0.4), "size": 1.0, "g": 260.0})


func _grito(who: int) -> String:
	var list: Array = GRITOS[who]
	var line: String = list[_grito_n[who] % list.size()]
	_grito_n[who] += 1
	return line


## El globo de lo que gritan: uno a la vez, al lado de la cabeza de quien grita (x en el mundo, y en
## pantalla): a la izquierda, de donde viene él; si ya no cabe, a la derecha. Nunca encima del aviso.
func _say(text: String, at: Vector2, lift := 0.0) -> void:
	_bubble_lift = lift
	_bubble.text = text
	var font: Font = FONT
	var w := minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, 132.0)
	var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w + 1.0, 8).y
	_bubble.custom_minimum_size = Vector2(w + 9.0, h + 6.0)
	_bubble.size = _bubble.custom_minimum_size
	_bubble_at = at
	_bubble_t = 2.6
	_bubble.visible = true


func _bubble_tick(delta: float) -> void:
	if _bubble_t <= 0.0:
		_bubble.visible = false
		return
	_bubble_t -= delta
	var right := Controls.right_edge()
	var sx := _sx(_bubble_at.x)
	_bubble.size = _bubble.custom_minimum_size
	var bw := _bubble.size.x
	var bx := sx - 14.0 - bw
	if bx < 4.0:
		bx = sx + 14.0
	_bubble.position = Vector2(clampf(bx, 4.0, right - bw - 4.0),
		clampf(_bubble_at.y + _bubble_lift - _bubble.size.y / 2.0, 50.0, 176.0 - _bubble.size.y))
	_bubble.modulate.a = clampf(_bubble_t / 0.3, 0.0, 1.0)


## Las balas: primero el aviso en el borde, después pasan. Alta: al piso. Baja: en el aire.
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
			var safe: bool = (_low() or _in_pass) if s["high"] else _air() > 7.0
			if not safe:
				_trip(22.0)
				continue  # (le dio: la bala no sigue)
		if now > -30.0 and now < 350.0:
			keep.append(s)
	_shots = keep


## La ráfaga del helicóptero: avisa (el de la puerta apunta), y los tiros barren el techo de un lado al
## otro. Hay que estar en el aire cuando pasan.
func _strafe_tick(delta: float) -> void:
	if _strafe.is_empty():
		return
	if _strafe["warn"] > 0.0:
		_strafe["warn"] -= delta
		return
	var before: float = _strafe["x"]
	var now: float = before + float(_strafe["dir"]) * float(_strafe["v"]) * delta
	_strafe["x"] = now
	if not _sfx["rafaga"].playing:
		_sfx["rafaga"].play()
	if randf() < 0.7:
		_debris(_x + now - PX)
	if not _strafe["hit"] and (before - PX) * (now - PX) <= 0.0:
		_strafe["hit"] = true
		if _air() < 6.0:
			_trip(24.0)
	if now < -24.0 or now > 344.0:
		_strafe = {}


## La mira: lo sigue un segundo, se queda quieta donde él va a estar, y ahí disparan. Tirarse lo adelanta.
func _aim_tick(delta: float) -> void:
	if _aim.is_empty():
		return
	_aim["t"] -= delta
	if _aim["phase"] == "track":
		if _aim["t"] <= 0.0:
			_aim["phase"] = "lock"
			_aim["t"] = 0.6
			_aim["lx"] = _x + _speed * 0.6
	elif _aim["t"] <= 0.0:
		_sfx["rafaga"].play()
		var lx: float = _aim["lx"]
		for k in 7:
			_debris(lx + randf_range(-13, 13))
		if absf(_x - lx) < 14.0 and not _in_pass:
			_trip(28.0)
		_aim = {}


## Lo que tiran desde las terrazas: vuela en arco hasta donde está su cabeza. Al piso, pasa por encima.
func _throws_tick(delta: float) -> void:
	var keep: Array = []
	for th in _throws:
		th["t"] += delta
		if not th["done"] and th["t"] >= th["T"]:
			th["done"] = true
			_sfx["ploc"].play()
			if not (_low() or _in_pass):
				th["hit"] = true
				_trip(16.0)
				if th["item"] == 1:
					_splat = 3.0  # el huevo se le queda en el pelo un rato
				for k in 6:
					_parts.append({"x": _x + randf_range(-3, 5), "y": GROUND - _y - 26.0, "vx": randf_range(-40, 40),
						"vy": randf_range(-60, -10), "life": 0.5, "col": [Color(0.3, 0.75, 0.4), Color(1, 0.85, 0.3),
						Color(0.7, 0.36, 0.24), Color(0.95, 0.92, 0.85)][th["item"]], "size": 1.0, "g": 260.0})
		if th["t"] < th["T"] + 0.7 and not th["hit"]:
			keep.append(th)
	_throws = keep


func _debris(wx: float) -> void:
	var y := GROUND - _floor_at(wx) - 1.0
	for k in 2:
		_parts.append({"x": wx + randf_range(-2, 2), "y": y, "vx": randf_range(-30, 30), "vy": randf_range(-90, -40),
			"life": 0.45, "col": Color(0.55, 0.42, 0.36) if stage == 1 else Color(0.5, 0.5, 0.55), "size": 1.0, "g": 320.0})
	_parts.append({"x": wx, "y": y - 2.0, "vx": 0.0, "vy": -8.0, "life": 0.4, "col": Color(1.0, 0.85, 0.5, 0.9),
		"size": 1.5, "g": 0.0, "grow": true})


func _particles(delta: float) -> void:
	for p in _parts:
		p["life"] -= delta
		p["vy"] += float(p["g"]) * delta
		p["x"] += float(p["vx"]) * delta
		p["y"] += float(p["vy"]) * delta
	_parts = _parts.filter(func(p): return p["life"] > 0.0)
	for b in _birds:
		b["vy"] -= 20.0 * delta
		b["x"] += float(b["vx"]) * delta
		b["y"] += float(b["vy"]) * delta
	_birds = _birds.filter(func(b): return b["y"] > -20.0)


func _trip(cost: float) -> void:
	_lead -= cost
	_stun = 0.55
	_slide = 0.0
	_crouch = false
	_vy = 0.0
	_y = _floor_at(_x)
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


## El helicóptero: siempre encima, un poco adelante. Se acomoda para disparar o para alumbrar.
func _heli_tick(delta: float) -> void:
	var target := Vector2(PX + 150.0 + sin(_t * 0.6) * 24.0, 52.0 + sin(_t * 2.1) * 2.0)  # (debajo del aviso)
	if _beam != "":
		target.x = _beam_x() + 24.0
	elif not _strafe.is_empty():
		target.x = clampf(float(_strafe["x"]) + 40.0 * float(_strafe["dir"]) * -1.0 + 30.0, 30.0, 300.0)
	elif not _aim.is_empty():
		target.x = PX + 90.0
	_heli = _heli.lerp(target, minf(1.0, delta * 1.8))


func _beam_x() -> float:
	var cx := _sx(_cover_x)
	if _beam == "warn":
		return cx + 220.0 * (_beam_t / 1.7)  # viene barriendo desde adelante
	return cx + sin(_t * 5.0) * 26.0


func _hints() -> void:
	var text := ""
	if _lift_wait:
		text = Controls.keys_in("¡LUKAS NO ALCANZA! E: alzarlo")
	elif _carry_note > 0.0:
		text = "(Con Lukas alzado, nada de tirarse)"
	elif _beam == "warn":
		text = "¡EL HELICOPTERO! Abajo, detrás del tanque"
	elif _beam == "on":
		text = "(quieto)" if _crouch else ""
	elif not _aim.is_empty():
		text = "¡LO TIENEN EN LA MIRA! Abajo: tirarse"
	elif not _strafe.is_empty() and not _strafe["hit"]:
		text = Controls.keys_in("¡DISPARAN DE ARRIBA! E: saltar")
	elif _incoming() >= 0:
		text = ITEMS[_incoming()] + " Abajo"
	elif stage == 2 and _x >= JUMP_FROM - 40.0 and _x <= JUMP_TO:
		text = Controls.keys_in("¡E! ¡AL RIO!")
	elif not _shots.is_empty() and not _shots[0]["hit"]:
		text = ("¡BALA ATRAS! " if _shots[0]["dir"] > 0.0 else "¡BALA AL FRENTE! ") \
			+ ("¡Abajo!" if _shots[0]["high"] else Controls.keys_in("¡E, salta!"))
	elif _in_pass and _slide <= 0.1:
		text = "(Abajo, apretado... no lo suelte)"
	else:
		for o in _obs:
			var ahead: float = o["x"] - _x
			var kind: String = o["kind"]
			if o["done"] or ahead < 0.0 or ahead > 110.0 or _seen.get(kind, 0) >= 2:
				continue
			if JUMPS.has(kind) or kind == "hueco":
				text = Controls.keys_in("E: saltar")
			elif kind == "calle":
				text = "(Esa calle es muy ancha para Lukas)"
			elif kind == "nivel" and float(o["a"]) > _floor_at(o["x"] - 1.0):
				text = Controls.keys_in("E: al techo de al lado")
			elif DUCK.has(kind):
				text = "Abajo: tirarse por debajo" if DUCK[kind][2] < 80 else "Abajo, y mantenga: es largo"
			if text != "":
				if ahead < 12.0 and not o.has("hinted"):
					o["hinted"] = true
					_seen[kind] = int(_seen.get(kind, 0)) + 1
				break
	_hint.text = text


func _incoming() -> int:
	for th in _throws:
		if not th["done"]:
			return th["item"]
	return -1


# ---------------------------------------------------------------- Dibujar

func _place() -> void:
	if _jumped_off:
		return
	_me.position = Vector2(PX, GROUND - 22.0 - _y)
	if _run:
		var anim := "walk"
		if _in_pass:
			anim = "flat"
		elif _stun > 0.0:
			anim = "hurt"
		elif _slide > 0.0:
			anim = "slide"
		elif _crouch:
			anim = "crouch"
		elif _lift_wait:
			anim = "idle"
		if _me.animation != anim:
			_me.play(anim)
		_me.speed_scale = 1.5
	if not _dog_busy:
		_dog.z_index = 0
		if _carry:  # en brazos, contra el pecho
			_dog.position = Vector2(PX + 3.0, GROUND - 22.0 - _y + 1.0)
			_dog.z_index = 1
			_dog.speed_scale = 0.0
		elif _lift_wait:  # en el borde, mirando la calle; mira para atrás
			_dog.position = Vector2(PX + 12.0, GROUND - 7.0 - _floor_at(_x) + (sin(_t * 9.0) if fmod(_t, 1.2) < 0.6 else 0.0))
			_dog.flip_h = fmod(_t, 1.6) < 1.0
			_dog.speed_scale = 0.0
		else:
			_dog.flip_h = true
			_dog.position = Vector2(PX - 24.0, GROUND - 7.0 - _floor_at(_x - 24.0) - maxf(0.0, _air()) * 0.7)
			_dog.speed_scale = 0.0 if (_crouch or not _run) else 1.6
	for i in _cops.size():
		var c: AnimatedSprite2D = _cops[i]
		var cx := PX - 46.0 - _lead * 0.9 - i * 18.0
		c.position = Vector2(cx, GROUND - 22.0 - _floor_at(_x + cx - PX))
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


const ROOF := Color(0.24, 0.16, 0.16)
## Las fachadas (tools/art/draw_fondos.py): ladrillo, o pañete pintado; cada techo, según su altura.
const FACHADAS := [preload("res://assets/prologue/techo_0.png"), preload("res://assets/prologue/techo_1.png")]
const ROOF_EDGE := Color(0.42, 0.3, 0.26)


func _draw_roofs() -> void:
	# Los techos: cada parte a su altura; donde cambia, se ve la pared del más alto.
	var left := _x - PX - 4.0
	var right := left + 332.0
	var cur := left
	var h := _floor_at(left)
	for l in _levels:
		if l[0] <= left:
			continue
		if l[0] >= right:
			break
		_slab(cur, l[0], h)
		var hi := maxf(h, l[1])
		var lo := minf(h, l[1])
		draw_rect(Rect2(_sx(l[0]) - 1.0, GROUND - hi, 3, hi - lo + 1.0), Color(0.34, 0.22, 0.2))
		cur = l[0]
		h = l[1]
	_slab(cur, right, h)
	# Las antenas y las ventanas de abajo, casa por casa.
	var first := int(floor((_x - PX) / 90.0))
	for k in range(first, first + 6):
		var bx := _sx(k * 90.0)
		var top := GROUND - _floor_at(k * 90.0)
		var hs := hash(k)
		draw_rect(Rect2(bx + 8, top + 8, 10, 8), Color(1.0, 0.8, 0.4, 0.7) if hs % 3 == 0 else Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(bx + 50, top + 14, 10, 8), Color(1.0, 0.8, 0.4, 0.7) if hs % 5 == 0 else Color(0.12, 0.1, 0.14))
		draw_rect(Rect2(bx, top, 1, 40), Color(0.16, 0.1, 0.12))
		if hs % 4 == 1:  # una antena
			var c := Color(0.3, 0.3, 0.34)
			draw_line(Vector2(bx + 34, top), Vector2(bx + 34, top - 26), c)
			draw_line(Vector2(bx + 28, top - 22), Vector2(bx + 40, top - 22), c)
			draw_line(Vector2(bx + 30, top - 17), Vector2(bx + 38, top - 17), c)
	for o in _obs:
		var sx := _sx(o["x"])
		if sx < -160.0 or sx > 420.0:
			continue
		var top := GROUND - _floor_at(o["x"])
		match o["kind"]:
			"vecino":
				_draw_terrace(o, sx, top)
			"hueco", "calle":
				var wdt := 46.0 if o["kind"] == "hueco" else 60.0
				draw_rect(Rect2(sx, top, wdt, 180 - top), Color(0.03, 0.03, 0.06))
				if o["kind"] == "calle":  # allá abajo, la calle: el poste prendido y un carro que pasa
					draw_rect(Rect2(sx + 6, 176, wdt - 12, 4), Color(0.12, 0.12, 0.16))
					draw_circle(Vector2(sx + 14, 168), 6.0, Color(1.0, 0.8, 0.4, 0.15))
					draw_rect(Rect2(sx + 13, 166, 3, 2), Color(1.0, 0.85, 0.5))
					var car := fposmod(_t * 50.0, wdt + 30.0) - 15.0
					draw_rect(Rect2(sx + car, 173, 10, 3), Color(0.5, 0.2, 0.2))
					draw_rect(Rect2(sx + car + 9, 174, 2, 1), Color(1, 0.95, 0.7))
				else:
					draw_rect(Rect2(sx + 20, 172, 3, 2), Color(1.0, 0.85, 0.5, 0.8))  # un farol, allá abajo
				draw_rect(Rect2(sx - 1, top, 2, 40), ROOF_EDGE)
				draw_rect(Rect2(sx + wdt - 1, top, 2, 40), ROOF_EDGE)
			"tanque":
				draw_rect(Rect2(sx - 13, top - 26, 26, 26), Color(0.2, 0.24, 0.3))
				draw_rect(Rect2(sx - 15, top - 28, 30, 3), Color(0.32, 0.36, 0.44))
				draw_rect(Rect2(sx - 9, top - 20, 3, 14), Color(0.28, 0.32, 0.4))
			_:
				_draw_thing(o, sx, top)


func _slab(wx0: float, wx1: float, h: float) -> void:
	if wx1 <= wx0:
		return
	var top := GROUND - h
	var tex: Texture2D = FACHADAS[int(h / 8.0) % 2]
	# Pegada al mundo (no a la pantalla): al correr, la pared pasa; no se desliza encima.
	draw_texture_rect_region(tex, Rect2(_sx(wx0), top, wx1 - wx0, 180 - top), Rect2(fposmod(wx0, 48.0), 0, wx1 - wx0, 180 - top))


## Lo de saltar y lo de pasar por debajo (la capa de atrás: lo de adelante va en _draw_fx).
func _draw_thing(o: Dictionary, sx: float, top: float) -> void:
	var kind: String = o["kind"]
	if JUMPS.has(kind) and kind != "cono":
		var tex: Texture2D = _tex["salta_" + kind]
		draw_texture(tex, Vector2(round(sx - tex.get_width() / 2.0), top - tex.get_height()))
	elif DUCK.has(kind):
		var tex: Texture2D = _tex[DUCK[kind][0] + "_atras"]
		var at := Vector2(round(sx - float(DUCK[kind][1])), top - tex.get_height())
		draw_texture(tex, at)
		match kind:
			"elevado":  # el rebose gotea
				var d := fmod(_t * 1.3, 1.0)
				draw_rect(Rect2(at + Vector2(39, 15 + d * 18.0), Vector2(1, 2)), Color(0.55, 0.75, 0.95, 1.0 - d))
			"cumple":  # las velas; si ya pasó por debajo, apagadas (las sopló sin querer)
				if not o.has("in"):
					for k in 3:
						if fmod(_t * 6.0 + k, 2.0) < 1.6:
							draw_rect(Rect2(at + Vector2(25 + k * 3, 20), Vector2(1, 1)), Color(1.0, 0.95, 0.6))
			"poste":  # el cable pelado echa chispas
				if fmod(_t * 1.4, 1.0) < 0.15:
					for k in 3:
						draw_rect(Rect2(at + Vector2(randf_range(-1, 5), randf_range(14, 20)), Vector2(1, 1)), Color(1, 0.9, 0.4))
	elif kind == "cono":
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 5, top), Vector2(sx + 5, top), Vector2(sx + 1, top - 14), Vector2(sx - 1, top - 14)]), Color(1.0, 0.5, 0.15))
		draw_rect(Rect2(sx - 3, top - 8, 6, 2), Color(0.95, 0.95, 0.95))


## La terraza de la casa de atrás: la pared, el vecino asomado y su baranda (más oscuro: está atrás).
func _draw_terrace(o: Dictionary, sx: float, top: float) -> void:
	var terr: int = o["c"]
	var wall: Color = [Color(0.36, 0.3, 0.26), Color(0.34, 0.2, 0.17)][terr]
	draw_rect(Rect2(sx - 22, top - 30, 44, 30), wall)
	draw_rect(Rect2(sx - 15, top - 23, 9, 9), Color(1.0, 0.78, 0.4, 0.55))  # la ventana, prendida
	draw_rect(Rect2(sx - 11, top - 23, 1, 9), wall)
	var who: int = o["a"]
	var frame := 1 if (int(o["b"]) >= 0 and not o.has("thrown")) else 0
	var bob := 0.0
	if o.has("yelled") and _bubble_t > 0.0 and absf(_bubble_at.x - o["x"]) < 1.0:
		bob = -1.0 if fmod(_t * 8.0, 1.0) < 0.5 else 0.0  # gritando: se le mueve todo
	draw_texture_rect_region(_tex["vecinos"], Rect2(sx - 12, top - 68 + bob, 24, 28), Rect2(frame * 24, who * 28, 24, 28),
		Color(0.85, 0.85, 0.9))
	draw_texture(_tex["terraza_%d" % terr], Vector2(sx - 20, top - 48), Color(0.8, 0.8, 0.86))


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
		if sx < -160.0 or sx > 420.0:
			continue
		_draw_thing(o, sx, GROUND)
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


## Encima de él: lo de adelante de lo que se pasa por debajo, el polvo, las palomas, lo que tiran, las
## balas, la ráfaga, la mira, el helicóptero y su luz, y el pico del globo.
func _draw_fx() -> void:
	for o in _obs:
		if o["done"] and _sx(o["x"]) < -160.0:
			continue
		if DUCK.has(o["kind"]):
			var sx := _sx(o["x"])
			if sx > -160.0 and sx < 420.0:
				var tex: Texture2D = _tex[DUCK[o["kind"]][0] + "_frente"]
				_fx.draw_texture(tex, Vector2(round(sx - float(DUCK[o["kind"]][1])), GROUND - _floor_at(o["x"]) - tex.get_height()))
	for p in _parts:
		var col: Color = p["col"]
		var size: float = p["size"]
		if p.get("grow", false):
			size += (0.5 - float(p["life"])) * 5.0
			col.a *= clampf(float(p["life"]) / 0.5, 0.0, 1.0)
		_fx.draw_rect(Rect2(Vector2(_sx(p["x"]), p["y"]) - Vector2(size, size) / 2.0, Vector2(size, size)), col)
	for b in _birds:
		var f := int(_t * 12.0) % 2
		_fx.draw_texture_rect_region(_tex["paloma"], Rect2(_sx(b["x"]), b["y"], 8, 6), Rect2(f * 8, 0, 8, 6), Color(1, 1, 1), false)
	if _splat > 0.0 and not _in_pass:  # el huevo
		var hp := _me.position + Vector2(-2, -12)
		_fx.draw_rect(Rect2(hp, Vector2(4, 2)), Color(0.98, 0.95, 0.85))
		_fx.draw_rect(Rect2(hp + Vector2(1, 0), Vector2(2, 1)), Color(1.0, 0.8, 0.2))
	for th in _throws:
		var u := clampf(float(th["t"]) / float(th["T"]), 0.0, 1.4)
		var from: Vector2 = th["from"]
		var to: Vector2 = th["to"]
		var p := from.lerp(to, u) + Vector2(0, -34.0 * 4.0 * u * (1.0 - u))
		if u > 1.0:  # pasó por encima: sigue y cae atrás
			p = to + Vector2(-90.0 * (u - 1.0) * 2.0, 60.0 * (u - 1.0))
		_fx.draw_set_transform(p, _t * 14.0, Vector2.ONE)
		_fx.draw_texture_rect_region(_tex["tiran"], Rect2(-4, -4, 8, 8), Rect2(int(th["item"]) * 8, 0, 8, 8))
		_fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in _shots:
		var y := GROUND - _floor_at(_x) - (31.0 if s["high"] else 5.0)
		var dir: float = s["dir"]
		if s["warn"] > 0.0:  # el aviso, en el borde por donde viene
			if fmod(_t * 10.0, 1.0) < 0.6:
				var ex := 5.0 if dir > 0.0 else 315.0
				_fx.draw_colored_polygon(PackedVector2Array([Vector2(ex - 4 * dir, y - 5), Vector2(ex + 5 * dir, y), Vector2(ex - 4 * dir, y + 5)]), Color(1.0, 0.3, 0.25))
		else:
			var x: float = s["x"]
			_fx.draw_line(Vector2(x - 26.0 * dir, y), Vector2(x - 8.0 * dir, y), Color(1.0, 0.9, 0.5, 0.35), 1.0)
			_fx.draw_line(Vector2(x - 8.0 * dir, y), Vector2(x, y), Color(1.0, 0.95, 0.6), 2.0)
	if _intro or stage == 0 or _jumped_off:
		return
	var gun := _heli + Vector2(-7, 3)
	if not _strafe.is_empty():
		if _strafe["warn"] > 0.0:  # el de la puerta apunta: la línea roja
			if fmod(_t * 8.0, 1.0) < 0.5:
				var aim_at := Vector2(float(_strafe["x"]) + 60.0 * -float(_strafe["dir"]), GROUND - _floor_at(_x))
				_fx.draw_line(gun, gun.lerp(aim_at, 0.5), Color(1.0, 0.2, 0.2, 0.5), 1.0)
		else:
			var ix: float = _strafe["x"]
			var iy := GROUND - _floor_at(_x + ix - PX)
			if fmod(_t * 20.0, 1.0) < 0.6:
				_fx.draw_line(gun, Vector2(ix, iy), Color(1.0, 0.92, 0.55, 0.8), 1.0)
				_fx.draw_circle(gun, 2.5, Color(1.0, 0.9, 0.5))
	if not _aim.is_empty():
		var ax := PX if _aim["phase"] == "track" else _sx(_aim["lx"])
		var ay := GROUND - _floor_at(_x) - 14.0
		var blink: bool = _aim["phase"] == "track" or fmod(_t * 12.0, 1.0) < 0.6
		if blink:
			var r := 10.0 if _aim["phase"] == "track" else 7.0
			var c := Color(1.0, 0.2, 0.2)
			for sgn in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var corner: Vector2 = Vector2(ax, ay) + sgn * r
				_fx.draw_line(corner, corner - Vector2(sgn.x * 4.0, 0), c, 1.0)
				_fx.draw_line(corner, corner - Vector2(0, sgn.y * 4.0), c, 1.0)
			_fx.draw_rect(Rect2(ax - 0.5, ay - 0.5, 1, 1), c)
		if _aim["phase"] == "lock":
			_fx.draw_line(gun, Vector2(ax, ay), Color(1.0, 0.2, 0.2, 0.35), 1.0)
	if _beam != "":
		_cone(_beam_x(), Color(1.0, 1.0, 0.85, 0.12 if _beam == "warn" else 0.3))
	var hf := int(_t * 20.0) % 2
	_fx.draw_texture_rect_region(_tex["heli"], Rect2(round(_heli.x - 36.0), round(_heli.y - 15.0), 72, 30), Rect2(hf * 72, 0, 72, 30))
	if _bubble.visible:  # el pico del globo, hacia la boca de quien grita
		var head := Vector2(_sx(_bubble_at.x), _bubble_at.y)
		var left := _bubble.position.x + _bubble.size.x < head.x
		var ex := _bubble.position.x + (_bubble.size.x - 1.0 if left else 1.0)
		var ey := clampf(head.y, _bubble.position.y + 4.0, _bubble.position.y + _bubble.size.y - 4.0)
		var tip := head + Vector2(-6.0 if left else 6.0, 0)
		_fx.draw_colored_polygon(PackedVector2Array([Vector2(ex, ey - 3), Vector2(ex, ey + 3), tip]),
			Color(0.97, 0.95, 0.9, _bubble.modulate.a))


func _cone(cx: float, col: Color) -> void:
	var src := _heli + Vector2(-24, 8)  # el reflector
	_fx.draw_colored_polygon(PackedVector2Array([src - Vector2(3, 0), src + Vector2(3, 0), Vector2(cx + 46, GROUND + 2), Vector2(cx - 46, GROUND + 2)]), col)
	_fx.draw_rect(Rect2(cx - 46, GROUND - _floor_at(_x), 92, 3), Color(col.r, col.g, col.b, col.a * 1.5))
