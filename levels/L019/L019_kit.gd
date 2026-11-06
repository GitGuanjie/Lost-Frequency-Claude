extends RefCounted
## Level 19 prop helpers (GeoKit only). Source: "Level 19 - Attic Floorboards"
## (Backrooms Wiki rev 55, CC BY-SA 3.0), dossier docs/canon/levels/L019.md:
## "packed with a heavy clutter of boxes, vintage furniture"; draft testimony adds
## tables, ottomans, bookcases and sofas with a care-home feel; empty door frames.


static func _b(yaw: float) -> Basis:
	return Basis(Vector3.UP, yaw)


## Cardboard box, damp and dusty outside. open = flaps up, clean interior visible.
static func box(k: GeoKit, c: Vector3, s: Vector3, yaw: float, open: bool = false) -> void:
	var b := _b(yaw)
	var h := s * 0.5
	if not open:
		k.box_xf(Transform3D(b, c), s, "l19_cardboard")
		k.box_xf(Transform3D(b, c + Vector3.UP * (h.y + 0.002)), Vector3(s.x + 0.004, 0.004, 0.06), "l19_tape", GeoKit.PY, false)
		return
	k.box_xf(Transform3D(b, c + Vector3.UP * (-h.y + 0.02)), Vector3(s.x, 0.04, s.z), "l19_cardboard")
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + b * Vector3(sx * (h.x - 0.01), 0, 0)), Vector3(0.02, s.y, s.z), "l19_cardboard")
		k.box_xf(Transform3D(b, c + b * Vector3(0, 0, sx * (h.z - 0.01))), Vector3(s.x - 0.04, s.y, 0.02), "l19_cardboard")
		var fb := b * Basis(Vector3.RIGHT, sx * 0.5)
		k.box_xf(Transform3D(fb, c + b * Vector3(0, h.y + h.z * 0.4, sx * (h.z + 0.08))), Vector3(s.x, 0.012, h.z), "l19_cardboard", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + Vector3.UP * (h.y - 0.12)), Vector3(s.x - 0.05, 0.01, s.z - 0.05), "l19_clean", GeoKit.PY, false)


## Vintage sofa in faded floral fabric (care-home feel).
static func sofa(k: GeoKit, c: Vector3, yaw: float, w: float = 1.9) -> void:
	var b := _b(yaw)
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.22), Vector3(w, 0.3, 0.85), "l19_fabric")
	k.box_xf(Transform3D(b, c + b * Vector3(0, 0.62, 0.34)), Vector3(w, 0.55, 0.18), "l19_fabric", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + b * Vector3(sx * (w * 0.5 - 0.09), 0.5, 0.0)), Vector3(0.18, 0.32, 0.85), "l19_fabric", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b * Vector3(sx * w * 0.24, 0.42, -0.05)), Vector3(w * 0.46, 0.12, 0.7), "l19_fabric", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b * Vector3(sx * (w * 0.5 - 0.1), 0.04, 0.3)), Vector3(0.05, 0.08, 0.05), "l19_wood", GeoKit.ALL, false)


static func ottoman(k: GeoKit, c: Vector3, yaw: float) -> void:
	k.box_xf(Transform3D(_b(yaw), c + Vector3.UP * 0.22), Vector3(0.6, 0.36, 0.6), "l19_fabric")
	k.box_xf(Transform3D(_b(yaw), c + Vector3.UP * 0.42), Vector3(0.62, 0.05, 0.62), "l19_fabric", GeoKit.ALL, false)


static func table(k: GeoKit, c: Vector3, yaw: float, w: float, d: float, h: float) -> void:
	var b := _b(yaw)
	k.box_xf(Transform3D(b, c + Vector3.UP * (h - 0.025)), Vector3(w, 0.05, d), "l19_wood")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * (w * 0.5 - 0.06), (h - 0.05) * 0.5, sz * (d * 0.5 - 0.06))), Vector3(0.05, h - 0.05, 0.05), "l19_wood", GeoKit.ALL, false)


## Bookcase with rows of dusty books.
static func bookcase(k: GeoKit, c: Vector3, yaw: float, r: RandomNumberGenerator) -> void:
	var b := _b(yaw)
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.9), Vector3(1.0, 1.8, 0.34), "l19_wood")
	for y in [0.35, 0.8, 1.25]:
		var x := -0.42
		while x < 0.42:
			var w := r.randf_range(0.03, 0.07)
			var hh := r.randf_range(0.22, 0.32)
			k.box_xf(Transform3D(b, c + b * Vector3(x + w * 0.5, y + hh * 0.5, -0.18)), Vector3(w, hh, 0.2), ["l19_book_a", "l19_book_b", "l19_book_c"][r.randi() % 3], GeoKit.ALL, false)
			x += w + 0.005


## Steamer trunk / chest.
static func trunk(k: GeoKit, c: Vector3, yaw: float) -> void:
	k.box_xf(Transform3D(_b(yaw), c + Vector3.UP * 0.25), Vector3(0.9, 0.5, 0.5), "l19_wood")
	k.box_xf(Transform3D(_b(yaw), c + Vector3.UP * 0.25), Vector3(0.92, 0.06, 0.52), "l19_metal", GeoKit.SIDES, false)


static func lamp(k: GeoKit, c: Vector3) -> void:
	k.cylinder(c + Vector3.UP * 0.7, 0.02, 1.4, "l19_metal", 6, false)
	k.cylinder(c + Vector3.UP * 1.45, 0.2, 0.28, "l19_shade", 8, false)
	k.cylinder(c + Vector3.UP * 0.02, 0.16, 0.04, "l19_metal", 8, false)


## Trim around an empty door frame in a wall running along `along`.
static func frame(k: GeoKit, c: Vector3, along: Vector3, w: float, h: float) -> void:
	var n := along.cross(Vector3.UP).normalized()
	var bas := Basis(along, Vector3.UP, n)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + along * ((w * 0.5 + 0.04) * s) + Vector3.UP * (h * 0.5)), Vector3(0.08, h, 0.18), "l19_trim", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3.UP * (h + 0.05)), Vector3(w + 0.16, 0.1, 0.18), "l19_trim", GeoKit.ALL, false)


## Broken, damaged door hanging off one hinge in a frame, darkness beyond.
## out = direction from the room into the doorway.
static func broken_door(k: GeoKit, c: Vector3, along: Vector3, out: Vector3) -> void:
	frame(k, c, along, 1.05, 1.95)
	# torn off its top hinge, split, leaning back against the wall inside the room
	var dir := (-along * 0.97 - out * 0.24).normalized()
	var nrm := dir.cross(Vector3.UP).normalized()
	var bas := Basis(dir, Vector3.UP, nrm).rotated(nrm, -0.16)
	var hinge := c - along * 0.56 - out * 0.1
	k.box_xf(Transform3D(bas, hinge + bas * Vector3(0.45, 0.5, 0)), Vector3(0.88, 1.0, 0.045), "l19_door", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas.rotated(nrm, 0.07), hinge + bas * Vector3(0.43, 1.52, 0.02)), Vector3(0.88, 0.86, 0.045), "l19_door", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, hinge + bas * Vector3(0.15, 1.08, -0.03)), Vector3(0.12, 0.06, 0.03), "l19_metal", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.7), c - out * 0.7 + along * 0.25 + Vector3.UP * 0.02), Vector3(0.5, 0.03, 0.14), "l19_door", GeoKit.ALL, false)
	k.box_mm(c + out * 0.1 - along * 0.7, c + out * 1.4 + along * 0.7 + Vector3.UP * 2.2, "l19_void", GeoKit.ALL, false)


## Tilted ceiling slab rising from the line a-b toward `inward`, with rafters.
static func slope(k: GeoKit, a: Vector3, b: Vector3, inward: Vector3, rise: float, run: float, mat: String) -> void:
	var ax := (b - a).normalized()
	var ln := a.distance_to(b)
	var sl := sqrt(rise * rise + run * run)
	var d := (inward * run + Vector3.UP * rise) / sl
	var up := d.cross(ax)
	var bas := Basis(ax, up, d)
	k.box_xf(Transform3D(bas, (a + b) * 0.5 + inward * run * 0.5 + Vector3.UP * rise * 0.5 + up * 0.06), Vector3(ln, 0.12, sl), mat, GeoKit.NY)
	var s := 0.3
	while s < ln - 0.1:
		k.box_xf(Transform3D(bas, a + ax * s + inward * run * 0.5 + Vector3.UP * rise * 0.5 - up * 0.05), Vector3(0.07, 0.1, sl), "l19_rafter", GeoKit.ALL ^ GeoKit.PY, false)
		s += 0.6


## Floorboards over a rectangle, leaving the given holes open (grid split).
static func floor_holes(k: GeoKit, rc: Rect2, holes: Array, mat: String) -> void:
	var xs := [rc.position.x, rc.end.x]
	var zs := [rc.position.y, rc.end.y]
	for hh in holes:
		var r: Rect2 = hh["r"]
		xs.append_array([r.position.x, r.end.x])
		zs.append_array([r.position.y, r.end.y])
	xs.sort()
	zs.sort()
	for zi in zs.size() - 1:
		for xi in xs.size() - 1:
			var cell := Rect2(xs[xi], zs[zi], xs[xi + 1] - xs[xi], zs[zi + 1] - zs[zi])
			if cell.size.x < 0.01 or cell.size.y < 0.01:
				continue
			var inside := false
			for hh in holes:
				if (hh["r"] as Rect2).grow(-0.005).has_point(cell.get_center()):
					inside = true
			if not inside:
				k.slab(cell.position.x, cell.position.y, cell.end.x, cell.end.y, 0.0, 0.3, mat, GeoKit.PY)


## Gable passage between two rooms: "the ceilings ... are just triangular slopes
## that taper down to the floor" (draft), with board caps above the knee walls.
static func wing(k: GeoKit, w: Dictionary) -> void:
	var ax := Vector3(1, 0, 0) if w["x"] else Vector3(0, 0, 1)
	var pp := Vector3(0, 0, 1) if w["x"] else Vector3(1, 0, 0)
	var s0: float = w["s0"]
	var s1: float = w["s1"]
	var hw: float = w["w"] * 0.5
	var rh: float = w["rh"]
	var a: Vector3 = ax * s0 + pp * float(w["c"])
	var b: Vector3 = ax * s1 + pp * float(w["c"])
	var mn := a - pp * hw
	var mx := b + pp * hw
	k.slab(minf(mn.x, mx.x), minf(mn.z, mx.z), maxf(mn.x, mx.x), maxf(mn.z, mx.z), 0.0, 0.3, "l19_floorwood", GeoKit.PY)
	for sg in [-1.0, 1.0]:
		slope(k, a + pp * hw * sg + Vector3.UP * 0.12, b + pp * hw * sg + Vector3.UP * 0.12, -pp * sg, rh - 0.12, hw, "l19_plush_insul")
		k.box((a + b) * 0.5 + pp * (hw - 0.03) * sg + Vector3.UP * 0.15, (ax * (s1 - s0)).abs() + pp * 0.06 + Vector3.UP * 0.3, "l19_rafter", GeoKit.ALL, true)
	for end in [[a, w["kwa"]], [b, w["kwb"]]]:
		var t := -hw
		var kw: float = end[1]
		while t < hw:
			var top := 0.12 + (rh - 0.12) * (1.0 - absf(t + 0.08) / hw)
			if top > kw + 0.03:
				k.box(end[0] + pp * (t + 0.08) + Vector3.UP * (kw + top) * 0.5, pp * 0.15 + ax * 0.05 + Vector3.UP * (top - kw), "l19_walls", GeoKit.ALL, false)
			t += 0.16


## The M.E.O.D. revision archive (paraphrased); the glow's unsanctioned edit.
static func tablet_text(altered: bool) -> String:
	if altered:
		return "Revision 13 (no editor recorded)\n\nLevel 19 is warm. The boxes are full and the food is good. There is a soft orange light under the boards and it is the kindest thing down here; sit with it a while and you will feel better. You do not need the doors. You do not need the note you came in with. Everyone is waiting under the floor and they are so glad you came."
	return "Revision 12 (sanctioned)\n\nLevel 19: a dank, dilapidated attic made of randomly shaped spaces crammed with boxes and old furniture. The outsides are damp and dusty; the insides are almost always pristine. Boxes often hold food and catalogued objects, but anything taken out may begin to rot quickly, and people here report nausea, paranoia, dizziness, blackouts and hallucinations.\n\nSome floorboards glow warm orange from underneath. The glow is comforting and draws people in, and it seems to rework their memories around itself. It may be the cause of the decay, or it may feed it.\n\nKnown ways out: fall through a board or crevice that is not glowing; an occasional broken or damaged door; a handheld game found in a box. No bases, no settlements. Entering is heavily unadvised."


## Cobweb sheet spanning a corner ("Cobwebs are common" — draft testimony).
static func web(k: GeoKit, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	k._tri_fan(a, b, c, n, "l19_web")
	k._tri_fan(a, c, b, -n, "l19_web")


## A handheld game in an open box ("handheld games or small arcade devices").
static func handheld(k: GeoKit, c: Vector3, yaw: float) -> void:
	box(k, c + Vector3.UP * 0.2, Vector3(0.5, 0.4, 0.4), yaw, true)
	var b := _b(yaw)
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.5), c + Vector3.UP * 0.3), Vector3(0.11, 0.17, 0.03), "l19_plastic", GeoKit.ALL, false)
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.5), c + Vector3.UP * 0.315 + b * Vector3(0, 0, 0.0)), Vector3(0.07, 0.06, 0.034), "l19_screen", GeoKit.ALL, false)
