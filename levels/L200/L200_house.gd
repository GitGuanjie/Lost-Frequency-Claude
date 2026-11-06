extends RefCounted
## Level 200 "Home" — the house (static builders). SOURCE: "It's a house";
## it used to be beautiful; now the paint chips and the walls are too thin; it
## has not taken shape yet; remembering (walks with Mother, birthdays, not
## thinking about living and dying) is meant to make it better.
## ADAPTATION: the floor plan (a 10 x 9 m two-storey centre-hall house with a
## real 16-riser stair and an open gallery), the furniture, and the split of
## rooms into three memory groups: g0 walks (hall, living room, den), g1
## birthday (dining room, kitchen), g2 childhood (bedrooms, bathroom). The
## spare room never takes shape (bare studs). No basement or attic: the page
## gives the house neither (the basement on the page is the school's).
##
## Plan (x east, z south toward Main Street). Ground floor top G, upper U.
##   ground: living -4.9..-1.1 x 0..4.4 | hall -1.1..1.1 | den 1.1..4.9 x 0.3..4.4
##           dining -4.9..-1.1 x -4.4..0 |   (stair)    | kitchen 1.1..4.9 x -4.4..0.3
##   upper:  child -4.9..-1.1 x 0.4..4.4 | gallery hall | spare 1.1..4.9 x 0.4..4.4
##           parents -4.9..-1.1 x -4.4..0.4 |           | bath 1.1..4.9 x -4.4..0.4

const FX := preload("res://levels/L200/L200_fx.gd")
const G := 0.54
const C1 := 3.24
const U := 3.54
const C2 := 6.09
const EAVE := 6.3
const STAIR_X0 := 0.04
const STAIR_X1 := 1.02
const STAIR_Z0 := 3.2      # bottom riser
const STAIR_RUN := 0.26
const STAIR_N := 16
const STAIR_TOP := STAIR_Z0 - STAIR_RUN * STAIR_N   # -0.96

## Openings in world coordinates: line "x"/"z" at coord c, centred at "at"
## along the other axis, on the floor at height y. sill/w/h in metres.
const OPS := [
	{"line": "z", "c": 4.5, "at": -3.0, "y": G, "sill": 0.75, "w": 1.4, "h": 1.5, "win": true},
	{"line": "z", "c": 4.5, "at": -0.1, "y": G, "sill": 0.0, "w": 0.95, "h": 2.1, "door": "front"},
	{"line": "z", "c": 4.5, "at": 3.0, "y": G, "sill": 0.75, "w": 1.4, "h": 1.5, "win": true},
	{"line": "z", "c": 4.5, "at": -2.6, "y": U, "sill": 0.9, "w": 1.1, "h": 1.3, "win": true},
	{"line": "z", "c": 4.5, "at": -0.45, "y": U, "sill": 0.9, "w": 0.7, "h": 1.1, "win": true},
	{"line": "z", "c": 4.5, "at": 3.0, "y": U, "sill": 0.9, "w": 1.1, "h": 1.3, "win": true},
	{"line": "z", "c": -4.5, "at": -3.0, "y": G, "sill": 0.75, "w": 1.4, "h": 1.5, "win": true},
	{"line": "z", "c": -4.5, "at": -0.4, "y": G, "sill": 0.9, "w": 0.7, "h": 1.1, "win": true},
	{"line": "z", "c": -4.5, "at": 1.75, "y": G, "sill": 0.0, "w": 0.85, "h": 2.05, "door": "back"},
	{"line": "z", "c": -4.5, "at": 3.4, "y": G, "sill": 1.0, "w": 1.2, "h": 1.0, "win": true},
	{"line": "z", "c": -4.5, "at": -3.0, "y": U, "sill": 0.9, "w": 1.2, "h": 1.3, "win": true},
	{"line": "z", "c": -4.5, "at": -0.4, "y": U, "sill": 0.9, "w": 0.7, "h": 1.1, "win": true},
	{"line": "z", "c": -4.5, "at": 3.6, "y": U, "sill": 1.3, "w": 0.8, "h": 0.7, "win": true},
	{"line": "x", "c": -5.0, "at": 2.2, "y": G, "sill": 0.75, "w": 1.1, "h": 1.5, "win": true},
	{"line": "x", "c": -5.0, "at": -2.2, "y": G, "sill": 0.75, "w": 1.1, "h": 1.5, "win": true},
	{"line": "x", "c": -5.0, "at": 1.6, "y": U, "sill": 0.9, "w": 1.0, "h": 1.3, "win": true},
	{"line": "x", "c": 5.0, "at": 2.4, "y": G, "sill": 0.75, "w": 1.1, "h": 1.5, "win": true},
	{"line": "x", "c": 5.0, "at": 2.4, "y": U, "sill": 0.9, "w": 1.0, "h": 1.3, "win": true},
	{"line": "x", "c": 5.0, "at": -2.2, "y": G, "sill": 1.0, "w": 0.9, "h": 1.0, "win": true},
	# interior
	{"line": "x", "c": -1.1, "at": 2.2, "y": G, "sill": 0.0, "w": 1.5, "h": 2.25},
	{"line": "x", "c": -1.1, "at": -2.2, "y": G, "sill": 0.0, "w": 1.4, "h": 2.25},
	{"line": "x", "c": -1.1, "at": 1.4, "y": U, "sill": 0.0, "w": 0.9, "h": 2.05},
	{"line": "x", "c": -1.1, "at": -2.4, "y": U, "sill": 0.0, "w": 0.9, "h": 2.05},
	{"line": "x", "c": 1.1, "at": 3.8, "y": G, "sill": 0.0, "w": 0.85, "h": 2.05},
	{"line": "x", "c": 1.1, "at": -2.6, "y": G, "sill": 0.0, "w": 0.9, "h": 2.05},
	{"line": "x", "c": 1.1, "at": 3.8, "y": U, "sill": 0.0, "w": 0.85, "h": 2.05},
	{"line": "x", "c": 1.1, "at": -2.6, "y": U, "sill": 0.0, "w": 0.8, "h": 2.05},
	{"line": "z", "c": 0.0, "at": -3.0, "y": G, "sill": 0.0, "w": 1.6, "h": 2.25},
	{"line": "z", "c": 0.3, "at": 3.0, "y": G, "sill": 0.0, "w": 0.85, "h": 2.05},
]

## id, rect [x0,z0,x1,z1], floor y, wall height, wall material, floor material
const ROOMS := [
	["hall", [-1.1, -4.4, 1.1, 4.4], G, C2 - G, "l200_wall_g0", "l200_oak"],
	["living", [-4.9, 0.0, -1.1, 4.4], G, C1 - G, "l200_wall_g0", "l200_oak"],
	["dining", [-4.9, -4.4, -1.1, 0.0], G, C1 - G, "l200_wall_g1", "l200_oak"],
	["den", [1.1, 0.3, 4.9, 4.4], G, C1 - G, "l200_wall_g0", "l200_oak"],
	["kitchen", [1.1, -4.4, 4.9, 0.3], G, C1 - G, "l200_wall_g1", "l200_tile"],
	["child", [-4.9, 0.4, -1.1, 4.4], U, C2 - U, "l200_wall_g2", "l200_carpet"],
	["parents", [-4.9, -4.4, -1.1, 0.4], U, C2 - U, "l200_wall_g2", "l200_carpet"],
	["bath", [1.1, -4.4, 4.9, 0.4], U, C2 - U, "l200_wall_g2", "l200_tile"],
	["spare", [1.1, 0.4, 4.9, 4.4], U, C2 - U, "", "l200_stud_wood"],
]


static func _ops_for(line: String, c: float, base: float, height: float, a0: float, a1: float) -> Array:
	var out: Array = []
	for op in OPS:
		if op["line"] != line or absf(float(op["c"]) - c) > 0.15:
			continue
		if float(op["at"]) < a0 + 0.1 or float(op["at"]) > a1 - 0.1:
			continue
		var y: float = op["y"]
		if y < base - 0.01 or y >= base + height - 0.01:
			continue
		out.append({"at": float(op["at"]) - a0, "w": op["w"], "h": op["h"], "sill": y - base + float(op["sill"])})
	return out


## Finish walls of one room (0.06 thick, inset into the rect), with openings.
static func _room_walls(k: GeoKit, r: Array, y: float, h: float, mat: String) -> void:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	k.wall(Vector3(x0, y, z0 + 0.03), Vector3(x1, y, z0 + 0.03), h, 0.06, mat, _ops_for("z", z0, y, h, x0, x1))
	k.wall(Vector3(x0, y, z1 - 0.03), Vector3(x1, y, z1 - 0.03), h, 0.06, mat, _ops_for("z", z1, y, h, x0, x1))
	k.wall(Vector3(x0 + 0.03, y, z0 + 0.06), Vector3(x0 + 0.03, y, z1 - 0.06), h, 0.06, mat, _ops_for("x", x0, y, h, z0 + 0.06, z1 - 0.06))
	k.wall(Vector3(x1 - 0.03, y, z0 + 0.06), Vector3(x1 - 0.03, y, z1 - 0.06), h, 0.06, mat, _ops_for("x", x1, y, h, z0 + 0.06, z1 - 0.06))
	# baseboards
	var bm := "l200_trim"
	k.box_mm(Vector3(x0 + 0.06, y, z0 + 0.06), Vector3(x1 - 0.06, y + 0.1, z0 + 0.075), bm, GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 0.06, y, z1 - 0.075), Vector3(x1 - 0.06, y + 0.1, z1 - 0.06), bm, GeoKit.ALL, false)


static func shell(k: GeoKit) -> void:
	# foundation and exterior skin (lap siding, peeling)
	k.box_mm(Vector3(-5.02, -0.1, -4.52), Vector3(5.02, 0.5, 4.52), "l200_concrete")
	var sb := 0.5
	# one wall per storey: GeoKit.wall cannot stack openings that overlap in plan
	for seg in [[sb, U - sb], [U, EAVE - U]]:
		var y: float = seg[0]
		var h: float = seg[1]
		k.wall(Vector3(-5.0, y, 4.45), Vector3(5.0, y, 4.45), h, 0.1, "l200_siding", _ops_for("z", 4.5, y, h, -5.0, 5.0))
		k.wall(Vector3(-5.0, y, -4.45), Vector3(5.0, y, -4.45), h, 0.1, "l200_siding", _ops_for("z", -4.5, y, h, -5.0, 5.0))
		k.wall(Vector3(-4.95, y, -4.4), Vector3(-4.95, y, 4.4), h, 0.1, "l200_siding", _ops_for("x", -5.0, y, h, -4.4, 4.4))
		k.wall(Vector3(4.95, y, -4.4), Vector3(4.95, y, 4.4), h, 0.1, "l200_siding", _ops_for("x", 5.0, y, h, -4.4, 4.4))
	# corner boards and a band between storeys
	for c in [Vector2(-5.0, -4.5), Vector2(5.0, -4.5), Vector2(-5.0, 4.5), Vector2(5.0, 4.5)]:
		k.box(Vector3(c.x, (sb + EAVE) * 0.5, c.y), Vector3(0.18, EAVE - sb, 0.18), "l200_trim", GeoKit.ALL, false)
	for zz in [4.52, -4.52]:
		k.box(Vector3(0, U - 0.15, zz), Vector3(10.1, 0.16, 0.04), "l200_trim", GeoKit.ALL, false)
	# rooms: floors, ceilings, finish walls
	for rd in ROOMS:
		var r: Array = rd[1]
		var y: float = rd[2]
		if rd[0] == "hall":
			continue
		k.box_mm(Vector3(r[0], y - 0.04, r[1]), Vector3(r[2], y, r[3]), rd[5], GeoKit.PY)
		var ctop: float = C1 if y < 1.0 else C2
		k.box_mm(Vector3(r[0], ctop, r[1]), Vector3(r[2], ctop + 0.04, r[3]), "l200_ceiling", GeoKit.NY, false)
		if rd[4] != "":
			_room_walls(k, r, y, ctop - y, rd[4])
	# upper floor slab under the upper rooms (between C1 and U)
	for r in [[-4.9, -4.4, -1.1, 4.4], [1.1, -4.4, 4.9, 4.4]]:
		k.box_mm(Vector3(r[0], C1 + 0.04, r[1]), Vector3(r[2], U - 0.04, r[3]), "l200_concrete", GeoKit.ALL)
	# hall: ground floor, gallery floor around the stair opening, ceilings
	k.box_mm(Vector3(-1.1, G - 0.04, -4.4), Vector3(1.1, G, 4.4), "l200_oak", GeoKit.PY)
	for r in [[-1.1, -4.4, STAIR_X0, 4.4], [STAIR_X0, -4.4, 1.1, STAIR_TOP], [STAIR_X0, STAIR_Z0, 1.1, 4.4]]:
		k.box_mm(Vector3(r[0], C1, r[1]), Vector3(r[2], C1 + 0.04, r[3]), "l200_ceiling", GeoKit.NY | GeoKit.SIDES)
		k.box_mm(Vector3(r[0], C1 + 0.04, r[1]), Vector3(r[2], U, r[3]), "l200_oak", GeoKit.PY | GeoKit.SIDES)
	k.box_mm(Vector3(-1.1, C2, -4.4), Vector3(1.1, C2 + 0.04, 4.4), "l200_ceiling", GeoKit.NY, false)
	_room_walls(k, [-1.1, -4.4, 1.1, 4.4], G, U - G, "l200_wall_g0")
	_room_walls(k, [-1.1, -4.4, 1.1, 4.4], U, C2 - U, "l200_wall_g0")
	k.box_mm(Vector3(-5.1, C2 + 0.04, -4.6), Vector3(5.1, C2 + 0.2, 4.6), "l200_concrete", GeoKit.PY, false)
	_stair(k)
	_roof(k)
	_trim_openings(k)


static func _stair(k: GeoKit) -> void:
	var w := STAIR_X1 - STAIR_X0
	var cx := (STAIR_X0 + STAIR_X1) * 0.5
	k.stairs(Vector3(cx, G, STAIR_Z0), Vector3(0, 0, -1), w, U - G, STAIR_N, "l200_oak", STAIR_RUN)
	# collision under the ramp so the stair block is solid from the side
	var segs := 4
	for i in segs:
		var za := STAIR_Z0 - (STAIR_Z0 - STAIR_TOP) * float(i) / segs
		var zb := STAIR_Z0 - (STAIR_Z0 - STAIR_TOP) * float(i + 1) / segs
		var top := G + (U - G) * float(i) / segs - 0.18
		if top > G + 0.05:
			k.add_box_shape(Transform3D(Basis(), Vector3(cx, (G + top) * 0.5, (za + zb) * 0.5)), Vector3(w, top - G, za - zb), "wood")
	# skirt board, newel post, handrail on the open (west) side
	var a := Vector3(STAIR_X0 - 0.03, G + 0.95, STAIR_Z0 + 0.1)
	var b := Vector3(STAIR_X0 - 0.03, U + 0.95, STAIR_TOP)
	_stick(k, a, b, 0.06, "l200_wood_dark")
	k.box(Vector3(STAIR_X0 - 0.03, G + 0.55, STAIR_Z0 + 0.12), Vector3(0.1, 1.1, 0.1), "l200_wood_dark")
	for i in range(1, STAIR_N, 2):
		var z := STAIR_Z0 - STAIR_RUN * (i + 0.5)
		var ys := G + (U - G) * float(i + 1) / STAIR_N
		k.box(Vector3(STAIR_X0 + 0.02, ys + 0.45, z), Vector3(0.035, 0.9, 0.035), "l200_trim", GeoKit.ALL, false)
	# gallery railing around the opening upstairs (visible, solid)
	for seg in [[Vector3(STAIR_X0 - 0.05, U, STAIR_TOP + 0.05), Vector3(STAIR_X0 - 0.05, U, STAIR_Z0)], [Vector3(STAIR_X0, U, STAIR_Z0 + 0.03), Vector3(1.08, U, STAIR_Z0 + 0.03)]]:
		var p0: Vector3 = seg[0]
		var p1: Vector3 = seg[1]
		var d := p1 - p0
		var n := int(d.length() / 0.14)
		for j in n + 1:
			k.box(p0 + d * (float(j) / n) + Vector3(0, 0.46, 0), Vector3(0.035, 0.92, 0.035), "l200_trim", GeoKit.ALL, false)
		_stick(k, p0 + Vector3(0, 0.95, 0), p1 + Vector3(0, 0.95, 0), 0.07, "l200_wood_dark")
		k.add_box_shape(Transform3D(Basis(), (p0 + p1) * 0.5 + Vector3(0, 0.5, 0)), Vector3(maxf(absf(d.x), 0.08), 1.0, maxf(absf(d.z), 0.08)), "wood")


static func _stick(k: GeoKit, a: Vector3, b: Vector3, th: float, mat: String, col := false) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(th, th, d.length()), mat, GeoKit.ALL, col)


static func _roof(k: GeoKit) -> void:
	var ridge := EAVE + 2.5
	for s in [-1.0, 1.0]:
		var lo := Vector3(0, EAVE - 0.22, s * 4.95)
		var hi := Vector3(0, ridge, 0)
		var d := hi - lo
		var z := d.normalized()
		var y := z.cross(Vector3.RIGHT).normalized()
		if y.y < 0:
			y = -y
		var x := y.cross(z).normalized()
		k.box_xf(Transform3D(Basis(x, y, z), (lo + hi) * 0.5 + y * 0.06), Vector3(10.7, 0.12, d.length()), "l200_roof", GeoKit.ALL, false)
		k.box(Vector3(0, EAVE - 0.28, s * 4.95), Vector3(10.7, 0.2, 0.05), "l200_trim", GeoKit.ALL, false)
		FX.tri(k, Vector3(s * 5.0, EAVE, -4.5), Vector3(s * 5.0, EAVE, 4.5), Vector3(s * 5.0, ridge - 0.05, 0), Vector3(s, 0, 0), "l200_siding")
	k.box(Vector3(-3.4, ridge - 0.4, -1.2), Vector3(0.7, 2.6, 0.8), "l200_brick", GeoKit.ALL, false)
	k.box(Vector3(-3.4, ridge + 0.92, -1.2), Vector3(0.8, 0.1, 0.9), "l200_concrete", GeoKit.ALL, false)


## Windows (glass, sash bars, casings, sills) and the two doors.
static func _trim_openings(k: GeoKit) -> void:
	for op in OPS:
		var c: float = op["c"]
		if absf(absf(c) - 5.0) > 0.01 and absf(absf(c) - 4.5) > 0.01:
			continue
		var n := Vector3(signf(c), 0, 0) if op["line"] == "x" else Vector3(0, 0, signf(c))
		var along := Vector3(-n.z, 0, n.x).abs()
		var w: float = op["w"]
		var h: float = op["h"]
		var y0: float = float(op["y"]) + float(op["sill"])
		var base := (Vector3(c - n.x * 0.06, 0, float(op["at"])) if op["line"] == "x" else Vector3(float(op["at"]), 0, c - n.z * 0.06))
		var mid := base + Vector3(0, y0 + h * 0.5, 0)
		var thin := along * w + n.abs() * 0.02
		if op.has("win"):
			k.box(mid, thin + Vector3(0, h, 0), "glass", GeoKit.ALL, true)
			k.box(mid, along * w + n.abs() * 0.05 + Vector3(0, 0.045, 0), "l200_trim", GeoKit.ALL, false)
			k.box(mid, along * 0.04 + n.abs() * 0.05 + Vector3(0, h, 0), "l200_trim", GeoKit.ALL, false)
			k.box(base + Vector3(0, y0 - 0.03, 0) + n * 0.1, along * (w + 0.2) + n.abs() * 0.24 + Vector3(0, 0.05, 0), "l200_trim", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(base + along * s * (w * 0.5 + 0.05) + Vector3(0, y0 + h * 0.5, 0), along * 0.1 + n.abs() * 0.3 + Vector3(0, h + 0.1, 0), "l200_trim", GeoKit.ALL, false)
		k.box(base + Vector3(0, y0 + h + 0.06, 0), along * (w + 0.3) + n.abs() * 0.3 + Vector3(0, 0.12, 0), "l200_trim", GeoKit.ALL, false)
	# door leaves standing open, swung inward against their hinge side
	k.box_mm(Vector3(0.33, G, 3.47), Vector3(0.38, G + 2.05, 4.33), "l200_wood_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(0.38, G + 0.95, 3.6), Vector3(0.42, G + 1.0, 3.66), "l200_metal", GeoKit.ALL, false)
	k.box_mm(Vector3(2.12, G, -4.33), Vector3(2.17, G + 2.0, -3.52), "l200_wood_dark", GeoKit.ALL, false)


## Porch, steps, front walk, porch roof on posts, railing.
static func porch(k: GeoKit) -> void:
	k.box_mm(Vector3(-3.0, 0.0, 4.5), Vector3(3.0, G - 0.04, 6.4), "l200_concrete")
	k.box_mm(Vector3(-3.0, G - 0.04, 4.5), Vector3(3.0, G, 6.4), "l200_fence_wood", GeoKit.PY | GeoKit.SIDES)
	k.stairs(Vector3(0, 0, 7.21), Vector3(0, 0, -1), 1.6, G, 3, "l200_fence_wood", 0.27)
	k.box_mm(Vector3(-0.8, -0.05, 7.21), Vector3(0.8, 0.03, 12.5), "l200_sidewalk", GeoKit.PY | GeoKit.SIDES)
	for x in [-2.9, -0.95, 0.95, 2.9]:
		k.box(Vector3(x, (G + 3.0) * 0.5, 6.3), Vector3(0.14, 3.0 - G, 0.14), "l200_trim")
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 3.1, 5.55)), Vector3(6.4, 0.1, 2.3), "l200_roof", GeoKit.ALL, false)
	k.box(Vector3(0, 2.98, 6.33), Vector3(6.2, 0.2, 0.12), "l200_trim", GeoKit.ALL, false)
	for seg in [[-2.9, -0.95], [0.95, 2.9]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		k.box(Vector3((x0 + x1) * 0.5, G + 0.9, 6.3), Vector3(x1 - x0, 0.06, 0.08), "l200_trim")
		k.box(Vector3((x0 + x1) * 0.5, G + 0.1, 6.3), Vector3(x1 - x0, 0.05, 0.06), "l200_trim", GeoKit.ALL, false)
		var nb := int((x1 - x0) / 0.13)
		for j in range(1, nb):
			k.box(Vector3(x0 + (x1 - x0) * j / nb, G + 0.5, 6.3), Vector3(0.035, 0.8, 0.035), "l200_trim", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), Vector3((x0 + x1) * 0.5, G + 0.5, 6.3)), Vector3(x1 - x0, 1.0, 0.1), "wood")
	for x in [-3.0, 3.0]:
		k.add_box_shape(Transform3D(Basis(), Vector3(x, G + 0.5, 5.45)), Vector3(0.1, 1.0, 1.8), "wood")
		k.box(Vector3(x, G + 0.9, 5.45), Vector3(0.08, 0.06, 1.8), "l200_trim", GeoKit.ALL, false)
		for j in 13:
			k.box(Vector3(x, G + 0.5, 4.6 + j * 0.13), Vector3(0.035, 0.8, 0.035), "l200_trim", GeoKit.ALL, false)
	# back stoop: three steps down from the kitchen door to the yard
	k.stairs(Vector3(1.75, 0, -5.31), Vector3(0, 0, 1), 1.2, G, 3, "l200_concrete", 0.27)
	# a porch swing bench and a doormat
	k.box_mm(Vector3(-2.7, G + 0.42, 4.65), Vector3(-1.3, G + 0.47, 5.15), "l200_fence_wood", GeoKit.ALL, false)
	k.box_mm(Vector3(-2.7, G + 0.47, 4.62), Vector3(-1.3, G + 0.95, 4.68), "l200_fence_wood", GeoKit.ALL, false)
	for x in [-2.65, -1.35]:
		_stick(k, Vector3(x, G + 0.45, 4.9), Vector3(x, 2.95, 4.9), 0.015, "l200_metal")
	k.box_mm(Vector3(-0.55, G, 4.6), Vector3(0.35, G + 0.015, 5.2), "l200_fab_g0", GeoKit.ALL, false)


## Furniture. Fabrics/wallpapers take the memory-group materials.
static func furnish(k: GeoKit) -> void:
	var g := G
	var W := "l200_wood_dark"
	# hall: coat hooks with an adult's and a child's coat, shoes, runner, console
	k.box_mm(Vector3(-1.06, g + 1.6, 3.2), Vector3(-1.02, g + 1.7, 4.25), W, GeoKit.ALL, false)
	for i in 4:
		var z := 3.35 + i * 0.27
		var tall := i % 2 == 0
		k.box_mm(Vector3(-1.02, g + (0.55 if tall else 0.95), z - 0.11), Vector3(-0.9, g + 1.6, z + 0.11), "l200_fab_g0" if tall else "l200_fab_g2", GeoKit.ALL, false)
	for p in [[Vector3(-0.85, g, 3.5), 0.3], [Vector3(-0.85, g, 3.85), 0.3], [Vector3(-0.85, g, 4.05), 0.2]]:
		var c: Vector3 = p[0]
		var l: float = p[1]
		k.box(c + Vector3(0, 0.05, 0), Vector3(0.11, 0.1, l), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(-0.8, g, -3.6), Vector3(-0.1, g + 0.01, 2.9), "l200_fab_g0", GeoKit.ALL, false)
	k.box_mm(Vector3(-1.04, g + 0.78, -1.5), Vector3(-0.7, g + 0.82, -0.5), W)
	for z in [-1.45, -0.55]:
		k.box(Vector3(-0.75, g + 0.39, z), Vector3(0.04, 0.78, 0.04), W, GeoKit.ALL, false)
	k.box_mm(Vector3(-0.98, g + 0.82, -1.25), Vector3(-0.8, g + 0.9, -1.05), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(-1.04, g + 1.15, -1.35), Vector3(-1.03, g + 1.85, -0.65), "l200_porcelain", GeoKit.ALL, false)
	# framed photographs climbing the stair wall (blank until remembered)
	for i in 5:
		var z := 2.6 - i * 0.8
		var y := g + 1.5 + (U - G) * (STAIR_Z0 - z) / (STAIR_Z0 - STAIR_TOP)
		k.box(Vector3(1.035, y, z), Vector3(0.03, 0.42 - (i % 2) * 0.1, 0.34), W, GeoKit.ALL, false)
		k.box(Vector3(1.012, y, z), Vector3(0.012, 0.34 - (i % 2) * 0.1, 0.26), "l200_wall_g0", GeoKit.ALL, false)
	# living room
	k.box_mm(Vector3(-4.84, g, 1.2), Vector3(-3.95, g + 0.42, 3.4), "l200_fab_g0")
	k.box_mm(Vector3(-4.84, g + 0.42, 1.2), Vector3(-4.58, g + 0.88, 3.4), "l200_fab_g0", GeoKit.ALL, false)
	for z in [1.2, 3.22]:
		k.box_mm(Vector3(-4.84, g, z), Vector3(-3.95, g + 0.62, z + 0.18), "l200_fab_g0", GeoKit.ALL, false)
	k.box_mm(Vector3(-3.5, g + 0.38, 1.8), Vector3(-2.7, g + 0.43, 2.8), W)
	for p in [Vector2(-3.45, 1.85), Vector2(-2.75, 1.85), Vector2(-3.45, 2.75), Vector2(-2.75, 2.75)]:
		k.box(Vector3(p.x, g + 0.19, p.y), Vector3(0.04, 0.38, 0.04), W, GeoKit.ALL, false)
	k.box_mm(Vector3(-2.2, g, 0.5), Vector3(-1.45, g + 0.42, 1.25), "l200_fab_g0")
	k.box_mm(Vector3(-2.2, g + 0.42, 0.5), Vector3(-1.45, g + 0.9, 0.7), "l200_fab_g0", GeoKit.ALL, false)
	k.box_mm(Vector3(-1.95, g, 3.75), Vector3(-1.2, g + 0.55, 4.3), W)
	k.box_mm(Vector3(-1.9, g + 0.55, 3.82), Vector3(-1.3, g + 1.05, 4.28), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.82, g, 0.06), Vector3(-4.0, g + 1.9, 0.4), W)
	for y in [0.4, 0.8, 1.2, 1.6]:
		k.box_mm(Vector3(-4.78, g + y, 0.1), Vector3(-4.04, g + y + 0.26, 0.36), "l200_fab_g1", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.3, g, 1.0), Vector3(-2.0, g + 0.012, 3.6), "l200_fab_g1", GeoKit.ALL, false)
	k.cylinder(Vector3(-4.6, g + 0.75, 3.85), 0.015, 1.5, "l200_metal", 6, false)
	k.cylinder(Vector3(-4.6, g + 1.55, 3.85), 0.2, 0.28, "l200_lamp", 12, false)
	# dining room: the birthday table
	k.box_mm(Vector3(-3.8, g + 0.72, -2.65), Vector3(-2.2, g + 0.77, -1.55), W)
	for p in [Vector2(-3.75, -2.6), Vector2(-2.25, -2.6), Vector2(-3.75, -1.6), Vector2(-2.25, -1.6)]:
		k.box(Vector3(p.x, g + 0.36, p.y), Vector3(0.06, 0.72, 0.06), W, GeoKit.ALL, false)
	for c in [[-3.4, -3.0, 0.0], [-2.6, -3.0, 0.0], [-3.4, -1.2, PI], [-2.6, -1.2, PI], [-4.15, -2.1, PI * 0.5], [-1.85, -2.1, -PI * 0.5]]:
		_chair(k, Vector3(c[0], g, c[1]), c[2], "l200_fab_g1")
	k.box_mm(Vector3(-3.8, g + 0.77, -2.6), Vector3(-2.2, g + 0.775, -1.6), "l200_porcelain", GeoKit.ALL, false)
	k.cylinder(Vector3(-3.0, g + 0.84, -2.1), 0.16, 0.13, "l200_porcelain", 18, false)
	k.cylinder(Vector3(-3.0, g + 0.91, -2.1), 0.165, 0.02, "l200_fab_g1", 18, false)
	k.box_mm(Vector3(-4.84, g, -3.2), Vector3(-4.4, g + 0.9, -1.2), W)
	k.box_mm(Vector3(-4.86, g + 1.3, -2.6), Vector3(-4.84, g + 1.9, -1.8), "l200_porcelain", GeoKit.ALL, false)
	k.cylinder(Vector3(-3.0, C1 - 0.35, -2.1), 0.012, 0.7, "l200_metal", 6, false)
	k.cylinder(Vector3(-3.0, C1 - 0.72, -2.1), 0.28, 0.12, "l200_lamp", 14, false)
	# den
	k.box_mm(Vector3(4.3, g, 0.8), Vector3(4.84, g + 0.76, 2.0), W)
	k.box_mm(Vector3(3.6, g, 3.4), Vector3(4.4, g + 0.45, 4.2), "l200_fab_g0")
	k.box_mm(Vector3(4.2, g + 0.45, 3.4), Vector3(4.4, g + 0.95, 4.2), "l200_fab_g0", GeoKit.ALL, false)
	k.box_mm(Vector3(1.2, g, 0.4), Vector3(2.6, g + 2.0, 0.75), W)
	for y in [0.3, 0.75, 1.2, 1.6]:
		k.box_mm(Vector3(1.25, g + y, 0.45), Vector3(2.55, g + y + 0.3, 0.7), "l200_fab_g2", GeoKit.ALL, false)
	k.box_mm(Vector3(4.4, g + 0.76, 1.1), Vector3(4.75, g + 0.98, 1.6), "l200_wood_dark", GeoKit.ALL, false)
	# kitchen
	k.box_mm(Vector3(2.25, g, -4.34), Vector3(4.84, g + 0.9, -3.74), "l200_trim")
	k.box_mm(Vector3(2.22, g + 0.9, -4.36), Vector3(4.86, g + 0.94, -3.7), "l200_formica")
	k.box_mm(Vector3(4.24, g, -3.74), Vector3(4.84, g + 0.9, -1.55), "l200_trim")
	k.box_mm(Vector3(4.2, g + 0.9, -3.74), Vector3(4.86, g + 0.94, -1.55), "l200_formica")
	k.box_mm(Vector3(3.1, g + 0.8, -4.25), Vector3(3.7, g + 0.95, -3.85), "l200_metal", GeoKit.ALL, false)
	k.box_mm(Vector3(4.26, g + 0.94, -2.8), Vector3(4.82, g + 0.97, -2.1), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(4.25, g, -1.45), Vector3(4.84, g + 1.75, -0.75), "l200_porcelain")
	k.box_mm(Vector3(2.25, g + 1.5, -4.34), Vector3(2.75, g + 2.3, -4.0), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(4.05, g + 1.5, -4.34), Vector3(4.84, g + 2.3, -4.0), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(4.5, g + 1.5, -3.74), Vector3(4.84, g + 2.3, -2.8), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(2.0, g + 0.72, -1.8), Vector3(2.9, g + 0.76, -0.9), "l200_formica")
	for c in [[2.45, -2.15, 0.0], [2.45, -0.55, PI]]:
		_chair(k, Vector3(c[0], g, c[1]), c[2], "l200_fab_g1")
	k.cylinder(Vector3(3.0, C1 - 0.05, -2.0), 0.22, 0.06, "l200_lamp", 14, false)
	# upper floor ---------------------------------------------------------
	var u := U
	# child's bedroom: twin bed, desk with a model rocket (space camp), dresser
	k.box_mm(Vector3(-4.84, u, 2.5), Vector3(-3.9, u + 0.38, 4.3), W)
	k.box_mm(Vector3(-4.82, u + 0.38, 2.55), Vector3(-3.92, u + 0.55, 4.28), "l200_fab_g2", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.7, u + 0.55, 3.9), Vector3(-4.05, u + 0.66, 4.22), "l200_porcelain", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.84, u, 4.25), Vector3(-3.9, u + 0.95, 4.33), W, GeoKit.ALL, false)
	k.box_mm(Vector3(-3.1, u + 0.72, 3.8), Vector3(-2.0, u + 0.76, 4.32), W)
	for p in [Vector2(-3.05, 3.85), Vector2(-2.05, 3.85), Vector2(-3.05, 4.27), Vector2(-2.05, 4.27)]:
		k.box(Vector3(p.x, u + 0.36, p.y), Vector3(0.04, 0.72, 0.04), W, GeoKit.ALL, false)
	k.cylinder(Vector3(-2.4, u + 0.9, 4.1), 0.035, 0.28, "l200_porcelain", 8, false)
	k.cylinder(Vector3(-2.4, u + 1.07, 4.1), 0.018, 0.06, "l200_fab_g1", 8, false)
	_chair(k, Vector3(-2.55, u, 3.35), PI, "l200_fab_g2")
	k.box_mm(Vector3(-4.4, u, 0.46), Vector3(-3.4, u + 1.0, 0.95), W)
	k.box_mm(Vector3(-2.2, u, 0.5), Vector3(-1.5, u + 0.45, 0.95), "l200_fab_g1")
	k.cylinder(Vector3(-3.2, u + 0.006, 2.6), 0.75, 0.012, "l200_fab_g1", 20, false)
	k.box(Vector3(-2.9, u + 1.6, 0.47), Vector3(0.45, 0.6, 0.01), "l200_fab_g1", GeoKit.ALL, false)
	k.box(Vector3(-1.75, u + 1.6, 0.47), Vector3(0.5, 0.65, 0.01), "l200_fab_g2", GeoKit.ALL, false)
	# parents' bedroom
	k.box_mm(Vector3(-4.84, u, -2.7), Vector3(-2.9, u + 0.45, -0.95), W)
	k.box_mm(Vector3(-4.8, u + 0.45, -2.66), Vector3(-2.95, u + 0.62, -0.99), "l200_fab_g2", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.84, u, -2.75), Vector3(-4.76, u + 1.15, -0.9), W, GeoKit.ALL, false)
	for z in [-3.2, -0.45]:
		k.box_mm(Vector3(-4.84, u, z - 0.22), Vector3(-4.4, u + 0.55, z + 0.22), W)
	k.box_mm(Vector3(-2.4, u, -4.34), Vector3(-1.2, u + 2.0, -3.75), W)
	k.box_mm(Vector3(-1.75, u, -0.2), Vector3(-1.2, u + 0.9, 0.34), W)
	# bathroom
	k.box_mm(Vector3(2.6, u, -4.34), Vector3(4.84, u + 0.55, -3.6), "l200_porcelain")
	k.box_mm(Vector3(2.75, u + 0.35, -4.24), Vector3(4.7, u + 0.56, -3.7), "l200_dark", GeoKit.PY, false)
	k.box_mm(Vector3(1.16, u, -4.34), Vector3(4.84, u + 1.2, -4.3), "l200_tile_wall", GeoKit.ALL, false)
	k.box_mm(Vector3(4.8, u, -4.3), Vector3(4.84, u + 1.2, 0.34), "l200_tile_wall", GeoKit.ALL, false)
	k.box_mm(Vector3(4.3, u, -1.2), Vector3(4.8, u + 0.42, -0.75), "l200_porcelain")
	k.box_mm(Vector3(4.62, u + 0.42, -1.2), Vector3(4.8, u + 0.8, -0.75), "l200_porcelain", GeoKit.ALL, false)
	k.box_mm(Vector3(4.3, u, -2.6), Vector3(4.8, u + 0.85, -1.9), "l200_porcelain")
	k.box(Vector3(4.835, u + 1.55, -2.25), Vector3(0.01, 0.6, 0.5), "l200_glass", GeoKit.ALL, false)
	# spare room: never took shape — studs, subfloor, sawhorses, a bare bulb
	var r := [1.1, 0.4, 4.9, 4.4]
	for x in range(0, 10):
		var xx := 1.25 + x * 0.4
		if absf(xx - 3.0) > 0.6:
			k.box(Vector3(xx, u + 1.27, 4.33), Vector3(0.05, 2.55, 0.1), "l200_stud_wood", GeoKit.ALL, false)
		k.box(Vector3(xx, u + 1.27, 0.46), Vector3(0.05, 2.55, 0.1), "l200_stud_wood", GeoKit.ALL, false)
	for z in range(0, 10):
		var zz := 0.55 + z * 0.4
		if absf(zz - 3.8) > 0.55:
			k.box(Vector3(1.16, u + 1.27, zz), Vector3(0.1, 2.55, 0.05), "l200_stud_wood", GeoKit.ALL, false)
		if absf(zz - 2.4) > 0.6:
			k.box(Vector3(4.84, u + 1.27, zz), Vector3(0.1, 2.55, 0.05), "l200_stud_wood", GeoKit.ALL, false)
	k.wall(Vector3(r[0] + 0.02, u, r[1] + 0.02), Vector3(r[2], u, r[1] + 0.02), C2 - u, 0.04, "l200_fence_wood")
	k.wall(Vector3(r[0] + 0.02, u, r[3] - 0.02), Vector3(r[2], u, r[3] - 0.02), C2 - u, 0.04, "l200_fence_wood", _ops_for("z", 4.4, u, 2.5, r[0], r[2]))
	k.wall(Vector3(r[0] + 0.03, u, r[1] + 0.04), Vector3(r[0] + 0.03, u, r[3] - 0.04), C2 - u, 0.04, "l200_fence_wood", _ops_for("x", 1.1, u, 2.5, r[1] + 0.04, r[3] - 0.04))
	k.wall(Vector3(r[2] - 0.03, u, r[1] + 0.04), Vector3(r[2] - 0.03, u, r[3] - 0.04), C2 - u, 0.04, "l200_fence_wood", _ops_for("x", 4.9, u, 2.5, r[1] + 0.04, r[3] - 0.04))
	for x in [2.4, 3.6]:
		k.box(Vector3(x, u + 0.55, 1.8), Vector3(0.08, 0.06, 1.0), "l200_stud_wood", GeoKit.ALL, false)
		for z in [1.4, 2.2]:
			k.box(Vector3(x, u + 0.27, z), Vector3(0.05, 0.54, 0.05), "l200_stud_wood", GeoKit.ALL, false)
	k.box(Vector3(3.0, u + 0.6, 1.8), Vector3(1.6, 0.03, 0.4), "l200_stud_wood", GeoKit.ALL, false)
	k.cylinder(Vector3(3.0, C2 - 0.3, 2.4), 0.006, 0.6, "l200_dark", 4, false)
	k.cylinder(Vector3(3.0, C2 - 0.64, 2.4), 0.04, 0.08, "l200_bulb", 8, false)
	# upper hall: a runner and a small table under the landing window
	k.box_mm(Vector3(-0.85, u, -3.9), Vector3(-0.25, u + 0.01, 2.9), "l200_fab_g0", GeoKit.ALL, false)
	k.cylinder(Vector3(-0.5, C2 - 0.05, -2.6), 0.2, 0.06, "l200_lamp", 14, false)
	k.cylinder(Vector3(0.5, C2 - 0.45, 1.0), 0.008, 0.8, "l200_metal", 6, false)
	k.cylinder(Vector3(0.5, C2 - 0.9, 1.0), 0.24, 0.16, "l200_lamp", 14, false)


static func _chair(k: GeoKit, p: Vector3, yaw: float, fab: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, p + Vector3(0, 0.45, 0)), Vector3(0.44, 0.05, 0.42), fab, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + b * Vector3(0, 0.72, -0.2)), Vector3(0.44, 0.5, 0.04), "l200_wood_dark", GeoKit.ALL, false)
	for s in [Vector2(-0.19, -0.18), Vector2(0.19, -0.18), Vector2(-0.19, 0.18), Vector2(0.19, 0.18)]:
		k.box_xf(Transform3D(b, p + b * Vector3(s.x, 0.22, s.y)), Vector3(0.035, 0.44, 0.035), "l200_wood_dark", GeoKit.ALL, false)
