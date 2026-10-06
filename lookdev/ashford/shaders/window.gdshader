shader_type spatial;
render_mode diffuse_burley;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"

uniform vec3 glow : source_color = vec3(1.0, 0.58, 0.24);
uniform float energy = 3.5;
uniform float seed = 0.0;
void fragment() {
	vec2 uv = UV;
	// lead lines: a 2x3 grid of panes, and the frame
	vec2 g = vec2(fract(uv.x * 2.0), fract(uv.y * 3.0));
	float lead = smoothstep(0.0, 0.05, g.x) * smoothstep(1.0, 0.95, g.x) * smoothstep(0.0, 0.05, g.y) * smoothstep(1.0, 0.95, g.y);
	float frame = smoothstep(0.0, 0.06, uv.x) * smoothstep(1.0, 0.94, uv.x) * smoothstep(0.0, 0.06, uv.y) * smoothstep(1.0, 0.94, uv.y);
	float m = lead * frame;
	// warm interior with a curtain shadow and a candle flicker
	float flick = 0.88 + 0.12 * vnoise(vec2(TIME * 6.0 + seed * 10.0, seed));
	float curtain = mix(0.55, 1.0, smoothstep(0.08, 0.3, uv.x) * smoothstep(0.92, 0.7, uv.x));
	float grad = mix(1.15, 0.7, uv.y);
	float wobble = 0.85 + 0.15 * vnoise(uv * vec2(14.0, 20.0) + seed);
	vec3 e = glow * energy * flick * curtain * grad * wobble;
	ALBEDO = mix(vec3(0.03, 0.025, 0.02), vec3(0.2, 0.15, 0.1), m);
	EMISSION = e * m;
	ROUGHNESS = mix(0.8, 0.15, m);
	METALLIC = 0.0;
}
