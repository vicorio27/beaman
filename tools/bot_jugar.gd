extends SceneTree
## Juega cada escena con una política tonta y anota qué pasa (prueba de jugabilidad).
##   idle: no hace nada (solo pasa los diálogos).
##   mash: machaca la acción, cambia de dirección al azar, a veces suelta/olfatea.
## Uso: godot --headless --path . -s res://tools/bot_jugar.gd -- <politica> <segundos> <escena> [<escena>...]
## Sirve para encontrar partes débiles: si "idle" gana, la parte no pide nada; si "mash" gana fácil, es plana.

var _held := {}


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
		print("BOT %s %-28s t=%5.1f fin=%-7s -> %-18s puntos=%d presses=%d min=%s" % [policy, path.get_file(), t, ended if ended != "" else "TIEMPO", nxt, load("res://scripts/prologue/Dream.gd").score, presses, notes])
		Engine.time_scale = 1.0
	quit()


func _track(scene_node: Node, notes: Dictionary) -> void:
	for holder in [scene_node, scene_node.get("player")]:
		if holder == null or not (holder is Object):
			continue
		for k in ["life", "hp", "lives", "health", "armor"]:
			var v = holder.get(k)
			if v != null and (v is int or v is float):
				notes[k] = mini(notes.get(k, 99999), int(v))
	for k in ["defeated", "phase", "level", "round", "deaths", "caught", "lap", "position"]:
		var v = scene_node.get(k)
		if v != null and (v is int or v is float or v is String):
			notes["last_" + k] = v
