extends RefCounted
## Level 41 structures: raised boardwalks (concrete or steel feet, wooden legs
## and walkways, 2-6 m above the ground), the group-built ladders, burnt and
## sunken pier remains, and the four standout exit objects (barn door on a
## stone plinth, lighthouse gallery, navy vessel bridge, inverted shuttle).

const W := 2.0               # walkway width

var lvl
var land
var ladders: Array = []      # {base: Vector3, top: Vector3, out: Vector3}
var rail_open: Array = []    # Vector2 points where rails are left open
var pier_lines: Array = []   # [Vector3...] per pier (for proximity tests)
var burning: Array = []      # Vector3 points on burning wood


func _init(level, land_model) -> void:
	lvl = level
	land = land_model


static func materials() -> void:
	MatLib.define("l41_plank", {"albedo_a": Color(0.36, 0.31, 0.25), "albedo_b": Color(0.25, 0.21, 0.17), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.16), "grout_width": 0.01, "grout_color": Color(0.06, 0.05, 0.04),
		"roughness_a": 0.85, "roughness_b": 0.98, "stain_amount": 0.45, "stain_color": Color(0.12, 0.1, 0.08),
		"grime_height": 0.4, "grime_color": Color(0.05, 0.045, 0.04), "bump_strength": 1.0}, "wood_floor")
	MatLib.define("l41_beam", {"albedo_a": Color(0.27, 0.23, 0.19), "albedo_b": Color(0.19, 0.16, 0.13), "noise_scale": 3.0,
		"roughness_a": 0.9, "roughness_b": 1.0, "stain_amount": 0.5, "stain_color": Color(0.08, 0.07, 0.06), "bump_strength": 1.2}, "wood_floor")
	MatLib.define("l41_char", {"albedo_a": Color(0.035, 0.03, 0.028), "albedo_b": Color(0.07, 0.06, 0.05), "pattern": 1,
		"pattern_scale": Vector2(0.09, 0.05), "grout_color": Color(0.01, 0.01, 0.01), "grout_width": 0.008,
		"roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 1.6, "emission_color": Color(0.5, 0.12, 0.02), "emission_energy": 0.0}, "plaster")
	MatLib.define("l41_ember", {"albedo_a": Color(0.04, 0.03, 0.03), "albedo_b": Color(0.08, 0.05, 0.03), "pattern": 1,
		"pattern_scale": Vector2(0.09, 0.05), "grout_color": Color(1.0, 0.35, 0.05), "grout_width": 0.01,
		"roughness_a": 0.9, "emission_color": Color(1.0, 0.3, 0.04), "emission_energy": 0.8, "bump_strength": 1.6}, "plaster")
	MatLib.define("l41_concrete", {"albedo_a": Color(0.42, 0.41, 0.39), "albedo_b": Color(0.33, 0.32, 0.3), "noise_scale": 1.8,
		"stain_amount": 0.35, "stain_color": Color(0.2, 0.19, 0.17), "grime_height": 1.4, "grime_color": Color(0.03, 0.025, 0.02),
		"roughness_a": 0.9, "roughness_b": 0.98, "bump_strength": 1.0}, "concrete")
	MatLib.define("l41_steel", {"albedo_a": Color(0.3, 0.31, 0.32), "albedo_b": Color(0.22, 0.17, 0.12), "metallic_value": 0.6,
		"roughness_a": 0.55, "roughness_b": 0.85, "noise_scale": 2.5, "stain_amount": 0.55, "stain_color": Color(0.32, 0.16, 0.07),
		"grime_height": 1.2, "grime_color": Color(0.03, 0.025, 0.02), "bump_strength": 1.0}, "metal")
	MatLib.define("l41_navy", {"albedo_a": Color(0.36, 0.38, 0.4), "albedo_b": Color(0.3, 0.32, 0.34), "metallic_value": 0.35,
		"roughness_a": 0.6, "roughness_b": 0.8, "noise_scale": 1.4, "stain_amount": 0.5, "stain_color": Color(0.33, 0.17, 0.08),
		"grime_height": 2.0, "grime_color": Color(0.02, 0.018, 0.016), "bump_strength": 0.5}, "metal")
	MatLib.define("l41_stone", {"albedo_a": Color(0.42, 0.4, 0.37), "albedo_b": Color(0.33, 0.31, 0.29), "pattern": 4,
		"pattern_scale": Vector2(0.62, 0.32), "grout_width": 0.02, "grout_color": Color(0.16, 0.15, 0.14),
		"roughness_a": 0.9, "roughness_b": 1.0, "stain_amount": 0.35, "stain_color": Color(0.2, 0.18, 0.16),
		"grime_height": 0.6, "grime_color": Color(0.05, 0.045, 0.04), "bump_strength": 1.4}, "rock")
	MatLib.define("l41_barn", {"albedo_a": Color(0.4, 0.07, 0.05), "albedo_b": Color(0.3, 0.05, 0.04), "pattern": 3, "uv_rotate": 1.5708,
		"pattern_scale": Vector2(2.4, 0.18), "grout_width": 0.008, "grout_color": Color(0.1, 0.03, 0.02),
		"roughness_a": 0.85, "roughness_b": 0.95, "stain_amount": 0.4, "stain_color": Color(0.2, 0.08, 0.05), "peel_amount": 0.3}, "wood_floor")
	MatLib.define("l41_white", {"albedo_a": Color(0.78, 0.76, 0.72), "albedo_b": Color(0.66, 0.64, 0.6), "noise_scale": 2.0,
		"stain_amount": 0.5, "stain_color": Color(0.32, 0.3, 0.27), "grime_height": 1.5, "grime_color": Color(0.04, 0.035, 0.03),
		"roughness_a": 0.7, "roughness_b": 0.9}, "plaster")
	MatLib.define("l41_red", {"albedo_a": Color(0.42, 0.06, 0.04), "albedo_b": Color(0.32, 0.05, 0.035), "noise_scale": 2.0,
		"stain_amount": 0.4, "stain_color": Color(0.15, 0.06, 0.04), "roughness_a": 0.7}, "plaster")
	MatLib.define("l41_orange", {"albedo_a": Color(0.5, 0.2, 0.06), "albedo_b": Color(0.38, 0.14, 0.04), "noise_scale": 5.0,
		"stain_amount": 0.55, "stain_color": Color(0.12, 0.06, 0.03), "grime_height": 2.5, "grime_color": Color(0.02, 0.015, 0.01),
		"roughness_a": 0.85, "bump_strength": 1.3}, "plaster")
	MatLib.define("l41_tiles_black", {"albedo_a": Color(0.03, 0.03, 0.032), "albedo_b": Color(0.05, 0.05, 0.05), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_color": Color(0.12, 0.12, 0.12), "grout_width": 0.008, "tile_variation": 0.25,
		"roughness_a": 0.85}, "plaster")
	MatLib.define("l41_nozzle", {"albedo_a": Color(0.16, 0.15, 0.14), "albedo_b": Color(0.08, 0.075, 0.07), "metallic_value": 0.7,
		"roughness_a": 0.5, "roughness_b": 0.7, "stain_amount": 0.6, "stain_color": Color(0.3, 0.2, 0.12), "noise_scale": 3.0}, "metal")
	MatLib.define("l41_roof_tile", {"albedo_a": Color(0.36, 0.14, 0.08), "albedo_b": Color(0.28, 0.1, 0.06), "pattern": 14,
		"pattern_scale": Vector2(0.3, 0.2), "grout_color": Color(0.08, 0.04, 0.03), "grout_width": 0.02, "tile_variation": 0.18,
		"grime_height": 0.9, "grime_color": Color(0.02, 0.015, 0.012), "roughness_a": 0.85}, "plaster")
	MatLib.define("l41_slate", {"albedo_a": Color(0.2, 0.21, 0.22), "albedo_b": Color(0.15, 0.16, 0.17), "pattern": 14,
		"pattern_scale": Vector2(0.4, 0.22), "grout_color": Color(0.05, 0.05, 0.05), "grout_width": 0.02, "tile_variation": 0.2,
		"grime_height": 0.9, "grime_color": Color(0.02, 0.015, 0.012), "roughness_a": 0.7}, "plaster")
	MatLib.define("l41_brick", {"albedo_a": Color(0.36, 0.17, 0.12), "albedo_b": Color(0.28, 0.13, 0.09),
		"grime_height": 0.8, "grime_color": Color(0.02, 0.015, 0.012), "stain_amount": 0.4, "stain_color": Color(0.1, 0.06, 0.04)}, "brick")
	MatLib.define("l41_pole", {"albedo_a": Color(0.17, 0.12, 0.08), "albedo_b": Color(0.11, 0.08, 0.05), "noise_scale": 4.0,
		"roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 1.5, "grime_height": 1.0, "grime_color": Color(0.01, 0.01, 0.01)}, "wood_floor")
	MatLib.define("l41_wire", {"albedo_a": Color(0.3, 0.2, 0.12), "albedo_b": Color(0.25, 0.16, 0.1), "metallic_value": 0.8, "roughness_a": 0.5}, "metal")
	MatLib.define("l41_glass_dark", {"albedo_a": Color(0.02, 0.025, 0.03), "albedo_b": Color(0.03, 0.035, 0.04), "roughness_a": 0.05,
		"roughness_b": 0.12, "metallic_value": 0.2, "stain_amount": 0.4, "stain_color": Color(0.12, 0.11, 0.1)}, "plaster")
	MatLib.define("l41_bone", {"albedo_a": Color(0.56, 0.48, 0.36), "albedo_b": Color(0.36, 0.28, 0.2), "noise_scale": 6.0,
		"roughness_a": 0.75, "roughness_b": 0.95, "stain_amount": 0.55, "stain_color": Color(0.12, 0.09, 0.06), "bump_strength": 1.6}, "plaster")
	MatLib.define("l41_canvas", {"albedo_a": Color(0.11, 0.11, 0.085), "albedo_b": Color(0.07, 0.07, 0.055), "noise_scale": 2.0,
		"stain_amount": 0.6, "stain_color": Color(0.08, 0.07, 0.05), "roughness_a": 0.95}, "plaster")
	MatLib.register("l41_beacon", MatLib.panel(Color(1.0, 0.9, 0.62), 9.0))
	MatLib.register("l41_bridge_glow", MatLib.panel(Color(0.35, 0.55, 0.45), 0.6))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.55, 0.6, 0.58, 0.16)
	g.roughness = 0.08
	g.metallic_specular = 0.9
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l41_glass", g)


# ------------------------------------------------------------ helpers

static func seg_basis(a: Vector3, b: Vector3) -> Basis:
	var z := (b - a).normalized()
	var hz := Vector3(z.x, 0.0, z.z)
	if hz.length() < 0.01:
		hz = Vector3.FORWARD
	var x := Vector3.UP.cross(hz.normalized()).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)


## A square-section beam between two points.
static func beam(k: GeoKit, a: Vector3, b: Vector3, w: float, h: float, mat: String, collide := false) -> void:
	if a.distance_to(b) < 0.02:
		return
	k.box_xf(Transform3D(seg_basis(a, b), (a + b) * 0.5), Vector3(w, h, a.distance_to(b)), mat, GeoKit.ALL, collide)


# ------------------------------------------------------------ boardwalks

## pts: deck centre-line points (x, deck_top_y, z). opts: burnt (Array of
## segment indices), rails (0, 1 or 2 sides), feet ("concrete"/"steel").
func pier(k: GeoKit, pts: Array, opts: Dictionary = {}) -> void:
	pier_lines.append(pts)
	var burnt: Array = opts.get("burnt", [])
	var rails: int = opts.get("rails", 2)
	var feet: String = opts.get("feet", "concrete")
	var r := RandomNumberGenerator.new()
	r.seed = hash([pts[0], pts.size()])
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var bas := seg_basis(a, b)
		var ln := a.distance_to(b)
		var is_burnt := i in burnt
		if not is_burnt:
			k.box_xf(Transform3D(bas, (a + b) * 0.5 - bas.y * 0.07), Vector3(W, 0.14, ln + 0.04), "l41_plank", GeoKit.ALL, true, "wood")
			for s in [-1.0, 1.0]:
				beam(k, a + bas.x * s * (W * 0.5 - 0.12) - bas.y * 0.25, b + bas.x * s * (W * 0.5 - 0.12) - bas.y * 0.25, 0.14, 0.22, "l41_beam")
			if rails > 0:
				_rails(k, a, b, bas, rails)
		else:
			_burnt_deck(k, a, b, bas, r)
		# supports along the segment
		var n := maxi(1, int(round(ln / 3.6)))
		for j in n + 1:
			if j == n and i < pts.size() - 2:
				continue
			var t := float(j) / n
			var p := a.lerp(b, t)
			var charred := is_burnt or (i > 0 and (i - 1) in burnt and j == 0) or ((i + 1) in burnt and j == n)
			_support(k, p, bas, feet, charred, r)
		# a landing pad joins two segments
		if i > 0 and not is_burnt and not ((i - 1) in burnt):
			var pb := seg_basis(pts[i - 1], b)
			k.box_xf(Transform3D(Basis(pb.x, Vector3.UP, pb.x.cross(Vector3.UP)), a - Vector3.UP * 0.07), Vector3(W, 0.14, W), "l41_plank", GeoKit.ALL, true, "wood")


func _support(k: GeoKit, p: Vector3, bas: Basis, feet: String, charred: bool, r: RandomNumberGenerator) -> void:
	var g: float = land.h(p.x, p.z)
	var foot_top := maxf(g, land.TAR_Y) + (0.55 if g < 0.0 else 0.3)
	var deck_low := p.y - 0.36
	var fc := Vector3(p.x, (g - 0.4 + foot_top) * 0.5, p.z)
	if feet == "steel":
		for s in [-1.0, 1.0]:
			k.cylinder(Vector3(p.x, fc.y, p.z) + bas.x * s * 0.7, 0.16, foot_top - g + 0.4, "l41_steel", 8, false)
	else:
		k.box_xf(Transform3D(Basis(bas.x, Vector3.UP, bas.x.cross(Vector3.UP)), fc), Vector3(W * 0.95, foot_top - g + 0.4, 0.55), "l41_concrete", GeoKit.ALL, true)
	var top := deck_low if not charred else foot_top + r.randf_range(0.2, 1.1)
	if top <= foot_top + 0.05:
		return
	var mat := "l41_char" if charred else "l41_beam"
	for s in [-1.0, 1.0]:
		var q: Vector3 = Vector3(p.x, 0, p.z) + bas.x * s * 0.78
		var tt := top if not charred else foot_top + r.randf_range(0.2, 1.4)
		beam(k, Vector3(q.x, foot_top, q.z), Vector3(q.x, tt, q.z), 0.2, 0.2, mat)
	if not charred:
		var l0 := Vector3(p.x, 0, p.z) - bas.x * 0.78
		var r0 := Vector3(p.x, 0, p.z) + bas.x * 0.78
		k.box_xf(Transform3D(Basis(bas.x, Vector3.UP, bas.x.cross(Vector3.UP)), Vector3(p.x, deck_low - 0.08, p.z)), Vector3(W + 0.3, 0.2, 0.24), "l41_beam", GeoKit.ALL, false)
		if deck_low - foot_top > 1.2:
			beam(k, Vector3(l0.x, foot_top + 0.2, l0.z), Vector3(r0.x, deck_low - 0.25, r0.z), 0.1, 0.16, "l41_beam")


func _rails(k: GeoKit, a: Vector3, b: Vector3, bas: Basis, sides: int) -> void:
	var ln := a.distance_to(b)
	var n := maxi(1, int(ceil(ln / 2.0)))
	for s in ([-1.0, 1.0] if sides == 2 else [1.0]):
		for j in n:
			var p0: Vector3 = a.lerp(b, float(j) / n) + bas.x * s * (W * 0.5 - 0.05)
			var p1: Vector3 = a.lerp(b, float(j + 1) / n) + bas.x * s * (W * 0.5 - 0.05)
			var mid: Vector3 = (p0 + p1) * 0.5
			var open := false
			for o in rail_open:
				if Vector2(mid.x, mid.z).distance_to(o) < 1.6:
					open = true
			if open:
				continue
			beam(k, p0, p0 + Vector3.UP * 1.05, 0.1, 0.1, "l41_beam")
			beam(k, p0 + Vector3.UP * 1.0, p1 + Vector3.UP * 1.0, 0.08, 0.12, "l41_beam")
			beam(k, p0 + Vector3.UP * 0.5, p1 + Vector3.UP * 0.5, 0.05, 0.1, "l41_beam")
			# one thin collision board keeps you on the walkway
			k.box_xf(Transform3D(bas, mid + Vector3.UP * 0.55), Vector3(0.08, 1.1, p0.distance_to(p1)), "l41_beam", 0, true)


func _burnt_deck(k: GeoKit, a: Vector3, b: Vector3, bas: Basis, r: RandomNumberGenerator) -> void:
	# a few charred boards still cling to the ends; the middle is gone
	for e in [0.0, 1.0]:
		var p := a.lerp(b, e)
		var inward := (b - a).normalized() * (1.0 if e == 0.0 else -1.0)
		for j in 4:
			var lat := r.randf_range(-0.8, 0.8)
			var ln := r.randf_range(0.4, 1.6)
			var q := p + bas.x * lat + inward * ln * 0.5 - Vector3.UP * (0.08 + r.randf() * 0.1)
			k.box_xf(Transform3D(bas.rotated(Vector3.UP, r.randf_range(-0.15, 0.15)), q), Vector3(0.24, 0.07, ln), "l41_char", GeoKit.ALL, false)
	burning.append(a.lerp(b, 0.5))


## A raised boardwalk ruin: only concrete feet and charred leg stubs remain.
func ruin(k: GeoKit, pts: Array) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(pts[0])
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var bas := seg_basis(a, b)
		var n := maxi(1, int(round(a.distance_to(b) / 3.6)))
		for j in n + 1:
			if j == n and i < pts.size() - 2:
				continue
			_support(k, a.lerp(b, float(j) / n), bas, "concrete", true, r)


## A pier that has sunk: its walkway runs down into the tar.
func sunken(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var bas := seg_basis(a, b)
	k.box_xf(Transform3D(bas, (a + b) * 0.5 - bas.y * 0.07), Vector3(W, 0.14, a.distance_to(b)), "l41_plank", GeoKit.ALL, true, "wood")
	for s in [-1.0, 1.0]:
		beam(k, a + bas.x * s * 0.9 - bas.y * 0.25, b + bas.x * s * 0.9 - bas.y * 0.25, 0.14, 0.22, "l41_beam")
		beam(k, a + bas.x * s * 0.95, a + bas.x * s * 0.95 + Vector3.UP * 1.0, 0.1, 0.1, "l41_beam")
	var n := int(a.distance_to(b) / 3.6)
	for j in n:
		var p := a.lerp(b, (j + 0.5) / n)
		if p.y < 0.6:
			continue
		var g: float = land.h(p.x, p.z)
		var c := Vector3(p.x, (g - 0.3 + p.y - 0.4) * 0.5, p.z)
		k.box(c, Vector3(0.5, p.y - 0.4 - g + 0.3, 0.5), "l41_concrete", GeoKit.ALL, false)


# ------------------------------------------------------------ ladders

## A crude wooden ladder from the sand up to a deck edge. out = horizontal
## direction from the deck edge towards the ladder (away from the pier).
func ladder(k: GeoKit, parent: Node3D, edge: Vector3, out: Vector3) -> void:
	out.y = 0.0
	out = out.normalized()
	var side := Vector3.UP.cross(out).normalized()
	var deck_y := edge.y
	var base_xz := edge + out * 0.62
	var gy: float = land.h(base_xz.x, base_xz.z)
	var base := Vector3(base_xz.x, gy, base_xz.z)
	var top := edge + out * 0.16 + Vector3.UP * 0.9
	for s in [-1.0, 1.0]:
		beam(k, base + side * s * 0.24 - Vector3.UP * 0.1, top + side * s * 0.24, 0.07, 0.09, "l41_beam")
	var steps := int((top.y - base.y) / 0.3)
	for j in range(1, steps):
		var p := base.lerp(top, float(j) / steps)
		k.box_xf(Transform3D(seg_basis(p - side, p + side), p), Vector3(0.06, 0.05, 0.5), "l41_beam", GeoKit.ALL, false)
	# a backboard the climber leans on (the ladder itself, as collision)
	var bb := edge + out * 0.1
	k.box_xf(Transform3D(seg_basis(bb - side, bb + side), Vector3(bb.x, (gy + deck_y) * 0.5, bb.z)), Vector3(0.12, deck_y - gy, 0.8), "l41_beam", 0, true)
	var lv := LadderVolume.new()
	lv.name = "Ladder"
	parent.add_child(lv)
	var c0 := edge + out * 0.05 - side * 0.5
	var c1 := edge + out * 1.05 + side * 0.5
	lv.setup(Vector3(minf(c0.x, c1.x), gy + 0.95, minf(c0.z, c1.z)), Vector3(maxf(c0.x, c1.x), deck_y + 1.0, maxf(c0.z, c1.z)))
	ladders.append({"base": base, "top": edge, "out": out, "vol": lv})


# ------------------------------------------------------------ exit objects

## The odd barn door on a stone plinth (Level 612).
func barn_door(k: GeoKit, c: Vector3, yaw: float) -> Dictionary:
	var b := Basis(Vector3.UP, yaw)
	var fwd := b * Vector3(0, 0, 1)
	var rt := b * Vector3(1, 0, 0)
	var top := c.y + 1.0
	# two-tier plinth of dressed stone blocks
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.25), Vector3(4.2, 0.5 + 0.4, 3.4), "l41_stone", GeoKit.ALL, true, "stone")
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.75), Vector3(3.4, 0.5, 2.6), "l41_stone", GeoKit.ALL, true, "stone")
	k.stairs(c + fwd * 1.3 + fwd * (5 * 0.3) - Vector3.UP * 0.2, -fwd, 1.6, 1.2, 5, "l41_stone", 0.3)
	# freestanding frame and the door itself, closed
	var dc := c + Vector3.UP * top + fwd * -0.2
	dc.y = top
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, dc + rt * s * 1.15 + Vector3.UP * 1.35), Vector3(0.2, 2.7, 0.22), "l41_beam", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, dc + Vector3.UP * 2.76), Vector3(2.6, 0.2, 0.26), "l41_beam", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, dc + Vector3.UP * 1.3), Vector3(2.1, 2.5, 0.08), "l41_barn", GeoKit.ALL, true)
	# white frame and Z brace on the face
	var f := dc + fwd * 0.05
	for p in [[Vector3(-1.0, 0.1, 0), Vector3(1.0, 0.1, 0)], [Vector3(-1.0, 2.5, 0), Vector3(1.0, 2.5, 0)],
			[Vector3(-1.0, 0.1, 0), Vector3(-1.0, 2.5, 0)], [Vector3(1.0, 0.1, 0), Vector3(1.0, 2.5, 0)],
			[Vector3(-1.0, 0.1, 0), Vector3(1.0, 1.3, 0)], [Vector3(-1.0, 1.3, 0), Vector3(1.0, 2.5, 0)], [Vector3(-1.0, 1.3, 0), Vector3(1.0, 1.3, 0)]]:
		beam(k, f + b * p[0], f + b * p[1], 0.04, 0.13, "l41_white")
	return {"front": dc + fwd * 0.9 + Vector3.UP * 1.0, "fwd": fwd, "top_y": top}


## The submerged lighthouse: tower body under the tar, the gallery partly
## above it, the lantern room with its flickering beacon.
func lighthouse(k: GeoKit, c: Vector3) -> Dictionary:
	var tilt := Basis(Vector3(0.0, 0.0, 1.0), 0.05) * Basis(Vector3(1.0, 0.0, 0.0), -0.035)
	var deck := c + Vector3.UP * 0.32
	k.cylinder(c + Vector3.DOWN * 3.0, 3.0, 6.4, "l41_white", 20, true, true)
	k.cylinder(deck + Vector3.DOWN * 0.16, 3.7, 0.28, "l41_steel", 24, true, true)
	# gallery railing (tilted with the tower, a few bars bent away)
	for j in 28:
		var a := TAU * j / 28.0
		var o := Vector3(cos(a), 0, sin(a)) * 3.55
		if a > 0.15 and a < 0.75:
			continue
		var p0 := deck + tilt * o
		var p1 := deck + tilt * (o + Vector3.UP * 1.05)
		beam(k, p0, p1, 0.05, 0.05, "l41_steel")
		var a2 := TAU * (j + 1) / 28.0
		var o2 := Vector3(cos(a2), 0, sin(a2)) * 3.55
		if not (a2 > 0.15 and a2 < 0.75):
			beam(k, deck + tilt * (o + Vector3.UP * 1.0), deck + tilt * (o2 + Vector3.UP * 1.0), 0.06, 0.06, "l41_steel")
	# lantern room: a low wall, glazing bars, glass, a dome
	var lr := deck
	k.cylinder(lr + Vector3.UP * 0.45, 2.2, 0.9, "l41_red", 16, false, false)
	for j in 12:
		var a := TAU * j / 12.0
		var o := Vector3(cos(a), 0, sin(a)) * 2.15
		beam(k, lr + o + Vector3.UP * 0.9, lr + o + Vector3.UP * 3.0, 0.07, 0.07, "l41_steel")
		if a > 0.2 and a < 0.75:
			continue    # the open panel (door) faces the sunken boardwalk
		var o2 := Vector3(cos(TAU * (j + 1) / 12.0), 0, sin(TAU * (j + 1) / 12.0)) * 2.15
		var pc := lr + (o + o2) * 0.5 + Vector3.UP * 1.95
		k.box_xf(Transform3D(seg_basis(lr + o, lr + o2), pc), Vector3(0.02, 2.1, o.distance_to(o2)), "l41_glass", GeoKit.ALL, true)
		k.box_xf(Transform3D(seg_basis(lr + o, lr + o2), lr + (o + o2) * 0.5 + Vector3.UP * 0.6), Vector3(0.2, 1.2, o.distance_to(o2)), "l41_red", GeoKit.ALL, true)
	k.cylinder(lr + Vector3.UP * 3.15, 2.35, 0.3, "l41_red", 16, false, true)
	k.cylinder(lr + Vector3.UP * 3.55, 1.6, 0.5, "l41_red", 12, false, true)
	k.cylinder(lr + Vector3.UP * 4.0, 0.25, 0.6, "l41_steel", 6, false, true)
	# the beacon on its pedestal
	k.cylinder(lr + Vector3.UP * 0.6, 0.35, 1.2, "l41_steel", 10, true, true)
	k.cylinder(lr + Vector3.UP * 1.55, 0.42, 0.7, "l41_beacon", 12, false, true)
	k.cylinder(lr + Vector3.UP * 1.55, 0.5, 0.8, "l41_glass", 12, false, false)
	return {"deck": deck, "beacon": lr + Vector3.UP * 1.55, "door_dir": Vector3(cos(0.47), 0, sin(0.47))}


## The bridge of a navy vessel, listing in the tar; one window is broken.
## The forward deckhouse roof is level with sill_y (the walkway's end).
func navy_bridge(k: GeoKit, parent: Node3D, c: Vector3, yaw: float, sill_y: float) -> Dictionary:
	var yb := Basis(Vector3.UP, yaw)
	var b := yb * Basis(Vector3(0, 0, 1), 0.05)
	var fwd := yb * Vector3(0, 0, 1)
	var o := Vector3(c.x, 0.0, c.z)
	var at := func(x: float, y: float, z: float) -> Vector3: return o + b * Vector3(x, y, z)
	# forward deckhouse (its roof is the landing), the bridge level behind it
	k.box_xf(Transform3D(b, at.call(0, sill_y - 3.0, 0)), Vector3(16.0, 6.0, 10.0), "l41_navy", GeoKit.ALL, true, "metal")
	k.box_xf(Transform3D(b, at.call(0, sill_y + 1.15, -1.0)), Vector3(12.0, 2.3, 6.4), "l41_navy", GeoKit.ALL, true, "metal")
	k.box_xf(Transform3D(b, at.call(0, sill_y + 2.4, -1.0)), Vector3(13.0, 0.22, 7.2), "l41_navy", GeoKit.ALL, true, "metal")
	k.box_xf(Transform3D(b, at.call(0, sill_y + 3.3, -2.2)), Vector3(5.0, 1.8, 3.6), "l41_navy", GeoKit.ALL, false)
	# bridge wings and their rails
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, at.call(s * 7.6, sill_y + 0.05, 0.6)), Vector3(3.2, 0.14, 2.4), "l41_navy", GeoKit.ALL, false)
		for j in 4:
			beam(k, at.call(s * (6.2 + j * 0.9), sill_y + 0.1, 1.8), at.call(s * (6.2 + j * 0.9), sill_y + 1.1, 1.8), 0.05, 0.05, "l41_white")
		beam(k, at.call(s * 6.2, sill_y + 1.05, 1.8), at.call(s * 9.1, sill_y + 1.05, 1.8), 0.05, 0.06, "l41_white")
		# life-raft canisters and a row of portholes down the deckhouse side
		for j in 3:
			k.cylinder(at.call(s * 8.05, sill_y - 1.2 + j * 0.0, -3.0 + j * 1.6), 0.32, 1.1, "l41_white", 10, false)
		for j in 6:
			k.cylinder(at.call(s * 8.02, sill_y - 2.0, -4.0 + j * 1.5), 0.2, 0.05, "l41_glass_dark", 10, false)
	# the deckhouse roof rail, open where the walkway meets it
	for j in 9:
		var x := -7.6 + j * 1.9
		if absf(x) < 2.2:
			continue
		beam(k, at.call(x, sill_y, 4.85), at.call(x, sill_y + 1.05, 4.85), 0.05, 0.05, "l41_white")
		if j < 8 and absf(x + 1.9) >= 2.2:
			beam(k, at.call(x, sill_y + 1.0, 4.85), at.call(x + 1.9, sill_y + 1.0, 4.85), 0.05, 0.06, "l41_white")
	# mast: lattice tripod, a yard, a radar array and whip antennas
	var mb: Vector3 = at.call(0, sill_y + 4.2, -2.2)
	for p in [Vector3(-1.0, 0, -0.8), Vector3(1.0, 0, -0.8), Vector3(0, 0, 0.9)]:
		beam(k, mb + b * p, mb + Vector3.UP * 5.0 + b * (p * 0.2), 0.12, 0.12, "l41_navy")
	beam(k, mb + Vector3.UP * 4.0 - b.x * 2.4, mb + Vector3.UP * 4.0 + b.x * 2.4, 0.1, 0.1, "l41_navy")
	k.box_xf(Transform3D(b * Basis(Vector3.UP, 0.4), mb + Vector3.UP * 5.4), Vector3(2.6, 0.5, 0.16), "l41_steel", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		beam(k, at.call(s * 5.5, sill_y + 2.5, -3.6), at.call(s * 5.3, sill_y + 8.5, -3.6), 0.04, 0.04, "l41_steel")
	# window band: black glass in white frames; the fourth from the right is smashed
	var broken := Vector3.ZERO
	var zf := -1.0 + 3.2 + 0.03
	for i in 8:
		var x := -5.25 + i * 1.5
		var wc: Vector3 = at.call(x, sill_y + 1.35, zf)
		for e in [[Vector3(-0.62, 0, 0), Vector3(0.62, 0, 0), -0.5], [Vector3(-0.62, 0, 0), Vector3(0.62, 0, 0), 0.5]]:
			beam(k, wc + b * (e[0] + Vector3(0, e[2], 0)), wc + b * (e[1] + Vector3(0, e[2], 0)), 0.06, 0.06, "l41_white")
		beam(k, wc + b * Vector3(-0.62, -0.5, 0), wc + b * Vector3(-0.62, 0.5, 0), 0.06, 0.06, "l41_white")
		if i == 4:
			broken = wc
			# jagged shards left in the frame
			k.box_xf(Transform3D(b * Basis(Vector3(0, 0, 1), 0.5), wc + b * Vector3(0.38, -0.36, 0)), Vector3(0.4, 0.2, 0.02), "l41_glass_dark", GeoKit.ALL, false)
			k.box_xf(Transform3D(b * Basis(Vector3(0, 0, 1), -0.4), wc + b * Vector3(-0.42, 0.38, 0)), Vector3(0.3, 0.18, 0.02), "l41_glass_dark", GeoKit.ALL, false)
			continue
		k.box_xf(Transform3D(b, wc), Vector3(1.18, 0.95, 0.04), "l41_glass_dark", GeoKit.ALL, false)
	beam(k, at.call(-6.0, sill_y + 0.82, zf), at.call(6.0, sill_y + 0.82, zf), 0.08, 0.08, "l41_white")
	# the bridge interior seen through the hole: consoles under a dim green glow
	var room: Vector3 = broken - fwd * 1.6
	k.box_xf(Transform3D(b, room + b * Vector3(0, -0.85, 0)), Vector3(2.4, 0.9, 0.6), "l41_bridge_glow", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, room + b * Vector3(-1.6, -0.9, -0.8)), Vector3(0.6, 0.8, 0.6), "l41_steel", GeoKit.ALL, false)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.5, 0.8, 0.6)
	glow.light_energy = 0.9
	glow.omni_range = 4.0
	glow.position = room + Vector3.UP * 0.2
	parent.add_child(glow)
	return {"window": broken + fwd * 0.55 + Vector3.DOWN * 0.25, "fwd": fwd}


## An upside-down orbiter stack, almost all of it under the tar: the aft ends
## of the two boosters with their nozzles, a hump of the fuel tank, and the
## orbiter's black underside with its engine bells.
func shuttle(k: GeoKit, parent: Node3D, c: Vector3, yaw: float) -> Dictionary:
	var yb := Basis(Vector3.UP, yaw)
	var fwd := yb * Vector3(0, 0, 1)      # towards the island
	var rt := yb * Vector3(1, 0, 0)
	var axis := (fwd * cos(0.2) + Vector3.UP * sin(0.2)).normalized()
	var ax_b := Basis(rt, axis, rt.cross(axis)).orthonormalized()
	var mouths: Array = []
	var white: Material = MatLib.get_mat("l41_white")
	var noz: Material = MatLib.get_mat("l41_nozzle")
	for s in [-1.0, 1.0]:
		var aft: Vector3 = c + rt * s * 4.4 + Vector3.UP * 1.9
		# casing with its field joints, the flared aft skirt, then the bell
		_lathe(parent, [Vector2(0.0, -22.0), Vector2(1.85, -22.0), Vector2(1.85, -1.2), Vector2(2.55, 0.0), Vector2(1.0, 0.05)], 20, white, Transform3D(ax_b, aft))
		for j in 3:
			_lathe(parent, [Vector2(1.84, -0.12), Vector2(1.93, -0.1), Vector2(1.93, 0.1), Vector2(1.84, 0.12)], 20, noz, Transform3D(ax_b, aft - axis * (4.5 + j * 5.5)))
		_lathe(parent, [Vector2(0.75, -0.2), Vector2(0.95, 0.4), Vector2(1.45, 1.6), Vector2(1.9, 2.5), Vector2(1.8, 2.5), Vector2(1.35, 1.6), Vector2(0.85, 0.4), Vector2(0.6, 0.0)], 20, noz, Transform3D(ax_b, aft))
		mouths.append(aft + axis * 2.5)
		k.box_xf(Transform3D(ax_b, aft - axis * 5.0), Vector3(3.6, 10.0, 3.6), "l41_white", 0, true, "metal")
	# the external tank: a rusted orange hump between and behind the boosters
	_lathe(parent, [Vector2(0.0, -30.0), Vector2(4.2, -28.0), Vector2(4.2, -3.0), Vector2(3.4, -0.8), Vector2(0.0, 0.0)], 24, MatLib.get_mat("l41_orange"), Transform3D(ax_b, c - fwd * 1.0 + Vector3.DOWN * 1.2))
	# orbiter underside (black tiles), nose down in the tar, its engine bells
	var ob := c - fwd * 13.0 + Vector3.UP * 0.1
	var obas := yb * Basis(Vector3(1, 0, 0), -0.06)
	k.box_xf(Transform3D(obas, ob + Vector3.DOWN * 0.4), Vector3(8.5, 1.6, 15.0), "l41_tiles_black", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(obas * Basis(Vector3.UP, s * 0.5), ob + rt * s * 6.0 + Vector3.DOWN * 0.55), Vector3(5.5, 0.6, 9.0), "l41_tiles_black", GeoKit.ALL, false)
	for p in [Vector3(-1.5, 0.3, 7.6), Vector3(1.5, 0.3, 7.6), Vector3(0, 1.4, 7.6)]:
		var eb := Basis(rt, fwd.rotated(rt, 0.15), rt.cross(fwd.rotated(rt, 0.15))).orthonormalized()
		_lathe(parent, [Vector2(0.4, 0.0), Vector2(0.75, 0.8), Vector2(1.15, 1.8), Vector2(1.08, 1.8), Vector2(0.7, 0.8), Vector2(0.3, 0.0)], 14, noz, Transform3D(eb, ob + obas * p))
	return {"mouths": mouths, "fwd": fwd}


## A surface of revolution about the local Y axis (profile: Vector2(r, y)).
func _lathe(parent: Node3D, prof: Array, sides: int, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		for j in sides:
			var a0 := TAU * j / sides
			var a1 := TAU * (j + 1) / sides
			var q := [Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x), Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x),
				Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x), Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x)]
			var uv := [Vector2(a0 * 2.0, p0.y), Vector2(a1 * 2.0, p0.y), Vector2(a1 * 2.0, p1.y), Vector2(a0 * 2.0, p1.y)]
			for kk in [0, 2, 1, 0, 3, 2]:
				st.set_uv(uv[kk])
				st.add_vertex(q[kk])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	return mi
