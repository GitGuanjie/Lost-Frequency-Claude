extends LevelBase
## Level 15 — "Futuristic Halls" (Backrooms Wikidot rev 47, accessed 2026-11-04;
## cite: Anonymous User, rewrite of u/Hugorrr, u/incomplete-sentanc and KingSheep17,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L015.md.
## Content note: desiccated corpses, dried blood, makeshift weapons (no gore detail).
##
## PLAN (v2.0 rebuild, authored layout; procedural: false)
## SOURCE: futuristic hallways of white or gray concrete lined with white steel beams
##   carrying arabesque-like symbols; large lights on walls, ceilings or ground; some
##   stretches pitch black. Engine noise heard from afar, from large machine rooms
##   behind reinforced metal doors with a thick glass wall section; machines from
##   laptop size to unmeasurable, some making steel rods, most with no clear task;
##   rare rooms of destroyed machines whose glass is shattered but not broken.
##   Laboratories, dormitories, kitchens, control rooms, storage (food, water,
##   equipment), mostly empty. Corpses in lab coats from violent fights, makeshift
##   knives and spears, no firearms; desiccated, no bugs. Hound corpses piled in a
##   cremation room. No Almond Water anywhere. Computers run "Avalon 2.4"; every
##   scanner terminal shows the same radar at the same time. Enric's only base is a
##   large control room; the Level 10 door slammed shut and never reopened. Two hours
##   from camp: an engine room with every engine missing and a glowing doorframe on
##   a night sky with a still, clear blue sphere; the reinforced door is intact.
## SPACE (ADAPTATION of scale; the page gives no map): the control room (camp, start)
##   with an operator gallery at +3.4 m; an 8 x 6 m spine running 110 m north with
##   ribs every 4 m and four lighting regimes (ceiling + wall lights, ground lights
##   only, pitch black, sparse wall lights); off it a lab, dormitory, kitchen and
##   storage (west), an engine hall 6 m below the spine seen through laminated glass
##   and reached by a reinforced door and a 33-step stair (flywheel, rod press,
##   a drum that runs through floor and ceiling), a wrecked engine room with cracked
##   glass and a cremation room (east); a cross gallery in the black stretch runs
##   66 m each way to sealed reinforced doors (the halls continue: "thought infinite").
##   The doorframe room closes the spine ("two hours away" compressed to ~3 minutes).
## SIGNATURE MECHANIC (stateful): one shared scanner state drives every radar screen
##   (constant drift, a few accelerate, links only when both ends are on screen,
##   overlaps turn green, orange predictions only while the shape is visible, the
##   centre and the small right circle never move; their green line is the theorised
##   doorframe link, shown as theory). The rod press keeps filling its bin; time in
##   the doorframe room is counted against the page's "as little time as possible".
## EXIT: L015>EXT#2 walk_in through the frame (DANGEROUS+UNKNOWN). The Level 10 door
##   (L015>L010#1, closed) is an interactable that never opens. ENTITIES: none alive.

const Geo := preload("res://levels/L015/L015_geo.gd")
const Dress := preload("res://levels/L015/L015_dress.gd")
const Radar := preload("res://levels/L015/L015_radar.gd")
const Extra := preload("res://levels/L015/L015_extra.gd")
const SPAWN := Vector3(0.0, 0.05, -3.0)
const EXIT_ID := "L015>EXT#2"

var geo
var dress
var radar
var t := 260.0   # the scanner has been running long before you arrived
var produced := 0
var exposure := 0.0
var _told := {}
var _press_t := 0.0


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 150.0
	rules["reverb_room"] = 0.8
	rules["reverb_wet"] = 0.3
	var fog := Color(0.006, 0.008, 0.012)
	indoor_env(Color(0.55, 0.64, 0.74), 0.05, fog, 0.011)
	environment.background_color = fog
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.08
	Geo.materials()
	Dress.materials()
	var ks := kit("Structure")
	var kf := kit("Faces")
	kf.shadows = false
	var kd := kit("Dressing")
	geo = Geo.new(self, ks, kf)
	dress = Dress.new(self, kd, kf)
	geo.control_room()
	geo.spine()
	geo.engine_hall()
	geo.wreck_room()
	geo.cremation_room()
	geo.west_rooms()
	geo.cross_gallery()
	geo.frame_room()
	geo.heavy_door_x(4.0, -58.0, 3.0, 3.4, 1.0, 1.05)
	geo.heavy_door_x(4.0, -82.0, 2.4, 3.0, 1.0, 1.05)
	geo.heavy_door_x(4.0, -104.0, 2.4, 3.0, 1.0, 1.05)
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var rr := RandomNumberGenerator.new()
	rr.seed = 15015
	dress.control_room(props, rr)
	dress.engine_hall(props, rr)
	dress.wreck_room(props, rr)
	dress.cremation_room(props, rr)
	dress.lab(props, rr)
	dress.dorm(props, rr)
	dress.kitchen(props, rr)
	dress.storage(props, rr)
	dress.halls(props, rr)
	ks.commit()
	kd.commit()
	kf.commit()
	Extra.beyond(self)
	radar = Radar.new()
	var scr := Node3D.new()
	scr.name = "Screens"
	add_child(scr)
	radar.add_display(scr, Transform3D(Basis(), Vector3(0, 5.75, -21.53)), 9.2, 3.4)
	radar.add_display(scr, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(13.77, 5.1, -9.6)), 1.6, 1.0)
	radar.add_display(scr, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-19.78, 1.75, -34.0)), 1.1, 0.7)
	radar.add_display(scr, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(4.42, 1.7, -61.0)), 0.9, 0.6)
	radar.update(0.0)
	Extra.lights(self)
	Extra.sounds(self)
	Extra.notes(self)
	add_arrival("start", SPAWN, 0.0)
	var ex := add_exit(EXIT_ID, "walk_in", Vector3(0, 1.6, Geo.FRAME_Z - 0.9), Vector3(2.8, 3.0, 1.6), "Step through the frame")
	if ex:
		ex.fired.connect(_on_frame)
	add_landmark("Control room (Enric's camp)", Vector3(0, 0, -10))
	add_landmark("Engine hall glass", Vector3(3.6, 1.6, -40))
	add_landmark("Pitch-black stretch", Vector3(0, 0, -90))
	add_landmark("Room with the glowing doorframe", Vector3(0, 0, -150))
	_shots()


func _on_frame(_e: String) -> void:
	if SessionState.is_qa():
		return
	Overlay.subtitle("[beyond the frame: a night sky, distant points of light, a still blue sphere]", 5.0)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[a deep, even drone from somewhere beyond the walls: engines]", 4.0)


func level_process(delta: float) -> void:
	t += delta
	radar.update(t)
	if dress.wheel:
		dress.wheel.rotate_x(delta * 0.9)
	produced += dress.rods_step(delta)
	var shown := mini(dress.pile.size(), 14 + produced)
	for i in dress.pile.size():
		(dress.pile[i] as Node3D).visible = i < shown
	_press_t += delta
	if _press_t > 4.4:
		_press_t = 0.0
		if player and player.global_position.distance_to(Vector3(14, -4, -52)) < 34.0:
			sound.play_at("knock", {"hits": 1}, Vector3(14.0, -4.0, -52.0), -6.0, "[the press thumps; a steel rod slides out]" if not _told.has("press") else "")
			_told["press"] = true
	if player == null:
		return
	var pp := player.global_position
	if pp.z < Geo.SPINE_Z1 - 0.5 and absf(pp.x) < 15.0:
		exposure += delta
		Extra.exposure_step(self)
	if not _told.has("dark") and pp.z < -80.0 and pp.z > -99.0 and absf(pp.x) < 4.0:
		_told["dark"] = true
		if not SessionState.is_qa():
			Overlay.subtitle("[the lights stop. Nothing here has ever been lit.]", 3.5)
	if not _told.has("glass") and pp.z < -30.0 and pp.z > -50.0 and pp.x > 2.0 and pp.y > -1.0:
		_told["glass"] = true
		if not SessionState.is_qa():
			Overlay.subtitle("[behind the thick glass, six metres down, a wheel turns with nothing attached]", 4.0)


func _shots() -> void:
	add_shot("control_room", Vector3(-1.2, 1.62, -1.6), Vector3(2.0, 4.0, -21.0))
	add_shot("spine", Vector3(-2.4, 1.62, -24.0), Vector3(1.5, 2.0, -62.0))
	add_shot("engine_hall", Vector3(5.2, 1.7, -56.4), Vector3(22.0, -4.5, -38.0))
	add_shot("doorframe", Vector3(-1.4, 1.62, -137.0), Vector3(0.0, 2.2, -166.0))
	add_shot("cremation", Vector3(6.0, 1.62, -103.0), Vector3(17.0, 0.3, -111.0))
	add_shot("kitchen", Vector3(-5.4, 1.62, -68.8), Vector3(-13.0, 0.4, -76.0))


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	radar.update(123.4)
	out.append({"what": "every scanner screen shows the same frame", "ok": radar.displays.size() >= 4 and radar.displays_agree(), "detail": radar.displays.size()})
	var s0: Dictionary = radar.compute(0.0)
	var c0: Vector2 = Radar.CIRCLE
	var ov := 0
	var lk := 0
	var tt := 0.0
	while tt < 900.0:
		var st: Dictionary = radar.compute(tt)
		if (st["hit"] as Array).has(true) or st["centre_hit"]:
			ov += 1
		if (st["links"] as Array).has(true):
			lk += 1
		tt += 2.0
	out.append({"what": "objects drift, overlap (green) and link only when both on screen", "ok": ov > 0 and lk > 0 and s0["pos"][0] != radar.compute(50.0)["pos"][0], "detail": [ov, lk]})
	out.append({"what": "centre shape and small right circle never move", "ok": Radar.CENTRE == Vector2.ZERO and c0 == Radar.CIRCLE and radar.displays.size() > 0})
	var p0 := produced
	for i in 40:
		produced += dress.rods_step(0.5)
	out.append({"what": "the rod press keeps producing steel rods", "ok": produced > p0, "detail": produced - p0})
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(11.0, 6.0, -14.0), Vector3(11.0, 0.5, -14.0), 1))
	out.append({"what": "operator gallery is a walkable second height (+3.4 m)", "ok": not hit.is_empty() and absf(hit["position"].y - 3.4) < 0.05, "detail": hit.get("position", null)})
	var hit2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(22.0, -2.0, -45.0), Vector3(22.0, -9.0, -45.0), 1))
	out.append({"what": "engine hall floor lies 6 m below the spine", "ok": not hit2.is_empty() and absf(hit2["position"].y + 6.0) < 0.05, "detail": hit2.get("position", null)})
	var hit3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(15.0, 1.0, -60.2), Vector3(15.0, -8.0, -60.2), 1))
	out.append({"what": "stair down into the engine hall has collision", "ok": not hit3.is_empty() and hit3["position"].y > -5.5 and hit3["position"].y < -0.5, "detail": hit3.get("position", null)})
	var exit_ok := exits.size() == 1 and (exits[0] as ExitTrigger).edge_id == EXIT_ID
	out.append({"what": "single exit is the doorframe (no route back to Level 10)", "ok": exit_ok})
	out.append({"what": "dead in lab coats with makeshift weapons; Hound corpses piled", "ok": dress.corpses >= 8 and dress.hounds >= 10, "detail": [dress.corpses, dress.hounds]})
	var e0 := exposure
	exposure += 15.0
	Extra.exposure_step(self)
	out.append({"what": "time near the frame is counted", "ok": exposure > e0 and _told.has("exp1")})
	exposure = 0.0
	return out
