extends RefCounted
## Level 79 clinic: shell, seven rooms and their dressing. Coordinates: the main corridor
## runs from the entrance door (z = 0) toward -Z; right-hand rooms (x > 0) are 1, 3, 5,
## left-hand rooms (x < 0) are 2, 4, 6; Room 7 lies at the end, five steps down.

const T := 0.16
const H := 3.0
const CW := 1.4          # corridor half width (inner face)
const WX := 1.48         # corridor wall centre
const OX := 7.08         # outer wall centre
const THEATRE_Y := -0.72
const HALL_Y := -0.9

var L: LevelBase
var k: GeoKit
var d: GeoKit
var props: Node3D
var labels: Node3D


func _init(level: LevelBase, arch: GeoKit, dress: GeoKit) -> void:
	L = level
	k = arch
	d = dress
	props = Node3D.new()
	props.name = "Props"
	L.add_child(props)
	labels = Node3D.new()
	labels.name = "Labels"
	L.add_child(labels)


static func materials() -> void:
	MatLib.define("l79_lino", {"albedo_a": Color(0.62, 0.62, 0.55), "albedo_b": Color(0.55, 0.56, 0.49), "pattern": 9,
		"pattern_scale": Vector2(0.305, 0.305), "pattern_color": Color(0.36, 0.40, 0.36), "pattern_strength": 0.55,
		"grout_width": 0.0, "stain_amount": 0.45, "stain_color": Color(0.33, 0.3, 0.24), "roughness_a": 0.38,
		"roughness_b": 0.62, "noise_scale": 0.7, "bump_strength": 0.25}, "")
	MatLib.define("l79_mint", {"albedo_a": Color(0.47, 0.58, 0.52), "albedo_b": Color(0.42, 0.53, 0.47), "noise_scale": 1.2,
		"stain_amount": 0.35, "stain_color": Color(0.3, 0.33, 0.27), "grime_height": 0.35, "grime_color": Color(0.24, 0.26, 0.22),
		"peel_amount": 0.18, "peel_color": Color(0.62, 0.6, 0.55), "roughness_a": 0.55, "roughness_b": 0.75, "bump_strength": 0.5}, "")
	MatLib.define("l79_cream", {"albedo_a": Color(0.78, 0.75, 0.64), "albedo_b": Color(0.72, 0.69, 0.58), "noise_scale": 1.0,
		"stain_amount": 0.4, "stain_color": Color(0.55, 0.48, 0.34), "peel_amount": 0.22, "peel_color": Color(0.56, 0.55, 0.52),
		"roughness_a": 0.75, "roughness_b": 0.92, "bump_strength": 0.5}, "")
	MatLib.define("l79_ceiling", {"albedo_a": Color(0.72, 0.7, 0.62), "albedo_b": Color(0.64, 0.62, 0.55), "pattern": 7,
		"pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.012, "grout_color": Color(0.5, 0.48, 0.42), "stain_amount": 0.5,
		"stain_color": Color(0.48, 0.4, 0.26), "tile_variation": 0.05}, "")
	MatLib.define("l79_tile", {"albedo_a": Color(0.5, 0.62, 0.58), "albedo_b": Color(0.46, 0.58, 0.54), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.008, "grout_color": Color(0.36, 0.38, 0.35), "roughness_a": 0.15,
		"roughness_b": 0.35, "stain_amount": 0.4, "stain_color": Color(0.3, 0.28, 0.2), "grime_height": 0.5,
		"grime_color": Color(0.25, 0.18, 0.13)}, "")
	MatLib.define("l79_floor_tile", {"albedo_a": Color(0.6, 0.62, 0.58), "albedo_b": Color(0.55, 0.57, 0.53), "pattern": 1,
		"pattern_scale": Vector2(0.2, 0.2), "grout_width": 0.01, "grout_color": Color(0.32, 0.3, 0.26), "roughness_a": 0.3,
		"roughness_b": 0.5, "stain_amount": 0.55, "stain_color": Color(0.32, 0.22, 0.16)}, "")
	MatLib.define("l79_hall_floor", {"albedo_a": Color(0.36, 0.36, 0.34), "albedo_b": Color(0.29, 0.29, 0.28), "noise_scale": 1.5,
		"stain_amount": 0.5, "stain_color": Color(0.2, 0.17, 0.15), "wetness": 0.35, "roughness_a": 0.6, "roughness_b": 0.9,
		"bump_strength": 0.8}, "")
	MatLib.define("l79_hall_wall", {"albedo_a": Color(0.42, 0.42, 0.4), "albedo_b": Color(0.36, 0.36, 0.34), "pattern": 4,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.01, "grout_color": Color(0.3, 0.3, 0.28), "pattern_strength": 0.3,
		"stain_amount": 0.45, "stain_color": Color(0.25, 0.22, 0.18), "grime_height": 0.6, "floor_y": -0.9}, "")
	MatLib.define("l79_door", {"albedo_a": Color(0.42, 0.3, 0.2), "albedo_b": Color(0.36, 0.25, 0.16), "pattern": 3,
		"pattern_scale": Vector2(2.2, 0.3), "grout_width": 0.002, "grout_color": Color(0.2, 0.13, 0.08), "roughness_a": 0.4,
		"roughness_b": 0.6, "stain_amount": 0.3}, "")
	MatLib.define("l79_frame", {"albedo_a": Color(0.28, 0.33, 0.3), "albedo_b": Color(0.24, 0.28, 0.26), "metallic_value": 0.3,
		"roughness_a": 0.5, "roughness_b": 0.7, "stain_amount": 0.3, "noise_scale": 2.0}, "")
	MatLib.define("l79_enamel", {"albedo_a": Color(0.82, 0.82, 0.78), "albedo_b": Color(0.74, 0.74, 0.7), "roughness_a": 0.25,
		"roughness_b": 0.45, "stain_amount": 0.3, "stain_color": Color(0.5, 0.42, 0.3), "noise_scale": 2.0}, "")
	MatLib.define("l79_chrome", {"albedo_a": Color(0.7, 0.7, 0.7), "albedo_b": Color(0.55, 0.55, 0.55), "metallic_value": 0.9,
		"roughness_a": 0.2, "roughness_b": 0.45, "stain_amount": 0.25, "stain_color": Color(0.35, 0.25, 0.15)}, "")
	MatLib.define("l79_soot", {"albedo_a": Color(0.07, 0.06, 0.05), "albedo_b": Color(0.2, 0.17, 0.13), "noise_scale": 3.5, "noise_mix": 0.8,
		"roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 1.4}, "")
	MatLib.define("l79_char", {"albedo_a": Color(0.08, 0.06, 0.05), "albedo_b": Color(0.2, 0.13, 0.08), "pattern": 3,
		"pattern_scale": Vector2(1.0, 0.12), "grout_width": 0.01, "grout_color": Color(0.03, 0.02, 0.02), "noise_scale": 3.0,
		"roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 1.6}, "")
	MatLib.define("l79_board", {"albedo_a": Color(0.07, 0.09, 0.08), "albedo_b": Color(0.1, 0.12, 0.11), "noise_scale": 4.0,
		"stain_amount": 0.3, "stain_color": Color(0.22, 0.24, 0.22), "roughness_a": 0.85, "roughness_b": 0.95}, "")
	MatLib.define("l79_mattress", {"albedo_a": Color(0.7, 0.68, 0.6), "albedo_b": Color(0.64, 0.62, 0.55), "pattern": 2,
		"pattern_scale": Vector2(0.06, 1.0), "pattern_color": Color(0.5, 0.55, 0.62), "pattern_strength": 0.45,
		"stain_amount": 0.55, "stain_color": Color(0.55, 0.46, 0.3), "roughness_a": 0.95, "roughness_b": 1.0}, "")
	MatLib.define("l79_slurry", {"albedo_a": Color(0.2, 0.05, 0.035), "albedo_b": Color(0.12, 0.06, 0.04), "noise_scale": 2.2,
		"wetness": 1.0, "roughness_a": 0.08, "roughness_b": 0.3, "stain_amount": 0.5, "stain_color": Color(0.22, 0.2, 0.17),
		"bump_strength": 1.2}, "")
	MatLib.define("l79_machine", {"albedo_a": Color(0.17, 0.16, 0.13), "albedo_b": Color(0.1, 0.11, 0.1), "pattern": 11,
		"pattern_color": Color(0.32, 0.27, 0.18), "pattern_strength": 0.45, "noise_scale": 0.6, "metallic_value": 0.6,
		"roughness_a": 0.3, "roughness_b": 0.7, "bump_strength": 1.6, "stain_amount": 0.4, "stain_color": Color(0.22, 0.08, 0.05)}, "")
	MatLib.define("l79_machine_b", {"albedo_a": Color(0.36, 0.33, 0.27), "albedo_b": Color(0.24, 0.22, 0.18), "pattern": 1,
		"pattern_scale": Vector2(1.25, 0.85), "grout_width": 0.012, "grout_color": Color(0.04, 0.04, 0.03), "tile_variation": 0.12, "metallic_value": 0.75,
		"roughness_a": 0.35, "roughness_b": 0.6, "stain_amount": 0.5, "stain_color": Color(0.3, 0.12, 0.06)}, "")
	MatLib.define("l79_cart", {"albedo_a": Color(0.76, 0.76, 0.7), "albedo_b": Color(0.68, 0.68, 0.62), "roughness_a": 0.35,
		"roughness_b": 0.55, "stain_amount": 0.35, "stain_color": Color(0.45, 0.4, 0.3)}, "")
	MatLib.define("l79_rubber", {"albedo_a": Color(0.12, 0.12, 0.12), "albedo_b": Color(0.08, 0.08, 0.08), "roughness_a": 0.7,
		"roughness_b": 0.9}, "")
	MatLib.define("l79_red_ball", {"albedo_a": Color(0.62, 0.08, 0.06), "albedo_b": Color(0.55, 0.06, 0.05), "roughness_a": 0.55,
		"roughness_b": 0.7}, "")
	MatLib.define("l79_wood", {"albedo_a": Color(0.38, 0.27, 0.17), "albedo_b": Color(0.32, 0.22, 0.14), "pattern": 3,
		"pattern_scale": Vector2(1.0, 0.12), "grout_width": 0.003, "grout_color": Color(0.18, 0.12, 0.07), "roughness_a": 0.5,
		"roughness_b": 0.7, "stain_amount": 0.3}, "")
	MatLib.define("l79_pipe", {"albedo_a": Color(0.5, 0.48, 0.42), "albedo_b": Color(0.4, 0.38, 0.33), "metallic_value": 0.5,
		"roughness_a": 0.5, "roughness_b": 0.8, "stain_amount": 0.5, "stain_color": Color(0.35, 0.22, 0.12)}, "")
	MatLib.register("l79_panel_dead", MatLib.panel(Color(0.5, 0.5, 0.48), 0.05))
	MatLib.register("l79_panel_on", MatLib.panel(Color(1.0, 0.94, 0.82), 1.6, 0.0))
	MatLib.register("l79_lightbox", MatLib.panel(Color(0.82, 0.9, 1.0), 2.2))
	MatLib.register("l79_clockface", MatLib.panel(Color(0.9, 0.8, 0.6), 0.32))
	MatLib.register("l79_frost", MatLib.panel(Color(0.32, 0.34, 0.33), 0.12))


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


func label(text: String, p: Vector3, n: Vector3, px: float, col: Color, size: int = 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.basis = Basis.looking_at(-n, Vector3.UP)
	l.position = p + n * 0.006
	l.visibility_range_end = 16.0
	labels.add_child(l)
	return l


## Two-tone painted wall (mint dado, cream above), one storey, with door openings.
func wall2(a: Vector3, b: Vector3, ops: Array = [], top: float = H) -> void:
	var dado := 1.15
	k.wall(a, b, dado - a.y, T, "l79_mint", ops)
	var up_ops: Array = []
	for o in ops:
		var oh: float = float(o.get("h", 2.15)) - (dado - a.y)
		if oh > 0.0:
			up_ops.append({"at": o["at"], "w": o["w"], "h": oh, "sill": 0.0})
	k.wall(Vector3(a.x, dado, a.z), Vector3(b.x, dado, b.z), top - dado, T, "l79_cream", up_ops)


## A dark painted steel door frame around an opening, and the leaf swung into the room.
## p: centre of the opening on the wall line; along: unit wall direction; into: room side.
func door(p: Vector3, along: Vector3, into: Vector3, w: float, swing_deg: float = 95.0, double := false, frame_only := false) -> void:
	var b := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	for s in [-1.0, 1.0]:
		d.box_xf(Transform3D(b, p + along * (s * (w * 0.5 + 0.04)) + Vector3.UP * 1.1), Vector3(0.08, 2.2, T + 0.06), "l79_frame", GeoKit.ALL, false)
	d.box_xf(Transform3D(b, p + Vector3.UP * 2.19), Vector3(w + 0.16, 0.08, T + 0.06), "l79_frame", GeoKit.ALL, false)
	if frame_only:
		return
	var leaves := 2 if double else 1
	var lw := w / leaves
	for i in leaves:
		var side := -1.0 if i == 0 else 1.0
		var hinge := p + along * (side * w * 0.5) + into * 0.06
		var ang := deg_to_rad(swing_deg) * (-side)
		# rotate the closed leaf direction (-side * along) about the hinge into the room
		var dir0 := along * (-side)
		var dir := dir0.rotated(Vector3.UP, ang)
		if dir.dot(into) < 0.0:
			dir = dir0.rotated(Vector3.UP, -ang)
		var c := hinge + dir * (lw * 0.5) + Vector3.UP * 1.05
		var lb := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
		d.box_xf(Transform3D(lb, c), Vector3(lw - 0.02, 2.08, 0.045), "l79_door", GeoKit.ALL, false)
		d.box_xf(Transform3D(lb, c + Vector3.UP * 0.45), Vector3(lw * 0.5, 0.55, 0.05), "l79_frost", GeoKit.ALL, false)


# ----------------------------------------------------------------- shell

func shell() -> void:
	# floors
	k.slab(-1.56, 0.08, 1.56, -24.0, 0.0, 0.3, "l79_lino")
	k.slab(1.56, 0.08, OX + 0.08, -24.0, 0.0, 0.3, "l79_lino")
	k.slab(-OX - 0.08, -2.4, -1.56, -16.8, 0.0, 0.3, "l79_lino")
	k.box_mm(Vector3(-2.9, THEATRE_Y, -24.0), Vector3(-1.56, 0.0, -16.8), "l79_floor_tile")
	k.slab(-OX - 0.08, -16.8, -2.9, -24.0, THEATRE_Y, 0.3, "l79_floor_tile")
	k.box_mm(Vector3(-5.6, HALL_Y, -25.3), Vector3(5.6, 0.0, -24.0), "l79_hall_floor")
	k.slab(-5.66, -25.3, 5.66, -34.16, HALL_Y, 0.3, "l79_hall_floor")
	# ceilings
	k.slab(-OX - 0.08, 0.08, OX + 0.08, -24.0, H + 0.12, 0.12, "l79_ceiling")
	k.slab(-5.66, -24.0, 5.66, -34.16, 3.92, 0.12, "l79_ceiling")
	# entrance wall with the one door
	wall2(Vector3(-OX, 0, 0.0), Vector3(OX, 0, 0.0), [{"at": OX, "w": 1.0, "h": 2.1}])
	# corridor walls
	wall2(Vector3(WX, 0, 0.0), Vector3(WX, 0, -24.0), [{"at": 3.7, "w": 1.0}, {"at": 11.3, "w": 1.0}, {"at": 19.6, "w": 1.0}])
	wall2(Vector3(-WX, 0, 0.0), Vector3(-WX, 0, -24.0), [{"at": 6.0, "w": 1.6}, {"at": 13.2, "w": 1.0}, {"at": 20.4, "w": 1.6}])
	# outer walls
	wall2(Vector3(OX, 0, 0.0), Vector3(OX, 0, -24.0))
	wall2(Vector3(-OX, 0, -2.4), Vector3(-OX, 0, -16.8))
	k.wall(Vector3(-OX, THEATRE_Y, -16.8), Vector3(-OX, THEATRE_Y, -24.0), H - THEATRE_Y, T, "l79_tile")
	# partitions
	wall2(Vector3(1.56, 0, -7.4), Vector3(OX, 0, -7.4))
	wall2(Vector3(1.56, 0, -15.2), Vector3(OX, 0, -15.2))
	wall2(Vector3(-OX, 0, -2.4), Vector3(-1.56, 0, -2.4))
	wall2(Vector3(-OX, 0, -9.6), Vector3(-1.56, 0, -9.6))
	k.wall(Vector3(-OX, THEATRE_Y, -16.8), Vector3(-1.56, THEATRE_Y, -16.8), H - THEATRE_Y, T, "l79_tile")
	# end wall between rooms 5/6 and the machine hall (corridor opening in the middle)
	k.wall(Vector3(OX, 0, -24.0), Vector3(-OX, 0, -24.0), 3.92, T, "l79_cream", [{"at": OX, "w": 2.8, "h": 2.6}])
	k.wall(Vector3(-OX, THEATRE_Y, -24.0), Vector3(-1.56, THEATRE_Y, -24.0), -THEATRE_Y, T, "l79_tile")
	# machine hall
	k.wall(Vector3(5.66, HALL_Y, -24.0), Vector3(5.66, HALL_Y, -34.16), 3.92 - HALL_Y, T, "l79_hall_wall")
	k.wall(Vector3(-5.66, HALL_Y, -24.0), Vector3(-5.66, HALL_Y, -34.16), 3.92 - HALL_Y, T, "l79_hall_wall")
	k.wall(Vector3(-5.66, HALL_Y, -34.16), Vector3(5.66, HALL_Y, -34.16), 3.92 - HALL_Y, T, "l79_hall_wall")
	k.stairs(Vector3(0, HALL_Y, -26.8), Vector3(0, 0, 1), 3.0, -HALL_Y, 5, "l79_hall_floor", 0.3)
	for sx in [-1.0, 1.0]:
		# landing rail either side of the steps
		k.box(Vector3(sx * 3.55, 0.95, -25.25), Vector3(4.1, 0.05, 0.05), "l79_chrome", GeoKit.ALL, false)
		k.box(Vector3(sx * 3.55, 0.5, -25.25), Vector3(4.1, 1.0, 0.04), "l79_frame", GeoKit.ALL, true)
		for i in 5:
			k.box(Vector3(sx * (1.6 + i * 0.98), 0.48, -25.25), Vector3(0.05, 0.95, 0.05), "l79_chrome", GeoKit.ALL, false)
	# a frame on the opening into the hall
	door(Vector3(0, 0, -24.0), Vector3(1, 0, 0), Vector3(0, 0, -1), 2.8, 0.0, false, true)
	# entrance door (closed)
	d.box(Vector3(0, 1.05, 0.0), Vector3(0.98, 2.08, 0.06), "l79_door", GeoKit.ALL, true)
	d.box(Vector3(0, 1.55, -0.035), Vector3(0.5, 0.55, 0.01), "l79_frost", GeoKit.ALL, false)
	d.box(Vector3(0.38, 1.0, -0.06), Vector3(0.05, 0.05, 0.06), "l79_chrome", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		d.box(Vector3(s * 0.54, 1.1, -0.02), Vector3(0.08, 2.2, T + 0.06), "l79_frame", GeoKit.ALL, false)
	d.box(Vector3(0, 2.19, -0.02), Vector3(1.16, 0.08, T + 0.06), "l79_frame", GeoKit.ALL, false)
	# doors into the rooms (leaves open into each room)
	door(Vector3(WX, 0, -3.7), Vector3(0, 0, -1), Vector3(1, 0, 0), 1.0)
	door(Vector3(WX, 0, -11.3), Vector3(0, 0, -1), Vector3(1, 0, 0), 1.0)
	door(Vector3(WX, 0, -19.6), Vector3(0, 0, -1), Vector3(1, 0, 0), 1.0, 70.0)
	door(Vector3(-WX, 0, -6.0), Vector3(0, 0, -1), Vector3(-1, 0, 0), 1.6, 90.0, true)
	door(Vector3(-WX, 0, -13.2), Vector3(0, 0, -1), Vector3(-1, 0, 0), 1.0)
	door(Vector3(-WX, 0, -20.4), Vector3(0, 0, -1), Vector3(-1, 0, 0), 1.6, 90.0, true)
	# room numbers over each door, corridor side
	var nums := [[1, 1, -3.7], [2, -1, -6.0], [3, 1, -11.3], [4, -1, -13.2], [5, 1, -19.6], [6, -1, -20.4]]
	for n in nums:
		var sx: float = float(n[1])
		var z: float = float(n[2])
		d.box(Vector3(sx * (CW - 0.01), 2.45, z), Vector3(0.02, 0.22, 0.3), "l79_enamel", GeoKit.ALL, false)
		label(str(n[0]), Vector3(sx * (CW - 0.02), 2.45, z), Vector3(-sx, 0, 0), 0.0028, Color(0.12, 0.12, 0.12))
	label("7", Vector3(0, 2.8, -23.9), Vector3(0, 0, 1), 0.0034, Color(0.12, 0.12, 0.12))
	d.box(Vector3(0, 2.8, -23.91), Vector3(0.3, 0.26, 0.02), "l79_enamel", GeoKit.ALL, false)
	# ceiling fixtures: corridor (two lit, three dead) and one per room
	for z in [-4.5, -9.5, -15.5, -20.5]:
		var lit: bool = z == -4.5 or z == -15.5
		_fixture(Vector3(0, H, z), lit)
	_fixture(Vector3(4.6, H, -3.0), true)
	_fixture(Vector3(4.4, H, -11.6), true)
	_fixture(Vector3(4.4, H, -19.6), false)
	_fixture(Vector3(-4.4, H, -6.0), false)
	_fixture(Vector3(-4.4, H, -13.2), false)


func _fixture(p: Vector3, lit: bool) -> void:
	d.box(p + Vector3(0, -0.06, 0), Vector3(0.5, 0.1, 1.25), "l79_enamel", GeoKit.ALL, false)
	d.panel(p + Vector3(0, -0.115, 0), 0.38, 1.12, "l79_panel_on" if lit else "l79_panel_dead")


# ------------------------------------------------------------------ rooms

## Room 1 (right): an office; desk, filing cabinets and shelving shoved into a storage
## closet, all badly fire-damaged; a large black chalkboard with Dr. Zohn's note.
func office() -> void:
	# the closet in the south-east corner; its door burnt away, the frame charred
	wall2(Vector3(4.3, 0, -0.08), Vector3(4.3, 0, -2.7))
	wall2(Vector3(4.3, 0, -2.7), Vector3(7.0, 0, -2.7), [{"at": 1.35, "w": 1.6, "h": 2.1}])
	for x in [4.84, 6.46]:
		d.box(Vector3(x, 1.05, -2.7), Vector3(0.08, 2.1, T + 0.04), "l79_char", GeoKit.ALL, false)
	d.box(Vector3(5.65, 2.14, -2.7), Vector3(1.72, 0.08, T + 0.04), "l79_char", GeoKit.ALL, false)
	# smoke-blackening: heavy inside, a plume licking up the wall above the doorway
	d.box_mm(Vector3(4.39, 0.0, -2.62), Vector3(4.4, 2.95, -0.1), "l79_soot", GeoKit.ALL, false)
	d.box_mm(Vector3(6.98, 0.0, -2.62), Vector3(6.99, 2.95, -0.1), "l79_soot", GeoKit.ALL, false)
	d.box_mm(Vector3(4.4, 2.97, -2.62), Vector3(6.98, 2.98, -0.1), "l79_soot", GeoKit.ALL, false)
	for i in 4:
		var w := 1.5 - i * 0.32
		d.box(Vector3(5.65, 2.25 + i * 0.18, -2.785 - i * 0.001), Vector3(w, 0.2, 0.004), "l79_soot", GeoKit.ALL, false)
	d.box_mm(Vector3(4.4, 0.002, -2.62), Vector3(6.98, 0.008, -0.1), "l79_char", GeoKit.ALL, false)
	# the burnt desk on its side, cabinets and a shelf unit jammed in, one cabinet half out
	d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(80.0)), Vector3(5.1, 0.46, -1.1)), Vector3(0.75, 1.5, 0.7), "l79_char", GeoKit.ALL, true)
	d.box_xf(Transform3D(Basis(Vector3.UP, 0.3), Vector3(5.5, 0.02, -1.9)), Vector3(1.3, 0.04, 0.6), "l79_char", GeoKit.ALL, false)
	_p("ph/drawer_cabinet", Vector3(6.55, 0, -0.72), -90.0, 1.4, true)
	_p("ph/drawer_cabinet", Vector3(5.25, 0, -0.42), 172.0, 1.3, true)
	_p("ph/Shelf_01", Vector3(6.75, 0, -1.6), -78.0, 2.0)
	d.box_xf(Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3(1, 0, 0), deg_to_rad(-12.0)), Vector3(6.0, 0.55, -3.05)), Vector3(0.5, 1.1, 0.6), "l79_char", GeoKit.ALL, true)
	var r := RandomNumberGenerator.new()
	r.seed = 7901
	for i in 14:
		var pp := Vector3(r.randf_range(4.9, 6.6), 0.012 + i * 0.0006, r.randf_range(-4.4, -3.0))
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), pp), Vector3(0.21, 0.002, 0.29), "paper" if r.randf() < 0.6 else "l79_char", GeoKit.ALL, false)
	_p("ph/cardboard_box_01", Vector3(4.75, 0, -2.2), 20.0)
	_p("ph/binder_notebook", Vector3(5.4, 0.0, -2.35), 40.0)
	# the chalkboard on the east wall, Dr. Zohn's note in yellow chalk
	d.box(Vector3(6.97, 1.5, -5.0), Vector3(0.04, 1.3, 3.6), "l79_board", GeoKit.ALL, false)
	d.box(Vector3(6.94, 0.82, -5.0), Vector3(0.1, 0.04, 3.6), "l79_wood", GeoKit.ALL, false)
	var chalk := Color(0.92, 0.82, 0.36)
	var lines := ["The experiments were only somewhat successful;", "don't stay here long.", "We're going to move to Phase 2 anyway,", "I'll meet you then.", "                         - Dr. Zohn"]
	for i in lines.size():
		var l := label(lines[i], Vector3(6.94, 1.98 - i * 0.2, -5.0), Vector3(-1, 0, 0), 0.0016, chalk, 72)
		l.shaded = false
		l.modulate = Color(chalk.r, chalk.g, chalk.b, 0.86)
	# the office proper: bare, a chair, papers, a radiator, a dead wall clock
	_p("ph/SchoolChair_01", Vector3(3.1, 0, -5.6), 130.0)
	_p("ph/office_notepads", Vector3(2.6, 0.0, -6.3), 15.0)
	_p("ph/clipboard", Vector3(3.8, 0.0, -4.4), 70.0)
	_p("ph/wall_clock", Vector3(2.4, 2.25, -7.29), 0.0)
	_radiator(Vector3(1.75, 0, -6.2), Vector3(0, 0, 1))
	_p("kenney/furniture-kit/coatrackstanding", Vector3(2.0, 0, -1.0), 0.0, 1.75)


func _radiator(p: Vector3, along: Vector3) -> void:
	var b := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	for i in 9:
		d.box_xf(Transform3D(b, p + along * (i * 0.09 - 0.36) + Vector3.UP * 0.42), Vector3(0.05, 0.62, 0.16), "l79_cart", GeoKit.ALL, false)
	d.box_xf(Transform3D(b, p + Vector3.UP * 0.1), Vector3(0.86, 0.04, 0.1), "l79_pipe", GeoKit.ALL, false)


## A cylinder along any axis (GeoKit cylinders are vertical only).
func hcyl(c: Vector3, r: float, length: float, axis: Vector3, mat: String, sides: int = 14) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = length
	cm.radial_segments = sides
	cm.rings = 1
	m.mesh = cm
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	m.basis = Basis(x, y, x.cross(y))
	m.position = c
	m.material_override = MatLib.get_mat(mat)
	props.add_child(m)
	return m


## A wheeled equipment cart; returns its top centre.
func cart(p: Vector3, yaw: float, w: float = 0.7, dep: float = 0.5, h: float = 0.82) -> Vector3:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	d.box_xf(Transform3D(b, p + Vector3.UP * (h - 0.02)), Vector3(w, 0.04, dep), "l79_cart", GeoKit.ALL, false)
	d.box_xf(Transform3D(b, p + Vector3.UP * 0.22), Vector3(w, 0.03, dep), "l79_cart", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var o := b * Vector3(sx * (w * 0.5 - 0.03), 0, sz * (dep * 0.5 - 0.03))
			d.box(p + o + Vector3.UP * (h * 0.5), Vector3(0.025, h - 0.06, 0.025), "l79_chrome", GeoKit.ALL, false)
			d.box(p + o + Vector3.UP * 0.035, Vector3(0.05, 0.07, 0.05), "l79_rubber", GeoKit.ALL, false)
	return p + Vector3.UP * h


## Room 2 (left): equipment storage. Six named machines and four unknown, newer ones.
func storage() -> void:
	# steel shelving with boxed supplies along the west wall
	for i in 4:
		var z := -3.3 - i * 0.62
		_p("ph/steel_frame_shelves_02", Vector3(-6.72, 0, z), 90.0, 2.1, i == 0)
	var r := RandomNumberGenerator.new()
	r.seed = 7902
	for i in 4:
		for lvl in [0.42, 1.02, 1.6]:
			if r.randf() < 0.75:
				_p("ph/medical_box" if r.randf() < 0.5 else "ph/cardboard_box_01", Vector3(-6.72, lvl, -3.3 - i * 0.62 + r.randf_range(-0.08, 0.08)), 90.0 + r.randf_range(-20, 20), 0.0)
	# cardiopulmonary monitor: a CRT on a cart
	var t1 := cart(Vector3(-4.2, 0, -3.1), 0.0)
	_p("ph/Television_01", t1, 180.0)
	# ECG machine
	var t2 := cart(Vector3(-3.1, 0, -3.1), 0.0, 0.6, 0.45)
	_p("ph/vintage_radio_transceiver", t2, 180.0)
	d.box(t2 + Vector3(0.0, -0.4, 0.0), Vector3(0.5, 0.25, 0.35), "l79_cart", GeoKit.ALL, false)
	# kidney dialysis machine: tall cabinet, pump drum, tubing
	d.box(Vector3(-2.2, 0.72, -3.0), Vector3(0.55, 1.44, 0.5), "l79_enamel", GeoKit.ALL, true)
	d.box(Vector3(-2.2, 1.0, -2.74), Vector3(0.26, 0.26, 0.03), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-2.2, 1.3, -2.745), Vector3(0.36, 0.14, 0.01), "l79_rubber", GeoKit.ALL, false)
	for i in 3:
		d.cylinder(Vector3(-2.38 + i * 0.18, 1.62, -3.0), 0.012, 0.36, "l79_rubber", 6, false)
	# mechanical ventilator: bellows column on a stand
	var t3 := cart(Vector3(-2.6, 0, -9.0), 180.0, 0.6, 0.5, 0.7)
	d.box(t3 + Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.4), "l79_cart", GeoKit.ALL, false)
	d.cylinder(t3 + Vector3(0.12, 0.66, 0), 0.11, 0.42, "l79_frost", 12, false)
	# sonograph: console with a small screen and probe arm
	var t4 := cart(Vector3(-3.6, 0, -9.0), 180.0, 0.7, 0.55, 0.78)
	_p("kenney/furniture-kit/televisionvintage", t4, 0.0, 0.32)
	d.box(t4 + Vector3(0.28, 0.25, 0.1), Vector3(0.04, 0.5, 0.04), "l79_chrome", GeoKit.ALL, false)
	# fixed-angle centrifuge on a bench
	d.box(Vector3(-4.9, 0.45, -9.15), Vector3(1.2, 0.9, 0.55), "l79_wood", GeoKit.ALL, true)
	d.cylinder(Vector3(-5.0, 1.04, -9.15), 0.22, 0.28, "l79_enamel", 16, false)
	d.cylinder(Vector3(-5.0, 1.19, -9.15), 0.2, 0.03, "l79_chrome", 16, false)
	# the four machines of unknown purpose, newer than anything else here
	_p("kenney/space-kit/machine-generatorlarge", Vector3(-6.2, 0, -8.3), 90.0, 1.25, true)
	_p("kenney/space-kit/machine-wirelesscable", Vector3(-6.3, 0, -6.9), 90.0, 1.35, true)
	_p("kenney/space-kit/machine-barrellarge", Vector3(-5.0, 0, -7.6), 30.0, 0.95)
	_p("kenney/space-kit/machine-generator", Vector3(-5.3, 0, -6.3), -60.0, 0.75)
	_p("ph/hand_truck", Vector3(-2.2, 0, -8.6), 200.0)
	_p("ph/clipboard", Vector3(-4.95, 0.9, -9.05), 15.0)


## Room 3 (right): examination room. Wall machine on the right as you enter; locked
## medicine cabinet on the left.
func exam() -> void:
	# examination couch
	d.box(Vector3(4.4, 0.42, -11.5), Vector3(0.7, 0.84, 1.85), "l79_enamel", GeoKit.ALL, true)
	d.box(Vector3(4.4, 0.89, -11.5), Vector3(0.72, 0.1, 1.9), "l79_rubber", GeoKit.ALL, false)
	d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(28.0)), Vector3(4.4, 1.1, -10.75)), Vector3(0.72, 0.1, 0.62), "l79_rubber", GeoKit.ALL, false)
	_p("kenney/furniture-kit/stoolbar", Vector3(3.3, 0, -12.2), 30.0, 0.55)
	# the wall-embedded machine of unknown function (south wall = right side on entering)
	d.box_mm(Vector3(2.9, 0.0, -7.58), Vector3(5.7, 2.6, -7.48), "l79_machine_b", GeoKit.ALL, false)
	d.box_mm(Vector3(3.1, 0.12, -7.95), Vector3(5.5, 0.95, -7.56), "l79_machine", GeoKit.ALL, true)
	d.box_mm(Vector3(3.1, 1.1, -7.75), Vector3(5.5, 2.45, -7.56), "l79_machine", GeoKit.ALL, false)
	for i in 6:
		d.box(Vector3(3.35 + i * 0.4, 1.85, -7.74), Vector3(0.22, 0.12, 0.02), "l79_lightbox" if i == 2 else "l79_frame", GeoKit.ALL, false)
	# corrugated hoses, IV lines and wires spilling from the lower compartment
	var r := RandomNumberGenerator.new()
	r.seed = 7903
	for i in 5:
		var x := 3.3 + i * 0.5
		for s in 6:
			d.box(Vector3(x + s * 0.03, 0.08, -8.0 - s * 0.16), Vector3(0.09, 0.09, 0.12), "l79_rubber", GeoKit.ALL, false)
	for i in 4:
		var x2 := 3.4 + i * 0.6
		d.box(Vector3(x2, 1.6, -7.98), Vector3(0.008, 1.2, 0.008), "l79_frost", GeoKit.ALL, false)
	_p("ph/modular_electric_cables", Vector3(4.3, 2.48, -7.62), 0.0, 0.5)
	_p("ph/modular_industrial_pipes_01", Vector3(5.85, 0, -7.7), 0.0, 2.6)
	# locked medicine cabinet, glass front (north wall = left side)
	d.box_mm(Vector3(3.4, 0.9, -15.12), Vector3(4.7, 2.2, -14.72), "l79_enamel", GeoKit.ALL, true)
	d.box_mm(Vector3(3.45, 0.95, -14.73), Vector3(4.65, 2.15, -14.71), "glass", GeoKit.ALL, false)
	for sh in [1.25, 1.62, 1.98]:
		d.box(Vector3(4.05, sh - 0.12, -14.95), Vector3(1.2, 0.02, 0.32), "l79_chrome", GeoKit.ALL, false)
		for j in 8:
			var col: String = ["l79_lightbox", "l79_red_ball", "l79_enamel", "l79_frost"][int(r.randi() % 4)]
			d.cylinder(Vector3(3.55 + j * 0.14, sh - 0.04, -14.95 + r.randf_range(-0.05, 0.05)), 0.03, 0.14 + r.randf() * 0.06, col, 8, false)
	d.box(Vector3(4.66, 1.5, -14.7), Vector3(0.05, 0.12, 0.04), "l79_chrome", GeoKit.ALL, false)
	# sink and wall cabinets on the far wall
	_p("kenney/furniture-kit/bathroomsinksquare", Vector3(6.75, 0, -13.6), -90.0, 0.95)
	_p("kenney/furniture-kit/bathroommirror", Vector3(6.97, 1.2, -13.6), -90.0, 0.6)
	_p("kenney/furniture-kit/kitchencabinetupper", Vector3(6.8, 1.5, -10.4), -90.0, 0.7)
	_p("ph/medical_box", Vector3(6.6, 0.0, -9.0), 30.0)
	# a folding screen
	for i in 3:
		var p := Vector3(2.4 + i * 0.5, 0.9, -9.4 - (i % 2) * 0.12)
		d.box(p, Vector3(0.5, 1.6, 0.03), "l79_mattress", GeoKit.ALL, false)


## Room 4 (left): radiology. A mid-century X-ray unit and, on the rear wall, the
## negatoscope with a single film.
func xray() -> void:
	# patient table
	d.box(Vector3(-4.2, 0.4, -13.2), Vector3(0.9, 0.8, 0.5), "l79_frame", GeoKit.ALL, true)
	d.box(Vector3(-4.2, 0.84, -13.2), Vector3(2.1, 0.08, 0.75), "l79_enamel", GeoKit.ALL, false)
	# tube stand on floor rails: twin column, carriage, cross-arm, tube head and collimator
	for sx in [-0.1, 0.1]:
		d.box(Vector3(-4.2 + sx, 1.4, -14.4), Vector3(0.07, 2.8, 0.12), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 1.4, -14.4), Vector3(0.28, 2.8, 0.04), "l79_enamel", GeoKit.ALL, true)
	for sx in [-1.2, 1.2]:
		d.box(Vector3(-4.2 + sx * 0.0, 0.03, -14.4), Vector3(2.6, 0.06, 0.1), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 2.05, -14.25), Vector3(0.36, 0.34, 0.22), "l79_enamel", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 2.05, -13.75), Vector3(0.1, 0.1, 0.9), "l79_chrome", GeoKit.ALL, false)
	hcyl(Vector3(-4.2, 1.92, -13.25), 0.13, 0.62, Vector3(1, 0, 0), "l79_enamel")
	for sx in [-1.0, 1.0]:
		hcyl(Vector3(-4.2 + sx * 0.33, 1.92, -13.25), 0.15, 0.06, Vector3(1, 0, 0), "l79_frame")
	d.box(Vector3(-4.2, 1.68, -13.25), Vector3(0.22, 0.2, 0.22), "l79_frame", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 1.56, -13.25), Vector3(0.16, 0.05, 0.16), "l79_lightbox", GeoKit.ALL, false)
	for i in 3:
		d.box(Vector3(-4.32 + i * 0.12, 2.24, -14.25), Vector3(0.012, 0.012, 0.6), "l79_rubber", GeoKit.ALL, false)
	# bucky tray under the table top
	d.box(Vector3(-4.2, 0.74, -13.2), Vector3(0.5, 0.08, 0.6), "l79_chrome", GeoKit.ALL, false)
	# control desk and lead apron
	d.box(Vector3(-2.3, 0.55, -10.2), Vector3(0.9, 1.1, 0.55), "l79_cart", GeoKit.ALL, true)
	for i in 4:
		d.cylinder(Vector3(-2.55 + i * 0.16, 1.12, -10.2), 0.035, 0.03, "l79_frame", 10, false)
	d.box(Vector3(-2.3, 1.45, -10.42), Vector3(0.7, 0.55, 0.06), "l79_frame", GeoKit.ALL, false)
	d.box(Vector3(-6.95, 1.3, -10.6), Vector3(0.06, 1.0, 0.55), "l79_rubber", GeoKit.ALL, false)
	d.box(Vector3(-6.97, 1.85, -10.6), Vector3(0.04, 0.06, 0.3), "l79_chrome", GeoKit.ALL, false)
	# the negatoscope: a lit box on the rear wall with one film clipped on
	d.box(Vector3(-6.96, 1.55, -13.2), Vector3(0.12, 0.8, 1.6), "l79_enamel", GeoKit.ALL, false)
	d.box(Vector3(-6.895, 1.57, -13.2), Vector3(0.01, 0.62, 1.44), "l79_lightbox", GeoKit.ALL, false)
	d.box(Vector3(-6.885, 1.57, -13.55), Vector3(0.01, 0.5, 0.4), "l79_board", GeoKit.ALL, false)
	# the radiograph: pale bone shapes of a small, badly deformed forearm and hand
	var bones := [[-13.55, 1.42, 0.03, 0.32, 8.0], [-13.5, 1.44, 0.025, 0.3, -6.0], [-13.6, 1.66, 0.06, 0.08, 20.0],
		[-13.66, 1.73, 0.015, 0.1, 35.0], [-13.58, 1.76, 0.015, 0.09, 5.0], [-13.5, 1.72, 0.015, 0.07, -40.0]]
	for b in bones:
		d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(float(b[4]))), Vector3(-6.879, float(b[1]), float(b[0]))),
			Vector3(0.004, float(b[3]), float(b[2])), "l79_enamel", GeoKit.ALL, false)
	_p("ph/clipboard", Vector3(-2.35, 1.1, -10.1), 80.0)
	_p("ph/SchoolChair_01", Vector3(-2.6, 0, -11.0), 200.0)


## Room 5 (right): living quarters. Six twin mattresses on wire frames, two dressers.
func quarters() -> void:
	var beds := [[5.95, -16.1, 90.0], [5.95, -18.1, 90.0], [5.95, -20.6, 90.0], [5.95, -22.6, 90.0], [2.35, -22.9, 0.0], [3.6, -22.9, 0.0]]
	var r := RandomNumberGenerator.new()
	r.seed = 7905
	for b in beds:
		var p := Vector3(float(b[0]), 0, float(b[1]))
		var yaw: float = float(b[2])
		_p("ph/old_bed_frame", p, yaw, 0.0, true)
		var bas := Basis(Vector3.UP, deg_to_rad(yaw + r.randf_range(-3, 3)))
		d.box_xf(Transform3D(bas, p + Vector3.UP * 0.5), Vector3(0.84, 0.13, 1.88), "l79_mattress", GeoKit.ALL, false)
	# two dressers against the entrance-side wall
	_p("ph/drawer_cabinet", Vector3(3.0, 0, -15.56), 180.0, 1.15, true)
	_p("ph/drawer_cabinet", Vector3(4.45, 0, -15.56), 180.0, 1.15, true)
	# three black crayons and the blank sheets on top
	for i in 3:
		d.box_xf(Transform3D(Basis(Vector3.UP, 0.4 + i * 0.5), Vector3(2.85 + i * 0.07, 1.16, -15.5)), Vector3(0.09, 0.009, 0.009), "l79_rubber", GeoKit.ALL, false)
	for i in 4:
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(4.45, 1.155 + i * 0.002, -15.5)), Vector3(0.21, 0.001, 0.28), "paper", GeoKit.ALL, false)
	# the red rubber handball, by the wall
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	ball.mesh = sm
	ball.material_override = MatLib.get_mat("l79_red_ball")
	ball.position = Vector3(5.2, 0.035, -19.3)
	props.add_child(ball)
	_radiator(Vector3(1.75, 0, -22.6), Vector3(0, 0, 1))


## Room 6 (left): operating theatre, sunk four steps below a viewing landing. Empty;
## a slurry of fluids with screws and metal shavings has built up on the floor.
func theatre() -> void:
	var y := THEATRE_Y
	k.stairs(Vector3(-4.1, y, -20.4), Vector3(1, 0, 0), 1.6, -y, 4, "l79_floor_tile", 0.3)
	# landing rail, open at the stair
	for seg in [[-16.9, -19.6], [-21.2, -23.9]]:
		var z0: float = float(seg[0])
		var z1: float = float(seg[1])
		k.box(Vector3(-2.92, 0.98, (z0 + z1) * 0.5), Vector3(0.05, 0.05, absf(z1 - z0)), "l79_chrome", GeoKit.ALL, false)
		k.box(Vector3(-2.92, 0.5, (z0 + z1) * 0.5), Vector3(0.03, 1.0, absf(z1 - z0)), "glass", GeoKit.ALL, true)
		for i in int(absf(z1 - z0) / 0.9) + 1:
			k.box(Vector3(-2.92, 0.5, z0 - i * 0.9), Vector3(0.04, 1.0, 0.04), "l79_chrome", GeoKit.ALL, false)
	# operating table and the lamp above it
	var c := Vector3(-5.3, y, -20.4)
	d.box(c + Vector3(0, 0.45, 0), Vector3(0.35, 0.9, 0.35), "l79_chrome", GeoKit.ALL, true)
	d.box(c + Vector3(0, 0.06, 0), Vector3(0.7, 0.12, 0.9), "l79_chrome", GeoKit.ALL, false)
	d.box(c + Vector3(0, 0.95, 0), Vector3(0.6, 0.1, 1.95), "l79_rubber", GeoKit.ALL, false)
	d.cylinder(c + Vector3(0, H - y - 0.4, 0), 0.03, 0.8, "l79_chrome", 6, false)
	d.cylinder(c + Vector3(0, H - y - 0.9, 0), 0.42, 0.22, "l79_enamel", 18, false)
	d.panel(c + Vector3(0, H - y - 1.015, 0), 0.5, 0.5, "l79_panel_on")
	# instrument trolley, empty
	var tt := cart(c + Vector3(0.3, 0, 1.75), 20.0, 0.6, 0.4, 0.85)
	d.box(tt + Vector3(0, 0.01, 0), Vector3(0.5, 0.015, 0.32), "l79_chrome", GeoKit.ALL, false)
	# the slurry: one wide pool around the table and runnels toward the drain
	d.box(c + Vector3(-0.1, 0.006, 0.1), Vector3(2.6, 0.012, 3.4), "l79_slurry", GeoKit.ALL, false)
	d.box(c + Vector3(0.6, 0.008, -1.6), Vector3(1.0, 0.012, 1.0), "l79_slurry", GeoKit.ALL, false)
	d.box(c + Vector3(-1.0, 0.008, 1.9), Vector3(0.9, 0.012, 1.1), "l79_slurry", GeoKit.ALL, false)
	d.cylinder(c + Vector3(0.9, 0.004, -0.6), 0.12, 0.008, "l79_frame", 12, false)
	var r := RandomNumberGenerator.new()
	r.seed = 7906
	for i in 26:
		var o := Vector3(r.randf_range(-1.2, 1.2), 0.016, r.randf_range(-1.6, 1.6))
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), c + o), Vector3(0.03 + r.randf() * 0.03, 0.008, 0.008), "l79_chrome", GeoKit.ALL, false)
	_p("ph/korean_fire_extinguisher_01", Vector3(-1.8, 0, -17.3), 0.0)


func corridor_dressing() -> void:
	# bench by the entrance, with the log sheet
	d.box(Vector3(-1.15, 0.42, -2.0), Vector3(0.4, 0.05, 1.4), "l79_wood", GeoKit.ALL, true)
	for z in [-1.4, -2.6]:
		d.box(Vector3(-1.15, 0.2, z), Vector3(0.36, 0.4, 0.05), "l79_frame", GeoKit.ALL, false)
	_p("ph/clipboard", Vector3(-1.1, 0.445, -2.0), 85.0)
	# bumper rail on both corridor walls (skipping doorways)
	var ops := {1.0: [[0.0, 3.1], [4.3, 10.7], [11.9, 19.0], [20.2, 24.0]], -1.0: [[0.2, 5.1], [6.9, 12.6], [13.8, 19.5], [21.3, 24.0]]}
	for sx in ops.keys():
		for seg in ops[sx]:
			var z0 := -float(seg[0])
			var z1 := -float(seg[1])
			d.box(Vector3(float(sx) * (CW - 0.03), 0.92, (z0 + z1) * 0.5), Vector3(0.06, 0.14, absf(z1 - z0)), "l79_wood", GeoKit.ALL, false)
	# a gurney left against the wall, a wheel missing
	var g := Vector3(-0.95, 0, -16.5)
	d.box(g + Vector3(0, 0.78, 0), Vector3(0.6, 0.08, 1.9), "l79_rubber", GeoKit.ALL, true)
	d.box(g + Vector3(0, 0.7, 0), Vector3(0.62, 0.06, 1.95), "l79_chrome", GeoKit.ALL, false)
	for sz in [-0.85, 0.85]:
		d.box(g + Vector3(0, 0.36, sz), Vector3(0.5, 0.04, 0.04), "l79_chrome", GeoKit.ALL, false)
		for sx2 in [-0.27, 0.27]:
			d.box(g + Vector3(sx2, 0.36, sz), Vector3(0.03, 0.7, 0.03), "l79_chrome", GeoKit.ALL, false)
	d.box(g + Vector3(0.0, 0.83, 0.65), Vector3(0.5, 0.06, 0.4), "l79_mattress", GeoKit.ALL, false)
	# pipes under the ceiling, a fire extinguisher, an alarm, radiators
	d.box(Vector3(0.95, H - 0.18, -12.0), Vector3(0.11, 0.11, 24.0), "l79_pipe", GeoKit.ALL, false)
	d.box(Vector3(0.7, H - 0.12, -12.0), Vector3(0.06, 0.06, 24.0), "l79_pipe", GeoKit.ALL, false)
	for z in [-2.0, -12.0, -22.0]:
		d.box(Vector3(0.95, H - 0.06, z), Vector3(0.04, 0.12, 0.04), "l79_frame", GeoKit.ALL, false)
	_p("ph/korean_fire_extinguisher_01", Vector3(1.2, 0.0, -14.4), -90.0)
	_p("ph/fire_alarm", Vector3(1.39, 1.45, -14.4), -90.0)
	_radiator(Vector3(-1.32, 0, -10.8), Vector3(0, 0, 1))
	_radiator(Vector3(1.32, 0, -6.4), Vector3(0, 0, 1))
	_p("ph/WetFloorSign_01", Vector3(0.6, 0, -22.4), 30.0)
	_p("kenney/furniture-kit/trashcan", Vector3(-1.15, 0, -4.2), 0.0, 0.5)


## The corridor clock (it jumps when the machine knocks).
func corridor_clock(p: Vector3) -> Dictionary:
	return _clock(p, Vector3(-1, 0, 0), 0.17, 0.4, 2.1)


## A wall clock facing n: bezel, lit face, ticks and two hands on pivots.
func _clock(c: Vector3, n: Vector3, r: float, hour_angle: float, min_angle: float) -> Dictionary:
	var root := Node3D.new()
	root.basis = Basis.looking_at(-n, Vector3.UP)
	root.position = c
	props.add_child(root)
	var bez := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r + 0.03
	cm.bottom_radius = r + 0.03
	cm.height = 0.06
	cm.radial_segments = 20
	bez.mesh = cm
	bez.rotation.x = PI * 0.5
	bez.material_override = MatLib.get_mat("l79_frame")
	root.add_child(bez)
	var face := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = r
	fm.bottom_radius = r
	fm.height = 0.01
	fm.radial_segments = 20
	face.mesh = fm
	face.rotation.x = PI * 0.5
	face.position.z = 0.031
	face.material_override = MatLib.get_mat("l79_clockface")
	root.add_child(face)
	for i in 12:
		var t := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.012, r * (0.2 if i % 3 == 0 else 0.11), 0.004)
		t.mesh = tb
		var a := TAU * i / 12.0
		t.position = Vector3(sin(a), cos(a), 0) * r * 0.84 + Vector3(0, 0, 0.038)
		t.rotation.z = -a
		t.material_override = MatLib.get_mat("l79_rubber")
		root.add_child(t)
	var out := {}
	for hand in [["hour", 0.55, 0.022, hour_angle], ["min", 0.82, 0.014, min_angle]]:
		var piv := Node3D.new()
		piv.position = Vector3(0, 0, 0.042 if hand[0] == "hour" else 0.046)
		piv.rotation.z = -float(hand[3])
		root.add_child(piv)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(hand[2]), r * float(hand[1]), 0.004)
		m.mesh = bm
		m.position = Vector3(0, r * float(hand[1]) * 0.45, 0)
		m.material_override = MatLib.get_mat("l79_rubber")
		piv.add_child(m)
		out[hand[0]] = piv
	return out


## Room 7 (centre): the machine. Undetermined composition; sixteen clocks, each showing a
## different time; a slow leak from its left side. Returns the clocks.
func machine(base: Vector3) -> Array:
	var fz := base.z + 0.9
	k.box(base + Vector3(0, 1.75, 0), Vector3(5.0, 3.5, 1.8), "l79_machine", GeoKit.ALL, true)
	k.box(base + Vector3(0, 3.95, -0.3), Vector3(3.8, 0.9, 1.2), "l79_machine_b", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		k.box(base + Vector3(sx * 2.85, 1.2, -0.2), Vector3(0.7, 2.4, 1.3), "l79_machine_b", GeoKit.ALL, true)
		k.box(base + Vector3(sx * 2.85, 1.2, 0.46), Vector3(0.5, 2.0, 0.02), "l79_frame", GeoKit.ALL, false)
	# pipes into the ceiling and walls
	for i in 5:
		var x := -1.6 + i * 0.8
		d.cylinder(base + Vector3(x, 4.65, -0.3 + (i % 2) * 0.3), 0.09 + (i % 3) * 0.03, 0.6, "l79_pipe", 10, false)
	d.cylinder(Vector3(-4.6, 2.7, base.z - 0.4), 0.12, 1.6, "l79_pipe", 10, false)
	d.box(Vector3(-4.6, 3.45, base.z - 0.4), Vector3(0.24, 0.1, 1.4), "l79_pipe", GeoKit.ALL, false)
	# cables across the floor from both sides
	var r := RandomNumberGenerator.new()
	r.seed = 7907
	for i in 8:
		var sx2 := -1.0 if i % 2 == 0 else 1.0
		var x0 := sx2 * (2.5 + r.randf() * 0.3)
		var z0 := base.z + r.randf_range(-0.5, 1.6)
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.6, 0.6)), Vector3(x0 + sx2 * 1.1, base.y + 0.025, z0)),
			Vector3(2.2, 0.05, 0.05), "l79_rubber", GeoKit.ALL, false)
	# the face: rivets and vents around a 4 x 4 grid of clocks
	for row in 2:
		for i in 11:
			d.box(Vector3(base.x - 2.25 + i * 0.45, base.y + 0.15 + row * 3.2, fz + 0.01), Vector3(0.05, 0.05, 0.02), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(base.x, base.y + 1.8, fz + 0.005), Vector3(3.9, 3.2, 0.02), "l79_board", GeoKit.ALL, false)
	var clocks: Array = []
	var used := {}
	for row in 4:
		for col in 4:
			var cp := Vector3(base.x - 1.38 + col * 0.92, base.y + 0.55 + row * 0.82, fz + 0.03)
			var hh := 0
			var mm := 0
			while true:
				hh = r.randi() % 12
				mm = r.randi() % 60
				if not used.has(hh * 60 + mm):
					used[hh * 60 + mm] = true
					break
			var hour_a := TAU * (hh + mm / 60.0) / 12.0
			var min_a := TAU * mm / 60.0
			var c := _clock(cp, Vector3(0, 0, 1), 0.3, hour_a, min_a)
			var rate := TAU / 3600.0 * r.randf_range(0.4, 3.0) * (-1.0 if r.randf() < 0.3 else 1.0)
			c["rate"] = rate
			clocks.append(c)
	# a manifold across the top, conduit columns, louvres and a hatch: it is built, not grown
	hcyl(base + Vector3(0, 2.75, 0.75), 0.16, 5.4, Vector3(1, 0, 0), "l79_pipe")
	for sx in [-1.0, 1.0]:
		hcyl(base + Vector3(sx * 2.15, 1.3, 1.02), 0.11, 2.6, Vector3(0, 1, 0), "l79_pipe")
		hcyl(base + Vector3(sx * 2.15, 2.75, 1.02), 0.14, 0.18, Vector3(0, 1, 0), "l79_frame")
		for j in 9:
			d.box(base + Vector3(sx * 2.85, 0.5 + j * 0.16, 0.48), Vector3(0.44, 0.03, 0.05), "l79_frame", GeoKit.ALL, false)
		hcyl(Vector3(sx * 4.2, base.y + 3.0, base.z), 0.1, 2.6, Vector3(1, 0, 0), "l79_pipe")
	d.box(base + Vector3(0, 0.12, 0.92), Vector3(3.9, 0.2, 0.05), "l79_frame", GeoKit.ALL, false)
	d.box(base + Vector3(0, 3.32, 0.92), Vector3(3.9, 0.2, 0.05), "l79_frame", GeoKit.ALL, false)
	for i in 6:
		d.box(Vector3(-1.5 + i * 0.6, 3.85, base.z + 0.2), Vector3(0.02, 0.7, 0.02), "l79_rubber", GeoKit.ALL, false)
	# the leak runs down the left side to the floor
	d.box(Vector3(base.x - 2.52, base.y + 1.1, fz - 0.4), Vector3(0.02, 1.8, 0.16), "l79_slurry", GeoKit.ALL, false)
	return clocks


func leak_patch(p: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 0.012
	cm.radial_segments = 20
	m.mesh = cm
	m.position = p
	m.material_override = MatLib.get_mat("l79_slurry")
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(m)
	return m
