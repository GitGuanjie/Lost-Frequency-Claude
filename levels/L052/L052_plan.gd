extends RefCounted
## Level 52 layout. Authored anchors near the entrance (the shallow crawl, the
## first hall with the campfire alcove, a 2 m low gallery, the tall second hall
## with a ledge, a side loop) and then a seeded main gallery that keeps going
## east ("its length is unknown"). Floor heights are absolute.

const C := preload("res://levels/L052/L052_cave.gd")

const APRON := Vector3(-31.0, 0.0, 0.0)
const CRAWL := [Vector3(-25.6, 0.0, 0.0), Vector3(-21.0, -0.1, 0.5), Vector3(-16.0, -0.35, -0.4), Vector3(-11.0, -0.6, 0.4), Vector3(-6.4, -0.8, 0.2)]
const HALL1 := Vector3(8.0, -1.2, 0.0)
const ALCOVE := Vector3(10.0, -1.2, 10.5)
const FIRE := Vector3(9.6, -1.2, 10.6)
const HALL2 := Vector3(80.0, -3.6, 4.0)
const LEDGE := Vector3(87.0, 1.0, -11.5)

var seed_v := 0
var nodes: Array = []          # [{p, kind, ra, sq}]
var fixed: Array = []          # authored features


func _init(sd: int) -> void:
	seed_v = sd
	var r := RandomNumberGenerator.new()
	r.seed = hash([sd, "authored"])
	# authored spine (floor points); segment kind is stored on its first node
	var jit := func(v: Vector3, a: float) -> Vector3: return v + Vector3(0, 0, r.randf_range(-a, a))
	nodes = [
		{"p": Vector3(-1.0, -1.2, 0.2), "kind": "normal"},
		{"p": jit.call(Vector3(14.0, -1.2, -1.0), 1.5), "kind": "normal"},
		{"p": jit.call(Vector3(30.0, -1.6, 3.0), 2.5), "kind": "low"},
		{"p": jit.call(Vector3(45.0, -2.2, -2.0), 2.5), "kind": "low"},
		{"p": jit.call(Vector3(60.0, -2.8, 2.0), 2.0), "kind": "normal"},
		{"p": Vector3(78.0, -3.6, 4.0), "kind": "normal"},
		{"p": jit.call(Vector3(98.0, -3.4, 0.0), 2.0), "kind": "normal"},
	]
	# the few metres in front of the mouth, the crawl's rock sleeve, the halls
	_room(APRON + Vector3(0, 0, 0), Vector3(5.0, 2.7, 4.6), 0.9)
	var sleeve: Array = [APRON + Vector3(2.0, 0, 0)]
	sleeve.append_array(CRAWL)
	sleeve.append(Vector3(-1.5, -1.0, 0.2))
	for i in sleeve.size() - 1:
		var a: Vector3 = sleeve[i]
		var b: Vector3 = sleeve[i + 1]
		_add({"t": "tube", "a": a + Vector3(0, 1.0, 0), "b": b + Vector3(0, 1.0, 0), "ra": 1.8, "rb": 1.8, "sq": 0.9,
			"fa": a.y - 0.3, "fb": b.y - 0.3, "amp": 0.25})
	_room(HALL1, Vector3(13.0, 6.5, 10.0), 1.5, 0.45)
	_room(ALCOVE, Vector3(5.5, 2.4, 4.0), 0.8)
	_room(HALL2, Vector3(16.0, 9.0, 12.0), 1.8, 0.6)
	# a ramp along the north wall of the second hall up to a ledge 4.6 m above its floor
	_add({"t": "tube", "a": Vector3(72.0, -2.6, -3.0), "b": Vector3(80.5, 2.0, -11.5), "ra": 2.1, "rb": 2.1, "sq": 0.9, "fa": -3.6, "fb": 1.0, "amp": 0.5})
	_room(LEDGE, Vector3(7.0, 2.8, 4.5), 0.7)
	# a narrower side loop north of the low gallery (two ways between the halls)
	var loop := [Vector3(5.0, -1.2, -7.0), Vector3(22.0, -0.6, -16.0), Vector3(40.0, -1.3, -16.5), Vector3(57.0, -2.7, -8.0)]
	for i in loop.size() - 1:
		var a2: Vector3 = loop[i]
		var b2: Vector3 = loop[i + 1]
		_add({"t": "tube", "a": a2 + Vector3(0, 1.1, 0), "b": b2 + Vector3(0, 1.1, 0), "ra": 2.2, "rb": 2.0, "sq": 0.85, "fa": a2.y, "fb": b2.y, "amp": 0.6})


func _add(f: Dictionary) -> void:
	f["bb"] = C.aabb_of(f)
	fixed.append(f)


func _room(fl: Vector3, r: Vector3, amp: float, fn: float = 0.0) -> void:
	_add({"t": "room", "c": fl + Vector3(0, r.y * 0.45, 0), "r": r, "f": fl.y, "amp": amp, "fn": fn})


## Grow the seeded spine until it reaches x.
func ensure(x: float) -> void:
	while (nodes[nodes.size() - 1]["p"] as Vector3).x < x:
		var i := nodes.size()
		var prev: Vector3 = nodes[i - 1]["p"]
		var r := RandomNumberGenerator.new()
		r.seed = hash([seed_v, "node", i])
		var roll := r.randf()
		var kind := "normal"
		if roll < 0.25:
			kind = "low"
		elif roll < 0.4:
			kind = "canyon"
		elif roll < 0.55:
			kind = "hall"
		var p := Vector3(prev.x + r.randf_range(16.0, 22.0), clampf(prev.y + r.randf_range(-1.6, 1.6), -14.0, 4.0), clampf(prev.z + r.randf_range(-9.0, 9.0), -30.0, 30.0))
		var n := {"p": p, "kind": kind, "pocket": r.randf() < 0.35, "pside": -1.0 if r.randf() < 0.5 else 1.0,
			"hr": Vector3(r.randf_range(9.0, 14.0), r.randf_range(5.0, 9.0), r.randf_range(7.0, 11.0))}
		nodes.append(n)


func seg_feature(i: int) -> Dictionary:
	var a: Vector3 = nodes[i]["p"]
	var b: Vector3 = nodes[i + 1]["p"]
	var kind: String = nodes[i]["kind"]
	match kind:
		"low":
			# wide and flat: the ceiling is barely above head height
			return {"t": "tube", "a": a + Vector3(0, 0.9, 0), "b": b + Vector3(0, 0.9, 0), "ra": 3.2, "rb": 3.2, "sq": 0.45, "fa": a.y, "fb": b.y, "amp": 0.3, "fn": 0.12}
		"canyon":
			return {"t": "tube", "a": a + Vector3(0, 2.6, 0), "b": b + Vector3(0, 2.6, 0), "ra": 2.6, "rb": 2.4, "sq": 2.3, "fa": a.y, "fb": b.y, "amp": 0.9, "fn": 0.3}
	return {"t": "tube", "a": a + Vector3(0, 1.3, 0), "b": b + Vector3(0, 1.3, 0), "ra": 3.1, "rb": 3.0, "sq": 0.95, "fa": a.y, "fb": b.y, "amp": 0.9, "fn": 0.3}


## Features that may touch the region [x0, x1] x [z0, z1].
func features_for(region: AABB) -> Array:
	ensure(region.end.x + 40.0)
	var out: Array = []
	for f in fixed:
		if (f["bb"] as AABB).intersects(region):
			out.append(f)
	for i in nodes.size() - 1:
		var pa: Vector3 = nodes[i]["p"]
		var pb: Vector3 = nodes[i + 1]["p"]
		if maxf(pa.x, pb.x) < region.position.x - 40.0 or minf(pa.x, pb.x) > region.end.x + 40.0:
			continue
		var fs: Array = [seg_feature(i)]
		if i >= 7 and nodes[i]["kind"] == "hall":
			var hr: Vector3 = nodes[i]["hr"]
			fs.append({"t": "room", "c": pa + Vector3(0, hr.y * 0.45, 0), "r": hr, "f": pa.y, "amp": 1.6, "fn": 0.5})
		if i >= 7 and nodes[i].get("pocket", false):
			var dir := (pb - pa).normalized()
			var side := Vector3(-dir.z, 0, dir.x) * float(nodes[i]["pside"])
			var pc := pa.lerp(pb, 0.5) + side * 9.0
			fs.append({"t": "room", "c": pc + Vector3(0, 1.4, 0), "r": Vector3(4.5, 2.8, 4.0), "f": pc.y, "amp": 0.9})
			fs.append({"t": "tube", "a": pa.lerp(pb, 0.5) + Vector3(0, 1.2, 0), "b": pc + Vector3(0, 1.2, 0), "ra": 1.9, "rb": 1.9, "sq": 0.9, "fa": pa.lerp(pb, 0.5).y, "fb": pc.y, "amp": 0.5})
		for f in fs:
			f["bb"] = C.aabb_of(f)
			if (f["bb"] as AABB).intersects(region):
				out.append(f)
	return out


## Floor points along the spine inside a chunk (for dressing), with the segment kind.
func spine_points(x0: float, x1: float, z0: float, z1: float, step: float) -> Array:
	var out: Array = []
	for i in nodes.size() - 1:
		var pa: Vector3 = nodes[i]["p"]
		var pb: Vector3 = nodes[i + 1]["p"]
		var l := pa.distance_to(pb)
		var n := maxi(1, int(l / step))
		for s in n:
			var p := pa.lerp(pb, (float(s) + 0.5) / n)
			if p.x >= x0 and p.x < x1 and p.z >= z0 and p.z < z1:
				out.append({"p": p, "kind": nodes[i]["kind"], "dir": (pb - pa).normalized()})
	return out
