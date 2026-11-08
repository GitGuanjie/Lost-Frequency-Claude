extends LevelBase
## Level 60 "The Baywalk" (Backrooms Wikidot rev 33, accessed 2026-11-04; D34TH_0000,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L060.md.
## Content note: the page reports deaths by drowning and by the "Painless Death". Shown
## through mechanics and notes only; nothing graphic.
##
## PLAN (v2.0 rebuild: read -> design)
## - SOURCE: outdoors beside a bay; an infinitely long, newly built, well-kept concrete
##   bay walk; street lights mostly broken or off; no daylight, mostly darkness ->
##   ChunkWorld streams 100 m coast chunks along x (a finite streaming window; fog and
##   darkness end every sightline). Cross-section: dead-grass embankment rising inland,
##   the Upper Area walk (+5.0 m) with railing and lamps, a retaining wall, the Lower Area
##   dirt path (+1.0 m), a beach slope into The Sea.
## - SOURCE: Lower Area = unfinished dirt path, construction equipment everywhere, no
##   barriers against falling into the sea, no entities; staircases about 100 m apart are
##   safe and the lamp in front of each staircase works -> one stair + one working lamp per
##   chunk; seeded scatter of barriers, cones, crates, generators, formwork, rebar, sacks.
## - SOURCE: arrival is always in The Sea after drowning elsewhere; you rise and set foot on
##   the dirt path -> sea arrivals ~14 m out in 4 ft of water, facing the shore.
## - SOURCE: Smilers concentrate in the Upper Area's darker stretches, drawn to light; none
##   in the Lower Area; one may be met on the exposed shore at low tide -> scripted grins
##   that gather at the edges of lamp pools and creep toward you (faster with a torch on),
##   hurt on contact, and never come down the stairs.
## - SOURCE: The Sea changes characteristic: Normal (4 ft, safe), Portal (looks the same,
##   pulls you in: mostly Level 7; exit 1), Low-Tide (no water, black sand, Painless Death
##   stops), Ocean (~3,740 m, calm, a downward current drowns you) -> a seeded timed cycle.
## - Signature mechanic (stateful): the Painless Death. Facing the sea breeze while afraid
##   (Upper Area, Smilers near, hurt) builds a calm that grows stronger with time; keep
##   moving (the Guide) to shake it, The Brave slap you out of it near their camp, it stops
##   at low tide; at full calm you never get up.
## - SOURCE: The Brave (~10, no leader, hidden, friendly traders, weekly radio reports to
##   M.E.G., camp moves) -> a hiding spot built from the equipment (seeded position), a
##   radio, notes with the Guide and the sea chart; no visible members.
## - RUMOURED: sleeping in the Upper Area wakes you on Level 61 (exit 2, documented edge,
##   added in this rebuild; strongly discouraged: Smilers come while you sleep).
## - ABSENT: daylight, food and water in the Upper Area, entities in the Lower Area.

const Coast := preload("res://levels/L060/L060_coast.gd")
const GRIN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float reveal = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float eyes = 0.0;
	eyes += 1.0 - smoothstep(0.09, 0.12, length((p - vec2(-0.36, 0.45)) * vec2(1.0, 1.4)));
	eyes += 1.0 - smoothstep(0.09, 0.12, length((p - vec2(0.36, 0.45)) * vec2(1.0, 1.4)));
	float outer = 1.0 - smoothstep(0.80, 0.84, length(p - vec2(0.0, 0.55)));
	float inner = 1.0 - smoothstep(0.80, 0.84, length(p - vec2(0.0, 0.80)));
	float grin = clamp(outer - inner, 0.0, 1.0) * step(p.y, 0.2);
	float teeth = step(0.16, fract(p.x * 7.0 + 0.5));
	float m = clamp(eyes + grin * mix(0.3, 1.0, teeth), 0.0, 1.0);
	ALBEDO = vec3(0.97, 0.97, 0.92) * 1.6;
	ALPHA = m * reveal;
}
"""
const SEA_START := Vector3(30.0, -1.2, 21.0)
const QA_START := Vector3(30.0, 1.0, 5.6)
const PHASES := ["normal", "portal", "lowtide", "ocean"]

var coast
var world: ChunkWorld
var sea: WaterVolume
var seabed: StaticBody3D
var qa_fixture := false
var phase := "normal"
var phase_t := 150.0
var calm := 0.0
var stay := 0.0
var hurt_t := 0.0
var hideout: Dictionary = {}
var hide_x := 24.0
var smilers: Array = []        # [{node, mat, pos, v}]
var portal_exit: ExitTrigger
var sleep_exit: ExitTrigger
var _roll := false
var _was_wet := false
var _sleeping := false
var _asleep := false
var _sleep_t := 0.0
var _said := {}
var _buzz: AudioStreamPlayer3D
var _waves: AudioStreamPlayer
var _pad: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _hiss: AudioStreamPlayer3D
var _lamp_t := 0.0
var _sea_mat: ShaderMaterial


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 300.0
	rules["oxygen_seconds"] = 45.0
	rules["kill_y"] = -3800.0
	rules["reverb_room"] = 0.05
	rules["reverb_wet"] = 0.02
	indoor_env(Color(0.36, 0.46, 0.66), 0.15, Color(0.020, 0.027, 0.040), 0.012)
	environment.background_color = Color(0.008, 0.012, 0.02)
	environment.fog_sky_affect = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_hdr_threshold = 0.9
	var night := DirectionalLight3D.new()
	night.name = "NightSkyGlow"
	night.rotation_degrees = Vector3(-35.0, 200.0, 0.0)
	night.light_color = Color(0.45, 0.55, 0.75)
	night.light_energy = 0.14
	add_child(night)
	Coast.materials()
	_sea_mat = MatLib.get_mat("l60_sea") as ShaderMaterial
	var pick := RandomNumberGenerator.new()
	pick.seed = hash([level_seed, "brave"])
	hide_x = [14.0, 24.0, 72.0, 84.0][pick.randi() % 4]
	coast = Coast.new(self)
	_sea()
	lights.setup(8, 1)
	world = ChunkWorld.new()
	world.name = "Baywalk"
	world.chunk_size = Coast.CHUNK
	world.radius = 2
	world.unload_radius = 3
	world.builder = func(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary: return _build_chunk(cx, cz, node)
	world.chunk_unloaded.connect(func(key: Vector2i) -> void: lights.remove_group("c%d" % key.x))
	add_child(world)
	world.build_around(Vector3(30, 0, 0), 2)
	_smilers()
	_sounds()
	_exits()
	_notes()
	var land := QA_START if qa_fixture else SEA_START
	add_arrival("start", land, 180.0 if qa_fixture else 0.0)
	add_arrival("from_L085", SEA_START, 0.0)
	add_arrival("from_L009", SEA_START + Vector3(-6.0, 0, 2.0), 0.0)
	if qa_fixture:
		_set_phase("portal")
		_roll = true
	add_landmark("Staircase with a working lamp", Vector3(Coast.STAIR_X, Coast.LOW_Y, 1.4))
	add_landmark("The Brave's hiding spot", Vector3(hide_x, Coast.LOW_Y, 3.0))
	add_landmark("Upper Area bay walk", Vector3(60, Coast.UP_Y, -6))
	add_shot("upper_walk", Vector3(61.0, 6.7, -1.6), Vector3(30.0, 5.7, -9.5), {"flashlight": false})
	add_shot("lower_path", Vector3(38.0, 2.6, 6.6), Vector3(56.0, 2.2, 1.5), {"flashlight": false})
	add_shot("from_the_sea", Vector3(47.0, 0.45, 19.0), Vector3(56.0, 3.4, 0.0), {"flashlight": false, "prepare": _prep_normal})
	add_shot("brave_camp", Vector3(hide_x + 4.5, 2.6, 8.4), Vector3(hide_x - 0.5, 1.4, 2.0), {"flashlight": false})
	add_shot("stairs", Vector3(51.0, 2.6, 6.2), Vector3(57.5, 5.4, 0.3), {"flashlight": false})


func _build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = coast.chunk(cx, cz, node, level_seed, hide_x if cx == 0 else INF)
	if cz != 0:
		return meta
	for l in meta["lamps"]:
		var st: int = l["state"]
		if st == 2:
			lights.add_anchor(l["pos"], Color(1.0, 0.8, 0.52), 4.2, 19.0, 0.0, "c%d" % cx)
		elif st == 1:
			lights.add_anchor(l["pos"], Color(1.0, 0.8, 0.52), 2.6, 14.0, 0.8, "c%d" % cx)
	if meta.has("hideout"):
		hideout = meta["hideout"]
		lights.add_anchor(hideout["lantern"], Color(1.0, 0.6, 0.3), 0.7, 6.0, 0.1, "c%d" % cx)
		make_interactable(hideout["radio"], Vector3(0.6, 0.5, 0.5), "Listen to the radio", _radio, node)
		var n := Interactable.new()
		node.add_child(n)
		n.setup(hideout["table"] + Vector3(-0.35, 0.03, 0.1), Vector3(0.4, 0.06, 0.3), "Read")
		n.as_note("l60_guide", "The \"Guide\" (pinned under the radio)",
			"From The Brave. If you feel optimistic here, think straight away about what hides in the dark. If the breeze changes, ignore it and keep moving. Do not meditate. If someone is too cheerful, cure them at once: a slap usually works.")
	return meta


func _sea() -> void:
	sea = WaterVolume.new()
	sea.name = "TheSea"
	add_child(sea)
	sea.setup(Vector3(-6000, -40.0, 7.0), Vector3(6000, 0.0, 1600.0), "l60_sea", true)
	sea.fog_color = Color(0.01, 0.03, 0.04)
	sea.fog_density = 0.25
	sea.tint = Color(0.05, 0.15, 0.18)
	seabed = StaticBody3D.new()
	seabed.name = "Seabed"
	add_child(seabed)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(12000, 1.0, 1590.0)
	cs.shape = bs
	cs.position = Vector3(0, Coast.BED_Y - 0.5, 13.0 + 795.0)
	cs.set_meta("surface", "sand")
	seabed.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12000, 1590.0)
	mi.mesh = pm
	mi.material_override = MatLib.get_mat("l60_blacksand")
	mi.position = Vector3(0, Coast.BED_Y, 13.0 + 795.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seabed.add_child(mi)


func _smilers() -> void:
	var sh := Shader.new()
	sh.code = GRIN_SHADER
	for i in 9:
		var mat := ShaderMaterial.new()
		mat.shader = sh
		var mi := MeshInstance3D.new()
		mi.name = "Smiler"
		var q := QuadMesh.new()
		q.size = Vector2(1.0, 0.64)
		mi.mesh = q
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, -50, 0)
		add_child(mi)
		smilers.append({"node": mi, "mat": mat, "v": 0.0, "home": Vector3.ZERO, "set": false})


func _sounds() -> void:
	sound.bed("wind", {"seconds": 6.0}, -19.0)
	_waves = sound.bed("water_bed", {"bright": 0.35, "seconds": 6.0}, -15.0)
	_pad = sound.bed("pad", {"root": 98.0, "chord": [0, 7, 12, 16], "bright": 0.1, "seconds": 10.0}, -80.0)
	_heart = sound.bed("heartbeat", {}, -80.0)
	_buzz = sound.emitter("transformer", Vector3(Coast.STAIR_X + 7.5, 11.0, 0.15), {"base": 100.0, "seconds": 3.0}, -20.0, 18.0)
	_hiss = sound.emitter("whisper", Vector3(0, -50, 0), {"seconds": 3.0}, -80.0, 14.0)
	sound.emitter("static", Vector3(hide_x, 1.6, 3.6), {"seconds": 3.0}, -27.0, 7.0)
	sound.oneshot("splash", {}, 9.0, 20.0, 18.0, "[a wave slaps the shore]", -18.0)


func _exits() -> void:
	# Exit 1 first (QA walker target): contact with The Sea in its Portal characteristic.
	portal_exit = add_exit("L060>L007#1", "condition", Vector3(30.0, -0.7, 34.75), Vector3(120.0, 2.8, 50.5))
	if portal_exit:
		portal_exit.condition = func() -> bool: return phase == "portal" and _roll and is_instance_valid(player) and player.global_position.y < 0.05
	# Exit 2 (RUMOURED+DANGEROUS): sleep on a bench in the Upper Area -> Level 61.
	sleep_exit = add_exit("L060>L061#2", "interact", Vector3(22.0, Coast.UP_Y + 0.8, -11.0), Vector3(2.2, 1.6, 1.6), "Lie down on the bench and sleep")
	if sleep_exit:
		sleep_exit.condition = func() -> bool: return _asleep or qa_fixture
		sleep_exit.fired.connect(func(_e: String) -> void: _sleeping = false)


func _notes() -> void:
	add_note("l60_sea_chart", "The Sea, as charted by The Brave", "NORMAL: like any sea back home. About four feet deep. Safe. The only way in.\nPORTAL: looks the same but is not water. It pulls you in. Mostly it sends you to Level 7.\nLOW-TIDE: no water at all, black sand. The calm stops. Smilers walk the sand.\nOCEAN: deep as an ocean, calm waves, and the current goes DOWN. Four of us were lost to it.",
		Vector3(Coast.STAIR_X - 0.6, Coast.LOW_Y + 1.25, 0.47), Vector3(0.4, 0.3, 0.05), false)
	add_note("l60_report", "Weekly report to M.E.G. (copy)", "Lower Area: clear, no entities this week. Stairs about every hundred metres, all safe; the lamps at the stairs still work. Upper Area: hordes in the dark stretches, thickest round the lit lamps. No food or water up there. Do not go up first thing. Be patient.",
		Vector3(Coast.STAIR_X + 1.2, Coast.LOW_Y + 0.05, 3.2))
	var meg := kit("NoticeBoard")
	meg.box(Vector3(Coast.STAIR_X - 0.6, Coast.LOW_Y + 1.25, 0.47), Vector3(0.5, 0.4, 0.02), "paper", GeoKit.ALL, false)
	meg.commit()


# ---------------------------------------------------------------- interaction

func _radio(_p: Player) -> void:
	Overlay.subtitle("[static, then a calm voice: \"...weekly update. Lower Area holding. Lamps at the stairs still on. Keep away from the water when it goes quiet...\"]", 5.0)


# ---------------------------------------------------------------- the sea

func _set_phase(p: String) -> void:
	phase = p
	sea.surface_mesh.visible = p != "lowtide"
	if p == "lowtide":
		sea.aabb = AABB(Vector3(-6000, -200.0, 7.0), Vector3(12000, 1.0, 1593.0))
		sea.surface_y = -199.0
	elif p == "ocean":
		sea.aabb = AABB(Vector3(-6000, -3740.0, 7.0), Vector3(12000, 3740.0, 1593.0))
		sea.surface_y = 0.0
	else:
		sea.aabb = AABB(Vector3(-6000, -40.0, 7.0), Vector3(12000, 40.0, 1593.0))
		sea.surface_y = 0.0
	seabed.position.y = -360.0 if p == "ocean" else 0.0
	if world:
		for key in world.chunks.keys():
			var deb := (world.chunks[key]["node"] as Node3D).get_node_or_null("SeaDebris")
			if deb:
				(deb as Node3D).visible = p != "ocean"
	if _sea_mat:
		_sea_mat.set_shader_parameter("wave_height", 0.16 if p == "ocean" else 0.07)
		_sea_mat.set_shader_parameter("foam_amount", 0.0 if p == "portal" else 0.18)
	if _waves:
		_waves.volume_db = -80.0 if p == "lowtide" else (-22.0 if p == "portal" else -15.0)
	if built and not qa_fixture:
		var cue := {"normal": "[the sea comes back in, calm, ankle to chest deep]", "portal": "[the waves go quiet. The water looks the same, but nothing moves in it.]",
			"lowtide": "[the sea is gone. Black sand runs out into the dark.]", "ocean": "[the swell rises. The water past the shore looks very deep now.]"}
		Overlay.subtitle(cue[p], 4.0)


func _sea_cycle(delta: float) -> void:
	if qa_fixture:
		return
	phase_t -= delta
	if phase_t > 0.0:
		return
	if phase != "normal":
		_set_phase("normal")
		phase_t = rng.randf_range(120.0, 220.0)
		return
	var v := rng.randf()
	_set_phase("portal" if v < 0.3 else ("lowtide" if v < 0.65 else "ocean"))
	phase_t = rng.randf_range(40.0, 80.0)


func _water_rules(delta: float, pp: Vector3) -> void:
	var wet := sea.contains(pp + Vector3.UP * 0.1)
	if wet and not _was_wet and phase == "portal" and not qa_fixture:
		# SOURCE: it pulls anyone who touches it; it has sent people mostly to Level 7
		_roll = rng.randf() < 0.75
		if not _roll:
			Overlay.subtitle("[the water grips you like hands, then lets go and drops you on the sand]", 3.5)
			player.global_position = Vector3(pp.x, Coast.LOW_Y + 0.05, 5.0)
	_was_wet = wet
	if phase == "ocean" and wet and pp.z > 12.0:
		# SOURCE: the current strangely goes downwards
		player.global_position.y -= 1.1 * delta
		if not _said.has("current"):
			_said["current"] = true
			Overlay.subtitle("[the current pulls straight down. Swimming up does nothing.]", 4.0)
	# keep the shoreline triggers with the player
	if portal_exit:
		var cx := snappedf(pp.x, 20.0)
		if absf(portal_exit.global_position.x - cx) > 0.5:
			portal_exit.global_position.x = cx


# ---------------------------------------------------------------- smilers & calm

func _working_lamps() -> Array:
	var out: Array = []
	for key in world.chunks.keys():
		var m: Dictionary = world.meta_of(key)
		for l in m.get("lamps", []):
			if int(l["state"]) >= 1:
				out.append(l["pos"])
	return out


func _smiler_rules(delta: float, pp: Vector3) -> float:
	var upper := pp.y > 3.6 and pp.z < 0.6
	var shore := phase == "lowtide" and pp.z > 7.0
	var near := INF
	var lamps := _working_lamps()
	var i := 0
	for s in smilers:
		var node := s["node"] as MeshInstance3D
		var want := upper or (shore and i == 0)
		var mode := "shore" if (shore and i == 0) else "upper"
		if want and bool(s["set"]) and (str(s.get("mode", "")) != mode or absf((s["home"] as Vector3).x - pp.x) > 45.0):
			s["set"] = false
		if want and not bool(s["set"]):
			s["mode"] = mode
			# gather in the dark at the edge of a lamp's pool, or along the dark walk
			var anchor := pp
			if not lamps.is_empty() and i % 3 != 2:
				var best: Vector3 = lamps[0]
				for lp in lamps:
					if absf((lp as Vector3).x - pp.x) < absf(best.x - pp.x):
						best = lp
				anchor = Vector3(best.x, pp.y, pp.z)
			var off := rng.randf_range(9.0, 16.0) * (1.0 if rng.randf() < 0.5 else -1.0)
			var home := Vector3(anchor.x + off, Coast.UP_Y + rng.randf_range(1.2, 1.7), rng.randf_range(-11.0, -2.0))
			if shore and i == 0:
				home = Vector3(pp.x + rng.randf_range(-10, 10), Coast.BED_Y + 1.5, pp.z + rng.randf_range(16, 24))
			s["home"] = home
			node.position = home
			s["set"] = true
		var target := 1.0 if want else 0.0
		s["v"] = move_toward(float(s["v"]), target, delta * (0.6 if want else 0.4) * (8.0 if qa_fixture else 1.0))
		(s["mat"] as ShaderMaterial).set_shader_parameter("reveal", float(s["v"]))
		if float(s["v"]) <= 0.0:
			s["set"] = false
			node.position.y = -50.0
		elif is_instance_valid(player.camera):
			node.look_at(player.camera.global_position, Vector3.UP, true)
			var d := node.global_position.distance_to(pp + Vector3.UP)
			near = minf(near, d)
			if want and not qa_fixture:
				# drawn to light: a lamp overhead or a torch in hand brings them on
				var lit := player.flashlight.visible
				for lp in lamps:
					if Vector2((lp as Vector3).x - pp.x, (lp as Vector3).z - pp.z).length() < 7.0:
						lit = true
				var speed := (0.9 if lit else 0.25) * (2.5 if _sleeping else 1.0)
				var goal := pp + Vector3(0, 1.3, 0)
				if not shore:
					goal.z = minf(goal.z, -0.6)
				node.position = node.position.move_toward(goal, speed * delta)
				if d < 1.3:
					Overlay.glitch(0.7)
					player.hurt(28.0, "Smilers in the dark of the Upper Area, Level 60")
					hurt_t = 6.0
					if _sleeping:
						_sleeping = false
						player.frozen = false
						Overlay.set_screen_effect("blackout", 0.0)
						Overlay.subtitle("[you wake to teeth in the dark]", 3.0)
					node.position = s["home"]
		i += 1
	if near < 12.0 and _hiss:
		var closest: Vector3 = smilers[0]["node"].global_position
		for s in smilers:
			if (s["node"] as Node3D).global_position.distance_to(pp) < closest.distance_to(pp):
				closest = (s["node"] as Node3D).global_position
		_hiss.global_position = closest
	if _hiss:
		_hiss.volume_db = lerpf(-80.0, -16.0, clampf((14.0 - near) / 12.0, 0.0, 1.0))
	return near


func _calm_rules(delta: float, pp: Vector3, near: float) -> void:
	if qa_fixture:
		return
	var upper := pp.y > 3.6 and pp.z < 0.6
	var fwd := -player.camera.global_transform.basis.z
	var facing := fwd.z > 0.45
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	var afraid := upper or near < 25.0 or hurt_t > 0.0 or player.health < 70.0
	if phase == "lowtide":
		calm = move_toward(calm, 0.0, delta * 0.2)
	elif afraid and facing and speed < 1.2 and pp.z > -13.0:
		var rate := (1.0 / 70.0 if upper else 1.0 / 200.0) * (1.0 + stay / 900.0)
		calm = minf(1.0, calm + rate * delta)
	elif speed > 2.5:
		calm = maxf(0.0, calm - delta * 0.05)
	else:
		calm = maxf(0.0, calm - delta * 0.005)
	if calm > 0.45 and absf(pp.x - hide_x) < 14.0 and pp.y < 3.0 and not _said.has("slap"):
		_said["slap"] = true
		calm = 0.0
		Overlay.glitch(0.3)
		sound.play_at("knock", {"hits": 1}, pp + Vector3(0.4, 1.6, 0), -6.0, "[a hand cracks across your face out of the dark: \"Snap out of it. Keep moving.\"]")
	var marks := {0.3: "[the sea breeze is soft. You feel... relaxed.]", 0.6: "[calm. So calm. What were you even worried about?]",
		0.85: "[your legs fold. You sit and let the breeze wash over you.]"}
	for m in marks.keys():
		if calm >= float(m) and not _said.has(m):
			_said[m] = true
			Overlay.subtitle(marks[m], 4.0)
		elif calm < float(m) - 0.15:
			_said.erase(m)
	player.walk_speed = lerpf(3.1, 1.2, clampf((calm - 0.4) / 0.5, 0.0, 1.0))
	player.sprint_speed = lerpf(5.3, 1.6, clampf((calm - 0.4) / 0.5, 0.0, 1.0))
	_pad.volume_db = -80.0 if calm < 0.05 else lerpf(-34.0, -12.0, calm)
	environment.adjustment_saturation = lerpf(0.9, 1.25, calm)
	environment.adjustment_brightness = lerpf(1.0, 1.25, calm)
	Overlay.set_screen_effect("vignette", 0.2 + calm * 0.3)
	if calm >= 1.0 and not player.dead:
		player.hurt(1000.0, "The Painless Death: you let the sea breeze take you, Level 60")


# ---------------------------------------------------------------- loop

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	stay += delta
	hurt_t = maxf(0.0, hurt_t - delta)
	_sea_cycle(delta)
	_water_rules(delta, pp)
	var near := _smiler_rules(delta, pp)
	_heart.volume_db = -80.0 if near > 18.0 else lerpf(-40.0, -14.0, clampf((18.0 - near) / 16.0, 0.0, 1.0))
	_calm_rules(delta, pp, near)
	_sleep_rules(delta, pp)
	_lamp_t -= delta
	if _lamp_t <= 0.0:
		_lamp_t = 1.0
		var best := Vector3(0, -100, 0)
		for lp in _working_lamps():
			if (lp as Vector3).distance_to(pp) < best.distance_to(pp):
				best = lp
		_buzz.global_position = best
		if sleep_exit:
			var bx := INF
			var cx := floorf(pp.x / Coast.CHUNK) * Coast.CHUNK
			for o in [-Coast.CHUNK, 0.0, Coast.CHUNK]:
				for b in Coast.BENCH_XS:
					var x: float = cx + o + float(b)
					if absf(x - pp.x) < absf(bx - pp.x):
						bx = x
			if absf(sleep_exit.global_position.x - bx) > 0.1 and not _sleeping:
				sleep_exit.global_position.x = bx


func _sleep_rules(delta: float, pp: Vector3) -> void:
	if sleep_exit == null:
		return
	if not _sleeping and sleep_exit._inside == player and Input.is_action_just_pressed("interact") and not qa_fixture:
		_sleeping = true
		_sleep_t = 0.0
		player.frozen = true
		Overlay.subtitle("[you lie down on the cold bench. Everyone says not to. Your eyes close anyway.]", 4.0)
	if _sleeping:
		_sleep_t += delta
		Overlay.set_screen_effect("blackout", clampf(_sleep_t / 6.0, 0.0, 0.95))
		if _sleep_t > 7.0:
			_asleep = true
			sleep_exit.interact(player)
			player.frozen = false
			_sleeping = false


func _prep_normal() -> void:
	_set_phase("normal")
	await get_tree().process_frame


func _prep_lowtide() -> void:
	_set_phase("lowtide")
	await get_tree().process_frame


func on_player_ready() -> void:
	if not qa_fixture:
		_set_phase("normal")
		phase_t = rng.randf_range(150.0, 240.0)
		Overlay.subtitle("[you break the surface, choking. Dark water to your chest. Lamps far apart along a sea wall.]", 5.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "streamed coast chunks loaded around the arrival", "ok": world.chunks.size() >= 3})
	out.append({"what": "a working lamp at every staircase", "ok": _working_lamps().size() >= 3})
	out.append({"what": "the Brave's hiding spot exists", "ok": not hideout.is_empty()})
	_set_phase("lowtide")
	out.append({"what": "low tide drains the sea", "ok": not sea.contains(Vector3(30, -1.0, 20)) and not sea.surface_mesh.visible})
	_set_phase("ocean")
	out.append({"what": "ocean drops the seabed and deepens the water", "ok": sea.contains(Vector3(30, -2000.0, 40)) and seabed.position.y < -100.0})
	_set_phase("portal")
	out.append({"what": "portal characteristic restores the 4 ft sea", "ok": sea.contains(Vector3(30, -1.0, 20)) and seabed.position.y == 0.0})
	out.append({"what": "no Smiler is revealed in the Lower Area", "ok": smilers.all(func(s): return float(s["v"]) == 0.0)})
	return out
