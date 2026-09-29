shader_type canvas_item;

// Old VHS fast-forward look over whatever is already drawn on screen.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float shake_px = 6.0;
uniform float line_jitter_px = 3.0;
uniform float band_jitter_px = 24.0;
uniform float band_noise = 0.3;
uniform float chroma_px = 3.0;
uniform float band_speed = 0.65;
uniform float frame_rate = 30.0;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	float frame = floor(TIME * frame_rate);
	vec2 uv = SCREEN_UV;

	vec2 shake = vec2(hash11(frame * 1.7 + 3.0) - 0.5, hash11(frame * 2.3 + 11.0) - 0.5);
	uv += shake * shake_px * px * intensity;

	float line = floor(uv.y / px.y / 3.0);
	float jitter = (hash21(vec2(line, frame)) - 0.5) * line_jitter_px;

	float bands = 0.0;
	for (int i = 0; i < 2; i++) {
		float fi = float(i);
		float center = fract(TIME * (band_speed + fi * 0.37) + fi * 0.53);
		float d = abs(uv.y - center);
		d = min(d, 1.0 - d);
		bands = max(bands, smoothstep(0.032 + fi * 0.014, 0.0, d));
	}
	jitter += bands * (hash21(vec2(line * 0.7, frame + 5.0)) - 0.5) * band_jitter_px;
	uv.x += jitter * px.x * intensity;

	float ca = chroma_px * px.x * intensity * (1.0 + bands * 2.0);
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;

	float grain = hash21(floor(FRAGCOORD.xy / vec2(4.0, 2.0)) + frame * 7.0);
	col = mix(col, vec3(grain), bands * band_noise * intensity);
	col += (grain - 0.5) * 0.05 * intensity;

	float scan = 0.5 + 0.5 * sin(FRAGCOORD.y * 3.14159 / 3.0);
	col *= 1.0 - 0.10 * scan * intensity;

	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(luma), 0.12 * intensity);
	col *= mix(vec3(1.0), vec3(1.03, 1.0, 0.94), intensity);

	COLOR = vec4(col, 1.0);
}
