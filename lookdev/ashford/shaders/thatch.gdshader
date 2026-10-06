shader_type spatial;
render_mode diffuse_burley;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"

uniform vec3 straw : source_color = vec3(0.36, 0.28, 0.16);
uniform vec3 old_straw : source_color = vec3(0.20, 0.17, 0.12);
uniform float age : hint_range(0.0, 1.0) = 0.4;
void fragment() {
	vec2 uv = UV; // u: metres along the ridge, v: metres down the slope
	float strands = vnoise(vec2(uv.x * 38.0, uv.y * 1.6)) * 0.6 + vnoise(vec2(uv.x * 110.0, uv.y * 3.0)) * 0.4;
	float course = fract(uv.y / 0.32);
	float layer = smoothstep(0.0, 0.25, course) * (1.0 - 0.35 * smoothstep(0.7, 1.0, course));
	float patchn = fbm(uv * 0.6);
	vec3 c = mix(straw, old_straw, clamp(age + (patchn - 0.5) * 0.8, 0.0, 1.0));
	c *= 0.55 + 0.6 * strands;
	c *= 0.7 + 0.3 * layer;
	// moss
	c = mix(c, vec3(0.10, 0.13, 0.05), smoothstep(0.62, 0.8, fbm(uv * 1.5 + 3.0)) * 0.7);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
	float sx = vnoise(vec2((uv.x + 0.01) * 38.0, uv.y * 1.6)) - vnoise(vec2(uv.x * 38.0, uv.y * 1.6));
	NORMAL_MAP = normalize(vec3(-sx * 3.0 + 0.0, (layer - 0.6) * 0.4, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.5;
	AO = 0.6 + 0.4 * layer;
	BACKLIGHT = vec3(0.05, 0.035, 0.015);
}
