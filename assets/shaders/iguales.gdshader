shader_type canvas_item;
// "Todos iguales", de a poco: cómo ve él a una persona a medida que se le va la cabeza.
// amount 0: la persona como es. Primero se le apagan los colores; después sus pixeles se van cambiando,
// uno por uno y siempre los mismos, por los del maniquí gris (iguales.png), hasta que no queda nadie.
// La hoja de la persona y same_tex tienen la misma distribución (celdas de 16x26), así que el mismo UV
// cae en el mismo cuadro. Ver CharacterFrames.dress().

uniform sampler2D same_tex : filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

varying vec4 tint;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 own = texture(TEXTURE, UV);
	vec4 same = texture(same_tex, UV);
	// Se apaga: hacia un gris un poco frío.
	float drain = smoothstep(0.0, 0.6, amount) * 0.85;
	float g = dot(own.rgb, vec3(0.3, 0.59, 0.11));
	own.rgb = mix(own.rgb, vec3(g) * vec3(0.96, 0.96, 1.0), drain);
	// Se borra: cada pixel de la celda tiene su turno (el mismo en todos los cuadros: no titila al caminar).
	vec2 px = mod(floor(UV / TEXTURE_PIXEL_SIZE), vec2(16.0, 26.0));
	float gone = smoothstep(0.35, 1.0, amount);
	COLOR = (hash(px) < gone ? same : own) * tint;
}
