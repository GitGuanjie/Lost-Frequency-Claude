extends RefCounted
## Level 4 authored anchor, chunk (0,0): the stair hall by M.E.G. Base Omega.
## SOURCE: Base Omega "reside[s] close to one of the entrances of Level 5 and
## Level 6"; exits "take the form of office-style stairways". So the anchor holds
## an old-fashioned stairway down to Level 5 and a plain one down to Level 6,
## side by side, across a lobby from the fire stair between the two storeys.
## A double-height atrium with a glass-railed gallery (start point) looks down
## on the closed Base Omega shutters and a break room stocked with Almond Water.
## Local coordinates equal world coordinates here (chunk origin = 0,0,0).

const P := preload("res://levels/L004/L004_parts.gd")
const FY := [0.0, 3.6]
const CH := P.CH
const T := P.T

var lvl: Node3D
var parts: RefCounted
var office: RefCounted
const ATR := Rect2(9.6, 10.8, 9.6, 10.8)      # atrium void
const STAIRS_DOWN := Rect2(2.4, 2.4, 9.6, 6.6)  # L5 + L6 stairways (F0 only)
const CORE := Rect2(2.4, 13.2, 4.8, 6.6)       # fire stair F0 <-> F1
const BREAK := Rect2(12.0, 2.4, 7.2, 7.2)
const BASE := Rect2(19.2, 2.4, 4.8, 21.6)      # Base Omega (closed)


func _init(level: Node3D, p: RefCounted, o: RefCounted) -> void:
	lvl = level
	parts = p
	office = o


static func inside_sign(f: Dictionary) -> float:
	var u: Vector3 = f["u"]
	return signf(u.cross(Vector3.UP).dot(f["v"]))


func build(k: GeoKit, node: Node3D, o: Vector3, meta: Dictionary) -> void:
	var group := "0,0"
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, "anchor"])
	var corr := [Rect2(0, 0, 24, 2.4), Rect2(0, 2.4, 2.4, 21.6)]
	var block := [Rect2(2.4, 2.4, 21.6, 21.6)]
	# ---- floors / ceilings
	P.floor_rects(k, corr, 0.0, 0.3, "l4_carpet_corr")
	P.floor_rects(k, P.cut(block, [STAIRS_DOWN, BREAK]), 0.0, 0.3, "l4_carpet")
	P.floor_rects(k, [BREAK], 0.0, 0.3, "l4_vinyl")
	P.ceil_rects(k, P.cut(corr + block, [ATR, CORE, STAIRS_DOWN]), CH, "l4_ceiling")
	P.floor_rects(k, corr, FY[1], 0.8, "l4_carpet_corr")
	P.floor_rects(k, P.cut(block, [ATR, CORE]), FY[1], 0.8, "l4_carpet")
	P.ceil_rects(k, P.cut(corr + block, [CORE]), FY[1] + CH, "l4_ceiling")
	for f in 2:
		office._corridor_lights(k, o, FY[f], group, r)
	# ---- the two exit stairways and the fire stair
	var fa := P.fr(Vector3(2.4, 0, 9.0), Vector3.RIGHT, Vector3.FORWARD)
	var fb := P.fr(Vector3(7.2, 0, 9.0), Vector3.RIGHT, Vector3.FORWARD)
	var fc := P.fr(Vector3(2.4, 0, 13.2), Vector3.RIGHT, Vector3.BACK)
	var sa: Dictionary = parts.stairwell(k, node, fa, 0.0, false, "old", [])
	var sb: Dictionary = parts.stairwell(k, node, fb, 0.0, false, "dark", ["l"])
	var sc: Dictionary = parts.stairwell(k, node, fc, 0.0, true, "core", [])
	var ins_a := inside_sign(fa)
	var da: Dictionary = sa["doors"][0]
	P.door_trim(k, da["a"], da["b"], da["at"], P.DOOR_W, P.DOOR_H, "l4_oldwood", "l4_oldwood", ins_a)
	P.exit_sign(k, node, da["a"], da["b"], da["at"], 2.38, -ins_a)
	var db: Dictionary = sb["doors"][0]
	P.door_trim(k, db["a"], db["b"], db["at"], P.DOOR_W, P.DOOR_H, "l4_frame", "l4_firedoor", ins_a)
	P.exit_sign(k, node, db["a"], db["b"], db["at"], 2.38, -ins_a)
	for dd in sc["doors"]:
		var ya: Vector3 = Vector3.UP * float(dd["y"])
		P.door_trim(k, dd["a"] + ya, dd["b"] + ya, dd["at"], P.DOOR_W, P.DOOR_H, "l4_frame", "l4_firedoor", inside_sign(fc))
		P.exit_sign(k, node, dd["a"] + ya, dd["b"] + ya, dd["at"], 2.38, -inside_sign(fc))
	# brass plate by the old stairway; a warm glow far below it
	k.box(Vector3(4.55, 1.45, 9.0 + T * 0.5 + 0.01), Vector3(0.22, 0.3, 0.015), "l4_brass", GeoKit.ALL, false)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.64, 0.34)
	glow.light_energy = 0.9
	glow.omni_range = 4.5
	glow.position = Vector3(6.0, -3.0, 9.4)
	node.add_child(glow)
	var ta: ExitTrigger = lvl.make_exit("L004>L005#1", "walk_in", (sa["bottom"] as Vector3) + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 1.3), "", node)
	var tb: ExitTrigger = lvl.make_exit("L004>L006#2", "walk_in", (sb["bottom"] as Vector3) + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 1.3), "", node)
	meta["anchor_exits"] = [ta, tb]
	# ---- storey walls
	_walls_f0(k, node, o)
	_walls_f1(k, node, o, r)
	_base_omega(k, node)
	_atrium(k, node, group)
	# ---- break room: the supplies wanderers stock up on before Levels 5 and 6
	var spots := [["vending", Vector3(12.05, 0, 2.4 + T * 0.5)], ["vending", Vector3(13.25, 0, 2.4 + T * 0.5)], ["cooler", Vector3(15.5, 0, 2.4 + T * 0.5)]]
	var i := 0
	for s in spots:
		var c: Vector3 = parts.dispenser(k, s[0], s[1], Vector3.BACK)
		lvl.register_dispenser(node, s[0], c, "anchor:%d" % i)
		i += 1
	var cf: Vector3 = parts.dispenser(k, "fountain", Vector3(12.0 + T * 0.5, 0, 6.8), Vector3.RIGHT)
	lvl.register_dispenser(node, "fountain", cf, "anchor:f")
	var cu: Vector3 = parts.dispenser(k, "cooler", Vector3(10.6, FY[1], 7.2 + T * 0.5), Vector3.BACK)
	lvl.register_dispenser(node, "cooler", cu, "anchor:up")
	# M.E.G. supply crates stacked by the shutter, a folding table (checkpoint desk)
	for q in 5:
		var cp := Vector3(17.6 + (q % 2) * 0.62, 0.2 + (q / 2) * 0.4, 3.1 + (q % 3) * 0.05)
		k.box(cp, Vector3(0.58, 0.4, 0.46), "l4_cardboard", GeoKit.ALL, q < 2)
	k.box(Vector3(17.2, 0.74, 8.3), Vector3(1.6, 0.04, 0.7), "l4_plastic")
	for sx in [-0.7, 0.7]:
		k.box(Vector3(17.2 + sx, 0.36, 8.3), Vector3(0.04, 0.72, 0.6), "l4_rail", GeoKit.ALL, false)
	for q in 6:
		k.cylinder(Vector3(16.7 + q * 0.12, 0.88, 8.15), 0.035, 0.24, "l4_bottle", 6, false)
	# lights over the break room and the lobby
	for p in [Vector3(14.4, CH - 0.004, 4.8), Vector3(16.8, CH - 0.004, 7.2), Vector3(4.8, CH - 0.004, 11.1), Vector3(9.6, CH - 0.004, 11.1), Vector3(4.8, FY[1] + CH - 0.004, 10.8), Vector3(4.8, FY[1] + CH - 0.004, 22.0), Vector3(14.4, FY[1] + CH - 0.004, 23.0)]:
		k.panel(p, 0.6, 1.2, "l4_panel", r.randf() * 40.0, 0.0)
		lvl.lights.add_anchor(p + Vector3.DOWN * 0.75, Color(0.92, 0.96, 1.0), 1.2, 6.0, 0.0, group)
	for p in [Vector3(11.0, CH - 0.004, 22.8), Vector3(16.8, CH - 0.004, 22.8), Vector3(4.8, CH - 0.004, 21.6), Vector3(8.4, CH - 0.004, 16.8)]:
		k.panel(p, 0.6, 1.2, "l4_panel", 100.0 if r.randf() < 0.3 else 5.0, 0.0)
	# the M.E.G. notice (paraphrase of the page's advice)
	k.box(Vector3(9.0, FY[1] + 0.2, 8.3), Vector3(0.52, 0.4, 0.42), "l4_cardboard")
	lvl.add_note("L004_meg_notice", "Notice, taped to a supply box",
		"[i]Typed, with an M.E.G. stamp in the corner.[/i]\n\nBase Omega is downstairs, by the stairways to Levels 5 and 6. Residents and teams only. The shutters stay down.\n\nFill up before you go on. There is more Almond Water here than anywhere else, and you will need it on 5 and 6. Coolers, vending machines, fountains: help yourself.\n\nIf a window has NOT been blacked out, do not stand at it. Do not look through it. Walk away.\n\nStairways and lifts out of here are real, but keep your eyes on them. Lose sight of one and it may not be there when you turn back.\n\nTwo groups keep rooms on this level. Amor Incrementum: do not approach. T.B.D.: they ignore you unless you bother them, and only trade for useless things.",
		Vector3(9.0, FY[1] + 0.43, 8.3), Vector3(0.4, 0.06, 0.3))
	lvl.add_landmark("Base Omega shutters", Vector3(19.2, 0, 12.0))
	lvl.add_landmark("Old stairway down (Level 5)", Vector3(3.6, 0, 9.0))
	lvl.add_landmark("Stairway down (Level 6)", Vector3(8.4, 0, 9.0))


func _walls_f0(k: GeoKit, node: Node3D, o: Vector3) -> void:
	var y: float = FY[0]
	# west: lobby opening + south opening (the stairwells provide the rest)
	k.wall(Vector3(2.4 - T * 0.5, y, 9.0), Vector3(2.4 - T * 0.5, y, 13.2), CH, T, "l4_wall", [{"at": 2.1, "w": 2.4, "h": 2.3}], GeoKit.ALL)
	k.wall(Vector3(2.4 - T * 0.5, y, 19.8), Vector3(2.4 - T * 0.5, y, 24.0 + T * 0.5), CH, T, "l4_wall", [{"at": 2.1, "w": 1.8, "h": 2.3}], GeoKit.ALL)
	# north (break room side), with painted-over windows facing the corridor
	var a := Vector3(12.0, y, 2.4 - T * 0.5)
	var b := Vector3(24.0 + T * 0.5, y, 2.4 - T * 0.5)
	k.wall(a, b, CH, T, "l4_wall", [], GeoKit.ALL)
	for at in [5.0, 9.6]:
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, -1.0, at > 6.0)
	# east (behind Base Omega) and south
	a = Vector3(24.0, y, 2.4)
	b = Vector3(24.0, y, 24.0 + T * 0.5)
	k.wall(a, b, CH, T, "l4_wall", [], GeoKit.ALL)
	for at in [3.0, 8.4, 13.8, 19.2]:
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, -1.0, int(at) % 2 == 0)
	a = Vector3(2.4, y, 24.0)
	b = Vector3(24.0 + T * 0.5, y, 24.0)
	k.wall(a, b, CH, T, "l4_wall", [{"at": 2.4, "w": 1.8, "h": 2.3}, {"at": 12.0, "w": 2.4, "h": 2.3}], GeoKit.ALL)
	for at in [7.2, 15.6]:
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, -1.0)


func _walls_f1(k: GeoKit, node: Node3D, o: Vector3, r: RandomNumberGenerator) -> void:
	var y: float = FY[1]
	k.wall(Vector3(2.4 - T * 0.5, y, 2.4), Vector3(2.4 - T * 0.5, y, 13.2), CH, T, "l4_wall", [{"at": 6.0, "w": 2.4, "h": 2.3}], GeoKit.ALL)
	k.wall(Vector3(2.4 - T * 0.5, y, 19.8), Vector3(2.4 - T * 0.5, y, 24.0 + T * 0.5), CH, T, "l4_wall", [{"at": 2.1, "w": 1.8, "h": 2.3}], GeoKit.ALL)
	var a := Vector3(2.4 - T * 0.5, y, 2.4 - T * 0.5)
	var b := Vector3(24.0 + T * 0.5, y, 2.4 - T * 0.5)
	k.wall(a, b, CH, T, "l4_wall", [{"at": 7.2, "w": 1.0, "h": P.DOOR_H}], GeoKit.ALL)
	P.door_trim(k, a, b, 7.2, P.DOOR_W, P.DOOR_H, "l4_frame", "l4_door", 1.0)
	for at in [2.4, 12.0, 16.8, 20.4]:
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, -1.0, true)
		if at > 10.0:
			P.black_window(k, a, b, at, 1.6, 0.9, 1.4, 1.0, int(at) % 3 == 0)
	# two empty private offices on the north side
	a = Vector3(2.4 - T * 0.5, y, 7.2)
	b = Vector3(12.0 + T * 0.5, y, 7.2)
	k.wall(a, b, CH, T, "l4_wall", [{"at": 2.6, "w": P.DOOR_W, "h": P.DOOR_H}, {"at": 7.2, "w": P.DOOR_W, "h": P.DOOR_H}], GeoKit.ALL)
	P.door_trim(k, a, b, 2.6, P.DOOR_W, P.DOOR_H, "l4_frame", "l4_door", -1.0)
	P.door_trim(k, a, b, 7.2, P.DOOR_W, P.DOOR_H, "l4_frame", "", 0.0)
	k.wall(Vector3(7.2, y, 2.4), Vector3(7.2, y, 7.2), CH, T, "l4_wall", [], GeoKit.ALL)
	k.wall(Vector3(12.0, y, 2.4), Vector3(12.0, y, 7.2), CH, T, "l4_wall", [], GeoKit.ALL)
	for p in [Vector3(4.8, y + CH - 0.004, 4.8), Vector3(9.6, y + CH - 0.004, 4.8)]:
		k.panel(p, 0.6, 1.2, "l4_panel", 100.0 if p.x > 6.0 else 3.0, 0.0)
	lvl.lights.add_anchor(Vector3(4.8, y + CH - 0.3, 4.8), Color(0.92, 0.96, 1.0), 0.8, 4.0, 0.0, "0,0")
	# east: the tall blacked-out windows seen across the atrium
	a = Vector3(24.0, y, 2.4)
	b = Vector3(24.0, y, 24.0 + T * 0.5)
	k.wall(a, b, CH, T, "l4_wall", [], GeoKit.ALL)
	for at in [2.6, 6.2, 9.8, 13.4, 17.0, 20.6]:
		P.black_window(k, a, b, at, 1.8, 0.55, 1.95, 1.0, r.randf() < 0.4)
		P.black_window(k, a, b, at, 1.8, 0.55, 1.95, -1.0, false)
	a = Vector3(2.4, y, 24.0)
	b = Vector3(24.0 + T * 0.5, y, 24.0)
	k.wall(a, b, CH, T, "l4_wall", [{"at": 12.0, "w": 2.4, "h": 2.3}], GeoKit.ALL)
	for at in [4.8, 17.4]:
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, 1.0, true)
		P.black_window(k, a, b, at, 1.6, 0.9, 1.4, -1.0)


func _base_omega(k: GeoKit, node: Node3D) -> void:
	var a := Vector3(19.2, 0, 2.4)
	var b := Vector3(19.2, 0, 24.0)
	var ops := [{"at": 3.6, "w": 3.0, "h": 2.5}, {"at": 10.8, "w": 3.0, "h": 2.5}, {"at": 15.6, "w": 1.0, "h": P.DOOR_H}]
	k.wall(a, b, CH, 0.2, "l4_block", ops, GeoKit.ALL)
	for at in [3.6, 10.8]:
		var c := a + Vector3(0, 0, at)
		k.box(c + Vector3(0.0, 1.25, 0), Vector3(0.08, 2.5, 3.0), "l4_shutter")
		k.box(c + Vector3(-0.2, 2.62, 0), Vector3(0.3, 0.3, 3.2), "l4_steel", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(-0.08, 1.25, s * 1.53), Vector3(0.12, 2.5, 0.06), "l4_steel", GeoKit.ALL, false)
		P.label(node, "NO ENTRY", c + Vector3(-0.045, 1.6, 0), Vector3.LEFT, 0.0045, Color(0.65, 0.12, 0.08))
	var dc := a + Vector3(0, 0, 15.6)
	k.box(dc + Vector3(0, 1.05, 0), Vector3(0.06, 2.1, 0.98), "l4_firedoor")
	P.door_trim(k, a, b, 15.6, P.DOOR_W, P.DOOR_H, "l4_frame", "", 0.0)
	k.box(dc + Vector3(-0.08, 1.0, 0.36), Vector3(0.05, 0.03, 0.14), "l4_alu", GeoKit.ALL, false)
	k.box(dc + Vector3(-0.12, 2.42, 0), Vector3(0.02, 0.26, 1.4), "l4_white", GeoKit.ALL, false)
	P.label(node, "M.E.G.  BASE OMEGA", dc + Vector3(-0.135, 2.45, 0), Vector3.LEFT, 0.0021, Color(0.08, 0.1, 0.16))
	P.label(node, "RESIDENT TEAMS ONLY", dc + Vector3(-0.135, 2.34, 0), Vector3.LEFT, 0.0012, Color(0.45, 0.08, 0.06))
	lvl.add_interactable(dc + Vector3(-0.3, 1.1, 0), Vector3(0.4, 2.0, 1.0), "Try the door", lvl.base_door)
	# work lights over the shutters keep the guarded wall lit
	for z in [6.0, 13.2, 18.0]:
		lvl.lights.add_anchor(Vector3(18.4, 2.5, z), Color(1.0, 0.9, 0.72), 1.3, 6.0, 0.0, "0,0")
		k.panel(Vector3(18.0, CH - 0.004, z), 0.6, 1.2, "l4_panel_warm", 2.0, 0.0)


func _atrium(k: GeoKit, node: Node3D, group: String) -> void:
	var x0 := ATR.position.x
	var z0 := ATR.position.y
	var x1 := ATR.end.x
	var z1 := ATR.end.y
	var y: float = FY[1]
	for e in [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)], [Vector3(x1, 0, z1), Vector3(x0, 0, z1)], [Vector3(x0, 0, z1), Vector3(x0, 0, z0)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var mn := Vector3(minf(a.x, b.x) - 0.03, CH, minf(a.z, b.z) - 0.03)
		var mx := Vector3(maxf(a.x, b.x) + 0.03, y, maxf(a.z, b.z) + 0.03)
		k.box_mm(mn, mx, "l4_wall", GeoKit.ALL, false)
		k.box_mm(Vector3(mn.x, y, mn.z), Vector3(mx.x, y + 1.0, mx.z), "l4_glass", GeoKit.ALL, true)
		k.box_mm(Vector3(mn.x - 0.02, y + 1.0, mn.z - 0.02), Vector3(mx.x + 0.02, y + 1.06, mx.z + 0.02), "l4_rail", GeoKit.ALL, false)
	for j in 4:
		for i in 4:
			var c := Vector3(x0 + 1.2 + i * 2.4, y + CH - 0.004, z0 + 1.35 + j * 2.7)
			var dead := (i + j * 3) % 5 == 2
			k.panel(c, 0.6, 1.2, "l4_panel", 100.0 if dead else float(i + j * 4), 0.0)
			if not dead and (i + j) % 2 == 0:
				lvl.lights.add_anchor(c + Vector3.DOWN * 1.1, Color(0.92, 0.96, 1.0), 1.6, 9.5, 0.0, group)
	# empty floor below: unfaded carpet where desks used to be
	for p in [Vector2(10.8, 12.4), Vector2(14.6, 12.4), Vector2(10.8, 17.2), Vector2(14.8, 17.6)]:
		for q in 4:
			var qx: float = p.x + (q % 2) * 1.75
			var qz: float = p.y + (q / 2) * 0.95
			k.box_mm(Vector3(qx, 0.0, qz), Vector3(qx + 1.6, 0.004, qz + 0.8), "l4_carpet_ghost", GeoKit.PY, false)
	k.box(Vector3(16.4, 0.18, 19.6), Vector3(0.52, 0.36, 0.4), "l4_cardboard")
	k.box(Vector3(12.9, 0.003, 15.0), Vector3(0.14, 0.006, 0.14), "l4_alu", GeoKit.ALL, false)
	# columns along the gallery edge carry the upper floor
	for p in [Vector3(9.3, 0, 10.5), Vector3(9.3, 0, 21.9)]:
		k.box(p + Vector3(0, CH * 0.5, 0), Vector3(0.45, CH, 0.45), "l4_wall", GeoKit.SIDES)
