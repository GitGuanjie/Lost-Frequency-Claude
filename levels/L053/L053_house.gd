extends RefCounted
## Level 53 house: Allen Grady's ordinary two-storey suburban home with a basement,
## December 2008, Christmas decorations still up, glass and fallen things on the floor.
## Plan (x east, -z north, front door on the south side at z = 5):
##  ground (y 0)   living room W, hall with the stair up, study SE, basement stairwell E,
##                 dining NW and kitchen N/NE
##  upstairs (2.9) master bedroom SW, spare room NW, kids' room SE (the old hamster cage
##                 with Louie), bathroom NE, landing round the stairwell
##  basement (-2.6) bare concrete: furnace, water heater, shelves of saved food, washer
## Outside (seen, never reached): porch, front lawn, the street, houses opposite and
## either side, a back yard. All outside geometry sits beyond glass or a loop trigger.

const T := 0.2
const TI := 0.12
const UP := 2.9
const BASE := -2.6
const H1 := 2.6
const H2 := 2.5
const DOOR := Vector3(0.1, 0.0, 5.0)

var L: LevelBase
var props: Node3D
var k: GeoKit
var panes: Array = []        # [{c, size}] glass panes (for the "try the window" prompt)
var broken := Vector3(-3.8, 0.0, -5.0)


func _init(level: LevelBase, root: Node3D) -> void:
	L = level
	props = root


static func materials() -> void:
	MatLib.define("l53_wall", {"albedo_a": Color(0.80, 0.76, 0.66), "albedo_b": Color(0.76, 0.72, 0.62), "noise_scale": 1.5,
		"stain_amount": 0.12, "stain_color": Color(0.62, 0.56, 0.44), "grime_height": 0.15, "grime_color": Color(0.55, 0.5, 0.4)}, "plaster")
	MatLib.define("l53_wall_green", {"albedo_a": Color(0.58, 0.66, 0.56), "albedo_b": Color(0.54, 0.62, 0.52), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.62, 0.70, 0.60), "pattern_strength": 0.3}, "plaster")
	MatLib.define("l53_wall_blue", {"albedo_a": Color(0.55, 0.66, 0.78), "albedo_b": Color(0.50, 0.61, 0.73)}, "plaster")
	MatLib.define("l53_tile", {"albedo_a": Color(0.86, 0.86, 0.82), "albedo_b": Color(0.82, 0.82, 0.78), "pattern": 1,
		"pattern_scale": Vector2(0.3, 0.3), "grout_width": 0.008, "grout_color": Color(0.6, 0.6, 0.56), "roughness_a": 0.2,
		"roughness_b": 0.35})
	MatLib.define("l53_floor_tile", {"albedo_a": Color(0.78, 0.74, 0.66), "albedo_b": Color(0.72, 0.68, 0.60), "pattern": 9,
		"pattern_scale": Vector2(0.33, 0.33), "pattern_color": Color(0.55, 0.50, 0.42), "pattern_strength": 0.35,
		"roughness_a": 0.3, "roughness_b": 0.45})
	MatLib.define("l53_wood", {"albedo_a": Color(0.52, 0.34, 0.20), "albedo_b": Color(0.45, 0.29, 0.17), "pattern": 3,
		"pattern_scale": Vector2(1.4, 0.13), "grout_width": 0.003}, "wood_floor")
	MatLib.define("l53_carpet", {"albedo_a": Color(0.55, 0.50, 0.42), "albedo_b": Color(0.50, 0.45, 0.38), "pattern": 6,
		"pattern_strength": 0.1, "noise_scale": 6.0, "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 0.6})
	MatLib.define("l53_concrete", {"albedo_a": Color(0.50, 0.49, 0.46), "albedo_b": Color(0.42, 0.41, 0.38), "stain_amount": 0.3,
		"stain_color": Color(0.34, 0.32, 0.28), "wetness": 0.15}, "concrete")
	MatLib.define("l53_trim", {"albedo_a": Color(0.92, 0.90, 0.85), "albedo_b": Color(0.88, 0.86, 0.80)}, "trim_white")
	MatLib.define("l53_ceiling", {"albedo_a": Color(0.90, 0.89, 0.85), "albedo_b": Color(0.87, 0.86, 0.82), "noise_scale": 2.0,
		"bump_strength": 0.2}, "plaster")
	MatLib.define("l53_siding", {"albedo_a": Color(0.82, 0.80, 0.72), "albedo_b": Color(0.76, 0.74, 0.66), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.2), "pattern_color": Color(0.6, 0.58, 0.52), "pattern_strength": 0.5, "uv_rotate": 1.5708}, "plaster")
	MatLib.define("l53_roof", {"albedo_a": Color(0.25, 0.22, 0.21), "albedo_b": Color(0.20, 0.18, 0.17), "pattern": 14,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.01, "grout_color": Color(0.12, 0.1, 0.1)})
	MatLib.define("l53_red_door", {"albedo_a": Color(0.55, 0.06, 0.05), "albedo_b": Color(0.48, 0.05, 0.04), "pattern": 3,
		"pattern_scale": Vector2(0.2, 2.0), "grout_width": 0.002, "roughness_a": 0.4, "roughness_b": 0.5}, "wood_floor")
	MatLib.define("l53_counter", {"albedo_a": Color(0.30, 0.28, 0.26), "albedo_b": Color(0.24, 0.22, 0.21), "pattern": 15,
		"pattern_color": Color(0.5, 0.48, 0.44), "pattern_strength": 0.4, "roughness_a": 0.25, "roughness_b": 0.35})
	MatLib.define("l53_cabinet", {"albedo_a": Color(0.72, 0.62, 0.46), "albedo_b": Color(0.66, 0.56, 0.40), "pattern": 3,
		"pattern_scale": Vector2(0.15, 1.5), "grout_width": 0.002}, "wood_floor")
	MatLib.define("l53_fabric", {"albedo_a": Color(0.32, 0.36, 0.30), "albedo_b": Color(0.28, 0.32, 0.26), "noise_scale": 6.0,
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 0.6})
	MatLib.define("l53_sheet", {"albedo_a": Color(0.70, 0.72, 0.76), "albedo_b": Color(0.64, 0.66, 0.70), "pattern": 9,
		"pattern_scale": Vector2(0.2, 0.2), "pattern_strength": 0.15})
	MatLib.define("l53_lawn", {"albedo_a": Color(0.26, 0.36, 0.16), "albedo_b": Color(0.20, 0.30, 0.12)}, "grass")
	MatLib.define("l53_asphalt", {"albedo_a": Color(0.20, 0.20, 0.21)}, "asphalt")
	MatLib.define("l53_pavement", {"albedo_a": Color(0.62, 0.61, 0.58), "albedo_b": Color(0.56, 0.55, 0.52), "pattern": 1,
		"pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.01, "grout_color": Color(0.4, 0.4, 0.38)}, "concrete")
	MatLib.define("l53_tree_green", {"albedo_a": Color(0.06, 0.20, 0.09), "albedo_b": Color(0.04, 0.15, 0.07), "noise_scale": 8.0,
		"bump_strength": 1.5, "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l53_bark", {"albedo_a": Color(0.25, 0.18, 0.12), "albedo_b": Color(0.20, 0.14, 0.10), "noise_scale": 5.0}, "dirt")
	MatLib.define("l53_leaves", {"albedo_a": Color(0.22, 0.34, 0.14), "albedo_b": Color(0.16, 0.27, 0.10), "noise_scale": 3.0,
		"bump_strength": 1.6, "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l53_steel", {"albedo_a": Color(0.6, 0.6, 0.62), "albedo_b": Color(0.52, 0.52, 0.54)}, "metal")
	MatLib.define("l53_black", {"albedo_a": Color(0.04, 0.04, 0.045), "albedo_b": Color(0.03, 0.03, 0.035), "roughness_a": 0.3,
		"roughness_b": 0.4}, "plaster")
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.75, 0.85, 0.9, 0.12)
	g.roughness = 0.03
	g.metallic_specular = 0.9
	MatLib.register("l53_glass", g)
	var cols := {"red": Color(1, 0.15, 0.1), "green": Color(0.2, 1, 0.3), "blue": Color(0.25, 0.4, 1), "gold": Color(1, 0.8, 0.3)}
	for key in cols.keys():
		MatLib.register("l53_bulb_" + key, MatLib.panel(cols[key], 3.0, 0.08, randf() * 10.0))
	MatLib.register("l53_lamp", MatLib.panel(Color(1.0, 0.9, 0.72), 2.2))
	MatLib.register("l53_tv", MatLib.panel(Color(0.7, 0.75, 0.8), 1.4, 0.9, 2.0))
	MatLib.register("l53_screen", MatLib.panel(Color(0.55, 0.7, 0.95), 1.2))
	for key in [["red", Color(0.7, 0.08, 0.08)], ["green", Color(0.1, 0.45, 0.2)], ["gold", Color(0.8, 0.62, 0.2)], ["blue", Color(0.15, 0.25, 0.65)]]:
		MatLib.register("l53_paper_" + key[0], MatLib.standard(key[1], 0.5))


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


## A window in an exterior wall: frame, sill, mullion and a glass pane with collision.
func window(c: Vector3, along_x: bool, w: float, h: float, outward: float) -> void:
	var t := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var n := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	var sz := func(a: float, b: float, d: float) -> Vector3: return (Vector3(a, b, d) if along_x else Vector3(d, b, a))
	k.box(c, sz.call(w, h, 0.02), "l53_glass", GeoKit.ALL, true)
	panes.append({"c": c, "size": sz.call(w, h, 0.3)})
	k.box(c - n * outward * 0.06 + Vector3(0, -h * 0.5 - 0.03, 0), sz.call(w + 0.16, 0.05, 0.22), "l53_trim", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(c + t * s * (w * 0.5 + 0.03), sz.call(0.06, h + 0.06, 0.24), "l53_trim", GeoKit.ALL, false)
	k.box(c + Vector3(0, h * 0.5 + 0.03, 0), sz.call(w + 0.12, 0.06, 0.24), "l53_trim", GeoKit.ALL, false)
	k.box(c, sz.call(0.04, h, 0.05), "l53_trim", GeoKit.ALL, false)
	k.box(c + Vector3(0, h * 0.08, 0), sz.call(w, 0.04, 0.05), "l53_trim", GeoKit.ALL, false)


## Exterior wall of one storey with window openings; windows: [[at, w, h, sill]].
func ext_wall(a: Vector3, b: Vector3, h: float, mat: String, wins: Array, door := -1.0, door_w := 1.0) -> void:
	var ops := []
	for wv in wins:
		ops.append({"at": wv[0], "w": wv[1], "h": wv[2], "sill": wv[3]})
	if door >= 0.0:
		ops.append({"at": door, "w": door_w, "h": 2.12, "sill": 0.0})
	var along_x := absf(b.x - a.x) > absf(b.z - a.z)
	var dir := (b - a).normalized()
	var outward := 1.0 if (along_x and a.z > 0.0) or (not along_x and a.x > 0.0) else -1.0
	var n := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	# inner face in the room's paint, outer face in siding
	k.wall(a - n * outward * 0.06, b - n * outward * 0.06, h, 0.12, mat, ops)
	k.wall(a + n * outward * 0.06, b + n * outward * 0.06, h, 0.12, "l53_siding", ops)
	for wv in wins:
		if wv.size() > 4 and wv[4] == "broken":
			continue
		window(a + dir * float(wv[0]) + Vector3(0, float(wv[3]) + float(wv[2]) * 0.5, 0), along_x, float(wv[1]), float(wv[2]), outward)


func shell() -> void:
	k = L.kit("House")
	# floors: basement concrete, ground (holes for the basement stair), upstairs (stairwell hole)
	k.slab(-6, -5, 6, 5, BASE, 0.3, "l53_concrete")
	for r in [[-6, -5, 1.6, 5], [1.6, -5, 6, 0], [1.6, 0.95, 6, 5], [4.85, 0, 6, 0.95]]:
		k.slab(r[0], r[1], r[2], r[3], 0.0, 0.3, "l53_wood")
	for r in [[-6, -5, -1, 5], [0, -5, 6, 5], [-1, -5, 0, -0.32], [-1, 4.0, 0, 5]]:
		k.slab(r[0], r[1], r[2], r[3], UP, 0.3, "l53_carpet")
	# ground-floor rooms: kitchen tiles, hall/study wood
	k.box(Vector3(0.0, 0.004, -2.75), Vector3(12.0, 0.008, 4.5), "l53_floor_tile", GeoKit.PY, false)
	k.box(Vector3(3.5, UP + 0.004, -2.25), Vector3(5.0, 0.008, 5.5), "l53_tile", GeoKit.PY, false)
	k.slab(-6.2, -5.2, 6.2, 5.2, UP + H2 + 0.15, 0.15, "l53_ceiling")
	# roof: a simple gable over the whole house
	for s in [-1.0, 1.0]:
		var a := Vector3(0, UP + H2 + 0.15, s * 5.6)
		var b := Vector3(0, UP + H2 + 2.4, 0)
		var z := (b - a).normalized()
		var xv := Vector3.UP.cross(z).normalized()
		k.box_xf(Transform3D(Basis(xv, z.cross(xv), z), (a + b) * 0.5 + z.cross(xv) * 0.08), Vector3(13.0, 0.16, (b - a).length()), "l53_roof", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		for i in 6:
			var hh := 2.25 * (1.0 - float(i) / 6.0)
			k.box(Vector3(s * 6.06, UP + H2 + 0.15 + hh * 0.5, 0), Vector3(0.12, hh, 10.4 * (1.0 - float(i) / 6.0) + 0.6), "l53_siding", GeoKit.ALL, false)
	# basement walls (below grade)
	for w in [[Vector3(-6, BASE, -5), Vector3(6, BASE, -5)], [Vector3(-6, BASE, 5), Vector3(6, BASE, 5)], [Vector3(-6, BASE, -5), Vector3(-6, BASE, 5)], [Vector3(6, BASE, -5), Vector3(6, BASE, 5)]]:
		k.wall(w[0], w[1], -BASE - 0.3, T, "l53_concrete")
	# ground floor exterior (windows: at, w, h, sill)
	ext_wall(Vector3(-6, 0, 5), Vector3(6, 0, 5), H1, "l53_wall", [[2.5, 2.2, 1.4, 0.8], [9.6, 1.6, 1.3, 0.9]], 6.1, 1.0)
	ext_wall(Vector3(-6, 0, -5), Vector3(6, 0, -5), H1, "l53_wall", [[2.2, 1.2, 1.9, 0.3, "broken"], [8.5, 1.6, 1.0, 1.1]])
	ext_wall(Vector3(-6, 0, -5), Vector3(-6, 0, 5), H1, "l53_wall", [[2.2, 1.4, 1.3, 0.9], [7.0, 1.4, 1.3, 0.9]])
	ext_wall(Vector3(6, 0, -5), Vector3(6, 0, 5), H1, "l53_wall", [[2.0, 1.0, 1.0, 1.1], [8.2, 1.2, 1.2, 0.9]])
	# upstairs exterior
	ext_wall(Vector3(-6, UP, 5), Vector3(6, UP, 5), H2, "l53_wall_blue", [[2.5, 1.6, 1.3, 0.8], [6.6, 0.7, 1.0, 1.0], [9.6, 1.4, 1.3, 0.8]])
	ext_wall(Vector3(-6, UP, -5), Vector3(6, UP, -5), H2, "l53_wall", [[2.5, 1.2, 1.2, 0.9], [9.5, 0.7, 0.7, 1.4]])
	ext_wall(Vector3(-6, UP, -5), Vector3(-6, UP, 5), H2, "l53_wall", [[2.2, 1.2, 1.2, 0.9], [7.0, 1.2, 1.2, 0.9]])
	ext_wall(Vector3(6, UP, -5), Vector3(6, UP, 5), H2, "l53_wall_green", [[2.5, 0.7, 0.7, 1.4], [7.5, 1.2, 1.2, 0.9]])
	# the band between storeys, outside
	for bnd in [[Vector3(0, 2.75, 5.06), Vector3(12.24, 0.3, 0.12)], [Vector3(0, 2.75, -5.06), Vector3(12.24, 0.3, 0.12)],
			[Vector3(6.06, 2.75, 0), Vector3(0.12, 0.3, 10.24)], [Vector3(-6.06, 2.75, 0), Vector3(0.12, 0.3, 10.24)]]:
		k.box(bnd[0], bnd[1], "l53_trim", GeoKit.ALL, false)
	# ground interior walls
	k.wall(Vector3(-1, 0, -0.5), Vector3(-1, 0, 5), H1, TI, "l53_wall", [{"at": 5.0, "w": 0.9, "h": 2.1}])
	k.wall(Vector3(-6, 0, -0.5), Vector3(-1, 0, -0.5), H1, TI, "l53_wall", [{"at": 3.0, "w": 1.6, "h": 2.2}])
	k.wall(Vector3(-1, 0, -0.5), Vector3(1.2, 0, -0.5), H1, TI, "l53_wall", [{"at": 1.6, "w": 1.2, "h": 2.3}])
	k.wall(Vector3(1.2, 0, -0.5), Vector3(6, 0, -0.5), H1, TI, "l53_wall")
	k.wall(Vector3(1.2, 0, -0.5), Vector3(1.2, 0, 5), H1, TI, "l53_wall", [{"at": 0.975, "w": 0.85, "h": 2.05}, {"at": 3.9, "w": 0.9, "h": 2.1}])
	k.wall(Vector3(1.2, 0, 1.5), Vector3(6, 0, 1.5), H1, TI, "l53_wall_green")
	# upstairs interior walls
	k.wall(Vector3(-1, UP, -5), Vector3(-1, UP, 5), H2, TI, "l53_wall_blue", [{"at": 2.5, "w": 0.85, "h": 2.05}, {"at": 9.5, "w": 0.85, "h": 2.05}])
	k.wall(Vector3(-6, UP, 0.2), Vector3(-1, UP, 0.2), H2, TI, "l53_wall")
	k.wall(Vector3(1.2, UP, -5), Vector3(1.2, UP, 5), H2, TI, "l53_wall_green", [{"at": 3.5, "w": 0.8, "h": 2.05}, {"at": 7.5, "w": 0.85, "h": 2.05}])
	k.wall(Vector3(1.2, UP, 0.5), Vector3(6, UP, 0.5), H2, TI, "l53_tile")
	# stairs: up from the hall, down from the stairwell door to the basement
	k.stairs(Vector3(-0.5, 0, 4.0), Vector3(0, 0, -1), 1.0, UP, 16, "l53_carpet", 0.27)
	k.stairs(Vector3(4.85, BASE, 0.475), Vector3(-1, 0, 0), 0.95, -BASE, 13, "l53_wood", 0.25)
	# railings: stairwell (upstairs), basement opening (ground), hand rails
	k.wall(Vector3(0.0, UP, -0.32), Vector3(0.0, UP, 4.0), 0.95, 0.05, "l53_trim")
	k.wall(Vector3(-1.0, UP, 4.0), Vector3(0.0, UP, 4.0), 0.95, 0.05, "l53_trim")
	k.wall(Vector3(1.6, 0, -0.02), Vector3(4.85, 0, -0.02), 0.95, 0.05, "l53_trim")
	k.wall(Vector3(4.87, 0, -0.02), Vector3(4.87, 0, 0.97), 0.95, 0.05, "l53_trim")
	k.wall(Vector3(2.0, 0, 0.97), Vector3(4.87, 0, 0.97), 0.95, 0.05, "l53_trim")
	var ha := Vector3(0.02, 0.95, 4.0)
	var hb := Vector3(0.02, UP + 0.95, -0.32)
	var hz := (hb - ha).normalized()
	var hx := Vector3.UP.cross(hz).normalized()
	k.box_xf(Transform3D(Basis(hx, hz.cross(hx), hz), (ha + hb) * 0.5), Vector3(0.06, 0.06, (hb - ha).length()), "l53_cabinet", GeoKit.ALL, false)
	for i in 5:
		var f := float(i) / 4.0
		k.box(ha.lerp(hb, f) - Vector3(0, 0.47, 0), Vector3(0.04, 0.95, 0.04), "l53_trim", GeoKit.ALL, false)
	# skirting and ceiling lamps
	for c in [Vector3(-3.5, H1 - 0.02, 2.2), Vector3(-3.5, H1 - 0.02, -2.8), Vector3(3.0, H1 - 0.02, -2.8), Vector3(3.6, H1 - 0.02, 3.2),
			Vector3(0.6, H1 - 0.02, 2.0), Vector3(-3.5, UP + H2 - 0.02, 2.6), Vector3(-3.5, UP + H2 - 0.02, -2.4),
			Vector3(3.6, UP + H2 - 0.02, 2.8), Vector3(3.5, UP + H2 - 0.02, -2.2), Vector3(0.6, UP + H2 - 0.02, -2.0)]:
		k.cylinder(c, 0.18, 0.04, "l53_lamp", 14, false)
	k.commit()


## The front door: red-painted outside, white inside; swings on a pivot; mail slot.
func front_door() -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "FrontDoorPivot"
	pivot.position = DOOR + Vector3(-0.48, 0, 0.0)
	L.add_child(pivot)
	var dk := GeoKit.new(pivot, "FrontDoor")
	dk.box(Vector3(0.48, 1.05, 0.03), Vector3(0.94, 2.08, 0.04), "l53_red_door", GeoKit.ALL, true)
	dk.box(Vector3(0.48, 1.05, -0.015), Vector3(0.94, 2.08, 0.01), "l53_trim", GeoKit.ALL, false)
	dk.box(Vector3(0.48, 1.0, -0.025), Vector3(0.3, 0.05, 0.01), "l53_steel", GeoKit.ALL, false)
	dk.box(Vector3(0.48, 1.0, 0.055), Vector3(0.3, 0.06, 0.01), "l53_steel", GeoKit.ALL, false)
	dk.box(Vector3(0.84, 1.0, -0.04), Vector3(0.06, 0.04, 0.05), "l53_steel", GeoKit.ALL, false)
	# a wreath on the outside (the decorations are still up)
	dk.cylinder(Vector3(0.48, 1.55, 0.08), 0.22, 0.06, "l53_tree_green", 14, false)
	dk.box(Vector3(0.48, 1.36, 0.1), Vector3(0.08, 0.06, 0.03), "l53_bulb_red", GeoKit.ALL, false)
	dk.commit()
	var fk := L.kit("DoorFrame")
	for s in [-1.0, 1.0]:
		fk.box(DOOR + Vector3(s * 0.53, 1.08, 0), Vector3(0.08, 2.16, 0.26), "l53_trim", GeoKit.ALL, false)
	fk.box(DOOR + Vector3(0, 2.16, 0), Vector3(1.14, 0.08, 0.26), "l53_trim", GeoKit.ALL, false)
	fk.commit()
	return pivot


func interior() -> Dictionary:
	var out := {}
	k = L.kit("Furnishing")
	# living room: couch facing the TV on the west wall, the Christmas tree by the front window
	p("ph/Sofa_01", Vector3(-2.2, 0, 2.2), 90.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(-3.4, 0, 4.1), 160.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(-3.6, 0, 2.2), 0.0, 0.42, true)
	p("kenney/furniture-kit/cabinettelevision", Vector3(-5.6, 0, 2.2), 90.0, 0.55, true)
	p("ph/Television_01", Vector3(-5.6, 0.55, 2.2), 90.0)
	out["tv"] = Vector3(-5.45, 0.8, 2.2)
	k.box(Vector3(-5.31, 0.8, 2.2), Vector3(0.01, 0.3, 0.4), "l53_tv", GeoKit.ALL, false)
	p("kenney/furniture-kit/lamproundfloor", Vector3(-5.5, 0, 0.0), 0.0, 1.5)
	p("kenney/furniture-kit/rugrectangle", Vector3(-3.5, 0.005, 2.2), 90.0, 0.01)
	p("ph/wooden_bookshelf_worn", Vector3(-5.65, 0, 4.3), 90.0, 1.9, true)
	out["tree"] = _christmas_tree(Vector3(-5.1, 0, 4.4))
	# hall: coat rack, mat, a mirror, garland along the banister
	p("kenney/furniture-kit/coatrackstanding", Vector3(1.0, 0, 4.6), 0.0, 1.75)
	p("kenney/furniture-kit/rugdoormat", Vector3(0.1, 0.005, 4.55), 0.0, 0.01)
	p("ph/ornate_mirror_01", Vector3(1.13, 1.5, 2.4), -90.0)
	var ga := Vector3(0.02, 0.86, 4.0)
	var gb := Vector3(0.02, UP + 0.86, -0.32)
	var gz := (gb - ga).normalized()
	var gx := Vector3.UP.cross(gz).normalized()
	k.box_xf(Transform3D(Basis(gx, gz.cross(gx), gz), (ga + gb) * 0.5), Vector3(0.09, 0.09, (gb - ga).length()), "l53_tree_green", GeoKit.ALL, false)
	for i in 14:
		var c := ga.lerp(gb, (float(i) + 0.5) / 14.0)
		k.box(c + Vector3(0.05, -0.04, 0), Vector3(0.025, 0.025, 0.025), ["l53_bulb_red", "l53_bulb_gold", "l53_bulb_green"][i % 3], GeoKit.ALL, false)
	# study: desk with the laptop and paper, chair, filing
	p("ph/metal_office_desk", Vector3(4.6, 0, 4.4), 180.0, 0.0, true)
	p("ph/classic_laptop", Vector3(4.2, 0.79, 4.4), 180.0)
	p("ph/office_notepads", Vector3(5.1, 0.79, 4.5), 170.0, 0.0)
	p("ph/stationery_supplies", Vector3(5.6, 0.79, 4.6), 180.0)
	p("ph/SchoolChair_01", Vector3(4.6, 0, 3.5), 10.0)
	p("ph/drawer_cabinet", Vector3(5.7, 0, 2.2), -90.0, 1.3, true)
	p("ph/wall_clock", Vector3(1.27, 1.95, 3.0), 90.0)
	out["desk"] = Vector3(4.9, 0.85, 4.35)
	out["laptop"] = Vector3(4.2, 0.95, 4.4)
	out["clock"] = Vector3(1.3, 1.95, 3.0)
	# kitchen: counters along the north wall, sink under the window, stove, fridge, cookbook
	k.box_mm(Vector3(0.0, 0, -5.0), Vector3(5.9, 0.88, -4.4), "l53_cabinet")
	k.box_mm(Vector3(-0.02, 0.88, -5.0), Vector3(5.92, 0.92, -4.38), "l53_counter")
	k.box_mm(Vector3(0.0, 1.45, -5.0), Vector3(1.7, 2.2, -4.65), "l53_cabinet")
	k.box_mm(Vector3(3.3, 1.45, -5.0), Vector3(4.8, 2.2, -4.65), "l53_cabinet")
	k.box(Vector3(2.5, 0.9, -4.7), Vector3(0.7, 0.04, 0.45), "l53_steel", GeoKit.ALL, false)
	k.box_mm(Vector3(4.9, 0, -2.6), Vector3(5.9, 0.9, -1.0), "l53_cabinet")
	k.box_mm(Vector3(4.88, 0.9, -2.62), Vector3(5.92, 0.94, -0.98), "l53_counter")
	p("kenney/furniture-kit/kitchenstove", Vector3(0.9, 0, -4.68), 180.0, 0.92, true)
	p("kenney/furniture-kit/kitchenfridgelarge", Vector3(5.45, 0, -3.55), -90.0, 1.85, true)
	p("kenney/furniture-kit/kitchenmicrowave", Vector3(3.9, 0.92, -4.7), 180.0, 0.32)
	p("kenney/furniture-kit/kitchencoffeemachine", Vector3(4.6, 0.92, -4.75), 180.0, 0.3)
	p("kenney/furniture-kit/toaster", Vector3(5.4, 0.94, -2.2), -90.0, 0.2)
	p("kenney/food-kit/frying-pan", Vector3(0.9, 0.93, -4.65), 30.0, 0.06)
	p("kenney/food-kit/knife-block", Vector3(1.7, 0.92, -4.8), 180.0, 0.3)
	p("kenney/food-kit/cutting-board", Vector3(3.2, 0.92, -4.65), 10.0, 0.03)
	p("ph/binder_notebook", Vector3(5.4, 0.94, -1.5), -80.0)
	out["stove"] = Vector3(0.9, 1.1, -4.4)
	out["fridge"] = Vector3(5.0, 1.0, -3.55)
	out["sink"] = Vector3(2.5, 1.1, -4.5)
	out["cookbook"] = Vector3(5.4, 0.97, -1.5)
	# dining: table and chairs, one chair knocked over in the fall
	p("ph/dining_table", Vector3(-3.6, 0, -2.8), 0.0, 0.0, true)
	for c in [[Vector3(-4.5, 0, -2.0), 180.0], [Vector3(-2.7, 0, -2.0), 180.0], [Vector3(-4.5, 0, -3.6), 0.0]]:
		p("ph/dining_chair_02", c[0], c[1])
	var fallen := p("ph/dining_chair_02", Vector3(-2.6, 0.22, -3.9), 20.0)
	if fallen:
		fallen.rotation.x = deg_to_rad(-90.0)
	p("kenney/food-kit/plate", Vector3(-3.3, 0.88, -2.6), 0.0, 0.02)
	p("kenney/food-kit/mug", Vector3(-3.0, 0.88, -2.9), 40.0, 0.1)
	# the fall: glass shards and a few things on the floor
	var r := RandomNumberGenerator.new()
	r.seed = 5353
	for i in 26:
		var pos := Vector3(r.randf_range(-4.8, -2.8), 0.006, r.randf_range(-4.8, -4.0)) if i < 14 else Vector3(r.randf_range(-4.6, -2.4), 0.006, r.randf_range(4.0, 4.8))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), pos), Vector3(r.randf_range(0.03, 0.14), 0.004, r.randf_range(0.02, 0.08)), "l53_glass", GeoKit.ALL, false)
	p("kenney/furniture-kit/books", Vector3(-4.9, 0.01, 3.4), 40.0, 0.09)
	p("kenney/furniture-kit/books", Vector3(-4.6, 0.01, 3.1), 120.0, 0.09)
	var frame := p("ph/ornate_mirror_01", Vector3(-1.5, 0.02, 1.0), 30.0)
	if frame:
		frame.rotation.x = deg_to_rad(-88.0)
	_upstairs(out)
	_basement(out)
	k.commit()
	return out


func _christmas_tree(c: Vector3) -> Vector3:
	k.cylinder(c + Vector3(0, 0.15, 0), 0.25, 0.3, "l53_paper_red", 10, true)
	for i in 6:
		var r := 0.75 - i * 0.11
		k.cylinder(c + Vector3(0, 0.5 + i * 0.3, 0), r, 0.32, "l53_tree_green", 12, false)
	var rr := RandomNumberGenerator.new()
	rr.seed = 1225
	for i in 34:
		var y := 0.45 + rr.randf() * 1.75
		var rad := 0.78 - (y - 0.45) / 1.75 * 0.65
		var a := rr.randf() * TAU
		k.box(c + Vector3(cos(a) * rad, y, sin(a) * rad), Vector3(0.04, 0.04, 0.04), ["l53_bulb_red", "l53_bulb_green", "l53_bulb_blue", "l53_bulb_gold"][i % 4], GeoKit.ALL, false)
	k.box(c + Vector3(0, 2.32, 0), Vector3(0.12, 0.14, 0.04), "l53_bulb_gold", GeoKit.ALL, false)
	for i in 4:
		var gp := c + Vector3(-0.6 + i * 0.4, 0.12, 0.35 + (i % 2) * 0.25)
		k.box(gp, Vector3(0.3, 0.24, 0.26), ["l53_paper_red", "l53_paper_green", "l53_paper_gold", "l53_paper_blue"][i], GeoKit.ALL, false)
	return c + Vector3(0, 1.2, 0)


func _upstairs(out: Dictionary) -> void:
	var y := UP
	# master bedroom
	p("kenney/furniture-kit/beddouble", Vector3(-4.6, y, 2.8), 90.0, 0.55, true)
	p("ph/ClassicNightstand_01", Vector3(-5.65, y, 1.4), 90.0)
	p("ph/ClassicNightstand_01", Vector3(-5.65, y, 4.2), 90.0)
	p("ph/drawer_cabinet", Vector3(-1.4, y, 1.4), -90.0, 1.6, true)
	p("kenney/furniture-kit/lamproundfloor", Vector3(-5.6, y + 0.7, 4.2), 0.0, 0.4)
	# spare room: boxes, a suitcase, the old exercise of moving in
	p("ph/cardboard_box_01", Vector3(-5.4, y, -4.4), 10.0, 0.0, true)
	p("ph/cardboard_box_01", Vector3(-5.35, y + 0.34, -4.45), 50.0)
	p("ph/cardboard_box_01", Vector3(-4.6, y, -4.5), -20.0, 0.0, true)
	p("ph/vintage_suitcase", Vector3(-3.0, y, -4.6), 0.0)
	p("ph/SchoolDesk_01", Vector3(-1.5, y, -3.5), -90.0, 0.0, true)
	p("kenney/furniture-kit/bedsingle", Vector3(-4.8, y, -1.4), 90.0, 0.45, true)
	# kids' room: bunk bed, toys, the hamster cage where Louie lives
	p("kenney/furniture-kit/bedbunk", Vector3(5.2, y, 3.6), -90.0, 1.6, true)
	p("ph/plastic_crate_01", Vector3(2.0, y, 4.5), 20.0)
	p("ph/rubber_duck_toy", Vector3(2.6, y, 3.0), 60.0)
	p("kenney/furniture-kit/sidetable", Vector3(2.0, y, 1.3), 0.0, 0.7, true)
	var cage := Vector3(2.0, y + 0.7, 1.3)
	k.box(cage + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.32), "l53_paper_blue", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(cage + Vector3(s * 0.25, 0.15, 0), Vector3(0.008, 0.28, 0.32), "l53_steel", GeoKit.ALL, false)
		k.box(cage + Vector3(0, 0.15, s * 0.16), Vector3(0.5, 0.28, 0.008), "l53_steel", GeoKit.ALL, false)
	k.box(cage + Vector3(0, 0.29, 0), Vector3(0.5, 0.008, 0.32), "l53_steel", GeoKit.ALL, false)
	out["cage"] = cage
	# bathroom
	p("kenney/furniture-kit/bathtub", Vector3(5.0, y, -4.3), 0.0, 0.6, true)
	p("kenney/furniture-kit/toilet", Vector3(5.5, y, -1.2), -90.0, 0.8, true)
	p("kenney/furniture-kit/bathroomsink", Vector3(2.0, y, -4.6), 0.0, 0.9, true)
	p("kenney/furniture-kit/bathroommirror", Vector3(2.0, y + 1.3, -4.88), 0.0, 0.7)


func _basement(out: Dictionary) -> void:
	var y := BASE
	p("ph/steel_frame_shelves_02", Vector3(-5.5, y, -4.4), 0.0, 2.0, true)
	p("ph/steel_frame_shelves_02", Vector3(-4.8, y, -4.4), 0.0, 2.0, true)
	p("ph/steel_frame_shelves_02", Vector3(-4.1, y, -4.4), 0.0, 2.0, true)
	for i in 9:
		var sx := -5.5 + (i % 3) * 0.7
		var sy := y + 0.45 + int(i / 3) * 0.55
		p(["kenney/food-kit/can-open", "kenney/food-kit/carton", "kenney/food-kit/soda-bottle"][i % 3], Vector3(sx, sy, -4.4), 0.0, 0.2)
	p("kenney/furniture-kit/washerdryerstacked", Vector3(5.5, y, -4.5), 180.0, 1.8, true)
	k.cylinder(Vector3(-5.3, y + 0.8, 4.3), 0.3, 1.6, "l53_steel", 14, true)
	k.box(Vector3(-4.2, y + 0.75, 4.5), Vector3(0.8, 1.5, 0.6), "l53_steel")
	k.box(Vector3(-4.2, y + 1.85, 4.6), Vector3(0.3, 0.7, 0.3), "l53_steel", GeoKit.ALL, false)
	p("ph/cardboard_box_01", Vector3(3.2, y, 4.4), 15.0, 0.0, true)
	p("ph/plastic_crate_01", Vector3(2.5, y, 4.5), -10.0)
	k.box(Vector3(0.0, -0.32, -1.2), Vector3(0.06, 0.03, 0.06), "l53_lamp", GeoKit.ALL, false)
	k.box(Vector3(0.0, -0.31, -1.2), Vector3(0.01, 0.02, 0.01), "l53_black", GeoKit.ALL, false)
	out["pile"] = Vector3(0.0, y, -1.2)
	out["bulb"] = Vector3(0.0, -0.45, -1.2)


## Outside, seen through the windows and the open door: early-morning suburbia.
func outside() -> Dictionary:
	var o := L.kit("Outside")
	var g := -0.45
	for r in [[-200, -200, 200, -5.2], [-200, 5.2, 200, 13.0], [-200, -5.2, -6.2, 5.2], [6.2, -5.2, 200, 5.2]]:
		o.slab(r[0], r[1], r[2], r[3], g, 0.3, "l53_lawn")
	o.slab(-200, 13.0, 200, 16.0, g + 0.1, 0.3, "l53_pavement")
	o.slab(-200, 16.0, 200, 24.0, g - 0.05, 0.3, "l53_asphalt")
	o.slab(-200, 24.0, 200, 27.0, g + 0.1, 0.3, "l53_pavement")
	o.slab(-200, 27.0, 200, 200, g, 0.3, "l53_lawn")
	for i in 40:
		o.box(Vector3(-195 + i * 10.0, g - 0.04, 20.0), Vector3(3.0, 0.01, 0.15), "l53_trim", GeoKit.PY, false)
	# porch, path and driveway
	o.box_mm(Vector3(-1.3, g, 5.0), Vector3(1.5, -0.02, 6.8), "l53_pavement")
	o.box_mm(Vector3(-1.0, g, 6.8), Vector3(1.2, -0.24, 7.2), "l53_pavement")
	o.box(Vector3(0.1, g + 0.01, 10.0), Vector3(1.2, 0.04, 6.0), "l53_pavement", GeoKit.ALL, false)
	o.box(Vector3(4.0, g + 0.01, 9.0), Vector3(3.2, 0.04, 8.0), "l53_pavement", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		o.cylinder(Vector3(0.1 + s * 1.3, 1.2, 6.6), 0.07, 2.5, "l53_trim", 10, true)
	o.box_mm(Vector3(-1.5, 2.45, 5.0), Vector3(1.7, 2.6, 6.9), "l53_roof", GeoKit.ALL, false)
	# mailbox on its post at the kerb
	o.cylinder(Vector3(-1.4, 0.1, 12.6), 0.05, 1.1, "l53_cabinet", 8, false)
	o.box(Vector3(-1.4, 0.75, 12.6), Vector3(0.22, 0.24, 0.5), "l53_black", GeoKit.ALL, false)
	# trees
	var r := RandomNumberGenerator.new()
	r.seed = 909
	for tp in [Vector3(-8.5, g, 10.0), Vector3(9.5, g, 11.0), Vector3(-14.0, g, 29.0), Vector3(12.0, g, 30.0), Vector3(-9.0, g, -12.0),
			Vector3(8.0, g, -14.0), Vector3(30.0, g, 9.0), Vector3(-30.0, g, 10.0), Vector3(-2.0, g, 31.0)]:
		var th := r.randf_range(3.5, 5.0)
		o.cylinder(tp + Vector3(0, th * 0.5, 0), 0.18, th, "l53_bark", 8, false)
		for j in 3:
			var cr := r.randf_range(1.6, 2.4) - j * 0.35
			o.cylinder(tp + Vector3(r.randf_range(-0.4, 0.4), th + j * 0.9, r.randf_range(-0.4, 0.4)), cr, 1.4, "l53_leaves", 10, false)
	o.commit()
	# houses: opposite, either side, behind
	var houses := [["building-type-a", Vector3(-22, g, 38), 180.0], ["building-type-c", Vector3(-4, g, 38), 180.0], ["building-type-h", Vector3(14, g, 38), 180.0],
		["building-type-i", Vector3(32, g, 38), 180.0], ["building-type-c", Vector3(-19, g, 0), 90.0], ["building-type-i", Vector3(19, g, 0), -90.0],
		["building-type-h", Vector3(-12, g, -26), 0.0], ["building-type-a", Vector3(8, g, -26), 0.0], ["building-type-a", Vector3(-40, g, 38), 180.0],
		["building-type-i", Vector3(50, g, 38), 180.0], ["building-type-h", Vector3(-38, g, 0), 90.0], ["building-type-c", Vector3(38, g, 0), -90.0]]
	for h in houses:
		p("kenney/city-kit-suburban/" + str(h[0]), h[1], h[2], 7.5)
	for i in 10:
		p("kenney/city-kit-suburban/fence", Vector3(-6.5 - i * 1.1, g, -6.0), 0.0, 1.2)
		p("kenney/city-kit-suburban/fence", Vector3(6.5 + i * 1.1, g, -6.0), 0.0, 1.2)
	for i in 6:
		p("ph/street_lamp_01", Vector3(-40.0 + i * 20.0, g + 0.1, 25.0), 180.0)
	p("ph/covered_car", Vector3(4.0, g, 9.5), 0.0)
	p("ph/fire_hydrant", Vector3(7.5, g + 0.1, 14.5), 0.0)
	return {"street_z": 25.5, "porch": Vector3(0.1, -0.02, 5.9)}
