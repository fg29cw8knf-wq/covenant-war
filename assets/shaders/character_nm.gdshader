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

// The jaw (18 November, Gary: "Can we make the players mouth move when they
// are eating the porridge"). The models have no jaw bone and no face shapes:
// one skin, a painted mouth. So the mouth is opened here: the skin below the
// line of the lips, on the front of the face and no wider than the jaw, is
// moved down the face and a little back (as a jaw swings on its hinge), most
// at the lower lip and the chin, fading out back along the jaw, out at the
// cheeks and down under the chin, so the neck and the collar stay still. The
// upper lip doesn't move, so the lips part. jaw_open 0 (the default) is the
// face as modelled, and costs nothing. jaw_frame takes a point of the mesh's
// own space (as skinned) to the mouth's: its origin between the lips, x
// across the face, y up it, z out of it (Figure3D.jaw sets them, a frame at
// a time, from the Head bone as it's drawn).
uniform float jaw_open = 0.0;
uniform float jaw_drop = 0.015;
uniform mat4 jaw_frame = mat4(1.0);
uniform vec3 jaw_way = vec3(0.0, -1.0, 0.0);
// A smile (18 November, Gary's yes: "Tilly: she gasps and smiles when the
// moth appears"): the corners of the mouth drawn up, out and a little back
// into the cheeks, and the cheeks over them lifted; the middle of the lips
// stays. mouth_half is from the middle of the lips to a corner, and
// mouth_size the face's size against the hero's (a child's is smaller): the
// distances here are his, in metres, and jaw_frame brings a smaller face up
// to them (Figure3D._set_jaw), so what's moved is moved mouth_size as far.
uniform float smile = 0.0;
uniform float mouth_half = 0.024;
uniform float mouth_size = 1.0;

void vertex() {
	if (jaw_open > 0.001 || smile > 0.001) {
		vec3 h = (jaw_frame * vec4(VERTEX, 1.0)).xyz;
		float front = smoothstep(-0.08, -0.02, h.z);
		if (jaw_open > 0.001) {
			// (18 November, later, for talk: parting the skin on the very line
			// of the lips, with the opening drawn dark, was tried. These
			// faces have no ring of points round the mouth to part along:
			// the opening came out jagged, a black notch across the hero's
			// lip. So the skin is still drawn out smoothly over a centimetre
			// from the lips down, as it was for the porridge.)
			float below = smoothstep(0.003, -0.009, h.y);
			float chin = smoothstep(-0.09, -0.05, h.y);
			float side = 1.0 - smoothstep(0.03, 0.06, abs(h.x));
			VERTEX += jaw_way * (jaw_drop * mouth_size * jaw_open * below * chin * front * side);
		}
		if (smile > 0.001) {
			// the mouth's own ways, in the mesh's space
			mat3 back = inverse(mat3(jaw_frame));
			vec3 across = normalize(back[0]) * sign(h.x);
			vec3 up = normalize(back[1]);
			vec3 out_of = normalize(back[2]);
			float ax = abs(h.x);
			float corner = exp(-pow((ax - mouth_half) / 0.011, 2.0)) * exp(-pow(h.y / 0.011, 2.0));
			float cheek = exp(-pow((ax - mouth_half * 1.4) / 0.02, 2.0)) * exp(-pow((h.y - 0.022) / 0.018, 2.0));
			VERTEX += (up * 0.0048 + across * 0.0032 - out_of * 0.002) * (corner * front * smile * mouth_size);
			VERTEX += (up * 0.0022 + out_of * 0.0012) * (cheek * front * smile * mouth_size);
		}
	}
}

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
