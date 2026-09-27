// Ink-bleed wipe: blots of iron-gall ink spread from the page edges and seep inward
// until the screen is covered (progress 1), then recede (progress back to 0).
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink : source_color = vec4(0.078, 0.063, 0.051, 1.0);
uniform vec2 rect_size = vec2(1080.0, 1920.0);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 uv = local / rect_size;
	float n = noise(local * 0.006) * 0.55 + noise(local * 0.02) * 0.3 + noise(local * 0.07) * 0.15;
	vec2 c = abs(uv - 0.5) * 2.0;
	float edge = 1.0 - max(c.x, c.y * 0.9);
	float field = edge * 0.75 + n * 0.45;
	float t = progress * 1.35;
	float a = smoothstep(field - 0.03, field + 0.03, t);
	// A slightly lighter wet rim at the advancing front.
	float rim = smoothstep(field - 0.09, field - 0.03, t) - a;
	COLOR = vec4(mix(ink.rgb, vec3(0.22, 0.05, 0.04), clamp(rim, 0.0, 1.0)), max(a, rim * 0.8));
}
