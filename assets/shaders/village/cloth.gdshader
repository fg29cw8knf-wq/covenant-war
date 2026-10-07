shader_type spatial;
render_mode cull_disabled, diffuse_burley;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 col_a : source_color = vec3(0.55, 0.08, 0.06);
uniform vec3 col_b : source_color = vec3(0.85, 0.78, 0.6);
uniform float stripes = 8.0;
void fragment() {
	float s = step(0.5, fract(UV.x * stripes));
	vec3 c = mix(col_a, col_b, s) * (0.85 + 0.15 * vnoise(UV * vec2(200.0, 4.0)));
	ALBEDO = c;
	ROUGHNESS = 0.85;
	BACKLIGHT = c * 0.6;
}
