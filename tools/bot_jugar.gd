extends SceneTree
## Juega cada escena con una política tonta y anota qué pasa (prueba de jugabilidad).
##   idle: no hace nada (solo pasa los diálogos).
##   mash: machaca la acción, cambia de dirección al azar, a veces suelta/olfatea.
##   ritmo (beat 'em up): se alinea con el matón más cercano, pega con pausas y, si se cubre,
##     carga la patada giratoria (mantener y soltar). Es lo que haría alguien que entendió.
##   machaca (beat 'em up): se alinea igual, pero machaca el botón sin parar (el que no entendió).
##   camion (el camión del prólogo): patea cuando la moto pasa el umbral, encoge las piernas con el
##     aviso, tira harina a los lejanos y se vuelve a agarrar rápido. Lo que haría alguien que entendió.
## Uso: godot --headless --path . -s res://tools/bot_jugar.gd -- <politica> <segundos> <escena> [<escena>...]
## Sirve para encontrar partes débiles: si "idle" gana, la parte no pide nada; si "mash" gana fácil, es plana.

var _held := {}
var _seq: Array = []  # ritmo: [interact apretado, segundos de juego]
var _phys := 0


func _init() -> void:
	_run.call_deferred()


func _press(action: String, on: bool) -> void:
	if _held.get(action, false) == on:
		return
	_held[action] = on
	var e := InputEventAction.new()
	e.action = action
	e.pressed = on
	Input.parse_input_event(e)


func _release_all() -> void:
	for a in _held.keys():
		_press(a, false)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var policy: String = args[0]
	var limit := float(args[1])
	var router = root.get_node("SceneRouter")
	var dlg = root.get_node("Dialogue")
	for path in args.slice(2):
		var gs = root.get_node("GameState")
		gs.new_game()
		gs.flags["arcade"] = true
		load("res://scripts/prologue/Dream.gd").score = 0
		change_scene_to_file(path)
		for i in 5:
			await process_frame
		Engine.time_scale = 3.0
		var t := 0.0
		var f := 0
		var dir := Vector2.ZERO
		var presses := 0
		var ended := ""
		var scene_node = current_scene
		var notes := {}
		while t < limit:
			await process_frame
			f += 1
			t += get_root().get_process_delta_time() if false else 1.0 / 60.0 * Engine.time_scale
			if Engine.time_scale != 3.0 and not router.busy:
				Engine.time_scale = 3.0
			if current_scene != scene_node:
				ended = "cambió"
				break
			var talk: bool = dlg.active
			if policy == "idle":
				_press("interact", talk and f % 8 < 4)
				_track(scene_node, notes)
				continue
			if policy == "camion" and scene_node.has_method("_nearest_ahead"):
				if talk:
					_press("interact", f % 8 < 4)
				else:
					_camion(scene_node, f)
				_track(scene_node, notes)
				continue
			if policy in ["ritmo", "machaca"] and scene_node.has_method("foes") and scene_node.get("player") != null:
				if talk:
					_press("interact", f % 8 < 4)
				else:
					_ritmo(scene_node, policy == "machaca", f)
				_track(scene_node, notes)
				continue
			if f % 36 == 0:
				dir = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(1, -1), Vector2(-1, 1), Vector2.ZERO].pick_random()
			_press("move_left", dir.x < 0)
			_press("move_right", dir.x > 0)
			_press("move_up", dir.y < 0)
			_press("move_down", dir.y > 0)
			var hit := f % 6 < 3
			if hit and not _held.get("interact", false):
				presses += 1
			_press("interact", hit)
			_press("drop", f % 46 < 3)
			# lo que haya de vida / vidas en la escena
			_track(scene_node, notes)
		_release_all()
		await process_frame
		await process_frame
		for i in 30:
			await process_frame
		var nxt: String = current_scene.scene_file_path.get_file() if current_scene else "?"
		print("BOT %s %-28s t=%5.1f fin=%-7s -> %-18s ganó=%s puntos=%d plata=%d ánimo=%d presses=%d min=%s" % [policy, path.get_file(), t, ended if ended != "" else "TIEMPO", nxt, gs.flags.get("dream_won", "?"), load("res://scripts/prologue/Dream.gd").score, gs.money, int(gs.mood), presses, notes])
		Engine.time_scale = 1.0
	quit()


func _ritmo(arena: Node, mash := false, f := 0) -> void:
	var p = arena.player
	var best = null
	for e in arena.foes():
		if is_instance_valid(e) and e.state != 6 and (best == null or e.position.distance_to(p.position) < best.position.distance_to(p.position)):
			best = e
	var mv := Vector2.ZERO
	if best == null:
		mv.x = 1.0  # avanzar
	else:
		var side := -1.0 if p.position.x < best.position.x else 1.0
		var want: Vector2 = best.position + Vector2(side * 22.0, 0.0)
		var to: Vector2 = want - p.position
		if absf(to.y) > 3.0:
			mv.y = signf(to.y)
		if absf(to.x) > 6.0:
			mv.x = signf(to.x)
		elif p.facing != int(-side):
			mv.x = -side  # mirarlo
	var busy: bool = not _seq.is_empty()
	_press("move_left", mv.x < 0 and not busy)
	_press("move_right", mv.x > 0 and not busy)
	_press("move_up", mv.y < 0 and not busy)
	_press("move_down", mv.y > 0 and not busy)
	if mash:
		_press("move_left", mv.x < 0)
		_press("move_right", mv.x > 0)
		_press("move_up", mv.y < 0)
		_press("move_down", mv.y > 0)
		_press("interact", f % 6 < 3 and best != null and best.position.distance_to(p.position) < 40.0)
		return
	if _seq.is_empty() and best != null and mv == Vector2.ZERO:
		var guarding: bool = best.get("_guard") != null and best._guard > 0.0 or best.get("_guarding") != null and best._guarding > 0.0
		if guarding:
			_seq = [[true, 0.75], [false, 0.3]]  # cargar y soltar: patada giratoria
		else:
			_seq = [[true, 0.05], [false, 0.07]]  # pega rápido, pero mirando
	elif not _seq.is_empty() and _seq.size() == 2 and _seq[0][1] < 0.06 and best != null:
		pass
	# El tiempo del juego (los cuadros de dibujo sin pantalla van mucho más rápido que la física).
	var dt := (Engine.get_physics_frames() - _phys) / 60.0 * Engine.time_scale
	_phys = Engine.get_physics_frames()
	if not _seq.is_empty():
		_press("interact", _seq[0][0])
		_seq[0][1] -= dt
		if _seq[0][1] <= 0.0:
			_seq.pop_front()
	else:
		_press("interact", false)


func _camion(tr: Node, f: int) -> void:
	if tr.phase == 0:  # avenida: correr y saltar
		_press("move_right", true)
		_press("interact", f % 6 < 3)
		return
	_press("move_right", false)
	if tr._slip > 0.0:
		_press("interact", f % 4 < 2)
		return
	var coming: bool = tr._warned
	for o in tr._obstacles:
		var n = o["node"]
		if is_instance_valid(n) and n.position.x < tr._px + 60.0 and n.position.x + n.texture.get_width() > tr._px - 10.0:
			coming = true
	_press("move_up", coming)
	if coming:
		_press("interact", false)
		return
	var best = null
	for b in tr._bikers:
		if best == null or absf(tr._bx(b) - tr._px) < absf(tr._bx(best) - tr._px):
			best = b
	var want := false
	if best != null and tr._attack <= 0.0 and tr._recover <= 0.0 and not tr._warned:
		var d: float = absf(tr._bx(best) - tr._px)
		var open: bool = best["kind"] == "punk" or best["state"] in ["windup", "stagger", "punch"]
		if d > 8.0 and d < 40.0 and open:
			want = true
		elif d > 70.0 and tr._bags > 0 and tr._throw_cd <= 0.0 and f % 20 == 0:
			want = true
	_press("interact", want and f % 4 < 2)
	# Con uno tirando botellas, se corre un poco cada tanto (la botella va a donde estaba).
	var thrower := false
	for b in tr._bikers:
		thrower = thrower or b["thrower"]
	var step: bool = thrower and not want and f % 40 < 8
	var left: bool = (f / 40) % 2 == 0
	_press("move_left", step and left)
	_press("move_right", step and not left)


func _track(scene_node: Node, notes: Dictionary) -> void:
	for holder in [scene_node, scene_node.get("player")]:
		if holder == null or not (holder is Object):
			continue
		for k in ["life", "hp", "lives", "health", "armor"]:
			var v = holder.get(k)
			if v != null and (v is int or v is float):
				notes[k] = mini(notes.get(k, 99999), int(v))
	var st = scene_node.get("stats")
	if st is Dictionary:
		for k in st:
			notes[k] = st[k]
	for k in ["defeated", "phase", "level", "round", "deaths", "caught", "lap", "position"]:
		var v = scene_node.get(k)
		if v != null and (v is int or v is float or v is String):
			notes["last_" + k] = v
