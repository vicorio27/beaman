extends Node2D
## TORNEO DE LUCHA LIBRE (la "WrestleMania" de domingo, en el coliseo del barrio). Un sueño por pelea
## (fight = 0..3, escenas Lucha1..4): empieza con un "anteriormente", la entrada al ring con el nombre en
## la pantalla gigante, y termina con un gancho hacia el próximo domingo. Él tiene quince años.
## Lukas es el árbitro: camiseta a rayas, cuenta con la pata. Dos comentaristas, con humor negro.
##   1. RAUL, "El Millonario" (tipo Big Show): gigante, lento, chokeslam. No se deja levantar hasta
##      que se cansa (menos de la mitad de vida).
##   2. ALVARITO, "El Corazón" (tipo Eddie Guerrero): rápido, tramposo con cariño. Se hace el lesionado
##      y, si uno se le acerca, lo sorprende con un pin. Si lo tumba, lo ayuda a levantarse.
##   3. EL PECAS, "El Lambón": Mauricio está en el delantal del ring y le agarra el pie si se acerca a
##      las cuerdas.
##   4. MAURICIO, "El Enterrador de Domingos" (tipo Undertaker): se apagan las luces, suena el gong.
##      La primera vez que lo tumban de verdad, SE SIENTA. Fase 2: sobrio, sin chaleco, Tombstone.
## Controles: flechas = moverse. E = golpe. X cerca = agarre (machacar E; con las flechas se elige la
## llave: ← suplex, → a las cuerdas, ↑ DDT, ↓ slam; con la barra llena, ↑ = EL PORTAZO). X lejos =
## correr a las cuerdas (E en carrera: clothesline). X sobre el rival caído = cuenta. En la esquina,
## con el rival en el piso: ↑ sube, E salta. F = provocar al público (llena la barra).
## Gana el que cuenta tres. Si pierde: revancha o despertarse.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NIGHT := "res://scenes/world/Night.tscn"
const RING_L := 40.0
const RING_R := 280.0
const FLOOR_T := 118.0
const FLOOR_B := 152.0
const REACH := 22.0

const OPPONENTS := [
	{"id": "raul", "name": "RAUL", "ring": "EL MILLONARIO", "sheet": "enemy_boss", "scale": 1.45,
		"hp": 130.0, "speed": 30.0, "power": 1.35, "grip": 1.5, "signature": "chokeslam", "lift_at": 0.5,
		"taunts": ["RAUL: —¡Yo pago la próxima ronda! ¡Y la entrada de todos! ¡Menos la suya!",
			"RAUL: —¡Esta cadena es de dieciocho kilates! ¡La suya es de lata! ¡Bueno, usted no tiene cadena!",
			"RAUL: —¡Tengo tres carros y una finca en Melgar! ¡Y un hígado de segunda mano!"]},
	{"id": "alvarito", "name": "ALVARITO", "ring": "EL CORAZON", "sheet": "enemy_thug", "scale": 1.0,
		"hp": 90.0, "speed": 62.0, "power": 0.85, "grip": 0.9, "signature": "frogsplash", "trick": true,
		"taunts": ["ALVARITO: —¡Perdóneme, mijo! ¡Es el show! ¡Su mamá me perdonaría! ¡Bueno, no!",
			"ALVARITO: —Su papá hablaba de ustedes. Borracho, pero hablaba. Sobrio no hablaba de nada.",
			"ALVARITO: —¡Usted tenía tres años y le decía \"tío Alvito\"! ¡Tome, tío Alvito!"]},
	{"id": "pecas", "name": "EL PECAS", "ring": "EL LAMBON", "sheet": "enemy_punk", "scale": 1.05,
		"hp": 105.0, "speed": 46.0, "power": 1.0, "grip": 1.0, "signature": "ddt", "helper": true,
		"taunts": ["EL PECAS: —¡Lo que usted diga, don Mauricio! ¡Lo que diga!",
			"EL PECAS: —Los domingos salíamos en moto. Él y yo. A Melgar. Él pagaba la gasolina. Yo ponía la compañía.",
			"EL PECAS: —¡Don Mauricio me enseñó a manejar! ¡A usted no le enseñó nada! ¡Eso es preferencia!"]},
	{"id": "mauricio", "name": "MAURICIO", "ring": "EL ENTERRADOR DE DOMINGOS", "sheet": "enemy_boss", "scale": 1.15,
		"hp": 140.0, "speed": 38.0, "power": 1.2, "grip": 1.25, "signature": "tombstone", "situp": true,
		"taunts": ["MAURICIO: —Yo los veía todos los domingos. Pregúntele a cualquiera. Pregúntele al Pecas.",
			"MAURICIO: —Su mamá me alejó de ustedes. Ella cambió la chapa. Dos veces.",
			"MAURICIO: —Le mandaba plata. Todos los meses. Por Efecty. Guarde los recibos, le dije."],
		"taunts2": ["MAURICIO: —Me fui porque no sabía ser papá. Y no aprendí. No hay curso. Yo busqué. Mentira, no busqué.",
			"MAURICIO: —Tomaba para no pensar en ustedes. Y funcionaba. Eso es lo peor. Que funcionaba."]},
]
## Lukas, el árbitro.
const REF_TEX := {
	"quieto": preload("res://assets/dreams/lukas_arbitro.png"),
	"cuenta": preload("res://assets/dreams/lukas_arbitro_cuenta.png"),
	"cartel": preload("res://assets/dreams/lukas_arbitro_cartel.png"),
}
## Lo que dicen los comentaristas al sonar la campana: el truco de cada rival (y él lo muestra).
const GIMMICK := [
	"",
	"LA MONA: —Dato: Alvarito se ha hecho el lesionado en catorce de sus veinte peleas. Ganó trece. No se le acerquen.",
	"DON TITO: —¡Y en el delantal, señoras y señores, el papá! ¡Si el pelado se arrima a las cuerdas, le agarra el pie! ¡Eso no es trampa, es crianza!",
	"LA MONA: —El Enterrador no se queda en la lona. Se sienta. Hay que tumbarlo, esperar que se siente, y tumbarlo otra vez. Como a una deuda.",
]
const RECAP := {
	1: [["", "ANTERIORMENTE EN RAW DE DOMINGO..."], ["", "El Pelado tumbó a Raúl, El Millonario. Mauricio lo miró desde la tribuna. Una vez. Tres segundos. Él los contó."],
		["", "Otra vez el coliseo. Otra vez el olor a aguardiente Néctar y a crispetas de las que se pegan en las muelas."]],
	2: [["", "ANTERIORMENTE EN RAW DE DOMINGO..."], ["", "Alvarito perdió limpio. Y le dijo algo que nadie le había dicho: que el papá los quería. A su manera. Una manera con muchas cervezas."],
		["", "El Pecas lo espera con una chaqueta de cuero igualita a la de Mauricio. Talla más grande. Le queda grande. Todo lo de Mauricio le queda grande."]],
	3: [["", "ANTERIORMENTE EN RAW DE DOMINGO..."], ["", "Raúl. Alvarito. El Pecas. Los tres contaron las luces del techo mientras Lukas contaba hasta tres."],
		["", "Queda uno. Quince años esperando este domingo. Hoy se cobra."]],
}
const BEFORE := [
	[["", "Domingo. Coliseo del barrio. LUCHA LIBRE: \"RAW DE DOMINGO\". Él tiene quince años y unas mallas prestadas por un primo que nunca las devolvió a nadie."],
		["DON TITO", "—¡Buenas noches, coliseo! ¡Transmitiendo para todo el barrio, con el patrocinio de Colchones El Descanso: porque usted se lo merece, aunque no lo pague!"],
		["LA MONA", "—Tito, son las diez de la mañana."],
		["DON TITO", "—¡Buenas noches igual, Mona! ¡En la lucha libre siempre es de noche!"],
		["", "En primera fila, con chaleco de motociclista y una cerveza: Mauricio. Hace un año que se fue."],
		["MAURICIO", "—¡Ese es mi hijo! ¡Lo veo todos los domingos!"],
		["", "E: golpe. X cerca: agarre (machacá E y elegí la llave con las flechas). X lejos: correr a las cuerdas."],
		["", "X sobre el caído: cuenta. En la esquina, con él en el piso: arriba sube, E salta. F: provocar al público."],
		["", "El árbitro es Lukas. Camiseta a rayas. Corbatín. Pito. Cuenta con la pata. No tiene sentido. Es perfecto."],
		["LA MONA", "—El árbitro es un beagle, Tito."],
		["DON TITO", "—¡Y el más honesto que ha tenido este coliseo, Mona! ¡No acepta sobornos! ¡Bueno, acepta salchichas!"]],
	[["MAURICIO", "—Suerte de principiante. Raúl ya estaba prendido. Raúl siempre está prendido. Es su estado natural."],
		["ALVARITO", "—Hola, mijo. Usted no se acuerda de mí. Yo lo cargué cuando nació. En la clínica. Usted me orinó la camisa. La guardé."],
		["ALVARITO", "—Hoy lo voy a cargar otra vez. Para un suplex. Pero con cariño."],
		["EL PELADO", "—No me acuerdo de usted."],
		["ALVARITO", "—Nadie se acuerda de mí, mijo. Es mi encanto."]],
	[["EL PECAS", "—¡A donde vaya don Mauricio, voy yo! ¡En moto, a pie, al ring! ¡Al baño no, pero lo espero afuera!"],
		["", "Mauricio se para en el delantal del ring, del lado del Pecas. Ese no es su lugar. Nunca supo cuál era su lugar."],
		["DON TITO", "—¡El papá en la esquina del rival, Mona! ¿Ha visto algo así?"],
		["LA MONA", "—Todos los días, Tito. Se llama divorcio."]],
	[["", "Se apagan las luces del coliseo."], ["", "GONG."], ["", "Humo. Pasos lentos. Una moto suena en algún lado, aunque no hay moto."],
		["DON TITO", "—¡Señoras y señores! ¡El hombre que se fue por cigarrillos en el 2009 y volvió con un chaleco! ¡EL ENTERRADOR DE DOMINGOS!"],
		["MAURICIO", "—Bueno, mijo. Aquí estamos. Como los domingos."], ["EL PELADO", "—Nunca estuvimos así. Ni un domingo."],
		["MAURICIO", "—Una vez fuimos a Melgar."], ["EL PELADO", "—Ese fue el Pecas, pa."]],
]
const AFTER := [
	[["RAUL", "—Uy... el pelado. Ya me bajó la borrachera. Y eso me cuesta plata. Una borrachera mía vale como cien mil."],
		["MAURICIO", "—Raúl ya está viejo. No cuenta."]],
	[["ALVARITO", "—Me ganó limpio. Así me gusta. Bueno, no me gusta. Pero me gusta que haya sido usted."],
		["ALVARITO", "—Mijo... su papá los quería. A su manera. Una manera muy mala, pero los quería."],
		["EL PELADO", "—Gracias, Alvarito. Usted sí vino a verme. Hoy."], ["ALVARITO", "—Yo vine por la cerveza gratis, mijo. Pero me quedé por usted."]],
	[["EL PECAS", "—... Usted pega como él."], ["EL PELADO", "—No. Yo pego como yo. Él pega como se va."],
		["EL PECAS", "—... Él me prestó la chaqueta. Dijo que me quedaba mejor que a usted."], ["EL PELADO", "—Nunca me la ofreció."]],
]
const TEASE := [
	[["", "Mauricio levanta la cerveza hacia el ring. Es la primera vez que lo mira en quince años."],
		["MAURICIO", "—El próximo domingo, Alvarito. Si es que vuelve."], ["", "Va a volver."],
		["DON TITO", "—¡No se lo pierdan! ¡Raw de Domingo vuelve con el patrocinio de Colchones El Descanso!"], ["LA MONA", "—Ya cerró Colchones El Descanso, Tito."],
		["DON TITO", "—¡Con el patrocinio de la memoria de Colchones El Descanso!"]],
	[["ALVARITO", "—Mijo... el Pecas sabe cosas de su papá. De los domingos en la moto."],
		["ALVARITO", "—Pregúntele. Con una llave puesta: así sí contesta. El Pecas solo es sincero con dolor. Como todos."]],
	[["", "Mauricio se quita el chaleco. Se sube al delantal. Lo mira por entre las cuerdas."],
		["MAURICIO", "—Ahora sí, mijo. Usted y yo. El próximo domingo. Cuando se apaguen las luces."],
		["", "Quince años esperando un domingo. Puede esperar uno más."], ["", "Uno solo."]],
]
## Los comentaristas: humor negro de transmisión.
const CALLS := {
	"hit": ["DON TITO: —¡QUÉ GOLPE, SEÑORAS Y SEÑORES! ¡Ese le dolió hasta a la pensión alimenticia!",
		"LA MONA: —Golpe número doce. Once en la cara. Uno en el orgullo.",
		"DON TITO: —¡Esto no se veía desde el Santo contra Blue Demon en el 72! ¡Yo estuve ahí, Mona! ¡En la tele de un vecino!"],
	"suplex": ["DON TITO: —¡SUPLEX! ¡Lo dobló como a un recibo de la luz que uno no quiere abrir!", "LA MONA: —Eso no lo cubre la EPS. Nada lo cubre la EPS."],
	"slam": ["DON TITO: —¡Contra la lona! ¡La lona tampoco eligió estar aquí, Mona!", "LA MONA: —La lona es del 98, Tito. Ha visto peores."],
	"ddt": ["LA MONA: —DDT. De cabeza. Como entran todos al gota a gota: con fe y sin ver el piso."],
	"clothesline": ["DON TITO: —¡CLOTHESLINE! ¡Le borró los domingos! ¡Todos! ¡Hasta el de Ramos!"],
	"splash": ["LA MONA: —Tercera cuerda. Dos metros diez. El pelado no le tiene miedo a nada. Estadísticamente, debería."],
	"portazo": ["DON TITO: —¡EL PORTAZO! ¡Así suena una puerta cuando alguien se va por cigarrillos y no vuelve!"],
	"chokeslam": ["LA MONA: —Chokeslam. El Millonario lo levantó del cuello. Como levanta todo: sin pagar."],
	"frogsplash": ["DON TITO: —¡FROG SPLASH! ¡Alvarito vuela con todo el corazón y todo el aguardiente que se tomó en el intermedio!"],
	"tombstone": ["LA MONA: —Tombstone. Lo plantó de cabeza. El Pecas está grabando con el celular. Para mostrarle a nadie."],
	"kickout": ["DON TITO: —¡Se levantó en dos! ¡Este pelado no sabe rendirse! ¡Nadie le enseñó, Mona! ¡NADIE!", "LA MONA: —Se levantó en dos. Tito llora."],
	"situp": ["LA MONA: —Se sentó. Quince años sin sentarse a la mesa y ahora se sienta en la lona."],
	"trip": ["DON TITO: —¡Mauricio le agarró el pie desde afuera! ¡Eso es trampa! ¡Eso es familia!", "LA MONA: —Primera vez que le agarra algo al hijo, Tito."],
}

## Un luchador (objeto, para que los tweens puedan animar pos, lift y rot).
class W:
	var node: AnimatedSprite2D
	var pos := Vector2.ZERO
	var face := 1
	var state := "idle"
	var t := 0.0
	var lift := 0.0
	var rot := 0.0
	var cd := 1.0
	var run := 0
	var hp := 100.0
	var max := 100.0


@export var fight := 0

var o: Dictionary = {}
var me: W
var him: W
var state := "intro"           # intro, fight, busy, pin, end
var _special := 0.0
var _grapple_t := 0.0
var _grip_me := 0.0
var _grip_him := 0.0
var _choice := ""
var _pin_count := 0
var _pin_t := 0.0
var _pin_by_me := false
var _kick := 0.0
var _call_cd := 0.0
var _taunt_cd := 6.0
var _trip_cd := 6.0
var _phase2 := false
var _dark := 0.0
var _shake := 0.0
var _result := ""
var _t := 0.0
var _ref: Sprite2D
var _ref_count: Label
var _top: Label
var _call: Label
var _center: Label
var _sfx := {}
var _lights := 1.0
var _top_r: Label
var _sign: Label
## Tutorial (primera pelea): qué hizo el jugador.
var _tutorial := false
var _did := {}


# ---------------------------------------------------------------- Armado

func _ready() -> void:
	o = OPPONENTS[fight]
	me = _wrestler("res://assets/prologue/player.png", SideFrames.PLAYER, 1.0, Color(1, 1, 1), Vector2(90, 136), 1)
	me.hp = 100.0
	me.max = 100.0
	# Cada uno con su muñeco (tools/art/draw_luchadores.py); "sheet" es la hoja de la que sale (la tabla de cuadros).
	him = _wrestler("res://assets/dreams/luchador_%s.png" % o["id"], SideFrames.BOSS if o["sheet"] == "enemy_boss" else SideFrames.ENEMY,
		o["scale"], Color(1, 1, 1), Vector2(230, 136), -1)
	him.hp = o["hp"]
	him.max = o["hp"]
	_ref = Sprite2D.new()
	_ref.texture = REF_TEX["quieto"]
	_ref.offset = Vector2(0, -16)
	_ref.position = Vector2(160, 150)
	add_child(_ref)
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_top = _label(ui, Vector2(4, 2), 8)
	_top_r = _label(ui, Vector2(4, 2), 8)
	_top_r.size = Vector2(312, 10)
	_top_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sign = _label(ui, Vector2(0, 46), 8)
	_sign.size = Vector2(320, 30)
	_sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sign.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sign.add_theme_color_override("font_color", Color(0.75, 1.0, 0.75))
	_call = _label(ui, Vector2(4, 160), 8)  # abajo, sobre el delantal: no tapa el cartel ni la pantalla
	_call.size = Vector2(Controls.right_edge() - 8, 20)
	_call.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_call.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
	_center = _label(ui, Vector2(0, 70), 16)
	_center.size = Vector2(320, 20)
	_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ref_count = _label(self, Vector2(150, 118), 16)
	for n in ["hit-1", "hit-2", "miss", "grunt"]:
		var pl := AudioStreamPlayer.new()
		pl.stream = load("res://assets/audio/%s.wav" % n)
		pl.volume_db = -6.0
		add_child(pl)
		_sfx[n] = pl
	MusicDirector.force("")
	_show()


## Mauricio con o sin el chaleco (fase 2: "Ya no más chaleco. Ya no más trago"). Ver draw_luchadores.py.
func _vest(on: bool) -> void:
	var anim := him.node.animation
	him.node.sprite_frames = SideFrames.build(load("res://assets/dreams/luchador_mauricio%s.png" % ("" if on else "2")), SideFrames.BOSS)
	him.node.play(anim)


func _wrestler(sheet: String, table: Dictionary, sc: float, tint: Color, at: Vector2, face: int) -> W:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SideFrames.build(load(sheet), table)
	s.scale = Vector2(sc, sc)
	s.modulate = tint
	s.offset = Vector2(0, -22)
	add_child(s)
	s.play("idle")
	var w := W.new()
	w.node = s
	w.pos = at
	w.face = face
	return w


func _label(parent: Node, pos: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.05))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	l.z_index = 50
	parent.add_child(l)
	return l


# ---------------------------------------------------------------- El show

func _show() -> void:
	await get_tree().create_timer(0.6).timeout
	var rush := FinalRush.is_step("lucha")
	if rush:
		# Revancha: Mauricio llega sobrio, sin chaleco (fase 2 desde el principio), y el Pecas en el delantal.
		o = o.duplicate()
		o["helper"] = true
		await Dialogue.talk([["", "El coliseo, vacío. Solo él, Mauricio en el ring y el Pecas en el delantal. Ni Don Tito vino. Don Tito tiene control de la próstata los jueves."],
			["MAURICIO", "—Esta vez sin trago, mijo. Así es más justo. Para usted, no para mí."]])
	elif RECAP.has(fight):
		await Dialogue.talk(RECAP[fight])
	if o["id"] == "mauricio" and not rush:
		_lights = 0.0
	if not rush:
		await Dialogue.talk(BEFORE[fight])
	await _entrance()
	if fight == 0 and not GameState.flags.get("lucha_tutorial", false):
		await _tutorial_run()
		if not is_inside_tree():
			return  # se salió del sueño durante el tutorial
		GameState.flags["lucha_tutorial"] = true
	while true:
		if not is_inside_tree():
			return
		_reset()
		if rush:
			_phase2 = true
			_vest(false)
		state = "fight"
		MusicDirector.force("boxeo")
		_center.text = "¡SUENA LA CAMPANA!"
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
		_center.text = ""
		_showcase()
		while _result == "":
			if not is_inside_tree():
				return
			await get_tree().process_frame
		if _result == "win":
			break
		if rush:
			await Dialogue.talk([["", "Lukas cuenta tres. En la revancha no hay despertarse. Otra vez."]])
			continue
		var i := await Dialogue.talk([["", "Uno. Dos. Tres. Lukas cuenta con la pata, con cara de pena. El coliseo da vueltas."],
			["DON TITO", "—¡Y se acabó! ¡Se acabó, Mona!"], ["LA MONA", "—Por hoy, Tito. Los domingos vuelven. Para bien y para mal."]],
			["Revancha", "Despertarse"])
		if i == 1:
			_wake(false)
			return
	MusicDirector.force("")
	if rush:
		await Dialogue.talk([["MAURICIO", "—... Bien, mijo. Bien."], ["", "Por primera vez, lo dice sin trago."]])
		FinalRush.next()
		return
	if fight < AFTER.size():
		await Dialogue.talk(AFTER[fight])
	if fight < TEASE.size():
		await Dialogue.talk(TEASE[fight] + [["", "CONTINUARÁ EL PRÓXIMO DOMINGO."]])
		_wake(true)
		return
	await _final()


## La primera pelea enseña: Lukas levanta un cartel con cada cosa y espera a que el pelado la haga.
## Después Raúl muestra lo suyo (no se deja levantar; chokeslam) y hay que levantarse de su cuenta.
func _tutorial_run() -> void:
	_tutorial = true
	_reset()
	state = "fight"
	MusicDirector.force("boxeo")
	_ref.texture = REF_TEX["cartel"]
	_ref.position = Vector2(160, 112)
	var steps := [
		["hit", "LUKAS LEVANTA UN CARTEL:\nE = GOLPE. Pegale a Raúl."],
		["taunt", "LUKAS LEVANTA OTRO CARTEL:\nF = PROVOCAR AL PÚBLICO. Llena la barra del ESPECIAL."],
		["clothesline", "X LEJOS DE RAÚL = CORRER A LAS CUERDAS.\nAl volver, E = CLOTHESLINE."],
		["llave", "X CERCA = AGARRE. Machacá E.\nCon las flechas elegís: ← SUPLEX  → CUERDAS  ↑ DDT  ↓ SLAM."],
		["pin", "CON RAÚL EN EL PISO: X ENCIMA = LA CUENTA.\n(Lukas cuenta. Raúl todavía se levanta.)"],
		["splash", "ÉL EN EL PISO, VOS EN LA ESQUINA: ↑ SUBE, E SALTA.\n(Si no hay nadie abajo, duele.)"],
	]
	for st in steps:
		_did.erase(st[0])
		_sign.text = st[1]
		var tries := 0.0
		while not _did.get(st[0], false):
			if not is_inside_tree():
				return
			await get_tree().process_frame
			tries += get_process_delta_time()
			# Que el paso se pueda hacer: Raúl se tumba solo para la cuenta y la esquina.
			if st[0] in ["pin", "splash"] and him.state != "down" and state == "fight":
				him.state = "down"
				him.t = 99.0
				him.node.play("fall")
			if tries > 45.0:
				break
		_sign.text = "¡BIEN!"
		_say_call(["DON TITO: —¡El pelado aprende rápido! ¡Como aprenden los que no tienen a quién preguntarle, Mona!",
			"LA MONA: —¡Eso! ¡Lukas está orgulloso! Bueno, Lukas siempre está orgulloso."].pick_random(), true)
		await get_tree().create_timer(1.0).timeout
		if him.state == "down":
			him.t = 0.3
	# Ahora le toca a Raúl mostrar lo suyo.
	_sign.text = "LUKAS: ¡AHORA MUESTRA LO SUYO EL MILLONARIO!"
	await get_tree().create_timer(1.2).timeout
	for w in [me, him]:
		w.state = "idle"
		w.node.play("idle")
	him.pos = me.pos + Vector2(18 * me.face, 0)
	_sign.text = "RAÚL NO SE DEJA LEVANTAR HASTA QUE SE CANSA (MENOS DE LA MITAD DE VIDA)."
	_say_call("DON TITO: —¡Nadie levanta a El Millonario! ¡Ciento cuarenta kilos, Mona! ¡Ciento treinta de plata y diez de carácter!", true)
	await get_tree().create_timer(2.4).timeout
	_sign.text = "Y SU LLAVE: EL CHOKESLAM."
	await _perform(him, me, "chokeslam")
	_did.erase("kickout")
	_sign.text = "TE ESTÁ CONTANDO. ¡MACHACÁ E PARA LEVANTARTE!"
	_start_pin(false)
	while not _did.get("kickout", false):
		if not is_inside_tree():
			return
		await get_tree().process_frame
	_sign.text = "LUKAS GUARDA LOS CARTELES. ¡AHORA ES EN SERIO!"
	await get_tree().create_timer(1.8).timeout
	_sign.text = ""
	_ref.texture = REF_TEX["quieto"]
	_ref.position = Vector2(160, 150)
	_tutorial = false
	state = "intro"


## Al sonar la campana: el comentarista presenta el truco del rival, y él lo muestra enseguida.
func _showcase() -> void:
	if fight > 0 and fight < GIMMICK.size():
		_say_call(GIMMICK[fight], true)
	await get_tree().create_timer(1.4).timeout
	if state != "fight":
		return
	match o["id"]:
		"alvarito":
			him.state = "fake"
			him.node.play("fall")
			_fake()
		"pecas":
			_trip_cd = 0.0
		"mauricio":
			if _near(me, him, 60):
				await _perform(him, me, "tombstone")
			else:
				him.cd = 0.0


## La entrada: el nombre en la pantalla gigante. Mauricio: luces apagadas y gong.
func _entrance() -> void:
	_center.text = o["ring"]
	if o["id"] == "mauricio":
		_shake = 0.6
		_sfx["grunt"].pitch_scale = 0.4
		_sfx["grunt"].play()
		var tw := create_tween()
		tw.tween_property(self, "_lights", 0.35, 2.0)
		await tw.finished
	await get_tree().create_timer(1.6).timeout
	_center.text = ""


func _reset() -> void:
	_result = ""
	me.hp = me.max
	him.hp = him.max
	me.pos = Vector2(90, 136)
	him.pos = Vector2(230, 136)
	for w in [me, him]:
		w.state = "idle"
		w.lift = 0.0
		w.rot = 0.0
		w.t = 0.0
	_special = 0.0
	_phase2 = false
	if o["id"] == "mauricio":
		_vest(true)


# ---------------------------------------------------------------- Bucle

## En el celular, los carteles que dicen "E" / "F" dicen el botón en pantalla.
var _shown_keys := {}
func _touch_keys() -> void:
	if not Controls.touch():
		return
	for l in [_sign, _center, _call]:
		if l and l.text != _shown_keys.get(l, ""):
			l.text = Controls.keys_in(l.text)
			_shown_keys[l] = l.text


func _process(delta: float) -> void:
	_touch_keys()
	_t += delta
	_shake = maxf(0.0, _shake - delta * 2.0)
	_call_cd -= delta
	if state == "fight":
		_player(delta)
		_ai(delta)
		_timers(delta)
		_helper(delta)
	elif state == "grapple":
		_grapple(delta)
	elif state == "pin":
		_pin(delta)
	_place(me)
	_place(him)
	_hud()
	queue_redraw()


func _timers(delta: float) -> void:
	for w in [me, him]:
		w.cd -= delta
		if w.state in ["hurt", "down", "punch"]:
			w.t -= delta
			if w.t <= 0.0:
				if w.state == "down":
					w.node.play("idle")
				w.state = "idle"


func _place(w: W) -> void:
	var s: AnimatedSprite2D = w.node
	var shake := Vector2(randf_range(-2, 2), 0) * _shake
	s.position = w.pos + Vector2(0, -w.lift) + shake
	s.rotation = w.rot
	s.flip_h = w.face < 0
	s.z_index = int(w.pos.y)
	if w.state == "down" and w.lift == 0.0:
		s.rotation = 0.0  # la animación de caída ya lo muestra acostado
		s.position.y += 2


func _player(delta: float) -> void:
	var st: String = me.state
	if st == "climb":
		if Input.is_action_just_pressed("interact"):
			_splash()
		return
	if st == "run":
		me.pos.x += 150.0 * delta * me.face
		if me.pos.x >= RING_R or me.pos.x <= RING_L:
			me.face = -me.face
			me.run += 1
			if me.run > 2:
				_stop(me)
		if Input.is_action_just_pressed("interact") and _near(me, him, REACH + 6) and him.state in ["idle", "walk", "punch"]:
			_stop(me)
			await _perform(me, him, "clothesline")
		elif _near(me, him, 12) and him.state in ["idle", "walk"]:
			_stop(me)
			_hit(him, 6.0, me)
		return
	if st != "idle" and st != "walk":
		return
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		v.x -= 1
	if Input.is_action_pressed("move_right"):
		v.x += 1
	if Input.is_action_pressed("move_up"):
		v.y -= 0.6
	if Input.is_action_pressed("move_down"):
		v.y += 0.6
	# En la esquina con el rival en el piso: subir.
	if Input.is_action_just_pressed("move_up") and him.state == "down" and _at_corner(me):
		me.state = "climb"
		me.lift = 26.0
		me.node.play("crouch")
		_say_call("LA MONA: —Se sube a la tercera cuerda. Alguien llame a la mamá. Ah, no. La mamá vive en Ibagué.")
		return
	if v != Vector2.ZERO:
		me.pos += v.normalized() * 70.0 * delta
		_clamp(me)
		if v.x != 0:
			me.face = 1 if v.x > 0 else -1
		me.state = "walk"
		if me.node.animation != "walk":
			me.node.play("walk")
	else:
		me.state = "idle"
		if me.node.animation != "idle":
			me.node.play("idle")
	if Input.is_action_just_pressed("interact"):
		if him.state == "down" and _near(me, him, 30):
			_elbow_drop()  # E con él en el piso: codazo (antes: golpe al aire)
		else:
			if _near(me, him, REACH + 4) and signf(him.pos.x - me.pos.x) != me.face:
				me.face = -me.face  # lo tiene atrás: se da vuelta y le pega
			_strike(me, him, 4.0)
	elif Input.is_action_just_pressed("drop"):
		if him.state == "down" and _near(me, him, 30):
			_start_pin(true)
		elif _near(me, him, REACH) and him.state in ["idle", "walk", "punch"]:
			_start_grapple(true)
		else:
			me.state = "run"
			me.run = 0
			me.node.play("walk")
	elif Input.is_action_just_pressed("sniff") and me.cd <= 0.0:
		me.cd = 2.5
		_special = minf(100.0, _special + 18.0)
		_did["taunt"] = true
		_say_call(["DON TITO: —¡Provoca al público! ¡El público lo abuchea! ¡Le encanta! ¡Como a mí mi exesposa!",
			"LA MONA: —¡El pelado saluda a la tribuna! ¡Nadie le devuelve el saludo! ¡Tradición familiar!"].pick_random())


func _ai(delta: float) -> void:
	if _tutorial:
		return
	var st: String = him.state
	if st not in ["idle", "walk"]:
		return
	var d: Vector2 = me.pos - him.pos
	him.face = 1 if d.x > 0 else -1
	var speed: float = o["speed"] * (1.35 if _phase2 else 1.0)
	_taunt_cd -= delta
	if _taunt_cd <= 0.0:
		_taunt_cd = randf_range(7.0, 11.0)
		var pool: Array = o.get("taunts2", o["taunts"]) if _phase2 else o["taunts"]
		_say_call(pool.pick_random(), true)
	# El caído: cuenta, o Alvarito lo ayuda a levantarse (es el corazón).
	if me.state == "down":
		if absf(d.x) > 26 or absf(d.y) > 8:
			him.pos += d.normalized() * speed * delta
			_walkanim(him)
		elif him.cd <= 0.0:
			him.cd = 1.0
			if o.get("trick", false) and randf() < 0.25:
				me.state = "idle"
				me.node.play("idle")
				_say_call("DON TITO: —¡Alvarito lo ayuda a levantarse! ¡En plena lucha libre! ¡Qué hombre! ¡Qué hígado!")
			else:
				_start_pin(false)
		return
	# Alvarito: se hace el lesionado cuando va perdiendo; si uno se acerca, lo sorprende.
	if o.get("trick", false) and him.hp < him.max * 0.4 and randf() < 0.004:
		him.state = "fake"
		him.t = 2.5
		him.node.play("fall")
		_say_call("LA MONA: —Alvarito se agarra la rodilla. La izquierda. La semana pasada era la derecha.")
		_fake()
		return
	if absf(d.x) > REACH - 2 or absf(d.y) > 6:
		var dir := d.normalized()
		him.pos += dir * speed * delta
		_clamp(him)
		_walkanim(him)
		# A veces corre a las cuerdas para un clothesline.
		if absf(d.x) > 90 and him.cd <= 0.0 and randf() < 0.01:
			him.cd = 3.0
			_ai_run()
		return
	if him.node.animation != "idle":
		him.node.play("idle")
	if him.cd > 0.0:
		return
	him.cd = randf_range(0.7, 1.4) / (1.4 if _phase2 else 1.0)
	var r := randf()
	if r < 0.55:
		_strike(him, me, 5.0 * o["power"])
	elif r < 0.85 and me.state in ["idle", "walk"]:
		_start_grapple(false)


func _ai_run() -> void:
	him.state = "busy"
	him.node.play("run" if him.node.sprite_frames.has_animation("run") else "walk")
	var start: float = him.pos.x
	var edge := RING_R if him.face < 0 else RING_L
	var tw := create_tween()
	tw.tween_property(him, "pos:x", edge, 0.4)
	tw.tween_property(him, "pos:x", me.pos.x, 0.45)
	await tw.finished
	him.state = "idle"
	if _near(him, me, REACH + 6) and me.state in ["idle", "walk", "run"]:
		await _perform(him, me, "clothesline")


## Alvarito, el lesionado: si el pelado se le acerca a ayudarlo, ¡pin sorpresa!
func _fake() -> void:
	var t := 2.5
	while t > 0.0 and state == "fight":
		if not is_inside_tree():
			return
		await get_tree().process_frame
		t -= get_process_delta_time()
		if _near(me, him, 26):
			him.state = "idle"
			_say_call("DON TITO: —¡ERA MENTIRA! ¡ROLL-UP! ¡Mintió, hizo trampa y robó! ¡Con cariño! ¡Como un tío de verdad!")
			me.state = "down"
			me.t = 3.0
			_start_pin(false)
			return
	if him.state == "fake":
		him.state = "idle"
		him.node.play("idle")


## El Pecas: Mauricio, desde el delantal, le agarra el pie si se acerca a las cuerdas.
func _helper(delta: float) -> void:
	if not o.get("helper", false):
		return
	_trip_cd -= delta
	if _trip_cd <= 0.0 and me.state in ["idle", "walk"] and (me.pos.x < RING_L + 18 or me.pos.x > RING_R - 18):
		_trip_cd = 8.0
		me.state = "down"
		me.t = 1.6
		me.node.play("fall")
		_sfx["miss"].play()
		_say_call(CALLS["trip"][0])


func _walkanim(w: W) -> void:
	w.state = "walk"
	if w.node.animation != "walk":
		w.node.play("walk")


func _stop(w: W) -> void:
	w.state = "idle"
	w.node.play("idle")


func _clamp(w: W) -> void:
	w.pos.x = clampf(w.pos.x, RING_L, RING_R)
	w.pos.y = clampf(w.pos.y, FLOOR_T, FLOOR_B)


func _near(a: W, b: W, r: float) -> bool:
	return absf(a.pos.x - b.pos.x) < r and absf(a.pos.y - b.pos.y) < 9.0


func _at_corner(w: W) -> bool:
	return (w.pos.x < RING_L + 14 or w.pos.x > RING_R - 14) and w.pos.y < FLOOR_T + 10


# ---------------------------------------------------------------- Golpes y llaves

func _strike(a: W, b: W, dmg: float) -> void:
	if a.cd > 0.0 and a == me:
		return
	a.cd = 0.35
	a.state = "punch"
	a.t = 0.3
	a.node.play("punch")
	if _near(a, b, REACH + 4) and b.state in ["idle", "walk", "punch", "run"] and signf(b.pos.x - a.pos.x) == a.face:
		_hit(b, dmg, a)
	else:
		_sfx["miss"].play()


## Codazo al que está en el piso: poquito daño, mucho público. No lo levanta (para la cuenta, X).
func _elbow_drop() -> void:
	if me.cd > 0.0:
		return
	me.cd = 0.6
	me.state = "punch"
	me.t = 0.4
	me.node.play("crouch")
	him.hp -= 3.0
	_special = minf(100.0, _special + 8.0)
	_sfx["hit-1"].play()
	_check_ko(him)
	_say_call(["DON TITO: —¡Codazo al piso! ¡Sin elegancia, pero con fe!",
		"LA MONA: —Le cae con el codo. Así le caía el papá a la nevera."].pick_random())


func _hit(b: W, dmg: float, by: W) -> void:
	b.hp -= dmg
	b.state = "hurt"
	b.t = 0.35
	b.node.play("hurt")
	b.pos.x += 6 * by["face"]
	_clamp(b)
	_sfx["hit-1"].play()
	if by == me:
		_special = minf(100.0, _special + 6.0)
		_did["hit"] = true
	if randf() < 0.25:
		_say_call(CALLS["hit"].pick_random())
	_check_ko(b)


func _start_grapple(by_me: bool) -> void:
	state = "grapple"
	_grapple_t = 1.3
	_grip_me = 0.0
	_grip_him = 0.0
	_choice = ""
	for w in [me, him]:
		w.state = "busy"
		w.node.play("idle")
	me.face = 1 if him.pos.x > me.pos.x else -1
	him.face = -me.face
	him.pos = me.pos + Vector2(16 * me.face, 0)
	_center.text = "¡E E E!"
	if by_me:
		_grip_me += 1.0


func _grapple(delta: float) -> void:
	_grapple_t -= delta
	if Input.is_action_just_pressed("interact"):
		_grip_me += 1.0
	for k in ["move_left", "move_right", "move_up", "move_down"]:
		if Input.is_action_pressed(k):
			_choice = k
	_grip_him += delta * 6.5 * o["grip"] * (1.3 if _phase2 else 1.0) * (0.0 if _tutorial else 1.0)
	_center.text = "¡E E E!  %s" % {"": "", "move_left": "SUPLEX", "move_right": "A LAS CUERDAS",
		"move_up": "EL PORTAZO" if _special >= 100.0 else "DDT", "move_down": "SLAM"}[_choice]
	if _grapple_t > 0.0:
		return
	_center.text = ""
	state = "busy"
	if _grip_me >= _grip_him:
		var move: String = {"": "slam", "move_left": "suplex", "move_right": "whip", "move_up": "ddt", "move_down": "slam"}[_choice]
		if move == "ddt" and _special >= 100.0:
			move = "portazo"
			_special = 0.0
		# Raúl no se deja levantar hasta que se cansa.
		if move in ["suplex", "slam", "portazo"] and him.hp > him.max * o.get("lift_at", 1.1) and o["id"] == "raul" and not _tutorial:
			_say_call("LA MONA: —No lo puede levantar. Nadie ha levantado a Raúl desde el divorcio. La exesposa lo intentó con abogado.")
			_hit(me, 3.0, him)
			state = "fight"
			_stop(him)
			return
		await _perform(me, him, move)
	else:
		await _perform(him, me, o["signature"] if randf() < 0.5 else ["suplex", "slam"].pick_random())


## La llave: animación con tweens sobre el que la recibe. Después queda en el piso.
func _perform(a: W, b: W, move: String) -> void:
	state = "busy"
	a.state = "busy"
	b.state = "busy"
	var dmg: float = {"clothesline": 9.0, "suplex": 12.0, "slam": 10.0, "ddt": 14.0, "whip": 0.0, "portazo": 28.0,
		"chokeslam": 16.0, "frogsplash": 15.0, "tombstone": 20.0}.get(move, 10.0)
	if a == him:
		dmg *= o["power"] * (1.25 if _phase2 else 1.0)
	var tw := create_tween()
	match move:
		"suplex":
			tw.tween_property(b, "lift", 30.0, 0.25)
			tw.parallel().tween_property(b, "rot", -PI * a.face, 0.45)
			tw.parallel().tween_property(b, "pos:x", a.pos.x - 18 * a.face, 0.45)
			tw.tween_property(b, "lift", 0.0, 0.12)
		"slam", "chokeslam":
			var h := 40.0 if move == "slam" else 58.0
			tw.tween_property(b, "lift", h, 0.35)
			tw.tween_interval(0.2)
			tw.tween_property(b, "lift", 0.0, 0.1)
		"ddt", "tombstone", "portazo":
			tw.tween_property(b, "rot", PI, 0.25)
			tw.parallel().tween_property(b, "lift", 30.0 if move != "ddt" else 12.0, 0.25)
			tw.tween_interval(0.25 if move != "ddt" else 0.05)
			tw.tween_property(b, "lift", 0.0, 0.08)
		"clothesline":
			b.node.play("fall")
			tw.tween_property(b, "rot", -PI / 2.0 * a.face, 0.15)
		"whip":
			# A las cuerdas: rebota y vuelve; si al volver le pega E, clothesline.
			var edge := RING_R if a.face > 0 else RING_L
			b.node.play("walk")
			tw.tween_property(b, "pos:x", edge, 0.35)
			tw.tween_property(b, "pos:x", a.pos.x + 14 * a.face, 0.4)
			await tw.finished
			state = "fight"
			a.state = "idle"
			b.state = "idle"
			b.cd = 0.8
			_center.text = Controls.keys_in("¡E!")
			var t := 0.4
			while t > 0.0:
				if not is_inside_tree():
					return
				await get_tree().process_frame
				t -= get_process_delta_time()
				if Input.is_action_just_pressed("interact"):
					_center.text = ""
					await _perform(a, b, "clothesline")
					return
			_center.text = ""
			return
		"frogsplash":
			tw.tween_property(a, "lift", 34.0, 0.25)
			tw.parallel().tween_property(a, "pos:x", b.pos.x, 0.45)
			tw.tween_property(a, "lift", 0.0, 0.12)
	await tw.finished
	_clamp(a)
	_clamp(b)
	_shake = 1.0
	_sfx["hit-2"].play()
	b.rot = 0.0
	b.lift = 0.0
	b.hp -= dmg
	b.state = "down"
	b.t = 1.8 if move != "portazo" else 2.6
	b.node.play("fall")
	a.state = "idle"
	a.node.play("idle")
	if a == me:
		_special = minf(100.0, _special + 14.0)
		_did["clothesline" if move == "clothesline" else "llave"] = true
	var calls: Array = CALLS.get(move, CALLS["hit"])
	_say_call(calls.pick_random(), true)
	state = "fight"
	_check_ko(b)


## Desde la esquina, sobre el rival caído.
func _splash() -> void:
	state = "busy"
	me.state = "busy"
	me.node.play("kick")
	var tw := create_tween()
	tw.tween_property(me, "lift", 44.0, 0.2)
	tw.parallel().tween_property(me, "pos:x", him.pos.x, 0.5)
	tw.parallel().tween_property(me, "pos:y", him.pos.y, 0.5)  # la esquina está más atrás: cae sobre él
	tw.tween_property(me, "lift", 0.0, 0.15)
	await tw.finished
	if him.state == "down" and _near(me, him, 26):
		_shake = 1.0
		_sfx["hit-2"].play()
		him.hp -= 18.0
		him.t = 2.2
		_special = minf(100.0, _special + 20.0)
		_did["splash"] = true
		_say_call(CALLS["splash"][0], true)
	else:
		me.hp -= 8.0
		me.state = "down"
		me.t = 1.5
		me.node.play("fall")
		_say_call("DON TITO: —¡Se tiró al vacío! ¡No había nadie abajo!", true)
		state = "fight"
		return
	me.state = "idle"
	me.node.play("idle")
	state = "fight"
	_check_ko(him)


## Mauricio, la primera vez que lo tumban de verdad: se sienta. Fase 2.
func _check_ko(b: W) -> void:
	if b == him and o.get("situp", false) and not _phase2 and him.hp <= him.max * 0.35:
		_phase2 = true
		_situp()
	b.hp = maxf(b.hp, 1.0 if not _tutorial else b.max * 0.5)


func _situp() -> void:
	await get_tree().create_timer(1.2).timeout
	_lights = 0.15
	him.rot = 0.0
	him.state = "busy"
	him.node.play("getup")
	_say_call(CALLS["situp"][0], true)
	_center.text = "SE SENTÓ"
	await get_tree().create_timer(1.4).timeout
	_center.text = ""
	_lights = 0.5
	him.hp = him.max * 0.7
	_vest(false)
	him.state = "idle"
	him.node.play("idle")
	_say_call("MAURICIO: —Está bien. Está bien. Ya no más chaleco. Ya no más trago.", true)


# ---------------------------------------------------------------- La cuenta (Lukas)

func _start_pin(by_me: bool) -> void:
	state = "pin"
	_pin_by_me = by_me
	_pin_count = 0
	_pin_t = 0.9
	_kick = 0.0
	var top: W = me if by_me else him
	var bot: W = him if by_me else me
	bot.state = "down"
	top.state = "busy"
	top.pos = bot.pos + Vector2(0, -2)
	top.node.play("crouch" if top == me else "getup")
	_ref.position = bot.pos + Vector2(-20, 8)
	if not by_me:
		_center.text = "¡E E E! ¡LEVANTATE!"


func _pin(delta: float) -> void:
	_pin_t -= delta
	if not _pin_by_me and Input.is_action_just_pressed("interact"):
		_kick += 1.0
	if _pin_t > 0.0:
		return
	_pin_t = 0.9
	_pin_count += 1
	_ref_count.text = str(_pin_count)
	_ref.texture = REF_TEX["cuenta"]
	get_tree().create_timer(0.4).timeout.connect(func(): if is_instance_valid(_ref): _ref.texture = REF_TEX["quieto"])
	_ref_count.position = _ref.position + Vector2(-6, -40)
	_ref.position.y += -3 if _pin_count % 2 == 1 else 3
	var kicked := false
	if _pin_by_me:
		var hp_ratio: float = him.hp / him.max
		var chance := clampf(hp_ratio * 1.6 + 0.08 - 0.12 * _pin_count, 0.0, 0.97)
		if him.t > 1.8:  # recién golpeado con algo grande: no se levanta tan fácil
			chance *= 0.6
		kicked = randf() < chance and _pin_count < 3
		if o.get("situp", false) and not _phase2:
			kicked = true  # el Enterrador no pierde antes de sentarse
	else:
		var need := 4.0 + (1.0 - me.hp / me.max) * 9.0
		kicked = _kick >= need * (_pin_count / 3.0) and _pin_count < 3 and _kick >= 2.0
	if _tutorial and not _pin_by_me and _pin_count == 2:
		kicked = true  # en el tutorial, siempre llega a levantarse
	if _tutorial and _pin_by_me:
		kicked = true  # y Raúl también: todavía no es en serio
	if kicked:
		if not _pin_by_me:
			_did["kickout"] = true
		else:
			_did["pin"] = true
		_end_pin()
		_say_call(CALLS["kickout"][0] if not _pin_by_me else "LA MONA: —¡Se levantó en %d! ¡Todavía no!" % _pin_count, true)
		return
	if _pin_count >= 3:
		_ref_count.text = "3!"
		_center.text = "¡GANÓ!" if _pin_by_me else "PERDISTE"
		state = "end"
		await get_tree().create_timer(1.5).timeout
		_ref_count.text = ""
		_center.text = ""
		_result = "win" if _pin_by_me else "lose"


func _end_pin() -> void:
	_ref_count.text = ""
	_center.text = ""
	state = "fight"
	for w in [me, him]:
		if w.state == "busy":
			w.state = "idle"
			w.node.play("idle")
	# El que se levantó de la cuenta queda de pie (si no, se lo podría contar otra vez sin parar).
	var bot: W = him if _pin_by_me else me
	var top: W = me if _pin_by_me else him
	bot.state = "idle"
	bot.rot = 0.0
	bot.node.play("idle")
	bot.pos.x += 14 * (1 if bot.pos.x < 160 else -1)
	top.cd = 1.0
	_ref.position = Vector2(160, 150)


# ---------------------------------------------------------------- Final y despertar

func _final() -> void:
	state = "end"
	await Dialogue.talk([
		["", "Mauricio queda en la lona, mirando las luces. Lukas cuenta hasta tres. Despacio. Nadie lo apura."],
		["MAURICIO", "—Yo... los veía. Desde lejos. Desde la moto, con el Pecas. Los domingos."],
		["EL PELADO", "—Ya sé, pa. Desde lejos."],
		["", "Raúl pide otra ronda. El Pecas mira para otro lado. Alvarito es el único que aplaude, despacio."],
		["", "Él se baja del ring solo. Camina derecho. Por primera vez, sin mirar atrás."],
	])
	_wake(true)


func _wake(won: bool) -> void:
	state = "out"
	GameState.flags["dream_won"] = won
	GameState.flags["dream_return"] = "lucha%d" % (fight + 1)
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


func _say_call(line: String, force := false) -> void:
	if _call_cd > 0.0 and not force:
		return
	_call_cd = 2.8
	_call.text = line
	var tw := create_tween()
	_call.modulate.a = 1.0
	tw.tween_interval(2.6)
	tw.tween_property(_call, "modulate:a", 0.0, 0.4)


func _hud() -> void:
	_top.text = "EL PELADO %s" % _bar(me.hp / me.max)
	_top_r.text = "%s %s" % [_bar(him.hp / him.max), o["name"]]
	if state in ["fight", "busy", "grapple"]:
		_top.text += "\nESPECIAL %s%s" % [_bar(_special / 100.0), " ¡LISTO!" if _special >= 100.0 else ""]


func _bar(r: float) -> String:
	var n := int(round(clampf(r, 0.0, 1.0) * 8))
	return "[" + "|".repeat(n) + ".".repeat(8 - n) + "]"


# ---------------------------------------------------------------- Dibujo: el coliseo

func _draw() -> void:
	var L := _lights
	# Tribuna oscura con el público (siluetas) y flashes de cámaras.
	draw_rect(Rect2(0, 0, 320, 180), Color(0.05, 0.04, 0.07))
	for row in 4:
		for k in 30:
			var x := k * 11.0 + (row % 2) * 5.0
			var y := 44.0 + row * 12.0 + sin(_t * 3.0 + k + row) * (1.5 if state == "fight" else 0.4)
			draw_circle(Vector2(x, y), 4.0, Color(0.16, 0.12, 0.18).lerp(Color(0.3, 0.22, 0.28), L * 0.5))
			draw_rect(Rect2(x - 4, y + 3, 8, 6), Color(0.14, 0.1, 0.16).lerp(Color(0.26, 0.18, 0.24), L * 0.5))
	if state == "fight" and randf() < 0.08:
		draw_circle(Vector2(randf_range(0, 320), randf_range(40, 86)), 2.0, Color(1, 1, 0.9, 0.9))
	# La pantalla gigante: el nombre de la función y el del rival, titilando.
	draw_rect(Rect2(50, 26, 220, 16), Color(0.08, 0.08, 0.12))
	draw_rect(Rect2(50, 26, 220, 16), Color(0.5, 0.45, 0.6), false, 1.0)
	var title: String = "RAW DE DOMINGO" if int(_t * 0.5) % 2 == 0 else o["ring"]
	draw_string(FONT, Vector2(50, 38), title, HORIZONTAL_ALIGNMENT_CENTER, 220, 8, Color(1, 0.85, 0.4, 0.6 + 0.4 * L))
	# El ring: lona, delantal, postes y tres cuerdas (las de atrás, después los luchadores, y adelante).
	var lona := Color(0.78, 0.76, 0.72) * Color(L * 0.7 + 0.3, L * 0.7 + 0.3, L * 0.7 + 0.3)
	draw_colored_polygon(PackedVector2Array([Vector2(36, 110), Vector2(284, 110), Vector2(300, 158), Vector2(20, 158)]), lona)
	draw_rect(Rect2(20, 158, 280, 18), Color(0.55, 0.1, 0.12) * Color(L * 0.6 + 0.4, L * 0.6 + 0.4, L * 0.6 + 0.4))
	for x in [36.0, 284.0]:
		draw_rect(Rect2(x - 2, 80, 4, 32), Color(0.5, 0.5, 0.55))
	for k in 3:
		var y := 84.0 + k * 9.0
		draw_line(Vector2(36, y), Vector2(284, y), Color(0.9, 0.2, 0.2) if k == 0 else Color(0.95, 0.95, 0.95), 1.0)
	# Un foco sobre el ring.
	draw_colored_polygon(PackedVector2Array([Vector2(150, 0), Vector2(170, 0), Vector2(260, 158), Vector2(60, 158)]),
		Color(1, 0.95, 0.8, 0.05 + 0.05 * L))
	# Cuerdas de adelante (se dibujan con el z-index alto: aparte).
	if L < 0.99:
		draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, (1.0 - L) * 0.55))
