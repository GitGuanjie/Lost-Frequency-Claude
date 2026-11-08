extends LevelBase
## Level 10.1 — "Corpse Lake" (Backrooms Wikidot rev 66, accessed 2026-11-04;
## cite: Kitty Rika, CC BY-SA 3.0). Dossier: docs/canon/levels/L010_1.md.
## CONTENT WARNING (page): radiation death and body horror. The game keeps all
## of it implied: captions, screen effects and fades, never bodies or gore.
##
## PLAN (v2.0 rebuild)
## SOURCE: a manmade lake inside Level 10, ~40 km from Malt Town, made by
## dumping the melt of Object 24 masks; the liquid is radioactive, toxic and
## carnivorous, seeks out the nearest living animal and drains blood on
## contact; once black, now murky crimson; UV-only veins and a central black
## area darker than Vantablack; plants are never harmed (grass on the banks,
## algae and trichodesmium in the lake); ~7 Sv/h, standing beside it for an
## hour is fatal, three sickness stages within 10/30/60 minutes of exposure,
## even through a suit; radiation deadly 1 cm inside the zone and absent
## outside; barbed-wire fence and warning signs since 10 Aug 2021; entrants are
## "considered deceased"; the substance was carried in nuclear waste barrels
## and dumped (21:20); the depression held the entrance to an undocumented
## level nobody returned from; high winds; a Geiger counter sound.
## ADAPTATION: the lake is scaled to ~350 m across (page: 0.8 cubic miles) and
## sits in a grass basin ~12 m below the Level 10 plain; the fence ring runs
## along the rim 86 m from the water; the gate, the M.E.G. notice board, the
## Geiger counter left on it and the abandoned barrels at the dump point are
## ours; the "seeking" is one slow swell that follows you along the shore;
## walking 146 m out from the water (anywhere) returns you to Level 10 (edge
## L010_1>L010#2); the undocumented level under the lake is never an exit.
## Mechanic: zone state + exposure clock (10/30/60 min) + Geiger + seeker +
## contact. Verticality: rim plateau -> bank -> waterline, a ramp down to the
## dump point. Helpers: L010_1_land.gd (terrain), L010_1_dress.gd (dressing).

const LAND := preload("res://levels/L010_1/L010_1_land.gd")
const DRESS := preload("res://levels/L010_1/L010_1_dress.gd")
const CS := 64.0
const STAGES := [600.0, 1800.0, 3600.0]

var land
var dress
var world: ChunkWorld
var lake: WaterVolume
var start := Vector3.ZERO
var exit_t: ExitTrigger
var inside := false
var contaminated := false
var t_cont := 0.0
var stage := 0
var has_geiger := false
var geiger: AudioStreamPlayer
var beds := {}
var contact_t := -1.0
var dead_sent := false
var said := {}
var seeker: Node3D
var seek_pos := Vector3.ZERO
var seek_act := 0.0
var ripple_mat: ShaderMaterial
var d_player := 999.0
var gust := 0.2
var gust_t := 6.0
var _creak_t := 8.0
var freeze_seeker := false


func build() -> void:
	land = LAND.new()
	rules["view_distance"] = 2400.0
	rules["reverb_room"] = 0.05
	rules["reverb_wet"] = 0.02
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -60.0
	var top := Color(0.29, 0.30, 0.32)
	var hor := Color(0.50, 0.50, 0.49)
	outdoor_env(top, hor, hor, Vector2(38.0, 150.0), Color(0.92, 0.88, 0.82), 0.9, Color(0.47, 0.46, 0.44), 0.0018)
	var sky_sh := Shader.new()
	sky_sh.code = SKY
	var sm := ShaderMaterial.new()
	sm.shader = sky_sh
	environment.sky.sky_material = sm
	environment.ambient_light_sky_contribution = 0.6
	environment.ambient_light_energy = 0.7
	environment.fog_sky_affect = 0.25
	environment.fog_aerial_perspective = 0.3
	environment.tonemap_exposure = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	environment.adjustment_contrast = 1.08
	sun.shadow_blur = 2.5
	sun.light_specular = 0.25
	sun.directional_shadow_max_distance = 110.0
	DRESS.define_materials()
	MatLib.register("l10l_liquid", MatLib.water({"shallow_color": Color(0.25, 0.026, 0.022), "deep_color": Color(0.12, 0.01, 0.01),
		"absorption": 3.0, "clarity": 0.02, "wave_height": 0.012, "wave_scale": 0.16, "wave_speed": 0.06,
		"normal_strength": 0.16, "refraction": 0.004, "foam_amount": 0.0, "roughness_value": 0.34, "dark_surface": 0.0}))
	dress = DRESS.new(self, land)
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	land.build_meshes(geo, land.make_material())
	lake = WaterVolume.new()
	lake.name = "CorpseLake"
	add_child(lake)
	lake.setup(Vector3(-205.0, -14.0, -205.0), Vector3(205.0, 0.0, 205.0), "l10l_liquid", true)
	lake.fog_color = Color(0.12, 0.0, 0.0)
	lake.fog_density = 0.9
	lake.tint = Color(0.5, 0.02, 0.02)
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	var k := kit("ExclusionFence")
	dress.fence(k, props)
	k.commit()
	dress.dump_site(props, rng)
	dress.lake_surface_features(props, rng)
	dress.tree_lines(props, rng)
	_seeker()
	start = Vector3(land.track_x(land.shore_s + 98.0), 0.0, land.shore_s + 98.0)
	start.y = land.h(start.x, start.z) + 0.05
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.build_around(start, 2)
	_notes()
	_sounds()
	exit_t = add_exit("L010_1>L010#2", "walk_in", _exit_center(start), Vector3(40.0, 8.0, 3.0), "")
	_place_exit(start)
	for tag in ["start", "from_L010"]:
		add_arrival(tag, start, 0.0)
	var fall_a := PI * 0.5 - 0.42
	var fr: float = land.shore_r(fall_a) + 24.0
	var fp := Vector3(cos(fall_a) * fr, 0.0, sin(fall_a) * fr)
	add_arrival("from_L028", Vector3(fp.x, land.h(fp.x, fp.z) + 1.4, fp.z), rad_to_deg(atan2(fp.x, fp.z)))
	add_landmark("Exclusion Zone gate and M.E.G. board", dress.gate_pos)
	add_landmark("Dump point (abandoned waste barrels)", land.dump)
	add_landmark("Cut fence section (north-west)", dress.breach_pos)
	add_landmark("The black centre of the lake", Vector3(-8, 0, -14))
	_shots()


const SKY := """
shader_type sky;
uniform vec3 top : source_color = vec3(0.29, 0.30, 0.32);
uniform vec3 hor : source_color = vec3(0.50, 0.50, 0.49);
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { s += a * vn(p); p = p * 2.07 + vec2(1.7, 9.2); a *= 0.5; } return s; }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec2 uv = d.xz / (d.y + 0.1) + vec2(TIME * 0.004, TIME * 0.002);
	float c = fbm(uv * 0.8 + vec2(3.1, 7.7));
	float c2 = fbm(uv * 2.4 + vec2(c * 2.0, 1.3));
	vec3 col = mix(hor, top, smoothstep(0.0, 0.55, y));
	col *= 0.72 + 0.4 * c + 0.14 * c2 - 0.14 * smoothstep(0.55, 0.85, c);
	col = mix(hor, col, smoothstep(0.0, 0.18, y));
	if (d.y < 0.0) { col = hor * 0.92; }
	COLOR = col;
}
"""


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var c := Vector2(ox + CS * 0.5, oz + CS * 0.5)
	var dc: float = land.dist(c.x, c.y)
	if dc > land.EXIT_D + 70.0 or dc < -110.0:
		return {}
	land.collision_tile(node, ox, oz, int(CS))
	for tz in 4:
		for tx in 4:
			dress.veg_tile(node, ox + tx * 16.0, oz + tz * 16.0, 16.0, hash([cx, cz, tx, tz, level_seed]))
	_scatter_rocks(node, ox, oz, hash([cx, cz, level_seed]))
	return {"d": dc}


## A few field stones on the banks and rim; per-seed, so the layout varies.
func _scatter_rocks(node: Node3D, ox: float, oz: float, sd: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	for i in 3:
		var x := ox + r.randf_range(2.0, CS - 2.0)
		var z := oz + r.randf_range(2.0, CS - 2.0)
		var d: float = land.dist(x, z)
		if d < 4.0 or d > land.CROP_D - 4.0 or land.track_w(x, z) > 0.0 or land.apron_w(x, z) > 0.0:
			continue
		if Vector2(x - dress.gate_pos.x, z - dress.gate_pos.z).length() < 14.0 or absf(x - land.track_x(z)) < 10.0:
			continue
		var s := r.randf_range(0.5, 1.4)
		Props.place(self, node, "ph/boulder_01", Vector3(x, land.h(x, z) - s * 0.25, z), r.randf_range(0, 360), s, s > 0.8)


# ---------------------------------------------------------------- the lake reacts

func _seeker() -> void:
	seeker = Node3D.new()
	seeker.name = "Seeker"
	add_child(seeker)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 24
	sm.rings = 10
	dome.mesh = sm
	dome.name = "Swell"
	dome.material_override = MatLib.get_mat("l10l_bulge")
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seeker.add_child(dome)
	var rp := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(16, 16)
	rp.mesh = pm
	ripple_mat = (MatLib.get_mat("l10l_ripple") as ShaderMaterial).duplicate()
	rp.material_override = ripple_mat
	rp.position.y = 0.03
	rp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	seeker.add_child(rp)
	var a := rng.randf_range(0.0, TAU)
	seek_pos = Vector3(cos(a) * 70.0, 0.0, sin(a) * 70.0)
	_seeker_pose()


func _seeker_pose() -> void:
	seeker.position = Vector3(seek_pos.x, 0.0, seek_pos.z)
	var dome := seeker.get_node("Swell") as MeshInstance3D
	dome.scale = Vector3(3.2, 0.03 + 0.55 * seek_act, 3.2)
	dome.visible = seek_act > 0.02
	ripple_mat.set_shader_parameter("strength", seek_act)


func _update_seeker(delta: float, p: Vector3) -> void:
	var a := atan2(p.z, p.x)
	var target: Vector3 = Vector3(cos(a), 0.0, sin(a)) * (land.shore_r(a) - 2.5)
	var hunting := d_player < 34.0
	seek_act = move_toward(seek_act, 1.0 if hunting else 0.0, delta * (0.25 if hunting else 0.08))
	var to := target - seek_pos
	to.y = 0.0
	var speed := 1.7 if hunting else 0.25
	if to.length() > 0.05:
		seek_pos += to.normalized() * minf(speed * delta, to.length())
	# never leave the liquid
	var sa := atan2(seek_pos.z, seek_pos.x)
	var lim: float = land.shore_r(sa) - 2.5
	var r := Vector2(seek_pos.x, seek_pos.z).length()
	if r > lim:
		seek_pos *= lim / r
	_seeker_pose()
	var gap := Vector2(seek_pos.x - p.x, seek_pos.z - p.z).length()
	if hunting and gap < 45.0:
		_say("seek", "[out on the surface a slow swell moves against the wind - toward you]", 5.0)
	if gap < 4.4 and d_player < 1.8 and seek_act > 0.8:
		_contact("It reached the shore where you stood")


# ---------------------------------------------------------------- notes and items

func _notes() -> void:
	var bp: Vector3 = dress.board_pos
	add_note("l101_overseer", "Notice, Overseer-C (10 August 2021)", "To all wanderers and M.E.G. operatives.\n\nFrom 10 August 2021 nobody crosses the barbed-wire fence without express permission from the Overseers AND working, high-grade radiation gear. Fencing and warning signs now mark the whole perimeter.\n\nAnyone who crosses without them is to be considered deceased. The M.E.G. will not come for you.", bp + Vector3(-0.55, 1.62, 0.05), Vector3(0.4, 0.5, 0.2), false)
	add_note("l101_summary", "Level 10.1 - fact sheet (M.E.G.)", "A manmade lake in Level 10, about 40 km (20 miles) from Malt Town.\n\nIt was made by trying to destroy Object 24 masks with heat. The melt became a semi-sentient liquid: radioactive, toxic and carnivorous. It seeks out the nearest living animal.\n\nAbout 700 roentgens per hour (7 Sv/h) within a square mile of the surface. Standing beside it for more than an hour is fatal.\n\nIt was pitch black when it was dumped. It is a murky crimson now.\n\nIt does not touch plants. Grass grows to the water; algae thrive in it.", bp + Vector3(-0.02, 1.62, 0.05), Vector3(0.4, 0.5, 0.2), false)
	add_note("l101_stages", "Exposure sheet (abridged)", "[Content warning: the full M.E.G. account is graphic.]\n\nAny exposure counts, even through a suit, and even 1 cm inside the fence. Outside it, nothing has been measured.\n\nStage one, within 10 minutes: nausea, dizziness, headache, fever.\nStage two, within 30 minutes: violent sickness, collapse.\nStage three, before 60 minutes: death.\n\nThere is no treatment.\n\nDirect contact is faster: the liquid sets like glue on skin and drains the blood.", bp + Vector3(0.52, 1.62, 0.05), Vector3(0.4, 0.5, 0.2), false)
	add_note("l101_casualties", "Casualty list (first entries)", "15 Dec 2020 - initial experiment:\nHolly S. Surview, Volunteer Specialist\nJames A. Lucas, Volunteer Specialist\nJake Jonas, Volunteer Specialist\nSamantha Bluewood, Volunteer Specialist\nToga Hajime, Volunteer intern\n\nMay 2021 - Malt Town, 40 km away:\n\"Radiation poisoning, spread by unusual winds.\"\n\nThe list goes on for two more pages.", bp + Vector3(0.78, 1.45, 0.05), Vector3(0.3, 0.4, 0.2), false)
	add_interactable(bp + Vector3(0.0, 1.0, 0.18), Vector3(1.6, 0.4, 0.5), "Take the Geiger counter from the shelf", _take_geiger)
	var dp: Vector3 = land.dump + Vector3(-9.0, 0.0, 9.5)
	add_note("l101_depression", "Notice to the citizens of Malt Town (4 April 2021)", "This site was chosen because the original depression held an entrance to an undocumented level. Nobody who went in has ever been heard from again.\n\nThe hope was that the liquid would drain down into it. It did not. The lake has instead drawn up liquid from below - presumably water - and grown from about 2 cubic metres when it was dumped to some 0.8 cubic miles.\n\n- compiled by the Chief M.E.G. Recordkeeper, Base Alpha", Vector3(dp.x, land.h(dp.x, dp.z) + 0.36, dp.z), Vector3(0.5, 0.2, 0.4), true)
	var sp: Vector3 = land.dump + Vector3(8.4, 0.0, 10.6)
	add_note("l101_plants", "Study of recovered aquatic plant specimens (27 July 2021)", "Every specimen collected from the lake carries microscopic particles of the substance, and each particle is as active as the lake itself.\n\nRadiation and volume both rise with the amount of water nearby.\n\nThe plants themselves are untouched. Nothing else that lives here is.", Vector3(sp.x, land.h(sp.x, sp.z) + 0.3, sp.z), Vector3(0.4, 0.2, 0.4), true)
	var wl: Vector3 = land.dump + Vector3(1.5, 0.0, -2.0)
	add_interactable(Vector3(wl.x, land.h(wl.x, wl.z) + 0.6, wl.z), Vector3(4.0, 1.2, 2.0), "Listen to the liquid", func():
		Overlay.subtitle("[it makes no sound you can hear. The M.E.G. recorded a ~30 PHz emission while it fed - far beyond any ear]", 6.0))


func _take_geiger() -> void:
	if has_geiger:
		Overlay.subtitle("[the Geiger counter is clipped to your jacket]", 2.5)
		return
	has_geiger = true
	Overlay.subtitle("[a Geiger counter, left on the board by a checkup team. It is silent out here.]", 4.5)
	SaveService.record_discovery(stable_id, "l101:geiger", "Took the Geiger counter from the Exclusion Zone board.", "ADAPTATION")


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -22.0)
	beds["lap"] = sound.bed("water_bed", {"seconds": 8.0, "bright": 320.0}, -70.0)
	beds["heart"] = sound.bed("heartbeat", {}, -70.0)
	geiger = AudioStreamPlayer.new()
	geiger.stream = AudioSynth.get_stream("crackle", {"seconds": 2.4})
	geiger.bus = "SFX"
	geiger.volume_db = -60.0
	add_child(geiger)


# ---------------------------------------------------------------- exit

func _exit_center(p: Vector3) -> Vector3:
	var a := atan2(p.z, p.x)
	var r: float = land.shore_r(a) + land.EXIT_D
	var c := Vector3(cos(a) * r, 0.0, sin(a) * r)
	c.y = land.h(c.x, c.z) + 2.0
	return c


## One walk-in band that always sits across your bearing, 146 m from the water.
func _place_exit(p: Vector3) -> void:
	if exit_t == null:
		return
	var c := _exit_center(p)
	exit_t.global_position = c
	exit_t.rotation.y = atan2(c.x, c.z)


# ---------------------------------------------------------------- process

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	d_player = land.dist(p.x, p.z)
	_place_exit(p)
	var qa := SessionState.is_qa()
	inside = d_player < land.FENCE_D - 0.2
	if inside and not contaminated:
		contaminated = true
		_say("in", "[you are inside the Exclusion Zone. Here it is already a lethal dose.]", 5.0)
	if contaminated:
		t_cont += delta
		_stages(qa)
	if lake.contains(p + Vector3.UP * 0.15) and contact_t < 0.0:
		_contact("You touched the liquid")
	if contact_t >= 0.0:
		contact_t += delta
		Overlay.set_screen_effect("red_tint", clampf(contact_t * 0.25, 0.0, 0.6))
		Overlay.set_screen_effect("blackout", clampf((contact_t - 1.0) * 0.4, 0.0, 1.0))
		if contact_t > 3.5 and not dead_sent and not qa:
			dead_sent = true
			player.hurt(1000.0, "Corpse Lake: the liquid set around you like glue")
	if not freeze_seeker:
		_update_seeker(delta, p)
	_audio(delta, p)


func _contact(why: String) -> void:
	if contact_t >= 0.0:
		return
	contact_t = 0.0
	Overlay.glitch(0.6)
	Overlay.subtitle("[%s. It sets like glue the instant it touches skin, and it does not let go.]" % why, 6.0)


func _stages(qa: bool) -> void:
	var m := t_cont
	if stage == 0 and m >= STAGES[0]:
		stage = 1
		Overlay.subtitle("[ten minutes inside: nausea, dizziness, a headache that will not lift]", 5.0)
	elif stage == 1 and m >= STAGES[1]:
		stage = 2
		Overlay.subtitle("[thirty minutes: you are very sick now. Walking out will not change it.]", 5.0)
	elif stage == 2 and m >= STAGES[2] - 300.0:
		stage = 3
		Overlay.subtitle("[the edges of everything are going dark]", 5.0)
	if contact_t >= 0.0:
		return
	var s1 := smoothstep(STAGES[0] - 60.0, STAGES[0] + 60.0, m)
	var s2 := smoothstep(STAGES[1] - 120.0, STAGES[1] + 120.0, m)
	var s3 := smoothstep(STAGES[2] - 300.0, STAGES[2], m)
	Overlay.set_screen_effect("desaturate", s1 * 0.15 + s2 * 0.25)
	Overlay.set_screen_effect("vignette", 0.25 + s1 * 0.12 + s2 * 0.18)
	Overlay.set_screen_effect("red_tint", s2 * (0.06 + 0.05 * sin(m * 1.3)))
	Overlay.set_screen_effect("blackout", s3 * 0.85)
	if player.camera:
		player.camera.rotation.z = (s1 * 0.012 + s2 * 0.02) * sin(m * 0.7)
	if m >= STAGES[2] and not dead_sent and not qa:
		dead_sent = true
		player.hurt(1000.0, "Radiation from Corpse Lake - within the hour, as recorded")


func _audio(delta: float, p: Vector3) -> void:
	var k := minf(delta * 1.5, 1.0)
	gust_t -= delta
	if gust_t <= 0.0:
		gust_t = rng.randf_range(4.0, 11.0)
		gust = rng.randf_range(0.1, 0.75)
		MatLib.get_mat("l10l_veg").set_shader_parameter("gust", gust)
	_vol("wind", -26.0 + gust * 10.0, delta * 0.4)
	_vol("lap", lerpf(-70.0, -28.0, 1.0 - clampf(d_player / 22.0, 0.0, 1.0)), k)
	var hb := -70.0
	if stage >= 2 or contact_t >= 0.0:
		hb = -14.0
	_vol("heart", hb, k)
	# Geiger: silent outside the fence (canon: absent outside), roaring inside
	if has_geiger and inside:
		var near := 1.0 - clampf(d_player / land.FENCE_D, 0.0, 1.0)
		geiger.volume_db = lerpf(geiger.volume_db, lerpf(-16.0, -2.0, near), k)
		geiger.pitch_scale = 1.0 + near * 0.6
		if not geiger.playing:
			geiger.play()
	elif geiger.playing:
		geiger.stop()
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = rng.randf_range(9.0, 18.0)
		if p.distance_to(dress.gate_pos) < 60.0 and gust > 0.4:
			sound.play_at("creak", {"freq": 180.0}, dress.gate_pos + Vector3(2.6, 1.0, -1.0), -12.0, "")


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ---------------------------------------------------------------- QA stills

func _shots() -> void:
	var g: Vector3 = dress.gate_pos
	add_shot("gate_to_lake", start + Vector3(-0.8, 1.62, -3.0), Vector3(-14.0, 0.0, 30.0), {"flashlight": false})
	var dv: Vector3 = land.dump + Vector3(-6.0, 0.0, 15.0)
	dv.y = land.h(dv.x, dv.z) + 1.7
	add_shot("dump_point", dv, land.dump + Vector3(2.0, -1.2, -10.0), {"flashlight": false, "prepare": _prep_at.bind(dv)})
	var sa := PI * 0.5 - 0.6
	var sp: Vector3 = Vector3(cos(sa), 0, sin(sa)) * (land.shore_r(sa) + 8.0)
	sp.y = land.h(sp.x, sp.z) + 1.65
	add_shot("seeking_swell", sp, Vector3(sp.x * 0.86, -0.4, sp.z * 0.86), {"flashlight": false, "prepare": _prep_swell.bind(sp)})
	# a warning sign on the rim, the crimson basin behind it
	var best: Vector3 = dress.sign_posts[0]
	for sp2 in dress.sign_posts:
		if absf(atan2(sp2.z, sp2.x) - (PI * 0.5 + 0.35)) < absf(atan2(best.z, best.x) - (PI * 0.5 + 0.35)):
			best = sp2
	var out: Vector3 = Vector3(best.x, 0, best.z).normalized()
	var side := out.cross(Vector3.UP)
	var fp: Vector3 = best + out * 2.4 + side * 1.0
	fp.y = land.h(fp.x, fp.z) + 1.6
	add_shot("fence_sign_basin", fp, best - out * 70.0 + Vector3(0, -2.0, 0), {"flashlight": false, "prepare": _prep_at.bind(fp)})


func _prep_at(p: Vector3) -> void:
	world.build_around(p, 1)
	await get_tree().process_frame


func _prep_swell(p: Vector3) -> void:
	world.build_around(p, 1)
	var a := atan2(p.z, p.x)
	seek_pos = Vector3(cos(a), 0, sin(a)) * (land.shore_r(a) - 11.0)
	seek_act = 1.0
	_seeker_pose()
	freeze_seeker = true
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "one physical exit (walk back out to Level 10)", "ok": exits.size() == 1})
	out.append({"what": "spawn outside the fence (no exposure at arrival)", "ok": land.dist(player.global_position.x, player.global_position.z) > land.FENCE_D, "detail": land.dist(player.global_position.x, player.global_position.z)})
	out.append({"what": "not contaminated at start", "ok": not contaminated and t_cont == 0.0})
	out.append({"what": "lake surface is liquid (water volume) at the dump point", "ok": lake.contains(Vector3(land.dump.x, -0.3, land.dump.z - 9.0))})
	out.append({"what": "dump apron above the liquid", "ok": land.h(land.dump.x, land.dump.z) > 0.1})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
