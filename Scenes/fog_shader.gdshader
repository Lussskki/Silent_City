shader_type canvas_item;

uniform vec4 fog_color : source_color = vec4(0.65, 0.72, 0.78, 0.22);
uniform float speed = 0.03;
uniform float scale = 6.0;

float hash(vec2 p) 
{
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) 
{
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(
		mix(a, b, u.x),
		mix(c, d, u.x),
		u.y
	);
}

void fragment() 
{
	vec2 uv = UV;

	uv.x += TIME * speed;

	float n = noise(uv * scale);

	float alpha = smoothstep(0.35, 0.75, n);

	COLOR = vec4(
		fog_color.rgb,
		alpha * fog_color.a
	);
}