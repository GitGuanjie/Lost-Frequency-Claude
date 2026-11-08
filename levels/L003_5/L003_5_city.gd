extends RefCounted
## Level 3.5 "Electropolis": the streamed brutalist city (design notes in
## L003_5.gd). 48 m chunks: a 36 m block (ground y = 0) ringed by half-streets
## (asphalt at y = -0.15). Blocks hold a brutalist tower, a slab block or an open
## plaza with transmission pylons; exoskeletal floodlight towers stand on corners.
## Every building has one open ground-floor lobby: shelter (page: "seek shelter
## inside these structures"). Chunk (0,0) is the outpost tower, built elsewhere.
## Returns strike targets, pylons, glass panels and lobby rects per chunk.

const CS := 48.0
const ST := 6.0            # half street width owned by each chunk
const SY := -0.15          # street level
const FLOOR := 4.5         # lobby / ground storey height

var lvl
var seed_v := 0


func _init(level) -> void:
	lvl = level
	seed_v = level.level_seed


func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([seed_v, a, b, salt])) % 100003) / 100003.0


func kind_of(cx: int, cz: int) -> String:
	if cx == 0 and cz == 0:
		return "outpost"
	if cx == 1 and cz == 0:
		return "plaza"
	var h := h01(cx, cz, 5)
	if h < 0.52:
		return "tower"
	if h < 0.78:
		return "slab"
	return "plaza"


func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, cx, cz, "city"])
	var ox := cx * CS
	var oz := cz * CS
	var meta := {"kind": kind_of(cx, cz), "targets": [], "pylons": [], "glass": [], "lobbies": [], "floods": []}
	var k := GeoKit.new(node, "K")
	var g := GeoKit.new(node, "Glass")
	g.shadows = false
	_ground(k, ox, oz, r)
	match meta["kind"]:
		"tower":
			_tower(k, g, node, ox, oz, r, meta)
		"slab":
			_slab(k, g, node, ox, oz, r, meta)
		"plaza":
			_plaza(k, node, ox, oz, r, meta, cx == 1 and cz == 0)
	if meta["kind"] != "outpost" and (h01(cx, cz, 9) < 0.45 or (cx == 1 and cz == 0)):
		var corner := Vector3(ox + (ST + 1.6 if r.randf() < 0.5 else CS - ST - 1.6), 0, oz + (ST + 1.6 if r.randf() < 0.5 else CS - ST - 1.6))
		if cx == 1 and cz == 0:
			corner = Vector3(ox + CS - ST - 2.0, 0, oz + ST + 2.0)
		flood_tower(k, node, corner, r.randf_range(26.0, 34.0), r, meta)
	k.commit()
	g.commit()
	return meta


## Streets, kerbs, sidewalks and the odd manhole and drain.
func _ground(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator) -> void:
	k.box_mm(Vector3(ox, SY - 0.3, oz), Vector3(ox + CS, SY, oz + CS), "asphalt")
	k.box_mm(Vector3(ox + ST, -0.4, oz + ST), Vector3(ox + CS - ST, 0.0, oz + CS - ST), "l35_pavement")
	# lane markings (faded) on the streets this chunk owns
	for t in range(0, int(CS), 6):
		k.box(Vector3(ox + t + 1.5, SY + 0.003, oz + 1.0), Vector3(2.4, 0.006, 0.14), "l35_paint", GeoKit.ALL, false)
		k.box(Vector3(ox + 1.0, SY + 0.003, oz + t + 1.5), Vector3(0.14, 0.006, 2.4), "l35_paint", GeoKit.ALL, false)
	if r.randf() < 0.5:
		Props.place(lvl, k.root, "ph/water_manhole_cover", Vector3(ox + r.randf_range(8, 40), SY, oz + 2.5), 0.0)
	# street furniture along the kerb: dead lamp posts, a barrier, a hydrant
	for n in r.randi_range(1, 3):
		var along := r.randf_range(9.0, CS - 9.0)
		var side := r.randi() % 2
		var pos := Vector3(ox + along, 0, oz + ST + 0.6) if side == 0 else Vector3(ox + ST + 0.6, 0, oz + along)
		match r.randi() % 4:
			0: Props.place(lvl, k.root, "ph/street_lamp_01", pos, 0.0 if side == 0 else 90.0, 0.0, true)
			1: Props.place(lvl, k.root, "ph/fire_hydrant", pos, r.randf() * 360.0)
			2: Props.place(lvl, k.root, "ph/concrete_road_barrier", pos + (Vector3(0, SY, -1.6) if side == 0 else Vector3(-1.6, SY, 0)), 90.0 if side == 1 else 0.0, 0.0, true)
			_: Props.place(lvl, k.root, "ph/utility_box_01", pos, 0.0 if side == 0 else 90.0, 0.0, true)


## A brutalist high-rise: podium with a lobby, a fin-ribbed shaft with dark
## window bands, a cantilevered crown, a mast on the roof.
func _tower(k: GeoKit, g: GeoKit, node: Node3D, ox: float, oz: float, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var w := r.randf_range(18.0, 28.0)
	var d := r.randf_range(18.0, 28.0)
	var c := Vector2(ox + CS * 0.5 + r.randf_range(-2.0, 2.0), oz + CS * 0.5 + r.randf_range(-2.0, 2.0))
	var hgt := snappedf(r.randf_range(38.0, 112.0), 3.6)
	var f := Rect2(c.x - w * 0.5, c.y - d * 0.5, w, d)
	var face := r.randi() % 4
	_podium(k, node, f, face, r, meta)
	var mat := "concrete" if r.randf() < 0.6 else "concrete_dark"
	k.box_mm(Vector3(f.position.x, FLOOR, f.position.y), Vector3(f.end.x, hgt, f.end.y), mat)
	_bands(k, g, f, FLOOR + 1.2, hgt - 4.0, r, meta)
	# crown: a heavier cantilevered top block
	if r.randf() < 0.6:
		var cr := f.grow(r.randf_range(0.8, 2.0))
		k.box_mm(Vector3(cr.position.x, hgt - 7.2, cr.position.y), Vector3(cr.end.x, hgt, cr.end.y), "concrete_dark")
	k.box_mm(Vector3(f.position.x - 0.2, hgt, f.position.y - 0.2), Vector3(f.end.x + 0.2, hgt + 1.1, f.end.y + 0.2), mat, GeoKit.ALL, false)
	var mast := Vector3(c.x + r.randf_range(-w, w) * 0.25, hgt, c.y + r.randf_range(-d, d) * 0.25)
	var mh := r.randf_range(6.0, 16.0)
	k.box(mast + Vector3(0, mh * 0.5, 0), Vector3(0.35, mh, 0.35), "l35_steel", GeoKit.ALL, false)
	for y in range(2, int(mh), 3):
		k.box(mast + Vector3(0, y, 0), Vector3(1.6, 0.12, 0.12), "l35_steel", GeoKit.ALL, false)
	meta["targets"].append(mast + Vector3(0, mh, 0))
	# exoskeleton: a steel lattice on one face carrying pulsing floodlights
	if r.randf() < 0.45:
		_exoskeleton(k, f, (face + 2) % 4, hgt, r, meta)


## Ground storey around an open lobby on face `face` (0 N, 1 E, 2 S, 3 W).
func _podium(k: GeoKit, node: Node3D, f: Rect2, face: int, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var lw := minf(10.0, f.size.x - 4.0) if face % 2 == 0 else minf(10.0, f.size.y - 4.0)
	var ld := 8.0
	var lob: Rect2
	match face:
		0: lob = Rect2(f.get_center().x - lw * 0.5, f.position.y, lw, ld)
		2: lob = Rect2(f.get_center().x - lw * 0.5, f.end.y - ld, lw, ld)
		1: lob = Rect2(f.end.x - ld, f.get_center().y - lw * 0.5, ld, lw)
		_: lob = Rect2(f.position.x, f.get_center().y - lw * 0.5, ld, lw)
	var t := 0.5
	# solid ground storey around the lobby
	for q in [Rect2(f.position.x, f.position.y, f.size.x, lob.position.y - f.position.y), Rect2(f.position.x, lob.end.y, f.size.x, f.end.y - lob.end.y),
			Rect2(f.position.x, lob.position.y, lob.position.x - f.position.x, lob.size.y), Rect2(lob.end.x, lob.position.y, f.end.x - lob.end.x, lob.size.y)]:
		var qr: Rect2 = q
		if qr.size.x > 0.05 and qr.size.y > 0.05:
			k.box_mm(Vector3(qr.position.x, 0.0, qr.position.y), Vector3(qr.end.x, FLOOR, qr.end.y), "concrete_dark")
	# the lobby's street wall with a wide doorway
	var a: Vector3
	var b: Vector3
	match face:
		0:
			a = Vector3(lob.position.x, 0, lob.position.y + t * 0.5)
			b = Vector3(lob.end.x, 0, lob.position.y + t * 0.5)
		2:
			a = Vector3(lob.position.x, 0, lob.end.y - t * 0.5)
			b = Vector3(lob.end.x, 0, lob.end.y - t * 0.5)
		1:
			a = Vector3(lob.end.x - t * 0.5, 0, lob.position.y)
			b = Vector3(lob.end.x - t * 0.5, 0, lob.end.y)
		_:
			a = Vector3(lob.position.x + t * 0.5, 0, lob.position.y)
			b = Vector3(lob.position.x + t * 0.5, 0, lob.end.y)
	k.wall(a, b, FLOOR, t, "concrete_dark", [{"at": (b - a).length() * 0.5, "w": 3.2, "h": 3.2}])
	k.box_mm(Vector3(lob.position.x, -0.05, lob.position.y), Vector3(lob.end.x, 0.01, lob.end.y), "l35_lobby_floor", GeoKit.PY, false)
	k.box_mm(Vector3(lob.position.x, FLOOR - 0.01, lob.position.y), Vector3(lob.end.x, FLOOR, lob.end.y), "l35_plaster", GeoKit.NY, false)
	var lc := Vector3(lob.get_center().x, 0, lob.get_center().y)
	# a dead fixture, a bench, debris; one weak emergency light
	k.box(lc + Vector3(0, FLOOR - 0.06, 0), Vector3(1.2, 0.06, 0.3), "l35_fixture", GeoKit.ALL, false)
	if r.randf() < 0.6:
		Props.place(lvl, node, "ph/concrete_road_barrier", lc + Vector3(r.randf_range(-2, 2), 0, r.randf_range(-1.5, 1.5)), r.randf() * 180.0)
	if r.randf() < 0.5:
		Props.place(lvl, node, "ph/cardboard_box_01", lc + Vector3(r.randf_range(-3, 3), 0, r.randf_range(-2, 2)), r.randf() * 360.0)
	if r.randf() < 0.5:
		Props.place(lvl, node, "ph/power_box_01", lc + Vector3(r.randf_range(-3, 3), 1.2, r.randf_range(-2, 2)), 0.0)
	lvl.lights.add_anchor(lc + Vector3(0, FLOOR - 0.6, 0), Color(0.9, 0.92, 1.0), 0.5, 7.0, 0.25, "c%d_%d" % [int(floor(f.position.x / CS)), int(floor(f.position.y / CS))])
	meta["lobbies"].append(lob)


## Dark window bands every 3.6 m (one glass strip per face per floor) and
## vertical concrete fins. Glass strips are where the Windows can appear.
func _bands(k: GeoKit, g: GeoKit, f: Rect2, y0: float, y1: float, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var y := y0
	var fins := r.randf() < 0.6
	while y < y1:
		for side in 4:
			var along_x := side % 2 == 0
			var L := f.size.x if along_x else f.size.y
			var pos: Vector3
			match side:
				0: pos = Vector3(f.get_center().x, y + 0.9, f.position.y - 0.02)
				2: pos = Vector3(f.get_center().x, y + 0.9, f.end.y + 0.02)
				1: pos = Vector3(f.end.x + 0.02, y + 0.9, f.get_center().y)
				_: pos = Vector3(f.position.x - 0.02, y + 0.9, f.get_center().y)
			g.box(pos, Vector3(L - 1.2, 1.7, 0.04) if along_x else Vector3(0.04, 1.7, L - 1.2), "l35_glass", GeoKit.ALL, false)
			if r.randf() < 0.25:
				var n := Vector3(0, 0, -1) if side == 0 else (Vector3(0, 0, 1) if side == 2 else (Vector3(1, 0, 0) if side == 1 else Vector3(-1, 0, 0)))
				var off := r.randf_range(-L * 0.4, L * 0.4)
				meta["glass"].append({"pos": pos + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off)) + n * 0.03, "n": n})
		y += 3.6
	if fins:
		for side in 4:
			var along_x2 := side % 2 == 0
			var L2 := f.size.x if along_x2 else f.size.y
			var t := 1.5
			while t < L2 - 1.0:
				var p: Vector3
				match side:
					0: p = Vector3(f.position.x + t, (y0 + y1) * 0.5, f.position.y - 0.3)
					2: p = Vector3(f.position.x + t, (y0 + y1) * 0.5, f.end.y + 0.3)
					1: p = Vector3(f.end.x + 0.3, (y0 + y1) * 0.5, f.position.y + t)
					_: p = Vector3(f.position.x - 0.3, (y0 + y1) * 0.5, f.position.y + t)
				k.box(p, Vector3(0.35, y1 - y0, 0.6) if along_x2 else Vector3(0.6, y1 - y0, 0.35), "concrete", GeoKit.ALL, false)
				t += 3.0


## Exterior steel lattice on one face, floodlights at intervals (they pulse).
func _exoskeleton(k: GeoKit, f: Rect2, side: int, hgt: float, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var along_x := side % 2 == 0
	var L := f.size.x if along_x else f.size.y
	var n := Vector3(0, 0, -1) if side == 0 else (Vector3(0, 0, 1) if side == 2 else (Vector3(1, 0, 0) if side == 1 else Vector3(-1, 0, 0)))
	var base := Vector3(f.get_center().x, 0, f.get_center().y) + n * ((f.size.y if along_x else f.size.x) * 0.5 + 1.2)
	var dir := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	for t: float in [-0.45, -0.15, 0.15, 0.45]:
		var col := base + dir * (L * float(t))
		k.box(col + Vector3(0, hgt * 0.5, 0), Vector3(0.4, hgt, 0.4), "l35_steel", GeoKit.ALL, true)
	var y := 8.0
	while y < hgt:
		k.box(base + Vector3(0, y, 0), (Vector3(L * 0.92, 0.3, 0.3) if along_x else Vector3(0.3, 0.3, L * 0.92)), "l35_steel", GeoKit.ALL, false)
		for q in 3:
			var a := base + dir * (L * (-0.45 + q * 0.3)) + Vector3(0, y, 0)
			var b := base + dir * (L * (-0.15 + q * 0.3)) + Vector3(0, y + 7.0, 0)
			_strut(k, a, b, 0.18)
		if r.randf() < 0.55:
			var fp := base + dir * (L * r.randf_range(-0.4, 0.4)) + Vector3(0, y + 0.6, 0) + n * 0.5
			_flood_head(k, fp, n, meta)
		y += 7.0


static func _strut(k: GeoKit, a: Vector3, b: Vector3, th: float) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(th, th, d.length()), "l35_steel", GeoKit.ALL, false)


func _flood_head(k: GeoKit, p: Vector3, n: Vector3, meta: Dictionary) -> void:
	k.box(p, Vector3(1.0, 0.7, 1.0), "l35_steel", GeoKit.ALL, false)
	var face := p + n * 0.51 + Vector3(0, -0.05, 0)
	var hu := Vector3(0.38, 0, 0) if absf(n.z) > 0.5 else Vector3(0, 0, 0.38)
	k.quad(face, (n + Vector3(0, -0.45, 0)).normalized(), hu, Vector3(0, 0.26, 0), "l35_flood")
	meta["floods"].append({"pos": p + n * 2.0 + Vector3(0, -1.0, 0), "head": p})


## An exoskeletal floodlight tower: four legs, bracing, a platform of lamps.
func flood_tower(k: GeoKit, node: Node3D, base: Vector3, hgt: float, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var s := 1.6
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_strut(k, base + Vector3(dx * s, 0, dz * s), base + Vector3(dx * 0.7, hgt, dz * 0.7), 0.22)
	var y := 3.0
	while y < hgt - 2.0:
		var w := lerpf(s, 0.7, y / hgt)
		for q in 4:
			var a := Vector3(-w, y, -w) if q == 0 else (Vector3(w, y, -w) if q == 1 else (Vector3(w, y, w) if q == 2 else Vector3(-w, y, w)))
			var w2 := lerpf(s, 0.7, (y + 4.0) / hgt)
			var b := Vector3(w2, y + 4.0, -w2) if q == 0 else (Vector3(w2, y + 4.0, w2) if q == 1 else (Vector3(-w2, y + 4.0, w2) if q == 2 else Vector3(-w2, y + 4.0, -w2)))
			_strut(k, base + a, base + b, 0.1)
		y += 4.0
	k.box(base + Vector3(0, hgt, 0), Vector3(3.4, 0.25, 3.4), "l35_steel", GeoKit.ALL, false)
	k.box(base + Vector3(0, 1.2, 0), Vector3(3.6, 2.4, 3.6), "l35_steel", 0, true)
	for n in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		_flood_head(k, base + Vector3(0, hgt + 0.6, 0) + n * 1.1, n, meta)
	meta["targets"].append(base + Vector3(0, hgt + 1.5, 0))
	Props.place(lvl, node, "ph/utility_box_01", base + Vector3(2.4, 0, 0.0), -90.0, 0.0, true)


## A transmission pylon (lattice, cross-arms, insulators). Returns its base.
func pylon(k: GeoKit, base: Vector3, hgt: float) -> void:
	var s := 2.2
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_strut(k, base + Vector3(dx * s, 0, dz * s), base + Vector3(dx * 0.6, hgt, dz * 0.6), 0.2)
			k.box(base + Vector3(dx * s, 0.25, dz * s), Vector3(0.7, 0.5, 0.7), "concrete", GeoKit.ALL, true)
	var y := 2.5
	while y < hgt - 1.0:
		var w := lerpf(s, 0.6, y / hgt)
		var w2 := lerpf(s, 0.6, (y + 3.5) / hgt)
		for q in 4:
			var a := Vector3(-w, y, -w) if q == 0 else (Vector3(w, y, -w) if q == 1 else (Vector3(w, y, w) if q == 2 else Vector3(-w, y, w)))
			var b := Vector3(w2, y + 3.5, -w2) if q == 0 else (Vector3(w2, y + 3.5, w2) if q == 1 else (Vector3(-w2, y + 3.5, w2) if q == 2 else Vector3(-w2, y + 3.5, -w2)))
			_strut(k, base + a, base + b, 0.09)
		y += 3.5
	for ay in [hgt - 6.0, hgt - 2.0]:
		k.box(base + Vector3(0, ay, 0), Vector3(11.0, 0.35, 0.5), "l35_steel", GeoKit.ALL, false)
		for sx: float in [-5.0, 5.0]:
			k.box(base + Vector3(sx, ay - 0.8, 0), Vector3(0.18, 1.4, 0.18), "l35_insulator", GeoKit.ALL, false)
	k.box(base + Vector3(0, hgt + 1.5, 0), Vector3(0.25, 3.0, 0.25), "l35_steel", GeoKit.ALL, false)


## A long brutalist slab block with ribbon balconies and a lobby.
func _slab(k: GeoKit, g: GeoKit, node: Node3D, ox: float, oz: float, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var along_x := r.randf() < 0.5
	var w := 32.0 if along_x else 14.0
	var d := 14.0 if along_x else 32.0
	var c := Vector2(ox + CS * 0.5, oz + CS * 0.5)
	var f := Rect2(c.x - w * 0.5, c.y - d * 0.5, w, d)
	var hgt := snappedf(r.randf_range(24.0, 48.0), 3.6)
	_podium(k, node, f, 0 if along_x else 1, r, meta)
	k.box_mm(Vector3(f.position.x, FLOOR, f.position.y), Vector3(f.end.x, hgt, f.end.y), "concrete")
	_bands(k, g, f, FLOOR + 1.2, hgt - 2.0, r, meta)
	var y := FLOOR + 3.4
	while y < hgt - 1.0:
		var rb := f.grow(1.3)
		k.box_mm(Vector3(rb.position.x, y, rb.position.y), Vector3(rb.end.x, y + 0.35, rb.end.y), "concrete_dark", GeoKit.ALL, false)
		y += 3.6
	meta["targets"].append(Vector3(f.position.x + 2.0, hgt + 0.5, f.position.y + 2.0))
	meta["targets"].append(Vector3(f.end.x - 2.0, hgt + 0.5, f.end.y - 2.0))


## Open plaza: one or two pylons (the discharge points), planters, low walls.
func _plaza(k: GeoKit, node: Node3D, ox: float, oz: float, r: RandomNumberGenerator, meta: Dictionary, anchor: bool) -> void:
	var c := Vector3(ox + CS * 0.5, 0, oz + CS * 0.5)
	var bases: Array = [c + Vector3(r.randf_range(-6, 6), 0, r.randf_range(-6, 6))]
	if anchor:
		bases = [c + Vector3(-4.0, 0, 0.0)]
	elif r.randf() < 0.5:
		bases = [c + Vector3(-9, 0, -8), c + Vector3(9, 0, 8)]
	for b in bases:
		var hh := r.randf_range(24.0, 32.0)
		pylon(k, b, hh)
		meta["pylons"].append({"base": b, "top": b + Vector3(0, hh + 3.0, 0)})
		meta["targets"].append(b + Vector3(0, hh + 3.0, 0))
	if bases.size() == 2:
		for ay: float in [-6.0, -2.0]:
			for sx: float in [-5.0, 5.0]:
				var p0: Vector3 = bases[0] + Vector3(sx, 24.0 + ay - 1.5, 0)
				var p1: Vector3 = bases[1] + Vector3(sx, 24.0 + ay - 1.5, 0)
				_strut(k, p0, p1, 0.04)
	# planters, a concrete canopy shelter, benches
	for n in r.randi_range(3, 6):
		var p := c + Vector3(r.randf_range(-15, 15), 0, r.randf_range(-15, 15))
		if Vector2(p.x - c.x, p.z - c.z).length() < 7.0 and anchor:
			continue
		k.box(p + Vector3(0, 0.45, 0), Vector3(r.randf_range(2.0, 4.0), 0.9, r.randf_range(1.2, 2.4)), "concrete_dark")
	var cp := c + Vector3(r.randf_range(-12, -8) if not anchor else 10.0, 0, r.randf_range(8, 13))
	k.box(cp + Vector3(0, 3.4, 0), Vector3(7.0, 0.4, 4.0), "concrete")
	for sx: float in [-3.0, 3.0]:
		k.box(cp + Vector3(sx, 1.6, 0), Vector3(0.5, 3.2, 0.5), "concrete")
	Props.place(lvl, node, "ph/covered_car", c + Vector3(r.randf_range(-14, 14), 0, -15.0), r.randf_range(-20, 20), 0.0, true)
	if r.randf() < 0.6:
		Props.place(lvl, node, "ph/old_tyre", c + Vector3(r.randf_range(-10, 10), 0, r.randf_range(-10, 10)), r.randf() * 360.0)
