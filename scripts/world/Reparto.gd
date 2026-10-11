extends "res://scripts/world/MotoRide.gd"
## RAPIDITO: un pedido en bicicleta (alquilada a Yeison). Mismo motor que el recuerdo de la moto:
## esquivar el tráfico y los huecos y llegar al cliente. Paga $5.000 y propina según el tiempo; cada
## golpe aplasta el pedido (menos propina). Si pasa del tiempo límite, el cliente cancela.
## Cada pedido se juega distinto (los cuatro primeros salen en orden; después, al azar):
##   hamburguesa: normal.
##   sushi: frágil. Cada golpe cuesta el triple de propina, pero hay más tiempo.
##   medicamentos: urgente. Menos tiempo y más propina; el cliente llama a mitad de camino.
##   torta: no se puede ir a fondo. Más de 80% de velocidad un rato y la torta se ladea (cuenta como golpe).

const PAY := 5000
const LIMIT := 75.0
## [pedido, línea de la mitad, tipo, tiempo límite, propina rápida, costo por golpe, [rápido, a tiempo]]
## (una vuelta limpia: ~43 s a fondo; ~54 s con la torta, sin pasar del 80%)
const ORDERS := [
	["Hamburguesa doble. Con todo.", "El cliente puso en la app: \"Rápido, que tengo hambre\". Él también, señor. Él también.", "", 75.0, 3000, 500, [50.0, 62.0]],
	["Sushi. FRÁGIL. Para una persona que pidió para dos.", "Lo lleva con cuidado. Cuesta lo que él se gana en tres días. Cada hueco le duele en el arroz.", "sushi", 90.0, 4000, 1500, [58.0, 72.0]],
	["Medicamentos. URGENTE.", "El cliente llama: \"¿Ya viene? Es para mi mamá\". En la caja va el remedio de alguien. Pedalea distinto.", "remedio", 58.0, 6000, 500, [47.0, 53.0]],
	["Una torta de cumpleaños. NO CORRA.", "\"Feliz cumpleaños, mi amor\", dice. Pedalea sin pensar en ningún cumpleaños. No le sale.", "torta", 85.0, 4000, 1000, [62.0, 72.0]],
]
const TORTA_SPEED := 0.8
const TORTA_TIME := 1.6

var order: Array = []
var _cancelled := false
var _limit := LIMIT
var _torta := 0.0  # cuánto se viene ladeando la torta


## El pedido de hoy: los cuatro primeros en orden (cada uno se juega distinto); después, al azar.
func _pick_order() -> Array:
	var n := int(GameState.flags.get("reparto_n", 0))
	return ORDERS[n] if n < ORDERS.size() else ORDERS[randi() % ORDERS.size()]


func setup() -> void:
	order = _pick_order()
	_limit = order[3]
	sky_top = Color(0.45, 0.62, 0.85)
	sky_low = Color(0.82, 0.9, 0.95)
	haze = Color(0.8, 0.86, 0.9)
	hills = [Color(0.45, 0.55, 0.45), Color(0.38, 0.5, 0.4)]
	sun = true
	start_line = "RAPIDITO: Pedido #%d. %s" % [4000 + randi() % 999, order[0]]
	half_line = order[1]
	goal_label = "EL CLIENTE"


func _ready() -> void:
	super._ready()
	_bike = {-1: load("res://assets/moto/bici_l.png"), 0: load("res://assets/moto/bici_c.png"), 1: load("res://assets/moto/bici_r.png")}


func _countdown() -> void:
	MusicDirector.force("")
	await get_tree().create_timer(0.6).timeout
	await super._countdown()


func _ride(dt: float) -> void:
	super._ride(dt)
	if order[2] == "torta" and state == "ride":
		if speed > MAX_SPEED * TORTA_SPEED:
			_torta += dt
			if _torta > TORTA_TIME * 0.5:
				_hud_center.text = "¡LA TORTA!" if int(time * 6) % 2 == 0 else ""
		else:
			_torta = maxf(0.0, _torta - dt * 1.5)
			if _hud_center.text == "¡LA TORTA!" or _hud_center.text == "":
				_hud_center.text = ""
		if _torta > TORTA_TIME:
			_torta = 0.0
			_hud_center.text = ""
			_crash(["La torta se ladeó. Ahora dice \"Feliz cumpl\". El resto está en la tapa.",
				"Otra vez. El muñequito de los novios ya no se casa: se separaron en la curva.",
				"La torta es ahora una torta abstracta. Arte moderno. Vale más."], 0.6)
	if time > _limit and not _cancelled:
		_cancelled = true
		f_reparto_n()
		state = "arrival"
		_hud_center.text = "CANCELADO"
		await get_tree().create_timer(1.0).timeout
		await Dialogue.talk([["RAPIDITO", "—El cliente canceló. Su calificación bajó a 3,2 estrellas."],
			["CLIENTE", "—(Mensaje de voz.) ¡Ni contesta el chat! ¡Una estrella! ¡Media, si se pudiera!"]])
		_back("Ni plata ni propina. La bicicleta, eso sí, la pago igual.")


func _arrival() -> void:
	if _cancelled:
		return
	_engine.stop()
	var tip := 0
	var fast: int = order[4]
	var tiers: Array = order[6]
	if time < tiers[0]:
		tip = fast
	elif time < tiers[1]:
		tip = fast / 2
	tip = maxi(0, tip - crashes * int(order[5]))
	f_reparto_n()
	var pay := PAY + tip
	GameState.add_money(pay)
	var f := GameState.flags
	f["reparto_hoy"] = int(f.get("reparto_hoy", 0)) + 1
	f["reparto_dia"] = GameState.day
	if f.get("trabajo_ultimo", -1) != GameState.day:
		f["trabajo_ultimo"] = GameState.day
		f["trabajo_dias"] = int(f.get("trabajo_dias", 0)) + 1
	TimeManager.skip(1.0)
	GameState.set_hunger(GameState.hunger - 8.0)
	var squashed := "Llegó entero." if crashes == 0 else ("Llegó un poco aplastado. %d golpes." % crashes)
	var who: String = {"sushi": "—¿Esto es sushi o es arroz con sorpresa?" if crashes > 0 else "—Perfecto. Ni un grano fuera de lugar. ¿Usted es japonés?",
		"remedio": "—¡Gracias, gracias! Mi mamá... gracias." if time < order[6][0] else "—Ya llegó. Ya. Gracias.",
		"torta": "—¡Está perfecta! ¡Mi amor, mira!" if crashes == 0 else "—... Bueno. Igual se va a comer."}.get(order[2],
		["—¿Por qué tan demorado?", "—Gracias, joven. ... ¿Ese perro es suyo?", "—Déjelo en la puerta. No me mire."].pick_random())
	await Dialogue.talk([
		["CLIENTE", who],
		["", "%s $%d de pedido y $%d de propina." % [squashed, PAY, tip]],
	])
	_back("(Un pedido. La app ya está pidiendo otro. La app no duerme. Él tampoco.)")


func f_reparto_n() -> void:
	GameState.flags["reparto_n"] = int(GameState.flags.get("reparto_n", 0)) + 1


func _back(line: String) -> void:
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(CITY, "FromCafe", "", line)


func _update_hud() -> void:
	super._update_hud()
	_hud_time.text = "%s/%s" % [_clock(time), _clock(_limit)]  # corto: no tapa la barra
