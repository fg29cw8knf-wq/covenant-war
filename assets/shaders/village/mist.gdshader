shader_type fog;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform float density = 0.12;
uniform float top = 4.0;
uniform vec3 albedo : source_color = vec3(0.55, 0.6, 0.75);
void fog() {
	vec3 p = WORLD_POSITION;
	float n = fbm3(p * 0.06 + vec3(TIME * 0.03, 0.0, TIME * 0.015));
	float hgt = smoothstep(top, 0.0, p.y - 0.0);
	DENSITY = density * hgt * smoothstep(0.35, 0.75, n) * smoothstep(0.0, 0.15, UVW.x) * smoothstep(1.0, 0.85, UVW.x) * smoothstep(0.0, 0.15, UVW.z) * smoothstep(1.0, 0.85, UVW.z);
	ALBEDO = albedo;
}
