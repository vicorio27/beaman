class_name FinalRush
## El sueño final ("LA SERPIENTE"): antes de llegar a Lilato, la galería de revanchas. Todos los
## jefes otra vez, cada uno con una vuelta en su mecánica, uno detrás del otro (perder = se repite
## esa pelea; no hay despertarse). Después, el final: los policías, el operativo y la serpiente.
## Cada motor pregunta FinalRush.is_step("<clave>") para saber si está en la revancha.

const ORDER := [
	["brenda", "res://scenes/dreams/Callejon3.tscn", "REVANCHA: BRENDA"],
	["guillermo", "res://scenes/dreams/PeleaGuillermo.tscn", "REVANCHA: GUILLERMO"],
	["carrera", "res://scenes/dreams/Carrera3.tscn", "REVANCHA: LOS DOS"],
	["sigilo", "res://scenes/dreams/Sigilo4.tscn", "REVANCHA: JOSE MARIO"],
	["lucha", "res://scenes/dreams/Lucha4.tscn", "REVANCHA: MAURICIO"],
	["lisandro", "res://scenes/dreams/PlomoDealer3.tscn", "REVANCHA: LISANDRO"],
	["final", "res://scenes/dreams/FinalCallejon.tscn", "LA SERPIENTE"],
]


static func active() -> bool:
	return GameState.flags.get("final_rush", false)


static func is_step(key: String) -> bool:
	return active() and ORDER[clampi(int(GameState.flags.get("final_rush_step", 0)), 0, ORDER.size() - 1)][0] == key


## Empieza el sueño final (desde la noche o desde el menú SUEÑOS).
static func begin() -> void:
	GameState.flags["final_rush"] = true
	GameState.flags["final_rush_step"] = 0
	SceneRouter.go(ORDER[0][1], "", ORDER[0][2])


## La revancha se ganó: la siguiente.
static func next() -> void:
	var step := int(GameState.flags.get("final_rush_step", 0)) + 1
	GameState.flags["final_rush_step"] = step
	var tree := Engine.get_main_loop() as SceneTree
	while SceneRouter.busy:
		await tree.process_frame
	SceneRouter.go(ORDER[step][1], "", ORDER[step][2])


## Se perdió: la misma pelea otra vez.
static func retry() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	tree.reload_current_scene()


static func finish() -> void:
	GameState.flags.erase("final_rush")
	GameState.flags.erase("final_rush_step")
