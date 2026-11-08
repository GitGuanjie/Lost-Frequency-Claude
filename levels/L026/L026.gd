extends LevelBase
## Level 26 "The SS Fun =)" (Backrooms Wikidot rev 67, accessed 2026-11-04; Robert Goerman and
## MC_Crafter_24_7, CC BY-SA 3.0). Dossier: docs/canon/levels/L026.md.
##
## PLAN (read -> design):
## - SOURCE: the Frontrooms cruise liner Adventure (~150 x 18 m), its name crudely replaced
##   by "SS Fun =)"; exterior = top, upper and main decks (normal reality), interior = lower
##   decks that appear infinite. Every circuit is powered with no generator.
##   -> an authored 148 m hull on a sea: main deck (forty staterooms off a carpeted hallway,
##   20 a side; lobby with the elevators; covered promenades; foredeck; stern deck), upper
##   deck (crimson pool, restaurant, bar and lounge), sun deck on top ("nowhere higher to
##   go"): three walkable heights joined by real stairs; every light is on.
## - SOURCE: exterior trashed by a perpetual frat party; blood spatter (toned down); cabins
##   are garbage dumps; a crimson pool reeking of death (victims not depicted); remnants of
##   restaurant, bar, lounge.
## - SOURCE: lower decks: endless corridors and party rooms (typical decor, movie and holiday
##   themes, booby-trapped favours), the elevators are the hub, hallways branch to every
##   compass point; Liminal Echo clones one party room 38 times along a hallway, items spawn
##   by themselves; Carnivorous Balloons infest the darkest corners.
##   -> elevator to a streamed ChunkWorld window (finite; canon infinity is not simulated):
##   crossings of corridors, a themed room per quadrant, the same birthday room repeating along
##   the hub hallway, unwatched chunks rebuilt with new contents; balloon clusters in dark rooms.
## - SOURCE stateful mechanic: periodically a green fog covers the ship and it is gone (it
##   no-clips) -> the fog rolls in, thickens to green, and lifts on a different place: open sea,
##   dusk sea, a plain, a desert (appearances list water and land levels; which ones is ours).
## - SOURCE entities: Partygoers dominate (scripted presences only: yellow, Gumby-like figures
##   that no-clip away when approached; none on the sun deck, per testimony). Balloons only
##   creep in the dark. No combat. The golden egg monster and transformed victims are
##   testimony and are not shown.
## - SOURCE exits: touch a reversed, out-of-focus party poster (testimony: on the sun deck ->
##   Level 4); jump overboard (outcome not stated -> the open boarding gate, EXT).
## - ABSENT: friendly bases, safe zones, shops, any other exit.

const Ship := preload("res://levels/L026/L026_ship.gd")
const ShipFull := preload("res://levels/L026/L026_upper.gd")
const Decks := preload("res://levels/L026/L026_decks.gd")
const FOG_PERIOD := 210.0
const SPLAT := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque;
uniform vec3 col : source_color = vec3(0.22, 0.02, 0.02);
uniform float seed = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p) + (n(UV * 6.0) - 0.5) * 0.55 + (n(UV * 17.0) - 0.5) * 0.25;
	float drops = step(0.83, n(UV * 22.0)) * step(length(p), 0.95);
	if (r > 0.6 && drops < 0.5) { discard; }
	ALBEDO = col * (0.8 + 0.4 * n(UV * 9.0));
	ROUGHNESS = 0.25;
}
"""
const LOCATIONS := [
	{"name": "open sea", "top": Color(0.3, 0.35, 0.4), "hor": Color(0.62, 0.64, 0.62), "sun": Vector2(28.0, 40.0), "sun_col": Color(0.95, 0.92, 0.85), "sun_e": 0.7, "fog": Color(0.6, 0.62, 0.6), "dens": 0.0032, "land": ""},
	{"name": "a red dusk sea", "top": Color(0.14, 0.1, 0.18), "hor": Color(0.82, 0.42, 0.28), "sun": Vector2(5.0, -60.0), "sun_col": Color(1.0, 0.55, 0.35), "sun_e": 0.9, "fog": Color(0.5, 0.3, 0.26), "dens": 0.004, "land": ""},
	{"name": "a flat golden plain", "top": Color(0.35, 0.5, 0.72), "hor": Color(0.78, 0.8, 0.76), "sun": Vector2(42.0, 120.0), "sun_col": Color(1.0, 0.95, 0.85), "sun_e": 1.1, "fog": Color(0.74, 0.76, 0.72), "dens": 0.0026, "land": "l26_land_grass"},
	{"name": "a desert", "top": Color(0.42, 0.55, 0.72), "hor": Color(0.9, 0.82, 0.68), "sun": Vector2(58.0, 200.0), "sun_col": Color(1.0, 0.94, 0.8), "sun_e": 1.3, "fog": Color(0.86, 0.78, 0.64), "dens": 0.0035, "land": "l26_land_sand"}]

var S
var D
var world: ChunkWorld
var sea: WaterVolume
var pool: WaterVolume
var land: MeshInstance3D
var sky_mat: ProceduralSkyMaterial
var loc := 0
var fog_t := 0.0
var fog_phase := 0               # 0 clear, 1 rolling in, 2 gone, 3 lifting
var fog_k := 0.0
var relocations := 0
var inside := false
var figures: Array = []          # [{node, home, gone, t, seen}]
var balloons: Array = []
var _said := {}
var _trapped := {}
var _sea_bed: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _deck_bed: AudioStreamPlayer
var _outdoor := {}
var poster_pos := Vector3.ZERO


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 900.0
	rules["kill_y"] = -150.0
	rules["reverb_room"] = 0.2
	rules["reverb_wet"] = 0.08
	var L0: Dictionary = LOCATIONS[0]
	outdoor_env(L0["top"], L0["hor"], Color(0.1, 0.14, 0.16), L0["sun"], L0["sun_col"], L0["sun_e"], L0["fog"], L0["dens"])
	sky_mat = (environment.sky.sky_material as ProceduralSkyMaterial)
	environment.ambient_light_energy = 0.55
	environment.fog_sky_affect = 0.7
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.85
	environment.glow_intensity = 0.4
	sun.directional_shadow_max_distance = 80.0
	Ship.materials()
	Decks.materials()
	MatLib.register("l26_sea", MatLib.water({"shallow_color": Color(0.12, 0.26, 0.3), "deep_color": Color(0.03, 0.08, 0.11),
		"absorption": 0.05, "clarity": 0.6, "wave_height": 0.08, "wave_scale": 0.25, "wave_speed": 0.5, "foam_amount": 0.2}))
	MatLib.define("l26_land_grass", {"albedo_a": Color(0.62, 0.55, 0.28), "albedo_b": Color(0.5, 0.46, 0.22), "pattern": 12,
		"pattern_color": Color(0.7, 0.62, 0.3), "pattern_strength": 0.5, "noise_scale": 0.05}, "")
	MatLib.define("l26_land_sand", {"albedo_a": Color(0.86, 0.72, 0.5), "albedo_b": Color(0.78, 0.64, 0.42), "pattern": 13,
		"noise_scale": 0.05, "pattern_strength": 0.4}, "")
	var k := kit("Ship")
	var dk := kit("ShipDressing")
	S = ShipFull.new(self, k, dk, rng)
	S.hull()
	S.superstructure()
	S.cabin_interiors()
	S.upper_deck()
	var sd: Dictionary = S.sun_deck()
	S.foredeck()
	k.commit()
	dk.commit()
	_sea()
	lights.setup(14, 1)
	lights.max_distance = 34.0
	for lp in S.lamp_points:
		lights.add_anchor(lp[0], lp[1], lp[2], lp[3], lp[4])
	_string_lights(S.string_lights())
	_posters(sd)
	var deb: Array = S.party_debris()
	for sp in S.splats:
		add_splat(sp[0], sp[1])
	_scatter_mm(deb[0], "confetti")
	_scatter_mm(deb[1], "hats")
	_scatter_mm(deb[2], "balloons")
	_figures()
	_sounds()
	_interactions()
	# the lower decks
	D = Decks.new(self, level_seed)
	world = ChunkWorld.new()
	world.name = "LowerDecks"
	world.chunk_size = Decks.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = func(cx: int, cz: int, v: int, node: Node3D) -> Dictionary: return D.build_chunk(cx, cz, v, node)
	world.can_shift = func(key: Vector2i, _m: Dictionary) -> bool: return key != Vector2i(Decks.IX, 0) and key.y != 0
	world.shift_enabled = true
	world.shift_after = 25.0
	add_child(world)
	world.chunk_built.connect(_on_chunk_built)
	world.chunk_unloaded.connect(func(key: Vector2i) -> void: lights.remove_group("deck_%d_%d" % [key.x, key.y]))
	# arrivals, exits, landmarks
	add_arrival("start", Vector3(0.0, 0.05, -66.5), 180.0)
	var pe := add_exit("L026>L004#1", "interact", poster_pos + Vector3(0, 0.0, -0.75), Vector3(1.4, 2.0, 1.3),
		"Touch the poster whose writing runs backwards and will not come into focus")
	if pe:
		pe.fired.connect(func(_e: String) -> void: Overlay.glitch(1.0))
	var ob := add_exit("L026>EXT#2", "fall", Vector3(10.6, -4.0, Ship.GATE_Z), Vector3(3.2, 8.0, 2.6), "")
	if ob:
		ob.fall_y = -3.0
	fog_t = FOG_PERIOD * (0.55 + 0.2 * rng.randf())
	add_landmark("Stern deck under the pool", Vector3(0, 0, -64))
	add_landmark("Stateroom hallway", Vector3(0, 0, -18))
	add_landmark("Elevator lobby", Vector3(0, 0, 12))
	add_landmark("Crimson pool", Vector3(0, Ship.UP, -50.5))
	add_landmark("Sun deck posters", poster_pos)
	add_landmark("Open boarding gate", Vector3(8.8, 0, Ship.GATE_Z))
	add_landmark("Lower decks hub", Decks.hub_arrival())
	_shots()


func _sea() -> void:
	sea = WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-1500, Ship.SEA_Y - 60.0, -1500), Vector3(1500, Ship.SEA_Y, 1500), "l26_sea", true)
	sea.fog_color = Color(0.04, 0.12, 0.14)
	sea.fog_density = 0.08
	pool = WaterVolume.new()
	pool.name = "CrimsonPool"
	add_child(pool)
	var P: Rect2 = Ship.POOL
	pool.setup(Vector3(P.position.x, Ship.UP - 1.2, P.position.y), Vector3(P.end.x, Ship.UP - 0.2, P.end.y), "l26_crimson", true)
	pool.fog_color = Color(0.25, 0.0, 0.0)
	pool.fog_density = 0.9
	pool.tint = Color(0.6, 0.05, 0.05)
	land = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(3000, 3000)
	land.mesh = pm
	land.position = Vector3(0, Ship.SEA_Y + 0.02, 0)
	land.visible = false
	add_child(land)
	# a few drifting things on the water, beer-can bright
	for i in 6:
		Props.place(self, S.props, "ph/lifebuoy" if i % 2 == 0 else "ph/plastic_crate_01", Vector3(rng.randf_range(-40, 40), Ship.SEA_Y - 0.1, rng.randf_range(-90, 90)) + Vector3(18.0 if i % 2 == 0 else -18.0, 0, 0), rng.randf() * 360.0)


func _string_lights(pts: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.12
	sm.radial_segments = 6
	sm.rings = 3
	mm.mesh = sm
	mm.instance_count = pts.size()
	var cols := [Color(1.6, 0.3, 0.3), Color(0.3, 1.4, 0.4), Color(0.4, 0.6, 1.8), Color(1.8, 1.4, 0.3), Color(1.6, 0.4, 1.4)]
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis(), pts[i]))
		mm.set_instance_color(i, cols[i % cols.size()])
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "PartyLights"
	mmi.multimesh = mm
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	for i in range(0, pts.size(), 18):
		lights.add_anchor(pts[i], [Color(1.0, 0.4, 0.5), Color(0.5, 1.0, 0.6), Color(0.6, 0.7, 1.0)][i % 3], 0.6, 5.0, 0.0)


func _scatter_mm(pts: Array, kind: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	match kind:
		"confetti":
			mm.mesh = D_conf_mesh()
		"hats":
			var hm := CylinderMesh.new()
			hm.top_radius = 0.0
			hm.bottom_radius = 0.07
			hm.height = 0.2
			hm.radial_segments = 8
			mm.mesh = hm
		_:
			var bm := SphereMesh.new()
			bm.radius = 0.15
			bm.height = 0.38
			bm.radial_segments = 10
			bm.rings = 6
			mm.mesh = bm
	mm.instance_count = pts.size()
	for i in pts.size():
		var b := Basis(Vector3.UP, rng.randf() * TAU)
		if kind == "hats" and rng.randf() < 0.6:
			b = b * Basis(Vector3(1, 0, 0), PI * 0.5)
		mm.set_instance_transform(i, Transform3D(b, pts[i]))
		mm.set_instance_color(i, Decks.BALLOON_COLORS[rng.randi() % Decks.BALLOON_COLORS.size()])
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.45
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Party_" + kind
	mmi.multimesh = mm
	mmi.material_override = m
	if kind != "balloons":
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func D_conf_mesh() -> PlaneMesh:
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.03, 0.04)
	return pm


## Blood spatter, toned down: an irregular dark stain on the floor.
func add_splat(pos: Vector3, size: float, parent: Node3D = null) -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(size * 2.0, size * 2.0)
	m.mesh = pm
	var sh := Shader.new()
	sh.code = SPLAT
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("seed", rng.randf() * 100.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.rotation.y = rng.randf() * TAU
	if parent:
		parent.add_child(m)
		m.global_position = pos
	else:
		m.position = pos
		add_child(m)


func _poster(p: Vector3, n: Vector3, text: String, col: Color, reversed := false) -> void:
	var b := Basis.looking_at(-n, Vector3.UP)
	var paper := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.62, 0.88, 0.006)
	paper.mesh = bm
	paper.material_override = MatLib.get_mat("l26_poster")
	paper.basis = b * Basis(Vector3(0, 0, 1), rng.randf_range(-0.06, 0.06))
	paper.position = p
	S.labels.add_child(paper)
	var copies := 4 if reversed else 1
	for i in copies:
		var l: Label3D = S.label(text, p + Vector3(0, 0.05, 0) + (b.x * (0.012 * (i - 1.5)) + b.y * (0.008 * ((i % 2) * 2 - 1)) if reversed else Vector3.ZERO), n, 0.0034, col, 64)
		l.line_spacing = -8.0
		if reversed:
			l.scale = Vector3(-1, 1, 1)
			l.double_sided = true
			l.modulate = Color(col.r, col.g, col.b, 0.38)


func _posters(sd: Dictionary) -> void:
	var pw: Vector3 = sd["poster_wall"]
	var n := Vector3(0, 0, -1)
	var face := pw + Vector3(0, 0, -0.07)
	var y := Ship.SUN
	_poster(face + Vector3(-1.0, 1.35, 0), n, "TIME\n4 FUN", Color(0.9, 0.15, 0.3))
	_poster(face + Vector3(-0.15, 1.25, 0), n, "PARTY\nALL\nNIGHT", Color(0.15, 0.35, 0.85))
	poster_pos = face + Vector3(0.8, 1.3, 0)
	_poster(poster_pos, n, "TIME\n4 FUN", Color(0.2, 0.2, 0.25), true)
	_poster(Vector3(3.4, y + 1.3, 9.53), n, "FUN\nFUN\nFUN", Color(0.95, 0.55, 0.1))
	_poster(Vector3(4.4, y + 1.2, 9.53), n, "TIME\n4 FUN", Color(0.9, 0.15, 0.3))
	# more on the main and upper decks, torn and tilted
	_poster(Vector3(6.38, 1.4, -30.5), Vector3(1, 0, 0), "TIME\n4 FUN", Color(0.9, 0.15, 0.3))
	_poster(Vector3(-6.38, 1.5, -12.0), Vector3(-1, 0, 0), "PARTY\nTIME", Color(0.2, 0.5, 0.2))
	_poster(Vector3(5.12, Ship.UP + 1.5, -24.0), Vector3(1, 0, 0), "TIME\n4 FUN", Color(0.9, 0.15, 0.3))
	_poster(Vector3(0.0, 1.5, -44.14), Vector3(0, 0, -1), "TIME\n4 FUN", Color(0.9, 0.15, 0.3))


# --------------------------------------------------------------- Partygoers

func _figure_node(parent: Node3D) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var yel := StandardMaterial3D.new()
	yel.albedo_color = Color(0.95, 0.78, 0.12)
	yel.roughness = 0.35
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 1.5
	body.mesh = cap
	body.material_override = yel
	body.position = Vector3(0, 0.95, 0)
	body.scale = Vector3(1.0, 1.0, 0.75)
	n.add_child(body)
	var head := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.34, 0.5, 0.26)
	head.mesh = hb
	head.material_override = yel
	head.position = Vector3(0, 1.92, 0)
	head.rotation.z = 0.22
	n.add_child(head)
	for s: float in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		var am := CapsuleMesh.new()
		am.radius = 0.07
		am.height = 1.25
		arm.mesh = am
		arm.material_override = yel
		arm.position = Vector3(s * 0.34, 1.05, 0.05)
		arm.rotation.z = s * 0.08
		n.add_child(arm)
	return n


func _figures() -> void:
	# main deck hallway's far end, the pool deck, the foredeck; none on the sun deck
	for spec in [[Vector3(0, 0, -42.6), 0.0], [Vector3(-7.4, Ship.UP, -41.0), 70.0], [Vector3(3.0, 0, 46.0), 200.0]]:
		var nd := _figure_node(self)
		nd.position = spec[0]
		nd.rotation_degrees.y = spec[1]
		figures.append({"node": nd, "home": spec[0], "gone": false, "t": 0.0, "seen": 0.0})


func _on_chunk_built(_key: Vector2i, meta: Dictionary) -> void:
	for b in meta.get("balloons", []):
		balloons.append(b)
	var fp: Variant = meta.get("figure", null)
	if fp is Vector3 and not SessionState.is_qa():
		var nd := _figure_node(world.chunks[_key]["node"])
		nd.global_position = fp
		nd.look_at(Vector3(nd.global_position.x, nd.global_position.y, nd.global_position.z) + Vector3(12.0 - fmod(fp.x, 24.0), 0, 12.0 - fmod(fp.z, 24.0)), Vector3.UP)
		figures.append({"node": nd, "home": fp, "gone": false, "t": 0.0, "seen": 0.0})
	for rm in meta.get("rooms", []):
		if rm.has("music"):
			sound.emitter("chiptune", rm["music"], {"bpm": 124.0, "root": 196.0}, -24.0, 9.0)


func _update_figures(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if player == null or cam == null:
		return
	var pp := player.global_position
	for f in figures:
		var nd: Node3D = f["node"]
		if not is_instance_valid(nd):
			continue
		if f["gone"]:
			f["t"] += delta
			if f["t"] > 45.0 and pp.distance_to(f["home"]) > 26.0:
				f["gone"] = false
				nd.visible = true
			continue
		var d := pp.distance_to(nd.global_position)
		var to := (nd.global_position + Vector3.UP * 1.5 - cam.global_position).normalized()
		var looking := (-cam.global_transform.basis.z).dot(to) > 0.95 and d < 32.0
		f["seen"] = f["seen"] + delta if looking else maxf(0.0, f["seen"] - delta)
		if d < 9.0 or f["seen"] > 2.2:
			f["gone"] = true
			f["t"] = 0.0
			nd.visible = false
			Overlay.glitch(0.35)
			if not _said.has("figure"):
				_said["figure"] = true
				Overlay.subtitle("[a figure in yellow - and then it has no-clipped away]", 3.0)


func _update_balloons(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position + Vector3.UP * 1.4
	var lit: bool = player.flashlight.visible
	var now := Time.get_ticks_msec() / 1000.0
	var keep: Array = []
	for b in balloons:
		var nd: Node3D = b["node"]
		if not is_instance_valid(nd):
			continue
		keep.append(b)
		var home: Vector3 = b["home"]
		var d := pp.distance_to(nd.global_position)
		var target := home
		if d < 8.0 and not lit:
			target = home + (pp - home).normalized() * minf(2.6, pp.distance_to(home) - 1.2)
			if not _said.has("balloons"):
				_said["balloons"] = true
				Overlay.subtitle("[rubber squeaks in the dark corner; the balloons turn toward you]", 3.5)
		var bob := Vector3(0, sin(now * 1.3 + float(b["phase"])) * 0.06, 0)
		nd.global_position = nd.global_position.lerp(target + bob, minf(1.0, delta * 0.6))
		if d > 0.3:
			nd.look_at(pp, Vector3.UP)
			nd.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
	balloons = keep


# --------------------------------------------------------------- interactions

func _interactions() -> void:
	for spec in [[Vector3(-2.0, 1.1, 15.6), "main"], [Vector3(2.0, 1.1, 15.6), "main"], [Vector3(-1.6, Ship.UP + 1.1, 12.7), "upper"], [Vector3(1.6, Ship.UP + 1.1, 12.7), "upper"]]:
		add_interactable(spec[0], Vector3(1.4, 2.2, 0.6), "Take the elevator down (the lower decks)", func(_p: Player) -> void: go_down())
	add_interactable(D_hub_doors(), Vector3(3.0, 2.2, 0.8), "Take the elevator back up to the main deck", func(_p: Player) -> void: go_up())
	add_note("l26_name", "The name on the bow",
		"Leaning over the bulwark you can read it on the hull: ADVENTURE. Someone has slashed red paint across it and daubed beside it, crudely: SS Fun =)",
		Vector3(0, 1.0, 66.0), Vector3(6.0, 2.0, 2.0), false)
	add_note("l26_time4fun", "A party poster: TIME 4 FUN",
		"No smiley face on it. Touching posters like this one, or party hats and balloons anywhere in the Backrooms, is how people end up on this ship. Here, it does nothing more.",
		Vector3(0.0, 1.4, -44.6), Vector3(0.9, 1.2, 0.6), false)
	add_note("l26_pool", "The pool",
		"The water is crimson and it reeks of death. Things float in it; some of them still move. You do not look closer.",
		Vector3(0, Ship.UP + 0.8, -46.4), Vector3(8.0, 1.6, 0.8), false)


func D_hub_doors() -> Vector3:
	return Decks.origin(Decks.IX, 0) + Vector3(12.0, 1.1, 14.6)


func go_down() -> void:
	if player == null:
		return
	var p: Vector3 = Decks.hub_arrival()
	world.target = player
	world.build_around(p, 1)
	player.global_position = p
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	Overlay.glitch(0.6)
	sound.play_at("ui", {"kind": "click"}, p, -6.0, "[the elevator chimes. Two decks down. The doors open on a hallway that goes on forever]")
	_set_inside(true)


func go_up() -> void:
	if player == null:
		return
	player.global_position = Vector3(0, 0.05, 14.4)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	Overlay.glitch(0.4)
	sound.play_at("ui", {"kind": "click"}, player.global_position, -6.0, "[the elevator chimes: main deck]")
	_set_inside(false)


func _set_inside(on: bool) -> void:
	if on == inside:
		return
	inside = on
	if on:
		_outdoor = {"bg": environment.background_mode, "amb_src": environment.ambient_light_source, "amb": environment.ambient_light_energy,
			"fog": environment.fog_light_color, "dens": environment.fog_density, "sky": environment.fog_sky_affect}
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color.BLACK
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.7, 0.6, 0.55)
		environment.ambient_light_energy = 0.12
		environment.fog_light_color = Color(0.06, 0.05, 0.05)
		environment.fog_density = 0.035
		sun.visible = false
		sea.visible = false
		Settings.set_reverb(0.7, 0.3)
	else:
		environment.background_mode = _outdoor.get("bg", Environment.BG_SKY)
		environment.ambient_light_source = _outdoor.get("amb_src", Environment.AMBIENT_SOURCE_SKY)
		environment.ambient_light_energy = _outdoor.get("amb", 0.55)
		environment.fog_light_color = _outdoor.get("fog", Color(0.6, 0.62, 0.6))
		environment.fog_density = _outdoor.get("dens", 0.003)
		sun.visible = true
		sea.visible = true
		world.target = null
		Settings.set_reverb(rules["reverb_room"], rules["reverb_wet"])
	if _deck_bed:
		_deck_bed.volume_db = -80.0 if on else -26.0
	if _sea_bed:
		_sea_bed.volume_db = -80.0 if on else -20.0
	if _wind:
		_wind.volume_db = -80.0 if on else -24.0


func _trap_favor(_p: Player, pos: Vector3) -> void:
	if _trapped.has(pos):
		Overlay.toast("Already sprung.", 2.0)
		return
	_trapped[pos] = true
	sound.play_at("knock", {"hits": 1}, pos, 2.0, "[the favour snaps open - something spring-loaded and sharp]")
	Overlay.glitch(0.4)
	if player and not SessionState.is_qa():
		player.hurt(10.0, "a booby-trapped party favour")


# --------------------------------------------------------------- green fog

func _fog(delta: float) -> void:
	fog_t -= delta
	match fog_phase:
		0:
			if fog_t <= 0.0:
				fog_phase = 1
				fog_t = 14.0
				if not SessionState.is_qa():
					Overlay.subtitle("[a green fog rolls up the hull and over the decks, like a magician's cape]", 4.5)
		1:
			fog_k = clampf(1.0 - fog_t / 14.0, 0.0, 1.0)
			if fog_t <= 0.0:
				fog_phase = 2
				fog_t = 4.0
				relocate((loc + 1 + rng.randi() % (LOCATIONS.size() - 1)) % LOCATIONS.size())
		2:
			fog_k = 1.0
			if fog_t <= 0.0:
				fog_phase = 3
				fog_t = 12.0
		3:
			fog_k = clampf(fog_t / 12.0, 0.0, 1.0)
			if fog_t <= 0.0:
				fog_phase = 0
				fog_k = 0.0
				fog_t = FOG_PERIOD * (0.85 + 0.3 * rng.randf())
	if inside:
		return
	var Lc: Dictionary = LOCATIONS[loc]
	environment.fog_light_color = (Lc["fog"] as Color).lerp(Color(0.22, 0.62, 0.3), fog_k)
	environment.fog_density = lerpf(float(Lc["dens"]), 0.16, fog_k * fog_k)
	environment.fog_sky_affect = lerpf(0.7, 1.0, fog_k)


## The cape lifts and the ship is somewhere else.
func relocate(i: int) -> void:
	loc = i
	relocations += 1
	var Lc: Dictionary = LOCATIONS[i]
	sky_mat.sky_top_color = Lc["top"]
	sky_mat.sky_horizon_color = Lc["hor"]
	sky_mat.ground_horizon_color = Lc["hor"]
	var sv: Vector2 = Lc["sun"]
	sun.rotation_degrees = Vector3(-sv.x, sv.y, 0)
	sun.light_color = Lc["sun_col"]
	sun.light_energy = Lc["sun_e"]
	var on_land: bool = str(Lc["land"]) != ""
	land.visible = on_land
	if on_land:
		land.material_override = MatLib.get_mat(Lc["land"])
	sea.surface_mesh.visible = not on_land
	sea.aabb = AABB(Vector3(-1500, Ship.SEA_Y - 60.0, -1500), Vector3(3000, 60.0, 3000)) if not on_land else AABB(Vector3(0, -9000, 0), Vector3(1, 1, 1))
	if _sea_bed:
		_sea_bed.volume_db = -80.0 if (on_land or inside) else -20.0
	Overlay.glitch(0.7)
	if not SessionState.is_qa():
		Overlay.subtitle("[the fog lifts. The ship is somewhere else: %s]" % Lc["name"], 4.0)


# --------------------------------------------------------------- audio, frame

func _sounds() -> void:
	_sea_bed = sound.bed("water_bed", {"bright": 0.3, "seconds": 8.0}, -20.0)
	_wind = sound.bed("wind", {"seconds": 7.0}, -24.0)
	_deck_bed = sound.bed("pad", {"root": 55.0, "chord": [0, 7, 12], "bright": 0.06, "seconds": 10.0}, -26.0)
	for mp in S.music_points:
		sound.emitter("chiptune", mp, {"bpm": 128.0, "root": 220.0}, -22.0, 8.0)
	sound.emitter("fluorescent_hum", Vector3(0, 2.8, -18.0), {"base": 120.0, "rasp": 0.15, "seconds": 3.0}, -30.0, 12.0)
	sound.oneshot("creak", {"freq": 60.0}, 14.0, 30.0, 14.0, "[the hull groans]", -18.0)
	sound.oneshot("knock", {"hits": 2}, 18.0, 40.0, 10.0, "[knocking from behind a cabin door]", -16.0)
	sound.oneshot("whisper", {"seconds": 2.0}, 20.0, 45.0, 20.0, "[a scream, somewhere below, echoing]", -22.0)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[music thumping somewhere in the ship; the deck is littered and stained]", 4.0)


func level_process(delta: float) -> void:
	_fog(delta)
	_update_figures(delta)
	_update_balloons(delta)
	if player == null:
		return
	var p := player.global_position
	if p.x > 2000.0 and not inside:
		_set_inside(true)
	elif p.x < 2000.0 and inside and world.target != null:
		_set_inside(false)
	if not _said.has("sun") and p.y > Ship.SUN - 0.3 and p.x < 2000.0 and not SessionState.is_qa():
		_said["sun"] = true
		Overlay.subtitle("[the top of the ship. There is nowhere higher to go, and no one up here]", 3.5)


# --------------------------------------------------------------- QA

func _shots() -> void:
	add_shot("stern_deck", Vector3(-2.0, 1.62, -68.5), Vector3(1.5, 2.2, -50.0), {"flashlight": false})
	add_shot("ship_from_sea", Vector3(52.0, 13.0, 44.0), Vector3(0.0, 2.0, -8.0), {"flashlight": false})
	add_shot("stateroom_hall", Vector3(0.3, 1.62, 9.0), Vector3(0.0, 1.3, -40.0), {"flashlight": false})
	add_shot("pool_deck", Vector3(6.8, Ship.UP + 1.62, -40.5), Vector3(-1.0, Ship.UP + 0.2, -52.0), {"flashlight": false})
	add_shot("sun_deck_posters", Vector3(-2.2, Ship.SUN + 1.62, 4.2), poster_pos + Vector3(-0.5, -0.2, 0), {"flashlight": false})
	add_shot("lower_decks", Decks.hub_arrival() + Vector3(0, 1.57, 0.0), Decks.hub_arrival() + Vector3(0, 1.3, -30.0), {"flashlight": false, "prepare": _prep_inside})
	var cr := RandomNumberGenerator.new()
	cr.seed = 3838
	var at := cr.randf_range(2.0, 8.5)
	var o := Decks.origin(Decks.IX + 1, 0)
	add_shot("party_room", o + Vector3(Decks.B + at - 0.2, 1.62, Decks.A - 1.0), o + Vector3(Decks.B + 5.0, 0.7, 3.0), {"flashlight": false, "prepare": _prep_inside})


func _prep_inside() -> void:
	if not inside:
		go_down()
	for i in 4:
		await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "the reversed poster hangs on the sun deck", "ok": poster_pos.y > Ship.SUN})
	var l0 := loc
	relocate((loc + 1) % LOCATIONS.size())
	out.append({"what": "the green fog relocates the ship (sky, sun and water change)", "ok": loc != l0 and relocations > 0})
	relocate(0)
	var back := player.global_position
	go_down()
	await get_tree().physics_frame
	var down_ok: bool = inside and world.chunks.size() >= 9 and player.global_position.x > 2000.0
	var clone_a: Dictionary = world.meta_of(Vector2i(Decks.IX + 1, 0))
	var clone_b: Dictionary = world.meta_of(Vector2i(Decks.IX - 1, 0))
	var themes_a: Array = clone_a.get("rooms", []).map(func(r): return r.get("theme", ""))
	var themes_b: Array = clone_b.get("rooms", []).map(func(r): return r.get("theme", ""))
	out.append({"what": "the elevator reaches the lower decks hub; chunks stream around it", "ok": down_ok, "detail": world.chunks.size()})
	out.append({"what": "the same birthday room repeats along the hub hallway", "ok": "birthday" in themes_a and "birthday" in themes_b})
	go_up()
	await get_tree().physics_frame
	out.append({"what": "the elevator returns to the main deck", "ok": not inside and player.global_position.x < 100.0})
	player.global_position = back
	return out
