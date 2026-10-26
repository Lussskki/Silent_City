shader_type canvas_item;

uniform float wind_strength : hint_range(0.0, 5.0) = 1.0;
uniform float bend_base : hint_range(0.0, 1.0) = 0.95;
uniform float bend_height : hint_range(0.01, 1.0) = 0.5;
uniform float bend_amount : hint_range(0.0, 0.15) = 0.065;
uniform float sway_speed = 2.0;
uniform float sway_amplitude = 0.25;
varying float instance_phase;

void vertex() {
	instance_phase = MODEL_MATRIX[3].x * 0.017;
}

void fragment() {
	float height_weight = pow(clamp((bend_base - UV.y) / bend_height, 0.0, 1.0), 2.0);
	float flutter = 0.65 + sin(TIME * sway_speed + instance_phase) * sway_amplitude
		+ sin(TIME * sway_speed * 2.3 + instance_phase) * 0.1;
	vec2 sample_uv = UV;
	sample_uv.x -= height_weight * bend_amount * wind_strength * flutter;
	if (sample_uv.x < 0.0 || sample_uv.x > 1.0) { discard; }
	COLOR *= texture(TEXTURE, sample_uv);
}
