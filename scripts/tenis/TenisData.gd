class_name TenisData
extends RefCounted
## Los datos del torneo, aparte del motor (como Items.DEFS o Quests.DEFS): los formatos de partido, la
## física, los tipos de golpe y los jugadores. Agregar un jugador es agregar una entrada en PLAYERS
## (y, si trae habilidad, una en TenisAbilities.DEFS): el motor no se toca.

## Formatos: el arcade (un set a 4 juegos, desempate 3-3, como el Fast4) y el de verdad.
const FORMATS := {
	"arcade": {"games_per_set": 4, "tiebreak_at": 3, "tiebreak_points": 7, "sets_to_win": 1, "no_ad": false},
	"corto": {"games_per_set": 2, "tiebreak_at": 1, "tiebreak_points": 5, "sets_to_win": 1, "no_ad": true},
	"real": {"games_per_set": 6, "tiebreak_at": 6, "tiebreak_points": 7, "sets_to_win": 2, "no_ad": false},
}

## La cancha (metros): la de singles. y > 0 es la mitad de abajo (el jugador 0); la red, en y = 0.
const HALF_W := 4.115
const HALF_L := 11.885
const SERVICE_L := 6.40
const NET_H := 0.95
const GRAVITY := 9.8
const DRAG := 0.06

## Los golpes: [velocidad base (m/s), cuánto suma la potencia, efecto (+ liftado, - cortado), margen
## sobre la red (m), qué atributo manda en la precisión ("precision" o "touch"), qué tan lejos cae].
const SHOTS := {
	"drive": {"speed": 21.0, "power_k": 1.6, "spin": 0.45, "net_margin": 0.45, "skill": "precision", "depth": 0.8},
	"slice": {"speed": 15.0, "power_k": 0.6, "spin": -0.6, "net_margin": 0.30, "skill": "touch", "depth": 0.75},
	"lob": {"speed": 11.0, "power_k": 0.3, "spin": 0.3, "net_margin": 3.0, "skill": "touch", "depth": 0.85},
	"drop": {"speed": 7.5, "power_k": 0.2, "spin": -0.8, "net_margin": 0.35, "skill": "touch", "depth": 0.22},
	"serve": {"speed": 24.0, "power_k": 2.6, "spin": 0.25, "net_margin": 0.15, "skill": "precision", "depth": 0.0},
	"underarm": {"speed": 8.0, "power_k": 0.1, "spin": -0.7, "net_margin": 0.3, "skill": "touch", "depth": 0.0},
}

## Los jugadores. Atributos de 1 a 10: power, precision, defense (velocidad y alcance), touch,
## composure (presión y frustración), chaos (variación: engaña, pero también falla más).
## "ai": cómo decide la máquina (pesos de los golpes, cuánto arriesga, dónde se para).
const PLAYERS := {
	"base": {"name": "Jugador", "short": "JUG", "color": Color(0.85, 0.85, 0.9), "hand": "right",
		"attr": {"power": 5, "precision": 5, "defense": 5, "touch": 5, "composure": 5, "chaos": 3},
		"ai": {"shots": {"drive": 1.0, "slice": 0.35, "lob": 0.15, "drop": 0.06}, "risk": 0.5, "home_depth": 0.6, "net": 0.1},
		"ability": ""},
	# El agente del caos: lo raro (dejadas, saque por abajo, el amague) le da puntos; repetirlo le
	# sube el error, y el peloteo largo y normal lo aburre.
	"bublikov": {"name": "Alexander Bublikov", "short": "BUB", "color": Color(0.55, 0.75, 0.95), "hand": "right",
		"title": "El agente del caos",
		"attr": {"power": 9, "precision": 6.75, "defense": 7, "touch": 9, "composure": 6, "chaos": 8},
		"traits": {"trick_tax": 0.15, "boredom": 0.02, "underarm": 0.35},
		"ai": {"shots": {"drive": 1.0, "slice": 0.7, "lob": 0.3, "drop": 0.22}, "risk": 0.7, "home_depth": 0.5,
			"return_depth": 0.8, "style": {"drop": 0.08}},
		"ability": "por_que_no"},
	# La artillería: pegada de fondo, parada adentro. Corriendo de lado, o con bolas bajas o altas,
	# se le descuadra.
	"sabalenkova": {"name": "Aryna Sabalenkova", "short": "SAB", "color": Color(0.95, 0.5, 0.6), "hand": "right",
		"title": "La artillería",
		"attr": {"power": 10, "precision": 5.75, "defense": 5, "touch": 3, "composure": 5, "chaos": 3},
		"traits": {"lateral_tax": 0.3},
		"ai": {"shots": {"drive": 1.0, "slice": 0.12, "lob": 0.05, "drop": 0.03}, "risk": 0.75, "home_depth": 0.95,
			"return_depth": 0.0, "style": {"drive": 0.1}},
		"ability": "demolicion"},
	# El acróbata: llega a todo y se tira por lo que no llega, pero se cansa más que nadie y resta
	# desde la tribuna (el saque por abajo lo mata).
	"monfiz": {"name": "Gaël Monfiz", "short": "MON", "color": Color(0.95, 0.85, 0.35), "hand": "right",
		"title": "El acróbata",
		"attr": {"power": 6, "precision": 4.75, "defense": 9, "touch": 6, "composure": 6, "chaos": 6},
		"traits": {"drain": 0.3},
		"ai": {"shots": {"drive": 1.0, "slice": 0.25, "lob": 0.7, "drop": 0.08}, "risk": 0.45, "home_depth": 0.35,
			"return_depth": 2.6, "style": {"lob": 0.13}},
		"ability": "gravedad"},
	# El devorador de esperanzas: devuelve todo, resta mejor que nadie y bajo presión no se cae. Lo
	# que lo gana es la variedad: el que le repite, le da de comer.
	"yokovich": {"name": "Novak Yokovich", "short": "YOK", "color": Color(0.9, 0.3, 0.3), "hand": "right",
		"title": "El devorador de esperanzas",
		"attr": {"power": 3, "precision": 5, "defense": 6, "touch": 3, "composure": 7, "chaos": 3},
		"traits": {"return_k": 0.93},
		"ai": {"shots": {"drive": 1.0, "slice": 0.6, "lob": 0.15, "drop": 0.1}, "risk": 0.5, "home_depth": 0.55,
			"return_depth": 0.5, "style": {"slice": 0.05}},
		"ability": "todavia_no"},
	# El provocador: cambia el ritmo, deja, corta, y se queja de todo. Cuando no manda, se pierde.
	"moutette": {"name": "Corentin Moutette", "short": "MOU", "color": Color(0.5, 0.78, 0.95), "hand": "left",
		"title": "El provocador",
		"attr": {"power": 5, "precision": 7, "defense": 6, "touch": 9, "composure": 5, "chaos": 8},
		"traits": {"rhythm_need": 0.1},
		"ai": {"shots": {"drive": 1.0, "slice": 0.8, "lob": 0.3, "drop": 0.6}, "risk": 0.55, "home_depth": 0.5,
			"return_depth": 0.6, "style": {"drop": 0.08, "slice": 0.04}},
		"ability": "queja"},
	# El showman: ataque y público. Un ganador lo prende; si se lo neutralizan, se apaga.
	"tiafuego": {"name": "Frances Tiafuego", "short": "TIA", "color": Color(0.6, 0.9, 0.35), "hand": "right",
		"title": "El showman",
		"attr": {"power": 5, "precision": 4.5, "defense": 4, "touch": 6, "composure": 4, "chaos": 5},
		"traits": {},
		"ai": {"shots": {"drive": 1.0, "slice": 0.25, "lob": 0.1, "drop": 0.1}, "risk": 0.75, "home_depth": 0.7,
			"return_depth": 0.3, "style": {"drive": 0.08}, "wide": 0.1},
		"ability": "vamos"},
	# El lanzacohetes: zurdo, el saque más rápido del torneo. El segundo saque y la defensa, flojos.
	"sheltron": {"name": "Ben Sheltron", "short": "SHE", "color": Color(0.98, 0.6, 0.25), "hand": "left",
		"title": "El lanzacohetes",
		"attr": {"power": 10, "precision": 5.75, "defense": 5, "touch": 4, "composure": 5, "chaos": 4},
		"traits": {"second_tax": 0.25, "defense_tax": 0.25},
		"ai": {"shots": {"drive": 1.0, "slice": 0.2, "lob": 0.08, "drop": 0.05}, "risk": 0.7, "home_depth": 0.8,
			"return_depth": 0.2, "style": {"drive": 0.1}, "wide": 0.14},
		"ability": "llamada"},
	# El volátil: todo el talento, cero paciencia. Se prende, y si el punto se alarga, se calienta.
	"kyrgistan": {"name": "Nick Kyrgistán", "short": "KYR", "color": Color(0.9, 0.25, 0.3), "hand": "right",
		"title": "El volátil",
		"attr": {"power": 8, "precision": 4, "defense": 5, "touch": 6, "composure": 2, "chaos": 7},
		"traits": {},
		"ai": {"shots": {"drive": 1.0, "slice": 0.3, "lob": 0.1, "drop": 0.3}, "risk": 0.8, "home_depth": 0.6,
			"return_depth": 0.4, "style": {"drive": 0.05, "drop": 0.1}},
		"ability": "modo_k"},
	# El compilador: profundo, limpio, siempre igual. Lo que lo saca es que le cambien la secuencia.
	"pecador": {"name": "Jannik Pecador", "short": "PEC", "color": Color(0.98, 0.55, 0.3), "hand": "right",
		"title": "El compilador",
		"attr": {"power": 6, "precision": 6.75, "defense": 6, "touch": 4, "composure": 8, "chaos": 1},
		"traits": {},
		"ai": {"shots": {"drive": 1.0, "slice": 0.15, "lob": 0.05, "drop": 0.03}, "risk": 0.45, "home_depth": 0.6,
			"return_depth": 0.4, "style": {"drive": 0.12}, "depth": 0.08},
		"ability": "ejecucion"},
	# El artista: toque, cortado, cambio de ritmo y la subida a la red. Apurado y por el revés, sufre.
	"fedorer": {"name": "Roger Fedorer", "short": "FED", "color": Color(0.95, 0.95, 0.92), "hand": "right",
		"title": "El artista",
		"attr": {"power": 6, "precision": 4.5, "defense": 6, "touch": 10, "composure": 6, "chaos": 4},
		"traits": {"backhand_tax": 0.45},
		"ai": {"shots": {"drive": 1.0, "slice": 0.6, "lob": 0.15, "drop": 0.25}, "risk": 0.6, "home_depth": 0.65,
			"return_depth": 0.3, "style": {"slice": 0.06, "drop": 0.03}},
		"ability": "firma"},
}

## Los del torneo, en el orden del selector.
const ROSTER := ["bublikov", "sabalenkova", "monfiz", "yokovich", "moutette", "tiafuego", "sheltron", "kyrgistan",
	"pecador", "fedorer"]

## Dificultad de la máquina: no le cambia los atributos; le cambia qué tan rápido reacciona, qué tan
## bien decide, qué tan limpio ejecuta y qué tan seguido le juega la contra a la habilidad del otro.
const DIFFICULTY := {
	"facil": {"react": 0.32, "decide_noise": 0.45, "exec": 1.35, "counter": 0.0},
	"normal": {"react": 0.2, "decide_noise": 0.25, "exec": 1.1, "counter": 0.5},
	"dificil": {"react": 0.12, "decide_noise": 0.1, "exec": 1.0, "counter": 0.9},
}


static func player(id: String) -> Dictionary:
	return PLAYERS.get(id, PLAYERS["base"])
