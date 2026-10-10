extends "res://scripts/dreams/Plomo.gd"
## PLOMO: EL DEALER, en tres capítulos (escenas PlomoDealer1..3, chapter = 1..3). Un barrio de crayón,
## de noche y tachado; se juega siendo Lisandro.
##   1. LA ESQUINA: le quita la esquina a Don Lucho, el capo viejo (mini jefe: el Coronel, con la llave).
##   2. LA COCINA: el Químico (mini jefe, la llave) y el Coronel, que ya no quiere cobrarle a él.
##   3. EL QUE NO SE MUERE: la pelea bien Doom contra el protagonista (ráfagas de plasma, refuerzos) y el
##      giro de papeles (abajo). Cada capítulo termina con un gancho hacia el siguiente.
## Lisandro Es poderoso (doble vida, pega más) y lo que recoge son drogas: la bolsita lo
## pone "en subida" (más rápido, daño doble, la pantalla cambia de color) y después viene el bajón.
## Callejón → calle → la cocina (el Coronel, mini jefe, tiene la llave) → la casa → "el que no se
## muere": el protagonista, armado como un caballero del infierno.
## EL GIRO: cuando al que no se muere le queda un cuarto de vida, los papeles se cambian. Ahora uno
## es él, con la escopeta, y Lisandro es el jefe. A los dos tercios llama a Camila (La Devoradora) y a
## Guillermo (el marrano); a un tercio, como siempre en el peor momento, aparece Lilato.
## LISANDRO, DE CERCA: es un hijo de puta (los chistes que hace cuando mata, el pelado, la plata
## falsa), pero el sueño lo deja ver por dentro para que uno le tome cariño antes de matarlo:
##   - la mamá lo llama al teléfono público del callejón en los tres capítulos ("¿ya comió?");
##   - en el 1, un pelado le pide trabajo (campanero o colegio, con billete falso);
##   - en el 2 se le pega un perro flaco, Billete, que lo sigue y gruñe cuando hay alguien escondido;
##   - en el 3, una foto vieja: los dos de pelados en la misma esquina (de ahí la envidia).
## LA PELEA CON LISANDRO (después del giro) es un acertijo, no una esponja: tiene el maletín de
## plata adelante (las balas casi no le entran). Cada tanto grita "¡mi bolsita!" y corre a una de
## las bolsitas del piso: si se la toma, entra en subida (rápido, no le entra nada); después viene el
## bajón (suelta el maletín: AHORA). Si uno le revienta la bolsita de un tiro antes de que llegue,
## el bajón es inmediato y más largo. Sin bolsitas, es un señor gordo con una pistola.

const RUSH_TIME := 7.0
const CRASH_TIME := 3.0
const RUSH_LINES := [
	"Uff. El crayón se derrite. Los colores me gritan. Me encanta.",
	"Otra. Ahora sí veo todo. Todo es mío.",
	"Más rápido. Más fuerte. Más solo. Pero eso no lo pienso ahora.",
]
const CRASH_LINES := [
	"El bajón. Las piernas de plomo. El barrio se ve como es.",
	"Se acabó la subida. Quedé yo. No me gusto.",
]

var _twist := false
var _rush := 0.0
var _crash := 0.0
var _rush_i := 0
var _called_duo := false
var _called_lilato := false
var _white := 0.0
var _plasma_t := 3.0

const BAG_SPOTS := [Vector2(23.0, 13.0), Vector2(30.0, 15.0), Vector2(23.0, 22.0), Vector2(30.0, 21.5)]
const GUARD_TIME := 6.0
const LIS_RUSH := 6.0
const LIS_CRASH := 4.0
const LIS_DENIED := 5.5
## Cuánto le entra a Lisandro según cómo esté.
const LIS_TAKE := {"guard": 0.3, "seek": 0.7, "rush": 0.08, "crash": 1.25, "naked": 1.4}
const SEEK_LINES := ["LISANDRO: —¡Mi bolsita! ¡Nadie toca mi bolsita!", "LISANDRO: —¡Un pase! ¡Uno solo y lo mato!",
	"LISANDRO: —¡Billete, cúbrame! ¡Es una orden! ... ¿Los perros reciben órdenes?"]
const RUSH_LINES_LIS := ["LISANDRO: —¡SUBIDA! ¡Soy inmortal! ¡Soy usted!", "LISANDRO: —¡No siento nada! ¡Qué rico no sentir nada!",
	"LISANDRO: —¡Ahora sí! ¡Ahora sí me quiere la gente!"]
const CRASH_LINES_LIS := ["LISANDRO: —Amá... Amá, ¿ya comió?", "LISANDRO: —Billete... venga... usted no se va, ¿cierto?",
	"LISANDRO: —Yo no quería ser así. Bueno, sí quería. Pero no tanto."]
## Lo que dice cuando mata (es un hijo de puta; con gracia, pero un hijo de puta).
const KILL_QUIPS := ["LISANDRO: —Mándenle flores a la mamá. Las pago yo. Con la plata de él.",
	"LISANDRO: —Nada personal. Bueno, un poquito personal.", "LISANDRO: —Ese me debía. Todos me deben.",
	"LISANDRO: —Uno menos en la nómina.", "LISANDRO: —Qué pecado. Tenía unos tenis lindos. Ya son míos."]

var _bags: Array = []          # las bolsitas que quedan en el piso de la casa (la pelea con Lisandro)
var _puffs: Array = []         # nubes de polvo de las bolsitas reventadas: {"pos", "t"}
var _lis_mode := ""            # guard, seek, rush, crash, naked
var _lis_t := 0.0
var _lis_bag := -1
var _lis_i := 0
var _guard_say := 0.0
var _taught := false
var _quip_cd := 0.0
## La historia: lo que hay para encontrar ({"id", "pos", "tex", "h", "done", "keep"}).
var _scenes: Array = []
var _ring_said := false
var _dog_on := false
var _dog_pos := Vector2.ZERO
var _dog_moving := false
var _dog_bark := 5.0
var _dog_owner := "player"    # player, lisandro (después del giro), body (cuando Lisandro se muere)
var _dog_body := Vector2.ZERO
var _dog_saw_bag := false
var _resupply := 6.0
var _resupply_said := false
const AMMO_SPOTS := [Vector2(22.5, 13.5), Vector2(22.5, 21.5), Vector2(30.5, 18.5), Vector2(26.5, 22.3)]

@export var chapter := 3


func setup() -> void:
	dream_id = "plomo_d%d" % chapter
	title_text = "PLOMO"
	subtitle = "EPISODIO: EL DEALER\n(esta vez usted es Lisandro)"
	recap = [
		["", "Esta noche el sueño se equivoca de cuerpo."],
		["", "Las manos tienen anillos de oro. La camisa es blanca, de lino. La pistola, dorada."],
		["", "Ahora usted es Lisandro. Disfrútelo. Él lo disfrutaba."],
		["", "Lisandro: gordo, bajito, gafas oscuras hasta de noche. Un hijo de puta de traje blanco. Lo blanco es para que se note que nunca se mancha: para eso paga."],
	]
	weapon_prefix = "dw_"
	face_prefix = "dface_"
	ceil_cols = [Color(0.02, 0.01, 0.04), Color(0.12, 0.04, 0.1)]
	floor_cols = [Color(0.06, 0.05, 0.07), Color(0.18, 0.14, 0.16)]
	# A lo Doom: paredes de 64x64, pisos y techos con textura, luz por casilla (ver _build_map).
	wall_tex = {"#": "dd_ladrillo", "C": "dd_dibujos", "Z": "dd_persiana", "K": "dd_contenedor", "P": "dd_columna",
		"W": "dd_cajas", "Q": "dd_cocina", "G": "dd_oro", "M": "dd_marmol",
		"D": "dd_puerta", "L": "dd_puerta_llave", "E": "dd_salida"}
	flats_tex = load("res://assets/shooter/dd_suelos.png")
	flats_n = 8
	kinds = {
		"rival": {"hp": 30, "speed": 1.8, "range": 0.9, "dmg": 10, "cd": 1.0, "attack": "melee", "h": 0.8, "sprite": "dl_rival"},
		"campanero": {"hp": 15, "speed": 2.3, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.78, "sprite": "dl_sapo"},
		"tombo": {"hp": 40, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.82, "sprite": "dl_tombo"},
		"motorizado": {"hp": 40, "speed": 2.4, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.8, "sprite": "kid_motorizado"},
		"coronel": {"hp": 220, "speed": 1.6, "range": 10.0, "dmg": 8, "cd": 1.5, "attack": "burst", "h": 1.1, "sprite": "dl_tombo"},
		"slayer": {"hp": 560, "speed": 1.3, "range": 12.0, "dmg": 9, "cd": 1.3, "attack": "burst", "h": 1.6, "sprite": "dl_slayer"},
		"lisandro": {"hp": 700, "speed": 1.4, "range": 12.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.05, "sprite": "kid_lisandro"},
		"devoradora": {"hp": 150, "speed": 1.1, "range": 9.0, "dmg": 9, "cd": 1.7, "attack": "fan:bolso_p", "h": 1.15, "sprite": "dl_devoradora"},
		"marrano": {"hp": 170, "speed": 1.6, "range": 8.0, "dmg": 10, "cd": 1.4, "attack": "throw:cadena_p", "h": 1.15, "sprite": "dl_marrano"},
		"lilato": {"hp": 150, "speed": 1.9, "range": 8.0, "dmg": 9, "cd": 1.7, "attack": "fan:saliva", "h": 0.8, "sprite": "kid_lilato"},
	}
	pickup_tex = {"balas": "balas", "cartuchos": "cartuchos", "empanada": "d_bolsita", "aguapanela": "d_pepas",
		"chaleco": "d_maletin", "llave": "llave", "escopeta": "escopeta", "caneca": "d_caneca"}
	projectile_tex = ["cuchillo", "saliva", "bolso_p", "cadena_p", "plasma", "d_pepas"]
	mini_kind = "coronel"
	boss_kind = "slayer"
	summon_kind = "tombo"
	music = "plomo"
	music_boss = "plomo_boss"
	finish_note = "(el que no se muere sigue sin morirse)"
	# Lisandro: poderoso. Vida doble, pega más, ya tiene la escopeta.
	max_hp = 200.0
	dmg_mult = 1.5
	owned = [true, true, true]
	ammo = {"balas": 80, "cartuchos": 16}
	lines = {
		"start": "LISANDRO: —Mi barrio. Lo pinté yo. Con crayón y con la plata de otros. Camisa de lino. Italiana. Bueno, de Bello. Pero de lino.",
		"mini_wake": "EL CORONEL: —Lisandro. Usted me debe este mes. Y el pasado.",
		"mini_half": "EL CORONEL: —¡A mí nadie me deja de pagar!",
		"mini_die": "EL CORONEL: —Tome la llave... de todos modos ya era suya. Todo es suyo.",
		"boss_wake": "Al fondo hay alguien. Grande. Verde. No se mueve. Me está esperando.",
		"boss_p1": "LISANDRO: —¡Usted debería estar muerto! ¡Yo pagué para eso! ¡Tombos!",
		"boss_p2": "EL QUE NO SE MUERE: —... Usted pagó. Yo no cobré.",
		"boss_die": "LISANDRO: —Yo tenía todo... todo...",
		"boss_reply": "Tenía todo menos lo que importa. Eso no se vende. Ni en su esquina. Lo averigüé.",
		"key_use": "La llave del Coronel abre la casa. El Estado al servicio del barrio.",
		"locked": "Cerrada. El Coronel tiene la llave. Siempre hay un uniforme con la llave.",
		"exit_wait": "SALIDA. Todavía no: él sigue ahí.",
		"alert": "(Un sapo pita. El barrio sabe que llegué. Bien: que sepan.)",
		"vest": "Un maletín de plata. Samsonite. La mejor armadura: nadie le dispara al que paga.",
		"shotgun": "Otra escopeta. Uno nunca tiene suficientes.",
		"no_ammo": "Sin balas. A puño con anillos. Duele más.",
	}
	_chapter_setup()


## Lo que cambia en cada capítulo: subtítulo, el "anteriormente", jefes y lo que dicen.
func _chapter_setup() -> void:
	match chapter:
		1:
			subtitle = "CAPITULO 1: LA ESQUINA\n(esta noche usted es Lisandro)"
			kinds["capo"] = {"hp": 380, "speed": 1.3, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.4, "sprite": "dl_rival"}
			boss_kind = "capo"
			summon_kind = "rival"
			finish_note = "(la esquina es suya. Nadie aplaudió)"
			lines.merge({
				"boss_wake": "DON LUCHO: —Esta esquina era mía antes de que usted naciera, pelado.",
				"boss_p1": "DON LUCHO: —¡Muchachos! ¡Al de blanco!",
				"boss_p2": "DON LUCHO: —Usted no sabe lo que es esto. Esto se come a la gente. Primero a los que mandan.",
				"boss_die": "DON LUCHO: —Quédesela, la esquina. Ella sabe cobrar.",
				"boss_reply": "LISANDRO: —Mía. Todo esto es mío. (Nadie aplaude. Raro.)",
				"key_use": "La llave del Coronel abre la casa de Don Lucho. El Estado al servicio del barrio.",
				"exit_wait": "SALIDA. Todavía no: Don Lucho sigue en su esquina.",
			}, true)
		2:
			subtitle = "CAPITULO 2: LA COCINA"
			recap = [
				["", "ANTERIORMENTE EN PLOMO..."],
				["", "Lisandro se quedó con la esquina de Don Lucho. Los pelados le dicen patrón. Tienen doce años."],
				["", "Ahora quiere la cocina: el lugar donde se hace lo que se vende."],
			]
			wall_tex["W"] = "dd_cocina"  # la bodega ya es cocina
			kinds["quimico"] = {"hp": 200, "speed": 1.4, "range": 9.0, "dmg": 9, "cd": 1.5, "attack": "fan:d_pepas", "h": 1.05, "sprite": "dl_sapo"}
			kinds["coronel"] = {"hp": 450, "speed": 1.4, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.35, "sprite": "dl_tombo"}
			mini_kind = "quimico"
			boss_kind = "coronel"
			summon_kind = "tombo"
			finish_note = "(la cocina es suya. El Coronel también)"
			lines.merge({
				"mini_wake": "EL QUIMICO: —No toque nada. Todo lo que hay aquí mata. Yo incluido.",
				"mini_half": "EL QUIMICO: —¡Usted no sabe ni hacer un huevo, y quiere la cocina!",
				"mini_die": "EL QUIMICO: —La llave... de donde el Coronel. Ahí va a ver quién manda de verdad.",
				"boss_wake": "EL CORONEL: —Lisandro. Llega tarde con la cuota. Llega tarde a todo.",
				"boss_p1": "EL CORONEL: —¡Refuerzos! ¡Que este se creyó dueño!",
				"boss_p2": "EL CORONEL: —El barrio no es suyo. Es del que le pone el uniforme.",
				"boss_die": "EL CORONEL: —Hay alguien preguntando por usted. Grande. Verde. Nosotros no lo mandamos.",
				"boss_reply": "LISANDRO: —¿Verde? ¿Quién? ... ¿Quién?",
				"key_use": "La llave del Químico abre la casa del Coronel. Huele a lo mismo que la cocina.",
				"locked": "Cerrada. El Químico tiene la llave. En la cocina.",
				"exit_wait": "SALIDA. Todavía no: el Coronel sigue cobrando.",
			}, true)
		3:
			if FinalRush.is_step("lisandro"):
				# Revancha: él ya es él (armadura); Lisandro, en subida para siempre. Camila y Guillermo vuelven.
				subtitle = "REVANCHA: LISANDRO\n(en subida, para siempre)"
				recap = [["", "Lisandro otra vez. Esta vez con la bolsita pegada a la nariz. No se le acaba nunca."]]
				weapon_prefix = "sw_"
				face_prefix = "sface_"
				max_hp = 100.0
				dmg_mult = 1.0
				armor = 100.0
				_twist = true
				_called_lilato = true  # ella va al final
				boss_kind = "lisandro"
				kinds["lisandro"]["speed"] = 2.2
				kinds["lisandro"]["cd"] = 0.8
				pickup_tex["empanada"] = "empanada"
				pickup_tex["aguapanela"] = "aguapanela"
				projectile_tex.append_array(["empanada", "aguapanela"])
				lines["boss_wake"] = "LISANDRO: —¡Volví! ¡Y no me baja! ¡Nunca me baja!"
				return
			subtitle = "CAPITULO 3: EL QUE NO SE MUERE"
			recap = [
				["", "ANTERIORMENTE EN PLOMO..."],
				["", "La esquina. La cocina. El Coronel. Todo es de Lisandro."],
				["", "Pero en el barrio alguien pregunta por él. Grande, verde, y no le entran las balas."],
				["", "Lisandro lo mandó a matar hace años. Lo sabe. Por eso ya no duerme."],
				["", "Billete duerme a sus pies. Es lo único en el barrio que no le cobra."],
			]
			kinds["slayer"]["hp"] = 900
			lines["boss_p1"] = "Llegan tombos. No vienen a ayudar a nadie: vienen a ver quién gana."

# ---------------------------------------------------------------- El barrio (a lo Doom)

## El plano: el mismo orden de zonas del motor (callejón, calle, cocina, la casa), pero con recodos,
## locales con persiana, kioscos de concreto, la cocina con cajas y la casa con columnas de mármol.
const MAP := [
	"#CCCCCCCC#ZZZZZZZZZZZCQQQQQQQQQ#",
	"#........#...........C...W.....Q",
	"#........#...........C...W.....Q",
	"#........D...........C...W..W..Q",
	"#....#...#...........C.........Q",
	"#....#...#...........D.........Q",
	"######...#....KK...##C.........Q",
	"C........Z....KK...##C...W.....Q",
	"C........Z.........##C...W..QQ.Q",
	"C.....P..Z...........C...W.....Q",
	"C........Z..P........C.........Q",
	"#........#...........GGGGGGGGGGG",
	"#...######........P..G.........G",
	"C........#ZZ.........G.........G",
	"C........#ZZ.........G..M...M..G",
	"C.....P..#ZZ.........G.........G",
	"C........#ZZ....KK...G.........G",
	"######...#......KK...L.........E",
	"#........Z...........G.........G",
	"#........Z...........G.........G",
	"#..KK....ZZ..........G..M...M..G",
	"#........ZZ..........G.........G",
	"#........#Z..........G.........G",
	"#####################GGGGGGGGGG#",
]
## Pisos y techos (el atlas dd_suelos.png, en este orden).
enum Flat { ASFALTO, ANDEN, BALDOSA, MADERA, MARMOL, TECHO_COCINA, TECHO_CASA, TIERRA }
## Decorado: [textura (o cuadros), x, y, alto, radio que estorba].
const DECOR := [
	["dd_farol", 1.4, 18.4, 1.1, 0.12], [["dd_caneca_fuego1", "dd_caneca_fuego2"], 7.4, 21.4, 0.5, 0.25],
	["dd_bolsas", 1.5, 21.6, 0.3, 0.0], [["dd_caneca_fuego1", "dd_caneca_fuego2"], 1.6, 11.4, 0.5, 0.25],
	["dd_farol", 8.7, 8.4, 1.1, 0.12], ["dd_bolsas", 8.4, 13.5, 0.3, 0.0], ["dd_farol", 10.5, 1.5, 1.1, 0.12],
	["dd_carro", 12.5, 6.0, 0.45, 0.5], ["dd_carro", 18.5, 4.5, 0.45, 0.5], ["dd_carro", 17.0, 21.0, 0.45, 0.5],
	["dd_farol", 20.5, 9.5, 1.1, 0.12], ["dd_farol", 12.5, 16.5, 1.1, 0.12],
	[["dd_caneca_fuego1", "dd_caneca_fuego2"], 19.6, 18.5, 0.5, 0.25], ["dd_farol", 20.5, 22.5, 1.1, 0.12],
	["dd_bolsas", 14.5, 22.4, 0.3, 0.0], [["dd_caneca_fuego1", "dd_caneca_fuego2"], 26.5, 5.5, 0.5, 0.25],
	["dd_bolsas", 30.4, 6.5, 0.3, 0.0], ["dd_estatua", 26.5, 12.6, 1.15, 0.3], ["dd_espejo", 30.6, 13.0, 0.75, 0.2],
	[["dd_caneca_fuego1", "dd_caneca_fuego2"], 22.6, 12.5, 0.5, 0.25],
]


func _build_map() -> void:
	grid.clear()
	for row in MAP:
		var r := []
		for ch in row:
			r.append(ch)
		grid.append(r)
	floor_map.clear()
	ceil_map.clear()
	light_base.clear()
	for y in 24:
		var fr := []
		var cr := []
		var lr := []
		for x in 32:
			var z := _zone_of(Vector2(x + 0.5, y + 0.5))
			match z:
				0:  # el callejón: tierra y asfalto, oscuro
					fr.append(Flat.TIERRA if (x + y * 3) % 7 == 0 else Flat.ASFALTO)
					cr.append(-1)
					lr.append(0.5)
				1:  # la calle: andén pegado a los locales, asfalto en el medio
					fr.append(Flat.ANDEN if x <= 10 or x >= 20 or y <= 1 or y >= 22 else Flat.ASFALTO)
					cr.append(-1)
					lr.append(0.62)
				2:  # la cocina: madera en la bodega, baldosa donde se cocina
					fr.append(Flat.MADERA if x <= 25 else Flat.BALDOSA)
					cr.append(Flat.TECHO_COCINA)
					lr.append(0.78)
				_:  # la casa
					fr.append(Flat.MARMOL)
					cr.append(Flat.TECHO_CASA)
					lr.append(0.95)
		floor_map.append(fr)
		ceil_map.append(cr)
		light_base.append(lr)
	props.clear()
	flicker.clear()
	for d in DECOR:
		var pr := {"pos": Vector2(d[1], d[2]), "h": d[3], "r": d[4]}
		if d[0] is Array:
			pr["tex"] = d[0][0]
			pr["anim"] = d[0]
		else:
			pr["tex"] = d[0]
		props.append(pr)
		# Faroles y fuego alumbran alrededor; el fuego titila.
		var is_fire: bool = d[0] is Array
		var is_lamp: bool = d[0] is String and d[0] == "dd_farol"
		if not (is_fire or is_lamp):
			continue
		var reach := 2.5 if is_lamp else 2.0
		for y in range(int(d[2] - reach), int(d[2] + reach) + 1):
			for x in range(int(d[1] - reach), int(d[1] + reach) + 1):
				if x < 0 or y < 0 or x > 31 or y > 23:
					continue
				var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(d[1], d[2]))
				var l: float = clampf(1.15 - dist * 0.2, 0.0, 1.1)
				if l > light_base[y][x]:
					light_base[y][x] = l
					if is_fire and dist < 1.6:
						flicker[Vector2i(x, y)] = 11.0
	for c in [Vector2i(8, 7), Vector2i(8, 8), Vector2i(7, 7)]:  # un farol que se está muriendo
		flicker[c] = 2.3
	for c in [Vector2i(27, 4), Vector2i(27, 5), Vector2i(28, 5), Vector2i(26, 4)]:  # el tubo de la cocina
		flicker[c] = 5.0


func _place() -> void:
	var list := [
		["rival", 3.5, 14.5], ["rival", 6.5, 10.5], ["campanero", 2.5, 3.5], ["rival", 7.5, 2.5],
		["tombo", 15.5, 3.5], ["motorizado", 19.5, 14.5], ["tombo", 11.5, 12.5], ["tombo", 19.5, 21.5],
		["campanero", 12.5, 19.5], ["rival", 17.5, 8.5], ["rival", 13.5, 14.5], ["rival", 15.5, 18.5],
		["rival", 23.5, 9.5], ["motorizado", 29.5, 2.5], ["tombo", 27.5, 1.5], ["coronel", 28.5, 5.5],
		["slayer", 27.5, 17.5],
	]
	# El mini jefe y el jefe de cada capítulo van en los mismos lugares.
	list[-2][0] = mini_kind
	list[-1][0] = boss_kind
	for e in list:
		_spawn(e[0], Vector2(e[1], e[2]))
	total = enemies.size()
	for p in [["empanada", 4.5, 18.5], ["balas", 7.5, 19.5], ["aguapanela", 1.5, 8.5], ["caneca", 7.5, 4.5],
			["empanada", 13.5, 9.5], ["cartuchos", 11.5, 2.5], ["aguapanela", 19.5, 2.5], ["chaleco", 12.5, 21.5],
			["balas", 19.5, 10.5], ["caneca", 17.5, 19.5], ["cartuchos", 23.5, 2.5], ["empanada", 29.5, 9.5],
			["balas", 22.5, 13.5], ["cartuchos", 22.5, 21.5], ["empanada", 29.5, 21.5], ["aguapanela", 23.5, 21.5]]:
		pickups.append({"kind": p[0], "pos": Vector2(p[1], p[2])})
	_story_setup()
	if _twist:  # la revancha: la pelea con Lisandro desde el principio
		_bags = BAG_SPOTS.duplicate()


# ---------------------------------------------------------------- La subida y el bajón

## La bolsita: siempre se la toma (aunque tenga la vida llena). Así es esto.
func _pickups() -> void:
	if not _twist:
		for p in pickups.duplicate():
			if p["kind"] == "empanada" and p["pos"].distance_to(pos) <= 0.5:
				pickups.erase(p)
				hp = minf(max_hp, hp + 15.0)
				_rush = RUSH_TIME
				_crash = 0.0
				_bonus = 0.6
				_face_grin = 1.5
				_say(RUSH_LINES[_rush_i % RUSH_LINES.size()], 0)
				_rush_i += 1
				if _dog_on and not _dog_saw_bag:
					_dog_saw_bag = true
					_say("(Billete le mira la nariz blanca y se acuesta. Los perros saben. No dicen nada; por eso uno los quiere.)")
	super._pickups()


func _special(delta: float) -> void:
	_white = maxf(0.0, _white - delta * 1.4)
	_quip_cd -= delta
	for pf in _puffs.duplicate():
		pf["t"] -= delta
		if pf["t"] <= 0.0:
			_puffs.erase(pf)
	_dog(delta)
	if _twist:
		_lis_fight(delta)
	_story(delta)
	if chapter == 3 and not _twist and boss_awake:
		_slayer_plasma(delta)
	if _twist:
		return
	if _rush > 0.0:
		_rush -= delta
		move_mult = 1.45
		dmg_mult = 3.0
		if _rush <= 0.0:
			_crash = CRASH_TIME
			_say(CRASH_LINES[_rush_i % CRASH_LINES.size()])
	elif _crash > 0.0:
		_crash -= delta
		move_mult = 0.7
		dmg_mult = 1.2
	else:
		move_mult = 1.0
		dmg_mult = 1.5


func _draw() -> void:
	super._draw()
	if state == "title" or state == "done":
		return
	if _rush > 0.0:  # los colores del crayón se vuelven locos
		var hue := fposmod(time * 0.35, 1.0)
		draw_rect(Rect2(0, 0, W, VIEW_H), Color.from_hsv(hue, 0.8, 1.0, 0.16))
	elif _crash > 0.0:
		draw_rect(Rect2(0, 0, W, VIEW_H), Color(0.1, 0.12, 0.2, 0.35))
	if _white > 0.0:
		draw_rect(Rect2(0, 0, W, 180), Color(1, 1, 1, minf(1.0, _white)))


# ---------------------------------------------------------------- El giro

func _damage(e: Ent, dmg: float) -> void:
	if e.kind == "slayer" and not _twist:
		var max_e: float = kinds["slayer"]["hp"] * (1.0 + dream_hard)
		if e.hp - dmg <= max_e * 0.25:
			e.hp = max_e * 0.25
			_role_swap(e)
			return
	if e.kind == "lisandro" and _twist:
		dmg *= LIS_TAKE.get(_lis_mode, 1.0)
		_guard_say -= 1.0
		if _lis_mode in ["guard", "rush"] and _guard_say <= 0.0:
			_guard_say = 6.0
			_say("(¡TAC! El maletín de plata. Así no le entra.)" if _lis_mode == "guard" else "(No le entra nada: está en subida. Mejor correr.)", 0)
	super._damage(e, dmg)
	if e.kind == "lisandro" and e.state != "dead":
		var max_l: float = kinds["lisandro"]["hp"] * (1.0 + dream_hard)
		if not _called_duo and e.hp < max_l * 0.66:
			_called_duo = true
			for k in [["devoradora", summon_points[0]], ["marrano", summon_points[1]]]:
				var s := _spawn(k[0], k[1])
				s.alerted = true
				total += 1
			_say("LISANDRO: —¡Camila! ¡Guillermo! ¡Vengan, que este no se muere!")
		elif not _called_lilato and e.hp < max_l * 0.33:
			_called_lilato = true
			var at := e.pos + Vector2(-2.0, 0.0)
			var l := _spawn("lilato", at if walkable(at) and los(e.pos, at) else summon_points[0])
			l.alerted = true
			total += 1
			_say("LILATO: —¿Me extrañaste? Vine en el peor momento. Siempre vengo en el peor momento.")


## Capítulo 3: el que no se muere tira ráfagas de plasma verde en abanico (además de la escopeta).
func _slayer_plasma(delta: float) -> void:
	_plasma_t -= delta
	if _plasma_t > 0.0:
		return
	_plasma_t = 3.2
	for e in enemies:
		if e.kind != "slayer" or e.state == "dead" or not los(e.pos, pos):
			continue
		var aim := (pos - e.pos).angle()
		for sp in [-0.32, -0.16, 0.0, 0.16, 0.32]:
			var dir := Vector2(cos(aim + sp), sin(aim + sp))
			projectiles.append({"tex": "plasma", "pos": e.pos + dir * 0.6, "vel": dir * 6.0, "dmg": 7.0})
		_shake_say()


func _shake_say() -> void:
	if randf() < 0.2:
		_say(["EL QUE NO SE MUERE: —...", "Plasma. Verde. Como en las películas que él veía de chiquito.",
			"EL QUE NO SE MUERE: —Usted pagó por esto, Lisandro."].pick_random(), 0)


## Al que no se muere le queda un cuarto de vida: el sueño se da vuelta.
func _role_swap(slayer: Ent) -> void:
	_twist = true
	state = "talk"
	projectiles.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	MusicDirector.cut()
	await Dialogue.talk([
		["LISANDRO", "—¿Por qué no se muere? ¡Yo pagué para que lo mataran!"],
		["EL QUE NO SE MUERE", "—Ya sé. Y aquí sigo. Uno se acostumbra a no morirse."],
		["EL QUE NO SE MUERE", "—¿Sabe qué es lo peor de jugar con usted? Que se siente bien. Por eso nadie lo deja."],
		["", "Algo se da vuelta. El arma pesa distinto. Las manos ya no tienen anillos."],
		["", "El del otro lado ahora es Lisandro. Y el que tiene la escopeta..."],
		["", "... soy yo."],
		["", "Billete corre para el otro lado. Hacia Lisandro. Claro. Uno no elige a quién quiere el perro."],
		["", "Lisandro tiene el maletín de plata adelante, como un escudo. Y en el piso de la casa hay bolsitas. Él las está mirando."],
	])
	_white = 1.0
	boss_awake = true
	mini_awake = true
	# Se cambian de lugar: uno queda donde estaba el otro.
	var mine := pos
	pos = slayer.pos
	enemies.erase(slayer)
	total -= 1
	var lis := _spawn("lisandro", mine)
	total += 1
	lis.alerted = true
	lis.state = "chase"
	ang = (lis.pos - pos).angle()
	boss_kind = "lisandro"
	summon_points = [Vector2(24.5, 15.5), Vector2(28.5, 19.5)]
	summon_kind = "tombo"
	lines["boss_p1"] = "LISANDRO: —¡Usted no era así! ¡Usted era el que corría!"
	lines["boss_p2"] = "LISANDRO: —¡Era envidia, sí! ¡¿Y qué?! ¡Usted también la tendría!"
	# Él: armadura, escopeta, sin drogas. Las bolsitas que quedaban ahora son empanadas.
	_load_kit("sw_", "sface_")
	max_hp = 100.0
	hp = 100.0
	armor = 100.0
	move_mult = 1.0
	dmg_mult = 1.0
	_rush = 0.0
	_crash = 0.0
	ammo["balas"] = maxi(ammo["balas"], 60)
	ammo["cartuchos"] = maxi(ammo["cartuchos"], 20)
	weapon = 2
	for k in ["empanada", "aguapanela"]:
		_tex[k] = load("res://assets/shooter/%s.png" % k)
		pickup_tex[k] = k
	checkpoints = checkpoints.duplicate()  # si se muere ahora, reaparece donde empezó a ser él
	checkpoints[3] = pos
	checkpoint = 3
	MusicDirector.force(music_boss)
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_bags = BAG_SPOTS.duplicate()
	_lis_mode = "guard"
	_lis_t = GUARD_TIME
	_dog_owner = "lisandro"
	if not _dog_on:
		_dog_on = true
		_dog_pos = lis.pos
	_say("Las bolsitas de afuera ahora son empanadas. Las de la casa no: esas son de él.", 2)
	_guard_say = 6.0  # que el ¡TAC! no la pise


# ---------------------------------------------------------------- La pelea con Lisandro (acertijo)

func _lisandro() -> Ent:
	for e in enemies:
		if e.kind == "lisandro" and e.state != "dead":
			return e
	return null


func _lis_fight(delta: float) -> void:
	var lis := _lisandro()
	if lis == null or not boss_awake:
		return
	if _lis_mode == "":  # la revancha: arranca en subida (para siempre... casi)
		_lis_mode = "rush"
		_lis_t = LIS_RUSH * 1.5
		_lis_speed(true)
	_lis_t -= delta
	_ammo_drop(delta)
	match _lis_mode:
		"guard":
			if _lis_t <= 0.0:
				if _bags.is_empty():
					_lis_mode = "naked"
					kinds["lisandro"]["speed"] = 1.0  # sin bolsitas: lento, y dispara como puede
					kinds["lisandro"]["cd"] = 1.8
					_say("LISANDRO: —¿Y las bolsitas? ... Sin bolsitas soy un señor gordo con una pistola. Siempre fui eso.")
					return
				var best := 0
				for i in _bags.size():
					if lis.pos.distance_to(_bags[i]) < lis.pos.distance_to(_bags[best]):
						best = i
				_lis_bag = best
				_lis_mode = "seek"
				_lis_t = 8.0
				if not _taught:
					_taught = true
					_say("LISANDRO: —¡Mi bolsita! (Va por una del piso. Si se la reviento de un tiro antes de que llegue...)", 2)
				else:
					_say(SEEK_LINES[_lis_i % SEEK_LINES.size()], 2)
		"seek":
			if _lis_bag < 0 or _lis_bag >= _bags.size() or _lis_t <= 0.0:
				if _zone_of(lis.pos) != boss_zone:  # por si quedó fuera de la casa: vuelve (si no, la pelea no se acaba)
					lis.pos = summon_points[0]
				_lis_guard()
				return
			lis.state = "seek"  # el motor no lo mueve: lo mueve esto
			var to: Vector2 = _bags[_lis_bag] - lis.pos
			if to.length() < 0.45:
				_bags.remove_at(_lis_bag)
				_lis_bag = -1
				_lis_mode = "rush"
				_lis_t = LIS_RUSH * (1.5 if FinalRush.is_step("lisandro") else 1.0)
				lis.state = "chase"
				_lis_speed(true)
				_say(RUSH_LINES_LIS[_lis_i % RUSH_LINES_LIS.size()] + " (Correr.)", 2)
				return
			var sp := 1.7 if _lis_i == 0 else 2.3  # la primera vez, más despacio: para alcanzar a entender
			var next := _next_cell(lis.pos, _bags[_lis_bag])  # rodea las columnas (antes se trababa en una)
			_walk(lis, (next - lis.pos).normalized(), sp, delta)
		"rush":
			if _lis_t <= 0.0:
				_lis_down(LIS_CRASH, CRASH_LINES_LIS[_lis_i % CRASH_LINES_LIS.size()])
		"crash":
			lis.state = "pain"  # la cara de dolor, quieto, sin disparar
			lis.timer = 0.3
			if _lis_t <= 0.0:
				_lis_guard()


## Hacia dónde dar el próximo paso para llegar a "to" sin chocar (BFS por casillas; la última, derecho).
func _next_cell(from: Vector2, to: Vector2) -> Vector2:
	var start := Vector2i(from.floor())
	var goal := Vector2i(to.floor())
	if start == goal or los(from, to) and _clear_line(from, to):
		return to
	var prev := {start: start}
	var q := [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == goal:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if prev.has(n) or not walkable(Vector2(n) + Vector2(0.5, 0.5)):
				continue
			prev[n] = c
			q.append(n)
	if not prev.has(goal):
		return to
	var c := goal
	while prev[c] != start:
		c = prev[c]
	return Vector2(c) + Vector2(0.5, 0.5)


## Que el cuerpo entero quepa por la línea (no solo el rayo del medio).
func _clear_line(a: Vector2, b: Vector2) -> bool:
	var n := int(a.distance_to(b) / 0.25) + 1
	for i in n + 1:
		if not walkable(a.lerp(b, float(i) / n)):
			return false
	return true


## Con poca munición en la pelea larga, aparece una caja en la casa (lejos de él): a puño no se le gana.
func _ammo_drop(delta: float) -> void:
	_resupply -= delta
	if _resupply > 0.0 or ammo["balas"] >= 20 or ammo["cartuchos"] >= 4:
		return
	_resupply = 10.0
	for p in pickups:
		if p["kind"] in ["balas", "cartuchos"] and _zone_of(p["pos"]) == boss_zone:
			return
	var lis := _lisandro()
	var spot: Vector2 = AMMO_SPOTS[0]
	for sp in AMMO_SPOTS:
		if lis and sp.distance_to(lis.pos) > spot.distance_to(lis.pos):
			spot = sp
	pickups.append({"kind": "balas" if randf() < 0.6 else "cartuchos", "pos": spot})
	if not _resupply_said:
		_resupply_said = true
		_say("(Una caja de balas en el piso, lejos de él. El sueño ayuda poco, pero ayuda.)")


func _lis_speed(rush: bool) -> void:
	kinds["lisandro"]["speed"] = 2.6 if rush else (2.2 if FinalRush.is_step("lisandro") else 1.4)
	kinds["lisandro"]["cd"] = 0.55 if rush else (0.8 if FinalRush.is_step("lisandro") else 1.3)


func _lis_down(t: float, line: String) -> void:
	_lis_mode = "crash"
	_lis_t = t
	_lis_i += 1
	_lis_speed(false)
	_say(line, 2)
	# El maletín se abre al caer: plata, balas y un rosario. Las balas sirven (así nunca se queda sin).
	var lis := _lisandro()
	if lis:
		for k in [["balas", Vector2(0.6, 0.0)], ["cartuchos", Vector2(-0.6, 0.0)]]:
			var at: Vector2 = lis.pos + k[1]
			pickups.append({"kind": k[0], "pos": at if walkable(at) and los(lis.pos, at) else lis.pos})
	await get_tree().create_timer(2.0).timeout
	if _lis_mode == "crash" and _lis_i <= 2:
		_say("(Soltó el maletín. Se riegan las balas. AHORA.)")


func _lis_guard() -> void:
	var lis := _lisandro()
	_lis_mode = "guard"
	_lis_t = GUARD_TIME
	_lis_bag = -1
	_lis_speed(false)
	if lis:
		lis.state = "chase"


## Un tiro que pasa por encima de una bolsita la revienta (si no la tapa nadie).
func _ray_hook(from: Vector2, dir: Vector2, reach: float) -> void:
	if not _twist or _bags.is_empty():
		return
	var hit := -1
	var best_t := reach
	for i in _bags.size():
		var rel: Vector2 = _bags[i] - from
		var t := rel.dot(dir)
		if t > 0.0 and t < best_t and absf(rel.cross(dir)) < 0.25:
			hit = i
			best_t = t
	if hit < 0:
		return
	_puffs.append({"pos": _bags[hit], "t": 1.2})
	_bags.remove_at(hit)
	_bonus = 0.3
	if _lis_mode == "seek" and hit == _lis_bag:
		_lis_bag = -1
		_lis_down(LIS_DENIED, "LISANDRO: —¡NOOO! ¡Esa era la última de la cuadra! ... ¿Y ahora qué soy?")
	else:
		if hit < _lis_bag:
			_lis_bag -= 1
		_say("(Una bolsita menos. Lisandro lo vio. Se le cayó la cara.)", 0)


func extra_sprites() -> Array:
	var out := []
	for b in _bags:
		out.append([b, _t("d_bolsita"), 0.26, 0.0])
	for pf in _puffs:
		out.append([pf["pos"], _t("dd_polvo"), 0.5 * (1.4 - pf["t"] * 0.3), 0.1])
	for sc in _scenes:
		if not sc["done"] or sc["keep"]:
			out.append([sc["pos"], _t(sc["tex"]), sc["h"], 0.0])
	if _dog_on:
		var frame := "dd_billete_sit" if not _dog_moving else ("dd_billete_walk1" if int(time * 8.0) % 2 == 0 else "dd_billete_walk2")
		out.append([_dog_pos, _t(frame), 0.32, 0.0])
	return out


func _t(name: String) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load("res://assets/shooter/%s.png" % name)
	return _tex[name]


# ---------------------------------------------------------------- Billete

func _dog(delta: float) -> void:
	if not _dog_on:
		return
	var target := _dog_pos
	match _dog_owner:
		"player":
			target = pos - Vector2(cos(ang), sin(ang)) * 1.1
		"lisandro":
			var lis := _lisandro()
			if lis:
				target = lis.pos + (lis.pos - pos).normalized() * 0.9  # detrás de él, del lado de él
		"body":
			target = _dog_body + Vector2(0.45, 0.2)
	var to := target - _dog_pos
	_dog_moving = to.length() > 0.35
	if _dog_moving:
		var step := to.normalized() * minf(to.length(), 4.2 * delta)
		if walkable(_dog_pos + Vector2(step.x, 0)):
			_dog_pos.x += step.x
		if walkable(_dog_pos + Vector2(0, step.y)):
			_dog_pos.y += step.y
		if to.length() > 5.0 and walkable(target):  # se quedó atrás (una puerta, una esquina): llega corriendo
			_dog_pos = target
	if _dog_owner != "player":
		return
	# Gruñe cuando hay alguien cerca que todavía no se ve.
	_dog_bark -= delta
	if _dog_bark > 0.0:
		return
	var near: Ent = null
	for e in enemies:
		if e.state == "dead" or e.kind in [boss_kind, mini_kind] or e.pos.distance_to(pos) > 6.0:
			continue
		var rel := e.pos - pos
		var da := wrapf(rel.angle() - ang, -PI, PI)
		if absf(da) > 0.6 or not los(pos, e.pos):
			if near == null or e.pos.distance_to(pos) < near.pos.distance_to(pos):
				near = e
	if near == null:
		_dog_bark = 1.0
		return
	_dog_bark = 9.0
	var a := wrapf((near.pos - pos).angle() - ang, -PI, PI)
	var side := "adelante, detrás de algo" if absf(a) <= 0.6 else ("atrás" if absf(a) > 2.3 else ("a la derecha" if a > 0.0 else "a la izquierda"))
	_say("(Billete gruñe %s. Hay alguien.)" % side, 0)


# ---------------------------------------------------------------- La historia de Lisandro

func _story_setup() -> void:
	_scenes.clear()
	if FinalRush.is_step("lisandro"):
		return
	var phone := {"id": "mama", "pos": Vector2(1.5, 7.5), "tex": "dd_telefono", "h": 0.85, "done": false, "keep": true}
	match chapter:
		1:
			_scenes.append(phone)
			_scenes.append({"id": "pelado", "pos": Vector2(11.5, 7.5), "tex": "dd_pelado", "h": 0.6, "done": false, "keep": false})
		2:
			_scenes.append(phone)
			_scenes.append({"id": "billete", "pos": Vector2(14.0, 12.5), "tex": "dd_billete_sit", "h": 0.32, "done": false, "keep": false})
		3:
			_scenes.append(phone)
			_scenes.append({"id": "foto", "pos": Vector2(23.0, 1.5), "tex": "dd_foto", "h": 0.45, "done": false, "keep": true})
			_dog_on = true  # Billete ya es de él
			_dog_pos = pos + Vector2(0.0, 1.0)


func _story(_delta: float) -> void:
	if _twist:
		return
	for sc in _scenes:
		if sc["done"]:
			continue
		var d: float = pos.distance_to(sc["pos"])
		if sc["id"] == "mama" and d < 6.0 and not _ring_said:
			_ring_said = true
			_say("(RIIIING. El teléfono público del callejón. Suena para él. Siempre sabe dónde está.)")
		if d < 1.2:
			sc["done"] = true
			_run_scene(sc["id"])
			return


func _talk(lines_: Array, choices := []) -> int:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var i: int = await Dialogue.talk(lines_, choices)
	state = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return i


func _run_scene(id: String) -> void:
	match id:
		"mama":
			await _mama()
		"pelado":
			var i := await _talk([
				["PELADO", "—Patrón. ¿Me da trabajo? Tengo doce. Mi mamá está enferma. Bueno, no está enferma, pero está brava."],
				["LISANDRO", "—¿Y qué sabe hacer?"],
				["PELADO", "—Pitar. Correr. Mentir. Lo que usted hace, pero chiquito."],
			], ["Póngase de campanero", "Tome, váyase pa'l colegio"])
			GameState.flags["lis_pelado"] = i
			if i == 0:
				await _talk([
					["LISANDRO", "—Pite si viene la policía. Le pago en tenis."],
					["PELADO", "—¿Tenis de marca?"],
					["LISANDRO", "—De marca de alguien."],
					["", "El pelado sale corriendo a pararse en la esquina. Feliz. Ahí empieza todo, siempre, con alguien feliz."],
				])
				ammo["balas"] = mini(200, ammo["balas"] + 20)
				_say("(El pelado le trae una caja de balas de la casa del tío. Eficiente. Lisandro casi se conmueve.)")
			else:
				await _talk([
					["LISANDRO", "—Tome. Y estudie. Yo no estudié y míreme: gordo, rico y solo."],
					["PELADO", "—¿Solo?"],
					["LISANDRO", "—Era un chiste. Lárguese."],
					["", "El billete es falso. Lisandro lo sabe. Pero se lo dio con cariño, que es más de lo que le dieron a él."],
				])
				hp = minf(max_hp, hp + 15.0)
		"billete":
			var i := await _talk([
				["", "Un perro flaco se está comiendo una bolsa de basura. Café, con una oreja caída."],
				["", "Lo mira. No le tiene miedo. Es el primero en el barrio que no le tiene miedo en años."],
			], ["Darle la mitad del pan", "Pegarle una patada"])
			if i == 0:
				await _talk([
					["LISANDRO", "—Tome. Pan de ayer. Como todo en este barrio."],
					["", "El perro se lo come en dos mordiscos y mueve la cola. Nadie le había movido la cola a Lisandro. Nunca."],
				])
			else:
				await _talk([
					["", "Lisandro le tira una patada. El perro la esquiva, se aleja... y vuelve."],
					["", "Los perros vuelven. La gente no."],
				])
			await _talk([
				["LISANDRO", "—Lárguese. ... ¿No se va? ... Bueno. Le voy a poner Billete."],
				["LISANDRO", "—Por fin uno que me sigue sin que le pague."],
			])
			_dog_on = true
			_dog_pos = sc_pos("billete")
			_say("(Billete lo sigue. Si gruñe, es que hay alguien escondido.)")
		"foto":
			await _talk([
				["", "Una foto vieja en una mesita: dos pelados en la misma esquina, con la misma pistola de agua."],
				["", "Uno es Lisandro. El otro es él. Uno sonríe. El otro mira al que sonríe."],
				["LISANDRO", "—Él siempre tenía con quién jugar. Yo tenía la pistola."],
				["LISANDRO", "—Después yo tuve todo. Y él seguía teniendo con quién jugar. ... No se puede comprar eso, Billete. Lo intenté."],
			])


func sc_pos(id: String) -> Vector2:
	for sc in _scenes:
		if sc["id"] == id:
			return sc["pos"]
	return pos


## La mamá: llama al teléfono público del callejón. Una llamada por capítulo.
func _mama() -> void:
	match chapter:
		1:
			var i := await _talk([
				["MAMÁ", "—¿Aló? ¿Mijo? ¿Lisandro?"],
				["LISANDRO", "—Amá. ¿Cómo sabe este número? Es un teléfono público."],
				["MAMÁ", "—Una mamá sabe. ¿Ya comió?"],
			], ["Sí, amá.", "Estoy trabajando, amá."])
			if i == 0:
				await _talk([["LISANDRO", "—Sí, amá. Bandeja paisa."], ["", "Hace dos días que no come. Solo lo que se recoge en este nivel."]])
			else:
				await _talk([["LISANDRO", "—Estoy trabajando, amá. En el banco."], ["MAMÁ", "—Ay, mi gerente. ¿Y se está poniendo el saco?"],
					["LISANDRO", "—El blanco, amá. El de lino."]])
			await _talk([
				["MAMÁ", "—Dios me lo bendiga. Y no se meta con gente mala."],
				["LISANDRO", "—No, amá. La gente mala se mete conmigo."],
				["", "Cuelga. Le tiembla la mano un segundo. Después le pega un tiro al teléfono, por si acaso."],
			])
		2:
			var i := await _talk([
				["MAMÁ", "—Mijo, en las noticias dicen que en el barrio hay uno grande, verde, matando gente mala."],
				["LISANDRO", "—No vea noticias, amá. Eso da cáncer."],
				["MAMÁ", "—Usted no es gente mala, ¿cierto?"],
			], ["No, amá.", "(Quedarse callado)"])
			if i == 0:
				await _talk([["LISANDRO", "—No, amá."], ["", "Lo dice rápido. Las mentiras que uno dice mucho salen rápido."]])
			else:
				await _talk([["", "Lisandro no contesta. La mamá tampoco cuelga. Se quedan así un rato, oyendo respirar al otro."],
					["MAMÁ", "—Bueno, mijo. Yo le dejo arroz en la olla. Por si acaso."]])
		3:
			await _talk([
				["MAMÁ", "—Mijo, vino un señor grande preguntando por usted. Verde. Muy educado. Se limpió los pies."],
				["LISANDRO", "—¿Y qué le dijo, amá?"],
				["MAMÁ", "—Que usted le debía algo. Le ofrecí tinto. No quiso. Dijo que no se quedaba mucho en ningún lado."],
				["LISANDRO", "—Amá... si me pasa algo..."],
				["MAMÁ", "—¿Qué le va a pasar, mijo? Usted es gerente."],
				["LISANDRO", "—Sí, amá. Gerente."],
			])


## Los que mata Lisandro: un chiste de hijo de puta (no todas las veces). Y la muerte de Lisandro.
func _die(e: Ent) -> void:
	if e.kind == "lisandro" and _twist and not FinalRush.is_step("lisandro"):
		e.state = "dead"
		kills += 1
		_bags.clear()
		MusicDirector.force(music)
		_dog_owner = "body"
		_dog_body = e.pos
		await _talk([
			["", "Lisandro, en el piso de mármol. Sin gafas. Más chiquito de lo que me acordaba."],
			["LISANDRO", "—¿Llamó mi mamá?"],
			["", "—No."],
			["LISANDRO", "—Si llama... dígale que estaba en el banco. Que era gerente."],
			["", "—Le digo."],
			["LISANDRO", "—Y a Billete no lo deje comer basura. Come basura. Como yo."],
			["", "Se muere con los ojos abiertos, mirando la puerta, como esperando a alguien."],
			["", "Billete le lame la cara. Le sigue lamiendo un rato largo. Por si acaso."],
			["", "Lo maté. Lo odiaba. Le había tomado cariño. El sueño sabía las dos cosas y no me avisó."],
		])
		return
	super._die(e)
	if not _twist and e.kind not in [mini_kind, boss_kind] and _quip_cd <= 0.0 and randf() < 0.3:
		_quip_cd = 14.0
		_say(KILL_QUIPS.pick_random(), 0)


func _respawn() -> void:
	super._respawn()
	if _twist:
		armor = 60.0


func _load_kit(wp: String, fp: String) -> void:
	for w in WEAPONS:
		_tex["w_" + w["tex"]] = load("res://assets/shooter/%s%s.png" % [wp, w["tex"]])
		_tex["w_%s_fire" % w["tex"]] = load("res://assets/shooter/%s%s_fire.png" % [wp, w["tex"]])
	for i in 5:
		_tex["face_%d" % i] = load("res://assets/shooter/%s%d.png" % [fp, i])
	_tex["face_hurt"] = load("res://assets/shooter/%shurt.png" % fp)
	_tex["face_grin"] = load("res://assets/shooter/%sgrin.png" % fp)


func _on_exit() -> void:
	state = "talk"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if FinalRush.is_step("lisandro"):
		await Dialogue.talk([["", "Lisandro, en el piso, temblando. La subida se le acabó de golpe. Como se acaban."]])
		FinalRush.next()
		return
	if chapter == 1:
		await Dialogue.talk([
			["", "La esquina es de Lisandro. Los pelados le dicen patrón."],
			["", "Al fondo de la calle, por un segundo, alguien lo mira. Grande. No se mueve."],
			["", "Cuando vuelve a mirar, no hay nadie."],
			["", "CAPITULO 1 COMPLETO. CONTINUARÁ."],
		])
		_finish()
		return
	if chapter == 2:
		await Dialogue.talk([
			["", "La cocina es de Lisandro. El Coronel ahora le cobra a otros para él."],
			["RADIO", "—Hay uno grande, verde, caminando hacia la casa. No le entran las balas. Repito: no le entran."],
			["", "Lisandro apaga la radio. Esa noche no duerme. Ni la siguiente."],
			["", "CAPITULO 2 COMPLETO. CONTINUARÁ."],
		])
		_finish()
		return
	var end := [
		["", "Billete no viene. Se queda con él, echado, con la cabeza en la camisa blanca."],
		["", "Algunos perros no cambian de dueño. Ni cuando el dueño es malo. Sobre todo cuando el dueño es malo: alguien tiene que quedarse."],
	]
	match GameState.flags.get("lis_pelado", -1):
		0:
			end.append(["", "Afuera, en la esquina, el pelado pita. Ya trabaja para otro. Así se hereda esto."])
		1:
			end.append(["", "En algún colegio hay un pelado con un billete falso de Lisandro. Ojalá lo haya gastado en algo que valga."])
	end.append(["", "EPISODIO COMPLETO."])
	await Dialogue.talk(end)
	_finish()
