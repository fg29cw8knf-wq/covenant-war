shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// A prop that moves in the wind and catches the moon at its edges
// (18 November, Gary's yeses: "make the thorn bushes and the bank's ferns
// sway a little in the wind"; "put a moonlit edge on the bank and bushes, so
// the mouth stands out from the dark behind Corin"). Its own colour,
// roughness-metal and normal maps, lit as StandardMaterial3D lights them.
//
// How far each vertex moves is painted into UV2.x by tools/add_sway.py (0
// still: a trunk, the earth, a timber; 1 free: a twig's end, a fern's tip).
// The wind is a slow push along wind_dir with a gust rolling across the
// ground (each thing in its own beat, from where it stands) and a quick
// flutter on top, smaller.
//
// rim_k > 0 adds a cold edge where the surface turns away from the camera
// (a fresnel), as moonlight from behind would draw it; the hillside sets it
// by the time of day (none by day).
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D mr_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_on = 1.0;
uniform float metallic_k = 1.0;
uniform float roughness_k = 1.0;
uniform vec3 wind_dir = vec3(-0.84, 0.0, 0.3);
uniform float sway = 0.06;      // the most a free part is pushed (m, in the world)
uniform float flutter = 0.012;  // the quick shiver on top (m)
uniform float rim_k = 0.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float desat = 0.0;
uniform vec3 rim_col : source_color = vec3(0.55, 0.66, 1.0);

void vertex() {
	float w = UV2.x;
	if (w > 0.001) {
		vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 base = MODEL_MATRIX[3].xyz;
		float gust = vnoise(base.xz * 0.15 + vec2(TIME * 0.35, TIME * 0.11));
		float push = (0.35 + 0.65 * gust) * (0.6 + 0.4 * sin(TIME * 1.3 + base.x * 0.7 + base.z * 0.5));
		float shiver = sin(TIME * 7.3 + wp.x * 9.0 + wp.y * 6.0) * 0.6 + sin(TIME * 11.1 + wp.z * 13.0) * 0.4;
		vec3 dw = normalize(wind_dir + vec3(0.0001));
		vec3 off = dw * (sway * push * w) + vec3(0.0, -0.25 * sway * push * w * w, 0.0) + vec3(dw.z, 0.4, -dw.x) * (flutter * shiver * w);
		// the push said in the model's own frame and its own size (turned and
		// evenly scaled only: the transpose over the scale squared undoes it)
		mat3 m = mat3(MODEL_MATRIX);
		VERTEX += (transpose(m) * off) / max(dot(m[0], m[0]), 0.0001);
	}
}

void fragment() {
	vec4 a = texture(albedo_tex, UV);
	float grey = dot(a.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = mix(a.rgb, vec3(grey), desat) * tint;
	vec4 mr = texture(mr_tex, UV);
	METALLIC = mr.b * metallic_k;
	ROUGHNESS = mr.g * roughness_k;
	if (normal_on > 0.5) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	if (rim_k > 0.001) {
		float f = 1.0 - clamp(dot(normalize(NORMAL), VIEW), 0.0, 1.0);
		EMISSION = rim_col * pow(f, 3.0) * rim_k * (0.4 + 0.6 * a.g);
	}
}
