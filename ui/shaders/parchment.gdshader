// Aged vellum: layered value noise for tone, fibres, stains, foxing and a burnt,
// ragged edge. Draw a rect in local coordinates and set rect_size to its size.
// Mobile-safe (no textures, 4-octave fbm), Compatibility renderer friendly.
shader_type canvas_item;

uniform vec2 rect_size = vec2(1000.0, 600.0);
uniform float seed = 0.0;
uniform vec4 base_color : source_color = vec4(0.914, 0.863, 0.753, 1.0);
uniform vec4 dark_color : source_color = vec4(0.845, 0.765, 0.610, 1.0);
uniform vec4 burn_color : source_color = vec4(0.200, 0.120, 0.060, 1.0);
uniform float burn_width = 34.0;
uniform float stain_strength = 0.45;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031 + seed * 0.0137);
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

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = local;
	float tone = fbm(p * 0.0028 + seed);
	vec3 col = mix(dark_color.rgb, base_color.rgb, smoothstep(0.25, 0.75, tone));
	// Fibres: long thin streaks along the page.
	float fib = noise(vec2(p.x * 0.35, p.y * 0.012 + seed)) * 0.6 + noise(vec2(p.x * 0.012, p.y * 0.3)) * 0.4;
	col *= 0.955 + 0.06 * fib;
	// Water stains with a darker tide line.
	float st = fbm(p * 0.0016 + vec2(seed * 3.1, 7.7));
	float stain = smoothstep(0.60, 0.66, st) * (1.0 - smoothstep(0.66, 0.80, st) * 0.4);
	col = mix(col, col * vec3(0.86, 0.78, 0.64), stain * stain_strength);
	// Foxing: sparse small brown spots.
	vec2 cell = floor(p / 22.0);
	float fx = step(0.992, hash(cell + 3.0));
	float spot = fx * (1.0 - smoothstep(2.0, 7.0, length(fract(p / 22.0) * 22.0 - 11.0)));
	col = mix(col, vec3(0.55, 0.38, 0.22), spot * 0.5);
	// Burnt, ragged edge.
	vec2 d = min(p, rect_size - p);
	float edge = min(d.x, d.y) + (fbm(p * 0.04 + seed) - 0.5) * 16.0;
	float burn = 1.0 - smoothstep(0.0, burn_width, edge);
	col = mix(col, burn_color.rgb, burn * burn * 0.9);
	float alpha = smoothstep(-1.0, 2.5, edge);
	COLOR = vec4(col, alpha * COLOR.a);
}
