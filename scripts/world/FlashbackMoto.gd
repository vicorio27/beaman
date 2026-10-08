extends Node2D
## Recuerdo: el día que compró su primera moto (una UM Renegade 180 café).
## Una calle de antes, con colores cálidos (el pasado era mejor, o así se acuerda). Él camina
## hasta el taller de motos usadas, le paga al señor de la chaqueta de cuero (Conversations:
## "chaqueta") y se sube (ServiceSpot "fb_moto") → MotoRide.tscn, la ruta hasta la casa de ella.
## Sin hambre, sin reloj, sin Lukas: todavía no existían.

const W := 30  # tiles
const H := 12
const SIDEWALK := 13
const CURB := 16
const ASPHALT := 8
const DASH := 11
const DIRT := 6
const MOTO_FOOT := Vector2(300, 110)

var _player: CharacterBody2D


func _ready() -> void:
	var ts: TileSet = load("res://assets/barrio/barrio_tileset.tres")
	var ground := TileMapLayer.new()
	ground.tile_set = ts
	add_child(ground)
	for y in H:
		for x in W:
			var t := DIRT
			if y in [5, 6]:
				t = SIDEWALK
			elif y == 7:
				t = CURB
			elif y >= 8:
				t = DASH if y == 10 and x % 2 == 0 else ASPHALT
			ground.set_cell(Vector2i(x, y), 0, Vector2i(t, 0))
	var world := Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_prop(world, "house_b", Vector2(60, 84))
	_prop(world, "warehouse_b", Vector2(220, 84))
	_prop(world, "house_e", Vector2(380, 84))
	_prop(world, "tree_sparse", Vector2(140, 86))
	_prop(world, "pole", Vector2(440, 90))
	_label("MOTOS USADAS", Vector2(220, 18))
	_prop(world, "moto_parked", MOTO_FOOT)

	# El señor de la chaqueta de cuero, al lado de la moto.
	var seller := CharacterBody2D.new()
	seller.set_script(load("res://scripts/npc/NPC.gd"))
	seller.name = "Chaqueta"
	seller.npc_id = "chaqueta"
	seller.sheet_row = 0
	seller.face = "left"
	seller.position = MOTO_FOOT + Vector2(-26, -8)
	world.add_child(seller)
	seller.modulate = Color(0.55, 0.45, 0.42)  # cuero viejo

	var spot := Area2D.new()
	spot.set_script(load("res://scripts/world/ServiceSpot.gd"))
	spot.service_id = "fb_moto"
	spot.hint = "MOTO"
	spot.area = Vector2(34, 18)
	spot.position = MOTO_FOOT + Vector2(0, 2)
	world.add_child(spot)

	_player = load("res://scenes/player/Player.tscn").instantiate()
	_player.position = Vector2(36, 104)
	world.add_child(_player)
	_player.face("right")
	var cam: Camera2D = _player.get_node("Camera2D")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * 16
	cam.limit_bottom = H * 16
	_walls()

	# Antes: cálido y con sol.
	var tint := CanvasModulate.new()
	tint.color = Color(1.0, 0.92, 0.8)
	add_child(tint)
	var mood: Node = load("res://scenes/ui/MoodFilter.tscn").instantiate()
	mood.forced_distress = 0.0
	add_child(mood)
	Narrator.say("Antes. Un año de ahorros en el bolsillo, ninguna cana y cero problemas. Bueno, casi cero.", true)


func _prop(parent: Node, art: String, foot: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/barrio/%s.png" % art)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = foot
	parent.add_child(s)


func _label(text: String, center: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", load("res://assets/fonts/PressStart2P.ttf"))
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.1))
	l.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	l.size = Vector2(120, 10)
	l.position = center - Vector2(60, 5)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 5
	add_child(l)


## La vereda y la calle se caminan; las fachadas y los bordes, no.
func _walls() -> void:
	var body := StaticBody2D.new()
	for r in [Rect2(0, 0, W * 16, 86), Rect2(0, H * 16, W * 16, 20), Rect2(-10, 0, 10, H * 16),
			Rect2(W * 16, 0, 10, H * 16), Rect2(MOTO_FOOT.x - 14, MOTO_FOOT.y - 6, 28, 6)]:
		var cs := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		cs.shape = shape
		cs.position = r.position + r.size / 2.0
		body.add_child(cs)
	add_child(body)
