extends LevelBase
## Level 1.3 — "Malignance" (Backrooms Wiki rev 35, accessed 2026-11-04;
## cite: DivineAtlas, CC BY-SA 3.0; part of the Decay Canon). Dossier:
## docs/canon/levels/L001_3.md.
##
## DESIGN PLAN
## Space: "a lengthy, single hallway with branching paths to the left and right",
##   each path leading to "one of sixteen large rooms" (page). The hallway (5 m
##   wide, 3.6 m) runs 204 m from the south end wall (where you come through from
##   Level 1) to the north end wall; eight branch pairs, one per streamed 24 m
##   chunk, open through 6 m corridors into 16 x 18 m rooms 5.4 m high. Floors are
##   unblemished soft white tile, walls pristine white, ceilings flush light panels.
## Rooms (seeded order): eight Detox Zones (The Ward is "stationed in all eight
##   zones"): an empty sunken zone edged with green tape, ringed by Ward beds,
##   curtains, IV stands, monitors and a nurses' station; and eight rooms of
##   "medical supplies and equipment": three supply stores and two surgeries with a
##   steel mezzanine (stores up top, an observation deck), M.E.G. admissions,
##   staff quarters and a pharmacy. The M.E.G. checkpoint stands at the south end.
## Second heights: sunken Detox Zones (three risers down), mezzanines (+2.7 m).
## Two states (dossier): White Halls (the article) or the Decay "Dead Zone"
##   (testimony), a seeded flag. Decay: black pits cut real holes in the floor and
##   swallow whatever falls in, white walls buckle toward them, irregular spots of
##   pure blackness, dried brown blood streaks, most lights dead, rancid humid air,
##   the Detox Zones mostly a gaping abyss, the Ward abandoned and overturned.
## Signature mechanic (SOURCE): standing in a Detox Zone heals you fast but it
##   burns (red pulse, captions); in the Decay state the zone first closes a wound
##   and then the skin bubbles and tears (damage that grows while you stay). In the
##   White state damaged tile regenerates while you watch. Decay pits take the
##   fishing-line test (a yard goes in, less than a foot comes back).
## Exits: no-clip into either end of the main hallway (L001_3>L001#1, noclip, hold).
## Entities: none (page). M.E.G. staff are absent: off shift (White) or gone (Dead).
## ADAPTATION: the hallway length (page: one square mile), room sizes and layout,
##   heal/damage numbers, the mezzanines, which rooms hold what.

const Geo := preload("res://levels/L001_3/L001_3_geo.gd")
const Dress := preload("res://levels/L001_3/L001_3_dress.gd")
const SPAWN := Vector3(0.0, 0.05, 3.0)
const EXIT_ID := "L001_3>L001#1"

var geo
var dress
var world: ChunkWorld
var decay := false
var metas: Dictionary = {}
var zones: Array = []        # {rect, no, chunk}
var notes_staged := 0
var line_used := 0
var _zone_t := 0.0
var _in_zone := -1
var _told: Dictionary = {}
var _t := 0.0
var _pulse := 0.0
var _hum: AudioStreamPlayer
var _tone: AudioStreamPlayer


func build() -> void:
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.2
	rules["view_distance"] = 160.0
	rules["kill_y"] = -30.0
	decay = absi(hash([level_seed, "decay"])) % 3 == 0
	_materials()
	geo = Geo.new(self)
	geo.plan(rng)
	dress = Dress.new(self)
	lights.setup(14, 1)
	lights.max_distance = 30.0
	_env(decay)
	world = ChunkWorld.new()
	world.name = "Hallway"
	world.chunk_size = Geo.S
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L001", SPAWN, 0.0)
	world.build_around(SPAWN, 2)
	_checkpoint()
	_hum = sound.bed("fluorescent_hum", {"base": 120.0, "rasp": 0.1}, -27.0)
	_tone = sound.bed("room_tone", {"cutoff": 420.0, "rumble": 0.15}, -28.0)
	_audio_state()
	add_landmark("South end wall (from Level 1)", Vector3(0, 0, 5))
	add_landmark("M.E.G. checkpoint", Vector3(-1.6, 0, -3.5))
	add_landmark("North end wall", Vector3(0, 0, Geo.NORTH + 1.0))
	_shots()


func _materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	m.call("l13_tile", "pool_tile", {"albedo_a": Color(0.9, 0.91, 0.92), "albedo_b": Color(0.87, 0.88, 0.89), "pattern_scale": Vector2(0.9, 0.9),
		"grout_width": 0.004, "grout_color": Color(0.8, 0.81, 0.82), "roughness_a": 0.3, "roughness_b": 0.42, "bump_strength": 0.15})
	m.call("l13_zone_tile", "pool_tile", {"albedo_a": Color(0.84, 0.9, 0.91), "albedo_b": Color(0.81, 0.87, 0.88), "pattern_scale": Vector2(0.6, 0.6),
		"grout_width": 0.005, "grout_color": Color(0.72, 0.8, 0.81), "roughness_a": 0.25})
	m.call("l13_wall", "plaster", {"albedo_a": Color(0.9, 0.91, 0.92), "albedo_b": Color(0.88, 0.89, 0.9), "noise_scale": 0.5, "bump_strength": 0.08, "roughness_a": 0.7})
	m.call("l13_wall_end", "plaster", {"albedo_a": Color(0.93, 0.94, 0.95), "albedo_b": Color(0.91, 0.92, 0.93), "noise_scale": 0.5, "bump_strength": 0.05})
	m.call("l13_ceiling", "l0_ceiling", {"albedo_a": Color(0.92, 0.93, 0.94), "albedo_b": Color(0.9, 0.91, 0.92), "stain_amount": 0.0, "grout_color": Color(0.84, 0.85, 0.86), "pattern_scale": Vector2(1.2, 1.2)})
	m.call("l13_trim", "trim_white", {})
	m.call("l13_skirt", "trim_white", {"albedo_a": Color(0.7, 0.74, 0.76), "albedo_b": Color(0.68, 0.72, 0.74)})
	m.call("l13_steel", "metal", {"albedo_a": Color(0.74, 0.76, 0.78), "albedo_b": Color(0.68, 0.7, 0.72), "metallic_value": 0.8, "roughness_a": 0.3, "stain_amount": 0.0})
	m.call("l13_deck_metal", "metal", {"albedo_a": Color(0.6, 0.62, 0.64), "albedo_b": Color(0.55, 0.57, 0.59), "pattern": 9, "pattern_scale": Vector2(0.05, 0.05),
		"pattern_color": Color(0.5, 0.52, 0.54), "pattern_strength": 0.4, "metallic_value": 0.7, "stain_amount": 0.0})
	m.call("l13_linen", "plaster", {"albedo_a": Color(0.94, 0.95, 0.95), "albedo_b": Color(0.9, 0.91, 0.92), "noise_scale": 3.0, "bump_strength": 0.4})
	m.call("l13_blanket", "plaster", {"albedo_a": Color(0.86, 0.76, 0.42), "albedo_b": Color(0.8, 0.7, 0.38), "noise_scale": 4.0, "bump_strength": 0.6})
	m.call("l13_gurney_pad", "plaster", {"albedo_a": Color(0.82, 0.68, 0.22), "albedo_b": Color(0.76, 0.62, 0.2), "roughness_a": 0.5})
	m.call("l13_bedframe", "trim_white", {"albedo_a": Color(0.8, 0.83, 0.85), "albedo_b": Color(0.78, 0.81, 0.83)})
	m.call("l13_rubber", "plaster", {"albedo_a": Color(0.08, 0.08, 0.09), "albedo_b": Color(0.07, 0.07, 0.08)})
	m.call("l13_curtain", "plaster", {"albedo_a": Color(0.6, 0.76, 0.72), "albedo_b": Color(0.56, 0.72, 0.68), "pattern": 2, "pattern_scale": Vector2(0.05, 1.0),
		"pattern_color": Color(0.5, 0.66, 0.62), "pattern_strength": 0.3, "noise_scale": 2.0})
	m.call("l13_cart", "trim_white", {"albedo_a": Color(0.88, 0.89, 0.9), "albedo_b": Color(0.85, 0.86, 0.87)})
	m.call("l13_counter", "plaster", {"albedo_a": Color(0.62, 0.66, 0.68), "albedo_b": Color(0.58, 0.62, 0.64), "roughness_a": 0.3, "noise_scale": 3.0})
	m.call("l13_box_white", "plaster", {"albedo_a": Color(0.86, 0.87, 0.86), "albedo_b": Color(0.82, 0.83, 0.82), "roughness_a": 0.6})
	m.call("l13_cardboard", "plaster", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.48, 0.36, 0.22), "noise_scale": 4.0})
	m.call("l13_pad", "plaster", {"albedo_a": Color(0.2, 0.3, 0.38), "albedo_b": Color(0.18, 0.27, 0.35), "roughness_a": 0.4})
	m.call("l13_drape", "plaster", {"albedo_a": Color(0.26, 0.5, 0.55), "albedo_b": Color(0.24, 0.46, 0.51)})
	m.call("l13_locker", "metal", {"albedo_a": Color(0.58, 0.64, 0.7), "albedo_b": Color(0.54, 0.6, 0.66), "pattern": 1, "pattern_scale": Vector2(0.45, 1.9),
		"grout_width": 0.01, "grout_color": Color(0.3, 0.33, 0.36), "metallic_value": 0.5, "stain_amount": 0.0})
	m.call("l13_sign", "plaster", {"albedo_a": Color(0.12, 0.3, 0.36), "albedo_b": Color(0.11, 0.28, 0.34), "roughness_a": 0.4})
	m.call("l13_tape", "plaster", {"albedo_a": Color(0.12, 0.62, 0.24), "albedo_b": Color(0.1, 0.56, 0.22), "roughness_a": 0.35})
	m.call("l13_blood", "plaster", {"albedo_a": Color(0.24, 0.1, 0.05), "albedo_b": Color(0.32, 0.14, 0.07), "noise_scale": 6.0, "roughness_a": 0.75})
	MatLib.register("l13_void", MatLib.get_mat("unlit_black"))
	MatLib.register("l13_glass", MatLib.get_mat("glass"))
	var bag := StandardMaterial3D.new()
	bag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bag.albedo_color = Color(0.85, 0.92, 0.95, 0.5)
	bag.roughness = 0.15
	MatLib.register("l13_ivbag", bag)
	MatLib.register("l13_panel", MatLib.panel(Color(0.98, 0.99, 1.0), 3.2))
	MatLib.register("l13_panel_dim", MatLib.panel(Color(0.9, 0.86, 0.76), 0.8))
	MatLib.register("l13_panel_flick", MatLib.panel(Color(0.92, 0.9, 0.82), 1.8, 1.0))
	MatLib.register("l13_panel_dead", MatLib.panel(Color(0.14, 0.14, 0.14), 0.0, 0.0, 100.0))
	MatLib.register("l13_screen", MatLib.panel(Color(0.3, 0.95, 0.55), 1.2))
	MatLib.register("l13_screen_dead", MatLib.panel(Color(0.04, 0.05, 0.05), 0.0, 0.0, 100.0))


func _env(d: bool) -> void:
	if d:
		indoor_env(Color(0.62, 0.58, 0.54), 0.065, Color(0.06, 0.055, 0.05), 0.03)
		environment.background_color = Color(0, 0, 0)
		environment.tonemap_exposure = 0.95
		environment.glow_intensity = 0.25
		environment.glow_hdr_threshold = 1.0
		environment.adjustment_enabled = true
		environment.adjustment_saturation = 0.72
		environment.adjustment_contrast = 1.12
	else:
		indoor_env(Color(0.96, 0.98, 1.0), 0.42, Color(0.62, 0.64, 0.66), 0.006)
		environment.background_color = Color(0.9, 0.92, 0.94)
		environment.tonemap_exposure = 1.0
		environment.glow_intensity = 0.55
		environment.glow_hdr_threshold = 0.95
		environment.glow_bloom = 0.08
		environment.adjustment_enabled = true
		environment.adjustment_saturation = 0.9
		environment.adjustment_contrast = 1.04


func _audio_state() -> void:
	if _hum:
		_hum.volume_db = -60.0 if decay else -27.0
	if _tone:
		_tone.volume_db = -22.0 if decay else -28.0
	if decay:
		sound.oneshot("drip", {"freq": 900.0}, 6.0, 16.0, 9.0, "[water drips in the humid dark]", -14.0)
		sound.oneshot("creak", {"freq": 46.0}, 18.0, 45.0, 12.0, "[a wall groans as it bends toward a pit]", -10.0)


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if cx != 0:
		return {}
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cz, "l13", decay])
	geo.decay = decay
	dress.decay = decay
	var meta: Dictionary = geo.build_chunk(cz, node, r)
	var k := GeoKit.new(node, "Dress")
	if cz <= -1 and cz >= -8:
		var i := Geo.pair_of_chunk(cz)
		for rec in meta["rooms"]:
			dress.room(node, k, rec, r)
			if rec["type"] == "detox":
				zones.append({"rect": rec["zone_rect"], "no": rec["zone"], "chunk": cz})
		dress.hallway(node, k, i, r)
		if decay and not meta["hall_pits"].is_empty() and cz >= -2:
			_line_spot(node, k, meta["hall_pits"][0])
	k.commit()
	if cz == 0:
		var t := make_exit(EXIT_ID, "noclip", Vector3(0, 1.3, Geo.SOUTH), Vector3(4.6, 2.6, 1.6), "Push through the end wall (Level 1)", node)
		if t:
			t.hold_seconds = 1.5
	elif cz == -9:
		var t2 := make_exit(EXIT_ID, "noclip", Vector3(0, 1.3, Geo.NORTH), Vector3(4.6, 2.6, 1.6), "Push through the end wall (Level 1)", node)
		if t2:
			t2.hold_seconds = 1.5
	metas[cz] = meta
	return meta


func _on_unload(k: Vector2i) -> void:
	if k.x != 0:
		return
	lights.remove_group("k%d" % k.y)
	metas.erase(k.y)
	zones = zones.filter(func(z): return z["chunk"] != k.y)
	dress.cracks = dress.cracks.filter(func(c): return is_instance_valid(c["node"]) and not (c["node"] as Node).is_queued_for_deletion())
	exits = exits.filter(func(t): return is_instance_valid(t) and not t.is_queued_for_deletion())


## The scout's test (Decay): a spool of fishing line at the first hallway pit.
func _line_spot(node: Node3D, k: GeoKit, hr: Rect2) -> void:
	var side := signf(hr.get_center().x)
	var p := Vector3(hr.get_center().x - side * (hr.size.x * 0.5 + 0.35), 0.0, hr.get_center().y)
	k.cylinder(p + Vector3(0, 0.03, 0), 0.06, 0.06, "l13_steel", 10, false)
	k.cylinder(p + Vector3(0, 0.03, 0), 0.045, 0.065, "l13_tape", 10, false)
	make_interactable(p + Vector3(0, 0.3, 0), Vector3(0.9, 0.7, 0.9), "Lower the fishing line into the pit", _line_test, node)


func _line_test() -> void:
	line_used += 1
	if line_used == 1:
		Overlay.toast("You measure out about a yard of line and let it dangle into the black. When you pull it up, less than a foot comes back. The end is gone.", 5.0)
	else:
		Overlay.toast("You toss the rest of the spool into the hole. It makes no sound.", 3.0)


## The M.E.G. checkpoint just inside the south end (static, near the arrival).
func _checkpoint() -> void:
	var node := Node3D.new()
	node.name = "Checkpoint"
	add_child(node)
	var k := GeoKit.new(node, "K")
	var dp := Vector3(-1.75, 0, -3.6)
	dress.p(node, "ph/metal_office_desk", dp, 90.0 + (25.0 if decay else 0.0), 0.0, true)
	dress.p(node, "kenney/furniture-kit/chairdesk", dp + Vector3(-0.85, 0, 0.2), 90.0 + (70.0 if decay else 0.0), 1.0)
	dress.p(node, "ph/vintage_radio_transceiver", dp + Vector3(0.05, 0.79, 0.6), 90.0)
	dress.p(node, "ph/classic_laptop", dp + Vector3(0.05, 0.79, -0.3), 90.0, 0.3)
	dress.p(node, "ph/security_camera_01", Vector3(-2.35, 3.3, 4.6), 135.0)
	for z: float in [-1.0, -6.2]:
		k.box(Vector3(1.9, 0.5, z), Vector3(0.05, 1.0, 0.05), "l13_steel", GeoKit.ALL, false)
		k.box(Vector3(1.9, 0.02, z), Vector3(0.3, 0.04, 0.3), "l13_steel", GeoKit.ALL, false)
	k.box(Vector3(1.9, 0.9, -3.6), Vector3(0.03, 0.06, 5.2), "l13_tape", GeoKit.ALL, false)
	dress.sign_plate(node, k, Vector3(0, 3.2, Geo.SOUTH - 0.17), PI, "THE WARD  ·  M.E.G.  ·  LEVEL 1.3")
	k.commit()
	var at := dp + Vector3(0.1, 0.81, 0.1)
	if decay:
		add_note("L001_3_docs", "Binder: M.E.G. documents (Dead Zone)",
			"[i]A binder left on the checkpoint desk. Paraphrased.[/i]\n\nWARNING: the M.E.G. has reclassified Level 1.3 as a Dead Zone. Only sanctioned operatives may enter. Anomalies followed what is suspected to be Decay, and the Detox Zones have produced strange effects.\n\n[b]Document 1, Dr. Reathe's autopsy notes.[/b] Three patients who came for healing died of extreme, lethal overproduction or overreaction: a fatal allergic response with no known allergen, runaway growths, organs drowned in their own fluid. Reathe's own old nerve damage never healed here.\n\n[b]Document 2, a scout's log.[/b] Rancid humid air. White walls bending into spots of pure blackness. A yard of fishing line lowered into a pit; less than a foot came back. Dried brown blood across the tile. At the Ward, green tape marks a Detox Zone that is mostly abyss. He cut his arm and reached in: the wound closed, then the skin around it bubbled and tore.\n\n[b]Document 3, the Director's note.[/b] The scout's arm was amputated. The level is no longer of use. \"We can't even no-clip into the level anymore.\"",
			at)
	else:
		add_note("L001_3_leaflet", "M.E.G. patient leaflet",
			"[i]A laminated leaflet on the checkpoint desk. Paraphrased.[/i]\n\nWELCOME TO LEVEL 1.3. The M.E.G. manages entry; the injured and seriously ill go first.\n\nThe sixteen rooms off this hallway hold medical supplies and equipment, or a Detox Zone. Exposure to a Detox Zone heals broken bones, wounds, fevers and poisoning quickly. Serious illness can take days or weeks. Congenital illness is not cured.\n\nWait for a doctor before you go in: bones heal as they lie, and badly set ones heal wrong. Expect burning and sharp pain until healing is complete.\n\nThe Ward's staff are in all eight zones. To return to Level 1, no-clip into either end of the main hallway.",
			at)
	notes_staged = 1


# ------------------------------------------------------------------ state

func _set_state(d: bool) -> void:
	if d == decay:
		return
	decay = d
	_env(d)
	_audio_state()
	var keys: Array = world.chunks.keys()
	for key in keys:
		world.rebuild(key, false)


func on_player_ready() -> void:
	world.target = player
	if SessionState.is_qa():
		return
	if decay:
		Overlay.subtitle("[a wash of rancid, humid air. Under the rot, the sharp smell of cleaning chemicals.]", 5.0)
	else:
		Overlay.subtitle("[blinding white. The sharp smell of cleaning chemicals.]", 4.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var pp := player.global_position
	# Detox Zones
	var zi := -1
	for i in zones.size():
		var zr: Rect2 = zones[i]["rect"]
		if zr.has_point(Vector2(pp.x, pp.z)) and pp.y < -0.25 and pp.y > -1.2:
			zi = i
	if zi != _in_zone:
		_in_zone = zi
		_zone_t = 0.0
		if zi >= 0:
			_enter_zone()
	if zi >= 0:
		_detox_step(delta)
	else:
		_pulse = maxf(0.0, _pulse - delta * 1.5)
	if not SessionState.is_qa():
		Overlay.set_screen_effect("red_tint", _pulse)
	# Decay pits swallow whatever falls in
	if decay and pp.y < -3.0 and not player.dead:
		player.hurt(1000.0, "swallowed by a Decay pit")
	# White state: damaged tile regenerates while you watch
	if not decay:
		for c in dress.cracks:
			if not is_instance_valid(c["node"]) or c["heal"] <= 0.0:
				continue
			if (c["node"] as Node3D).global_position.distance_to(pp) < 7.0:
				c["heal"] = maxf(0.0, c["heal"] - delta / 20.0)
				(c["mat"] as StandardMaterial3D).albedo_color.a = 0.9 * c["heal"]
				if c["heal"] <= 0.0:
					(c["node"] as Node3D).visible = false
				if not _told.has("crack") and not SessionState.is_qa():
					_told["crack"] = true
					Overlay.subtitle("[a crack in the tile is slowly knitting itself back together]", 4.0)


func _enter_zone() -> void:
	if SessionState.is_qa():
		return
	if decay:
		Overlay.subtitle("[a familiar burning; your fingertips tingle]", 3.0)
	elif player.health < 99.0:
		Overlay.subtitle("[a burning, sharp pain as the Detox Zone closes your wounds]", 3.5)
	else:
		Overlay.subtitle("[your skin tingles. There is nothing here to heal.]", 3.0)


## One step of Detox Zone exposure. White: fast, painful healing. Decay: the wound
## closes, then the healing overreacts and tears the flesh (damage grows).
func _detox_step(delta: float) -> void:
	_zone_t += delta
	if not decay:
		if player.health < 100.0:
			player.heal(7.0 * delta)
			_pulse = 0.22 + 0.12 * sin(_t * 7.0)
			if player.health >= 99.9 and not SessionState.is_qa():
				Overlay.toast("The burning fades. You are whole again.", 3.0)
		else:
			_pulse = maxf(0.0, _pulse - delta)
		return
	if _zone_t < 1.6:
		player.heal(4.0 * delta)
		_pulse = 0.15
		return
	if not _told.has("tear") and not SessionState.is_qa():
		_told["tear"] = true
		Overlay.subtitle("[the skin around the wound bubbles and tears]", 3.5)
		Overlay.glitch(0.3)
	player.hurt((6.0 + 4.0 * (_zone_t - 1.6)) * delta, "the Detox Zone's healing turned on you")
	_pulse = 0.5 + 0.2 * sin(_t * 11.0)


# ------------------------------------------------------------------ QA

func _shots() -> void:
	add_shot("hallway", Vector3(0.7, 1.62, 1.5), Vector3(-0.2, 1.3, -70.0), {"prepare": func(): await _prep(false, Vector3(0, 0, -10))})
	add_shot("checkpoint", Vector3(1.6, 1.62, 1.0), Vector3(-1.9, 0.9, -4.5), {"prepare": func(): await _prep(false, Vector3(0, 0, -10))})


func _prep(d: bool, at: Vector3) -> void:
	_set_state(d)
	world.build_around(at, 1)
	await get_tree().process_frame


func _first(typ: String) -> Array:
	for idx in geo.types.size():
		if geo.types[idx] == typ:
			return [idx / 2, 1 if idx % 2 == 1 else -1]
	return []


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	var dx := _first("detox")
	if not dx.is_empty():
		var i: int = dx[0]
		var s: int = dx[1]
		var zc := Geo.pair_z(i)
		var o := Vector3(float(s) * (Geo.RX0 + 0.9), 1.7, zc + 2.2)
		var tg := Vector3(float(s) * (Geo.RX0 + 11.0), 0.0, zc - 3.5)
		plan.append({"name": "ward", "pos": o, "target": tg, "prepare": func(): await _prep(false, o)})
		plan.append({"name": "ward_decay", "pos": o, "target": tg, "prepare": func(): await _prep(true, o)})
	var sp := _first("supplies")
	if not sp.is_empty():
		var i2: int = sp[0]
		var s2: int = sp[1]
		var zc2 := Geo.pair_z(i2)
		var o2 := Vector3(float(s2) * (Geo.RX0 + 1.0), 1.62, zc2 + 7.6)
		plan.append({"name": "supplies_mezzanine", "pos": o2, "target": Vector3(float(s2) * (Geo.RX0 + 14.0), 2.2, zc2 - 3.0), "prepare": func(): await _prep(false, o2)})
	var sg := _first("surgery")
	if not sg.is_empty():
		var i3: int = sg[0]
		var s3: int = sg[1]
		var zc3 := Geo.pair_z(i3)
		var o3 := Vector3(float(s3) * (Geo.RX0 + 1.0), 1.62, zc3 - 6.5)
		plan.append({"name": "surgery", "pos": o3, "target": Vector3(float(s3) * (Geo.RX0 + 8.0), 1.0, zc3 + 1.0), "prepare": func(): await _prep(false, o3)})
	plan.append({"name": "hallway_decay", "pos": Vector3(0.6, 1.62, -1.0), "target": Vector3(-0.3, 0.8, -40.0), "prepare": func(): await _prep(true, Vector3(0, 0, -20))})
	plan.append({"name": "decay_pit", "pos": Vector3(-1.2, 1.62, -25.0), "target": Vector3(0.6, 0.0, -36.0), "prepare": func(): await _prep(true, Vector3(0, 0, -30))})
	return plan


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	_set_state(false)
	world.build_around(SPAWN, 2)
	var detox := 0
	for t in geo.types:
		if t == "detox":
			detox += 1
	out.append({"what": "sixteen rooms, eight of them Detox Zones", "ok": geo.types.size() == 16 and detox == 8, "detail": geo.types})
	out.append({"what": "a Detox Zone in the first branch pair", "ok": geo.types[0] == "detox" or geo.types[1] == "detox"})
	out.append({"what": "rooms dressed (Ward beds, racks, models)", "ok": dress.beds >= 10 and dress.props >= 20, "detail": [dress.beds, dress.props]})
	var space := get_world_3d().direct_space_state
	var zr: Rect2 = Geo.zone_rect(0, 1 if geo.types[1] == "detox" else -1)
	var c := Vector3(zr.get_center().x, 0, zr.get_center().y)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(c + Vector3(0, 1.5, 0), c + Vector3(0, -2.0, 0), 1))
	out.append({"what": "sunken Detox Zone floor three risers down", "ok": not hit.is_empty() and absf(hit["position"].y - Geo.ZONE_Y) < 0.05, "detail": hit.get("position", null)})
	# Detox exposure heals (White) ...
	player.health = 40.0
	_zone_t = 0.0
	for n in 3:
		_detox_step(1.0)
	var healed := player.health
	out.append({"what": "White Detox Zone heals fast", "ok": healed >= 58.0, "detail": healed})
	# ... a stretch of damaged tile regenerates
	var crack_ok: bool = dress.cracks.size() > 0
	out.append({"what": "regenerating tile damage present in the White state", "ok": crack_ok, "detail": dress.cracks.size()})
	# both ends of the hallway are noclip exits back to Level 1
	world.build_around(Vector3(0, 0, Geo.NORTH), 0)
	var ends := 0
	for t in exits:
		if is_instance_valid(t) and t.edge_id == EXIT_ID and t.kind == "noclip":
			ends += 1
	out.append({"what": "noclip exits at both ends of the main hallway", "ok": ends >= 2, "detail": ends})
	# Decay state: pits cut the floor, the zone turns on you
	_set_state(true)
	world.build_around(SPAWN, 2)
	for n in 3:
		await get_tree().physics_frame
	var pits := 0
	for k in metas.keys():
		pits += (metas[k].get("pits", []) as Array).size()
	out.append({"what": "Decay state opens black pits in the floor", "ok": pits >= 4, "detail": pits})
	var ph: Rect2 = Rect2()
	for k in metas.keys():
		for h in metas[k].get("hall_pits", []):
			ph = h
	var pc := Vector3(ph.get_center().x, 0, ph.get_center().y)
	var hit2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(pc + Vector3(0, 1.5, 0), pc + Vector3(0, -3.0, 0), 1))
	out.append({"what": "a pit is a real hole (no floor collision)", "ok": ph.size.x > 0.0 and hit2.is_empty(), "detail": [ph, hit2.get("position", null)]})
	player.health = 80.0
	_zone_t = 0.0
	for n in 4:
		_detox_step(1.0)
	out.append({"what": "Decay Detox Zone heals, then tears (net damage)", "ok": player.health < 80.0, "detail": player.health})
	player.health = 100.0
	player.dead = false
	_pulse = 0.0
	_set_state(false)
	world.build_around(SPAWN, 2)
	return out
