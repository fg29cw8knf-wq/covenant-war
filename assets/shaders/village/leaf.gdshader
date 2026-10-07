shader_type spatial;
render_mode cull_disabled, diffuse_burley;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform sampler2D leaves : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.35, 0.45, 0.2);
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = vnoise(wp.xz * 0.2 + TIME * 0.3) - 0.5;
	VERTEX += vec3(w, 0.0, w * 0.6) * 0.08;
}
void fragment() {
	vec4 t = texture(leaves, UV);
	ALBEDO = t.rgb * tint * COLOR.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.7;
	BACKLIGHT = vec3(0.25, 0.3, 0.1);
	SPECULAR = 0.3;
}
