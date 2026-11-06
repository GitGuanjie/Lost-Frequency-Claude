// LOST FREQUENCY — water surface: depth-based absorption, refraction, fresnel,
// soft shoreline and small procedural waves. Used by pools, flooded rooms and seas.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

uniform vec3 shallow_color : source_color = vec3(0.35, 0.75, 0.78);
uniform vec3 deep_color : source_color = vec3(0.03, 0.18, 0.24);
uniform float absorption = 0.35;        // per metre
uniform float clarity = 0.85;           // how much refracted scene shows through
uniform float wave_height = 0.025;
uniform float wave_scale = 0.6;
uniform float wave_speed = 0.35;
uniform float normal_strength = 0.35;
uniform float refraction = 0.03;
uniform float roughness_value = 0.04;
uniform float foam_width = 0.12;
uniform vec3 foam_color : source_color = vec3(0.9, 0.95, 0.95);
uniform float foam_amount = 0.25;
uniform float dark_surface = 0.0;       // 1 = ink-black ocean (Level 7 style)

varying vec3 wpos;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x),
		mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}
float waves(vec2 p, float t) {
	float h = vnoise(p * wave_scale + vec2(t * wave_speed, t * wave_speed * 0.6));
	h += 0.5 * vnoise(p * wave_scale * 2.3 - vec2(t * wave_speed * 1.3, -t * wave_speed * 0.4));
	h += 0.25 * sin(p.x * 0.7 + t * 0.9) * sin(p.y * 0.5 + t * 0.7);
	return h;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (waves(wpos.xz, TIME) - 0.6) * wave_height;
}

void fragment() {
	float t = TIME;
	float e = 0.08;
	float h0 = waves(wpos.xz, t);
	float hx = waves(wpos.xz + vec2(e, 0.0), t);
	float hz = waves(wpos.xz + vec2(0.0, e), t);
	vec3 wn = normalize(vec3((h0 - hx) * normal_strength * 6.0, 1.0, (h0 - hz) * normal_strength * 6.0));
	vec3 vn = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	if (!FRONT_FACING) {
		vn = -vn;
	}
	NORMAL = vn;

	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec4 view = INV_PROJECTION_MATRIX * ndc;
	view.xyz /= view.w;
	float thickness = max(0.0, -view.z - (-VERTEX.z));

	vec2 ruv = SCREEN_UV + vn.xz * refraction;
	vec3 behind = texture(screen_tex, ruv).rgb;
	float absorb = 1.0 - exp(-thickness * absorption);
	vec3 water_col = mix(shallow_color, deep_color, absorb);
	vec3 col = mix(behind * shallow_color * 1.2, water_col, clamp(absorb + (1.0 - clarity), 0.0, 1.0));
	col = mix(col, deep_color * 0.25, dark_surface);

	float fres = pow(1.0 - clamp(dot(normalize(-VERTEX), vn), 0.0, 1.0), 4.0);
	float foam = (1.0 - smoothstep(0.0, foam_width, thickness)) * foam_amount;
	foam *= 0.6 + 0.4 * vnoise(wpos.xz * 8.0 + t);
	col = mix(col, foam_color, foam);

	ALBEDO = col * (1.0 - fres * 0.4);
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	SPECULAR = 0.6;
	ALPHA = 1.0;
	if (!FRONT_FACING) {
		// seen from below: dim surface with total-internal-reflection feel
		ALBEDO = mix(deep_color, behind, 0.35);
	}
}
