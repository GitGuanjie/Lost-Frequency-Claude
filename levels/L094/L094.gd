extends LevelBase
## Level 94 - "Motion" (Backrooms Wikidot rev 77, accessed 2026-11-04; cite:
## Stretchsterz, Dr. Bierre and ShadowOfTheProphet, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L094.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: a large town, grass hills and a floating castle, all with a grainy,
## crafted, 1930s stop-motion look; the town is safe and empty by day; a big
## fountain in the centre flowing with Almond Water; tiny houses furnished
## 1930s-1950s; 1930s cars and milk vans of Almond Milk; siren poles that now
## and then play happy cartoon music; at night the music stops completely and
## the Animations come out and attack whatever they spot; Death Rats drawn in
## the same style; the hills go on forever with a few strange parked cars, a
## water tower of Almond Water and random furniture sets that are just a wall
## with furniture next to it; above the hills, the floating castle on a
## "Transparent Mountain"; some houses lead to Levels 7, 9 and 53.
## ADAPTATION: the town is a 4-street plan round a cobbled square (~190 m
## across) on a plateau, ringed by streamed hills; the day is 6 min and the
## night 3 min; the castle is seen but not reached (the page gives no route);
## three of the open houses (chosen per seed - the page does not say which)
## have a back door that opens somewhere else; houses hide you from the
## Animations, which are shown as ink-black rubber-hose cut-outs moving on
## "twos"; the other night entities the page lists are not shown.
## Mechanic: day/night with the music schedule, Animations that patrol and
## chase on sight, indoor cover, and the stepped "boil" of every surface.
## Verticality: corner houses with an upper floor and stair, the fountain's
## tiers, the hills and the water tower's ladder and catwalk.
## Helpers: L094_land.gd, L094_town.gd, L094_props.gd, L094_night.gd.

const LAND := preload("res://levels/L094/L094_land.gd")
const TOWN := preload("res://levels/L094/L094_town.gd")
const PROPS := preload("res://levels/L094/L094_props.gd")
const NIGHT := preload("res://levels/L094/L094_night.gd")
const CS := 64.0
const EXIT_IDS := ["L094>L007#2", "L094>L009#3", "L094>L053#4"]

var land
var town
var things
var cyc
var world: ChunkWorld
var sky_mat: ShaderMaterial
var water_mats: Array = []
var start := Vector3.ZERO
var tower := {}
var exit_houses: Array = []
var lamp_pos: Array = []
var street_lit := false
var said := {}
var indoors := false


func build() -> void:
	land = LAND.new()
	rules["view_distance"] = 2800.0
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -50.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.06
	var clay := func(n: String, a: Color, b: Color, pat := 0, sc := 1.0, th := 1.0) -> void: LAND.clay(n, a, b, pat, sc, th)
	TOWN.materials(clay)
	PROPS.materials(clay)
	LAND.clay("l94_grass_hill", Color(0.3, 0.55, 0.2), Color(0.24, 0.47, 0.15), 5, 0.35, 1.2)
	outdoor_env(Color(0.3, 0.5, 0.85), Color(0.75, 0.85, 0.95), Color(0.3, 0.45, 0.25), Vector2(48.0, 30.0),
		Color(1.0, 0.95, 0.82), 1.15, Color(0.72, 0.8, 0.9), 0.0011)
	var sh := Shader.new()
	sh.code = SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	environment.sky.sky_material = sky_mat
	environment.ambient_light_sky_contribution = 0.75
	environment.ambient_light_energy = 0.8
	environment.fog_sky_affect = 0.15
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.12
	environment.adjustment_contrast = 1.06
	sun.shadow_blur = 1.2
	sun.directional_shadow_max_distance = 80.0
	lights.setup(10, 0)
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	land.build_meshes(geo, MatLib.get_mat("l94_grass_hill"))
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	var k := kit("Town")
	town = TOWN.new(self, k, props)
	things = PROPS.new(self)
	town.streets()
	town.fountain()
	town.all_houses()
	_fountain_water(props)
	_parked(k, props)
	cyc = NIGHT.new(self)
	cyc.build_music()
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var top: Vector3 = things.siren_pole(k, props, Vector3(c.x * 17.0, 0.06, c.y * 17.0))
		cyc.add_speaker(top)
	_lamps(props)
	start = Vector3(0.0, 0.07, 27.0)
	_exits(k)
	var tw := Vector3(178.0, 0, 64.0)
	tw.y = land.h(tw.x, tw.z)
	tower = things.water_tower(k, props, tw)
	k.commit()
	things.castle(self, Vector3(-50.0, 150.0, -440.0))
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.build_around(start, 2)
	cyc.spawn(props, [Vector3(0, 0, -88), Vector3(88, 0, 0), Vector3(-88, 0, 0), Vector3(0, 0, 88), Vector3(30, 0, -30)])
	_notes()
	sound.bed("wind", {"seconds": 9.0}, -34.0)
	add_arrival("start", start, 0.0)
	add_landmark("Almond Water fountain", Vector3(0, 0, 0))
	add_landmark("Siren poles", Vector3(17, 0, 17))
	add_landmark("Water tower in the hills", tw)
	add_landmark("Floating castle on the Transparent Mountain (not reachable)", Vector3(-50, 150, -440))
	_shots()


const SKY := """
shader_type sky;
uniform float night = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec3 day = mix(vec3(0.78, 0.87, 0.95), vec3(0.28, 0.5, 0.88), smoothstep(0.0, 0.55, y));
	// painted cotton clouds that shift on twos
	float fr = floor(TIME * 4.0) / 4.0;
	vec2 uv = d.xz / (d.y + 0.12) * 0.9 + vec2(fr * 0.02, 0.0);
	float c = vn(uv * 1.3) * 0.6 + vn(uv * 3.1 + 5.0) * 0.3 + vn(uv * 9.0 + floor(TIME * 4.0)) * 0.1;
	float cl = smoothstep(0.55, 0.62, c) * smoothstep(0.02, 0.2, y);
	day = mix(day, vec3(0.97, 0.96, 0.92) - 0.12 * smoothstep(0.62, 0.8, c), cl);
	float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
	day += vec3(1.0, 0.95, 0.8) * smoothstep(0.9985, 0.999, s) * 2.0;
	vec3 nt = mix(vec3(0.03, 0.05, 0.12), vec3(0.005, 0.01, 0.04), smoothstep(0.0, 0.6, y));
	vec2 g = floor(vec2(atan(d.x, d.z) * 150.0, d.y * 220.0));
	nt += vec3(step(0.996, hsh(g)) * smoothstep(0.05, 0.3, y)) * 0.8;
	float m = dot(d, normalize(vec3(-0.4, 0.5, -0.6)));
	nt += vec3(0.9, 0.9, 0.75) * smoothstep(0.9993, 0.9995, m);
	vec3 col = mix(day, nt, night);
	if (d.y < 0.0) { col = mix(vec3(0.55, 0.65, 0.5), vec3(0.01, 0.015, 0.03), night); }
	COLOR = col;
}
"""


func clock_frames() -> int:
	return int(Time.get_ticks_msec() / 125)


# ---------------------------------------------------------------- town extras

## The basin and the falling sheets of Almond Water, animated on twos.
func _fountain_water(props: Node3D) -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
uniform float fall = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void fragment() {
	float fr = floor(TIME * 8.0);
	vec2 uv = UV;
	float n;
	if (fall > 0.5) { n = vn(vec2(uv.x * 40.0, uv.y * 6.0 - fr * 0.9)); }
	else { float r = length(uv - 0.5) * 30.0; n = 0.5 + 0.5 * sin(r - fr * 1.3) * 0.6 + vn(uv * 30.0 + fr) * 0.4; }
	ALBEDO = mix(vec3(0.72, 0.74, 0.68), vec3(0.95, 0.94, 0.88), n);
	ALPHA = fall > 0.5 ? 0.55 + 0.3 * n : 0.88;
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
}
"""
	for spec in [[6.1, 0.62, false], [2.45, 2.7, false], [0.95, 4.15, false]]:
		var m := ShaderMaterial.new()
		m.shader = sh
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = spec[0]
		cm.bottom_radius = spec[0]
		cm.height = 0.02
		cm.radial_segments = 26
		mi.mesh = cm
		mi.material_override = m
		mi.position = Vector3(0, spec[1], 0)
		props.add_child(mi)
	for spec in [[2.62, 2.75, 2.1], [1.02, 4.12, 1.4], [0.2, 5.2, 1.0]]:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("fall", 1.0)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = spec[0]
		cm.bottom_radius = spec[0] + 0.25
		cm.height = spec[2]
		cm.cap_top = false
		cm.cap_bottom = false
		cm.radial_segments = 22
		mi.mesh = cm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, spec[1] - spec[2] * 0.5, 0)
		props.add_child(mi)
	sound.emitter("water_bed", Vector3(0, 1.0, 0), {"seconds": 6.0, "bright": 900.0}, -8.0, 26.0)


func _parked(k: GeoKit, props: Node3D) -> void:
	var slots: Array = []
	for z in [-36.0, -50.0, -64.0, -78.0, 36.0, 50.0, 64.0, 78.0]:
		for s in [-1.0, 1.0]:
			slots.append([Vector3(s * 3.1, 0.02, z), 0.0 if s > 0 else PI])
			slots.append([Vector3(z, 0.02, s * 3.1), PI * 0.5 if s < 0 else -PI * 0.5])
	var order: Array = range(slots.size())
	var rr := RandomNumberGenerator.new()
	rr.seed = level_seed + 9411
	for i in order.size():
		var j := rr.randi() % order.size()
		var t = order[i]
		order[i] = order[j]
		order[j] = t
	for i in 9:
		var sl: Array = slots[order[i]]
		if i < 2:
			things.van(k, props, sl[0], sl[1])
		else:
			things.car(k, props, sl[0], sl[1])
	# one van on the square, by the fountain, for the milk
	things.van(k, props, Vector3(-11.5, 0.06, -15.5), PI * 0.5)
	add_interactable(Vector3(-11.5, 1.0, -18.4), Vector3(1.8, 1.4, 0.9), "Take a bottle of Almond Milk from the van", func():
		Overlay.subtitle("[a cold glass bottle of Almond Milk. The crate is full again when you look back.]", 4.0)
		SaveService.record_discovery(stable_id, "l94:milk", "Almond Milk from the milk van.", "SOURCE"))


func _lamps(props: Node3D) -> void:
	for d in [24.0, 40.0, 56.0, 72.0, 88.0]:
		for s in [-1.0, 1.0]:
			for side in [-1.0, 1.0]:
				var p1 := Vector3(side * 5.9, 0.08, s * d)
				var p2 := Vector3(s * d, 0.08, side * 5.9)
				for q in [p1, p2]:
					if side > 0:
						Props.place(self, props, "ph/street_lamp_01", q, 90.0 if absf(q.x) < 7.0 else 0.0, 3.9, true)
						lamp_pos.append(q + Vector3(0, 3.7, 0))


func _exits(k: GeoKit) -> void:
	var cand: Array = []
	for h in town.houses:
		if h["open"] and not h["two"]:
			cand.append(h)
	var rr := RandomNumberGenerator.new()
	rr.seed = level_seed + 9413
	for i in cand.size():
		var j := rr.randi() % cand.size()
		var t = cand[i]
		cand[i] = cand[j]
		cand[j] = t
	var picked: Array = cand.slice(0, 3)
	picked.sort_custom(func(a, b): return (a["front"] as Vector3).distance_to(start) < (b["front"] as Vector3).distance_to(start))
	var ids: Array = EXIT_IDS.duplicate()
	for i in ids.size():
		var j := rr.randi() % ids.size()
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	for i in picked.size():
		var h: Dictionary = picked[i]
		var bas: Basis = h["basis"]
		var bd: Vector3 = h["back_door"]
		k.box_xf(Transform3D(bas, bd + bas * Vector3(0, 1.07, 0.04)), Vector3(0.95, 2.1, 0.06), h["door"], GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, bd + bas * Vector3(0, 2.2, 0.05)), Vector3(1.25, 0.12, 0.1), "l94_trim_white", GeoKit.ALL, false)
		for sx in [-0.55, 0.55]:
			k.box_xf(Transform3D(bas, bd + bas * Vector3(sx, 1.1, 0.05)), Vector3(0.12, 2.2, 0.1), "l94_trim_white", GeoKit.ALL, false)
		var c: Vector3 = bd + bas * Vector3(0, 1.1, 0.75)
		var ex := add_exit(ids[i], "interact", c, Vector3(1.6, 2.2, 1.3), "Open the back door")
		if ex:
			ex.rotation.y = h["yaw"]
		exit_houses.append(h)


# ---------------------------------------------------------------- hills

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	land.collision_tile(node, ox, oz, int(CS))
	var c := Vector3(ox + CS * 0.5, 0, oz + CS * 0.5)
	var dc := Vector2(c.x, c.z).length()
	if dc < 170.0:
		return {}
	var r := RandomNumberGenerator.new()
	r.seed = hash([cx, cz, level_seed, 94])
	var kk := GeoKit.new(node, "Hill")
	var any := false
	if r.randf() < 0.28:
		var fp := c + Vector3(r.randf_range(-20, 20), 0, r.randf_range(-20, 20))
		fp.y = land.h(fp.x, fp.z)
		things.fragment(kk, node, fp, r.randf() * TAU, r)
		any = true
	if r.randf() < 0.14:
		var cp := c + Vector3(r.randf_range(-24, 24), 0, r.randf_range(-24, 24))
		cp.y = land.h(cp.x, cp.z) + 0.02
		things.car(kk, node, cp, r.randf() * TAU)
		any = true
	if any:
		kk.commit()
	return {}


# ---------------------------------------------------------------- notes

func _notes() -> void:
	add_note("l94_meg", "M.E.G. scouting card, tucked under a bench",
		"Level 94 - 'Motion'.\n\nEverything looks hand-made, grainy, like a 1930s stop-motion picture. Daytime: safe, no entities, Almond Water in the fountain, Almond Milk in the vans.\n\nNIGHT: the siren-pole music cuts out completely and the Animations come out. They attack anything they spot that isn't 'animated'. Get inside a house and stay there.\n\nToo dangerous to hold as a group. Outpost: still looking for a way.",
		Vector3(13.0 - 6.4 + 0.2, 0.62, 13.0), Vector3(0.4, 0.2, 0.35))
	add_note("l94_houses", "Pencilled on a door frame",
		"some of these houses go somewhere else.\nbehind one back door: Level 7. another: 9. another: 53.\nthey are not the same ones every time.",
		town.houses[0]["inside"] + Vector3(0, 1.5, 0), Vector3(0.4, 0.5, 0.3), false)
	add_note("l94_castle", "Field note, weighted with a stone on the hillside",
		"The castle hangs over the hills on what looks like a transparent mountain. Nobody I know has found the way up.\n\nThose who say they went: a fun-house - ball pits, playgrounds, an animation studio with a model of this town. Bright rooms. Bring Almond Water.\n\nPhotos from up there come out normal. No cartoon look at all.",
		tower["ladder"] + Vector3(1.4, 0.3, 0.6), Vector3(0.4, 0.2, 0.35))
	add_interactable(Vector3(0, 0.9, 6.6), Vector3(3.0, 1.0, 0.8), "Drink from the fountain", func():
		Overlay.subtitle("[cool and faintly sweet: Almond Water, running out of a clay fountain]", 4.0)
		SaveService.record_discovery(stable_id, "l94:fountain", "The town fountain flows with Almond Water.", "SOURCE"))


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	world.target = player
	Overlay.set_screen_effect("grain", 0.085)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	indoors = _inside_house(pp)
	cyc.tick(delta, pp, indoors)
	_apply_light(cyc.night)
	for h in exit_houses:
		if (h["back_door"] as Vector3).distance_to(pp) < 2.5 and not said.has("draught") and not SessionState.is_qa():
			said["draught"] = true
			Overlay.subtitle("[a draught under the back door, from somewhere that is not the yard]", 4.0)


func _inside_house(pp: Vector3) -> bool:
	for h in town.houses:
		var l: Vector3 = (h["basis"] as Basis).inverse() * (pp - (h["o"] as Vector3))
		if absf(l.x) < float(h["w"]) * 0.5 - 0.1 and absf(l.z) < float(h["d"]) * 0.5 - 0.1:
			return true
	return false


var _last_n := -1.0


func _apply_light(n: float) -> void:
	if absf(n - _last_n) < 0.002:
		return
	_last_n = n
	sun.light_energy = lerpf(1.15, 0.12, n)
	sun.light_color = Color(1.0, 0.95, 0.82).lerp(Color(0.5, 0.6, 0.95), n)
	sky_mat.set_shader_parameter("night", n)
	environment.ambient_light_energy = lerpf(0.8, 0.25, n)
	environment.fog_light_color = Color(0.72, 0.8, 0.9).lerp(Color(0.02, 0.03, 0.07), n)
	var lit := n > 0.4
	if lit != street_lit:
		street_lit = lit
		if lit:
			for q in lamp_pos:
				lights.add_anchor(q, Color(1.0, 0.85, 0.55), 2.2, 11.0, 0.0, "street")
		else:
			lights.remove_group("street")


# ---------------------------------------------------------------- QA

func _shots() -> void:
	add_shot("town_square_fountain", start + Vector3(-4.0, 1.62, 2.0), Vector3(0, 2.6, 0), {"flashlight": false, "prepare": _prep.bind(0.0)})
	add_shot("street_houses_cars", Vector3(-2.5, 1.7, -24.0), Vector3(1.0, 1.6, -70.0), {"flashlight": false, "prepare": _prep.bind(0.0)})
	var h: Dictionary = exit_houses[0] if not exit_houses.is_empty() else town.houses[0]
	var bas: Basis = h["basis"]
	var inside: Vector3 = (h["o"] as Vector3) + bas * Vector3(float(h["w"]) * 0.32, 1.95, float(h["d"]) * 0.36)
	add_shot("parlour_back_door", inside, (h["back_door"] as Vector3) + Vector3(0, 1.0, 0) - bas * Vector3(float(h["w"]) * 0.15, 0, 0), {"flashlight": false, "prepare": _prep.bind(0.0)})
	var td: Vector3 = tower["deck"]
	var cdir := (Vector3(-50.0, 0, -440.0) - Vector3(td.x, 0, td.z)).normalized()
	var hp := td - cdir * 30.0 + Vector3(6.0, 0, 0)
	hp.y = land.h(hp.x, hp.z) + 1.7
	add_shot("hills_tower_castle", hp, td + Vector3(0, 7.0, 0), {"flashlight": false, "prepare": _prep_hills.bind(hp)})
	add_shot("night_street_animations", Vector3(2.0, 1.7, -36.0), Vector3(-0.5, 1.3, -60.0), {"flashlight": false, "prepare": _prep.bind(1.0)})


func _prep(n: float) -> void:
	cyc.frozen = true
	cyc.clock = 30.0 if n < 0.5 else NIGHT.DAY_S + 90.0
	cyc.night = n
	var to_night: bool = n > 0.5
	if to_night != cyc.is_night:
		cyc.is_night = to_night
		cyc._turn(to_night)
	if to_night:
		var i := 0
		for a in cyc.anims:
			a["pos"] = Vector3(-3.0 + i * 1.7, 0.02, -46.0 - i * 3.5)
			a["yaw"] = PI * 0.9
			(a["node"] as Node3D).position = a["pos"]
			(a["node"] as Node3D).rotation.y = a["yaw"]
			i += 1
	_last_n = -1.0
	_apply_light(n)
	await get_tree().process_frame


func _prep_hills(p: Vector3) -> void:
	world.build_around(p, 2)
	await _prep(0.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "three house back doors lead to Levels 7, 9 and 53", "ok": exits.size() == 3 and exit_houses.size() == 3})
	out.append({"what": "the day begins (safe, no Animations visible)", "ok": not cyc.is_night})
	var vis := 0
	for a in cyc.anims:
		if (a["node"] as Node3D).visible:
			vis += 1
	out.append({"what": "no night entities during the day", "ok": vis == 0})
	var was_on: bool = cyc.music_on
	cyc._turn(true)
	var silent := true
	for pl in cyc.players:
		if (pl as AudioStreamPlayer3D).playing:
			silent = false
	cyc._turn(false)
	out.append({"what": "the music stops completely at night", "ok": silent, "detail": was_on})
	out.append({"what": "houses are enterable and give cover", "ok": _inside_house(town.houses[0]["inside"] + Vector3(0, 0.5, 0))})
	out.append({"what": "water tower deck is a second height", "ok": float((tower["deck"] as Vector3).y) > 8.0})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
