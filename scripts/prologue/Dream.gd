class_name Dream
## Estado del sueño de arcade que pasa de una escena a otra (el puntaje).

static var score := 0


static func add(points: int) -> void:
	score += points


static func reset() -> void:
	score = 0
