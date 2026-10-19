class_name Penal
extends CanvasLayer
## Penaltis con los pelados del lote: una tanda de seis, por turnos. Unas veces tapa él, otras patea.
##   TAPAR: el que patea toma carrera y, justo antes, se le va el cuerpo para un lado (casi siempre es
##     para donde patea; a veces engaña). Tirarse a tiempo: izquierda, arriba (el medio) o derecha.
##   PATEAR: la mira va y viene sola por el arco: [E] la clava. Después sube y baja la fuerza: [E] otra
##     vez. Poquita, sale rastrera (fácil de tapar); mucha, se va por encima, a la casa de doña Rosa.
##     Arriba y a un lado, no la tapa nadie. Con las flechas mientras sube la fuerza, le pega con efecto: sale
##     para un lado y se tuerce al otro (el arquero se tira para donde parece que va), pero va menos
##     precisa.
##   LA PELOTA: va por una curva (el efecto), pega en los palos y en el travesaño (y a veces entra),
##     rebota en las manos del que ataja y se queda en la red, que se infla.
##   LA BARRA: cada gol y cada atajada la llenan (FULL). Llena, con [F]:
##     pateando, EL SUPERTIRO: un cañonazo de fuego que va adentro sí o sí (si el arquero adivina, se
##       mete al arco con pelota y todo);
##     tapando, LA SUPERATAJADA: todo en cámara lenta, el cuerpo del pelado dice la verdad y él se
##       estira hasta la zona de al lado.
##     Los pelados también tienen barra: llena, tiran LA HOJA SECA (sube por encima del travesaño y cae
##     en el ángulo, con el cuerpo diciendo mentiras).
##   var res: Array = await Penal.play(self, [[nombre, frase], ...])   # [atajadas, goles de él, goles de ellos]
## Todo dibujado por código (_Cancha): el lote, el arco de morrales, la barra, Lukas, el papel picado.
## Los sonidos: tools/audio/futbol_audio.py (y la barra llena, el del tenis).

signal _done(result: Array)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const PANEL := Rect2(34, 34, 252, 144)  # debajo de la barra de arriba; a la izquierda de los botones
const GOAL := Rect2(112, 62, 96, 38)
const SPOT := Vector2(160, 134)  # el punto penal
const RUNUP := 1.1  # la carrera; a los 0.6 se le va el cuerpo
const TELL_AT := 0.6
const FLY := 0.5  # lo que tarda la pelota en llegar (con poquita fuerza; con mucha, menos)
const TRUTH := 0.72  # qué tanto el cuerpo dice la verdad
const ROUNDS := 6
const CURVE := 26.0  # cuánto se tuerce con efecto (px)
const FULL := 2      # la barra del supertiro: goles y atajadas
const SAVE_LINES := ["Con la panza. Cuenta igual.", "Con la punta de los dedos.", "Le pega en la cara y sale. Cuenta."]
const CONCEDE_LINES := ["Por el otro lado.", "Lo engañó con el cuerpo.", "Lo celebran como un Mundial."]
const SCORE_LINES := ["El arquero todavía la está buscando.", "Al ángulo. Donde duermen las arañas.", "Los pelados piden revisión. No hay."]
const MISS_LINES := ["Se la tapó un niño de nueve años.", "El arquero ni se despeinó.", "Ahí estaba el pelado. Siempre está."]
const OVER_LINES := ["Por encima. A la casa de doña Rosa.", "Afuera. La pelota conoce el barrio.", "Esa todavía va subiendo."]
const POST_LINES := ["El palo. El palo siempre juega para ellos.", "Sonó como una campana. La de la iglesia contestó.", "El palo tembló. Doña Rosa salió a mirar."]
const POST_IN_LINES := ["Pegó en el palo y entró. Así también cuenta.", "Palo y adentro. Con susto, pero adentro."]
const SFX := {"patada": ["futbol", -4.0], "palo": ["futbol", -5.0], "atajada": ["futbol", -4.0], "red": ["futbol", -7.0],
	"fuego": ["futbol", -3.0], "carga": ["tenis", -9.0], "super": ["tenis", -5.0]}

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
var _curve := 0.0    # el efecto: sale hacia -curve y se tuerce hasta el punto
var _from := SPOT
var _ctrl := SPOT    # por donde "parece" que va (la curva pasa cerca)
var _to := SPOT
var _fly_t := FLY
var _arc := 9.0      # cuánto sube en el camino
var _ball := SPOT
var _ball_h := 0.0   # qué tan alto va (para la sombra)
var _bv := Vector2.ZERO  # después de llegar: el rebote, o hacia la red
var _stopped := false
var _over := false
var _net := 0.0      # la red se sacude
var _pocket := Vector2.ZERO  # donde la pelota infla la red (con _net)
var _post := 0.0     # el palo tiembla
var _cheer := 0.0    # la barra salta
var _tell_on := false
var _bits: Array = []  # el papel picado
var _bar := [0, 0]   # la barra del supertiro: [él, los pelados]
var _super := ""     # "" / "tiro" (él patea) / "atajada" (él tapa) / "hoja" (los pelados)
var _slow := 1.0     # la cámara lenta de la superatajada
var _flash := 0.0
var _shake := 0.0
var _fire: Array = []  # la estela del supertiro (y de la hoja seca)
var _sfx := {}
var _field: Node2D
var _him: AnimatedSprite2D
var _kid: AnimatedSprite2D
var _score: Label
var _big: Label
var _who: Label
var _hint: Label


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
	Controls.minigame = true   # en el celular: los botones del minijuego (con la huella)
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
	_hint = _label(Vector2(PANEL.position.x, 49), Color(1.0, 0.75, 0.3), 8)
	_big = _label(Vector2(PANEL.position.x, 104), Color(1, 0.95, 0.6), 16)
	_big.size.y = 18
	_who = _label(Vector2(PANEL.position.x + 4, 152), Color(0.93, 0.91, 0.87), 8)
	_who.size = Vector2(PANEL.size.x - 8, 22)
	_who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for n in SFX:
		var a := AudioStreamPlayer.new()
		a.stream = load("res://assets/audio/%s/%s.wav" % [SFX[n][0], n])
		a.volume_db = SFX[n][1]
		a.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(a)
		_sfx[n] = a
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


func _sound(n: String, pitch := 1.0) -> void:
	var a: AudioStreamPlayer = _sfx.get(n)
	if a != null:
		a.pitch_scale = pitch
		a.play()


func _zone_x(z: int) -> float:
	return GOAL.position.x + GOAL.size.x * (0.17 + z * 0.33)


func _zone_of(x: float) -> int:
	return clampi(int((x - GOAL.position.x) / (GOAL.size.x / 3.0)), 0, 2)


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
	_bv = Vector2.ZERO
	_curve = 0.0
	_super = ""
	_slow = 1.0
	_fire.clear()
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
		if _bar[1] >= FULL:  # los pelados, con la barra llena: la hoja seca (al ángulo, y el cuerpo miente)
			_bar[1] = 0
			_super = "hoja"
			_aim = [0, 2].pick_random()
			_tell = 2 - _aim
			_big.text = "¡LA HOJA SECA!"
			_who.text = "%s: ¡La hoja seca! Como en el Mundial del 62." % s[0]
			_sound("carga", 0.8)
	else:
		_state = "aim"
		_kid.position = Vector2(_zone_x(1), _line_y() + 5.0)
		_kid.play("idle_down")
		_him.position = SPOT + Vector2(14, 12)
		_him.play("idle_up")
		_who.text = Controls.keys_in("Patea él. E: la mira. E: la fuerza; con las flechas, efecto.")
	_refresh_score()


func _refresh_score() -> void:
	_score.text = "EL %d - %d PELADOS    %d/%d" % [_mine, _theirs, mini(_i + 1, ROUNDS), ROUNDS]


func _process(delta: float) -> void:
	var dt := delta * _slow   # (la superatajada: todo despacio)
	_guard -= delta
	_t += dt
	_net = maxf(0.0, _net - delta)
	_post = maxf(0.0, _post - delta)
	_cheer = maxf(0.0, _cheer - delta)
	_flash = maxf(0.0, _flash - delta)
	_shake = maxf(0.0, _shake - delta)
	offset = Vector2(randi_range(-1, 1), randi_range(-1, 1)) if _shake > 0.0 else Vector2.ZERO
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
				if _super == "hoja":  # arriba, al ángulo; sale hacia donde dijo el cuerpo y se tuerce
					_shoot(Vector2(_zone_x(_aim), GOAL.position.y + 7.0), (_aim - 1) * CURVE * 0.8, 0.62, 28.0)
				else:
					_shoot(Vector2(_zone_x(_aim), GOAL.position.y + 18.0 + (6.0 if _aim == 1 else 0.0)), 0.0, FLY, 9.0)
		"aim":
			_aim_x = GOAL.get_center().x + sin(_t * 2.7) * 60.0
		"power":
			_power = absf(sin(_t * 3.4))
			_curve = (CURVE if Input.is_action_pressed("move_right") else 0.0) - (CURVE if Input.is_action_pressed("move_left") else 0.0)
		"kickrun":
			_him.position = (SPOT + Vector2(14, 12)).lerp(SPOT + Vector2(5, 6), minf(1.0, _t / 0.3))
			if _t >= 0.3:
				_him.play("idle_up")
				_kick()
		"fly":
			var k := minf(1.0, _t / _fly_t)
			var u := 1.0 - k
			var p := u * u * _from + 2.0 * u * k * _ctrl + k * k * _to   # la curva (el efecto)
			var lift := sin(pow(k, 0.75) * PI) * _arc if _super == "hoja" else sin(k * PI) * _arc
			_ball_h = lift + k * (SPOT.y - _to.y) * 0.25
			_ball = p - Vector2(0, lift)
			if _super in ["tiro", "hoja"]:
				_fire.push_front(_ball)
				if _fire.size() > 9:
					_fire.pop_back()
			if k >= 1.0:
				_arrive()
		"show":
			if not _fire.is_empty():  # la estela se apaga
				_fire.pop_back()
			if _over:  # a la casa de doña Rosa
				_ball += (_to - _from).normalized() * 160.0 * delta
			elif not _stopped:
				_ball += _bv * delta
				_bv *= pow(0.08, delta)          # el pasto la frena
				if _bv.length() < 4.0:
					_stopped = true
			if _t > 1.6:
				_i += 1
				if _i >= ROUNDS:
					_close()
				else:
					_new_shot()
	_update_hint()
	_field.queue_redraw()
	get_node("Encima").queue_redraw()


## Él le pega (después de la carrera): con la mira, la fuerza y el efecto. El supertiro va adentro sí o sí.
func _kick() -> void:
	var to := Vector2(_aim_x, lerpf(GOAL.end.y - 6.0, GOAL.position.y - 14.0, _power))
	var fly := lerpf(0.55, 0.38, _power)
	if _curve != 0.0:  # con efecto: menos precisa
		to.x += randf_range(-7.0, 7.0)
	if _super == "tiro":
		to = Vector2(clampf(to.x, GOAL.position.x + 6.0, GOAL.end.x - 6.0), clampf(to.y, GOAL.position.y + 6.0, GOAL.end.y - 6.0))
		fly = 0.26
		_flash = 0.12
		_shake = 0.3
		_sound("fuego")
	_kid_dives(to)
	_shoot(to, _curve, fly, 4.0 if _super == "tiro" else 9.0)


func _shoot(to: Vector2, curve: float, fly: float, arc: float) -> void:
	_state = "fly"
	_t = 0.0
	_from = SPOT
	_to = to
	_ctrl = (SPOT + to) * 0.5 + Vector2(-curve, 0)   # sale hacia un lado y se tuerce al otro
	_fly_t = fly
	_arc = arc
	_sound("patada", randf_range(0.92, 1.08))


## El pelado que tapa: la mitad de las veces adivina... para donde parece que va (el efecto lo engaña).
func _kid_dives(to: Vector2) -> void:
	var seems := _zone_of(to.x - 2.0 * _curve)
	_dive = seems if randf() < 0.55 else randi() % 3
	_lay(_kid, _dive, _line_y() + 5.0)


## Tirarse: al medio, un saltico; a los lados, acostado.
func _lay(sp: AnimatedSprite2D, z: int, y: float) -> void:
	var t := create_tween().set_parallel()
	t.set_speed_scale(_slow)
	if z == 1:
		t.tween_property(sp, "position:y", y - 5.0, 0.12)
		t.chain().tween_property(sp, "position:y", y, 0.15)
	else:
		t.tween_property(sp, "position", Vector2(_zone_x(z) + (z - 1) * 6.0, y - 4.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(sp, "rotation", (z - 1) * 1.2, 0.2)


func _unhandled_input(event: InputEvent) -> void:
	if _guard > 0.0 or _state in ["show", "closed", "kickrun"]:
		return
	if event.is_action_pressed("sniff"):
		if _use_super():
			get_viewport().set_input_as_handled()
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


## [F] con la barra llena: pateando, el supertiro; tapando (antes de tirarse), la superatajada.
func _use_super() -> bool:
	if _bar[0] < FULL or _super == "tiro" or _super == "atajada":
		return false
	if _role == "patea" and _state in ["aim", "power"]:
		_super = "tiro"
		_big.text = "¡SUPERTIRO!"
	elif _role == "arco" and _state in ["runup", "fly"] and _dive == -1:
		_super = "atajada"
		_slow = 0.4
		_tell = _aim          # el cuerpo ya no miente
		_tell_on = true
		_big.text = "¡SUPERATAJADA!"
	else:
		return false
	_bar[0] = 0
	_flash = 0.1
	_sound("super")
	return true


func _update_hint() -> void:
	var can: bool = _bar[0] >= FULL and _super != "tiro" and _super != "atajada"
	if can and _role == "patea" and _state in ["aim", "power"]:
		_hint.text = Controls.keys_in("F: ¡SUPERTIRO!")
	elif can and _role == "arco" and _state in ["runup", "fly"] and _dive == -1:
		_hint.text = Controls.keys_in("F: ¡SUPERATAJADA!")
	else:
		_hint.text = ""


## La pelota llegó al arco: el palo, afuera, atajada (con rebote) o gol (a la red).
func _arrive() -> void:
	_state = "show"
	_t = 0.0
	_slow = 1.0
	var x := _to.x
	var y := _to.y
	var gl := GOAL.position.x
	var gr := GOAL.end.x
	var top := GOAL.position.y
	var zone := _zone_of(x)
	var post := (absf(x - gl) < 3.0 or absf(x - gr) < 3.0) and y > top - 3.0
	var crossbar := absf(y - top) < 3.0 and x > gl - 3.0 and x < gr + 3.0
	var inside := x > gl and x < gr and y > top
	if _super == "tiro":
		post = false
		crossbar = false
		inside = true
	if post or crossbar:
		_post = 0.7
		_sound("palo", randf_range(0.95, 1.05))
		if randf() < 0.45 and inside:  # pegó y entró
			_goal(POST_IN_LINES.pick_random(), "¡PALO Y ADENTRO!")
		else:  # pegó y salió: rebota para la cancha
			_bv = Vector2(signf(x - GOAL.get_center().x) * 45.0, 85.0) if post else Vector2(randf_range(-30, 30), 95.0)
			_big.text = "¡PALO!"
			_who.text = POST_LINES.pick_random()
			_cheer = 1.0
		_refresh_score()
		return
	if not inside:
		_over = true
		_big.text = "AFUERA"
		_who.text = OVER_LINES.pick_random()
		_cheer = 1.0
		_refresh_score()
		return
	var high := y < top + 13.0
	var saved := false
	if _role == "arco":
		saved = _dive != -1 and (_dive == zone or (_super == "atajada" and absi(_dive - zone) <= 1))
	else:
		saved = _super != "tiro" and _dive == zone and not (high and zone != 1)
	if saved:
		_stopped = false
		_bv = Vector2((zone - 1) * 50.0 + randf_range(-25, 25), 90.0)  # rebota en las manos
		_sound("atajada", randf_range(0.95, 1.05))
		if _role == "arco":
			_saves += 1
			_fill(0)
			_big.text = "¡SUPERATAJADA!" if _super == "atajada" else "¡ATAJADA!"
			_who.text = SAVE_LINES.pick_random()
			_party(_him.position, Color(1.0, 0.9, 0.5))
		else:
			_fill(1)
			_big.text = "TAPADA"
			_who.text = MISS_LINES.pick_random()
			_cheer = 1.4
		_refresh_score()
		return
	var line := ""
	if _role == "arco":
		line = "Ni se movió. Llegó tarde." if _dive == -1 else CONCEDE_LINES.pick_random()
		if _super == "hoja":
			line = "Subió, lo pensó y bajó al ángulo."
	elif _super == "tiro":
		line = SCORE_LINES.pick_random()
		if _dive == zone:  # adivinó... y se lo llevó la pelota
			line = "Se metió al arco con pelota y todo."
			var t := create_tween()
			t.tween_property(_kid, "position", Vector2(x, top + 6.0), 0.18)
	else:
		line = SCORE_LINES.pick_random()
	_goal(line, "¡GOOOL!" if _role == "patea" else "GOL")


func _goal(line: String, big: String) -> void:
	_stopped = false
	_bv = (_to - _ctrl).normalized() * 40.0   # sigue hasta la red
	_pocket = _to
	_net = 0.6
	_sound("red")
	_big.text = big
	_who.text = line
	if _role == "patea":
		_mine += 1
		_fill(0)
		_party(_to, Color(0.6, 1.0, 0.6))
	else:
		_theirs += 1
		_fill(1)
		_cheer = 1.4
	_refresh_score()


## La barra del supertiro (0: él, 1: los pelados). La de él, al llenarse, suena.
func _fill(who: int) -> void:
	if _bar[who] >= FULL:
		return
	_bar[who] += 1
	if who == 0 and _bar[0] >= FULL:
		_sound("carga")


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

func _exit_tree() -> void:
	Controls.minigame = false


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
	# El arco: la red (prestada de una cancha de verdad), dos palos y los dos morrales de siempre. Con
	# gol, la red se sacude y se infla donde entró la pelota.
	var shake := sin(_net * 40.0) * _net * 4.0
	var pull := _net / 0.6
	for k in 13:
		var x := GOAL.position.x + k * 8.0
		var dx := (x - _pocket.x) / 14.0
		var bag := exp(-dx * dx) * 3.0 * pull
		f.draw_line(Vector2(x, GOAL.position.y), Vector2(x + shake, GOAL.end.y - 2 - bag), Color(0.9, 0.9, 0.9, 0.22))
	for k in 5:
		var y := GOAL.position.y + k * 8.0
		f.draw_line(Vector2(GOAL.position.x, y), Vector2(GOAL.end.x, y - shake * 0.5), Color(0.9, 0.9, 0.9, 0.22))
	if pull > 0.0:  # la bolsa de la red, detrás de la pelota
		f.draw_circle(_pocket + Vector2(0, -2), 5.0 * pull, Color(0.05, 0.08, 0.05, 0.35 * pull))
	var post := Color(0.9, 0.88, 0.8)
	var buzz := Vector2(sin(_t * 70.0) * _post * 1.5, 0).round()   # el palo, temblando
	f.draw_rect(Rect2(GOAL.position + Vector2(-3, -3) + buzz, Vector2(GOAL.size.x + 6, 3)), post)
	f.draw_rect(Rect2(GOAL.position + Vector2(-3, 0) + buzz, Vector2(3, GOAL.size.y)), post)
	f.draw_rect(Rect2(Vector2(GOAL.end.x, GOAL.position.y) + buzz, Vector2(3, GOAL.size.y)), post)
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
	# Las barras del supertiro: la de él (dorada, a la izquierda) y la de los pelados (morada, a la
	# derecha). Llenas, titilan.
	for who in 2:
		var x0 := 40.0 if who == 0 else 258.0
		var col := Color(1.0, 0.78, 0.25) if who == 0 else Color(0.62, 0.42, 0.85)
		var lit: bool = _bar[who] >= FULL and fmod(_t * 4.0, 1.0) < 0.5
		for k in FULL:
			var r := Rect2(x0 + k * 12.0, 50, 10, 4)
			f.draw_rect(r.grow(1), Color(0.05, 0.05, 0.05))
			if k < _bar[who]:
				f.draw_rect(r, col.lightened(0.4) if lit else col)
	# A dónde se le fue el cuerpo (en la superatajada, grande y brillando: ya no miente).
	if _role == "arco" and _tell_on and _state in ["runup", "fly"]:
		var big := 1.6 if _super == "atajada" else 1.0
		var a := _kid.position + Vector2((_tell - 1) * 12.0, -14.0)
		var gold := Color(1, 0.85, 0.3) if _super != "atajada" else Color(0.6, 1.0, 1.0)
		if _tell == 1:
			f.draw_colored_polygon(PackedVector2Array([a + Vector2(-4, 2) * big, a + Vector2(4, 2) * big, a + Vector2(0, -5) * big]), gold)
		else:
			var d := float(_tell - 1)
			f.draw_colored_polygon(PackedVector2Array([a + Vector2(-3 * d, -4) * big, a + Vector2(-3 * d, 4) * big, a + Vector2(5 * d, 0) * big]), gold)
	if _role == "patea":
		if _state in ["aim", "power"]:  # la mira (y, con efecto, por dónde va a ir)
			var c := Vector2(_aim_x, lerpf(GOAL.end.y - 6.0, GOAL.position.y - 14.0, _power) if _state == "power" else GOAL.get_center().y)
			f.draw_arc(c, 5.0, 0.0, TAU, 12, Color(1, 0.3, 0.3))
			f.draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(1, 0.3, 0.3))
			f.draw_line(c + Vector2(0, -8), c + Vector2(0, 8), Color(1, 0.3, 0.3))
			if _curve != 0.0:
				var ctrl := (SPOT + c) * 0.5 + Vector2(-_curve, 0)
				for k in range(1, 10):
					var u := k / 10.0
					var q: Vector2 = (1 - u) * (1 - u) * SPOT + 2 * (1 - u) * u * ctrl + u * u * c
					f.draw_rect(Rect2(q.round(), Vector2(1, 1)), Color(1, 0.6, 0.4, 0.8))
		if _state in ["power", "kickrun"]:  # la fuerza: arriba de la raya, se va
			var bar := Rect2(44, 66, 6, 60)
			f.draw_rect(bar.grow(1), Color(0.05, 0.05, 0.05))
			f.draw_rect(Rect2(bar.position.x, bar.position.y, 6, 21), Color(0.75, 0.2, 0.2))
			f.draw_rect(Rect2(bar.position.x, bar.position.y + 21, 6, 14), Color(0.3, 0.8, 0.35))
			f.draw_rect(Rect2(bar.position.x, bar.position.y + 35, 6, 25), Color(0.85, 0.75, 0.3))
			f.draw_rect(Rect2(bar.position.x - 3, bar.end.y - _power * 60.0 - 1, 12, 2), Color.WHITE)


func _draw_over(n: Node2D) -> void:
	# La estela: el fuego del supertiro, las hojas de la hoja seca.
	var m := _fire.size()
	for k in range(m - 1, 0, -1):
		var u := float(k) / m
		var col := Color(1.0, 0.75, 0.2).lerp(Color(0.9, 0.15, 0.1), u) if _super == "tiro" else Color(0.55, 0.85, 0.35).lerp(Color(0.2, 0.5, 0.2), u)
		n.draw_circle(_fire[k], 3.2 * (1.0 - u) + 0.6, Color(col, 0.85 * (1.0 - u)))
	if _super == "tiro" and _state in ["aim", "power", "kickrun"]:  # la pelota ya echando chispas en el punto
		for k in 5:
			var a := _t * 9.0 + k * TAU / 5.0
			n.draw_circle(SPOT + Vector2(cos(a) * 4.0, -absf(sin(a * 1.3)) * 5.0 - 2.0), 1.2, Color(1.0, 0.6 + 0.3 * sin(a), 0.2, 0.85))
	# La pelota (pelada), con su sombra.
	var far := clampf((SPOT.y - _ball.y) / (SPOT.y - GOAL.position.y), 0.0, 1.2)
	n.draw_circle(_ball + Vector2(0, 3.0 + _ball_h), 2.5, Color(0, 0, 0, 0.3))
	var r := lerpf(3.2, 2.2, minf(1.0, far))
	if _super == "tiro" and _state == "fly":
		n.draw_circle(_ball, r + 2.5, Color(1.0, 0.55, 0.15, 0.45))
	n.draw_circle(_ball, r, Color(0.95, 0.95, 0.92))
	n.draw_circle(_ball + Vector2(cos(_t * 20.0), sin(_t * 20.0)) * (r - 1.2), 0.9, Color(0.25, 0.25, 0.25))
	for b in _bits:
		n.draw_rect(Rect2(b["p"], Vector2(2, 2)), b["c"])
	if _flash > 0.0:
		n.draw_rect(PANEL, Color(1, 1, 0.95, 0.5 * _flash / 0.12))
