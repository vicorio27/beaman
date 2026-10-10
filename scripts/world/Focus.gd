class_name Focus
## De todo lo que el jugador tiene al lado (una persona, una puerta, un servicio, algo para agarrar,
## un lugar para dormir), solo lo más cercano muestra su letrero y responde a la acción. Así nunca
## hay dos letreros encimados ni un botón que haga dos cosas (o la que uno no quería).
## Cada uno se mete al grupo "interactable" y pregunta Focus.mine(self) antes de mostrarse o actuar.

const GROUP := "interactable"


static func mine(node: Node2D) -> bool:
	var player = node.get("_player")
	if player == null or not is_instance_valid(player):
		return false
	var me := node.global_position.distance_squared_to(player.global_position)
	for n in node.get_tree().get_nodes_in_group(GROUP):
		if n == node or not (n is Node2D) or n.get("_player") != player or n.get("concealed") == true:
			continue
		var d: float = n.global_position.distance_squared_to(player.global_position)
		if d < me - 0.01 or (absf(d - me) <= 0.01 and n.get_instance_id() < node.get_instance_id()):
			return false
	return true


## El letrero se ve solo si es el elegido (con alfa, para no pelearse con quien lo prende y apaga).
static func dim(node: Node2D, hint: CanvasItem) -> void:
	if hint:
		hint.modulate.a = 1.0 if node.get("_player") == null or mine(node) else 0.0
