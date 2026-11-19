shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// The world's surfaces: vertex colours, soft matte light with shadows.
// Our own light() keeps brightness identical on every device and browser.

uniform float sun_strength = 0.9;

void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(2.2));
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI * sun_strength;
}
