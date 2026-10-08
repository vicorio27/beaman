extends "res://scripts/prologue/FightArena.gd"
## SUEÑO 3 — beat 'em up, episodio 2: retoma donde terminó el sueño 1 (la serpiente cayó al
## río, y él con ella). Empieza en la madriguera de la serpiente; sale a la calle de los que lo
## traicionaron. Jefes en pareja: Camila y Guillermo.
##   - Pelean juntos: Camila pega y se aleja; si la golpean, Guillermo embiste para defenderla.
##   - Si cae Camila primero, Guillermo se rinde: perdonarlo o terminar la pelea.
##   - Si cae Guillermo primero, Camila se va corriendo, riéndose (va a volver).
## Al final de la calle, la terminal: un bus a Ibagué (el episodio 3). Despierta en la noche.

const NIGHT := "res://scenes/world/Night.tscn"

var _camila: FightCamila
var _guillermo: FightBoss
var _camila_out := false
var _guillermo_out := false
var _said_g := false


func setup() -> void:
	waves = [
		{"at": 0.0, "enemies": ["punk", "punk", "goon"]},
		{"at": 320.0, "enemies": ["goon+knife", "thug", "punk", "goon"]},
		{"at": 640.0, "enemies": ["thug", "thug+knife", "punk", "punk"]},
		{"at": 960.0, "enemies": ["guillermo", "camila"]},
	]
	types = TYPES.duplicate()
	for k in types:  # el episodio 2 pega más
		types[k] = types[k].duplicate()
		types[k]["hp"] = int(types[k]["hp"] * 1.25)
	types["camila"] = {"sheet": "res://assets/prologue/camila.png", "hp": 110, "speed": 66.0, "damage": 5}
	types["guillermo"] = {"sheet": "res://assets/prologue/guillermo.png", "hp": 170, "speed": 36.0, "damage": 7,
		"scale": Vector2(1.4, 1.05)}  # gordo, muy gordo
	items = [["bottle", Vector2(180, 150)], ["pipe", Vector2(470, 166)], ["bottle", Vector2(700, 140)],
		["bottle", Vector2(900, 160)], ["pipe", Vector2(1040, 150)]]
	lines = ["—¿Y este de dónde salió? ¿De la alcantarilla?",
		"—Aquí no se le debe nada a nadie. Aquí se cobra.",
		"—Camila dijo que usted vendría.",
		"—..."]
	boss_name = "CAMILA Y GUILLERMO"
	bg_path = "res://assets/prologue/ep2_bg.png"
	intro_title = "SUEÑO 3"
	lilato_cameo = false
	rain = false
	next_scene = NIGHT


## "Anteriormente...": retoma desde el final del sueño 1.
func before_start() -> void:
	await Dialogue.talk([
		["", "ANTERIORMENTE..."],
		["", "Le robaron la mochila. Se colgó de un camión. Le ganó a Lilato y a lo que salió de adentro de ella."],
		["", "La serpiente cayó al río. Y él cayó con ella."],
		["", "Ahora está en su madriguera. Huele a piel mudada y a cosas que nadie dijo."],
		["", "Episodio 2. Las secuelas siempre son peores. Ya lo dijo alguien. Ese alguien también hizo una secuela."],
	])


func _spawn(kind_spec: String, pos: Vector2) -> void:
	if kind_spec == "camila":
		var c := FightCamila.new()
		_setup_boss(c, "camila", pos)
		c.points = 4000
		c.got_hit.connect(_defend_camila)
		c.spoke.connect(func(l): Narrator.say(l, true))
		_camila = c
	elif kind_spec == "guillermo":
		var g := FightBoss.new()
		_setup_boss(g, "guillermo", pos)
		g.points = 4000
		g.life_changed.connect(_guillermo_life)
		_guillermo = g
		Narrator.say("GUILLERMO: —Perdón, parce. Ella me pidió que eligiera.", true)
	else:
		super._spawn(kind_spec, pos)


func _setup_boss(e: FightEnemy, kind: String, pos: Vector2) -> void:
	var t: Dictionary = types[kind]
	e.sheet = load(t["sheet"])
	e.max_hp = t["hp"]
	e.speed = t["speed"]
	e.damage = t["damage"]
	e.body_scale = t.get("scale", Vector2.ONE)
	e.position = pos
	e.arena = self
	add_child(e)
	e.knocked_out.connect(_on_duo_out)
	if e.has_signal("life_changed"):
		e.life_changed.connect(func(_r): _duo_life())
	_alive.append(e)
	hud.show_boss(boss_name)
	_duo_life()


## Una sola barra para los dos.
func _duo_life() -> void:
	var hp := 0.0
	var mx := 0.0
	for e in [_camila, _guillermo]:
		if e != null and is_instance_valid(e):
			hp += maxf(e.hp, 0.0)
			mx += e.max_hp
	hud.set_boss(hp / mx if mx > 0.0 else 0.0)


## Cuando le pegan a Camila, Guillermo sale a defenderla.
func _defend_camila() -> void:
	if _guillermo and is_instance_valid(_guillermo) and not _guillermo_out and _guillermo._charging <= 0.0 \
			and _guillermo.state in [Brawler.State.IDLE, Brawler.State.WALK] and randf() < 0.45:
		_guillermo._start_charge()


func _guillermo_life(ratio: float) -> void:
	if ratio < 0.5 and not _said_g:
		_said_g = true
		Narrator.say("GUILLERMO: —Usted también me habría dejado. Todos se van.", true)


func _on_duo_out(e: Brawler) -> void:
	_alive.erase(e)
	defeated += 1
	Dream.add(e.points)
	_update_hud()
	if e == _camila:
		_camila_out = true
		if _guillermo and is_instance_valid(_guillermo) and not _guillermo_out:
			await _guillermo_gives_up()
	elif e == _guillermo:
		_guillermo_out = true
		if _camila and is_instance_valid(_camila) and not _camila_out:
			_camila_flees()
	_check_end()


## Sin Camila, Guillermo no sabe qué hacer. Se arrodilla.
func _guillermo_gives_up() -> void:
	var g := _guillermo
	g.set_physics_process(false)
	g.set_process(false)
	g.play("getup")
	await get_tree().create_timer(0.8).timeout
	var i := await Dialogue.talk([
		["GUILLERMO", "—¿Y ahora qué hago? Ella decidía todo."],
		["GUILLERMO", "—Usted era mi amigo, parce. Yo los cambié a todos por ella."],
	], ["Perdonarlo", "Terminar la pelea"])
	if i == 0:
		await Dialogue.talk([["YO", "—Yo también lo quería, hermano. Por eso dolió."], ["GUILLERMO", "—..."],
			["GUILLERMO", "—¿Todavía tiene la camiseta del Mundial del 2014? La que cambiamos."], ["YO", "—Me la robaron con la mochila."],
			["GUILLERMO", "—La mía me la botó ella. Dijo que era de pobre."]])
		GameState.flags["dream_forgave_guillermo"] = true
		Dream.add(3000)
		_guillermo_out = true
		_alive.erase(g)
		defeated += 1
		_update_hud()
		var t := create_tween()
		t.tween_property(g, "modulate:a", 0.0, 1.2)
		t.tween_callback(g.queue_free)
		_check_end()
	else:
		Narrator.say("GUILLERMO: —Bueno. Como quiera. Igual ya no me queda nada.", true)
		g.hp = mini(g.hp, 30)
		g.set_physics_process(true)
		g.set_process(true)
		_duo_life()


## Sin Guillermo, Camila se va. Riéndose. Va a volver.
func _camila_flees() -> void:
	var c := _camila
	_alive.erase(c)
	defeated += 1
	_update_hud()
	_camila_out = true
	c.set_physics_process(false)
	c.set_process(false)
	c.set_facing(1)
	c.play("walk")
	Narrator.say("CAMILA: —Igual ya no me servía. Chao, mi amor.", true)
	GameState.flags["dream_camila_escaped"] = true
	var t := create_tween()
	t.tween_property(c, "position:x", c.position.x + 280.0, 1.8)
	t.tween_callback(c.queue_free)


func _check_end() -> void:
	if _alive.is_empty() and phase == Phase.FIGHT:
		_sfx["gogogo"].play()
		phase = Phase.EXIT
		hud.set_boss(0.0)


## Al final de la calle: la terminal. Y alguien conocido subiéndose a un bus.
func _level_done() -> void:
	await Dialogue.talk([
		["", "Al final de la calle hay una terminal. Un bus con letrero: IBAGUÉ."],
		["", "Alguien se sube sin mirar atrás. Camina igual que él."],
		["", "EPISODIO 2 COMPLETO. Continuará."],
	])
	GameState.flags["dream_won"] = true
	GameState.flags["dream_return"] = "callejon2"
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)
