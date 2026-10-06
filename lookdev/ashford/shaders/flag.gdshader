shader_type spatial;
render_mode cull_disabled, diffuse_burley;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.z += sin(TIME * 2.5 + wp.x * 0.7 + wp.z * 0.5) * 0.04 * (1.0 - UV.y);
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.8;
	BACKLIGHT = COLOR.rgb * 0.7;
}
