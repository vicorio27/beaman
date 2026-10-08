extends "res://scripts/dreams/Plomo.gd"
## PLOMO 2: "La Empresa". Retoma donde terminó el episodio 1: la SALIDA de la mansión de
## Lisandro no daba a la calle, daba a una oficina. Él ya es adulto (corbata, treinta y pico).
## Recepción → oficina abierta (cubículos) → Recursos Humanos (mini jefa: tiene la tarjeta) →
## la oficina de José Mario Camilo, el jefe que le contó a toda la empresa lo de las drogas.
## Enemigos: oficinistas (tiran tazas), guardas de seguridad, los de Recursos Humanos (reportan).
## Al final, la SALIDA da a un pasillo blanco que huele a hospital (episodio 3).


func setup() -> void:
	dream_id = "plomo2"
	dream_hard = 0.3
	title_text = "PLOMO 2"
	subtitle = "EPISODIO 2: LA EMPRESA"
	recap = [
		["", "ANTERIORMENTE EN PLOMO..."],
		["", "Tenía diez años y mataba demonios. Lisandro cayó."],
		["", "La SALIDA de la mansión no daba a la calle. Daba a una oficina."],
		["", "Ahora tiene treinta y pico, corbata y una tarjeta de acceso que no abre nada."],
	]
	weapon_prefix = "w_"
	face_prefix = "face_"
	drawn_sky = false
	ceil_cols = [Color(0.5, 0.5, 0.48), Color(0.66, 0.66, 0.62)]      # techo de placas
	floor_cols = [Color(0.16, 0.18, 0.26), Color(0.3, 0.33, 0.42)]    # alfombra gris azulada
	wall_tex = {"#": "oficina", "V": "vidrio", "A": "ascensor", "M": "caoba", "F": "archivo",
		"D": "puerta", "L": "puerta_llave", "E": "salida"}
	kinds = {
		"oficinista": {"hp": 25, "speed": 1.5, "range": 8.0, "dmg": 8, "cd": 1.6, "attack": "throw:taza", "h": 0.8},
		"guarda": {"hp": 45, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.82},
		"rrhh": {"hp": 20, "speed": 2.1, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.8},
		"rrhh_jefa": {"hp": 180, "speed": 1.6, "range": 8.0, "dmg": 9, "cd": 1.5, "attack": "fan:papel", "h": 0.95, "sprite": "rrhh"},
		"josemario": {"hp": 450, "speed": 1.2, "range": 11.0, "dmg": 9, "cd": 1.2, "attack": "fan:chisme", "h": 1.3},
	}
	pickup_tex = {"balas": "balas", "cartuchos": "cartuchos", "empanada": "empanada", "aguapanela": "aguapanela",
		"chaleco": "chaleco", "llave": "tarjeta", "escopeta": "escopeta", "caneca": "planta"}
	projectile_tex = ["taza", "chisme", "papel"]
	mini_kind = "rrhh_jefa"
	boss_kind = "josemario"
	summon_kind = "guarda"
	finish_note = "(secretos: todos. Esta oficina vive de eso)"
	lines = {
		"start": "Lunes. En este sueño siempre es lunes.",
		"mini_wake": "RECURSOS HUMANOS: —Tenemos que hablar de su... situación.",
		"mini_half": "RECURSOS HUMANOS: —Esto queda en su hoja de vida.",
		"mini_die": "RECURSOS HUMANOS: —Tome la tarjeta. Igual nadie lo quiere aquí.",
		"boss_wake": "JOSE MARIO: —¡Ah, usted! Pase, pase. Justo estábamos hablando de usted.",
		"boss_p1": "JOSE MARIO: —Yo solo conté la verdad. ¿O no consumía?",
		"boss_p2": "JOSE MARIO: —Aquí todos saben. Todos. Hasta el de los tintos.",
		"boss_die": "JOSE MARIO: —Usted no era el problema. Yo necesitaba uno.",
		"boss_reply": "Y yo necesitaba un jefe. A los dos nos tocó lo que no pedimos.",
		"key_use": "La tarjeta abre la oficina del jefe. Por fin una tarjeta que sirve para algo.",
		"locked": "Acceso restringido. La tarjeta la tiene Recursos Humanos. Como todo.",
		"exit_wait": "SALIDA. Todavía no: él sigue hablando de mí.",
		"alert": "(—¡Voy a reportar esto! Recursos Humanos te vio.)",
		"vest": "Un chaleco reflectivo. Ahora soy visible. Justo lo que no quería.",
		"shotgun": "Una escopeta en una oficina. Por fin una reunión que va a ser corta.",
		"no_ammo": "Sin balas. Como mi nómina.",
	}


func _build_map() -> void:
	super._build_map()
	# Mismo plano que el episodio 1, otro edificio: se cambian las paredes.
	var swap := {"#": "#", "C": "V", "Z": "F", "W": "F", "G": "M"}
	for y in grid.size():
		for x in grid[y].size():
			var c: String = grid[y][x]
			if swap.has(c):
				grid[y][x] = swap[c]
	for x in range(1, 9):
		grid[23][x] = "A" if x % 3 == 0 else "#"  # ascensores en la recepción
	for x in range(10, 21):
		grid[0][x] = "V"  # ventanales a la ciudad


func _place() -> void:
	var list := [
		["oficinista", 3.5, 14.5], ["oficinista", 6.5, 9.5], ["rrhh", 2.5, 3.5],
		["guarda", 15.5, 3.5], ["guarda", 19.5, 15.5], ["oficinista", 11.5, 10.5], ["oficinista", 19.5, 21.5],
		["rrhh", 11.5, 19.5], ["oficinista", 16.5, 8.5], ["oficinista", 12.5, 13.5],
		["oficinista", 23.5, 9.5], ["guarda", 29.5, 2.5], ["oficinista", 25.5, 1.5], ["rrhh_jefa", 28.5, 5.5],
		["josemario", 27.5, 17.5],
	]
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["balas", 7.5, 19.5], ["empanada", 1.5, 8.5], ["caneca", 7.5, 2.5], ["caneca", 1.5, 15.5],
			["escopeta", 15.5, 12.5], ["cartuchos", 11.5, 2.5], ["aguapanela", 19.5, 2.5], ["chaleco", 12.5, 21.5],
			["balas", 19.5, 11.5], ["caneca", 15.5, 18.0], ["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5],
			["balas", 22.5, 13.5], ["cartuchos", 22.5, 21.5], ["empanada", 29.5, 21.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})


func _on_exit() -> void:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await Dialogue.talk([
		["", "La SALIDA no da a la calle. Da a un pasillo blanco."],
		["", "Huele a alcohol de hospital. Un altoparlante dice su nombre completo. Lo dice mal."],
		["", "EPISODIO 2 COMPLETO. Continuará."],
	])
	_finish()
