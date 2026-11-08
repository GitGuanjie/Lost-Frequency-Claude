extends RefCounted
## Level 1.2 architecture: the Level 1 warehouse grammar (8 m bays, huge square
## pillars with faded two-tone paint, 4.6 m ceiling, pipe runs, hanging tubes),
## a seeded labyrinth of partition walls, the ancient stone terrace with its
## fragile fences, the wanderers' settlement with a lookout, and a sunken bay.

const BAY := 8.0
const HH := 4.6
const X0 := -32.0
const X1 := 32.0
const ZG := -12.0          # garden starts here (concrete threshold north of it)
const Z1 := -92.0
const HALL_Z := 30.0
const TERRACE := Rect2(-30.0, -70.0, 16.0, 20.0)   # x, z, w, d (top +1.2)
const TERRACE_Y := 1.2
const PIT := Rect2(-8.0, -72.0, 16.0, 20.0)        # sunken bay (floor -1.2)
const PIT_Y := -1.2
const LOOKOUT := Rect2(21.6, -50.0, 4.8, 4.0)       # platform +2.4
const LOOKOUT_Y := 2.4

var lvl
var k: GeoKit
var fx: GeoKit
var walls: Array = []         # [{a: Vector3, b: Vector3}] for vine dressing
var pillars: Array = []       # Vector3 bases
var tubes: Array = []         # [{pos, alive}]
var blocked: Array = []       # Rect2 footprints where no plants grow
var fence_node: Node3D
var rubble_node: Node3D
var fence_kit: GeoKit


func _init(level, structure: GeoKit, faces: GeoKit) -> void:
	lvl = level
	k = structure
	fx = faces


static func materials() -> void:
	var m := func(n: String, base: String, a: Color, b: Color, x: Dictionary) -> void:
		x["albedo_a"] = a
		x["albedo_b"] = b
		MatLib.define(n, x, base)
	var c := "concrete"
	m.call("l12_floor", c, Color(0.31, 0.32, 0.31), Color(0.25, 0.26, 0.25), {"pattern": 1, "pattern_scale": Vector2(4.0, 4.0), "grout_width": 0.012,
		"grout_color": Color(0.17, 0.17, 0.16), "stain_amount": 0.55, "stain_color": Color(0.17, 0.16, 0.14), "stain_scale": 0.2, "wetness": 0.45})
	m.call("l12_turf", "grass", Color(0.1, 0.17, 0.06), Color(0.14, 0.2, 0.07), {"pattern": 12, "pattern_color": Color(0.2, 0.3, 0.1), "pattern_strength": 0.6, "noise_scale": 0.4})
	m.call("l12_wall", c, Color(0.44, 0.44, 0.40), Color(0.36, 0.36, 0.33), {"pattern": 1, "pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.006,
		"grout_color": Color(0.30, 0.30, 0.28), "stain_amount": 0.95, "stain_color": Color(0.2, 0.22, 0.13), "stain_scale": 0.55, "grime_height": 1.5,
		"grime_color": Color(0.12, 0.16, 0.09), "wetness": 0.3})
	m.call("l12_pillar", c, Color(0.42, 0.42, 0.40), Color(0.33, 0.33, 0.31), {"stain_amount": 0.8, "stain_color": Color(0.22, 0.24, 0.15),
		"grime_height": 1.2, "grime_color": Color(0.1, 0.15, 0.08), "bump_strength": 1.0})
	m.call("l12_pband", c, Color(0.27, 0.31, 0.28), Color(0.23, 0.27, 0.24), {"stain_amount": 0.5, "roughness_a": 0.6})
	m.call("l12_plinth", c, Color(0.26, 0.26, 0.25), Color(0.21, 0.21, 0.20), {})
	m.call("l12_ceiling", c, Color(0.28, 0.28, 0.27), Color(0.21, 0.21, 0.20), {"stain_amount": 0.85, "stain_color": Color(0.13, 0.12, 0.09), "stain_scale": 0.25})
	m.call("l12_pipe", "metal", Color(0.40, 0.44, 0.40), Color(0.34, 0.28, 0.20), {"metallic_value": 0.5, "stain_amount": 0.6, "stain_color": Color(0.38, 0.22, 0.12)})
	m.call("l12_fixture", "metal", Color(0.70, 0.70, 0.67), Color(0.60, 0.60, 0.57), {"metallic_value": 0.3})
	m.call("l12_stone", "rock", Color(0.56, 0.52, 0.45), Color(0.46, 0.42, 0.36), {"pattern": 4, "pattern_scale": Vector2(0.9, 0.45), "grout_width": 0.02,
		"grout_color": Color(0.3, 0.28, 0.24), "stain_amount": 0.6, "stain_color": Color(0.22, 0.26, 0.14), "bump_strength": 1.6, "wetness": 0.1})
	m.call("l12_stone_rough", "rock", Color(0.5, 0.47, 0.41), Color(0.38, 0.35, 0.3), {"stain_amount": 0.5, "stain_color": Color(0.2, 0.25, 0.12)})
	m.call("l12_vine", "plaster", Color(0.1, 0.17, 0.06), Color(0.16, 0.22, 0.08), {"noise_scale": 6.0, "roughness_a": 0.8, "bump_strength": 0.8})
	m.call("l12_moss", "grass", Color(0.08, 0.15, 0.05), Color(0.13, 0.22, 0.07), {"noise_scale": 1.5, "bump_strength": 1.5})
	m.call("l12_wood", "wood_floor", Color(0.36, 0.27, 0.18), Color(0.28, 0.21, 0.14), {"pattern": 3, "pattern_scale": Vector2(1.6, 0.18), "stain_amount": 0.6,
		"stain_color": Color(0.18, 0.2, 0.1)})
	m.call("l12_tarp_a", "plaster", Color(0.2, 0.32, 0.45), Color(0.16, 0.26, 0.36), {"noise_scale": 3.0, "stain_amount": 0.6, "stain_color": Color(0.2, 0.24, 0.12)})
	m.call("l12_tarp_b", "plaster", Color(0.55, 0.36, 0.16), Color(0.45, 0.3, 0.13), {"noise_scale": 3.0, "stain_amount": 0.6, "stain_color": Color(0.24, 0.24, 0.12)})
	m.call("l12_cloth", "plaster", Color(0.34, 0.3, 0.24), Color(0.28, 0.25, 0.2), {"noise_scale": 4.0, "bump_strength": 0.8})
	MatLib.register("l12_tube", MatLib.panel(Color(0.88, 0.95, 1.0), 2.6))
	MatLib.register("l12_tube_dead", MatLib.panel(Color(0.1, 0.1, 0.1), 0.0, 0.0, 100.0))


## Octagonal pipe from a to b (quads only).
func pipe(a: Vector3, b: Vector3, r: float, mat: String, sides := 8) -> void:
	var ax := b - a
	var ln := ax.length()
	if ln < 0.01:
		return
	var d := ax / ln
	var ref := Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT
	var u := d.cross(ref).normalized()
	var v := d.cross(u).normalized()
	var c := (a + b) * 0.5
	var half := r * sin(PI / sides)
	var apo := r * cos(PI / sides)
	for i in sides:
		var t := TAU * (float(i) + 0.5) / sides
		var n := u * cos(t) + v * sin(t)
		k.quad(c + n * apo, n, d * (ln * 0.5), n.cross(d).normalized() * half, mat)


func _wall(a: Vector3, b: Vector3, ops: Array = [], h := HH) -> void:
	k.wall(a, b, h, 0.3, "l12_wall", ops)
	walls.append({"a": a, "b": b, "ops": ops})
	var mn := Vector2(minf(a.x, b.x) - 0.35, minf(a.z, b.z) - 0.35)
	var mx := Vector2(maxf(a.x, b.x) + 0.35, maxf(a.z, b.z) + 0.35)
	blocked.append(Rect2(mn, mx - mn))


# ------------------------------------------------------------------ shell

func shell(r: RandomNumberGenerator) -> void:
	# floors: the concrete hall, the garden around the sunken bay, the pit
	k.slab(-12, HALL_Z, 12, ZG, 0.0, 0.5, "l12_floor")
	k.slab(X0, ZG, X1, PIT.position.y + PIT.size.y, 0.0, 0.5, "l12_turf")
	k.slab(X0, PIT.position.y, X1, Z1, 0.0, 0.5, "l12_turf")
	k.slab(X0, PIT.position.y + PIT.size.y, PIT.position.x, PIT.position.y, 0.0, 0.5, "l12_turf")
	k.slab(PIT.end.x, PIT.position.y + PIT.size.y, X1, PIT.position.y, 0.0, 0.5, "l12_turf")
	# ceilings
	k.slab(-12, HALL_Z, 12, ZG, HH + 0.4, 0.4, "l12_ceiling")
	k.slab(X0, ZG, X1, Z1, HH + 0.4, 0.4, "l12_ceiling")
	# outer walls
	_wall(Vector3(X0, 0, ZG), Vector3(X0, 0, Z1))
	_wall(Vector3(X1, 0, ZG), Vector3(X1, 0, Z1))
	_wall(Vector3(X0, 0, Z1), Vector3(X1, 0, Z1))
	_wall(Vector3(X0, 0, ZG), Vector3(-12, 0, ZG))
	_wall(Vector3(12, 0, ZG), Vector3(X1, 0, ZG))
	# the concrete hall back toward the rest of Level 1, a dark stub beyond
	_wall(Vector3(-12, 0, ZG), Vector3(-12, 0, HALL_Z))
	_wall(Vector3(12, 0, ZG), Vector3(12, 0, HALL_Z))
	_wall(Vector3(-12, 0, HALL_Z), Vector3(12, 0, HALL_Z), [{"at": 12.0, "w": 5.0, "h": 3.4}])
	k.slab(-2.5, HALL_Z, 2.5, HALL_Z + 8.0, 0.0, 0.5, "l12_floor")
	k.slab(-14.0, HALL_Z + 8.0, 2.5, HALL_Z + 13.0, 0.0, 0.5, "l12_floor")
	k.slab(-14.0, HALL_Z, 2.5, HALL_Z + 13.0, 3.8, 0.4, "l12_ceiling")
	k.wall(Vector3(2.5, 0, HALL_Z), Vector3(2.5, 0, HALL_Z + 13.0), 3.4, 0.3, "l12_wall")
	k.wall(Vector3(-2.5, 0, HALL_Z), Vector3(-2.5, 0, HALL_Z + 8.0), 3.4, 0.3, "l12_wall")
	k.wall(Vector3(-14.0, 0, HALL_Z + 13.0), Vector3(2.5, 0, HALL_Z + 13.0), 3.4, 0.3, "l12_wall")
	k.wall(Vector3(-14.0, 0, HALL_Z + 8.0), Vector3(-2.5, 0, HALL_Z + 8.0), 3.4, 0.3, "l12_wall")
	k.wall(Vector3(-14.0, 0, HALL_Z + 8.0), Vector3(-14.0, 0, HALL_Z + 13.0), 3.4, 0.3, "l12_wall")
	# seeded labyrinth of partition walls on the bay lines ("labyrinthine complex")
	var pick := func(opts: Array) -> float:
		return float(opts[r.randi() % opts.size()])
	_wall(Vector3(X0, 0, -36), Vector3(-12, 0, -36), [{"at": pick.call([8.0, 16.0]), "w": 4.0, "h": 3.2}])
	_wall(Vector3(-12, 0, -36), Vector3(-12, 0, -76), [{"at": 20.0, "w": 4.0, "h": 3.2}, {"at": pick.call([4.0, 12.0]), "w": 4.0, "h": 3.0}])
	_wall(Vector3(12, 0, -28), Vector3(12, 0, -68), [{"at": pick.call([4.0, 12.0]), "w": 4.0, "h": 3.2}, {"at": pick.call([20.0, 28.0, 36.0]), "w": 4.0, "h": 3.2}])
	_wall(Vector3(12, 0, -68), Vector3(X1, 0, -68), [{"at": pick.call([4.0, 12.0]), "w": 4.0, "h": 3.2}])
	_wall(Vector3(X0, 0, -76), Vector3(-12, 0, -76), [{"at": pick.call([8.0, 16.0]), "w": 4.0, "h": 3.2}])
	_wall(Vector3(20, 0, -76), Vector3(20, 0, Z1), [{"at": pick.call([4.0, 12.0]), "w": 4.0, "h": 3.2}])
	var wx := -4.0 if r.randf() < 0.5 else 4.0
	_wall(Vector3(wx, 0, -76), Vector3(wx, 0, Z1), [{"at": pick.call([4.0, 12.0]), "w": 3.0, "h": 3.0}])
	_pillars()
	_pipes_and_tubes(r)


func _pillars() -> void:
	var xs := [-28.0, -20.0, -12.0, -4.0, 4.0, 12.0, 20.0, 28.0]
	var z := 20.0
	while z > Z1 + 1.0:
		for x in xs:
			if z > ZG and absf(x) > 5.0:
				continue
			var p := Vector3(x, 0.0, z)
			var y0 := 0.0
			if PIT.has_point(Vector2(x, z)):
				y0 = PIT_Y
			var h := HH - y0
			k.box(Vector3(x, y0 + h * 0.5, z), Vector3(1.4, h, 1.4), "l12_pillar", GeoKit.SIDES)
			k.box(Vector3(x, y0 + 0.12, z), Vector3(1.48, 0.24, 1.48), "l12_plinth", GeoKit.SIDES | GeoKit.PY, false)
			k.box(Vector3(x, y0 + 0.72, z), Vector3(1.412, 0.96, 1.412), "l12_pband", GeoKit.SIDES, false)
			pillars.append(Vector3(x, y0, z))
			blocked.append(Rect2(x - 0.85, z - 0.85, 1.7, 1.7))
		z -= BAY


func _pipes_and_tubes(r: RandomNumberGenerator) -> void:
	for x in [-9.7, 2.3]:
		pipe(Vector3(x, HH - 0.75, HALL_Z), Vector3(x, HH - 0.75, Z1), 0.12, "l12_pipe")
	for x in [-25.7, 18.3]:
		pipe(Vector3(x, HH - 0.6, ZG), Vector3(x, HH - 0.6, Z1), 0.08, "l12_pipe")
	for zp in [-30.0, -62.0]:
		pipe(Vector3(X0, HH - 0.45, zp), Vector3(X1, HH - 0.45, zp), 0.07, "l12_pipe")
	var z := 24.0
	while z > Z1:
		for x in [-24.0, -16.0, -8.0, 0.0, 8.0, 16.0, 24.0]:
			if z > ZG and absf(x) > 9.0:
				continue
			var depth := clampf((ZG - z) / (ZG - Z1), 0.0, 1.0)
			var alive := r.randf() > 0.12 + depth * 0.45 or Vector2(x, z).distance_to(Vector2(-20.0, -24.0)) < 5.0
			var c := Vector3(x, HH - 0.95, z)
			k.box(c, Vector3(0.28, 0.08, 1.5), "l12_fixture", GeoKit.ALL ^ GeoKit.NY, false)
			fx.panel(c + Vector3.DOWN * 0.042, 0.24, 1.46, "l12_tube" if alive else "l12_tube_dead", float(int(x * 7.0 + z * 3.0)), 0.8 if alive and r.randf() < 0.08 else 0.0)
			for s in [-0.6, 0.6]:
				k.box(Vector3(x, (c.y + HH) * 0.5, z + s), Vector3(0.02, HH - c.y, 0.02), "l12_pipe", GeoKit.SIDES, false)
			tubes.append({"pos": c, "alive": alive})
		z -= BAY


# ------------------------------------------------------------------ set pieces

## The ancient stone terrace: steps, broken columns, wall fragments, an arch.
func terrace(r: RandomNumberGenerator) -> void:
	var t := TERRACE
	k.box_mm(Vector3(t.position.x, -0.1, t.position.y), Vector3(t.end.x, TERRACE_Y, t.end.y), "l12_stone")
	k.stairs(Vector3(-22.0, 0, t.end.y + 4.2), Vector3(0, 0, -1), 4.0, TERRACE_Y, 7, "l12_stone", 0.6)
	k.stairs(Vector3(-9.8, 0, -56.0), Vector3(-1, 0, 0), 3.0, TERRACE_Y, 7, "l12_stone", 0.6)
	blocked.append(Rect2(-24.2, t.end.y, 4.4, 4.4))
	blocked.append(Rect2(-14.2, -57.7, 4.6, 3.4))
	# coping stones along the edge
	for e in [[Vector3(t.position.x, TERRACE_Y, t.position.y), Vector3(t.end.x, TERRACE_Y, t.position.y)],
			[Vector3(t.position.x, TERRACE_Y, t.position.y), Vector3(t.position.x, TERRACE_Y, t.end.y)]]:
		k.wall(e[0], e[1], 0.5, 0.45, "l12_stone_rough")
	# columns: standing, snapped, fallen
	for i in 6:
		var cx := -27.0 + float(i % 3) * 5.5
		var cz := -54.0 - float(i / 3) * 9.0
		var hgt: float = [3.4, 1.4, 2.6, 0.9, 3.4, 2.0][i]
		k.cylinder(Vector3(cx, TERRACE_Y + hgt * 0.5, cz), 0.42, hgt, "l12_stone", 14)
		k.cylinder(Vector3(cx, TERRACE_Y + 0.12, cz), 0.6, 0.24, "l12_stone_rough", 14)
		if hgt < 1.5:
			var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3(1, 0, 0), PI * 0.5)
			k.box_xf(Transform3D(b, Vector3(cx + r.randf_range(-1.6, 1.6), TERRACE_Y + 0.4, cz + r.randf_range(-1.8, 1.8))), Vector3(0.75, 2.2, 0.75), "l12_stone", GeoKit.ALL, true)
	# wall fragments and the gate arch
	k.box_mm(Vector3(-30.0, TERRACE_Y, -69.6), Vector3(-24.0, TERRACE_Y + 2.6, -69.0), "l12_stone")
	k.box_mm(Vector3(-30.0, TERRACE_Y, -69.6), Vector3(-29.4, TERRACE_Y + 1.8, -63.0), "l12_stone")
	k.arch_wall(Vector3(-23.0, TERRACE_Y, -66.0), Vector3(-15.0, TERRACE_Y, -66.0), 3.2, 0.6, "l12_stone", [{"at": 4.0, "w": 2.4, "spring": 1.7}], 12)


## Low stone fences north of the terrace; one of them is fragile (it collapses).
func fences(r: RandomNumberGenerator) -> void:
	for seg in [[Vector3(X0 + 0.3, 0, -41.0), Vector3(-26.0, 0, -41.0)], [Vector3(-18.0, 0, -41.0), Vector3(-13.0, 0, -41.0)]]:
		k.wall(seg[0], seg[1], 0.8, 0.4, "l12_stone_rough")
		blocked.append(Rect2(minf(seg[0].x, seg[1].x), -41.4, absf(seg[1].x - seg[0].x), 0.8))
	# collapsed fences elsewhere (seeded heaps of stone)
	for i in 5:
		var c := Vector3(r.randf_range(-28, 28), 0, r.randf_range(-20, -88))
		if PIT.grow(1.0).has_point(Vector2(c.x, c.z)) or TERRACE.grow(1.0).has_point(Vector2(c.x, c.z)):
			continue
		for j in 6:
			k.box_xf(Transform3D(Basis.from_euler(Vector3(r.randf() * 0.5, r.randf() * TAU, r.randf() * 0.5)), c + Vector3(r.randf_range(-1.2, 1.2), 0.15, r.randf_range(-0.4, 0.4))),
				Vector3(r.randf_range(0.35, 0.6), 0.3, 0.3), "l12_stone_rough", GeoKit.ALL, j < 2)
	# the fragile fence: its own node, swapped for rubble when it gives way
	fence_node = Node3D.new()
	fence_node.name = "FragileFence"
	lvl.add_child(fence_node)
	fence_kit = GeoKit.new(fence_node, "Fence")
	fence_kit.wall(Vector3(-31.4, 0, -45.5), Vector3(-25.0, 0, -45.5), 0.75, 0.42, "l12_stone_rough")
	for i in 8:
		fence_kit.box(Vector3(-31.0 + float(i) * 0.8, 0.8, -45.5), Vector3(0.5, 0.1, 0.46), "l12_stone", GeoKit.ALL, false)
	fence_kit.commit()
	rubble_node = Node3D.new()
	rubble_node.name = "FenceRubble"
	rubble_node.visible = false
	lvl.add_child(rubble_node)
	var rk := GeoKit.new(rubble_node, "Rubble")
	var rr := RandomNumberGenerator.new()
	rr.seed = 4521
	for i in 14:
		rk.box_xf(Transform3D(Basis.from_euler(Vector3(rr.randf() * 0.7, rr.randf() * TAU, rr.randf() * 0.7)), Vector3(rr.randf_range(-31.2, -25.2), 0.12, -45.5 + rr.randf_range(-0.9, 0.9))),
			Vector3(rr.randf_range(0.3, 0.55), 0.25, 0.3), "l12_stone_rough", GeoKit.ALL, false)
	rk.commit()
	blocked.append(Rect2(-31.6, -45.9, 6.8, 0.8))


func collapse_fence() -> void:
	if fence_node == null or not fence_node.visible:
		return
	fence_node.visible = false
	for b in fence_node.find_children("*", "StaticBody3D", true, false):
		(b as StaticBody3D).collision_layer = 0
	rubble_node.visible = true


## The wanderers' settlement: a lookout on posts, fallen tarps, crates.
func settlement(r: RandomNumberGenerator) -> void:
	var l := LOOKOUT
	k.slab(l.position.x, l.position.y, l.end.x, l.end.y, LOOKOUT_Y, 0.16, "l12_wood")
	for p in [Vector2(l.position.x + 0.15, l.position.y + 0.15), Vector2(l.end.x - 0.15, l.position.y + 0.15),
			Vector2(l.position.x + 0.15, l.end.y - 0.15), Vector2(l.end.x - 0.15, l.end.y - 0.15)]:
		k.box(Vector3(p.x, LOOKOUT_Y * 0.5, p.y), Vector3(0.2, LOOKOUT_Y, 0.2), "l12_wood")
		k.box(Vector3(p.x, LOOKOUT_Y + 0.55, p.y), Vector3(0.1, 1.1, 0.1), "l12_wood", GeoKit.ALL, false)
	k.stairs(Vector3(24.0, 0, l.position.y - 3.9), Vector3(0, 0, 1), 1.2, LOOKOUT_Y, 13, "l12_wood", 0.3)
	blocked.append(Rect2(23.2, l.position.y - 4.1, 1.6, 4.2))
	blocked.append(l.grow(0.3))
	for e in [[Vector3(l.position.x, 0, l.end.y), Vector3(l.end.x, 0, l.end.y)], [Vector3(l.position.x, 0, l.position.y), Vector3(l.position.x, 0, l.end.y)],
			[Vector3(l.end.x, 0, l.position.y), Vector3(l.end.x, 0, l.end.y)]]:
		k.box(((e[0] + e[1]) as Vector3) * 0.5 + Vector3(0, LOOKOUT_Y + 1.05, 0), Vector3(maxf(absf(e[1].x - e[0].x), 0.08), 0.08, maxf(absf(e[1].z - e[0].z), 0.08)), "l12_wood", GeoKit.ALL, false)
		k.box(((e[0] + e[1]) as Vector3) * 0.5 + Vector3(0, LOOKOUT_Y + 0.55, 0), Vector3(maxf(absf(e[1].x - e[0].x), 0.12), 1.1, maxf(absf(e[1].z - e[0].z), 0.12)), "l12_wood", 0, true)
	# the settlers' tents: two still standing on their poles, one collapsed flat
	for t in [[Vector3(16.5, 0, -59.5), "l12_tarp_a", 0.4, 1.0], [Vector3(29.0, 0, -42.5), "l12_tarp_b", -0.5, 1.0], [Vector3(16.5, 0, -42.5), "l12_tarp_b", 0.2, 0.25]]:
		var o := Transform3D(Basis(Vector3.UP, float(t[2])), t[0])
		var hgt: float = 1.5 * float(t[3])
		for sd in [-1.0, 1.0]:
			var pan := o * Transform3D(Basis(Vector3(0, 0, 1), sd * (0.75 if t[3] > 0.5 else 1.35)), Vector3(sd * 0.55, hgt * 0.5, 0))
			k.box_xf(pan, Vector3(0.03, hgt / cos(0.75) if t[3] > 0.5 else 1.5, 2.6), t[1], GeoKit.ALL, false)
		if t[3] > 0.5:
			for pz in [-1.25, 1.25]:
				k.box_xf(o * Transform3D(Basis(), Vector3(0, hgt * 0.5, pz)), Vector3(0.05, hgt, 0.05), "l12_wood", GeoKit.ALL, false)
			k.box_xf(o * Transform3D(Basis(), Vector3(0, hgt, 0)), Vector3(0.05, 0.05, 2.7), "l12_wood", GeoKit.ALL, false)
		blocked.append(Rect2(t[0].x - 1.4, t[0].z - 1.4, 2.8, 2.8))
	for i in 7:
		var c := Vector3(r.randf_range(14.0, 30.0), 0, r.randf_range(-40.0, -66.0))
		if l.grow(1.0).has_point(Vector2(c.x, c.z)) or Rect2(22.5, -55.0, 3.0, 6.0).has_point(Vector2(c.x, c.z)):
			continue
		var s := r.randf_range(0.6, 1.0)
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), c + Vector3(0, s * 0.4, 0)), Vector3(s, s * 0.8, s * 0.9), "l12_wood", GeoKit.ALL, true)
		blocked.append(Rect2(c.x - 0.6, c.z - 0.6, 1.2, 1.2))


## The sunken bay: a pit 1.2 m down with a ramp in and steps out.
func pit() -> void:
	var p := PIT
	k.slab(p.position.x, p.position.y, p.end.x, p.end.y, PIT_Y, 0.5, "l12_turf")
	k.ramp(Vector3(0, 0.0, p.end.y), Vector3(0, PIT_Y, p.end.y - 4.0), 6.0, 0.3, "l12_floor")
	k.stairs(Vector3(0, PIT_Y, p.position.y + 3.36), Vector3(0, 0, -1), 3.0, -PIT_Y, 7, "l12_floor", 0.48)
	blocked.append(Rect2(-3.2, p.end.y - 4.2, 6.4, 4.4))
	blocked.append(Rect2(-1.7, p.position.y - 0.2, 3.4, 3.8))
	# retaining walls and a low curb
	k.box_mm(Vector3(p.position.x - 0.3, PIT_Y, p.position.y), Vector3(p.position.x, 0.3, p.end.y), "l12_floor")
	k.box_mm(Vector3(p.end.x, PIT_Y, p.position.y), Vector3(p.end.x + 0.3, 0.3, p.end.y), "l12_floor")
	k.box_mm(Vector3(p.position.x, PIT_Y, p.position.y - 0.3), Vector3(-1.5, 0.3, p.position.y), "l12_floor")
	k.box_mm(Vector3(1.5, PIT_Y, p.position.y - 0.3), Vector3(p.end.x, 0.3, p.position.y), "l12_floor")
	k.box_mm(Vector3(p.position.x, PIT_Y, p.end.y), Vector3(-3.0, 0.3, p.end.y + 0.3), "l12_floor")
	k.box_mm(Vector3(3.0, PIT_Y, p.end.y), Vector3(p.end.x, 0.3, p.end.y + 0.3), "l12_floor")
	for sx in [-3.3, 3.0]:
		k.box_mm(Vector3(sx, PIT_Y, p.end.y - 4.0), Vector3(sx + 0.3, 0.3, p.end.y), "l12_floor")
