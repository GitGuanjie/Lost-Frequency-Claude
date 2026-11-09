extends RefCounted
## Level 998 geometry and looks: the concrete office stairwell (eight flights,
## 1.6 m each) under the cloud plane, the small room at the top styled like a
## rooftop elevator house with roof skirting and a triangular skylight, the
## painted pebbles, the flat wool-cloud plane (a parallax "holographic" shader:
## clouds that seem to have depth and move with your gaze, white -> grey ->
## black with distance), the sky, the storm wall, rain and the drifting figures.

const FLIGHT := 1.6
const STEPS := 9
const RUN := 0.28
const TOP_Y := FLIGHT * 8.0        # 12.8: the plane and the room floor
const SX := 1.6                    # shaft half width (inner)
const SZ := 3.2                    # shaft half depth (inner): deep landings
const VZ := SZ + 1.6               # back wall of the base vestibule
const LZ := 1.26                   # landing edge (flight run is 2 * LZ)
const RX1 := 4.35                  # room inner east wall
const DOOR := Vector3(RX1, TOP_Y, 0.0)

const CLOUD := """shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform float m_to_km = 0.2;
uniform float storm_km = 95.0;
varying vec3 wp;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
float fbm(vec3 p) { return vn(p) * 0.55 + vn(p * 2.03 + 3.1) * 0.28 + vn(p * 4.1 + 7.7) * 0.17; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 V = normalize(wp - CAMERA_POSITION_WORLD);
	float km = length(wp.xz) * m_to_km;
	float grey = smoothstep(27.0, 34.0, km);
	float black = smoothstep(77.0, 85.0, km);
	vec3 deep = mix(mix(vec3(0.34, 0.5, 0.78), vec3(0.3, 0.31, 0.33), grey), vec3(0.012, 0.012, 0.016), black);
	vec3 cloud = mix(mix(vec3(0.93, 0.94, 0.96), vec3(0.5, 0.51, 0.53), grey), vec3(0.05, 0.05, 0.06), black);
	// imprinted clouds with an illusion of depth: layers sampled below the surface
	vec3 acc = vec3(0.0);
	float tr = 1.0;
	float vy = max(-V.y, 0.06);
	for (int i = 0; i < 5; i++) {
		float depth = 2.0 + float(i) * 7.0;
		vec3 p = wp + V * (depth / vy);
		float d = fbm(vec3(p.xz * 0.045, float(i) * 1.7));
		float c = smoothstep(0.42, 0.72, d);
		float shade = 1.0 - float(i) * 0.12;
		acc += tr * c * cloud * shade;
		tr *= 1.0 - c * 0.75;
	}
	vec3 col = acc + tr * deep;
	// solid surface: a fine wool texture over the image
	float wool = vn(wp * vec3(9.0, 9.0, 9.0)) * 0.6 + vn(wp * vec3(31.0, 31.0, 7.0)) * 0.4;
	col *= 0.86 + 0.18 * wool;
	ALBEDO = col * 0.55;
	EMISSION = col * 0.42;
	ROUGHNESS = 1.0;
}"""

const SKY := """shader_type sky;
uniform float grey = 0.0;
uniform float black = 0.0;
uniform float storm = 0.0;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
float fbm(vec3 p) { return vn(p) * 0.5 + vn(p * 2.1 + 3.1) * 0.3 + vn(p * 4.3 + 7.7) * 0.2; }
void sky() {
	vec3 d = EYEDIR;
	float el = d.y;
	vec3 top = mix(mix(vec3(0.09, 0.25, 0.7), vec3(0.32, 0.33, 0.35), grey), vec3(0.01, 0.01, 0.012), black);
	vec3 hor = mix(mix(vec3(0.66, 0.78, 0.92), vec3(0.5, 0.51, 0.52), grey), vec3(0.03, 0.03, 0.035), black);
	vec3 col = mix(hor, top, smoothstep(-0.05, 0.55, el));
	if (el > 0.0) {
		vec2 uv = d.xz / (el + 0.08) * 1.4;
		float c = fbm(vec3(uv * 0.9 + TIME * 0.004, 0.0));
		float cov = mix(0.6, 0.32, max(grey, black));
		float cl = smoothstep(cov, cov + 0.25, c) * smoothstep(0.0, 0.18, el);
		vec3 ccol = mix(mix(vec3(1.0), vec3(0.6), grey), vec3(0.06), black);
		col = mix(col, ccol * (0.85 + 0.15 * fbm(vec3(uv * 3.0, 1.0))), cl * (1.0 - storm * 0.5));
	}
	col = mix(col, vec3(0.015, 0.015, 0.02), storm);
	if (!AT_CUBEMAP_PASS) {
		float sd = distance(d, LIGHT0_DIRECTION);
		col += vec3(1.0, 0.97, 0.9) * smoothstep(0.03, 0.025, sd) * (1.0 - max(grey, black)) * 3.0;
	}
	COLOR = col;
}"""

const WALL := """shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform float near = 0.0;
uniform float top_h = 120.0;
varying vec3 wp;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 p = wp * 0.025 + vec3(0.0, TIME * 0.06, TIME * 0.02);
	float c = vn(p) * 0.5 + vn(p * 2.3) * 0.3 + vn(p * 5.1) * 0.2;
	float flash = step(0.985, vn(vec3(floor(TIME * 3.0), wp.y * 0.01, 0.0))) * smoothstep(0.55, 0.8, c);
	ALBEDO = vec3(0.012 + 0.03 * c) + vec3(0.5, 0.52, 0.6) * flash;
	float hgt = (wp.y - 12.8) / top_h;
	float body = clamp(0.7 + 0.3 * c, 0.0, 1.0) * (1.0 - smoothstep(0.35 + 0.4 * c, 1.0, hgt));
	ALPHA = body * mix(0.55, 1.0, near);
}"""

var lvl
var k: GeoKit
var kl: GeoKit
var r := RandomNumberGenerator.new()
var lamps: Array = []
var pebble_spot := Vector3.ZERO
var cloud_mat: ShaderMaterial
var sky_mat: ShaderMaterial
var wall_mat: ShaderMaterial


func _init(level, kit: GeoKit, lamp_kit: GeoKit) -> void:
	lvl = level
	k = kit
	kl = lamp_kit
	r.seed = 99801


func materials(m_to_km: float, storm_km: float) -> void:
	MatLib.define("l998_concrete", {"albedo_a": Color(0.42, 0.42, 0.4), "albedo_b": Color(0.36, 0.36, 0.35), "stain_amount": 0.3,
		"stain_color": Color(0.3, 0.29, 0.27), "noise_scale": 1.4, "bump_strength": 0.8}, "concrete")
	MatLib.define("l998_paint", {"albedo_a": Color(0.5, 0.52, 0.48), "albedo_b": Color(0.47, 0.49, 0.45), "grime_height": 0.3,
		"grime_color": Color(0.33, 0.33, 0.3), "stain_amount": 0.15, "roughness_a": 0.6, "roughness_b": 0.7, "noise_scale": 0.8}, "plaster")
	MatLib.define("l998_stripe", {"albedo_a": Color(0.25, 0.3, 0.27), "albedo_b": Color(0.23, 0.28, 0.25), "roughness_a": 0.5}, "plaster")
	MatLib.define("l998_tread", {"albedo_a": Color(0.3, 0.3, 0.29), "albedo_b": Color(0.26, 0.26, 0.25), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.22, 0.22, 0.21), "pattern_strength": 0.3, "stain_amount": 0.35}, "concrete")
	MatLib.define("l998_rail", {"albedo_a": Color(0.35, 0.36, 0.38), "albedo_b": Color(0.3, 0.31, 0.33), "metallic_value": 0.7, "roughness_a": 0.35}, "metal")
	MatLib.define("l998_nosing", {"albedo_a": Color(0.6, 0.55, 0.2), "albedo_b": Color(0.55, 0.5, 0.18), "roughness_a": 0.5}, "plaster")
	MatLib.define("l998_whitedoor", {"albedo_a": Color(0.86, 0.87, 0.88), "albedo_b": Color(0.8, 0.81, 0.82), "metallic_value": 0.35,
		"roughness_a": 0.3, "roughness_b": 0.4, "pattern": 2, "pattern_scale": Vector2(0.02, 1.0), "pattern_color": Color(0.78, 0.79, 0.8), "pattern_strength": 0.2}, "metal")
	MatLib.define("l998_render", {"albedo_a": Color(0.78, 0.78, 0.76), "albedo_b": Color(0.72, 0.72, 0.7), "noise_scale": 0.6,
		"stain_amount": 0.2, "stain_color": Color(0.6, 0.6, 0.58), "grime_height": 0.25, "grime_color": Color(0.6, 0.6, 0.58)}, "plaster")
	MatLib.register("l998_lamp", MatLib.panel(Color(1.0, 0.95, 0.85), 3.0))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.75, 0.85, 0.9, 0.16)
	g.roughness = 0.05
	g.metallic_specular = 0.9
	MatLib.register("l998_glass", g)
	cloud_mat = _shader(CLOUD)
	cloud_mat.set_shader_parameter("m_to_km", m_to_km)
	cloud_mat.set_shader_parameter("storm_km", storm_km)
	MatLib.register("l998_cloud", cloud_mat)
	sky_mat = _shader(SKY)
	wall_mat = _shader(WALL)


static func _shader(code: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = code
	m.shader = sh
	return m


# ------------------------------------------------------------ stairwell

## The base floor (with the white metal double door behind the arrival),
## eight flights and their landings, walls, rails and bulkhead lamps.
func stairwell() -> void:
	# base floor and a short vestibule (z -VZ .. -SZ) where the doors are
	k.box_mm(Vector3(-SX - 0.25, -0.3, -VZ), Vector3(SX + 0.25, 0.0, SZ + 0.25), "l998_concrete")
	# shaft walls (west, east, north) and the vestibule
	var H := TOP_Y
	k.box_mm(Vector3(-SX - 0.25, 0.0, -VZ), Vector3(-SX, H, SZ + 0.25), "l998_paint")
	k.box_mm(Vector3(SX, 0.0, -VZ), Vector3(SX + 0.25, H, SZ + 0.25), "l998_paint")
	k.box_mm(Vector3(-SX, 0.0, SZ), Vector3(SX, H, SZ + 0.25), "l998_paint")
	k.box_mm(Vector3(-SX, 0.0, -VZ), Vector3(SX, 3.0, -VZ + 0.2), "l998_paint")
	k.box_mm(Vector3(-SX, 3.0, -VZ), Vector3(SX, H, -SZ), "l998_concrete")
	# painted dado stripe on every storey
	for s in 4:
		var y := s * FLIGHT * 2.0 + 1.0
		for wv in [[Vector3(-SX + 0.006, y, 0.0), Vector3(0.012, 0.08, SZ * 2.0)], [Vector3(SX - 0.006, y, 0.0), Vector3(0.012, 0.08, SZ * 2.0)],
				[Vector3(0, y, SZ - 0.006), Vector3(SX * 2.0, 0.08, 0.012)]]:
			k.box(wv[0], wv[1], "l998_stripe", GeoKit.ALL, false)
	# white metal double door (closed) in the vestibule end wall
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 0.46, 1.05, -VZ + 0.22), Vector3(0.9, 2.1, 0.05), "l998_whitedoor", GeoKit.ALL, false)
	k.box(Vector3(0, 2.18, -VZ + 0.23), Vector3(2.0, 0.16, 0.08), "l998_rail", GeoKit.ALL, false)
	k.box(Vector3(0, 1.05, -VZ + 0.25), Vector3(0.02, 2.1, 0.02), "l998_rail", GeoKit.ALL, false)
	# flights and landings
	for i in 8:
		var y0 := i * FLIGHT
		var even := i % 2 == 0
		var x := -0.8 if even else 0.8
		var start := Vector3(x, y0, -LZ if even else LZ)
		var dir := Vector3(0, 0, 1) if even else Vector3(0, 0, -1)
		k.stairs(start, dir, 1.48, FLIGHT, STEPS, "l998_tread", RUN, false)
		# yellow nosing on each tread edge
		for s in STEPS:
			var zc := start.z + dir.z * (RUN * (s + 1) - 0.02)
			k.box(Vector3(x, y0 + FLIGHT / STEPS * (s + 1) + 0.003, zc), Vector3(1.46, 0.006, 0.04), "l998_nosing", GeoKit.ALL, false)
		# sloped soffit under the flight
		var a := start + Vector3(0, -0.12, 0)
		var b := start + dir * (RUN * STEPS) + Vector3(0, FLIGHT - 0.12, 0)
		var z := (b - a).normalized()
		var xx := Vector3.UP.cross(z).normalized()
		var yy := z.cross(xx).normalized()
		k.box_xf(Transform3D(Basis(xx, yy, z), (a + b) * 0.5 - yy * 0.1), Vector3(1.48, 0.2, (b - a).length()), "l998_concrete", GeoKit.ALL, false)
		# a thicker walking slab under the treads (the thin GeoKit ramp alone bakes poorly)
		var ta := start + Vector3(0, 0.02, 0)
		var tb := start + dir * (RUN * STEPS) + Vector3(0, FLIGHT, 0)
		var tz := (tb - ta).normalized()
		var tx := Vector3.UP.cross(tz).normalized()
		var ty := tz.cross(tx).normalized()
		k.add_box_shape(Transform3D(Basis(tx, ty, tz), (ta + tb) * 0.5 - ty * 0.2), Vector3(1.48, 0.4, (tb - ta).length()), "concrete")
		# landing at the top of this flight
		var ly := y0 + FLIGHT
		if even:
			k.box_mm(Vector3(-SX, ly - 0.22, LZ), Vector3(SX, ly, SZ), "l998_concrete")
		elif i < 7:
			k.box_mm(Vector3(-SX, ly - 0.22, -SZ), Vector3(SX, ly, -LZ), "l998_concrete")
		# handrails: inner (centre well) and wall side
		for hx in [x + (0.7 if even else -0.7), x - (0.7 if even else -0.7)]:
			var ra := start + Vector3(hx - x, 0.9, 0)
			var rb := start + dir * (RUN * STEPS) + Vector3(hx - x, FLIGHT + 0.9, 0)
			var rz := (rb - ra).normalized()
			var rx := Vector3.UP.cross(rz).normalized()
			k.box_xf(Transform3D(Basis(rx, rz.cross(rx).normalized(), rz), (ra + rb) * 0.5), Vector3(0.05, 0.05, ra.distance_to(rb)), "l998_rail", GeoKit.ALL, false)
		# bulkhead lamp on the landing wall
		var lp := Vector3(0.0, ly + 2.1, SZ - 0.06) if even else Vector3(0.0, ly + 2.1, -SZ + 0.06)
		if i == 7:
			lp = Vector3(-SX + 0.06, ly + 2.2, -2.2)
		kl.box(lp, Vector3(0.34, 0.14, 0.08) if i < 7 else Vector3(0.08, 0.14, 0.34), "l998_lamp", GeoKit.ALL, false)
		lamps.append(lp + (Vector3(0, -0.2, -0.3) if even else Vector3(0, -0.2, 0.3)))
	# the base floor lamp
	kl.box(Vector3(0, 2.6, -VZ + 0.25), Vector3(0.34, 0.14, 0.08), "l998_lamp", GeoKit.ALL, false)
	lamps.append(Vector3(0, 2.4, -VZ + 0.8))
	# centre well divider between the two flight runs (a thin concrete spine)
	k.box_mm(Vector3(-0.05, 0.0, -LZ), Vector3(0.05, TOP_Y - 0.6, LZ), "l998_concrete", GeoKit.ALL, true)


# ------------------------------------------------------------ the room

## The small room at the top: the top landing plus a floor east of the shaft,
## walls rising above the plane like a rooftop elevator house, roof skirting,
## a triangular skylight, an empty doorway onto the clouds.
func room() -> void:
	var y := TOP_Y
	var H := 3.0
	k.box_mm(Vector3(-SX, y - 0.22, -SZ), Vector3(SX, y, -LZ), "l998_concrete")
	k.box_mm(Vector3(SX, y - 0.22, -SZ), Vector3(RX1, y, SZ), "l998_concrete")
	# walls (outer face rendered with a pale render coat, like a roof structure)
	var t := 0.25
	k.box_mm(Vector3(-SX - t, y, -SZ - t), Vector3(-SX, y + H, SZ + t), "l998_render")
	k.box_mm(Vector3(-SX, y, SZ), Vector3(RX1 + t, y + H, SZ + t), "l998_render")
	k.box_mm(Vector3(-SX, y, -SZ - t), Vector3(RX1 + t, y + H, -SZ), "l998_render")
	k.wall(Vector3(RX1 + t * 0.5, y, -SZ - t), Vector3(RX1 + t * 0.5, y, SZ + t), H, t, "l998_render", [{"at": SZ + t, "w": 1.0, "h": 2.1}])
	# the shaft east wall stops at the room floor; a rail guards the open well
	k.box(Vector3(SX - 0.03, y + 0.95, 0.925), Vector3(0.05, 0.05, 4.55), "l998_rail", GeoKit.ALL, false)
	k.box(Vector3(-SX * 0.5, y + 0.95, -LZ + 0.03), Vector3(SX, 0.05, 0.05), "l998_rail", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(SX - 0.03, y + 0.5, 0.925)), Vector3(0.06, 1.0, 4.55), "metal")
	k.add_box_shape(Transform3D(Basis(), Vector3(-SX * 0.5, y + 0.5, -LZ + 0.03)), Vector3(SX, 1.0, 0.06), "metal")
	for p in [Vector3(SX - 0.03, y + 0.5, -1.2), Vector3(SX - 0.03, y + 0.5, 0.8), Vector3(SX - 0.03, y + 0.5, 3.15), Vector3(-1.55, y + 0.5, -LZ + 0.03), Vector3(-0.1, y + 0.5, -LZ + 0.03)]:
		k.box(p, Vector3(0.04, 1.0, 0.04), "l998_rail", GeoKit.ALL, false)
	# roof slab with the triangular skylight opening
	var ry := y + H
	k.box_mm(Vector3(-SX - t, ry, -SZ - t), Vector3(RX1 + t, ry + 0.25, -1.7), "l998_render")
	k.box_mm(Vector3(-SX - t, ry, 1.7), Vector3(RX1 + t, ry + 0.25, SZ + t), "l998_render")
	k.box_mm(Vector3(-SX - t, ry, -1.7), Vector3(-0.6, ry + 0.25, 1.7), "l998_render")
	k.box_mm(Vector3(3.6, ry, -1.7), Vector3(RX1 + t, ry + 0.25, 1.7), "l998_render")
	# glazed triangular prism (ridge along x)
	var x0 := -0.6
	var x1 := 3.6
	for s in [-1.0, 1.0]:
		var c := Vector3((x0 + x1) * 0.5, ry + 0.25 + 0.6, s * 0.85)
		var tilt := Basis(Vector3.RIGHT, s * -0.61)
		k.box_xf(Transform3D(tilt, c), Vector3(x1 - x0, 0.02, 2.06), "l998_glass", GeoKit.PY | GeoKit.NY, false)
		for gx in [x0, (x0 + x1) * 0.5, x1]:
			k.box_xf(Transform3D(tilt, Vector3(gx, c.y, c.z)), Vector3(0.06, 0.06, 2.06), "l998_rail", GeoKit.ALL, false)
	k.box(Vector3((x0 + x1) * 0.5, ry + 0.25 + 1.2, 0), Vector3(x1 - x0, 0.07, 0.07), "l998_rail", GeoKit.ALL, false)
	for gx in [x0, x1]:
		k.box(Vector3(gx, ry + 0.25 + 0.6, 0), Vector3(0.02, 1.2, 3.4), "l998_glass", GeoKit.PX | GeoKit.NX, false)
	# skirting around the roof perimeter
	for e in [[Vector3(-SX - t, ry + 0.25, -SZ - t), Vector3(RX1 + t, ry + 0.6, -SZ - t + 0.15)], [Vector3(-SX - t, ry + 0.25, SZ + t - 0.15), Vector3(RX1 + t, ry + 0.6, SZ + t)],
			[Vector3(-SX - t, ry + 0.25, -SZ - t), Vector3(-SX - t + 0.15, ry + 0.6, SZ + t)], [Vector3(RX1 + t - 0.15, ry + 0.25, -SZ - t), Vector3(RX1 + t, ry + 0.6, SZ + t)]]:
		k.box_mm(e[0], e[1], "l998_render", GeoKit.ALL, false)
	k.box_mm(Vector3(-SX - t - 0.05, y - 0.05, -SZ - t - 0.05), Vector3(RX1 + t + 0.05, y + 0.15, SZ + t + 0.05), "l998_concrete", GeoKit.SIDES | GeoKit.PY, false)
	# a bare bulb on a cord (the room was originally bare)
	kl.box(Vector3(2.8, y + 2.35, 1.4), Vector3(0.07, 0.1, 0.07), "l998_lamp", GeoKit.ALL, false)
	k.box(Vector3(2.8, y + 2.68, 1.4), Vector3(0.01, 0.6, 0.01), "l998_rail", GeoKit.ALL, false)
	lamps.append(Vector3(2.8, y + 2.2, 1.4))
	pebble_spot = Vector3(3.7, y, -1.6)


## About 38 small hand-painted stones in a clumsy pile near the doorway.
func pebbles(parent: Node3D) -> Array:
	var cols := [Color(0.75, 0.12, 0.1), Color(0.12, 0.3, 0.75), Color(0.9, 0.75, 0.15), Color(0.92, 0.92, 0.9), Color(0.15, 0.55, 0.25),
		Color(0.55, 0.2, 0.6), Color(0.95, 0.5, 0.15), Color(0.4, 0.4, 0.42), Color(0.2, 0.65, 0.75)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var placed: Array = []
	for i in 38:
		var c: Color = cols[i % cols.size()]
		var paint: Color = cols[(i * 5 + 3) % cols.size()]
		var h := pow(r.randf(), 0.8)
		var ang := r.randf() * TAU
		var rad := (1.0 - h) * 0.42 + 0.03
		var y := h * 0.22
		var p := pebble_spot + Vector3(cos(ang) * rad, y, sin(ang) * rad) + Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		var s := Vector3(r.randf_range(0.06, 0.1), r.randf_range(0.035, 0.055), r.randf_range(0.05, 0.09))
		_pebble(st, p + Vector3(0, s.y, 0), s, r.randf() * TAU, c, paint)
		placed.append(p)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "PaintedPebbles"
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.55
	mi.material_override = m
	parent.add_child(mi)
	return placed


func _pebble(st: SurfaceTool, c: Vector3, s: Vector3, yaw: float, col: Color, paint: Color) -> void:
	var b := Basis(Vector3.UP, yaw)
	var rings := 4
	var seg := 8
	var pts: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			row.append(c + b * (Vector3(sin(v) * cos(u) * s.x, cos(v) * s.y, sin(v) * sin(u) * s.z)))
		pts.append(row)
	for i in rings:
		for j in seg:
			var jn := (j + 1) % seg
			var cc := paint if (i == 0 and j % 2 == 0) or (i == 1 and j < 3) else col
			for v in [pts[i][j], pts[i][jn], pts[i + 1][jn], pts[i][j], pts[i + 1][jn], pts[i + 1][j]]:
				st.set_color(cc)
				st.add_vertex(v)


# ------------------------------------------------------------ the plane

## The flat cloud plane at TOP_Y, built as four large slabs around the room's
## footprint (so the stair shaft below stays open), 3 km across.
func plane(parent: Node3D, col: GeoKit, half: float) -> void:
	var y := TOP_Y
	var fx0 := -SX - 0.25
	var fx1 := RX1 + 0.25
	var fz0 := -SZ - 0.25
	var fz1 := SZ + 0.25
	var rects := [[-half, -half, half, fz0], [-half, fz1, half, half], [-half, fz0, fx0, fz1], [fx1, fz0, half, fz1]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for rc in rects:
		var x0: float = rc[0]
		var z0: float = rc[1]
		var x1: float = rc[2]
		var z1: float = rc[3]
		col.box_mm(Vector3(x0, y - 1.0, z0), Vector3(x1, y, z1), "l998_cloud", 0, true, "plush")
		# subdivide for precision far from the origin
		var n := maxi(1, int((x1 - x0) / 150.0))
		var m := maxi(1, int((z1 - z0) / 150.0))
		for i in n:
			for j in m:
				var a := Vector3(lerpf(x0, x1, float(i) / n), y, lerpf(z0, z1, float(j) / m))
				var b := Vector3(lerpf(x0, x1, float(i + 1) / n), y, lerpf(z0, z1, float(j + 1) / m))
				for v in [Vector3(a.x, y, a.z), Vector3(b.x, y, a.z), Vector3(b.x, y, b.z), Vector3(a.x, y, a.z), Vector3(b.x, y, b.z), Vector3(a.x, y, b.z)]:
					st.set_normal(Vector3.UP)
					st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "CloudPlane"
	mi.mesh = st.commit()
	mi.material_override = cloud_mat
	parent.add_child(mi)


## The neverending storm: a ring wall of churning black cloud at the storm edge.
func storm_wall(parent: Node3D, radius: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 96
	for i in seg:
		var a0 := TAU * i / seg
		var a1 := TAU * (i + 1) / seg
		var p0 := Vector3(cos(a0), 0, sin(a0)) * radius
		var p1 := Vector3(cos(a1), 0, sin(a1)) * radius
		var lo := TOP_Y - 30.0
		var hi := TOP_Y + radius * 0.3
		for v in [p0 + Vector3(0, lo, 0), p1 + Vector3(0, lo, 0), p1 + Vector3(0, hi, 0), p0 + Vector3(0, lo, 0), p1 + Vector3(0, hi, 0), p0 + Vector3(0, hi, 0)]:
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "StormWall"
	mi.mesh = st.commit()
	wall_mat.set_shader_parameter("top_h", radius * 0.3)
	mi.material_override = wall_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func rain(parent: Node3D, heavy: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "RainHeavy" if heavy else "Rain"
	p.amount = 3000 if heavy else 1200
	p.lifetime = 0.9
	p.emitting = false
	p.visibility_aabb = AABB(Vector3(-24, -16, -24), Vector3(48, 22, 48))
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(18, 0.5, 18)
	pm.direction = Vector3(0.45 if heavy else 0.25, -1, 0.2)
	pm.spread = 4.0
	pm.initial_velocity_min = 16.0 if heavy else 11.0
	pm.initial_velocity_max = 21.0 if heavy else 13.0
	pm.gravity = Vector3(0, -6, 0)
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.015, 0.6 if heavy else 0.45)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.57, 0.6, 0.35)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.material = mat
	p.draw_pass_1 = qm
	parent.add_child(p)
	return p


## A wandering figure seen far off: stooped, featureless, dark, walking away.
static func figure(mat: Material, tall: float) -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.22
	cm.height = tall * 0.62
	body.mesh = cm
	body.material_override = mat
	body.position = Vector3(0, tall * 0.55, 0.05)
	body.rotation.x = 0.18
	n.add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13
	sm.height = 0.28
	head.mesh = sm
	head.material_override = mat
	head.position = Vector3(0, tall * 0.9, 0.16)
	n.add_child(head)
	for s in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := CapsuleMesh.new()
		lm.radius = 0.08
		lm.height = tall * 0.48
		leg.mesh = lm
		leg.material_override = mat
		leg.position = Vector3(s * 0.11, tall * 0.24, 0)
		leg.name = "Leg%d" % (0 if s < 0 else 1)
		n.add_child(leg)
		var arm := MeshInstance3D.new()
		var am := CapsuleMesh.new()
		am.radius = 0.055
		am.height = tall * 0.4
		arm.mesh = am
		arm.material_override = mat
		arm.position = Vector3(s * 0.28, tall * 0.62, 0.08)
		n.add_child(arm)
	return n


## A Smiler as rumoured in the black haze: only a wide grin and two eyes, lit.
static func smiler() -> Node3D:
	var n := Node3D.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.95, 0.95, 0.9)
	for s in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.1
		e.mesh = sm
		e.material_override = m
		e.position = Vector3(s * 0.16, 1.75, 0)
		n.add_child(e)
	for i in 9:
		var t := (i - 4) / 4.0
		var tooth := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.05, 0.045, 0.02)
		tooth.mesh = bm
		tooth.material_override = m
		tooth.position = Vector3(t * 0.24, 1.52 + t * t * 0.07, 0)
		n.add_child(tooth)
	return n
