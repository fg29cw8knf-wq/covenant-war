shader_type spatial;
render_mode diffuse_burley, cull_disabled;
#include "res://lookdev/ashford/shaders/noise.gdshaderinc"
// Paper lantern: glows brighter near the flame at the bottom.
uniform float energy = 2.2;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 tint = COLOR.rgb;
	float h = clamp(lp.y / 0.5 + 0.5, 0.0, 1.0);
	float ang = atan(lp.z, lp.x);
	float ribs = 0.75 + 0.25 * smoothstep(0.0, 0.3, abs(sin(ang * 4.0)));
	float bands = 0.8 + 0.2 * smoothstep(0.0, 0.15, abs(sin(lp.y * 18.0)));
	float fl = 0.85 + 0.15 * vnoise(vec2(TIME * 5.0, COLOR.a * 50.0));
	float b = mix(1.6, 0.55, h) * ribs * bands * fl;
	ALBEDO = tint * 0.4;
	EMISSION = tint * energy * b;
	ROUGHNESS = 0.9;
	BACKLIGHT = tint;
}
