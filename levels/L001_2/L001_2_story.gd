extends RefCounted
## Level 1.2: light plan, soundscape, documents, the Bloom stages and QA checks.

const G := preload("res://levels/L001_2/L001_2_geo.gd")
const D := preload("res://levels/L001_2/L001_2_dress.gd")

const NOTEBOOK := [
	"Day of entry. Grass where concrete should be, and flowers of every colour. No sun, no soil, and yet everything grows.",
	"Specimens from the Frontrooms and from the Backrooms, from different countries and different levels, side by side. Every one of them needs a different climate. They grow together anyway.",
	"Ruins deeper in. Some are camps. Some are far older than any wanderer group could have built.",
	"The bluebonnets: a fall, a cough, and a memory that was not mine. These plants are memories. Of the people who died here.",
	"Something about a dinner. I can't. The sunflowers, go back to the sunflowers, they",
]


static func lights(lvl) -> void:
	var L: LightPool = lvl.lights
	L.setup(14, 1)
	L.max_distance = 34.0
	for t in lvl.geo.tubes:
		if not t["alive"]:
			continue
		var p: Vector3 = t["pos"]
		var deep := clampf((G.ZG - p.z) / (G.ZG - G.Z1), 0.0, 1.0)
		var col := Color(0.86, 0.94, 1.0).lerp(Color(0.92, 1.0, 0.86), deep)
		L.add_anchor(p + Vector3.DOWN * 0.3, col, 1.9 - deep * 0.5, 10.5)


static func sounds(lvl) -> void:
	var S: Soundscape = lvl.sound
	S.bed("room_tone", {"cutoff": 300.0, "rumble": 0.05, "seconds": 6.0}, -33.0)
	S.bed("wind", {"seconds": 9.0}, -40.0)
	S.emitter("fluorescent_hum", Vector3(0, 3.6, 8.0), {"base": 120.0, "rasp": 0.2}, -26.0, 14.0)
	S.emitter("fluorescent_hum", Vector3(-20, 3.6, -24.0), {"base": 100.0, "rasp": 0.1}, -28.0, 12.0)
	S.emitter("drip", Vector3(2.3, 0.1, 8.0), {"freq": 700.0}, -22.0, 10.0)
	S.oneshot("creak", {"freq": 60.0}, 30.0, 70.0, 20.0, "[a pipe ticks somewhere overhead]", -26.0)
	S.oneshot("scratch", {}, 18.0, 40.0, 10.0, "[leaves stir, though nothing moves the air]", -30.0)


static func notes(lvl) -> void:
	lvl.add_note("l12_report", "Exploration report extract (Aquila Sector, 2012)",
		"[i]A torn page from a mapping report. Paraphrased; testimony.[/i]\n\nThree on a mapping mission, lost, lights back on in the halls. One of them spots grass patches in the distance, and flowers. Plants in Level 1? The botanist wants to go in. The leader refuses: it could be toxic, and they are miles from base. They agree on one closer photo, then they turn back to look for the way home.",
		Vector3(2.8, 0.03, -5.4))
	lvl.add_note("l12_article", "M.E.G. Level 1 article (pinned to the pillar)",
		"[i]Paraphrased from the article.[/i]\n\nThis sub-sector looks like the rest of the Scene except for the plants: tall grass and flowers of every colour on the floor, vines over the pillars and walls and sometimes across the ceiling. Nobody knows where they came from.\n\nEntities avoid it completely. Many tried to settle here because of that; none have been heard from again. Do not spend more than a few hours inside.\n\nGarden Sector warning: an hour in there starts turning you into a plant, like many others before you. If you find the entrance, avoid it like the plague.",
		Vector3(4.0, 1.5, -3.26), Vector3(0.5, 0.6, 0.12), false)
	var k: GeoKit = lvl.dress.k
	k.box(Vector3(4.0, 1.5, -3.285), Vector3(0.42, 0.56, 0.01), "paper", GeoKit.ALL, false)
	lvl.add_interactable(D.SUNFLOWERS + Vector3(3.6, 0.2, 2.8), Vector3(0.9, 0.5, 0.9), "Read the botanist's notebook", func(): read_notebook(lvl))
	lvl.add_interactable(Vector3(-28.2, 0.9, -45.5), Vector3(5.6, 1.0, 1.0), "Rest on the low stone wall", func(): lvl.rest_on_fence())
	lvl.add_interactable(Vector3(17.0, 0.9, -55.0), Vector3(2.4, 1.0, 1.6), "Look over the settlers' table", func():
		Overlay.show_note("A settlers' table",
			"Plates, a stew pot, a lantern, chairs knocked over, everything furred with grass. Entities never come in here, and people took that as a reason to stay.\n\nNone of the people who settled in the Concrete Garden have been heard from again."))
	lvl.add_interactable(Vector3(-22.0, 2.4, -66.0), Vector3(8.0, 2.6, 1.2), "Look at the old stonework", func():
		Overlay.show_note("Ancient stonework",
			"Cut stone, columns, an arch: a settlement, long abandoned. It looks far too ancient to have been built by any wanderer group.\n\n[i]Testimony (a botanist's account), not survey.[/i]"))


## The notebook loses words as the garden takes your memories.
static func read_notebook(lvl) -> void:
	var b: float = lvl.bloom
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var out: Array = []
	for i in NOTEBOOK.size():
		var words: PackedStringArray = (NOTEBOOK[i] as String).split(" ")
		var kept: Array = []
		for w in words:
			kept.append("…" if r.randf() < b * 0.9 else w)
		out.append(" ".join(kept))
	Overlay.show_note("A botanist's field notebook (dropped)",
		"[i]Field notes, testimony. Paraphrased.[/i]\n\n" + "\n\n".join(out))


static func bloom_stages(lvl) -> void:
	var b: float = lvl.bloom
	var told: Dictionary = lvl.told
	var qa := SessionState.is_qa()
	if not qa:
		Overlay.set_screen_effect("vignette", 0.25 + b * 0.45)
		Overlay.set_screen_effect("desaturate", b * 0.25)
	if b > 0.01 and not told.has("b1"):
		told["b1"] = true
		if not qa:
			Overlay.toast("You have been in the garden for a while now. An hour here is enough for it to start working on you.", 5.0)
	if b >= 0.35 and not told.has("b2"):
		told["b2"] = true
		if not qa:
			Overlay.subtitle("[there was someone you meant to tell where you were going. You can't think who.]", 5.0)
	if b >= 0.6 and not told.has("b3"):
		told["b3"] = true
		if not qa:
			Overlay.toast("A rose has opened on your right leg. Its stem goes in through the skin.", 5.0)
	if b >= 0.85 and not told.has("b4"):
		told["b4"] = true
		if lvl.player:
			lvl.player.walk_speed = lvl._base_walk * 0.55
			lvl.player.sprint_speed = lvl._base_walk * 0.7
		if not qa:
			Overlay.subtitle("[your legs feel far away. The muscles answer late, then not at all.]", 5.0)
	if b >= 1.0 and not told.has("b5"):
		told["b5"] = true
		if lvl.player and not qa:
			lvl.player.hurt(1000.0, "became one more memory in the Concrete Garden")


static func self_test(lvl) -> Array:
	await lvl.get_tree().process_frame
	var out: Array = []
	var fl = lvl.flora
	var dr = lvl.dress
	out.append({"what": "grass carpet and multicoloured flowers instanced", "ok": dr.tufts_n > 8000 and dr.flowers_n > 2500, "detail": [dr.tufts_n, dr.flowers_n, fl.instances]})
	out.append({"what": "vines on pillars and walls (leaves instanced)", "ok": dr.leaves.size() > 3, "detail": dr.leaves.size()})
	var space: PhysicsDirectSpaceState3D = lvl.get_world_3d().direct_space_state
	var h1 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-20.0, 4.0, -58.0), Vector3(-20.0, -1.0, -58.0), 1))
	out.append({"what": "ancient terrace is walkable at +1.2 m", "ok": not h1.is_empty() and absf(h1["position"].y - G.TERRACE_Y) < 0.05, "detail": h1.get("position", null)})
	var h2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(5.0, 1.0, -64.0), Vector3(5.0, -4.0, -64.0), 1))
	out.append({"what": "sunken bay floor at -1.2 m", "ok": not h2.is_empty() and absf(h2["position"].y - G.PIT_Y) < 0.05, "detail": h2.get("position", null)})
	var h3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(24.0, 4.0, -48.0), Vector3(24.0, 0.5, -48.0), 1))
	out.append({"what": "settlers' lookout platform at +2.4 m", "ok": not h3.is_empty() and absf(h3["position"].y - G.LOOKOUT_Y) < 0.05, "detail": h3.get("position", null)})
	# Bloom: nothing during the first compressed hour, then it grows
	lvl.bloom = 0.0
	lvl.garden_t = 0.0
	lvl.step_bloom(200.0)
	var early: float = lvl.bloom
	lvl.step_bloom(120.0)
	out.append({"what": "Bloom starts only after the compressed hour, then grows", "ok": early == 0.0 and lvl.bloom > 0.0, "detail": [early, lvl.bloom]})
	var m0: int = lvl.memories
	var b0: float = lvl.bloom
	lvl.memory(1)
	out.append({"what": "bluebonnet pollen plays a memory and feeds Bloom", "ok": lvl.memories == m0 + 1 and lvl.bloom > b0})
	lvl.rest_on_fence()
	await lvl.get_tree().physics_frame
	var h4 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-28.0, 0.6, -45.5), Vector3(-28.0, 0.05, -45.5), 1))
	out.append({"what": "the fragile stone fence gives way (collision gone, rubble shown)", "ok": not lvl.geo.fence_node.visible and lvl.geo.rubble_node.visible and h4.is_empty(), "detail": h4.get("position", null)})
	lvl.bloom = 0.9
	bloom_stages(lvl)
	out.append({"what": "at 85 % Bloom the body slows", "ok": lvl.player.walk_speed < lvl._base_walk, "detail": lvl.player.walk_speed})
	lvl.player.walk_speed = lvl._base_walk
	lvl.player.sprint_speed = lvl._base_sprint
	lvl.bloom = 0.0
	lvl.garden_t = 0.0
	lvl.told.clear()
	out.append({"what": "the only exit is the walk back to Level 1", "ok": lvl.exits.size() == 1 and (lvl.exits[0] as ExitTrigger).edge_id == "L001_2>L001#1"})
	return out
