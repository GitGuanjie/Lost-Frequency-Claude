extends RefCounted
## Level 55 room shell: one rustic restaurant room per 24 m chunk (interior
## 18 x 18 m, centre at local (12, 0, 12)), four doorways joined to the
## neighbours by short corridors, a kitchen block with a pass window and an
## ordering counter in one corner, a rare restroom. Seating, light and
## sunbeams come from L055_dress.gd.
##
## Door offsets alternate with chunk parity so that opposite doorways of a
## room never line up (no straight sightline through three rooms).

const CHUNK := 24.0
const H := 9.0              # half interior size
const CEIL := 4.0
const DOOR_W := 2.2
const DOOR_H := 2.6
const OFF := 3.5
const KDEPTH := 3.6
const CORR_W := 2.4
const CORR_H := 2.75
const WAINSCOT := 1.1
const C := Vector3(12.0, 0.0, 12.0)
## side: 0 east (+X), 1 west (-X), 2 south (+Z), 3 north (-Z)
const N := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
const T := [Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(1, 0, 0)]


## Door offset (along the side's tangent) for side k of chunk (cx, cz).
static func door_off(cx: int, cz: int, k: int) -> float:
	var p := 0
	match k:
		0, 2: p = posmod(cx + cz, 2)
		1: p = posmod(cx - 1 + cz, 2)
		3: p = posmod(cx + cz - 1, 2)
	return OFF if p == 0 else -OFF


## Local point: `along` the side's tangent, `depth` metres in from its wall.
static func at(k: int, along: float, depth: float, y: float = 0.0) -> Vector3:
	return C + (N[k] as Vector3) * (H - depth) + (T[k] as Vector3) * along + Vector3(0, y, 0)


static func opposite(k: int) -> int:
	return [1, 0, 3, 2][k]


static func door_point(cx: int, cz: int, k: int) -> Vector3:
	return at(k, door_off(cx, cz, k), 0.0)


static func _wall_ab(k: int) -> Array:
	return [at(k, -H, 0.0), at(k, H, 0.0)]


# ---------------------------------------------------------------- shell

static func shell(k: GeoKit, cx: int, cz: int, d: Dictionary) -> void:
	var paper: String = d["paper"]
	var low: String = d["low"]
	# floorboards, ceiling planks and beams
	k.box_mm(Vector3(C.x - H - 0.15, -0.12, C.z - H - 0.15), Vector3(C.x + H + 0.15, 0.0, C.z + H + 0.15), "l55_floor")
	k.box_mm(Vector3(C.x - H - 0.15, CEIL, C.z - H - 0.15), Vector3(C.x + H + 0.15, CEIL + 0.15, C.z + H + 0.15), "l55_ceiling", GeoKit.NY, true)
	var along_x: bool = d["beam_x"]
	var i := -H + 1.5
	while i < H:
		var c := C + (Vector3(0, 0, i) if along_x else Vector3(i, 0, 0)) + Vector3(0, CEIL - 0.15, 0)
		k.box(c, Vector3(2.0 * H, 0.3, 0.24) if along_x else Vector3(0.24, 0.3, 2.0 * H), "l55_beam", GeoKit.ALL, false)
		i += 3.0
	k.box(C + Vector3(0, CEIL - 0.42, 0), Vector3(0.34, 0.24, 2.0 * H) if along_x else Vector3(2.0 * H, 0.24, 0.34), "l55_beam", GeoKit.ALL, false)
	# walls: brick or panelled wainscot, wallpaper above (tavern rooms are all brick)
	for s in 4:
		var ab := _wall_ab(s)
		var off := door_off(cx, cz, s) + H
		var ops := [{"at": off, "w": DOOR_W, "h": DOOR_H, "sill": 0.0}]
		var a: Vector3 = ab[0] + (N[s] as Vector3) * 0.15
		var b: Vector3 = ab[1] + (N[s] as Vector3) * 0.15
		if d["arch"] == 1:
			k.wall(a, b, CEIL, 0.3, "l55_brick", ops)
		else:
			k.wall(a, b, WAINSCOT, 0.3, low, [{"at": off, "w": DOOR_W, "h": DOOR_H, "sill": 0.0}])
			k.wall(a + Vector3(0, WAINSCOT, 0), b + Vector3(0, WAINSCOT, 0), CEIL - WAINSCOT, 0.3, paper, [{"at": off, "w": DOOR_W, "h": DOOR_H - WAINSCOT, "sill": 0.0}])
			# chair rail
			var ra: Vector3 = ab[0] - (N[s] as Vector3) * 0.0 + Vector3(0, WAINSCOT, 0)
			for seg in [[-H, off - H - DOOR_W * 0.5], [off - H + DOOR_W * 0.5, H]]:
				var l: float = seg[1] - seg[0]
				if l > 0.05:
					var mid := at(s, (seg[0] + seg[1]) * 0.5, 0.02, WAINSCOT)
					var sz := Vector3(0.06, 0.07, l) if absf((T[s] as Vector3).z) > 0.5 else Vector3(l, 0.07, 0.06)
					k.box(mid, sz, "l55_beam", GeoKit.ALL, false)
		# door frame
		var dp := at(s, off - H, 0.0)
		var t: Vector3 = T[s]
		for sg in [-1.0, 1.0]:
			k.box(dp + t * sg * (DOOR_W * 0.5 + 0.06) + Vector3(0, DOOR_H * 0.5, 0), _orient(s, Vector3(0.12, DOOR_H, 0.42)), "l55_beam", GeoKit.ALL, false)
		k.box(dp + Vector3(0, DOOR_H + 0.08, 0), _orient(s, Vector3(DOOR_W + 0.36, 0.16, 0.42)), "l55_beam", GeoKit.ALL, false)
	# corner posts
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(C + Vector3(sx * (H - 0.12), CEIL * 0.5, sz * (H - 0.12)), Vector3(0.26, CEIL, 0.26), "l55_beam", GeoKit.ALL, false)


## Size for a box lying along side s (x = along the wall, z = through it).
static func _orient(s: int, sz: Vector3) -> Vector3:
	if absf((T[s] as Vector3).z) > 0.5:
		return Vector3(sz.z, sz.y, sz.x)
	return sz


## Half a corridor on side s, from the wall face out to the chunk edge.
static func corridor(k: GeoKit, cx: int, cz: int, s: int, d: Dictionary) -> Vector3:
	var off := door_off(cx, cz, s)
	var n: Vector3 = N[s]
	var t: Vector3 = T[s]
	var p0 := at(s, off, -0.15)
	var len := CHUNK * 0.5 - H - 0.15
	var mid := p0 + n * (len * 0.5)
	k.box(mid + Vector3(0, -0.06, 0), _orient(s, Vector3(CORR_W + 0.3, 0.12, len)), "l55_floor")
	k.box(mid + Vector3(0, CORR_H + 0.06, 0), _orient(s, Vector3(CORR_W + 0.3, 0.12, len)), "l55_ceiling")
	for sg in [-1.0, 1.0]:
		var wc: Vector3 = mid + t * float(sg) * (CORR_W * 0.5 + 0.08)
		k.box(wc + Vector3(0, WAINSCOT * 0.5, 0), _orient(s, Vector3(0.16, WAINSCOT, len)), d["low"])
		k.box(wc + Vector3(0, WAINSCOT + (CORR_H - WAINSCOT) * 0.5, 0), _orient(s, Vector3(0.16, CORR_H - WAINSCOT, len)), "l55_paper_hall")
	# a header beam where the corridor meets the room
	k.box(p0 + n * 0.1 + Vector3(0, CORR_H - 0.1, 0), _orient(s, Vector3(CORR_W, 0.2, 0.2)), "l55_beam", GeoKit.ALL, false)
	return mid + Vector3(0, CORR_H - 0.3, 0)


# ---------------------------------------------------------------- kitchen

## Kitchen block in the corner of side ks on the half away from that side's
## door. Returns anchors: pass, counter, stove, sink, fridge, lamp, door.
static func kitchen(k: GeoKit, cx: int, cz: int, d: Dictionary) -> Dictionary:
	var ks: int = d["kside"]
	var off := door_off(cx, cz, ks)
	var a0 := -H if off > 0.0 else 0.6
	var a1 := -0.6 if off > 0.0 else H
	var inner_end := a1 if off > 0.0 else a0       # the end nearer the room's middle
	var out := {}
	# long pass wall (depth KDEPTH), with a serving hatch in its middle
	var pa := at(ks, a0, KDEPTH)
	var pb := at(ks, a1, KDEPTH)
	var span := absf(a1 - a0)
	k.wall(pa, pb, WAINSCOT, 0.2, d["low"], [{"at": span * 0.5, "w": 2.6, "h": 1.0, "sill": 1.05}])
	k.wall(pa + Vector3(0, WAINSCOT, 0), pb + Vector3(0, WAINSCOT, 0), CEIL - WAINSCOT, 0.2, d["paper"], [{"at": span * 0.5, "w": 2.6, "h": 1.0, "sill": 0.0}])
	k.box(at(ks, (a0 + a1) * 0.5, KDEPTH, 1.08), _orient(ks, Vector3(2.7, 0.06, 0.5)), "l55_steel")
	# end wall with the swing-door opening
	var ea := at(ks, inner_end, 0.0)
	var eb := at(ks, inner_end, KDEPTH)
	k.wall(ea, eb, CEIL, 0.2, "l55_tile_wall", [{"at": KDEPTH * 0.5, "w": 1.0, "h": 2.15, "sill": 0.0}])
	# tiled floor and walls inside
	var fa := at(ks, a0, 0.0)
	var fb := at(ks, a1, KDEPTH)
	k.box_mm(Vector3(minf(fa.x, fb.x), 0.0, minf(fa.z, fb.z)), Vector3(maxf(fa.x, fb.x), 0.012, maxf(fa.z, fb.z)), "l55_tile_floor", GeoKit.PY, false)
	var wa := at(ks, a0, 0.02, 0.0)
	var wb := at(ks, a1, 0.03, 2.2)
	k.box_mm(Vector3(minf(wa.x, wb.x), 0.0, minf(wa.z, wb.z)), Vector3(maxf(wa.x, wb.x), 2.2, maxf(wa.z, wb.z)), "l55_tile_wall", GeoKit.ALL, false)
	out["inner_end"] = inner_end
	out["a0"] = a0
	out["a1"] = a1
	var dir := 1.0 if off < 0.0 else -1.0      # from inner end toward the corner
	out["stove"] = at(ks, inner_end + dir * 2.4, 0.5)
	out["sink"] = at(ks, inner_end + dir * 4.2, 0.5)
	out["fridge"] = at(ks, inner_end + dir * 6.0, 0.55)
	out["cab"] = at(ks, inner_end + dir * 1.2, 0.5)
	out["prep"] = at(ks, inner_end + dir * 4.0, 2.0)
	out["lamp"] = at(ks, (a0 + a1) * 0.5, KDEPTH * 0.5, CEIL - 0.6)
	out["pass"] = at(ks, (a0 + a1) * 0.5, KDEPTH + 0.3, 1.1)
	out["door"] = at(ks, inner_end, KDEPTH * 0.5)
	# the ordering counter, out in the room in front of the hatch
	var cl := span - 2.2
	var cc := at(ks, (a0 + a1) * 0.5, KDEPTH + 1.35, 0.0)
	k.box(cc + Vector3(0, 0.5, 0), _orient(ks, Vector3(cl, 1.0, 0.62)), "l55_counter")
	k.box(cc + Vector3(0, 1.03, 0), _orient(ks, Vector3(cl + 0.12, 0.06, 0.74)), "l55_beam", GeoKit.ALL, false)
	k.box(cc + (N[ks] as Vector3) * -0.33 + Vector3(0, 0.08, 0), _orient(ks, Vector3(cl, 0.16, 0.04)), "l55_beam", GeoKit.ALL, false)
	out["counter"] = cc + Vector3(0, 1.06, 0)
	out["counter_len"] = cl
	# a menu board over the hatch
	out["menu"] = at(ks, (a0 + a1) * 0.5 + (2.3 if off > 0.0 else -2.3), KDEPTH + 0.12, 2.55)
	k.box(out["menu"], _orient(ks, Vector3(1.6, 1.0, 0.04)), "l55_board", GeoKit.ALL, false)
	k.box(out["menu"], _orient(ks, Vector3(1.72, 1.12, 0.03)), "l55_beam", GeoKit.ALL, false)
	return out


## A small restroom in the corner of side ks on the door's half.
static func restroom(k: GeoKit, cx: int, cz: int, d: Dictionary) -> Dictionary:
	var ks: int = d["kside"]
	var off := door_off(cx, cz, ks)
	var sg := 1.0 if off > 0.0 else -1.0
	var a0 := sg * 6.0
	var a1 := sg * H
	var pa := at(ks, a0, 3.0)
	var pb := at(ks, a1, 3.0)
	k.wall(pa, pb, CEIL, 0.16, "l55_tile_wall", [{"at": 1.4, "w": 0.85, "h": 2.1, "sill": 0.0}])
	k.wall(at(ks, a0, 0.0), at(ks, a0, 3.0), CEIL, 0.16, "l55_tile_wall")
	var fa := at(ks, a0, 0.0)
	var fb := at(ks, a1, 3.0)
	k.box_mm(Vector3(minf(fa.x, fb.x), 0.0, minf(fa.z, fb.z)), Vector3(maxf(fa.x, fb.x), 0.012, maxf(fa.z, fb.z)), "l55_tile_floor", GeoKit.PY, false)
	return {"toilet": at(ks, (a0 + a1) * 0.5 + sg * 0.6, 0.45), "sink": at(ks, a0 + sg * 0.5, 1.5), "door": at(ks, a0 + sg * 1.4, 3.0)}
