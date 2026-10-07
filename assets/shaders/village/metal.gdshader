shader_type spatial;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform vec3 base : source_color = vec3(0.08, 0.075, 0.07);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp.xy * 6.0 + wp.z * 3.0);
	ALBEDO = mix(base, vec3(0.18, 0.09, 0.04), smoothstep(0.55, 0.8, n));
	METALLIC = 0.8;
	ROUGHNESS = 0.45 + 0.4 * n;
}
