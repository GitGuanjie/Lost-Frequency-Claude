extends LevelBase
## Level 188 - "The Courtyard of Windows" (Backrooms Wikidot rev 69, accessed
## 2026-11-04; cite: Kai4C, CC BY-SA 3.0). Dossier: docs/canon/levels/L188.md.
## Survival class 5 (Exit 5/5 dead end, Environment 4/5, Entities 5/5).
## A cold, silent, irregular white-concrete atrium (~48 m across, 30 m tall)
## whose walls carry evenly spaced windows, most with blinds, many replaced by
## living window entities. Stateful rules:
##  - the entry window stays open 2-3 minutes; climbing back through it is the
##    only sourced way out ("@origin"), then it is just a window
##  - NAA/NVA exposure: nearing windows, staring into open ones, looking
##    straight at silhouettes, touching glass railings, standing in the wooden
##    circle, going to the table or handling its objects; full exposure kills
##  - emergency protocol: crouch and stay still with eyes bound for "6-8 hours"
##    (compressed); apparitions test you; meanwhile the courtyard shifts (the
##    table moves to the middle, windows shift and multiply, balloons, music)
##  - vacant windows: the rumoured way to Level 1.5 (unbuilt); some are not vacant
##  - mahogany doors (one shifts when unobserved) to clinical corridors, a
##    stairwell, walkways at 8 m and 16 m and a bridge over the pentagon; falls kill
##  - a pink-dress faceling on one corridor floor; silhouettes at corners
## Geometry: L188_geo.gd. No settlement, no noise: silence is the soundtrack.

const G := preload("res://levels/L188/L188_geo.gd")
const DAISY := [7, 7, 4, 4, 0, 0, -5, -5, -3, -1, 0, -3, 0, -5, -5, -5, 2, 2, 7, 7, 4, 4, 0, 0, -3, -1, 0, 2, 4, 2, 2, 2]
const DEATH := {"window": "You went to the windows. They are not exits.", "railing": "You kept your hands on the glass railing.",
	"circle": "You stood in the wooden circle. It is not a trapdoor.", "table": "You went to the table.",
	"object": "You handled the things on the table.", "look": "You looked straight at them.",
	"cold": "The courtyard wore you down. (The advisory card says how to wait it out.)", "protocol": "You answered them. They are not real."}
const SENSE := ["[a dry itch crawls over your skin]", "[numbness spreads through your fingers]", "[tingling runs along your arms]",
	"[something wet trickles down your neck]", "[a voice across the courtyard calls your name]", "[footsteps stop right beside you]",
	"[someone whispers in a voice like yours]"]
const ADVISORY := "M.E.G. ADVISORY: COURTYARD OF WINDOWS (laminated card, edges worn)\n\nIf you came in through a window, go back out through that same window now. Entry windows close within two or three minutes and become ordinary windows.\n\nEvery other window: keep away. They are not exits, and many of them are not windows at all. Do not look straight at anything you see moving in them.\n\nDo not touch the glass railings. Do not touch or stand on the wooden circle; it is not a trapdoor. Stay away from the table, and do not handle the clock, the gramophone or anything else on it.\n\nIf you cannot leave: cover your eyes and ears, crouch with your head down and your arms locked behind your neck, and do not move for six to eight hours. Do not react to anything you feel or hear, human or otherwise. They are not real.\n\n(Rumour, unconfirmed: vacant windows lead to Level 1.5.)"
const LOGS := "Field recorder, M.E.G. Team Owl-Eyes. Audio corrupted; transcript fragments only.\n\n1. Arrived. Maybe a dozen window entities in view, possibly more. The atrium is otherwise clear: a clock sitting in the middle on a round patch of wood, a table in the far corner.\n\n2. The window we came through is gone; there's an ordinary window in its place. The wooden circle sounds hollow, but a crowbar won't move it. On the table: a gramophone and a copy of The Great Gatsby.\n\n3. About four hours in. We slept with one man on watch and woke to the gramophone playing. The man on watch is gone. The table has moved into the middle of the room. The windows have moved too, and there are more of them than before. Someone is standing in one of the windows-"
const BOOK := "An old copy of The Great Gatsby. The print is wrong in places: misspellings, words out of order, and the mistakes multiply the further you read. About halfway through it stops making sense."

var es: Array = []
var wins: Array = []
var rails: Array = []
var walk: Dictionary = {}
var locked: Array = []
var spacing := 5.6
var rows := 6
var live := 0.4
var shifts := 0
var naa := 0.0
var cause := "cold"
var entry: Dictionary = {}
var entry_t := 150.0
var entry_open := true
var entry_mat: StandardMaterial3D
var entry_pane: MeshInstance3D
var entry_mus: AudioStreamPlayer3D
var entry_warned := false
var vacs: Array = []
var wall_root: Node3D
var face_root: Node3D
var door_root: Node3D
var door_a := true
var door_t := 60.0
var table: Node3D
var clock_node: Node3D
var gramo: AudioStreamPlayer3D
var gramo_t := 0.0
var figs: Array = []
var fig_cd := 6.0
var cfig: MeshInstance3D
var cfig_t := -1.0
var cfig_cd := 8.0
var face: Node3D
var face_u := 4.0
var face_w := 1.8
var face_y := 8.0
var face_dir := 1.0
var face_wait := 0.0
var face_step := 0.0
var face_alert := false
var still_t := 0.0
var proto_on := false
var proto_t := 0.0
var proto_need := 70.0
var proto_app := 5.0
var air_top := 0.0
var flash := 0.0
var _black := 0.0
var _vert := 0.0
var _wt := 8.0
var _st := 10.0
var _tick := 1.0
var _rail_cap := 0.0
var _knock := 0.0
var heart: AudioStreamPlayer


func build() -> void:
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.95
	rules["reverb_wet"] = 0.42
	rules["view_distance"] = 160.0
	indoor_env(Color(0.86, 0.9, 0.96), 0.38, Color(0.84, 0.87, 0.92), 0.0045)
	environment.tonemap_exposure = 0.92
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 1.3
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.78
	environment.adjustment_contrast = 1.06
	var sky := DirectionalLight3D.new()
	sky.name = "Skylight"
	sky.rotation_degrees = Vector3(-62.0, 35.0, 0.0)
	sky.light_color = Color(0.93, 0.96, 1.0)
	sky.light_energy = 1.35
	sky.shadow_enabled = true
	sky.directional_shadow_max_distance = 90.0
	add_child(sky)
	G.materials()
	lights.setup(8, 0)
	lights.max_distance = 24.0
	es = G.edges()
	_load_state()
	var k := kit("Atrium")
	G.ground(k)
	walk = G.walkways(k, es, rails)
	locked = G.annex(self, k, es[G.AX])
	var cr := RandomNumberGenerator.new()
	cr.seed = hash([level_seed, "clutter"])
	G.clutter(k, self, cr)
	G.door(k, es[G.AX], 11.025, 8.0, true)
	G.door(k, es[G.AX], 6.025, 16.0, true)
	k.commit()
	_build_doors()
	_make_walls()
	var e6: Dictionary = es[G.EN]
	var n: Vector3 = e6["n"]
	var ap := G.ep(e6, entry["u"], -1.6, 0.05)
	var yaw := rad_to_deg(atan2(-n.x, -n.z))
	add_arrival("start", ap, yaw)
	add_arrival("from_L025", ap, yaw)
	if entry_open:
		entry_mat = StandardMaterial3D.new()
		entry_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		entry_mat.albedo_color = Color(0.95, 0.5, 0.38)
		entry_pane = G.pane(self, e6, entry["u"], entry["sill"], entry_mat)
		lights.add_anchor(G.ep(e6, entry["u"], -0.6, 2.2), Color(1.0, 0.55, 0.4), 1.5, 7.0, 0.0, "entry")
		var t := add_exit("L188>EXT#1", "interact", G.ep(e6, entry["u"], -0.8, 1.0), Vector3(1.8, 2.0, 1.8), "Climb back through the window you came in by")
		t.condition = func(): return entry_open
		var from_arcade: bool = TransitionService.pending_arrival == "from_L025"
		entry_mus = _emit("chiptune" if from_arcade else "room_tone", G.ep(e6, entry["u"], 0.3, 2.2),
			{"bpm": 132.0, "scale": [0, 3, 5, 7, 10, 12], "root": 220.0} if from_arcade else {"cutoff": 500.0}, -22.0, 12.0)
	_place_vacant()
	_faces()
	# the table (far corner), the clock (in the circle), notes
	table = G.table(self)
	var corner := G.miter(es[2]["a"], es[G.AX]["n"], es[2]["n"], 3.4)
	table.position = corner
	table.rotation.y = atan2(corner.x, corner.z)
	clock_node = G.clock(self, Vector3(0.35, 0.08, -0.4))
	_touchable(clock_node, Vector3(0, 0.1, 0), Vector3(0.3, 0.3, 0.3), "Pick up the alarm clock", "clock")
	_touchable(table, Vector3(-0.38, 0.95, 0.05), Vector3(0.45, 0.4, 0.45), "Touch the gramophone", "gramo")
	_touchable(table, Vector3(0.4, 0.82, -0.12), Vector3(0.3, 0.12, 0.32), "Open the novel on the table", "book")
	_touchable(self, Vector3(0, 0.15, 2.45), Vector3(0.6, 0.3, 0.4), "Pry at the wooden circle", "circle")
	for p in locked:
		add_interactable(p, Vector3(0.9, 2.0, 0.4), "Door", func(_p): Overlay.toast("Locked. From the inside.", 2.0))
	var pk := kit("Notes")
	var cp := G.ep(e6, entry["u"] + 1.2, -2.3, 0.0)
	pk.box(cp + Vector3.UP * 0.006, Vector3(0.18, 0.012, 0.13), "l188_frame", GeoKit.ALL, false)
	pk.box(Vector3(3.6, 0.045, -3.2), Vector3(0.15, 0.05, 0.09), "l188_book", GeoKit.ALL, false)
	pk.commit()
	add_note("l188_advisory", "M.E.G. advisory card", ADVISORY, cp + Vector3.UP * 0.05, Vector3(0.4, 0.12, 0.4))
	add_note("l188_recorder", "Field recorder (Team Owl-Eyes)", LOGS, Vector3(3.6, 0.1, -3.2), Vector3(0.4, 0.15, 0.4))
	gramo = AudioStreamPlayer3D.new()
	gramo.stream = AudioSynth.get_stream("music_box", {"notes": DAISY, "root": 261.63})
	gramo.bus = "SFX"
	gramo.volume_db = -4.0
	gramo.max_distance = 60.0
	gramo.unit_size = 8.0
	gramo.position = Vector3(-0.4, 1.1, 0.0)
	table.add_child(gramo)
	if shifts > 0:
		_rearrange()
	for i in 2:
		figs.append({"m": G.figure(self, 0.72, 1.5), "t": -1.0, "w": {}, "s": 1.0})
	cfig = G.figure(self, 0.8, 1.9)
	face = G.faceling(self)
	face_y = 8.0 if absi(hash([level_seed, "face"])) % 2 == 0 else 16.0
	face_u = 4.0 + float(absi(hash([level_seed, "fu"])) % 14)
	sound.bed("room_tone", {"cutoff": 110.0}, -38.0)
	heart = AudioStreamPlayer.new()
	heart.stream = AudioSynth.get_stream("heartbeat", {})
	heart.bus = "SFX"
	heart.volume_db = -60.0
	add_child(heart)
	heart.play()
	var o: Vector3 = walk["o"]
	var dir: Vector3 = walk["dir"]
	add_shot("vertigo", o + dir * 12.0 + Vector3.UP * 1.62, Vector3(0.6, 0.0, 0.4) + dir * 3.0)
	add_shot("atrium", ap + n * 0.6 + Vector3.UP * 1.57, Vector3(4.0, 10.5, 14.0))
	var e1: Dictionary = es[G.AX]
	add_shot("zwalk", G.ep(e1, 2.0, -0.9, 9.62), G.ep(e1, 14.0, -0.6, 9.2))
	add_shot("zcorr", G.ep(e1, 2.0, 1.8, 1.62), G.ep(e1, 14.0, 1.8, 1.3))
	add_shot("zbridge", o + dir * 2.0 + Vector3.UP * 1.62, o + dir * 30.0 + Vector3.UP * 0.5)
	add_shot("zground", Vector3(9.0, 1.62, 6.0), Vector3(-6.0, 3.0, 18.0))
	add_landmark("Entry window", ap)
	add_landmark("Wooden circle", Vector3.ZERO)


func _emit(recipe: String, p: Vector3, params: Dictionary, db: float, dist: float) -> AudioStreamPlayer3D:
	var a := AudioStreamPlayer3D.new()
	a.stream = AudioSynth.get_stream(recipe, params)
	a.volume_db = db
	a.max_distance = dist
	a.bus = "Ambience"
	a.position = p
	a.autoplay = true
	add_child(a)
	return a


func _touchable(parent: Node3D, pos: Vector3, size: Vector3, prompt: String, what: String) -> void:
	var it := Interactable.new()
	parent.add_child(it)
	it.setup(pos, size, prompt, _touch.bind(what))


# ------------------------------------------------------------------ state

func _load_state() -> void:
	var restoring: bool = TransitionService.pending_restore.get("level", "") == stable_id
	if not restoring:
		SaveService.set_flag(stable_id, "closed", false)
		SaveService.set_flag(stable_id, "shifts", 0)
	var sr := RandomNumberGenerator.new()
	sr.seed = hash([level_seed, "court"])
	spacing = sr.randf_range(5.2, 6.4)
	live = sr.randf_range(0.28, 0.48)
	entry_t = sr.randf_range(120.0, 180.0)
	entry_open = not SaveService.flag(stable_id, "closed", false)
	shifts = int(SaveService.flag(stable_id, "shifts", 0))
	for i in shifts:
		spacing = maxf(4.3, spacing - 0.55)
		live = minf(0.9, live + 0.17)
	rows = 7 if shifts > 0 else 6


func _save_state() -> void:
	SaveService.set_flag(stable_id, "closed", not entry_open)
	SaveService.set_flag(stable_id, "shifts", shifts)


func _make_walls() -> void:
	if wall_root:
		wall_root.free()
	var k := kit("Walls")
	wins = G.walls(k, es, spacing, rows)
	k.commit()
	wall_root = k.root
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "win", shifts])
	var e6: Dictionary = es[G.EN]
	var best := 1e9
	for w in wins:
		w["st"] = "live" if r.randf() < live else "ord"
		w["lift"] = r.randf_range(0.25, 0.85)
		if w["e"] == G.EN and w["sill"] < 2.0 and absf(w["u"] - e6["len"] * 0.5) < best:
			best = absf(w["u"] - e6["len"] * 0.5)
			entry = w
	entry["st"] = "entry" if entry_open else "ord"


func _faces() -> void:
	if face_root:
		face_root.free()
	var k := kit("Windows")
	k.shadows = false
	G.faces(k, es, wins)
	k.commit()
	face_root = k.root


func _build_doors() -> void:
	if door_root:
		door_root.free()
	var k := kit("Doors")
	for i in 2:
		var u: float = G.DOORS[i][0]
		if (i == 0) == door_a:
			G.door(k, es[G.AX], u, 0.0, true)
		else:
			G.ebox(k, es[G.AX], u - 0.6, u + 0.6, 0.0, 0.65, 0.0, 2.3, "l188_concrete")
	k.commit()
	door_root = k.root


## Vacant windows (rumoured exits): one at ground level; after a shift, one
## more beside a walkway. About a third of them are not vacant at all.
func _place_vacant() -> void:
	for v in vacs:
		if is_instance_valid(v["pane"]):
			v["pane"].queue_free()
		if is_instance_valid(v["ex"]):
			v["ex"].queue_free()
	vacs.clear()
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "vac", shifts])
	var pools := [wins.filter(func(w): return w["sill"] < 2.0 and w["e"] != G.EN and w["e"] != G.AX)]
	if shifts > 0:
		pools.append(wins.filter(_high))
	for pool in pools:
		if pool.is_empty():
			continue
		var w: Dictionary = pool[r.randi() % pool.size()]
		w["st"] = "vac"
		var e: Dictionary = es[w["e"]]
		var v := {"w": w, "fake": r.randf() < 0.35, "pane": G.pane(self, e, w["u"], w["sill"], MatLib.get_mat("l188_vacant"))}
		var ex := add_exit("L188>L001_5#2", "interact", G.ep(e, w["u"], -0.8, w["sill"]), Vector3(1.6, 2.0, 1.5), "Climb into the vacant window")
		ex.condition = func(): return not v["fake"] and w["st"] == "vac"
		v["ex"] = ex
		vacs.append(v)


func _high(w: Dictionary) -> bool:
	var e: int = w["e"]
	var u: float = w["u"]
	var s: float = w["sill"]
	if e == G.AX:
		return s == 9.0 or s == 17.0
	if e == 0:
		return s == 9.0 and u > float(walk["L0"]) - 7.2
	if e == 2:
		return s == 9.0 and u < 8.2
	return e == int(walk["far"]) and s == 17.0 and absf(u - float(walk["fu"])) < 2.6


## Log 3: after the sleep the table is in the middle and the windows moved.
func _rearrange() -> void:
	table.position = Vector3(0.0, 0.08, 0.0)
	table.rotation.y = 0.6
	clock_node.position = Vector3(1.5, 0.08, 1.1)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "balloons", shifts])
	var cols := [Color(0.72, 0.2, 0.2), Color(0.86, 0.83, 0.76), Color(0.82, 0.66, 0.2), Color(0.3, 0.45, 0.72)]
	for i in 10:
		var sm := SphereMesh.new()
		sm.radius = 0.17
		sm.height = 0.36
		var a := r.randf() * TAU
		var sy := r.randf_range(0.4, 1.0)
		var m := G.prim(self, sm, MatLib.standard(cols[i % 4], 0.35), Vector3(cos(a), 0, sin(a)) * r.randf_range(3.2, 9.0) + Vector3.UP * (0.04 + 0.18 * sy))
		m.scale = Vector3(1.0, sy, 1.0)


# ---------------------------------------------------------------- systems

func _spike(v: float, c: String) -> void:
	naa = minf(1.0, naa + v)
	cause = c
	flash = 0.2


func _touch(_p: Variant, what: String) -> void:
	match what:
		"clock":
			_spike(0.3, "object")
			sound.play_at("knock", {"hits": 6}, clock_node.global_position, -6.0, "[the alarm clock rattles and rings in your hands]")
		"gramo":
			_spike(0.3, "object")
			_daisy(28.0)
		"book":
			_spike(0.12, "object")
			Overlay.show_note("The Great Gatsby", BOOK)
		_:
			_spike(0.1, "circle")
			sound.play_at("knock", {"hits": 3}, Vector3(0, 0.1, 0), -4.0, "[hollow knocking under the planks]")
			Overlay.toast("The pale planks won't budge. It sounds hollow underneath.", 3.0)


func _daisy(secs: float) -> void:
	if not gramo.playing:
		gramo.play()
		Overlay.subtitle("[the gramophone plays: Daisy, Daisy...]", 3.5)
	gramo_t = secs


func _close_entry() -> void:
	if not entry_open:
		return
	entry_open = false
	if is_instance_valid(entry_pane):
		entry_pane.queue_free()
	if is_instance_valid(entry_mus):
		entry_mus.queue_free()
	lights.remove_group("entry")
	entry["st"] = "ord"
	_faces()
	sound.play_at("pipe_clank", {"f": 180.0}, entry["pos"], -6.0, "[behind you, blinds rattle down; it is just a window now]")
	_save_state()


## Hours pass under the emergency protocol; the courtyard rearranges itself.
func _shift() -> void:
	shifts += 1
	naa = 0.0
	spacing = maxf(4.3, spacing - 0.55)
	live = minf(0.9, live + 0.17)
	rows = 7
	_make_walls()
	_place_vacant()
	_faces()
	_rearrange()
	_daisy(30.0)
	Overlay.subtitle("[hours pass; when you uncover your eyes, the courtyard has changed]", 5.0)
	_save_state()
	checkpoint("protocol")


func on_player_ready() -> void:
	air_top = player.global_position.y
	if SessionState.is_qa():
		qa_routes.append({"edge": "L188>EXT#1", "target": entry.get("pos", Vector3.ZERO), "note": "The bot climbs straight back out through the open entry window (page: leave immediately)."})
	elif SessionState.is_story() and spawn_report.get("used_arrival", "") != "checkpoint_position":
		checkpoint("arrival")
		Overlay.subtitle("[silence; the air is cold and painfully dry]", 5.0)


func level_process(delta: float) -> void:
	if player == null or player.dead:
		return
	var pp := player.global_position
	var eye := player.camera.global_position
	var look := -player.camera.global_transform.basis.z
	var e1: Dictionary = es[G.AX]
	var rel: Vector3 = pp - e1["a"]
	var inside: bool = -rel.dot(e1["n"]) < 0.65
	if entry_open:
		entry_t -= delta * (8.0 if proto_on else 1.0)
		var f := clampf(entry_t / 25.0, 0.0, 1.0)
		var fl := 1.0 if entry_t > 25.0 else (0.3 + 0.7 * f) * (0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.021))
		entry_mat.albedo_color = Color(0.3, 0.3, 0.32).lerp(Color(0.95, 0.5, 0.38), fl)
		if is_instance_valid(entry_mus):
			entry_mus.volume_db = lerpf(-44.0, -22.0, f)
		if entry_t < 25.0 and not entry_warned:
			entry_warned = true
			Overlay.subtitle("[the warm light in the window you came through is failing]", 3.0)
		if entry_t <= 0.0:
			_close_entry()
	_protocol(delta, pp)
	if not proto_on:
		_expose(delta, pp, eye, look)
	_figures(delta, eye, look, inside)
	_corridor_figure(delta, pp, eye, look, inside)
	_faceling(delta, pp)
	_room(delta, pp, eye, look)
	# vertigo above the atrium floor: the view widens and sways when you look down
	var vt := 0.0
	if inside and pp.y > 5.0:
		vt = clampf((-look.y - 0.3) / 0.6, 0.0, 1.0) * clampf((pp.y - 3.0) / 12.0, 0.3, 1.0)
	_vert = lerpf(_vert, vt, clampf(delta * 1.5, 0.0, 1.0))
	player.camera.fov = float(Settings.get_value("fov")) + 12.0 * _vert
	if not Settings.get_value("reduce_motion"):
		player.head.rotation.z = sin(Time.get_ticks_msec() * 0.0012) * 0.035 * _vert
	# screen: cold wash, flashes of nothing, eyes bound during the protocol
	flash = maxf(0.0, flash - delta)
	if naa > 0.45 and rng.randf() < delta * (naa - 0.4) * 0.8:
		flash = rng.randf_range(0.06, 0.2)
	var b := 1.0 if flash > 0.0 else (0.94 if proto_on else 0.0)
	_black = lerpf(_black, b, clampf(delta * (14.0 if flash > 0.0 else 2.5), 0.0, 1.0))
	Overlay.set_screen_effect("blackout", _black)
	Overlay.set_screen_effect("desaturate", clampf(0.15 + naa * 0.75, 0.0, 0.9))
	heart.volume_db = lerpf(heart.volume_db, -60.0 + 50.0 * clampf(maxf((naa - 0.45) * 2.0, _vert * 0.6), 0.0, 1.0), clampf(delta * 2.0, 0.0, 1.0))
	if player.frozen:
		return
	if player.is_on_floor():
		if air_top - pp.y > 6.5:
			player.hurt(1000.0, "You fell into the courtyard.")
		air_top = pp.y
	else:
		air_top = maxf(air_top, pp.y)
	if naa >= 1.0:
		player.hurt(1000.0, DEATH.get(cause, DEATH["cold"]))


func _protocol(delta: float, pp: Vector3) -> void:
	var still := player.crouching and player.is_on_floor() and Vector2(player.velocity.x, player.velocity.z).length() < 0.05
	if not proto_on:
		still_t = still_t + delta if still else 0.0
		if still_t > 3.0:
			proto_on = true
			proto_t = 0.0
			proto_need = rng.randf_range(60.0, 80.0)
			proto_app = 4.0
			Overlay.subtitle("[you bind your eyes and ears, lock your arms behind your neck and keep still]", 4.0)
		return
	if not still:
		proto_on = false
		still_t = 0.0
		_spike(0.22, "protocol")
		Overlay.subtitle("[you moved; you answered them]", 3.0)
		return
	proto_t += delta
	naa = maxf(0.0, naa - 0.05 * delta)
	proto_app -= delta
	if proto_app <= 0.0:
		proto_app = rng.randf_range(6.0, 11.0)
		Overlay.subtitle(SENSE[rng.randi() % SENSE.size()], 3.0)
		if rng.randf() < 0.5:
			sound.play_at("whisper", {}, pp + Vector3(rng.randf_range(-1.5, 1.5), 1.0, rng.randf_range(-1.5, 1.5)), -10.0)
	if proto_t >= proto_need:
		proto_on = false
		still_t = 0.0
		_shift()


## NAA/NVA exposure from windows, railings, the circle, the table and time.
func _expose(delta: float, pp: Vector3, eye: Vector3, look: Vector3) -> void:
	var gain := 0.0
	var gazed := false
	for w in wins:
		var st: String = w["st"]
		if st == "entry":
			continue
		var c: Vector3 = w["pos"]
		var to := c - eye
		if st == "live" and not gazed and to.length() < 22.0 and to.normalized().dot(look) > 0.9976:
			gazed = true
			gain += 0.03
			cause = "window"
		if absf(c.y - pp.y - 1.0) > 2.2:
			continue
		var dh := Vector2(c.x - pp.x, c.z - pp.z).length()
		if dh > 2.6:
			continue
		var f := 1.0 - dh / 2.6
		gain += (0.03 if st == "ord" else (0.07 if st == "vac" else (0.42 if dh < 1.25 else 0.13))) * f
		cause = "window"
		if st == "vac":
			for v in vacs:
				if v["w"] == w and v["fake"] and dh < 1.7:
					w["st"] = "live"
					v["pane"].queue_free()
					_faces()
					_spike(0.35, "window")
					Overlay.subtitle("[the empty window is not empty]", 3.0)
	_rail_cap = maxf(0.0, _rail_cap - delta)
	for rl in rails:
		var a: Vector3 = rl[0]
		var b: Vector3 = rl[1]
		if absf(pp.y - a.y) > 0.6:
			continue
		var p2 := Vector2(pp.x, pp.z)
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x, b.z) - a2
		var t := clampf((p2 - a2).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		if p2.distance_to(a2 + ab * t) < 0.5:
			gain += 0.22
			cause = "railing"
			if _rail_cap <= 0.0:
				_rail_cap = 20.0
				Overlay.subtitle("[the glass railing is freezing, and it hums under your hand]", 3.0)
			break
	if pp.y < 0.6 and Vector2(pp.x, pp.z).length() < 2.65:
		gain += 0.16
		cause = "circle"
		_knock -= delta * Vector2(player.velocity.x, player.velocity.z).length()
		if _knock <= 0.0:
			_knock = 0.7
			sound.play_at("knock", {"hits": 1}, pp, -10.0, "[the planks knock hollow underfoot]")
	var tp := table.global_position
	if absf(pp.y - tp.y) < 1.0 and Vector2(pp.x - tp.x, pp.z - tp.z).length() < 1.7:
		gain += 0.18
		cause = "table"
	if gain == 0.0:
		if entry_open:
			naa = maxf(0.0, naa - 0.02 * delta)
		else:
			gain = 0.0022
			cause = "cold"
	naa = minf(1.0, naa + gain * delta)


## Shadowy figures flit across open windows at the edge of vision.
func _figures(delta: float, eye: Vector3, look: Vector3, inside: bool) -> void:
	fig_cd -= delta * (1.0 + naa * 2.5)
	for f in figs:
		if f["t"] < 0.0 or f.get("hold", false):
			continue
		f["t"] += delta
		var w: Dictionary = f["w"]
		var m: MeshInstance3D = f["m"]
		var k: float = f["t"] / 1.3
		m.position = G.ep(es[w["e"]], w["u"] + lerpf(-0.75, 0.75, k) * f["s"], 0.27, w["sill"] + 1.1)
		(m.material_override as ShaderMaterial).set_shader_parameter("alpha", sin(clampf(k, 0.0, 1.0) * PI))
		if (m.position - eye).normalized().dot(look) > 0.996 and k > 0.15:
			_spike(0.1, "look")
			Overlay.subtitle("[you looked straight at one of them]", 2.5)
			k = 2.0
		if k >= 1.0:
			f["t"] = -1.0
			m.visible = false
	if fig_cd > 0.0 or proto_on or not inside:
		return
	fig_cd = rng.randf_range(5.0, 12.0)
	for f in figs:
		if f["t"] >= 0.0:
			continue
		for i in 30:
			var w: Dictionary = wins[rng.randi() % wins.size()]
			var to: Vector3 = w["pos"] - eye
			var c := to.normalized().dot(look)
			if w["st"] == "live" and to.length() < 34.0 and c > 0.3 and c < 0.85:
				show_figure(f, w)
				break
		break


func show_figure(f: Dictionary, w: Dictionary) -> void:
	var m: MeshInstance3D = f["m"]
	var n: Vector3 = es[w["e"]]["n"]
	m.basis = Basis(Vector3.UP.cross(n), Vector3.UP, n)
	m.visible = true
	f["w"] = w
	f["t"] = 0.0
	f["s"] = 1.0 if rng.randf() < 0.5 else -1.0


## Silhouettes at corridor corners: gone if looked at or approached.
func _corridor_figure(delta: float, pp: Vector3, eye: Vector3, look: Vector3, inside: bool) -> void:
	var e1: Dictionary = es[G.AX]
	if cfig_t >= 0.0:
		cfig_t += delta
		var to := cfig.global_position + Vector3.UP * 0.95 - eye
		cfig.look_at(Vector3(eye.x, cfig.global_position.y, eye.z), Vector3.UP)
		cfig.rotate_object_local(Vector3.UP, PI)
		var gone := cfig_t > 2.6 or to.length() < 4.0 or inside
		if to.normalized().dot(look) > 0.99:
			_spike(0.08, "look")
			gone = true
		(cfig.material_override as ShaderMaterial).set_shader_parameter("alpha", clampf(cfig_t * 3.0, 0.0, 1.0))
		if gone:
			cfig_t = -1.0
			cfig.visible = false
		return
	cfig_cd -= delta
	if inside or cfig_cd > 0.0 or proto_on:
		return
	cfig_cd = rng.randf_range(10.0, 20.0)
	var fy := 0.0 if pp.y < 6.0 else (8.0 if pp.y < 14.0 else 16.0)
	for u in [1.4, float(e1["len"]) - 1.4, 12.75]:
		var p := G.ep(e1, u, 1.8 if u != 12.75 else 3.9, fy + 0.95)
		var to := p - eye
		var c := to.normalized().dot(look)
		if to.length() > 5.0 and to.length() < 18.0 and c > 0.2 and c < 0.8:
			cfig.position = p
			cfig.visible = true
			cfig_t = 0.0
			return


## The pink-dress faceling keeps to one corridor floor; it runs at you on sight.
func _faceling(delta: float, pp: Vector3) -> void:
	var e1: Dictionary = es[G.AX]
	var lp: Vector3 = pp - e1["a"]
	var pu := lp.dot(e1["d"])
	var pw := -lp.dot(e1["n"])
	var same := absf(pp.y - face_y) < 1.3 and pw > 0.6 and pw < 3.1 and pu > 0.6 and pu < float(e1["len"]) - 0.6
	var speed := 0.0
	if same and absf(pu - face_u) < 15.0:
		face_dir = signf(pu - face_u) if absf(pu - face_u) > 0.05 else face_dir
		speed = 2.7
		face_w = move_toward(face_w, clampf(pw, 0.9, 2.7), delta * 1.5)
		if not face_alert:
			face_alert = true
			Overlay.subtitle("[quick footsteps in the hall]", 2.5)
	else:
		face_alert = false
		if face_wait > 0.0:
			face_wait -= delta
		else:
			speed = 1.0
			if (face_u > 19.6 and face_dir > 0.0) or (face_u < 2.4 and face_dir < 0.0):
				face_dir = -face_dir
				face_wait = 2.0
	face_u = clampf(face_u + face_dir * speed * delta, 1.4, float(e1["len"]) - 1.4)
	var d: Vector3 = e1["d"]
	face.position = G.ep(e1, face_u, face_w, face_y) + Vector3.UP * absf(sin(face_u * 3.0)) * 0.03 * minf(speed, 1.0)
	face.rotation.y = atan2(d.x * face_dir, d.z * face_dir)
	if speed > 0.0:
		face_step -= delta * speed
		if face_step <= 0.0:
			face_step = 0.75
			sound.play_at("footstep", {"surface": "tile", "variant": 1}, face.position, -6.0)
	if same and not player.frozen and Vector2(pu - face_u, pw - face_w).length() < 0.9:
		player.hurt(1000.0, "A pink-dressed faceling caught you in the halls.")


## Clock ticks, the gramophone, whispers, the wandering mahogany door.
func _room(delta: float, pp: Vector3, eye: Vector3, look: Vector3) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		if pp.distance_to(clock_node.global_position) < 16.0:
			sound.play_at("drip", {"freq": 3200.0}, clock_node.global_position + Vector3.UP * 0.1, -20.0)
	if gramo.playing:
		gramo_t -= delta
		if gramo_t <= 0.0:
			gramo.stop()
			Overlay.subtitle("[the music stops abruptly]", 2.5)
	elif naa > 0.5 and rng.randf() < delta * 0.02:
		_daisy(20.0)
	_wt -= delta
	if naa > 0.25 and _wt <= 0.0 and not proto_on:
		_wt = rng.randf_range(4.0, 12.0) * (1.4 - naa)
		sound.play_at("whisper", {}, pp + Vector3(rng.randf_range(-4, 4), 1.4, rng.randf_range(-4, 4)), -14.0, "[whispering, from nowhere in particular]")
	_st -= delta
	if naa > 0.55 and _st <= 0.0 and not proto_on:
		_st = rng.randf_range(7.0, 14.0)
		Overlay.subtitle(SENSE[rng.randi() % SENSE.size()], 3.0)
	door_t -= delta
	if door_t > 0.0:
		return
	door_t = rng.randf_range(45.0, 90.0)
	var a := G.ep(es[G.AX], 6.025, -0.5, 1.2)
	var b := G.ep(es[G.AX], 16.025, -0.5, 1.2)
	if (a - eye).normalized().dot(look) > 0.2 or (b - eye).normalized().dot(look) > 0.2 or pp.distance_to(a) < 7.0 or pp.distance_to(b) < 7.0:
		return
	door_a = not door_a
	_build_doors()


## Captures: add a close look at an open window with a silhouette held in it.
func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	for w in wins:
		if w["st"] == "live" and w["sill"] < 2.0 and w["e"] != G.EN and w["e"] != G.AX:
			var e: Dictionary = es[w["e"]]
			var f: Dictionary = figs[0]
			plan.append({"name": "zwin", "pos": G.ep(e, w["u"] - 1.4, -3.4, 1.62), "target": G.ep(e, w["u"], 0.0, 2.0),
				"prepare": func():
					show_figure(f, w)
					f["t"] = 0.5
					f["hold"] = true
					var m: MeshInstance3D = f["m"]
					m.position = G.ep(e, w["u"] - 0.15, 0.27, float(w["sill"]) + 1.1)
					(m.material_override as ShaderMaterial).set_shader_parameter("alpha", 1.0)})
			break
	return plan
