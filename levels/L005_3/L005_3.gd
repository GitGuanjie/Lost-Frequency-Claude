extends LevelBase
## Level 5.3 — "Promethei Bibliotheca" (Backrooms Wikidot rev 40, accessed
## 2026-11-04; cite: Praetor3005, CC BY-SA 3.0). Dossier: docs/canon/levels/L005_3.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: a sub-section of the Terror Hotel (Level 5) found in May 2016 behind
## an old wooden door at the end of a corridor of peeled wallpaper near
## Housekeeping; an elegant library with hundreds of corridors on all sides;
## marble walls with granite features, pillars of tuff, iron bars along the
## side of the corridor that meets a void; Renaissance-style paintings of
## unknown events above the shelves; endless corridors but only seven floors,
## joined by wooden staircases; "Promethei Bibliotheca" at the top of some
## walls; books of every colour and size, few illustrations, pristine but
## dusty, mostly in unknown languages (some English, French, Italian), mainly
## about the Backrooms; after one to two hours it extracts memories (newer,
## "important" ones), with growing headaches, unnoticed by the victim, and
## consigns them to books (a notebook up to a series); it gives the knowledge
## you seek in exchange for memory, refuses those who would harm or dominate
## (headaches, heavy memory loss), talks through emotions, drops books to
## guide, collapses whole bookshelves in anger; the Lost Hall Society used it
## until about the 17th century; documents imply the hotel's staff isolated it;
## no entities seen (testimony); a dead-end corridor may end in a small wooden
## door that leads back to the entrance; the Gentleman's visit (vignette).
## ADAPTATION: the library is a finite streaming window (24 m chunks, all
## seven floors each, 5 m storeys, arrival on floor 4); a 4 m corridor grid
## with walls of shelves facing it and ranges inside; about one block in five
## is the void, fenced with iron bars and climbed by switchback wooden stairs;
## dead ends are seeded (one always near the arrival on floor 4); the loop door
## is a seamless return to the entrance (edge L005_3>L005_3#1); the exit to
## Level 5 is the old door you came in by (L005_3>L005#2, not explicitly
## stated); time is compressed (an hour here is about six minutes); the
## lectern requests, the falling-book guide and the consigned notebook are our
## staging of the page's exchange, guidance and memory-book behaviour.
## Material language: Level 5's walnut, gilt, red-and-gold carpet and
## checkered marble, plus the page's marble, granite, tuff and iron.

const S := preload("res://levels/L005_3/L005_3_stacks.gd")
const CHUNK := preload("res://levels/L005_3/L005_3_chunk.gd")
const MIND := preload("res://levels/L005_3/L005_3_mind.gd")
const ENTRY := Vector3(14.0, 0.0, 3.5)

var builder
var world: ChunkWorld
var mind
var floor_now := S.ENTRY_F
var prop_nodes: Dictionary = {}      # "cx,cz,f" -> Node3D
var _light_key := ""
var _prop_t := 0.0
var shelf: Node3D                    # the bookcase that falls when the Mind is angry
var lectern_pos := Vector3(7.2, 0.0, 1.1)


func build() -> void:
	rules["view_distance"] = 120.0
	rules["reverb_room"] = 0.7
	rules["reverb_wet"] = 0.26
	rules["flashlight"] = "allowed"
	rules["kill_y"] = S.floor_y(1) - 40.0
	indoor_env(Color(0.45, 0.32, 0.21), 0.42, Color(0.05, 0.034, 0.022), 0.03)
	environment.tonemap_exposure = 1.35
	environment.glow_intensity = 0.7
	environment.glow_hdr_threshold = 0.9
	environment.glow_bloom = 0.06
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	environment.adjustment_contrast = 1.05
	S.materials()
	builder = CHUNK.new(self)
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 5
	var near := [Vector2i(1, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(1, -1)]
	var pick := r.randi_range(0, near.size() - 1)
	for i in near.size():
		var cand: Vector2i = near[(pick + i) % near.size()]
		if S.kind_of(cand.x, cand.y, level_seed) == "stacks":
			builder.forced_dead = cand
			break
	lights.setup(14, 1)
	lights.max_distance = 26.0
	world = ChunkWorld.new()
	world.name = "Stacks"
	world.chunk_size = S.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.chunk_built.connect(func(_k, _m): _light_key = "")
	world.chunk_unloaded.connect(_on_unload)
	world.build_around(ENTRY, 2)
	mind = MIND.new(self)
	add_child(mind)
	_entrance()
	_sounds()
	add_arrival("start", ENTRY, 0.0)
	add_arrival("from_L005", ENTRY, 0.0)
	add_arrival("from_L005_3", ENTRY, 0.0)
	add_exit("L005_3>L005#2", "interact", Vector3(14.0, 1.1, 5.25), Vector3(2.0, 2.2, 1.5), "Go back out through the old wooden door")
	add_landmark("Entrance: the old wooden door from the hotel", Vector3(14, 0, 6))
	add_landmark("The void (iron bars, wooden stairs)", Vector3(14, 0, -10))
	add_landmark("Lectern by the void", lectern_pos)
	var fd: Vector2i = builder.forced_dead
	add_landmark("Dead-end corridor with a small wooden door", Vector3(fd.x * S.CS + 13.1, 0, fd.y * S.CS + 16.0))
	_refresh_props(ENTRY)
	_refresh_lights(ENTRY)
	_shots()


func on_player_ready() -> void:
	world.target = player
	mind.on_ready()
	checkpoint("start")


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = builder.build(cx, cz, node)
	for d in meta["doors"]:
		var it := make_interactable(d["pos"], Vector3(1.1, 1.9, 0.5), "Open the small wooden door", _loop_door, node)
		it.name = "LoopDoor"
	return meta


func _on_unload(k: Vector2i) -> void:
	for f in range(1, S.NF + 1):
		var key := "%d,%d,%d" % [k.x, k.y, f]
		if prop_nodes.has(key):
			var n: Node3D = prop_nodes[key]
			prop_nodes.erase(key)
			if is_instance_valid(n):
				n.queue_free()
	_light_key = ""


## Props on the player's floor and the floors either side, near chunks only.
func _refresh_props(p: Vector3) -> void:
	var pc := world.key_at(p)
	var want := {}
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var k := pc + Vector2i(dx, dz)
			var meta: Dictionary = world.meta_of(k)
			if meta.is_empty():
				continue
			for f in [floor_now - 1, floor_now, floor_now + 1]:
				if f < 1 or f > S.NF:
					continue
				if f != floor_now and meta["kind"] != "void" and Vector2i(dx, dz) != Vector2i.ZERO:
					continue
				var key := "%d,%d,%d" % [k.x, k.y, f]
				want[key] = true
				if prop_nodes.has(key):
					continue
				var n := Node3D.new()
				n.name = "Props_" + key.replace(",", "_")
				add_child(n)
				prop_nodes[key] = n
				for pr in meta["floors"][f]["props"]:
					Props.place(self, n, pr["id"], pr["pos"], pr["yaw"], pr["h"], pr["collide"])
	for key in prop_nodes.keys():
		if not want.has(key):
			var n2: Node3D = prop_nodes[key]
			prop_nodes.erase(key)
			if is_instance_valid(n2):
				n2.queue_free()


## Pooled lights only for the player's own storey (they would leak through
## the floors otherwise); the other storeys glow by their candles.
func _refresh_lights(p: Vector3) -> void:
	var pc := world.key_at(p)
	var key := "%d,%d,%d,%d" % [pc.x, pc.y, floor_now, world.chunks.size()]
	if key == _light_key:
		return
	_light_key = key
	lights.clear_anchors()
	for k in world.chunks.keys():
		if absi(k.x - pc.x) > 1 or absi(k.y - pc.y) > 1:
			continue
		var meta: Dictionary = world.meta_of(k)
		if meta.is_empty():
			continue
		for a in meta["floors"][floor_now]["anchors"]:
			lights.add_anchor(a["pos"], a["color"], a["energy"], a["range"], 0.04)
		if meta["kind"] == "void":
			for f in [floor_now - 1, floor_now + 1]:
				if f >= 1 and f <= S.NF:
					for a in meta["floors"][f]["anchors"]:
						if a.get("void", false):
							lights.add_anchor(a["pos"], a["color"], a["energy"] * 0.8, a["range"], 0.04)
	if floor_now == S.ENTRY_F and absi(pc.x) <= 1 and absi(pc.y) <= 1:
		lights.add_anchor(lectern_pos + Vector3(0, 1.6, 0), Color(1.0, 0.8, 0.5), 1.2, 4.5, 0.06)


# ---------------------------------------------------------------- entrance

func _entrance() -> void:
	var k := kit("Entrance")
	# lectern by the iron bars, facing the void, with three request slips
	var lp := lectern_pos
	k.box(lp + Vector3(0, 0.05, 0), Vector3(0.6, 0.1, 0.5), "l53_walnut", GeoKit.ALL, true, "wood")
	k.box(lp + Vector3(0, 0.55, 0), Vector3(0.16, 1.0, 0.16), "l53_walnut", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), 0.35), lp + Vector3(0, 1.1, 0)), Vector3(0.7, 0.05, 0.5), "l53_walnut", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), 0.35), lp + Vector3(0, 1.135, 0.0)), Vector3(0.6, 0.02, 0.4), "l53_paper", GeoKit.ALL, false)
	k.box(lp + Vector3(0.42, 1.06, 0.1), Vector3(0.05, 0.12, 0.05), "l53_candle", GeoKit.ALL, false)
	k.box(lp + Vector3(0.42, 1.16, 0.1), Vector3(0.025, 0.06, 0.025), "l53_flame", GeoKit.ALL, false)
	k.commit()
	var slips := [["Ask the library for books about the Lost Hall Society", "lost_hall"],
		["Ask how this library came to be cut off from the hotel", "isolation"],
		["Ask for knowledge that would make others obey you", "dominate"]]
	for i in 3:
		var sp := lp + Vector3(-0.2 + i * 0.2, 1.16, 0.02)
		var it := add_interactable(sp, Vector3(0.18, 0.12, 0.3), slips[i][0], mind.request.bind(slips[i][1]))
		it.name = "Request_" + slips[i][1]
	# the bookcase pulled out from the wall (it is the one that falls)
	shelf = Props.place(self, self, "ph/wooden_bookshelf_worn", Vector3(10.4, 0.0, 3.62), 180.0, 2.06, true)
	Props.place(self, self, "ph/wooden_ladder", Vector3(11.6, 0.0, 3.5), 200.0, 0.0, false)
	# the Gentleman's flung notebook (vignette), open on the runner
	var gp := Vector3(19.5, 0.04, 2.4)
	Props.place(self, self, "ph/binder_notebook", gp, 64.0, 0.0, false)
	add_note("l53_staff_notebook", "A small notebook, flung across the corridor", "It lies splayed open where it landed, spine cracked, as if someone threw it without looking.\n\nPencil sketches of people in hotel uniforms - a bellhop, a woman at a desk, a man carrying a tray - each with small, careful notes beside it about who they are and what they do.\n\nOn the last page, in a different hand, a single line has been scored through so hard the paper tore.", gp + Vector3(0, 0.06, 0), Vector3(0.5, 0.15, 0.4), false)
	var np := Vector3(12.45, 1.45, 3.97)
	add_note("l53_hermes", "Card pinned beside the door (Hermes team, Ariane Circle)", "PROMETHEAN LIBRARY - read before you go in.\n\n- Seven floors. Wooden stairs between them, out where the iron bars are. The corridors do not end.\n- Do not stay longer than an hour. After one or two it starts taking memories: the newest, or the ones that matter. You will get headaches. You will not notice what is gone unless someone tells you.\n- What it takes ends up in a book somewhere in here. Nobody knows how they are shelved.\n- If you are looking for a book, it knows. It will let you find it - for a price.\n- It will not help anyone who wants knowledge to hurt or rule others. Do not try.\n- No entities seen. Ever.\n\nIf a corridor ends at a small wooden door, it takes you back here.", np, Vector3(0.3, 0.4, 0.1), false)
	var pk := kit("Card")
	pk.box(np, Vector3(0.24, 0.32, 0.01), "l53_paper", GeoKit.ALL, false)
	pk.commit()


# ---------------------------------------------------------------- loop

func _loop_door() -> void:
	if player == null or not is_instance_valid(player):
		return
	var e := TransitionService.get_edge("L005_3>L005_3#1")
	if not e.is_empty():
		SaveService.record_edge(e)
	Overlay.glitch(0.5)
	player.global_position = ENTRY
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	floor_now = S.ENTRY_F
	world.build_around(ENTRY, 1)
	_light_key = ""
	Overlay.subtitle("[the small door opens onto the corridor by the old wooden door - the way you came in]", 4.5)


# ---------------------------------------------------------------- process

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var f := S.floor_of(p.y)
	if f != floor_now:
		floor_now = f
		_light_key = ""
		_prop_t = 0.0
	_prop_t -= delta
	if _prop_t <= 0.0:
		_prop_t = 0.5
		_refresh_props(p)
	_refresh_lights(p)
	mind.step(delta)
	if p.y < S.floor_y(1) - 12.0 and not player.dead:
		if SessionState.is_qa():
			player.global_position = ENTRY
		else:
			player.hurt(1000.0, "Level 5.3: fell into the void below the seventh floor")


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 260.0, "rumble": 0.4}, -24.0)
	sound.bed("pad", {"root": 49.0, "chord": [0, 7, 12], "bright": 0.15}, -34.0)
	sound.oneshot("scratch", {}, 14.0, 34.0, 14.0, "[pages turn somewhere in the stacks]", -20.0)
	sound.oneshot("creak", {"freq": 120.0}, 20.0, 50.0, 12.0, "[old wood settles]", -18.0)


# ---------------------------------------------------------------- QA

func _shots() -> void:
	add_shot("entrance_void", ENTRY + Vector3(0.6, 1.62, -0.4), Vector3(9.0, 0.6, -14.0), {"flashlight": false})
	add_shot("corridor_stacks", Vector3(2.2, 1.62, 22.0), Vector3(2.0, 1.4, 50.0), {"flashlight": false, "prepare": _prep.bind(Vector3(2, 0, 30))})
	add_shot("void_floors", Vector3(20.0, 1.62, 1.5), Vector3(7.0, -6.0, -14.0), {"flashlight": false})
	var pv := _painting_view()
	add_shot("painting_band", pv[0], pv[1], {"flashlight": false})
	add_shot("entrance_door", ENTRY + Vector3(-2.2, 1.55, -3.0), Vector3(14.2, 2.6, 6.0), {"flashlight": false})
	var fd: Vector2i = builder.forced_dead
	var dc := Vector3(fd.x * S.CS + 13.1, 0.0, fd.y * S.CS)
	add_shot("dead_end_door", dc + Vector3(0.2, 1.62, 6.0), dc + Vector3(0.0, 1.0, 17.2), {"flashlight": false, "prepare": _prep.bind(dc + Vector3(0, 0, 10))})


## A band with paintings (not the inscription) on the arrival chunk, floor 4.
func _painting_view() -> Array:
	var cands := [[2, Vector3(4, 4.0, 9.25), Vector3(-1, 0, 0)], [3, Vector3(24, 4.0, 9.25), Vector3(1, 0, 0)], [1, Vector3(9.25, 4.0, 24), Vector3(0, 0, 1)]]
	for c in cands:
		if S.rnd(0, 0, S.ENTRY_F, level_seed, int(c[0]) + 31) >= 0.22:
			var p: Vector3 = c[1]
			var o: Vector3 = c[2]
			var side := Vector3(o.z, 0, -o.x)
			return [p + o * 3.3 + Vector3.DOWN * 1.9 + side * 1.4, p + Vector3.DOWN * 0.15]
	return [Vector3(1.1, 1.7, 6.6), Vector3(4.0, 3.9, 9.25)]


func _prep(p: Vector3) -> void:
	world.build_around(p, 1)
	_refresh_props(p)
	_light_key = ""
	_refresh_lights(p)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	var floors := 0
	for f in range(1, S.NF + 1):
		var y := S.floor_y(f)
		var q := PhysicsRayQueryParameters3D.create(Vector3(2.0, y + 1.0, 10.0), Vector3(2.0, y - 0.6, 10.0), 1)
		if not space.intersect_ray(q).is_empty():
			floors += 1
	out.append({"what": "seven walkable floors in the arrival chunk", "ok": floors == S.NF, "detail": floors})
	var steps := 0
	for f in range(1, S.NF):
		var y := S.floor_y(f)
		for pt in [Vector3(10.0, y + 3.0, -19.2), Vector3(5.0, y + 5.5, -15.8)]:
			var q2 := PhysicsRayQueryParameters3D.create(pt, pt + Vector3.DOWN * 2.5, 1)
			if not space.intersect_ray(q2).is_empty():
				steps += 1
	out.append({"what": "wooden stairs in the void join every pair of floors", "ok": steps == (S.NF - 1) * 2, "detail": steps})
	var bars := PhysicsRayQueryParameters3D.create(Vector3(14.0, 0.6, 1.0), Vector3(14.0, 0.6, -1.0), 1)
	out.append({"what": "iron bars fence the void beside the arrival corridor", "ok": not space.intersect_ray(bars).is_empty()})
	var fd: Vector2i = builder.forced_dead
	var meta: Dictionary = world.meta_of(fd)
	out.append({"what": "a dead-end corridor with a small wooden door near the arrival", "ok": not meta.is_empty() and meta["doors"].size() >= 1, "detail": fd})
	var before := player.global_position
	player.global_position = Vector3(fd.x * S.CS + 13.1, 0.1, fd.y * S.CS + 16.0)
	_loop_door()
	var looped := player.global_position.distance_to(ENTRY) < 0.5
	player.global_position = before
	out.append({"what": "the small door returns you to the entrance (seamless loop)", "ok": looped})
	var stray := 0
	for a in lights.anchors:
		var ap: Vector3 = a["pos"]
		var in_void := absf(fposmod(ap.x, S.CS) - 14.0) < 0.5 and absf(fposmod(ap.z, S.CS) - 14.0) < 0.5
		if absf(ap.y - S.floor_y(floor_now) - 2.5) > 3.0 and not in_void:
			stray += 1
	out.append({"what": "pooled lights only from the current storey (plus the open void)", "ok": lights.anchors.size() > 0 and stray == 0, "detail": stray})
	var mt: Array = await mind.qa_check()
	out.append_array(mt)
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
