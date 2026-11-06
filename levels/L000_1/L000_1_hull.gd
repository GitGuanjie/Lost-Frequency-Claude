extends RefCounted
## Level 0.1 Outer Ring: where the station's hull meets its parent level.
## SOURCE: "Wanderers can easily pass between Level 0 and Level 0.1 by simply
## walking from one section to another"; "when viewed from the sub-section,
## Level 0 appears to be a series of nearly identical floors stacked
## vertically"; vignette: "An enormous lattice of dimly lit rooms surrounds the
## view outside the station". ADAPTATION: a torn hull breach where one Level 0
## hallway runs across the gulf straight into the station; the concourse,
## windows and lift lobby are ours.
## Everything here is built in the Outer Ring's local frame (node at D.TH).

const D := preload("res://levels/L000_1/L000_1_dims.gd")

var lvl
var sys
var th: Node3D
var rng: RandomNumberGenerator
var glass := D.Quads.new()
var noclip_spots: Array = []


func _init(level, systems, frame: Node3D) -> void:
	lvl = level
	sys = systems
	th = frame
	rng = level.rng


func w(p: Vector3) -> Vector3:
	return th.global_transform * p


func build() -> void:
	_concourse()
	_bridge()
	_level0_room()
	glass.commit(th, "HullGlass")


func _concourse() -> void:
	var k := GeoKit.new(th, "Concourse")
	var hh := 4.6
	k.slab(-14.0, D.HULLZ, 14.0, 10.0, 0.0, 0.4, "l01_floor")
	k.slab(-14.0, D.HULLZ - 0.6, -1.6, D.HULLZ, 0.0, 0.4, "l01_floor")
	k.slab(1.6, D.HULLZ - 0.6, 14.0, D.HULLZ, 0.0, 0.4, "l01_floor")
	# the hull: two long windows out to Level 0 and the breach between them
	k.wall(Vector3(-14.0, 0, D.HULLZ - 0.3), Vector3(14.0, 0, D.HULLZ - 0.3), hh, 0.6, "l01_hull_in",
		[{"at": 6.5, "w": 9.0, "h": 2.9, "sill": 0.9}, {"at": 14.0, "w": 3.2, "h": 2.9, "sill": 0.0}, {"at": 21.5, "w": 9.0, "h": 2.9, "sill": 0.9}])
	for cx: float in [-7.5, 7.5]:
		for p in 4:
			var x0: float = cx - 4.5 + 2.25 * p
			glass.box(Vector3(x0 - 0.05, 0.9, D.HULLZ - 0.36), Vector3(x0 + 0.05, 3.8, D.HULLZ - 0.24), "l01_mullion")
		k.box(Vector3(cx, 0.86, D.HULLZ + 0.12), Vector3(9.0, 0.08, 0.3), "l01_trim")
		k.box(Vector3(cx, 2.35, D.HULLZ - 0.3), Vector3(9.0, 2.9, 0.04), "l01_glass")
	# torn edges of the breach: bent plates and loose wires
	for i in 9:
		var side := -1.0 if i % 2 == 0 else 1.0
		var y := rng.randf_range(0.2, 3.2)
		var b := Basis(Vector3.FORWARD, rng.randf_range(-0.8, 0.8)) * Basis(Vector3.UP, side * rng.randf_range(0.3, 0.9))
		k.box_xf(Transform3D(b, Vector3(side * rng.randf_range(1.45, 1.75), y, D.HULLZ - 0.3 + rng.randf_range(-0.4, 0.3))), Vector3(0.5, rng.randf_range(0.3, 0.9), 0.06), "l01_hull_in", GeoKit.ALL, false)
	for i in 5:
		var p := Vector3(rng.randf_range(-1.3, 1.3), 2.95, D.HULLZ - 0.3 + rng.randf_range(-0.3, 0.3))
		var l := rng.randf_range(0.4, 1.1)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)), p - Vector3(0, l * 0.5, 0)), Vector3(0.025, l, 0.025), "l01_wire" if i % 2 else "l01_wire_red", GeoKit.ALL, false)
	k.stairs(Vector3(0, D.L0Y, D.HULLZ - 0.95), Vector3.BACK, 3.0, -D.L0Y, 3, "l01_floor", 0.32)
	# side walls: jammed doors onto collapsed ring corridors
	for sx: float in [-1.0, 1.0]:
		var x := 14.0 * sx
		k.wall(Vector3(x, 0, D.HULLZ - 0.6), Vector3(x, 0, 10.0), hh, 0.3, "l01_hull_in", [{"at": 8.6, "w": 1.8, "h": 2.5}])
		sys.add_door(th, Vector3(x, 0, 2.0), Vector3.BACK, 1.8, 2.5, "stuck")
		k.slab(x, 0.6, x + 4.0 * sx, 3.4, 0.0, 0.4, "l01_floor_dark")
		k.slab(x, 0.6, x + 4.0 * sx, 3.4, 3.0, 0.2, "l01_slab_metal")
		k.wall(Vector3(x, 0, 0.6), Vector3(x + 4.0 * sx, 0, 0.6), 3.0, 0.2, "l01_hull_in")
		k.wall(Vector3(x, 0, 3.4), Vector3(x + 4.0 * sx, 0, 3.4), 3.0, 0.2, "l01_hull_in")
		for i in 7:
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.5, 0.5))
			k.box_xf(Transform3D(b, Vector3(x + sx * rng.randf_range(1.8, 3.6), rng.randf_range(0.3, 2.4), rng.randf_range(1.0, 3.0))), Vector3(rng.randf_range(0.8, 1.6), 0.1, rng.randf_range(0.6, 1.4)), "l01_slab_metal")
		k.box(Vector3(x + sx * 3.9, 1.5, 2.0), Vector3(0.2, 3.0, 2.8), "l01_hull_in")
	k.wall(Vector3(-14.0, 0, 10.0), Vector3(14.0, 0, 10.0), hh, 0.3, "l01_hull_in", [{"at": 14.0, "w": 1.3, "h": 2.3}])
	# structural frames, ceiling beams and conduits
	for i in 8:
		var z := -4.4 + 2.0 * i
		if absf(z - 2.0) < 1.4 or absf(z + 2.6) < 1.5:
			continue
		for sx: float in [-1.0, 1.0]:
			k.box(Vector3(sx * 13.7, hh * 0.5, z), Vector3(0.3, hh, 0.45), "l01_slab_metal")
	for i in 7:
		var z := -4.0 + 2.3 * i
		k.box(Vector3(0, hh - 0.2, z), Vector3(27.4, 0.4, 0.35), "l01_slab_metal", GeoKit.ALL, false)
	for x: float in [-12.0, -6.5, 6.5, 12.0]:
		k.box(Vector3(x, hh * 0.5, 9.7), Vector3(0.45, hh, 0.3), "l01_slab_metal")
	for x: float in [-13.3, -2.2, 2.2, 13.3]:
		k.box(Vector3(x, hh * 0.5, D.HULLZ + 0.2), Vector3(0.5, hh, 0.4), "l01_slab_metal")
	for yy: float in [3.75, 4.0]:
		k.box(Vector3(0, yy, 9.6), Vector3(27.0, 0.12, 0.12), "l01_mullion", GeoKit.ALL, false)
	lvl.lights.add_anchor(w(Vector3(0, 2.3, D.HULLZ + 1.2)), Color(1.0, 0.88, 0.6), 0.9, 7.0, 0.3, "hull")
	k.box(Vector3(0, 2.42, 9.82), Vector3(1.7, 0.24, 0.04), "l01_trim")
	k.slab(-14.0, D.HULLZ - 0.6, 14.0, 10.0, hh + 0.4, 0.4, "l01_slab_metal")
	# ceiling: long strips, half of them dead
	for zr: float in [-3.6, 0.0, 3.6, 7.2]:
		for p in 9:
			var x := -12.0 + 3.0 * p
			var dead := rng.randf() < 0.45
			k.panel(Vector3(x, hh - 0.01, zr), 2.4, 0.3, "l01_panel", 150.0 if dead else rng.randf() * 30.0, 1.0 if rng.randf() < 0.15 else 0.0)
	for p in 3:
		lvl.lights.add_anchor(w(Vector3(-9.0 + 9.0 * p, 3.9, 1.0)), Color(0.82, 0.9, 1.0), 1.4, 12.0, 0.0, "hull")
	lvl.lights.add_anchor(w(Vector3(0, 3.9, 7.6)), Color(0.82, 0.9, 1.0), 0.8, 8.0, 0.2, "hull")
	# benches facing the windows, a dead info pylon, debris
	for bx: float in [-7.5, 7.5]:
		k.box_mm(Vector3(bx - 2.0, 0, -3.4), Vector3(bx + 2.0, 0.45, -2.8), "l01_trim")
	k.box_mm(Vector3(-10.5, 0, 6.0), Vector3(-10.0, 1.9, 6.4), "l01_slab_metal")
	k.box_mm(Vector3(-10.53, 0.9, 6.02), Vector3(-10.51, 1.7, 6.38), "l01_screen", GeoKit.ALL, false)
	for i in 4:
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.2, 0.2))
		k.box_xf(Transform3D(b, Vector3(rng.randf_range(-12.0, 12.0), 0.08, rng.randf_range(1.0, 8.0))), Vector3(1.2, 0.05, 0.6), "l01_slab_metal")
	sys.add_broken_bot(Vector3(9.5, 0, 6.5), rng.randf() * TAU, th)
	k.commit()
	for c in k.root.get_children():
		if c is MeshInstance3D and str(c.name).contains("glass"):
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a still-flickering wall on one side wall: the sourced no-clip route
	var sx := -1.0 if rng.randf() < 0.5 else 1.0
	noclip_spots.append({"pos": Vector3(14.0 * sx - sx * 0.17, 0, -2.6), "along": Vector3.BACK, "n": Vector3(-sx, 0, 0)})


## The Level 0 hallway that runs across the gulf into the hull.
func _bridge() -> void:
	var k := GeoKit.new(th, "Bridge")
	var y := D.L0Y
	var z0 := D.HULLZ - 0.62
	var z1 := D.L0Z
	var h := 2.75
	k.slab(-1.62, z1, 1.62, z0, y, 0.25, "l01_l0carpet")
	k.slab(-1.62, z1, 1.62, z0, y + h + 0.25, 0.25, "l01_l0slab")
	for sx: float in [-1.0, 1.0]:
		var ops: Array = []
		var at := rng.randf_range(4.0, 7.0)
		while at < (z0 - z1) - 3.0:
			ops.append({"at": at, "w": rng.randf_range(1.6, 3.2), "h": rng.randf_range(0.9, 1.4), "sill": 0.95})
			at += rng.randf_range(4.5, 8.0)
		k.wall(Vector3(1.55 * sx, y, z0), Vector3(1.55 * sx, y, z1), h, 0.14, "l01_l0wall", ops)
	var n := 0
	var z := z0 - 1.5
	while z > z1 + 1.0:
		var dead := rng.randf() < 0.2
		k.panel(Vector3(0, y + h - 0.01, z), 0.6, 1.2, "l01_l0panel", 150.0 if dead else rng.randf() * 30.0, 1.0 if rng.randf() < 0.3 else 0.0)
		if n % 2 == 0 and not dead:
			lvl.lights.add_anchor(w(Vector3(0, y + h - 0.3, z)), Color(1.0, 0.93, 0.7), 0.85, 6.0, 0.25, "hull")
		n += 1
		z -= 3.0
	k.commit()
	lvl.sound.emitter("fluorescent_hum", w(Vector3(0, y + 2.4, (z0 + z1) * 0.5)), {"base": 60.0, "rasp": 0.4}, -15.0, 22.0)


## The Level 0 room the hallway opens into: floor 0 of the stack.
func _level0_room() -> void:
	var k := GeoKit.new(th, "L0Room")
	var y := D.L0Y
	var z0 := D.L0Z
	var zb := D.L0Z - 12.0
	var h := 2.75
	k.slab(-6.0, zb, 6.0, z0, y, 0.25, "l01_l0carpet")
	k.slab(-6.0, zb, 6.0, z0, y + h + 0.25, 0.25, "l01_l0ceiling")
	for sx: float in [-1.0, 1.0]:
		k.wall(Vector3(6.0 * sx, y, zb), Vector3(6.0 * sx, y, z0), h, 0.15, "l01_l0wall")
		k.wall(Vector3(1.62 * sx, y, z0), Vector3(6.0 * sx, y, z0), h, 0.15, "l01_l0wall")
		k.box_mm(Vector3(3.4 * sx - 0.3, y, z0 - 6.8), Vector3(3.4 * sx + 0.3, y + h, z0 - 6.2), "l01_l0wall")
	k.wall(Vector3(-6.0, y, zb), Vector3(6.0, y, zb), h, 0.15, "l01_l0wall")
	for px: float in [-3.0, 0.0, 3.0]:
		for pz: float in [z0 - 2.0, z0 - 5.5, z0 - 9.5]:
			k.panel(Vector3(px, y + h - 0.01, pz), 0.6, 1.2, "l01_l0panel", rng.randf() * 30.0, 1.0 if rng.randf() < 0.2 else 0.0)
	lvl.lights.add_anchor(w(Vector3(0, y + 2.3, z0 - 5.0)), Color(1.0, 0.93, 0.68), 1.3, 10.0, 0.0, "hull")
	k.commit()
