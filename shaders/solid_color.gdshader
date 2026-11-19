shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// Same soft lighting as world.gdshader, for single-colour shapes (the avatar).

uniform vec4 color : source_color = vec4(1.0);
uniform float sun_strength = 0.9;

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += ndl * ATTENUATION * LIGHT_COLOR / PI * sun_strength;
}
