shader_type spatial;
render_mode diffuse_burley;
#include "res://assets/shaders/village/noise.gdshaderinc"

uniform sampler2D path_mask : filter_linear, repeat_disable;
uniform float path_extent = 120.0;
uniform vec3 grass_a : source_color = vec3(0.10, 0.16, 0.06);
uniform vec3 grass_b : source_color = vec3(0.16, 0.20, 0.08);
uniform vec3 dirt : source_color = vec3(0.20, 0.15, 0.10);
uniform vec3 field_brown : source_color = vec3(0.17, 0.13, 0.08);

varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = wpos.xz;
	float n1 = fbm(p * 0.08);
	float n2 = vnoise(p * 0.9);
	float n3 = vnoise(p * 4.0);
	// patchwork fields
	vec2 fp = p / 34.0 + vec2(fbm(p * 0.02), fbm(p * 0.02 + 7.0)) * 0.8;
	vec2 cell = floor(fp);
	float ch = hash12(cell);
	vec3 g = mix(grass_a, grass_b, n1);
	g *= 0.75 + 0.5 * n2;
	float r = length(p);
	if (r > 55.0) {
		vec3 fc = mix(g, g * vec3(1.15, 1.05, 0.7), step(0.6, ch));
		fc = mix(fc, field_brown * (0.8 + 0.3 * n3), step(0.85, ch));
		// furrows on ploughed fields
		float fur = 0.5 + 0.5 * sin(dot(p, normalize(vec2(1.0, ch * 3.0))) * 3.0);
		fc *= mix(1.0, 0.75 + 0.25 * fur, step(0.85, ch));
		g = mix(g, fc, smoothstep(55.0, 70.0, r));
	}
	vec2 muv = p / (path_extent * 2.0) + 0.5;
	float pm = texture(path_mask, muv).r;
	pm = smoothstep(0.25, 0.75, pm + (n2 - 0.5) * 0.35);
	vec3 d = dirt * (0.7 + 0.5 * n3) * (0.85 + 0.3 * n1);
	ALBEDO = mix(g, d, pm);
	ROUGHNESS = mix(0.95, 0.85, pm);
	SPECULAR = 0.3;
	// gentle bumps
	float e = 0.15;
	float hx = vnoise((p + vec2(e, 0.0)) * 4.0) - n3;
	float hz = vnoise((p + vec2(0.0, e)) * 4.0) - n3;
	vec3 wn = normalize(vec3(-hx * 0.15, 1.0, -hz * 0.15));
	vec3 base_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 nn = normalize(base_n + (wn - vec3(0.0, 1.0, 0.0)));
	NORMAL = normalize((VIEW_MATRIX * vec4(nn, 0.0)).xyz);
}
