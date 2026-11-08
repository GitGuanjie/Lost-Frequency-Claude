extends LevelBase
## Level 994 — "Exist Here" (Backrooms Wikidot rev 28, accessed 2026-11-04;
## cite: iccaarus, CC BY-SA 3.0). Dossier: docs/canon/levels/L994.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: a beach facing the sea in the east, mountains in every other
## direction; no animals, plants or structures; irregular flood and ebb tides;
## the only way in is an iron gate engraved "EXIST" (we place it in the west
## mountain, as the audio log's base says); the beach is clean; pebbles; the
## north end is "the cliff that has nothing but sand"; the waves sound wrong
## near the water (machines, tracks, jets, talking, crying, praying, "Except
## for water"); clear water shows rust, building debris and daily necessities
## (TESTIMONY); safe distances 15/30/40 m; the beach fogs up and the tide comes
## fast; "Please just go back to where you came from" before the tide comes.
## ADAPTATION: the bay is scaled to ~0.2 km2 (page: up to ~20 km2 at ebb) and
## closed by a mountain ring and headlands; a gorge with a 13 % slope climbs to
## the gate ledge (second walkable height); the tide is a noise-driven sea
## level with one flood event (after you stand within 3 m of the water, or
## after an irregular 6-12 minutes); the faces are never shown, only heard and
## described in captions; the gate creaks in the wind so it can be found in fog.
## Signature mechanic: tide clock + proximity distortion + fog + flood race.
## Helper: L994_terrain.gd (height function, meshes, collision).

const T := preload("res://levels/L994/L994_terrain.gd")
const START := Vector3(-135.0, 7.75, 0.0)
const SEA_LO := -0.6
const SEA_PEAK := 11.0

var ter
var terrain_mat: ShaderMaterial
var sea: WaterVolume
var sea_y := 0.0
var state := "calm"          # calm | haze | flood
var state_t := 0.0
var clock := 0.0
var flood_at := 600.0
var warned_t := -1.0
var dist := 99.0
var _dist_t := 0.0
var said := {}
var fog_base := 0.0016
var beds := {}
var _talk_t := 4.0
var _creak_t := 6.0
var gate_pos := Vector3.ZERO
var dead_sent := false


func build() -> void:
	ter = T.new()
	rules["view_distance"] = 4200.0
	rules["reverb_room"] = 0.2
	rules["reverb_wet"] = 0.04
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.29, 0.41, 0.57), Color(0.72, 0.72, 0.70), Color(0.32, 0.31, 0.29), Vector2(26.0, 40.0), Color(1.0, 0.9, 0.76), 1.3, Color(0.70, 0.72, 0.74), fog_base)
	environment.ambient_light_energy = 0.75
	environment.tonemap_exposure = 0.95
	environment.fog_sky_affect = 0.35
	environment.fog_aerial_perspective = 0.55
	sun.directional_shadow_max_distance = 180.0
	flood_at = rng.randf_range(360.0, 720.0)
	_materials()
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	terrain_mat = ter.make_material()
	ter.build_meshes(geo, terrain_mat)
	ter.build_collision(geo)
	sea = WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-180.0, -40.0, -2600.0), Vector3(3400.0, 0.0, 2600.0), "l994_sea", true)
	sea.fog_color = Color(0.12, 0.26, 0.28)
	sea.fog_density = 0.05
	sea.tint = Color(0.35, 0.55, 0.55)
	_gate()
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	_boulders(props)
	_pebbles(props)
	_seabed(props)
	_sounds()
	for tag in ["start", "from_L011", "from_L221", "from_L422"]:
		add_arrival(tag, START, -90.0)
	add_landmark("Iron gate engraved EXIST (west gorge)", gate_pos)
	add_landmark("North sand cliff", Vector3(-20.0, 13.0, -292.0))
	add_landmark("Waterline at mean sea level", Vector3(T.SEA_X, 0.0, 0.0))
	add_shot("gate_ledge_to_sea", START + Vector3(1.0, 1.65, 0.6), Vector3(70.0, -1.0, 18.0), {"flashlight": false})
	add_shot("bay_north_sand_cliff", Vector3(-8.0, 2.9, 70.0), Vector3(30.0, 4.0, -280.0), {"flashlight": false})
	add_shot("clear_water_debris", Vector3(T.SEA_X - 1.0, 2.0, 22.0), Vector3(T.SEA_X + 9.0, -3.0, 26.0), {"flashlight": false})
	add_shot("gate_from_gorge_mouth", Vector3(-118.0, 7.4, 2.5), Vector3(-143.0, 9.4, 0.0), {"flashlight": false})
	add_shot("tide_coming_fog", Vector3(-86.0, 5.4, -14.0), Vector3(40.0, 0.5, 10.0), {"flashlight": false, "prepare": _prep_flood_shot})


func _materials() -> void:
	MatLib.register("l994_sea", MatLib.water({"shallow_color": Color(0.40, 0.60, 0.58), "deep_color": Color(0.06, 0.17, 0.22),
		"absorption": 0.05, "clarity": 0.97, "wave_height": 0.06, "wave_scale": 0.22, "wave_speed": 0.28,
		"normal_strength": 0.45, "foam_amount": 0.4, "foam_width": 0.35, "roughness_value": 0.03}))
	MatLib.define("l994_iron", {"albedo_a": Color(0.16, 0.13, 0.11), "albedo_b": Color(0.27, 0.16, 0.09),
		"metallic_value": 0.55, "roughness_a": 0.55, "roughness_b": 0.9, "noise_scale": 4.0, "stain_amount": 0.45,
		"stain_color": Color(0.36, 0.17, 0.07), "bump_strength": 1.3}, "rust")
	MatLib.define("l994_stone", {"albedo_a": Color(0.27, 0.26, 0.245), "albedo_b": Color(0.19, 0.185, 0.175),
		"pattern": 4, "pattern_scale": Vector2(0.9, 0.45), "grout_width": 0.02, "grout_color": Color(0.2, 0.19, 0.18),
		"noise_scale": 1.2, "bump_strength": 1.6, "stain_amount": 0.4, "stain_color": Color(0.25, 0.27, 0.22)}, "rock")


# ---------------------------------------------------------------- the gate

func _gate() -> void:
	var k := kit("IronGate")
	var gx := T.GATE.x
	var fy := T.GORGE_FLOOR
	gate_pos = Vector3(gx, fy, 0.0)
	# hewn stone piers set into the gorge walls, a lintel beam and a sill
	for side in [-1.0, 1.0]:
		k.box(Vector3(gx, fy + 2.4, side * 3.25), Vector3(1.2, 5.6, 1.1), "l994_stone")
		k.box(Vector3(gx - 0.2, fy + 2.0, side * 4.6), Vector3(1.6, 5.0, 1.8), "l994_stone")
	k.box(Vector3(gx, fy + 5.0, 0.0), Vector3(1.3, 0.9, 7.6), "l994_stone")
	k.box(Vector3(gx, fy - 0.15, 0.0), Vector3(1.4, 0.5, 5.6), "l994_stone")
	# the gate itself: two leaves of square iron bars with rails and a plate
	k.box(Vector3(gx, fy + 4.3, 0.0), Vector3(0.16, 0.22, 5.4), "l994_iron")
	k.box(Vector3(gx, fy + 0.35, 0.0), Vector3(0.14, 0.16, 5.4), "l994_iron")
	k.box(Vector3(gx, fy + 2.1, 0.0), Vector3(0.12, 0.12, 5.4), "l994_iron", GeoKit.ALL, false)
	var nbar := 17
	for i in nbar:
		var z := -2.6 + 5.2 * float(i) / float(nbar - 1)
		k.box(Vector3(gx, fy + 2.3, z), Vector3(0.07, 4.0, 0.07), "l994_iron", GeoKit.ALL, i % 2 == 0)
		k.box(Vector3(gx, fy + 4.52, z), Vector3(0.05, 0.22, 0.05), "l994_iron", GeoKit.ALL, false)
	k.box(Vector3(gx + 0.1, fy + 4.75, 0.0), Vector3(0.06, 0.62, 2.4), "l994_iron", GeoKit.ALL, false)
	k.box(Vector3(gx, fy + 2.3, 0.0), Vector3(0.1, 4.0, 0.1), "l994_iron", GeoKit.ALL, false)
	for side in [-1.0, 1.0]:
		for hy in [0.9, 3.6]:
			k.box(Vector3(gx, fy + hy, side * 2.68), Vector3(0.22, 0.28, 0.18), "l994_iron", GeoKit.ALL, false)
	# what lies behind the bars: only darkness, the way you came
	k.box(Vector3(gx - 2.6, fy + 2.3, 0.0), Vector3(0.2, 4.8, 5.8), "unlit_black", GeoKit.ALL, true)
	k.box(Vector3(gx - 1.4, fy + 4.85, 0.0), Vector3(2.4, 0.3, 5.8), "l994_stone")
	for side in [-1.0, 1.0]:
		k.box(Vector3(gx - 1.4, fy + 2.3, side * 2.95), Vector3(2.4, 4.8, 0.3), "l994_stone")
	k.box(Vector3(gx - 1.4, fy - 0.1, 0.0), Vector3(2.4, 0.3, 5.8), "l994_stone")
	k.commit()
	var lab := Label3D.new()
	lab.name = "Engraving"
	lab.text = "E X I S T"
	lab.font_size = 96
	lab.pixel_size = 0.0042
	lab.modulate = Color(0.10, 0.08, 0.07)
	lab.outline_size = 6
	lab.outline_modulate = Color(0.52, 0.36, 0.22)
	lab.shaded = true
	lab.double_sided = false
	lab.position = Vector3(gx + 0.14, fy + 4.75, 0.0)
	lab.rotation.y = PI * 0.5
	add_child(lab)
	# the exit: go back through the gate you came in by (canon: before the tide)
	var t := add_exit("L994>EXT#1", "interact", Vector3(gx + 1.3, fy + 1.0, 0.0), Vector3(2.0, 2.2, 4.8), "Go back through the iron gate")
	if t:
		t.condition = func() -> bool: return sea_y < fy - 0.2
	add_note("l994_meg_notice", "M.E.G. notice wired to the gate", "LEVEL 994. A beach facing the sea to the east, mountains in every other direction. Habitable. No animals, plants or structures recorded, so no entities.\n\nThe sea floods and ebbs on no schedule anyone has found.\n\nA base was ordered here in April 2022. Nothing was built. The one constructor sent cannot account for 3-12 May.\n\nAn unverified recording (the agent is not on file) asks visitors to keep 40 m from the water, and to come back through this gate before the tide comes.", Vector3(gx + 0.7, fy + 1.15, 3.9), Vector3(0.5, 0.5, 0.5))
	add_interactable(Vector3(gx + 0.5, fy + 4.7, 0.0), Vector3(0.6, 0.8, 2.6), "Read the engraving", func():
		Overlay.show_note("Iron plate above the gate", "One word is cut deep into the iron, the letters wide apart:\n\nE X I S T\n\nThe bars are cold. Behind them there is only the dark you walked out of."))


# ---------------------------------------------------------------- dressing

func _boulders(parent: Node3D) -> void:
	# talus along the mountain foot; boulders stay off the beach centre
	var z := -286.0
	while z < 286.0:
		z += rng.randf_range(5.0, 11.0)
		var foot: float = -114.0 + 12.0 * ter.n_foot.get_noise_1d(z) + 7.0 * ter.n_foot.get_noise_1d(z * 4.3 + 300.0) + 0.00004 * z * z
		if absf(z) < 13.0:
			continue
		var x := foot + rng.randf_range(-3.0, 4.0)
		var hgt := rng.randf_range(0.9, 3.6)
		Props.place(self, parent, "ph/boulder_01", Vector3(x, ter.h(x, z) - hgt * 0.18, z), rng.randf_range(0, 360), hgt, true)
		if rng.randf() < 0.55:
			var x2 := x + rng.randf_range(2.0, 7.0)
			var h2 := rng.randf_range(0.35, 1.2)
			_vis(Props.place(self, parent, "ph/boulder_01", Vector3(x2, ter.h(x2, z + 1.5) - h2 * 0.2, z + 1.5), rng.randf_range(0, 360), h2, h2 > 0.7), 160.0)
	# the gorge mouth and its walls
	for p in [Vector3(-110, 0, -7.4), Vector3(-117, 0, 6.6), Vector3(-124, 0, -5.6), Vector3(-131, 0, 4.4), Vector3(-101, 0, 10.5), Vector3(-138.5, 0, -3.7)]:
		var hgt := rng.randf_range(0.9, 1.8)
		if ter.normal_at(p.x, p.z).y < 0.82:
			continue
		Props.place(self, parent, "ph/boulder_01", Vector3(p.x, ter.h(p.x, p.z) - hgt * 0.25, p.z), rng.randf_range(0, 360), hgt, true)
	# sea stacks off the headlands (always in water)
	for i in 14:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := T.SEA_X + rng.randf_range(30.0, 240.0)
		var zz := side * (300.0 + (x - T.SEA_X) * 0.55 - rng.randf_range(4.0, 30.0))
		var hgt := rng.randf_range(4.0, 11.0)
		Props.place(self, parent, "ph/boulder_01", Vector3(x, ter.h(x, zz) - 1.5, zz), rng.randf_range(0, 360), hgt, false)


func _pebbles(parent: Node3D) -> void:
	# pebbles mostly in a band 10-25 m from the water (audio log: "some pebbles")
	var n := 0
	while n < 80:
		var z := rng.randf_range(-270.0, 270.0)
		var sx: float = T.SEA_X + 7.0 * ter.n_shore.get_noise_1d(z)
		var x := sx - rng.randf_range(4.0, 34.0) - (40.0 if rng.randf() < 0.15 else 0.0)
		var s := rng.randf_range(0.06, 0.2) if rng.randf() < 0.8 else rng.randf_range(0.25, 0.45)
		_vis(Props.place(self, parent, "ph/rock_07", Vector3(x, ter.h(x, z) - s * 0.15, z), rng.randf_range(0, 360), s, false, false), 45.0)
		n += 1
	for zc in [-64.0, 38.0, 146.0]:
		var sx: float = T.SEA_X + 7.0 * ter.n_shore.get_noise_1d(zc)
		var c := Vector3(sx - 15.0, 0.0, zc)
		c.y = ter.h(c.x, c.z)
		for j in 9:
			var p := c + Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
			_vis(Props.place(self, parent, "ph/rock_07", Vector3(p.x, ter.h(p.x, p.z) - 0.02, p.z), rng.randf_range(0, 360), rng.randf_range(0.07, 0.16), false, false), 45.0)
		add_interactable(c + Vector3(0, 0.4, 0), Vector3(2.4, 0.8, 2.4), "Skip a pebble", _skip_pebble)


## Rust, building debris and daily necessities on the sea floor, always under
## the lowest ebb (TESTIMONY: Richee James, audio of unverifiable authenticity).
func _seabed(parent: Node3D) -> void:
	var ids := ["ph/barrel_03", "ph/old_tyre", "ph/concrete_road_barrier", "ph/plastic_monobloc_chair_01",
		"ph/Television_01", "ph/vintage_suitcase", "ph/metal_trash_can", "ph/rollershutter_door", "ph/dining_chair_02",
		"ph/plastic_bottle_gallon", "ph/old_bed_frame", "ph/wooden_crate_01", "ph/hand_truck", "ph/propane_tank", "ph/SchoolChair_01"]
	var placed := 0
	var tries := 0
	while placed < 44 and tries < 400:
		tries += 1
		var z := rng.randf_range(-250.0, 250.0) if placed >= 10 else rng.randf_range(14.0, 40.0)
		var x := T.SEA_X + rng.randf_range(3.0, 24.0)
		var y: float = ter.h(x, z)
		if y > SEA_LO - 0.55:
			continue
		var id: String = ids[rng.randi() % ids.size()]
		var hold := Props.place(self, parent, id, Vector3(x, y - 0.05, z), rng.randf_range(0, 360), 0.0, false, false)
		_vis(hold, 90.0)
		if hold:
			hold.rotation.x = rng.randf_range(-0.5, 0.5)
			hold.rotation.z = rng.randf_range(-0.9, 0.9) if id != "ph/rollershutter_door" else PI * 0.5
			placed += 1


func _vis(n: Node, end: float) -> void:
	if n == null:
		return
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).visibility_range_end = end
		(n as GeometryInstance3D).visibility_range_end_margin = end * 0.15
	for c in n.get_children():
		_vis(c, end)


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -27.0)
	beds["waves"] = sound.bed("water_bed", {"seconds": 8.0, "bright": 1300.0}, -22.0)
	beds["machines"] = sound.bed("transformer", {"base": 46.0}, -70.0)
	beds["jets"] = sound.bed("static", {"seconds": 3.0}, -70.0)
	beds["prayer"] = sound.bed("pad", {"root": 98.0, "chord": [0, 3, 7, 10, 15], "seconds": 9.0, "bright": 0.12}, -70.0)
	beds["roar"] = sound.bed("room_tone", {"seconds": 5.0, "cutoff": 260.0, "rumble": 0.6}, -70.0)


func _skip_pebble() -> void:
	Overlay.glitch(0.35)
	Overlay.subtitle("[the pebble skips once, twice... and the splash never comes]", 4.0)


# ---------------------------------------------------------------- tide

func _set_sea(y: float) -> void:
	sea_y = y
	sea.surface_y = y
	sea.aabb.size.y = y - sea.aabb.position.y
	if sea.surface_mesh:
		sea.surface_mesh.position.y = y
	terrain_mat.set_shader_parameter("water_y", y)
	terrain_mat.set_shader_parameter("wet_top", y + 0.75)


func _calm_level(t: float) -> float:
	# irregular: three incommensurate swells plus a slow wandering offset
	var v := 0.32 * sin(t * 0.0137 + 1.1) + 0.18 * sin(t * 0.0291 + 2.3) + 0.09 * sin(t * 0.071)
	v += 0.22 * ter.n_shore.get_noise_1d(t * 0.9 + 4000.0)
	return clampf(v - 0.05, SEA_LO, 0.55)


func _shore_distance(p: Vector3) -> float:
	if p.y < sea_y + 0.05:
		return 0.0
	var x := p.x
	for i in 400:
		x += 1.0
		if ter.h(x, p.z) < sea_y:
			return x - p.x
	return 400.0


func on_player_ready() -> void:
	_set_sea(_calm_level(0.0))


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	clock += delta
	state_t += delta
	var qa := SessionState.is_qa()
	match state:
		"calm":
			_set_sea(_calm_level(clock))
			if not qa and (clock > flood_at or (warned_t >= 0.0 and clock - warned_t > 14.0)):
				_begin_haze()
		"haze":
			_set_sea(sea_y + delta * lerpf(0.0, 0.035, minf(state_t / 30.0, 1.0)))
			environment.fog_density = lerpf(environment.fog_density, 0.06, delta * 0.09)
			environment.fog_sky_affect = lerpf(environment.fog_sky_affect, 1.0, delta * 0.1)
			if state_t > 32.0:
				state = "flood"
				state_t = 0.0
				Overlay.subtitle("[the tide is coming]", 4.0)
		"flood":
			var rate := 0.04 + 0.15 * smoothstep(0.0, 70.0, state_t)
			_set_sea(minf(sea_y + rate * delta, SEA_PEAK))
			environment.fog_density = lerpf(environment.fog_density, 0.075, delta * 0.1)
			if not dead_sent and sea_y - player.global_position.y > 1.15:
				dead_sent = true
				player.hurt(1000.0, "The tide came. You became part of the sea.")
	_dist_t -= delta
	if _dist_t <= 0.0:
		_dist_t = 0.25
		dist = _shore_distance(player.global_position)
		_captions()
	_mix(delta)


func _begin_haze() -> void:
	state = "haze"
	state_t = 0.0
	create_tween().tween_property(environment, "fog_light_color", Color(0.78, 0.8, 0.82), 20.0)
	Overlay.subtitle("[the beach is fogging up — walk in a straight line, don't stop]", 5.0)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func _captions() -> void:
	if state != "calm":
		return
	if dist < 30.0:
		_say("30", "[the waves sound wrong: mixed, noisy, not only water]")
	if dist < 15.0:
		_say("15", "[under the surf: machines, tracks, jets]")
	if dist < 5.0:
		_say("5", "[talking, shouting, crying, friction, howling, praying... except for water]", 5.0)
	if dist < 3.0 and warned_t < 0.0:
		warned_t = clock
		Overlay.glitch(0.5)
		_say("3", "[the clear water shows rust, rubble, chairs and pale swollen faces whose mouths move: \"Leave before the tide comes.\"]", 7.0)
	if said.has("3") and dist > 40.0:
		_say("40", "[40 metres. Only waves again.]")


func _mix(delta: float) -> void:
	var near := 1.0 - clampf(dist / 60.0, 0.0, 1.0)
	var flood := 1.0 if state == "flood" else (clampf(state_t / 30.0, 0.0, 1.0) if state == "haze" else 0.0)
	var k := minf(delta * 2.0, 1.0)
	_vol("waves", lerpf(-26.0, -8.0, near) + flood * 8.0, k)
	_vol("machines", lerpf(-70.0, -15.0, clampf((18.0 - dist) / 15.0, 0.0, 1.0)) + flood * 4.0, k)
	_vol("jets", lerpf(-70.0, -24.0, clampf((10.0 - dist) / 8.0, 0.0, 1.0)), k)
	_vol("prayer", lerpf(-70.0, -17.0, clampf((6.0 - dist) / 4.0, 0.0, 1.0)), k)
	_vol("roar", lerpf(-70.0, -6.0, flood), k)
	if dist < 12.0 and state == "calm":
		_talk_t -= delta
		if _talk_t <= 0.0:
			_talk_t = rng.randf_range(1.5, 4.0)
			var p := player.global_position + Vector3(dist + rng.randf_range(1.0, 6.0), 0.0, rng.randf_range(-6.0, 6.0))
			sound.play_at("whisper", {"seconds": 2.2}, Vector3(p.x, sea_y, p.z), -10.0 + (12.0 - dist), "")
	_creak_t -= delta
	if _creak_t <= 0.0 and player.global_position.distance_to(gate_pos) < 200.0:
		_creak_t = rng.randf_range(7.0, 14.0)
		sound.play_at("creak", {"freq": 140.0}, gate_pos + Vector3(0.5, 2.5, 0.0), -6.0, "[an iron gate creaks, somewhere west]" if state != "calm" else "")


func _vol(key: String, db: float, k: float) -> void:
	var p: AudioStreamPlayer = beds.get(key)
	if p:
		p.volume_db = lerpf(p.volume_db, db, k)


func _prep_flood_shot() -> void:
	state = "flood"
	state_t = 40.0
	_set_sea(2.6)
	environment.fog_density = 0.035
	environment.fog_sky_affect = 0.95
	environment.fog_light_color = Color(0.78, 0.8, 0.82)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "gate exit is the only physical exit", "ok": exits.size() == 1})
	out.append({"what": "spawn on the gate ledge above the beach", "ok": player.global_position.y > 6.5, "detail": player.global_position})
	var y0 := _calm_level(10.0)
	var y1 := _calm_level(400.0)
	out.append({"what": "tide level varies irregularly", "ok": absf(y0 - y1) > 0.01 and y0 >= SEA_LO and y1 <= 0.55, "detail": [y0, y1]})
	out.append({"what": "shore distance from gate > 40 m (safe)", "ok": _shore_distance(player.global_position) > 40.0, "detail": _shore_distance(player.global_position)})
	out.append({"what": "no flood in QA mode", "ok": state == "calm"})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
