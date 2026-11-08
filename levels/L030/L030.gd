extends LevelBase
## Level 30 — "Shifted Beyond Reality" (Backrooms Wikidot rev 46, accessed
## 2026-11-04; cite: i like computer, CC BY-SA 3.0). Dossier: docs/canon/levels/L030.md.
##
## PLAN (v2.0 rebuild)
## The page is three contradicting blocks, and block C says why: Level 30 has
## a false form shown through Memory Lurkers and an unknown true form. The
## level keeps both false forms and never resolves them.
## Form A (block A, where you arrive): a large daytime skybox; one flat island
## with a thin grass surface over stone and rocks, its underside tapering into
## open sky; other islands far away across the sky (never reachable); a rock
## causeway down to a lower shelf under the north rim where the destroyed
## outpost's remains and notes lie; Wormlings moving under three dirt patches;
## Memory Lurkers, small squid-like flyers, drift around the island.
## Form B (block B, the trance): touching a Lurker, or letting one reach you,
## grabs your head: the same island goes dark and plastic, bridges that clip
## into each other run out into the dark (most end in the void; one ends at a
## blue glow, "The Blue Channel", that recedes; one ends at a painted backdrop
## of the bright island). The level itself speaks from everywhere.
## Block C rules: realising that everything is fake (at the painted backdrop)
## kills you, and you wake on the grass as if alive; falling off either form
## does the same. Each loop the bright form grows more plastic and the voice
## less kind (memories and nostalgia turning to fear and disgust).
## Exits: "Unknown" in blocks A and C; the draft bridges are a false form.
## None is built (level.json no_exit_reason).
## Helper: L030_world.gd.

const W := preload("res://levels/L030/L030_world.gd")
const START := Vector3(4.0, 0.05, -20.0)
const PARK := Vector3(0, 6000, 0)
const VOICE_A := ["[a voice from nowhere in particular: it remembers your old bedroom, the smell of it]",
	"[the voice recalls a summer you had forgotten. It is very kind about it.]",
	"[the voice says the floating ones are \"The Gateway To Paradise\"]",
	"[the voice: touch one, and the regret stops. Forever.]"]
const VOICE_B := ["[the voice is behind you, then inside your head: it knows what you did]",
	"[the voice lists your regrets, one by one, in order]",
	"[the voice: the Backrooms will never let you go. The Gateway will.]",
	"[the voice speaks about you to someone else, as if you were not here]"]

var world
var form := "A"
var loops := 0
var bridges_root: Node3D
var lurkers: Array = []     # {node, c, r, h, a, speed, sneak}
var worm_mounds: Array = []  # {node, c, a}
var sky_mat: ProceduralSkyMaterial
var lurker_mat: StandardMaterial3D
var voice_bed: AudioStreamPlayer
var pad_a: AudioStreamPlayer
var pad_b: AudioStreamPlayer
var voice_t := 40.0
var voice_i := 0
var still_t := 0.0
var blue_light: OmniLight3D
var blue_quad: MeshInstance3D
var busy := false
var said := {}
var sky_nodes: Array = []


func build() -> void:
	world = W.new(self)
	rules["view_distance"] = 3200.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.04
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -900.0
	outdoor_env(Color(0.2, 0.42, 0.82), Color(0.72, 0.84, 0.95), Color(0.5, 0.68, 0.9), Vector2(58.0, 35.0),
		Color(1.0, 0.96, 0.88), 1.1, Color(0.72, 0.82, 0.93), 0.0009)
	sky_mat = environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.ground_horizon_color = Color(0.72, 0.84, 0.95)
	sky_mat.ground_bottom_color = Color(0.38, 0.58, 0.88)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0
	environment.fog_sky_affect = 0.3
	sun.directional_shadow_max_distance = 160.0
	W.materials()
	lights.setup(6, 0)
	var isl := Node3D.new()
	isl.name = "Island"
	add_child(isl)
	var col := kit("IslandCollision")
	var k := kit("Shelf")
	world.island(isl, col)
	world.shelf(isl, col, k)
	col.commit()
	k.commit()
	var fk := kit("FarIslands")
	world.far_islands(fk)
	fk.commit()
	sky_nodes.append(fk.root)
	var sky := Node3D.new()
	sky.name = "Clouds"
	add_child(sky)
	world.clouds(sky)
	sky_nodes.append(sky)
	bridges_root = Node3D.new()
	bridges_root.name = "FalseFormBridges"
	add_child(bridges_root)
	var bk := GeoKit.new(bridges_root, "Bridges")
	world.bridges(bk)
	world.backdrop(bk)
	bk.commit()
	_blue_channel()
	make_interactable(world.flat_at + Vector3(0, 1.5, 0), Vector3(3.0, 3.0, 3.0), "Look closely at the painted sky", _realise, bridges_root)
	bridges_root.position = PARK
	bridges_root.visible = false
	var d := Node3D.new()
	d.name = "Dressing"
	add_child(d)
	_dress(d)
	_lurkers()
	_wormlings()
	_sounds()
	_notes()
	add_arrival("start", START, 180.0)
	add_landmark("The flat island (bright false form)", Vector3.ZERO)
	add_landmark("Shelf with the outpost remains", world.shelf_c)
	add_landmark("Island rim over open sky", Vector3(0, 0, world.rn))
	add_landmark("Dark island bridges (trance only)", world.blue_end)
	add_shot("island_skybox", START + Vector3(1.5, 1.62, 2.5), START + Vector3(-5.0, 2.3, -14.0), {"flashlight": false, "prepare": _prep_lurker})
	var ra := 2.3
	var rim := Vector3(cos(ra), 0, sin(ra)) * (W.rad(ra) - 1.2)
	add_shot("rim_into_sky", world.shelf_c + Vector3(15.0, 1.65, -9.0), Vector3(75.0, -14.0, -world.rn + 25.0), {"flashlight": false, "prepare": _prep.bind("A")})
	add_shot("outpost_shelf", world.ramp_top + Vector3(-1.0, 1.65, -2.0), world.shelf_c + Vector3(-2.0, 0.6, -2.0), {"flashlight": false, "prepare": _prep.bind("A")})
	var ba := -0.3 - PI * 0.5
	var bd := Vector3(cos(ba), 0, sin(ba))
	var b0 := bd * (W.rad(ba) + 8.0)
	add_shot("false_form_bridges", b0 + Vector3(0, 1.75, 0) - bd.cross(Vector3.UP) * 0.8, world.blue_end + bd * 30.0 + Vector3(0, 2.0, 0), {"flashlight": true, "prepare": _prep.bind("B")})


# ------------------------------------------------------------------ dressing

func _dress(d: Node3D) -> void:
	var rr := RandomNumberGenerator.new()
	rr.seed = 3003
	for i in 12:
		var a := rr.randf() * TAU
		var rad := W.rad(a) - rr.randf_range(2.0, 7.0)
		Props.place(self, d, "ph/boulder_01", Vector3(cos(a) * rad, -0.2, sin(a) * rad), rr.randf_range(0, 360), rr.randf_range(1.0, 3.2), true)
	for i in 6:
		var p := Vector3(rr.randf_range(-70, 70), -0.05, rr.randf_range(-70, 70))
		if W.inside(p.x, p.z, 8.0):
			Props.place(self, d, "ph/boulder_01", p, rr.randf_range(0, 360), rr.randf_range(0.5, 1.4), true)
	# where the thin grass has worn through: bare stone, flush with the turf
	var sk := kit("WornStone")
	for i in 70:
		var p := Vector3(rr.randf_range(-95, 95), 0.0, rr.randf_range(-95, 95))
		if W.inside(p.x, p.z, 4.0):
			if i < 70:
				sk.box_xf(Transform3D(Basis(Vector3.UP, rr.randf() * PI), p + Vector3(0, 0.008, 0)), Vector3(rr.randf_range(1.5, 6.0), 0.016, rr.randf_range(1.0, 4.0)), "l30_rock", GeoKit.PY, false)
	sk.commit()
	# the outpost remains on the shelf
	var c: Vector3 = world.shelf_c
	for e in [["ph/old_military_crate", Vector3(-1.5, 0, -0.5), 20.0, true], ["ph/old_military_crate", Vector3(-1.4, 0.3, -0.3), 64.0, false],
			["ph/wooden_crate_01", Vector3(4.6, 0, 1.5), -30.0, true], ["ph/old_bed_frame", Vector3(1.8, 0, 3.6), 80.0, true],
			["ph/vintage_radio_transceiver", Vector3(-1.4, 0.6, -0.4), 160.0, false], ["ph/plastic_bottle_gallon", Vector3(5.2, 0, 2.8), 0.0, false],
			["ph/plastic_bottle_gallon", Vector3(5.5, 0, 2.4), 70.0, false], ["ph/vintage_flashlight", Vector3(0.6, 0, -1.8), 40.0, false],
			["ph/binder_notebook", Vector3(2.2, 0, -1.0), 15.0, false], ["ph/plastic_monobloc_chair_01", Vector3(-4.2, 0, 1.6), 200.0, false],
			["ph/medical_box", Vector3(-5.5, 0, -2.6), 30.0, false], ["ph/vintage_suitcase", Vector3(7.5, 0, -1.6), 100.0, false]]:
		Props.place(self, d, e[0], c + e[1], e[2], 0.0, e[3])
	Props.place(self, d, "kenney/graveyard-kit/lantern-glass", c + Vector3(-0.8, 0.0, 2.0), 0.0, 0.35)


func _blue_channel() -> void:
	var e: Vector3 = world.blue_end
	var dir := (e * Vector3(1, 0, 1)).normalized()
	blue_light = OmniLight3D.new()
	blue_light.light_color = Color(0.25, 0.5, 1.0)
	blue_light.light_energy = 4.0
	blue_light.omni_range = 40.0
	blue_light.position = e + dir * 30.0 + Vector3(0, 3, 0)
	bridges_root.add_child(blue_light)
	blue_quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(9, 6)
	blue_quad.mesh = qm
	blue_quad.material_override = MatLib.get_mat("l30_blue")
	bridges_root.add_child(blue_quad)
	blue_quad.position = e + dir * 34.0 + Vector3(0, 3, 0)
	blue_quad.look_at(blue_quad.position - dir, Vector3.UP)


func _lurkers() -> void:
	lurker_mat = MatLib.standard(Color(0.82, 0.78, 0.86), 0.25, 0.0, Color(0.5, 0.45, 0.6), 0.25)
	var rr := RandomNumberGenerator.new()
	rr.seed = 3030
	for i in 7:
		var n: Node3D = W.lurker(lurker_mat)
		n.scale = Vector3.ONE * 1.5
		add_child(n)
		var a := rr.randf() * TAU
		var c := Vector3(cos(a), 0, sin(a)) * rr.randf_range(30.0, 95.0)
		var L := {"node": n, "c": c, "r": rr.randf_range(8.0, 22.0), "h": rr.randf_range(2.2, 6.0), "a": rr.randf() * TAU,
			"speed": rr.randf_range(0.08, 0.16) * (1.0 if i % 2 == 0 else -1.0), "sneak": false}
		lurkers.append(L)
		n.position = c + Vector3(cos(L["a"]) * L["r"], L["h"], sin(L["a"]) * L["r"])
		make_interactable(Vector3.ZERO, Vector3(1.2, 1.2, 1.4), "Touch the Memory Lurker", _grabbed, n)
	# one hangs close to the start so a still can find it
	lurkers[0]["c"] = START + Vector3(-9.0, 0, -14.0)
	lurkers[0]["r"] = 4.0
	lurkers[0]["h"] = 2.4
	(lurkers[0]["node"] as Node3D).position = lurkers[0]["c"] + Vector3(cos(lurkers[0]["a"]) * 4.0, 2.4, sin(lurkers[0]["a"]) * 4.0)


func _wormlings() -> void:
	var dk := kit("DirtPatches")
	var m := MatLib.standard(Color(0.24, 0.17, 0.11), 1.0)
	for c in [Vector3(-38.0, 0, 22.0), Vector3(30.0, 0, 48.0), Vector3(52.0, 0, -36.0)]:
		dk.box(c + Vector3(0, 0.01, 0), Vector3(9.0, 0.02, 7.0), "l30_soil", GeoKit.PY, false)
		var mound := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.35
		sm.height = 0.3
		mound.mesh = sm
		mound.material_override = m
		add_child(mound)
		worm_mounds.append({"node": mound, "c": c, "a": randf() * TAU})
		sound.emitter("scratch", c + Vector3(0, 0.2, 0), {"seconds": 1.8}, -14.0, 9.0)
	dk.commit()


func _sounds() -> void:
	sound.bed("wind", {"seconds": 10.0}, -24.0)
	pad_a = sound.bed("pad", {"root": 196.0, "chord": [0, 4, 7, 11, 14], "bright": 0.25, "seconds": 12.0}, -30.0)
	pad_b = sound.bed("pad", {"root": 73.0, "chord": [0, 1, 6, 10, 13], "bright": 0.1, "seconds": 10.0}, -80.0)
	voice_bed = sound.bed("whisper", {"seconds": 3.0}, -46.0)
	for L in lurkers:
		sound.emitter("drip", Vector3.ZERO, {"freq": 380.0}, -22.0, 7.0).reparent(L["node"], false)
	sound.oneshot("creak", {"freq": 300.0}, 50.0, 120.0, 30.0, "", -30.0)


func _notes() -> void:
	var c: Vector3 = world.shelf_c
	add_note("l30_outpost", "Outpost note (left on the shelf)", "Hello? Can anybody hear us? I think this is supposed to send in some kind of report about an entity. But listen. \"Something is wrong here, the description is short for a reason.\" They don't know what is going on, so they can't explain much. We know more. We will try to remake this draft. I'm out.\n\n(Underneath, in another hand, an M.E.G. annotation: the outpost was destroyed by Memory Lurkers. \"Do not listen to them; they are under the level's many effects and trances.\")", c + Vector3(2.2, 0.05, -1.0))
	add_note("l30_draft", "Torn page: original_draft_30", "A dark island, a lot of bridges clipping into each other. Most lead somewhere: some to the Blue Channel, some into the void, some you can't tell, it's so dark. The Lurkers weren't here at first; now they just float. One hit with a crowbar flopped like a fish.\n\nThe level talks. Not a Lurker. From everywhere: behind us, in our heads. About our past, our regrets, and the Lurkers, which it calls the Gateway To Paradise.\n\nMy friend got 'killed'. Now she talks so flat, no expression. Everything feels fake, 2D, plastic, like a VR headset. The Lurkers are the headset.\n\nthe truth was in my eyes", c + Vector3(-4.6, 0.05, 1.2))
	add_note("l30_meg", "M.E.G. notice (collated)", "LEVEL 30. Collected from the original file and the first revision.\n\nTwo forms. The false form is shown to you through Memory Lurkers and looks like an ordinary level. The true form is unknown, possibly incomprehensible.\n\nThe Lurkers kill instantly and make you think you are still alive. Realising that everything around you is fake will kill you. This is a dead zone.\n\nThe level itself is an entity. It speaks. Do not touch the Lurkers, whatever it promises.\n\nNo known bases, outposts or communities. Exits: unknown.", c + Vector3(-1.2, 0.64, -0.6))


# --------------------------------------------------------------- the forms

func _prep_lurker() -> void:
	await _prep("A")
	var L: Dictionary = lurkers[0]
	L["c"] = START + Vector3(-1.6, 0, -4.2)
	L["r"] = 0.0
	L["h"] = 2.0
	(L["node"] as Node3D).position = L["c"] + Vector3(0, 2.0, 0)
	await get_tree().process_frame


func _prep(f: String) -> void:
	if f != form:
		_set_form(f)
	await get_tree().process_frame


func _set_form(f: String) -> void:
	form = f
	var dark := f == "B"
	bridges_root.position = Vector3.ZERO if dark else PARK
	bridges_root.visible = dark
	sun.visible = not dark
	for n in sky_nodes:
		(n as Node3D).visible = not dark
	var plastic := clampf(loops * 0.18, 0.0, 0.7)
	if dark:
		sky_mat.sky_top_color = Color(0.004, 0.005, 0.009)
		sky_mat.sky_horizon_color = Color(0.016, 0.02, 0.03)
		sky_mat.ground_horizon_color = Color(0.016, 0.02, 0.03)
		sky_mat.ground_bottom_color = Color(0.0, 0.0, 0.0)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.3, 0.33, 0.46)
		environment.ambient_light_energy = 1.9
		environment.fog_light_color = Color(0.03, 0.035, 0.05)
		environment.fog_density = 0.004
		environment.adjustment_saturation = 0.55
		environment.adjustment_contrast = 1.25
	else:
		sky_mat.sky_top_color = Color(0.2, 0.42, 0.82).lerp(Color(0.1, 0.5, 1.0), plastic)
		sky_mat.sky_horizon_color = Color(0.72, 0.84, 0.95)
		sky_mat.ground_horizon_color = Color(0.72, 0.84, 0.95)
		sky_mat.ground_bottom_color = Color(0.38, 0.58, 0.88)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		environment.ambient_light_energy = 0.55
		environment.fog_light_color = Color(0.72, 0.82, 0.93)
		environment.fog_density = 0.0009
		environment.adjustment_saturation = 1.15 + plastic
		environment.adjustment_contrast = 1.0 + plastic * 0.3
	# plastic look: flatter, glossier surfaces, more so each loop and in the trance
	var gl := 0.85 - (0.6 if dark else plastic * 0.8)
	for mn in ["l30_grass", "l30_rock", "l30_soil"]:
		var m := MatLib.get_mat(mn) as ShaderMaterial
		m.set_shader_parameter("roughness_a", gl)
		m.set_shader_parameter("bump_strength", 0.05 if dark else 0.8 * (1.0 - plastic))
	var g := MatLib.get_mat("l30_grass") as ShaderMaterial
	g.set_shader_parameter("albedo_a", Color(0.16, 0.2, 0.18) if dark else Color(0.15, 0.3, 0.08).lerp(Color(0.25, 0.75, 0.2), plastic))
	g.set_shader_parameter("albedo_b", Color(0.19, 0.23, 0.21) if dark else Color(0.32, 0.46, 0.14).lerp(Color(0.3, 0.8, 0.25), plastic))
	pad_a.volume_db = -80.0 if dark else -30.0
	pad_b.volume_db = -26.0 if dark else -80.0
	voice_bed.volume_db = -24.0 if dark else -46.0 + loops * 3.0
	for L in lurkers:
		L["sneak"] = false


func _grabbed() -> void:
	if busy or form == "B":
		return
	busy = true
	Overlay.subtitle("[something soft closes over your head]", 3.0)
	Overlay.glitch(1.0)
	await Overlay.fade_to(1.0, 0.8)
	_set_form("B")
	var p := player.global_position
	player.global_position = Vector3(p.x, maxf(p.y, 0.05), p.z)
	await get_tree().create_timer(0.6).timeout
	await Overlay.fade_to(0.0, 1.4)
	Overlay.subtitle("[it is so dark. Bridges everywhere, crossing through each other.]", 4.5)
	busy = false


func _wake(reason: String) -> void:
	if busy:
		return
	busy = true
	loops += 1
	SaveService.set_flag(stable_id, "loops", loops)
	Overlay.glitch(1.0)
	Overlay.subtitle(reason, 4.0)
	await Overlay.fade_to(1.0, 0.5)
	_set_form("A")
	player.global_position = START
	player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.8).timeout
	await Overlay.fade_to(0.0, 2.0)
	Overlay.subtitle("[you are standing on the grass. Warm sun. You feel fine. You feel very fine.]", 4.5)
	busy = false


func on_player_ready() -> void:
	loops = int(SaveService.flag(stable_id, "loops", 0))
	if loops > 0:
		_set_form("A")


func _realise() -> void:
	if form != "B":
		return
	_wake("[it is flat. It was always flat. The truth was in your eyes, and it kills you.]")


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var t := Time.get_ticks_msec() * 0.001
	_tick_lurkers(delta, p, t)
	for w in worm_mounds:
		w["a"] += delta * 0.6
		var n: MeshInstance3D = w["node"]
		n.position = w["c"] + Vector3(cos(w["a"]) * 3.0, -0.12 + 0.06 * sin(t * 3.0), sin(w["a"] * 1.3) * 2.2)
	if form == "B":
		var dd := Vector2(p.x - world.blue_end.x, p.z - world.blue_end.z).length()
		blue_light.light_energy = clampf(dd / 30.0, 0.0, 1.0) * 4.0
		blue_quad.visible = dd > 12.0
		if dd < 14.0 and not said.has("blue"):
			said["blue"] = true
			Overlay.subtitle("[the blue light was further away than it looked. Now it is gone.]", 4.0)
	if SessionState.is_qa() or busy:
		return
	if p.y < -40.0:
		_wake("[you fall, and fall, and then you are not falling]")
		return
	voice_t -= delta
	if voice_t <= 0.0:
		voice_t = rng.randf_range(35.0, 70.0) if form == "A" else rng.randf_range(15.0, 30.0)
		var lines: Array = VOICE_A if form == "A" and loops < 2 else VOICE_B
		Overlay.subtitle(lines[voice_i % lines.size()], 5.0)
		voice_i += 1


func _tick_lurkers(delta: float, p: Vector3, t: float) -> void:
	var v := player.velocity
	v.y = 0.0
	still_t = still_t + delta if v.length() < 0.3 else 0.0
	var cam := player.camera.global_transform if player.camera else Transform3D()
	for i in lurkers.size():
		var L: Dictionary = lurkers[i]
		var n: Node3D = L["node"]
		var target: Vector3
		if form == "B":
			target = L["c"] + Vector3(cos(L["a"]) * L["r"], L["h"] + 0.3 * sin(t + i), sin(L["a"]) * L["r"])
			L["a"] += delta * 0.02
		else:
			L["a"] += delta * L["speed"]
			target = L["c"] + Vector3(cos(L["a"]) * L["r"], L["h"] + 0.4 * sin(t * 0.8 + i), sin(L["a"]) * L["r"])
			# one of them sneaks up on anyone who stands still too long
			if not SessionState.is_qa() and i == 1 and still_t > 25.0 and not busy:
				L["sneak"] = true
			if L["sneak"]:
				var behind := p + cam.basis.z * 1.2 + Vector3(0, 1.7, 0)
				var seen := (n.global_position - cam.origin).normalized().dot(-cam.basis.z) > 0.6
				target = n.global_position if seen else behind
				if n.global_position.distance_to(p + Vector3(0, 1.6, 0)) < 1.3:
					L["sneak"] = false
					_grabbed()
		var prev := n.global_position
		n.global_position = prev.move_toward(target, delta * (2.2 if L["sneak"] else 1.6))
		var mv := n.global_position - prev
		if mv.length() > 0.001:
			n.look_at(n.global_position + mv, Vector3.UP)
		for c in n.get_children():
			if c.name.begins_with("T"):
				(c as Node3D).rotation.y = 0.25 * sin(t * 3.0 + float(str(c.name).substr(1)))


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "no exits built (page: Exits unknown)", "ok": exits.is_empty()})
	var space := get_world_3d().direct_space_state
	var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 5, 0), Vector3(0, -5, 0), 1))
	out.append({"what": "flat grass island under the start area", "ok": not down.is_empty() and absf(float(down["position"].y)) < 0.05})
	var sh: Vector3 = world.shelf_c
	var hs := space.intersect_ray(PhysicsRayQueryParameters3D.create(sh + Vector3(0, 3, 0), sh + Vector3(0, -3, 0), 1))
	out.append({"what": "lower shelf is walkable (second height)", "ok": not hs.is_empty() and absf(float(hs["position"].y) - W.SHELF_Y) < 0.1})
	var probe: Vector3 = world.blue_end * Vector3(0.6, 0, 0.6)
	var bh := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe + Vector3(0, 30, 0), probe + Vector3(0, -30, 0), 1))
	var off_ok := bh.is_empty() or float(bh["position"].y) < 1.0
	_set_form("B")
	await get_tree().physics_frame
	await get_tree().physics_frame
	var bh2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(world.blue_end * Vector3(0.9, 0, 0.9) + Vector3(0, 30, 0), world.blue_end * Vector3(0.9, 0, 0.9) + Vector3(0, -30, 0), 1))
	out.append({"what": "bridges exist only inside the trance", "ok": off_ok and not bh2.is_empty(), "detail": [off_ok, bh2.get("position", null)]})
	var flat := form == "B" and not sun.visible
	_set_form("A")
	out.append({"what": "trance switches to the dark form and back", "ok": flat and form == "A" and sun.visible})
	out.append({"what": "seven Memory Lurkers drift around the island", "ok": lurkers.size() == 7})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
