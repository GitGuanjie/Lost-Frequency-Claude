extends RefCounted
## Level 23 layout: the carved air pockets inside the tree superorganism.
## Zone 1: the Base Seedling glow room and its tunnels (bark and root-mat).
## Zone 2: the hollow core around the Heart of Water.
## Zone 3: the surface clearing under the canopy (its ceiling is cut away).
## Zone 4: the ruin grove glow room.
## Zone 0: cut (nothing is meshed).

const C := preload("res://levels/L023/L023_cave.gd")

const ROOM_A := Vector3(0.0, 0.0, 0.0)        # Base Seedling glow room floor centre
const ROOM_A_R := Vector3(30.0, 12.0, 24.0)
const ROOM_B := Vector3(10.0, 3.0, -80.0)     # ruin grove floor centre
const ROOM_B_R := Vector3(34.0, 14.0, 25.0)
const CORE := Vector3(-102.0, -10.0, 10.0)    # hollow core floor centre (the Heart)
const CORE_R := Vector3(38.0, 20.0, 38.0)
const SURF := Vector3(96.0, 12.0, -10.0)      # surface clearing floor centre
const SURF_R := Vector3(40.0, 6.0, 40.0)
const SURF_CUT := 14.2
const HEART_R := 12.5
const WATER_Y := -10.7

var features: Array = []
var paths: Dictionary = {}


func _init() -> void:
	_room(ROOM_A, ROOM_A_R, 0.9, 0.12, 1)
	_room(ROOM_B, ROOM_B_R, 1.0, 0.12, 4)
	_room(CORE, CORE_R, 1.4, 0.15, 2)
	_room(SURF, SURF_R, 0.6, 0.18, 3)
	# the Heart of Water basin: a bowl sunk into the core floor
	_add({"t": "room", "c": CORE + Vector3(0, -0.4, 0), "r": Vector3(HEART_R, 2.8, HEART_R), "amp": 0.25, "z": 2})
	var tp := {"cy": 1.7, "ra": 2.7, "sq": 0.85, "amp": 0.45, "fn": 0.1, "z": 1}
	paths["grove"] = [Vector3(7.0, 0.0, -17.0), Vector3(14.0, 0.4, -31.0), Vector3(5.0, 1.2, -43.0), Vector3(12.0, 2.3, -53.0), Vector3(10.0, 3.0, -62.0)]
	paths["surface"] = [Vector3(24.0, 0.0, 4.0), Vector3(37.0, 1.6, 11.0), Vector3(49.0, 4.4, 4.0), Vector3(59.0, 7.6, -5.0), Vector3(69.0, 10.6, -9.0), Vector3(79.0, 12.0, -10.0)]
	paths["core"] = [Vector3(-24.0, 0.0, 6.0), Vector3(-37.0, -1.8, 13.0), Vector3(-49.0, -4.6, 5.0), Vector3(-59.0, -7.4, 11.0), Vector3(-68.0, -9.6, 10.0), Vector3(-76.0, -10.0, 10.0)]
	for k in paths.keys():
		var pts: Array = paths[k]
		for i in pts.size() - 1:
			_seg(pts[i], pts[i + 1], tp)


func _add(f: Dictionary) -> void:
	f["bb"] = C.aabb_of(f)
	features.append(f)


func _room(fl: Vector3, r: Vector3, amp: float, fn: float, zone: int) -> void:
	_add({"t": "room", "c": fl + Vector3(0, r.y * 0.45, 0), "r": r, "f": fl.y, "amp": amp, "fn": fn, "z": zone})


func _seg(a: Vector3, b: Vector3, p: Dictionary) -> void:
	_add({"t": "tube", "a": a + Vector3(0, p["cy"], 0), "b": b + Vector3(0, p["cy"], 0), "ra": p["ra"], "rb": p["ra"],
		"sq": p["sq"], "fa": a.y, "fb": b.y, "amp": p["amp"], "fn": p["fn"], "z": p["z"]})


static func zone_of(p: Vector3) -> int:
	if p.x > 57.0:
		return 0 if p.y > SURF_CUT else 3
	if p.x < -64.0:
		return 2
	if p.z < -52.0:
		return 4
	return 1


func features_for(region: AABB) -> Array:
	var out: Array = []
	for f in features:
		if (f["bb"] as AABB).intersects(region):
			out.append(f)
	return out


func bounds() -> AABB:
	var b: AABB = features[0]["bb"]
	for f in features:
		b = b.merge(f["bb"])
	return b
