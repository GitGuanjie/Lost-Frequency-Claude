extends LevelBase
## Level 60 — The Baywalk. Canon basis: docs/canon/levels/L060.md.
## Distinct upper/lower walkways, working stair lights ~100m apart, dark water,
## seeded water characteristics, and a conditional source-backed Portal exit.
## IN_DEVELOPMENT until Godot QA and human walkthrough, never marked PLAYABLE.

const LENGTH := 260.0
const UPPER_Y := 3.35
const LOWER_Y := 0.0
const SEA_Y := -0.40

var sea: WaterVolume
var portal: ExitTrigger
var sea_state := 0            # 0 normal / 1 portal / 2 low tide / 3 ocean
var state_time := 0.0
var portal_open := false
var anxiety := 0.0
var painless := 0.0
var qa_fixture := false
var low_tide_notice := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 240.0
	rules["reverb_room"] = 0.06
	rules["reverb_wet"] = 0.02
	rules["flashlight"] = "allowed"
	rules["oxygen_seconds"] = 90.0
	indoor_env(Color(0.21, 0.28, 0.38), 0.14, Color(0.015, 0.028, 0.048), 0.006)
	environment.tonemap_exposure = 0.85
	environment.glow_intensity = 0.1
	_materials()
	lights.setup(8, 1)
	lights.max_distance = 32.0
	_walkways()
	_ocean()
	_portal()
	add_arrival("start", Vector3(-2, -0.90, 12), -90.0)
	add_arrival("from_L085", Vector3(-2, -0.90, 12), -90.0)
	add_landmark("The Sea: shallow arrival", Vector3(-2, SEA_Y, 12))
	add_landmark("Lower unfinished construction path", Vector3(3, 0, 36))
	add_landmark("First lit stair between the levels", Vector3(9, 1.5, 48))
	add_landmark("Upper Baywalk: no food or water", Vector3(16, UPPER_Y, 65))
	add_shot("dim_upper_baywalk", Vector3(17, UPPER_Y + 1.62, 7), Vector3(16, UPPER_Y + 1.2, 125))
	add_shot("two_tier_bay", Vector3(-4, 1.62, 35), Vector3(11, 2.7, 82))
	sound.bed("wind", {"seconds": 7.0}, -30.0)
	sound.bed("water_bed", {"seconds": 6.0}, -29.0)
	sound.oneshot("creak", {"freq": 65.0}, 35.0, 95.0, 22.0, "[an empty light fixture rattles]", -30.0)
	state_time = 110.0 if not qa_fixture else 1000.0
	if qa_fixture:
		# A deterministic, *valid* portal window for physical route QA.
		# Never bypass ExitTrigger.condition or its water/swim requirement.
		sea_state = 1
		portal_open = true
	_apply_sea_characteristic()


func _materials() -> void:
	MatLib.define("l60_walk", {"albedo_a": Color(0.29, 0.32, 0.33), "albedo_b": Color(0.24, 0.27, 0.30), "roughness_a": 0.93}, "concrete")
	MatLib.define("l60_dirt", {"albedo_a": Color(0.21, 0.19, 0.16), "albedo_b": Color(0.25, 0.22, 0.18), "noise_scale": 4.0}, "dirt")
	MatLib.define("l60_seabed", {"albedo_a": Color(0.18, 0.23, 0.25), "albedo_b": Color(0.12, 0.17, 0.19)}, "sand")
	MatLib.define("l60_black_sand", {"albedo_a": Color(0.08, 0.07, 0.065), "albedo_b": Color(0.11, 0.10, 0.09), "roughness_a": 0.95}, "sand")
	MatLib.register("l60_water", MatLib.water({"shallow_color": Color(0.045, 0.10, 0.14), "deep_color": Color(0.008, 0.03, 0.05), "absorption": 0.95, "clarity": 0.22, "wave_height": 0.035, "wave_scale": 0.18}))
	MatLib.define("l60_rust", {"albedo_a": Color(0.17, 0.19, 0.19), "albedo_b": Color(0.37, 0.21, 0.15), "metallic_value": 0.5}, "metal")
	MatLib.define("l60_fence", {"albedo_a": Color(0.27, 0.3, 0.32), "albedo_b": Color(0.2, 0.22, 0.25)}, "metal")
	MatLib.register("l60_glow", MatLib.panel(Color(0.93, 0.93, 0.67), 2.1))


func _walkways() -> void:
	var k := kit("BaywalkTwoTierArchitecture")
	# Two genuinely different heights; no rail on the unfinished lower path.
	k.slab(0, 0, 7, LENGTH, LOWER_Y, 0.32, "l60_dirt")
	k.slab(11.5, 0, 20.5, LENGTH, UPPER_Y, 0.55, "l60_walk")
	k.slab(-26, -4, -0.3, LENGTH + 4, -1.48, 0.4, "l60_seabed")
	k.slab(-26, -4, -0.3, LENGTH + 4, -1.455, 0.008, "l60_black_sand", GeoKit.PY)
	# The retaining wall is segmented at all three stair landings. A continuous
	# collision wall here would seal off the stairs even if the steps render.
	var wall_breaks := [0.0, 45.8, 52.2, 145.8, 152.2, 245.8, 252.2, LENGTH]
	var solid_ranges: Array[Vector2] = [Vector2(wall_breaks[0], wall_breaks[1]), Vector2(wall_breaks[2], wall_breaks[3]), Vector2(wall_breaks[4], wall_breaks[5]), Vector2(wall_breaks[6], wall_breaks[7])]
	for span in solid_ranges:
		var segment_center: float = 0.5 * (span.x + span.y)
		var segment_length: float = span.y - span.x
		k.box(Vector3(11.50, 1.5, segment_center), Vector3(0.5, 3.0, segment_length), "l60_walk")
	k.box(Vector3(20.5, UPPER_Y + 0.42, LENGTH * 0.5), Vector3(0.16, 0.84, LENGTH), "l60_fence")
	# Stairs: physical treads rise from lower x=5 to upper x=12.2.
	# Nonwalkable decorative scaffolding is collision-free.
	for z in [49.0, 149.0, 249.0]:
		k.stairs(Vector3(5.0, LOWER_Y, z), Vector3(1, 0, 0), 2.8, UPPER_Y, 16, "l60_walk", 0.45)
		for i in 5:
			var p := Vector3(7 + float(i) * 1.1, 0.4 + float(i) * 0.49, z + 1.7)
			k.box(p, Vector3(0.09, 0.85, 0.09), "l60_rust", GeoKit.ALL, false)
		lights.add_anchor(Vector3(11.8, UPPER_Y + 4.0, z), Color(1.0, 0.94, 0.73), 1.2, 14.0, 0.82, "l60_stair")
	for i in 26:
		var z := 6.0 + float(i) * 10.0
		k.cylinder(Vector3(19.0, UPPER_Y + 2.25, z), 0.065, 4.5, "l60_rust", 8)
		k.box(Vector3(18.6, UPPER_Y + 4.35, z), Vector3(1.2, 0.12, 0.13), "l60_rust")
		k.box(Vector3(18.1, UPPER_Y + 4.2, z), Vector3(0.32, 0.1, 0.48), "l60_glow" if i % 9 == 4 else "l60_rust", GeoKit.ALL, false)
		# Few lights work: the upper area is predominantly dark.
		if i % 9 == 4:
			lights.add_anchor(Vector3(18.1, UPPER_Y + 4.05, z), Color(0.90, 0.95, 1.0), 0.45, 11.0, 0.75, "l60_brokenlamp")
	for i in 31:
		var z := rng.randf_range(8.0, LENGTH - 8.0)
		var x := rng.randf_range(0.9, 5.7)
		var p := Vector3(x, 0.36, z)
		# Inert construction equipment; never convert the lower area into a hostile area.
		k.box(p, Vector3(0.5, 0.72, 0.7), "l60_rust", GeoKit.ALL, false)
		if i % 4 == 0:
			k.box(p + Vector3(0.35, 0.4, 0), Vector3(0.5, 0.08, 2.5), "l60_rust", GeoKit.ALL, false)
	k.commit()


func _ocean() -> void:
	sea = WaterVolume.new()
	sea.name = "TheSea"
	add_child(sea)
	sea.setup(Vector3(-26, -1.45, 0), Vector3(-0.3, SEA_Y, LENGTH), "l60_water", true)
	sea.current = Vector3(0.05, 0, 0.0)
	sea.fog_color = Color(0.01, 0.055, 0.085)
	sea.fog_density = 0.12


func _portal() -> void:
	# Every *entry* into this region during Portal characteristic uses one
	# stable pre-rolled chance. No per-frame RNG that turns chance into certainty.
	portal = add_exit("L060>L007#1", "condition", Vector3(-7, -0.9, 150), Vector3(12, 3.6, 15), "The sea sometimes opens into another level")
	portal.condition = func(): return sea_state == 1 and portal_open and player != null and player.swimming


func _apply_sea_characteristic() -> void:
	if sea == null:
		return
	# Low tide exposes dark sand. The ocean state makes the local current drag
	# down; this bounded region is a release-scale approximation, not 3,740 m.
	sea.surface_y = -1.40 if sea_state == 2 else SEA_Y
	var region := sea.aabb
	region.size.y = sea.surface_y - region.position.y
	sea.aabb = region
	if sea.surface_mesh:
		sea.surface_mesh.position.y = sea.surface_y
	sea.current = Vector3(0, -0.75 if sea_state == 3 else 0, 0)
	sea.fog_density = 0.20 if sea_state == 3 else 0.12


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[the sea is dark] [the unfinished path lies above the water]", 4.0)


func level_process(delta: float) -> void:
	if player == null or qa_fixture:
		return
	state_time -= delta
	if state_time <= 0.0:
		sea_state = (sea_state + 1) % 4
		state_time = rng.randf_range(95, 175)
		portal_open = rng.randf() < 0.23
		_apply_sea_characteristic()
		if sea_state == 2:
			Overlay.subtitle("[the water retreats; black sand shows through]", 4.0)
		elif sea_state == 1:
			Overlay.subtitle("[the water has changed]", 3.0)
		elif sea_state == 3:
			Overlay.subtitle("[an impossible depth opens below the sea]", 4.0)
	if player.global_position.y > UPPER_Y + 0.1 and player.global_position.x > 11.4:
		# Restrict the lethal sedation to an anxious listener lingering near the
		# water. Running or looking away interrupts it; moving normalises it.
		var faces_water := player.global_transform.basis.z.x > 0.5
		anxiety = clampf(anxiety + delta * (0.005 if faces_water else -0.018), 0, 1)
		painless = clampf(painless + delta * (0.02 if faces_water and anxiety > 0.5 and sea_state != 2 else -0.035), 0, 1)
		if painless >= 0.85:
			Overlay.subtitle("[the breeze asks you to stop moving]", 2.0)
	else:
		anxiety = maxf(0.0, anxiety - delta * 0.05)
		painless = maxf(0.0, painless - delta * 0.07)
	# Full damage/death is postponed: without proven anxiety and rescue rules,
	# this development scene only implements readable warning feedback.


func qa_self_test() -> Array:
	return [
		{"ok": sea != null, "what": "water body available at the original sea arrival"},
		{"ok": portal != null, "what": "sourced conditional Portal characteristic exit"},
		{"ok": sea_state == (1 if qa_fixture else 0), "what": "starts normal for players and condition-ready in QA fixture"},
		{"ok": arrivals.has("from_L085"), "what": "source-specific arrival tag"},
	]
