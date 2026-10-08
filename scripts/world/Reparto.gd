extends "res://scripts/world/MotoRide.gd"
## RAPIDITO: un pedido en bicicleta (alquilada a Yeison). Mismo motor que el recuerdo de la moto:
## esquivar el tráfico y los huecos y llegar al cliente. Paga $5.000 y propina según el tiempo; cada
## golpe aplasta el pedido (menos propina). Si pasa del tiempo límite, el cliente cancela.

const PAY := 5000
const LIMIT := 75.0
const ORDERS := [
	["Hamburguesa doble. Con todo.", "El cliente puso en la app: \"Rápido, que tengo hambre\". Yo también, señor. Yo también."],
	["Sushi. Para una sola persona. Que pidió para dos.", "Lo llevo con cuidado. Cuesta lo que yo me gano en tres días."],
	["Medicamentos. Urgente.", "En la caja va el remedio de alguien. Pedaleo distinto."],
	["Una torta de cumpleaños.", "\"Feliz cumpleaños, mi amor\", dice. Pedaleo sin pensar en ningún cumpleaños. No me sale."],
]

var order: Array = []
var _cancelled := false


func setup() -> void:
	order = ORDERS[randi() % ORDERS.size()]
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
	if time > LIMIT and not _cancelled:
		_cancelled = true
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
	if time < 50.0:
		tip = 3000
	elif time < 62.0:
		tip = 1500
	tip = maxi(0, tip - crashes * 500)
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
	await Dialogue.talk([
		["CLIENTE", ["—¿Por qué tan demorado?", "—Gracias, joven. ... ¿Ese perro es suyo?", "—Déjelo en la puerta. No me mire."].pick_random()],
		["", "%s $%d de pedido y $%d de propina." % [squashed, PAY, tip]],
	])
	_back("Un pedido. La app ya me está pidiendo otro. La app no duerme. Yo tampoco.")


func _back(line: String) -> void:
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(CITY, "FromCafe", "", line)


func _update_hud() -> void:
	super._update_hud()
	_hud_time.text = "%s/%s" % [_clock(time), _clock(LIMIT)]  # corto: no tapa la barra
