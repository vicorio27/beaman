class_name Pickup
extends Area2D
## Algo tirado en el piso que se puede agarrar (interactuar). Va a la mochila si hay lugar.

const FONT := preload("res://assets/fonts/PressStart2P.ttf")

@export var item_id := "lata"
@export var qty := 1
## Línea al agarrarlo ("" = la de siempre).
@export_multiline var found_line := ""
## Escondido: no se ve ni se puede agarrar hasta que Lukas lo encuentra olfateando.
@export var concealed := false

var _player: Node2D
var _hint: Label
var _sprite: Sprite2D


func _ready() -> void:
	# Lo que ya se agarró hoy no vuelve a aparecer hasta mañana (la calle repone, pero no tan rápido).
	if GameState.flags.get("taken", {}).get(name, -1) == GameState.day:
		queue_free()
		return
	# El coleccionable: una vez encontrado, no vuelve nunca. Y no lo toca la dificultad.
	var collectible: bool = Items.info(item_id)["type"] in ["coleccionable", "pista"]
	if collectible and name in GameState.flags.get("coleccion", []):
		queue_free()
		return
	# Dificultad: hoy quizás no está, o está escondido (solo Lukas lo encuentra). Lo de los favores, no.
	if not concealed and not collectible and Items.info(item_id)["type"] != "especial":
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(name) + str(GameState.day))
		var d := GameState.diff("buscar")
		if rng.randf() < 0.45 * d:
			queue_free()
			return
		if rng.randf() < 0.65 * d:
			concealed = true
	if not GameState.lukas_alive():
		concealed = false  # ya no hay quién lo encuentre olfateando: se ve, si uno mira bien
	add_to_group("pickups")
	add_to_group(Focus.GROUP)
	_sprite = Sprite2D.new()
	_sprite.texture = Items.icon(item_id)
	_sprite.offset = Vector2(0, -8)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 12)
	shape.shape = rect
	shape.position = Vector2(0, -4)
	add_child(shape)
	_hint = Label.new()
	_hint.text = "AGARRAR"
	_hint.add_theme_font_override("font", FONT)
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.add_theme_constant_override("outline_size", 3)
	_hint.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	_hint.position = Vector2(-28, -30)
	_hint.size = Vector2(56, 10)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.z_index = 5
	_hint.visible = false
	add_child(_hint)
	_sprite.visible = not concealed
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Lukas lo encontró: queda a la vista.
func reveal() -> void:
	concealed = false
	_sprite.visible = true
	if _player:
		_hint.visible = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_hint.visible = not concealed


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		_hint.visible = false


func _process(_delta: float) -> void:
	if _sprite == null:  # hoy no estaba (queue_free en _ready): todavía corre un cuadro
		return
	# Brillito para que se vea entre la basura.
	_sprite.modulate = Color(1, 1, 1) * (1.0 + 0.25 * sin(Time.get_ticks_msec() / 250.0))
	Focus.dim(self, _hint)
	if _player == null or concealed or GameState.input_blocked() or SceneRouter.busy:
		return
	if Input.is_action_just_pressed("interact") and Focus.mine(self):
		var it := Items.info(item_id)
		var left := GameState.add_item(item_id, qty)
		if left == qty:
			Narrator.say("(Mochila llena.)", true)
			return
		if it["type"] == "pista":
			var got_p: Array = GameState.flags.get("coleccion", [])
			got_p.append(name)
			GameState.flags["coleccion"] = got_p
			Narrator.say("(%s)" % it["desc"], true)  # las líneas viejas (found_line) eran pensamientos: ya no
		elif it["type"] == "coleccionable":
			var got: Array = GameState.flags.get("coleccion", [])
			got.append(name)
			GameState.flags["coleccion"] = got
			Narrator.say("(%s)" % GameState.photo_line(got.size()), true)
		else:
			Narrator.say("(Recoge: %s.)" % it["name"].to_lower(), true)
		var taken: Dictionary = GameState.flags.get("taken", {})
		taken[name] = GameState.day
		GameState.flags["taken"] = taken
		queue_free()
