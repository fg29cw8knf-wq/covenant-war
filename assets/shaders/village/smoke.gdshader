shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, unshaded;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 smoke_col : source_color = vec3(0.12, 0.11, 0.11);
uniform float opacity = 0.55;
uniform vec3 glow_tint = vec3(1.0);
varying float age;
varying float seed;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	age = INSTANCE_CUSTOM.y;
	seed = INSTANCE_CUSTOM.x;
}
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float n = fbm(UV * 3.0 + vec2(seed * 11.0, -TIME * 0.2));
	float a = smoothstep(1.0, 0.2, d + (n - 0.5) * 0.8);
	a *= smoothstep(0.0, 0.2, age) * smoothstep(1.0, 0.6, age) * opacity;
	vec3 hot = vec3(0.55, 0.16, 0.04) * smoothstep(0.45, 0.0, age);
	ALBEDO = (smoke_col * (0.7 + 0.6 * n) + hot) * glow_tint;
	ALPHA = a;
}
