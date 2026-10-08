extends CanvasLayer
## Filtro de ánimo de pantalla. El hambre empuja la imagen del registro cálido al frío.
## Por ahora el hambre vive acá; en la Fase 3 se lee de GameState.
##
## Herramienta de prueba (solo en builds de debug, oculta por defecto):
##   F3     -> mostrar / ocultar el panel de prueba
##   1 / 2  -> bajar / subir hambre 10 (con el panel visible)
##   3      -> activar / desactivar el modo memoria (con el panel visible)

## Por encima de este valor de hambre la imagen está 100% cálida.
const CALM_ABOVE := 70.0

@export_range(0, 100) var hunger := 80.0
## Si es >= 0, ignora el hambre y usa este valor (el prólogo lo maneja a mano).
@export_range(-1.0, 1.0) var forced_distress := -1.0

var memory_on := false

@onready var mat: ShaderMaterial = $Screen.material
@onready var debug_label: Label = $Debug/Label


func _ready() -> void:
	debug_label.visible = false
	_apply(true)


func _process(delta: float) -> void:
	if forced_distress < 0.0 and not debug_label.visible:
		hunger = GameState.hunger
	_apply(false, delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or forced_distress >= 0.0 or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_F3:
		debug_label.visible = not debug_label.visible
		return
	if not debug_label.visible:
		return
	match event.physical_keycode:
		KEY_1:
			hunger = maxf(hunger - 10.0, 0.0)
		KEY_2:
			hunger = minf(hunger + 10.0, 100.0)
		KEY_3:
			memory_on = not memory_on


func target_distress() -> float:
	if forced_distress >= 0.0:
		return forced_distress
	var d := clampf(1.0 - hunger / CALM_ABOVE, 0.0, 1.0)
	# El ánimo bajo también oscurece el mundo (un poco menos que el hambre).
	d = maxf(d, clampf(1.0 - GameState.mood / 45.0, 0.0, 1.0) * 0.8)
	# Acariciar a Lukas (o jugar con él) calma un rato.
	return d * 0.35 if GameState.is_calm() else d


## Las transiciones son lentas a propósito: el jugador lo nota sin que se lo anuncien.
func _apply(instant: bool, delta := 0.0) -> void:
	var d: float = mat.get_shader_parameter("distress")
	var m: float = mat.get_shader_parameter("memory")
	var td := target_distress()
	var tm := 1.0 if memory_on else 0.0
	if instant:
		d = td
		m = tm
	else:
		d = move_toward(d, td, delta * (2.0 if forced_distress >= 0.0 else 0.35))
		m = move_toward(m, tm, delta * 1.5)
	mat.set_shader_parameter("distress", d)
	mat.set_shader_parameter("memory", m)
	var g: float = mat.get_shader_parameter("grief") if mat.get_shader_parameter("grief") != null else 0.0
	mat.set_shader_parameter("grief", GameState.grief() if instant else move_toward(g, GameState.grief(), delta * 0.2))
	if debug_label.visible:
		debug_label.text = "HAMBRE %d  [1/2]  MEMORIA [3]" % hunger
