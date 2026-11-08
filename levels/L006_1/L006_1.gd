extends LevelBase
## Level 6.1 "The Snackrooms" (Backrooms Wikidot rev 100, accessed 2026-11-04;
## "Level 6.1 - "The Snackrooms"" by Stretchsterz, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L006_1.md. Content note: the page's December 2020
## massacre by shape-shifters posing as Guild of Many members is a logged
## incident (TESTIMONY); it appears only as the lockdown notice. Nothing hostile
## spawns here.
##
## PLAN (v2.0 rebuild: read -> design)
## - SOURCE: a sub-section of Level 6: an infinite 1980s mall cafeteria, a
##   labyrinth of snack bars and restaurants from modern joints back to the 1600s,
##   navy blue cafeteria tables and chairs, spacious halls with few benches,
##   pillars and plants, large rooms with a circular dip and benches all around
##   -> an atrium food court with a three-step sunken dip (the second walkable
##   height), four 8 m halls of storefronts (L006_1_mall.gd), interiors
##   (L006_1_shops.gd), furniture and people (L006_1_kit.gd).
## - SOURCE: glass skylights on most ceilings show only darkness, yet everything
##   is lit like daylight, unchanging; windows glow a slight orange-white -> black
##   skylight glass with the light pooled beneath it; glowing clerestory windows.
##   The darkness above is Level 6's (the parent: total darkness).
## - SOURCE: restaurant exits can lead to another restaurant -> the back EXIT of
##   each restaurant brings you in through the back of a different one (seeded).
## - SOURCE: food is free and restocks weekly; some restaurants close when they
##   run out; vending machines give snacks and drinks (Almond Water, Cashew Water,
##   distilled water) with no payment; rooms of machines in order or random; some
##   rooms blocked by piled machines -> stocked counters whose shutters roll down
##   when empty ("closed until restock"), free vending with finite stock, a seeded
##   vending room, a hall end choked with toppled machines (a diegetic boundary).
## - SOURCE: Facelings with "The 11 Effect" cook, clean and serve; Track Mappers
##   give maps to anyone who asks; a M.E.G. outpost with 4+ guards at the rusty
##   steel door to Level 6 (screaming behind it; permission needed); lockdown.
## - SOURCE: Clippers, the 1950s red bar with wooden floor where the discoverer
##   fell from Level 6 onto a table -> the from_L006 arrival lands on that table.
## - Exits: perimeter sliding glass doors -> Level 11 (the walker's target, the
##   safest way); rusty steel door -> Level 6 (after the guards' warning); any vent
##   opening -> Level 3; an unnaturally bent wall -> The Blue Channel (not built).
## - Signature mechanic (stateful): free food that runs out. Each counter and
##   machine has a stock; emptied shops shut their shutters until the restock.
## - ABSENT: payment, natural hostiles, wars, the massacre as an encounter, the
##   "free us" line as an exit, Level 1.5 / 6.2 edges.

const Kit := preload("res://levels/L006_1/L006_1_kit.gd")
const Mall := preload("res://levels/L006_1/L006_1_mall.gd")
const Shops := preload("res://levels/L006_1/L006_1_shops.gd")
const START := Vector3(0.0, 0.0, 22.0)
const ITEMS := ["a bag of chips", "cheese puffs", "a chocolate bar", "a bottle of Almond Water", "a bottle of Cashew Water",
	"a bottle of distilled water", "a bottle of purified water", "a pack of crackers"]
const MEALS := ["a burger, still hot", "a slice of pizza", "a paper cup of coffee", "a bowl of noodles", "a warm pretzel",
	"fries in a paper cone", "a sandwich", "a scoop of ice cream", "a plate of pancakes"]

var K
var M
var S
var props: Node3D
var permission := false
var map_given := false
var meals := 0
var snacks := 0
var _go6 := false
var _bent_go := false
var _warp_map: Array = []
var _warp_cd := 0.0
var _slide: Array = []
var _slide_t := 0.0
var _shutter_anim: Array = []
var _scream_t := 8.0
var _music_said := false


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 180.0
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.14
	indoor_env(Color(1.0, 0.9, 0.78), 0.18, Color(0.55, 0.48, 0.4), 0.003)
	environment.tonemap_exposure = 0.82
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.12
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_hdr_threshold = 1.0
	Mall.materials()
	Shops.materials()
	props = Node3D.new()
	props.name = "Dressing"
	add_child(props)
	var k := kit("Mall")
	K = Kit.new(self, props, k)
	M = Mall.new(self, props, k, K)
	M.build(Shops.SLOTS)
	S = Shops.new(self, props, k, K)
	S.build(M.slots)
	_sliding_doors(k)
	k.commit()
	_warp_setup()
	_lights()
	_sounds()
	_exits()
	_interactions()
	_notes()
	add_arrival("start", START, 0.0)
	add_arrival("from_L006", S.clippers_table + Vector3(0, 0.8, 0), S.clippers_yaw)
	add_landmark("Atrium food court with the circular dip", Vector3(0, -0.9, 0))
	add_landmark("Clippers (1950s red bar)", S.clippers_table)
	add_landmark("Perimeter sliding glass doors (Level 11)", Vector3(0, 0, 56))
	add_landmark("M.E.G. Level 6 Access Outpost, rusty steel door", Vector3(0, 0, -62))
	add_landmark("Track Mappers office (maps)", S.map_desk)
	add_landmark("Room blocked by piled vending machines", Vector3(57.5, 0, 0))
	add_landmark("The bent wall", M.bent_wall)
	add_shot("atrium", Vector3(-1.5, 1.7, 14.5), Vector3(-2.0, -0.6, -6.0), {"flashlight": false})
	add_shot("dip", Vector3(2.0, 1.7, 10.6), Vector3(-1.0, -0.9, 1.0), {"flashlight": false})
	add_shot("north_hall", Vector3(1.2, 1.7, -17.0), Vector3(-0.6, 1.4, -62.0), {"flashlight": false})
	add_shot("clippers", S.clippers_table + Vector3(2.6, 1.65, 0.0) + _dir_in(S.clippers_yaw) * -3.0, S.clippers_table + _dir_in(S.clippers_yaw) * 3.0 + Vector3(0, 0.6, 0), {"flashlight": false})
	add_shot("glass_doors", Vector3(1.5, 1.7, 40.0), Vector3(0.0, 1.6, 57.0), {"flashlight": false})
	add_shot("east_hall", Vector3(20.0, 1.7, 1.5), Vector3(56.0, 1.2, -0.5), {"flashlight": false})
	add_shot("tavern", _tavern_cam(), _tavern_cam() + Vector3(-4.0, -0.6, 0.0), {"flashlight": false})


func _dir_in(yaw_deg: float) -> Vector3:
	# the direction a player with this yaw faces
	return Vector3(-sin(deg_to_rad(yaw_deg)), 0, -cos(deg_to_rad(yaw_deg)))


func _tavern_cam() -> Vector3:
	for s in M.slots:
		if s["kind"] == "tavern":
			return (s["xf"] as Transform3D) * Vector3(2.8, 1.7, 1.2)
	return Vector3.ZERO


# ---------------------------------------------------------------- construction

func _sliding_doors(_k: GeoKit) -> void:
	for sx in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(sx * 1.35, 0, 56.0)
		props.add_child(leaf)
		var g := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.7, 3.55, 0.04)
		g.mesh = bm
		g.material_override = MatLib.get_mat("l61_glass")
		g.position = Vector3(0, 1.78, 0)
		leaf.add_child(g)
		for fy in [0.04, 3.52]:
			var fr := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(2.7, 0.08, 0.08)
			fr.mesh = fm
			fr.material_override = MatLib.get_mat("l61_chrome")
			fr.position = Vector3(0, fy, 0)
			leaf.add_child(fr)
		var ed := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(0.08, 3.55, 0.08)
		ed.mesh = em
		ed.material_override = MatLib.get_mat("l61_chrome")
		ed.position = Vector3(-sx * 1.33, 1.78, 0)
		leaf.add_child(ed)
		_slide.append({"node": leaf, "x0": sx * 1.35, "x1": sx * 3.9})


func _warp_setup() -> void:
	# SOURCE: a restaurant's exit can lead into another restaurant (seeded derangement)
	var n: int = S.backdoors.size()
	var order: Array = range(n)
	for i in range(n - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t: int = order[i]
		order[i] = order[j]
		order[j] = t
	for i in n:
		if order[i] == i:
			var sw := (i + 1) % n
			var t2: int = order[i]
			order[i] = order[sw]
			order[sw] = t2
	_warp_map = order


func _lights() -> void:
	lights.setup(16, 1)
	lights.max_distance = 42.0
	for p in M.skylights:
		lights.add_anchor(p, Color(1.0, 0.93, 0.8), 1.5, 10.0, 0.0, "sky")
	for l in S.lamps:
		lights.add_anchor(l["pos"], l["col"], 1.4 * float(l["e"]), 7.0, 0.0, "shop")
	lights.add_anchor(Vector3(0, 3.0, 58.5), Color(1.0, 0.86, 0.66), 2.4, 9.0, 0.0, "daylight")
	var sun := OmniLight3D.new()
	sun.name = "SkylightFill"
	sun.position = Vector3(0, 6.6, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.light_energy = 2.0
	sun.omni_range = 18.0
	sun.omni_attenuation = 0.7
	sun.shadow_enabled = true
	add_child(sun)


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 420.0, "rumble": 0.1, "seconds": 6.0}, -30.0)
	sound.bed("chiptune", {"bpm": 118.0, "root": 220.0, "scale": [0, 2, 4, 7, 9, 12, 14, 16]}, -25.0)
	sound.bed("whisper", {"seconds": 5.0}, -38.0)
	for m in S.music_spots:
		match m["kind"]:
			"jukebox":
				sound.emitter("chiptune", m["pos"], {"bpm": 140.0, "root": 261.6, "scale": [0, 4, 7, 9, 12]}, -12.0, 10.0)
			"lounge":
				sound.emitter("pad", m["pos"], {"root": 110.0, "chord": [0, 3, 7, 10], "bright": 0.35, "seconds": 8.0}, -14.0, 11.0)
			"old":
				sound.emitter("music_box", m["pos"], {"notes": [0, 3, 5, 7, 10, 7, 5, 3], "root": 196.0}, -16.0, 10.0)
			"diner":
				sound.emitter("chiptune", m["pos"], {"bpm": 128.0, "root": 293.7, "scale": [0, 2, 4, 7, 9]}, -14.0, 10.0)
	for v in M.vents:
		sound.emitter("wind", v["pos"], {"seconds": 4.0}, -16.0, 6.0)
	sound.emitter("whisper", Vector3(0, 1.2, -65.0), {"seconds": 3.0}, -14.0, 14.0)
	sound.emitter("crackle", M.bent_wall, {"seconds": 3.0}, -20.0, 7.0)
	for c in S.counters:
		sound.emitter("crackle", c["pos"] + Vector3(0, 0, 0), {"seconds": 2.0}, -30.0, 5.0)


func _exits() -> void:
	# 1 (walker target): the perimeter sliding glass doors -> Level 11, the safest way out
	add_exit("L006_1>L011#2", "walk_in", Vector3(0, 1.2, 58.6), Vector3(5.2, 2.4, 2.4))
	# 2: the rusty steel door -> Level 6, once the guards have let you through
	var t6 := add_exit("L006_1>L006#1", "condition", Vector3(0, 1.1, -63.0), Vector3(1.8, 2.2, 1.8))
	if t6:
		t6.condition = func() -> bool: return _go6
	# 3: any vent opening -> Level 3
	for v in M.vents:
		add_exit("L006_1>L003#3", "interact", v["pos"], Vector3(1.4, 1.2, 1.2), "Crawl into the vent opening")
	# 4: the unnaturally bent wall -> The Blue Channel (destination set as you step in)
	var tb := add_exit("L006_1>EXT#4", "condition", M.bent_wall, Vector3(2.4, 2.4, 2.0))
	if tb:
		tb.condition = func() -> bool: return _bent_go


func _interactions() -> void:
	for i in S.counters.size():
		var c: Dictionary = S.counters[i]
		add_interactable(c["pos"], Vector3(1.6, 0.5, 0.6), "Ask for food (it is free)", _serve.bind(i))
	for i in K.vending.size():
		var v: Dictionary = K.vending[i]
		add_interactable(v["pos"], Vector3(0.8, 0.8, 0.3), "Press a button on the vending machine", _vend.bind(i))
	add_interactable(S.map_desk, Vector3(1.6, 0.6, 0.6), "Ask the Track Mappers for a map", _map)
	add_interactable(S.guard_post, Vector3(0.7, 1.2, 0.7), "Talk to the M.E.G. guard", _guard)
	add_interactable(Vector3(0, 1.2, -63.85), Vector3(1.3, 2.2, 0.2), "Open the rusty steel door", _steel_door)
	add_interactable(M.bent_wall + Vector3(0, 0.3, 0), Vector3(1.6, 1.8, 0.4), "Step into the bent wall", _bent)


func _notes() -> void:
	var cl: Vector3 = S.clippers_table
	add_note("l61_clippers", "Framed card behind the bar",
		"CLIPPERS. In 2011 a wanderer of The Explorers tripped on a wire in the dark of Level 6, fell through the floor and landed on a wooden table in a red-walled bar like this one. The photo he took never loaded. The Snackrooms Staff named the bar for the wire.\n\n(paraphrased; Level 6.1 article, Backrooms Wiki, CC BY-SA 3.0)",
		cl + Vector3(0, 0.8, 0) + _dir_in(S.clippers_yaw) * 0.25)
	add_note("l61_lockdown", "M.E.G. notice (laminated)",
		"LOCKDOWN. The Guild of Many is under investigation over a possible entity invasion. Every entrance to Level 6.1 is guarded by the M.E.G. until further notice. Wanderers who trip in are escorted once identified as human.\n\nThe Level 6 door is for research and exploration only.",
		Vector3(-2.55, 0.82, -62.0))
	add_note("l61_staff", "Snackrooms Staff board",
		"Everything here is free. No payment, no currency (there is talk of one; ignore it).\nStock comes back once a week, in no particular order. When a counter runs dry, its shutter comes down until the restock.\nThe Facelings help us cook, clean and serve. Be nice to them.\nNo fighting. This is a safe zone for every group.",
		Vector3(12.5, 0.77, 2.6))
	add_note("l61_expansion", "Track Mappers log card",
		"Paraphrased from a Track Mappers log: a crack in a wall started to glow blue and The Blue Channel showed through it; the wall then morphed and ran back, unfolding halls nobody had mapped. A 'Level Expansion Event', seen twice. Stay back if a wall starts to bend.",
		_slot_point("NL4", Vector3(-0.6, 0.81, 2.1)))


func _slot_point(key: String, local: Vector3) -> Vector3:
	for s in M.slots:
		var kk: String = "%s%s%d" % [s["hall"], "L" if s["side"] == 1 else "R", s["i"]]
		if kk == key:
			return (s["xf"] as Transform3D) * local
	return Vector3.ZERO


# ---------------------------------------------------------------- interactions

func _serve(i: int) -> void:
	var c: Dictionary = S.counters[i]
	if c["stock"] <= 0:
		Overlay.subtitle("[nothing left here until the restock]", 2.0)
		return
	c["stock"] -= 1
	meals += 1
	player.heal(15.0)
	Overlay.subtitle("[a Faceling slides you %s. No charge]" % MEALS[rng.randi() % MEALS.size()], 2.5)
	if c["stock"] == 0 and int(c["shutter"]) >= 0:
		var sh: Dictionary = S.shutters[c["shutter"]]
		_shutter_anim.append({"sh": sh, "t": 0.0})
		Overlay.subtitle("[that was the last of it; the shutter rattles down: CLOSED UNTIL RESTOCK]", 3.0)
		sound.play_at("creak", {"freq": 90.0}, c["pos"], -8.0, "")


func _vend(i: int) -> void:
	var v: Dictionary = K.vending[i]
	if v["stock"] <= 0:
		Overlay.subtitle("[the machine hums; SOLD OUT until the restock]", 2.0)
		return
	v["stock"] -= 1
	snacks += 1
	player.heal(6.0)
	sound.play_at("knock", {"hits": 2}, v["pos"], -10.0, "")
	Overlay.subtitle("[clunk: %s drops into the tray. No payment needed]" % ITEMS[rng.randi() % ITEMS.size()], 2.2)


func _map() -> void:
	map_given = true
	Overlay.show_note("Track Mappers map (controlled area)",
		"A photocopied sketch, handed over without question:\n\nCENTRE: the food court with the sunken seating.\nNORTH HALL: Clippers and Liquorette at the near end; coffee, pizza; our office; M.E.G. outpost and the Level 6 door at the far end (restricted).\nSOUTH HALL: burgers, the old tavern with no name, soda fountain, restrooms, a vending room. Glass doors at the very end: Level 11, the easy way out.\nEAST HALL: the diner; the far end is choked with vending machines.\nWEST HALL: shuttered; watch for bent walls.\n\nVents pull you down to Level 3. Restaurant back doors do not go where you think.")


func _guard() -> void:
	permission = true
	Overlay.show_note("M.E.G. guard",
		"\"Level 6 access is for research and exploration, nothing else. We're on lockdown.\" He looks at you for a long moment.\n\n\"You want to go into the dark, that's on you. Sign the log. Don't come back with anyone you didn't leave with.\"\n\n(The guards will let you open the steel door.)")


func _steel_door() -> void:
	if not permission:
		Overlay.subtitle("[a guard steps in front of the door: \"Restricted. Talk to us first.\"]", 2.5)
		return
	_go6 = true
	Overlay.subtitle("[the rusty door grinds open on total darkness; the screaming stops]", 2.0)


func _bent() -> void:
	var e := TransitionService.get_edge("L006_1>EXT#4")
	if not e.is_empty():
		e["to"] = "THE_BLUE_CHANNEL"
	_bent_go = true
	Overlay.subtitle("[the wall gives like cloth; blue light pours through the cracks]", 2.0)


# ---------------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	# perimeter sliding doors open as you approach
	var want := 1.0 if Vector2(pp.x, pp.z - 56.0).length() < 5.0 else 0.0
	_slide_t = move_toward(_slide_t, want, delta * 1.6)
	for s in _slide:
		(s["node"] as Node3D).position.x = lerpf(s["x0"], s["x1"], smoothstep(0.0, 1.0, _slide_t))
	for a in _shutter_anim.duplicate():
		a["t"] = minf(1.0, a["t"] + delta * 0.8)
		var sh: Dictionary = a["sh"]
		var mi := sh["mi"] as MeshInstance3D
		mi.scale.y = lerpf(0.04, 1.0, a["t"])
		var top: float = (mi.global_transform.basis.y.normalized()).y
		mi.global_position.y = lerpf(float(sh["h"]) - 0.05, float(sh["h"]) * 0.5, a["t"]) * top
		if a["t"] >= 1.0:
			(sh["placard"] as Label3D).visible = true
			_shutter_anim.erase(a)
	# restaurant back doors lead into a different restaurant
	_warp_cd -= delta
	if _warp_cd <= 0.0:
		for i in S.backdoors.size():
			var bd: Dictionary = S.backdoors[i]
			var z: Vector3 = bd["zone"]
			if Vector2(pp.x - z.x, pp.z - z.z).length() < 0.75 and absf(pp.y - z.y) < 1.6:
				var to: Dictionary = S.backdoors[_warp_map[i]]
				player.global_position = to["inside"]
				player.rotation.y = deg_to_rad(to["yaw"])
				player.velocity = Vector3.ZERO
				Overlay.glitch(0.35)
				Overlay.subtitle("[the back door lets you into a different restaurant]", 2.2)
				_warp_cd = 2.0
				break
	# screaming behind the steel door, only when close
	_scream_t -= delta
	if _scream_t <= 0.0:
		_scream_t = rng.randf_range(14.0, 26.0)
		if pp.z < -50.0 and absf(pp.x) < 5.0 and not _go6:
			Overlay.subtitle("[screaming, muffled, from behind the rusty steel door]", 3.0)
	if not _music_said and SessionState.in_gameplay:
		_music_said = true
		Overlay.subtitle("[an 80s pop song plays from ceiling speakers somewhere]", 3.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "free-food counters and vending machines are stocked", "ok": S.counters.size() >= 8 and K.vending.size() >= 15, "detail": [S.counters.size(), K.vending.size()]})
	out.append({"what": "restaurant back doors lead to a different restaurant", "ok": _warp_map.size() >= 4 and not _warp_map.has(-1) and range(_warp_map.size()).all(func(i): return _warp_map[i] != i), "detail": _warp_map})
	_serve(0)
	out.append({"what": "serving reduces stock (no payment)", "ok": meals == 1, "detail": S.counters[0]["stock"]})
	return out
