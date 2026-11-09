extends LevelBase
## Level 29 "Hyperian" (Backrooms Wikidot rev 37, accessed 2026-11-04; cite:
## MyrandFox, CC BY-SA 3.0). Dossier: docs/canon/levels/L029.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: an island in vast oceans under a pale pink sky and an everlasting
##   sun; rough cliffs and steep slopes of rock and metal at the edge; tall
##   mountains protecting the interior and feeding wide rivers of Almond Water;
##   three zones (the outer areas = the ocean, the outer circle = unprotected
##   land, the inner circle = behind the mountains); wooden towns surrounded by
##   large farms and huts between the mountains; huts and watchtowers on hills
##   and cliffs; Hyperia, the trade hub in the middle with office-like
##   diplomatic buildings, "a gathering station, and not a capital"; native
##   trees with red trunks and white leaves whose wood is fire-proof and
##   stronger than aluminium; iron and copper in giant cave veins; colourful
##   flowers on the hills, sometimes rainbows; arrivals at the dockyards; the
##   sea past the shore is a dead zone that breaks the strongest boats; the only
##   exit is a crossing that kills everyone who tries (theoretically leading to
##   Level 114 or Level 284); the "Kraken" sleeps far out in the depths.
## SPACE (ADAPTATION, compressed from 2 166 000 km2): a cove dockyard at sea
##   level -> gully road -> outer-circle plateau (~14 m) with two cliff
##   watchtowers (+6.4 m decks) -> a pass through the south mountain arm ->
##   the inner basin (~20 m): Hyperia (plaza, market stalls, trade hall, timber
##   yard, three-storey diplomatic hall with a public gallery at +3 m), farm
##   fields with huts, an Almond Water river from a mountain waterfall into a
##   lake, a bridge; red-and-white forest; mountains 150-300 m on every land
##   side, the sea to the horizon on the other. No world edge.
## SIGNATURE MECHANIC (stateful): the dead zone. Past the cove mouth the sea
##   current pulls you out, captions escalate and the sea kills you (no boat
##   or swimmer survives). Casting off from the T-head is the page's only exit
##   and is fired as a DANGEROUS+UNKNOWN crossing. Watching the sea from a
##   watchtower deck records a sighting of something enormous far offshore in
##   the tower's watch log (REPORTED sightings only; the Kraken is never shown).
## ABSENT: land entities, NPCs, safe sea, the Kraken near the island.
## Helpers: L029_terrain (height), L029_flora (plants), L029_build (kit),
## L029_harbour (dockyard + towers), L029_town (Hyperia + farms).

const T := preload("res://levels/L029/L029_terrain.gd")
const Flora := preload("res://levels/L029/L029_flora.gd")
const Build := preload("res://levels/L029/L029_build.gd")
const Harbour := preload("res://levels/L029/L029_harbour.gd")
const Town := preload("res://levels/L029/L029_town.gd")
const START := Vector3(0.0, 1.6, 47.0)
const DEAD_Z := 140.0
const DEATH_Z := 190.0

var ter
var flora
var harbour
var town
var sea: WaterVolume
var region := ""
var said := {}
var beds := {}
var danger := 0.0
var dead_sent := false
var sightings := 0
var watch_t := 0.0
var shape: MeshInstance3D
var shape_t := -1.0
var _tick := 0.0
var _hammer_t := 5.0
var departure_triggers: Array = []
var watch_note: Interactable


func build() -> void:
	ter = T.new()
	rules["view_distance"] = 4000.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.05
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -80.0
	outdoor_env(Color(0.50, 0.40, 0.58), Color(0.98, 0.74, 0.74), Color(0.20, 0.22, 0.30), Vector2(11.0, 18.0),
		Color(1.0, 0.80, 0.70), 1.35, Color(0.86, 0.66, 0.70), 0.0011)
	environment.ambient_light_energy = 0.9
	environment.tonemap_exposure = 1.0
	environment.fog_sky_affect = 0.25
	environment.fog_aerial_perspective = 0.4
	sun.directional_shadow_max_distance = 160.0
	var sky_mat := environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sun_angle_max = 22.0
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.16, 0.2, 0.28)
	Build.materials()
	MatLib.register("l29_sea", MatLib.water({"shallow_color": Color(0.42, 0.52, 0.62), "deep_color": Color(0.08, 0.12, 0.22),
		"absorption": 0.45, "clarity": 0.45, "wave_height": 0.12, "wave_scale": 0.18, "wave_speed": 0.45,
		"normal_strength": 0.6, "foam_amount": 0.45, "foam_width": 0.4, "roughness_value": 0.22, "dark_surface": 0.22}))
	MatLib.register("l29_almond", MatLib.water({"shallow_color": Color(0.82, 0.80, 0.74), "deep_color": Color(0.40, 0.42, 0.42),
		"absorption": 0.2, "clarity": 0.55, "wave_height": 0.02, "wave_scale": 0.5, "wave_speed": 0.8,
		"normal_strength": 0.4, "foam_amount": 0.2, "roughness_value": 0.04}))
	lights.setup(4, 0)
	var land := Node3D.new()
	land.name = "Island"
	add_child(land)
	var mat: ShaderMaterial = ter.make_material()
	ter.build_meshes(land, mat)
	ter.build_collision(land)
	_waters()
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var k := kit("Timber")
	var bk = Build.new(self, ter, k)
	harbour = Harbour.new(self, ter, bk, k, props)
	harbour.build()
	town = Town.new(self, ter, bk, k, props)
	town.build()
	k.commit()
	_plants(land)
	_smoke(bk.chimneys)
	_rainbow()
	_far_shape()
	_exits()
	_notes()
	_sounds()
	add_arrival("start", START, 180.0)
	add_arrival("from_L025", ter.TOWN + Vector3(3.0, 0.1, 21.0), 0.0)
	add_landmark("Dockyard cove (arrivals)", START)
	add_landmark("West watchtower", harbour.towers[0])
	add_landmark("Hyperia gathering station", town.hall_gallery)
	add_landmark("Almond Water waterfall", Vector3(T.RIVER_X, T.WATER_Y, T.RIVER_Z0))
	_shots()


# ------------------------------------------------------------- water

func _waters() -> void:
	sea = WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-3200.0, -70.0, 58.0), Vector3(3200.0, T.SEA_Y, 3400.0), "l29_sea", true)
	sea.fog_color = Color(0.10, 0.16, 0.24)
	sea.fog_density = 0.07
	sea.tint = Color(0.35, 0.45, 0.6)
	# the cove reflects its own cliffs, not open sky
	var probe := ReflectionProbe.new()
	probe.name = "CoveProbe"
	probe.position = Vector3(0.0, 12.0, 80.0)
	probe.size = Vector3(150.0, 60.0, 120.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.box_projection = true
	probe.max_distance = 600.0
	add_child(probe)
	var river := WaterVolume.new()
	river.name = "AlmondRiver"
	add_child(river)
	river.setup(Vector3(T.RIVER_X - 13.0, T.WATER_Y - 3.0, T.RIVER_Z0 - 14.0), Vector3(T.RIVER_X + 13.0, T.WATER_Y, T.LAKE.y + 6.0), "l29_almond", true)
	river.fog_color = Color(0.5, 0.5, 0.46)
	river.tint = Color(0.8, 0.78, 0.7)
	var lake := WaterVolume.new()
	lake.name = "AlmondLake"
	add_child(lake)
	lake.setup(Vector3(T.LAKE.x - T.LAKE_R - 14.0, T.WATER_Y - 3.5, T.LAKE.y - T.LAKE_R - 14.0), Vector3(T.LAKE.x + T.LAKE_R + 14.0, T.WATER_Y, T.LAKE.y + T.LAKE_R + 14.0), "l29_almond", true)
	lake.fog_color = Color(0.5, 0.5, 0.46)
	lake.tint = Color(0.8, 0.78, 0.7)
	# the waterfall: a ribbon down the mountain face where the river is born
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var z := T.RIVER_Z0 + 2.0
	var i := 0
	while z > T.RIVER_Z0 - 34.0:
		var xr := T.RIVER_X + 6.0 * sin(z * 0.03)
		var y: float = maxf(ter.h(xr, z), T.WATER_Y) + 0.35
		var l := Vector3(xr - 5.0, y, z)
		var r := Vector3(xr + 5.0, y, z)
		if i > 0:
			for v in [[prev_l, 0.0], [r, 1.0], [prev_r, 1.0], [prev_l, 0.0], [l, 0.0], [r, 1.0]]:
				st.set_uv(Vector2(v[1], (v[0] as Vector3).y * 0.08))
				st.set_normal(Vector3(0, 0.3, 1).normalized())
				st.add_vertex(v[0])
		prev_l = l
		prev_r = r
		z -= 2.0
		i += 1
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;
void fragment() {
	float s = fract(UV.y * 6.0 + TIME * 1.4 + sin(UV.x * 23.0) * 0.2);
	float streak = smoothstep(0.2, 0.9, s) * (0.6 + 0.4 * sin(UV.x * 61.0 + TIME * 3.0));
	ALBEDO = mix(vec3(0.42, 0.44, 0.44), vec3(0.72, 0.72, 0.7), streak);
	ROUGHNESS = 0.2;
	ALPHA = 0.85 * smoothstep(0.0, 0.12, UV.x) * smoothstep(1.0, 0.88, UV.x);
}"""
	var wm := ShaderMaterial.new()
	wm.shader = sh
	var wf := MeshInstance3D.new()
	wf.name = "Waterfall"
	wf.mesh = st.commit()
	wf.material_override = wm
	wf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wf)


# ------------------------------------------------------------- plants

func _clear_of_work(p: Vector3, margin: float) -> bool:
	if absf(p.x - ter.road_x(p.z)) < 5.0 + margin and p.z < 70.0:
		return false
	if Vector2(p.x - T.TOWN.x, p.z - T.TOWN.z).length() < 32.0 + margin:
		return false
	if ter.in_field(p.x, p.z, 3.0 + margin) >= 0:
		return false
	for f in town.footprints:
		if Vector2(p.x, p.z).distance_to(f[0]) < float(f[1]) + margin:
			return false
	for c in harbour.towers:
		if Vector2(p.x - c.x, p.z - c.z).length() < 16.0 + margin:
			return false
	if p.z > 20.0 and absf(p.x) < ter.cove_half(p.z) + 6.0:
		return false
	if p.z > ter.coast_z(p.x) - 6.0:
		return false
	var rx := T.RIVER_X + 6.0 * sin(p.z * 0.03)
	if p.z < T.LAKE.y + 10.0 and p.z > T.RIVER_Z0 - 10.0 and absf(p.x - rx) < 13.0 + margin:
		return false
	if Vector2(p.x - T.LAKE.x, p.z - T.LAKE.y).length() < T.LAKE_R + 8.0 + margin:
		return false
	if absf(p.z + 312.0) < 4.0 and absf(p.x - T.RIVER_X) < 22.0:
		return false
	return true


func _plants(parent: Node3D) -> void:
	flora = Flora.new()
	var col := kit("TreeTrunks")
	var forest := FastNoiseLite.new()
	forest.seed = 2910
	forest.frequency = 0.012
	var r := RandomNumberGenerator.new()
	r.seed = 29100 + level_seed % 7
	var cell := 9.0
	var trees := 0
	for ix in range(-26, 27):
		for iz in range(-46, 12):
			var p := Vector3((ix + r.randf_range(0.1, 0.9)) * cell, 0, (iz + r.randf_range(0.1, 0.9)) * cell)
			var f := forest.get_noise_2d(p.x, p.z)
			if f < 0.12 or r.randf() > 0.75:
				continue
			if not _clear_of_work(p, 1.5):
				continue
			p.y = ter.h(p.x, p.z)
			if p.y - ter.lowland(p.x, p.z) > 6.0 or ter.normal_at(p.x, p.z).y < 0.88:
				continue
			if Vector2(p.x - START.x, p.z - START.z).length() < 8.0:
				continue
			var kind := r.randi_range(0, 3)
			var s := r.randf_range(0.85, 1.3)
			flora.add_tree(kind, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.9, 1.25), s)), p - Vector3(0, 0.2, 0)))
			var cs := CollisionShape3D.new()
			var sh := CylinderShape3D.new()
			sh.radius = (0.5 + kind * 0.09) * s * 1.2
			sh.height = 6.0
			cs.shape = sh
			cs.position = p + Vector3(0, 2.8, 0)
			cs.set_meta("surface", "wood")
			col.body.add_child(cs)
			trees += 1
	# a few lone trees in the plaza ring and by the hall
	for p in [Vector3(-22.0, 0, -224.0), Vector3(23.0, 0, -186.0), Vector3(-20.0, 0, -186.0), Vector3(18.0, 0, -246.0)]:
		p.y = ter.h(p.x, p.z)
		flora.add_tree(1, Transform3D(Basis(Vector3.UP, r.randf() * TAU), p - Vector3(0, 0.2, 0)))
	# crops in rows
	for i in T.FIELDS.size():
		var fd: Array = T.FIELDS[i]
		var z: float = fd[1] - fd[3] + 1.0
		while z < fd[1] + fd[3] - 0.5:
			var x: float = fd[0] - fd[2] + 1.5
			while x < fd[0] + fd[2] - 1.0:
				var q := Vector3(x + r.randf_range(-0.1, 0.1), 0, z)
				q.y = ter.h(q.x, q.z) - 0.03
				var s := r.randf_range(0.85, 1.15)
				flora.add("crop%d" % int(fd[4]), Transform3D(Basis(Vector3.UP, r.randf_range(-0.08, 0.08)).scaled(Vector3(1, s, 1)), q))
				x += 2.4
			z += 1.7
	# flowers painting the hills
	var fl := FastNoiseLite.new()
	fl.seed = 2911
	fl.frequency = 0.02
	var n := 0
	for it in 6000:
		if n >= 900:
			break
		var p := Vector3(r.randf_range(-200.0, 200.0), 0, r.randf_range(-380.0, 60.0))
		var v := fl.get_noise_2d(p.x, p.z)
		if v < 0.25 or not _clear_of_work(p, 0.0):
			continue
		p.y = ter.h(p.x, p.z)
		if p.y - ter.lowland(p.x, p.z) > 3.0:
			continue
		var c := int(absf(fl.get_noise_2d(p.x * 0.3 + 99.0, p.z * 0.3)) * 17.0) % 6
		flora.add("flower%d" % c, Transform3D(Basis(Vector3.UP, r.randf() * TAU), p))
		n += 1
	flora.commit(parent)
	col.commit()


func _smoke(chimneys: Array) -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var qm := QuadMesh.new()
	qm.size = Vector2(1.4, 1.4)
	qm.material = m
	var used := 0
	for c in chimneys:
		if used >= 7:
			break
		if (c as Vector3).z > -100.0:
			continue
		var p := CPUParticles3D.new()
		p.mesh = qm
		p.amount = 18
		p.lifetime = 7.0
		p.position = c
		p.direction = Vector3(0.25, 1, 0.1)
		p.spread = 10.0
		p.initial_velocity_min = 0.7
		p.initial_velocity_max = 1.1
		p.gravity = Vector3(0.18, 0.05, 0.05)
		p.scale_amount_min = 0.8
		p.scale_amount_max = 2.6
		var g := Gradient.new()
		g.set_color(0, Color(0.55, 0.52, 0.52, 0.45))
		g.set_color(1, Color(0.8, 0.76, 0.78, 0.0))
		p.color_ramp = g
		add_child(p)
		used += 1


func _rainbow() -> void:
	# "colourful shades ... sometimes, creating rainbows" over the inner hills
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := 260.0
	var W := 26.0
	var n := 48
	for i in n:
		var a0 := PI * float(i) / n
		var a1 := PI * float(i + 1) / n
		for v in [[a0, 0.0], [a1, 0.0], [a1, 1.0], [a0, 0.0], [a1, 1.0], [a0, 1.0]]:
			var a: float = v[0]
			var rr: float = R + W * float(v[1])
			st.set_uv(Vector2(float(v[1]), a / PI))
			st.add_vertex(Vector3(cos(a) * rr, sin(a) * rr - 70.0, 0))
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;
uniform float strength = 0.16;
void fragment() {
	float t = UV.x;
	vec3 c = clamp(vec3(abs(t * 6.0 - 3.0) - 1.0, 2.0 - abs(t * 6.0 - 2.0), 2.0 - abs(t * 6.0 - 4.0)), 0.0, 1.0);
	float edge = smoothstep(0.0, 0.18, t) * smoothstep(1.0, 0.82, t);
	float foot = smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);
	ALBEDO = c * strength * edge * foot;
}"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.name = "Rainbow"
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(-60.0, 0.0, -470.0)
	mi.rotation.y = 0.35
	add_child(mi)


func _far_shape() -> void:
	# REPORTED: "sightings of strange and enormous entities" outside the island.
	# Only ever a dark mass breaking the surface far offshore; never the Kraken.
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 8
	shape = MeshInstance3D.new()
	shape.name = "FarSighting"
	shape.mesh = sm
	shape.material_override = MatLib.standard(Color(0.03, 0.035, 0.05), 0.35)
	shape.scale = Vector3(70.0, 9.0, 22.0)
	shape.position = Vector3(-300.0, -30.0, 1100.0)
	shape.visible = false
	add_child(shape)


# ------------------------------------------------------------- exits

func _exits() -> void:
	var ids := ["L029>L114#1", "L029>L284#2"]
	for i in 2:
		var p: Vector3 = harbour.exit_spots[i]
		var t := add_exit(ids[i], "interact", p + Vector3(0, 1.1, 0), Vector3(3.6, 2.2, 3.6), "Board the sloop and sail out past the shore")
		if t:
			t.fired.connect(_on_departure)
			departure_triggers.append(t)


func _on_departure(_edge: String) -> void:
	Overlay.glitch(0.8)
	Overlay.subtitle("[you cast off past the cove mouth... the water turns, the hull splits, and the dead zone takes you under]", 6.0)


# ------------------------------------------------------------- notes

func _notes() -> void:
	var o: Vector3 = harbour.office_pos
	var f: float = harbour.office_floor
	add_note("l29_welcome", "Dockyard notice board", "WELCOME TO THE ISLAND.\n\nIf you came in over the water, you were lucky: the crossing stopped being survivable a long time ago. People from the different societies come down to meet new arrivals here, and most of them are friendly.\n\nThe gully road climbs to the outer circle. Past the watchtowers, the road goes through the mountains to the inner circle, the farms and Hyperia.\n\nDo not go swimming past the cove mouth.", Vector3(o.x + 2.6, f + 1.5, o.z + 3.0), Vector3(1.6, 1.1, 0.3), false)
	add_note("l29_harbour_log", "Harbour log: departures", "Every line in this book is a departure for the far side, and every line ends the same way.\n\n- Sloop, red-wood hull, treated twice. Wreckage found at the cove mouth.\n- Two rowing boats lashed together. Not seen again.\n- The strongest hull we ever built. Broke apart in sight of the towers.\n\nThe old wanderers said the crossing leads, in theory, to Level 114 or Level 284. That was before the water turned. No one who has tried since has lived.", Vector3(o.x - 0.6, f + 0.82, o.z - 1.5))
	add_note("l29_kraken", "Deep-water expedition account (copy)", "Far from the island, asleep in the depths, there is something we call the Kraken. Around it the sea is pulled in like a whirlpool; nothing that drifts near it comes back. We think it could, in theory, slip out of this level the way wanderers do.\n\nWe have stopped sending expeditions. We lack the equipment, and we have lost too many people. There may be two hundred kinds of things living out there. We have seen almost none of them.", Vector3(o.x + 2.7, f + 1.2, o.z - 2.0))
	var tw: Vector3 = harbour.towers[0]
	watch_note = add_note("l29_watch", "Watchtower log (west)", _watch_text(), tw + Vector3(-1.6, 0.42, 1.9))
	add_note("l29_register", "Register of the Gathering Station", "Hyperia is the hub between the settlements, a gathering station and not a capital: every society keeps its own capital. Trade and exchange between them passes through here, and the offices upstairs serve as stations for their diplomats.\n\nMost of our nations have no formal name; people call them Wanderer Nations. Not every society uses this hub. Any society may do as it likes with its own goods, and no other may stand in its way.\n\nBest count of the island: around twenty-five thousand people.", town.hall_gallery + Vector3(-3.5, 1.0, -1.4), Vector3(0.6, 0.6, 0.3))
	add_note("l29_wood", "Timber yard chalkboard", "RED TRUNK, WHITE LEAVES. Cuts easily with a plain axe.\n\nAfter the treatment process the wood is stronger than aluminium and will not burn. Every wall in this town is built from it.\n\nLog the loads for the gathering station before noon. (There is no noon. Log them anyway.)", Vector3(-52.0 + 8.5, ter.h(-43.5, -158.8) + 1.0, -158.8), Vector3(0.6, 0.6, 0.6))
	add_note("l29_ore", "Trade hall manifest", "From the cave diggings: iron, copper. The veins in the small caves are enormous; the problem is carrying it out, not finding it.\n\nFrom the farms: grain, greens, roots. From the sea: nothing. Nobody fishes past the cove.", Vector3(30.0, ter.h(30.0, -196.0) + 1.0, -196.0), Vector3(0.6, 0.6, 0.6))
	add_note("l29_mountains", "Waymarker by the river", "The rivers run off the mountainsides: Almond Water, fresh and drinkable.\n\nDo not climb. The high ground and the coast are not fit to live on: the terrain kills, and so does the cold and heat up there.", Vector3(T.RIVER_X - 14.0, ter.h(T.RIVER_X - 14.0, -306.0) + 1.0, -306.0), Vector3(0.5, 0.6, 0.5))
	add_interactable(Vector3(T.RIVER_X - 9.5, T.WATER_Y + 0.6, -300.0), Vector3(3.0, 1.4, 6.0), "Drink from the river", func():
		Overlay.subtitle("[Almond Water: cool, faintly sweet. You feel steadier.]", 4.0))


func _watch_text() -> String:
	var s := "Watch from the cliffs: the outer circle has no mountains to hide behind.\n\nEntries:\n- Something enormous, far out, broke the surface and went down again.\n- The same, or another. Bigger than any boat.\n- Haze. Nothing."
	for i in sightings:
		s += "\n- (your entry) A dark mass far offshore, rising and sinking. Sighting %d." % (i + 1)
	return s


# ------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -24.0)
	beds["surf"] = sound.bed("water_bed", {"seconds": 8.0, "bright": 1100.0}, -20.0)
	beds["deep"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0, "rumble": 0.8}, -70.0)
	beds["town"] = sound.bed("pad", {"root": 196.0, "chord": [0, 4, 7, 12], "seconds": 10.0, "bright": 0.08}, -70.0)
	sound.emitter("water_bed", Vector3(T.RIVER_X, T.WATER_Y + 2.0, T.RIVER_Z0 - 6.0), {"seconds": 6.0, "bright": 2400.0}, -2.0, 70.0)
	sound.emitter("water_bed", Vector3(T.RIVER_X, T.WATER_Y + 0.5, -310.0), {"seconds": 7.0, "bright": 1600.0}, -10.0, 30.0)
	sound.emitter("creak", Vector3(0, 2.0, 100.0), {"freq": 180.0}, -14.0, 30.0)
	sound.oneshot("creak", {"freq": 120.0}, 9.0, 20.0, 10.0, "[mooring lines creak]", -12.0)


# ------------------------------------------------------------- shots

func _shots() -> void:
	add_shot("dockyard_from_t_head", Vector3(5.0, 3.3, 117.5), Vector3(-4.0, 6.0, 40.0), {"flashlight": false})
	add_shot("arrival_beach_to_sea", START + Vector3(-3.0, 1.65, -2.0), Vector3(-2.0, 1.6, 118.0), {"flashlight": false})
	var tw: Vector3 = harbour.towers[0]
	add_shot("watchtower_cliffs", tw + Vector3(1.0, 1.65, 1.0), Vector3(20.0, 4.0, 85.0), {"flashlight": false})
	add_shot("hyperia_hall_plaza", Vector3(-4.5, T.TOWN.y + 1.7, -214.0), town.hall_gallery + Vector3(5.0, -0.5, 0), {"flashlight": false})
	add_shot("inner_circle_farms", Vector3(-42.0, ter.h(-42.0, -236.0) + 2.2, -236.0), Vector3(-112.0, 22.0, -266.0), {"flashlight": false})
	add_shot("waterfall_almond", Vector3(T.RIVER_X - 10.0, T.WATER_Y + 3.0, -320.0), Vector3(T.RIVER_X, T.WATER_Y + 12.0, T.RIVER_Z0 - 10.0), {"flashlight": false})


# ------------------------------------------------------------- mechanic

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.3
		_region(p)
	_dead_zone(p, delta)
	_watch(p, delta)
	_mix(p, delta)


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func _region(p: Vector3) -> void:
	var r := "outer"
	if ter.basin_d(p.x, p.z) < 0.0:
		r = "inner"
	elif p.z > 30.0 and p.y < 6.0:
		r = "harbour"
	if p.z > ter.coast_z(p.x) + 20.0:
		r = "sea"
	if r == region:
		return
	region = r
	match r:
		"outer":
			_say("outer", "[the outer circle: open ground, no mountains between you and the sea wind]")
		"inner":
			_say("inner", "[the inner circle: the mountains close the wind off; the air smells of wood smoke and fields]")
		"sea":
			_say("sea", "[the outer areas: the open sea]")


func _dead_zone(p: Vector3, delta: float) -> void:
	var in_sea := sea.contains(p + Vector3(0, 0.6, 0))
	var target := 0.0
	if in_sea and p.z > DEAD_Z:
		target = clampf((p.z - DEAD_Z) / (DEATH_Z - DEAD_Z), 0.0, 1.0)
	danger = move_toward(danger, target, delta * 0.5)
	sea.current = Vector3(0, 0, 0.4 + 2.2 * danger) if target > 0.0 else Vector3.ZERO
	if target > 0.0:
		_say("dz0", "[past the cove mouth the water changes: colder, pulling outward]")
		if danger > 0.4:
			_say("dz1", "[the swell lifts you and drags you seaward; the island is getting smaller]")
		if danger > 0.8:
			_say("dz2", "[the dead zone: nothing that goes this far comes back]")
	if SessionState.is_qa():
		return
	if not dead_sent and in_sea and p.z > DEATH_Z:
		dead_sent = true
		player.hurt(1000.0, "The sea past the shore broke you as it breaks every boat.")


func _watch(p: Vector3, delta: float) -> void:
	var on_tower := false
	for c in harbour.towers:
		var cc: Vector3 = c
		if Vector2(p.x - cc.x, p.z - cc.z).length() < 2.8 and absf(p.y - cc.y) < 0.6:
			on_tower = true
	if on_tower and shape_t < 0.0:
		watch_t += delta
		if watch_t > 6.0:
			watch_t = 0.0
			_begin_sighting(p)
	elif not on_tower:
		watch_t = 0.0
	if shape_t >= 0.0:
		shape_t += delta
		var k := shape_t / 16.0
		shape.position.y = lerpf(-12.0, 3.5, sin(clampf(k, 0.0, 1.0) * PI))
		shape.position.x += delta * 6.0
		if k >= 1.0:
			shape_t = -1.0
			shape.visible = false


func _begin_sighting(p: Vector3) -> void:
	if sightings >= 3:
		return
	sightings += 1
	shape_t = 0.0
	shape.visible = true
	shape.position = Vector3(p.x + rng.randf_range(-500.0, 500.0), -12.0, 1000.0 + rng.randf_range(0.0, 300.0))
	sound.play_at("distant_boom", {}, p + Vector3(0, 0, 80.0), -18.0, "")
	Overlay.subtitle("[far out beyond the shore, something enormous breaks the surface... and slowly goes under]", 6.0)
	if is_instance_valid(watch_note):
		watch_note.note_text = _watch_text()


func _mix(p: Vector3, delta: float) -> void:
	var k := minf(delta * 1.5, 1.0)
	var coast := clampf((p.z - 20.0) / 80.0, 0.0, 1.0)
	var inner := 1.0 if region == "inner" else 0.0
	_vol("surf", lerpf(-34.0, -14.0, coast) + danger * 8.0, k)
	_vol("wind", lerpf(-20.0, -30.0, inner) + danger * 6.0, k)
	_vol("deep", lerpf(-70.0, -10.0, danger), k)
	_vol("town", lerpf(-70.0, -34.0, inner * (1.0 - clampf(Vector2(p.x - T.TOWN.x, p.z - T.TOWN.z).length() / 160.0, 0.0, 1.0))), k)
	if region == "inner":
		_hammer_t -= delta
		if _hammer_t <= 0.0:
			_hammer_t = rng.randf_range(6.0, 14.0)
			var src := T.TOWN + Vector3(rng.randf_range(-40.0, 40.0), 3.0, rng.randf_range(-40.0, 40.0))
			if src.distance_to(p) < 90.0:
				sound.play_at("knock", {"hits": rng.randi_range(3, 6)}, src, -10.0, "[hammering somewhere in town]")


func _vol(key: String, db: float, k: float) -> void:
	var a: AudioStreamPlayer = beds.get(key)
	if a:
		a.volume_db = lerpf(a.volume_db, db, k)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "two sea departures on the T-head (both documented edges)", "ok": departure_triggers.size() == 2})
	out.append({"what": "spawn on the dockyard beach above sea level", "ok": is_instance_valid(player) and player.global_position.y > 0.8, "detail": player.global_position if is_instance_valid(player) else null})
	out.append({"what": "plateau ~14 m and basin ~20 m (three walkable levels)", "ok": absf(ter.h(0.0, -30.0) - 14.0) < 3.0 and absf(ter.h(0.0, -205.0) - 20.0) < 0.5, "detail": [ter.h(0.0, -30.0), ter.h(0.0, -205.0)]})
	out.append({"what": "watchtower decks above the cliff", "ok": harbour.towers.size() == 2 and (harbour.towers[0] as Vector3).y > 18.0, "detail": harbour.towers})
	out.append({"what": "hall gallery is an upper storey", "ok": town.hall_gallery.y > 22.0, "detail": town.hall_gallery})
	out.append({"what": "red trees and crops planted", "ok": flora.count > 900, "detail": flora.count})
	out.append({"what": "dead zone is lethal only outside QA", "ok": not dead_sent})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
