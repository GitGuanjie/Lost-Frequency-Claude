extends RefCounted
## Level 974 "Kitty's House" — static builders for the ~970 sq ft pink home.
## SOURCE rooms: bedroom, master bedroom, two bathrooms, living room and a
## kitchen/dining room; only the dining room and bedroom are furnished; no door
## to the outdoors; windows are coquette "outdoor" artwork. Footprint 12 x 8 m
## (96 m2 gross ~ 970 sq ft net). ADAPTATION: exact plan, a sunken living room
## (two 0.18 m risers) and a master bedroom raised one step (guide section 9
## "natural vertical variation"), fixtures in the bathrooms (plumbing works per
## page), and everyday clutter (outlets, switches, vents, utensils).
##
## Plan (x east, z south):  z 0..3  master 0..4.2 | bath 4.2..6.2 | bedroom 6.2..10 | bath 10..12
##                          z 3..4.2 hallway 0..12
##                          z 4.2..8 living 0..5.2 (sunken) | kitchen + dining 5.2..12

const Art := preload("res://levels/L974/L974_art.gd")
const B := -0.36          # lowest floor (sunken living room) = wall base
const CEIL := 2.62
const MASTER := 0.18
const WH := CEIL - B


static func materials(seed_value: int) -> void:
	MatLib.define("l974_wall", {"albedo_a": Color(0.98, 0.58, 0.69), "albedo_b": Color(0.96, 0.56, 0.67), "pattern": 0,
		"noise_scale": 0.6, "roughness_a": 0.82, "roughness_b": 0.9, "bump_strength": 0.15}, "plaster")
	MatLib.define("l974_ceiling", {"albedo_a": Color(0.98, 0.95, 0.95), "albedo_b": Color(0.96, 0.93, 0.93)}, "plaster")
	MatLib.define("l974_wood_floor", {"albedo_a": Color(0.86, 0.71, 0.64), "albedo_b": Color(0.80, 0.64, 0.58),
		"grout_color": Color(0.55, 0.40, 0.38)}, "wood_floor")
	MatLib.define("l974_tile_check", {"albedo_a": Color(0.99, 0.96, 0.96), "albedo_b": Color(0.97, 0.94, 0.94), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.97, 0.70, 0.78), "pattern_strength": 0.5,
		"grout_width": 0.004, "grout_color": Color(0.85, 0.8, 0.8), "roughness_a": 0.25, "roughness_b": 0.35}, "pool_tile")
	MatLib.define("l974_trim", {"albedo_a": Color(1.0, 0.97, 0.97), "albedo_b": Color(0.97, 0.94, 0.95)}, "trim_white")
	MatLib.define("l974_pinkwood", {"albedo_a": Color(0.95, 0.62, 0.71), "albedo_b": Color(0.90, 0.57, 0.66),
		"grout_color": Color(0.7, 0.4, 0.48), "roughness_a": 0.55, "roughness_b": 0.7}, "wood_floor")
	MatLib.define("l974_cabinet", {"albedo_a": Color(0.98, 0.78, 0.83), "albedo_b": Color(0.96, 0.75, 0.80),
		"roughness_a": 0.45, "roughness_b": 0.55}, "trim_white")
	MatLib.define("l974_counter", {"albedo_a": Color(0.98, 0.96, 0.93), "albedo_b": Color(0.93, 0.90, 0.88), "pattern": 15,
		"pattern_color": Color(0.95, 0.70, 0.78), "pattern_strength": 0.5, "roughness_a": 0.3, "roughness_b": 0.4}, "trim_white")
	MatLib.define("l974_fridge_metal", {"albedo_a": Color(0.98, 0.70, 0.78), "albedo_b": Color(0.97, 0.68, 0.76),
		"roughness_a": 0.22, "roughness_b": 0.3, "noise_scale": 0.3}, "trim_white")
	MatLib.define("l974_porcelain", {"albedo_a": Color(1.0, 0.95, 0.96), "albedo_b": Color(0.98, 0.93, 0.94),
		"roughness_a": 0.12, "roughness_b": 0.2}, "trim_white")
	MatLib.define("l974_bedding", {"albedo_a": Color(0.99, 0.74, 0.82), "albedo_b": Color(0.97, 0.71, 0.80), "pattern": 5,
		"pattern_scale": Vector2(0.12, 0.12), "pattern_color": Color(1.0, 0.97, 0.98), "pattern_strength": 0.9,
		"roughness_a": 0.95, "roughness_b": 1.0}, "plaster")
	MatLib.define("l974_fabric_pink", {"albedo_a": Color(0.96, 0.66, 0.76), "albedo_b": Color(0.92, 0.62, 0.72), "pattern": 2,
		"pattern_scale": Vector2(0.06, 1.0), "pattern_color": Color(0.9, 0.58, 0.68), "pattern_strength": 0.4}, "plaster")
	MatLib.define("l974_beige", {"albedo_a": Color(0.84, 0.80, 0.70), "albedo_b": Color(0.80, 0.76, 0.66),
		"roughness_a": 0.5, "roughness_b": 0.6}, "trim_white")
	MatLib.define("l974_dark", {"albedo_a": Color(0.12, 0.1, 0.11), "albedo_b": Color(0.1, 0.08, 0.09), "roughness_a": 0.4}, "trim_white")
	MatLib.define("l974_rug", {"albedo_a": Color(0.98, 0.80, 0.86), "albedo_b": Color(0.95, 0.76, 0.83), "pattern": 6,
		"pattern_scale": Vector2(0.2, 0.2), "pattern_color": Color(1, 1, 1), "pattern_strength": 0.5}, "plaster")
	MatLib.register("l974_glass", MatLib.get_mat("glass"))
	MatLib.register("l974_mirror", MatLib.standard(Color(0.85, 0.88, 0.9), 0.02, 1.0))
	MatLib.register("l974_lamp_panel", MatLib.standard(Color(1, 0.97, 0.92), 1.0, 0.0, Color(1.0, 0.9, 0.82), 1.3))
	for i in 3:
		MatLib.register("l974_window_panel%d" % i, Art.window_mat(float(seed_value % 97) + i * 3.7))
	var pal := [[Color(0.75, 0.88, 1.0), Color(1.0, 0.85, 0.92)], [Color(1.0, 0.86, 0.92), Color(1.0, 1.0, 1.0)],
		[Color(0.86, 0.95, 0.84), Color(1.0, 0.92, 0.75)], [Color(0.92, 0.85, 1.0), Color(1.0, 0.8, 0.9)]]
	for i in 4:
		var c: Array = pal[(seed_value + i) % 4]
		MatLib.register("l974_poster%d" % i, Art.poster_mat(float(seed_value % 53) + i * 1.37, c[0], c[1]))


static func door(at: float, floor_y: float = 0.0, w: float = 1.0) -> Dictionary:
	return {"at": at, "w": w, "h": 2.1, "sill": floor_y - B}


static func gap(at: float, w: float) -> Dictionary:
	return {"at": at, "w": w, "h": 2.46, "sill": 0.0}


static func win(at: float, w: float, floor_y: float, sill: float = 0.9, h: float = 1.2) -> Dictionary:
	return {"at": at, "w": w, "h": h, "sill": floor_y - B + sill}


## Shell: floors, ceiling, exterior and interior walls (pink both sides).
static func shell(k: GeoKit) -> void:
	k.slab(0, 0, 4.2, 3.0, MASTER, 0.5, "l974_wood_floor", GeoKit.PY | GeoKit.SIDES)
	k.slab(4.2, 0, 6.2, 3.0, 0.0, 0.3, "l974_tile_check", GeoKit.PY)
	k.slab(6.2, 0, 10.0, 3.0, 0.0, 0.3, "l974_wood_floor", GeoKit.PY)
	k.slab(10.0, 0, 12.0, 3.0, 0.0, 0.3, "l974_tile_check", GeoKit.PY)
	k.slab(0, 3.0, 12.0, 4.2, 0.0, 0.3, "l974_wood_floor", GeoKit.PY | GeoKit.SIDES)
	k.slab(0, 4.2, 5.2, 8.0, B, 0.3, "l974_wood_floor", GeoKit.PY)
	k.slab(5.2, 4.2, 12.0, 8.0, 0.0, 0.66, "l974_tile_check", GeoKit.PY | GeoKit.SIDES)
	k.slab(-0.2, -0.2, 12.2, 8.2, CEIL + 0.2, 0.2, "l974_ceiling", GeoKit.NY)
	var A := GeoKit.ALL
	k.wall(Vector3(-0.2, B, -0.1), Vector3(12.2, B, -0.1), WH, 0.2, "l974_wall", [win(8.2, 1.2, 0.0, 0.95, 1.1)], A)
	k.wall(Vector3(-0.2, B, 8.1), Vector3(12.2, B, 8.1), WH, 0.2, "l974_wall", [win(2.5, 2.2, B, 0.85, 1.25), win(9.3, 1.4, 0.0)], A)
	k.wall(Vector3(-0.1, B, -0.2), Vector3(-0.1, B, 8.2), WH, 0.2, "l974_wall", [win(1.7, 1.2, MASTER), win(6.3, 1.4, B, 0.85, 1.25)], A)
	k.wall(Vector3(12.1, B, -0.2), Vector3(12.1, B, 8.2), WH, 0.2, "l974_wall", [], A)
	k.wall(Vector3(0, B, 3.0), Vector3(12, B, 3.0), WH, 0.12, "l974_wall",
		[door(3.5), door(5.15, 0.0, 0.95), door(6.9), door(10.95, 0.0, 0.95)], A)
	k.wall(Vector3(0, B, 4.2), Vector3(12, B, 4.2), WH, 0.12, "l974_wall", [gap(4.0, 1.2), door(7.9)], A)
	for x in [4.2, 6.2, 10.0]:
		k.wall(Vector3(x, B, 0), Vector3(x, B, 3.0), WH, 0.12, "l974_wall", [], A)
	k.wall(Vector3(5.2, B, 4.2), Vector3(5.2, B, 8.0), WH, 0.12, "l974_wall", [gap(1.0, 1.4)], A)
	# sunken living room: two 0.18 m risers at both openings
	k.stairs(Vector3(4.0, B, 4.76), Vector3(0, 0, -1), 1.2, -B, 2, "l974_wood_floor", 0.28)
	k.stairs(Vector3(4.64, B, 5.2), Vector3(1, 0, 0), 1.4, -B, 2, "l974_wood_floor", 0.28)
	# trims: door casings and baseboards
	for d in [[3.5, 3.0, true], [5.15, 3.0, true], [6.9, 3.0, true], [10.95, 3.0, true], [7.9, 4.2, true]]:
		_casing(k, d[0], d[1])
	for seg in [[0.0, 4.25, 3.4, 4.25, B], [0.05, 4.2, 0.05, 8.0, B], [0.0, 7.95, 5.2, 7.95, B], [6.25, 0.05, 10.0, 0.05, 0.0],
			[0.0, 0.05, 4.2, 0.05, MASTER], [5.3, 7.95, 12.0, 7.95, 0.0], [12.0, 4.2, 12.0, 8.0, 0.0]]:
		k.box_mm(Vector3(minf(seg[0], seg[2]) - 0.01, seg[4], minf(seg[1], seg[3]) - 0.01), Vector3(maxf(seg[0], seg[2]) + 0.01, seg[4] + 0.09, maxf(seg[1], seg[3]) + 0.01), "l974_trim", GeoKit.ALL, false)


static func _casing(k: GeoKit, x: float, z: float) -> void:
	for s in [-1.0, 1.0]:
		k.box(Vector3(x + s * 0.53, 1.05, z), Vector3(0.06, 2.1, 0.16), "l974_trim", GeoKit.ALL, false)
	k.box(Vector3(x, 2.13, z), Vector3(1.12, 0.07, 0.16), "l974_trim", GeoKit.ALL, false)


## Window: white frame, sill, glass, and the painted coquette "outdoors" behind.
static func window(k: GeoKit, c: Vector3, n: Vector3, w: float, h: float, art: int) -> void:
	var along := Vector3(-n.z, 0, n.x)
	k.quad(c - n * 0.08, n, along * (w * 0.5), Vector3(0, h * 0.5, 0), "l974_window_panel%d" % art, Vector2.ZERO, true)
	k.box(c - n * 0.03, Vector3(absf(along.x) * w + 0.02, h, absf(along.z) * w + 0.02), "l974_glass", GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		k.box(c + along * s * (w * 0.5 + 0.03), Vector3(absf(along.x) * 0.07 + absf(n.x) * 0.2, h + 0.1, absf(along.z) * 0.07 + absf(n.z) * 0.2), "l974_trim", GeoKit.ALL, false)
		k.box(c + Vector3.UP * s * (h * 0.5 + 0.03), Vector3(absf(along.x) * (w + 0.12) + absf(n.x) * 0.2, 0.07, absf(along.z) * (w + 0.12) + absf(n.z) * 0.2), "l974_trim", GeoKit.ALL, false)
	k.box(c + Vector3(0, -h * 0.5 - 0.06, 0) + n * 0.06, Vector3(absf(along.x) * (w + 0.2) + absf(n.x) * 0.3, 0.04, absf(along.z) * (w + 0.2) + absf(n.z) * 0.3), "l974_trim", GeoKit.ALL, false)
	# soft pink curtains either side
	for s in [-1.0, 1.0]:
		k.box(c + along * s * (w * 0.5 + 0.2) + n * 0.1 + Vector3(0, 0.12, 0), Vector3(absf(along.x) * 0.28 + absf(n.x) * 0.06, h + 0.6, absf(along.z) * 0.28 + absf(n.z) * 0.06), "l974_fabric_pink", GeoKit.ALL, false)


static func windows(k: GeoKit) -> Array:
	var list := [
		[Vector3(8.0, 1.5, 0.0), Vector3(0, 0, 1), 1.2, 1.1, 0, "bedroom"],
		[Vector3(2.3, B + 0.85 + 0.625, 8.0), Vector3(0, 0, -1), 2.2, 1.25, 1, "living"],
		[Vector3(9.1, 1.5, 8.0), Vector3(0, 0, -1), 1.4, 1.2, 2, "kitchen"],
		[Vector3(0.0, MASTER + 1.5, 1.5), Vector3(1, 0, 0), 1.2, 1.2, 0, "master"],
		[Vector3(0.0, B + 0.85 + 0.625, 6.1), Vector3(1, 0, 0), 1.4, 1.25, 2, "living"],
	]
	for wdef in list:
		window(k, wdef[0], wdef[1], wdef[2], wdef[3], wdef[4])
	return list


## Bedroom: twin bed nestled between two walls jutting from the east wall,
## open closet with a dresser next to the door, desk with an old computer
## parallel to the bed, plushies, cute posters.
static func bedroom(k: GeoKit) -> void:
	for z in [0.3, 2.36]:
		k.box_mm(Vector3(8.95, 0, z - 0.06), Vector3(10.0, CEIL, z + 0.06), "l974_wall")
	k.box_mm(Vector3(9.0, 0, 0.38), Vector3(9.98, 0.32, 2.3), "l974_trim")
	k.box_mm(Vector3(9.03, 0.32, 0.4), Vector3(9.96, 0.5, 2.28), "l974_porcelain")
	k.box_mm(Vector3(9.0, 0.5, 0.95), Vector3(9.98, 0.58, 2.29), "l974_bedding", GeoKit.ALL, false)
	k.box_mm(Vector3(9.15, 0.5, 0.45), Vector3(9.85, 0.64, 0.8), "l974_porcelain", GeoKit.ALL, false)
	k.box_mm(Vector3(8.94, 0, 2.42), Vector3(9.06, CEIL, 3.0), "l974_wall")
	k.box_mm(Vector3(7.55, 2.12, 2.4), Vector3(9.06, CEIL, 2.52), "l974_wall")
	k.box_mm(Vector3(7.7, 0, 2.52), Vector3(8.9, 0.86, 2.96), "l974_cabinet")
	for y in [0.2, 0.45, 0.7]:
		k.box(Vector3(8.3, y, 2.51), Vector3(0.9, 0.012, 0.01), "l974_trim", GeoKit.ALL, false)
		k.box(Vector3(8.3, y + 0.06, 2.505), Vector3(0.12, 0.025, 0.02), "l974_trim", GeoKit.ALL, false)
	k.box(Vector3(8.3, 1.92, 2.74), Vector3(1.3, 0.02, 0.02), "l974_trim", GeoKit.ALL, false)
	var cols := ["l974_bedding", "l974_cabinet", "l974_fabric_pink", "l974_trim", "l974_rug"]
	for i in 9:
		k.box(Vector3(7.8 + i * 0.12, 1.55, 2.74), Vector3(0.03, 0.7, 0.38), cols[i % cols.size()], GeoKit.ALL, false)
	k.box_mm(Vector3(6.2, 0.72, 0.3), Vector3(6.95, 0.76, 1.75), "l974_pinkwood")
	for p in [Vector2(6.24, 0.34), Vector2(6.9, 0.34), Vector2(6.24, 1.7), Vector2(6.9, 1.7)]:
		k.box(Vector3(p.x, 0.36, p.y), Vector3(0.04, 0.72, 0.04), "l974_trim")
	k.box_mm(Vector3(6.24, 0.76, 0.82), Vector3(6.64, 1.12, 1.22), "l974_beige", GeoKit.ALL, false)
	k.box_mm(Vector3(6.7, 0.76, 0.8), Vector3(6.86, 0.785, 1.22), "l974_beige", GeoKit.ALL, false)
	k.box_mm(Vector3(6.72, 0.76, 1.3), Vector3(6.8, 0.79, 1.38), "l974_beige", GeoKit.ALL, false)
	k.box_mm(Vector3(6.26, 0.0, 1.32), Vector3(6.46, 0.42, 1.66), "l974_beige")
	k.box_mm(Vector3(6.2, 1.36, 0.3), Vector3(6.45, 1.39, 1.75), "l974_pinkwood", GeoKit.ALL, false)
	k.cylinder(Vector3(7.3, 0.22, 1.0), 0.2, 0.44, "l974_cabinet", 14)
	k.cylinder(Vector3(7.9, 0.005, 1.5), 0.85, 0.01, "l974_rug", 24, false)
	k.quad(Vector3(6.205, 1.8, 1.0), Vector3(1, 0, 0), Vector3(0, 0, 0.26), Vector3(0, 0.36, 0), "l974_poster0", Vector2.ZERO, true)
	k.quad(Vector3(6.85, 1.6, 0.065), Vector3(0, 0, 1), Vector3(0.24, 0, 0), Vector3(0, 0.33, 0), "l974_poster1", Vector2.ZERO, true)
	k.quad(Vector3(9.5, 1.65, 2.295), Vector3(0, 0, -1), Vector3(0.24, 0, 0), Vector3(0, 0.33, 0), "l974_poster2", Vector2.ZERO, true)


## Master bedroom: empty except a pink and white cat bed at the back wall.
static func master(k: GeoKit) -> void:
	k.cylinder(Vector3(2.1, MASTER + 0.1, 0.55), 0.46, 0.2, "l974_fabric_pink", 20)
	k.cylinder(Vector3(2.1, MASTER + 0.16, 0.55), 0.35, 0.12, "l974_porcelain", 20, false)


static func baths(k: GeoKit) -> void:
	k.box_mm(Vector3(4.28, 0, 0.06), Vector3(6.14, 0.55, 0.82), "l974_porcelain")
	k.box_mm(Vector3(4.4, 0.4, 0.16), Vector3(6.02, 0.56, 0.72), "l974_dark", GeoKit.PY, false)
	k.box_mm(Vector3(4.3, 0, 1.5), Vector3(4.72, 0.42, 1.95), "l974_porcelain")
	k.box_mm(Vector3(4.27, 0.42, 1.5), Vector3(4.44, 0.8, 1.95), "l974_porcelain")
	k.box_mm(Vector3(5.72, 0, 1.2), Vector3(6.14, 0.84, 1.9), "l974_cabinet")
	k.box_mm(Vector3(5.7, 0.84, 1.18), Vector3(6.14, 0.9, 1.92), "l974_porcelain")
	k.quad(Vector3(6.135, 1.55, 1.55), Vector3(-1, 0, 0), Vector3(0, 0, 0.3), Vector3(0, 0.36, 0), "l974_mirror", Vector2.ZERO, true)
	k.box_mm(Vector3(10.98, 0, 0.06), Vector3(11.94, 0.08, 1.02), "l974_porcelain")
	k.box_mm(Vector3(10.97, 0.08, 0.06), Vector3(11.0, 2.0, 1.02), "l974_glass")
	k.box_mm(Vector3(10.08, 0, 0.3), Vector3(10.5, 0.42, 0.75), "l974_porcelain")
	k.box_mm(Vector3(10.07, 0.42, 0.3), Vector3(10.22, 0.8, 0.75), "l974_porcelain")
	k.cylinder(Vector3(11.75, 0.4, 1.9), 0.09, 0.8, "l974_porcelain", 12)
	k.box_mm(Vector3(11.5, 0.8, 1.6), Vector3(11.94, 0.9, 2.2), "l974_porcelain")
	k.quad(Vector3(11.935, 1.55, 1.9), Vector3(-1, 0, 0), Vector3(0, 0, 0.28), Vector3(0, 0.34, 0), "l974_mirror", Vector2.ZERO, true)


## Kitchen and dining: counters, sink, stove, fridge, pantry; a pink wooden
## banquette wrapping two sides of the table; everyday clutter.
static func kitchen(k: GeoKit, r: RandomNumberGenerator) -> void:
	k.box_mm(Vector3(8.6, 0, 4.27), Vector3(12.0, 0.88, 4.86), "l974_cabinet")
	k.box_mm(Vector3(8.58, 0.88, 4.26), Vector3(12.0, 0.92, 4.9), "l974_counter")
	k.box_mm(Vector3(9.6, 0.75, 4.4), Vector3(10.2, 0.921, 4.76), "l974_dark", GeoKit.PY, false)
	k.box_mm(Vector3(9.86, 0.92, 4.3), Vector3(9.94, 1.2, 4.36), "l974_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(11.0, 0.921, 4.32), Vector3(11.6, 0.93, 4.84), "l974_trim", GeoKit.ALL, false)
	for p in [Vector2(11.15, 4.45), Vector2(11.45, 4.45), Vector2(11.15, 4.7), Vector2(11.45, 4.7)]:
		k.cylinder(Vector3(p.x, 0.935, p.y), 0.08, 0.012, "l974_dark", 12, false)
	k.box_mm(Vector3(8.6, 1.45, 4.27), Vector3(12.0, 2.15, 4.6), "l974_cabinet", GeoKit.ALL, false)
	for x in range(0, 6):
		k.box(Vector3(8.9 + x * 0.57, 1.5, 4.605), Vector3(0.1, 0.02, 0.02), "l974_trim", GeoKit.ALL, false)
		k.box(Vector3(8.9 + x * 0.57, 0.8, 4.865), Vector3(0.1, 0.02, 0.02), "l974_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(11.25, 0, 5.0), Vector3(11.98, 1.75, 5.75), "l974_fridge_metal")
	k.box_mm(Vector3(11.2, 1.0, 5.1), Vector3(11.25, 1.5, 5.14), "l974_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(11.4, 0, 5.85), Vector3(11.98, 2.1, 6.65), "l974_cabinet")
	k.box_mm(Vector3(11.39, 0.05, 6.24), Vector3(11.4, 2.05, 6.26), "l974_trim", GeoKit.ALL, false)
	# banquette (pink wood) wrapping the SW corner and the table
	k.box_mm(Vector3(5.26, 0, 7.45), Vector3(7.6, 0.45, 7.94), "l974_pinkwood")
	k.box_mm(Vector3(5.26, 0.45, 7.8), Vector3(7.6, 0.98, 7.94), "l974_pinkwood")
	k.box_mm(Vector3(5.26, 0, 6.1), Vector3(5.75, 0.45, 7.45), "l974_pinkwood")
	k.box_mm(Vector3(5.26, 0.45, 6.1), Vector3(5.4, 0.98, 7.8), "l974_pinkwood")
	k.box_mm(Vector3(5.4, 0.45, 7.47), Vector3(7.55, 0.52, 7.8), "l974_fabric_pink", GeoKit.ALL, false)
	k.box_mm(Vector3(5.42, 0.45, 6.12), Vector3(5.73, 0.52, 7.47), "l974_fabric_pink", GeoKit.ALL, false)
	k.box_mm(Vector3(5.95, 0.72, 6.3), Vector3(7.25, 0.77, 7.35), "l974_pinkwood")
	k.cylinder(Vector3(6.6, 0.36, 6.82), 0.07, 0.72, "l974_trim", 10)
	k.cylinder(Vector3(6.6, 0.02, 6.82), 0.3, 0.04, "l974_trim", 16, false)
	# clutter: kettle, utensil crock, cutting board, fruit bowl, mugs, wall clock, outlets, vents
	var tint: String = ["l974_cabinet", "l974_fabric_pink", "l974_porcelain"][r.randi() % 3]
	k.cylinder(Vector3(11.3, 1.03, 4.57), 0.1, 0.2, tint, 12, false)
	k.cylinder(Vector3(9.1, 1.0, 4.45), 0.06, 0.16, "l974_porcelain", 10, false)
	for i in 3 + r.randi() % 3:
		k.box(Vector3(9.08 + i * 0.015, 1.15, 4.45 + (i % 2) * 0.02), Vector3(0.012, 0.22, 0.03), ["l974_dark", "l974_cabinet", "l974_trim"][i % 3], GeoKit.ALL, false)
	k.box_mm(Vector3(10.4, 0.92, 4.35), Vector3(10.8, 0.94, 4.7), "l974_pinkwood", GeoKit.ALL, false)
	k.cylinder(Vector3(6.6, 0.8, 6.82), 0.16, 0.06, "l974_porcelain", 16, false)
	for p in [Vector3(6.52, 0.86, 6.78), Vector3(6.68, 0.86, 6.88), Vector3(6.6, 0.88, 6.72)]:
		k.cylinder(p, 0.045, 0.07, "l974_fabric_pink", 10, false)
	k.cylinder(Vector3(7.0, 0.82, 6.5), 0.045, 0.1, "l974_cabinet", 10, false)
	k.cylinder(Vector3(10.0, 1.95, 7.99), 0.16, 0.03, "l974_trim", 20, false)
	for o in [Vector3(8.0, 0.3, 7.99), Vector3(6.2, 0.3, 0.07), Vector3(1.0, 0.0, 7.99), Vector3(11.99, 1.1, 7.0)]:
		k.box(o, Vector3(0.08, 0.12, 0.02) if absf(o.x - 11.99) > 0.1 else Vector3(0.02, 0.12, 0.08), "l974_trim", GeoKit.ALL, false)
	for v in [Vector3(9.5, CEIL - 0.005, 6.0), Vector3(6.0, CEIL - 0.005, 3.6), Vector3(2.5, CEIL - 0.005, 5.5)]:
		k.box(v, Vector3(0.4, 0.01, 0.25), "l974_trim", GeoKit.ALL, false)


## Light switches by each doorway (electricity works per the page).
static func switches(k: GeoKit) -> void:
	for s in [Vector3(4.15, 1.2, 3.06), Vector3(2.8, 1.2 + MASTER, 2.94), Vector3(6.3, 1.2, 2.94), Vector3(5.6, 1.2, 2.94),
			Vector3(8.5, 1.2, 4.26), Vector3(3.2, 1.2, 4.26), Vector3(10.4, 1.2, 2.94)]:
		k.box(s, Vector3(0.07, 0.11, 0.02), "l974_trim", GeoKit.ALL, false)


## Empty photo frames (page: "empty photo frames adorning the walls"),
## tailored per wanderer: count and placement vary with the seed.
static func frames(k: GeoKit, r: RandomNumberGenerator) -> void:
	var spots := [Vector3(1.4, 1.55, 3.065), Vector3(2.2, 1.7, 3.065), Vector3(8.6, 1.6, 3.065), Vector3(9.4, 1.5, 3.065),
		Vector3(1.5, B + 1.6, 4.265), Vector3(0.065, B + 1.7, 7.4), Vector3(5.135, B + 1.6, 7.0), Vector3(11.0, 1.6, 4.135)]
	for i in spots.size():
		if r.randf() < 0.3:
			continue
		var p: Vector3 = spots[i]
		var n := Vector3(0, 0, 1) if absf(p.z - 3.065) < 0.01 or absf(p.z - 4.265) < 0.01 else (Vector3(1, 0, 0) if p.x < 0.1 else (Vector3(-1, 0, 0) if absf(p.x - 5.135) < 0.01 else Vector3(0, 0, -1)))
		var along := Vector3(-n.z, 0, n.x)
		var w := 0.3 + r.randf() * 0.2
		var h := 0.25 + r.randf() * 0.2
		k.box(p, Vector3(absf(along.x) * w + absf(n.x) * 0.03, h, absf(along.z) * w + absf(n.z) * 0.03), "l974_trim" if i % 2 == 0 else "l974_pinkwood", GeoKit.ALL, false)
		k.quad(p + n * 0.017, n, along * (w * 0.5 - 0.04), Vector3(0, h * 0.5 - 0.04, 0), "l974_ceiling", Vector2.ZERO, true)


## Pastel plushies from primitive shapes: bears and bunnies.
static func plush(parent: Node3D, pos: Vector3, yaw: float, color: Color, bunny: bool, s: float = 1.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * s
	parent.add_child(root)
	var parts := [[Vector3(0, 0.09, 0), Vector3(0.09, 0.1, 0.08)], [Vector3(0, 0.24, 0.0), Vector3(0.075, 0.07, 0.07)],
		[Vector3(-0.07, 0.12, -0.04), Vector3(0.03, 0.05, 0.03)], [Vector3(0.07, 0.12, -0.04), Vector3(0.03, 0.05, 0.03)],
		[Vector3(-0.05, 0.02, -0.05), Vector3(0.035, 0.03, 0.04)], [Vector3(0.05, 0.02, -0.05), Vector3(0.035, 0.03, 0.04)]]
	if bunny:
		parts.append([Vector3(-0.03, 0.36, 0.0), Vector3(0.02, 0.08, 0.015)])
		parts.append([Vector3(0.03, 0.36, 0.0), Vector3(0.02, 0.08, 0.015)])
	else:
		parts.append([Vector3(-0.055, 0.3, 0.0), Vector3(0.025, 0.025, 0.015)])
		parts.append([Vector3(0.055, 0.3, 0.0), Vector3(0.025, 0.025, 0.015)])
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.06, 0.04, 0.05)
	for p in parts:
		root.add_child(_sph(p[0], p[1], m))
	for sx in [-0.025, 0.025]:
		root.add_child(_sph(Vector3(sx, 0.25, -0.065), Vector3(0.009, 0.009, 0.006), eye))


static func _sph(pos: Vector3, rad: Vector3, mat: Material) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = sm
	mi.position = pos
	mi.scale = rad
	mi.material_override = mat
	return mi
