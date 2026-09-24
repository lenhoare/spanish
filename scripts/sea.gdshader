shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 deep : source_color = vec4(0.07, 0.36, 0.8, 1.0);
uniform vec4 shallow : source_color = vec4(0.18, 0.6, 0.93, 1.0);
uniform vec4 sparkle : source_color = vec4(0.9, 0.97, 1.0, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_pos.x * 0.35 + TIME * 1.3) * 0.08 + cos(world_pos.z * 0.3 + TIME * 1.1) * 0.08;
}

void fragment() {
	float w = sin(world_pos.x * 0.45 + TIME * 0.9) * sin(world_pos.z * 0.5 - TIME * 0.7);
	float w2 = sin(world_pos.x * 1.7 - TIME * 1.6 + world_pos.z * 0.9);
	vec3 col = mix(deep.rgb, shallow.rgb, 0.35 + 0.25 * w);
	col = mix(col, sparkle.rgb, smoothstep(0.93, 1.0, w * w2) * 0.8);
	ALBEDO = col;
	ROUGHNESS = 0.25;
	SPECULAR = 0.6;
}
