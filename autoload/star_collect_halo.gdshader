shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec2 rect_size = vec2(120.0, 120.0);
uniform float star_radius_px = 24.0;
uniform float fade_px = 40.0;

void fragment() {
	vec2 px = (UV - vec2(0.5)) * rect_size;
	float d = length(px) - star_radius_px;
	float alpha = 1.0;
	if (d >= fade_px) {
		alpha = 0.0;
	} else if (d > 0.0) {
		float sigma = fade_px / 2.5;
		float g = exp(-0.5 * (d / sigma) * (d / sigma));
		float g_end = exp(-0.5 * (fade_px / sigma) * (fade_px / sigma));
		alpha = (g - g_end) / max(1.0 - g_end, 0.0001);
	}
	COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
