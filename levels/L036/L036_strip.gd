extends RefCounted
## Level 36 strips, streamed in 32 m chunks along x ("infinite only horizontally"):
## the baggage wall (the level's only known bounded edge) with endless numbered
## carousels, then the endless row of deserted check-in counters under a 12 m hall.
## Chunk cx spans x in [cx*32-16, cx*32+16]. Chunk 0 is the authored centre.

const CS := 32.0
const WALL_Z := 16.0
const BAG_Z1 := -8.0
const BACK_Z := -44.0
const BAG_H := 6.5
const CHK_H := 12.0
const COUNTER_Z := -26.0
const BELT_Y := 0.28
const RUN_Z0 := 15.6
const RUN_Z1 := 4.0
const R_IN := 1.15
const R_OUT := 2.25
## Carousels the page names for Level 11 (#9, #28, #147); others are uncorrelated numbers.
const FIXED := {0: 9, 2: 28, -3: 147}
const ACTIVE := [0, 1, 2, -2, -3, 4, -5]

var lvl
var belt_on: ShaderMaterial
var belt_off: ShaderMaterial
var carousels: Dictionary = {}     # index -> {x, number, active}
var screens: Array = []            # Label3D flight lists (pruned when freed)


func _init(level) -> void:
	lvl = level
	var sh := Shader.new()
	sh.code = "shader_type spatial;\nuniform float speed = 0.0;\nuniform float uscale = 1.0;\nvoid fragment() {\n\tfloat u = UV.x * uscale - TIME * speed;\n\tfloat slat = smoothstep(0.02, 0.05, fract(u / 0.32)) * (1.0 - smoothstep(0.95, 0.98, fract(u / 0.32)));\n\tfloat edge = smoothstep(0.0, 0.06, UV.y) * smoothstep(1.0, 0.94, UV.y);\n\tALBEDO = mix(vec3(0.015), vec3(0.09, 0.09, 0.1), slat * edge);\n\tROUGHNESS = 0.55;\n\tMETALLIC = 0.4;\n}\n"
	belt_on = ShaderMaterial.new()
	belt_on.shader = sh
	belt_on.set_shader_parameter("speed", 0.5)
	belt_off = ShaderMaterial.new()
	belt_off.shader = sh
	belt_off.set_shader_parameter("speed", 0.0)


static func number_of(i: int) -> int:
	if FIXED.has(i):
		return FIXED[i]
	return absi(hash([i, "carousel36"])) % 480 + 1


## Loop path of a carousel (local to its centre x): returns position at arc length s.
static func path_point(xc: float, s: float) -> Vector3:
	var rm := (R_IN + R_OUT) * 0.5
	var run := RUN_Z0 - RUN_Z1
	var arc := PI * rm
	var hidden := 4.0
	var total := run * 2.0 + arc + hidden
	s = fposmod(s, total)
	if s < run:
		return Vector3(xc + rm, BELT_Y, RUN_Z0 - s)
	s -= run
	if s < arc:
		var a := s / rm
		return Vector3(xc + rm * cos(a), BELT_Y, RUN_Z1 - rm * sin(a))
	s -= arc
	if s < run:
		return Vector3(xc - rm, BELT_Y, RUN_Z1 + s)
	s -= run
	return Vector3(xc - rm + (s / hidden) * rm * 2.0, BELT_Y - 0.6, RUN_Z0 + 0.6)


static func path_length() -> float:
	var rm := (R_IN + R_OUT) * 0.5
	return (RUN_Z0 - RUN_Z1) * 2.0 + PI * rm + 4.0


func _belt_mesh(xc: float, active: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := BELT_Y + 0.002
	var run := RUN_Z0 - RUN_Z1
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3, u0: float, u1: float) -> void:
		for v in [[a, Vector2(u0, 0)], [b, Vector2(u0, 1)], [c, Vector2(u1, 1)], [a, Vector2(u0, 0)], [c, Vector2(u1, 1)], [d, Vector2(u1, 0)]]:
			st.set_normal(Vector3.UP)
			st.set_uv(v[1])
			st.add_vertex(v[0])
	quad.call(Vector3(xc + R_IN, y, RUN_Z0), Vector3(xc + R_OUT, y, RUN_Z0), Vector3(xc + R_OUT, y, RUN_Z1), Vector3(xc + R_IN, y, RUN_Z1), 0.0, run)
	var rm := (R_IN + R_OUT) * 0.5
	var segs := 16
	for i in segs:
		var a0 := PI * float(i) / segs
		var a1 := PI * float(i + 1) / segs
		var u0 := run + a0 * rm
		var u1 := run + a1 * rm
		quad.call(Vector3(xc + R_IN * cos(a0), y, RUN_Z1 - R_IN * sin(a0)), Vector3(xc + R_OUT * cos(a0), y, RUN_Z1 - R_OUT * sin(a0)),
			Vector3(xc + R_OUT * cos(a1), y, RUN_Z1 - R_OUT * sin(a1)), Vector3(xc + R_IN * cos(a1), y, RUN_Z1 - R_IN * sin(a1)), u0, u1)
	var u2 := run + PI * rm
	quad.call(Vector3(xc - R_IN, y, RUN_Z1), Vector3(xc - R_OUT, y, RUN_Z1), Vector3(xc - R_OUT, y, RUN_Z0), Vector3(xc - R_IN, y, RUN_Z0), u2, u2 + run)
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = belt_on if active else belt_off
	return mi


func carousel(node: Node3D, k: GeoKit, i: int) -> void:
	var xc := float(i) * 16.0 + 8.0
	var active := ACTIVE.has(i)
	var num := number_of(i)
	carousels[i] = {"x": xc, "number": num, "active": active}
	var rm := (R_IN + R_OUT) * 0.5
	for sx in [-1.0, 1.0]:
		k.box_mm(Vector3(xc + sx * R_IN - (0.0 if sx > 0 else R_OUT - R_IN), 0.0, RUN_Z1), Vector3(xc + sx * R_IN + (R_OUT - R_IN if sx > 0 else 0.0), BELT_Y, RUN_Z0), "l36_skirt")
	k.cylinder(Vector3(xc, BELT_Y * 0.5, RUN_Z1), R_OUT, BELT_Y, "l36_skirt", 20, true)
	# centre island: stainless sloped plate
	k.box_mm(Vector3(xc - R_IN + 0.02, 0.0, RUN_Z1), Vector3(xc + R_IN - 0.02, 0.62, RUN_Z0), "l36_steel")
	k.cylinder(Vector3(xc, 0.31, RUN_Z1), R_IN - 0.02, 0.62, "l36_steel", 16, true)
	k.box(Vector3(xc, 0.66, (RUN_Z0 + RUN_Z1) * 0.5), Vector3(0.5, 0.08, RUN_Z0 - RUN_Z1), "l36_skirt", GeoKit.ALL, false)
	node.add_child(_belt_mesh(xc, active))
	# hatch flaps where the belt comes through the wall
	for sx in [-rm, rm]:
		for f in 5:
			k.box(Vector3(xc + sx - 0.5 + float(f) * 0.25, BELT_Y + 0.45, WALL_Z - 0.25), Vector3(0.22, 0.85, 0.02), "l36_rubber", GeoKit.ALL, false)
		k.box(Vector3(xc + sx, BELT_Y + 1.0, WALL_Z - 0.3), Vector3(1.6, 0.18, 0.4), "l36_steel", GeoKit.ALL, false)
	# number sign over the carousel
	var sp := Vector3(xc, 4.4, RUN_Z1 - 0.5)
	k.box(sp, Vector3(2.2, 1.0, 0.12), "l36_signboard", GeoKit.ALL, false)
	for sx in [-0.8, 0.8]:
		k.box(Vector3(xc + sx, (sp.y + BAG_H) * 0.5 + 0.25, sp.z), Vector3(0.03, BAG_H - sp.y - 0.5, 0.03), "l36_steel", GeoKit.ALL, false)
	for face in [1.0, -1.0]:
		var lb := Label3D.new()
		lb.text = "%d" % num
		lb.font_size = 160
		lb.pixel_size = 0.004
		lb.modulate = Color(1.0, 0.82, 0.2) if active else Color(0.55, 0.5, 0.35)
		lb.outline_size = 0
		lb.double_sided = false
		lb.position = sp + Vector3(0, 0.08, face * 0.07)
		lb.rotation.y = 0.0 if face > 0 else PI
		node.add_child(lb)
		var sub := Label3D.new()
		sub.text = "BAGGAGE CLAIM" if active else "BAGGAGE CLAIM  -  NOT IN USE"
		sub.font_size = 36
		sub.pixel_size = 0.004
		sub.modulate = Color(0.85, 0.88, 0.9)
		sub.double_sided = false
		sub.position = sp + Vector3(0, -0.35, face * 0.07)
		sub.rotation.y = lb.rotation.y
		node.add_child(sub)


func build_chunk(cx: int, node: Node3D) -> Dictionary:
	var x0 := float(cx) * CS - 16.0
	var x1 := x0 + CS
	var k := GeoKit.new(node, "Strip")
	var d := GeoKit.new(node, "Detail")
	d.shadows = false
	# floors and ceilings
	k.slab(x0, WALL_Z, x1, BAG_Z1, 0.0, 0.5, "l36_floor")
	k.slab(x0, BAG_Z1, x1, BACK_Z, 0.0, 0.5, "l36_floor_hall")
	k.slab(x0, WALL_Z, x1, BAG_Z1, BAG_H + 0.4, 0.4, "l36_ceiling")
	k.slab(x0, BAG_Z1, x1, BACK_Z, CHK_H + 0.4, 0.4, "l36_ceiling")
	k.box(Vector3((x0 + x1) * 0.5, (BAG_H + CHK_H) * 0.5, BAG_Z1), Vector3(CS, CHK_H - BAG_H, 0.5), "l36_wall", GeoKit.ALL, false)
	# the bounded edge: the baggage wall, with hatches for each belt
	var ops: Array = []
	for i in [cx * 2 - 1, cx * 2]:
		var xc := float(i) * 16.0 + 8.0
		if cx == 0 and i == -1:
			continue
		for sx in [-1.7, 1.7]:
			ops.append({"at": xc + sx - x0, "w": 1.3, "h": 0.9, "sill": 0.0})
	k.wall(Vector3(x0, 0, WALL_Z), Vector3(x1, 0, WALL_Z), BAG_H, 0.4, "l36_wall_bag", ops)
	for o in ops:
		k.box(Vector3(x0 + float(o["at"]), 0.45, WALL_Z + 0.5), Vector3(1.3, 0.9, 0.6), "l36_void", GeoKit.ALL, true)
	# carousels (chunk 0's western one is the Lost and Found office instead)
	for i in [cx * 2 - 1, cx * 2]:
		if cx == 0 and i == -1:
			continue
		carousel(node, k, i)
	# baggage hall lights and columns
	for xl in [x0 + 8.0, x0 + 24.0]:
		for zl in [10.0, 0.0, -5.0]:
			d.panel(Vector3(xl, BAG_H - 0.01, zl), 4.0, 1.2, "l36_panel", float(cx * 13 + int(zl)), 0.0)
	for xp in [x0, x0 + 16.0]:
		k.cylinder(Vector3(xp, BAG_H * 0.5, 0.0), 0.45, BAG_H, "l36_column", 16)
	# luggage trolleys left where people dropped them, benches facing the belts
	var rr := RandomNumberGenerator.new()
	rr.seed = hash([cx, "trolleys"])
	for t in 3:
		var tp := Vector3(x0 + rr.randf_range(2.0, 30.0), 0, rr.randf_range(-6.0, 1.5))
		trolley(d, Transform3D(Basis(Vector3.UP, rr.randf() * TAU), tp), rr)
	for bxp in [x0 + 4.0, x0 + 20.0]:
		k.box(Vector3(bxp + 4.0, 0.22, -3.2), Vector3(4.0, 0.44, 0.6), "l36_seat")
		d.box(Vector3(bxp + 4.0, 0.46, -3.2), Vector3(4.0, 0.05, 0.62), "l36_steel", GeoKit.ALL, false)
	# check-in hall: columns, counters, screens, queue lines, hanging signs
	for xp in [x0, x0 + 16.0]:
		k.cylinder(Vector3(xp, CHK_H * 0.5, -14.0), 0.6, CHK_H, "l36_column", 18)
		if cx != 0:
			k.cylinder(Vector3(xp, CHK_H * 0.5, -38.0), 0.6, CHK_H, "l36_column", 18)
	for b in 2:
		var bx0 := x0 + 2.0 + float(b) * 16.0
		var bx1 := bx0 + 12.0
		var cz := COUNTER_Z
		k.box_mm(Vector3(bx0, 0, cz - 0.45), Vector3(bx1, 1.05, cz + 0.45), "l36_counter_front")
		d.box_mm(Vector3(bx0 - 0.05, 1.05, cz - 0.5), Vector3(bx1 + 0.05, 1.1, cz + 0.55), "l36_counter")
		for p in 4:
			var px := bx0 + 1.5 + float(p) * 3.0
			d.box(Vector3(px, 1.15, cz + 0.3), Vector3(0.6, 0.06, 0.3), "l36_dark", GeoKit.ALL, false)
			d.box(Vector3(px, 0.18, cz + 0.62), Vector3(0.7, 0.36, 0.5), "l36_steel", GeoKit.ALL, false)
		if cx != 0:
			k.box_mm(Vector3(bx0, 0, cz - 2.1), Vector3(bx1, 2.4, cz - 2.0), "l36_wall")
			d.box_mm(Vector3(bx0, 0, cz - 1.4), Vector3(bx1, 0.35, cz - 0.6), "l36_skirt")
		# screen above the counter block
		var sc := Vector3((bx0 + bx1) * 0.5, 2.9, cz + 0.2)
		d.box(sc, Vector3(3.4, 1.1, 0.12), "l36_dark", GeoKit.ALL, false)
		d.box(sc + Vector3(0, 0, 0.065), Vector3(3.2, 0.95, 0.01), "l36_screen", GeoKit.ALL, false)
		for sx in [-1.2, 1.2]:
			d.box(Vector3(sc.x + sx, 2.0, cz), Vector3(0.06, 1.4, 0.06), "l36_steel", GeoKit.ALL, false)
		var lb := Label3D.new()
		lb.font_size = 32
		lb.pixel_size = 0.0036
		lb.modulate = Color(1.0, 0.86, 0.3)
		lb.outline_size = 0
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lb.double_sided = false
		lb.position = sc + Vector3(-1.5, 0.0, 0.08)
		lb.width = 900.0
		lb.autowrap_mode = TextServer.AUTOWRAP_OFF
		node.add_child(lb)
		screens.append(lb)
		# queue stanchions in front
		for q in 6:
			var qx := bx0 + 1.0 + float(q) * 2.0
			for qz in [-19.0, -21.5]:
				d.cylinder(Vector3(qx, 0.5, qz), 0.03, 1.0, "l36_steel", 6, false)
				d.cylinder(Vector3(qx, 0.02, qz), 0.16, 0.04, "l36_steel", 10, false)
			d.box(Vector3(qx, 0.88, -20.25), Vector3(0.03, 0.05, 2.5), "l36_tape", GeoKit.ALL, false)
	# big ceiling light boxes
	for xl in [x0 + 8.0, x0 + 24.0]:
		for zl in [-16.0, -32.0]:
			d.panel(Vector3(xl, CHK_H - 0.01, zl), 7.0, 2.4, "l36_panel_big", float(cx * 7 + int(zl)), 0.0)
	# back wall: chunk 0 opens on the concourse, the others hold shuttered portals
	if cx == 0:
		k.wall(Vector3(x0, 0, BACK_Z), Vector3(x1, 0, BACK_Z), CHK_H, 0.4, "l36_wall", [{"at": 16.0, "w": 12.0, "h": 4.6}])
	else:
		k.wall(Vector3(x0, 0, BACK_Z), Vector3(x1, 0, BACK_Z), CHK_H, 0.4, "l36_wall", [{"at": 16.0, "w": 6.0, "h": 4.0}])
		k.box(Vector3(x0 + 16.0, 2.0, BACK_Z + 0.26), Vector3(6.2, 4.0, 0.12), "l36_shutter")
		var letter := String.chr(65 + absi(hash([cx, "conc"])) % 26)
		_sign(node, d, Vector3(x0 + 16.0, 5.0, BACK_Z + 0.3), "CONCOURSE %s  %s" % [letter, ["<", ">", "^", "v"][absi(cx) % 4]])
	# hanging directional signs (they do not agree)
	var dirs := ["CHECK-IN  >", "<  BAGGAGE CLAIM", "GATES A-Z  ^", "<  GATES M-Z", "EXIT  >", "TERMINAL C  <", "", "LOST AND FOUND  v"]
	_sign(node, d, Vector3(x0 + 8.0, 8.4, -10.5), dirs[absi(hash([cx, 1])) % dirs.size()])
	_sign(node, d, Vector3(x0 + 24.0, 4.9, -2.0), dirs[absi(hash([cx, 2])) % dirs.size()])
	k.commit()
	d.commit()
	var g := "c%d" % cx
	for xl in [x0 + 8.0, x0 + 24.0]:
		lvl.lights.add_anchor(Vector3(xl, BAG_H - 0.6, 6.0), Color(0.92, 0.95, 1.0), 1.5, 15.0, 0.0, g)
		lvl.lights.add_anchor(Vector3(xl, CHK_H - 1.5, -24.0), Color(0.96, 0.97, 1.0), 1.8, 24.0, 0.0, g)
	return {"x0": x0}


func trolley(d: GeoKit, o: Transform3D, rr: RandomNumberGenerator) -> void:
	for sx in [-0.28, 0.28]:
		d.box_xf(o * Transform3D(Basis(), Vector3(sx, 0.32, 0)), Vector3(0.04, 0.04, 1.0), "l36_steel", GeoKit.ALL, false)
		d.box_xf(o * Transform3D(Basis(Vector3(1, 0, 0), -0.25), Vector3(sx, 0.75, 0.5)), Vector3(0.04, 0.9, 0.04), "l36_steel", GeoKit.ALL, false)
		for wz in [-0.42, 0.42]:
			d.box_xf(o * Transform3D(Basis(), Vector3(sx, 0.08, wz)), Vector3(0.05, 0.16, 0.16), "l36_rubber", GeoKit.ALL, false)
	d.box_xf(o * Transform3D(Basis(), Vector3(0, 0.3, 0)), Vector3(0.6, 0.03, 0.95), "l36_steel", GeoKit.ALL, false)
	d.box_xf(o * Transform3D(Basis(), Vector3(0, 1.18, 0.62)), Vector3(0.62, 0.05, 0.05), "l36_counter_front", GeoKit.ALL, false)
	if rr.randf() < 0.5:
		var mats := ["l36_bag_a", "l36_bag_b", "l36_bag_c", "l36_bag_d"]
		d.box_xf(o * Transform3D(Basis(), Vector3(0, 0.45, -0.05)), Vector3(0.5, 0.26, 0.72), mats[rr.randi() % mats.size()], GeoKit.ALL, false)


## A hanging airport sign (dark board, yellow text). Empty text = a blank sign.
func _sign(node: Node3D, d: GeoKit, pos: Vector3, text: String) -> void:
	var w := maxf(2.4, float(text.length()) * 0.24 + 0.6)
	d.box(pos, Vector3(w, 0.7, 0.1), "l36_signboard", GeoKit.ALL, false)
	for face in [1.0, -1.0]:
		var lb := Label3D.new()
		lb.text = text
		lb.font_size = 64
		lb.pixel_size = 0.0045
		lb.modulate = Color(1.0, 0.84, 0.16)
		lb.outline_size = 0
		lb.double_sided = false
		lb.position = pos + Vector3(0, 0, face * 0.06)
		lb.rotation.y = 0.0 if face > 0 else PI
		node.add_child(lb)
