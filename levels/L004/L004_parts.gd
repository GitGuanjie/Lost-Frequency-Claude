extends RefCounted
## Level 4 building parts: materials, frame-mapped boxes, switchback stairwells
## (office cores between floors; exit stairways down out of the level), lift
## shafts, doors, blacked-out windows, Almond Water dispensers and labels.
## A "frame" maps local (x, y, z) to world with axis-aligned u/v, so one stair
## routine serves any 90-degree orientation.

const T := 0.12          # partition / wall thickness
const FH := 3.6          # floor-to-floor height
const CH := 2.8          # clear ceiling height (film-real office)
const DOOR_W := 1.0
const DOOR_H := 2.1
const SW := 4.8          # stairwell width
const SD := 6.6          # stairwell depth
const LAND := 1.5        # door landing depth
const RUN := 0.28        # tread run; 10 risers of 0.18 per flight

var lvl: Node3D


func _init(level: Node3D) -> void:
	lvl = level


static func define_materials() -> void:
	MatLib.define("l4_carpet", {"albedo_a": Color(0.33, 0.34, 0.37), "albedo_b": Color(0.27, 0.28, 0.31), "pattern": 6,
		"pattern_strength": 0.0, "wetness": 0.0, "noise_scale": 0.55, "roughness_a": 0.97, "roughness_b": 1.0, "bump_strength": 0.55,
		"stain_amount": 0.32, "stain_color": Color(0.24, 0.23, 0.21), "stain_scale": 0.22, "tile_variation": 0.0}, "l0_carpet")
	MatLib.define("l4_carpet_corr", {"albedo_a": Color(0.25, 0.26, 0.29), "albedo_b": Color(0.21, 0.22, 0.25), "pattern": 6,
		"pattern_strength": 0.0, "wetness": 0.0, "stain_amount": 0.4, "stain_color": Color(0.19, 0.18, 0.17), "noise_scale": 0.6}, "l0_carpet")
	MatLib.define("l4_carpet_ghost", {"albedo_a": Color(0.25, 0.28, 0.34), "albedo_b": Color(0.22, 0.25, 0.31), "pattern": 6,
		"pattern_strength": 0.0, "wetness": 0.0, "stain_amount": 0.05, "noise_scale": 0.55}, "l0_carpet")
	MatLib.define("l4_wall", {"albedo_a": Color(0.73, 0.72, 0.67), "albedo_b": Color(0.69, 0.68, 0.63), "noise_scale": 1.1,
		"stain_amount": 0.34, "stain_color": Color(0.58, 0.55, 0.47), "stain_scale": 0.3, "grime_height": 0.16, "grime_color": Color(0.45, 0.44, 0.40),
		"bump_strength": 0.3}, "plaster")
	MatLib.define("l4_block", {"albedo_a": Color(0.70, 0.71, 0.70), "albedo_b": Color(0.66, 0.67, 0.66), "pattern": 4,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.6, 0.61, 0.6), "bump_strength": 0.6,
		"stain_amount": 0.2, "stain_color": Color(0.52, 0.52, 0.5)}, "plaster")
	MatLib.define("l4_ceiling", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80), "pattern": 7,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.012, "grout_color": Color(0.62, 0.62, 0.60), "stain_amount": 0.34,
		"stain_color": Color(0.70, 0.64, 0.50), "roughness_a": 0.92, "noise_scale": 0.7, "tile_variation": 0.03})
	MatLib.define("l4_facade", {"albedo_a": Color(0.56, 0.56, 0.54), "albedo_b": Color(0.48, 0.48, 0.46), "stain_amount": 0.35,
		"stain_color": Color(0.38, 0.37, 0.34), "stain_scale": 0.15}, "concrete")
	MatLib.define("l4_frame", {"albedo_a": Color(0.42, 0.43, 0.45), "albedo_b": Color(0.38, 0.39, 0.41), "metallic_value": 0.3, "roughness_a": 0.5, "stain_amount": 0.0}, "metal")
	MatLib.define("l4_alu", {"albedo_a": Color(0.70, 0.71, 0.72), "albedo_b": Color(0.64, 0.65, 0.66), "metallic_value": 0.6, "roughness_a": 0.35, "stain_amount": 0.0}, "metal")
	MatLib.define("l4_steel", {"albedo_a": Color(0.62, 0.63, 0.64), "albedo_b": Color(0.56, 0.57, 0.58), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.012), "pattern_color": Color(0.66, 0.67, 0.68), "pattern_strength": 0.3, "metallic_value": 0.8,
		"roughness_a": 0.3, "roughness_b": 0.42, "stain_amount": 0.05}, "metal")
	MatLib.define("l4_rail", {"albedo_a": Color(0.22, 0.23, 0.24), "albedo_b": Color(0.2, 0.21, 0.22), "metallic_value": 0.5, "roughness_a": 0.45, "stain_amount": 0.0}, "metal")
	MatLib.define("l4_door", {"albedo_a": Color(0.60, 0.46, 0.31), "albedo_b": Color(0.54, 0.41, 0.27), "pattern_scale": Vector2(2.4, 0.06), "roughness_a": 0.5}, "wood_floor")
	MatLib.define("l4_firedoor", {"albedo_a": Color(0.47, 0.50, 0.52), "albedo_b": Color(0.44, 0.47, 0.49), "roughness_a": 0.5, "stain_amount": 0.1}, "metal")
	MatLib.define("l4_blackglass", {"albedo_a": Color(0.012, 0.012, 0.014), "albedo_b": Color(0.02, 0.02, 0.022), "roughness_a": 0.16,
		"roughness_b": 0.34, "noise_scale": 2.5, "bump_strength": 0.05, "metallic_value": 0.0}, "concrete")
	MatLib.define("l4_tape", {"albedo_a": Color(0.62, 0.58, 0.48), "albedo_b": Color(0.55, 0.51, 0.41), "noise_scale": 6.0}, "plaster")
	MatLib.define("l4_stair_conc", {"albedo_a": Color(0.52, 0.52, 0.5), "albedo_b": Color(0.45, 0.45, 0.43), "stain_amount": 0.3}, "concrete")
	MatLib.define("l4_oldwood", {"albedo_a": Color(0.31, 0.17, 0.09), "albedo_b": Color(0.25, 0.13, 0.07), "pattern_scale": Vector2(1.6, 0.18), "roughness_a": 0.42}, "wood_floor")
	MatLib.define("l4_oldwall", {"albedo_a": Color(0.33, 0.30, 0.21), "albedo_b": Color(0.29, 0.26, 0.18), "pattern": 10,
		"pattern_scale": Vector2(0.32, 0.42), "pattern_color": Color(0.40, 0.34, 0.19), "pattern_strength": 0.45, "stain_amount": 0.35,
		"stain_color": Color(0.22, 0.18, 0.1), "grime_height": 0.3}, "plaster")
	MatLib.define("l4_brass", {"albedo_a": Color(0.66, 0.50, 0.24), "albedo_b": Color(0.58, 0.43, 0.2), "metallic_value": 0.8, "roughness_a": 0.3, "stain_amount": 0.1}, "metal")
	MatLib.define("l4_vinyl", {"albedo_a": Color(0.72, 0.71, 0.66), "albedo_b": Color(0.66, 0.65, 0.60), "pattern": 1,
		"pattern_scale": Vector2(0.3, 0.3), "grout_width": 0.004, "grout_color": Color(0.58, 0.57, 0.52), "roughness_a": 0.35,
		"roughness_b": 0.5, "stain_amount": 0.25}, "pool_tile")
	MatLib.define("l4_vend", {"albedo_a": Color(0.42, 0.07, 0.06), "albedo_b": Color(0.38, 0.06, 0.05), "metallic_value": 0.3, "roughness_a": 0.4, "stain_amount": 0.05}, "metal")
	MatLib.define("l4_plastic", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80), "roughness_a": 0.4, "roughness_b": 0.5, "bump_strength": 0.1}, "plaster")
	MatLib.define("l4_beige", {"albedo_a": Color(0.80, 0.78, 0.72), "albedo_b": Color(0.76, 0.74, 0.68), "roughness_a": 0.5}, "plaster")
	MatLib.define("l4_cardboard", {"albedo_a": Color(0.56, 0.43, 0.28), "albedo_b": Color(0.50, 0.38, 0.24), "roughness_a": 0.95}, "plaster")
	MatLib.define("l4_red", {"albedo_a": Color(0.62, 0.07, 0.05), "albedo_b": Color(0.55, 0.05, 0.04), "roughness_a": 0.35}, "plaster")
	MatLib.define("l4_shutter", {"albedo_a": Color(0.55, 0.56, 0.55), "albedo_b": Color(0.48, 0.49, 0.48), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.075), "pattern_color": Color(0.36, 0.37, 0.36), "pattern_strength": 0.6, "stain_amount": 0.3}, "metal")
	MatLib.define("l4_partition", {"albedo_a": Color(0.42, 0.44, 0.47), "albedo_b": Color(0.38, 0.40, 0.43), "noise_scale": 9.0, "roughness_a": 1.0, "bump_strength": 0.8}, "plaster")
	MatLib.define("l4_table", {"albedo_a": Color(0.44, 0.33, 0.23), "albedo_b": Color(0.40, 0.30, 0.21), "pattern_scale": Vector2(3.0, 0.1), "roughness_a": 0.35}, "wood_floor")
	MatLib.define("l4_white", {"albedo_a": Color(0.93, 0.93, 0.92), "albedo_b": Color(0.9, 0.9, 0.89), "roughness_a": 0.15, "roughness_b": 0.2, "stain_amount": 0.05}, "plaster")
	MatLib.define("l4_grille", {"albedo_a": Color(0.5, 0.51, 0.51), "albedo_b": Color(0.46, 0.47, 0.47), "pattern": 2,
		"pattern_scale": Vector2(0.04, 1.0), "pattern_color": Color(0.16, 0.16, 0.16), "pattern_strength": 0.8}, "metal")
	MatLib.define("l4_dark", {"albedo_a": Color(0.05, 0.05, 0.055), "albedo_b": Color(0.04, 0.04, 0.045), "roughness_a": 0.9}, "plaster")
	MatLib.register("l4_panel", MatLib.panel(Color(0.93, 0.97, 1.0), 2.3))
	MatLib.register("l4_panel_warm", MatLib.panel(Color(1.0, 0.82, 0.55), 1.6))
	MatLib.register("l4_litwin", MatLib.standard(Color(0.7, 0.74, 0.78), 0.4, 0.0, Color(0.78, 0.84, 0.9), 0.55))
	MatLib.register("l4_vendfront", MatLib.standard(Color(0.9, 0.86, 0.75), 0.3, 0.0, Color(1.0, 0.93, 0.78), 1.3))
	MatLib.register("l4_exitglow", MatLib.standard(Color(0.1, 0.6, 0.25), 0.4, 0.0, Color(0.2, 1.0, 0.45), 2.2))
	var bottle := StandardMaterial3D.new()
	bottle.albedo_color = Color(0.45, 0.68, 0.9, 0.55)
	bottle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bottle.roughness = 0.1
	MatLib.register("l4_bottle", bottle)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.62, 0.72, 0.74, 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.04
	glass.metallic_specular = 0.9
	MatLib.register("l4_glass", glass)


# ------------------------------------------------------------- frames

static func fr(o: Vector3, u: Vector3, v: Vector3) -> Dictionary:
	return {"o": o, "u": u, "v": v}


static func fp(f: Dictionary, x: float, y: float, z: float) -> Vector3:
	return f["o"] + f["u"] * x + Vector3.UP * y + f["v"] * z


static func fbox(k: GeoKit, f: Dictionary, a: Vector3, b: Vector3, mat: String, faces := GeoKit.ALL, collide := true) -> void:
	var p := fp(f, a.x, a.y, a.z)
	var q := fp(f, b.x, b.y, b.z)
	k.box_mm(Vector3(minf(p.x, q.x), minf(p.y, q.y), minf(p.z, q.z)), Vector3(maxf(p.x, q.x), maxf(p.y, q.y), maxf(p.z, q.z)), mat, faces, collide)


static func fwall(k: GeoKit, f: Dictionary, x0: float, z0: float, x1: float, z1: float, y0: float, h: float, mat: String, ops: Array = []) -> void:
	k.wall(fp(f, x0, y0, z0), fp(f, x1, y0, z1), h, T, mat, ops, GeoKit.ALL)


## Rect2 list minus holes (all in the XZ plane).
static func cut(rects: Array, holes: Array) -> Array:
	var out := rects
	for h in holes:
		var nxt: Array = []
		for r in out:
			var rr: Rect2 = r
			var hh: Rect2 = h
			if not rr.intersects(hh):
				nxt.append(rr)
				continue
			var i := rr.intersection(hh)
			if i.position.x > rr.position.x + 0.001:
				nxt.append(Rect2(rr.position.x, rr.position.y, i.position.x - rr.position.x, rr.size.y))
			if i.end.x < rr.end.x - 0.001:
				nxt.append(Rect2(i.end.x, rr.position.y, rr.end.x - i.end.x, rr.size.y))
			if i.position.y > rr.position.y + 0.001:
				nxt.append(Rect2(i.position.x, rr.position.y, i.size.x, i.position.y - rr.position.y))
			if i.end.y < rr.end.y - 0.001:
				nxt.append(Rect2(i.position.x, i.end.y, i.size.x, rr.end.y - i.end.y))
		out = nxt
	return out


static func floor_rects(k: GeoKit, rects: Array, y: float, thick: float, mat: String) -> void:
	for r in rects:
		var rr: Rect2 = r
		k.box_mm(Vector3(rr.position.x, y - thick, rr.position.y), Vector3(rr.end.x, y, rr.end.y), mat, GeoKit.PY)


static func ceil_rects(k: GeoKit, rects: Array, y: float, mat: String) -> void:
	for r in rects:
		var rr: Rect2 = r
		k.box_mm(Vector3(rr.position.x, y, rr.position.y), Vector3(rr.end.x, y + 0.05, rr.end.y), mat, GeoKit.NY, false)


# ------------------------------------------------------------- details

## Door frame (and an open leaf) for an opening in the wall a->b.
static func door_trim(k: GeoKit, a: Vector3, b: Vector3, at: float, w: float, h: float, frame_mat: String, leaf_mat: String, swing: float, open_deg := 82.0) -> void:
	var dir := b - a
	dir.y = 0.0
	dir = dir.normalized()
	var nrm := dir.cross(Vector3.UP).normalized()
	var bas := Basis(dir, Vector3.UP, nrm)
	var c := a + dir * at
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + dir * (s * (w * 0.5 + 0.03)) + Vector3.UP * (h * 0.5)), Vector3(0.06, h, T + 0.04), frame_mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3.UP * (h + 0.03)), Vector3(w + 0.12, 0.06, T + 0.04), frame_mat, GeoKit.ALL, false)
	if leaf_mat == "" or swing == 0.0:
		return
	var sg := signf(swing)
	var th := deg_to_rad(open_deg)
	var ld := (dir * cos(th) + nrm * sg * sin(th)).normalized()
	var hinge := c - dir * (w * 0.5 - 0.02) + nrm * sg * (T * 0.5 + 0.02)
	var lb := Basis(ld, Vector3.UP, ld.cross(Vector3.UP))
	k.box_xf(Transform3D(lb, hinge + ld * ((w - 0.04) * 0.5) + Vector3.UP * ((h - 0.02) * 0.5)), Vector3(w - 0.04, h - 0.02, 0.045), leaf_mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(lb, hinge + ld * (w - 0.14) + Vector3.UP * 1.0 + lb.z * 0.05), Vector3(0.12, 0.02, 0.03), "l4_alu", GeoKit.ALL, false)


## Painted-over window on one face of the wall a->b (side +1 = the a->b x UP side).
static func black_window(k: GeoKit, a: Vector3, b: Vector3, at: float, w: float, sill: float, h: float, side: float, taped := false) -> void:
	var dir := b - a
	dir.y = 0.0
	dir = dir.normalized()
	var nrm := dir.cross(Vector3.UP).normalized() * side
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var c := a + dir * at + Vector3.UP * (sill + h * 0.5) + nrm * (T * 0.5)
	k.box_xf(Transform3D(bas, c + nrm * 0.008), Vector3(w, h, 0.016), "l4_blackglass", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + dir * (s * (w * 0.5 + 0.025)) + nrm * 0.02), Vector3(0.05, h + 0.1, 0.04), "l4_alu", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, c + Vector3.UP * (s * (h * 0.5 + 0.025)) + nrm * 0.02), Vector3(w + 0.1, 0.05, 0.04), "l4_alu", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3.UP * (-h * 0.5 - 0.06) + nrm * 0.06), Vector3(w + 0.16, 0.03, 0.12), "l4_alu", GeoKit.ALL, false)
	if taped:
		# paper and tape pressed over the glass from this side
		k.box_xf(Transform3D(bas, c + dir * (w * 0.5 - 0.03) + nrm * 0.019), Vector3(0.05, h * 0.9, 0.004), "l4_tape", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, c + Vector3.UP * (h * 0.5 - 0.04) + nrm * 0.019), Vector3(w * 0.85, 0.05, 0.004), "l4_tape", GeoKit.ALL, false)


static func label(parent: Node3D, text: String, p: Vector3, n: Vector3, px: float, col: Color, unshaded := false, vis := 14.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = not unshaded
	l.double_sided = false
	var z := n.normalized()
	var x := Vector3.UP.cross(z).normalized()
	l.basis = Basis(x, Vector3.UP, z)
	l.position = p + z * 0.012
	l.visibility_range_end = vis
	parent.add_child(l)
	return l


## Illuminated EXIT sign over a door (a, b = wall line; at = door centre).
static func exit_sign(k: GeoKit, node: Node3D, a: Vector3, b: Vector3, at: float, y: float, side: float) -> void:
	var dir := b - a
	dir.y = 0.0
	dir = dir.normalized()
	var nrm := dir.cross(Vector3.UP).normalized() * side
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var c := a + dir * at + Vector3.UP * y + nrm * (T * 0.5 + 0.05)
	k.box_xf(Transform3D(bas, c), Vector3(0.36, 0.17, 0.08), "l4_plastic", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + nrm * 0.041), Vector3(0.32, 0.13, 0.004), "l4_exitglow", GeoKit.ALL, false)
	label(node, "EXIT", c + nrm * 0.045, nrm, 0.0016, Color(0.9, 1.0, 0.92), true, 16.0)


# --------------------------------------------------------- stairwells

## Switchback stair enclosure in frame f (front/door wall at local z = 0).
## up = true: an office core from y0 to y0 + FH with doors on both floors.
## up = false: an exit stairway from y0 down to y0 - FH (door at the top).
## style: "core" | "old" | "dark" | "basement". skip: walls not to build
## ("l", "r", "b") when a neighbour already provides them.
## Returns {doors: [{a, b, at, y}], bottom: Vector3, top: Vector3}.
func stairwell(k: GeoKit, node: Node3D, f: Dictionary, y0: float, up: bool, style: String, skip: Array = []) -> Dictionary:
	var tread := "l4_stair_conc"
	var wmat := "l4_block"
	if style == "old":
		tread = "l4_oldwood"
		wmat = "l4_oldwall"
	var lo := y0 if up else y0 - FH
	var hi := y0 + FH + CH if up else y0 + CH
	var hgt := hi - (lo - 0.3)
	var res := {"doors": []}
	# enclosure walls
	var front_ops: Array = []
	if up:
		# one door per floor: lower at lx 1.2, upper at lx 3.6
		front_ops = [{"at": 1.2, "w": DOOR_W, "h": DOOR_H, "sill": 0.3}, {"at": 3.6, "w": DOOR_W, "h": DOOR_H, "sill": 0.3 + FH}]
	else:
		front_ops = [{"at": 1.2, "w": DOOR_W, "h": DOOR_H, "sill": 0.3 + FH}, {"at": 3.6, "w": 1.0, "h": 2.2, "sill": 0.3}]
	fwall(k, f, -T * 0.5, 0.0, SW + T * 0.5, 0.0, lo - 0.3, hgt, wmat, front_ops)
	if not skip.has("b"):
		fwall(k, f, -T * 0.5, SD, SW + T * 0.5, SD, lo - 0.3, hgt, wmat)
	if not skip.has("l"):
		fwall(k, f, 0.0, 0.0, 0.0, SD, lo - 0.3, hgt, wmat)
	if not skip.has("r"):
		fwall(k, f, SW, 0.0, SW, SD, lo - 0.3, hgt, wmat)
	var fa := fp(f, 0.0, 0.0, 0.0)
	var fb := fp(f, SW, 0.0, 0.0)
	var mid := y0 + (0.5 * FH if up else -0.5 * FH)
	if up:
		# flight A (left) rises to the mid landing; flight B (right) rises to the upper landing
		k.stairs(fp(f, 1.2, y0, LAND), f["v"], 2.3, FH * 0.5, 10, tread, RUN, true)
		fbox(k, f, Vector3(0, y0, LAND + 10 * RUN), Vector3(SW, mid, SD), tread)
		fbox(k, f, Vector3(2.4, y0, LAND), Vector3(SW, mid, LAND + 10 * RUN), wmat)
		k.stairs(fp(f, 3.6, mid, LAND + 10 * RUN), -f["v"], 2.3, FH * 0.5, 10, tread, RUN, true)
		fbox(k, f, Vector3(0, y0 + FH - 0.25, 0), Vector3(SW, y0 + FH, LAND), tread)
		fbox(k, f, Vector3(2.4 - 0.06, y0, LAND), Vector3(2.4 + 0.06, y0 + FH + 1.0, LAND + 10 * RUN), wmat)
		fbox(k, f, Vector3(0.0, y0 + FH, LAND - 0.05), Vector3(2.34, y0 + FH + 1.0, LAND + 0.05), "l4_rail")
		res["doors"] = [{"a": fa, "b": fb, "at": 1.2, "y": y0}, {"a": fa, "b": fb, "at": 3.6, "y": y0 + FH}]
		res["bottom"] = fp(f, 1.2, y0, 0.75)
		res["top"] = fp(f, 3.6, y0 + FH, 0.75)
	else:
		fbox(k, f, Vector3(0, y0 - 0.25, 0), Vector3(SW, y0, LAND), tread)
		fbox(k, f, Vector3(0, lo, 0), Vector3(2.4, mid, LAND + 10 * RUN), wmat)
		fbox(k, f, Vector3(0, lo, 0), Vector3(2.4, y0 - 0.25, LAND), wmat)
		k.stairs(fp(f, 1.2, mid, LAND + 10 * RUN), -f["v"], 2.3, FH * 0.5, 10, tread, RUN, true)
		fbox(k, f, Vector3(0, lo, LAND + 10 * RUN), Vector3(SW, mid, SD), tread)
		k.stairs(fp(f, 3.6, lo, LAND), f["v"], 2.3, FH * 0.5, 10, tread, RUN, true)
		fbox(k, f, Vector3(2.4, lo - 0.3, 0), Vector3(SW, lo, LAND), tread)
		fbox(k, f, Vector3(2.4 - 0.06, lo, LAND), Vector3(2.4 + 0.06, y0 + 1.0, LAND + 10 * RUN), wmat)
		fbox(k, f, Vector3(2.46, y0, LAND - 0.05), Vector3(SW, y0 + 1.0, LAND + 0.05), "l4_rail" if style != "old" else "l4_oldwood")
		# the way on: a doorway at the bottom that keeps going down into the dark
		fbox(k, f, Vector3(2.9, lo - 2.0, -1.4), Vector3(4.3, lo + 2.4, -1.25), "void_black")
		fbox(k, f, Vector3(2.9, lo - 2.0, -1.4), Vector3(3.0, lo + 2.4, 0.0), "void_black", GeoKit.ALL, false)
		fbox(k, f, Vector3(4.2, lo - 2.0, -1.4), Vector3(4.3, lo + 2.4, 0.0), "void_black", GeoKit.ALL, false)
		fbox(k, f, Vector3(2.9, lo + 2.2, -1.4), Vector3(4.3, lo + 2.4, 0.0), "void_black", GeoKit.ALL, false)
		for i in 5:
			fbox(k, f, Vector3(3.0, lo - 0.18 * (i + 1), -0.28 * (i + 1)), Vector3(4.2, lo - 0.18 * i, -0.28 * i), tread, GeoKit.ALL, false)
		res["doors"] = [{"a": fa, "b": fb, "at": 1.2, "y": y0}]
		res["bottom"] = fp(f, 3.6, lo, 0.75)
		res["top"] = fp(f, 2.4, y0, 0.75)
	# handrails along the flights (visual)
	var rail := "l4_brass" if style == "old" else "l4_rail"
	var ya := y0 if up else lo
	_rail(k, fp(f, 2.3, ya + (0.0 if up else FH * 0.5) + 0.9, LAND if up else LAND + 10 * RUN), fp(f, 2.3, ya + (FH * 0.5 if up else FH) + 0.9, LAND + 10 * RUN if up else LAND), rail)
	_rail(k, fp(f, 2.5, (y0 + FH * 0.5 if up else lo) + 0.9, LAND + 10 * RUN if up else LAND), fp(f, 2.5, (y0 + FH if up else mid) + 0.9, LAND if up else LAND + 10 * RUN), rail)
	if style == "old":
		for i in 9:
			var zz := LAND + 0.3 + i * 0.28
			var yy := mid + (FH * 0.5) * (1.0 - (zz - LAND) / (10 * RUN))
			fbox(k, f, Vector3(2.27, yy - 0.05, zz - 0.02), Vector3(2.31, yy + 0.88, zz + 0.02), "l4_oldwood", GeoKit.ALL, false)
	# landing lights
	var lamp := "l4_panel_warm" if style == "old" else "l4_panel"
	var lc := Color(1.0, 0.74, 0.46) if style == "old" else Color(0.92, 0.96, 1.0)
	var spots: Array = [Vector3(1.2, y0 + CH - 0.02, 0.75), Vector3(2.4, mid + CH - 0.02, LAND + 10 * RUN + 1.1)]
	if up:
		spots.append(Vector3(2.4, y0 + FH + CH - 0.02, 0.75))
	for i in spots.size():
		var s: Vector3 = spots[i]
		var dead := (style == "dark" and i > 0)
		var c := fp(f, s.x, s.y, s.z)
		k.panel(c, 0.6, 0.6, lamp, 100.0 if dead else 3.0 + i, 0.0)
		if not dead:
			lvl.lights.add_anchor(c + Vector3.DOWN * 0.75, lc, 1.1 if style == "old" else 1.3, 6.0, 0.0, str(node.get_meta("group", "")))
	# ceiling of the shaft
	fbox(k, f, Vector3(0, hi, 0), Vector3(SW, hi + 0.05, SD), "l4_ceiling", GeoKit.NY, false)
	return res


func _rail(k: GeoKit, a: Vector3, b: Vector3, mat: String) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z).normalized()
	if x.length() < 0.1:
		x = Vector3.RIGHT
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(0.05, 0.05, d.length()), mat, GeoKit.ALL, false)


## Lift shaft (2.4 x 2.4) in frame f with doors on the front (local z = 0) at
## each floor; one floor may hold an open car. Returns the open car centre or null.
func lift(k: GeoKit, node: Node3D, f: Dictionary, open_floor: int) -> Variant:
	var w := 2.4
	fwall(k, f, -T * 0.5, 0.0, w + T * 0.5, 0.0, -0.3, FH + 0.3, "l4_wall", [{"at": 1.2, "w": 1.1, "h": DOOR_H, "sill": 0.3}])
	fwall(k, f, -T * 0.5, 0.0, w + T * 0.5, 0.0, FH, FH, "l4_wall", [{"at": 1.2, "w": 1.1, "h": DOOR_H, "sill": 0.0}])
	var res: Variant = null
	fwall(k, f, w, 0.0, w, w, -0.3, FH * 2.0 + 0.3, "l4_wall")
	fwall(k, f, -T * 0.5, w, w + T * 0.5, w, -0.3, FH * 2.0 + 0.3, "l4_wall")
	for fl in 2:
		var y := fl * FH
		var opened := fl == open_floor
		# steel surround and leaves
		fbox(k, f, Vector3(0.5, y, -0.08), Vector3(0.62, y + DOOR_H + 0.12, -0.02), "l4_steel", GeoKit.ALL, false)
		fbox(k, f, Vector3(1.78, y, -0.08), Vector3(1.9, y + DOOR_H + 0.12, -0.02), "l4_steel", GeoKit.ALL, false)
		fbox(k, f, Vector3(0.5, y + DOOR_H, -0.08), Vector3(1.9, y + DOOR_H + 0.12, -0.02), "l4_steel", GeoKit.ALL, false)
		if opened:
			fbox(k, f, Vector3(0.1, y, 0.03), Vector3(0.66, y + DOOR_H, 0.07), "l4_steel", GeoKit.ALL, false)
			fbox(k, f, Vector3(1.74, y, 0.03), Vector3(2.3, y + DOOR_H, 0.07), "l4_steel", GeoKit.ALL, false)
			fbox(k, f, Vector3(0.06, y - 0.2, 0.06), Vector3(w - 0.06, y, w - 0.06), "l4_vinyl")
			fbox(k, f, Vector3(0.06, y + 2.45, 0.06), Vector3(w - 0.06, y + 2.5, w - 0.06), "l4_steel", GeoKit.NY, false)
			k.panel(fp(f, 1.2, y + 2.44, 1.2), 0.8, 0.8, "l4_panel", 7.0, 0.15)
			fbox(k, f, Vector3(0.08, y + 0.9, 0.3), Vector3(0.1, y + 1.05, 2.1), "l4_steel", GeoKit.ALL, false)
			lvl.lights.add_anchor(fp(f, 1.2, y + 2.1, 1.2), Color(0.95, 0.97, 1.0), 1.0, 4.5, 0.12, str(node.get_meta("group", "")))
			res = fp(f, 1.2, y + 1.1, 1.2)
		else:
			fbox(k, f, Vector3(0.62, y, -0.05), Vector3(1.19, y + DOOR_H, -0.01), "l4_steel")
			fbox(k, f, Vector3(1.21, y, -0.05), Vector3(1.78, y + DOOR_H, -0.01), "l4_steel")
		# call button plate
		fbox(k, f, Vector3(2.02, y + 1.0, -0.03), Vector3(2.12, y + 1.25, -0.01), "l4_steel", GeoKit.ALL, false)
		fbox(k, f, Vector3(2.05, y + 1.08, -0.035), Vector3(2.09, y + 1.12, -0.03), "l4_exitglow" if opened else "l4_dark", GeoKit.ALL, false)
	return res


# ---------------------------------------------------- almond water points

## Water cooler / vending machine / drinking fountain against a wall at floor
## point p, facing n. Returns the interactable box centre.
func dispenser(k: GeoKit, kind: String, p: Vector3, n: Vector3) -> Vector3:
	var x := Vector3.UP.cross(n).normalized()
	var b := Basis(x, Vector3.UP, n)
	match kind:
		"vending":
			var c := p + n * 0.42
			k.box_xf(Transform3D(b, c + Vector3.UP * 0.92), Vector3(0.92, 1.84, 0.78), "l4_vend")
			k.box_xf(Transform3D(b, c + n * 0.392 + Vector3.UP * 1.12 - x * 0.12), Vector3(0.58, 1.1, 0.01), "l4_vendfront", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c + n * 0.395 + Vector3.UP * 0.22 - x * 0.12), Vector3(0.58, 0.16, 0.012), "l4_dark", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c + n * 0.395 + Vector3.UP * 1.1 + x * 0.3), Vector3(0.16, 0.4, 0.012), "l4_steel", GeoKit.ALL, false)
			for row in 4:
				for col in 4:
					k.cylinder(c + n * 0.3 + Vector3.UP * (0.68 + row * 0.27) + x * (-0.35 + col * 0.15), 0.035, 0.2, "l4_bottle", 6, false)
			return c + Vector3.UP * 1.0 + n * 0.45
		"fountain":
			var c2 := p + n * 0.2 + Vector3.UP * 0.82
			k.box_xf(Transform3D(b, c2), Vector3(0.46, 0.2, 0.36), "l4_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c2 + Vector3.UP * 0.11 + n * 0.02), Vector3(0.36, 0.02, 0.26), "l4_dark", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c2 + Vector3.DOWN * 0.38 - n * 0.1), Vector3(0.16, 0.56, 0.12), "l4_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c2 + Vector3.UP * 0.16 + x * 0.12 - n * 0.06), Vector3(0.04, 0.1, 0.04), "l4_alu", GeoKit.ALL, false)
			return c2 + Vector3.UP * 0.1
		_:
			var c3 := p + n * 0.24
			k.box_xf(Transform3D(b, c3 + Vector3.UP * 0.52), Vector3(0.32, 1.04, 0.32), "l4_plastic")
			k.cylinder(c3 + Vector3.UP * 1.27, 0.14, 0.46, "l4_bottle", 12, false)
			k.cylinder(c3 + Vector3.UP * 1.06, 0.06, 0.04, "l4_plastic", 8, false)
			k.box_xf(Transform3D(b, c3 + Vector3.UP * 0.8 + n * 0.17), Vector3(0.2, 0.12, 0.04), "l4_beige", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c3 + Vector3.UP * 0.76 + n * 0.19 - x * 0.05), Vector3(0.03, 0.04, 0.04), "l4_red", GeoKit.ALL, false)
			k.box_xf(Transform3D(b, c3 + Vector3.UP * 0.76 + n * 0.19 + x * 0.05), Vector3(0.03, 0.04, 0.04), "l4_bottle", GeoKit.ALL, false)
			return c3 + Vector3.UP * 0.9
