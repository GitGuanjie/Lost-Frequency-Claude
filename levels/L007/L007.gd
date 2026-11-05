extends LevelBase
## Level 7 — "Thalassophobia" (Backrooms Wikidot rev 48, accessed 2026-11-04;
## cite: Bart0nius, CC BY-SA 3.0). Dossier: docs/canon/levels/L007.md.
##
## Two frames. The furnished entrance room (bottom of the stairs from Level 6)
## is walkable in its own frame; it is "built sideways into the ceiling", so the
## doorway shows the sea face-on and anyone directly in front of it has gravity
## turned toward the water: they drop through a hatch in the concrete ceiling,
## ~4.5 m above an endless ocean. A rope ladder (left coiled by the door) is the
## only way back up. Ocean: one WaterVolume, streamed 150 m ceiling/abyss chunks
## (seeded islands, tar-and-rock piles), an authored seamount almost straight
## below the hatch with an underwater cave on its east ridge (-> Level 8), and a
## ring of pipes and pillars round a stone platform 150 m west / 150 m down whose
## wooden floor door leads to Level 9. Depth zones (compressed, see notes):
## Daylight 0..180 m, Twilight ..320 m, Midnight ..500 m, Abyss below.
## Entities are presences, never bodies (the page gives no appearance):
## Tiny near his ring (hearing; loud noise subdues), the Thing in the Midnight
## Zone/upper Abyss (light subdues). Staying in the Abyss ~2 min -> Level 83.

const Geo := preload("res://levels/L007/SeaGeo.gd")
const Build := preload("res://levels/L007/SeaBuild.gd")
const ROOM := Geo.ROOM
const DOOR := Geo.DOOR
const RING := Geo.RING
const FORT := Geo.FORT
const Z_DAY := Geo.Z_DAY
const Z_TWI := Geo.Z_TWI
const Z_MID := Geo.Z_MID
const CS := Geo.CS
const SEA := Geo.SEA

var geo: Geo
var vis_xf: Transform3D
var sea: WaterVolume
var surf: MeshInstance3D
var snow: CPUParticles3D
var world: ChunkWorld
var qa_fixture := false
var rope := false
var rope_nodes: Array = []
var mouth := Vector3.ZERO
var abyss_t := 0.0
var tiny := 0.0
var tiny_sub := 0.0
var thing := 0.0
var cold := 0.0
var _flip_cd := 0.0
var _said: Dictionary = {}
var _under := false
var _beds: Dictionary = {}
var _groan_t := 8.0
var _boom_t := 20.0
var _shake := 0.0


func build() -> void:
	geo = Geo.new()
	qa_fixture = SessionState.is_qa()
	var has_light := not SessionState.is_story() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["oxygen_seconds"] = 450.0
	rules["view_distance"] = 650.0
	rules["reverb_room"] = 0.62
	rules["reverb_wet"] = 0.2
	indoor_env(Color(0.5, 0.48, 0.44), 0.2, Color(0.1, 0.1, 0.1), 0.0)
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.3
	environment.adjustment_enabled = true
	Build.materials()
	vis_xf = Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(DOOR.x - 1.025, SEA + 4.82, DOOR.z))
	var rr := RandomNumberGenerator.new()
	rr.seed = 7  # furniture is fixed; the sideways copy must match the room
	var k := kit("Room")
	Geo.room(k, Transform3D(Basis(), ROOM), true, rr)
	k.commit()
	rr.seed = 7
	var kv := kit("RoomSideways")
	Geo.room(kv, vis_xf, false, rr)
	kv.commit()
	_room_dressing()
	_ocean()
	Build.seamount(self, geo, level_seed)
	Build.ring(self, geo)
	Build.fort(self, geo)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.build_around(ROOM, 2)
	_exits()
	add_arrival("start", ROOM + Vector3(0, 0.05, 5.6), 0.0)
	add_arrival("from_L006", ROOM + Vector3(0, 0.05, 5.6), 0.0)
	add_landmark("Entrance room (home base)", ROOM)
	add_landmark("Ceiling hatch", DOOR)
	add_landmark("Pipe-and-pillar ring", RING)
	add_landmark("Cave on the seamount", mouth)
	_audio()
	if SessionState.is_story() and SaveService.flag(stable_id, "rope", false):
		_drop_rope(false)


# ------------------------------------------------------------- the room

func _room_dressing() -> void:
	var ss := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(60, 60)
	ss.mesh = qm
	ss.material_override = MatLib.get_mat("l7_sidesea")
	ss.position = ROOM + Vector3(0, 1.0, -4.8)
	add_child(ss)
	var lamp := OmniLight3D.new()
	lamp.position = ROOM + Vector3(0, 2.4, 3.2)
	lamp.light_color = Color(1.0, 0.94, 0.82)
	lamp.light_energy = 2.1
	lamp.omni_range = 9.0
	lamp.omni_attenuation = 1.6
	lamp.shadow_enabled = true
	add_child(lamp)
	var cool := OmniLight3D.new()
	cool.position = ROOM + Vector3(0, 1.0, -2.5)
	cool.light_color = Color(0.55, 0.66, 0.74)
	cool.light_energy = 1.0
	cool.omni_range = 5.0
	add_child(cool)
	# the sideways copy's lamp shines down through the hatch onto the water
	var spot := SpotLight3D.new()
	spot.position = DOOR + Vector3(0, 0.6, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	spot.light_color = Color(1.0, 0.92, 0.78)
	spot.light_energy = 3.0
	spot.spot_range = 16.0
	spot.spot_angle = 34.0
	add_child(spot)
	var inner := OmniLight3D.new()
	inner.position = vis_xf * Vector3(0, 2.3, 3.2)
	inner.light_color = Color(1.0, 0.94, 0.82)
	inner.light_energy = 1.2
	inner.omni_range = 4.0
	add_child(inner)
	var bounce := OmniLight3D.new()
	bounce.position = DOOR + Vector3(0, -2.6, 0)
	bounce.light_color = Color(0.9, 0.8, 0.62)
	bounce.light_energy = 0.45
	bounce.omni_range = 9.0
	add_child(bounce)
	var shaft := Geo.shaft_mesh(1.0, 0.43, 1.8, 1.0, 4.5, 0.1, Color(0.022, 0.019, 0.015, 1.0))
	shaft.position = Vector3(DOOR.x, SEA, DOOR.z)
	add_child(shaft)
	add_note("l7_card", "Water-stained card", "Tucked between swollen books. Someone's survival notes, in your own paraphrase:\n\n" +
		"- This room is home base. Keep every trip into the water short.\n- Tie a rope or ladder from the doorway down to the water before you go: nothing else gets you back up.\n" +
		"- The air up here lets you hold your breath far longer than you should be able to.\n- The cold is cruel but slow.\n" +
		"- Two things live down there. Loud noise hurts the one near the surface; light hurts the one in the black.",
		ROOM + Vector3(-2.3, 1.3, 2.0), Vector3(0.3, 0.3, 0.3))
	add_interactable(ROOM + Vector3(-2.3, 0.9, 2.6), Vector3(0.3, 0.6, 0.6), "Pull out a book", func(_p):
		Overlay.toast("The cover is blank. The pages have swollen into a single block; whatever it was, it came from somewhere else.", 4.0))
	add_interactable(ROOM + Vector3(-1.15, 0.2, 0.6), Vector3(0.7, 0.4, 0.7), "Tie the rope ladder to the doorframe and drop it through", func(_p):
		if not rope:
			_drop_rope(true))
	var kc := kit("Coil")
	for i in 5:
		kc.cylinder(ROOM + Vector3(-1.15, 0.03 + i * 0.045, 0.6), 0.32 - i * 0.03, 0.045, "l7_rope", 10, false, true)
	kc.commit()


func _drop_rope(announce: bool) -> void:
	rope = true
	for n in rope_nodes:
		if is_instance_valid(n):
			n.queue_free()
	rope_nodes.clear()
	var k := kit("RopeLadder")
	rope_nodes.append(k.root)
	# room frame: the ladder runs out of the doorway, "down" to the sideways sea
	for sx in [-0.22, 0.22]:
		k.box(ROOM + Vector3(sx, 0.03, -2.55), Vector3(0.03, 0.03, 4.5), "l7_rope", GeoKit.ALL, false)
	for i in 14:
		k.box(ROOM + Vector3(0, 0.035, -0.5 - i * 0.3), Vector3(0.44, 0.03, 0.04), "l7_wood", GeoKit.ALL, false)
	# ocean frame: hangs from the hatch edge to below the surface
	var lx := DOOR.x - 0.8
	for sz in [-0.22, 0.22]:
		k.box(Vector3(lx, SEA + 1.5, DOOR.z + sz), Vector3(0.03, 6.0, 0.03), "l7_rope", GeoKit.ALL, false)
	for i in 19:
		k.box(Vector3(lx, SEA - 1.3 + i * 0.3, DOOR.z), Vector3(0.04, 0.03, 0.44), "l7_wood", GeoKit.ALL, false)
	k.box(Vector3(lx - 0.06, SEA + 1.8, DOOR.z), Vector3(0.04, 5.6, 0.5), "l7_rope", 0, true)
	k.commit()
	var lad := LadderVolume.new()
	add_child(lad)
	lad.setup(Vector3(lx - 0.1, SEA - 2.2, DOOR.z - 0.4), Vector3(lx + 0.75, SEA + 4.4, DOOR.z + 0.4))
	rope_nodes.append(lad)
	if announce:
		if SessionState.is_story():
			SaveService.set_flag(stable_id, "rope", true)
		Overlay.toast("The rope ladder unrolls out of the doorway and down to the water. It is the only way back up.", 4.5)


# ------------------------------------------------------------ the ocean

func _ocean() -> void:
	sea = WaterVolume.new()
	sea.name = "Ocean"
	add_child(sea)
	sea.setup(Vector3(-6000, Geo.FLOOR - 20.0, -6000), Vector3(6000, SEA, 6000), "l7_sea", false)
	sea.tint = Color(0.1, 0.3, 0.36)
	surf = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	pm.subdivide_width = 179
	pm.subdivide_depth = 179
	surf.mesh = pm
	surf.material_override = MatLib.get_mat("l7_sea")
	surf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surf)
	snow = CPUParticles3D.new()
	snow.amount = 700
	snow.lifetime = 14.0
	snow.preprocess = 14.0
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(16, 9, 16)
	snow.direction = Vector3(0.2, -1, 0.1)
	snow.spread = 40.0
	snow.gravity = Vector3(0, -0.04, 0)
	snow.initial_velocity_min = 0.02
	snow.initial_velocity_max = 0.12
	snow.local_coords = false
	var qm := QuadMesh.new()
	qm.size = Vector2(0.035, 0.035)
	var sm := StandardMaterial3D.new()
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.85, 0.9, 0.88, 0.55)
	sm.roughness = 1.0
	qm.material = sm
	snow.mesh = qm
	snow.visible = false
	add_child(snow)
	sun = DirectionalLight3D.new()
	sun.name = "DimNaturalLight"
	sun.rotation_degrees = Vector3(-38, 150, 0)
	sun.light_color = Color(0.72, 0.8, 0.86)
	sun.light_energy = 0.0
	sun.shadow_enabled = false
	add_child(sun)


# --------------------------------------------------------------- chunks


func _build_chunk(cx: int, cz: int, v: int, node: Node3D) -> Dictionary:
	return Build.build_chunk(self, geo, level_seed, cx, cz, v, node)


# ---------------------------------------------------------------- exits

func _exits() -> void:
	if qa_fixture:
		# QA FIXTURE ONLY: a copy of the Level 9 floor door in the entrance-room
		# floor, so the walker bot can fire L007>L009#3 through normal logic.
		var k := kit("QAFixture")
		for i in 5:
			k.box(ROOM + Vector3(-1.95 + i * 0.2, 0.012, 2.4), Vector3(0.18, 0.024, 1.3), "l7_door", GeoKit.ALL, false)
		k.commit()
		var t := add_exit("L007>L009#3", "interact", ROOM + Vector3(-1.55, 1.0, 2.4), Vector3(1.4, 2.0, 1.6), "Open the wooden door in the floor and go through")
		if t:
			qa_routes.append({"edge": "L007>L009#3", "target": ROOM + Vector3(-1.55, 0.05, 2.4), "note": "QA fixture: Level 9 floor door copied into the entrance room"})
		return
	var inner: Vector3 = get_meta("cave_inner")
	add_exit("L007>L008#1", "walk_in", inner, Vector3(7, 7, 8), "")
	add_exit("L007>L009#3", "interact", RING + Vector3(0, 1.2, 0), Vector3(3.0, 3.2, 3.0), "Open the wooden door in the platform and go through")
	var ab := add_exit("L007>L083#2", "condition", Vector3(Geo.AX, SEA + Z_MID - 80.0, Geo.AZ), Vector3(2400, 170, 2400), "")
	if ab:
		ab.condition = func() -> bool: return abyss_t >= 115.0


# ---------------------------------------------------------------- audio

func _audio() -> void:
	_beds["hum"] = sound.emitter("fluorescent_hum", ROOM + Vector3(0, 2.4, 3.2), {"base": 60.0, "rasp": 0.25}, -18.0, 9.0)
	_beds["door"] = sound.emitter("water_bed", ROOM + Vector3(0, 1.0, -1.5), {"bright": 650.0}, -10.0, 9.0)
	_beds["lap"] = sound.bed("water_bed", {"bright": 760.0}, -60.0)
	_beds["hall"] = sound.bed("room_tone", {"cutoff": 150.0, "rumble": 0.25}, -24.0)
	_beds["deep"] = sound.bed("pad", {"root": 41.2, "chord": [0, 1, 6, 13], "bright": 0.05}, -60.0)
	_beds["bubble"] = sound.bed("water_bed", {"bright": 200.0}, -60.0)
	_beds["heart"] = sound.bed("heartbeat", {}, -60.0)
	sound.oneshot("drip", {"freq": 900.0}, 9.0, 22.0, 6.0, "[a drip falls from the concrete]", -16.0)


# -------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[waves, close, through the doorway] [water soaks the carpet]", 5.0)
	checkpoint("room")


func _say(key: String, text: String, secs: float = 3.5) -> void:
	if not _said.has(key):
		_said[key] = true
		Overlay.subtitle(text, secs)


func _strike_pipe(_p: Variant, at: Vector3) -> void:
	sound.play_at("pipe_clank", {"f": 96.0}, at, 6.0, "[the pipe rings out like a bell — a pained roar below, then quiet]")
	tiny = 0.0
	tiny_sub = 45.0


func _flip_to_ocean() -> void:
	_flip_cd = 2.0
	var lx: float = clampf((player.global_position - ROOM).x, -0.2, 0.2)
	player.velocity = Vector3(0, -2.5, 0)
	player.global_position = Vector3(DOOR.x, SEA + 2.45, DOOR.z + lx)
	player.rotation = Vector3(0, -PI * 0.5, 0)
	player.look_pitch = deg_to_rad(-70.0)
	player.head.rotation = Vector3(player.look_pitch, 0, 0)
	sound.play_at("splash", {}, Vector3(DOOR.x, SEA, DOOR.z), -4.0)
	Overlay.subtitle("[gravity wrenches toward the doorway — you fall into the sea]", 3.0)
	if not rope:
		Overlay.toast("Nothing hangs from the doorway. With no rope or ladder there is no way back up.", 5.0)


func _flip_to_room() -> void:
	_flip_cd = 2.0
	player.velocity = Vector3.ZERO
	player.global_position = ROOM + Vector3(0, 0.05, 1.35)
	player.rotation = Vector3(0, PI, 0)
	player.look_pitch = 0.0
	player.head.rotation = Vector3.ZERO
	player.on_ladder = false
	Overlay.subtitle("[you haul yourself over the threshold and the room's gravity takes you]", 3.0)
	checkpoint("room")


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam else p + Vector3.UP * 1.6
	_flip_cd = maxf(0.0, _flip_cd - delta)
	var in_room := p.y > SEA + 30.0
	var ry := eye.y - SEA
	surf.position = Vector3(snappedf(eye.x, 5.0), SEA, snappedf(eye.z, 5.0))
	var under := not in_room and ry < -0.05
	snow.visible = under
	snow.position = eye
	if player.frozen and under != _under:
		Overlay.set_underwater(under, sea)
	_under = under
	var desat := 0.0
	var vign := 0.0
	if in_room:
		var lp := p - ROOM
		if _flip_cd <= 0.0 and lp.z < 0.85 and lp.z > -0.4 and absf(lp.x) < 0.6 and not player.frozen:
			_flip_to_ocean()
		elif lp.z < 1.8 and absf(lp.x) < 0.9:
			_say("pull", "[a sideways pull from the doorway — the water below is 'down' out there]", 3.0)
			player.head.rotation.z = lerpf(player.head.rotation.z, 0.06 * (1.8 - lp.z), clampf(delta * 4.0, 0.0, 1.0))
		else:
			player.head.rotation.z = lerpf(player.head.rotation.z, 0.0, clampf(delta * 4.0, 0.0, 1.0))
		if lp.z > 10.2 and lp.y > 2.6:
			_say("stairs", "[total darkness above; you cannot find the way back up to Level 6]", 4.0)
		cold = maxf(0.0, cold - delta * 4.0)
		_env_room()
	else:
		if _flip_cd <= 0.0 and rope and player.on_ladder and p.y > SEA + 2.2 and absf(p.z - DOOR.z) < 0.8 and absf(p.x - DOOR.x) < 1.5:
			_flip_to_room()
			return
		_env_ocean(ry)
		if player.swimming:
			cold += delta * (1.0 + clampf(-ry / 200.0, 0.0, 2.0))
		else:
			cold = maxf(0.0, cold - delta * 2.0)
		if cold > 1500.0 and not player.dead:
			player.hurt(delta * 2.0, "the cold, after far too long in the water")
		desat = clampf(cold / 900.0, 0.0, 0.4)
		_entities(delta, eye, ry)
		vign = clampf(abyss_t / 115.0, 0.0, 1.0)
	Overlay.set_screen_effect("desaturate", maxf(desat, vign * 0.8))
	Overlay.set_screen_effect("blackout", clampf((vign - 0.75) * 2.4, 0.0, 0.85))
	_mix(delta, in_room, under, ry)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		player.camera.h_offset = randf_range(-0.03, 0.03) * _shake
		player.camera.v_offset = randf_range(-0.03, 0.03) * _shake


func _entities(delta: float, eye: Vector3, ry: float) -> void:
	var swim_loud := player.swimming and Input.is_action_pressed("sprint")
	# Tiny: Daylight/Twilight only, mostly at his ring; very strong hearing
	tiny_sub = maxf(0.0, tiny_sub - delta)
	var dr := eye.distance_to(RING)
	if ry < 0.0 and ry > Z_TWI and dr < 75.0 and tiny_sub <= 0.0:
		tiny += delta / 80.0 * (2.4 if swim_loud else 1.0)
		if tiny > 0.3:
			_say("tiny1", "[something enormous shifts in the dark under the platform]", 3.5)
		if tiny > 0.7:
			_say("tiny2", "[a deep groan — it is listening for you]", 3.5)
			_shake = maxf(_shake, 0.6)
	else:
		tiny = maxf(0.0, tiny - delta / 30.0)
	_groan_t -= delta
	if tiny > 0.25 and _groan_t <= 0.0:
		_groan_t = randf_range(4.0, 9.0) * (1.4 - tiny)
		sound.play_at("creak", {"freq": 52.0}, RING + Vector3(randf_range(-20, 20), -10, randf_range(-20, 20)), -6.0 + tiny * 8.0, "[a deep groan]")
	if tiny >= 1.0 and not player.dead:
		player.hurt(1000.0, "Tiny heard you. A fight with him is a death sentence")
	# The Thing: Midnight Zone and upper Abyss; its eyes cannot stand light
	var in_dark := ry < Z_TWI and ry > Z_MID - 120.0 and player.swimming
	if in_dark:
		if player.flashlight.visible:
			if thing > 0.35:
				_say("recoil", "[something vast recoils from your light]", 3.0)
			thing = maxf(0.0, thing - delta / 18.0)
		else:
			thing += delta / 90.0
			if thing > 0.5:
				_say("thing", "[a pressure wave rolls past you in the black]", 3.5)
				_shake = maxf(_shake, 0.4)
	else:
		thing = maxf(0.0, thing - delta / 20.0)
	_boom_t -= delta
	if thing > 0.45 and _boom_t <= 0.0:
		_boom_t = randf_range(6.0, 12.0)
		sound.play_at("distant_boom", {}, eye + Vector3(randf_range(-30, 30), -15, randf_range(-30, 30)), -2.0, "[something moves in the dark]")
	if thing >= 1.0 and not player.dead:
		player.hurt(1000.0, "The Thing On Level 7 found you in the dark")
	# The Abyss: nobody has stayed down longer than about two minutes
	if ry < Z_MID and player.swimming:
		abyss_t += delta
		if abyss_t > 60.0:
			_say("abyss", "[the pressure presses in; your vision narrows]", 4.0)
	else:
		abyss_t = maxf(0.0, abyss_t - delta * 3.0)


func _env_ocean(ey: float) -> void:
	var e := environment
	var amb := Color(0.46, 0.52, 0.56)
	var fogc := Color(0.25, 0.29, 0.32)
	var dens := 0.0052
	var en := 0.62
	var expo := 1.0
	var fl := 0.0
	if ey <= -0.05:
		var dep := -ey
		var a := clampf(dep / -Z_DAY, 0.0, 1.0)
		var b := clampf((dep + Z_DAY) / (Z_DAY - Z_TWI), 0.0, 1.0)
		var c := clampf((dep + Z_TWI) / 40.0, 0.0, 1.0)
		fogc = Color(0.13, 0.26, 0.3).lerp(Color(0.075, 0.16, 0.19), a).lerp(Color(0.006, 0.016, 0.022), b).lerp(Color(0, 0, 0), c)
		amb = Color(0.32, 0.5, 0.56)
		en = lerpf(1.0, 0.72, a) * (1.0 - b * 0.92) * (1.0 - c)
		dens = lerpf(0.017, 0.024, a) - 0.006 * b
		expo = 1.0 + 0.35 * b
		fl = 1.0
		Overlay.fx_mat.set_shader_parameter("water_tint", Vector3(0.16, 0.36, 0.42).lerp(Vector3(0.09, 0.2, 0.24), a).lerp(Vector3(0.0, 0.012, 0.018), b))
	e.background_color = fogc
	e.ambient_light_color = amb
	e.ambient_light_energy = en
	e.fog_enabled = true
	e.fog_light_color = fogc
	e.fog_light_energy = 1.0
	e.fog_density = dens
	e.tonemap_exposure = expo
	e.ssr_enabled = ey > -0.05 and Settings.quality() >= 1
	e.adjustment_saturation = 0.9
	e.adjustment_contrast = 1.06
	sun.light_energy = 0.32 if ey > -0.05 else 0.25 * clampf(1.0 + ey / 60.0, 0.0, 1.0)
	player.flashlight.light_energy = lerpf(2.2, 6.0, fl)
	player.flashlight.spot_range = lerpf(22.0, 28.0, fl)
	player.flashlight.spot_angle = lerpf(26.0, 34.0, fl)


func _env_room() -> void:
	var e := environment
	e.background_color = Color(0, 0, 0)
	e.ambient_light_color = Color(0.5, 0.48, 0.44)
	e.ambient_light_energy = 0.07
	e.fog_enabled = false
	e.tonemap_exposure = 1.05
	e.ssr_enabled = Settings.quality() >= 1
	e.ssr_max_steps = 48
	e.ssr_depth_tolerance = 0.3
	e.adjustment_saturation = 0.95
	e.adjustment_contrast = 1.08
	sun.light_energy = 0.0
	player.flashlight.light_energy = 2.2
	player.flashlight.spot_range = 22.0
	player.flashlight.spot_angle = 26.0


func _mix(delta: float, in_room: bool, under: bool, ey: float) -> void:
	var t := clampf(delta * 2.0, 0.0, 1.0)
	var deep := clampf(-ey / 300.0, 0.0, 1.0)
	var target := {
		"lap": -60.0 if in_room else (-30.0 if under else -11.0),
		"hall": -26.0 if in_room else (-16.0 + deep * 6.0 if under else -20.0),
		"deep": -60.0 + 54.0 * thing,
		"bubble": -60.0 if ey > Z_TWI or in_room else lerpf(-34.0, -8.0, clampf((Z_TWI - ey) / 200.0, 0.0, 1.0)),
		"heart": -60.0 + 50.0 * maxf(maxf(tiny, thing), clampf(abyss_t / 115.0, 0.0, 1.0)),
	}
	for key in target.keys():
		var pl: Node = _beds[key]
		pl.volume_db = lerpf(pl.volume_db, target[key], t)


# ----------------------------------------------------------- QA captures

func qa_capture_plan() -> Array:
	var plan: Array = []
	var ap: Vector3 = get_meta("abyss_piece")
	plan.append({"name": "room", "pos": ROOM + Vector3(-1.05, 1.55, 6.0), "target": ROOM + Vector3(0.2, 0.9, -2.0),
		"prepare": func():
			_drop_rope(false)
			var f := get_node_or_null("QAFixture")
			if f:
				f.visible = false})
	plan.append({"name": "hatch", "pos": Vector3(-1.7, SEA + 0.4, 1.5), "target": DOOR + Vector3(0.35, 0.6, -0.15)})
	plan.append({"name": "hatch_wide", "pos": Vector3(5.0, SEA + 0.45, 6.5), "target": DOOR + Vector3(-0.4, 0.2, 0)})
	plan.append({"name": "sea", "pos": Vector3(3.0, SEA + 0.5, 1.0), "target": FORT + Vector3(0, 2.0, 0)})
	plan.append({"name": "ring", "pos": RING + Vector3(8, 7, 9), "target": RING + Vector3(0, 0, 0), "flashlight": true})
	plan.append({"name": "cave", "pos": mouth + Vector3(13, 2, 5), "target": mouth + Vector3(-4, -1, 0), "flashlight": true})
	plan.append({"name": "abyss", "pos": ap + Vector3(-57, 3.5, 2), "target": ap + Vector3(-40, 3, -15), "flashlight": true})
	return plan
