shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, skip_vertex_transform, shadows_disabled, fog_disabled;
// A falling Sigil streak: a camera-facing ribbon along the node's local Y axis.
instance uniform vec4 col : source_color = vec4(1.0, 0.5, 0.2, 1.0);
instance uniform float intensity = 12.0;
uniform float width = 0.16;
void vertex() {
	vec3 axis = MODEL_MATRIX[1].xyz;
	float len = length(axis);
	vec3 along = axis / len;
	vec3 center = MODEL_MATRIX[3].xyz;
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - center);
	vec3 side = normalize(cross(along, to_cam));
	float w = width * mix(0.25, 1.0, UV.y) * length(MODEL_MATRIX[0].xyz);
	vec3 wp = center + along * VERTEX.y * len + side * VERTEX.x * w * 2.0;
	VERTEX = (VIEW_MATRIX * vec4(wp, 1.0)).xyz;
}
void fragment() {
	float t = clamp(UV.y, 0.0, 1.0); // 1 at the head (bottom of the quad), 0 at the tail
	float ax = (UV.x - 0.5) * 5.0;
	float across = exp(-ax * ax);
	float cx = (UV.x - 0.5) * 16.0;
	float coreb = exp(-cx * cx);
	float along_f = pow(t, 2.4);
	vec3 c = col.rgb * across * along_f + vec3(1.0) * coreb * pow(t, 6.0) * 0.8;
	ALBEDO = c * intensity;
}
