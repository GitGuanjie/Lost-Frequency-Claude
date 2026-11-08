extends LevelBase
## Level 52 "DESTINATION REACHED" (Backrooms Wikidot rev 15, accessed 2026-11-04;
## CamaradeAlbabar, CC BY-SA 3.0). Dossier: docs/canon/levels/L052.md.
##
## PLAN (read -> design):
## - SOURCE: entered through a shallow passage that makes movement difficult, opening
##   onto a large cavern; the mouth is smaller from within than from outside, so the way
##   back is impossible. -> Arrival on a dark rock apron a few metres outside the mouth
##   (ADAPTATION: Plane #445 is not described, so this is bare rock). A lofted crawl tube
##   (1.35 m crest: crouch only) runs 19 m down into the cavern. Once you stand in the
##   cavern the passage behind you tapers to a hand-sized hole (stateful).
## - SOURCE: three incomplete remains (bloated, decaying, skeletal) three metres from the
##   entrance; Dina A.'s notebook in a torn rucksack with delivery papers. -> set dressing on
##   the apron; the notebook is an examine note whose entries degrade.
## - SOURCE: limestone cave, earthy walls, no natural light, height from ~2 m to much taller,
##   stalactites, unknown length. -> SDF caves meshed per streamed 24 m chunk (method from
##   L008): a first hall, a campfire alcove, a 2 m low gallery, a side loop, a 13 m second
##   hall with a ramp to a ledge 4.6 m up (two walkable heights), then a seeded gallery that
##   keeps going east. No light at all except the player's flashlight.
## - SOURCE: reddish-brown drawings on every inspected wall (three figures round a fire, two
##   crossed out; animals, some degraded; a figure enclosed by small shapes), hand prints,
##   clawing; one extinguished campfire, crude tools; few bugs; water only as drips.
## - SOURCE (diary): feeling observed, mentions of eyes increase. -> stateful mechanic: the
##   longer you stay (faster with the light off) the more pairs of eyes are painted on the
##   walls around you, always where you were not looking. No entity is ever shown.
## - No exit is stated: none is built (no_exit_reason in level.json).

const C := preload("res://levels/L052/L052_cave.gd")
const Plan := preload("res://levels/L052/L052_plan.gd")
const Art := preload("res://levels/L052/L052_art.gd")
const CS := C.CS

var plan
var world: ChunkWorld
var noise := FastNoiseLite.new()
var qa_fixture := false
var chunk_feats: Dictionary = {}
var crawl_node: Node3D
var mouth_closed := false
var watch := 0.0
var eyes: Array = []
var bugs: Array = []
var authored_art := 0
var _said: Dictionary = {}
var _eye_t := 0.0
var _heart: AudioStreamPlayer
var _room: AudioStreamPlayer


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.9
	rules["reverb_wet"] = 0.34
	rules["kill_y"] = -80.0
	indoor_env(Color(0.55, 0.5, 0.44), 0.022, Color(0.003, 0.0026, 0.002), 0.011)
	environment.tonemap_exposure = 1.75
	environment.glow_intensity = 0.25
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	environment.adjustment_contrast = 1.06
	_materials()
	noise.seed = level_seed
	noise.frequency = 0.13
	noise.fractal_octaves = 3
	plan = Plan.new(level_seed)
	world = ChunkWorld.new()
	world.name = "Cave"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.build_around(Plan.APRON, 2)
	_crawl(false)
	_apron()
	_alcove()
	_authored_art()
	_sounds()
	add_arrival("start", Plan.APRON + Vector3(-2.4, 0.05, 0.4), -90.0)
	add_landmark("The mouth of Plane #52 (crawl)", Plan.CRAWL[0])
	add_landmark("First hall", Plan.HALL1)
	add_landmark("The extinguished campfire", Plan.FIRE)
	add_landmark("Second hall and ledge", Plan.HALL2)
	add_shot("entrance", Plan.APRON + Vector3(-3.6, 1.55, 1.9), Plan.APRON + Vector3(3.5, 0.2, -0.4), {"flashlight": true, "prepare": _prep.bind(Plan.APRON)})
	add_shot("hall", Vector3(0.0, 0.5, -3.0), Vector3(14.0, 3.5, 3.0), {"flashlight": true, "prepare": _prep.bind(Plan.HALL1)})
	add_shot("campfire", Plan.FIRE + Vector3(-1.3, 1.25, -2.3), Plan.FIRE + Vector3(0.3, 0.8, 3.4), {"flashlight": true, "prepare": _prep.bind(Plan.FIRE)})
	add_shot("ledge", Vector3(75.0, -1.9, 6.0), Vector3(84.0, 2.4, -9.0), {"flashlight": true, "prepare": _prep.bind(Plan.HALL2)})
	var n2: Vector3 = plan.nodes[2]["p"]
	var n3: Vector3 = plan.nodes[3]["p"]
	add_shot("low_gallery", n2.lerp(n3, 0.15) + Vector3(0, 1.6, 0), n3 + Vector3(0, 0.9, 0), {"flashlight": true, "prepare": _prep.bind(n2.lerp(n3, 0.5))})
	add_shot("crawl", Plan.CRAWL[3] + Vector3(-0.4, 0.92, 0.0), Plan.CRAWL[1] + Vector3(0, 0.6, 0), {"flashlight": true, "prepare": _prep_closed})


func _materials() -> void:
	var rock := ORMMaterial3D.new()
	var base := "res://assets/external/%s/%s_%s_1k.jpg"
	rock.albedo_texture = load(base % ["aerial_rocks_02", "aerial_rocks_02", "diff"])
	rock.normal_enabled = true
	rock.normal_texture = load(base % ["aerial_rocks_02", "aerial_rocks_02", "nor_gl"])
	rock.orm_texture = load(base % ["aerial_rocks_02", "aerial_rocks_02", "arm"])
	rock.albedo_color = Color(0.98, 0.76, 0.56)
	rock.uv1_triplanar = true
	rock.uv1_scale = Vector3(0.3, 0.3, 0.3)
	rock.uv1_triplanar_sharpness = 5.0
	rock.normal_scale = 1.4
	MatLib.register("l52_rock", rock)
	var fl := ORMMaterial3D.new()
	fl.albedo_texture = load(base % ["dirt_floor", "dirt_floor", "diff"])
	fl.normal_enabled = true
	fl.normal_texture = load(base % ["dirt_floor", "dirt_floor", "nor_gl"])
	fl.orm_texture = load(base % ["dirt_floor", "dirt_floor", "arm"])
	fl.albedo_color = Color(0.6, 0.5, 0.4)
	fl.uv1_triplanar = true
	fl.uv1_scale = Vector3(0.33, 0.33, 0.33)
	MatLib.register("l52_floor", fl)
	var flow := rock.duplicate() as ORMMaterial3D
	flow.albedo_color = Color(1.0, 0.8, 0.6)
	flow.roughness = 0.45
	MatLib.register("l52_flowstone", flow)
	MatLib.register("l52_puddle", MatLib.standard(Color(0.26, 0.2, 0.15), 0.04, 0.0))


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var region := AABB(Vector3(ox - C.H, -60.0, oz - C.H), Vector3(CS + C.H * 2.0, 120.0, CS + C.H * 2.0))
	var fs: Array = plan.features_for(region)
	var key := Vector2i(cx, cz)
	chunk_feats[key] = fs
	if fs.is_empty():
		return {"kind": "solid"}
	var ylo := 1e9
	var yhi := -1e9
	for f in fs:
		ylo = minf(ylo, (f["bb"] as AABB).position.y)
		yhi = maxf(yhi, (f["bb"] as AABB).end.y)
	var gy0 := floori(ylo / C.H) - 1
	var gy1 := ceili(yhi / C.H) + 1
	var field := C.Field.new(Vector3i(cx * C.N - 1, gy0, cz * C.N - 1), Vector3i(C.N + 2, gy1 - gy0 + 1, C.N + 2), noise)
	for f in fs:
		field.carve(f)
	field.clamp_all()
	var fa := C.Acc.new()
	var wa := C.Acc.new()
	field.mesh(fa, wa)
	C.commit(node, fa, "l52_floor", true, "dirt")
	C.commit(node, wa, "l52_rock", true, "concrete")
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "dress", cx, cz, version])
	_dress(node, fs, r, ox, oz)
	return {"kind": "cave"}


## Stalactites, breakdown rocks, paintings, drips and bugs along the spine of this chunk.
func _dress(node: Node3D, fs: Array, r: RandomNumberGenerator, ox: float, oz: float) -> void:
	var pts: Array = plan.spine_points(ox, ox + CS, oz, oz + CS, 3.0)
	for f in fs:
		if f["t"] == "room":
			var c: Vector3 = f["c"]
			if c.x >= ox and c.x < ox + CS and c.z >= oz and c.z < oz + CS:
				var rr0: Vector3 = f["r"]
				if rr0.x > 8.0 and r.randf() < 0.7:
					var bp := Vector3(c.x + r.randf_range(-0.5, 0.5) * rr0.x, float(f["f"]) - 0.3, c.z + r.randf_range(-0.5, 0.5) * rr0.z)
					Props.place(self, node, "ph/boulder_01", bp, r.randf_range(0, 360), r.randf_range(1.6, 2.8), true)
				for i in 6:
					var rr: Vector3 = f["r"]
					pts.append({"p": Vector3(c.x + r.randf_range(-0.6, 0.6) * rr.x, f["f"], c.z + r.randf_range(-0.6, 0.6) * rr.z), "kind": "room", "dir": Vector3.RIGHT})
	if pts.is_empty():
		return
	var spikes := C.Acc.new()
	var rocks := Node3D.new()
	rocks.name = "Dress"
	node.add_child(rocks)
	var art_left := r.randi_range(2, 4)
	var drips := r.randi_range(1, 2)
	var bug_left := r.randi_range(0, 2)
	for i in pts.size() * 3:
		var sp: Dictionary = pts[r.randi() % pts.size()]
		var base: Vector3 = sp["p"]
		var dir: Vector3 = sp["dir"]
		var side := Vector3(-dir.z, 0, dir.x)
		var air := base + side * r.randf_range(-2.4, 2.4) + Vector3(0, 1.1, 0)
		if C.sdf(fs, air, noise) > -0.25:
			continue
		var up := C.march(fs, air, Vector3.UP, 16.0, noise)
		if up.is_empty():
			continue
		var ceil_y: float = (up["p"] as Vector3).y
		var dn0 := C.march(fs, air, Vector3.DOWN, 8.0, noise)
		var floor_y: float = (dn0["p"] as Vector3).y if not dn0.is_empty() else base.y
		var room := ceil_y - floor_y
		var length := r.randf_range(0.25, 1.9) * (1.0 if room > 4.0 else 0.4) * (1.8 if room > 8.0 else 1.0)
		length = minf(length, maxf(0.12, room - 2.05))
		var cl := 1 + (r.randi() % 3 if room > 3.0 else 0)
		for k in cl:
			var off := Vector3(r.randf_range(-0.5, 0.5), 0.15, r.randf_range(-0.5, 0.5)) * (0.0 if k == 0 else 1.0)
			var l2 := length * (1.0 if k == 0 else r.randf_range(0.3, 0.7))
			C.spike(spikes, up["p"] + off, Vector3(r.randf_range(-0.06, 0.06), -1, r.randf_range(-0.06, 0.06)).normalized(), l2, maxf(0.05, l2 * r.randf_range(0.13, 0.2)), r)
		if drips > 0 and room > 2.6 and r.randf() < 0.3:
			drips -= 1
			_drip(node, Vector3(up["p"].x, floor_y, up["p"].z), up["p"])
	for i in pts.size():
		var sp: Dictionary = pts[r.randi() % pts.size()]
		var base: Vector3 = sp["p"]
		var dir: Vector3 = sp["dir"]
		var side := Vector3(-dir.z, 0, dir.x) * (1.0 if r.randf() < 0.5 else -1.0)
		var air := base + Vector3(0, 1.5, 0)
		if C.sdf(fs, air, noise) > -0.3:
			continue
		var hit := C.march(fs, air, (side + dir * r.randf_range(-0.4, 0.4)).normalized(), 14.0, noise)
		if hit.is_empty() or absf((hit["n"] as Vector3).y) > 0.55:
			continue
		var hp: Vector3 = hit["p"]
		var hn: Vector3 = hit["n"]
		if art_left > 0 and hp.y - base.y > 0.7:
			art_left -= 1
			var kinds := ["animals", "animals_bad", "campfire", "hands", "claws", "enclosed", "animals_bad"]
			var kd: String = kinds[r.randi() % kinds.size()]
			var w := r.randf_range(1.0, 1.8)
			Art.decal(node, hp, hn, w, w, Art.texture(kd, r.randi() % 3), r.randf_range(0.7, 0.92))
		else:
			# breakdown: rocks fallen against the wall, off the walking line
			var fp := hp + hn * r.randf_range(0.6, 1.3)
			var dn := C.march(fs, fp + Vector3(0, 0.6, 0), Vector3.DOWN, 6.0, noise)
			if dn.is_empty():
				continue
			var g: Vector3 = dn["p"]
			var big := r.randf() < 0.45
			if big:
				Props.place(self, rocks, "ph/boulder_01", g - Vector3(0, 0.15, 0), r.randf_range(0, 360), r.randf_range(0.6, 1.3), true)
			else:
				Props.place(self, rocks, "ph/rock_07", g - Vector3(0, 0.03, 0), r.randf_range(0, 360), r.randf_range(0.12, 0.5))
		if bug_left > 0 and r.randf() < 0.4:
			bug_left -= 1
			_bug(node, hp + hn * 0.05, hn, r)
	C.commit(node, spikes, "l52_flowstone", false, "concrete")


func _drip(node: Node3D, floor_p: Vector3, tip: Vector3) -> void:
	var pud := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.35
	cm.bottom_radius = 0.35
	cm.height = 0.01
	pud.mesh = cm
	pud.material_override = MatLib.get_mat("l52_puddle")
	pud.position = floor_p + Vector3(0, 0.02, 0)
	pud.scale = Vector3(1.0, 1.0, 0.7)
	node.add_child(pud)
	var e := sound.emitter("drip", tip, {"freq": [980.0, 1150.0, 1320.0][absi(int(tip.x)) % 3]}, -14.0, 14.0)
	if e:
		e.reparent(node)
	make_interactable(floor_p + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 1.0), "Catch the drips from the stalactite", func(_p: Player) -> void:
		Overlay.subtitle("[a drop every few seconds. It takes minutes to wet your mouth.]", 3.5), node)


func _bug(node: Node3D, at: Vector3, n: Vector3, r: RandomNumberGenerator) -> void:
	var holder := Node3D.new()
	holder.name = "Bug"
	node.add_child(holder)
	holder.position = at
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.008
	cap.height = 0.03
	cap.radial_segments = 6
	cap.rings = 2
	mi.mesh = cap
	mi.material_override = MatLib.standard(Color(0.05, 0.04, 0.03), 0.3)
	mi.rotation = Vector3(PI * 0.5, 0, 0)
	holder.add_child(mi)
	bugs.append({"node": holder, "home": at, "n": n, "ph": r.randf() * TAU, "sp": r.randf_range(0.3, 0.8)})
	make_interactable(at, Vector3(0.5, 0.5, 0.5), "Look at the bug", func(_p: Player) -> void:
		Overlay.subtitle("[a small pale beetle on the damp rock. Whether it is edible, nobody knows.]", 3.5), node)


# ------------------------------------------------------------- set pieces

func _crawl(closed: bool) -> void:
	if is_instance_valid(crawl_node):
		crawl_node.queue_free()
	crawl_node = Node3D.new()
	crawl_node.name = "CrawlClosed" if closed else "Crawl"
	add_child(crawl_node)
	var path: Array = Plan.CRAWL
	var total := 0.0
	for i in path.size() - 1:
		total += (path[i] as Vector3).distance_to(path[i + 1])
	var prof := func(t: float) -> Vector2:
		var m := t * total
		var w := 0.95
		var h := 1.35
		var e0 := 1.0 - clampf(m / 1.8, 0.0, 1.0)
		var e1 := 1.0 - clampf((total - m) / 1.8, 0.0, 1.0)
		if closed:
			var k := clampf(1.0 - m / 6.0, 0.0, 1.0)
			k = k * k
			w = lerpf(w, 0.16, k)
			h = lerpf(h, 0.26, k)
		else:
			w = lerpf(w, 2.8, e0 * e0)
			h = lerpf(h, 3.6, e0 * e0)
		w = lerpf(w, 2.8, e1 * e1)
		h = lerpf(h, 3.6, e1 * e1)
		return Vector2(w, h)
	var a := C.Acc.new()
	var fa := C.Acc.new()
	C.loft(a, fa, path, prof, noise)
	C.commit(crawl_node, a, "l52_rock", true, "concrete")
	C.commit(crawl_node, fa, "l52_floor", true, "dirt")


func _close_mouth() -> void:
	if mouth_closed:
		return
	mouth_closed = true
	_crawl(true)
	if not qa_fixture:
		add_interactable(Plan.CRAWL[0] + Vector3(4.2, 0.6, 0.0), Vector3(1.2, 1.2, 1.4), "Try to squeeze back out", func(_p: Player) -> void:
			Overlay.subtitle("[the mouth is smaller from in here than it was outside. Not even your arm fits.]", 4.0))


func _apron() -> void:
	var k := Node3D.new()
	k.name = "Entrance"
	add_child(k)
	Art.remains(k, Plan.CRAWL[0] + Vector3(-3.0, 0.0, 0.2), 0.2)
	add_interactable(Plan.CRAWL[0] + Vector3(-3.0, 0.6, 0.2), Vector3(3.0, 1.2, 2.6), "Look at the remains", func(_p: Player) -> void:
		Overlay.subtitle("[three bodies three metres from the mouth: one bloated, one rotting, one bare bone. Each is missing limbs, cut with something crude or torn off.]", 6.0))
	var rk := Plan.CRAWL[0] + Vector3(-1.85, 0.0, -0.7)
	add_note("dina_notebook", "NOTEBOOK OF DINA A. (courier, Supplying and Communications Agency)",
		"57 entries; 43 can still be read.\n\n#1, 28/05/1997: arrived with the delivery. Dark cave, no light but mine.\n#9: the feeling that something watches me while I sleep.\n#20: more drawings on the walls than I counted yesterday.\n#33, 14/04/2009: the last date. After this, no dates.\n#38: \"eyes\" again, and again.\n#44 onward: the hand gets worse; words fall apart.\n#52 to #56: crude drawings and prints. Every one has a pair of eyes.\n#57: \"I se e yo u\"\n\n(The bones beside the bag are not bleached enough to be ten years old.)",
		rk + Vector3(0.15, 0.06, 0.35))
	add_note("delivery_papers", "DELIVERY INSTRUCTIONS - PLANE #52",
		"Water-stained papers from the torn rucksack: instructions for a delivery to Plane #52. Across the top, in a later hand: delivery successful; all further requests to supply Plane #52 are to be ignored.",
		rk + Vector3(-0.35, 0.03, 0.15))


func _alcove() -> void:
	var k := Node3D.new()
	k.name = "Campfire"
	add_child(k)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "fire"])
	Art.campfire(self, k, Plan.FIRE, r)
	Art.tools(self, k, Plan.FIRE + Vector3(1.4, 0, 0.6), r)
	add_interactable(Plan.FIRE + Vector3(0, 0.4, 0), Vector3(1.4, 0.8, 1.4), "Feel the ashes", func(_p: Player) -> void:
		Overlay.subtitle("[cold, packed ash. The only campfire anyone has found in here, and it went out long ago.]", 4.0))
	add_interactable(Plan.FIRE + Vector3(1.4, 0.3, 0.6), Vector3(1.2, 0.6, 1.2), "Examine the crude tools", func(_p: Player) -> void:
		Overlay.subtitle("[knapped stones, a bone, a stick sharpened to a point. Prehistoric work, or someone forced to work like it.]", 4.5))


## Hand-placed drawings: their walls are found by marching the same SDF the mesh uses.
func _authored_art() -> void:
	var holder := Node3D.new()
	holder.name = "Paintings"
	add_child(holder)
	var fs: Array = plan.features_for(AABB(Vector3(-40, -40, -40), Vector3(170, 80, 80)))
	var spots := [
		[Plan.FIRE + Vector3(0, 1.5, 0), Vector3(0.1, 0, 1), "campfire", 0, 1.9, "three stick figures round a fire; two have been crossed out"],
		[Plan.FIRE + Vector3(0, 1.2, 0), Vector3(1, 0, 0.6), "hands", 1, 1.4, "hand prints in the same reddish brown"],
		[Plan.FIRE + Vector3(0, 1.4, 0), Vector3(-1, 0, 0.5), "campfire", 1, 1.6, "the fire and the figures again; this time a different two are crossed out"],
		[Vector3(-1.0, 0.4, 0.2), Vector3(0.2, 0, -1), "claws", 0, 1.3, "deep parallel scratches. Something clawed at the rock here"],
		[Vector3(-1.0, 0.4, 0.2), Vector3(0.2, 0, 1), "claws", 1, 1.1, "more clawing, at the height of a kneeling person"],
		[Vector3(38.0, -0.8, 0.0), Vector3(0, 0, -1), "enclosed", 0, 1.5, "one stick figure, enclosed by small irregular shapes"],
		[Vector3(18.0, 0.5, 0.0), Vector3(0, 0, -1), "animals", 0, 2.2, "animals from above the threshold: one with tusks, one with antlers"],
		[Vector3(22.0, -0.4, -16.0), Vector3(0, 0, -1), "animals_bad", 0, 1.8, "the same animals, but wrong: legs in the wrong places, as if drawn from a fading memory"],
		[Plan.LEDGE + Vector3(1.0, 1.5, 0), Vector3(0.3, 0, -1), "animals_bad", 2, 2.0, "animals drawn from memory, the shapes failing"],
		[Plan.LEDGE + Vector3(-2.0, 1.5, 0), Vector3(-1, 0, -0.2), "hands", 0, 1.5, "hand prints, many sizes, one on top of another"],
	]
	for s in spots:
		var hit := C.march(fs, s[0], (s[1] as Vector3).normalized(), 18.0, noise)
		if hit.is_empty():
			continue
		var sz: float = s[4]
		Art.decal(holder, hit["p"], hit["n"], sz, sz, Art.texture(s[2], s[3]), 0.9)
		authored_art += 1
		var txt: String = s[5]
		add_interactable(hit["p"] + (hit["n"] as Vector3) * 0.5, Vector3(1.4, 1.4, 1.4), "Look at the drawing", func(_p: Player) -> void:
			Overlay.subtitle("[%s]" % txt, 4.5))


func _sounds() -> void:
	_room = sound.bed("room_tone", {"cutoff": 140.0, "rumble": 0.3, "seconds": 6.0}, -26.0)
	sound.oneshot("drip", {"freq": 1250.0}, 4.0, 11.0, 14.0, "[water drips from the stalactites]", -13.0)
	sound.oneshot("drip", {"freq": 820.0}, 7.0, 19.0, 20.0, "[a drop lands somewhere far off]", -18.0)
	_heart = sound.bed("heartbeat", {}, -80.0)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	player.flashlight.visible = true
	player.flashlight.spot_angle = 36.0
	player.flashlight.spot_angle_attenuation = 1.6
	player.flashlight.spot_range = 40.0
	player.flashlight.light_energy = 3.6
	player.flashlight.spot_attenuation = 0.75
	# a real torch throws a wide dim spill around its hot spot; it switches with the torch
	var spill := SpotLight3D.new()
	spill.name = "FlashlightSpill"
	spill.light_color = Color(1.0, 0.9, 0.78)
	spill.light_energy = 0.7
	spill.spot_angle = 62.0
	spill.spot_angle_attenuation = 0.8
	spill.spot_range = 24.0
	spill.shadow_enabled = false
	player.flashlight.add_child(spill)
	if not qa_fixture:
		Overlay.subtitle("[no light here but yours. Ahead, a passage in the rock no higher than your waist.]", 5.0)


func _prep(at: Vector3) -> void:
	world.build_around(at, 1)
	await get_tree().process_frame


func _prep_closed() -> void:
	_close_mouth()
	world.build_around(Plan.CRAWL[2], 1)
	await get_tree().process_frame


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	if not mouth_closed and p.x > -4.5:
		_close_mouth()
	var inside := p.x > -6.0
	if inside:
		var dark := not player.flashlight.visible
		watch = minf(1.0, watch + delta / 540.0 * (2.5 if dark else 1.0))
	_eye_t -= delta
	if _eye_t <= 0.0:
		_eye_t = 2.0
		var want := int(watch * 22.0)
		if eyes.size() < want:
			_spawn_eyes()
	var marks := {0.12: "[the skin on your neck prickles, as if someone were looking at it]",
		0.4: "[you are sure of it now: you are being watched]",
		0.7: "[there are more eyes on these walls than there were]", 0.95: "[I se e yo u]"}
	if not qa_fixture:
		for m in marks.keys():
			if watch >= float(m) and not _said.has(m):
				_said[m] = true
				Overlay.subtitle(marks[m], 4.5)
		Overlay.set_screen_effect("vignette", 0.2 + watch * 0.35)
	_heart.volume_db = -80.0 if watch < 0.35 else lerpf(-40.0, -16.0, (watch - 0.35) / 0.65)
	bugs = bugs.filter(func(b): return is_instance_valid(b["node"]))
	for b in bugs:
		var n := b["node"] as Node3D
		b["ph"] = float(b["ph"]) + delta * float(b["sp"])
		var nn: Vector3 = b["n"]
		var t1 := Vector3.UP.cross(nn)
		if t1.length() < 0.2:
			t1 = Vector3.RIGHT
		t1 = t1.normalized()
		var t2 := nn.cross(t1)
		n.position = (b["home"] as Vector3) + (t1 * sin(float(b["ph"])) + t2 * sin(float(b["ph"]) * 0.7)) * 0.12


## A new pair of eyes on a wall near the player, where the camera is not looking.
func _spawn_eyes() -> bool:
	var key := world.key_at(player.global_position)
	var fs: Array = chunk_feats.get(key, [])
	if fs.is_empty():
		return false
	var cam_f := -player.camera.global_transform.basis.z
	cam_f.y = 0.0
	cam_f = cam_f.normalized()
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "eyes", eyes.size()])
	for attempt in 8:
		var ang := r.randf_range(100.0, 260.0)
		var d := cam_f.rotated(Vector3.UP, deg_to_rad(ang))
		var from := player.global_position + Vector3(0, r.randf_range(1.2, 2.2), 0)
		var hit := C.march(fs, from, (d + Vector3(0, r.randf_range(-0.1, 0.25), 0)).normalized(), 12.0, noise)
		if hit.is_empty() or absf((hit["n"] as Vector3).y) > 0.6:
			continue
		var w := r.randf_range(0.5, 0.9)
		var dc := Art.decal(self, hit["p"], hit["n"], w, w, Art.texture("eyes", r.randi() % 3), r.randf_range(0.6, 0.9))
		dc.name = "EyePair"
		eyes.append(dc)
		if eyes.size() > 26:
			(eyes.pop_front() as Node).queue_free()
		return true
	return false


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "no exit is built (none stated); the reason is in level.json", "ok": exits.is_empty()})
	out.append({"what": "authored drawings found their walls", "ok": authored_art >= 7, "detail": authored_art})
	var lights_found := 0
	for l in find_children("*", "Light3D", true, false):
		if not player.is_ancestor_of(l):
			lights_found += 1
	out.append({"what": "no light source in the cave except the flashlight", "ok": lights_found == 0, "detail": lights_found})
	_close_mouth()
	await get_tree().process_frame
	out.append({"what": "the crawl behind you narrows once you are inside", "ok": mouth_closed and crawl_node.name == "CrawlClosed"})
	var before := eyes.size()
	watch = 0.5
	var made := false
	for i in 4:
		made = _spawn_eyes() or made
	out.append({"what": "eyes multiply on the walls as the watch grows", "ok": made and eyes.size() > before, "detail": [before, eyes.size()]})
	watch = 0.0
	return out
