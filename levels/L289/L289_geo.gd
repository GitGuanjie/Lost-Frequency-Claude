extends "res://levels/L289/L289_kit.gd"
## Level 289 geometry: streamed 16 m chunks of a flooded, badly built basement
## (see L289.gd for the source mapping). Each chunk holds one waist-deep water
## volume, a 2x2 grid of 8 m structural bays (columns, downstand beams, a
## stained slab soffit) and the scaffolding that is "everywhere" (pieces in
## L289_kit.gd). Authored chunks: (0,0) arrival + abandoned hideout, and the
## stair core whose door is stencilled with the corrupted level number.


func _init(level: Node3D) -> void:
	super(level)


func chunk(cx: int, cz: int, n: Node3D) -> Dictionary:
	var key := Vector2i(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([L.level_seed, cx, cz, 289])
	var o := Vector3(cx * CS, 0, cz * CS)
	var kind: String = L.kind_of(key)
	var grp := "%d,%d" % [cx, cz]
	var meta := {"kind": kind}
	var k := GeoKit.new(n, "K")
	var w := WaterVolume.new()
	n.add_child(w)
	w.setup(o + Vector3(0, DEEP - 0.6, 0), o + Vector3(CS, SURF, CS), "l289_water")
	w.fog_color = Color(0.06, 0.06, 0.03)
	w.fog_density = 0.6
	w.tint = Color(0.26, 0.25, 0.12)
	var hole := Rect2()
	var shaft := 0.0
	var sunk: Array = []
	var bays := {}
	match kind:
		"well":
			hole = Rect2(4, 4, 8, 8)
			shaft = 9.0
		"stair":
			hole = Rect2(9.3, 1.2, 2.6, 11.2)
		"collapse":
			var bx := r.randi_range(0, 1)
			var bz := r.randi_range(0, 1)
			hole = Rect2(bx * 8 + 0.6, bz * 8 + 0.6, 6.8, 6.8)
			shaft = 3.5
			bays[Vector2i(bx, bz)] = "collapse"
			meta["collapse_c"] = o + Vector3(bx * 8 + 4, 0, bz * 8 + 4)
		"sump":
			sunk.append(Vector2i(r.randi_range(0, 1), r.randi_range(0, 1)))
			if r.randf() < 0.45:
				var s2: Vector2i = sunk[0] + (Vector2i(1 - 2 * sunk[0].x, 0) if r.randf() < 0.5 else Vector2i(0, 1 - 2 * sunk[0].y))
				sunk.append(s2)
			for s in sunk:
				bays[s] = "sump"
	# floor (per bay, so sumps can drop)
	for bz in 2:
		for bx in 2:
			var b := o + Vector3(bx * 8, 0, bz * 8)
			var fy := DEEP if Vector2i(bx, bz) in sunk else 0.0
			k.slab(b.x, b.z, b.x + 8, b.z + 8, fy, 0.3, "l289_silt", GeoKit.PY, "water")
	ceiling(k, o, hole, shaft)
	# columns and downstand beams on the 8 m grid
	for c: Vector2 in [Vector2(0, 0), Vector2(8, 0), Vector2(0, 8), Vector2(8, 8)]:
		if _in_hole(hole, c.x, c.y, 0.2):
			continue
		k.box_mm(o + Vector3(c.x - 0.26, DEEP - 0.1, c.y - 0.26), o + Vector3(c.x + 0.26, H, c.y + 0.26), "l289_wall", GeoKit.SIDES)
		tide(k, o + Vector3(c.x - 0.26, 0, c.y - 0.26), o + Vector3(c.x + 0.26, 0, c.y + 0.26))
	for zb: float in [0.0, 8.0]:
		_beam(k, o, hole, true, zb)
	for xb: float in [0.0, 8.0]:
		_beam(k, o, hole, false, xb)
	_pipes(k, o, cx, cz, hole)
	match kind:
		"start":
			_start(k, o, grp, r)
		"stair":
			meta.merge(_stair_core(k, o, n, grp))
			_frame(k, o + Vector3(0, 0, 0), true, 5.6, r, grp, 0.5)
			_props(k, o + Vector3(0, 0, 8), r, 2)
		"well":
			_tower(k, o, grp, r)
		_:
			for bz in 2:
				for bx in 2:
					var bk := Vector2i(bx, bz)
					var b := o + Vector3(bx * 8, 0, bz * 8)
					match bays.get(bk, ""):
						"sump":
							_sump(k, b, r)
						"collapse":
							_collapse(k, b, r)
						_:
							_bay(k, b, cx * 2 + bx, cz * 2 + bz, r, grp)
	_debris(k, o, r, hole)
	k.commit()
	return meta


## The only exit: a concrete stair core climbing out of the water to a steel
## door whose stencil reads the corrupted level number. Beyond it: nothing lit.
func _stair_core(k: GeoKit, o: Vector3, n: Node3D, grp: String) -> Dictionary:
	var cx := o.x + 10.6
	var top := STAIR_Y + 3.6
	k.wall(o + Vector3(9.45, 0, 3.0), o + Vector3(9.45, 0, 12.4), top, 0.3, "l289_block",
		[{"at": 5.6, "w": 4.6, "h": 2.6, "sill": 0.0}, {"at": 1.6, "w": 1.4, "h": 1.2, "sill": STAIR_Y + 0.9}])
	k.wall(o + Vector3(11.75, 0, 3.0), o + Vector3(11.75, 0, 12.4), top, 0.3, "l289_block")
	tide(k, o + Vector3(11.6, 0, 3.0), o + Vector3(11.9, 0, 12.4), GeoKit.PX)
	tide(k, o + Vector3(9.3, 0, 3.0), o + Vector3(9.6, 0, 6.3), GeoKit.NX)
	tide(k, o + Vector3(9.3, 0, 10.9), o + Vector3(9.6, 0, 12.4), GeoKit.NX)
	tide(k, o + Vector3(9.3, 0, 12.1), o + Vector3(9.6, 0, 12.4), GeoKit.PZ)
	tide(k, o + Vector3(11.6, 0, 12.1), o + Vector3(11.9, 0, 12.4), GeoKit.PZ)
	k.wall(o + Vector3(9.3, 0, 12.25), o + Vector3(11.9, 0, 12.25), top, 0.3, "l289_block", [{"at": 1.3, "w": 2.0, "h": 3.0, "sill": 0.0}])
	k.wall(o + Vector3(9.3, 0, 3.15), o + Vector3(11.9, 0, 3.15), top, 0.3, "l289_wall", [{"at": 1.3, "w": 1.0, "h": 2.1, "sill": STAIR_Y}])
	k.slab(o.x + 9.3, o.z + 3.0, o.x + 11.9, o.z + 12.4, top + 0.3, 0.3, "l289_ceiling", GeoKit.NY | GeoKit.PY)
	k.stairs(Vector3(cx, 0.0, o.z + 12.0), Vector3(0, 0, -1), 2.0, STAIR_Y, 18, "l289_wall", 0.28, true)
	k.slab(o.x + 9.6, o.z + 3.3, o.x + 11.6, o.z + 6.96, STAIR_Y, STAIR_Y + 0.3, "l289_wall", GeoKit.PY | GeoKit.PX | GeoKit.NX)
	# handrail
	tube(k, Vector3(o.x + 11.5, 0.9, o.z + 12.0), Vector3(o.x + 11.5, STAIR_Y + 0.9, o.z + 6.96), 0.025, "l289_tube")
	tube(k, Vector3(o.x + 11.5, STAIR_Y + 0.9, o.z + 6.96), Vector3(o.x + 11.5, STAIR_Y + 0.9, o.z + 3.4), 0.025, "l289_tube")
	# vestibule beyond the door: unlit, matte black
	k.slab(o.x + 9.8, o.z + 1.5, o.x + 11.4, o.z + 3.3, STAIR_Y, 0.3, "void_black", GeoKit.ALL)
	k.box_mm(Vector3(o.x + 9.6, STAIR_Y, o.z + 1.3), Vector3(o.x + 9.8, STAIR_Y + 2.6, o.z + 3.0), "void_black")
	k.box_mm(Vector3(o.x + 11.4, STAIR_Y, o.z + 1.3), Vector3(o.x + 11.6, STAIR_Y + 2.6, o.z + 3.0), "void_black")
	k.box_mm(Vector3(o.x + 9.6, STAIR_Y, o.z + 1.3), Vector3(o.x + 11.6, STAIR_Y + 2.6, o.z + 1.5), "void_black")
	k.box_mm(Vector3(o.x + 9.6, STAIR_Y + 2.6, o.z + 1.3), Vector3(o.x + 11.6, STAIR_Y + 2.8, o.z + 3.0), "void_black")
	# door leaf, swung in against the vestibule wall; frame
	k.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(-100.0)), Vector3(o.x + 10.15, STAIR_Y + 1.05, o.z + 2.55)), Vector3(0.95, 2.05, 0.05), "l289_door_metal", GeoKit.ALL, false)
	for sx: float in [-0.53, 0.53]:
		k.box(Vector3(cx + sx, STAIR_Y + 1.06, o.z + 3.31), Vector3(0.06, 2.12, 0.04), "l289_door_metal", GeoKit.ALL, false)
	k.box(Vector3(cx, STAIR_Y + 2.13, o.z + 3.31), Vector3(1.12, 0.06, 0.04), "l289_door_metal", GeoKit.ALL, false)
	# landing lamp: the only steady light in the area, spilling down the flight
	var rr := RandomNumberGenerator.new()
	rr.seed = 289
	lamp(k, Vector3(cx, STAIR_Y + 2.7, o.z + 5.6), grp, rr, 0.0, 1.25)
	L.lights.add_anchor(Vector3(cx, 2.3, o.z + 11.0), Color(1.0, 0.72, 0.42), 1.0, 6.0, 0.0, grp)
	var door := Vector3(cx, STAIR_Y, o.z + 3.15)
	var lb := Label3D.new()
	lb.text = "LEVEL\n14444444-\n£÷¥π÷ππ^÷\n¢|}≠{=/~"
	lb.font_size = 64
	lb.pixel_size = 0.0042
	lb.line_spacing = -6.0
	lb.modulate = Color(0.32, 0.06, 0.04)
	lb.outline_size = 0
	lb.position = door + Vector3(0, 2.86, 0.165)
	lb.shaded = true
	n.add_child(lb)
	var loops := int(L.loops)
	var tally := 7 + loops
	for i in tally:
		var gx := floorf(i / 5.0) * 0.42 + (i % 5) * 0.07
		var p := Vector3(o.x + 11.59, STAIR_Y + 1.35, o.z + 4.0 + gx)
		if i % 5 == 4:
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.95), p + Vector3(0, 0, -0.14)), Vector3(0.01, 0.42, 0.018), "l289_chalk", GeoKit.ALL, false)
		else:
			k.box(p, Vector3(0.01, 0.34, 0.018), "l289_chalk", GeoKit.ALL, false)
	var ex: ExitTrigger = L.make_exit("L289>EXT#1", "walk_in", Vector3(cx, STAIR_Y + 1.0, o.z + 2.25), Vector3(1.4, 2.0, 1.0), "", n)
	if ex:
		ex.fired.connect(L.on_loop_exit)
	var draft := AudioStreamPlayer3D.new()
	draft.stream = AudioSynth.get_stream("wind", {"cutoff": 300.0})
	draft.volume_db = -14.0
	draft.max_distance = 22.0
	draft.bus = "Ambience"
	draft.position = door + Vector3(0, 1.2, 1.0)
	draft.autoplay = true
	n.add_child(draft)
	return {"door": door, "arrival": Vector3(cx, STAIR_Y + 0.05, o.z + 4.7)}


# ------------------------------------------------------------ start chunk

## Arrival chunk: a damaged door in the south partition (from Level 19), the
## west block wall (no-clip arrivals from Level 13), the abandoned hideout on
## a scaffold deck, and the radio lying in the water.
func _start(k: GeoKit, o: Vector3, grp: String, r: RandomNumberGenerator) -> void:
	k.wall(o + Vector3(0.0, 0, 15.85), o + Vector3(8.0, 0, 15.85), H, 0.2, "l289_block", [{"at": 4.0, "w": 0.95, "h": 2.05, "sill": 0.0}])
	k.wall(o + Vector3(0.15, 0, 0.3), o + Vector3(0.15, 0, 7.7), H, 0.2, "l289_block")
	tide(k, o + Vector3(0.05, 0, 0.3), o + Vector3(0.25, 0, 7.7))
	tide(k, o + Vector3(0.0, 0, 15.75), o + Vector3(3.52, 0, 15.95))
	tide(k, o + Vector3(4.48, 0, 15.75), o + Vector3(8.0, 0, 15.95))
	for sx: float in [-0.5, 0.5]:
		k.box(o + Vector3(4.0 + sx, 1.05, 15.72), Vector3(0.06, 2.1, 0.06), "l289_door_metal", GeoKit.ALL, false)
	k.box(o + Vector3(4.0, 2.08, 15.72), Vector3(1.06, 0.06, 0.06), "l289_door_metal", GeoKit.ALL, false)
	var leaf := Basis(Vector3.UP, deg_to_rad(64.0)) * Basis(Vector3.FORWARD, deg_to_rad(7.0))
	k.box_xf(Transform3D(leaf, o + Vector3(3.73, 1.0, 15.28)), Vector3(0.9, 1.98, 0.045), "l289_door_metal", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.3).rotated(Vector3.RIGHT, 1.35), o + Vector3(4.7, SURF + 0.01, 14.4)), Vector3(0.42, 0.6, 0.03), "l289_door_metal", GeoKit.ALL, false)
	_frame(k, o, true, 6.2, r, grp, 0.0)
	_frame(k, o + Vector3(8, 0, 8), true, 1.4, r, grp, 0.0)
	prop(k, o + Vector3(1.6, 0, 10.2), r)
	prop(k, o + Vector3(2.5, 0, 13.9), r)
	# hideout deck (bay x 8..16, z 0..8)
	var d0 := o + Vector3(9.2, 0, 1.2)
	var d1 := o + Vector3(14.8, 0, 5.0)
	k.slab(d0.x, d0.z, d1.x, d1.z, DECK, 0.08, "l289_board_wood", GeoKit.ALL, "wood")
	k.stairs(o + Vector3(12.0, 0, 7.0), Vector3(0, 0, -1), 1.0, DECK, 7, "l289_board_wood", 0.28, false)
	for sx: float in [d0.x, (d0.x + d1.x) * 0.5, d1.x]:
		for sz: float in [d0.z, d1.z]:
			tube(k, Vector3(sx, 0.02, sz), Vector3(sx, H - 0.55, sz), 0.026, "l289_tube")
			k.add_box_shape(Transform3D(Basis(), Vector3(sx, 0.6, sz)), Vector3(0.07, 1.2, 0.07), "metal")
	for hgt: float in [0.5, 1.0]:
		tube(k, Vector3(d0.x, DECK + hgt, d0.z), Vector3(d1.x, DECK + hgt, d0.z), 0.022, "l289_tube")
		tube(k, Vector3(d1.x, DECK + hgt, d0.z), Vector3(d1.x, DECK + hgt, d1.z), 0.022, "l289_tube")
	k.add_box_shape(Transform3D(Basis(), Vector3((d0.x + d1.x) * 0.5, DECK + 0.55, d0.z)), Vector3(d1.x - d0.x, 1.1, 0.06), "metal")
	k.add_box_shape(Transform3D(Basis(), Vector3(d1.x, DECK + 0.55, (d0.z + d1.z) * 0.5)), Vector3(0.06, 1.1, d1.z - d0.z), "metal")
	# tarp strung under the slab as a drip shield
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.08), Vector3((d0.x + d1.x) * 0.5, 3.25, (d0.z + d1.z) * 0.5)), Vector3(5.9, 0.02, 4.2), "l289_tarp", GeoKit.ALL, false)
	# packed-up camp: bags, bedrolls, a crate with the terminal on it
	k.box(o + Vector3(10.0, DECK + 0.25, 2.0), Vector3(0.45, 0.5, 0.3), "l289_cloth", GeoKit.ALL, false)
	k.box(o + Vector3(10.6, DECK + 0.2, 1.9), Vector3(0.4, 0.4, 0.28), "l289_cloth", GeoKit.ALL, false)
	k.box(o + Vector3(11.8, DECK + 0.06, 3.9), Vector3(1.9, 0.12, 0.7), "l289_cloth", GeoKit.ALL, false)
	k.box(o + Vector3(13.4, DECK + 0.06, 3.7), Vector3(0.7, 0.12, 1.9), "l289_cloth", GeoKit.ALL, false)
	k.box(o + Vector3(13.9, DECK + 0.25, 1.8), Vector3(0.8, 0.5, 0.6), "l289_board_wood", GeoKit.ALL, true, "wood")
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.25), o + Vector3(13.85, DECK + 0.515, 1.8)), Vector3(0.36, 0.02, 0.26), "l289_cable", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.25) * Basis(Vector3.RIGHT, -1.25), o + Vector3(13.82, DECK + 0.64, 1.69)), Vector3(0.34, 0.24, 0.012), "l289_screen", GeoKit.ALL, false)
	k.box(o + Vector3(14.3, DECK + 0.12, 4.4), Vector3(0.14, 0.24, 0.14), "l289_bulb", GeoKit.ALL, false)
	L.lights.add_anchor(o + Vector3(14.3, DECK + 0.45, 4.4), Color(1.0, 0.8, 0.55), 2.2, 8.0, 0.0, grp)
	lamp(k, o + Vector3(4.2, H - 0.95, 6.2), grp, r, 0.0, 1.5)
	lamp(k, o + Vector3(13.0, H - 0.95, 11.8), grp, r, 0.0, 1.3)
