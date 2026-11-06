extends LevelBase
## Level 0.1 — "Zenith Station" (Backrooms Wikidot rev 29, accessed 2026-11-04;
## cite: "Level 0.1 - "Zenith Station"" by CutTheBirch, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L000_1.md.
##
## A damaged metal-and-glass megastructure embedded in Level 0, believed to be
## a vast spherical shell around a hollow centre. Two authored places joined by
## a radial lift (ADAPTATION, see level.json notes):
##  - the Outer Ring (start): the hull breach where a Level 0 hallway runs across
##    a gulf into the station, with Level 0's identical floors stacked
##    vertically outside the windows; walking back out is the sourced exit.
##  - the Inner Gallery: four decks on the cavity wall, leaning out over a
##    2.8 km hollow sphere lined with lit decks, dark districts and frozen or
##    overheated wings (L000_1_gallery.gd, far field in L000_1_vista.gd).
## Systems (L000_1_sys.gd): sliding doors, lethal hot/cold wings, Level 0's
## hallucinations, roaming cleaning/cooking automatons (props), the lift.
## No entities; no other wanderers (isolation inherited from Level 0).

const D := preload("res://levels/L000_1/L000_1_dims.gd")
const V := preload("res://levels/L000_1/L000_1_vista.gd")
const G := preload("res://levels/L000_1/L000_1_gallery.gd")
const H := preload("res://levels/L000_1/L000_1_hull.gd")
const S := preload("res://levels/L000_1/L000_1_sys.gd")
const Q := preload("res://levels/L000_1/L000_1_qa.gd")

var sys
var gallery
var hull
var th: Node3D
var qa_fixture := false
var facade_segments := 0
var stack_floors := 0
var _drone: AudioStreamPlayer
var _seen_gallery := false
var _zone_exits := {"hull": [], "gallery": []}
var _live_exits: Array = []


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.5
	rules["reverb_wet"] = 0.2
	rules["view_distance"] = 4600.0
	indoor_env(Color(0.8, 0.74, 0.55), 0.24, Color(0.33, 0.28, 0.14), 0.0)
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.0
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.95
	environment.adjustment_contrast = 1.07
	_materials()
	V.materials()
	lights.setup(16, 1)
	lights.max_distance = 34.0
	sys = S.new(self)
	sys.apply_zone("hull")
	th = Node3D.new()
	th.name = "OuterRing"
	add_child(th)
	th.position = D.TH
	# the sourced walk-back exit comes first (it is the QA bot's route)
	_zone_exits["hull"].append({"edge": "L000_1>L000#1", "kind": "walk_in", "c": Vector3(0, D.L0Y + 1.2, D.L0Z - 3.5), "size": Vector3(4.6, 2.4, 1.6), "prompt": "", "parent": th})
	hull = H.new(self, sys, th)
	hull.build()
	gallery = G.new(self, sys)
	gallery.build()
	sys.build_car(th, Transform3D(Basis(Vector3.UP, PI), Vector3(0, 0, 10.0)))
	sys.build_car(self, Transform3D(Basis(), Vector3(-5.0, 0, D.ZW)))
	var far := Node3D.new()
	far.name = "FarField"
	add_child(far)
	V.cavity(far)
	facade_segments = V.facade(far)
	stack_floors = V.level0_stack(th)
	V.hull_face(th)
	_noclip(th, hull.noclip_spots[0], "hull")
	var spots: Array = gallery.noclip_spots
	if spots.is_empty():
		spots = [{"pos": Vector3(-D.GX + 0.12, D.deck_y(1), -4.0), "along": Vector3.BACK, "n": Vector3.RIGHT}]
	_noclip(self, spots[rng.randi() % spots.size()], "gallery")
	stream_exits("hull")
	sys.add_cleaner([Vector3(-27.0, 0, -6.6), Vector3(-4.0, 0, -6.6), Vector3(-4.0, 0, -3.6), Vector3(-27.0, 0, -3.6)])
	add_arrival("start", D.TH + Vector3(0, 0.05, -3.6), 180.0)
	_audio()
	add_note("L000_1_harvest_tag", "Harvest tag",
		"[i]A plastic tag zip-tied to a stripped wall panel, stamped with a trader's mark.[/i]\n\nSTRIPPED: glass, wire, panel alloy.\nLift by the back wall still runs. Inside it's bright, mostly.\nWings that hum hot or frost over: stay out. They kill you slow.\nWay home is the yellow hall, back out through the hole in the hull.\nYou won't meet anyone in here. Don't wait.",
		D.TH + Vector3(-7.2, 0.48, -3.1))
	add_shot("vacuole", Vector3(21.5, D.deck_y(2) + 1.62, D.edge(2) + 6.9), Vector3(-60.0, 5.0, 60.0))
	add_shot("threshold", D.TH + Vector3(6.5, 1.62, -5.6), D.TH + Vector3(-4.0, -6.0, -45.0))
	add_landmark("Outer Ring breach (start)", D.TH + Vector3(0, 0, -6.0))
	add_landmark("Inner Gallery atrium", Vector3(0, 0, -1.0))
	add_landmark("Cavity gantry", Vector3(20.0, D.deck_y(2), D.edge(2) + 4.0))


func _materials() -> void:
	var white := {"albedo_a": Color(0.84, 0.85, 0.86), "albedo_b": Color(0.78, 0.79, 0.8), "pattern": 1, "pattern_scale": Vector2(1.2, 1.3),
		"grout_width": 0.006, "grout_color": Color(0.5, 0.52, 0.54), "roughness_a": 0.35, "roughness_b": 0.5, "noise_scale": 0.6,
		"stain_amount": 0.25, "stain_color": Color(0.5, 0.5, 0.48), "grime_height": 0.25, "grime_color": Color(0.42, 0.42, 0.4), "bump_strength": 0.3}
	MatLib.define("l01_wall", white, "trim_white")
	MatLib.define("l01_wall_flicker", {"emission_color": Color(0.75, 0.88, 1.0), "emission_energy": 0.6, "emission_flicker": 1.0}, "trim_white")
	MatLib.define("l01_trim", {"albedo_a": Color(0.9, 0.9, 0.9), "albedo_b": Color(0.86, 0.86, 0.87)}, "trim_white")
	MatLib.define("l01_parapet", {"albedo_a": Color(0.74, 0.76, 0.78), "albedo_b": Color(0.7, 0.72, 0.74), "metallic_value": 0.4, "roughness_a": 0.3}, "trim_white")
	MatLib.define("l01_floor", {"albedo_a": Color(0.5, 0.52, 0.54), "albedo_b": Color(0.44, 0.46, 0.48), "pattern": 1, "pattern_scale": Vector2(1.2, 1.2),
		"grout_width": 0.008, "grout_color": Color(0.2, 0.21, 0.22), "metallic_value": 0.45, "roughness_a": 0.32, "roughness_b": 0.55, "stain_amount": 0.3}, "metal")
	MatLib.define("l01_floor_dark", {"albedo_a": Color(0.3, 0.31, 0.33), "albedo_b": Color(0.26, 0.27, 0.29), "pattern": 1, "pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01}, "metal")
	MatLib.define("l01_slab_metal", {"albedo_a": Color(0.42, 0.43, 0.45), "albedo_b": Color(0.36, 0.37, 0.39)}, "metal")
	MatLib.define("l01_rail", {"albedo_a": Color(0.6, 0.6, 0.58), "albedo_b": Color(0.5, 0.5, 0.48)}, "metal")
	MatLib.define("l01_stair", {"albedo_a": Color(0.46, 0.47, 0.49), "albedo_b": Color(0.4, 0.41, 0.43), "pattern": 2, "pattern_scale": Vector2(0.06, 1.0), "pattern_strength": 0.35}, "metal")
	MatLib.define("l01_grate", {"albedo_a": Color(0.3, 0.31, 0.32), "albedo_b": Color(0.2, 0.2, 0.21), "pattern": 9, "pattern_scale": Vector2(0.05, 0.05), "pattern_color": Color(0.05, 0.05, 0.05), "pattern_strength": 0.7}, "metal")
	MatLib.define("l01_mullion", {"albedo_a": Color(0.16, 0.17, 0.18), "albedo_b": Color(0.12, 0.13, 0.14), "roughness_a": 0.3}, "metal")
	MatLib.define("l01_door", {"albedo_a": Color(0.7, 0.72, 0.74), "albedo_b": Color(0.64, 0.66, 0.68), "pattern": 2, "pattern_scale": Vector2(0.9, 1.0), "pattern_strength": 0.15, "metallic_value": 0.5}, "metal")
	MatLib.define("l01_car", {"albedo_a": Color(0.55, 0.56, 0.58), "albedo_b": Color(0.5, 0.51, 0.53), "pattern": 2, "pattern_scale": Vector2(0.02, 1.0), "pattern_strength": 0.12, "roughness_a": 0.25}, "metal")
	MatLib.define("l01_hull_in", {"albedo_a": Color(0.5, 0.52, 0.55), "albedo_b": Color(0.43, 0.45, 0.48), "pattern": 1, "pattern_scale": Vector2(2.0, 1.15),
		"grout_width": 0.01, "grout_color": Color(0.15, 0.15, 0.16), "stain_amount": 0.5, "stain_color": Color(0.25, 0.2, 0.15)}, "metal")
	MatLib.define("l01_hull", {"albedo_a": Color(0.3, 0.31, 0.33), "albedo_b": Color(0.24, 0.25, 0.26), "pattern": 1, "pattern_scale": Vector2(6.0, 4.5),
		"grout_width": 0.004, "grout_color": Color(0.1, 0.1, 0.1), "stain_amount": 0.6, "stain_scale": 0.05, "stain_color": Color(0.2, 0.17, 0.12)}, "metal")
	MatLib.define("l01_fac_slab", {"albedo_a": Color(0.55, 0.57, 0.6), "albedo_b": Color(0.5, 0.52, 0.55), "emission_color": Color(0.5, 0.55, 0.62), "emission_energy": 0.05}, "trim_white")
	MatLib.define("l01_fac_soffit", {"albedo_a": Color(0.25, 0.26, 0.28), "albedo_b": Color(0.2, 0.21, 0.23), "emission_color": Color(0.6, 0.62, 0.66), "emission_energy": 0.04, "pattern": 1, "pattern_scale": Vector2(1.2, 1.2)}, "metal")
	MatLib.define("l01_tile", {"albedo_a": Color(0.86, 0.87, 0.86), "albedo_b": Color(0.8, 0.81, 0.8), "stain_amount": 0.35}, "pool_tile")
	MatLib.define("l01_rubber", {"albedo_a": Color(0.12, 0.12, 0.13), "albedo_b": Color(0.09, 0.09, 0.1), "roughness_a": 0.9, "roughness_b": 1.0, "pattern": 1, "pattern_scale": Vector2(1.0, 1.0), "grout_width": 0.004}, "concrete")
	MatLib.define("l01_fabric", {"albedo_a": Color(0.28, 0.34, 0.42), "albedo_b": Color(0.24, 0.29, 0.36), "roughness_a": 0.95, "roughness_b": 1.0}, "plaster")
	MatLib.define("l01_locker", {"albedo_a": Color(0.62, 0.66, 0.7), "albedo_b": Color(0.56, 0.6, 0.64), "pattern": 2, "pattern_scale": Vector2(0.8, 1.0), "pattern_strength": 0.4}, "metal")
	MatLib.define("l01_mirror", {"albedo_a": Color(0.8, 0.82, 0.85), "albedo_b": Color(0.78, 0.8, 0.83), "metallic_value": 1.0, "roughness_a": 0.04, "roughness_b": 0.1}, "metal")
	MatLib.define("l01_stove", {"albedo_a": Color(0.08, 0.08, 0.08), "albedo_b": Color(0.06, 0.06, 0.06), "emission_color": Color(1.0, 0.35, 0.1), "emission_energy": 0.4}, "metal")
	MatLib.define("l01_plant", {"albedo_a": Color(0.2, 0.42, 0.14), "albedo_b": Color(0.13, 0.3, 0.09), "pattern": 12, "noise_scale": 3.0}, "grass")
	MatLib.define("l01_plant_dead", {"albedo_a": Color(0.36, 0.3, 0.2), "albedo_b": Color(0.26, 0.22, 0.15), "pattern": 12, "noise_scale": 3.0}, "grass")
	MatLib.define("l01_soil", {}, "dirt")
	MatLib.define("l01_frost", {"albedo_a": Color(0.82, 0.9, 0.98), "albedo_b": Color(0.7, 0.8, 0.92), "roughness_a": 0.2, "roughness_b": 0.6, "noise_scale": 4.0, "emission_color": Color(0.3, 0.45, 0.7), "emission_energy": 0.25}, "plaster")
	MatLib.define("l01_scorch", {"albedo_a": Color(0.1, 0.07, 0.05), "albedo_b": Color(0.2, 0.12, 0.07), "noise_scale": 2.0, "roughness_a": 0.9, "emission_color": Color(0.5, 0.12, 0.02), "emission_energy": 0.15}, "concrete_dark")
	MatLib.define("l01_wire", {"albedo_a": Color(0.04, 0.04, 0.04), "albedo_b": Color(0.06, 0.06, 0.06)}, "metal")
	MatLib.define("l01_wire_red", {"albedo_a": Color(0.45, 0.05, 0.04), "albedo_b": Color(0.35, 0.04, 0.03)}, "metal")
	MatLib.define("l01_bot", {"albedo_a": Color(0.9, 0.91, 0.92), "albedo_b": Color(0.82, 0.83, 0.85), "roughness_a": 0.25, "roughness_b": 0.4, "stain_amount": 0.3}, "trim_white")
	MatLib.define("l01_l0wall", {"emission_color": Color(0.74, 0.65, 0.36), "emission_energy": 0.035}, "l0_wallpaper")
	MatLib.define("l01_ceiling", {"albedo_a": Color(0.78, 0.8, 0.82), "albedo_b": Color(0.74, 0.76, 0.78), "pattern": 1, "pattern_scale": Vector2(0.6, 1.2),
		"grout_width": 0.008, "grout_color": Color(0.45, 0.47, 0.5), "roughness_a": 0.7, "roughness_b": 0.85, "stain_amount": 0.3, "stain_color": Color(0.45, 0.43, 0.4)}, "trim_white")
	MatLib.define("l01_l0carpet", {}, "l0_carpet")
	MatLib.define("l01_l0wall_far", {"albedo_a": Color(0.5, 0.44, 0.24), "albedo_b": Color(0.44, 0.38, 0.2)}, "l0_wallpaper")
	MatLib.define("l01_l0carpet_far", {"albedo_a": Color(0.3, 0.24, 0.13), "albedo_b": Color(0.24, 0.19, 0.1)}, "l0_carpet")
	MatLib.define("l01_l0ceiling_far", {"albedo_a": Color(0.5, 0.48, 0.42), "albedo_b": Color(0.46, 0.44, 0.38)}, "l0_ceiling")
	MatLib.define("l01_l0ceiling", {"emission_color": Color(0.85, 0.83, 0.72), "emission_energy": 0.02}, "l0_ceiling")
	MatLib.define("l01_l0slab", {}, "concrete_dark")
	MatLib.register("l01_plenum", MatLib.get_mat("unlit_black"))
	MatLib.register("l01_panel", MatLib.panel(Color(0.88, 0.94, 1.0), 1.9))
	MatLib.register("l01_panel_cold", MatLib.panel(Color(0.5, 0.7, 1.0), 1.4))
	MatLib.register("l01_panel_hot", MatLib.panel(Color(1.0, 0.45, 0.18), 1.1))
	MatLib.register("l01_grow", MatLib.panel(Color(1.0, 0.35, 0.85), 2.2))
	MatLib.register("l01_vent_hot", MatLib.panel(Color(1.0, 0.38, 0.08), 2.6))
	MatLib.register("l01_l0panel", MatLib.panel(Color(1.0, 0.95, 0.78), 2.3))
	MatLib.register("l01_screen", MatLib.panel(Color(0.25, 0.42, 0.55), 0.7, 0.6))
	MatLib.register("l01_led_green", MatLib.panel(Color(0.3, 1.0, 0.45), 2.0))
	MatLib.register("l01_led_red", MatLib.panel(Color(1.0, 0.15, 0.1), 2.0))
	MatLib.register("l01_led_amber", MatLib.panel(Color(1.0, 0.65, 0.2), 2.0))
	MatLib.register("l01_led_cyan", MatLib.panel(Color(0.4, 0.95, 1.0), 2.2))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.72, 0.82, 0.9, 0.07)
	g.roughness = 0.06
	g.metallic_specular = 0.45
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l01_glass", g)


## A wall that flickers and crackles like Level 0's: push into it to no-clip.
func _noclip(parent: Node3D, spot: Dictionary, z: String) -> void:
	var pos: Vector3 = spot["pos"]
	var along: Vector3 = spot["along"]
	var n: Vector3 = spot["n"]
	var k := GeoKit.new(parent, "FlickerWall")
	k.box_xf(Transform3D(Basis(along, Vector3.UP, along.cross(Vector3.UP)), pos + n * 0.03 + Vector3.UP * 1.25), Vector3(2.4, 2.5, 0.04), "l01_wall_flicker", GeoKit.ALL, false)
	k.commit()
	var wp: Vector3 = parent.global_transform * pos
	lights.add_anchor(wp + n * 0.8 + Vector3.UP * 2.2, Color(0.8, 0.9, 1.0), 1.3, 5.0, 0.9, "noclip")
	sound.emitter("static", wp + Vector3.UP * 1.2, {"seconds": 2.0}, -15.0, 10.0)
	var size := along.abs() * 2.6 + Vector3.UP * 2.3 + n.abs() * 1.5
	_zone_exits[z].append({"edge": "L000_1>L001#2", "kind": "noclip", "c": pos + n * 0.5 + Vector3.UP * 1.15, "size": size,
		"prompt": "Push through the flickering wall (press / sprint into it)", "parent": parent, "hold": 1.2})


## Exit triggers live only in the slice the player is in (like streamed
## chunks): the two slices are ~2 km apart and joined only by the lift.
func stream_exits(z: String) -> void:
	for t in _live_exits:
		if is_instance_valid(t):
			t.queue_free()
	_live_exits.clear()
	for e in _zone_exits.get(z, []):
		var t := make_exit(e["edge"], e["kind"], e["c"], e["size"], e["prompt"], e["parent"])
		if t:
			t.hold_seconds = float(e.get("hold", 2.0))
			_live_exits.append(t)


func _audio() -> void:
	sys.setup_audio()
	sound.bed("room_tone", {"cutoff": 180.0, "rumble": 0.5}, -22.0)
	_drone = sound.bed("pad", {"root": 41.0, "chord": [0, 7, 12], "bright": 0.05, "seconds": 10.0}, -60.0)
	sound.oneshot("creak", {"freq": 55.0}, 40.0, 110.0, 30.0, "[the shell creaks somewhere far off]", -16.0)
	sound.oneshot("distant_boom", {}, 120.0, 260.0, 40.0, "[a deep groan travels through the structure]", -18.0)
	sound.oneshot("crackle", {}, 30.0, 80.0, 6.0, "[something shorts out behind a panel]", -20.0)


# --------------------------------------------------------------- runtime

func on_player_ready() -> void:
	if SessionState.is_story():
		checkpoint(str(spawn_report.get("used_arrival", "start")))
		if not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
			Overlay.subtitle("[the Level 0 buzz fades behind you] [metal underfoot] [cold, filtered air]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L000_1>L000#1", "target": D.TH + Vector3(0, D.L0Y, D.L0Z - 3.5), "note": "start -> breach steps -> Level 0 hallway across the gulf -> the stacked floors"})


func level_process(delta: float) -> void:
	if player == null:
		return
	sys.tick(delta)
	if _drone:
		_drone.volume_db = lerpf(_drone.volume_db, -19.0 if sys.zone == "gallery" else -40.0, minf(1.0, delta * 0.8))


func on_lift_arrived(idx: int) -> void:
	if idx == 1 and not _seen_gallery:
		_seen_gallery = true
		Overlay.subtitle("[the hum dies away] [beyond the glass: a hollow the size of a country, lit deck by deck]", 5.0)
		if SessionState.is_story():
			checkpoint("inner_gallery")


# -------------------------------------------------------------------- QA

func qa_capture_plan() -> Array:
	return Q.capture_plan(self)


func qa_self_test() -> Array:
	return await Q.self_test(self)
