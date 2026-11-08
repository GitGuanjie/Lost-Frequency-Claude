extends RefCounted
## Level 37.1 dressing helpers (static). Geometry only; L037_1.gd owns the state.
##   sprouts   - SOURCE fact 6: "bright red sprouts that illuminate Level 37.1".
##               Thin emissive stalks with swollen tips, rooted in pool walls at
##               the water line, at pillar feet and in wall corners; some grow
##               below the surface. Their glow is a shared material L037_1.gd ramps.
##   camera    - SOURCE (Discovery): a damaged video camera found submerged in a pool.
##   figures   - TESTIMONY (transcript): "people lying at the bottom of that pool".
##               Indistinct, cloth-pale shapes on the floor of the deepest basin.
##   ambassador- SOURCE (Entities): Ambassadors hover across the level at high
##               speed and ignore wanderers. Their look is not on this page, so
##               the silhouette stays dark and undefined.

const Cells := preload("res://levels/L037/L037_cells.gd")
const N := 16
const C := 2.0


static func materials() -> void:
	MatLib.register("l371_sprout", MatLib.standard(Color(0.42, 0.02, 0.03), 0.55, 0.0, Color(1.0, 0.08, 0.06), 0.4))
	MatLib.register("l371_sprout_tip", MatLib.standard(Color(0.7, 0.05, 0.05), 0.35, 0.0, Color(1.0, 0.16, 0.09), 0.8))
	MatLib.register("l371_cam", MatLib.standard(Color(0.05, 0.05, 0.055), 0.55, 0.2))
	MatLib.register("l371_lens", MatLib.standard(Color(0.02, 0.02, 0.03), 0.08, 0.6))
	MatLib.define("l371_cloth", {"albedo_a": Color(0.55, 0.50, 0.47), "albedo_b": Color(0.42, 0.38, 0.36),
		"noise_scale": 3.0, "roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 0.6,
		"stain_amount": 0.5, "stain_color": Color(0.30, 0.10, 0.10)}, "plaster")
	var amb := StandardMaterial3D.new()
	amb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	amb.albedo_color = Color(0.01, 0.0, 0.0, 0.85)
	amb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	MatLib.register("l371_shadowform", amb)


## One cluster of sprouts rooted at `root`, leaning along `out` (unit, horizontal).
static func sprout_cluster(k: GeoKit, r: RandomNumberGenerator, root: Vector3, out: Vector3, count: int) -> void:
	var side := Vector3(-out.z, 0, out.x)
	for n in count:
		var base := root + side * r.randf_range(-0.45, 0.45) + out * r.randf_range(0.0, 0.12) + Vector3.UP * r.randf_range(-0.5, 0.05)
		var length := r.randf_range(0.35, 1.25)
		var dir := (Vector3.UP * r.randf_range(0.8, 1.6) + out * r.randf_range(0.2, 0.9) + side * r.randf_range(-0.4, 0.4)).normalized()
		var segs := 3 if length > 0.8 else 2
		var p := base
		for s in segs:
			var bend := (dir + out * 0.25 * s + side * r.randf_range(-0.15, 0.15)).normalized()
			var seg := length / segs
			var mid := p + bend * seg * 0.5
			k.box_xf(Transform3D(_basis_along(bend), mid), Vector3(0.035 - 0.008 * s, seg, 0.035 - 0.008 * s), "l371_sprout", GeoKit.SIDES, false)
			p += bend * seg
		var tip := r.randf_range(0.025, 0.055)
		k.box_xf(Transform3D(_basis_along(dir), p + dir * tip), Vector3(tip, tip * 2.6, tip), "l371_sprout_tip", GeoKit.ALL, false)
		if r.randf() < 0.35:
			var leaf := p - dir * length * 0.4
			k.box_xf(Transform3D(_basis_along(side.rotated(Vector3.UP, r.randf_range(-0.6, 0.6))), leaf), Vector3(0.02, 0.22, 0.02), "l371_sprout", GeoKit.SIDES, false)


static func _basis_along(y_dir: Vector3) -> Basis:
	var y := y_dir.normalized()
	var x := Vector3.FORWARD.cross(y)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	return Basis(x, y, x.cross(y).normalized()).orthonormalized()


## Candidate sprout roots in a painted cell grid: pool rims at the water line,
## pillar feet and wall feet. Returns [[local Vector3 root, Vector3 out]].
static func sprout_sites(g, r: RandomNumberGenerator) -> Array:
	var rims: Array = []
	var feet: Array = []
	var floors: Array = []
	for j in range(1, N - 1):
		for i in range(1, N - 1):
			if g.solid(i, j):
				continue
			var f: float = g.f(i, j)
			if f < -2.0 and not g.is_res(i, j) and r.randf() < 0.5:
				var a := r.randf() * TAU
				floors.append([Vector3((i + r.randf_range(0.2, 0.8)) * C, f + 0.4, (j + r.randf_range(0.2, 0.8)) * C), Vector3(cos(a), 0, sin(a))])
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var ni: int = i + d.x
				var nj: int = j + d.y
				if not g.inside(ni, nj):
					continue
				var edge := Vector3((i + 0.5 + d.x * 0.5) * C, 0.0, (j + 0.5 + d.y * 0.5) * C)
				var out := Vector3(-d.x, 0, -d.y)
				if g.solid(ni, nj):
					if f > -0.6:
						feet.append([edge + Vector3(0, f, 0), out])
				elif f < -0.8 and g.f(ni, nj) > f + 0.7:
					# pool wall: the neighbour is higher; grow from the wall into the pool
					rims.append([edge + Vector3(0, -0.15, 0), out])
	for p in g.pillars:
		var c := Vector3(float(p["x"]), 0, float(p["z"]))
		var ci := floori(c.x / C)
		var cj := floori(c.z / C)
		var fl: float = g.f(ci, cj)
		if fl < 0.5:
			var ang := r.randf() * TAU
			var out := Vector3(cos(ang), 0, sin(ang))
			feet.append([c + out * (float(p["s"]) * 0.5 + 0.02) + Vector3(0, maxf(fl, -0.4), 0), out])
	return [rims, feet, floors]


## A water-damaged camcorder lying on its side.
static func camera(k: GeoKit, at: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, 1.35)
	k.box_xf(Transform3D(b, at + Vector3(0, 0.055, 0)), Vector3(0.11, 0.1, 0.24), "l371_cam", GeoKit.ALL, false)
	var fwd := Basis(Vector3.UP, yaw) * Vector3(0, 0, -1)
	k.box_xf(Transform3D(b, at + Vector3(0, 0.055, 0) + fwd * 0.15), Vector3(0.07, 0.07, 0.07), "l371_lens", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, yaw + 0.5), at + Vector3(0.09, 0.012, 0.02)), Vector3(0.012, 0.022, 0.07), "l371_cam", GeoKit.ALL, false)


## Indistinct figures lying on a pool floor (TESTIMONY). Pale shapes only.
static func figures(k: GeoKit, r: RandomNumberGenerator, centre: Vector3, spread: Vector2, count: int) -> void:
	for n in count:
		var at := centre + Vector3(r.randf_range(-spread.x, spread.x), 0, r.randf_range(-spread.y, spread.y))
		var yaw := r.randf() * TAU
		var b := Basis(Vector3.UP, yaw)
		var fwd := b * Vector3(0, 0, 1)
		var side := b * Vector3(1, 0, 0)
		var tilt := Basis(fwd, r.randf_range(-0.25, 0.25))
		k.box_xf(Transform3D(tilt * b, at + Vector3(0, 0.13, 0)), Vector3(0.46, 0.24, 0.62), "l371_cloth", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, at + fwd * 0.44 + Vector3(0, 0.1, 0)), Vector3(0.19, 0.19, 0.23), "l371_cloth", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			var leg: Vector3 = at - fwd * 0.62 + side * (0.11 * s) + side * r.randf_range(-0.05, 0.08)
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.2, 0.2)), leg + Vector3(0, 0.08, 0)), Vector3(0.15, 0.15, 0.78), "l371_cloth", GeoKit.ALL, false)
			var arm: Vector3 = at + side * (0.3 * s) + fwd * r.randf_range(-0.1, 0.25)
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.7, 0.7)), arm + Vector3(0, 0.06, 0)), Vector3(0.1, 0.1, 0.55), "l371_cloth", GeoKit.ALL, false)


## Dark, undefined silhouette for an Ambassador fly-past.
static func ambassador() -> Node3D:
	var n := Node3D.new()
	n.name = "AmbassadorPass"
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.45
	cm.height = 2.6
	mi.mesh = cm
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.material_override = MatLib.get_mat("l371_shadowform")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	var trail := MeshInstance3D.new()
	var tm := CapsuleMesh.new()
	tm.radius = 0.25
	tm.height = 4.5
	trail.mesh = tm
	trail.rotation_degrees = Vector3(90, 0, 0)
	trail.position = Vector3(0, 0, 2.2)
	var tmat := (MatLib.get_mat("l371_shadowform") as StandardMaterial3D).duplicate() as StandardMaterial3D
	tmat.albedo_color = Color(0.02, 0.0, 0.0, 0.35)
	trail.material_override = tmat
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(trail)
	n.visible = false
	return n
