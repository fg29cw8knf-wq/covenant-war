shader_type spatial;
render_mode diffuse_burley, cull_disabled;
#include "res://assets/shaders/village/noise.gdshaderinc"

// A leaded window seen from inside on a frosty morning (the taproom's
// windows, 29 October): diamond panes of old, uneven glass with the white
// day behind them, frost creeping in from the frame.
uniform vec3 day : source_color = vec3(0.80, 0.87, 1.0);
uniform float energy = 1.5;
uniform vec2 panes = vec2(3.0, 4.0); // diamonds across and up the whole window
uniform float seed = 0.0;

void fragment() {
	vec2 uv = UV;
	vec2 d = vec2(uv.x * panes.x + uv.y * panes.y, uv.x * panes.x - uv.y * panes.y) + seed;
	vec2 g = min(fract(d), 1.0 - fract(d));
	float lead = 1.0 - smoothstep(0.025, 0.07, min(g.x, g.y));
	float frame = 1.0 - smoothstep(0.0, 0.03, min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y)));
	lead = max(lead, frame);
	// each pane its own old glass: a shade greener or bluer, rippled
	float tint = hash12(floor(d) + seed);
	vec3 glass = day * mix(vec3(0.86, 0.94, 0.9), vec3(1.0, 1.0, 1.04), tint) * (0.88 + 0.12 * vnoise(uv * vec2(38.0, 52.0) + seed));
	// rime: thick at the frame and the leads, feathering into the panes
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float frost = smoothstep(0.22, 0.0, edge) * 0.55 + smoothstep(0.16, 0.0, min(g.x, g.y)) * 0.35;
	frost *= 0.6 + 0.6 * fbm(uv * 11.0 + seed);
	glass = mix(glass, vec3(0.96, 0.98, 1.0), clamp(frost, 0.0, 0.85));
	ALBEDO = mix(glass * 0.25, vec3(0.035, 0.033, 0.03), lead);
	EMISSION = glass * energy * (1.0 - lead) * (0.82 + 0.18 * uv.y);
	ROUGHNESS = mix(0.15, 0.55, lead);
	METALLIC = lead * 0.4;
}
