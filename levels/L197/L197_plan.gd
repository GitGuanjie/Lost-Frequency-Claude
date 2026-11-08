extends RefCounted
## Level 197 authored layout (not seeded). Floor heights are absolute metres.
## The route is folded into a U so that the documented Zone 3 exit lies about
## 65 m (straight line) from the arrival:
##   Zone 1 (turquoise) east from the arrival hall and M.E.G. Outpost "Good Feels",
##     with the hidden Meditation Cove on a loop to the north and an unlit side path;
##   Zone 2 (amethyst) south through a narrow, haphazard passage with two open areas,
##     two pitch-black grooves and a breach in the floor to the graphite layer below;
##   Zone 3 (ruby) west: 3 m bores, an incline, a junction with an 83-degree chimney up
##     to a tunnel that opens on the Crimson Fortress, and the unlit buzzing tunnel.
## Zones: 1 turquoise, 2 amethyst, 3 ruby, 4 graphite (Zone 2's second layer).

const C := preload("res://levels/L197/L197_cave.gd")

const HALL_A := Vector3(0.0, 0.0, 0.0)
const OUTPOST := Vector3(-0.5, 0.0, -2.6)
const ARRIVAL := Vector3(4.6, 0.0, 2.4)
const J1 := Vector3(38.0, 0.0, 1.0)
const COVE := Vector3(33.0, -1.5, 31.0)
const COVE_R := 10.0
const THRESH := Vector3(67.2, -0.6, -5.2)       # Zone 1 -> Zone 2 (the amethyst wall grows here)
const KNEE := Vector3(71.0, -1.1, -22.0)        # past this point the way back shatters
const O1 := Vector3(72.0, -1.2, -27.0)
const O2 := Vector3(58.0, -1.6, -40.0)
const BREACH := Vector3(60.3, -1.6, -42.3)
const GRAPHITE_Y := -5.4
const GROOM := Vector3(71.0, -5.6, -47.0)
const Z3_IN := Vector3(45.0, -2.0, -41.0)
const R1 := Vector3(18.0, 0.0, -47.0)
const CHIMNEY := Vector3(21.2, 0.0, -44.2)
const UPPER_Y := 6.8
const MOUTH := Vector3(12.0, 7.0, -74.0)
const VOID_Z := -74.4                            # the Crimson Fortress chamber starts south of this
const FLUO_END := Vector3(-3.0, -1.0, -67.0)
const EXIT_L000 := Vector3(-1.4, -0.95, -64.0)

# Tube profiles: cy = axis height above the floor, ra = radius, sq = vertical squash.
const P1 := {"cy": 1.6, "ra": 2.4, "sq": 1.5, "amp": 0.14, "fn": 0.04, "z": 1}       # 15 ft x 17 ft
const P1N := {"cy": 1.35, "ra": 1.75, "sq": 1.45, "amp": 0.18, "fn": 0.05, "z": 1}   # cove passage
const P2 := {"cy": 1.1, "ra": 1.25, "sq": 1.55, "amp": 0.22, "fn": 0.08, "z": 2}       # ~7 ft x 5 ft (kept above head height)
const P3 := {"cy": 1.2, "ra": 1.75, "sq": 1.0, "amp": 0.24, "fn": 0.08, "z": 3}      # 10 ft x 10 ft
const PG := {"cy": 1.0, "ra": 1.5, "sq": 1.0, "amp": 0.3, "fn": 0.12, "z": 4}

var features: Array = []
var lit_path: Array = []       # floor points where turquoise bunches light the lit path
var unlit_path: Array = []
var cove_path: Array = []
var z2_path: Array = []
var z3_path: Array = []
var fluo_path: Array = []
var upper_path: Array = []
var graphite_path: Array = []


func _init() -> void:
	_room(HALL_A, Vector3(8.5, 5.6, 7.0), 0.22, 0.04, 1)
	lit_path = [Vector3(5.0, 0, 0), Vector3(14.0, 0, -2.5), Vector3(24.0, 0, -3.0), Vector3(33.0, 0, -0.5), J1,
		Vector3(46.0, 0, 3.0), Vector3(54.0, 0, 3.5), Vector3(61.0, -0.3, 1.0), Vector3(65.5, -0.5, -2.2)]
	_path(lit_path, P1)
	_room(J1 + Vector3(1.0, 0, 0.5), Vector3(5.5, 5.8, 5.0), 0.2, 0.04, 1)
	# the lit path narrows into the amethyst passage
	_seg(Vector3(65.5, -0.5, -2.2), Vector3(68.2, -0.7, -8.0), P1, P2)
	# Meditation Cove: off J1, a narrower, darker passage curving north and down
	cove_path = [J1 + Vector3(1.0, 0, 3.0), Vector3(41.0, -0.3, 11.0), Vector3(38.5, -0.8, 18.0), Vector3(35.0, -1.3, 23.0)]
	_path(cove_path, P1N)
	_room(COVE, Vector3(COVE_R, 9.5, COVE_R), 0.45, 0.05, 1)
	# the loop back west to the arrival hall
	var loop := [Vector3(24.5, -1.5, 30.0), Vector3(17.0, -1.1, 25.0), Vector3(9.0, -0.6, 15.0), Vector3(3.0, -0.2, 7.5), Vector3(0.5, 0, 4.0)]
	cove_path.append_array(loop)
	_path(loop, P1)
	# the unlit path (rumoured to reach Level 108; unconfirmed, so it simply goes on into the dark)
	unlit_path = [Vector3(54.0, 0, 4.0), Vector3(57.0, 0.2, 11.0), Vector3(63.0, 0.4, 18.0), Vector3(70.0, 0.6, 22.0), Vector3(77.0, 0.8, 21.0), Vector3(82.0, 1.0, 17.0)]
	_path(unlit_path, P1)
	# ----- Zone 2
	z2_path = [Vector3(68.2, -0.7, -8.0), Vector3(70.6, -0.8, -13.0), Vector3(69.0, -1.0, -18.0), KNEE,
		Vector3(72.0, -1.2, -27.0), Vector3(71.5, -1.2, -30.5), Vector3(68.0, -1.4, -33.5), Vector3(63.0, -1.5, -36.2),
		O2, Vector3(53.5, -1.7, -41.5), Vector3(49.0, -1.9, -42.0), Z3_IN]
	_path(z2_path, P2)
	_room(O1, Vector3(4.6, 2.9, 4.0), 0.5, 0.14, 2)
	_room(O2, Vector3(5.6, 3.0, 4.6), 0.5, 0.14, 2)
	# grooves: pitch-black side pockets
	_seg(Vector3(75.0, -1.2, -27.5), Vector3(80.0, -1.0, -25.0), P2, P2)
	_room(Vector3(81.2, -1.0, -24.6), Vector3(2.4, 1.7, 2.1), 0.45, 0.1, 2)
	_seg(Vector3(64.5, -1.5, -35.0), Vector3(61.0, -1.4, -29.5), P2, P2)
	_room(Vector3(60.2, -1.4, -28.4), Vector3(2.3, 1.7, 2.2), 0.45, 0.1, 2)
	# the breach in the floor and the graphite layer ~3.4 m below
	_add({"t": "tube", "a": Vector3(BREACH.x, GRAPHITE_Y + 0.6, BREACH.z), "b": Vector3(BREACH.x, BREACH.y + 1.0, BREACH.z),
		"ra": 0.95, "rb": 0.95, "sq": 1.0, "amp": 0.15, "z": 4})
	graphite_path = [Vector3(51.5, GRAPHITE_Y, -36.5), Vector3(BREACH.x, GRAPHITE_Y, BREACH.z), Vector3(65.5, -5.5, -43.0), GROOM]
	_path(graphite_path, PG)
	_room(GROOM, Vector3(6.0, 2.7, 5.0), 0.6, 0.15, 4)
	# ----- Zone 3
	z3_path = [Z3_IN, Vector3(38.0, -1.8, -44.0), Vector3(31.0, -1.0, -46.8), Vector3(24.5, 0.0, -47.5), R1]
	_path(z3_path, P3)
	_room(R1, Vector3(5.0, 3.6, 4.4), 0.22, 0.06, 3)
	fluo_path = [R1 + Vector3(-1.5, 0, -1.5), Vector3(11.0, -0.3, -53.0), Vector3(6.0, -0.6, -56.0), Vector3(2.0, -0.8, -59.0), Vector3(-0.8, -1.0, -63.0), FLUO_END]
	_path(fluo_path, P3)
	# the 83-degree chimney (no floor cut) up to the upper bore
	_add({"t": "tube", "a": CHIMNEY + Vector3(0, 0.6, 0), "b": CHIMNEY + Vector3(0, UPPER_Y + 0.9, 0),
		"ra": 1.15, "rb": 1.05, "sq": 1.0, "amp": 0.12, "z": 3})
	_room(Vector3(CHIMNEY.x + 0.6, UPPER_Y, CHIMNEY.z - 1.6), Vector3(3.0, 2.4, 3.2), 0.25, 0.06, 3)
	upper_path = [Vector3(CHIMNEY.x + 0.6, UPPER_Y, CHIMNEY.z - 3.0), Vector3(24.0, 6.9, -52.0), Vector3(22.0, 7.0, -60.0), Vector3(16.5, 7.0, -66.0), Vector3(MOUTH.x, 7.0, -71.0), Vector3(MOUTH.x, 7.0, -77.5)]
	_path(upper_path, P3)


func _add(f: Dictionary) -> void:
	f["bb"] = C.aabb_of(f)
	features.append(f)


func _room(fl: Vector3, r: Vector3, amp: float, fn: float, zone: int) -> void:
	_add({"t": "room", "c": fl + Vector3(0, r.y * 0.45, 0), "r": r, "f": fl.y, "amp": amp, "fn": fn, "z": zone})


func _seg(a: Vector3, b: Vector3, pa: Dictionary, pb: Dictionary) -> void:
	_add({"t": "tube", "a": a + Vector3(0, pa["cy"], 0), "b": b + Vector3(0, pb["cy"], 0), "ra": pa["ra"], "rb": pb["ra"],
		"sq": (float(pa["sq"]) + float(pb["sq"])) * 0.5, "fa": a.y, "fb": b.y, "amp": (float(pa["amp"]) + float(pb["amp"])) * 0.5,
		"fn": pa["fn"], "z": pa["z"]})


func _path(pts: Array, p: Dictionary) -> void:
	for i in pts.size() - 1:
		_seg(pts[i], pts[i + 1], p, p)


## Mineral zone of a point (used per quad by the mesher and per frame by the mood).
## Returns 0 for points that are cut away (the tunnel end inside the Fortress chamber).
static func zone_of(p: Vector3) -> int:
	if p.z < VOID_Z + 0.4 and p.y > 3.0:
		return 0
	if p.x > 47.0 and p.x < 82.0 and p.z > -56.0 and p.z < -34.0 and p.y < -2.0:
		return 4
	if p.x > 64.0 and p.x < 82.0 and p.z > -56.0 and p.z < -42.6:
		return 4
	if p.z < -36.0 and p.x < 46.5:
		return 3
	if p.z < -60.0:
		return 3
	if p.x > 62.0 and p.z < -3.6:
		return 2
	if p.z < -28.0 and p.x >= 46.5:
		return 2
	return 1


## Features touching a box.
func features_for(region: AABB) -> Array:
	var out: Array = []
	for f in features:
		if (f["bb"] as AABB).intersects(region):
			out.append(f)
	return out


## Bounds of all features (used to enumerate build blocks).
func bounds() -> AABB:
	var b: AABB = features[0]["bb"]
	for f in features:
		b = b.merge(f["bb"])
	return b
