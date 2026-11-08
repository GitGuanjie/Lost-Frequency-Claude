extends RefCounted
## Level 60 coast, one 100 m streamed chunk at a time along x. Cross-section (z grows
## toward the sea): a grass embankment rising inland into the dark, a planting strip,
## the Upper Area (new concrete bay walk, y 5.0, z -12..0) with its railing and lamps,
## the retaining wall, the Lower Area (unfinished dirt path, y 1.0, z 0.45..7) strewn
## with construction equipment and no barrier, the beach slope into The Sea (surface
## y 0, about 4 ft deep). One staircase per chunk (SOURCE: about 100 m apart); the lamp
## in front of each staircase works, most others are broken or off.

const CHUNK := 100.0
const UP_Y := 5.0
const LOW_Y := 1.0
const BED_Y := -1.22
const STAIR_X := 50.0
const STAIR_RUN := 0.3
const STAIR_STEPS := 22
const LAMP_XS := [12.5, 37.5, 62.5, 87.5]
const BENCH_XS := [9.0, 33.0, 72.0, 92.0]

var L: LevelBase


func _init(level: LevelBase) -> void:
	L = level


static func materials() -> void:
	MatLib.define("l60_pavers", {"albedo_a": Color(0.50, 0.50, 0.48), "albedo_b": Color(0.44, 0.44, 0.42), "pattern": 1,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.006, "grout_color": Color(0.30, 0.30, 0.29), "tile_variation": 0.04,
		"roughness_a": 0.8, "roughness_b": 0.92, "stain_amount": 0.15, "stain_color": Color(0.36, 0.36, 0.34), "wetness": 0.25,
		"bump_strength": 0.5})
	MatLib.define("l60_curb", {"albedo_a": Color(0.58, 0.58, 0.56), "albedo_b": Color(0.52, 0.52, 0.50), "noise_scale": 2.0,
		"roughness_a": 0.8, "roughness_b": 0.9}, "concrete")
	MatLib.define("l60_wall", {"albedo_a": Color(0.42, 0.42, 0.40), "albedo_b": Color(0.34, 0.34, 0.32), "pattern": 1,
		"pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.01, "grout_color": Color(0.26, 0.26, 0.25), "stain_amount": 0.45,
		"stain_color": Color(0.22, 0.24, 0.22), "stain_scale": 0.6, "grime_height": 1.2, "grime_color": Color(0.16, 0.18, 0.16),
		"floor_y": 1.0, "bump_strength": 0.8}, "concrete")
	MatLib.define("l60_dirt", {"albedo_a": Color(0.25, 0.20, 0.15), "albedo_b": Color(0.19, 0.15, 0.11), "noise_scale": 1.2,
		"stain_amount": 0.3, "stain_color": Color(0.14, 0.12, 0.09), "wetness": 0.35, "bump_strength": 1.4}, "dirt")
	MatLib.define("l60_wet_sand", {"albedo_a": Color(0.22, 0.20, 0.17), "albedo_b": Color(0.15, 0.14, 0.12), "pattern": 13,
		"noise_scale": 0.6, "wetness": 0.8, "roughness_a": 0.4, "roughness_b": 0.7, "bump_strength": 0.6}, "sand")
	MatLib.define("l60_blacksand", {"albedo_a": Color(0.05, 0.05, 0.055), "albedo_b": Color(0.03, 0.03, 0.035), "pattern": 13,
		"noise_scale": 0.5, "wetness": 0.6, "roughness_a": 0.5, "roughness_b": 0.8, "bump_strength": 0.6}, "sand")
	MatLib.define("l60_grass", {"albedo_a": Color(0.10, 0.12, 0.07), "albedo_b": Color(0.07, 0.08, 0.05), "pattern": 12,
		"pattern_color": Color(0.16, 0.16, 0.09), "pattern_strength": 0.5, "noise_scale": 0.4}, "grass")
	MatLib.define("l60_soil", {"albedo_a": Color(0.14, 0.11, 0.08), "albedo_b": Color(0.10, 0.08, 0.06)}, "dirt")
	MatLib.define("l60_steel", {"albedo_a": Color(0.30, 0.32, 0.34), "albedo_b": Color(0.24, 0.26, 0.28), "roughness_a": 0.4,
		"roughness_b": 0.6, "stain_amount": 0.2}, "metal")
	MatLib.define("l60_rust", {"albedo_a": Color(0.32, 0.17, 0.09), "albedo_b": Color(0.22, 0.12, 0.07)}, "rust")
	MatLib.define("l60_wood", {"albedo_a": Color(0.36, 0.27, 0.18), "albedo_b": Color(0.28, 0.21, 0.14), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.12), "grout_width": 0.01, "grout_color": Color(0.12, 0.09, 0.06), "wetness": 0.2}, "wood_floor")
	MatLib.define("l60_container", {"albedo_a": Color(0.16, 0.24, 0.18), "albedo_b": Color(0.13, 0.20, 0.15), "pattern": 2,
		"pattern_scale": Vector2(0.25, 1.0), "pattern_color": Color(0.09, 0.13, 0.10), "pattern_strength": 0.7,
		"metallic_value": 0.5, "stain_amount": 0.5, "stain_color": Color(0.30, 0.17, 0.08), "stain_scale": 1.5}, "metal")
	MatLib.define("l60_tarp", {"albedo_a": Color(0.12, 0.20, 0.32), "albedo_b": Color(0.10, 0.16, 0.26), "noise_scale": 3.0,
		"roughness_a": 0.6, "roughness_b": 0.8, "bump_strength": 0.8})
	MatLib.define("l60_cloth", {"albedo_a": Color(0.25, 0.24, 0.20), "albedo_b": Color(0.20, 0.19, 0.16)})
	MatLib.define("l60_orange", {"albedo_a": Color(0.8, 0.32, 0.05), "albedo_b": Color(0.7, 0.27, 0.04), "roughness_a": 0.5,
		"roughness_b": 0.6, "stain_amount": 0.3, "stain_color": Color(0.35, 0.25, 0.15)}, "plaster")
	MatLib.define("l60_bag", {"albedo_a": Color(0.62, 0.58, 0.50), "albedo_b": Color(0.55, 0.51, 0.44), "noise_scale": 4.0}, "paper")
	MatLib.register("l60_lamp_on", MatLib.panel(Color(1.0, 0.82, 0.55), 5.0))
	MatLib.register("l60_lamp_flick", MatLib.panel(Color(1.0, 0.82, 0.55), 2.8, 0.75, 3.0))
	MatLib.register("l60_lamp_off", MatLib.standard(Color(0.06, 0.06, 0.06), 0.15, 0.2))
	MatLib.register("l60_lantern", MatLib.panel(Color(1.0, 0.6, 0.3), 1.6, 0.15))
	MatLib.register("l60_sea", MatLib.water({"shallow_color": Color(0.02, 0.05, 0.07), "deep_color": Color(0.005, 0.012, 0.02),
		"absorption": 0.12, "clarity": 0.5, "wave_height": 0.07, "wave_scale": 0.22, "wave_speed": 0.45, "foam_amount": 0.18,
		"dark_surface": 0.45}))


## Lamp state for a chunk lamp: 2 = working, 1 = flickering, 0 = broken / off.
static func lamp_state(seed_v: int, cx: int, i: int) -> int:
	if i < 0:
		return 2
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, cx, i, "lamp"])
	var v := r.randf()
	return 2 if v < 0.12 else (1 if v < 0.24 else 0)


## World x of the staircase (and its working lamp) in chunk cx.
static func stair_x(cx: int) -> float:
	return cx * CHUNK + STAIR_X


func chunk(cx: int, cz: int, node: Node3D, seed_v: int, avoid_x := INF) -> Dictionary:
	var meta := {"lamps": [], "benches": []}
	if cz != 0:
		return meta
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, cx, "coast"])
	var x0 := cx * CHUNK
	var x1 := x0 + CHUNK
	var xm := x0 + CHUNK * 0.5
	var k := GeoKit.new(node, "Coast")
	# inland: planting strip and a dead-grass embankment climbing into the dark
	k.slab(x0, -14.0, x1, -12.2, UP_Y + 0.3, 0.6, "l60_soil")
	k.box_mm(Vector3(x0, UP_Y, -12.35), Vector3(x1, UP_Y + 0.45, -12.0), "l60_curb")
	k.ramp(Vector3(xm, UP_Y + 0.3, -14.0), Vector3(xm, 14.0, -40.0), CHUNK, 1.0, "l60_grass")
	k.ramp(Vector3(xm, 14.0, -40.0), Vector3(xm, 30.0, -90.0), CHUNK, 1.0, "l60_grass")
	# the Upper Area: new concrete bay walk with a granite edge
	k.slab(x0, -12.0, x1, 0.0, UP_Y, 0.5, "l60_pavers")
	k.box_mm(Vector3(x0, UP_Y - 0.5, -0.35), Vector3(x1, UP_Y + 0.02, 0.0), "l60_curb", GeoKit.ALL, false)
	for i in 10:
		k.box(Vector3(x0 + 5.0 + i * 10.0, UP_Y + 0.004, -6.0), Vector3(0.03, 0.004, 12.0), "l60_curb", GeoKit.PY, false)
	# retaining wall down to the Lower Area, with drain outlets and stains
	k.box_mm(Vector3(x0, LOW_Y - 0.6, 0.0), Vector3(x1, UP_Y - 0.5, 0.45), "l60_wall")
	for i in 8:
		var dx := x0 + 6.0 + i * 12.5
		if absf(dx - (x0 + STAIR_X + 3.3)) < 5.0:
			continue
		k.cylinder(Vector3(dx, LOW_Y + 0.9, 0.5), 0.12, 0.2, "l60_rust", 10, false)
	# the Lower Area: unfinished dirt path, then the beach slope into the sea
	k.slab(x0, 0.45, x1, 7.0, LOW_Y, 1.4, "l60_dirt")
	k.ramp(Vector3(xm, LOW_Y, 7.0), Vector3(xm, BED_Y, 13.0), CHUNK, 1.2, "l60_wet_sand")
	_railing(k, x0, x1)
	_stairs(k, x0)
	for i in LAMP_XS.size():
		var st := lamp_state(seed_v, cx, i)
		var lx: float = x0 + LAMP_XS[i]
		lamp(k, node, Vector3(lx, UP_Y, -0.75), st, r)
		meta["lamps"].append({"pos": Vector3(lx, UP_Y + 6.1, 0.15), "state": st})
	var sl := Vector3(x0 + STAIR_X + 7.5, UP_Y, -0.75)
	lamp(k, node, sl, 2, r)
	meta["lamps"].append({"pos": sl + Vector3(0, 6.1, 0.9), "state": 2})
	for bx in BENCH_XS:
		var bp := Vector3(x0 + float(bx), UP_Y, -11.2)
		bench(k, bp)
		meta["benches"].append(bp)
		k.cylinder(bp + Vector3(1.6, 0.45, 0.1), 0.24, 0.9, "l60_steel", 12, true)
		k.cylinder(bp + Vector3(1.6, 0.92, 0.1), 0.27, 0.05, "l60_curb", 12, false)
	# a drinking fountain that gives nothing (SOURCE: zero water/food supply up here)
	var fp := Vector3(x0 + 45.0, UP_Y, -11.7)
	k.box(fp + Vector3(0, 0.45, 0), Vector3(0.4, 0.9, 0.4), "l60_curb")
	k.box(fp + Vector3(0, 0.93, -0.05), Vector3(0.46, 0.06, 0.36), "l60_steel", GeoKit.ALL, false)
	L.make_interactable(fp + Vector3(0, 1.0, 0.1), Vector3(0.5, 0.3, 0.5), "Press the drinking fountain's button",
		func(_p: Player) -> void: Overlay.subtitle("[the tap coughs once. Nothing comes. There is no water up here.]", 3.0), node)
	for i in 6:
		var px := x0 + 8.0 + i * 16.0
		if absf(px - (x0 + STAIR_X + 7.5)) < 3.0:
			continue
		k.cylinder(Vector3(px, UP_Y + 0.45, -12.6 if i % 2 == 0 else -0.9), 0.11, 0.9, "l60_curb", 10, true)
	for i in 3:
		Props.place(L, node, "kenney/city-kit-suburban/planter", Vector3(x0 + 30.0 + i * 20.0 + r.randf_range(-3, 3), UP_Y + 0.3, -13.1), 0.0, 0.7)
	_equipment(k, node, x0, r, avoid_x)
	if avoid_x >= x0 and avoid_x < x1:
		meta["hideout"] = hideout(k, node, avoid_x)
	k.commit()
	return meta


func _railing(k: GeoKit, x0: float, x1: float) -> void:
	var gap0 := x0 + STAIR_X + 6.6
	var gap1 := gap0 + 1.8
	var spans := [[x0, gap0], [gap1, x1]]
	for sp in spans:
		var a: float = sp[0]
		var b: float = sp[1]
		k.box_mm(Vector3(a, UP_Y + 1.02, -0.22), Vector3(b, UP_Y + 1.1, -0.1), "l60_steel")
		k.box_mm(Vector3(a, UP_Y + 0.5, -0.18), Vector3(b, UP_Y + 0.54, -0.14), "l60_steel", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), Vector3((a + b) * 0.5, UP_Y + 0.55, -0.16)), Vector3(b - a, 1.1, 0.1), "metal")
		var n := int((b - a) / 2.0)
		for i in n + 1:
			k.box(Vector3(a + i * (b - a) / maxf(n, 1), UP_Y + 0.55, -0.16), Vector3(0.05, 1.1, 0.05), "l60_steel", GeoKit.ALL, false)


func _stairs(k: GeoKit, x0: float) -> void:
	# SOURCE: staircases between the areas, about 100 m apart, safe to use
	var sx := x0 + STAIR_X
	var top := sx + STAIR_RUN * STAIR_STEPS
	k.stairs(Vector3(sx, LOW_Y, 1.35), Vector3(1, 0, 0), 1.6, UP_Y - LOW_Y, STAIR_STEPS, "l60_curb", STAIR_RUN)
	k.box_mm(Vector3(top, LOW_Y, 0.45), Vector3(top + 1.8, UP_Y, 2.15), "l60_curb")
	k.box_mm(Vector3(top, UP_Y - 0.5, -0.01), Vector3(top + 1.8, UP_Y, 0.46), "l60_pavers")
	k.box_mm(Vector3(top + 1.8, LOW_Y, 0.45), Vector3(top + 1.95, UP_Y + 1.1, 2.15), "l60_steel")
	k.box_mm(Vector3(top, UP_Y, 2.1), Vector3(top + 1.95, UP_Y + 1.1, 2.2), "l60_steel")
	k.box_mm(Vector3(sx - 0.2, LOW_Y, 2.15), Vector3(top + 1.95, LOW_Y + 0.25, 2.3), "l60_curb", GeoKit.ALL, false)
	# handrail on the open side: posts and a sloped rail
	for i in 6:
		var px := sx + 0.3 + i * (STAIR_RUN * STAIR_STEPS - 0.6) / 5.0
		var py := LOW_Y + (px - sx) / (STAIR_RUN * STAIR_STEPS) * (UP_Y - LOW_Y)
		k.box(Vector3(px, py + 0.5, 2.12), Vector3(0.05, 1.0, 0.05), "l60_steel", GeoKit.ALL, false)
	var a := Vector3(sx, LOW_Y + 1.0, 2.12)
	var b := Vector3(top, UP_Y + 1.0, 2.12)
	var z := (b - a).normalized()
	var xv := Vector3.UP.cross(z).normalized()
	k.box_xf(Transform3D(Basis(xv, z.cross(xv), z), (a + b) * 0.5), Vector3(0.06, 0.06, (b - a).length()), "l60_steel", GeoKit.ALL, false)


func lamp(k: GeoKit, node: Node3D, base: Vector3, state: int, r: RandomNumberGenerator) -> void:
	k.cylinder(base + Vector3(0, 0.15, 0), 0.22, 0.3, "l60_curb", 10, true)
	k.cylinder(base + Vector3(0, 3.2, 0), 0.075, 6.2, "l60_steel", 8, false)
	k.box(base + Vector3(0, 6.25, 0.45), Vector3(0.08, 0.08, 1.0), "l60_steel", GeoKit.ALL, false)
	var head := base + Vector3(0, 6.15, 0.9)
	if state == 0 and r.randf() < 0.35:
		# head snapped and hanging off the arm
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, 1.1), head + Vector3(0, -0.25, 0.1)), Vector3(0.3, 0.16, 0.6), "l60_steel", GeoKit.ALL, false)
		return
	k.box(head, Vector3(0.32, 0.14, 0.6), "l60_steel", GeoKit.ALL, false)
	var mat := "l60_lamp_on" if state == 2 else ("l60_lamp_flick" if state == 1 else "l60_lamp_off")
	k.box(head + Vector3(0, -0.08, 0), Vector3(0.26, 0.02, 0.5), mat, GeoKit.ALL, false)


func bench(k: GeoKit, p: Vector3) -> void:
	for dx in [-0.75, 0.75]:
		k.box(p + Vector3(dx, 0.22, 0), Vector3(0.18, 0.44, 0.55), "l60_curb")
	for i in 4:
		k.box(p + Vector3(0, 0.46, -0.2 + i * 0.13), Vector3(1.9, 0.04, 0.1), "l60_wood", GeoKit.ALL, false)
	for i in 3:
		k.box(p + Vector3(0, 0.62 + i * 0.13, 0.33), Vector3(1.9, 0.1, 0.04), "l60_wood", GeoKit.ALL, false)


## SOURCE: many items and pieces of construction equipment scattered along the
## unfinished Lower Area; no barrier on the sea side.
func _equipment(k: GeoKit, node: Node3D, x0: float, r: RandomNumberGenerator, avoid_x: float) -> void:
	var picks := ["ph/concrete_road_barrier", "ph/wooden_crate_01", "ph/Barrel_01", "ph/old_tyre", "ph/portable_generator",
		"ph/propane_tank", "ph/metal_tool_chest", "ph/hand_truck", "ph/wooden_ladder", "kenney/city-kit-roads/construction-cone",
		"kenney/city-kit-roads/construction-cone", "ph/concrete_road_barrier", "ph/plastic_bottle_gallon", "ph/barrel_03"]
	var heights := {"kenney/city-kit-roads/construction-cone": 0.7}
	var n := r.randi_range(9, 13)
	for i in n:
		var x := x0 + r.randf_range(2.0, 98.0)
		if x > x0 + STAIR_X - 1.5 and x < x0 + STAIR_X + 9.0:
			x += 12.0
		if absf(x - avoid_x) < 6.0:
			x += 13.0 if x > avoid_x else -13.0
		var id: String = picks[r.randi() % picks.size()]
		var z := r.randf_range(2.6, 6.2) if id != "ph/wooden_ladder" else 0.8
		var big := id in ["ph/concrete_road_barrier", "ph/wooden_crate_01", "ph/portable_generator", "ph/Barrel_01", "ph/barrel_03", "ph/metal_tool_chest"]
		var yaw := r.randf_range(0, 360) if id != "ph/wooden_ladder" else 0.0
		Props.place(L, node, id, Vector3(x, LOW_Y, z), yaw, float(heights.get(id, 0.0)), big)
	# formwork and rebar where a slab was never poured
	var fx := x0 + r.randf_range(10.0, 35.0)
	k.box_mm(Vector3(fx, LOW_Y, 1.0), Vector3(fx + 6.0, LOW_Y + 0.25, 1.06), "l60_wood", GeoKit.ALL, false)
	k.box_mm(Vector3(fx, LOW_Y, 3.4), Vector3(fx + 6.0, LOW_Y + 0.25, 3.46), "l60_wood", GeoKit.ALL, false)
	k.box_mm(Vector3(fx, LOW_Y, 1.0), Vector3(fx + 2.5, LOW_Y + 0.2, 3.4), "l60_curb")
	for i in 9:
		k.box(Vector3(fx + 2.8 + i * 0.36, LOW_Y + 0.45, 2.2), Vector3(0.025, 0.9, 0.025), "l60_rust", GeoKit.ALL, false)
	# a pallet of cement sacks and a pile of sand
	var px := x0 + r.randf_range(64.0, 92.0)
	k.box(Vector3(px, LOW_Y + 0.07, 4.8), Vector3(1.2, 0.14, 1.0), "l60_wood", GeoKit.ALL, true)
	for i in 6:
		k.box(Vector3(px - 0.3 + (i % 2) * 0.6, LOW_Y + 0.24 + int(i / 2) * 0.16, 4.8), Vector3(0.55, 0.15, 0.9), "l60_bag", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI) * Basis(Vector3.RIGHT, 0.0), Vector3(px - 4.0, LOW_Y + 0.25, 5.2)), Vector3(2.2, 0.5, 1.6), "l60_wet_sand", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI), Vector3(px - 4.0, LOW_Y + 0.55, 5.2)), Vector3(1.2, 0.3, 0.9), "l60_wet_sand", GeoKit.ALL, false)
	# concrete drain pipes waiting to be laid, and a skip
	var cp := x0 + r.randf_range(4.0, 30.0)
	for i in 3:
		var pz := 5.1 + (i % 2) * 1.0
		var py := LOW_Y + 0.5 + int(i / 2) * 0.85
		k.box_xf(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(cp + (0.5 if i == 2 else 0.0), py, pz if i < 2 else 5.6)), Vector3(0.95, 2.4, 0.95), "l60_curb", GeoKit.ALL, i < 2)
	Props.place(L, node, "kenney/city-kit-roads/dumpster", Vector3(x0 + r.randf_range(64.0, 94.0), LOW_Y, 2.2), 0.0, 1.5, true)
	# things the sea has taken: on the bed, seen only through the water or at low tide
	var deb := Node3D.new()
	deb.name = "SeaDebris"
	node.add_child(deb)
	for i in 5:
		var id: String = ["ph/boulder_01", "ph/old_tyre", "ph/concrete_road_barrier", "ph/boulder_01", "ph/Barrel_01"][i]
		Props.place(L, deb, id, Vector3(x0 + r.randf_range(0.0, 100.0), BED_Y - 0.05, r.randf_range(14.0, 34.0)), r.randf_range(0, 360), 0.0, false)
	# a generator and a tool chest left by the wall
	var gx := x0 + r.randf_range(36.0, 45.0)
	Props.place(L, node, "ph/portable_generator", Vector3(gx, LOW_Y, 1.1), r.randf_range(-20, 20), 0.0, true)
	Props.place(L, node, "ph/metal_tool_chest", Vector3(gx + 1.3, LOW_Y, 0.8), r.randf_range(-10, 10), 0.0, true)


## The Brave's hiding spot (SOURCE: they build a secure hiding spot from the scattered
## equipment, live mostly in the Lower Area, report weekly to M.E.G. by radio).
func hideout(k: GeoKit, node: Node3D, x: float) -> Dictionary:
	var z0 := 0.6
	k.box_mm(Vector3(x - 3.0, LOW_Y, z0), Vector3(x + 3.0, LOW_Y + 2.6, z0 + 2.4), "l60_container")
	k.box_mm(Vector3(x - 3.05, LOW_Y + 2.6, z0 - 0.05), Vector3(x + 3.05, LOW_Y + 2.7, z0 + 2.45), "l60_steel", GeoKit.ALL, false)
	# a tarp lean-to off the container toward the sea, on scaffold poles
	var a := Vector3(x, LOW_Y + 2.6, z0 + 2.4)
	var b := Vector3(x, LOW_Y + 1.9, z0 + 5.2)
	var zz := (b - a).normalized()
	var xx := Vector3.UP.cross(zz).normalized()
	k.box_xf(Transform3D(Basis(xx, zz.cross(xx), zz), (a + b) * 0.5), Vector3(6.4, 0.03, (b - a).length()), "l60_tarp", GeoKit.ALL, false)
	for sx in [-3.0, 3.0]:
		k.cylinder(Vector3(x + sx, LOW_Y + 0.95, z0 + 5.1), 0.04, 1.9, "l60_steel", 8, true)
	# walls of stacked pallets and barrier blocks at both ends
	for sx in [-3.4, 3.4]:
		for i in 5:
			k.box(Vector3(x + sx, LOW_Y + 0.08 + i * 0.16, z0 + 3.6), Vector3(0.12, 0.14, 2.4), "l60_wood", GeoKit.ALL, i == 0)
		k.add_box_shape(Transform3D(Basis(), Vector3(x + sx, LOW_Y + 0.4, z0 + 3.6)), Vector3(0.14, 0.8, 2.4), "wood")
	for i in 2:
		k.box(Vector3(x - 1.6 + i * 3.2, LOW_Y + 0.05, z0 + 3.4), Vector3(0.8, 0.1, 1.9), "l60_cloth", GeoKit.ALL, false)
	k.box(Vector3(x, LOW_Y + 0.5, z0 + 3.0), Vector3(1.2, 0.04, 0.8), "l60_wood", GeoKit.ALL, false)
	k.box(Vector3(x - 0.3, LOW_Y + 2.3, z0 + 2.5), Vector3(0.14, 0.2, 0.14), "l60_lantern", GeoKit.ALL, false)
	Props.place(L, node, "ph/wooden_crate_01", Vector3(x, LOW_Y, z0 + 3.0), 0.0, 0.48, true)
	Props.place(L, node, "ph/vintage_radio_transceiver", Vector3(x + 0.2, LOW_Y + 0.52, z0 + 3.0), 180.0)
	Props.place(L, node, "ph/old_military_crate", Vector3(x + 2.0, LOW_Y, z0 + 2.75), 0.0, 0.0, true)
	Props.place(L, node, "ph/medical_box", Vector3(x + 2.0, LOW_Y + 0.3, z0 + 2.75), 20.0)
	Props.place(L, node, "ph/plastic_bottle_gallon", Vector3(x - 2.4, LOW_Y, z0 + 2.7), 0.0)
	Props.place(L, node, "ph/plastic_bottle_gallon", Vector3(x - 2.15, LOW_Y, z0 + 2.8), 40.0)
	Props.place(L, node, "ph/vintage_flashlight", Vector3(x - 0.5, LOW_Y + 0.52, z0 + 3.1), 70.0)
	Props.place(L, node, "ph/portable_generator", Vector3(x + 2.6, LOW_Y, z0 + 4.6), -20.0, 0.0, true)
	Props.place(L, node, "ph/vintage_suitcase", Vector3(x - 1.6, LOW_Y + 0.1, z0 + 4.3), 90.0)
	return {"radio": Vector3(x + 0.2, LOW_Y + 0.75, z0 + 3.0), "table": Vector3(x, LOW_Y + 0.52, z0 + 3.0), "lantern": Vector3(x - 0.3, LOW_Y + 2.1, z0 + 2.6)}
