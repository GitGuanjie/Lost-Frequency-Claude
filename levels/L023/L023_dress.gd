extends RefCounted
## Level 23 dressing: cave materials, the sky over the canopy, glow-room growth
## (trees growing into the caverns, hanging roots, glowing fungi and bushes,
## Gardener's Sorries with their silk threads and coloured light), the core's
## downward trees and lush flora, the dense surface forest and tunnel growth.

const C := preload("res://levels/L023/L023_cave.gd")
const P := preload("res://levels/L023/L023_plan.gd")
const Flora := preload("res://levels/L023/L023_flora.gd")

const SKY := """shader_type sky;
void sky() {
	vec3 d = EYEDIR;
	// permanently bathed in light from all directions; one star that never moves
	vec3 col = mix(vec3(0.55, 0.6, 0.5), vec3(0.85, 0.82, 0.62), smoothstep(-0.2, 0.8, d.y));
	vec3 sd = normalize(vec3(0.25, 0.93, -0.27));
	float s = max(dot(d, sd), 0.0);
	col += vec3(1.6, 1.5, 1.2) * pow(s, 900.0) * 6.0 + vec3(0.6, 0.55, 0.35) * pow(s, 18.0) * 0.6;
	COLOR = col;
}"""

const PALETTE := [Color(0.25, 0.75, 1.0), Color(0.3, 1.0, 0.75), Color(0.65, 0.4, 1.0), Color(1.0, 0.45, 0.8),
	Color(0.55, 1.0, 0.35), Color(1.0, 0.75, 0.3), Color(0.3, 0.55, 1.0)]

var lvl
var fl
var plan
var noise: FastNoiseLite
var r := RandomNumberGenerator.new()
var sorry_spots: Array = []
var specks := 0
var surface_trees := 0
var body: StaticBody3D
var root: Node3D


func _init(level, flora, p, n: FastNoiseLite) -> void:
	lvl = level
	fl = flora
	plan = p
	noise = n
	r.seed = 23500
	root = Node3D.new()
	root.name = "Growth"
	lvl.add_child(root)
	body = StaticBody3D.new()
	body.name = "GrowthCollision"
	lvl.add_child(body)


static func materials() -> void:
	MatLib.define("l23_wood", {"albedo_a": Color(0.1, 0.07, 0.045), "albedo_b": Color(0.065, 0.045, 0.03), "pattern": 2,
		"pattern_scale": Vector2(0.35, 1.0), "uv_rotate": 0.5, "pattern_color": Color(0.03, 0.022, 0.016), "pattern_strength": 0.75,
		"noise_scale": 0.35, "bump_strength": 2.0, "stain_amount": 0.55, "stain_color": Color(0.04, 0.075, 0.03), "stain_scale": 0.25, "wetness": 0.35}, "concrete")
	MatLib.define("l23_wood_core", {"albedo_a": Color(0.09, 0.075, 0.05), "albedo_b": Color(0.05, 0.05, 0.035), "pattern": 2,
		"pattern_scale": Vector2(0.5, 1.0), "uv_rotate": 1.2, "pattern_color": Color(0.025, 0.03, 0.02), "pattern_strength": 0.7,
		"noise_scale": 0.25, "bump_strength": 2.0, "stain_amount": 0.75, "stain_color": Color(0.04, 0.1, 0.05), "stain_scale": 0.2, "wetness": 0.5}, "concrete")
	MatLib.define("l23_rootmat", {"albedo_a": Color(0.07, 0.055, 0.035), "albedo_b": Color(0.045, 0.06, 0.03), "noise_scale": 0.9,
		"bump_strength": 1.6, "stain_amount": 0.6, "stain_color": Color(0.03, 0.07, 0.025), "stain_scale": 0.6, "wetness": 0.45}, "dirt")
	MatLib.define("l23_rootmat_g", {"albedo_a": Color(0.05, 0.08, 0.03), "albedo_b": Color(0.04, 0.055, 0.03), "noise_scale": 0.9,
		"bump_strength": 1.4, "stain_amount": 0.5, "stain_color": Color(0.06, 0.05, 0.03), "wetness": 0.4}, "dirt")
	MatLib.define("l23_moss_core", {"albedo_a": Color(0.04, 0.1, 0.04), "albedo_b": Color(0.03, 0.07, 0.035), "pattern": 12,
		"pattern_color": Color(0.06, 0.13, 0.05), "pattern_strength": 0.5, "noise_scale": 0.6, "wetness": 0.5}, "grass")
	MatLib.define("l23_soil", {"albedo_a": Color(0.06, 0.045, 0.03), "albedo_b": Color(0.045, 0.035, 0.025), "noise_scale": 0.7, "bump_strength": 1.5}, "dirt")
	MatLib.define("l23_litter", {"albedo_a": Color(0.075, 0.05, 0.03), "albedo_b": Color(0.05, 0.04, 0.025), "pattern": 12,
		"pattern_color": Color(0.1, 0.07, 0.035), "pattern_strength": 0.5, "noise_scale": 0.5, "bump_strength": 1.2}, "grass")


static func sky_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY
	m.shader = sh
	return m


func _clear(p: Vector3, fps: Array, margin: float) -> bool:
	for f in fps:
		if Vector2(p.x - f[0].x, p.z - f[0].z).length() < float(f[1]) + margin:
			return false
	return true


func _cyl(p: Vector3, rad: float, h: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = rad
	sh.height = h
	cs.shape = sh
	cs.position = p + Vector3(0, h * 0.5, 0)
	cs.set_meta("surface", "wood")
	body.add_child(cs)


## A cluster of Sorries on the ceiling above p: glowing specks, hanging silk
## threads and one pooled coloured light.
func sorries(p: Vector3, n: int, spread: float, energy: float) -> void:
	var top: float = lvl.ceiling_at(p)
	var col: Color = PALETTE[r.randi() % PALETTE.size()]
	var xs: Array = []
	var cs: Array = []
	var tx: Array = []
	var tc: Array = []
	for i in n:
		var a := r.randf() * TAU
		var d := sqrt(r.randf()) * spread
		var q := Vector3(p.x + cos(a) * d, top - r.randf_range(0.15, 0.6) - d * 0.12, p.z + sin(a) * d)
		var c: Color = col.lerp(PALETTE[r.randi() % PALETTE.size()], 0.25 if r.randf() < 0.8 else 0.8)
		xs.append(Flora.xf(q, 0.0, Vector3.ONE * r.randf_range(0.6, 1.6)))
		cs.append(c)
		if r.randf() < 0.45:
			var ln := r.randf_range(0.2, 1.3)
			tx.append(Transform3D(Basis().scaled(Vector3(1, ln, 1)), q - Vector3(0, ln * 0.5, 0)))
			tc.append(c * 0.35)
	fl.mm(root, "speck", xs, fl.glow, cs)
	fl.mm(root, "thread", tx, fl.glow, tc, 40.0)
	specks += n
	lvl.lights.add_anchor(Vector3(p.x, top - 2.0, p.z), col, energy * 1.9, 18.0, 0.05)
	sorry_spots.append(Vector3(p.x, top - 1.0, p.z))


func _floor_point(c: Vector3, rx: float, rz: float) -> Vector3:
	var a := r.randf() * TAU
	var d := sqrt(r.randf())
	return Vector3(c.x + cos(a) * rx * d, c.y, c.z + sin(a) * rz * d)


func glow_room(c: Vector3, rad: Vector3, seed_v: int, fps: Array, density: float) -> void:
	r.seed = seed_v
	var rx := rad.x * 0.78
	var rz := rad.z * 0.78
	# trees that grew into the cavern: floor to ceiling, leaves sprouting
	var trunks: Array = []
	var crowns: Array = []
	for i in int(7 * density):
		var p := _floor_point(c, rx * 0.9, rz * 0.9)
		if not _clear(p, fps, 2.0):
			continue
		var top: float = lvl.ceiling_at(p + Vector3(0, 1.0, 0))
		var h := top - p.y + 1.5
		var s := r.randf_range(1.6, 2.6)
		trunks.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, h, s)), p - Vector3(0, 0.3, 0)))
		_cyl(p, 0.5 * s * 0.9, h)
		for j in 3:
			crowns.append(Flora.xf(p + Vector3(r.randf_range(-3, 3), h * r.randf_range(0.45, 0.8), r.randf_range(-3, 3)), r.randf() * TAU, Vector3.ONE * r.randf_range(1.2, 2.2)))
	fl.mm(root, "gnarl", trunks, fl.bark, [], 0.0, true)
	fl.mm(root, "bush", crowns, fl.leaf)
	# roots hanging from the ceiling
	var roots: Array = []
	for i in int(40 * density):
		var p := _floor_point(c, rx, rz)
		var top: float = lvl.ceiling_at(p + Vector3(0, 1.0, 0))
		var ln := r.randf_range(2.0, minf(8.0, top - p.y - 2.5))
		if ln < 1.0:
			continue
		var s := r.randf_range(0.7, 2.2)
		roots.append(Transform3D(Basis(Vector3.RIGHT, PI).scaled(Vector3(s, ln, s)), Vector3(p.x, top + 0.5, p.z)))
	fl.mm(root, "root", roots, fl.bark)
	# Sorries
	for i in int(7 * density):
		var p := _floor_point(c, rx * 0.8, rz * 0.8)
		sorries(p + Vector3(0, 1.0, 0), int(r.randf_range(180, 320)), r.randf_range(2.5, 4.5), 1.7)
	_floor_growth(c, rx, rz, fps, int(260 * density), int(36 * density))


func _floor_growth(c: Vector3, rx: float, rz: float, fps: Array, n_fungi: int, n_bush: int) -> void:
	var fx: Array = []
	var fcol: Array = []
	var clumps := n_fungi / 12
	for i in clumps:
		var a := r.randf() * TAU
		var p := Vector3(c.x + cos(a) * rx * r.randf_range(0.6, 1.02), c.y, c.z + sin(a) * rz * r.randf_range(0.6, 1.02))
		if not _clear(p, fps, 0.5):
			continue
		var col: Color = PALETTE[r.randi() % PALETTE.size()]
		for j in 12:
			var q := p + Vector3(r.randf_range(-1.2, 1.2), -0.02, r.randf_range(-1.2, 1.2))
			fx.append(Flora.xf(q, r.randf() * TAU, Vector3.ONE * r.randf_range(0.6, 2.6)))
			fcol.append(col * r.randf_range(0.6, 1.1))
	fl.mm(root, "mushroom", fx, fl.glow_soft, fcol, 70.0)
	var bx: Array = []
	var gx: Array = []
	var gc: Array = []
	for i in n_bush:
		var p := _floor_point(c, rx, rz)
		if not _clear(p, fps, 1.0):
			continue
		var t := Flora.xf(p + Vector3(0, 0.3, 0), r.randf() * TAU, Vector3(1, 0.7, 1) * r.randf_range(0.5, 1.1))
		if r.randf() < 0.3:
			gx.append(t)
			gc.append((PALETTE[r.randi() % PALETTE.size()] as Color) * 0.35)
		else:
			bx.append(t)
	fl.mm(root, "bush", bx, fl.leaf)
	fl.mm(root, "glowbush", gx, fl.glow_soft, gc)


func core(giants: Array, fps: Array) -> void:
	r.seed = 23600
	var c := P.CORE
	# trees growing down from the spherical ceiling
	var trunks: Array = []
	var tips: Array = []
	for i in 14:
		var a := r.randf() * TAU
		var d := r.randf_range(10.0, 30.0)
		var p := c + Vector3(cos(a) * d, 1.0, sin(a) * d)
		var top: float = lvl.ceiling_at(p)
		var ln := r.randf_range(7.0, minf(15.0, top - c.y - 4.0))
		var s := r.randf_range(1.4, 2.4)
		trunks.append(Transform3D(Basis(Vector3.RIGHT, PI).scaled(Vector3(s, ln, s)), Vector3(p.x, top + 1.0, p.z)))
		for j in 3:
			tips.append(Flora.xf(Vector3(p.x, top + 1.0 - ln, p.z) + Vector3(r.randf_range(-2, 2), r.randf_range(-0.5, 1.5), r.randf_range(-2, 2)), r.randf() * TAU, Vector3.ONE * r.randf_range(1.4, 2.6)))
	fl.mm(root, "gnarl", trunks, fl.bark)
	fl.mm(root, "crown", tips, fl.leaf)
	for g in giants:
		var gp: Vector3 = g[0]
		lvl.lights.add_anchor(gp + Vector3(0, 3.0, 0) - (gp - c).normalized() * (float(g[1]) + 1.5), Color(0.4, 0.95, 0.7), 2.4, 16.0)
	for i in 6:
		var a := r.randf() * TAU
		sorries(c + Vector3(cos(a), 0, sin(a)) * r.randf_range(14.0, 28.0) + Vector3(0, 1.0, 0), 220, 4.0, 1.4)
	_floor_growth(c, 30.0, 30.0, fps + [[c, P.HEART_R + 0.5]], 420, 60)


func surface(fps: Array) -> void:
	r.seed = 23700
	var c := P.SURF
	var kinds := {"conifer": [[], [], fl.bark], "hardwood": [[], [], fl.bark], "aspen": [[], [], fl.pale]}
	var mouth: Vector3 = P.SURF + Vector3(-17.0, 0, 0)
	var x := -36.0
	while x <= 36.0:
		var z := -36.0
		while z <= 36.0:
			var p := c + Vector3(x + r.randf_range(-1.2, 1.2), 0, z + r.randf_range(-1.2, 1.2))
			var e := Vector2((p.x - c.x) / 33.0, (p.z - c.z) / 33.0).length()
			z += 3.6 if e < 0.8 else 2.0
			if e > 1.02:
				continue
			if Vector2(p.x - mouth.x, p.z - mouth.z).length() < 7.0 and e < 0.8:
				continue
			if e < 0.8 and r.randf() < 0.25:
				continue
			var roll := r.randf()
			var kind := "conifer" if roll < 0.42 else ("hardwood" if roll < 0.75 else "aspen")
			var s := r.randf_range(0.8, 1.25)
			var yaw := r.randf() * TAU
			kinds[kind][0].append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p - Vector3(0, 0.2, 0)))
			match kind:
				"conifer":
					kinds[kind][1].append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p))
				"hardwood":
					kinds[kind][1].append(Flora.xf(p + Vector3(0, 23.0 * s, 0), yaw, Vector3(3.2, 2.4, 3.2) * s))
				"aspen":
					kinds[kind][1].append(Flora.xf(p + Vector3(0, 18.0 * s, 0), yaw, Vector3(1.6, 2.2, 1.6) * s))
			_cyl(p, {"conifer": 0.8, "hardwood": 1.0, "aspen": 0.3}[kind] * s, 6.0)
			surface_trees += 1
		x += 3.4
	for kind in kinds.keys():
		fl.mm(root, kind, kinds[kind][0], kinds[kind][2], [], 0.0, false)
		fl.mm(root, {"conifer": "cones", "hardwood": "crown", "aspen": "aspen_crown"}[kind], kinds[kind][1], fl.leaf)
	# low growth and fallen trunks in the gloom
	var bx: Array = []
	for i in 140:
		var p := c + Vector3(r.randf_range(-30, 30), 0.2, r.randf_range(-30, 30))
		bx.append(Flora.xf(p, r.randf() * TAU, Vector3(1, 0.5, 1) * r.randf_range(0.4, 0.9)))
	fl.mm(root, "bush", bx, fl.leaf, [], 40.0)
	for i in 6:
		Props.place(lvl, root, "ph/dead_tree_trunk", c + Vector3(r.randf_range(-24, 24), 0.0, r.randf_range(-24, 24)), r.randf() * 360.0, 0.0, false)
	# where a little light gets through: one gap toward the star
	lvl.lights.add_anchor(mouth + Vector3(4.0, 9.0, -2.0), Color(1.0, 0.9, 0.65), 1.3, 22.0)
	var shaft := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.0, 40.0, 3.0)
	shaft.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.albedo_color = Color(0.2, 0.18, 0.1, 0.12)
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft.material_override = sm
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shaft.position = mouth + Vector3(4.0, 20.0, -2.0) + Vector3(5.0, 0, -5.4)
	shaft.rotation = Vector3(0.27, 0.0, -0.25)
	root.add_child(shaft)


func tunnels() -> void:
	r.seed = 23800
	for k in plan.paths.keys():
		var pts: Array = plan.paths[k]
		for i in range(1, pts.size() - 1):
			var p: Vector3 = (pts[i] as Vector3)
			if P.zone_of(p + Vector3(0, 1.0, 0)) == 3:
				continue
			sorries(p + Vector3(0, 1.0, 0), 70, 1.6, 0.9)
		var fx: Array = []
		var fcol: Array = []
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			for j in 8:
				var q := a.lerp(b, r.randf())
				var side := (b - a).cross(Vector3.UP).normalized() * r.randf_range(1.4, 2.0) * (1.0 if r.randf() < 0.5 else -1.0)
				fx.append(Flora.xf(q + side + Vector3(0, 0.05, 0), r.randf() * TAU, Vector3.ONE * r.randf_range(0.6, 1.8)))
				fcol.append((PALETTE[r.randi() % PALETTE.size()] as Color) * 0.8)
		fl.mm(root, "mushroom", fx, fl.glow_soft, fcol, 60.0)
