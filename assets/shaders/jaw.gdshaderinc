// The jaw and the smile, shared by the people's shader (character_nm) and
// the coat-and-cloak wind shader (ShardSet.WEATHER: Bram in the snow, 18
// November, Gary's yes to mouths in time with the voices). Included at the
// top level; jaw_move() is called first thing in vertex().

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

// The inside of the mouth (18 November, Gary's yes: "a proper jaw ... so
// mouths really open"). The models have no inside to their mouths and no
// ring of points round the lips to part them along (a split along the lip
// line came out as a jagged black notch). So the opening is drawn instead,
// a pixel at a time, from where each point of the skin was before the jaw
// moved it (mouth_h, in the mouth's own frame): the skin drawn out between
// the lips as the jaw drops is darkened to the dark of a mouth, deepest in
// the middle of that stretch and narrowing to nothing at the corners, with
// the edge of the upper teeth just showing under the upper lip when it's
// open wide. Shut (jaw_open 0) it's the face as modelled.
varying vec3 mouth_h;
uniform vec3 mouth_dark : source_color = vec3(0.13, 0.045, 0.04);
uniform vec3 teeth_col : source_color = vec3(0.74, 0.7, 0.62);
uniform float mouth_k = 1.0;

// Where a point of the mesh is in the mouth's frame (before the jaw moves it).
vec3 jaw_h(vec3 v) {
	return (jaw_frame * vec4(v, 1.0)).xyz;
}

// The skin's colour with the open mouth's inside drawn over it.
vec3 mouth_shade(vec3 albedo, vec3 h) {
	if (jaw_open < 0.02 || mouth_k < 0.001) {
		return albedo;
	}
	float front = smoothstep(-0.08, -0.02, h.z);
	// across: the opening's lens, widest in the middle, shut at the corners
	float ax = abs(h.x) / max(mouth_half * 1.05, 0.005);
	float lens = clamp(1.0 - ax * ax, 0.0, 1.0);
	// up and down: the stretch of skin the jaw drew out (where `below`
	// climbs, jaw_move), most at its middle; and less of it opens the
	// further from the middle of the lips
	float below = smoothstep(0.003, -0.009, h.y);
	float mid = 1.0 - abs(2.0 * below - 1.0);
	float open = clamp(jaw_open * 1.4, 0.0, 1.0);
	float dark = pow(mid, 0.7) * sqrt(lens) * front * open * mouth_k;
	// it narrows as it closes: only the middle of the stretch at first
	dark *= smoothstep(1.0 - open * 0.9, 1.0, mid + 0.35 * lens);
	vec3 c = mix(albedo, mouth_dark, clamp(dark * 1.15, 0.0, 0.92));
	// the upper teeth: the top of the opening, under the upper lip, wide open
	float teeth = smoothstep(0.35, 0.75, open) * smoothstep(0.0, 0.25, below) * (1.0 - smoothstep(0.25, 0.5, below)) * lens * front;
	return mix(c, teeth_col, clamp(teeth * dark * 1.6, 0.0, 0.55));
}

vec3 jaw_move(vec3 v) {
	vec3 p = v;

	if (jaw_open > 0.001 || smile > 0.001) {
		vec3 h = (jaw_frame * vec4(p, 1.0)).xyz;
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
			p += jaw_way * (jaw_drop * mouth_size * jaw_open * below * chin * front * side);
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
			p += (up * 0.0048 + across * 0.0032 - out_of * 0.002) * (corner * front * smile * mouth_size);
			p += (up * 0.0022 + out_of * 0.0012) * (cheek * front * smile * mouth_size);
		}
	}
	return p;
}

// The hero's hands closing (18 November, Gary's yes: "let the hero's
// fingers bend ... so he can close his own hand"). His model's finger bones
// sit in a heap at his knuckles and his skin doesn't follow them
// (Figure3D.FROZEN), so his fingers are curled here instead: every point
// of the hand beyond its knuckle line is bent round towards the palm as a
// rod bends, more the further out it is, `grip` 0 open (as modelled, in
// its relaxed curl) to 1 a closed fist (GRIP_MOST at the fingertips). Each
// hand's frame is its knuckle line's middle, x across, y along the
// fingers, z out of the palm (Figure3D.HANDS, from his skin), in metres;
// hand_back its inverse.
uniform float grip_l = 0.0;
uniform float grip_r = 0.0;
uniform mat4 hand_frame_l = mat4(1.0);
uniform mat4 hand_back_l = mat4(1.0);
uniform mat4 hand_frame_r = mat4(1.0);
uniform mat4 hand_back_r = mat4(1.0);
uniform vec2 hand_size_l = vec2(0.09, 0.06);   // the fingers' length, the hand's half width
uniform vec2 hand_size_r = vec2(0.09, 0.06);
const float GRIP_MOST = 2.4;

void hand_curl(inout vec3 v, inout vec3 nrm, mat4 fr, mat4 back, float grip, vec2 size) {
	vec3 h = (fr * vec4(v, 1.0)).xyz;
	if (h.y <= 0.0 || h.y > size.x * 1.5 || abs(h.x) > size.y * 1.2 || abs(h.z) > 0.035) {
		return;
	}
	float k = grip * (1.0 - smoothstep(size.y, size.y * 1.2, abs(h.x))) * (1.0 - smoothstep(0.025, 0.035, abs(h.z)));
	if (k < 0.001) {
		return;
	}
	// a rod of length size.x bent through GRIP_MOST * k: its radius
	float r = size.x / (GRIP_MOST * k);
	float th = min(h.y, size.x * 1.2) / r;
	float rz = r - h.z;
	vec3 hb = vec3(h.x, rz * sin(th), r - rz * cos(th));
	// (past the fingertips' length it goes straight on)
	hb.yz += vec2(cos(th), sin(th)) * max(h.y - size.x * 1.2, 0.0);
	v = (back * vec4(hb, 1.0)).xyz;
	vec3 nh = mat3(fr) * nrm;
	float c = cos(th);
	float sn = sin(th);
	nh = vec3(nh.x, c * nh.y - sn * nh.z, sn * nh.y + c * nh.z);
	nrm = normalize(mat3(back) * nh);
}

void hands_move(inout vec3 v, inout vec3 nrm) {
	if (grip_l > 0.001) {
		hand_curl(v, nrm, hand_frame_l, hand_back_l, grip_l, hand_size_l);
	}
	if (grip_r > 0.001) {
		hand_curl(v, nrm, hand_frame_r, hand_back_r, grip_r, hand_size_r);
	}
}
