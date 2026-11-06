extends LevelBase
## Level 14 — "Paradise" (Backrooms Wikidot rev 51, accessed 2026-11-04; cite:
## CutTheBirch, CC BY-SA 3.0). Dossier: docs/canon/levels/L014.md.
## Second-person lure prose: a night forest oasis, crashing waterfalls, crimson
## grass wet with dew, a starlit sky the branches reach for, whispers, a
## cacophony, guests' bones in the soil, children in rows howling at the moon,
## a promised feast, and no exit. NO ENTITY PER SOURCE: the danger is the lure,
## a stateful perceptual system. `lure` rises with time, nearness and gazing;
## the world grows lovelier, the forest falls silent under singing, your heading
## drifts inward, you grow lighter, and things change while unobserved; at full
## lure you lie down and stay. `resolve` rises only while walking away with your
## back turned and drains beauty toward the truth; when you can no longer hear
## them you are out (mechanism is ADAPTATION, see level.json). The world is a
## finite streaming window (32 m chunks, radius 2) hidden by night fog and trees.

const Land := preload("res://levels/L014/L014_land.gd")
const Art := preload("res://levels/L014/L014_art.gd")
const CS := 32.0
const START_XZ := Vector2(9.0, 23.0)
const QA_EXIT_XZ := Vector2(30.9, 78.9)
const ROWS_XZ := Vector2(17.5, -8.5)
const FEAST_C := Vector2(0.0, 2.0)
const RESOLVE_S := 14.0
const FOG := Color(0.05, 0.03, 0.065)
const FOG_LURE := Color(0.10, 0.026, 0.06)

var land
var world: ChunkWorld
var qa_fixture := false
var m_ground: ShaderMaterial
var m_grass: ShaderMaterial
var m_tree: ShaderMaterial
var m_fig: ShaderMaterial
var m_sky: ShaderMaterial
var m_falls: ShaderMaterial
var m_bones: StandardMaterial3D
var tree_meshes: Array = []
var tuft: ArrayMesh
var bones: ArrayMesh
var keep_out: Array = []
var ring: Array = []
var rows_c := Vector3.ZERO
var m_rock: ShaderMaterial
var m_soil: StandardMaterial3D
var soil_mesh: SphereMesh
var lure := 0.25
var resolve := 0.0
var peak := 0.25
var surrender := 0.0
var sur_t := -1.0
var presence := 1.0
var feast_on := false
var rows_mmi: MultiMeshInstance3D
var feast: GeoKit
var candle: OmniLight3D
var follow: ExitTrigger
var _last := Vector3.ZERO
var _said := {}
var _arng := RandomNumberGenerator.new()
var _whisper_t := 5.0
var _howl_t := 6.0
var _howl := -1.0
var _glitch := 0.0
var _looked_back := 0.0
var _lb_cool := 0.0
var b_choir: AudioStreamPlayer
var b_caco: AudioStreamPlayer
var b_static: AudioStreamPlayer
var b_crickets: AudioStreamPlayer
var b_wind: AudioStreamPlayer
var b_heart: AudioStreamPlayer
var howlers: Array = []
var _forced := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	land = Land.new(level_seed)
	_arng.seed = hash([level_seed, "lure"])
	peak = 0.6 if qa_fixture else 0.25
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 400.0
	rules["reverb_room"] = 0.35
	rules["reverb_wet"] = 0.08
	_env()
	_materials()
	var sy: float = land.h(START_XZ.x, START_XZ.y)
	add_arrival("start", Vector3(START_XZ.x, sy + 0.05, START_XZ.y), rad_to_deg(atan2(11.0, 37.0)))
	var door := _door_frame()
	keep_out = [[START_XZ, 4.0], [Vector2(door.origin.x, door.origin.z), 4.0], [FEAST_C, 6.0]]
	for f in [0.2, 0.45, 0.7]:
		keep_out.append([START_XZ * (1.0 - f), 5.5])   # the view down into the Clearing
	ring = _ring_xfs()
	rows_c = Vector3(ROWS_XZ.x, land.h(ROWS_XZ.x, ROWS_XZ.y) + 1.2, ROWS_XZ.y) + Vector3(0.0, 0.0, 2.7)
	keep_out.append([ROWS_XZ + Vector2(0.0, 2.7), 8.5])
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	var tag := TransitionService.pending_arrival
	var at: Transform3D = arrivals.get(tag, arrivals["start"])
	world.build_around(at.origin, 2)
	_falls()
	_rocks()
	_rows()
	_guests_ring()
	_feast()
	_door(door)
	if qa_fixture:
		# QA fixture: a fixed region uphill, directly away from the Clearing
		var qy: float = land.h(QA_EXIT_XZ.x, QA_EXIT_XZ.y)
		var t := add_exit("L014>EXT#1", "condition", Vector3(QA_EXIT_XZ.x, qy + 2.0, QA_EXIT_XZ.y), Vector3(14, 16, 14), "")
		if t:
			t.condition = _can_leave
	else:
		follow = add_exit("L014>EXT#1", "condition", at.origin + Vector3.UP, Vector3(3, 4, 3), "")
		if follow:
			follow.condition = _can_leave
	_sounds()
	add_shot("basin", Vector3(START_XZ.x, sy + 1.62, START_XZ.y), Vector3(-2.0, 4.5, -14.0),
		{"flashlight": false, "prepare": _prep.bind(0.3, 0.0, Vector3(START_XZ.x, sy, START_XZ.y))})
	var gy: float = land.h(-7.0, 11.0)
	add_shot("guests", Vector3(-7.0, gy + 1.55, 11.0), Vector3(4.0, 5.0, -14.0),
		{"flashlight": false, "prepare": _prep.bind(0.78, 0.0, Vector3(-7.0, gy, 11.0))})
	add_landmark("Basin rim (start)", Vector3(START_XZ.x, sy, START_XZ.y))
	add_landmark("The Clearing", Vector3(0, 0, 0))
	add_landmark("The Falls", Vector3(-3, 0, -12))


func _env() -> void:
	m_sky = Art.shader_mat(Art.SKY)
	var sky := Sky.new()
	sky.sky_material = m_sky
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.15, 0.14, 0.24)
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = FOG
	environment.fog_light_energy = 1.0
	environment.fog_density = 1.0
	environment.fog_depth_begin = 7.0
	environment.fog_depth_end = 60.0
	environment.fog_depth_curve = 1.35
	environment.fog_sky_affect = 0.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.06
	# the moon: low in the north-north-west, so it hangs over the Falls
	sun = DirectionalLight3D.new()
	sun.name = "Moon"
	sun.rotation_degrees = Vector3(-31.0, -162.5, 0.0)
	sun.light_color = Color(0.88, 0.9, 1.0)
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	sun.shadow_bias = 0.06
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 55.0
	add_child(sun)
	# faint starlight fill from the open southern sky, so the falls cliff
	# (backlit by the moon) keeps its shape
	var fill := DirectionalLight3D.new()
	fill.name = "Starlight"
	fill.rotation_degrees = Vector3(-35.0, 20.0, 0.0)
	fill.light_color = Color(0.45, 0.5, 0.8)
	fill.light_energy = 0.14
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	add_child(fill)


func _materials() -> void:
	m_ground = Art.shader_mat(Art.GROUND)
	m_ground.set_shader_parameter("moon_dir", sun.basis.z)
	m_grass = Art.shader_mat(Art.GRASS)
	m_tree = Art.shader_mat(Art.TREE)
	m_fig = Art.shader_mat(Art.FIGURE)
	m_falls = Art.shader_mat(Art.FALLS)
	m_bones = StandardMaterial3D.new()
	m_bones.albedo_color = Color(0.86, 0.83, 0.74)
	m_bones.roughness = 0.2
	m_bones.metallic_specular = 0.9
	m_bones.rim_enabled = true
	m_bones.rim = 0.4
	m_rock = Art.shader_mat(Art.ROCK)
	m_soil = MatLib.standard(Color(0.055, 0.035, 0.03), 0.9)
	soil_mesh = SphereMesh.new()
	soil_mesh.radial_segments = 12
	soil_mesh.rings = 6
	for v in 3:
		tree_meshes.append(Art.tree_mesh(v))
	tuft = Art.tuft_mesh()
	bones = Art.bones_mesh()
	MatLib.register("l14_water", MatLib.water({"shallow_color": Color(0.05, 0.07, 0.12), "deep_color": Color(0.005, 0.01, 0.03),
		"absorption": 1.2, "clarity": 0.35, "wave_height": 0.03, "wave_scale": 0.9, "foam_amount": 0.5, "dark_surface": 0.55}))
	MatLib.define("l14_rust", {"albedo_a": Color(0.24, 0.1, 0.05), "albedo_b": Color(0.14, 0.07, 0.04), "stain_amount": 0.5}, "rust")
	for spec in [["l14_cloth", Color(0.62, 0.56, 0.48), 0.9, 0.0, 0.0], ["l14_plate", Color(0.92, 0.92, 0.9), 0.15, 0.0, 0.0],
			["l14_gold", Color(0.8, 0.62, 0.3), 0.25, 1.0, 0.0], ["l14_flame", Color(1.0, 0.7, 0.35), 1.0, 0.0, 5.0]]:
		var m := MatLib.standard(spec[1], spec[2], spec[3], spec[1], spec[4])
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		m.distance_fade_min_distance = 8.0
		m.distance_fade_max_distance = 14.0
		MatLib.register(spec[0], m)


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var o := Vector3(cx * CS, 0, cz * CS)
	var hs: PackedFloat32Array = land.chunk_heights(cx, cz)
	land.build_ground(node, cx, cz, hs, m_ground)
	var tr: Array = land.trees(cx, cz, hs, keep_out)
	var by_var: Array = [[], [], []]
	var body := StaticBody3D.new()
	body.name = "Trunks"
	node.add_child(body)
	for t in tr:
		var sc: float = t[2]
		var pos: Vector3 = t[0]
		by_var[t[3]].append(Transform3D(Basis(Vector3.UP, t[1]).scaled(Vector3.ONE * sc), pos))
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.55 * sc, 3.0, 0.55 * sc)
		cs.shape = bs
		cs.position = o + pos + Vector3(0, 1.4, 0)
		cs.set_meta("surface", "wood")
		body.add_child(cs)
	for i in 3:
		if not by_var[i].is_empty():
			var mmi := Art.multimesh(tree_meshes[i], by_var[i], m_tree, true)
			mmi.position = o
			node.add_child(mmi)
	var gs: Array = land.guests(cx, cz, hs)
	var bare: Array = []
	for g in gs:
		bare.append(Vector2(o.x + g.origin.x, o.z + g.origin.z))
	for g in ring:
		bare.append(Vector2(g.origin.x, g.origin.z))
	var gr := Art.multimesh(tuft, land.grass(cx, cz, hs, 0.8, bare), m_grass, false)
	gr.position = o
	gr.visibility_range_end = 48.0
	node.add_child(gr)
	if not gs.is_empty():
		_guest_set(node, gs, o)
	return {"trees": tr.size()}


# ----------------------------------------------------------------- anchors

## SOURCE: "the crashing waterfalls" — two falls off the north cliff into pools.
func _falls() -> void:
	for f in [[Vector3(-3.0, 8.55, -17.4), 4.6, 3.2], [Vector3(7.0, 8.55, -17.4), 3.8, 1.4]]:
		var mi := MeshInstance3D.new()
		mi.mesh = Art.falls_mesh(f[0], Land.POOL_Y, f[1], f[2])
		mi.material_override = m_falls
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	var mist := Art.shader_mat(Art.MIST.replace("void fragment() {", "void vertex() { MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]); }\nvoid fragment() {"))
	for mp in [Vector3(-3.0, 1.2, -11.6), Vector3(-1.0, 2.2, -12.4), Vector3(-5.5, 0.8, -10.5), Vector3(7.0, 1.0, -12.4)]:
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(7.0, 4.0)
		q.mesh = qm
		q.material_override = mist
		q.position = mp
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)
	for pl in [[Vector3(-8.4, -2.6, -16.4), Vector3(2.4, Land.POOL_Y, -5.6)], [Vector3(2.9, -2.0, -15.9), Vector3(10.2, Land.POOL_Y, -8.5)]]:
		var wv := WaterVolume.new()
		wv.name = "Pool"
		add_child(wv)
		wv.setup(pl[0], pl[1], "l14_water", true)
		wv.tint = Color(0.04, 0.06, 0.1)


## ADAPTATION: boulders on the cliff lip, its foot and the pool rims.
func _rocks() -> void:
	var m := m_rock
	var r := RandomNumberGenerator.new()
	r.seed = 1499
	var groups: Array = [[], []]
	for spec in [[-12.5, -15.4, 2.6], [-9.0, -14.6, 1.6], [1.6, -15.3, 1.8], [12.0, -15.6, 2.4], [15.5, -16.6, 2.0],
			[-8.6, -8.2, 1.2], [-1.0, -6.4, 0.9], [3.6, -7.8, 1.1], [10.6, -9.6, 1.0], [-14.0, -18.5, 1.8], [18.0, -12.0, 1.6]]:
		var x: float = spec[0]
		var z: float = spec[1]
		var s: float = spec[2] * r.randf_range(0.85, 1.15)
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s * r.randf_range(0.9, 1.3), s * r.randf_range(0.55, 0.85), s))
		groups[r.randi() % 2].append(Transform3D(b, Vector3(x, land.h(x, z) - s * 0.25, z)))
	# crags breaking up the cliff face (kept clear of the two falls)
	var fx := -19.5
	while fx < 16.5:
		fx += r.randf_range(1.6, 3.0)
		if absf(fx + 3.0) < 2.4 or absf(fx - 7.0) < 1.4:
			continue
		for lvl in 2:
			var fy := r.randf_range(1.2, 3.2) + lvl * 2.8
			var fz := -14.0
			while land.h(fx, fz) < fy and fz > -20.0:
				fz -= 0.25
			var fs := r.randf_range(1.4, 2.6)
			var fb := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(fs * 1.2, fs * r.randf_range(0.6, 1.0), fs * 0.8))
			groups[r.randi() % 2].append(Transform3D(fb, Vector3(fx, fy, fz + 0.3)))
	for g in 2:
		var mi := Art.multimesh(Art.rock_mesh(1500 + g), groups[g], m, true)
		mi.name = "Boulders%d" % g
		add_child(mi)


## SOURCE: "Children line up in rows. They howl beautifully at the moon."
## Unclassified lure imagery, not agents: silhouettes on the basin slope that
## dissolve as you come near and that come and go only while unobserved.
func _rows() -> void:
	var xfs: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 1414
	var f := Vector2(-0.3, -0.95)          # facing the moon
	var u := Vector2(0.95, -0.3)
	for row in 4:
		for i in 6:
			var q := ROWS_XZ + u * ((i - 2.5) * 2.0 + (row % 2) * 0.9 + r.randf_range(-0.2, 0.2)) - f * (row * 1.8 + r.randf_range(-0.15, 0.15))
			var s := r.randf_range(1.05, 1.25)
			xfs.append(Transform3D(Basis(Vector3.UP, 0.305 + r.randf_range(-0.08, 0.08)).scaled(Vector3.ONE * s), Vector3(q.x, land.h(q.x, q.y) - 0.02, q.y)))
	rows_mmi = Art.multimesh(Art.child_mesh(), xfs, m_fig, false)
	rows_mmi.name = "Rows"
	add_child(rows_mmi)


## SOURCE: "the other guests lying peacefully in the soil ... their bones
## glistening in the moonlight" — a loose ring around the Clearing.
func _guests_ring() -> void:
	_guest_set(self, ring, Vector3.ZERO)


func _ring_xfs() -> Array:
	var xfs: Array = []
	for k in 11:
		var a := TAU * k / 11.0 + 0.4
		var rr := 5.8 + (k % 3) * 1.7
		var p := Vector2(cos(a), sin(a)) * rr
		if p.y < -6.0:
			continue
		var yaw := atan2(p.x, p.y) + PI + (k % 2) * 0.35
		xfs.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, land.h(p.x, p.y) + 0.01, p.y)))
	return xfs


## Bones lying in a shallow bare hollow of dark soil.
func _guest_set(parent: Node3D, xfs: Array, o: Vector3) -> void:
	var bm := Art.multimesh(bones, xfs, m_bones, true)
	bm.position = o
	parent.add_child(bm)
	var soil: Array = []
	for x in xfs:
		var t: Transform3D = x
		soil.append(Transform3D(t.basis * Basis.from_scale(Vector3(0.75, 0.05, 1.35)), t.origin + Vector3(0, -0.012, 0.05)))
	var sm := Art.multimesh(soil_mesh, soil, m_soil, false)
	sm.position = o
	parent.add_child(sm)


## SOURCE: "We'll have a great feast when you come." ADAPTATION: a set table
## that appears in the Clearing only once the lure is strong, swaps only while
## unobserved, and dissolves as you approach into a long mound of soil.
func _feast() -> void:
	var y: float = land.h(FEAST_C.x, FEAST_C.y)
	var c := Vector3(FEAST_C.x, y, FEAST_C.y)
	var mound := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radial_segments = 16
	sm.rings = 8
	mound.mesh = sm
	mound.scale = Vector3(4.4, 0.42, 1.0)
	mound.position = c + Vector3(0, -0.05, 0)
	mound.material_override = MatLib.standard(Color(0.08, 0.045, 0.04), 0.95)
	add_child(mound)
	var mb := Art.multimesh(bones, [Transform3D(Basis(Vector3.UP, PI * 0.5), c + Vector3(-2.2, 0.12, 0.1)),
		Transform3D(Basis(Vector3.UP, -PI * 0.5), c + Vector3(1.6, 0.14, -0.2))], m_bones, true)
	add_child(mb)
	feast = kit("Feast")
	var ty := y + 0.76
	feast.box(c + Vector3(0, 0.76, 0), Vector3(7.6, 0.05, 1.3), "l14_cloth", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		feast.box(c + Vector3(0, 0.56, s * 0.66), Vector3(7.6, 0.4, 0.02), "l14_cloth", GeoKit.ALL, false)
	for e in [-1.0, 1.0]:
		feast.box(c + Vector3(e * 3.81, 0.56, 0), Vector3(0.02, 0.4, 1.34), "l14_cloth", GeoKit.ALL, false)
	for i in 12:
		var x := -3.3 + i * 0.6
		for s in [-1.0, 1.0]:
			feast.cylinder(Vector3(x, ty + 0.03, c.z + s * 0.38), 0.14, 0.012, "l14_plate", 12, false)
		if i % 2 == 0:
			feast.cylinder(Vector3(x + 0.3, ty + 0.105, c.z + 0.08), 0.035, 0.16, "l14_gold", 8, false)
	for i in 5:
		var x := -3.0 + i * 1.5
		feast.cylinder(Vector3(x, ty + 0.155, c.z - 0.05), 0.025, 0.26, "l14_plate", 8, false)
		feast.box(Vector3(x, ty + 0.33, c.z - 0.05), Vector3(0.05, 0.1, 0.05), "l14_flame", GeoKit.ALL, false)
	feast.commit()
	feast.root.visible = false
	candle = OmniLight3D.new()
	candle.light_color = Color(1.0, 0.68, 0.38)
	candle.light_energy = 0.0
	candle.omni_range = 8.5
	candle.position = c + Vector3(0, 1.3, 0)
	add_child(candle)


## The rusted door set into the Gully wall, where wanderers from Level 49's
## bunker doors arrive. ADAPTATION: L049's page names the door; the arrival
## side is unstated. It does not open from this side (no exit is documented).
func _door_frame() -> Transform3D:
	var a: Vector2 = Land.GULLY[1]
	var b: Vector2 = Land.GULLY[2]
	var p := a.lerp(b, 0.55)
	var dir := (b - a).normalized()
	var n := Vector2(dir.y, -dir.x)
	if n.y > 0.0:
		n = -n
	var head: Vector2 = Land.GULLY[0]
	var to_head := (head - p).normalized()
	var fp := p + n * 1.2
	add_arrival("from_L049", Vector3(fp.x, land.h(fp.x, fp.y) + 0.05, fp.y), rad_to_deg(atan2(-to_head.x, -to_head.y)))
	var dp := p + n * 2.8
	var base: float = land.h(dp.x, dp.y) - 0.15
	return Transform3D(Basis(Vector3.UP, atan2(n.x, n.y)), Vector3(dp.x, base, dp.y))


func _door(xf: Transform3D) -> void:
	var k := kit("RustedDoor")
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 1.0, 0)), Vector3(1.0, 2.6, 0.12), "l14_rust")
	k.box_xf(xf * Transform3D(Basis(), Vector3(-0.6, 1.1, -0.05)), Vector3(0.16, 2.8, 0.22), "l14_rust")
	k.box_xf(xf * Transform3D(Basis(), Vector3(0.6, 1.1, -0.05)), Vector3(0.16, 2.8, 0.22), "l14_rust")
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 2.42, -0.05)), Vector3(1.36, 0.18, 0.22), "l14_rust")
	k.box_xf(xf * Transform3D(Basis(), Vector3(0.3, 1.05, -0.09)), Vector3(0.08, 0.2, 0.06), "l14_rust", GeoKit.ALL, false)
	k.commit()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bark := Color(1, 0, 0, 1)
	for rt in [[Vector3(-0.8, 2.6, -0.2), Vector3(0.7, 0.2, -0.14)], [Vector3(0.75, 2.5, -0.2), Vector3(-0.5, 0.0, -0.14)],
			[Vector3(-0.2, 2.8, -0.25), Vector3(0.2, 1.2, -0.12)]]:
		Art.tube(st, rt[0], rt[1], 0.07, 0.03, 5, bark, bark)
	var roots := MeshInstance3D.new()
	roots.mesh = st.commit()
	roots.material_override = m_tree
	roots.transform = xf
	add_child(roots)
	add_interactable(xf * Vector3(0, 1.1, -0.35), Vector3(1.2, 2.2, 0.6), "Try the rusted door", _try_door)


func _try_door(_p: Player) -> void:
	Overlay.toast("The rusted door has grown into the rock, and roots hold it shut. It does not open from this side.", 4.0)


# ------------------------------------------------------------------ sound

func _sounds() -> void:
	sound.emitter("water_bed", Vector3(-3.0, 1.5, -12.5), {"bright": 2600.0, "seconds": 5.0}, 0.0, 75.0)
	sound.emitter("water_bed", Vector3(7.0, 1.5, -12.6), {"bright": 1800.0, "seconds": 4.0}, -5.0, 55.0)
	b_wind = sound.bed("wind", {"seconds": 9.0}, -24.0)
	b_crickets = sound.bed("crickets", {}, -26.0)
	b_choir = sound.bed("pad", {"root": 220.0, "chord": [0, 7, 15], "bright": 0.2, "seconds": 6.0}, -80.0, "Music")
	b_caco = sound.bed("pad", {"root": 233.1, "chord": [0, 1, 6, 11], "bright": 0.6, "seconds": 5.0}, -80.0)
	b_static = sound.bed("static", {}, -80.0)
	b_heart = sound.bed("heartbeat", {}, -80.0)
	for i in 3:
		var hp := AudioStreamPlayer3D.new()
		hp.stream = AudioSynth.get_stream("pad", {"root": 392.0 + i * 37.0, "chord": [0, 12], "bright": 0.1, "seconds": 4.0})
		hp.volume_db = -80.0
		hp.max_distance = 160.0
		hp.unit_size = 14.0
		hp.bus = "Ambience"
		hp.position = rows_c + Vector3(-5.0 + i * 5.0, 0, 0)
		add_child(hp)
		hp.play()
		howlers.append(hp)


func on_player_ready() -> void:
	world.target = player
	_last = player.global_position
	_apply(0.0, true)
	Overlay.subtitle("[It's right there below you. Keep going.]", 5.0)


# ---------------------------------------------------------------- the lure

## Core state step (pure in its inputs, so the self-test can drive it).
## d = distance to the Clearing, face = 1 when looking at it, radial = speed
## away from it (m/s), spd = ground speed, up = gazing at the sky (0..1).
func step_lure(dt: float, d: float, face: float, radial: float, spd: float, up: float) -> void:
	var prox := 1.0 - smoothstep(10.0, 90.0, d)
	var beauty := maxf(smoothstep(0.75, 0.97, face) * (1.0 - smoothstep(20.0, 75.0, d)), up)
	var still := 1.0 if spd < 0.3 else 0.0
	var gain := 0.0025 + 0.009 * prox + 0.005 * beauty + 0.004 * still * (0.4 + prox)
	if radial > 0.6 and face < -0.3:
		resolve += dt / RESOLVE_S * (1.0 - 0.35 * lure)
		lure -= dt * 0.012
	elif face > 0.55 and resolve > 0.05:
		resolve -= dt * 0.3
		_looked_back += dt
		lure += gain * dt
	else:
		resolve -= dt * 0.03
		lure += gain * dt
	if face <= 0.55:
		_looked_back = maxf(0.0, _looked_back - dt)
	lure = clampf(lure, 0.0, 1.0)
	resolve = clampf(resolve, 0.0, 1.0)
	peak = maxf(peak, lure)


func _can_leave() -> bool:
	return resolve >= 1.0 and peak >= 0.5 and player != null and Vector2(player.global_position.x, player.global_position.z).length() > 40.0


func level_process(delta: float) -> void:
	if player == null or delta <= 0.0:
		return
	var p := player.global_position
	var vel := (p - _last) / delta
	_last = p
	if vel.length() > 30.0:
		vel = Vector3.ZERO
	var fwd := -player.camera.global_transform.basis.z
	var flat := Vector2(fwd.x, fwd.z).normalized()
	var d := Vector2(p.x, p.z).length()
	var to_c := -Vector2(p.x, p.z) / maxf(d, 0.01)
	var face := flat.dot(to_c)
	var radial := Vector2(vel.x, vel.z).dot(-to_c)
	if not _forced and sur_t < 0.0:
		step_lure(delta, d, face, radial, Vector2(vel.x, vel.z).length(), smoothstep(0.35, 0.7, fwd.y))
	if follow:
		follow.global_position = p + Vector3.UP
	_body(delta, to_c, face)
	_messages(delta)
	_apply(delta, false)
	_audio(delta, p)
	_surrender(delta)


## The pull: heading drifts toward the Clearing, feet are light going in and
## heavy going out, and you grow lighter ("you can almost float away").
func _body(delta: float, to_c: Vector2, face: float) -> void:
	if player.frozen or player.qa_active:
		return
	if lure > 0.35:
		var want := atan2(-to_c.x, -to_c.y)
		var diff := wrapf(want - player.rotation.y, -PI, PI)
		var rate := (lure - 0.35) * 0.32 * (1.0 - resolve)
		player.rotation.y += signf(diff) * minf(absf(diff), rate * delta)
	var k := 1.0 + 0.22 * lure * maxf(face, 0.0) - 0.3 * lure * maxf(-face, 0.0)
	player.walk_speed = 3.1 * k
	player.sprint_speed = 5.3 * k
	var light := smoothstep(0.6, 1.0, lure)
	player.gravity = 9.8 - 3.2 * light
	player.jump_velocity = 4.3 + 1.0 * light


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if not _said.has(key):
		_said[key] = true
		Overlay.subtitle(text, secs)


## Paraphrased lure voice (never long page quotes).
func _messages(delta: float) -> void:
	if lure > 0.3:
		_say("l1", "[The forest is whispering to you.]")
	if lure > 0.45:
		_say("l2", "[Everyone here looks so content. Why shouldn't you be?]")
	if lure > 0.6:
		_say("l3", "[It's hard to hold a thought here. It's easier not to.]")
	if lure > 0.75:
		_say("l4", "[You feel light. You could drift right up into the stars.]")
	if lure > 0.86:
		_say("l5", "[Something is gently rearranging your thoughts.]")
	if lure > 0.95:
		_say("l6", "[Lie down. Rest with the others.]", 5.0)
	if resolve > 0.25:
		_say("r1", "[You keep walking. The singing is behind you now.]")
	if resolve > 0.6:
		_say("r2", "[The voices are fainter. The grass looks duller, browner.]")
	_lb_cool -= delta
	if _looked_back > 0.6 and _lb_cool <= 0.0:
		_looked_back = 0.0
		_lb_cool = 8.0
		Overlay.subtitle("[You looked back. They are all still there, waiting.]", 3.5)
	if resolve > 0.97:
		_say("r3", "[You can't hear them anymore.]", 5.0)


## Everything the lure and the resolve change on screen.
func _apply(delta: float, snap: bool) -> void:
	var L := lure
	var T := resolve
	for m in [m_ground, m_grass, m_tree]:
		m.set_shader_parameter("lure", L)
		m.set_shader_parameter("truth", T)
	m_sky.set_shader_parameter("star_gain", 1.0 + 1.3 * L - 0.55 * T)
	m_sky.set_shader_parameter("band_gain", 1.0 + 1.1 * L - 0.6 * T)
	var fc := FOG.lerp(FOG_LURE, L * 0.75 * (1.0 - T))
	environment.fog_light_color = fc
	m_sky.set_shader_parameter("horizon", Vector3(fc.r, fc.g, fc.b))
	m_fig.set_shader_parameter("fogc", Vector3(fc.r, fc.g, fc.b))
	environment.adjustment_saturation = 1.0 + 0.45 * L - 0.6 * T
	environment.glow_intensity = 0.45 + 0.55 * L
	environment.tonemap_exposure = 1.15 + 0.2 * L - 0.12 * T
	m_bones.roughness = lerpf(lerpf(0.2, 0.5, L), 0.1, T)
	Overlay.set_screen_effect("vignette", 0.25 + 0.3 * L)
	Overlay.set_screen_effect("desaturate", 0.35 * T)
	_glitch = maxf(0.0, _glitch - delta * 2.5)
	if L > 0.75 and _arng.randf() < delta * 0.12 * (L - 0.7) * 10.0:
		_glitch = 0.18       # "I bet you feel your mind leaking."
	Overlay.set_screen_effect("glitch", _glitch)
	# things that change only while unobserved
	var want_rows := 1.0 if (L > 0.22 and T < 0.6) else 0.0
	var want_feast := L > 0.55 and T < 0.4
	var cam := get_viewport().get_camera_3d()
	if snap or cam == null:
		presence = want_rows
		_set_feast(want_feast)
	else:
		if not cam.is_position_in_frustum(rows_c):
			presence = move_toward(presence, want_rows, delta * 2.0)
		if want_feast != feast_on and not cam.is_position_in_frustum(Vector3(FEAST_C.x, 0.8, FEAST_C.y)):
			_set_feast(want_feast)
	m_fig.set_shader_parameter("presence", presence)


func _set_feast(on: bool) -> void:
	feast_on = on
	feast.root.visible = on
	candle.light_energy = 1.8 if on else 0.0


func _audio(delta: float, p: Vector3) -> void:
	var L := lure
	var T := resolve
	var k := clampf(delta * 1.5, 0.0, 1.0)
	var choir := clampf(L * 1.15 - 0.2 - T * 0.9, 0.0, 1.0)
	b_choir.volume_db = lerpf(b_choir.volume_db, -80.0 if choir <= 0.0 else linear_to_db(choir) - 15.0, k)
	b_crickets.volume_db = lerpf(b_crickets.volume_db, -26.0 - 34.0 * clampf(L * 1.4 - 0.3 - T, 0.0, 1.0), k)
	b_wind.volume_db = lerpf(b_wind.volume_db, -24.0 + 6.0 * L - 10.0 * T, k)
	var caco := smoothstep(0.65, 0.95, L) * (1.0 - T)
	b_caco.volume_db = lerpf(b_caco.volume_db, -80.0 if caco <= 0.01 else linear_to_db(caco) - 14.0, k)
	b_static.volume_db = lerpf(b_static.volume_db, -80.0 if caco <= 0.01 else linear_to_db(caco) - 26.0, k)
	b_heart.volume_db = lerpf(b_heart.volume_db, -80.0 if L < 0.85 else -14.0, k)
	if caco > 0.3:
		_say("caco", "[A cacophony fills your head, and you stop needing to think.]", 4.5)
	# the forest whispers, more often the longer you stay
	_whisper_t -= delta
	if _whisper_t <= 0.0:
		_whisper_t = lerpf(15.0, 1.4, L) * (1.0 + 2.5 * T) * _arng.randf_range(0.7, 1.3)
		var a := _arng.randf() * TAU
		var pos := p + Vector3(cos(a), 0, sin(a)) * _arng.randf_range(2.5, 7.0) + Vector3.UP * _arng.randf_range(0.5, 3.0)
		var cap := "[whispering]" if _arng.randf() < 0.35 else ""
		sound.play_at("whisper", {"seconds": [2.0, 2.4, 2.8, 3.2][_arng.randi() % 4]}, pos, -10.0 + 8.0 * L - 10.0 * T, cap)
	# children howl at the moon, in waves
	_howl_t -= delta
	if _howl < 0.0 and _howl_t <= 0.0 and presence > 0.5:
		_howl = 0.0
		Overlay.subtitle("[Rows of small voices howl at the moon.]", 3.5)
	if _howl >= 0.0:
		_howl += delta
		var e := sin(clampf(_howl / 5.5, 0.0, 1.0) * PI)
		for i in howlers.size():
			var hp: AudioStreamPlayer3D = howlers[i]
			hp.pitch_scale = 0.82 + 0.3 * sin(clampf((_howl - i * 0.35) / 5.5, 0.0, 1.0) * PI) + 0.02 * sin(_howl * 7.0 + i)
			hp.volume_db = -80.0 if e <= 0.01 else linear_to_db(e * presence) - 6.0
		if _howl > 5.6:
			_howl = -1.0
			_howl_t = _arng.randf_range(16.0, 34.0) * (1.0 + 2.0 * T)
			for hp in howlers:
				(hp as AudioStreamPlayer3D).volume_db = -80.0


## At full lure you stop resisting: you lie down, you float, you stay.
func _surrender(delta: float) -> void:
	if sur_t < 0.0:
		surrender = surrender + delta if lure >= 0.999 else maxf(0.0, surrender - delta * 2.0)
		if surrender > 3.0 and not player.qa_active and not SessionState.is_qa():
			sur_t = 0.0
			player.frozen = true
			Overlay.subtitle("[You lie down in the crimson grass.]", 5.0)
		return
	sur_t += delta
	player.head.position.y = lerpf(Player.EYE_STAND, 0.25, clampf(sur_t / 3.0, 0.0, 1.0)) + maxf(0.0, sur_t - 3.0) * 0.6
	player.look_pitch = lerpf(player.look_pitch, deg_to_rad(70.0), clampf(delta * 0.8, 0.0, 1.0))
	player.head.rotation.x = player.look_pitch
	Overlay.set_screen_effect("blackout", clampf((sur_t - 2.5) / 3.5, 0.0, 1.0))
	if sur_t > 6.2:
		sur_t = 99.0
		player.hurt(1000.0, "stopped resisting and lay down with the other guests")


func _exit_tree() -> void:
	Overlay.set_screen_effect("glitch", 0.0)
	Overlay.set_screen_effect("desaturate", 0.0)
	Overlay.set_screen_effect("blackout", 0.0)
	Overlay.set_screen_effect("vignette", 0.25)


# --------------------------------------------------------------------- QA

func _prep(l: float, r: float, at: Vector3) -> void:
	_forced = true
	lure = l
	resolve = r
	world.build_around(at, 2)
	_apply(0.0, true)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var save := [lure, resolve, peak, _looked_back]
	lure = 0.3
	resolve = 0.0
	for i in 600:
		step_lure(1.0 / 60.0, 5.0, 1.0, 0.0, 0.0, 0.0)
	out.append({"what": "lure deepens while lingering in the Clearing", "ok": lure > 0.4, "detail": lure})
	var l0 := lure
	for i in int(RESOLVE_S * 1.7 * 60.0):
		step_lure(1.0 / 60.0, 50.0, -1.0, 2.5, 2.5, 0.0)
	out.append({"what": "walking away with your back turned builds resolve and eases the lure", "ok": resolve >= 1.0 and lure < l0, "detail": [resolve, lure]})
	for i in 60:
		step_lure(1.0 / 60.0, 50.0, 1.0, 0.0, 0.0, 0.0)
	out.append({"what": "looking back costs resolve", "ok": resolve < 0.8, "detail": resolve})
	resolve = 0.5
	out.append({"what": "no way out before resolve is complete", "ok": not _can_leave(), "detail": resolve})
	out.append({"what": "no entity spawned (NO ENTITY PER SOURCE)", "ok": find_children("*", "CharacterBody3D", true, false).size() == 1})
	lure = save[0]
	resolve = save[1]
	peak = save[2]
	_looked_back = save[3]
	return out

