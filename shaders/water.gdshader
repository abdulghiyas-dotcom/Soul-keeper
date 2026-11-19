shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
// Calm water: soft ripples and shimmering highlights. Works on WebGL 2.

uniform vec4 shallow : source_color = vec4(0.62, 0.84, 0.90, 0.82);
uniform vec4 deep : source_color = vec4(0.42, 0.70, 0.80, 0.88);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(TIME * 1.3 + world_pos.x * 2.1 + world_pos.z * 1.7) * 0.012;
}

void fragment() {
	float r = sin(TIME * 1.6 + world_pos.x * 5.0 + sin(world_pos.z * 3.0 + TIME)) * 0.5 + 0.5;
	float s = smoothstep(0.92, 1.0, sin(TIME * 2.0 + world_pos.z * 7.0 + world_pos.x * 3.0) * 0.5 + 0.5);
	vec4 col = mix(deep, shallow, r * 0.6);
	ALBEDO = col.rgb + vec3(s * 0.25);
	ALPHA = col.a;
	ROUGHNESS = 0.15;
	SPECULAR = 0.7;
}
