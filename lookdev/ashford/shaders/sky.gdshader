shader_type sky;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
#define CUBEPASS false
#else
#define CUBEPASS AT_CUBEMAP_PASS
#endif

uniform vec3 zenith : source_color = vec3(0.006, 0.011, 0.04);
uniform vec3 horizon : source_color = vec3(0.07, 0.085, 0.17);
uniform vec3 moon_dir = vec3(-0.84, 0.45, 0.30);
uniform vec3 tear_a = vec3(0.4777, 0.6691, -0.5693);
uniform vec3 tear_b = vec3(0.3726, 0.1045, -0.9222);
uniform float tear_open : hint_range(0.0, 1.5) = 1.0;
uniform float sky_dim : hint_range(0.0, 1.0) = 1.0;

vec3 tear_light(vec3 d, out float core) {
	vec3 a = normalize(tear_a);
	vec3 b = normalize(tear_b);
	vec3 n = normalize(cross(a, b));
	vec3 b2 = normalize(cross(n, a));
	float ang_total = acos(clamp(dot(a, b), -1.0, 1.0));
	float s = atan(dot(d, b2), dot(d, a)) / ang_total; // 0..1 along the tear
	float ends = smoothstep(-0.02, 0.25, s) * smoothstep(1.02, 0.75, s);
	// jagged path: offset the crack off the great circle
	float seg = s * 9.0;
	float k0 = floor(seg);
	float jag = mix(hash12(vec2(k0, 1.7)), hash12(vec2(k0 + 1.0, 1.7)), fract(seg)) - 0.5;
	float seg2 = s * 31.0;
	float k1 = floor(seg2);
	jag = jag * 0.035 + (mix(hash12(vec2(k1, 5.3)), hash12(vec2(k1 + 1.0, 5.3)), fract(seg2)) - 0.5) * 0.012;
	float dist = abs(dot(d, n) - jag);
	float width = 0.0010 + 0.0024 * ends;
	core = exp(-dist / width) * ends * step(-0.05, s) * step(s, 1.05);
	float glow1 = exp(-dist / (width * 4.0)) * ends;
	float glow2 = exp(-dist / 0.035) * ends;
	// colours bleeding out of the tear: violet, teal and gold along its length
	vec3 c = mix(vec3(0.55, 0.25, 1.0), vec3(0.15, 0.85, 0.95), smoothstep(0.15, 0.55, s));
	c = mix(c, vec3(1.0, 0.75, 0.3), smoothstep(0.6, 0.95, s));
	// small forks off the crack
	float fork = 0.0;
	for (int k = 0; k < 4; k++) {
		float fs = 0.18 + float(k) * 0.2;
		float side = (k % 2 == 0) ? 1.0 : -1.0;
		float along = s - fs;
		float fd = abs(dot(d, n) - jag - side * along * 0.35);
		float m = step(0.0, along) * smoothstep(0.08, 0.0, along);
		fork += exp(-fd / 0.0008) * m;
	}
	core = max(core, fork * 0.6);
	vec3 col = vec3(1.0, 0.97, 0.9) * core * 10.0 + c * glow1 * 1.1 + c * glow2 * 0.12;
	if (CUBEPASS) col *= 0.3;
	return col * tear_open;
}

void sky() {
	vec3 d = EYEDIR;
	float h = clamp(d.y, -1.0, 1.0);
	vec3 col = mix(horizon, zenith, pow(clamp(h, 0.0, 1.0), 0.45));
	// faint warm glow on the horizon from the village
	col += vec3(0.10, 0.05, 0.02) * exp(-max(h, 0.0) * 18.0) * 0.6;

	// stars
	if (h > 0.0 && !CUBEPASS) {
		vec3 sp = d * 260.0;
		vec3 cell = floor(sp);
		float r = hash13(cell);
		if (r > 0.985) {
			vec3 cp = cell + vec3(hash13(cell + 1.3), hash13(cell + 2.7), hash13(cell + 4.1));
			float dd = length(sp - cp);
			float tw = 0.7 + 0.3 * sin(TIME * (2.0 + r * 5.0) + r * 40.0);
			float b = smoothstep(0.35, 0.0, dd) * (r - 0.985) * 66.0 * tw;
			vec3 sc = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.9, 0.75), hash13(cell + 7.7));
			col += sc * b * 2.2 * smoothstep(0.0, 0.25, h);
		}
		// milky band
		col += vec3(0.05, 0.05, 0.09) * fbm(d.xz * 6.0) * smoothstep(0.1, 0.7, h) * 0.6;
	}

	// moon
	vec3 md = normalize(moon_dir);
	float mdot = dot(d, md);
	float disc = smoothstep(0.99965, 0.99972, mdot);
	vec2 muv = vec2(dot(d, normalize(cross(md, vec3(0,1,0)))), d.y - md.y) * 900.0;
	float maria = fbm(muv * 0.08 + 3.0);
	vec3 moon = vec3(0.95, 0.93, 0.85) * (0.75 + 0.35 * maria) * 9.0;
	col = mix(col, moon, disc);
	col += vec3(0.5, 0.55, 0.7) * pow(max(mdot, 0.0), 2200.0) * 1.5;
	col += vec3(0.12, 0.14, 0.22) * pow(max(mdot, 0.0), 60.0) * 0.6;

	// the tear
	float core;
	vec3 tl = tear_light(d, core);

	// clouds, lit from beneath by the tear and the village
	if (h > -0.05 && !CUBEPASS) {
		vec2 cuv = d.xz / (h + 0.12) * 0.55;
		float cl = fbm(cuv * 1.3 + vec2(TIME * 0.004, 0.0));
		cl = smoothstep(0.42, 0.78, cl + 0.08 * fbm(cuv * 5.0));
		float tear_near = 0.0;
		float c2;
		vec3 tglow = tear_light(normalize(d + vec3(0.0, 0.0, 0.0)), c2);
		vec3 cloud_col = vec3(0.025, 0.03, 0.06) + tglow * 0.25 + vec3(0.09, 0.06, 0.04) * exp(-h * 9.0);
		cloud_col += vec3(0.12, 0.13, 0.18) * pow(max(mdot, 0.0), 30.0);
		float cover = cl * smoothstep(-0.05, 0.12, h) * 0.92;
		col = mix(col, cloud_col, cover);
		tl *= mix(1.0, 0.55, cover * (1.0 - core));
	}
	col += tl;
	if (h < 0.0) col = mix(col, horizon * 0.4, smoothstep(0.0, -0.1, h));
	COLOR = col * sky_dim;
}
