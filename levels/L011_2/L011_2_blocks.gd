extends RefCounted
## Level 11.2 exterior kit: identical orange-and-white panel apartment blocks,
## the Banner Building, M.E.G. tents, street furniture and the shrinking,
## vacant Level 11 buildings along the approach road (the blending zone).
## Blocks are 64 m x 13 m x 9 storeys (2.9 m); the long axis is x or z.

const STOREY := 2.9
const FLOORS := 9
const BAY := 3.2
const DEPTH := 13.0
const LENGTH := 64.0

var lvl
var r := RandomNumberGenerator.new()


func _init(level) -> void:
	lvl = level
	r.seed = hash([level.level_seed, 112])


## A block centred at c with its long axis along x (axis_x) or z.
## solid_from: the body is a solid mass from this height up (0 = whole block);
## enterable blocks build their own ground floors. inner: faces the courtyard
## at +side (balconies on that side). south_hits: barricade dents on the face
## nearest Level 11.
func block(k: GeoKit, c: Vector3, axis_x: bool, solid_from: float, lit_ratio: float, barricade: float, balcony_side: int, detail: bool) -> void:
	var hgt := STOREY * FLOORS
	var size := Vector3(LENGTH, hgt - solid_from, DEPTH) if axis_x else Vector3(DEPTH, hgt - solid_from, LENGTH)
	k.box(c + Vector3(0, solid_from + size.y * 0.5, 0), size, "l112_white")
	# parapet, roof snow and roof boxes
	var top := c + Vector3(0, hgt, 0)
	var ps := Vector3(LENGTH + 0.3, 0.9, DEPTH + 0.3) if axis_x else Vector3(DEPTH + 0.3, 0.9, LENGTH + 0.3)
	k.box(top + Vector3(0, 0.45, 0), ps, "l112_orange", GeoKit.ALL, false)
	k.box(top + Vector3(0, 0.92, 0), ps - Vector3(0.6, 0.86, 0.6), "l112_snow", GeoKit.PY, false)
	for i in 3:
		var off := (float(i) - 1.0) * 21.0
		k.box(top + (Vector3(off, 1.6, 0) if axis_x else Vector3(0, 1.6, off)), Vector3(3.2, 3.2, 4.0) if axis_x else Vector3(4.0, 3.2, 3.2), "l112_white", GeoKit.ALL, false)
		k.box(top + (Vector3(off, 3.25, 0) if axis_x else Vector3(0, 3.25, off)), Vector3(3.4, 0.12, 4.2) if axis_x else Vector3(4.2, 0.12, 3.4), "l112_snow", GeoKit.PY, false)
	var bays := int(LENGTH / BAY)
	for side in [-1, 1]:
		var n := Vector3(0, 0, side) if axis_x else Vector3(side, 0, 0)
		var t := Vector3(1, 0, 0) if axis_x else Vector3(0, 0, 1)
		var face := c + n * (DEPTH * 0.5)
		# orange stair-core bands (full height) at three entrances
		for i in 3:
			var off := (float(i) - 1.0) * 21.0
			k.box(face + t * off + n * 0.12 + Vector3(0, (hgt + solid_from) * 0.5, 0), _sz(t, n, 3.0, hgt - solid_from, 0.24), "l112_orange", GeoKit.ALL, false)
			# stair-core windows: narrow vertical strip
			for f in FLOORS:
				var y := f * STOREY + 1.6
				if f * STOREY < solid_from - 0.1:
					continue
				k.box(face + t * off + n * 0.25 + Vector3(0, y, 0), _sz(t, n, 0.9, 1.2, 0.04), "l112_win_dark" if r.randf() > 0.4 else "l112_win_stair", GeoKit.ALL, false)
		for b in bays:
			var u := -LENGTH * 0.5 + BAY * (b + 0.5)
			if _near_core(u):
				continue
			for f in FLOORS:
				var y := f * STOREY + 1.45
				if f * STOREY < solid_from - 0.1:
					continue
				var p := face + t * u + n * 0.03 + Vector3(0, y, 0)
				var lit := r.randf() < lit_ratio
				var plated := f <= 1 and r.randf() < barricade
				if plated:
					k.box(p + n * 0.06, _sz(t, n, 1.7, 1.7, 0.08), "l112_blackmetal", GeoKit.ALL, false)
					if side == 1 and not axis_x and r.randf() < 0.4 or (axis_x and side == 1 and r.randf() < 0.5):
						for d in 3:
							k.box(p + n * 0.11 + t * r.randf_range(-0.6, 0.6) + Vector3(0, r.randf_range(-0.6, 0.6), 0), _sz(t, n, 0.06, 0.06, 0.02), "l112_dent", GeoKit.ALL, false)
				else:
					k.box(p, _sz(t, n, 1.5, 1.5, 0.04), "l112_win_lit" if lit else "l112_win_dark", GeoKit.ALL, false)
				if detail:
					k.box(p + n * 0.08 + Vector3(0, -0.8, 0), _sz(t, n, 1.7, 0.08, 0.2), "l112_white_trim", GeoKit.ALL, false)
					k.box(p + n * 0.14 + Vector3(0, -0.75, 0), _sz(t, n, 1.7, 0.05, 0.16), "l112_snow", GeoKit.PY, false)
			# orange spandrel on every bay of the first floor line
			k.box(face + t * u + n * 0.05 + Vector3(0, STOREY - 0.15, 0), _sz(t, n, BAY - 0.1, 0.3, 0.1), "l112_orange", GeoKit.ALL, false)
		# balconies on the courtyard face
		if side == balcony_side and detail:
			for b in range(1, bays, 3):
				var u := -LENGTH * 0.5 + BAY * (b + 0.5)
				if _near_core(u):
					continue
				for f in range(1, FLOORS):
					var y := f * STOREY
					var p := face + t * u + n * 0.65 + Vector3(0, y, 0)
					k.box(p, _sz(t, n, 3.0, 0.16, 1.3), "l112_white", GeoKit.ALL, false)
					k.box(p + n * 0.6 + Vector3(0, 0.55, 0), _sz(t, n, 3.0, 0.95, 0.08), "l112_orange", GeoKit.ALL, false)
					k.box(p + Vector3(0, 0.1, 0), _sz(t, n, 2.9, 0.06, 1.2), "l112_snow", GeoKit.PY, false)
		# entrance canopies and doors at the three cores (ground floor)
		if solid_from < 0.1:
			for i in 3:
				var off := (float(i) - 1.0) * 21.0
				var dp := face + t * off + n * 0.06
				k.box(dp + Vector3(0, 1.1, 0), _sz(t, n, 1.6, 2.2, 0.1), "l112_door", GeoKit.ALL, false)
				k.box(dp + n * 0.9 + Vector3(0, 2.6, 0), _sz(t, n, 2.8, 0.15, 1.8), "l112_concrete", GeoKit.ALL, false)
				k.box(dp + n * 0.9 + Vector3(0, 2.69, 0), _sz(t, n, 2.7, 0.05, 1.7), "l112_snow", GeoKit.PY, false)
				if r.randf() < barricade + 0.2:
					k.box(dp + n * 0.18 + Vector3(0, 1.1, 0), _sz(t, n, 1.9, 2.3, 0.08), "l112_blackmetal", GeoKit.ALL, false)
	# snow drift skirt along the base
	k.box(c + Vector3(0, 0.12, 0), (Vector3(LENGTH + 1.4, 0.24, DEPTH + 1.4) if axis_x else Vector3(DEPTH + 1.4, 0.24, LENGTH + 1.4)), "l112_snow", GeoKit.PY | GeoKit.SIDES, false)


func _near_core(u: float) -> bool:
	for i in 3:
		if absf(u - (float(i) - 1.0) * 21.0) < 2.4:
			return true
	return false


static func _sz(t: Vector3, n: Vector3, along: float, up: float, out: float) -> Vector3:
	return Vector3(absf(t.x) * along + absf(n.x) * out, up, absf(t.z) * along + absf(n.z) * out)


# ------------------------------------------------------------- banner building

func banner_building(k: GeoKit, c: Vector3) -> void:
	var w := 26.0
	var d := 16.0
	var h := 12.4
	k.box(c + Vector3(0, h * 0.5, 0), Vector3(w, h, d), "l112_banner_base")
	k.box(c + Vector3(0, h + 0.4, 0), Vector3(w + 0.4, 0.8, d + 0.4), "l112_bb_navy", GeoKit.ALL, false)
	k.box(c + Vector3(0, h + 0.85, 0), Vector3(w, 0.1, d), "l112_snow", GeoKit.PY, false)
	# painted geometric shapes
	var cols := ["l112_bb_red", "l112_bb_yellow", "l112_bb_teal", "l112_bb_navy", "l112_bb_green", "l112_bb_pink"]
	var rr := RandomNumberGenerator.new()
	rr.seed = 1102
	for side in [-1.0, 1.0]:
		for i in 9:
			var x := rr.randf_range(-w * 0.45, w * 0.45)
			var y := rr.randf_range(4.0, h - 1.5)
			var s := rr.randf_range(0.8, 2.4)
			var mat: String = cols[rr.randi() % cols.size()]
			var ang := rr.randf_range(0.0, PI)
			var xf := Transform3D(Basis(Vector3.BACK, ang), c + Vector3(x, y, side * (d * 0.5 + 0.03)))
			k.box_xf(xf, Vector3(s, s * rr.randf_range(0.4, 1.0), 0.04), mat, GeoKit.ALL, false)
		for e in [-1.0, 1.0]:
			for i in 3:
				var z := rr.randf_range(-d * 0.4, d * 0.4)
				var y := rr.randf_range(4.0, h - 2.0)
				var s := rr.randf_range(0.8, 2.0)
				var xf := Transform3D(Basis(Vector3.RIGHT, rr.randf_range(0, PI)), c + Vector3(e * (w * 0.5 + 0.03), y, z))
				k.box_xf(xf, Vector3(0.04, s, s * 0.7), cols[rr.randi() % cols.size()], GeoKit.ALL, false)
	# banners painted as if hanging from the roof (long tapered strips)
	for side in [-1.0, 1.0]:
		for i in 6:
			var x := -w * 0.5 + 2.4 + i * (w - 4.8) / 5.0
			var mat: String = cols[(i + (0 if side > 0 else 3)) % cols.size()]
			var length := 5.0 + (i % 3) * 1.4
			k.box(c + Vector3(x, h - length * 0.5, side * (d * 0.5 + 0.06)), Vector3(1.5, length, 0.03), mat, GeoKit.ALL, false)
			var tri := Transform3D(Basis(Vector3.BACK, PI * 0.25), c + Vector3(x, h - length, side * (d * 0.5 + 0.06)))
			k.box_xf(tri, Vector3(1.06, 1.06, 0.03), mat, GeoKit.ALL, false)
	# the lit hall: a long glazed band on the south face (ground floor)
	k.box(c + Vector3(0, 1.9, d * 0.5 + 0.02), Vector3(w - 4.0, 2.4, 0.04), "l112_bb_hall", GeoKit.ALL, false)
	k.box(c + Vector3(0, 1.9, -d * 0.5 - 0.02), Vector3(w - 8.0, 2.4, 0.04), "l112_bb_hall", GeoKit.ALL, false)
	for i in 7:
		var x := -w * 0.5 + 2.0 + i * (w - 4.0) / 6.0
		k.box(c + Vector3(x, 1.9, d * 0.5 + 0.06), Vector3(0.18, 2.5, 0.06), "l112_bb_navy", GeoKit.ALL, false)
	# the removed outer barricade: black metal casing panels stacked nearby
	for i in 5:
		var p := c + Vector3(-w * 0.5 - 3.0, 0.1 + i * 0.09, d * 0.5 - 2.0 - i * 0.15)
		k.box(p, Vector3(2.2, 0.08, 1.8), "l112_blackmetal", GeoKit.ALL, i == 0)
	for i in 3:
		var xf := Transform3D(Basis(Vector3.BACK, 0.25 + i * 0.03), c + Vector3(w * 0.5 + 1.2 + i * 0.25, 1.1, 2.0 - i * 2.2))
		k.box_xf(xf, Vector3(0.08, 2.4, 1.9), "l112_blackmetal", GeoKit.ALL, true)


# ------------------------------------------------------------- tents

func tent(k: GeoKit, c: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var w := 3.6
	var l := 5.0
	var ridge := 2.4
	for side in [-1.0, 1.0]:
		var ang: float = atan2(ridge - 0.8, w * 0.5) * side
		var xf := Transform3D(bas * Basis(Vector3.FORWARD, ang), c + bas * Vector3(side * w * 0.25, (ridge + 0.8) * 0.5, 0))
		k.box_xf(xf, Vector3(sqrt(pow(w * 0.5, 2) + pow(ridge - 0.8, 2)) + 0.1, 0.05, l), "l112_tent", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, c + bas * Vector3(side * w * 0.5, 0.4, 0)), Vector3(0.05, 0.8, l), "l112_tent", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + bas * Vector3(0, ridge + 0.02, 0)), Vector3(0.3, 0.06, l + 0.1), "l112_snow", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + bas * Vector3(0, 1.0, -l * 0.5)), Vector3(w * 0.7, 2.0, 0.05), "l112_tent", GeoKit.ALL, false)
	# collision: one box for the whole tent body
	k.add_box_shape(Transform3D(bas, c + bas * Vector3(0, 0.9, 0)), Vector3(w, 1.8, l), "concrete")


# ------------------------------------------------------------- approach road

## Small, vacant Level 11 buildings that grow taller with distance from the
## estate (the blending zone): z from 64 to 200 along the road at x = 20.
func approach(k: GeoKit, road_x: float) -> Array:
	var placed: Array = []
	var z := 62.0
	while z < 236.0:
		var t := smoothstep(60.0, 220.0, z)
		for side in [-1.0, 1.0]:
			var w := lerpf(5.0, 16.0, t) + r.randf_range(-1.0, 2.0)
			var dd := lerpf(5.0, 14.0, t)
			var floors := int(round(lerpf(1.0, 6.0, t) + r.randf_range(-0.4, 0.6)))
			var hh := maxf(1, floors) * 3.2
			var x: float = road_x + side * (10.6 + dd * 0.5)
			var mat := "l112_l11_grey" if r.randf() < 0.6 else "l112_l11_brick"
			k.box(Vector3(x, hh * 0.5, z), Vector3(dd, hh, w), mat)
			k.box(Vector3(x, hh + 0.05, z), Vector3(dd + 0.1, 0.1, w + 0.1), "l112_snow", GeoKit.PY, false)
			# dark, empty windows facing the road
			for f in maxi(1, floors):
				var nwin := int(w / 2.6)
				for i in nwin:
					var wz := z - w * 0.5 + (i + 0.5) * w / nwin
					k.box(Vector3(x - side * (dd * 0.5 + 0.02), f * 3.2 + 1.6, wz), Vector3(0.04, 1.3, 1.2), "l112_win_dark", GeoKit.ALL, false)
			placed.append(Vector3(x, 0, z))
		z += lerpf(9.0, 20.0, t) + 4.0
	# a low barricade line of black sheet metal on both kerbs: the road is the way
	for side in [-1.0, 1.0]:
		var fz := 60.0
		while fz < 236.0:
			var tilt := r.randf_range(-0.06, 0.06)
			k.box_xf(Transform3D(Basis(Vector3.BACK, tilt), Vector3(road_x + side * 9.3, 0.7, fz + 1.5)), Vector3(0.06, 1.4, 2.96), "l112_blackmetal", GeoKit.ALL, true)
			k.box(Vector3(road_x + side * 9.36, 0.75, fz), Vector3(0.1, 1.5, 0.1), "l112_steel", GeoKit.ALL, false)
			fz += 3.0
	return placed
