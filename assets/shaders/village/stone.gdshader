shader_type spatial;
render_mode diffuse_burley;
#include "res://assets/shaders/village/noise.gdshaderinc"

uniform vec3 stone_a : source_color = vec3(0.34, 0.32, 0.29);
uniform vec3 stone_b : source_color = vec3(0.30, 0.27, 0.23);
uniform vec3 mortar : source_color = vec3(0.20, 0.19, 0.17);
uniform float course = 0.22;
uniform float block = 0.38;
uniform float whitewash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 plaster : source_color = vec3(0.78, 0.74, 0.66);

varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float stone_h(vec2 uv, out vec2 cid) {
	// irregular rubble stone: Voronoi cells stretched wider than tall
	vec2 sc = vec2(1.0 / block, 1.0 / course);
	vec2 w = uv * sc + (vec2(vnoise(uv * 2.5), vnoise(uv * 2.5 + 9.0)) - 0.5) * 0.35;
	vec2 i = floor(w);
	vec2 f = fract(w);
	float f1 = 8.0; float f2 = 8.0;
	vec2 best = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = hash22(i + g) * 0.8 + 0.1;
			float d = length((g + o - f) * vec2(1.0, 0.75));
			if (d < f1) { f2 = f1; f1 = d; best = i + g; }
			else if (d < f2) { f2 = d; }
		}
	}
	cid = best;
	float edge = f2 - f1;
	return smoothstep(0.0, 0.16, edge) * (0.85 + 0.15 * vnoise(uv * 9.0 + cid));
}
void fragment() {
	vec3 n = normalize(wnrm);
	vec3 an = abs(n);
	vec3 U; vec3 V = vec3(0.0, 1.0, 0.0);
	vec2 uv;
	if (an.y > 0.7) { U = vec3(1.0, 0.0, 0.0); V = vec3(0.0, 0.0, 1.0); uv = wpos.xz; }
	else if (an.x > an.z) { U = vec3(0.0, 0.0, 1.0); uv = vec2(wpos.z, wpos.y); }
	else { U = vec3(1.0, 0.0, 0.0); uv = vec2(wpos.x, wpos.y); }
	vec2 cid;
	float h = stone_h(uv, cid);
	vec2 c2;
	float hx = stone_h(uv + vec2(0.015, 0.0), c2) - h;
	float hy = stone_h(uv + vec2(0.0, 0.015), c2) - h;
	float sv = hash12(cid);
	vec3 sc = mix(stone_a, stone_b, sv) * (0.8 + 0.35 * vnoise(uv * 14.0 + sv * 10.0));
	sc = mix(sc, sc * vec3(0.8, 0.95, 0.7), smoothstep(0.6, 0.9, vnoise(uv * 2.0)) * 0.6); // lichen
	vec3 col = mix(mortar, sc, smoothstep(0.1, 0.5, h));
	float bump = 1.0;
	float ww = 0.0;
	if (whitewash > 0.0) {
		float wear = smoothstep(0.74, 0.9, vnoise(uv * 1.7)) * 0.75;
		ww = whitewash * (1.0 - wear);
		float grime = smoothstep(0.25, 0.75, vnoise(vec2(uv.x * 2.5, uv.y * 0.35)));
		vec3 pl = plaster * (0.9 + 0.1 * fbm(uv * 3.0)) * (0.78 + 0.22 * grime);
		col = mix(col, pl, ww);
		bump = 1.0 - ww;
	}
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
	vec3 wn = normalize(n - (hx * U + hy * V) * 7.0 * bump);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	AO = mix(mix(0.5, 1.0, h), 1.0, ww);
}
