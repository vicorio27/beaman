shader_type canvas_item;
// PLOMO a lo Doom: pisos y techos con textura. Cada pixel de abajo (o de arriba) del horizonte es un
// punto del piso (o del techo) a cierta distancia; se busca qué casilla es en el mapa de casillas
// (R: piso, G: techo, 255 = cielo; B: luz) y se pinta con su cuadro del atlas, más oscuro de lejos.

uniform sampler2D flats : filter_nearest, repeat_enable;
uniform sampler2D cells : filter_nearest;
uniform float n_flats = 8.0;
uniform vec2 map_size = vec2(32.0, 24.0);
uniform vec2 cam_pos;
uniform vec2 cam_dir;
uniform vec2 cam_plane;
uniform float view_w = 320.0;
uniform float view_h = 148.0;
uniform vec4 sky_top : source_color;
uniform vec4 sky_bottom : source_color;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	float y = floor(UV.y * view_h) + 0.5;
	float x = floor(UV.x * view_w) + 0.5;
	float half_h = view_h * 0.5;
	bool is_floor = y > half_h;
	float p = max(abs(y - half_h), 0.5);
	float dist = half_h / p;
	vec2 ray = cam_dir + cam_plane * (2.0 * x / view_w - 1.0);
	vec2 w = cam_pos + ray * dist;
	vec4 c = texture(cells, (floor(w) + 0.5) / map_size);
	float idx = floor((is_floor ? c.r : c.g) * 255.0 + 0.5);
	if (!is_floor && idx > 254.0) {
		COLOR = mix(sky_top, sky_bottom, y / half_h);
	} else {
		vec2 f = fract(w);
		vec4 t = texture(flats, vec2((idx + f.x) / n_flats, f.y));
		float light = clamp(1.25 - dist * 0.085, 0.12, 1.0) * c.b;
		COLOR = vec4(t.rgb * light * (is_floor ? 1.0 : 0.85), 1.0) * tint;
	}
}
