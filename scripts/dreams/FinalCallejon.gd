extends "res://scripts/prologue/FightArena.gd"
## EL SUEÑO FINAL — "LA SERPIENTE", fase 1 de 3 (beat 'em up). El callejón del prólogo, otra vez,
## pero esta vez lo que viene son los policías del operativo que ella armó. Al fondo, mirando desde un
## balcón, Lilato. Al vencer al sargento, ella escapa: fase 2 (PLOMO: el operativo).

const NEXT := "res://scenes/dreams/FinalOperativo.tscn"
const POLICE_TINT := Color(0.55, 0.7, 1.0)


func setup() -> void:
	waves = [
		{"at": 0.0, "enemies": ["goon", "goon", "punk", "punk"]},
		{"at": 320.0, "enemies": ["thug", "goon+knife", "punk", "goon"]},
		{"at": 640.0, "enemies": ["thug", "thug", "punk+knife", "goon", "punk"]},
		{"at": 960.0, "enemies": ["boss"]},
	]
	types = TYPES.duplicate()
	for k in types:  # el final pega más que todo lo anterior
		types[k] = types[k].duplicate()
		types[k]["hp"] = int(types[k]["hp"] * 1.8)
		types[k]["damage"] = types[k]["damage"] + 2
	items = [["pipe", Vector2(180, 150)], ["bottle", Vector2(420, 160)], ["pipe", Vector2(700, 140)], ["bottle", Vector2(980, 160)]]
	lines = ["—¡Al suelo! ¡Policía!", "—¡Es él! ¡El del operativo! ¡El de la foto borrosa!", "—La señora dijo que estaba armado. Revisen. ... Un perro. Tiene un perro.", "—..."]
	boss_name = "EL SARGENTO"
	intro_title = "LA SERPIENTE"
	player_hp = 90
	lilato_cameo = false
	rain = true
	next_scene = NEXT


func before_start() -> void:
	await Dialogue.talk([
		["", "El último sueño."],
		["", "El callejón del principio. La misma lluvia. El mismo olor a ladrillo mojado."],
		["", "Pero esta vez no vienen a robarle la mochila. Vienen con uniforme. Con chalecos. Con una foto suya."],
		["", "En un balcón, al fondo, con el celular en la mano: Lilato."],
		["LILATO", "—Ese es. Ese es el peligroso. Yo les dije."],
		["", "Esta vez él sabe todo. Y todavía tiene los puños."],
	])


## Los matones son policías (azulados) en este sueño.
func _spawn(kind_spec: String, pos: Vector2) -> void:
	super._spawn(kind_spec, pos)
	var e: Node2D = _alive[-1]
	e.modulate = POLICE_TINT if kind_spec.get_slice("+", 0) != "boss" else Color(0.45, 0.55, 0.9)


func _level_done() -> void:
	await Dialogue.talk([
		["EL SARGENTO", "—(desde el piso) La señora... nos dio la dirección. Y la foto. Dijo que usted tenía un arma."],
		["YO", "—Nunca tuve un arma. Tenía una hija."],
		["EL SARGENTO", "—... Eso no venía en el informe."],
		["", "En el balcón, Lilato baja el celular. Por primera vez, lo mira con miedo. Se va corriendo."],
		["LILATO", "—¡Refuerzos! ¡Que entre el ejército! ¡Que entre todo!"],
	])
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NEXT, "", "EL OPERATIVO")
