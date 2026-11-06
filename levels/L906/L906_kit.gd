extends RefCounted
## Level 906 kit: materials and the furniture vocabulary of the Cygnus Archive.
## Everything sits on one global shelf lattice (PITCH) so that real shelf boards
## line up with the book-spine shader on every bookcase, floating ones included.
## Page facts used here: wooden shelves full of books in many languages; wooden
## floor with blue velvet carpets with golden ornaments; candelabras hanging from
## the impossibly high ceiling; wooden ladders; gothic / victorian / baroque
## decoration. Proportions and joinery are ADAPTATION.

const S := preload("res://levels/L906/L906_shaders.gd")
const PITCH := 0.375
const GAL := 4.5          # gallery floor (12 shelf rows above the floor)
const CHAIN_TOP := 140.0


static func materials() -> void:
	MatLib.define("l906_wood", {"albedo_a": Color(0.2, 0.11, 0.055), "albedo_b": Color(0.14, 0.075, 0.04),
		"pattern": 3, "pattern_scale": Vector2(2.4, 0.3), "grout_width": 0.004, "grout_color": Color(0.06, 0.03, 0.015),
		"tile_variation": 0.08, "noise_scale": 2.6, "roughness_a": 0.42, "roughness_b": 0.62, "bump_strength": 0.35})
	MatLib.define("l906_panel", {"albedo_a": Color(0.13, 0.07, 0.036), "albedo_b": Color(0.095, 0.05, 0.026),
		"pattern": 1, "pattern_scale": Vector2(1.6, 2.4), "grout_width": 0.035, "grout_color": Color(0.06, 0.03, 0.015),
		"tile_variation": 0.015, "noise_scale": 2.0, "roughness_a": 0.45, "roughness_b": 0.65, "bump_strength": 0.6})
	MatLib.define("l906_carpet", {"albedo_a": Color(0.07, 0.11, 0.34), "albedo_b": Color(0.045, 0.075, 0.25),
		"pattern": 6, "pattern_scale": Vector2(0.62, 0.62), "pattern_color": Color(0.78, 0.6, 0.22),
		"pattern_strength": 0.6, "noise_scale": 0.6, "bump_strength": 0.5})
	MatLib.define("l906_carpet_rug", {"albedo_a": Color(0.06, 0.09, 0.3), "albedo_b": Color(0.04, 0.06, 0.22),
		"pattern": 6, "pattern_scale": Vector2(0.34, 0.34), "pattern_color": Color(0.66, 0.5, 0.18),
		"pattern_strength": 0.55, "noise_scale": 0.6, "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l906_carpet_edge", {"albedo_a": Color(0.7, 0.52, 0.18), "albedo_b": Color(0.56, 0.4, 0.13),
		"pattern": 2, "pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.32, 0.2, 0.06),
		"pattern_strength": 0.5, "roughness_a": 0.9, "roughness_b": 1.0})
	MatLib.define("l906_gilt", {"albedo_a": Color(0.74, 0.56, 0.22), "albedo_b": Color(0.55, 0.4, 0.14),
		"metallic_value": 0.85, "roughness_a": 0.28, "roughness_b": 0.48, "noise_scale": 5.0})
	MatLib.define("l906_brass", {"albedo_a": Color(0.42, 0.3, 0.12), "albedo_b": Color(0.26, 0.18, 0.07),
		"metallic_value": 0.8, "roughness_a": 0.35, "roughness_b": 0.6, "noise_scale": 4.0})
	MatLib.define("l906_marble", {"albedo_a": Color(0.86, 0.84, 0.8), "albedo_b": Color(0.72, 0.7, 0.66),
		"pattern": 11, "pattern_color": Color(0.58, 0.55, 0.52), "pattern_strength": 0.35, "noise_scale": 1.4,
		"roughness_a": 0.18, "roughness_b": 0.3, "bump_strength": 0.15})
	MatLib.define("l906_damask", {"albedo_a": Color(0.2, 0.035, 0.03), "albedo_b": Color(0.15, 0.025, 0.02),
		"pattern": 10, "pattern_scale": Vector2(0.42, 0.56), "pattern_color": Color(0.46, 0.12, 0.08),
		"pattern_strength": 0.55, "roughness_a": 0.8, "roughness_b": 0.9})
	MatLib.define("l906_tea_wall", {"albedo_a": Color(0.13, 0.22, 0.16), "albedo_b": Color(0.1, 0.18, 0.13),
		"pattern": 10, "pattern_scale": Vector2(0.36, 0.48), "pattern_color": Color(0.62, 0.55, 0.32),
		"pattern_strength": 0.4, "roughness_a": 0.8, "roughness_b": 0.9})
	MatLib.define("l906_tea_tile", {"albedo_a": Color(0.38, 0.33, 0.26), "albedo_b": Color(0.33, 0.29, 0.22),
		"pattern": 9, "pattern_scale": Vector2(0.16, 0.16), "pattern_color": Color(0.2, 0.07, 0.04), "pattern_strength": 0.45,
		"grout_width": 0.006, "grout_color": Color(0.4, 0.38, 0.33), "roughness_a": 0.3, "roughness_b": 0.45})
	MatLib.define("l906_tin", {"albedo_a": Color(0.78, 0.74, 0.62), "albedo_b": Color(0.68, 0.64, 0.52),
		"pattern": 10, "pattern_scale": Vector2(0.6, 0.6), "pattern_color": Color(0.58, 0.54, 0.42),
		"pattern_strength": 0.5, "metallic_value": 0.3, "roughness_a": 0.4, "roughness_b": 0.6})
	MatLib.define("l906_iron", {"albedo_a": Color(0.07, 0.07, 0.075), "albedo_b": Color(0.04, 0.04, 0.045),
		"metallic_value": 0.6, "roughness_a": 0.45, "roughness_b": 0.7, "noise_scale": 3.0})
	MatLib.define("l906_porcelain", {"albedo_a": Color(0.93, 0.92, 0.88), "albedo_b": Color(0.88, 0.87, 0.83),
		"roughness_a": 0.12, "roughness_b": 0.2, "bump_strength": 0.0})
	MatLib.define("l906_silver", {"albedo_a": Color(0.78, 0.78, 0.8), "albedo_b": Color(0.62, 0.62, 0.64),
		"metallic_value": 0.95, "roughness_a": 0.2, "roughness_b": 0.35})
	MatLib.define("l906_linen", {"albedo_a": Color(0.86, 0.83, 0.76), "albedo_b": Color(0.78, 0.75, 0.68),
		"pattern": 2, "pattern_scale": Vector2(0.02, 1.0), "pattern_color": Color(0.8, 0.77, 0.7), "pattern_strength": 0.2,
		"roughness_a": 0.95, "roughness_b": 1.0})
	MatLib.define("l906_velvet", {"albedo_a": Color(0.1, 0.13, 0.36), "albedo_b": Color(0.06, 0.08, 0.24),
		"noise_scale": 3.0, "roughness_a": 0.85, "roughness_b": 1.0})
	MatLib.define("l906_wax", {"albedo_a": Color(0.92, 0.88, 0.76), "albedo_b": Color(0.85, 0.8, 0.66),
		"roughness_a": 0.5, "roughness_b": 0.6, "emission_color": Color(0.5, 0.35, 0.15), "emission_energy": 0.25})
	MatLib.define("l906_cloth", {"albedo_a": Color(0.9, 0.88, 0.82), "albedo_b": Color(0.84, 0.82, 0.76),
		"pattern": 5, "pattern_scale": Vector2(0.08, 0.08), "pattern_color": Color(0.8, 0.76, 0.66), "pattern_strength": 0.3})
	MatLib.define("l906_plush", {"albedo_a": Color(0.36, 0.31, 0.26), "albedo_b": Color(0.29, 0.25, 0.21),
		"noise_scale": 9.0, "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.0})
	MatLib.define("l906_gown", {"albedo_a": Color(0.4, 0.54, 0.8), "albedo_b": Color(0.34, 0.47, 0.72), "noise_scale": 6.0,
		"pattern": 2, "pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.55, 0.66, 0.88), "pattern_strength": 0.3,
		"roughness_a": 0.55, "roughness_b": 0.75, "bump_strength": 0.2})
	MatLib.define("l906_lace", {"albedo_a": Color(0.95, 0.94, 0.92), "albedo_b": Color(0.86, 0.85, 0.83), "pattern": 5,
		"pattern_scale": Vector2(0.02, 0.02), "pattern_color": Color(0.75, 0.74, 0.72), "pattern_strength": 0.5})
	MatLib.define("l906_skin", {"albedo_a": Color(0.95, 0.86, 0.8), "albedo_b": Color(0.92, 0.82, 0.76), "noise_scale": 3.0,
		"roughness_a": 0.6, "roughness_b": 0.7, "bump_strength": 0.0})
	MatLib.define("l906_hair", {"albedo_a": Color(0.88, 0.74, 0.44), "albedo_b": Color(0.74, 0.58, 0.3), "pattern": 2,
		"pattern_scale": Vector2(0.012, 1.0), "pattern_color": Color(0.95, 0.84, 0.56), "pattern_strength": 0.5,
		"roughness_a": 0.45, "roughness_b": 0.6})
	MatLib.define("l906_eye", {"albedo_a": Color(0.5, 0.74, 0.95), "albedo_b": Color(0.45, 0.7, 0.92), "roughness_a": 0.1, "roughness_b": 0.1})
	MatLib.register("l906_flame", MatLib.panel(Color(1.0, 0.72, 0.36), 7.0, 0.15))
	MatLib.register("l906_books", S.mat(S.BOOKS, {"pitch": PITCH}))
	MatLib.register("l906_ceiling", S.mat(S.CEILING, {"cell": 9.0, "glow": 1.0}))
	MatLib.register("l906_painting", S.mat(S.PAINTING, {"mode": 0, "seed": 1.3}))
	MatLib.register("l906_painting2", S.mat(S.PAINTING, {"mode": 0, "seed": 4.1}))
	MatLib.register("l906_portrait", S.mat(S.PAINTING, {"mode": 1}))


## A run of shelving between `a` and `b` (axis-aligned floor points, same y).
## `front` is the unit normal of the book face; double=true puts books on both
## faces. Height is snapped to whole shelf rows. Returns the top height.
static func shelves(k: GeoKit, a: Vector3, b: Vector3, depth: float, rows: int, front: Vector3, double: bool = false, cornice := true) -> float:
	var along := (b - a)
	var length := along.length()
	if length < 0.2:
		return a.y
	var ax := along / length
	var h := rows * PITCH
	var y0 := a.y
	var c := (a + b) * 0.5
	var size := ax.abs() * length + front.abs() * depth + Vector3.UP * h
	var face := GeoKit.PX if front.x > 0.5 else (GeoKit.NX if front.x < -0.5 else (GeoKit.PZ if front.z > 0.5 else GeoKit.NZ))
	var back := GeoKit.NX if face == GeoKit.PX else (GeoKit.PX if face == GeoKit.NX else (GeoKit.NZ if face == GeoKit.PZ else GeoKit.PZ))
	# book block (collision for the whole case) and the carcass behind
	k.box(c + Vector3.UP * (h * 0.5), size - front.abs() * 0.04, "l906_books", face | (back if double else 0))
	if not double:
		k.box(c + Vector3.UP * (h * 0.5) - front * 0.02, size - front.abs() * 0.04 + Vector3(0.001, 0, 0.001), "l906_wood", back, false)
	# real shelf boards on the lattice, slightly proud of the spines
	for r in rows + 1:
		var yb := y0 + r * PITCH
		k.box(Vector3(c.x, yb + 0.015, c.z) + (Vector3.ZERO if double else front * 0.01),
			ax.abs() * length + front.abs() * (depth + (0.02 if double else 0.0)) + Vector3.UP * 0.03, "l906_wood",
			GeoKit.PY | GeoKit.NY | face | (back if double else 0), false)
	# uprights every ~1.2 m and at both ends
	var n := maxi(1, int(round(length / 1.2)))
	for i in n + 1:
		var p := a + ax * (length * i / n)
		k.box(p + Vector3.UP * (h * 0.5), ax.abs() * 0.07 + front.abs() * (depth + 0.03) + Vector3.UP * h, "l906_wood",
			GeoKit.ALL ^ GeoKit.NY, false)
	if cornice:
		k.box(c + Vector3.UP * (h + 0.09), ax.abs() * (length + 0.14) + front.abs() * (depth + 0.12) + Vector3.UP * 0.18, "l906_wood", GeoKit.ALL ^ GeoKit.NY, false)
		k.box(c + Vector3.UP * (h + 0.05) + front * (depth * 0.5 + 0.065), ax.abs() * (length + 0.14) + front.abs() * 0.01 + Vector3.UP * 0.035, "l906_gilt", face, false)
		if double:
			k.box(c + Vector3.UP * (h + 0.05) - front * (depth * 0.5 + 0.065), ax.abs() * (length + 0.14) + front.abs() * 0.01 + Vector3.UP * 0.035, "l906_gilt", back, false)
	return y0 + h


## Turned column with a gilt capital, from y0 to y1.
static func column(k: GeoKit, p: Vector3, y1: float, r: float, mat := "l906_wood") -> void:
	k.box(Vector3(p.x, p.y + 0.12, p.z), Vector3(r * 2.6, 0.24, r * 2.6), mat)
	k.cylinder(Vector3(p.x, (p.y + y1) * 0.5, p.z), r, y1 - p.y - 0.5, mat, 10)
	k.box(Vector3(p.x, y1 - 0.2, p.z), Vector3(r * 2.4, 0.16, r * 2.4), "l906_gilt", GeoKit.ALL, false)
	k.box(Vector3(p.x, y1 - 0.06, p.z), Vector3(r * 3.0, 0.12, r * 3.0), mat, GeoKit.ALL, false)


## Balustrade along an axis-aligned line at floor height a.y (collides as a rail).
static func rail(k: GeoKit, a: Vector3, b: Vector3, mat := "l906_wood", h := 1.0) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.1:
		return
	var ax := d / length
	var side := Vector3.UP.cross(ax).abs()
	var c := (a + b) * 0.5
	k.box(c + Vector3.UP * (h - 0.04), ax.abs() * length + side * 0.12 + Vector3.UP * 0.08, mat, GeoKit.ALL, false)
	k.box(c + Vector3.UP * 0.06, ax.abs() * length + side * 0.1 + Vector3.UP * 0.12, mat, GeoKit.ALL, false)
	var n := int(length / 0.22)
	for i in n:
		var p := a + ax * ((i + 0.5) * length / n)
		k.box(p + Vector3.UP * (h * 0.5), Vector3(0.045, h - 0.2, 0.045), mat, GeoKit.SIDES, false)
	k.add_box_shape(Transform3D(Basis(), c + Vector3.UP * (h * 0.5 + 0.1)), ax.abs() * length + side * 0.1 + Vector3.UP * (h + 0.2), "wood")


## Hanging candelabra: rings of candles on brass arms, chain up into the dark.
## Returns the light position.
static func candelabra(k: GeoKit, p: Vector3, r: float, candles: int, tiers: int = 2, top := CHAIN_TOP) -> Vector3:
	k.box(Vector3(p.x, (p.y + top) * 0.5, p.z), Vector3(0.035, top - p.y, 0.035), "l906_brass", GeoKit.SIDES, false)
	k.cylinder(p + Vector3.DOWN * 0.3, 0.07, 1.1, "l906_brass", 8, false)
	k.cylinder(p + Vector3.DOWN * 0.95, 0.16, 0.22, "l906_gilt", 8, false)
	for t in tiers:
		var rr := r * (1.0 - 0.38 * t)
		var y := p.y - 0.7 + 0.55 * t
		var n := maxi(5, candles - t * 4)
		for i in n:
			var a := TAU * (i + 0.5 * t) / n
			var q := Vector3(p.x + cos(a) * rr, y, p.z + sin(a) * rr)
			var a2 := TAU * (i + 1 + 0.5 * t) / n
			var q2 := Vector3(p.x + cos(a2) * rr, y, p.z + sin(a2) * rr)
			var mid := (q + q2) * 0.5
			var bas := Basis(Vector3.UP, -atan2(q2.z - q.z, q2.x - q.x))
			k.box_xf(Transform3D(bas, mid), Vector3(q.distance_to(q2) + 0.02, 0.035, 0.035), "l906_brass", GeoKit.ALL, false)
			k.box_xf(Transform3D(Basis(Vector3.UP, -a), Vector3(p.x + cos(a) * rr * 0.5, y - 0.04, p.z + sin(a) * rr * 0.5)), Vector3(rr, 0.025, 0.025), "l906_brass", GeoKit.ALL, false)
			k.cylinder(q + Vector3.UP * 0.04, 0.05, 0.03, "l906_gilt", 6, false)
			k.cylinder(q + Vector3.UP * 0.17, 0.022, 0.24, "l906_wax", 6, false)
			k.box(q + Vector3.UP * 0.33, Vector3(0.022, 0.06, 0.022), "l906_flame", GeoKit.ALL, false)
	return p + Vector3.DOWN * 0.4


## Standing / table candlestick with n candles.
static func candlestick(k: GeoKit, p: Vector3, n: int = 3, h: float = 0.35) -> void:
	k.cylinder(p + Vector3.UP * 0.015, 0.07, 0.03, "l906_brass", 8, false)
	k.cylinder(p + Vector3.UP * (h * 0.5), 0.015, h, "l906_brass", 6, false)
	for i in n:
		var off := Vector3((i - (n - 1) * 0.5) * 0.11, 0, 0)
		if i > 0 and i < n - 1:
			off.y = 0.04
		k.box(p + off * Vector3(1, 0, 1) + Vector3.UP * h, Vector3(absf(off.x) * 2.0 + 0.02, 0.015, 0.015), "l906_brass", GeoKit.ALL, false)
		k.cylinder(p + off + Vector3.UP * (h + 0.08), 0.014, 0.16, "l906_wax", 6, false)
		k.box(p + off + Vector3.UP * (h + 0.19), Vector3(0.016, 0.04, 0.016), "l906_flame", GeoKit.ALL, false)


## Wooden ladder from foot to top (centre line); `side` is the horizontal rung
## axis (perpendicular to the lean).
static func ladder(k: GeoKit, foot: Vector3, top: Vector3, side: Vector3, width := 0.5) -> void:
	var d := top - foot
	var length := d.length()
	var z := d / length
	var x := side
	var y := z.cross(x).normalized()
	for s: float in [-1.0, 1.0]:
		var c := (foot + top) * 0.5 + side * (width * 0.5 * s)
		k.box_xf(Transform3D(Basis(x, y, z).orthonormalized(), c), Vector3(0.06, 0.035, length), "l906_wood", GeoKit.ALL, false)
	var n := int(length / 0.3)
	for i in range(1, n + 1):
		var p := foot + z * (i * 0.3)
		k.box(p, side.abs() * width + Vector3(0.03, 0.03, 0.03), "l906_wood", GeoKit.ALL, false)


static func table(k: GeoKit, c: Vector3, sx: float, sz: float, h := 0.76, mat := "l906_wood") -> void:
	k.box(c + Vector3.UP * (h - 0.025), Vector3(sx, 0.05, sz), mat)
	k.box(c + Vector3.UP * (h - 0.09), Vector3(sx - 0.1, 0.08, sz - 0.1), mat, GeoKit.SIDES, false)
	for i in 4:
		var lx := (sx * 0.5 - 0.07) * (1.0 if i % 2 == 0 else -1.0)
		var lz := (sz * 0.5 - 0.07) * (1.0 if i < 2 else -1.0)
		k.box(c + Vector3(lx, (h - 0.05) * 0.5, lz), Vector3(0.06, h - 0.05, 0.06), mat, GeoKit.SIDES, false)


static func chair(k: GeoKit, c: Vector3, facing: Vector3, seat := "l906_velvet") -> void:
	var f := facing.normalized()
	var s := Vector3.UP.cross(f).normalized()
	var bas := Basis(s, Vector3.UP, f)
	k.box_xf(Transform3D(bas, c + Vector3.UP * 0.45), Vector3(0.46, 0.08, 0.46), seat, GeoKit.ALL, true)
	k.box_xf(Transform3D(bas, c + Vector3.UP * 0.75 - f * 0.21), Vector3(0.44, 0.6, 0.05), seat)
	k.box_xf(Transform3D(bas, c + Vector3.UP * 1.08 - f * 0.21), Vector3(0.48, 0.06, 0.07), "l906_wood", GeoKit.ALL, false)
	for i in 4:
		var o := s * (0.19 * (1.0 if i % 2 == 0 else -1.0)) + f * (0.19 * (1.0 if i < 2 else -1.0))
		k.box(c + o + Vector3.UP * 0.21, Vector3(0.045, 0.42, 0.045), "l906_wood", GeoKit.SIDES, false)


## A loose stack of books (no collision), for floors and tables.
static func stack(k: GeoKit, p: Vector3, r: RandomNumberGenerator, n: int) -> void:
	var y := p.y
	for i in n:
		var w := r.randf_range(0.15, 0.24)
		var d := r.randf_range(0.2, 0.3)
		var t := r.randf_range(0.03, 0.06)
		var bas := Basis(Vector3.UP, r.randf_range(-0.4, 0.4))
		k.box_xf(Transform3D(bas, Vector3(p.x, y + t * 0.5, p.z)), Vector3(w, t, d), "l906_books", GeoKit.ALL, false)
		y += t


## Framed canvas on a wall: centre, outward normal, width, height.
static func painting(k: GeoKit, c: Vector3, n: Vector3, w: float, h: float, mat: String) -> void:
	var s := Vector3.UP.cross(n).normalized()
	k.quad(c + n * 0.035, n, s * (w * 0.5), Vector3.UP * (h * 0.5), mat, Vector2.ZERO, true)
	for e in [[s * (w * 0.5 + 0.06), Vector3(0.12, h + 0.24, 0.07)], [-s * (w * 0.5 + 0.06), Vector3(0.12, h + 0.24, 0.07)],
			[Vector3.UP * (h * 0.5 + 0.06), Vector3(w, 0.12, 0.07)], [Vector3.DOWN * (h * 0.5 + 0.06), Vector3(w, 0.12, 0.07)]]:
		var sz: Vector3 = e[1]
		var sz2 := s.abs() * sz.x + Vector3.UP * sz.y + n.abs() * sz.z
		k.box(c + (e[0] as Vector3) + n * 0.035, sz2, "l906_gilt", GeoKit.ALL, false)
