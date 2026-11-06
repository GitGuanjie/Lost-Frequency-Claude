extends RefCounted
## Level 289 geometry kit: materials, primitives (hex tubes, scum lines, slab
## soffits with shafts, caged work lamps) and the bay pieces that the chunk
## builder in L289_geo.gd assembles: scaffold runs with board walkways,
## shoring props, block partitions, sumps, collapsed slab bays and light-well
## stair towers. Kept apart from the chunk builder for the script size budget.

const CS := 16.0
const H := 3.6          # slab soffit
const SURF := 0.86      # water surface: waist-deep wading (swim mode starts below)
const DECK := 1.25      # scaffold boards above the water
const DEEP := -2.4      # sump floor
const STAIR_Y := 3.24   # stair-core landing (18 risers of 0.18 m)

var L: Node3D           # the level (LevelBase)


func _init(level: Node3D) -> void:
	L = level


static func materials() -> void:
	var grime := {"grime_height": 1.55, "floor_y": 0.0, "grime_color": Color(0.12, 0.11, 0.07)}
	var p := {"albedo_a": Color(0.43, 0.42, 0.38), "albedo_b": Color(0.33, 0.32, 0.29), "noise_scale": 1.3,
		"stain_amount": 0.45, "stain_color": Color(0.24, 0.22, 0.15), "wetness": 0.35, "bump_strength": 0.9,
		"roughness_a": 0.78, "roughness_b": 0.95}
	p.merge(grime)
	MatLib.define("l289_wall", p)
	var b := p.duplicate()
	b.merge({"pattern": 4, "pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.012, "grout_color": Color(0.27, 0.26, 0.23),
		"albedo_a": Color(0.38, 0.37, 0.34), "albedo_b": Color(0.3, 0.29, 0.27), "tile_variation": 0.1}, true)
	MatLib.define("l289_block", b)
	MatLib.define("l289_ceiling", {"albedo_a": Color(0.36, 0.35, 0.33), "albedo_b": Color(0.27, 0.27, 0.25),
		"noise_scale": 1.0, "stain_amount": 0.75, "stain_color": Color(0.55, 0.5, 0.38), "stain_scale": 0.7,
		"wetness": 0.5, "bump_strength": 0.8})
	MatLib.define("l289_silt", {"albedo_a": Color(0.17, 0.15, 0.1), "albedo_b": Color(0.11, 0.1, 0.07),
		"noise_scale": 0.8, "wetness": 0.8, "bump_strength": 1.2})
	MatLib.define("l289_tube", {"albedo_a": Color(0.52, 0.52, 0.5), "albedo_b": Color(0.38, 0.38, 0.37),
		"metallic_value": 0.6, "roughness_a": 0.42, "roughness_b": 0.7, "noise_scale": 3.0,
		"stain_amount": 0.4, "stain_color": Color(0.38, 0.21, 0.1), "grime_height": 1.0, "floor_y": 0.0,
		"grime_color": Color(0.2, 0.15, 0.09)})
	MatLib.define("l289_prop_rust", {"albedo_a": Color(0.5, 0.24, 0.12), "albedo_b": Color(0.33, 0.17, 0.09),
		"metallic_value": 0.35, "roughness_a": 0.6, "roughness_b": 0.9, "noise_scale": 3.5,
		"grime_height": 1.0, "floor_y": 0.0, "grime_color": Color(0.16, 0.11, 0.07)})
	MatLib.define("l289_board_wood", {"albedo_a": Color(0.31, 0.27, 0.2), "albedo_b": Color(0.21, 0.18, 0.13),
		"pattern": 3, "pattern_scale": Vector2(3.9, 0.225), "grout_width": 0.022, "grout_color": Color(0.03, 0.025, 0.02),
		"tile_variation": 0.14, "noise_scale": 2.2, "wetness": 0.6, "stain_amount": 0.6, "stain_color": Color(0.14, 0.12, 0.08),
		"roughness_a": 0.75, "roughness_b": 0.95, "bump_strength": 1.0})
	MatLib.define("l289_tarp", {"albedo_a": Color(0.1, 0.22, 0.4), "albedo_b": Color(0.08, 0.17, 0.32),
		"roughness_a": 0.55, "roughness_b": 0.7, "noise_scale": 2.0, "stain_amount": 0.3, "stain_color": Color(0.1, 0.12, 0.12)})
	MatLib.define("l289_cloth", {"albedo_a": Color(0.25, 0.27, 0.17), "albedo_b": Color(0.18, 0.2, 0.12),
		"roughness_a": 0.95, "roughness_b": 1.0, "noise_scale": 4.0})
	MatLib.define("l289_door_metal", {"albedo_a": Color(0.3, 0.35, 0.32), "albedo_b": Color(0.24, 0.28, 0.25),
		"metallic_value": 0.4, "roughness_a": 0.5, "roughness_b": 0.8, "peel_amount": 0.35,
		"peel_color": Color(0.4, 0.2, 0.1), "stain_amount": 0.4, "stain_color": Color(0.3, 0.18, 0.1)})
	MatLib.define("l289_tide", {"albedo_a": Color(0.1, 0.095, 0.06), "albedo_b": Color(0.16, 0.14, 0.08),
		"noise_scale": 6.0, "wetness": 0.9, "roughness_a": 0.3, "roughness_b": 0.6, "bump_strength": 0.4})
	MatLib.define("l289_chalk", {"albedo_a": Color(0.85, 0.84, 0.8), "albedo_b": Color(0.75, 0.74, 0.7),
		"emission_color": Color(0.3, 0.3, 0.28), "emission_energy": 0.25})
	MatLib.register("l289_bulb", MatLib.panel(Color(1.0, 0.74, 0.42), 5.0))
	MatLib.register("l289_bulb_flicker", MatLib.panel(Color(1.0, 0.74, 0.42), 5.0, 0.6, 3.0))
	MatLib.register("l289_bulb_dead", MatLib.standard(Color(0.12, 0.11, 0.09), 0.2, 0.0))
	MatLib.register("l289_screen", MatLib.panel(Color(0.55, 0.95, 0.7), 1.6))
	MatLib.register("l289_cable", MatLib.standard(Color(0.03, 0.03, 0.03), 0.6, 0.0))
	MatLib.register("l289_water", MatLib.water({"shallow_color": Color(0.33, 0.3, 0.17), "deep_color": Color(0.11, 0.1, 0.055),
		"absorption": 3.4, "clarity": 0.15, "wave_height": 0.008, "wave_scale": 0.9, "wave_speed": 0.12,
		"foam_amount": 0.55, "foam_color": Color(0.36, 0.33, 0.2), "foam_width": 0.14, "roughness_value": 0.08,
		"normal_strength": 0.28, "refraction": 0.015}))


# ------------------------------------------------------------- primitives

## Hexagonal tube between two points (scaffold standards, ledgers, props, pipes).
static func tube(k: GeoKit, a: Vector3, b: Vector3, r: float, mat: String) -> void:
	var ax := b - a
	var hl := ax.length() * 0.5
	if hl < 0.005:
		return
	var d := ax / (hl * 2.0)
	var ref := Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT
	var u := d.cross(ref).normalized()
	var v := d.cross(u).normalized()
	var mid := (a + b) * 0.5
	for i in 6:
		var ang := TAU * (float(i) + 0.5) / 6.0
		var n := u * cos(ang) + v * sin(ang)
		var tng := n.cross(d).normalized()
		k.quad(mid + n * r * 0.866, n, d * hl, tng * r * 0.5, mat)


## Scum line where the water meets a vertical face (axis-aligned box faces).
static func tide(k: GeoKit, mn: Vector3, mx: Vector3, faces: int = GeoKit.SIDES) -> void:
	k.box_mm(Vector3(mn.x - 0.012, SURF - 0.05, mn.z - 0.012), Vector3(mx.x + 0.012, SURF + 0.16, mx.z + 0.012), "l289_tide", faces, false)


## Horizontal ceiling slab over a chunk with at most one rectangular hole
## (local coordinates) plus inner shaft walls rising `shaft` metres above it.
static func ceiling(k: GeoKit, o: Vector3, hole: Rect2, shaft: float) -> void:
	if hole.size == Vector2.ZERO:
		k.slab(o.x, o.z, o.x + CS, o.z + CS, H + 0.35, 0.35, "l289_ceiling", GeoKit.NY)
		return
	var x0 := o.x + hole.position.x
	var z0 := o.z + hole.position.y
	var x1 := x0 + hole.size.x
	var z1 := z0 + hole.size.y
	for r in [[o.x, o.z, o.x + CS, z0], [o.x, z1, o.x + CS, o.z + CS], [o.x, z0, x0, z1], [x1, z0, o.x + CS, z1]]:
		if r[2] - r[0] > 0.01 and r[3] - r[1] > 0.01:
			k.slab(r[0], r[1], r[2], r[3], H + 0.35, 0.35, "l289_ceiling", GeoKit.NY)
	if shaft > 0.0:
		var yc := H + shaft * 0.5
		k.box(Vector3((x0 + x1) * 0.5, yc, z0 - 0.15), Vector3(x1 - x0 + 0.6, shaft, 0.3), "l289_wall", GeoKit.PZ, false)
		k.box(Vector3((x0 + x1) * 0.5, yc, z1 + 0.15), Vector3(x1 - x0 + 0.6, shaft, 0.3), "l289_wall", GeoKit.NZ, false)
		k.box(Vector3(x0 - 0.15, yc, (z0 + z1) * 0.5), Vector3(0.3, shaft, z1 - z0), "l289_wall", GeoKit.PX, false)
		k.box(Vector3(x1 + 0.15, yc, (z0 + z1) * 0.5), Vector3(0.3, shaft, z1 - z0), "l289_wall", GeoKit.NX, false)


static func _in_hole(hole: Rect2, lx: float, lz: float, pad: float = 0.0) -> bool:
	return hole.size != Vector2.ZERO and hole.grow(pad).has_point(Vector2(lx, lz))


## Work lamp hung on a short cable: emissive cage bulb + pooled real light.
func lamp(k: GeoKit, p: Vector3, grp: String, r: RandomNumberGenerator, dead_chance: float = 0.4, energy: float = 1.7) -> void:
	var dead := r.randf() < dead_chance
	var flick := 0.0 if dead or r.randf() < 0.7 else r.randf_range(0.25, 0.6)
	tube(k, p + Vector3.UP * 0.12, p + Vector3.UP * 0.75, 0.008, "l289_cable")
	k.box(p + Vector3.UP * 0.1, Vector3(0.09, 0.07, 0.09), "l289_tube", GeoKit.ALL, false)
	var mat := "l289_bulb_dead" if dead else ("l289_bulb_flicker" if flick > 0.0 else "l289_bulb")
	k.box(p, Vector3(0.09, 0.13, 0.09), mat, GeoKit.ALL, false)
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		tube(k, p + Vector3(cos(a) * 0.075, 0.09, sin(a) * 0.075), p + Vector3(cos(a) * 0.075, -0.09, sin(a) * 0.075), 0.005, "l289_tube")
	if not dead:
		L.lights.add_anchor(p + Vector3.DOWN * 0.1, Color(1.0, 0.72, 0.42), energy, 9.5, flick, grp)


# ----------------------------------------------------------------- chunks

func _beam(k: GeoKit, o: Vector3, hole: Rect2, along_x: bool, at: float) -> void:
	var segs: Array = [[0.0, CS]]
	if hole.size != Vector2.ZERO:
		if along_x and at >= hole.position.y - 0.3 and at <= hole.end.y + 0.3:
			segs = [[0.0, hole.position.x], [hole.end.x, CS]]
		elif not along_x and at >= hole.position.x - 0.3 and at <= hole.end.x + 0.3:
			segs = [[0.0, hole.position.y], [hole.end.y, CS]]
	for s in segs:
		if s[1] - s[0] < 0.2:
			continue
		if along_x:
			k.box_mm(o + Vector3(s[0], H - 0.5, at - 0.2), o + Vector3(s[1], H, at + 0.2), "l289_wall", GeoKit.NY | GeoKit.PZ | GeoKit.NZ, false)
		else:
			k.box_mm(o + Vector3(at - 0.2, H - 0.5, s[0]), o + Vector3(at + 0.2, H, s[1]), "l289_wall", GeoKit.NY | GeoKit.PX | GeoKit.NX, false)


## Service pipes under the slab; rows are global so they run on across chunks.
func _pipes(k: GeoKit, o: Vector3, cx: int, cz: int, hole: Rect2) -> void:
	var hx := absi(hash([L.level_seed, "pz", cz])) % 3
	if hx < 2:
		var z := o.z + (3.6 if hx == 0 else 11.4)
		for i in 2:
			var y := H - 0.12 - i * 0.2
			if hole.size == Vector2.ZERO or z < o.z + hole.position.y - 0.2 or z > o.z + hole.end.y + 0.2:
				tube(k, Vector3(o.x, y, z + i * 0.3), Vector3(o.x + CS, y, z + i * 0.3), 0.07 - i * 0.02, "l289_prop_rust")
	var hz := absi(hash([L.level_seed, "px", cx])) % 3
	if hz == 0:
		var x := o.x + 5.2
		if hole.size == Vector2.ZERO or x < o.x + hole.position.x - 0.2 or x > o.x + hole.end.x + 0.2:
			tube(k, Vector3(x, H - 0.22, o.z), Vector3(x, H - 0.22, o.z + CS), 0.11, "l289_tube")


## One 8 m bay of ordinary basement: scaffold run, shoring props, a partition
## block wall or nothing. gx/gz are global bay indices (aligned walkways).
func _bay(k: GeoKit, b: Vector3, gx: int, gz: int, r: RandomNumberGenerator, grp: String) -> void:
	var roll := r.randf()
	if roll < 0.52:
		var along_x := (absi(hash([L.level_seed, "ori", gx + gz])) % 2) == 0
		var row := gz if along_x else gx
		var off := 2.6 if (absi(hash([L.level_seed, "row", row, along_x])) % 2) == 0 else 5.4
		_frame(k, b, along_x, off, r, grp, 0.45)
		if r.randf() < 0.7:
			var band := Rect2(0, off - 1.4, 8, 2.8) if along_x else Rect2(off - 1.4, 0, 2.8, 8)
			_props(k, b, r, 2, band)
	elif roll < 0.78:
		_props(k, b, r, r.randi_range(2, 4))
		if r.randf() < 0.35:
			lamp(k, b + Vector3(r.randf_range(2.0, 6.0), H - 0.95, r.randf_range(2.0, 6.0)), grp, r)
	elif roll < 0.9:
		_block_wall(k, b, r)
	# else: open water


## Scaffold run with a board walkway at DECK, guard rail on one side only,
## braces, and (sometimes) a stair unit up from the water at its start.
func _frame(k: GeoKit, b: Vector3, along_x: bool, off: float, r: RandomNumberGenerator, grp: String, lamp_chance: float) -> void:
	var stair := r.randf() < 0.5
	var s0 := 2.3 if stair else 0.15
	var s1 := 7.85
	var ax := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var sd := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	var base := b + sd * off
	var hw := 0.65
	var dc := base + ax * ((s0 + s1) * 0.5) + Vector3.UP * (DECK - 0.04)
	var dsz := (Vector3(s1 - s0, 0.08, hw * 2.0) if along_x else Vector3(hw * 2.0, 0.08, s1 - s0))
	k.box(dc, dsz, "l289_board_wood", GeoKit.ALL, true, "wood")
	var rail_side := 1.0 if r.randf() < 0.5 else -1.0
	var top := H - 0.55
	var stations: Array = []
	var cnt := ceili((s1 - s0) / 1.95)
	for i in cnt + 1:
		stations.append(s0 + 0.05 + (s1 - s0 - 0.1) * float(i) / cnt)
	for st: float in stations:
		for side: float in [-1.0, 1.0]:
			var p := base + ax * st + sd * (hw * side)
			var lean := Vector3(r.randf_range(-0.04, 0.04), 0, r.randf_range(-0.04, 0.04))
			tube(k, p + Vector3.UP * 0.02, p + Vector3.UP * top + lean, 0.025, "l289_tube")
			k.box(p + Vector3.UP * 0.01, Vector3(0.15, 0.02, 0.15), "l289_tube", GeoKit.PY, false)
			k.add_box_shape(Transform3D(Basis(), p + Vector3.UP * 0.6), Vector3(0.07, 1.2, 0.07), "metal")
		tube(k, base + ax * st + sd * -hw + Vector3.UP * (DECK - 0.1), base + ax * st + sd * hw + Vector3.UP * (DECK - 0.1), 0.022, "l289_tube")
	for side: float in [-1.0, 1.0]:
		var e := sd * (hw * side)
		tube(k, base + ax * s0 + e + Vector3.UP * (DECK - 0.1), base + ax * s1 + e + Vector3.UP * (DECK - 0.1), 0.022, "l289_tube")
		tube(k, base + ax * s0 + e + Vector3.UP * 0.35, base + ax * s1 + e + Vector3.UP * 0.35, 0.022, "l289_tube")
	var re := sd * (hw * rail_side)
	for hgt: float in [0.5, 1.0]:
		tube(k, base + ax * s0 + re + Vector3.UP * (DECK + hgt), base + ax * s1 + re + Vector3.UP * (DECK + hgt), 0.022, "l289_tube")
	k.add_box_shape(Transform3D(Basis(), base + ax * ((s0 + s1) * 0.5) + re + Vector3.UP * (DECK + 0.55)),
		(Vector3(s1 - s0, 1.1, 0.06) if along_x else Vector3(0.06, 1.1, s1 - s0)), "metal")
	# braces zig-zag on the far side (some missing: badly built)
	for i in stations.size() - 1:
		if r.randf() < 0.25:
			continue
		var e2 := sd * (-hw * rail_side)
		var lo: float = stations[i] if i % 2 == 0 else stations[i + 1]
		var hi: float = stations[i + 1] if i % 2 == 0 else stations[i]
		tube(k, base + ax * lo + e2 + Vector3.UP * 0.2, base + ax * hi + e2 + Vector3.UP * (DECK - 0.15), 0.02, "l289_tube")
	if stair:
		var st0 := base + ax * 0.3
		k.stairs(st0, ax, 0.9, DECK, 7, "l289_board_wood", 0.28, false)
		for side: float in [-1.0, 1.0]:
			tube(k, st0 + sd * (0.47 * side), st0 + ax * 1.96 + sd * (0.47 * side) + Vector3.UP * DECK, 0.03, "l289_tube")
			tube(k, st0 + sd * (0.47 * side) + Vector3.UP * 0.95, st0 + ax * 1.96 + sd * (0.47 * side) + Vector3.UP * (DECK + 0.95), 0.02, "l289_tube")
	if r.randf() < lamp_chance:
		lamp(k, base + ax * r.randf_range(s0 + 1.0, s1 - 1.0) + sd * ((hw + 0.2) * rail_side) + Vector3.UP * (top - 0.6), grp, r)


## Adjustable steel props shoring the slab, some visibly out of plumb.
func _props(k: GeoKit, b: Vector3, r: RandomNumberGenerator, count: int, avoid := Rect2()) -> void:
	for i in count:
		var lp := Vector2(r.randf_range(1.2, 6.8), r.randf_range(1.2, 6.8))
		if avoid.size != Vector2.ZERO and avoid.has_point(lp):
			continue
		prop(k, b + Vector3(lp.x, 0, lp.y), r)


## One adjustable steel prop under a timber bearer, sometimes out of plumb.
func prop(k: GeoKit, p: Vector3, r: RandomNumberGenerator) -> void:
	var lean := Vector3(r.randf_range(-0.22, 0.22), 0, r.randf_range(-0.22, 0.22)) if r.randf() < 0.5 else Vector3.ZERO
	var tp := p + Vector3.UP * (H - 0.17) + lean
	var mid := p.lerp(tp, 0.55)
	tube(k, p + Vector3.UP * 0.02, mid, 0.035, "l289_prop_rust")
	tube(k, mid - (tp - p).normalized() * 0.1, tp, 0.026, "l289_tube")
	k.box(p + Vector3.UP * 0.01, Vector3(0.18, 0.02, 0.18), "l289_prop_rust", GeoKit.PY, false)
	var yaw := r.randf() * PI
	k.box_xf(Transform3D(Basis(Vector3.UP, yaw), tp + Vector3.UP * 0.085), Vector3(0.1, 0.15, 1.6), "l289_board_wood", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), p.lerp(tp, 0.25)), Vector3(0.08, 1.6, 0.08), "metal")


## Partition of concrete block along one bay edge, stopped short of the slab
## or holed through; a few blocks lie in the water.
func _block_wall(k: GeoKit, b: Vector3, r: RandomNumberGenerator) -> void:
	var along_x := r.randf() < 0.5
	var a := b + (Vector3(0.3, 0, 0.1) if along_x else Vector3(0.1, 0, 0.3))
	var e := a + (Vector3(7.4, 0, 0) if along_x else Vector3(0, 0, 7.4))
	var hgt := H if r.randf() < 0.5 else r.randf_range(2.3, 3.0)
	var ops: Array = [{"at": r.randf_range(1.5, 5.9), "w": r.randf_range(1.0, 1.8), "h": minf(2.2, hgt - 0.1), "sill": 0.0}]
	k.wall(a, e, hgt, 0.2, "l289_block", ops)
	var op0: float = ops[0]["at"] - ops[0]["w"] * 0.5
	var op1: float = ops[0]["at"] + ops[0]["w"] * 0.5
	var dirv := (e - a).normalized()
	var th := Vector3(0.1, 0, 0.1) - dirv * 0.1
	tide(k, a + dirv * 0.0 - th, a + dirv * op0 + th)
	tide(k, a + dirv * op1 - th, e + th)
	for i in r.randi_range(1, 4):
		var p := a.lerp(e, r.randf()) + Vector3(r.randf_range(-0.9, 0.9), 0.1, r.randf_range(-0.9, 0.9))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI).rotated(Vector3.RIGHT, r.randf_range(-0.4, 0.4)), p), Vector3(0.4, 0.2, 0.2), "l289_block", GeoKit.ALL, false)


## Sunken bay: the floor drops to DEEP (over your head), with underwater steps.
func _sump(k: GeoKit, b: Vector3, r: RandomNumberGenerator) -> void:
	var lip := 0.2
	k.box_mm(b + Vector3(0, DEEP, 0), b + Vector3(8, 0, lip), "l289_wall", GeoKit.ALL)
	k.box_mm(b + Vector3(0, DEEP, 8 - lip), b + Vector3(8, 0, 8), "l289_wall", GeoKit.ALL)
	k.box_mm(b + Vector3(0, DEEP, lip), b + Vector3(lip, 0, 8 - lip), "l289_wall", GeoKit.ALL)
	k.box_mm(b + Vector3(8 - lip, DEEP, lip), b + Vector3(8, 0, 8 - lip), "l289_wall", GeoKit.ALL)
	var flip := r.randf() < 0.5
	var sx := r.randf_range(1.4, 6.6)
	var dir := Vector3(0, 0, -1) if flip else Vector3(0, 0, 1)
	var sz := (lip + 13 * 0.28) if flip else (8.0 - lip - 13 * 0.28)
	k.stairs(b + Vector3(sx, DEEP, sz), dir, 1.2, -DEEP, 13, "l289_wall", 0.28, true)
	# a drowned pump and its riser pipe
	var pp := b + Vector3(r.randf_range(2.0, 6.0), DEEP, r.randf_range(2.5, 5.5))
	k.box(pp + Vector3(0, 0.45, 0), Vector3(1.1, 0.9, 0.7), "l289_prop_rust")
	tube(k, pp + Vector3(0.3, 0.9, 0), pp + Vector3(0.3, H - 0.3 - DEEP, 0), 0.08, "l289_prop_rust")
	# a few standards someone started around the edge and gave up on
	for i in r.randi_range(2, 4):
		var e := b + Vector3(r.randf_range(0.5, 7.5), 0, [0.5, 7.5][i % 2])
		tube(k, e, e + Vector3(r.randf_range(-0.1, 0.1), r.randf_range(1.6, 2.6), 0), 0.025, "l289_tube")


## Bay where the slab has dropped: a tilted slab piece rests in the water and
## can be climbed toward the hole above; rubble and a fallen frame around it.
func _collapse(k: GeoKit, b: Vector3, r: RandomNumberGenerator) -> void:
	var c := b + Vector3(4, 0, 4)
	var yaw := float(r.randi_range(0, 3)) * PI * 0.5
	var bas := Basis(Vector3.UP, yaw)
	var tilt := deg_to_rad(31.0)
	var len := 6.4
	var sb := bas * Basis(Vector3.RIGHT, tilt)
	var lowp := c + bas * Vector3(0, 0, len * 0.5 * cos(tilt))
	var hi := lowp + sb * Vector3(0, 0, -len)
	k.box_xf(Transform3D(sb, (lowp + hi) * 0.5 - sb.y * 0.15), Vector3(5.2, 0.3, len), "l289_ceiling", GeoKit.ALL, true, "concrete")
	for i in r.randi_range(5, 9):
		var p := c + Vector3(r.randf_range(-3.5, 3.5), 0.15, r.randf_range(-3.5, 3.5))
		var s := Vector3(r.randf_range(0.3, 1.0), r.randf_range(0.2, 0.6), r.randf_range(0.3, 1.0))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI), p), s, "l289_wall", GeoKit.ALL, s.y > 0.4)
	for i in 3:
		var p := c + bas * Vector3(-3.2 + i * 1.1, 0.0, 2.6)
		tube(k, p, p + bas * Vector3(r.randf_range(0.5, 1.2), 0.25, -2.6), 0.025, "l289_tube")
	for i in 4:
		var p := c + Vector3(r.randf_range(-3.0, 3.0), H + r.randf_range(0.2, 2.0), r.randf_range(-3.0, 3.0))
		tube(k, p, p + Vector3(r.randf_range(-0.3, 0.3), -r.randf_range(0.8, 2.2), r.randf_range(-0.3, 0.3)), 0.012, "l289_tube")


func _debris(k: GeoKit, o: Vector3, r: RandomNumberGenerator, hole: Rect2) -> void:
	for i in r.randi_range(3, 7):
		var p := o + Vector3(r.randf_range(0.5, CS - 0.5), SURF + 0.006, r.randf_range(0.5, CS - 0.5))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI).rotated(Vector3.FORWARD, r.randf_range(-0.03, 0.03)), p),
			Vector3(0.22, 0.03, r.randf_range(1.2, 3.0)), "l289_board_wood", GeoKit.ALL, false)
	if r.randf() < 0.4:
		var p := o + Vector3(r.randf_range(2.0, CS - 2.0), 0.0, r.randf_range(2.0, CS - 2.0))
		if not _in_hole(hole, p.x - o.x, p.z - o.z, 1.0):
			k.cylinder(p + Vector3(0, 0.45, 0), 0.29, 0.9, "l289_prop_rust", 10, true)
	# drip-stained cables hanging from the slab
	for i in r.randi_range(1, 3):
		var p := o + Vector3(r.randf_range(1.0, CS - 1.0), H, r.randf_range(1.0, CS - 1.0))
		if not _in_hole(hole, p.x - o.x, p.z - o.z, 0.5):
			tube(k, p, p + Vector3(r.randf_range(-0.2, 0.2), -r.randf_range(0.6, 1.6), r.randf_range(-0.2, 0.2)), 0.01, "l289_cable")


# ------------------------------------------------------------ light well

## Stair tower in an open light well: boards at DECK, a flight of 18 risers to
## a second deck at DECK+3.2 inside the shaft, guard rails up there.
func _tower(k: GeoKit, o: Vector3, grp: String, r: RandomNumberGenerator) -> void:
	var y2 := DECK + 3.2
	var x0 := o.x + 5.0
	var x1 := o.x + 11.5
	k.slab(x0, o.z + 4.5, x1, o.z + 6.5, DECK, 0.08, "l289_board_wood", GeoKit.ALL, "wood")
	k.slab(x0, o.z + 6.5, x0 + 0.6, o.z + 7.7, DECK, 0.08, "l289_board_wood", GeoKit.ALL, "wood")
	k.stairs(Vector3(x0 + 0.6, DECK, o.z + 7.1), Vector3(1, 0, 0), 1.2, 3.2, 18, "l289_board_wood", 0.28, false)
	tube(k, Vector3(x0 + 0.6, DECK, o.z + 6.5), Vector3(x0 + 5.64, y2, o.z + 6.5), 0.035, "l289_tube")
	tube(k, Vector3(x0 + 0.6, DECK, o.z + 7.7), Vector3(x0 + 5.64, y2, o.z + 7.7), 0.035, "l289_tube")
	k.slab(x0 + 5.64, o.z + 6.5, x1, o.z + 7.7, y2, 0.08, "l289_board_wood", GeoKit.ALL, "wood")
	k.slab(x0, o.z + 7.7, x1, o.z + 11.5, y2, 0.08, "l289_board_wood", GeoKit.ALL, "wood")
	k.stairs(Vector3(o.x + 6.0, 0.0, o.z + 2.54), Vector3(0, 0, 1), 1.2, DECK, 7, "l289_board_wood", 0.28, false)
	# standards around the tower, to the top of the shaft lift
	for sx: float in [x0, x0 + 2.15, x0 + 4.3, x1]:
		for sz: float in [o.z + 4.5, o.z + 7.7, o.z + 11.5]:
			tube(k, Vector3(sx, 0.02, sz), Vector3(sx, y2 + 2.5, sz), 0.028, "l289_tube")
			if sz != o.z + 7.7 or sx == x0 or sx == x1:
				k.add_box_shape(Transform3D(Basis(), Vector3(sx, 0.6, sz)), Vector3(0.07, 1.2, 0.07), "metal")
	# rails on the upper deck (north, west, east, and over the flight)
	var rails := [[Vector3(x0, y2, o.z + 11.5), Vector3(x1, y2, o.z + 11.5)], [Vector3(x0, y2, o.z + 7.7), Vector3(x0, y2, o.z + 11.5)],
		[Vector3(x1, y2, o.z + 6.5), Vector3(x1, y2, o.z + 11.5)], [Vector3(x0, y2, o.z + 7.7), Vector3(x0 + 5.6, y2, o.z + 7.7)]]
	for rl in rails:
		var a: Vector3 = rl[0]
		var e: Vector3 = rl[1]
		for hgt: float in [0.5, 1.0]:
			tube(k, a + Vector3.UP * hgt, e + Vector3.UP * hgt, 0.022, "l289_tube")
		var d := e - a
		k.add_box_shape(Transform3D(Basis(), (a + e) * 0.5 + Vector3.UP * 0.55), Vector3(maxf(absf(d.x), 0.06), 1.1, maxf(absf(d.z), 0.06)), "metal")
	# braces on the tower faces
	for i in 3:
		var sx: float = [x0, x0 + 2.15, x0 + 4.3][i]
		tube(k, Vector3(sx, 0.2, o.z + 11.5), Vector3(sx + 2.15, y2 - 0.2, o.z + 11.5), 0.02, "l289_tube")
	lamp(k, Vector3(x0 + 3.2, y2 + 2.35, o.z + 9.6), grp, r, 0.0, 1.4)
	lamp(k, Vector3(x0 + 1.0, DECK + 1.6, o.z + 5.0), grp, r, 0.55)
	for i in 5:
		var p := o + Vector3(r.randf_range(4.5, 11.5), H + r.randf_range(3.0, 8.0), r.randf_range(4.5, 11.5))
		tube(k, p, p + Vector3(0, -r.randf_range(1.0, 3.0), 0), 0.01, "l289_cable")


# -------------------------------------------------------------- stair core
