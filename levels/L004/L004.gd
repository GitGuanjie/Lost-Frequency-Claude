extends LevelBase
## Level 4 — "Abandoned Office" (Backrooms Wikidot rev 110, accessed 2026-11-04;
## cite: "Level 4 - "Abandoned Office"" by u/M654zy on Reddit, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L004.md. Systems map to SOURCE FACT rows or to
## ADAPTATION notes in level.json.
##
## Layout: an authored anchor (stair hall by M.E.G. Base Omega, L004_anchor.gd)
## inside streamed two-storey office chunks (L004_office.gd).
## Stateful systems:
##  - Almond Water: coolers, vending machines and fountains everywhere; each
##    fills one bottle (inventory "almond_water") and restores a little health.
##  - Windows: nearly all are painted black. The few clear ones are traps:
##    standing at one and looking through builds "exposure" (the hum drains away,
##    colour drains away, a low drone rises) until it costs you (damage).
##  - Exits (office stairways down, an occasional lift) may vanish once you lose
##    direct line of sight with them; a vanished doorway is plastered over.
## Entities: none spawned (page: Hounds and Dullers observed, no behaviour given;
## Smiler unverified). Wanderers are many per the page, but there are no NPCs:
## only their traces (notes, distant doors, Base Omega's closed shutters).

const P := preload("res://levels/L004/L004_parts.gd")
const Office := preload("res://levels/L004/L004_office.gd")
const Anchor := preload("res://levels/L004/L004_anchor.gd")
const START := Vector3(8.0, 3.65, 9.2)

var parts: RefCounted
var office: RefCounted
var anchor: RefCounted
var world: ChunkWorld
var qa_fixture := false
var exposure := 0.0
var trap_hits := 0
var _vanish: Array = []          # streamed exits that may disappear
var _gone: Dictionary = {}       # "cx,cz:edge" -> true (stays gone this visit)
var _windows: Dictionary = {}    # chunk key -> [{pos, n}] clear (trap) windows
var _taken: Dictionary = {}      # dispenser id -> true
var _disp_ids: Array = []
var _force_vanish := false
var _hum: AudioStreamPlayer
var _drone: AudioStreamPlayer
var _hum_db := -19.0
var _vt := 0.0
var _warned := false
var _base_heard := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.26
	rules["reverb_wet"] = 0.09
	rules["view_distance"] = 90.0
	indoor_env(Color(0.82, 0.86, 0.92), 0.10, Color(0.06, 0.065, 0.075), 0.03)
	environment.tonemap_exposure = 0.98
	environment.glow_intensity = 0.28
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.88
	environment.adjustment_contrast = 1.06
	P.define_materials()
	lights.setup(14, 1)
	lights.max_distance = 26.0
	parts = P.new(self)
	office = Office.new(self, parts)
	anchor = Anchor.new(self, parts, office)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = Office.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", START, -136.7)
	# came back up the old stairway from Level 5: on its top landing, facing the door out
	add_arrival("from_L005", Vector3(5.4, 0.05, 8.25), 180.0)
	world.build_around(START, 2)
	_audio()
	add_shot("atrium", START + Vector3(0, 1.57, 0), Vector3(16.5, 1.0, 17.5))
	add_landmark("Gallery over the atrium (start)", START)


func _audio() -> void:
	_hum = sound.bed("fluorescent_hum", {"base": 120.0, "rasp": 0.22}, _hum_db)
	sound.bed("room_tone", {"cutoff": 170.0, "rumble": 0.35}, -23.0)
	_drone = sound.bed("pad", {"root": 55.0, "chord": [0, 1, 6], "bright": 0.08, "seconds": 8.0}, -80.0)
	sound.oneshot("knock", {"hits": 1}, 40.0, 110.0, 16.0, "[a door shuts somewhere on another floor]", -21.0)
	sound.oneshot("creak", {"freq": 80.0}, 70.0, 170.0, 12.0, "[the building ticks and settles]", -23.0)
	sound.oneshot("footstep", {"surface": "concrete", "variant": 3}, 55.0, 150.0, 14.0, "[a footstep in a distant stairwell]", -17.0)
	sound.emitter("static", Vector3(21.6, 1.4, 10.8), {"seconds": 2.0}, -24.0, 9.0)


# ------------------------------------------------------------- chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = office.build_chunk(cx, cz, node)
	var key := Vector2i(cx, cz)
	_windows[key] = meta.get("windows", [])
	for e in meta.get("exits", []):
		var rec: Dictionary = e
		rec["key"] = key
		rec["gid"] = "%d,%d:%s" % [cx, cz, rec["id"]]
		rec["seen"] = false
		rec["lost"] = 0.0
		rec["rolls"] = 0
		if _gone.has(rec["gid"]):
			_vanish_exit(rec, false)
		else:
			_vanish.append(rec)
	return meta


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("%d,%d" % [k.x, k.y])
	_windows.erase(k)
	_vanish = _vanish.filter(func(r): return r["key"] != k)


## Called by the office grammar for every cooler / vending machine / fountain.
func register_dispenser(node: Node3D, kind: String, c: Vector3, id: String) -> void:
	var it := Interactable.new()
	node.add_child(it)
	var prompt: String = {"vending": "Buy a bottle of Almond Water", "fountain": "Drink from the fountain (Almond Water)"}.get(kind, "Fill a bottle at the water cooler (Almond Water)")
	it.setup(c, Vector3(0.7, 0.9, 0.7), prompt, func(_p): drink(id, kind))
	if not _disp_ids.has(id):
		_disp_ids.append(id)


func drink(id: String, kind: String) -> void:
	if _taken.has(id):
		Overlay.toast("This one is dry for now. There are more all over the level.", 3.0)
		return
	_taken[id] = true
	SaveService.add_item("almond_water")
	if player:
		player.heal(20.0)
	var how: String = {"vending": "The machine takes nothing and drops a sealed bottle.", "fountain": "You drink, then fill a bottle."}.get(kind, "The cooler gurgles as you fill a bottle.")
	Overlay.toast("%s Almond Water: sweet, faintly nutty. (%d carried)" % [how, SaveService.item_count("almond_water")], 4.0)


func base_door(_p) -> void:
	Overlay.toast("Locked. Through the door, a radio is turned down. M.E.G. Base Omega does not open to strangers.", 4.0)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story():
		checkpoint(str(spawn_report.get("used_arrival", "start")))
		if not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
			Overlay.subtitle("[ballast hum] [stale conditioned air] [an empty office, floor after floor]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L004>L005#1", "target": Vector3(6.0, -3.6, 8.25), "note": "gallery -> fire stair down -> lobby -> old stairway down to the Level 5 landing"})


func level_process(delta: float) -> void:
	if player == null or player.camera == null:
		return
	_vt += delta
	if _vt >= 0.2:
		_tick_vanish(_vt)
		_vt = 0.0
	_tick_windows(delta)
	if not _base_heard and player.global_position.distance_to(Vector3(18.0, 0.0, 12.0)) < 6.0:
		_base_heard = true
		Overlay.subtitle("[a radio murmurs behind the shutters]", 3.0)


func _visible(p: Vector3) -> bool:
	var cam := player.camera
	var cp := cam.global_position
	if cp.distance_to(p) > 30.0 or not cam.is_position_in_frustum(p):
		return false
	var q := PhysicsRayQueryParameters3D.create(cp, p, 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or (hit["position"] as Vector3).distance_to(p) < 0.45


## Exits "may disappear unexpectedly" once direct line of sight is lost.
func _tick_vanish(dt: float) -> void:
	var pp := player.global_position
	for rec in _vanish.duplicate():
		if not is_instance_valid(rec["trig"]):
			_vanish.erase(rec)
			continue
		var zone: Rect2 = rec["zone"]
		if zone.grow(0.6).has_point(Vector2(pp.x, pp.z)):
			rec["lost"] = 0.0
			continue
		if _visible(rec["pos"]):
			rec["seen"] = true
			rec["lost"] = 0.0
		elif rec["seen"]:
			rec["lost"] += dt
			if rec["lost"] > 2.5:
				rec["seen"] = false
				rec["lost"] = 0.0
				rec["rolls"] += 1
				var roll := float(absi(hash([level_seed, rec["gid"], rec["rolls"]])) % 1000) / 1000.0
				if _force_vanish or roll < 0.5:
					_vanish_exit(rec, true)


func _vanish_exit(rec: Dictionary, live: bool) -> void:
	_gone[rec["gid"]] = true
	_vanish.erase(rec)
	var parent: Node = null
	if is_instance_valid(rec["trig"]):
		parent = (rec["trig"] as Node).get_parent()
		(rec["trig"] as Node).queue_free()
	if rec.get("door") != null and is_instance_valid(rec["door"]):
		(rec["door"] as Node).queue_free()
	var s: Variant = rec.get("seal")
	if s is Dictionary and parent is Node3D:
		var a: Vector3 = s["a"]
		var b: Vector3 = s["b"]
		var dir := (b - a).normalized()
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
		var k := GeoKit.new(parent, "Sealed")
		var lift: bool = rec["id"] == "L004>L003#3"
		k.box_xf(Transform3D(bas, a + dir * float(s["at"]) + Vector3.UP * (float(s["y"]) + 1.08)), Vector3(float(s["w"]) + 0.1, 2.16, P.T + (0.0 if lift else 0.02)),
			"l4_steel" if lift else "l4_wall")
		k.commit()
	if live and SessionState.is_story():
		SaveService.set_flag(stable_id, "saw_exit_vanish", true)


## Clear windows are traps: looking through one builds exposure.
func _tick_windows(delta: float) -> void:
	var cam := player.camera
	var cp := cam.global_position
	var fwd := -cam.global_transform.basis.z
	var look := 0.0
	for key in _windows:
		for w in _windows[key]:
			var wp: Vector3 = w["pos"]
			var to := wp - cp
			var d := to.length()
			if d > 4.5 or d < 0.05 or absf(wp.y - cp.y) > 2.2:
				continue
			if to.normalized().dot(fwd) < 0.8 or (cp - wp).dot(w["n"]) < 0.0:
				continue
			var q := PhysicsRayQueryParameters3D.create(cp, wp + (wp - cp).normalized() * 0.1, 1, [player.get_rid()])
			var hit := get_world_3d().direct_space_state.intersect_ray(q)
			if not hit.is_empty() and (hit["position"] as Vector3).distance_to(wp) > 1.3:
				continue
			look = maxf(look, 1.0 - d / 5.0)
	if look > 0.0:
		exposure = minf(1.0, exposure + delta * (0.1 + 0.28 * look))
	else:
		exposure = maxf(0.0, exposure - delta * 0.2)
	Overlay.set_screen_effect("desaturate", exposure * 0.75)
	Overlay.set_screen_effect("vignette", 0.25 + 0.6 * exposure)
	_hum.volume_db = _hum_db - 24.0 * exposure
	_drone.volume_db = -80.0 + 62.0 * minf(1.0, exposure * 1.4)
	if exposure > 0.3 and not _warned:
		_warned = true
		Overlay.subtitle("[this window was never blacked out] [the hum goes quiet]", 3.5)
	if exposure >= 1.0 and not player.dead:
		trap_hits += 1
		exposure = 0.35
		player.hurt(34.0, "You kept looking through a window that had not been blacked out")
		if not player.dead:
			Overlay.toast("You tear your eyes away from the glass. You have lost a few seconds you can't account for.", 4.5)


# ---------------------------------------------------------------------- QA

func _first_window() -> Dictionary:
	if _windows.has(Vector2i(1, 1)) and not (_windows[Vector2i(1, 1)] as Array).is_empty():
		return _windows[Vector2i(1, 1)][0]
	for key in _windows:
		if not (_windows[key] as Array).is_empty():
			return _windows[key][0]
	return {}


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	var w := _first_window()
	if not w.is_empty():
		var n: Vector3 = w["n"]
		var wp: Vector3 = w["pos"]
		plan.append({"name": "window", "pos": wp + n * 1.4 + n.cross(Vector3.UP) * 0.5, "target": wp - n * 6.0 + Vector3.UP * -2.2})
	plan.append({"name": "corridor", "pos": Vector3(24.6, 1.62, 1.2), "target": Vector3(44.0, 1.3, 1.6)})
	plan.append({"name": "oldstair", "pos": Vector3(3.3, 1.55, 8.7), "target": Vector3(3.6, -1.2, 4.8)})
	plan.append({"name": "breakroom", "pos": Vector3(17.6, 1.6, 12.2), "target": Vector3(13.0, 0.9, 3.2)})
	return plan


func qa_self_test() -> Array:
	var out: Array = []
	var space := get_world_3d().direct_space_state
	# two walkable storeys in a streamed chunk corridor
	var h1 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(25.2, 6.0, 1.2), Vector3(25.2, -2.0, 1.2), 1))
	var h0 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(25.2, 2.5, 1.2), Vector3(25.2, -2.0, 1.2), 1))
	out.append({"what": "streamed office chunk has two walkable storeys (y 3.6 and 0)", "ok": not h1.is_empty() and not h0.is_empty()
		and absf(float(h1["position"].y) - 3.6) < 0.05 and absf(float(h0["position"].y)) < 0.05, "detail": [h1.get("position"), h0.get("position")]})
	# almond water dispensers
	var before := SaveService.item_count("almond_water")
	drink("anchor:0", "vending")
	drink("anchor:0", "vending")
	out.append({"what": "Almond Water dispenser fills exactly one bottle", "ok": SaveService.item_count("almond_water") == before + 1, "detail": [_disp_ids.size(), before]})
	# clear window trap
	var w := _first_window()
	out.append({"what": "a clear (trap) window exists in the loaded light well", "ok": not w.is_empty()})
	if not w.is_empty():
		var n: Vector3 = w["n"]
		var wp: Vector3 = w["pos"]
		player.global_position = Vector3(wp.x, wp.y - 1.65 + 0.05, wp.z) + n * 1.5
		player.velocity = Vector3.ZERO
		player.rotation.y = atan2(n.x, n.z)
		player.head.rotation.x = 0.0
		player.health = 100.0
		var peak := 0.0
		for i in 900:
			await get_tree().process_frame
			peak = maxf(peak, exposure)
			if trap_hits > 0:
				break
		out.append({"what": "looking through a clear window builds exposure and then hurts", "ok": peak > 0.6 and trap_hits > 0 and player.health < 100.0, "detail": [peak, trap_hits, player.health]})
		player.health = 100.0
		player.rotation.y += PI
		for i in 60:
			await get_tree().process_frame
		exposure = 0.0
	# exits vanish after line of sight is lost
	var t := make_exit("L004>L071#4", "walk_in", Vector3(0, -60, 0), Vector3(0.5, 0.5, 0.5), "", self)
	var cam := player.camera
	var rec := {"trig": t, "id": "L004>L071#4", "gid": "qa:test", "key": Vector2i(99, 99), "pos": cam.global_position + cam.global_transform.basis.z * 6.0,
		"zone": Rect2(-900, -900, 1, 1), "seal": null, "door": null, "seen": true, "lost": 0.0, "rolls": 0}
	_vanish.append(rec)
	_force_vanish = true
	for i in 240:
		await get_tree().process_frame
	_force_vanish = false
	out.append({"what": "an exit out of line of sight vanishes (trigger removed)", "ok": not is_instance_valid(t) and _gone.has("qa:test")})
	var anchors_ok := 0
	for e in exits:
		if is_instance_valid(e) and (e.edge_id == "L004>L005#1" or e.edge_id == "L004>L006#2"):
			anchors_ok += 1
	out.append({"what": "anchor stairways to Levels 5 and 6 stay put", "ok": anchors_ok >= 2, "detail": anchors_ok})
	return out
