class_name Location
extends Node2D
## Raíz de cada lugar jugable de la vida real (la ciudad, la panadería, el café...).
## Ubica al jugador en el punto de entrada, limita la cámara y pone paredes en el borde.
## Además prende el reloj y agrega el HUD, la mochila y los efectos del hambre.

## Tamaño del lugar en píxeles.
@export var area_size := Vector2i(960, 992)
## Marker2D donde aparece el jugador si no viene de otra escena.
@export var default_spawn := "Start"
## Afuera: tiene ciclo de día y noche (DayNight). Adentro, la luz es fija.
@export var outdoor := true

@onready var player: CharacterBody2D = find_child("Player", true, false)


func _ready() -> void:
	var spawn: Node2D = get_node_or_null(SceneRouter.spawn_point)
	if SceneRouter.spawn_point == "" or spawn == null:
		spawn = get_node(default_spawn)
	player.global_position = spawn.global_position
	if spawn.has_meta("facing"):
		player.face(spawn.get_meta("facing"))

	var cam: Camera2D = player.get_node("Camera2D")
	var view := get_viewport_rect().size
	# Si el lugar es más chico que la pantalla, se centra.
	var pad := ((view - Vector2(area_size)) / 2.0).max(Vector2.ZERO)
	cam.limit_left = int(-pad.x)
	cam.limit_top = int(-pad.y)
	cam.limit_right = int(area_size.x + pad.x)
	cam.limit_bottom = int(area_size.y + pad.y)
	cam.reset_smoothing()
	_add_bounds()

	_add_lukas()
	TimeManager.running = true
	var systems := ["res://scripts/ui/Hud.gd", "res://scripts/ui/InventoryUI.gd", "res://scripts/ui/Libreta.gd",
		"res://scripts/systems/Survival.gd"]
	if outdoor:
		systems.append("res://scripts/systems/DayNight.gd")
		systems.append("res://scripts/systems/NightLife.gd")
		systems.append("res://scripts/world/PasserbySpawner.gd")
	for script in systems:
		var n: Node = CanvasLayer.new() if script.contains("/ui/") else Node.new()
		n.set_script(load(script))
		add_child(n)


## Lukas va con él a todos lados de la vida real.
func _add_lukas() -> void:
	if not GameState.lukas_alive():
		return
	var lukas := CharacterBody2D.new()
	lukas.set_script(load("res://scripts/world/Lukas.gd"))
	lukas.name = "Lukas"
	lukas.player = player
	lukas.position = player.position + Vector2(-14, 4)
	player.get_parent().add_child(lukas)


func _exit_tree() -> void:
	TimeManager.running = false
	GameState.ui_open = false


## Paredes invisibles en el borde del lugar.
func _add_bounds() -> void:
	var body := StaticBody2D.new()
	body.name = "Bounds"
	var edges := {
		Vector2.DOWN: Vector2.ZERO,
		Vector2.UP: Vector2(0, area_size.y),
		Vector2.RIGHT: Vector2.ZERO,
		Vector2.LEFT: Vector2(area_size.x, 0),
	}
	for normal in edges:
		var shape := CollisionShape2D.new()
		var line := WorldBoundaryShape2D.new()
		line.normal = normal
		shape.shape = line
		shape.position = edges[normal]
		body.add_child(shape)
	add_child(body)
