extends RefCounted
## Level 22 structure: three walkable decks of a 20th-century multi-storey car park
## (floor to floor 3.0 m, 8 m column grid, downstand beams), the roof slab above, the
## car ramp, a concrete switchback stair core with glass lobby doors, a deck that
## collapsed into a walkable debris ramp, ragged mining holes (one is a deep shaft), a
## hole up through the roof, and a perimeter choked with collapse rubble beyond which
## the decks carry on into the dark ("an infinite, average-looking car park").

const X0 := -32.0
const X1 := 32.0
const Z0 := -24.0
const Z1 := 24.0
const FLOOR := 3.0
const SLAB := 0.3
const DECKS := [0.0, 3.0, 6.0, 9.0]            # A, B, C walkable; D is the roof above C
const OUT := 14.0                             # how far the decks visibly continue past the rubble

# holes per deck index (Rect2: x, z, w, d)
const SHAFT := Rect2(-15.0, 3.0, 7.0, 7.0)                   # deck A: deep mining shaft (-> Level 23)
const RAMP_SLOT := Rect2(8.0, 15.0, 19.0, 6.0)               # deck B: the car ramp from A
const COLLAPSE_B := Rect2(-24.0, -14.0, 10.0, 9.0)           # deck B: collapse hole onto deck A
const DEBRIS := Rect2(2.0, -21.0, 11.0, 9.0)                 # deck C: slab fell onto B as a ramp
const ROOF_HOLE := Rect2(19.5, -6.5, 5.0, 5.0)               # roof: hole up (-> Level 21)
const CORE := Rect2(-32.0, -24.0, 6.0, 6.0)                  # stair core (all decks)
const WELL := Rect2(-31.6, -22.4, 5.2, 4.2)                  # stairwell opening inside the core

const STAIR_RUN := 0.28


static func holes_for(deck: int) -> Array:
	match deck:
		0: return [SHAFT]
		1: return [RAMP_SLOT, COLLAPSE_B, WELL]
		2: return [DEBRIS, WELL]
		3: return [ROOF_HOLE, WELL]
	return []


## A slab over [x0,x1]x[z0,z1] at top height y, minus rectangular holes (grid split).
static func slab_holes(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float, holes: Array, mat: String, collide: bool = true) -> void:
	var xs := [x0, x1]
	var zs := [z0, z1]
	for h in holes:
		var r: Rect2 = h
		for v in [r.position.x, r.end.x]:
			if v > x0 and v < x1 and not xs.has(v):
				xs.append(v)
		for v in [r.position.y, r.end.y]:
			if v > z0 and v < z1 and not zs.has(v):
				zs.append(v)
	xs.sort()
	zs.sort()
	# merge runs along x to keep the box count low
	for j in zs.size() - 1:
		var run0 := -1
		for i in xs.size():
			var solid := false
			if i < xs.size() - 1:
				var c := Vector2((xs[i] + xs[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5)
				solid = true
				for h in holes:
					if (h as Rect2).has_point(c):
						solid = false
			if solid and run0 < 0:
				run0 = i
			elif not solid and run0 >= 0:
				k.box_mm(Vector3(xs[run0], y - SLAB, zs[j]), Vector3(xs[i], y, zs[j + 1]), mat, GeoKit.ALL, collide)
				run0 = -1


static func build(L, k: GeoKit) -> void:
	for d in DECKS.size():
		var y: float = DECKS[d]
		var holes := holes_for(d)
		# the walkable deck (or roof) inside the playable area
		slab_holes(k, X0, Z0, X1, Z1, y, holes, "l22_deck" if d < 3 else "l22_soffit")
		# the deck carries on past the rubble into the dark (seen, never reached)
		for e in [Rect2(X0 - OUT, Z0 - OUT, OUT, Z1 - Z0 + OUT * 2.0), Rect2(X1, Z0 - OUT, OUT, Z1 - Z0 + OUT * 2.0),
				Rect2(X0, Z0 - OUT, X1 - X0, OUT), Rect2(X0, Z1, X1 - X0, OUT)]:
			var r: Rect2 = e
			k.box_mm(Vector3(r.position.x, y - SLAB, r.position.y), Vector3(r.end.x, y, r.end.y), "l22_deck" if d < 3 else "l22_soffit", GeoKit.ALL, false)
		if d == 0:
			continue
		# downstand beams under this slab along x on every grid line
		var by := y - SLAB
		for zi in range(-5, 6):
			var z := zi * 8.0
			if z < Z0 - OUT or z > Z1 + OUT:
				continue
			var segs := [[X0 - OUT, X1 + OUT]]
			for h in holes:
				var r: Rect2 = h
				if z > r.position.y - 0.3 and z < r.end.y + 0.3:
					var nsegs := []
					for sg in segs:
						if r.position.x > sg[0] and r.position.x < sg[1]:
							nsegs.append([sg[0], r.position.x])
						if r.end.x > sg[0] and r.end.x < sg[1]:
							nsegs.append([r.end.x, sg[1]])
						if r.position.x >= sg[1] or r.end.x <= sg[0]:
							nsegs.append(sg)
					segs = nsegs
			for sg in segs:
				if float(sg[1]) - float(sg[0]) > 0.5:
					k.box_mm(Vector3(sg[0], by - 0.45, z - 0.2), Vector3(sg[1], by, z + 0.2), "l22_concrete", GeoKit.ALL, false)
	# columns on the 8 m grid, every storey (skipping holes and the core)
	for d in 3:
		var y: float = DECKS[d]
		for xi in range(-6, 7):
			for zi in range(-4, 5):
				var p := Vector2(xi * 8.0, zi * 8.0)
				if p.x < X0 - OUT + 1 or p.x > X1 + OUT - 1:
					continue
				var inside := p.x > X0 - 0.1 and p.x < X1 + 0.1 and p.y > Z0 - 0.1 and p.y < Z1 + 0.1
				var skip := false
				for h in holes_for(d) + [CORE]:
					if (h as Rect2).grow(0.5).has_point(p):
						skip = true
				if skip:
					continue
				k.box(Vector3(p.x, y + (FLOOR - SLAB) * 0.5, p.y), Vector3(0.6, FLOOR - SLAB, 0.6), "l22_concrete", GeoKit.ALL, inside)
				if inside:
					L.columns.append(Vector3(p.x, y, p.y))
	_ramp(L, k)
	_core(L, k)
	_shaft(L, k)
	_roof_shaft(L, k)
	_debris_ramp(L, k)


## The car ramp from deck A up to deck B, with kerbs.
static func _ramp(_L, k: GeoKit) -> void:
	var r := RAMP_SLOT
	var zc := r.position.y + r.size.y * 0.5
	k.ramp(Vector3(r.position.x + 0.5, 0.0, zc), Vector3(r.end.x, DECKS[1], zc), r.size.y - 0.6, 0.3, "l22_deck", "concrete")
	for s in [-1.0, 1.0]:
		var z: float = zc + s * (r.size.y * 0.5 - 0.2)
		var a := Vector3(r.position.x + 0.5, 0.0, z)
		var b := Vector3(r.end.x, DECKS[1], z)
		var mid := (a + b) * 0.5 + Vector3(0, 0.35, 0)
		var zz := (b - a).normalized()
		var xx := Vector3.UP.cross(zz).normalized()
		k.box_xf(Transform3D(Basis(xx, zz.cross(xx), zz), mid), Vector3(0.3, 0.7, a.distance_to(b)), "l22_concrete", GeoKit.ALL, true)


## Concrete switchback stair core in the SW corner: landings at every deck, a mid landing
## between; doorways east onto each deck (deck B's are the glass doors).
static func _core(L, k: GeoKit) -> void:
	var c := CORE
	var xw := c.position.x + 0.4
	var xe := c.end.x
	for d in 3:
		var y: float = DECKS[d]
		# walls (west and south are the building edge; north and east face the deck)
		k.wall(Vector3(c.position.x, y, c.end.y), Vector3(xe, y, c.end.y), FLOOR - SLAB, 0.25, "l22_core")
		k.wall(Vector3(xe, y, c.position.y), Vector3(xe, y, c.end.y), FLOOR - SLAB, 0.25, "l22_core",
			[{"at": 1.0, "w": 1.5, "h": 2.15, "sill": 0.0}])
		k.wall(Vector3(c.position.x, y, c.position.y), Vector3(c.position.x, y, c.end.y), FLOOR - SLAB, 0.25, "l22_core")
		k.wall(Vector3(c.position.x, y, c.position.y), Vector3(xe, y, c.position.y), FLOOR - SLAB, 0.25, "l22_core")
		if d < 3:
			var steps := 8
			var half := FLOOR * 0.5
			var w0 := WELL
			# flight 1 (west half) rises north to the mid landing, flight 2 (east half) returns south
			k.stairs(Vector3(w0.position.x + 1.2, y, w0.position.y), Vector3(0, 0, 1), 2.3, half, steps, "l22_concrete", STAIR_RUN, d == 0)
			var mz := w0.position.y + steps * STAIR_RUN
			k.box_mm(Vector3(w0.position.x, (y if d == 0 else y + half - 0.25), mz), Vector3(w0.end.x, y + half, w0.end.y), "l22_concrete")
			if d < 2:
				k.stairs(Vector3(w0.end.x - 1.2, y + half, mz), Vector3(0, 0, -1), 2.3, half, steps, "l22_concrete", STAIR_RUN, false)
			else:
				# the flights above deck C are buried: rubble fills the mid landing to the roof
				L.rubble_pile(Vector3(w0.position.x + w0.size.x * 0.5, y + half, w0.position.y + w0.size.y * 0.5 + 0.6), Vector3(w0.size.x * 0.5, 2.6, 1.6), true)
			# a steel rail between the flights
			k.box_mm(Vector3(w0.position.x + 2.4, (y if d == 0 else y - 0.6), w0.position.y), Vector3(w0.position.x + 2.6, y + half + 0.95, mz), "l22_core", GeoKit.ALL, true)
		# painted floor sign (census material designations)
		var label: String = ["FLOOR 8\nANOMALOUS ITEM SCAVENGERS", "FLOOR 9\nCONCRETE MINERS", "FLOOR 10\nAPPLIANCE FORAGING"][d]
		L.label(label, Vector3(xe + 0.14, y + 1.75, c.position.y + 3.6), Vector3(1, 0, 0), 0.006, Color(0.85, 0.82, 0.7), 64)
	# glass lobby doors on deck B (the Level 1 arrival)
	var y1: float = DECKS[1]
	var dz := c.position.y + 1.0
	var gk: GeoKit = L.kit("GlassDoors")
	for s in [-1.0, 1.0]:
		# both leaves stand open, swung out onto the deck
		var hinge := Vector3(xe + 0.02, y1 + 1.07, dz + s * 0.75)
		var leaf := Basis(Vector3.UP, s * deg_to_rad(-80.0))
		gk.box_xf(Transform3D(leaf, hinge + leaf * Vector3(0, 0, -s * 0.36)), Vector3(0.04, 2.1, 0.72), "l22_glass", GeoKit.ALL, false)
		gk.box_xf(Transform3D(leaf, hinge + leaf * Vector3(0, 0, -s * 0.36)), Vector3(0.06, 2.12, 0.74), "l22_alu", GeoKit.PY | GeoKit.NY, false)
		gk.box(Vector3(xe + 0.02, y1 + 1.07, dz + s * 0.78), Vector3(0.12, 2.15, 0.06), "l22_alu", GeoKit.ALL, false)
	gk.box(Vector3(xe + 0.02, y1 + 2.12, dz), Vector3(0.1, 0.06, 1.5), "l22_alu", GeoKit.ALL, false)
	gk.commit()
	L.glass_door_at = Vector3(xe + 0.02, y1, dz)


## The deep mining shaft below deck A: rough concrete then raw rock into the dark.
static func _shaft(_L, k: GeoKit) -> void:
	var r := SHAFT
	var depth := 34.0
	for side in 4:
		var bx := r.position.x
		var bz := r.position.y
		match side:
			0: k.box_mm(Vector3(bx - 0.6, -depth, bz - 0.6), Vector3(r.end.x + 0.6, -SLAB, bz), "l22_shaftwall", GeoKit.PZ, true)
			1: k.box_mm(Vector3(bx - 0.6, -depth, r.end.y), Vector3(r.end.x + 0.6, -SLAB, r.end.y + 0.6), "l22_shaftwall", GeoKit.NZ, true)
			2: k.box_mm(Vector3(bx - 0.6, -depth, bz), Vector3(bx, -SLAB, r.end.y), "l22_shaftwall", GeoKit.PX, true)
			3: k.box_mm(Vector3(r.end.x, -depth, bz), Vector3(r.end.x + 0.6, -SLAB, r.end.y), "l22_shaftwall", GeoKit.NX, true)


## A hole up through the roof slab: a short broken shaft rising toward Level 21.
static func _roof_shaft(_L, k: GeoKit) -> void:
	var r := ROOF_HOLE
	var y0: float = DECKS[3]
	var y1 := y0 + 7.0
	k.box_mm(Vector3(r.position.x - 0.5, y0, r.position.y - 0.5), Vector3(r.end.x + 0.5, y1, r.position.y), "l22_shaftwall", GeoKit.PZ, false)
	k.box_mm(Vector3(r.position.x - 0.5, y0, r.end.y), Vector3(r.end.x + 0.5, y1, r.end.y + 0.5), "l22_shaftwall", GeoKit.NZ, false)
	k.box_mm(Vector3(r.position.x - 0.5, y0, r.position.y), Vector3(r.position.x, y1, r.end.y), "l22_shaftwall", GeoKit.PX, false)
	k.box_mm(Vector3(r.end.x, y0, r.position.y), Vector3(r.end.x + 0.5, y1, r.end.y), "l22_shaftwall", GeoKit.NX, false)


## Part of deck C broke at its south edge and dropped onto deck B: a walkable debris ramp.
static func _debris_ramp(L, k: GeoKit) -> void:
	var r := DEBRIS
	var xc := r.position.x + r.size.x * 0.5
	var a := Vector3(xc, DECKS[1], r.position.y + 0.4)
	var b := Vector3(xc, DECKS[2], r.end.y)
	k.ramp(a, b, r.size.x - 3.0, 0.3, "l22_deck", "concrete")
	L.debris_ramp = [a, b, r.size.x - 3.0]
