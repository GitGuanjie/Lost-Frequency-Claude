extends LevelBase
## Level 8 — "Cave Systems" (Backrooms Wikidot rev 77, accessed 2026-11-04;
## cite: C-Graph and kai4C, CC BY-SA 3.0). Dossier: docs/canon/levels/L008.md.
##
## Organic karst caves streamed in 30 m columns (SDF + surface nets, CaveGeo).
## The 9th Road is the stable, authored spine: from the entrance pool (where
## wanderers surface from the water) through a phreatic tube, a vadose canyon,
## a breakdown chamber with floating boulders, a laddered shaft, a dip that
## floods in seconds (with a narrow high bypass) and out over sand, gravel and
## asphalt to Level 9. Markers every ~50 m glow with the M.E.G. paint and
## decay fast once left unobserved. Off the road, chunks shift when nobody is
## looking ("the same path twice may lead to a different chamber"): plain,
## spiked, breakdown, low-gravity and flood-prone chambers. Cold and wet bring
## drowsiness; standing still too long while freezing is fatal. Side exits:
## a tar pool whose hands drag you under (Level 41/91), a cracked floor that
## gives way (Level 69). Entities: hands of tar act; wranglers are only felt
## as tremors in the rock; chittering stays unseen.

const Cave := preload("res://levels/L008/CaveGeo.gd")
const Lay := preload("res://levels/L008/CaveBuild.gd")
const CS := Lay.CS
const GLOW := Color(0.55, 0.95, 0.78)

var world: ChunkWorld
var feats: Array = []
var noise := FastNoiseLite.new()
var qa_fixture := false
var markers: Array = []
var floods: Dictionary = {}
var lowg: Dictionary = {}
var floaters: Array = []
var dip: WaterVolume
var dip_t := 45.0
var dip_phase := 0
var wet := 0.0
var cold := 0.0
var drowsy := 0.0
var still_t := 0.0
var heater_on := false
var tar_grab := 0.0
var tar_hands: Node3D
var pit_slab: Node3D
var pit_t := 0.0
var tremor_t := 90.0
var _shake := 0.0
var _said: Dictionary = {}
var _rush: AudioStreamPlayer3D


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := not SessionState.is_story() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["view_distance"] = 140.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.32
	indoor_env(Color(0.4, 0.46, 0.52), 0.13, Color(0.018, 0.022, 0.026), 0.028)
	environment.tonemap_exposure = 1.3
	environment.glow_intensity = 0.55
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.85
	environment.adjustment_contrast = 1.08
	Lay.materials(GLOW)
	noise.seed = level_seed
	noise.frequency = 0.11
	noise.fractal_octaves = 3
	feats = Lay.road_features()
	lights.setup(10, 1)
	lights.max_distance = 40.0
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	world.can_shift = func(_k, meta): return meta.get("kind", "road") not in ["road", "solid"] and not meta.get("held", false)
	world.shift_enabled = true
	world.shift_after = 10.0
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", Vector3(6.0, 0.05, 4.0), -90.0)
	add_arrival("from_L007", Vector3(-15.5, -5.0, 1.0), -90.0)
	world.build_around(Vector3(6, 0, 4), 2)
	_set_pieces()
	_exits()
	_audio()
	add_landmark("Entrance pool and 9th Road sign", Vector3(4, 0, 0))
	add_landmark("Breakdown chamber", Lay.BREAK)
	add_landmark("Road shaft (ladder)", Lay.SHAFT)
	add_landmark("Road end", Lay.EXIT)


# ------------------------------------------------------------------ chunks

func _key(k: Vector2i) -> String:
	return "%d,%d" % [k.x, k.y]


func _build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var meta := {"kind": "road"}
	var region := AABB(Vector3(ox - Cave.H, -80.0, oz - Cave.H), Vector3(CS + Cave.H * 2.0, 160.0, CS + Cave.H * 2.0))
	var fs: Array = []
	for f in feats:
		if (f["bb"] as AABB).intersects(region):
			fs.append(f)
	var road := not fs.is_empty()
	var pts := Lay.portals_of(level_seed, cx, cz)
	var own: Array = []
	for pt in pts:
		own.append(Lay.stub(pt))
	var off := {}
	if road:
		for pt in pts:
			var inner: Vector3 = pt["inner"]
			var tgt := Lay.road_closest(inner)
			tgt.x = clampf(tgt.x, ox + 7.0, ox + CS - 7.0)
			tgt.z = clampf(tgt.z, oz + 7.0, oz + CS - 7.0)
			own.append({"t": "tube", "a": inner + Vector3(0, 1.2, 0), "b": tgt + Vector3(0, 1.3, 0), "ra": 2.0, "rb": 2.2, "sq": 0.9, "fa": inner.y, "fb": tgt.y, "amp": 0.7})
	elif pts.is_empty():
		meta["kind"] = "solid"
	else:
		off = Lay.offroad(level_seed, cx, cz, version, pts)
		meta["kind"] = off["kind"]
		var c: Vector3 = off["floor"]
		var rad: Vector3 = off["rad"]
		own.append({"t": "room", "c": c + Vector3(0, rad.y * 0.45, 0), "r": rad, "f": c.y, "amp": 1.4})
		for pt in pts:
			var inner: Vector3 = pt["inner"]
			own.append({"t": "tube", "a": c + Vector3(0, 1.3, 0), "b": inner + Vector3(0, 1.2, 0), "ra": 2.3, "rb": 2.0, "sq": 0.9, "fa": c.y, "fb": inner.y, "amp": 0.8})
		meta["center"] = c
		meta["rad"] = rad
	for o in own:
		o["bb"] = Cave.aabb_of(o)
		fs.append(o)
	if fs.is_empty():
		return meta
	var ylo := 1e9
	var yhi := -1e9
	for f in fs:
		var bb: AABB = f["bb"]
		ylo = minf(ylo, bb.position.y)
		yhi = maxf(yhi, bb.end.y)
	var gy0 := floori(ylo / Cave.H) - 1
	var gy1 := ceili(yhi / Cave.H) + 1
	var field := Cave.Field.new(Vector3i(cx * Lay.N - 1, gy0, cz * Lay.N - 1), Vector3i(Lay.N + 2, gy1 - gy0 + 1, Lay.N + 2), noise)
	for f in fs:
		field.carve(f)
	field.clamp_all()
	var fa := Cave.Acc.new()
	var wa := Cave.Acc.new()
	field.mesh(fa, wa)
	Cave.commit(node, fa, "l8_floor", true, "dirt")
	Cave.commit(node, wa, "l8_rock", true, "concrete")
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "props", cx, cz, version])
	var spikes := 8 if road else (34 if off.get("kind", "") == "spikes" else 10)
	_spikes(node, fa, wa, r, spikes, road)
	var key := _key(Vector2i(cx, cz))
	var k := GeoKit.new(node, "Props")
	if not off.is_empty():
		var c: Vector3 = off["floor"]
		var rad: Vector3 = off["rad"]
		match str(off["kind"]):
			"breakdown":
				for i in 7:
					var bp := c + Vector3(r.randf_range(-rad.x, rad.x) * 0.6, 0, r.randf_range(-rad.z, rad.z) * 0.6)
					var bs := Vector3(r.randf_range(0.8, 2.2), r.randf_range(0.6, 1.6), r.randf_range(0.8, 2.0))
					k.box_xf(Transform3D(Basis.from_euler(Vector3(r.randf() * 0.4, r.randf() * TAU, r.randf() * 0.4)), bp + Vector3(0, bs.y * 0.4, 0)), bs, "l8_rock")
			"lowg":
				lowg[key] = [c + Vector3(0, rad.y * 0.45, 0), rad]
				for i in 6:
					var fp := c + Vector3(r.randf_range(-rad.x, rad.x) * 0.5, r.randf_range(2.2, rad.y * 1.3), r.randf_range(-rad.z, rad.z) * 0.5)
					_floater(node, fp, r.randf_range(0.4, 1.1), r)
			"flood":
				var wv := WaterVolume.new()
				node.add_child(wv)
				wv.setup(c - Vector3(rad.x + 2, 1.0, rad.z + 2), c + Vector3(rad.x + 2, -0.9, rad.z + 2), "l8_lake", true)
				wv.tint = Color(0.16, 0.22, 0.2)
				floods[key] = {"wv": wv, "lo": c.y - 0.9, "hi": c.y + rad.y * 1.25, "t": r.randf_range(20.0, 60.0), "ph": 0}
	k.add_box_shape(Transform3D(Basis(), Vector3(ox + 2.0 + r.randf() * 26.0, -70.0, oz + 2.0 + r.randf() * 26.0)), Vector3(0.5, 0.5, 0.5), "concrete")
	k.commit()
	return meta


func _on_unload(k: Vector2i) -> void:
	var key := _key(k)
	floods.erase(key)
	lowg.erase(key)
	lights.remove_group(key)
	floaters = floaters.filter(func(f): return is_instance_valid(f["node"]))


## Stalagspikes from floors, ceilings and walls at chaotic angles.
func _spikes(node: Node3D, fa: Cave.Acc, wa: Cave.Acc, r: RandomNumberGenerator, count: int, road: bool) -> void:
	var a := Cave.Acc.new()
	var tries := 0
	var made := 0
	while made < count and tries < count * 6 and (fa.v.size() + wa.v.size()) > 0:
		tries += 1
		var use_floor := r.randf() < 0.3 and fa.v.size() > 0
		var src: Cave.Acc = fa if use_floor or wa.v.size() == 0 else wa
		var vi := r.randi() % src.v.size()
		var p := src.v[vi]
		var n := src.n[vi]
		if road and absf(n.y) < 0.75:
			continue
		var rc := Lay.road_closest(p)
		if Vector2(p.x - rc.x, p.z - rc.z).length() < 3.4 and n.y > 0.0:
			continue
		var dir := (n + Vector3(r.randf_range(-0.5, 0.5), r.randf_range(-0.3, 0.3), r.randf_range(-0.5, 0.5)) * (0.3 if road else 0.9)).normalized()
		var length := r.randf_range(0.7, 2.6) * (1.6 if n.y < -0.6 else 1.0)
		Cave.spike(a, p - n * 0.25, dir, length, length * r.randf_range(0.12, 0.2), r)
		made += 1
	Cave.commit(node, a, "l8_flowstone", false, "concrete")


func _floater(node: Node3D, p: Vector3, s: float, r: RandomNumberGenerator) -> void:
	var holder := Node3D.new()
	node.add_child(holder)
	var k := GeoKit.new(holder, "Floater")
	k.box_xf(Transform3D(Basis.from_euler(Vector3(r.randf() * TAU, r.randf() * TAU, 0)), p), Vector3(s, s * 0.8, s * 0.9), "l8_rock")
	k.commit()
	floaters.append({"node": holder, "pos": p, "s": s, "fallen": false})


# ------------------------------------------------------------- set pieces

func _set_pieces() -> void:
	var k := kit("Road")
	# entrance pool (almond water) and the ring of spikes round the shore
	var lake := WaterVolume.new()
	lake.name = "EntrancePool"
	add_child(lake)
	lake.setup(Vector3(-30, -8.0, -10), Vector3(5, -0.45, 10), "l8_lake", true)
	lake.tint = Color(0.2, 0.26, 0.22)
	var sa := Cave.Acc.new()
	var r := RandomNumberGenerator.new()
	r.seed = 88
	for i in 22:
		var ang := TAU * i / 22.0 + r.randf_range(-0.1, 0.1)
		var rr := r.randf_range(10.5, 13.0)
		var bp := Vector3(cos(ang) * rr * 1.25 + 2.0, -0.2, sin(ang) * rr)
		if bp.x < -6.0 or absf(bp.z - 2.0) < 3.5 and bp.x > 6.0:
			continue
		Cave.spike(sa, bp, Vector3(r.randf_range(-0.15, 0.15), 1, r.randf_range(-0.15, 0.15)).normalized(), r.randf_range(2.0, 4.5), r.randf_range(0.25, 0.45), r)
		Cave.spike(sa, Vector3(bp.x, 9.5, bp.z), Vector3(r.randf_range(-0.2, 0.2), -1, r.randf_range(-0.2, 0.2)).normalized(), r.randf_range(2.5, 5.0), r.randf_range(0.25, 0.5), r)
	Cave.commit(self, sa, "l8_flowstone", false, "concrete")
	# the welcome sign of the 9th Road, painted in faintly glittering paint
	var sp := Vector3(8.6, 0.0, -2.9)
	for px in [-0.75, 0.75]:
		k.box(sp + Vector3(px, 0.75, 0), Vector3(0.09, 1.5, 0.09), "l8_board")
	k.box(sp + Vector3(0, 1.55, 0), Vector3(1.9, 1.05, 0.06), "l8_board")
	_logo(sp + Vector3(-0.62, 1.66, 0.035), 0.2)
	_label(sp + Vector3(0.12, 1.56, 0.04), "WELCOME TO THE 9TH ROAD\n« M.E.G. OUTPOST (8.7 MILES|14 KM) »\nHelp is ahead! Stay strong.\nM.E.G. — Bettering Humanity", 0.0021, 0.0)
	lights.add_anchor(sp + Vector3(0, 1.7, 0.7), GLOW, 1.4, 11.0, 0.0, "sign")
	# markers every ~50 m
	var n := 1
	for mp in Lay.marker_points():
		var p: Vector3 = mp[0]
		var d: Vector3 = mp[1]
		var right := Vector3(-d.z, 0, d.x).normalized()
		var base := p + right * 1.75
		k.cylinder(base + Vector3(0, 0.7, 0), 0.05, 1.4, "l8_metal", 6)
		var face := Basis.looking_at(Vector3(-d.x, 0, -d.z).normalized())
		k.box_xf(Transform3D(face, base + Vector3(0, 1.35, 0)), Vector3(0.5, 0.36, 0.03), "l8_metal")
		var holder := Node3D.new()
		add_child(holder)
		holder.global_transform = Transform3D(face, base + Vector3(0, 1.35, 0))
		_logo_local(holder, Vector3(-0.15, 0.03, -0.02), 0.07)
		var lab := _label_local(holder, Vector3(0.07, 0.0, -0.02), "9TH ROAD\nMARKER #%d" % n, 0.0016)
		var li := lights.add_anchor(base + Vector3(0, 1.5, 0) - d * 0.6, GLOW, 0.7, 5.5, 0.0, "marker")
		markers.append({"num": n, "pos": base, "label": lab, "holder": holder, "light": li, "cond": 1.0, "seen": false, "reached": false})
		n += 1
	# M.E.G. ladder bolted up the east wall of the road shaft (12 m)
	for i in 34:
		k.box(Lay.SHAFT + Vector3(1.2, 0.3 + i * 0.36, 0), Vector3(0.05, 0.04, 0.6), "l8_metal", GeoKit.ALL, false)
	for sz in [-0.3, 0.3]:
		k.box(Lay.SHAFT + Vector3(1.25, 6.2, sz), Vector3(0.05, 12.4, 0.05), "l8_metal", GeoKit.ALL, false)
	k.box(Lay.SHAFT + Vector3(1.45, 5.8, 0), Vector3(0.06, 11.2, 3.4), "l8_metal", 0, true)
	k.box(Lay.SHAFT + Vector3(2.75, 11.96, 0), Vector3(2.3, 0.08, 2.0), "l8_metal")
	var lad := LadderVolume.new()
	add_child(lad)
	lad.setup(Lay.SHAFT + Vector3(0.3, 0.0, -1.3), Lay.SHAFT + Vector3(1.4, 13.2, 1.3))
	_caver(k)
	_tar()
	_pit(k)
	# the dip that floods
	dip = WaterVolume.new()
	dip.name = "FloodDip"
	add_child(dip)
	dip.setup(Vector3(229, -3.0, 11), Vector3(258, -2.9, 31), "l8_lake", true)
	dip.tint = Color(0.16, 0.22, 0.2)
	# road end: rock -> sand -> gravel -> asphalt, and a dim glow ahead
	var segs := [[312.0, 325.0, "l8_sand"], [325.0, 338.0, "l8_gravel"], [338.0, 353.0, "l8_asphalt"]]
	for sg in segs:
		var x0: float = sg[0]
		while x0 < float(sg[1]):
			var x1 := minf(x0 + 3.0, float(sg[1]))
			var pa := Lay.road_closest(Vector3(x0, 0, 44))
			var pb := Lay.road_closest(Vector3(x1, 0, 46))
			var c := (pa + pb) * 0.5
			k.box(c + Vector3(0, 0.03, 0), Vector3(x1 - x0 + 0.05, 0.06, 3.4), sg[2])
			x0 = x1
	var glow := OmniLight3D.new()
	glow.position = Lay.EXIT + Vector3(3.5, 2.6, 0)
	glow.light_color = Color(1.0, 0.62, 0.28)
	glow.light_energy = 1.6
	glow.omni_range = 22.0
	add_child(glow)
	k.commit()


func _label(p: Vector3, text: String, px: float, yaw: float) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = px
	l.font_size = 64
	l.modulate = GLOW
	l.outline_size = 0
	l.shaded = false
	l.double_sided = false
	l.position = p
	l.rotation.y = yaw
	add_child(l)
	return l


func _label_local(parent: Node3D, p: Vector3, text: String, px: float) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.pixel_size = px
	l.font_size = 64
	l.modulate = GLOW
	l.outline_size = 0
	l.position = p
	l.rotation.y = PI
	parent.add_child(l)
	return l


## The M.E.G. eagle: a ring and two swept wings in luminous paint.
func _logo(c: Vector3, s: float) -> void:
	var holder := Node3D.new()
	add_child(holder)
	holder.position = c
	_logo_local(holder, Vector3.ZERO, s)


func _logo_local(parent: Node3D, c: Vector3, s: float) -> void:
	var k := GeoKit.new(parent, "Logo")
	for i in 16:
		var a := TAU * i / 16.0
		k.box_xf(Transform3D(Basis(Vector3.BACK, a), c + Vector3(cos(a), sin(a), 0) * s), Vector3(s * 0.42, s * 0.1, 0.01), "l8_paint", GeoKit.ALL, false)
	for sd in [-1.0, 1.0]:
		k.box_xf(Transform3D(Basis(Vector3.BACK, sd * 0.45), c + Vector3(sd * s * 0.42, s * 0.12, 0)), Vector3(s * 0.75, s * 0.14, 0.012), "l8_paint", GeoKit.ALL, false)
	k.box(c + Vector3(0, -s * 0.15, 0), Vector3(s * 0.16, s * 0.45, 0.012), "l8_paint", GeoKit.ALL, false)
	k.commit()


func _caver(k: GeoKit) -> void:
	# the vignette's dead caver: seated against the wall, pack at his feet
	var c := Lay.CAVER + Vector3(0, 0, 1.3)
	var xf := Transform3D(Basis(Vector3.UP, PI), c)
	for b in [[Vector3(0, 0.55, 0.12), Vector3(0.42, 0.62, 0.26), "l8_suit"], [Vector3(0, 1.0, 0.16), Vector3(0.2, 0.24, 0.22), "l8_skin"],
			[Vector3(-0.12, 0.12, -0.32), Vector3(0.15, 0.15, 0.7), "l8_suit"], [Vector3(0.12, 0.12, -0.3), Vector3(0.15, 0.15, 0.7), "l8_suit"],
			[Vector3(-0.27, 0.42, -0.02), Vector3(0.1, 0.1, 0.5), "l8_suit"], [Vector3(0.27, 0.42, -0.02), Vector3(0.1, 0.1, 0.5), "l8_suit"],
			[Vector3(0.05, 0.2, -0.95), Vector3(0.36, 0.42, 0.24), "l8_pack"], [Vector3(-0.45, 0.13, -0.75), Vector3(0.26, 0.26, 0.18), "l8_metal"]]:
		k.box_xf(xf * Transform3D(Basis(), b[0]), b[1], b[2], GeoKit.ALL, false)
	var heater_at: Vector3 = xf * Vector3(-0.45, 0.13, -0.66)
	var hk := GeoKit.new(self, "Heater")
	hk.box(heater_at, Vector3(0.18, 0.12, 0.02), "l8_heat", GeoKit.ALL, false)
	hk.commit()
	hk.root.visible = false
	add_interactable(xf * Vector3(0.05, 0.25, -0.95), Vector3(0.6, 0.6, 0.6), "Search the dead caver's backpack", func(_p):
		if SessionState.is_story():
			SaveService.add_item("flashlight")
		player.flashlight_policy = "allowed"
		Overlay.toast("A flashlight and a battery heater. The flashlight works, if dimly. (Flashlight key to switch it on.)", 5.0))
	add_interactable(heater_at, Vector3(0.5, 0.4, 0.5), "Switch on the battery heater", func(_p):
		heater_on = true
		hk.root.visible = true
		lights.add_anchor(heater_at + Vector3(0, 0.3, 0), Color(1.0, 0.5, 0.2), 0.8, 3.5, 0.0, "heater")
		Overlay.toast("The heater ticks and glows. Warmth, at last.", 3.5))
	set_meta("heater", heater_at)


func _tar() -> void:
	var t := Lay.TAR
	var k := kit("Tar")
	k.cylinder(t + Vector3(0, 0.02, 0), 2.4, 0.08, "l8_tar", 20, false)
	for i in 5:
		var a := TAU * i / 5.0
		k.box_xf(Transform3D(Basis(Vector3.UP, a), t + Vector3(cos(a) * 2.9, 0.03, sin(a) * 2.9)), Vector3(0.06, 0.05, 0.5), "l8_flowstone", GeoKit.ALL, false)
	k.commit()
	tar_hands = Node3D.new()
	add_child(tar_hands)
	tar_hands.position = t + Vector3(0, -2.4, 0)
	var hk := GeoKit.new(tar_hands, "Hands")
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		Cave.stone_hand(hk, Vector3(cos(a) * 1.3, 0, sin(a) * 1.3), a + PI * 0.5, 0.75, "l8_tar")
	hk.commit()
	tar_hands.visible = false
	var steam := CPUParticles3D.new()
	steam.position = t + Vector3(0, 0.1, 0)
	steam.amount = 40
	steam.lifetime = 5.0
	steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	steam.emission_sphere_radius = 1.8
	steam.direction = Vector3.UP
	steam.gravity = Vector3(0, 0.15, 0)
	steam.initial_velocity_min = 0.1
	steam.initial_velocity_max = 0.3
	steam.scale_amount_min = 2.0
	steam.scale_amount_max = 5.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.25, 0.25)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.7, 0.68, 0.08)
	qm.material = m
	steam.mesh = qm
	add_child(steam)


func _pit(k: GeoKit) -> void:
	var p := Lay.PIT
	pit_slab = Node3D.new()
	add_child(pit_slab)
	var sk := GeoKit.new(pit_slab, "CrackedFloor")
	sk.box(p + Vector3(0, -0.18, 0), Vector3(4.4, 0.4, 4.4), "l8_cracked")
	sk.commit()
	for i in 4:
		k.box_xf(Transform3D(Basis(Vector3.UP, i * 0.9), p + Vector3(cos(i * 1.7) * 3.2, 0.12, sin(i * 1.7) * 3.2)), Vector3(0.5, 0.25, 0.4), "l8_rock", GeoKit.ALL, false)


# ------------------------------------------------------------------- exits

func _exits() -> void:
	if qa_fixture:
		# QA FIXTURE ONLY: the road-end trigger copied 24 m into the first road
		# tube so the walker bot fires L008>L009#1 through the normal logic.
		add_exit("L008>L009#1", "walk_in", Vector3(34.0, 0.9, 4.8), Vector3(3.0, 3.0, 5.0), "")
		qa_routes.append({"edge": "L008>L009#1", "target": Vector3(34.0, -0.5, 4.8), "note": "QA fixture: road-end trigger placed in the first tube"})
		return
	add_exit("L008>L009#1", "walk_in", Lay.EXIT + Vector3(0, 1.5, 0), Vector3(3.0, 3.5, 6.0), "")
	var tr := add_exit("L008>L041#3", "condition", Lay.TAR + Vector3(0, 1.2, 0), Vector3(5.6, 3.0, 5.6), "")
	if tr:
		tr.condition = func() -> bool: return tar_grab >= 3.0
	var fl := add_exit("L008>L069#8", "fall", Lay.PIT + Vector3(0, -6.0, 0), Vector3(3.6, 12.0, 3.6), "")
	if fl:
		fl.fall_y = Lay.PIT.y - 5.0


# ------------------------------------------------------------------- audio

func _audio() -> void:
	sound.bed("room_tone", {"cutoff": 200.0, "rumble": 0.2}, -21.0)
	sound.emitter("water_bed", Lay.LAKE + Vector3(0, 0, 0), {"bright": 520.0}, -9.0, 28.0)
	sound.emitter("water_bed", Lay.TAR + Vector3(0, 0.5, 0), {"bright": 140.0}, -4.0, 22.0)
	sound.emitter("crickets", Lay.EXIT + Vector3(6, 2, 0), {}, -12.0, 70.0)
	_rush = sound.emitter("wind", Lay.DIP + Vector3(0, 2, 0), {"seconds": 6.0}, -60.0, 45.0)
	sound.oneshot("drip", {"freq": 1300.0}, 3.0, 9.0, 10.0, "[water drips in the dark]", -12.0)
	sound.oneshot("crackle", {"seconds": 1.4}, 14.0, 40.0, 14.0, "[chittering and clicking from something unseen]", -17.0)
	sound.oneshot("scratch", {}, 30.0, 80.0, 9.0, "[many small legs, somewhere in the rock]", -20.0)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	player.flashlight.light_energy = 2.0
	player.flashlight.spot_range = 20.0
	if TransitionService.pending_arrival == "from_L007" or spawn_report.get("used_arrival", "") == "from_L007":
		wet = 1.0
		cold = 0.35
		Overlay.subtitle("[you break the surface of a lake, soaked and shivering in the icy air]", 5.0)
	elif SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		Overlay.subtitle("[chittering and clicking echo off the rock] [the air is icy]", 5.0)
	SaveService.set_flag(stable_id, "arrived", true)
	if qa_fixture:
		pass


func _say(key: String, text: String, secs: float = 3.5) -> void:
	if not _said.has(key):
		_said[key] = true
		Overlay.subtitle(text, secs)


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var cam := get_viewport().get_camera_3d()
	_markers(delta, p, cam)
	# gravity fluctuates in magnitude off the road (low-gravity chambers)
	var g := 9.8
	for v in lowg.values():
		var c: Vector3 = v[0]
		var rad: Vector3 = v[1]
		if ((p - c) / rad).length() < 1.0:
			g = 9.8 * 0.4
			_say("lowg", "[your stomach lifts: gravity is weaker here]", 3.0)
	player.gravity = g
	for f in floaters:
		if not f["fallen"] and is_instance_valid(f["node"]) and p.distance_to(f["pos"]) < f["s"] + 0.7:
			f["fallen"] = true
			var tw := create_tween()
			tw.tween_property(f["node"], "position:y", -float(f["pos"].y - p.y) - 0.4, 0.9).set_ease(Tween.EASE_IN)
			sound.play_at("distant_boom", {}, f["pos"], -6.0, "[the floating rock drops]")
	# top of the road shaft: haul yourself over the lip onto the landing
	if player.on_ladder and p.y > Lay.SHAFT.y + 11.3 and Vector2(p.x - Lay.SHAFT.x, p.z - Lay.SHAFT.z).length() < 2.5:
		player.global_position = Lay.SHAFT + Vector3(2.9, 12.06, 0)
		player.velocity = Vector3.ZERO
		_say("lip", "[you haul yourself over the lip of the shaft, arms burning]", 3.0)
	_floods(delta, p)
	_cold(delta, p)
	_tar_and_pit(delta, p)
	tremor_t -= delta
	if tremor_t <= 0.0:
		tremor_t = randf_range(110.0, 220.0)
		_shake = 2.2
		sound.play_at("distant_boom", {}, p + Vector3(randf_range(-30, 30), -20, randf_range(-30, 30)), 2.0, "[a vast shape grinds through the rock somewhere below]")
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		player.camera.h_offset = randf_range(-0.04, 0.04) * _shake
		player.camera.v_offset = randf_range(-0.03, 0.03) * _shake
	if p.distance_to(Lay.EXIT) < 45.0:
		_say("glow", "[the rock gives way to sand underfoot… a dim glow, far ahead]", 4.0)


func _markers(delta: float, p: Vector3, cam: Camera3D) -> void:
	for m in markers:
		var to: Vector3 = (m["pos"] as Vector3) + Vector3(0, 1.3, 0) - (cam.global_position if cam else p)
		var dist := to.length()
		var seen_now := dist < 30.0 and cam != null and (-cam.global_transform.basis.z).dot(to / maxf(dist, 0.01)) > 0.55
		if seen_now:
			m["seen"] = true
		if m["seen"]:
			m["cond"] = maxf(0.0, m["cond"] - delta / (700.0 if seen_now else 70.0))
		var cnd: float = m["cond"]
		(m["label"] as Label3D).modulate = Color(GLOW.r, GLOW.g, GLOW.b, 0.12 + 0.88 * cnd)
		(m["holder"] as Node3D).visible = cnd > 0.04
		lights.anchors[m["light"]]["energy"] = 0.7 * cnd
		if not m["reached"] and p.distance_to(m["pos"]) < 3.2:
			m["reached"] = true
			checkpoint("marker_%d" % m["num"])
			Overlay.subtitle("[9th Road · Marker #%d]" % m["num"], 2.5)


func _floods(delta: float, p: Vector3) -> void:
	# the road dip: bone-dry, then submerged in a matter of seconds
	dip_t -= delta
	var lvl := dip.surface_y
	match dip_phase:
		0:
			if dip_t <= 6.0:
				dip_phase = 1
				if p.distance_to(Lay.DIP) < 45.0:
					Overlay.subtitle("[a rushing roar of water, close by]", 3.0)
			_rush.volume_db = lerpf(_rush.volume_db, -40.0, delta)
		1:
			_rush.volume_db = lerpf(_rush.volume_db, -4.0, delta * 2.0)
			if dip_t <= 0.0:
				dip_phase = 2
				dip_t = 7.0
		2:
			lvl = minf(1.4, lvl + delta * 4.4 / 7.0)
			if dip_t <= 0.0:
				dip_phase = 3
				dip_t = 18.0
		3:
			if dip_t <= 0.0:
				dip_phase = 4
		4:
			lvl -= delta * 4.4 / 12.0
			_rush.volume_db = lerpf(_rush.volume_db, -40.0, delta)
			if lvl <= -2.9:
				lvl = -2.9
				dip_phase = 0
				dip_t = randf_range(50.0, 80.0)
	dip.surface_y = lvl
	if dip.surface_mesh:
		dip.surface_mesh.position.y = lvl
	for f in floods.values():
		var wv: WaterVolume = f["wv"]
		if not is_instance_valid(wv):
			continue
		f["t"] -= delta
		var y := wv.surface_y
		if f["ph"] == 0 and f["t"] <= 0.0:
			f["ph"] = 1
			f["t"] = 20.0
			if p.distance_to(wv.aabb.get_center()) < 30.0:
				Overlay.subtitle("[water surges up through the floor]", 3.0)
		if f["ph"] == 1:
			y = minf(f["hi"], y + delta * (f["hi"] - f["lo"]) / 6.0)
			if f["t"] <= 0.0:
				f["ph"] = 2
		elif f["ph"] == 2:
			y = maxf(f["lo"], y - delta * (f["hi"] - f["lo"]) / 14.0)
			if y <= f["lo"]:
				f["ph"] = 0
				f["t"] = randf_range(40.0, 90.0)
		wv.surface_y = y
		if wv.surface_mesh:
			wv.surface_mesh.position.y = y


func _cold(delta: float, p: Vector3) -> void:
	if player.swimming:
		wet = 1.0
	else:
		wet = maxf(0.0, wet - delta / 240.0)
	var warm: bool = heater_on and p.distance_to(get_meta("heater")) < 3.5
	if warm:
		wet = maxf(0.0, wet - delta / 15.0)
		cold = maxf(0.0, cold - delta / 12.0)
		_say("warm", "[warmth seeps back into your hands]", 3.0)
	else:
		cold = clampf(cold + delta * (wet / 150.0 - 0.004), 0.0, 1.0)
	if cold > 0.45:
		_say("shiver", "[you are shivering hard; you need to get dry and keep moving]", 4.0)
	# hypothermia kills those who give in to exhaustion: keep moving
	if cold > 0.65 and player.velocity.length() < 0.3 and not player.swimming:
		still_t += delta
	else:
		still_t = 0.0
	if still_t > 6.0:
		drowsy = minf(1.0, drowsy + delta / 14.0)
		_say("drowsy", "[your eyelids are so heavy… keep moving, stay awake]", 4.0)
	else:
		drowsy = maxf(0.0, drowsy - delta / 2.0)
	Overlay.set_screen_effect("desaturate", clampf(cold * 0.45, 0.0, 0.45))
	Overlay.set_screen_effect("blackout", drowsy * 0.92)
	if drowsy >= 1.0 and not player.dead:
		player.hurt(1000.0, "You closed your eyes in the cold and did not open them again")


func _tar_and_pit(delta: float, p: Vector3) -> void:
	var tp := Lay.TAR
	var flat := Vector2(p.x - tp.x, p.z - tp.z)
	if flat.length() < 2.7 and absf(p.y - tp.y) < 1.5:
		if tar_grab <= 0.0:
			tar_hands.visible = true
			var tw := create_tween()
			tw.tween_property(tar_hands, "position:y", tp.y - 0.6, 0.8).set_ease(Tween.EASE_OUT)
			Overlay.subtitle("[hands black with tar rise out of the pool and seize you]", 3.5)
		tar_grab += delta
		if tar_grab > 0.6:
			player.velocity.x = -flat.x * 1.6
			player.velocity.z = -flat.y * 1.6
			player.walk_speed = 0.2
			player.sprint_speed = 0.2
	elif tar_grab > 0.0 and tar_grab < 0.6:
		tar_grab = 0.0
		tar_hands.visible = false
		tar_hands.position.y = tp.y - 2.4
	else:
		player.walk_speed = 3.1
		player.sprint_speed = 5.3
	if is_instance_valid(pit_slab) and Vector2(p.x - Lay.PIT.x, p.z - Lay.PIT.z).length() < 2.1 and absf(p.y - Lay.PIT.y) < 0.6:
		pit_t += delta
		if pit_t > 1.0:
			_say("crack", "[the floor cracks under your weight]", 2.0)
		if pit_t > 2.2:
			sound.play_at("distant_boom", {}, Lay.PIT, 0.0, "[the floor gives way]")
			pit_slab.queue_free()
	else:
		pit_t = maxf(0.0, pit_t - delta)


# ------------------------------------------------------------- QA captures

func qa_capture_plan() -> Array:
	var plan: Array = []
	var m1: Vector3 = markers[0]["pos"] if not markers.is_empty() else Vector3(24, 0, 4)
	plan.append({"name": "pool", "pos": Vector3(13.0, 1.7, 3.5), "target": Vector3(-8.0, 0.6, -1.5), "flashlight": true})
	plan.append({"name": "road", "pos": m1 + Vector3(-9.0, 1.6, -1.6), "target": m1 + Vector3(2.0, 1.0, 0.0),
		"prepare": func(): world.build_around(m1, 1)})
	plan.append({"name": "break", "pos": Lay.BREAK + Vector3(-15, 1.7, 4), "target": Lay.BREAK + Vector3(8, 5, -3), "flashlight": true,
		"prepare": func(): world.build_around(Lay.BREAK, 1)})
	plan.append({"name": "tar", "pos": Lay.TAR + Vector3(4.5, 1.7, 4.0), "target": Lay.TAR + Vector3(0, 0.6, 0), "flashlight": true,
		"prepare": func():
			world.build_around(Lay.TAR, 1)
			tar_hands.visible = true
			tar_hands.position.y = Lay.TAR.y - 0.6})
	plan.append({"name": "exit", "pos": Lay.EXIT + Vector3(-22, 1.6, -3.0), "target": Lay.EXIT + Vector3(2, 1.2, 0),
		"prepare": func(): world.build_around(Lay.EXIT, 1)})
	return plan
