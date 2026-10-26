shader_type canvas_item;

uniform sampler2D sky_texture : source_color, filter_nearest, repeat_disable;
uniform vec2 sky_origin = vec2(400.0, 284.0);
uniform float art_scale = 0.75;
uniform vec2 lower_cloud_scroll = vec2(0.52, 0.68);
uniform vec2 upper_cloud_scroll = vec2(0.28, 0.52);
uniform float cloud_wind_speed = 4.0;
uniform vec4 time_sky_top : source_color = vec4(0.196, 0.157, 0.247, 1.0);
uniform vec4 time_sky_bottom : source_color = vec4(0.396, 0.333, 0.447, 1.0);
uniform float time_sky_blend : hint_range(0.0, 1.0) = 0.0;

varying vec2 world_position;
varying vec2 camera_origin;
varying vec2 camera_axis_x;
varying vec2 camera_axis_y;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	mat4 inverse_canvas = inverse(CANVAS_MATRIX);
	camera_origin = inverse_canvas[3].xy;
	camera_axis_x = inverse_canvas[0].xy;
	camera_axis_y = inverse_canvas[1].xy;
}

void fragment() {
	vec2 viewport_center = 0.5 / SCREEN_PIXEL_SIZE;
	vec2 camera_center = camera_origin + camera_axis_x * viewport_center.x + camera_axis_y * viewport_center.y;
	vec2 source_pixel = (world_position - sky_origin) / art_scale;
	// Scroll factors describe world travel: smaller values appear farther away.
	vec2 lower_pixel = source_pixel - camera_center * (vec2(1.0) - lower_cloud_scroll) / art_scale;
	vec2 upper_pixel = source_pixel - camera_center * (vec2(1.0) - upper_cloud_scroll) / art_scale;
	upper_pixel.x -= TIME * cloud_wind_speed / art_scale;
	float source_x = lower_pixel.x;
	float tile_index = 0.0;
	bool clouds_only = false;
	// Only this one section of the lower layer contains the moon.
	if (source_x < 0.0) {
		tile_index = floor(source_x / 574.0) - 1.0;
		clouds_only = true;
		source_x = 760.0 + mod(source_x, 574.0);
	} else if (source_x >= 1334.0) {
		tile_index = floor((source_x - 1334.0) / 574.0);
		clouds_only = true;
		source_x = 760.0 + mod(source_x - 1334.0, 574.0);
	}
	// Extend the edge sky colors vertically, avoiding cropped layer seams.
	vec2 uv = vec2(clamp(source_x, 0.5, 1333.5), clamp(lower_pixel.y, 0.5, 749.5)) / vec2(1334.0, 750.0);
	vec3 clear_sky = texture(sky_texture, vec2(1333.5 / 1334.0, clamp(source_pixel.y, 0.5, 749.5) / 750.0)).rgb;
	vec3 timed_sky = mix(time_sky_top.rgb, time_sky_bottom.rgb, clamp(source_pixel.y / 750.0, 0.0, 1.0));
	clear_sky = mix(clear_sky, timed_sky, time_sky_blend);
	vec3 lower_detail = texture(sky_texture, uv).rgb - texture(sky_texture, vec2(1333.5 / 1334.0, uv.y)).rgb;
	vec4 sky_color = vec4(clamp(clear_sky + lower_detail, vec3(0.0), vec3(1.0)), 1.0);
	if (clouds_only) {
		// Fixed variation per cloud group; keep the sky gradient at its original height.
		float height_offset = (fract(sin((tile_index + 3.0) * 127.1) * 43758.5453) - 0.5) * 400.0;
		vec2 cloud_uv = vec2(uv.x, clamp(lower_pixel.y - height_offset, 0.5, 749.5) / 750.0);
		vec3 cloud_detail = texture(sky_texture, cloud_uv).rgb - texture(sky_texture, vec2(1333.5 / 1334.0, cloud_uv.y)).rgb;
		sky_color = vec4(clamp(clear_sky + cloud_detail, vec3(0.0), vec3(1.0)), 1.0);
	}
	// A separate staggered layer fills the sky above the upper platforms.
	float upper_tile = floor((upper_pixel.x + 257.0) / 574.0);
	float upper_offset = (fract(sin((upper_tile + 7.0) * 93.7) * 24634.6345) - 0.5) * 240.0;
	vec2 upper_uv = vec2(
		(760.0 + mod(upper_pixel.x + 257.0, 574.0)) / 1334.0,
		clamp(upper_pixel.y + 420.0 - upper_offset, 0.5, 749.5) / 750.0
	);
	vec3 upper_cloud = texture(sky_texture, upper_uv).rgb - texture(sky_texture, vec2(1333.5 / 1334.0, upper_uv.y)).rgb;
	sky_color.rgb = clamp(sky_color.rgb + upper_cloud * 0.75, vec3(0.0), vec3(1.0));
	COLOR *= sky_color;
}
