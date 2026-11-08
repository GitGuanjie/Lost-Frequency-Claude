extends RefCounted
## Level 17 compartment dressing and small builders: berthing racks, galley,
## radio room, storeroom, engineering flats, compartment clocks (each keeps its
## own time), notice boards with the Project RAINBOW schematic, occupants.
## All functions are static and take the sector builder `sb` (L017_sector.gd).

const PA := 5.0
const PF := 7.0
const LOW := -3.2
const ROOMS := {"AP": [-9.2, -3.0, 0.2, PA], "AS": [3.0, 9.2, 0.2, PA], "FP": [-9.2, -3.0, PF, 11.8], "FS": [3.0, 9.2, PF, 11.8]}
const RATES := [0.0, 1.0, 1.0, -1.0, 14.0, 0.25, 120.0, 1.0, 0.0, -6.0]


static func materials() -> void:
	var paints := [[Color(0.27, 0.3, 0.26), 0.25], [Color(0.24, 0.26, 0.22), 0.5], [Color(0.18, 0.19, 0.16), 0.8]]
	for i in 3:
		var c: Color = paints[i][0]
		var st: float = paints[i][1]
		MatLib.define("l17_paint%d" % i, {"albedo_a": c, "albedo_b": c * 0.9, "noise_scale": 0.7, "pattern": 1,
			"pattern_scale": Vector2(1.8, 1.2), "grout_width": 0.004, "grout_color": c * 0.75, "tile_variation": 0.015,
			"roughness_a": 0.55, "roughness_b": 0.8, "bump_strength": 0.35, "stain_amount": st, "stain_color": Color(0.2, 0.15, 0.08),
			"stain_scale": 0.5, "grime_height": 0.45 + st, "grime_color": Color(0.16, 0.13, 0.09), "floor_y": 0.0}, "")
		var d := [Color(0.13, 0.045, 0.035), Color(0.11, 0.045, 0.035), Color(0.075, 0.045, 0.03)][i] as Color
		MatLib.define("l17_deck%d" % i, {"albedo_a": d, "albedo_b": d * 0.85, "pattern": 1, "pattern_scale": Vector2(0.23, 0.23),
			"grout_width": 0.01, "grout_color": d * 0.6, "tile_variation": 0.025, "roughness_a": 0.45, "roughness_b": 0.75,
			"stain_amount": st, "stain_color": Color(0.05, 0.04, 0.03), "wetness": 0.1 * i, "noise_scale": 1.2}, "")
	MatLib.define("l17_overhead", {"albedo_a": Color(0.36, 0.36, 0.33), "albedo_b": Color(0.3, 0.3, 0.27), "noise_scale": 0.5,
		"stain_amount": 0.4, "stain_color": Color(0.3, 0.25, 0.15), "roughness_a": 0.7}, "")
	MatLib.define("l17_hullside", {"albedo_a": Color(0.25, 0.27, 0.23), "albedo_b": Color(0.2, 0.22, 0.19), "pattern": 1,
		"pattern_scale": Vector2(2.4, 1.0), "grout_width": 0.008, "grout_color": Color(0.2, 0.2, 0.18), "bump_strength": 0.5,
		"stain_amount": 0.45, "stain_color": Color(0.25, 0.15, 0.07), "grime_height": 0.6, "grime_color": Color(0.12, 0.1, 0.07)}, "")
	MatLib.define("l17_steel", {"albedo_a": Color(0.2, 0.21, 0.2), "albedo_b": Color(0.15, 0.15, 0.14), "metallic_value": 0.35,
		"roughness_a": 0.5, "roughness_b": 0.85, "stain_amount": 0.5, "stain_color": Color(0.22, 0.12, 0.05), "bump_strength": 0.6}, "")
	MatLib.define("l17_plate", {"albedo_a": Color(0.14, 0.14, 0.13), "albedo_b": Color(0.1, 0.1, 0.09), "pattern": 1,
		"pattern_scale": Vector2(1.5, 1.0), "grout_width": 0.004, "grout_color": Color(0.06, 0.06, 0.06), "tile_variation": 0.02, "noise_scale": 2.0, "metallic_value": 0.5,
		"roughness_a": 0.45, "roughness_b": 0.8, "stain_amount": 0.6, "stain_color": Color(0.04, 0.03, 0.02), "wetness": 0.3}, "")
	MatLib.define("l17_tread", {"albedo_a": Color(0.22, 0.22, 0.2), "albedo_b": Color(0.17, 0.17, 0.16), "pattern": 9,
		"pattern_scale": Vector2(0.05, 0.05), "pattern_strength": 0.35, "metallic_value": 0.5, "roughness_a": 0.4}, "metal")
	MatLib.define("l17_door", {"albedo_a": Color(0.36, 0.39, 0.35), "albedo_b": Color(0.3, 0.32, 0.29), "metallic_value": 0.3,
		"roughness_a": 0.5, "stain_amount": 0.3, "stain_color": Color(0.25, 0.14, 0.06), "bump_strength": 0.4}, "")
	MatLib.define("l17_rail", {"albedo_a": Color(0.5, 0.52, 0.48), "albedo_b": Color(0.42, 0.44, 0.4), "metallic_value": 0.4, "roughness_a": 0.4}, "")
	MatLib.define("l17_lagging", {"albedo_a": Color(0.42, 0.4, 0.35), "albedo_b": Color(0.34, 0.32, 0.27), "pattern": 2,
		"pattern_scale": Vector2(0.4, 0.4), "pattern_strength": 0.15, "stain_amount": 0.5, "stain_color": Color(0.3, 0.24, 0.14)}, "")
	MatLib.define("l17_pipe_red", {"albedo_a": Color(0.36, 0.05, 0.03), "albedo_b": Color(0.28, 0.04, 0.03), "roughness_a": 0.5, "stain_amount": 0.3}, "")
	MatLib.define("l17_brass", {"albedo_a": Color(0.42, 0.3, 0.12), "albedo_b": Color(0.3, 0.2, 0.08), "metallic_value": 0.8, "roughness_a": 0.35}, "")
	MatLib.define("l17_canvas", {"albedo_a": Color(0.4, 0.38, 0.3), "albedo_b": Color(0.33, 0.31, 0.24), "pattern": 2, "pattern_scale": Vector2(0.05, 0.05), "pattern_strength": 0.1}, "")
	MatLib.define("l17_mattress", {"albedo_a": Color(0.46, 0.45, 0.4), "albedo_b": Color(0.4, 0.38, 0.33), "pattern": 2,
		"pattern_scale": Vector2(0.12, 0.12), "pattern_color": Color(0.22, 0.25, 0.32), "pattern_strength": 0.4, "stain_amount": 0.4, "stain_color": Color(0.3, 0.24, 0.12)}, "")
	MatLib.define("l17_blanket", {"albedo_a": Color(0.14, 0.15, 0.17), "albedo_b": Color(0.1, 0.11, 0.13)}, "")
	MatLib.define("l17_locker", {"albedo_a": Color(0.3, 0.33, 0.3), "albedo_b": Color(0.26, 0.28, 0.25), "pattern": 2,
		"pattern_scale": Vector2(0.04, 0.6), "pattern_strength": 0.25, "metallic_value": 0.3, "stain_amount": 0.25}, "")
	MatLib.define("l17_stainless", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.4, 0.4, 0.4), "metallic_value": 0.8, "roughness_a": 0.3, "roughness_b": 0.5, "stain_amount": 0.2}, "")
	MatLib.define("l17_black", {"albedo_a": Color(0.04, 0.04, 0.04), "albedo_b": Color(0.03, 0.03, 0.03), "metallic_value": 0.4, "roughness_a": 0.6}, "")
	MatLib.define("l17_wood", {"albedo_a": Color(0.3, 0.17, 0.08), "albedo_b": Color(0.24, 0.13, 0.06), "pattern": 3, "pattern_scale": Vector2(0.15, 1.5), "roughness_a": 0.5}, "")
	MatLib.define("l17_boiler", {"albedo_a": Color(0.17, 0.17, 0.16), "albedo_b": Color(0.12, 0.11, 0.1), "metallic_value": 0.3,
		"stain_amount": 0.7, "stain_color": Color(0.24, 0.1, 0.04), "bump_strength": 0.8, "pattern": 1, "pattern_scale": Vector2(1.0, 0.8), "grout_width": 0.01, "grout_color": Color(0.05, 0.05, 0.05)}, "")
	MatLib.define("l17_paper", {"albedo_a": Color(0.62, 0.58, 0.46), "albedo_b": Color(0.55, 0.5, 0.38), "stain_amount": 0.4, "stain_color": Color(0.4, 0.3, 0.15)}, "")
	MatLib.define("l17_blueprint", {"albedo_a": Color(0.05, 0.12, 0.32), "albedo_b": Color(0.04, 0.1, 0.28), "pattern": 1,
		"pattern_scale": Vector2(0.05, 0.05), "grout_width": 0.04, "grout_color": Color(0.2, 0.3, 0.5), "roughness_a": 0.9}, "")
	MatLib.define("l17_cork", {"albedo_a": Color(0.32, 0.2, 0.1), "albedo_b": Color(0.26, 0.16, 0.08), "noise_scale": 8.0}, "")
	MatLib.define("l17_sheet", {"albedo_a": Color(0.55, 0.54, 0.5), "albedo_b": Color(0.46, 0.45, 0.41), "stain_amount": 0.35, "stain_color": Color(0.3, 0.22, 0.14), "roughness_a": 0.95}, "")
	MatLib.define("l17_navy", {"albedo_a": Color(0.012, 0.016, 0.04), "albedo_b": Color(0.01, 0.013, 0.03), "roughness_a": 0.9, "stain_amount": 0.4, "stain_color": Color(0.12, 0.05, 0.03), "stain_scale": 1.5}, "")
	MatLib.define("l17_dungaree", {"albedo_a": Color(0.18, 0.24, 0.34), "albedo_b": Color(0.14, 0.19, 0.28), "stain_amount": 0.3, "stain_color": Color(0.15, 0.12, 0.08)}, "")
	MatLib.define("l17_skin", {"albedo_a": Color(0.5, 0.36, 0.28), "albedo_b": Color(0.44, 0.3, 0.23)}, "")
	MatLib.define("l17_white", {"albedo_a": Color(0.7, 0.7, 0.67), "albedo_b": Color(0.62, 0.62, 0.6)}, "")
	MatLib.define("l17_sludge", {"albedo_a": Color(0.025, 0.018, 0.01), "albedo_b": Color(0.04, 0.025, 0.012), "roughness_a": 0.15, "roughness_b": 0.35, "metallic_value": 0.2}, "")
	MatLib.define("l17_scorch", {"albedo_a": Color(0.03, 0.028, 0.025), "albedo_b": Color(0.07, 0.06, 0.05), "noise_scale": 3.0, "roughness_a": 0.9, "bump_strength": 1.2}, "")
	MatLib.define("l17_chart", {"albedo_a": Color(0.62, 0.6, 0.5), "albedo_b": Color(0.55, 0.55, 0.47), "pattern": 1, "pattern_scale": Vector2(0.12, 0.12),
		"grout_width": 0.03, "grout_color": Color(0.3, 0.38, 0.5), "stain_amount": 0.3, "stain_color": Color(0.45, 0.4, 0.25)}, "")
	MatLib.define("l17_frost", {"albedo_a": Color(0.7, 0.74, 0.78), "albedo_b": Color(0.55, 0.6, 0.66), "noise_scale": 4.0, "roughness_a": 0.3, "roughness_b": 0.6}, "")
	MatLib.define("l17_skinless", {"albedo_a": Color(0.32, 0.07, 0.06), "albedo_b": Color(0.24, 0.05, 0.05), "pattern": 2,
		"pattern_scale": Vector2(0.02, 0.3), "pattern_color": Color(0.42, 0.18, 0.15), "pattern_strength": 0.35, "roughness_a": 0.35}, "")
	MatLib.register("l17_blue", MatLib.panel(Color(0.3, 0.55, 1.0), 0.9, 0.15))
	MatLib.register("l17_blue_dim", MatLib.panel(Color(0.3, 0.5, 1.0), 1.5, 0.3))
	MatLib.register("l17_bulb", MatLib.panel(Color(1.0, 0.8, 0.52), 3.0))
	MatLib.register("l17_dial", MatLib.panel(Color(1.0, 0.62, 0.2), 1.6, 0.05))
	MatLib.register("l17_dial_green", MatLib.panel(Color(0.4, 1.0, 0.45), 1.3))


# ------------------------------------------------------------------ small builders

static func label(sb, text: String, p: Vector3, n: Vector3, px: float, col: Color, size := 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.basis = Basis.looking_at(-n, Vector3.UP)
	l.position = p + n * 0.012
	l.visibility_range_end = 30.0
	sb.node.add_child(l)
	return l


## A flat disc (axis along local z) as a child of parent.
static func disc(parent: Node3D, r: float, depth: float, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = depth
	cm.radial_segments = 16
	cm.rings = 1
	mi.mesh = cm
	mi.rotation.x = PI * 0.5
	mi.material_override = MatLib.get_mat(mat)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Horizontal pipe along x at height y, local u; flanges every 3 m.
static func pipe_x(sb, x0: float, x1: float, y: float, u: float, r: float, mat: String) -> void:
	sb.k.box(sb.P((x0 + x1) * 0.5, y, u), Vector3(x1 - x0, r * 2.0, r * 2.0), mat, GeoKit.ALL, false)
	var x := x0 + 1.5
	while x < x1:
		sb.k.box(sb.P(x, y, u), Vector3(0.05, r * 2.0 + 0.06, r * 2.0 + 0.06), mat, GeoKit.ALL, false)
		x += 3.0


static func pipe_u(sb, x: float, y: float, u0: float, u1: float, r: float, mat: String) -> void:
	sb.k.box(sb.P(x, y, (u0 + u1) * 0.5), Vector3(r * 2.0, r * 2.0, u1 - u0), mat, GeoKit.ALL, false)
	var u := u0 + 1.0
	while u < u1:
		sb.k.box(sb.P(x, y, u), Vector3(r * 2.0 + 0.06, r * 2.0 + 0.06, 0.05), mat, GeoKit.ALL, false)
		u += 3.0


## A caged incandescent bulb hanging from the deckhead at p (top point).
static func bulb(sb, p: Vector3, dead: bool) -> void:
	sb.k.box(p + Vector3(0, -0.04, 0), Vector3(0.2, 0.08, 0.2), "l17_steel", GeoKit.ALL, false)
	sb.k.box(p + Vector3(0, -0.2, 0), Vector3(0.13, 0.18, 0.13), "l17_black" if dead else "l17_bulb", GeoKit.ALL, false)
	for o in [Vector3(0.09, 0, 0), Vector3(-0.09, 0, 0), Vector3(0, 0, 0.09), Vector3(0, 0, -0.09)]:
		sb.k.box(p + o + Vector3(0, -0.2, 0), Vector3(0.012, 0.22, 0.012), "l17_steel", GeoKit.ALL, false)


## A compartment clock. Each compartment keeps its own time (rate, offset).
static func clock(sb, p: Vector3, n: Vector3, cid: String) -> void:
	var c := Node3D.new()
	sb.node.add_child(c)
	c.position = p + n * 0.03
	c.basis = Basis.looking_at(-n, Vector3.UP)
	disc(c, 0.17, 0.05, "l17_brass")
	var face := disc(c, 0.145, 0.06, "l17_white")
	face.position.z = 0.004
	var hands: Array = []
	for spec in [[0.085, 0.018], [0.125, 0.012]]:
		var pv := Node3D.new()
		pv.position.z = 0.04
		c.add_child(pv)
		var h := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(spec[1], spec[0], 0.006)
		h.mesh = bm
		h.position.y = float(spec[0]) * 0.4
		h.material_override = MatLib.get_mat("l17_black")
		pv.add_child(h)
		hands.append(pv)
	var rate: float = RATES[sb.rng.randi() % RATES.size()]
	var off: float = sb.rng.randf() * 43200.0
	sb.meta["clocks"].append({"node": c, "h": hands[0], "m": hands[1], "rate": rate, "off": off, "id": cid})


static func note(sb, id: String, title: String, text: String, p: Vector3, size := Vector3(0.6, 0.6, 0.4)) -> void:
	var it := Interactable.new()
	sb.node.add_child(it)
	it.setup(p, size, "Read")
	it.as_note(id, title, text)


# ------------------------------------------------------------------ sector dressing

static func dress_sector(sb) -> void:
	for id in ["AP", "AS", "FP", "FS"]:
		var r: Array = ROOMS[id]
		var t: String = sb.plan[id]
		var fore: bool = id.begins_with("F")
		var du: float = PF if fore else PA
		var bu: float = 11.8 if fore else 0.2
		var sg := -1.0 if fore else 1.0
		var dx := 6.1 if id.ends_with("S") else -6.1
		var inward := Vector3(0, 0, 1) if not fore else Vector3(0, 0, -1)
		var room := {"x0": r[0], "x1": r[1], "bu": bu, "du": du, "sg": sg, "dx": dx, "id": id, "type": t}
		var closed: bool = t == "storage" and sb.rng.randf() < 0.3 or t.begins_with("sealed")
		closed = closed or t == "bridge"
		if t != "machine" and t != "infirmary":
			door_leaf(sb, dx, du, sg, closed)
		if not t in ["infirmary", "bridge", "machine"]:
			clock(sb, sb.P(dx, 2.35, du - sg * 0.06), inward, "%d-%s" % [sb.n, id])
		match t:
			"barracks", "barracks_blocked":
				berthing(sb, room)
			"galley":
				galley(sb, room)
			"comms", "schematics":
				radio(sb, room)
			"storage":
				storeroom(sb, room)
		if not closed and not t in ["bridge", "machine", "infirmary"]:
			var cx := (float(r[0]) + float(r[1])) * 0.5
			var cu := (bu + du) * 0.5
			sb.meta["lights_up"].append([sb.P(cx, 2.3, cu), Color(1.0, 0.8, 0.55), 0.7, 5.0, 0.0])
			bulb(sb, sb.P(cx, 2.7, cu), false)
		var names := {"barracks": "BERTHING", "barracks_blocked": "BERTHING", "galley": "GALLEY", "comms": "RADIO", "storage": "STOREROOM",
			"chartroom": "CHART ROOM", "schematics": "RADIO", "infirmary": "INFIRMARY", "bridge": "BRIDGE", "machine": ""}
		var nm: String = names.get(t, "")
		if nm != "":
			label(sb, "2-%d-%d-%s  %s" % [sb.n * 10 + (2 if fore else 0), [1, 2, 3, 4][["AP", "AS", "FP", "FS"].find(id)], "L" if t != "storage" else "A", nm],
				sb.P(dx, 2.25, du + sg * 0.06), -inward, 0.0034, Color(0.1, 0.1, 0.1), 48)
	board(sb)
	occupants(sb)


static func door_leaf(sb, dx: float, du: float, sg: float, closed: bool) -> void:
	if closed:
		sb.k.box(sb.P(dx, 0.98, du), Vector3(0.8, 1.94, 0.05), "l17_door", GeoKit.ALL, true)
		sb.k.box(sb.P(dx + 0.3, 1.0, du + 0.05 * sg), Vector3(0.1, 0.04, 0.04), "l17_steel", GeoKit.ALL, false)
		return
	var hx := dx + (0.41 if dx < 0 else -0.41)
	var dir := 1.0 if dx < 0 else -1.0
	sb.k.box(sb.P(hx + dir * 0.4, 0.98, du - sg * 0.07), Vector3(0.8, 1.94, 0.04), "l17_door", GeoKit.ALL, false)


static func rack(sb, x: float, u: float, along_x: bool, tiers := 3) -> void:
	var lx := 1.95 if along_x else 0.7
	var lu := 0.7 if along_x else 1.95
	for cx in [-0.5, 0.5]:
		for cu in [-0.5, 0.5]:
			sb.k.box(sb.P(x + cx * (lx - 0.04), 1.02, u + cu * (lu - 0.04)), Vector3(0.035, 2.05, 0.035), "l17_rail", GeoKit.ALL, false)
	for i in tiers:
		var y := 0.32 + i * 0.64
		sb.k.box(sb.P(x, y, u), Vector3(lx, 0.04, lu), "l17_canvas", GeoKit.ALL, false)
		if sb.rng.randf() < 0.8:
			sb.k.box(sb.P(x, y + 0.07, u), Vector3(lx - 0.1, 0.1, lu - 0.1), "l17_mattress", GeoKit.ALL, false)
			var fold: float = sb.rng.randf()
			if fold < 0.5:
				var o := Vector3(0.6, 0, 0) if along_x else Vector3(0, 0, 0.6)
				sb.k.box(sb.P(x + o.x, y + 0.16, u + o.z), Vector3(0.5 if along_x else 0.55, 0.08, 0.55 if along_x else 0.5), "l17_blanket", GeoKit.ALL, false)
			elif fold < 0.8:
				sb.k.box(sb.P(x, y + 0.14, u), Vector3(lx - 0.3, 0.05, lu - 0.15), "l17_blanket", GeoKit.ALL, false)
	sb.k.box(sb.P(x, 1.0, u), Vector3(lx, 2.0, lu), "l17_rail", 0, true)


static func berthing(sb, r: Dictionary) -> void:
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var bu: float = r["bu"]
	var sg: float = r["sg"]
	rack(sb, x0 + 1.2, bu + sg * 0.45, true)
	rack(sb, x1 - 1.2, bu + sg * 0.45, true)
	var side := x0 + 0.45 if r["dx"] > 0 else x1 - 0.45
	rack(sb, side, bu + sg * 2.55, false)
	# lockers along the other side wall
	var lx := x1 - 0.3 if r["dx"] > 0 else x0 + 0.3
	for i in 4:
		var u: float = bu + sg * (1.4 + i * 0.62)
		sb.k.box(sb.P(lx, 0.9, u), Vector3(0.55, 1.8, 0.6), "l17_locker", GeoKit.ALL, i == 0)
	if sb.rng.randf() < 0.6:
		Props.place(sb.lv, sb.node, "ph/vintage_suitcase", sb.P((x0 + x1) * 0.5 + sb.rng.randf_range(-0.6, 0.6), 0.0, bu + sg * 2.4), sb.rng.randf() * 360.0, 0.0)
	if sb.wear > 0:
		Props.place(sb.lv, sb.node, "ph/trashbag", sb.P((x0 + x1) * 0.5 + 0.9, 0.0, bu + sg * 3.4), sb.rng.randf() * 360.0)


static func galley(sb, r: Dictionary) -> void:
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var bu: float = r["bu"]
	var sg: float = r["sg"]
	var cx := (x0 + x1) * 0.5
	# range with hood along the back wall
	sb.k.box(sb.P(cx, 0.45, bu + sg * 0.45), Vector3(2.4, 0.9, 0.8), "l17_black", GeoKit.ALL, true)
	sb.k.box(sb.P(cx, 0.91, bu + sg * 0.45), Vector3(2.45, 0.03, 0.85), "l17_stainless", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 2.3, bu + sg * 0.5), Vector3(2.6, 0.5, 1.0), "l17_stainless", GeoKit.ALL, false)
	for i in 4:
		var px := cx - 0.9 + i * 0.6
		Props.place(sb.lv, sb.node, ["kenney/food-kit/pot-stew", "kenney/food-kit/pan", "kenney/food-kit/pot", "kenney/food-kit/frying-pan"][i], sb.P(px, 0.93, bu + sg * 0.45), sb.rng.randf() * 360.0, 0.22 if i != 3 else 0.06)
	# counters along both side walls
	for s in [x0 + 0.38, x1 - 0.38]:
		sb.k.box(sb.P(s, 0.45, bu + sg * 2.6), Vector3(0.7, 0.9, 2.8), "l17_stainless", GeoKit.ALL, true)
		for j in 3:
			sb.k.box(sb.P(s, 1.75, bu + sg * (1.6 + j * 0.9)), Vector3(0.4, 0.03, 0.8), "l17_stainless", GeoKit.ALL, false)
	# soup kettles
	for s in [-1.0, 1.0]:
		var kx := x0 + 0.6 if s < 0 else x1 - 0.6
		sb.k.cylinder(sb.P(kx, 0.55, bu + sg * 0.5), 0.32, 0.8, "l17_stainless", 14, false)
	Props.place(sb.lv, sb.node, "ph/Barrel_01", sb.P(x1 - 0.45 if r["dx"] < 0 else x0 + 0.45, 0.0, r["du"] - sg * 0.5), 0.0)
	# mess table and benches
	var tu: float = bu + sg * 2.8
	sb.k.box(sb.P(cx, 0.74, tu), Vector3(2.2, 0.05, 0.8), "l17_stainless", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 0.37, tu), Vector3(2.0, 0.72, 0.1), "l17_steel", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 0.4, tu), Vector3(2.2, 0.8, 0.8), "l17_steel", 0, true)
	for o in [-0.65, 0.65]:
		sb.k.box(sb.P(cx, 0.44, tu + o), Vector3(2.1, 0.05, 0.3), "l17_wood", GeoKit.ALL, false)
		sb.k.box(sb.P(cx, 0.21, tu + o), Vector3(1.9, 0.42, 0.06), "l17_steel", GeoKit.ALL, false)
	for i in 3:
		Props.place(sb.lv, sb.node, "kenney/food-kit/mug" if i != 1 else "kenney/food-kit/plate", sb.P(cx - 0.7 + i * 0.7, 0.765, tu + sb.rng.randf_range(-0.2, 0.2)), sb.rng.randf() * 360.0, 0.1 if i != 1 else 0.03)


static func radio(sb, r: Dictionary) -> void:
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var bu: float = r["bu"]
	var sg: float = r["sg"]
	var cx := (x0 + x1) * 0.5
	# operating desk along the back wall with three sets
	sb.k.box(sb.P(cx, 0.76, bu + sg * 0.4), Vector3(4.6, 0.05, 0.75), "l17_wood", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 0.38, bu + sg * 0.4), Vector3(4.6, 0.76, 0.75), "l17_steel", 0, true)
	for lx in [cx - 2.2, cx + 2.2, cx]:
		sb.k.box(sb.P(lx, 0.37, bu + sg * 0.4), Vector3(0.05, 0.74, 0.7), "l17_steel", GeoKit.ALL, false)
	for i in 3:
		if i == 1:
			sb.k.box(sb.P(cx, 1.0, bu + sg * 0.3), Vector3(0.7, 0.45, 0.45), "l17_locker", GeoKit.ALL, false)
			for d in 3:
				sb.k.box(sb.P(cx - 0.2 + d * 0.2, 1.05, bu + sg * 0.535), Vector3(0.07, 0.07, 0.02), "l17_dial", GeoKit.ALL, false)
		else:
			Props.place(sb.lv, sb.node, "ph/vintage_radio_transceiver", sb.P(cx - 1.5 + i * 1.5, 0.785, bu + sg * 0.35), 180.0 if sg < 0 else 0.0)
			Props.place(sb.lv, sb.node, "ph/dining_chair_02", sb.P(cx - 1.5 + i * 1.5, 0.0, bu + sg * 1.15), (180.0 if sg < 0 else 0.0) + sb.rng.randf_range(-25, 25))
	# equipment cabinets with dials along the side wall
	var sx := x1 - 0.35 if r["dx"] > 0 else x0 + 0.35
	for j in 3:
		var u: float = bu + sg * (1.7 + j * 0.85)
		sb.k.box(sb.P(sx, 0.95, u), Vector3(0.6, 1.9, 0.8), "l17_locker", GeoKit.ALL, true)
		var face := -0.31 if r["dx"] > 0 else 0.31
		for d in 3:
			sb.k.box(sb.P(sx + face, 1.3 + d * 0.15, u - 0.2 + d * 0.2), Vector3(0.02, 0.04, 0.04), "l17_dial" if (j + d) % 2 == 0 else "l17_dial_green", GeoKit.ALL, false)
	sb.k.box(sb.P(cx - 0.7, 0.79, bu + sg * 0.6), Vector3(0.3, 0.02, 0.22), "l17_paper", GeoKit.ALL, false)
	sb.k.box(sb.P(cx + 0.8, 0.79, bu + sg * 0.62), Vector3(0.24, 0.015, 0.32), "l17_wood", GeoKit.ALL, false)


static func storeroom(sb, r: Dictionary) -> void:
	var x0: float = r["x0"]
	var x1: float = r["x1"]
	var bu: float = r["bu"]
	var sg: float = r["sg"]
	for i in 3:
		var sx := x0 + 0.9 + i * 2.2
		Props.place(sb.lv, sb.node, "ph/steel_frame_shelves_02", sb.P(sx, 0.0, bu + sg * 0.3), 0.0 if sg > 0 else 180.0, 0.0, true)
		Props.place(sb.lv, sb.node, "ph/steel_frame_shelves_02", sb.P(sx + 0.62, 0.0, bu + sg * 0.3), 0.0 if sg > 0 else 180.0, 0.0, false)
		for b in 3:
			sb.k.box(sb.P(sx + 0.3 + sb.rng.randf_range(-0.3, 0.3), 0.98 + b * 0.5, bu + sg * 0.32), Vector3(0.4, 0.3, 0.35), "l17_paper", GeoKit.ALL, false)
	for i in 3:
		var p: Vector3 = sb.P(sb.rng.randf_range(x0 + 0.8, x1 - 0.8), 0.0, bu + sg * sb.rng.randf_range(1.5, 3.4))
		Props.place(sb.lv, sb.node, ["ph/wooden_crate_01", "ph/old_military_crate", "ph/Barrel_01"][i], p, sb.rng.randf() * 360.0, 0.0, true)
	if sb.rng.randf() < 0.5:
		Props.place(sb.lv, sb.node, "ph/hand_truck", sb.P(x1 - 0.5 if r["dx"] < 0 else x0 + 0.5, 0.0, r["du"] - sg * 0.6), 30.0)


## Notice board in the athwartship passage; the Project RAINBOW schematic sheet
## is reported as found in every sector.
static func board(sb) -> void:
	var p: Vector3 = sb.P(-4.25, 1.5, PA + 0.06)
	sb.k.box(p, Vector3(1.3, 0.9, 0.03), "l17_cork", GeoKit.ALL, false)
	sb.k.box(p + Vector3(-0.25, 0.02, -0.02), Vector3(0.62, 0.44, 0.006), "l17_blueprint", GeoKit.ALL, false)
	sb.k.box(p + Vector3(0.35, 0.1, -0.02), Vector3(0.3, 0.4, 0.006), "l17_paper", GeoKit.ALL, false)
	label(sb, "CONFIDENTIAL", p + Vector3(-0.25, 0.16, -0.025), Vector3(0, 0, -1), 0.0016, Color(0.75, 0.8, 0.9), 48)
	note(sb, "l17_schematic", "A schematic sheet",
		"Blue-line drawings of a machine built from thousands of vacuum tubes, transistors and parts nobody could name. The same sheet turns up in every sector. The title page is stamped CONFIDENTIAL.",
		p + Vector3(0, 0, -0.25), Vector3(1.4, 1.0, 0.5))


## Occupants or their remains: stationary presences, never combat.
static func occupants(sb) -> void:
	if sb.n <= 2 or sb.n in [12, 165, 185, 217, 104]:
		return
	var roll: float = sb.rng.randf()
	var ids := ["AP", "AS", "FP", "FS"]
	var id: String = ids[sb.rng.randi() % 4]
	var r: Array = ROOMS[id]
	var fore := id.begins_with("F")
	var cx: float = (float(r[0]) + float(r[1])) * 0.5 + sb.rng.randf_range(-1.0, 1.0)
	var cu: float = (8.8 if fore else 3.0) + sb.rng.randf_range(-0.6, 0.6)
	if roll < 0.3:
		sb.meta["figures"].append({"kind": "dungarees", "pos": sb.P(cx, 0.0, cu), "yaw": sb.rng.randf() * 360.0, "watch": sb.rng.randf() < 0.6})
	elif roll < 0.5:
		sb.meta["figures"].append({"kind": "remains", "pos": sb.P(cx, 0.0, cu), "yaw": sb.rng.randf() * 360.0, "watch": false})
