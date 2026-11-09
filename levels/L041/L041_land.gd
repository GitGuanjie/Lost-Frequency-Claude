extends RefCounted
## Level 41 land model. One height grid (2 m samples) shared by the island
## render mesh, the streamed HeightMapShape3D collision tiles and all prop
## placement. The tar surface is the plane y = 0; the bed under the shallow
## tar is BED. Islands are charcoal-sand bumps that pierce the surface; the
## lake is circular and ringed by unreachable dunes (render only).

const TAR_Y := 0.0
const BED := -1.15
const HALF := 256.0          # grid half size (m)
const STEP := 2.0
const N := 257               # samples per side
const LAKE_R := 252.0        # dune foot (tar edge)
const REACH_R := 196.0       # nothing traversable beyond this (page: 50 m from the dunes)
const DUNE_H := 15.0

var hs := PackedFloat32Array()
var islands: Array = []      # {c: Vector2, rx, rz, rot, top, name}
var n_shape := FastNoiseLite.new()
var n_fine := FastNoiseLite.new()


func _init() -> void:
	n_shape.seed = 4101
	n_shape.frequency = 0.045
	n_shape.fractal_octaves = 3
	n_fine.seed = 4102
	n_fine.frequency = 0.21


## Authored islands (the reachable network) plus seeded outliers.
func plan(rng: RandomNumberGenerator) -> void:
	islands.clear()
	_isl(Vector2(0, 40), 15.0, 10.5, 0.35, 1.05, "landing")
	_isl(Vector2(12.5, 49.0), 7.5, 3.2, 0.9, 0.55, "spit")
	_isl(Vector2(22.0, 54.0), 9.0, 7.0, 0.2, 0.95, "plinth")
	_isl(Vector2(-6.0, 32.0), 7.0, 4.5, 1.2, 0.6, "landing_w")
	_isl(Vector2(-35.0, 2.0), 11.0, 9.0, 0.8, 0.85, "midway")
	_isl(Vector2(-21.0, -21.0), 4.0, 3.0, 0.2, 0.45, "midway_n")
	_isl(Vector2(62.0, 12.0), 12.0, 10.0, -0.5, 1.0, "shuttle")
	_isl(Vector2(52.0, 22.0), 5.0, 3.0, 0.6, 0.5, "shuttle_s")
	_isl(Vector2(-58.0, -36.0), 4.5, 3.2, 0.3, 0.45, "lamp_rock")
	# seeded outliers: small, patchy, isolated (marooning islands)
	var tries := 0
	while islands.size() < 34 and tries < 400:
		tries += 1
		var a := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf_range(0.03, 1.0)) * (REACH_R - 8.0)
		var c := Vector2(cos(a) * r, sin(a) * r)
		var rx := rng.randf_range(2.5, 9.0)
		var ok := true
		for i in islands:
			if (i["c"] as Vector2).distance_to(c) < float(i["rx"]) + rx + 9.0:
				ok = false
				break
		# keep the authored routes and landmarks clear
		for p in [Vector2(-77, -31), Vector2(8, -72), Vector2(74, 6), Vector2(0, 40), Vector2(22, 54), Vector2(-35, 2), Vector2(62, 12), Vector2(-20, -20), Vector2(40, 36)]:
			if c.distance_to(p) < 30.0:
				ok = false
		if not ok:
			continue
		_isl(c, rx, rx * rng.randf_range(0.45, 0.9), rng.randf_range(0, PI), rng.randf_range(0.25, 0.9), "isle_%d" % islands.size())
	_bake()


func _isl(c: Vector2, rx: float, rz: float, rot: float, top: float, nm: String) -> void:
	islands.append({"c": c, "rx": rx, "rz": rz, "rot": rot, "top": top, "name": nm})


func island(nm: String) -> Dictionary:
	for i in islands:
		if i["name"] == nm:
			return i
	return {}


func _raw(x: float, z: float) -> float:
	var y := BED - 0.05 * n_fine.get_noise_2d(x, z)
	for i in islands:
		var c: Vector2 = i["c"]
		var dx := x - c.x
		var dz := z - c.y
		var reach := maxf(float(i["rx"]), float(i["rz"])) * 1.6 + 4.0
		if absf(dx) > reach or absf(dz) > reach:
			continue
		var ca := cos(float(i["rot"]))
		var sa := sin(float(i["rot"]))
		var u := (dx * ca + dz * sa) / float(i["rx"])
		var v := (-dx * sa + dz * ca) / float(i["rz"])
		var d := sqrt(u * u + v * v)
		var wob := 0.22 * n_shape.get_noise_2d(x, z)
		var t := 1.0 - d + wob
		var top: float = i["top"]
		var k := smoothstep(-0.12, 0.42, t)
		var iy := BED + (top - BED) * k + 0.18 * n_fine.get_noise_2d(x * 0.6, z * 0.6) * k
		y = maxf(y, iy)
	return y


func _bake() -> void:
	hs.resize(N * N)
	for iz in N:
		for ix in N:
			hs[iz * N + ix] = _raw(-HALF + ix * STEP, -HALF + iz * STEP)


## Bilinear height of the ground (sand / tar bed).
func h(x: float, z: float) -> float:
	var fx := clampf((x + HALF) / STEP, 0.0, N - 1.001)
	var fz := clampf((z + HALF) / STEP, 0.0, N - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var a := hs[iz * N + ix]
	var b := hs[iz * N + ix + 1]
	var c := hs[(iz + 1) * N + ix]
	var d := hs[(iz + 1) * N + ix + 1]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


func is_sand(x: float, z: float) -> bool:
	return h(x, z) > TAR_Y + 0.04


## Distance (approx, metres) from a point on sand to the nearest tar, up to r.
func shore_dist(x: float, z: float, r: float = 3.0) -> float:
	if not is_sand(x, z):
		return 0.0
	for k in [0.8, 1.6, 2.4, r]:
		for j in 8:
			var a := TAU * j / 8.0
			if not is_sand(x + cos(a) * k, z + sin(a) * k):
				return k
	return r + 1.0


# ------------------------------------------------------------ render meshes

func build_meshes(parent: Node3D, sand_mat: Material, dune_mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var used := {}
	var idx := {}
	var count := 0
	for iz in N - 1:
		for ix in N - 1:
			var a := hs[iz * N + ix]
			var b := hs[iz * N + ix + 1]
			var c := hs[(iz + 1) * N + ix]
			var d := hs[(iz + 1) * N + ix + 1]
			if maxf(maxf(a, b), maxf(c, d)) < -0.75:
				continue
			for q in [[ix, iz], [ix + 1, iz], [ix, iz + 1], [ix + 1, iz + 1]]:
				var key: int = q[1] * N + q[0]
				if not idx.has(key):
					idx[key] = count
					count += 1
					var x: float = -HALF + q[0] * STEP
					var z: float = -HALF + q[1] * STEP
					var y := hs[key]
					st.set_normal(_nrm(q[0], q[1]))
					st.set_color(Color(clampf(y + 0.4, 0.0, 1.0), 0, 0))
					st.add_vertex(Vector3(x, y, z))
			used[iz * N + ix] = true
	for key in used.keys():
		var ix: int = key % N
		var iz: int = key / N
		var i0: int = idx[iz * N + ix]
		var i1: int = idx[iz * N + ix + 1]
		var i2: int = idx[(iz + 1) * N + ix]
		var i3: int = idx[(iz + 1) * N + ix + 1]
		st.add_index(i0)
		st.add_index(i1)
		st.add_index(i2)
		st.add_index(i1)
		st.add_index(i3)
		st.add_index(i2)
	var mi := MeshInstance3D.new()
	mi.name = "Islands"
	mi.mesh = st.commit()
	mi.material_override = sand_mat
	parent.add_child(mi)
	_dunes(parent, dune_mat)


func _nrm(ix: int, iz: int) -> Vector3:
	var l := hs[iz * N + maxi(ix - 1, 0)]
	var r := hs[iz * N + mini(ix + 1, N - 1)]
	var u := hs[maxi(iz - 1, 0) * N + ix]
	var d := hs[mini(iz + 1, N - 1) * N + ix]
	return Vector3(l - r, 2.0 * STEP, u - d).normalized()


## The dune ring: rises 15 m from the tar edge and tapers away out of sight.
func dune_y(r: float, a: float) -> float:
	var crest := LAKE_R + 30.0 + 8.0 * n_shape.get_noise_2d(cos(a) * 40.0, sin(a) * 40.0)
	var hh := DUNE_H + 3.0 * n_shape.get_noise_2d(cos(a) * 90.0 + 5.0, sin(a) * 90.0)
	if r < crest:
		var t := clampf((r - LAKE_R + 6.0) / (crest - LAKE_R + 6.0), 0.0, 1.0)
		return BED + (hh - BED) * (t * t * (3.0 - 2.0 * t))
	var t2 := clampf((r - crest) / 140.0, 0.0, 1.0)
	return hh - (hh + 6.0) * t2 * t2


func _dunes(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 192
	var radii := [LAKE_R - 8.0, LAKE_R, LAKE_R + 8.0, LAKE_R + 16.0, LAKE_R + 24.0, LAKE_R + 32.0, LAKE_R + 44.0, LAKE_R + 64.0, LAKE_R + 100.0, LAKE_R + 160.0, LAKE_R + 260.0]
	var nr := radii.size()
	for j in segs + 1:
		var a := TAU * j / segs
		for i in nr:
			var r: float = radii[i]
			var y := dune_y(r, a)
			var e := 2.0
			var nx := dune_y(r + e, a) - dune_y(r - e, a)
			var dir := Vector3(cos(a), 0, sin(a))
			var n := (Vector3.UP * 2.0 * e - dir * nx).normalized()
			st.set_normal(n)
			st.set_color(Color(0.5, 0, 0))
			st.add_vertex(Vector3(cos(a) * r, y, sin(a) * r))
	for j in segs:
		for i in nr - 1:
			var a0 := j * nr + i
			var b0 := (j + 1) * nr + i
			st.add_index(a0)
			st.add_index(a0 + 1)
			st.add_index(b0)
			st.add_index(a0 + 1)
			st.add_index(b0 + 1)
			st.add_index(b0)
	var mi := MeshInstance3D.new()
	mi.name = "Dunes"
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


# ------------------------------------------------------------ collision

## One 64 m HeightMapShape3D tile with 1 m samples, bilinear from the grid.
func collision_tile(node: Node3D, ox: float, oz: float, size: int) -> void:
	var md := PackedFloat32Array()
	md.resize((size + 1) * (size + 1))
	for j in size + 1:
		for i in size + 1:
			md[j * (size + 1) + i] = h(ox + i, oz + j)
	var body := StaticBody3D.new()
	body.name = "Ground"
	node.add_child(body)
	var sh := HeightMapShape3D.new()
	sh.map_width = size + 1
	sh.map_depth = size + 1
	sh.map_data = md
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + size * 0.5, 0.0, oz + size * 0.5)
	cs.set_meta("surface", "sand")
	body.add_child(cs)


# ------------------------------------------------------------ shaders

const SAND := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float dune = 0.0;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wp.xz / 3.2;
	vec3 tex = texture(sand_alb, uv).rgb;
	float l = dot(tex, vec3(0.3, 0.5, 0.2));
	float macro = vn(wp.xz * 0.05) * 0.6 + vn(wp.xz * 0.23) * 0.4;
	// charcoal sand: near-black grains with grey ash drifts and rare pale flecks
	vec3 c = vec3(0.055, 0.052, 0.05) * (0.55 + 1.1 * l) * (0.8 + 0.4 * macro);
	c = mix(c, vec3(0.16, 0.155, 0.15) * (0.7 + 0.6 * l), smoothstep(0.62, 0.9, macro) * 0.55);
	float fleck = step(0.985, hsh(floor(wp.xz * 34.0)));
	c += vec3(0.12) * fleck * (1.0 - dune);
	// tar-soaked rim at the waterline: glossy, black, with a hot orange sheen
	float rim = 1.0 - smoothstep(0.02, 0.28, wp.y);
	c = mix(c, vec3(0.012, 0.01, 0.009), rim * (1.0 - dune));
	c = mix(c, vec3(0.2, 0.19, 0.18), dune * smoothstep(4.0, 16.0, wp.y));
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.18, rim * (1.0 - dune));
	SPECULAR = mix(0.3, 0.7, rim);
	NORMAL_MAP = texture(sand_nrm, uv).rgb;
	NORMAL_MAP_DEPTH = mix(0.9, 0.2, rim);
}
"""

## Boiling tar: glossy black, a field of bubbles that swell and burst, slow
## convection cells, and orange glow under the fires (fires[i] = xz, radius).
const TAR := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 fires[24];
uniform int fire_count = 0;
uniform float boil = 1.0;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
vec2 h2(vec2 p) { return vec2(hsh(p), hsh(p + 17.3)); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
// returns height of bubble domes in a cell grid of the given scale
float bubbles(vec2 p, float sc, float spd, out vec2 grad) {
	vec2 q = p / sc;
	vec2 cell = floor(q);
	float hgt = 0.0;
	grad = vec2(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cc = cell + vec2(float(i), float(j));
			vec2 r = h2(cc);
			vec2 ctr = cc + 0.2 + 0.6 * r;
			float ph = fract(TIME * spd * (0.6 + 0.8 * r.x) + r.y * 7.0);
			float rad = 0.12 + 0.3 * smoothstep(0.0, 0.85, ph);
			float alive = step(ph, 0.9) * step(0.35, hsh(cc + 3.1));
			vec2 d = q - ctr;
			float dl = length(d);
			float dome = alive * max(0.0, 1.0 - (dl * dl) / (rad * rad));
			hgt = max(hgt, dome * rad);
			grad += alive * step(dl, rad) * (-2.0 * d / (rad * rad)) * rad * 0.5;
			// the pop: a thin expanding ring
			float pr = (ph - 0.9) * 10.0;
			float ring = step(0.9, ph) * (1.0 - pr) * smoothstep(0.05, 0.0, abs(dl - (rad + pr * 0.25)));
			hgt += ring * 0.05;
		}
	}
	return hgt;
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 g1; vec2 g2;
	float b1 = bubbles(wp.xz, 0.55, 0.22 * boil, g1);
	float b2 = bubbles(wp.xz + 31.0, 2.1, 0.07 * boil, g2);
	float conv = vn(wp.xz * 0.12 + vec2(TIME * 0.01, -TIME * 0.013));
	float conv2 = vn(wp.xz * 0.6 - vec2(TIME * 0.03, 0.0));
	vec3 n = normalize(vec3(-(g1.x * 0.35 + g2.x * 0.25 + (conv2 - 0.5) * 0.08), 1.0, -(g1.y * 0.35 + g2.y * 0.25 + (conv - 0.5) * 0.05)));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec3 c = vec3(0.004, 0.0035, 0.003) + vec3(0.006, 0.0045, 0.003) * conv;
	// a dull bronze skin where the surface has rested longest
	c = mix(c, vec3(0.022, 0.016, 0.01), smoothstep(0.65, 0.95, conv) * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.22 + 0.3 * smoothstep(0.4, 0.9, conv) + 0.15 * (b1 + b2);
	SPECULAR = 0.32;
	float glow = 0.0;
	for (int i = 0; i < 24; i++) {
		if (i >= fire_count) { break; }
		vec4 f = fires[i];
		float d = length(wp.xz - f.xy) * (0.7 + 0.6 * vn(wp.xz * 0.35 + f.xy));
		glow += (1.0 - smoothstep(f.z * 0.25, f.z * 1.4, d)) * f.w;
	}
	float flick = 0.75 + 0.25 * vn(wp.xz * 0.9 + vec2(TIME * 2.3, TIME * 1.7));
	vec3 hot = vec3(1.0, 0.36, 0.06) * glow * flick * (0.35 + 1.4 * b1);
	EMISSION = hot * 2.2;
}
"""

const FLAME := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float seed = 0.0;
uniform float energy = 3.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() {
	// cylindrical billboard: keep the quad upright, face the camera
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 org = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 fw = cam - org; fw.y = 0.0; fw = normalize(fw);
	vec3 rt = normalize(cross(vec3(0.0, 1.0, 0.0), fw));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 w = org + rt * VERTEX.x * sx + vec3(0.0, 1.0, 0.0) * VERTEX.y * sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w, 1.0);
}
void fragment() {
	vec2 uv = UV;
	float t = TIME * 1.6 + seed * 11.0;
	float n = vn(vec2(uv.x * 4.0 + seed * 3.0, uv.y * 3.0 + t)) * 0.6 + vn(vec2(uv.x * 9.0 - seed, uv.y * 7.0 + t * 1.7)) * 0.4;
	float y = 1.0 - uv.y;
	float w = (1.0 - abs(uv.x - 0.5) * 2.0);
	float body = smoothstep(0.0, 0.5, w * (1.15 - y) - (n - 0.45) * 0.6 * y);
	body *= smoothstep(0.0, 0.08, y) * (1.0 - smoothstep(0.75, 1.0, y + n * 0.25));
	vec3 col = mix(vec3(1.0, 0.75, 0.3), vec3(0.9, 0.22, 0.03), smoothstep(0.1, 0.7, y));
	ALBEDO = col * body * energy;
	ALPHA = body;
}
"""

const SMOKE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, unshaded;
uniform float seed = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() {
	vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 org = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 fw = cam - org; fw.y = 0.0; fw = normalize(fw);
	vec3 rt = normalize(cross(vec3(0.0, 1.0, 0.0), fw));
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	vec3 w = org + rt * VERTEX.x * sx + vec3(0.0, 1.0, 0.0) * VERTEX.y * sy;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w, 1.0);
}
void fragment() {
	float t = TIME * 0.12 + seed * 5.0;
	vec2 uv = UV;
	float y = 1.0 - uv.y;
	float n = vn(vec2(uv.x * 3.0 + seed, uv.y * 2.0 + t)) * 0.6 + vn(vec2(uv.x * 7.0, uv.y * 5.0 + t * 2.0)) * 0.4;
	float w = 1.0 - abs(uv.x - 0.5) * 2.0;
	float a = smoothstep(0.0, 0.6, w * (0.4 + y) + n * 0.5 - 0.55) * smoothstep(0.0, 0.15, y) * (1.0 - smoothstep(0.55, 1.0, y));
	ALBEDO = vec3(0.07, 0.065, 0.06);
	ALPHA = a * 0.55;
}
"""


static func shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func sand_material(dune: bool) -> ShaderMaterial:
	var m := shader_mat(SAND)
	var p := "res://assets/external/coast_sand_01/coast_sand_01_%s_1k.jpg"
	if ResourceLoader.exists(p % "diff"):
		m.set_shader_parameter("sand_alb", load(p % "diff"))
		m.set_shader_parameter("sand_nrm", load(p % "nor_gl"))
	m.set_shader_parameter("dune", 1.0 if dune else 0.0)
	return m
