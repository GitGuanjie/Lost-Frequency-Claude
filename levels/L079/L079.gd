extends LevelBase
## Level 79 "Ghosts in the Machine" (Backrooms Wikidot rev 24, accessed 2026-11-04; DrAkimoto,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L079.md.
##
## PLAN (read -> design):
## - SOURCE: seven rooms of intelligent design diverge from one main corridor, alternating
##   right/left (1R 2L 3R 4L 5R 6L), the seventh central at the end; ~370 m2; a mid-20th-
##   century medical research clinic with signs of previous human occupation.
##   -> one authored, compact clinic (no streaming, no extra hallways): a 24 m linoleum
##   corridor with staggered doors, six rooms of 30-48 m2 and a taller machine hall.
## - SOURCE room contents, exactly as listed: 1 office (fire-damaged desk, filing cabinets,
##   shelving shoved into a closet; Dr. Zohn's yellow-chalk note), 2 equipment storage (six
##   named machines plus four advanced machines of unknown purpose), 3 examination (wall-
##   embedded machine with corrugated hoses, IV lines and wires; locked medicine cabinet),
##   4 X-ray (mid-century machine, negatoscope with one child's arm film), 5 living quarters
##   (six twin mattresses on wire frames, two dressers, red handball, black crayons, paper),
##   6 operating theatre (empty, slurry of fluids with screws and shavings), 7 the machine
##   (16 clocks, each a different time; electrically distorted sobbing; leaking left side).
## - Verticality: the page gives none. Natural variation only: the operating theatre is a
##   sunken well under a viewing landing (4 steps), the machine hall lies 5 steps below the
##   corridor with a taller ceiling. ADAPTATION, no rooms added.
## - Stateful mechanic (TESTIMONY, two accounts): about every 30 minutes the machine knocks,
##   a tremor passes through the level and you feel something like no-clipping.
##   ADAPTATION: one cycle per ~150 s of play; each cycle advances a displacement counter,
##   jumps the corridor clock, and the leak from the machine's left side keeps spreading.
## - Exit: the only entrance/exit is the door at the start of the main corridor; its
##   destination and date are not stated (Inconsistent Exit) -> EXT release boundary, and
##   the log sheet by the door records the two first-hand entry/exit dates.
## - Lighting is not stated by the page. ADAPTATION: most ceiling fixtures dead, a few weak
##   ones, the negatoscope and the clock faces glowing faintly; the flashlight carries it.
## - ABSENT: entities of any kind (warning says only "Unknown Potential"), combat, a named
##   destination, Level 78.

const Rooms := preload("res://levels/L079/L079_clinic.gd")
const PERIOD := 150.0
const MACHINE := Vector3(0.0, -0.9, -32.6)

var R
var clocks: Array = []          # [{min: Node3D, hour: Node3D, rate: float}]
var corridor_clock: Dictionary = {}
var leak: MeshInstance3D
var leak_size := 0.9
var displacement := 0
var tremor := 0.0
var cycle_t := 0.0
var knocks := 0
var _sob: AudioStreamPlayer3D
var _sob2: AudioStreamPlayer3D
var _said := {}
var _entry_date := ""


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 60.0
	rules["reverb_room"] = 0.32
	rules["reverb_wet"] = 0.2
	indoor_env(Color(0.62, 0.64, 0.6), 0.055, Color(0.0, 0.0, 0.0), 0.025)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.72
	environment.adjustment_contrast = 1.08
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 0.9
	Rooms.materials()
	var k := kit("Clinic")
	var d := kit("Dressing")
	d.shadows = true
	R = Rooms.new(self, k, d)
	R.shell()
	R.office()
	R.storage()
	R.exam()
	R.xray()
	R.quarters()
	R.theatre()
	R.corridor_dressing()
	clocks = R.machine(MACHINE)
	corridor_clock = R.corridor_clock(Vector3(1.4, 2.25, -9.0))
	leak = R.leak_patch(MACHINE + Vector3(-2.9, 0.012, 0.9))
	k.commit()
	d.commit()
	_lights()
	_sounds()
	_notes()
	cycle_t = PERIOD * (0.45 + 0.2 * rng.randf())
	add_arrival("start", Vector3(0.0, 0.02, -3.2), 0.0)
	var ex := add_exit("L079>EXT#1", "interact", Vector3(0.0, 1.05, -0.75), Vector3(1.8, 2.1, 1.3),
		"Open the door you came in by (where, and when, it opens is not stated)")
	if ex:
		ex.fired.connect(_on_exit_used)
	add_landmark("Main corridor", Vector3(0, 0, -12))
	add_landmark("Chalkboard (Room 1)", Vector3(6.9, 1.6, -3.6))
	add_landmark("Operating theatre (Room 6)", Vector3(-4.6, -0.72, -20.4))
	add_landmark("The machine (Room 7)", MACHINE)
	_shots()


func _lights() -> void:
	lights.setup(6, 1)
	lights.max_distance = 26.0
	var warm := Color(1.0, 0.93, 0.8)
	# corridor: five fixtures, two alive, one stuttering
	lights.add_anchor(Vector3(0, 2.7, -4.5), warm, 0.55, 6.5, 0.0)
	lights.add_anchor(Vector3(0, 2.7, -15.5), warm, 0.4, 6.0, 0.7)
	# Room 1 office: a single weak lamp over the scorched desk
	lights.add_anchor(Vector3(4.6, 2.6, -3.0), warm, 0.32, 5.0, 0.0)
	# Room 3 examination: one fixture still on
	lights.add_anchor(Vector3(4.4, 2.6, -11.6), Color(0.95, 0.98, 1.0), 0.45, 5.5, 0.15)
	# Room 4: the negatoscope's cold box light
	lights.add_anchor(Vector3(-6.6, 1.6, -13.2), Color(0.8, 0.9, 1.0), 0.55, 4.5, 0.0)
	# Room 6: a surgical lamp at a fraction of its power
	lights.add_anchor(Vector3(-4.6, 1.9, -20.4), Color(0.95, 1.0, 0.95), 0.35, 5.0, 0.3)
	# Room 7: the clock faces and one amber lamp high on the wall
	lights.add_anchor(MACHINE + Vector3(0, 2.4, 2.6), Color(1.0, 0.78, 0.5), 0.7, 7.5, 0.0)
	lights.add_anchor(Vector3(4.6, 3.2, -26.0), Color(1.0, 0.85, 0.6), 0.3, 6.0, 0.4)


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 180.0, "rumble": 0.35, "seconds": 7.0}, -30.0)
	sound.emitter("fluorescent_hum", Vector3(0, 2.8, -4.5), {"base": 120.0, "rasp": 0.2, "seconds": 3.0}, -30.0, 7.0)
	sound.emitter("fluorescent_hum", Vector3(4.4, 2.7, -11.6), {"base": 100.0, "rasp": 0.3, "seconds": 3.0}, -32.0, 6.0)
	# The machine: an electrically distorted sound like sobbing (both first-hand accounts).
	_sob = sound.emitter("whisper", MACHINE + Vector3(0, 1.6, 0.9), {"seconds": 2.4}, -12.0, 34.0)
	_sob2 = sound.emitter("static", MACHINE + Vector3(0.6, 1.2, 0.9), {"seconds": 3.0}, -26.0, 20.0)
	sound.emitter("pad", MACHINE + Vector3(0, 1.0, 0.9), {"root": 46.0, "chord": [0, 1, 6], "bright": 0.05, "seconds": 9.0}, -22.0, 30.0)
	sound.emitter("drip", MACHINE + Vector3(-2.6, 0.3, 0.9), {"freq": 420.0}, -24.0, 9.0)
	sound.oneshot("creak", {"freq": 70.0}, 22.0, 48.0, 10.0, "[the building settles]", -24.0)


func _notes() -> void:
	add_note("l79_chalk", "Chalkboard, Room 1 (yellow chalk)",
		"Written in yellow chalk, signed Dr. Zohn:\n\n\"The experiments were only somewhat successful; don't stay here long. We're going to move to Phase 2 anyway, I'll meet you then.\"\n\n(Level 79 page, Room 1.)",
		Vector3(6.75, 1.25, -3.6), Vector3(0.5, 1.6, 2.6), false)
	add_note("l79_log", "Log sheet on the bench by the door",
		"Two first-hand accounts, as logged:\nM. Akimoto - entered 4/10/2021, left 4/10/2023, three hours inside.\nM. Grey - entered 8/23/2024, left 7/23/1992, nine and a half hours inside.\n\nThe file's warning: if you have only just come in, turn back. Long stays may displace you in space, in time, or both.",
		Vector3(-1.05, 0.62, -2.0), Vector3(0.6, 0.3, 0.6))
	add_note("l79_storage", "Equipment storage, Room 2",
		"A cardiopulmonary monitor, a kidney dialysis machine, a sonograph, an ECG machine, a mechanical ventilator and a fixed-angle centrifuge.\n\nAnd four machines nobody has identified. They look far more advanced than everything else in the room.",
		Vector3(-4.3, 1.0, -6.0), Vector3(1.2, 1.6, 1.2), false)
	add_note("l79_cabinet", "Locked cabinet, Room 3",
		"Through the glass you can read the labels: Almond Water, pethidine, azathioprine, LSD, doxorubicin, Seer powder, scopolamine, and a jar of multicoloured lollipops laced with melatonin. The cabinet is locked.",
		Vector3(4.05, 1.5, -14.55), Vector3(1.4, 1.4, 0.6), false)
	add_note("l79_film", "Radiograph on the negatoscope, Room 4",
		"A single film is still clipped to the illuminator: a human arm, badly deformed. From the bones of the hand, the person was between six and ten years old.",
		Vector3(-6.75, 1.55, -13.2), Vector3(0.4, 1.0, 1.6), false)
	add_note("l79_dresser", "Dresser drawers, Room 5",
		"Six sets of plain grey shirts and trousers, size youth small. A red rubber handball. Three black crayons. Fourteen sheets of lined paper, all blank.",
		Vector3(3.7, 0.9, -15.8), Vector3(2.4, 1.2, 0.6), false)
	add_note("l79_theatre", "Operating theatre, Room 6",
		"The room is empty except for what has built up on the floor: viscera and fluids that are not all identified, with metal shavings and screws through it. Analysis found the DNA of six separate people.",
		Vector3(-2.3, 0.9, -20.4), Vector3(0.9, 1.4, 2.6), false)
	add_interactable(MACHINE + Vector3(0, 1.4, 1.45), Vector3(4.6, 2.6, 0.8), "Look at the clocks", _read_clocks)


func _read_clocks(_p: Player) -> void:
	var times: Array = []
	for c in clocks:
		times.append(_clock_text(c))
	Overlay.show_note("The machine, Room 7",
		"Sixteen clocks on its face, each showing a different time:\n\n" + "   ".join(times.slice(0, 8)) + "\n" + "   ".join(times.slice(8, 16)) +
		"\n\nNobody knows what it is made of or what it does. Something like the slurry in Room 6 seeps slowly from its left side.")


func _clock_text(c: Dictionary) -> String:
	var h_deg := fposmod(-rad_to_deg((c["hour"] as Node3D).rotation.z), 360.0)
	var m_deg := fposmod(-rad_to_deg((c["min"] as Node3D).rotation.z), 360.0)
	var hh := int(floor(h_deg / 30.0))
	var mm := int(floor(m_deg / 6.0))
	return "%d:%02d" % [12 if hh == 0 else hh, mm]


func _on_exit_used(_e: String) -> void:
	if SessionState.is_qa():
		return
	var y := 1990 + int(rng.randi() % 40)
	Overlay.toast("The door opens somewhere. Your watch and the date outside disagree (%d tremor%s felt; the calendar there reads %d)." % [knocks, "" if knocks == 1 else "s", y], 6.0)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[from the end of the corridor: an electrical sound, like someone sobbing]", 4.0)


func level_process(delta: float) -> void:
	# clocks keep their own, different, time; some run backwards
	for c in clocks:
		(c["min"] as Node3D).rotation.z -= delta * float(c["rate"])
		(c["hour"] as Node3D).rotation.z -= delta * float(c["rate"]) / 12.0
	if not corridor_clock.is_empty():
		(corridor_clock["min"] as Node3D).rotation.z -= delta * TAU / 3600.0
		(corridor_clock["hour"] as Node3D).rotation.z -= delta * TAU / 43200.0
	# the leak spreads (never past the hall's width)
	leak_size = minf(leak_size + delta * 0.0025, 2.2)
	if leak:
		leak.scale = Vector3(leak_size, 1.0, leak_size * 0.8)
	cycle_t -= delta
	if cycle_t <= 0.0:
		knock()
	if tremor > 0.0:
		tremor = maxf(0.0, tremor - delta)
		if player and player.camera:
			var a := tremor * 0.035
			player.camera.h_offset = randf_range(-a, a)
			player.camera.v_offset = randf_range(-a, a)
			if tremor == 0.0:
				player.camera.h_offset = 0.0
				player.camera.v_offset = 0.0
	if player and not _said.has("hall") and player.global_position.z < -25.5:
		_said["hall"] = true
		if not SessionState.is_qa():
			Overlay.subtitle("[the sobbing is coming from the machine itself]", 3.5)


## The machine's cycle (TESTIMONY): a loud knock, a tremor felt throughout the level,
## then a sensation like no-clipping.
func knock() -> void:
	cycle_t = PERIOD * (0.9 + 0.2 * rng.randf())
	knocks += 1
	displacement += 1
	tremor = 2.6
	sound.play_at("knock", {"hits": 3}, MACHINE + Vector3(0, 1.4, 0.8), 4.0, "[a loud knocking from the machine]")
	sound.play_at("distant_boom", {}, MACHINE + Vector3(0, 0.5, 2.0), -2.0)
	Overlay.glitch(0.85)
	if not SessionState.is_qa():
		Overlay.subtitle("[a tremor runs through the floor; for a moment you feel yourself slipping through it]", 3.5)
	# the corridor clock is no longer where it was
	if not corridor_clock.is_empty():
		(corridor_clock["min"] as Node3D).rotation.z = -rng.randf() * TAU
		(corridor_clock["hour"] as Node3D).rotation.z = -rng.randf() * TAU
	if player and player.global_position.distance_to(MACHINE) < 6.0:
		player.velocity += Vector3(rng.randf_range(-1.0, 1.0), 0.6, rng.randf_range(-1.0, 1.0))


func _shots() -> void:
	add_shot("corridor", Vector3(0.35, 1.6, -1.6), Vector3(0.0, 1.0, -26.0), {"flashlight": true})
	add_shot("machine", Vector3(2.1, 0.75, -27.9), MACHINE + Vector3(-0.5, 1.5, 0), {"flashlight": true})
	add_shot("office", Vector3(2.2, 1.6, -6.6), Vector3(5.6, 0.7, -1.6), {"flashlight": true})
	add_shot("theatre", Vector3(-2.2, 1.55, -17.6), Vector3(-5.4, -0.6, -21.6), {"flashlight": true})
	add_shot("xray", Vector3(-2.2, 1.55, -10.4), Vector3(-5.6, 1.2, -14.0), {"flashlight": true})
	add_shot("quarters", Vector3(2.3, 1.6, -16.6), Vector3(6.6, 0.4, -22.8), {"flashlight": true})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var times := {}
	for c in clocks:
		times[_clock_text(c)] = true
	out.append({"what": "the machine shows 16 clocks, each a different time", "ok": clocks.size() == 16 and times.size() == 16, "detail": times.keys()})
	var before := displacement
	knock()
	out.append({"what": "the knock cycle starts a tremor and advances displacement", "ok": tremor > 0.0 and displacement == before + 1})
	var l0 := leak_size
	level_process(10.0)
	out.append({"what": "the leak from the machine spreads over time", "ok": leak_size > l0})
	return out
