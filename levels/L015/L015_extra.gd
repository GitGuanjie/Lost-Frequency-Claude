extends RefCounted
## Level 15: the sky beyond the frame, the light plan, the soundscape, the
## documents and the time-near-the-frame counter.

const G := preload("res://levels/L015/L015_geo.gd")


## What lies beyond the frame: a night sky with distant points of light and a
## large, still sphere of clear blue light at its centre. A flipped box is
## invisible from outside, so only the frame opening shows it.
static func beyond(lvl) -> void:
	var root := Node3D.new()
	root.name = "Beyond"
	lvl.add_child(root)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(120, 100, 104)
	bm.flip_faces = true
	box.mesh = bm
	box.position = Vector3(0, 10, G.FRAME_Z - 4.5 - 52.0)
	box.material_override = MatLib.get_mat("l15_void")
	box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(box)
	var star := StandardMaterial3D.new()
	star.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star.albedo_color = Color(0.92, 0.95, 1.0)
	star.disable_fog = true
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	sm.radial_segments = 6
	sm.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sm
	mm.instance_count = 900
	var r := RandomNumberGenerator.new()
	r.seed = 1566
	for i in mm.instance_count:
		var face := r.randi() % 5
		var p := Vector3.ZERO
		match face:
			0, 1:
				p = Vector3(r.randf_range(-58, 58), r.randf_range(-38, 58), G.FRAME_Z - 108.0 + r.randf_range(0, 4))
			2:
				p = Vector3(r.randf_range(-58, 58), 58.0 - r.randf_range(0, 3), G.FRAME_Z - r.randf_range(15, 108))
			3:
				p = Vector3(-58.0 + r.randf_range(0, 3), r.randf_range(-38, 58), G.FRAME_Z - r.randf_range(15, 108))
			4:
				p = Vector3(58.0 - r.randf_range(0, 3), r.randf_range(-38, 58), G.FRAME_Z - r.randf_range(15, 108))
		var s := r.randf_range(0.2, 0.7) * (1.0 + float(r.randi() % 23 == 0) * 1.5)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), p))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = star
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var core := MeshInstance3D.new()
	var cs := SphereMesh.new()
	cs.radius = 4.0
	cs.height = 8.0
	core.mesh = cs
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.0, 0.0, 0.0)
	cm.emission_enabled = true
	cm.emission = Color(0.45, 0.7, 1.0)
	cm.emission_energy_multiplier = 3.2
	cm.disable_fog = true
	core.material_override = cm
	core.position = Vector3(0, 2.6, G.FRAME_Z - 70.0)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	var halo := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 7.5
	hs.height = 15.0
	halo.mesh = hs
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.albedo_color = Color(0.12, 0.25, 0.6, 0.35)
	hm.disable_fog = true
	hm.cull_mode = BaseMaterial3D.CULL_FRONT
	halo.material_override = hm
	halo.position = core.position
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)


static func lights(lvl) -> void:
	var L: LightPool = lvl.lights
	L.setup(12, 1)
	L.max_distance = 38.0
	var cold := Color(0.82, 0.92, 1.0)
	var ground := Color(0.55, 0.88, 1.0)
	var teal := Color(0.4, 0.95, 0.85)
	# control room: radar wall, two live ceiling bars, Enric's lamp
	L.add_anchor(Vector3(0, 5.4, -20.0), teal, 1.4, 13.0)
	L.add_anchor(Vector3(-6.5, 7.3, -4.0), cold, 1.1, 12.0)
	L.add_anchor(Vector3(-6.5, 7.3, -14.0), cold, 1.0, 12.0)
	L.add_anchor(Vector3(4.5, 7.3, -9.0), cold, 0.6, 10.0, 0.8)
	L.add_anchor(Vector3(13.2, 4.9, -14.2), Color(1.0, 0.82, 0.6), 0.9, 6.5)
	L.add_anchor(Vector3(-12.5, 0.6, -11.0), ground, 0.5, 6.0)
	# spine A: ceiling bars
	for z in [-26.0, -34.0, -42.0, -50.0, -58.0]:
		L.add_anchor(Vector3(0, 5.5, z), cold, 1.25, 11.0)
	# spine B: ground light only
	for z in [-62.0, -67.0, -72.0, -77.0]:
		L.add_anchor(Vector3(-3.2 if int(z) % 2 == 0 else 3.2, 0.3, z), ground, 0.7, 5.5)
	# spine D: sparse wall lights, one stuttering
	for z in [-102.0, -108.0, -114.0, -120.0, -126.0]:
		L.add_anchor(Vector3(-3.4 if int(z) % 12 == 6 else 3.4, 3.0, z), cold, 0.55, 7.0, 0.6 if z == -114.0 else 0.0)
	# engine hall
	L.add_anchor(Vector3(14, 8.2, -34), cold, 2.4, 24.0)
	L.add_anchor(Vector3(14, 8.2, -50), cold, 2.2, 24.0)
	L.add_anchor(Vector3(28, 8.2, -56), cold, 2.0, 22.0)
	L.add_anchor(Vector3(16, -3.0, -54.0), Color(1.0, 0.6, 0.2), 1.2, 8.0)
	L.add_anchor(Vector3(22, -4.5, -38.0), teal, 1.2, 11.0)
	L.add_anchor(Vector3(36, -3.0, -50.0), ground, 1.0, 10.0)
	# side rooms
	L.add_anchor(Vector3(10, 6.0, -78), cold, 0.7, 9.0, 1.0)
	L.add_anchor(Vector3(9, 4.7, -112), cold, 0.9, 11.0)
	L.add_anchor(Vector3(17, 3.6, -110), Color(1.0, 0.8, 0.6), 0.5, 7.0)
	L.add_anchor(Vector3(-12, 4.2, -30), cold, 1.0, 9.0)
	L.add_anchor(Vector3(-12, 4.2, -38), cold, 0.9, 9.0)
	L.add_anchor(Vector3(-12, 3.3, -54), cold, 0.9, 10.0)
	L.add_anchor(Vector3(-12, 3.3, -71), cold, 1.0, 10.0, 1.0)
	L.add_anchor(Vector3(-12, 3.3, -77), cold, 0.6, 8.0)
	L.add_anchor(Vector3(-10, 4.6, -106), cold, 0.7, 9.0)
	L.add_anchor(Vector3(-18, 4.6, -116), cold, 0.6, 9.0)
	# sealed doors at the ends of the dark gallery
	for sx in [-1.0, 1.0]:
		L.add_anchor(Vector3(sx * (G.CROSS_X - 1.0), 3.8, G.CROSS_Z), Color(1.0, 0.15, 0.1), 0.5, 5.0)
	# the doorframe room: the frame's soft white light and the blue beyond
	L.add_anchor(Vector3(0, 2.4, G.FRAME_Z + 1.2), Color(0.88, 0.94, 1.0), 2.0, 20.0)
	L.add_anchor(Vector3(0, 2.4, G.FRAME_Z - 1.0), Color(0.45, 0.65, 1.0), 1.0, 12.0)
	L.add_anchor(Vector3(-14.0, 3.2, -134.6), cold, 0.45, 7.0)


static func sounds(lvl) -> void:
	var S: Soundscape = lvl.sound
	S.bed("room_tone", {"cutoff": 140.0, "rumble": 0.45, "seconds": 7.0}, -31.0)
	S.emitter("transformer", Vector3(30.0, -2.0, -40.0), {"base": 37.0}, -7.0, 75.0)
	S.emitter("room_tone", Vector3(14.0, -2.0, -33.0), {"cutoff": 90.0, "rumble": 0.9, "seconds": 5.0}, -6.0, 45.0)
	S.emitter("transformer", Vector3(14.0, -4.0, -52.0), {"base": 61.0}, -18.0, 26.0)
	S.emitter("fluorescent_hum", Vector3(0, 5.8, -40.0), {"base": 120.0, "rasp": 0.15}, -27.0, 16.0)
	S.emitter("fluorescent_hum", Vector3(-5.0, 7.6, -9.0), {"base": 100.0, "rasp": 0.1}, -28.0, 14.0)
	S.emitter("static", Vector3(0, 5.6, -20.5), {"seconds": 3.0}, -34.0, 10.0)
	S.emitter("crackle", Vector3(10.0, 5.8, -78.0), {}, -26.0, 12.0)
	S.oneshot("knock", {"hits": 1}, 25.0, 60.0, 40.0, "[far off, a machine changes pitch]", -24.0)
	S.oneshot("creak", {"freq": 55.0}, 30.0, 70.0, 20.0, "[a steel beam ticks as it cools]", -26.0)


static func notes(lvl) -> void:
	lvl.add_interactable(Vector3(0, 1.6, -0.8), Vector3(3.6, 3.2, 0.8), "Try the heavy door", func():
		Overlay.toast("It does not move. This is where the first wanderer came in from Level 10, during an event that has happened only once. Two days later the door slammed shut by itself, and it has not reopened since.", 6.0))
	lvl.add_note("l15_enric", "Laptop on the gallery desk (I.L.N. connected)",
		"[i]The camp of the only known base on Level 15. Paraphrased from the page.[/i]\n\nThe wanderer the groups call Enric came in from Level 10 and made this large control room his camp. He has been here about two years.\n\nYear one: exploring. By his own estimate he covered around 6,080 km² and found no end.\nYear two: the files and the technology. No breakthrough that would let him leave.\n\nThe I.L.N. never drops here. Through it he posts weekly updates, receives books, music and games, has spoken with his family on Level 11, and keeps sessions with a psychiatrist. He has coped, mostly.\n\nOther camps exist, all abandoned, all made by the people now lying dead in these halls.",
		Vector3(12.8, 4.24, -12.6))
	lvl.add_interactable(Vector3(-3.4, 1.1, -9.9), Vector3(2.0, 0.8, 0.9), "Watch the scanner", func():
		Overlay.show_note("Scanner (every terminal, the same picture)",
			"Every screen that shows this scan shows the same thing at the same moment.\n\nShapes cross the screen, most at a constant rate; a few speed up or slow down. Some are joined by green lines, but only while both ends are on screen. When two shapes overlap, they turn green. Orange lines predict where a shape is going, only while that shape is visible, and they never change.\n\nTwo things never move: the shape in the centre and the small circle on the right. A green line joins them.\n\n[i]Theories (not confirmed):[/i] that this was once a space station tracking objects around it; or that the shapes are levels, the green lines the ways between them, and overlaps two levels colliding. The second theory links the centre-to-circle line to the room with the glowing doorframe."))
	lvl.add_interactable(Vector3(3.4, 1.1, -9.9), Vector3(2.0, 0.8, 0.9), "Read the terminal", func():
		Overlay.show_note("Terminal: AVALON 2.4",
			"AVALON 2.4  (an unknown version of Linux)\nI.L.N. link: up\n\n/data/  ⟟⟒⌇⟟⏃  ⏚⟒⍀⟟⋔⌰  ⟊⍜⏁⟒⌇  ⋏⍜⏁⟒⌇⟟⏁  ...\n\nThe file names and contents are in a language nobody can read yet; the Cygnus Order is studying it. What is known is the kind of file: journals, mails, studies, and manuals about the engines and machines in these halls and what they do."))
	lvl.add_note("l15_dead", "Clipboard on the lab bench",
		"[i]Observations, paraphrased from the page.[/i]\n\nThe dead look human. All wear lab coats. They died fighting, with makeshift knives and spears; no firearm has been found, yet some bodies carry clear gunshot wounds.\n\nThere are no bugs to break them down, but they have dried out enough to have lain here for months, maybe years. Nobody here has the manpower to examine, identify or move them.",
		Vector3(-12.1, 0.98, -30.7))
	lvl.add_note("l15_stores", "Inventory sheet on the crates",
		"Food. Water. Equipment of many kinds.\n\nNot on the list, not on any shelf, not anywhere on this level: Almond Water. Its absence is the one thing every report agrees on.",
		Vector3(-21.6, 1.24, -101.5))
	lvl.add_interactable(Vector3(15.5, 1.0, -110.0), Vector3(5.0, 1.8, 6.0), "Look at the pile", func():
		Overlay.show_note("The cremation room",
			"Corpses of Hounds, a great many of them, heaped in front of the furnace. The room seems to have been used to burn a large number of things nobody can name.\n\nNo living entity has ever been found on Level 15. These are only the dead."))
	lvl.add_interactable(Vector3(3.6, 2.4, -75.0), Vector3(0.6, 2.4, 9.0), "Look at the glass", func():
		Overlay.show_note("Wrecked engine room",
			"Rarely, a machine room holds machines that have exploded or broken apart for no known reason. Lack of maintenance is the usual theory: nothing here seems to stop them from failing.\n\nThe glass took the blast. It is shattered, but not broken, like laminated glass."))
	lvl.add_interactable(Vector3(27.6, -5.0, -52.0), Vector3(2.2, 1.2, 2.0), "Look into the bin", func():
		Overlay.toast("Finished steel rods, still arriving. Some machines here have an obvious job; most do not, and some have no Frontrooms equivalent at all. %d rods have dropped since you came in." % lvl.produced, 5.0))
	lvl.add_note("l15_frame", "Survey sheet taped to the reinforced door",
		"[i]Paraphrased from the page.[/i]\n\nThis room looks like every engine room on the level, except that all of its engines are missing. At the back stands a doorframe with no door, glowing a soft white light. Through it: a night sky, distant points of light, and at the centre a large, still sphere of clear blue light, suspected to be a star.\n\nThe reinforced door into this room is intact, which may be what keeps Level 15 from depressurising. The sphere may have irradiated this room: spend as little time here as possible.\n\nIt looks like a way into a new, undocumented level. Exploring it is not considered viable.",
		Vector3(2.4, 1.35, G.SPINE_Z1 + 0.5), Vector3(0.5, 0.5, 0.2))


## Time spent in the doorframe room (the page asks Enric to keep it short).
static func exposure_step(lvl) -> void:
	var e: float = lvl.exposure
	var told: Dictionary = lvl._told
	if e > 10.0 and not told.has("exp1"):
		told["exp1"] = true
		if not SessionState.is_qa():
			Overlay.subtitle("[no engines here. The drone of the halls falls away behind the door.]", 4.0)
	if e > 45.0 and not told.has("exp2"):
		told["exp2"] = true
		if not SessionState.is_qa():
			Overlay.toast("You have been near the frame for a while. The advice was to spend as little time here as possible: the sphere may have irradiated this room.", 5.0)
	if e > 120.0 and not told.has("exp3"):
		told["exp3"] = true
		if not SessionState.is_qa():
			Overlay.toast("Still here. Nobody knows yet what the sphere does to a room, or to the people standing in it.", 4.0)
