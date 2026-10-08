extends CanvasLayer
## Cambia de escena con fundido a negro y recuerda en qué punto aparecer.
## Puede mostrar un título sobre el negro ("DÍA 1 — 06:17") y una línea del narrador al llegar.
## En debug, F2 llama a debug_skip() de la escena actual (para probar sin jugar todo).
## En debug, F4 abre el menú de prueba (dormir ya, saltar días, plata, disparar hechos, soñar ya).

const FADE_TIME := 0.3
const TITLE_TIME := 2.2
const FONT := preload("res://assets/fonts/PressStart2P.ttf")

## Nombre del Marker2D donde aparece el jugador en la escena nueva ("" = el de por defecto).
var spawn_point := ""
## Mientras es true el jugador no se mueve.
var busy := false

var _fade: ColorRect
var _title: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)

	_title = Label.new()
	_title.add_theme_font_override("font", FONT)
	_title.add_theme_font_size_override("font_size", 8)
	_title.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.modulate.a = 0.0
	add_child(_title)


func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.pressed and not event.echo and event.physical_keycode == KEY_F4 \
			and not busy and not Dialogue.active:
		_debug_menu()
		return
	if OS.is_debug_build() and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		var scene := get_tree().current_scene
		if scene and scene.has_method("debug_skip") and not busy:
			scene.debug_skip()


func go(scene_path: String, spawn := "", title := "", line := "") -> void:
	if busy:
		return
	# Sueño suelto (menú SUEÑOS): al despertar no hay noche ni ciudad, vuelve al título.
	if GameState.flags.get("arcade", false) and (scene_path.ends_with("Night.tscn") or scene_path.ends_with("City.tscn")):
		GameState.flags.erase("arcade")
		scene_path = "res://scenes/ui/Title.tscn"
		spawn = ""
		title = ""
		line = ""
	busy = true
	Engine.time_scale = 1.0
	await create_tween().tween_property(_fade, "modulate:a", 1.0, FADE_TIME).finished
	spawn_point = spawn
	get_tree().change_scene_to_file(scene_path)
	if title != "":
		await _show_title(title)
	# Esperar a que la escena nueva haga su _ready.
	await get_tree().process_frame
	await get_tree().process_frame
	await create_tween().tween_property(_fade, "modulate:a", 0.0, FADE_TIME).finished
	busy = false
	if line != "":
		await get_tree().create_timer(1.2).timeout
		Narrator.say(line)


## Arranque desde negro con un título (la primera escena del juego).
func intro(title: String) -> void:
	busy = true
	_fade.modulate.a = 1.0
	await _show_title(title)
	await create_tween().tween_property(_fade, "modulate:a", 0.0, FADE_TIME * 2).finished
	busy = false


func _show_title(title: String) -> void:
	_title.text = title
	var t := create_tween()
	t.tween_property(_title, "modulate:a", 1.0, 0.4)
	t.tween_interval(TITLE_TIME)
	t.tween_property(_title, "modulate:a", 0.0, 0.4)
	await t.finished


# ---------------------------------------------------------------- Menú de prueba (solo en debug, F4)

const CITY := "res://scenes/world/City.tscn"
const NIGHT := "res://scenes/world/Night.tscn"


func _debug_menu() -> void:
	var g := GameState
	var opts := ["Dormir ya (pasar la noche)", "+$50.000", "Día +1 (sin dormir)", "Día +5 (sin dormir)",
		"Hechos: cédula, obra, centro", "Hechos: llamada a mamá", "Hechos: papá en la plaza",
		"Victoria: vínculo 3 + visitas", "Misterios: todas las pistas", "Soñar ya el próximo sueño",
		"Todos iguales: %s" % str(g.flags.get("iguales", "gradual")), "Locura +5 (ahora %d)" % int(g.flags.get("locura", 0)), "Nada"]
	var i := await Dialogue.talk([["PRUEBA", "Día %d, %s. $%d. Sueños vistos: %d." % [g.day, TimeManager.clock_text(), g.money,
		g.flags.get("dreams_seen", []).size()]]], opts)
	var f := g.flags
	match i:
		0:
			if not f.has("sleep_spot"):
				f["sleep_spot"] = "banco"
			go(NIGHT)
		1:
			g.add_money(50000)
		2:
			g.day += 1
		3:
			g.day += 5
		4:
			f["centro_open"] = true
			f["obra_ready"] = true
			if g.count("cedula") == 0:
				g.add_item("cedula")
			if g.count("carta_german") == 0:
				g.add_item("carta_german")
		5:
			f["llamo_mama"] = true
			f["llamada_mama"] = "hablo"
		6:
			f["papa_encuentro"] = true
		7:
			f["victoria"] = 3
			f["victoria_vista"] = true
			f["visitas"] = true
			f["trabajo_dias"] = maxi(3, int(f.get("trabajo_dias", 0)))
		8:
			f["es_el_oido"] = true
			f["casa_tejas_misterio"] = true
			f["senor_negro"] = true
			for it in ["recorte_1", "recorte_2", "recorte_3", "carta_ines"]:
				if g.count(it) == 0:
					g.add_item(it)
			for who in ["marta", "wilson", "samuel", "german", "rosa", "aurelio", "padre"]:
				f["pista_" + who] = true
		10:
			var modes := ["gradual", "siempre", "no"]
			f["iguales"] = modes[(modes.find(str(f.get("iguales", "gradual"))) + 1) % modes.size()]
			Narrator.say("Todos iguales: %s." % f["iguales"])
			go(get_tree().current_scene.scene_file_path)
		11:
			g.add_locura(5)
			Narrator.say("Locura: %d." % int(f["locura"]))
			go(get_tree().current_scene.scene_file_path)
		9:
			# Que esta noche toque sueño: se olvida del "una noche libre" y se duerme.
			f["last_dream_day"] = -99
			if not f.has("sleep_spot"):
				f["sleep_spot"] = "banco"
			go(NIGHT)
