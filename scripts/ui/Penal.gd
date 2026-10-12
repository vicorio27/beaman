class_name Penal
extends CanvasLayer
## Penaltis con los pelados del lote: una tanda de seis, por turnos. Unas veces tapa él, otras patea.
##   TAPAR: el que patea toma carrera y, justo antes, se le va el cuerpo para un lado (casi siempre es
##     para donde patea; a veces engaña). Tirarse a tiempo: izquierda, arriba (el medio) o derecha.
##   PATEAR: la mira va y viene sola por el arco: [E] la clava. Después sube y baja la fuerza: [E] otra
##     vez. Poquita, sale rastrera (fácil de tapar); mucha, se va por encima, a la casa de doña Rosa.
##     Arriba y a un lado, no la tapa nadie.
##   var res: Array = await Penal.play(self, [[nombre, frase], ...])   # [atajadas, goles de él, goles de ellos]
## Todo dibujado por código (_Cancha): el lote, el arco de morrales, la barra, Lukas, el papel picado.

signal _done(result: Array)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const PANEL := Rect2(34, 34, 252, 144)  # debajo de la barra de arriba; a la izquierda de los botones
const GOAL := Rect2(112, 62, 96, 38)
const SPOT := Vector2(160, 134)  # el punto penal
const RUNUP := 1.1  # la carrera; a los 0.6 se le va el cuerpo
const TELL_AT := 0.6
const FLY := 0.5  # lo que tarda la pelota en llegar
const TRUTH := 0.72  # qué tanto el cuerpo dice la verdad
const ROUNDS := 6
const SAVE_LINES := ["Con la panza. Cuenta igual.", "Con la punta de los dedos.", "Le pega en la cara y sale. Cuenta."]
const CONCEDE_LINES := ["Por el otro lado.", "Lo engañó con el cuerpo.", "Lo celebran como un Mundial."]
const SCORE_LINES := ["El arquero todavía la está buscando.", "Al ángulo. Donde duermen las arañas.", "Los pelados piden revisión. No hay."]
const MISS_LINES := ["Se la tapó un niño de nueve años.", "El arquero ni se despeinó.", "Ahí estaba el pelado. Siempre está."]
const OVER_LINES := ["Por encima. A la casa de doña Rosa.", "Afuera. La pelota conoce el barrio.", "Esa todavía va subiendo."]

var _shots: Array = []
var _i := 0
var _start := 0      # quién arranca tapando (0) o pateando (1)
var _saves := 0
var _mine := 0       # goles de él
var _theirs := 0     # goles de los pelados
var _role := "arco"  # "arco": tapa él. "patea": patea él.
var _state := "runup"
var _t := 0.0
var _aim := 1        # 0 izquierda, 1 medio, 2 derecha
var _tell := 1
var _dive := -1
var _guard := 0.3
var _aim_x := 160.0
var _power := 0.0
var _from := SPOT
var _to := SPOT
var _ball := SPOT
var _ball_h := 0.0   # qué tan alto va (para la sombra)
var _stopped := false
var _over := false
var _net := 0.0      # la red se sacude
var _cheer := 0.0    # la barra salta
var _tell_on := false
var _bits: Array = []  # el papel picado
var _field: Node2D
var _him: AnimatedSprite2D
var _kid: AnimatedSprite2D
var _score: Label
var _big: Label
var _who: Label


static func play(parent: Node, shots: Array) -> Array:
	var ui := Penal.new()
	ui._shots = shots
	parent.get_tree().root.add_child(ui)
	var res: Array = await ui._done
	ui.queue_free()
	return res


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.ui_open = true
	_start = randi() % 2
	_field = Node2D.new()
	_field.draw.connect(_draw_field)
	add_child(_field)
	_kid = AnimatedSprite2D.new()
	_kid.sprite_frames = CharacterFrames.adult(CharacterFrames.STRANGERS[1])
	_kid.scale = Vector2(0.8, 0.8)  # un pelado
	add_child(_kid)
	_him = AnimatedSprite2D.new()
	_him.sprite_frames = CharacterFrames.protagonist()
	add_child(_him)
	var over := Node2D.new()  # la pelota y el papel picado, encima de los muñecos
	over.draw.connect(_draw_over.bind(over))
	over.name = "Encima"
	add_child(over)
	_score = _label(Vector2(PANEL.position.x, 37), Color(0.95, 0.85, 0.55), 8)
	_big = _label(Vector2(PANEL.position.x, 104), Color(1, 0.95, 0.6), 16)
	_big.size.y = 18
	_who = _label(Vector2(PANEL.position.x + 4, 152), Color(0.93, 0.91, 0.87), 8)
	_who.size = Vector2(PANEL.size.x - 8, 22)
	_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_new_shot()


func _label(pos: Vector2, color: Color, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(PANEL.size.x, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(l)
	return l


func _zone_x(z: int) -> float:
	return GOAL.position.x + GOAL.size.x * (0.17 + z * 0.33)


func _line_y() -> float:
	return GOAL.end.y - 6.0


func _new_shot() -> void:
	_role = "arco" if (_i + _start) % 2 == 0 else "patea"
	_t = 0.0
	_dive = -1
	_stopped = false
	_over = false
	_tell_on = false
	_ball = SPOT
	_ball_h = 0.0
	_big.text = ""
	var s: Array = _shots[_i % _shots.size()]
	for sp in [_him, _kid]:
		sp.rotation = 0.0
		sp.flip_h = false
	if _role == "arco":
		_state = "runup"
		_aim = randi() % 3
		_tell = _aim if randf() < TRUTH else [0, 1, 2].filter(func(z): return z != _aim).pick_random()
		_him.position = Vector2(_zone_x(1), _line_y())
		_him.play("idle_down")
		_kid.position = SPOT + Vector2(32, 2)
		_kid.flip_h = true
		_kid.play("walk_side")
		_who.text = "%s: %s" % [s[0], s[1]]
	else:
		_state = "aim"
		_kid.position = Vector2(_zone_x(1), _line_y() + 5.0)
		_kid.play("idle_down")
		_him.position = SPOT + Vector2(14, 12)
		_him.play("idle_up")
		_who.text = Controls.keys_in("Patea él. E: clavar la mira. E otra vez: la fuerza.")
	_refresh_score()


func _refresh_score() -> void:
	_score.text = "EL %d - %d PELADOS    %d/%d" % [_mine, _theirs, mini(_i + 1, ROUNDS), ROUNDS]


func _process(delta: float) -> void:
	_guard -= delta
	_t += delta
	_net = maxf(0.0, _net - delta)
	_cheer = maxf(0.0, _cheer - delta)
	for b in _bits:
		b["v"] += Vector2(0, 90.0) * delta
		b["p"] += b["v"] * delta
		b["life"] -= delta
	_bits = _bits.filter(func(b): return b["life"] > 0.0)
	match _state:
		"runup":
			_kid.position.x = lerpf(SPOT.x + 32, SPOT.x + 7, minf(1.0, _t / RUNUP)) + ((_tell - 1) * 4.0 if _tell_on else 0.0)
			if _t >= TELL_AT:
				_tell_on = true  # se le va el cuerpo
			if _t >= RUNUP:
				_kid.play("idle_side")
				_shoot(Vector2(_zone_x(_aim), GOAL.position.y + 18.0 + (6.0 if _aim == 1 else 0.0)))
		"aim":
			_aim_x = GOAL.get_center().x + sin(_t * 2.7) * 60.0
		"power":
			_power = absf(sin(_t * 3.4))
		"kickrun":
			_him.position = (SPOT + Vector2(14, 12)).lerp(SPOT + Vector2(5, 6), minf(1.0, _t / 0.3))
			if _t >= 0.3:
				_him.play("idle_up")
				_kid_dives()
				_shoot(Vector2(_aim_x, lerpf(GOAL.end.y - 6.0, GOAL.position.y - 14.0, _power)))
		"fly":
			var k := minf(1.0, _t / FLY)
			_ball_h = sin(k * PI) * 10.0 + k * (SPOT.y - _to.y) * 0.25
			_ball = _from.lerp(_to, k) - Vector2(0, sin(k * PI) * 9.0)
			if k >= 1.0:
				_resolve()
		"show":
			if not _stopped:  # la pelota sigue: a la red, o a la casa de doña Rosa
				_ball += (_to - _from).normalized() * (160.0 if _over else 40.0) * delta
				if not _over and _ball.y < GOAL.position.y + 6.0:
					_stopped = true
			if _t > 1.5:
				_i += 1
				if _i >= ROUNDS:
					_close()
				else:
					_new_shot()
	_field.queue_redraw()
	get_node("Encima").queue_redraw()


func _shoot(to: Vector2) -> void:
	_state = "fly"
	_t = 0.0
	_from = SPOT
	_to = to


## El pelado que tapa: la mitad de las veces adivina.
func _kid_dives() -> void:
	var zone := clampi(int((_aim_x - GOAL.position.x) / (GOAL.size.x / 3.0)), 0, 2)
	_dive = zone if randf() < 0.5 else randi() % 3
	_lay(_kid, _dive, _line_y() + 5.0)


## Tirarse: al medio, un saltico; a los lados, acostado.
func _lay(sp: AnimatedSprite2D, z: int, y: float) -> void:
	var t := create_tween().set_parallel()
	if z == 1:
		t.tween_property(sp, "position:y", y - 5.0, 0.12)
		t.chain().tween_property(sp, "position:y", y, 0.15)
	else:
		t.tween_property(sp, "position", Vector2(_zone_x(z) + (z - 1) * 6.0, y - 4.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(sp, "rotation", (z - 1) * 1.2, 0.2)


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0 or _state in ["show", "closed", "kickrun"]:
		return
	if _role == "patea":
		if not (event.is_action_pressed("interact") or event.is_action_pressed("move_up")):
			return
		get_viewport().set_input_as_handled()
		if _state == "aim":
			_state = "power"
			_t = 0.0
		elif _state == "power":
			_state = "kickrun"
			_t = 0.0
			_him.play("walk_up")
		return
	if _dive != -1:
		return
	var z := -1
	if event.is_action_pressed("move_left"):
		z = 0
	elif event.is_action_pressed("move_up") or event.is_action_pressed("interact"):
		z = 1
	elif event.is_action_pressed("move_right"):
		z = 2
	if z == -1:
		return
	get_viewport().set_input_as_handled()
	_dive = z
	_lay(_him, z, _line_y())


func _resolve() -> void:
	_state = "show"
	_t = 0.0
	if _role == "arco":
		if _dive == _aim:
			_saves += 1
			_stopped = true
			_big.text = "¡ATAJADA!"
			_who.text = SAVE_LINES.pick_random()
			_party(_him.position, Color(1.0, 0.9, 0.5))
		else:
			_theirs += 1
			_net = 0.5
			_big.text = "GOL"
			_who.text = "Ni se movió. Llegó tarde." if _dive == -1 else CONCEDE_LINES.pick_random()
			_cheer = 1.4
	else:
		var on_frame: bool = _to.x > GOAL.position.x + 3.0 and _to.x < GOAL.end.x - 3.0 and _to.y > GOAL.position.y + 2.0
		var zone := clampi(int((_to.x - GOAL.position.x) / (GOAL.size.x / 3.0)), 0, 2)
		var top: bool = _to.y < GOAL.position.y + 13.0
		if not on_frame:
			_over = true
			_big.text = "AFUERA"
			_who.text = OVER_LINES.pick_random()
			_cheer = 1.0
		elif _dive == zone and not (top and zone != 1):
			_stopped = true
			_big.text = "TAPADA"
			_who.text = MISS_LINES.pick_random()
			_cheer = 1.4
		else:
			_mine += 1
			_net = 0.5
			_big.text = "¡GOOOL!"
			_who.text = SCORE_LINES.pick_random()
			_party(_to, Color(0.6, 1.0, 0.6))
	_refresh_score()


func _party(at: Vector2, tint: Color) -> void:
	for k in 26:
		_bits.append({"p": at, "v": Vector2(randf_range(-70, 70), randf_range(-120, -30)),
			"c": [tint, Color(1, 0.4, 0.4), Color(0.5, 0.7, 1.0), Color.WHITE].pick_random(), "life": randf_range(0.6, 1.3)})


func _close() -> void:
	if _state == "closed":
		return
	_state = "closed"
	GameState.ui_open = false
	GameState.block_input(0.2)
	_done.emit([_saves, _mine, _theirs])


# ---------------------------------------------------------------- Dibujar

func _draw_field() -> void:
	var f := _field
	var p := PANEL
	f.draw_rect(p, Color(0.13, 0.22, 0.13))
	for k in 6:  # el pasto, a franjas (lo que queda de pasto)
		if k % 2 == 0:
			f.draw_rect(Rect2(p.position.x, 52 + k * 21, p.size.x, 21), Color(0.15, 0.25, 0.14))
	for k in 9:  # los peladeros
		var h := hash(k * 7)
		f.draw_rect(Rect2(p.position.x + 10 + h % 230, 104 + (h / 7) % 40, 9 + h % 6, 3), Color(0.3, 0.26, 0.17, 0.7))
	# El muro del fondo, con su letrero.
	f.draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 18), Color(0.3, 0.2, 0.18))
	for k in 13:
		f.draw_rect(Rect2(p.position.x + k * 20, p.position.y + (9 if k % 2 == 0 else 0), 1, 9), Color(0.2, 0.13, 0.12))
	f.draw_rect(Rect2(p.position.x, p.position.y + 9, p.size.x, 1), Color(0.2, 0.13, 0.12))
	# La cal (media caneca): el área y el punto.
	var chalk := Color(0.85, 0.85, 0.8, 0.45)
	f.draw_rect(Rect2(86, GOAL.end.y, 148, 1), chalk)
	f.draw_rect(Rect2(86, GOAL.end.y, 1, 46), chalk)
	f.draw_rect(Rect2(233, GOAL.end.y, 1, 46), chalk)
	f.draw_rect(Rect2(86, GOAL.end.y + 46, 148, 1), chalk)
	f.draw_circle(SPOT + Vector2(0, 3), 1.5, chalk)
	# El arco: la red (prestada de una cancha de verdad), dos palos y los dos morrales de siempre.
	var shake := sin(_net * 40.0) * _net * 4.0
	for k in 13:
		var x := GOAL.position.x + k * 8.0
		f.draw_line(Vector2(x, GOAL.position.y), Vector2(x + shake, GOAL.end.y - 2), Color(0.9, 0.9, 0.9, 0.22))
	for k in 5:
		var y := GOAL.position.y + k * 8.0
		f.draw_line(Vector2(GOAL.position.x, y), Vector2(GOAL.end.x, y - shake * 0.5), Color(0.9, 0.9, 0.9, 0.22))
	var post := Color(0.9, 0.88, 0.8)
	f.draw_rect(Rect2(GOAL.position.x - 3, GOAL.position.y - 3, GOAL.size.x + 6, 3), post)
	f.draw_rect(Rect2(GOAL.position.x - 3, GOAL.position.y, 3, GOAL.size.y), post)
	f.draw_rect(Rect2(GOAL.end.x, GOAL.position.y, 3, GOAL.size.y), post)
	f.draw_rect(Rect2(GOAL.position.x - 10, GOAL.end.y - 8, 9, 8), Color(0.75, 0.25, 0.25))
	f.draw_rect(Rect2(GOAL.end.x + 2, GOAL.end.y - 8, 9, 8), Color(0.25, 0.4, 0.75))
	# La barra: dos pelados y, si está, Lukas. Saltan cuando hay con qué.
	var hop := absf(sin(_cheer * 14.0)) * 5.0 if _cheer > 0.0 else 0.0
	for k in 2:
		var at := Vector2(250 + k * 14, 124 + k * 6 - (hop if k == 0 else hop * 0.6))
		f.draw_rect(Rect2(at.x - 3, at.y - 9, 6, 9), [Color(0.9, 0.75, 0.25), Color(0.5, 0.3, 0.7)][k])
		f.draw_circle(at + Vector2(0, -12), 3.0, Color(0.8, 0.6, 0.45))
		if _cheer > 0.0:  # los brazos arriba
			f.draw_line(at + Vector2(-3, -8), at + Vector2(-6, -15), Color(0.8, 0.6, 0.45))
			f.draw_line(at + Vector2(3, -8), at + Vector2(6, -15), Color(0.8, 0.6, 0.45))
	if GameState.lukas_alive():
		var wag := 1.0 if fmod(_t * 6.0, 1.0) < 0.5 else 0.0
		f.draw_texture(Lukas.cell(3, 0), Vector2(52 + wag, 116 - (2.0 if _state == "fly" else 0.0)))
	# A dónde se le fue el cuerpo.
	if _role == "arco" and _tell_on and _state == "runup":
		var a := _kid.position + Vector2((_tell - 1) * 12.0, -14.0)
		var gold := Color(1, 0.85, 0.3)
		if _tell == 1:
			f.draw_colored_polygon(PackedVector2Array([a + Vector2(-4, 2), a + Vector2(4, 2), a + Vector2(0, -5)]), gold)
		else:
			var d := float(_tell - 1)
			f.draw_colored_polygon(PackedVector2Array([a + Vector2(-3 * d, -4), a + Vector2(-3 * d, 4), a + Vector2(5 * d, 0)]), gold)
	if _role == "patea":
		if _state in ["aim", "power"]:  # la mira
			var c := Vector2(_aim_x, lerpf(GOAL.end.y - 6.0, GOAL.position.y - 14.0, _power) if _state == "power" else GOAL.get_center().y)
			f.draw_arc(c, 5.0, 0.0, TAU, 12, Color(1, 0.3, 0.3))
			f.draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(1, 0.3, 0.3))
			f.draw_line(c + Vector2(0, -8), c + Vector2(0, 8), Color(1, 0.3, 0.3))
		if _state in ["power", "kickrun"]:  # la fuerza: arriba de la raya, se va
			var bar := Rect2(44, 66, 6, 60)
			f.draw_rect(bar.grow(1), Color(0.05, 0.05, 0.05))
			f.draw_rect(Rect2(bar.position.x, bar.position.y, 6, 21), Color(0.75, 0.2, 0.2))
			f.draw_rect(Rect2(bar.position.x, bar.position.y + 21, 6, 14), Color(0.3, 0.8, 0.35))
			f.draw_rect(Rect2(bar.position.x, bar.position.y + 35, 6, 25), Color(0.85, 0.75, 0.3))
			f.draw_rect(Rect2(bar.position.x - 3, bar.end.y - _power * 60.0 - 1, 12, 2), Color.WHITE)


func _draw_over(n: Node2D) -> void:
	# La pelota (pelada), con su sombra.
	var far := clampf((SPOT.y - _ball.y) / (SPOT.y - GOAL.position.y), 0.0, 1.2)
	n.draw_circle(_ball + Vector2(0, 3.0 + _ball_h), 2.5, Color(0, 0, 0, 0.3))
	var r := lerpf(3.2, 2.2, minf(1.0, far))
	n.draw_circle(_ball, r, Color(0.95, 0.95, 0.92))
	n.draw_circle(_ball + Vector2(cos(_t * 20.0), sin(_t * 20.0)) * (r - 1.2), 0.9, Color(0.25, 0.25, 0.25))
	for b in _bits:
		n.draw_rect(Rect2(b["p"], Vector2(2, 2)), b["c"])
