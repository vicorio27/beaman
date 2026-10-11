class_name CharacterFrames
## Arma las animaciones de un personaje visto desde arriba.
## Cada personaje ocupa 3 filas (quieto, paso 1, paso 2) y 3 columnas: costado (mira a la izquierda),
## frente y espalda. Sirve para la hoja de Kenney (NPCs) y para la del protagonista.

const SHEET := preload("res://assets/tilesets/kenney_urban.png")
const COL_SIDE := 23
const PROTAGONIST := preload("res://assets/characters/protagonist_topdown.png")
## El protagonista adulto (versión A: saco grande, corbata roja). Celdas de 16x26; ver draw_protagonist_adult.py.
const PROTAGONIST_ADULT := preload("res://assets/characters/protagonist_adult.png")
const IGUALES := preload("res://assets/characters/iguales.png")
## Cómo se le van volviendo iguales (ver dress() y assets/shaders/iguales.gdshader).
const SAME_SHADER := preload("res://assets/shaders/iguales.gdshader")
## Los desconocidos: uno por cada fila de Kenney que usaban antes (0, 3, 6, 9, 12, 15).
const STRANGERS := [
	preload("res://assets/characters/transeunte_0.png"),
	preload("res://assets/characters/transeunte_1.png"),
	preload("res://assets/characters/transeunte_2.png"),
	preload("res://assets/characters/transeunte_3.png"),
	preload("res://assets/characters/transeunte_4.png"),
	preload("res://assets/characters/transeunte_5.png"),
]
## Los que ya tienen hoja propia de adulto (misma distribución que el protagonista, sin gestos).
## Los demás siguen con la fila de Kenney.
const OWN := {
	"samuel": preload("res://assets/characters/samuel.png"),
	"german": preload("res://assets/characters/german.png"),
	"rosa": preload("res://assets/characters/rosa.png"),
	"marta": preload("res://assets/characters/marta.png"),
	"wilson": preload("res://assets/characters/wilson.png"),
	"padre": preload("res://assets/characters/padre.png"),
	"fabiola": preload("res://assets/characters/fabiola.png"),
	"aurelio": preload("res://assets/characters/aurelio.png"),
	"leonor": preload("res://assets/characters/leonor.png"),
	"efrain": preload("res://assets/characters/efrain.png"),
	"mono": preload("res://assets/characters/mono.png"),
	"viejos": preload("res://assets/characters/viejos.png"),
	"viejo2": preload("res://assets/characters/viejo2.png"),
	"celador": preload("res://assets/characters/celador.png"),
	"brenda": preload("res://assets/characters/brenda.png"),
	"mauricio": preload("res://assets/characters/mauricio.png"),
	"pecas": preload("res://assets/characters/pecas.png"),
	"lilato": preload("res://assets/characters/lilato.png"),
	"josemario": preload("res://assets/characters/josemario.png"),
	"walter": preload("res://assets/characters/walter.png"),
	"nicolas": preload("res://assets/characters/nicolas.png"),
	"eddy": preload("res://assets/characters/eddy.png"),
	"lisandro": preload("res://assets/characters/lisandro.png"),
	"camila": preload("res://assets/characters/camila.png"),
	"guillermo": preload("res://assets/characters/guillermo.png"),
	"diana": preload("res://assets/characters/diana.png"),
	"raul": preload("res://assets/characters/raul.png"),
	"alvarito": preload("res://assets/characters/alvarito.png"),
}
const ADULT_W := 16
const ADULT_H := 26
## Gestos de quieto: [nombre, celdas (columna de la fila 3), cuadros por segundo]. Se repiten para que duren.
const QUIRKS := {
	"quirk_tie": [[0, 1, 0, 1, 0], 4.0],
	"quirk_salute": [[2, 2, 2, 2], 3.0],
	"quirk_laugh": [[3, 4, 3, 4, 3, 4, 3, 4], 7.0],
	"quirk_talk": [[5, 6, 5, 6, 5, 6, 5, 6], 5.0],
	"blink": [[7], 8.0],
}


## first_row: fila del personaje en la hoja. first_col: columna de la vista de costado.
static func build(first_row: int, sheet: Texture2D = SHEET, first_col := COL_SIDE) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var cols := {"side": first_col, "down": first_col + 1, "up": first_col + 2}
	for dir in cols:
		var col: int = cols[dir]
		frames.add_animation("idle_" + dir)
		frames.add_frame("idle_" + dir, _tile(sheet, col, first_row))
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, 6.0)
		frames.add_frame("walk_" + dir, _tile(sheet, col, first_row + 1))
		frames.add_frame("walk_" + dir, _tile(sheet, col, first_row + 2))
	return frames


## El protagonista: adulto, saco que le queda grande, corbata roja floja, un zapato de cada color.
## Las celdas llevan 10 px vacíos abajo: así los pies quedan donde estaban con los dibujos de 16x16.
static func protagonist() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var cols := {"side": 0, "down": 1, "up": 2}
	for dir in cols:
		frames.add_animation("idle_" + dir)
		frames.add_frame("idle_" + dir, _adult(cols[dir], 0))
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, 6.0)
		frames.add_frame("walk_" + dir, _adult(cols[dir], 1))
		frames.add_frame("walk_" + dir, _adult(cols[dir], 2))
	for q in QUIRKS:
		frames.add_animation(q)
		frames.set_animation_loop(q, false)
		frames.set_animation_speed(q, QUIRKS[q][1])
		for c in QUIRKS[q][0]:
			frames.add_frame(q, _adult(c, 3))
	# Sentado (fila 4): agacharse, de frente (y parpadeando, y con la cabeza gacha), de espalda.
	for anim in [["sit_crouch", 0], ["sit_down", 1], ["sit_down_blink", 2], ["sit_down_bow", 3], ["sit_up", 4], ["sit_up_bow", 5]]:
		frames.add_animation(anim[0])
		frames.add_frame(anim[0], _adult(anim[1], 4))
	return frames


## Viste a una persona de la vida real como la ve él: al principio, como es; con los días y la
## locura se le apagan los colores y se le va borrando la cara, hasta quedar igual a todos los demás
## (GameState.sameness). Los desconocidos usan una de las hojas de transeúnte, según su fila.
static func dress(sprite: AnimatedSprite2D, row: int, id := "", stranger := true) -> void:
	var amount := GameState.sameness(id, stranger)
	sprite.material = null
	if amount >= 1.0:
		sprite.sprite_frames = everyone()
		return
	sprite.sprite_frames = adult(OWN[id] if OWN.has(id) else STRANGERS[(row / 3) % STRANGERS.size()])
	if amount > 0.0:
		var m := ShaderMaterial.new()
		m.shader = SAME_SHADER
		m.set_shader_parameter("same_tex", IGUALES)
		m.set_shader_parameter("amount", amount)
		sprite.material = m


## Con su cara: su hoja de adulto si ya la tiene, si no la de Kenney.
static func named(row: int, id := "") -> SpriteFrames:
	return adult(OWN[id]) if OWN.has(id) else build(row)


## ¿Tiene hoja propia? (entonces no se tiñe).
static func has_own(id: String) -> bool:
	return OWN.has(id)


## Todos iguales: sin cara, sin color.
static func everyone() -> SpriteFrames:
	return adult(IGUALES)


## Una hoja de adulto (celdas de 16x26): quieto y caminando, de costado, frente y espalda.
static func adult(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var cols := {"side": 0, "down": 1, "up": 2}
	for dir in cols:
		frames.add_animation("idle_" + dir)
		frames.add_frame("idle_" + dir, _adult(cols[dir], 0, sheet))
		frames.add_animation("walk_" + dir)
		frames.set_animation_speed("walk_" + dir, 6.0)
		frames.add_frame("walk_" + dir, _adult(cols[dir], 1, sheet))
		frames.add_frame("walk_" + dir, _adult(cols[dir], 2, sheet))
	return frames


static func _adult(col: int, row: int, sheet: Texture2D = PROTAGONIST_ADULT) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = sheet
	t.region = Rect2(col * ADULT_W, row * ADULT_H, ADULT_W, ADULT_H)
	t.margin = Rect2(0, 0, 0, 10)
	return t


static func _tile(sheet: Texture2D, col: int, row: int) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = sheet
	t.region = Rect2(col * 16, row * 16, 16, 16)
	return t
