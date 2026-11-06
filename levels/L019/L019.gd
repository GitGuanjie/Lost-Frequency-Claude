extends LevelBase
## Level 19 — "Attic Floorboards" (Backrooms Wiki rev 55, accessed 2026-11-04; cite:
## Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L019.md. The final
## revision is the article; earlier drafts are TESTIMONY and only colour the space.
##
## "A complex series of randomly shaped attic spaces": a seeded grid of rooms with
## board knee walls and hipped ceilings (rafters over pink insulation), joined by
## steep gable passages whose ceilings taper to the floor, through empty door frames.
## Floors mix floorboards and insulation. Systems: the Orange Glow under some boards
## (comfort, lure, memory rewriting, amplified decay); decay (nausea, dizziness,
## hallucinations, blackouts; items taken from boxes may rot); rotten non-glowing
## boards that give way. Exits (SOURCE): broken doors (5 / 289 / 12 / 20), falling
## through non-glowing boards or crevices (38 / 202 / 432 / 654), a handheld game in
## a box (40 or 212). No entities, no bases.

const Kit := preload("res://levels/L019/L019_kit.gd")
const NX := 5
const NZ := 5
const S := 10.5
const FALLS := ["L019>L038#1", "L019>L202#2", "L019>L432#3", "L019>L654#4"]
const DOORS := ["L019>L289#5", "L019>L012#7", "L019>L020#8"]
const START := Vector2i(0, 2)

var qa_fixture := false
var hubs: Dictionary = {}       # Vector2i -> room record
var glows: Array = []           # [{p, a}] glowing board patches (anchor index a)
var rotten: Array = []          # [{r: Rect2, node, strain, broken}]
var _k: GeoKit
var _box_n := 0
var _glow := 0.0
var _decay := 0.0
var _bo_t := 40.0
var _bo := 0.0
var _hal_t := 20.0
var _amb_t := 6.0
var _safe := Vector3.ZERO
var _fell := 0.0
var _falls: Array = []
var _tablet: Interactable
var _pad: AudioStreamPlayer
var _creak_cd := 0.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.22
	rules["reverb_wet"] = 0.08
	rules["view_distance"] = 70.0
	var fog := Color(0.05, 0.04, 0.034)
	indoor_env(Color(0.62, 0.50, 0.38), 0.075, fog, 0.05)
	environment.background_color = fog
	environment.tonemap_exposure = 1.15
	environment.glow_intensity = 0.55
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	environment.adjustment_contrast = 1.08
	_materials()
	_layout()
	lights.setup(8, 1)
	lights.max_distance = 26.0
	_k = kit("Attic")
	var st: Dictionary = hubs[START]
	var spawn := Vector3((st["x0"] + st["x1"]) * 0.5 - 1.0, 0.05, (st["z0"] + st["z1"]) * 0.5)
	var arc := Vector3((st["x0"] + st["x1"]) * 0.5 + 0.6, 0.0, st["z1"] - 0.7)
	st["keep"] = [Rect2(spawn.x - 1.2, spawn.z - 1.2, 3.2, 2.4), Rect2(arc.x - 0.7, arc.z - 0.7, 1.4, 1.4)]
	add_arrival("start", spawn, -90.0)
	add_arrival("from_L001", spawn, -90.0)
	add_arrival("from_L025", Vector3((hubs[Vector2i(2, 0)]["x0"] + hubs[Vector2i(2, 0)]["x1"]) * 0.5, 0.05, (hubs[Vector2i(2, 0)]["z0"] + hubs[Vector2i(2, 0)]["z1"]) * 0.5), 0.0)
	_safe = spawn
	# exits first: the QA walker targets the first reachable exit (the Level 5 door)
	_doors()
	for key in hubs.keys():
		_room(hubs[key], key)
	for w in _wings:
		Kit.wing(_k, w)
	_k.commit()
	# the hole you came up through, now boarded shut ("getting out ... that's going to be an issue")
	var pk := kit("Patch")
	pk.box(Vector3(spawn.x + 0.9, -0.021, spawn.z + 0.2), Vector3(1.0, 0.05, 0.8), "l19_newboards", GeoKit.PY, false)
	pk.commit()
	_tablet = add_note("L019_meod_tablet", "Tablet: M.E.O.D. revision archive", Kit.tablet_text(false), arc + Vector3.UP * 0.62, Vector3(0.35, 0.1, 0.3))
	_k = kit("Tablet")
	Kit.box(_k, arc + Vector3.UP * 0.28, Vector3(0.6, 0.56, 0.5), 0.1)
	_k.box(arc + Vector3.UP * 0.575, Vector3(0.24, 0.015, 0.17), "l19_plastic", GeoKit.ALL, false)
	_k.box(arc + Vector3.UP * 0.584, Vector3(0.2, 0.004, 0.13), "l19_screen", GeoKit.PY, false)
	_k.commit()
	sound.bed("room_tone", {"cutoff": 230.0}, -21.0)
	_pad = sound.bed("pad", {"root": 98.0, "chord": [0, 4, 7, 12], "bright": 0.25}, -70.0)
	var shot := [spawn + Vector3(-0.6, 1.57, 0.6), spawn + Vector3(9.0, 1.4, -0.4)]
	for w in _wings:   # look from the arrival room down a tapering gable passage
		if w["ka"] == START or w["kb"] == START:
			var ax := Vector3(1, 0, 0) if w["x"] else Vector3(0, 0, 1)
			var pp: Vector3 = (Vector3(0, 0, 1) if w["x"] else Vector3(1, 0, 0)) * float(w["c"])
			var s0: float = w["s0"] if w["ka"] == START else w["s1"]
			var s1: float = w["s1"] if w["ka"] == START else w["s0"]
			var dir := signf(s1 - s0)
			shot = [ax * (s0 - dir * 1.3) + pp + Vector3.UP * 1.55, ax * (s1 + dir * 2.5) + pp + Vector3.UP * 1.25]
			break
	add_shot("attic", shot[0], shot[1], {"flashlight": true})
	add_shot("door", _door_shot[0], _door_shot[1])
	add_landmark("Arrival: boarded-over hole", spawn)


func _m(n: String, base: String, a: Color, b: Color, x: Dictionary = {}) -> void:
	x["albedo_a"] = a
	x["albedo_b"] = b
	MatLib.define(n, x, base)


func _materials() -> void:
	var dust := {"stain_amount": 0.7, "stain_color": Color(0.36, 0.33, 0.28), "stain_scale": 0.6, "bump_strength": 0.3}
	var fb := {"pattern": 3, "pattern_scale": Vector2(1.6, 0.16), "grout_width": 0.006, "grout_color": Color(0.06, 0.04, 0.03), "roughness_a": 0.8, "roughness_b": 0.95}
	fb.merge(dust)
	_m("l19_floorwood", "wood_floor", Color(0.30, 0.22, 0.15), Color(0.21, 0.15, 0.10), fb.duplicate())
	_m("l19_walls", "wood_floor", Color(0.31, 0.25, 0.18), Color(0.22, 0.17, 0.12), fb.duplicate())
	_m("l19_newboards", "wood_floor", Color(0.52, 0.40, 0.27), Color(0.45, 0.34, 0.22), {"pattern": 3, "pattern_scale": Vector2(1.0, 0.16)})
	fb.merge({"stain_amount": 0.8, "stain_color": Color(0.10, 0.08, 0.06), "wetness": 0.8}, true)
	_m("l19_rotten_wood", "wood_floor", Color(0.22, 0.16, 0.11), Color(0.16, 0.12, 0.08), fb)
	_m("l19_boards", "wood_floor", Color(0.33, 0.24, 0.16), Color(0.26, 0.18, 0.12), {"pattern": 3, "pattern_scale": Vector2(1.4, 0.2), "stain_amount": 0.4})
	_m("l19_rafter", "wood_floor", Color(0.38, 0.27, 0.17), Color(0.30, 0.21, 0.13), {"stain_amount": 0.5, "stain_color": Color(0.5, 0.46, 0.4)})
	_m("l19_trim", "wood_floor", Color(0.48, 0.42, 0.33), Color(0.40, 0.35, 0.27), {"peel_amount": 0.35, "peel_color": Color(0.30, 0.22, 0.14)})
	_m("l19_plush_insul", "plaster", Color(0.86, 0.56, 0.58), Color(0.74, 0.46, 0.49), {"noise_scale": 7.0, "bump_strength": 2.6, "stain_amount": 0.45, "stain_color": Color(0.55, 0.45, 0.40), "stain_scale": 0.5, "roughness_a": 1.0})
	_m("l19_cardboard", "plaster", Color(0.55, 0.42, 0.27), Color(0.46, 0.34, 0.21), {"stain_amount": 0.7, "stain_color": Color(0.36, 0.30, 0.22), "stain_scale": 1.4, "noise_scale": 3.0, "wetness": 0.3})
	_m("l19_tape", "plaster", Color(0.62, 0.52, 0.34), Color(0.58, 0.48, 0.30), {"roughness_a": 0.4})
	_m("l19_clean", "plaster", Color(0.78, 0.72, 0.60), Color(0.74, 0.68, 0.56))
	_m("l19_fabric", "plaster", Color(0.46, 0.50, 0.40), Color(0.40, 0.42, 0.34), {"pattern": 10, "pattern_scale": Vector2(0.22, 0.22), "pattern_color": Color(0.62, 0.42, 0.40), "pattern_strength": 0.5, "stain_amount": 0.6, "stain_color": Color(0.5, 0.46, 0.4)})
	_m("l19_wood", "wood_floor", Color(0.30, 0.18, 0.10), Color(0.24, 0.14, 0.08), {"roughness_a": 0.5, "stain_amount": 0.5, "stain_color": Color(0.45, 0.40, 0.34)})
	_m("l19_metal", "metal", Color(0.35, 0.30, 0.24), Color(0.28, 0.24, 0.19))
	_m("l19_shade", "plaster", Color(0.70, 0.62, 0.48), Color(0.62, 0.54, 0.40))
	_m("l19_door", "wood_floor", Color(0.52, 0.55, 0.47), Color(0.44, 0.47, 0.40), {"peel_amount": 0.5, "peel_color": Color(0.32, 0.22, 0.14), "stain_amount": 0.6, "stain_color": Color(0.30, 0.28, 0.22)})
	_m("l19_book_a", "plaster", Color(0.42, 0.16, 0.12), Color(0.34, 0.12, 0.10))
	_m("l19_book_b", "plaster", Color(0.18, 0.26, 0.34), Color(0.14, 0.20, 0.28))
	_m("l19_book_c", "plaster", Color(0.50, 0.44, 0.30), Color(0.42, 0.36, 0.24))
	_m("l19_plastic", "plaster", Color(0.22, 0.22, 0.24), Color(0.18, 0.18, 0.20), {"roughness_a": 0.4})
	_m("l19_screen", "plaster", Color(0.1, 0.2, 0.1), Color(0.1, 0.2, 0.1), {"emission_color": Color(0.5, 0.95, 0.4), "emission_energy": 0.5})
	_m("l19_glow", "plaster", Color(1, 0.6, 0.3), Color(1, 0.5, 0.2), {"emission_color": Color(1.0, 0.36, 0.06), "emission_energy": 1.7, "bump_strength": 0.0})
	MatLib.define("l19_void", {}, "void_black")
	var web := StandardMaterial3D.new()
	web.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web.albedo_color = Color(0.78, 0.76, 0.72, 0.22)
	web.cull_mode = BaseMaterial3D.CULL_DISABLED
	web.roughness = 1.0
	MatLib.register("l19_web", web)


# ----------------------------------------------------------------- layout

var _wings: Array = []
var _door_shot := [Vector3.ZERO, Vector3.ONE]
var _hh_key := Vector2i(-1, -1)
var _hh_edge := ""


## Rooms on a jittered grid; a randomised spanning tree (plus a few loops) of gable
## passages joins them, so every room is reachable.
func _layout() -> void:
	for j in NZ:
		for i in NX:
			var c := Vector2(i * S + rng.randf_range(-0.6, 0.6), j * S + rng.randf_range(-0.6, 0.6))
			var sx := rng.randf_range(4.8, 6.6)
			var sz := rng.randf_range(4.8, 6.6)
			hubs[Vector2i(i, j)] = {"x0": c.x - sx * 0.5, "x1": c.x + sx * 0.5, "z0": c.y - sz * 0.5, "z1": c.y + sz * 0.5,
				"kw": rng.randf_range(2.1, 2.3), "pk": rng.randf_range(3.3, 3.9), "m": rng.randf_range(1.3, 1.8),
				"ops": {"n": [], "s": [], "e": [], "w": []}, "holes": [], "free": ["n", "s", "e", "w"], "kind": ["store", "parlour", "library", "store", "plain"][rng.randi() % 5]}
	var edges: Array = []
	for j in NZ:
		for i in NX:
			if i < NX - 1:
				edges.append([Vector2i(i, j), Vector2i(i + 1, j)])
			if j < NZ - 1:
				edges.append([Vector2i(i, j), Vector2i(i, j + 1)])
	for i in range(edges.size() - 1, 0, -1):
		var q := rng.randi() % (i + 1)
		var tmp = edges[i]
		edges[i] = edges[q]
		edges[q] = tmp
	var parent := {}
	for key in hubs.keys():
		parent[key] = key
	for e in edges:
		var ra: Vector2i = _find(parent, e[0])
		var rb: Vector2i = _find(parent, e[1])
		if ra != rb or rng.randf() < 0.14:
			parent[ra] = rb
			_link(e[0], e[1])


func _find(parent: Dictionary, x: Vector2i) -> Vector2i:
	while parent[x] != x:
		x = parent[x]
	return x


func _link(ka: Vector2i, kb: Vector2i) -> void:
	var a: Dictionary = hubs[ka]
	var b: Dictionary = hubs[kb]
	var along_x := kb.x != ka.x
	var lo: float = maxf(a["z0"], b["z0"]) if along_x else maxf(a["x0"], b["x0"])
	var hi: float = minf(a["z1"], b["z1"]) if along_x else minf(a["x1"], b["x1"])
	var w := minf(rng.randf_range(3.6, 4.3), hi - lo - 0.6)
	var c := clampf((lo + hi) * 0.5 + rng.randf_range(-0.5, 0.5), lo + w * 0.5 + 0.3, hi - w * 0.5 - 0.3)
	var s0: float = a["x1"] if along_x else a["z1"]
	var s1: float = b["x0"] if along_x else b["z0"]
	_wings.append({"x": along_x, "s0": s0, "s1": s1, "c": c, "w": w, "rh": rng.randf_range(2.9, 3.3), "kwa": a["kw"], "kwb": b["kw"], "ka": ka, "kb": kb})
	a["ops"]["e" if along_x else "s"].append(c)
	b["ops"]["w" if along_x else "n"].append(c)
	a["free"].erase("e" if along_x else "s")
	b["free"].erase("w" if along_x else "n")


## Broken or damaged doors on dead-end walls: the Level 5 door is authored two rooms
## from the arrival; the others are seeded.
func _doors() -> void:
	var order: Array = [Vector2i(2, 2), Vector2i(2, 1), Vector2i(2, 3), Vector2i(1, 1), Vector2i(1, 3), Vector2i(3, 2), Vector2i(1, 2)]
	var picked := Vector2i(-1, -1)
	var side := ""
	for key in order:
		var h: Dictionary = hubs[key]
		for s in ["n", "s", "e", "w"]:
			if s in h["free"]:
				picked = key
				side = s
				break
		if side != "":
			break
	if side != "":
		_broken_door(picked, side, "L019>L005#6", true)
	var keys := hubs.keys()
	for i in range(keys.size()):
		var key: Vector2i = keys[(i * 11 + absi(level_seed) % 7) % keys.size()]
		if key != START and key != picked:
			_hh_key = key
			break
	_hh_edge = "L019>L040#9" if absi(level_seed) % 2 == 0 else "L019>L212#10"
	var d := 0
	for i in range(keys.size()):
		var key: Vector2i = keys[(i * 7 + absi(level_seed) % 25) % keys.size()]
		if key == START or key == picked or d >= DOORS.size():
			continue
		var h: Dictionary = hubs[key]
		if not h["free"].is_empty() and rng.randf() < 0.5:
			_broken_door(key, h["free"][rng.randi() % h["free"].size()], DOORS[d], false)
			d += 1


func _broken_door(key: Vector2i, side: String, edge: String, main: bool) -> void:
	var h: Dictionary = hubs[key]
	h["free"].erase(side)
	var c := _side_mid(h, side)
	h["ops"][side].append(c.x if side in ["n", "s"] else c.z)
	h["broken"] = [side, c, edge]
	var out := _out(side)
	var t := make_exit(edge, "walk_in", c + out * 0.55 + Vector3.UP * 1.0, Vector3(1.0, 2.0, 1.0) if side in ["e", "w"] else Vector3(1.0, 2.0, 1.0), "", self)
	if main:
		_door_shot = [c - out * 4.2 + Vector3.UP * 1.5 + _along(side) * 1.1, c + Vector3.UP * 0.95]
		glows.append({"p": c - out * 1.9 + _along(side) * 0.9, "a": -1})   # the glow lies close by
	if t:
		h["door_trig"] = t


func _side_mid(h: Dictionary, side: String) -> Vector3:
	var cx: float = (h["x0"] + h["x1"]) * 0.5
	var cz: float = (h["z0"] + h["z1"]) * 0.5
	match side:
		"n": return Vector3(cx, 0, h["z0"])
		"s": return Vector3(cx, 0, h["z1"])
		"w": return Vector3(h["x0"], 0, cz)
	return Vector3(h["x1"], 0, cz)


func _out(side: String) -> Vector3:
	return {"n": Vector3(0, 0, -1), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0), "e": Vector3(1, 0, 0)}[side]


func _along(side: String) -> Vector3:
	return Vector3(1, 0, 0) if side in ["n", "s"] else Vector3(0, 0, 1)


# ------------------------------------------------------------------ rooms

func _room(h: Dictionary, key: Vector2i) -> void:
	var x0: float = h["x0"]
	var x1: float = h["x1"]
	var z0: float = h["z0"]
	var z1: float = h["z1"]
	var kw: float = h["kw"]
	var m: float = h["m"]
	var rise: float = h["pk"] - kw
	var c := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, key, "room"])
	# floor patches: glowing boards, rotten boards / crevices, insulation between joists
	var corners: Array = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for i in range(3, 0, -1):
		var q := r.randi() % (i + 1)
		var tmp = corners[i]
		corners[i] = corners[q]
		corners[q] = tmp
	var spot := func(cn: Vector2, w: float, d: float) -> Rect2:
		var p := Vector2(c.x + cn.x * ((x1 - x0) * 0.5 - 1.2), c.z + cn.y * ((z1 - z0) * 0.5 - 1.2))
		return Rect2(p.x - w * 0.5, p.y - d * 0.5, w, d)
	var glow_here := key == START + Vector2i(1, 0) or (key != START and r.randf() < 0.35)
	for g in glows:
		if g["a"] == -1 and Rect2(x0, z0, x1 - x0, z1 - z0).has_point(Vector2(g["p"].x, g["p"].z)):
			h["holes"].append({"r": Rect2(g["p"].x - 0.55, g["p"].z - 0.9, 1.1, 1.8), "t": "glow"})
			glow_here = false
	if glow_here:
		h["holes"].append({"r": spot.call(corners[0], 1.1, 1.8) if key != START + Vector2i(1, 0) else Rect2(x0 + 1.0, c.z - 0.9, 1.1, 1.8), "t": "glow"})
	if key != START and r.randf() < 0.45:
		h["holes"].append({"r": spot.call(corners[1], 0.9, 1.4), "t": "rotten" if r.randf() < 0.65 else "crevice"})
	if r.randf() < 0.4:
		h["holes"].append({"r": spot.call(corners[2], 1.6, 1.6), "t": "insul"})
	Kit.floor_holes(_k, Rect2(x0, z0, x1 - x0, z1 - z0), h["holes"], "l19_floorwood")
	for hh in h["holes"]:
		_patch(hh["r"], hh["t"], r)
	# board knee walls with empty door frames
	for side in ["n", "s", "w", "e"]:
		var a := Vector3(x0, 0, z0) if side in ["n", "w"] else (Vector3(x0, 0, z1) if side == "s" else Vector3(x1, 0, z0))
		var b := Vector3(x1, 0, z0) if side == "n" else (Vector3(x1, 0, z1) if side == "s" else (Vector3(x0, 0, z1) if side == "w" else Vector3(x1, 0, z1)))
		var ops: Array = []
		for p in h["ops"][side]:
			var at: float = p - (a.x if side in ["n", "s"] else a.z)
			ops.append({"at": at, "w": 1.05, "h": 1.95})
			var fc := a + _along(side) * at
			if h.get("broken", []).size() > 0 and h["broken"][0] == side:
				Kit.broken_door(_k, fc, _along(side), _out(side))
			else:
				Kit.frame(_k, fc, _along(side), 1.05, 1.95)
		_k.wall(a, b, kw, 0.12, "l19_walls", ops, GeoKit.ALL)
	# hipped ceiling: four slopes up to a flat collar, rafters over pink insulation
	for sl in [[Vector3(x0 - 0.2, kw, z0), Vector3(x1 + 0.2, kw, z0), Vector3(0, 0, 1)], [Vector3(x0 - 0.2, kw, z1), Vector3(x1 + 0.2, kw, z1), Vector3(0, 0, -1)],
			[Vector3(x0, kw, z0 - 0.2), Vector3(x0, kw, z1 + 0.2), Vector3(1, 0, 0)], [Vector3(x1, kw, z0 - 0.2), Vector3(x1, kw, z1 + 0.2), Vector3(-1, 0, 0)]]:
		Kit.slope(_k, sl[0], sl[1], sl[2], rise, m, "l19_plush_insul")
	for cn in [[x0, z0, 1.0, 1.0], [x1, z1, -1.0, -1.0], [x0, z1, 1.0, -1.0], [x1, z0, -1.0, 1.0]]:   # cobwebs in the corners
		if r.randf() < 0.6:
			var cp := Vector3(cn[0] + 0.07 * cn[2], kw - 0.03, cn[1] + 0.07 * cn[3])
			Kit.web(_k, cp, cp + Vector3(0.8 * cn[2], -0.55, 0.0), cp + Vector3(0.0, -0.6, 0.75 * cn[3]))
	_k.slab(x0 + m - 0.05, z0 + m - 0.05, x1 - m + 0.05, z1 - m + 0.05, h["pk"] + 0.06, 0.06, "l19_boards", GeoKit.NY)
	_clutter(h, key, r)


func _patch(rc: Rect2, t: String, r: RandomNumberGenerator) -> void:
	var c := Vector3(rc.get_center().x, 0, rc.get_center().y)
	match t:
		"glow":   # a warm, fire-like glow shining up between the boards
			_k.box(c + Vector3.DOWN * 0.15, Vector3(rc.size.x, 0.02, rc.size.y), "l19_glow", GeoKit.PY, false)
			_k.box(c, Vector3(rc.size.x, 0.02, rc.size.y), "l19_floorwood", 0, true)
			var x := rc.position.x + 0.07
			while x < rc.end.x - 0.05:
				_k.box(Vector3(x, -0.03, c.z), Vector3(0.115, 0.06, rc.size.y), "l19_floorwood", GeoKit.PY | GeoKit.PX | GeoKit.NX, false)
				x += 0.15
			var a := lights.add_anchor(c + Vector3.UP * 0.35, Color(1.0, 0.48, 0.14), 1.15, 5.5, 0.0, "")
			var found := false
			for g in glows:
				if g["a"] == -1 and Rect2(rc).has_point(Vector2(g["p"].x, g["p"].z)):
					g["a"] = a
					g["p"] = c
					found = true
			if not found:
				glows.append({"p": c, "a": a})
		"rotten", "crevice":   # non-glowing boards or crevices you can fall through
			for sd in [[Vector3(rc.position.x, -5.0, rc.position.y), Vector3(rc.end.x, 0.0, rc.position.y + 0.05)], [Vector3(rc.position.x, -5.0, rc.end.y - 0.05), Vector3(rc.end.x, 0.0, rc.end.y)],
					[Vector3(rc.position.x, -5.0, rc.position.y), Vector3(rc.position.x + 0.05, 0.0, rc.end.y)], [Vector3(rc.end.x - 0.05, -5.0, rc.position.y), Vector3(rc.end.x, 0.0, rc.end.y)]]:
				_k.box_mm(sd[0], sd[1], "l19_void")
			_k.box_mm(Vector3(rc.position.x, -5.2, rc.position.y), Vector3(rc.end.x, -5.0, rc.end.y), "l19_void")
			for jx in [rc.position.x + 0.03, rc.end.x - 0.03]:
				_k.box(Vector3(jx, -0.07, c.z), Vector3(0.06, 0.14, rc.size.y), "l19_rafter", GeoKit.ALL, false)
			var edge: String = FALLS[(rotten.size() + absi(level_seed)) % FALLS.size()]
			var tr := make_exit(edge, "fall", c + Vector3.DOWN * 1.6, Vector3(rc.size.x + 0.3, 3.0, rc.size.y + 0.3), "", self)
			if tr:
				tr.fall_y = -0.9
				tr.fired.connect(_on_fall.bind(tr))
				_falls.append(tr)
			var rec := {"r": rc, "node": null, "strain": 0.0, "broken": t == "crevice"}
			if t == "rotten":
				var n := Node3D.new()
				add_child(n)
				var bk := GeoKit.new(n, "Rotten")
				var x := rc.position.x + 0.08
				while x < rc.end.x - 0.05:
					bk.box(Vector3(x, -0.03, c.z + r.randf_range(-0.04, 0.04)), Vector3(0.14, 0.06, rc.size.y - 0.02), "l19_rotten_wood", GeoKit.PY | GeoKit.PX | GeoKit.NX, false)
					x += 0.155
				bk.box(c + Vector3.DOWN * 0.03, Vector3(rc.size.x, 0.06, rc.size.y), "l19_rotten_wood", 0, true)
				bk.commit()
				rec["node"] = n
			rotten.append(rec)
		"insul":   # "a mix of pink insulation material and floorboards"
			_k.box(c + Vector3.DOWN * 0.09, Vector3(rc.size.x, 0.06, rc.size.y), "l19_plush_insul", GeoKit.PY, true)
			var x := rc.position.x + 0.2
			while x < rc.end.x:
				_k.box(Vector3(x, -0.03, c.z), Vector3(0.05, 0.06, rc.size.y), "l19_rafter", GeoKit.PY | GeoKit.PX | GeoKit.NX, false)
				x += 0.4


func _blocked(h: Dictionary, p: Vector3, rad: float) -> bool:
	for kr in h.get("keep", []):
		if (kr as Rect2).grow(rad).has_point(Vector2(p.x, p.z)):
			return true
	for hh in h["holes"]:
		if (hh["r"] as Rect2).grow(rad).has_point(Vector2(p.x, p.z)):
			return true
	for side in ["n", "s", "w", "e"]:
		for o in h["ops"][side]:
			var dp := Vector3(o, 0, h["z0"] if side == "n" else h["z1"]) if side in ["n", "s"] else Vector3(h["x0"] if side == "w" else h["x1"], 0, o)
			if Vector2(p.x - dp.x, p.z - dp.z).length() < 1.5 + rad:
				return true
	return false


## "Packed with a heavy clutter of boxes, vintage furniture, and other items."
func _clutter(h: Dictionary, key: Vector2i, r: RandomNumberGenerator) -> void:
	var opened := 0
	for side in ["n", "s", "w", "e"]:
		var a := _side_mid(h, side)
		var al := _along(side)
		var inw := -_out(side)
		var half: float = ((h["x1"] - h["x0"]) if side in ["n", "s"] else (h["z1"] - h["z0"])) * 0.5 - 0.5
		var s := -half
		var yaw := atan2(inw.x, inw.z) + PI
		while s < half - 0.4:
			var p := a + al * s
			var pick := r.randf()
			var size := r.randf_range(0.5, 0.9)
			if pick < 0.5 and not _blocked(h, p + inw * 0.4, 0.4):
				var bs := Vector3(r.randf_range(0.45, 0.75), r.randf_range(0.35, 0.6), r.randf_range(0.4, 0.6))
				var bp := p + inw * (bs.z * 0.5 + 0.08)
				if opened < 2 and key != START:
					_open_box(bp, bs, yaw + r.randf_range(-0.2, 0.2))
					opened += 1
				else:
					Kit.box(_k, bp + Vector3.UP * bs.y * 0.5, bs, yaw + r.randf_range(-0.3, 0.3))
					if r.randf() < 0.6:
						Kit.box(_k, bp + Vector3.UP * (bs.y + 0.2), Vector3(0.5, 0.4, 0.45), yaw + r.randf_range(-0.5, 0.5))
				size = bs.x + 0.1
			elif pick < 0.62 and h["kind"] == "library" and not _blocked(h, p + inw * 0.25, 0.6):
				Kit.bookcase(_k, p + inw * 0.24, yaw, r)
				size = 1.1
			elif pick < 0.72 and half > 1.6 and h["kind"] == "parlour" and not _blocked(h, p + al * 0.9 + inw * 0.5, 1.1):
				Kit.sofa(_k, p + al * 0.95 + inw * 0.52, yaw)
				size = 2.0
			elif pick < 0.8 and not _blocked(h, p + inw * 0.3, 0.5):
				Kit.trunk(_k, p + inw * 0.3, yaw)
				size = 1.0
			s += size
	var c := Vector3((h["x0"] + h["x1"]) * 0.5, 0, (h["z0"] + h["z1"]) * 0.5)
	if h["kind"] == "parlour" and not _blocked(h, c, 0.9):
		Kit.table(_k, c + Vector3(0.3, 0, 0.2), r.randf() * 0.5, 1.1, 0.7, 0.72)
		Kit.ottoman(_k, c + Vector3(-0.8, 0, -0.5), 0.2)
		Kit.lamp(_k, c + Vector3(1.2, 0, -0.9))
	for i in 2 + r.randi() % 2:   # free-standing piles: "a heavy clutter of boxes"
		var p := c + Vector3(r.randf_range(-1, 1) * ((h["x1"] - h["x0"]) * 0.5 - 1.0), 0, r.randf_range(-1, 1) * ((h["z1"] - h["z0"]) * 0.5 - 1.0))
		if Vector2(p.x - c.x, p.z - c.z).length() > 1.3 and not _blocked(h, p, 0.6):
			var y := 0.0
			for q in 1 + r.randi() % 3:
				var bs := Vector3(r.randf_range(0.45, 0.8), r.randf_range(0.3, 0.55), r.randf_range(0.4, 0.7))
				Kit.box(_k, p + Vector3(r.randf_range(-0.08, 0.08), y + bs.y * 0.5, r.randf_range(-0.08, 0.08)), bs, r.randf() * TAU)
				y += bs.y
	if key == _hh_key:   # "handheld games or small arcade devices within the boxes"
		for cn in [Vector2(-1, -1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1)]:
			var p := c + Vector3(cn.x * ((h["x1"] - h["x0"]) * 0.5 - 0.9), 0, cn.y * ((h["z1"] - h["z0"]) * 0.5 - 0.9))
			if not _blocked(h, p, 0.5):
				Kit.handheld(_k, p, r.randf() * TAU)
				make_exit(_hh_edge, "interact", p + Vector3.UP * 0.35, Vector3(0.8, 0.8, 0.8), "Switch on the handheld game lying in the box", self)
				break


func _open_box(p: Vector3, s: Vector3, yaw: float) -> void:
	_box_n += 1
	var id := "b%d" % _box_n
	var n := Node3D.new()
	add_child(n)
	var bk := GeoKit.new(n, "Box")
	Kit.box(bk, p + Vector3.UP * s.y * 0.5, s, yaw)
	bk.commit()
	var it := add_interactable(p + Vector3.UP * s.y * 0.5, s + Vector3(0.06, 0.06, 0.06), "Open the box", Callable())
	it.rotation.y = yaw
	it.once = true
	it.action = _take.bind(id, n, p, s, yaw)


## Boxes hold "vital foods and ... cataloged, anomalous objects"; once removed, an
## item may "decay at a rapid rate" (and the decay reaches the one holding it).
func _take(pl: Player, id: String, n: Node3D, p: Vector3, s: Vector3, yaw: float) -> void:
	for ch in n.get_children():
		ch.queue_free()
	var bk := GeoKit.new(n, "Open")
	Kit.box(bk, p + Vector3.UP * s.y * 0.5, s, yaw, true)
	bk.commit()
	var cr := RandomNumberGenerator.new()
	cr.seed = hash([level_seed, id])
	var item: String = ["an open can of tuna", "a sealed bottle of water", "cooked gammon on a plate, still warm", "a small catalogued object on an old paper tag", "tins of food in perfect condition"][cr.randi() % 5]
	if cr.randf() < 0.45:
		_decay = minf(1.0, _decay + 0.08)
		Overlay.toast("Inside, pristine: %s. As you lift it out it greys, softens and rots in your hands." % item, 5.0)
		Overlay.subtitle("[your stomach turns]", 2.5)
	else:
		SaveService.add_item("l19_supplies")
		pl.heal(15.0)
		Overlay.toast("Inside, pristine despite the damp outside: %s." % item, 4.0)


# ---------------------------------------------------------------- runtime

func on_player_ready() -> void:
	if SessionState.is_story():
		Overlay.subtitle("[old boards creak shut beneath you] [dust]", 4.0)
		if TransitionService.pending_arrival == "from_L001" or not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
	if qa_fixture:
		qa_routes.append({"edge": "L019>L005#6", "note": "authored broken door two rooms from the arrival"})


func level_process(delta: float) -> void:
	if player == null or player.dead:
		return
	var pos := player.global_position
	var cam := player.camera
	var fwd := -cam.global_transform.basis.z
	var near := Vector3.INF
	var nd := 1e9
	var t := Time.get_ticks_msec() * 0.001
	for g in glows:
		var gp: Vector3 = g["p"]
		var d := Vector2(gp.x - pos.x, gp.z - pos.z).length()
		if d < nd:
			nd = d
			near = gp
		if int(g["a"]) >= 0:   # fire-like breathing of the glow
			lights.anchors[g["a"]]["energy"] = 1.05 + 0.25 * sin(t * 1.3 + gp.x) + 0.12 * sin(t * 3.7 + gp.z)
	# Orange Glow: comfort and lure; it rewrites what you remember; it feeds the decay
	var gain := 0.0
	if nd < 4.5:
		gain += (1.0 - nd / 4.5) * 0.09
	if near != Vector3.INF and nd < 11.0 and fwd.dot((near - cam.global_position).normalized()) > 0.9:
		gain += 0.03
	_glow = clampf(_glow + (gain if gain > 0.0 else -0.012) * delta, 0.0, 1.0)
	if _glow > 0.3 and nd > 0.7 and nd < 9.0 and not qa_fixture:
		var to := near - pos
		to.y = 0.0
		player.move_and_collide(to.normalized() * (_glow - 0.3) * 0.55 * delta)
	if _glow > 0.55 and _tablet and not SaveService.flag(stable_id, "memory_rewritten", false):
		SaveService.set_flag(stable_id, "memory_rewritten", true)
		_tablet.note_text = Kit.tablet_text(true)
		Overlay.toast("You remember the hole you climbed through glowing orange, warm as a hearth. It was dark. Wasn't it?", 6.0)
	_decay = clampf(_decay + delta * 0.0018 * (1.0 + 2.5 * _glow), 0.0, 1.0)
	var dz := maxf(0.0, _decay - 0.2)
	player.head.rotation.z = sin(t * 0.7) * 0.06 * dz
	_hal_t -= delta
	var flash := 0.0
	if _decay > 0.5 and _hal_t <= 0.0:   # hallucinations: colours, phantom sounds
		_hal_t = rng.randf_range(12.0, 30.0)
		sound.play_at(["knock", "creak", "whisper"][randi() % 3], {"hits": 2, "freq": 120.0}, pos + Vector3(randf_range(-6, 6), 1.0, randf_range(-6, 6)), -10.0, "[a sound that may not be there]")
	if _decay > 0.5:
		flash = maxf(0.0, sin(t * 2.3) * sin(t * 0.37)) * (_decay - 0.5)
	_bo_t -= delta
	if _decay > 0.7 and _bo_t <= 0.0 and not qa_fixture:   # periods of blacking out
		_bo_t = rng.randf_range(30.0, 60.0)
		_bo = 2.6
		if near != Vector3.INF and nd > 1.5:
			var to2 := near - pos
			to2.y = 0.0
			player.move_and_collide(to2.normalized() * 1.5)
		Overlay.subtitle("[you come to on the floorboards]", 3.0)
	_bo = maxf(0.0, _bo - delta)
	Overlay.set_screen_effect("blackout", clampf(_bo, 0.0, 1.0))
	Overlay.set_screen_effect("desaturate", clampf(0.3 * _decay - 0.25 * _glow, 0.0, 0.5))
	Overlay.set_screen_effect("red_tint", clampf(0.14 * _glow + flash * 0.5, 0.0, 0.4))
	_pad.volume_db = lerpf(_pad.volume_db, lerpf(-60.0, -14.0, _glow) if nd < 12.0 else -70.0, clampf(delta * 1.5, 0.0, 1.0))
	if _glow > 0.45 and rng.randf() < delta * 0.06:
		sound.play_at("whisper", {}, near + Vector3.DOWN * 0.3, -14.0, "[warm, happy voices beneath the floor]")
	_boards(delta, pos)
	_amb_t -= delta
	if _amb_t <= 0.0:
		_amb_t = rng.randf_range(7.0, 18.0)
		sound.play_at("creak", {"freq": randf_range(80.0, 160.0)}, pos + Vector3(randf_range(-9, 9), 0.2, randf_range(-9, 9)), -12.0, "[floorboards creak somewhere]")


## Rotten, non-glowing boards give way under a standing (or running) weight.
func _boards(delta: float, pos: Vector3) -> void:
	_creak_cd -= delta
	var on_floor := player.is_on_floor() and pos.y > -0.2
	var on_rot := false
	for b in rotten:
		if b["broken"] or not (b["r"] as Rect2).grow(0.15).has_point(Vector2(pos.x, pos.z)):
			continue
		if on_floor:
			on_rot = true
			b["strain"] += delta * (2.2 if player.velocity.length() > 4.0 else 1.0)
			if _creak_cd <= 0.0:
				_creak_cd = 1.6
				sound.play_at("creak", {"freq": 70.0}, pos, -4.0, "[the boards groan under your weight]")
			if b["strain"] > 1.4 and not qa_fixture:
				b["broken"] = true
				(b["node"] as Node3D).queue_free()
				sound.play_at("crackle", {}, pos, -2.0, "[rotten wood splinters]")
	for b in rotten:
		if not b["broken"]:
			b["strain"] = maxf(0.0, b["strain"] - delta * 0.5)
	if on_floor and not on_rot:
		_safe = pos
	# release boundary: a fall whose destination is not built returns you to the boards
	if pos.y < -2.6 and not TransitionService.loading:
		_fell += delta
		if _fell > 1.2:
			_fell = 0.0
			player.global_position = _safe + Vector3.UP * 0.1
			player.velocity = Vector3.ZERO
			for tr in _falls:
				if is_instance_valid(tr):
					tr.enabled = true
	else:
		_fell = 0.0


func _on_fall(_edge: String, tr: ExitTrigger) -> void:
	tr.enabled = false
