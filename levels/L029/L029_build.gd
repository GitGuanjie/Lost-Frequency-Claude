extends RefCounted
## Level 29 building kit: red-wood architecture (SOURCE: buildings "made mainly
## out of wood" from the native tree, fire-proof and very sturdy), shared by the
## dockyard, the watchtowers, Hyperia and the farm huts.
## - solid(): a closed building (one collision box) with timber frame, window
##   frames and panes, shutters, a door, gable roof and chimney;
## - room(): an enterable one-storey room (walls with openings, floor, roof);
## - stair_to(): a straight stair that lands exactly on a deck edge;
## - boat(): a procedural clinker hull (rowing boat or sloop with mast).

var lvl: Node3D
var ter
var k: GeoKit
var chimneys: Array = []
var doors: Array = []


func _init(level: Node3D, terrain, kit: GeoKit) -> void:
	lvl = level
	ter = terrain
	k = kit


static func materials() -> void:
	_tex("l29_plank", "old_wood_floor", Color(0.98, 0.52, 0.42), 2.2)
	_tex("l29_deck_wood", "old_wood_floor", Color(0.80, 0.55, 0.45), 2.0)
	MatLib.define("l29_timber", {"albedo_a": Color(0.20, 0.045, 0.03), "albedo_b": Color(0.14, 0.03, 0.02), "pattern": 2,
		"pattern_scale": Vector2(0.07, 1.0), "pattern_color": Color(0.09, 0.02, 0.012), "pattern_strength": 0.5,
		"noise_scale": 2.0, "bump_strength": 1.2, "roughness_a": 0.8, "roughness_b": 0.95}, "wood_floor")
	MatLib.define("l29_roof", {"albedo_a": Color(0.16, 0.13, 0.13), "albedo_b": Color(0.11, 0.09, 0.09), "pattern": 14,
		"pattern_scale": Vector2(0.42, 0.22), "grout_width": 0.03, "grout_color": Color(0.05, 0.04, 0.04),
		"tile_variation": 0.18, "noise_scale": 1.0, "bump_strength": 1.4, "roughness_a": 0.75, "roughness_b": 0.9}, "rock")
	MatLib.define("l29_stone", {"albedo_a": Color(0.34, 0.30, 0.30), "albedo_b": Color(0.24, 0.21, 0.21), "pattern": 4,
		"pattern_scale": Vector2(0.7, 0.35), "grout_width": 0.03, "grout_color": Color(0.16, 0.15, 0.14),
		"noise_scale": 1.2, "bump_strength": 1.5}, "rock")
	MatLib.define("l29_pane", {"albedo_a": Color(0.035, 0.035, 0.045), "albedo_b": Color(0.05, 0.05, 0.06),
		"roughness_a": 0.08, "roughness_b": 0.15, "metallic_value": 0.3, "noise_scale": 0.5, "bump_strength": 0.0}, "concrete")
	MatLib.define("l29_whitewash", {"albedo_a": Color(0.78, 0.74, 0.70), "albedo_b": Color(0.70, 0.66, 0.62),
		"noise_scale": 1.3, "stain_amount": 0.3, "stain_color": Color(0.55, 0.45, 0.4)}, "plaster")
	MatLib.define("l29_rope", {"albedo_a": Color(0.55, 0.47, 0.33), "albedo_b": Color(0.45, 0.38, 0.26), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "noise_scale": 4.0}, "dirt")
	MatLib.define("l29_iron", {"albedo_a": Color(0.18, 0.16, 0.15), "albedo_b": Color(0.28, 0.17, 0.10),
		"metallic_value": 0.6, "roughness_a": 0.5, "roughness_b": 0.85, "noise_scale": 3.0, "stain_amount": 0.4,
		"stain_color": Color(0.35, 0.16, 0.07)}, "rust")
	MatLib.define("l29_copper", {"albedo_a": Color(0.20, 0.36, 0.28), "albedo_b": Color(0.42, 0.24, 0.12),
		"metallic_value": 0.5, "roughness_a": 0.5, "roughness_b": 0.8, "noise_scale": 5.0, "bump_strength": 1.5}, "rock")
	MatLib.define("l29_bark", {"albedo_a": Color(0.42, 0.075, 0.05), "albedo_b": Color(0.30, 0.05, 0.035), "pattern": 2,
		"pattern_scale": Vector2(0.09, 1.0), "pattern_color": Color(0.17, 0.03, 0.02), "pattern_strength": 0.65,
		"noise_scale": 1.6, "bump_strength": 1.6, "roughness_a": 0.85, "roughness_b": 1.0}, "concrete")
	MatLib.define("l29_sacking", {"albedo_a": Color(0.52, 0.45, 0.33), "albedo_b": Color(0.44, 0.37, 0.27), "pattern": 6,
		"noise_scale": 3.0, "roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 0.8}, "dirt")
	var cloth := ["l29_cloth_a", Color(0.62, 0.10, 0.10), "l29_cloth_b", Color(0.80, 0.62, 0.20), "l29_cloth_c", Color(0.18, 0.32, 0.55), "l29_cloth_d", Color(0.85, 0.82, 0.74)]
	for i in range(0, cloth.size(), 2):
		var c: Color = cloth[i + 1]
		MatLib.define(cloth[i], {"albedo_a": c, "albedo_b": c * 0.85, "pattern": 2, "pattern_scale": Vector2(0.5, 1.0),
			"pattern_color": c * 0.7, "pattern_strength": 0.4, "noise_scale": 2.0, "roughness_a": 0.95, "roughness_b": 1.0}, "plaster")
	var hull := StandardMaterial3D.new()
	var p := "res://assets/external/old_wood_floor/old_wood_floor_diff_1k.jpg"
	if ResourceLoader.exists(p):
		hull.albedo_texture = load(p)
	hull.albedo_color = Color(0.9, 0.5, 0.42)
	hull.uv1_scale = Vector3(0.5, 0.5, 1.0)
	hull.cull_mode = BaseMaterial3D.CULL_DISABLED
	hull.roughness = 0.8
	MatLib.register("l29_hull", hull)
	var sail := StandardMaterial3D.new()
	sail.albedo_color = Color(0.82, 0.78, 0.68)
	sail.cull_mode = BaseMaterial3D.CULL_DISABLED
	sail.roughness = 1.0
	MatLib.register("l29_sail", sail)


static func _tex(name: String, asset: String, tint: Color, rep: float) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint * 0.5, "albedo_b": tint * 0.4}, "wood_floor")
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	m.roughness = 0.85
	var r := 1.0 / rep
	m.uv1_scale = Vector3(r, r, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	MatLib.register(name, m)


# ------------------------------------------------------------ cheap goods

## Bulk goods as kit geometry (a few dozen triangles each) instead of 7-8k
## triangle scanned props; scanned props stay for close-up detail only.
const CHEAP := ["ph/wooden_crate_01", "ph/Barrel_01", "ph/barrel_03", "ph/old_military_crate", "ph/cardboard_box_01", "ph/plastic_crate_01"]


func prop(parent: Node3D, id: String, pos: Vector3, yaw: float = 0.0, height: float = 0.0, collide: bool = false) -> void:
	if not id in CHEAP:
		Props.place(lvl, parent, id, pos, yaw, height, collide)
		return
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	match id:
		"ph/Barrel_01", "ph/barrel_03":
			var r := 0.3 if id == "ph/Barrel_01" else 0.33
			var h := 0.9
			k.cylinder(pos + Vector3(0, h * 0.5, 0), r, h, "l29_deck_wood", 10, collide, true)
			for y in [0.15, 0.75]:
				k.cylinder(pos + Vector3(0, y, 0), r + 0.015, 0.06, "l29_iron", 10, false, false)
		"ph/old_military_crate":
			k.box_xf(Transform3D(b, pos + Vector3(0, 0.25, 0)), Vector3(1.6, 0.5, 0.8), "l29_plank", GeoKit.ALL, collide)
			k.box_xf(Transform3D(b, pos + Vector3(0, 0.52, 0)), Vector3(1.64, 0.05, 0.84), "l29_timber", GeoKit.ALL, false)
		_:
			var sz := Vector3(0.8, 0.6, 0.6) if id == "ph/wooden_crate_01" else Vector3(0.5, 0.4, 0.4)
			var mat := "l29_plank" if id == "ph/wooden_crate_01" else "l29_sacking"
			k.box_xf(Transform3D(b, pos + Vector3(0, sz.y * 0.5, 0)), sz, mat, GeoKit.ALL, collide)
			if id == "ph/wooden_crate_01":
				for sx in [-0.5, 0.5]:
					k.box_xf(Transform3D(b, pos + b * Vector3(sz.x * sx, sz.y * 0.5, 0)), Vector3(0.06, sz.y + 0.02, sz.z + 0.02), "l29_timber", GeoKit.ALL, false)


# ------------------------------------------------------------ helpers

func ground_span(o: Vector3, b: Basis, w: float, d: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for sx in [-0.5, 0.0, 0.5]:
		for sz in [-0.5, 0.0, 0.5]:
			var p: Vector3 = o + b * Vector3(w * sx, 0, d * sz)
			var y: float = ter.h(p.x, p.z)
			lo = minf(lo, y)
			hi = maxf(hi, y)
	return Vector2(lo, hi)


func _bx(o: Vector3, b: Basis, local: Vector3, size: Vector3, mat: String, collide: bool = false) -> void:
	k.box_xf(Transform3D(b, o + b * local), size, mat, GeoKit.ALL, collide)


## Gable roof along local x over a w x d footprint whose eaves are at y_e.
func roof(o: Vector3, b: Basis, w: float, d: float, y_e: float, pitch_h: float, wall_mat: String) -> void:
	var ov := 0.55
	var half := d * 0.5 + ov
	var ang := atan2(pitch_h, d * 0.5)
	var slope_len := half / cos(ang)
	for s in [-1.0, 1.0]:
		var c := Vector3(0, y_e + pitch_h * 0.5 - ov * tan(ang) * 0.5 + 0.08, s * half * 0.5)
		var rb := b * Basis(Vector3.RIGHT, s * ang)
		k.box_xf(Transform3D(rb, o + b * c), Vector3(w + ov * 2.0, 0.14, slope_len), "l29_roof", GeoKit.ALL, false)
	# ridge beam and gable ends
	_bx(o, b, Vector3(0, y_e + pitch_h + 0.05, 0), Vector3(w + ov * 2.0, 0.18, 0.22), "l29_timber")
	for sx in [-1.0, 1.0]:
		var x: float = sx * w * 0.5
		var a: Vector3 = o + b * Vector3(x, y_e, -d * 0.5)
		var c2: Vector3 = o + b * Vector3(x, y_e, d * 0.5)
		var t: Vector3 = o + b * Vector3(x, y_e + pitch_h, 0)
		k._tri_fan(t, a, c2, b * Vector3(sx, 0, 0), wall_mat)


## A closed timber building. front = local +z. Returns its door point (ground).
func solid(o: Vector3, yaw: float, w: float, d: float, storeys: int, opts: Dictionary = {}) -> Vector3:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var gs := ground_span(o, b, w, d)
	var fy := gs.y + 0.25
	var sh := 3.0
	var top := fy + sh * storeys
	var wall_mat: String = opts.get("wall", "l29_plank")
	# stone plinth down into the slope, then the timber body (one collision box)
	_bx(Vector3(o.x, 0, o.z), b, Vector3(0, (fy + gs.x - 0.8) * 0.5, 0), Vector3(w + 0.3, fy - gs.x + 0.8, d + 0.3), "l29_stone", true)
	_bx(Vector3(o.x, 0, o.z), b, Vector3(0, (fy + top) * 0.5, 0), Vector3(w, top - fy, d), wall_mat, true)
	var oo := Vector3(o.x, 0, o.z)
	# corner posts, storey beams
	for sx in [-0.5, 0.5]:
		for sz in [-0.5, 0.5]:
			_bx(oo, b, Vector3(w * sx, (fy + top) * 0.5, d * sz), Vector3(0.26, top - fy + 0.1, 0.26), "l29_timber")
	for s in storeys + 1:
		var y := fy + s * sh + (0.0 if s < storeys else -0.1)
		_bx(oo, b, Vector3(0, y, d * 0.5 + 0.06), Vector3(w + 0.1, 0.2, 0.14), "l29_timber")
		_bx(oo, b, Vector3(0, y, -d * 0.5 - 0.06), Vector3(w + 0.1, 0.2, 0.14), "l29_timber")
		_bx(oo, b, Vector3(w * 0.5 + 0.06, y, 0), Vector3(0.14, 0.2, d + 0.1), "l29_timber")
		_bx(oo, b, Vector3(-w * 0.5 - 0.06, y, 0), Vector3(0.14, 0.2, d + 0.1), "l29_timber")
	# windows on all four sides, door on the front
	var door_x: float = opts.get("door_x", 0.0)
	for s in storeys:
		var wy := fy + s * sh + 1.55
		for side in 4:
			var along := w if side < 2 else d
			var n := maxi(1, int(along / 2.6))
			for i in n:
				var u := (float(i) + 0.5) / n * along - along * 0.5
				if side == 0 and s == 0 and absf(u - door_x) < 1.2:
					continue
				_window(oo, b, side, w, d, u, wy)
	var dp: Vector3 = oo + b * Vector3(door_x, 0, d * 0.5)
	_bx(oo, b, Vector3(door_x, fy + 1.05, d * 0.5 + 0.04), Vector3(1.05, 2.1, 0.08), "l29_timber")
	_bx(oo, b, Vector3(door_x, fy + 1.1, d * 0.5 + 0.07), Vector3(1.3, 2.3, 0.04), "l29_deck_wood")
	_bx(oo, b, Vector3(door_x, fy + 1.05, d * 0.5 + 0.1), Vector3(0.95, 2.0, 0.04), "l29_timber")
	var gy: float = ter.h(dp.x, dp.z)
	if fy - gy > 0.22:
		var n := maxi(1, int(ceil((fy - gy) / 0.18)))
		k.stairs(oo + b * Vector3(door_x, 0, d * 0.5 + 0.15 + n * 0.3) + Vector3(0, fy - n * 0.18 + 0.0, 0) * 0.0 + Vector3(0, gy, 0), b * Vector3(0, 0, -1), 1.6, fy - gy, n, "l29_stone", 0.3)
	doors.append(dp)
	var pitch: float = opts.get("pitch", d * 0.36)
	roof(oo, b, w, d, top, pitch, wall_mat)
	if opts.get("chimney", true):
		var cx := w * 0.3 * (1.0 if int(o.x * 7.0) % 2 == 0 else -1.0)
		_bx(oo, b, Vector3(cx, top + pitch * 0.75, -d * 0.15), Vector3(0.7, pitch * 1.3 + 0.8, 0.7), "l29_stone")
		chimneys.append(oo + b * Vector3(cx, top + pitch * 1.45 + 0.4, -d * 0.15))
	return dp


func _window(oo: Vector3, b: Basis, side: int, w: float, d: float, u: float, wy: float) -> void:
	var nrm: Vector3
	var c: Vector3
	var along: Vector3
	match side:
		0:
			nrm = Vector3(0, 0, 1)
			c = Vector3(u, wy, d * 0.5)
			along = Vector3.RIGHT
		1:
			nrm = Vector3(0, 0, -1)
			c = Vector3(u, wy, -d * 0.5)
			along = Vector3.RIGHT
		2:
			nrm = Vector3(1, 0, 0)
			c = Vector3(w * 0.5, wy, u)
			along = Vector3.BACK
		_:
			nrm = Vector3(-1, 0, 0)
			c = Vector3(-w * 0.5, wy, u)
			along = Vector3.BACK
	var sz_frame := along * 1.15 + Vector3(0, 1.35, 0) + nrm.abs() * 0.1
	_bx(oo, b, c + nrm * 0.04, sz_frame, "l29_timber")
	_bx(oo, b, c + nrm * 0.08, along * 0.9 + Vector3(0, 1.1, 0) + nrm.abs() * 0.04, "l29_pane")
	_bx(oo, b, c + nrm * 0.11 + Vector3(0, 0, 0), along * 0.06 + Vector3(0, 1.1, 0) + nrm.abs() * 0.03, "l29_timber")
	_bx(oo, b, c + nrm * 0.11, along * 0.9 + Vector3(0, 0.06, 0) + nrm.abs() * 0.03, "l29_timber")
	_bx(oo, b, c + nrm * 0.12 + Vector3(0, -0.72, 0), along * 1.3 + Vector3(0, 0.08, 0) + nrm.abs() * 0.22, "l29_timber")


## An enterable one-storey room. Walls with a front door gap and windows.
## Returns the interior floor height.
func room(o: Vector3, yaw: float, w: float, d: float, h: float = 3.0, mat: String = "l29_plank") -> float:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var oo := Vector3(o.x, 0, o.z)
	var gs := ground_span(oo, b, w, d)
	var fy := gs.y + 0.2
	_bx(oo, b, Vector3(0, (fy + gs.x - 0.8) * 0.5 - 0.1, 0), Vector3(w + 0.3, fy - gs.x + 0.6, d + 0.3), "l29_stone", true)
	_bx(oo, b, Vector3(0, fy - 0.06, 0), Vector3(w - 0.1, 0.12, d - 0.1), "l29_deck_wood", true)
	var c := [Vector3(-w * 0.5, fy, d * 0.5), Vector3(w * 0.5, fy, d * 0.5), Vector3(w * 0.5, fy, -d * 0.5), Vector3(-w * 0.5, fy, -d * 0.5)]
	var wc: Array = []
	for p in c:
		wc.append(oo + b * (p as Vector3))
	var win := {"w": 1.1, "h": 1.15, "sill": 0.95}
	k.wall(wc[0], wc[1], h, 0.2, mat, [{"at": w * 0.5, "w": 1.2, "h": 2.2, "sill": 0.0}, {"at": w * 0.2, "w": 1.1, "h": 1.15, "sill": 0.95}, {"at": w * 0.8, "w": 1.1, "h": 1.15, "sill": 0.95}])
	k.wall(wc[1], wc[2], h, 0.2, mat, [win.merged({"at": d * 0.5})])
	k.wall(wc[2], wc[3], h, 0.2, mat, [win.merged({"at": w * 0.3}), win.merged({"at": w * 0.7})])
	k.wall(wc[3], wc[0], h, 0.2, mat, [win.merged({"at": d * 0.5})])
	for p in wc:
		k.box((p as Vector3) + Vector3(0, h * 0.5, 0), Vector3(0.28, h + 0.05, 0.28), "l29_timber", GeoKit.ALL, false)
	_bx(oo, b, Vector3(0, fy + h - 0.06, 0), Vector3(w - 0.2, 0.12, d - 0.2), "l29_deck_wood")
	roof(oo, b, w, d, fy + h, d * 0.33, mat)
	var dp: Vector3 = oo + b * Vector3(0, 0, d * 0.5)
	var gy: float = ter.h(dp.x, dp.z)
	if fy - gy > 0.22:
		var n := maxi(1, int(ceil((fy - gy) / 0.18)))
		k.stairs(oo + b * Vector3(0, 0, d * 0.5 + 0.12 + n * 0.3) + Vector3(0, gy, 0), b * Vector3(0, 0, -1), 1.5, fy - gy, n, "l29_stone", 0.3)
	return fy


## A straight stair whose top tread lands on (top) going along dir.
func stair_to(top: Vector3, dir: Vector3, width: float, mat: String) -> void:
	dir = dir.normalized()
	var run := 0.28
	var steps := 1
	var g := 0.0
	for it in 4:
		var start := top - dir * run * steps
		g = ter.h(start.x, start.z)
		steps = maxi(1, int(ceil((top.y - g) / 0.18)))
	var st := top - dir * run * steps
	g = ter.h(st.x, st.z)
	k.stairs(Vector3(st.x, g, st.z), dir, width, top.y - g, steps, mat, run)
	# stringers
	var side := Vector3.UP.cross(dir).normalized()
	for s in [-1.0, 1.0]:
		var a: Vector3 = Vector3(st.x, g, st.z) + side * s * (width * 0.5 + 0.05)
		var bpt: Vector3 = top + side * s * (width * 0.5 + 0.05)
		var mid: Vector3 = (a + bpt) * 0.5
		var z: Vector3 = (bpt - a).normalized()
		var x := Vector3.UP.cross(z).normalized()
		var y: Vector3 = z.cross(x).normalized()
		k.box_xf(Transform3D(Basis(x, y, z), mid + Vector3(0, 0.05, 0)), Vector3(0.08, 0.3, (bpt - a).length()), "l29_timber", GeoKit.ALL, false)
		# hand rail
		k.box_xf(Transform3D(Basis(x, y, z), mid + Vector3(0, 0.95, 0)), Vector3(0.07, 0.07, (bpt - a).length()), "l29_timber", GeoKit.ALL, false)


## Railing posts and rail along a polyline at deck height y (no collision gaps).
func rail(a: Vector3, b2: Vector3, collide: bool = true) -> void:
	var d := b2 - a
	var n := maxi(1, int(d.length() / 1.6))
	for i in n + 1:
		var p := a.lerp(b2, float(i) / n)
		k.box(p + Vector3(0, 0.5, 0), Vector3(0.1, 1.0, 0.1), "l29_timber", GeoKit.ALL, false)
	var bas := Basis.looking_at(d.normalized(), Vector3.UP)
	k.box_xf(Transform3D(bas, (a + b2) * 0.5 + Vector3(0, 1.0, 0)), Vector3(0.08, 0.08, d.length()), "l29_timber", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, (a + b2) * 0.5 + Vector3(0, 0.55, 0)), Vector3(0.05, 0.05, d.length()), "l29_timber", GeoKit.ALL, false)
	if collide:
		k.box_xf(Transform3D(bas, (a + b2) * 0.5 + Vector3(0, 0.6, 0)), Vector3(0.1, 1.2, d.length()), "l29_timber", 0, true)


# ------------------------------------------------------------ boats

## Clinker hull mesh, bow toward +z. length L, beam B, depth D.
static func hull_mesh(L: float, B: float, D: float, sheer: float = 0.35) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ns := 14
	var prof := [Vector2(1.0, 0.0), Vector2(0.96, -0.35), Vector2(0.78, -0.7), Vector2(0.42, -0.92), Vector2(0.0, -1.0)]
	var rings: Array = []
	for i in ns + 1:
		var t := float(i) / ns
		var z := (t - 0.5) * L
		var bow := pow(maxf(0.0, t - 0.55) / 0.45, 1.6)
		var stern := pow(maxf(0.0, 0.18 - t) / 0.18, 2.0)
		var hb := B * 0.5 * (1.0 - bow) * (1.0 - stern * 0.45)
		var dd := D * (1.0 - bow * 0.35)
		var top := sheer * (pow(2.0 * t - 1.0, 2.0))
		var ring: Array = []
		for j in prof.size():
			var p: Vector2 = prof[j]
			ring.append(Vector3(p.x * hb, top + p.y * dd, z))
		rings.append(ring)
	for i in ns:
		for side in [-1.0, 1.0]:
			for j in prof.size() - 1:
				var a: Vector3 = rings[i][j] * Vector3(side, 1, 1)
				var b2: Vector3 = rings[i + 1][j] * Vector3(side, 1, 1)
				var c: Vector3 = rings[i + 1][j + 1] * Vector3(side, 1, 1)
				var d: Vector3 = rings[i][j + 1] * Vector3(side, 1, 1)
				var n: Vector3 = (b2 - a).cross(d - a).normalized() * side
				for v in [a, b2, c, a, c, d]:
					st.set_normal(n)
					st.set_uv(Vector2((v as Vector3).z, (v as Vector3).y * 3.0))
					st.add_vertex(v)
	# gunwale cap strips
	for i in ns:
		for side in [-1.0, 1.0]:
			var a: Vector3 = rings[i][0] * Vector3(side, 1, 1)
			var b2: Vector3 = rings[i + 1][0] * Vector3(side, 1, 1)
			var inn := Vector3(-side * 0.07, 0, 0)
			for v in [a, b2, b2 + inn, a, b2 + inn, a + inn]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2((v as Vector3).z, (v as Vector3).x))
				st.add_vertex((v as Vector3) + Vector3(0, 0.03, 0))
	# transom
	var r0: Array = rings[0]
	for j in prof.size() - 1:
		for side in [-1.0, 1.0]:
			var a: Vector3 = r0[j] * Vector3(side, 1, 1)
			var c: Vector3 = r0[j + 1] * Vector3(side, 1, 1)
			var m := Vector3(0, (a.y + c.y) * 0.5, a.z)
			for v in [a, c, m]:
				st.set_normal(Vector3(0, 0, -1))
				st.set_uv(Vector2((v as Vector3).x, (v as Vector3).y))
				st.add_vertex(v)
	return st.commit()


## Place a boat (visual only) floating at water level y. Returns the node.
func boat(parent: Node3D, pos: Vector3, yaw: float, L: float, sloop: bool, tilt: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = "Boat"
	n.position = pos
	n.rotation = Vector3(tilt.x, deg_to_rad(yaw), tilt.z)
	parent.add_child(n)
	var B := L * 0.34
	var D := L * 0.12
	var mi := MeshInstance3D.new()
	mi.mesh = hull_mesh(L, B, D)
	mi.material_override = MatLib.get_mat("l29_hull")
	mi.position = Vector3(0, D * 0.8, 0)
	n.add_child(mi)
	# thwarts, floorboards
	for t in [-0.25, 0.05, 0.3]:
		var th := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(B * 0.82 * (1.0 - absf(t) * 0.8), 0.06, 0.24)
		th.mesh = bm
		th.material_override = MatLib.get_mat("l29_timber")
		th.position = Vector3(0, D * 0.8 - 0.05, t * L)
		n.add_child(th)
	var fb := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(B * 0.45, 0.04, L * 0.6)
	fb.mesh = fm
	fb.material_override = MatLib.get_mat("l29_deck_wood")
	fb.position = Vector3(0, D * 0.8 - D * 0.8, -0.05 * L)
	n.add_child(fb)
	if sloop:
		var mast := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.06
		cm.bottom_radius = 0.1
		cm.height = L * 1.15
		mast.mesh = cm
		mast.material_override = MatLib.get_mat("l29_timber")
		mast.position = Vector3(0, D * 0.8 + L * 0.5, L * 0.18)
		n.add_child(mast)
		var boom := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.05
		bc.bottom_radius = 0.05
		bc.height = L * 0.55
		boom.mesh = bc
		boom.material_override = MatLib.get_mat("l29_timber")
		boom.rotation = Vector3(PI * 0.5, 0, 0)
		boom.position = Vector3(0, D * 0.8 + 1.1, L * 0.18 - L * 0.27)
		n.add_child(boom)
		var furl := MeshInstance3D.new()
		var fc := CapsuleMesh.new()
		fc.radius = 0.16
		fc.height = L * 0.5
		furl.mesh = fc
		furl.material_override = MatLib.get_mat("l29_sail")
		furl.rotation = Vector3(PI * 0.5, 0, 0)
		furl.position = Vector3(0, D * 0.8 + 1.3, L * 0.18 - L * 0.27)
		n.add_child(furl)
	return n
