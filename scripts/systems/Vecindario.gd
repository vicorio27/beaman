extends Node
## Cosas del barrio que se ponen por código (lo agrega Location en los lugares de afuera):
##   - LA CAVERNA DE GAMER, la tienda de videojuegos (City, al lado del billar), y Álvaro, "Al", que la
##     atiende: el único amigo que tiene. Abre de 10 a 8. Lo que dice: Conversations._amigo.
##   - Las canecas (trash_*, dumpster_*): se pueden esculcar (Conversations._caneca).
##   - En la esquina de la avenida, sin postes en la mitad: los semáforos y las cebras son de Traffic.gd.
##   - José Mario Camilo, en el centro, en la puerta de La Empresa: su jefe de antes. Sale después de
##     que muere Lukas (de 7 a 6) y le ofrece el último trabajo que él hace (Conversations._ultimo_trabajo).
##   - Tom Queen, el padrino (el buhonero; "algunos me dicen el Lobo"): alguien que solo ve él. Alto,
##     bigote blanco, sombrero negro, todo de negro. Sale algunos días (más seguido entre más
##     lo busca), parado donde no hay nada. Soluciona problemas y no cobra plata: cobra en locura, y con
##     la locura se le van borrando las caras a los demás (Conversations._buhonero).
##   - Los otros perros. Cuando Lukas pasa cerca de un perro de la calle, se encuentran: si Lukas no
##     ha comido hoy, casi siempre pelean; si ya comió, casi siempre juegan. A veces es al revés,
##     porque sí. Una vez al día por perro.
##   - El palo de guayaba (el primer árbol con hojas de cada lugar): comida gratis. Quita poquita
##     hambre, cada una menos que la anterior, y a la tercera se hostiga (Conversations._frutas).
## Flags: perro_visto_<nombre> (día), perros_jugo / perros_peleo (cuántas veces).

const SHOP_AT := Vector2(440, 200)   # el pie de la fachada
const SHOP_OPEN := 10.0
const SHOP_CLOSE := 20.0
const MEET_DIST := 30.0
const JOSE_MARIO_AT := Vector2(392, 208)  # en la puerta del edificio de vidrio
## Donde se para el buhonero: sitios donde no hay nadie.
const BUHONERO_AT := {"City": [Vector2(70, 70), Vector2(520, 130), Vector2(840, 566)]}
## Perros que no están en el mapa y salen por aquí: [nombre, textura, posición].
const STRAYS := {
	"Parque": [["dog_parque", "res://assets/barrio/dog_b.png", Vector2(388, 356)]],
}
const PLAY := [
	"(Lukas y el otro se huelen el currículum. Aprobados. Corren en círculos alrededor de nada.)",
	"(Juegan a que uno persigue y el otro también. No hay reglas ni árbitro. Funciona mejor que el fútbol.)",
	"(Se revuelcan en la tierra. Lukas sale más sucio y más contento. Las dos cosas le lucen.)",
]
const FIGHT_HUNGRY := [
	"(Lukas no ha comido. Con hambre no conoce a nadie. Se van a los dientes por un hueso que ninguno de los dos tiene.)",
	"(El otro perro olía a almuerzo. Lukas no ha almorzado. Hubo un malentendido con colmillos.)",
]
const FIGHT_RANDOM := [
	"(Se miran. Algo se dijeron, en perro. Fue grave. Se agarran.)",
	"(Ayer se caían bien. Hoy no. Los perros tampoco explican.)",
]

var _scene: Node
var _world: Node
var _dogs: Array = []
var _friend: Node2D
var _check := 0.0
var _busy := false
var _hit: AudioStreamPlayer


func _ready() -> void:
	_scene = get_parent()
	_world = _scene.get_node_or_null("World")
	if _world == null:
		_world = _scene
	_hit = AudioStreamPlayer.new()
	_hit.stream = load("res://assets/audio/hit-1.wav")
	_hit.volume_db = -10.0
	add_child(_hit)
	_setup.call_deferred()


func _setup() -> void:
	if _scene.name == "City":
		_add_shop()
		for pole in ["pole_426_300", "pole_864_300"]:  # (estaban metidos en la avenida)
			var pn := _world.find_child(pole, false, false)
			if pn:
				pn.queue_free()
	for n in _world.find_children("*", "", false, false):  # las canecas: esculcar
		var nm := str(n.name)
		if (nm.begins_with("trash_") or nm.begins_with("dumpster_")) and n is Node2D:
			var spot := Area2D.new()
			spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
			spot.name = "Caneca_" + nm
			spot.service_id = "caneca"
			spot.hint = "ESCULCAR"
			spot.area = Vector2(22, 16)
			spot.position = (n as Node2D).position + Vector2(0, 8)
			_world.add_child(spot)
	var f := GameState.flags
	var h := fmod(TimeManager.minutes / 60.0, 24.0)
	if _scene.name == "Centro" and not GameState.lukas_alive() and GameState.day > int(f.get("lukas_muerto", GameState.day)) \
			and not f.has("ultimo_trabajo") and h >= 7.0 and h < 18.0:
		var jm := CharacterBody2D.new()
		jm.set_script(load("res://scripts/npc/NPC.gd"))
		jm.name = "JoseMario"
		jm.npc_id = "josemario"
		jm.sheet_row = 6
		jm.face = "down"
		jm.position = JOSE_MARIO_AT
		_world.add_child(jm)
	for spec in STRAYS.get(_scene.name, []):
		var d := Sprite2D.new()
		d.name = spec[0]
		d.texture = load(spec[1])
		d.centered = false
		d.offset = Vector2(-10, -14)
		d.position = spec[2]
		_world.add_child(d)
	_add_buhonero()
	var tree := _world.find_child("tree_sparse*", false, false) as Node2D
	if tree:
		for at in [Vector2(-9, -34), Vector2(6, -40), Vector2(11, -28), Vector2(-3, -26)]:  # las guayabas
			var g := ColorRect.new()
			g.size = Vector2(2, 2)
			g.color = Color(0.95, 0.82, 0.3)
			g.position = at
			tree.add_child(g)
		var spot := Area2D.new()
		spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
		spot.name = "Servicio_frutas"
		spot.service_id = "frutas"
		spot.hint = "GUAYABAS"
		spot.area = Vector2(30, 16)
		spot.position = tree.position + Vector2(0, 8)
		_world.add_child(spot)
	for n in _world.find_children("dog_*", "", false, false):
		if n is Node2D:
			_dogs.append(n)


## El buhonero: algunos días, en un sitio solo. Un día sí lo sacó la suerte, otro no (la misma todo el día).
func _add_buhonero() -> void:
	var spots: Array = BUHONERO_AT.get(_scene.name, [])
	var f := GameState.flags
	if spots.is_empty() or GameState.day < 3 or f.get("buhonero_dia", -1) == GameState.day:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("buhonero%d" % GameState.day)
	if rng.randf() > minf(0.3 + 0.05 * int(f.get("buhonero_n", 0)), 0.75):
		return
	var b := CharacterBody2D.new()
	b.set_script(load("res://scripts/npc/NPC.gd"))
	b.name = "Buhonero"
	b.npc_id = "buhonero"
	b.sheet_row = 9
	b.face = "down"
	b.position = spots[rng.randi() % spots.size()]
	_world.add_child(b)
	_haunt.call_deferred(b)


## No es de aquí: alto, de negro, y titila un poco.
func _haunt(b: Node2D) -> void:
	await get_tree().process_frame
	if not is_instance_valid(b):
		return
	var sp: Node2D = b.get("sprite")
	sp.modulate = Color(0.3, 0.28, 0.36)
	sp.scale = Vector2(1.0, 1.18)
	sp.position.y -= 2.0
	var t := sp.create_tween().set_loops()
	t.tween_property(sp, "modulate:a", 0.55, 0.9)
	t.tween_property(sp, "modulate:a", 1.0, 0.9)


func _add_shop() -> void:
	var shop := Sprite2D.new()
	shop.name = "videojuegos"
	shop.texture = load("res://assets/barrio/videojuegos.png")
	shop.centered = false
	shop.offset = Vector2(-55, -70)
	shop.position = SHOP_AT
	_world.add_child(shop)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(108, 26)
	shape.shape = rect
	shape.position = Vector2(0, -14)
	body.add_child(shape)
	shop.add_child(body)
	# El que atiende: en la puerta, mirando para la calle. (Cerrado, no está: ver _process.)
	_friend = CharacterBody2D.new()
	_friend.set_script(load("res://scripts/npc/NPC.gd"))
	_friend.name = "Amigo"
	_friend.npc_id = "amigo"
	_friend.sheet_row = 9
	_friend.face = "down"
	_friend.position = SHOP_AT + Vector2(60, 4)  # al lado, para que el aviso no tape el letrero
	_world.add_child(_friend)
	_shop_hours()


func _shop_hours() -> void:
	if not is_instance_valid(_friend):
		return
	var h := fmod(TimeManager.minutes / 60.0, 24.0)
	var open := h >= SHOP_OPEN and h < SHOP_CLOSE
	if _friend.visible != open:
		_friend.visible = open
		_friend.process_mode = Node.PROCESS_MODE_INHERIT if open else Node.PROCESS_MODE_DISABLED
		_friend.collision_layer = 1 if open else 0
	var shop := _world.get_node_or_null("videojuegos") as CanvasItem
	if shop:
		shop.self_modulate = Color.WHITE if open else Color(0.55, 0.55, 0.65)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.3
	_shop_hours()
	if _busy or Dialogue.active or GameState.ui_open or SceneRouter.busy or GameState.input_blocked():
		return
	var lukas := _scene.find_child("Lukas", true, false) as Node2D
	if lukas == null or not GameState.lukas_alive() or not str(lukas.get("state")) in ["follow", "sit"]:
		return
	for d in _dogs:
		if not is_instance_valid(d) or not d.visible:
			continue
		var key := "perro_visto_" + str(d.name)
		if GameState.flags.get(key, -1) == GameState.day:
			continue
		if d.global_position.distance_to(lukas.global_position) < MEET_DIST:
			GameState.flags[key] = GameState.day
			_meet(lukas, d)
			return


## Lukas y otro perro: juegan o pelean. Con hambre, casi siempre pelean.
func _meet(lukas: Node2D, dog: Node2D) -> void:
	_busy = true
	var f := GameState.flags
	var hungry: bool = f.get("lukas_fed_day", -1) != GameState.day
	var fight: bool = randf() < (0.65 if hungry else 0.15)
	GameState.block_input(2.2)
	lukas.set_physics_process(false)
	var l0 := lukas.position
	var d0 := dog.position
	var mid := (l0 + d0) / 2.0
	if fight:
		for k in 5:  # se van encima, se sueltan, otra vez
			var t := create_tween().set_parallel()
			t.tween_property(lukas, "position", mid + Vector2(-3, 0), 0.08)
			t.tween_property(dog, "position", mid + Vector2(3, 0), 0.08)
			await t.finished
			_hit.play()
			lukas.modulate = Color(1.0, 0.6, 0.6)
			dog.modulate = Color(1.0, 0.6, 0.6)
			var back := create_tween().set_parallel()
			back.tween_property(lukas, "position", mid + Vector2(-11, randf_range(-3, 3)), 0.1)
			back.tween_property(dog, "position", mid + Vector2(11, randf_range(-3, 3)), 0.1)
			await back.finished
			lukas.modulate = Color.WHITE
			dog.modulate = Color.WHITE
	else:
		var spin := create_tween()  # se persiguen en círculo
		spin.tween_method(func(a: float) -> void:
			lukas.position = mid + Vector2(cos(a), sin(a) * 0.6) * 13.0
			dog.position = mid - Vector2(cos(a), sin(a) * 0.6) * 13.0, 0.0, TAU * 2.5, 1.8)
		await spin.finished
	var home := create_tween().set_parallel()
	home.tween_property(lukas, "position", l0, 0.2)
	home.tween_property(dog, "position", d0, 0.2)
	await home.finished
	lukas.set_physics_process(true)
	if fight:
		f["perros_peleo"] = int(f.get("perros_peleo", 0)) + 1
		var lines := [["", (FIGHT_HUNGRY if hungry else FIGHT_RANDOM).pick_random()]]
		if hungry and randf() < 0.4:
			lines.append(["", "(Lukas sale con un hueso que no era de él. Lo defiende con todo el cuerpo. Desayunó.)"])
			f["lukas_fed_day"] = GameState.day
			f.erase("lukas_hungry")
		else:
			lines.append(["", "(Él los separa con el saco. El saco pierde un botón. Lukas camina adelante, ofendido, como si hubiera ganado.)"])
			if hungry:
				lines.append(["", "(Con la barriga llena, Lukas es otro. Con la barriga vacía, también: es este.)"])
		await Dialogue.talk(lines)
		GameState.change_mood(-3.0)
	else:
		f["perros_jugo"] = int(f.get("perros_jugo", 0)) + 1
		await Dialogue.talk([["", PLAY.pick_random()]])
		GameState.change_mood(4.0)
		GameState.company(6.0)
	_busy = false
