extends "res://scripts/dreams/Plomo.gd"
## EL SUEÑO FINAL — fase 2 de 3 (PLOMO): EL OPERATIVO. Él, con la armadura de "el que no se muere",
## dentro del operativo que Lilato armó: policías, soldados, el capitán (tiene la llave). Al fondo, con
## un megáfono, ella: dispara denuncias (papeles). Cuando cae, se escapa al río: fase 3 (la serpiente).

const NEXT := "res://scenes/dreams/FinalSerpiente.tscn"


func setup() -> void:
	dream_id = "final"
	dream_hard = 0.5
	title_text = "EL OPERATIVO"
	subtitle = "LA SERPIENTE: FASE 2\\n(lo que ella armó)"
	recap = [
		["", "El sargento cayó. Lilato llamó a todos."],
		["", "Él se pone la armadura verde del sueño de Lisandro. Le queda. Siempre le quedó."],
	]
	weapon_prefix = "sw_"
	face_prefix = "sface_"
	drawn_sky = false
	ceil_cols = [Color(0.03, 0.03, 0.08), Color(0.12, 0.08, 0.2)]
	floor_cols = [Color(0.08, 0.08, 0.1), Color(0.22, 0.2, 0.24)]
	wall_tex = {"#": "ladrillo", "C": "grafiti", "Z": "zinc", "W": "madera", "G": "ladrillo",
		"D": "puerta", "L": "puerta_llave", "E": "salida"}
	kinds = {
		"tombo": {"hp": 45, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.2, "attack": "hitscan", "h": 0.82, "sprite": "dl_tombo"},
		"soldado": {"hp": 60, "speed": 1.8, "range": 10.0, "dmg": 9, "cd": 1.0, "attack": "burst", "h": 0.84, "sprite": "guarda"},
		"campanero": {"hp": 15, "speed": 2.3, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.78, "sprite": "dl_sapo"},
		"capitan": {"hp": 260, "speed": 1.6, "range": 11.0, "dmg": 9, "cd": 1.3, "attack": "burst", "h": 1.15, "sprite": "dl_tombo"},
		"lilato": {"hp": 620, "speed": 1.5, "range": 12.0, "dmg": 9, "cd": 1.0, "attack": "fan:papel", "h": 1.0, "sprite": "lilato"},
	}
	pickup_tex = {"balas": "balas", "cartuchos": "cartuchos", "empanada": "empanada", "aguapanela": "aguapanela",
		"chaleco": "chaleco", "llave": "llave", "escopeta": "escopeta", "caneca": "caneca"}
	projectile_tex = ["papel", "cuchillo"]
	mini_kind = "capitan"
	boss_kind = "lilato"
	summon_kind = "soldado"
	music = "plomo"
	music_boss = "plomo_boss"
	owned = [true, true, true]
	ammo = {"balas": 90, "cartuchos": 20}
	armor = 100.0
	finish_note = "(ella corre hacia el río)"
	lines = {
		"start": "Sirenas. Helicóptero. Reflectores. Todo esto, por un hombre con un perro.",
		"mini_wake": "EL CAPITAN: —Tenemos órdenes. La señora fue muy clara.",
		"mini_half": "EL CAPITAN: —¡Nadie dijo que este se defendía!",
		"mini_die": "EL CAPITAN: —Tome la llave... La señora está adentro. Con el megáfono.",
		"boss_wake": "LILATO: —¡Ahí está! ¡Es él! ¡Está armado! ¡Disparen!",
		"boss_p1": "LILATO: —¡Yo les di la dirección! ¡Y la foto! ¡Y les dije que estaba armado! ¡Hasta los dientes! ¡Lo vi en un estado de WhatsApp!",
		"boss_p2": "LILATO: —¡Era para quedarme con la niña! ¿Qué querías que hiciera?",
		"boss_die": "LILATO: —Esto no se acaba aquí...",
		"boss_reply": "Se arrastra hacia el río. Se le está cayendo la piel. Ya sé qué viene.",
		"key_use": "La llave del capitán. Adentro, el megáfono suena más fuerte.",
		"locked": "Cerrada. El capitán tiene la llave.",
		"exit_wait": "SALIDA. Todavía no: ella sigue gritando.",
		"alert": "(Un sapo pita. Hasta los sapos trabajan para ella.)",
		"vest": "Un chaleco antibalas de la policía. Me queda. Qué ironía tan pesada.",
		"shotgun": "Otra escopeta. Esta vez no tengo miedo de usarla. Es un sueño. Es mi sueño.",
		"no_ammo": "Sin balas. A puño. Como al principio.",
	}


func _place() -> void:
	var list := [
		["tombo", 3.5, 14.5], ["soldado", 6.5, 9.5], ["campanero", 2.5, 3.5],
		["tombo", 15.5, 3.5], ["soldado", 19.5, 15.5], ["tombo", 11.5, 10.5], ["soldado", 19.5, 21.5],
		["campanero", 11.5, 19.5], ["tombo", 16.5, 8.5], ["soldado", 12.5, 13.5], ["tombo", 15.5, 17.5],
		["soldado", 23.5, 9.5], ["tombo", 29.5, 2.5], ["soldado", 25.5, 1.5], ["capitan", 28.5, 5.5],
		["lilato", 27.5, 17.5],
	]
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["balas", 7.5, 19.5], ["empanada", 1.5, 8.5], ["cartuchos", 11.5, 2.5], ["chaleco", 12.5, 21.5],
			["balas", 19.5, 11.5], ["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5], ["balas", 22.5, 13.5],
			["cartuchos", 22.5, 21.5], ["aguapanela", 19.5, 2.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})


## Cuando ella cae, no hay "nivel completo": se escapa al río. La salida lleva a la última fase.
func _on_exit() -> void:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await Dialogue.talk([["", "La SALIDA da al río. El puente del principio. Abajo, en el agua, algo enorme se enrosca."],
		["", "Fase final."]])
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NEXT, "", "LA SERPIENTE")
