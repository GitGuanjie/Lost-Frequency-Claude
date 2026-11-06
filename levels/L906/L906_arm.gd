extends RefCounted
## Level 906 arm segments: the four "seemingly endless" halls that run out from
## the central crossing (Blanche's office and the tea room sit in the middle of
## the library, per the page). Each arm is streamed in 12 m segments around the
## player. A segment is built in arm-local space (x across, z outward) and placed
## by its node transform. Grammar (ADAPTATION, modelled on the long-room library
## the page's licence box credits as "bearing some resemblance"):
##  - a 14 m nave with a blue-and-gold carpet runner down the middle;
##  - ground bays between double-sided bookcase stacks, under a 4.5 m gallery
##    carried on turned columns; upper stacks on the gallery; panelled walls rising
##    into the dark towards the receding ceiling;
##  - a candelabra hanging on a chain over the nave every 12 m, small ones over
##    the galleries;
##  - every third segment a stair up to the gallery;
##  - floating bookcases (page: "unaffected by gravity, floating in place") with a
##    wooden ladder to reach them and a walkable top.

const K := preload("res://levels/L906/L906_kit.gd")
const W := 11.2
const SEG := 12.0
const START := 19.0
const LIGHT := Color(1.0, 0.71, 0.4)

var L: Node3D


func _init(level: Node3D) -> void:
	L = level


static func arm_basis(arm: int) -> Basis:
	var d: Vector3 = [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)][arm]
	return Basis(Vector3.UP.cross(d), Vector3.UP, d)


static func seg_center(arm: int, i: int) -> Vector3:
	return arm_basis(arm) * Vector3(0, 0, START + SEG * (i + 0.5))


func build(arm: int, i: int, node: Node3D) -> Dictionary:
	node.transform = Transform3D(arm_basis(arm), Vector3.ZERO)
	var r := RandomNumberGenerator.new()
	r.seed = hash([L.level_seed, arm, i, 906])
	var grp := "s%d_%d" % [arm, i]
	var meta := {"group": grp, "spots": [], "lights": 0}
	var k := GeoKit.new(node, "Seg")
	var z0 := START + SEG * i
	var z1 := z0 + SEG
	var xf := node.transform
	# floor, runner, walls rising into the dark
	k.slab(-W - 0.3, z0, W + 0.3, z1, 0.0, 0.3, "wood_floor", GeoKit.PY)
	k.box_mm(Vector3(-2.2, 0, z0), Vector3(2.2, 0.012, z1), "l906_carpet", GeoKit.PY, false)
	for s: float in [-1.0, 1.0]:
		k.box_mm(Vector3(s * 2.32 if s < 0 else 2.2, 0, z0), Vector3(-2.2 if s < 0 else 2.32, 0.014, z1), "l906_carpet_edge", GeoKit.PY, false)
	var stair_side := 0.0
	if i % 3 == 1:
		stair_side = -1.0 if r.randf() < 0.5 else 1.0
	for s: float in [-1.0, 1.0]:
		var face := GeoKit.NX if s > 0 else GeoKit.PX
		k.box_mm(Vector3(minf(s * W, s * (W + 0.3)), 0, z0), Vector3(maxf(s * W, s * (W + 0.3)), K.CHAIN_TOP, z1), "l906_panel", face)
		for j in 3:
			var zf := z0 + 4.0 * j
			k.box(Vector3(s * (W - 0.1), (8.6 + K.CHAIN_TOP) * 0.5, zf), Vector3(0.2, K.CHAIN_TOP - 8.6, 0.55), "l906_panel", GeoKit.SIDES ^ (GeoKit.PX if s > 0 else GeoKit.NX), false)
			# ground stack, wall case and column
			K.shelves(k, Vector3(s * 7.55, 0, zf), Vector3(s * W, 0, zf), 0.5, 11, Vector3(0, 0, 1), true)
			K.shelves(k, Vector3(s * 10.95, 0, zf + 0.25), Vector3(s * 10.95, 0, zf + 3.75), 0.45, 11, Vector3(-s, 0, 0))
			K.column(k, Vector3(s * 7.25, 0, zf), 4.2, 0.19)
			# upper stack and wall case (or a guest-room door)
			K.shelves(k, Vector3(s * 8.95, K.GAL, zf), Vector3(s * W, K.GAL, zf), 0.45, 10, Vector3(0, 0, 1), true)
			if i > 0 and r.randf() < 0.12:
				_guest_door(k, node, Vector3(s * 10.95, K.GAL, zf + 2.0), s)
			else:
				K.shelves(k, Vector3(s * 10.95, K.GAL, zf + 0.25), Vector3(s * 10.95, K.GAL, zf + 3.75), 0.45, 10, Vector3(-s, 0, 0))
			_bay(k, Vector3(s * 9.1, 0, zf + 2.0), s, r, meta, xf)
		# gallery deck, runner, fascia and rail
		k.slab(s * 7.0, z0, s * W, z1, K.GAL, 0.3, "l906_wood")
		k.box_mm(Vector3(minf(s * 7.0, s * W), K.GAL, z0), Vector3(maxf(s * 7.0, s * W), K.GAL + 0.004, z1), "wood_floor", GeoKit.PY, false)
		k.box_mm(Vector3(minf(s * 7.4, s * 8.6), K.GAL, z0), Vector3(maxf(s * 7.4, s * 8.6), K.GAL + 0.012, z1), "l906_carpet", GeoKit.PY, false)
		k.box(Vector3(s * 6.985, K.GAL - 0.22, (z0 + z1) * 0.5), Vector3(0.03, 0.08, SEG), "l906_gilt", GeoKit.ALL, false)
		k.box(Vector3(s * (W - 0.3), 8.42, (z0 + z1) * 0.5), Vector3(0.6, 0.34, SEG), "l906_wood", GeoKit.ALL ^ GeoKit.PY, false)
		k.box(Vector3(s * (W - 0.61), 8.36, (z0 + z1) * 0.5), Vector3(0.02, 0.05, SEG), "l906_gilt", GeoKit.ALL, false)
		if s == stair_side:
			K.rail(k, Vector3(s * 7.05, K.GAL, z0), Vector3(s * 7.05, K.GAL, z0 + 8.0))
			K.rail(k, Vector3(s * 7.05, K.GAL, z0 + 9.6), Vector3(s * 7.05, K.GAL, z1))
			_stair(k, s, z0)
		else:
			K.rail(k, Vector3(s * 7.05, K.GAL, z0), Vector3(s * 7.05, K.GAL, z1))
		# small candelabra over the gallery walk
		if (i + (1 if s > 0 else 0)) % 2 == 0:
			var lp := K.candelabra(k, Vector3(s * 8.2, 7.6, z0 + 6.0), 0.45, 6, 1)
			L.lights.add_anchor(xf * lp, LIGHT, 1.3, 9.0, 0.0, grp)
	# the nave candelabra
	var cp := K.candelabra(k, Vector3(0, 9.8, z0 + 6.0), 1.25, 12, 2)
	L.lights.add_anchor(xf * cp, LIGHT, 3.4, 21.0, 0.0, grp)
	# a floating bookcase with its ladder
	if stair_side == 0.0 and r.randf() < 0.6:
		_floating(k, node, r, z0, xf, meta)
	elif r.randf() < 0.5:
		var p := Vector3(r.randf_range(-1.5, 1.5), 0.012, z0 + r.randf_range(2.0, 10.0))
		K.stack(k, p, r, r.randi_range(2, 6))
	k.commit()
	return meta


func _stair(k: GeoKit, s: float, z0: float) -> void:
	k.stairs(Vector3(s * 6.3, 0, z0 + 1.0), Vector3(0, 0, 1), 1.2, K.GAL, 25, "l906_wood", 0.28)
	k.slab(s * 5.7, z0 + 8.0, s * 7.0, z0 + 9.6, K.GAL, 0.3, "l906_wood")
	k.box_mm(Vector3(minf(s * 5.7, s * 7.0), 0, z0 + 8.0), Vector3(maxf(s * 5.7, s * 7.0), K.GAL - 0.3, z0 + 9.6), "l906_panel")
	k.box_mm(Vector3(minf(s * 5.8, s * 6.9), K.GAL, z0 + 8.0), Vector3(maxf(s * 5.8, s * 6.9), K.GAL + 0.012, z0 + 9.6), "l906_carpet", GeoKit.PY, false)
	# sloped handrail on the nave side, newel posts, landing rails
	var a := Vector3(s * 5.65, 1.0, z0 + 1.0)
	var b := Vector3(s * 5.65, K.GAL + 1.0, z0 + 8.0)
	var z := (b - a).normalized()
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, z.cross(Vector3.RIGHT), z), (a + b) * 0.5), Vector3(0.1, 0.08, a.distance_to(b)), "l906_wood", GeoKit.ALL, false)
	for t in 13:
		var p := a.lerp(b, (t + 0.5) / 13.0)
		k.box(Vector3(p.x, p.y - 0.47, p.z), Vector3(0.045, 0.86, 0.045), "l906_wood", GeoKit.SIDES, false)
	K.column(k, Vector3(s * 5.65, 0, z0 + 1.0), 1.25, 0.09)
	K.rail(k, Vector3(s * 5.75, K.GAL, z0 + 8.0), Vector3(s * 5.75, K.GAL, z0 + 9.6))
	K.rail(k, Vector3(s * 5.7, K.GAL, z0 + 9.6), Vector3(s * 7.0, K.GAL, z0 + 9.6))


## Ground bay furniture between two stacks (centre c on the floor).
func _bay(k: GeoKit, c: Vector3, s: float, r: RandomNumberGenerator, meta: Dictionary, xf: Transform3D) -> void:
	var kind := r.randi_range(0, 5)
	match kind:
		0, 1:
			K.table(k, c + Vector3(-s * 0.2, 0, 0), 1.0, 1.6)
			K.chair(k, c + Vector3(-s * 0.2, 0, -1.15), Vector3(0, 0, 1))
			K.candlestick(k, c + Vector3(-s * 0.35, 0.76, 0.45), 3, 0.3)
			K.stack(k, c + Vector3(-s * 0.05, 0.76, -0.3), r, r.randi_range(1, 4))
			meta["spots"].append(xf * (c + Vector3(-s * 0.2, 0.77, 0.1)))
		2:
			K.stack(k, c + Vector3(r.randf_range(-0.8, 0.8), 0.0, r.randf_range(-1.2, 1.2)), r, r.randi_range(3, 8))
			K.stack(k, c + Vector3(r.randf_range(-0.8, 0.8), 0.0, r.randf_range(-1.2, 1.2)), r, r.randi_range(2, 5))
			meta["spots"].append(xf * (c + Vector3(-s * 0.9, 0.01, 0.6)))
		3:
			# library steps
			for t in 3:
				k.box(c + Vector3(s * 0.9, 0.16 + t * 0.16, -0.9 + t * 0.22), Vector3(0.6, 0.32 + t * 0.32, 0.24) * Vector3(1, 1, 1), "l906_wood", GeoKit.ALL, t == 2)
			meta["spots"].append(xf * (c + Vector3(-s * 0.6, 0.01, 0.4)))
		4:
			# scroll rack
			k.box(c + Vector3(s * 0.4, 0.55, 0), Vector3(0.7, 1.1, 2.0), "l906_wood")
			for t in 14:
				var p := c + Vector3(s * 0.4 - 0.2 + (t % 2) * 0.1, 1.13 + (t % 3) * 0.06, -0.85 + t * 0.13)
				k.box_xf(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), p), Vector3(0.07, 0.62, 0.07), "paper", GeoKit.ALL, false)
			meta["spots"].append(xf * (c + Vector3(s * 0.4, 1.11, 0.0)))
		_:
			meta["spots"].append(xf * (c + Vector3(-s * 0.4, 0.01, 0.0)))


## A bookcase floating in mid-air over the nave, with a ladder and a deck on top.
func _floating(k: GeoKit, node: Node3D, r: RandomNumberGenerator, z0: float, xf: Transform3D, meta: Dictionary) -> void:
	var big := r.randf() < 0.35
	var fx := 3.2 if big else 2.4
	var fz := 2.6 if big else 1.3
	var rows := 9 if big else 7
	var yb := [2.25, 2.625, 3.0][r.randi_range(0, 2)] as float
	var xc := r.randf_range(-2.4, 2.4)
	var zc := z0 + (2.4 if r.randf() < 0.5 else 9.6)
	var b0 := Vector3(xc - fx * 0.5, yb, zc)
	var b1 := Vector3(xc + fx * 0.5, yb, zc)
	K.shelves(k, b0, b1, fz, rows, Vector3(0, 0, 1), true, false)
	var yt := yb + rows * K.PITCH
	k.box_mm(Vector3(xc - fx * 0.5 - 0.06, yb - 0.12, zc - fz * 0.5 - 0.04), Vector3(xc + fx * 0.5 + 0.06, yb, zc + fz * 0.5 + 0.04), "l906_wood")
	for e: float in [-1.0, 1.0]:
		k.box_mm(Vector3(xc + e * fx * 0.5 - 0.05, yb, zc - fz * 0.5), Vector3(xc + e * fx * 0.5 + 0.05, yt, zc + fz * 0.5), "l906_panel", GeoKit.ALL, false)
	k.slab(xc - fx * 0.5 - 0.08, zc - fz * 0.5 - 0.06, xc + fx * 0.5 + 0.08, zc + fz * 0.5 + 0.06, yt + 0.1, 0.1, "l906_wood")
	k.box_mm(Vector3(xc - fx * 0.5 + 0.1, yt + 0.1, zc - fz * 0.5 + 0.1), Vector3(xc + fx * 0.5 - 0.1, yt + 0.112, zc + fz * 0.5 - 0.1), "l906_carpet", GeoKit.PY, false)
	k.box(Vector3(xc, yb - 0.05, zc - fz * 0.5 - 0.045), Vector3(fx + 0.12, 0.04, 0.012), "l906_gilt", GeoKit.ALL, false)
	k.box(Vector3(xc, yb - 0.05, zc + fz * 0.5 + 0.045), Vector3(fx + 0.12, 0.04, 0.012), "l906_gilt", GeoKit.ALL, false)
	var top := yt + 0.1
	K.rail(k, Vector3(xc - fx * 0.5, top, zc - fz * 0.5 - 0.02), Vector3(xc + fx * 0.5, top, zc - fz * 0.5 - 0.02))
	K.rail(k, Vector3(xc - fx * 0.5, top, zc + fz * 0.5 + 0.02), Vector3(xc + fx * 0.5, top, zc + fz * 0.5 + 0.02))
	K.rail(k, Vector3(xc + fx * 0.5 + 0.02, top, zc - fz * 0.5), Vector3(xc + fx * 0.5 + 0.02, top, zc + fz * 0.5))
	# ladder up the near end (towards -x)
	var lx := xc - fx * 0.5
	K.ladder(k, Vector3(lx - 0.55, 0.0, zc), Vector3(lx - 0.1, top + 0.9, zc), Vector3(0, 0, 1), 0.52)
	var lv := LadderVolume.new()
	lv.name = "FloatLadder"
	node.add_child(lv)
	var bb := xf * AABB(Vector3(lx - 0.8, 0.0, zc - 0.36), Vector3(0.82, top + 1.0, 0.72))
	lv.setup(bb.position, bb.end)
	meta["spots"].append(xf * Vector3(xc + 0.4, top, zc))
	meta["float"] = {"top": xf * Vector3(xc, top, zc), "foot": xf * Vector3(lx - 0.75, 0.05, zc), "face": xf.basis * Vector3(1, 0, 0)}


func _guest_door(k: GeoKit, node: Node3D, c: Vector3, s: float) -> void:
	k.box_mm(Vector3(minf(s * 10.95 - s * 0.22, s * 11.2), c.y, c.z - 2.0 + 0.25), Vector3(maxf(s * 10.95 - s * 0.22, s * 11.2), c.y + 3.75, c.z - 0.75), "l906_panel")
	k.box_mm(Vector3(minf(s * 10.95 - s * 0.22, s * 11.2), c.y, c.z + 0.75), Vector3(maxf(s * 10.95 - s * 0.22, s * 11.2), c.y + 3.75, c.z + 2.0 - 0.25), "l906_panel")
	k.box_mm(Vector3(minf(s * 10.95 - s * 0.22, s * 11.2), c.y + 2.4, c.z - 0.75), Vector3(maxf(s * 10.95 - s * 0.22, s * 11.2), c.y + 3.75, c.z + 0.75), "l906_panel")
	k.box(Vector3(s * 11.12, c.y + 1.2, c.z), Vector3(0.08, 2.4, 1.5), "l906_wood")
	k.box(Vector3(s * 10.72, c.y + 2.48, c.z), Vector3(0.06, 0.14, 1.74), "l906_gilt", GeoKit.ALL, false)
	k.box(Vector3(s * 11.06, c.y + 1.05, c.z + 0.55), Vector3(0.06, 0.06, 0.06), "l906_brass", GeoKit.ALL, false)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(Vector3(s * 10.95, c.y + 1.2, c.z), Vector3(0.5, 2.2, 1.4), "Try the door", func(_p): L.hosts.empty_guest_room())
