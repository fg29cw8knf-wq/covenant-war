shader_type canvas_item;
// The impact punch on the duel's 3D field (5 November, Gary: "I want it more
// dramatic"): for a few frames after a heavy blow the whole picture is
// smeared outward from where the blow landed (a radial blur), and its
// colours part a little at the edges (a chromatic punch), then it settles.
// DuelField3D sets it as its own container's material and tweens `strength`
// from a punch down to nothing (impact_punch); at 0 the picture is drawn as
// it is, one read a pixel. Only at Gfx.level() 2 (a Mac, or a phone set to
// Full): six reads a pixel at the screen's size for a fifth of a second.

uniform float strength : hint_range(0.0, 1.0) = 0.0;   // the punch, 1 at its hardest, 0 the picture as it is
uniform vec2 centre = vec2(0.5, 0.5);                   // where the blow landed on the screen (0-1 across and down)
uniform float reach = 0.07;                             // how far the smear runs at full strength (a share of the screen)
uniform float split = 0.014;                            // how far red and blue part from green at full strength

void fragment() {
	if (strength < 0.002) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec2 d = UV - centre;
		vec2 run = d * reach * strength;
		vec2 part = d * split * strength;
		vec3 sum = vec3(0.0);
		const int N = 6;
		for (int i = 0; i < N; i++) {
			vec2 uv = UV - run * (float(i) / float(N - 1));
			sum.r += texture(TEXTURE, uv + part).r;
			sum.g += texture(TEXTURE, uv).g;
			sum.b += texture(TEXTURE, uv - part).b;
		}
		COLOR = vec4(sum / float(N), 1.0);
	}
}
