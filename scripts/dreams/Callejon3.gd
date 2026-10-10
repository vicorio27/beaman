extends "res://scripts/prologue/FightArena.gd"
## BRENDA (un solo sueño, largo; lo dispara la llamada a la mamá). La terminal → el bus → Ibagué → la
## casa de ella. Brenda, la mamá, se fue cuando supo que lo querían matar. Avara y mentirosa.
##   Fase 1: no pelea; se escapa y le tira maletas.
##   Fase 2, "LA DE MIL CARAS": se arranca la cara como una máscara. Aparecen cuatro: ella y tres
##   copias con caras de gente que lo quiere (Germán, Rosa, Samuel, Marta). Las copias dicen lo que esa
##   gente diría de verdad; la de verdad es la única que pide plata o miente. Cada rato se mezclan.
##   Pegarle a una copia la deshace y duele. A la de verdad: hasta que se siente. Abrazarla o dejarla ir.
## Deja la habilidad Cocinero de calle (la mamá se fue; él aprendió a cocinarse solo).

const NIGHT := "res://scenes/world/Night.tscn"
const MALETA_SPEED := 160.0

## Las caras: lo que diría de verdad cada uno. La de verdad pide plata o miente.
const FACES := {
	"DON GERMAN": ["—¿Cómo amaneció, mijo?", "—Siga, que afuera hace frío."],
	"DOÑA ROSA": ["—Mijito, ¿ya comió?", "—Me la paga cuando pueda. O nunca."],
	"SAMUEL": ["—Cuide a ese perro, compa.", "—Uno siempre espera algo."],
	"MARTA": ["—¿Ya desayunaste?", "—Me caés bien, no sé por qué."],
}
const REAL_LINES := ["—Mijo, présteme plata. Se la devuelvo el domingo.", "—Yo le mandaba plata. Todos los meses.",
	"—¿Me regala lo de la alcancía? Es para usted. Bueno, para mí.", "—Yo nunca le pedí nada. ¿Me presta?"]
var SHUFFLE := 6.0

var _brenda: FightBrenda
var _phase2 := false
var _fakes: Array = []
var _shuffle_t := SHUFFLE
var _speak_t := 0.5
var _speak_i := 0


func setup() -> void:
	if FinalRush.is_step("brenda"):
		SHUFFLE = 3.5
	waves = [
		{"at": 0.0, "enemies": ["punk", "goon", "punk"]},
		{"at": 320.0, "enemies": ["thug", "punk+knife", "goon", "punk"]},
		{"at": 640.0, "enemies": ["thug", "goon+knife", "punk", "thug+knife"]},
		{"at": 960.0, "enemies": ["brenda"]},
	]
	types = TYPES.duplicate()
	for k in types:  # el episodio 3 pega más que el 2
		types[k] = types[k].duplicate()
		types[k]["hp"] = int(types[k]["hp"] * 1.5)
		types[k]["damage"] = types[k]["damage"] + 1
	types["brenda"] = {"sheet": "res://assets/prologue/brenda.png", "hp": 130, "speed": 64.0, "damage": 6}
	if FinalRush.is_step("brenda"):
		waves = [{"at": 0.0, "enemies": ["brenda"]}]
	items = [["bottle", Vector2(200, 150)], ["pipe", Vector2(430, 160)], ["bottle", Vector2(560, 140)],
		["bottle", Vector2(820, 165)], ["pipe", Vector2(1000, 150)]]
	lines = ["—¡Pasajes para Ibagué! ¡Salimos ya!",
		"—El bus va lleno, joven. Bájese.",
		"—Aquí nadie lo conoce. Mejor para todos.",
		"—..."]
	boss_name = "BRENDA"
	bg_path = "res://assets/prologue/ep3_bg.png"
	intro_title = "SUEÑO 6"
	lilato_cameo = false
	rain = false
	next_scene = NIGHT


func before_start() -> void:
	if FinalRush.is_step("brenda"):
		await Dialogue.talk([["", "El último sueño empieza por donde más dolió."],
			["", "Brenda, otra vez. Esta vez no huye: ya tiene todas las caras puestas."]])
		return
	await Dialogue.talk([
		["", "La llamada. \"No me llame a este número. Aquí no saben de usted.\""],
		["", "Esa noche sueña con una terminal. Un bus a Ibagué. Alguien se sube sin mirar atrás. Camina igual que él."],
		["", "Él sabe quién es. Siempre supo."],
		["", "Este sueño no da risa. Bueno, un poquito, al principio."],
		["ÉL", "Brenda. Mi mamá. Uno ochenta descalza; con tacones agachaba la cabeza para entrar a la cocina. Crema Nivea de la lata azul, chancletas de baño en la calle, una novela a las nueve que no se perdía ni con el apartamento en llamas. Se fue un martes. La novela siguió."],
	])


func _spawn(kind_spec: String, pos: Vector2) -> void:
	if kind_spec != "brenda":
		super._spawn(kind_spec, pos)
		return
	var b := FightBrenda.new()
	var t: Dictionary = types["brenda"]
	b.sheet = load(t["sheet"])
	b.max_hp = t["hp"]
	b.speed = t["speed"]
	b.damage = t["damage"]
	b.position = pos
	b.arena = self
	b.points = 5000
	add_child(b)
	b.knocked_out.connect(_on_brenda_out)
	b.life_changed.connect(hud.set_boss)
	b.spoke.connect(func(l): Narrator.say(l, true))
	_alive.append(b)
	_brenda = b
	hud.show_boss(boss_name)
	hud.set_boss(1.0)
	Narrator.say("BRENDA: —¿Usted qué hace aquí? ¿Quién le dijo dónde estaba?", true)
	if FinalRush.is_step("brenda"):
		await get_tree().create_timer(0.8).timeout
		_start_phase2(b)


## Brenda se escapa, pero dentro de la pantalla (los demás pueden entrar desde afuera).
func walk_bounds(who: Node = null) -> Rect2:
	var r := super.walk_bounds(who)
	if who is FightBrenda:
		r = Rect2(_cam_left + 16.0, r.position.y, VIEW_W - 32.0, r.size.y)
	return r


## Con las copias en pantalla no se da vuelta solo: pegarle a la de atrás puede ser pegarle a una copia.
func auto_turn() -> bool:
	return not _phase2


## Una maleta que vuela por el carril de quien la tira y le pega al primero que agarra.
func enemy_throw(from: Brawler, kind: String) -> void:
	var m := Sprite2D.new()
	m.texture = load("res://assets/prologue/item_%s.png" % kind)
	m.position = from.position + Vector2(from.facing * 12, -18)
	m.z_index = 400
	add_child(m)
	var dir := float(from.facing)
	var lane := from.position.y
	while is_instance_valid(m):
		if not is_inside_tree():
			return
		await get_tree().physics_frame
		if not is_instance_valid(m):
			return
		m.position.x += dir * MALETA_SPEED * get_physics_process_delta_time()
		m.rotation += dir * 0.15
		var p := player
		if p.state not in [Brawler.State.DOWN, Brawler.State.OUT] and absf(p.position.y - lane) <= 9.0 \
				and absf(p.position.x - m.position.x) < 10.0:
			p.take_hit(8, m.position.x - dir * 10.0, false)
			on_hit_landed(p, false)
			m.queue_free()
			return
		if m.position.x < _cam_left - 20.0 or m.position.x > _cam_left + VIEW_W + 20.0:
			m.queue_free()


## La primera vez que la alcanza: no se sienta. Se arranca la cara. LA DE MIL CARAS.
func _start_phase2(b: FightBrenda) -> void:
	_phase2 = true
	b.state = Brawler.State.IDLE
	b.play("idle")
	await Dialogue.talk([
		["", "Ella no se sienta. Se pasa la mano por la cara. La cara se le cae como una máscara."],
		["", "Debajo hay otra. La de Don Germán. Y debajo, otra. Y otra."],
		["BRENDA", "—¿Usted me quiere ver a mí? ¿O a los que sí lo quieren? Escoja. Usted siempre escoge mal."],
		["", "LA DE MIL CARAS. Tres son de mentira. La de verdad siempre pide algo."],
	])
	hud.show_boss("LA DE MIL CARAS")
	b.hp = int(b.max_hp * 0.6)
	hud.set_boss(0.6)
	b.phase2 = true
	b.set_physics_process(true)
	for i in 3:
		_spawn_fake()
	_shuffle()


func _spawn_fake() -> void:
	var f := FightBrenda.new()
	var t: Dictionary = types["brenda"]
	f.sheet = load(t["sheet"])
	f.max_hp = 999
	f.speed = 40.0
	f.damage = 0
	f.fake = true
	f.position = Vector2(_cam_left + randf_range(40.0, VIEW_W - 40.0), randf_range(BAND.x + 6.0, BAND.y - 6.0))
	f.arena = self
	add_child(f)
	_fakes.append(f)
	_alive.append(f)  # para que se le pueda pegar
	_add_face_label(f)


func _add_face_label(b: FightBrenda) -> void:
	var l := Label.new()
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.06))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(90, 10)
	l.position = Vector2(-45, -58 - 10 * (_fakes.size() % 2))  # alternadas, para que no se pisen
	l.z_index = 500
	b.add_child(l)
	b.face_label = l


## Todas cambian de cara (también la de verdad): hay que volver a leerlas.
func _shuffle() -> void:
	var names := FACES.keys()
	names.shuffle()
	var all: Array = [_brenda] + _fakes.filter(func(x): return is_instance_valid(x))
	for i in all.size():
		var b: FightBrenda = all[i]
		var face: String = names[i % names.size()]
		if b.face_label == null:
			_add_face_label(b)
		var line: String = REAL_LINES.pick_random() if b == _brenda else FACES[face].pick_random()
		b.face_label.text = face  # arriba, solo el nombre; la frase la dice cuando le toca hablar
		b.face_label.position.y = -58.0 - 10.0 * i  # cada una a su altura: si se juntan, no se pisan
		b.set_meta("line", line)
		b.face_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
		b.modulate = Color.from_hsv(randf(), 0.25, 1.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _phase2 or phase != Phase.FIGHT:
		return
	_shuffle_t -= delta
	if _shuffle_t <= 0.0:
		_shuffle_t = SHUFFLE
		_shuffle()
	# Hablan de a una: la frase arriba, y la que habla se ilumina.
	_speak_t -= delta
	if _speak_t <= 0.0:
		_speak_t = 1.5
		var all: Array = [_brenda] + _fakes.filter(func(x): return is_instance_valid(x))
		var who: FightBrenda = all[_speak_i % all.size()]
		_speak_i += 1
		if who.face_label and who.has_meta("line"):
			Narrator.say("%s: %s" % [who.face_label.text, who.get_meta("line")], true)
			var tw := create_tween()
			tw.tween_property(who.face_label, "modulate", Color(1.6, 1.6, 0.6), 0.1)
			tw.tween_interval(1.0)
			tw.tween_property(who.face_label, "modulate", Color(1, 1, 1), 0.3)


## Le pegó a una copia: se deshace, y duele igual.
func fake_hit(f: FightBrenda) -> void:
	if not _fakes.has(f):
		return
	_fakes.erase(f)
	_alive.erase(f)
	var face: String = f.face_label.text if f.face_label else "alguien"
	Narrator.say("Le pegué a la cara de %s. Era de mentira. Igual dolió." % face.capitalize(), true)
	player.take_hit(6, f.position.x, false)
	_on_player_hurt(float(player.hp) / player.max_hp)
	var tw := create_tween()
	tw.tween_property(f, "modulate:a", 0.0, 0.5)
	tw.tween_callback(f.queue_free)
	await get_tree().create_timer(3.0).timeout
	if _phase2 and phase == Phase.FIGHT:
		_spawn_fake()
		_shuffle()


## Ella se sienta en el piso. Ya no corre. Abrazarla o dejarla ir.
func _on_brenda_out(b: Brawler) -> void:
	if not _phase2:
		await _start_phase2(b as FightBrenda)
		return
	if FinalRush.is_step("brenda"):
		for f in _fakes:
			_alive.erase(f)
			if is_instance_valid(f):
				f.queue_free()
		_fakes.clear()
		_alive.erase(b)
		await Dialogue.talk([["BRENDA", "—..."], ["YO", "—Ya no te tengo miedo, ma. Ni a vos ni a tus caras."]])
		FinalRush.next()
		return
	for f in _fakes:
		_alive.erase(f)
		if is_instance_valid(f):
			f.queue_free()
	_fakes.clear()
	if _brenda.face_label:
		_brenda.face_label.text = ""
	_brenda.modulate = Color.WHITE
	_alive.erase(b)
	defeated += 1
	Dream.add(b.points)
	_update_hud()
	await get_tree().create_timer(1.0).timeout
	var i := await Dialogue.talk([
		["", "Ella se sienta en el piso. Ya no corre."],
		["BRENDA", "—Perdóneme. O no me perdone. Pero no me pegue más."],
		["BRENDA", "—Yo me fui porque tenía miedo. Usted también tenía miedo, y se quedó."],
	], ["Abrazarla", "Dejarla ir"])
	if i == 0:
		GameState.flags["dream_brenda"] = "abrazo"
		await Dialogue.talk([
			["", "(Ella tiembla. Huele a la misma crema de cuando él era chiquito.)"],
			["BRENDA", "—Usted siempre fue el fuerte. Yo no."],
			["YO", "—No era fuerte, ma. No me quedaba otra."],
		])
	else:
		GameState.flags["dream_brenda"] = "irse"
		await Dialogue.talk([
			["YO", "—Váyase, ma. Ya sé el camino a la terminal."],
			["", "(Ella se sube a otro bus. Esta vez él no corre detrás.)"],
		])
	_sfx["gogogo"].play()
	phase = Phase.EXIT
	hud.set_boss(0.0)


func _level_done() -> void:
	await Dialogue.talk([
		["", "Adentro de la casa hay una olla en el fogón. Sopa. La misma de cuando él tenía siete años."],
		["", "Él se sirve un plato. Solo. Como aprendió."],
		["ÉL", "Sopa de pasta con papa. Ella le echaba cilantro hasta que no se veía la sopa. Yo le echo igual. No sé por qué. Sí sé."],
		["", "BRENDA: COMPLETO."],
	])
	GameState.flags["dream_won"] = true
	GameState.flags["dream_return"] = "callejon3"
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)
