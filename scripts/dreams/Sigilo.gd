extends Node2D
## SIGILO: LA EMPRESA. Vista desde arriba, una pantalla por nivel (level = 1..4, escenas Sigilo1..4).
## La empresa donde trabajaba: José Mario, el jefe, le contó a todos lo de las drogas. Primero caen sus
## líderes, uno por sueño, y al final él.
##   1. WALTER: el lambón de José Mario. Se para a comer (y ahí no mira). Hay que llegarle tres veces
##      por la espalda (le pega un post-it: "SOY EL SAPO DE JOSE MARIO").
##   2. NICOLAS: habla duro, todo el tiempo. Cuando grita, los guardias lo miran a él: ahí se pasa.
##   3. EDDY: el de gafas que quiere el puesto de todos. Revisa los escondites.
##   4. JOSE MARIO: no se mueve. Cámaras por todos lados; hay que apagar los tres tableros y llegarle.
## Controles: flechas = moverse. E = dormir a un guardia por la espalda / pegarle al jefe / tablero.
## X = tirar una taza (hace ruido donde cae: los guardias van a mirar). Los lockers y plantas (verde
## oscuro) esconden. Los documentos (amarillo) abren la oficina del jefe. Si un cono se llena: lo vieron.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NIGHT := "res://scenes/world/Night.tscn"
const T := 16
const TOP := 16
const VIEW := 74.0
const HALF_ANGLE := 0.48
const SPEED := 52.0
## Los guardias de seguridad (tools/art/draw_gente.py). Los jefes usan su hoja (CharacterFrames.OWN, por "id").
const GUARDS := [
	preload("res://assets/characters/guardia_0.png"),
	preload("res://assets/characters/guardia_1.png"),
	preload("res://assets/characters/guardia_2.png"),
]

## Mapas (20x10). # pared, . piso, d escritorio, h escondite, o documento, D puerta del jefe,
## P tablero de cámaras, S inicio, B jefe.
const LEVELS := {
	1: {"boss": "WALTER", "id": "walter", "boss_speed": 22.0, "tags": 3, "cups": 3,
		"map": [
			"####################",
			"#S..h.....#........#",
			"#.dd..dd..#.dd..dd.#",
			"#.........#........#",
			"#.dd.odd..D....B...#",
			"#.........#........#",
			"#.dd..dd.h#.dd..dd.#",
			"#....o....#......h.#",
			"#h........#........#",
			"####################"],
		"guards": [[[2, 3], [8, 3], [8, 7], [2, 7]], [[6, 1], [6, 8]]],
		"boss_path": [[13, 3], [17, 3], [17, 7], [13, 7]],
		"intro": [["", "Lunes, 7:58. La Empresa. Piso 6. Alfombra gris, cubículos grises, una planta de plástico que alguien riega por costumbre."],
			["ÉL", "Mi tarjeta de presentación: papel de 300 gramos, mate, letra Helvetica. \"Coordinador de Proyectos Estratégicos\". Nadie sabía qué coordinaba. Yo tampoco. Coordinaba muy bien."],
			["", "Lo echaron hace un año. En el sueño todavía tiene puesto el carné. Con la foto vieja, cuando sonreía."],
			["", "Primero, Walter. Contabilidad. El que le llevaba los chismes a José Mario. Siempre con algo en la boca: una empanada o el nombre de alguien."],
			["ÉL", "Walter almuerza a las 11:40 para tener la mejor mesa del comedor. Durante cuatro años nadie le disputó la mesa. Nadie quería sentarse con Walter."],
			["", "Flechas: moverse. E por la espalda: dormir a un guardia. X: tirar una taza para distraer. Verde oscuro: escondite."],
			["", "Juntá los documentos (amarillo) para abrir la oficina. A Walter llegale tres veces por la espalda."]],
		"tag_lines": ["WALTER: —¿Quién me tocó? ... Nadie. Bueno. Sigo comiendo. Es de pollo. Creo.",
			"WALTER: —¡Epa! ¿Y este papelito en la espalda? ... ¿Post-it amarillo? Esos son de mi cajón. Me los roban todos.",
			"WALTER: —\"SOY EL SAPO DE JOSE MARIO\". ... ¿Quién escribió la verdad en mi espalda? ¿Y con mi lapicero?"],
		"outro": [["WALTER", "—Yo solo le contaba lo que veía, pana. Él preguntaba. Yo no sabía decir que no."],
			["YO", "—Usted sí sabía. Le gustaba. A cambio le dieron el puesto al lado de la ventana."],
			["WALTER", "—... La ventana da a un muro. Un muro de ladrillo. Lo he mirado cuatro años."],
			["WALTER", "—Tiene treinta y dos ladrillos de ancho. Los conté. No le dije a nadie. ¿A quién le iba a decir? Yo era el que contaba."]],
		"tease": [["", "En el escritorio de Walter hay una lista. Cinco nombres tachados. El de él, primero. Con resaltador verde."],
			["ÉL", "Verde. Walter usa el verde para \"pendientes resueltos\". Fui un pendiente resuelto. En verde."],
			["", "El siguiente nombre lo escribió Nicolás. Con mayúsculas. Como habla."]]},
	2: {"boss": "NICOLAS", "id": "nicolas", "boss_speed": 26.0, "tags": 3, "cups": 3, "loud": true,
		"map": [
			"####################",
			"#S.....#...h...#...#",
			"#.dd.d.#.dd.dd.#.B.#",
			"#..o...#.......D...#",
			"#.dd.d.#.dd.dd.#...#",
			"#..........o...#.h.#",
			"#h.dd.d..dd.dd.#...#",
			"#..............#...#",
			"#....h.........#...#",
			"####################"],
		"guards": [[[2, 5], [13, 5]], [[9, 1], [9, 8]], [[13, 7], [2, 7]]],
		"boss_path": [[17, 2], [17, 8], [18, 5]],
		"intro": [["", "ANTERIORMENTE... Walter quedó con un post-it en la espalda y una verdad en la cabeza."],
			["", "Ahora Nicolás. Gerente de Cuentas Clave. Gordo, prepotente, habla duro todo el día. Habla mierda de todos. De él, más."],
			["ÉL", "Nicolás tiene un mug que dice WORLD'S BEST BOSS. Se lo compró él mismo en el aeropuerto de Miami. Lo contó en tres reuniones."],
			["", "Cuando Nicolás grita, los guardias lo miran a él. Aprovechá. Juntá los documentos y llegale tres veces."]],
		"shouts": ["NICOLAS: —¡ESTE PISO HUELE A FRACASO! ¡Y A ATÚN! ¡¿QUIÉN TRAJO ATÚN?!", "NICOLAS: —¡Yo a ese man lo saqué! ¡Con un correo! ¡Con copia a todos!",
			"NICOLAS: —¡Aquí el que no rinde, se va! ¡Como el drogadicto ese!", "NICOLAS: —¡Que alguien me traiga un tinto! ¡Juan Valdez! ¡No el de la greca!",
			"NICOLAS: —¡LOS INDICADORES ESTÁN EN ROJO! ¡Bueno, el rojo es el color corporativo! ¡PERO IGUAL!"],
		"tag_lines": ["NICOLAS: —¡¿Quién me jaló la corbata?! ¡Es Hermès! ¡De San Andresito, pero Hermès!",
			"NICOLAS: —¡Esto es acoso laboral! ¡Lo voy a reportar a Talento Humano! ¡Talento Humano soy yo los jueves!",
			"NICOLAS: —... ¿Usted? ¿El que yo saqué? ¿Qué hace aquí? Seguridad no lo dejó entrar. Yo firmé esa orden. Con mi Montblanc."],
		"outro": [["NICOLAS", "—Yo solo decía lo que todos pensaban. Duro. Alguien tenía que decirlo."],
			["YO", "—Nadie lo pensaba, Nicolás. Usted lo pensaba duro para que pareciera de todos."],
			["NICOLAS", "—... ¿Y ahora quién me va a escuchar?"], ["YO", "—El mug. El mug lo escucha."],
			["NICOLAS", "—El mug dice que soy el mejor jefe del mundo."], ["YO", "—El mug no tiene criterio, Nicolás. Es un mug."]],
		"tease": [["", "En el computador de Nicolás hay un correo sin enviar. Para: Eddy. Asunto: \"Su puesto\". Prioridad: alta. Con un emoji de un cohete."],
			["", "Eddy lleva gafas, sonríe en las reuniones y quiere el puesto de todos. Hasta el de él, que ya no tiene puesto."]]},
	3: {"boss": "EDDY", "id": "eddy", "boss_speed": 34.0, "tags": 3, "cups": 4, "seeker": true,
		"map": [
			"####################",
			"#S..d...h...d......#",
			"#...d.......d..dd..#",
			"#.h.d..ddd..d..o...#",
			"#...d.......d......#",
			"#...dddd.ddddd.dd.h#",
			"#.o.......h........#",
			"#..dd.dd.....dd.dd.#",
			"#h........B.......h#",
			"####################"],
		"guards": [[[2, 1], [2, 8]], [[6, 6], [16, 6]], [[14, 1], [17, 4]]],
		"boss_path": [[10, 8], [17, 8], [17, 6], [3, 6], [3, 8]],
		"intro": [["", "ANTERIORMENTE... Nicolás se quedó sin nadie que lo escuche. Por primera vez, en silencio."],
			["", "Eddy. Analista Senior Junior. Gafas sin aumento, sonrisa de reunión, quiere el puesto de todos. Revisa los escondites: no te quedes mucho en uno."],
			["ÉL", "Eddy toma kombucha. Lo dice antes de que uno le pregunte. Tiene una libreta Moleskine donde anota lo que dicen los demás. Nunca escribió una idea propia ahí. Lo sé: la leí."],
			["", "Juntá los documentos. Llegale tres veces por la espalda. Eddy no tiene oficina: anda por todo el piso."]],
		"tag_lines": ["EDDY: —Ajá. Interesante. Muy interesante. Lo anoto. ¿Cómo se escribe \"traición\"? ¿Con c o con s?",
			"EDDY: —¿Usted quiere mi puesto? ... Yo también quiero el suyo. Ah, no tiene. Bueno, quiero el que tenía.",
			"EDDY: —Se me cayeron las gafas. No veo nada. Igual no tienen aumento. Nunca vi nada, en realidad. Es estético."],
		"outro": [["EDDY", "—Yo solo quería subir. Usted estaba en la escalera. No era personal. Era estratégico."],
			["YO", "—Usted me empujó y después subió un escalón. Un escalón, Eddy. Ni siquiera dos. Me cambió por un aumento del cuatro por ciento."],
			["EDDY", "—El tres coma ocho."],
			["EDDY", "—... José Mario me prometió su puesto. Después se lo dio a otro. A un sobrino. Que no habla inglés."], ["YO", "—Bienvenido."]],
		"tease": [["", "El ascensor se abre solo. Último piso. Suena una versión instrumental de \"Hotel California\". Una sola oficina, con vidrio, y alguien adentro que no se mueve."],
			["", "José Mario. Vicepresidente. Nunca levanta la voz. Nunca la necesitó."],
			["ÉL", "Su tarjeta de presentación es negra. Letras en relieve. Sin cargo. Solo el nombre. El que necesita poner el cargo no es nadie. Él me lo enseñó."]]},
	4: {"boss": "JOSE MARIO", "id": "josemario", "boss_speed": 0.0, "tags": 1, "cups": 4, "cameras": true,
		"map": [
			"####################",
			"#S.....h.....P.....#",
			"#.dd.dd...dd...dd..#",
			"#.......P..........#",
			"#.dd.dd...dd.dd....#",
			"#h........h....#D###",
			"#..dd..dd......#...#",
			"#P.............#.B.#",
			"#.....h........#...#",
			"####################"],
		"guards": [[[3, 3], [12, 3]], [[9, 6], [9, 8], [14, 8]]],
		"cams": [[[9, 1], 1.6], [[18, 1], 2.2], [[1, 8], -0.9], [[14, 8], -2.2]],
		"boss_path": [[17, 7]],
		"intro": [["", "ANTERIORMENTE... Walter, Nicolás, Eddy. Los tres en el piso de abajo, contando sus propios chismes."],
			["", "Último piso. Cámaras en cada esquina. José Mario no las mira: no le hace falta. Él sabe."],
			["ÉL", "Escritorio de vidrio. Nada encima. Ni un papel. Un hombre sin papeles en el escritorio es un hombre que tiene a otros cargándolos."],
			["", "Apagá los tres tableros (P, con E). Juntá... no hay documentos: él es el documento. Llegale."]],
		"tag_lines": ["JOSE MARIO: —Llegó. Tarde. Como siempre. Siéntese."],
		"outro": [["JOSE MARIO", "—Siéntese."], ["YO", "—Prefiero quedarme de pie. Ya me senté suficiente en su piso."],
			["JOSE MARIO", "—¿Agua? Es de Noruega. Viene en botella de vidrio. No sabe a nada. Eso es lo que uno paga: que no sepa a nada."],
			["JOSE MARIO", "—Yo no le conté a nadie. Lo dejé en un correo, abierto, en una pantalla. En la pantalla de Walter. A las 11:39. La gente lee lo que quiere."],
			["YO", "—Usted sabía quién iba a leer."], ["JOSE MARIO", "—Claro. Yo siempre sé. Walter almuerza a las 11:40."],
			["JOSE MARIO", "—Usted era bueno. Demasiado. Y tenía un pasado. Eso, en una empresa, es una oportunidad. Para mí."],
			["YO", "—Yo estaba limpio. Hacía dos años."], ["JOSE MARIO", "—Nadie lee esa parte del correo. Está en el tercer párrafo. Nadie llega al tercer párrafo."],
			["", "(Él le saca el carné del cuello. Lo pone en el escritorio, con la foto hacia arriba. Esa, cuando sonreía.)"],
			["YO", "—Quédese con él. Yo ya no lo necesito para entrar. Ni para salir."],
			["ÉL", "El primer papel que hay sobre ese escritorio en cinco años. Lo dejé yo."]],
		"tease": []},
}

## Un guardia (o el jefe).
class G:
	var node: AnimatedSprite2D
	var pos := Vector2.ZERO
	var path: Array = []
	var wi := 0
	var ang := 0.0
	var state := "patrol"     # patrol, look, investigate, out, eat
	var sus := 0.0
	var target := Vector2.ZERO
	var wait := 0.0
	var boss := false


@export var level := 1

var L: Dictionary = {}
var grid: Array = []
var me_pos := Vector2.ZERO
var me_node: AnimatedSprite2D
var guards: Array[G] = []
var boss: G
var docs_total := 0
var docs := 0
var cups := 3
var tags := 0
var panels := 0
var panels_total := 0
var cams: Array = []
var state := "intro"
var _hint: Label
var _top: Label
var _msg: Label
var _t := 0.0
var _shout_t := 4.0
var _noise := Vector2.ZERO
var _noise_t := 0.0
var _hidden := false
var _hide_time := 0.0
var _caught_flash := 0.0
var _cup_fx: Array = []
var _cam_speed := 1.0


func _ready() -> void:
	L = LEVELS[level]
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	_top = _lab(ui, Vector2(4, 3))
	_msg = _lab(ui, Vector2(4, 158))
	_msg.size = Vector2(312, 20)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _lab(ui, Vector2(0, 80))
	_hint.size = Vector2(320, 20)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	me_node = AnimatedSprite2D.new()
	me_node.sprite_frames = CharacterFrames.protagonist()
	me_node.offset = Vector2(0, -6)
	add_child(me_node)
	MusicDirector.force("")
	_build()
	_start()


func _lab(parent: Node, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.06))
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	parent.add_child(l)
	return l


func _tile_center(c: int, r: int) -> Vector2:
	return Vector2(c * T + 8, TOP + r * T + 8)


## Arma el nivel desde el mapa (también al reintentar).
func _build() -> void:
	for g in guards:
		g.node.queue_free()
	guards.clear()
	grid.clear()
	docs_total = 0
	docs = 0
	tags = 0
	panels = 0
	panels_total = 0
	cups = L["cups"]
	var m: Array = L["map"]
	for r in m.size():
		var row: Array = []
		for c in m[r].length():
			var ch: String = m[r][c]
			if ch == "S":
				me_pos = _tile_center(c, r)
				ch = "."
			elif ch == "B":
				ch = "."
			elif ch == "o":
				docs_total += 1
			elif ch == "P":
				panels_total += 1
			row.append(ch)
		grid.append(row)
	if docs_total == 0:
		_open_door()
	for path in L["guards"]:
		var g := _make_guard(path, GUARDS.pick_random())
		guards.append(g)
	boss = _make_guard(L["boss_path"], CharacterFrames.OWN[L["id"]])
	boss.boss = true
	boss.node.scale = Vector2(1.25, 1.25)
	guards.append(boss)
	cams.clear()
	for cdef in L.get("cams", []):
		cams.append({"pos": _tile_center(cdef[0][0], cdef[0][1]), "base": cdef[1], "on": true})


func _make_guard(path: Array, sheet: Texture2D) -> G:
	var g := G.new()
	for p in path:
		g.path.append(_tile_center(p[0], p[1]))
	g.pos = g.path[0]
	g.node = AnimatedSprite2D.new()
	g.node.sprite_frames = CharacterFrames.adult(sheet)
	g.node.offset = Vector2(0, -6)
	add_child(g.node)
	return g


func _start() -> void:
	state = "intro"
	await get_tree().create_timer(0.5).timeout
	if FinalRush.is_step("sigilo"):
		_cam_speed = 2.0
		await Dialogue.talk([["", "Último piso, otra vez. Las cámaras giran el doble de rápido. José Mario aprendió."],
			["JOSE MARIO", "—Yo siempre aprendo. Usted también, parece. Le haría una evaluación de desempeño, pero usted ya no trabaja aquí."]])
	else:
		await Dialogue.talk(L["intro"])
	MusicDirector.force("plomo")
	state = "play"


func cell_at(p: Vector2) -> String:
	var c := int(floor(p.x / T))
	var r := int(floor((p.y - TOP) / T))
	if r < 0 or r >= grid.size() or c < 0 or c >= grid[r].size():
		return "#"
	return grid[r][c]


func blocks_move(p: Vector2) -> bool:
	return cell_at(p) in ["#", "d", "D", "P"]


func blocks_view(ch: String) -> bool:
	return ch in ["#", "d", "D", "h", "P"]


## ¿Se ven? (las paredes, escritorios y escondites tapan).
func los(a: Vector2, b: Vector2) -> bool:
	var d := a.distance_to(b)
	var steps := int(d / 4.0)
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		if blocks_view(cell_at(p)):
			return false
	return true


# ---------------------------------------------------------------- Bucle

func _process(delta: float) -> void:
	_t += delta
	_caught_flash = maxf(0.0, _caught_flash - delta)
	_noise_t -= delta
	if state == "play":
		_player(delta)
		for g in guards:
			_guard(g, delta)
		_cameras(delta)
		if L.get("loud", false):
			_shout(delta)
	_place()
	_hud()
	queue_redraw()


func _player(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		v.x -= 1
	if Input.is_action_pressed("move_right"):
		v.x += 1
	if Input.is_action_pressed("move_up"):
		v.y -= 1
	if Input.is_action_pressed("move_down"):
		v.y += 1
	if v != Vector2.ZERO:
		v = v.normalized()
		var step := v * SPEED * delta
		for axis in [Vector2(step.x, 0), Vector2(0, step.y)]:
			var np: Vector2 = me_pos + axis
			if not blocks_move(np + Vector2(sign(axis.x) * 5, sign(axis.y) * 4)):
				me_pos = np
		var anim := "walk_side" if absf(v.x) > absf(v.y) else ("walk_down" if v.y > 0 else "walk_up")
		me_node.flip_h = v.x > 0
		if me_node.animation != anim:
			me_node.play(anim)
	else:
		me_node.play(me_node.animation.replace("walk", "idle"))
	# Escondido: en un locker o detrás de una planta.
	_hidden = cell_at(me_pos) == "h"
	_hide_time = _hide_time + delta if _hidden else 0.0
	me_node.modulate.a = 0.35 if _hidden else 1.0
	# Documentos.
	if cell_at(me_pos) == "o":
		var c := int(me_pos.x / T)
		var r := int((me_pos.y - TOP) / T)
		grid[r][c] = "."
		docs += 1
		_say("Documento %d de %d. Mi nombre aparece en todos. Subrayado." % [docs, docs_total])
		if docs >= docs_total:
			_open_door()
			_say("Los documentos completos. La oficina se abre. Nadie la cerró nunca de verdad.")
	if Input.is_action_just_pressed("interact"):
		_act()
	elif Input.is_action_just_pressed("drop"):
		_throw_cup(v)


func _open_door() -> void:
	for r in grid.size():
		for c in grid[r].size():
			if grid[r][c] == "D":
				grid[r][c] = "."


## E: dormir a un guardia por la espalda, pegarle al jefe, o apagar un tablero.
func _act() -> void:
	for r in grid.size():
		for c in grid[r].size():
			if grid[r][c] == "P" and _tile_center(c, r).distance_to(me_pos) < 20:
				grid[r][c] = "p"
				panels += 1
				for cam in cams:
					if cam["on"]:
						cam["on"] = false
						break
				_say("Tablero apagado (%d de %d). Una cámara menos mirándome. Quedan las de siempre." % [panels, panels_total])
				return
	for g in guards:
		if g.state == "out" or g.pos.distance_to(me_pos) > 18:
			continue
		var facing := Vector2.from_angle(g.ang)
		var to_me := (me_pos - g.pos).normalized()
		var behind := facing.dot(to_me) < 0.2 or g.state == "eat"
		if not behind:
			continue
		if g.boss:
			if L.get("cameras", false) and panels < panels_total:
				_say("Todavía hay cámaras prendidas. Él lo vería. Él siempre ve.")
				return
			if docs < docs_total:
				_say("Sin los documentos no hay nada que decirle.")
				return
			tags += 1
			var lines: Array = L["tag_lines"]
			_say(lines[mini(tags - 1, lines.size() - 1)])
			if tags >= L["tags"]:
				_win()
			else:
				g.wi = (g.wi + 1) % g.path.size()
				g.pos = g.path[g.wi]
				g.sus = 0.0
		else:
			g.state = "out"
			g.node.play("idle_down")
			g.node.rotation = PI / 2
			_say(["Lo duermo. Ronca. Igual que en las reuniones.", "Uno menos. Se va a despertar con un tortícolis y una historia."].pick_random())
		return


func _throw_cup(dir: Vector2) -> void:
	if cups <= 0:
		_say("No me quedan tazas. Ni paciencia.")
		return
	cups -= 1
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if me_node.flip_h else Vector2.LEFT  # flip_h: mira a la derecha
	var p := me_pos
	for i in 12:
		var np := p + dir * 4.0
		if blocks_view(cell_at(np)):
			break
		p = np
	_noise = p
	_noise_t = 3.0
	_cup_fx.append({"pos": p, "t": 0.6})
	for g in guards:
		if g.state in ["patrol", "look"] and g.pos.distance_to(p) < 90 and not (g.boss and g.path.size() == 1):
			g.state = "investigate"
			g.target = p
			g.wait = 2.0
	_say("¡Crash! Una taza contra el piso. En esta empresa eso es más grave que un despido.")


func _guard(g: G, delta: float) -> void:
	if g.state == "out":
		return
	var speed: float = (L["boss_speed"] if g.boss else 30.0)
	match g.state:
		"patrol":
			if g.path.size() > 1:
				var tgt: Vector2 = g.path[g.wi]
				if g.pos.distance_to(tgt) < 2.0:
					g.wi = (g.wi + 1) % g.path.size()
					if g.boss and L["boss"] == "WALTER" and randf() < 0.5:
						g.state = "eat"
						g.wait = 3.0
				else:
					_move(g, tgt, speed, delta)
			else:
				if g.boss and L.get("cameras", false):
					# Con las cámaras prendidas, José Mario lo sigue con la mirada. Apagadas: mira su pantalla.
					g.ang = (me_pos - g.pos).angle() if panels < panels_total else PI / 2.0 + sin(_t * 0.5) * 0.35
				else:
					g.ang += delta * 0.6
			# Eddy revisa los escondites: si el pelado lleva rato en uno cerca, va a mirar.
			if L.get("seeker", false) and g.boss and _hidden and _hide_time > 2.5 and g.pos.distance_to(me_pos) < 110:
				g.state = "investigate"
				g.target = me_pos
				g.wait = 1.5
				_say("EDDY: —Ese locker estaba cerrado esta mañana. Lo anoté.")
		"eat":
			g.wait -= delta
			g.node.play("idle_down")
			if g.wait <= 0.0:
				g.state = "patrol"
			return
		"investigate":
			if g.pos.distance_to(g.target) > 3.0:
				_move(g, g.target, speed * 1.2, delta)
			else:
				g.wait -= delta
				g.ang += delta * 2.5
				# Eddy abre el locker: si está adentro, lo encontró.
				if L.get("seeker", false) and g.boss and _hidden and g.pos.distance_to(me_pos) < 14:
					_caught(g)
					return
				if g.wait <= 0.0:
					g.state = "patrol"
	_vision(g, delta)


func _move(g: G, tgt: Vector2, speed: float, delta: float) -> void:
	var d := tgt - g.pos
	g.ang = lerp_angle(g.ang, d.angle(), delta * 8.0)
	var step := d.normalized() * speed * delta
	if not blocks_move(g.pos + step * 2.0):
		g.pos += step
	else:
		g.pos += Vector2(step.y, -step.x)  # rodea
	var anim := "walk_side" if absf(d.x) > absf(d.y) else ("walk_down" if d.y > 0 else "walk_up")
	g.node.flip_h = d.x > 0
	if g.node.animation != anim:
		g.node.play(anim)


## El cono: si lo ve, se llena la sospecha. Lleno: lo vieron.
func _vision(g: G, delta: float) -> void:
	var sees := _sees(g.pos, g.ang, VIEW)
	if sees:
		var d := g.pos.distance_to(me_pos)
		g.sus += delta * (2.4 if d < 32 else 1.2)
		if g.sus > 0.35 and g.state == "patrol":
			g.ang = lerp_angle(g.ang, (me_pos - g.pos).angle(), delta * 3.0)
		if g.sus >= 1.0:
			_caught(g)
	else:
		g.sus = maxf(0.0, g.sus - delta * 0.5)


func _sees(from: Vector2, ang: float, reach: float) -> bool:
	if _hidden:
		return false
	var d := me_pos - from
	if d.length() > reach or d.length() < 1.0:
		return false
	if absf(angle_difference(ang, d.angle())) > HALF_ANGLE:
		return false
	return los(from, me_pos)


## Nicolás grita: todos los guardias lo miran a él (un rato).
func _shout(delta: float) -> void:
	_shout_t -= delta
	if _shout_t > 0.0 or boss.state == "out":
		return
	_shout_t = randf_range(4.0, 6.0)
	_say(L["shouts"].pick_random())
	for g in guards:
		if not g.boss and g.state == "patrol":
			g.state = "investigate"
			g.target = g.pos
			g.wait = 1.8
			g.ang = (boss.pos - g.pos).angle()


## Las cámaras de José Mario: giran despacio; si lo ven, lo vieron.
func _cameras(delta: float) -> void:
	for cam in cams:
		if not cam["on"]:
			continue
		var a: float = cam["base"] + sin(_t * 0.7 * _cam_speed) * 0.6
		cam["ang"] = a
		if _sees(cam["pos"], a, 120.0):
			cam["sus"] = cam.get("sus", 0.0) + delta * 1.4
			if cam["sus"] >= 1.0:
				_caught(null)
		else:
			cam["sus"] = maxf(0.0, cam.get("sus", 0.0) - delta * 0.5)


func _caught(g) -> void:
	if state != "play":
		return
	state = "caught"
	_caught_flash = 1.0
	MusicDirector.force("")
	var who: String = "CAMARA" if g == null else (L["boss"] if g.boss else "SEGURIDAD")
	var line: String = "—¡Usted qué hace aquí! ¡Usted ya no trabaja aquí!" if g == null or not g.boss else "—Lo vi. Siempre lo veo."
	await Dialogue.talk([[who, line], ["", "Lo sacan del edificio. Otra vez. En el sueño también. Con la misma caja de cartón."],
		["ÉL", "La caja de cartón. Un portarretratos, una taza, un cactus. El cactus sobrevivió. Yo casi."]])
	var i := 0 if FinalRush.active() else await Dialogue.talk([["", "¿Otra vez?"]], ["Reintentar", "Despertarse"])
	if i == 1:
		_wake(false)
		return
	_build()
	state = "play"
	MusicDirector.force("plomo")


func _win() -> void:
	state = "end"
	MusicDirector.force("")
	if FinalRush.is_step("sigilo"):
		await Dialogue.talk([["JOSE MARIO", "—... Usted ya no necesita mi permiso para nada."], ["", "—Nunca lo necesité. Tardé en saberlo."]])
		FinalRush.next()
		return
	await Dialogue.talk(L["outro"])
	if not L["tease"].is_empty():
		await Dialogue.talk(L["tease"] + [["", "CONTINUARÁ."]])
	else:
		await Dialogue.talk([["", "Sale del edificio por la puerta principal. Nadie lo para. Nadie lo mira."],
			["", "Por primera vez, eso no le duele."], ["", "LA EMPRESA: COMPLETO."]])
	_wake(true)


func _wake(won: bool) -> void:
	state = "out"
	GameState.flags["dream_won"] = won
	GameState.flags["dream_return"] = "sigilo%d" % level
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)


func _say(line: String) -> void:
	_msg.text = line
	_msg.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(_msg, "modulate:a", 0.0, 0.4)


func _place() -> void:
	me_node.position = me_pos
	me_node.z_index = int(me_pos.y)
	for g in guards:
		g.node.position = g.pos
		g.node.z_index = int(g.pos.y)


func _hud() -> void:
	var goal := "DOCS %d/%d" % [docs, docs_total] if docs_total > 0 else "TABLEROS %d/%d" % [panels, panels_total]
	_top.text = "%s   %s %d/%d   TAZAS %d%s" % [goal, L["boss"], tags, L["tags"], cups, "   ESCONDIDO" if _hidden else ""]


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.08, 0.08, 0.1))
	for r in grid.size():
		for c in grid[r].size():
			var ch: String = grid[r][c]
			var rect := Rect2(c * T, TOP + r * T, T, T)
			match ch:
				"#":
					draw_rect(rect, Color(0.42, 0.42, 0.46))
					draw_rect(Rect2(rect.position, Vector2(T, 3)), Color(0.55, 0.55, 0.6))
				"d":
					draw_rect(rect, Color(0.3, 0.33, 0.42))
					draw_rect(rect.grow(-2), Color(0.55, 0.42, 0.3))
					draw_rect(Rect2(rect.position + Vector2(4, 3), Vector2(8, 5)), Color(0.15, 0.2, 0.3))  # el computador
				"h":
					draw_rect(rect, Color(0.3, 0.33, 0.42))
					draw_rect(rect.grow(-1), Color(0.15, 0.32, 0.2))
					draw_line(rect.position + Vector2(8, 2), rect.position + Vector2(8, 14), Color(0.1, 0.2, 0.12))
				"o":
					draw_rect(rect, Color(0.3, 0.33, 0.42))
					draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(8, 9)), Color(0.95, 0.85, 0.3) * (0.8 + 0.2 * sin(_t * 5.0)))
				"D":
					draw_rect(rect, Color(0.45, 0.28, 0.18))
					draw_rect(Rect2(rect.position + Vector2(11, 7), Vector2(2, 2)), Color(0.9, 0.8, 0.3))
				"P", "p":
					draw_rect(rect, Color(0.3, 0.33, 0.42))
					draw_rect(rect.grow(-2), Color(0.2, 0.2, 0.24))
					draw_circle(rect.get_center(), 3.0, Color(0.9, 0.2, 0.2) if ch == "P" else Color(0.2, 0.4, 0.2))
				_:
					draw_rect(rect, Color(0.3, 0.33, 0.42) if (r + c) % 2 == 0 else Color(0.28, 0.31, 0.4))
	# Conos de visión.
	for g in guards:
		if g.state == "out" or g.state == "eat":
			continue
		var col := Color(1, 0.9, 0.3, 0.12).lerp(Color(1, 0.2, 0.2, 0.35), g.sus)
		_cone(g.pos, g.ang, VIEW, col)
		if g.sus > 0.35:
			draw_string(FONT, g.pos + Vector2(-4, -20), "!" if g.sus > 0.7 else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.3, 0.3))
	for cam in cams:
		if cam["on"] and cam.has("ang"):
			_cone(cam["pos"], cam["ang"], 120.0, Color(0.4, 0.8, 1.0, 0.1).lerp(Color(1, 0.2, 0.2, 0.35), cam.get("sus", 0.0)))
		draw_circle(cam["pos"], 3.0, Color(0.9, 0.2, 0.2) if cam["on"] else Color(0.3, 0.3, 0.3))
	for g in guards:
		if g.state == "out":
			draw_string(FONT, g.pos + Vector2(-6, -16), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.8, 1.0))
		elif g.state == "eat":
			draw_string(FONT, g.pos + Vector2(-10, -18), "ñam", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.6))
	for fx in _cup_fx.duplicate():
		fx["t"] -= get_process_delta_time()
		draw_arc(fx["pos"], 18.0 * (1.0 - fx["t"]), 0, TAU, 16, Color(1, 1, 1, fx["t"]))
		if fx["t"] <= 0.0:
			_cup_fx.erase(fx)
	if _caught_flash > 0.0:
		draw_rect(Rect2(0, 0, 320, 180), Color(1, 0, 0, _caught_flash * 0.35))


## El cono, cortado por las paredes (rayos).
func _cone(from: Vector2, ang: float, reach: float, col: Color) -> void:
	var pts := PackedVector2Array([from])
	for i in 13:
		var a := ang - HALF_ANGLE + HALF_ANGLE * 2.0 * i / 12.0
		var d := reach
		for s in range(4, int(reach), 4):
			if blocks_view(cell_at(from + Vector2.from_angle(a) * s)):
				d = s
				break
		pts.append(from + Vector2.from_angle(a) * d)
	draw_colored_polygon(pts, col)
