extends RefCounted
## Level 37.1 water surface. Same approach as levels/L037/L037_water.gd (the
## refracted scene goes to EMISSION so dark rooms keep dark water; coloured
## Beer-Lambert absorption along the view path), plus a `blood` uniform that
## L037_1.gd raises as the light dies: the water thickens (slower, heavier
## ripples, less refraction) and takes the "slight red tint" of the page.

const CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 tint : source_color = vec3(0.55, 0.93, 0.90);
uniform vec3 deep_color : source_color = vec3(0.02, 0.24, 0.31);
uniform vec3 red_tint : source_color = vec3(0.95, 0.30, 0.30);
uniform vec3 red_deep : source_color = vec3(0.30, 0.012, 0.018);
uniform float blood = 0.0;
uniform float absorption = 0.05;
uniform float tint_strength = 0.35;
uniform float wave_height = 0.012;
uniform float wave_scale = 0.8;
uniform float wave_speed = 0.45;
uniform float refraction = 0.022;
uniform float reflectivity = 0.55;

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
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}
float waves(vec2 p, float t) {
	float sp = wave_speed * (1.0 - 0.75 * blood);
	float h = vnoise(p * wave_scale + vec2(t * sp, t * sp * 0.6));
	h += 0.5 * vnoise(p * wave_scale * 2.3 - vec2(t * sp * 1.3, -t * sp * 0.4));
	h += 0.25 * sin(p.x * 0.7 + t * 0.9 * (1.0 - 0.7 * blood)) * sin(p.y * 0.5 + t * 0.7);
	return h;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (waves(wpos.xz, TIME) - 0.6) * wave_height;
}

vec3 view_at(vec2 uv, mat4 ipm) {
	float d = texture(depth_tex, uv).r;
	vec4 v = ipm * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.xyz / v.w;
}

void fragment() {
	float e = 0.08;
	float h0 = waves(wpos.xz, TIME);
	float hx = waves(wpos.xz + vec2(e, 0.0), TIME);
	float hz = waves(wpos.xz + vec2(0.0, e), TIME);
	vec3 wn = normalize(vec3((h0 - hx) * 1.7, 1.0, (h0 - hz) * 1.7));
	vec3 vn = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	float surf = length(VERTEX);
	float path = max(0.0, length(view_at(SCREEN_UV, INV_PROJECTION_MATRIX)) - surf);
	float refr = refraction * (1.0 - 0.6 * blood);
	vec2 ruv = SCREEN_UV + vn.xz * refr * clamp(path, 0.0, 1.0);
	if (length(view_at(ruv, INV_PROJECTION_MATRIX)) < surf) {
		ruv = SCREEN_UV;
	}
	vec3 behind = textureLod(screen_tex, ruv, 0.0).rgb;
	vec3 local = textureLod(screen_tex, SCREEN_UV, 5.0).rgb;
	float lum = dot(local, vec3(0.299, 0.587, 0.114));
	vec3 tt = mix(tint, red_tint, blood);
	vec3 dc = mix(deep_color, red_deep, blood);
	vec3 ext = vec3(absorption * (1.0 + 0.6 * blood)) + (vec3(1.0) - tt) * tint_strength * (1.0 + 0.3 * blood);
	vec3 trans = exp(-path * ext);
	vec3 col = behind * trans + dc * (0.12 + 1.7 * lum) * (vec3(1.0) - trans);
	float fres = 0.02 + 0.98 * pow(1.0 - clamp(dot(normalize(-VERTEX), vn), 0.0, 1.0), 5.0);
	col = mix(col, local * 1.25 + vec3(0.02, 0.01, 0.01), fres * reflectivity);
	col += vec3(0.06) * (1.0 - smoothstep(0.0, 0.05, path)) * lum;
	if (!FRONT_FACING) {
		col = mix(dc * (0.25 + lum), behind, 0.45);
	}
	ALBEDO = vec3(0.0);
	EMISSION = col;
	ROUGHNESS = 0.06 + 0.1 * blood;
	SPECULAR = 0.45;
	METALLIC = 0.0;
	ALPHA = 1.0;
}
"""


static func material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = CODE
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
