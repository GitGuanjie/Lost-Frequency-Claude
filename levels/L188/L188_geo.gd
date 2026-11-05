extends RefCounted
## Level 188 geometry (static helpers called from L188.gd): the irregular white
## atrium and its evenly spaced windows, the pentagonal path, the birchwood
## circle and the moss, the glass-railed walkways and the bridge, the clinical
## corridor annex and its stairwell, the table and its objects, the pink-dress
## faceling and the window silhouettes. Edge frame: u runs along a wall from
## its first vertex, w points outward from the wall's inner face, y is up.

## Irregular nine-sided atrium, mean diameter ~48 m (page: ~45 m / 50 yards).
const V := [Vector2(23.0, -4.0), Vector2(19.5, 13.0), Vector2(1.0, 25.0), Vector2(-14.0, 19.0), Vector2(-24.5, 5.5),
	Vector2(-21.0, -11.0), Vector2(-9.5, -22.5), Vector2(6.0, -23.5), Vector2(18.5, -15.5)]
const ROWS := [1.0, 5.0, 9.0, 13.0, 17.0, 21.0, 25.0]
const WW := 1.5
const WH := 2.5
const H := 30.0
const AX := 1        # wall with the corridor annex behind it
const EN := 6        # wall holding the entry window
const BAL := 1.8     # walkway depth
const BU := 11.025   # bridge root along the annex wall
const AX_COLS := [3.525, 8.525, 13.525, 18.525]
## Mahogany doorways in the annex wall: ground A, ground B, walkway 8 m, walkway 16 m.
const DOORS := [[6.025, 0.0], [16.025, 0.0], [11.025, 8.0], [6.025, 16.0]]
const FIG := """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float alpha = 0.0;
void fragment() {
	float head = length((UV - vec2(0.5, 0.16)) * vec2(1.0, 1.3)) - 0.12;
	float body = max(abs(UV.x - 0.5) - (0.15 + 0.2 * smoothstep(0.24, 0.42, UV.y)), 0.27 - UV.y);
	ALBEDO = vec3(0.0);
	ALPHA = smoothstep(0.04, -0.03, min(head, body)) * alpha * 0.95;
}
"""


static func materials() -> void:
	MatLib.define("l188_concrete", {"albedo_a": Color(0.86, 0.865, 0.86), "albedo_b": Color(0.8, 0.805, 0.8), "pattern": 1,
		"pattern_scale": Vector2(1.8, 1.2), "grout_width": 0.006, "grout_color": Color(0.68, 0.69, 0.69), "tile_variation": 0.03,
		"noise_scale": 0.8, "stain_amount": 0.1, "stain_color": Color(0.72, 0.73, 0.73), "roughness_a": 0.88, "roughness_b": 0.96, "bump_strength": 0.3})
	MatLib.define("l188_deck", {"albedo_a": Color(0.62, 0.63, 0.64), "albedo_b": Color(0.58, 0.59, 0.6), "pattern": 1,
		"pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.006, "grout_color": Color(0.45, 0.46, 0.47), "roughness_a": 0.85})
	MatLib.define("l188_edge", {"albedo_a": Color(0.42, 0.44, 0.47), "albedo_b": Color(0.38, 0.4, 0.43), "metallic_value": 0.5, "roughness_a": 0.45})
	MatLib.define("l188_floor", {"albedo_a": Color(0.74, 0.745, 0.74), "albedo_b": Color(0.69, 0.695, 0.69), "pattern": 1,
		"pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.008, "grout_color": Color(0.58, 0.59, 0.59), "roughness_a": 0.8, "tile_variation": 0.02})
	MatLib.define("l188_paver", {"albedo_a": Color(0.6, 0.6, 0.58), "albedo_b": Color(0.55, 0.55, 0.53), "pattern": 14,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.4, 0.4, 0.39), "roughness_a": 0.85})
	MatLib.define("l188_moss_grass", {"albedo_a": Color(0.07, 0.17, 0.04), "albedo_b": Color(0.045, 0.11, 0.03), "pattern": 12,
		"pattern_color": Color(0.16, 0.26, 0.07), "pattern_strength": 0.6, "noise_scale": 0.22, "stain_amount": 0.4, "stain_color": Color(0.1, 0.12, 0.05), "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.8})
	MatLib.define("l188_wood_birch", {"albedo_a": Color(0.82, 0.74, 0.58), "albedo_b": Color(0.75, 0.66, 0.5), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.14), "grout_width": 0.003, "grout_color": Color(0.42, 0.35, 0.25), "roughness_a": 0.6, "roughness_b": 0.75})
	MatLib.define("l188_wood_dark", {"albedo_a": Color(0.2, 0.11, 0.065), "albedo_b": Color(0.15, 0.08, 0.05), "pattern": 3,
		"pattern_scale": Vector2(1.2, 0.12), "grout_width": 0.002, "grout_color": Color(0.08, 0.04, 0.02), "roughness_a": 0.35, "roughness_b": 0.5})
	MatLib.define("l188_mahogany", {"albedo_a": Color(0.29, 0.11, 0.065), "albedo_b": Color(0.23, 0.08, 0.045), "pattern": 3,
		"pattern_scale": Vector2(0.25, 1.6), "grout_width": 0.002, "grout_color": Color(0.12, 0.04, 0.02), "roughness_a": 0.3, "roughness_b": 0.45})
	MatLib.define("l188_blinds", {"albedo_a": Color(0.8, 0.72, 0.56), "albedo_b": Color(0.76, 0.68, 0.52), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.5, 0.44, 0.33), "pattern_strength": 0.6, "uv_rotate": 1.5708,
		"emission_color": Color(0.82, 0.74, 0.58), "emission_energy": 0.16, "roughness_a": 0.6})
	MatLib.define("l188_frame", {"albedo_a": Color(0.9, 0.9, 0.89), "albedo_b": Color(0.86, 0.86, 0.85), "roughness_a": 0.5})
	MatLib.define("l188_corr_wall", {"albedo_a": Color(0.92, 0.925, 0.93), "albedo_b": Color(0.89, 0.895, 0.9), "noise_scale": 0.6,
		"roughness_a": 0.55, "roughness_b": 0.65, "bump_strength": 0.15})
	MatLib.define("l188_corr_floor", {"albedo_a": Color(0.86, 0.865, 0.87), "albedo_b": Color(0.83, 0.835, 0.84), "pattern": 1,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.004, "grout_color": Color(0.7, 0.71, 0.72), "roughness_a": 0.22, "roughness_b": 0.3})
	MatLib.define("l188_door_white", {"albedo_a": Color(0.93, 0.93, 0.92), "albedo_b": Color(0.9, 0.9, 0.89), "roughness_a": 0.4})
	MatLib.define("l188_steel", {"albedo_a": Color(0.7, 0.72, 0.74), "albedo_b": Color(0.62, 0.64, 0.66), "metallic_value": 0.85, "roughness_a": 0.3})
	MatLib.define("l188_brass", {"albedo_a": Color(0.62, 0.46, 0.18), "albedo_b": Color(0.52, 0.38, 0.14), "metallic_value": 0.9, "roughness_a": 0.3})
	MatLib.define("l188_book", {"albedo_a": Color(0.3, 0.1, 0.08), "albedo_b": Color(0.24, 0.08, 0.06), "roughness_a": 0.7})
	MatLib.define("l188_photo", {"albedo_a": Color(0.52, 0.43, 0.3), "albedo_b": Color(0.36, 0.29, 0.2), "noise_scale": 9.0, "roughness_a": 0.4})
	MatLib.define("l188_porcelain", {"albedo_a": Color(0.88, 0.9, 0.94), "albedo_b": Color(0.3, 0.42, 0.7), "pattern": 10,
		"pattern_scale": Vector2(0.08, 0.08), "pattern_color": Color(0.22, 0.32, 0.62), "pattern_strength": 0.7, "roughness_a": 0.15})
	MatLib.define("l188_clay", {"albedo_a": Color(0.6, 0.32, 0.2), "albedo_b": Color(0.52, 0.27, 0.17), "roughness_a": 0.8})
	var rail := StandardMaterial3D.new()
	rail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rail.albedo_color = Color(0.55, 0.78, 0.72, 0.34)
	rail.roughness = 0.04
	rail.metallic_specular = 0.9
	MatLib.register("l188_glassrail", rail)
	var void_m := StandardMaterial3D.new()
	void_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	void_m.albedo_color = Color(0.1, 0.11, 0.13)
	MatLib.register("l188_void", void_m)
	var vac := StandardMaterial3D.new()
	vac.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vac.albedo_color = Color(0.9, 0.91, 0.93)
	MatLib.register("l188_vacant", vac)
	MatLib.register("l188_panel_sky", MatLib.panel(Color(0.93, 0.95, 1.0), 1.25))
	MatLib.register("l188_panel_harsh", MatLib.panel(Color(0.92, 0.96, 1.0), 2.6))


# ---------------------------------------------------------------- frames

static func edges() -> Array:
	var out := []
	for i in V.size():
		var p: Vector2 = V[i]
		var q: Vector2 = V[(i + 1) % V.size()]
		var a := Vector3(p.x, 0, p.y)
		var b := Vector3(q.x, 0, q.y)
		var d := (b - a).normalized()
		var n := Vector3(-d.z, 0, d.x)
		if n.dot(-(a + b) * 0.5) < 0.0:
			n = -n
		out.append({"a": a, "d": d, "n": n, "len": a.distance_to(b), "i": i})
	return out


## World point in an edge frame (w > 0 is inside the wall / beyond it).
static func ep(e: Dictionary, u: float, w: float, y: float) -> Vector3:
	return e["a"] + e["d"] * u - e["n"] * w + Vector3.UP * y


static func ebox(k: GeoKit, e: Dictionary, u0: float, u1: float, w0: float, w1: float, y0: float, y1: float, mat: String, collide := true) -> void:
	var d: Vector3 = e["d"]
	k.box_xf(Transform3D(Basis(d, Vector3.UP, d.cross(Vector3.UP)), ep(e, (u0 + u1) * 0.5, (w0 + w1) * 0.5, (y0 + y1) * 0.5)),
		Vector3(u1 - u0, y1 - y0, w1 - w0), mat, GeoKit.ALL, collide)


## Wall layer covering [u0,u1] x [y0,y1] between w0 and w1, minus holes [ua, ub, ya, yb].
static func holed(k: GeoKit, e: Dictionary, u0: float, u1: float, w0: float, w1: float, y0: float, y1: float, holes: Array, mat: String) -> void:
	var us := [u0, u1]
	for h in holes:
		us.append(clampf(h[0], u0, u1))
		us.append(clampf(h[1], u0, u1))
	us.sort()
	for i in us.size() - 1:
		var p: float = us[i]
		var q: float = us[i + 1]
		if q - p < 0.005:
			continue
		var ys := []
		for h in holes:
			if h[0] <= p + 0.001 and h[1] >= q - 0.001:
				ys.append([h[2], h[3]])
		ys.sort_custom(func(a, b): return a[0] < b[0])
		var y := y0
		for yy in ys:
			if yy[0] > y + 0.005:
				ebox(k, e, p, q, w0, w1, y, yy[0], mat)
			y = maxf(y, yy[1])
		if y1 > y + 0.005:
			ebox(k, e, p, q, w0, w1, y, y1, mat)


static func cols(L: float, sp: float) -> Array:
	var n := int((L - 2.8) / sp) + 1
	var out := []
	for i in n:
		out.append(L * 0.5 + (i - (n - 1) * 0.5) * sp)
	return out


# ----------------------------------------------------------------- atrium

## Every wall: a recessed front layer pierced by the window grid (and the annex
## doorways), a solid back layer. Returns window records {e, u, sill, pos}.
static func walls(k: GeoKit, es: Array, spacing: float, rows: int) -> Array:
	var wins := []
	for e in es:
		var L: float = e["len"]
		var holes := []
		var back := []
		for u in (AX_COLS if e["i"] == AX else cols(L, spacing)):
			for r in rows:
				var sill: float = ROWS[r]
				holes.append([u - WW * 0.5, u + WW * 0.5, sill, sill + WH])
				wins.append({"e": e["i"], "u": u, "sill": sill, "pos": ep(e, u, 0.0, sill + WH * 0.5), "st": "ord", "lift": 0.5})
		if e["i"] == AX:
			for dr in DOORS:
				var hh := [dr[0] - 0.6, dr[0] + 0.6, dr[1], dr[1] + 2.3]
				holes.append(hh)
				back.append(hh)
		holed(k, e, -0.6, L + 0.6, 0.0, 0.35, 0.0, H, holes, "l188_concrete")
		holed(k, e, -0.6, L + 0.6, 0.35, 0.65, 0.0, H, back, "l188_corr_wall" if e["i"] == AX else "l188_concrete")
	return wins


## Window contents by state: blinds (ord), blinds raised on a dim room (live).
## Entry and vacant windows are separate panes owned by the level.
static func faces(k: GeoKit, es: Array, wins: Array) -> void:
	for w in wins:
		var e: Dictionary = es[w["e"]]
		var u: float = w["u"]
		var s: float = w["sill"]
		var st: String = w["st"]
		var n: Vector3 = e["n"]
		var d: Vector3 = e["d"]
		if st == "ord":
			k.quad(ep(e, u, 0.33, s + WH * 0.5), n, d * WW * 0.5, Vector3.UP * WH * 0.5, "l188_blinds")
		elif st == "live":
			var bh: float = WH * (1.0 - float(w["lift"]))
			k.quad(ep(e, u, 0.32, s + WH - bh * 0.5), n, d * WW * 0.5, Vector3.UP * bh * 0.5, "l188_blinds")
			k.quad(ep(e, u, 0.34, s + (WH - bh) * 0.5), n, d * WW * 0.5, Vector3.UP * (WH - bh) * 0.5, "l188_void")
		else:
			continue
		k.quad(ep(e, u, 0.1, s + WH * 0.5), n, d * WW * 0.5, Vector3.UP * WH * 0.5, "glass")
		ebox(k, e, u - 0.025, u + 0.025, 0.07, 0.12, s, s + WH, "l188_frame", false)
		ebox(k, e, u - WW * 0.5, u + WW * 0.5, 0.07, 0.12, s + WH * 0.68 - 0.025, s + WH * 0.68 + 0.025, "l188_frame", false)


## Flat pane filling a window opening (entry glow, vacant emptiness).
static func pane(parent: Node3D, e: Dictionary, u: float, sill: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(WW, WH)
	m.mesh = q
	m.material_override = mat
	var n: Vector3 = e["n"]
	m.transform = Transform3D(Basis(Vector3.UP.cross(n), Vector3.UP, n), ep(e, u, 0.34, sill + WH * 0.5))
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m


static func fan(k: GeoKit, c: Vector3, r: float, n: int, mat: String) -> void:
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		k._tri_fan(c, c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r, Vector3.UP, mat)


static func seg(k: GeoKit, p: Vector3, q: Vector3, width: float, top: float, mat: String) -> void:
	var d := (q - p).normalized()
	k.box_xf(Transform3D(Basis(d, Vector3.UP, d.cross(Vector3.UP)), (p + q) * 0.5 + Vector3.UP * top * 0.5), Vector3(p.distance_to(q), top, width), mat)


static func shape(k: GeoKit, sh: Shape3D, pos: Vector3, surface: String) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = pos
	cs.set_meta("surface", surface)
	k.body.add_child(cs)


## Floor, moss, the pentagonal path with four perpendicular inroads, the circle.
static func ground(k: GeoKit) -> void:
	k.slab(-27, -27, 27, 27, 0.0, 0.3, "l188_floor", GeoKit.PY)
	var mp := []
	for i in 28:
		var a := TAU * i / 28.0
		mp.append(Vector3(cos(a), 0, sin(a)) * (15.2 + 1.3 * sin(a * 3.0 + 0.7) + 0.6 * sin(a * 7.0)) + Vector3.UP * 0.02)
	for i in 28:
		k._tri_fan(Vector3(0, 0.02, 0), mp[i], mp[(i + 1) % 28], Vector3.UP, "l188_moss_grass")
	var moss := CylinderShape3D.new()
	moss.radius = 15.5
	moss.height = 0.04
	shape(k, moss, Vector3.ZERO, "grass")
	var R := 11.5
	for i in 5:
		var a0 := -PI * 0.5 + i * TAU / 5.0
		var p := Vector3(cos(a0), 0, sin(a0)) * R
		seg(k, p, Vector3(cos(a0 + TAU / 5.0), 0, sin(a0 + TAU / 5.0)) * R, 1.7, 0.06, "l188_paver")
		k.box_xf(Transform3D(Basis(Vector3.UP, -a0), p + Vector3.UP * 0.03), Vector3(1.7, 0.06, 1.7), "l188_paver")
	for j in 4:
		var phi := j * PI * 0.5
		var best := 1e9
		for i in 5:
			var c := cos(phi - (-PI * 0.5 + i * TAU / 5.0 + PI / 5.0))
			if c > 0.01:
				best = minf(best, R * cos(PI / 5.0) / c)
		var dv := Vector3(cos(phi), 0, sin(phi))
		seg(k, dv * 2.5, dv * best, 1.4, 0.055, "l188_paver")
	fan(k, Vector3(0, 0.075, 0), 2.75, 40, "l188_wood_dark")
	fan(k, Vector3(0, 0.08, 0), 2.6, 40, "l188_wood_birch")
	var circ := CylinderShape3D.new()
	circ.radius = 2.7
	circ.height = 0.16
	shape(k, circ, Vector3.ZERO, "wood")
	k.panel(Vector3(0, H - 0.01, 0), 56.0, 56.0, "l188_panel_sky", 0.0, 0.0)


# --------------------------------------------------------------- walkways

static func miter(v: Vector3, n0: Vector3, n1: Vector3, w: float) -> Vector3:
	return v + (n0 + n1) * (w / (1.0 + n0.dot(n1)))


static func strip(k: GeoKit, e: Dictionary, u0: float, u1: float, y: float) -> void:
	ebox(k, e, u0, u1, -BAL, 0.02, y - 0.35, y, "l188_deck")


## Glass railing between floor points a and b: 1.1 m panel and a steel top rail.
static func rail(k: GeoKit, a: Vector3, b: Vector3, rails: Array) -> void:
	var d := b - a
	d.y = 0.0
	var L := d.length()
	if L < 0.05:
		return
	d /= L
	var bas := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	var c := (a + b) * 0.5
	k.box_xf(Transform3D(bas, c + Vector3.UP * 0.55), Vector3(L, 1.1, 0.03), "l188_glassrail")
	k.box_xf(Transform3D(bas, c + Vector3.DOWN * 0.16), Vector3(L, 0.32, 0.06), "l188_edge", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3.UP * 1.12), Vector3(L + 0.04, 0.05, 0.06), "l188_steel", GeoKit.ALL, false)
	rails.append([a, b])


static func hit_line(o: Vector3, dir: Vector3, a: Vector3, d: Vector3) -> Vector2:
	var den := dir.x * d.z - dir.z * d.x
	if absf(den) < 1e-6:
		return Vector2(1e9, 0)
	var ax := a.x - o.x
	var az := a.z - o.z
	return Vector2((ax * d.z - az * d.x) / den, (ax * dir.z - az * dir.x) / den)


## Walkway at 8 m (end of wall 0, the annex wall, start of wall 2; both ends
## open), walkway at 16 m along the annex wall, and the bridge from it across
## the atrium to a railed landing on the far wall. Returns walkable info.
static func walkways(k: GeoKit, es: Array, rails: Array) -> Dictionary:
	var e0: Dictionary = es[0]
	var e1: Dictionary = es[AX]
	var e2: Dictionary = es[2]
	var L0: float = e0["len"]
	var L1: float = e1["len"]
	var p1 := miter(e1["a"], e0["n"], e1["n"], BAL)
	var p2 := miter(e2["a"], e1["n"], e2["n"], BAL)
	strip(k, e0, L0 - 8.0, L0 + 2.0, 8.0)
	strip(k, e1, -2.0, L1 + 2.0, 8.0)
	strip(k, e2, -2.0, 9.0, 8.0)
	rail(k, ep(e0, L0 - 8.0, -BAL, 8.0), p1 + Vector3.UP * 8.0, rails)
	rail(k, p1 + Vector3.UP * 8.0, p2 + Vector3.UP * 8.0, rails)
	rail(k, p2 + Vector3.UP * 8.0, ep(e2, 9.0, -BAL, 8.0), rails)
	strip(k, e1, -2.0, L1 + 2.0, 16.0)
	rail(k, p1 + Vector3.UP * 16.0, ep(e1, BU - 0.92, -BAL, 16.0), rails)
	rail(k, ep(e1, BU + 0.92, -BAL, 16.0), p2 + Vector3.UP * 16.0, rails)
	# bridge
	var dir: Vector3 = e1["n"]
	var o := ep(e1, BU, -BAL + 0.05, 16.0)
	var best := Vector3(1e9, -1, 0)
	for e in es:
		if e["i"] == AX:
			continue
		var h := hit_line(o, dir, e["a"], e["d"])
		if h.x > 0.0 and h.y >= 0.0 and h.y <= e["len"] and h.x < best.x:
			best = Vector3(h.x, e["i"], h.y)
	var fe: Dictionary = es[int(best.y)]
	var side := dir.cross(Vector3.UP)
	var ends := []
	for s in [-0.92, 0.92]:
		var so: Vector3 = o + side * s
		var h2 := hit_line(so, dir, ep(fe, 0.0, -BAL, 0.0), fe["d"])
		ends.append([so, so + dir * h2.x, h2.y])
	var t_end := best.x - 0.15
	k.box_xf(Transform3D(Basis(dir, Vector3.UP, dir.cross(Vector3.UP)), o + dir * (t_end * 0.5 - 0.1) + Vector3.UP * (16.0 - 0.175)),
		Vector3(t_end + 0.2, 0.35, 1.84), "l188_deck")
	for en in ends:
		rail(k, en[0], en[1], rails)
	var su: float = best.z
	strip(k, fe, su - 3.2, su + 3.2, 16.0)
	var lo := minf(ends[0][2], ends[1][2])
	var hi := maxf(ends[0][2], ends[1][2])
	rail(k, ep(fe, su - 3.2, -BAL, 16.0), ep(fe, lo, -BAL, 16.0), rails)
	rail(k, ep(fe, hi, -BAL, 16.0), ep(fe, su + 3.2, -BAL, 16.0), rails)
	rail(k, ep(fe, su - 3.2, -BAL, 16.0), ep(fe, su - 3.2, 0.0, 16.0), rails)
	rail(k, ep(fe, su + 3.2, -BAL, 16.0), ep(fe, su + 3.2, 0.0, 16.0), rails)
	return {"o": o, "dir": dir, "len": t_end, "far": int(best.y), "fu": su, "L0": L0}


## Mahogany door frame; open = leaf swung into the corridor, else a closed leaf.
static func door(k: GeoKit, e: Dictionary, u: float, y: float, open: bool) -> void:
	ebox(k, e, u - 0.7, u - 0.6, -0.05, 0.36, y, y + 2.4, "l188_mahogany", false)
	ebox(k, e, u + 0.6, u + 0.7, -0.05, 0.36, y, y + 2.4, "l188_mahogany", false)
	ebox(k, e, u - 0.7, u + 0.7, -0.05, 0.36, y + 2.3, y + 2.4, "l188_mahogany", false)
	if open:
		ebox(k, e, u + 0.62, u + 1.78, 0.66, 0.71, y, y + 2.28, "l188_mahogany")
	else:
		ebox(k, e, u - 0.6, u + 0.6, -0.02, 0.0, y, y + 2.3, "l188_mahogany")
		ebox(k, e, u + 0.42, u + 0.48, -0.08, -0.02, y + 1.0, y + 1.06, "l188_brass", false)


# ------------------------------------------------------------------ annex

## Clinical corridors on floors 0 / 8 / 16 behind the annex wall, a switchback
## stairwell, locked white doors, one blank white room, harsh panels.
## Returns locked-door positions (world) for interactables.
static func annex(lvl, k: GeoKit, e: Dictionary) -> Array:
	var L: float = e["len"]
	var d: Vector3 = e["d"]
	var locked := []
	for f in [0.0, 8.0, 16.0]:
		ebox(k, e, 0.7, L - 0.7, 0.65, 3.0, f - 0.3, f, "l188_corr_floor")
		ebox(k, e, 0.7, L - 0.7, 0.65, 3.0, f + 3.0, f + 3.3, "l188_corr_wall", false)
		var u := 2.0
		while u < L - 1.5:
			k.panel(ep(e, u, 1.82, f + 2.995), 0.62, 0.62, "l188_panel_harsh", u, 0.0)
			lvl.lights.add_anchor(ep(e, u, 1.82, f + 2.4), Color(0.9, 0.95, 1.0), 1.0, 3.6, 0.0, "annex")
			u += 3.6
		for du in [2.6, 9.0, 18.4]:
			if f == 8.0 and du == 2.6:
				continue
			ebox(k, e, du - 0.46, du + 0.46, 2.94, 3.0, f, f + 2.15, "l188_door_white", false)
			ebox(k, e, du + 0.3, du + 0.36, 2.88, 2.94, f + 1.0, f + 1.06, "l188_steel", false)
			locked.append(ep(e, du, 2.6, f + 1.0))
	ebox(k, e, 0.4, 0.7, 0.65, 3.3, 0.0, 19.6, "l188_corr_wall")
	ebox(k, e, L - 0.7, L - 0.4, 0.65, 3.3, 0.0, 19.6, "l188_corr_wall")
	holed(k, e, 0.7, L - 0.7, 3.0, 3.3, 0.0, 19.3, [[12.15, 13.35, 0.0, 2.3], [12.15, 13.35, 8.0, 10.3], [12.15, 13.35, 16.0, 18.3],
		[4.4, 5.6, 8.0, 10.3]], "l188_corr_wall")
	ebox(k, e, 0.4, L - 0.4, 0.65, 3.3, 19.3, 19.6, "l188_corr_wall")
	# stairwell u 12..21, lanes w 3.3..4.7 and 4.9..6.3
	ebox(k, e, 11.7, 12.0, 3.3, 6.6, 0.0, 19.6, "l188_corr_wall")
	ebox(k, e, 21.0, 21.3, 3.3, 6.6, 0.0, 19.6, "l188_corr_wall")
	ebox(k, e, 11.7, 21.3, 6.3, 6.6, 0.0, 19.6, "l188_corr_wall")
	ebox(k, e, 11.7, 21.3, 3.3, 6.6, 19.3, 19.6, "l188_corr_wall")
	ebox(k, e, 13.5, 19.5, 4.7, 4.9, 0.0, 19.3, "l188_corr_wall")
	ebox(k, e, 12.0, 21.0, 3.3, 6.3, -0.3, 0.0, "l188_corr_floor")
	for y in [8.0, 16.0]:
		ebox(k, e, 12.0, 13.5, 3.3, 6.3, y - 0.3, y, "l188_corr_floor")
	for y in [4.0, 12.0]:
		ebox(k, e, 19.5, 21.0, 3.3, 6.3, y - 0.3, y, "l188_corr_floor")
	for y in [0.0, 8.0]:
		k.stairs(ep(e, 13.5, 4.0, y), d, 1.4, 4.0, 20, "l188_corr_floor", 0.3, true)
		k.stairs(ep(e, 19.5, 5.6, y + 4.0), -d, 1.4, 4.0, 20, "l188_corr_floor", 0.3, true)
	for y in [0.0, 4.0, 8.0, 12.0, 16.0]:
		var uu := 12.75 if int(y) % 8 == 0 else 20.25
		k.quad(ep(e, uu, 6.29, y + 2.5), e["n"], d * 0.32, Vector3.UP * 0.12, "l188_panel_harsh", Vector2(y, 0), true)
		lvl.lights.add_anchor(ep(e, uu, 4.8, y + 2.6), Color(0.9, 0.95, 1.0), 1.8, 4.2, 0.0, "annex")
	# the blank room on floor 8: u 2.6..7.4, w 3.3..7.3
	ebox(k, e, 2.6, 7.4, 3.3, 7.3, 7.7, 8.0, "l188_concrete")
	ebox(k, e, 2.6, 7.4, 3.3, 7.3, 11.0, 11.3, "l188_concrete", false)
	ebox(k, e, 2.3, 7.7, 7.3, 7.6, 7.7, 11.3, "l188_concrete")
	ebox(k, e, 2.3, 2.6, 3.3, 7.6, 7.7, 11.3, "l188_concrete")
	ebox(k, e, 7.4, 7.7, 3.3, 7.6, 7.7, 11.3, "l188_concrete")
	k.panel(ep(e, 5.0, 5.3, 10.995), 0.62, 0.62, "l188_panel_harsh", 3.0, 0.0)
	lvl.lights.add_anchor(ep(e, 5.0, 5.3, 10.4), Color(0.92, 0.95, 1.0), 1.4, 5.5, 0.0, "annex")
	ebox(k, e, 5.6, 5.65, 3.31, 4.45, 8.0, 10.28, "l188_door_white")
	return locked


# ------------------------------------------------------------------ props

static func prim(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m


static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 16
	return c


## The wooden table with the gramophone, a novel and old photographs.
static func table(parent: Node3D) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var k := GeoKit.new(n, "Table")
	k.box(Vector3(0, 0.75, 0), Vector3(1.6, 0.06, 0.9), "l188_wood_dark", GeoKit.ALL, false)
	for sx in [-0.72, 0.72]:
		for sz in [-0.37, 0.37]:
			k.box(Vector3(sx, 0.36, sz), Vector3(0.07, 0.72, 0.07), "l188_wood_dark", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(0, 0.39, 0)), Vector3(1.6, 0.78, 0.9), "wood")
	k.box(Vector3(-0.38, 0.85, 0.05), Vector3(0.36, 0.14, 0.36), "l188_wood_dark", GeoKit.ALL, false)
	k.cylinder(Vector3(-0.38, 0.926, 0.05), 0.15, 0.012, "l188_book", 18, false)
	k.box(Vector3(0.4, 0.797, -0.12), Vector3(0.16, 0.035, 0.23), "l188_book", GeoKit.ALL, false)
	for i in 3:
		k.box_xf(Transform3D(Basis(Vector3.UP, 0.3 * i - 0.2), Vector3(0.15 + i * 0.16, 0.782, 0.22)), Vector3(0.1, 0.004, 0.14), "l188_photo", GeoKit.ALL, false)
	k.commit()
	var horn := prim(n, cyl(0.24, 0.025, 0.5), MatLib.get_mat("l188_brass"), Vector3(-0.42, 1.12, -0.12))
	horn.rotation = Vector3(-0.85, 0.0, 0.25)
	return n


## The alarm clock that sits in the wooden circle.
static func clock(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	var body := BoxMesh.new()
	body.size = Vector3(0.12, 0.12, 0.06)
	prim(n, body, MatLib.get_mat("l188_steel"), Vector3(0, 0.08, 0))
	var face := CylinderMesh.new()
	face.top_radius = 0.045
	face.bottom_radius = 0.045
	face.height = 0.005
	prim(n, face, MatLib.get_mat("l188_frame"), Vector3(0, 0.09, 0.031)).rotation.x = PI * 0.5
	var bell := SphereMesh.new()
	bell.radius = 0.032
	bell.height = 0.05
	for s in [-1.0, 1.0]:
		prim(n, bell, MatLib.get_mat("l188_brass"), Vector3(s * 0.04, 0.155, 0))
	return n


## Arbitrarily placed vases, ornaments, photographs and books.
static func clutter(k: GeoKit, parent: Node3D, r: RandomNumberGenerator) -> void:
	for i in 7:
		var a := r.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * r.randf_range(4.0, 19.0)
		var m := "l188_porcelain" if r.randf() < 0.6 else "l188_clay"
		var h := r.randf_range(0.25, 0.5)
		k.cylinder(p + Vector3.UP * (h * 0.5 + 0.03), r.randf_range(0.08, 0.13), h, m, 12)
		k.cylinder(p + Vector3.UP * (h + 0.07), 0.045, 0.09, m, 10, false)
	for i in 3:
		var a := r.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * r.randf_range(5.0, 18.0)
		var b := Basis(Vector3.UP, r.randf() * TAU)
		var y := 0.03
		for j in 2 + r.randi() % 3:
			var s := Vector3(r.randf_range(0.16, 0.24), r.randf_range(0.03, 0.06), r.randf_range(0.22, 0.3))
			k.box_xf(Transform3D(b * Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), p + Vector3.UP * (y + s.y * 0.5)), s, "l188_book", GeoKit.ALL, false)
			y += s.y
	for i in 3:
		var a := r.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * r.randf_range(6.0, 17.0)
		var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, -0.25)
		k.box_xf(Transform3D(b, p + Vector3.UP * 0.24), Vector3(0.34, 0.44, 0.025), "l188_wood_dark", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, p + Vector3.UP * 0.24 + b.z * 0.014), Vector3(0.26, 0.34, 0.004), "l188_photo", GeoKit.ALL, false)


## Pink-dress faceling: featureless pale head, pink dress, a blade (log 4).
static func faceling(parent: Node3D) -> Node3D:
	var f := Node3D.new()
	parent.add_child(f)
	var pink := MatLib.standard(Color(0.86, 0.46, 0.62), 0.85)
	var skin := MatLib.standard(Color(0.86, 0.79, 0.73), 0.6)
	prim(f, cyl(0.17, 0.44, 0.98), pink, Vector3(0, 0.55, 0))
	prim(f, cyl(0.15, 0.17, 0.42), pink, Vector3(0, 1.25, 0))
	prim(f, cyl(0.045, 0.05, 0.12), skin, Vector3(0, 1.5, 0))
	var head := SphereMesh.new()
	head.radius = 0.115
	head.height = 0.27
	prim(f, head, skin, Vector3(0, 1.66, 0))
	for s in [-1.0, 1.0]:
		var arm := CapsuleMesh.new()
		arm.radius = 0.042
		arm.height = 0.62
		prim(f, arm, skin, Vector3(s * 0.21, 1.14, 0.02)).rotation.z = s * 0.12
		prim(f, cyl(0.035, 0.04, 0.1), skin, Vector3(s * 0.09, 0.05, 0))
	var bl := BoxMesh.new()
	bl.size = Vector3(0.02, 0.24, 0.035)
	prim(f, bl, MatLib.standard(Color(0.7, 0.72, 0.75), 0.25, 0.9), Vector3(0.25, 0.76, 0.06))
	return f


static func figure(parent: Node3D, w: float, h: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	m.mesh = q
	var sh := Shader.new()
	sh.code = FIG
	var mat := ShaderMaterial.new()
	mat.shader = sh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	parent.add_child(m)
	return m
