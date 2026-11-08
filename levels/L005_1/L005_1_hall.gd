extends RefCounted
## Level 5.1 architecture and dressing. The casino wears the Terror Hotel's own
## material language (Level 5: mahogany-red and gold damask, walnut wainscot,
## gilt trim, white marble, red-and-gold carpet, crystal chandeliers), then turns
## Vegas: slot banks, roulette, card and dice tables, a bar, a stage, red neon.
## SOURCE: "a large, Vegas-style casino" (~5000 occupancy) with the initials "TH"
## in large red letters; roulettes, cards, dice, slots; dim lights that flash;
## classy new carpet; a bar run by The Barkeep; chips bartered at the front desk.
## ADAPTATION: the plan (entrance lobby, sunk gaming floor ringed by a promenade,
## the Beast's raised table, a stage, an east mezzanine with the bar) is ours.

const FL := -0.6        # sunk gaming floor
const CEIL := 7.5
const MEZ := 4.2
const LOBBY_H := 6.5

var lvl: LevelBase
var dress: Node3D
var slot_sites: Array = []     # [{pos, size, dir}] interactable spans of slot rows
var tables: Array = []         # [{kind, pos}]
var lamp_anchors: Array = []   # anchor ids that pulse with the casino lights
var _cue_mat: StandardMaterial3D


func _init(level: LevelBase) -> void:
	lvl = level
	dress = Node3D.new()
	dress.name = "Dressing"
	lvl.add_child(dress)


static func _m(n: String, p: Dictionary, base := "") -> void:
	MatLib.define(n, p, base)


static func _emit(n: String, c: Color, e: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	MatLib.register(n, m)


static func materials() -> void:
	var gold := Color(0.56, 0.4, 0.17)
	# Level 5 language (same colours as the hotel)
	_m("l51_wallpaper", {"albedo_a": Color(0.34, 0.05, 0.04), "albedo_b": Color(0.27, 0.035, 0.03), "pattern": 10, "pattern_scale": Vector2(0.21, 0.29), "pattern_color": gold, "pattern_strength": 0.42, "noise_scale": 0.6, "roughness_a": 0.6, "roughness_b": 0.75, "bump_strength": 0.6})
	_m("l51_wainscot", {"albedo_a": Color(0.22, 0.12, 0.065), "albedo_b": Color(0.18, 0.095, 0.05), "pattern": 1, "pattern_scale": Vector2(0.8, 0.95), "grout_color": Color(0.09, 0.045, 0.025), "grout_width": 0.035, "tile_variation": 0.05, "roughness_a": 0.28, "roughness_b": 0.42, "bump_strength": 0.8})
	_m("l51_gold", {"albedo_a": Color(0.78, 0.58, 0.26), "albedo_b": Color(0.64, 0.46, 0.18), "metallic_value": 0.85, "roughness_a": 0.28, "roughness_b": 0.45, "noise_scale": 3.0})
	_m("l51_brass", {"albedo_a": Color(0.62, 0.47, 0.22), "albedo_b": Color(0.52, 0.38, 0.16), "metallic_value": 0.85, "roughness_a": 0.25, "roughness_b": 0.4})
	_m("l51_marble", {"albedo_a": Color(0.88, 0.86, 0.82), "albedo_b": Color(0.79, 0.77, 0.73), "pattern": 9, "pattern_scale": Vector2(0.6, 0.6), "pattern_color": Color(0.07, 0.065, 0.06), "pattern_strength": 0.5, "grout_color": Color(0.45, 0.43, 0.4), "grout_width": 0.004, "roughness_a": 0.05, "roughness_b": 0.16, "noise_scale": 2.4, "tile_variation": 0.02, "bump_strength": 0.3})
	_m("l51_marble_w", {"albedo_a": Color(0.9, 0.88, 0.84), "albedo_b": Color(0.82, 0.8, 0.76), "noise_scale": 2.2, "roughness_a": 0.12, "roughness_b": 0.22}, "plaster")
	_m("l51_marble_dark", {"albedo_a": Color(0.06, 0.12, 0.09), "albedo_b": Color(0.03, 0.06, 0.05), "noise_scale": 2.0, "roughness_a": 0.1, "roughness_b": 0.2}, "plaster")
	_m("l51_ceiling", {"albedo_a": Color(0.5, 0.36, 0.22), "albedo_b": Color(0.44, 0.31, 0.19), "noise_scale": 0.8, "roughness_a": 0.8})
	_m("l51_mahogany", {"albedo_a": Color(0.25, 0.1, 0.06), "albedo_b": Color(0.2, 0.08, 0.045), "pattern": 3, "pattern_scale": Vector2(1.2, 0.1), "grout_color": Color(0.08, 0.03, 0.02), "grout_width": 0.002, "roughness_a": 0.15, "roughness_b": 0.3})
	_m("l51_velvet", {"albedo_a": Color(0.4, 0.04, 0.05), "albedo_b": Color(0.3, 0.025, 0.035), "roughness_a": 0.85, "roughness_b": 0.95, "noise_scale": 1.5, "bump_strength": 0.3})
	_m("l51_curtain", {"albedo_a": Color(0.42, 0.03, 0.04), "albedo_b": Color(0.24, 0.015, 0.02), "pattern": 2, "pattern_scale": Vector2(0.35, 1.0), "pattern_color": Color(0.18, 0.01, 0.015), "pattern_strength": 0.8, "roughness_a": 0.9})
	# the casino: classy new carpet, felt, lacquer and neon
	_m("l51_carpet", {"albedo_a": Color(0.3, 0.035, 0.05), "albedo_b": Color(0.22, 0.025, 0.04), "pattern": 6, "pattern_scale": Vector2(0.42, 0.42), "pattern_color": Color(0.62, 0.42, 0.12), "pattern_strength": 0.45, "noise_scale": 0.4, "bump_strength": 0.5, "roughness_a": 0.95})
	_m("l51_carpet_b", {"albedo_a": Color(0.05, 0.12, 0.13), "albedo_b": Color(0.035, 0.09, 0.1), "pattern": 6, "pattern_scale": Vector2(0.7, 0.7), "pattern_color": Color(0.7, 0.45, 0.12), "pattern_strength": 0.6, "roughness_a": 0.95})
	_m("l51_felt", {"albedo_a": Color(0.04, 0.26, 0.12), "albedo_b": Color(0.03, 0.22, 0.1), "noise_scale": 3.0, "roughness_a": 0.95, "bump_strength": 0.2}, "plaster")
	_m("l51_lacquer_red", {"albedo_a": Color(0.42, 0.03, 0.04), "albedo_b": Color(0.36, 0.02, 0.03), "roughness_a": 0.12, "roughness_b": 0.2, "metallic_value": 0.3}, "plaster")
	_m("l51_lacquer_black", {"albedo_a": Color(0.04, 0.04, 0.05), "albedo_b": Color(0.03, 0.03, 0.035), "roughness_a": 0.1, "roughness_b": 0.18, "metallic_value": 0.5}, "plaster")
	_m("l51_chrome", {"albedo_a": Color(0.75, 0.76, 0.78), "albedo_b": Color(0.65, 0.66, 0.68), "metallic_value": 0.95, "roughness_a": 0.12, "roughness_b": 0.2})
	_m("l51_wheel", {"albedo_a": Color(0.4, 0.02, 0.02), "albedo_b": Color(0.02, 0.02, 0.02), "pattern": 2, "pattern_scale": Vector2(0.06, 1.0), "pattern_color": Color(0.02, 0.02, 0.02), "pattern_strength": 1.0, "roughness_a": 0.2}, "plaster")
	_m("l51_reel", {"albedo_a": Color(0.92, 0.9, 0.84), "albedo_b": Color(0.88, 0.86, 0.8), "pattern": 5, "pattern_scale": Vector2(0.09, 0.09), "pattern_color": Color(0.7, 0.1, 0.08), "pattern_strength": 0.8}, "plaster")
	_m("l51_bottles", {"albedo_a": Color(0.5, 0.26, 0.05), "albedo_b": Color(0.08, 0.2, 0.08), "pattern": 2, "pattern_scale": Vector2(0.09, 1.0), "pattern_color": Color(0.35, 0.04, 0.06), "pattern_strength": 0.6, "roughness_a": 0.05, "emission_color": Color(0.5, 0.3, 0.1), "emission_energy": 0.35}, "plaster")
	_m("l51_staff_suit", {"albedo_a": Color(0.05, 0.05, 0.06), "albedo_b": Color(0.04, 0.04, 0.05), "roughness_a": 0.7}, "plaster")
	_m("l51_staff_vest", {"albedo_a": Color(0.45, 0.04, 0.05), "albedo_b": Color(0.38, 0.03, 0.04), "pattern": 10, "pattern_scale": Vector2(0.08, 0.1), "pattern_color": gold, "pattern_strength": 0.3}, "plaster")
	_m("l51_shirt", {"albedo_a": Color(0.88, 0.86, 0.82), "albedo_b": Color(0.84, 0.82, 0.78)}, "plaster")
	_m("l51_skin", {"albedo_a": Color(0.62, 0.5, 0.42), "albedo_b": Color(0.56, 0.44, 0.37), "roughness_a": 0.6}, "plaster")
	_emit("l51_neon_red", Color(1.0, 0.06, 0.04), 4.5)
	_emit("l51_bulbs", Color(1.0, 0.78, 0.45), 3.0)
	_emit("l51_slot_screen", Color(0.35, 0.55, 1.0), 1.6)
	_emit("l51_slot_screen_b", Color(1.0, 0.35, 0.6), 1.6)
	_emit("l51_slot_top", Color(1.0, 0.55, 0.15), 2.2)
	_emit("l51_backbar", Color(1.0, 0.62, 0.3), 0.5)
	_emit("l51_shade", Color(0.25, 0.55, 0.3), 0.6)
	_emit("l51_sconce", Color(1.0, 0.7, 0.4), 2.0)


func _p(id: String, pos: Vector3, yaw := 0.0, h := 0.0, collide := false) -> Node3D:
	return Props.place(lvl, dress, id, pos, yaw, h, collide)


## A hotel wall: damask, a walnut wainscot and a gilt rail on the inside face.
func _hwall(k: GeoKit, a: Vector3, b: Vector3, h: float, ops: Array, inside: int, base_y := 0.0) -> void:
	k.wall(a, b, h, 0.4, "l51_wallpaper", ops)
	var dir := (b - a)
	dir.y = 0.0
	dir = dir.normalized()
	var n := dir.cross(Vector3.UP).normalized() * float(inside)
	var off := n * 0.215
	var face := GeoKit.PZ if inside > 0 else GeoKit.NZ
	var wops: Array = []
	for o in ops:
		if float(o.get("sill", 0.0)) < 1.1:
			wops.append(o)
	k.wall(a + off + Vector3(0, base_y, 0), b + off + Vector3(0, base_y, 0), 1.1, 0.03, "l51_wainscot", wops, face | GeoKit.PY)
	k.wall(a + off * 1.25 + Vector3(0, base_y + 1.1, 0), b + off * 1.25 + Vector3(0, base_y + 1.1, 0), 0.07, 0.05, "l51_gold", wops, GeoKit.ALL)
	k.wall(a + off * 1.25 + Vector3(0, h - 0.3, 0), b + off * 1.25 + Vector3(0, h - 0.3, 0), 0.3, 0.12, "l51_gold", [], face | GeoKit.NY)


# ------------------------------------------------------------------ shell

func shell(k: GeoKit) -> void:
	# entrance lobby (hotel marble), front doors at z = 0
	k.slab(-9.0, 0.0, 9.0, 12.0, 0.0, 0.4, "l51_marble")
	_hwall(k, Vector3(-9.0, 0, 0.0), Vector3(9.0, 0, 0.0), LOBBY_H, [{"at": 9.0, "w": 3.2, "h": 3.2}], 1)
	_hwall(k, Vector3(-9.0, 0, 12.0), Vector3(-9.0, 0, 0.0), LOBBY_H, [], 1)
	_hwall(k, Vector3(9.0, 0, 0.0), Vector3(9.0, 0, 12.0), LOBBY_H, [], 1)
	k.box_mm(Vector3(-9.2, LOBBY_H, -0.2), Vector3(9.2, LOBBY_H + 0.3, 12.0), "l51_ceiling", GeoKit.NY, false)
	for x in [-4.5, 0.0, 4.5]:
		k.box(Vector3(x, LOBBY_H - 0.1, 6.0), Vector3(0.3, 0.2, 12.0), "l51_gold", GeoKit.ALL, false)
	# the doors (walnut with gilt, closed: you leave through them)
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 0.8, 1.6, 0.05), Vector3(1.55, 3.18, 0.1), "l51_mahogany")
		k.box(Vector3(s * 0.25, 1.15, 0.13), Vector3(0.05, 0.4, 0.05), "l51_gold", GeoKit.ALL, false)
	k.box(Vector3(0, 3.35, 0.24), Vector3(3.8, 0.3, 0.1), "l51_gold", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 1.75, 1.6, 0.24), Vector3(0.22, 3.2, 0.1), "l51_gold", GeoKit.ALL, false)
	# arch to the gaming floor, with the TH in large red letters above it
	_hwall(k, Vector3(-9.0, 0, 12.0), Vector3(9.0, 0, 12.0), LOBBY_H, [{"at": 9.0, "w": 8.0, "h": 4.0}], -1)
	_th(k, Vector3(0, 4.15, 11.76), -1.0, 1.0)
	# gaming hall shell
	k.slab(-30.0, 12.0, 30.0, 62.0, FL, 0.5, "l51_carpet")
	_hwall(k, Vector3(-30.0, FL, 62.0), Vector3(-30.0, FL, 12.0), CEIL - FL, [], 1, 0.6)
	_hwall(k, Vector3(30.0, FL, 12.0), Vector3(30.0, FL, 62.0), CEIL - FL, [], 1, 0.6)
	_hwall(k, Vector3(30.0, FL, 62.0), Vector3(-30.0, FL, 62.0), CEIL - FL, [], 1, 0.6)
	k.wall(Vector3(-30.0, FL, 12.0), Vector3(-9.0, FL, 12.0), CEIL - FL, 0.4, "l51_wallpaper")
	k.wall(Vector3(9.0, FL, 12.0), Vector3(30.0, FL, 12.0), CEIL - FL, 0.4, "l51_wallpaper")
	k.box_mm(Vector3(-9.0, LOBBY_H, 11.8), Vector3(9.0, CEIL, 12.2), "l51_wallpaper")
	_th(k, Vector3(0, 4.6, 12.24), 1.0, 1.25)
	k.box_mm(Vector3(-30.2, CEIL, 11.8), Vector3(30.2, CEIL + 0.3, 62.2), "l51_ceiling", GeoKit.NY, false)
	var x := -25.0
	while x <= 25.0:
		k.box(Vector3(x, CEIL - 0.18, 37.0), Vector3(0.35, 0.36, 50.0), "l51_gold", GeoKit.ALL, false)
		x += 5.0
	var z := 17.0
	while z <= 57.0:
		k.box(Vector3(0.0, CEIL - 0.18, z), Vector3(60.0, 0.36, 0.35), "l51_gold", GeoKit.ALL, false)
		z += 5.0
	# pilasters with gilt capitals around the hall
	for zz in [18.0, 26.0, 34.0, 42.0, 50.0, 58.0]:
		for s in [-1.0, 1.0]:
			k.box(Vector3(s * 29.65, (CEIL - 0.6) * 0.5, zz), Vector3(0.3, CEIL - 0.6, 0.7), "l51_marble_w", GeoKit.ALL, false)
			k.box(Vector3(s * 29.62, CEIL - 0.45, zz), Vector3(0.38, 0.3, 0.85), "l51_gold", GeoKit.ALL, false)
	# four marble columns hold the coffered ceiling over the floor
	for cp in [Vector3(-7.5, 0, 24.0), Vector3(-7.5, 0, 50.0), Vector3(2.5, 0, 24.0), Vector3(2.5, 0, 50.0)]:
		k.cylinder(Vector3(cp.x, (FL + CEIL) * 0.5, cp.z), 0.5, CEIL - FL, "l51_marble_w", 20)
		k.box(Vector3(cp.x, CEIL - 0.35, cp.z), Vector3(1.3, 0.5, 1.3), "l51_gold", GeoKit.ALL, false)
		k.box(Vector3(cp.x, FL + 0.2, cp.z), Vector3(1.2, 0.4, 1.2), "l51_marble_dark", GeoKit.ALL, false)
		k.cylinder(Vector3(cp.x, FL + 1.3, cp.z), 0.52, 0.05, "l51_gold", 20, false)
	_promenade(k)
	_mezzanine(k)
	_stage(k)
	_dais(k)


## Large red letters "TH" (neon tubes on gilt backing boards).
func _th(k: GeoKit, c: Vector3, facing: float, s: float) -> void:
	var zf := c.z
	var d := 0.12 * facing
	var bars := [[Vector3(-1.25, 2.0, 0), Vector3(1.7, 0.32, 0)], [Vector3(-1.25, 1.0, 0), Vector3(0.32, 2.0, 0)],
		[Vector3(0.45, 1.0, 0), Vector3(0.32, 2.3, 0)], [Vector3(1.55, 1.0, 0), Vector3(0.32, 2.3, 0)], [Vector3(1.0, 1.0, 0), Vector3(1.1, 0.28, 0)]]
	for b in bars:
		var p: Vector3 = b[0] * s
		p.x *= facing
		var sz: Vector3 = b[1] * s
		k.box(Vector3(c.x + p.x, c.y + p.y, zf + d), Vector3(sz.x, sz.y, 0.14), "l51_neon_red", GeoKit.ALL, false)
		k.box(Vector3(c.x + p.x, c.y + p.y, zf), Vector3(sz.x + 0.14, sz.y + 0.14, 0.1), "l51_gold", GeoKit.ALL, false)


## The promenade ring (y = 0) around the sunk floor, with brass rails and stairs.
func _promenade(k: GeoKit) -> void:
	var strips := [[-30.0, 12.0, -25.0, 62.0], [-25.0, 12.0, 22.0, 16.0], [22.0, 12.0, 30.0, 62.0], [-25.0, 58.0, -9.0, 62.0], [9.0, 58.0, 22.0, 62.0]]
	for r in strips:
		k.box_mm(Vector3(r[0], FL, r[1]), Vector3(r[2], 0.0, r[3]), "l51_carpet_b", GeoKit.PY | GeoKit.SIDES)
	k.stairs(Vector3(0.0, FL, 17.2), Vector3(0, 0, -1), 8.0, 0.6, 4, "l51_marble", 0.3)
	k.stairs(Vector3(-23.8, FL, 37.0), Vector3(-1, 0, 0), 3.0, 0.6, 4, "l51_marble", 0.3)
	k.stairs(Vector3(20.8, FL, 30.0), Vector3(1, 0, 0), 3.0, 0.6, 4, "l51_marble", 0.3)
	# brass rails along the drop (gaps at the stairs)
	var rails := [[Vector3(-25.0, 0, 16.0), Vector3(-4.0, 0, 16.0)], [Vector3(4.0, 0, 16.0), Vector3(22.0, 0, 16.0)],
		[Vector3(-25.0, 0, 16.0), Vector3(-25.0, 0, 35.5)], [Vector3(-25.0, 0, 38.5), Vector3(-25.0, 0, 58.0)],
		[Vector3(22.0, 0, 16.0), Vector3(22.0, 0, 28.5)], [Vector3(22.0, 0, 31.5), Vector3(22.0, 0, 58.0)],
		[Vector3(-25.0, 0, 58.0), Vector3(-9.0, 0, 58.0)], [Vector3(9.0, 0, 58.0), Vector3(22.0, 0, 58.0)]]
	for r in rails:
		_rail(k, r[0], r[1], 0.95)


func _rail(k: GeoKit, a: Vector3, b: Vector3, h: float) -> void:
	var d := b - a
	var n := maxi(1, int(d.length() / 1.5))
	for i in n + 1:
		k.box(a + d * float(i) / n + Vector3(0, h * 0.5, 0), Vector3(0.05, h, 0.05), "l51_brass", GeoKit.SIDES, false)
	var c := (a + b) * 0.5 + Vector3(0, h, 0)
	var horiz := absf(d.x) > absf(d.z)
	k.box(c, Vector3(d.length() if horiz else 0.08, 0.06, 0.08 if horiz else d.length()), "l51_brass", GeoKit.ALL, false)
	k.box((a + b) * 0.5 + Vector3(0, h * 0.5, 0), Vector3(d.length() if horiz else 0.04, h, 0.04 if horiz else d.length()), "l51_brass", 0, true)


## East mezzanine (+4.2 m): the bar and lounge, reached by a grand stair.
func _mezzanine(k: GeoKit) -> void:
	k.box_mm(Vector3(22.0, MEZ - 0.35, 12.4), Vector3(29.8, MEZ, 58.0), "l51_carpet", GeoKit.PY | GeoKit.SIDES)
	k.box_mm(Vector3(22.0, MEZ - 0.36, 12.4), Vector3(29.8, MEZ - 0.35, 58.0), "l51_ceiling", GeoKit.NY, false)
	for zz in [18.0, 25.0, 32.0, 39.0, 46.0, 53.0]:
		k.cylinder(Vector3(22.45, (MEZ - 0.35) * 0.5, zz), 0.32, MEZ - 0.35, "l51_marble_w", 16)
		k.box(Vector3(22.45, MEZ - 0.5, zz), Vector3(0.9, 0.3, 0.9), "l51_gold", GeoKit.ALL, false)
	k.box(Vector3(22.05, MEZ - 0.18, 35.2), Vector3(0.12, 0.36, 45.6), "l51_gold", GeoKit.ALL, false)
	_rail(k, Vector3(22.15, MEZ, 14.8), Vector3(22.15, MEZ, 58.0), 1.0)
	_rail(k, Vector3(22.15, MEZ, 58.0), Vector3(29.8, MEZ, 58.0), 1.0)
	# grand stair up from the south promenade
	var steps := 23
	var start := Vector3(14.6, 0.0, 13.6)
	k.stairs(start, Vector3(1, 0, 0), 2.2, MEZ, steps, "l51_marble", 0.28)
	k.box_mm(Vector3(14.6 + steps * 0.28, 0.0, 12.4), Vector3(22.0, MEZ, 14.75), "l51_marble_w", GeoKit.ALL)
	for i in steps:
		var top := MEZ * float(i + 1) / steps
		k.box(Vector3(start.x + 0.28 * (i + 0.5), top + 0.45, 14.76), Vector3(0.29, 0.9, 0.06), "l51_brass", GeoKit.ALL, false)
	k.box(Vector3(start.x + steps * 0.14, MEZ * 0.5 + 0.45, 14.76), Vector3(steps * 0.28, 0.9, 0.05), "l51_brass", 0, true)
	_rail(k, Vector3(14.6 + steps * 0.28, MEZ, 14.8), Vector3(22.15, MEZ, 14.8), 1.0)
	# the bar: counter, back bar of strange bottles, stools
	k.box_mm(Vector3(27.6, MEZ, 22.0), Vector3(28.4, MEZ + 1.05, 44.0), "l51_mahogany")
	k.box_mm(Vector3(27.5, MEZ + 1.05, 21.9), Vector3(28.55, MEZ + 1.11, 44.1), "l51_marble_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(29.5, MEZ, 22.0), Vector3(29.78, MEZ + 3.0, 44.0), "l51_mahogany", GeoKit.ALL, false)
	for yy in [1.3, 1.8, 2.3]:
		k.box_mm(Vector3(29.3, MEZ + yy - 0.03, 22.2), Vector3(29.78, MEZ + yy, 43.8), "l51_gold", GeoKit.ALL, false)
	k.box_mm(Vector3(29.76, MEZ + 1.0, 22.2), Vector3(29.79, MEZ + 2.8, 43.8), "l51_backbar", GeoKit.NX, false)
	_bottles()


## The stage where the grand opening was announced: velvet curtain, marquee bulbs.
func _stage(k: GeoKit) -> void:
	k.box_mm(Vector3(-9.0, FL, 55.0), Vector3(9.0, 0.5, 62.0), "l51_mahogany", GeoKit.PY | GeoKit.SIDES)
	k.stairs(Vector3(0.0, FL, 53.8), Vector3(0, 0, 1), 4.0, 1.1, 6, "l51_marble", 0.2)
	k.box_mm(Vector3(-8.6, 0.5, 61.4), Vector3(8.6, 6.4, 61.7), "l51_curtain", GeoKit.NZ, false)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(minf(s * 9.0, s * 9.6), FL, 54.8), Vector3(maxf(s * 9.0, s * 9.6), 6.8, 55.4), "l51_gold")
		k.box_mm(Vector3(minf(s * 6.0, s * 8.6), 0.5, 55.6), Vector3(maxf(s * 6.0, s * 8.6), 6.4, 55.9), "l51_curtain", GeoKit.NZ | GeoKit.PZ, false)
	k.box_mm(Vector3(-9.6, 6.4, 54.8), Vector3(9.6, 7.2, 55.4), "l51_gold", GeoKit.ALL, false)
	for i in 31:
		var x := -9.3 + float(i) * 0.62
		k.box(Vector3(x, 6.8, 54.74), Vector3(0.1, 0.1, 0.06), "l51_bulbs", GeoKit.ALL, false)
	for i in 10:
		var y := FL + 0.5 + float(i) * 0.62
		for s in [-1.0, 1.0]:
			k.box(Vector3(s * 9.3, y, 54.74), Vector3(0.1, 0.1, 0.06), "l51_bulbs", GeoKit.ALL, false)
	k.cylinder(Vector3(0.0, 0.5 + 0.75, 57.0), 0.012, 1.5, "l51_chrome", 6, false)
	k.cylinder(Vector3(0.0, 0.52, 57.0), 0.14, 0.04, "l51_chrome", 12, false)
	k.box(Vector3(0.0, 2.02, 57.0), Vector3(0.05, 0.1, 0.05), "l51_lacquer_black", GeoKit.ALL, false)


## Mr. Gentleman's table: a raised round dais behind velvet ropes.
func _dais(k: GeoKit) -> void:
	var c := Vector3(-2.0, 0.0, 37.0)
	k.cylinder(Vector3(c.x, FL + 0.6, c.z), 3.6, 1.2, "l51_marble_dark", 32)
	k.cylinder(Vector3(c.x, 0.61, c.z), 3.3, 0.02, "l51_velvet", 32, false)
	k.cylinder(Vector3(c.x, 0.4, c.z), 3.62, 0.08, "l51_gold", 32, false)
	k.stairs(Vector3(c.x, FL, c.z - 3.6 - 1.7), Vector3(0, 0, 1), 2.0, 1.2, 8, "l51_marble", 0.25)
	for i in 14:
		var a := TAU * float(i) / 14.0
		if absf(a - PI * 1.5) < 0.35:
			continue
		var p := c + Vector3(cos(a), 0, sin(a)) * 3.35
		k.cylinder(Vector3(p.x, 0.6 + 0.45, p.z), 0.035, 0.9, "l51_brass", 8, false)
		k.cylinder(Vector3(p.x, 0.6 + 0.92, p.z), 0.06, 0.06, "l51_brass", 8, false)
	for i in 14:
		var a0 := TAU * float(i) / 14.0
		var a1 := TAU * float(i + 1) / 14.0
		if absf(a0 - PI * 1.5) < 0.35 or absf(a1 - PI * 1.5) < 0.35:
			continue
		var p0 := c + Vector3(cos(a0), 0, sin(a0)) * 3.35
		var p1 := c + Vector3(cos(a1), 0, sin(a1)) * 3.35
		var mid := (p0 + p1) * 0.5 + Vector3(0, 0.6 + 0.72, 0)
		k.box_xf(Transform3D(Basis(Vector3.UP, -atan2(p1.z - p0.z, p1.x - p0.x)), mid), Vector3((p1 - p0).length(), 0.04, 0.04), "l51_velvet", GeoKit.ALL, false)
	k.cylinder(Vector3(c.x, 0.6 + 0.38, c.z), 0.12, 0.76, "l51_mahogany", 12, true)
	k.cylinder(Vector3(c.x, 0.6 + 0.77, c.z), 0.85, 0.04, "l51_felt", 28, false)
	k.cylinder(Vector3(c.x, 0.6 + 0.765, c.z), 0.9, 0.05, "l51_mahogany", 28, false)
	_p("ph/ArmChair_01", Vector3(c.x, 0.6, c.z - 1.25), 0.0, 1.07, true)
	_p("ph/ArmChair_01", Vector3(c.x, 0.6, c.z + 1.3), 180.0, 1.45, true)
	_p("kenney/food-kit/cup-saucer", Vector3(c.x + 0.15, 0.6 + 0.79, c.z + 0.55), 0.0, 0.03)
	_p("kenney/food-kit/cup-tea", Vector3(c.x + 0.15, 0.6 + 0.81, c.z + 0.55), 30.0, 0.07)
	for i in 5:
		k.cylinder(Vector3(c.x - 0.3 + float(i) * 0.03, 0.6 + 0.8 + float(i) * 0.012, c.z - 0.3), 0.022, 0.01, "l51_lacquer_red" if i % 2 == 0 else "l51_gold", 10, false)
	tables.append({"kind": "beast", "pos": c + Vector3(0, 0.6, 0)})


# ------------------------------------------------------------------ games

## A slot machine cabinet facing `dir` (+1 = +x, -1 = -x), base at y.
func _slot(k: GeoKit, p: Vector3, dir: float, variant: int) -> void:
	var body := "l51_lacquer_red" if variant % 2 == 0 else "l51_lacquer_black"
	var screen := "l51_slot_screen" if variant % 3 != 0 else "l51_slot_screen_b"
	var f := Vector3(dir, 0, 0)
	k.box(p + Vector3(0, 0.62, 0), Vector3(0.66, 1.24, 0.84), body, GeoKit.ALL, false)
	k.box(p + Vector3(0, 1.52, 0) - f * 0.06, Vector3(0.52, 0.56, 0.78), body, GeoKit.ALL, false)
	k.box(p + Vector3(0, 1.52, 0) + f * 0.2, Vector3(0.02, 0.4, 0.62), screen, GeoKit.ALL, false)
	k.box(p + Vector3(0, 1.08, 0) + f * 0.335, Vector3(0.02, 0.24, 0.56), "l51_reel", GeoKit.ALL, false)
	k.box(p + Vector3(0, 0.86, 0) + f * 0.38, Vector3(0.14, 0.05, 0.7), "l51_chrome", GeoKit.ALL, false)
	k.box(p + Vector3(0, 1.88, 0) - f * 0.06, Vector3(0.4, 0.16, 0.6), "l51_slot_top", GeoKit.ALL, false)
	k.box(p + Vector3(0, 0.2, 0) + f * 0.336, Vector3(0.02, 0.12, 0.3), "l51_chrome", GeoKit.ALL, false)


func slots(k: GeoKit, r: RandomNumberGenerator) -> void:
	var v := 0
	for bx in [-21.0, -15.5, -10.0]:
		for z0 in [19.0, 31.0, 43.0]:
			var n := 10
			for side in [-1.0, 1.0]:
				for i in n:
					var p := Vector3(bx + side * 0.42, FL, z0 + 0.45 + float(i) * 0.9)
					_slot(k, p, side, v + r.randi_range(0, 5))
					v += 1
					# a stool in front of each machine
					var sp := p + Vector3(side * 1.05, 0, 0)
					k.cylinder(sp + Vector3(0, 0.36, 0), 0.03, 0.72, "l51_chrome", 6, false)
					k.cylinder(sp + Vector3(0, 0.74, 0), 0.2, 0.08, "l51_velvet", 10, false)
				slot_sites.append({"pos": Vector3(bx + side * 1.1, FL + 1.0, z0 + n * 0.45), "size": Vector3(0.9, 2.0, n * 0.9), "dir": side})
			k.box(Vector3(bx, FL + 0.95, z0 + n * 0.45), Vector3(1.5, 1.9, n * 0.9), "l51_lacquer_black", 0, true)
			k.box(Vector3(bx, FL + 2.0, z0 + n * 0.45), Vector3(0.36, 0.2, n * 0.9), "l51_lacquer_black", GeoKit.ALL, false)
			k.box(Vector3(bx, FL + 2.0, z0 + n * 0.45), Vector3(0.38, 0.05, n * 0.9 - 0.1), "l51_neon_red", GeoKit.SIDES, false)
			k.box(Vector3(bx, FL + 2.13, z0 + n * 0.45), Vector3(0.42, 0.06, n * 0.9 + 0.1), "l51_gold", GeoKit.ALL, false)


func table_games(k: GeoKit) -> void:
	for t in [[Vector3(8.0, FL, 22.0), "roulette"], [Vector3(16.0, FL, 22.0), "roulette"], [Vector3(8.0, FL, 29.0), "roulette"],
			[Vector3(16.0, FL, 29.0), "dice"], [Vector3(8.0, FL, 38.0), "cards"], [Vector3(16.0, FL, 38.0), "cards"],
			[Vector3(8.0, FL, 46.0), "cards"], [Vector3(16.0, FL, 46.0), "cards"], [Vector3(26.0, 0.0, 24.0), "dice"], [Vector3(26.0, 0.0, 44.0), "dice"]]:
		var p: Vector3 = t[0]
		var kind: String = t[1]
		match kind:
			"roulette":
				k.box(p + Vector3(0, 0.4, 0), Vector3(2.6, 0.8, 1.2), "l51_mahogany")
				k.box(p + Vector3(0.3, 0.82, 0), Vector3(1.9, 0.04, 1.1), "l51_felt", GeoKit.PY, false)
				k.cylinder(p + Vector3(-1.05, 0.88, 0), 0.5, 0.16, "l51_mahogany", 24, false)
				k.cylinder(p + Vector3(-1.05, 0.92, 0), 0.42, 0.1, "l51_wheel", 24, false)
				k.cylinder(p + Vector3(-1.05, 1.0, 0), 0.06, 0.12, "l51_gold", 8, false)
			"cards":
				k.cylinder(p + Vector3(0, 0.4, 0), 1.15, 0.8, "l51_mahogany", 20)
				k.cylinder(p + Vector3(0, 0.81, 0), 1.05, 0.03, "l51_felt", 20, false)
				k.box(p + Vector3(0, 0.45, -1.0), Vector3(1.6, 0.9, 0.5), "l51_mahogany", GeoKit.ALL, false)
				k.box(p + Vector3(0.4, 0.88, -0.7), Vector3(0.18, 0.1, 0.3), "l51_lacquer_black", GeoKit.ALL, false)
			"dice":
				k.box(p + Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 3.6), "l51_mahogany")
				k.box(p + Vector3(0, 0.82, 0), Vector3(1.3, 0.04, 3.3), "l51_felt", GeoKit.PY, false)
				k.box(p + Vector3(0, 0.95, 0), Vector3(1.62, 0.12, 0.08), "l51_gold", GeoKit.ALL, false)
		# chip stacks in the four confirmed colours
		var cols := ["l51_lacquer_red", "l51_chip_blue", "l51_chip_yellow", "l51_chip_green"]
		for i in 4:
			var cp := p + Vector3(0.2 + float(i) * 0.12, 0.84, 0.25)
			k.cylinder(cp + Vector3(0, 0.02 + float(i) * 0.008, 0), 0.02, 0.04 + float(i) * 0.016, cols[i], 10, false)
		# simple velvet stools and a green-shaded pendant
		for j in 4:
			var a := PI * 0.25 + float(j) * PI * 0.5 / 1.5
			var sp := p + Vector3(cos(a) * 1.6, 0, sin(a) * 1.6)
			k.cylinder(sp + Vector3(0, 0.33, 0), 0.03, 0.66, "l51_brass", 6, false)
			k.cylinder(sp + Vector3(0, 0.68, 0), 0.21, 0.08, "l51_velvet", 10, false)
		var lamp_y := (CEIL - 2.2) if p.y < -0.1 else (MEZ - 1.2)
		k.box(p + Vector3(0, lamp_y + 0.15 - p.y, 0), Vector3(1.4, 0.3, 0.6), "l51_lacquer_black", GeoKit.ALL ^ GeoKit.NY, false)
		k.box(p + Vector3(0, lamp_y - p.y, 0), Vector3(1.3, 0.02, 0.5), "l51_shade", GeoKit.NY, false)
		k.cylinder(p + Vector3(0, (lamp_y + (CEIL if p.y < -0.1 else MEZ - 0.36)) * 0.5 + 0.15 - p.y, 0), 0.01, (CEIL if p.y < -0.1 else MEZ - 0.36) - lamp_y - 0.3, "l51_brass", 4, false)
		lamp_anchors.append(lvl.lights.add_anchor(Vector3(p.x, lamp_y - 0.3, p.z), Color(1.0, 0.88, 0.62), 1.3, 4.5))
		tables.append({"kind": kind, "pos": p + Vector3(0, 0.85, 0)})


static func chip_materials() -> void:
	_m("l51_chip_blue", {"albedo_a": Color(0.05, 0.12, 0.5), "albedo_b": Color(0.04, 0.1, 0.42), "roughness_a": 0.3}, "plaster")
	_m("l51_chip_yellow", {"albedo_a": Color(0.85, 0.66, 0.08), "albedo_b": Color(0.78, 0.6, 0.06), "roughness_a": 0.3}, "plaster")
	_m("l51_chip_green", {"albedo_a": Color(0.04, 0.4, 0.14), "albedo_b": Color(0.03, 0.34, 0.12), "roughness_a": 0.3}, "plaster")


# ------------------------------------------------------------------ lobby

func lobby(k: GeoKit) -> void:
	# front desk (chips bartered here) and the cashier's cage (chips traded out)
	k.box_mm(Vector3(4.6, 0.0, 4.6), Vector3(8.6, 1.1, 5.4), "l51_mahogany")
	k.box_mm(Vector3(4.5, 1.1, 4.5), Vector3(8.7, 1.16, 5.5), "l51_marble_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(4.6, 0.0, 5.4), Vector3(5.4, 1.1, 8.4), "l51_mahogany")
	k.box(Vector3(6.6, 1.5, 4.52), Vector3(1.3, 0.3, 0.04), "l51_gold", GeoKit.ALL, false)
	k.box_mm(Vector3(-8.6, 0.0, 4.6), Vector3(-4.6, 1.1, 5.4), "l51_mahogany")
	k.box_mm(Vector3(-8.7, 1.1, 4.5), Vector3(-4.5, 1.16, 5.5), "l51_marble_dark", GeoKit.ALL, false)
	for i in 14:
		k.cylinder(Vector3(-8.5 + float(i) * 0.29, 1.16 + 0.75, 4.62), 0.012, 1.5, "l51_brass", 6, false)
	k.box(Vector3(-6.6, 2.66, 4.62), Vector3(4.2, 0.06, 0.06), "l51_brass", GeoKit.ALL, false)
	k.box(Vector3(-6.6, 1.5, 4.5), Vector3(1.6, 0.3, 0.04), "l51_gold", GeoKit.ALL, false)
	k.box_mm(Vector3(-8.6, 0.0, 5.4), Vector3(-8.2, 3.0, 8.4), "l51_wainscot", GeoKit.ALL, false)
	# a red carpet runner from the doors to the arch
	k.box(Vector3(0, 0.006, 6.0), Vector3(3.2, 0.012, 11.6), "l51_carpet", GeoKit.PY, false, "carpet")
	_p("ph/Chandelier_01", Vector3(0, LOBBY_H - 1.6, 6.0), 0.0, 1.5)
	_p("ph/CashRegister_01", Vector3(-6.2, 1.16, 4.95), 180.0)
	_p("ph/CashRegister_01", Vector3(7.4, 1.16, 4.95), 180.0)
	for s in [-1.0, 1.0]:
		_p("kenney/furniture-kit/pottedplant", Vector3(s * 3.0, 0, 1.0), 0.0, 1.6)
		_p("ph/Sofa_01", Vector3(s * 8.4, 0, 10.4), -90.0 * s, 0.0, true)
		for zz in [2.5, 9.5]:
			k.box(Vector3(s * 8.76, 2.6, zz), Vector3(0.08, 0.5, 0.25), "l51_gold", GeoKit.ALL, false)
			k.box(Vector3(s * 8.7, 2.9, zz), Vector3(0.12, 0.2, 0.18), "l51_sconce", GeoKit.ALL, false)
			lvl.lights.add_anchor(Vector3(s * 8.4, 2.8, zz), Color(1.0, 0.72, 0.42), 0.7, 4.0)
	_p("ph/ornate_mirror_01", Vector3(-8.78, 1.3, 9.5), 90.0, 1.2)


# ------------------------------------------------------------------ hall dressing

func hall_dress(k: GeoKit) -> void:
	for p in [Vector3(-15.0, CEIL - 2.0, 25.0), Vector3(-15.0, CEIL - 2.0, 49.0), Vector3(2.0, CEIL - 2.0, 25.0),
			Vector3(12.0, CEIL - 2.0, 34.0), Vector3(12.0, CEIL - 2.0, 50.0), Vector3(-2.0, CEIL - 2.6, 37.0)]:
		_p("ph/Chandelier_01", p, 0.0, 1.8 if p.y > 5.0 else 1.6)
		k.cylinder(Vector3(p.x, (p.y + 1.8 + CEIL) * 0.5, p.z), 0.012, CEIL - p.y - 1.8, "l51_brass", 4, false)
	# the mezzanine lounge and bar
	for i in 7:
		_p("ph/bar_chair_round_01", Vector3(27.0, MEZ, 23.5 + float(i) * 3.0), 90.0)
	for zz in [48.0, 54.0]:
		_p("ph/Sofa_01", Vector3(29.2, MEZ, zz), -90.0, 0.0, true)
		_p("ph/coffee_table_round_01", Vector3(27.6, MEZ, zz), 0.0, 0.42)
		_p("ph/ArmChair_01", Vector3(25.9, MEZ, zz - 0.8), 100.0)
		_p("ph/ArmChair_01", Vector3(25.9, MEZ, zz + 0.8), 80.0)
	for zz in [17.0, 19.5]:
		_p("ph/ArmChair_01", Vector3(28.8, MEZ, zz), -90.0)
	_p("ph/Chandelier_01", Vector3(26.0, CEIL - 1.5, 33.0), 0.0, 1.2)
	_p("ph/Chandelier_01", Vector3(26.0, CEIL - 1.5, 50.0), 0.0, 1.2)
	# under the mezzanine: dim brass wall lamps
	for zz in [20.0, 34.0, 50.0]:
		k.box(Vector3(29.7, 2.6, zz), Vector3(0.12, 0.2, 0.18), "l51_sconce", GeoKit.ALL, false)
	# a few drinks and chips left at the machines and on the rails
	_p("kenney/food-kit/glass", Vector3(-20.0, FL + 0.86, 24.5), 0.0, 0.12)
	_p("kenney/food-kit/glass", Vector3(-14.4, FL + 0.86, 46.2), 0.0, 0.12)
	_p("kenney/food-kit/glass", Vector3(27.9, MEZ + 1.11, 30.0), 0.0, 0.12)
	_p("kenney/food-kit/glass", Vector3(27.9, MEZ + 1.11, 36.5), 0.0, 0.12)
	_p("ph/WetFloorSign_01", Vector3(23.4, 0.0, 15.6), 20.0)
	for s in [-1.0, 1.0]:
		_p("kenney/furniture-kit/pottedplant", Vector3(s * 5.0, 0.0, 14.0), 0.0, 1.8)


# ------------------------------------------------------------------ staff

## A casino staff member: vaguely human, with casino parts (SOURCE: staff are
## partly human, body parts changed to match the casino). Stylised, non-graphic.
func figure(pos: Vector3, yaw: float, kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Staff_" + kind
	root.position = pos
	root.rotation.y = deg_to_rad(yaw)
	dress.add_child(root)
	var suit := MatLib.get_mat("l51_staff_suit")
	var vest := MatLib.get_mat("l51_staff_vest")
	var shirt := MatLib.get_mat("l51_shirt")
	var skin := MatLib.get_mat("l51_skin")
	var tall := 1.15 if kind == "barkeep" else 1.0
	for x in [-0.11, 0.11]:
		if kind == "pegleg" and x > 0.0:
			_part(root, "cyl", Vector3(x, 0.42, 0), Vector3(0.05, 0.84, 0.05), MatLib.get_mat("l51_mahogany"))
		else:
			_part(root, "capsule", Vector3(x, 0.45 * tall, 0), Vector3(0.13, 0.9 * tall, 0.13), suit)
	_part(root, "capsule", Vector3(0, 1.22 * tall, 0), Vector3(0.42, 0.72 * tall, 0.26), shirt)
	_part(root, "box", Vector3(0, 1.2 * tall, -0.1), Vector3(0.38, 0.5 * tall, 0.08), vest)
	_part(root, "box", Vector3(0, 1.5 * tall, -0.13), Vector3(0.12, 0.05, 0.03), suit)
	_part(root, "sphere", Vector3(0, 1.72 * tall, 0), Vector3(0.22, 0.27, 0.23), skin)
	if kind == "louie":
		# pool sticks for arms, a billiard ball for one eye (the page's description)
		if _cue_mat == null:
			_cue_mat = StandardMaterial3D.new()
			_cue_mat.albedo_color = Color(0.72, 0.56, 0.34)
			_cue_mat.roughness = 0.35
		for s in [-1.0, 1.0]:
			var cue := _part(root, "cyl", Vector3(s * 0.3, 1.0, -0.15), Vector3(0.03, 1.3, 0.03), _cue_mat)
			cue.rotation = Vector3(-0.35, 0, s * 0.1)
		var ball := StandardMaterial3D.new()
		ball.albedo_color = Color(0.02, 0.02, 0.02)
		ball.roughness = 0.08
		_part(root, "sphere", Vector3(0.05, 1.75, -0.1), Vector3(0.06, 0.06, 0.06), ball)
		_part(root, "sphere", Vector3(-0.05, 1.75, -0.105), Vector3(0.025, 0.025, 0.02), MatLib.get_mat("l51_staff_suit"))
		_part(root, "cyl", Vector3(0.0, 1.38, -0.55), Vector3(0.36, 0.02, 0.36), MatLib.get_mat("l51_chrome"))
	else:
		for s in [-1.0, 1.0]:
			var arm := _part(root, "capsule", Vector3(s * 0.27, 1.12 * tall, 0), Vector3(0.1, 0.7 * tall, 0.1), suit)
			arm.rotation.z = s * 0.08
		for s in [-1.0, 1.0]:
			_part(root, "sphere", Vector3(s * 0.06, 1.76 * tall, -0.105), Vector3(0.03, 0.02, 0.02), MatLib.get_mat("l51_staff_suit"))
	if kind == "billy":
		var b := StandardMaterial3D.new()
		b.albedo_color = Color(0.85, 0.82, 0.7)
		b.roughness = 0.08
		_part(root, "sphere", Vector3(0, 1.72, 0), Vector3(0.26, 0.26, 0.26), b)
	if kind == "pegleg":
		_part(root, "cyl", Vector3(0, 1.95, 0), Vector3(0.2, 0.18, 0.2), MatLib.get_mat("l51_lacquer_red"))
	return root


func _part(root: Node3D, mesh_type: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m: Mesh
	if mesh_type == "capsule":
		var c := CapsuleMesh.new()
		c.radius = size.x * 0.5
		c.height = size.y
		c.radial_segments = 10
		c.rings = 4
		m = c
	elif mesh_type == "sphere":
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = 12
		s.rings = 6
		m = s
		mi.scale = size
	elif mesh_type == "cyl":
		var cy := CylinderMesh.new()
		cy.top_radius = size.x
		cy.bottom_radius = size.x
		cy.height = size.y
		cy.radial_segments = 8
		m = cy
	else:
		var bx := BoxMesh.new()
		bx.size = size
		m = bx
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


## The back bar: rows of unfamiliar bottles (no Frontrooms brands), instanced.
func _bottles() -> void:
	var cols := [Color(0.45, 0.22, 0.04), Color(0.06, 0.2, 0.08), Color(0.4, 0.03, 0.06), Color(0.75, 0.72, 0.62)]
	var r := RandomNumberGenerator.new()
	r.seed = 5151
	for ci in cols.size():
		var cm := CylinderMesh.new()
		cm.top_radius = 0.025
		cm.bottom_radius = 0.04
		cm.height = 0.3
		cm.radial_segments = 8
		cm.rings = 1
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(cols[ci].r, cols[ci].g, cols[ci].b, 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.metallic_specular = 0.9
		cm.material = m
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = cm
		var xf: Array = []
		for yy in [1.3, 1.8, 2.3]:
			var z := 22.4
			while z < 43.6:
				if r.randi_range(0, 3) == ci:
					var h := r.randf_range(0.8, 1.15)
					xf.append(Transform3D(Basis.from_scale(Vector3(1, h, 1)), Vector3(29.55 + r.randf_range(-0.08, 0.08), MEZ + yy + 0.15 * h, z)))
				z += 0.11
		mm.instance_count = xf.size()
		for i in xf.size():
			mm.set_instance_transform(i, xf[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		dress.add_child(mi)
