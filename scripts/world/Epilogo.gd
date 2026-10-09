extends Node2D
## EPÍLOGO. Él murió después del último sueño. Primero, el entierro: los únicos que lo querían, debajo
## del árbol de flores amarillas del Parque, al lado de Lukas. Después, un recorrido corto por la vida de
## todos los demás: siguen tranquilos, sin enterarse. Al final, Victoria, el día de su cumpleaños.
## Cada cuadro: un lugar dibujado, la gente (los muñecos de la vida real, teñidos) y unas líneas.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const TITLE := "res://scenes/ui/Title.tscn"

## [lugar, título, gente [fila de la hoja, tinte, x, y, escala, mira, (id si tiene hoja propia)], líneas]
const SCENES := [
	["entierro", "PARQUE DE SAN JUDAS", [[12, Color(0.8, 0.75, 0.7), 70, 120, 2.2, "down", "samuel"], [6, Color(1, 0.95, 0.85), 100, 112, 2.2, "down", "german"],
		[15, Color(1, 0.85, 0.9), 130, 118, 2.2, "down", "rosa"], [3, Color(1, 1, 1), 160, 112, 2.2, "down", "marta"], [9, Color(1, 0.95, 0.8), 190, 120, 2.2, "down", "wilson"],
		[6, Color(0.32, 0.3, 0.36), 222, 112, 2.2, "down", "padre"], [3, Color(1, 0.86, 0.72), 250, 120, 2.2, "down", "fabiola"], [15, Color(1, 0.8, 0.86), 280, 114, 2.2, "down", "leonor"],
		[0, Color(0.86, 0.76, 0.62), 40, 132, 2.2, "side", "mono"]],
		[["", "Lo entierran al lado de Lukas, debajo del árbol de flores amarillas. Hace sol. A él le habría parecido un chiste."],
		["SAMUEL", "—Once años en la calle y nunca vi a nadie aguantar tanto riéndose. Ni yo."],
		["DON GERMAN", "—Todos los días le guardaba el pan. Mañana también se lo voy a guardar. No sé hacer otra cosa."],
		["DOÑA ROSA", "—Me debía unas empanadas. Nunca se las cobré. Nunca se las iba a cobrar."],
		["MARTA", "—Era un descarado. Me caía bien. Todavía no sé por qué. Ahora ya no lo voy a saber."],
		["WILSON", "—Le dejo una lata. Él sabía lo que valía. Trescientos. Más que muchos."],
		["PADRE HERNANDO", "—No voy a decir que está en un lugar mejor. Él estaba aprendiendo a estar en este. Eso es más difícil."],
		["DOÑA FABIOLA", "—Le hice sopa. Ya sé. La dejo aquí igual."],
		["DOÑA LEONOR", "—Un clavel. Medio caído. Como a él le gustaban."],
		["", "Don Efraín sienta a Gloria, la muñeca sin un ojo, al lado de la cruz. Que lo mire ella ahora."],
		["", "El Mono toca un bolero. Mal. Con sentimiento. Como él hacía todo."],
		["", "Once personas. Ninguna de su familia. Todas, su familia."]]],
	["cocina", "IBAGUE. LA CASA NUEVA DE BRENDA", [[3, Color(0.75, 0.55, 0.45), 160, 140, 2.6, "side", "brenda"], [0, Color(1, 1, 1), 230, 146, 1.8, "down"]],
		[["", "Brenda revuelve una sopa. La misma. Se la sirve a un niño que no es él."],
		["", "En la radio pasan un bolero. Ella lo tararea. No sabe por qué se le aguan los ojos. Le echa la culpa a la cebolla."]]],
	["garaje", "UN GARAJE. DOMINGO", [[6, Color(0.85, 0.82, 0.76), 130, 140, 2.6, "side", "mauricio"], [12, Color(1, 0.7, 0.55), 210, 142, 2.4, "side", "pecas"]],
		[["", "Mauricio le saca brillo al tanque de la moto. El Pecas le pasa el trapo."],
		["EL PECAS", "—¿Salimos a Melgar, don Mauricio?"],
		["MAURICIO", "—Ahorita. Primero el partido."],
		["", "Es domingo. Mauricio no piensa en ningún hijo. Los domingos nunca pensó."]]],
	["apartamento", "EL APARTAMENTO DE LORENA", [[3, Color(0.85, 0.45, 0.5), 150, 142, 2.6, "side", "lilato"]],
		[["", "Lorena se pinta las uñas de rosado. Siempre rosado. Habla por teléfono con una amiga."],
		["LORENA", "—No, mija, ese ya no aparece. Mejor. ... ¿Y vos qué te vas a poner el sábado?"],
		["", "Afuera llueve. Ella cierra la ventana. No se entera de nada. Nunca se enteró de nada que no le sirviera."]]],
	["oficina", "LA EMPRESA. ULTIMO PISO", [[6, Color(0.6, 0.6, 0.75), 200, 140, 2.6, "side", "josemario"], [9, Color(1, 0.85, 0.6), 110, 144, 2.6, "side", "walter"],
		[12, Color(0.85, 0.7, 0.7), 70, 144, 2.6, "side", "nicolas"], [0, Color(0.8, 0.9, 1.0), 260, 146, 2.4, "side", "eddy"]],
		[["", "José Mario firma un ascenso. El suyo. Walter le trae el tinto. Nicolás grita en el pasillo. Eddy mide la silla con los ojos."],
		["JOSE MARIO", "—Siguiente punto."],
		["", "En el computador, en una carpeta que nadie abre, hay un correo viejo. Con un nombre. Nadie lo va a leer nunca más."]]],
	["esquina", "UNA ESQUINA NUEVA", [[12, Color(1, 1, 0.92), 160, 144, 2.6, "side", "lisandro"], [0, Color(0.7, 0.7, 0.8), 230, 148, 2.0, "down"]],
		[["", "Lisandro cuenta billetes debajo de un poste. Un pelado de doce años le dice \"patrón\"."],
		["", "Se ríe. Tiene la nariz roja. Se le acaba la bolsita. Pide otra. Siempre pide otra."]]],
	["casa_camila", "LA CASA DE GUILLERMO", [[3, Color(1.0, 0.85, 0.4), 120, 140, 2.6, "side", "camila"], [9, Color(0.6, 0.85, 0.6), 230, 142, 2.8, "side", "guillermo"]],
		[["", "Camila llega con bolsas de tres almacenes. Paga la tarjeta de Guillermo. Siempre paga la tarjeta de Guillermo."],
		["", "Guillermo lava la camioneta. Silba. Por un segundo se acuerda de un amigo. Le da una manguerazo más fuerte al rin. Se le pasa."]]],
	["ciudad", "OTRA CIUDAD", [[3, Color(0.75, 0.6, 0.5), 150, 142, 2.6, "side", "diana"]],
		[["", "Diana Carolina trota por un parque de otra ciudad. Tiene audífonos. Tiene otra vida."],
		["", "El celular vibra con una noticia del barrio de antes. No lo mira. Hace tiempo que no mira para atrás."]]],
	["cantina", "LA CANTINA DE SIEMPRE", [[6, Color(1.0, 0.86, 0.5), 110, 142, 2.6, "side", "raul"], [0, Color(0.7, 0.85, 1.0), 200, 142, 2.6, "side", "alvarito"]],
		[["RAUL", "—¡Otra ronda! ¡Yo invito!"],
		["", "Alvarito levanta la copa. No sabe por qué, pero esa noche la levanta un poquito más alto."],
		["ALVARITO", "—Por los que no vinieron."],
		["RAUL", "—¿Quiénes?"],
		["ALVARITO", "—... No sé. Alguno."]]],
	["victoria", "EL CUMPLEAÑOS DE VICTORIA", [[3, Color(1.0, 0.8, 0.9), 150, 150, 1.6, "side"]],
		[["", "29 de octubre. Doce años. Le llega una bicicleta rosada, con canasta y timbre. La trae Don Germán."],
		["", "Tiene una tarjeta, con letra de adulto que escribe despacio: \"Feliz cumpleaños. El del perro.\""],
		["VICTORIA", "—¿Y él? ¿Por qué no vino?"],
		["DON GERMAN", "—... Le tocó irse lejos, mija. Pero le dejó esto."],
		["", "Ella da una vuelta en la bicicleta por el Parque. Pasa por el árbol de flores amarillas. Toca el timbre dos veces."],
		["", "Una para él. Otra para el perro."],
		["", "Mira hacia la reja del colegio. Saluda con la mano. Chiquita. A nadie."],
		["", "Algún día alguien le va a contar quién era. Ese día va a ser la única que no diga \"es él\"."]]],
]

var _i := 0
var _people: Array = []
var _head: Label
var _t := 0.0
var _place := ""


func _ready() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	_head = Label.new()
	_head.position = Vector2(0, 6)
	_head.size = Vector2(320, 10)
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_head.add_theme_font_override("font", FONT)
	_head.add_theme_font_size_override("font_size", 8)
	_head.add_theme_constant_override("outline_size", 3)
	_head.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	_head.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	ui.add_child(_head)
	MusicDirector.force("night")
	_run()


func _run() -> void:
	for sc in SCENES:
		_show(sc)
		await get_tree().create_timer(1.2).timeout
		await Dialogue.talk(sc[3])
		await get_tree().create_timer(0.6).timeout
	_place = "negro"
	for p in _people:
		p.queue_free()
	_people.clear()
	_head.text = ""
	await Dialogue.talk([["", "BE A MAN"], ["", "Para los que se quedan en la calle. Y para los perros que se quedan con ellos."], ["", "FIN."]])
	GameState.flags["juego_terminado"] = true
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(TITLE)


func _show(sc: Array) -> void:
	_place = sc[0]
	_head.text = sc[1]
	for p in _people:
		p.queue_free()
	_people.clear()
	for who in sc[2]:
		var s := AnimatedSprite2D.new()
		var id: String = who[6] if who.size() > 6 else ""
		s.sprite_frames = CharacterFrames.named(who[0], id)
		s.modulate = Color.WHITE if CharacterFrames.has_own(id) else who[1]
		s.position = Vector2(who[2], who[3] - 38)
		s.scale = Vector2(who[4], who[4])
		s.play("idle_" + who[5])
		s.flip_h = who[2] < 160 and who[5] == "side"
		add_child(s)
		_people.append(s)
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -38))  # todo más arriba: abajo va la caja de diálogo
	match _place:
		"entierro":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.62, 0.78, 0.92))
			draw_rect(Rect2(0, 90, 320, 90), Color(0.4, 0.6, 0.32))
			_tree(Vector2(160, 92))
			for g in [[Vector2(140, 150), 10.0], [Vector2(176, 152), 18.0]]:  # Lukas, chiquita; él, al lado
				draw_rect(Rect2(g[0].x - g[1], g[0].y - 4, g[1] * 2, 8), Color(0.45, 0.34, 0.24))
				draw_rect(Rect2(g[0].x - 1, g[0].y - 18, 3, 16), Color(0.5, 0.36, 0.22))
				draw_rect(Rect2(g[0].x - 6, g[0].y - 14, 13, 3), Color(0.5, 0.36, 0.22))
			draw_circle(Vector2(170, 148), 3.0, Color(0.9, 0.2, 0.25))  # el clavel
			draw_rect(Rect2(188, 140, 6, 9), Color(0.92, 0.82, 0.78))  # Gloria
		"cocina":
			_room(Color(0.86, 0.78, 0.62), Color(0.55, 0.42, 0.3))
			draw_rect(Rect2(40, 60, 70, 40), Color(0.6, 0.75, 0.9))  # ventana
			draw_rect(Rect2(200, 92, 60, 26), Color(0.3, 0.3, 0.33))  # estufa
			draw_rect(Rect2(214, 80, 22, 14), Color(0.5, 0.5, 0.55))  # la olla
			for k in 3:
				draw_line(Vector2(218 + k * 6, 78 - fmod(_t * 10 + k * 5, 14)), Vector2(220 + k * 6, 70 - fmod(_t * 10 + k * 5, 14)), Color(1, 1, 1, 0.5))
		"garaje":
			_room(Color(0.55, 0.55, 0.58), Color(0.4, 0.4, 0.42))
			draw_rect(Rect2(150, 120, 70, 14), Color(0.15, 0.15, 0.18))  # la moto
			draw_circle(Vector2(156, 136), 9.0, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(214, 136), 9.0, Color(0.1, 0.1, 0.1))
			draw_rect(Rect2(170, 112, 26, 10), Color(0.6, 0.25, 0.2))
			draw_rect(Rect2(40, 70, 26, 16), Color(0.3, 0.3, 0.32))  # radio
		"apartamento":
			_room(Color(0.75, 0.6, 0.68), Color(0.45, 0.35, 0.38))
			draw_rect(Rect2(220, 50, 70, 50), Color(0.3, 0.35, 0.5))  # ventana con lluvia
			for k in 12:
				var x := 222.0 + fmod(k * 13.0, 66.0)
				var y := 52.0 + fmod(_t * 60.0 + k * 17.0, 46.0)
				draw_line(Vector2(x, y), Vector2(x - 1, y + 4), Color(0.8, 0.85, 1.0, 0.6))
			draw_rect(Rect2(60, 110, 70, 22), Color(0.6, 0.2, 0.3))  # el sofá
		"oficina":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.25, 0.3, 0.4))
			for k in 8:
				draw_rect(Rect2(k * 42, 40 + (k % 3) * 12, 30, 70), Color(0.18, 0.22, 0.3))  # la ciudad por el vidrio
			draw_rect(Rect2(0, 120, 320, 60), Color(0.3, 0.32, 0.42))
			draw_rect(Rect2(170, 112, 70, 12), Color(0.45, 0.3, 0.2))  # escritorio
		"esquina":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.08, 0.07, 0.12))
			draw_rect(Rect2(0, 120, 320, 60), Color(0.2, 0.2, 0.22))
			draw_line(Vector2(180, 40), Vector2(180, 150), Color(0.35, 0.35, 0.38), 3.0)  # el poste
			draw_circle(Vector2(180, 40), 30.0, Color(1, 0.85, 0.5, 0.12))
		"casa_camila":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.7, 0.85, 0.95))
			draw_rect(Rect2(0, 100, 320, 80), Color(0.6, 0.6, 0.62))
			draw_rect(Rect2(180, 104, 90, 34), Color(0.2, 0.45, 0.3))  # la camioneta
			draw_circle(Vector2(196, 140), 9.0, Color(0.1, 0.1, 0.1))
			draw_circle(Vector2(254, 140), 9.0, Color(0.1, 0.1, 0.1))
		"ciudad":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.9, 0.75, 0.6))
			for k in 6:
				draw_rect(Rect2(k * 56, 60 + (k % 2) * 20, 40, 60), Color(0.6, 0.55, 0.6))
			draw_rect(Rect2(0, 120, 320, 60), Color(0.5, 0.65, 0.4))
		"cantina":
			_room(Color(0.35, 0.22, 0.2), Color(0.25, 0.15, 0.12))
			draw_rect(Rect2(40, 108, 240, 16), Color(0.45, 0.28, 0.18))  # la barra
			for k in 7:
				draw_rect(Rect2(60 + k * 30, 60, 8, 22), Color(0.3, 0.6, 0.35, 0.8))  # botellas
		"victoria":
			draw_rect(Rect2(0, 0, 320, 180), Color(0.62, 0.78, 0.92))
			draw_rect(Rect2(0, 100, 320, 80), Color(0.4, 0.62, 0.32))
			_tree(Vector2(260, 104))
			draw_circle(Vector2(140, 156), 9.0, Color(0.15, 0.15, 0.18))  # la bicicleta rosada
			draw_circle(Vector2(170, 156), 9.0, Color(0.15, 0.15, 0.18))
			draw_line(Vector2(140, 156), Vector2(160, 142), Color(1, 0.5, 0.7), 3.0)
			draw_line(Vector2(160, 142), Vector2(170, 156), Color(1, 0.5, 0.7), 3.0)
			for k in 3:
				draw_circle(Vector2(60 + k * 14, 60 + sin(_t * 2 + k) * 3), 6.0, [Color(1, 0.4, 0.5), Color(0.5, 0.7, 1), Color(1, 0.9, 0.3)][k])
		"negro":
			draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0))


func _room(wall: Color, floor: Color) -> void:
	draw_rect(Rect2(0, 0, 320, 120), wall)
	draw_rect(Rect2(0, 120, 320, 60), floor)


## El árbol de flores amarillas (guayacán).
func _tree(base: Vector2) -> void:
	draw_rect(Rect2(base.x - 4, base.y - 40, 8, 44), Color(0.45, 0.32, 0.2))
	for k in 18:
		var p := base + Vector2(cos(k * 1.7) * 30.0, -50.0 + sin(k * 2.3) * 16.0)
		draw_circle(p, 10.0, Color(0.95, 0.82, 0.2))
	for k in 6:  # flores que caen
		var x := base.x - 40 + fmod(k * 23.0 + _t * 8.0, 80.0)
		var y := base.y - 30 + fmod(_t * 14.0 + k * 19.0, 60.0)
		draw_circle(Vector2(x, y), 1.5, Color(1, 0.86, 0.25))
