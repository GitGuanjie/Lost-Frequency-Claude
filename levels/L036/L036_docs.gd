extends RefCounted
## Level 36: centre lights, the soundscape, the BTA's documents and the stills/QA.

const C := preload("res://levels/L036/L036_core.gd")
const T := preload("res://levels/L036/L036_term.gd")
const S := preload("res://levels/L036/L036_strip.gd")
const SY := preload("res://levels/L036/L036_sys.gd")


static func lights(lvl) -> void:
	var L: LightPool = lvl.lights
	L.add_anchor(Vector3(-9.0, 2.6, -14.6), Color(0.7, 0.35, 1.0), 1.0, 7.0)
	L.add_anchor(Vector3(-8.0, 2.8, 11.5), Color(0.95, 0.96, 1.0), 0.9, 7.0)
	L.add_anchor(Vector3(0, C.MEZZ_Y - 0.6, -40.0), Color(0.95, 0.96, 1.0), 1.1, 9.0)
	for x in [-10.0, 0.0, 10.0]:
		L.add_anchor(Vector3(x, C.MEZZ_Y + 3.0, -40.0), Color(1.0, 0.94, 0.85), 1.0, 9.0)


static func sounds(lvl) -> void:
	var Sd: Soundscape = lvl.sound
	Sd.bed("room_tone", {"cutoff": 220.0, "rumble": 0.08, "seconds": 6.0}, -27.0)
	Sd.bed("fluorescent_hum", {"base": 120.0, "rasp": 0.08, "seconds": 3.0}, -40.0)
	for x in [9.7, 25.7, -22.3]:
		Sd.emitter("transformer", Vector3(x, 0.4, 14.0), {"base": 48.0}, -17.0, 26.0)
	Sd.oneshot("creak", {"freq": 90.0}, 14.0, 34.0, 18.0, "[metal creaks somewhere along the carousels]", -22.0)
	Sd.emitter("whisper", Vector3(-30.0, 1.2, -126.0), {"seconds": 3.0}, -15.0, 30.0)
	Sd.emitter("whisper", Vector3(-30.0, 1.2, -140.0), {"seconds": 2.6}, -17.0, 30.0)
	Sd.emitter("room_tone", Vector3(0, 0.2, -75.0), {"cutoff": 600.0, "seconds": 3.0}, -26.0, 12.0)


static func notes(lvl) -> void:
	lvl.add_note("l36_flyer", "BTA navigation flyer (booth 0)",
		"[i]Backrooms Travel Agency flyer, paraphrased.[/i]\n\nORIENTATION: work out where you want to go. NAVIGATION: get to your gate. ANTICIPATION: wait until your flight is called, then board.\n\nThe screens list every outbound flight by a countdown, a flight number, a gate and a status. At 1000 the flight boards: its gate becomes a doorway into Sublevel 36.1, the Airplane. At 0 the doorway closes and the flight is gone. Nobody knows where most flights go; boarding blind can take you somewhere deadly.\n\nOur catalogue (already out of date as you read it): gate H85 to Level 828, recommended. Gate Y436 to Level 750, not recommended. Gate P252: Level 36 itself, useless. Gate C32 to Level 186, recommended, at a countdown of 94612753.\n\nQUICK TIPS: if a sign contradicts the last one, follow the new one. Do not trust any \"exit\" sign; there is no real exit. Listen to the PA and watch the screens. Empty sign = no good. Lost? Find a Meeting Place; our staff pass through.",
		Vector3(-10.5, 1.17, -15.3))
	lvl.add_interactable(Vector3(-9.8, 1.2, 9.8), Vector3(3.0, 0.6, 1.0), "Ask at the Lost and Found counter", func():
		Overlay.show_note("Lost and Found",
			"Mostly empty: a few discarded or forgotten bags on the shelves.\n\nAnything left on a carousel for ten rounds is rerouted here. It is common courtesy not to touch other people's luggage.\n\nRerouted since you arrived: %d." % lvl.sys.rerouted))
	lvl.add_interactable(C.MEET + Vector3(0.0, 1.6, 0.0), Vector3(1.6, 1.6, 1.6), "Read the Meeting Place sign", func():
		Overlay.show_note("The Meeting Place",
			"Reported in at least 47 different places in the airport, and every report describes the same single place. It cannot be mapped; it seems to vanish and come back.\n\nIf you are lost, wait here: other wanderers come through, and BTA staff pass by regularly."))
	lvl.add_interactable(T.C32_CAMP + Vector3(3.6, 1.2, 5.5), Vector3(1.4, 1.2, 0.8), "Read the group's board", func():
		Overlay.show_note("Gate 32 Support Group",
			"Spread around gate C32, the largest community in the airport waits for flight 1784XBA8JLP to Level 186, the Infinite Valley. Its countdown sits on the very last row of every screen.\n\nAbout 150 of them are real passengers; others just come to spend time with them. They keep their own day and night, mealtimes, and outings: the lounges, the shops, the Meeting Place, walking other wanderers to their gates.\n\n\"I've been waiting for, what, five months? I'm not gonna give up now.\" (a passenger)\n\nTheir blankets and bags are here. Their voices carry from somewhere further on."))
	lvl.add_interactable(Vector3(6.0, 0.6, -117.0), Vector3(3.0, 1.0, 0.8), "Try to sleep", func():
		Overlay.toast("You close your eyes and wait. Nothing comes. It is physically impossible to sleep anywhere in this airport, however tired you are.", 5.0))
	lvl.add_interactable(Vector3(9.0, 5.6, T.Z0 - 0.4), Vector3(1.2, 1.2, 0.6), "Check the time", func():
		Overlay.toast("The clocks disagree, and one has no hands. Your own watch stopped the moment you arrived. There is no day or night here; the countdown on the screens is the only thing that moves.", 5.5))
	lvl.add_interactable(Vector3(-3.9, 1.3, T.GATE_DOOR.z + 4.4), Vector3(2.0, 1.2, 1.2), "Read the gate screen", func():
		var f: Dictionary = lvl.sys.ours()
		Overlay.show_note("Gate C31",
			"Flight %s. Status: %s. Countdown: %d.\n\nWhen the countdown reaches 1000 the doors open onto the jet bridge, a threshold into Sublevel 36.1, the Airplane. At 0 it closes. The destination is not announced; most flights have never been documented." % [f.get("num", "?"), lvl.sys.status(f), int(f.get("cd", 0.0))]))
	lvl.add_interactable(Vector3(-22.0, 1.0, -66.0), Vector3(5.0, 1.6, 1.2), "Search the shelves", func():
		var r := randf()
		var found := "Nothing you can use: brand-name goods that are worth nothing here."
		if r < 0.06:
			found = "Behind the sparkling water, a single bottle of Almond Water."
		elif r < 0.1:
			found = "A carton of Lucky O' Milk, mixed in with the dairy."
		elif r < 0.14:
			found = "A packet of ChocoBytes in the snack aisle."
		elif r < 0.5:
			found = "Clothes, a bag, packaged snacks: the only things here that are worth taking."
		Overlay.toast(found + " Don't scavenge too long, or you may end up far from where you started.", 5.0))


static func shots(lvl) -> void:
	lvl.add_shot("baggage_claim", Vector3(4.0, 2.3, -2.5), Vector3(40.0, 0.8, 10.0))
	lvl.add_shot("check_in", Vector3(5.0, 1.62, -16.0), Vector3(-30.0, 2.6, -27.0))
	lvl.add_shot("concourse", Vector3(-3.4, 1.62, -46.0), Vector3(0.5, 1.4, -100.0))
	lvl.add_shot("gate_c31", Vector3(5.0, 1.62, -124.0), Vector3(-1.0, 1.6, -152.0))
	lvl.add_shot("c32_camp", Vector3(-3.0, 1.9, -124.0), Vector3(-17.0, 0.3, -136.0))
	lvl.add_shot("food_court", Vector3(9.0, 6.6, -36.8), Vector3(-8.0, 5.5, -42.0))
	lvl.add_shot("meeting_place", Vector3(6.6, 1.62, -74.0), Vector3(13.0, 0.4, -79.0))
	lvl.add_shot("duty_free", Vector3(-7.0, 1.62, -64.0), Vector3(-30.0, 1.0, -74.0))


static func self_test(lvl) -> Array:
	await lvl.get_tree().process_frame
	var out: Array = []
	var sys = lvl.sys
	lvl.player.global_position = lvl.SPAWN
	lvl.world.build_around(lvl.SPAWN, 3)
	await lvl.get_tree().process_frame
	lvl.refresh_screens()
	var live: Array = lvl.strip.screens.filter(func(x): return is_instance_valid(x) and not (x as Node).is_queued_for_deletion())
	out.append({"what": "baggage carousels streamed with numbers; #9 at the arrival", "ok": lvl.strip.carousels.has(0) and lvl.strip.carousels[0]["number"] == 9 and lvl.strip.carousels.size() >= 6, "detail": lvl.strip.carousels.size()})
	out.append({"what": "every check-in screen shows the shared countdown", "ok": live.size() >= 6 and (live[0] as Label3D).text.contains("1784XBA8JLP"), "detail": live.size()})
	# boarding: open now (QA fixture), closes at 0, a new flight takes the gate
	var b0: bool = sys.boarding()
	var f: Dictionary = sys.ours()
	var num: String = f["num"]
	sys.tick(f["cd"] / SY.RATE + 0.5)
	var f2: Dictionary = sys.ours()
	out.append({"what": "gate C31 boards between 1000 and 0, then a new flight takes the gate", "ok": b0 and not sys.boarding() and f2["num"] != num and f2["cd"] > 1000.0, "detail": [num, f2["num"], f2["cd"]]})
	lvl.level_process(5.0)
	out.append({"what": "gate doors shut (collision) when not boarding", "ok": lvl.term.door_body.collision_layer == 1})
	f2["cd"] = 995.0
	lvl.level_process(5.0)
	out.append({"what": "gate doors open when boarding", "ok": lvl.term.door_body.collision_layer == 0})
	var c32: Array = sys.flights.filter(func(x): return x["gate"] == "C32")
	out.append({"what": "C32's flight keeps its enormous countdown", "ok": c32.size() == 1 and c32[0]["cd"] > 94000000.0})
	var bags_before: int = sys.bags.size()
	for i in 80:
		sys.bags_step(8.0)
	out.append({"what": "luggage left 10 rounds is rerouted to Lost and Found", "ok": sys.rerouted > 0 and sys.bags.size() < bags_before, "detail": [bags_before, sys.rerouted]})
	var space: PhysicsDirectSpaceState3D = lvl.get_world_3d().direct_space_state
	var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 7.0, -40.0), Vector3(0, 3.0, -40.0), 1))
	out.append({"what": "food-court mezzanine walkable at +5 m", "ok": not h.is_empty() and absf(h["position"].y - C.MEZZ_Y) < 0.05, "detail": h.get("position", null)})
	var h2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(18.0, 6.5, -120.0), Vector3(18.0, 2.0, -120.0), 1))
	out.append({"what": "terminal lounge mezzanine at +4.2 m", "ok": not h2.is_empty() and absf(h2["position"].y - T.LOUNGE_Y) < 0.05, "detail": h2.get("position", null)})
	out.append({"what": "only exit: gate C31 into Sublevel 36.1", "ok": lvl.exits.size() == 1 and (lvl.exits[0] as ExitTrigger).edge_id == "L036>L036_1#1"})
	return out
