extends RefCounted
## Level 90 lot: lawn front and back inside a tall board fence (x -18..22,
## z -14..42) with a chained front gate; the old oak in the back garden; woods
## all round outside the fence, thinning into haze. Trees are grown
## procedurally (tapered branch tubes plus alpha-cut leaf cards).

const FX0 := -18.0
const FX1 := 22.0
const FZ0 := -14.0
const FZ1 := 42.0
const OAK := Vector3(5.0, 0.0, 28.0)
const GATE_X0 := 2.4
const GATE_X1 := 5.8

var lvl
var anchors := {}
var lights: Array = []
var tree_variants: Array = []      # [bark ArrayMesh, leaf ArrayMesh]


func _init(level) -> void:
	lvl = level


func build(node: Node3D) -> void:
	_ground(node)
	var k := GeoKit.new(node, "Yard")
	_fence(k)
	_paths(k)
	k.commit()
	_oak(node)
	_woods(node)
	_dress(node)


# ---------------------------------------------------------------- ground

const GROUND := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 lot = vec4(-18.0, -14.0, 22.0, 42.0);
uniform vec3 oak = vec3(5.0, 0.0, 28.0);
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float seg(vec2 p, vec2 a, vec2 b) { vec2 pa = p - a; vec2 ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0); return length(pa - ba * h); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wp.xz / 2.6;
	float m = vn(wp.xz * 0.11) * 0.6 + vn(wp.xz * 0.43) * 0.4;
	vec3 g = texture(grass_alb, uv).rgb;
	float det = clamp(g.g * 11.0, 0.35, 1.7);
	vec3 mown = det * mix(vec3(0.07, 0.13, 0.03), vec3(0.11, 0.17, 0.04), m);
	// mowing stripes inside the lot
	mown *= 0.93 + 0.07 * step(0.5, fract(wp.x / 3.0));
	vec3 wild = det * mix(vec3(0.08, 0.1, 0.035), vec3(0.13, 0.12, 0.05), m);
	vec3 litter = texture(dirt_alb, wp.xz / 3.0).rgb * vec3(0.62, 0.52, 0.42);
	wild = mix(wild, litter, smoothstep(0.45, 0.75, vn(wp.xz * 0.25)) * 0.8);
	float inside = step(lot.x, wp.x) * step(wp.x, lot.z) * step(lot.y, wp.z) * step(wp.z, lot.w);
	vec3 col = mix(wild, mown, inside);
	// a worn footpath from the deck steps round the back of the oak
	float d = min(seg(wp.xz, vec2(-0.8, 15.6), vec2(3.2, 25.0)), seg(wp.xz, vec2(3.2, 25.0), vec2(6.2, 31.2)));
	float wear = (1.0 - smoothstep(0.35, 0.9 + 0.3 * vn(wp.xz * 1.7), d)) * inside;
	// bare earth and leaf litter under the oak's canopy
	float od = length(wp.xz - oak.xz);
	float shade = (1.0 - smoothstep(3.0, 9.5, od + vn(wp.xz * 0.6) * 2.0)) * 0.75;
	vec3 dirt = texture(dirt_alb, wp.xz / 2.0).rgb * vec3(0.78, 0.68, 0.56);
	col = mix(col, dirt, max(wear * 0.85, shade));
	ALBEDO = col;
	NORMAL_MAP = texture(grass_nrm, uv).rgb;
	ROUGHNESS = 0.95;
}
"""


func _ground(node: Node3D) -> void:
	var sh := Shader.new()
	sh.code = GROUND
	var m := ShaderMaterial.new()
	m.shader = sh
	var ga := "res://assets/external/sparse_grass/sparse_grass_%s_1k.jpg"
	var da := "res://assets/external/dirt_floor/dirt_floor_%s_1k.jpg"
	if ResourceLoader.exists(ga % "diff"):
		m.set_shader_parameter("grass_alb", load(ga % "diff"))
		m.set_shader_parameter("grass_nrm", load(ga % "nor_gl"))
	if ResourceLoader.exists(da % "diff"):
		m.set_shader_parameter("dirt_alb", load(da % "diff"))
	m.set_shader_parameter("lot", Vector4(FX0, FZ0, FX1, FZ1))
	m.set_shader_parameter("oak", OAK)
	MatLib.register("l90_ground", m)
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	var pm := PlaneMesh.new()
	pm.size = Vector2(420.0, 420.0)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	mi.mesh = pm
	mi.material_override = m
	mi.position = Vector3(2.0, 0.0, 14.0)
	node.add_child(mi)
	var k := GeoKit.new(node, "GroundCollision")
	k.add_box_shape(Transform3D(Basis(), Vector3(2.0, -0.25, 14.0)), Vector3(420.0, 0.5, 420.0), "grass")
	k.commit()


# ---------------------------------------------------------------- fence and paths

func _fence_run(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var len := a.distance_to(b)
	var dir := (b - a) / len
	var along_x := absf(dir.x) > 0.5
	var c := (a + b) * 0.5
	var hh := 1.95
	var sz := Vector3(len, hh, 0.04) if along_x else Vector3(0.04, hh, len)
	k.box(c + Vector3(0, hh * 0.5 + 0.05, 0), sz, "l90_fence")
	var n := int(len / 2.4)
	for i in n + 1:
		var p := a + dir * (len * float(i) / maxf(n, 1))
		k.box(p + Vector3(0, 1.0, 0), Vector3(0.1, 2.05, 0.1), "l90_fence_post", GeoKit.ALL, false)
	var off := Vector3(0, 0, 0.05) if along_x else Vector3(0.05, 0, 0)
	for y in [0.35, 1.7]:
		var rs := Vector3(len, 0.09, 0.05) if along_x else Vector3(0.05, 0.09, len)
		k.box(c + Vector3(0, y, 0) + off, rs, "l90_fence_post", GeoKit.ALL, false)
		k.box(c + Vector3(0, y, 0) - off, rs, "l90_fence_post", GeoKit.ALL, false)


func _fence(k: GeoKit) -> void:
	_fence_run(k, Vector3(FX0, 0, FZ0), Vector3(GATE_X0, 0, FZ0))
	_fence_run(k, Vector3(GATE_X1, 0, FZ0), Vector3(FX1, 0, FZ0))
	_fence_run(k, Vector3(FX0, 0, FZ1), Vector3(FX1, 0, FZ1))
	_fence_run(k, Vector3(FX0, 0, FZ0), Vector3(FX0, 0, FZ1))
	_fence_run(k, Vector3(FX1, 0, FZ0), Vector3(FX1, 0, FZ1))
	# the front gate: two leaves, shut, a chain and padlock through them
	var gw := (GATE_X1 - GATE_X0) * 0.5
	for i in 2:
		var x0 := GATE_X0 + gw * i
		k.box(Vector3(x0 + gw * 0.5, 1.0, FZ0), Vector3(gw - 0.06, 1.8, 0.06), "l90_fence_post")
		for y in [0.4, 1.6]:
			k.box(Vector3(x0 + gw * 0.5, y, FZ0 - 0.05), Vector3(gw - 0.1, 0.1, 0.05), "l90_trim", GeoKit.ALL, false)
	for x in [GATE_X0, GATE_X1]:
		k.box(Vector3(x, 1.15, FZ0), Vector3(0.2, 2.3, 0.2), "l90_trim", GeoKit.ALL, false)
	for i in 7:
		k.box(Vector3(GATE_X0 + gw - 0.18 + i * 0.06, 1.05 - absf(i - 3) * 0.03, FZ0 - 0.1), Vector3(0.05, 0.03, 0.03), "l90_chain", GeoKit.ALL, false)
	k.box(Vector3(GATE_X0 + gw, 0.92, FZ0 - 0.12), Vector3(0.07, 0.09, 0.03), "l90_brass", GeoKit.ALL, false)
	anchors["gate"] = Vector3(GATE_X0 + gw, 1.0, FZ0 + 0.6)


func _paths(k: GeoKit) -> void:
	# driveway from the chained gate to the porch, concrete pavers to the door
	k.box_mm(Vector3(GATE_X0, 0.0, FZ0 + 0.2), Vector3(GATE_X1, 0.04, -1.0), "l90_drive", GeoKit.PY | GeoKit.SIDES, false)
	k.box_mm(Vector3(-1.2, 0.0, -6.0), Vector3(0.8, 0.035, -3.3), "l90_paver", GeoKit.PY | GeoKit.SIDES, false)
	k.box_mm(Vector3(0.8, 0.0, -6.0), Vector3(GATE_X0, 0.035, -4.4), "l90_paver", GeoKit.PY | GeoKit.SIDES, false)
	# stepping stones across the lawn from the deck toward the oak
	var r := RandomNumberGenerator.new()
	r.seed = 9091
	var a := Vector3(-0.8, 0, 15.8)
	var b := Vector3(3.2, 0, 25.0)
	for i in 9:
		var p := a.lerp(b, (i + 0.5) / 9.0) + Vector3(r.randf_range(-0.15, 0.15), 0, 0)
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI), p + Vector3(0, 0.015, 0)), Vector3(0.62, 0.03, 0.48), "l90_stone", GeoKit.PY | GeoKit.SIDES, false)


# ---------------------------------------------------------------- trees

const BARK := """
shader_type spatial;
render_mode diffuse_burley;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
uniform vec3 tint = vec3(0.13, 0.11, 0.09);
void fragment() {
	vec2 u = UV * vec2(6.0, 1.6);
	float ridge = vn(vec2(u.x * 2.0, u.y * 0.35)) * 0.6 + vn(u * vec2(5.0, 1.2)) * 0.4;
	float crack = smoothstep(0.32, 0.12, ridge);
	vec3 c = tint * (0.75 + 0.5 * ridge) * (1.0 - crack * 0.55);
	c = mix(c, vec3(0.24, 0.3, 0.14), smoothstep(0.62, 0.9, vn(u * 0.7 + 7.0)) * 0.45 * COLOR.r);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	NORMAL_MAP = normalize(vec3(0.5 + (ridge - 0.5) * 0.6, 0.5, 1.0));
}
"""

const LEAF := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
uniform float sway = 1.0;
void vertex() {
	float t = TIME * 1.3 + NODE_POSITION_WORLD.x * 0.3 + VERTEX.x * 0.2;
	VERTEX += vec3(sin(t), 0.0, cos(t * 0.8)) * 0.04 * sway * COLOR.g;
}
void fragment() {
	// a card of small lobed leaves: cells with an ellipse each
	vec2 g = UV * 7.0;
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float r = hsh(id);
	float a = r * 6.283;
	mat2 rot = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
	vec2 q = rot * (f + (vec2(hsh(id + 3.1), hsh(id + 5.7)) - 0.5) * 0.3);
	float leaf = 1.0 - smoothstep(0.4, 0.48, length(q * vec2(1.0, 1.7)) + 0.05 * sin(q.x * 40.0));
	float edge = length(UV - 0.5) * 2.0;
	float keep = leaf * step(hsh(id + 9.0), 1.02 - edge * 0.5);
	if (keep < 0.5) { discard; }
	vec3 base = mix(vec3(0.16, 0.22, 0.07), vec3(0.3, 0.36, 0.12), COLOR.b);
	base *= 0.75 + 0.5 * r;
	ALBEDO = base * (0.7 + 0.45 * COLOR.r);
	ROUGHNESS = 0.8;
	SPECULAR = 0.25;
	BACKLIGHT = vec3(0.35, 0.42, 0.12);
}
"""


static func materials() -> void:
	var bs := Shader.new()
	bs.code = BARK
	var bm := ShaderMaterial.new()
	bm.shader = bs
	MatLib.register("l90_bark", bm)
	var ls := Shader.new()
	ls.code = LEAF
	var lm := ShaderMaterial.new()
	lm.shader = ls
	MatLib.register("l90_leaf", lm)


## Grow a tree: returns [bark mesh, leaf mesh]. Spreading = how far the main
## limbs lean out (an oak spreads wide, a woodland tree reaches up).
static func grow(seed_value: int, trunk_len: float, trunk_r: float, depth: int, spread: float, leaf_n: int, leaf_size: float) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var bark := SurfaceTool.new()
	bark.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaf := SurfaceTool.new()
	leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
	_branch(bark, leaf, r, Vector3.ZERO, Vector3.UP, trunk_len, trunk_r, depth, depth, spread, leaf_n, leaf_size, 0.0)
	return [bark.commit(), leaf.commit()]


static func _branch(bark: SurfaceTool, leaf: SurfaceTool, r: RandomNumberGenerator, p: Vector3, dir: Vector3, len: float, rad: float,
		depth: int, top: int, spread: float, leaf_n: int, leaf_size: float, v0: float) -> void:
	# a slightly bent limb in three segments
	var segs := 3
	var cur := p
	var d := dir
	var bend := Vector3(r.randf_range(-1, 1), r.randf_range(-0.3, 0.3), r.randf_range(-1, 1)) * 0.18
	var r0 := rad
	var v := v0
	for s in segs:
		var nd := (d + bend).normalized()
		if depth < top:
			nd = (nd + Vector3.UP * 0.05).normalized()
		var nxt := cur + nd * (len / segs)
		var r1 := rad * lerpf(1.0, 0.62, float(s + 1) / segs)
		_tube(bark, cur, nxt, r0, r1, 8 if depth >= top - 1 else 5, v, 1.0 if depth == top else 0.0)
		v += len / segs
		cur = nxt
		d = nd
		r0 = r1
	if depth <= 0:
		_leaves(leaf, r, cur, d, leaf_n, leaf_size)
		return
	var kids := 3 if depth == top else r.randi_range(2, 3)
	if depth == top:
		kids = 4 + r.randi_range(0, 1)
	var phase := r.randf() * TAU
	for i in kids:
		var a := phase + TAU * float(i) / kids + r.randf_range(-0.4, 0.4)
		var out := Vector3(cos(a), 0, sin(a))
		var lean := spread if depth == top else r.randf_range(0.35, 0.8)
		var nd := (d * (1.0 - lean) + out * lean + Vector3.UP * 0.12).normalized()
		var nl := len * (0.95 if depth == top else r.randf_range(0.62, 0.8))
		_branch(bark, leaf, r, cur, nd, nl, r0 * (0.72 if depth == top else 0.66), depth - 1, top, spread, leaf_n, leaf_size, v)
	if depth < top and r.randf() < 0.6:
		_leaves(leaf, r, cur, d, maxi(leaf_n / 2, 2), leaf_size * 0.8)


static func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, sides: int, v: float, moss: float) -> void:
	var ax := (b - a).normalized()
	var u := ax.cross(Vector3.UP if absf(ax.y) < 0.95 else Vector3.RIGHT).normalized()
	var w := ax.cross(u).normalized()
	var l := a.distance_to(b)
	for k in sides:
		var a0 := TAU * float(k) / sides
		var a1 := TAU * float(k + 1) / sides
		var n0 := u * cos(a0) + w * sin(a0)
		var n1 := u * cos(a1) + w * sin(a1)
		var q := [a + n0 * r0, a + n1 * r0, b + n1 * r1, b + n0 * r1]
		var nn := [n0, n1, n1, n0]
		var uv := [Vector2(float(k) / sides, v), Vector2(float(k + 1) / sides, v), Vector2(float(k + 1) / sides, v + l), Vector2(float(k) / sides, v + l)]
		for i in [0, 2, 1, 0, 3, 2]:
			st.set_color(Color(moss, 0, 0))
			st.set_normal(nn[i])
			st.set_uv(uv[i])
			st.add_vertex(q[i])


static func _leaves(st: SurfaceTool, r: RandomNumberGenerator, c: Vector3, d: Vector3, n: int, size: float) -> void:
	for i in n:
		var p := c + d * r.randf_range(-0.2, 0.8) * size + Vector3(r.randf_range(-1, 1), r.randf_range(-0.6, 0.8), r.randf_range(-1, 1)) * size * 0.9
		var nrm := Vector3(r.randf_range(-1, 1), r.randf_range(0.2, 1.2), r.randf_range(-1, 1)).normalized()
		var t1 := nrm.cross(Vector3.FORWARD if absf(nrm.z) < 0.9 else Vector3.RIGHT).normalized()
		var t2 := nrm.cross(t1).normalized()
		var s := size * r.randf_range(0.75, 1.25)
		var q := [p - t1 * s - t2 * s, p + t1 * s - t2 * s, p + t1 * s + t2 * s, p - t1 * s + t2 * s]
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		var shade := clampf(0.4 + (p.y - c.y) / (size * 2.0) * 0.5, 0.2, 1.0)
		var col := Color(shade, 1.0, r.randf())
		var up := (nrm + Vector3.UP).normalized()
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_normal(up)
			st.set_uv(uv[k])
			st.add_vertex(q[k])


func _mi(node: Node3D, mesh: Mesh, mat: String, xf: Transform3D, shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = MatLib.get_mat(mat)
	mi.transform = xf
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	return mi


## The old oak: a short massive trunk, wide low limbs, roots at the base.
func _oak(node: Node3D) -> void:
	var t: Array = grow(9090, 4.0, 0.8, 4, 0.8, 24, 1.5)
	var xf := Transform3D(Basis(Vector3.UP, 0.4).scaled(Vector3.ONE * 1.4), OAK)
	_mi(node, t[0], "l90_bark", xf)
	_mi(node, t[1], "l90_leaf", xf)
	var k := GeoKit.new(node, "OakRoots")
	k.cylinder(OAK + Vector3(0, 2.0, 0), 1.05, 4.0, "l90_bark_col", 10, true, false)
	var rs := SurfaceTool.new()
	rs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := RandomNumberGenerator.new()
	r.seed = 9092
	for i in 9:
		var a := TAU * float(i) / 9.0 + r.randf_range(-0.2, 0.2)
		var out := Vector3(cos(a), 0, sin(a))
		var len := r.randf_range(1.8, 3.4)
		_tube(rs, OAK + out * 0.6 + Vector3(0, 0.75, 0), OAK + out * (0.9 + len * 0.5) + Vector3(0, 0.18, 0), 0.55, 0.26, 7, 0.0, 1.0)
		_tube(rs, OAK + out * (0.9 + len * 0.5) + Vector3(0, 0.18, 0), OAK + out * (1.0 + len) + Vector3(0, -0.1, 0), 0.24, 0.06, 6, 1.0, 1.0)
	_mi(node, rs.commit(), "l90_bark", Transform3D.IDENTITY)
	k.commit()
	# a fallen limb and a rope swing left on the lowest bough
	Props.place(lvl, node, "ph/dead_tree_trunk", OAK + Vector3(-4.2, 0.0, 3.6), 32.0, 0.0, false)
	anchors["oak_back"] = OAK + Vector3(1.0, 0.0, 3.0)


## Woods outside the fence, three grown variants instanced around the lot.
func _woods(node: Node3D) -> void:
	for i in 3:
		tree_variants.append(grow(9100 + i, 6.0 + i * 1.5, 0.3 + i * 0.05, 3, 0.36, 16, 1.6))
	var r := RandomNumberGenerator.new()
	r.seed = 9093
	var xforms: Array = [[], [], []]
	var placed := 0
	var tries := 0
	while placed < 150 and tries < 2000:
		tries += 1
		var p := Vector3(r.randf_range(FX0 - 46.0, FX1 + 46.0), 0.0, r.randf_range(FZ0 - 46.0, FZ1 + 46.0))
		var dx := maxf(FX0 - p.x, p.x - FX1)
		var dz := maxf(FZ0 - p.z, p.z - FZ1)
		var dist := maxf(dx, dz)
		if dist < 3.0:
			continue
		# leave the lane in front of the gate open into the haze
		if p.z < FZ0 and absf(p.x - (GATE_X0 + GATE_X1) * 0.5) < 3.2:
			continue
		var s := r.randf_range(0.85, 1.35)
		var v := r.randi() % 3
		(xforms[v] as Array).append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.95, 1.2), s)), p))
		placed += 1
	for v in 3:
		for part in 2:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = tree_variants[v][part]
			var list: Array = xforms[v]
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Woods%d_%d" % [v, part]
			mmi.multimesh = mm
			mmi.material_override = MatLib.get_mat("l90_bark" if part == 0 else "l90_leaf")
			if part == 1:
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(mmi)


# ---------------------------------------------------------------- dressing

func _dress(node: Node3D) -> void:
	# for-sale sign on the front lawn
	var k := GeoKit.new(node, "Sign")
	var sp := Vector3(-6.5, 0.0, -7.5)
	k.box(sp + Vector3(0, 0.9, 0), Vector3(0.08, 1.8, 0.08), "l90_trim")
	k.box(sp + Vector3(0.6, 1.7, 0), Vector3(1.3, 0.06, 0.06), "l90_trim", GeoKit.ALL, false)
	k.box(sp + Vector3(0.62, 1.25, 0), Vector3(1.0, 0.7, 0.03), "l90_sign", GeoKit.ALL, false)
	k.box(sp + Vector3(0.62, 0.78, 0), Vector3(0.7, 0.18, 0.03), "l90_sign2", GeoKit.ALL, false)
	k.commit()
	for side in [-1.0, 1.0]:
		var lb := Label3D.new()
		lb.text = "FOR SALE\nNEWLY RENOVATED!"
		lb.font_size = 40
		lb.pixel_size = 0.004
		lb.modulate = Color(0.12, 0.16, 0.3)
		lb.outline_size = 0
		lb.position = sp + Vector3(0.62, 1.27, side * 0.02)
		lb.rotation.y = PI if side < 0.0 else 0.0
		node.add_child(lb)
		var lb2 := Label3D.new()
		lb2.text = "MOVE-IN READY"
		lb2.font_size = 26
		lb2.pixel_size = 0.004
		lb2.modulate = Color(0.95, 0.95, 0.9)
		lb2.position = sp + Vector3(0.62, 0.78, side * 0.02)
		lb2.rotation.y = PI if side < 0.0 else 0.0
		node.add_child(lb2)
	anchors["sign"] = sp + Vector3(0.6, 1.2, -0.6)
	# outdoor AC condenser on the east side, a panel off and leaning
	Props.place(lvl, node, "ph/exterior_aircon_unit", Vector3(7.75, 0.0, 7.2), -90.0, 0.0, true)
	Props.place(lvl, node, "ph/metal_trash_can", Vector3(7.7, 0.0, 2.2), -90.0, 0.0, true)
	Props.place(lvl, node, "ph/street_lamp_01", Vector3(GATE_X0 - 0.9, 0.0, FZ0 + 0.8), 0.0, 0.0, true)
	lights.append([Vector3(GATE_X0 - 0.75, 3.7, FZ0 + 0.8), Color(1.0, 0.78, 0.5), 1.3, 9.0])
	Props.place(lvl, node, "ph/security_light", Vector3(-2.6, 3.0, 11.25), 0.0, 0.0, false)
	lights.append([Vector3(-2.6, 2.8, 11.6), Color(1.0, 0.9, 0.72), 0.7, 7.0])
	Props.place(lvl, node, "ph/wooden_picnic_table", Vector3(-9.5, 0.0, 19.0), 80.0, 0.0, true)
	Props.place(lvl, node, "ph/plastic_monobloc_chair_01", Vector3(-3.6, 0.45, 13.6), 200.0, 0.0, true)
	Props.place(lvl, node, "ph/plastic_monobloc_chair_01", Vector3(-5.0, 0.45, 13.4), 160.0, 0.0, true)
	Props.place(lvl, node, "ph/hand_truck", Vector3(6.4, 0.0, -2.6), 200.0, 0.0, false)
	Props.place(lvl, node, "ph/wooden_crate_01", Vector3(-9.0, 0.0, 11.8), 10.0, 0.0, true)
	# tall grass tufts along the fence lines and round the oak
	var r := RandomNumberGenerator.new()
	r.seed = 9094
	for i in 14:
		var side := i % 4
		var p: Vector3
		match side:
			0: p = Vector3(r.randf_range(FX0 + 2.0, FX1 - 3.0), 0.0, FZ1 - 0.5)
			1: p = Vector3(FX0 + 0.5, 0.0, r.randf_range(FZ0 + 2.0, FZ1 - 2.0))
			2: p = Vector3(FX1 - 0.5, 0.0, r.randf_range(FZ0 + 2.0, FZ1 - 2.0))
			_: p = OAK + Vector3(r.randf_range(-6, 6), 0, r.randf_range(-6, 6))
		var yaw := 90.0 if side in [1, 2] else r.randf_range(-20.0, 20.0)
		Props.place(lvl, node, "ph/grass_medium_01", p, yaw, 0.0, false)
	for i in 10:
		var p := Vector3(r.randf_range(FX0 - 4.0, FX1 + 4.0), 0.0, FZ1 + r.randf_range(1.0, 5.0))
		Props.place(lvl, node, "ph/grass_medium_01", p, r.randf_range(-30.0, 30.0), 0.0, false)
	# boulders as garden edging near the oak
	for b in [[Vector3(9.6, 0, 24.0), 20.0], [Vector3(0.0, 0, 31.5), 110.0]]:
		Props.place(lvl, node, "ph/boulder_01", b[0], b[1], 0.7, false)
