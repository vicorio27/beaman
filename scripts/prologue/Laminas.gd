extends Node2D
## Las láminas del prólogo: mientras se cuenta lo que pasó (Huida.gd, INTRO), cada texto trae su viñeta
## animada, del mismo motor que las de las noches (tools/art/draw_vinetas.py, hoja "prologo").
##   show_page(i)  muestra la viñeta del texto i (11: los techos, 12: el río, 13: "así no fue").
##   clear()       la quita.
## Cabe arriba del cuadro de diálogo (y < 114) y a la izquierda de los botones del celular (x < 286).
## Detrás va la misma viñeta, grande y oscura, de borde a borde: la pantalla nunca queda en negro.

const SCALE := 1.1
const BACK_SCALE := 1.9  # 456x190: tapa los 320x180 aunque la sacuda el tiro

var _back: Vineta
var _pic: Vineta


func _ready() -> void:
	_back = Vineta.new()
	_back.scale = Vector2(BACK_SCALE, BACK_SCALE)
	_back.position = Vector2(160 - 120 * BACK_SCALE, 90 - 50 * BACK_SCALE)
	_back.self_modulate = Color(0.3, 0.27, 0.33)
	_back.modulate.a = 0.0
	add_child(_back)
	_pic = Vineta.new()
	_pic.position = Vector2(14, 3)
	_pic.scale = Vector2(SCALE, SCALE)
	_pic.modulate.a = 0.0
	add_child(_pic)


func show_page(i: int) -> void:
	_back.show_row("prologo", i)
	_pic.show_row("prologo", i)
	_pic.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_pic, "modulate:a", 1.0, 0.35)
	t.parallel().tween_property(_back, "modulate:a", 1.0, 0.35)


func clear() -> void:
	_pic.modulate.a = 0.0
	create_tween().tween_property(_back, "modulate:a", 0.0, 0.3)
