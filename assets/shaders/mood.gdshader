shader_type canvas_item;
// Filtro de pantalla con dos registros visuales:
//   distress = 0 -> mundo cálido (luz de mañana, colores vivos)
//   distress = 1 -> mundo interior (duotono frío, rojos que sobreviven, grano, viñeta)
//   memory   = 1 -> recuerdo (foto vieja quemada, parpadeo)
// La pantalla es de 320x180, así que el grano queda del tamaño de un píxel del juego.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float distress : hint_range(0.0, 1.0) = 0.0;
uniform float memory : hint_range(0.0, 1.0) = 0.0;
// Luto: después de que se muere Lukas, el mundo se va quedando sin color (gris frío).
uniform float grief : hint_range(0.0, 1.0) = 0.0;

uniform vec3 warm_tint = vec3(1.08, 1.0, 0.86);
uniform vec3 cold_shadow = vec3(0.03, 0.04, 0.06);
uniform vec3 cold_light = vec3(0.56, 0.64, 0.64);
uniform vec3 blood = vec3(0.62, 0.07, 0.09);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = floor(FRAGCOORD.xy);

	// Leve desfase de canales cuando el hambre aprieta.
	float ab = distress * distress * 0.006;
	vec3 col = vec3(
		texture(screen_tex, uv + vec2(ab, 0.0)).r,
		texture(screen_tex, uv).g,
		texture(screen_tex, uv - vec2(ab, 0.0)).b);
	float lum = luma(col);

	// Registro cálido: tinte de mañana y un poco más de saturación.
	vec3 warm = col * warm_tint;
	warm = mix(vec3(luma(warm)), warm, 1.2);

	// Registro frío: duotono, y los rojos se conservan como sangre/óxido.
	vec3 cold = mix(cold_shadow, cold_light, smoothstep(0.05, 0.95, lum));
	float redness = clamp((col.r - max(col.g, col.b)) * 2.5, 0.0, 1.0);
	cold = mix(cold, blood * (0.4 + lum), redness);
	float levels = mix(12.0, 4.0, distress);
	cold = floor(cold * levels + 0.5) / levels;

	col = mix(warm, cold, smoothstep(0.0, 1.0, distress));

	// Grano animado, del tamaño de un píxel.
	float grain = hash(px + fract(TIME * 7.0) * 100.0) - 0.5;
	col += grain * (0.03 + distress * 0.13);

	// Líneas horizontales sutiles.
	if (mod(px.y, 2.0) < 1.0) {
		col *= 1.0 - 0.07 * distress;
	}

	// Viñeta que "late" despacio cuando el hambre es fuerte.
	vec2 d = uv - 0.5;
	float pulse = 1.0 + distress * 0.15 * sin(TIME * 2.2);
	float vig = 1.0 - dot(d, d) * (0.5 + 2.0 * distress) * pulse;
	col *= clamp(vig, 0.0, 1.0);

	// Luto: sin color, un poco azul, un poco más oscuro.
	vec3 grey = vec3(luma(col)) * vec3(0.9, 0.94, 1.04) * (1.0 - 0.12 * grief);
	col = mix(col, grey, grief);

	// Memoria: sepia quemado, centro sobreexpuesto, parpadeo de proyector.
	vec3 sepia = vec3(lum) * vec3(1.25, 1.02, 0.72) + vec3(0.1, 0.05, 0.0);
	sepia = sepia * 0.88 + (1.0 - length(d) * 1.8) * 0.1;
	sepia *= 0.94 + 0.06 * hash(vec2(floor(TIME * 12.0), 3.0));
	sepia += (hash(px * 0.37 + floor(TIME * 12.0)) - 0.5) * 0.12;
	col = mix(col, sepia, memory);

	COLOR = vec4(col, 1.0);
}
