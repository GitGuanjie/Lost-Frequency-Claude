extends RefCounted
## Level 26: the exterior of the cruise liner Adventure ("SS Fun =)"). Ship axis along Z,
## bow at +Z. Main deck y = 0 (cabin superstructure, promenades, foredeck, stern deck),
## upper deck y = 3.2 (crimson pool, restaurant, bar and lounge deckhouse), sun deck
## y = 6.4 (open-air bar remnants, broken loungers, posters, funnel). Sea surface y = -7.

const SEA_Y := -7.0
const UP := 3.2
const SUN := 6.4
const T := 0.2
const BOW := [Vector2(-9, 50), Vector2(9, 50), Vector2(7.6, 61), Vector2(4.4, 69), Vector2(0, 74), Vector2(-4.4, 69), Vector2(-7.6, 61)]
const STERN := [Vector2(9, -60), Vector2(-9, -60), Vector2(-8.4, -67), Vector2(-6.2, -71.5), Vector2(0, -73.5), Vector2(6.2, -71.5), Vector2(8.4, -67)]
const CAB0 := -44.0           # cabin block aft end
const CAB_P := 2.6            # cabin pitch: 20 cabins per side
const LOBBY := Vector2(8.0, 16.0)
const POOL := Rect2(-4.0, -54.0, 8.0, 7.0)
const GATE_Z := 0.0           # starboard boarding gate, gangway gone

var L: LevelBase
var k: GeoKit
var d: GeoKit
var props: Node3D
var labels: Node3D
var rng: RandomNumberGenerator
var posters: Array = []        # [{pos, n}]
var open_cabins: Array = []
var lamp_points: Array = []    # [pos, color, energy, range, flicker]
var music_points: Array = []
var splats: Array = []


func _init(level: LevelBase, arch: GeoKit, dress: GeoKit, r: RandomNumberGenerator) -> void:
	L = level
	k = arch
	d = dress
	rng = r
	props = Node3D.new()
	props.name = "ShipProps"
	L.add_child(props)
	labels = Node3D.new()
	labels.name = "ShipLabels"
	L.add_child(labels)


static func materials() -> void:
	MatLib.define("l26_deck", {"albedo_a": Color(0.5, 0.38, 0.26), "albedo_b": Color(0.42, 0.31, 0.21), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.14), "grout_width": 0.006, "grout_color": Color(0.12, 0.09, 0.07), "roughness_a": 0.6,
		"roughness_b": 0.85, "stain_amount": 0.5, "stain_color": Color(0.26, 0.18, 0.12), "wetness": 0.2}, "")
	MatLib.define("l26_hull", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.78, 0.78, 0.76), "noise_scale": 0.7,
		"stain_amount": 0.22, "stain_color": Color(0.5, 0.42, 0.32), "stain_scale": 0.6, "roughness_a": 0.45, "roughness_b": 0.7,
		"grime_height": 1.2, "grime_color": Color(0.35, 0.3, 0.26), "floor_y": -7.0}, "")
	MatLib.define("l26_hull_band", {"albedo_a": Color(0.12, 0.2, 0.42), "albedo_b": Color(0.1, 0.17, 0.36), "roughness_a": 0.4}, "")
	MatLib.define("l26_white", {"albedo_a": Color(0.84, 0.84, 0.82), "albedo_b": Color(0.77, 0.77, 0.75), "noise_scale": 1.0,
		"stain_amount": 0.4, "stain_color": Color(0.5, 0.42, 0.32), "grime_height": 0.5, "grime_color": Color(0.45, 0.4, 0.33),
		"roughness_a": 0.45, "roughness_b": 0.7, "bump_strength": 0.4}, "")
	MatLib.define("l26_steel", {"albedo_a": Color(0.42, 0.44, 0.46), "albedo_b": Color(0.34, 0.36, 0.38), "metallic_value": 0.6,
		"roughness_a": 0.4, "roughness_b": 0.7, "stain_amount": 0.4, "stain_color": Color(0.38, 0.22, 0.12)}, "")
	MatLib.define("l26_rail", {"albedo_a": Color(0.5, 0.36, 0.22), "albedo_b": Color(0.44, 0.31, 0.19), "pattern": 3,
		"pattern_scale": Vector2(1.5, 0.05), "roughness_a": 0.35, "roughness_b": 0.55}, "")
	MatLib.define("l26_carpet", {"albedo_a": Color(0.42, 0.08, 0.1), "albedo_b": Color(0.34, 0.06, 0.08), "pattern": 10,
		"pattern_scale": Vector2(0.5, 0.5), "pattern_color": Color(0.62, 0.48, 0.2), "pattern_strength": 0.4, "stain_amount": 0.55,
		"stain_color": Color(0.16, 0.08, 0.06), "roughness_a": 0.95, "roughness_b": 1.0, "wetness": 0.25}, "")
	MatLib.define("l26_wallpaper", {"albedo_a": Color(0.78, 0.7, 0.55), "albedo_b": Color(0.72, 0.64, 0.5), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.66, 0.56, 0.4), "pattern_strength": 0.4, "stain_amount": 0.5,
		"stain_color": Color(0.42, 0.3, 0.2), "grime_height": 0.6, "grime_color": Color(0.4, 0.3, 0.2), "peel_amount": 0.15,
		"peel_color": Color(0.6, 0.6, 0.58)}, "")
	MatLib.define("l26_cabin_door", {"albedo_a": Color(0.36, 0.22, 0.13), "albedo_b": Color(0.3, 0.18, 0.1), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.4), "grout_width": 0.003, "roughness_a": 0.35, "roughness_b": 0.5, "stain_amount": 0.25}, "")
	MatLib.define("l26_ceiling", {"albedo_a": Color(0.82, 0.8, 0.74), "albedo_b": Color(0.76, 0.74, 0.68), "pattern": 7,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.6, 0.58, 0.52), "stain_amount": 0.4,
		"stain_color": Color(0.55, 0.45, 0.3)}, "")
	MatLib.define("l26_pool_tile", {"albedo_a": Color(0.62, 0.78, 0.8), "albedo_b": Color(0.58, 0.74, 0.76), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.008, "grout_color": Color(0.42, 0.46, 0.46), "roughness_a": 0.12,
		"roughness_b": 0.3, "stain_amount": 0.55, "stain_color": Color(0.42, 0.08, 0.06), "grime_height": 1.4,
		"grime_color": Color(0.36, 0.06, 0.05), "floor_y": 2.0}, "")
	MatLib.define("l26_brass", {"albedo_a": Color(0.72, 0.56, 0.28), "albedo_b": Color(0.6, 0.46, 0.22), "metallic_value": 0.9,
		"roughness_a": 0.25, "roughness_b": 0.45, "stain_amount": 0.3}, "")
	MatLib.define("l26_funnel", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.8, 0.8, 0.78), "stain_amount": 0.5,
		"stain_color": Color(0.3, 0.28, 0.26), "stain_scale": 0.3, "roughness_a": 0.5}, "")
	MatLib.define("l26_funnel_red", {"albedo_a": Color(0.62, 0.1, 0.08), "albedo_b": Color(0.55, 0.08, 0.06), "stain_amount": 0.3,
		"stain_color": Color(0.2, 0.1, 0.08)}, "")
	MatLib.define("l26_black", {"albedo_a": Color(0.06, 0.06, 0.06), "albedo_b": Color(0.1, 0.1, 0.1), "roughness_a": 0.6}, "")
	MatLib.define("l26_boat", {"albedo_a": Color(0.92, 0.5, 0.12), "albedo_b": Color(0.85, 0.44, 0.1), "roughness_a": 0.4,
		"stain_amount": 0.35, "stain_color": Color(0.4, 0.3, 0.2)}, "")
	MatLib.define("l26_blood", {"albedo_a": Color(0.24, 0.02, 0.02), "albedo_b": Color(0.16, 0.01, 0.01), "wetness": 0.6,
		"roughness_a": 0.2, "roughness_b": 0.5, "noise_scale": 3.0}, "")
	MatLib.define("l26_poster", {"albedo_a": Color(0.92, 0.9, 0.82), "albedo_b": Color(0.86, 0.84, 0.76), "noise_scale": 5.0,
		"stain_amount": 0.4, "stain_color": Color(0.6, 0.5, 0.35)}, "")
	MatLib.define("l26_glass_dark", {"albedo_a": Color(0.12, 0.16, 0.18), "albedo_b": Color(0.1, 0.13, 0.15), "roughness_a": 0.05,
		"roughness_b": 0.15, "metallic_value": 0.4}, "")
	MatLib.define("l26_cloth", {"albedo_a": Color(0.82, 0.8, 0.74), "albedo_b": Color(0.74, 0.72, 0.66), "noise_scale": 3.0,
		"stain_amount": 0.55, "stain_color": Color(0.45, 0.12, 0.1)}, "")
	MatLib.define("l26_stripe", {"albedo_a": Color(0.86, 0.32, 0.38), "albedo_b": Color(0.86, 0.32, 0.38), "pattern": 2,
		"pattern_scale": Vector2(0.3, 1.0), "pattern_color": Color(0.94, 0.92, 0.86), "pattern_strength": 1.0}, "")
	MatLib.register("l26_fixture", MatLib.panel(Color(1.0, 0.95, 0.84), 2.2))
	MatLib.register("l26_fixture_dim", MatLib.panel(Color(1.0, 0.9, 0.75), 1.1, 0.35))
	MatLib.register("l26_neon_pink", MatLib.panel(Color(1.0, 0.25, 0.6), 4.0))
	MatLib.register("l26_neon_green", MatLib.panel(Color(0.35, 1.0, 0.45), 3.0, 0.1))
	MatLib.register("l26_window_lit", MatLib.panel(Color(1.0, 0.86, 0.6), 1.4))
	MatLib.register("l26_crimson", MatLib.water({"shallow_color": Color(0.34, 0.02, 0.02), "deep_color": Color(0.1, 0.0, 0.0),
		"absorption": 2.0, "clarity": 0.0, "dark_surface": 0.6, "wave_height": 0.004, "wave_scale": 1.5, "wave_speed": 0.2, "foam_amount": 0.0}))


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


func label(text: String, p: Vector3, n: Vector3, px: float, col: Color, size := 64, parent: Node3D = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.basis = Basis.looking_at(-n, Vector3.UP)
	l.position = p + n * 0.01
	l.visibility_range_end = 60.0
	(parent if parent else labels).add_child(l)
	return l


## A horizontal prism from a convex polygon (x, z), top at y_top.
func prism(poly: Array, y_top: float, thick: float, mat: String, collide := true) -> void:
	var c := Vector3.ZERO
	for p in poly:
		c += Vector3(p.x, 0, p.y)
	c /= poly.size()
	var pts := PackedVector3Array()
	for i in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		var a3 := Vector3(a.x, y_top, a.y)
		var b3 := Vector3(b.x, y_top, b.y)
		k._tri_fan(Vector3(c.x, y_top, c.z), a3, b3, Vector3.UP, mat)
		k._tri_fan(Vector3(c.x, y_top - thick, c.z), a3 - Vector3(0, thick, 0), b3 - Vector3(0, thick, 0), Vector3.DOWN, mat)
		pts.append(a3)
		pts.append(a3 - Vector3(0, thick, 0))
	if collide:
		var cs := CollisionShape3D.new()
		var sh := ConvexPolygonShape3D.new()
		sh.points = pts
		cs.shape = sh
		cs.set_meta("surface", "wood")
		k.body.add_child(cs)


## Railing along a -> b: posts, a varnished top rail and two steel bars; one collider.
func railing(a: Vector3, b: Vector3, h := 1.1, collide := true) -> void:
	var dir := (b - a)
	var len := Vector2(dir.x, dir.z).length()
	if len < 0.05:
		return
	var bas := Basis(dir.normalized(), Vector3.UP, dir.normalized().cross(Vector3.UP))
	var mid := (a + b) * 0.5
	d.box_xf(Transform3D(bas, mid + Vector3.UP * h), Vector3(len, 0.07, 0.1), "l26_rail", GeoKit.ALL, false)
	for hh: float in [0.38, 0.72]:
		d.box_xf(Transform3D(bas, mid + Vector3.UP * hh), Vector3(len, 0.03, 0.03), "l26_steel", GeoKit.ALL, false)
	var n := int(len / 1.5) + 1
	for i in n + 1:
		var p := a + dir * (float(i) / n)
		d.box(p + Vector3.UP * (h * 0.5), Vector3(0.05, h, 0.05), "l26_steel", GeoKit.ALL, false)
	if collide:
		k.add_box_shape(Transform3D(bas, mid + Vector3.UP * (h * 0.5 + 0.1)), Vector3(len, h + 0.2, 0.12), "metal")


# ------------------------------------------------------------------ hull and decks

func hull() -> void:
	# main deck: midship rectangle plus bow and stern prisms
	k.slab(-9.0, -60.0, 9.0, 50.0, 0.0, 0.4, "l26_deck")
	prism(BOW, 0.0, 0.4, "l26_deck")
	prism(STERN, 0.0, 0.4, "l26_deck")
	# hull plating down past the waterline; a navy band; bulwarks at bow and stern
	var outline: Array = []
	outline.append_array([Vector2(9, -60), Vector2(9, 50)])
	for i in range(2, BOW.size()):
		outline.append(BOW[i])
	outline.append(Vector2(-9, 50))
	outline.append(Vector2(-9, -60))
	for i in range(2, STERN.size()):
		outline.append(STERN[i])
	for i in outline.size():
		var a: Vector2 = outline[i]
		var b: Vector2 = outline[(i + 1) % outline.size()]
		var a3 := Vector3(a.x, SEA_Y - 3.0, a.y)
		var b3 := Vector3(b.x, SEA_Y - 3.0, b.y)
		var nrm := Vector3(b.y - a.y, 0, -(b.x - a.x)).normalized()
		if nrm.dot(Vector3(a.x + b.x, 0, a.y + b.y)) < 0.0:
			nrm = -nrm
		var off := nrm * 0.16
		k.wall(a3 + off, b3 + off, 3.0 - SEA_Y, 0.3, "l26_hull")
		k.wall(Vector3(a.x, -1.7, a.y) + off * 2.1, Vector3(b.x, -1.7, b.y) + off * 2.1, 0.45, 0.06, "l26_hull_band")
		var bow_part: bool = a.y >= 50.0 and b.y >= 50.0
		var stern_part: bool = a.y <= -60.0 and b.y <= -60.0
		if bow_part or stern_part:
			# solid bulwark with a varnished cap
			k.wall(Vector3(a.x, 0, a.y) + off, Vector3(b.x, 0, b.y) + off, 1.05, 0.2, "l26_hull")
			d.wall(Vector3(a.x, 1.05, a.y) + off, Vector3(b.x, 1.05, b.y) + off, 0.06, 0.3, "l26_rail")
	# a red antifouling band at the waterline and two rows of portholes along both sides
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 9.34, SEA_Y + 0.1, -5.0), Vector3(0.04, 0.9, 110.0), "l26_funnel_red", GeoKit.ALL, false)
		for row in 2:
			var z := -57.0
			while z < 48.0:
				d.box(Vector3(sx * 9.34, -3.4 - row * 1.5, z), Vector3(0.04, 0.42, 0.42), "l26_glass_dark", GeoKit.ALL, false)
				z += 2.6 if row == 0 else 3.9
	# promenade rails along both sides, with the starboard boarding gate left open
	railing(Vector3(-8.85, 0, -60), Vector3(-8.85, 0, 50))
	railing(Vector3(8.85, 0, -60), Vector3(8.85, 0, GATE_Z - 0.8))
	railing(Vector3(8.85, 0, GATE_Z + 0.8), Vector3(8.85, 0, 50))
	for s: float in [-1.0, 1.0]:
		d.box(Vector3(8.85, 0.6, GATE_Z + s * 0.8), Vector3(0.12, 1.2, 0.12), "l26_brass", GeoKit.ALL, false)
	d.box(Vector3(8.85, 0.02, GATE_Z), Vector3(0.3, 0.04, 1.6), "l26_steel", GeoKit.ALL, false)
	# the name on both bows and the transom: ADVENTURE, crudely crossed out, SS Fun =)
	for s: float in [-1.0, 1.0]:
		var nn := Vector3(s * 11.0, 0, 1.4).normalized()
		_name_plate(Vector3(s * 8.3, -2.6, 55.5) + nn * 0.34, nn, s)


func _name_plate(p: Vector3, n: Vector3, s: float) -> void:
	label("ADVENTURE", p, n, 0.012, Color(0.1, 0.1, 0.12), 96)
	var side := n.cross(Vector3.UP).normalized()
	var b := Basis.looking_at(-n, Vector3.UP)
	for i in 3:
		d.box_xf(Transform3D(b * Basis(Vector3(0, 0, 1), 0.12 - i * 0.12), p + n * 0.03 + Vector3.UP * (0.1 - i * 0.12)), Vector3(3.6, 0.12, 0.02), "l26_funnel_red", GeoKit.ALL, false)
	var f := label("SS Fun =)", p + Vector3.UP * 1.2 - side * 0.4 * s, n, 0.013, Color(0.75, 0.08, 0.06), 96)
	f.rotation_degrees.z += -6.0 * s


## Main-deck superstructure: forty staterooms off a carpeted hallway, a lobby with the
## elevators, side doors to the covered promenades; its roof is the upper deck.
func superstructure() -> void:
	var z0 := CAB0
	var z1 := LOBBY.y
	var hgt := 3.0
	# floor finish: carpet in hallway and lobby
	k.box_mm(Vector3(-1.1, 0.0, z0), Vector3(1.1, 0.02, z1), "l26_carpet", GeoKit.PY, false)
	k.box_mm(Vector3(-6.4, 0.0, LOBBY.x), Vector3(6.4, 0.02, z1), "l26_carpet", GeoKit.PY, false)
	# outer walls with a window per cabin
	for s: float in [-1.0, 1.0]:
		var ops: Array = []
		for i in 20:
			ops.append({"at": i * CAB_P + CAB_P * 0.5, "w": 0.9, "h": 0.8, "sill": 1.1})
		ops.append({"at": (LOBBY.x + LOBBY.y) * 0.5 - z0, "w": 1.6, "h": 2.2, "sill": 0.0})
		k.wall(Vector3(s * 6.5, 0, z0), Vector3(s * 6.5, 0, z1), hgt, T, "l26_white", ops)
		for i in 20:
			var wz := z0 + i * CAB_P + CAB_P * 0.5
			d.box(Vector3(s * 6.5, 1.5, wz), Vector3(0.04, 0.8, 0.9), "l26_glass_dark", GeoKit.ALL, false)
	# aft wall with the door onto the stern deck, forward wall with the elevators
	k.wall(Vector3(-6.6, 0, z0), Vector3(6.6, 0, z0), hgt, T, "l26_white", [{"at": 6.6, "w": 1.2, "h": 2.2}])
	k.wall(Vector3(-6.6, 0, z1), Vector3(6.6, 0, z1), hgt, T, "l26_white")
	# hallway walls: a door per cabin (20 each side); lobby at the forward end
	for s: float in [-1.0, 1.0]:
		var ops2: Array = []
		for i in 20:
			ops2.append({"at": i * CAB_P + CAB_P * 0.5 - 0.6, "w": 0.85, "h": 2.05})
		k.wall(Vector3(s * 1.2, 0, z0), Vector3(s * 1.2, 0, LOBBY.x), hgt, T, "l26_wallpaper", ops2)
		for i in 21:
			var pz := z0 + i * CAB_P
			k.wall(Vector3(s * 1.3, 0, pz), Vector3(s * 6.4, 0, pz), hgt, 0.12, "l26_wallpaper")
	k.slab(-6.6, z0, 6.6, z1, hgt + 0.01, 0.01, "l26_ceiling", GeoKit.NY)
	# cabin doors: most closed and occupied, some open onto what is left
	var r := rng
	var open_set := {}
	while open_set.size() < 9:
		open_set[r.randi() % 40] = true
	for s: float in [-1.0, 1.0]:
		for i in 20:
			var idx := i + (0 if s < 0 else 20)
			var dz := z0 + i * CAB_P + CAB_P * 0.5 - 0.6
			var num: int = (101 if s < 0 else 121) + i
			var nx := s * 1.09
			label(str(num), Vector3(nx, 2.25, dz), Vector3(-s, 0, 0), 0.0026, Color(0.85, 0.7, 0.35))
			if open_set.has(idx):
				var hinge := Vector3(s * 1.2, 0, dz - 0.42)
				var leaf_dir := Vector3(s * 0.75, 0, 0.66).normalized()
				d.box_xf(Transform3D(Basis(leaf_dir, Vector3.UP, leaf_dir.cross(Vector3.UP)), hinge + leaf_dir * 0.42 + Vector3.UP * 1.02), Vector3(0.84, 2.03, 0.04), "l26_cabin_door", GeoKit.ALL, false)
				open_cabins.append({"c": Vector3(s * 3.85, 0, z0 + i * CAB_P + CAB_P * 0.5), "s": s, "door": Vector3(s * 1.2, 0, dz)})
			else:
				d.box(Vector3(s * 1.2, 1.02, dz), Vector3(0.06, 2.03, 0.84), "l26_cabin_door", GeoKit.ALL, true)
				d.box(Vector3(s * 1.16, 1.0, dz + 0.3), Vector3(0.04, 0.05, 0.05), "l26_brass", GeoKit.ALL, false)
				if r.randf() < 0.35:
					music_points.append(Vector3(s * 3.0, 1.2, dz))
	# hallway fluorescent fixtures; a few flicker
	for i in 13:
		var lz := z0 + 2.0 + i * 4.4
		d.box(Vector3(0, hgt - 0.05, lz), Vector3(0.4, 0.08, 1.2), "l26_white", GeoKit.ALL, false)
		var fl := 0.5 if i % 5 == 3 else 0.0
		d.panel(Vector3(0, hgt - 0.095, lz), 0.32, 1.1, "l26_fixture_dim" if fl > 0.0 else "l26_fixture")
		lamp_points.append([Vector3(0, hgt - 0.4, lz), Color(1.0, 0.92, 0.8), 0.9, 6.0, fl])
	# lobby: chandelier, elevator doors, brass
	_p("ph/Chandelier_01", Vector3(0, hgt - 0.82, 12.0), 0.0, 0.8)
	lamp_points.append([Vector3(0, 2.0, 12.0), Color(1.0, 0.85, 0.6), 1.6, 8.0, 0.0])
	for x: float in [-2.0, 2.0]:
		elevator_doors(Vector3(x, 0, z1 - 0.12), Vector3(0, 0, -1))
	_p("ph/Sofa_01", Vector3(-5.2, 0, 10.5), 90.0)
	_p("ph/ArmChair_01", Vector3(5.0, 0, 9.4), -120.0)
	_p("kenney/furniture-kit/pottedplant", Vector3(-5.8, 0, 15.3), 0.0, 1.3)
	_p("kenney/furniture-kit/pottedplant", Vector3(5.8, 0, 15.3), 0.0, 1.3)
	# door frames onto the promenade
	for s: float in [-1.0, 1.0]:
		var dzc := (LOBBY.x + LOBBY.y) * 0.5
		d.box(Vector3(s * 6.5, 2.25, dzc), Vector3(0.3, 0.1, 1.8), "l26_brass", GeoKit.ALL, false)


func elevator_doors(p: Vector3, n: Vector3) -> void:
	elevator_doors_into(d, p, n)


func elevator_doors_into(d: GeoKit, p: Vector3, n: Vector3, w := 1.3) -> void:
	var side := n.cross(Vector3.UP).normalized()
	var b := Basis(side, Vector3.UP, side.cross(Vector3.UP))
	d.box_xf(Transform3D(b, p + n * 0.02 + Vector3.UP * 1.1), Vector3(w, 2.2, 0.06), "l26_brass", GeoKit.ALL, false)
	d.box_xf(Transform3D(b, p + n * 0.055 + Vector3.UP * 1.1), Vector3(0.012, 2.2, 0.01), "l26_black", GeoKit.ALL, false)
	d.box_xf(Transform3D(b, p + n * 0.03 + Vector3.UP * 2.42), Vector3(w + 0.2, 0.2, 0.08), "l26_brass", GeoKit.ALL, false)
	if w > 1.0:
		d.box_xf(Transform3D(b, p + n * 0.06 + side * (w * 0.5 + 0.3) + Vector3.UP * 1.2), Vector3(0.12, 0.3, 0.03), "l26_steel", GeoKit.ALL, false)
		d.box_xf(Transform3D(b, p + n * 0.08 + side * (w * 0.5 + 0.3) + Vector3.UP * 1.25), Vector3(0.05, 0.05, 0.02), "l26_neon_green", GeoKit.ALL, false)


func cabin_interiors() -> void:
	for oc in open_cabins:
		var c: Vector3 = oc["c"]
		var s: float = oc["s"]
		var zc := c.z
		_p("kenney/furniture-kit/bedsingle" if rng.randf() < 0.5 else "kenney/furniture-kit/beddouble", Vector3(s * 5.2, 0, zc + 0.1), 90.0 * s + rng.randf_range(-20, 20), 0.55)
		for i in 3 + rng.randi() % 3:
			var tid: String = ["ph/trashbag", "kenney/food-kit/pizza-box", "kenney/food-kit/soda-can-crushed", "ph/cardboard_box_01", "kenney/food-kit/plate-broken"][rng.randi() % 5]
			var hh := 0.0
			if tid.begins_with("kenney/food-kit"):
				hh = 0.05 if tid.ends_with("box") else 0.1
			_p(tid, Vector3(s * rng.randf_range(2.0, 4.8), 0, zc + rng.randf_range(-0.9, 0.9)), rng.randf() * 360.0, hh)
		_p("ph/Television_01", Vector3(s * 1.7, 0, zc - 0.6), -90.0 * s + 180.0)
		splats.append([Vector3(s * rng.randf_range(2.2, 4.5), 0.012, zc + rng.randf_range(-0.8, 0.8)), 0.6])
		lamp_points.append([Vector3(s * 4.0, 2.3, zc), Color(1.0, 0.78, 0.55), 0.7, 3.8, 0.0])
