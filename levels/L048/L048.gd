extends LevelBase
## Level 48 "The Sunset Beach" (Backrooms Wikidot rev 63, accessed 2026-11-04;
## cite: SolarisExplosive, CC BY-SA 3.0). Dossier: docs/canon/levels/L048.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: an infinite sandy beachfront with a lukewarm, possibly lifeless
##   ocean to the south; a large tropical forest 200 m north of the beach;
##   no day-night cycle, a permanent sunny sunset; a red-yellow sun giving 30 %
##   of noon light; 22-36 C depending on location; many modern luxury houses and
##   hotels with contemporary furniture, appliances and air conditioning; lush
##   vegetation and edible plants; a forest of palms, conifers, broadleaf
##   evergreen and deciduous trees whose fauna resembles the Frontrooms and is
##   non-hostile (unique species live ~30 km north, so none here); Gromeliads;
##   grey Veroka Flowers with grey egg-like fruit; the Veroka Farmers with
##   shops selling juice and fruit. Exits: noclip inside a hotel (Level 581
##   lobby), swim to the floor of a small lake (Level 121), follow dirt
##   trenches in the forest long enough (Level 49), enter and exit a farmhouse
##   seen in the forest (Level 10), play dead on the beach (Level 100, small
##   chance, not confirmed).
## SPACE (ADAPTATION): a 480 m window of the endless beach: waterline z~60,
##   dunes, a paved promenade, a three-storey-plus lobby hotel (enterable
##   lobby, first-floor sea terrace by a side stair, pool), two closed hotel
##   towers, eight villas with decks, the Veroka kiosk; the Veroka farm and
##   the forest edge 200 m from the water; forested hills with a small lake, a
##   farmhouse and a 290 m dirt trench running north. The beach and sea run on
##   in a far mesh into the sunset haze; the far forest is a canopy band. Past
##   the window the haze thickens and the sand slows you (soft limit).
## SIGNATURE MECHANIC (stateful): portal variety, each with its own sourced
##   condition: the hotel lobby wall noclips after a sustained push; the lake
##   exit needs you at its floor; the trench exit only opens after you have
##   followed the trench most of its length; the farmhouse exit fires when you
##   leave it after having been inside; playing dead rolls a small chance.
##   Zone captions follow the page's temperature range (sea breeze, humid
##   forest, air-conditioned lobby).
## ABSENT: day-night, noon sun, hostile fauna, unique species, The Shadow
##   (only rumoured; never shown).

const T := preload("res://levels/L048/L048_terrain.gd")
const Flora := preload("res://levels/L048/L048_flora.gd")
const Build := preload("res://levels/L048/L048_build.gd")
const START := Vector3(6.0, 0.0, 30.0)
const HOTEL := Vector3(0.0, 0.0, -44.0)
const FARMHOUSE := Vector3(-150.0, 0.0, -300.0)
const SOFT_X := 232.0
const SOFT_Z := -432.0
const HOLD := 7.0

var ter
var flora
var bk
var hotel_info: Dictionary = {}
var farm: Dictionary = {}
var lazy: Dictionary = {}
var trench_walked := 0.0
var trench_last := Vector3.ZERO
var was_inside_farmhouse := false
var shadow_ok := false
var dead_attempts := 0
var said := {}
var beds := {}
var zone := ""
var _tick := 0.0
var _base_walk := 3.1


func build() -> void:
	ter = T.new()
	rules["view_distance"] = 4000.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.05
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -60.0
	outdoor_env(Color(0.17, 0.16, 0.36), Color(1.0, 0.48, 0.2), Color(0.18, 0.12, 0.12), Vector2(6.0, -40.0),
		Color(1.0, 0.56, 0.3), 1.0, Color(0.95, 0.55, 0.32), 0.0016)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.48, 0.58)
	environment.ambient_light_energy = 0.85
	environment.tonemap_exposure = 1.05
	environment.fog_sky_affect = 0.3
	environment.fog_aerial_perspective = 0.5
	environment.glow_intensity = 0.5
	sun.directional_shadow_max_distance = 140.0
	var sky_mat := environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sun_angle_max = 30.0
	sky_mat.sky_curve = 0.09
	sky_mat.sun_curve = 0.08
	sky_mat.ground_bottom_color = Color(0.1, 0.08, 0.12)
	Build.materials()
	MatLib.register("l48_sea", MatLib.water({"shallow_color": Color(0.5, 0.48, 0.45), "deep_color": Color(0.1, 0.12, 0.2),
		"absorption": 0.35, "clarity": 0.55, "wave_height": 0.16, "wave_scale": 0.2, "wave_speed": 0.5,
		"normal_strength": 0.7, "foam_amount": 0.55, "foam_width": 0.5, "roughness_value": 0.1, "dark_surface": 0.1}))
	MatLib.register("l48_pool", MatLib.water({"shallow_color": Color(0.45, 0.8, 0.85), "deep_color": Color(0.1, 0.4, 0.5),
		"absorption": 0.2, "clarity": 0.9, "wave_height": 0.01, "wave_scale": 1.2, "foam_amount": 0.0, "roughness_value": 0.03}))
	MatLib.register("l48_lake", MatLib.water({"shallow_color": Color(0.3, 0.38, 0.3), "deep_color": Color(0.05, 0.1, 0.08),
		"absorption": 0.5, "clarity": 0.5, "wave_height": 0.02, "foam_amount": 0.1, "roughness_value": 0.05}))
	lights.setup(5, 0)
	var land := Node3D.new()
	land.name = "Land"
	add_child(land)
	ter.build_meshes(land, ter.make_material(false), ter.make_material(true))
	ter.build_collision(land)
	_waters()
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var k := kit("Seafront")
	bk = Build.new(self, ter, k, props)
	hotel_info = bk.lobby_hotel(HOTEL, 30.0, 18.0, 5)
	_pool(k)
	bk.hotel(Vector3(-118.0, 0, -48.0), 40.0, 20.0, 7, "HOTEL")
	bk.hotel(Vector3(122.0, 0, -46.0), 34.0, 18.0, 5, "SUITES")
	var vi := 0
	for x in [-205.0, -176.0, -74.0, -48.0, 46.0, 72.0, 172.0, 200.0]:
		bk.villa(Vector3(x, 0, -36.0 + (vi % 2) * 3.0), 0.0, rng.randf_range(13.0, 16.0), rng.randf_range(10.0, 12.0), vi % 3 == 0)
		vi += 1
	_promenade(k)
	bk.kiosk(Vector3(30.0, 0, -12.0))
	_veroka_farm(k)
	farm = bk.farmhouse(FARMHOUSE, 30.0)
	k.commit()
	_plants(land)
	_beach_dressing(props)
	_exits()
	_notes()
	_sounds()
	for tag in ["start", "from_L011", "from_L320"]:
		add_arrival(tag, START + Vector3(0, ter.h(START.x, START.z) + 0.05, 0), 150.0)
	var fo: Vector3 = farm["out"]
	var od := (fo - (farm["door"] as Vector3)).normalized()
	add_arrival("from_L010", fo + od * 2.0 + Vector3(0, 0.1, 0), rad_to_deg(atan2(-od.x, -od.z)))
	add_landmark("The sunset beach and the lobby hotel", START)
	add_landmark("Veroka kiosk on the promenade", Vector3(30.0, 3.4, -12.0))
	add_landmark("Forest edge, 200 m from the water", Vector3(0.0, 6.0, -140.0))
	add_landmark("Farmhouse in the forest", FARMHOUSE)
	_shots()


# ------------------------------------------------------------- water

func _waters() -> void:
	var sea := WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-3400.0, -40.0, 30.0), Vector3(3400.0, 0.0, 3400.0), "l48_sea", true)
	sea.fog_color = Color(0.25, 0.25, 0.28)
	sea.fog_density = 0.05
	sea.tint = Color(0.6, 0.55, 0.5)
	var lake := WaterVolume.new()
	lake.name = "SmallLake"
	add_child(lake)
	lake.setup(Vector3(T.LAKE.x - T.LAKE_R - 3.0, T.LAKE_FLOOR - 1.0, T.LAKE.y - T.LAKE_R - 3.0), Vector3(T.LAKE.x + T.LAKE_R + 3.0, T.LAKE_Y, T.LAKE.y + T.LAKE_R + 3.0), "l48_lake", true)
	lake.fog_color = Color(0.08, 0.14, 0.1)
	lake.fog_density = 0.18
	lake.tint = Color(0.3, 0.45, 0.35)
	var probe := ReflectionProbe.new()
	probe.position = Vector3(0.0, 10.0, 20.0)
	probe.size = Vector3(300.0, 50.0, 140.0)
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.max_distance = 2000.0
	add_child(probe)


func _pool(k: GeoKit) -> void:
	var r: Rect2 = T.POOL
	var y := T.PROM_Y
	var x0 := r.position.x
	var z0 := r.position.y
	var x1 := r.end.x
	var z1 := r.end.y
	k.box_mm(Vector3(x0, y - 2.0, z0), Vector3(x1, y - 1.6, z1), "l48_pool_tile")
	for w in [[Vector3(x0 - 0.3, y - 2.0, z0 - 0.3), Vector3(x0, y + 0.05, z1 + 0.3)], [Vector3(x1, y - 2.0, z0 - 0.3), Vector3(x1 + 0.3, y + 0.05, z1 + 0.3)],
			[Vector3(x0, y - 2.0, z0 - 0.3), Vector3(x1, y + 0.05, z0)], [Vector3(x0, y - 2.0, z1), Vector3(x1, y + 0.05, z1 + 0.3)]]:
		k.box_mm(w[0], w[1], "l48_pool_tile")
	# deck around the pool, a ladder and loungers
	k.slab(x0 - 3.0, z0 - 1.0, x0 - 0.3, z1 + 2.5, y + 0.06, 0.2, "l48_marble_tile")
	k.slab(x1 + 0.3, z0 - 1.0, x1 + 3.0, z1 + 2.5, y + 0.06, 0.2, "l48_marble_tile")
	k.slab(x0 - 0.3, z1 + 0.3, x1 + 0.3, z1 + 2.5, y + 0.06, 0.2, "l48_marble_tile")
	var pool := WaterVolume.new()
	pool.name = "HotelPool"
	add_child(pool)
	pool.setup(Vector3(x0, y - 1.6, z0), Vector3(x1, y - 0.15, z1), "l48_pool", true)
	pool.tint = Color(0.5, 0.8, 0.85)
	for i in 4:
		Props.place(self, bk.props, "kenney/furniture-kit/loungechairrelax", Vector3(x0 + 1.2 + i * 2.6, y + 0.06, z1 + 1.4), 180.0, 0.9)
	lights.add_anchor(Vector3((x0 + x1) * 0.5, y - 1.2, (z0 + z1) * 0.5), Color(0.5, 0.9, 1.0), 1.2, 7.0, 0.0, "pool")


func _promenade(k: GeoKit) -> void:
	var y := T.PROM_Y
	k.slab(-240.0, -15.0, 240.0, -9.0, y + 0.08, 0.3, "l48_paver")
	# boardwalks across the dunes down to the sand
	for x in [-150.0, -96.0, 4.0, 96.0, 150.0]:
		var zb := 10.0
		var yb: float = ter.h(x, zb)
		k.slab(x - 1.4, -9.2, x + 1.4, -3.0, y + 0.1, 0.2, "l48_deck")
		k.ramp(Vector3(x, y + 0.1, -3.0), Vector3(x, yb + 0.05, zb), 2.8, 0.25, "l48_deck")
		for s in [-1.0, 1.0]:
			for i in 6:
				var zz := lerpf(-8.0, zb, float(i) / 5.0)
				var yy := lerpf(y + 0.1, yb, clampf((zz + 3.0) / (zb + 3.0), 0.0, 1.0)) if zz > -3.0 else y + 0.1
				k.box(Vector3(x + s * 1.45, yy + 0.45, zz), Vector3(0.1, 0.9, 0.1), "l48_deck", GeoKit.ALL, false)
	# street lamps along the promenade, lit for the evening
	for i in 17:
		var x := -224.0 + i * 28.0
		var p := Vector3(x, y + 0.08, -15.4)
		k.box(p + Vector3(0, 2.0, 0), Vector3(0.12, 4.0, 0.12), "l48_steel", GeoKit.ALL, true)
		k.box(p + Vector3(0, 4.0, 0.35), Vector3(0.1, 0.08, 0.8), "l48_steel", GeoKit.ALL, false)
		k.box(p + Vector3(0, 3.92, 0.7), Vector3(0.36, 0.06, 0.24), "l48_window_lit", GeoKit.ALL, false)
		lights.add_anchor(p + Vector3(0, 3.7, 0.7), Color(1.0, 0.72, 0.42), 1.2, 9.0, 0.0, "prom")
	for i in 10:
		var x := -200.0 + i * 44.0 + 14.0
		Props.place(self, bk.props, "kenney/furniture-kit/bench", Vector3(x, y + 0.08, -9.6), 180.0, 1.0)


func _veroka_farm(k: GeoKit) -> void:
	# trellis rows (the Veroka Farmers harvest Veroka fruit from their plants)
	var y0: float
	for row in 9:
		var x := 60.0 + row * 7.5
		for i in 10:
			var z := -126.0 + i * 3.0
			y0 = ter.h(x, z)
			k.box(Vector3(x, y0 + 1.0, z), Vector3(0.12, 2.0, 0.12), "l48_cladding", GeoKit.ALL, false)
		var ya: float = ter.h(x, -126.0)
		var yb: float = ter.h(x, -99.0)
		for wy in [1.0, 1.9]:
			var a := Vector3(x, ya + wy, -126.0)
			var b := Vector3(x, yb + wy, -99.0)
			k.box_xf(Transform3D(Basis.looking_at((b - a).normalized(), Vector3.UP), (a + b) * 0.5), Vector3(0.02, 0.02, a.distance_to(b)), "l48_steel", GeoKit.ALL, false)
	bk.farm_shed(Vector3(140.0, 0, -110.0))
	var lab := Label3D.new()
	lab.text = "VEROKA FARMERS"
	lab.font_size = 64
	lab.pixel_size = 0.007
	lab.modulate = Color(0.95, 0.9, 0.8)
	lab.outline_size = 8
	lab.outline_modulate = Color(0.15, 0.1, 0.06)
	lab.position = Vector3(140.0, ter.h(140.0, -110.0) + 3.4, -107.9)
	add_child(lab)


# ------------------------------------------------------------- plants

func _clear(p: Vector3, m: float) -> bool:
	if p.z > -8.0 and p.z < 40.0 and absf(p.x - START.x) < 6.0:
		return false
	if p.z > -60.0 and p.z < 4.0:
		return false
	if absf(p.x - FARMHOUSE.x) < 16.0 + m and absf(p.z - FARMHOUSE.z) < 16.0 + m:
		return false
	if Vector2(p.x - T.LAKE.x, p.z - T.LAKE.y).length() < T.LAKE_R + 4.0 + m:
		return false
	if p.z < -140.0 and ter.trench_d(p.x, p.z) < 4.0 + m:
		return false
	if p.x > 50.0 and p.x < 152.0 and p.z > -134.0 and p.z < -92.0:
		return false
	if absf(p.x - 6.0 - 5.0 * sin(p.z * 0.04)) < 3.5 + m and p.z < -60.0 and p.z > -150.0:
		return false
	return true


func _plants(parent: Node3D) -> void:
	flora = Flora.new()
	var col := kit("Trunks")
	var r := RandomNumberGenerator.new()
	r.seed = 48100
	var cell := 7.0
	var dense := FastNoiseLite.new()
	dense.seed = 4811
	dense.frequency = 0.02
	for ix in range(-35, 36):
		for iz in range(-63, -18):
			var p := Vector3((ix + r.randf_range(0.1, 0.9)) * cell, 0, (iz + r.randf_range(0.1, 0.9)) * cell)
			if p.z > -135.0 or absf(p.x) > T.PLANT_X or p.z < T.PLANT_Z:
				continue
			if r.randf() > 0.72 + 0.2 * dense.get_noise_2d(p.x, p.z) or not _clear(p, 0.5):
				continue
			p.y = ter.h(p.x, p.z) - 0.2
			var roll := r.randf()
			var kind := "broad" if roll < 0.55 else ("palm" if roll < 0.78 else "con")
			var i := r.randi_range(0, 2) if kind != "con" else r.randi_range(0, 1)
			var s := r.randf_range(0.8, 1.25)
			flora.add_tree(kind, i, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), p))
			_trunk(col, p, 0.4 * s)
			# undergrowth
			for u in 2:
				var q := p + Vector3(r.randf_range(-3.5, 3.5), 0, r.randf_range(-3.5, 3.5))
				if not _clear(q, 0.0):
					continue
				q.y = ter.h(q.x, q.z)
				var uk := "bush" if r.randf() < 0.45 else ("fern" if r.randf() < 0.8 else "gromeliad")
				flora.add(uk, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.3)), q))
	# palms along the beach back, the promenade and among the villas
	for i in 90:
		var x := r.randf_range(-236.0, 236.0)
		var z := r.randf_range(-70.0, 8.0) if i % 3 != 0 else r.randf_range(-6.0, 6.0)
		var p := Vector3(x, 0, z)
		if (z > -16.0 and z < -7.0) or absf(x - START.x) < 6.0:
			continue
		if z < -24.0 and z > -60.0 and _in_building(p):
			continue
		if T.POOL.grow(3.0).has_point(Vector2(x, z)):
			continue
		p.y = ter.h(x, z) - 0.2
		var s := r.randf_range(0.85, 1.2)
		flora.add_tree("palm", r.randi_range(0, 2), Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), p))
		_trunk(col, p, 0.26)
	# Veroka vines on the trellis rows
	for row in 9:
		var x := 60.0 + row * 7.5
		var z := -124.8
		while z < -100.0:
			var q := Vector3(x, ter.h(x, z), z)
			flora.add("veroka", Transform3D(Basis(Vector3.UP, PI * 0.5 + r.randf_range(-0.05, 0.05)), q))
			z += 2.4
	# Gromeliads along the forest edge
	for i in 70:
		var q := Vector3(r.randf_range(-220.0, 220.0), 0, r.randf_range(-150.0, -126.0))
		if not _clear(q, 0.0):
			continue
		q.y = ter.h(q.x, q.z)
		flora.add("gromeliad", Transform3D(Basis(Vector3.UP, r.randf() * TAU), q))
	flora.commit(parent)
	col.commit()


func _in_building(p: Vector3) -> bool:
	if absf(p.x - HOTEL.x) < 22.0:
		return true
	for c in [Vector2(-118.0, 22.0), Vector2(122.0, 19.0)]:
		if absf(p.x - c.x) < c.y:
			return true
	for x in [-205.0, -176.0, -74.0, -48.0, 46.0, 72.0, 172.0, 200.0]:
		if absf(p.x - x) < 10.0:
			return true
	return false


func _trunk(col: GeoKit, p: Vector3, radius: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 5.0
	cs.shape = sh
	cs.position = p + Vector3(0, 2.6, 0)
	cs.set_meta("surface", "wood")
	col.body.add_child(cs)


func _beach_dressing(props: Node3D) -> void:
	# a few sunbeds and umbrellas, towels, a lifebuoy post, driftwood
	var k := kit("Beach")
	for i in 7:
		var x := -60.0 + i * 20.0 + rng.randf_range(-4.0, 4.0)
		var z := rng.randf_range(18.0, 32.0)
		if absf(x - START.x) < 5.0:
			continue
		var y: float = ter.h(x, z)
		Props.place(self, props, "kenney/furniture-kit/loungechair", Vector3(x, y, z), 180.0 + rng.randf_range(-15, 15), 0.9)
		Props.place(self, props, "kenney/furniture-kit/loungechair", Vector3(x + 1.4, ter.h(x + 1.4, z), z), 180.0 + rng.randf_range(-15, 15), 0.9)
		k.cylinder(Vector3(x + 0.7, y + 1.2, z - 1.0), 0.04, 2.4, "l48_steel", 6, false, false)
		k.cylinder(Vector3(x + 0.7, y + 2.35, z - 1.0), 1.5, 0.06, "l48_awning", 12, false, true)
	for i in 6:
		var x := rng.randf_range(-200.0, 200.0)
		var z := rng.randf_range(35.0, 52.0)
		var bas := Basis(Vector3.UP, rng.randf() * TAU)
		k.box_xf(Transform3D(bas, Vector3(x, ter.h(x, z) + 0.12, z)), Vector3(0.28, 0.24, rng.randf_range(1.6, 3.4)), "l48_bark", GeoKit.ALL, false)
	var lp := Vector3(-24.0, 0, 24.0)
	lp.y = ter.h(lp.x, lp.z)
	k.box(lp + Vector3(0, 1.2, 0), Vector3(0.14, 2.4, 0.14), "l48_cladding")
	Props.place(self, props, "ph/lifebuoy", lp + Vector3(0, 1.3, 0.1), 0.0, 0.8)
	# a lifeguard tower on stilts with a stair (empty: no staff anywhere)
	var g := Vector3(-34.0, 0, 30.0)
	g.y = ter.h(g.x, g.z)
	var gy := g.y + 2.6
	for sx in [-1.2, 1.2]:
		for sz in [-1.2, 1.2]:
			k.box(g + Vector3(sx, 1.3, sz), Vector3(0.16, 2.8, 0.16), "l48_deck")
	k.slab(g.x - 1.5, g.z - 1.5, g.x + 1.5, g.z + 1.5, gy, 0.15, "l48_deck")
	k.box(g + Vector3(0, gy - g.y + 1.1, -1.4), Vector3(3.0, 2.2, 0.1), "l48_awning", GeoKit.ALL, true)
	k.box(g + Vector3(-1.45, gy - g.y + 1.1, 0), Vector3(0.1, 2.2, 3.0), "l48_render", GeoKit.ALL, true)
	k.box(g + Vector3(1.45, gy - g.y + 0.5, 0.4), Vector3(0.08, 1.0, 2.2), "l48_render", GeoKit.ALL, true)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.15), g + Vector3(0, gy - g.y + 2.4, 0)), Vector3(3.6, 0.08, 3.6), "l48_awning", GeoKit.ALL, false)
	var steps := int(ceil(2.6 / 0.18))
	k.stairs(Vector3(g.x, ter.h(g.x, g.z + 1.5 + steps * 0.26), g.z + 1.5 + steps * 0.26), Vector3(0, 0, -1), 1.0, gy - ter.h(g.x, g.z + 1.5 + steps * 0.26), steps, "l48_deck", 0.26)
	Props.place(self, props, "ph/lifebuoy", g + Vector3(1.5, gy - g.y + 0.6, -0.6), 90.0, 0.8)
	# the towel where people say you can play dead
	k.box(Vector3(-14.0, ter.h(-14.0, 26.0) + 0.02, 26.0), Vector3(1.0, 0.02, 1.9), "l48_awning", GeoKit.ALL, false)
	k.commit()


# ------------------------------------------------------------- exits

func _exits() -> void:
	# QA-tested first: noclip through the lobby's east wall (SOURCE: inside a hotel)
	var nc: Vector3 = hotel_info["noclip"]
	var t := add_exit("L048>L581#1", "noclip", Vector3(nc.x, nc.y + 1.1, nc.z), Vector3(1.4, 2.2, 3.0), "")
	if t:
		t.hold_seconds = 2.2
	# play dead on the beach (RUMORED, small chance)
	var dp := Vector3(-14.0, ter.h(-14.0, 26.0), 26.0)
	var d := add_exit("L048>L100#3", "condition", dp + Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 3.0), "")
	if d:
		d.condition = func() -> bool: return shadow_ok
	add_interactable(dp + Vector3(0, 0.4, 0), Vector3(1.6, 0.8, 2.2), "Lie down on the sand and play dead", _play_dead)


## Forest exits are created only near them (keeps the QA nav window local).
func _lazy_exits(p: Vector3) -> void:
	if not lazy.has("farm") and p.distance_to(FARMHOUSE) < 90.0:
		var o: Vector3 = farm["out"]
		var t := add_exit("L048>L010#5", "condition", o + Vector3(0, 1.1, 0), Vector3(2.4, 2.2, 1.6), "")
		if t:
			t.condition = func() -> bool: return was_inside_farmhouse
		lazy["farm"] = t
	var lake_c := Vector3(T.LAKE.x, T.LAKE_FLOOR, T.LAKE.y)
	if not lazy.has("lake") and Vector2(p.x - lake_c.x, p.z - lake_c.z).length() < 80.0:
		lazy["lake"] = add_exit("L048>L121#2", "walk_in", lake_c + Vector3(0, 0.7, 0), Vector3(12.0, 1.4, 12.0), "")
	var end: Vector2 = T.TRENCH[T.TRENCH.size() - 1]
	if not lazy.has("trench") and Vector2(p.x - end.x, p.z - end.y).length() < 90.0:
		var y: float = ter.h(end.x, end.y)
		var tt := add_exit("L048>L049#4", "condition", Vector3(end.x, y + 1.2, end.y), Vector3(5.0, 2.6, 5.0), "")
		if tt:
			tt.condition = func() -> bool: return trench_walked > 200.0
		lazy["trench"] = tt


func _play_dead() -> void:
	dead_attempts += 1
	if not SessionState.is_qa() and rng.randf() < 0.08:
		shadow_ok = true
		Overlay.glitch(1.2)
		Overlay.subtitle("[you lie still on the warm sand... something long and dark slides across you, and pulls]", 6.0)
		return
	var lines := ["[you lie still on the warm sand. The waves come and go. Nothing comes for you.]",
		"[the sun does not move. Neither do you. Nothing happens.]",
		"[you play dead until your back aches. The beach does not care.]"]
	Overlay.subtitle(lines[(dead_attempts - 1) % lines.size()], 5.0)


# ------------------------------------------------------------- notes

func _notes() -> void:
	var fy: float = hotel_info["floor"]
	add_note("l48_guestbook", "Hotel guest book", "Arrivals sign here. Most entries say the same: woke on the sand, sun going down, still going down.\n\nThe rooms upstairs are furnished and the air conditioning works. There is no staff. Take a key.\n\nOne entry, underlined: 'Leaned on the lobby wall too long and went through it. Came out in another hotel lobby, much bigger. Level 581, the M.E.G. said.'", Vector3(HOTEL.x - 1.6, fy + 1.18, HOTEL.z - 9.0 + 3.2))
	add_note("l48_meg", "M.E.G. notice (promenade)", "LEVEL 48 - HABITABLE.\n\nEndless beach, lukewarm sea to the south, tropical forest 200 m inland. The sun never sets: about a third of noon light, red to yellow. 22 to 36 degrees depending on where you stand.\n\nFood is easy: plenty of edible plants. Forest animals look like Frontrooms ones and are harmless. The strange species live about 30 km north; do not go looking.", Vector3(-6.0, T.PROM_Y + 1.2, -15.6), Vector3(0.6, 0.6, 0.4))
	add_note("l48_veroka", "Veroka price board", "VEROKA FRUIT - grey, egg-shaped, good for you: vitamin C and potassium.\nVEROKA JUICE - pressed from the fruit. Also carries lithium; some drink it for their nerves.\n\nGrown on the trellises up by the forest by the Veroka Farmers (about 300 of us). Veroka flowers are grey and live eight months; pick them before.", Vector3(30.0, ter.h(30.0, -12.0) + 1.5, -12.65), Vector3(0.8, 0.6, 0.2))
	var tp: Vector2 = T.TRENCH[0]
	add_note("l48_trench", "Scratched on a post at the trench mouth", "These dirt trenches run all through the forest. Follow one long enough and it leads you down into Level 49. Do not give up halfway; it does not work if you cut across.", Vector3(tp.x + 2.4, ter.h(tp.x + 2.4, tp.y) + 1.2, tp.y), Vector3(0.4, 0.6, 0.4))
	var fo: Vector3 = farm["door"]
	add_note("l48_farmhouse", "Pencilled on the farmhouse door frame", "Farmhouses turn up in this forest where there were none. Walk in, walk back out, and you are in Level 10. Nobody has found the same one twice.", fo + Vector3(0.9, 1.4, 0.2), Vector3(0.4, 0.6, 0.4))
	add_note("l48_lake", "Waterproof tag on a reed post", "Small lake. Dive to the bottom and you come up in Level 121 instead. It is shallow enough to reach the floor on one breath.", Vector3(T.LAKE.x - T.LAKE_R - 2.0, ter.h(T.LAKE.x - T.LAKE_R - 2.0, T.LAKE.y) + 1.0, T.LAKE.y), Vector3(0.4, 0.6, 0.4))


# ------------------------------------------------------------- sound

func _sounds() -> void:
	beds["surf"] = sound.bed("water_bed", {"seconds": 8.0, "bright": 1200.0}, -16.0)
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -30.0)
	beds["forest"] = sound.bed("crickets", {"seconds": 6.0}, -70.0)
	beds["ac"] = sound.bed("room_tone", {"seconds": 5.0, "cutoff": 900.0, "rumble": 0.2}, -70.0)
	beds["lobby"] = sound.bed("pad", {"root": 220.0, "chord": [0, 4, 7, 11], "seconds": 10.0, "bright": 0.1}, -70.0)
	for p in bk.ac_units:
		sound.emitter("fluorescent_hum", p + Vector3(0, 0.5, 0), {}, -18.0, 10.0)


# ------------------------------------------------------------- shots

func _shots() -> void:
	var sy: float = ter.h(START.x, START.z)
	add_shot("promenade_sunset", Vector3(-28.0, T.PROM_Y + 1.8, -10.5), Vector3(60.0, T.PROM_Y + 2.5, -24.0), {"flashlight": false})
	add_shot("sea_and_sun", START + Vector3(0, sy + 1.65, 0), Vector3(-160.0, 8.0, 240.0), {"flashlight": false})
	var fy: float = hotel_info["floor"]
	add_shot("hotel_lobby", Vector3(HOTEL.x - 11.0, fy + 1.7, HOTEL.z + 7.5), Vector3(HOTEL.x + 6.0, fy + 1.2, HOTEL.z - 6.0), {"flashlight": false})
	var ty: float = hotel_info["terrace"]
	add_shot("terrace_pool_sea", Vector3(HOTEL.x + 10.0, ty + 1.7, -30.0), Vector3(-30.0, 1.0, 40.0), {"flashlight": false})
	var tp: Vector2 = T.TRENCH[2]
	add_shot("forest_trench", Vector3(tp.x + 0.5, ter.h(tp.x + 0.5, tp.y + 6.0) + 1.65, tp.y + 6.0), Vector3(-71.0, ter.h(-71.0, -290.0) + 1.0, -290.0), {"flashlight": false})


# ------------------------------------------------------------- mechanic

func on_player_ready() -> void:
	_base_walk = player.walk_speed
	trench_last = player.global_position


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.4
		_lazy_exits(p)
		_zone(p)
	# trench following (only counts while you walk inside it)
	if p.z < -140.0 and ter.trench_d(p.x, p.z) < 2.2:
		var step := Vector2(p.x - trench_last.x, p.z - trench_last.z).length()
		if step < 2.0:
			trench_walked += step
		if trench_walked > 60.0:
			_say("tr1", "[the trench keeps going, deeper into the trees]")
		if trench_walked > 150.0:
			_say("tr2", "[the walls of the trench are higher now. The forest above is very quiet.]")
	trench_last = p
	# farmhouse: inside?
	var fi: Vector3 = farm["inside"]
	if Vector2(p.x - fi.x, p.z - fi.z).length() < 2.8 and absf(p.y - fi.y) < 1.0:
		if not was_inside_farmhouse:
			_say("farm_in", "[an old farmhouse, too old for this beach. The door is behind you.]")
		was_inside_farmhouse = true
	_soft_limit(p)
	_mix(p, delta)


func _soft_limit(p: Vector3) -> void:
	if SessionState.is_qa():
		return
	var d := maxf(absf(p.x) - SOFT_X, SOFT_Z - p.z)
	if d > 0.0:
		player.walk_speed = _base_walk * clampf(1.0 - d / HOLD, 0.25, 1.0)
		_say("soft", "[the sand and the haze go on, unchanged, for as far as anyone has walked]", 5.0)
		if d > HOLD:
			player.global_position = Vector3(clampf(p.x, -SOFT_X - HOLD, SOFT_X + HOLD), p.y, maxf(p.z, SOFT_Z - HOLD))
	elif player.walk_speed != _base_walk:
		player.walk_speed = _base_walk


func _zone(p: Vector3) -> void:
	var z := "beach"
	var fy: float = hotel_info["floor"]
	if absf(p.x - HOTEL.x) < 15.0 and p.z < HOTEL.z + 9.0 and p.z > HOTEL.z - 9.0 and p.y < fy + 4.0:
		z = "lobby"
	elif p.z < -140.0:
		z = "forest"
	elif p.z < -6.0:
		z = "promenade"
	if z == zone:
		return
	zone = z
	match z:
		"beach":
			_say("z_beach", "[warm sea breeze, about 30 degrees; the sun sits on the horizon and stays there]")
		"lobby":
			_say("z_lobby", "[air conditioning: cool, dry, a steady hum]")
		"forest":
			_say("z_forest", "[under the trees the air is close and humid, well over 30 degrees]")


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func _mix(p: Vector3, delta: float) -> void:
	var k := minf(delta * 1.5, 1.0)
	var near_sea := 1.0 - clampf((T.WATERLINE - p.z) / 160.0, 0.0, 1.0)
	_vol("surf", lerpf(-40.0, -12.0, near_sea) - (14.0 if zone == "lobby" else 0.0), k)
	_vol("forest", -24.0 if zone == "forest" else -70.0, k * 0.5)
	_vol("ac", -26.0 if zone == "lobby" else -70.0, k)
	_vol("lobby", -32.0 if zone == "lobby" else -70.0, k)
	_vol("wind", -30.0 if zone != "lobby" else -50.0, k)


func _vol(key: String, db: float, k: float) -> void:
	var a: AudioStreamPlayer = beds.get(key)
	if a:
		a.volume_db = lerpf(a.volume_db, db, k)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var ok_spawn := is_instance_valid(player) and player.global_position.y > 0.3
	out.append({"what": "spawn on the sand above the waterline", "ok": ok_spawn, "detail": player.global_position if is_instance_valid(player) else null})
	out.append({"what": "lobby noclip and play-dead exits built near the beach", "ok": exits.size() >= 2})
	out.append({"what": "terrace is an upper walkable level", "ok": float(hotel_info.get("terrace", 0.0)) - float(hotel_info.get("floor", 0.0)) > 4.0})
	out.append({"what": "forest edge lies 200 m from the waterline", "ok": absf((T.WATERLINE - T.FOREST_Z) - 200.0) < 1.0})
	out.append({"what": "trench exit stays shut until the trench is followed", "ok": trench_walked < 200.0})
	out.append({"what": "play dead never fires in QA", "ok": not shadow_ok})
	out.append({"what": "forest planted", "ok": flora.count > 1500, "detail": flora.count})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
