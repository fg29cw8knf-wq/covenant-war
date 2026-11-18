shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Dead bracken fronds (18 November, Gary's yes: "a few curled dead bracken
// fronds at the tunnel's foot"): coloured by their vertices, each one
// stirring in the wind from its root (UV.y 0) to its curled tip (1).
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 wind_dir = vec3(-0.84, 0.0, 0.3);
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float gust = vnoise(wp.xz * 0.4 + vec2(TIME * 0.5, TIME * 0.17));
	float w = UV.y * UV.y;
	vec3 dw = normalize(wind_dir + vec3(0.0001));
	vec3 off = dw * (0.03 * gust * w) + vec3(0.0, 0.0, 0.006 * sin(TIME * 6.1 + wp.x * 11.0) * w);
	mat3 m = mat3(MODEL_MATRIX);
	VERTEX += (transpose(m) * off) / max(dot(m[0], m[0]), 0.0001);
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.88;
	BACKLIGHT = COLOR.rgb * 0.35;
}
