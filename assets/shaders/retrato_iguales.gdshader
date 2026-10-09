shader_type canvas_item;
// "Todos iguales" en los retratos de los diálogos: igual que iguales.gdshader, pero sobre el busto
// entero (72x88). amount 0: la persona como es; se le apagan los colores y sus pixeles se cambian, uno
// por uno, por los del maniquí gris sin cara (assets/portraits/iguales.png). Ver Dialogue.gd.

uniform sampler2D same_tex : filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 own = texture(TEXTURE, UV);
	vec4 same = texture(same_tex, UV);
	float drain = smoothstep(0.0, 0.6, amount) * 0.85;
	float g = dot(own.rgb, vec3(0.3, 0.59, 0.11));
	own.rgb = mix(own.rgb, vec3(g) * vec3(0.96, 0.96, 1.0), drain);
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	float gone = smoothstep(0.35, 1.0, amount);
	COLOR = hash(px) < gone ? same : own;
}
