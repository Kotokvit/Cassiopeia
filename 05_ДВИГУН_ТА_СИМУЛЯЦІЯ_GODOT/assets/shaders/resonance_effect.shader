// ResonanceEffect.shader — Visual effect for rune activation
// Creates a pulsing resonance aura with rune-specific color

shader_type spatial;
render_mode blend_add, depth_draw_neutral, cull_disabled;

uniform vec4 rune_color : source_color = vec4(0.2, 0.6, 0.8, 1.0);
uniform float intensity : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float echo_level : hint_range(0.0, 50.0) = 0.0;

void fragment() {
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float echo_factor = echo_level / 50.0;
	float alpha = intensity * pulse * (0.3 + echo_factor * 0.7);
	
	vec3 final_color = rune_color.rgb * (1.0 + echo_factor * 2.0);
	
	ALBEDO = final_color;
	ALPHA = alpha;
	EMISSION = final_color * (1.0 + echo_factor);
}
