// BioluminescentFlora.shader — Dark/black flora with weak bioluminescence
// Plants on Cassiopeia absorb all incident photons → almost black
// Bioluminescence provides weak light source

shader_type spatial;

uniform vec4 glow_color : source_color = vec4(0.1, 0.35, 0.2, 1.0);
uniform float glow_intensity : hint_range(0.0, 3.0) = 0.5;
uniform float glow_pulse_speed : hint_range(0.1, 5.0) = 0.8;

void fragment() {
	// Near-black base color (absorbs all incident light)
	vec3 base_color = vec3(0.02, 0.01, 0.03);
	
	// Bioluminescent pulse
	float pulse = sin(TIME * glow_pulse_speed) * 0.3 + 0.7;
	vec3 glow = glow_color.rgb * glow_intensity * pulse;
	
	ALBEDO = base_color;
	EMISSION = glow;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;
}
