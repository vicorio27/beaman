class_name Recuerdo
## Los recuerdos: una foto vieja en sepia aparece de golpe (como la de la primera noche), se cuenta en
## tercera persona, se voltea y atrás hay algo escrito a mano. Cada una sale una sola vez, en un momento
## de la vida real, y cuenta un pedazo de lo que él era. Arte: tools/art/draw_recuerdos.py.
##   await Recuerdo.show("renegade")   (no hace nada si ya se vio)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
## id -> [foto, lo que se cuenta mirándola, lo escrito atrás, lo que queda después]
const ALL := {
	"renegade": ["recuerdo_renegade",
		["(Una foto. Él, de veintitantos, sin barba, con chaqueta. Una mano en el tanque de una moto negra.)",
			"(Sonríe con toda la cara. No se acuerda de haber sonreído así.)"],
		"La Renegade. Primer día.\nCuotas: 36. Pagadas: 36.",
		["(La pagó toda. Fue lo único que pagó completo.)"]],
	"lorena": ["recuerdo_lorena",
		["(Otra foto. Ella, atrás en la moto, el pelo castaño volando. Se está riendo. De él, seguro.)",
			"(De él solo sale un hombro: tomaba la foto con la otra mano, manejando. Ella lo regañó por eso.)"],
		"Lore. \"Más despacio.\"",
		["(Los dos se reían en esa época. Hay pruebas.)"]],
	"bebe": ["recuerdo_bebe",
		["(Una foto en un hospital. Él, con una camisa planchada, sostiene una cobija con una cara adentro.)",
			"(Tiene las manos tiesas, como si le hubieran dado algo que se rompe con mirarlo.)"],
		"Victoria. 3,1 kilos.\n29 de octubre.",
		["(Ella ahora sale del colegio y no sabe quién es él. Todavía.)"]],
	"lukas": ["recuerdo_lukas",
		["(Una foto: una caja de zapatos en el piso de una cocina. Adentro, un cachorro de orejas enormes.)",
			"(Una mano entra a acariciarlo. Es la de él. Es la misma mano.)"],
		"Lukas. Llegó en una caja\nde zapatos. Talla 42.",
		["(Lukas, al lado, lo mira mirar la foto. Bosteza. Él sí se acuerda de la caja: se la comió.)"]],
	"oficina": ["recuerdo_oficina",
		["(Una foto de oficina. Él, de saco y corbata, detrás de un escritorio. En la placa: EMPLEADO DEL MES.)",
			"(La sonrisa es la de las fotos de la empresa: la que se pone para que no la quiten.)"],
		"Marzo. Empleado del mes.\nEl único mes.",
		["(Seis horas cargando ladrillo le dolieron menos que ese año firmando.)"]],
}


static func seen(id: String) -> bool:
	return id in GameState.flags.get("recuerdos", [])


## Muestra el recuerdo (una vez). Se espera con await.
static func show(id: String) -> void:
	if seen(id) or not ALL.has(id):
		return
	var r: Array = ALL[id]
	var list: Array = GameState.flags.get("recuerdos", [])
	list.append(id)
	GameState.flags["recuerdos"] = list
	var tree := Engine.get_main_loop() as SceneTree
	var scene := tree.current_scene
	if scene == null:
		return
	MusicDirector.force("memory")  # la cajita de música desafinada
	var layer := CanvasLayer.new()
	layer.layer = 12
	scene.add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.size = Vector2(320, 180)
	layer.add_child(dim)
	var pic := TextureRect.new()
	pic.texture = load("res://assets/items/%s.png" % r[0])
	pic.position = Vector2(100, 18)
	pic.pivot_offset = Vector2(60, 44)
	pic.rotation = -0.03
	pic.modulate.a = 0.0
	layer.add_child(pic)
	# Aparece como un flash de memoria: blanco un instante, después la foto.
	var flash := ColorRect.new()
	flash.color = Color(1, 0.96, 0.88, 0.0)
	flash.size = Vector2(320, 180)
	layer.add_child(flash)
	var t := scene.create_tween()
	t.tween_property(flash, "color:a", 0.7, 0.12)
	t.parallel().tween_property(dim, "color:a", 0.78, 0.4)
	t.tween_property(flash, "color:a", 0.0, 0.6)
	t.parallel().tween_property(pic, "modulate:a", 1.0, 0.9)
	await t.finished
	# El grano: la foto respira un poquito mientras se mira.
	var breath := scene.create_tween().set_loops()
	breath.tween_property(pic, "modulate", Color(0.94, 0.9, 0.84), 1.4)
	breath.tween_property(pic, "modulate", Color(1, 1, 1), 1.4)
	await Dialogue.talk(r[1].map(func(l): return ["", l]))
	# La voltea: atrás, escrito a mano.
	var flip := scene.create_tween()
	flip.tween_property(pic, "scale:x", 0.0, 0.25)
	flip.tween_callback(func():
		pic.texture = load("res://assets/items/recuerdo_dorso.png")
		var ink := Label.new()
		ink.text = r[2]
		ink.add_theme_font_override("font", FONT)
		ink.add_theme_font_size_override("font_size", 8)
		ink.add_theme_color_override("font_color", Color(0.25, 0.2, 0.3))
		ink.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ink.position = Vector2(8, 30)
		ink.size = Vector2(106, 52)
		ink.rotation = -0.04
		pic.add_child(ink))
	flip.tween_property(pic, "scale:x", 1.0, 0.25)
	await flip.finished
	await Dialogue.talk(r[3].map(func(l): return ["", l]))
	breath.kill()
	var out := scene.create_tween()
	out.tween_property(pic, "modulate:a", 0.0, 0.8)
	out.parallel().tween_property(dim, "color:a", 0.0, 0.8)
	await out.finished
	layer.queue_free()
	GameState.change_mood(3.0)
	MusicDirector.release()
