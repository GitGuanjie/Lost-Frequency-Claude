extends RefCounted
## Level 94 town: the cobbled square with the Almond Water fountain at the
## centre, four streets, tiny 1930s houses (gabled, chimneyed, porches and
## painted doors), corner houses with an upper floor, siren poles at the square
## and street lamps. Some houses are open and furnished in 1930s-1950s style.
## Frame: +X east, -Z north; the square spans |x|,|z| < SQ.

const SQ := 20.0
const ROAD := 4.5          # half width of the carriageway
const WALK := 7.0          # outer edge of the pavement
const FY := 0.36           # house floor height (one porch step up)

var lv
var k: GeoKit
var props: Node3D
var r := RandomNumberGenerator.new()
var houses: Array = []     # {o, yaw, w, d, open, two, back_door (world), inside (world)}
var poles: Array = []
var lamps: Array = []
var fountain_top := Vector3.ZERO


func _init(level, kit: GeoKit, prop_parent: Node3D) -> void:
	lv = level
	k = kit
	props = prop_parent
	r.seed = 94030


static func materials(clay: Callable) -> void:
	clay.call("l94_cobble_stone", Color(0.5, 0.45, 0.4), Color(0.42, 0.38, 0.34), 3, 1.0)
	clay.call("l94_road_asphalt", Color(0.2, 0.19, 0.19), Color(0.16, 0.15, 0.15), 0, 0.5)
	clay.call("l94_kerb_concrete", Color(0.55, 0.53, 0.5), Color(0.5, 0.48, 0.45), 0, 1.5)
	clay.call("l94_paving_tile", Color(0.6, 0.55, 0.48), Color(0.55, 0.5, 0.44), 3, 1.4)
	clay.call("l94_cream_plaster", Color(0.78, 0.68, 0.5), Color(0.72, 0.62, 0.45), 0, 1.0)
	clay.call("l94_mint_plaster", Color(0.45, 0.62, 0.52), Color(0.4, 0.56, 0.47), 0, 1.0)
	clay.call("l94_salmon_plaster", Color(0.78, 0.48, 0.4), Color(0.72, 0.42, 0.35), 0, 1.0)
	clay.call("l94_butter_plaster", Color(0.85, 0.72, 0.38), Color(0.78, 0.65, 0.32), 0, 1.0)
	clay.call("l94_sky_plaster", Color(0.48, 0.6, 0.72), Color(0.42, 0.54, 0.66), 0, 1.0)
	clay.call("l94_brick", Color(0.55, 0.25, 0.18), Color(0.48, 0.2, 0.15), 2, 1.0)
	clay.call("l94_roof_red", Color(0.55, 0.16, 0.12), Color(0.45, 0.12, 0.09), 4, 1.0)
	clay.call("l94_roof_slate", Color(0.22, 0.25, 0.32), Color(0.18, 0.2, 0.26), 4, 1.0)
	clay.call("l94_roof_green", Color(0.2, 0.35, 0.22), Color(0.16, 0.29, 0.18), 4, 1.0)
	clay.call("l94_trim_white", Color(0.88, 0.86, 0.8), Color(0.82, 0.8, 0.74), 0, 1.0, 0.5)
	clay.call("l94_door_red", Color(0.65, 0.1, 0.1), Color(0.55, 0.08, 0.08), 1, 1.0)
	clay.call("l94_door_blue", Color(0.12, 0.25, 0.55), Color(0.1, 0.2, 0.46), 1, 1.0)
	clay.call("l94_door_green", Color(0.12, 0.4, 0.2), Color(0.1, 0.33, 0.16), 1, 1.0)
	clay.call("l94_wood_floor", Color(0.45, 0.28, 0.15), Color(0.38, 0.23, 0.12), 1, 1.0)
	clay.call("l94_wallpaper", Color(0.75, 0.62, 0.45), Color(0.68, 0.55, 0.4), 0, 2.0)
	clay.call("l94_metal_pole", Color(0.25, 0.28, 0.3), Color(0.2, 0.22, 0.25), 0, 2.0, 0.4)
	clay.call("l94_grass_lawn", Color(0.28, 0.5, 0.2), Color(0.22, 0.42, 0.16), 5, 0.6)
	clay.call("l94_hedge_grass", Color(0.12, 0.32, 0.12), Color(0.09, 0.26, 0.1), 5, 1.5, 2.0)
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.3, 0.42, 0.5, 0.55)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.1
	g.metallic_specular = 0.9
	MatLib.register("l94_glass", g)
	MatLib.register("l94_window_lit", MatLib.panel(Color(1.0, 0.8, 0.45), 1.6))


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, col := false) -> Node3D:
	return Props.place(lv, props, id, pos, yaw, h, col)


# ------------------------------------------------------------------ ground

func streets() -> void:
	# the square: cobbles; streets: asphalt with kerbs and pavements
	k.slab(-SQ, -SQ, SQ, SQ, 0.06, 0.3, "l94_cobble_stone")
	for s in [-1.0, 1.0]:
		# N-S street
		k.slab(-ROAD, SQ if s > 0 else -96.0, ROAD, 96.0 if s > 0 else -SQ, 0.03, 0.3, "l94_road_asphalt")
		for side in [-1.0, 1.0]:
			var x0: float = side * ROAD
			var x1: float = side * WALK
			k.slab(minf(x0, x1), SQ if s > 0 else -96.0, maxf(x0, x1), 96.0 if s > 0 else -SQ, 0.08, 0.3, "l94_paving_tile")
		# E-W street
		k.slab(SQ if s > 0 else -96.0, -ROAD, 96.0 if s > 0 else -SQ, ROAD, 0.03, 0.3, "l94_road_asphalt")
		for side in [-1.0, 1.0]:
			var z0: float = side * ROAD
			var z1: float = side * WALK
			k.slab(SQ if s > 0 else -96.0, minf(z0, z1), 96.0 if s > 0 else -SQ, maxf(z0, z1), 0.08, 0.3, "l94_paving_tile")
	# a low clipped hedge and benches round the square's lawns
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cx: float = c.x * 13.0
		var cz: float = c.y * 13.0
		k.slab(cx - 5.0, cz - 5.0, cx + 5.0, cz + 5.0, 0.12, 0.2, "l94_grass_lawn")
		k.box(Vector3(cx + c.x * 5.2, 0.45, cz), Vector3(0.6, 0.8, 10.6), "l94_hedge_grass")
		k.box(Vector3(cx, 0.45, cz + c.y * 5.2), Vector3(10.6, 0.8, 0.6), "l94_hedge_grass")
		p("kenney/graveyard-kit/bench-damaged", Vector3(cx - c.x * 6.4, 0.06, cz), 90.0 * c.x, 0.9, true)


# ------------------------------------------------------------------ fountain

func fountain() -> void:
	k.cylinder(Vector3(0, 0.35, 0), 6.4, 0.6, "l94_kerb_concrete", 28)
	k.cylinder(Vector3(0, 0.66, 0), 6.6, 0.1, "l94_trim_white", 28, false)
	k.cylinder(Vector3(0, 1.4, 0), 0.7, 2.2, "l94_kerb_concrete", 14)
	k.cylinder(Vector3(0, 2.55, 0), 2.6, 0.35, "l94_cream_plaster", 22, false)
	k.cylinder(Vector3(0, 2.75, 0), 2.7, 0.08, "l94_trim_white", 22, false)
	k.cylinder(Vector3(0, 3.4, 0), 0.35, 1.3, "l94_cream_plaster", 10, false)
	k.cylinder(Vector3(0, 4.05, 0), 1.05, 0.25, "l94_cream_plaster", 16, false)
	k.cylinder(Vector3(0, 4.55, 0), 0.18, 0.8, "l94_trim_white", 8, false)
	k.cylinder(Vector3(0, 5.0, 0), 0.32, 0.2, "l94_trim_white", 10, false)
	fountain_top = Vector3(0, 5.0, 0)


# ------------------------------------------------------------------ houses

const COLS := ["l94_cream_plaster", "l94_mint_plaster", "l94_salmon_plaster", "l94_butter_plaster", "l94_sky_plaster", "l94_brick"]
const ROOFS := ["l94_roof_red", "l94_roof_slate", "l94_roof_green"]
const DOORS := ["l94_door_red", "l94_door_blue", "l94_door_green"]


func all_houses() -> void:
	# along the four streets, facing the carriageway
	var zs := [-32.0, -45.0, -58.0, -71.0, -84.0]
	for s in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			for i in zs.size():
				var along: float = -zs[i] * s
				var w := r.randf_range(6.0, 7.4)
				var d := r.randf_range(6.0, 7.0)
				var off: float = WALK + 1.8 + d * 0.5
				var open: bool = i == 0 or (i == 2 and side > 0)
				# N-S street: house at x = side*off, z = along
				house(Vector3(side * off, 0, along), atan2(-side, 0.0), w, d, open, false)
				# E-W street
				var w2 := r.randf_range(6.0, 7.4)
				var d2 := r.randf_range(6.0, 7.0)
				var off2: float = WALK + 1.8 + d2 * 0.5
				house(Vector3(along, 0, side * off2), atan2(0.0, -side), w2, d2, open and side < 0, false)
	# the four corner houses on the square, with an upper floor
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var o := Vector3(c.x * 28.0, 0, c.y * 28.0)
		house(o, atan2(-c.x, -c.y) , 8.0, 7.5, true, true)


## One tiny house. Local frame: +Z is the front (door side), x across.
func house(o: Vector3, yaw: float, w: float, d: float, open: bool, two: bool) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var L := func(v: Vector3) -> Vector3: return o + bas * v
	var col: String = COLS[r.randi() % COLS.size()]
	var roof: String = ROOFS[r.randi() % ROOFS.size()]
	var door: String = DOORS[r.randi() % DOORS.size()]
	var eave := 2.75 if not two else 5.5
	var hw := w * 0.5
	var hd := d * 0.5
	var door_at := hw + r.randf_range(-1.2, 1.2) * (0.0 if two else 1.0)
	# plinth and floor
	k.box_xf(Transform3D(bas, L.call(Vector3(0, FY * 0.5 - 0.15, 0))), Vector3(w + 0.3, FY + 0.3, d + 0.3), "l94_kerb_concrete")
	k.box_xf(Transform3D(bas, L.call(Vector3(0, FY + 0.01, 0))), Vector3(w - 0.4, 0.02, d - 0.4), "l94_wood_floor", GeoKit.PY, false)
	var win := func(at: float, sill: float) -> Dictionary: return {"at": at, "w": 0.9, "h": 1.15, "sill": sill}
	var front_ops: Array = [{"at": door_at, "w": 1.05, "h": 2.15}]
	for wx in [door_at - 2.1, door_at + 2.1]:
		if wx > 0.9 and wx < w - 0.9:
			front_ops.append(win.call(wx, 0.95))
	var storey := 2.75
	for lvl_i in (2 if two else 1):
		var y0 := FY + lvl_i * storey
		var ops_f: Array = front_ops if lvl_i == 0 else [win.call(w * 0.3, 0.9), win.call(w * 0.7, 0.9)]
		k.wall(L.call(Vector3(-hw, y0, hd)), L.call(Vector3(hw, y0, hd)), storey, 0.22, col, ops_f)
		k.wall(L.call(Vector3(hw, y0, -hd)), L.call(Vector3(-hw, y0, -hd)), storey, 0.22, col, [win.call(w * 0.5, 0.95)])
		k.wall(L.call(Vector3(hw, y0, hd)), L.call(Vector3(hw, y0, -hd)), storey, 0.22, col, [win.call(d * 0.5, 0.95)])
		k.wall(L.call(Vector3(-hw, y0, -hd)), L.call(Vector3(-hw, y0, hd)), storey, 0.22, col, [win.call(d * 0.5, 0.95)])
		# window panes, frames and shutters (front)
		for op in ops_f:
			if op.get("sill", 0.0) > 0.0:
				var wc: Vector3 = Vector3(-hw + float(op["at"]), y0 + op["sill"] + 0.575, hd)
				k.box_xf(Transform3D(bas, L.call(wc)), Vector3(0.9, 1.15, 0.04), "l94_glass", GeoKit.ALL, false)
				k.box_xf(Transform3D(bas, L.call(wc + Vector3(0, 0, 0.02))), Vector3(0.06, 1.15, 0.06), "l94_trim_white", GeoKit.ALL, false)
				k.box_xf(Transform3D(bas, L.call(wc + Vector3(0, -0.62, 0.08))), Vector3(1.1, 0.08, 0.2), "l94_trim_white", GeoKit.ALL, false)
				for sx in [-0.62, 0.62]:
					k.box_xf(Transform3D(bas, L.call(wc + Vector3(sx, 0, 0.1))), Vector3(0.32, 1.2, 0.05), door, GeoKit.ALL, false)
	# corner boards and a band under the eaves
	for cx in [-hw, hw]:
		for cz in [-hd, hd]:
			k.box_xf(Transform3D(bas, L.call(Vector3(cx, FY + eave * 0.5, cz))), Vector3(0.3, eave, 0.3), "l94_trim_white", GeoKit.ALL, false)
	if two:
		var sx0 := -hw + 0.15
		var sx1 := hw - 1.25
		k.box_xf(Transform3D(bas, L.call(Vector3((sx0 + sx1) * 0.5, FY + storey, 0))), Vector3(sx1 - sx0, 0.16, d - 0.3), "l94_wood_floor")
		var lz1 := hd - 0.6 - 14.0 * 0.3
		k.box_xf(Transform3D(bas, L.call(Vector3(hw - 0.7, FY + storey, (-hd + 0.15 + lz1) * 0.5))), Vector3(1.1, 0.16, lz1 + hd - 0.15), "l94_wood_floor")
	k.box_xf(Transform3D(bas, L.call(Vector3(0, FY + eave + 0.06, 0))), Vector3(w - 0.3, 0.12, d - 0.3), "l94_wallpaper", GeoKit.NY, false)
	# gable roof, ridge along x
	var rise := 2.0 + d * 0.08
	var run := hd + 0.45
	var ang := atan2(rise, run)
	var ln := sqrt(run * run + rise * rise)
	for s in [-1.0, 1.0]:
		var rc := Vector3(0, FY + eave + rise * 0.5 + 0.1, s * run * 0.5)
		k.box_xf(Transform3D(bas * Basis(Vector3(1, 0, 0), s * ang), L.call(rc)), Vector3(w + 0.7, 0.16, ln + 0.1), roof)
	for gx in [-hw, hw]:
		var steps := 7
		for i in steps:
			var t := float(i) / steps
			var half := hd * (1.0 - t) - 0.05
			if half > 0.05:
				k.box_xf(Transform3D(bas, L.call(Vector3(gx, FY + eave + rise * (t + 0.5 / steps), 0))), Vector3(0.22, rise / steps + 0.01, half * 2.0), col, GeoKit.ALL, false)
	# chimney
	var chx := hw * r.randf_range(-0.6, 0.6)
	k.box_xf(Transform3D(bas, L.call(Vector3(chx, FY + eave + rise * 0.7, -hd * 0.3))), Vector3(0.6, rise * 1.2 + 0.8, 0.6), "l94_brick", GeoKit.ALL, false)
	# porch step, door leaf and lamp
	var ps: Vector3 = L.call(Vector3(-hw + door_at, 0.0, hd + 0.95))
	k.stairs(ps, (L.call(Vector3(-hw + door_at, 0.0, hd)) - ps).normalized(), 1.6, FY, 2, "l94_kerb_concrete", 0.4)
	if open:
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, -1.35), L.call(Vector3(-hw + door_at - 0.5, FY + 1.07, hd + 0.5))), Vector3(1.0, 2.1, 0.06), door, GeoKit.ALL, false)
	else:
		k.box_xf(Transform3D(bas, L.call(Vector3(-hw + door_at, FY + 1.07, hd))), Vector3(1.05, 2.15, 0.1), door)
		k.box_xf(Transform3D(bas, L.call(Vector3(-hw + door_at + 0.35, FY + 1.05, hd + 0.07))), Vector3(0.06, 0.06, 0.06), "l94_metal_pole", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, L.call(Vector3(-hw + door_at, FY + 2.35, hd + 0.2))), Vector3(1.5, 0.08, 0.5), "l94_trim_white", GeoKit.ALL, false)
	# a picket fence and a gate gap in front
	var fz := hd + 1.6
	for fx in range(int(-hw * 2.0), int(hw * 2.0) + 1):
		var xx := float(fx) * 0.5
		if absf(xx - (-hw + door_at)) < 0.8:
			continue
		k.box_xf(Transform3D(bas, L.call(Vector3(xx, 0.45, fz))), Vector3(0.08, 0.8, 0.05), "l94_trim_white", GeoKit.ALL, false)
	for fy in [0.3, 0.65]:
		for sgn in [-1.0, 1.0]:
			var a := -hw if sgn < 0 else -hw + door_at + 0.8
			var b := -hw + door_at - 0.8 if sgn < 0 else hw
			if b - a > 0.2:
				k.box_xf(Transform3D(bas, L.call(Vector3((a + b) * 0.5, fy, fz - 0.03))), Vector3(b - a, 0.06, 0.03), "l94_trim_white", GeoKit.ALL, false)
	var rec := {"o": o, "yaw": yaw, "w": w, "d": d, "open": open, "two": two, "door": door,
		"front": L.call(Vector3(-hw + door_at, 0.0, hd + 2.6)), "inside": L.call(Vector3(-hw + door_at, FY, hd - 1.4)),
		"back_door": L.call(Vector3(0.0, FY, -hd + 0.11)), "basis": bas}
	if open:
		_furnish(rec, L, two, storey)
	houses.append(rec)


func _furnish(h: Dictionary, L: Callable, two: bool, storey: float) -> void:
	var w: float = h["w"]
	var d: float = h["d"]
	var yd := rad_to_deg(float(h["yaw"]))
	var hw := w * 0.5
	var hd := d * 0.5
	var y := FY + 0.02
	var kind := r.randi() % 3
	# parlour: armchair, sofa, radio or set, a rug, lamps; kitchen corner
	p("ph/ArmChair_01", L.call(Vector3(-hw + 1.0, y, -0.4)), yd + 70.0)
	if kind == 0:
		p("ph/Sofa_01", L.call(Vector3(hw - 0.6, y, 0.0)), yd - 90.0, 0.0, true)
		p("ph/coffee_table_round_01", L.call(Vector3(hw - 2.0, y, 0.0)), yd, 0.45)
		p("kenney/furniture-kit/radio", L.call(Vector3(hw - 2.0, y + 0.47, 0.1)), yd + 180.0, 0.25)
	elif kind == 1:
		p("ph/dining_table", L.call(Vector3(0.6, y, -0.6)), yd, 0.8, true)
		p("ph/dining_chair_02", L.call(Vector3(-0.4, y, -0.6)), yd + 90.0)
		p("ph/dining_chair_02", L.call(Vector3(1.6, y, -0.6)), yd - 90.0)
		p("ph/Chandelier_01", L.call(Vector3(0.6, FY + 2.0, -0.6)), yd)
	else:
		p("ph/GreenChair_01", L.call(Vector3(hw - 0.8, y, 0.4)), yd - 110.0)
		p("ph/Television_01", L.call(Vector3(hw - 0.5, y, -1.2)), yd - 90.0, 0.55)
		p("ph/ClassicNightstand_01", L.call(Vector3(hw - 0.5, y, -1.2)), yd - 90.0)
	p("ph/vintage_grandfather_clock_01", L.call(Vector3(-hw + 0.45, y, -hd + 0.6)), yd + 90.0)
	p("kenney/furniture-kit/rugrounded", L.call(Vector3(0.3, y, 0.3)), yd, 0.02)
	p("ph/wall_clock", L.call(Vector3(hw - 0.14, FY + 1.9, -0.5)), yd - 90.0)
	p("kenney/furniture-kit/lamproundfloor", L.call(Vector3(-hw + 0.5, y, 0.9)), yd, 1.5)
	lv.lights.add_anchor(L.call(Vector3(0, FY + 2.2, 0)), Color(1.0, 0.82, 0.55), 1.2, 6.0, 0.0, "houses")
	if two:
		# a stair up the side wall to the bedroom
		var sa: Vector3 = L.call(Vector3(hw - 0.7, FY, hd - 0.6))
		k.stairs(sa, (L.call(Vector3(hw - 0.7, FY, -hd)) - sa).normalized(), 0.95, storey, 14, "l94_wood_floor", 0.3)
		var y2 := FY + storey + 0.09
		p("ph/old_bed_frame", L.call(Vector3(-hw + 1.4, y2, -0.6)), yd + 90.0)
		p("ph/ornate_mirror_01", L.call(Vector3(-hw + 0.14, y2 + 1.2, 1.4)), yd + 90.0)
		p("ph/vintage_suitcase", L.call(Vector3(0.0, y2, -hd + 0.5)), yd)
		h["upstairs"] = L.call(Vector3(-hw + 2.0, y2, 0.6))
