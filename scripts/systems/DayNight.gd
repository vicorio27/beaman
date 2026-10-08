extends Node
## Luz del día en los lugares de afuera (spec, sección 20): amanecer azulado, mediodía,
## atardecer naranja, noche oscura. De noche se prenden los faroles y las vidrieras.
## Lo agrega Location en los lugares con `outdoor = true`.

## Hora (en horas) -> color de la luz. Se interpola entre puntos.
const KEYS := [
	[0.0, Color(0.36, 0.38, 0.62)],
	[5.0, Color(0.38, 0.4, 0.64)],
	[6.5, Color(0.78, 0.74, 0.86)],
	[8.0, Color(1, 1, 1)],
	[16.0, Color(1, 1, 1)],
	[18.0, Color(1.0, 0.84, 0.7)],
	[19.5, Color(0.6, 0.52, 0.66)],
	[20.5, Color(0.36, 0.38, 0.62)],
	[24.0, Color(0.36, 0.38, 0.62)],
]
## Nombres de nodos (prefijo) que dan luz de noche, y cómo.
const LIGHTS := {
	"lamp_on": {"offset": Vector2(8, -40), "scale": 1.6, "color": Color(1.0, 0.86, 0.55)},
	"bakery": {"offset": Vector2(0, -12), "scale": 2.0, "color": Color(1.0, 0.8, 0.45)},
	"cafe": {"offset": Vector2(0, -12), "scale": 1.5, "color": Color(0.95, 0.85, 0.6)},
}

var _modulate: CanvasModulate
var _lights: Array[PointLight2D] = []


func _ready() -> void:
	_modulate = CanvasModulate.new()
	get_parent().add_child.call_deferred(_modulate)
	var tex := _glow_texture()
	for node in get_parent().find_children("*", "", true, false):
		for prefix in LIGHTS:
			if node is Node2D and str(node.name).begins_with(prefix):
				var spec: Dictionary = LIGHTS[prefix]
				var l := PointLight2D.new()
				l.texture = tex
				l.texture_scale = spec["scale"]
				l.color = spec["color"]
				l.position = spec["offset"]
				node.add_child.call_deferred(l)
				_lights.append(l)
	_apply()


func _process(_delta: float) -> void:
	_apply()


func _apply() -> void:
	var h := fmod(TimeManager.minutes / 60.0, 24.0)
	var c := _color_at(h)
	_modulate.color = c
	# Cuanto más oscuro, más fuerte la luz de los faroles.
	var night := clampf((1.0 - c.v) / 0.5, 0.0, 1.0)
	for l in _lights:
		l.energy = night * 1.1
		l.enabled = night > 0.02


func _color_at(h: float) -> Color:
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if h >= a[0] and h <= b[0]:
			return (a[1] as Color).lerp(b[1], (h - a[0]) / maxf(0.001, b[0] - a[0]))
	return KEYS[0][1]


func _glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 96
	t.height = 96
	return t
