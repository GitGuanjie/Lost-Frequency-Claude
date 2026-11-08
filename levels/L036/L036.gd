extends LevelBase
## Level 36 — "Timeless Airport" (Backrooms Wikidot rev 33, accessed 2026-11-04;
## cite: Endrew1, CC BY-SA 3.0). Dossier: docs/canon/levels/L036.md.
##
## PLAN (v2.0 rebuild; authored layout, procedural: false)
## SOURCE: you arrive by conveyor belt in baggage claim; endless rows of numbered
##   carousels, attached to a wall that is the only known bounded edge; most belts
##   are still; each active belt is one entrance (Level 11: #9, #28, #147); bags left
##   10 rounds are rerouted to the mostly empty Lost and Found. Check-in: an infinite
##   row of deserted counters; screens everywhere list flights by unitless countdown,
##   flight number, gate and status; at 1000 a flight boards and its gate becomes a
##   threshold to Sublevel 36.1; at 0 it closes and vanishes. BTA booth 0 with
##   bright purple signs. Defunct security, then a non-Euclidean maze of concourses
##   that connect to themselves, contradictory signs (do not trust "exit"; an empty
##   sign is no good), hot and cold air, light distortion and afterimages of
##   wanderers, carpeted duty-free halls of mostly worthless goods, one-way
##   travelators, the Meeting Place. Terminals: gates with seats, bathrooms,
##   fountains, lounges with books, buffets and fridges. Clocks random or handless,
##   no day or night, sleep impossible. Gate C32: the Support Group waits for flight
##   1784XBA8JLP (countdown 94612753). A monotone, androgynous PA voice.
## SPACE: the baggage hall (6.5 m) and the check-in hall (12 m) stream in 32 m chunks
##   along x without end, fading into haze; the bounded wall stays on one side. At
##   the centre: Lost and Found, BTA booth 0, a food-court mezzanine (+5 m) over the
##   security frames, then the concourse (one-way travelator, signs that disagree)
##   with the duty-free hall, the sunken Meeting Place and Concourse M (a seam returns
##   you 30 m back: it connects to itself), then Terminal C: gate C31 and its jet
##   bridge, the C32 camp, a lounge mezzanine (+4.2 m), restrooms, a fountain.
## SIGNATURE MECHANIC (stateful): one countdown drives every screen; gate C31's
##   doors open only while its flight boards (1000..0) and close at 0, when a new
##   flight takes the gate; PA calls boarding, delays and gate changes; luggage rides
##   the active belts and is rerouted to Lost and Found after 10 rounds.
## EXIT: L036>L036_1#1, walk through gate C31 while boarding (Sublevel 36.1, not
##   built: release boundary). ADAPTATION: the Support Group are out on one of their
##   group outings (the page lists them), so their camp is empty but their talk
##   carries; flight numbers other than C32's are generated.
## ABSENT: hostile entities, a real exit sign that works, clocks that tell time,
##   day/night, sleep, fixed destinations.

const Strip := preload("res://levels/L036/L036_strip.gd")
const Core := preload("res://levels/L036/L036_core.gd")
const Term := preload("res://levels/L036/L036_term.gd")
const Sys := preload("res://levels/L036/L036_sys.gd")
const Docs := preload("res://levels/L036/L036_docs.gd")
const SPAWN := Vector3(9.7, 0.3, 13.0)
const EXIT_ID := "L036>L036_1#1"

var strip
var core
var term
var sys
var world: ChunkWorld
var door_open := 0.0


func build() -> void:
	rules["flashlight"] = "none"
	rules["view_distance"] = 170.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.26
	var haze := Color(0.52, 0.54, 0.56)
	indoor_env(Color(0.82, 0.84, 0.88), 0.11, haze, 0.015)
	environment.background_color = haze
	environment.tonemap_exposure = 0.88
	environment.glow_intensity = 0.4
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.85
	environment.adjustment_contrast = 1.05
	Core.materials()
	lights.setup(16, 1)
	lights.max_distance = 42.0
	strip = Strip.new(self)
	var ks := kit("Centre")
	var kd := kit("CentreDetail")
	kd.shadows = false
	core = Core.new(self, ks, kd)
	var node := Node3D.new()
	node.name = "Authored"
	add_child(node)
	var r := RandomNumberGenerator.new()
	r.seed = 3636
	core.lost_and_found(node, r)
	core.bta_booth(node)
	core.mezzanine(node, r)
	core.concourse(node, r)
	core.duty_free(node, r)
	core.meeting_place(node)
	core.loop(node)
	term = Term.new(self, core)
	term.build(node, r)
	ks.commit()
	kd.commit()
	world = ChunkWorld.new()
	world.name = "Strips"
	world.chunk_size = Strip.CS
	world.radius = 3
	world.unload_radius = 4
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	world.build_around(SPAWN, 3)
	sys = Sys.new()
	sys.name = "AirportSystems"
	add_child(sys)
	sys.setup(self, level_seed)
	var luggage := Node3D.new()
	luggage.name = "Luggage"
	add_child(luggage)
	sys.spawn_bags(luggage)
	sys.make_ghosts(node)
	Docs.lights(self)
	Docs.sounds(self)
	Docs.notes(self)
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L011", SPAWN, 0.0)
	add_arrival("from_L009", Vector3(25.7, 0.3, 13.0), 0.0)
	add_arrival("from_L011_2", Vector3(-22.3, 0.3, 13.0), 0.0)
	var ex := add_exit(EXIT_ID, "walk_in", Vector3(0, 1.3, Term.GATE_DOOR.z - 1.2), Vector3(3.0, 2.6, 1.6), "Board the flight at gate C31")
	if ex:
		ex.condition = func() -> bool: return sys.boarding()
	_door(1.0 if sys.boarding() else 0.0)
	refresh_screens()
	add_landmark("Baggage carousel #9", Vector3(8, 0, 8))
	add_landmark("Check-in counters", Vector3(0, 0, -26))
	add_landmark("BTA booth 0", Vector3(-9, 0, -15.5))
	add_landmark("Concourse and travelator", Vector3(0, 0, -75))
	add_landmark("Gate C31", Term.GATE_DOOR)
	add_landmark("Gate C32 Support Group camp", Term.C32_CAMP)
	Docs.shots(self)


func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if cz != 0:
		return {}
	return strip.build_chunk(cx, node)


func _on_unload(k: Vector2i) -> void:
	if k.y != 0:
		return
	lights.remove_group("c%d" % k.x)
	strip.screens = strip.screens.filter(func(s): return is_instance_valid(s) and not (s as Node).is_queued_for_deletion() and not (s as Node).get_parent().is_queued_for_deletion())


func refresh_screens() -> void:
	var small: String = sys.board_text(5)
	for s in strip.screens:
		if is_instance_valid(s):
			(s as Label3D).text = small
	if term.board:
		term.board.text = sys.board_text(14)
	var f: Dictionary = sys.ours()
	if term.gate_label and not f.is_empty():
		term.gate_label.text = "FLIGHT %s\n%s   %d\nDESTINATION: NOT ANNOUNCED" % [f["num"], sys.status(f), int(f["cd"])]


## Gate C31's glass leaves: open (1) while boarding, shut (0) otherwise.
func _door(v: float) -> void:
	door_open = v
	for i in term.leaves.size():
		var sx := -1.0 if i == 0 else 1.0
		(term.leaves[i] as Node3D).position.x = sx * (0.75 + 1.45 * v)
	term.door_body.collision_layer = 0 if v > 0.5 else 1


func on_player_ready() -> void:
	world.target = player
	if not SessionState.is_qa():
		Overlay.subtitle("[a conveyor belt carries you out through rubber flaps, into baggage claim]", 4.0)


func level_process(delta: float) -> void:
	var want := 1.0 if sys.boarding() else 0.0
	if absf(door_open - want) > 0.001:
		_door(move_toward(door_open, want, delta * 0.8))


func qa_self_test() -> Array:
	return await Docs.self_test(self)
