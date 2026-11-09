extends RefCounted
## Level 15 architecture: control room, the white-ribbed spine, engine halls,
## side rooms, the dark cross gallery and the doorframe room. Pure geometry
## (GeoKit) plus emissive light faces; props and bodies live in L015_dress.gd.
## Coordinates: y up, the spine runs from the control room (z 0) toward -z.

const HW := 4.0          # half width of the spine
const HH := 6.0          # spine height
const SPINE_Z0 := -22.0
const SPINE_Z1 := -132.0
const E1 := Rect2(4.0, -62.0, 36.0, 36.0)      # engine hall (x, z, w, d) floor at -6
const E1_Y := -6.0
const E1_TOP := 9.0
const FRAME_Z := -166.0
const CROSS_Z := -90.0
const CROSS_X := 70.0

var lvl
var k: GeoKit           # structure (collides)
var fx: GeoKit          # emissive faces and trims (no collision)


func _init(level, structure: GeoKit, faces: GeoKit) -> void:
	lvl = level
	k = structure
	fx = faces


static func materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	m.call("l15_floor", "concrete", {"albedo_a": Color(0.6, 0.61, 0.62), "albedo_b": Color(0.53, 0.54, 0.55), "pattern": 1,
		"pattern_scale": Vector2(2.0, 2.0), "grout_width": 0.008, "grout_color": Color(0.38, 0.39, 0.4), "tile_variation": 0.03,
		"roughness_a": 0.32, "roughness_b": 0.5, "bump_strength": 0.25, "stain_amount": 0.12, "stain_color": Color(0.42, 0.42, 0.42)})
	m.call("l15_wall", "concrete", {"albedo_a": Color(0.84, 0.85, 0.86), "albedo_b": Color(0.76, 0.77, 0.79), "pattern": 1,
		"pattern_scale": Vector2(3.0, 1.5), "grout_width": 0.012, "grout_color": Color(0.6, 0.61, 0.63), "tile_variation": 0.025,
		"roughness_a": 0.75, "roughness_b": 0.9, "bump_strength": 0.35, "stain_amount": 0.14, "stain_color": Color(0.62, 0.62, 0.62),
		"grime_height": 0.25, "grime_color": Color(0.55, 0.55, 0.55)})
	m.call("l15_wall_grey", "concrete", {"albedo_a": Color(0.6, 0.61, 0.63), "albedo_b": Color(0.52, 0.53, 0.55), "pattern": 1,
		"pattern_scale": Vector2(3.0, 1.5), "grout_width": 0.012, "grout_color": Color(0.42, 0.43, 0.45), "bump_strength": 0.5, "stain_amount": 0.25})
	m.call("l15_ceil", "concrete", {"albedo_a": Color(0.74, 0.75, 0.76), "albedo_b": Color(0.66, 0.67, 0.68), "pattern": 1,
		"pattern_scale": Vector2(4.0, 4.0), "grout_width": 0.02, "grout_color": Color(0.5, 0.5, 0.52), "bump_strength": 0.3})
	m.call("l15_beam", "metal", {"albedo_a": Color(0.92, 0.93, 0.94), "albedo_b": Color(0.87, 0.88, 0.9), "metallic_value": 0.25,
		"roughness_a": 0.3, "roughness_b": 0.45, "pattern": 10, "pattern_scale": Vector2(0.55, 0.32), "pattern_color": Color(0.58, 0.6, 0.63),
		"pattern_strength": 0.75, "stain_amount": 0.0, "noise_scale": 0.6, "bump_strength": 0.6})
	m.call("l15_steel", "metal", {"albedo_a": Color(0.3, 0.32, 0.35), "albedo_b": Color(0.24, 0.26, 0.28), "metallic_value": 0.8,
		"roughness_a": 0.35, "roughness_b": 0.55, "stain_amount": 0.15})
	m.call("l15_enamel", "metal", {"albedo_a": Color(0.86, 0.87, 0.88), "albedo_b": Color(0.8, 0.81, 0.83), "metallic_value": 0.2,
		"roughness_a": 0.3, "roughness_b": 0.4, "pattern": 1, "pattern_scale": Vector2(1.2, 0.8), "grout_width": 0.006,
		"grout_color": Color(0.45, 0.46, 0.48), "stain_amount": 0.08})
	m.call("l15_door", "metal", {"albedo_a": Color(0.44, 0.47, 0.5), "albedo_b": Color(0.38, 0.41, 0.44), "metallic_value": 0.7,
		"pattern": 1, "pattern_scale": Vector2(0.8, 0.8), "grout_width": 0.01, "grout_color": Color(0.22, 0.23, 0.25), "stain_amount": 0.25,
		"stain_color": Color(0.3, 0.26, 0.22)})
	m.call("l15_hazard", "metal", {"albedo_a": Color(0.8, 0.62, 0.08), "albedo_b": Color(0.74, 0.56, 0.06), "pattern": 2,
		"pattern_scale": Vector2(0.4, 1.0), "pattern_color": Color(0.06, 0.06, 0.06), "pattern_strength": 1.0, "uv_rotate": 0.785,
		"metallic_value": 0.1, "roughness_a": 0.6})
	m.call("l15_grate", "metal", {"albedo_a": Color(0.36, 0.38, 0.4), "albedo_b": Color(0.3, 0.32, 0.34), "pattern": 9,
		"pattern_scale": Vector2(0.06, 0.06), "pattern_color": Color(0.16, 0.17, 0.18), "pattern_strength": 0.6, "metallic_value": 0.7})
	m.call("l15_dark", "concrete_dark", {"albedo_a": Color(0.2, 0.21, 0.22), "albedo_b": Color(0.15, 0.16, 0.17)})
	m.call("l15_soot", "concrete_dark", {"albedo_a": Color(0.07, 0.07, 0.07), "albedo_b": Color(0.11, 0.1, 0.1), "wetness": 0.0})
	m.call("l15_rubber", "plaster", {"albedo_a": Color(0.05, 0.05, 0.06), "albedo_b": Color(0.04, 0.04, 0.05), "roughness_a": 0.6})
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.62, 0.78, 0.82, 0.16)
	g.roughness = 0.04
	g.metallic_specular = 0.9
	MatLib.register("l15_glass", g)
	var cr := StandardMaterial3D.new()
	cr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cr.albedo_color = Color(0.9, 0.95, 0.97, 0.55)
	cr.roughness = 0.2
	MatLib.register("l15_crack", cr)
	var vo := StandardMaterial3D.new()
	vo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vo.albedo_color = Color(0.0, 0.0, 0.004)
	vo.disable_fog = true
	MatLib.register("l15_void", vo)
	MatLib.register("l15_lamp", MatLib.panel(Color(0.86, 0.94, 1.0), 3.2))
	MatLib.register("l15_lamp_ground", MatLib.panel(Color(0.62, 0.9, 1.0), 2.6))
	MatLib.register("l15_lamp_warm", MatLib.panel(Color(1.0, 0.86, 0.66), 2.0))
	MatLib.register("l15_lamp_dim", MatLib.panel(Color(0.8, 0.9, 1.0), 1.5, 1.0))
	MatLib.register("l15_lamp_dead", MatLib.panel(Color(0.1, 0.1, 0.1), 0.0, 0.0, 100.0))
	MatLib.register("l15_frame", MatLib.panel(Color(0.94, 0.97, 1.0), 4.5))
	MatLib.register("l15_amber", MatLib.panel(Color(1.0, 0.58, 0.14), 2.6))
	MatLib.register("l15_green", MatLib.panel(Color(0.3, 1.0, 0.45), 2.2))
	MatLib.register("l15_red", MatLib.panel(Color(1.0, 0.12, 0.08), 2.4))
	MatLib.register("l15_cyan", MatLib.panel(Color(0.4, 0.95, 1.0), 2.4))


# ------------------------------------------------------------------ helpers

## Emissive face (local UVs so the diffuser reads correctly). n = facing direction.
func lamp(c: Vector3, n: Vector3, w: float, h: float, mat: String, flick := 0.0, seed_v := 0.0) -> void:
	var up := Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD
	var hu := n.cross(up).normalized() * (w * 0.5)
	var hv := hu.cross(n).normalized() * (h * 0.5)
	fx.quad(c, n, hu, hv, mat, Vector2(seed_v, flick), true)


## Room shell: floor, ceiling and the walls not shared with the spine.
## side = -1 west (door wall at x=-4), +1 east (door wall at x=+4).
func room(x0: float, z0: float, x1: float, z1: float, y0: float, h: float, wall: String, floor_mat: String, skip_x: float) -> void:
	k.slab(x0, z0, x1, z1, y0, 0.4, floor_mat)
	k.slab(x0, z0, x1, z1, y0 + h + 0.4, 0.4, "l15_ceil")
	var a := Vector3(x0, y0, z0)
	var b := Vector3(x1, y0, z0)
	var c := Vector3(x1, y0, z1)
	var d := Vector3(x0, y0, z1)
	k.wall(a, b, h, 0.4, wall)
	k.wall(d, c, h, 0.4, wall)
	if absf(x0 - skip_x) > 0.5:
		k.wall(a, d, h, 0.4, wall)
	if absf(x1 - skip_x) > 0.5:
		k.wall(b, c, h, 0.4, wall)


## White steel rib: two pilasters and a ceiling beam across a corridor.
func rib(z: float, half: float, h: float, along_x := false) -> void:
	if along_x:
		k.box(Vector3(z, h * 0.5, -half + 0.2), Vector3(0.6, h, 0.4), "l15_beam")
		k.box(Vector3(z, h * 0.5, half - 0.2), Vector3(0.6, h, 0.4), "l15_beam")
		k.box(Vector3(z, h - 0.25, 0.0), Vector3(0.6, 0.5, half * 2.0), "l15_beam", GeoKit.ALL, false)
		return
	k.box(Vector3(-half + 0.2, h * 0.5, z), Vector3(0.4, h, 0.6), "l15_beam")
	k.box(Vector3(half - 0.2, h * 0.5, z), Vector3(0.4, h, 0.6), "l15_beam")
	k.box(Vector3(0, h - 0.25, z), Vector3(half * 2.0, 0.5, 0.6), "l15_beam", GeoKit.ALL, false)


## A reinforced metal door: deep frame and a heavy leaf slid into the room.
## wall along z at x = wx (door_n points into the room), or along x at z = wz.
func heavy_door_x(wx: float, zc: float, w: float, h: float, into: float, open_frac: float) -> void:
	var t := 0.7
	k.box(Vector3(wx, h * 0.5, zc - w * 0.5 - 0.2), Vector3(t, h, 0.4), "l15_door")
	k.box(Vector3(wx, h * 0.5, zc + w * 0.5 + 0.2), Vector3(t, h, 0.4), "l15_door")
	k.box(Vector3(wx, h + 0.25, zc), Vector3(t, 0.5, w + 0.8), "l15_door")
	k.box(Vector3(wx, 0.02, zc), Vector3(t, 0.04, w), "l15_hazard", GeoKit.ALL, false)
	var leaf_z := zc - w * open_frac
	k.box(Vector3(wx + into * 0.55, h * 0.5, leaf_z - 0.1), Vector3(0.28, h - 0.05, w), "l15_door")
	fx.box(Vector3(wx - into * 0.37, h + 0.65, zc), Vector3(0.05, 0.12, 0.5), "l15_amber", GeoKit.ALL, false)


func heavy_door_z(wz: float, xc: float, w: float, h: float, into: float, open_frac: float) -> void:
	var t := 0.8
	k.box(Vector3(xc - w * 0.5 - 0.25, h * 0.5, wz), Vector3(0.5, h, t), "l15_door")
	k.box(Vector3(xc + w * 0.5 + 0.25, h * 0.5, wz), Vector3(0.5, h, t), "l15_door")
	k.box(Vector3(xc, h + 0.3, wz), Vector3(w + 1.0, 0.6, t), "l15_door")
	k.box(Vector3(xc, 0.02, wz), Vector3(w, 0.04, t), "l15_hazard", GeoKit.ALL, false)
	var leaf_x := xc + w * open_frac
	k.box(Vector3(leaf_x + 0.1, h * 0.5, wz + into * 0.6), Vector3(w, h - 0.05, 0.32), "l15_door")


# ------------------------------------------------------------------ spaces

## Control room (Enric's camp): 28 x 22 m, 8 m high, operator gallery at +3.4 m.
func control_room() -> void:
	k.slab(-14, 0, 14, -22, 0.0, 0.5, "l15_floor")
	k.slab(-14, 0, 14, -22, 8.4, 0.4, "l15_ceil")
	k.wall(Vector3(-14, 0, 0), Vector3(14, 0, 0), 8.0, 0.4, "l15_wall")
	k.wall(Vector3(-14, 0, 0), Vector3(-14, 0, -22), 8.0, 0.4, "l15_wall")
	k.wall(Vector3(14, 0, 0), Vector3(14, 0, -22), 8.0, 0.4, "l15_wall")
	k.wall(Vector3(-14, 0, -22), Vector3(14, 0, -22), 8.0, 0.4, "l15_wall", [{"at": 14.0, "w": 5.0, "h": 3.8}])
	# the sealed Level 10 door (south wall), closed for good
	k.box(Vector3(0, 1.9, -0.32), Vector3(3.6, 3.8, 0.3), "l15_door")
	k.box(Vector3(-2.0, 2.1, -0.4), Vector3(0.4, 4.2, 0.5), "l15_beam")
	k.box(Vector3(2.0, 2.1, -0.4), Vector3(0.4, 4.2, 0.5), "l15_beam")
	k.box(Vector3(0, 4.1, -0.4), Vector3(4.4, 0.4, 0.5), "l15_beam")
	fx.box(Vector3(0, 4.45, -0.5), Vector3(0.6, 0.12, 0.08), "l15_red", GeoKit.ALL, false)
	# ribs around the room walls
	for x in [-10.0, -5.0, 5.0, 10.0]:
		k.box(Vector3(x, 4.0, -21.6), Vector3(0.6, 8.0, 0.4), "l15_beam")
		k.box(Vector3(x, 7.75, -11.0), Vector3(0.6, 0.5, 22.0), "l15_beam", GeoKit.ALL, false)
	for z in [-5.0, -11.0, -17.0]:
		k.box(Vector3(-13.6, 4.0, z), Vector3(0.4, 8.0, 0.6), "l15_beam")
	# the big radar wall above the doorway
	k.box(Vector3(0, 5.75, -21.7), Vector3(10.0, 3.9, 0.3), "l15_steel")
	# operator gallery (east): slab, rail, columns, stair
	k.slab(8.8, -6.3, 13.8, -21.8, 3.4, 0.3, "l15_grate")
	for z in [-7.0, -13.0, -19.0]:
		k.box(Vector3(9.1, 1.6, z), Vector3(0.3, 3.2, 0.3), "l15_beam")
	k.box(Vector3(8.85, 4.45, -14.05), Vector3(0.06, 0.06, 15.5), "l15_beam", GeoKit.ALL, false)
	k.box(Vector3(8.85, 3.95, -14.05), Vector3(0.04, 0.04, 15.5), "l15_beam", GeoKit.ALL, false)
	k.box(Vector3(8.85, 3.95, -14.05), Vector3(0.12, 1.1, 15.5), "l15_glass", GeoKit.ALL, true)
	var z := -6.6
	while z > -21.6:
		k.box(Vector3(8.85, 3.95, z), Vector3(0.05, 1.1, 0.05), "l15_beam", GeoKit.ALL, false)
		z -= 1.5
	k.stairs(Vector3(12.8, 0, -1.0), Vector3(0, 0, -1), 2.0, 3.4, 19, "l15_grate", 0.28)
	k.box(Vector3(11.75, 2.2, -3.65), Vector3(0.06, 0.06, 5.6), "l15_beam", GeoKit.ALL, false)
	# ceiling light bars (half of them dead: Enric runs only what he needs)
	for i in 4:
		var zz := -4.0 - float(i) * 5.0
		lamp(Vector3(-6.5, 8.0, zz), Vector3.DOWN, 1.0, 4.0, "l15_lamp" if i % 2 == 0 else "l15_lamp_dead")
		lamp(Vector3(4.5, 8.0, zz), Vector3.DOWN, 1.0, 4.0, "l15_lamp_dead" if i % 2 == 0 else "l15_lamp_dim", 0.0, float(i))
	# ground lights along the west wall
	for i in 5:
		lamp(Vector3(-13.78, 0.35, -3.0 - float(i) * 4.0), Vector3.RIGHT, 1.4, 0.18, "l15_lamp_ground")


## The spine: 8 m wide, 6 m high, white concrete with white steel ribs.
func spine() -> void:
	var z0 := SPINE_Z0
	var z1 := SPINE_Z1
	k.slab(-HW, z0, HW, z1, 0.0, 0.5, "l15_floor")
	k.slab(-HW, z0, HW, z1, HH + 0.4, 0.4, "l15_ceil")
	var west := [
		{"at": 16.0, "w": 2.4, "h": 2.9},      # lab (z -38)
		{"at": 28.0, "w": 2.4, "h": 2.9},      # dormitory (z -50)
		{"at": 48.0, "w": 2.4, "h": 2.9},      # kitchen (z -70)
		{"at": -CROSS_Z - 22.0, "w": 6.0, "h": 4.6},   # cross gallery
		{"at": 82.0, "w": 3.0, "h": 3.2}]      # storage (z -104)
	var east := [
		{"at": 18.0, "w": 20.0, "h": 3.6, "sill": 1.0},   # engine hall glass (z -30..-50)
		{"at": 36.0, "w": 3.0, "h": 3.4},                 # engine hall door (z -58)
		{"at": 53.0, "w": 10.0, "h": 3.4, "sill": 1.0},   # wrecked engine room glass (z -70..-80)
		{"at": 60.0, "w": 2.4, "h": 3.0},                 # wrecked room door (z -82)
		{"at": -CROSS_Z - 22.0, "w": 6.0, "h": 4.6},      # cross gallery
		{"at": 82.0, "w": 2.4, "h": 3.0}]                 # cremation room door (z -104)
	k.wall(Vector3(-HW, 0, z0), Vector3(-HW, 0, z1), HH, 0.4, "l15_wall", west)
	k.wall(Vector3(HW, 0, z0), Vector3(HW, 0, z1), HH, 0.4, "l15_wall", east)
	# glass: thick laminated panes
	k.box(Vector3(HW, 2.8, -40.0), Vector3(0.3, 3.6, 20.0), "l15_glass")
	k.box(Vector3(HW, 2.7, -75.0), Vector3(0.3, 3.4, 10.0), "l15_glass")
	for zm in [-30.0, -35.0, -40.0, -45.0, -50.0]:
		k.box(Vector3(HW - 0.1, 2.8, zm), Vector3(0.22, 3.6, 0.22), "l15_beam", GeoKit.ALL, false)
	k.box(Vector3(HW - 0.1, 0.95, -40.0), Vector3(0.5, 0.1, 20.2), "l15_beam", GeoKit.ALL, false)
	# ribs every 4 m, skipped where the walls open
	var openings := [[-36.8, -39.2], [-48.8, -51.2], [-68.8, -71.2], [-86.5, -93.5], [-102.5, -105.5],
		[-29.6, -50.4], [-56.0, -60.0], [-69.6, -80.4], [-80.6, -83.4]]
	var z := -24.0
	while z > z1 + 1.0:
		var blocked := false
		for o in openings:
			if z <= o[0] + 0.4 and z >= o[1] - 0.4:
				blocked = true
		if blocked:
			k.box(Vector3(0, HH - 0.25, z), Vector3(HW * 2.0, 0.5, 0.6), "l15_beam", GeoKit.ALL, false)
		else:
			rib(z, HW, HH)
		z -= 4.0
	# Lights. Segment A (z -22..-60): ceiling bars and wall lights on the ribs.
	z = -26.0
	while z > -60.0:
		lamp(Vector3(0, HH - 0.01, z), Vector3.DOWN, 1.2, 5.0, "l15_lamp")
		z -= 8.0
	for zw in [-28.0, -44.0, -52.0]:
		lamp(Vector3(-HW + 0.41, 3.4, zw), Vector3.RIGHT, 0.3, 4.4, "l15_lamp")
	# Segment B (z -60..-78): only ground lights along both wall bases.
	z = -61.0
	while z > -78.0:
		for sx in [-1.0, 1.0]:
			lamp(Vector3(sx * (HW - 0.22), 0.012, z), Vector3.UP, 0.25, 3.0, "l15_lamp_ground")
		z -= 4.0
	for zg in [-62.0, -66.0, -74.0]:
		lamp(Vector3(-HW + 0.41, 0.5, zg), Vector3.RIGHT, 0.3, 0.9, "l15_lamp_ground")
	# Segment C (z -78..-100): nothing at all. Segment D (z -100..-132): sparse wall lights.
	for zd in [-102.0, -114.0, -126.0]:
		lamp(Vector3(-HW + 0.41, 3.0, zd), Vector3.RIGHT, 0.3, 3.6, "l15_lamp_dim", 0.6 if zd == -114.0 else 0.0, absf(zd))
		lamp(Vector3(HW - 0.41, 3.0, zd - 6.0), Vector3.LEFT, 0.3, 3.6, "l15_lamp_dim", 0.0, absf(zd) + 3.0)
	for zc in [-98.0, -110.0, -122.0]:
		lamp(Vector3(0, HH - 0.01, zc), Vector3.DOWN, 1.2, 5.0, "l15_lamp_dead")


## Engine hall (east): 36 x 36 m, floor 6 m below the spine, 15 m tall.
func engine_hall() -> void:
	var x0 := 4.0
	var x1 := 40.0
	var z0 := -26.0
	var z1 := -62.0
	k.slab(x0 + 0.2, z0, x1, z1, E1_Y, 0.4, "l15_floor")
	k.slab(x0, z0, x1, z1, E1_TOP + 0.4, 0.4, "l15_ceil")
	k.wall(Vector3(x0, E1_Y, z0), Vector3(x1, E1_Y, z0), E1_TOP - E1_Y, 0.4, "l15_wall_grey")
	k.wall(Vector3(x0, E1_Y, z1), Vector3(x1, E1_Y, z1), E1_TOP - E1_Y, 0.4, "l15_wall_grey")
	k.wall(Vector3(x1, E1_Y, z0), Vector3(x1, E1_Y, z1), E1_TOP - E1_Y, 0.4, "l15_wall_grey")
	# under and above the spine wall
	k.box_mm(Vector3(x0 - 0.2, E1_Y, z1), Vector3(x0 + 0.2, 0.0, z0), "l15_wall_grey")
	k.box_mm(Vector3(x0 - 0.2, HH, z1), Vector3(x0 + 0.2, E1_TOP, z0), "l15_wall_grey")
	# entry landing behind the reinforced door and the long stair down the north wall
	k.slab(x0 + 0.2, -55.6, 10.6, -61.8, 0.0, 0.35, "l15_grate")
	k.stairs(Vector3(19.84, E1_Y, -60.4), Vector3(-1, 0, 0), 2.6, 6.0, 33, "l15_grate", 0.28)
	for xp in [6.0, 9.6]:
		k.box(Vector3(xp, -3.0, -55.9), Vector3(0.35, 6.0, 0.35), "l15_steel")
	# rails: landing edge and the stair's open side
	k.box(Vector3(7.4, 1.05, -55.65), Vector3(6.4, 0.06, 0.06), "l15_hazard", GeoKit.ALL, false)
	k.box(Vector3(7.4, 0.55, -55.65), Vector3(6.4, 1.1, 0.06), "l15_glass")
	var a := Vector3(10.6, 1.05, -59.05)
	var b := Vector3(19.84, E1_Y + 1.05, -59.05)
	var d := b - a
	k.box_xf(Transform3D(Basis.looking_at(d, Vector3.UP), (a + b) * 0.5), Vector3(0.06, 0.06, d.length()), "l15_hazard", GeoKit.ALL, false)
	for i in 7:
		var p := a.lerp(b, float(i) / 6.0)
		k.box(Vector3(p.x, p.y - 0.53, p.z), Vector3(0.05, 1.06, 0.05), "l15_beam", GeoKit.ALL, false)
	# ribs on the walls
	for xr in [10.0, 16.0, 22.0, 28.0, 34.0]:
		k.box(Vector3(xr, 1.5, z0 - 0.4), Vector3(0.6, 15.0, 0.4), "l15_beam")
		k.box(Vector3(xr, 1.5, z1 + 0.4), Vector3(0.6, 15.0, 0.4), "l15_beam")
		k.box(Vector3(xr, E1_TOP - 0.35, (z0 + z1) * 0.5), Vector3(0.6, 0.7, 36.0), "l15_beam", GeoKit.ALL, false)
	# high-bay light faces
	for p in [Vector3(14, 0, -34), Vector3(14, 0, -50), Vector3(28, 0, -56)]:
		lamp(Vector3(p.x, E1_TOP - 0.01, p.z), Vector3.DOWN, 2.4, 2.4, "l15_lamp")
	lamp(Vector3(39.78, 2.0, -30.0), Vector3.LEFT, 0.4, 6.0, "l15_lamp_dim", 0.0, 3.0)


## The destroyed engine room (east, z -66..-84): glass shattered but not broken.
func wreck_room() -> void:
	room(4.0, -66.0, 24.0, -84.0, 0.0, 6.5, "l15_wall_grey", "l15_floor", 4.0)
	k.box_mm(Vector3(3.8, HH, -84.0), Vector3(4.2, 6.5, -66.0), "l15_wall_grey")
	# spider cracks in the pane (three impact points)
	var r := RandomNumberGenerator.new()
	r.seed = 1515
	for c in [Vector2(-72.4, 3.1), Vector2(-76.6, 2.0), Vector2(-78.9, 3.6)]:
		var ctr := Vector3(HW - 0.16, c.y, c.x)
		for i in 11:
			var ang := r.randf() * TAU
			var ln := r.randf_range(0.5, 1.9)
			var dir := Vector3(0, sin(ang), cos(ang))
			var mid := ctr + dir * ln * 0.5
			var bs := Basis(Vector3(1, 0, 0), ang)
			fx.box_xf(Transform3D(bs, mid), Vector3(0.012, 0.012, ln), "l15_crack", GeoKit.ALL, false)
		for ring in [0.25, 0.6]:
			for j in 8:
				var aa := TAU * float(j) / 8.0 + r.randf() * 0.3
				var p: Vector3 = ctr + Vector3(0, sin(aa), cos(aa)) * ring
				fx.box_xf(Transform3D(Basis(Vector3(1, 0, 0), aa + PI * 0.5), p), Vector3(0.01, 0.01, ring * 0.8), "l15_crack", GeoKit.ALL, false)
		fx.box(ctr, Vector3(0.02, 0.09, 0.09), "l15_crack", GeoKit.ALL, false)
	for zr in [-70.0, -76.0, -82.0]:
		k.box(Vector3(23.6, 3.25, zr), Vector3(0.4, 6.5, 0.6), "l15_beam")
	lamp(Vector3(10.0, 6.49, -78.0), Vector3.DOWN, 1.0, 3.0, "l15_lamp_dim", 1.0, 7.0)
	lamp(Vector3(18.0, 6.49, -72.0), Vector3.DOWN, 1.0, 3.0, "l15_lamp_dead")


## The cremation room (east, z -100..-120).
func cremation_room() -> void:
	room(4.0, -100.0, 22.0, -120.0, 0.0, 5.0, "l15_wall_grey", "l15_dark", 4.0)
	# the furnace on the east wall: jambs, lintel, soot-black throat
	var fxw := 21.8
	k.box(Vector3(fxw - 1.4, 2.0, -105.6), Vector3(2.8, 4.0, 1.2), "l15_steel")
	k.box(Vector3(fxw - 1.4, 2.0, -114.4), Vector3(2.8, 4.0, 1.2), "l15_steel")
	k.box(Vector3(fxw - 1.4, 3.45, -110.0), Vector3(2.8, 1.1, 7.6), "l15_steel")
	k.box(Vector3(fxw - 0.35, 1.45, -110.0), Vector3(0.6, 2.9, 7.6), "l15_soot")
	k.box(Vector3(fxw - 1.6, 0.25, -110.0), Vector3(2.4, 0.5, 7.6), "l15_soot")
	k.box(Vector3(fxw - 1.4, 4.4, -110.0), Vector3(1.6, 1.2, 1.6), "l15_steel")
	fx.box(Vector3(fxw - 2.85, 3.1, -110.0), Vector3(0.06, 0.3, 3.0), "l15_hazard", GeoKit.ALL, false)
	for zr in [-104.0, -116.0]:
		k.box(Vector3(4.6, 2.5, zr), Vector3(0.4, 5.0, 0.6), "l15_beam")
	lamp(Vector3(9.0, 4.99, -112.0), Vector3.DOWN, 0.8, 2.4, "l15_lamp_dim", 0.0, 11.0)


## West rooms: laboratory, dormitory, kitchen, storage.
func west_rooms() -> void:
	room(-20.0, -26.0, -4.0, -42.0, 0.0, 4.5, "l15_wall", "l15_floor", -4.0)
	room(-20.0, -46.0, -4.0, -62.0, 0.0, 3.6, "l15_wall", "l15_floor", -4.0)
	room(-20.0, -66.0, -4.0, -80.0, 0.0, 3.6, "l15_wall", "l15_floor", -4.0)
	room(-24.0, -98.0, -4.0, -124.0, 0.0, 5.0, "l15_wall_grey", "l15_floor", -4.0)
	# room lights
	for p in [Vector3(-12, 4.49, -30), Vector3(-12, 4.49, -38)]:
		lamp(p, Vector3.DOWN, 1.0, 3.0, "l15_lamp")
	lamp(Vector3(-12, 3.59, -54), Vector3.DOWN, 1.0, 3.0, "l15_lamp_dim", 0.0, 5.0)
	lamp(Vector3(-12, 3.59, -73), Vector3.DOWN, 1.0, 3.0, "l15_lamp_dim", 1.0, 9.0)
	for p in [Vector3(-10, 4.99, -106), Vector3(-18, 4.99, -116)]:
		lamp(p, Vector3.DOWN, 1.0, 3.0, "l15_lamp_dim", 0.0, p.z)
	lamp(Vector3(-10, 4.99, -116), Vector3.DOWN, 1.0, 3.0, "l15_lamp_dead")


## The cross gallery through the dark stretch: runs 66 m each way into black and
## ends at sealed reinforced doors (the halls continue beyond them).
func cross_gallery() -> void:
	var zc := CROSS_Z
	var w := 6.0
	var h := 4.6
	for side in [-1.0, 1.0]:
		var xa: float = side * HW
		var xb: float = side * CROSS_X
		k.slab(minf(xa, xb), zc + w * 0.5, maxf(xa, xb), zc - w * 0.5, 0.0, 0.5, "l15_floor")
		k.slab(minf(xa, xb), zc + w * 0.5, maxf(xa, xb), zc - w * 0.5, h + 0.4, 0.4, "l15_ceil")
		k.wall(Vector3(xa, 0, zc + w * 0.5), Vector3(xb, 0, zc + w * 0.5), h, 0.4, "l15_wall")
		k.wall(Vector3(xa, 0, zc - w * 0.5), Vector3(xb, 0, zc - w * 0.5), h, 0.4, "l15_wall")
		k.box(Vector3(xb, h * 0.5, zc), Vector3(0.4, h, w), "l15_wall")
		# sealed door at the far end
		k.box(Vector3(xb - side * 0.35, 1.7, zc), Vector3(0.3, 3.4, 3.2), "l15_door")
		k.box(Vector3(xb - side * 0.4, 1.8, zc - 1.8), Vector3(0.5, 3.6, 0.4), "l15_beam")
		k.box(Vector3(xb - side * 0.4, 1.8, zc + 1.8), Vector3(0.5, 3.6, 0.4), "l15_beam")
		fx.box(Vector3(xb - side * 0.52, 3.85, zc), Vector3(0.05, 0.14, 0.6), "l15_red", GeoKit.ALL, false)
		var x: float = xa + side * 6.0
		while absf(x) < CROSS_X - 2.0:
			k.box(Vector3(x, h * 0.5, zc + w * 0.5 - 0.2), Vector3(0.6, h, 0.4), "l15_beam")
			k.box(Vector3(x, h * 0.5, zc - w * 0.5 + 0.2), Vector3(0.6, h, 0.4), "l15_beam")
			k.box(Vector3(x, h - 0.25, zc), Vector3(0.6, 0.5, w), "l15_beam", GeoKit.ALL, false)
			x += side * 6.0


## The room two hours from camp (here: at the end of the spine). Engine-room
## proportions, every engine gone, the glowing doorframe in the back wall.
func frame_room() -> void:
	var z0 := SPINE_Z1
	var z1 := FRAME_Z
	var h := 12.0
	k.slab(-15, z0, 15, z1, 0.0, 0.5, "l15_floor")
	k.slab(-15, z0, 15, z1, h + 0.4, 0.4, "l15_ceil")
	k.wall(Vector3(-15, 0, z0), Vector3(15, 0, z0), h, 0.6, "l15_wall_grey", [{"at": 15.0, "w": 3.2, "h": 3.6}])
	k.wall(Vector3(-15, 0, z0), Vector3(-15, 0, z1), h, 0.4, "l15_wall_grey")
	k.wall(Vector3(15, 0, z0), Vector3(15, 0, z1), h, 0.4, "l15_wall_grey")
	k.wall(Vector3(-15, 0, z1), Vector3(15, 0, z1), h, 0.6, "l15_wall_grey", [{"at": 15.0, "w": 3.0, "h": 4.4}])
	heavy_door_z(z0, 0.0, 3.2, 3.6, -1.0, 0.95)
	# ribs and crane beams
	for zr in [-138.0, -146.0, -154.0, -162.0]:
		k.box(Vector3(-14.6, h * 0.5, zr), Vector3(0.4, h, 0.6), "l15_beam")
		k.box(Vector3(14.6, h * 0.5, zr), Vector3(0.4, h, 0.6), "l15_beam")
		k.box(Vector3(0, h - 0.4, zr), Vector3(30.0, 0.8, 0.6), "l15_beam", GeoKit.ALL, false)
	for xr in [-6.0, 6.0]:
		k.box(Vector3(xr, h - 1.0, (z0 + z1) * 0.5), Vector3(0.6, 0.6, 33.0), "l15_steel", GeoKit.ALL, false)
	# empty engine plinths: anchor bolts and cut cable stubs, nothing on them
	for p in [Vector2(-8.5, -141.0), Vector2(8.5, -141.0), Vector2(-8.5, -155.0), Vector2(8.5, -155.0)]:
		k.box(Vector3(p.x, 0.18, p.y), Vector3(6.0, 0.36, 8.0), "l15_dark")
		k.box(Vector3(p.x, 0.37, p.y), Vector3(4.6, 0.02, 6.6), "l15_hazard", GeoKit.ALL, false)
		k.box(Vector3(p.x, 0.375, p.y), Vector3(4.4, 0.025, 6.4), "l15_dark", GeoKit.ALL, false)
		for bx in [-1.8, 1.8]:
			for bz in [-2.8, 0.0, 2.8]:
				k.cylinder(Vector3(p.x + bx, 0.46, p.y + bz), 0.06, 0.2, "l15_steel", 6, false)
		for c in 3:
			k.box(Vector3(p.x - 2.6, 0.5 + float(c) * 0.03, p.y - 1.0 + float(c) * 0.5), Vector3(0.5, 0.12, 0.12), "l15_rubber", GeoKit.ALL, false)
	# the doorframe: no door, a soft white glow
	var fz := z1 + 0.05
	fx.box(Vector3(-1.62, 2.3, fz), Vector3(0.24, 4.6, 0.75), "l15_frame", GeoKit.ALL, false)
	fx.box(Vector3(1.62, 2.3, fz), Vector3(0.24, 4.6, 0.75), "l15_frame", GeoKit.ALL, false)
	fx.box(Vector3(0, 4.52, fz), Vector3(3.48, 0.24, 0.75), "l15_frame", GeoKit.ALL, false)
	fx.box(Vector3(0, 0.015, fz), Vector3(3.0, 0.03, 0.75), "l15_frame", GeoKit.ALL, false)
	# invisible lip just beyond the frame (the trigger fires before you reach it)
	k.box(Vector3(0, -0.25, z1 - 1.4), Vector3(3.0, 0.5, 2.2), "l15_void", 0, true)
	k.box(Vector3(0, 2.3, z1 - 2.6), Vector3(3.2, 4.6, 0.2), "l15_void", 0, true)
	# a single work light by the door Enric used
	lamp(Vector3(-14.58, 3.2, -134.6), Vector3.RIGHT, 0.3, 1.2, "l15_lamp_dim", 0.0, 41.0)
