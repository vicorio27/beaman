extends "res://scripts/dreams/Plomo.gd"
## PLOMO 3: "Clínica Irene". Retoma donde terminó el episodio 2: el pasillo blanco que huele a
## hospital. La clínica que filtró sus datos. Urgencias → pasillo (Zaida aparece: no pelea) →
## la sala de espera (Lilato, mini jefa recurrente: tiene la llave) → el Archivo Central, donde lo
## espera El Expediente: un monstruo hecho de su historia clínica.
## Al final Zaida está en la SALIDA: creerle o no (queda en flags.zaida_trust, para más adelante).

const ZAIDA_POS := Vector2(15.5, 12.5)

var _zaida_met := false


func setup() -> void:
	dream_id = "plomo3"
	dream_hard = 0.6
	title_text = "PLOMO 3"
	subtitle = "EPISODIO 3: CLINICA IRENE"
	recap = [
		["", "ANTERIORMENTE EN PLOMO..."],
		["", "José Mario cayó. La salida de la oficina daba a un pasillo blanco."],
		["", "Huele a alcohol. En una pared, un cartel: CLINICA IRENE. SU INFORMACION ESTA SEGURA CON NOSOTROS."],
		["", "Ja."],
	]
	weapon_prefix = "w_"
	face_prefix = "face_"
	drawn_sky = false
	ceil_cols = [Color(0.72, 0.75, 0.75), Color(0.86, 0.88, 0.88)]    # techo blanco de hospital
	floor_cols = [Color(0.28, 0.38, 0.34), Color(0.5, 0.6, 0.55)]     # linóleo verde
	wall_tex = {"#": "clinica", "B": "baldosa", "F": "archivo", "V": "vidrio",
		"D": "puerta", "L": "puerta_llave", "E": "salida_blanca"}
	kinds = {
		"enfermero": {"hp": 32, "speed": 1.9, "range": 0.9, "dmg": 11, "cd": 1.0, "attack": "melee", "h": 0.82},
		"archivista": {"hp": 28, "speed": 1.3, "range": 9.0, "dmg": 9, "cd": 1.7, "attack": "throw:papel", "h": 0.8},
		"guarda": {"hp": 45, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.82},
		"lilato": {"hp": 190, "speed": 1.9, "range": 8.0, "dmg": 10, "cd": 1.6, "attack": "fan:saliva", "h": 0.8},
		"expediente": {"hp": 480, "speed": 1.0, "range": 11.0, "dmg": 10, "cd": 1.1, "attack": "fan:papel", "h": 1.45},
	}
	pickup_tex = {"balas": "balas", "cartuchos": "cartuchos", "empanada": "empanada", "aguapanela": "aguapanela",
		"chaleco": "chaleco", "llave": "llave", "escopeta": "escopeta", "caneca": "planta"}
	projectile_tex = ["papel", "cuchillo", "saliva"]
	mini_kind = "lilato"
	boss_kind = "expediente"
	summon_kind = "enfermero"
	finish_note = "(secretos: el suyo. Ya no.)"
	lines = {
		"start": "Sala de urgencias. Turno: el último. Como siempre.",
		"mini_wake": "LILATO: —¿Aquí también? Siempre llegás tarde a todo.",
		"mini_half": "LILATO: —Ni el siquiatra te va a creer. Ni el sicólogo. Ni el de la P muda.",
		"mini_die": "LILATO: —Tomá la llave. Ya que ahora te querés curar...",
		"boss_wake": "EL EXPEDIENTE: —Paciente masculino. Antecedentes de consumo. Datos: compartidos.",
		"boss_p1": "EL EXPEDIENTE: —Compartidos con terceros. Con una tal Zaida. Sin firma suya.",
		"boss_p2": "EL EXPEDIENTE: —Diagnóstico: no confiable. Pronóstico: reservado. Firma: ilegible.",
		"boss_die": "EL EXPEDIENTE: —Usted no es un expediente... Error. Error. Error.",
		"boss_reply": "No soy un expediente. Soy un tipo con un perro. Ahí está toda la diferencia.",
		"key_use": "La llave abre el Archivo Central. Adentro está todo lo que dijeron de mí.",
		"locked": "ARCHIVO CENTRAL. Cerrado. La llave la tiene alguien en la sala de espera.",
		"exit_wait": "SALIDA. Todavía no: mi expediente sigue abierto.",
		"alert": "(Un enfermero llama por el altoparlante. Vienen más.)",
		"vest": "Una bata de paciente. Abierta atrás. Me protege de todo menos de la vergüenza.",
		"shotgun": "Una escopeta en un hospital. Por lo menos acá curan rápido.",
		"no_ammo": "Sin balas. Ni la EPS cubre esto.",
	}


func _build_map() -> void:
	super._build_map()
	var swap := {"#": "#", "C": "B", "Z": "B", "W": "B", "G": "F"}
	for y in grid.size():
		for x in grid[y].size():
			var c: String = grid[y][x]
			if swap.has(c):
				grid[y][x] = swap[c]
	for x in range(10, 21, 3):
		grid[0][x] = "V"


func _place() -> void:
	var list := [
		["enfermero", 3.5, 14.5], ["enfermero", 6.5, 9.5], ["archivista", 2.5, 3.5],
		["guarda", 15.5, 3.5], ["guarda", 19.5, 15.5], ["archivista", 11.5, 10.5], ["enfermero", 19.5, 21.5],
		["archivista", 11.5, 19.5], ["enfermero", 16.5, 8.5], ["archivista", 18.5, 6.5],
		["enfermero", 23.5, 9.5], ["guarda", 29.5, 2.5], ["archivista", 25.5, 1.5], ["lilato", 28.5, 5.5],
		["expediente", 27.5, 17.5],
	]
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["balas", 7.5, 19.5], ["empanada", 1.5, 8.5], ["caneca", 7.5, 2.5], ["escopeta", 15.5, 14.5],
			["cartuchos", 11.5, 2.5], ["aguapanela", 19.5, 2.5], ["chaleco", 12.5, 21.5], ["balas", 19.5, 11.5],
			["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5], ["balas", 22.5, 13.5], ["cartuchos", 22.5, 21.5],
			["empanada", 29.5, 21.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})


## Zaida, en el pasillo: no pelea. Si se le dispara, no le pasa nada (es un sueño; o es Zaida).
func extra_sprites() -> Array:
	if _zaida_met:
		return []
	return [[ZAIDA_POS, _zaida_tex(), 0.85, 0.0]]


func _zaida_tex() -> Texture2D:
	if not _tex.has("zaida"):
		_tex["zaida"] = load("res://assets/shooter/zaida.png")
	return _tex["zaida"]


func _special(_delta: float) -> void:
	if _zaida_met or pos.distance_to(ZAIDA_POS) > 1.4:
		return
	_zaida_met = true
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await Dialogue.talk([
		["ZAIDA", "—¿Qué hacés acá? Esto no es para vos."],
		["ZAIDA", "—Tomá. Balas. No preguntes de dónde las saqué."],
		["ZAIDA", "—Al fondo está tu expediente. Yo ya lo leí. Todo."],
	])
	ammo["balas"] = mini(200, ammo["balas"] + 25)
	_bonus = 0.4
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## En la SALIDA está Zaida otra vez: creerle o no.
func _on_exit() -> void:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var i := await Dialogue.talk([
		["", "En la SALIDA hay alguien esperando. Zaida."],
		["ZAIDA", "—Yo solo quería ayudarte. Te lo juro."],
	], ["Creerle", "No creerle"])
	GameState.flags["zaida_trust"] = i == 0
	if i == 0:
		await Dialogue.talk([["", "—... Gracias."], ["ZAIDA", "—Nos vemos afuera. Siempre nos vemos."]])
	else:
		await Dialogue.talk([["ZAIDA", "—Está bien. Algún día vas a necesitarme."]])
	await Dialogue.talk([["", "EPISODIO 3 COMPLETO. Fin de la temporada."]])
	_finish()
