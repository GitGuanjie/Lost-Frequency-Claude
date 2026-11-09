extends RefCounted
## Level 149: floating sand isles. One shape function drives the render mesh (sand rim, grass
## heart, rock-and-dirt root hanging into the abyss), the trimesh collision of the top and the
## placement of palms and props. Also: the palm meshes (detailed and distant), the evening sky
## shader and the rain streaks.

const SKY := """
shader_type sky;
uniform vec3 top_col : source_color = vec3(0.14, 0.13, 0.32);
uniform vec3 hor_col : source_color = vec3(0.98, 0.56, 0.36);
uniform vec3 glow_col : source_color = vec3(1.0, 0.42, 0.18);
uniform vec3 east_col : source_color = vec3(0.3, 0.22, 0.42);
uniform vec3 abyss_col : source_color = vec3(0.06, 0.04, 0.1);
uniform vec3 sun_dir = vec3(-0.98, 0.12, 0.1);
uniform float rain = 0.0;
uniform float unrest = 0.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * n2(p); p *= 2.03; a *= 0.5; } return v; }
void sky() {
	vec3 d = EYEDIR;
	vec3 sd = normalize(sun_dir);
	float s = max(dot(d, sd), 0.0);
	float west = clamp(dot(normalize(vec2(d.x, d.z) + 1e-4), normalize(sd.xz)) * 0.5 + 0.5, 0.0, 1.0);
	vec3 hor = mix(east_col, hor_col, pow(west, 1.6));
	vec3 col;
	if (d.y >= 0.0) {
		col = mix(hor, top_col, pow(clamp(d.y, 0.0, 1.0), 0.45));
	} else {
		col = mix(hor * 0.75, abyss_col, pow(clamp(-d.y, 0.0, 1.0), 0.35));
	}
	col += glow_col * (pow(s, 6.0) * 0.55 + pow(s, 40.0) * 0.8);
	// cloud banks above and a cloud sea far below the isles
	vec2 cp = d.xz / (abs(d.y) + 0.12);
	float c = fbm(cp * 1.4 + vec2(TIME * 0.004, 0.0));
	float band = d.y > 0.0 ? smoothstep(0.45, 0.8, c) * smoothstep(0.02, 0.12, d.y) * (1.0 - smoothstep(0.35, 0.7, d.y))
		: smoothstep(0.4, 0.75, c) * smoothstep(-0.03, -0.25, d.y) * 0.85;
	vec3 ccol = mix(vec3(0.36, 0.24, 0.32), vec3(1.0, 0.62, 0.42), pow(west, 2.0) * (0.4 + 0.6 * pow(s, 3.0)));
	col = mix(col, ccol, band * (0.75 + rain * 0.25));
	col += vec3(1.0, 0.8, 0.55) * smoothstep(0.9993, 0.9998, s) * 3.0;
	col = mix(col, vec3(0.32, 0.3, 0.36) * (0.6 + 0.4 * west), rain * 0.55);
	float flick = unrest * (0.5 + 0.5 * sin(TIME * 23.0 + d.y * 40.0)) * smoothstep(0.2, 0.9, 1.0 - west);
	col = mix(col, col * vec3(0.7, 0.6, 1.1) + vec3(0.06, 0.02, 0.1), flick * 0.6);
	COLOR = col;
}
"""

const FROND := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform vec3 col_a : source_color = vec3(0.13, 0.24, 0.07);
uniform vec3 col_b : source_color = vec3(0.24, 0.34, 0.1);
uniform float sway = 1.0;
void vertex() {
	float w = UV.x;
	float t = TIME * 1.3 + MODEL_MATRIX[3].x * 0.07 + MODEL_MATRIX[3].z * 0.05;
	VERTEX.y += sin(t) * 0.04 * w * w * sway;
	VERTEX.x += cos(t * 0.8) * 0.03 * w * sway;
}
void fragment() {
	// UV.x: along the frond (0 base, 1 tip); UV.y: across (-1..1). Leaflets cut by alpha.
	float across = abs(UV.y);
	float taper = 1.0 - smoothstep(0.75, 1.0, UV.x) * 0.9;
	float leaf = fract(UV.x * 26.0 + across * 2.2);
	float a = step(across, taper) * step(0.32, leaf) * step(UV.x, 0.995);
	a = max(a, step(across, 0.06));
	if (a < 0.5) { discard; }
	ALBEDO = mix(col_a, col_b, UV.x * 0.8 + leaf * 0.2) * (0.75 + 0.25 * (1.0 - across));
	ROUGHNESS = 0.7;
	BACKLIGHT = vec3(0.35, 0.45, 0.12);
}
"""

const RAIN := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
uniform float amount = 0.0;
void vertex() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 p = o;
	p.y -= TIME * 9.0;
	p = mod(p - cam + vec3(15.0, 12.0, 15.0), vec3(30.0, 24.0, 30.0)) - vec3(15.0, 12.0, 15.0) + cam;
	vec3 r = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 wv = p + r * VERTEX.x + vec3(0.12, 1.0, 0.0) * VERTEX.y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(wv, 1.0);
}
void fragment() {
	ALBEDO = vec3(0.75, 0.78, 0.85);
	ALPHA = amount * 0.32 * (1.0 - abs(UV.x - 0.5) * 2.0);
}
"""

var L: LevelBase
var palm_mesh: ArrayMesh
var far_palm_mesh: ArrayMesh
var shrub_mesh: ArrayMesh
var frond_mat: ShaderMaterial
var isles: Array = []        # spec dictionaries (with body, node, etc.)


func _init(level: LevelBase) -> void:
	L = level


static func materials() -> void:
	MatLib.define("l149_sand", {"albedo_a": Color(0.78, 0.63, 0.43), "albedo_b": Color(0.7, 0.55, 0.36), "pattern": 13,
		"noise_scale": 0.35, "roughness_a": 0.92, "roughness_b": 1.0, "stain_amount": 0.2, "stain_color": Color(0.55, 0.42, 0.28)}, "")
	MatLib.define("l149_grass", {"albedo_a": Color(0.2, 0.3, 0.08), "albedo_b": Color(0.27, 0.32, 0.1), "pattern": 12,
		"pattern_color": Color(0.36, 0.42, 0.14), "pattern_strength": 0.6, "noise_scale": 0.3, "roughness_a": 0.9}, "")
	MatLib.define("l149_root", {"albedo_a": Color(0.36, 0.27, 0.19), "albedo_b": Color(0.24, 0.2, 0.17), "pattern": 11,
		"pattern_color": Color(0.46, 0.36, 0.26), "pattern_strength": 0.55, "noise_scale": 0.6, "bump_strength": 1.6, "roughness_a": 0.95}, "")
	MatLib.define("l149_trunk", {"albedo_a": Color(0.4, 0.33, 0.24), "albedo_b": Color(0.3, 0.24, 0.17), "pattern": 2,
		"pattern_scale": Vector2(1.0, 6.0), "pattern_color": Color(0.22, 0.17, 0.12), "pattern_strength": 0.6, "roughness_a": 0.9}, "")
	MatLib.register("l149_coconut", MatLib.standard(Color(0.28, 0.2, 0.08), 0.6))


# ------------------------------------------------------------------ isle shape

static func edge_r(spec: Dictionary, th: float) -> float:
	var s: float = spec["seed"]
	return 1.0 + 0.15 * sin(3.0 * th + s) + 0.08 * sin(5.0 * th + s * 1.7) + 0.04 * sin(11.0 * th + s * 2.3)


## Normalised radius (0 centre .. 1 edge) of a local point.
static func rn_of(spec: Dictionary, lx: float, lz: float) -> float:
	var ax := lx / float(spec["rx"])
	var az := lz / float(spec["rz"])
	var th := atan2(az, ax)
	return Vector2(ax, az).length() / edge_r(spec, th)


## Local height of the top surface (relative to spec.c.y).
static func h_local(spec: Dictionary, lx: float, lz: float) -> float:
	var rn := rn_of(spec, lx, lz)
	var s: float = spec["seed"]
	var dome: float = spec["dome"]
	var h := dome * (1.0 - rn * rn)
	h += 0.25 * sin(lx * 0.31 + s) * sin(lz * 0.27 - s)
	h -= smoothstep(0.86, 1.0, rn) * 0.7
	var flat: Array = spec.get("flats", [])
	for f: Vector4 in flat:
		var dd := Vector2(lx - f.x, lz - f.y).length()
		h = lerpf(h, f.z, 1.0 - smoothstep(f.w, f.w + 3.0, dd))
	return h


func ground(spec: Dictionary, lx: float, lz: float) -> Vector3:
	return Vector3(lx, h_local(spec, lx, lz), lz)


## Build an isle under parent. spec keys: c (top centre), rx, rz, seed, dome, depth, rings, segs,
## grass (rn below which grass grows), moving (AnimatableBody3D) ; returns the spec with node/body.
func build(spec: Dictionary, parent: Node3D) -> Dictionary:
	var body: StaticBody3D
	if spec.get("moving", false):
		var ab := AnimatableBody3D.new()
		ab.sync_to_physics = true
		body = ab
	else:
		body = StaticBody3D.new()
	body.name = "Isle_%d" % isles.size()
	body.position = spec["c"]
	parent.add_child(body)
	var rings: int = spec.get("rings", 10)
	var segs: int = spec.get("segs", 28)
	var rx: float = spec["rx"]
	var rz: float = spec["rz"]
	var grass_r: float = spec.get("grass", 0.0)
	var st_s := SurfaceTool.new()
	var st_g := SurfaceTool.new()
	var st_r := SurfaceTool.new()
	for st in [st_s, st_g, st_r]:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var gfaces := PackedVector3Array()
	var pts: Array = []          # [ring][seg] local points
	for i in rings + 1:
		var rn := pow(float(i) / rings, 0.8)
		var row: Array = []
		for j in segs:
			var th := TAU * j / segs
			var e := edge_r(spec, th)
			var lx := cos(th) * rx * rn * e
			var lz := sin(th) * rz * rn * e
			row.append(Vector3(lx, h_local(spec, lx, lz), lz))
		pts.append(row)
	for i in rings:
		for j in segs:
			var j2 := (j + 1) % segs
			var a: Vector3 = pts[i][j]
			var b: Vector3 = pts[i][j2]
			var c: Vector3 = pts[i + 1][j2]
			var dd: Vector3 = pts[i + 1][j]
			var mid_rn := (float(i) + 0.5) / rings
			var gr := grass_r * (1.0 + 0.12 * sin(j * 1.7 + float(spec["seed"])))
			var st: SurfaceTool = st_g if mid_rn < gr else st_s
			for tri in [[a, c, b], [a, dd, c]]:
				_tri(st, spec, tri[0], tri[1], tri[2], true)
				var t0: Vector3 = tri[0]
				var t1: Vector3 = tri[1]
				var t2: Vector3 = tri[2]
				var ordered := PackedVector3Array([t0, t1, t2]) if (t1 - t0).cross(t2 - t0).y < 0.0 else PackedVector3Array([t0, t2, t1])
				if st == st_g:
					gfaces.append_array(ordered)
				else:
					faces.append_array(ordered)
	# the root: rock and dirt narrowing into the abyss
	var depth: float = spec.get("depth", maxf(rx, rz) * 0.9)
	var levels := 6
	var prev: Array = pts[rings]
	for lv in range(1, levels + 1):
		var t := float(lv) / levels
		var row: Array = []
		for j in segs:
			var p0: Vector3 = pts[rings][j]
			var shrink := pow(1.0 - t, 1.25) * (0.95 + 0.1 * sin(j * 2.3 + lv * 1.1 + float(spec["seed"])))
			if lv == levels:
				shrink = 0.0
			var y := p0.y - 0.6 - t * depth * (0.85 + 0.25 * sin(j * 0.9 + float(spec["seed"]) * 3.0) * (1.0 - t * 0.5))
			row.append(Vector3(p0.x * shrink, y, p0.z * shrink))
		for j in segs:
			var j2 := (j + 1) % segs
			_tri(st_r, spec, prev[j], prev[j2], row[j2], false)
			_tri(st_r, spec, prev[j], row[j2], row[j], false)
		prev = row
	var mats := [["l149_sand", st_s], ["l149_grass", st_g], ["l149_root", st_r]]
	for m in mats:
		var stx: SurfaceTool = m[1]
		var mesh := stx.commit()
		if mesh.get_surface_count() == 0:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = MatLib.get_mat(m[0])
		body.add_child(mi)
	for fs in ([] if spec.get("decor", false) else [[faces, "sand"], [gfaces, "grass"]]):
		var arr: PackedVector3Array = fs[0]
		if arr.is_empty():
			continue
		var cs := CollisionShape3D.new()
		var sh := ConcavePolygonShape3D.new()
		sh.set_faces(arr)
		sh.backface_collision = true
		cs.shape = sh
		cs.set_meta("surface", fs[1])
		body.add_child(cs)
	spec["body"] = body
	isles.append(spec)
	return spec


## Triangle with Godot's front-face winding for the wanted side (up for the top, out for the root).
func _tri(st: SurfaceTool, spec: Dictionary, a: Vector3, b: Vector3, c: Vector3, top: bool) -> void:
	var n := (b - a).cross(c - a)
	var want := Vector3.UP if top else Vector3((a.x + b.x + c.x), 0.0, (a.z + b.z + c.z)).normalized() + Vector3(0, -0.3, 0)
	var order := [a, b, c] if n.dot(want) < 0.0 else [a, c, b]
	for v: Vector3 in order:
		if top:
			var e := 0.6
			var nx := h_local(spec, v.x - e, v.z) - h_local(spec, v.x + e, v.z)
			var nz := h_local(spec, v.x, v.z - e) - h_local(spec, v.x, v.z + e)
			st.set_normal(Vector3(nx, 2.0 * e, nz).normalized())
		else:
			st.set_normal((Vector3(v.x, 0.0, v.z).normalized() + Vector3(0, -0.4, 0)).normalized())
		st.set_uv(Vector2(v.x, v.z))
		st.add_vertex(v)


# ------------------------------------------------------------------ palms

## Unit palm (height 1): a leaning, tapering ringed trunk, a crown of drooping fronds, coconuts.
func make_palm_meshes() -> void:
	frond_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = FROND
	frond_mat.shader = sh
	palm_mesh = _palm(8, 10, 11, 7, true)
	shrub_mesh = _shrub()
	far_palm_mesh = _palm(5, 4, 7, 3, false)


func _palm(sides: int, segs: int, fronds: int, fsegs: int, nuts: bool) -> ArrayMesh:
	var trunk := SurfaceTool.new()
	trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lean := 0.1
	var top := Vector3.ZERO
	var rings: Array = []
	for i in segs + 1:
		var t := float(i) / segs
		var c := Vector3(lean * t * t, t, 0.0)
		var r := lerpf(0.0135, 0.009, t) * (1.0 + (0.1 if i % 2 == 1 else 0.0)) * (1.0 + 0.6 * pow(1.0 - t, 8.0))
		var ring: Array = []
		for j in sides:
			var a := TAU * j / sides
			ring.append(c + Vector3(cos(a) * r, 0, sin(a) * r))
		rings.append(ring)
		top = c
	for i in segs:
		for j in sides:
			var j2 := (j + 1) % sides
			var a: Vector3 = rings[i][j]
			var b: Vector3 = rings[i][j2]
			var c: Vector3 = rings[i + 1][j2]
			var d: Vector3 = rings[i + 1][j]
			for tri in [[a, c, b], [a, d, c]]:
				for v: Vector3 in tri:
					var cen := Vector3(lean * v.y * v.y, v.y, 0)
					trunk.set_normal((v - cen).normalized())
					trunk.set_uv(Vector2(float(j) / sides, v.y * 8.0))
					trunk.add_vertex(v)
	var fr := SurfaceTool.new()
	fr.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in fronds:
		var yaw := TAU * f / fronds + 0.3 * sin(f * 2.1)
		var dir := Vector3(cos(yaw), 0, sin(yaw))
		var side := Vector3(-dir.z, 0, dir.x)
		var length := 0.27 + 0.05 * sin(f * 1.3)
		var lift := 0.35 + 0.25 * sin(f * 0.7)
		var prev_c := top
		var prev_w := 0.0
		for s in range(1, fsegs + 1):
			var t := float(s) / fsegs
			var c := top + dir * length * t + Vector3(0, length * (lift * t - 1.1 * t * t), 0)
			var w := 0.055 * sin(PI * minf(t * 1.2, 1.0))
			var t0 := float(s - 1) / fsegs
			var quad := [prev_c - side * prev_w, prev_c + side * prev_w, c + side * w, c - side * w]
			var uvs := [Vector2(t0, -1), Vector2(t0, 1), Vector2(t, 1), Vector2(t, -1)]
			for idx in [[0, 2, 1], [0, 3, 2]]:
				for q: int in idx:
					fr.set_normal((Vector3.UP + dir * 0.2).normalized())
					fr.set_uv(uvs[q])
					fr.add_vertex(quad[q])
			prev_c = c
			prev_w = w
	var mesh := ArrayMesh.new()
	trunk.commit(mesh)
	mesh.surface_set_material(0, MatLib.get_mat("l149_trunk"))
	fr.commit(mesh)
	mesh.surface_set_material(1, frond_mat)
	if nuts:
		var nt := SurfaceTool.new()
		nt.begin(Mesh.PRIMITIVE_TRIANGLES)
		for n in 5:
			var a := TAU * n / 5.0
			var c := top + Vector3(cos(a) * 0.016, -0.015 - 0.01 * (n % 2), sin(a) * 0.016)
			_octa(nt, c, 0.009)
		nt.commit(mesh)
		mesh.surface_set_material(2, MatLib.get_mat("l149_coconut"))
	return mesh


## Undergrowth: a fan of young fronds springing from the ground (unit height).
func _shrub() -> ArrayMesh:
	var fr := SurfaceTool.new()
	fr.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in 9:
		var yaw := TAU * f / 9.0 + 0.4 * sin(f * 3.1)
		var dir := Vector3(cos(yaw), 0, sin(yaw))
		var side := Vector3(-dir.z, 0, dir.x)
		var length := 0.8 + 0.25 * sin(f * 1.9)
		var lift := 1.6 + 0.4 * sin(f * 0.9)
		var prev_c := Vector3.ZERO
		var prev_w := 0.0
		for sgm in range(1, 6):
			var t := float(sgm) / 5.0
			var c := dir * length * t * 0.8 + Vector3(0, length * (lift * t - 1.4 * t * t) * 0.6, 0)
			var w := 0.16 * sin(PI * minf(t * 1.2, 1.0))
			var t0 := float(sgm - 1) / 5.0
			var quad := [prev_c - side * prev_w, prev_c + side * prev_w, c + side * w, c - side * w]
			var uvs := [Vector2(t0, -1), Vector2(t0, 1), Vector2(t, 1), Vector2(t, -1)]
			for idx in [[0, 2, 1], [0, 3, 2]]:
				for q: int in idx:
					fr.set_normal(Vector3.UP)
					fr.set_uv(uvs[q])
					fr.add_vertex(quad[q])
			prev_c = c
			prev_w = w
	var mesh := ArrayMesh.new()
	fr.commit(mesh)
	mesh.surface_set_material(0, frond_mat)
	return mesh


func _octa(st: SurfaceTool, c: Vector3, r: float) -> void:
	var p := [Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, r, 0), Vector3(0, -r, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]
	for f in [[0, 2, 4], [2, 1, 4], [1, 3, 4], [3, 0, 4], [2, 0, 5], [1, 2, 5], [3, 1, 5], [0, 3, 5]]:
		for i: int in f:
			st.set_normal((p[i] as Vector3).normalized())
			st.add_vertex(c + p[i])


## Scatter palms on an isle (local coordinates), clustered in the middle; avoid = [Vector3(x, z, r)].
func palms(spec: Dictionary, count: int, h_min: float, h_max: float, spread: float, rng: RandomNumberGenerator, avoid: Array = [], far := false) -> int:
	var xs: Array = []
	var tries := 0
	while xs.size() < count and tries < count * 8:
		tries += 1
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * spread
		var lx := cos(a) * r * float(spec["rx"])
		var lz := sin(a) * r * float(spec["rz"])
		var bad := false
		for v: Vector3 in avoid:
			if Vector2(lx - v.x, lz - v.y).length() < v.z:
				bad = true
		if bad:
			continue
		var h := rng.randf_range(h_min, h_max)
		var tilt_axis := Vector3(cos(a + 1.3), 0, sin(a + 1.3))
		var b := (Basis(tilt_axis, deg_to_rad(rng.randf_range(2.0, 11.0) * (0.4 + r))) * Basis(Vector3.UP, rng.randf() * TAU)).scaled(Vector3.ONE * h)
		xs.append(Transform3D(b, ground(spec, lx, lz) - Vector3(0, 0.15, 0)))
	var body: Node3D = spec["body"]
	for pass_i in (1 if far else 2):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = far_palm_mesh if (far or pass_i == 1) else palm_mesh
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.name = "Palms" if pass_i == 0 else "PalmsFar"
		if not far:
			if pass_i == 0:
				mi.visibility_range_end = 230.0
				mi.visibility_range_end_margin = 20.0
			else:
				mi.visibility_range_begin = 230.0
				mi.visibility_range_begin_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		body.add_child(mi)
	# one collision post per palm near the walking height of the trunk
	if not far:
		for x: Transform3D in xs:
			var cs := CollisionShape3D.new()
			var cy := CylinderShape3D.new()
			cy.radius = 0.016 * x.basis.get_scale().y
			cy.height = 3.0
			cs.shape = cy
			cs.position = x.origin + Vector3(0, 1.5, 0)
			cs.set_meta("surface", "wood")
			body.add_child(cs)
	return xs.size()


# ------------------------------------------------------------------ sky and rain

func sky_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SKY
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func rain_node() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var qm := QuadMesh.new()
	qm.size = Vector2(0.015, 0.55)
	mm.mesh = qm
	mm.instance_count = 1400
	var r := RandomNumberGenerator.new()
	r.seed = 149
	for i in 1400:
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(r.randf() * 30.0, r.randf() * 24.0, r.randf() * 30.0)))
	var mi := MultiMeshInstance3D.new()
	mi.name = "Rain"
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = RAIN
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.visible = false
	return mi
