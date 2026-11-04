// Fluorescent troffer / emissive panel with diffuser ribs. Per-panel data comes
// from UV2 (x = seed, y = flicker 0..1; seed >= 100 marks a dead tube) so many
// panels batch into one mesh while still flickering independently.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 color : source_color = vec3(1.0, 0.97, 0.86);
uniform float energy = 2.5;
uniform float ribs = 18.0;
uniform float flicker = 1.0;     // global multiplier for UV2.y

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void fragment() {
	float rib = 0.85 + 0.15 * smoothstep(0.2, 0.5, abs(fract(UV.x * ribs) - 0.5));
	float edge = smoothstep(0.0, 0.08, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float seed = UV2.x;
	float fl = UV2.y * flicker;
	float f = 1.0;
	if (fl > 0.0) {
		float t = floor(TIME * 16.0 + seed * 7.0);
		float n = hash11(t + seed * 13.0);
		float burst = step(0.82, hash11(floor(TIME * 0.7 + seed)));
		f = (n < fl * 0.6 * burst + fl * 0.05) ? 0.12 + 0.35 * n : 1.0;
	}
	vec3 c = color * energy * rib * mix(0.6, 1.0, edge) * f;
	if (seed >= 100.0) {
		c = vec3(0.09, 0.09, 0.08);
	}
	ALBEDO = c;
}
