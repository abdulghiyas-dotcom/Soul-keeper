shader_type spatial;
render_mode unshaded;
// Self-lit surfaces (window glass, lamp bulbs) using the mesh's vertex colours.

uniform float brightness = 1.08;

void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * brightness;
}
