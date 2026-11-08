extends LevelBase
## Level 31 "The Roller Rink" (Backrooms Wikidot rev 16, accessed 2026-11-04; DrJTC and
## SkullDoggery, CC BY-SA 3.0). Dossier: docs/canon/levels/L031.md.
## Content note: the page's diary ends with a wanderer's apathy and death by
## dehydration. Shown only through notes; nothing graphic, no body.
##
## PLAN (v2.0 rebuild: read -> design)
## - SOURCE: an infinitely looping roller rink; the rink is the largest part and where
##   most arrive. Smooth wooden floor in a loop, a short wooden gate with flaps onto rough
##   black carpet, many colourful fluorescent tubes in patterns and a star-shaped fixture
##   at the centre, usually dimmed; muffled radio pop, skates on wood, laughter; the DJ
##   station on the south side with a docile Faceling who sometimes picks the songs.
##   -> a 56 x 32 m hall with a 34 x 18 m maple oval (the loop: a Faceling skates it
##   forever), rail and flap gates, carpet concourse, neon rings, the star (+5.7 m), and
##   a raised DJ booth (+1.08 m, stair). The loop is the oval, not a huge building.
## - SOURCE: the arcade east of the rink loops back round to its north entrance; free
##   games with a green card from a metal box at the entrance (big blue button, card
##   catcher); Ski-Ball, big game wheels, air hockey, pinball, a few 1980s cabinets.
##   No-clipping into any working game -> Level 40 (exit 1, the walker's target).
## - TESTIMONY (diary): a back area of the arcade, machines off or under cloth, and the
##   white door engraved 70 -> a sunken back room (-0.72 m, four steps) (exit 2, SOURCE).
## - SOURCE: small food court: free pizza, wings, foot-long hot dogs, soda and almond
##   water from a Faceling clerk with a blank name tag who will not talk about the
##   Backrooms; square tables, orange plastic chairs, orange/green benches by the walls,
##   condiment stand, trash cans and a taped sign by the exit. Leave food or trash and
##   the clerk cleans it up and refuses you free food (stateful). "Employees only!" door
##   -> Level 232 (exit 3; the diary's claim that nobody returns is TESTIMONY only).
## - SOURCE: blue-walled skate rental with a US size chart, run by the Coach (striped
##   uniform, brown hair, faceless): free lessons (skates make you fast on the maple),
##   small talk, leads you out if asked, and does so unprompted after a prolonged stay.
##   He leads you to the white door (the diary shows him doing exactly that).
## - SOURCE: the Cinema north past TV screens: a large television and three continuous
##   metal benches stepped like stairs; leave by walking south.
## - Signature mechanic (stateful): comfort decays. The longer you stay, the colour drains,
##   the same song repeats a little flatter, laughter thins out, and the Coach comes
##   looking for you to talk about not staying too long.
## - ABSENT: hostile entities, permanent communities (a Venosha camp is temporary),
##   Jonathan (a past incident, notes only), a Coach exit with its own destination.

const Rink := preload("res://levels/L031/L031_rink.gd")
const Arcade := preload("res://levels/L031/L031_arcade.gd")
const START := Vector3(-26.4, 0.0, 2.0)
const COACH_POST := Vector3(-5.0, 0.0, -21.6)
const FADE_FROM := 150.0
const FADE_SPAN := 450.0
const SEEK_AT := 330.0
const LEAD_AT := 720.0
const NODES := [Vector3(-5, 0, -21.6), Vector3(-5, 0, -14.5), Vector3(14, 0, -12.6), Vector3(22, 0, -1), Vector3(30.5, 0, 0),
	Vector3(31.5, 0, -28.5), Vector3(49, 0, -28.5), Vector3(49, 0, -16), Vector3(55, 0, -16), Vector3(60, -0.72, -16),
	Vector3(64.6, -0.72, -16), Vector3(14, 0, -22), Vector3(29.5, 0, -27), Vector3(24, 0, -21.6), Vector3(-24, 0, -14),
	Vector3(-24, 0, -42), Vector3(-24, 0, -46), Vector3(31.5, 0, 6), Vector3(-18, 0, -12), Vector3(-22, 0, 6),
	Vector3(0, 0, -12.4), Vector3(0, 0, 10.4), Vector3(20, 0, 11), Vector3(-20, 0, 11), Vector3(-5, 0, -10.4),
	Vector3(5, 0, -10.4), Vector3(-6, 0, 10.4), Vector3(41, 0, 8), Vector3(49.5, 0, 6)]
const EDGES := [[0, 1], [1, 20], [1, 18], [20, 2], [2, 11], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 8], [8, 9], [9, 10],
	[11, 13], [13, 12], [12, 5], [18, 14], [14, 15], [15, 16], [18, 19], [19, 23], [23, 21], [21, 22], [22, 3],
	[24, 20], [25, 20], [26, 21], [26, 23], [4, 17], [17, 27], [27, 28], [28, 7]]
const DOOR_NODE := 10
const TALK := ["\"How are you holding up? Eaten anything today?\"",
	"\"The food court's free. Just clean up after yourself; the cook remembers who doesn't.\"",
	"\"Card box at the arcade entrance. Press the blue button and every game's free.\"",
	"\"Cinema's up north, past the TVs. Quiet in there. When you're done, just walk south.\"",
	"\"Want to try a new move? Spins. Knees soft, weight forward.\"",
	"\"I never forget a name. People pass through here and I remember every one of them.\""]

var R
var A
var qa_fixture := false
var props: Node3D
var stay := 0.0
var card := false
var skates := false
var tray := false
var littered := false
var meals := 0
var plays := 0
var talk_i := 0
var advised := false
var _said := {}
var coach: Node3D
var coach_state := "post"
var coach_path: Array = []
var coach_talk: Interactable
var coach_lead: Interactable
var clerk: Node3D
var dj: Node3D
var skater: Node3D
var skater_t := 0.0
var skater2: Node3D
var wheel_speed := 0.0
var music: AudioStreamPlayer
var dj_music: AudioStreamPlayer3D
var crowd: AudioStreamPlayer
var song := 0
var _dj_t := 50.0
var _skate_t := 0.0
var _laugh_t := 20.0
var _litter_node: Node3D
var _clean_t := -1.0
var _movie_light: OmniLight3D
var _tables: Array = []
var _songs := [{"bpm": 116.0, "root": 196.0, "scale": [0, 2, 4, 7, 9, 12, 14]}, {"bpm": 124.0, "root": 220.0, "scale": [0, 2, 4, 5, 7, 9, 12]},
	{"bpm": 104.0, "root": 174.6, "scale": [0, 3, 5, 7, 10, 12]}]


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 140.0
	rules["reverb_room"] = 0.6
	rules["reverb_wet"] = 0.16
	indoor_env(Color(0.55, 0.42, 0.85), 0.07, Color(0.025, 0.015, 0.05), 0.006)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.15
	environment.adjustment_contrast = 1.06
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.9
	Rink.materials()
	props = Node3D.new()
	props.name = "Dressing"
	add_child(props)
	R = Rink.new(self, props)
	R.hall()
	R.rental()
	var tvs: Array = R.corridor_and_cinema()
	_tables = R.food_court()["tables"]
	A = Arcade.new(self, props)
	A.build()
	_people()
	_lights(tvs)
	_sounds()
	_exits()
	_interactions()
	_notes()
	add_arrival("start", START, -90.0)
	add_arrival("from_L002", START, -90.0)
	add_arrival("from_L003", START, -90.0)
	add_arrival("from_L201", Vector3(-14.0, 0.0, -12.8), -135.0)
	add_landmark("Maple rink oval and the star fixture", Vector3(0, 0, 0))
	add_landmark("DJ station, south side", Vector3(0, 1.08, 13.5))
	add_landmark("Arcade and green card dispenser", A.dispenser)
	add_landmark("Food court", Vector3(14, 0, -24))
	add_landmark("Skate rental (blue walls) and the Coach", COACH_POST)
	add_landmark("Cinema", Vector3(-24, 0, -50))
	add_landmark("White door 70, back of the arcade", A.white_door)
	add_shot("rink", Vector3(14.5, 3.3, 13.4), Vector3(-5.0, 0.8, -5.0), {"flashlight": false})
	add_shot("arcade", Vector3(31.0, 1.6, -31.2), Vector3(33.0, 1.2, -6.0), {"flashlight": false})
	add_shot("food_court", Vector3(26.4, 1.7, -17.2), Vector3(11.0, 0.9, -30.0), {"flashlight": false})
	add_shot("cinema", Vector3(-17.2, 1.75, -45.2), Vector3(-25.5, 0.6, -59.0), {"flashlight": false})
	add_shot("white_door", Vector3(55.8, 1.3, -18.6), Vector3(65.8, 0.5, -15.6), {"flashlight": false})
	add_shot("rental", Vector3(1.2, 1.7, -17.0), Vector3(-9.0, 1.0, -29.0), {"flashlight": false})


# ---------------------------------------------------------------- people

func _skin() -> StandardMaterial3D:
	return MatLib.standard(Color(0.80, 0.72, 0.64), 0.55)


## A docile Faceling: a person-shaped figure with a smooth, featureless face.
func _figure(pos: Vector3, yaw: float, kind: String, sit := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Faceling_" + kind
	root.position = pos
	root.rotation.y = deg_to_rad(yaw)
	add_child(root)
	var cols := {"coach": [Color(0.12, 0.12, 0.16), Color(0.92, 0.92, 0.9)], "clerk": [Color(0.15, 0.15, 0.18), Color(0.72, 0.08, 0.06)],
		"dj": [Color(0.1, 0.1, 0.12), Color(0.2, 0.2, 0.25)], "a": [Color(0.18, 0.22, 0.4), Color(0.55, 0.18, 0.5)],
		"b": [Color(0.3, 0.26, 0.2), Color(0.15, 0.45, 0.42)], "c": [Color(0.12, 0.12, 0.14), Color(0.8, 0.6, 0.15)]}
	var c: Array = cols.get(kind, cols["a"])
	var pants := MatLib.standard(c[0], 0.8)
	var shirt := MatLib.standard(c[1], 0.75)
	var hip := 0.45 if sit else 0.9
	for x in [-0.11, 0.11]:
		if sit:
			var thigh := _part(root, "capsule", Vector3(x, 0.48, -0.2), Vector3(0.14, 0.5, 0.14), pants)
			thigh.rotation.x = PI * 0.5
			_part(root, "capsule", Vector3(x, 0.24, -0.42), Vector3(0.12, 0.48, 0.12), pants)
		else:
			_part(root, "capsule", Vector3(x, 0.46, 0), Vector3(0.14, 0.92, 0.14), pants)
	_part(root, "capsule", Vector3(0, hip + 0.33, 0), Vector3(0.42, 0.72, 0.26), shirt)
	for s in [-1.0, 1.0]:
		var arm := _part(root, "capsule", Vector3(s * 0.27, hip + 0.22, 0), Vector3(0.1, 0.68, 0.1), shirt)
		arm.rotation.z = s * 0.1
	var head := _part(root, "sphere", Vector3(0, hip + 0.83, 0), Vector3(0.22, 0.27, 0.23), _skin())
	head.name = "Head"
	if kind == "coach":
		# striped coach's uniform, brown hair, a whistle, a name tag
		var black := MatLib.standard(Color(0.04, 0.04, 0.05), 0.7)
		for i in 5:
			var sx := -0.16 + i * 0.08
			_part(root, "box", Vector3(sx, hip + 0.33, -0.125), Vector3(0.025, 0.6, 0.02), black)
			_part(root, "box", Vector3(sx, hip + 0.33, 0.125), Vector3(0.025, 0.6, 0.02), black)
		_part(root, "sphere", Vector3(0, hip + 0.92, 0.02), Vector3(0.24, 0.16, 0.25), MatLib.standard(Color(0.25, 0.14, 0.07), 0.9))
		_part(root, "cyl", Vector3(0.05, hip + 0.42, -0.14), Vector3(0.015, 0.05, 0.015), MatLib.standard(Color(0.8, 0.8, 0.82), 0.2, 0.9))
		_part(root, "box", Vector3(-0.1, hip + 0.52, -0.135), Vector3(0.1, 0.04, 0.005), MatLib.standard(Color(0.95, 0.95, 0.9), 0.6))
	elif kind == "clerk":
		_part(root, "box", Vector3(0, hip + 0.15, -0.135), Vector3(0.36, 0.5, 0.02), MatLib.standard(Color(0.9, 0.9, 0.86), 0.8))
		_part(root, "box", Vector3(-0.1, hip + 0.5, -0.135), Vector3(0.1, 0.04, 0.005), MatLib.standard(Color(0.98, 0.98, 0.96), 0.6))
		_part(root, "box", Vector3(0, hip + 0.96, -0.08), Vector3(0.26, 0.04, 0.2), MatLib.standard(Color(0.72, 0.08, 0.06), 0.6))
	elif kind == "dj":
		var hp := MatLib.standard(Color(0.05, 0.05, 0.05), 0.4)
		for s in [-1.0, 1.0]:
			var cup := _part(root, "cyl", Vector3(s * 0.12, hip + 0.83, 0), Vector3(0.06, 0.05, 0.06), hp)
			cup.rotation.z = PI * 0.5
		_part(root, "box", Vector3(0, hip + 0.98, 0), Vector3(0.26, 0.025, 0.04), hp)
	return root


func _part(root: Node3D, mesh_type: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m: Mesh
	if mesh_type == "capsule":
		var cm := CapsuleMesh.new()
		cm.radius = size.x * 0.5
		cm.height = size.y
		cm.radial_segments = 10
		cm.rings = 4
		m = cm
	elif mesh_type == "sphere":
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 14
		sm.rings = 7
		m = sm
		mi.scale = size
	elif mesh_type == "cyl":
		var cy := CylinderMesh.new()
		cy.top_radius = size.x
		cy.bottom_radius = size.x
		cy.height = size.y
		cy.radial_segments = 10
		m = cy
	else:
		var bx := BoxMesh.new()
		bx.size = size
		m = bx
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


func _people() -> void:
	coach = _figure(COACH_POST, 180.0, "coach")
	coach_talk = make_interactable(Vector3(0, 1.45, 0), Vector3(0.6, 0.7, 0.5), "Talk to the Coach", _talk_coach, coach)
	coach_lead = make_interactable(Vector3(0, 0.6, 0), Vector3(0.6, 0.9, 0.5), "Ask the Coach to lead you out", _ask_lead, coach)
	clerk = _figure(Vector3(13.5, 0, -30.3), 180.0, "clerk")
	make_interactable(Vector3(0, 1.72, 0), Vector3(0.4, 0.4, 0.4), "Ask the clerk about the Backrooms", _ask_clerk, clerk)
	dj = _figure(Vector3(0.3, 1.08, 13.1), 0.0, "dj")
	dj.visible = true
	skater = _figure(Rink.oval_point(0.0, 6.2), 0.0, "a")
	skater2 = _figure(Rink.oval_point(0.5, 4.4), 0.0, "c")
	_figure(Vector3(47.75, 0, -10.9), 90.0, "b")
	_figure(Vector3(-27.0, 0.02, -47.3), 0.0, "c", true)
	_figure(Vector3(16.8, 0.0, -20.0), 90.0, "b", true)


# ---------------------------------------------------------------- light & sound

func _lights(tvs: Array) -> void:
	lights.setup(10, 1)
	var cols := [Color(1.0, 0.3, 0.7), Color(0.3, 0.8, 1.0), Color(0.6, 0.35, 1.0), Color(1.0, 0.8, 0.35)]
	for i in 8:
		var q := Rink.oval_point(float(i) / 8.0 + 0.06, 7.0)
		lights.add_anchor(q + Vector3(0, 5.4, 0), cols[i % 4], 1.4, 10.0, 0.0, "rink")
	var star_l := OmniLight3D.new()
	star_l.name = "StarLight"
	star_l.position = Vector3(0, 5.0, 0)
	star_l.light_color = Color(1.0, 0.86, 0.6)
	star_l.light_energy = 2.2
	star_l.omni_range = 13.0
	star_l.omni_attenuation = 1.1
	add_child(star_l)
	lights.add_anchor(Vector3(0, 3.2, 13.6), Color(1.0, 0.35, 0.75), 1.1, 5.5, 0.0, "dj")
	for c in [Vector3(-22, 4, -10), Vector3(-22, 4, 10), Vector3(22, 4, 10), Vector3(22, 4, -10)]:
		lights.add_anchor(c, cols[int(absf(c.x + c.z)) % 4], 0.9, 9.0, 0.0, "concourse")
	for c in [Vector3(-9.5, 2.9, -20), Vector3(-3, 2.9, -26.5), Vector3(-9, 2.9, -26.5)]:
		lights.add_anchor(c, Color(0.85, 0.92, 1.0), 1.4, 8.0, 0.0, "rental")
	for c in [Vector3(8, 3.3, -20), Vector3(20, 3.3, -20), Vector3(14, 3.3, -30), Vector3(25, 3.3, -30)]:
		lights.add_anchor(c, Color(1.0, 0.93, 0.8), 1.1, 8.0, 0.0, "food")
	for c in [Vector3(32, 3.4, -28), Vector3(32, 3.4, -12), Vector3(32, 3.4, 5), Vector3(41, 3.4, -30), Vector3(41, 3.4, 8),
			Vector3(50, 3.4, -24), Vector3(50, 3.4, -7), Vector3(50, 3.4, 6)]:
		lights.add_anchor(c, cols[int(absf(c.x * 2.0 + c.z)) % 4], 0.9, 8.0, 0.0, "arcade")
	lights.add_anchor(Vector3(60, 1.45, -16), Color(1.0, 0.75, 0.45), 1.5, 8.0, 0.2, "back")
	lights.add_anchor(Vector3(64.3, 1.7, -15.2), Color(1.0, 0.8, 0.55), 0.7, 4.0, 0.0, "back")
	for i in range(0, tvs.size(), 4):
		lights.add_anchor(tvs[i], Color(0.6, 0.7, 1.0), 0.35, 4.0, 0.2, "tv")
	for z in [-57.0, -47.0]:
		lights.add_anchor(Vector3(-15.0, 2.2, z), Color(1.0, 0.8, 0.55), 0.6, 6.0, 0.0, "cinema")
		lights.add_anchor(Vector3(-33.0, 2.2, z), Color(1.0, 0.8, 0.55), 0.6, 6.0, 0.0, "cinema")
	_movie_light = OmniLight3D.new()
	_movie_light.name = "MovieLight"
	_movie_light.position = Vector3(-24.0, 2.4, -55.0)
	_movie_light.light_color = Color(0.9, 0.78, 0.65)
	_movie_light.light_energy = 1.8
	_movie_light.omni_range = 15.0
	_movie_light.omni_attenuation = 0.8
	add_child(_movie_light)


func _sounds() -> void:
	music = sound.bed("chiptune", _songs[0], -21.0)
	dj_music = sound.emitter("chiptune", Vector3(0, 2.2, 13.0), _songs[0], -9.0, 30.0)
	crowd = sound.bed("whisper", {"seconds": 4.0}, -30.0)
	sound.bed("room_tone", {"cutoff": 300.0, "rumble": 0.2, "seconds": 6.0}, -30.0)
	sound.emitter("chiptune", Vector3(41, 1.5, -11), {"bpm": 168.0, "root": 440.0, "scale": [0, 4, 7, 12, 16]}, -17.0, 20.0)
	sound.emitter("crackle", Vector3(12, 1.0, -33), {"seconds": 3.0}, -24.0, 9.0)
	sound.emitter("fluorescent_hum", Vector3(14, 3.4, -24), {"base": 120.0, "seconds": 3.0}, -30.0, 12.0)
	sound.emitter("fluorescent_hum", Vector3(-5, 3.0, -24), {"base": 100.0, "seconds": 3.0}, -32.0, 9.0)
	sound.emitter("pad", Vector3(-24, 2.0, -58), {"root": 130.8, "chord": [0, 4, 7, 11], "bright": 0.3, "seconds": 9.0}, -18.0, 16.0)
	sound.emitter("room_tone", Vector3(60, 1.0, -16), {"cutoff": 140.0, "rumble": 0.4, "seconds": 5.0}, -22.0, 8.0)


# ---------------------------------------------------------------- exits & interaction

func _exits() -> void:
	# Exit 1 first (QA walker target): no-clip into any working arcade game -> Level 40.
	for nc in A.noclip_cabs:
		var t := add_exit("L031>L040#1", "noclip", (nc["pos"] as Vector3) + Vector3(0.15, 0, 0), Vector3(1.9, 1.9, 1.0))
		if t:
			t.hold_seconds = 2.0
	add_exit("L031>L070#2", "interact", A.white_door + Vector3(-0.6, 1.0, 0), Vector3(1.4, 2.0, 1.6), "Open the white door engraved 70")
	add_exit("L031>L232#3", "interact", Vector3(25.5, 1.0, -33.1), Vector3(1.4, 2.0, 1.4), "Open the door marked \"Employees only!\"")


func _interactions() -> void:
	add_interactable(A.dispenser, Vector3(0.3, 0.6, 0.6), "Press the big blue button", _get_card)
	for g in A.playable:
		var kind: String = g["kind"]
		add_interactable(g["pos"], g["size"], "Play the " + {"video": "game", "old": "old cabinet", "drive": "sit-down machine",
			"pinball": "pinball machine", "skiball": "Ski-Ball lane", "hockey": "air hockey table", "wheel": "big wheel"}[kind],
			func(_p: Player) -> void: _play(kind))
	add_interactable(Vector3(13.5, 1.25, -28.95), Vector3(3.0, 0.5, 0.6), "Ask the clerk for food", _order_food)
	add_interactable(Vector3(19.6, 1.25, -28.95), Vector3(1.4, 0.5, 0.6), "Ask for a soda or almond water", _order_drink)
	add_interactable(Vector3(8.6, 0.8, -16.7), Vector3(2.6, 1.0, 0.8), "Throw away your trash", _bin)
	add_interactable(Vector3(0.0, 2.1, 12.0), Vector3(2.0, 0.4, 0.6), "Ask the DJ for a song", _request_song)
	add_interactable(Vector3(-25.5, 0.6, -47.3), Vector3(12.0, 0.6, 0.6), "Sit and watch the big television", _watch)
	add_interactable(Vector3(-6.0, 1.2, -24.05), Vector3(4.0, 0.4, 0.6), "Ring for skates", _ring_rental)


func _notes() -> void:
	add_note("l31_entry1", "Notebook page (wanderer's diary, entry 1)",
		"Came through a wooden door in the brick wall of an old electrical station, following music I knew from home. A roller rink, just like the one in my old town. Same lights. Same sounds. Like I was home.",
		Vector3(-26.8, 0.47, -3.2))
	add_note("l31_arcade", "M.E.G. field note (arcade)",
		"Games here are free with a green card from the metal box at the entrance: press the blue button. Wanderers report that no-clipping into any working machine sends you to Level 40. The old 1980s cabinets are few and far between.",
		Vector3(29.3, 1.0, -31.6), Vector3(0.3, 0.3, 0.4))
	add_note("l31_rental", "Notice on the rental counter",
		"LESSONS ARE FREE. Ask the Coach. Sizes on the chart.\nHe remembers everyone's name. If you've been here a while, he'll want to talk about moving on. Listen to him.",
		Vector3(-8.0, 1.12, -24.05))
	add_note("l31_entry12", "Notebook page (wanderer's diary, entry 12)",
		"Coach walked me to the back of the arcade. Machines switched off, some under cloth. A white door with 70 on it. He said it was time to move on. I told him I wasn't ready.",
		Vector3(63.5, -0.45, -14.0))
	add_note("l31_entry13", "Notebook page (wanderer's diary, entry 13)",
		"Coach says there's more food behind the employee door, and helping the cook might do me good. \"I've seen other people go in this door and never come out.\" Another exit he wants me through.",
		Vector3(23.0, 0.76, -31.5))
	add_note("l31_entry5", "Notebook page (wanderer's diary, entry 5)",
		"A cinema, of all things. Tiny: one big television and three metal benches stacked like stairs. It was playing one of my favourites from when I was a kid. I fell asleep in the corner.",
		Vector3(-31.0, 0.47, -47.3))
	add_note("l31_meg", "M.E.G. retrieval note",
		"On entry the operative was approached by the Coach, who asked for help: a wanderer lay unresponsive in the food court corner and would not eat, drink or move. The operative carried him out with his notebook. He had already died of dehydration. Cause unknown. Listen to the Coach. Do not stay too long.",
		Vector3(3.2, 0.47, -32.8))


func _ask_clerk(_p: Player) -> void:
	Overlay.subtitle("[the clerk's blank face turns to you. It says nothing, and goes back to wiping the counter.]", 3.5)


func _watch(_p: Player) -> void:
	Overlay.subtitle("[it is playing a film you loved as a child, from the part you remember best]" if _fam() < 0.4 else "[the same film again. You know every line.]", 4.0)


func _get_card(_p: Player) -> void:
	if card:
		Overlay.subtitle("[you already have a green card]", 2.0)
		return
	card = true
	sound.play_at("ui", {"kind": "click"}, A.dispenser, -8.0, "[clunk: a green card drops into the holder]")


func _play(kind: String) -> void:
	if not card:
		Overlay.subtitle("[the reader blinks: it wants a green card. The box at the entrance gives them out.]", 3.0)
		return
	plays += 1
	var stale := _fam() > 0.4
	var lines := {"video": "[bright sprites, a high score table, the old thrill]", "old": "[a boxy 1980s cabinet you played when you were too short to reach the controls]",
		"drive": "[engine roar, the seat rumbles under you]", "pinball": "[flippers clack; the ball rattles round the bumpers]",
		"skiball": "[the wooden ball rolls up the lane and drops into a ring]", "hockey": "[the puck cracks off the rails; nobody on the other side]",
		"wheel": "[the big wheel spins, ticking, slowing, stopping]"}
	Overlay.subtitle(("[you've played this one before.] " if stale else "") + str(lines.get(kind, "")), 3.0)
	sound.play_at("chiptune", {"bpm": 180.0, "root": 523.0, "scale": [0, 4, 7, 12]}, player.global_position + Vector3(0, 1, -0.5), -14.0, "")
	if kind == "wheel":
		wheel_speed = 9.0


func _order_food(_p: Player) -> void:
	if littered:
		Overlay.subtitle("[the clerk looks at you, then at the table you left your mess on, and does not move]", 3.5)
		return
	if tray:
		Overlay.subtitle("[you are still holding your tray]", 2.0)
		return
	var menu := ["a cheese slice", "a pepperoni slice", "hot wings", "a foot-long hot dog"]
	tray = true
	meals += 1
	player.heal(15.0)
	Overlay.subtitle("[the clerk slides over %s and a large soda on a tray. Free. It asks for nothing.]" % menu[(meals - 1) % menu.size()], 3.5)


func _order_drink(_p: Player) -> void:
	if littered:
		Overlay.subtitle("[the clerk ignores you]", 2.5)
		return
	player.heal(5.0)
	Overlay.subtitle("[a paper cup of almond water from the fountain, for free]", 2.5)


func _bin(_p: Player) -> void:
	if tray:
		tray = false
		Overlay.subtitle("[you tip the tray into the bin, under the taped sign]", 2.5)
	else:
		Overlay.subtitle("[the bins are clean]", 2.0)


func _request_song(_p: Player) -> void:
	if not dj.visible:
		Overlay.subtitle("[the booth is empty; the song plays on]", 2.5)
		return
	if _fam() > 0.55:
		Overlay.subtitle("[the DJ nods. The same song starts again.]", 3.0)
		_set_song(0)
		return
	_set_song((song + 1) % _songs.size())
	Overlay.subtitle("[the DJ's blank face tilts; a new song fades in]", 3.0)


func _ring_rental(_p: Player) -> void:
	if coach_state == "post" and coach.global_position.distance_to(COACH_POST) < 2.0:
		_talk_coach(player)
	else:
		Overlay.subtitle("[the bell dings. The Coach is out on the floor somewhere.]", 2.5)


func _talk_coach(_p: Player) -> void:
	if not _said.has("met"):
		_said["met"] = true
		coach_talk.prompt = "Accept the Coach's free skating lesson"
		Overlay.subtitle("The Coach: \"Hey! Saw you come in. They call me the Coach. First skating lesson's free. So's every one after.\"", 5.0)
		return
	if not skates:
		skates = true
		coach_talk.prompt = "Talk to the Coach"
		Overlay.subtitle("[he finds skates in your size behind the counter and walks you onto the maple] \"Knees soft. Lean in. I've got you.\"", 5.0)
		return
	if stay > SEEK_AT * 0.8 and not advised:
		_advise()
		return
	var stale := _fam() > 0.35
	Overlay.subtitle(("[the same words as last time] " if stale else "") + "The Coach: " + TALK[talk_i % TALK.size()], 4.0)
	talk_i += 1


func _advise() -> void:
	advised = true
	Overlay.subtitle("The Coach: \"Can I tell you something? Don't stay in one place too long. Connections out there beat comfort in here. Want me to walk you to a door?\"", 6.0)


func _ask_lead(_p: Player) -> void:
	if coach_state == "lead" or coach_state == "at_door":
		Overlay.subtitle("The Coach: \"This way. Stay close.\"", 2.5)
		return
	_start_lead()


func _start_lead() -> void:
	coach_state = "lead"
	coach_path = _route(_nearest(coach.global_position), DOOR_NODE)
	Overlay.subtitle("The Coach: \"Come on, I'll show you out. You're always welcome back.\"", 4.0)


# ---------------------------------------------------------------- mechanics

func _fam() -> float:
	return clampf((stay - FADE_FROM) / FADE_SPAN, 0.0, 1.0)


func _set_song(i: int) -> void:
	song = i
	music.stream = AudioSynth.get_stream("chiptune", _songs[i])
	music.play()
	dj_music.stream = music.stream
	dj_music.play()


func _in_rink(p: Vector3) -> bool:
	if absf(p.x) <= Rink.RINK_A:
		return absf(p.z) < Rink.RINK_R
	return Vector2(absf(p.x) - Rink.RINK_A, p.z).length() < Rink.RINK_R


func _in_food(p: Vector3) -> bool:
	return p.x > 2.0 and p.x < 28.0 and p.z > -34.0 and p.z < -16.0


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	stay += delta
	R.star.rotation.y += delta * 0.08
	A.wheel.rotation.z += wheel_speed * delta
	wheel_speed = move_toward(wheel_speed, 0.0, delta * 1.6)
	_skater(delta)
	_comfort(delta)
	_dj_cycle(delta)
	_food_rules(delta, pp)
	_coach_tick(delta, pp)
	if _movie_light:
		var t := Time.get_ticks_msec() * 0.001
		_movie_light.light_energy = 1.7 + 0.35 * sin(t * 1.7) + 0.15 * sin(t * 5.3)
	var fast := skates and _in_rink(pp)
	player.walk_speed = 4.4 if fast else 3.1
	player.sprint_speed = 6.8 if fast else 5.3


func _skater(delta: float) -> void:
	skater_t = fposmod(skater_t + delta * 3.0 / 72.0, 1.0)
	var a := Rink.oval_point(skater_t, 6.2)
	var b := Rink.oval_point(skater_t + 0.01, 6.2)
	skater.position = a + Vector3(0, 0.03, 0)
	skater.rotation.y = atan2(-(b.x - a.x), -(b.z - a.z))
	skater.rotation.z = 0.12 * sin(skater_t * TAU * 4.0)
	var t2 := fposmod(0.5 - skater_t * 1.35, 1.0)
	var a2 := Rink.oval_point(t2, 4.4)
	var b2 := Rink.oval_point(t2 - 0.01, 4.4)
	skater2.position = a2 + Vector3(0, 0.03, 0)
	skater2.rotation.y = atan2(-(b2.x - a2.x), -(b2.z - a2.z))
	_skate_t -= delta
	if _skate_t <= 0.0 and player.global_position.distance_to(a) < 22.0:
		_skate_t = 0.55
		sound.play_at("footstep", {"surface": "wood", "variant": int(skater_t * 40.0) % 4}, a, -16.0, "")


func _comfort(delta: float) -> void:
	var f := _fam()
	environment.adjustment_saturation = lerpf(1.15, 0.45, f)
	environment.adjustment_brightness = lerpf(1.0, 0.86, f)
	music.pitch_scale = lerpf(1.0, 0.965, f)
	dj_music.pitch_scale = music.pitch_scale
	crowd.volume_db = lerpf(-30.0, -48.0, f)
	Overlay.set_screen_effect("vignette", 0.12 + f * 0.33)
	_laugh_t -= delta
	if _laugh_t <= 0.0:
		_laugh_t = rng.randf_range(25.0, 45.0) * (1.0 + f * 3.0)
		Overlay.subtitle("[distant laughter across the rink, skates on the wooden floor, a muffled pop song]", 3.0)
	if qa_fixture:
		return
	var marks := {60: "[the lights, the music, the smell of cheap pizza... it feels like the rink back home]",
		240: "[the same song again]", 420: "[it is dimmer than it was. Nothing here feels new any more.]",
		600: "[you don't really feel like doing anything]"}
	for s in marks.keys():
		if stay >= float(s) and not _said.has(s):
			_said[s] = true
			Overlay.subtitle(marks[s], 4.5)
			if int(s) == 240:
				_set_song(0)
	if stay >= SEEK_AT and coach_state == "post" and not advised:
		coach_state = "seek"
	if stay >= LEAD_AT and coach_state != "lead" and coach_state != "at_door":
		_start_lead()


func _dj_cycle(delta: float) -> void:
	_dj_t -= delta
	if _dj_t > 0.0:
		return
	dj.visible = not dj.visible
	_dj_t = rng.randf_range(40.0, 90.0) if dj.visible else rng.randf_range(30.0, 60.0)
	if dj.visible and _fam() < 0.5:
		_set_song(rng.randi() % _songs.size())


func _food_rules(delta: float, pp: Vector3) -> void:
	if tray and not _in_food(pp):
		# left the food court with food and trash still on the table
		tray = false
		littered = true
		var t: Vector3 = _tables[rng.randi() % _tables.size()]
		_litter_node = Node3D.new()
		_litter_node.name = "LeftTray"
		add_child(_litter_node)
		Props.place(self, _litter_node, "kenney/food-kit/plate", t + Vector3(0.1, 0.76, 0.1), 20.0, 0.02)
		Props.place(self, _litter_node, "kenney/food-kit/soda-can-crushed", t + Vector3(-0.2, 0.76, -0.1), 0.0, 0.06)
		_clean_t = 6.0
		Overlay.subtitle("[behind you, the clerk sighs at the tray you left on the table]", 3.0)
	if _clean_t > 0.0:
		_clean_t -= delta
		if _clean_t <= 0.0 and is_instance_valid(_litter_node):
			_litter_node.queue_free()


func _nearest(p: Vector3) -> int:
	var best := 0
	var bd := INF
	for i in NODES.size():
		var d := Vector2(p.x - NODES[i].x, p.z - NODES[i].z).length() + absf(p.y - NODES[i].y) * 4.0
		if d < bd:
			bd = d
			best = i
	return best


func _route(a: int, b: int) -> Array:
	var prev := {a: -1}
	var q := [a]
	while not q.is_empty():
		var n: int = q.pop_front()
		if n == b:
			break
		for e in EDGES:
			var m := -1
			if int(e[0]) == n:
				m = int(e[1])
			elif int(e[1]) == n:
				m = int(e[0])
			if m >= 0 and not prev.has(m):
				prev[m] = n
				q.append(m)
	var out: Array = []
	if not prev.has(b):
		return out
	var c := b
	while c != -1:
		out.push_front(NODES[c])
		c = int(prev[c])
	return out


func _coach_tick(delta: float, pp: Vector3) -> void:
	var cp := coach.global_position
	var goal := Vector3.INF
	match coach_state:
		"post":
			if cp.distance_to(COACH_POST) > 0.3:
				coach_path = _route(_nearest(cp), 0)
				coach_state = "return"
			elif pp.distance_to(cp) < 6.0:
				_face(pp, delta)
			return
		"seek":
			if coach_path.is_empty():
				coach_path = _route(_nearest(cp), _nearest(pp))
				if coach_path.is_empty():
					coach_state = "return"
					return
			if pp.distance_to(cp) < (2.4 if not _in_rink(pp) else 9.5):
				coach_path.clear()
				coach_state = "post_wait"
				_advise()
				return
		"post_wait":
			_face(pp, delta)
			if pp.distance_to(cp) > 14.0:
				coach_state = "return"
				coach_path = _route(_nearest(cp), 0)
			return
		"lead":
			if not coach_path.is_empty() and pp.distance_to(cp) > 7.0:
				_face(pp, delta)
				return
			if coach_path.is_empty():
				coach_state = "at_door"
				Overlay.subtitle("The Coach: \"This is it. The white door. Go on. And come back and visit sometime.\"", 5.0)
				return
		"at_door":
			_face(pp, delta)
			return
		"return":
			if coach_path.is_empty():
				coach_state = "post"
				return
	if coach_path.is_empty():
		return
	goal = coach_path[0]
	var to := goal - cp
	to.y = 0.0
	if to.length() < 0.35:
		coach_path.pop_front()
		if coach_state == "seek" and coach_path.is_empty():
			# arrived near the player's area: close the last gap in a straight line
			if not _in_rink(pp):
				coach_path.append(pp)
		return
	var step := minf(to.length(), 1.6 * delta)
	var np := cp + to.normalized() * step
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(np + Vector3.UP * 1.2, np + Vector3.DOWN * 1.5, 1))
	np.y = (hit["position"] as Vector3).y if not hit.is_empty() else goal.y
	coach.global_position = np
	coach.rotation.y = atan2(-to.x, -to.z)


func _face(p: Vector3, delta: float) -> void:
	var to := p - coach.global_position
	if to.length() < 0.1:
		return
	var want := atan2(-to.x, -to.z)
	coach.rotation.y = lerp_angle(coach.rotation.y, want, clampf(delta * 3.0, 0.0, 1.0))


func on_player_ready() -> void:
	if not qa_fixture:
		Overlay.subtitle("[the door shuts behind you on a muffled pop song. A roller rink, lights dimmed, the smell of pizza.]", 5.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "three sourced exit kinds present (noclip game, white door 70, Employees only!)",
		"ok": exits.filter(func(t): return t.edge_id == "L031>L040#1").size() >= 1 and exits.filter(func(t): return t.edge_id == "L031>L070#2").size() == 1
			and exits.filter(func(t): return t.edge_id == "L031>L232#3").size() == 1})
	_play("video")
	out.append({"what": "games need a green card", "ok": plays == 0})
	_get_card(player)
	_play("video")
	out.append({"what": "green card makes games free", "ok": card and plays == 1})
	var before := environment.adjustment_saturation
	stay = FADE_FROM + FADE_SPAN
	_comfort(0.016)
	out.append({"what": "comfort decays with the length of the stay", "ok": environment.adjustment_saturation < before - 0.5,
		"detail": [before, environment.adjustment_saturation]})
	stay = 0.0
	_comfort(0.016)
	var path := _route(0, DOOR_NODE)
	out.append({"what": "the Coach can lead from the rental to the white door", "ok": path.size() > 4 and (path[path.size() - 1] as Vector3).distance_to(A.white_door) < 2.0})
	out.append({"what": "a Faceling skates the oval loop", "ok": _in_rink(skater.global_position)})
	return out
