extends RefCounted
## Level 7.8 sea: the seabed 20 m down with a Deep Eye (a subsided hole with coral on its
## rim and fish in its semi-dark), streamed lone stilt houses and drifting boats toward the
## horizon, Seawalkers wearing houses as shells, and domesticated gulls over the roofs.

const V := preload("res://levels/L007_8/L007_8_village.gd")
const SEABED := -20.0
const EYE := Vector3(78.0, 0.0, 58.0)
const EYE_R := 38.0
const EYE_FLOOR := -175.0
const WORLD_R := 2200.0


static func seabed(L, nz: FastNoiseLite) -> void:
	var k: GeoKit = L.kit("Seabed")
	var col: Array = []
	var rings := [EYE_R, EYE_R + 6.0, EYE_R + 30.0, 160.0, 600.0, WORLD_R]
	var segs := 64
	for ri in rings.size() - 1:
		var r0: float = rings[ri]
		var r1: float = rings[ri + 1]
		for s in segs:
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			var p := [_bed(EYE, a0, r0, nz, ri == 0), _bed(EYE, a1, r0, nz, ri == 0), _bed(EYE, a1, r1, nz, false), _bed(EYE, a0, r1, nz, false)]
			var m := "l78_coral_sand" if ri <= 1 else "sand"
			V.quad(k, m, p[0], p[1], p[2], p[3], Vector3.UP)
			col.append_array([p[0], p[1], p[2], p[0], p[2], p[3]])
	# the Eye: a rough shaft from the seabed down into the dark
	var rows := 22
	var cols := 48
	var grid: Array = []
	for j in rows + 1:
		var y := lerpf(SEABED - 0.3, EYE_FLOOR, pow(float(j) / rows, 1.15))
		var row: Array = []
		for i in cols:
			var a := TAU * float(i) / cols
			var n := nz.get_noise_3d(cos(a) * 30.0, y * 0.25, sin(a) * 30.0) * clampf(float(j) / 2.0, 0.0, 1.0)
			var r := EYE_R * (1.0 + 0.09 * n)
			row.append(EYE + Vector3(cos(a) * r, y, sin(a) * r))
		grid.append(row)
	for j in rows:
		for i in cols:
			var i2 := (i + 1) % cols
			var p00: Vector3 = grid[j][i]
			var p10: Vector3 = grid[j][i2]
			var p11: Vector3 = grid[j + 1][i2]
			var p01: Vector3 = grid[j + 1][i]
			var cen := (p00 + p11) * 0.5
			V.quad(k, "l78_eye_rock" if j < 9 else "l78_abyss_rock", p00, p10, p11, p01, Vector3(EYE.x, cen.y, EYE.z) - cen)
			col.append_array([p00, p10, p11, p00, p11, p01])
	V.poly(k, "unlit_black", [EYE + Vector3(-EYE_R, EYE_FLOOR, -EYE_R), EYE + Vector3(EYE_R, EYE_FLOOR, -EYE_R), EYE + Vector3(EYE_R, EYE_FLOOR, EYE_R), EYE + Vector3(-EYE_R, EYE_FLOOR, EYE_R)], Vector3.UP)
	k.box(EYE + Vector3(0, EYE_FLOOR - 0.5, 0), Vector3(EYE_R * 2.2, 1.0, EYE_R * 2.2), "unlit_black", 0, true)
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(PackedVector3Array(col))
	sh.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.set_meta("surface", "sand")
	k.body.add_child(cs)
	k.shadows = false
	k.commit()


static func _bed(c: Vector3, a: float, r: float, nz: FastNoiseLite, lip: bool) -> Vector3:
	var p := c + Vector3(cos(a) * r, 0, sin(a) * r)
	var y := SEABED + (0.0 if r > 900.0 else 1.2 * nz.get_noise_2d(p.x * 0.05, p.z * 0.05))
	if lip:
		y -= 0.3
	return Vector3(p.x, y, p.z)


## Coral on the Eye's rim and its first ledges; fish schools in its semi-dark.
static func eye_life(L, rng: RandomNumberGenerator) -> Array:
	var k: GeoKit = L.kit("Coral")
	var mats := ["l78_coral_pink", "l78_coral_orange", "l78_coral_purple", "l78_coral_yellow"]
	for i in 150:
		var a := rng.randf() * TAU
		var r := rng.randf_range(EYE_R - 1.0, EYE_R + 14.0)
		var y := SEABED + 0.9
		if i % 4 == 0:
			r = EYE_R * rng.randf_range(0.97, 1.0)
			y = rng.randf_range(-22.0, -34.0)
		var p := EYE + Vector3(cos(a) * r, y - 0.9, sin(a) * r)
		var m: String = mats[rng.randi() % mats.size()]
		var roll := rng.randf()
		if roll < 0.6:
			for bi in rng.randi_range(4, 8):
				var dir := Vector3(rng.randf_range(-0.6, 0.6), 1.0, rng.randf_range(-0.6, 0.6)).normalized()
				var tip := p + dir * rng.randf_range(0.6, 1.8)
				V.beam(k, p, tip, 0.14, 0.14, m)
				if rng.randf() < 0.5:
					V.beam(k, tip, tip + (dir + Vector3(rng.randf_range(-0.5, 0.5), 0.3, rng.randf_range(-0.5, 0.5))).normalized() * 0.5, 0.09, 0.09, m)
		elif roll < 0.85:
			k.cylinder(p + Vector3(0, 0.55, 0), 0.12, 1.1, m, 6, false)
			k.cylinder(p + Vector3(0, 1.15, 0), rng.randf_range(0.6, 1.2), 0.12, m, 9, false)
		else:
			k.box(p + Vector3(0, 0.3, 0), Vector3(rng.randf_range(0.5, 1.2), rng.randf_range(0.3, 0.8), rng.randf_range(0.5, 1.2)), m, GeoKit.ALL, false)
	k.shadows = false
	k.commit()
	var schools: Array = []
	var fm := ["l78_fish_a", "l78_fish_b", "l78_fish_c"]
	for s in 5:
		var holder := Node3D.new()
		holder.name = "FishSchool%d" % s
		holder.position = EYE + Vector3(0, rng.randf_range(-24.0, -62.0), 0)
		L.add_child(holder)
		var fk := GeoKit.new(holder, "Fish")
		var rad := rng.randf_range(12.0, 30.0)
		var a0 := rng.randf() * TAU
		for f in 34:
			var a := a0 + rng.randf_range(0.0, 0.9)
			var p := Vector3(cos(a) * (rad + rng.randf_range(-2.0, 2.0)), rng.randf_range(-1.5, 1.5), sin(a) * (rad + rng.randf_range(-2.0, 2.0)))
			var t := Vector3(-sin(a), 0, cos(a))
			fk.box_xf(Transform3D(Basis(t.cross(Vector3.UP), Vector3.UP, t), p), Vector3(0.09, 0.22, 0.42), fm[s % 3], GeoKit.ALL, false)
		fk.shadows = false
		fk.commit()
		schools.append({"node": holder, "speed": rng.randf_range(0.04, 0.09) * (1.0 if s % 2 == 0 else -1.0)})
	return schools


## Streamed chunk: lone stilt houses, the odd drifting boat, rocks on the seabed.
static func chunk(L, cx: int, cz: int, node: Node3D, seed_base: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_base, cx, cz])
	var size: float = L.world.chunk_size
	var origin := Vector3(cx * size, 0, cz * size)
	var k := GeoKit.new(node, "Chunk")
	var meta := {"houses": 0}
	var centre := origin + Vector3(size * 0.5, 0, size * 0.5)
	var near_village := Vector2(centre.x, centre.z).length() < 120.0
	var near_eye := Vector2(centre.x - EYE.x, centre.z - EYE.z).length() < EYE_R + 90.0
	if not near_village and not near_eye:
		var n := r.randi_range(0, 2)
		if absi(cx) % 7 == 3 and absi(cz) % 5 == 2:
			n = 0
			# rarely, a row of identical houses stands side by side
			for i in 6:
				_lone_house(k, origin + Vector3(20.0 + i * 13.0, 0, size * 0.5), 9.0, 6.0, 3.2, "l78_paint_white", "rust", r, false)
			meta["houses"] = 6
		for i in n:
			var p := origin + Vector3(r.randf_range(15.0, size - 15.0), 0, r.randf_range(15.0, size - 15.0))
			var paints := ["l78_paint_blue", "l78_paint_red", "l78_paint_green", "l78_paint_white", "l78_paint_yellow"]
			_lone_house(k, p, r.randf_range(5.0, 9.0), r.randf_range(4.0, 7.0), r.randf_range(2.6, 4.5), paints[r.randi() % paints.size()],
				"rust" if r.randf() < 0.5 else "l78_roof_tar", r, r.randf() < 0.07)
			meta["houses"] = int(meta["houses"]) + 1
		if r.randf() < 0.18:
			V.boat(k, origin + Vector3(r.randf_range(10.0, size - 10.0), 0.05, r.randf_range(10.0, size - 10.0)), r.randf() * TAU, "l78_boat_paint")
	for i in r.randi_range(2, 5):
		var p := origin + Vector3(r.randf_range(0.0, size), SEABED - 0.3, r.randf_range(0.0, size))
		if Vector2(p.x - EYE.x, p.z - EYE.z).length() < EYE_R + 4.0:
			continue
		k.box(p, Vector3(r.randf_range(1.0, 4.0), r.randf_range(0.6, 2.2), r.randf_range(1.0, 4.0)), "rock", GeoKit.ALL, false)
	k.shadows = true
	k.commit()
	return meta


## Distant stilt house (no interior): stilts, deck, walls, roof. Seen from far away.
static func _lone_house(k: GeoKit, p: Vector3, w: float, d: float, deck_y: float, paint: String, roof_mat: String, r: RandomNumberGenerator, snow: bool) -> void:
	k.slab(p.x - w * 0.5 - 1.0, p.z - d * 0.5 - 1.0, p.x + w * 0.5 + 1.0, p.z + d * 0.5 + 1.0, deck_y, 0.3, "wood_floor")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cylinder(Vector3(p.x + sx * (w * 0.5 + 0.7), (deck_y + SEABED) * 0.5, p.z + sz * (d * 0.5 + 0.7)), 0.18, deck_y - SEABED, "l78_wood_stilt", 6, false)
	k.box(Vector3(p.x, deck_y + 1.3, p.z), Vector3(w, 2.6, d), paint, GeoKit.ALL, false)
	for sx in [-0.25, 0.25]:
		k.box(Vector3(p.x + sx * w, deck_y + 1.4, p.z + d * 0.5 + 0.01), Vector3(0.9, 1.0, 0.02), "unlit_black", GeoKit.PZ, false)
	V.roof(k, p.x - w * 0.5, p.z - d * 0.5, p.x + w * 0.5, p.z + d * 0.5, deck_y + 2.6, minf(w, d) * 0.3, roof_mat, paint, snow)


## A Seawalker: crab-like, four long legs, slimy grey, white empty eyes, a stilt house
## worn as a shell. Returns the root; legs are animated by the level.
static func seawalker(L, height: float, rng: RandomNumberGenerator) -> Dictionary:
	var root := Node3D.new()
	root.name = "Seawalker"
	L.add_child(root)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.33, 0.35, 0.36)
	skin.roughness = 0.18
	skin.metallic_specular = 0.8
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.95, 0.95, 0.93)
	eye.emission_enabled = true
	eye.emission = Color(0.9, 0.9, 0.88)
	eye.emission_energy_multiplier = 0.4
	var body_h := height * 0.78
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = height * 0.15
	sm.height = height * 0.17
	sm.radial_segments = 16
	sm.rings = 8
	body.mesh = sm
	body.material_override = skin
	body.scale = Vector3(1.0, 0.8, 1.7)
	body.position = Vector3(0, body_h, 0)
	root.add_child(body)
	for s in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = height * 0.012
		em.height = height * 0.024
		e.mesh = em
		e.material_override = eye
		e.position = Vector3(s * height * 0.05, body_h + height * 0.01, height * 0.245)
		root.add_child(e)
	# the shell: a whole stilt house sat on its back
	var shell := Node3D.new()
	shell.position = Vector3(0, body_h + height * 0.07, 0)
	root.add_child(shell)
	var k := GeoKit.new(shell, "ShellHouse")
	var w := height * 0.2
	var d := height * 0.16
	var paints := ["l78_paint_blue", "l78_paint_red", "l78_paint_green", "l78_paint_white"]
	var paint: String = paints[rng.randi() % paints.size()]
	k.box(Vector3(0, w * 0.32, 0), Vector3(w, w * 0.64, d), paint, GeoKit.ALL, false)
	k.box(Vector3(0, -0.2, 0), Vector3(w * 1.25, 0.4, d * 1.25), "wood_floor", GeoKit.ALL, false)
	for sx in [-0.25, 0.25]:
		k.box(Vector3(sx * w, w * 0.36, d * 0.5 + 0.02), Vector3(w * 0.14, w * 0.16, 0.05), "unlit_black", GeoKit.PZ, false)
	V.roof(k, -w * 0.5, -d * 0.5, w * 0.5, d * 0.5, w * 0.64, d * 0.4, "rust", paint, false)
	k.commit()
	var legs: Array = []
	for i in 4:
		var hip := Node3D.new()
		var fx := -1.0 if i % 2 == 0 else 1.0
		var fz := 1.0 if i < 2 else -1.0
		hip.position = Vector3(fx * height * 0.07, body_h, fz * height * 0.13)
		root.add_child(hip)
		var upper := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = height * 0.034
		cm.bottom_radius = height * 0.02
		cm.height = height * 0.55
		cm.radial_segments = 8
		upper.mesh = cm
		upper.material_override = skin
		upper.position = Vector3(0, -height * 0.27, 0)
		var thigh := Node3D.new()
		thigh.rotation = Vector3(fz * 0.25, 0, fx * 0.55)
		hip.add_child(thigh)
		thigh.add_child(upper)
		var knee := Node3D.new()
		knee.position = Vector3(0, -height * 0.54, 0)
		thigh.add_child(knee)
		var lower := MeshInstance3D.new()
		var cm2 := CylinderMesh.new()
		cm2.top_radius = height * 0.02
		cm2.bottom_radius = height * 0.006
		cm2.height = height * 0.5
		cm2.radial_segments = 8
		lower.mesh = cm2
		lower.material_override = skin
		lower.position = Vector3(0, -height * 0.25, 0)
		knee.rotation = Vector3(0, 0, -fx * 0.75)
		knee.add_child(lower)
		legs.append({"hip": thigh, "knee": knee, "fx": fx, "fz": fz, "phase": float(i) * 0.5 + (0.25 if i % 3 == 0 else 0.0)})
	return {"root": root, "legs": legs, "height": height, "body": body, "shell": shell}


## A gull: two flapping wings on a small body.
static func gull(L, mat: Material) -> Dictionary:
	var root := Node3D.new()
	root.name = "Gull"
	L.add_child(root)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.08
	bm.height = 0.42
	body.mesh = bm
	body.rotation = Vector3(PI * 0.5, 0, 0)
	body.material_override = mat
	root.add_child(body)
	var wings: Array = []
	for s in [-1.0, 1.0]:
		var pivot := Node3D.new()
		root.add_child(pivot)
		var wing := MeshInstance3D.new()
		var qm := BoxMesh.new()
		qm.size = Vector3(0.55, 0.02, 0.18)
		wing.mesh = qm
		wing.material_override = mat
		wing.position = Vector3(s * 0.3, 0, 0)
		pivot.add_child(wing)
		wings.append({"pivot": pivot, "s": s})
	return {"root": root, "wings": wings}
