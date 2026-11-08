// PerceptionMode.shader — Visual overlay for ℘ (Perception) mode
// Highlights semantic nodes: vulnerabilities, patrol routes, resonance hotspots

shader_type canvas_item;
render_mode blend_add;

uniform vec4 highlight_color : source_color = vec4(0.2, 0.6, 0.9, 0.5);
uniform float scan_line_speed : hint_range(0.5, 5.0) = 1.5;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Scan lines sweeping across screen
	float scan_line = fract(UV.y + TIME * scan_line_speed * 0.1);
	scan_line = smoothstep(0.0, 0.02, scan_line) * smoothstep(0.04, 0.02, scan_line);
	
	// Vignette effect
	vec2 center = UV - vec2(0.5);
	float vignette = 1.0 - length(center) * vignette_intensity * 2.0;
	vignette = clamp(vignette, 0.0, 1.0);
	
	// Combine
	vec3 color = highlight_color.rgb * (scan_line * 0.3 + 0.1) * vignette;
	float alpha = (scan_line * 0.2 + 0.05) * vignette * highlight_color.a;
	
	COLOR.rgb += color;
	COLOR.a += alpha;
}
