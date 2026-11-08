extends LevelBase
## Level 37.1 — "The Sanguine Reservoir" (Backrooms Wikidot rev 19, accessed
## 2026-11-04; cite: VivamusLudio, CC BY-SA 3.0). Dossier: docs/canon/levels/L037_1.md.
##
## DESIGN (read -> plan):
## SOURCE: "structurally an exact copy of Level 37" (fact 2). The procedural
##   chunks therefore reuse Level 37's own cell grammar read-only
##   (levels/L037/L037_cells.gd + L037_kinds.gd): the same tiles, pools,
##   pillar lattices, stair pits, corridors and open basins, so the crossing
##   "can easily go unnoticed" (fact 3). Playable world = finite 32 m
##   ChunkWorld streaming window; the page gives no size (fact 17).
## Authored spine (chunks (0,0) -> (1,0) -> (2,0), walking east):
##   Threshold - an ordinary white Poolrooms hall: dry entry platform, a pillar
##     lattice standing in a two-depth pool, bright wells. Arrival point.
##   Gallery   - a long hall split by a deep channel; colonnades either side,
##     low alcoves. Here the light visibly fails.
##   Reservoir - a 10 m hall around a 6.5 m deep basin with a grand stair
##     descending into it; sprouts crowd the walls; on the floor lie the shapes
##     the recovered recording describes (TESTIMONY); a damaged camera rests
##     in a shallow side basin.
## Stateful mechanic (facts 4-6): `_att` grows with how far you have wandered
##   (and slowly with time). Every native light, the wells, the panels and your
##   flashlight attenuate; the water thickens (slower wading and swimming);
##   once darkness is complete the threshold hall rebuilds as more red rooms
##   ("retracing their steps will be useless") and the red sprouts and the
##   red-tinted water become the only light.
## Sound: faint chorus that grows with darkness and can, after long exposure,
##   be parsed (fact 13); rare slithering and whimpers (RUMORED entity, audio
##   only); Ambassadors (CONFIRMED) streak past overhead and ignore you.
## Exits: none documented (no Entrances and Exits section). See level.json.

const Cells := preload("res://levels/L037/L037_cells.gd")
const Kinds := preload("res://levels/L037/L037_kinds.gd")
const Water := preload("res://levels/L037_1/L037_1_water.gd")
const Dress := preload("res://levels/L037_1/L037_1_dress.gd")
const CS := 32.0
const N := 16
const C := 2.0
const WALK := -0.18
const DRY := 0.35
const SKY_COL := Color(0.93, 0.99, 1.0)
const UW_COL := Color(0.45, 0.92, 1.0)
const RED := Color(0.85, 0.08, 0.045)
const HUB := {Vector2i(0, 0): "threshold", Vector2i(1, 0): "gallery", Vector2i(2, 0): "reservoir"}
const HUB_BORDERS := {"0,0,x": [[6, 3, 4.2]], "1,0,x": [[6, 3, 4.2]]}
const START := Vector3(4.0, DRY, 16.0)
const RES := Vector3(64.0, 0.0, 0.0)        # reservoir chunk origin

var world: ChunkWorld
var qa_fixture := false
var _saved_aa: Array = []
var _arng := RandomNumberGenerator.new()
var _att := 0.0
var _force_att := -1.0
var _maxd := 0.0
var _time_att := 0.0
var _sealed := false
var _apply_t := 0.0
var _fl_base := -1.0
var _msgs := {}
var _chant: AudioStreamPlayer
var _bed: AudioStreamPlayer
var _chant_t := 0.0
var _slither_t := 40.0
var _whimper_t := 75.0
var _amb_t := 90.0
var _amb: Node3D
var _amb_from := Vector3.ZERO
var _amb_to := Vector3.ZERO
var _amb_p := -1.0
var _under_res := 0.0
var _drank := 0
var _listens := 0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	# Same depth-texture workaround as Level 37 (see levels/L037/L037.gd).
	var vp := get_viewport()
	_saved_aa = [vp.msaa_3d, vp.screen_space_aa]
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_arng.seed = hash([level_seed, "l371-runtime"])
	rules["flashlight"] = "allowed"          # foreign light exists, then fades (fact 4)
	rules["reverb_room"] = 0.9
	rules["reverb_wet"] = 0.06
	rules["view_distance"] = 140.0
	indoor_env(Color(0.80, 0.92, 0.95), 0.12, Color(0.62, 0.74, 0.77), 0.0045)
	environment.background_color = Color(0.92, 0.97, 1.0)
	environment.background_energy_multiplier = 2.6
	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 1.1
	sun = DirectionalLight3D.new()
	sun.name = "WellLight"
	sun.rotation_degrees = Vector3(-63.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.99, 0.96)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	_materials()
	Dress.materials()
	lights.setup(20, 0)
	lights.max_distance = 34.0
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", START + Vector3(0, 0.05, 0), -90.0)
	add_arrival("from_L037", START + Vector3(0, 0.05, 0), -90.0)
	world.build_around(START, 2)
	_props()
	_interactions()
	_amb = Dress.ambassador()
	add_child(_amb)
	_bed = sound.bed("water_bed", {"bright": 520.0}, -24.0)
	sound.bed("room_tone", {"cutoff": 130.0, "rumble": 0.2}, -32.0)
	_chant = sound.bed("pad", {"root": 98.0, "chord": [0, 3, 7, 10, 15], "bright": 0.08, "seconds": 11.0}, -70.0)
	add_landmark("Threshold hall (looks like the Poolrooms)", START)
	add_landmark("Gallery where the light fails", Vector3(48, WALK, 16))
	add_landmark("The Sanguine Reservoir", RES + Vector3(16, WALK, 16))
	add_landmark("Reservoir floor", RES + Vector3(20, -6.5, 17))
	add_shot("threshold", START + Vector3(1.0, 1.62, 0.6), Vector3(26.0, 1.2, 12.0), {"prepare": _prep.bind(0.0, START)})
	add_shot("gallery_dimming", Vector3(34.0, WALK + 1.62, 11.0), Vector3(58.0, 0.2, 17.0), {"prepare": _prep.bind(0.55, Vector3(40, 0, 16))})
	add_shot("reservoir", RES + Vector3(3.5, WALK + 1.65, 17.6), RES + Vector3(17.0, -3.8, 14.0), {"prepare": _prep.bind(1.0, RES + Vector3(16, 0, 16))})
	add_shot("reservoir_wide", RES + Vector3(28.4, WALK + 1.65, 3.6), RES + Vector3(12.0, -1.5, 20.0), {"prepare": _prep.bind(1.0, RES + Vector3(16, 0, 16))})
	add_shot("reservoir_floor", RES + Vector3(16.5, -4.4, 23.0), RES + Vector3(20.5, -6.5, 16.5), {"prepare": _prep.bind(1.0, RES + Vector3(16, 0, 16))})
	add_shot("camera_basin", RES + Vector3(26.2, WALK + 0.95, 26.9), RES + Vector3(27.2, -0.42, 28.1), {"prepare": _prep.bind(1.0, RES + Vector3(16, 0, 16))})


func _materials() -> void:
	MatLib.define("l371_tile", {"albedo_a": Color(0.95, 0.965, 0.965), "albedo_b": Color(0.93, 0.95, 0.95),
		"pattern": 1, "pattern_scale": Vector2(0.24, 0.24), "grout_width": 0.008, "grout_color": Color(0.78, 0.80, 0.80),
		"roughness_a": 0.05, "roughness_b": 0.09, "tile_variation": 0.0, "noise_scale": 0.15, "bump_strength": 0.3,
		"caustics": 0.45, "water_y": 0.0}, "pool_tile")
	MatLib.define("l371_tile_ceil", {"albedo_a": Color(0.93, 0.95, 0.95), "albedo_b": Color(0.91, 0.93, 0.93),
		"pattern": 1, "pattern_scale": Vector2(0.24, 0.24), "grout_width": 0.008, "grout_color": Color(0.78, 0.80, 0.80),
		"roughness_a": 0.34, "roughness_b": 0.46, "tile_variation": 0.0, "noise_scale": 0.15, "bump_strength": 0.3}, "pool_tile")
	MatLib.register("l371_water", Water.material())
	MatLib.register("l371_panel", MatLib.standard(Color(1, 1, 1), 1.0, 0.0, SKY_COL, 7.0))
	MatLib.register("l371_panel_uw", MatLib.standard(Color(0.8, 1, 1), 1.0, 0.0, UW_COL, 4.0))


# ------------------------------------------------------------ layout rules

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func kind_of(cx: int, cz: int) -> String:
	var key := Vector2i(cx, cz)
	if HUB.has(key) and not (_sealed and key == Vector2i(0, 0)):
		return HUB[key]
	var h := _h01(cx, cz, 11)
	if h < 0.18:
		return "corridor"
	if h < 0.30:
		return "pit"
	if h < 0.44:
		return "pillars"
	if h < 0.54:
		return "dark"
	if h < 0.68:
		return "open"
	return "hall"


func _axis_of(cx: int, cz: int) -> String:
	return "x" if _h01(cx, cz, 13) < 0.5 else "z"


## Same border rule as Level 37: depends only on the border and both kinds.
func _border(ax: int, az: int, axis: String) -> Array:
	var key := "%d,%d,%s" % [ax, az, axis]
	if HUB_BORDERS.has(key):
		return HUB_BORDERS[key]
	var bx := ax + (1 if axis == "x" else 0)
	var bz := az + (1 if axis == "z" else 0)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "border", axis, ax, az])
	var pc := 3.0 + 0.2 * (r.randi() % 7)
	var out: Array = []
	if (kind_of(ax, az) == "corridor" and _axis_of(ax, az) == axis) or (kind_of(bx, bz) == "corridor" and _axis_of(bx, bz) == axis):
		out.append([7, 2, pc])
	var want := out.size() + (1 if out.size() > 0 else 1 + (1 if r.randf() < 0.45 else 0))
	var tries := 0
	while out.size() < want and tries < 16:
		tries += 1
		var w := 2 + (1 if r.randf() < 0.3 else 0)
		var t0 := 2 + r.randi() % (N - 3 - w)
		var ok := true
		for o in out:
			if t0 <= int(o[0]) + int(o[1]) and int(o[0]) <= t0 + w:
				ok = false
		if ok:
			out.append([t0, w, pc])
	return out


func _openings(g, cx: int, cz: int) -> Array:
	var ops: Array = []
	for side in ["w", "e", "n", "s"]:
		var b: Array
		match side:
			"w":
				b = _border(cx - 1, cz, "x")
			"e":
				b = _border(cx, cz, "x")
			"n":
				b = _border(cx, cz - 1, "z")
			_:
				b = _border(cx, cz, "z")
		for o in b:
			for t in range(int(o[0]), int(o[0]) + int(o[1])):
				for depth in 2:
					var c: Vector2i
					match side:
						"w":
							c = Vector2i(depth, t)
						"e":
							c = Vector2i(N - 1 - depth, t)
						"n":
							c = Vector2i(t, depth)
						_:
							c = Vector2i(t, N - 1 - depth)
					g.setc(c.x, c.y, WALK, float(o[2]), true)
					g.lock_cell(c.x, c.y)
			ops.append({"side": side, "t0": int(o[0]), "w": int(o[1]), "ceil": float(o[2])})
	return ops


# ------------------------------------------------------------ authored hubs

## Threshold: indistinguishable from the Poolrooms. Dry entry platform, a
## pillar lattice standing in a two-depth pool, two bright wells, a high slit.
func _paint_threshold(g) -> void:
	g.rect(1, 1, N - 1, N - 1, WALK, 7.5)
	g.rect(1, 6, 4, 10, DRY, 4.4)
	g.stair(Vector3(8.0, DRY, 16.0), Vector3(1, 0, 0), 7.4, WALK)
	g.reserve(1, 5, 5, 11)
	g.rect(6, 3, 13, 13, -1.5)
	g.rect(8, 6, 11, 10, -2.8)
	var top := Vector3(12.0, WALK, 9.0)
	g.stair(top, Vector3(1, 0, 0), 3.8, -1.5)
	Kinds.reserve_flight(g, top - Vector3(C, 0, 0), Vector3(1, 0, 0), 3.8, Cells.run_for(WALK + 1.5) + C)
	for j in [4, 6, 8, 10, 12]:
		for i in [7, 9, 11]:
			Kinds.pillar(g, i, j, 0.9)
	Kinds.pillar(g, 13, 3, 0.9)
	Kinds.pillar(g, 13, 12, 0.9)
	Kinds.well(g, 7, 4, 12, 5, 7.5, 3.0, 4.4)
	Kinds.well(g, 9, 9, 11, 11, 7.5, 3.0, 4.6)
	g.lights.append({"t": "slit", "p": Vector3(18.0, 5.4, 2.02), "n": Vector3(0, 0, 1), "len": 10.0, "h": 0.7, "e": 2.4})
	g.lights.append({"t": "uw", "p": Vector3(12.02, -0.9, 21.0), "n": Vector3(1, 0, 0), "e": 1.5})
	g.lights.append({"t": "uw", "p": Vector3(25.98, -0.9, 12.0), "n": Vector3(-1, 0, 0), "e": 1.5})
	g.lights.append({"t": "panel", "x": 5.0, "z": 16.0, "y": 4.4, "e": 1.7, "dead": false})


## Gallery: a long hall split by a deep channel; the light fails along it.
func _paint_gallery(g) -> void:
	g.rect(1, 4, N - 1, 12, WALK, 5.2)
	g.rect(3, 7, 13, 9, -2.4)
	g.rect(3, 1, 7, 4, WALK, 3.0)
	g.rect(9, 12, 13, 15, WALK, 3.0)
	for i in range(3, 14, 2):
		Kinds.pillar(g, i, 6, 0.7)
		Kinds.pillar(g, i, 9, 0.7)
	Kinds.well(g, 6, 7, 8, 9, 5.2, 2.5, 3.0)
	for x in [8.0, 14.0, 20.0, 26.0]:
		g.lights.append({"t": "panel", "x": x, "z": 10.0, "y": 5.2, "e": 1.5, "dead": x == 20.0})
		g.lights.append({"t": "panel", "x": x + 3.0, "z": 22.0, "y": 5.2, "e": 1.5, "dead": x == 8.0})
	g.lights.append({"t": "uw", "p": Vector3(10.0, -1.2, 14.02), "n": Vector3(0, 0, 1), "e": 1.6})
	g.lights.append({"t": "uw", "p": Vector3(21.0, -1.2, 17.98), "n": Vector3(0, 0, -1), "e": 1.6})


## The Sanguine Reservoir: 10 m hall, 6.5 m deep basin, a grand stair down
## into it, a far stair out, pillars ringing the rim and rising from the floor,
## and a shallow side basin.
func _paint_reservoir(g) -> void:
	g.rect(1, 1, N - 1, N - 1, WALK, 10.5)
	g.rect(3, 3, 13, 13, -6.5)
	var top := Vector3(6.0, WALK, 16.0)
	g.stair(top, Vector3(1, 0, 0), 5.8, -6.5)
	Kinds.reserve_flight(g, top - Vector3(C, 0, 0), Vector3(1, 0, 0), 5.8, Cells.run_for(WALK + 6.5) + C)
	var top2 := Vector3(26.0, WALK, 9.0)
	g.stair(top2, Vector3(-1, 0, 0), 3.8, -6.5)
	Kinds.reserve_flight(g, top2 + Vector3(C, 0, 0), Vector3(-1, 0, 0), 3.8, Cells.run_for(WALK + 6.5) + C)
	g.rect(12, 13, N - 1, N - 1, -0.42)
	for t in range(2, 14, 2):
		Kinds.pillar(g, t, 1, 1.1)
		Kinds.pillar(g, 1, t, 1.1)
		Kinds.pillar(g, 14, t, 1.1)
	for c in [[8, 5], [11, 7], [9, 11], [5, 11]]:
		Kinds.pillar(g, c[0], c[1], 1.4)
	Kinds.well(g, 9, 8, 11, 10, 10.5, 3.0, 1.4)


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, 371])
	var g = Cells.new()
	var ops := _openings(g, cx, cz)
	var meta := {"kind": kind}
	match kind:
		"threshold":
			_paint_threshold(g)
		"gallery":
			_paint_gallery(g)
		"reservoir":
			_paint_reservoir(g)
		"corridor":
			Kinds.corridor(g, r, ops, _axis_of(cx, cz), meta, false)
		"pit":
			Kinds.pit(g, r, meta)
		"pillars":
			Kinds.pillars(g, r, ops, meta)
		"dark":
			Kinds.dark(g, r, ops, meta)
		"open":
			Kinds.open(g, r, ops, meta)
		_:
			Kinds.hall(g, r, meta)
	var o := Vector3(cx * CS, 0, cz * CS)
	var group := "%d,%d" % [cx, cz]
	var k := GeoKit.new(node, "K")
	g.emit(k, o.x, o.z, "l371_tile", "l371_tile_ceil")
	g.emit_stairs(k, o.x, o.z, "l371_tile")
	g.emit_pillars(k, o.x, o.z, "l371_tile")
	_emit_lights(g, k, o, group)
	var ks := GeoKit.new(node, "Sprouts")
	meta["sprouts"] = _sprouts(g, ks, r, o, group, kind)
	if kind == "reservoir":
		var rf := RandomNumberGenerator.new()
		rf.seed = 3701   # fixed: the authored scene is the same on every seed
		Dress.figures(ks, rf, o + Vector3(20.5, -6.5, 17.0), Vector2(2.6, 5.5), 7)
		Dress.camera(ks, o + Vector3(27.2, -0.42, 28.1), 0.7)
		Dress.sprout_cluster(ks, rf, o + Vector3(28.9, -0.42, 29.6), Vector3(-0.7, 0, -0.7), 5)
		_anchor(o + Vector3(28.2, 0.5, 28.9), RED, 1.2, 4.5, group, "sprout")
	ks.commit()
	k.commit()
	var wv := WaterVolume.new()
	wv.name = "Water"
	node.add_child(wv)
	wv.setup(Vector3(o.x, Cells.BASE, o.z), Vector3(o.x + CS, 0.0, o.z + CS), "l371_water", true)
	wv.tint = _water_tint()
	wv.fog_color = Color(0.25, 0.02, 0.02).lerp(Color(0.05, 0.25, 0.3), 1.0 - _att)
	meta["min_floor"] = g.min_floor()
	meta["boxes"] = k.stats["boxes"]
	return meta


## Native light features (the same kinds Level 37 uses). Every anchor carries
## its base energy and kind so the attenuation can scale it.
func _emit_lights(g, k: GeoKit, o: Vector3, group: String) -> void:
	for L in g.lights:
		var t: String = L["t"]
		if t == "sky":
			var low: float = L["low"]
			var c := o + Vector3((float(L["x0"]) + float(L["x1"])) * 0.5, 0, (float(L["z0"]) + float(L["z1"])) * 0.5)
			_anchor(Vector3(c.x, low - 1.0, c.z), SKY_COL, float(L["e"]) * 1.3, low * 1.5 + 3.0, group, "native")
		elif t == "slit":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			var along := Vector3(-n.z, 0, n.x)
			k.quad(p, n, along * float(L["len"]) * 0.5, Vector3(0, float(L["h"]) * 0.5, 0), "l371_panel", Vector2.ZERO, true)
			_anchor(p + n * 2.2, SKY_COL, float(L["e"]) * 1.2, 13.0, group, "native")
		elif t == "uw":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			k.quad(p, n, Vector3(-n.z, 0, n.x) * 0.32, Vector3(0, 0.2, 0), "l371_panel_uw", Vector2.ZERO, true)
			_anchor(p + n * 0.9, UW_COL, float(L["e"]), 8.5, group, "native")
		elif t == "panel":
			var c := o + Vector3(float(L["x"]), float(L["y"]) - 0.02, float(L["z"]))
			if not L.get("dead", false):
				k.quad(c, Vector3.DOWN, Vector3(0.55, 0, 0), Vector3(0, 0, 0.55), "l371_panel", Vector2.ZERO, true)
			if float(L["e"]) > 0.0:
				_anchor(c + Vector3.DOWN * 0.7, SKY_COL, float(L["e"]), 9.0, group, "native")
		elif t == "tilt":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			k.quad(p, n, L["hu"], L["hv"], "l371_panel", Vector2.ZERO, true)
			_anchor(p + n * 2.5, SKY_COL, float(L["e"]), 18.0, group, "native")


func _anchor(p: Vector3, col: Color, e: float, rng_m: float, group: String, kind: String) -> void:
	var i := lights.add_anchor(p, col, e * _factor(kind), rng_m, 0.0, group)
	lights.anchors[i]["base"] = e
	lights.anchors[i]["k"] = kind


## Red sprouts: pool walls at the water line, pillar feet, wall feet.
func _sprouts(g, k: GeoKit, r: RandomNumberGenerator, o: Vector3, group: String, kind: String) -> int:
	var wants := [14 + r.randi() % 6, 8 + r.randi() % 4, 3]
	match kind:
		"threshold":
			return 0
		"gallery":
			wants = [5, 3, 1]
		"reservoir":
			wants = [26, 12, 9]
		"dark":
			wants = [6, 4, 1]
	var sites: Array = Dress.sprout_sites(g, r)
	var placed := 0
	for pass_i in 3:
		var pool: Array = sites[pass_i]
		var want: int = wants[pass_i]
		for n in mini(want, pool.size()):
			var s: Array = pool.pop_at(r.randi() % pool.size())
			var root: Vector3 = o + s[0]
			Dress.sprout_cluster(k, r, root, s[1], 4 + r.randi() % 4)
			if placed % 3 != 2:
				_anchor(root + (s[1] as Vector3) * 0.5 + Vector3.UP * (0.6 if pass_i < 2 else 1.2), RED, 1.6 if pass_i < 2 else 3.0, 7.5 if pass_i < 2 else 9.5, group, "sprout")
			placed += 1
	return placed


func _props() -> void:
	var holder := Node3D.new()
	holder.name = "Props"
	add_child(holder)
	# Foreign light that died (fact 4): two dropped torches in the gallery.
	Props.place(self, holder, "ph/vintage_flashlight", Vector3(41.5, WALK, 10.4), 35.0)
	Props.place(self, holder, "ph/vintage_flashlight", Vector3(55.2, WALK, 21.6), 160.0)
	# Rumour-seekers who came to drink the water (RUMOR, fact 10).
	Props.place(self, holder, "ph/plastic_bottle_gallon", RES + Vector3(3.6, WALK, 19.2), 20.0)
	Props.place(self, holder, "ph/plastic_bottle_gallon", RES + Vector3(4.3, WALK, 19.7), 75.0)


func _interactions() -> void:
	add_note("l371_camera", "Damaged video camera (TESTIMONY)",
		"Waterlogged, lens cracked, battery long dead.\n\nArchivists recovered one recording from a camera found in these pools by a wanderer known as Suraj C. Two unknown voices talk over it. One calls the place a laboratory and says \"there are people lying at the bottom of that pool\". The other says they are \"only making tests here\" and that subjects \"will come here themselves\". Then the camera drops into the water.\n\nThe last frame is corrupted. Some say a figure with several limbs can be glimpsed in it.\n\n(Transcript paraphrased; testimony, not verified.)",
		RES + Vector3(27.2, -0.38, 28.1), Vector3(0.5, 0.25, 0.5), false)
	add_note("l371_rumours", "Wet page, several hands",
		"What people say about this water, written down by people who came looking for it:\n- soak in it again and again and you grow younger, body and mind\n- drink it and you start seeing what has not happened yet\n- swim in it hurt and you come out whole\nNobody agrees. Nothing here is verified. Everyone who waded in says the same thing: it \"changed them permanently\".",
		RES + Vector3(3.2, WALK + 0.03, 12.6))
	add_note("l371_poem", "Torn verse",
		"A few lines, the ink run pink:\n\"No one told me about the nightmares\"\n...\n\"They promised me paradise\nThis might be it\"\n\n(Verse closing the Level 37.1 page; testimony.)",
		RES + Vector3(29.0, WALK + 0.03, 4.0))
	add_interactable(RES + Vector3(4.6, WALK + 1.2, 22.5), Vector3(1.8, 1.8, 1.8), "Listen to the chanting", _listen)
	add_interactable(RES + Vector3(4.6, WALK + 0.4, 19.5), Vector3(1.4, 0.8, 1.4), "Cup the thick water in your hands", _drink)


func _listen(_p) -> void:
	_listens += 1
	if _chant_t < 25.0:
		Overlay.subtitle("[a faint chorus, far off; no words you can hold]", 4.0)
	elif _chant_t < 70.0:
		Overlay.subtitle("[the chant has shape now... \"...the mother's...\"]", 4.5)
	else:
		Overlay.subtitle("[\"...granted the mother's gift and a place in paradise.\" It wants you under the water.]", 6.0)
		SaveService.record_discovery(stable_id, "chant_parsed", "The chant urges full submersion for 'the mother's gift'.", "TESTIMONY")


func _drink(_p) -> void:
	_drank += 1
	Overlay.subtitle("[it is thick and faintly metallic. You cannot tell if anything has changed.]", 4.5)
	SaveService.record_discovery(stable_id, "drank", "Drank the water. Its rumoured effects are unverified.", "RUMOR")


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	_fl_base = player.flashlight.light_energy
	_apply_phase()


func _exit_tree() -> void:
	if _saved_aa.size() == 2:
		var vp := get_viewport()
		vp.msaa_3d = _saved_aa[0]
		vp.screen_space_aa = _saved_aa[1]


func _factor(kind: String) -> float:
	if kind == "native":
		return 1.0 - smoothstep(0.05, 0.85, _att)
	return 0.1 + 0.9 * smoothstep(0.6, 1.0, _att)


func _water_tint() -> Color:
	return Color(0.10, 0.52, 0.54).lerp(Color(0.55, 0.03, 0.04), smoothstep(0.4, 1.0, _att))


func _apply_phase() -> void:
	var nf := _factor("native")
	var sf := _factor("sprout")
	var blood := smoothstep(0.4, 1.0, _att)
	for a in lights.anchors:
		if a.has("base"):
			a["energy"] = float(a["base"]) * _factor(str(a["k"]))
	(MatLib.get_mat("l371_panel") as StandardMaterial3D).emission_energy_multiplier = 7.0 * nf
	(MatLib.get_mat("l371_panel_uw") as StandardMaterial3D).emission_energy_multiplier = 4.0 * nf
	(MatLib.get_mat("l371_sprout") as StandardMaterial3D).emission_energy_multiplier = 0.3 + 2.4 * sf
	(MatLib.get_mat("l371_sprout_tip") as StandardMaterial3D).emission_energy_multiplier = 0.6 + 4.5 * sf
	(MatLib.get_mat("l371_water") as ShaderMaterial).set_shader_parameter("blood", blood)
	environment.background_energy_multiplier = 2.6 * nf
	environment.background_color = Color(0.92, 0.97, 1.0).lerp(Color(0.02, 0.0, 0.0), _att)
	environment.ambient_light_color = Color(0.80, 0.92, 0.95).lerp(Color(0.55, 0.07, 0.06), _att)
	environment.ambient_light_energy = lerpf(0.12, 0.07, _att)
	environment.fog_light_color = Color(0.62, 0.74, 0.77).lerp(Color(0.07, 0.003, 0.004), _att)
	environment.fog_density = lerpf(0.0045, 0.024, _att)
	sun.light_energy = 1.55 * nf
	sun.visible = nf > 0.01
	var tint := _water_tint()
	for w in get_tree().get_nodes_in_group("water"):
		(w as WaterVolume).tint = tint
		(w as WaterVolume).fog_color = Color(0.05, 0.25, 0.3).lerp(Color(0.25, 0.01, 0.01), blood)
	if player and _fl_base >= 0.0:
		player.flashlight.light_energy = _fl_base * maxf(nf, 0.0)


func _prep(att: float, around: Vector3) -> void:
	_force_att = att
	_att = att
	world.build_around(around, 1)
	_apply_phase()
	await get_tree().process_frame


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	_maxd = maxf(_maxd, Vector2(p.x - START.x, p.z - START.z).length())
	_time_att = minf(1.0, _time_att + delta / 900.0)
	var target := clampf((_maxd - 14.0) / 58.0, 0.0, 1.0)
	target = maxf(target, _time_att)
	if _force_att >= 0.0:
		target = _force_att
	_att = move_toward(_att, maxf(_att, target), delta * 0.08) if _force_att < 0.0 else target
	_apply_t -= delta
	if _apply_t <= 0.0:
		_apply_t = 0.1
		_apply_phase()
	_story_beats(p)
	_viscous(p)
	_audio(delta, p)
	_ambassador(delta, p)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if _msgs.has(key):
		return
	_msgs[key] = true
	Overlay.subtitle(text, secs)


func _story_beats(p: Vector3) -> void:
	if _att > 0.25:
		_say("dim", "[the lights seem weaker than they were]", 3.5)
	if _att > 0.5 and p.y < 0.0:
		_say("thick", "[the water has turned thick; it drags at you, as if not letting go]", 4.5)
	if _att > 0.8:
		_say("torch", "[your own light is failing too]", 3.5)
	if _att >= 0.999 and not _sealed:
		_sealed = true
		_say("dark", "[darkness, complete. Then, along the pool walls, red sprouts glowing]", 5.0)
		SaveService.record_discovery(stable_id, "sealed", "The light died and the way back changed.", "SOURCE")
		var k0 := Vector2i(0, 0)
		if world.chunks.has(k0) and world.key_at(p) != k0:
			world.rebuild(k0, true)
	if Vector2(p.x - (RES.x + 16.0), p.z - 16.0).length() < 15.0:
		_say("res", "[an enormous red-lit basin. Shapes lie still on its floor]", 4.5)


## Viscous water (fact 5): wading and swimming slow as the darkness grows.
func _viscous(p: Vector3) -> void:
	var visc := smoothstep(0.3, 0.85, _att)
	var depth := maxf(0.0, -p.y)
	if player.swimming:
		player.swim_speed = 2.4 * (1.0 - 0.5 * visc)
	else:
		var drag := clampf(1.0 - depth * (0.6 + 0.9 * visc), 0.4, 1.0)
		player.walk_speed = 3.1 * drag
		player.sprint_speed = 5.3 * drag


func _audio(delta: float, p: Vector3) -> void:
	var in_res := Vector2(p.x - (RES.x + 16.0), p.z - 16.0).length() < 16.0
	var chant_db := lerpf(-62.0, -28.0, smoothstep(0.1, 1.0, _att)) + (5.0 if in_res else 0.0)
	_chant.volume_db = lerpf(_chant.volume_db, chant_db, clampf(delta * 0.8, 0.0, 1.0))
	_bed.volume_db = lerpf(-24.0, -30.0, _att)
	if _att > 0.6:
		_chant_t += delta * (1.6 if in_res else 1.0)
	if _chant_t > 70.0:
		_say("parse", "[the distant chant: \"...the mother's gift...\"]", 4.0)
	if player.head_under and in_res:
		_under_res += delta
		if _under_res > 6.0 and _chant_t > 70.0:
			_say("submerged", "[under the surface the chorus is very close. You surface. Nothing you can name has changed.]", 5.5)
	else:
		_under_res = 0.0
	if _att < 0.5:
		return
	_slither_t -= delta
	_whimper_t -= delta
	var away := Vector3(_arng.randf_range(-1, 1), 0, _arng.randf_range(-1, 1)).normalized() * _arng.randf_range(9.0, 15.0)
	if _slither_t <= 0.0:
		_slither_t = _arng.randf_range(55.0, 120.0)
		sound.play_at("scratch", {"seconds": 2.2}, p + away, -14.0, "[something slithers in a dark corner]")
	if _whimper_t <= 0.0:
		_whimper_t = _arng.randf_range(80.0, 160.0)
		sound.play_at("whisper", {"seconds": 1.4}, p + away, -16.0, "[a whimper, from nowhere]")


## Ambassadors (CONFIRMED): hover at high speed across the level, ignoring you.
func _ambassador(delta: float, p: Vector3) -> void:
	if _amb_p >= 0.0:
		_amb_p += delta / 1.4
		_amb.global_position = _amb_from.lerp(_amb_to, _amb_p)
		if _amb_p >= 1.0:
			_amb_p = -1.0
			_amb.visible = false
		return
	if _att < 0.4:
		return
	_amb_t -= delta
	if _amb_t > 0.0:
		return
	_amb_t = _arng.randf_range(70.0, 150.0)
	var kind: String = world.meta_of(world.key_at(p)).get("kind", "")
	if kind in ["corridor", "dark"]:
		_amb_t = 15.0
		return
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var side := Vector3(-fwd.z, 0, fwd.x)
	var mid := p + fwd * _arng.randf_range(10.0, 16.0) + Vector3.UP * _arng.randf_range(3.0, 4.5)
	_amb_from = mid - side * 22.0
	_amb_to = mid + side * 22.0
	_amb.global_position = _amb_from
	_amb.look_at(_amb_to, Vector3.UP)
	_amb.visible = true
	_amb_p = 0.0
	sound.play_at("wind", {"seconds": 1.6}, mid, -10.0, "[something passes overhead at great speed, and is gone]")


## Adds one still of an ordinary procedural hall (a copy of Level 37) in full darkness.
func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	for kind in ["hall", "pillars", "open"]:
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if kind_of(dx, dz) == kind and not plan.any(func(s): return s["name"] == "red_hall"):
					var o := Vector3(dx * CS, 0, dz * CS)
					plan.append({"name": "red_hall", "pos": o + Vector3(3.0, WALK + 1.65, 3.0), "target": o + Vector3(20.0, -0.5, 18.0),
						"prepare": _prep.bind(1.0, o + Vector3(16, 0, 16))})
	return plan


func qa_self_test() -> Array:
	await get_tree().process_frame
	var res_meta := world.meta_of(Vector2i(2, 0))
	var natives := 0
	var sprouts := 0
	for a in lights.anchors:
		if str(a.get("k", "")) == "native":
			natives += 1
		elif str(a.get("k", "")) == "sprout":
			sprouts += 1
	var out: Array = []
	out.append({"what": "no exit invented (page documents none)", "ok": exits.is_empty()})
	out.append({"what": "threshold starts lit (attenuation 0)", "ok": _att < 0.05 and natives > 0, "detail": [_att, natives]})
	out.append({"what": "reservoir chunk built with sprouts", "ok": int(res_meta.get("sprouts", 0)) >= 20, "detail": res_meta.get("sprouts", 0)})
	var before := float(lights.anchors.filter(func(a): return str(a.get("k", "")) == "native").map(func(a): return float(a["energy"])).reduce(func(x, y): return x + y, 0.0))
	_att = 1.0
	_apply_phase()
	var after := float(lights.anchors.filter(func(a): return str(a.get("k", "")) == "native").map(func(a): return float(a["energy"])).reduce(func(x, y): return x + y, 0.0))
	out.append({"what": "full darkness extinguishes native light and lights the sprouts", "ok": after < 0.01 and before > 1.0 and sprouts > 0, "detail": [before, after, sprouts]})
	_att = 0.0
	_apply_phase()
	return out
