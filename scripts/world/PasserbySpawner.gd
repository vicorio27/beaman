extends Node
## Hace pasar gente por las veredas (Passerby.gd) en los lugares de afuera, de día.
## Los carriles de cada lugar están acá (de punta a punta de cada vereda).

const LANES := {
	"City": [
		[Vector2(-10, 218), Vector2(970, 218)],
		[Vector2(-10, 282), Vector2(970, 282)],
		[Vector2(438, 290), Vector2(438, 650)],
		[Vector2(506, 290), Vector2(506, 650)],
		[Vector2(520, 396), Vector2(760, 486)],
	],
	"Centro": [
		[Vector2(-10, 198), Vector2(650, 198)],
		[Vector2(-10, 290), Vector2(650, 290)],
		[Vector2(-10, 346), Vector2(650, 352)],
	],
	"Parque": [
		[Vector2(-10, 312), Vector2(780, 312)],
		[Vector2(400, 214), Vector2(400, 420)],
		[Vector2(-10, 424), Vector2(780, 424)],
		[Vector2(-10, 196), Vector2(780, 196)],
	],
}
const MAX := {"City": 4, "Centro": 6, "Parque": 5}
const ROWS := [0, 3, 6, 9, 12, 15]

var _lanes: Array = []
var _timer := 2.0
var _world: Node


func _ready() -> void:
	var scene := get_parent()
	_lanes = LANES.get(scene.name, [])
	_world = scene.get_node_or_null("World")


func _process(delta: float) -> void:
	if _lanes.is_empty() or _world == null or GameState.ui_open:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(2.5, 5.0)
	var h := TimeManager.hour()
	if h < 7 or h >= 20:
		return
	if get_tree().get_nodes_in_group("passersby").size() >= MAX.get(get_parent().name, 3):
		return
	var lane: Array = _lanes.pick_random()
	var p := Passerby.new()
	p.add_to_group("passersby")
	var flip := randf() < 0.5
	p.path_from = lane[1] if flip else lane[0]
	p.path_to = lane[0] if flip else lane[1]
	p.speed = randf_range(18.0, 30.0)
	p.row = ROWS.pick_random()
	_world.add_child(p)
