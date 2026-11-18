shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// The attic bed's wool blanket (18 November, Gary's yes to "a soft blanket
// that folds over him"). cloth.gdshader with what a thick wool blanket has
// that a flat colour hasn't:
// - small soft creases and the wool's nap in its surface (a height worked
//   out from where a point is on the cloth, in metres, and the light bent by
//   its slope; no texture and no tangents: the slope's own frame is found
//   per pixel, as character_nm does);
// - its stripes woven, their edges a thread or two uneven, each a little
//   mottled as dyed wool is;
// - a soft bloom of light where it turns away from the eye (the nap);
// - its hollows darker: how deep in a fold each point lies is in the
//   mesh's colour (BlanketDrape's "shade": 1 in the open, less in a fold).
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 col_a : source_color = vec3(0.3, 0.1, 0.07);
uniform vec3 col_b : source_color = vec3(0.16, 0.15, 0.11);
uniform float stripes = 3.0;
// the cloth's size (m): along it (UV.x) and across it (UV.y)
uniform vec2 size = vec2(1.42, 0.96);
// how much the creases and the nap stand in its surface (0 none)
uniform float crease = 1.0;
// how dark a fold's depth is (0 not at all .. 1 as dark as the mesh says)
uniform float hollow = 1.0;

// How high the cloth's surface stands at a point of it (m, a couple of
// millimetres at most): soft creases that wander along it and across it,
// and the nap.
float surface(vec2 m) {
	vec2 w = vec2(vnoise(m * 3.1 + 7.0), vnoise(m * 3.1 + 41.0)) - 0.5;
	float a = vnoise((m + w * 0.25) * vec2(5.0, 17.0));
	float b = vnoise((m - w * 0.2) * vec2(15.0, 6.0) + 23.0);
	float ridge_a = 1.0 - abs(a * 2.0 - 1.0);
	float ridge_b = 1.0 - abs(b * 2.0 - 1.0);
	float nap = vnoise(m * 240.0) + 0.5 * vnoise(m * 610.0);
	return 0.0021 * ridge_a * ridge_a + 0.0014 * ridge_b * ridge_b + 0.00016 * nap;
}

void fragment() {
	vec2 m = UV * size;
	// the stripes down its length, their edges a thread or two uneven
	// (uneven by the nearest edge's own wander, the same either side of it)
	float edge = (vnoise(vec2(m.y * 90.0, floor(UV.x * stripes * 2.0 + 0.5))) - 0.5) * 0.006;
	float f = fract(UV.x * stripes + edge * stripes / size.x);
	float px = fwidth(UV.x * stripes) + 0.004;
	float s = smoothstep(0.5 - px, 0.5 + px, f) * (1.0 - smoothstep(1.0 - 2.0 * px, 1.0, f));
	vec3 c = mix(col_a, col_b, clamp(s, 0.0, 1.0));
	// dyed wool: mottled a little, and the weft showing across it
	c *= 0.8 + 0.18 * vnoise(m * vec2(210.0, 9.0)) + 0.12 * fbm(m * 26.0);
	float shade = mix(1.0, COLOR.r, hollow);
	ALBEDO = c * mix(0.85, 1.0, shade);
	ROUGHNESS = 0.92;
	AO = shade;
	AO_LIGHT_AFFECT = 0.3;
	BACKLIGHT = c * 0.45;
	RIM = 0.3;
	RIM_TINT = 0.75;
	// the creases and the nap: the light bent by the surface's slope
	if (crease > 0.001) {
		vec3 n = normalize(NORMAL);
		highp vec3 dp1 = dFdx(VERTEX);
		highp vec3 dp2 = dFdy(VERTEX);
		highp vec2 duv1 = dFdx(UV);
		highp vec2 duv2 = dFdy(UV);
		highp float det = duv1.x * duv2.y - duv2.x * duv1.y;
		highp vec3 t = (dp1 * duv2.y - dp2 * duv1.y) * sign(det);
		highp vec3 b = (dp2 * duv1.x - dp1 * duv2.x) * sign(det);
		t -= n * dot(n, t);
		b -= n * dot(n, b);
		if (det != 0.0 && dot(t, t) > 1e-24 && dot(b, b) > 1e-24) {
			// (the nap's too fine to stand in the picture from across the
			// room: the slope is taken over what a pixel covers, at least)
			float e = max(0.0012, 0.75 * length(fwidth(m)));
			float h0 = surface(m);
			float hx = surface(m + vec2(e, 0.0));
			float hy = surface(m + vec2(0.0, e));
			vec2 slope = vec2(hx - h0, hy - h0) / e * crease;
			NORMAL = normalize(n - normalize(t) * slope.x - normalize(b) * slope.y);
		}
	}
}
