extends "res://scripts/world/MotoRide.gd"
## La primera vuelta: después de llegar a la casa de ella, Lorena se sube atrás. Ahora es al revés que
## en la ida: no hay reloj, y ella lo regaña cuando va rápido (casi siempre). Si va a una velocidad
## tranquila un rato, se ríe; si va demasiado lento, se burla. Si se estrella, "¡SE LO DIJE!".
## Al final se cuenta: cuántas veces se rió, cuántas lo regañó. Después, de vuelta al presente.

const FAST := 0.72        # más de esto (de la velocidad máxima) y empieza el regaño
const CALM := Vector2(0.3, 0.62)  # en esta franja, un rato, y se ríe
const SLOW := 0.2
const SCOLD := [
	"LORENA: —¡Más despacio! ¡Que yo me peiné!",
	"LORENA: —¡Usted maneja como si lo persiguiera el ICETEX!",
	"LORENA: —¡Me va a matar! ¡Y yo con estos zapatos!",
	"LORENA: —¡Esto no es la Fórmula Uno, esto es la avenida!",
	"LORENA: —¡Le voy a contar a mi mamá! ¡Y a la suya!",
	"LORENA: —¡Despacio, que se me sale el corazón! ¡Y lo tengo maquillado!",
	"LORENA: —¡Si me caigo, me caigo con usted! ¡Pero primero lo mato!",
	"LORENA: —¡Frene! ¡Frene! ... No tanto. ¡Ay, usted es imposible!",
	"LORENA: —¡El viento me está despeinando por dentro!",
	"LORENA: —¡¿Usted sabe cuánto me costó este cepillado?!",
]
const LAUGH := [
	"LORENA: —¡Jajaja! ¡Así sí! ¡Así sí me gusta!",
	"(Se ríe con la cara contra su espalda. La risa se le siente en las costillas.)",
	"LORENA: —¡Jaja! ¡Mire ese perro corriéndonos!",
	"LORENA: —¡Jajaja! ¡Usted maneja con una cara de serio!",
]
const TOO_SLOW := [
	"LORENA: —¿Ya llegamos? Ah, no, es que vamos parados.",
	"LORENA: —Mi abuela camina más rápido. Y mi abuela está muerta.",
]
const CRASH := ["LORENA: —¡¿VIO?! ¡SE LO DIJE! ¡SE LO DIJE!", "LORENA: —¡Mi pelo! ¡MI PELO, POR DIOS!",
	"LORENA: —¡Yo sabía! ¡Yo sabía que hoy me moría!"]

var _lorena: Texture2D
var _lorena_laugh: Texture2D
var _fast_t := 0.0
var _calm_t := 0.0
var _slow_t := 0.0
var _cool := 3.0
var _laughing := 0.0
var _i_scold := 0
var _i_laugh := 0
var _i_slow := 0
var scolds := 0
var laughs := 0


func setup() -> void:
	time_limit = 0.0  # con ella atrás no hay apuro (eso dice ella)
	start_line = "(Ella se sube atrás y le agarra la cintura. Él arranca despacio. Por ahora.)"
	half_line = "(Ella le aprieta la cintura en cada curva. Él no se lo dice a nadie, pero frena en las curvas para eso.)"
	goal_label = "LA PRIMERA VUELTA"
	sky_top = Color(0.62, 0.32, 0.5)
	sky_low = Color(1.0, 0.62, 0.45)
	haze = Color(0.95, 0.6, 0.55)
	_lorena = load("res://assets/moto/lorena_atras.png")
	_lorena_laugh = load("res://assets/moto/lorena_atras_risa.png")


func _ride(dt: float) -> void:
	super._ride(dt)
	_cool -= dt
	_laughing = maxf(0.0, _laughing - dt)
	var pct := speed / MAX_SPEED
	_fast_t = _fast_t + dt if pct > FAST else maxf(0.0, _fast_t - dt * 2.0)
	_calm_t = _calm_t + dt if pct > CALM.x and pct < CALM.y else 0.0
	_slow_t = _slow_t + dt if pct < SLOW else 0.0
	if _cool > 0.0:
		return
	if _fast_t > 1.2:
		Narrator.say(SCOLD[_i_scold % SCOLD.size()], true)
		_i_scold += 1
		scolds += 1
		_fast_t = 0.0
		_cool = 3.2
	elif _calm_t > 5.0:
		Narrator.say(LAUGH[_i_laugh % LAUGH.size()], true)
		_i_laugh += 1
		laughs += 1
		_laughing = 1.6
		_calm_t = 0.0
		_cool = 4.0
	elif _slow_t > 4.0 and time > 6.0:
		Narrator.say(TOO_SLOW[_i_slow % TOO_SLOW.size()], true)
		_i_slow += 1
		laughs += 1  # se burla, pero se está riendo
		_laughing = 1.2
		_slow_t = 0.0
		_cool = 4.0


func _crash(lines: Array, keep: float) -> void:
	super._crash([CRASH[crashes % CRASH.size()]], keep)
	scolds += 1
	_cool = 3.0


func _draw_rider_extra(at: Vector2, _size: Vector2) -> void:
	var hop := -1.0 if _laughing > 0.0 and int(_laughing * 8.0) % 2 == 0 else 0.0  # se ríe: rebota
	draw_texture(_lorena_laugh if _laughing > 0.0 else _lorena, at + Vector2(_lean, hop))


func _arrival() -> void:
	_hud_center.text = ""
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 1.2)
	await t.finished
	_engine.stop()
	var lines := [["", "Paran en el mirador. Abajo, la ciudad se prende de a poquitos."]]
	if laughs >= scolds:
		lines += [["LORENA", "—... Bueno. Estuvo bonito. No le digo más porque se lo cree."],
			["", "(Se ríe. Le da un beso en el casco, porque no se quitó el casco. Él tampoco se lo quita: para que no se le note.)"]]
	else:
		lines += [["LORENA", "—Nunca más. Nunca más me subo a esa cosa con usted. ¡Nunca!"],
			["LORENA", "—... ¿Mañana me recoge a las seis?"]]
	lines.append(["", "Se rió %d %s. Lo regañó %d %s." % [laughs, "vez" if laughs == 1 else "veces", scolds, "vez" if scolds == 1 else "veces"]])
	await Dialogue.talk(lines)
	await Recuerdo.show("lorena")  # la foto de ese día
	await Dialogue.talk([["", "Ninguno de los dos sabía lo que venía después."]])
	_back_to_present()
