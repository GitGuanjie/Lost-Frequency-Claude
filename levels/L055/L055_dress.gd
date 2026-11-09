extends RefCounted
## Level 55 room dressing: tables and chairs (merged boxes, cheap), booths,
## a raised dais, kitchen appliances and food (Kenney CC0), pendant lamps,
## and the sunbeams: a spot light with a dusty shaft that starts in mid-air
## (the page's "unperceivable source"), never at a window.

const R := preload("res://levels/L055/L055_room.gd")
const KS := 2.05
const ROOMS := 32               # the finite set of rooms that move around
const PAPERS := ["l55_paper0", "l55_paper1", "l55_paper2", "l55_paper3"]
const LOWS := ["l55_panel", "l55_brick", "l55_panel"]

var lvl


func _init(level) -> void:
	lvl = level


## Room design `i` of the level's finite set (seeded by the level seed).
static func design(i: int, level_seed: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, i, 5505])
	return {"id": i, "arch": i % 4, "kside": r.randi() % 4, "paper": PAPERS[r.randi() % PAPERS.size()],
		"low": LOWS[r.randi() % LOWS.size()], "bath": r.randf() < 0.22, "dais": (i % 4 == 1) or (i % 4 == 3 and r.randf() < 0.5),
		"beam_x": r.randf() < 0.5, "beams": 1 + int(r.randf() < 0.55), "stacked": r.randf() < 0.3, "seed": r.randi()}


# ---------------------------------------------------------------- furniture blocks

static func chair(k: GeoKit, p: Vector3, yaw: float, mat: String = "l55_chair", tipped: bool = false) -> void:
	var b := Basis(Vector3.UP, yaw)
	if tipped:
		b = b * Basis(Vector3.RIGHT, -PI * 0.5)
		p += Vector3(0, 0.22, 0)
	var parts := [[Vector3(0, 0.45, 0), Vector3(0.42, 0.05, 0.42)], [Vector3(0, 0.75, -0.19), Vector3(0.42, 0.5, 0.04)]]
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			parts.append([Vector3(sx, 0.215, sz), Vector3(0.04, 0.43, 0.04)])
	for q in parts:
		k.box_xf(Transform3D(b, p + b * (q[0] as Vector3)), q[1], mat, GeoKit.ALL, false)


static func table(k: GeoKit, p: Vector3, size: Vector2, yaw: float, top: String = "l55_table", cloth: bool = false) -> void:
	var b := Basis(Vector3.UP, yaw)
	var hh := 0.76
	k.box_xf(Transform3D(b, p + Vector3(0, hh - 0.025, 0)), Vector3(size.x, 0.05, size.y), "l55_cloth" if cloth else top, GeoKit.ALL, false)
	if cloth:
		k.box_xf(Transform3D(b, p + Vector3(0, hh - 0.2, 0)), Vector3(size.x + 0.04, 0.34, size.y + 0.04), "l55_cloth", GeoKit.SIDES, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, p + b * Vector3(sx * (size.x * 0.5 - 0.07), (hh - 0.05) * 0.5, sz * (size.y * 0.5 - 0.07))), Vector3(0.06, hh - 0.05, 0.06), "l55_chair", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, p + Vector3(0, hh * 0.5, 0)), Vector3(size.x, hh, size.y), "wood")


static func round_table(k: GeoKit, p: Vector3, r: float) -> void:
	k.cylinder(p + Vector3(0, 0.74, 0), r, 0.04, "l55_table", 14, false)
	k.cylinder(p + Vector3(0, 0.37, 0), 0.05, 0.72, "l55_steel", 6, false)
	k.cylinder(p + Vector3(0, 0.02, 0), 0.24, 0.04, "l55_steel", 10, false)
	k.add_box_shape(Transform3D(Basis(), p + Vector3(0, 0.38, 0)), Vector3(r * 1.5, 0.76, r * 1.5), "wood")


## A booth: two benches with high backs facing a table, against a wall.
static func booth(k: GeoKit, p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	for sg in [-1.0, 1.0]:
		var c := p + b * Vector3(0, 0, sg * 0.85)
		k.box_xf(Transform3D(b, c + Vector3(0, 0.23, 0)), Vector3(1.5, 0.46, 0.5), "l55_booth", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b * Vector3(0, 0.75, sg * 0.24)), Vector3(1.5, 0.6, 0.12), "l55_booth", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b * Vector3(0, 0.3, sg * 0.27)), Vector3(1.56, 1.6, 0.06), "l55_beam", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(b, c + Vector3(0, 0.55, 0)), Vector3(1.5, 1.1, 0.5), "wood")
	table(k, p, Vector2(1.3, 0.7), yaw)


static func bench(k: GeoKit, p: Vector3, yaw: float, len: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, p + Vector3(0, 0.44, 0)), Vector3(len, 0.06, 0.32), "l55_table", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, p + b * Vector3(sx * (len * 0.5 - 0.15), 0.21, 0)), Vector3(0.06, 0.42, 0.28), "l55_chair", GeoKit.ALL, false)


# ---------------------------------------------------------------- seating

## Fill the dining floor. Returns table-top points (for food, beams, lamps).
func seating(k: GeoKit, node: Node3D, cx: int, cz: int, d: Dictionary, r: RandomNumberGenerator, dais: Dictionary) -> Array:
	var ks: int = d["kside"]
	var arch: int = d["arch"]
	var tops: Array = []
	var doors: Array = []
	for s in 4:
		doors.append([R.door_point(cx, cz, s), -(R.N[s] as Vector3)])
	var t: Vector3 = R.T[ks]
	var yaw_along := atan2(t.x, t.z)
	var step_a := 3.3 if arch == 1 else (2.2 if arch == 2 else 2.6)
	var step_d := 2.6 if arch == 1 else 2.3
	var depth := 6.9
	while depth < 2.0 * R.H - 1.2:
		var along := -R.H + 1.6
		while along < R.H - 1.4:
			var p := R.at(ks, along + r.randf_range(-0.2, 0.2), depth + r.randf_range(-0.15, 0.15))
			var y := 0.0
			if not dais.is_empty() and _in_rect(p, dais["rect"]):
				y = dais["y"]
			elif not dais.is_empty() and _in_rect(p, _grow(dais["rect"], 1.0)):
				along += step_a
				continue
			if _near_aisle(p, doors, 1.35 if arch != 1 else 1.8) or r.randf() < 0.06:
				along += step_a
				continue
			p.y = y
			_table_set(k, node, p, arch, yaw_along, r, d)
			tops.append(p + Vector3(0, 0.78, 0))
			along += step_a
		depth += step_d
	# booths along the side opposite the kitchen in diners
	if arch == 0 and dais.is_empty():
		var opp := R.opposite(ks)
		var off := R.door_off(cx, cz, opp)
		var a := -R.H + 1.0
		while a < R.H - 0.8:
			if absf(a - off) > 2.2:
				var bp := R.at(opp, a, 0.95)
				booth(k, bp, atan2(t.x, t.z))
				tops.append(bp + Vector3(0, 0.78, 0))
			a += 2.5
	return tops


func _table_set(k: GeoKit, node: Node3D, p: Vector3, arch: int, yaw: float, r: RandomNumberGenerator, d: Dictionary) -> void:
	var stacked: bool = d["stacked"]
	match arch:
		1:  # tavern: long communal table, benches
			table(k, p, Vector2(2.8, 0.9), yaw + PI * 0.5)
			var b := Basis(Vector3.UP, yaw + PI * 0.5)
			for sg in [-1.0, 1.0]:
				bench(k, p + b * Vector3(0, 0, sg * 0.75), yaw + PI * 0.5, 2.6)
		2:  # cafe: small round tables, two or three chairs
			round_table(k, p, 0.42)
			var n := 2 + r.randi() % 2
			var a0 := r.randf() * TAU
			for i in n:
				var a := a0 + TAU * i / n
				var cp := p + Vector3(cos(a), 0, sin(a)) * 0.68
				chair(k, cp, atan2(-cos(a), -sin(a)), "l55_chair", r.randf() < 0.06)
		_:  # diner / dining room: square or long tables with chairs
			var cloth := arch == 3
			var long := arch == 3 and r.randf() < 0.6
			var sz := Vector2(1.6, 0.9) if long else Vector2(0.9, 0.9)
			table(k, p, sz, yaw, "l55_table", cloth)
			var b := Basis(Vector3.UP, yaw)
			var seats: Array = []
			if long:
				for sx in [-0.4, 0.4]:
					seats.append([Vector3(sx, 0, -0.68), 0.0])
					seats.append([Vector3(sx, 0, 0.68), PI])
			else:
				seats = [[Vector3(0, 0, -0.68), 0.0], [Vector3(0, 0, 0.68), PI], [Vector3(-0.68, 0, 0), PI * 0.5], [Vector3(0.68, 0, 0), -PI * 0.5]]
			for s in seats:
				if stacked and r.randf() < 0.7:
					# closing time: chairs upturned on the table top
					var up := Basis(Vector3.UP, yaw + float(s[1])) * Basis(Vector3.RIGHT, PI)
					var cp := p + b * ((s[0] as Vector3) * 0.4) + Vector3(0, 0.78 + 0.88, 0)
					_chair_xf(k, Transform3D(up, cp))
				else:
					var jitter := Vector3(r.randf_range(-0.08, 0.08), 0, r.randf_range(-0.08, 0.12))
					chair(k, p + b * ((s[0] as Vector3) + jitter), yaw + float(s[1]) + r.randf_range(-0.25, 0.25), "l55_chair", r.randf() < 0.05)


static func _chair_xf(k: GeoKit, xf: Transform3D) -> void:
	var parts := [[Vector3(0, 0.45, 0), Vector3(0.42, 0.05, 0.42)], [Vector3(0, 0.75, -0.19), Vector3(0.42, 0.5, 0.04)]]
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			parts.append([Vector3(sx, 0.215, sz), Vector3(0.04, 0.43, 0.04)])
	for q in parts:
		k.box_xf(Transform3D(xf.basis, xf * (q[0] as Vector3)), q[1], "l55_chair", GeoKit.ALL, false)


static func _in_rect(p: Vector3, rc: Rect2) -> bool:
	return rc.has_point(Vector2(p.x, p.z))


static func _grow(rc: Rect2, m: float) -> Rect2:
	return rc.grow(m)


static func _near_aisle(p: Vector3, doors: Array, w: float) -> bool:
	for dd in doors:
		var a: Vector3 = dd[0]
		var n: Vector3 = dd[1]
		var rel := p - a
		var along := rel.dot(n)
		if along > -0.5 and along < 10.0:
			var side := (rel - n * along)
			side.y = 0.0
			if side.length() < w:
				return true
	return false


## A raised dais (three steps up) on the half of the side opposite the
## kitchen that has no door. Returns {rect, y} or {}.
func dais(k: GeoKit, cx: int, cz: int, d: Dictionary) -> Dictionary:
	if not d["dais"]:
		return {}
	var s := R.opposite(d["kside"])
	var off := R.door_off(cx, cz, s)
	var a0 := -R.H if off > 0.0 else 0.8
	var a1 := -0.8 if off > 0.0 else R.H
	var y := 0.45
	var p0 := R.at(s, a0, 0.0)
	var p1 := R.at(s, a1, 3.6)
	var mn := Vector3(minf(p0.x, p1.x), 0.0, minf(p0.z, p1.z))
	var mx := Vector3(maxf(p0.x, p1.x), y, maxf(p0.z, p1.z))
	k.box_mm(mn, mx, "l55_floor")
	var n: Vector3 = R.N[s]
	var t: Vector3 = R.T[s]
	# steps down into the room from the dais front, in its middle
	var front := R.at(s, (a0 + a1) * 0.5, 3.6 + 0.9)
	k.stairs(front, n, 2.0, y, 3, "l55_floor", 0.3, true)
	# a turned rail along the front, broken by the steps
	for seg in [[a0 + 0.1, (a0 + a1) * 0.5 - 1.1], [(a0 + a1) * 0.5 + 1.1, a1 - 0.1]]:
		var l: float = seg[1] - seg[0]
		var c := R.at(s, (seg[0] + seg[1]) * 0.5, 3.55, y)
		k.box(c + Vector3(0, 0.9, 0), R._orient(s, Vector3(l, 0.07, 0.07)), "l55_beam", GeoKit.ALL, false)
		var nb := int(l / 0.3)
		for i in nb:
			var bp := R.at(s, seg[0] + (i + 0.5) * l / nb, 3.55, y)
			k.box(bp + Vector3(0, 0.45, 0), Vector3(0.05, 0.9, 0.05), "l55_chair", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), c + Vector3(0, 0.5, 0)), R._orient(s, Vector3(l, 1.0, 0.1)), "wood")
	k.box(R.at(s, (a0 + a1) * 0.5, 3.6, y - 0.08), R._orient(s, Vector3(absf(a1 - a0), 0.16, 0.04)), "l55_beam", GeoKit.ALL, false)
	return {"rect": Rect2(Vector2(mn.x, mn.z), Vector2(mx.x - mn.x, mx.z - mn.z)), "y": y}


# ---------------------------------------------------------------- kitchen props

func _kn(node: Node3D, name: String, p: Vector3, yaw: float, collide: bool = false, mult: float = 1.0) -> Node3D:
	var id := "kenney/furniture-kit/" + name
	return Props.place(lvl, node, id, p, yaw, maxf(Props.bounds(id).size.y * KS * mult, 0.01), collide)


func _food(node: Node3D, name: String, p: Vector3, yaw: float, h: float) -> Node3D:
	return Props.place(lvl, node, "kenney/food-kit/" + name, p, yaw, h, false)


func kitchen_props(node: Node3D, d: Dictionary, ka: Dictionary, r: RandomNumberGenerator) -> void:
	var ks: int = d["kside"]
	var yaw := rad_to_deg(atan2(-(R.N[ks] as Vector3).x, -(R.N[ks] as Vector3).z))
	_kn(node, "kitchenstove", ka["stove"], yaw, true)
	_kn(node, "kitchensink", ka["sink"], yaw, true)
	_kn(node, "kitchenfridgelarge", ka["fridge"], yaw, true)
	_kn(node, "kitchencabinetdrawer", ka["cab"], yaw, true)
	_kn(node, "kitchencabinetupper", (ka["stove"] as Vector3) + Vector3(0, 1.45, 0) + (R.N[ks] as Vector3) * 0.22, yaw)
	# stainless prep table
	var pp: Vector3 = ka["prep"]
	table(GeoKit.new(node, "Prep"), pp, Vector2(1.8, 0.8), deg_to_rad(yaw), "l55_steel")
	var st: Vector3 = ka["stove"]
	_food(node, ["pot-stew", "pan-stew", "pot"][r.randi() % 3], st + Vector3(0, 0.95, 0), r.randf() * 360.0, 0.22)
	_food(node, "frying-pan", st + (R.T[ks] as Vector3) * 0.3 + Vector3(0, 0.95, 0), r.randf() * 360.0, 0.06)
	_food(node, "cutting-board", pp + Vector3(0, 0.78, 0), r.randf() * 360.0, 0.03)
	_food(node, "knife-block", pp + (R.T[ks] as Vector3) * 0.6 + Vector3(0, 0.78, 0), yaw, 0.25)
	if r.randf() < 0.6:
		_food(node, "bowl", pp + (R.T[ks] as Vector3) * -0.5 + Vector3(0, 0.78, 0), 0.0, 0.1)
	# the counter: a till, cups, a jug of plain water
	var cc: Vector3 = ka["counter"]
	var t: Vector3 = R.T[ks]
	var cl: float = ka["counter_len"]
	Props.place(lvl, node, "ph/CashRegister_01", cc + t * (cl * 0.3), yaw + 180.0, 0.0, false)
	_food(node, "cup-coffee", cc - t * (cl * 0.2), r.randf() * 360.0, 0.12)
	_food(node, "mug", cc - t * (cl * 0.25), r.randf() * 360.0, 0.1)
	# stools along the counter
	var n := int(cl / 0.9)
	for i in n:
		var sp := cc - Vector3(0, 1.06, 0) + t * ((i + 0.5) * cl / n - cl * 0.5) - (R.N[ks] as Vector3) * 0.75
		Props.place(lvl, node, "ph/bar_chair_round_01", sp, r.randf() * 360.0, 0.0, false)


# ---------------------------------------------------------------- light

## Pendant lamps over some tables; a dead one now and then. Returns anchors.
func lamps(node: Node3D, tops: Array, d: Dictionary, r: RandomNumberGenerator, origin: Vector3) -> Array:
	var out: Array = []
	var ids := ["ph/lantern_chandelier_01"] if d["arch"] == 1 else ["ph/hanging_industrial_lamp", "ph/modern_ceiling_lamp_01"]
	var picks := tops.duplicate()
	var sr := RandomNumberGenerator.new()
	sr.seed = r.randi()
	for i in range(picks.size() - 1, 0, -1):
		var j := sr.randi() % (i + 1)
		var tmp = picks[i]
		picks[i] = picks[j]
		picks[j] = tmp
	var id: String = ids[r.randi() % ids.size()]
	for i in mini(2, picks.size()):
		var tp: Vector3 = picks[i]
		var hb := Props.bounds(id).size.y
		var hang := minf(hb, 1.2)
		Props.place(lvl, node, id, Vector3(tp.x, R.CEIL - hang, tp.z), r.randf() * 360.0, hang, false)
		var dead := r.randf() < 0.25
		if not dead:
			out.append([origin + Vector3(tp.x, R.CEIL - hang - 0.15, tp.z), Color(1.0, 0.74, 0.46), 0.6, 7.5, 0.0])
	return out


const SHAFT := """
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.82, 0.55);
uniform float strength = 0.1;
varying vec3 wp;
float hsh(vec3 p) { p = fract(p * 0.3183099 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float along = UV.y;
	float fade = smoothstep(0.0, 0.45, along) * (1.0 - smoothstep(0.7, 0.93, along));
	float rim = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.6);
	vec3 cell = floor(wp * 26.0 + vec3(0.0, TIME * 0.4, 0.0));
	float mote = step(0.9965, hsh(cell)) * 3.0;
	ALBEDO = tint * strength * fade * (rim + mote);
}
"""


## A sunbeam: from a point high in the room (nothing visible there) down to
## `hit`. Returns the beam's floor point.
func beam(node: Node3D, hit: Vector3, r: RandomNumberGenerator, shadows: bool) -> Vector3:
	var pitch := deg_to_rad(r.randf_range(38.0, 58.0))
	var h := R.CEIL - 0.35
	var hl := (h - hit.y) / tan(pitch)
	var src := Vector3.ZERO
	for i in 12:
		var yaw := r.randf() * TAU
		src = hit + Vector3(cos(yaw) * hl, h - hit.y, sin(yaw) * hl)
		if absf(src.x - R.C.x) < R.H - 0.6 and absf(src.z - R.C.z) < R.H - 0.6:
			break
	src.x = clampf(src.x, R.C.x - R.H + 0.6, R.C.x + R.H - 0.6)
	src.z = clampf(src.z, R.C.z - R.H + 0.6, R.C.z + R.H - 0.6)
	var sp := SpotLight3D.new()
	sp.name = "Sunbeam"
	node.add_child(sp)
	sp.transform = Transform3D(Basis.looking_at(hit - src, Vector3.UP if absf((hit - src).normalized().y) < 0.99 else Vector3.RIGHT), src)
	sp.light_color = Color(1.0, 0.84, 0.6)
	sp.light_energy = 20.0
	sp.spot_range = src.distance_to(hit) + 3.0
	sp.spot_angle = 11.0
	sp.spot_angle_attenuation = 0.6
	sp.spot_attenuation = 0.4
	sp.shadow_enabled = shadows
	sp.light_specular = 0.6
	# the visible shaft
	var len := src.distance_to(hit) + 1.2
	var cm := CylinderMesh.new()
	var r1 := tan(deg_to_rad(11.0)) * len * 0.9
	cm.top_radius = 0.06
	cm.bottom_radius = r1
	cm.height = len
	cm.radial_segments = 12
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = MatLib.get_mat("l55_shaft")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dir := (hit - src).normalized()
	var b := Basis(Quaternion(Vector3.DOWN, dir))
	mi.transform = Transform3D(b, src + dir * (len * 0.5))
	node.add_child(mi)
	return Vector3(hit.x, hit.y, hit.z)


static func shaft_material() -> void:
	var sh := Shader.new()
	sh.code = SHAFT
	var m := ShaderMaterial.new()
	m.shader = sh
	MatLib.register("l55_shaft", m)


# ---------------------------------------------------------------- small dressing

func table_dressing(node: Node3D, tops: Array, r: RandomNumberGenerator) -> void:
	var items := [["plate", 0.03], ["plate-dinner", 0.03], ["cup", 0.1], ["glass", 0.13], ["mug", 0.1], ["cup-saucer", 0.08], ["bowl", 0.08]]
	for tp in tops:
		if r.randf() < 0.45:
			var it: Array = items[r.randi() % items.size()]
			var off := Vector3(r.randf_range(-0.25, 0.25), 0, r.randf_range(-0.2, 0.2))
			_food(node, it[0], (tp as Vector3) + off + Vector3(0, 0.0, 0), r.randf() * 360.0, it[1])


## Pictures, a shelf of jars and bottles, a coat rack, barrels in taverns.
func wall_dressing(k: GeoKit, node: Node3D, cx: int, cz: int, d: Dictionary, r: RandomNumberGenerator) -> void:
	var ks: int = d["kside"]
	var shelf_done := false
	for s in 4:
		if s == ks:
			continue
		var off := R.door_off(cx, cz, s)
		var yaw := atan2(-(R.N[s] as Vector3).x, -(R.N[s] as Vector3).z)
		var a := -R.H + 1.4
		while a < R.H - 1.2:
			if absf(a - off) > 2.0 and r.randf() < 0.55:
				var w := r.randf_range(0.45, 0.9)
				var h := r.randf_range(0.4, 0.7)
				var c := R.at(s, a, 0.04, r.randf_range(1.75, 2.15))
				var b := Basis(Vector3.UP, yaw)
				k.box_xf(Transform3D(b, c), Vector3(w + 0.08, h + 0.08, 0.04), "l55_beam", GeoKit.ALL, false)
				k.box_xf(Transform3D(b, c + b.z * 0.022), Vector3(w, h, 0.004), "l55_pic%d" % (r.randi() % 4), GeoKit.ALL, false)
			a += r.randf_range(1.8, 2.8)
		if not shelf_done and r.randf() < 0.6:
			shelf_done = true
			var sa := -off * 1.6
			var sc := R.at(s, sa, 0.14, 1.65)
			k.box(sc, R._orient(s, Vector3(1.8, 0.04, 0.26)), "l55_beam", GeoKit.ALL, false)
			k.box(sc + Vector3(0, 0.6, 0), R._orient(s, Vector3(1.8, 0.04, 0.26)), "l55_beam", GeoKit.ALL, false)
			var items := [["soda-bottle", 0.26], ["can", 0.12], ["pot", 0.16], ["carton", 0.2], ["bag", 0.22], ["mug", 0.1]]
			for row in [0.02, 0.62]:
				for i in 4:
					var it: Array = items[r.randi() % items.size()]
					var ip := R.at(s, sa - 0.7 + i * 0.47, 0.14, 1.67 + row)
					_food(node, it[0], ip, r.randf() * 360.0, it[1])
	# a coat rack by one doorway
	var cs := (ks + 1 + r.randi() % 3) % 4
	if cs != ks:
		var cp := R.at(cs, R.door_off(cx, cz, cs) + (1.6 if R.door_off(cx, cz, cs) < 0.0 else -1.6), 0.35)
		Props.place(lvl, node, "kenney/furniture-kit/coatrackstanding", cp, r.randf() * 360.0, 1.85, false)
	if d["arch"] == 1:
		for i in 3:
			var corner := Vector3(R.C.x + (R.H - 0.6) * (1.0 if i % 2 == 0 else -1.0), 0.0, R.C.z + (R.H - 0.6) * (1.0 if i < 2 else -1.0))
			Props.place(lvl, node, "kenney/food-kit/barrel", corner + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)), r.randf() * 360.0, 0.95, true)
