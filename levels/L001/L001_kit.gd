extends RefCounted
## Level 1 geometry helpers (props and structures, GeoKit only). Behaviour lives
## in L001.gd. Source: "Level 1 - Habitable Zone" (Backrooms Wiki rev 83, CC BY-SA
## 3.0), dossier docs/canon/levels/L001.md. Shapes follow the page's wording:
## pillars, ceiling pipes, fluorescent fixtures, crates, purposeless corridor rooms.


## Round pipe from a to b (n-gon prism, visual only).
static func pipe(k: GeoKit, a: Vector3, b: Vector3, r: float, mat: String, sides: int = 8) -> void:
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


## Flat disc facing n (gauge faces, bottle caps).
static func disk(k: GeoKit, c: Vector3, n: Vector3, r: float, mat: String, sides: int = 12) -> void:
	var ref := Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT
	var u := n.cross(ref).normalized()
	var v := n.cross(u).normalized()
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		k._tri_fan(c, c + (u * cos(a0) + v * sin(a0)) * r, c + (u * cos(a1) + v * sin(a1)) * r, n, mat)


static func _xf(out: Vector3, c: Vector3) -> Transform3D:
	var side := Vector3.UP.cross(out).normalized()
	return Transform3D(Basis(side, Vector3.UP, out), c)


## Steel ladder bolted to a wall. foot = floor point on the wall face; out =
## horizontal unit vector from the wall into the room.
static func ladder(k: GeoKit, foot: Vector3, out: Vector3, h: float, mat: String, w: float = 0.5) -> void:
	var side := Vector3.UP.cross(out).normalized()
	var c := foot + out * 0.14
	for s in [-1.0, 1.0]:
		var rc: Vector3 = c + side * (w * 0.5 * s)
		k.box_xf(_xf(out, rc + Vector3.UP * (h * 0.5)), Vector3(0.05, h, 0.06), mat, GeoKit.ALL, false)
		for y in [0.5, h * 0.5, h - 0.4]:
			k.box_xf(_xf(out, rc + Vector3.UP * y - out * 0.08), Vector3(0.04, 0.04, 0.16), mat, GeoKit.ALL, false)
	var y := 0.3
	while y < h - 0.05:
		k.box_xf(_xf(out, c + Vector3.UP * y), Vector3(w, 0.035, 0.035), mat, GeoKit.ALL, false)
		y += 0.3


## Featureless wooden crate; open = lid pried off and dropped beside it.
static func crate(k: GeoKit, c: Vector3, s: Vector3, yaw: float, open: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	var h := s * 0.5
	if open:
		var t := 0.035
		k.box_xf(Transform3D(b, c + b * Vector3(0, -h.y + t * 0.5, 0)), Vector3(s.x, t, s.z), "l1_crate_dark")
		for sx in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * (h.x - t * 0.5), 0, 0)), Vector3(t, s.y, s.z), "l1_crate")
			k.box_xf(Transform3D(b, c + b * Vector3(0, 0, sx * (h.z - t * 0.5))), Vector3(s.x - t * 2.0, s.y, t), "l1_crate")
		var lb := Basis(Vector3.UP, yaw + 0.5)
		k.box_xf(Transform3D(lb, c + b * Vector3(h.x + h.z + 0.15, -h.y + 0.02, 0.1)), Vector3(s.x, 0.035, s.z), "l1_crate", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b * Vector3(0, -h.y + 0.12, 0)), Vector3(s.x - 0.1, 0.16, s.z - 0.1), "l1_straw", GeoKit.PY, false)
	else:
		k.box_xf(Transform3D(b, c), s, "l1_crate")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * (h.x - 0.025), 0, sz * (h.z - 0.025))), Vector3(0.07, s.y + 0.01, 0.07), "l1_crate_dark", GeoKit.ALL, false)


## Hanging fluorescent fixture: housing, emissive diffuser, two drop rods.
static func tube(k: GeoKit, c: Vector3, along_x: bool, ceil_y: float, mat: String, seed_v: float, flick: float) -> void:
	var sz := Vector3(1.5, 0.08, 0.28) if along_x else Vector3(0.28, 0.08, 1.5)
	k.box(c, sz, "l1_fixture", GeoKit.ALL ^ GeoKit.NY, false)
	k.panel(c + Vector3.DOWN * 0.042, sz.x - 0.04, sz.z - 0.04, mat, seed_v, flick)
	var off := Vector3(0.6, 0, 0) if along_x else Vector3(0, 0, 0.6)
	for s in [-1.0, 1.0]:
		var top: Vector3 = c + off * s
		k.box(Vector3(top.x, (c.y + ceil_y) * 0.5, top.z), Vector3(0.02, ceil_y - c.y, 0.02), "l1_metal", GeoKit.SIDES, false)


## Bare bulb on a cord ("a singular light bulb hanging from the ceiling").
static func bulb(k: GeoKit, c: Vector3, ceil_y: float) -> void:
	k.box(Vector3(c.x, (c.y + ceil_y) * 0.5, c.z), Vector3(0.012, ceil_y - c.y, 0.012), "l1_cord", GeoKit.SIDES, false)
	k.box(c, Vector3(0.09, 0.12, 0.09), "l1_bulb", GeoKit.ALL, false)


static func table(k: GeoKit, c: Vector3, yaw: float, w: float, d: float, h: float, mat: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, c + Vector3.UP * (h - 0.025)), Vector3(w, 0.05, d), mat)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * (w * 0.5 - 0.05), (h - 0.05) * 0.5, sz * (d * 0.5 - 0.05))), Vector3(0.05, h - 0.05, 0.05), mat, GeoKit.ALL, false)


static func chair(k: GeoKit, c: Vector3, yaw: float, sink: float = 0.0) -> void:
	var b := Basis(Vector3.UP, yaw)
	var y := 0.46 - sink
	k.box_xf(Transform3D(b, c + Vector3.UP * y), Vector3(0.46, 0.05, 0.46), "l1_wood")
	k.box_xf(Transform3D(b, c + b * Vector3(0, y + 0.42, -0.21)), Vector3(0.46, 0.5, 0.04), "l1_wood", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * 0.19, (y - 0.03) * 0.5, sz * 0.19)), Vector3(0.04, maxf(0.05, y - 0.03), 0.04), "l1_metal", GeoKit.ALL, false)


## Old office: desk, beige CRT computer and keyboard (page: "an old computer").
static func office(k: GeoKit, c: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	table(k, c, yaw, 1.4, 0.7, 0.75, "l1_wood")
	k.box_xf(Transform3D(b, c + b * Vector3(0.15, 0.97, 0.05)), Vector3(0.42, 0.38, 0.42), "l1_beige")
	k.box_xf(Transform3D(b, c + b * Vector3(0.15, 0.98, -0.165)), Vector3(0.33, 0.27, 0.01), "l1_screen", GeoKit.NZ | GeoKit.PZ, false)
	k.box_xf(Transform3D(b, c + b * Vector3(0.1, 0.77, -0.25)), Vector3(0.45, 0.03, 0.16), "l1_beige", GeoKit.ALL, false)
	chair(k, c + b * Vector3(0.1, 0, -0.75), yaw + PI)


static func bed(k: GeoKit, c: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.3), Vector3(0.95, 0.12, 2.0), "l1_metal")
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.44), Vector3(0.9, 0.16, 1.92), "l1_mattress", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + b * Vector3(0, 0.56, 0.78)), Vector3(0.55, 0.1, 0.3), "l1_mattress", GeoKit.ALL, false)
	for sz in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + b * Vector3(0, 0.5, sz * 1.0)), Vector3(0.95, 1.0 if sz > 0 else 0.7, 0.04), "l1_metal", GeoKit.ALL, false)
		for sx in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, c + b * Vector3(sx * 0.44, 0.15, sz * 0.94)), Vector3(0.04, 0.3, 0.04), "l1_metal", GeoKit.ALL, false)


## Framed painting; n = facing direction. Canvas material picks the "art".
static func painting(k: GeoKit, c: Vector3, n: Vector3, w: float, h: float, canvas: String, tilt: float = 0.0) -> void:
	var side := Vector3.UP.cross(n).normalized()
	var up := Vector3.UP.rotated(side, tilt)
	var nn := n.rotated(side, tilt)
	var bas := Basis(side, up, nn)
	k.box_xf(Transform3D(bas, c), Vector3(w, h, 0.04), "l1_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + nn * 0.022), Vector3(w - 0.12, h - 0.12, 0.01), canvas, GeoKit.PZ, false)


## Steel warehouse rack ("metal shelves") with collision as one block.
static func rack(k: GeoKit, a: Vector3, len: float, h: float, along_x: bool) -> Array:
	var d := 0.9
	var ax := Vector3.RIGHT if along_x else Vector3.BACK
	var sd := Vector3.BACK if along_x else Vector3.RIGHT
	var size := Vector3(len, h, 0.5) if along_x else Vector3(0.5, h, len)
	var c := a + ax * (len * 0.5) + Vector3.UP * (h * 0.5)
	k.box(c, size, "l1_metal", 0, true)   # slim collision core keeps shelf crates pickable
	var shelves: Array = []
	var x := 0.0
	while x <= len + 0.01:
		for s in [-1.0, 1.0]:
			k.box(a + ax * x + sd * (d * 0.5 * s) + Vector3.UP * (h * 0.5), Vector3(0.06, h, 0.06), "l1_rack", GeoKit.ALL, false)
		x += 2.0
	for y in [0.15, 1.15, 2.15]:
		k.box(a + ax * (len * 0.5) + Vector3.UP * y, Vector3(len, 0.05, d) if along_x else Vector3(d, 0.05, len), "l1_rack", GeoKit.ALL, false)
		shelves.append(y + 0.025)
	return shelves


## Wall-mounted pressure dial (pipes-and-dials gradient toward Level 2).
static func dial(k: GeoKit, c: Vector3, out: Vector3, r: float = 0.13) -> void:
	pipe(k, c - out * 0.02, c + out * 0.06, r, "l1_metal", 10)
	disk(k, c + out * 0.061, out, r * 0.86, "l1_dial", 12)
	var side := Vector3.UP.cross(out).normalized()
	k.box_xf(Transform3D(Basis(side, Vector3.UP, out).rotated(out, 0.7), c + out * 0.065), Vector3(0.012, r * 1.4, 0.006), "l1_valve", GeoKit.ALL, false)
	pipe(k, c - out * 0.02 + Vector3.DOWN * r, c - out * 0.02 + Vector3.DOWN * 0.9, 0.018, "l1_metal", 6)


## Hand wheel valve on a stub pipe.
static func valve(k: GeoKit, c: Vector3, out: Vector3) -> void:
	pipe(k, c - out * 0.2, c + out * 0.1, 0.04, "l1_pipe", 8)
	var side := Vector3.UP.cross(out).normalized()
	for i in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		pipe(k, c + out * 0.1 + (side * cos(a0) + Vector3.UP * sin(a0)) * 0.16, c + out * 0.1 + (side * cos(a1) + Vector3.UP * sin(a1)) * 0.16, 0.018, "l1_valve", 5)


## Pile of crate planks, packing material and scrap ("small piles of debris").
static func debris(k: GeoKit, c: Vector3, r: RandomNumberGenerator) -> void:
	for i in 5 + r.randi() % 5:
		var p := c + Vector3(r.randf_range(-0.9, 0.9), 0.0, r.randf_range(-0.9, 0.9))
		var m: String = ["l1_crate", "l1_crate", "l1_straw", "l1_metal"][r.randi() % 4]
		var s := Vector3(r.randf_range(0.6, 1.4), 0.03, r.randf_range(0.08, 0.16)) if m == "l1_crate" else Vector3(r.randf_range(0.2, 0.5), r.randf_range(0.05, 0.25), r.randf_range(0.2, 0.5))
		var b := Basis(Vector3.UP, r.randf() * TAU).rotated(Vector3.FORWARD, r.randf_range(-0.15, 0.15))
		k.box_xf(Transform3D(b, p + Vector3.UP * (s.y * 0.5 + 0.02 * i)), s, m, GeoKit.ALL, false)


## Room lining (brick cells, rubber rooms): thin inner skins on 4 walls with a
## gap for the door on the side facing door_z.
static func line_room(k: GeoKit, rc: Rect2, h: float, mat: String, door_x: float, door_on_min_z: bool) -> void:
	var t := 0.05
	var x0 := rc.position.x
	var z0 := rc.position.y
	var x1 := rc.end.x
	var z1 := rc.end.y
	k.box_mm(Vector3(x0, 0, z0), Vector3(x0 + t, h, z1), mat, GeoKit.PX, false)
	k.box_mm(Vector3(x1 - t, 0, z0), Vector3(x1, h, z1), mat, GeoKit.NX, false)
	var dz := z0 if door_on_min_z else z1 - t
	var oz := z1 - t if door_on_min_z else z0
	k.box_mm(Vector3(x0, 0, oz), Vector3(x1, h, oz + t), mat, GeoKit.NZ if door_on_min_z else GeoKit.PZ, false)
	var f := GeoKit.PZ if door_on_min_z else GeoKit.NZ
	k.wall(Vector3(x0, 0, dz + t * 0.5), Vector3(x1, 0, dz + t * 0.5), h, t, mat, [{"at": door_x - x0, "w": 1.0, "h": 2.15}], f)


# ------------------------------------------------- corridors ("the second zone")
const HH := 4.6       # hall ceiling (same value as L001.gd)
const CH := 2.7       # corridor ceiling


## Green EXIT sign: emissive face, "EXIT" letters and a light that survives
## Flickering ("a green exit light faintly illuminating the door below it").
static func exit_sign(lvl, k: GeoKit, p: Vector3, n: Vector3, g: String) -> void:
	k.box(p - n * 0.04, Vector3(0.72, 0.26, 0.08) if absf(n.z) > 0.5 else Vector3(0.08, 0.26, 0.72), "l1_fixture", GeoKit.ALL, false)
	k.quad(p + n * 0.002, n, Vector3(0.32, 0, 0) if absf(n.z) > 0.5 else Vector3(0, 0, 0.32), Vector3(0, 0.11, 0), "l1_exit")
	var lb := Label3D.new()
	lb.text = "EXIT"
	lb.font_size = 64
	lb.pixel_size = 0.0028
	lb.modulate = Color(0.85, 1.0, 0.88)
	lb.position = p + n * 0.012
	lb.rotation.y = atan2(n.x, n.z)
	k.root.add_child(lb)
	lvl.signs.add_anchor(p + n * 0.4 + Vector3.DOWN * 0.3, Color(0.25, 1.0, 0.45), 0.9, 5.5, 0.0, g)


## Pushable double doors, propped open inward.
static func door_leaves(k: GeoKit, dx: float, z: float) -> void:
	for s in [-1.0, 1.0]:
		var hinge := Vector3(dx + 0.95 * s, 0.0, z)
		var dir := Vector3(-s * cos(1.33), 0.0, sin(1.33))
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		k.box_xf(Transform3D(bas, hinge + dir * 0.47 + Vector3.UP * 1.1), Vector3(0.92, 2.2, 0.05), "l1_door")
		k.box_xf(Transform3D(bas, hinge + dir * 0.55 + Vector3.UP * 1.0 + bas.z * 0.05), Vector3(0.7, 0.05, 0.05), "l1_metal", GeoKit.ALL, false)


static func segments(xa: float, xb: float, r: RandomNumberGenerator, stub: bool) -> Array:
	var kinds := ["office", "brick", "infirmary", "rubber", "paintings", "mattress", "empty", "dark", "dark"]
	var out: Array = []
	var x := xa
	while x < xb - 0.01:
		var w := r.randf_range(3.4, 5.0)
		if xb - (x + w) < 2.6:
			w = xb - x
		out.append([x, x + w, kinds[r.randi() % kinds.size()]])
		x += w
	if stub:
		var i := (1 + r.randi() % (out.size() - 2)) if out.size() > 2 else 0
		var a: float = out[i][0]
		var b: float = out[i][1]
		if b - a >= 4.4:
			out[i] = [a + 1.9, b, out[i][2]]
			out.insert(i, [a, a + 1.9, "stub"])
		else:
			out[i] = [a, b, "stub"]
	return out


## Corridor block: hall-facing outer skin, white painted-block inner skin, a spine
## corridor with purposeless rooms either side and a door stub to the halls.
static func corridor_block(lvl, k: GeoKit, node: Node3D, rc: Rect2, r: RandomNumberGenerator, g: String, meta: Dictionary, authored: bool) -> void:
	var x0 := rc.position.x
	var z0 := rc.position.y
	var x1 := rc.end.x
	var z1 := rc.end.y
	var t := 0.3
	var zs := (z0 + z1) * 0.5
	var sn := zs - 0.9
	var ss := zs + 0.9
	meta["blocks"].append(rc)
	k.slab(x0, z0, x1, z1, 0.0, 0.4, "l1_corr_floor", GeoKit.PY)
	k.slab(x0, z0, x1, z1, CH + 0.2, 0.2, "l1_corr_ceiling", GeoKit.NY)
	var north: Array = [[0.15, 4.5, "office"], [4.5, 9.0, "brick"], [9.0, 14.2, "base"], [14.2, 19.05, "infirmary"], [19.05, 20.95, "stub"], [20.95, 26.0, "rubber"], [26.0, 31.85, "paintings"]]
	var south: Array = [[0.15, 5.2, "dark"], [5.2, 10.6, "mattress"], [10.6, 16.0, "office"], [16.0, 21.4, "empty"], [21.4, 26.8, "dark"], [26.8, 31.85, "brick"]]
	if not authored:
		north = segments(x0 + 0.15, x1 - 0.15, r, true)
		south = segments(x0 + 0.15, x1 - 0.15, r, false)
	var nops: Array = []
	var spn: Array = []
	for s in north:
		var a: float = s[0]
		var b: float = s[1]
		var mid := (a + b) * 0.5
		if s[2] == "stub":
			nops.append({"at": mid - x0, "w": 1.9, "h": 2.25})
			spn.append({"at": mid - x0, "w": b - a - 0.1, "h": CH + 0.5})
			exit_sign(lvl, k, Vector3(mid, 2.55, z0 - 0.02), Vector3(0, 0, -1), g)
			door_leaves(k, mid, z0 + t)
			if authored:
				lvl.sys.floor_painting(node, Vector3(mid + 0.3, 0.0, z0 + t + 1.25))
			meta["lm"].append(Vector3(mid, 2.5, z0))
			bulb(k, Vector3(mid, CH - 0.5, z0 + 3.0), CH)
			lvl.lights.add_anchor(Vector3(mid, CH - 0.6, z0 + 3.0), Color(1.0, 0.8, 0.55), 0.8, 4.5, 0.1, g)
		elif s[2] == "base":
			nops.append({"at": mid - x0, "w": 1.9, "h": 2.25})
		else:
			var dx := r.randf_range(a + 0.9, b - 0.9)
			spn.append({"at": dx - x0, "w": 0.95, "h": 2.1})
			room(lvl, k, Rect2(a, z0 + t, b - a, sn - 0.15 - z0 - t), s[2], dx, false, r, g, meta)
		if b < x1 - 0.2:
			k.wall(Vector3(b, 0, z0 + t), Vector3(b, 0, sn - 0.15), CH, 0.15, "l1_corr_wall", [], GeoKit.ALL)
	var sps: Array = []
	for s in south:
		var a: float = s[0]
		var b: float = s[1]
		var dx := r.randf_range(a + 0.9, b - 0.9)
		sps.append({"at": dx - x0, "w": 0.95, "h": 2.1})
		room(lvl, k, Rect2(a, ss + 0.15, b - a, z1 - t - ss - 0.15), s[2], dx, true, r, g, meta)
		if b < x1 - 0.2:
			k.wall(Vector3(b, 0, ss + 0.15), Vector3(b, 0, z1 - t), CH, 0.15, "l1_corr_wall", [], GeoKit.ALL)
	var wops: Array = [{"at": zs - z0, "w": 0.9, "h": 1.15}] if authored else []
	for pr in [[Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(0, 0, 1), nops], [Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, -1), []],
			[Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3(1, 0, 0), wops], [Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(-1, 0, 0), []]]:
		var inw: Vector3 = pr[2]
		k.wall(pr[0] + inw * t * 0.25, pr[1] + inw * t * 0.25, HH, t * 0.5, "l1_wall", pr[3], GeoKit.SIDES)
		k.wall(pr[0] + inw * t * 0.75, pr[1] + inw * t * 0.75, CH, t * 0.5, "l1_corr_wall", pr[3], GeoKit.SIDES)
	k.wall(Vector3(x0, 0, sn - 0.075), Vector3(x1, 0, sn - 0.075), CH, 0.15, "l1_corr_wall", spn, GeoKit.ALL)
	k.wall(Vector3(x0, 0, ss + 0.075), Vector3(x1, 0, ss + 0.075), CH, 0.15, "l1_corr_wall", sps, GeoKit.ALL)
	var x := x0 + 2.5
	while x < x1 - 1.0:
		bulb(k, Vector3(x, CH - 0.45, zs), CH)
		lvl.lights.add_anchor(Vector3(x, CH - 0.55, zs), Color(1.0, 0.82, 0.58), 0.75, 5.0, 0.12 if r.randf() < 0.3 else 0.0, g)
		x += 6.0
	if authored:
		base_alpha(lvl, k, node, z0, g, meta)


## Purposeless rooms (page list): office with an old computer under a hanging
## bulb, brick cell, infirmary bed, rubber room with a chair (sometimes clipped
## into the floor), paintings on walls and floor; plus mattresses and dark rooms.
static func room(lvl, k: GeoKit, rc: Rect2, kind: String, dx: float, door_min_z: bool, r: RandomNumberGenerator, g: String, meta: Dictionary) -> void:
	meta["rooms"].append(rc)
	var c := Vector3(rc.get_center().x, 0.0, rc.get_center().y)
	var back := Vector3(0, 0, 1) if door_min_z else Vector3(0, 0, -1)
	var far_z := rc.end.y - 0.55 if door_min_z else rc.position.y + 0.55
	if kind not in ["dark", "mattress"]:
		bulb(k, c + Vector3.UP * (CH - 0.55), CH)
		lvl.lights.add_anchor(c + Vector3.UP * (CH - 0.65), Color(1.0, 0.8, 0.52) if kind != "infirmary" else Color(0.9, 0.95, 1.0), 1.0, 5.0, 0.15 if r.randf() < 0.25 else 0.0, g)
	match kind:
		"office":
			office(k, Vector3(c.x, 0, far_z), PI if not door_min_z else 0.0)
		"brick":
			line_room(k, rc, CH, "l1_brick", dx, door_min_z)
		"infirmary":
			bed(k, c, PI * 0.5 if rc.size.x > rc.size.y else 0.0)
			table(k, Vector3(rc.position.x + 0.5, 0, c.z), 0.0, 0.6, 0.6, 0.8, "l1_metal")
			table(k, Vector3(rc.end.x - 0.5, 0, c.z), 0.0, 0.6, 0.6, 0.8, "l1_metal")
		"rubber":
			line_room(k, rc, CH, "l1_plush_rubber", dx, door_min_z)
			k.box_mm(Vector3(rc.position.x + 0.05, 0.0, rc.position.y + 0.05), Vector3(rc.end.x - 0.05, 0.03, rc.end.y - 0.05), "l1_plush_rubber", GeoKit.PY, false)
			chair(k, c, r.randf() * TAU, 0.2 if r.randf() < 0.5 else 0.0)
		"paintings":
			var mats := ["l1_canvas_a", "l1_canvas_b", "l1_canvas_c"]
			painting(k, Vector3(rc.position.x + 0.07, 1.55, c.z), Vector3.RIGHT, 1.0, 0.8, mats[r.randi() % 3])
			painting(k, Vector3(rc.end.x - 0.07, 1.5, c.z), Vector3.LEFT, 0.8, 1.0, mats[r.randi() % 3])
			painting(k, Vector3(c.x, 1.6, far_z + back.z * 0.47), -back, 1.4, 0.9, mats[r.randi() % 3])
			for i in 2:
				var p := Vector3(rc.position.x + r.randf_range(0.8, rc.size.x - 0.8), 0.02, rc.position.y + r.randf_range(0.8, rc.size.y - 0.8))
				k.box(p, Vector3(0.9, 0.04, 0.7), "l1_frame", GeoKit.ALL, false)
				k.box(p + Vector3.UP * 0.021, Vector3(0.78, 0.005, 0.58), mats[r.randi() % 3], GeoKit.PY, false)
		"mattress":
			for i in 2 + r.randi() % 2:
				var p := Vector3(rc.position.x + r.randf_range(0.8, rc.size.x - 0.8), 0.09, rc.position.y + r.randf_range(1.0, rc.size.y - 1.0))
				k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI), p), Vector3(0.9, 0.18, 1.9), "l1_mattress", GeoKit.ALL, false)


## M.E.G. Base Alpha's north exit (barred: the base is a separate article and no
## NPCs are spawned) and the group's landmark: a lime cloth with a logo, Almond
## Water and a note. Taking the water drops the cloth to the floor, as asked.
static func base_alpha(lvl, k: GeoKit, node: Node3D, z0: float, g: String, meta: Dictionary) -> void:
	var dx := 11.5
	for s in [-1.0, 1.0]:
		k.box(Vector3(dx + 0.475 * s, 1.125, z0 + 0.15), Vector3(0.94, 2.25, 0.08), "l1_door")
		k.box(Vector3(dx + 0.45 * s, 1.05, z0 + 0.09), Vector3(0.7, 0.06, 0.05), "l1_metal", GeoKit.ALL, false)
	exit_sign(lvl, k, Vector3(dx, 2.55, z0 - 0.02), Vector3(0, 0, -1), g)
	_label(k.root, "M.E.G.\nBASE ALPHA  —  N", 40, 0.0035, Color(0.78, 0.9, 0.2), Vector3(dx, 1.62, z0 + 0.1))
	lvl.add_interactable(Vector3(dx, 1.1, z0 + 0.05), Vector3(1.9, 2.2, 0.2), "Push the double doors",
		func(_p): Overlay.toast("Barred from the inside. The stencilled eagle and \"M.E.G.\" are fresh paint.", 4.0))
	meta["lm"].append(Vector3(dx, 2.5, z0))
	var taken: bool = SaveService.flag("L001", "meg_landmark_taken", false)
	var cloth := Node3D.new()
	node.add_child(cloth)
	var cw := GeoKit.new(cloth, "Cloth")
	cw.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.04), Vector3(13.85, 1.75, z0 - 0.02)), Vector3(1.1, 1.3, 0.02), "l1_meg", GeoKit.ALL, false)
	cw.commit()
	_label(cloth, "M.E.G.", 56, 0.004, Color(0.08, 0.1, 0.05), Vector3(13.85, 1.85, z0 - 0.035))
	var down := Node3D.new()
	node.add_child(down)
	var cf := GeoKit.new(down, "ClothDown")
	cf.box_xf(Transform3D(Basis(Vector3.UP, 0.4), Vector3(13.6, 0.01, z0 - 0.7)), Vector3(1.1, 0.012, 1.0), "l1_meg", GeoKit.PY, false)
	cf.commit()
	var bottle := Node3D.new()
	node.add_child(bottle)
	var bk := GeoKit.new(bottle, "Bottle")
	bk.cylinder(Vector3(14.2, 0.14, z0 - 0.25), 0.045, 0.28, "glass", 10, false)
	bk.cylinder(Vector3(14.2, 0.30, z0 - 0.25), 0.02, 0.05, "l1_metal", 8, false)
	bk.commit()
	cloth.visible = not taken
	down.visible = taken
	bottle.visible = not taken
	meta["lm"].append(Vector3(13.85, 1.75, z0))
	if not taken:
		var it: Interactable = lvl.add_interactable(Vector3(14.2, 0.2, z0 - 0.25), Vector3(0.3, 0.4, 0.3), "Take the Almond Water", Callable())
		it.once = true
		it.action = func(_p):
			bottle.visible = false
			cloth.visible = false
			down.visible = true
			SaveService.add_item("almond_water")
			SaveService.set_flag("L001", "meg_landmark_taken", true)
			lvl.player.heal(30.0)
			Overlay.toast("Almond Water: sweet, nutty, oddly restoring. As the note asks, you pull the cloth down and leave it on the floor.", 5.0)
	lvl.add_note("L001_meg_landmark", "Note tied to a lime-yellow cloth",
		"To whoever just fell through from the yellow rooms: you made it out. Cloths like this mark supplies left by the Major Explorer Group. Take the water. If you do, pull the cloth down and leave it on the floor so the next patrol knows to restock it.\n\nThe halls lie about distance. Pick a landmark (a crate, a painted pillar, an electrical panel, a table) and walk to it without looking away. If it never seems to get closer, it is farther than it looks: pick another.\n\nWhen every light goes out, do not switch on a torch in the halls. Find a green EXIT light, keep a hand on the wall and walk, don't run, to its door. The corridors behind those doors do not shift, and things rarely wander there.\n\n— Team Compass Point, M.E.G.",
		Vector3(14.55, 0.9, z0 - 0.05), Vector3(0.3, 0.4, 0.15))


static func _label(parent: Node, text: String, size: int, px: float, col: Color, pos: Vector3) -> void:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = size
	lb.pixel_size = px
	lb.modulate = col
	lb.position = pos
	lb.rotation.y = PI
	parent.add_child(lb)
