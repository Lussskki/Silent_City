shader_type canvas_item;
render_mode unshaded;

// Feather the new transparent fog silhouette and remove stray card-edge pixels.
uniform float feather_pixels : hint_range(0.0, 4.0, 0.25) = 1.5;
uniform vec2 card_fade = vec2(0.055, 0.10);
uniform float bottom_clear : hint_range(0.0, 0.25, 0.005) = 0.075;
uniform float bottom_fade : hint_range(0.01, 0.35, 0.005) = 0.17;

varying vec4 sprite_color;


void vertex() {
	sprite_color = COLOR;
}


void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE * feather_pixels;
	vec4 center = texture(TEXTURE, UV);
	vec4 left = texture(TEXTURE, UV + vec2(-pixel.x, 0.0));
	vec4 right = texture(TEXTURE, UV + vec2(pixel.x, 0.0));
	vec4 up = texture(TEXTURE, UV + vec2(0.0, -pixel.y));
	vec4 down = texture(TEXTURE, UV + vec2(0.0, pixel.y));

	float alpha_sum = center.a * 4.0 + left.a + right.a + up.a + down.a;
	vec3 color_sum = center.rgb * center.a * 4.0;
	color_sum += left.rgb * left.a + right.rgb * right.a;
	color_sum += up.rgb * up.a + down.rgb * down.a;
	float soft_alpha = alpha_sum / 8.0;
	vec3 soft_color = color_sum / max(alpha_sum, 0.0001);

	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	vec2 card_feather = smoothstep(vec2(0.0), card_fade, edge_distance);
	float distance_from_bottom = 1.0 - UV.y;
	float bottom_mask = smoothstep(bottom_clear, bottom_fade, distance_from_bottom);
	float edge_mask = card_feather.x * card_feather.y * bottom_mask;

	COLOR = vec4(soft_color * sprite_color.rgb, soft_alpha * sprite_color.a * edge_mask);
}
