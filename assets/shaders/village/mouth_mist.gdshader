shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// A breath of cold mist out of the tunnel's mouth (18 November, Gary's yes
// to "a dark floor and a faint cold mist inside"): a soft round puff that
// drifts out along its own +z and up a little, swelling and thinning as it
// goes, then starts again from the dark; each puff in its own beat (phase).
// Billboarded about the up axis, so it's never seen edge-on.
uniform float phase = 0.0;
uniform float period = 7.0;
uniform float travel = 0.9;     // how far it drifts out (m, in its own frame)
uniform float strength = 0.22;
uniform vec3 col : source_color = vec3(0.72, 0.8, 0.95);
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
varying float k;
void vertex() {
	k = fract(TIME / period + phase);
	vec3 drift = vec3(0.0, 0.12 * k, travel * k);
	float grow = 0.7 + 0.8 * k;
	// face the camera about the up axis
	vec3 right = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	mat3 to_local = inverse(mat3(MODEL_MATRIX));
	vec3 r = normalize(to_local * right);
	vec3 u = normalize(to_local * vec3(0.0, 1.0, 0.0));
	VERTEX = drift + (r * VERTEX.x + u * VERTEX.y) * grow;
}
void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	// a soft round puff, its edge broken a little, thinning towards its foot
	float d = length(c * vec2(1.0, 1.25));
	float edge = 0.75 + 0.25 * sin(atan(c.y, c.x) * 5.0 + phase * 31.0 + TIME * 0.4);
	float puff = pow(clamp(1.0 - d / edge, 0.0, 1.0), 1.8) * smoothstep(1.0, 0.55, UV.y);
	float life = smoothstep(0.0, 0.2, k) * smoothstep(1.0, 0.55, k);
	// thinned where it meets the ground or the bank, so it never shows a
	// straight edge against them
	float dep = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, dep * 2.0 - 1.0);
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, dep);
#endif
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float behind = (-vp.z / vp.w) - (-VERTEX.z);
	float soft = smoothstep(0.0, 0.2, behind);
	ALBEDO = col;
	ALPHA = puff * life * strength * soft;
}
