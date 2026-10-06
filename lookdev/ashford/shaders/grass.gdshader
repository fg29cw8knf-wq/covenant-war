shader_type spatial;
render_mode cull_disabled, diffuse_burley;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"

uniform vec3 root_col : source_color = vec3(0.04, 0.07, 0.02);
uniform vec3 tip_col : source_color = vec3(0.13, 0.20, 0.06);
varying float hgt;
void vertex() {
	hgt = clamp(UV.y, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = sin(TIME * 1.3 + wp.x * 0.35 + wp.z * 0.22) * 0.5 + 0.5 * vnoise(wp.xz * 0.3 + TIME * 0.4);
	VERTEX.x += (w - 0.4) * 0.12 * UV.y * UV.y;
	VERTEX.z += (w - 0.5) * 0.06 * UV.y * UV.y;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.6));
}
void fragment() {
	float hh = clamp(hgt, 0.0, 1.0);
	vec3 c = mix(root_col, tip_col, pow(hh, 1.3));
	ALBEDO = c * COLOR.rgb;
	ROUGHNESS = 0.55;
	SPECULAR = 0.15;
	BACKLIGHT = vec3(0.25, 0.35, 0.12) * hgt;
	AO = mix(0.35, 1.0, hgt);
	AO_LIGHT_AFFECT = 0.6;
}
