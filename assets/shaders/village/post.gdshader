shader_type canvas_item;
#include "res://assets/shaders/village/noise.gdshaderinc"
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float vignette = 0.42;
uniform float grain = 0.025;
uniform float aberration = 0.0005;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dc = uv - 0.5;
	float r = dot(dc, dc);
	vec3 c;
	c.r = texture(screen, uv + dc * aberration * 4.0).r;
	c.g = texture(screen, uv).g;
	c.b = texture(screen, uv - dc * aberration * 4.0).b;
	c *= mix(1.0, 1.0 - vignette, smoothstep(0.08, 0.55, r));
	c += (hash12(uv * 1000.0 + fract(TIME) * 100.0) - 0.5) * grain;
	COLOR = vec4(c, 1.0);
}
