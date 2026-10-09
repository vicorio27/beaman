extends Node
## Registra las acciones de input al arrancar (teclado + gamepad).
## Se hace por código para que los bindings queden legibles en un solo lugar;
## se pueden mover al Input Map del editor más adelante sin cambiar nada más.

const ACTIONS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"cancel": [KEY_Q, KEY_ESCAPE],
	"inventory": [KEY_TAB, KEY_I],
	"drop": [KEY_X],
	"sniff": [KEY_F],
	"craft": [KEY_C],
	"libreta": [KEY_L],
}

const PAD_BUTTONS := {
	"move_up": JOY_BUTTON_DPAD_UP,
	"move_down": JOY_BUTTON_DPAD_DOWN,
	"move_left": JOY_BUTTON_DPAD_LEFT,
	"move_right": JOY_BUTTON_DPAD_RIGHT,
	"interact": JOY_BUTTON_A,
	"cancel": JOY_BUTTON_B,
	"inventory": JOY_BUTTON_Y,
	"drop": JOY_BUTTON_X,
	"sniff": JOY_BUTTON_RIGHT_SHOULDER,
	"craft": JOY_BUTTON_LEFT_SHOULDER,
	"libreta": JOY_BUTTON_BACK,
}

const PAD_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}


## ¿Se juega con los dedos? (la versión web en el celular). Las pantallas dejan libre la franja
## derecha (x > 286) para los botones, y los avisos de abajo se angostan entre la palanca y los botones.
static var force_touch := false  # para probar el diseño del celular en el computador
## Controles en pantalla: "auto" (solo si hay pantalla táctil), "si" o "no". Se elige en el título
## y se guarda en user://ajustes.cfg.
static var touch_pref := "auto"
const SETTINGS := "user://ajustes.cfg"
const TOUCH_PREFS := ["auto", "si", "no"]


static func touch() -> bool:
	if force_touch or touch_pref == "si":
		return true
	if touch_pref == "no":
		return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")


static func set_touch_pref(pref: String) -> void:
	touch_pref = pref
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("controles", "en_pantalla", pref)
	cfg.save(SETTINGS)


## Cómo se llama el botón de una acción en lo que tiene el jugador en la mano: en el celular, la letra
## del botón en pantalla ("A"); si no, la tecla ("E"). Para los avisos ("[E] agarrar").
static func key_name(action: String) -> String:
	var touch_names := {"interact": "A", "cancel": "B", "inventory": "I", "drop": "X", "sniff": "huella", "libreta": "libro"}
	if touch() and touch_names.has(action):
		return touch_names[action]
	var keys: Array = ACTIONS.get(action, [])
	return OS.get_keycode_string(keys[0]) if not keys.is_empty() else action


## En el celular, los textos que nombran teclas ("E: golpe", "[Q] dejar", "F: provocar") nombran el
## botón en pantalla. Solo letras sueltas (una E sola, no la de una palabra).
static func keys_in(text: String) -> String:
	if not touch():
		return text
	var out := text
	for pair in [["E", "A"], ["Q", "B"], ["F", "huella"], ["Tab", "I"]]:
		var re := RegEx.new()
		re.compile("(?<![\\wÁÉÍÓÚáéíóúñÑ'])%s(?![\\wÁÉÍÓÚáéíóúñÑ'])" % pair[0])
		out = re.sub(out, pair[1], true)
	return out


## Hasta dónde llega el texto a la derecha: con controles en pantalla, la franja x > 286 es de los botones.
static func right_edge() -> float:
	return 286.0 if touch() else 320.0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		var pref: String = cfg.get_value("controles", "en_pantalla", "auto")
		if pref in TOUCH_PREFS:
			touch_pref = pref
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		var btn := InputEventJoypadButton.new()
		btn.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, btn)
		if PAD_AXES.has(action):
			var axis := InputEventJoypadMotion.new()
			axis.axis = PAD_AXES[action][0]
			axis.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, axis)
