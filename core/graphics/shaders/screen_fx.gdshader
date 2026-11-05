// Full-screen post layer: brightness/contrast accessibility, underwater tint and
// wobble, vignette, low-oxygen desaturation, red-room tint, film grain.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float brightness = 1.0;
uniform float contrast = 1.0;
uniform float underwater = 0.0;
uniform vec3 water_tint : source_color = vec3(0.1, 0.45, 0.5);
uniform float vignette = 0.25;
uniform float desaturate = 0.0;
uniform float red_tint = 0.0;
uniform float grain = 0.03;
uniform float blackout = 0.0;
uniform float glitch = 0.0;      // no-clip transition tear (0..1)
uniform float camcorder = 0.0;   // found-footage look (0..1)

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	if (camcorder > 0.0) {
		vec2 cc = uv - 0.5;
		uv = 0.5 + cc * (1.0 - 0.035 * camcorder * dot(cc, cc) * 4.0);
		uv.x += (hash12(vec2(floor(uv.y * 240.0), floor(TIME * 30.0))) - 0.5) * 0.0012 * camcorder;
	}
	if (glitch > 0.0) {
		float band = step(0.82 - glitch * 0.5, hash12(vec2(floor(uv.y * 38.0), floor(TIME * 24.0))));
		uv.x += (hash12(vec2(floor(uv.y * 90.0), TIME)) - 0.5) * 0.12 * glitch * band;
		uv.y += sin(TIME * 60.0) * 0.004 * glitch;
	}
	if (underwater > 0.0) {
		uv += vec2(sin(uv.y * 24.0 + TIME * 2.0), cos(uv.x * 19.0 + TIME * 1.7)) * 0.0035 * underwater;
	}
	vec3 c = texture(screen_tex, uv).rgb;
	float ca = 0.0015 * camcorder + 0.012 * glitch;
	if (ca > 0.0) {
		c.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
		c.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;
	}
	c = (c - 0.5) * contrast + 0.5;
	c *= brightness;
	if (underwater > 0.0) {
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, water_tint * (0.35 + lum * 1.4), 0.55 * underwater);
	}
	if (desaturate > 0.0) {
		float lum = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, vec3(lum), desaturate);
	}
	if (red_tint > 0.0) {
		c = mix(c, c * vec3(1.25, 0.55, 0.5), red_tint);
	}
	float d = distance(SCREEN_UV, vec2(0.5));
	c *= 1.0 - smoothstep(0.35, 0.85, d) * vignette;
	c += (hash12(SCREEN_UV * 1000.0 + TIME) - 0.5) * (grain + 0.05 * camcorder + 0.25 * glitch);
	if (camcorder > 0.0) {
		float scan = 0.5 + 0.5 * sin(SCREEN_UV.y * 900.0);
		c *= 1.0 - 0.06 * camcorder * scan;
		c = mix(c, c * vec3(1.03, 1.0, 0.94) + vec3(0.01, 0.01, 0.0), camcorder * 0.6);
		c *= 1.0 - smoothstep(0.45, 0.95, distance(SCREEN_UV, vec2(0.5))) * 0.35 * camcorder;
	}
	if (glitch > 0.0) {
		c = mix(c, vec3(dot(c, vec3(0.33))), glitch * 0.4);
	}
	c = mix(c, vec3(0.0), blackout);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
