extends LevelBase
## Level 1.1 — "Corrupted Corridor" (Backrooms Wiki rev 58, accessed 2026-11-04;
## cite: kvn7, CC BY-SA 3.0). Dossier: docs/canon/levels/L001_1.md.
##
## DESIGN PLAN
## Space: one straight, narrow corridor south from Level 1 (white-painted cinder
##   block, blue tile, exposed pipes and ducts through cracks), streamed along -Z in
##   24 m chunks. It degrades with depth through four sectors (compressed: the page
##   gives miles; ADAPTATION):
##   S1 0-192 m   12 ft wide, ceiling 7-12 ft in steps, fluorescent hum, many supply
##                crates, Outpost 1 (basement-like side room three steps down) and
##                Outpost 2 (widened trading hall, dorm/storage and kitchen/common
##                rooms in white tile, lights on a 16 h / 8 h timer).
##   S2 192-432   glitched: floor tilts into hills and drops, colours shift, whole
##                stretches repeat, pipes block parts of the hall, unreadable markings,
##                glitching walls you can noclip through to Level 1, Outpost 3 (shelf +
##                cot whose supplies vanish), Jakob's Hut in a large recess.
##   S3 432-600   dark: 20 ft ceiling, width 6-20 ft, no working light and flashlights
##                change nothing, patches of bright light with no source, antiseptic
##                smell, Smilers watching, Outpost 4 (a 4 ft crate mid-hall), M.E.G.
##                warning sign and tape at the end.
##   S4 600-696   black and white, the hall heaves, much of the floor has no collision
##                and drops into an endless void; glitched entities hang overhead.
##   Beyond: nothing; a beacon of light far off (Sector 5 is unconfirmed: never reached).
## Signature mechanic: depth-driven sector state (geometry, light, colour, sound and
##   rules all follow how far you are from the entrance) plus crates that thin out.
## Exits: walk back out through the entrance (L001_1>L001#1); noclip through glitching
##   walls in S2-S3 (L001_1>L001#2); fall through S4 into the void (L001_1>EXT#3,
##   destination unbuilt). Two walkable heights: Outpost 1 is three risers down;
##   Sector 2's floor climbs and drops by metres.

const Geo := preload("res://levels/L001_1/L001_1_geo.gd")
const Feat := preload("res://levels/L001_1/L001_1_feat.gd")
const Look := preload("res://levels/L001_1/L001_1_look.gd")
const SPAWN := Vector3(0.0, 0.05, -3.0)
const HUE_COL := [Color(0.92, 0.95, 1.0), Color(1.0, 0.62, 0.82), Color(0.66, 1.0, 0.55), Color(0.72, 0.6, 1.0), Color(1.0, 0.72, 0.38)]

var geo: Geo
var feat: Feat
var world: ChunkWorld
var sector := 1
var depth := 0.0
var crates_opened: Dictionary = {}
var shelf_items: Array = []
var shelf_center := Vector3.ZERO
var o2_tubes: Array = []          # MeshInstance3D of Outpost 2 tubes
var o2_on := true
var o2_hour := 9.0
var smilers: Array = []           # {node, seen}
var floaters: Array = []          # {node, base, ph}
var wobblers: Array = []          # {node, ph}
var beacon: Node3D
var hum: AudioStreamPlayer
var drone: AudioStreamPlayer
var _sec_seen: Dictionary = {}
var _ent_t := 30.0
var _shelf_t := 0.0
var _fl_energy := -1.0
var _t := 0.0
var _crate_plan: Dictionary = {}  # chunk -> crate count (QA density check)


func build() -> void:
	rules["reverb_room"] = 0.6
	rules["reverb_wet"] = 0.26
	rules["view_distance"] = 160.0
	indoor_env(Color(0.85, 0.9, 1.0), 0.12, Color(0.18, 0.2, 0.24), 0.03)
	environment.background_color = Color(0.0, 0.0, 0.0)
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.3
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0
	environment.adjustment_contrast = 1.06
	Look.materials(HUE_COL)
	geo = Geo.new(self)
	geo.profile(rng)
	rules["kill_y"] = geo.min_y - 90.0
	feat = Feat.new(self, geo)
	lights.setup(14, 1)
	lights.max_distance = 30.0
	world = ChunkWorld.new()
	world.name = "Corridor"
	world.chunk_size = Geo.S
	world.radius = 3
	world.unload_radius = 4
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L001", SPAWN, 0.0)
	world.build_around(SPAWN, 3)
	add_exit("L001_1>L001#1", "walk_in", Vector3(0.0, 1.2, 0.95), Vector3(2.2, 2.4, 1.0), "")
	beacon = Look.beacon_node(Vector3(0, geo.Y[geo.Y.size() - 1] + 2.0, -Geo.N_CH * Geo.S - 260.0))
	add_child(beacon)
	hum = sound.bed("fluorescent_hum", {"base": 120.0, "rasp": 0.35}, -21.0)
	sound.bed("room_tone", {"cutoff": 240.0, "rumble": 0.4}, -27.0)
	drone = sound.bed("pad", {"root": 41.0, "chord": [0, 1, 6], "bright": 0.1}, -80.0)
	add_landmark("Entrance from Level 1 (south of M.E.G. Base Alpha)", Vector3(0, 0, 0))
	add_landmark("Outpost 1", Vector3(-6, -0.54, -33))
	add_landmark("Outpost 2 trading hall", Vector3(0, 0, -180))
	add_landmark("Outpost 3 shelf", Vector3(1.6, geo.Y[12 * 4 + 2], -12 * 24 - 15))
	add_landmark("Jakob's Hut", Vector3(5, geo.Y[16 * 4 + 1], -393))
	add_landmark("Outpost 4 crate", Vector3(0, geo.Y[21 * 4 + 2], -21 * 24 - 15))
	add_landmark("M.E.G. cordon before Sector 4", Vector3(0, geo.Y[100], -599))
	_shots()


func _mats(n: int) -> Dictionary:
	var sec := Geo.sector(n)
	if sec == 4:
		return {"wall": "l11_bw_block", "floor": "l11_bw_floor", "ceil": "l11_bw_ceil", "nofloor": true}
	if n == 8:
		return {"wall": "l11_wtile", "floor": "l11_wtile_floor", "ceil": "l11_wtile"}
	var h: int = geo.HUE[n]
	if h > 0:
		return {"wall": "l11_block_h%d" % h, "floor": "l11_floor_h%d" % h, "ceil": "l11_ceil_h%d" % h}
	return {"wall": "l11_block", "floor": "l11_floor", "ceil": "l11_ceil"}


# ------------------------------------------------------------------ chunks

func _on_unload(k: Vector2i) -> void:
	lights.remove_group("k%d" % -k.y)
	smilers = smilers.filter(func(s): return is_instance_valid(s["node"]))
	floaters = floaters.filter(func(s): return is_instance_valid(s["node"]))
	wobblers = wobblers.filter(func(s): return is_instance_valid(s["node"]))
	if -k.y == 8:
		o2_tubes.clear()
	if -k.y == 13:
		shelf_items.clear()


func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var n := -cz
	var meta := {"n": n}
	if cx != 0 or n < 0:
		return meta
	var k := GeoKit.new(node, "K")
	if n == 0:
		feat.entrance(k, node)
		k.commit()
		return meta
	if n >= Geo.N_CH:
		_void_exit(node, n)
		return meta
	var sec := Geo.sector(n)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, geo.DSEED[n], "l11"])
	var g0 := (n - 1) * Geo.SPC
	var mats := _mats(n)
	var grp := "k%d" % n
	# openings in the side walls: outposts, the hut recess, cracks, glitch walls
	var skip: Dictionary = {}
	var cracks: Array = []
	var glitch := -1
	var glitch_side := 1.0
	if n == 2:
		skip["1_-1"] = [{"at": 3.0, "w": 2.2, "h": 2.3}]
	elif n == 8:
		skip["1_-1"] = [{"at": 3.0, "w": 1.6, "h": 2.2}]
		skip["1_1"] = [{"at": 3.0, "w": 1.6, "h": 2.2}]
	elif n == 17:
		skip["1_1"] = [{"at": 3.0, "w": 5.0, "h": float(geo.HC[g0 + 1]) - 0.1}]
	if sec in [2, 3] and not n in [13, 17] and r.randf() < 0.7:
		glitch = r.randi_range(0, 3)
		glitch_side = -1.0 if r.randf() < 0.5 else 1.0
	if sec <= 2 and n != 8:
		for kl in Geo.SPC:
			for side in [-1.0, 1.0]:
				var key := "%d_%d" % [kl, int(side)]
				if skip.has(key) or (kl == glitch and side == glitch_side) or r.randf() > 0.22:
					continue
				var z := geo.seg_z0(g0 + kl) - r.randf_range(1.6, 4.4)
				var hw: float = geo.W[g0 + kl] * 0.5
				var lo := minf(geo.Y[g0 + kl], geo.Y[g0 + kl + 1]) - 0.4
				var op: Dictionary = Geo.crack(k, side, hw, z, lerpf(geo.Y[g0 + kl], geo.Y[g0 + kl + 1], 0.5) - (0.0), r)
				op["at"] = geo.seg_z0(g0 + kl) - z
				skip[key] = [op]
				cracks.append(z)
	var shell_kit := k
	if sec == 4:
		var wob := Node3D.new()
		wob.name = "Heave"
		node.add_child(wob)
		shell_kit = GeoKit.new(wob, "K")
		wobblers.append({"node": wob, "ph": r.randf() * TAU})
	var fixtures: Array = geo.shell(shell_kit, n, mats, r, skip)
	# lights by sector
	for i in fixtures.size():
		var fp: Vector3 = fixtures[i]
		var gi := g0 + i
		match sec:
			1:
				if n == 8:
					continue
				var dead := r.randf() < 0.1
				var flick := not dead and r.randf() < 0.12
				Geo.fixture(k, fp, "l11_tube_dead" if dead else ("l11_tube_flick" if flick else "l11_tube"), r.randf() * 9.0)
				if not dead:
					lights.add_anchor(fp + Vector3(0, -0.35, 0), Color(0.9, 0.95, 1.0), 1.25, 7.5, 0.6 if flick else 0.0, grp)
			2:
				var h: int = geo.HUE[n]
				var dead2 := r.randf() < 0.2
				Geo.fixture(k, fp, "l11_tube_dead" if dead2 else ("l11_tube_h%d" % h if h > 0 else "l11_tube_flick"), r.randf() * 9.0)
				if not dead2:
					lights.add_anchor(fp + Vector3(0, -0.35, 0), HUE_COL[h], 1.1, 7.0, 0.3, grp)
			3:
				Geo.fixture(k, fp, "l11_tube_dead", 100.0)
			4:
				Geo.fixture(shell_kit, fp, "l11_tube_bw", r.randf() * 9.0)
				lights.add_anchor(fp + Vector3(0, -0.4, 0), Color(1, 1, 1), 1.4, 8.0, 0.5, grp)
		if sec <= 2 and r.randf() < 0.35:
			# exposed duct or pipe run on the ceiling
			var y := float(fp.y) - 0.25
			var x := (r.randf_range(0.6, 1.2)) * (-1.0 if r.randf() < 0.5 else 1.0)
			if absf(geo.Y[gi + 1] - geo.Y[gi]) < 0.01:
				k.box(Vector3(x, y, fp.z), Vector3(0.55, 0.3, Geo.SEG), "l11_duct", GeoKit.ALL, false)
			else:
				k.box(Vector3(-x * 1.3, fp.y - 0.12, fp.z), Vector3(0.1, 0.1, 0.1), "l11_pipe", GeoKit.ALL, false)
	match sec:
		1, 2:
			_crates(k, node, n, r)
		3:
			_dark_sector(k, node, n, r, grp)
	if sec == 2:
		_markings(k, n, r)
		if r.randf() < 0.35 and not n in [13, 17]:
			_pipe_block(k, n, r)
		if r.randf() < 0.25:
			_smiler(node, Vector3(r.randf_range(-1.0, 1.0), geo.floor_at(-geo.seg_z0(g0) + 18.0) + 1.6, geo.seg_z0(g0) - 18.0))
	if glitch >= 0:
		_glitch_wall(k, node, n, glitch, glitch_side)
	if sec == 4:
		_sector4(k, node, n, r)
	# set pieces
	match n:
		2:
			var o1: Dictionary = feat.outpost1(k, node, geo.seg_z0(g0 + 1), r)
			add_note("L001_1_o1_survey", "M.E.G. survey sheet (Outpost 1)",
				"[i]A laminated sheet on the outpost table (paraphrased from the M.E.G. survey).[/i]\n\nLEVEL 1.1 is one straight corridor south of Base Alpha. Nobody is separated on entry; travel in groups.\n\nSECTOR 1: stable, about 12 ft wide, ceiling 7-12 ft, crates plentiful. No dangerous entities documented.\nSECTOR 2: glitched. Slanted floors, colour shifts, repeating stretches, blocked halls. Smilers, Hounds and Skin-Stealers occasionally.\nSECTOR 3: dark; lights and flashlights do not help. Smilers common.\nSECTOR 4: cordoned off. Do not enter.\n\nCrates thin out the deeper you go. Plan your supplies.",
				o1["note_at"])
			make_interactable(o1["rest"] + Vector3(0, 0.8, 0), Vector3(2.0, 1.6, 2.0), "Rest in Outpost 1", func(): _rest("Outpost 1"), node)
		8:
			var o2: Dictionary = feat.outpost2(k, node, geo.seg_z0(g0) - 12.0, r)
			for fp in o2["tubes"]:
				lights.add_anchor(fp + Vector3(0, -0.4, 0), Color(0.95, 0.97, 1.0), 1.2, 7.5, 0.0, grp)
			for fz in [-3.0, -9.0, -15.0, -21.0]:
				var hp := Vector3(0, 3.0, geo.seg_z0(g0) + fz)
				Geo.fixture(k, hp, "l11_tube_o2", r.randf() * 9.0)
				lights.add_anchor(hp + Vector3(0, -0.4, 0), Color(0.95, 0.97, 1.0), 1.25, 7.5, 0.0, grp)
			make_interactable(o2["timer_at"], Vector3(0.6, 0.6, 0.6), "Check the light timer", _timer_info, node)
			make_interactable(Vector3(-7.0, 1.0, geo.seg_z0(g0) - 9.0), Vector3(2.0, 2.0, 2.0), "Rest in the Outpost 2 dormitory", func(): _rest("Outpost 2"), node)
			for mi in node.find_children("Mesh_l11_tube_o2", "MeshInstance3D", true, false):
				o2_tubes.append(mi)
			_apply_o2()
		13:
			var z3 := geo.seg_z0(g0 + 2) - 3.0
			shelf_center = Vector3(1.6, geo.Y[g0 + 2] + 1.3, z3)
			shelf_items = feat.outpost3(k, node, z3, geo.Y[g0 + 2], r)
			make_interactable(shelf_center, Vector3(0.8, 1.4, 2.0), "Take supplies from the Outpost 3 shelf", _take_shelf, node)
		17:
			var hd: Dictionary = feat.hut(k, node, geo.seg_z0(g0 + 1) - 3.0, geo.Y[g0 + 1], r)
			lights.add_anchor(hd["lantern"] + Vector3(0, 0.3, 0), Color(1.0, 0.72, 0.4), 1.0, 6.0, 0.15, grp)
			var lk := GeoKit.new(node, "Lantern")
			lk.box(hd["lantern"], Vector3(0.16, 0.24, 0.16), "l11_lantern", GeoKit.ALL, false)
			lk.commit()
			add_note("L001_1_gang_log", "Notebook page at Jakob's Hut",
				"[i]A page in a Tunnel Gang member's hand (paraphrased).[/i]\n\nNo update for days - it is too dark in Sector 3 to write. We finally found a lit patch and slept in the corridor; nothing came. Blade says Outpost 4 is a few hours on. Later: found it. Cam walked straight into the box in the dark and hurt his knee, but he can walk. We sleep by the box tonight.\n\n[i]The hut belongs to the Tunnel Gang now. They trade with anyone who shows no sign of M.E.G. affiliation.[/i]",
				hd["note_at"])
		22:
			var c4: Vector3 = feat.outpost4(k, node, geo.seg_z0(g0 + 2) - 3.0, geo.Y[g0 + 2])
			make_interactable(c4 + Vector3(0, 0, 0.8), Vector3(1.6, 1.4, 0.6), "Open the Outpost 4 crate", _open_o4, node)
			for sx in [-1.0, 1.0]:
				_smiler(node, c4 + Vector3(sx * 1.6, 1.0, -7.0 - absf(sx) * 2.0))
		25:
			feat.cordon(k, node, geo.seg_z0(g0 + 3) - 5.5, geo.Y[g0 + 4], geo.W[g0 + 3])
	k.commit()
	if sec == 4 and shell_kit != k:
		shell_kit.commit()
	return meta


## Supply crates, frequent near the entrance and rare by Sector 3.
func _crates(k: GeoKit, node: Node3D, n: int, r: RandomNumberGenerator) -> void:
	var g0 := (n - 1) * Geo.SPC
	var d0 := (n - 1) * Geo.S
	var expect := lerpf(5.0, 0.6, clampf(d0 / 432.0, 0.0, 1.0))
	var count := int(expect + r.randf())
	_crate_plan[n] = count
	for i in count:
		var dz := r.randf_range(1.0, Geo.S - 1.0)
		var gi := g0 + int(dz / Geo.SEG)
		var hw: float = geo.W[gi] * 0.5
		if absf(geo.Y[gi + 1] - geo.Y[gi]) > 0.01:
			continue
		var side := -1.0 if r.randf() < 0.5 else 1.0
		var y: float = geo.Y[gi]
		var z := -d0 - dz
		var x := side * (hw - 0.5)
		if (n == 2 and side < 0 and absf(z + 33.0) < 3.0) or n == 8:
			continue
		var kind := r.randi() % 4
		var key := "%d_%d" % [n, i]
		match kind:
			0:
				Props.place(self, node, "ph/old_military_crate", Vector3(side * (hw - 0.45), y, z), 90.0 + r.randf_range(-6, 6), 0.0, true)
			1:
				Props.place(self, node, "ph/wooden_crate_01", Vector3(x, y, z), 90.0 + r.randf_range(-15, 15), 0.0, true)
				k.box(Vector3(x, y + 0.5, z + 0.7), Vector3(0.7, 0.6, 0.6), "l11_crate")
			_:
				var sz := Vector3(r.randf_range(0.7, 0.95), r.randf_range(0.55, 0.8), r.randf_range(0.6, 0.9))
				k.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.15, 0.15)), Vector3(x, y + sz.y * 0.5, z)), sz, "l11_crate")
				if r.randf() < 0.4:
					k.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(x, y + sz.y + 0.25, z)), Vector3(0.6, 0.5, 0.55), "l11_crate")
		make_interactable(Vector3(x, y + 0.6, z), Vector3(1.0, 1.0, 1.2), "Open the crate", _open_crate.bind(key, n), node)
	# traces of the many explorers in Sector 1
	if Geo.sector(n) == 1 and r.randf() < 0.5:
		var z2 := -d0 - r.randf_range(3.0, 21.0)
		Props.place(self, node, "ph/vintage_suitcase", Vector3(r.randf_range(-1.2, 1.2), geo.floor_at(-z2), z2), r.randf() * 360.0)


func _dark_sector(k: GeoKit, node: Node3D, n: int, r: RandomNumberGenerator, grp: String) -> void:
	var g0 := (n - 1) * Geo.SPC
	# a patch of bright light with no source
	var pd := (n - 1) * Geo.S + r.randf_range(4.0, 20.0)
	lights.add_anchor(Vector3(r.randf_range(-0.8, 0.8), geo.floor_at(pd) + 2.4, -pd), Color(1.0, 0.98, 0.94), 2.2, 6.5, 0.0, grp)
	if r.randf() < 0.3:
		_crates(k, node, n, r)
	for i in r.randi_range(1, 2):
		var d := (n - 1) * Geo.S + r.randf_range(2.0, 22.0)
		_smiler(node, Vector3(r.randf_range(-1.5, 1.5), geo.floor_at(d) + r.randf_range(0.6, 2.8), -d))


## Unreadable markings on walls, floor and ceiling (Sector 2).
func _markings(k: GeoKit, n: int, r: RandomNumberGenerator) -> void:
	for i in r.randi_range(3, 6):
		var d := (n - 1) * Geo.S + r.randf_range(1.0, 23.0)
		var gi := int(d / Geo.SEG)
		var hw: float = geo.W[gi] * 0.5
		var y := geo.floor_at(d)
		var where := r.randi() % 4
		var c: Vector3
		var bas: Basis
		match where:
			0, 1:
				var sd := -1.0 if where == 0 else 1.0
				c = Vector3(sd * (hw - 0.004), y + r.randf_range(0.8, 1.9), -d)
				bas = Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(1, 0, 0))
			2:
				c = Vector3(r.randf_range(-hw + 0.5, hw - 0.5), y + 0.004, -d)
				bas = Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0))
			_:
				c = Vector3(r.randf_range(-hw + 0.5, hw - 0.5), y + float(geo.HC[gi]) - 0.004, -d)
				bas = Basis(Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(0, -1, 0))
		for s in r.randi_range(4, 9):
			var o := Vector3(r.randf_range(-0.45, 0.45), r.randf_range(-0.2, 0.2), 0)
			var sb := bas * Basis(Vector3(0, 0, 1), r.randf_range(-1.2, 1.2))
			k.box_xf(Transform3D(sb, c + bas * o), Vector3(r.randf_range(0.08, 0.3), 0.025, 0.004), "l11_glyph", GeoKit.ALL, false)


## Pipes and ducts blocking part of the hall (Sector 2); a gap stays open.
func _pipe_block(k: GeoKit, n: int, r: RandomNumberGenerator) -> void:
	var g0 := (n - 1) * Geo.SPC
	for kl in Geo.SPC:
		var gi := g0 + kl
		if absf(geo.Y[gi + 1] - geo.Y[gi]) > 0.01:
			continue
		var z := geo.seg_z0(gi) - 3.0
		var y: float = geo.Y[gi]
		var hc: float = geo.HC[gi]
		var hw: float = geo.W[gi] * 0.5
		var side := -1.0 if r.randf() < 0.5 else 1.0
		for p in 4:
			var x := side * (hw - 0.2 - p * 0.42)
			k.cylinder(Vector3(x, y + hc * 0.5, z + r.randf_range(-0.2, 0.2)), r.randf_range(0.08, 0.17), hc, "l11_rust" if p % 2 else "l11_pipe", 10)
		k.box(Vector3(side * (hw - 1.0), y + 1.05, z), Vector3(2.0, 0.22, 0.22), "l11_pipe")
		return


## A stretch of wall that glitches (Sectors 2-3): pushing into it noclips you into
## another part of Level 1.
func _glitch_wall(k: GeoKit, node: Node3D, n: int, kl: int, side: float) -> void:
	var gi := (n - 1) * Geo.SPC + kl
	var hw: float = geo.W[gi] * 0.5
	var z := geo.seg_z0(gi) - 3.0
	var y := geo.floor_at(-z)
	k.box(Vector3(side * (hw - 0.01), y + 1.15, z), Vector3(0.02, 2.2, 1.6), "l11_glitch", GeoKit.ALL, false)
	var t := make_exit("L001_1>L001#2", "noclip", Vector3(side * (hw - 0.3), y + 1.1, z), Vector3(0.9, 2.2, 1.6), "Push into the glitching wall", node)
	if t:
		t.hold_seconds = 2.2
	sound.emitter("static", Vector3(side * hw, y + 1.2, z), {}, -18.0, 8.0).reparent(node)


## Sector 4: floor tiles, many of them without collision, over a void; hovering
## glitched entities; a fall exit far below.
func _sector4(k: GeoKit, node: Node3D, n: int, r: RandomNumberGenerator) -> void:
	var g0 := (n - 1) * Geo.SPC
	var ghost := GeoKit.new(node, "NoCollision")
	for kl in Geo.SPC:
		var gi := g0 + kl
		var y: float = geo.Y[gi]
		var hw: float = geo.W[gi] * 0.5
		var z0 := geo.seg_z0(gi)
		for tz in 3:
			for tx in 2:
				var mn := Vector3(-hw + tx * hw, y - 0.3, z0 - (tz + 1) * 2.0)
				var mx := Vector3(-hw + (tx + 1) * hw, y, z0 - tz * 2.0)
				var solid := (n == 26 and kl == 0) or r.randf() < 0.5
				if solid:
					k.box_mm(mn, mx, "l11_bw_floor")
				else:
					ghost.box_mm(mn, mx, "l11_bw_floor", GeoKit.PY)
	ghost.commit()
	for c in ghost.body.get_children():
		c.free()
	for i in r.randi_range(2, 4):
		var d := (n - 1) * Geo.S + r.randf_range(2.0, 22.0)
		_floater(node, Vector3(r.randf_range(-1.2, 1.2), geo.floor_at(d) + r.randf_range(2.4, 3.9), -d), r)
	_void_exit(node, n)


func _void_exit(node: Node3D, n: int) -> void:
	var zc := -(n - 0.5) * Geo.S
	var t := make_exit("L001_1>EXT#3", "fall", Vector3(0, geo.min_y - 30.0, zc), Vector3(60.0, 50.0, Geo.S), "", node)
	if t:
		t.fall_y = geo.min_y - 18.0


# ------------------------------------------------------------------ presences

func _smiler(node: Node3D, pos: Vector3) -> void:
	smilers.append({"node": Look.smiler(node, pos), "seen": false})


func _floater(node: Node3D, pos: Vector3, r: RandomNumberGenerator) -> void:
	floaters.append({"node": Look.floater(node, pos, r), "base": pos, "ph": r.randf() * TAU})


# ------------------------------------------------------------------ interactions

func _open_crate(key: String, n: int) -> void:
	if crates_opened.has(key):
		Overlay.toast("Already opened. Empty.", 2.0)
		return
	crates_opened[key] = true
	var luck := lerpf(0.8, 0.25, clampf(float(n) / 25.0, 0.0, 1.0))
	if rng.randf() < luck:
		SaveService.add_item("almond_water")
		Overlay.toast("Inside: tinned food, a folded jacket and a bottle of Almond Water. You take the water.", 3.5)
	else:
		Overlay.toast("Packing straw and an empty tin. Someone got here first.", 3.0)


func _open_o4() -> void:
	if crates_opened.has("o4"):
		Overlay.toast("The Outpost 4 crate is empty now.", 2.5)
		return
	crates_opened["o4"] = true
	SaveService.add_item("almond_water", 2)
	Overlay.toast("Food, drinks, clothing. You take two bottles of Almond Water and close the lid quietly.", 4.0)
	Overlay.subtitle("[something in the dark shifts its weight]", 3.0)


func _take_shelf() -> void:
	for mi in shelf_items:
		if is_instance_valid(mi) and (mi as Node3D).visible:
			(mi as Node3D).visible = false
			SaveService.add_item("almond_water")
			Overlay.toast("You take supplies from the Outpost 3 shelf.", 2.5)
			return
	Overlay.toast("The shelf is empty. Explorers who planned to restock here turned back.", 3.5)


func _rest(where: String) -> void:
	checkpoint(where.to_lower().replace(" ", "_"))
	if player:
		player.heal(40.0)
	Overlay.toast("You rest a while in %s." % where, 2.5)


func _timer_info() -> void:
	var left := (16.0 - o2_hour) if o2_on else (24.0 - o2_hour)
	Overlay.toast("A relay timer: lights on 16 hours a day, off 8. Lights are %s; they switch in about %d hours." % ["on" if o2_on else "off", int(ceil(left))], 4.0)


func _apply_o2() -> void:
	for mi in o2_tubes:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).material_override = MatLib.get_mat("l11_tube_o2" if o2_on else "l11_tube_dead")
	for a in lights.anchors:
		if a.get("group", "") == "k8":
			if not a.has("e0"):
				a["e0"] = a["energy"]
			a["energy"] = a["e0"] if o2_on else 0.0


# ------------------------------------------------------------------ per frame

func on_player_ready() -> void:
	world.target = player


func level_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var pp := player.global_position
	depth = -pp.z
	var sec := Geo.depth_sector(depth) if depth > 0.0 else 1
	if sec > 4:
		sec = 4
	if sec != sector:
		sector = sec
		_enter_sector(sec)
	_env(delta, pp)
	# Outpost 2 light timer: one game hour every 15 s
	o2_hour = fmod(o2_hour + delta / 15.0, 24.0)
	var want := o2_hour < 16.0
	if want != o2_on:
		o2_on = want
		_apply_o2()
		if absf(depth - 180.0) < 30.0 and not SessionState.is_qa():
			Overlay.subtitle("[a relay clicks: the outpost lights %s]" % ["come on" if o2_on else "go out for the night"], 3.0)
	# Outpost 3: supplies vanish while nobody watches
	if not shelf_items.is_empty():
		_shelf_t += delta
		if _shelf_t > 20.0:
			_shelf_t = 0.0
			var cam := player.camera
			var to := shelf_center - cam.global_position
			var watched := to.length() < 25.0 and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.5
			if not watched and rng.randf() < 0.5:
				for mi in shelf_items:
					if is_instance_valid(mi) and (mi as Node3D).visible:
						(mi as Node3D).visible = false
						break
	if fmod(_t, 3.0) < delta:
		smilers = smilers.filter(func(x): return is_instance_valid(x["node"]))
		floaters = floaters.filter(func(x): return is_instance_valid(x["node"]))
		wobblers = wobblers.filter(func(x): return is_instance_valid(x["node"]))
	# Smilers vanish when approached
	for s in smilers:
		if not is_instance_valid(s["node"]):
			continue
		var sn: Node3D = s["node"]
		if not sn.visible:
			continue
		if sn.global_position.distance_to(pp) < 7.5:
			sn.visible = false
			if not s["seen"] and not SessionState.is_qa():
				s["seen"] = true
				Overlay.subtitle("[a wide grin in the dark - then nothing]", 3.0)
	for f in floaters:
		if is_instance_valid(f["node"]):
			var fnode: Node3D = f["node"]
			fnode.position = f["base"] + Vector3(sin(_t * 0.3 + f["ph"]) * 0.8, sin(_t * 0.7 + f["ph"]) * 0.35, cos(_t * 0.25 + f["ph"]) * 0.6)
			fnode.rotation.y += delta * 0.2
	for w in wobblers:
		if is_instance_valid(w["node"]):
			var wn: Node3D = w["node"]
			wn.position.y = sin(_t * 0.9 + w["ph"]) * 0.18
			wn.rotation.z = sin(_t * 0.6 + w["ph"]) * 0.025
	# flashlights change nothing in Sector 3
	if player.flashlight:
		if _fl_energy < 0.0:
			_fl_energy = player.flashlight.light_energy
		player.flashlight.light_energy = 0.0 if sec == 3 else _fl_energy
	player.head.rotation.z = sin(_t * 0.8) * 0.05 if sec == 4 else lerpf(player.head.rotation.z, 0.0, clampf(delta * 3.0, 0.0, 1.0))
	beacon.visible = sec == 4
	if sec == 4 and not SessionState.is_qa() and fmod(_t, 9.0) < delta:
		Overlay.glitch(0.35)
	# sparse entity sounds in Sectors 2 and 3
	if sec in [2, 3] and not SessionState.is_qa():
		_ent_t -= delta
		if _ent_t <= 0.0:
			_ent_t = rng.randf_range(35.0, 80.0)
			var ahead := pp + Vector3(rng.randf_range(-1, 1), 0.5, -rng.randf_range(18.0, 30.0) * (1.0 if rng.randf() < 0.6 else -1.0))
			match rng.randi() % 3 if sec == 2 else 0:
				0: sound.play_at("scratch", {}, ahead, -10.0, "[claws on tile, somewhere far down the hall]")
				1: sound.play_at("whisper", {}, ahead, -12.0, "[a voice calls from far behind - almost right, not quite]")
				_: sound.play_at("heartbeat", {}, ahead, -14.0, "[heavy breathing, a long way off]")


func _enter_sector(sec: int) -> void:
	if SessionState.is_qa() or _sec_seen.has(sec):
		return
	_sec_seen[sec] = true
	match sec:
		2: Overlay.subtitle("[the hum wavers; ahead, the floor starts to tilt]", 4.0)
		3: Overlay.subtitle("[the light gives out. A faint smell of antiseptic.]", 4.5)
		4: Overlay.subtitle("[colour drains away; the hall heaves under you]", 4.5)


func _env(delta: float, pp: Vector3) -> void:
	var a := clampf(delta * 1.2, 0.0, 1.0)
	var amb := 0.12
	var amb_c := Color(0.85, 0.9, 1.0)
	var fog_c := Color(0.16, 0.18, 0.22)
	var fog_d := 0.03
	var sat := 1.0
	var hum_db := -21.0
	var drone_db := -80.0
	match sector:
		2:
			var n := int(ceil(maxf(depth, 0.01) / Geo.S))
			var tint: Color = HUE_COL[geo.HUE[clampi(n, 0, geo.HUE.size() - 1)]]
			amb = 0.1
			amb_c = tint
			fog_c = tint * 0.16
			fog_d = 0.036
			sat = 1.15
			hum_db = -25.0
		3:
			amb = 0.0
			fog_c = Color(0, 0, 0)
			fog_d = 0.11
			sat = 0.9
			hum_db = -80.0
		4:
			amb = 0.25
			amb_c = Color(1, 1, 1)
			fog_c = Color(0.3, 0.3, 0.3)
			fog_d = 0.022
			sat = 0.0
			hum_db = -80.0
			drone_db = -22.0
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, amb, a)
	environment.ambient_light_color = environment.ambient_light_color.lerp(amb_c, a)
	environment.fog_light_color = environment.fog_light_color.lerp(fog_c, a)
	environment.fog_density = lerpf(environment.fog_density, fog_d, a)
	environment.adjustment_saturation = lerpf(environment.adjustment_saturation, sat, a)
	if hum:
		hum.volume_db = lerpf(hum.volume_db, hum_db, a)
	if drone:
		drone.volume_db = lerpf(drone.volume_db, drone_db, a)


# ------------------------------------------------------------------ QA

func _shots() -> void:
	add_shot("sector1", Vector3(0.6, 1.62, -6.0), Vector3(-0.3, 1.4, -60.0))
	add_shot("outpost1", Vector3(-2.2, 1.4, -31.2), Vector3(-8.5, 0.2, -35.0), {"prepare": func(): _go(-33.0)})
	add_shot("outpost2", Vector3(-1.5, 1.62, -170.5), Vector3(1.2, 1.2, -186.0), {"prepare": func(): _go(-178.0)})
	add_shot("sector2", Vector3(0.5, geo.floor_at(250.0) + 1.62, -250.0), Vector3(0.0, geo.floor_at(275.0) + 1.0, -275.0), {"prepare": func(): _go(-255.0)})
	var best := 9 * Geo.SPC
	for g in range(8 * Geo.SPC + 1, 18 * Geo.SPC):
		if absf(geo.Y[g + 1] - geo.Y[g]) > absf(geo.Y[best + 1] - geo.Y[best]):
			best = g
	var d0 := best * Geo.SEG - 4.0
	add_shot("sector2_slope", Vector3(0.4, geo.floor_at(d0) + 1.62, -d0), Vector3(0.0, geo.floor_at(d0 + 14.0) + 1.2, -d0 - 14.0), {"prepare": func(): _go(-d0 - 4.0)})
	add_shot("hut", Vector3(-0.8, geo.floor_at(389.0) + 1.62, -389.0), Vector3(5.0, geo.floor_at(393.0) + 0.8, -394.0), {"prepare": func(): _go(-392.0)})
	add_shot("sector3", Vector3(0.3, geo.floor_at(509.0) + 1.62, -509.0), Vector3(0.0, geo.floor_at(519.0) + 0.7, -519.0), {"prepare": func(): _go(-515.0, 3)})
	add_shot("sector4", Vector3(0.4, geo.floor_at(605.0) + 1.62, -605.0), Vector3(0.0, geo.floor_at(640.0) + 2.0, -640.0), {"prepare": func(): _go(-615.0, 4)})


## Stream the corridor around a capture point and snap the sector state there.
func _go(z: float, sec: int = 0) -> void:
	world.build_around(Vector3(0, 0, z), 2)
	depth = -z
	sector = sec if sec > 0 else Geo.depth_sector(depth)
	for i in 120:
		_env(0.1, Vector3(0, 0, z))
	beacon.visible = sector == 4
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "entrance exit back to Level 1 present", "ok": exits.size() >= 1})
	var max_dy := 0.0
	for g in range(8 * Geo.SPC, 18 * Geo.SPC):
		max_dy = maxf(max_dy, absf(geo.Y[g + 1] - geo.Y[g]))
	out.append({"what": "Sector 2 floor tilts into hills and drops", "ok": max_dy > 0.8, "detail": max_dy})
	var flat1 := true
	for g in range(0, 8 * Geo.SPC):
		if absf(geo.Y[g + 1] - geo.Y[g]) > 0.001:
			flat1 = false
	out.append({"what": "Sector 1 is level and 12 ft wide", "ok": flat1 and absf(geo.W[2] - 3.66) < 0.01})
	out.append({"what": "Sector 3 ceiling about 20 ft", "ok": absf(geo.HC[20 * Geo.SPC] - 6.1) < 0.01})
	out.append({"what": "repeating stretches share layout", "ok": geo.DSEED[10] == geo.DSEED[9] and geo.W[10 * Geo.SPC + 1] == geo.W[9 * Geo.SPC + 1]})
	# crate density: build the deep chunks' plans and compare
	var r := RandomNumberGenerator.new()
	var tmp := Node3D.new()
	add_child(tmp)
	for n in [3, 4, 14, 15]:
		r.seed = hash([level_seed, geo.DSEED[n], "l11"])
		_crates(GeoKit.new(tmp, "T"), tmp, n, r)
	tmp.queue_free()
	out.append({"what": "crates thin out with depth", "ok": _crate_plan[3] + _crate_plan[4] > _crate_plan[14] + _crate_plan[15], "detail": _crate_plan})
	# deep chunks carry the noclip walls and the void fall
	for zz in [-8.5 * Geo.S, -11.5 * Geo.S, -13.5 * Geo.S, -18.5 * Geo.S, -19.5 * Geo.S, -20.5 * Geo.S, -26.5 * Geo.S]:
		world.build_around(Vector3(0, 0, zz), 0)
	var kinds := {}
	for t in exits:
		if is_instance_valid(t):
			kinds[t.edge_id] = t.kind
	out.append({"what": "Sector 2 glitch walls carry the noclip exit to Level 1", "ok": kinds.get("L001_1>L001#2", "") == "noclip", "detail": kinds})
	out.append({"what": "Sector 4 drops into the void (fall exit)", "ok": kinds.get("L001_1>EXT#3", "") == "fall"})
	# Outpost 2 timer
	o2_hour = 15.99
	level_process(0.5)
	var off := not o2_on
	o2_hour = 23.99
	level_process(0.5)
	out.append({"what": "Outpost 2 lights follow the 16 h / 8 h timer", "ok": off and o2_on})
	return out
