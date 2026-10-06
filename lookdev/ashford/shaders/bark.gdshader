shader_type spatial;
render_mode diffuse_burley;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"
uniform vec3 bark_a : source_color = vec3(0.16, 0.13, 0.10);
uniform vec3 bark_b : source_color = vec3(0.07, 0.06, 0.05);
void fragment() {
	float n = vnoise(vec2(UV.x * 18.0, UV.y * 2.5)) * 0.6 + vnoise(vec2(UV.x * 50.0, UV.y * 8.0)) * 0.4;
	float cracks = smoothstep(0.35, 0.2, n);
	ALBEDO = mix(bark_a, bark_b, cracks) * (0.8 + 0.3 * vnoise(UV * 6.0));
	ROUGHNESS = 0.95;
	NORMAL_MAP = vec3(0.5 + (n - 0.5) * 0.6, 0.5, 1.0);
	AO = 1.0 - cracks * 0.5;
}
