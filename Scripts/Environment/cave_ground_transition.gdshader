shader_type canvas_item;

uniform sampler2D stone_texture : source_color, filter_linear, repeat_disable;
uniform bool left_edge = true;
uniform bool surface_row = true;
uniform bool stone_only = false;
varying vec2 tile_uv;
varying vec2 world_position;
varying vec4 sprite_tint;

void vertex() {
	tile_uv = (VERTEX + vec2(256.0)) / 512.0;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	sprite_tint = COLOR;
}

void fragment() {
	vec4 moss = texture(TEXTURE, UV);
	float value = dot(moss.rgb, vec3(0.299, 0.587, 0.114));
	vec3 moss_color = mix(vec3(value), moss.rgb, 0.5) * vec3(0.72, 0.83, 1.0);
	moss.rgb = mix(vec3(0.075, 0.08, 0.11), moss_color, smoothstep(0.0, 0.22, value));

	float inward = left_edge ? tile_uv.x : 1.0 - tile_uv.x;
	float contour = sin(world_position.y * 0.055) * 0.035 + sin(world_position.y * 0.12) * 0.025;
	float blend = smoothstep(0.18 + contour, 0.92 + contour, inward);
	if (surface_row) {
		blend *= smoothstep(0.22, 0.55, tile_uv.y);
	}
	// One continuous mirrored pattern spans every row, excluding the baked border.
	float depth = world_position.y - 620.0 + sin(world_position.x * 0.017) * 18.0 + sin(world_position.x * 0.043) * 7.0;
	vec2 stone_uv = 1.0 - abs(fract(vec2(world_position.x, depth) / 256.0) * 2.0 - 1.0);
	float stone_x = clamp(stone_uv.x, 0.5 / 320.0, 319.5 / 320.0);
	float stone_y = (80.0 + stone_uv.y * 216.0) / 320.0;
	vec4 stone = texture(stone_texture, vec2(stone_x, stone_y));
	if (stone_only) {
		COLOR = stone * sprite_tint;
	} else {
		stone.rgb *= vec3(0.83, 0.85, 0.95);
		float alpha = mix(moss.a, stone.a, blend);
		vec3 color = mix(moss.rgb * moss.a, stone.rgb * stone.a, blend) / max(alpha, 0.0001);
		COLOR = vec4(color, alpha) * sprite_tint;
	}
}
