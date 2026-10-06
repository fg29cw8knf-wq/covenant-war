shader_type spatial;
render_mode unshaded;
uniform float energy = 6.0;
void fragment() {
	ALBEDO = COLOR.rgb * energy;
}
