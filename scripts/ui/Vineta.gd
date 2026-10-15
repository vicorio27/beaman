class_name Vineta
extends TextureRect
## Una viñeta animada (240x100, cuatro cuadros que se pasan despacio). Las dibuja
## tools/art/draw_vinetas.py: una hoja por lugar donde duerme (assets/ui/vinetas_<lugar>.png) y una de
## momentos (vinetas_momentos.png); cada fila de la hoja es una viñeta.
##   var v := Vineta.new()
##   v.show_spot("rio", "dormir", "noche", false)   # cómo quedó dormido debajo del puente
##   v.show_row("momentos", Vineta.M.ENTIERRO)
## La usan la noche (NightSequence), los carteles de cambio de escena (SceneRouter), el título y la
## pantalla de CONTINUE?: ningún texto del juego va sobre negro solo.

const SPOTS := ["banco", "kiosco", "rio", "callejon", "parque", "pension", "lote"]
## Las filas de la hoja de un lugar: fila = tipo * 4 + lluvia * 2 + solo (solo = sin Lukas).
const KINDS := ["dormir_noche", "sueno_noche", "despierta_alba", "despierta_noche", "golpeado_alba", "golpeado_noche"]
const FINAL := 24  # el último amanecer
## Las filas de la hoja de momentos.
enum M {INTRUSO, INTRUSO_SOLO, LUKAS_PECHO, LUKAS_QUIETO, ENTIERRO, COLLAR,
	ANTES, MOTO, BILLAR, DESMAYO, DESMAYO_SOLO, FIN,
	ATARDECER, ATARDECER_SOLO, PUENTE_DIA, ESPEJO, ESPEJO_3}
const FRAME_TIME := 0.42

var _frames: Array = []
var _t := 0.0


## Una viñeta grande encima del juego (arriba; el diálogo va debajo), mientras dura lo que se cuenta.
## Devuelve la capa: se quita con hide_over(capa).
static func show_over(sheet: String, row: int) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 12
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.04, 0.0)
	shade.size = Vector2(320, 180)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	var v := Vineta.new()
	v.show_row(sheet, row)
	v.position = Vector2(16, 0)
	v.scale = Vector2(1.2, 1.2)
	v.modulate.a = 0.0
	layer.add_child(v)
	var tree := Engine.get_main_loop() as SceneTree
	(tree.current_scene if tree.current_scene else tree.root).add_child(layer)  # (si cambia la escena, se va con ella)
	var t := layer.create_tween()
	t.tween_property(shade, "color:a", 0.75, 0.5)
	t.parallel().tween_property(v, "modulate:a", 1.0, 0.6)
	return layer


static func hide_over(layer: CanvasLayer) -> void:
	if not is_instance_valid(layer):
		return
	var t := layer.create_tween()
	for c in layer.get_children():
		t.parallel().tween_property(c, "modulate:a", 0.0, 0.5)
	t.tween_callback(layer.queue_free)


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


static func spot_row(kind: String, time: String, rain: bool, solo: bool) -> int:
	return KINDS.find("%s_%s" % [kind, time]) * 4 + (2 if rain else 0) + (1 if solo else 0)


## La fila `row` de la hoja `sheet` ("momentos" o un lugar).
func show_row(sheet: String, row: int) -> void:
	var tex: Texture2D = load("res://assets/ui/vinetas_%s.png" % sheet)
	_frames.clear()
	for k in 4:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(k * 240, row * 100, 240, 100)
		_frames.append(at)
	_t = 0.0
	texture = _frames[0]


## La viñeta de un lugar. kind: "dormir", "sueno", "despierta" o "golpeado"; time: "noche" o "alba".
## Sin Lukas, la misma, sin él. Un lugar que no tiene hoja usa la del banco.
func show_spot(spot: String, kind: String, time: String, rain: bool) -> void:
	show_row(spot if spot in SPOTS else "banco", spot_row(kind, time, rain, not GameState.lukas_alive()))


func _process(delta: float) -> void:
	if _frames.size() > 1 and is_visible_in_tree():
		_t += delta
		texture = _frames[int(_t / FRAME_TIME) % _frames.size()]
