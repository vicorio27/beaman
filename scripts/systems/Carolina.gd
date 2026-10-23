class_name Carolina
extends RefCounted
## Diana Carolina: la denuncia se va cayendo con los días, y ella lo busca para pedirle perdón.
## Ella no lo busca para volver; lo busca para que él sepa que ella ya sabe lo que hizo. Él no habla.
## Una cosa por día, y solo en la ciudad (City), en orden (flags.carolina_etapa):
##   0 -> 1  (día 5+, de día)     la ve en la esquina: lo mira, se tapa con el pelo y se va.
##   1 -> 2  (día 10+)            con celular: una llamada en silencio y un "perdón". Sin celular: una
##                                nota debajo del cartón, con una sola palabra.
##   2 -> 3  (día 15+, mañana)    el periódico de la banca: "la denunciante rectifica" (recorte_4).
##   3 -> 4  (día 20+, mañana)    la carta, debajo del cartón (carta_carolina).
##   4 -> 5  (día 25+, tarde)     habla: por teléfono o, sin celular, en persona, al lado del puente.
##   5 -> 6  (día 30+)            la denuncia, retirada del todo (flags.denuncia_retirada): aparece la
##                                página 14 en el parque. La ficha de la policía sigue abierta: eso
##                                se cierra en la Defensoría.
## Lo llama QuestDirector.tick; Phone llama a llamada() cuando él contesta.

const CAROLINA := "DIANA CAROLINA"


static func etapa() -> int:
	return int(GameState.flags.get("carolina_etapa", 0))


static func _done() -> void:
	var f := GameState.flags
	f["carolina_etapa"] = etapa() + 1
	f["carolina_dia"] = GameState.day


static func tick(scene: Node) -> void:
	var g := GameState
	var f := g.flags
	if scene == null or scene.name != "City" or not TimeManager.running or Dialogue.active or SceneRouter.busy \
			or g.ui_open or g.input_blocked() or f.get("carolina_ocupada", false):
		return
	if int(f.get("carolina_dia", -1)) == g.day or int(f.get("carolina_intento", -1)) == g.day:
		return
	var h := TimeManager.hour()
	match etapa():
		0:
			if g.day >= 5 and h >= 9 and h < 17:
				_esquina(scene)
		1:
			if g.day >= 10 and h >= 8 and h < 20:
				if Phone.has_phone():
					f["carolina_intento"] = g.day  # si no contesta, mañana vuelve a intentar
					Phone.call_in("carolina")
				else:
					_nota()
		2:
			if g.day >= 15 and h >= 7 and h < 13:
				_periodico()
		3:
			if g.day >= 20 and h >= 6 and h < 12:
				_carta()
		4:
			if g.day >= 25 and h >= 16 and h < 19:
				if Phone.has_phone():
					f["carolina_intento"] = g.day
					Phone.call_in("carolina")
				else:
					_en_persona(scene)
		5:
			if g.day >= 30:
				_done()
				f["denuncia_retirada"] = true
				Narrator.say("(Un patrullero pasa despacio. Esta vez no frena. En algún escritorio, un papel se cerró: el de ella. El de ellos, todavía no.)")


## La ve en la esquina. Ella lo mira, se tapa la cara con el pelo y se va.
static func _esquina(scene: Node) -> void:
	var f := GameState.flags
	var player := scene.get("player") as Node2D
	if player == null:
		return
	f["carolina_ocupada"] = true
	var her := _sprite(scene, player.global_position + Vector2(110, -24))
	her.play("idle_side")
	her.flip_h = false  # lo mira a él (la hoja mira a la izquierda)
	await Dialogue.talk([["", "(En la esquina, una muchacha de pelo negro. Lo está mirando. Cuando él la mira, se tapa la cara con el pelo.)"],
		["", "(Diana Carolina. La reconoce por cómo camina, aunque esté quieta: como si llegara tarde a algo que no existe.)"]])
	if GameState.lukas_alive():
		await Dialogue.talk([["", "(Lukas la conoce. No ladra. Mueve la cola poquito, como pidiendo permiso.)"]])
	if not is_instance_valid(her):  # (se cambió de lugar mientras hablaban)
		f.erase("carolina_ocupada")
		_done()
		return
	her.flip_h = true
	her.play("walk_side")
	await her.create_tween().tween_property(her, "position", her.position + Vector2(160, 0), 2.4).finished
	her.queue_free()
	f.erase("carolina_ocupada")
	_done()


static func _sprite(scene: Node, at: Vector2) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = CharacterFrames.adult(CharacterFrames.OWN["diana"])
	s.position = at + Vector2(0, -8)
	var world := scene.get_node_or_null("World")
	(world if world else scene).add_child(s)
	return s


## Sin celular: la nota, debajo del cartón de la cama.
static func _nota() -> void:
	_done()
	if GameState.has_space_for("nota_perdon"):
		GameState.add_item("nota_perdon")
	await Dialogue.talk([["", "(Debajo del cartón de la cama hay una hoja de cuaderno, doblada en cuatro. Dice una sola palabra: \"Perdón.\")"],
		["", "(Sin firma. No hace falta: las íes con circulito.)"]])


## El periódico de la banca: la denunciante rectifica.
static func _periodico() -> void:
	_done()
	if GameState.has_space_for("recorte_4"):
		GameState.add_item("recorte_4")
	await Dialogue.talk([["", "(En la banca hay un periódico de ayer. Página 9, abajo, chiquito, al lado de un aviso de colchones:)"],
		["", "\"Operativo del sur: la denunciante rectifica. 'Nadie me obligó', dijo ante la Fiscalía.\""],
		["", "(Arranca el pedazo. La portada, la de su foto, salió del tamaño de media página. Esto, del tamaño de una estampilla.)"]])


## La carta, debajo del cartón.
static func _carta() -> void:
	_done()
	if GameState.has_space_for("carta_carolina"):
		GameState.add_item("carta_carolina")
	await Dialogue.talk([["", "(Debajo del cartón, metido para que no se moje, un sobre. Su nombre, con la letra redonda de ella.)"],
		["", "«No sé si usted va a leer esto. Lo dejo debajo del cartón porque la señora del puesto me dijo dónde duerme. No la regañe: le dije que era su hermana.»"],
		["", "«Lo que dije de usted no es verdad. Ya empecé a retirarlo. Es lento, como todo allá: hay que hacer fila hasta para decir la verdad.»"],
		["", "«No le pido nada. Solo que no se crea lo que dice ese papel. Yo tampoco me lo creo. — C.»"],
		["", "(La dobla. La guarda en la mochila. No la vuelve a leer. Bueno: una vez más.)"]])


## Lo que le dice (por teléfono o en persona). Devuelve si se quedó a oírla.
static func _palabras(phone: bool) -> bool:
	var stay := ["(Respirar)", "(Quedarse en la línea)", "(Colgar)"] if phone else ["(Quedarse)", "(Mirar el río)", "(Irse)"]
	var i := await Dialogue.talk([
		[CAROLINA, "—¿Aló? No cuelgue. Por favor. Soy yo. Carolina." if phone else "—No se vaya. Por favor. Un minuto. Ya sé que usted no habla: yo hablo por los dos. Así nos fue."],
		[CAROLINA, "—Lo que dije en la estación no fue cierto. Usted no me obligó a nada. Fue mi decisión. Mía. Y me dio miedo que fuera mía, y se la eché a usted."],
		[CAROLINA, "—Lorena me llevó. Me dijo cómo decirlo. Lo del arma lo puso ella. Yo firmé. Firmar es fácil: uno no le ve la cara al otro."]], stay)
	if i == 2:
		return false
	await Dialogue.talk([
		[CAROLINA, "—Ya fui a la Fiscalía tres veces. La primera me temblaba la mano. La tercera ya no. Me falta poquito para retirarla toda."],
		[CAROLINA, "—¿Lukas está bien? ... Dígale que perdón también. Él no tuvo la culpa de nada." if GameState.lukas_alive() else "—Supe lo de Lukas. ... Eso también se lo debo. No sé cómo se paga eso."],
		[CAROLINA, "—No le pido que me perdone. Le pido nada más que sepa que ya sé lo que hice."]])
	return true


## La llamada que contesta (Phone). Etapa 1: el silencio. Etapa 4: habla.
static func llamada() -> void:
	var f := GameState.flags
	f.erase("carolina_intento")
	if etapa() == 1:
		_done()
		await Dialogue.talk([["", "(Silencio. Alguien respira del otro lado. No es Lorena: Lorena no sabe respirar callada.)"],
			["", "(Así un rato. Él tampoco cuelga.)"],
			["UNA VOZ", "—... Perdón."],
			["", "(Cuelga ella. Esa voz la conoce. El número no vuelve a aparecer.)"]])
		return
	_done()
	if await _palabras(true):
		await Dialogue.talk([["", "(Él no dice nada. Respira. Del otro lado, ella también. Así un rato, como cuando eran novios y ninguno quería colgar primero.)"],
			[CAROLINA, "—... Bueno. Cuelgue usted. Yo no soy capaz."],
			["", "(Cuelga él. Despacio.)"]])
	else:
		await Dialogue.talk([["", "(Cuelga.)"],
			["", "(Ella no vuelve a marcar. Al rato, un mensaje de texto, sin tildes: \"Esta bien. Igual la retiro.\")"]])


## Sin celular: lo encuentra en persona, a la orilla del puente, a la hora en que se pone el sol.
static func _en_persona(scene: Node) -> void:
	var f := GameState.flags
	var player := scene.get("player") as Node2D
	if player == null:
		return
	f["carolina_ocupada"] = true
	_done()
	var her := _sprite(scene, player.global_position + Vector2(90, 0))
	her.play("walk_side")
	await her.create_tween().tween_property(her, "position", player.global_position + Vector2(26, -8), 1.6).finished
	her.play("idle_side")
	await Dialogue.talk([["", "(Ella. Llega caminando rápido y se frena a dos pasos, como si ahí hubiera una raya que solo ella ve.)"]])
	if await _palabras(false):
		await Dialogue.talk([["", "(Se quedan ahí, uno al lado del otro, mirando el río. Ninguno dice nada. Eso sí lo sabían hacer bien.)"],
			[CAROLINA, "—... Bueno. Me voy yo, que usted no se va a ir nunca."]])
	else:
		await Dialogue.talk([["", "(Él se da la vuelta y camina. Ella no lo sigue.)"],
			[CAROLINA, "—Está bien. Igual la retiro."]])
	her.flip_h = true
	her.play("walk_side")
	await her.create_tween().tween_property(her, "position", her.position + Vector2(150, 0), 2.2).finished
	her.queue_free()
	f.erase("carolina_ocupada")
