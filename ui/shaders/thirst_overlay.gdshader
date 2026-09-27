// Thirst feedback over the whole screen. Every term keeps the centre of the screen
// (where the letter and tools live) clear: effects are weighted to the edges.
//   vignette 0..1  faint red vignette (40+)
//   ink      0..1  ink bleeding in from the corners (65+)
//   desat    0..1  desaturation (90+), strongest at the edges
//   pulse    0..1  heartbeat pulse amplitude (90+)
//   drip     0..1  blood drips from the top edge (threshold events, frenzy)
// Clear Mind sets everything but a static thin vignette to zero from script.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 rect_size = vec2(1080.0, 1920.0);
uniform float vignette = 0.0;
uniform float ink = 0.0;
uniform float desat = 0.0;
uniform float pulse = 0.0;
uniform float drip = 0.0;
uniform float time = 0.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float hash1(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
	vec2 uv = local / rect_size;
	vec3 scene = texture(screen_tex, SCREEN_UV).rgb;
	vec2 c = (uv - 0.5) * vec2(1.0, rect_size.y / rect_size.x);
	float r = length(c * vec2(1.0, 0.62));
	float beat = pulse * pow(0.5 + 0.5 * sin(time * 6.2), 6.0);
	float edge = smoothstep(0.38, 0.95, r + beat * 0.05);
	float grey = dot(scene, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(scene, vec3(grey), desat * (0.35 + 0.65 * edge));
	col = mix(col, vec3(0.45, 0.02, 0.02), edge * vignette * 0.55);
	float corner = smoothstep(0.55, 1.05, r) * ink;
	col = mix(col, vec3(0.06, 0.04, 0.03), corner * 0.85);
	// Drips: columns of blood from the top edge, confined to the top 6% (the title bar),
	// so they never run over the letter card or the tools.
	float colx = floor(uv.x * 36.0);
	float len = (0.015 + 0.045 * hash1(colx)) * drip;
	float w = 0.3 + 0.4 * hash1(colx + 7.0);
	float inside = step(abs(fract(uv.x * 36.0) - 0.5), w * 0.5) * step(uv.y, len);
	float bulb = step(length(vec2((fract(uv.x * 36.0) - 0.5) / 36.0, uv.y - len) * vec2(1.0, rect_size.y / rect_size.x)), 0.006 * drip);
	float d = max(inside * step(0.35, hash1(colx + 3.0)), bulb * step(0.35, hash1(colx + 3.0)));
	col = mix(col, vec3(0.42, 0.03, 0.03), d * 0.9);
	COLOR = vec4(col, 1.0);
}
