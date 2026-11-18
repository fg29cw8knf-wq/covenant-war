shader_type spatial;
render_mode depth_draw_opaque, diffuse_burley, cull_back;
// A boot print pressed into the path's earth (18 November, Gary's yes to
// "footprints in the path's earth, leading out of the tunnel"). The quad's UV
// runs across the print (x) and from heel (y 0) to toe (y 1); its vertex
// colour's alpha says how clear it is (a print half on grass is faint).
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 earth : source_color = vec3(0.07, 0.055, 0.04);
uniform vec3 rim : source_color = vec3(0.16, 0.125, 0.085);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// the sole: a broad front and a narrower heel, joined at the waist
	float front = length((p - vec2(0.0, 0.35)) / vec2(0.85, 0.62));
	float heel = length((p - vec2(0.0, -0.62)) / vec2(0.62, 0.36));
	float waist = (abs(p.x) < 0.5 && p.y > -0.55 && p.y < 0.0) ? 0.9 : 2.0;
	float d = min(min(front, heel), waist);
	float n = vnoise(wpos.xz * 40.0);
	float inside = 1.0 - smoothstep(0.82, 1.0, d + (n - 0.5) * 0.25);
	// the pressed-up earth round its edge, and the tread across the sole
	float edge = smoothstep(0.75, 0.95, d) * (1.0 - smoothstep(0.95, 1.12, d));
	float tread = step(0.5, fract(p.y * 4.0 + 0.5)) * 0.25 * step(-0.2, p.y);
	ALBEDO = mix(earth * (1.0 - tread), rim, edge);
	ALPHA = max(inside, edge * 0.9) * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
}
