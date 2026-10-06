shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 ember_col : source_color = vec3(1.0, 0.45, 0.1);
uniform float intensity = 14.0;
varying float age;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	age = INSTANCE_CUSTOM.y;
}
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float g = exp(-d * d * 8.0);
	ALBEDO = ember_col * g * intensity * (1.0 - age) * COLOR.rgb;
}
