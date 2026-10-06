shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"
uniform float intensity = 1.9;
varying float age;
varying float seed;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	age = INSTANCE_CUSTOM.y;
	seed = INSTANCE_CUSTOM.x;
}
void fragment() {
	vec2 uv = UV;
	vec2 p = uv - vec2(0.5, 0.72);
	float n = fbm(vec2(uv.x * 3.0 + seed * 7.0, uv.y * 2.0 + TIME * 2.5 + seed * 3.0));
	p.x += (n - 0.5) * 0.35 * (1.0 - uv.y);
	float shape = 1.0 - length(p * vec2(2.4, 1.3 + (1.0 - uv.y) * 0.4));
	shape += (n - 0.5) * 0.6;
	float f = smoothstep(0.0, 0.5, shape);
	float life = smoothstep(0.0, 0.15, age) * smoothstep(1.0, 0.5, age);
	f *= life;
	vec3 c = mix(vec3(0.75, 0.07, 0.01), vec3(1.0, 0.3, 0.03), smoothstep(0.05, 0.6, f));
	c = mix(c, vec3(1.0, 0.62, 0.22), smoothstep(0.8, 1.0, f));
	ALBEDO = c * intensity * (0.6 + 0.6 * f);
	ALPHA = clamp(f * 1.4, 0.0, 1.0);
}
