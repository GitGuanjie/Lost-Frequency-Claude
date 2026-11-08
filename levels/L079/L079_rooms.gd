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
