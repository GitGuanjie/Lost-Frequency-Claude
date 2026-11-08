extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Level 11 — "The City That Never Sleeps" (Backrooms Wikidot rev 60, accessed
## 2026-11-04; cite: Greggita Mahayfaio, inspired by the original Level 11 by
## nerdykiddo4884, CC BY-SA 3.0). Dossier: docs/canon/levels/L011.md.
## Streamed empty metropolis: 80 m chunks = one block + two street corridors.
## SOURCE: block grid with alleys, plazas, parking and parks; density changes
## gradually from three-storey lots and suburban houses to skyscraper blocks;
## bland, repetitive buildings, one in three sealed behind black-mirror windows;
## open ground floors with sparse furnishing and working lights; canals that
## follow the road grid under bridges; fluid streets (cars move between kerb and
## car park, ads change or fade, roadworks appear) only while unobserved;
## residents' barricades, spray-painted trails and memorials around exit-dense
## streets; exits as building types and odd objects. ADAPTATION: night (time
## of day is not stated); a far skyline LOD; one authored exit street.
## Helpers: L011_city.gd (geometry), L011_mats.gd (materials/shaders).

const C := preload("res://levels/L011/L011_city.gd")
const M := preload("res://levels/L011/L011_mats.gd")
const CS := 80.0
const W := 20.0
const LY := 0.15
const CANAL_Z := 1
const WEST := Vector2i(0, -1)
const EAST := Vector2i(1, -1)
const START := Vector3(110.0, 0.2, 18.0)
const CAB := Vector3(90.0, 0.0, -40.0)
const SLOGANS := ["OPEN ALL NIGHT", "NOW LEASING", "FRESH COFFEE", "SALE SALE SALE", "CALL NOW", "NOW HIRING"]
const CAR_COLS := [Color(0.8, 0.8, 0.78), Color(0.55, 0.56, 0.58), Color(0.06, 0.06, 0.07), Color(0.08, 0.12, 0.26), Color(0.5, 0.06, 0.05), Color(0.6, 0.55, 0.45), Color(0.1, 0.25, 0.15)]

var world: ChunkWorld
var far: ChunkWorld
var qa_fixture := false
var car_mesh: Array = []
var fr_rng := RandomNumberGenerator.new()
var tick := 0.0
var notice_cd := 0.0
var water_bed: AudioStreamPlayer
var said := {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 1500.0
	rules["reverb_room"] = 0.35
	rules["reverb_wet"] = 0.08
	outdoor_env(Color(0.012, 0.016, 0.035), Color(0.13, 0.11, 0.13), Color(0.02, 0.02, 0.022), Vector2(40.0, 210.0), Color(0.55, 0.62, 0.8), 0.12, Color(0.12, 0.11, 0.13), 0.0028)
	environment.ambient_light_energy = 0.55
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.6
	environment.glow_hdr_threshold = 0.85
	environment.ssr_enabled = Settings.quality() >= 2
	sun.directional_shadow_max_distance = 160.0
	M.define_all()
	_car_setup()
	lights.setup(14, 1)
	lights.max_distance = 90.0
	fr_rng.seed = level_seed ^ 0x5bd1
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	far = ChunkWorld.new()
	far.name = "Skyline"
	far.chunk_size = CS * 3.0
	far.radius = 3
	far.unload_radius = 4
	far.builder = _build_far
	add_child(far)
	add_arrival("start", START, -90.0)
	add_arrival("from_L009", Vector3(-290.0, 0.05, 10.0), -90.0)
	add_arrival("from_L025", CAB + Vector3(0.0, 0.05, 4.5), 0.0)
	var at: Transform3D = arrivals.get(TransitionService.pending_arrival, arrivals["start"])
	if at.origin.distance_to(START) < 200.0:
		world.build_around(Vector3(EAST.x * CS + 40.0, 0, EAST.y * CS + 40.0), 0)
	world.build_around(at.origin, 2)
	far.build_around(at.origin, 3)
	_sounds()
	add_shot("avenue", START + Vector3(0, 1.62, 0), Vector3(420.0, 45.0, 6.0), {"flashlight": false})
	add_landmark("Spawn sidewalk (skyline east, barricade south-west)", START)
	add_shot("overpass", Vector3(198.0, 5.4, 59.0), Vector3(210.0, 1.8, 57.0))


func _car_setup() -> void:
	var a := StandardMaterial3D.new()
	a.vertex_color_use_as_albedo = true
	a.metallic = 0.5
	a.roughness = 0.32
	MatLib.register("l11_car_a", a)
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.03, 0.035, 0.045)
	g.metallic = 0.6
	g.roughness = 0.08
	MatLib.register("l11_car_b", g)
	var d := StandardMaterial3D.new()
	d.albedo_color = Color(0.035, 0.035, 0.04)
	d.roughness = 0.85
	MatLib.register("l11_car_c", d)
	var tmp := Node3D.new()
	var ck := GeoKit.new(tmp, "Car")
	ck.box(Vector3(0, 0.66, 0), Vector3(4.4, 0.68, 1.8), "l11_car_a", GeoKit.ALL, false)
	ck.box(Vector3(-0.1, 1.27, 0), Vector3(2.1, 0.55, 1.62), "l11_car_a", GeoKit.ALL, false)
	ck.box(Vector3(-0.1, 1.26, 0), Vector3(1.9, 0.42, 1.64), "l11_car_b", GeoKit.ALL, false)
	ck.box(Vector3(0.96, 1.26, 0), Vector3(0.1, 0.42, 1.5), "l11_car_b", GeoKit.ALL, false)
	ck.box(Vector3(-1.16, 1.26, 0), Vector3(0.1, 0.42, 1.5), "l11_car_b", GeoKit.ALL, false)
	for sx in [-1.35, 1.35]:
		for sz in [-0.78, 0.78]:
			ck.box(Vector3(sx, 0.34, sz), Vector3(0.7, 0.68, 0.3), "l11_car_c", GeoKit.ALL, false)
	for sx in [-2.22, 2.22]:
		ck.box(Vector3(sx, 0.5, 0), Vector3(0.1, 0.25, 1.82), "l11_car_c", GeoKit.ALL, false)
	ck.commit()
	for n in ["l11_car_a", "l11_car_b", "l11_car_c"]:
		car_mesh.append((ck.root.get_node("Mesh_" + n) as MeshInstance3D).mesh)
	tmp.free()


# ------------------------------------------------------------- planning

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func _vn(x: float, z: float) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	return lerpf(lerpf(_h01(ix, iz, 7), _h01(ix + 1, iz, 7), fx), lerpf(_h01(ix, iz + 1, 7), _h01(ix + 1, iz + 1, 7), fx), fz)


## Density: suburban lots to the west, skyscraper blocks to the east, with a
## noise field so transitions stay gradual (SOURCE) but never uniform.
func density(cx: int, cz: int) -> float:
	if Vector2i(cx, cz) in [WEST, EAST]:
		return 0.55
	return clampf(0.5 + 0.36 * tanh(cx * 0.25) + (_vn(cx * 0.31 + 0.5, cz * 0.31 + 0.5) - 0.5) * 0.6, 0.0, 1.0)


func kind_of(cx: int, cz: int) -> String:
	# Authored overpass park one block from the eastern start area.
	if cx == 2 and cz == 0:
		return "park"
	var d := density(cx, cz)
	if maxi(absi(cx), absi(cz)) >= 2 and _h01(cx, cz, 61) > 0.9 and d < 0.8:
		return "park"
	if d >= 0.72:
		return "tower"
	if d >= 0.45:
		return "mid"
	if d >= 0.25:
		return "low"
	return "sub"


func _bd(r: RandomNumberGenerator, rc: Rect2, h: float, kind: String, front: int, facs: Array, shops: Array) -> Dictionary:
	var sealed := r.randf() < 0.333
	var shop := "" if sealed or shops.is_empty() else str(shops[r.randi() % shops.size()])
	return {"r": rc, "h": h, "kind": kind, "front": front, "fac": "l11_fac_mirror" if sealed else str(facs[r.randi() % facs.size()]),
		"sealed": sealed, "shop": shop, "pod": 0.0, "ins": 0.0, "spire": false}


## Deterministic building plan of a chunk (used by both the near and far LOD).
func plan(cx: int, cz: int) -> Array:
	var kd := kind_of(cx, cz)
	var out: Array = []
	if kd == "park":
		return out
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, 3])
	var b0 := Vector2(cx * CS + W, cz * CS + W)
	var d := density(cx, cz)
	match kd:
		"tower":
			var sp := r.randi() % 3
			var lots: Array = [Rect2(b0, Vector2(60, 60))]
			if sp == 1:
				lots = [Rect2(b0, Vector2(60, 30)), Rect2(b0 + Vector2(0, 30), Vector2(60, 30))]
			elif sp == 2:
				lots = [Rect2(b0, Vector2(30, 30)), Rect2(b0 + Vector2(30, 0), Vector2(30, 30)), Rect2(b0 + Vector2(0, 30), Vector2(30, 30)), Rect2(b0 + Vector2(30, 30), Vector2(30, 30))]
			var pz := (r.randi() % lots.size()) if lots.size() > 1 and r.randf() < 0.35 else -1
			for i in lots.size():
				var lot: Rect2 = lots[i]
				if i == pz:
					out.append({"kind": "plaza", "r": lot, "h": 0.0})
					continue
				var b := _bd(r, lot.grow(-r.randf_range(0.0, 2.0)), r.randf_range(45.0, 70.0) + d * r.randf_range(40.0, 125.0), "tower",
					0 if lot.position.y < b0.y + 1.0 else 2, ["l11_fac_office", "l11_fac_office", "l11_fac_stone", "l11_fac_concrete"], ["lobby", "lobby", "store"])
				b["pod"] = r.randf_range(9.0, 16.0)
				b["ins"] = r.randf_range(2.0, 4.5)
				b["spire"] = r.randf() < 0.3
				out.append(b)
		"mid":
			var dd := 15.0 if Vector2i(cx, cz) in [WEST, EAST] else r.randf_range(13.0, 17.0)
			var strips := [[Rect2(b0, Vector2(60, dd)), 0], [Rect2(b0 + Vector2(0, 60 - dd), Vector2(60, dd)), 2],
				[Rect2(b0 + Vector2(0, dd), Vector2(dd, 60 - 2 * dd)), 3], [Rect2(b0 + Vector2(60 - dd, dd), Vector2(dd, 60 - 2 * dd)), 1]]
			for s in strips:
				var rc: Rect2 = s[0]
				var f: int = s[1]
				var ax := f % 2 == 0
				var ln := rc.size.x if ax else rc.size.y
				var pos := 0.0
				while pos < ln - 0.5:
					var w := minf(r.randf_range(11.0, 22.0), ln - pos)
					if ln - pos - w < 8.0:
						w = ln - pos
					var seg := Rect2(rc.position + Vector2(pos, 0), Vector2(w, rc.size.y)) if ax else Rect2(rc.position + Vector2(0, pos), Vector2(rc.size.x, w))
					out.append(_bd(r, seg, r.randf_range(12.0, 18.0) + d * r.randf_range(8.0, 42.0), "mid", f,
						["l11_fac_apts", "l11_fac_brick", "l11_fac_stone", "l11_fac_concrete"], ["store", "store", "laundromat", "office", "lobby"]))
					pos += w
					if ax and pos < ln - 12.0 and r.randf() < 0.3:
						pos += 4.0
			if Vector2i(cx, cz) == WEST:
				for b in out:
					if (b["r"] as Rect2).end.x > b0.x + 59.0:
						b.merge({"sealed": true, "fac": "l11_fac_concrete", "shop": ""}, true)
			elif Vector2i(cx, cz) == EAST:
				out = out.filter(func(b): return int(b["front"]) != 3)
				out.append({"r": Rect2(b0 + Vector2(0, 15), Vector2(15, 9)), "h": 16.0, "kind": "mid", "front": 3, "fac": "l11_fac_brick", "sealed": false, "shop": "store", "pod": 0.0, "ins": 0.0, "spire": false})
				out.append({"r": Rect2(b0 + Vector2(0, 24), Vector2(15, 21)), "h": 13.0, "kind": "mid", "front": 3, "fac": "l11_fac_brick", "sealed": false, "shop": "arcade", "pod": 0.0, "ins": 0.0, "spire": false})
		"low":
			if r.randf() < 0.5:
				var x := b0.x + 3.0
				while x < b0.x + 56.0:
					var w := minf(r.randf_range(9.0, 14.0), b0.x + 57.0 - x)
					out.append(_bd(r, Rect2(x, b0.y + 45.0, w, 15.0), 5.2, "low", 0, ["l11_fac_brick", "l11_fac_concrete"], ["store", "laundromat", "office"]))
					x += w
				out.append({"kind": "parking", "r": Rect2(b0 + Vector2(4, 5), Vector2(52, 34)), "h": 0.0})
			else:
				var x := b0.x
				while x < b0.x + 59.0:
					var w := minf(r.randf_range(10.0, 16.0), b0.x + 60.0 - x)
					out.append(_bd(r, Rect2(x, b0.y, w, 16.0), r.randf_range(7.0, 12.0), "low", 0, ["l11_fac_brick", "l11_fac_stone", "l11_fac_concrete"], ["store", "laundromat"]))
					x += w
				out.append({"kind": "parking", "r": Rect2(b0 + Vector2(4, 22), Vector2(52, 34)), "h": 0.0})
		"sub":
			for row in 2:
				for i in 3:
					var w := r.randf_range(9.0, 12.0)
					var dpt := r.randf_range(8.0, 10.0)
					var lx := b0.x + i * 20.0 + (20.0 - w) * 0.5
					var z := b0.y + 6.0 if row == 0 else b0.y + 54.0 - dpt
					var b := _bd(r, Rect2(lx, z, w, dpt), 6.2 if r.randf() < 0.6 else 3.6, "house", 0 if row == 0 else 2, ["l11_fac_house"], [])
					if not b["sealed"]:
						b["fac"] = "l11_fac_house"
					out.append(b)
	return out


# --------------------------------------------------------------- chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var kd := kind_of(cx, cz)
	var key := Vector2i(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, 9])
	var k := GeoKit.new(node, "K")
	var cb := C.new(k, r)
	var ox := cx * CS
	var oz := cz * CS
	var grp := "%d,%d" % [cx, cz]
	var meta := {"kind": kd, "ads": [], "rw": [], "cars": {}}
	var slots: Array = []
	var lamps: Array = []
	if key == EAST:
		_exit_east(cb, node, grp)
	k.slab(ox + W, oz + W, ox + CS, oz + CS, LY, 0.45, "l11_grass" if kd in ["park", "sub"] else "l11_sidewalk", GeoKit.PY)
	_streets(cb, k, cx, cz, r, slots, lamps, meta, node)
	var far_out := maxi(absi(cx - 1), absi(cz)) >= 4
	for b in plan(cx, cz):
		match str(b["kind"]):
			"parking":
				_parking(k, b["r"], slots)
			"plaza":
				_plaza(cb, k, b["r"], node, far_out and r.randf() < 0.3)
			_:
				if far_out and b["shop"] == "store" and r.randf() < 0.05:
					b["shop"] = "arcade"
				for p in cb.building(b):
					lamps.append([p, Color(1.0, 0.92, 0.78), 1.5, 11.0])
				_extras(cb, k, b, r, node, meta, far_out)
	if kd == "park":
		_park(cb, k, ox, oz, node, far_out)
		if key == Vector2i(2, 0):
			_elevated_walkway(k, node, ox, oz, grp)
	if key == WEST:
		_exit_west(cb, node)
	elif key == Vector2i(1, 0):
		_supplies(k, cb)
	for l in lamps:
		lights.add_anchor(l[0], l[1], l[2], l[3], 0.0, grp)
	meta["cars"] = _cars(node, slots, r)
	k.commit()
	ModelDress.decorate_chunk(self, node, "L011", cx, cz)
	return meta


func _streets(cb, k: GeoKit, cx: int, cz: int, r: RandomNumberGenerator, slots: Array, lamps: Array, meta: Dictionary, node: Node3D) -> void:
	var ox := cx * CS
	var oz := cz * CS
	var canal := cz == CANAL_Z
	var PY := GeoKit.PY
	var SR := GeoKit.PY | GeoKit.SIDES
	if canal:
		for zz in [[oz, oz + 3.5], [oz + 16.5, oz + 20.0]]:
			k.slab(ox + 4, zz[0], ox + 16, zz[1], 0.0, 0.3, "l11_asphalt", PY)
			k.slab(ox, zz[0], ox + 4, zz[1], LY, 0.45, "l11_sidewalk", SR)
			k.slab(ox + 16, zz[0], ox + 20, zz[1], LY, 0.45, "l11_sidewalk", SR)
		var cl: Array = []
		cb.canal(ox, ox + CS, oz, cl)
		for p in cl:
			lamps.append([p, Color(1.0, 0.85, 0.6), 1.8, 12.0])
	else:
		k.slab(ox + 4, oz, ox + 16, oz + 20, 0.0, 0.3, "l11_asphalt", PY)
		k.slab(ox, oz + 4, ox + 4, oz + 16, 0.0, 0.3, "l11_asphalt", PY)
		k.slab(ox + 16, oz + 4, ox + 20, oz + 16, 0.0, 0.3, "l11_asphalt", PY)
		for c in [Vector2(0, 0), Vector2(16, 0), Vector2(0, 16), Vector2(16, 16)]:
			k.slab(ox + c.x, oz + c.y, ox + c.x + 4, oz + c.y + 4, LY, 0.45, "l11_sidewalk", SR)
		for i in 7:
			var s := 4.6 + i * 1.6
			k.box(Vector3(ox + s, 0.005, oz + 2.0), Vector3(0.7, 0.01, 3.0), "l11_paint_white", PY, false)
			k.box(Vector3(ox + s, 0.005, oz + 18.0), Vector3(0.7, 0.01, 3.0), "l11_paint_white", PY, false)
			k.box(Vector3(ox + 2.0, 0.005, oz + s), Vector3(3.0, 0.01, 0.7), "l11_paint_white", PY, false)
			k.box(Vector3(ox + 18.0, 0.005, oz + s), Vector3(3.0, 0.01, 0.7), "l11_paint_white", PY, false)
		cb.signal_mast(Vector3(ox + 16.6, LY, oz + 16.6))
		cb.signal_mast(Vector3(ox + 3.4, LY, oz + 3.4))
	if not canal:
		_corridor(cb, k, r, Vector3(ox + W, 0, oz), true, slots, lamps, meta, node, cx, cz)
	_corridor(cb, k, r, Vector3(ox, 0, oz + W), false, slots, lamps, meta, node, cx, cz)


func _corridor(cb, k: GeoKit, r: RandomNumberGenerator, a: Vector3, ax: bool, slots: Array, lamps: Array, meta: Dictionary, node: Node3D, cx: int, cz: int) -> void:
	var ln := CS - W
	var P := func(s: float, t: float, y: float) -> Vector3: return Vector3(a.x + s, y, a.z + t) if ax else Vector3(a.x + t, y, a.z + s)
	var SR := GeoKit.PY | GeoKit.SIDES
	for b in [[0.0, 4.0, true], [4.0, 16.0, false], [16.0, 20.0, true]]:
		var p0: Vector3 = P.call(0.0, b[0], 0.0)
		var p1: Vector3 = P.call(ln, b[1], 0.0)
		if b[2]:
			k.slab(p0.x, p0.z, p1.x, p1.z, LY, 0.45, "l11_sidewalk", SR)
		else:
			k.slab(p0.x, p0.z, p1.x, p1.z, 0.0, 0.3, "l11_asphalt", GeoKit.PY)
	var lane := Vector3(ln, 0.01, 0.12) if ax else Vector3(0.12, 0.01, ln)
	for t in [9.85, 10.15]:
		k.box(P.call(ln * 0.5, t, 0.005), lane, "l11_paint_yellow", GeoKit.PY, false)
	for t in [6.5, 13.5]:
		for i in 8:
			k.box(P.call(3.0 + i * 7.5, t, 0.005), Vector3(3.0, 0.01, 0.1) if ax else Vector3(0.1, 0.01, 3.0), "l11_paint_white", GeoKit.PY, false)
	var exit_st := not ax and Vector2i(cx, cz) == EAST
	var led := density(cx, cz) > 0.6
	for lp in [[12.0, 3.4, 1.0], [38.0, 3.4, 1.0], [25.0, 16.6, -1.0], [51.0, 16.6, -1.0]]:
		var out := (Vector3(0, 0, 1) if ax else Vector3(1, 0, 0)) * float(lp[2])
		var tip: Vector3 = cb.street_light(P.call(lp[0], lp[1], LY), out, led)
		lamps.append([tip, Color(0.85, 0.92, 1.0) if led else Color(1.0, 0.8, 0.55), 2.6, 19.0])
	if exit_st:
		return
	var yaw := 0.0 if ax else PI * 0.5
	for t in [5.25, 14.75]:
		for i in 7:
			var s := 7.0 + i * 7.0
			slots.append({"xf": Transform3D(Basis(Vector3.UP, yaw + (PI if r.randf() < 0.5 else 0.0)), P.call(s, t, 0.0)), "p": 0.2})
	for s in [18.0, 44.0]:
		for t in [1.6, 18.4]:
			if r.randf() < 0.4:
				cb.tree(P.call(s, t, LY), 1.0)
	if r.randf() < 0.5:
		k.cylinder(P.call(30.0, 3.3, LY + 0.35), 0.16, 0.7, "l11_cabinet_red", 8, true, true)
	if r.randf() < 0.2:
		cb.bench(P.call(31.0, 18.9, LY), 0.0 if ax else -PI * 0.5)
	if r.randf() < 0.25:
		var pc: Vector3 = P.call(5.0, 18.6, LY)
		k.cylinder(pc + Vector3(0, 1.6, 0), 0.62, 3.2, "l11_dark", 10, true, true)
		var e := _ad(node, pc + Vector3(0, 1.7, 0), 0.0, Vector2.ZERO, r.randi() % 7, true)
		meta["ads"].append(e)
	if r.randf() < 0.35:
		var site := Node3D.new()
		node.add_child(site)
		var rk := GeoKit.new(site, "RW")
		var c0: Vector3 = P.call(r.randf_range(12.0, 40.0), 8.2, 0.0)
		var al := Vector3(1, 0, 0) if ax else Vector3(0, 0, 1)
		for i in 3:
			rk.box(c0 + al * (i * 2.3) + Vector3(0, 0.5, 0), Vector3(2.0, 1.0, 0.25) if ax else Vector3(0.25, 1.0, 2.0), "l11_barrier")
		for i in 5:
			rk.box(c0 + al * (i * 1.4 - 1.5) + (Vector3(0, 0, 1.2) if ax else Vector3(1.2, 0, 0)) + Vector3(0, 0.35, 0), Vector3(0.32, 0.7, 0.32), "l11_cone")
		rk.commit()
		var e := {"node": site, "body": rk.body, "on": r.randf() < 0.5, "pos": c0, "t": 0.0}
		_rw_state(e)
		meta["rw"].append(e)


func _parking(k: GeoKit, rc: Rect2, slots: Array) -> void:
	k.box_mm(Vector3(rc.position.x, LY, rc.position.y), Vector3(rc.end.x, LY + 0.01, rc.end.y), "l11_asphalt", GeoKit.PY, false)
	var rows := [rc.position.y + 3.0, rc.end.y - 3.0]
	for z in rows:
		var n := int(rc.size.x / 2.8)
		for i in n:
			var x := rc.position.x + 1.4 + i * 2.8
			k.box(Vector3(x - 1.4, LY + 0.012, z), Vector3(0.1, 0.01, 5.0), "l11_paint_white", GeoKit.PY, false)
			slots.append({"xf": Transform3D(Basis(Vector3.UP, PI * 0.5 if z < rc.get_center().y else -PI * 0.5), Vector3(x, LY, z)), "p": 0.4})


func _plaza(cb, k: GeoKit, rc: Rect2, node: Node3D, cabinet: bool) -> void:
	k.box_mm(Vector3(rc.position.x, LY, rc.position.y), Vector3(rc.end.x, LY + 0.02, rc.end.y), "l11_plaza", GeoKit.PY, false)
	var c := Vector3(rc.get_center().x, LY, rc.get_center().y)
	k.cylinder(c + Vector3(0, 0.3, 0), 4.0, 0.6, "l11_canal_wall", 16, true, true)
	for p in [Vector3(-9, 0, -9), Vector3(9, 0, -9), Vector3(-9, 0, 9), Vector3(9, 0, 9)]:
		k.box(c + p + Vector3(0, 0.4, 0), Vector3(2.4, 0.8, 2.4), "l11_canal_wall")
		cb.tree(c + p + Vector3(0, 0.8, 0), 0.9)
	if cabinet:
		_odd_cabinet(cb, c + Vector3(6.0, 0, 0), node)


func _park(cb, k: GeoKit, ox: float, oz: float, node: Node3D, cabinet: bool) -> void:
	var c := Vector3(ox + 50.0, LY, oz + 50.0)
	k.box_mm(Vector3(ox + W, LY, c.z - 1.5), Vector3(ox + CS, LY + 0.02, c.z + 1.5), "l11_plaza", GeoKit.PY, false)
	k.box_mm(Vector3(c.x - 1.5, LY, oz + W), Vector3(c.x + 1.5, LY + 0.02, oz + CS), "l11_plaza", GeoKit.PY, false)
	for i in 14:
		var p := Vector3(ox + W + 4.0 + fmod(i * 37.0, 52.0), LY, oz + W + 4.0 + fmod(i * 23.0 + 11.0, 52.0))
		if absf(p.x - c.x) > 3.5 and absf(p.z - c.z) > 3.5:
			# Keep the raised route and BOTH stair approaches clear of trees.
			if Vector2i(floori(ox / CS), floori(oz / CS)) != Vector2i(2, 0) or absf(p.z - (c.z + 10.0)) > 5.0:
				cb.tree(p, 1.3)
	for i in 4:
		cb.bench(c + Vector3([-8, 8, 0, 0][i], 0, [0, 0, -8, 8][i]) * 1.0 + Vector3([0, 0, 2.6, -2.6][i], 0, [2.6, -2.6, 0, 0][i]), [0.0, PI, PI * 0.5, -PI * 0.5][i])
	if cabinet:
		_odd_cabinet(cb, c + Vector3(-14.0, 0, 9.0), node)


## Walkable elevated observation bridge over the civic park. Stair collision
## follows the same continuous-ramp method used elsewhere in the game. Its
## elevated deck stays well within the park parcel (not on streamed borders).
func _elevated_walkway(k: GeoKit, node: Node3D, ox: float, oz: float, group: String) -> void:
	var mid := Vector3(ox + 50.0, LY, oz + 60.0)
	var rise := 3.6
	var steps := 18
	var run := 0.45
	var upper_y := LY + rise
	var left := mid + Vector3(-20.0, 0, 0)
	var right := mid + Vector3(20.0, 0, 0)
	k.stairs(left, Vector3.RIGHT, 3.2, rise, steps, "l11_canal_wall", run)
	k.stairs(right, Vector3.LEFT, 3.2, rise, steps, "l11_canal_wall", run)
	k.slab(mid.x - 12.0, mid.z - 1.7, mid.x + 12.0, mid.z + 1.7, upper_y, 0.24, "l11_plaza")
	for side in [-1.0, 1.0]:
		var rz := mid.z + side * 1.78
		# The northern railing has a 3.2m opening for the NEW upper stair.
		if side < 0.0:
			for offset in [-6.8, 6.8]:
				k.box(Vector3(mid.x + offset, upper_y + 0.72, rz), Vector3(10.4, 1.44, 0.11), "l11_rail_metal")
		else:
			k.box(Vector3(mid.x, upper_y + 0.72, rz), Vector3(24.0, 1.44, 0.11), "l11_rail_metal")
		for i in 9:
			var x := mid.x - 11.5 + i * 2.875
			if side < 0.0 and absf(x - mid.x) < 1.6:
				continue
			k.box(Vector3(x, upper_y + 0.75, rz), Vector3(0.12, 1.5, 0.18), "l11_rail_metal", GeoKit.ALL, false)
	_skywalk_upper(k, node, mid, upper_y, group)
	for side in [-1.0, 1.0]:
		var p := mid + Vector3(side * 17.0, upper_y * 0.5, 0)
		lights.add_anchor(p, Color(0.75, 0.82, 1.0), 1.0, 8.0, 0.0, group)
	var sign := Interactable.new()
	node.add_child(sign)
	sign.setup(Vector3(mid.x, upper_y + 1.1, mid.z), Vector3(1.4, 2.0, 1.4), "Read the overpass notice", func(_p):
		SaveService.set_flag(stable_id, "overpass_seen", true)
		Overlay.toast("Civic pedestrian bridge. There are no train routes on the diagram, only roads with the names scratched out.", 4.5))
	add_landmark("Overpass park (upper observation walkway)", Vector3(mid.x, upper_y, mid.z))


## DEV12: the second elevation is accessed from the original overpass, NOT from
## a debug teleport. It creates a three-level (street / bridge / roofwalk) park.
## The upper route returns to the original bridge via the same physical stairs.
func _skywalk_upper(k: GeoKit, node: Node3D, mid: Vector3, base_y: float, group: String) -> void:
	var upper := base_y + 3.5
	var rise_steps := 20
	var run := 0.40
	# From the centre of the existing bridge through its 3.2m northern gap.
	k.stairs(Vector3(mid.x, base_y, mid.z), Vector3.FORWARD, 2.0, 3.5, rise_steps, "l11_canal_wall", run)
	var z := mid.z - rise_steps * run
	# A cross-bridge and two distinct balcony wings with an open central void.
	k.slab(mid.x - 11.0, z - 1.5, mid.x + 11.0, z + 1.5, upper, 0.25, "l11_plaza")
	k.slab(mid.x - 10.8, z - 11.0, mid.x - 7.6, z + 1.5, upper, 0.25, "l11_plaza")
	k.slab(mid.x + 7.6, z - 11.0, mid.x + 10.8, z + 1.5, upper, 0.25, "l11_plaza")
	k.slab(mid.x - 11.0, z - 11.0, mid.x + 11.0, z - 8.0, upper, 0.25, "l11_plaza")
	# Perimeter barriers, with an intentional open stair threshold on south edge.
	for rail in [
		[Vector3(mid.x - 11.1, upper + 0.7, z - 4.8), Vector3(0.12, 1.4, 12.3)],
		[Vector3(mid.x + 11.1, upper + 0.7, z - 4.8), Vector3(0.12, 1.4, 12.3)],
		[Vector3(mid.x, upper + 0.7, z - 11.1), Vector3(22.0, 1.4, 0.12)],
		[Vector3(mid.x - 6.7, upper + 0.7, z + 1.63), Vector3(8.6, 1.4, 0.12)],
		[Vector3(mid.x + 6.7, upper + 0.7, z + 1.63), Vector3(8.6, 1.4, 0.12)],
		[Vector3(mid.x, upper + 0.7, z - 7.91), Vector3(15.0, 1.4, 0.12)],
		[Vector3(mid.x - 7.48, upper + 0.7, z - 5.7), Vector3(0.12, 1.4, 4.0)],
		[Vector3(mid.x + 7.48, upper + 0.7, z - 5.7), Vector3(0.12, 1.4, 4.0)]
	]:
		k.box(rail[0], rail[1], "l11_rail_metal")
	for x in [mid.x - 10.0, mid.x + 10.0]:
		for zz in [z - 10.0, z - 1.0]:
			k.box(Vector3(x, (LY + upper) * 0.5, zz), Vector3(0.28, upper - LY, 0.28), "l11_canal_wall", GeoKit.ALL, false)
	var sign := Interactable.new()
	node.add_child(sign)
	sign.setup(Vector3(mid.x, upper + 1.0, z - 9.3), Vector3(1.6, 1.8, 1.6), "Inspect the high observation map", func(_p):
		SaveService.set_flag(stable_id, "skywalk_seen", true)
		Overlay.toast("This walkway overlooks three streets that do not meet on the map. The upper route ends above the same park.", 4.5))
	lights.add_anchor(Vector3(mid.x, upper + 2.2, z - 9.5), Color(0.67, 0.78, 1.0), 0.7, 10.0, 0.0, group)
	add_landmark("High park observation loop (third elevation)", Vector3(mid.x, upper, z - 9.0))
	add_shot("skywalk_upper", Vector3(mid.x + 8.4, upper + 1.65, z - 8.0), Vector3(mid.x, 0.6, mid.z))
	_skywalk_fourth(k, node, mid, upper, group)



## DEV14: two truly independent flights to a fourth elevation (one can be
## descended while the other is climbed). A bridging spine connects the stair
## heads, rather than a roof panel merely decorating the existing overpass.
func _skywalk_fourth(k: GeoKit, node: Node3D, mid: Vector3, base_y: float, group: String) -> void:
	var upper := base_y + 3.4
	var z := mid.z - 8.0
	# Existing third-storey bridge has two long side wings centred at x=+/-9.
	# Ascents point north; the deck starts exactly beyond their final riser.
	for side in [-1.0, 1.0]:
		k.stairs(Vector3(mid.x + side * 9.0, base_y, z - 0.8), Vector3.FORWARD,
			2.1, upper - base_y, 18, "l11_canal_wall", 0.40, false)
	# Opposite wings meet on the far side of the open air atrium.
	k.slab(mid.x - 11.0, z - 14.5, mid.x + 11.0, z - 11.8,
		upper, 0.25, "l11_plaza")
	for side in [-1.0, 1.0]:
		var xc := mid.x + side * 9.0
		k.slab(xc - 1.65, z - 11.8, xc + 1.65, z - 7.9,
			upper, 0.25, "l11_plaza")
		# Outer and inner rails frame a shaft; don't block the stair mouths.
		for xx in [xc - 1.72, xc + 1.72]:
			k.box(Vector3(xx, upper + 0.65, z - 9.8),
				Vector3(0.12, 1.30, 3.80), "l11_rail_metal")
	for zz in [z - 14.6, z - 11.72]:
		k.box(Vector3(mid.x, upper + 0.65, zz), Vector3(15.0 if zz > z - 14.0 else 22.0, 1.30, 0.12), "l11_rail_metal")
	for xx in [mid.x - 11.10, mid.x + 11.10]:
		k.box(Vector3(xx, upper + 0.65, z - 13.25), Vector3(0.12, 1.30, 2.7), "l11_rail_metal")
	var map := Interactable.new()
	node.add_child(map)
	map.setup(Vector3(mid.x, upper + 0.95, z - 13.1), Vector3(1.25, 1.0, 0.75),
		"Inspect the fourth-level city index", func(_p):
			Overlay.toast("The same avenue runs beneath both staircases, yet neither points to its original intersection.", 5.0))
	lights.add_anchor(Vector3(mid.x, upper + 2.1, z - 13.1), Color(0.65, 0.76, 0.95), 0.75, 10.0, 0.0, group)
	add_landmark("Fourth-elevation double stairway", Vector3(mid.x, upper, z - 13.0))
	add_shot("skywalk_fourth", Vector3(mid.x - 8.9, upper + 1.6, z - 12.4), Vector3(mid.x + 9.0, base_y, z))


func _odd_cabinet(cb, p: Vector3, node: Node3D) -> void:
	cb.cabinet(p, PI, "l11_cabinet_blue")
	make_exit("L011>L025#39", "interact", p + Vector3(0, 1.0, -0.9), Vector3(1.6, 2.0, 1.4), "Play the arcade machine", node)


## Per-building extras: rooftop billboards, out-of-place exits far from spawn.
func _extras(cb, k: GeoKit, b: Dictionary, r: RandomNumberGenerator, node: Node3D, meta: Dictionary, far_out: bool) -> void:
	var fr: Array = C.face(b["r"], b["front"])
	var h: float = b["h"]
	var mid: Vector3 = fr[0] + fr[1] * (float(fr[3]) * 0.5)
	if b["kind"] in ["mid", "low"] and h < 26.0 and float(fr[3]) > 12.0 and r.randf() < 0.3:
		var c: Vector3 = mid - fr[2] * 3.0 + Vector3(0, h + 3.4, 0)
		for sx in [-2.5, 2.5]:
			cb.stick(c + fr[1] * sx - Vector3(0, 3.4, 0), c + fr[1] * sx - Vector3(0, 1.6, 0), 0.2, "l11_rail_metal")
		meta["ads"].append(_ad(node, c, atan2(fr[2].x, fr[2].z), Vector2(8.0, 3.4), r.randi() % 7, false))
	if not far_out:
		return
	if b["shop"] == "arcade":
		var dc := float(fr[3]) * 0.3
		make_exit("L011>L808#13", "walk_in", fr[0] + fr[1] * dc - fr[2] * 1.4 + Vector3(0, 1.4, 0), Vector3(1.8, 2.4, 1.8), "", node)
		var lb := Label3D.new()
		lb.text = "ARCADE"
		lb.font_size = 80
		lb.pixel_size = 0.012
		lb.outline_size = 0
		lb.shaded = false
		lb.modulate = Color(1.0, 0.35, 0.8)
		lb.transform = Transform3D(Basis(Vector3.UP, atan2(fr[2].x, fr[2].z)), fr[0] + fr[1] * (float(fr[3]) * 0.5) + fr[2] * 0.2 + Vector3(0, 3.85, 0))
		node.add_child(lb)
	elif b["sealed"] and b["kind"] in ["mid", "tower"] and r.randf() < 0.05:
		var c2: Vector3 = mid + fr[1] * 4.0 + Vector3(0, LY, 0)
		cb.elevator(c2, fr[1], fr[2])
		make_exit("L011>L998#44", "interact", c2 + fr[2] * 0.9 + Vector3(0, 1.2, 0), Vector3(1.6, 2.4, 1.6) + (fr[1] as Vector3).abs() * 2.0, "Press the call button", node)


func _ad(node: Node3D, c: Vector3, yaw: float, size: Vector2, st: int, pillar: bool) -> Dictionary:
	var mi := MeshInstance3D.new()
	if pillar:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.66
		cm.bottom_radius = 0.66
		cm.height = 2.4
		mi.mesh = cm
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, size.y, 0.12)
		mi.mesh = bm
	mi.transform = Transform3D(Basis(Vector3.UP, yaw), c)
	node.add_child(mi)
	var lb := Label3D.new()
	lb.font_size = 64
	lb.pixel_size = 0.011
	lb.outline_size = 10
	lb.shaded = false
	lb.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lb.transform = Transform3D(Basis(Vector3.UP, yaw), c + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.67 if pillar else 0.07))
	if pillar:
		lb.font_size = 26
	node.add_child(lb)
	var e := {"mi": mi, "lb": lb, "st": st, "pos": c, "t": 0.0}
	_ad_state(e)
	return e


func _ad_state(e: Dictionary) -> void:
	var st: int = e["st"]
	(e["mi"] as MeshInstance3D).material_override = MatLib.get_mat("l11_ad_faded" if st >= 6 else "l11_ad_%d" % st)
	(e["lb"] as Label3D).text = "" if st >= 6 else SLOGANS[st]


func _rw_state(e: Dictionary) -> void:
	(e["node"] as Node3D).visible = e["on"]
	(e["body"] as StaticBody3D).collision_layer = 1 if e["on"] else 0


## Parked cars as three MultiMeshes per chunk (no fuel in any of them; SOURCE).
func _cars(node: Node3D, slots: Array, r: RandomNumberGenerator) -> Dictionary:
	var occ: Array = []
	var cols: Array = []
	for i in slots.size():
		if r.randf() < float(slots[i]["p"]):
			occ.append(i)
			cols.append(CAR_COLS[r.randi() % CAR_COLS.size()])
	var mms: Array = []
	for j in 3:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = j == 0
		mm.mesh = car_mesh[j]
		mm.instance_count = occ.size()
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = MatLib.get_mat(["l11_car_a", "l11_car_b", "l11_car_c"][j])
		node.add_child(mmi)
		mms.append(mm)
	var body := StaticBody3D.new()
	node.add_child(body)
	var shapes: Array = []
	var timers: Array = []
	for c in occ.size():
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(4.4, 1.5, 1.8)
		cs.shape = bs
		cs.set_meta("surface", "metal")
		body.add_child(cs)
		shapes.append(cs)
		timers.append(0.0)
	var data := {"slots": slots, "occ": occ, "cols": cols, "mm": mms, "shapes": shapes, "t": timers, "known": {}}
	for c in occ.size():
		_place_car(data, c)
	return data


func _place_car(data: Dictionary, c: int) -> void:
	var xf: Transform3D = data["slots"][data["occ"][c]]["xf"]
	for j in 3:
		(data["mm"][j] as MultiMesh).set_instance_transform(c, xf)
	(data["mm"][0] as MultiMesh).set_instance_color(c, data["cols"][c])
	(data["shapes"][c] as CollisionShape3D).transform = xf * Transform3D(Basis(), Vector3(0, 0.75, 0))


func _build_far(fx: int, fz: int, _v: int, node: Node3D) -> Dictionary:
	var k := GeoKit.new(node, "F")
	k.shadows = false
	for sz in 3:
		for sx in 3:
			for b in plan(fx * 3 + sx, fz * 3 + sz):
				if not b.has("fac") or b["kind"] == "house" or float(b["h"]) < 15.0:
					continue
				var rc: Rect2 = (b["r"] as Rect2).grow(-0.5 - float(b["ins"]))
				k.box_mm(Vector3(rc.position.x, 5.0, rc.position.y), Vector3(rc.end.x, float(b["h"]) - 0.5, rc.end.y), b["fac"], GeoKit.SIDES | GeoKit.PY, false)
				if b["spire"]:
					k.box(Vector3(rc.get_center().x, float(b["h"]) + 18.0, rc.get_center().y), Vector3(0.9, 0.9, 0.9), "l11_blink", GeoKit.ALL, false)
	k.commit()
	return {}


# ------------------------------------------------------- authored street

## The barricaded exit street (z-street of chunk (1,-1)): a lone arcade machine
## in the road (Level 25), an arcade building (808), memorial and painted trail.
func _exit_east(cb, node: Node3D, grp: String) -> void:
	cb.cabinet(CAB, 0.0, "l11_cabinet_red")
	make_exit("L011>L025#39", "interact", CAB + Vector3(0, 1.0, 0.9), Vector3(1.6, 2.0, 1.4), "Play the arcade machine", node)
	lights.add_anchor(CAB + Vector3(0, 1.5, 1.4), Color(0.45, 0.75, 1.0), 1.3, 7.0, 0.3, grp)
	_emit(node, "chiptune", {"bpm": 144.0, "root": 330.0}, CAB + Vector3(0, 1.2, 0), -13.0, 32.0)
	make_exit("L011>L808#13", "walk_in", Vector3(101.4, 1.4, -21.3), Vector3(1.4, 2.4, 1.8), "", node)
	var lb := Label3D.new()
	lb.text = "ARCADE"
	lb.font_size = 90
	lb.pixel_size = 0.012
	lb.outline_size = 0
	lb.shaded = false
	lb.modulate = Color(1.0, 0.35, 0.8)
	lb.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(99.8, 3.8, -26.0))
	node.add_child(lb)
	for y in [3.25, 4.35]:
		cb.bmm(Vector3(99.74, y, -30.4), Vector3(99.8, y + 0.06, -21.6), "l11_neon_cyan", 63, false)
	lights.add_anchor(Vector3(97.5, 3.6, -25.0), Color(1.0, 0.35, 0.8), 2.2, 11.0, 0.0, grp)
	_emit(node, "chiptune", {"bpm": 118.0, "root": 262.0, "scale": [0, 4, 7, 9, 12]}, Vector3(104.0, 1.5, -25.0), -18.0, 26.0)
	cb.barricade(80.0, -7.0)
	cb.memorial(Vector3(87.0, 0.0, -5.2))
	var nt := add_note("l11_memorial", "Card tucked between the candles", "We haven't stopped looking.\nCome home. We moved the trail so it always passes this corner.\n\n(Photographs, candles and dried flowers are piled against the barricade.)", Vector3(85.6, 0.3, -5.5))
	nt.reparent(node)
	var tags := [["NO EXITS PAST HERE", Vector3(90.5, 1.75, -6.0), 0.0, Color(0.85, 0.08, 0.06)], ["SAFE ROUTE", Vector3(89.5, 0.02, 4.0), -1.0, Color(1.0, 0.45, 0.05)]]
	for t in tags:
		var tl := Label3D.new()
		tl.text = t[0]
		tl.font_size = 48 if t[2] == 0.0 else 120
		tl.pixel_size = 0.01
		tl.outline_size = 0
		tl.modulate = t[3]
		var bas := Basis() if t[2] == 0.0 else Basis(Vector3.RIGHT, -PI * 0.5)
		tl.transform = Transform3D(bas, t[1])
		node.add_child(tl)
	for seg in [[Vector3(89.5, 0.006, -3.0), Vector3(89.5, 0.006, 9.5)], [Vector3(89.5, 0.006, 9.5), Vector3(24.0, 0.006, 9.5)]]:
		cb.bmm(seg[0] - Vector3(0.13, 0, 0.13), seg[1] + Vector3(0.13, 0.008, 0.13), "l11_spray", 4, false)
	for i in 5:
		var p := Vector3(76.0 - i * 13.0, 0.016, 9.5)
		cb.tri(p + Vector3(-1.0, 0, -0.55), p + Vector3(-1.0, 0, 0.55), p + Vector3(-1.9, 0, 0), "l11_spray", Vector3.UP)


func _exit_west(cb, node: Node3D) -> void:
	var bp: Vector3 = cb.elevator(Vector3(80.0, LY, -52.0), Vector3(0, 0, 1), Vector3(1, 0, 0))
	make_exit("L011>L998#44", "interact", Vector3(80.9, LY + 1.2, -51.0), Vector3(1.6, 2.4, 3.6), "Press the call button", node)
	lights.add_anchor(bp + Vector3(1.0, 0.8, 0), Color(1.0, 0.9, 0.7), 0.9, 6.0, 0.0, "0,-1")
	cb.bmm(Vector3(80.0, LY + 0.95, -24.65), Vector3(80.04, LY + 2.85, -23.35), "l11_poster", 63, false)
	make_exit("L011>L049#41", "interact", Vector3(80.7, LY + 1.6, -24.0), Vector3(1.2, 2.2, 1.6), "Touch the poster", node)
	for t in [["ENLIST", 2.55, 44], ["SERVE WITH PRIDE", 1.25, 16], ["DON'T", 2.0, 64]]:
		var lb := Label3D.new()
		lb.text = t[0]
		lb.font_size = t[2]
		lb.pixel_size = 0.01
		lb.outline_size = 0
		lb.modulate = Color(0.95, 0.93, 0.85) if t[0] != "DON'T" else Color(0.85, 0.08, 0.06)
		lb.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(80.06, LY + float(t[1]), -24.0 if t[0] != "DON'T" else -55.6))
		node.add_child(lb)
	var c := Vector3(80.07, LY + 1.95, -24.0)
	cb.tri(c + Vector3(0, 0.28, 0), c + Vector3(0, -0.2, -0.26), c + Vector3(0, -0.2, 0.26), "l11_paper", Vector3(1, 0, 0))


## A Malt Marters supply drop with an anonymous note (SOURCE practice).
func _supplies(k: GeoKit, cb) -> void:
	var c := Vector3(82.4, LY, 28.0)
	for p in [Vector3(0, 0, 0), Vector3(0, 0, 0.9), Vector3(0.1, 0.6, 0.4), Vector3(0, 0, 1.8)]:
		k.box(c + p + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.8), "l11_crate")
	k.box(c + Vector3(0, 0.25, 2.8), Vector3(0.6, 0.5, 0.6), "l11_paper", GeoKit.ALL, false)
	var nt := add_note("l11_mm_note", "Note under the twine", "Left for whoever is nearest.\nWater, tins, batteries, a blanket.\nNo need to thank anyone; we will be gone by the time you read this.\n- M.M.", c + Vector3(0.0, 0.95, 0.4))
	nt.reparent(k.root)


func _emit(node: Node3D, recipe: String, params: Dictionary, p: Vector3, db: float, dist: float) -> void:
	var e := AudioStreamPlayer3D.new()
	e.stream = AudioSynth.get_stream(recipe, params)
	e.volume_db = db
	e.max_distance = dist
	e.unit_size = 4.0
	e.bus = "Ambience"
	e.position = p
	e.autoplay = true
	node.add_child(e)


# -------------------------------------------------------------- runtime

func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 240.0, "rumble": 0.35}, -25.0)
	sound.bed("wind", {"seconds": 10.0}, -31.0)
	sound.bed("transformer", {"base": 60.0}, -44.0)
	water_bed = sound.bed("water_bed", {"bright": 500.0}, -60.0)
	sound.oneshot("knock", {"hits": 4}, 45.0, 120.0, 40.0, "[distant hammering from roadworks nobody is working on]", -22.0)
	sound.oneshot("knock", {"hits": 1}, 50.0, 150.0, 16.0, "[a soft thump from a shop you cannot see into]", -24.0)


func on_player_ready() -> void:
	world.target = player
	far.target = player
	if SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[a city hum with no traffic in it] [traffic lights clicking for no one]", 5.0)
	if TransitionService.pending_arrival == "from_L025":
		Overlay.subtitle("[the arcade machine behind you keeps playing its demo]", 4.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var dz := absf(p.z - (CANAL_Z * CS + 10.0))
	water_bed.volume_db = lerpf(water_bed.volume_db, lerpf(-60.0, -21.0, clampf(1.0 - (dz - 6.0) / 40.0, 0.0, 1.0)), clampf(delta * 2.0, 0.0, 1.0))
	if p.distance_to(CAB) < 26.0 and not said.has("cab"):
		said["cab"] = true
		Overlay.subtitle("[a tinny arcade jingle, out in the middle of the road]", 4.0)
	notice_cd = maxf(0.0, notice_cd - delta)
	tick -= delta
	if tick > 0.0 or qa_fixture:
		return
	tick = 0.5
	_fluid()


## Street fluidity (SOURCE): only things nobody is looking at change.
func _fluid() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var pc := world.key_at(player.global_position)
	var changed_seen := false
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var meta := world.meta_of(pc + Vector2i(dx, dz))
			if meta.is_empty():
				continue
			var cars: Dictionary = meta.get("cars", {})
			if not cars.is_empty():
				for c in (cars["occ"] as Array).size():
					var xf: Transform3D = cars["slots"][cars["occ"][c]]["xf"]
					if _seen(cam, xf.origin):
						cars["t"][c] = 0.0
						if cars["known"].get(c, 0) == 2:
							changed_seen = true
						cars["known"][c] = 1
						continue
					cars["t"][c] += 0.5
					if cars["t"][c] > 9.0 and fr_rng.randf() < 0.05:
						var free: Array = []
						for s in (cars["slots"] as Array).size():
							if not (cars["occ"] as Array).has(s) and not _seen(cam, cars["slots"][s]["xf"].origin):
								free.append(s)
						if not free.is_empty():
							cars["occ"][c] = free[fr_rng.randi() % free.size()]
							_place_car(cars, c)
							cars["t"][c] = 0.0
							if cars["known"].get(c, 0) == 1:
								cars["known"][c] = 2
			for e in meta.get("ads", []) + meta.get("rw", []):
				if _seen(cam, e["pos"]):
					e["t"] = 0.0
					if e.get("k", 0) == 2:
						changed_seen = true
					e["k"] = 1
					continue
				e["t"] += 0.5
				if e["t"] > 10.0 and fr_rng.randf() < 0.05:
					e["t"] = 0.0
					if e.has("mi"):
						e["st"] = (int(e["st"]) + 1 + fr_rng.randi() % 6) % 7
						_ad_state(e)
					else:
						e["on"] = not e["on"]
						_rw_state(e)
					if e.get("k", 0) == 1:
						e["k"] = 2
	if changed_seen and notice_cd <= 0.0:
		notice_cd = 75.0
		Overlay.subtitle("[the street is not quite how you left it]", 3.5)


func _seen(cam: Camera3D, p: Vector3) -> bool:
	var d := p.distance_to(cam.global_position)
	return d < 7.0 or (d < 150.0 and cam.is_position_in_frustum(p + Vector3(0, 1.0, 0)))


# ------------------------------------------------------------------ QA

## Engine-level geometry evidence. A lexer/source check cannot prove that a
## bridge collision works or a staircase actually has a reachable top landing.
func qa_self_test() -> Array:
	var result: Array = []
	result.append({"what": "authored civic overpass park is deterministic", "ok": kind_of(2, 0) == "park"})
	world.build_around(Vector3(210.0, 0.0, 60.0), 0)
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(210.0, 4.35, 60.0), Vector3(210.0, 3.25, 60.0), 1))
	var stair := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(194.0, 3.3, 60.0), Vector3(194.0, 1.0, 60.0), 1))
	var upper_ok := not top.is_empty() and absf(float(top["position"].y) - 3.75) < 0.12
	var stair_ok := not stair.is_empty() and float(stair["position"].y) > 0.8 and float(stair["position"].y) < 3.0
	result.append({"what": "park overpass deck collision at 3.75m", "ok": upper_ok, "detail": top.get("position", Vector3.ZERO)})
	result.append({"what": "left physical stair ramp rises above park floor", "ok": stair_ok, "detail": stair.get("position", Vector3.ZERO)})
	var sky_y := LY + 7.1
	var sky_deck := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(202.0, sky_y + 0.8, 52.0), Vector3(202.0, sky_y - 0.6, 52.0), 1))
	var sky_ok := not sky_deck.is_empty() and absf(float(sky_deck.get("position", Vector3.ZERO).y) - sky_y) < 0.14
	result.append({"what": "third-height skywalk has a walkable collision deck", "ok": sky_ok, "detail": sky_deck.get("position", Vector3.ZERO)})
	var upstair := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(210.0, 6.8, 56.0), Vector3(210.0, 4.2, 56.0), 1))
	result.append({"what": "second ascent uses a physical stair ramp", "ok": not upstair.is_empty() and float(upstair.get("position", Vector3.ZERO).y) > 4.7 and float(upstair.get("position", Vector3.ZERO).y) < 6.3, "detail": upstair.get("position", Vector3.ZERO)})
	return result


func qa_capture_plan() -> Array:
	var plan_: Array = qa_shots.duplicate()
	plan_.append({"name": "exitstreet", "pos": Vector3(92.5, 1.8, 7.0), "target": Vector3(91.0, 1.2, -40.0), "flashlight": false})
	plan_.append({"name": "cabinet", "pos": Vector3(92.4, 1.5, -33.5), "target": Vector3(90.0, 1.2, -40.0), "flashlight": false})
	plan_.append({"name": "arcade", "pos": Vector3(87.0, 1.7, -17.0), "target": Vector3(100.0, 2.8, -26.0), "flashlight": false})
	plan_.append({"name": "elevator", "pos": Vector3(86.0, 1.62, -47.0), "target": Vector3(80.0, 1.3, -52.0), "flashlight": false})
	plan_.append({"name": "canal", "pos": Vector3(90.0, 1.8, 92.0), "target": Vector3(400.0, 12.0, 90.0), "flashlight": false})
	plan_.append({"name": "suburb", "pos": Vector3(-290.0, 1.7, 10.0), "target": Vector3(-60.0, 25.0, 6.0), "flashlight": false,
		"prepare": func(): world.build_around(Vector3(-290.0, 0, 10.0), 2)})
	plan_.append({"name": "downtown", "pos": Vector3(330.0, 1.7, 10.0), "target": Vector3(440.0, 60.0, 30.0), "flashlight": false,
		"prepare": func(): world.build_around(Vector3(330.0, 0, 10.0), 2)})
	return plan_
