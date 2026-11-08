extends RefCounted
## Level 49 structures: dugout stairs and timbered bunker rooms (and the
## tunnel joining the Gutter Bunkers), the drainage culvert, covered gun
## emplacements, artillery pits with mortars of non-human make, collapsed
## dugouts.

const TR := preload("res://levels/L049/L049_trench.gd")


static func _lat(d: Vector2i) -> Vector2i:
	return Vector2i(d.y, d.x)


static func _v(d: Vector2i) -> Vector3:
	return Vector3(d.x, 0, d.y)


## Underground spaces. Returns per-bunker anchors.
static func bunkers(k: GeoKit, lay: Dictionary, r: RandomNumberGenerator) -> Array:
	var cells: Dictionary = lay["cells"]
	var out: Array = []
	for b in lay["bunkers"]:
		var t: Vector2i = b["t"]
		var d: Vector2i = b["d"]
		var dv := _v(d)
		var lat := _lat(d)
		var lv := _v(lat)
		var top := TR.cpos(t) + dv * 1.0
		if b.get("collapsed", false):
			_collapsed(k, top, dv, lv, r)
			out.append({"collapsed": true, "entrance": top + Vector3(0, TR.FLOOR, 0) - dv * 0.6})
			continue
		# entrance frame, stair, stairwell walls
		for s: float in [-0.8, 0.8]:
			k.box(top + lv * s + Vector3(0, (TR.FLOOR + TR.STAIR_ROOF) * 0.5, 0), Vector3(0.16, TR.STAIR_ROOF - TR.FLOOR, 0.16), "l49_post", GeoKit.ALL, false)
		k.box(top + Vector3(0, TR.STAIR_ROOF - 0.1, 0), _o(lv, Vector3(1.9, 0.2, 0.22)), "l49_post", GeoKit.ALL, false)
		var bottom := TR.cpos(t) + dv * 5.0 + Vector3(0, TR.UFLOOR, 0)
		k.stairs(bottom, -dv, 1.4, TR.FLOOR - TR.UFLOOR, 14, "l49_board", 4.0 / 14.0, true)
		for sg: float in [-1.0, 1.0]:
			var wc := TR.cpos(t) + dv * 3.0 + lv * sg * 0.76
			k.box(wc + Vector3(0, (TR.UFLOOR + TR.STAIR_ROOF) * 0.5, 0), _o(dv, Vector3(4.0, TR.STAIR_ROOF - TR.UFLOOR, 0.1)), "l49_plank_wet")
			for i in 4:
				k.box(TR.cpos(t) + dv * (1.5 + i) + lv * sg * 0.68 + Vector3(0, (TR.UFLOOR + TR.STAIR_ROOF) * 0.5, 0), Vector3(0.12, TR.STAIR_ROOF - TR.UFLOOR, 0.12), "l49_post", GeoKit.ALL, false)
		var room: Array = b["room"]
		out.append({"t": t, "d": d, "room": room, "gutter": b.get("gutter", false),
			"centre": (TR.cpos(t + d * 3) + TR.cpos(t + d * 4)) * 0.5 + Vector3(0, TR.UFLOOR, 0),
			"back": TR.cpos(t + d * 4) + dv * 0.92 + Vector3(0, TR.UFLOOR, 0),
			"side": TR.cpos(t + d * 4 + lat) + lv * 0.92 + Vector3(0, TR.UFLOOR, 0),
			"corner_a": TR.cpos(t + d * 4 - lat) + Vector3(0, TR.UFLOOR, 0),
			"corner_b": TR.cpos(t + d * 3 + lat) + Vector3(0, TR.UFLOOR, 0),
			"near_a": TR.cpos(t + d * 3 - lat) + Vector3(0, TR.UFLOOR, 0), "lat": lat})
	# floors, ceilings and walls of every underground cell
	var under := {}
	for c in cells:
		if cells[c] == "r" or cells[c] == "u":
			under[c] = true
	var stair_bottoms := {}
	for b in lay["bunkers"]:
		if not b.get("collapsed", false):
			stair_bottoms[(b["t"] as Vector2i) + (b["d"] as Vector2i) * 2] = b["d"]
	for c in under:
		var p := TR.cpos(c)
		k.box_mm(Vector3(p.x - 1.0, TR.UFLOOR - 0.2, p.z - 1.0), Vector3(p.x + 1.0, TR.UFLOOR, p.z + 1.0), "l49_mud_floor")
		k.box_mm(Vector3(p.x - 1.0, TR.UCEIL, p.z - 1.0), Vector3(p.x + 1.0, TR.EARTH_BOTTOM, p.z + 1.0), "l49_board_dark", GeoKit.NY | GeoKit.SIDES, true)
		k.box(p + Vector3(0, TR.UCEIL - 0.1, 0), Vector3(2.0, 0.18, 0.18), "l49_post", GeoKit.ALL, false)
		for di in 4:
			var dvv: Vector2i = TR.DIRS[di]
			var n: Vector2i = c + dvv
			if under.has(n):
				continue
			var nv := _v(dvv)
			var face := p + nv * 0.97
			if stair_bottoms.has(n) and stair_bottoms[n] == -dvv:
				for s: float in [-0.78, 0.78]:
					k.box(face + _v(_lat(dvv)) * s + Vector3(0, (TR.UFLOOR + TR.UCEIL) * 0.5, 0), Vector3(0.16, TR.UCEIL - TR.UFLOOR, 0.16), "l49_post")
				for s: float in [-1.0, 1.0]:
					k.box(face + _v(_lat(dvv)) * s * 0.93 + Vector3(0, (TR.UFLOOR + TR.UCEIL) * 0.5, 0), _o(_v(_lat(dvv)), Vector3(0.14, TR.UCEIL - TR.UFLOOR, 0.1)), "l49_plank_wet")
				continue
			var y := TR.UFLOOR
			while y < TR.UCEIL - 0.05:
				var ph := minf(r.randf_range(0.2, 0.26), TR.UCEIL - y)
				k.box(face + Vector3(0, y + ph * 0.5, 0), _o(_v(_lat(dvv)), Vector3(2.0, ph - 0.015, 0.06)), "l49_plank_wet", GeoKit.ALL, false)
				y += ph
			k.add_box_shape(Transform3D(Basis(), face + Vector3(0, (TR.UFLOOR + TR.UCEIL) * 0.5, 0)), _o(_v(_lat(dvv)), Vector3(2.0, TR.UCEIL - TR.UFLOOR, 0.1)), "wood")
			k.box(face + nv * 0.08 + Vector3(0, (TR.UFLOOR + TR.EARTH_BOTTOM) * 0.5, 0), _o(_v(_lat(dvv)), Vector3(2.1, TR.EARTH_BOTTOM - TR.UFLOOR, 0.06)), "l49_mud_wall", GeoKit.ALL, false)
			k.box(face - nv * 0.05 + _v(_lat(dvv)) * 0.95 + Vector3(0, (TR.UFLOOR + TR.UCEIL) * 0.5, 0), Vector3(0.14, TR.UCEIL - TR.UFLOOR, 0.14), "l49_post", GeoKit.ALL, false)
	return out


## Box size for something lying along direction `along` (x = along).
static func _o(along: Vector3, sz: Vector3) -> Vector3:
	if absf(along.z) > 0.5:
		return Vector3(sz.z, sz.y, sz.x)
	return sz


static func _collapsed(k: GeoKit, top: Vector3, dv: Vector3, lv: Vector3, r: RandomNumberGenerator) -> void:
	for s: float in [-0.8, 0.8]:
		k.box(top + lv * s + Vector3(0, -1.4, 0), Vector3(0.16, 2.1, 0.16), "l49_post", GeoKit.ALL, false)
	# fallen timbers and a slump of earth fill the stairwell mouth
	k.box_mm(Vector3(minf(top.x, top.x + dv.x * 2.0) - (0.95 if absf(dv.x) < 0.5 else 0.0), TR.FLOOR, minf(top.z, top.z + dv.z * 2.0) - (0.95 if absf(dv.z) < 0.5 else 0.0)),
		Vector3(maxf(top.x, top.x + dv.x * 2.0) + (0.95 if absf(dv.x) < 0.5 else 0.0), TR.STAIR_ROOF, maxf(top.z, top.z + dv.z * 2.0) + (0.95 if absf(dv.z) < 0.5 else 0.0)), "l49_mud_wall")
	for i in 4:
		var a := top + Vector3(0, TR.FLOOR + 0.3 + i * 0.35, 0) - dv * r.randf_range(0.1, 0.5)
		var b := Basis(Vector3.UP, atan2(lv.x, lv.z)) * Basis(Vector3.RIGHT, r.randf_range(-0.5, 0.5)) * Basis(Vector3.FORWARD, r.randf_range(-0.6, 0.6))
		k.box_xf(Transform3D(b, a), Vector3(0.16, 0.16, 2.2), "l49_post", GeoKit.ALL, false)
	k.box(top - dv * 0.45 + Vector3(0, TR.FLOOR + 0.25, 0), Vector3(1.8, 0.5, 1.8) * (Vector3(1, 1, 0.6) if absf(dv.z) > 0.5 else Vector3(0.6, 1, 1)), "l49_mud_wall")


## The Gutter Bunkers' drainage culvert: a low passage under the fire
## trench's south wall, grated shut. Returns the grate's collision shape.
static func culvert(k: GeoKit, lay: Dictionary) -> Dictionary:
	if not lay.has("culvert"):
		return {}
	var cs: Array = lay["culvert"]
	var a := TR.cpos(cs[0])
	var roof := TR.FLOOR + 1.25
	for c in [cs[1], cs[2]]:
		var p := TR.cpos(c)
		k.box_mm(Vector3(p.x - 1.0, TR.FLOOR - 0.6, p.z - 1.0), Vector3(p.x + 1.0, TR.FLOOR - 0.4, p.z + 1.0), "l49_mud_floor")
		for s: float in [-1.0, 1.0]:
			k.box(p + Vector3(s * 0.75, (TR.FLOOR - 0.4 + roof) * 0.5, 0), Vector3(0.5, roof - TR.FLOOR + 0.4, 2.0), "l49_brick")
	var end := TR.cpos(cs[2]) + Vector3(0, 0, 0.95)
	k.box(end + Vector3(0, (TR.FLOOR - 0.4 + roof) * 0.5, 0), Vector3(2.0, roof - TR.FLOOR + 0.4, 0.1), "l49_mud_wall")
	# the mouth: brick arch-ish header and an iron grate
	var mouth := a + Vector3(0, 0, 1.0)
	k.box(mouth + Vector3(0, roof + 0.12, 0), Vector3(1.6, 0.24, 0.3), "l49_brick", GeoKit.ALL, false)
	return {"mouth": mouth + Vector3(0, TR.FLOOR, 0), "inner": TR.cpos(cs[2]) + Vector3(0, TR.FLOOR - 0.4, 0)}


## Covered emplacement: corrugated roof on posts over part of the wide cells,
## a high fire-step along one side (from it a head clears the parapet).
static func emplacement(k: GeoKit, lay: Dictionary, r: RandomNumberGenerator) -> Dictionary:
	var c: Vector2i = lay["node"]
	var cells: Dictionary = lay["cells"]
	var p := TR.cpos(c)
	var side := -1
	var s0 := r.randi() % 4
	for i in 4:
		var sd: Vector2i = TR.DIRS[(s0 + i) % 4]
		var ok := true
		for l: int in [-1, 0, 1]:
			if TR.is_open(cells.get(c + sd * 2 + _lat(sd) * l, "")):
				ok = false
		if ok:
			side = (s0 + i) % 4
			break
	if side < 0:
		return {}
	var dv := _v(TR.DIRS[side])
	var lv := Vector3(-dv.z, 0, dv.x)
	var step_c := p + dv * 2.45 + Vector3(0, TR.FLOOR + 0.5, 0)
	k.box(step_c, _o(lv, Vector3(5.6, 1.0, 0.9)), "l49_bag")
	for i in 3:
		k.box(p + dv * (1.7 - i * 0.0) + lv * (i - 1) * 1.6 + Vector3(0, TR.FLOOR + 0.12, 0), _o(lv, Vector3(1.0, 0.24, 0.4)), "l49_board", GeoKit.ALL, true)
	# roof
	for i in 4:
		var x := -2.6 + i * 1.75
		k.box(p - dv * 0.4 + lv * x + Vector3(0, TR.FLOOR + 1.15, 0), Vector3(0.14, 2.3, 0.14), "l49_post")
	k.box(p - dv * 1.4 + Vector3(0, -0.28, 0), _o(lv, Vector3(6.2, 0.06, 3.2)), "l49_iron", GeoKit.ALL, false)
	k.box(p - dv * 0.4 + Vector3(0, -0.38, 0), _o(lv, Vector3(6.2, 0.16, 0.16)), "l49_post", GeoKit.ALL, false)
	# an empty machine-gun tripod on the step
	var mg := step_c + Vector3(0, 0.5, 0) - dv * 0.1
	for a in 3:
		var ang := TAU * a / 3.0
		var leg := Vector3(cos(ang), 0, sin(ang)) * 0.35
		k.box_xf(Transform3D(Basis.looking_at((leg - Vector3(0, 0.45, 0)).normalized(), Vector3.UP), mg + leg * 0.5 + Vector3(0, 0.22, 0)), Vector3(0.03, 0.03, 0.56), "l49_steel", GeoKit.ALL, false)
	k.box(mg + Vector3(0, 0.48, 0), Vector3(0.12, 0.08, 0.12), "l49_steel", GeoKit.ALL, false)
	return {"step": step_c + Vector3(0, 0.5, 0), "dv": dv, "lv": lv, "warn": p + dv * 1.6 + Vector3(0, TR.FLOOR + 1.3, 0)}


## A mortar that no human factory made: a ribbed tube on three unequal legs,
## a fin of greenish alloy where a sight would be.
static func mortar(k: GeoKit, p: Vector3, yaw: float, r: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.cylinder(p + Vector3(0, 0.06, 0), 0.42, 0.12, "l49_alien", 7, true)
	var tilt := b * Basis(Vector3.RIGHT, deg_to_rad(-30.0))
	var tube_c := p + Vector3(0, 0.75, 0) + b * Vector3(0, 0, 0.25)
	k.box_xf(Transform3D(tilt, tube_c), Vector3(0.22, 1.5, 0.22), "l49_alien", GeoKit.ALL, false)
	for i in 3:
		k.box_xf(Transform3D(tilt * Basis(Vector3.UP, 0.4 * i), tube_c + tilt * Vector3(0, -0.5 + i * 0.45, 0)), Vector3(0.27, 0.04, 0.27), "l49_alien_dark", GeoKit.ALL, false)
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		var foot := p + b * Vector3(cos(a) * (0.5 + i * 0.12), 0.0, sin(a) * (0.5 + i * 0.12) + 0.5)
		var head := tube_c + tilt * Vector3(0, 0.15 * i, 0)
		var dir := head - foot
		k.box_xf(Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), (foot + head) * 0.5), Vector3(0.05, 0.08, dir.length()), "l49_alien_dark", GeoKit.ALL, false)
	k.box_xf(Transform3D(tilt * Basis(Vector3.UP, 0.7), tube_c + tilt * Vector3(0.2, 0.2, 0)), Vector3(0.02, 0.35, 0.22), "l49_alien_glass", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, p + Vector3(0, 0.6, 0.2)), Vector3(0.9, 1.2, 1.0), "metal")


static func artillery(k: GeoKit, lay: Dictionary, r: RandomNumberGenerator) -> Array:
	var p := TR.cpos(lay["node"]) + Vector3(0, TR.FLOOR, 0)
	var spots: Array = []
	for i in 2 + r.randi() % 2:
		var mp := p + Vector3(r.randf_range(-1.8, 1.8), 0.0, -2.2 + i * 2.2)
		mortar(k, mp, r.randf_range(-0.6, 0.6) + PI, r)
		spots.append(mp)
	# a revetted ammunition recess
	k.box(p + Vector3(2.1, 0.5, 0), Vector3(0.4, 1.0, 2.6), "l49_bag")
	return spots


static func rifle(k: GeoKit, base: Vector3, n: Vector3, r: RandomNumberGenerator) -> void:
	# leaning against a wall: bottom on the floor, muzzle up against the planks
	var lean := Basis.looking_at((n * 0.35 + Vector3.UP).normalized(), Vector3(n.z, 0, -n.x) if absf(n.z) > 0.1 else Vector3.FORWARD)
	var up := (n * 0.35 + Vector3.UP).normalized()
	var c := base + up * 0.6
	k.box_xf(Transform3D(lean, c), Vector3(0.05, 0.07, 1.2), "l49_rifle_wood", GeoKit.ALL, false)
	k.box_xf(Transform3D(lean, c + up * 0.45), Vector3(0.025, 0.025, 0.5), "l49_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(lean, c - up * 0.48), Vector3(0.06, 0.12, 0.3), "l49_rifle_wood", GeoKit.ALL, false)
