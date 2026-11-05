extends RefCounted
## Level 37 water surface (level-local workaround, see final report).
## core/graphics/shaders/water.gdshader writes the refracted scene into lit
## ALBEDO, so clear water renders dark and opaque wherever the ambient light is
## low — and Level 37 must keep lightless corners. This variant puts the
## refraction in EMISSION (unaffected by scene lighting), applies coloured
## Beer-Lambert absorption along the view path (clear over ankle-deep tiles,
## deep blue-green in pits), scales the in-scatter by the local light level (so
## dark rooms keep dark water), and keeps the constant minimal ripple (SOURCE:
## "a minimal and constant rippling ... despite it being undisturbed").

const CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 tint : source_color = vec3(0.55, 0.93, 0.90);
uniform vec3 deep_color : source_color = vec3(0.02, 0.24, 0.31);
uniform float absorption = 0.05;
uniform float tint_strength = 0.35;
uniform float wave_height = 0.012;
uniform float wave_scale = 0.8;
uniform float wave_speed = 0.45;
uniform float refraction = 0.022;
uniform float reflectivity = 0.55;
uniform int debug_mode = 0;

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
	float h = vnoise(p * wave_scale + vec2(t * wave_speed, t * wave_speed * 0.6));
	h += 0.5 * vnoise(p * wave_scale * 2.3 - vec2(t * wave_speed * 1.3, -t * wave_speed * 0.4));
	h += 0.25 * sin(p.x * 0.7 + t * 0.9) * sin(p.y * 0.5 + t * 0.7);
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
	vec2 ruv = SCREEN_UV + vn.xz * refraction * clamp(path, 0.0, 1.0);
	if (length(view_at(ruv, INV_PROJECTION_MATRIX)) < surf) {
		ruv = SCREEN_UV;
	}
	vec3 behind = textureLod(screen_tex, ruv, 0.0).rgb;
	vec3 local = textureLod(screen_tex, SCREEN_UV, 5.0).rgb;
	float lum = dot(local, vec3(0.299, 0.587, 0.114));
	vec3 ext = vec3(absorption) + (vec3(1.0) - tint) * tint_strength;
	vec3 trans = exp(-path * ext);
	vec3 col = behind * trans + deep_color * (0.12 + 1.7 * lum) * (vec3(1.0) - trans);
	float fres = 0.02 + 0.98 * pow(1.0 - clamp(dot(normalize(-VERTEX), vn), 0.0, 1.0), 5.0);
	col = mix(col, local * 1.25 + vec3(0.02, 0.03, 0.03), fres * reflectivity);
	col += vec3(0.06) * (1.0 - smoothstep(0.0, 0.05, path)) * lum;
	if (!FRONT_FACING) {
		col = mix(deep_color * (0.25 + lum), behind, 0.45);
	}
	if (debug_mode == 1) { col = behind; }
	if (debug_mode == 2) { col = vec3(path * 0.1, fract(path), 0.0); }
	if (debug_mode == 3) { col = vec3(texture(depth_tex, SCREEN_UV).r * 20.0); }
	ALBEDO = vec3(0.0);
	EMISSION = col;
	ROUGHNESS = 0.06;
	SPECULAR = 0.45;
	METALLIC = 0.0;
	ALPHA = 1.0;   // writing ALPHA puts the surface in the transparent pass (screen/depth reads)
}
"""


static func material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = CODE
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
