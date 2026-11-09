extends RefCounted
## The scanner shown on every Level 15 terminal (SOURCE, "Entrances and Exits"):
## all devices show the same thing at any given time; objects cross the screen at
## constant rates (a few speed up or slow down); green lines link some objects but
## only while both are on screen; overlapping shapes are highlighted green; orange
## lines predict a shape's movement only while that shape is on screen and never
## change; the centre shape and a small circle on the right never move.
## One shared state, many displays: every display is redrawn from the same time.

const MOVERS := [
	# start (screen units, screen is [-1,1]^2), velocity per second, wobble amp, kind
	{"p": Vector2(-1.5, 0.55), "v": Vector2(0.050, -0.012), "w": 0.0, "kind": 0},
	{"p": Vector2(1.4, -0.7), "v": Vector2(-0.038, 0.020), "w": 0.0, "kind": 1},
	{"p": Vector2(-0.4, 1.5), "v": Vector2(0.008, -0.045), "w": 0.16, "kind": 2},
	{"p": Vector2(0.9, 1.3), "v": Vector2(-0.030, -0.034), "w": 0.0, "kind": 0},
	{"p": Vector2(-1.3, -1.2), "v": Vector2(0.040, 0.036), "w": 0.12, "kind": 1},
	{"p": Vector2(1.6, 0.25), "v": Vector2(-0.056, -0.004), "w": 0.0, "kind": 2},
	{"p": Vector2(0.2, -1.6), "v": Vector2(0.012, 0.050), "w": 0.0, "kind": 0},
]
const LINKS := [[0, 1], [2, 4], [3, 6], [5, -1]]   # -1 = centre shape
const CENTRE := Vector2(0.0, 0.0)
const CIRCLE := Vector2(0.74, 0.06)
const FIELD := 1.7      # movers wrap on [-FIELD, FIELD]
const SIZE := 0.075

var displays: Array = []     # [{node, w, h, movers:[MeshInstance3D], preds, links, ...}]
var mat: Dictionary = {}
var state: Dictionary = {}   # last computed shared state
var overlaps_seen := 0
var links_seen := 0


func _init() -> void:
	for pair in [["bg", Color(0.01, 0.035, 0.03)], ["grid", Color(0.05, 0.22, 0.16)], ["shape", Color(0.82, 0.92, 0.9)],
			["hit", Color(0.2, 1.0, 0.35)], ["link", Color(0.15, 0.85, 0.3)], ["pred", Color(1.0, 0.55, 0.12)],
			["centre", Color(0.9, 0.95, 1.0)]]:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = pair[1]
		m.disable_fog = true
		mat[pair[0]] = m


## Shared state at time t: positions, which shapes are on screen, overlaps.
func compute(t: float) -> Dictionary:
	var pos: Array = []
	var on: Array = []
	for m in MOVERS:
		var v: Vector2 = m["v"]
		var p: Vector2 = m["p"] + v * t
		if float(m["w"]) > 0.0:
			p += v.normalized() * float(m["w"]) * sin(t * 0.21)   # visibly speeds up, slows down
		p.x = fposmod(p.x + FIELD, FIELD * 2.0) - FIELD
		p.y = fposmod(p.y + FIELD, FIELD * 2.0) - FIELD
		pos.append(p)
		on.append(absf(p.x) < 0.95 and absf(p.y) < 0.95)
	var hit: Array = []
	hit.resize(pos.size())
	hit.fill(false)
	var centre_hit := false
	for i in pos.size():
		if not on[i]:
			continue
		for j in range(i + 1, pos.size()):
			if on[j] and (pos[i] as Vector2).distance_to(pos[j]) < SIZE * 1.6:
				hit[i] = true
				hit[j] = true
		if (pos[i] as Vector2).distance_to(CENTRE) < SIZE * 1.8:
			hit[i] = true
			centre_hit = true
	var links_on: Array = []
	for l in LINKS:
		links_on.append(on[l[0]] and (l[1] < 0 or on[l[1]]))
	state = {"t": t, "pos": pos, "on": on, "hit": hit, "centre_hit": centre_hit, "links": links_on}
	return state


func _quad(parent: Node3D, m: String, size: Vector2, z: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat[m]
	mi.position.z = z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _ring(parent: Node3D, m: String, r: float, z: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.outer_radius = r
	t.inner_radius = r * 0.94
	t.rings = 24
	t.ring_segments = 3
	mi.mesh = t
	mi.material_override = mat[m]
	mi.rotation.x = PI * 0.5
	mi.scale = Vector3(1, 0.05, 1)
	mi.position.z = z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A display on a screen of w x h metres. xf places the screen; local +Z faces the viewer.
func add_display(parent: Node, xf: Transform3D, w: float, h: float) -> Dictionary:
	var root := Node3D.new()
	root.name = "Radar%d" % displays.size()
	root.transform = xf
	parent.add_child(root)
	_quad(root, "bg", Vector2(w, h), 0.0)
	var s := minf(w, h) * 0.5          # screen unit -> metres
	var face := Node3D.new()
	face.scale = Vector3(s * w / minf(w, h), s, 1.0)
	root.add_child(face)
	for r in [0.33, 0.66, 0.95]:
		_ring(face, "grid", r, 0.002)
	_quad(face, "grid", Vector2(1.9, 0.008), 0.002)
	_quad(face, "grid", Vector2(0.008, 1.9), 0.002)
	var centre := _quad(face, "centre", Vector2(SIZE * 1.6, SIZE * 1.6), 0.006)
	centre.rotation.z = PI * 0.25
	var circ := _ring(face, "centre", 0.05, 0.006)
	circ.position = Vector3(CIRCLE.x, CIRCLE.y, 0.006)
	var fixed_link := _quad(face, "link", Vector2(1, 0.012), 0.004)
	_place_line(fixed_link, CENTRE, CIRCLE)
	var d := {"node": root, "face": face, "centre": centre, "movers": [], "preds": [], "links": []}
	for m in MOVERS:
		var q := _quad(face, "shape", Vector2(SIZE, SIZE), 0.008)
		if int(m["kind"]) == 1:
			q.rotation.z = PI * 0.25
		elif int(m["kind"]) == 2:
			q.scale = Vector3(1.6, 0.6, 1)
		d["movers"].append(q)
		d["preds"].append(_quad(face, "pred", Vector2(1, 0.01), 0.005))
	for l in LINKS:
		d["links"].append(_quad(face, "link", Vector2(1, 0.01), 0.004))
	displays.append(d)
	return d


static func _place_line(mi: MeshInstance3D, a: Vector2, b: Vector2) -> void:
	var dv := b - a
	var c := (a + b) * 0.5
	mi.position = Vector3(c.x, c.y, mi.position.z)
	mi.rotation.z = atan2(dv.y, dv.x)
	mi.scale = Vector3(maxf(dv.length(), 0.001), 1, 1)


## Clip a prediction ray from p along v to the screen edge.
static func _edge(p: Vector2, v: Vector2) -> Vector2:
	var n := v.normalized()
	var tmax := 4.0
	if absf(n.x) > 0.0001:
		tmax = minf(tmax, ((0.95 if n.x > 0 else -0.95) - p.x) / n.x)
	if absf(n.y) > 0.0001:
		tmax = minf(tmax, ((0.95 if n.y > 0 else -0.95) - p.y) / n.y)
	return p + n * maxf(tmax, 0.0)


## Redraw every display from the one shared state.
func update(t: float) -> void:
	var st := compute(t)
	if st["centre_hit"] or (st["hit"] as Array).has(true):
		overlaps_seen += 1
	if (st["links"] as Array).has(true):
		links_seen += 1
	for d in displays:
		if not is_instance_valid(d["node"]):
			continue
		(d["centre"] as MeshInstance3D).material_override = mat["hit"] if st["centre_hit"] else mat["centre"]
		for i in MOVERS.size():
			var q: MeshInstance3D = d["movers"][i]
			var p: Vector2 = st["pos"][i]
			q.visible = st["on"][i]
			q.position = Vector3(p.x, p.y, q.position.z)
			q.material_override = mat["hit"] if st["hit"][i] else mat["shape"]
			var pr: MeshInstance3D = d["preds"][i]
			pr.visible = st["on"][i]
			if pr.visible:
				_place_line(pr, p, _edge(p, MOVERS[i]["v"]))
		for li in LINKS.size():
			var lq: MeshInstance3D = d["links"][li]
			lq.visible = st["links"][li]
			if lq.visible:
				var a: Vector2 = st["pos"][LINKS[li][0]]
				var b: Vector2 = CENTRE if LINKS[li][1] < 0 else st["pos"][LINKS[li][1]]
				_place_line(lq, a, b)


## Every display shows the same frame: compare the drawn shape positions.
func displays_agree() -> bool:
	if displays.size() < 2:
		return false
	var ref: Dictionary = displays[0]
	for d in displays:
		for i in MOVERS.size():
			var a: MeshInstance3D = ref["movers"][i]
			var b: MeshInstance3D = d["movers"][i]
			if a.visible != b.visible or a.position.distance_to(b.position) > 0.0001:
				return false
	return true
