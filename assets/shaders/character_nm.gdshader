shader_type spatial;
// A character with its normal map, lit as StandardMaterial3D lights a glTF
// model (albedo, metal-roughness: roughness in G, metal in B), with the
// normal map's tangent frame worked out per pixel from how the surface and
// its UVs change across the screen (a "cotangent frame") instead of the
// mesh's tangents.
//
// Why (29 October, Player A's head from Gary's own file): on the Compatibility
// renderer (the phone link), a skinned mesh's tangents come out of Godot
// 4.7's skinning pass mangled (its transform-feedback shader decodes the
// tangent it encoded the other way), so a normal map on a rigged character
// shades every island of the atlas from a different side, in patches. The
// unskinned mesh, and Forward+, were fine. This needs no tangents at all.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mr_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float metallic_k = 1.0;
uniform float roughness_k = 1.0;
uniform float normal_strength = 1.0;
// which way the normal map's x and y run against the UVs (Godot's own, as
// StandardMaterial3D reads a glTF normal map: measured with tests/nm_check.gd)
uniform float sign_t = 1.0;
uniform float sign_b = -1.0;

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	ALBEDO = a.rgb;
	vec4 mr = texture(mr_tex, UV);
	METALLIC = mr.b * metallic_k;
	ROUGHNESS = mr.g * roughness_k;
	vec3 n = normalize(NORMAL);
	// the UVs' way across the surface at this pixel: solved from how the
	// place and the UVs change one pixel right and one down, signed by the
	// UVs' own winding so it comes out the same whichever way the screen's
	// axes run (GL's y is up, Vulkan's and Metal's down: Forward+ on the
	// iPhone and the Mac)
	highp vec3 dp1 = dFdx(VERTEX);
	highp vec3 dp2 = dFdy(VERTEX);
	highp vec2 duv1 = dFdx(UV);
	highp vec2 duv2 = dFdy(UV);
	highp float det = duv1.x * duv2.y - duv2.x * duv1.y;
	highp vec3 t = (dp1 * duv2.y - dp2 * duv1.y) * sign(det);
	highp vec3 b = (dp2 * duv1.x - dp1 * duv2.x) * sign(det);
	t -= n * dot(n, t);
	b -= n * dot(n, b);
	if (det != 0.0 && dot(t, t) > 1e-24 && dot(b, b) > 1e-24) {
		// x and y from the map, z rebuilt (as StandardMaterial3D does: a
		// normal map imported for the GPU may keep only two channels)
		vec3 nm = vec3(texture(normal_tex, UV).rg * 2.0 - 1.0, 0.0);
		nm.z = sqrt(max(0.0, 1.0 - dot(nm.xy, nm.xy)));
		nm.xy *= normal_strength;
		NORMAL = normalize(normalize(t) * sign_t * nm.x + normalize(b) * sign_b * nm.y + n * nm.z);
	}
}
