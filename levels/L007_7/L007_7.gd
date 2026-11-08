extends LevelBase
## Level 7.7 — "The Forsaken Debris" (Backrooms Wikidot rev 59, accessed
## 2026-11-04; cite: Ericote, CC BY-SA 3.0). Dossier: docs/canon/levels/L007_7.md.
##
## DESIGN (read -> plan):
## - Four components (fact 2): the Rock, the Lighthouse, the Ocean, the Sky.
##   The Geolith rises from the sea floor; its narrow, uneven summit is 47 m
##   above calm grey water (facts 3-5). One tongue of rock (the east spur)
##   hangs over open water: the only place a jump clears the rock.
## - The lighthouse is the sole building, shabby concrete with some wood and
##   metal (fact 6). Ground Floor: no windows, dead switches, burned-out lamps
##   barely hanging, worn furniture, mouldy tables, withered plants, paintings
##   gone indiscernible; light only from the stairs and the door (fact 7). It is
##   bigger on the inside (fact 8): crossing the door threshold swaps the
##   tower's outer shell for a wider, deeper complex of rooms (no windows means
##   it is never seen from outside). Upper Floor: windows, rust everywhere,
##   enclosed pipes, and behind a knot of them, the valve (facts 9-10, 18, 22).
##   Ceiling: decaying white floor and the Lamp Zone (giant bulb, ancient
##   glass, dead consoles incl. a radio transmitter, cables gone; fact 12).
## - Sky: empty light grey, lit from nowhere, never night; fast air mass gives
##   gusts that can only unbalance you (facts 14-15). Waves are the only
##   ambient sound (fact 16). No life anywhere (Entities: none).
## - Stateful mechanic (audio-log hypothesis, TESTIMONY): pressure climbs from
##   arrival; the consoles implode (CLANC), the pipes leak a toxic gas (blurred,
##   bleeding vision, damage), the Lamp Zone's glass gives way, fire spreads down
##   the tower and onto the rock. The valve turns; what that does is not stated
##   and nothing visible changes (report 1/22/2022).
## - Exit (fact 13, Exits): jump from the rock, survive the fall, beat the
##   currents near the Geolith and swim until the rock is out of sight
##   (compressed to 450 m, where the haze hides it) -> Level 7.

const B := preload("res://levels/L007_7/L007_7_build.gd")
const D := preload("res://levels/L007_7/L007_7_dress.gd")
const S := B.S
const UF := B.UF
const ROOF := B.ROOF
const T_LEAK := 480.0
const T_BOOM := 560.0
const OUT_OF_SIGHT := 450.0

var qa_fixture := false
var sea: WaterVolume
var surf: MeshInstance3D
var _shell: GeoKit
var _stub: GeoKit
var _inner: GeoKit
var _inner_props: Node3D
var _door_hinge: Node3D
var _door_open := false
var _ground_in := false
var _inside_vis := true
var _t := 0.0
var _valve_turns := 0
var _leak := false
var _boom := false
var _gas_up: CPUParticles3D
var _gas_down: CPUParticles3D
var _fires: Array = []
var _fire_t := 0.0
var _bulb: Node3D
var _valve_at := Vector3.ZERO
var _hiss: AudioStreamPlayer3D
var _gas_dose := 0.0
var _vy_min := 0.0
var _was_swimming := false
var _was_floor := true
var _gust_t := 30.0
var _cur_t := 0.0
var _arng := RandomNumberGenerator.new()
var _msgs := {}
var _door_side := 1.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	_arng.seed = hash([level_seed, "l77"])
	rules["view_distance"] = 900.0
	rules["oxygen_seconds"] = 35.0
	rules["kill_y"] = -120.0
	rules["reverb_room"] = 0.35
	rules["reverb_wet"] = 0.12
	outdoor_env(Color(0.60, 0.62, 0.64), Color(0.72, 0.73, 0.74), Color(0.16, 0.19, 0.21), Vector2(50, 140),
		Color(0.93, 0.94, 0.96), 0.8, Color(0.64, 0.66, 0.68), 0.0035)
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY      # lit from an unknown source; no sun
	sun.directional_shadow_max_distance = 140.0
	environment.ambient_light_energy = 0.32
	environment.fog_sky_affect = 0.85
	environment.tonemap_exposure = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.85
	environment.adjustment_contrast = 1.05
	B.materials()
	MatLib.register("l77_sea", _sea_material())
	lights.setup(4, 0)
	var r := RandomNumberGenerator.new()
	r.seed = 77    # the level reconstructs itself identically for every wanderer
	var rk := kit("Geolith")
	B.rock(rk, r)
	rk.commit()
	var tk := kit("Tower")
	B.tower(tk)
	var up_props := Node3D.new()
	up_props.name = "UpperProps"
	add_child(up_props)
	_valve_at = D.upper_floor(self, up_props, tk)
	_bulb = D.lamp_zone(self, up_props, tk)
	tk.commit()
	_shell = kit("Shell")
	B.shell(_shell)
	_shell.commit()
	_stub = kit("DoorwayStub")
	B.stub(_stub)
	_stub.commit()
	_inner = kit("GroundFloorInside")
	B.interior(_inner)
	_inner_props = Node3D.new()
	_inner_props.name = "Props"
	_inner.root.add_child(_inner_props)
	D.ground_floor(self, _inner_props, _inner, r)
	_inner.commit()
	_interior_light()
	var ext := Node3D.new()
	ext.name = "Exterior"
	add_child(ext)
	D.exterior(self, ext, r)
	_door()
	_ocean()
	_effects()
	_set_inside(false)
	add_arrival("start", Vector3(0.0, S + 0.06, 10.4), 0.0)
	add_arrival("from_L007", Vector3(0.0, S + 0.06, 10.4), 0.0)
	add_arrival("from_L007_8", Vector3(0.0, S + 0.09, 3.3), 0.0)
	if TransitionService.pending_arrival == "from_L007_8":
		_ground_in = true
	if qa_fixture:
		# QA FIXTURE ONLY: fires the documented edge at the spur's tip so the
		# walker bot can test it; the story exit needs the jump and a long swim.
		add_exit("L007_7>L007#1", "walk_in", Vector3(14.6, S + 1.0, 6.8), Vector3(1.8, 2.2, 2.0), "")
		qa_routes.append({"edge": "L007_7>L007#1", "target": Vector3(14.6, S, 6.8), "note": "QA fixture at the east spur; story = jump, then swim until the rock is out of sight"})
	else:
		var t := add_exit("L007_7>L007#1", "condition", Vector3(0, -6.0, 0), Vector3(3200, 14, 3200), "")
		if t:
			t.condition = func() -> bool: return player != null and player.swimming and Vector2(player.global_position.x, player.global_position.z).length() > OUT_OF_SIGHT
	add_interactable(_valve_at + Vector3(0.25, 0, 0), Vector3(0.6, 0.7, 0.7), "Turn the valve hidden behind the pipes", _turn_valve)
	add_interactable(B.LAMP + Vector3(1.0, 1.1, 1.6), Vector3(4.6, 1.2, 1.6), "Try the control panels", _panels)
	add_note("l77_mp3", "Water-damaged MP3 player (TESTIMONY)",
		"One recovered file. A girl, Samantha, talks to nobody from the top of this rock: she no-clipped here; it is far too high to jump unless you dive like a professional; the building is bigger inside than out; she found a lever marked \"pipe link source\" up by the lamp.\n\nThen a CLANC from above, gas from every pipe, blood from her eyes, the lamp room exploding, fire running down the tower and over the rock.\n\nThe file ends with her jumping.",
		Vector3(-5.6, S + 0.55, 2.3), Vector3(0.35, 0.2, 0.35), false)
	add_note("l77_log", "Typed transcript, M.E.G. (TESTIMONY)",
		"Three researchers on Level 7.7: only one wanderer at a time; the place picks who comes in and rebuilds itself for each one. Something like a valve below keeps raising the pressure in the whole building. The panels implode once and for a fraction of a second they work; the gas, then the lamp room's glass, then fire.\n\n\"What happens if the wanderer shuts it off before everything goes nuts?\"\n\nNobody answers.",
		Vector3(5.6, S + 0.92, 1.4))
	sound.bed("wind", {"seconds": 9.0}, -24.0)
	sound.emitter("water_bed", Vector3(12, 1.0, 4), {"bright": 520.0, "seconds": 7.0}, 4.0, 160.0)
	sound.emitter("water_bed", Vector3(-12, 1.0, -6), {"bright": 380.0, "seconds": 6.0}, 2.0, 160.0)
	_hiss = sound.emitter("static", Vector3(-3.0, UF + 1.5, -3.0), {"seconds": 3.0}, -40.0, 14.0)
	sound.emitter("room_tone", Vector3(0, S + 1.5, -3.0), {"cutoff": 120.0, "rumble": 0.3}, -22.0, 14.0)
	sound.oneshot("creak", {"freq": 90.0}, 25.0, 60.0, 10.0, "[the building creaks]", -16.0)
	add_landmark("Front of the lighthouse (arrival)", Vector3(0, S, 10))
	add_landmark("East spur over open water", Vector3(14.5, S, 6.8))
	add_landmark("Ground floor (bigger inside)", Vector3(-5.6, S, 2.0))
	add_landmark("Upper floor pipes and valve", _valve_at)
	add_landmark("Lamp Zone", B.LAMP)
	add_shot("rock_and_lighthouse", Vector3(52.0, 2.6, 74.0), Vector3(0.0, 46.0, 0.0), {"prepare": _prep.bind(false, -1)})
	add_shot("summit_door", Vector3(4.2, S + 1.7, 12.0), Vector3(-0.4, S + 2.6, 4.5), {"prepare": _prep.bind(false, -1)})
	add_shot("ground_floor", Vector3(-1.9, S + 1.62, 3.7), Vector3(-8.0, S + 0.9, 0.9), {"prepare": _prep.bind(true, -1)})
	add_shot("corridor", Vector3(0.3, S + 1.62, 4.0), Vector3(-0.2, S + 1.7, -8.0), {"prepare": _prep.bind(true, -1)})
	add_shot("upper_pipes", Vector3(2.2, UF + 1.62, 3.7), Vector3(-3.6, UF + 1.2, -3.2), {"prepare": _prep.bind(false, -1)})
	add_shot("lamp_zone", Vector3(3.7, ROOF + 1.62, 3.9), B.LAMP + Vector3(0, 1.7, 0), {"prepare": _prep.bind(false, -1)})
	add_shot("gas_leak", Vector3(2.2, UF + 1.62, 3.7), Vector3(-3.6, UF + 1.2, -3.2), {"prepare": _prep.bind(false, 1)})
	add_shot("spur_drop", Vector3(15.7, S + 1.62, 9.2), Vector3(-2.0, S - 6.0, -3.0), {"prepare": _prep.bind(false, 2)})


func _sea_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec3 deep : source_color = vec3(0.10, 0.15, 0.17);
uniform vec3 crest : source_color = vec3(0.30, 0.36, 0.38);
varying vec3 wp;
float h2(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
float hgt(vec2 p, float t) { return sin(p.x * 0.11 + t * 0.6) * 0.18 + sin(p.y * 0.07 - t * 0.45) * 0.14 + vn(p * 0.6 + t * 0.3) * 0.12 + vn(p * 2.3 - t * 0.5) * 0.05; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; VERTEX.y += (sin(wp.x * 0.11 + TIME * 0.6) * 0.18 + sin(wp.z * 0.07 - TIME * 0.45) * 0.14); }
void fragment() {
	float e = 0.08;
	float h0 = hgt(wp.xz, TIME);
	vec3 n = normalize(vec3((h0 - hgt(wp.xz + vec2(e, 0.0), TIME)) * 4.0, 1.0, (h0 - hgt(wp.xz + vec2(0.0, e), TIME)) * 4.0));
	NORMAL = normalize((VIEW_MATRIX * vec4(FRONT_FACING ? n : -n, 0.0)).xyz);
	float r = length(wp.xz - vec2(-2.0, 1.5));
	float foam = (1.0 - smoothstep(9.0, 20.0, r)) * smoothstep(0.55, 0.85, vn(wp.xz * 1.3 + TIME * 0.4)) * 0.6;
	ALBEDO = mix(mix(deep, crest, clamp(h0 * 0.8, 0.0, 1.0) * 0.4), vec3(0.8, 0.82, 0.82), foam);
	ROUGHNESS = 0.08 + foam * 0.6;
	SPECULAR = 0.5;
	ALPHA = FRONT_FACING ? 0.97 : 0.8;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _ocean() -> void:
	sea = WaterVolume.new()
	sea.name = "Ocean"
	add_child(sea)
	sea.setup(Vector3(-5000, -70, -5000), Vector3(5000, 0, 5000), "l77_sea", false)
	sea.tint = Color(0.12, 0.2, 0.22)
	sea.fog_color = Color(0.08, 0.13, 0.15)
	surf = MeshInstance3D.new()
	surf.name = "SeaSurface"
	var pm := PlaneMesh.new()
	pm.size = Vector2(1800, 1800)
	pm.subdivide_width = 160
	pm.subdivide_depth = 160
	surf.mesh = pm
	surf.material_override = MatLib.get_mat("l77_sea")
	surf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surf)


## Ground floor light: none of its own. Grey daylight falls down the stairwell
## and in through the door; a little bounces into every room.
func _interior_light() -> void:
	for d in [[Vector3(0, UF - 0.4, -2.6), 1.2, 7.5], [Vector3(0, S + 2.2, 3.6), 0.35, 5.0],
			[Vector3(-5.4, S + 2.6, 2.2), 0.28, 7.0], [Vector3(5.4, S + 2.6, 1.0), 0.28, 7.0],
			[Vector3(-5.4, S + 2.6, -4.0), 0.16, 6.5], [Vector3(5.4, S + 2.6, -5.2), 0.16, 6.5]]:
		var l := OmniLight3D.new()
		l.position = d[0]
		l.light_color = Color(0.80, 0.83, 0.86)
		l.light_energy = d[1]
		l.omni_range = d[2]
		l.omni_attenuation = 1.3
		l.shadow_enabled = false
		_inner.root.add_child(l)
	var up := OmniLight3D.new()
	up.position = Vector3(0, UF + 2.2, 0)
	up.light_color = Color(0.78, 0.8, 0.82)
	up.light_energy = 0.5
	up.omni_range = 7.5
	add_child(up)


func _door() -> void:
	_door_hinge = Node3D.new()
	_door_hinge.name = "DoorHinge"
	_door_hinge.position = Vector3(-B.DOOR_W * 0.5, S + 0.03, B.HT)
	add_child(_door_hinge)
	var leaf := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(B.DOOR_W - 0.04, 2.08, 0.06)
	leaf.mesh = bm
	leaf.material_override = MatLib.get_mat("l77_wood")
	leaf.position = Vector3(B.DOOR_W * 0.5, 1.04, 0)
	_door_hinge.add_child(leaf)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	shp.size = bm.size
	cs.shape = shp
	body.add_child(cs)
	leaf.add_child(body)
	add_interactable(Vector3(0, S + 1.1, B.HT + 0.25), Vector3(1.2, 2.1, 0.5), "Open / close the door", func(_p): _set_door(not _door_open))
	add_interactable(Vector3(0, S + 1.1, B.HT - 0.3), Vector3(1.2, 2.1, 0.4), "Open / close the door", func(_p): _set_door(not _door_open))
	_set_door(qa_fixture)


func _set_door(open: bool) -> void:
	_door_open = open
	var tw := create_tween()
	tw.tween_property(_door_hinge, "rotation:y", deg_to_rad(-105.0 if open else 0.0), 0.6)
	sound.play_at("creak", {"freq": 140.0}, Vector3(0, S + 1.0, B.HT), -10.0, "[the door scrapes]" if open else "")


func _effects() -> void:
	_gas_up = _particles(Vector3(0, UF + 1.6, 0), Vector3(4.0, 1.6, 4.0), Color(0.42, 0.62, 0.28, 0.045), 150, 1.7)
	_gas_down = _particles(Vector3(0, S + 1.0, -1.5), Vector3(9.0, 0.9, 6.0), Color(0.42, 0.62, 0.28, 0.04), 200, 1.8)
	_gas_down.reparent(_inner.root)


func _particles(at: Vector3, ext: Vector3, col: Color, amount: int, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.disable_receive_shadows = true
	qm.material = m
	p.mesh = qm
	p.position = at
	p.emitting = false
	p.visible = false
	add_child(p)
	return p


func _fire_at(at: Vector3, ext: Vector3) -> void:
	var p := _particles(at, ext, Color(1.0, 0.45, 0.12, 0.55), 120, 0.9)
	(p.mesh.surface_get_material(0) as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p.direction = Vector3(0, 1, 0)
	p.spread = 15.0
	p.gravity = Vector3(0, 1.2, 0)
	p.lifetime = 1.4
	p.preprocess = 1.4
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.4
	p.emitting = true
	p.visible = true
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.18)
	l.light_energy = 2.6
	l.omni_range = maxf(ext.x, ext.z) * 2.5 + 4.0
	l.position = at + Vector3(0, 0.8, 0)
	add_child(l)
	_fires.append({"p": p, "l": l, "at": at, "ext": ext})
	sound.play_at("crackle", {"seconds": 2.0}, at, -6.0, "[fire]")


# ------------------------------------------------------------- state changes

func _set_inside(v: bool) -> void:
	if _inside_vis == v:
		return
	_inside_vis = v
	_shell.root.visible = not v
	_shell.body.collision_layer = 0 if v else 1
	_stub.root.visible = not v
	_stub.body.collision_layer = 0 if v else 1
	_inner.root.visible = v
	for b in _inner.root.find_children("*", "StaticBody3D", true, false):
		(b as StaticBody3D).collision_layer = 1 if v else 0


func _turn_valve(_p) -> void:
	_valve_turns += 1
	var w := get_node_or_null("UpperProps/PressureValve") as Node3D
	if w:
		create_tween().tween_property(w, "rotation:x", w.rotation.x + PI * 0.75, 0.9)
	sound.play_at("creak", {"freq": 60.0}, _valve_at, -6.0, "[the wheel grinds round]")
	Overlay.subtitle("[it turns. The hissing in the pipes does not change. Nobody ever said what this does.]", 5.0)
	SaveService.record_discovery(stable_id, "valve", "Turned the valve. No visible effect (as in the 1/22/2022 report).", "TESTIMONY")


func _panels(_p) -> void:
	if _leak:
		Overlay.subtitle("[dead and scorched. Behind them, nothing: the cables are gone.]", 4.0)
	else:
		Overlay.subtitle("[buttons, levers, an ancient radio transmitter. Nothing responds; behind the panels there are no cables at all.]", 5.0)


func _start_leak() -> void:
	_leak = true
	sound.play_at("pipe_clank", {"f": 180.0}, B.LAMP + Vector3(0, 1, -3), 6.0, "[CLANC! — from above]")
	sound.play_at("static", {"seconds": 3.0}, Vector3(-2, UF + 1.4, -2), 0.0, "[PSSSST — gas, from every pipe]")
	_gas_up.visible = true
	_gas_up.emitting = true
	_hiss.volume_db = -8.0


func _explode() -> void:
	_boom = true
	sound.play_at("distant_boom", {}, B.LAMP, 8.0, "[an explosion in the Lamp Zone]")
	sound.play_at("crackle", {"seconds": 1.5}, B.LAMP, 4.0, "[glass, everywhere]")
	if _bulb:
		_bulb.visible = false
	_fire_at(B.LAMP + Vector3(0, 0.8, 0), Vector3(1.6, 0.6, 1.6))


func _spread_fire(delta: float) -> void:
	_fire_t += delta
	var stages := [[12.0, Vector3(2.0, UF + 0.4, 2.6), Vector3(1.5, 0.4, 1.2)], [30.0, Vector3(-2.6, UF + 0.4, 1.0), Vector3(1.4, 0.4, 2.0)],
		[48.0, Vector3(0.0, S + 0.4, -5.0), Vector3(2.0, 0.4, 2.0)], [70.0, Vector3(-4.0, S + 0.3, 7.0), Vector3(2.5, 0.3, 2.0)],
		[85.0, Vector3(4.5, S + 0.3, 9.0), Vector3(2.2, 0.3, 2.0)], [100.0, Vector3(0.0, S + 0.3, 10.5), Vector3(3.0, 0.3, 1.4)]]
	if _fires.size() <= stages.size() and _fire_t >= float(stages[_fires.size() - 1][0]):
		var st: Array = stages[_fires.size() - 1]
		_fire_at(st[1], st[2])
		if _fires.size() == 5:
			_say("rockfire", "[the flames reach the rock — and spread across it]", 4.5)


# ----------------------------------------------------------------- runtime

func _prep(inside: bool, state: int) -> void:
	_ground_in = inside
	_set_inside(inside)
	if state >= 1 and not _leak:
		_start_leak()
	if state >= 2 and not _boom:
		_explode()
	surf.position = Vector3.ZERO
	await get_tree().process_frame


func on_player_ready() -> void:
	_set_inside(_ground_in)
	if SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[wind. Waves, far below. Nothing alive anywhere.]", 5.0)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if _msgs.has(key):
		return
	_msgs[key] = true
	Overlay.subtitle(text, secs)


func _exit_tree() -> void:
	for k in ["desaturate", "red_tint"]:
		Overlay.set_screen_effect(k, 0.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	surf.position = Vector3(snappedf(p.x, 20.0), 0.0, snappedf(p.z, 20.0))
	# --- door threshold: the ground floor is one thing inside, another outside
	if absf(p.x) < 0.9 and p.z > B.HT - 1.2 and p.z < B.HT + 1.2 and p.y < S + 1.5:
		var side := signf(p.z - B.HT)
		if side != 0.0 and side != _door_side:
			_ground_in = side < 0.0
		_door_side = side
	if p.y > ROOF - 0.6:
		_ground_in = false
	_set_inside(_ground_in and p.y < UF - 0.6)
	if _ground_in and p.y < UF - 0.6 and Vector2(p.x, p.z).length() > 6.0:
		_say("bigger", "[this room should not fit inside the tower]", 4.0)
	# --- pressure timeline (audio-log hypothesis)
	_t += delta
	if _hiss and not _leak:
		_hiss.volume_db = lerpf(-40.0, -16.0, clampf(_t / T_LEAK, 0.0, 1.0))
	if _t > T_LEAK * 0.6:
		_say("pressure", "[the pipes hiss louder than before; your ears pop]", 4.0)
	if _t >= T_LEAK and not _leak:
		_start_leak()
	if _leak and _t >= T_LEAK + 40.0 and not _gas_down.emitting:
		_gas_down.visible = true
		_gas_down.emitting = true
		_say("gasdown", "[the gas is coming down the stairs]", 4.0)
	if _t >= T_BOOM and not _boom:
		_explode()
	if _boom:
		_spread_fire(delta)
	_hazards(delta, p)
	_falls(p)
	_sea_state(delta, p)
	_gusts(delta, p)


func _hazards(delta: float, p: Vector3) -> void:
	var in_up := absf(p.x) < B.HT and absf(p.z) < B.HT and p.y > UF - 0.3 and p.y < ROOF
	var in_down := _ground_in and p.y < UF - 0.6 and _gas_down.emitting
	var gassed := (_leak and in_up) or in_down
	_gas_dose = clampf(_gas_dose + (delta * 0.12 if gassed else -delta * 0.04), 0.0, 1.0)
	if gassed:
		player.hurt(delta * 3.0, "toxic gas")
		_say("gas", "[green gas. Your eyes burn; the world blurs; there is blood on your fingers]", 5.0)
	Overlay.set_screen_effect("desaturate", _gas_dose * 0.7)
	Overlay.set_screen_effect("red_tint", _gas_dose * 0.45)
	for f in _fires:
		var at: Vector3 = f["at"]
		var ext: Vector3 = f["ext"]
		(f["l"] as OmniLight3D).light_energy = 2.2 + sin(_t * 17.0 + at.x) * 0.5 + sin(_t * 7.0) * 0.4
		if absf(p.x - at.x) < ext.x + 0.4 and absf(p.z - at.z) < ext.z + 0.4 and absf(p.y - at.y) < 2.0:
			player.hurt(delta * 14.0, "fire")


## Falling: no ropes, a 47 m drop. Water breaks the fall badly; rock does not.
func _falls(p: Vector3) -> void:
	if not player.swimming:
		_vy_min = minf(_vy_min, player.velocity.y)
	var on_floor := player.is_on_floor()
	if on_floor and not _was_floor and _vy_min < -15.0:
		player.hurt((absf(_vy_min) - 13.0) * 7.0, "fell on the rock")
	if player.swimming and not _was_swimming:
		if _vy_min < -18.0:
			var dmg := 30.0 + _arng.randf() * 35.0
			player.hurt(dmg, "hit the water from too high")
			Overlay.subtitle("[the water hits like concrete. You are alive.]", 4.5)
		_vy_min = 0.0
	if on_floor or player.swimming:
		_vy_min = 0.0 if on_floor else _vy_min
	_was_floor = on_floor
	_was_swimming = player.swimming


## Unpredictable currents near the Geolith; calm open water beyond.
func _sea_state(delta: float, p: Vector3) -> void:
	var d := Vector2(p.x + 2.0, p.z - 1.5).length()
	if player.swimming:
		_cur_t -= delta
		if _cur_t <= 0.0:
			_cur_t = _arng.randf_range(3.0, 7.0)
			var strength := clampf(1.0 - (d - 20.0) / 60.0, 0.0, 1.0) * _arng.randf_range(0.6, 1.8)
			var a := _arng.randf() * TAU
			sea.current = Vector3(cos(a), 0, sin(a)) * strength
			if strength > 1.0:
				_say("current", "[a current grabs you and drags you along the rock]", 4.0)
		if d > 120.0:
			_say("open", "[open water. The rock is a grey shape behind you in the haze.]", 4.0)
	else:
		sea.current = Vector3.ZERO


func _gusts(delta: float, p: Vector3) -> void:
	var exposed := (p.y > S - 0.5 and not (_ground_in and p.y < UF)) and not (absf(p.x) < B.HT and absf(p.z) < B.HT and p.y < ROOF - 0.3)
	_gust_t -= delta
	if _gust_t <= 0.0:
		_gust_t = _arng.randf_range(25.0, 55.0)
		if exposed and not player.swimming:
			var a := _arng.randf() * TAU
			player.velocity += Vector3(cos(a), 0, sin(a)) * 2.4
			sound.play_at("wind", {"seconds": 2.0}, p + Vector3(cos(a), 1, sin(a)) * 4.0, -4.0, "[a gust drops out of the sky and shoves you]")


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "one documented exit edge (QA fixture of L007_7>L007#1)", "ok": exits.size() == 1 and exits[0].edge_id == "L007_7>L007#1"})
	out.append({"what": "starts outside: shell solid, inside rooms hidden and non-solid", "ok": not _inside_vis and _shell.body.collision_layer == 1 and not _inner.root.visible})
	var span_out := _inner.root.visible
	_set_inside(true)
	var bigger := _inner.root.visible and _shell.body.collision_layer == 0
	_set_inside(false)
	out.append({"what": "door threshold swaps shell for the bigger interior", "ok": bigger and not span_out})
	var before := _t
	_turn_valve(null)
	out.append({"what": "valve turns without stopping the pressure clock (effect not stated)", "ok": _valve_turns == 1 and _t >= before})
	out.append({"what": "no gas or fire at arrival", "ok": not _leak and not _boom and _fires.is_empty()})
	out.append({"what": "summit is 47 m above the sea", "ok": absf(S - 47.0) < 0.01 and sea.surface_y == 0.0})
	return out
