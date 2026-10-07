shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Soft billboard halo.
instance uniform vec4 col : source_color = vec4(1.0, 0.6, 0.3, 1.0);
instance uniform float intensity = 4.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float g = exp(-d * d * 6.0) + exp(-d * 18.0) * 2.0;
	g *= smoothstep(1.0, 0.85, d);
	ALBEDO = col.rgb * g * intensity + vec3(1.0) * exp(-d * 40.0) * intensity * 0.5;
}
