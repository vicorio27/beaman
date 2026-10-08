class_name SideFrames
## Arma animaciones de las hojas de personajes de costado (celdas de 48x48, una animación por fila).
## Los personajes miran a la derecha; para la izquierda se espeja el sprite.

const CELL := 48

## Protagonista: nombre -> [fila, cantidad de cuadros, fps, loop, primer cuadro]
const PLAYER := {
	"idle": [0, 4, 6.0, true, 0],
	"walk": [1, 8, 10.0, true, 0],
	"punch": [2, 4, 16.0, false, 0],
	"punch2": [3, 3, 14.0, false, 0],
	"kick": [4, 6, 16.0, false, 0],
	"hurt": [7, 3, 12.0, false, 0],
	"fall": [8, 3, 8.0, false, 0],
	"crouch": [6, 1, 1.0, false, 0],
}

## Matones (goon, punk, thug comparten distribución).
const ENEMY := {
	"idle": [0, 1, 1.0, true, 0],
	"walk": [1, 8, 10.0, true, 0],
	"punch": [2, 3, 10.0, false, 0],
	"hurt": [4, 3, 12.0, false, 0],
	"fall": [5, 3, 8.0, false, 0],
	"getup": [7, 1, 1.0, false, 0],
	"stab": [3, 3, 10.0, false, 0],
}

## Jefe.
const BOSS := {
	"idle": [0, 1, 1.0, true, 0],
	"walk": [1, 8, 10.0, true, 0],
	"punch": [2, 4, 12.0, false, 0],
	"uppercut": [3, 3, 10.0, false, 0],
	"kick": [4, 5, 12.0, false, 0],
	"hurt": [5, 2, 12.0, false, 0],
	"fall": [6, 3, 8.0, false, 0],
	"getup": [7, 1, 1.0, false, 0],
	"guard": [8, 1, 1.0, true, 0],
	"run": [9, 8, 16.0, true, 0],
}

## Lilato (jefa final del sueño 1).
const LILATO := {
	"idle": [0, 2, 3.0, true, 0],
	"walk": [1, 4, 8.0, true, 0],
	"slash": [2, 3, 12.0, false, 0],
	"spin": [3, 4, 14.0, false, 0],
	"hurt": [4, 2, 12.0, false, 0],
	"fall": [5, 3, 8.0, false, 0],
	"getup": [6, 1, 1.0, false, 0],
	"transform": [7, 2, 6.0, true, 0],
}


static func build(sheet: Texture2D, table: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in table:
		var spec: Array = table[anim]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, spec[2])
		frames.set_animation_loop(anim, spec[3])
		for i in spec[1]:
			var t := AtlasTexture.new()
			t.atlas = sheet
			t.region = Rect2((spec[4] + i) * CELL, spec[0] * CELL, CELL, CELL)
			frames.add_frame(anim, t)
	return frames
