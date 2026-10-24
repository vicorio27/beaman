class_name LukasManda
extends Node
## El día que él no se levanta: si se acostó con el hambre en 0 o 1 (de 10), al otro día el cuerpo dice
## que no (GameState.new_day lo marca: "no_se_levanta"). Se queda tirado, tapado con el cartón, y el
## jugador maneja a Lukas: E, pedirle a la gente. Algunos le dan algo de comer; otros, un chiste. Lukas se
## lo lleva, él se sienta, come, le da el último pedazo y se levanta. A mediodía se levanta solo.
## Mientras tanto GameState.input_blocked() (bandera "lukas_manda"): él y todo lo que se toca con E se
## quedan quietos; Lukas lee los controles directo.

const HASTA := 12  # a esta hora se levanta solo, con o sin comida
const REACH := 30.0
const SPEED := 74.0

## npc_id -> lo que pasa cuando Lukas le pide. "da": lo que le dan (vacío: nada, solo el chiste).
const PIDE := {
	"rosa": {"da": "arepa", "lines": [["DOÑA ROSA", "—¿Y usted solo? ¿Y el mudo?"],
		["", "(Lukas se sienta. Levanta una pata. La deja en el aire, como quien firma.)"],
		["DOÑA ROSA", "—No me mire así. ... Tome. Para él, no para usted. Y no me la babee, que es con queso."]]},
	"marta": {"da": "empanada", "lines": [["MARTA", "—Ah, no. Ahora me manda al perro. Qué descaro tan bien entrenado."],
		["", "(Lukas apoya la cabeza en la rodilla de ella. Medio segundo. Lo justo.)"],
		["MARTA", "—... Una empanada. Y dígale que esto no fue cariño: fue chantaje."]]},
	"samuel": {"da": "pan", "lines": [["SAMUEL", "—¿Se cayó, cierto? Uno se cae por dentro primero."],
		["SAMUEL", "—Tome, medio pan. El otro medio es mío: también me caigo."]]},
	"fabiola": {"da": "pan", "lines": [["DOÑA FABIOLA", "—¡Lukas! ¿Y su dueño? ... ¿No se levantó? Eso es el hambre, mijo. Yo sé."],
		["DOÑA FABIOLA", "—Llévele este pan. Y dígale que la sopa es el jueves, que no me falte."]]},
	"padre": {"da": "pan", "lines": [["PADRE HERNANDO", "—Un perro solo en la puerta de la iglesia. O es un milagro o es un recado."],
		["", "(Lukas mueve la cola. Es un recado.)"],
		["PADRE HERNANDO", "—Tome. Pan de la sacristía. No está bendito, pero está blandito, que es más de lo que se le puede pedir a la sacristía."]]},
	"wilson": {"da": "", "lines": [["WILSON", "—Yo tengo latas, socio. Latas vacías. Si quiere le doy una para que la lama. Sabe a cerveza de anoche."],
		["", "(Lukas la huele. Decide que no. Tiene dignidad, aunque no tenga desayuno.)"]]},
	"mono": {"da": "", "lines": [["EL MONO", "—¿Comida? Yo le puedo dar una canción. ♪ Perro que ladra no come... ♪ No, esa no. Esa es triste."],
		["", "(Lukas se va antes del coro.)"]]},
	"efrain": {"da": "", "lines": [["DON EFRAIN", "—Aquí no hay nada de comer, pelao. Hay una tostadora de 1974. Sin pan, que es la parte que importa."],
		["", "(Lukas mira a Gloria, la muñeca de un ojo. Gloria lo mira. No negocian.)"]]},
	"leonor": {"da": "", "lines": [["DOÑA LEONOR", "—¿Un clavel? Para él. ... ¿No? ¿Comida? Los claveles no se comen, mijo. Bueno, se pueden. Pero no."],
		["", "(Lukas se lleva el clavel en la boca dos metros y lo deja. Hoy no.)"]]},
	"aurelio": {"da": "", "lines": [["DON AURELIO", "—En mis tiempos los perros cazaban. Usted es de los de ahora: pide."],
		["", "(Lukas no discute con viejos. Se va con la cola en alto.)"]]},
	"viejos": {"da": "", "lines": [["", "(Los del ajedrez no levantan la cara del tablero. Uno le acaricia la cabeza sin mirar, y mueve la reina.)"],
		["", "(Lukas espera que le toque algo. Le toca el jaque.)"]]},
	"celador": {"da": "", "lines": [["CELADOR", "—Aquí no pueden estar perros. ... Bueno. Usted no es perro: usted es visita. Pero no tengo nada."],
		["", "(Le toca el pito. Lukas le ladra al pito. Empatan.)"]]},
}
## Cuando Lukas vuelve donde alguien que ya le dio otro día: que no sea el mismo chiste.
const REPITE := {
	"rosa": [["DOÑA ROSA", "—¿Otra vez usted? Ese hombre suyo tiene que aprender a comer solo."],
		["DOÑA ROSA", "—Tome. Y dígale que esta se la anoto. Con letra grande."]],
	"marta": [["MARTA", "—Mire quién volvió: el cobrador. ... Una empanada. La de la otra vez me la pagó con ojitos. Esta también, ya sé."]],
	"samuel": [["SAMUEL", "—Usted otra vez. Bueno: el pan es del que lo necesita, y hoy lo necesitan dos."]],
	"fabiola": [["DOÑA FABIOLA", "—Ay, mijo, otra vez. Tome. Y dígale que la sopa es el jueves, que no me vuelva a faltar."]],
	"padre": [["PADRE HERNANDO", "—El recadero, otra vez. Tome. A este paso me toca bautizarlo."]],
}
const NO_OTRA_VEZ := [["", "(Ese ya le dijo que no la otra vez. Lukas lo intenta igual: los perros no creen en antecedentes.)"]]
## La segunda vez en adelante, la entrada es corta (y cambia).
const ENTRADA_OTRA := [
	["(Otra vez el cartón en la cara. Otra vez el cuerpo que dice que no.)", "(Lukas ya conoce el procedimiento. Se estira, bosteza y sale a trabajar.)"],
	["(No se levanta. Lukas le revisa los bolsillos con la nariz: nada. Lo de siempre.)", "(Lukas suspira como un empleado público y se pone de pie.)"],
	["(El cartón no se mueve. Lukas le ladra una vez, por protocolo.)", "(Después sale a la calle. Hoy el que trae la comida es el perro. Otra vez.)"],
]
const OTRA_VEZ := [["", "(Ya le dieron lo que había. Lukas lo sabe, pero lo intenta otra vez, por si cambió el mundo.)"]]
const SOLO := [
	"(Lukas ladra. Nadie le contesta. Un perro de otra cuadra sí, pero eso es otro tema.)",
	"(Lukas olfatea el piso. Encuentra un chicle viejo y una moneda de cincuenta. Ninguno se come.)",
	"(Lukas ladra hacia arriba, a una ventana. La ventana no baja.)",
]

var player: Node2D
var lukas: Node2D
var _cam: Camera2D
var _carry := ""
var _carry_spr: Sprite2D
var _asked := {}
var _busy := true
var _cool := 0.0


## Lo llama Player cuando entra a un lugar: arranca si hoy es el día y Lukas está.
static func maybe_start(scene: Node) -> void:
	if scene == null:
		return
	var f := GameState.flags
	if int(f.get("no_se_levanta", -1)) != GameState.day or int(f.get("no_se_levanta_hecho", -1)) == GameState.day:
		return
	if TimeManager.hour() >= HASTA or not GameState.lukas_alive():
		return
	var p := scene.get_tree().get_first_node_in_group("player") as Node2D
	var l := scene.find_child("Lukas", true, false) as Node2D
	if p == null or l == null or not "manda" in l:
		return
	f["no_se_levanta_hecho"] = GameState.day
	var m := LukasManda.new()
	m.name = "LukasManda"
	m.player = p
	m.lukas = l
	scene.add_child(m)


func _ready() -> void:
	GameState.flags["lukas_manda"] = true
	player.act("en_el_piso")
	while SceneRouter.busy or Dialogue.active:
		await get_tree().process_frame
	var veces := int(GameState.flags.get("lukas_manda_veces", 0))
	GameState.flags["lukas_manda_veces"] = veces + 1
	if veces == 0:
		await Dialogue.talk([
			["", "(No se levanta. Se tapa la cara con el cartón. Anoche se acostó sin comer, y hoy el cuerpo dijo que no.)"],
			["", "(Lukas le lame la oreja. Nada. Le jala la manga. Nada. Lukas se sienta y lo piensa.)"],
			["", "(Lo piensa poquito: es un perro. Pero lo piensa bien.)"],
			["", Controls.keys_in("Hoy manda LUKAS. Las flechas: caminar. E: pedirle a alguien. Hay que traerle algo de comer antes de mediodía.")],
		])
	else:
		var e: Array = ENTRADA_OTRA[(veces - 1) % ENTRADA_OTRA.size()]
		await Dialogue.talk([["", e[0]], ["", e[1]], ["", Controls.keys_in("Manda LUKAS. E: pedirle a alguien. Antes de mediodía.")]])
	_cam = Camera2D.new()
	_cam.position = Vector2(0, -7)
	_cam.position_smoothing_enabled = true
	_cam.position_smoothing_speed = 8.0
	lukas.add_child(_cam)
	_cam.make_current()
	lukas.manda = true
	_busy = false


func _process(delta: float) -> void:
	if Dialogue.active or SceneRouter.busy:
		_cool = 0.35  # (la tecla que cierra un diálogo no es un pedido nuevo)
		return
	_cool -= delta
	if _busy or _cool > 0.0 or not is_instance_valid(lukas) or not is_instance_valid(player):
		return
	if TimeManager.hour() >= HASTA:
		_solo()
		return
	if _carry != "" and lukas.global_position.distance_to(player.global_position) < 20.0:
		_deliver()
		return
	if Input.is_action_just_pressed("interact"):
		_ask()


## Lukas le pide a quien tenga más cerca (o ladra al aire).
func _ask() -> void:
	var best: Node2D = null
	var best_d := REACH
	for n in get_tree().current_scene.find_children("*", "NPC", true, false):
		var d: float = (n as Node2D).global_position.distance_to(lukas.global_position)
		if d < best_d:
			best_d = d
			best = n
	_busy = true
	lukas.sprite.play("sit")
	if best == null:
		lukas.sprite.play("bark")
		await Dialogue.talk([["", GameState.rota("lukas_solo", SOLO)]])
		_busy = false
		return
	var id: String = str(best.get("npc_id"))
	if _asked.has(id) or _carry != "":
		await Dialogue.talk(OTRA_VEZ if _carry == "" else [["", "(Lukas ya tiene algo en la boca. No se puede pedir con la boca llena: lo aprendió de él.)"]])
		_busy = false
		return
	_asked[id] = true
	var spec: Dictionary = PIDE.get(id, {"da": "", "lines": [["", "(Lo mira. Lukas lo mira. No pasa nada. Los perros saben cuándo no.)"]]})
	var antes: Dictionary = GameState.flags.get("lukas_pidio", {})
	var lines: Array = spec["lines"]
	if antes.has(id):  # ya le pidió otro día
		lines = REPITE.get(id, NO_OTRA_VEZ)
	antes[id] = true
	GameState.flags["lukas_pidio"] = antes
	await Dialogue.talk(lines)
	if str(spec["da"]) != "":
		_take(str(spec["da"]))
	_busy = false


## Se lo lleva en la boca: se ve.
func _take(item: String) -> void:
	_carry = item
	_carry_spr = Sprite2D.new()
	_carry_spr.texture = Items.icon(item)
	_carry_spr.scale = Vector2(0.5, 0.5)
	_carry_spr.position = Vector2(-9, -9)
	lukas.add_child(_carry_spr)
	Narrator.say("(Lukas se lo lleva en la boca, con cuidado de no comérselo. Le cuesta. Se le nota.)")


func _deliver() -> void:
	_busy = true
	lukas.manda = false
	lukas.sprite.play("sit")
	if _carry_spr:
		_carry_spr.queue_free()
	var nombre: String = {"arepa": "la arepa", "empanada": "la empanada", "pan": "el pan"}.get(_carry, "lo que trae")
	await Dialogue.talk([["", "(Lukas le pone %s al lado de la cara y le da un empujoncito con la nariz. Se sienta. Espera.)" % nombre]])
	await player.act("levantarse")
	player.act("comer", false, "mastica")
	await Dialogue.talk([
		["", "(Se sienta y come. Lukas mira cada mordisco como si fuera el suyo.)"],
		["", "(El último pedazo es para Lukas. Siempre fue así. Hoy, con más razón.)"],
	])
	GameState.set_hunger(GameState.hunger + float(Items.info(_carry).get("food", 25)))
	GameState.change_mood(10.0)
	GameState.flags["lukas_fed_day"] = GameState.day
	_end()


func _solo() -> void:
	_busy = true
	lukas.manda = false
	if _carry_spr:
		_carry_spr.queue_free()
	await Dialogue.talk([["", "(Mediodía. El sol le pega en la cara y se tiene que levantar. Lukas llega con la boca vacía y la cola baja.)"],
		["", "(Le rasca detrás de la oreja. No era culpa de nadie. Bueno: era culpa del hambre.)"]])
	await player.act("levantarse")
	_end()


func _end() -> void:
	GameState.flags.erase("lukas_manda")
	if is_instance_valid(lukas):
		lukas.manda = false
		lukas.state = "follow"
	var pcam := player.get_node_or_null("Camera2D") as Camera2D
	if pcam:
		pcam.make_current()
	if _cam:
		_cam.queue_free()
	player.act_stop()
	queue_free()


func _exit_tree() -> void:
	GameState.flags.erase("lukas_manda")  # (si cambia la escena a mitad, que no quede trabado)
