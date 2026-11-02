shader_type canvas_item;

uniform vec4 rock_color : source_color = vec4(0.075, 0.08, 0.11, 1.0);
uniform vec4 moss_tint : source_color = vec4(0.72, 0.83, 1.0, 1.0);
uniform float saturation : hint_range(0.0, 1.0) = 0.5;
uniform float dark_base_fade : hint_range(0.0, 1.0) = 0.0;
uniform float dark_base_canvas_height = 768.0;
varying vec4 sprite_tint;
varying float source_y;

void vertex() {
	sprite_tint = COLOR;
	source_y = VERTEX.y / dark_base_canvas_height + 0.5;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float value = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 moss = mix(vec3(value), source.rgb, saturation) * moss_tint.rgb;
	vec3 shaded = mix(rock_color.rgb, moss, smoothstep(0.0, 0.22, value));
	float base_alpha = mix(1.0, smoothstep(0.0, 0.06, value), dark_base_fade * smoothstep(0.65, 0.85, source_y));
	COLOR = vec4(shaded, source.a * base_alpha) * sprite_tint;
}
