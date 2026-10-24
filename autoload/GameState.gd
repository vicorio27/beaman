extends Node
## Estado de la vida real (no de los sueños): plata, hambre, día, mochila y marcas de historia.
## Chico a propósito (spec, sección 30). Lo lee el HUD, el filtro de ánimo, el jugador y las misiones.

signal hunger_changed(value: float)
signal money_changed(value: int)
signal inventory_changed
## Se desmayó de hambre (lo maneja Survival).
signal fainted
## Comió algo (para las misiones).
signal ate(item_id: String)
## Cuánta plata entró (+) o salió (-): Player.gd lo muestra (la mano, el billete, "+$5.000").
signal money_delta(amount: int)
## Una misión empezó ("active") o se cumplió ("done").
signal quest_changed(id: String, status: String)
signal hygiene_changed(value: float)
## El ánimo: lo bajan el desprecio de la gente, los robos y las malas noches; lo suben Lukas,
## la comida caliente, Germán, un cambuche mejor. Con ánimo bajo, el mundo se ve peor (MoodFilter).
signal mood_changed(value: float)
## La soledad cambió (0: acompañado, 100: hace mucho que no habla con nadie).
signal loneliness_changed(value: float)
signal skill_learned(id: String)
## El vínculo con alguien del barrio subió (0 a 3; se sube con favores).
signal bond_changed(id: String, level: int)
## El cambuche cambió (se armó, se mudó, se mejoró, se guardó algo).
signal cambuche_changed

const SLOTS := 10  # (los dos últimos, cuando Wilson le cose la mochila: bag_slots)
## Cuánta hambre se pierde por hora de juego (spec: de 80 a 20 en un día sin comer).
const HUNGER_PER_HOUR := 4.0
## Higiene: baja con las horas; debajo de DIRTY algunos negocios no lo atienden.
const HYGIENE_PER_HOUR := 1.6
## Soledad: sube sola con las horas; baja hablando con la gente, con Lukas, viendo fútbol con
## desconocidos. Muy alta, el ánimo se va cayendo (ver pass_time). En el HUD se ve como "compañía".
const LONELY_PER_HOUR := 5.0
const LONELY := 70.0
const DIRTY := 40.0
## Meta de la alcancía (el regalo para la hija).
const GIFT_GOAL := 150000
## Chance de que lo roben según dónde durmió (la pensión es segura).
const THEFT := {"banco": 0.45, "kiosco": 0.3, "rio": 0.15, "callejon": 0.6, "parque": 0.2, "lote": 0.1, "pension": 0.0}
## Lugares donde se puede armar un cambuche.
## Donde arma el cambuche: donde lo armaría alguien que vive en la calle. Lugares solos, o un parque.
## El callejón de las bodegas no: queda al lado del billar, y los que salen de ahí vuelven nada a
## cualquiera (se puede dormir, pero es donde más roban).
const CAMBUCHE_SPOTS := ["rio", "lote", "parque", "kiosco"]
## Lo caliente levanta el ánimo, no solo la panza.
## Niveles del cambuche: 1 Cartones, 2 Cambuche (toldo + cobija), 3 Rancho (paredes de estibas),
## 4 Ranchito (techo de zinc y radio). Cada nivel: más lugar en la caja, menos robos, más ánimo.
const CAMBUCHE_NAMES := ["", "Cartones", "Cambuche", "Rancho", "Ranchito"]
const BOX_CAPACITY := [0, 4, 6, 8, 10]
const LEVEL_THEFT := [1.0, 1.0, 0.8, 0.5, 0.3]
const LEVEL_MOOD := [0.0, 0.0, 3.0, 6.0, 10.0]
const HOT_FOOD := ["sopa", "arepa", "tinto", "aguapanela", "empanada"]
## Ánimo de la noche según dónde durmió (el cambuche suma según su nivel).
const SLEEP_MOOD := {"banco": -5.0, "kiosco": -3.0, "pension": 8.0}

var money := 0
var hunger := 80.0
var hygiene := 70.0
var mood := 55.0
var loneliness := 20.0
## Habilidades aprendidas (ver scripts/systems/Skills.gd).
var skills: Array = []
## Vínculos con la gente del barrio: npc_id -> 0..3. Cada nivel abre algo (ver Conversations).
var bonds := {}
const BOND_NAMES := {"german": "Don Germán", "marta": "Marta", "samuel": "Samuel", "rosa": "Doña Rosa", "wilson": "Wilson"}
## Hasta qué minuto del reloj dura la calma de acariciar a Lukas (baja la angustia del filtro).
var calm_until := -1.0
## El cambuche: {} si no hay. Si hay: spot, toldo, cocinita, candado, cobija (bool),
## box (Array de {"id", "qty"}), alcancia (int).
var cambuche := {}
var day := 1
## Mochila: SLOTS casilleros; cada uno {"id": String, "qty": int} o null.
var inventory: Array = []
## Misiones: id -> "active" / "done" (ver Quests.gd). Marcas de historia (memorias, zonas abiertas).
var quests := {}
var flags := {}
## Hay alguna ventana abierta (mochila, diálogo): el jugador no se mueve y el reloj se frena.
var ui_open := false:
	set(v):
		# Un minijuego que se cierra con un diálogo encima: el diálogo sigue abierto, y al cerrarse
		# ya no devuelve el minijuego (Dialogue._ui_was).
		if not v and Dialogue.active:
			Dialogue._ui_was = false
			return
		ui_open = v
## Estadísticas del día (para el resumen al dormir).
var stats := {"money_earned": 0, "food_eaten": 0, "segundos": 0.0}
var _block_until := 0


## Hay una ventana abierta o se acaba de cerrar una (evita que el mismo botón que cierra un
## diálogo agarre algo o abra una puerta).
func input_blocked() -> bool:
	return ui_open or Time.get_ticks_msec() < _block_until


func block_input(seconds: float) -> void:
	_block_until = Time.get_ticks_msec() + int(seconds * 1000.0)


func _ready() -> void:
	new_game()


## El tiempo jugado de verdad (segundos de reloj, mientras corre el juego). Sale al final.
func _process(delta: float) -> void:
	if not get_tree().paused:
		stats["segundos"] = float(stats.get("segundos", 0.0)) + delta


## Una línea de la lista, distinta cada vez: rota en orden (la cuenta va en las banderas, se guarda).
func rota(key: String, opts: Array) -> String:
	var n := int(flags.get("rota_" + key, 0))
	flags["rota_" + key] = n + 1
	return str(opts[n % opts.size()])


func play_time_text() -> String:
	var t := int(stats.get("segundos", 0.0))
	return "%d h %02d min" % [t / 3600, (t / 60) % 60]


func new_game() -> void:
	money = 0
	hunger = 80.0
	hygiene = 70.0
	mood = 55.0
	loneliness = 20.0
	skills = []
	bonds = {}
	calm_until = -1.0
	cambuche = {}
	day = 1
	flags = {}
	quests = {}
	stats = {"money_earned": 0, "food_eaten": 0, "segundos": 0.0}
	# Día 1.
	for id in ["conseguir_comida", "latas", "cartones", "lukas_olfato", "lo_bueno"]:
		quests[id] = "active"
	inventory.clear()
	inventory.resize(SLOTS)
	add_item("foto")
	add_item("camiseta")


# ---------------------------------------------------------------- Hambre

func set_hunger(value: float) -> void:
	var old := hunger
	hunger = clampf(value, 0.0, 100.0)
	if not is_equal_approx(old, hunger):
		hunger_changed.emit(hunger)
	if hunger <= 0.0 and old > 0.0:
		fainted.emit()


## El reloj avanzó `minutes` minutos de juego.
func pass_time(minutes: float) -> void:
	# Con Lukas al lado la soledad sube más despacio. Sin él, más rápido.
	set_loneliness(loneliness + LONELY_PER_HOUR * (0.7 if lukas_alive() else 1.5) * minutes / 60.0)
	if loneliness >= LONELY:
		change_mood(-1.5 * minutes / 60.0)
	if not lukas_alive():
		set_hygiene(hygiene - HYGIENE_PER_HOUR * minutes / 60.0)
		return  # ya no le da hambre (ver grief)
	set_hunger(hunger - HUNGER_PER_HOUR * (1.0 + 0.4 * diff("hambre")) * minutes / 60.0)
	set_hygiene(hygiene - HYGIENE_PER_HOUR * (1.0 + 0.5 * diff("cuerpo")) * minutes / 60.0)


func set_loneliness(value: float) -> void:
	var old := loneliness
	loneliness = clampf(value, 0.0, 100.0)
	if not is_equal_approx(old, loneliness):
		loneliness_changed.emit(loneliness)
	if old < LONELY and loneliness >= LONELY and not flags.get("soledad_aviso", false):
		flags["soledad_aviso"] = true
		Narrator.say("(Hace horas que no habla con nadie. Se le baja la barra de compañía, arriba. A Lukas sí le puede hablar: su menú, Hablarle.)")


## Alguien le habló (o él le habló a Lukas): baja la soledad.
func company(amount: float) -> void:
	set_loneliness(loneliness - amount)


func is_lonely() -> bool:
	return loneliness >= LONELY


func set_hygiene(value: float) -> void:
	var old := hygiene
	hygiene = clampf(value, 0.0, 100.0)
	if not is_equal_approx(old, hygiene):
		hygiene_changed.emit(hygiene)


func change_mood(delta: float) -> void:
	var old := mood
	mood = clampf(mood + delta, 0.0, 100.0)
	if not is_equal_approx(old, mood):
		mood_changed.emit(mood)


## 0 = muy mal, 1 = mal, 2 = regular, 3 = bien.
func mood_level() -> int:
	return 0 if mood < 15.0 else (1 if mood < 35.0 else (2 if mood < 65.0 else 3))


func is_dirty() -> bool:
	return hygiene < DIRTY


func is_calm() -> bool:
	return TimeManager.minutes < calm_until


# ---------------------------------------------------------------- Misiones

func start_quest(id: String) -> void:
	if quests.get(id, "") == "":
		quests[id] = "active"
		quest_changed.emit(id, "active")


func complete_quest(id: String) -> void:
	if quests.get(id, "") == "active":
		quests[id] = "done"
		quest_changed.emit(id, "done")


func is_active(id: String) -> bool:
	return quests.get(id, "") == "active"


## La principal activa (o "" si no hay).
func main_quest() -> String:
	if is_active("donde_dormir"):
		return "donde_dormir"
	# La más reciente: es el paso actual de la historia.
	var ids := quests.keys()
	ids.reverse()
	for id in ids:
		if quests[id] == "active" and Quests.kind(id) == "main":
			return id
	return ""


## Activas de un tipo, en orden.
func active_quests(kind: String) -> Array:
	return quests.keys().filter(func(id): return quests[id] == "active" and Quests.kind(id) == kind)


# ---------------------------------------------------------------- Plata

func add_money(amount: int) -> void:
	if amount > 0:
		stats["money_earned"] += amount
	var before := money
	money = maxi(0, money + amount)
	money_changed.emit(money)
	if money != before:
		money_delta.emit(money - before)


# ---------------------------------------------------------------- Mochila

## Los casilleros que se pueden usar: 8, o 10 con la mochila cosida por Wilson (flag mochila_grande).
func bag_slots() -> int:
	return SLOTS if flags.get("mochila_grande", false) else 8


## Agrega; devuelve cuántos no entraron (0 = entró todo).
func add_item(id: String, qty := 1) -> int:
	var stack: int = Items.info(id)["stack"]
	for i in bag_slots():  # primero completar pilas existentes
		var s = inventory[i]
		if qty > 0 and s != null and s["id"] == id and s["qty"] < stack:
			var n := mini(qty, stack - s["qty"])
			s["qty"] += n
			qty -= n
	for i in bag_slots():
		if qty > 0 and inventory[i] == null:
			var n := mini(qty, stack)
			inventory[i] = {"id": id, "qty": n}
			qty -= n
	inventory_changed.emit()
	return qty


func count(id: String) -> int:
	var total := 0
	for s in inventory:
		if s != null and s["id"] == id:
			total += s["qty"]
	return total


func remove_item(id: String, qty := 1) -> bool:
	if count(id) < qty:
		return false
	for i in range(SLOTS - 1, -1, -1):
		var s = inventory[i]
		if qty > 0 and s != null and s["id"] == id:
			var n := mini(qty, s["qty"])
			s["qty"] -= n
			qty -= n
			if s["qty"] <= 0:
				inventory[i] = null
	inventory_changed.emit()
	return true


func remove_slot(i: int, qty := 1) -> void:
	var s = inventory[i]
	if s == null:
		return
	s["qty"] -= qty
	if s["qty"] <= 0:
		inventory[i] = null
	inventory_changed.emit()


func has_space_for(id: String) -> bool:
	var stack: int = Items.info(id)["stack"]
	for i in bag_slots():
		var s = inventory[i]
		if s == null or (s["id"] == id and s["qty"] < stack):
			return true
	return false


## La locura: sube con el tiempo perdido, las cosas raras y lo violento. Él no lo sabe: el
## jugador lo nota en cómo cambia lo que él ve y oye (0: está bien, 1: raro, 2: ya habla con las cosas).
## "TODOS IGUALES": al principio cada uno se ve como es, con su color y su cara. Con los días, la locura
## y (después) el duelo por Lukas, se les apagan los colores y se les va borrando la cara hasta quedar
## todos iguales: un maniquí gris. Primero los desconocidos, después los conocidos (los más queridos,
## los últimos). Victoria y Lukas nunca: son lo único que ve de verdad. Él a sí mismo se ve bien.
## flags["iguales"]: "gradual" (el juego), "siempre" o "no" (para probar; se cambia con F4).
## Devuelve 0 (como es) a 1 (igual a todos).
func sameness(id := "", stranger := true) -> float:
	if id in ["victoria", "lukas", "buhonero"]:  # (Tom Queen no: él es el que se lleva las caras)
		return 0.0
	match str(flags.get("iguales", "gradual")):
		"siempre":
			return 1.0
		"no":
			return 0.0
	var p := clampf(0.5 * float(day - 1) / 40.0 + 0.5 * float(flags.get("locura", 0)) / 20.0 + 0.3 * grief(), 0.0, 1.0)
	if stranger:
		return smoothstep(0.05, 0.5, p)
	return smoothstep(0.3 + 0.05 * bond(id), 0.95, p)


## ¿Ya lo ve igual a todos, del todo?
func sees_same(id := "", stranger := true) -> bool:
	return sameness(id, stranger) >= 1.0


## El tinte de alguien: se le va apagando con lo demás.
func same_tint(c: Color, id := "", stranger := true) -> Color:
	return c.lerp(Color.WHITE, sameness(id, stranger))


func add_locura(n: int) -> void:
	flags["locura"] = int(flags.get("locura", 0)) + n


func locura_level() -> int:
	var l := int(flags.get("locura", 0))
	return 0 if l < 5 else (1 if l < 12 else 2)


## Los trucos de Lukas: se aprenden en 3 sesiones (una por día). Cada uno sirve para algo.
const LUKAS_TRICKS := {
	"sentarse": ["Sentarse", "Al pedir, el número de Lukas paga más."],
	"pata": ["Dar la pata", "Las señoras no se resisten. Victoria se lo pide."],
	"muerto": ["Hacerse el muerto", "Si entra un ladrón al cambuche, se asusta: cuenta como un golpe ganado."],
	"saludar": ["Saludar en dos patas", "La gente que pasa es más amable."],
}


func lukas_knows(trick: String) -> bool:
	return int(flags.get("truco_" + trick, 0)) >= 3


func lukas_sick() -> bool:
	return flags.has("lukas_enfermo") or lukas_stage() >= 2


## Los días después de Lukas: 0 antes; sube cada día (el color, el paso, él mismo).
func grief() -> float:
	if lukas_alive():
		return 0.0
	return clampf(0.35 + 0.15 * float(day - int(flags["lukas_muerto"])), 0.0, 0.95)


## Cuánto le cuesta caminar (1 = normal).
func walk_factor() -> float:
	return 1.0 - 0.45 * grief()


func lukas_alive() -> bool:
	return not flags.has("lukas_muerto")


## La enfermedad larga (el corazón; está viejito). 0: sano. 1: tose de noche. 2: come la mitad, camina
## lento. 3: duerme casi todo el día. 4: ya no está. Empieza el día 30 y no tiene cura.
func lukas_stage() -> int:
	if flags.has("lukas_muerto"):
		return 4
	if not flags.has("lukas_cronico_dia"):
		return 0
	var d: int = day - int(flags["lukas_cronico_dia"])
	return 1 if d < 4 else (2 if d < 8 else 3)


## ¿Esta noche se muere? Cuando ya está por tener lo de Victoria (el testigo), o a más tardar el día 43;
## y solo si lleva por lo menos ocho días enfermo (que no sea de un momento a otro).
func lukas_dies_tonight() -> bool:
	if not lukas_alive() or not flags.has("lukas_cronico_dia"):
		return false
	if day - int(flags["lukas_cronico_dia"]) < 8:
		return false
	return flags.get("testigo", false) or day >= 43


## Los pedazos de la foto (el coleccionable). Lo que piensa al encontrar el pedazo número n.
const PHOTO_PIECES := 7
const PHOTO_LINES := [
	"Un pedazo de foto, mojado. El borde encaja con el de la mochila.",
	"Otro pedazo. Un hombro y una camisa a cuadros.",
	"Una oreja grande.",
	"Medio ojo.",
	"La punta de un bigote negro.",
	"Una sonrisa.",
	"El último pedazo. Le tiemblan las manos.",
]


func photo_line(n: int) -> String:
	return "%s (%d/%d)" % [PHOTO_LINES[clampi(n - 1, 0, PHOTO_LINES.size() - 1)], n, PHOTO_PIECES]


## Qué tan protegido está el cambuche esta noche (multiplica la chance de que entre alguien).
func cambuche_guard() -> float:
	var g := 1.0
	if cambuche.get("alarma", false):
		g *= 0.75
	if cambuche.get("trampa", false):
		g *= 0.75
	if lukas_on_guard():
		g *= 0.7
	if flags.get("samuel_cuida_day", -1) == day:
		g *= 0.35
	return g


## Lukas está de guardia si hoy comió y tomó agua (o si tienen el lazo: duerme con una oreja parada).
func lukas_on_guard() -> bool:
	if not lukas_alive() or lukas_stage() >= 3:
		return false
	return has_skill("lazo_lukas") or (flags.get("lukas_fed_day", -1) == day and flags.get("lukas_water_day", -1) == day)


## ¿Esta noche alguien se mete al cambuche donde duerme? (Night lo resuelve con el minijuego.)
func intruder_tonight(spot: String) -> bool:
	if not has_cambuche(spot) or int(flags.get("buhonero_noche", -9)) == day:
		return false
	if flags.get("force_intruder", false) or int(flags.get("intruso_dia", -1)) == day:  # para probar; o Zaida lo vendió
		return true
	var p: float = THEFT.get(spot, 0.3) * LEVEL_THEFT[cambuche_level()] * (1.0 + 0.6 * diff("robos")) * cambuche_guard()
	return randf() < p * 1.4  # algo más seguido que un robo: se puede defender


## Usar el objeto del casillero i. Devuelve una línea para mostrar.
func use_slot(i: int) -> String:
	var s = inventory[i]
	if s == null:
		return ""
	var it := Items.info(s["id"])
	match it["type"]:
		"comida":
			var id: String = s["id"]
			set_hunger(hunger + it["food"])
			if id in HOT_FOOD:
				change_mood(3.0)
				flags["caliente_dia"] = day  # (la tos: algo caliente esa noche la frena un poquito)
			remove_slot(i)
			stats["food_eaten"] += 1
			ate.emit(id)
			return "(Come: %s.)" % it["name"].to_lower()
		"especial":
			return it["desc"]
		"pista":
			return it["desc"] + " (Va al tablero del cambuche.)"
		"coleccionable":
			return "(Pedazos de la foto: %d de %d.)" % [count("pedazo_foto"), PHOTO_PIECES]
		"rareza":  # le habla; cuanto más loco, más le contesta
			add_locura(1)
			var lines: Array = it.get("use", [it["desc"]])
			return lines[mini(locura_level(), lines.size() - 1)]
		"ingrediente":
			return "(Crudo no: hace falta la cocinita del cambuche.)"
		"lukas":
			return "(Es de Lukas: F para dárselo.)"
		"juguete":
			return "(Para jugar con Lukas: F.)"
		_:
			return "(Eso no se come.)"


## Lo pierde al desmayarse: algo al azar que no sea especial.
func lose_random_item() -> String:
	var candidates := []
	for i in SLOTS:
		var s = inventory[i]
		if s != null and not Items.info(s["id"]).get("fixed", false):
			candidates.append(i)
	if candidates.is_empty():
		return ""
	var i: int = candidates.pick_random()
	var name: String = Items.info(inventory[i]["id"])["name"]
	inventory[i] = null
	inventory_changed.emit()
	return name


## Combinar: gasta los ingredientes y agrega el resultado. Devuelve una línea para mostrar.
func craft(result: String) -> String:
	if not Items.can_craft(result):
		return "(Faltan: %s.)" % Items.recipe_text(result)
	var need: Dictionary = Items.RECIPES[result]
	for id in need:
		remove_item(id, need[id])
	if add_item(result) > 0:
		for id in need:  # no entró: devuelve todo
			add_item(id, need[id])
		return "(No cabe en la mochila.)"
	return "(Arma: %s.)" % Items.info(result)["name"].to_lower()


# ---------------------------------------------------------------- Cambuche

func has_cambuche(spot := "") -> bool:
	return not cambuche.is_empty() and (spot == "" or cambuche["spot"] == spot)


func build_cambuche(spot: String) -> void:
	cambuche = {"spot": spot, "toldo": false, "cocinita": false, "candado": false, "cobija": false,
		"paredes": false, "zinc": false, "box": [], "alcancia": 0}
	cambuche_changed.emit()


## Se muda con todo (mejoras, caja y alcancía).
func cambuche_level() -> int:
	if cambuche.is_empty():
		return 0
	if cambuche.get("zinc", false):
		return 4
	if cambuche.get("paredes", false):
		return 3
	if cambuche["toldo"] and cambuche["cobija"]:
		return 2
	return 1


func cambuche_mood() -> float:
	return LEVEL_MOOD[cambuche_level()] + extra_mood(cambuche)


## Lo que suman el piso de cartón y la cama de estibas (Items.BUILDS) al ánimo de la noche.
static func extra_mood(c: Dictionary) -> float:
	return (2.0 if c.get("piso", false) else 0.0) + (2.0 if c.get("cama_estiba", false) else 0.0)


func box_capacity() -> int:
	return BOX_CAPACITY[cambuche_level()] + (2 if cambuche.get("repisa", false) else 0)


func move_cambuche(spot: String) -> void:
	cambuche["spot"] = spot
	cambuche_changed.emit()


func box_add(id: String, qty: int) -> void:
	for s in cambuche["box"]:
		if s["id"] == id:
			s["qty"] += qty
			cambuche_changed.emit()
			return
	cambuche["box"].append({"id": id, "qty": qty})
	cambuche_changed.emit()


func box_take(index: int) -> void:
	var s: Dictionary = cambuche["box"][index]
	var left := add_item(s["id"], s["qty"])
	if left == 0:
		cambuche["box"].remove_at(index)
	else:
		s["qty"] = left
	cambuche_changed.emit()


# ---------------------------------------------------------------- Un día nuevo

## ¿Ahí no se moja? La pensión, el kiosco viejo, o el cambuche con toldo.
func roofed(spot: String) -> bool:
	return spot == "pension" or spot == "kiosco" or (has_cambuche(spot) and cambuche["toldo"])


## Pasa la noche en `spot` y arranca el día siguiente. Devuelve las líneas de la mañana.
func new_day(spot: String) -> Array:
	var lines := []
	var in_cambuche := has_cambuche(spot)
	var rained: bool = randf() < 0.3
	if flags.get("lluvia_noche_dia", -1) == day:  # (se decidió al acostarse, para verla llover: NightSequence)
		rained = flags["lluvia_noche"]
	var roof: bool = roofed(spot)
	# Hambre e higiene de la noche.
	var night_hunger := 8.0 if spot == "pension" else (10.0 if in_cambuche and cambuche["cobija"] else 15.0)
	if in_cambuche and cambuche.get("piso", false):
		night_hunger -= 3.0  # (el frío no sube del piso)
	var raised: bool = in_cambuche and cambuche.get("cama_estiba", false)  # la cama de estibas: lejos del agua
	if rained and not roof:
		night_hunger += 4.0 if raised else 8.0
	night_hunger *= 1.0 + 0.3 * diff("hambre")
	set_hunger(hunger - night_hunger)
	set_hygiene(100.0 if spot == "pension" else hygiene - 10.0)
	change_mood(SLEEP_MOOD.get(spot, 0.0) + (cambuche_mood() if in_cambuche else 0.0))
	if rained and not roof and not raised:
		change_mood(-5.0)
	if spot == "pension":
		lines.append(rota("pension", ["Durmió en una cama. Se despertó tres veces a revisar la puerta.",
			"Durmió en una cama. Se cayó de ella a las tres de la mañana: el cuerpo buscaba el piso.",
			"Durmió en una cama. La almohada olía a otro. Mejor que oler a nada.",
			"Durmió en una cama. Soñó que alguien le cobraba la cama. Se despertó y era verdad: a las doce."]))
	elif rained:
		lines.append(rota("lluvia_techo", ["Llovió toda la noche. El techo aguantó.",
			"Llovió toda la noche. El techo aguantó; las goteras, también.",
			"Llovió toda la noche. Él, seco. Lukas lo mira como si fuera mérito de él." if lukas_alive()
				else "Llovió toda la noche. Él, seco. Por una vez le tocó lo bueno."])
			if roof else rota("lluvia_mojado", ["Llovió toda la noche. Durmió mojado.",
			"Llovió toda la noche. Amaneció con los zapatos llenos, como dos materas.",
			"Llovió toda la noche. Exprime la camiseta. Sale agua para un tinto.",
			"Llovió toda la noche. Lo único seco es el bolsillo, porque no tiene nada.",
			"Llovió toda la noche. La ropa se le seca a las tres de la tarde. Si no vuelve a llover a las dos."]))
	# Robo. En el cambuche donde duerme, lo decide la defensa de la noche (NightSequence._defend).
	var defense: String = str(flags.get("defense_result", ""))
	flags.erase("defense_result")
	var theft: float = THEFT.get(spot, 0.3) * (LEVEL_THEFT[cambuche_level()] if in_cambuche else 1.0)
	theft *= 1.0 + 0.6 * diff("robos")
	if bond("samuel") >= 1:  # Samuel avisa cuando hay gente rara rondando
		theft *= 0.7
	if has_skill("lazo_lukas"):  # Lukas duerme con una oreja parada
		theft *= 0.6
	if in_cambuche:
		# Si perdió la defensa, se llevan la mitad. Si no, igual: lo del bolsillo se puede ir mientras
		# duerme (lo de la alcancía, no). Por eso la pregunta antes de dormir (SleepSpot._pocket_check).
		theft = 1.0 if defense == "lost" else 0.22 * LEVEL_THEFT[cambuche_level()] * cambuche_guard() * (1.0 + 0.6 * diff("robos"))
		if defense == "won":
			flags["violencia"] = true
	var pickpocket: bool = in_cambuche and defense != "lost"  # mientras dormía, sin pelea: solo el bolsillo
	if pickpocket and money <= 0:
		theft = 0.0
	if int(flags.get("nino_aviso", -1)) == day - 1 or int(flags.get("nino_aviso", -1)) == day \
			or int(flags.get("buhonero_noche", -9)) in [day - 1, day]:  # (o el buhonero arregló la noche)
		theft = 0.0  # Alejandro les dijo que tenía sarna (scripts/systems/Nino.gd)
	if randf() < theft:
		if not pickpocket:
			flags["violencia"] = true  # lo violento despierta a PLOMO (ver NightSequence)
		if money > 0:
			var lost := maxi(1000, money / 2)
			lost = mini(lost, money)
			money -= lost
			money_changed.emit(money)
			lines.append(("Se despierta con el bolsillo rajado: $%d menos. La alcancía sigue ahí." if pickpocket and has_cambuche()
				else "Se despierta con $%d menos.") % lost)
			change_mood(-10.0)
		else:
			var stolen := lose_random_item()
			if stolen != "":
				lines.append("No tenía plata. Se llevaron: %s." % stolen.to_lower())
	# La caja del cambuche, si durmió en otro lado.
	if has_cambuche() and not in_cambuche and not cambuche["candado"] and randf() < 0.25 * LEVEL_THEFT[cambuche_level()] * cambuche_guard() and (not cambuche["box"].is_empty() or cambuche["alcancia"] > 0):
		cambuche["box"].clear()
		cambuche["alcancia"] /= 2
		lines.append("Abrieron la caja del cambuche. Se llevaron todo y la mitad de la alcancía.")
		change_mood(-8.0)
	if flags.get("guayabo", false):
		flags.erase("guayabo")
		lines.append("Amanece con guayabo. El billar se llama así por algo.")
		change_mood(-8.0)
		set_hygiene(hygiene - 8.0)
	# La policía en el parque.
	if has_cambuche() and cambuche["spot"] == "parque" and randf() < 0.2 and not flags.get("ficha_cerrada", false):
		for s in cambuche["box"]:
			add_item(s["id"], s["qty"])
		add_money(cambuche["alcancia"])
		stats["money_earned"] -= cambuche["alcancia"]
		cambuche = {}
		lines.append("Pasó la policía por el parque y se llevó el cambuche. Solo el de él: los otros siguen ahí. La caja quedó tirada.")
		change_mood(-12.0)
	# Después de Lukas: no hay hambre; el mundo pierde el color; él se apaga.
	if not lukas_alive():
		set_hunger(100.0)
		var since: int = day - int(flags["lukas_muerto"])
		lines.append(["Se despierta. Busca a Lukas con la mano.",
			"No come. No tiene hambre.",
			"Le pesan las piernas. El barrio está más gris.",
			"Se mira en una vidriera. Tarda en encontrarse.",
			"El mundo está casi sin color."][clampi(since, 0, 4)])
	# La enfermedad larga: empieza el día 30 y avanza sola (ver lukas_stage).
	if lukas_alive() and day >= 30 and not flags.has("lukas_cronico_dia"):
		flags["lukas_cronico_dia"] = day
		lines.append("Lukas tosió toda la noche. Una tos seca, chiquita.")
	elif lukas_alive() and flags.has("lukas_cronico_dia"):
		var st := lukas_stage()
		change_mood(-2.0 * st)
		var by_stage := {
			1: ["Lukas tose otra vez. Le pone la camiseta encima. Tose debajo de la camiseta.", "La tos de Lukas lo despierta. Se queda despierto escuchándola."],
			2: ["Lukas comió la mitad. Después tampoco quiere el resto.", "Lukas camina más despacio. Él lo espera."],
			3: ["Lukas duerme casi todo el día. Cuando lo mira, mueve la cola una vez. Una sola.", "Lukas respira rápido, con la boca abierta. Le moja la lengua con agua del cuenco."],
		}
		lines.append(by_stage[st][day % 2])
	# Lukas se enferma si pasó el día sin comer ni tomar agua, o si se mojó toda la noche sin techo.
	if lukas_alive() and not flags.has("lukas_enfermo") and not flags.has("lukas_cronico_dia") and day >= 3:
		var risk := 0.0
		if flags.get("lukas_fed_day", -1) != day and flags.get("lukas_water_day", -1) != day:
			risk += 0.35
		if rained and not roof:
			risk += 0.15
		if randf() < risk:
			flags["lukas_enfermo"] = day
			lines.append("Lukas no se levanta. Tiene la nariz caliente y seca. No mueve la cola.")
	elif flags.has("lukas_enfermo") and lukas_alive():
		change_mood(-6.0)
		lines.append(rota("lukas_enfermo", ["Lukas sigue enfermo. Come poquito. Hay una veterinaria en el Parque de San Judas.",
			"Lukas tiembla de noche. Le da la cobija, la camiseta. Necesita un veterinario.",
			"Lukas tiene la nariz seca. Él se la toca cada hora, como quien revisa una olla.",
			"Lukas no se levantó a ladrarle al de la basura. Es la primera vez en años. El de la basura se queda esperando.",
			"Lukas toma agua y la devuelve. Lo vuelve a intentar: es más terco que enfermo. La Dra. Pilar está en el Parque.",
			"Lukas duerme con la cabeza encima del zapato de él. Para saber si se va. No se va."]))
	if lukas_alive() and day >= 2 and flags.get("lukas_fed_day", -1) != day:
		flags["lukas_hungry"] = true
		lines.append(rota("lukas_hambre", ["Lukas lo mira. Ayer no comió.",
			"Lukas le lame la mano a ver si sabe a algo. Ayer no comió.",
			"Lukas olfatea la mochila entera. Ayer no comió. La mochila tampoco tenía.",
			"Lukas no pide. Se le sienta al lado y espera. Ayer no comió."]))
	_tos_noche(spot, rained and not roof and not raised, in_cambuche, lines)
	if lines.is_empty():
		lines.append("Nadie le robó. No llovió. Nadie le pegó.")
	lines.append_array(DayTasks.close_day())
	# El día nuevo.
	day += 1
	stats = {"money_earned": 0, "food_eaten": 0, "segundos": stats.get("segundos", 0.0)}  # el tiempo jugado no es del día
	for f in ["job_german_done", "job_german_active", "german_gift", "dusk_warned", "rosa_fiado"]:
		flags.erase(f)
	for q in ["sobrevivir", "donde_dormir", "lukas_comida", "banarse", "lukas_agua"]:
		quests.erase(q)
	if lukas_alive():
		start_quest("lukas_agua")
	for q in ["conseguir_comida", "pasar_el_dia"]:  # lo del Día 1 que haya quedado abierto
		if quests.get(q, "") == "active":
			quests[q] = "done"
	if day == 2:
		# Día 2: aprender lo básico, una cosa a la vez (QuestDirector encadena el resto).
		start_quest("t_cambuche")
	else:
		if day == 3:
			for t in ["t_cambuche", "t_lukas", "t_bano"]:  # lo del tutorial que haya quedado
				if quests.get(t, "") == "active":
					quests[t] = "done"
			start_quest("hablar_german")  # la cédula: el primer objetivo de varios días
		elif not is_active("cedula") and not is_active("recoger_cedula"):
			start_quest("sobrevivir")
		start_quest("lukas_comida")
		if not has_cambuche() and not quests.has("armar_cambuche"):
			start_quest("armar_cambuche")
	if not quests.has("regalo_hija"):
		start_quest("regalo_hija")
	lines.append_array(DayTasks.open_day())
	lines.append_array(Torneo.manana())  # el torneo de tenis (días 32 a 36) y el gota a gota
	cambuche_changed.emit()
	return lines


# ---------------------------------------------------------------- La tos

## La enfermedad de él (la escogió el usuario: que cuando se muera Lukas solo se le agrave algo que ya
## venía). Sale de dormir en la calle y avanza sola: el techo, la cobija y la comida caliente la frenan,
## pero no la quitan. Con Lukas vivo no pasa de la tos de pecho; cuando Lukas se muere, él deja de
## cuidarse y se le dispara. Es lo que se lo lleva la noche del 49 (NightSequence._he_dies).
## En la calle se ve: le dan ataques de tos (Player.gd) y Lukas lo mira.
const TOS_MAX_CON_LUKAS := 65.0
const TOS_NUEVA := {
	1: ["Amanece con una tos que ayer no tenía. La tose despacio, para no despertar a Lukas.",
		"Amanece con una tos que ayer no tenía. La tose despacio. No hay a quién despertar."],
	2: ["La tos ahora es de pecho. Le suena por dentro, como una puerta mal cerrada.",
		"La tos ahora es de pecho. Le suena por dentro, como una puerta mal cerrada."],
	3: ["En el pañuelo hay una mancha que no es de tinto. Lo dobla rápido, con la mancha para adentro.",
		"En el pañuelo hay una mancha que no es de tinto. Lo dobla rápido, con la mancha para adentro."],
}
const TOS_LINES := {
	1: [["Tose al despertar. Lukas levanta la cabeza, lo mira hasta que termina y se vuelve a acomodar.", "Tose al despertar. Nadie levanta la cabeza."],
		["La tos ya tiene horario: a las seis, con el frío.", "La tos ya tiene horario: a las seis, con el frío."],
		["Escupe detrás del cartón. Mira el escupitajo un segundo, como quien lee el periódico.", "Escupe detrás del cartón. Mira el escupitajo un segundo, como quien lee el periódico."],
		["Tose y una paloma se va volando. Lukas la persigue dos metros, por si acaso.", "Tose y una paloma se va volando. Es lo único que se movió por él."],
		["La señora de las arepas le pasa un Halls sin decir nada. Él se lo guarda para cuando sea grave.", "La señora de las arepas le pasa un Halls sin decir nada. Él se lo guarda para cuando sea grave."]],
	2: [["Tose hasta que se tiene que sentar. Después se para como si nada. Lukas no le cree.", "Tose hasta que se tiene que sentar. Después se para como si nada."],
		["Respira y el pecho le silba. Lukas para las orejas: cree que es un pájaro.", "Respira y el pecho le silba. Ya no hay quién pare las orejas."],
		["Se amarra la camiseta vieja al cuello, como bufanda. No le sirve para nada. Se la deja.", "Se amarra la camiseta vieja al cuello, como bufanda. No le sirve para nada. Se la deja."],
		["Tose tan fuerte que el celador del frente prende la luz. La apaga. La vuelve a prender, por si acaso.", "Tose tan fuerte que el celador del frente prende la luz. La apaga. La vuelve a prender, por si acaso."],
		["Lukas le trae la camiseta en la boca y se la deja en el pecho. No sabe para qué. Él tampoco.", "Duerme con la mano en el pecho, como quien sostiene una puerta."]],
	3: [["Fiebre. El sol le hace frío.", "Fiebre. El sol le hace frío."],
		["Tose y Lukas le pone la pata encima.", "Tose y no hay quién lo mire."],
		["Le cuesta subir el andén. Lo sube igual, de lado.", "Le cuesta subir el andén. Lo sube igual, de lado."],
		["Suda frío. Se pone la chaqueta. Se la quita. Se la vuelve a poner. La chaqueta no opina.", "Suda frío. Se pone la chaqueta. Se la quita. Se la vuelve a poner. La chaqueta no opina."],
		["Lukas duerme pegado a su pecho, a ver si lo calienta. Lo calienta.", "Se abraza la mochila para dormir. La mochila no calienta. Igual."]],
}
const TOS_PECHO := ["tranquilo", "tose", "le silba", "le duele"]


func tos() -> float:
	return float(flags.get("tos", 0.0))


## 0: nada. 1: tose de vez en cuando. 2: tos de pecho (lo para). 3: fiebre, sangre en el pañuelo.
func tos_stage() -> int:
	var t := tos()
	return 0 if t < 15.0 else (1 if t < 40.0 else (2 if t < 70.0 else 3))


## Lo que le hizo la noche al pecho (y la línea de la mañana, si toca).
func _tos_noche(spot: String, wet: bool, in_cambuche: bool, lines: Array) -> void:
	if day < 4:
		return
	var before := tos_stage()
	var up := 1.0
	if wet:
		up += 3.0
	if spot != "pension" and not (in_cambuche and cambuche.get("cobija", false)):
		up += 0.8
	if hunger < 30.0:
		up += 0.8
	if spot == "pension":
		up -= 2.0
	if flags.get("caliente_dia", -1) == day:
		up -= 1.2
	var t := tos() + maxf(up, 0.6)
	if lukas_alive():
		t = minf(t, TOS_MAX_CON_LUKAS)
	else:
		t += 7.0  # ya no se cuida: el pecho se le apaga con lo demás
	flags["tos"] = clampf(t, 0.0, 100.0)
	var st := tos_stage()
	var solo := 0 if lukas_alive() else 1
	if st > before:
		lines.append(TOS_NUEVA[st][solo])
		change_mood(-4.0)
	elif st > 0 and (day % 3 == 0 or st == 3):
		var opts: Array = TOS_LINES[st]
		var n := int(flags.get("rota_tos_%d" % st, 0))  # (antes salía siempre la primera: day % 3 era 0)
		flags["rota_tos_%d" % st] = n + 1
		lines.append(opts[n % opts.size()][solo])


# ---------------------------------------------------------------- Habilidades

func has_skill(id: String) -> bool:
	return id in skills


## Aprende una habilidad. Devuelve false si ya la tenía. Deja el aviso para el HUD.
func learn(id: String) -> bool:
	if id in skills:
		return false
	skills.append(id)
	flags["skill_toast"] = id
	skill_learned.emit(id)
	return true


# ---------------------------------------------------------------- Vínculos

func bond(id: String) -> int:
	return bonds.get(id, 0)


func raise_bond(id: String) -> void:
	bonds[id] = mini(3, bond(id) + 1)
	bond_changed.emit(id, bonds[id])


# ---------------------------------------------------------------- Dificultad

## Qué habilidad alivia cada área (la baja un 40%: ayuda, pero no la vuelve fácil).
const SKILL_DOMAINS := {"buscar": "rebusque", "social": "aguante", "reflejos": "sangre_fria",
	"precios": "labia", "pedir": "labia", "olfato": "lazo_lukas", "robos": "lazo_lukas",
	"hambre": "cocinero", "cuerpo": "paso_firme"}


## La dificultad sube con los días: 0 en los Días 1 y 2, y llega a 1 cerca del Día 18.
func difficulty() -> float:
	return clampf((day - 2) / 16.0, 0.0, 1.0)


## La dificultad de un área, con lo que alivia la habilidad que le corresponde.
func diff(domain: String) -> float:
	var d := difficulty()
	var skill: String = SKILL_DOMAINS.get(domain, "")
	if skill != "" and has_skill(skill):
		d *= 0.6
	return d


# ---------------------------------------------------------------- Guardar (solo en los cuencos de agua)

const SAVE_PATH := "user://partida.save"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(scene_path: String, spawn: String) -> void:
	var data := {"version": 1, "money": money, "hunger": hunger, "hygiene": hygiene, "mood": mood, "day": day, "loneliness": loneliness,
		"inventory": inventory, "quests": quests, "flags": flags, "stats": stats, "cambuche": cambuche,
		"skills": skills, "bonds": bonds, "minutes": TimeManager.minutes, "scene": scene_path, "spawn": spawn}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_var(data)


## Carga la partida guardada en el estado. Devuelve los datos (escena y punto donde seguir).
func load_game() -> Dictionary:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = f.get_var()
	money = data["money"]
	hunger = data["hunger"]
	hygiene = data["hygiene"]
	mood = data["mood"]
	loneliness = data.get("loneliness", 20.0)
	day = data["day"]
	inventory = data["inventory"]
	inventory.resize(SLOTS)  # (las partidas viejas tenían 8)
	quests = data["quests"]
	flags = data["flags"]
	stats = data["stats"]
	cambuche = data["cambuche"]
	if cambuche.get("spot", "") == "callejon":  # (partidas viejas: en el callejón ya no se arma)
		cambuche["spot"] = "lote"
	skills = data["skills"]
	bonds = data["bonds"]
	if not quests.has("lo_bueno"):  # partidas de antes de "Lo bueno del barrio"
		quests["lo_bueno"] = "active"
	TimeManager.minutes = data["minutes"]
	TimeManager.set_time(int(data["minutes"]) / 60, int(data["minutes"]) % 60)
	inventory_changed.emit()
	money_changed.emit(money)
	hunger_changed.emit(hunger)
	mood_changed.emit(mood)
	loneliness_changed.emit(loneliness)
	return data
