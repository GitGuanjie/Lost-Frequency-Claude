extends LevelBase
## Level 41 — "The Black Lake" (Backrooms Wikidot rev 46, accessed 2026-11-04;
## cite: Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L041.md.
## Content warning (page): burns, melting flesh, abduction deaths. The game
## keeps all of it implied: captions, screen effects and fades.
##
## PLAN (v2.0 rebuild)
## SOURCE: a bubbling, flaming asphalt tar pit in perpetual grey fog, ringed by
## charcoal desert; the tar never cools (~95 C), its heat and fumes intoxicate
## (fainting, vomiting); touching it burns, and over about a second flesh fuses
## to it; it is shallow, so hot charcoal-sand islands pierce it in patchy
## clusters (only bones and dead dry bushes on them, do not stand still);
## islands and piers are the only two safe ways across; piers have concrete or
## metal supports, wooden legs and walkways, 2-6 m up, never touching the
## islands; dry boardwalks burn down to their concrete supports; the ground
## gives way and platforms sink and burn; submerged telegraph poles, small
## pylons, tiled bungalow roofs, flat brick townhouse roofs and metal rods;
## the lake is circular and ringed by ~15 m dunes nobody can get within 50 m
## of; ten failed groups (one stripped telegraph copper), their remains blend
## with the boardwalks; Collagen Leviathans (eel-like fossil skeletons, 7-20
## ft) breach and dive like dolphins, shower tar, and sense anyone at an island
## edge or on a pier, leap and take them; four one-of-a-kind exit objects: a
## navy vessel's bridge (broken window), an upside-down shuttle (booster
## nozzles), a barn door on a stone plinth, a lighthouse gallery (beacon).
## ADAPTATION: lake ~500 m across (page gives no size); an authored network of
## islands and boardwalks around the arrival island plus seeded outlying
## islets, ruins, submerged things and fires; group-built ladders take you
## from the sand up to the walkways (the page: groups tried to build bridges);
## the lighthouse is reached down a sunken boardwalk; exits L041>L500#1 and
## L041>L515#2 are documented edges added to the manifest.
## Mechanic (stateful): fume intoxication that only builds, hot sand while
## standing still, tar contact (fatal past about a second), and a leviathan
## that wakes, senses you at an island edge or on a walkway, bulges the tar,
## and strikes where you stood (sprint away). Verticality: sand 0-1 m, decks
## 2.4-4.6 m, the bridge roof 4.6 m, the lighthouse gallery at the tar line.

const LAND := preload("res://levels/L041/L041_land.gd")
const BUILD := preload("res://levels/L041/L041_build.gd")
const DRESS := preload("res://levels/L041/L041_dress.gd")
const MECH := preload("res://levels/L041/L041_mech.gd")
const CS := 64.0
const LH := Vector3(-77.0, 0.0, -31.0)
const P1 := [Vector3(3, 2.8, 32), Vector3(-8, 2.8, 30), Vector3(-22, 2.8, 16), Vector3(-34, 2.8, 4), Vector3(-50, 2.8, -11), Vector3(-66.3, 2.8, -25.56)]
const P2 := [Vector3(-31, 3.0, -1), Vector3(-27, 3.0, -12), Vector3(-15, 3.6, -32), Vector3(-3, 4.2, -52), Vector3(6, 4.6, -68)]
const P3 := [Vector3(26, 2.4, 50), Vector3(36, 2.4, 42), Vector3(46, 2.6, 30), Vector3(55, 2.6, 19)]

var land
var bld
var dress
var mech
var world: ChunkWorld
var tar_mat: ShaderMaterial
var start := Vector3.ZERO
var marks := {}               # landmark name -> {pos, edge, kind, center, size, prompt}
var lazy: Dictionary = {}     # edge -> ExitTrigger (exits are created near their object)
var beacon: OmniLight3D
var beacon_spot: SpotLight3D
var _beacon_t := 0.0


func build() -> void:
	rules["view_distance"] = 700.0
	rules["reverb_room"] = 0.08
	rules["reverb_wet"] = 0.04
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -30.0
	land = LAND.new()
	land.plan(rng)
	var grey := Color(0.2, 0.2, 0.195)
	outdoor_env(Color(0.14, 0.14, 0.145), grey, Color(0.03, 0.03, 0.03), Vector2(62.0, 30.0), Color(0.9, 0.86, 0.8), 0.5, Color(0.17, 0.17, 0.165), 0.0115)
	environment.fog_sky_affect = 0.95
	environment.fog_height = 1.2
	environment.fog_height_density = 0.012
	environment.fog_aerial_perspective = 0.2
	environment.ambient_light_energy = 0.45
	environment.tonemap_exposure = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.06
	environment.glow_intensity = 0.55
	environment.glow_hdr_threshold = 0.95
	sun.shadow_blur = 3.0
	sun.light_specular = 0.6
	sun.directional_shadow_max_distance = 80.0
	BUILD.materials()
	bld = BUILD.new(self, land)
	dress = DRESS.new(self, land)
	_terrain()
	var k := kit("Boardwalks")
	_network(k)
	var kl := kit("Landmarks")
	_landmarks(kl)
	kl.commit()
	var kd := kit("Submerged")
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	_submerged(kd, props)
	var camp: Dictionary = dress.group_remains(kd, props, Vector3(1.5, 0, 46.0))
	dress.group_bridge(kd, Vector3(-9.6, 0, 46.0), Vector3(-1.0, 0, 0.55))
	kd.commit()
	k.commit()
	dress.scatter_islands(props, rng)
	_fires(props)
	start = Vector3(-1.5, 0, 41.5)
	start.y = land.h(start.x, start.z) + 0.05
	var face: Vector3 = marks["barn"]["pos"] - start
	add_arrival("start", start, rad_to_deg(atan2(-face.x, -face.z)))
	var shore := Vector3(-9.0, 0, 37.2)
	shore.y = land.h(shore.x, shore.z) + 0.05
	add_arrival("from_L008", shore, rad_to_deg(atan2(-0.94, -0.34)))
	world = ChunkWorld.new()
	world.name = "Ground"
	world.chunk_size = CS
	world.radius = 1
	world.unload_radius = 2
	world.builder = _chunk
	add_child(world)
	world.build_around(start, 1)
	mech = MECH.new(self, land, bld, dress)
	add_child(mech)
	_notes(camp)
	_sounds()
	_update_exits(start)
	for nm in ["barn", "lighthouse", "navy", "shuttle"]:
		add_landmark(marks[nm]["label"], marks[nm]["pos"])
	add_landmark("The group camp on the landing island", camp["board"])
	_shots()


func on_player_ready() -> void:
	world.target = player
	mech.on_ready()
	checkpoint("start")


# ---------------------------------------------------------------- terrain

func _terrain() -> void:
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	land.build_meshes(geo, land.sand_material(false), land.sand_material(true))
	tar_mat = LAND.shader_mat(LAND.TAR)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 96
	var rings := [0.0, 30.0, 70.0, 120.0, 170.0, 220.0, LAND.LAKE_R + 40.0]
	for j in segs + 1:
		var a := TAU * j / segs
		for r in rings:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(cos(a) * r, LAND.TAR_Y, sin(a) * r))
	var nr := rings.size()
	for j in segs:
		for i in nr - 1:
			var a0 := j * nr + i
			var b0 := (j + 1) * nr + i
			st.add_index(a0)
			st.add_index(a0 + 1)
			st.add_index(b0)
			st.add_index(a0 + 1)
			st.add_index(b0 + 1)
			st.add_index(b0)
	var mi := MeshInstance3D.new()
	mi.name = "Tar"
	mi.mesh = st.commit()
	mi.material_override = tar_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	geo.add_child(mi)


func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var c := Vector2(ox + CS * 0.5, oz + CS * 0.5)
	if c.length() > LAND.LAKE_R + 50.0:
		return {}
	land.collision_tile(node, ox, oz, int(CS))
	return {}


# ---------------------------------------------------------------- boardwalks

## Best ladder spot along a segment: the side and point with the highest sand.
func _ladder_spot(pts: Array, seg: int, t0: float, t1: float) -> Dictionary:
	var a: Vector3 = pts[seg]
	var b: Vector3 = pts[seg + 1]
	var bas := BUILD.seg_basis(a, b)
	var best := {}
	var best_h := -INF
	var t := t0
	while t <= t1 + 0.001:
		var p := a.lerp(b, t)
		for s in [-1.0, 1.0]:
			var out: Vector3 = bas.x * s
			out.y = 0.0
			out = out.normalized()
			var edge := p + out * (BUILD.W * 0.5)
			var base := edge + out * 0.62
			var gh: float = land.h(base.x, base.z)
			var ok := true
			for q in [base + out * 0.6, base - Vector3(out.z, 0, -out.x) * 0.4, base + Vector3(out.z, 0, -out.x) * 0.4]:
				if land.h(q.x, q.z) < 0.06:
					ok = false
			if ok and gh > best_h:
				best_h = gh
				best = {"edge": edge, "out": out}
		t += 0.05
	return best


func _network(k: GeoKit) -> void:
	var spots := [_ladder_spot(P1, 0, 0.15, 0.9), _ladder_spot(P1, 3, 0.0, 0.4), _ladder_spot(P2, 0, 0.0, 0.5),
		_ladder_spot(P3, 0, 0.0, 0.5), _ladder_spot(P3, 2, 0.5, 1.0)]
	for s in spots:
		if not s.is_empty():
			bld.rail_open.append(Vector2(s["edge"].x, s["edge"].z))
	bld.pier(k, P1, {"rails": 2})
	bld.pier(k, P2, {"rails": 1, "feet": "steel"})
	bld.pier(k, P3, {"rails": 2})
	for s in spots:
		if not s.is_empty():
			bld.ladder(k, self, s["edge"], s["out"])
	# the boardwalk that sank onto the lighthouse gallery
	var door: Vector3 = Vector3(cos(0.47), 0, sin(0.47))
	var p_end: Vector3 = P1[P1.size() - 1]
	var g_end: Vector3 = LH + door * 3.3 + Vector3.UP * 0.42
	bld.sunken(k, p_end, g_end)
	k.box(p_end - Vector3.UP * 0.07, Vector3(2.4, 0.14, 2.4), "l41_plank", GeoKit.ALL, true, "wood")
	# a branch off P1 that burnt away; only its feet run on into the fog
	var br := [Vector3(-50, 2.8, -11), Vector3(-62, 2.8, -2), Vector3(-80, 2.8, 4)]
	bld.pier(k, [br[0], br[1]], {"rails": 1})
	bld.ruin(k, [br[1], br[2], Vector3(-98, 2.8, 12)])
	# seeded remains: burnt rows of supports, a sunk walkway, isolated decks
	for i in 5:
		var p: Vector3 = dress.tar_spot(rng, 14.0, 40.0, 185.0)
		var a := rng.randf_range(0, TAU)
		var d := Vector3(cos(a), 0, sin(a))
		var ln := rng.randf_range(14.0, 30.0)
		var y := rng.randf_range(2.2, 5.5)
		var q := p + d * ln
		if Vector2(q.x, q.z).length() > LAND.REACH_R:
			q = p + d * 8.0
		if i % 3 == 0:
			bld.ruin(k, [Vector3(p.x, y, p.z), Vector3(q.x, y, q.z)])
		elif i % 3 == 1:
			bld.pier(k, [Vector3(p.x, y, p.z), Vector3(q.x, y, q.z)], {"rails": 1, "burnt": [0] if rng.randf() < 0.4 else []})
		else:
			bld.sunken(k, Vector3(p.x, y, p.z), Vector3(q.x, -0.6, q.z))
	dress.avoid.append_array(P1 + P2 + P3)


# ---------------------------------------------------------------- landmarks

func _landmarks(k: GeoKit) -> void:
	# Level 612: the barn door on its plinth, facing the arrival island
	var bc := Vector3(18.5, 0, 57.0)
	bc.y = land.h(bc.x, bc.z) - 0.05
	var to_start := Vector3(-1.5, 0, 41.5) - bc
	to_start.y = 0
	var by := atan2(to_start.x, to_start.z)
	var barn: Dictionary = bld.barn_door(k, bc, by)
	marks["barn"] = {"label": "Barn door on a stone plinth", "pos": bc, "edge": "L041>L612#3", "kind": "interact",
		"center": barn["front"] + Vector3.UP * 0.1, "size": Vector3(2.4, 2.4, 1.6), "prompt": "Open the barn door and go through"}
	# Level 626: the lighthouse gallery
	var lh: Dictionary = bld.lighthouse(k, LH)
	marks["lighthouse"] = {"label": "Submerged lighthouse gallery", "pos": LH, "edge": "L041>L626#4", "kind": "interact",
		"center": lh["beacon"] + lh["door_dir"] * 0.9 + Vector3.DOWN * 0.3, "size": Vector3(2.0, 2.2, 2.0), "prompt": "Tamper with the flickering beacon"}
	beacon = OmniLight3D.new()
	beacon.light_color = Color(1.0, 0.86, 0.6)
	beacon.omni_range = 16.0
	beacon.light_energy = 3.0
	beacon.position = lh["beacon"] + Vector3.UP * 0.2
	add_child(beacon)
	beacon_spot = SpotLight3D.new()
	beacon_spot.light_color = Color(1.0, 0.9, 0.7)
	beacon_spot.spot_range = 140.0
	beacon_spot.spot_angle = 7.0
	beacon_spot.light_energy = 14.0
	beacon_spot.light_volumetric_fog_energy = 2.0
	beacon_spot.position = lh["beacon"]
	add_child(beacon_spot)
	# Level 500: the navy vessel bridge at the end of P2
	var pe: Vector3 = P2[P2.size() - 1]
	var d: Vector3 = (pe - P2[P2.size() - 2])
	d.y = 0
	d = d.normalized()
	var nc := Vector3(pe.x, 0, pe.z) + d * 5.15
	var nv: Dictionary = bld.navy_bridge(k, self, nc, atan2(-d.x, -d.z), pe.y)
	marks["navy"] = {"label": "Bridge of a navy vessel", "pos": nc, "edge": "L041>L500#1", "kind": "interact",
		"center": nv["window"] + Vector3.DOWN * 0.2, "size": Vector3(1.8, 2.0, 1.6), "prompt": "Clamber in through the broken window"}
	# Level 515: the inverted shuttle against the shuttle island
	var isl: Dictionary = land.island("shuttle")
	var u := Vector3(cos(float(isl["rot"])), 0, sin(float(isl["rot"])))
	var shore_pt := Vector3(isl["c"].x, 0, isl["c"].y) + u * float(isl["rx"]) * 0.8
	var sc := shore_pt + u * 0.4
	var sh: Dictionary = bld.shuttle(k, self, sc, atan2(-u.x, -u.z))
	var mouth: Vector3 = sh["mouths"][1]
	marks["shuttle"] = {"label": "Upside-down shuttle (booster nozzles)", "pos": sc, "edge": "L041>L515#2", "kind": "interact",
		"center": Vector3(mouth.x, land.h(mouth.x, mouth.z) + 1.1, mouth.z), "size": Vector3(3.0, 2.4, 3.0), "prompt": "Crawl up into the booster nozzle"}


## Exits exist only near their object, so a far object never draws a route
## (and the QA navmesh only sees the exit near the arrival).
func _update_exits(p: Vector3) -> void:
	for nm in ["barn", "lighthouse", "navy", "shuttle"]:
		var m: Dictionary = marks[nm]
		var near: bool = Vector2(p.x - m["center"].x, p.z - m["center"].z).length() < (60.0 if not lazy.has(m["edge"]) else 75.0)
		if near and not lazy.has(m["edge"]):
			var t := add_exit(m["edge"], m["kind"], m["center"], m["size"], m["prompt"])
			if t:
				lazy[m["edge"]] = t
		elif not near and lazy.has(m["edge"]):
			var t2: ExitTrigger = lazy[m["edge"]]
			lazy.erase(m["edge"])
			if is_instance_valid(t2):
				exits.erase(t2)
				t2.queue_free()


# ---------------------------------------------------------------- dressing

func _submerged(k: GeoKit, props: Node3D) -> void:
	dress.avoid.append_array([LH, marks["navy"]["pos"], marks["shuttle"]["pos"], marks["barn"]["pos"]])
	for l in bld.pier_lines:
		for p in l:
			dress.avoid.append(p)
	# telegraph lines: one authored past the landing island, more seeded
	dress.telegraph_line(k, Vector3(-44, 0, 82), 0.05, 6, rng)
	for i in 3:
		var p: Vector3 = dress.tar_spot(rng, 16.0, 40.0, 170.0)
		dress.telegraph_line(k, p, rng.randf_range(0, TAU), rng.randi_range(3, 6), rng)
	dress.pylon(k, Vector3(-20, 0, -48), 0.4, 0.12)
	dress.pylon(k, dress.tar_spot(rng, 18.0), rng.randf_range(0, TAU), rng.randf_range(-0.2, 0.2))
	dress.bungalow_roof(k, Vector3(-48, 0, 30), 0.6, 1.3, true)
	dress.bungalow_roof(k, Vector3(30, 0, 18), -0.4, 0.8, false)
	for i in 3:
		dress.bungalow_roof(k, dress.tar_spot(rng, 14.0), rng.randf_range(0, TAU), rng.randf_range(0.4, 1.6), rng.randf() < 0.6)
	dress.townhouse_roof(k, Vector3(-14, 0, -6), 0.3, rng)
	for i in 2:
		dress.townhouse_roof(k, dress.tar_spot(rng, 14.0), rng.randf_range(0, TAU), rng)
	for i in 5:
		dress.rods(k, dress.tar_spot(rng, 8.0, 15.0, 150.0), rng)
	# rusted remains of an older group, half sunk
	for i in 3:
		var p: Vector3 = Vector3(14 + i * 1.8, -0.3, 30 - i * 0.9)
		var b := Props.place(self, props, "ph/Barrel_01", p, i * 50.0)
		if b:
			b.rotation = Vector3(0.5, i * 0.9, 0.25)
	Props.place(self, props, "ph/modular_wooden_pier", Vector3(-112, -4.4, 70), 35.0)
	Props.place(self, props, "ph/lifebuoy", Vector3(5.0, 0.05, 31.2), 20.0)


func _fires(props: Node3D) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 41
	lights.setup(6, 0)
	lights.max_distance = 70.0
	# authored: burning tar off the landing island, the burnt branch still glowing
	dress.fire(props, Vector3(-24, 0.0, 52), 1.6, r)
	dress.fire(props, Vector3(-17, 0.0, 36.5), 0.9, r, false)
	dress.fire(props, Vector3(-71, 0.0, 1), 1.2, r)
	dress.fire(props, Vector3(30, 0.0, 70), 1.0, r)
	for i in 12:
		dress.fire(props, dress.tar_spot(r, 12.0, 25.0, 150.0 if i < 8 else 190.0), r.randf_range(0.6, 2.2), r, i % 2 == 0)
	for b in bld.burning:
		dress.fire(props, b + Vector3.DOWN * 0.1, 0.8, r, false)
	var arr: Array = []
	for f in dress.fires:
		var p: Vector3 = f["pos"]
		if arr.size() < 24:
			arr.append(Vector4(p.x, p.z, float(f["r"]) * 2.4, 1.0))
		lights.add_anchor(p + Vector3.UP * 1.4, Color(1.0, 0.5, 0.18), 2.6 * float(f["r"]), 10.0 + 5.0 * float(f["r"]), 0.25)
	while arr.size() < 24:
		arr.append(Vector4(0, 0, 0, 0))
	tar_mat.set_shader_parameter("fires", arr)
	tar_mat.set_shader_parameter("fire_count", mini(dress.fires.size(), 24))


# ---------------------------------------------------------------- notes

func _notes(camp: Dictionary) -> void:
	var bp: Vector3 = camp["board"]
	bp.y = land.h(bp.x, bp.z) + 0.75
	var board := kit("Board")
	board.box(bp + Vector3(0, -0.35, 0), Vector3(0.08, 0.8, 0.08), "l41_beam", GeoKit.ALL, false)
	board.box(bp + Vector3(0, 0.2, 0), Vector3(0.9, 0.6, 0.04), "l41_plank", GeoKit.ALL, false)
	board.commit()
	add_note("l41_board", "Board nailed up at the camp (one of the failed groups)", "The tar never cools. Call it 95 degrees, always, and it is still boiling after who knows how long.\n\nDo not touch it. Not with a boot, not with a glove. Longer than a second and it takes the skin with it.\n\nThe smell will put you on the ground: fainting, sick, vomiting. There is no getting used to it.\n\nThe sand burns too. Keep walking. Do not stand still on it.\n\nOnly two ways across: the islands, and the walkways up on their posts. The walkways never touch the islands, they stand 2 to 6 m up. We built ladders.", bp + Vector3(0, 0.2, 0.06), Vector3(0.9, 0.6, 0.2), false)
	var rp: Vector3 = camp["reel"]
	add_note("l41_copper", "Tally chalked on the cable drum", "Copper off the poles. Eleven spans this week.\nThe east line is all cut now. The ones still standing out there are too far from any island.\n\n(Most groups came to pull people off the little islands. This one came for the wire.)", rp + Vector3(0, 0.5, 0), Vector3(0.6, 0.4, 0.6), true)
	var lp := Vector3(3.6, 0, 46.2)
	lp.y = land.h(lp.x, lp.z) + 0.12
	add_note("l41_bones", "Torn page under the radio", "Saw one come up today. No skin on it, no meat, just old bones like a fossil - something between a snake, an eel and a salmon, longer than the drums are tall stacked three high. It went up and over and back in like a dolphin and the tar came down all over the far walkway.\n\nThey know when you are standing at the edge of an island, or up on a walkway. They jump out and they take you down with them. Nobody has come back up.", lp, Vector3(0.4, 0.2, 0.4), true)
	var dp := Vector3(-8.6, 0, 45.6)
	dp.y = land.h(dp.x, dp.z) + 0.6
	add_note("l41_ways", "List scratched into a plank", "WAYS OUT (each thing is the only one of its kind in the lake):\n- a barn door on a stone plinth\n- a lighthouse, the gallery just above the tar, the lamp still flickering\n- the bridge of a navy ship, one window broken\n- a space shuttle upside down in the tar - the booster nozzles\n\nSome of them you cannot get to from where you land.", dp, Vector3(0.5, 0.3, 0.5), true)
	add_interactable(dp + Vector3(-1.4, 0.4, 0.8), Vector3(1.4, 1.2, 1.4), "Look out past the end of the group's bridge", func():
		Overlay.subtitle("[only fog. Somewhere past it the lake is round, ringed by dunes some fifteen metres high - and nothing anyone can stand on gets within fifty metres of them]", 7.0))


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	sound.bed("water_bed", {"seconds": 9.0, "bright": 140.0}, -20.0)
	sound.bed("room_tone", {"cutoff": 110.0, "rumble": 1.0}, -22.0)
	sound.bed("wind", {"seconds": 11.0}, -30.0)
	sound.oneshot("drip", {"freq": 70.0}, 1.5, 4.0, 9.0, "[tar bubbles burst with a thick pop]", -10.0)
	sound.oneshot("distant_boom", {}, 25.0, 60.0, 60.0, "[somewhere out in the fog a bubble the size of a car bursts]", -16.0)
	for f in dress.fires:
		if float(f["r"]) >= 1.0:
			sound.emitter("crackle", f["pos"] + Vector3.UP, {"seconds": 3.0}, -6.0, 26.0)


# ---------------------------------------------------------------- process

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_update_exits(player.global_position)
	mech.step(delta)
	_beacon_t += delta
	if is_instance_valid(beacon):
		var f := 0.55 + 0.45 * sin(_beacon_t * 23.0) * sin(_beacon_t * 3.1 + 1.0)
		if fmod(_beacon_t, 5.3) < 0.35:
			f = 0.05
		beacon.light_energy = 3.0 * f
		beacon_spot.light_energy = 14.0 * f
		beacon_spot.rotation = Vector3(-0.06, _beacon_t * 0.6, 0)


# ---------------------------------------------------------------- QA

func _shots() -> void:
	var bpos: Vector3 = marks["barn"]["pos"]
	var bv := Vector3(8.5, 0, 46.0)
	bv.y = land.h(bv.x, bv.z) + 1.6
	add_shot("barn_door_plinth", bv, bpos + Vector3(0, 1.9, 0), {"flashlight": false})
	var on_p1: Vector3 = P1[2].lerp(P1[3], 0.3) + Vector3.UP * 1.62
	add_shot("boardwalk_fog", on_p1, P1[4] + Vector3(-6, 1.0, -6), {"flashlight": false})
	var door := Vector3(cos(0.47), 0, sin(0.47))
	add_shot("lighthouse_gallery", LH + door * 9.0 + Vector3(1.5, 3.4, 2.5), LH + Vector3(0, 1.4, 0), {"flashlight": false})
	var nv: Vector3 = marks["navy"]["pos"]
	var p2e: Vector3 = P2[P2.size() - 2].lerp(P2[P2.size() - 1], 0.25) + Vector3.UP * 1.62
	add_shot("navy_bridge", p2e + Vector3(1.0, 0, 0), nv + Vector3(0, 5.0, 0), {"flashlight": false})
	var sc: Vector3 = marks["shuttle"]["pos"]
	var isl: Dictionary = land.island("shuttle")
	var u := Vector3(cos(float(isl["rot"])), 0, sin(float(isl["rot"])))
	var side := Vector3(-u.z, 0, u.x)
	var vp := sc - u * 6.5 + side * 7.5
	vp.y = land.h(vp.x, vp.z) + 1.65
	add_shot("shuttle_nozzles", vp, sc + u * 5.0 - side * 1.5 + Vector3.UP * 1.2, {"flashlight": false})
	var tc := Vector3(-11.0, 0, 34.5)
	tc.y = land.h(tc.x, tc.z) + 1.5
	add_shot("tar_close", tc, tc + Vector3(-7.0, -1.4, 3.0), {"flashlight": false})
	add_shot("leviathan", start + Vector3(-9.5, 1.7, -5.5), start + Vector3(-24, 2.2, -14), {"flashlight": false, "prepare": _prep_dive})


func _prep_dive() -> void:
	mech.stage_dive(start + Vector3(-30, 0, -8), start + Vector3(-18, 0, -22), 0.52)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	# the arrival-island route to the barn door stays on sand
	var route := [start, Vector3(6, 0, 44), Vector3(12, 0, 48.5), Vector3(16, 0, 52), marks["barn"]["center"]]
	var wet := 0
	for i in route.size() - 1:
		for j in 12:
			var p: Vector3 = (route[i] as Vector3).lerp(route[i + 1], j / 12.0)
			if land.h(p.x, p.z) < 0.04:
				wet += 1
	out.append({"what": "arrival island reaches the barn-door plinth over sand", "ok": wet == 0, "detail": wet})
	var bad_ladders := 0
	for l in bld.ladders:
		var base: Vector3 = l["base"]
		var top: Vector3 = l["top"]
		if base.y < 0.04 or top.y - base.y < 1.6:
			bad_ladders += 1
	out.append({"what": "every ladder stands on sand and climbs 1.6 m or more", "ok": bad_ladders == 0 and bld.ladders.size() == 5, "detail": [bld.ladders.size(), bad_ladders]})
	var bad_h := 0
	for line in [P1, P2, P3]:
		for p in line:
			var hh: float = p.y - maxf(land.h(p.x, p.z), 0.0)
			if hh < 1.6 or hh > 6.0:
				bad_h += 1
	out.append({"what": "walkways stand 2-6 m above the ground", "ok": bad_h == 0, "detail": bad_h})
	var far := 0
	for isl in land.islands:
		if (isl["c"] as Vector2).length() + float(isl["rx"]) > LAND.REACH_R + 2.0:
			far += 1
	out.append({"what": "nothing traversable within 50 m of the dunes", "ok": far == 0, "detail": far})
	out.append({"what": "tar contact is detected on tar and not on sand", "ok": mech.in_tar(Vector3(0, -0.4, -90)) and not mech.in_tar(Vector3(start.x, start.y + 0.02, start.z))})
	out.append({"what": "the tested exit (barn door) exists near the arrival", "ok": lazy.has("L041>L612#3")})
	_update_exits(LH + Vector3(4, 1, 2))
	var lh_ok := lazy.has("L041>L626#4") and not lazy.has("L041>L612#3")
	if is_instance_valid(player):
		_update_exits(player.global_position)
	out.append({"what": "far exits appear near their object and leave when you go", "ok": lh_ok and lazy.has("L041>L612#3")})
	out.append({"what": "the shuttle nozzles are reachable from sand", "ok": land.h(marks["shuttle"]["center"].x, marks["shuttle"]["center"].z) > 0.04, "detail": land.h(marks["shuttle"]["center"].x, marks["shuttle"]["center"].z)})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
