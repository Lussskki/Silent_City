shader_type canvas_item;
render_mode unshaded;

uniform int window_count = 0;
uniform vec4 window_rect_1 = vec4(-1.0);
uniform vec4 window_rect_2 = vec4(-1.0);
uniform vec4 window_rect_3 = vec4(-1.0);
uniform vec4 window_rect_4 = vec4(-1.0);
uniform vec4 window_rect_5 = vec4(-1.0);

bool is_inside(vec2 uv, vec4 rect) {
	return uv.x >= rect.x && uv.y >= rect.y
		&& uv.x <= rect.x + rect.z && uv.y <= rect.y + rect.w;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	bool in_window = (window_count > 0 && is_inside(UV, window_rect_1))
		|| (window_count > 1 && is_inside(UV, window_rect_2))
		|| (window_count > 2 && is_inside(UV, window_rect_3))
		|| (window_count > 3 && is_inside(UV, window_rect_4))
		|| (window_count > 4 && is_inside(UV, window_rect_5));

	// Only replace luminous yellow/orange pixels. Frames, masonry, and alpha stay intact.
	bool warm_light = source.r > 0.42 && source.g > 0.20 && source.b < 0.46
		&& source.r > source.b * 1.35 && source.g > source.b * 1.08;
	if (in_window && warm_light) {
		float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
		vec3 moonlit_dark = vec3(0.035, 0.050, 0.080)
			+ value * vec3(0.095, 0.115, 0.155);
		source.rgb = mix(source.rgb, moonlit_dark, 0.94);
	}

	COLOR = source * COLOR;
}
