extends "res://levels/L026/L026_ship.gd"
## Level 26 ship, continued: upper deck (pool, deckhouse, lifeboats, stern party), sun deck,
## foredeck, party debris and the strings of party lights.


func _init(level: LevelBase, arch: GeoKit, dress: GeoKit, r: RandomNumberGenerator) -> void:
	super(level, arch, dress, r)


# ------------------------------------------------------------------ upper deck

func upper_deck() -> void:
	var zf := LOBBY.y
	var za := -56.0
	# deck slab around the pool opening
	k.slab(-9.0, za, 9.0, POOL.position.y, UP, 0.2, "l26_deck")
	k.slab(-9.0, POOL.end.y, 9.0, zf, UP, 0.2, "l26_deck")
	k.slab(-9.0, POOL.position.y, POOL.position.x, POOL.end.y, UP, 0.2, "l26_deck")
	k.slab(POOL.end.x, POOL.position.y, 9.0, POOL.end.y, UP, 0.2, "l26_deck")
	# the crimson pool: basin hanging under the deck, coping, steps
	var py := UP - 1.2
	k.slab(POOL.position.x, POOL.position.y, POOL.end.x, POOL.end.y, py, 0.2, "l26_pool_tile")
	for e in [[Vector3(POOL.position.x, py - 0.2, POOL.position.y), Vector3(POOL.end.x, py - 0.2, POOL.position.y)],
			[Vector3(POOL.position.x, py - 0.2, POOL.end.y), Vector3(POOL.end.x, py - 0.2, POOL.end.y)],
			[Vector3(POOL.position.x, py - 0.2, POOL.position.y), Vector3(POOL.position.x, py - 0.2, POOL.end.y)],
			[Vector3(POOL.end.x, py - 0.2, POOL.position.y), Vector3(POOL.end.x, py - 0.2, POOL.end.y)]]:
		k.wall(e[0], e[1], 1.4, 0.2, "l26_pool_tile")
	k.stairs(Vector3(POOL.end.x - 0.9, py, POOL.end.y - 2.3), Vector3(0, 0, 1), 1.4, 1.2, 7, "l26_pool_tile", 0.3)
	for s: float in [-1.0, 1.0]:
		d.box(Vector3(POOL.get_center().x + s * (POOL.size.x * 0.5 + 0.2), UP + 0.03, POOL.get_center().y), Vector3(0.4, 0.06, POOL.size.y + 0.8), "l26_white", GeoKit.ALL, false)
		d.box(Vector3(POOL.get_center().x, UP + 0.03, POOL.get_center().y + s * (POOL.size.y * 0.5 + 0.2)), Vector3(POOL.size.x + 0.8, 0.06, 0.4), "l26_white", GeoKit.ALL, false)
	# columns carrying the upper deck: along the promenades and over the stern deck
	for s: float in [-1.0, 1.0]:
		var z := za + 2.0
		while z < zf:
			if absf(z - GATE_Z) > 1.5:
				d.box(Vector3(s * 8.7, UP * 0.5, z), Vector3(0.22, UP, 0.22), "l26_white", GeoKit.ALL, true)
			z += 7.0
		for z2: float in [-54.0, -49.0]:
			d.box(Vector3(s * 4.6, UP * 0.5, z2), Vector3(0.3, UP, 0.3), "l26_white", GeoKit.ALL, true)
	# promenade ceiling lights under the upper deck
	for s: float in [-1.0, 1.0]:
		for i in 9:
			var lz := -40.0 + i * 6.5
			d.panel(Vector3(s * 7.7, UP - 0.21, lz), 0.5, 0.5, "l26_fixture")
			lamp_points.append([Vector3(s * 7.7, UP - 0.6, lz), Color(1.0, 0.92, 0.78), 0.8, 5.0, 0.0])
	# rails: sides, aft edge (gaps at the stern stairs), forward edge (gaps at the bow stairs)
	railing(Vector3(-8.85, UP, za), Vector3(-8.85, UP, zf))
	railing(Vector3(8.85, UP, za), Vector3(8.85, UP, zf))
	railing(Vector3(-8.85, UP, za + 0.1), Vector3(-7.3, UP, za + 0.1))
	railing(Vector3(-5.7, UP, za + 0.1), Vector3(5.7, UP, za + 0.1))
	railing(Vector3(7.3, UP, za + 0.1), Vector3(8.85, UP, za + 0.1))
	railing(Vector3(-8.85, UP, zf - 0.1), Vector3(-5.3, UP, zf - 0.1))
	railing(Vector3(-3.7, UP, zf - 0.1), Vector3(3.7, UP, zf - 0.1))
	railing(Vector3(5.3, UP, zf - 0.1), Vector3(8.85, UP, zf - 0.1))
	# stairs: stern (main -> upper) and bow (main -> upper)
	for s: float in [-1.0, 1.0]:
		k.stairs(Vector3(s * 6.5, 0.0, za - 5.04), Vector3(0, 0, 1), 1.4, UP, 18, "l26_steel", 0.28)
		railing(Vector3(s * 6.5 + 0.75, 0.0, za - 5.04), Vector3(s * 6.5 + 0.75, UP, za), 1.0, false)
		k.stairs(Vector3(s * 4.5, 0.0, zf + 5.04), Vector3(0, 0, -1), 1.4, UP, 18, "l26_steel", 0.28)
		railing(Vector3(s * 4.5 + s * 0.75, 0.0, zf + 5.04), Vector3(s * 4.5 + s * 0.75, UP, zf), 1.0, false)
	# elevator housing on the upper deck
	k.box_mm(Vector3(-3.5, UP, 13.0), Vector3(3.5, UP + 2.9, zf - 0.2), "l26_white", GeoKit.ALL, true)
	for x: float in [-1.6, 1.6]:
		elevator_doors(Vector3(x, UP, 12.98), Vector3(0, 0, -1))
	lamp_points.append([Vector3(0, UP + 2.4, 12.0), Color(1.0, 0.9, 0.75), 0.7, 5.0, 0.0])
	deckhouse()
	lifeboats()
	pool_dressing()
	stern_party()


## Restaurant (forward), bar and lounge (aft) in one glazed deckhouse; its roof is the sun deck.
func deckhouse() -> void:
	var x0 := -5.0
	var x1 := 5.0
	var z0 := -30.0
	var z1 := 12.0
	var h := SUN - UP - 0.2
	for s: float in [-1.0, 1.0]:
		var ops: Array = []
		var z := 1.5
		while z < (z1 - z0) - 1.0:
			ops.append({"at": z, "w": 2.2, "h": 1.4, "sill": 0.9})
			z += 3.2
		ops.append({"at": 10.0, "w": 1.2, "h": 2.2, "sill": 0.0})
		ops.append({"at": 34.0, "w": 1.2, "h": 2.2, "sill": 0.0})
		ops.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
		var clean: Array = []
		for o in ops:
			if o["sill"] > 0.0 and (absf(float(o["at"]) - 10.0) < 1.9 or absf(float(o["at"]) - 34.0) < 1.9):
				continue
			clean.append(o)
		k.wall(Vector3(s * x1, UP, z0), Vector3(s * x1, UP, z1), h, T, "l26_white", clean)
		for o in clean:
			if float(o["sill"]) > 0.0:
				d.box(Vector3(s * x1, UP + 1.6, z0 + float(o["at"])), Vector3(0.04, 1.4, 2.2), "glass", GeoKit.ALL, false)
	k.wall(Vector3(x0, UP, z0), Vector3(x1, UP, z0), h, T, "l26_white", [{"at": 2.0, "w": 1.2, "h": 2.2}, {"at": 8.0, "w": 1.2, "h": 2.2}])
	k.wall(Vector3(x0, UP, z1), Vector3(x1, UP, z1), h, T, "l26_white", [{"at": 5.0, "w": 3.0, "h": 2.2, "sill": 0.9}])
	d.box(Vector3(0, UP + 1.6, z1), Vector3(3.0, 1.4, 0.04), "glass", GeoKit.ALL, false)
	# partition between the bar/lounge and the restaurant
	k.wall(Vector3(x0, UP, -6.0), Vector3(x1, UP, -6.0), h, 0.15, "l26_wallpaper", [{"at": 5.0, "w": 3.2, "h": 2.4}])
	k.box_mm(Vector3(x0 + 0.1, UP, z0), Vector3(x1 - 0.1, UP + 0.02, z1), "l26_carpet", GeoKit.PY, false)
	# the sun deck on its roof
	k.slab(x0 - 0.4, z0 - 0.4, x1 + 0.4, z1 + 0.4, SUN, 0.2, "l26_deck")
	for i in 6:
		var lz := z0 + 3.5 + i * 7.0
		d.panel(Vector3(0, SUN - 0.21, lz), 1.0, 0.6, "l26_fixture")
		lamp_points.append([Vector3(0, SUN - 0.6, lz), Color(1.0, 0.86, 0.66), 1.0, 6.5, 0.0])
	# restaurant: tables, chairs knocked over, broken plates
	for row in 3:
		for col in 2:
			var tp := Vector3(-2.3 + col * 4.6, UP, -2.5 + row * 4.4)
			_p("ph/dining_table", tp, 90.0 + rng.randf_range(-12, 12), 0.0, true)
			for c in 4:
				var a := TAU * c / 4.0 + rng.randf() * 0.4
				var cp := tp + Vector3(cos(a) * 1.2, 0, sin(a) * 0.9)
				var ch := _p("ph/dining_chair_02", cp, rad_to_deg(a) + 90.0 + rng.randf_range(-30, 30))
				if ch and rng.randf() < 0.35:
					ch.rotation.x = PI * 0.5
					ch.position.y += 0.22
			for i in 3:
				_p("kenney/food-kit/plate-broken" if rng.randf() < 0.5 else "kenney/food-kit/cup", tp + Vector3(rng.randf_range(-0.8, 0.8), 0.88, rng.randf_range(-0.4, 0.4)), rng.randf() * 360.0, 0.04)
	# bar and lounge (aft half): bar counter with stools, sofas, armchairs, trash
	k.box(Vector3(-3.8, UP + 0.55, -18.0), Vector3(0.7, 1.1, 7.0), "l26_cabin_door", GeoKit.ALL, true)
	d.box(Vector3(-3.8, UP + 1.12, -18.0), Vector3(0.9, 0.06, 7.2), "l26_brass", GeoKit.ALL, false)
	d.box(Vector3(-4.85, UP + 1.6, -18.0), Vector3(0.2, 1.4, 6.0), "l26_glass_dark", GeoKit.ALL, false)
	d.box(Vector3(-4.82, UP + 2.4, -18.0), Vector3(0.06, 0.12, 4.0), "l26_neon_pink", GeoKit.ALL, false)
	for i in 6:
		var sp := Vector3(-2.9, UP, -21.0 + i * 1.2)
		var st := _p("ph/bar_chair_round_01", sp, rng.randf() * 360.0)
		if st and i % 3 == 1:
			st.rotation.z = PI * 0.5
			st.position.y += 0.25
	for i in 8:
		_p("kenney/food-kit/soda-bottle", Vector3(-4.85, UP + 1.2 + (i % 2) * 0.4, -20.5 + i * 0.6), 0.0, 0.3)
	_p("ph/Sofa_01", Vector3(2.6, UP, -24.0), -90.0, 0.0, true)
	_p("ph/Sofa_01", Vector3(2.6, UP, -14.0), -90.0 + 12.0, 0.0, true)
	_p("ph/ArmChair_01", Vector3(0.6, UP, -26.5), 150.0)
	_p("ph/ArmChair_01", Vector3(0.2, UP, -11.0), 30.0)
	_p("ph/coffee_table_round_01", Vector3(1.2, UP, -19.0), 0.0, 0.0, true)
	_p("kenney/furniture-kit/speaker", Vector3(4.3, UP, -28.6), 200.0, 1.3)
	_p("kenney/furniture-kit/speaker", Vector3(4.3, UP, -7.2), -20.0, 1.3)
	lamp_points.append([Vector3(-3.0, UP + 2.4, -18.0), Color(1.0, 0.3, 0.6), 1.2, 6.0, 0.2])
	music_points.append(Vector3(4.0, UP + 1.5, -18.0))
	for i in 10:
		var tid: String = ["ph/trashbag", "kenney/food-kit/pizza-box", "kenney/food-kit/soda-can-crushed", "kenney/food-kit/cup"][rng.randi() % 4]
		_p(tid, Vector3(rng.randf_range(-2.0, 4.4), UP, rng.randf_range(-29.0, -7.0)), rng.randf() * 360.0, 0.0 if tid.begins_with("ph") else 0.09)
	for i in 4:
		splats.append([Vector3(rng.randf_range(-2.5, 4.0), UP + 0.025, rng.randf_range(-28.0, 10.0)), rng.randf_range(0.5, 1.1)])


func lifeboats() -> void:
	for s: float in [-1.0, 1.0]:
		for z: float in [-30.0, -14.0, 2.0]:
			var c := Vector3(s * 10.0, UP + 1.9, z)
			d.box(c, Vector3(1.9, 1.0, 6.0), "l26_boat", GeoKit.ALL, false)
			d.box(c + Vector3(0, 0.55, 0), Vector3(1.6, 0.25, 5.4), "l26_white", GeoKit.ALL, false)
			for e: float in [-1.0, 1.0]:
				d.box_xf(Transform3D(Basis(Vector3.UP, 0.0), c + Vector3(0, -0.15, e * 3.3)), Vector3(1.3, 0.7, 0.8), "l26_boat", GeoKit.ALL, false)
				# davits
				d.box(Vector3(s * 9.0, UP + 1.6, z + e * 2.6), Vector3(0.18, 3.2, 0.18), "l26_steel", GeoKit.ALL, false)
				d.box(Vector3(s * 9.6, UP + 3.15, z + e * 2.6), Vector3(1.4, 0.16, 0.16), "l26_steel", GeoKit.ALL, false)


## The stern deck under the pool: where the party spills out.
func stern_party() -> void:
	for i in 3:
		var tp := Vector3(-3.0 + i * 3.0, 0, -65.0 + (i % 2) * 2.0)
		_p("ph/wooden_picnic_table", tp, rng.randf_range(-20, 20) + 90.0, 0.0, true)
		for j in 4:
			_p(["kenney/food-kit/cup", "kenney/food-kit/soda-bottle", "kenney/food-kit/plate-broken", "kenney/food-kit/pizza-box"][j],
				tp + Vector3(rng.randf_range(-0.8, 0.8), 0.76, rng.randf_range(-0.3, 0.3)), rng.randf() * 360.0, [0.1, 0.25, 0.04, 0.06][j])
	for s: float in [-1.0, 1.0]:
		_p("kenney/furniture-kit/speaker", Vector3(s * 3.8, 0, -58.5), 180.0 + s * 20.0, 1.4)
		_p("ph/plastic_monobloc_chair_01", Vector3(s * 2.0, 0, -61.5), rng.randf() * 360.0)
	var ch := _p("ph/plastic_monobloc_chair_01", Vector3(0.6, 0, -69.0), 40.0)
	if ch:
		ch.rotation.z = PI * 0.5
		ch.position.y += 0.3
	for i in 5:
		_p("ph/trashbag", Vector3(-7.6 + rng.randf_range(-0.3, 0.3), 0, -57.5 + i * 0.6), rng.randf() * 360.0)
	# fixtures under the overhang
	for x: float in [-6.5, -2.0, 2.0, 6.5]:
		for z: float in [-53.5, -47.5]:
			d.panel(Vector3(x, UP - 0.21, z), 0.5, 0.5, "l26_fixture")
			lamp_points.append([Vector3(x, UP - 0.6, z), Color(1.0, 0.9, 0.75), 0.8, 5.5, 0.0 if x != 2.0 else 0.4])
	# a crude banner on the aft rail of the upper deck
	var bp := Vector3(0, UP + 0.65, -56.2)
	d.box(bp, Vector3(6.0, 0.9, 0.02), "l26_cloth", GeoKit.ALL, false)
	label("SS FUN =)", bp + Vector3(0, 0, -0.012), Vector3(0, 0, -1), 0.011, Color(0.8, 0.08, 0.1), 64)
	music_points.append(Vector3(0, 1.2, -58.0))


func pool_dressing() -> void:
	var c := Vector3(POOL.get_center().x, UP, POOL.get_center().y)
	for i in 7:
		var side := -1.0 if i % 2 == 0 else 1.0
		var lp := c + Vector3(side * 5.6, 0, -3.2 + i * 1.2)
		var ch := _p("kenney/furniture-kit/loungechairrelax", lp, 90.0 * side + rng.randf_range(-25, 25), 0.75)
		if ch and rng.randf() < 0.3:
			ch.rotation.z = 0.9
	for i in 2:
		var up := c + Vector3(-6.2 + i * 12.4, 0, 2.0)
		d.box(up + Vector3(0, 1.2, 0), Vector3(0.05, 2.4, 0.05), "l26_steel", GeoKit.ALL, false)
		d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.35 if i == 0 else -0.5), up + Vector3(0, 2.35, 0)), Vector3(2.2, 0.06, 2.2), "l26_stripe", GeoKit.ALL, false)
	for i in 6:
		splats.append([c + Vector3(rng.randf_range(-6.5, 6.5), 0.025, rng.randf_range(-5.0, 5.0)), rng.randf_range(0.5, 1.2)])
	for i in 6:
		_p(["ph/trashbag", "kenney/food-kit/soda-can-crushed", "kenney/food-kit/pizza-box", "ph/plastic_crate_01"][i % 4],
			c + Vector3(rng.randf_range(-7.5, 7.5), 0, rng.randf_range(-1.5, 7.0)), rng.randf() * 360.0, 0.0 if i % 4 == 0 or i % 4 == 3 else 0.08)
	_p("ph/lifebuoy", Vector3(-8.75, UP + 0.6, -50.0), 90.0)
	_p("ph/lifebuoy", Vector3(8.75, UP + 0.6, -42.0), -90.0)


# ------------------------------------------------------------------ sun deck and foredeck

## The top of the ship: nowhere higher to go. Remnants of an open-air bar, broken lounge
## furniture, posters. No Partygoers come up here (testimony).
func sun_deck() -> Dictionary:
	var y := SUN
	railing(Vector3(-5.35, y, -30.35), Vector3(-5.35, y, 12.35))
	railing(Vector3(5.35, y, -30.35), Vector3(5.35, y, 12.35))
	railing(Vector3(-5.35, y, 12.35), Vector3(5.35, y, 12.35))
	railing(Vector3(-5.35, y, -30.35), Vector3(-0.9, y, -30.35))
	railing(Vector3(0.9, y, -30.35), Vector3(5.35, y, -30.35))
	k.stairs(Vector3(0, UP, -35.44), Vector3(0, 0, 1), 1.6, SUN - UP, 18, "l26_steel", 0.28)
	railing(Vector3(-0.85, UP, -35.44), Vector3(-0.85, SUN, -30.4), 1.0, false)
	railing(Vector3(0.85, UP, -35.44), Vector3(0.85, SUN, -30.4), 1.0, false)
	# the funnel: white, red band, black top
	var fz := -4.0
	k.box(Vector3(0, y + 3.0, fz), Vector3(3.4, 6.0, 7.0), "l26_funnel", GeoKit.ALL, true)
	d.box(Vector3(0, y + 4.6, fz), Vector3(3.46, 1.0, 7.06), "l26_funnel_red", GeoKit.ALL, false)
	d.box(Vector3(0, y + 6.15, fz), Vector3(3.5, 0.3, 7.1), "l26_black", GeoKit.ALL, false)
	label("SS Fun =)", Vector3(1.74, y + 3.0, fz), Vector3(1, 0, 0), 0.016, Color(0.7, 0.06, 0.05), 96)
	# open-air bar remnant forward of the funnel
	k.box(Vector3(0, y + 0.55, 6.5), Vector3(4.0, 1.1, 0.7), "l26_cabin_door", GeoKit.ALL, true)
	d.box(Vector3(0, y + 1.12, 6.5), Vector3(4.2, 0.06, 0.9), "l26_brass", GeoKit.ALL, false)
	for i in 4:
		var bp := Vector3(-1.5 + i * 1.0, y, 7.6)
		var st := _p("ph/bar_chair_round_01", bp, rng.randf() * 360.0)
		if st and i % 2 == 0:
			st.rotation.x = PI * 0.5
			st.position.y += 0.24
	d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.2), Vector3(0, y + 2.4, 6.5)), Vector3(4.6, 0.06, 2.0), "l26_stripe", GeoKit.ALL, false)
	for x: float in [-2.2, 2.2]:
		d.box(Vector3(x, y + 1.2, 6.0), Vector3(0.08, 2.4, 0.08), "l26_steel", GeoKit.ALL, false)
	# broken loungers, an overturned table
	for i in 8:
		var lp := Vector3(rng.randf_range(-4.2, 4.2), y, rng.randf_range(-28.0, -10.0))
		var ch := _p("kenney/furniture-kit/loungechairrelax", lp, rng.randf() * 360.0, 0.75)
		if ch and i % 3 == 0:
			ch.rotation.z = PI * 0.5
			ch.position.y += 0.3
	_p("ph/coffee_table_round_01", Vector3(3.2, y, 2.0), 0.0)
	# the poster wall: a windbreak by the bar, covered in party posters
	var pw := Vector3(-3.9, y, 9.6)
	k.box(pw + Vector3(0, 1.1, 0), Vector3(2.8, 2.2, 0.12), "l26_hull_band", GeoKit.ALL, true)
	k.box(Vector3(3.9, y + 1.1, 9.6), Vector3(2.8, 2.2, 0.12), "l26_hull_band", GeoKit.ALL, true)
	return {"poster_wall": pw, "funnel_z": fz}


## Party paraphernalia over the open decks: confetti, hats, balloon bunches tied to rails,
## trash. Returns [confetti points, hat points, balloon points] for the level's MultiMeshes.
func party_debris() -> Array:
	var zones := [[Rect2(-8.5, -72.0, 17.0, 11.5), 0.0], [Rect2(6.7, -40.0, 2.0, 88.0), 0.0], [Rect2(-8.7, -40.0, 2.0, 88.0), 0.0],
		[Rect2(-7.0, 17.0, 14.0, 34.0), 0.0], [Rect2(-8.5, -55.5, 17.0, 70.0), UP], [Rect2(-5.0, -30.0, 10.0, 42.0), SUN]]
	var conf: Array = []
	var hats: Array = []
	for zz in zones:
		var r: Rect2 = zz[0]
		var y: float = zz[1]
		var n := int(r.get_area() * 3.0)
		for i in n:
			var p := Vector3(rng.randf_range(r.position.x, r.end.x), y + 0.012, rng.randf_range(r.position.y, r.end.y))
			if y == UP and POOL.grow(0.2).has_point(Vector2(p.x, p.z)):
				continue
			if y == UP and absf(p.x) < 5.0 and p.z > -30.0 and p.z < 12.0:
				continue
			conf.append(p)
		for i in int(r.get_area() / 14.0):
			var hp := Vector3(rng.randf_range(r.position.x, r.end.x), y + 0.05, rng.randf_range(r.position.y, r.end.y))
			if y == UP and POOL.grow(0.2).has_point(Vector2(hp.x, hp.z)):
				continue
			hats.append(hp)
		for i in int(r.get_area() / 30.0):
			var tid: String = ["ph/trashbag", "kenney/food-kit/soda-can-crushed", "kenney/food-kit/pizza-box", "kenney/food-kit/cup", "kenney/food-kit/soda-bottle"][rng.randi() % 5]
			var tp := Vector3(rng.randf_range(r.position.x, r.end.x), y, rng.randf_range(r.position.y, r.end.y))
			if y == UP and (POOL.grow(0.4).has_point(Vector2(tp.x, tp.z)) or (absf(tp.x) < 5.3 and tp.z > -30.3 and tp.z < 12.3)):
				continue
			var hh := 0.0
			if not tid.begins_with("ph"):
				hh = 0.12 if tid.ends_with("box") else 0.2
			_p(tid, tp, rng.randf() * 360.0, hh)
		for i in int(r.get_area() / 60.0) + 1:
			splats.append([Vector3(rng.randf_range(r.position.x, r.end.x), y + 0.015, rng.randf_range(r.position.y, r.end.y)), rng.randf_range(0.4, 1.0)])
	var bunches: Array = []
	for spec in [[Vector3(-8.85, 1.1, -64.0)], [Vector3(8.85, 1.1, -64.0)], [Vector3(-8.85, UP + 1.1, -45.0)], [Vector3(8.85, UP + 1.1, -36.0)],
			[Vector3(-5.35, SUN + 1.1, -14.0)], [Vector3(5.35, SUN + 1.1, -22.0)], [Vector3(-8.85, 1.1, 30.0)], [Vector3(8.85, 1.1, -20.0)]]:
		var base: Vector3 = spec[0]
		for i in 6:
			var bp := base + Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(0.7, 1.3), rng.randf_range(-0.4, 0.4))
			bunches.append(bp)
			var dvec := bp - base
			var z := dvec.normalized()
			var x := Vector3.RIGHT if absf(z.x) < 0.9 else Vector3.FORWARD
			x = x.cross(z).normalized()
			d.box_xf(Transform3D(Basis(x, z.cross(x), z), (base + bp) * 0.5), Vector3(0.006, 0.006, dvec.length()), "l26_white", GeoKit.ALL, false)
	return [conf, hats, bunches]


func foredeck() -> void:
	# hatch covers, bollards, a winch, the foremast with strings of party lights
	for z: float in [26.0, 33.0]:
		k.box(Vector3(0, 0.35, z), Vector3(5.0, 0.7, 4.0), "l26_steel", GeoKit.ALL, true)
	for s: float in [-1.0, 1.0]:
		for z: float in [22.0, 44.0, 58.0]:
			var w := 7.6 if z < 50.0 else 5.6
			k.cylinder(Vector3(s * w, 0.3, z), 0.18, 0.6, "l26_black", 10, true)
			k.cylinder(Vector3(s * w, 0.3, z + 0.6), 0.18, 0.6, "l26_black", 10, true)
	k.box(Vector3(0, 0.6, 52.0), Vector3(3.0, 1.2, 1.8), "l26_steel", GeoKit.ALL, true)
	k.cylinder(Vector3(0, 6.0, 40.0), 0.22, 12.0, "l26_white", 12, true)
	d.box(Vector3(0, 9.0, 40.0), Vector3(3.0, 0.15, 0.15), "l26_white", GeoKit.ALL, false)


## Light points of the party strings: mast to the bridge front, around the sun deck rail.
func string_lights() -> Array:
	var pts: Array = []
	for s: float in [-1.0, 1.0]:
		var a := Vector3(0, 11.8, 40.0)
		var b := Vector3(s * 8.6, UP + 1.2, 16.0)
		for i in 26:
			var t := float(i) / 25.0
			var p := a.lerp(b, t)
			p.y -= sin(t * PI) * 1.4
			pts.append(p)
		var c := Vector3(0, 11.8, 40.0)
		var e := Vector3(s * 6.0, 1.15, 58.0)
		for i in 20:
			var t2 := float(i) / 19.0
			var p2 := c.lerp(e, t2)
			p2.y -= sin(t2 * PI) * 1.0
			pts.append(p2)
	for s: float in [-1.0, 1.0]:
		var a4 := Vector3(s * 8.8, UP - 0.25, -56.2)
		var b4 := Vector3(-s * 6.0, 1.15, -72.0)
		for i in 22:
			var t4 := float(i) / 21.0
			var p4 := a4.lerp(b4, t4)
			p4.y -= sin(t4 * PI) * 0.8
			pts.append(p4)
	for i in 40:
		var t3 := float(i) / 39.0
		pts.append(Vector3(-5.3, SUN + 1.2 - sin(fmod(t3 * 6.0, 1.0) * PI) * 0.3, lerpf(-30.0, 12.0, t3)))
		pts.append(Vector3(5.3, SUN + 1.2 - sin(fmod(t3 * 6.0, 1.0) * PI) * 0.3, lerpf(-30.0, 12.0, t3)))
	return pts
