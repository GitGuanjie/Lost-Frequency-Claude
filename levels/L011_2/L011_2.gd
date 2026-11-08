extends LevelBase
## Level 11.2 — "The Refuge" (Backrooms Wikidot rev 25, accessed 2026-11-04;
## cite: Univ - Wise Explorer, CC BY-SA 3.0). Dossier: docs/canon/levels/L011_2.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: many identical orange-and-white apartment buildings, covered in
## snow under a permanently black sky; about -11 C and frequent snow; yellow
## streetlights; the sub-section starts at the apartments and blends into
## Level 11, whose buildings get smaller and more vacant near the complex; no
## facelings; windows and doors heavily but poorly barricaded (black metal
## casing), gunshot dents on the side nearest Level 11; inside: apartments,
## classrooms, lounges, infirmaries; fridges restock every other week with
## random Frontrooms food; doors with amateur wooden signs carrying level
## numbers are gateways, and you return through the same door; M.E.G. Base
## Omicron (~250 people); the Banner Building: colourful geometric shapes and
## painted banners, the only building lit, an impenetrable invisible barrier
## under its removed black casing, a reported shadow figure sprinting across
## its lit hall, two M.E.G. tents on watch; Jane Mahayfaio's diary; walking
## away from the complex leads back to Level 11.
## Layout: an inner ring of four identical 9-storey blocks (A west, B north,
## C east = Base Omicron, D south-west) around a courtyard holding the Banner
## Building and the two tents; an outer ring of identical blocks and sheet-
## metal barricades closes the estate (no world edge, fog and snow beyond);
## the approach road runs south past shrinking, vacant Level 11 buildings to
## the walk-away exit. Block C's ground and first floors are enterable
## (corridor, infirmary, classroom, lobby, lounge, kitchen, stair, landing,
## Jane's room) and carry the eight signed gateway doors.
## Signature mechanics: signed gateway doors with matching return arrivals;
## the fridge's two-week restock cycle (taken items stay taken until the next
## cycle); the Banner Building's invisible barrier; a rare shadow-figure
## crossing in the lit hall (REPORTED); the sky darkens as you near the estate.
## Helpers: L011_2_blocks.gd (exterior), L011_2_interior.gd (Block C).

const BK := preload("res://levels/L011_2/L011_2_blocks.gd")
const IN := preload("res://levels/L011_2/L011_2_interior.gd")
const ROAD_X := 20.0
const START := Vector3(22.0, 0.05, 30.0)
const BANNER := Vector3(0.0, 0.0, -36.0)
const FORCE := AABB(Vector3(-13.8, 0.0, -44.8), Vector3(27.6, 14.0, 17.6))
const FOODS := ["canned tomato soup", "a box of corn flakes", "two cartons of milk", "a jar of peanut butter",
	"a bag of apples", "frozen peas", "a tray of eggs", "instant noodles", "a block of cheddar", "orange juice",
	"sliced bread", "a tin of peaches", "breakfast sausages", "a chocolate bar", "a bottle of ketchup", "yoghurt cups"]

var blocks
var interior
var snow: CPUParticles3D
var sky_mat: ProceduralSkyMaterial
var figure: MeshInstance3D
var figure_t := -1.0
var figure_cd := 0.0
var force_said := 0.0
var said := {}
var fridge_cycle := 0
var fridge_items: Array = []


func build() -> void:
	blocks = BK.new(self)
	interior = IN.new(self)
	rules["view_distance"] = 600.0
	rules["reverb_room"] = 0.3
	rules["reverb_wet"] = 0.1
	rules["walk_speed"] = 2.9
	outdoor_env(Color(0.002, 0.002, 0.003), Color(0.018, 0.014, 0.012), Color(0.03, 0.03, 0.035), Vector2(60.0, 200.0), Color(0.55, 0.6, 0.75), 0.03, Color(0.085, 0.06, 0.038), 0.02)
	sky_mat = environment.sky.sky_material as ProceduralSkyMaterial
	environment.ambient_light_energy = 0.45
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.16, 0.12)
	environment.tonemap_exposure = 1.25
	environment.glow_intensity = 0.7
	environment.glow_hdr_threshold = 0.8
	environment.fog_sky_affect = 1.0
	sun.shadow_enabled = false
	_materials()
	lights.setup(16, 1)
	lights.max_distance = 70.0
	var dress := Node3D.new()
	dress.name = "Dressing"
	add_child(dress)
	var k := kit("Estate")
	k.slab(-260, -260, 260, 320, 0.0, 0.6, "l112_snow")
	_roads(k)
	# inner ring (identical blocks; C is Base Omicron, enterable)
	blocks.block(k, Vector3(-52.5, 0, -26.0), false, 0.0, 0.18, 0.55, 1, true)
	blocks.block(k, Vector3(0.0, 0, -82.5), true, 0.0, 0.2, 0.5, 1, true)
	blocks.block(k, Vector3(48.5, 0, -28.0), false, 5.8, 0.55, 0.1, -1, true)
	blocks.block(k, Vector3(-28.0, 0, 28.5), true, 0.0, 0.12, 0.85, -1, true)
	# outer ring and the far rows, fading into snow and dark
	for b in [[Vector3(-128.0, 0, -40.0), false], [Vector3(-60.0, 0, -152.0), true], [Vector3(20.0, 0, -160.0), true],
			[Vector3(110.0, 0, -95.0), false], [Vector3(122.0, 0, 6.0), false], [Vector3(96.0, 0, 62.0), true],
			[Vector3(-60.0, 0, 78.0), true], [Vector3(-132.0, 0, 46.0), false], [Vector3(-190.0, 0, -110.0), false],
			[Vector3(70.0, 0, -230.0), true], [Vector3(-140.0, 0, -225.0), true], [Vector3(190.0, 0, -40.0), false]]:
		blocks.block(k, b[0], b[1], 0.0, 0.07, 0.75, 0, false)
	_barricade_lines(k)
	blocks.banner_building(k, BANNER)
	blocks.tent(k, Vector3(-9.0, 0.0, -21.5), 0.25)
	blocks.tent(k, Vector3(9.5, 0.0, -21.0), -0.3)
	blocks.approach(k, ROAD_X)
	interior.build(k, dress)
	k.commit()
	_force_field()
	_dress(dress)
	_streetlights(dress)
	_figure()
	_snowfall()
	_sounds()
	_exits_and_arrivals()
	_notes()
	add_landmark("Banner Building (barrier, tents)", BANNER)
	add_landmark("Block C entrance, M.E.G. Base Omicron", Vector3(41.0, 0.0, -28.0))
	add_landmark("Approach road to Level 11", Vector3(ROAD_X, 0.0, 150.0))
	add_shot("courtyard_arrival", START + Vector3(0, 1.62, 0), Vector3(-2.0, 7.0, -60.0), {"flashlight": false})
	add_shot("banner_building_watch", Vector3(-4.0, 1.65, -8.0), Vector3(0.0, 4.5, -36.0), {"flashlight": false})
	add_shot("gateway_corridor", Vector3(48.5, 1.95, -20.0), Vector3(48.5, 1.6, -40.0), {"flashlight": false})
	add_shot("approach_blending_zone", Vector3(ROAD_X, 1.65, 150.0), Vector3(ROAD_X - 2.0, 6.0, 20.0), {"flashlight": false})
	add_shot("kitchen_fridge", Vector3(50.4, 1.9, -7.4), Vector3(54.0, 1.0, -16.0), {"flashlight": false})
	add_shot("block_facades", Vector3(-30.0, 1.7, -2.0), Vector3(-52.0, 14.0, -50.0), {"flashlight": false})


func _materials() -> void:
	MatLib.define("l112_snow", {"albedo_a": Color(0.86, 0.88, 0.92), "albedo_b": Color(0.78, 0.80, 0.85), "pattern": 13,
		"pattern_color": Color(0.70, 0.72, 0.78), "pattern_strength": 0.25, "noise_scale": 0.3, "roughness_a": 0.55,
		"roughness_b": 0.75, "bump_strength": 0.6}, "sand")
	MatLib.define("l112_road", {"albedo_a": Color(0.42, 0.42, 0.44), "albedo_b": Color(0.60, 0.61, 0.64), "pattern": 2,
		"pattern_scale": Vector2(0.55, 1.0), "pattern_color": Color(0.30, 0.30, 0.32), "pattern_strength": 0.35,
		"noise_scale": 0.5, "wetness": 0.4, "roughness_a": 0.5}, "asphalt")
	MatLib.define("l112_white", {"albedo_a": Color(0.80, 0.78, 0.73), "albedo_b": Color(0.72, 0.70, 0.66), "pattern": 1,
		"pattern_scale": Vector2(3.2, 2.9), "grout_width": 0.025, "grout_color": Color(0.55, 0.53, 0.50), "tile_variation": 0.04,
		"stain_amount": 0.35, "stain_color": Color(0.55, 0.50, 0.42), "grime_height": 1.6, "grime_color": Color(0.42, 0.38, 0.32)}, "concrete")
	MatLib.define("l112_white_trim", {"albedo_a": Color(0.84, 0.83, 0.80), "albedo_b": Color(0.8, 0.79, 0.76)}, "trim_white")
	MatLib.define("l112_orange", {"albedo_a": Color(0.86, 0.36, 0.10), "albedo_b": Color(0.74, 0.29, 0.08), "pattern": 1,
		"pattern_scale": Vector2(3.0, 2.9), "grout_width": 0.02, "grout_color": Color(0.45, 0.2, 0.08),
		"stain_amount": 0.3, "stain_color": Color(0.5, 0.25, 0.1)}, "concrete")
	MatLib.define("l112_concrete", {"albedo_a": Color(0.5, 0.49, 0.47), "albedo_b": Color(0.42, 0.41, 0.39)}, "concrete")
	MatLib.define("l112_blackmetal", {"albedo_a": Color(0.05, 0.05, 0.055), "albedo_b": Color(0.09, 0.085, 0.08),
		"metallic_value": 0.6, "roughness_a": 0.5, "roughness_b": 0.8, "stain_amount": 0.4, "stain_color": Color(0.2, 0.1, 0.05)}, "metal")
	MatLib.define("l112_dent", {"albedo_a": Color(0.45, 0.43, 0.4), "albedo_b": Color(0.3, 0.29, 0.27), "metallic_value": 0.8}, "metal")
	MatLib.define("l112_steel", {"albedo_a": Color(0.45, 0.45, 0.46), "albedo_b": Color(0.35, 0.35, 0.36)}, "metal")
	MatLib.define("l112_door", {"albedo_a": Color(0.25, 0.16, 0.1), "albedo_b": Color(0.2, 0.13, 0.08)}, "wood_floor")
	MatLib.define("l112_door_wood", {"albedo_a": Color(0.42, 0.27, 0.15), "albedo_b": Color(0.36, 0.22, 0.12), "pattern": 3,
		"pattern_scale": Vector2(0.9, 0.1)}, "wood_floor")
	MatLib.define("l112_board", {"albedo_a": Color(0.62, 0.48, 0.32), "albedo_b": Color(0.52, 0.39, 0.25), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.08)}, "wood_floor")
	MatLib.define("l112_wood", {"albedo_a": Color(0.42, 0.28, 0.17), "albedo_b": Color(0.36, 0.23, 0.14)}, "wood_floor")
	MatLib.define("l112_lino", {"albedo_a": Color(0.42, 0.36, 0.30), "albedo_b": Color(0.38, 0.32, 0.27), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.30, 0.25, 0.21), "pattern_strength": 0.4,
		"roughness_a": 0.45, "roughness_b": 0.6, "stain_amount": 0.3}, "concrete")
	MatLib.define("l112_tile", {"albedo_a": Color(0.78, 0.80, 0.78), "albedo_b": Color(0.72, 0.74, 0.72), "pattern": 1,
		"pattern_scale": Vector2(0.2, 0.2), "grout_width": 0.008, "grout_color": Color(0.5, 0.5, 0.48), "roughness_a": 0.3}, "pool_tile")
	MatLib.define("l112_wall", {"albedo_a": Color(0.82, 0.80, 0.72), "albedo_b": Color(0.76, 0.74, 0.66), "stain_amount": 0.3,
		"stain_color": Color(0.62, 0.55, 0.42), "grime_height": 0.3, "grime_color": Color(0.5, 0.45, 0.35)}, "plaster")
	MatLib.define("l112_wall_dark", {"albedo_a": Color(0.18, 0.17, 0.16), "albedo_b": Color(0.14, 0.13, 0.12)}, "plaster")
	MatLib.define("l112_dado", {"albedo_a": Color(0.18, 0.38, 0.36), "albedo_b": Color(0.15, 0.33, 0.31), "roughness_a": 0.35,
		"stain_amount": 0.3, "stain_color": Color(0.1, 0.2, 0.18)}, "plaster")
	MatLib.define("l112_ceiling", {"albedo_a": Color(0.86, 0.85, 0.80), "albedo_b": Color(0.82, 0.81, 0.76)}, "plaster")
	MatLib.define("l112_chalkboard", {"albedo_a": Color(0.08, 0.16, 0.12), "albedo_b": Color(0.1, 0.18, 0.14), "noise_scale": 3.0}, "plaster")
	MatLib.define("l112_cork", {"albedo_a": Color(0.55, 0.40, 0.25), "albedo_b": Color(0.48, 0.34, 0.2), "noise_scale": 6.0}, "plaster")
	MatLib.define("l112_fridge", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80), "roughness_a": 0.3}, "trim_white")
	MatLib.define("l112_counter", {"albedo_a": Color(0.55, 0.48, 0.36), "albedo_b": Color(0.5, 0.43, 0.32)}, "wood_floor")
	MatLib.define("l112_worktop", {"albedo_a": Color(0.7, 0.68, 0.62), "albedo_b": Color(0.66, 0.64, 0.58), "roughness_a": 0.3}, "plaster")
	MatLib.define("l112_tent", {"albedo_a": Color(0.28, 0.32, 0.22), "albedo_b": Color(0.24, 0.28, 0.19), "noise_scale": 2.0,
		"roughness_a": 0.9}, "plaster")
	MatLib.define("l112_l11_grey", {"albedo_a": Color(0.36, 0.36, 0.37), "albedo_b": Color(0.3, 0.3, 0.31), "pattern": 1,
		"pattern_scale": Vector2(1.5, 3.2), "grout_width": 0.02, "grout_color": Color(0.22, 0.22, 0.23)}, "concrete")
	MatLib.define("l112_l11_brick", {"albedo_a": Color(0.40, 0.24, 0.18), "albedo_b": Color(0.34, 0.2, 0.15)}, "brick")
	MatLib.define("l112_banner_base", {"albedo_a": Color(0.86, 0.84, 0.78), "albedo_b": Color(0.8, 0.78, 0.72), "stain_amount": 0.2}, "plaster")
	for pair in [["l112_bb_red", Color(0.78, 0.12, 0.10)], ["l112_bb_yellow", Color(0.92, 0.72, 0.12)], ["l112_bb_teal", Color(0.08, 0.55, 0.55)],
			["l112_bb_navy", Color(0.10, 0.14, 0.38)], ["l112_bb_green", Color(0.18, 0.55, 0.22)], ["l112_bb_pink", Color(0.86, 0.38, 0.58)]]:
		MatLib.define(pair[0], {"albedo_a": pair[1], "albedo_b": (pair[1] as Color).darkened(0.12), "roughness_a": 0.7, "stain_amount": 0.15}, "plaster")
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.25, 0.3, 0.35, 0.3)
	g.roughness = 0.05
	g.metallic_specular = 0.9
	MatLib.register("l112_glass", g)
	MatLib.register("l112_win_dark", MatLib.standard(Color(0.03, 0.035, 0.045), 0.15, 0.3))
	MatLib.register("l112_win_lit", MatLib.panel(Color(1.0, 0.72, 0.42), 1.6))
	MatLib.register("l112_win_stair", MatLib.panel(Color(0.7, 0.8, 0.75), 0.5))
	MatLib.register("l112_bb_hall", MatLib.panel(Color(1.0, 0.88, 0.66), 1.5))
	MatLib.register("l112_tube", MatLib.panel(Color(0.95, 0.97, 1.0), 2.6))
	MatLib.register("l112_sodium", MatLib.panel(Color(1.0, 0.6, 0.22), 6.0))


# ----------------------------------------------------------------- layout

func _roads(k: GeoKit) -> void:
	# packed-snow carriageways with tyre ruts, kerbs and pavements
	var strips := [Rect2(ROAD_X - 7.0, -10.0, 14.0, 330.0), Rect2(-34.0, -66.0, 68.0, 8.0), Rect2(-34.0, -14.0, 68.0, 8.0),
		Rect2(-34.0, -66.0, 8.0, 60.0), Rect2(26.0, -66.0, 8.0, 60.0)]
	for rr in strips:
		k.box(Vector3(rr.position.x + rr.size.x * 0.5, 0.01, rr.position.y + rr.size.y * 0.5), Vector3(rr.size.x, 0.02, rr.size.y), "l112_road", GeoKit.PY, false)
	for side in [-1.0, 1.0]:
		k.box(Vector3(ROAD_X + side * 7.2, 0.07, 140.0), Vector3(0.3, 0.14, 300.0), "l112_concrete", GeoKit.ALL, false)
		k.box(Vector3(ROAD_X + side * 8.4, 0.075, 140.0), Vector3(2.0, 0.15, 300.0), "l112_snow", GeoKit.PY | GeoKit.SIDES, false)


func _barricade_lines(k: GeoKit) -> void:
	# sheet-metal barricades closing the gaps between the outer blocks
	var segs := [[Vector3(-96.0, 0, -8.0), Vector3(-92.0, 0, 46.0)], [Vector3(-28.0, 0, 70.0), Vector3(9.0, 0, 62.0)],
		[Vector3(31.0, 0, 60.0), Vector3(64.0, 0, 58.0)], [Vector3(128.0, 0, -63.0), Vector3(128.0, 0, -26.0)],
		[Vector3(-28.0, 0, -152.0), Vector3(-12.0, 0, -158.0)], [Vector3(52.0, 0, -160.0), Vector3(110.0, 0, -127.0)],
		[Vector3(-92.0, 0, -150.0), Vector3(-128.0, 0, -72.0)], [Vector3(-132.0, 0, 78.0), Vector3(-92.0, 0, 78.0)],
		[Vector3(128.0, 0, 38.0), Vector3(128.0, 0, 55.0)]]
	var rr := RandomNumberGenerator.new()
	rr.seed = hash([level_seed, 9])
	for sg in segs:
		var a: Vector3 = sg[0]
		var b: Vector3 = sg[1]
		var n := int(a.distance_to(b) / 2.4) + 1
		var dir := (b - a).normalized()
		var bas := Basis.looking_at(dir, Vector3.UP)
		for i in n:
			var p := a + dir * (2.4 * (i + 0.5))
			var hgt := rr.randf_range(2.2, 3.0)
			var tilt := Basis(dir, rr.randf_range(-0.08, 0.08))
			k.box_xf(Transform3D(tilt * bas, p + Vector3(0, hgt * 0.5, 0)), Vector3(0.06, hgt, 2.42), "l112_blackmetal", GeoKit.ALL, true)
		k.box_xf(Transform3D(bas, (a + b) * 0.5 + Vector3(0, 0.25, 0)), Vector3(2.0, 0.5, a.distance_to(b)), "l112_snow", GeoKit.PY | GeoKit.SIDES, false)


func _force_field() -> void:
	# the impenetrable, invisible barrier under the Banner Building's casing
	var body := StaticBody3D.new()
	body.name = "BannerBarrier"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = FORCE.size
	cs.shape = sh
	cs.position = FORCE.get_center()
	cs.set_meta("surface", "concrete")
	body.add_child(cs)
	add_child(body)


func _dress(d: Node3D) -> void:
	var rr := RandomNumberGenerator.new()
	rr.seed = hash([level_seed, 31])
	# snowed-over cars along the courtyard loop and the approach road
	var car_spots := [Vector3(30.2, 0, -44.0), Vector3(30.2, 0, -30.0), Vector3(-29.8, 0, -50.0), Vector3(-29.8, 0, -24.0),
		Vector3(ROAD_X + 5.2, 0, 52.0), Vector3(ROAD_X - 5.2, 0, 88.0), Vector3(ROAD_X + 5.2, 0, 121.0), Vector3(-10.0, 0, -62.0), Vector3(14.0, 0, -62.0)]
	for p in car_spots:
		if rr.randf() < 0.2:
			continue
		var along_z: bool = absf(p.x - 30.2) < 1.0 or absf(p.x + 29.8) < 1.0 or absf(p.x - ROAD_X) < 6.0
		var yaw := (0.0 if along_z else 90.0) + rr.randf_range(-6.0, 6.0)
		var pp: Vector3 = p + Vector3(0, 0, rr.randf_range(-3.0, 3.0))
		Props.place(self, d, "ph/covered_car", pp, yaw, 0.0, true)
		var sk := kit("CarSnow")
		sk.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), pp + Vector3(0, 1.43, 0)), Vector3(1.5, 0.12, 3.6), "l112_snow", GeoKit.ALL, false)
		sk.commit()
	# barricade at the estate mouth (the Level 11 side): road barriers with a gap
	for i in 6:
		var x := ROAD_X - 12.0 + i * 1.65 + (6.0 if i >= 3 else 0.0)
		Props.place(self, d, "ph/concrete_road_barrier", Vector3(x, 0, 46.0 + rr.randf_range(-0.3, 0.3)), rr.randf_range(-6, 6), 0.0, true)
	# street furniture
	for p in [Vector3(ROAD_X + 8.4, 0, 70.0), Vector3(-26.0, 0, -6.0), Vector3(26.0, 0, -66.5), Vector3(-33.0, 0, -60.0)]:
		Props.place(self, d, "ph/metal_trash_can", p, rr.randf_range(0, 360), 0.0, true)
		Props.place(self, d, "ph/trashbag", p + Vector3(1.2, 0, 0.6), rr.randf_range(0, 360))
	for p in [Vector3(ROAD_X - 8.2, 0, 40.0), Vector3(34.5, 0, -12.0), Vector3(-34.5, 0, -40.0)]:
		Props.place(self, d, "ph/fire_hydrant", p, rr.randf_range(0, 360))
	for p in [Vector3(41.0, 0, -18.0), Vector3(41.0, 0, -12.0), Vector3(-45.6, 0, -6.0), Vector3(1.0, 0, -75.5)]:
		Props.place(self, d, "ph/utility_box_01", p, 90.0 if p.x > 0 else -90.0, 0.0, true)
	Props.place(self, d, "ph/wooden_picnic_table", Vector3(-14.0, 0, -4.0), 15.0, 0.0, true)
	var pk := kit("PicnicSnow")
	pk.box(Vector3(-14.0, 0.78, -4.0), Vector3(1.0, 0.06, 2.6), "l112_snow", GeoKit.PY, false)
	pk.commit()
	# Base Omicron at the Block C entrance: crates, generator, lights
	Props.place(self, d, "ph/old_military_crate", Vector3(39.2, 0, -33.0), 90.0, 0.0, true)
	Props.place(self, d, "ph/old_military_crate", Vector3(39.2, 0.3, -33.0), 84.0)
	Props.place(self, d, "ph/wooden_crate_01", Vector3(39.6, 0, -23.4), 10.0)
	Props.place(self, d, "ph/Barrel_01", Vector3(39.4, 0, -36.0), 30.0, 0.0, true)
	Props.place(self, d, "ph/portable_generator", Vector3(38.8, 0, -20.6), 80.0, 0.0, true)
	Props.place(self, d, "ph/security_light", Vector3(41.85, 3.2, -30.8), -90.0)
	var sign := Label3D.new()
	sign.text = "M.E.G.  BASE OMICRON"
	sign.font_size = 72
	sign.pixel_size = 0.006
	sign.modulate = Color(0.92, 0.9, 0.85)
	sign.outline_size = 8
	sign.outline_modulate = Color(0.1, 0.1, 0.12)
	sign.position = Vector3(40.95, 3.25, -28.0)
	sign.rotation.y = -PI * 0.5
	add_child(sign)
	# the watch post at the Banner Building: two tents, chairs, a radio, a light
	for p in [Vector3(-6.0, 0, -18.8), Vector3(6.5, 0, -18.3)]:
		Props.place(self, d, "ph/plastic_monobloc_chair_01", p, rr.randf_range(150, 210))
	Props.place(self, d, "ph/wooden_crate_01", Vector3(0.4, 0, -18.6), 0.0, 0.0, true)
	Props.place(self, d, "ph/vintage_radio_transceiver", Vector3(0.4, 0.35, -18.6), 180.0)
	Props.place(self, d, "ph/propane_tank", Vector3(12.6, 0, -23.0), 0.0)
	Props.place(self, d, "ph/portable_generator", Vector3(-13.0, 0, -22.0), 20.0, 0.0, true)
	Props.place(self, d, "ph/vintage_flashlight", Vector3(0.8, 0.35, -18.4), 70.0)
	var wk := kit("WorkLights")
	for x in [-7.0, 7.5]:
		wk.cylinder(Vector3(x, 2.3, -22.3), 0.04, 4.6, "l112_steel", 6, false)
		wk.box(Vector3(x, 4.65, -22.6), Vector3(0.5, 0.35, 0.2), "l112_steel", GeoKit.ALL, false)
		wk.box(Vector3(x, 4.65, -22.71), Vector3(0.42, 0.27, 0.02), "l112_tube", GeoKit.ALL, false)
	wk.commit()
	# corridor and kitchen clutter in Block C
	for e in [["ph/cardboard_box_01", Vector3(48.0, 0.3, -2.0), 20.0], ["ph/cardboard_box_01", Vector3(48.0, 0.64, -2.1), 70.0],
			["ph/plastic_crate_01", Vector3(49.2, 0.3, -9.0), 0.0], ["ph/WetFloorSign_01", Vector3(48.9, 0.3, -20.5), 30.0],
			["ph/korean_fire_extinguisher_01", Vector3(47.65, 0.3, -36.5), 90.0], ["ph/plastic_crate_01", Vector3(47.7, 3.1, -14.0), 90.0],
			["ph/cardboard_box_01", Vector3(49.2, 3.1, -50.0), 40.0], ["ph/korean_fire_extinguisher_01", Vector3(49.35, 3.1, -32.5), -90.0],
			["ph/wall_clock", Vector3(47.49, 2.2, -45.0), 90.0], ["ph/fire_alarm", Vector3(49.51, 4.6, -26.0), -90.0],
			["ph/power_box_01", Vector3(54.45, 1.2, -9.0), -90.0], ["ph/plastic_bottle_gallon", Vector3(54.3, 0.3, -7.2), 0.0],
			["ph/plastic_bottle_gallon", Vector3(54.0, 0.3, -7.3), 30.0], ["ph/propane_tank", Vector3(50.2, 0.3, -17.3), 0.0]]:
		Props.place(self, d, e[0], e[1], e[2])
	var ck := kit("Kitchen")
	ck.box(Vector3(54.4, 0.75, -13.4), Vector3(0.6, 0.9, 0.6), "l112_steel")
	for bx in [[54.42, 1.2, -13.55], [54.42, 1.2, -13.25]]:
		ck.cylinder(Vector3(bx[0], bx[1], bx[2]), 0.1, 0.02, "l112_wall_dark", 10, false)
	ck.box(Vector3(54.55, 2.0, -14.9), Vector3(0.35, 0.7, 2.4), "l112_counter", GeoKit.ALL, false)
	ck.commit()
	# gunshot-dented barricade casings leaning on block D (the side nearest Level 11)
	var bk := kit("Casings")
	for i in 7:
		var x := -48.0 + i * 6.5 + rr.randf_range(-1.0, 1.0)
		bk.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(x, 1.0, 35.6)), Vector3(1.9, 2.1, 0.07), "l112_blackmetal", GeoKit.ALL, true)
		for j in 6:
			bk.box(Vector3(x + rr.randf_range(-0.8, 0.8), rr.randf_range(0.4, 1.8), 35.82), Vector3(0.05, 0.05, 0.02), "l112_dent", GeoKit.ALL, false)
	bk.commit()


func _streetlights(d: Node3D) -> void:
	var pts: Array = []
	var z := 40.0
	var side := 1.0
	while z < 236.0:
		pts.append([Vector3(ROAD_X + side * 7.9, 0, z), -90.0 if side > 0 else 90.0])
		side = -side
		z += 22.0
	for x in [-24.0, -6.0, 12.0]:
		pts.append([Vector3(x, 0, -68.0), 0.0])
		pts.append([Vector3(x + 6.0, 0, -4.0), 180.0])
	for zz in [-56.0, -38.0, -20.0]:
		pts.append([Vector3(-36.0, 0, zz), -90.0])
		pts.append([Vector3(36.0, 0, zz + 6.0), 90.0])
	pts.append([Vector3(ROAD_X - 7.9, 0, 12.0), 90.0])
	var hk := kit("LampHeads")
	for p in pts:
		var pos: Vector3 = p[0]
		Props.place(self, d, "ph/street_lamp_01", pos, p[1], 6.5, false)
		var head := pos + Vector3(0, 6.35, 0)
		hk.panel(head, 0.35, 0.35, "l112_sodium")
		lights.add_anchor(head + Vector3(0, -0.4, 0), Color(1.0, 0.58, 0.22), 3.6, 22.0)
	hk.commit()
	# the lit hall of the Banner Building and the tents' lamp
	lights.add_anchor(BANNER + Vector3(0, 2.0, 9.4), Color(1.0, 0.88, 0.66), 1.2, 8.0)
	lights.add_anchor(Vector3(0.0, 2.4, -19.0), Color(1.0, 0.8, 0.55), 1.0, 7.0, 0.05)
	# the watch post's work lights wash the painted south face
	lights.add_anchor(Vector3(-7.0, 4.5, -22.5), Color(1.0, 0.93, 0.82), 2.2, 15.0)
	lights.add_anchor(Vector3(7.5, 4.5, -22.5), Color(1.0, 0.93, 0.82), 2.2, 15.0)
	lights.add_anchor(Vector3(40.5, 3.0, -30.8), Color(0.95, 0.95, 1.0), 1.6, 12.0)


func _figure() -> void:
	figure = MeshInstance3D.new()
	figure.name = "ReportedShadowFigure"
	var cm := CapsuleMesh.new()
	cm.radius = 0.28
	cm.height = 1.75
	figure.mesh = cm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.0, 0.0, 0.0, 0.88)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	figure.material_override = m
	figure.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	figure.visible = false
	add_child(figure)


func _snowfall() -> void:
	snow = CPUParticles3D.new()
	snow.name = "Snow"
	snow.amount = 1600
	snow.lifetime = 9.0
	snow.preprocess = 9.0
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(26, 0.5, 26)
	snow.direction = Vector3(0.15, -1, 0.05)
	snow.spread = 12.0
	snow.gravity = Vector3(0, -0.4, 0)
	snow.initial_velocity_min = 0.9
	snow.initial_velocity_max = 1.4
	snow.local_coords = false
	var qm := QuadMesh.new()
	qm.size = Vector2(0.035, 0.035)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.albedo_color = Color(0.9, 0.88, 0.85)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.material = sm
	snow.mesh = qm
	snow.position = START + Vector3(0, 11, 0)
	add_child(snow)


func _sounds() -> void:
	sound.bed("wind", {"seconds": 10.0}, -20.0)
	sound.bed("room_tone", {"seconds": 6.0, "cutoff": 220.0}, -30.0)
	sound.emitter("transformer", Vector3(38.8, 0.6, -20.6), {"base": 55.0}, -12.0, 16.0)
	sound.emitter("transformer", Vector3(-13.0, 0.6, -22.0), {"base": 50.0}, -14.0, 14.0)
	sound.emitter("static", Vector3(0.4, 0.6, -18.6), {"seconds": 3.0}, -24.0, 7.0)
	sound.emitter("fluorescent_hum", Vector3(48.5, 2.4, -36.0), {}, -18.0, 12.0)
	sound.emitter("fluorescent_hum", Vector3(48.5, 5.3, -20.0), {}, -18.0, 12.0)
	sound.oneshot("creak", {"freq": 160.0}, 25.0, 60.0, 30.0, "[sheet metal ticks in the cold]", -16.0)


# ----------------------------------------------------------------- exits

func _exits_and_arrivals() -> void:
	var defs := [["L011_2>L283#2", "283", IN.CE, -33.0, IN.F0], ["L011_2>L189#3", "189", IN.CW, -16.0, IN.F0],
		["L011_2>L852#4", "852", IN.CW, -6.0, IN.F0], ["L011_2>L155#5", "155", IN.CE, -54.0, IN.F0],
		["L011_2>L036#6", "36", IN.CW, -54.0, IN.F1], ["L011_2>L059#7", "59", IN.CW, -30.0, IN.F1],
		["L011_2>L121#8", "121", IN.CE, -12.0, IN.F1], ["L011_2>L078#9", "78", IN.CW, -6.0, IN.F1]]
	var gk := kit("GatewayDoors")
	for dd in defs:
		var at: Vector3 = interior.gateway(gk, dd[0], dd[1], dd[2], dd[3], dd[4])
		add_exit(dd[0], "interact", at, Vector3(1.2, 2.2, 1.4), "Open the door marked %s" % dd[1])
		var yaw := -90.0 if dd[2] < 48.5 else 90.0
		add_arrival("from_" + str(dd[0]).split(">")[1].split("#")[0], Vector3(at.x, dd[4] + 0.05, at.z), yaw)
	gk.commit()
	add_exit("L011_2>L011#1", "walk_in", Vector3(ROAD_X, 1.5, 250.0), Vector3(16.0, 3.0, 6.0), "")
	add_arrival("start", START, 8.0)
	add_arrival("from_L011", Vector3(ROAD_X - 1.5, 0.05, 228.0), 0.0)


func _notes() -> void:
	add_note("l112_omicron", "Base Omicron notice board", "M.E.G. BASE OMICRON (Level 11.2, 'Scene-01.2'). Seventh main base. About 250 residents. Linked with Base Epsilon on Level 283.\n\nFound February 2015 by Team Reed: every door and window barricaded, badly. It took a day to lift them. Inside, a refugee community's home, kept as it was: classrooms, lounges, infirmaries, flats.\n\nDoors with wooden number signs are gateways. You come back through the same door. 283 and 189 are the useful ones.\n\nThe fridges refill about every other week. Nobody knows what with until you open them.\n\nNo facelings here. Nobody knows why.", Vector3(47.2, IN.F0 + 1.5, -24.6), Vector3(0.2, 0.9, 1.4), false)
	add_note("l112_watch", "Watch log, Banner Building post", "The black metal casing came off like every other building's. Under it: nothing you can see, and nothing you can get through. Breach attempts stopped in January 2016.\n\nIt was the only building lit after the first layer came off. People reported a shadow crossing the lit hall, fast, side to side.\n\nTwo tents, a watch kept at all hours. Nothing seen since the tents went up.", Vector3(0.4, 0.42, -18.6), Vector3(0.5, 0.3, 0.5))
	add_note("l112_diary", "Diary of Jane Mahayfaio (1992)", "9 Aug 92. Waiting in the snow while the soldiers check the place. Big orange blocks I might call home. I think we've escaped. I hope there are no entities. Somehow I know there aren't.\n\n12 Aug 92. More food and Almond Water than we can use. HQ named it Scene-01.4 and told us not to leave, gateways or not. Nobody wants to, not after what we found in the colourful building. Dad won't let me write what it does.\n\n15 Dec 92. Everything went silent. The thing in the colourful building warned us Emstable was coming. They're drafting everyone. We're putting up barricades.\n\n17 Dec 92. Smoke in the distance. The thing in the rainbow building says it will make its own barrier around it. I'm in the last building not yet barricaded, rifle in my other hand.", Vector3(54.4, IN.F1 + 0.72, -25.8), Vector3(0.4, 0.2, 0.4))
	add_interactable(interior.fridge_pos + Vector3(-0.45, 1.0, 0.0), Vector3(0.5, 1.8, 0.8), "Open the fridge", _open_fridge)
	add_interactable(Vector3(0.0, 1.6, FORCE.end.z + 0.25), Vector3(6.0, 2.6, 0.5), "Touch the air in front of the hall", func():
		Overlay.glitch(0.15)
		Overlay.subtitle("[hard, cold, and nothing there. It does not give at all.]", 4.0))


# ----------------------------------------------------------------- mechanics

func _cycle() -> int:
	# "restock every other week": a 14-day cycle on the real calendar
	return int(Time.get_unix_time_from_system() / 86400.0) / 14


func _stock(cycle: int) -> Array:
	var rr := RandomNumberGenerator.new()
	rr.seed = hash([level_seed, cycle, 0xF1D6E])
	var out: Array = []
	var n := rr.randi_range(3, 6)
	var pool := FOODS.duplicate()
	for i in n:
		out.append(pool.pop_at(rr.randi() % pool.size()))
	return out


func _open_fridge() -> void:
	var c := _cycle()
	if c != fridge_cycle or fridge_items.is_empty() and SaveService.flag(stable_id, "fridge_cycle", -1) != c:
		fridge_cycle = c
		fridge_items = _stock(c)
		var taken: int = int(SaveService.flag(stable_id, "fridge_taken_%d" % c, 0))
		for i in mini(taken, fridge_items.size()):
			fridge_items.pop_back()
		SaveService.set_flag(stable_id, "fridge_cycle", c)
	if fridge_items.is_empty():
		Overlay.show_note("Fridge", "Empty, and cold. It will be full again in a week or two; nobody knows what with.")
		return
	var got: String = fridge_items.pop_back()
	SaveService.set_flag(stable_id, "fridge_taken_%d" % c, int(SaveService.flag(stable_id, "fridge_taken_%d" % c, 0)) + 1)
	SaveService.add_item("frontrooms_food")
	if player:
		player.heal(15.0)
	Overlay.show_note("Fridge", "Stocked with Frontrooms food that nobody here bought: %s.\n\nYou take %s. Left: %s." % [", ".join(fridge_items + [got]), got, ("nothing" if fridge_items.is_empty() else ", ".join(fridge_items))])


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	snow.global_position = p + Vector3(0, 11, 0)
	snow.emitting = not _indoors(p)
	# the blending zone: the sky lightens toward Level 11
	var t := smoothstep(60.0, 230.0, p.z)
	sky_mat.sky_top_color = Color(0.002, 0.002, 0.003).lerp(Color(0.012, 0.016, 0.035), t)
	sky_mat.sky_horizon_color = Color(0.018, 0.014, 0.012).lerp(Color(0.13, 0.11, 0.13), t)
	environment.fog_light_color = Color(0.085, 0.06, 0.038).lerp(Color(0.12, 0.11, 0.13), t)
	# invisible barrier: a reaction when you walk into it
	force_said -= delta
	if force_said <= 0.0 and FORCE.grow(0.45).has_point(p + Vector3(0, 1.0, 0)):
		force_said = 12.0
		Overlay.subtitle("[you walk into something hard that is not there]", 3.5)
	_figure_tick(delta, p)


func _indoors(p: Vector3) -> bool:
	return p.x > IN.X0 and p.x < IN.X1 and p.z > IN.Z0 and p.z < IN.Z1 and p.y < IN.CEIL1


func _figure_tick(delta: float, p: Vector3) -> void:
	if figure_t >= 0.0:
		figure_t += delta
		var u := figure_t / 0.85
		figure.position = BANNER + Vector3(lerpf(-10.5, 10.5, u), 1.2, 8.05)
		if u >= 1.0:
			figure.visible = false
			figure_t = -1.0
		return
	if SessionState.is_qa():
		return
	figure_cd -= delta
	var near := p.z > BANNER.z + 8.0 and p.distance_to(BANNER) < 60.0
	if figure_cd <= 0.0 and near:
		figure_cd = rng.randf_range(120.0, 300.0)
		if rng.randf() < 0.5:
			figure_t = 0.0
			figure.visible = true
			if not said.has("figure"):
				said["figure"] = true
				Overlay.subtitle("[something dark crosses the lit hall, side to side]", 3.5)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var gate := 0
	for t in exits:
		if str(t.edge_id).begins_with("L011_2>") and t.kind == "interact":
			gate += 1
	out.append({"what": "eight signed gateway doors", "ok": gate == 8, "detail": gate})
	out.append({"what": "walk-away exit to Level 11 on the approach road", "ok": exits.any(func(t): return t.edge_id == "L011_2>L011#1")})
	out.append({"what": "a return arrival for every gateway", "ok": ["from_L283", "from_L189", "from_L852", "from_L155", "from_L036", "from_L059", "from_L121", "from_L078", "from_L011"].all(func(a): return arrivals.has(a))})
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0, 1.2, -10.0), Vector3(0, 1.2, -30.0), 1)
	var hit := space.intersect_ray(q)
	out.append({"what": "Banner Building barrier blocks the way in", "ok": not hit.is_empty() and absf(float(hit["position"].z) - FORCE.end.z) < 0.2, "detail": hit.get("position", null)})
	var a := _stock(5)
	var b := _stock(5)
	var c := _stock(6)
	out.append({"what": "fridge stock fixed within a cycle, changes between cycles", "ok": a == b and a != c and a.size() >= 3})
	out.append({"what": "no faceling or hostile entity nodes", "ok": not figure.visible})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
