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
## EL MUNDO DE LAS DROGAS, COMO ES (no un shooter genérico):
##   - el callejón es la olla: gente fumando contra las paredes (no pelean: son los clientes),
##     hollín, "SAPO = MUERTO"; un mural de un pelado muerto con velas al pie, al lado del teléfono;
## En el barrio a Lisandro le dicen "el Gato" (siete vidas; cae parado). Algunos se lo dicen; otros no se atreven.
##   - en la calle, carteles de desaparecidos; y en la esquina del farol, Camila y Verónica, que
##     trabajan para Lisandro (no son enemigas: los tiros no les hacen nada). Verónica fue la novia
##     de él (el protagonista); Camila, por celos, se metió en la mitad. Después de eso terminaron las
##     dos en esa esquina;
##   - los enemigos: los clientes (adictos: piden "una sola" y arañan), los de la otra banda (cuchillo),
##     los sicarios de moto (mini-Uzi), los tombos que cobran; y los campaneros son pelados de doce
##     años: no se pueden matar, se tiran al piso antes del tiro (ya saben);
##   - las armas: el puño con anillos, la pistola de oro y la mini-Uzi del sicariato (gasta mucho; la
##     pistola rinde más). Cuando uno pasa a ser él, vuelve la escopeta.
## LOS OTROS JEFES TAMBIÉN SON ACERTIJOS (ver "Los jefes de los capítulos 1 y 2"):
##   1. DON LUCHO: chaleco de los ochenta (casi no le entra). Le gusta pararse debajo de la luz, y en
##      la casa cuelgan lámparas de araña, cada una amarrada a un gancho en la pared: cuando él está
##      debajo, uno le dispara a la cuerda (no a él). Aplastado, sí le entra. Cada lámpara que cae deja
##      la casa más oscura.
##   2. EL CORONEL: el uniforme lo protege. Pero es codicioso: si uno le revienta una caja fuerte, el
##      fajo que cae lo hace correr a contarlo, y contando no se defiende. (Con Lisandro uno le quita
##      la carnada; con el Coronel uno se la pone.)

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
const LIS_CRASH := 2.5      # el bajón después de una bolsita que sí se metió (corto)
## Lo que se cura con cada bolsita que alcanza (dejarlo llegar sale caro).
const LIS_HEAL := 90.0
const LIS_DENIED := 5.5
## Cuánto le entra a Lisandro según cómo esté.
const LIS_TAKE := {"guard": 0.12, "seek": 0.5, "rush": 0.05, "crash": 1.6, "naked": 1.4}
const SEEK_LINES := ["LISANDRO: —¡Mi bolsita! ¡Nadie toca mi bolsita!", "LISANDRO: —¡Un pase! ¡Uno solo y lo mato!",
	"LISANDRO: —¡Billete, cúbrame! ¡Es una orden! ... ¿Los perros reciben órdenes?"]
const RUSH_LINES_LIS := ["LISANDRO: —¡SUBIDA! ¡Soy inmortal! ¡Soy usted!", "LISANDRO: —¡No siento nada! ¡Qué rico no sentir nada!",
	"LISANDRO: —¡Ahora sí! ¡Ahora sí me quiere la gente!"]
const CRASH_LINES_LIS := ["LISANDRO: —Amá... Amá, ¿ya comió?", "LISANDRO: —Billete... venga... usted no se va, ¿cierto?",
	"LISANDRO: —Yo no quería ser así. Bueno, sí quería. Pero no tanto."]
## Lo que dice cuando mata (es un hijo de puta; con gracia, pero un hijo de puta).
## Lo que dice cuando mata a un cliente. Lo peor de él.
const ADICTO_QUIPS := ["LISANDRO: —Cliente que no paga no es cliente. Es estadística.",
	"LISANDRO: —Ese me compraba desde los catorce. Fidelidad. Ya no se ve eso.",
	"LISANDRO: —Mírelo. Y todavía me debe. Los muertos siempre deben.",
	"LISANDRO: —Yo no lo maté. Lo mató la bolsita. Yo nomás la vendí.",
	"LISANDRO: —Su mamá lo va a buscar en los carteles. Que busque. Es bonito que lo busquen a uno."]
const ADICTO_LINES := ["CLIENTE: —Patrón... una sola... se la pago mañana...", "CLIENTE: —Fíeme, patrón, que yo era bueno. Yo era bueno.",
	"CLIENTE: —Una papeleta, patrón. Le lavo el carro. Le lavo lo que sea."]
## La mini-Uzi del sicariato (en vez de la escopeta): rápida, gasta balas como agua.
const DEALER_WEAPONS := [
	{"name": "PUÑO", "tex": "puno", "dmg": 15, "cd": 0.45, "ammo": "", "pellets": 1, "spread": 0.0, "reach": 1.2},
	{"name": "PISTOLA", "tex": "pistola", "dmg": 14, "cd": 0.32, "ammo": "balas", "pellets": 1, "spread": 0.01, "reach": 40.0},
	{"name": "MINIUZI", "tex": "uzi", "dmg": 7, "cd": 0.1, "ammo": "balas", "pellets": 1, "spread": 0.045, "reach": 40.0},
]
var _beg_cd := 4.0
var _pelado_said := false
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
## Capítulo 1: las lámparas de araña de la casa de Don Lucho ({"pos", "hook", "state" up/falling/down, "t"}),
## cada una con el gancho de la pared donde está amarrada su cuerda (en la pared más cercana).
const LAMP_SPOTS := [Vector2(25.4, 15.5), Vector2(29.4, 18.2), Vector2(26.4, 21.2)]
const HOOK_SPOTS := [Vector2(27.6, 12.18), Vector2(30.82, 15.8), Vector2(28.3, 22.82)]
const LUCHO_TAKE := {"armor": 0.1, "stun": 0.7, "dark": 0.6}
## Cuánto se queda debajo de cada lámpara antes de cambiarse a otra.
const LUCHO_POSE_TIME := 5.0
var _lamps: Array = []
## Capítulo 2: las cajas fuertes ({"pr" (el decorado), "open"}) y los fajos que se riegan.
const SAFE_SPOTS := [Vector2(22.5, 15.9), Vector2(30.5, 14.0), Vector2(30.5, 19.6), Vector2(22.5, 19.1)]
const CORONEL_TAKE := {"fight": 0.1, "greed": 0.4, "count": 0.8, "broke": 0.7}
var _safes: Array = []
var _fajos: Array = []
var _boss_mode := ""
var _boss_t := 0.0
var _boss_hint := false
var _boss_fajo := Vector2.ZERO
var _lucho_lamp := -1          # debajo de cuál lámpara se va a parar (le gusta que lo vean)
var _lucho_said := false
var _lucho_blind := 0.0        # cuánto lleva sin verlo desde su lámpara
var _lucho_hunt := 0.0         # salió a buscarlo (después vuelve a la luz)
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
		"D": "dd_puerta", "L": "dd_puerta_llave", "E": "dd_salida",
		"O": "dd_olla", "H": "dd_hollin", "R": "dd_mural", "X": "dd_desaparecidos"}
	flats_tex = load("res://assets/shooter/dd_suelos.png")
	flats_n = 8
	kinds = {
		"rival": {"hp": 30, "speed": 1.8, "range": 0.9, "dmg": 10, "cd": 1.0, "attack": "melee", "h": 0.8, "sprite": "dl_pandillero"},
		"campanero": {"hp": 15, "speed": 2.3, "range": 0.0, "dmg": 0, "cd": 2.0, "attack": "whistle", "h": 0.62, "sprite": "dl_pelado"},
		"adicto": {"hp": 12, "speed": 1.0, "range": 0.8, "dmg": 3, "cd": 1.4, "attack": "melee", "h": 0.76, "sprite": "dl_adicto"},
		"tombo": {"hp": 40, "speed": 2.0, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "hitscan", "h": 0.82, "sprite": "dl_tombo"},
		"motorizado": {"hp": 40, "speed": 2.4, "range": 9.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 0.82, "sprite": "dl_sicario"},
		"coronel": {"hp": 220, "speed": 1.6, "range": 10.0, "dmg": 8, "cd": 1.5, "attack": "burst", "h": 1.15, "sprite": "dl_coronel"},
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
	ammo = {"balas": 120, "cartuchos": 0}
	weapons = DEALER_WEAPONS
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
		"alert": "(Un pelado pita. Doce años. Ya trabaja para mí. El barrio sabe que llegué.)",
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
			kinds["capo"] = {"hp": 600, "speed": 1.3, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 0.72, "sprite": "dl_lucho"}
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
			kinds["coronel"] = {"hp": 900, "speed": 1.4, "range": 11.0, "dmg": 8, "cd": 1.3, "attack": "burst", "h": 1.3, "sprite": "dl_coronel"}
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
				weapons = WEAPONS
				ammo = {"balas": 80, "cartuchos": 16}
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
## Letras nuevas: H = la olla (hollín), O = la olla con "SAPO = MUERTO", R = el mural del pelado muerto,
## X = desaparecidos.
const MAP := [
	"#HOCCHHHH#ZZZZZZZZZZZCQQQQQQQQQ#",
	"H........#...........X...W.....Q",
	"H........#...........X...W.....Q",
	"H........D...........X...W..W..Q",
	"H....#...#...........C.........Q",
	"H....#...#...........D.........Q",
	"HHHOHH...#....KK...##C.........Q",
	"C........Z....KK...##C...W.....Q",
	"R........Z.........##C...W..QQ.Q",
	"C.....P..Z...........C...W.....Q",
	"C........Z..P........C.........Q",
	"#........#...........GGGGGGGGGGG",
	"#...######........P..G.........G",
	"C........#ZZ.........G.........G",
	"C........#ZZ.........G..M...M..G",
	"C.....P..#ZZ.........G.........G",
	"C........#ZZ....KK...G.........G",
	"HHOHHH...#......KK...L.........E",
	"H........Z...........G.........G",
	"H........Z...........G.........G",
	"O..KK....ZZ..........G..M...M..G",
	"H........ZZ..........G.........G",
	"H........#Z..........G.........G",
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
	# La olla: los clientes fumando contra las paredes (no pelean), un colchón, el altarcito del mural.
	["dd_fumador", 1.35, 13.6, 0.42, 0.2], ["dd_fumador", 1.35, 15.4, 0.42, 0.2], ["dd_fumador", 4.6, 22.6, 0.42, 0.2],
	["dd_fumador", 1.35, 2.6, 0.42, 0.2], ["dd_fumador", 6.4, 1.35, 0.42, 0.2], ["dd_colchon", 3.0, 1.5, 0.16, 0.0],
	["dd_colchon", 7.2, 18.6, 0.16, 0.0], ["dd_velas", 0.75, 8.5, 0.28, 0.0],
	# La esquina del farol: Camila y Verónica (trabajan para Lisandro; los tiros no les hacen nada).
	["dd_camila", 13.25, 16.15, 0.7, 0.18], ["dd_veronica", 13.3, 16.95, 0.8, 0.18],
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
				0:  # el callejón (la olla): tierra y asfalto, más oscuro
					fr.append(Flat.TIERRA if (x + y * 3) % 7 == 0 else Flat.ASFALTO)
					cr.append(-1)
					lr.append(0.42)
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
	_boss_props()
	for c in [Vector2i(8, 7), Vector2i(8, 8), Vector2i(7, 7)]:  # un farol que se está muriendo
		flicker[c] = 2.3
	for c in [Vector2i(27, 4), Vector2i(27, 5), Vector2i(28, 5), Vector2i(26, 4)]:  # el tubo de la cocina
		flicker[c] = 5.0


func _place() -> void:
	var list := [
		["adicto", 3.5, 15.0], ["adicto", 6.5, 8.5], ["adicto", 3.0, 4.5], ["adicto", 15.5, 6.5], ["adicto", 14.5, 21.0],
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
	total = enemies.filter(func(e): return e.kind != "campanero").size()  # a los pelados no se les cuenta
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
	for f in _fajos.duplicate():
		if f.distance_to(pos) <= 0.5:
			_fajos.erase(f)
			_bonus = 0.4
			_say("(Lisandro se guarda el fajo. Costumbre. El Coronel lo vio: ahora le sube la cuota.)", 2)
			if _boss_mode == "greed" and f == _boss_fajo:
				_boss_mode = "fight"
				var c := _boss()
				if c:
					c.state = "chase"
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
	_beggars(delta)
	_quip_cd -= delta
	for pf in _puffs.duplicate():
		pf["t"] -= delta
		if pf["t"] <= 0.0:
			_puffs.erase(pf)
	_dog(delta)
	if _twist:
		_lis_fight(delta)
	_story(delta)
	if not _twist:
		_boss_fight(delta)
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
	if e.kind == boss_kind and not _twist and chapter in [1, 2] and _boss_mode != "":
		var take: Dictionary = LUCHO_TAKE if chapter == 1 else CORONEL_TAKE
		dmg *= take.get(_boss_mode, 1.0)
		_guard_say -= 1.0
		if _boss_mode in ["armor", "fight"] and _guard_say <= 0.0:
			_guard_say = 7.0
			_say("(¡TAC! Chaleco de los ochenta. De cuando los chalecos eran chalecos.)" if chapter == 1 else
				"(¡TAC! El uniforme. Dispararle a un Coronel sale caro, hasta en un sueño.)", 0)
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
	weapons = WEAPONS  # la escopeta de él
	owned = [true, true, true]
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
	# La instrucción, cuando ya pasó el destello blanco (encima del blanco no se lee).
	get_tree().create_timer(0.8).timeout.connect(func(): _say("Las bolsitas de afuera ahora son empanadas. Las de la casa no: esas son de él.", 2))
	_big.text = "AHORA ES ÉL"
	get_tree().create_timer(2.6).timeout.connect(func(): if state == "play" and _big.text == "AHORA ES ÉL": _big.text = "")
	_guard_say = 6.0  # que el ¡TAC! no la pise


# ---------------------------------------------------------------- El mundo de las drogas

## Los clientes se acercan pidiendo. Y los cartuchos de escopeta que caen son balas (Lisandro no tiene
## escopeta: tiene la mini-Uzi).
func _beggars(delta: float) -> void:
	if weapons != WEAPONS:
		for p in pickups:
			if p["kind"] == "cartuchos":
				p["kind"] = "balas"
	_beg_cd -= delta
	if _beg_cd > 0.0:
		return
	for e in enemies:
		if e.kind == "adicto" and e.state != "dead" and e.pos.distance_to(pos) < 3.0 and los(e.pos, pos):
			_beg_cd = 7.0
			_say(ADICTO_LINES.pick_random(), 0)
			return
	_beg_cd = 1.0


## A los pelados no les entran los tiros: se tiran al piso antes (ya saben).
func _shootable(e: Ent) -> bool:
	return e.kind != "campanero"


## Un tiro que pasa cerca de un pelado: se tira al piso, las manos en la cabeza.
func _duck(from: Vector2, dir: Vector2, reach: float) -> void:
	for e in enemies:
		if e.kind != "campanero" or e.state == "dead":
			continue
		var rel := e.pos - from
		var t := rel.dot(dir)
		if t > 0.0 and t < reach + 1.0 and absf(rel.cross(dir)) < 1.0:
			e.state = "pain"
			e.timer = 1.4
			if not _pelado_said:
				_pelado_said = true
				_say("(El pelado se tira al piso antes del tiro, las manos en la cabeza. Ya sabe. Tiene doce años y ya sabe.)", 2)


# ---------------------------------------------------------------- Los jefes de los capítulos 1 y 2 (acertijos)

## Las lámparas (cap. 1, con su luz) y las cajas fuertes (cap. 2, estorban) de la casa.
func _boss_props() -> void:
	_lamps.clear()
	_safes.clear()
	_fajos.clear()
	if FinalRush.is_step("lisandro"):
		return
	if chapter == 1:
		for y in range(12, 23):  # la casa de Don Lucho, en penumbra: la luz es de las lámparas
			for x in range(22, 31):
				light_base[y][x] = 0.45
		for i in LAMP_SPOTS.size():
			_lamps.append({"pos": LAMP_SPOTS[i], "hook": HOOK_SPOTS[i], "state": "up", "t": 0.0})
			_lamp_light(LAMP_SPOTS[i], 1.0)
	elif chapter == 2:
		for sp in SAFE_SPOTS:
			var pr := {"tex": "dd_cajafuerte", "pos": sp, "h": 0.42, "r": 0.3}
			props.append(pr)
			_safes.append({"pr": pr, "open": false})


## La luz alrededor de una lámpara: k = 1 la prende; menos, la apaga (se cayó).
func _lamp_light(at: Vector2, k: float) -> void:
	for y in range(int(at.y) - 3, int(at.y) + 4):
		for x in range(int(at.x) - 3, int(at.x) + 4):
			if x < 22 or x > 30 or y < 12 or y > 22:
				continue
			var l: float = clampf(1.2 - Vector2(x + 0.5, y + 0.5).distance_to(at) * 0.22, 0.0, 1.0)
			if k >= 1.0:
				light_base[y][x] = maxf(light_base[y][x], l)
			else:
				light_base[y][x] = maxf(0.22, light_base[y][x] - l * (1.0 - k))
			if not _light.is_empty():
				_light[y * 32 + x] = light_base[y][x]
	if _cells_img:
		_paint_cells()
		_cells_tex.update(_cells_img)


func _aim_object(a: float, tol: float) -> bool:
	for l in _lamps:
		if l["state"] == "up" and in_sight(l["hook"], a, tol):
			return true
	for sf in _safes:
		if not sf["open"] and in_sight(sf["pr"]["pos"], a, tol):
			return true
	for b in _bags:
		if in_sight(b, a, tol):
			return true
	return false


func _boss() -> Ent:
	for e in enemies:
		if e.kind == boss_kind and e.state != "dead":
			return e
	return null


func _boss_fight(delta: float) -> void:
	if chapter == 1:
		_lamps_fall(delta)
	var b := _boss()
	if b == null or not boss_awake or chapter > 2 or FinalRush.is_step("lisandro"):
		return
	if _boss_mode == "":
		_boss_mode = "armor" if chapter == 1 else "fight"
		_tex["capo_stun"] = _t("dl_lucho_stun")
		_tex["coronel_count"] = _t("dl_coronel_count")
	if not _boss_hint:
		_boss_hint = true
		_say("(Arañas italianas, cada una amarrada a un gancho en la pared. A Don Lucho le gusta pararse debajo de la luz.)" if chapter == 1 else
			"(Cajas fuertes en la casa del Coronel. Él no resiste un billete en el piso. Nadie de uniforme lo resiste.)")
	_boss_t -= delta
	_ammo_drop(delta)
	if chapter == 1:
		_lucho(b)
	else:
		_coronel(b, delta)


func _lucho(b: Ent) -> void:
	match _boss_mode:
		"stun":
			b.state = "pain"  # aplastado: quieto, sin disparar
			b.timer = 0.3
			b.pose = "stun"
			if _boss_t <= 0.0:
				b.pose = ""
				b.state = "chase"
				_boss_mode = "armor"
				_lucho_lamp = -1
				_say("DON LUCHO: —Me levanto. Siempre me levanto. Por eso sigo siendo el dueño.")
		"armor":
			if _lamps.all(func(l): return l["state"] == "down"):
				_boss_mode = "dark"
				_lucho_lamp = -1
				b.state = "chase"
				_say("DON LUCHO: —¡Apagaron mi casa! ... A oscuras el viejo no ve. Ni el chaleco le sirve de nada.", 2)
				return
			_lucho_pose(b, get_process_delta_time())


## Don Lucho se para debajo de una lámpara (le gusta que lo vean) y dispara desde ahí; cada rato se
## cambia a otra. Eso es lo que hay que aprovechar.
func _lucho_pose(b: Ent, delta: float) -> void:
	if _lucho_lamp < 0 or _lamps[_lucho_lamp]["state"] != "up" or _boss_t <= 0.0:
		var choices := []
		for i in _lamps.size():
			if _lamps[i]["state"] == "up" and (i != _lucho_lamp or _lamps.filter(func(l): return l["state"] == "up").size() == 1):
				choices.append(i)
		if choices.is_empty():  # la última se está cayendo
			return
		_lucho_lamp = choices.pick_random()
		_boss_t = LUCHO_POSE_TIME + 2.5  # lo que se demora en llegar, más lo que se queda
	var spot: Vector2 = _lamps[_lucho_lamp]["pos"]
	if b.state in ["attack", "pain"]:
		return
	if _lucho_hunt > 0.0:  # buscándolo: el motor lo persigue un rato
		_lucho_hunt -= delta
		if b.state in ["seek", "plant"]:
			b.state = "chase"
		return
	if b.pos.distance_to(spot) > 0.15:
		b.state = "seek"  # caminando a su lámpara (el motor no lo mueve)
		var next := _next_cell(b.pos, spot)
		_walk(b, (next - b.pos).normalized(), 1.7, delta)
		return
	if not _lucho_said:
		_lucho_said = true
		_say("DON LUCHO: —Aquí, debajo de la luz. Un capo que no se ve no es capo.")
	b.state = "plant"  # quieto debajo de la lámpara: dispara desde ahí
	b.moving = false
	_lucho_blind = 0.0 if los(b.pos, pos) else _lucho_blind + delta
	if _lucho_blind > 3.0:  # no lo ve desde la luz: sale a buscarlo
		_lucho_blind = 0.0
		_lucho_hunt = 4.0
		b.state = "chase"
		_say(["DON LUCHO: —¿Dónde se metió, pelado? En mi casa nadie se esconde de mí.",
			"DON LUCHO: —Salga. Le prometo que no le hago nada. (Mentira.)"].pick_random(), 0)
		return
	var to := pos - b.pos
	if b.cd <= 0.0 and to.length() < kinds[boss_kind]["range"] and los(b.pos, pos):
		b.state = "attack"
		b.timer = 0.35
		b.cd = kinds[boss_kind]["cd"]


func _lamps_fall(delta: float) -> void:
	for l in _lamps:
		if l["state"] != "falling":
			continue
		l["t"] -= delta
		if l["t"] > 0.0:
			continue
		l["state"] = "down"
		_lamp_light(l["pos"], 0.0)
		_puffs.append({"pos": l["pos"], "t": 1.0})
		var caught := false
		for e in enemies.duplicate():
			if e.state == "dead" or e.pos.distance_to(l["pos"]) > 1.2:
				continue
			if e.kind == boss_kind:
				caught = true
				_boss_mode = "stun"
				_boss_t = 3.5
				e.hp -= 50.0
				_say(["DON LUCHO: —¡Mi espalda! ¡Mi columna! ¡Mi lámpara!",
					"DON LUCHO: —¡Murano! ¡Era de Murano! ... ¡Y yo era de acá!",
					"DON LUCHO: —¡Otra vez! ¡Cuarenta años de esquina y me mata la decoración!"][_lamps.filter(func(x): return x["state"] == "down").size() - 1], 2)
				if e.hp <= 0.0:
					_die(e)
			elif _shootable(e):
				_damage(e, 80.0)
		if not caught:
			_say("(Se cayó la araña. Don Lucho no estaba debajo.) DON LUCHO: —¡Esa era de Murano, animal!", 2)


func _coronel(b: Ent, delta: float) -> void:
	match _boss_mode:
		"fight":
			if not _fajos.is_empty():
				_boss_fajo = _fajos[0]
				for f in _fajos:
					if f.distance_to(b.pos) < _boss_fajo.distance_to(b.pos):
						_boss_fajo = f
				_boss_mode = "greed"
				_boss_t = 8.0
				_say("EL CORONEL: —¡Eso es evidencia! ¡La decomiso!", 2)
			elif _safes.all(func(sf): return sf["open"]):
				_boss_mode = "broke"
				_say("EL CORONEL: —¿Se acabó la plata? Entonces esto ya es personal.", 2)
		"greed":
			if not _fajos.has(_boss_fajo) or _boss_t <= 0.0:
				if _zone_of(b.pos) != boss_zone:
					b.pos = summon_points[0]
				_boss_mode = "fight"
				b.state = "chase"
				return
			b.state = "seek"  # el motor no lo mueve: lo mueve la plata
			if b.pos.distance_to(_boss_fajo) < 0.5:
				_fajos.erase(_boss_fajo)
				_boss_mode = "count"
				_boss_t = 3.5
				_say("EL CORONEL: —Uno... dos... (se lame el dedo) ... tres... AHORA.", 2)
				return
			var next := _next_cell(b.pos, _boss_fajo)
			_walk(b, (next - b.pos).normalized(), 2.4, delta)
		"count":
			b.state = "pain"
			b.timer = 0.3
			b.pose = "count"
			if _boss_t <= 0.0:
				b.pose = ""
				b.state = "chase"
				_boss_mode = "fight"
				_say("EL CORONEL: —Faltan doscientos. Usted me debe doscientos.", 0)


## Los tiros de los capítulos 1 y 2: las lámparas (cuelgan: el tiro pasa por encima de la gente) y
## las cajas fuertes (en el piso: si hay alguien adelante, no le llega).
func _boss_ray(from: Vector2, dir: Vector2, reach: float, wall: float) -> void:
	for l in _lamps:  # la cuerda, en el gancho de la pared (si hay alguien adelante, el tiro no llega)
		if l["state"] != "up":
			continue
		var rel: Vector2 = l["hook"] - from
		var t := rel.dot(dir)
		if t <= 0.0 or t >= reach or absf(rel.cross(dir)) > 0.3:
			continue
		l["state"] = "falling"
		l["t"] = 0.35
		_say("(¡Tas! La cuerda se suelta.)", 0)
		return
	for sf in _safes:
		if sf["open"]:
			continue
		var rel: Vector2 = sf["pr"]["pos"] - from
		var t := rel.dot(dir)
		if t <= 0.0 or t >= reach or absf(rel.cross(dir)) > 0.32:
			continue
		sf["open"] = true
		sf["pr"]["tex"] = "dd_cajafuerte_abierta"
		var center := Vector2(26.5, 17.5)
		var at: Vector2 = sf["pr"]["pos"] + (center - sf["pr"]["pos"]).normalized() * 0.8
		_fajos.append(at if walkable(at) else sf["pr"]["pos"])
		_puffs.append({"pos": sf["pr"]["pos"], "t": 0.6})
		_bonus = 0.3
		_say("(¡PUM! La caja fuerte se abre. Un fajo al piso. Al Coronel le brillan las gafas.)", 0)
		return


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
				var max_l: float = kinds["lisandro"]["hp"] * (1.0 + dream_hard)
				lis.hp = minf(max_l, lis.hp + LIS_HEAL)
				_lis_mode = "rush"
				_lis_t = LIS_RUSH * (1.5 if FinalRush.is_step("lisandro") else 1.0)
				lis.state = "chase"
				_lis_speed(true)
				_say(RUSH_LINES_LIS[_lis_i % RUSH_LINES_LIS.size()] + " (Se cura. Le vuelve la vida, prestada. Correr.)", 2)
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


## Con poca munición en una pelea con jefe, aparece una caja en la casa (lejos de él): a puño no se le gana.
func _ammo_drop(delta: float) -> void:
	_resupply -= delta
	if _resupply > 0.0 or ammo["balas"] >= 20 or ammo["cartuchos"] >= 4:
		return
	_resupply = 10.0
	for p in pickups:
		if p["kind"] in ["balas", "cartuchos"] and _zone_of(p["pos"]) == boss_zone:
			return
	var lis := _lisandro() if _twist else _boss()  # lejos del jefe que haya
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
func _ray_hook(from: Vector2, dir: Vector2, reach: float, wall: float) -> void:
	_duck(from, dir, reach)
	if not _twist:
		_boss_ray(from, dir, reach, wall)
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
	for l in _lamps:
		if l["state"] == "down":
			out.append([l["pos"], _t("dd_arana_rota"), 0.13, 0.0])
		else:  # colgando cerca del techo (cayendo: baja)
			var elev: float = 0.6 if l["state"] == "up" else 0.6 * maxf(0.0, l["t"] / 0.35)
			out.append([l["pos"], _t("dd_arana"), 0.42, elev])
		out.append([l["hook"], _t("dd_gancho" if l["state"] == "up" else "dd_gancho_suelto"), 0.5, 0.2])
	for f in _fajos:
		out.append([f, _t("dd_fajo"), 0.12, 0.0])
	for b in _bags:
		out.append([b, _t("d_bolsita"), 0.26, 0.0])
	for pf in _puffs:
		out.append([pf["pos"], _t("dd_polvo"), 0.5 * (1.4 - pf["t"] * 0.3), 0.1])
	for sc in _scenes:
		if sc["tex"] != "" and (not sc["done"] or sc["keep"]):
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

## Los secretos del Dealer, uno por capítulo, metidos en los bloques del mapa.
##   1: el cuarto de Martín, el hijo de Lisandro (nueve años), jugando Switch: Mario, la luna.
##   2: el escondite de Lisandro: la plata de verdad, y una carta de la mamá.
##   3: un colchón y la pistola de agua de la foto (la de los dos pelados en la esquina).
func _secrets_setup() -> void:
	match chapter:
		1:
			add_secret(Vector2i(19, 7), "martin")
			grid[7][20] = "."
			_scenes.append({"id": "martin", "pos": Vector2(20.55, 7.5), "tex": "dd_martin", "h": 0.42, "done": false, "keep": true})
			_scenes.append({"id": "deco", "pos": Vector2(20.85, 7.15), "tex": "dd_lampara", "h": 0.62, "done": true, "keep": true})
		2:
			add_secret(Vector2i(11, 14), "escondite")
			grid[14][10] = "."
			grid[15][10] = "."
			pickups.append({"kind": "chaleco", "pos": Vector2(10.5, 14.5)})
			pickups.append({"kind": "balas", "pos": Vector2(10.5, 15.5)})
		3:
			add_secret(Vector2i(19, 7), "pistola_agua")
			grid[7][20] = "."
			pickups.append({"kind": "chaleco", "pos": Vector2(20.5, 7.5)})


func _on_secret(id: String) -> void:
	match id:
		"martin":
			_say("(Atrás de la pared, un cuarto con luz. Un niño en el piso. Un ruidito: \"¡Ua-hú!\")", 1)
		"escondite":
			_say("(El escondite de Lisandro: la plata de verdad, en una caja de galletas. Y una carta de la mamá, sin abrir: \"Mijo, coma.\")", 1)
		"pistola_agua":
			_say("(Un colchón y una pistola de agua de plástico verde. La de la foto. Lisandro la carga igual, por si acaso.)", 1)


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
			_scenes.append({"id": "esquina", "pos": Vector2(12.6, 16.55), "tex": "", "h": 0.0, "done": false, "keep": false})
		3:
			_scenes.append(phone)
			_scenes.append({"id": "senora", "pos": Vector2(20.35, 3.0), "tex": "dd_senora", "h": 0.7, "done": false, "keep": true})
			_scenes.append({"id": "foto", "pos": Vector2(23.0, 1.5), "tex": "dd_foto", "h": 0.45, "done": false, "keep": true})
			_dog_on = true  # Billete ya es de él
			_dog_pos = pos + Vector2(0.0, 1.0)


## La esquina del farol: cada vez que Lisandro pasa cerca, saluda a Camila y a Verónica por el nombre
## (y una le contesta). Así el que juega sabe quiénes son. Vuelve a saludar cuando se aleja y vuelve.
const ESQUINA := Vector2(13.27, 16.55)
const GREETS := [
	["LISANDRO: —Buenas noches, Camila. Verónica.", "CAMILA: —Quiubo, Gato. ¿Viene a cobrar o de visita?"],
	["LISANDRO: —Verónica. Camila. Se me cuidan.", "VERÓNICA: —De usted es del que hay que cuidarse, Lisandro."],
	["LISANDRO: —¡Mis reinas! Camila, Verónica.", "CAMILA: —Uy, el Gato contento. Alguien se murió."],
	["LISANDRO: —Camila. Vero. Buena noche para trabajar.", "VERÓNICA: —Para usted todas las noches son buenas."],
	["LISANDRO: —Quiubo, Vero. Quiubo, Camila.", "CAMILA: —Miau. Siete vidas y ninguna buena, ¿cierto, Gato?"],
]
var _greet_i := 0
var _greet_away := true


func _greet() -> void:
	var d := pos.distance_to(ESQUINA)
	if d > 3.5:
		_greet_away = true
		return
	if d > 2.2 or not _greet_away or state != "play" or FinalRush.is_step("lisandro"):
		return  # (en la revancha del final el que juega no es Lisandro)
	for sc in _scenes:  # en el capítulo 2, la primera vez es la escena de la cuota
		if sc["id"] == "esquina" and not sc["done"]:
			return
	_greet_away = false
	var g: Array = GREETS[_greet_i % GREETS.size()]
	_greet_i += 1
	_say(g[0], 2)
	_say(g[1], 1)


func _story(_delta: float) -> void:
	if _twist:
		return
	_greet()
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
				["PELADO", "—¿Usted es el Gato? ... Patrón. ¿Me da trabajo? Tengo doce. Mi mamá está enferma. Bueno, no está enferma, pero está brava."],
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
		"esquina":
			var i := await _talk([
				["CAMILA", "—Llegó el Gato. Mírelo, Vero: camisa blanca. Blanca, en este barrio. Eso es tener plata o no tener vergüenza."],
				["LISANDRO", "—Verónica. La ex del que no se muere. Los ojos azules, todavía. Mire dónde vino a parar."],
				["VERÓNICA", "—Vine a parar donde usted me puso, Lisandro."],
				["CAMILA", "—Y yo por meterme en la mitad. Me dieron celos de ella, ¿sabe? De que él la quisiera así. Ya ve: ahora tenemos la misma esquina. Se me cumplió."],
				["LISANDRO", "—La cuota. La suya y la de ella."],
				["VERÓNICA", "—Esta semana no hubo. Llovió. Cuando llueve nadie para."],
				["LISANDRO", "—La deuda no se moja."],
				["", "Verónica tiene un morado debajo del ojo azul. Lisandro lo mira como se mira una cuenta: sabe cuánto costó y quién lo cobró."],
			], ["Cobrar igual", "Dejarlo para la otra semana"])
			GameState.flags["lis_esquina"] = i
			if i == 0:
				await _talk([
					["CAMILA", "—Tome. (Le da la plata de las dos.) Cuéntela, que usted no confía ni en la plata."],
					["LISANDRO", "—Completa. Así me gusta. Puntuales como el Metro."],
					["VERÓNICA", "—El Metro para a medianoche, Lisandro. Nosotras no."],
				])
				ammo["balas"] = mini(200, ammo["balas"] + 25)
				_say("(Con la plata de ellas, Lisandro compra balas. Así funciona: todo se convierte en balas.)")
			else:
				await _talk([
					["LISANDRO", "—La otra semana. Con intereses."],
					["CAMILA", "—Qué generoso. Así empieza siempre usted: generoso. Después cobra el doble."],
					["VERÓNICA", "—Gracias. (No se lo dice a él. Se lo dice a la lluvia, que fue la que paró.)"],
				])
				_say("(Lisandro se siente buena persona durante cuatro segundos. Se le pasa.)")
			await _talk([
				["CAMILA", "—Oiga, Lisandro. ¿Usted conoce a uno grande, verde, que anda preguntando por usted?"],
				["LISANDRO", "—No. ¿Por?"],
				["VERÓNICA", "—Porque preguntó también por mí. Por el nombre. Nadie aquí me dice por el nombre."],
				["CAMILA", "—Tenía cara de que iba a durar más que usted."],
			])
		"martin":
			await _martin()
		"senora":
			var j := await _talk([
				["SEÑORA", "—Joven, ¿usted lo ha visto? Se llama Brayan. Tiene diecisiete. Tenía... no. Tiene. Tiene diecisiete."],
				["", "Lisandro mira la foto. Lo conoce. El martes. Le debía cuarenta mil."],
			], ["No, señora.", "(Quedarse callado)"])
			if j == 0:
				await _talk([
					["LISANDRO", "—No, señora. No lo he visto."],
					["SEÑORA", "—Gracias, joven. Dios le pague."],
					["", "Dios no le paga a Lisandro. Le pagan otros. Por cosas como el martes."],
				])
			else:
				await _talk([["", "Lisandro no dice nada. La señora le pone un cartel en la mano y sigue pegando, encima de los viejos, encima de los de otras mamás."]])
			await _talk([["", "En la pared hay cuarenta carteles. Lisandro conoce a once."]])
		"foto":
			await _talk([
				["", "Una foto vieja en una mesita: dos pelados en la misma esquina, con la misma pistola de agua."],
				["", "Uno es Lisandro. El otro es él. Uno sonríe. El otro mira al que sonríe."],
				["LISANDRO", "—Él siempre tenía con quién jugar. Yo tenía la pistola."],
				["LISANDRO", "—Después yo tuve todo. Y él seguía teniendo con quién jugar. ... No se puede comprar eso, Billete. Lo intenté."],
			])


## Martín, el hijo de Lisandro. Nueve años. Juega Switch en un cuarto escondido: es el único lugar del
## barrio donde Lisandro no es el Gato. Ahí es el papá. (Lisandro no es el protagonista: es él quien
## lo encuentra, en su propio sueño.)
func _martin() -> void:
	var i := await _talk([
		["", "Martín, nueve años, sentado en el piso con las piernas cruzadas. Juega Switch con el volumen bajito. En la pantalla, Mario salta con la gorra."],
		["LISANDRO", "—¿Martín? ¿Usted qué hace aquí? ¿Quién lo trajo?"],
		["MARTÍN", "—Shh, pa. Me falta una luna. La del sombrero. Llevo toda la tarde."],
		["MARTÍN", "—Afuera hay mucho ruido. Aquí no. ¿Usted me pasa esta parte? Usted es bueno saltando. Mi mamá dice que usted salta de todo."],
		["", "Afuera suenan tiros. Martín no levanta la cabeza. Ya sabe cuáles son lejos y cuáles son cerca."],
	], ["Sentarse a jugar con él", "Irse a trabajar"])
	GameState.flags["lis_martin"] = i
	if i == 0:
		await _talk([
			["", "Lisandro se sienta en el piso. Le queda pequeño el piso. Martín le pasa el control."],
			["", "Mario se cae al vacío. Otra vez. Otra vez. A la cuarta, salta."],
			["MARTÍN", "—¡LA LUNA! ¡Pa, la luna! ¡La sacó usted!"],
			["LISANDRO", "—... No le cuente a nadie. Que el Gato juega Mario."],
			["MARTÍN", "—¿Quién es el Gato?"],
			["LISANDRO", "—Nadie, mijo. Nadie que usted conozca."],
		])
		hp = max_hp
		_say("(Lisandro sale con la vida llena. Y con algo más que no sabe dónde guardar.)", 1)
	else:
		await _talk([
			["LISANDRO", "—Ahorita vengo, mijo. Tengo que trabajar."],
			["MARTÍN", "—Eso dijo ayer."],
			["", "Martín no levanta la cabeza. Mario salta. Se cae."],
		])
		ammo["balas"] = mini(200, ammo["balas"] + 30)
		_say("(Debajo del colchón de Martín había una caja de balas. Lisandro se la lleva. No mira para atrás.)", 1)


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
				["MAMÁ", "—Preguntó por \"el Gato\". Le dije que aquí no vive ningún gato. Que aquí vive Lisandro, que es gerente."],
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
	if not _twist and e.kind == "adicto" and _quip_cd <= 0.0:
		_quip_cd = 9.0
		_say(ADICTO_QUIPS.pick_random(), 0)
		return
	if not _twist and e.kind not in [mini_kind, boss_kind] and _quip_cd <= 0.0 and randf() < 0.3:
		_quip_cd = 14.0
		_say(KILL_QUIPS.pick_random(), 0)


func _respawn() -> void:
	super._respawn()
	if _twist:
		armor = 60.0


func _load_kit(wp: String, fp: String) -> void:
	for w in weapons:
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
	if GameState.flags.get("lis_esquina", -1) == 0:
		end.append(["", "En la esquina del farol, Camila y Verónica ya no le deben a Lisandro. Ahora le deben a otro. La deuda no se muere: cambia de dueño."])
	end.append(["", "Al pasar por la esquina, Verónica me mira. Los ojos azules, todavía. No dice nada. Yo tampoco: no hay nada que decir que no haya dicho ya el barrio."])
	match GameState.flags.get("lis_pelado", -1):
		0:
			end.append(["", "Afuera, en la esquina, el pelado pita. Ya trabaja para otro. Así se hereda esto."])
		1:
			end.append(["", "En algún colegio hay un pelado con un billete falso de Lisandro. Ojalá lo haya gastado en algo que valga."])
	end.append(["", "EPISODIO COMPLETO."])
	await Dialogue.talk(end)
	_finish()
