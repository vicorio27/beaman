extends "res://scripts/prologue/FightArena.gd"
## CARRERAS 3, el final: después de ganarles en moto, Guillermo se baja. A mano limpia.
## Él cree que yo me acosté con Camila. Si le gano, me escucha.
## Camila mira desde un lado (no se mete: nunca se mete en lo que la puede ensuciar).

const NIGHT := "res://scenes/world/Night.tscn"
const RAGE := {
	0.75: "GUILLERMO: —¡Con mi mujer! ¡Usted, que comía en mi casa!",
	0.5: "GUILLERMO: —¡Ella me lo contó llorando! ¡Llorando, parce!",
	0.25: "CAMILA (desde la esquina): —¡Péguele, mi amor! ¡Péguele por mí!",
}

var _said := {}


func setup() -> void:
	waves = [{"at": 0.0, "enemies": ["boss"]}]
	types = TYPES.duplicate()
	types["boss"] = {"sheet": "res://assets/prologue/guillermo.png", "hp": 200, "speed": 44.0, "damage": 7,
		"scale": Vector2(1.4, 1.05)}  # gordo, muy gordo
	items = [["bottle", Vector2(200, 160)]]
	lines = ["GUILLERMO: —¡Venga! ¡Sin moto, sin nada! ¡Como hombres! ¡Como detrás de la cancha del Liceo!"]
	boss_name = "GUILLERMO"
	if FinalRush.is_step("guillermo"):
		types["boss"] = {"sheet": "res://assets/prologue/guillermo.png", "hp": 320, "speed": 52.0, "damage": 9,
			"scale": Vector2(1.4, 1.05)}
		boss_name = "GUILLERMO DE ORO"
		lines = ["GUILLERMO: —Me compré cadenas nuevas, parce. Pesan. Pegan. Las pagó ella. Con mi tarjeta."]
	bg_path = "res://assets/prologue/ep2_bg.png"
	intro_title = "MANO A MANO"
	lilato_cameo = false
	rain = false
	next_scene = NIGHT


func _spawn(kind_spec: String, pos: Vector2) -> void:
	super._spawn(kind_spec, pos)
	if kind_spec == "boss" and FinalRush.is_step("guillermo"):
		_alive[-1].modulate = Color(1.0, 0.85, 0.35)  # dorado
	if kind_spec == "boss":
		_alive[-1].life_changed.connect(_rage)


func _rage(ratio: float) -> void:
	for t in RAGE:
		if ratio <= t and not _said.has(t) and ratio > 0.0:
			_said[t] = true
			Narrator.say(RAGE[t], true)


## Guillermo en el piso. Ahora sí escucha.
func _level_done() -> void:
	if FinalRush.is_step("guillermo"):
		await Dialogue.talk([["GUILLERMO", "—Las cadenas eran de mentira, parce. Como todo lo de ella. Me dejaron el cuello verde."]])
		FinalRush.next()
		return
	await Dialogue.talk([
		["GUILLERMO", "—... ¿Por qué no me dijo nada?"],
		["YO", "—Se lo dije. Usted le creyó a ella."],
		["GUILLERMO", "—Ella me dijo que usted se le tiró encima."],
		["YO", "—Ella se me sentó encima. Yo le dije que no. Por usted, güevón. Y porque me debía ciento ochenta mil del perfume."],
		["GUILLERMO", "—... ¿El Carolina Herrera?"],
		["YO", "—El de la botella dorada."],
		["GUILLERMO", "—Ella me dijo que se lo había regalado la hermana."],
		["YO", "—Ella no tiene hermana, Guillermo."],
		["GUILLERMO", "—... ¿Y por qué le creo ahora?"],
		["YO", "—Porque está en el piso. Desde el piso se ve todo más claro. Créame: yo vivo ahí."],
		["CAMILA", "—¡Guillermo! ¡Nos vamos!"],
		["", "Guillermo se levanta. Me mira. La mira a ella. Duda."],
		["", "Y se va con ella. Igual. Algunos prefieren una mentira que los abrace a una verdad que los deje solos."],
		["", "Pero esta vez se fue sabiendo. Eso ya no es mi problema."],
		["", "EPISODIO 3 COMPLETO."],
	])
	GameState.flags["guillermo_sabe"] = true
	GameState.flags["dream_won"] = true
	GameState.flags["dream_return"] = "carrera3"
	while SceneRouter.busy:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	SceneRouter.go(NIGHT)
