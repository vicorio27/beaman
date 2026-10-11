extends Node
## Alejandro, el pelao de la calle. Ocho años, nadie lo quiere. Algunos días (no todos), a una hora y en un
## lugar al azar del barrio o del Parque, a él le está pasando algo: lo sacan a escobazos, le pegan con
## la correa, los grandes le quitan los zapatos, le echan agua dormido. El protagonista puede meterse
## (sin hablar: se para en medio, agarra la correa, se sienta al lado) o seguir de largo.
## Otros días es al revés: el niño lo ayuda a él (medio pan, un aviso, una moneda devuelta, agua).
## Cada encuentro termina con un pedazo de la infancia de él, en tercera persona: el niño es su espejo.
## Es la proyección de él a los ocho años (se llama igual). Nunca se dice: se entiende al final, cuando
## el niño se despide (después de que muere Lukas, unos días antes de que se muera él).
##   flags: nino_bond (veces que se ayudaron), nino_nombre (ya dijo cómo se llama, a la tercera),
##          nino_fin (ya se despidió: no vuelve a salir), nino_aviso (día del aviso:
##          esa noche no le rajan el bolsillo), nino_saco (le prestó el saco).
## Lo agrega Location en los lugares de afuera. Lo que se habla: talk() (desde Conversations.run).

## Dónde puede estar, por escena.
const SPOTS := {
	"City": [Vector2(520, 474), Vector2(456, 254), Vector2(694, 408)],
	"Parque": [Vector2(470, 384), Vector2(300, 338)],
}
## Le están haciendo daño (en orden la primera vez; después, al azar). "agua" es de noche.
const HURT := ["escoba", "correa", "solo", "grandes", "celador", "agua"]
## Él ayuda al protagonista.
const HELP := ["pan", "tombos", "moneda", "aviso", "agua_botella"]
## Quién le pega en cada una: [fila de desconocido, hacia dónde está del niño]. Sin entrada: nadie a la vista.
const BAD := {"escoba": [3, Vector2(15, 0)], "correa": [0, Vector2(-14, 1)], "grandes": [2, Vector2(14, 3)], "celador": [-1, Vector2(13, -1)]}
const HINTS := {
	"escoba": "(Cerca, un escobazo. Y otro. Alguien grita \"¡gamín!\".)",
	"correa": "(Cerca, un señor grita \"¡ladrón!\". Suena una correa.)",
	"grandes": "(Cerca, risas de pelados grandes. Y uno chiquito que no se ríe.)",
	"celador": "(Cerca, un pito de celador. Alguien arrastra a alguien.)",
	"agua": "(Cerca, una ventana que se abre. Un baldado de agua.)",
	"solo": "(Cerca, un niño sentado en el andén. Nadie lo mira.)",
	"final": "(En el andén, un niño peinado con agua. De manga larga. Lo está esperando.)",
}

var _kid: Node2D
var _bad: Node2D
var _check := 0.0
var _loop: Tween


func _ready() -> void:
	name = "NinoDirector"


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 1.0
	_tick()


func _tick() -> void:
	var g := GameState
	var f := g.flags
	if g.day < 2 or not TimeManager.running:
		return
	if f.get("nino_dia", -1) != g.day:
		_plan()
	var kind: String = f.get("nino_hoy", "")
	if kind == "" or f.get("nino_estado", "") == "fin" or f.get("nino_fin", false):
		return
	var scene := get_parent()
	var now := TimeManager.minutes / 60.0
	var from: float = f["nino_hora"]
	var here: bool = scene.name == f["nino_lugar"] and now >= from and now < from + 3.0
	if kind == "final":  # la despedida: todo el día, en el barrio
		here = scene.name == "City" and now >= 6.0 and now < 23.0
	if here and not is_instance_valid(_kid) and not g.input_blocked():
		_spawn(kind)
	elif not here and is_instance_valid(_kid) and not _kid.talking:
		_clear()


## El plan del día: si aparece, dónde, a qué hora y qué le pasa.
func _plan() -> void:
	var f := GameState.flags
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("nino" + str(GameState.day))
	f["nino_dia"] = GameState.day
	f["nino_estado"] = "espera"
	f["nino_hoy"] = ""
	var bond := int(f.get("nino_bond", 0))
	if f.get("nino_fin", false):
		return
	if not GameState.lukas_alive():
		# Después de Lukas: solo la despedida (si se conocieron), desde el día siguiente y hasta que pase.
		if bond >= 1 and GameState.day > int(f.get("lukas_muerto", GameState.day)):
			f["nino_hoy"] = "final"
			f["nino_lugar"] = "City"
			f["nino_pos"] = 0
			f["nino_hora"] = 6.0
		return
	if rng.randf() > (0.85 if bond == 0 else 0.6):
		return
	var kind := ""
	if bond >= 1 and rng.randf() < 0.4:
		kind = _next("help", HELP, rng)
	else:
		kind = _next("hurt", HURT, rng)
	var place: String = "City" if rng.randf() < 0.7 else "Parque"
	f["nino_hoy"] = kind
	f["nino_lugar"] = place
	f["nino_pos"] = rng.randi() % SPOTS[place].size()
	f["nino_hora"] = 20.0 if kind == "agua" else float(rng.randi_range(8, 15))


## Las primeras salen en orden (cada una una vez); después, al azar.
func _next(key: String, names: Array, rng: RandomNumberGenerator) -> String:
	var n := int(GameState.flags.get("nino_n_" + key, 0))
	return names[n] if n < names.size() else names[rng.randi() % names.size()]


func _spawn(kind: String) -> void:
	var f := GameState.flags
	var scene := get_parent()
	var world: Node = scene.get_node_or_null("World")
	if world == null:
		world = scene
	var at: Vector2 = SPOTS[scene.name][int(f["nino_pos"]) % SPOTS[scene.name].size()]
	var npc := CharacterBody2D.new()
	npc.set_script(load("res://scripts/npc/NPC.gd"))
	npc.name = "Nino"
	npc.npc_id = "nino"
	npc.face = "down"
	npc.position = at
	world.add_child(npc)
	_kid = npc
	if BAD.has(kind):
		var spec: Array = BAD[kind]
		_bad = Node2D.new()
		_bad.position = at + spec[1]
		var s := AnimatedSprite2D.new()
		s.sprite_frames = CharacterFrames.adult(CharacterFrames.OWN["celador"] if spec[0] < 0 else CharacterFrames.STRANGERS[spec[0]])
		s.position = Vector2(0, -8)
		s.flip_h = spec[1].x < 0
		s.play("idle_side")
		_bad.add_child(s)
		world.add_child(_bad)
		_hit_loop.call_deferred(spec[1])
	if f.get("nino_aviso_dia", -1) != GameState.day:
		f["nino_aviso_dia"] = GameState.day
		Narrator.say(HINTS.get(kind, "(Cerca, alguien chifla bajito. \"¡Pst! ¡Señor del perro!\")"))


## El que le pega: se le va encima cada tanto. El niño se encoge y se pone rojo un instante.
func _hit_loop(off: Vector2) -> void:
	if not is_instance_valid(_bad) or not is_instance_valid(_kid):
		return
	var home := _bad.position
	var kid_home: Vector2 = _kid.position
	_loop = create_tween().set_loops()
	_loop.tween_interval(0.9)
	_loop.tween_property(_bad, "position", home - off * 0.45, 0.09)
	_loop.tween_callback(func():
		if is_instance_valid(_kid) and not _kid.talking:
			_kid.modulate = Color(1.0, 0.55, 0.55)
			_kid.position = kid_home - off.normalized() * 2.0)
	_loop.tween_property(_bad, "position", home, 0.22)
	_loop.tween_callback(func():
		if is_instance_valid(_kid):
			_kid.modulate = Color.WHITE
			_kid.position = kid_home)


func _clear() -> void:
	if _loop:
		_loop.kill()
	for n in [_kid, _bad]:
		if is_instance_valid(n):
			n.queue_free()


## El que le pegaba se va (rápido, sin correr, para que no parezca).
func _bad_leaves() -> void:
	if _loop:
		_loop.kill()
	if not is_instance_valid(_bad):
		return
	var b := _bad
	var s := b.get_child(0) as AnimatedSprite2D
	var dir := signf(b.position.x - _kid.position.x)
	s.flip_h = dir > 0
	s.play("walk_side")
	var t := b.create_tween()
	t.tween_property(b, "position:x", b.position.x + dir * 70.0, 1.6)
	t.parallel().tween_property(b, "modulate:a", 0.0, 1.6)
	t.tween_callback(b.queue_free)
	_bad = null


## El niño se va por su lado.
func _kid_leaves() -> void:
	if not is_instance_valid(_kid):
		return
	var k := _kid
	k.set_physics_process(false)
	for c in k.get_children():
		if c is Label:
			c.visible = false
	k.collision_layer = 0
	k.sprite.play("walk_side")
	var t := k.create_tween()
	t.tween_interval(0.4)
	t.tween_property(k, "position:x", k.position.x - 60.0, 1.8)
	t.parallel().tween_property(k, "modulate:a", 0.0, 1.8)
	t.tween_callback(k.queue_free)


func _who() -> String:
	return "ALEJANDRO" if GameState.flags.get("nino_nombre", false) else "EL PELAO"


# ---------------------------------------------------------------- Lo que pasa

func talk(_npc: Node) -> void:
	var f := GameState.flags
	var kind: String = f.get("nino_hoy", "")
	if f.get("nino_estado", "") == "fin":  # ya pasó lo de hoy: se quedó sentado un rato
		await Dialogue.talk([[_who(), "—Váyase tranquilo. Yo me quedo. Tengo el andén separado hasta las cinco."]])
		return
	if _loop:
		_loop.kill()
	if is_instance_valid(_kid):
		_kid.modulate = Color.WHITE
	GameState.start_quest("nino")
	var helped := false
	match kind:
		"escoba":
			helped = await _escoba()
		"correa":
			helped = await _correa()
		"grandes":
			helped = await _grandes()
		"celador":
			helped = await _celador()
		"agua":
			helped = await _agua()
		"solo":
			helped = await _solo()
		"final":
			helped = await _final()
		_:
			helped = await _help(kind)
	f["nino_estado"] = "fin"
	var key := "nino_n_" + ("help" if kind in HELP else "hurt")
	if kind != "final":
		f[key] = int(f.get(key, 0)) + 1
	if helped:
		f["nino_bond"] = int(f.get("nino_bond", 0)) + 1
		GameState.company(30.0)
		if int(f["nino_bond"]) == 1:
			await Recuerdo.show("infancia")
		if int(f["nino_bond"]) >= 3 and not f.get("nino_nombre", false):
			f["nino_nombre"] = true
			await Dialogue.talk([["EL PELAO", "—Me llamo Alejandro. Completo. Alejo no: Alejo es para los amigos, y usted todavía está en periodo de prueba."],
				["ALEJANDRO", "—Usted no me diga el suyo. Yo le digo \"el del perro\". Así le dicen todos. Al perro le dicen \"el perro\". Él salió ganando."]])
	_bad_leaves()
	if not f.get("nino_quieto", false):
		_kid_leaves()
	f.erase("nino_quieto")


## Lo de él, de niño: una línea después de cada encuentro.
func _mirror(text: String) -> void:
	await Dialogue.talk([["", text]])


func _pass(line: String) -> bool:
	GameState.change_mood(-6.0)
	await Dialogue.talk([["", line]])
	return false


## El tendero lo saca a escobazos por mirar el pan.
func _escoba() -> bool:
	var opts := ["Ponerse en medio", "Seguir de largo"]
	if GameState.money >= 1500:
		opts.insert(1, "Comprarle un pan ($1.500)")
	var i := await Dialogue.talk([
		["", "(Un niño flaco, de unos ocho años, con una camiseta que le llega a las rodillas. Miraba el pan de una vitrina. Solo miraba.)"],
		["SEÑOR DE LA TIENDA", "—¡Fuera! ¡Fuera, gamín! ¡Que me espanta la clientela! ¡Y la clientela ya venía espantada!"],
		["", "(Le da con la escoba en las piernas. El niño se cubre la cabeza con una técnica impecable. Eso no se improvisa.)"]], opts)
	match opts[i]:
		"Ponerse en medio":
			GameState.change_mood(4.0)
			await Dialogue.talk([
				["", "(Él se para entre la escoba y el niño. No dice nada. La escoba le da a él, una vez. Después se queda en el aire.)"],
				["SEÑOR DE LA TIENDA", "—... ¿Y este qué? ¿Es suyo? Lléveselo, pues. Dos gamines en vez de uno. Hoy es promoción."],
				["EL PELAO", "—Yo lo tenía controlado, señor. ... ¿Le dolió? Esa escoba es de las baratas. La de la droguería sí pega."]])
		"Comprarle un pan ($1.500)":
			GameState.add_money(-1500)
			GameState.change_mood(6.0)
			await Dialogue.talk([
				["", "(Él pone la plata en el mostrador. Señala el pan. Señala al niño.)"],
				["SEÑOR DE LA TIENDA", "—... Plata es plata. Pero se lo come afuera."],
				["EL PELAO", "—(con la boca llena) ¿Usted no habla? Mejor. Yo hablo por los dos. Eso sí: cobro aparte."]])
		_:
			return await _pass("(Sigue de largo. Atrás, la escoba suena dos veces más. Él las cuenta. No sabe para qué.)")
	await _mirror("(A los ocho, a él lo sacaban igual de la tienda de don Octavio. Escoba de palo azul. Don Octavio le fiaba a todo el barrio, menos a uno.)")
	return true


## Un señor le pega con la correa: creyó que le había robado.
func _correa() -> bool:
	var opts := ["Agarrarle la correa", "Seguir de largo"]
	if GameState.lukas_alive():
		opts.insert(1, "Soltar a Lukas")
	var i := await Dialogue.talk([
		["", "(Un señor tiene al niño agarrado del brazo. En la otra mano, la correa, doblada en dos.)"],
		["SEÑOR", "—¡Ladrón! ¡Me sacó la billetera! ... Ah, no, aquí está. Igual. Por si acaso. Para que aprenda."],
		["", "(Levanta la correa. El niño cierra los ojos medio segundo antes. Tiene el tiempo medido.)"]], opts)
	match opts[i]:
		"Agarrarle la correa":
			GameState.change_mood(5.0)
			await Dialogue.talk([
				["", "(Él le agarra la correa en el aire. Por la hebilla. Le queda marcada en la palma. No la suelta.)"],
				["SEÑOR", "—¡Suélteme! ¡Este no es su hijo! ... ¿Qué mira? ¿Qué me mira así? ¡Diga algo!"],
				["", "(El señor suelta al niño. Se pone la correa con las manos temblando. Se va rápido, sin correr, para que no parezca.)"],
				[_who(), "—Usted la agarró por la hebilla. Eso no lo hace un aficionado. ¿Dónde estudió?"]])
		"Soltar a Lukas":
			GameState.change_mood(5.0)
			await Dialogue.talk([
				["", "(Lukas ladra. Un ladrido solo, de beagle, que suena a perro tres veces más grande.)"],
				["SEÑOR", "—¡Ese perro tiene rabia! ¡Los tres tienen rabia!"],
				["", "(Se va. Lukas le lame al niño la marca del brazo. El niño se deja.)"],
				[_who(), "—¿Cómo se llama? ... ¿No me va a decir? Entonces le pongo yo: Tiburón."]])
		_:
			return await _pass("(Sigue de largo. La correa suena atrás. A él se le cierra la mano sola, como agarrando una hebilla.)")
	await _mirror("(La correa de Mauricio, su papá, era café, con hebilla de caballo. Él todavía sabe cuántos huecos tenía. Siete.)")
	return true


## Los pelados grandes le quitan lo que pidió, y los zapatos.
func _grandes() -> bool:
	var opts := ["Caminar hacia ellos", "Seguir de largo"]
	if GameState.money >= 2000:
		opts.insert(1, "Pagarles para que lo suelten ($2.000)")
	var i := await Dialogue.talk([
		["", "(Un pelado grande tiene al niño contra la pared. Atrás hay otros dos. Le cuentan las monedas. Le están quitando las chanclas.)"],
		["EL GRANDE", "—¿Esto fue todo lo que pidió hoy? ¡Vago! Mañana trae el doble, o camina descalzo."]], opts)
	match opts[i]:
		"Caminar hacia ellos":
			GameState.change_mood(4.0)
			await Dialogue.talk([
				["", "(Él camina hacia ellos. Despacio. Sin decir nada. Un hombre grande, sucio y callado, que camina derecho hacia uno.)"],
				["EL GRANDE", "—... Vámonos. Ese es el loco del perro. Ese no habla: ese muerde."],
				["", "(Sueltan las chanclas. Una, mejor dicho. La otra no aparece.)"],
				[_who(), "—Fresco. Con una chancla se camina. Es como media bicicleta."]])
		"Pagarles para que lo suelten ($2.000)":
			GameState.add_money(-2000)
			GameState.change_mood(2.0)
			await Dialogue.talk([
				["", "(Él les tira dos billetes al piso. Los grandes los recogen sin dejar de mirarlo.)"],
				["EL GRANDE", "—Con usted sí da gusto, cucho."],
				[_who(), "—¿Dos mil? Yo pensé que valía más. ... No les vuelva a pagar, que me suben la tarifa."]])
		_:
			return await _pass("(Sigue de largo. Uno de los grandes se ríe. Él conoce esa risa: es la misma en todos los patios de todos los colegios.)")
	await _mirror("(En el colegio a él le quitaban la lonchera. Era de los Thundercats. Adentro casi nunca había nada: se la robaban por la lonchera.)")
	return true


## El celador lo saca de una oreja: dormía debajo de una banca.
func _celador() -> bool:
	var i := await Dialogue.talk([
		["", "(Un celador lo lleva agarrado de una oreja. El niño dormía debajo de una banca, con un cartón.)"],
		["CELADOR", "—¡Aquí no se duerme! ¡Esto es espacio público! ¡Público quiere decir que no es suyo!"]],
		["Sentarse y sentarlo al lado", "Seguir de largo"])
	if i != 0:
		return await _pass("(Sigue de largo. A él lo han sacado de esa misma banca. Con el mismo discurso. Público quiere decir que no es de él.)")
	GameState.flags["nino_quieto"] = true
	_bad_leaves()
	await Conversations._sit_ground("down")
	await Dialogue.talk([
		["", "(Él se sienta ahí mismo. Le da una palmada al piso, al lado. El niño se zafa y se sienta.)"],
		["CELADOR", "—... Sentados sí se puede. Acostados no. Es la norma. Yo no hice la norma. A mí también me sacan de sitios."],
		["", "(El niño se duerme sentado, en dos minutos, recostado en él. Pesa menos que la mochila. Ronca como un señor de cincuenta.)"]])
	TimeManager.skip(0.5)
	GameState.change_mood(7.0)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("stand_up"):
		await p.stand_up()
	await _mirror("(Él también duerme sentado desde chiquito. En la sala, con los zapatos puestos. Uno nunca sabía a qué hora tocaba salir.)")
	return true


## De noche: duerme en una puerta y le echan un balde de agua.
func _agua() -> bool:
	var i := await Dialogue.talk([
		["", "(El niño dormía en un cartón, en una puerta. Arriba se abre una ventana. Un balde de agua fría.)"],
		["UNA VOZ", "—¡A dormir a otra parte! ¡Que me daña el andén!"],
		["", "(El niño se para, sacude el cartón y mira para arriba.)"],
		[_who(), "—¡Ya me bañé ayer, señora! ¡Guarde para el domingo!"]],
		["Ponerle el saco encima", "Seguir de largo"])
	if i != 0:
		return await _pass("(Sigue de largo. El niño le hace con la mano que tranquilo, que él tiene todo bajo control. No tiene nada bajo control.)")
	GameState.flags["nino_saco"] = true
	GameState.change_mood(7.0)
	await Dialogue.talk([
		["", "(Él se quita el saco y se lo pone encima. Le llega a los tobillos. Le sobran las dos mangas.)"],
		[_who(), "—Huele a perro. ... Me gusta. Mañana se lo devuelvo. Yo devuelvo las cosas. Pregunte."]])
	await _mirror("(Las noches en que Mauricio llegaba tomado, él dormía en el patio. Hacía frío. El frío, por lo menos, no opinaba.)")
	return true


## Solo, golpeado. Dice que se cayó.
func _solo() -> bool:
	var i := await Dialogue.talk([
		["", "(El niño está sentado en el andén, solo. El labio partido. Un ojo que mañana va a estar morado.)"],
		[_who(), "—No fue nadie. Me caí. Tres veces. Encima de un puño."]],
		["Sentarse al lado", "Seguir de largo"])
	if i != 0:
		return await _pass("(Sigue de largo. \"Me caí.\" Esa excusa él la conoce. Es de él. El niño se la está usando sin permiso.)")
	GameState.flags["nino_quieto"] = true
	await Conversations._sit_ground("down")
	await Dialogue.talk([
		["", "(Se sienta al lado. No pregunta. %s)" % ("Lukas le pone la cabeza en las piernas al niño." if GameState.lukas_alive() else "El niño se le recuesta un poco, sin querer.")],
		[_who(), "—Mi mamá le decía a la profesora que yo era muy torpe. La profesora me metió a danzas. Para la coordinación."],
		["", "(Se quedan un rato. Pasa gente. Nadie los mira: sentados quedan por debajo de donde la gente mira.)"]])
	TimeManager.skip(0.5)
	GameState.change_mood(6.0)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("stand_up"):
		await p.stand_up()
	await _mirror("(\"Me caí.\" Él la usó hasta tercero. Ese año la profesora le regaló unas rodilleras.)")
	return true


## El final: unos días antes de que él se muera, después de Lukas. Alejandro viene a despedirse, vestido
## como él en la foto del colegio. No se dice que el niño era él: lo dicen el perro que "va a tener" (en una
## caja de zapatos, talla 42), la foto, y Don Germán, que lleva semanas viéndolo sentarse solo en ese andén.
func _final() -> bool:
	GameState.flags["nino_nombre"] = true
	var i := await Dialogue.talk([
		["", "(Alejandro está sentado en el andén. Peinado con agua. Camisa de manga larga, abotonada hasta arriba. Hace calor.)"],
		["ALEJANDRO", "—Quiubo. Vengo a entregar el puesto. Me voy."],
		["ALEJANDRO", "—No ponga esa cara. Bueno: usted siempre tiene esa cara. Es que aquí ya no hay nada que hacer. Usted ya agarró la correa, ya se sentó, ya pagó el pan. Me dejó sin trabajo."],
		["", "(El niño mira para el lado donde siempre andaba Lukas. No pregunta.)"],
		["ALEJANDRO", "—Yo también voy a tener un perro. Tiburón no: ese nombre ya lo gasté. Llega en una caja de zapatos. Talla 42. Se la come."]],
		["Ponerle la mano en la cabeza", "Quedarse quieto"])
	if i == 0:
		await Dialogue.talk([
			["", "(Él le pone la mano en la cabeza. El niño no se encoge. Primera vez.)"],
			["ALEJANDRO", "—Bueno, Alejo. Sí: ya pasó el periodo de prueba. Le digo Alejo y usted me dice Alejo. Queda en familia."]])
	else:
		await Dialogue.talk([
			["", "(Él no se mueve. El niño le agarra la mano y se la pone en la cabeza, como quien cuelga un sombrero.)"],
			["ALEJANDRO", "—Así. No era tan difícil, Alejo. Ya pasó el periodo de prueba."]])
	await Dialogue.talk([
		["", "(El niño le deja algo en la mano y se va por la mitad de la calle, sin mirar a los lados. No pasa ningún carro.)"],
		["", "(Es la foto del colegio. Segundo B. Manga larga todo el año. Abajo, con lápiz, alguien agregó: \"Sí aguantó.\")"],
		["DON GERMAN", "—¿Todo bien, vecino? ... Es que lleva semanas sentándose en ese andén. Solo. A veces compra dos panes."],
		["DON GERMAN", "—No me explique. Usted no explica. Yo le sigo vendiendo los dos."]])
	GameState.flags["nino_fin"] = true
	GameState.flags["nino_quieto"] = true
	GameState.change_mood(12.0)
	GameState.complete_quest("nino")
	if is_instance_valid(_kid):
		_kid.queue_free()
	return true


## El niño lo ayuda a él.
func _help(kind: String) -> bool:
	var f := GameState.flags
	var who := _who()
	var lines: Array = []
	if f.get("nino_saco", false):
		f.erase("nino_saco")
		lines.append(["", "(El niño le devuelve el saco, doblado. Mal doblado. Pero doblado.)"])
		lines.append([who, "—Le dije que yo devolvía."])
	var memory := ""
	match kind:
		"pan":
			lines.append(["", "(El niño sale de atrás de una caneca con un pan. Lo parte: un pedazo para él, otro para el señor%s.)" % (", otro para Lukas" if GameState.lukas_alive() else "")])
			lines.append([who, "—En la panadería botan el de ayer a las seis. Atrás, en la caneca verde. No le diga a nadie que yo le dije. Bueno, usted no dice."])
			if GameState.has_space_for("pan"):
				GameState.add_item("pan")
			GameState.set_hunger(GameState.hunger + 12.0)
			memory = "(A los ocho él también sabía a qué hora botaban el pan. De niño uno se aprende los horarios que le tocan.)"
		"moneda":
			var coins := 1200 + 300 * mini(6, int(f.get("nino_bond", 0)))
			GameState.add_money(coins)
			lines.append(["", "(El niño lo alcanza corriendo. Trae algo apretado en el puño.)"])
			lines.append([who, "—Se le cayó. Yo vi. Me lo iba a quedar. ... No me lo quedé. Son $%d. Cuéntelos." % coins])
			lines.append(["", "(Él le pone la mano en la cabeza. Un segundo. El niño se encoge primero, por costumbre. Después no.)"])
			memory = "(A los ocho él devolvió una billetera. El dueño le dio las gracias. Mauricio le dio otra cosa, por bobo.)"
		"tombos":
			f["ficha_oida"] = true
			f["es_el_oido"] = true
			lines.append([who, "—¡Pst! Los tombos tienen su foto pegada en la estación. Al lado de los que roban. Sale feo. Sin barba. La barba le ayuda."])
			lines.append([who, "—Usted no roba. Yo sí, y no tengo foto. Debajo dice \"que circule\". ¿Qué es circular? ¿Es que no lo dejan quedarse?"])
			lines.append(["", "(Él no contesta. El niño entiende igual.)"])
			lines.append([who, "—A mí tampoco me dejan. Pero a mí es por chiquito. A usted es por algo que alguien firmó."])
			memory = "(A los ocho, el vecino llamaba a la policía cuando oía los golpes. Llegaban, hablaban con Mauricio en la puerta, se reían. Se iban. Él aprendió temprano de qué lado se paran.)"
		"aviso":
			f["nino_aviso"] = GameState.day
			lines.append([who, "—¡Pst! ¡Señor del perro! Esta noche duerma tranquilo. Los de la esquina andan esculcando a los dormidos, pero yo les dije que usted tiene sarna."])
			lines.append([who, "—No tiene, ¿cierto? ... Bueno. Igual ya no se le arriman."])
			lines.append(["", "(Esta noche nadie le va a tocar el bolsillo.)"])
			memory = "(De niño él oía todo. El que crece con miedo oye las llaves antes de que entren en la chapa.)"
		_:
			lines.append(["", "(El niño le pone al lado una botella de agua, casi llena.)"])
			lines.append([who, "—Usted hoy está caminando feo. Como yo cuando no he comido. Tome. Era de un señor del gimnasio. No la babié."])
			GameState.set_hunger(GameState.hunger + 8.0)
			memory = "(Él recibe la botella con las dos manos, como un trofeo. No tiene mucha práctica recibiendo cosas.)"
	GameState.change_mood(6.0)
	await Dialogue.talk(lines)
	await _mirror(memory)
	return true
