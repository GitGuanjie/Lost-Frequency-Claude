extends RefCounted
## Level 96 house: architecture and dressing. SOURCE (fact 11-13): "This is a
## house. It overlooks the vast ranges of mountains." Porcelain pitchers sit
## filled; doorways stand with crumbling but steadfast paint; the windows are
## etched with intricate patterns; carpet underfoot; the dinner table.
## ADAPTATION: the plan (a central hall with a triple-arched front, four side
## rooms, a front terrace, a roof terrace and a lower overlook) is ours. It draws
## on the kind of old stone house in the page's image credits; no place is named.
## Floor y = 0. The view (and the triple arch) faces -z.

const GY := -0.45       # garden level (matches L096_land.GARDEN_Y)
const T := 0.5          # outer stone walls
const P := 0.3          # partitions
const WING_H := 3.6     # wing roof top (= roof-terrace floor)
const CEIL := 3.4       # wing ceilings
const HALL_H := 4.6     # hall ceiling
const WIN := {"w": 1.1, "h": 1.75, "sill": 0.85}

var lvl: LevelBase
var land
var dress: Node3D
var pitchers: Array = []      # world positions of the filled porcelain pitchers
var dust_spots: Array = []    # candidate floor points for dust patches
var _pitcher_mesh: ArrayMesh
var _water_mat: StandardMaterial3D


func _init(level: LevelBase, land_ref) -> void:
	lvl = level
	land = land_ref
	dress = Node3D.new()
	dress.name = "Dressing"
	lvl.add_child(dress)


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(lvl, dress, id, pos, yaw, h, collide)


# ------------------------------------------------------------------ shell

## Outer stone wall with a limewash lining on the inside face only.
## inside: +1 if the room is on the wall's local +z side, -1 for local -z.
func _owall(k: GeoKit, a: Vector3, b: Vector3, h: float, ops: Array, inside: int) -> void:
	var stone_faces := GeoKit.ALL & ~(GeoKit.PZ if inside > 0 else GeoKit.NZ)
	k.wall(a, b, h, T, "l96_stone", ops, stone_faces)
	var dir := (b - a)
	dir.y = 0.0
	dir = dir.normalized()
	var nz := dir.cross(Vector3.UP).normalized() * float(inside)
	var off := nz * (T * 0.5 + 0.012)
	var lin_ops: Array = []
	for o in ops:
		lin_ops.append(o)
	k.wall(a + off + dir * 0.25, b + off - dir * 0.25, CEIL, 0.02, "l96_plaster", _shift(lin_ops, -0.25), GeoKit.PZ if inside > 0 else GeoKit.NZ)


func _shift(ops: Array, d: float) -> Array:
	var out: Array = []
	for o in ops:
		var c: Dictionary = (o as Dictionary).duplicate()
		c["at"] = float(c["at"]) + d
		out.append(c)
	return out


func shell(k: GeoKit) -> void:
	# plinth, floors, terrace
	k.slab(-8.0, 0.0, 8.0, 10.0, 0.0, 0.03, "l96_tile", GeoKit.PY)
	k.box_mm(Vector3(-8.05, -0.47, -0.05), Vector3(8.05, -0.03, 10.05), "l96_rubble", GeoKit.SIDES | GeoKit.PY)
	k.slab(-8.5, -4.5, 8.5, 0.0, 0.0, 0.47, "l96_paving", GeoKit.PY | GeoKit.SIDES)
	k.stairs(Vector3(0, -0.45, -5.4), Vector3(0, 0, 1), 3.0, 0.45, 3, "l96_paving", 0.3)
	for x in [-1.0, 1.0]:
		k.wall(Vector3(x * 1.6, 0, -4.35), Vector3(x * 8.35, 0, -4.35), 0.5, 0.3, "l96_stone")
		k.wall(Vector3(x * 8.35, 0, -4.5), Vector3(x * 8.35, 0, -0.05), 0.5, 0.3, "l96_stone")
		k.box(Vector3(x * 1.75, 0.65, -4.35), Vector3(0.42, 0.3, 0.42), "l96_marble")
	# front wall: two wings with windows, the hall's triple arch between them
	_owall(k, Vector3(-8.0, 0, 0.25), Vector3(-3.0, 0, 0.25), WING_H, [_win(2.5)], 1)
	_owall(k, Vector3(3.0, 0, 0.25), Vector3(8.0, 0, 0.25), WING_H, [_win(2.5)], 1)
	k.arch_wall(Vector3(-3.0, 0, 0.25), Vector3(3.0, 0, 0.25), HALL_H + 0.15, T, "l96_stone",
		[{"at": 1.45, "w": 1.0, "spring": 2.45}, {"at": 3.0, "w": 1.3, "spring": 2.3}, {"at": 4.55, "w": 1.0, "spring": 2.45}], 12)
	for x in [-1.55, 1.55]:
		k.box(Vector3(x, 0.3, 0.25), Vector3(1.0, 0.6, T), "l96_stone")
		k.box(Vector3(x, 0.62, 0.25), Vector3(1.08, 0.05, T + 0.08), "l96_marble")
		_arch_pane(k, Vector3(x, 0.65, 0.25), 1.0, 1.8, Vector3.RIGHT)
		# slim marble colonnettes between the arches
	for x in [-0.95, 0.95]:
		k.cylinder(Vector3(x, 1.25, 0.04), 0.07, 2.5, "l96_marble", 10, false)
		k.box(Vector3(x, 2.53, 0.04), Vector3(0.22, 0.08, 0.16), "l96_marble", GeoKit.ALL, false)
	_arch_pane(k, Vector3(0.0, 2.3, 0.25), 1.3, 0.0, Vector3.RIGHT)
	# back wall
	_owall(k, Vector3(-8.0, 0, 9.75), Vector3(-3.0, 0, 9.75), WING_H, [_win(2.5)], -1)
	_owall(k, Vector3(3.0, 0, 9.75), Vector3(8.0, 0, 9.75), WING_H, [_win(2.5)], -1)
	k.arch_wall(Vector3(-3.0, 0, 9.75), Vector3(3.0, 0, 9.75), HALL_H + 0.15, T, "l96_stone", [{"at": 3.0, "w": 1.2, "spring": 2.2}], 12)
	# side walls
	_owall(k, Vector3(-7.75, 0, 0.0), Vector3(-7.75, 0, 10.0), WING_H, [_win(2.5), _win(7.5)], -1)
	_owall(k, Vector3(7.75, 0, 0.0), Vector3(7.75, 0, 10.0), WING_H, [_win(2.5)], 1)
	# partitions (limewash), the hall's upper stone band and wooden ceiling
	for x in [-3.0, 3.0]:
		k.wall(Vector3(x, 0, 0.5), Vector3(x, 0, 9.5), CEIL, P, "l96_plaster", [_door(2.0), _door(7.0)])
		k.box(Vector3(x, (CEIL + HALL_H + 0.15) * 0.5, 5.0), Vector3(P, HALL_H + 0.15 - CEIL, 10.0), "l96_stone")
		k.box(Vector3(x - signf(x) * 0.17, CEIL + 0.06, 5.0), Vector3(0.06, 0.12, 9.0), "l96_wood", GeoKit.ALL, false)
	k.wall(Vector3(-7.5, 0, 5.0), Vector3(-3.15, 0, 5.0), CEIL, P, "l96_plaster", [{"at": 0.8, "w": 0.9, "h": 2.1}])
	k.wall(Vector3(3.15, 0, 5.0), Vector3(7.5, 0, 5.0), CEIL, P, "l96_plaster", [{"at": 3.55, "w": 0.9, "h": 2.1}])
	k.box_mm(Vector3(-3.15, HALL_H, 0.5), Vector3(3.15, HALL_H + 0.15, 9.5), "l96_ceiling", GeoKit.NY, false)
	for i in 7:
		k.box(Vector3(0, HALL_H - 0.12, 1.4 + i * 1.2), Vector3(6.0, 0.24, 0.2), "l96_wood", GeoKit.ALL, false)
	# wing ceilings and roofs; the east roof is the roof terrace
	for x0 in [-8.0, 3.0]:
		k.box_mm(Vector3(x0 + 0.25 if x0 < 0 else x0, CEIL, 0.25), Vector3(x0 + 5.0 if x0 < 0 else x0 + 4.75, CEIL + 0.1, 9.75), "l96_plaster", GeoKit.NY, false)
		k.slab(x0, 0.0, x0 + 5.0, 10.0, WING_H, 0.1, "l96_paving", GeoKit.PY | GeoKit.SIDES)
	k.wall(Vector3(-8.0, WING_H, 0.1), Vector3(-3.0, WING_H, 0.1), 0.45, 0.2, "l96_stone")
	k.wall(Vector3(-8.0, WING_H, 9.9), Vector3(-3.0, WING_H, 9.9), 0.45, 0.2, "l96_stone")
	k.wall(Vector3(-7.9, WING_H, 0.0), Vector3(-7.9, WING_H, 10.0), 0.45, 0.2, "l96_stone")
	_roof_parapet(k)
	_hall_roof(k)
	_frames(k)
	_roof_stair(k)


func _win(at: float) -> Dictionary:
	return {"at": at, "w": WIN["w"], "h": WIN["h"], "sill": WIN["sill"]}


func _door(at: float) -> Dictionary:
	return {"at": at, "w": 1.0, "h": 2.15}


## Roof-terrace parapet (1.0 m) with a gap where the outside stair arrives.
func _roof_parapet(k: GeoKit) -> void:
	var y := WING_H
	k.wall(Vector3(3.0, y, 0.1), Vector3(8.0, y, 0.1), 1.05, 0.2, "l96_stone")
	k.wall(Vector3(3.0, y, 9.9), Vector3(8.0, y, 9.9), 1.05, 0.2, "l96_stone")
	k.wall(Vector3(7.9, y, 0.2), Vector3(7.9, y, 9.8), 1.05, 0.2, "l96_stone", [{"at": 3.7, "w": 1.2, "h": 1.05}])
	for z in [0.1, 9.9]:
		k.box(Vector3(5.5, y + 1.08, z), Vector3(5.0, 0.06, 0.3), "l96_marble", GeoKit.ALL, false)


## Stone stair up the east side to the roof terrace (22 risers, 0.184 m).
func _roof_stair(k: GeoKit) -> void:
	var steps := 22
	var rise := WING_H - GY
	var start := Vector3(8.7, GY, 4.5 + steps * 0.28)
	k.stairs(start, Vector3(0, 0, -1), 1.2, rise, steps, "l96_paving", 0.28)
	# landing on a stone pier against the house, level with the roof
	k.box_mm(Vector3(8.0, GY, 3.2), Vector3(9.4, WING_H, 4.5), "l96_stone")
	# stepped outer parapet
	for i in steps:
		var top := GY + rise * float(i + 1) / steps
		var z := start.z - 0.28 * (i + 0.5)
		k.box(Vector3(9.42, (GY + top + 1.0) * 0.5, z), Vector3(0.24, top + 1.0 - GY, 0.29), "l96_stone")
	k.box_mm(Vector3(9.3, WING_H, 3.2), Vector3(9.54, WING_H + 1.0, 4.5), "l96_stone")
	k.box_mm(Vector3(8.0, WING_H, 3.06), Vector3(9.54, WING_H + 1.0, 3.3), "l96_stone")


## Hipped terracotta roof over the hall (visual mesh, both faces).
func _hall_roof(k: GeoKit) -> void:
	var e := HALL_H + 0.15
	k.box_mm(Vector3(-3.55, e - 0.12, -0.4), Vector3(3.55, e, 10.4), "l96_marble", GeoKit.SIDES | GeoKit.NY, false)
	var a := Vector3(-3.55, e, -0.4)
	var b := Vector3(3.55, e, -0.4)
	var c := Vector3(3.55, e, 10.4)
	var d := Vector3(-3.55, e, 10.4)
	var r0 := Vector3(0, e + 2.0, 3.6)
	var r1 := Vector3(0, e + 2.0, 6.4)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[a, r0, b], [b, r0, r1], [b, r1, c], [c, r1, d], [d, r1, r0], [d, r0, a]]:
		var n: Vector3 = ((tri[1] - tri[0]).cross(tri[2] - tri[0])).normalized()
		if n.y < 0.0:
			n = -n
		var tu := Vector3(n.z, 0, -n.x).normalized() if absf(n.y) < 0.999 else Vector3.RIGHT
		var tv := n.cross(tu)
		for order in [[0, 1, 2], [0, 2, 1]]:
			var nn: Vector3 = n if order == [0, 2, 1] else -n
			for q in order:
				var v: Vector3 = tri[q]
				st.set_normal(nn)
				st.set_uv(Vector2(v.dot(tu), v.dot(tv)))
				st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.name = "HallRoof"
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l96_roof")
	lvl.add_child(mi)


## Painted doorframes, the crumbling paint the page names, and open door leaves.
func _frames(k: GeoKit) -> void:
	# [centre, along-axis (x or z), width, height, depth]
	var doors := [
		[Vector3(-3.0, 0, 2.5), "z", 1.0, 2.15, P], [Vector3(-3.0, 0, 7.5), "z", 1.0, 2.15, P],
		[Vector3(3.0, 0, 2.5), "z", 1.0, 2.15, P], [Vector3(3.0, 0, 7.5), "z", 1.0, 2.15, P],
		[Vector3(-6.7, 0, 5.0), "x", 0.9, 2.1, P], [Vector3(6.7, 0, 5.0), "x", 0.9, 2.1, P]]
	for d in doors:
		var c: Vector3 = d[0]
		var w: float = d[2]
		var h: float = d[3]
		var dep: float = float(d[4]) + 0.08
		var along_z: bool = d[1] == "z"
		for s in [-1.0, 1.0]:
			var off := Vector3(0, 0, s * (w * 0.5 + 0.06)) if along_z else Vector3(s * (w * 0.5 + 0.06), 0, 0)
			k.box(c + off + Vector3(0, h * 0.5, 0), Vector3(dep, h, 0.12) if along_z else Vector3(0.12, h, dep), "l96_frame", GeoKit.ALL, false)
		k.box(c + Vector3(0, h + 0.07, 0), Vector3(dep, 0.14, w + 0.24) if along_z else Vector3(w + 0.24, 0.14, dep), "l96_frame", GeoKit.ALL, false)
	# front double doors (glazed, open inward) and the back door leaf
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 0.66, 1.15, 0.86), Vector3(0.05, 2.3, 0.64), "l96_door", GeoKit.ALL, false)
		k.box(Vector3(s * 0.69, 1.6, 0.86), Vector3(0.012, 0.9, 0.42), "l96_etched", GeoKit.ALL, false)
	k.box(Vector3(-0.62, 1.1, 9.2), Vector3(0.05, 2.2, 0.62), "l96_door", GeoKit.ALL, false)
	# side-room doors stand open against the wall
	for d in [[Vector3(-3.5, 1.05, 2.0), true], [Vector3(3.5, 1.05, 7.0), true], [Vector3(-6.2, 1.02, 5.45), false]]:
		var p: Vector3 = d[0]
		k.box(p, Vector3(0.05, 2.1, 0.92) if d[1] else Vector3(0.9, 2.05, 0.05), "l96_door", GeoKit.ALL, false)
	# window frames and painted shutters folded back outside
	var wins := [[Vector3(-5.5, 0, 0.0), "x", -1.0], [Vector3(5.5, 0, 0.0), "x", -1.0], [Vector3(-5.5, 0, 10.0), "x", 1.0],
		[Vector3(5.5, 0, 10.0), "x", 1.0], [Vector3(-8.0, 0, 2.5), "z", -1.0], [Vector3(-8.0, 0, 7.5), "z", -1.0], [Vector3(8.0, 0, 2.5), "z", 1.0]]
	for wd in wins:
		var c: Vector3 = wd[0]
		var ax: bool = wd[1] == "x"
		var out: float = wd[2]
		var y0: float = WIN["sill"]
		var y1: float = y0 + WIN["h"]
		var mid := (y0 + y1) * 0.5
		var inset := Vector3(0, 0, out * 0.25) if ax else Vector3(out * 0.25, 0, 0)
		var wc := c - inset
		k.box(wc + Vector3(0, mid, 0), Vector3(1.1, WIN["h"], 0.025) if ax else Vector3(0.025, WIN["h"], 1.1), "l96_etched")
		k.box(c + Vector3(0, y0 - 0.03, 0) + inset * 0.1, Vector3(1.3, 0.06, 0.2) if ax else Vector3(0.2, 0.06, 1.3), "l96_marble", GeoKit.ALL, false)
		k.box(wc + Vector3(0, mid, 0), Vector3(1.1, 0.05, 0.06) if ax else Vector3(0.06, 0.05, 1.1), "l96_frame", GeoKit.ALL, false)
		k.box(wc + Vector3(0, mid, 0), Vector3(0.05, WIN["h"], 0.06) if ax else Vector3(0.06, WIN["h"], 0.05), "l96_frame", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			var side := Vector3(s * 0.9, 0, 0) if ax else Vector3(0, 0, s * 0.9)
			var pos := c + side + Vector3(0, mid, 0) + (Vector3(0, 0, out * 0.04) if ax else Vector3(out * 0.04, 0, 0))
			k.box(pos, Vector3(0.55, WIN["h"] + 0.1, 0.04) if ax else Vector3(0.04, WIN["h"] + 0.1, 0.55), "l96_shutter", GeoKit.ALL, false)
		dust_spots.append(c - inset * 3.2)


## An arched pane of etched glass in a wall opening (vertical slices).
## base = centre of the opening at the pane's bottom; rect_h = straight part.
func _arch_pane(k: GeoKit, base: Vector3, w: float, rect_h: float, axis: Vector3) -> void:
	var r := w * 0.5
	if rect_h > 0.0:
		k.box(base + Vector3(0, rect_h * 0.5, 0), Vector3(w, rect_h, 0.025), "l96_etched")
	var slices := 9
	for i in slices:
		var u0 := -r + w * float(i) / slices
		var u1 := -r + w * float(i + 1) / slices
		var um := (u0 + u1) * 0.5
		var hh := sqrt(maxf(r * r - um * um, 0.0))
		k.box(base + axis * um + Vector3(0, rect_h + hh * 0.5, 0), Vector3(u1 - u0, hh, 0.025), "l96_etched", GeoKit.ALL, false)
	k.box(base + Vector3(0, rect_h + 0.0, 0), Vector3(w, 0.04, 0.05), "l96_frame", GeoKit.ALL, false)


# ------------------------------------------------------------------ garden

func garden(k: GeoKit) -> void:
	var gy: float = GY
	k.slab(-19.0, -12.0, 19.0, 17.0, gy, 1.0, "l96_garden", GeoKit.PY)
	# paths: front steps to the overlook stair, around both sides to the back door
	k.box_mm(Vector3(-1.0, gy, -12.0), Vector3(1.0, gy + 0.02, -5.4), "l96_paving", GeoKit.PY, false)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(minf(s * 9.9, s * 11.6), gy, -5.6), Vector3(maxf(s * 9.9, s * 11.6), gy + 0.02, 12.6), "l96_paving", GeoKit.PY, false)
		k.box_mm(Vector3(minf(s * 1.0, s * 11.6), gy, -5.6), Vector3(maxf(s * 1.0, s * 11.6), gy + 0.02, -4.6), "l96_paving", GeoKit.PY, false)
	k.box_mm(Vector3(-11.6, gy, 10.6), Vector3(11.6, gy + 0.02, 12.6), "l96_paving", GeoKit.PY, false)
	k.stairs(Vector3(0, gy, 10.6), Vector3(0, 0, -1), 1.6, 0.0 - gy, 2, "l96_paving", 0.3)
	# boundary: parapets on the drop, a retaining wall against the hillside behind
	var ph := 1.1
	k.wall(Vector3(-19.0, gy, -12.0), Vector3(-8.0, gy, -12.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(8.0, gy, -12.0), Vector3(19.0, gy, -12.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(-19.0, gy, -12.0), Vector3(-19.0, gy, 17.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(19.0, gy, -12.0), Vector3(19.0, gy, 17.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(-19.2, gy, 17.0), Vector3(19.2, gy, 17.0), 2.6, 0.6, "l96_rubble")
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(minf(s * 19.0, s * 19.25), -16.0, -12.2), Vector3(maxf(s * 19.0, s * 19.25), gy, 17.0), "l96_rubble", GeoKit.SIDES, false)
		k.box_mm(Vector3(minf(s * 8.0, s * 19.2), -16.0, -12.25), Vector3(maxf(s * 8.0, s * 19.2), gy, -12.0), "l96_rubble", GeoKit.SIDES, false)
	# lower overlook terrace (y = -1.8) down seven steps
	var ly := -1.8
	k.slab(-8.0, -20.0, 8.0, -12.0, ly, 0.6, "l96_paving", GeoKit.PY)
	k.stairs(Vector3(0, ly, -14.1), Vector3(0, 0, 1), 2.4, gy - ly, 7, "l96_paving", 0.3)
	k.wall(Vector3(-8.0, ly, -12.0), Vector3(8.0, ly, -12.0), gy - ly, 0.4, "l96_rubble", [{"at": 8.0, "w": 2.4, "h": 3.0}])
	k.wall(Vector3(-8.0, gy, -12.0), Vector3(8.0, gy, -12.0), ph, 0.4, "l96_stone", [{"at": 8.0, "w": 2.6, "h": 3.0}])
	k.wall(Vector3(-8.0, ly, -20.0), Vector3(8.0, ly, -20.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(-8.0, ly, -20.0), Vector3(-8.0, ly, -12.0), ph, 0.4, "l96_stone")
	k.wall(Vector3(8.0, ly, -20.0), Vector3(8.0, ly, -12.0), ph, 0.4, "l96_stone")
	k.box_mm(Vector3(-8.25, -16.0, -20.25), Vector3(8.25, ly, -20.0), "l96_rubble", GeoKit.SIDES, false)
	k.box_mm(Vector3(-8.25, -16.0, -20.25), Vector3(-8.0, ly, -12.0), "l96_rubble", GeoKit.SIDES, false)
	k.box_mm(Vector3(8.0, -16.0, -20.25), Vector3(8.25, ly, -12.0), "l96_rubble", GeoKit.SIDES, false)
	# parapet copings
	for seg in [[Vector3(-13.5, gy + ph, -12.0), Vector3(11.0, 0.06, 0.5)], [Vector3(13.5, gy + ph, -12.0), Vector3(11.0, 0.06, 0.5)],
			[Vector3(0, ly + ph, -20.0), Vector3(16.4, 0.06, 0.5)]]:
		k.box(seg[0], seg[1], "l96_marble", GeoKit.ALL, false)
	# a stone bench against the overlook parapet
	k.box(Vector3(-4.0, ly + 0.22, -19.45), Vector3(3.0, 0.44, 0.5), "l96_stone")
	k.box(Vector3(4.0, ly + 0.22, -19.45), Vector3(3.0, 0.44, 0.5), "l96_stone")


func trees() -> void:
	var gy: float = GY
	for p in [Vector3(-17.5, gy, -2.0), Vector3(-17.5, gy, 4.0), Vector3(-17.5, gy, 10.0), Vector3(17.5, gy, 0.0),
			Vector3(17.5, gy, 6.5), Vector3(17.5, gy, 13.0), Vector3(-12.5, gy, 15.8), Vector3(12.5, gy, 15.8)]:
		land.cypress(p, 7.5 + fmod(absf(p.x * 3.1 + p.z * 1.7), 2.5))
	var bush: Array = []
	for x in [-17.8, -16.6, -15.2, 15.4, 16.8, 17.9]:
		bush.append(Vector3(x, gy, -11.1))
	for z in [-7.0, -4.5, 1.5, 7.5, 12.0, 15.0]:
		bush.append(Vector3(-18.1, gy, z))
		bush.append(Vector3(18.1, gy, z + 1.0))
	for x in [-8.6, -6.0, -4.0, 4.0, 6.0]:
		bush.append(Vector3(x, gy, -5.1))
	for x in [-18.0, -15.0, -9.0, -6.0, 6.0, 15.0, 18.0]:
		bush.append(Vector3(x, gy, 16.1))
	for z in [1.0, 4.0, 7.0]:
		bush.append(Vector3(-8.9, gy, z))
	land.shrubs(bush)
	land.stone_pine(Vector3(-13.0, gy, -8.0), 7.5, 0.18, 0.4)
	land.stone_pine(Vector3(14.0, gy, -7.0), 8.5, -0.12, 2.2)
	land.stone_pine(Vector3(-5.0, gy + 3.0, 26.0), 9.5, 0.08, 1.1)
	land.stone_pine(Vector3(9.0, gy + 4.0, 29.0), 10.0, -0.1, 3.0)


# ------------------------------------------------------------------ porcelain

func _pitcher_assets() -> void:
	if _pitcher_mesh:
		return
	_pitcher_mesh = land.lathe([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.075, 0.02), Vector2(0.088, 0.09), Vector2(0.082, 0.15),
		Vector2(0.06, 0.205), Vector2(0.048, 0.235), Vector2(0.055, 0.262), Vector2(0.05, 0.265), Vector2(0.04, 0.24)], 18)
	_water_mat = StandardMaterial3D.new()
	_water_mat.albedo_color = Color(0.1, 0.13, 0.14)
	_water_mat.roughness = 0.03
	_water_mat.metallic_specular = 0.9


## A filled porcelain pitcher: lathe body, loop handle, water at the brim.
func pitcher(pos: Vector3, yaw: float, scale: float = 1.0, mat: String = "l96_porcelain") -> void:
	_pitcher_assets()
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	root.scale = Vector3.ONE * scale
	dress.add_child(root)
	var body := MeshInstance3D.new()
	body.mesh = _pitcher_mesh
	body.material_override = MatLib.get_mat(mat)
	root.add_child(body)
	for i in 5:
		var a := -0.3 + float(i) * 0.65
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.018, 0.05, 0.016)
		seg.mesh = bm
		seg.material_override = body.material_override
		seg.position = Vector3(0.09 + cos(a) * 0.035, 0.15 + sin(a) * 0.05, 0)
		seg.rotation.z = a + PI * 0.5
		root.add_child(seg)
	var wtr := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.046
	cm.bottom_radius = 0.046
	cm.height = 0.004
	cm.radial_segments = 16
	wtr.mesh = cm
	wtr.material_override = _water_mat
	wtr.position = Vector3(0, 0.245, 0)
	root.add_child(wtr)
	pitchers.append(pos)


# ------------------------------------------------------------------ rooms

func rooms(k: GeoKit) -> void:
	_hall(k)
	_sitting(k)
	_kitchen(k)
	_dining(k)
	_bedroom(k)
	_outside(k)


func _rug(k: GeoKit, c: Vector3, sx: float, sz: float, mat: String) -> void:
	k.box(c + Vector3(0, 0.006, 0), Vector3(sx, 0.012, sz), mat, GeoKit.PY | GeoKit.SIDES, false, "carpet")
	k.box(c + Vector3(0, 0.005, 0), Vector3(sx + 0.12, 0.01, sz + 0.12), "l96_rug_fringe", GeoKit.PY, false)


func _hall(k: GeoKit) -> void:
	_rug(k, Vector3(0, 0, 5.0), 3.0, 5.0, "l96_rug_a")
	# divans along both side walls, between the doorways
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 2.48, 0.2, 5.0), Vector3(0.72, 0.4, 3.7), "l96_wood")
		k.box(Vector3(s * 2.48, 0.47, 5.0), Vector3(0.7, 0.14, 3.6), "l96_cushion", GeoKit.ALL, false)
		k.box(Vector3(s * 2.76, 0.78, 5.0), Vector3(0.16, 0.5, 3.6), "l96_cushion", GeoKit.ALL, false)
		for i in 3:
			k.box(Vector3(s * 2.62, 0.72, 3.8 + i * 1.2), Vector3(0.14, 0.36, 0.42), "l96_rug_b", GeoKit.ALL, false)
	_p("ph/coffee_table_round_01", Vector3(0, 0.012, 5.0), 0.0, 0.42)
	pitcher(Vector3(0.12, 0.43, 5.05), 0.6)
	for i in 4:
		var a := float(i) * TAU / 4.0 + 0.4
		_p("kenney/food-kit/cup-tea", Vector3(cos(a) * 0.38, 0.43, 5.0 + sin(a) * 0.38), rad_to_deg(a), 0.07)
	_p("ph/lantern_chandelier_01", Vector3(0, 3.35, 5.0), 0.0)
	k.cylinder(Vector3(0, 4.42, 5.0), 0.012, 0.36, "l96_iron", 6, false)
	_p("ph/vintage_grandfather_clock_01", Vector3(-2.3, 0, 9.22), 180.0, 0.0, true)
	_p("ph/ornate_mirror_01", Vector3(-2.84, 1.25, 5.0), 90.0)
	_p("ph/wall_clock", Vector3(2.84, 2.2, 5.0), -90.0)
	for x in [-2.3, 2.3]:
		_p("kenney/furniture-kit/pottedplant", Vector3(x, 0, 1.0), 0.0, 1.1)
	dust_spots.append_array([Vector3(-1.1, 0, 2.6), Vector3(1.5, 0, 8.1), Vector3(-0.5, 0, 8.9)])


func _sitting(k: GeoKit) -> void:
	_rug(k, Vector3(-5.3, 0, 2.7), 2.6, 2.8, "l96_rug_b")
	_p("ph/Sofa_01", Vector3(-4.6, 0.012, 4.42), 180.0, 0.0, true)
	_p("ph/ArmChair_01", Vector3(-6.85, 0.012, 2.4), 90.0, 0.0, true)
	_p("ph/coffee_table_round_01", Vector3(-5.2, 0.012, 2.7), 0.0, 0.42)
	_p("ph/Shelf_01", Vector3(-7.05, 0, 0.66), 0.0, 0.0, true)
	_p("ph/ClassicNightstand_01", Vector3(-3.5, 0, 1.25), -90.0, 0.0, true)
	_p("ph/Television_01", Vector3(-3.5, 0.7, 1.25), -90.0)
	_p("ph/vintage_radio_transceiver", Vector3(-7.05, 1.05, 0.66), 0.0, 0.3)
	_p("kenney/furniture-kit/lamproundfloor", Vector3(-7.1, 0, 4.5), 0.0, 1.6)
	pitcher(Vector3(-5.1, 0.43, 2.6), 2.0, 0.85)
	dust_spots.append_array([Vector3(-4.0, 0, 1.0), Vector3(-6.2, 0, 3.9)])


func _kitchen(k: GeoKit) -> void:
	# counter under the back window, open shelving, the stove, a small table
	k.box_mm(Vector3(-7.5, 0, 8.9), Vector3(-3.4, 0.86, 9.5), "l96_cabinet")
	k.box_mm(Vector3(-7.52, 0.86, 8.86), Vector3(-3.38, 0.91, 9.5), "l96_marble", GeoKit.ALL, false)
	k.box_mm(Vector3(-5.95, 0.84, 9.0), Vector3(-5.05, 0.912, 9.4), "l96_iron", GeoKit.PY, false)
	_p("kenney/furniture-kit/kitchenstove", Vector3(-7.15, 0, 6.0), 90.0, 0.9, true)
	_p("ph/Shelf_01", Vector3(-3.3, 0, 6.0), -90.0, 0.0, true)
	for i in 3:
		pitcher(Vector3(-3.32, 0.39 + float(i) * 0.47, 5.75 + float(i % 2) * 0.4), 1.4 + i, 0.8)
	k.box(Vector3(-5.3, 0.74, 7.3), Vector3(1.1, 0.04, 0.75), "l96_wood", GeoKit.ALL, false)
	for c in [Vector3(-5.78, 0.36, 6.98), Vector3(-4.82, 0.36, 6.98), Vector3(-5.78, 0.36, 7.62), Vector3(-4.82, 0.36, 7.62)]:
		k.box(c, Vector3(0.05, 0.72, 0.05), "l96_wood", GeoKit.ALL, false)
	k.box(Vector3(-5.3, 0.36, 7.3), Vector3(1.0, 0.72, 0.65), "l96_wood", 0, true)
	for zz in [6.62, 7.98]:
		_stool(k, Vector3(-5.3, 0, zz))
	pitcher(Vector3(-5.5, 0.76, 7.25), 0.3)
	pitcher(Vector3(-5.1, 0.76, 7.4), 2.5, 0.9)
	pitcher(Vector3(-4.2, 0.91, 9.2), 1.1)
	pitcher(Vector3(-7.0, 0.9, 6.0), 0.0, 0.8, "l96_brass")
	_p("kenney/food-kit/bowl", Vector3(-6.6, 0.91, 9.2), 0.0, 0.08)
	_p("kenney/food-kit/cutting-board", Vector3(-3.9, 0.91, 9.15), 10.0, 0.03)
	dust_spots.append_array([Vector3(-6.3, 0, 8.2), Vector3(-4.0, 0, 5.8)])


func _stool(k: GeoKit, c: Vector3) -> void:
	k.box(c + Vector3(0, 0.45, 0), Vector3(0.4, 0.04, 0.4), "l96_wood", GeoKit.ALL, false)
	for o in [Vector3(-0.17, 0, -0.17), Vector3(0.17, 0, -0.17), Vector3(-0.17, 0, 0.17), Vector3(0.17, 0, 0.17)]:
		k.box(c + o + Vector3(0, 0.215, 0), Vector3(0.035, 0.43, 0.035), "l96_wood", GeoKit.ALL, false)


func _dining(k: GeoKit) -> void:
	_rug(k, Vector3(5.3, 0, 2.7), 3.2, 2.6, "l96_rug_a")
	_p("ph/dining_table", Vector3(5.3, 0.012, 2.7), 0.0, 0.0, true)
	for x in [4.6, 5.3, 6.0]:
		_p("ph/dining_chair_02", Vector3(x, 0.012, 1.62), 0.0)
		_p("ph/dining_chair_02", Vector3(x, 0.012, 3.78), 180.0)
	_p("ph/Chandelier_01", Vector3(5.3, 2.35, 2.7), 0.0)
	k.cylinder(Vector3(5.3, 3.28, 2.7), 0.012, 0.25, "l96_iron", 6, false)
	var ty := 0.89
	for x in [4.6, 5.3, 6.0]:
		for zz in [2.15, 3.25]:
			_p("kenney/food-kit/plate-dinner", Vector3(x, ty, zz), 0.0, 0.03)
			_p("kenney/food-kit/glass", Vector3(x + 0.2, ty, zz + (0.16 if zz > 3.0 else -0.16)), 0.0, 0.11)
	pitcher(Vector3(4.95, ty, 2.7), 0.2)
	pitcher(Vector3(5.75, ty, 2.72), 2.9)
	_p("kenney/food-kit/bowl", Vector3(5.35, ty, 2.7), 0.0, 0.1)
	_p("ph/wooden_bookshelf_worn", Vector3(4.25, 0, 4.52), 180.0, 0.0, true)
	dust_spots.append_array([Vector3(3.8, 0, 4.4), Vector3(7.0, 0, 1.0)])


func _bedroom(k: GeoKit) -> void:
	_rug(k, Vector3(5.6, 0, 7.6), 2.0, 2.6, "l96_rug_b")
	_p("ph/old_bed_frame", Vector3(6.85, 0, 8.35), 0.0, 0.0, true)
	k.box(Vector3(6.85, 0.5, 8.35), Vector3(0.84, 0.16, 1.9), "l96_linen", GeoKit.ALL, false)
	k.box(Vector3(6.85, 0.6, 8.0), Vector3(0.88, 0.05, 1.3), "l96_blanket", GeoKit.ALL, false)
	_p("kenney/furniture-kit/pillow", Vector3(6.85, 0.58, 9.0), 0.0, 0.14)
	_p("ph/ClassicNightstand_01", Vector3(5.85, 0, 9.18), 180.0, 0.0, true)
	# a painted wooden wardrobe against the hall wall
	k.box_mm(Vector3(3.16, 0, 5.3), Vector3(3.76, 2.05, 6.6), "l96_cabinet")
	k.box_mm(Vector3(3.15, 2.05, 5.25), Vector3(3.8, 2.12, 6.65), "l96_wood", GeoKit.ALL, false)
	k.box(Vector3(3.77, 1.05, 5.95), Vector3(0.02, 1.9, 0.03), "l96_iron", GeoKit.ALL, false)
	_p("ph/GreenChair_01", Vector3(4.2, 0, 8.8), 150.0)
	_p("kenney/furniture-kit/lampsquareceiling", Vector3(5.5, CEIL - 0.25, 7.5), 0.0, 0.25)
	pitcher(Vector3(5.75, 0.7, 9.15), 1.2, 0.8)
	dust_spots.append_array([Vector3(4.3, 0, 6.1), Vector3(5.2, 0, 8.6)])


func _outside(k: GeoKit) -> void:
	var gy: float = GY
	# front terrace: monobloc chairs turned to the view, a small table
	_p("ph/plastic_monobloc_chair_01", Vector3(-4.2, 0, -2.6), 190.0)
	_p("ph/plastic_monobloc_chair_01", Vector3(-2.7, 0, -2.9), 165.0)
	k.cylinder(Vector3(-3.45, 0.35, -2.0), 0.04, 0.7, "l96_iron", 8, false)
	k.cylinder(Vector3(-3.45, 0.71, -2.0), 0.36, 0.03, "l96_marble", 20, true)
	_p("kenney/food-kit/cup-coffee", Vector3(-3.35, 0.725, -2.05), 0.0, 0.08)
	for x in [-7.6, -6.6, 6.6, 7.6]:
		_p("kenney/furniture-kit/pottedplant", Vector3(x, 0, -3.8), x * 40.0, 0.9)
	pitcher(Vector3(-3.6, 0.725, -1.9), 1.0, 1.1, "l96_clay")
	# roof terrace: a water tank, plants, a chair at the parapet
	k.cylinder(Vector3(4.0, WING_H + 0.75, 8.9), 0.55, 1.5, "l96_iron", 16)
	_p("ph/plastic_monobloc_chair_01", Vector3(5.2, WING_H, 1.2), 175.0)
	_p("kenney/furniture-kit/pottedplant", Vector3(7.3, WING_H, 0.7), 0.0, 0.9)
	_p("kenney/furniture-kit/pottedplant", Vector3(3.6, WING_H, 0.7), 70.0, 0.8)
	# garden: grass in the corners, a few boulders, the broom's place by the back door
	for g in [[Vector3(-15.0, gy, -9.0), 20.0], [Vector3(14.5, gy, -9.5), -15.0], [Vector3(-13.5, gy, 5.0), 85.0]]:
		_p("ph/grass_medium_01", g[0], g[1])
	_p("ph/boulder_01", Vector3(-16.8, gy - 0.25, 15.6), 30.0, 0.0, true)
	_p("ph/boulder_01", Vector3(17.2, gy - 0.3, -10.6), 200.0, 0.8, true)
	_p("ph/plastic_monobloc_chair_01", Vector3(-12.0, gy, 13.5), 120.0)
	dust_spots.append(Vector3(2.4, 0, -2.4))
