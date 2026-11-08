extends RefCounted
## Level 75 dressing: sunlight-like beams from arbitrary ceiling/wall spots, footprints
## and hand patterns (MultiMesh), dug holes, slumped sandcastles, toy-car tracks and the
## plastic toys embedded in the sand.

const BEAM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.86, 0.62);
uniform float strength = 0.22;
void fragment() {
	float along = clamp(UV.y, 0.0, 1.0);
	float edge = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	float motes = 0.85 + 0.15 * sin(UV.x * 61.0 + UV.y * 37.0 + TIME * 0.7);
	ALBEDO = tint;
	ALPHA = strength * edge * mix(1.0, 0.45, along) * motes;
}
"""

const POOL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.85, 0.6);
uniform float strength = 0.55;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	ALBEDO = tint;
	ALPHA = strength * (1.0 - smoothstep(0.35, 1.0, r));
}
"""

const PRINT_SHADER := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform vec3 col : source_color = vec3(0.55, 0.43, 0.24);
uniform int kind = 0;   // 0 bare foot, 1 shoe, 2 small hand
float ell(vec2 p, vec2 c, vec2 r) { return length((p - c) / r); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = 9.0;
	if (kind == 0) {
		d = min(ell(p, vec2(0.0, -0.15), vec2(0.78, 0.55)), ell(p, vec2(0.05, 0.5), vec2(0.5, 0.42)));
		for (int i = 0; i < 5; i++) {
			float fi = float(i);
			d = min(d, ell(p, vec2(-0.55 + fi * 0.27, -0.84 + abs(fi - 1.0) * 0.05), vec2(0.13, 0.13)));
		}
	} else if (kind == 1) {
		d = min(ell(p, vec2(0.0, -0.3), vec2(0.82, 0.62)), ell(p, vec2(0.0, 0.55), vec2(0.62, 0.42)));
		if (fract(p.y * 5.0) < 0.22) { d += 0.25; }
	} else {
		d = ell(p, vec2(0.0, 0.35), vec2(0.62, 0.55));
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			d = min(d, ell(p, vec2(-0.45 + fi * 0.3, -0.45), vec2(0.11, 0.38)));
		}
		d = min(d, ell(p, vec2(0.75, 0.1), vec2(0.12, 0.3)));
	}
	if (d > 1.0) { discard; }
	ALBEDO = col * (0.8 + 0.2 * d);
	ROUGHNESS = 1.0;
}
"""

var L: LevelBase
var P
var root: Node3D
var beam_mat: ShaderMaterial
var pool_mat: ShaderMaterial
var print_mats: Array = []
var old_prints: Array = []        # [Transform3D, kind]
var castles := 0
var tracks := 0
var toy_count := 0


func _init(level: LevelBase, plan) -> void:
	L = level
	P = plan
	root = Node3D.new()
	root.name = "SandDressing"
	L.add_child(root)
	var sh := Shader.new()
	sh.code = BEAM_SHADER
	beam_mat = ShaderMaterial.new()
	beam_mat.shader = sh
	var sh2 := Shader.new()
	sh2.code = POOL_SHADER
	pool_mat = ShaderMaterial.new()
	pool_mat.shader = sh2
	var sh3 := Shader.new()
	sh3.code = PRINT_SHADER
	for kind in 3:
		var m := ShaderMaterial.new()
		m.shader = sh3
		m.set_shader_parameter("kind", kind)
		m.set_shader_parameter("col", Color(0.6, 0.47, 0.27) if kind != 1 else Color(0.56, 0.44, 0.25))
		print_mats.append(m)


func mi(mesh: Mesh, mat: String, pos: Vector3, basis := Basis(), shadows := true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = MatLib.get_mat(mat)
	m.basis = basis
	m.position = pos
	if not shadows:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visibility_range_end = 40.0
	root.add_child(m)
	return m


static func cyl(r_top: float, r_bot: float, h: float, seg: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func boxm(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


# ------------------------------------------------------------------- light beams

## A shaft of sunlight-like glow from src to dst, its glare spot, and the lit pool.
func beam(src: Vector3, dst: Vector3, radius: float, src_n: Vector3) -> void:
	var axis := (src - dst)
	var length := axis.length()
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var m := MeshInstance3D.new()
	m.mesh = cyl(radius, radius * 1.55, length, 16)
	m.material_override = beam_mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.basis = Basis(x, y, x.cross(y))
	m.position = (src + dst) * 0.5
	m.visibility_range_end = 45.0
	root.add_child(m)
	# glare where the light leaves the plaster
	var g := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.4, radius * 2.4)
	g.mesh = q
	g.material_override = MatLib.get_mat("l75_glare")
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.basis = Basis.looking_at(-src_n, Vector3.UP if absf(src_n.y) < 0.9 else Vector3.FORWARD)
	g.position = src + src_n * 0.01
	root.add_child(g)
	# the pool on the sand, stretched along the beam
	var flat := Vector3(dst.x - src.x, 0, dst.z - src.z)
	var stretch := 1.0 + clampf(flat.length() / maxf(src.y - dst.y, 0.5), 0.0, 1.6)
	var pm := MeshInstance3D.new()
	var pl := PlaneMesh.new()
	pl.size = Vector2(radius * 3.4, radius * 3.4 * stretch)
	pm.mesh = pl
	pm.material_override = pool_mat
	pm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fwd := flat.normalized() if flat.length() > 0.05 else Vector3.FORWARD
	pm.basis = Basis(Vector3.UP.cross(fwd).normalized() * -1.0, Vector3.UP, -fwd).orthonormalized()
	pm.position = dst + Vector3(0, 0.06, 0)
	root.add_child(pm)


# ---------------------------------------------------------------- prints & marks

func add_print(pos: Vector3, yaw: float, kind: int, scale: float) -> void:
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(scale, 1.0, scale))
	old_prints.append([Transform3D(b, pos), kind])


## A meandering trail of small bare footprints from a to b.
func trail(a: Vector3, b: Vector3, rng: RandomNumberGenerator, child := true) -> void:
	var stride := 0.36 if child else 0.62
	var foot := 0.13 if child else 0.24
	var d := b - a
	d.y = 0.0
	var n := int(d.length() / stride)
	var dir := d.normalized()
	var wob := rng.randf() * TAU
	var p := a
	for i in n:
		var bend := sin(wob + i * 0.35) * 0.35
		var dd := dir.rotated(Vector3.UP, bend)
		p += dd * stride
		var side := dd.cross(Vector3.UP).normalized() * (0.07 if i % 2 == 0 else -0.07)
		var yaw := atan2(dd.x, dd.z)
		var fp := p + side
		fp.y = P.floor_y(P.cell_at(fp)) + 0.053
		if rng.randf() < 0.9:
			add_print(fp, yaw, 0, foot / 0.26)


## Patterns made with small hands: a ring or a fan of palm prints.
func hand_pattern(c: Vector3, rng: RandomNumberGenerator) -> void:
	var n := 6 + rng.randi() % 7
	var r := rng.randf_range(0.25, 0.55)
	for i in n:
		var a := TAU * i / n
		add_print(c + Vector3(cos(a) * r, 0.0, sin(a) * r), a + PI * 0.5, 2, 0.45)


func commit_prints() -> int:
	var by_kind := [[], [], []]
	for pr in old_prints:
		by_kind[int(pr[1])].append(pr[0])
	var total := 0
	for kind in 3:
		var list: Array = by_kind[kind]
		if list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var pl := PlaneMesh.new()
		pl.size = Vector2(0.11, 0.26)
		mm.mesh = pl
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = print_mats[kind]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mmi)
		total += list.size()
	return total


## Two thin grooves that wander: a toy car pushed through the sand.
func car_tracks(k: GeoKit, a: Vector3, rng: RandomNumberGenerator) -> void:
	var p := a
	var yaw := rng.randf() * TAU
	for i in 34:
		yaw += rng.randf_range(-0.22, 0.22)
		var dir := Vector3(sin(yaw), 0, cos(yaw))
		var side := dir.cross(Vector3.UP).normalized() * 0.03
		for s in [-1.0, 1.0]:
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw), p + side * s + Vector3(0, 0.051, 0)), Vector3(0.012, 0.004, 0.13), "l75_sand_dark", GeoKit.PY, false)
		p += dir * 0.12
	tracks += 1


## A dug hole: dark hollow inside a raised rim of thrown sand.
func hole(c: Vector3, r: float) -> Array:
	var rim := mi(cyl(r * 1.05, r * 1.6, 0.07, 18), "l75_sand", c + Vector3(0, 0.035 + 0.05, 0))
	var pit := mi(cyl(r, r, 0.004, 18), "l75_sand_pit", c + Vector3(0, 0.122, 0), Basis(), false)
	return [rim, pit]


## An attempt at a sandcastle, slumped: a mound, bucket-moulded towers, one fallen.
func castle(c: Vector3, rng: RandomNumberGenerator) -> void:
	mi(cyl(0.32, 0.55, 0.22, 16), "l75_sand_castle", c + Vector3(0, 0.16, 0))
	var n := 2 + rng.randi() % 3
	for i in n:
		var a := TAU * i / n + rng.randf() * 0.4
		var tp := c + Vector3(cos(a) * 0.3, 0.0, sin(a) * 0.3)
		var h := rng.randf_range(0.12, 0.2)
		if rng.randf() < 0.3:
			mi(cyl(0.07, 0.13, 0.08, 12), "l75_sand_castle", tp + Vector3(0, 0.08, 0))
		else:
			mi(cyl(0.075, 0.095, h, 12), "l75_sand_castle", tp + Vector3(0, 0.05 + h * 0.5 + 0.05, 0))
	mi(cyl(0.08, 0.1, 0.16, 12), "l75_sand_castle", c + Vector3(0, 0.27 + 0.08, 0))
	castles += 1


# --------------------------------------------------------------------- toys

const PLASTIC := ["l75_toy_red", "l75_toy_blue", "l75_toy_yellow", "l75_toy_green"]


## A toy embedded in the sand. kind: bucket, shovel, car, doll. Returns the root node.
func toy(kind: String, p: Vector3, yaw: float, rng: RandomNumberGenerator, sink := 0.04) -> Node3D:
	var n := Node3D.new()
	n.position = p + Vector3(0, 0.05 - sink, 0)
	n.rotation = Vector3(rng.randf_range(-0.35, 0.35), yaw, rng.randf_range(-0.35, 0.35))
	root.add_child(n)
	var col: String = PLASTIC[rng.randi() % PLASTIC.size()]
	match kind:
		"bucket":
			_part(n, cyl(0.1, 0.075, 0.16, 16), col, Vector3(0, 0.08, 0))
			_part(n, boxm(Vector3(0.2, 0.012, 0.012)), col, Vector3(0, 0.17, 0))
		"shovel":
			_part(n, boxm(Vector3(0.1, 0.012, 0.12)), col, Vector3(0, 0.01, 0.0))
			_part(n, boxm(Vector3(0.022, 0.022, 0.22)), col, Vector3(0, 0.02, 0.16))
			_part(n, boxm(Vector3(0.07, 0.024, 0.024)), col, Vector3(0, 0.02, 0.27))
		"car":
			_part(n, boxm(Vector3(0.06, 0.03, 0.12)), col, Vector3(0, 0.03, 0))
			_part(n, boxm(Vector3(0.05, 0.026, 0.06)), "l75_toy_glass", Vector3(0, 0.055, -0.01))
			for sx in [-0.034, 0.034]:
				for sz in [-0.04, 0.04]:
					var w := _part(n, cyl(0.016, 0.016, 0.012, 10), "l75_toy_tyre", Vector3(sx, 0.016, sz))
					w.rotation.z = PI * 0.5
		"doll":
			_part(n, boxm(Vector3(0.08, 0.035, 0.12)), "l75_toy_dress", Vector3(0, 0.02, 0))
			var hm := SphereMesh.new()
			hm.radius = 0.04
			hm.height = 0.08
			_part(n, hm, "l75_toy_skin", Vector3(0, 0.03, 0.1))
			for sx in [-0.055, 0.055]:
				_part(n, boxm(Vector3(0.02, 0.02, 0.08)), "l75_toy_skin", Vector3(sx, 0.02, 0.01))
				_part(n, boxm(Vector3(0.024, 0.024, 0.09)), "l75_toy_skin", Vector3(sx * 0.4, 0.02, -0.1))
	toy_count += 1
	return n


func _part(parent: Node3D, mesh: Mesh, mat: String, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = MatLib.get_mat(mat)
	m.position = pos
	m.visibility_range_end = 30.0
	parent.add_child(m)
	return m
