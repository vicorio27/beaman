class_name TenisPublico
extends Node2D
## El público del coliseo: el fondo (las tribunas vacías) y, encima, cada persona por su lado
## (tools/art/draw_tenis_coliseo.py: assets/tenis/publico.png y publico.json). Va detrás de lo que
## pinta TenisMatch (show_behind_parent).
## Lo que hace la gente:
##   cheer(fuerza, x): se para (los más cerca del punto primero) con los brazos arriba o la bandera.
##   clap(): unos cuantos aplauden.   uy(): unos cuantos se agarran la cabeza.
##   ola(): la ola, que sube por la izquierda, cruza el fondo y baja por la derecha.
## Y sola, todo el tiempo: alguno aplaude, alguno se para un momentico, alguno voltea a mirar.
## A los perezosos (publico.json) no los para nadie, ni la ola.

const BG := preload("res://assets/tenis/coliseo.png")
const SHEET := preload("res://assets/tenis/publico.png")
const FRAMES := ["sentado", "aplaude1", "aplaude2", "arriba1", "arriba2", "uy", "bandera1", "bandera2", "mira"]
const OLA_LEN := 5.0   # segundos que tarda la vuelta
const OLA_W := 0.045   # qué tan ancha es (en la vuelta, de 0 a 1)

var _cell := Vector2(8, 11)
var _origin := 5
var _x := PackedFloat32Array()
var _y := PackedFloat32Array()
var _flag := PackedByteArray()
var _lazy := PackedByteArray()
var _ola_at := PackedFloat32Array()
var _from := PackedFloat32Array()    # de pie: desde cuándo
var _until := PackedFloat32Array()   # de pie: hasta cuándo
var _clap := PackedFloat32Array()    # aplaudiendo hasta
var _uy := PackedFloat32Array()      # con las manos en la cabeza hasta
var _look := PackedFloat32Array()    # mirando para otro lado hasta
var _phase := PackedFloat32Array()   # para que no se muevan todos al tiempo
var _t := 0.0
var _ola := -1.0
var _idle := 0.0
var _redraw := 0.0


func _ready() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var info: Dictionary = (load("res://assets/tenis/publico.json") as JSON).data
	_cell = Vector2(info["cell"][0], info["cell"][1])
	_origin = int(info["origin_y"])
	assert(Array(info["frames"]) == FRAMES)
	for p in info["people"]:
		_x.append(float(p[0]))
		_y.append(float(p[1]))
		_flag.append(int(p[2]))
		_lazy.append(int(p[3]))
		_ola_at.append(float(p[4]))
		_phase.append(randf())
	for arr in [_from, _until, _clap, _uy, _look]:
		arr.resize(_x.size())
	_from.fill(0.0)
	_until.fill(0.0)
	_clap.fill(0.0)
	_uy.fill(0.0)
	_look.fill(0.0)


## Se para la gente: `strength` (0 a 1) cuánta; los más cerca de `x` (en la pantalla) primero.
func cheer(strength: float, x: float = 160.0) -> void:
	for i in _x.size():
		if _lazy[i] or randf() > strength:
			continue
		_from[i] = _t + randf() * 0.3 + absf(_x[i] - x) / 320.0 * 0.5
		_until[i] = _from[i] + randf_range(1.1, 2.2)


func clap(amount := 0.45) -> void:
	for i in _x.size():
		if randf() < amount:
			_clap[i] = _t + randf_range(0.7, 1.8)


func uy(amount := 0.35) -> void:
	for i in _x.size():
		if randf() < amount:
			_uy[i] = _t + randf_range(0.6, 1.2)


func ola() -> void:
	if _ola < 0.0:
		_ola = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _ola >= 0.0:
		_ola += delta / OLA_LEN
		if _ola > 1.0 + OLA_W:
			_ola = -1.0
	# Lo de siempre: alguno aplaude solo, alguno se para a estirarse, alguno voltea a mirar.
	_idle -= delta
	if _idle <= 0.0:
		_idle = randf_range(0.15, 0.4)
		var i := randi() % _x.size()
		var r := randf()
		if r < 0.45:
			_look[i] = _t + randf_range(0.8, 2.5)
		elif r < 0.8:
			_clap[i] = _t + randf_range(0.5, 1.2)
		elif not _lazy[i]:
			_from[i] = _t
			_until[i] = _t + randf_range(0.6, 1.4)
	_redraw -= delta
	if _redraw <= 0.0:  # la gente no necesita 60 cuadros: con 12 se ve viva
		_redraw = 1.0 / 12.0
		queue_redraw()


func _draw() -> void:
	draw_texture(BG, Vector2.ZERO)
	for i in _x.size():
		var f := _frame(i)
		var src := Rect2(Vector2(f * _cell.x, i * _cell.y), _cell)
		draw_texture_rect_region(SHEET, Rect2(Vector2(_x[i], _y[i] - _origin), _cell), src)


func _frame(i: int) -> int:
	var beat := int((_t + _phase[i]) * 5.0) % 2
	var up := _t >= _from[i] and _t < _until[i]
	if _ola >= 0.0 and not _lazy[i] and absf(_ola - _ola_at[i]) < OLA_W:
		up = true
	if up:
		return (6 if _flag[i] else 3) + beat
	if _t < _uy[i]:
		return 5
	if _t < _clap[i]:
		return 1 + int((_t + _phase[i]) * 8.0) % 2
	if _t < _look[i]:
		return 8
	return 0
