class_name Passerby
extends Node2D
## Un transeúnte: camina de una punta a la otra de su carril (una vereda) y se va.
## Cuando pasa cerca del protagonista reacciona una sola vez: casi siempre con desprecio
## (más si está sucio), a veces lo ignora y muy de vez en cuando es amable.
## El desprecio baja el ánimo; él a veces contesta (si todavía le queda humor).
## Casi siempre, en vez de insultarlo, lo reconocen: "mírenlo, es él", con asco o con lástima. Él no
## sabe por qué: nadie se lo dijo nunca. (El jugador tampoco lo sabe todavía.)

const FONT := preload("res://assets/fonts/PressStart2P.ttf")
const NEAR := 28.0
const DESPISE := [
	"—¡Consiga trabajo!",
	"—Ni me mire.",
	"—No tengo, no tengo.",
	"—Qué peligro este barrio.",
	"—Ese perro está mejor que usted.",
	"(aprieta la cartera)",
	"(se tapa la nariz)",
]
const DESPISE_DIRTY := ["—Uy, qué asco.", "—¡Báñese, hombre!", "(se tapa la nariz y apura el paso)"]
## Lo reconocen. Asco y lástima, nunca la explicación.
const WHISPERS := [
	"—Mírelo. Es él.",
	"—¿Ese no es el que...? Sí. Es él.",
	"—No lo mire. Dicen que fue él.",
	"—Y anda como si nada.",
	"—Pobrecito. Bueno, pobrecito no.",
	"—Yo no sé cómo duerme.",
	"—Es él. Salía en todas partes.",
	"—Pobre la niña.",
	"(lo mira y se persigna)",
	"(le dice algo al oído a la otra, y las dos lo miran)",
]
## Lo que piensa él cuando lo reconocen: no entiende, y se le nota.
## Él se queda mirando al que susurró. El que susurró sigue (y se pone peor).
const WHISPER_REPLIES := [
	"—Y nos mira. Mírelo cómo nos mira.",
	"—Ni se defiende. Eso es lo que más miedo me da.",
	"—Dicen que no habla. Dicen muchas cosas.",
	"—No lo mire, que se le queda mirando a uno. Fijo. Como un perro. Bueno, el perro es más normal.",
	"—¿Ve? Ni pestañea. Ese es capaz de todo.",
]
const KIND := [
	["—Tome, para un tintico.", 500, 3.0],
	["—Que Dios lo bendiga.", 0, 1.0],
	["—Lindo el perro. ¿Cómo se llama?", 0, 2.0],
]
## Le dicen algo feo. Él no contesta. El que lo dijo no sabe qué hacer con ese silencio.
const COMEBACKS := [
	"—¿Me oyó? ... ¿ME OYÓ? ... Encima sordo.",
	"—Hable, pues. ... Nada. Ni para eso sirve.",
	"—Uy, me miró. Ya me miró. Vámonos, vámonos.",
	"—¿No me va a contestar? ¿Nada? ... Qué falta de respeto. Por lo menos insúlteme.",
	"—Mudo y cochino. Combo completo. ... ¿Ni eso le duele?",
]

static var _last_comeback := -100.0
static var _comeback_i := 0
static var _whisper_i := 0

var path_from := Vector2.ZERO
var path_to := Vector2.ZERO
var speed := 22.0
var row := 0
var _sprite: AnimatedSprite2D
var _bubble: Label
var _reacted := false
var _detour := Vector2.ZERO


func _ready() -> void:
	position = path_from
	_sprite = AnimatedSprite2D.new()
	CharacterFrames.dress(_sprite, row)
	_sprite.position = Vector2(0, -8)
	add_child(_sprite)
	modulate = GameState.same_tint(Color.from_hsv(randf(), 0.22, 1.0))
	var dir := path_to - path_from
	if absf(dir.x) > absf(dir.y):
		_sprite.play("walk_side")
		_sprite.flip_h = dir.x > 0
	else:
		_sprite.play("walk_down" if dir.y > 0 else "walk_up")
	_bubble = Label.new()
	_bubble.add_theme_font_override("font", FONT)
	_bubble.add_theme_font_size_override("font_size", 8)
	_bubble.add_theme_constant_override("outline_size", 3)
	_bubble.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.size = Vector2(110, 20)
	_bubble.position = Vector2(-55, -40)
	_bubble.z_index = 6
	_bubble.visible = false
	add_child(_bubble)


func _process(delta: float) -> void:
	if GameState.ui_open:
		_sprite.pause()
		return
	_sprite.play()
	var target := path_to + _detour
	position = position.move_toward(target, speed * delta)
	if position.distance_to(target) < 1.0:
		queue_free()
		return
	if not _reacted:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and player.global_position.distance_to(global_position) < NEAR:
			_reacted = true
			_react()


func _react() -> void:
	var dirty := GameState.is_dirty()
	var roll := randf()
	var kind_chance := 0.05 if dirty else 0.1
	if GameState.lukas_knows("saludar"):
		kind_chance *= 2.0  # Lukas los saluda en dos patas
	var despise_chance := (0.75 if dirty else 0.45) + 0.2 * GameState.diff("social")
	if roll < kind_chance:
		var k: Array = KIND.pick_random()
		_say(k[0], Color(0.7, 0.95, 0.7))
		if k[1] > 0:
			GameState.add_money(k[1])
		GameState.change_mood(k[2])
	elif roll < kind_chance + despise_chance:
		# Casi siempre lo reconocen; a veces, solo lo desprecian (más si está sucio).
		if randf() < 0.65:
			_say(WHISPERS.pick_random(), Color(0.85, 0.8, 0.9))
			GameState.change_mood(-3.0 * (0.5 if GameState.has_skill("aguante") else 1.0))
			if randf() < 0.4:
				GameState.add_locura(1)
			_wonder()
			return
		var pool: Array = DESPISE + (DESPISE_DIRTY if dirty else [])
		var line: String = pool.pick_random()
		_say(line, Color(1, 0.75, 0.7))
		GameState.change_mood((-5.0 if dirty else -3.0) * (1.0 + 0.5 * GameState.diff("social")) * (0.5 if GameState.has_skill("aguante") else 1.0))
		if randf() < 0.35:  # se cambia de andén
			_detour = Vector2(0, 26 if position.y < 300 else -26)
		_comeback()


func _say(text: String, color: Color) -> void:
	_bubble.text = text
	_bubble.add_theme_color_override("font_color", color)
	_bubble.visible = true
	var t := create_tween()
	t.tween_interval(2.4)
	t.tween_property(_bubble, "modulate:a", 0.0, 0.5)


## Cuando lo reconocen no contesta: se queda mirando. El que susurró sigue hablando.
func _wonder() -> void:
	GameState.flags["es_el_oido"] = true
	var now := Time.get_ticks_msec() / 1000.0
	if GameState.flags.get("m_el_resuelto", false):
		# Ya sabe por qué. No contesta: les muestra el recorte.
		if now - _last_comeback > 8.0 and randf() < 0.4:
			_last_comeback = now
			await get_tree().create_timer(1.2).timeout
			if is_inside_tree():
				_say(["—¿Qué me muestra? ¿Un periódico? ... ¿Página 14? ... Igual. Igual da miedo.",
					"—¿Y ese recorte? ... \"No hubo cargos\". ... Ah. ... Bueno. Pero no habla. Eso no lo arregla un periódico.",
					"—No me ponga eso en la cara, señor. ... ¿Retirada? ... Bueno, perdón. Pero hable, hombre, que asusta."].pick_random(),
					Color(0.85, 0.85, 0.9))
		return
	if now - _last_comeback < 8.0 or randf() > 0.5:
		return
	_last_comeback = now
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		_say(WHISPER_REPLIES[_whisper_i % WHISPER_REPLIES.size()], Color(0.85, 0.85, 0.9))
	_whisper_i += 1


## Él nunca contesta. A veces, el que lo insultó se desespera.
func _comeback() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_comeback < 8.0 or randf() > 0.4:
		return
	_last_comeback = now
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		_say(COMEBACKS[_comeback_i % COMEBACKS.size()], Color(0.85, 0.85, 0.9))
	_comeback_i += 1
