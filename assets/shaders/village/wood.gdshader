shader_type spatial;
render_mode diffuse_burley;
#include "res://assets/shaders/village/noise.gdshaderinc"

uniform vec3 wood_a : source_color = vec3(0.22, 0.14, 0.08);
uniform vec3 wood_b : source_color = vec3(0.12, 0.08, 0.05);
uniform vec3 grain_axis = vec3(0.0, 1.0, 0.0);
uniform float plank = 0.0; // plank width in metres, 0 = none
uniform float paint : hint_range(0.0, 1.0) = 0.0;
uniform vec3 paint_col : source_color = vec3(0.15, 0.25, 0.20);
varying vec3 lpos;
varying vec3 lnrm;
void vertex() { lpos = VERTEX; lnrm = NORMAL; }
void fragment() {
	vec3 ga = normalize(grain_axis);
	vec3 an = abs(lnrm);
	vec3 cross_ax = normalize(cross(ga, an.x > 0.5 ? vec3(1,0,0) : (an.y > 0.5 ? vec3(0,1,0) : vec3(0,0,1))) + vec3(1e-4));
	float g = dot(lpos, ga);
	float c = dot(lpos, cross_ax);
	float pidx = plank > 0.0 ? floor(c / plank) : 0.0;
	float pf = plank > 0.0 ? fract(c / plank) : 0.5;
	float grain = vnoise(vec2(c * 40.0 + pidx * 13.0, g * 1.5)) * 0.6 + vnoise(vec2(c * 120.0, g * 4.0)) * 0.4;
	vec3 col = mix(wood_b, wood_a, grain) * (0.8 + 0.3 * hash12(vec2(pidx, 1.0)));
	float gap = plank > 0.0 ? smoothstep(0.0, 0.04, pf) * smoothstep(1.0, 0.96, pf) : 1.0;
	col *= mix(0.25, 1.0, gap);
	if (paint > 0.0) {
		float chip = smoothstep(0.55, 0.7, fbm(vec2(c, g) * 4.0));
		col = mix(col, paint_col * (0.85 + 0.15 * grain), paint * (1.0 - chip));
	}
	ALBEDO = col;
	ROUGHNESS = 0.85;
	SPECULAR = 0.3;
	AO = mix(0.4, 1.0, gap);
}
