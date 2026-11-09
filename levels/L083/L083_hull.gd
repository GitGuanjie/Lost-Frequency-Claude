extends RefCounted
## Level 83: the pressure hull of the USS Ace of Spades (SSN 744). Ship axis along Z, bow at +Z.
## Pressure hull radius 4.8 m around y = 3.4 (keel -1.4, crown 8.2). Forward compartment
## z 0..40 on three decks (lower y 0, middle y 2.7, upper y 5.3); reactor compartment z -14..0
## crossed by the shielded tunnel at middle-deck height; engine room z -44..-14 (lower flats y 0,
## side catwalks and the manoeuvring platform at y 2.7, hull crown visible overhead).

const R := 4.8
const HC := 3.4
const Y0 := 0.0
const Y1 := 2.7
const Y2 := 5.3
const UPC := 7.3            # upper-deck overhead
const FWD := 40.0
const RX := -14.0
const AFT := -44.0
const TH := 0.25
const HATCH := Vector3(0.0, 9.95, 1.9)
const TRUNK_FLOOR := 7.6

var L: LevelBase
var k: GeoKit                # structure (collision)
var d: GeoKit                # dressing (mostly visual)
var props: Node3D
var labels: Node3D
var windows: Array = []      # {pos (outer glass centre), n (outward), deck}
var lamps: Array = []        # [pos, color, energy, range, band]


func _init(level: LevelBase, arch: GeoKit, dress: GeoKit) -> void:
	L = level
	k = arch
	d = dress
	props = Node3D.new()
	props.name = "SubProps"
	L.add_child(props)
	labels = Node3D.new()
	labels.name = "SubLabels"
	L.add_child(labels)


static func materials() -> void:
	MatLib.define("l83_deck_metal", {"albedo_a": Color(0.2, 0.22, 0.22), "albedo_b": Color(0.16, 0.17, 0.17), "pattern": 5,
		"pattern_scale": Vector2(9.0, 9.0), "pattern_color": Color(0.3, 0.31, 0.3), "pattern_strength": 0.35, "metallic_value": 0.5,
		"roughness_a": 0.45, "roughness_b": 0.7, "stain_amount": 0.25, "stain_color": Color(0.1, 0.09, 0.07), "bump_strength": 0.5}, "")
	MatLib.define("l83_tile", {"albedo_a": Color(0.3, 0.29, 0.26), "albedo_b": Color(0.26, 0.25, 0.23), "pattern": 1,
		"pattern_scale": Vector2(3.3, 3.3), "grout_width": 0.02, "grout_color": Color(0.1, 0.1, 0.09), "tile_variation": 0.12, "roughness_a": 0.35,
		"roughness_b": 0.5, "stain_amount": 0.2, "stain_color": Color(0.18, 0.16, 0.12)}, "")
	MatLib.define("l83_liner", {"albedo_a": Color(0.5, 0.52, 0.5), "albedo_b": Color(0.46, 0.48, 0.46), "pattern": 14,
		"pattern_scale": Vector2(1.7, 0.85), "grout_width": 0.008, "grout_color": Color(0.22, 0.22, 0.2), "roughness_a": 0.5,
		"roughness_b": 0.65, "grime_height": 0.4, "grime_color": Color(0.3, 0.28, 0.24), "stain_amount": 0.15, "stain_scale": 0.8}, "")
	MatLib.define("l83_overhead", {"albedo_a": Color(0.3, 0.31, 0.3), "albedo_b": Color(0.25, 0.26, 0.25), "noise_scale": 0.8,
		"stain_amount": 0.25, "stain_color": Color(0.18, 0.16, 0.12), "roughness_a": 0.55, "bump_strength": 0.1}, "")
	MatLib.define("l83_green", {"albedo_a": Color(0.2, 0.32, 0.28), "albedo_b": Color(0.17, 0.27, 0.24), "roughness_a": 0.45,
		"roughness_b": 0.6, "stain_amount": 0.2, "stain_color": Color(0.12, 0.1, 0.07), "metallic_value": 0.2}, "")
	MatLib.define("l83_steel", {"albedo_a": Color(0.36, 0.37, 0.38), "albedo_b": Color(0.3, 0.31, 0.32), "metallic_value": 0.7,
		"roughness_a": 0.35, "roughness_b": 0.55, "stain_amount": 0.15}, "")
	MatLib.define("l83_hull_in", {"albedo_a": Color(0.2, 0.22, 0.2), "albedo_b": Color(0.16, 0.18, 0.16), "noise_scale": 0.6,
		"stain_amount": 0.35, "stain_color": Color(0.26, 0.2, 0.13), "stain_scale": 0.5, "roughness_a": 0.55}, "")
	MatLib.define("l83_console", {"albedo_a": Color(0.22, 0.26, 0.29), "albedo_b": Color(0.19, 0.22, 0.25), "roughness_a": 0.4,
		"roughness_b": 0.55, "metallic_value": 0.3}, "")
	MatLib.define("l83_black", {"albedo_a": Color(0.03, 0.03, 0.035), "albedo_b": Color(0.05, 0.05, 0.05), "roughness_a": 0.6}, "")
	MatLib.define("l83_mattress", {"albedo_a": Color(0.32, 0.36, 0.42), "albedo_b": Color(0.42, 0.44, 0.46), "pattern": 2,
		"pattern_scale": Vector2(6.0, 6.0), "pattern_color": Color(0.24, 0.27, 0.34), "pattern_strength": 0.6, "roughness_a": 0.95}, "")
	MatLib.define("l83_blanket", {"albedo_a": Color(0.06, 0.08, 0.16), "albedo_b": Color(0.08, 0.1, 0.18), "roughness_a": 0.95}, "")
	MatLib.define("l83_curtain", {"albedo_a": Color(0.1, 0.13, 0.2), "albedo_b": Color(0.08, 0.1, 0.16), "pattern": 2,
		"pattern_scale": Vector2(14.0, 14.0), "pattern_color": Color(0.05, 0.06, 0.1), "pattern_strength": 0.4, "roughness_a": 0.95}, "")
	MatLib.define("l83_leather", {"albedo_a": Color(0.16, 0.07, 0.035), "albedo_b": Color(0.11, 0.05, 0.025), "roughness_a": 0.32,
		"roughness_b": 0.5, "noise_scale": 3.0, "bump_strength": 0.3}, "")
	MatLib.define("l83_wood", {"albedo_a": Color(0.32, 0.19, 0.1), "albedo_b": Color(0.26, 0.15, 0.08), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.12), "roughness_a": 0.4}, "")
	MatLib.define("l83_torpedo", {"albedo_a": Color(0.12, 0.2, 0.13), "albedo_b": Color(0.1, 0.17, 0.11), "roughness_a": 0.25,
		"roughness_b": 0.35, "metallic_value": 0.45}, "")
	MatLib.define("l83_lead", {"albedo_a": Color(0.27, 0.28, 0.3), "albedo_b": Color(0.24, 0.25, 0.27), "pattern": 4,
		"pattern_scale": Vector2(1.2, 2.4), "grout_width": 0.01, "grout_color": Color(0.14, 0.14, 0.15), "roughness_a": 0.6}, "")
	MatLib.define("l83_yellow", {"albedo_a": Color(0.6, 0.45, 0.04), "albedo_b": Color(0.5, 0.37, 0.03), "pattern": 2,
		"pattern_scale": Vector2(4.0, 4.0), "pattern_color": Color(0.03, 0.03, 0.03), "pattern_strength": 0.9, "roughness_a": 0.5}, "")
	MatLib.define("l83_red_paint", {"albedo_a": Color(0.42, 0.04, 0.03), "albedo_b": Color(0.36, 0.03, 0.03), "roughness_a": 0.45}, "")
	MatLib.define("l83_bulkhead", {"albedo_a": Color(0.5, 0.51, 0.48), "albedo_b": Color(0.44, 0.45, 0.42), "noise_scale": 0.9,
		"grime_height": 0.5, "grime_color": Color(0.28, 0.26, 0.22), "stain_amount": 0.2, "roughness_a": 0.5}, "")
	MatLib.register("l83_lamp", MatLib.panel(Color(0.86, 0.92, 1.0), 2.2))
	MatLib.register("l83_lamp_warm", MatLib.panel(Color(1.0, 0.9, 0.74), 2.0))
	MatLib.register("l83_lamp_red", MatLib.panel(Color(1.0, 0.12, 0.08), 2.4))
	MatLib.register("l83_lamp_amber", MatLib.panel(Color(1.0, 0.55, 0.15), 2.2))
	MatLib.register("l83_screen", MatLib.panel(Color(0.12, 0.42, 0.3), 0.5))
	MatLib.register("l83_led_g", MatLib.panel(Color(0.2, 1.0, 0.35), 3.0))
	MatLib.register("l83_led_r", MatLib.panel(Color(1.0, 0.2, 0.1), 3.0, 0.2))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.25, 0.4, 0.45, 0.16)
	g.roughness = 0.04
	g.metallic_specular = 0.9
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l83_glass", g)


# ------------------------------------------------------------------ helpers

## Slab with rectangular holes (Rect2 in x/z). Cells are merged along X.
func slab_holes(x0: float, z0: float, x1: float, z1: float, y: float, mat: String, holes: Array, under_mat: String = "") -> void:
	var xs := [x0, x1]
	var zs := [z0, z1]
	for h: Rect2 in holes:
		xs.append_array([clampf(h.position.x, x0, x1), clampf(h.end.x, x0, x1)])
		zs.append_array([clampf(h.position.y, z0, z1), clampf(h.end.y, z0, z1)])
	xs.sort()
	zs.sort()
	for j in zs.size() - 1:
		var za: float = zs[j]
		var zb: float = zs[j + 1]
		if zb - za < 0.01:
			continue
		var run_start := -1.0e9
		for i in xs.size() - 1:
			var xa: float = xs[i]
			var xb: float = xs[i + 1]
			if xb - xa < 0.01:
				continue
			var c := Vector2((xa + xb) * 0.5, (za + zb) * 0.5)
			var hole := false
			for h: Rect2 in holes:
				if h.has_point(c):
					hole = true
			if hole:
				if run_start > -1.0e8:
					_slab_cell(run_start, za, xa, zb, y, mat, under_mat)
					run_start = -1.0e9
			elif run_start < -1.0e8:
				run_start = xa
		if run_start > -1.0e8:
			_slab_cell(run_start, za, xs[xs.size() - 1], zb, y, mat, under_mat)


func _slab_cell(xa: float, za: float, xb: float, zb: float, y: float, mat: String, under_mat: String) -> void:
	if under_mat == "":
		k.slab(xa, za, xb, zb, y, TH, mat)
	else:
		k.slab(xa, za, xb, zb, y, TH, mat, GeoKit.PY | GeoKit.SIDES)
		k.quad(Vector3((xa + xb) * 0.5, y - TH - 0.002, (za + zb) * 0.5), Vector3.DOWN, Vector3((xb - xa) * 0.5, 0, 0), Vector3(0, 0, (zb - za) * 0.5), under_mat)


## Thin railing (visual tube + one collision box).
func rail(a: Vector3, b: Vector3, h: float = 1.0) -> void:
	var len := a.distance_to(b)
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var bas := Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir)
	k.box_xf(Transform3D(bas, mid + Vector3.UP * (h * 0.5)), Vector3(0.06, h, len), "l83_yellow", 0, true)
	for i in int(len / 1.2) + 2:
		var t := clampf(i * 1.2 / maxf(len, 0.01), 0.0, 1.0)
		d.box(a.lerp(b, t) + Vector3.UP * (h * 0.5), Vector3(0.05, h, 0.05), "l83_yellow", GeoKit.ALL, false)
	d.box_xf(Transform3D(bas, mid + Vector3.UP * h), Vector3(0.07, 0.07, len), "l83_steel", GeoKit.ALL, false)
	d.box_xf(Transform3D(bas, mid + Vector3.UP * (h * 0.5)), Vector3(0.04, 0.04, len), "l83_steel", GeoKit.ALL, false)


## A lamp fixture on an overhead plus its pooled-light anchor. band = deck index.
func lamp(p: Vector3, band: int, mat: String = "l83_lamp", along_z := true, energy := 0.7, rng := 7.0) -> void:
	var sz := Vector3(0.3, 0.08, 1.2) if along_z else Vector3(1.2, 0.08, 0.3)
	d.box(p + Vector3(0, 0.04, 0), sz + Vector3(0.06, 0.0, 0.06), "l83_steel", GeoKit.ALL, false)
	d.quad(p - Vector3(0, 0.002, 0), Vector3.DOWN, Vector3(sz.x * 0.45, 0, 0), Vector3(0, 0, sz.z * 0.45), mat, Vector2.ZERO, true)
	var col := Color(0.82, 0.9, 1.0)
	if mat == "l83_lamp_warm":
		col = Color(1.0, 0.86, 0.68)
	elif mat == "l83_lamp_red":
		col = Color(1.0, 0.16, 0.1)
	elif mat == "l83_lamp_amber":
		col = Color(1.0, 0.55, 0.2)
	lamps.append([p - Vector3(0, 0.15, 0), col, energy, rng, band])


## Window through the liner and the pressure hull: an embrasure box, glass and a ring frame.
func window(x_liner: float, y_c: float, z: float, deck: int, w: float = 0.62, h: float = 0.62) -> void:
	w = minf(w, 0.62)
	h = w
	var s := signf(x_liner)
	var x_out := s * (sqrt(maxf(R * R - pow(y_c - HC, 2.0), 1.0)) + 0.12)
	var depth := absf(x_out - x_liner)
	var xc := (x_liner + x_out) * 0.5
	k.box(Vector3(xc, y_c + h * 0.5 + 0.04, z), Vector3(depth, 0.08, w + 0.16), "l83_console")
	k.box(Vector3(xc, y_c - h * 0.5 - 0.04, z), Vector3(depth, 0.08, w + 0.16), "l83_console")
	k.box(Vector3(xc, y_c, z + w * 0.5 + 0.04), Vector3(depth, h, 0.08), "l83_console")
	k.box(Vector3(xc, y_c, z - w * 0.5 - 0.04), Vector3(depth, h, 0.08), "l83_console")
	# thick glass near the outer end; collision keeps hands off the sea
	k.box(Vector3(x_out - s * 0.06, y_c, z), Vector3(0.03, h, w), "l83_glass", GeoKit.PX | GeoKit.NX, true, "metal")
	# round porthole: an annular steel plate (covers the square cut-out's corners) and bolts
	var n := Vector3(-s, 0, 0)
	var fx := x_liner - s * 0.035
	var seg := 32
	var r_in := 0.27
	var r_out := 0.5
	for i in seg:
		var a := TAU * (i + 0.5) / seg
		var radial := Vector3(0, sin(a), cos(a))
		var tang := n.cross(radial).normalized()
		var bas := Basis(n, radial, tang)
		if bas.determinant() < 0.0:
			bas = Basis(n, radial, -tang)
		var arc := TAU * r_out / seg * 1.03
		d.box_xf(Transform3D(bas, Vector3(fx, y_c, z) + radial * ((r_in + r_out) * 0.5)), Vector3(0.05, r_out - r_in, arc), "l83_steel", GeoKit.ALL, false)
		d.box_xf(Transform3D(bas, Vector3(fx - s * 0.03, y_c, z) + radial * (r_in + 0.025)), Vector3(0.06, 0.05, TAU * r_in / seg * 1.1), "l83_steel", GeoKit.ALL, false)
		if i % 2 == 0:
			d.box(Vector3(fx - s * 0.03, y_c, z) + radial * (r_out - 0.06), Vector3(0.04, 0.04, 0.04), "l83_black", GeoKit.ALL, false)
	d.box(Vector3(fx - s * 0.04, y_c - 0.6, z), Vector3(0.06, 0.05, 0.5), "l83_steel", GeoKit.ALL, false)
	windows.append({"pos": Vector3(x_out + s * 0.02, y_c, z), "n": Vector3(s, 0, 0), "deck": deck, "inner": Vector3(x_liner, y_c, z)})


## Hull half-width at height y (inner skin).
static func half_w(y: float) -> float:
	return sqrt(maxf(R * R - pow(y - HC, 2.0), 0.0))


## Oval watertight door frame drawn around an opening in a transverse bulkhead.
func wt_door(c: Vector3, w: float = 0.9, h: float = 1.75) -> void:
	for sx: float in [-1.0, 1.0]:
		d.box(c + Vector3(sx * (w * 0.5 + 0.08), h * 0.5, 0), Vector3(0.16, h, 0.3), "l83_steel", GeoKit.ALL, false)
	d.box(c + Vector3(0, h + 0.08, 0), Vector3(w + 0.32, 0.16, 0.3), "l83_steel", GeoKit.ALL, false)
	d.box(c + Vector3(0, 0.1, 0), Vector3(w + 0.32, 0.2, 0.32), "l83_steel", GeoKit.ALL, true)
	# the door itself, swung open against the bulkhead
	d.box(c + Vector3(w * 0.5 + 0.55, h * 0.5 + 0.05, 0.2), Vector3(0.9, h - 0.1, 0.08), "l83_bulkhead", GeoKit.ALL, false)
	d.cylinder(c + Vector3(w * 0.5 + 0.55, h * 0.5, 0.27), 0.16, 0.04, "l83_steel", 10, false)


## A transverse bulkhead filling the deck band [y0, y1] across |x| < hw with optional door at x = dx.
func bulkhead(z: float, y0: float, y1: float, hw: float, door_x: float = 999.0, door_w: float = 0.9) -> void:
	var ops: Array = []
	if door_x < 900.0:
		ops.append({"at": door_x + hw, "w": door_w, "h": 1.75, "sill": 0.0})
	k.wall(Vector3(-hw, y0, z), Vector3(hw, y0, z), y1 - y0, 0.12, "l83_bulkhead", ops)
	if door_x < 900.0:
		wt_door(Vector3(door_x, y0, z), door_w)


# ------------------------------------------------------------------ structure

func build() -> void:
	_decks()
	_forward_walls()
	_stairs()
	_trunk()
	_tunnel()
	_engine_room()
	_hull_skin()


func _decks() -> void:
	# lower deck, forward compartment
	k.slab(-3.39, 0.0, 3.39, FWD, Y0, TH, "l83_deck_metal")
	# middle deck: holes for the aft (S3) and forward (S4) ladders down
	var mid_holes := [Rect2(-3.25, 2.65, 1.1, 3.5), Rect2(1.35, 33.6, 1.1, 3.6)]
	slab_holes(-4.4, 0.0, 4.4, FWD, Y1, "l83_tile", mid_holes, "l83_overhead")
	# upper deck: holes for S1 (aft) and S2 (forward)
	var up_holes := [Rect2(2.15, 2.65, 1.1, 3.5), Rect2(2.95, 33.9, 1.1, 3.5)]
	slab_holes(-4.1, 0.0, 4.1, FWD, Y2, "l83_deck_metal", up_holes, "l83_overhead")
	# upper overhead with the escape-trunk opening (x -0.8..0.8, z 1.0..5.4)
	slab_holes(-3.0, 0.0, 3.0, FWD, UPC + TH, "l83_overhead", [Rect2(-0.8, 1.0, 1.6, 5.0)])
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 3.45, (UPC + 6.5) * 0.5 + 0.1, FWD * 0.5), Vector3(0.9, UPC - 6.5 + 0.2, FWD), "l83_overhead")
	# side liners: lower |x| 3.3, middle 4.4 (windowed rooms), upper 3.9
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 3.36, 1.22, FWD * 0.5), Vector3(0.12, 2.45, FWD), "l83_liner")
	# end bulkheads of the forward compartment
	bulkhead(FWD, Y0, Y1 - TH, 3.4)
	bulkhead(FWD, Y1, Y2 - TH, 4.45)
	bulkhead(FWD, Y2, UPC, 4.1)
	bulkhead(0.0, Y0, Y1 - TH, 3.4)
	bulkhead(0.0, Y1, Y2 - TH, 4.45, 0.0)
	bulkhead(0.0, Y2, UPC, 4.1)


## Middle-deck walls (windows on both sides) and room partitions.
func _forward_walls() -> void:
	var h := Y2 - TH - Y1
	for sx: float in [-1.0, 1.0]:
		var x := sx * 4.45
		# berth (4.5..17) blind; cross passage window at 18; mess windows at 21.5, 25, 28.5; galley/stairs blind
		var ops := [{"at": 18.4, "w": 0.62, "h": 0.62, "sill": 1.09}, {"at": 21.6, "w": 0.62, "h": 0.62, "sill": 1.09},
			{"at": 25.0, "w": 0.62, "h": 0.62, "sill": 1.09}, {"at": 28.4, "w": 0.62, "h": 0.62, "sill": 1.09}]
		k.wall(Vector3(x, Y1, 0.0), Vector3(x, Y1, FWD), h, 0.12, "l83_liner", ops)
		for z: float in [18.4, 21.6, 25.0, 28.4]:
			window(x, Y1 + 1.4, z, 1)
		# upper deck control-room windows (two each side)
		var ops2 := [{"at": 19.0, "w": 0.5, "h": 0.5, "sill": 0.55}, {"at": 25.0, "w": 0.5, "h": 0.5, "sill": 0.55}]
		k.wall(Vector3(sx * 3.95, Y2, 0.0), Vector3(sx * 3.95, Y2, FWD), 1.2, 0.1, "l83_liner", ops2)
		for z: float in [19.0, 25.0]:
			window(sx * 3.95, Y2 + 0.8, z, 2, 0.5, 0.5)
	# berth: inboard rack backs form the central passage walls (z 4.5..17)
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 1.15, Y1 + 1.15, 12.6), Vector3(0.08, 2.3, 10.4), "l83_liner")
	# mess: transverse walls with doors (z 19 aft, z 31 forward)
	k.wall(Vector3(-4.4, Y1, 19.0), Vector3(4.4, Y1, 19.0), h, 0.12, "l83_liner", [{"at": 4.4, "w": 1.4, "h": 2.0}])
	k.wall(Vector3(-4.4, Y1, 31.0), Vector3(4.4, Y1, 31.0), h, 0.12, "l83_liner",
		[{"at": 1.0, "w": 0.9, "h": 2.0}, {"at": 2.8, "w": 1.4, "h": 0.6, "sill": 1.0}, {"at": 6.0, "w": 1.1, "h": 2.0}])
	# galley / ladder-room partition
	k.box(Vector3(-0.55, Y1 + 1.12, 35.5), Vector3(0.1, 2.25, 9.0), "l83_liner")
	# upper deck rooms: radio (stbd) and CO stateroom (port) z 6.5..13.5, sonar fwd z 31..40 port
	var hu := UPC - Y2
	for sx: float in [-1.0, 1.0]:
		k.wall(Vector3(sx * 3.9, Y2, 6.5), Vector3(sx * 1.0, Y2, 6.5), hu, 0.1, "l83_liner")
		k.wall(Vector3(sx * 1.0, Y2, 6.5), Vector3(sx * 1.0, Y2, 13.5), hu, 0.1, "l83_liner", [{"at": 4.4, "w": 0.85, "h": 1.95}])
		k.wall(Vector3(sx * 1.0, Y2, 13.5), Vector3(sx * 3.9, Y2, 13.5), hu, 0.1, "l83_liner")
	k.wall(Vector3(-3.9, Y2, 31.0), Vector3(-0.8, Y2, 31.0), hu, 0.1, "l83_liner", [{"at": 1.6, "w": 0.9, "h": 1.95}])
	k.wall(Vector3(-0.8, Y2, 31.0), Vector3(-0.8, Y2, 40.0), hu, 0.1, "l83_liner")
	# lower deck: aux machinery / torpedo room bulkhead at z 10 with a wide door
	k.wall(Vector3(-3.3, Y0, 10.0), Vector3(3.3, Y0, 10.0), Y1 - TH, 0.12, "l83_bulkhead", [{"at": 3.3, "w": 1.2, "h": 1.9}])
	wt_door(Vector3(0.0, Y0, 10.0), 1.2)


func _stairs() -> void:
	# S3: lower -> middle, aft port (climbs toward the stern)
	k.stairs(Vector3(-2.7, Y0, 6.0), Vector3.FORWARD, 1.0, Y1, 13, "l83_steel", 0.25, false)
	# S1: middle -> upper, aft starboard (climbs toward the stern)
	k.stairs(Vector3(2.7, Y1, 6.0), Vector3.FORWARD, 1.0, Y2 - Y1, 13, "l83_steel", 0.25, false)
	# S4: lower -> middle, forward starboard (climbs toward the stern)
	k.stairs(Vector3(1.9, Y0, 37.0), Vector3.FORWARD, 1.0, Y1, 13, "l83_steel", 0.25, false)
	# S2: middle -> upper, forward (climbs toward the bow)
	k.stairs(Vector3(3.5, Y1, 34.0), Vector3.BACK, 1.0, Y2 - Y1, 13, "l83_steel", 0.25, false)
	# lockers under the high half of every ladder: nobody walks under a stair here
	for st in [[Vector3(-2.7, Y0, 6.0), -1.0, Y1], [Vector3(2.7, Y1, 6.0), -1.0, Y2 - Y1], [Vector3(1.9, Y0, 37.0), -1.0, Y1], [Vector3(3.5, Y1, 34.0), 1.0, Y2 - Y1]]:
		under_stair(st[0], Vector3(0, 0, st[1]), 3.25, st[2], 1.0)
	# railings around the wells (open sides only)
	rail(Vector3(-2.1, Y1, 2.85), Vector3(-2.1, Y1, 6.15))
	rail(Vector3(-3.25, Y1, 6.2), Vector3(-2.15, Y1, 6.2))
	rail(Vector3(2.1, Y2, 2.85), Vector3(2.1, Y2, 6.15))
	rail(Vector3(3.3, Y2, 2.85), Vector3(3.3, Y2, 6.15))
	rail(Vector3(2.15, Y2, 6.2), Vector3(3.25, Y2, 6.2))
	rail(Vector3(2.12, Y1, 5.9), Vector3(2.12, Y1, 6.75))
	rail(Vector3(1.3, Y1, 33.75), Vector3(1.3, Y1, 37.2))
	rail(Vector3(2.5, Y1, 33.75), Vector3(2.5, Y1, 37.2))
	rail(Vector3(1.35, Y1, 37.25), Vector3(2.45, Y1, 37.25))
	rail(Vector3(2.9, Y2, 33.95), Vector3(2.9, Y2, 37.3))
	rail(Vector3(2.95, Y2, 33.85), Vector3(3.9, Y2, 33.85))
	# stair stringers (visual)
	for s in [[Vector3(-2.7, Y0, 6.0), -1.0, Y1], [Vector3(2.7, Y1, 6.0), -1.0, Y2 - Y1], [Vector3(1.9, Y0, 37.0), -1.0, Y1], [Vector3(3.5, Y1, 34.0), 1.0, Y2 - Y1]]:
		var p: Vector3 = s[0]
		var dz: float = s[1] * 3.25
		var rise: float = s[2]
		for sx: float in [-0.52, 0.52]:
			var a := p + Vector3(sx, 0, 0)
			var b := p + Vector3(sx, rise, dz)
			var dir := (b - a).normalized()
			var bas := Basis(Vector3(1, 0, 0), dir.cross(Vector3(1, 0, 0)).normalized(), dir)
			d.box_xf(Transform3D(bas.orthonormalized(), (a + b) * 0.5 + Vector3(0, 0.12, 0)), Vector3(0.05, 0.24, a.distance_to(b)), "l83_yellow", GeoKit.ALL, false)
			d.box_xf(Transform3D(bas.orthonormalized(), (a + b) * 0.5 + Vector3(0, 0.95, 0)), Vector3(0.05, 0.05, a.distance_to(b)), "l83_steel", GeoKit.ALL, false)


func under_stair(foot: Vector3, dir: Vector3, run: float, rise: float, w: float) -> void:
	var t0 := 1.3 / rise * run
	var a := foot + dir * t0
	var b := foot + dir * run
	k.box((a + b) * 0.5 + Vector3(0, 0.62, 0), Vector3(w * 0.96, 1.24, absf(run - t0)), "l83_console")


## The forward escape trunk above the upper deck: a steep ladder-stair into a steel shaft,
## the hatch with its handwheel at the top of the vessel.
func _trunk() -> void:
	k.stairs(Vector3(0.0, Y2, 5.6), Vector3.FORWARD, 1.45, TRUNK_FLOOR - Y2, 10, "l83_steel", 0.3, false)
	k.slab(-0.8, 1.0, 0.8, 2.6, TRUNK_FLOOR, 0.15, "l83_deck_metal")
	under_stair(Vector3(0.0, Y2, 5.6), Vector3(0, 0, -1), 3.0, TRUNK_FLOOR - Y2, 1.4)
	var top := HATCH.y + 0.05
	k.box(Vector3(-0.85, (UPC + top) * 0.5, 3.5), Vector3(0.1, top - UPC, 5.2), "l83_bulkhead")
	k.box(Vector3(0.85, (UPC + top) * 0.5, 3.5), Vector3(0.1, top - UPC, 5.2), "l83_bulkhead")
	k.box(Vector3(0, (UPC + top) * 0.5, 0.95), Vector3(1.8, top - UPC, 0.1), "l83_bulkhead")
	k.box(Vector3(0, (UPC + top) * 0.5, 6.05), Vector3(1.8, top - UPC, 0.1), "l83_bulkhead")
	k.box(Vector3(0, top + 0.05, 3.5), Vector3(1.8, 0.1, 5.2), "l83_bulkhead")
	# hatch: a round lid with handwheel and dogs
	d.cylinder(HATCH, 0.42, 0.08, "l83_green", 20, false)
	d.cylinder(HATCH - Vector3(0, 0.18, 0), 0.06, 0.3, "l83_steel", 8, false)
	for i in 6:
		var a := TAU * i / 6.0
		d.box_xf(Transform3D(Basis(Vector3.UP, a), HATCH - Vector3(0, 0.32, 0) + Vector3(cos(a), 0, sin(a)) * 0.13), Vector3(0.04, 0.04, 0.28), "l83_red_paint", GeoKit.ALL, false)
	d.cylinder(HATCH - Vector3(0, 0.33, 0), 0.27, 0.04, "l83_red_paint", 16, false)
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		d.box(HATCH + Vector3(cos(a) * 0.48, -0.06, sin(a) * 0.48), Vector3(0.1, 0.1, 0.1), "l83_steel", GeoKit.ALL, false)
	# a short ladder against the trunk wall above the platform, and a caged lamp
	for i in 5:
		d.box(Vector3(0, TRUNK_FLOOR + 0.35 + i * 0.32, 1.06), Vector3(0.45, 0.04, 0.04), "l83_steel", GeoKit.ALL, false)
	for sx: float in [-0.24, 0.24]:
		d.box(Vector3(sx, TRUNK_FLOOR + 1.0, 1.06), Vector3(0.04, 1.9, 0.05), "l83_steel", GeoKit.ALL, false)
	lamp(Vector3(0.6, top - 0.06, 4.6), 3, "l83_lamp_warm", false, 0.6, 4.5)
	rail(Vector3(-0.78, TRUNK_FLOOR, 2.6), Vector3(-0.78, TRUNK_FLOOR, 1.05))
	rail(Vector3(0.78, TRUNK_FLOOR, 2.6), Vector3(0.78, TRUNK_FLOOR, 1.05))


## Shielded tunnel through the reactor compartment (middle-deck height) with lead-glass ports.
func _tunnel() -> void:
	var y := Y1
	slab_holes(-0.75, RX, 0.75, 0.0, y, "l83_deck_metal", [Rect2(-0.4, -9.4, 0.8, 0.9), Rect2(-0.4, -5.4, 0.8, 0.9)])
	for zc: float in [-8.95, -4.95]:
		k.box(Vector3(0, y - 0.03, zc), Vector3(0.8, 0.04, 0.9), "l83_glass", GeoKit.PY | GeoKit.NY, true, "metal")
		d.box(Vector3(0, y + 0.01, zc), Vector3(0.95, 0.03, 1.05), "l83_yellow", GeoKit.SIDES, false)
	for sx: float in [-1.0, 1.0]:
		k.wall(Vector3(sx * 0.8, y, RX), Vector3(sx * 0.8, y, 0.0), 2.25, 0.1, "l83_lead",
			[{"at": 4.0, "w": 0.5, "h": 0.36, "sill": 1.15}, {"at": 10.0, "w": 0.5, "h": 0.36, "sill": 1.15}])
		for zc: float in [-4.0, -10.0]:
			k.box(Vector3(sx * 0.82, y + 1.33, zc), Vector3(0.03, 0.36, 0.5), "l83_glass", GeoKit.PX | GeoKit.NX, true, "metal")
	k.slab(-0.8, RX, 0.8, 0.0, y + 2.45, 0.2, "l83_lead")
	for i in 4:
		lamp(Vector3(0, y + 2.24, -1.8 - i * 3.4), 1, "l83_lamp_amber" if i % 2 == 1 else "l83_lamp", true, 0.45, 4.0)
	# reactor compartment below and around the tunnel (seen only through the ports)
	k.slab(-3.4, RX, 3.4, 0.0, -1.0, 0.2, "l83_steel")
	d.cylinder(Vector3(0, 0.2, -7.0), 1.45, 2.4, "l83_steel", 20, false)
	d.cylinder(Vector3(0, 1.55, -7.0), 1.15, 0.35, "l83_yellow", 20, false)
	for i in 8:
		var a := TAU * i / 8.0
		d.cylinder(Vector3(cos(a) * 0.95, 1.85, -7.0 + sin(a) * 0.95), 0.08, 0.3, "l83_steel", 6, false)
	for sx: float in [-1.0, 1.0]:
		for zc: float in [-3.5, -10.5]:
			d.cylinder(Vector3(sx * 2.3, 1.7, zc), 0.75, 5.4, "l83_green", 14, false)
		d.box(Vector3(sx * 1.2, 0.9, -7.0), Vector3(1.3, 0.35, 0.35), "l83_steel", GeoKit.ALL, false)
	L.reactor_light_pos = Vector3(1.6, 1.4, -7.0)


func _engine_room() -> void:
	var z0 := RX
	var z1 := AFT
	# lower flats
	k.slab(-3.39, z1, 3.39, z0, Y0, TH, "l83_deck_metal")
	# manoeuvring platform z -19..-14, side catwalks |x| 2.2..4.75, aft crossover z -41..-39
	k.slab(-4.7, -19.0, 4.7, z0, Y1, TH, "l83_deck_metal", GeoKit.PY | GeoKit.SIDES)
	k.quad(Vector3(0, Y1 - TH - 0.002, -16.5), Vector3.DOWN, Vector3(4.7, 0, 0), Vector3(0, 0, 2.5), "l83_overhead")
	for sx: float in [-1.0, 1.0]:
		k.slab(sx * 2.2, -41.0, sx * 4.7, -19.0, Y1, TH, "l83_deck_metal")
		rail(Vector3(sx * 2.2, Y1, -19.05), Vector3(sx * 2.2, Y1, -38.95))
		k.box(Vector3(sx * 4.8, Y1 + 1.2, -29.0), Vector3(0.1, 2.4, 30.0), "l83_hull_in", 0)
	k.slab(-2.2, -41.0, 2.2, -39.0, Y1, TH, "l83_deck_metal")
	rail(Vector3(-2.15, Y1, -38.95), Vector3(2.15, Y1, -38.95))
	rail(Vector3(-2.15, Y1, -19.05), Vector3(-0.55, Y1, -19.05))
	rail(Vector3(0.55, Y1, -19.05), Vector3(2.15, Y1, -19.05))
	# S6: lower flats -> platform, central, climbing toward the bow
	k.stairs(Vector3(0.0, Y0, -22.25), Vector3.BACK, 1.0, Y1, 13, "l83_steel", 0.25, false)
	under_stair(Vector3(0.0, Y0, -22.25), Vector3(0, 0, 1), 3.25, Y1, 1.0)
	for sx: float in [-0.55, 0.55]:
		var a := Vector3(sx, Y0, -22.25)
		var b := Vector3(sx, Y1, -19.0)
		var dir := (b - a).normalized()
		var bas := Basis(Vector3(1, 0, 0), Vector3(1, 0, 0).cross(dir) * -1.0, dir).orthonormalized()
		d.box_xf(Transform3D(bas, (a + b) * 0.5 + Vector3(0, 0.95, 0)), Vector3(0.05, 0.05, a.distance_to(b)), "l83_steel", GeoKit.ALL, false)
	# reactor aft bulkhead (door from the tunnel onto the platform) and the stern bulkhead
	k.wall(Vector3(-4.7, Y1, z0), Vector3(4.7, Y1, z0), 5.3, 0.14, "l83_bulkhead", [{"at": 4.7, "w": 0.9, "h": 1.75}])
	wt_door(Vector3(0, Y1, z0 - 0.05))
	k.box(Vector3(0, 1.22, z0 - 0.05), Vector3(6.8, 2.45, 0.14), "l83_bulkhead")
	k.box(Vector3(0, 4.0, z1), Vector3(9.6, 8.6, 0.2), "l83_bulkhead")
	wt_door(Vector3(0, Y0, z1 + 0.12), 0.8)
	d.box(Vector3(0, 0.9, z1 + 0.14), Vector3(0.8, 1.6, 0.06), "l83_bulkhead", GeoKit.ALL, false)
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 3.36, 1.22, -29.0), Vector3(0.12, 2.45, 30.0), "l83_hull_in", GeoKit.PX if sx < 0 else GeoKit.NX)
	for i in 6:
		var z := -21.0 - i * 3.4
		lamp(Vector3(sx_lamp(i), 2.3, z), 0, "l83_lamp", true, 0.55, 6.0)
		lamp(Vector3(-sx_lamp(i) * 1.6, 6.9, z - 1.7), 1, "l83_lamp", true, 0.5, 8.0)
	lamp(Vector3(-2.0, Y1 + 2.3, -16.5), 1, "l83_lamp_red", false, 0.5, 5.0)
	lamp(Vector3(2.0, Y1 + 2.3, -16.5), 1, "l83_lamp", false, 0.5, 5.0)


func sx_lamp(i: int) -> float:
	return -2.6 if i % 2 == 0 else 2.6


## The pressure hull seen from inside the engine room: painted skin plus ring frames.
func _hull_skin() -> void:
	var sides := 28
	var z0 := 0.0
	var z1 := AFT
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var am := (a0 + a1) * 0.5
		var p0 := Vector3(cos(a0) * R, HC + sin(a0) * R, 0)
		var p1 := Vector3(cos(a1) * R, HC + sin(a1) * R, 0)
		if (p0.y + p1.y) * 0.5 < -0.9:
			continue
		var n := Vector3(-cos(am), -sin(am), 0)
		var c := (p0 + p1) * 0.5 + Vector3(0, 0, (z0 + z1) * 0.5)
		d.quad(c, n, (p1 - p0) * 0.5, Vector3(0, 0, (z0 - z1) * 0.5), "l83_hull_in")
	var z := z0 - 1.2
	while z > z1 + 0.5:
		for i in sides:
			var a0 := TAU * i / sides
			var a1 := TAU * (i + 1) / sides
			var p0 := Vector3(cos(a0) * (R - 0.09), HC + sin(a0) * (R - 0.09), z)
			var p1 := Vector3(cos(a1) * (R - 0.09), HC + sin(a1) * (R - 0.09), z)
			if (p0.y + p1.y) * 0.5 < -0.9:
				continue
			var dir := (p1 - p0).normalized()
			var bas := Basis(dir, Vector3(0, 0, 1).cross(dir), Vector3(0, 0, 1)).orthonormalized()
			d.box_xf(Transform3D(bas, (p0 + p1) * 0.5), Vector3(p0.distance_to(p1) + 0.02, 0.18, 0.12), "l83_hull_in", GeoKit.ALL, false)
		z -= 2.4
