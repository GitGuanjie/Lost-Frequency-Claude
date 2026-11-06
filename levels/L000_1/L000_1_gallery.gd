extends RefCounted
## Level 0.1 Inner Gallery: four decks on the cavity wall (SOURCE: "made
## primarily out of metal and glass", "bedrooms, kitchens, gyms, and even some
## hydroponic greenhouses", "automatic sliding doors", damage with "exposed
## wires and broken electronics"). ADAPTATION: the deck plan, the stepped
## glass line that follows the sphere, the atrium with alternating stair
## flights and the maintenance gantry are ours (the page gives no map).

const D := preload("res://levels/L000_1/L000_1_dims.gd")

var lvl
var sys
var rng: RandomNumberGenerator
var modules: Array = []
var noclip_spots: Array = []
var glass := D.Quads.new()
var stats := {"broken_panes": 0, "debris": 0}


func _init(level, systems) -> void:
	lvl = level
	sys = systems
	rng = level.rng


func build() -> void:
	_plan()
	for k in D.DECKS:
		_deck(k)
	_roof()
	_stairs()
	_atrium()
	_gantry()
	for m in modules:
		_module(m)
	for k in D.DECKS:
		_promenade_props(k)
	glass.commit(lvl, "GalleryGlass")


# ------------------------------------------------------------------ plan

func _plan() -> void:
	var types := ["bedroom", "kitchen", "gym", "bedroom", "kitchen", "gym", "greenhouse"]
	for k in D.DECKS:
		for i in 6:
			var m := {"deck": k, "slot": i, "x0": -D.GX + 10.0 * i, "type": "sealed", "state": "normal", "door": "jammed"}
			var r := rng.randf()
			var t: String = types[rng.randi() % types.size()]
			var s := rng.randf()
			if k == 0 and i == 2:
				m["type"] = "lift"
			elif r < 0.64:
				m["type"] = t
				m["state"] = "normal" if s < 0.5 else ("dark" if s < 0.72 else ("cold" if s < 0.86 else "hot"))
			modules.append(m)
	_force(0, 1, "kitchen", "normal")
	_force(0, 3, "bedroom", "normal")
	var have := {}
	for m in modules:
		have[m["type"]] = true
		have[m["state"] + "_" + str(m["type"] != "sealed" and m["type"] != "lift")] = true
	if not have.has("greenhouse"):
		_force(1, 4, "greenhouse", "normal")
	if not have.has("cold_true"):
		_force(2, 0, "bedroom", "cold")
	if not have.has("hot_true"):
		_force(3, 5, "kitchen", "hot")
	for m in modules:
		var open: bool = m["type"] != "sealed" and m["type"] != "lift"
		if open:
			m["door"] = "auto"
			if m["state"] == "dark":
				m["door"] = "stutter" if rng.randf() < 0.5 else "stuck"
		elif m["type"] == "lift":
			m["door"] = "lift"


func _force(k: int, i: int, t: String, s: String) -> void:
	var m: Dictionary = modules[k * 6 + i]
	m["type"] = t
	m["state"] = s


# ----------------------------------------------------------------- decks

func _slab_holes(kt: GeoKit, x0: float, x1: float, z0: float, z1: float, y: float, holes: Array, mat: String) -> void:
	var xs := [x0, x1]
	for h: Rect2 in holes:
		for xv: float in [h.position.x, h.end.x]:
			if xv > x0 and xv < x1 and not xs.has(xv):
				xs.append(xv)
	xs.sort()
	for i in xs.size() - 1:
		var a: float = xs[i]
		var b: float = xs[i + 1]
		var mid := (a + b) * 0.5
		var segs := [[z0, z1]]
		for h: Rect2 in holes:
			if mid <= h.position.x or mid >= h.end.x:
				continue
			var out: Array = []
			for sg in segs:
				if h.end.y <= sg[0] or h.position.y >= sg[1]:
					out.append(sg)
					continue
				if h.position.y > sg[0]:
					out.append([sg[0], h.position.y])
				if h.end.y < sg[1]:
					out.append([h.end.y, sg[1]])
			segs = out
		for sg in segs:
			if sg[1] - sg[0] > 0.01:
				_slab(kt, a, sg[0], b, sg[1], y, mat)


## A deck slab whose underside is the ceiling of the deck below.
func _slab(kt: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float, mat: String) -> void:
	kt.slab(x0, z0, x1, z1, y, D.SLAB, mat, GeoKit.ALL & ~GeoKit.NY)
	kt.box_mm(Vector3(x0, y - D.SLAB, z0), Vector3(x1, y - D.SLAB + 0.02, z1), "l01_ceiling", GeoKit.NY, false)


## Glass balustrade with a steel handrail; the glass is the collision.
func _rail(kt: GeoKit, a: Vector3, b: Vector3, h: float = 1.1) -> void:
	kt.wall(a, b, h, 0.03, "l01_glass")
	var dv := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var dir := dv.normalized()
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	kt.box_xf(Transform3D(bas, (a + b) * 0.5 + Vector3.UP * h), Vector3(dv.length(), 0.06, 0.07), "l01_rail", GeoKit.ALL, false)
	kt.box_xf(Transform3D(bas, (a + b) * 0.5 + Vector3.UP * 0.06), Vector3(dv.length(), 0.12, 0.05), "l01_mullion", GeoKit.ALL, false)


## Commit a kit; transparent glass never casts shadows.
func _commit(kt: GeoKit) -> void:
	kt.commit()
	for c in kt.root.get_children():
		if c is MeshInstance3D and str(c.name).contains("glass"):
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func stair_x(f: int) -> float:
	return (D.STA + D.STW * 0.5) * (1.0 if f % 2 == 0 else -1.0)


func _deck(k: int) -> void:
	var y := D.deck_y(k)
	var e := D.edge(k) + 0.4
	var kt: GeoKit = lvl.kit("Deck%d" % k)
	var holes: Array = []
	if k >= 1:
		holes.append(Rect2(-D.ATR, D.ATZ, 2.0 * D.ATR, e - D.ATZ + 0.5))
		var sx := stair_x(k - 1)
		holes.append(Rect2(sx - D.STW * 0.5, -3.2, D.STW, D.ST_HI + 3.2))
	_slab_holes(kt, -D.GX, D.GX, D.ZW, e, y, holes, "l01_floor")
	for m in modules:
		if m["deck"] == k:
			var mat: String = {"kitchen": "l01_tile", "gym": "l01_rubber", "greenhouse": "l01_grate"}.get(m["type"], "l01_floor_dark")
			_slab(kt, m["x0"], D.ZB, m["x0"] + 10.0, D.ZW, y, mat)
	var h := D.DY - D.SLAB
	# module fronts with door openings, partitions, back wall, end bulkheads
	for m in modules:
		if m["deck"] != k:
			continue
		var x0: float = m["x0"]
		var dw := 1.3 if m["type"] == "lift" else 1.8
		var dh := 2.3 if m["type"] == "lift" else 2.5
		kt.wall(Vector3(x0, y, D.ZW), Vector3(x0 + 10.0, y, D.ZW), h, 0.2, "l01_wall", [{"at": 5.0, "w": dw, "h": dh}])
		kt.box(Vector3(x0 + 5.0, y + dh + 0.12, D.ZW + 0.11), Vector3(dw + 0.4, 0.24, 0.04), "l01_trim")
		if m["type"] != "lift":
			var dc := Vector3(x0 + 5.0, y, D.ZW)
			sys.add_door(lvl, dc, Vector3.RIGHT, dw, dh, m["door"], m)
			var ind: String = {"auto": "l01_led_green", "jammed": "l01_led_red"}.get(m["door"], "l01_led_amber")
			kt.box(Vector3(x0 + 6.35, y + 1.35, D.ZW + 0.12), Vector3(0.14, 0.22, 0.03), ind, GeoKit.ALL, false)
	for i in 7:
		var x := -D.GX + 10.0 * i
		var zf := D.ZW if (i > 0 and i < 6) else e - 0.4
		kt.wall(Vector3(x, y, D.ZB), Vector3(x, y, zf), h, 0.2, "l01_wall")
	kt.wall(Vector3(-D.GX, y, D.ZB), Vector3(D.GX, y, D.ZB), h, 0.2, "l01_wall")
	# glass line: parapet + vertical panes outside the atrium
	var gy := y + h
	for p in 24:
		var u0 := -D.GX + 2.5 * p
		var u1 := u0 + 2.5
		var in_atr := u0 >= -D.ATR - 0.01 and u1 <= D.ATR + 0.01
		var gantry := k == 2 and u0 >= 17.4 and u1 <= 22.6
		var za := D.z_edge(u0, y)
		var zb := D.z_edge(u1, y)
		if not (in_atr and k >= 1) and not gantry:
			_rail(kt, Vector3(u0, y, za - 0.08), Vector3(u1, y, zb - 0.08))
		if in_atr:
			continue
		if gantry or rng.randf() < 0.07:
			stats["broken_panes"] += 1
			_shards(u0, u1, y, za, zb, gy)
		else:
			var n := Vector3(0, 0, 1)
			glass.q(Vector3(u0, y + 1.16, za), Vector3(u1, y + 1.16, zb), Vector3(u1, gy, zb), Vector3(u0, gy, za), n, "l01_glass")
		glass.box(Vector3(u0 - 0.05, y + 1.1, za - 0.05), Vector3(u0 + 0.05, gy, za + 0.05), "l01_mullion", 63)
	# ceiling light strips and light anchors (the deck above's underside)
	var cy := y + h - 0.01
	var dead_run := rng.randi() % 24
	for zr: float in [-6.6, -3.6, -0.6, 2.2, 5.0]:
		if zr > e - 1.4:
			continue
		for p in 20:
			var x := -D.GX + 1.5 + 3.0 * p
			if k < 3 and absf(x) < D.ATR + 0.5 and zr > D.ATZ - 0.6:
				continue
			if absf(absf(x) - (D.STA + D.STW * 0.5)) < 1.6 and zr > -3.6 and zr < D.ST_HI + 0.5:
				continue
			var dead := absi(p - dead_run) < 2 and k % 2 == 1
			var fl := 1.0 if rng.randf() < 0.05 else 0.0
			kt.panel(Vector3(x, cy, zr), 2.4, 0.28, "l01_panel", 150.0 if dead else rng.randf() * 40.0, fl)
	for p in 6:
		var lx := -25.0 + 10.0 * p
		lvl.lights.add_anchor(Vector3(lx, y + 3.3, -4.0), Color(0.86, 0.92, 1.0), 1.25, 11.0, 0.0, "gal")
		if e > 4.0:
			lvl.lights.add_anchor(Vector3(lx, y + 3.3, 1.5), Color(0.86, 0.92, 1.0), 0.9, 9.0, 0.0, "gal")
	_commit(kt)


func _shards(u0: float, u1: float, y: float, za: float, zb: float, gy: float) -> void:
	# a broken pane: jagged glass left in the frame, the rest open to the cavity
	var c := (u0 + u1) * 0.5
	var z := (za + zb) * 0.5
	var n := Vector3(0, 0, 1)
	glass.q(Vector3(u0, gy - 0.6, z), Vector3(c + 0.2, gy, z), Vector3(u0, gy, z), Vector3(u0, gy, z), n, "l01_glass")
	glass.q(Vector3(u1, y + 1.1, z), Vector3(u1, y + 1.9, z), Vector3(c + 0.5, y + 1.1, z), Vector3(c + 0.5, y + 1.1, z), n, "l01_glass")


func _roof() -> void:
	var kt: GeoKit = lvl.kit("Roof")
	var y := D.deck_y(D.DECKS)
	_slab(kt, -D.GX, D.ZB, D.GX, D.edge(D.DECKS) + 0.4, y, "l01_slab_metal")
	for p in 5:
		for q in 4:
			kt.panel(Vector3(-6.0 + 3.0 * p, y - D.SLAB - 0.01, -1.5 + 2.6 * q), 2.4, 0.4, "l01_panel", rng.randf() * 40.0)
	lvl.lights.add_anchor(Vector3(0, y - 1.2, 2.0), Color(0.86, 0.92, 1.0), 1.4, 14.0, 0.0, "gal")
	_commit(kt)


func _stairs() -> void:
	var kt: GeoKit = lvl.kit("Stairs")
	var run := (D.ST_HI - D.ST_LO) / 24.0
	for f in D.DECKS - 1:
		var x := stair_x(f)
		var y := D.deck_y(f)
		kt.stairs(Vector3(x, y, D.ST_LO), Vector3.BACK, D.STW, D.DY, 24, "l01_stair", run)
		var a := Vector3(0, y, D.ST_LO)
		var b := Vector3(0, y + D.DY, D.ST_HI)
		var z := (b - a).normalized()
		var bx := Vector3.UP.cross(z).normalized()
		var bas := Basis(bx, z.cross(bx), z)
		for sx: float in [-1.0, 1.0]:
			var c := (a + b) * 0.5 + Vector3(x + sx * (D.STW * 0.5 + 0.04), 0.55, 0)
			kt.box_xf(Transform3D(bas, c), Vector3(0.03, 1.0, (b - a).length()), "l01_glass")
			kt.box_xf(Transform3D(bas, c + bas.y * 0.52), Vector3(0.07, 0.06, (b - a).length()), "l01_rail", GeoKit.ALL, false)
		# rails round the opening this flight rises through
		var yu := y + D.DY
		for sx: float in [-1.0, 1.0]:
			var rx := x + sx * (D.STW * 0.5 + 0.06)
			_rail(kt, Vector3(rx, yu, -3.2), Vector3(rx, yu, D.ST_HI))
		_rail(kt, Vector3(x - D.STW * 0.5 - 0.1, yu, -3.25), Vector3(x + D.STW * 0.5 + 0.1, yu, -3.25))
	_commit(kt)


## The atrium: a four-storey void behind slanted glass that follows the
## sphere, so its lean is the cavity's own curvature.
func _atrium() -> void:
	var kt: GeoKit = lvl.kit("Atrium")
	var top := D.deck_y(D.DECKS) - D.SLAB
	var rows := 6
	var cols := 6
	for r in rows:
		var ya := top * r / rows
		var yb := top * (r + 1) / rows
		for c in cols:
			var xa := -D.ATR + 2.0 * D.ATR * c / cols
			var xb := -D.ATR + 2.0 * D.ATR * (c + 1) / cols
			var pa := Vector3(xa, ya, D.z_edge(xa, ya))
			var pb := Vector3(xb, ya, D.z_edge(xb, ya))
			var pc := Vector3(xb, yb, D.z_edge(xb, yb))
			var pd := Vector3(xa, yb, D.z_edge(xa, yb))
			var n := (D.cc() - (pa + pc) * 0.5).normalized()
			if r == 3 and c == 4:
				stats["broken_panes"] += 1
				glass.q(pa, pb, pb.lerp(pc, 0.5), pa.lerp(pd, 0.25), n, "l01_glass")
			else:
				glass.q(pa, pb, pc, pd, n, "l01_glass")
			_strip(pa, pb, n)
			_strip(pa, pd, n)
		_strip(Vector3(D.ATR, ya, D.z_edge(D.ATR, ya)), Vector3(D.ATR, yb, D.z_edge(D.ATR, yb)), Vector3(0, 0, 1))
	# side glass closing the wedge between the slant and the stepped decks
	for k in D.DECKS:
		var y := D.deck_y(k)
		var y1 := y + D.DY - D.SLAB
		for sx: float in [-1.0, 1.0]:
			var x := sx * D.ATR
			var n := Vector3(-sx, 0, 0)
			glass.q(Vector3(x, y, D.z_edge(x, y)), Vector3(x, y1, D.z_edge(x, y)), Vector3(x, y1, D.z_edge(x, y1)), Vector3(x, y, D.z_edge(x, y)), n, "l01_glass")
	# rails round the atrium void on decks 1..3
	for k in range(1, D.DECKS):
		var y := D.deck_y(k)
		var e := D.edge(k)
		for sx: float in [-1.0, 1.0]:
			_rail(kt, Vector3(sx * (D.ATR + 0.06), y, D.ATZ), Vector3(sx * (D.ATR + 0.06), y, e - 0.1))
		_rail(kt, Vector3(-D.ATR, y, D.ATZ - 0.06), Vector3(D.ATR, y, D.ATZ - 0.06))
		kt.box(Vector3(0, y - D.SLAB * 0.5, D.ATZ - 0.02), Vector3(2.0 * D.ATR, D.SLAB, 0.04), "l01_trim", GeoKit.PZ, false)
	# a dead hydroponic tree in a planter on the atrium floor
	kt.cylinder(Vector3(0, 0.35, -0.6), 1.9, 0.7, "l01_trim", 20)
	kt.cylinder(Vector3(0, 0.71, -0.6), 1.75, 0.02, "l01_soil", 20, false)
	kt.cylinder(Vector3(0, 2.6, -0.6), 0.16, 3.8, "l01_plant_dead", 8, false)
	for b in 5:
		var a := TAU * b / 5.0 + 0.4
		var tip := Vector3(cos(a) * 1.6, 4.4 + 0.5 * sin(b * 1.7), -0.6 + sin(a) * 1.6)
		var base := Vector3(0, 3.3 + 0.25 * b, -0.6)
		var dirv := (tip - base).normalized()
		var bx := dirv.cross(Vector3.UP).normalized()
		var bas := Basis(bx, dirv, bx.cross(dirv))
		kt.box_xf(Transform3D(bas, (tip + base) * 0.5), Vector3(0.09, (tip - base).length(), 0.09), "l01_plant_dead", GeoKit.ALL, false)
	_commit(kt)


func _strip(a: Vector3, b: Vector3, n: Vector3) -> void:
	var t := (b - a).normalized()
	var s := t.cross(n).normalized() * 0.045
	var o := n * 0.02
	glass.q(a - s + o, b - s + o, b + s + o, a + s + o, n, "l01_mullion")


## Maintenance gantry: a grated walkway cantilevered out over the cavity.
func _gantry() -> void:
	var kt: GeoKit = lvl.kit("Gantry")
	var y := D.deck_y(2)
	var z0 := D.edge(2) + 0.4
	var z1 := z0 + 7.2
	kt.slab(18.0, z0, 22.0, z1, y, 0.14, "l01_grate")
	for sx: float in [18.0, 22.0]:
		_rail(kt, Vector3(sx, y, z0 - 0.4), Vector3(sx, y, z1))
	_rail(kt, Vector3(18.0, y, z1), Vector3(22.0, y, z1))
	for i in 4:
		var z := z0 + 1.0 + 2.0 * i
		var a := Vector3(18.2, y - 0.14, z)
		var b := Vector3(18.2, y - 3.6, z0 - 1.2)
		for sx: float in [0.0, 3.6]:
			var p := a + Vector3(sx, 0, 0)
			var q := b + Vector3(sx, 0, 0)
			var d := (p - q).normalized()
			var bas := Basis(Vector3.RIGHT, d, Vector3.RIGHT.cross(d)).orthonormalized()
			kt.box_xf(Transform3D(bas, (p + q) * 0.5), Vector3(0.12, (p - q).length(), 0.12), "l01_slab_metal", GeoKit.ALL, false)
	kt.box(Vector3(21.7, y + 1.4, z1 - 0.1), Vector3(0.12, 2.8, 0.12), "l01_slab_metal", GeoKit.ALL, false)
	kt.box(Vector3(21.7, y + 2.85, z1 - 0.1), Vector3(0.3, 0.12, 0.3), "l01_led_amber", GeoKit.ALL, false)
	lvl.lights.add_anchor(Vector3(21.2, y + 2.6, z1 - 0.4), Color(1.0, 0.7, 0.4), 0.9, 7.0, 0.3, "gal")
	_commit(kt)


# --------------------------------------------------------------- modules

func _module(m: Dictionary) -> void:
	var t: String = m["type"]
	if t == "sealed" or t == "lift":
		return
	var k: int = m["deck"]
	var y := D.deck_y(k)
	var x0: float = m["x0"]
	var st: String = m["state"]
	var kt: GeoKit = lvl.kit("Mod%d_%d" % [k, m["slot"]])
	var h := D.DY - D.SLAB
	var c := Vector3(x0 + 5.0, y, (D.ZB + D.ZW) * 0.5)
	m["aabb"] = AABB(Vector3(x0 + 0.1, y - 0.2, D.ZB + 0.1), Vector3(9.8, h + 0.2, D.ZW - D.ZB - 0.2))
	match t:
		"bedroom":
			for i in 3:
				var bx := x0 + 1.2 + 3.6 * i
				for lvl_y: float in [0.0, 1.45]:
					kt.box_mm(Vector3(bx - 0.55, y + lvl_y + 0.25, D.ZB + 0.1), Vector3(bx + 0.55, y + lvl_y + 0.45, D.ZB + 2.2), "l01_slab_metal")
					kt.box_mm(Vector3(bx - 0.5, y + lvl_y + 0.45, D.ZB + 0.15), Vector3(bx + 0.5, y + lvl_y + 0.62, D.ZB + 2.15), "l01_fabric")
				kt.box_mm(Vector3(bx - 0.6, y, D.ZB + 2.15), Vector3(bx - 0.52, y + 2.2, D.ZB + 2.25), "l01_slab_metal")
				kt.box_mm(Vector3(bx + 0.52, y, D.ZB + 2.15), Vector3(bx + 0.6, y + 2.2, D.ZB + 2.25), "l01_slab_metal")
			for j in 6:
				kt.box_mm(Vector3(x0 + 0.15, y, -16.5 + 0.8 * j), Vector3(x0 + 0.75, y + 2.0, -15.75 + 0.8 * j), "l01_locker")
			kt.box_mm(Vector3(x0 + 8.4, y + 0.72, -15.0), Vector3(x0 + 9.85, y + 0.78, -12.0), "l01_trim")
			kt.box_mm(Vector3(x0 + 9.75, y + 1.0, -14.6), Vector3(x0 + 9.85, y + 1.8, -12.4), "l01_screen", GeoKit.ALL, false)
		"kitchen":
			kt.box_mm(Vector3(x0 + 0.5, y, D.ZB + 0.1), Vector3(x0 + 9.5, y + 0.92, D.ZB + 0.75), "l01_trim")
			kt.box_mm(Vector3(x0 + 0.5, y + 1.5, D.ZB + 0.1), Vector3(x0 + 9.5, y + 2.3, D.ZB + 0.45), "l01_locker")
			kt.box_mm(Vector3(x0 + 2.5, y, -14.6), Vector3(x0 + 7.5, y + 0.92, -13.4), "l01_trim")
			kt.box_mm(Vector3(x0 + 4.2, y + 0.92, -14.4), Vector3(x0 + 5.8, y + 0.95, -13.6), "l01_stove", GeoKit.ALL, false)
			kt.box_mm(Vector3(x0 + 0.15, y, -12.0), Vector3(x0 + 1.0, y + 2.1, -10.8), "l01_slab_metal")
			kt.box_mm(Vector3(x0 + 9.0, y, -16.0), Vector3(x0 + 9.85, y + 0.92, -11.0), "l01_trim")
			sys.add_cook_bot(Vector3(x0 + 5.0, y + h, -14.0), st == "normal")
		"gym":
			for i in 3:
				var tx := x0 + 1.8 + 3.2 * i
				kt.box_mm(Vector3(tx - 0.42, y, D.ZB + 0.6), Vector3(tx + 0.42, y + 0.25, D.ZB + 2.6), "l01_rubber")
				kt.box_mm(Vector3(tx - 0.4, y + 0.25, D.ZB + 0.7), Vector3(tx + 0.4, y + 1.35, D.ZB + 0.8), "l01_slab_metal")
				kt.box_mm(Vector3(tx - 0.35, y + 1.2, D.ZB + 0.8), Vector3(tx + 0.35, y + 1.45, D.ZB + 1.1), "l01_screen", GeoKit.ALL, false)
			kt.box_mm(Vector3(x0 + 0.12, y + 0.2, -17.0), Vector3(x0 + 0.16, y + 2.4, -10.0), "l01_mirror", GeoKit.ALL, false)
			kt.box_mm(Vector3(x0 + 8.6, y, -16.0), Vector3(x0 + 9.7, y + 1.8, -13.0), "l01_locker")
			kt.box_mm(Vector3(x0 + 3.0, y, -13.2), Vector3(x0 + 6.4, y + 0.45, -12.8), "l01_fabric")
		"greenhouse":
			for rx: float in [x0 + 2.2, x0 + 7.8]:
				for tier in 3:
					var ty := y + 0.5 + 0.75 * tier
					kt.box_mm(Vector3(rx - 0.7, ty, -18.8), Vector3(rx + 0.7, ty + 0.12, -9.6), "l01_slab_metal")
					var dead := st != "normal"
					kt.box_mm(Vector3(rx - 0.6, ty + 0.12, -18.6), Vector3(rx + 0.6, ty + 0.12 + rng.randf_range(0.18, 0.42), -9.8), "l01_plant_dead" if dead else "l01_plant", GeoKit.ALL, false)
					kt.panel(Vector3(rx, ty + 0.72, -14.2), 1.0, 8.6, "l01_grow" if st == "normal" else "l01_panel", 150.0 if st != "normal" else rng.randf() * 30.0)
				for z: float in [-18.8, -9.6]:
					kt.box_mm(Vector3(rx - 0.72, y, z - 0.06), Vector3(rx - 0.6, y + 2.4, z + 0.06), "l01_slab_metal", GeoKit.ALL, false)
					kt.box_mm(Vector3(rx + 0.6, y, z - 0.06), Vector3(rx + 0.72, y + 2.4, z + 0.06), "l01_slab_metal", GeoKit.ALL, false)
	# ceiling panels, light and climate by damage state
	var cy := y + h - 0.01
	var dead_all := st != "normal"
	for pz: float in [-17.0, -11.5]:
		for px: float in [x0 + 2.5, x0 + 7.5]:
			var pm: String = {"cold": "l01_panel_cold", "hot": "l01_panel_hot"}.get(st, "l01_panel")
			kt.panel(Vector3(px, cy, pz), 1.2, 2.4, pm, 150.0 if st == "dark" else rng.randf() * 40.0, 1.0 if st != "normal" and rng.randf() < 0.5 else 0.0)
	match st:
		"normal":
			lvl.lights.add_anchor(c + Vector3(0, 3.1, 0), Color(0.9, 0.94, 1.0) if t != "greenhouse" else Color(1.0, 0.55, 0.9), 1.5, 10.0, 0.0, "gal")
		"cold":
			lvl.lights.add_anchor(c + Vector3(0, 3.1, 0), Color(0.5, 0.72, 1.0), 1.2, 10.0, 0.0, "gal")
			kt.box_mm(Vector3(x0 + 0.2, y + 0.005, D.ZB + 0.2), Vector3(x0 + 9.8, y + 0.02, D.ZW - 0.6), "l01_frost", GeoKit.PY, false)
			for i in 14:
				var p := Vector3(x0 + rng.randf_range(0.6, 9.4), cy, rng.randf_range(D.ZB + 0.5, D.ZW - 0.8))
				kt.box(p - Vector3(0, 0.25, 0), Vector3(0.05, rng.randf_range(0.2, 0.6), 0.05), "l01_frost", GeoKit.ALL, false)
			sys.add_climate(m["aabb"], "cold", c + Vector3(0, 1.5, 0))
		"hot":
			lvl.lights.add_anchor(c + Vector3(0, 2.4, 0), Color(1.0, 0.42, 0.16), 1.9, 10.0, 0.15, "gal")
			kt.box_mm(Vector3(x0 + 0.2, y + 0.005, D.ZB + 0.2), Vector3(x0 + 9.8, y + 0.02, D.ZW - 0.6), "l01_scorch", GeoKit.PY, false)
			for i in 3:
				kt.box(Vector3(x0 + 9.86, y + 0.6, -18.0 + 3.0 * i), Vector3(0.04, 0.5, 1.4), "l01_vent_hot", GeoKit.ALL, false)
			sys.add_climate(m["aabb"], "hot", c + Vector3(0, 1.5, 0))
		"dark":
			lvl.lights.add_anchor(c + Vector3(rng.randf_range(-3, 3), 3.0, rng.randf_range(-3, 3)), Color(0.6, 0.75, 1.0), 0.35, 5.0, 0.95, "gal")
			sys.spark(c + Vector3(rng.randf_range(-3.5, 3.5), h - 0.4, rng.randf_range(-4.0, 4.0)))
	if dead_all:
		_wires(kt, x0 + 1.0, x0 + 9.0, D.ZB + 1.0, D.ZW - 1.5, cy, 6)
	# a still-flickering wall: the sourced no-clip route ("similarly to Level 0")
	if k >= 1 and (st == "normal" or st == "dark"):
		noclip_spots.append({"pos": Vector3(x0 + 9.88, y, -10.0), "along": Vector3.BACK, "n": Vector3.LEFT, "m": m})
	_commit(kt)


func _wires(kt: GeoKit, xa: float, xb: float, za: float, zb: float, cy: float, n: int) -> void:
	for i in n:
		var p := Vector3(rng.randf_range(xa, xb), cy, rng.randf_range(za, zb))
		var l := rng.randf_range(0.7, 2.0)
		var tilt := rng.randf_range(-0.35, 0.35)
		var bas := Basis(Vector3.FORWARD, tilt) * Basis(Vector3.UP, rng.randf() * TAU)
		kt.box_xf(Transform3D(bas, p - bas.y * (l * 0.5)), Vector3(0.025, l, 0.025), "l01_wire" if i % 3 else "l01_wire_red", GeoKit.ALL, false)
		if i % 2 == 0:
			kt.box(p + Vector3(0, -0.03, 0), Vector3(0.6, 0.04, 0.6), "l01_plenum", GeoKit.NY, false)


# ------------------------------------------------------ promenade dressing

func _promenade_props(k: int) -> void:
	var y := D.deck_y(k)
	var e := D.edge(k)
	var kt: GeoKit = lvl.kit("Props%d" % k)
	for bx: float in [-25.0, -16.5, 15.0, 25.5]:
		if k == 2 and bx > 14.0 and bx < 23.0:
			continue
		kt.box_mm(Vector3(bx - 1.2, y, e - 1.6), Vector3(bx + 1.2, y + 0.45, e - 1.05), "l01_trim")
	for px: float in [-21.0, 19.5]:
		kt.box_mm(Vector3(px - 0.25, y, -7.6), Vector3(px + 0.25, y + 1.9, -7.2), "l01_slab_metal")
		kt.box_mm(Vector3(px - 0.22, y + 0.9, -7.19), Vector3(px + 0.22, y + 1.7, -7.17), "l01_screen", GeoKit.ALL, false)
	# damage: fallen ceiling panels (seeded debris), hanging wires, dead runs
	for i in 3:
		var x := rng.randf_range(-27.0, 27.0)
		if absf(absf(x) - 10.1) < 2.4 or (k > 0 and absf(x) < D.ATR + 1.0):
			continue
		var z := rng.randf_range(-7.0, minf(e - 2.0, -1.0))
		var bas := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.25, 0.25))
		kt.box_xf(Transform3D(bas, Vector3(x, y + 0.08, z)), Vector3(1.2, 0.05, 0.6), "l01_slab_metal")
		stats["debris"] += 1
	_wires(kt, -27.0, 27.0, -7.0, -1.0, y + D.DY - D.SLAB - 0.01, 3)
	if rng.randf() < 0.7 or k == 0:
		var bx := rng.randf_range(12.1, 13.3) * (1.0 if rng.randf() < 0.5 else -1.0)
		sys.add_broken_bot(Vector3(bx, y, rng.randf_range(-5.6, -4.8)), rng.randf() * TAU)
	_commit(kt)
