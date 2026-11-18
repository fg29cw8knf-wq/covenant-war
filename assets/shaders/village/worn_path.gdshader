shader_type spatial;
render_mode depth_draw_opaque, diffuse_burley;
// A trodden path over the grass (18 November, Gary's yes to "a worn path
// from the tunnel down the slope"): bare earth down its middle, its edges
// broken into the grass, fading out where it runs out. UV.x is across it
// (0 .. 1), UV.y along it (0 at the tunnel .. 1 at its end).
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 earth_a : source_color = vec3(0.13, 0.10, 0.07);
uniform vec3 earth_b : source_color = vec3(0.085, 0.07, 0.05);
uniform vec3 grass : source_color = vec3(0.12, 0.17, 0.07);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float n = vnoise(wpos.xz * 4.0);
	float m = vnoise(wpos.xz * 1.3 + vec2(7.0, 3.0));
	float across = abs(UV.x - 0.5) * 2.0;
	// the bare middle, its edge wandering in and out
	float edge = 0.62 + 0.22 * (n - 0.5) * 2.0 + 0.12 * (m - 0.5) * 2.0;
	float wear = 1.0 - smoothstep(edge - 0.22, edge, across);
	// worn thinner towards its end, and gone
	wear *= 1.0 - smoothstep(0.72, 1.0, UV.y);
	// tufts of grass left in it
	wear *= 1.0 - smoothstep(0.7, 0.82, vnoise(wpos.xz * 9.0));
	vec3 earth = mix(earth_a, earth_b, smoothstep(0.3, 0.7, m)) * (0.85 + 0.3 * n);
	ALBEDO = earth;
	ALPHA = wear;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.96;
}
