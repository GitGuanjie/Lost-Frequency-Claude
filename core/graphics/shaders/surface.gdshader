// LOST FREQUENCY — procedural surface uber-shader (in-project, no texture files).
// Patterns are evaluated in metre-space mesh UVs written by GeoKit; stains, grime
// and organic materials use 3D world-space noise (projection free).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 albedo_a : source_color = vec3(0.8, 0.75, 0.45);
uniform vec3 albedo_b : source_color = vec3(0.7, 0.65, 0.38);
uniform float noise_scale = 1.3;
uniform float noise_mix = 0.5;
// 0 none, 1 tiles, 2 stripes, 3 planks, 4 bricks, 5 dots, 6 carpet,
// 7 ceiling tiles, 8 chevron wallpaper, 9 checker, 10 damask, 11 rock strata,
// 12 grass, 13 sand ripples, 14 hex tiles, 15 terrazzo
uniform int pattern = 0;
uniform vec2 pattern_scale = vec2(0.5, 0.5);
uniform vec3 pattern_color : source_color = vec3(0.6, 0.55, 0.3);
uniform float pattern_strength = 0.3;
uniform float grout_width = 0.03;
uniform vec3 grout_color : source_color = vec3(0.6, 0.6, 0.6);
uniform float tile_variation = 0.06;
uniform float roughness_a = 0.85;
uniform float roughness_b = 0.95;
uniform float metallic_value = 0.0;
uniform float bump_strength = 0.6;
uniform vec3 stain_color : source_color = vec3(0.45, 0.38, 0.2);
uniform float stain_amount = 0.0;
uniform float stain_scale = 0.35;
uniform float grime_height = 0.0;      // darkening band above floor_y (m)
uniform float floor_y = 0.0;
uniform vec3 grime_color : source_color = vec3(0.3, 0.26, 0.15);
uniform float wetness = 0.0;           // darker, glossier blotches
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energy = 0.0;
uniform float emission_flicker = 0.0;   // >0: glitchy flicker of the emission (e.g. no-clip wall)
uniform float sticky = 0.0;             // visual hint only (red-room carpet sheen)
uniform float caustics = 0.0;          // animated pool caustics below water_y
uniform float water_y = -1000.0;
uniform vec3 peel_color : source_color = vec3(0.45, 0.04, 0.03);
uniform float peel_amount = 0.0;       // wallpaper peeling to reveal peel_color
uniform float uv_rotate = 0.0;

varying vec3 world_pos;
varying vec3 world_nrm;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1, 0, 0));
	float n010 = hash13(i + vec3(0, 1, 0));
	float n110 = hash13(i + vec3(1, 1, 0));
	float n001 = hash13(i + vec3(0, 0, 1));
	float n101 = hash13(i + vec3(1, 0, 1));
	float n011 = hash13(i + vec3(0, 1, 1));
	float n111 = hash13(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}
float fbm3(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise3(p);
		p = p * 2.03 + vec3(17.1, 3.7, 9.2);
		a *= 0.5;
	}
	return s;
}
float vnoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x),
		mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}

vec3 perturb_normal(vec3 N, vec3 P, float h) {
	vec3 dpdx = dFdx(P);
	vec3 dpdy = dFdy(P);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, N);
	vec3 r2 = cross(N, dpdx);
	float det = dot(dpdx, r1);
	vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
	return normalize(abs(det) * N - grad);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = UV;
	if (uv_rotate != 0.0) {
		float c = cos(uv_rotate);
		float s = sin(uv_rotate);
		uv = mat2(vec2(c, -s), vec2(s, c)) * uv;
	}
	vec3 wp = world_pos;
	float n = fbm3(wp * noise_scale);
	float fine = vnoise3(wp * noise_scale * 9.0);
	vec3 col = mix(albedo_a, albedo_b, clamp(n * 2.0 - 0.5 + (noise_mix - 0.5), 0.0, 1.0));
	float rough = mix(roughness_a, roughness_b, n);
	float h = n * 0.3 + fine * 0.15;
	vec2 cell_uv = uv / pattern_scale;
	vec2 cell = floor(cell_uv);
	vec2 f = fract(cell_uv);

	if (pattern == 1 || pattern == 7 || pattern == 9 || pattern == 14) {
		vec2 g = f;
		if (pattern == 14) {
			// offset rows for a hex-ish staggered tile
			float row = cell.y;
			g = fract(vec2(cell_uv.x + 0.5 * mod(row, 2.0), cell_uv.y));
			cell = floor(vec2(cell_uv.x + 0.5 * mod(row, 2.0), cell_uv.y));
		}
		vec2 gw = vec2(grout_width) / pattern_scale;
		float edge = min(min(g.x, 1.0 - g.x) / gw.x, min(g.y, 1.0 - g.y) / gw.y);
		float grout = 1.0 - smoothstep(0.6, 1.0, edge);
		float tv = (hash12(cell) - 0.5) * tile_variation;
		vec3 tile = col + tv;
		if (pattern == 9) {
			float ch = mod(cell.x + cell.y, 2.0);
			tile = mix(col, pattern_color, ch * pattern_strength * 2.0);
		}
		if (pattern == 7) {
			// acoustic ceiling tile: fissures + pinholes
			float fiss = smoothstep(0.62, 0.7, vnoise2(uv * 38.0 + cell * 7.0));
			float pin = step(0.93, hash12(floor(uv * 120.0)));
			tile -= (fiss * 0.06 + pin * 0.05);
			h += -fiss * 0.2 - pin * 0.3;
		}
		col = mix(tile, grout_color, grout);
		h += (1.0 - grout) * 0.6;
		rough = mix(rough, roughness_b, grout);
	} else if (pattern == 2) {
		float stripe = smoothstep(0.45, 0.5, abs(fract(cell_uv.x) - 0.5));
		col = mix(col, pattern_color, stripe * pattern_strength);
		// roll seams every ~0.53 m with slight misprint
		float seam = 1.0 - smoothstep(0.0, 0.004, abs(fract(uv.x / 0.53) - 0.5) - 0.497);
		col *= 1.0 - seam * 0.12;
		h += stripe * 0.1;
	} else if (pattern == 3) {
		float row = floor(cell_uv.y);
		float off = hash12(vec2(row, 3.0)) * 3.0;
		float bx = floor(cell_uv.x + off);
		float lx = fract(cell_uv.x + off);
		float grain = vnoise2(vec2(uv.x * 2.0, uv.y * 60.0) + vec2(bx * 13.0, row * 7.0));
		vec3 plank = col * (0.85 + 0.3 * hash12(vec2(bx, row))) * (0.9 + 0.2 * grain);
		float gap = 1.0 - smoothstep(0.0, grout_width, min(min(lx, 1.0 - lx) * pattern_scale.x, min(f.y, 1.0 - f.y) * pattern_scale.y));
		col = mix(plank, grout_color, gap);
		h += grain * 0.2 - gap * 0.6;
	} else if (pattern == 4) {
		float row = floor(cell_uv.y);
		vec2 bu = vec2(cell_uv.x + 0.5 * mod(row, 2.0), cell_uv.y);
		vec2 bf = fract(bu);
		vec2 gw = vec2(grout_width) / pattern_scale;
		float edge = min(min(bf.x, 1.0 - bf.x) / gw.x, min(bf.y, 1.0 - bf.y) / gw.y);
		float grout = 1.0 - smoothstep(0.6, 1.0, edge);
		vec3 brick = col * (0.82 + 0.36 * hash12(floor(bu)));
		col = mix(brick, grout_color, grout);
		h += (1.0 - grout) * 0.7 + fine * 0.2;
	} else if (pattern == 5) {
		float d = length(f - 0.5);
		float dot_m = 1.0 - smoothstep(0.18, 0.22, d);
		col = mix(col, pattern_color, dot_m * pattern_strength);
	} else if (pattern == 6) {
		// carpet: dense pile + tufted rows
		float pile = vnoise2(uv * 220.0);
		float tuft = vnoise2(uv * 60.0);
		col *= 0.86 + 0.22 * pile + 0.08 * tuft;
		h += pile * 0.5;
		rough = 1.0;
		if (pattern_strength > 0.0) {
			// woven motif (hotel carpets): diamond lattice
			vec2 q = abs(fract(cell_uv) - 0.5);
			float diamond = 1.0 - smoothstep(0.02, 0.05, abs(q.x + q.y - 0.32));
			float dotc = 1.0 - smoothstep(0.05, 0.08, length(fract(cell_uv) - 0.5));
			col = mix(col, pattern_color, clamp(diamond + dotc, 0.0, 1.0) * pattern_strength);
		}
	} else if (pattern == 8) {
		// Level 0 style: faint chevron columns + roll seams, low contrast
		float x = fract(cell_uv.x);
		float y = fract(cell_uv.y + abs(x - 0.5) * 1.0);
		float chev = 1.0 - smoothstep(0.035, 0.07, abs(y - 0.5));
		float colline = 1.0 - smoothstep(0.0, 0.03, abs(x - 0.5) - 0.44);
		col = mix(col, pattern_color, (chev * 0.6 + colline * 0.4) * pattern_strength);
		float seam = 1.0 - smoothstep(0.0, 0.003, abs(fract(uv.x / 0.53) - 0.5) - 0.497);
		col *= 1.0 - seam * 0.15;
		h += chev * 0.05;
	} else if (pattern == 10) {
		// damask-like ornament for hotel wallpaper
		vec2 q = f - 0.5;
		float r = length(q * vec2(1.0, 0.7));
		float petals = 0.5 + 0.5 * cos(atan(q.y, q.x) * 4.0);
		float orn = smoothstep(0.03, 0.0, abs(r - 0.22 - 0.06 * petals)) + smoothstep(0.06, 0.0, r);
		col = mix(col, pattern_color, clamp(orn, 0.0, 1.0) * pattern_strength);
		h += orn * 0.1;
	} else if (pattern == 11) {
		float strata = sin(wp.y * 6.0 + fbm3(wp * 0.7) * 6.0);
		col = mix(col, pattern_color, smoothstep(0.3, 1.0, strata) * pattern_strength);
		h += strata * 0.15 + fbm3(wp * noise_scale * 4.0) * 0.6;
	} else if (pattern == 12) {
		float blades = vnoise3(wp * vec3(40.0, 4.0, 40.0));
		col = mix(col, pattern_color, smoothstep(0.4, 0.9, blades) * pattern_strength);
		h += blades * 0.5;
	} else if (pattern == 13) {
		float rip = sin(dot(wp.xz, vec2(3.1, 1.3)) + fbm3(wp * 0.5) * 5.0);
		col *= 0.92 + 0.08 * rip;
		h += rip * 0.25;
	} else if (pattern == 15) {
		float chips = step(0.82, vnoise2(uv * 40.0));
		col = mix(col, pattern_color, chips * pattern_strength);
		h += chips * 0.05;
	}

	// stains (water damage / mildew)
	if (stain_amount > 0.0) {
		float s = fbm3(wp * stain_scale + vec3(3.1, 0.0, 7.7));
		float sm = smoothstep(0.62 - stain_amount * 0.25, 0.75, s);
		float ring = smoothstep(0.0, 0.03, abs(s - 0.66 + stain_amount * 0.1)) ;
		col = mix(col, stain_color, sm * 0.7);
		col *= mix(0.92, 1.0, ring);
	}
	if (grime_height > 0.0) {
		float g = 1.0 - smoothstep(floor_y, floor_y + grime_height * (0.6 + 0.8 * n), wp.y);
		col = mix(col, grime_color, g * 0.55);
	}
	if (peel_amount > 0.0) {
		float pm = smoothstep(0.7 - peel_amount * 0.4, 0.72 - peel_amount * 0.4, fbm3(wp * 1.7 + 11.0));
		col = mix(col, peel_color, pm);
		h -= pm * 0.4;
	}
	float wet = 0.0;
	if (wetness > 0.0) {
		wet = smoothstep(0.55 - wetness * 0.3, 0.7, fbm3(wp * 0.45 + 5.0)) * wetness;
		col *= 1.0 - wet * 0.35;
		rough = mix(rough, 0.25, wet);
	}
	if (caustics > 0.0 && wp.y < water_y) {
		vec2 cp = wp.xz * 1.6;
		float t = TIME * 0.6;
		float c1 = vnoise2(cp + vec2(t, t * 0.7));
		float c2 = vnoise2(cp * 1.7 - vec2(t * 0.8, t * 0.4));
		float cc = pow(1.0 - abs(c1 - c2), 8.0);
		float depth_fade = clamp(1.0 - (water_y - wp.y) * 0.12, 0.25, 1.0);
		col += vec3(0.55, 0.85, 0.9) * cc * caustics * depth_fade;
	}

	ALBEDO = clamp(col, 0.0, 1.0);
	ROUGHNESS = clamp(rough, 0.02, 1.0);
	METALLIC = metallic_value;
	NORMAL = perturb_normal(NORMAL, VERTEX, h * bump_strength * 0.02);
	if (emission_energy > 0.0) {
		float fl = 1.0;
		if (emission_flicker > 0.0) {
			float t = floor(TIME * 22.0);
			float r = fract(sin(t * 12.9898 + wp.x * 0.37 + wp.z * 0.11) * 43758.5453);
			float band = step(0.5, fract(UV.y * 3.0 + TIME * 1.7));
			fl = mix(1.0, r * (0.4 + 0.6 * band), emission_flicker);
		}
		EMISSION = emission_color * emission_energy * fl;
	}
}
