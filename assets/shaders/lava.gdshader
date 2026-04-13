shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float time_scale : hint_range(0.05, 2.0) = 0.35;
uniform vec4 color_hot : source_color = vec4(1.0, 0.25, 0.0, 1.0);
uniform vec4 color_cool : source_color = vec4(0.55, 0.04, 0.0, 1.0);
uniform vec4 color_bright : source_color = vec4(1.0, 0.75, 0.15, 1.0);

void fragment() {
	vec2 uv = UV * 5.0;
	float t = TIME * time_scale;

	// Two scrolling noise layers at different speeds and scales
	float n1 = texture(noise_tex, uv + vec2(t * 0.28, t * 0.09)).r;
	float n2 = texture(noise_tex, uv * 0.6 + vec2(-t * 0.18, t * 0.13)).r;
	float n3 = texture(noise_tex, uv * 1.3 + vec2(t * 0.07, -t * 0.22)).r;

	// Combine with weighted blend
	float combined = n1 * 0.45 + n2 * 0.35 + n3 * 0.2;

	// Smooth color transitions
	vec3 col = mix(color_cool.rgb, color_hot.rgb, smoothstep(0.25, 0.65, combined));
	col = mix(col, color_bright.rgb, smoothstep(0.65, 0.85, combined));

	// Subtle pulsing glow
	float pulse = sin(t * 1.8 + uv.x * 2.5 + uv.y * 1.7) * 0.5 + 0.5;
	col += vec3(0.08, 0.015, 0.0) * pulse;

	// Dark crust patches at low values
	col = mix(vec3(0.18, 0.02, 0.0), col, smoothstep(0.1, 0.3, combined));

	COLOR = vec4(col, 1.0);
}
