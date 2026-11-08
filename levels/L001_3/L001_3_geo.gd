extends RefCounted
## Level 1.3 "Malignance": hallway, branches and the sixteen rooms (design notes
## in L001_3.gd). The single main hallway runs along -Z from the south end wall
## (z = +6) to the north end wall (z = -198). Eight branch pairs, one per 24 m
## chunk, lead left and right through 6 m corridors into 16 x 18 m rooms.
## Room types are seeded; eight are Detox Zones (The Ward is "stationed in all
## eight zones"). The Decay state (Dead Zone) is a flag the builder reads: black
## pits cut real holes in the floor, walls cave, the Detox Zones fall into abyss.

const S := 24.0
const NPAIR := 8
const HWD := 2.5          # hallway half width
const HH := 3.6           # hallway ceiling
const BR_H := 3.0         # branch corridor ceiling / opening height
const BR_W := 3.0
const RX0 := 8.5          # room inner edge (|x|)
const RX1 := 24.5         # room outer edge
const RD := 9.0           # room half depth (z)
const RH := 5.4           # room ceiling
const ZONE_Y := -0.54     # sunken Detox Zone floor (three risers)
const MEZ_Y := 2.7        # mezzanine deck (fifteen risers)
const WT := 0.3
const SOUTH := 6.0
const NORTH := -198.0
const VOID_Y := -9.0

var lvl
var types: Array = []      # 16 room types, index = pair * 2 + (0 west, 1 east)
var zone_no: Array = []    # Detox Zone number (1..8) or 0
var decay := false


func _init(level) -> void:
	lvl = level


static func pair_z(i: int) -> float:
	return -12.0 - S * i


static func pair_of_chunk(cz: int) -> int:
	return -cz - 1


func plan(rng: RandomNumberGenerator) -> void:
	var others := ["supplies", "supplies", "supplies", "surgery", "surgery", "admissions", "staff", "pharmacy"]
	var pool: Array = []
	for i in 8:
		pool.append("detox")
	pool.append_array(others)
	# Fisher-Yates with the level RNG; keep one Detox Zone in the first pair
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = t
	if pool[0] != "detox" and pool[1] != "detox":
		var k := pool.find("detox", 2)
		var t2: Variant = pool[0]
		pool[0] = pool[k]
		pool[k] = t2
	types = pool
	var n := 0
	zone_no = []
	for t in types:
		if t == "detox":
			n += 1
			zone_no.append(n)
		else:
			zone_no.append(0)


## World rect of room (pair i, side s = -1 west / +1 east).
static func room_rect(i: int, s: int) -> Rect2:
	var zc := pair_z(i)
	var x0 := RX0 if s > 0 else -RX1
	return Rect2(x0, zc - RD, RX1 - RX0, RD * 2.0)


static func zone_rect(i: int, s: int) -> Rect2:
	return room_rect(i, s).grow(-3.0)


## Mezzanine deck along the far wall (supplies and surgery rooms).
static func mez_rect(i: int, s: int) -> Rect2:
	var r := room_rect(i, s)
	if s > 0:
		return Rect2(r.end.x - 4.5, r.position.y, 4.5, r.size.y)
	return Rect2(r.position.x, r.position.y, 4.5, r.size.y)


# ------------------------------------------------------------------ floors

## Floor slab over rect with rectangular holes (pits). Splits the rect on the
## hole edges and emits every cell that is not inside a hole, merged per row.
static func floor_holes(k: GeoKit, rect: Rect2, y_top: float, holes: Array, mat: String, thick: float = 0.3) -> void:
	var xs: Array = [rect.position.x, rect.end.x]
	var zs: Array = [rect.position.y, rect.end.y]
	for h in holes:
		var hr: Rect2 = (h as Rect2).intersection(rect)
		if hr.size.x <= 0.0 or hr.size.y <= 0.0:
			continue
		xs.append_array([hr.position.x, hr.end.x])
		zs.append_array([hr.position.y, hr.end.y])
	xs.sort()
	zs.sort()
	for j in zs.size() - 1:
		var z0: float = zs[j]
		var z1: float = zs[j + 1]
		if z1 - z0 < 0.001:
			continue
		var open_run := false
		var run0 := 0.0
		for i in xs.size():
			var solid := false
			if i < xs.size() - 1:
				var x0: float = xs[i]
				var x1: float = xs[i + 1]
				if x1 - x0 >= 0.001:
					solid = true
					var cp := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
					for h in holes:
						if (h as Rect2).has_point(cp):
							solid = false
				elif open_run:
					continue
			if solid and not open_run:
				open_run = true
				run0 = xs[i]
			elif not solid and open_run:
				var xe: float = xs[i]
				k.box_mm(Vector3(run0, y_top - thick, z0), Vector3(xe, y_top, z1), mat)
				open_run = false


## The black shaft under a Decay pit, with a ragged black rim on the floor.
static func pit_shaft(k: GeoKit, hr: Rect2, y_top: float, r: RandomNumberGenerator) -> void:
	var b := VOID_Y
	k.box_mm(Vector3(hr.position.x - 0.1, b, hr.position.y - 0.1), Vector3(hr.end.x + 0.1, b + 0.1, hr.end.y + 0.1), "l13_void", GeoKit.PY, false)
	k.box_mm(Vector3(hr.position.x - 0.1, b, hr.position.y - 0.1), Vector3(hr.position.x, y_top - 0.01, hr.end.y + 0.1), "l13_void", GeoKit.ALL, false)
	k.box_mm(Vector3(hr.end.x, b, hr.position.y - 0.1), Vector3(hr.end.x + 0.1, y_top - 0.01, hr.end.y + 0.1), "l13_void", GeoKit.ALL, false)
	k.box_mm(Vector3(hr.position.x, b, hr.position.y - 0.1), Vector3(hr.end.x, y_top - 0.01, hr.position.y), "l13_void", GeoKit.ALL, false)
	k.box_mm(Vector3(hr.position.x, b, hr.end.y), Vector3(hr.end.x, y_top - 0.01, hr.end.y + 0.1), "l13_void", GeoKit.ALL, false)
	var per := 2.0 * (hr.size.x + hr.size.y)
	var n := int(per / 0.45)
	for i in n:
		var t := r.randf() * per
		var p: Vector2
		if t < hr.size.x:
			p = Vector2(hr.position.x + t, hr.position.y)
		elif t < 2.0 * hr.size.x:
			p = Vector2(hr.position.x + t - hr.size.x, hr.end.y)
		elif t < 2.0 * hr.size.x + hr.size.y:
			p = Vector2(hr.position.x, hr.position.y + t - 2.0 * hr.size.x)
		else:
			p = Vector2(hr.end.x, hr.position.y + t - 2.0 * hr.size.x - hr.size.y)
		var sz := Vector3(r.randf_range(0.2, 0.7), 0.004, r.randf_range(0.15, 0.5))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(p.x, y_top + 0.002 + r.randf() * 0.002, p.y)), sz, "l13_void", GeoKit.ALL, false)


# ------------------------------------------------------------------ chunk

## Returns meta {rooms:[{i,s,type,zone,rect,zone_rect,mez}], pits:[Rect2], hall_pits, signs, tiles}.
func build_chunk(cz: int, node: Node3D, r: RandomNumberGenerator) -> Dictionary:
	var meta := {"rooms": [], "pits": [], "hall_pits": [], "blood": 0, "cave": 0}
	var k := GeoKit.new(node, "K")
	var dk := GeoKit.new(node, "Dark")
	dk.shadows = false
	if cz == 0:
		_end_section(k, 0.0, SOUTH, SOUTH)
	elif cz == -9:
		_end_section(k, -192.0, NORTH, NORTH)
	elif cz <= -1 and cz >= -8:
		var i := pair_of_chunk(cz)
		_hall_section(k, dk, node, i, r, meta)
		for s: int in [-1, 1]:
			_branch(k, i, s)
			_room_shell(k, dk, node, i, s, r, meta)
	k.commit()
	dk.commit()
	return meta


## Hallway stub and end wall (the end walls are the noclip exits back to Level 1).
func _end_section(k: GeoKit, z_open: float, z_end: float, _wall_z: float) -> void:
	var z0 := minf(z_open, z_end)
	var z1 := maxf(z_open, z_end)
	k.box_mm(Vector3(-HWD - WT, -0.3, z0 - (0.3 if z_end < 0 else 0.0)), Vector3(HWD + WT, 0.0, z1 + (0.3 if z_end > 0 else 0.0)), "l13_tile")
	k.box_mm(Vector3(-HWD - WT, HH, z0 - 0.3), Vector3(HWD + WT, HH + 0.3, z1 + 0.3), "l13_ceiling", GeoKit.ALL, false)
	for sx: float in [-1.0, 1.0]:
		k.box_mm(Vector3(minf(sx * HWD, sx * (HWD + WT)), -0.3, z0), Vector3(maxf(sx * HWD, sx * (HWD + WT)), HH, z1), "l13_wall")
	var ez := z_end + (0.15 if z_end > 0 else -0.15)
	k.box(Vector3(0, HH * 0.5, ez), Vector3(HWD * 2.0 + WT * 2.0, HH + 0.3, 0.3), "l13_wall_end")
	for z in range(int(z0) + 1, int(z1), 3):
		_hall_panel(k, float(z) + 0.5, true)


func _hall_panel(k: GeoKit, z: float, lit: bool) -> void:
	var mat := "l13_panel"
	if decay:
		var h := absi(hash([lvl.level_seed, int(z * 10.0)])) % 100
		mat = "l13_panel_dead" if h < 62 else ("l13_panel_flick" if h < 82 else "l13_panel_dim")
	k.box(Vector3(0, HH - 0.01, z), Vector3(1.32, 0.03, 0.72), "l13_trim", GeoKit.ALL, false)
	k.panel(Vector3(0, HH - 0.03, z), 1.2, 0.6, mat, float(absi(int(z * 7.0)) % 13), 0.8 if mat == "l13_panel_flick" else 0.0)
	if lit and mat != "l13_panel_dead":
		var e := 1.45 if mat == "l13_panel" else 0.6
		lvl.lights.add_anchor(Vector3(0, HH - 0.4, z), Color(0.97, 0.99, 1.0) if not decay else Color(0.9, 0.86, 0.78), e, 8.5, 0.7 if mat == "l13_panel_flick" else 0.0, "k%d" % int(floor(z / S)))


## One 24 m hallway section with the branch openings of pair i.
func _hall_section(k: GeoKit, dk: GeoKit, node: Node3D, i: int, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var zc := pair_z(i)
	var z0 := zc - 12.0
	var z1 := zc + 12.0
	var holes: Array = []
	if decay:
		var side := 1.0 if r.randf() < 0.5 else -1.0
		for n in r.randi_range(1, 2):
			var pz := zc + (r.randf_range(4.0, 10.0) if n == 0 else -r.randf_range(4.0, 10.0))
			var pl := r.randf_range(1.5, 2.8)
			var pw := r.randf_range(1.6, 2.2)
			var hr := Rect2(side * HWD - (pw if side > 0 else 0.0), pz - pl * 0.5, pw, pl)
			holes.append(hr)
			side = -side
	floor_holes(k, Rect2(-HWD - WT, z0, (HWD + WT) * 2.0, S), 0.0, holes, "l13_tile")
	for h in holes:
		pit_shaft(dk, h, 0.0, r)
		meta["pits"].append(h)
		meta["hall_pits"].append(h)
		_cave_in(k, dk, h, r, meta)
	k.box_mm(Vector3(-HWD - WT, HH, z0), Vector3(HWD + WT, HH + 0.3, z1), "l13_ceiling", GeoKit.ALL, false)
	for sx: float in [-1.0, 1.0]:
		var x := sx * (HWD + WT * 0.5)
		k.wall(Vector3(x, 0, z1), Vector3(x, 0, z0), HH, WT, "l13_wall", [{"at": 12.0, "w": BR_W, "h": BR_H}])
		# stainless handrail and a pale skirting along the hallway walls
		for seg in [[z1 - 0.2, zc + BR_W * 0.5 + 0.2], [zc - BR_W * 0.5 - 0.2, z0 + 0.2]]:
			var a: float = seg[0]
			var b: float = seg[1]
			k.box(Vector3(sx * (HWD - 0.06), 0.9, (a + b) * 0.5), Vector3(0.05, 0.05, absf(a - b)), "l13_steel", GeoKit.ALL, false)
			k.box(Vector3(sx * (HWD - 0.012), 0.06, (a + b) * 0.5), Vector3(0.024, 0.12, absf(a - b)), "l13_skirt", GeoKit.ALL, false)
	var z := z1 - 1.5
	while z > z0:
		_hall_panel(k, z, int(round((z1 - z) / 3.0)) % 2 == 0)
		z -= 3.0
	if decay:
		_blood(k, Rect2(-HWD + 0.3, z0 + 1.0, HWD * 2.0 - 0.6, S - 2.0), r, meta, 2)
		_blotches(dk, r, Vector3(-HWD, 0, 0), z0, z1)
		_blotches(dk, r, Vector3(HWD, 0, 0), z0, z1)


## Short corridor from the hallway into the room on side s.
func _branch(k: GeoKit, i: int, s: int) -> void:
	var zc := pair_z(i)
	var xa := float(s) * (HWD + WT)
	var xb := float(s) * RX0
	k.box_mm(Vector3(minf(xa, xb), -0.3, zc - BR_W * 0.5), Vector3(maxf(xa, xb), 0.0, zc + BR_W * 0.5), "l13_tile")
	k.box_mm(Vector3(minf(xa, xb), BR_H, zc - BR_W * 0.5 - WT), Vector3(maxf(xa, xb), BR_H + 0.3, zc + BR_W * 0.5 + WT), "l13_ceiling", GeoKit.ALL, false)
	for sz: float in [-1.0, 1.0]:
		var zw := zc + sz * (BR_W * 0.5 + WT * 0.5)
		k.box_mm(Vector3(minf(xa, xb), -0.3, zw - WT * 0.5), Vector3(maxf(xa, xb), BR_H, zw + WT * 0.5), "l13_wall")
	var mid := (xa + xb) * 0.5
	k.box(Vector3(mid, BR_H - 0.01, zc), Vector3(0.72, 0.03, 1.32), "l13_trim", GeoKit.ALL, false)
	k.panel(Vector3(mid, BR_H - 0.03, zc), 0.6, 1.2, "l13_panel_dead" if decay and absi(hash([i, s])) % 3 != 0 else ("l13_panel_dim" if decay else "l13_panel"), 3.0)
	if not decay:
		lvl.lights.add_anchor(Vector3(mid, BR_H - 0.4, zc), Color(0.97, 0.99, 1.0), 0.9, 5.0, 0.0, "k%d" % int(floor(zc / S)))


## The 16 x 18 m room: walls, ceiling, floor (sunken Detox Zone or mezzanine).
func _room_shell(k: GeoKit, dk: GeoKit, node: Node3D, i: int, s: int, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var idx := i * 2 + (1 if s > 0 else 0)
	var typ: String = types[idx]
	var rr := room_rect(i, s)
	var zc := pair_z(i)
	var grp := "k%d" % int(floor(zc / S))
	var rec := {"i": i, "s": s, "type": typ, "zone": zone_no[idx], "rect": rr, "zone_rect": Rect2(), "mez": Rect2(), "holes": []}
	# walls (the hallway-side wall has the branch opening)
	var xi := float(s) * (RX0 - WT * 0.5)
	var xo := float(s) * RX1
	k.wall(Vector3(xi, 0, zc + RD + WT), Vector3(xi, 0, zc - RD - WT), RH, WT, "l13_wall", [{"at": RD + WT, "w": BR_W, "h": BR_H}])
	k.box_mm(Vector3(minf(xo, xo + s * WT), -0.3, zc - RD - WT), Vector3(maxf(xo, xo + s * WT), RH, zc + RD + WT), "l13_wall")
	for sz: float in [-1.0, 1.0]:
		var zw := zc + sz * (RD + WT * 0.5)
		k.box_mm(Vector3(rr.position.x, -0.3, zw - WT * 0.5), Vector3(rr.end.x, RH, zw + WT * 0.5), "l13_wall")
	k.box_mm(Vector3(rr.position.x - WT, RH, rr.position.y - WT), Vector3(rr.end.x + WT, RH + 0.3, rr.end.y + WT), "l13_ceiling", GeoKit.ALL, false)
	# bumper rail and skirting round the room (broken at the doorway)
	for e in [[Vector3(rr.position.x, 0, rr.position.y + 0.03), Vector3(rr.end.x, 0, rr.position.y + 0.03)],
			[Vector3(rr.position.x, 0, rr.end.y - 0.03), Vector3(rr.end.x, 0, rr.end.y - 0.03)],
			[Vector3(float(s) * (RX1 - 0.03), 0, rr.position.y), Vector3(float(s) * (RX1 - 0.03), 0, rr.end.y)],
			[Vector3(float(s) * (RX0 + 0.03), 0, rr.position.y), Vector3(float(s) * (RX0 + 0.03), 0, zc - BR_W * 0.5)],
			[Vector3(float(s) * (RX0 + 0.03), 0, zc + BR_W * 0.5), Vector3(float(s) * (RX0 + 0.03), 0, rr.end.y)]]:
		var a3: Vector3 = e[0]
		var b3: Vector3 = e[1]
		var c3 := (a3 + b3) * 0.5
		var sz3 := Vector3(maxf(absf(b3.x - a3.x), 0.05), 0.0, maxf(absf(b3.z - a3.z), 0.05))
		k.box(c3 + Vector3(0, 0.95, 0), sz3 + Vector3(0, 0.16, 0), "l13_skirt", GeoKit.ALL, false)
		k.box(c3 + Vector3(0, 0.06, 0), sz3 + Vector3(0, 0.12, 0), "l13_skirt", GeoKit.ALL, false)
	# floor
	var holes: Array = []
	if typ == "detox":
		var zr := zone_rect(i, s)
		rec["zone_rect"] = zr
		var ring := [Rect2(rr.position.x, rr.position.y, rr.size.x, zr.position.y - rr.position.y),
			Rect2(rr.position.x, zr.end.y, rr.size.x, rr.end.y - zr.end.y),
			Rect2(rr.position.x, zr.position.y, zr.position.x - rr.position.x, zr.size.y),
			Rect2(zr.end.x, zr.position.y, rr.end.x - zr.end.x, zr.size.y)]
		for q in ring:
			k.box_mm(Vector3(q.position.x, -0.6, q.position.y), Vector3(q.end.x, 0.0, q.end.y), "l13_tile")
		var abyss := Rect2()
		if decay:
			# "Most of it was gone, a gaping abyss": a rim of zone floor remains
			abyss = zr.grow(-1.3)
			holes.append(abyss)
			pit_shaft(dk, abyss, ZONE_Y, r)
			meta["pits"].append(abyss)
		floor_holes(k, zr, ZONE_Y, [abyss] if decay else [], "l13_zone_tile", 0.36)
		# stairs down from the door side and the far side
		var near_x := zr.position.x if s > 0 else zr.end.x
		var far_x := zr.end.x if s > 0 else zr.position.x
		k.stairs(Vector3(near_x + s * 0.9, ZONE_Y, zc), Vector3(-s, 0, 0), 2.0, -ZONE_Y, 3, "l13_zone_tile", 0.3)
		k.stairs(Vector3(far_x - s * 0.9, ZONE_Y, zc + 3.0), Vector3(s, 0, 0), 2.0, -ZONE_Y, 3, "l13_zone_tile", 0.3)
		# green tape on the zone edge
		for e in [[Vector3(zr.position.x - 0.12, 0.0, zr.position.y - 0.12), Vector3(zr.end.x + 0.12, 0.006, zr.position.y - 0.04)],
				[Vector3(zr.position.x - 0.12, 0.0, zr.end.y + 0.04), Vector3(zr.end.x + 0.12, 0.006, zr.end.y + 0.12)],
				[Vector3(zr.position.x - 0.12, 0.0, zr.position.y), Vector3(zr.position.x - 0.04, 0.006, zr.end.y)],
				[Vector3(zr.end.x + 0.04, 0.0, zr.position.y), Vector3(zr.end.x + 0.12, 0.006, zr.end.y)]]:
			k.box_mm(e[0], e[1], "l13_tape", GeoKit.ALL, false)
	else:
		if decay:
			for n in r.randi_range(1, 2):
				var px := rr.get_center().x + float(s) * r.randf_range(-3.5, 1.5)
				var pz := zc + (r.randf_range(3.5, 6.5) if n == 0 else -r.randf_range(3.5, 6.5))
				var hr := Rect2(px - 1.0, pz - 0.9, r.randf_range(1.6, 2.4), r.randf_range(1.4, 2.0))
				holes.append(hr)
				pit_shaft(dk, hr, 0.0, r)
				meta["pits"].append(hr)
		floor_holes(k, rr, 0.0, holes, "l13_tile")
		if typ in ["supplies", "surgery"]:
			_mezzanine(k, i, s, rec)
	rec["holes"] = holes
	# ceiling light grid (3 m)
	var nx := int(rr.size.x / 4.0)
	var nz := int(rr.size.y / 4.5)
	for a in nx:
		for b in nz:
			var c := Vector3(rr.position.x + (a + 0.5) * rr.size.x / nx, RH - 0.03, rr.position.y + (b + 0.5) * rr.size.y / nz)
			var mat := "l13_panel"
			if decay:
				var h := r.randi() % 100
				mat = "l13_panel_dead" if h < 60 else ("l13_panel_flick" if h < 80 else "l13_panel_dim")
			k.box(c + Vector3(0, 0.02, 0), Vector3(1.32, 0.03, 1.32), "l13_trim", GeoKit.ALL, false)
			k.panel(c, 1.2, 1.2, mat, r.randf() * 9.0, 0.8 if mat == "l13_panel_flick" else 0.0)
			if mat != "l13_panel_dead" and (a + b) % 2 == 0:
				lvl.lights.add_anchor(c + Vector3(0, -0.5, 0), Color(0.97, 0.99, 1.0) if not decay else Color(0.88, 0.84, 0.76),
					1.6 if mat == "l13_panel" else 0.7, 10.0, 0.7 if mat == "l13_panel_flick" else 0.0, grp)
	if decay:
		_blood(k, rr.grow(-1.0), r, meta, 3)
		_blotches(dk, r, Vector3(float(s) * RX1, 0, 0), zc - RD, zc + RD)
		for h in holes:
			if r.randf() < 0.6:
				_cave_room(k, dk, rr, h, s, r, meta)
	meta["rooms"].append(rec)


## Raised steel deck along the far wall with a stair against the north wall.
func _mezzanine(k: GeoKit, i: int, s: int, rec: Dictionary) -> void:
	var m := mez_rect(i, s)
	rec["mez"] = m
	var edge_x := m.position.x if s > 0 else m.end.x
	k.box_mm(Vector3(m.position.x, MEZ_Y - 0.2, m.position.y), Vector3(m.end.x, MEZ_Y, m.end.y), "l13_deck_metal")
	k.box_mm(Vector3(m.position.x, MEZ_Y - 0.22, m.position.y), Vector3(m.end.x, MEZ_Y - 0.2, m.end.y), "l13_trim", GeoKit.NY, false)
	# columns
	for z in [m.position.y + 0.3, m.get_center().y, m.end.y - 0.3]:
		k.box(Vector3(edge_x + s * 0.15, (MEZ_Y - 0.2) * 0.5, z), Vector3(0.2, MEZ_Y - 0.2, 0.2), "l13_steel")
	# railing along the open edge, gap at the stair head (north end)
	var gap0 := m.position.y
	var gap1 := m.position.y + 1.5
	k.box_mm(Vector3(edge_x - 0.03, MEZ_Y + 1.0, gap1), Vector3(edge_x + 0.03, MEZ_Y + 1.06, m.end.y), "l13_steel")
	k.box_mm(Vector3(edge_x - 0.02, MEZ_Y, gap1), Vector3(edge_x + 0.02, MEZ_Y + 1.0, m.end.y), "l13_glass", GeoKit.ALL, true)
	var z := gap1
	while z <= m.end.y + 0.01:
		k.box(Vector3(edge_x, MEZ_Y + 0.5, z), Vector3(0.05, 1.0, 0.05), "l13_steel", GeoKit.ALL, false)
		z += 1.5
	# stair: rises toward the far wall along the north wall
	var steps := 15
	var run := 0.3
	var sx := edge_x - s * (steps * run)
	k.stairs(Vector3(sx, 0.0, (gap0 + gap1) * 0.5), Vector3(s, 0, 0), 1.3, MEZ_Y, steps, "l13_deck_metal", run, false)
	var rz := gap1 + 0.04
	var a := Vector3(sx, 0.0, rz)
	var b := Vector3(edge_x, MEZ_Y, rz)
	var d := b - a
	var bz := d.normalized()
	var bx := Vector3.UP.cross(bz).normalized()
	var by := bz.cross(bx).normalized()
	k.box_xf(Transform3D(Basis(bx, by, bz), (a + b) * 0.5 + by * 1.0), Vector3(0.05, 0.05, d.length()), "l13_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(bx, by, bz), (a + b) * 0.5 + by * 0.5), Vector3(0.02, 1.0, d.length()), "l13_glass", GeoKit.ALL, true)


## Blood dried brown on the tile (Decay state; page: "streaks of oxidized blood").
func _blood(k: GeoKit, area: Rect2, r: RandomNumberGenerator, meta: Dictionary, n: int) -> void:
	for t in r.randi_range(1, n):
		var p := Vector3(r.randf_range(area.position.x, area.end.x), 0.004, r.randf_range(area.position.y, area.end.y))
		var yaw := r.randf() * TAU
		var L := r.randf_range(1.2, 3.8)
		for seg in r.randi_range(3, 6):
			var off := Basis(Vector3.UP, yaw) * Vector3(r.randf_range(-0.12, 0.12), 0, -L * 0.5 + L * seg / 5.0)
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.15, 0.15)), p + off), Vector3(r.randf_range(0.06, 0.22), 0.003, r.randf_range(0.4, 0.9)), "l13_blood", GeoKit.ALL, false)
		meta["blood"] += 1


## Irregular spots of pure blackness on a wall line x = wall.x between z0 and z1.
func _blotches(dk: GeoKit, r: RandomNumberGenerator, wall: Vector3, z0: float, z1: float) -> void:
	var s := signf(wall.x)
	for t in r.randi_range(1, 3):
		var c := Vector3(wall.x - s * 0.012, r.randf_range(0.6, 2.6), r.randf_range(z0 + 1.0, z1 - 1.0))
		for q in r.randi_range(5, 9):
			var o := Vector3(0, r.randf_range(-0.5, 0.5), r.randf_range(-0.7, 0.7))
			dk.box_xf(Transform3D(Basis(Vector3.RIGHT, r.randf() * TAU), c + o), Vector3(0.008, r.randf_range(0.2, 0.7), r.randf_range(0.2, 0.7)), "l13_void", GeoKit.ALL, false)


## A hallway wall caving toward a pit: a buckled panel leaning in, black behind.
func _cave_in(k: GeoKit, dk: GeoKit, hr: Rect2, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var s := 1.0 if hr.get_center().x > 0.0 else -1.0
	var zc := hr.get_center().y
	var w := hr.size.y + 0.8
	var lean := r.randf_range(0.12, 0.22)
	var bas := Basis(Vector3(0, 0, 1), s * lean)
	k.box_xf(Transform3D(bas, Vector3(s * (HWD - 0.25), 1.6, zc)), Vector3(0.12, 2.6, w), "l13_wall", GeoKit.ALL, false)
	dk.box(Vector3(s * (HWD - 0.01), 1.6, zc), Vector3(0.01, 2.8, w - 0.3), "l13_void", GeoKit.ALL, false)
	meta["cave"] += 1


func _cave_room(k: GeoKit, dk: GeoKit, rr: Rect2, hr: Rect2, s: int, r: RandomNumberGenerator, meta: Dictionary) -> void:
	# the nearest z wall bends in toward the pit
	var north := absf(hr.get_center().y - rr.position.y) < absf(hr.get_center().y - rr.end.y)
	var zw := rr.position.y + 0.3 if north else rr.end.y - 0.3
	var lean := r.randf_range(0.1, 0.2) * (1.0 if north else -1.0)
	var bas := Basis(Vector3(1, 0, 0), -lean)
	k.box_xf(Transform3D(bas, Vector3(hr.get_center().x, 2.2, zw)), Vector3(hr.size.x + 1.4, 3.6, 0.12), "l13_wall", GeoKit.ALL, false)
	dk.box(Vector3(hr.get_center().x, 2.2, zw + (-0.29 if north else 0.29)), Vector3(hr.size.x + 1.0, 3.8, 0.01), "l13_void", GeoKit.ALL, false)
	meta["cave"] += 1
