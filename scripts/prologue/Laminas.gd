extends Node2D
## Las láminas del prólogo: mientras se cuenta lo que pasó (Huida.gd, INTRO), cada texto trae su viñeta
## animada, del mismo motor que las de las noches (tools/art/draw_vinetas.py, hoja "prologo").
##   show_page(i)  muestra la viñeta del texto i (11: los techos, 12: el río, 13: "así no fue").
##   clear()       la quita.
## Cabe arriba del cuadro de diálogo (y < 114) y a la izquierda de los botones del celular (x < 286).

const SCALE := 1.1

var _pic: Vineta


func _ready() -> void:
	_pic = Vineta.new()
	_pic.position = Vector2(14, 3)
	_pic.scale = Vector2(SCALE, SCALE)
	_pic.modulate.a = 0.0
	add_child(_pic)


func show_page(i: int) -> void:
	_pic.show_row("prologo", i)
	_pic.modulate.a = 0.0
	create_tween().tween_property(_pic, "modulate:a", 1.0, 0.35)


func clear() -> void:
	_pic.modulate.a = 0.0
