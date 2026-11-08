// OverheatingOverlay.shader — Visual warning for body temperature exceeding threshold
// Red pulse overlay when body temp > 40.8°C

shader_type canvas_item;
render_mode blend_add;

uniform float temperature : hint_range(36.0, 42.0) = 36.6;
uniform float threshold : hint_range(38.0, 42.0) = 40.8;

void fragment() {
	float heat_factor = clamp((temperature - threshold) / (42.0 - threshold), 0.0, 1.0);
	float pulse = sin(TIME * 4.0) * 0.5 + 0.5;
	
	vec3 danger_color = vec3(1.0, 0.2, 0.05);
	float alpha = heat_factor * pulse * 0.4;
	
	// Edge distortion effect
	vec2 uv = UV;
	uv.x += sin(UV.y * 20.0 + TIME * 3.0) * heat_factor * 0.01;
	
	COLOR.rgb = danger_color * heat_factor;
	COLOR.a = alpha;
}
