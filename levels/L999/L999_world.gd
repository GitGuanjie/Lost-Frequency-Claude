extends RefCounted
## Level 999 world geometry: the starry void (a sky shader with no twinkle,
## stars in every direction, below the island too), the flat island top (one
## polar mesh, fine smoke-grey sand at the rim blending into coarse still dirt
## inward), the rim lip and the large inverted rocky pyramid underneath, dark
## rock crags that jut from the sand (tips of that underside), rocks floating
## motionless past the perimeter and the sand that drifts out and holds there.
## Nothing here has a TIME term: the level does not change.

const SEG := 256

const SKY := """shader_type sky;
uniform vec3 base_col : source_color = vec3(0.004, 0.004, 0.005);
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
float stars(vec3 d, float sc, float th, float sz) {
	vec3 p = d * sc; vec3 c = floor(p); vec3 f = fract(p); float h = h1(c);
	if (h < th) return 0.0;
	vec3 o = vec3(h1(c + 3.1), h1(c + 7.7), h1(c + 1.9)) * 0.6 + 0.2;
	return smoothstep(sz, 0.0, length(f - o)) * (0.3 + 0.7 * (h - th) / (1.0 - th));
}
void sky() {
	vec3 d = EYEDIR;
	vec3 col = base_col;
	if (!AT_CUBEMAP_PASS) {
		// a faint, fixed haze of distant stars along one band (no motion, no twinkle)
		vec3 bn = normalize(vec3(0.35, 0.55, -0.76));
		float b = dot(d, bn);
		float cl = vn(d * 6.0) * 0.6 + vn(d * 15.0) * 0.4;
		float band = exp(-b * b / 0.05) * (0.2 + 0.9 * cl * cl);
		col += vec3(0.05) * band;
		float s = stars(d, 80.0, 0.975, 0.22) * 3.2 + stars(d, 170.0, 0.96, 0.2) * 1.4 + stars(d, 320.0, 0.94, 0.17) * 0.7;
		s *= 1.0 + band * 1.4;
		col += vec3(s);
	} else {
		col = vec3(0.02);
	}
	COLOR = col;
}"""

const GROUND := """shader_type spatial;
render_mode diffuse_burley, specular_disabled;
varying vec3 wp;
varying float dirt;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; dirt = COLOR.r; }
void fragment() {
	float n1 = vn(wp * 0.21); float n2 = vn(wp * 1.7); float n3 = vn(wp * 7.0); float n4 = vn(wp * 23.0);
	float m = smoothstep(0.32, 0.68, dirt + (n1 - 0.5) * 0.55 + (n2 - 0.5) * 0.18);
	// fine smoke-grey sand with shallow, still ripples
	float rip = sin(dot(wp.xz, vec2(0.83, 0.55)) * 3.4 + n1 * 7.0 + n2 * 1.5);
	float rip2 = sin(dot(wp.xz, vec2(0.83, 0.55)) * 9.0 + n1 * 9.0 + n2 * 2.0);
	vec3 sand = vec3(0.085 + 0.02 * n1 + 0.012 * n4 + 0.012 * rip2 + 0.008 * rip);
	// coarse, still dirt: grit, gravel and darker clods, no grass
	float grit = smoothstep(0.62, 0.9, n4) * 0.5 + smoothstep(0.7, 0.95, n3) * 0.6;
	vec3 soil = vec3(0.045 + 0.02 * n2 + 0.012 * n1) * (1.0 - 0.35 * smoothstep(0.55, 0.85, vn(wp * 0.6))) + vec3(0.03) * grit;
	ALBEDO = mix(sand, soil, m);
	ROUGHNESS = 1.0;
	// cheap view-space relief from the same noise (sand ripples / gravel)
	float hx = vn((wp + vec3(0.05, 0.0, 0.0)) * 7.0) - n3;
	float hz = vn((wp + vec3(0.0, 0.0, 0.05)) * 7.0) - n3;
	vec3 bump = vec3(-hx, 0.0, -hz) * mix(0.18, 1.6, m) + vec3(0.83, 0.0, 0.55) * cos(dot(wp.xz, vec2(0.83, 0.55)) * 9.0 + n1 * 9.0 + n2 * 2.0) * 0.14 * (1.0 - m);
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(bump, 0.0)).xyz);
}"""

var lvl
var r := RandomNumberGenerator.new()
var crags: Array = []      # [pos, height]


func _init(level) -> void:
	lvl = level
	r.seed = 99901


static func rad(a: float) -> float:
	return 120.0 + 13.0 * sin(3.0 * a + 0.7) + 7.0 * sin(5.0 * a + 2.1) + 3.5 * sin(11.0 * a + 0.3)


static func rim_dist(p: Vector3) -> float:
	return Vector2(p.x, p.z).length() - rad(atan2(p.z, p.x))


static func materials() -> void:
	MatLib.define("l999_rock", {"albedo_a": Color(0.065, 0.065, 0.065), "albedo_b": Color(0.035, 0.035, 0.035), "pattern": 11,
		"pattern_color": Color(0.1, 0.1, 0.1), "pattern_strength": 0.45, "pattern_scale": Vector2(0.35, 0.35),
		"noise_scale": 0.35, "bump_strength": 2.2, "wetness": 0.0, "roughness_a": 0.9}, "rock")
	MatLib.define("l999_rock_grey", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.12, 0.12, 0.12), "pattern": 11,
		"pattern_color": Color(0.26, 0.26, 0.26), "pattern_strength": 0.45, "pattern_scale": Vector2(0.3, 0.3),
		"noise_scale": 0.25, "bump_strength": 2.0, "wetness": 0.0}, "rock")
	MatLib.define("l999_rock_deep", {"albedo_a": Color(0.15, 0.15, 0.15), "albedo_b": Color(0.09, 0.09, 0.09), "pattern": 11,
		"pattern_color": Color(0.2, 0.2, 0.2), "pattern_strength": 0.4, "pattern_scale": Vector2(0.12, 0.12),
		"noise_scale": 0.12, "bump_strength": 1.6, "wetness": 0.0}, "rock")
	MatLib.define("l999_sandlip", {"albedo_a": Color(0.13, 0.13, 0.13), "albedo_b": Color(0.1, 0.1, 0.1), "pattern": 13,
		"noise_scale": 0.5, "bump_strength": 0.8}, "sand")
	var g := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GROUND
	g.shader = sh
	MatLib.register("l999_ground", g)
	var dust := StandardMaterial3D.new()
	dust.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust.albedo_color = Color(0.36, 0.36, 0.36)
	MatLib.register("l999_dust", dust)


static func sky_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY
	m.shader = sh
	return m


## Dirt weight of a point on the top surface: 0 on the beach, 1 in the forest.
static func dirt_w(x: float, z: float) -> float:
	var d := -rim_dist(Vector3(x, 0, z))
	return clampf((d - 17.0) / 9.0, 0.0, 1.0)


# ------------------------------------------------------------------ the top

func top(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := [0.0, 0.03, 0.07, 0.12, 0.18, 0.25, 0.32, 0.4, 0.48, 0.55, 0.62, 0.68, 0.73, 0.77, 0.8, 0.83, 0.855, 0.875,
		0.895, 0.91, 0.925, 0.94, 0.955, 0.97, 0.985, 1.0]
	var grid: Array = []
	for f in rings:
		var row: Array = []
		for i in SEG:
			var a := TAU * i / SEG
			var rr: float = rad(a) * float(f)
			row.append(Vector3(cos(a) * rr, 0.0, sin(a) * rr))
		grid.append(row)
	for ri in range(1, grid.size()):
		for i in SEG:
			var j := (i + 1) % SEG
			var a: Vector3 = grid[ri - 1][i]
			var b: Vector3 = grid[ri - 1][j]
			var c: Vector3 = grid[ri][j]
			var d: Vector3 = grid[ri][i]
			# clockwise seen from above (Godot front faces)
			if ri == 1:
				_v(st, a)
				_v(st, d)
				_v(st, c)
			else:
				_v(st, a)
				_v(st, c)
				_v(st, b)
				_v(st, a)
				_v(st, d)
				_v(st, c)
	var mi := MeshInstance3D.new()
	mi.name = "IslandTop"
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l999_ground")
	parent.add_child(mi)


func _v(st: SurfaceTool, p: Vector3) -> void:
	st.set_color(Color(dirt_w(p.x, p.z), 0, 0))
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(p.x, p.z))
	st.add_vertex(p)


# --------------------------------------------------------- the underside

## The sand lip and the inverted, irregular rocky pyramid under the island.
func underside(parent: Node3D) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = 9991
	nz.frequency = 0.6
	var nz2 := FastNoiseLite.new()
	nz2.seed = 9992
	nz2.frequency = 2.3
	var levels := [[0.0, 0.0], [-0.8, 0.004], [-2.2, 0.012], [-5.0, 0.03], [-10.0, 0.07], [-18.0, 0.13], [-30.0, 0.21],
		[-46.0, 0.31], [-66.0, 0.43], [-90.0, 0.56], [-118.0, 0.69], [-150.0, 0.81], [-185.0, 0.91], [-215.0, 0.97]]
	var sts := {}
	for mn in ["l999_sandlip", "l999_rock_grey", "l999_rock_deep"]:
		var s := SurfaceTool.new()
		s.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[mn] = s
	var seg := 160
	var prev: Array = []
	for li in levels.size():
		var y: float = levels[li][0]
		var f: float = levels[li][1]
		var ring: Array = []
		for i in seg:
			var a := TAU * i / seg
			# blend the island outline into a four-sided pyramid as we go down
			var sq := 1.0 / maxf(absf(cos(a - 0.4)), absf(sin(a - 0.4)))
			var base := lerpf(rad(a), 118.0 * sq * 0.86, smoothstep(0.0, 0.35, f))
			var rr := base * (1.0 - f)
			if li > 1:
				var ridge := absf(nz2.get_noise_2d(cos(a) * 4.0 + li * 0.7, sin(a) * 4.0)) * 2.0 - 0.6
				rr += nz.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0 + li * 1.3) * (2.0 + f * 26.0) + ridge * (1.0 + f * 9.0)
			ring.append(Vector3(cos(a) * maxf(rr, 0.8), y + (nz2.get_noise_2d(a * 9.0, li * 3.0) * (1.5 + f * 6.0) if li > 2 else 0.0), sin(a) * maxf(rr, 0.8)))
		if li > 0:
			var mn := "l999_sandlip" if li <= 2 else ("l999_rock_grey" if y > -40.0 else "l999_rock_deep")
			for i in seg:
				var j := (i + 1) % seg
				_quad_out(sts[mn], prev[i], prev[j], ring[j], ring[i])
		prev = ring
	var tip := Vector3(14.0, -262.0, -9.0)
	for i in seg:
		_tri_out(sts["l999_rock_deep"], prev[i], prev[(i + 1) % seg], tip)
	for mn in sts.keys():
		var s: SurfaceTool = sts[mn]
		s.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "Underside_" + mn
		mi.mesh = s.commit()
		mi.material_override = MatLib.get_mat(mn)
		parent.add_child(mi)


func _quad_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri_out(st, a, b, c)
	_tri_out(st, a, c, d)


func _tri_out(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var mid := (a + b + c) / 3.0
	var out := Vector3(mid.x, 0.0, mid.z).normalized() + Vector3(0, -0.3, 0)
	var n := (b - a).cross(c - a)
	if n.dot(out) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		var vv: Vector3 = v
		st.set_uv(Vector2((atan2(vv.z, vv.x) + PI) * 60.0, -vv.y))
		st.add_vertex(vv)


# ---------------------------------------------------------------- rocks

## A faceted, irregular rock (subdivided octahedron with noise). Local origin
## at the base centre; height ~1 before scaling.
func rock_mesh(seed_v: int, spike: float) -> ArrayMesh:
	var nz := FastNoiseLite.new()
	nz.seed = seed_v
	nz.frequency = 1.4
	var verts := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var faces := [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	for it in 2:
		var nf: Array = []
		var cache := {}
		for f in faces:
			var m := []
			for e in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
				var key := "%d_%d" % [mini(e[0], e[1]), maxi(e[0], e[1])]
				if not cache.has(key):
					verts.append(((verts[e[0]] as Vector3) + (verts[e[1]] as Vector3)).normalized())
					cache[key] = verts.size() - 1
				m.append(cache[key])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		faces = nf
	var pts: Array = []
	for v in verts:
		var vv: Vector3 = v
		var k := 1.0 + nz.get_noise_3dv(vv * 1.3) * 0.45
		var p := vv * k
		p.y = (p.y + 1.0) * 0.5 * (1.0 + spike * maxf(vv.y, 0.0) * 1.6)
		p.x *= 0.6
		p.z *= 0.6
		pts.append(p)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var c: Vector3 = pts[f[2]]
		var n := (b - a).cross(c - a).normalized()
		if n.dot((a + b + c) / 3.0 - Vector3(0, 0.5, 0)) > 0.0:
			var t := b
			b = c
			c = t
			n = -n
		for v in [a, b, c]:
			var vv: Vector3 = v
			st.set_normal(-n)
			st.set_uv(Vector2(vv.x + vv.z, vv.y) * 3.0)
			st.add_vertex(vv)
	return st.commit()


func _mm(parent: Node3D, mesh: Mesh, xfs: Array, mat: Material, nm: String, vis := 0.0) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.material_override = mat
	if vis > 0.0:
		mi.visibility_range_end = vis
	parent.add_child(mi)
	return mi


## Dark crags jutting from the sand: the tips of the underside, immovable.
func beach_crags(parent: Node3D, col: GeoKit) -> void:
	var meshes := [rock_mesh(11, 1.2), rock_mesh(12, 0.6), rock_mesh(13, 1.8)]
	var groups := [[], [], []]
	for i in 70:
		var a := r.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * (rad(a) - r.randf_range(2.5, 16.0))
		if a > 2.75 and a < 3.4 and rim_dist(p) > -12.0:
			continue
		var h := r.randf_range(1.0, 2.8) if i % 3 else r.randf_range(3.2, 6.5)
		var w := h * r.randf_range(0.7, 1.3)
		var lean := Basis(Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized(), r.randf_range(0.0, 0.3))
		var b := lean * Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(w, h, w * r.randf_range(0.7, 1.2)))
		groups[i % 3].append(Transform3D(b, p - Vector3(0, 0.25 * h, 0)))
		crags.append([p, h])
		col.add_box_shape(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, h * 0.35, 0)), Vector3(w * 0.75, h * 0.7, w * 0.75), "rock")
		# small loose stones around the bigger crags
	for g in 3:
		_mm(parent, meshes[g], groups[g], MatLib.get_mat("l999_rock"), "Crags%d" % g, 260.0)


## Rocks floating in weightless, motionless silence past the perimeter, and the
## fine sand that drifts out and holds in the void around the island.
func void_drift(parent: Node3D) -> void:
	var meshes := [rock_mesh(21, 0.2), rock_mesh(22, 0.5), rock_mesh(23, 0.1)]
	var groups := [[], [], []]
	for i in 70:
		var a := r.randf() * TAU
		var out := r.randf_range(6.0, 60.0) if i < 50 else r.randf_range(70.0, 260.0)
		var y := r.randf_range(-14.0, 6.0) if i < 50 else r.randf_range(-90.0, 40.0)
		var s := r.randf_range(0.3, 2.2) if i < 50 else r.randf_range(2.0, 9.0)
		var p := Vector3(cos(a), 0, sin(a)) * (rad(a) + out) + Vector3(0, y, 0)
		var b := Basis(Vector3(r.randf(), r.randf(), r.randf()).normalized(), r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.6, 1.1), s * r.randf_range(0.7, 1.2)))
		groups[i % 3].append(Transform3D(b, p))
	for g in 3:
		_mm(parent, meshes[g], groups[g], MatLib.get_mat("l999_rock_grey" if g != 1 else "l999_rock"), "FloatingRocks%d" % g)
	# the held sand: thousands of motionless grains in a halo past the beach
	var grain := BoxMesh.new()
	grain.size = Vector3(0.05, 0.05, 0.05)
	var xfs: Array = []
	for i in 7000:
		var a := r.randf() * TAU
		var t := pow(r.randf(), 2.2)
		var out := t * 34.0 - 1.0
		var y := r.randf_range(-0.3, 0.4) + (r.randf() - 0.5) * t * 9.0 - t * 1.5
		var p := Vector3(cos(a), 0, sin(a)) * (rad(a) + out) + Vector3(0, y, 0)
		var s := r.randf_range(0.6, 2.4) * (1.0 + (1.0 - t) * 1.5)
		xfs.append(Transform3D(Basis(Vector3(r.randf(), r.randf(), r.randf()).normalized(), r.randf() * TAU).scaled(Vector3.ONE * s), p))
	var mi := _mm(parent, grain, xfs, MatLib.get_mat("l999_dust"), "HeldSand")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Small stones and clods on the coarse dirt (the soil holds still).
func soil_stones(parent: Node3D, avoid: Callable) -> void:
	var m := rock_mesh(31, 0.0)
	var xfs: Array = []
	for i in 900:
		var a := r.randf() * TAU
		var d := sqrt(r.randf()) * (rad(a) - 20.0)
		var p := Vector3(cos(a) * d, -0.02, sin(a) * d)
		if avoid.call(p):
			continue
		var s := r.randf_range(0.06, 0.28)
		xfs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s * 1.3, s * 0.6, s)), p))
	var mi := _mm(parent, m, xfs, MatLib.get_mat("l999_rock"), "SoilStones", 45.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
