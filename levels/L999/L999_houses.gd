extends RefCounted
## Level 999 structures: four dormant houses near the epicentre (concrete, wood,
## glass and stone, per the page's "masses of concrete, glass, wood, and stone"),
## settled into the dirt with soil banked against their walls, unconnected by any
## path; dark, dank, rectangular, barely decorated insides with empty beds,
## closed blinds and sparse furniture. Then the epicentre: a ring of old benches
## and, among them, the single trapdoor.

const HOUSES := [
	# [name, centre, yaw_deg]
	["concrete", Vector3(27.0, 0.0, 21.0), 32.0],
	["wood", Vector3(-41.0, 0.0, 22.0), -12.0],
	["glass", Vector3(-6.0, 0.0, -41.0), 8.0],
	["stone", Vector3(45.0, 0.0, -34.0), 61.0],
]

var lvl
var k: GeoKit
var r := RandomNumberGenerator.new()
var props: Node3D
var o := Vector3.ZERO
var bas := Basis()
var footprints: Array = []    # [centre, radius]
var bed_spots: Array = []     # world positions of the empty beds
var blind_spots: Array = []   # world positions of closed blinds (interaction)
var door_spots: Array = []    # world positions just inside each door


func _init(level, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	k = kit
	props = prop_parent
	r.seed = 99930


static func materials() -> void:
	MatLib.define("l999_concrete", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.15, 0.15, 0.15), "stain_amount": 0.75,
		"stain_color": Color(0.07, 0.07, 0.07), "stain_scale": 0.6, "grime_height": 0.9, "grime_color": Color(0.06, 0.06, 0.06), "wetness": 0.35}, "concrete")
	MatLib.define("l999_siding", {"albedo_a": Color(0.17, 0.17, 0.17), "albedo_b": Color(0.12, 0.12, 0.12), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.18), "uv_rotate": 0.0, "grout_width": 0.012, "grout_color": Color(0.04, 0.04, 0.04),
		"stain_amount": 0.6, "stain_color": Color(0.06, 0.06, 0.06), "grime_height": 0.8, "grime_color": Color(0.05, 0.05, 0.05), "roughness_a": 0.9}, "wood_floor")
	MatLib.define("l999_boards", {"albedo_a": Color(0.13, 0.13, 0.13), "albedo_b": Color(0.1, 0.1, 0.1), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.16), "grout_color": Color(0.035, 0.035, 0.035), "stain_amount": 0.5, "stain_color": Color(0.06, 0.06, 0.06),
		"roughness_a": 0.85}, "wood_floor")
	MatLib.define("l999_stone", {"albedo_a": Color(0.19, 0.19, 0.19), "albedo_b": Color(0.12, 0.12, 0.12), "pattern": 4,
		"pattern_scale": Vector2(0.55, 0.3), "grout_width": 0.03, "grout_color": Color(0.07, 0.07, 0.07), "bump_strength": 1.6,
		"stain_amount": 0.5, "stain_color": Color(0.07, 0.07, 0.07), "grime_height": 0.7, "grime_color": Color(0.05, 0.05, 0.05)}, "brick")
	MatLib.define("l999_slate", {"albedo_a": Color(0.08, 0.08, 0.08), "albedo_b": Color(0.06, 0.06, 0.06), "pattern": 14,
		"pattern_scale": Vector2(0.4, 0.25), "grout_width": 0.012, "grout_color": Color(0.03, 0.03, 0.03), "roughness_a": 0.7}, "concrete")
	MatLib.define("l999_plaster", {"albedo_a": Color(0.25, 0.25, 0.25), "albedo_b": Color(0.21, 0.21, 0.21), "stain_amount": 0.45,
		"stain_color": Color(0.16, 0.16, 0.16), "stain_scale": 1.6, "grime_height": 0.6, "grime_color": Color(0.1, 0.1, 0.1), "wetness": 0.25}, "plaster")
	MatLib.define("l999_steel", {"albedo_a": Color(0.12, 0.12, 0.12), "albedo_b": Color(0.08, 0.08, 0.08), "metallic_value": 0.5,
		"stain_amount": 0.5, "stain_color": Color(0.05, 0.05, 0.05)}, "metal")
	MatLib.define("l999_blind", {"albedo_a": Color(0.33, 0.33, 0.33), "albedo_b": Color(0.28, 0.28, 0.28), "stain_amount": 0.4,
		"stain_color": Color(0.16, 0.16, 0.16), "roughness_a": 0.6}, "plaster")
	MatLib.define("l999_soilbank", {"albedo_a": Color(0.1, 0.1, 0.1), "albedo_b": Color(0.075, 0.075, 0.075), "noise_scale": 1.2, "bump_strength": 1.5}, "dirt")
	MatLib.define("l999_mattress", {"albedo_a": Color(0.3, 0.3, 0.3), "albedo_b": Color(0.24, 0.24, 0.24), "pattern": 1,
		"pattern_scale": Vector2(0.25, 0.25), "grout_width": 0.008, "grout_color": Color(0.2, 0.2, 0.2), "stain_amount": 0.7,
		"stain_color": Color(0.14, 0.14, 0.14), "roughness_a": 1.0}, "plaster")
	MatLib.define("l999_benchwood", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.15, 0.15, 0.15), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.12), "grout_color": Color(0.05, 0.05, 0.05), "stain_amount": 0.4, "stain_color": Color(0.08, 0.08, 0.08)}, "wood_floor")
	MatLib.define("l999_iron", {"albedo_a": Color(0.06, 0.06, 0.06), "albedo_b": Color(0.04, 0.04, 0.04), "metallic_value": 0.6}, "metal")
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.45, 0.45, 0.45, 0.22)
	g.roughness = 0.12
	g.metallic_specular = 0.8
	MatLib.register("l999_glass", g)


# ------------------------------------------------------------- local frame

func L(v: Vector3) -> Vector3:
	return o + bas * v


func lbox(c: Vector3, s: Vector3, mat: String, faces := GeoKit.ALL, collide := true) -> void:
	k.box_xf(Transform3D(bas, L(c)), s, mat, faces, collide)


func lwall(a: Vector3, b: Vector3, h: float, t: float, mat: String, ops: Array = []) -> void:
	k.wall(L(a), L(b), h, t, mat, ops)


func prop(id: String, c: Vector3, yaw: float, collide := true, h := 0.0) -> Node3D:
	return Props.place(lvl, props, id, L(c), rad_to_deg(bas.get_euler().y) + yaw, h, collide)


## Closed venetian blinds filling a window (local, centred on the wall plane).
func blinds(c: Vector3, w: float, h: float, along_x: bool) -> void:
	var n := int(h / 0.05)
	for i in n:
		var y := c.y - h * 0.5 + 0.025 + i * 0.05
		var s := Vector3(w, 0.042, 0.012) if along_x else Vector3(0.012, 0.042, w)
		lbox(Vector3(c.x, y, c.z), s, "l999_blind", GeoKit.ALL, false)
	# head rail
	lbox(Vector3(c.x, c.y + h * 0.5 + 0.03, c.z), (Vector3(w + 0.04, 0.06, 0.05) if along_x else Vector3(0.05, 0.06, w + 0.04)), "l999_steel", GeoKit.ALL, false)
	blind_spots.append(L(c))


func glass(c: Vector3, w: float, h: float, along_x: bool) -> void:
	lbox(c, Vector3(w, h, 0.01) if along_x else Vector3(0.01, h, w), "l999_glass", GeoKit.PZ | GeoKit.NZ | GeoKit.PX | GeoKit.NX, false)


## Soil banked against a wall run (visual wedges, settling into the dirt).
func bank(a: Vector3, b: Vector3, out: Vector3, hgt: float) -> void:
	var d := b - a
	var along := d.normalized()
	var n := int(d.length() / 1.6) + 1
	var fb := Basis(along, Vector3.UP, out.normalized())
	for i in n:
		var t := (i + 0.5) / n
		var hh := hgt * r.randf_range(0.6, 1.2)
		var p := a.lerp(b, t) + out.normalized() * (hh * 0.55) + Vector3(0, -0.05, 0)
		var xf := Transform3D(bas * fb * Basis(Vector3.RIGHT, 0.62), L(p))
		k.box_xf(xf, Vector3(d.length() / n * 1.3, hh * 1.3, hh * 1.5), "l999_soilbank", GeoKit.ALL, false)


# ------------------------------------------------------------- the houses

func build_all() -> void:
	for hd in HOUSES:
		o = hd[1]
		bas = Basis(Vector3.UP, deg_to_rad(hd[2]))
		match hd[0]:
			"concrete":
				_concrete()
			"wood":
				_wood()
			"glass":
				_glass_house()
			"stone":
				_stone()


func _concrete() -> void:
	var W := 9.0
	var D := 7.0
	var H := 2.9
	footprints.append([o, 7.5])
	lbox(Vector3(0, 0.08, 0), Vector3(W, 0.16, D), "l999_concrete")
	var hw := W * 0.5
	var hd := D * 0.5
	lwall(Vector3(-hw, 0.16, -hd), Vector3(hw, 0.16, -hd), H, 0.25, "l999_concrete", [{"at": 2.2, "w": 1.0, "h": 2.1}, {"at": 6.6, "w": 1.6, "h": 1.1, "sill": 0.95}])
	lwall(Vector3(-hw, 0.16, hd), Vector3(hw, 0.16, hd), H, 0.25, "l999_concrete", [{"at": 2.4, "w": 1.6, "h": 1.1, "sill": 0.95}, {"at": 6.8, "w": 1.6, "h": 1.1, "sill": 0.95}])
	lwall(Vector3(-hw, 0.16, -hd), Vector3(-hw, 0.16, hd), H, 0.25, "l999_concrete")
	lwall(Vector3(hw, 0.16, -hd), Vector3(hw, 0.16, hd), H, 0.25, "l999_concrete", [{"at": 3.5, "w": 1.2, "h": 1.0, "sill": 1.0}])
	# interior partition with a doorway: front room | bedroom
	lwall(Vector3(0.6, 0.16, -hd), Vector3(0.6, 0.16, hd), H, 0.12, "l999_plaster", [{"at": 4.6, "w": 0.9, "h": 2.05}])
	# inner plaster skins
	for s in [-1.0, 1.0]:
		lbox(Vector3(0, 0.16 + H * 0.5, s * (hd - 0.14)), Vector3(W - 0.3, H, 0.02), "l999_plaster", GeoKit.ALL, false)
	lbox(Vector3(0, 0.16 + H + 0.12, 0), Vector3(W + 0.5, 0.24, D + 0.5), "l999_concrete")
	lbox(Vector3(0, 0.16 + H - 0.01, 0), Vector3(W - 0.4, 0.02, D - 0.4), "l999_plaster", GeoKit.NY, false)
	for s in [-1.0, 1.0]:
		blinds(Vector3((-hw + 2.4) if s > 0 else (-hw + 6.6), 0.16 + 1.5, s * (hd - 0.05)), 1.56, 1.06, true)
		glass(Vector3((-hw + 2.4) if s > 0 else (-hw + 6.6), 0.16 + 1.5, s * (hd + 0.02)), 1.6, 1.1, true)
	blinds(Vector3(-hw + 6.8, 0.16 + 1.5, hd - 0.05), 1.56, 1.06, true)
	glass(Vector3(-hw + 6.8, 0.16 + 1.5, hd + 0.02), 1.6, 1.1, true)
	blinds(Vector3(hw - 0.05, 0.16 + 1.5, -hd + 3.5), 1.16, 0.96, false)
	# an open, rotted door leaf
	lbox(Vector3(-hw + 1.75, 0.16 + 1.03, -hd - 0.45), Vector3(0.05, 2.05, 0.9), "l999_boards", GeoKit.ALL, true)
	door_spots.append(L(Vector3(-hw + 2.2, 0.2, -hd + 0.8)))
	# bedroom (x > 0.6): an empty bed, a nightstand, closed blinds
	prop("ph/old_bed_frame", Vector3(3.1, 0.16, 1.9), 90.0)
	lbox(Vector3(3.15, 0.16 + 0.47, 1.9), Vector3(1.85, 0.16, 0.82), "l999_mattress", GeoKit.ALL, false)
	bed_spots.append(L(Vector3(3.1, 0.6, 1.9)))
	prop("ph/ClassicNightstand_01", Vector3(1.2, 0.16, 3.0), 180.0)
	prop("ph/dining_chair_02", Vector3(3.6, 0.16, -2.6), 200.0)
	# front room: almost nothing
	prop("ph/drawer_cabinet", Vector3(-3.9, 0.16, 2.9), 180.0)
	prop("ph/dining_chair_02", Vector3(-1.4, 0.16, 0.6), 75.0)
	bank(Vector3(-hw, 0, hd + 0.15), Vector3(hw, 0, hd + 0.15), Vector3(0, 0, 1), 0.7)
	bank(Vector3(hw + 0.15, 0, -hd), Vector3(hw + 0.15, 0, hd), Vector3(1, 0, 0), 0.9)
	bank(Vector3(-hw - 0.15, 0, -hd), Vector3(-hw - 0.15, 0, hd), Vector3(-1, 0, 0), 0.5)


func _wood() -> void:
	var W := 7.0
	var D := 8.4
	var H1 := 2.8
	var F2 := 0.3 + H1 + 0.15
	var H2 := 2.5
	footprints.append([o, 7.5])
	var hw := W * 0.5
	var hd := D * 0.5
	lbox(Vector3(0, 0.15, 0), Vector3(W, 0.3, D), "l999_boards")
	lwall(Vector3(-hw, 0.3, -hd), Vector3(hw, 0.3, -hd), H1, 0.18, "l999_siding", [{"at": 1.6, "w": 1.0, "h": 2.05}, {"at": 5.0, "w": 1.2, "h": 1.2, "sill": 0.9}])
	lwall(Vector3(-hw, 0.3, hd), Vector3(hw, 0.3, hd), H1, 0.18, "l999_siding", [{"at": 3.5, "w": 1.2, "h": 1.2, "sill": 0.9}])
	lwall(Vector3(-hw, 0.3, -hd), Vector3(-hw, 0.3, hd), H1, 0.18, "l999_siding", [{"at": 2.0, "w": 1.0, "h": 1.2, "sill": 0.9}])
	lwall(Vector3(hw, 0.3, -hd), Vector3(hw, 0.3, hd), H1, 0.18, "l999_siding")
	# upper floor slab with a stair hole along the east wall (x from 2.1 to 3.4, z -3 .. 1.6)
	lbox(Vector3(-0.7, F2 - 0.08, 0), Vector3(W - 1.4, 0.16, D), "l999_boards")
	lbox(Vector3(hw - 0.7, F2 - 0.08, -3.55), Vector3(1.4, 0.16, 1.3), "l999_boards")
	lbox(Vector3(hw - 0.7, F2 - 0.08, 2.9), Vector3(1.4, 0.16, 2.6), "l999_boards")
	# stair: 16 steps rising north (+z) along the east wall
	k.stairs(L(Vector3(hw - 0.72, 0.3, -2.9)), bas * Vector3(0, 0, 1), 1.1, F2 - 0.3, 16, "l999_boards", 0.28, true)
	lbox(Vector3(hw - 1.38, F2 + 0.5, -0.6), Vector3(0.05, 1.0, 4.4), "l999_boards", GeoKit.ALL, false)
	# upper storey
	lwall(Vector3(-hw, F2, -hd), Vector3(hw, F2, -hd), H2, 0.18, "l999_siding", [{"at": 2.4, "w": 1.1, "h": 1.1, "sill": 0.8}])
	lwall(Vector3(-hw, F2, hd), Vector3(hw, F2, hd), H2, 0.18, "l999_siding", [{"at": 3.5, "w": 1.1, "h": 1.1, "sill": 0.8}])
	lwall(Vector3(-hw, F2, -hd), Vector3(-hw, F2, hd), H2, 0.18, "l999_siding")
	lwall(Vector3(hw, F2, -hd), Vector3(hw, F2, hd), H2, 0.18, "l999_siding")
	lwall(Vector3(-hw, F2, 0.4), Vector3(1.0, F2, 0.4), H2, 0.1, "l999_plaster", [{"at": 3.4, "w": 0.85, "h": 2.0}])
	lbox(Vector3(0, F2 + H2 - 0.01, 0), Vector3(W - 0.3, 0.02, D - 0.3), "l999_plaster", GeoKit.NY, false)
	# gable roof
	var top := F2 + H2
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas * Basis(Vector3.FORWARD, s * 0.62), L(Vector3(s * (hw * 0.5 + 0.1), top + 1.15, 0))), Vector3(hw * 1.32, 0.14, D + 0.6), "l999_slate", GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		for i in 6:
			var y := top + 0.2 + i * 0.36
			var wv := maxf(W * (1.0 - float(i) / 6.0) - 0.2, 0.3)
			lbox(Vector3(0, y, s * hd), Vector3(wv, 0.36, 0.16), "l999_siding", GeoKit.ALL, false)
	for w in [[Vector3(-hw + 5.0, 0.3 + 1.5, -hd), 1.16, 1.16, true], [Vector3(-hw + 3.5, 0.3 + 1.5, hd), 1.16, 1.16, true],
			[Vector3(-hw, 0.3 + 1.5, -hd + 2.0), 0.96, 1.16, false], [Vector3(-hw + 2.4, F2 + 1.35, -hd), 1.06, 1.06, true],
			[Vector3(-hw + 3.5, F2 + 1.35, hd), 1.06, 1.06, true]]:
		var c: Vector3 = w[0]
		var nrm := Vector3(0, 0, signf(c.z)) if w[3] else Vector3(signf(c.x), 0, 0)
		blinds(c - nrm * 0.12, w[1], w[2], w[3])
		glass(c + nrm * 0.01, w[1] + 0.04, w[2] + 0.04, w[3])
	lbox(Vector3(-hw + 0.95, 0.3 + 1.03, -hd - 0.42), Vector3(0.05, 2.05, 0.85), "l999_boards", GeoKit.ALL, true)
	door_spots.append(L(Vector3(-hw + 1.6, 0.35, -hd + 0.8)))
	# ground floor: a table, two chairs, one armchair
	prop("ph/dining_table", Vector3(-1.1, 0.3, 0.6), 90.0)
	prop("ph/dining_chair_02", Vector3(-1.8, 0.3, -0.7), 10.0)
	prop("ph/dining_chair_02", Vector3(-0.3, 0.3, 2.0), 160.0, true)
	prop("ph/ArmChair_01", Vector3(-2.5, 0.3, 3.2), 140.0)
	# upper floor (north room): the empty bed
	prop("ph/old_bed_frame", Vector3(-1.6, F2, 2.6), 90.0)
	lbox(Vector3(-1.55, F2 + 0.47, 2.6), Vector3(1.85, 0.16, 0.82), "l999_mattress", GeoKit.ALL, false)
	bed_spots.append(L(Vector3(-1.6, F2 + 0.4, 2.6)))
	prop("ph/drawer_cabinet", Vector3(-3.0, F2, -2.6), 90.0)
	bank(Vector3(-hw - 0.1, 0, -hd), Vector3(-hw - 0.1, 0, hd), Vector3(-1, 0, 0), 0.6)
	bank(Vector3(-hw, 0, hd + 0.1), Vector3(hw, 0, hd + 0.1), Vector3(0, 0, 1), 0.8)


func _glass_house() -> void:
	var W := 10.0
	var D := 6.0
	var H := 2.8
	footprints.append([o, 8.0])
	var hw := W * 0.5
	var hd := D * 0.5
	lbox(Vector3(0, 0.12, 0), Vector3(W, 0.24, D), "l999_concrete")
	# split level: a raised sleeping platform at the west end (+0.72), four steps
	lbox(Vector3(-hw + 1.75, 0.24 + 0.36, 0), Vector3(3.5, 0.72, D - 0.2), "l999_boards")
	k.stairs(L(Vector3(-hw + 3.5 + 1.12, 0.24, -1.2)), bas * Vector3(-1, 0, 0), 1.6, 0.72, 4, "l999_boards", 0.28, true)
	# steel frame posts and roof
	for x in [-hw, -hw + 2.5, 0.0, hw - 2.5, hw]:
		for z in [-hd, hd]:
			lbox(Vector3(x, 0.24 + H * 0.5, z), Vector3(0.14, H, 0.14), "l999_steel")
	for z in [-hd, -1.0, 1.0, hd]:
		lbox(Vector3(-hw, 0.24 + H * 0.5, z), Vector3(0.14, H, 0.14), "l999_steel")
		lbox(Vector3(hw, 0.24 + H * 0.5, z), Vector3(0.14, H, 0.14), "l999_steel")
	lbox(Vector3(0, 0.24 + H + 0.15, 0), Vector3(W + 0.8, 0.3, D + 0.8), "l999_concrete")
	lbox(Vector3(0, 0.24 + H - 0.01, 0), Vector3(W - 0.2, 0.02, D - 0.2), "l999_plaster", GeoKit.NY, false)
	# glass walls with blinds closed behind every pane; a gap for the door
	var bays := [[-hw, -hw + 2.5], [-hw + 2.5, 0.0], [0.0, hw - 2.5], [hw - 2.5, hw]]
	for zi in 2:
		var z := -hd if zi == 0 else hd
		for bi in bays.size():
			var b: Array = bays[bi]
			var cx := (float(b[0]) + float(b[1])) * 0.5
			var wv := float(b[1]) - float(b[0]) - 0.14
			if zi == 0 and bi == 2:
				# doorway bay: half glass, half open
				glass(Vector3(cx + 0.6, 0.24 + H * 0.5, z), wv * 0.5, H - 0.1, true)
				blinds(Vector3(cx + 0.6, 0.24 + H * 0.5, z + 0.12), wv * 0.5, H - 0.2, true)
				k.add_box_shape(Transform3D(bas, L(Vector3(cx + 0.6, 0.24 + H * 0.5, z))), Vector3(wv * 0.5, H, 0.1), "glass")
				continue
			glass(Vector3(cx, 0.24 + H * 0.5, z), wv, H - 0.1, true)
			blinds(Vector3(cx, 0.24 + H * 0.5, z + (0.12 if zi == 0 else -0.12)), wv, H - 0.2, true)
			k.add_box_shape(Transform3D(bas, L(Vector3(cx, 0.24 + H * 0.5, z))), Vector3(wv, H, 0.1), "glass")
	for xi in 2:
		var x := -hw if xi == 0 else hw
		for b in [[-hd, -1.0], [-1.0, 1.0], [1.0, hd]]:
			var cz := (float(b[0]) + float(b[1])) * 0.5
			var wv := float(b[1]) - float(b[0]) - 0.14
			glass(Vector3(x, 0.24 + H * 0.5, cz), wv, H - 0.1, false)
			blinds(Vector3(x + (0.12 if xi == 0 else -0.12), 0.24 + H * 0.5, cz), wv, H - 0.2, false)
			k.add_box_shape(Transform3D(bas, L(Vector3(x, 0.24 + H * 0.5, cz))), Vector3(0.1, H, wv), "glass")
	door_spots.append(L(Vector3(hw - 4.3, 0.3, -hd + 0.8)))
	# furniture: a sofa, a low table; the empty bed on the platform
	prop("ph/Sofa_01", Vector3(1.8, 0.24, 2.2), 180.0)
	prop("ph/coffee_table_round_01", Vector3(1.8, 0.24, 0.6), 0.0)
	prop("ph/old_bed_frame", Vector3(-hw + 1.6, 0.96, 1.2), 90.0)
	lbox(Vector3(-hw + 1.65, 0.96 + 0.47, 1.2), Vector3(1.85, 0.16, 0.82), "l999_mattress", GeoKit.ALL, false)
	bed_spots.append(L(Vector3(-hw + 1.6, 1.4, 1.2)))
	prop("ph/ClassicNightstand_01", Vector3(-hw + 0.5, 0.96, -0.5), 90.0)
	bank(Vector3(-hw, 0, hd + 0.2), Vector3(hw, 0, hd + 0.2), Vector3(0, 0, 1), 0.5)


func _stone() -> void:
	var W := 6.4
	var D := 5.2
	var H := 2.6
	footprints.append([o, 6.0])
	var hw := W * 0.5
	var hd := D * 0.5
	lbox(Vector3(0, 0.1, 0), Vector3(W, 0.2, D), "l999_stone")
	lwall(Vector3(-hw, 0.2, -hd), Vector3(hw, 0.2, -hd), H, 0.45, "l999_stone", [{"at": 2.0, "w": 0.95, "h": 1.95}, {"at": 4.6, "w": 0.8, "h": 0.8, "sill": 1.1}])
	lwall(Vector3(-hw, 0.2, hd), Vector3(hw, 0.2, hd), H, 0.45, "l999_stone", [{"at": 3.2, "w": 0.8, "h": 0.8, "sill": 1.1}])
	lwall(Vector3(-hw, 0.2, -hd), Vector3(-hw, 0.2, hd), H, 0.45, "l999_stone")
	lwall(Vector3(hw, 0.2, -hd), Vector3(hw, 0.2, hd), H, 0.45, "l999_stone", [{"at": 2.6, "w": 0.8, "h": 0.8, "sill": 1.1}])
	var top := 0.2 + H
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas * Basis(Vector3.RIGHT, -s * 0.7), L(Vector3(0, top + 0.95, s * (hd * 0.5 + 0.12)))), Vector3(W + 0.7, 0.16, hd * 1.45), "l999_slate", GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		for i in 5:
			var y := top + 0.17 + i * 0.36
			var wv := maxf(D * (1.0 - float(i) / 5.0) - 0.3, 0.3)
			lbox(Vector3(s * hw, y, 0), Vector3(0.45, 0.36, wv), "l999_stone", GeoKit.ALL, false)
	lbox(Vector3(0, top - 0.01, 0), Vector3(W - 0.9, 0.02, D - 0.9), "l999_boards", GeoKit.NY, false)
	for w in [[Vector3(-hw + 4.6, 0.2 + 1.5, -hd), true], [Vector3(-hw + 3.2, 0.2 + 1.5, hd), true], [Vector3(hw, 0.2 + 1.5, -hd + 2.6), false]]:
		var c: Vector3 = w[0]
		var nrm := Vector3(0, 0, signf(c.z)) if w[1] else Vector3(signf(c.x), 0, 0)
		blinds(c - nrm * 0.25, 0.76, 0.76, w[1])
	door_spots.append(L(Vector3(-hw + 2.0, 0.25, -hd + 0.8)))
	prop("ph/old_bed_frame", Vector3(1.6, 0.2, 1.3), 90.0)
	lbox(Vector3(1.65, 0.2 + 0.47, 1.3), Vector3(1.85, 0.16, 0.82), "l999_mattress", GeoKit.ALL, false)
	bed_spots.append(L(Vector3(1.6, 0.6, 1.3)))
	prop("ph/wooden_bookshelf_worn", Vector3(-2.4, 0.2, 1.95), 180.0)
	prop("ph/dining_chair_02", Vector3(-1.5, 0.2, 0.0), 230.0)
	for s in [Vector3(0, 0, -hd - 0.25), Vector3(0, 0, hd + 0.25), Vector3(hw + 0.25, 0, 0), Vector3(-hw - 0.25, 0, 0)]:
		var along := Vector3(1, 0, 0) if absf(s.z) > 0.1 else Vector3(0, 0, 1)
		var ln := W if absf(s.z) > 0.1 else D
		bank(s - along * ln * 0.5, s + along * ln * 0.5, s.normalized(), 1.0)


# --------------------------------------------------------------- epicentre

## A loose ring of old park benches at the exact centre of the island and,
## among them, the single trapdoor (wooden hatch in a stone kerb).
func epicentre() -> Array:
	o = Vector3.ZERO
	bas = Basis()
	var benches: Array = []
	var angs := [0.25, 1.05, 1.85, 2.5, 3.4, 4.25, 5.1, 5.75]
	for i in angs.size():
		var a: float = angs[i] + r.randf_range(-0.12, 0.12)
		var d := r.randf_range(5.0, 7.5)
		var p := Vector3(cos(a) * d, 0, sin(a) * d)
		var face := atan2(-p.x, -p.z) + r.randf_range(-0.35, 0.35)
		bench(p, face)
		benches.append(p)
	# two more, further out, turned away
	bench(Vector3(10.5, 0, -6.0), 0.9)
	bench(Vector3(-9.0, 0, 9.5), 2.6)
	# the trapdoor
	for s in [[Vector3(0, 0.04, -0.72), Vector3(1.6, 0.12, 0.22)], [Vector3(0, 0.04, 0.72), Vector3(1.6, 0.12, 0.22)],
			[Vector3(-0.72, 0.04, 0), Vector3(0.22, 0.12, 1.22)], [Vector3(0.72, 0.04, 0), Vector3(0.22, 0.12, 1.22)]]:
		k.box(s[0], s[1], "l999_stone", GeoKit.ALL, false)
	k.box(Vector3(0, 0.035, 0), Vector3(1.22, 0.05, 1.22), "l999_boards", GeoKit.ALL, false)
	for x in [-0.3, 0.3]:
		k.box(Vector3(x, 0.065, 0), Vector3(0.07, 0.012, 1.1), "l999_iron", GeoKit.ALL, false)
	# ring handle
	for i in 8:
		var a := TAU * i / 8.0
		k.box_xf(Transform3D(Basis(Vector3.UP, a), Vector3(cos(a) * 0.08, 0.075, 0.35 + sin(a) * 0.08)), Vector3(0.02, 0.018, 0.07), "l999_iron", GeoKit.ALL, false)
	return benches


func bench(p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var x := func(v: Vector3) -> Vector3: return p + b * v
	for sx in [-0.78, 0.78]:
		k.box_xf(Transform3D(b, x.call(Vector3(sx, 0.22, 0.0))), Vector3(0.06, 0.44, 0.5), "l999_iron", GeoKit.ALL, false)
		k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.22), x.call(Vector3(sx, 0.68, 0.22))), Vector3(0.06, 0.5, 0.06), "l999_iron", GeoKit.ALL, false)
	for i in 3:
		k.box_xf(Transform3D(b, x.call(Vector3(0, 0.45, -0.18 + i * 0.14))), Vector3(1.8, 0.04, 0.11), "l999_benchwood", GeoKit.ALL, false)
	for i in 2:
		k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.22), x.call(Vector3(0, 0.62 + i * 0.17, 0.25 + i * 0.04))), Vector3(1.8, 0.11, 0.035), "l999_benchwood", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, x.call(Vector3(0, 0.4, 0.05))), Vector3(1.7, 0.8, 0.55), "wood")
