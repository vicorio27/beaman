extends Node
## Reloj del día (vida real). 1 segundo real = 1,8 minutos de juego: un día de 06:17 a 22:00
## dura unos 8 minutos y medio. Solo corre en las escenas de la vida real y con las ventanas cerradas.

signal minute_passed(total_minutes: float)
signal hour_changed(hour: int)

const MINUTES_PER_SECOND := 1.8
const DAY_START := 6 * 60 + 17

## Minutos desde la medianoche.
var minutes := float(DAY_START)
## Lo prende cada lugar de la vida real (Location); en los sueños queda apagado.
var running := false
var _last_hour := 6


func _process(delta: float) -> void:
	if not running or GameState.ui_open or SceneRouter.busy:
		return
	var step := delta * MINUTES_PER_SECOND
	minutes += step
	GameState.pass_time(step)
	minute_passed.emit(minutes)
	var h := hour()
	if h != _last_hour:
		_last_hour = h
		hour_changed.emit(h)


func hour() -> int:
	return int(minutes / 60.0) % 24


func clock_text() -> String:
	var m := int(minutes) % (24 * 60)
	return "%02d:%02d" % [m / 60, m % 60]


func set_time(h: int, m: int) -> void:
	minutes = h * 60.0 + m
	_last_hour = h


## Avanza horas de golpe (desmayo, dormir). También pasa el hambre de esas horas.
func skip(hours: float) -> void:
	minutes += hours * 60.0
	GameState.pass_time(hours * 60.0)
	_last_hour = hour()
	hour_changed.emit(_last_hour)
