extends Node
## Duván, el pelao de la calle. Ocho años, nadie lo quiere. Algunos días (no todos), a una hora y en un
## lugar al azar del barrio o del Parque, a él le está pasando algo: lo sacan a escobazos, le pegan con
## la correa, los grandes le quitan los zapatos, le echan agua dormido. El protagonista puede meterse
## (sin hablar: se para en medio, agarra la correa, se sienta al lado) o seguir de largo.
## Otros días es al revés: el niño lo ayuda a él (medio pan, un aviso, una moneda devuelta, agua).
## Cada encuentro termina con un pedazo de la infancia de él, en tercera persona: el niño es su espejo.
##   flags: nino_bond (veces que se ayudaron), nino_nombre (ya dijo cómo se llama, a la tercera),
##          nino_hogar (lo llevó donde el Padre: ya no duerme en la calle), nino_aviso (día del aviso:
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
	"hogar": "(Hay un niño sentado en el andén, mirando para el lado de la iglesia.)",
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
	if kind == "" or f.get("nino_estado", "") == "fin":
		return
	var scene := get_parent()
	var now := TimeManager.minutes / 60.0
	var from: float = f["nino_hora"]
	var here: bool = scene.name == f["nino_lugar"] and now >= from and now < from + 3.0
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
	if rng.randf() > (0.85 if bond == 0 else 0.6):
		return
	var kind := ""
	if f.get("nino_hogar", false):
		kind = _next("help", HELP, rng)
	elif bond >= 6:
		kind = "hogar"
	elif bond >= 1 and rng.randf() < 0.4:
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
	var at: Vector2 = SPOTS[scene.name][int(f["nino_pos"])]
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
	return "DUVAN" if GameState.flags.get("nino_nombre", false) else "EL PELAO"


# ---------------------------------------------------------------- Lo que pasa

func talk(_npc: Node) -> void:
	var f := GameState.flags
	var kind: String = f.get("nino_hoy", "")
	if f.get("nino_estado", "") == "fin":  # ya pasó lo de hoy: se quedó sentado un rato
		await Dialogue.talk([[_who(), "—Váyase tranquilo. Yo me quedo otro rato. Aquí no estorbo."]])
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
		"hogar":
			helped = await _hogar()
		_:
			helped = await _help(kind)
	f["nino_estado"] = "fin"
	var key := "nino_n_" + ("help" if kind in HELP else "hurt")
	if kind != "hogar":
		f[key] = int(f.get(key, 0)) + 1
	if helped:
		f["nino_bond"] = int(f.get("nino_bond", 0)) + 1
		GameState.company(30.0)
		if int(f["nino_bond"]) == 1:
			await Recuerdo.show("infancia")
		if int(f["nino_bond"]) >= 3 and not f.get("nino_nombre", false):
			f["nino_nombre"] = true
			await Dialogue.talk([["EL PELAO", "—Me llamo Duván. Con uve. Usted no me preguntó, pero ya van tres veces. A la tercera uno dice el nombre."],
				["DUVAN", "—Usted no me diga el suyo. Yo le digo \"el del perro\". Así le dicen todos. Bueno, los que le dicen algo."]])
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
		["", "(Le da con la escoba en las piernas. El niño no llora. Se cubre la cabeza con los brazos: ya sabe dónde duele más.)"]], opts)
	match opts[i]:
		"Ponerse en medio":
			GameState.change_mood(4.0)
			await Dialogue.talk([
				["", "(Él se para entre la escoba y el niño. No dice nada. La escoba le da a él, una vez. Después se queda en el aire.)"],
				["SEÑOR DE LA TIENDA", "—... ¿Y este qué? ¿Es suyo? Lléveselo, pues. Dos gamines en vez de uno. Hoy es promoción."],
				["EL PELAO", "—Yo no le pedí nada, señor. ... ¿Le dolió? A mí ahí ya no me duele."]])
		"Comprarle un pan ($1.500)":
			GameState.add_money(-1500)
			GameState.change_mood(6.0)
			await Dialogue.talk([
				["", "(Él pone la plata en el mostrador. Señala el pan. Señala al niño.)"],
				["SEÑOR DE LA TIENDA", "—... Plata es plata. Pero se lo come afuera."],
				["EL PELAO", "—(con la boca llena) ¿Usted por qué no habla? ¿Le pegaron por hablar? A mí sí. Por eso hablo rápido."]])
		_:
			return await _pass("(Sigue de largo. Atrás, la escoba suena dos veces más. Él cuenta los golpes sin querer. Siempre los contó.)")
	await _mirror("(A él lo sacaban así de la tienda de la esquina, a los ocho. Tampoco lloraba. Llorar era darles la razón.)")
	return true


## Un señor le pega con la correa: creyó que le había robado.
func _correa() -> bool:
	var opts := ["Agarrarle la correa", "Seguir de largo"]
	if GameState.lukas_alive():
		opts.insert(1, "Soltar a Lukas")
	var i := await Dialogue.talk([
		["", "(Un señor tiene al niño agarrado del brazo. En la otra mano, la correa, doblada en dos.)"],
		["SEÑOR", "—¡Ladrón! ¡Me sacó la billetera! ... Ah, no, aquí está. Igual. Por si acaso. Para que aprenda."],
		["", "(Levanta la correa. El niño cierra los ojos antes de tiempo. Eso solo lo hace el que ya sabe cuánto se demora.)"]], opts)
	match opts[i]:
		"Agarrarle la correa":
			GameState.change_mood(5.0)
			await Dialogue.talk([
				["", "(Él le agarra la correa en el aire. Por la hebilla. Le queda marcada en la palma. No la suelta.)"],
				["SEÑOR", "—¡Suélteme! ¡Este no es su hijo! ... ¿Qué mira? ¿Qué me mira así? ¡Diga algo!"],
				["", "(El señor suelta al niño. Se pone la correa con las manos temblando. Se va rápido, sin correr, para que no parezca.)"],
				[_who(), "—Usted la agarró por la hebilla. Esa es la parte que más duele. ¿Cómo sabía?"]])
		"Soltar a Lukas":
			GameState.change_mood(5.0)
			await Dialogue.talk([
				["", "(Lukas ladra. Un ladrido solo, de beagle, que suena a perro tres veces más grande.)"],
				["SEÑOR", "—¡Ese perro tiene rabia! ¡Los tres tienen rabia!"],
				["", "(Se va. Lukas le lame al niño la marca del brazo. El niño se deja.)"],
				[_who(), "—¿Cómo se llama? ... ¿No me va a decir? Entonces le pongo yo: Tiburón."]])
		_:
			return await _pass("(Sigue de largo. La correa suena atrás. Él aprieta la mano sin darse cuenta, como agarrando una hebilla.)")
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
				[_who(), "—No importa. Con una camino. Con ninguna también."]])
		"Pagarles para que lo suelten ($2.000)":
			GameState.add_money(-2000)
			GameState.change_mood(2.0)
			await Dialogue.talk([
				["", "(Él les tira dos billetes al piso. Los grandes los recogen sin dejar de mirarlo.)"],
				["EL GRANDE", "—Con usted sí da gusto, cucho."],
				[_who(), "—No les hubiera dado. Mañana cobran más. ... Pero gracias. Nadie había pagado por mí. Ni para que me soltaran ni para nada."]])
		_:
			return await _pass("(Sigue de largo. Uno de los grandes se ríe. Él conoce esa risa: es la misma en todos los patios de todos los colegios.)")
	await _mirror("(En el colegio le quitaban la lonchera. Después dejó de llevar. No porque se la quitaran: porque ya no había qué echarle.)")
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
		["", "(El niño se duerme sentado, en dos minutos, recostado en él. Pesa menos que la mochila.)"]])
	TimeManager.skip(0.5)
	GameState.change_mood(7.0)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("stand_up"):
		await p.stand_up()
	await _mirror("(Él también aprendió a dormir sentado. En la sala, con los zapatos puestos, por si había que salir corriendo.)")
	return true


## De noche: duerme en una puerta y le echan un balde de agua.
func _agua() -> bool:
	var i := await Dialogue.talk([
		["", "(El niño dormía en un cartón, en una puerta. Arriba se abre una ventana. Un balde de agua fría.)"],
		["UNA VOZ", "—¡A dormir a otra parte! ¡Que me daña el andén!"],
		["", "(El niño no grita. Se para, sacude el cartón, busca otra puerta. Tirita.)"]],
		["Ponerle el saco encima", "Seguir de largo"])
	if i != 0:
		return await _pass("(Sigue de largo. El niño lo ve pasar. No le pide nada. Los que ya pidieron mucho dejan de pedir.)")
	GameState.flags["nino_saco"] = true
	GameState.change_mood(7.0)
	await Dialogue.talk([
		["", "(Él se quita el saco y se lo pone encima. Le llega a los tobillos. Le sobran las dos mangas.)"],
		[_who(), "—Huele a perro. ... Me gusta. Mañana se lo devuelvo. Yo devuelvo las cosas. Pregunte."]])
	await _mirror("(Las noches en que Mauricio llegaba tomado, él dormía en el patio. El frío era mejor. El frío no pegaba.)")
	return true


## Solo, golpeado. Dice que se cayó.
func _solo() -> bool:
	var i := await Dialogue.talk([
		["", "(El niño está sentado en el andén, solo. El labio partido. Un ojo que mañana va a estar morado.)"],
		[_who(), "—No fue nadie. Me caí. ... Uno siempre se cae, ¿no?"]],
		["Sentarse al lado", "Seguir de largo"])
	if i != 0:
		return await _pass("(Sigue de largo. \"Me caí.\" Él conoce esa frase. La dijo tantas veces que le salía sin pensar.)")
	GameState.flags["nino_quieto"] = true
	await Conversations._sit_ground("down")
	await Dialogue.talk([
		["", "(Se sienta al lado. No pregunta. %s)" % ("Lukas le pone la cabeza en las piernas al niño." if GameState.lukas_alive() else "El niño se le recuesta un poco, sin querer.")],
		[_who(), "—Mi mamá también decía que yo me caía. A la profesora. Yo le ayudaba a decir."],
		["", "(Se quedan un rato. Nadie los mira. Dos que nadie quiere, sentados, no le estorban la vista a nadie.)"]])
	TimeManager.skip(0.5)
	GameState.change_mood(6.0)
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("stand_up"):
		await p.stand_up()
	await _mirror("(\"Me caí.\" En tercero, la profesora dejó de preguntarle. Era más fácil para los dos.)")
	return true


## Después de seis veces: lo lleva donde el Padre. Ya no duerme en la calle.
func _hogar() -> bool:
	var i := await Dialogue.talk([
		["", "(Duván está sentado en el andén, mirando para la iglesia. Hace tres días no duerme: se le nota en cómo parpadea.)"],
		["DUVAN", "—Allá adentro hay catres. Me dijeron. Pero uno entra y le preguntan cosas. El nombre de la mamá. Yo no me acuerdo si es Sandra o Zandra."],
		["DUVAN", "—Y si uno no sabe, lo mandan a otra parte. A mí ya me mandaron a tres otras partes."]],
		["Darle la mano y llevarlo", "Todavía no"])
	if i != 0:
		await Dialogue.talk([["DUVAN", "—Tranquilo. Yo espero. Yo sé esperar: es lo que mejor hago."]])
		GameState.flags["nino_quieto"] = true
		return false
	await Dialogue.talk([
		["", "(Él le estira la mano. El niño la mira un rato, como una cosa que no sabe para qué sirve. Después la agarra.)"],
		["", "(Caminan hasta la iglesia. El niño cuenta los pasos en voz baja. Son ciento cuarenta.)"],
		["PADRE HERNANDO", "—¿Y este quién es? ... No me diga. Usted no dice. ¿Cómo se llama, mijo?"],
		["DUVAN", "—Duván. Con uve. Y él no tiene nombre, pero es bueno. No le pregunte cosas, padre. A él tampoco le gusta."],
		["PADRE HERNANDO", "—Aquí no se pregunta, mijo. Hay sopa y hay un catre. Lo de la mamá se averigua después. O no se averigua."],
		["", "(Duván entra. En la puerta se voltea.)"],
		["DUVAN", "—¿Usted viene mañana? ... No me diga. Yo sé que viene."]])
	GameState.flags["nino_hogar"] = true
	GameState.change_mood(14.0)
	GameState.complete_quest("nino")
	await _mirror("(A él nadie lo llevó de la mano a ninguna parte. Por eso se sabía el camino.)")
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
	if f.get("nino_hogar", false):
		lines.append(["", "(Duván. Peinado. Con zapatos. Los dos zapatos.)"])
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
			memory = "(Una vez él devolvió una billetera. Mauricio le pegó, por bobo. Nadie le puso nunca la mano en la cabeza para otra cosa.)"
		"tombos":
			f["ficha_oida"] = true
			f["es_el_oido"] = true
			lines.append([who, "—¡Pst! Los tombos tienen su foto pegada en la estación. Yo la vi cuando me llevaron. Al lado de los que roban."])
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
			memory = "(A los ocho nadie le alcanzó agua. Por eso ahora no sabe bien cómo se recibe. La recibe con las dos manos.)"
	GameState.change_mood(6.0)
	await Dialogue.talk(lines)
	await _mirror(memory)
	return true
