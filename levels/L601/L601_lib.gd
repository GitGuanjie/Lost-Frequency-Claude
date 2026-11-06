extends RefCounted
## Level 601 "The End": the library itself. Materials, the seemingly endless
## stacks (seeded per period cell so the plan repeats exactly: the loop) and the
## authored main area with its metal letters and buzzing terminals.
## Chunk-local coordinates (u, v) run 0..24 m inside each streamed chunk.

const CS := 24.0
const CEIL := 3.2
const GAL := 3.6          # gallery floor (top) in the main area
const ROOF := 7.6         # main-area roof
const SHELF_H := 2.1
const ROWS := [2.0, 4.2, 6.4, 8.6, 10.8, 13.0, 15.2, 17.4, 19.6, 21.8]
const SEGS := [[1.6, 10.4], [13.6, 22.4]]
const FREE := [Vector2(12, 6), Vector2(12, 18), Vector2(6, 12), Vector2(18, 12)]

var lvl: Node3D
var seed_value := 0


func _init(level: Node3D, s: int) -> void:
	lvl = level
	seed_value = s


static func h01(parts: Array) -> float:
	return float(absi(hash(parts)) % 100003) / 100003.0


static func materials() -> void:
	MatLib.define("l601_carpet", {"albedo_a": Color(0.25, 0.28, 0.31), "albedo_b": Color(0.21, 0.24, 0.27),
		"pattern": 1, "pattern_scale": Vector2(0.5, 0.5), "grout_width": 0.004, "grout_color": Color(0.17, 0.19, 0.21),
		"tile_variation": 0.04, "roughness_a": 0.97, "roughness_b": 1.0, "noise_scale": 0.6, "bump_strength": 0.4})
	MatLib.define("l601_carpet_pit", {"albedo_a": Color(0.36, 0.30, 0.25), "albedo_b": Color(0.30, 0.25, 0.21),
		"pattern": 6, "noise_scale": 0.7})
	MatLib.define("l601_stone_tile", {"albedo_a": Color(0.6, 0.59, 0.56), "albedo_b": Color(0.54, 0.53, 0.5),
		"pattern": 15, "pattern_color": Color(0.45, 0.44, 0.42), "pattern_strength": 0.35,
		"roughness_a": 0.28, "roughness_b": 0.4, "noise_scale": 0.9, "bump_strength": 0.2})
	MatLib.define("l601_wall", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80),
		"grime_height": 0.12, "grime_color": Color(0.62, 0.62, 0.60), "noise_scale": 0.8, "bump_strength": 0.3})
	MatLib.define("l601_ceiling", {"albedo_a": Color(0.88, 0.88, 0.87), "albedo_b": Color(0.84, 0.84, 0.83),
		"pattern": 1, "pattern_scale": Vector2(0.6, 1.2), "grout_width": 0.006, "grout_color": Color(0.68, 0.69, 0.70),
		"tile_variation": 0.02, "noise_scale": 0.5})
	MatLib.define("l601_birch", {"albedo_a": Color(0.78, 0.66, 0.50), "albedo_b": Color(0.72, 0.60, 0.45),
		"pattern": 3, "pattern_scale": Vector2(2.4, 0.2), "grout_width": 0.002, "grout_color": Color(0.5, 0.4, 0.3),
		"roughness_a": 0.5, "roughness_b": 0.7})
	MatLib.define("l601_metal_shelf", {"albedo_a": Color(0.80, 0.80, 0.78), "albedo_b": Color(0.74, 0.74, 0.72),
		"metallic_value": 0.3, "roughness_a": 0.45, "roughness_b": 0.6, "noise_scale": 2.0})
	MatLib.define("l601_plinth", {"albedo_a": Color(0.16, 0.16, 0.17), "albedo_b": Color(0.12, 0.12, 0.13)})
	var spines := [[Color(0.46, 0.14, 0.11), Color(0.62, 0.48, 0.24)], [Color(0.13, 0.20, 0.33), Color(0.20, 0.32, 0.27)],
		[Color(0.74, 0.70, 0.62), Color(0.32, 0.30, 0.33)]]
	for i in 3:
		MatLib.define("l601_books_" + str(i), {"albedo_a": spines[i][0], "albedo_b": spines[i][1],
			"pattern": 1, "pattern_scale": Vector2(0.034, 4.0), "grout_width": 0.0025, "grout_color": Color(0.05, 0.04, 0.04),
			"tile_variation": 0.42, "noise_scale": 2.6, "noise_mix": 0.5, "roughness_a": 0.6, "roughness_b": 0.85,
			"bump_strength": 0.3})
	MatLib.define("l601_fabric", {"albedo_a": Color(0.18, 0.30, 0.31), "albedo_b": Color(0.14, 0.25, 0.26),
		"pattern": 6, "noise_scale": 1.5})
	MatLib.define("l601_steel", {"albedo_a": Color(0.72, 0.73, 0.75), "albedo_b": Color(0.6, 0.61, 0.63),
		"metallic_value": 0.9, "roughness_a": 0.25, "roughness_b": 0.4, "noise_scale": 6.0})
	MatLib.define("l601_door", {"albedo_a": Color(0.42, 0.46, 0.43), "albedo_b": Color(0.38, 0.42, 0.39),
		"metallic_value": 0.4, "roughness_a": 0.5, "roughness_b": 0.65})
	MatLib.define("l601_neon_dead", {"albedo_a": Color(0.16, 0.05, 0.05), "albedo_b": Color(0.1, 0.03, 0.03),
		"roughness_a": 0.15, "roughness_b": 0.2})
	MatLib.define("l601_monitor", {"albedo_a": Color(0.07, 0.07, 0.08), "albedo_b": Color(0.05, 0.05, 0.06),
		"roughness_a": 0.35, "roughness_b": 0.5})
	var sky := MatLib.panel(Color(0.93, 0.96, 1.0), 1.7)
	sky.set_shader_parameter("ribs", 0.0)
	MatLib.register("l601_skylight_panel", sky)
	var scr := MatLib.panel(Color(0.55, 0.72, 0.95), 1.25)
	scr.set_shader_parameter("ribs", 90.0)
	MatLib.register("l601_screen_panel", scr)


func light(pos: Vector3, col: Color, e: float, r: float, group: String, flick := 0.0) -> void:
	lvl.lights.add_anchor(pos, col, e, r, flick, group)


# ------------------------------------------------------------------ shelving

## One double-sided shelf run from p0 along axis (unit, horizontal).
func shelf_run(k: GeoKit, p0: Vector3, axis: Vector3, length: float, hs: Array, height := SHELF_H) -> void:
	var bx := axis.normalized()
	var bas := Basis(bx, Vector3.UP, bx.cross(Vector3.UP))
	var at := func(x: float, y: float) -> Vector3: return p0 + bx * x + Vector3.UP * y
	var no_bottom := GeoKit.ALL & ~GeoKit.NY
	k.box_xf(Transform3D(bas, at.call(length * 0.5, 0.05)), Vector3(length, 0.1, 0.56), "l601_plinth", no_bottom, false)
	for ex in [0.015, length - 0.015]:
		k.box_xf(Transform3D(bas, at.call(ex, height * 0.5)), Vector3(0.03, height, 0.62), "l601_birch", no_bottom, false)
	k.box_xf(Transform3D(bas, at.call(length * 0.5, height + 0.015)), Vector3(length, 0.03, 0.62), "l601_birch", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, at.call(length * 0.5, height * 0.5)), Vector3(length - 0.06, height - 0.12, 0.015), "l601_metal_shelf", GeoKit.ALL, false)
	var n_up := maxi(1, int(round(length / 1.8)))
	for i in range(1, n_up):
		k.box_xf(Transform3D(bas, at.call(length * i / n_up, height * 0.5)), Vector3(0.025, height - 0.1, 0.58), "l601_metal_shelf", GeoKit.ALL, false)
	var levels := int(height / 0.38)
	for lv in levels:
		var y0 := 0.1 + lv * 0.38
		if lv > 0:
			k.box_xf(Transform3D(bas, at.call(length * 0.5, y0 - 0.0125)), Vector3(length - 0.06, 0.025, 0.58), "l601_metal_shelf", no_bottom, false)
		var x := 0.05
		var i := 0
		while x < length - 0.12:
			var r := h01(hs + [lv, i])
			var seg := minf(0.7 + r * 2.4, length - 0.05 - x)
			var bh := 0.22 + 0.1 * h01(hs + [lv, i, "h"])
			var m := "l601_books_" + str(int(h01(hs + [lv, i, "m"]) * 3.0) % 3)
			if seg > 0.08:
				k.box_xf(Transform3D(bas, at.call(x + seg * 0.5, y0 + bh * 0.5)), Vector3(seg, bh, 0.52), m, no_bottom, false)
			x += seg
			if h01(hs + [lv, i, "g"]) < 0.4:
				x += 0.05 + 0.25 * h01(hs + [lv, i, "w"])
			i += 1
	k.add_box_shape(Transform3D(bas, at.call(length * 0.5, height * 0.5 + 0.01)), Vector3(length, height + 0.02, 0.62), "wood")


## A run expressed in chunk-local terms (row b across, a0..a1 along).
func local_run(k: GeoKit, o: Vector3, orient_x: bool, b: float, a0: float, a1: float, hs: Array) -> void:
	if orient_x:
		shelf_run(k, o + Vector3(a0, 0, b), Vector3.RIGHT, a1 - a0, hs)
	else:
		shelf_run(k, o + Vector3(b, 0, a0), Vector3.BACK, a1 - a0, hs)


static func run_rect(orient_x: bool, b: float, a0: float, a1: float) -> Rect2:
	return Rect2(a0, b - 0.31, a1 - a0, 0.62) if orient_x else Rect2(b - 0.31, a0, 0.62, a1 - a0)


func columns(k: GeoKit, o: Vector3, skip_centre: bool) -> void:
	for p in [Vector2(0, 0), Vector2(12, 0), Vector2(0, 12), Vector2(12, 12)]:
		if skip_centre and p == Vector2(12, 12):
			continue
		k.box(o + Vector3(p.x, CEIL * 0.5, p.y), Vector3(0.5, CEIL, 0.5), "l601_wall")


func ceiling(k: GeoKit, o: Vector3, x0 := 0.0, z0 := 0.0, x1 := CS, z1 := CS) -> void:
	k.box_mm(o + Vector3(x0, CEIL, z0), o + Vector3(x1, CEIL + 0.2, z1), "l601_ceiling", GeoKit.NY | GeoKit.SIDES, false)


func skylights(k: GeoKit, o: Vector3, group: String, which: Array = [0, 1, 2, 3]) -> void:
	for i in which:
		var p: Vector2 = FREE[i]
		var vert: bool = i < 2
		k.panel(o + Vector3(p.x, CEIL - 0.01, p.y), 1.3 if vert else 5.6, 5.6 if vert else 1.3, "l601_skylight_panel")
		light(o + Vector3(p.x, CEIL - 0.35, p.y), Color(0.9, 0.94, 1.0), 1.0, 8.0, group)


# -------------------------------------------------------------------- stacks

func stacks_desc(lx: int, lz: int) -> Dictionary:
	var r := h01([seed_value, lx, lz, "kind"])
	var kind := "stacks"
	if r < 0.2:
		kind = "pit"
	elif r < 0.4:
		kind = "tables"
	return {"kind": kind, "orient_x": h01([seed_value, lx, lz, "o"]) < 0.5}


func stacks(o: Vector3, lx: int, lz: int, group: String, n: Node3D) -> Dictionary:
	var d := stacks_desc(lx, lz)
	var k := GeoKit.new(n, "Stacks")
	var ox: bool = d["orient_x"]
	var hole := Rect2()
	var clear := Rect2()
	if d["kind"] == "pit":
		hole = Rect2(14.4, 14.4, 7.2, 7.2)
		clear = Rect2(14.0, 14.0, 8.0, 8.0)
	elif d["kind"] == "tables":
		clear = Rect2(2.0, 14.0, 8.0, 8.0)
	_floor(k, o, hole)
	ceiling(k, o)
	columns(k, o, false)
	var removed := 0
	for ri in ROWS.size():
		for si in 2:
			var a0: float = SEGS[si][0]
			var a1: float = SEGS[si][1]
			var hs := [seed_value, lx, lz, ri, si]
			if clear.size.x > 0.0 and run_rect(ox, ROWS[ri], a0, a1).intersects(clear):
				continue
			var g := h01(hs + ["gap"])
			if g < 0.07:
				removed += 1
				continue
			if g < 0.2:
				a1 -= 2.2 + 2.0 * h01(hs + ["cut"])
			local_run(k, o, ox, ROWS[ri], a0, a1, hs)
	skylights(k, o, group)
	if d["kind"] == "pit":
		_pit(k, o, group, [seed_value, lx, lz])
	elif d["kind"] == "tables":
		_tables(k, o, Vector2(6.0, 18.0), [seed_value, lx, lz])
	k.commit()
	return {"kind": d["kind"], "layout": [d["kind"], ox, removed], "free": FREE}


func _floor(k: GeoKit, o: Vector3, hole: Rect2, mat := "l601_carpet") -> void:
	if hole.size.x <= 0.0:
		k.slab(o.x, o.z, o.x + CS, o.z + CS, 0.0, 0.2, mat, GeoKit.PY)
		return
	var hx0 := hole.position.x
	var hz0 := hole.position.y
	var hx1 := hole.end.x
	var hz1 := hole.end.y
	k.slab(o.x, o.z, o.x + CS, o.z + hz0, 0.0, 0.2, mat, GeoKit.PY)
	k.slab(o.x, o.z + hz1, o.x + CS, o.z + CS, 0.0, 0.2, mat, GeoKit.PY)
	k.slab(o.x, o.z + hz0, o.x + hx0, o.z + hz1, 0.0, 0.2, mat, GeoKit.PY)
	k.slab(o.x + hx1, o.z + hz0, o.x + CS, o.z + hz1, 0.0, 0.2, mat, GeoKit.PY)


## A sunken reading room, three 0.18 m risers down.
func _pit(k: GeoKit, o: Vector3, group: String, hs: Array) -> void:
	var d := 0.54
	k.slab(o.x + 14.4, o.z + 14.4, o.x + 21.6, o.z + 21.6, -d, 0.2, "l601_carpet_pit", GeoKit.PY)
	k.box_mm(o + Vector3(14.3, -d, 14.3), o + Vector3(21.7, 0.0, 14.4), "l601_birch")
	k.box_mm(o + Vector3(14.3, -d, 21.6), o + Vector3(21.7, 0.0, 21.7), "l601_birch")
	k.box_mm(o + Vector3(14.3, -d, 14.4), o + Vector3(14.4, 0.0, 21.6), "l601_birch")
	k.box_mm(o + Vector3(21.6, -d, 14.4), o + Vector3(21.7, 0.0, 21.6), "l601_birch")
	k.stairs(o + Vector3(18.0, -d, 15.24), Vector3(0, 0, -1), 2.4, d, 3, "l601_birch", 0.28)
	# upholstered benches along three sides
	k.box_mm(o + Vector3(14.4, -d, 20.95), o + Vector3(21.6, -d + 0.44, 21.6), "l601_fabric")
	k.box_mm(o + Vector3(14.4, -d, 16.2), o + Vector3(15.05, -d + 0.44, 20.95), "l601_fabric")
	k.box_mm(o + Vector3(20.95, -d, 16.2), o + Vector3(21.6, -d + 0.44, 20.95), "l601_fabric")
	k.cylinder(o + Vector3(18.0, -d + 0.2, 18.4), 0.7, 0.4, "l601_birch", 16)
	for i in int(2 + h01(hs + ["bk"]) * 3.0):
		var p := o + Vector3(17.4 + i * 0.35, -d + 0.42, 18.2 + 0.2 * h01(hs + [i]))
		k.box(p, Vector3(0.2, 0.04, 0.27), "l601_books_" + str(i % 3), GeoKit.ALL, false)
	k.panel(o + Vector3(18.0, CEIL - 0.01, 18.0), 5.0, 5.0, "l601_skylight_panel")
	light(o + Vector3(18.0, CEIL - 0.4, 18.0), Color(0.94, 0.95, 1.0), 1.5, 10.0, group)


func _tables(k: GeoKit, o: Vector3, c: Vector2, hs: Array) -> void:
	for t in 2:
		var z := c.y - 1.6 + t * 3.2
		var p := o + Vector3(c.x, 0.0, z)
		k.box(p + Vector3(0, 0.74, 0), Vector3(3.6, 0.04, 0.9), "l601_birch", GeoKit.ALL, false)
		for sx in [-1.6, 1.6]:
			k.box(p + Vector3(sx, 0.36, 0), Vector3(0.05, 0.72, 0.8), "l601_metal_shelf", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), p + Vector3(0, 0.38, 0)), Vector3(3.6, 0.76, 0.9), "wood")
		for j in 4:
			for side in [-1.0, 1.0]:
				var cp := p + Vector3(-1.35 + j * 0.9, 0, side * (0.75 + 0.15 * h01(hs + [t, j, side])))
				k.box(cp + Vector3(0, 0.44, 0), Vector3(0.44, 0.05, 0.42), "l601_fabric", GeoKit.ALL, false)
				k.box(cp + Vector3(0, 0.7, side * 0.2), Vector3(0.44, 0.5, 0.04), "l601_fabric", GeoKit.ALL, false)
				k.box(cp + Vector3(0, 0.21, 0), Vector3(0.04, 0.42, 0.04), "l601_plinth", GeoKit.ALL, false)
		# a desk lamp per table: dead, like everything electric here
		k.box(p + Vector3(0.4, 0.78, 0), Vector3(0.16, 0.03, 0.16), "l601_plinth", GeoKit.ALL, false)
		k.box(p + Vector3(0.4, 1.0, 0), Vector3(0.02, 0.42, 0.02), "l601_plinth", GeoKit.ALL, false)
		k.box(p + Vector3(0.4, 1.22, 0.08), Vector3(0.12, 0.06, 0.24), "l601_plinth", GeoKit.ALL, false)


# --------------------------------------------------------------- main area

func centre(o: Vector3, group: String, n: Node3D) -> Dictionary:
	var k := GeoKit.new(n, "Centre")
	k.slab(o.x, o.z, o.x + CS, o.z + CS, 0.0, 0.2, "l601_stone_tile", GeoKit.PY)
	# the ordinary library ceiling over the aisle that rings the hall
	for r in [[0, 0, CS, 1.45], [0, 22.55, CS, CS], [0, 1.45, 1.45, 22.55], [22.55, 1.45, CS, 22.55]]:
		ceiling(k, o, r[0], r[1], r[2], r[3])
	for p in [Vector2(0, 0), Vector2(12, 0), Vector2(0, 12)]:
		k.box(o + Vector3(p.x, CEIL * 0.5, p.y), Vector3(0.5, CEIL, 0.5), "l601_wall")
	for p in [Vector3(6, 0, 0.75), Vector3(18, 0, 23.25), Vector3(0.75, 0, 18), Vector3(23.25, 0, 6)]:
		var along_x: bool = p.x > 1.0 and p.x < 23.0
		k.panel(o + Vector3(p.x, CEIL - 0.01, p.z), 4.0 if along_x else 0.9, 0.9 if along_x else 4.0, "l601_skylight_panel")
		light(o + Vector3(p.x, CEIL - 0.4, p.z), Color(0.9, 0.94, 1.0), 0.8, 7.0, group)
	var main := [{"at": 10.4, "w": 4.8, "h": 3.0}]
	var side := [{"at": 3.4, "w": 1.4, "h": 2.4}, {"at": 17.4, "w": 1.4, "h": 2.4}]
	var c := [o + Vector3(1.6, 0, 1.6), o + Vector3(22.4, 0, 1.6), o + Vector3(22.4, 0, 22.4), o + Vector3(1.6, 0, 22.4)]
	k.wall(c[0], c[1], ROOF, 0.3, "l601_wall", main + side)
	k.wall(c[1], c[2], ROOF, 0.3, "l601_wall", main + side)
	k.wall(c[3], c[2], ROOF, 0.3, "l601_wall", main + [{"at": 3.4, "w": 1.0, "h": 2.1}, {"at": 17.4, "w": 1.4, "h": 2.4}])
	k.wall(c[0], c[3], ROOF, 0.3, "l601_wall", main + side)
	# the door you came in by (seen from this side: closed, its neon sign dead)
	k.box(o + Vector3(5.0, 1.04, 22.4), Vector3(0.96, 2.08, 0.06), "l601_door")
	k.box(o + Vector3(5.0, 1.02, 22.28), Vector3(0.7, 0.05, 0.05), "l601_steel", GeoKit.ALL, false)
	k.box(o + Vector3(5.0, 2.46, 22.2), Vector3(0.74, 0.24, 0.07), "l601_neon_dead", GeoKit.ALL, false)
	# gallery ring
	var ring := [[1.75, 1.75, 22.25, 6.0], [1.75, 18.0, 22.25, 22.25], [1.75, 6.0, 6.0, 18.0], [18.0, 6.0, 22.25, 18.0], [6.0, 8.6, 8.4, 10.8]]
	for r in ring:
		k.slab(o.x + r[0], o.z + r[1], o.x + r[2], o.z + r[3], GAL, 0.35, "l601_stone_tile", GeoKit.PY | GeoKit.SIDES)
		k.box_mm(o + Vector3(r[0], GAL - 0.36, r[1]), o + Vector3(r[2], GAL - 0.35, r[3]), "l601_birch", GeoKit.NY, false)
	k.stairs(o + Vector3(7.3, 0, 16.4), Vector3(0, 0, -1), 2.2, GAL, 20, "l601_stone_tile", 0.28)
	k.ramp(o + Vector3(8.45, 1.0, 16.4), o + Vector3(8.45, GAL + 1.0, 10.8), 0.03, 0.9, "glass")
	k.ramp(o + Vector3(8.45, 1.02, 16.4), o + Vector3(8.45, GAL + 1.02, 10.8), 0.05, 0.05, "l601_steel")
	k.ramp(o + Vector3(6.15, 1.0, 16.4), o + Vector3(6.15, GAL + 1.0, 10.8), 0.03, 0.9, "glass")
	for b in [[6, 6, 18, 6], [6, 18, 18, 18], [18, 6, 18, 18], [6, 10.8, 6, 18], [6, 6, 6, 8.6], [6, 8.6, 8.4, 8.6], [8.4, 8.6, 8.4, 10.8]]:
		_balustrade(k, o + Vector3(b[0], GAL, b[1]), o + Vector3(b[2], GAL, b[3]))
	for p in [Vector2(6, 6), Vector2(18, 6), Vector2(6, 18), Vector2(18, 18)]:
		k.cylinder(o + Vector3(p.x, ROOF * 0.5, p.y), 0.32, ROOF, "l601_wall", 16)
	# roof and the big frosted skylight over the void
	for r in [[1.6, 1.6, 22.4, 6.0], [1.6, 18.0, 22.4, 22.4], [1.6, 6.0, 6.0, 18.0], [18.0, 6.0, 22.4, 18.0]]:
		k.box_mm(o + Vector3(r[0], ROOF, r[1]), o + Vector3(r[2], ROOF + 0.2, r[3]), "l601_ceiling", GeoKit.NY, false)
	k.panel(o + Vector3(12, ROOF - 0.01, 12), 12.0, 12.0, "l601_skylight_panel")
	for i in range(1, 6):
		k.box(o + Vector3(6 + i * 2.0, ROOF - 0.09, 12), Vector3(0.08, 0.16, 12.0), "l601_plinth", GeoKit.ALL, false)
		k.box(o + Vector3(12, ROOF - 0.09, 6 + i * 2.0), Vector3(12.0, 0.16, 0.08), "l601_plinth", GeoKit.ALL, false)
	# clerestory: frosted ribbons high on the east and west walls
	for xw in [[1.76, Vector3.RIGHT], [22.24, Vector3.LEFT]]:
		k.quad(o + Vector3(xw[0], 6.2, 12), xw[1], Vector3(0, 0, 8.5), Vector3(0, 0.6, 0), "l601_skylight_panel", Vector2.ZERO, true)
	# gallery shelving along the walls, reading tables below
	var hs := [seed_value, "centre"]
	for r in [[2.6, 2.3, 11.0, true], [13.0, 2.3, 21.4, true], [2.6, 21.7, 11.0, true], [13.0, 21.7, 21.4, true],
			[2.3, 7.0, 17.0, false], [21.7, 7.0, 17.0, false]]:
		var p0: Vector3 = o + (Vector3(r[0], GAL, r[1]) if r[3] else Vector3(r[0], GAL, r[1]))
		shelf_run(k, p0, Vector3.RIGHT if r[3] else Vector3.BACK, (r[2] - r[0]) if r[3] else (r[2] - r[1]), hs + [r[0], r[1]])
	_tables(k, o, Vector2(3.9, 12.0), hs + ["w"])
	_tables(k, o, Vector2(20.1, 12.0), hs + ["e"])
	k.box_mm(o + Vector3(3.2, 5.95, 1.75), o + Vector3(20.8, 7.25, 1.79), "l601_plinth", GeoKit.ALL, false)
	var letters := _letters(n, o + Vector3(12.0, 6.6, 1.83))
	var term := _terminals(k, n, o)
	k.commit()
	for p in [Vector3(9, 6.6, 9), Vector3(15, 6.6, 9), Vector3(9, 6.6, 15), Vector3(15, 6.6, 15)]:
		light(o + p, Color(0.92, 0.95, 1.0), 1.7, 15.0, group)
	for p in [Vector3(3.9, 2.9, 12), Vector3(20.1, 2.9, 12), Vector3(12, 2.9, 4.0), Vector3(12, 2.9, 20.0)]:
		light(o + p, Color(0.9, 0.92, 0.95), 0.55, 7.0, group)
	light(o + Vector3(13, 1.25, 12), Color(0.55, 0.7, 1.0), 0.7, 5.5, group)
	return {"kind": "centre", "layout": ["centre"], "free": [], "letters": letters, "terminals": term}


func _balustrade(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var c := (a + b) * 0.5
	var l := a.distance_to(b)
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var sz := Vector3(l, 1.05, 0.02) if along_x else Vector3(0.02, 1.05, l)
	k.box(c + Vector3(0, 0.525, 0), sz, "glass")
	k.box(c + Vector3(0, 1.08, 0), Vector3(sz.x + 0.04, 0.05, maxf(sz.z, 0.06)) if along_x else Vector3(0.06, 0.05, sz.z + 0.04), "l601_steel", GeoKit.ALL, false)


## 'the end is near' in brushed metal letters: layered text gives them depth.
func _letters(n: Node3D, at: Vector3) -> Array:
	var out: Array = []
	for i in 7:
		var l := Label3D.new()
		l.text = "the end is near"
		l.font_size = 200
		l.pixel_size = 0.0068
		l.outline_size = 0
		l.shaded = true
		l.double_sided = false
		l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		var t := float(i) / 6.0
		l.modulate = Color(0.95, 0.95, 0.96).lerp(Color(0.32, 0.32, 0.34), t)
		l.position = at + Vector3(0, 0, 0.04 - 0.006 * i)
		l.render_priority = -i
		n.add_child(l)
		out.append(l)
	return out


func _terminals(k: GeoKit, n: Node3D, o: Vector3) -> Array:
	var out: Array = []
	var ix := 13.0
	for z in [11.3, 12.7]:
		k.box(o + Vector3(ix, 0.74, z), Vector3(7.2, 0.04, 0.72), "l601_birch", GeoKit.ALL, false)
	k.box(o + Vector3(ix, 0.55, 12.0), Vector3(7.2, 0.9, 0.04), "l601_metal_shelf", GeoKit.ALL, false)
	for x in [ix - 3.55, ix + 3.55]:
		k.box(o + Vector3(x, 0.37, 12.0), Vector3(0.05, 0.74, 2.1), "l601_metal_shelf", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), o + Vector3(ix, 0.38, 12.0)), Vector3(7.2, 0.76, 2.16), "wood")
	for side in [-1.0, 1.0]:
		var zm: float = 12.0 + side * 0.34
		for x in [ix - 2.7, ix - 0.9, ix + 0.9, ix + 2.7]:
			var m := o + Vector3(x, 1.08, zm)
			k.box(m, Vector3(0.62, 0.38, 0.04), "l601_monitor", GeoKit.ALL, false)
			k.box(o + Vector3(x, 0.84, zm - side * 0.02), Vector3(0.06, 0.2, 0.06), "l601_monitor", GeoKit.ALL, false)
			k.box(o + Vector3(x, 0.765, zm + side * 0.3), Vector3(0.44, 0.02, 0.15), "l601_monitor", GeoKit.ALL, false)
			k.quad(m + Vector3(0, 0, side * 0.021), Vector3(0, 0, side), Vector3(0.28, 0, 0), Vector3(0, 0.165, 0), "l601_screen_panel", Vector2.ZERO, true)
			var cp := o + Vector3(x, 0, zm + side * 0.95)
			k.box(cp + Vector3(0, 0.46, 0), Vector3(0.46, 0.06, 0.44), "l601_fabric", GeoKit.ALL, false)
			k.box(cp + Vector3(0, 0.78, side * 0.22), Vector3(0.44, 0.52, 0.05), "l601_fabric", GeoKit.ALL, false)
			k.box(cp + Vector3(0, 0.22, 0), Vector3(0.05, 0.44, 0.05), "l601_plinth", GeoKit.ALL, false)
			var smile := Label3D.new()
			smile.text = "=)"
			smile.font_size = 64
			smile.pixel_size = 0.004
			smile.modulate = Color(0.85, 0.95, 1.0)
			smile.position = m + Vector3(0, 0, side * 0.025)
			smile.rotation.y = 0.0 if side > 0 else PI
			smile.visible = false
			n.add_child(smile)
			out.append({"pos": m, "face": side, "smile": smile})
	return out
