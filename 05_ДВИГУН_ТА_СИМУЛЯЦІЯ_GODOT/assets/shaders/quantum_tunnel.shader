// QuantumTunnel.shader — Visual effect for quantum tunnel creation
// Resonator-Editor (S-class) ability

shader_type spatial;
render_mode blend_add, depth_draw_neutral, cull_disabled;

uniform vec4 tunnel_color : source_color = vec4(0.3, 0.5, 0.9, 1.0);
uniform float tunnel_width : hint_range(0.1, 2.0) = 0.5;
uniform float distortion_amount : hint_range(0.0, 1.0) = 0.3;

void vertex() {
	VERTEX += normal * distortion_amount * sin(TIME * 5.0 + VERTEX.x * 10.0);
}

void fragment() {
	float ring = abs(fract(UV.y * 10.0 + TIME * 2.0) - 0.5) * 2.0;
	float alpha = smoothstep(tunnel_width, 0.0, ring) * 0.7;
	
	ALBEDO = tunnel_color.rgb;
	ALPHA = alpha;
	EMISSION = tunnel_color.rgb * 2.0;
}
