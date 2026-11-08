extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Level 1 — "Habitable Zone" (Backrooms Wiki rev 83, accessed 2026-11-04; cite:
## Praetor3005 and DivineAtlas, CC BY-SA 3.0). Dossier: docs/canon/levels/L001.md.
##
## Halls: 32 m chunks on an 8 m structural bay grid ("an endless chimera between an
## underground parking lot and an abandoned warehouse"): huge pillars, ceiling pipes
## leaking onto the floor, crates, bland discoloured walls. Sectors (Aquila, Gild,
## Gothic) vary pillars, light and crates. Corridor blocks behind pushable doors with
## green EXIT lights are Euclidean, dim and safe (L001_kit.gd). Runtime systems
## (Flickering, Smilers, crates, non-Euclidean folds, rest) live in L001_sys.gd.
## Exits (SOURCE): ceiling holes -> 19, pipes-and-dials smooth threshold -> 2,
## open ventilation duct -> 800.

const Kit := preload("res://levels/L001/L001_kit.gd")
const Sys := preload("res://levels/L001/L001_sys.gd")
const CS := 32.0
const BAY := 8.0
const HH := 4.6
const SPAWN := Vector3(12.0, 0.05, 10.0)
const BLOCK := Rect2(0.0, 40.0, 32.0, 16.0)     # authored corridor block (Base Alpha outskirts)
const START_CRATE := Vector3(13.6, 0.0, 15.6)
const MEZZANINE_CHUNK := Vector2i(1, 0)   # authored exploration annex, not a new canonical exit

var world: ChunkWorld
var signs: LightPool
var sys: Node
var qa_fixture := false
var fog_color := Color(0.11, 0.125, 0.13)
var _udir := Vector2i(1, 0)
var _holes: Dictionary = {}
var _guarded: Array = []
var _valve_states: Dictionary = {}
var _gallery_circuit_on := false  # optional rechargeable service lighting


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.28
	rules["view_distance"] = 150.0
	indoor_env(Color(0.55, 0.63, 0.68), 0.07, fog_color, 0.03)
	environment.background_color = fog_color
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.3
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.78
	environment.adjustment_contrast = 1.1
	_materials()
	_udir = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)][absi(hash([level_seed, "util"])) % 3]
	if not qa_fixture:
		var hr := RandomNumberGenerator.new()
		hr.seed = hash([level_seed, "holes"])
		while _holes.size() < 15:   # "a further 15 have been found" (Level 19 page)
			var key := Vector2i(hr.randi_range(-10, 10), hr.randi_range(-10, 10))
			if maxi(absi(key.x), absi(key.y)) >= 3 and key.x * _udir.x + key.y * _udir.y < 7:
				_holes[key] = true
	sys = Sys.new()
	sys.name = "Systems"
	add_child(sys)
	sys.setup(self)
	if SaveService.flag(stable_id, "start_crate_open", false):
		sys.cstate["start"] = "open"
	lights.setup(14, 1)
	lights.max_distance = 34.0
	signs = LightPool.new()
	signs.name = "ExitSigns"
	add_child(signs)
	signs.setup(4, 0)
	signs.max_distance = 40.0
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", SPAWN, 180.0)
	add_arrival("from_L000", SPAWN, 180.0)
	world.build_around(SPAWN, 2)
	add_shot("halls", Vector3(12.6, 1.62, 11.0), Vector3(10.6, 1.75, 40.0))
	add_shot("hole", Vector3(14.0, 1.62, 33.5), Vector3(6.0, 2.8, 40.0))
	add_landmark("Arrival point (Aquila Sector)", SPAWN)
	add_landmark("Base Alpha north exit", Vector3(11.5, 0, 40))
	add_landmark("Upper maintenance gallery (east of arrival)", Vector3(53.0, 4.2, 23.0))
	add_shot("gallery", Vector3(38.0, 1.65, 14.0), Vector3(53.0, 5.0, 24.0))


func _on_unload(key: Vector2i) -> void:
	lights.remove_group("%d,%d" % [key.x, key.y])
	signs.remove_group("%d,%d" % [key.x, key.y])


func _m(n: String, base: String, a: Color, b: Color, x: Dictionary = {}) -> void:
	x["albedo_a"] = a
	x["albedo_b"] = b
	MatLib.define(n, x, base)


func _materials() -> void:
	var c := "concrete"
	var fl := {"pattern": 1, "pattern_scale": Vector2(4.0, 4.0), "grout_width": 0.012, "grout_color": Color(0.17, 0.17, 0.16), "tile_variation": 0.05, "noise_scale": 0.8,
		"stain_amount": 0.55, "stain_color": Color(0.17, 0.16, 0.14), "stain_scale": 0.2, "wetness": 0.6, "roughness_a": 0.75, "roughness_b": 0.95}
	_m("l1_floor", c, Color(0.30, 0.31, 0.30), Color(0.24, 0.25, 0.24), fl.duplicate())
	fl["wetness"] = 0.25
	_m("l1_floor_gild", c, Color(0.38, 0.35, 0.30), Color(0.31, 0.28, 0.24), fl)
	_m("l1_wall", c, Color(0.44, 0.44, 0.40), Color(0.36, 0.36, 0.33), {"pattern": 1, "pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.006, "grout_color": Color(0.30, 0.30, 0.28), "tile_variation": 0.08,
		"stain_amount": 0.95, "stain_color": Color(0.22, 0.20, 0.14), "stain_scale": 0.55, "grime_height": 1.5, "grime_color": Color(0.14, 0.14, 0.12), "noise_scale": 0.6, "wetness": 0.3})
	_m("l1_wall_gild", c, Color(0.52, 0.44, 0.28), Color(0.42, 0.36, 0.24), {"pattern": 4, "pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.35, 0.31, 0.24), "stain_amount": 0.5, "grime_height": 1.0})
	_m("l1_wall_gothic", c, Color(0.50, 0.48, 0.45), Color(0.42, 0.40, 0.37), {"stain_amount": 0.6, "grime_height": 1.0, "noise_scale": 0.9})
	_m("l1_pillar", c, Color(0.42, 0.42, 0.40), Color(0.33, 0.33, 0.31), {"stain_amount": 0.8, "stain_color": Color(0.24, 0.22, 0.17), "stain_scale": 0.4, "grime_height": 1.2, "grime_color": Color(0.15, 0.15, 0.13), "noise_scale": 1.2, "bump_strength": 1.0})
	_m("l1_pband", c, Color(0.27, 0.31, 0.28), Color(0.23, 0.27, 0.24), {"stain_amount": 0.5, "stain_color": Color(0.20, 0.20, 0.17), "stain_scale": 0.7, "grime_height": 0.5, "grime_color": Color(0.14, 0.15, 0.13), "roughness_a": 0.6})
	_m("l1_plinth", c, Color(0.26, 0.26, 0.25), Color(0.21, 0.21, 0.20))
	_m("l1_ceiling", c, Color(0.28, 0.28, 0.27), Color(0.21, 0.21, 0.20), {"stain_amount": 0.85, "stain_color": Color(0.13, 0.12, 0.09), "stain_scale": 0.25})
	_m("l1_corr_wall", c, Color(0.70, 0.70, 0.66), Color(0.62, 0.62, 0.58), {"pattern": 4, "pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.006, "grout_color": Color(0.58, 0.58, 0.55), "stain_amount": 0.45, "stain_color": Color(0.52, 0.48, 0.38), "grime_height": 0.7, "grime_color": Color(0.40, 0.39, 0.34)})
	_m("l1_corr_floor", c, Color(0.34, 0.36, 0.34), Color(0.29, 0.31, 0.29), {"roughness_a": 0.55, "stain_amount": 0.35})
	_m("l1_corr_ceiling", c, Color(0.52, 0.52, 0.50), Color(0.45, 0.45, 0.43), {"stain_amount": 0.5})
	_m("l1_line", c, Color(0.66, 0.63, 0.47), Color(0.50, 0.48, 0.38), {"stain_amount": 0.6, "stain_color": Color(0.3, 0.3, 0.28), "noise_scale": 2.0})
	var cr := {"pattern": 3, "pattern_scale": Vector2(0.9, 0.15), "grout_width": 0.005, "grout_color": Color(0.2, 0.13, 0.07), "roughness_a": 0.85, "roughness_b": 0.95, "stain_amount": 0.3, "stain_color": Color(0.3, 0.22, 0.12)}
	_m("l1_crate", "wood_floor", Color(0.58, 0.44, 0.27), Color(0.48, 0.36, 0.21), cr.duplicate())
	_m("l1_crate_dark", "wood_floor", Color(0.38, 0.27, 0.16), Color(0.31, 0.21, 0.12), cr)
	_m("l1_straw", "plaster", Color(0.72, 0.62, 0.38), Color(0.6, 0.5, 0.3), {"noise_scale": 9.0, "bump_strength": 2.0})
	_m("l1_wood", "wood_floor", Color(0.42, 0.30, 0.20), Color(0.34, 0.24, 0.16))
	_m("l1_metal", "metal", Color(0.42, 0.44, 0.44), Color(0.34, 0.35, 0.35))
	_m("l1_rack", "metal", Color(0.20, 0.34, 0.52), Color(0.16, 0.28, 0.44), {"metallic_value": 0.4, "roughness_a": 0.5})
	_m("l1_pipe", "metal", Color(0.40, 0.44, 0.40), Color(0.34, 0.28, 0.20), {"metallic_value": 0.5, "stain_amount": 0.6, "stain_color": Color(0.38, 0.22, 0.12)})
	_m("l1_fixture", "metal", Color(0.70, 0.70, 0.67), Color(0.60, 0.60, 0.57), {"metallic_value": 0.3})
	_m("l1_door", "metal", Color(0.33, 0.40, 0.38), Color(0.28, 0.33, 0.31), {"metallic_value": 0.35, "stain_amount": 0.4, "peel_amount": 0.25, "peel_color": Color(0.35, 0.22, 0.12)})
	_m("l1_meg", "plaster", Color(0.74, 0.88, 0.10), Color(0.64, 0.80, 0.08), {"roughness_a": 1.0, "bump_strength": 1.2, "noise_scale": 4.0})
	_m("l1_brick", "brick", Color(0.50, 0.28, 0.21), Color(0.43, 0.22, 0.17))
	_m("l1_plush_rubber", "plaster", Color(0.84, 0.82, 0.74), Color(0.78, 0.76, 0.68), {"pattern": 1, "pattern_scale": Vector2(0.5, 0.5), "grout_width": 0.04, "grout_color": Color(0.62, 0.60, 0.52), "bump_strength": 2.2, "roughness_a": 0.7})
	_m("l1_mattress", "plaster", Color(0.78, 0.76, 0.70), Color(0.70, 0.66, 0.58), {"stain_amount": 0.7, "stain_color": Color(0.55, 0.47, 0.32), "pattern": 2, "pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.62, 0.68, 0.74), "pattern_strength": 0.4})
	_m("l1_beige", "plaster", Color(0.74, 0.70, 0.60), Color(0.68, 0.64, 0.54), {"roughness_a": 0.5})
	_m("l1_screen", "plaster", Color(0.05, 0.07, 0.06), Color(0.04, 0.05, 0.05), {"roughness_a": 0.1, "roughness_b": 0.2})
	_m("l1_frame", "wood_floor", Color(0.36, 0.24, 0.12), Color(0.28, 0.18, 0.09))
	_m("l1_canvas_a", "plaster", Color(0.42, 0.52, 0.48), Color(0.62, 0.55, 0.38), {"noise_scale": 3.0, "noise_mix": 0.6})
	_m("l1_canvas_b", "plaster", Color(0.55, 0.30, 0.25), Color(0.80, 0.70, 0.52), {"pattern": 10, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.30, 0.16, 0.12), "pattern_strength": 0.6})
	_m("l1_canvas_c", "plaster", Color(0.25, 0.30, 0.45), Color(0.70, 0.66, 0.60), {"pattern": 15, "pattern_color": Color(0.85, 0.80, 0.55), "pattern_strength": 0.7, "noise_scale": 2.0})
	_m("l1_band_r", c, Color(0.55, 0.14, 0.11), Color(0.45, 0.11, 0.09), {"stain_amount": 0.4})
	_m("l1_band_b", c, Color(0.15, 0.29, 0.52), Color(0.11, 0.23, 0.42), {"stain_amount": 0.4})
	_m("l1_band_y", c, Color(0.72, 0.56, 0.11), Color(0.62, 0.47, 0.09), {"stain_amount": 0.4})
	_m("l1_dial", "plaster", Color(0.90, 0.88, 0.82), Color(0.84, 0.82, 0.76), {"roughness_a": 0.3})
	_m("l1_valve", "metal", Color(0.62, 0.10, 0.08), Color(0.50, 0.08, 0.06), {"roughness_a": 0.5})
	_m("l1_cord", "plaster", Color(0.05, 0.05, 0.05), Color(0.05, 0.05, 0.05))
	_m("l1_bulb", "plaster", Color(1, 1, 1), Color(1, 1, 1), {"emission_color": Color(1.0, 0.78, 0.48), "emission_energy": 5.0})
	_m("l1_smile", "plaster", Color(1, 1, 1), Color(1, 1, 1), {"emission_color": Color(1.0, 0.98, 0.9), "emission_energy": 7.0, "bump_strength": 0.0})
	_m("l1_boards", "wood_floor", Color(0.26, 0.18, 0.11), Color(0.18, 0.12, 0.07))
	_m("l1_ladder", "metal", Color(0.50, 0.50, 0.46), Color(0.38, 0.30, 0.22), {"stain_amount": 0.6, "stain_color": Color(0.40, 0.22, 0.10)})
	MatLib.define("l1_void", {}, "void_black")
	MatLib.register("l1_panel", MatLib.panel(Color(0.86, 0.95, 1.0), 2.4))
	MatLib.register("l1_panel_warm", MatLib.panel(Color(1.0, 0.90, 0.72), 2.3))
	MatLib.register("l1_exit", MatLib.panel(Color(0.22, 1.0, 0.45), 1.6))
	MatLib.register("l1_puddle", MatLib.water({"shallow_color": Color(0.40, 0.42, 0.40), "deep_color": Color(0.07, 0.08, 0.07), "absorption": 4.0, "clarity": 0.45,
		"wave_height": 0.0, "foam_amount": 0.0, "roughness_value": 0.02, "normal_strength": 0.06, "refraction": 0.004}))


# ------------------------------------------------------------- world rules

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func _vnoise(x: float, z: float) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := smoothstep(0.0, 1.0, x - ix)
	var fz := smoothstep(0.0, 1.0, z - iz)
	return lerpf(lerpf(_h01(ix, iz, 7), _h01(ix + 1, iz, 7), fx), lerpf(_h01(ix, iz + 1, 7), _h01(ix + 1, iz + 1, 7), fx), fz)


## Sectors: "similar yet distinct zones". New arrivals land in Aquila.
func sector_of(cx: int, cz: int) -> String:
	if maxi(absi(cx), absi(cz)) <= 2:
		return "aquila"
	var n := _vnoise(cx * 0.21 + 3.3, cz * 0.21 + 7.1)
	return "gothic" if n > 0.64 else ("gild" if n > 0.42 else "aquila")


## Pipes-and-dials gradient toward the Level 2 smooth threshold (0..1).
func util_of(cx: int, cz: int) -> float:
	return clampf(float(cx * _udir.x + cz * _udir.y - 1) / 6.0, 0.0, 1.0)


func _pw(sec: String) -> float:
	return 0.45 if sec == "gild" else (0.65 if sec == "gothic" else 0.7)


func _slab_around(k: GeoKit, o: Rect2, h: Rect2, y: float, th: float, mat: String, faces: int) -> void:
	if h.size == Vector2.ZERO:
		k.slab(o.position.x, o.position.y, o.end.x, o.end.y, y, th, mat, faces)
		return
	for q in [Rect2(o.position.x, o.position.y, h.position.x - o.position.x, o.size.y), Rect2(h.end.x, o.position.y, o.end.x - h.end.x, o.size.y),
			Rect2(h.position.x, o.position.y, h.size.x, h.position.y - o.position.y), Rect2(h.position.x, h.end.y, h.size.x, o.end.y - h.end.y)]:
		if q.size.x > 0.01 and q.size.y > 0.01:
			k.slab(q.position.x, q.position.y, q.end.x, q.end.y, y, th, mat, faces)


func _ok(p: Vector3, avoid: Array) -> bool:
	for a in avoid:
		if (a as Rect2).has_point(Vector2(p.x, p.z)):
			return false
	return true


# ---------------------------------------------------------------- builder

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, "l1"])
	var k := GeoKit.new(node, "K")
	var ox := cx * CS
	var oz := cz * CS
	var sec := sector_of(cx, cz)
	var u := util_of(cx, cz)
	var g := "%d,%d" % [cx, cz]
	var authored := cx == 0 and cz == 1
	var gallery := Vector2i(cx, cz) == MEZZANINE_CHUNK
	var meta := {"sector": sec, "util": u, "blocks": [], "rooms": [], "lm": [], "leaks": [], "authored": authored}
	var blk := BLOCK if authored else Rect2()
	if not authored and sec != "gothic" and u < 0.5 and maxi(absi(cx), absi(cz)) >= 2 and not _holes.has(Vector2i(cx, cz)) and r.randf() < 0.22:
		blk = Rect2(ox + 8.0, oz + 8.0, 16.0, 16.0)
	var hole := Rect2()
	var hfoot := Vector3(6.0, 0.0, 40.0)
	var hout := Vector3(0, 0, -1) if authored else Vector3.ZERO
	if _holes.has(Vector2i(cx, cz)):
		hfoot = Vector3(ox + (1 + r.randi() % 3) * BAY, 0.0, oz + (1 + r.randi() % 3) * BAY + _pw(sec))
		hout = Vector3(0, 0, 1)
	var avoid: Array = [BLOCK.grow(2.0)]
	if hout != Vector3.ZERO:
		var hc := hfoot + hout * 0.7
		hole = Rect2(hc.x - 0.7, hc.z - 0.7, 1.4, 1.4)
		avoid.append(hole.grow(1.6))
	if blk.size != Vector2.ZERO:
		avoid.append(blk.grow(1.2))
	if cx == 0 and cz == 0:
		avoid.append(Rect2(SPAWN.x - 3.0, SPAWN.z - 3.0, 6.0, 9.0))
	_slab_around(k, Rect2(ox, oz, CS, CS), blk, 0.0, 0.4, "l1_floor_gild" if sec == "gild" else "l1_floor", GeoKit.PY)
	_slab_around(k, Rect2(ox, oz, CS, CS), hole, 9.2 if gallery else HH + 0.4, 0.4, "l1_ceiling", GeoKit.NY)
	for b in 4:
		if not (authored and b == 1):
			k.box(Vector3(ox + CS * 0.5, 8.8 if gallery else HH - 0.3, oz + b * BAY), Vector3(CS, 0.6, 0.5), "l1_ceiling", GeoKit.NY | GeoKit.PZ | GeoKit.NZ, false)
		for zz in [2.2, 5.6]:   # conduits between the beams
			Kit.pipe(k, Vector3(ox, 8.9 if gallery else HH - 0.06, oz + b * BAY + zz), Vector3(ox + CS, 8.9 if gallery else HH - 0.06, oz + b * BAY + zz), 0.03, "l1_metal", 6)
	# pillars: huge and square in Aquila, slimmer in Gild, round in Gothic
	var band := Vector2i(r.randi() % 4, r.randi() % 4) if r.randf() < 0.3 else Vector2i(-1, -1)
	var bmat: String = ["l1_band_r", "l1_band_b", "l1_band_y"][r.randi() % 3]
	var pillars: Array = []
	for b in 4:
		for a in 4:
			var p := Vector3(ox + a * BAY, 0.0, oz + b * BAY)
			if (gallery and a >= 2 and b >= 1) or blk.grow(1.0).has_point(Vector2(p.x, p.z)) or BLOCK.grow(1.0).has_point(Vector2(p.x, p.z)):
				continue
			pillars.append(p)
			if sec == "gothic":
				k.cylinder(p + Vector3.UP * HH * 0.5, 0.65, HH, "l1_pillar", 16)
				continue
			var w := _pw(sec) * 2.0
			var ph := 9.1 if gallery else HH
			k.box(p + Vector3.UP * ph * 0.5, Vector3(w, ph, w), "l1_pillar", GeoKit.SIDES)
			k.box(p + Vector3.UP * 0.12, Vector3(w + 0.08, 0.24, w + 0.08), "l1_plinth", GeoKit.SIDES | GeoKit.PY, false)
			if sec == "aquila":   # faded two-tone paint on the lower pillar
				k.box(p + Vector3.UP * 0.72, Vector3(w + 0.012, 0.96, w + 0.012), "l1_pband", GeoKit.SIDES, false)
			if band == Vector2i(a, b):
				k.box(p + Vector3.UP * 1.3, Vector3(w + 0.02, 1.0, w + 0.02), bmat, GeoKit.SIDES, false)
				meta["lm"].append(p + Vector3.UP * 1.3)
	# fluorescent fixtures (Gild: "more lights"; along the Level 2 gradient: dying, amber)
	var pmat := "l1_panel_warm" if sec != "aquila" else "l1_panel"
	var lcol := Color(0.85, 0.94, 1.0) if sec == "aquila" else Color(1.0, 0.88, 0.70)
	for b in 4:
		for a in 4:
			for off in ([Vector2(4, 4), Vector2(4, 0)] if sec == "gild" else [Vector2(4, 4)]):
				var c := Vector3(ox + a * BAY + off.x, 8.75 if gallery else HH - 0.95, oz + b * BAY + off.y)
				if blk.has_point(Vector2(c.x, c.z)) or (sec == "gothic" and (a + b) % 2 == 1) or hole.grow(1.0).has_point(Vector2(c.x, c.z)):
					continue
				var dead := r.randf() < 0.05 + u * 0.35
				var fl := 0.85 if r.randf() < 0.06 + u * 0.1 else 0.0
				Kit.tube(k, c, off.y > 0.0, HH, pmat, 100.0 if dead else float(a * 7 + b * 3 + cx * 11 + cz), fl)
				if not dead and (off.y > 0.0 or (a + b) % 2 == 0 or sec != "gild"):
					lights.add_anchor(c + Vector3.DOWN * 0.3, lcol.lerp(Color(1.0, 0.7, 0.4), u), 2.2 - u * 0.7, 11.0, fl, g)
	# ceiling pipe trunks on fixed world lines (continuous across chunks); leaks below
	for a in 4:
		var ix := cx * 4 + a
		if _h01(ix, 0, 31) < 0.6 or cx == 0:
			var x := ox + a * BAY + 2.3
			Kit.pipe(k, Vector3(x, 8.5 if gallery else HH - 0.75, oz), Vector3(x, 8.5 if gallery else HH - 0.75, oz + CS), 0.12 if _h01(ix, 1, 31) < 0.5 else 0.07, "l1_pipe", 8)
			var lz := oz + r.randf_range(3.0, CS - 3.0)
			if not gallery and sec == "aquila" and r.randf() < 0.55 and _ok(Vector3(x, 0, lz), [BLOCK.grow(1.0), blk.grow(1.0)]):
				meta["leaks"].append(Vector3(x, 0.0, lz))
				for i in 4:
					Kit.disk(k, Vector3(x + r.randf_range(-0.7, 0.7), 0.008, lz + r.randf_range(-0.9, 0.9)), Vector3.UP, r.randf_range(0.35, 0.95), "l1_puddle", 14)
	for i in int(u * 7.0):
		var z := oz + r.randf_range(1.0, CS - 1.0)
		var y := r.randf_range(2.4, 3.9)
		Kit.pipe(k, Vector3(ox, y, z), Vector3(ox + CS, y, z), r.randf_range(0.05, 0.16), "l1_pipe" if i % 3 else "l1_metal", 8)
	# bland, discoloured walls; Gothic arches
	if blk.size == Vector2.ZERO and hole.size == Vector2.ZERO and sec != "gothic" and maxi(absi(cx), absi(cz)) > 0 and r.randf() < 0.28 + u * 0.4:
		var ax := r.randf() < 0.5
		var idx := 1 + r.randi() % 3
		var ops: Array = []
		for n in 1 + r.randi() % 3:
			ops.append({"at": 4.0 + 8.0 * (r.randi() % 4) + r.randf_range(-1.0, 1.0), "w": r.randf_range(3.0, 6.0), "h": HH + 1.0})
		var a0 := Vector3(ox, 0, oz + idx * BAY) if ax else Vector3(ox + idx * BAY, 0, oz)
		k.wall(a0, a0 + (Vector3(CS, 0, 0) if ax else Vector3(0, 0, CS)), HH, 0.3, "l1_wall_gild" if sec == "gild" else "l1_wall", ops, GeoKit.SIDES)
	if sec == "gothic":
		for n in 1 + r.randi() % 2:
			var arches: Array = []
			for i in 4:
				arches.append({"at": 4.0 + 8.0 * i, "w": 6.0, "spring": 1.35})
			var z := oz + (1 + r.randi() % 3) * BAY
			k.arch_wall(Vector3(ox, 0, z), Vector3(ox + CS, 0, z), HH, 0.45, "l1_wall_gothic", arches, 10)
	if hout != Vector3.ZERO:
		_ceiling_hole(k, node, hfoot, hout, meta, authored)
	if blk.size != Vector2.ZERO:
		Kit.corridor_block(self, k, node, blk, r, g, meta, authored)
		if authored:
			_vent(k, node, BLOCK.position.x, BLOCK.get_center().y)
	if gallery:
		_maintenance_gallery(k, node, g)
	else:
		_features(k, node, cx, cz, sec, u, r, pillars, avoid, meta)
	if cx == 0 and cz == 0:   # arrival dressing: the supply crate, a crate stack, debris
		sys.make_crate(node, "start", START_CRATE, 0.35, Vector3(0.9, 0.7, 0.7), true)
		sys.make_crate(node, "c0_0_s1", Vector3(19.6, 0, 13.2), 0.2, Vector3(1.0, 0.75, 0.8))
		sys.make_crate(node, "c0_0_s2", Vector3(19.7, 0.75, 13.3), 0.9, Vector3(0.7, 0.5, 0.6))
		sys.make_crate(node, "c0_0_s3", Vector3(21.1, 0, 14.4), 2.0, Vector3(0.8, 0.6, 0.7))
		Kit.debris(k, Vector3(8.8, 0, 19.5), r)
		meta["leaks"].append(Vector3(10.3, 0, 22.5))   # a pipe "leaking damp water on the floor"
		for d in [Vector4(10.1, 22.3, 0.9, 0), Vector4(10.9, 23.1, 0.6, 0), Vector4(9.6, 23.4, 0.5, 0), Vector4(10.6, 21.6, 0.45, 0)]:
			Kit.disk(k, Vector3(d.x, 0.008, d.y), Vector3.UP, d.z, "l1_puddle", 16)
		meta["lm"].append(START_CRATE + Vector3.UP * 0.5)
	if not qa_fixture and cx * _udir.x + cz * _udir.y >= 7:   # smooth threshold to Level 2
		make_exit("L001>L002#1", "walk_in", Vector3(ox + CS * 0.5, 1.5, oz + CS * 0.5), Vector3(CS - 2.0, 3.0, CS - 2.0), "", node)
	k.commit()
	ModelDress.decorate_chunk(self, node, "L001", cx, cz)
	return meta


## Authored warehouse mezzanine. Two heights are physically connected by a
## full-rise stair collision ramp, NOT by teleportation or fake decorative stairs.
## ADAPTATION: maintenance access within Level 1's abandoned warehouse setting.
func _maintenance_gallery(k: GeoKit, node: Node3D, group: String) -> void:
	const TOP := 4.2
	# The 9.2 m roof and the absence of normal random rack props in this bay
	# leave useful standing clearance above and beneath the suspended deck.
	k.stairs(Vector3(35.0, 0.0, 21.0), Vector3.RIGHT, 2.0, TOP, 16, "l1_metal", 0.55, true)
	k.slab(43.8, 17.0, 61.5, 29.5, TOP, 0.24, "l1_metal", GeoKit.ALL)
	k.slab(49.4, 7.0, 52.0, 17.0, TOP, 0.24, "l1_metal", GeoKit.ALL)
	# Rails around the open drop; the stair opening at x=43.8 remains clear.
	# Leave a 3 m bridge opening in the near rail; the far edge is continuous.
	for a in [[43.8, 49.1], [52.3, 61.5]]:
		k.box(Vector3((a[0] + a[1]) * 0.5, TOP + 0.54, 17.0), Vector3(a[1] - a[0], 1.08, 0.09), "l1_rack")
	k.box(Vector3(52.6, TOP + 0.54, 29.5), Vector3(17.8, 1.08, 0.09), "l1_rack")
	k.box(Vector3(61.45, TOP + 0.54, 23.25), Vector3(0.09, 1.08, 12.3), "l1_rack")
	for xx in [49.4, 52.0]:
		k.box(Vector3(xx, TOP + 0.54, 11.9), Vector3(0.08, 1.08, 9.5), "l1_rack")
	# The opposite end of the bridge is a deliberate dead end with an overlook.
	for xx in [45.5, 58.5]:
		for zz in [19.0, 27.5]:
			k.box(Vector3(xx, TOP - 2.05, zz), Vector3(0.22, 4.0, 0.22), "l1_metal")
	k.box(Vector3(58.5, TOP + 0.42, 25.8), Vector3(1.8, 0.84, 0.58), "l1_fixture")
	for i in 5:
		k.box(Vector3(58.5 - i * 0.22, TOP + 0.92, 25.5), Vector3(0.12, 0.04, 0.10), "l1_meg", GeoKit.ALL, false)
	# DEV19: one two-way emergency lighting circuit connects both levels of
	# the existing mezzanine. Its lamps physically reveal the stair and return
	# path during the wiki's unpredictable Flickering; it does NOT alter Flickering.
	var circuit_lights: Array = []
	for lamp_info in [
		["Entry", Vector3(36.2, 3.2, 21.0), 7.0],
		["StairLanding", Vector3(44.0, TOP + 2.0, 21.0), 9.0],
		["MaintenanceEmergencyLight", Vector3(58.5, TOP + 1.75, 25.8), 9.0],
		["ThirdDeck", Vector3(50.0, 7.7, 26.0), 8.0]
	]:
		var glow := OmniLight3D.new()
		glow.name = "Circuit_" + str(lamp_info[0])
		glow.position = lamp_info[1]
		glow.light_color = Color(1.0, 0.68, 0.32)
		glow.light_energy = 1.4 if _gallery_circuit_on else 0.0
		glow.omni_range = float(lamp_info[2])
		glow.shadow_enabled = false
		node.add_child(glow)
		circuit_lights.append(glow)
	# Accessible from the floor OR the upper level. Neither is compulsory:
	# the normal 9th Road / Level 1 exits remain unchanged.
	for control in [Vector3(35.5, 1.2, 22.0), Vector3(58.5, TOP + 1.15, 25.3)]:
		make_interactable(control, Vector3(1.25, 0.85, 0.85),
			"Toggle emergency gallery lamp" if control.y > TOP else "Toggle gallery emergency lighting", func(_p):
			_gallery_circuit_on = not _gallery_circuit_on
			for fixture in circuit_lights:
				fixture.light_energy = 1.4 if _gallery_circuit_on else 0.0
			SaveService.record_discovery(stable_id, "gallery_circuit",
				"The battery-fed maintenance lights outline the way up. The warehouse blackouts remain unpredictable.", "ADAPTATION")
			sound.play_at("transformer", {"seconds": 1.5}, control, -16.0)
			Overlay.subtitle("[a relay snaps; four amber lamps %s]" % ("illuminate the gallery" if _gallery_circuit_on else "go out"), 4.0), node)
	var note := Interactable.new()
	node.add_child(note)
	note.setup(Vector3(50.6, TOP + 0.95, 8.2), Vector3(1.4, 0.7, 0.3), "Inspect maintenance clipboard", func(_p):
		Overlay.toast("An unsigned inspection form. The diagram shows one stair, then the same stair again, impossibly.", 5.0))
	k.box(Vector3(50.6, TOP + 0.75, 8.2), Vector3(1.2, 0.7, 0.12), "l1_beige", GeoKit.ALL, false)
	lights.add_anchor(Vector3(50.5, TOP + 3.2, 14.5), Color(0.85, 0.88, 0.8), 1.25, 9.0, 0.0, group)
	_maintenance_upper_deck(k, node, group, TOP)



## DEV14: a third, deliberately compact inspection level over the original
## warehouse mezzanine. Cut a 2.9 m stair slot in its floor, with two separate
## viewing returns. Keep upper walkways under the 9.2 m ceiling beams.
func _maintenance_upper_deck(k: GeoKit, node: Node3D, group: String, lower: float) -> void:
	var upper := 6.50
	# Existing lower deck spans x=43.8..61.5, z=17..29.5.
	# Upward stair starts on it and finishes at the upper landing at z=25.25.
	k.stairs(Vector3(56.35, lower, 18.05), Vector3.BACK, 1.80, upper - lower,
		18, "l1_metal", 0.40, false)
	# Cutout x=55..58, z=18..25.2, flanked by two parallel balcony paths.
	for rect in [
		[44.0, 17.0, 55.0, 29.0], [58.0, 17.0, 61.2, 29.0],
		[55.0, 25.2, 58.0, 29.0], [55.0, 17.0, 58.0, 18.0]
	]:
		k.slab(rect[0], rect[1], rect[2], rect[3], upper, 0.20, "l1_metal", GeoKit.PY)
	# Upper loop with two different overlooking branches, not a solid slab.
	for zz in [17.0, 29.0]:
		k.box(Vector3(49.5, upper + 0.50, zz), Vector3(11.0, 1.0, 0.10), "l1_rack")
	for xx in [44.0, 61.2]:
		k.box(Vector3(xx, upper + 0.5, 23.0), Vector3(0.10, 1.0, 12.0), "l1_rack")
	# Guard the long sides of the rising slot, leaving both landings open.
	for xx in [55.0, 58.0]:
		k.box(Vector3(xx, upper + 0.55, 21.2), Vector3(0.10, 1.10, 6.3), "l1_rack")
	k.box(Vector3(52.0, upper + 0.48, 20.2), Vector3(2.0, 0.96, 0.24), "l1_fixture", GeoKit.ALL, false)
	var log := Interactable.new()
	node.add_child(log)
	log.setup(Vector3(50.0, upper + 1.0, 27.0), Vector3(1.2, 1.2, 1.2),
		"Read the third-deck safety chart", func(_p):
			Overlay.toast("Two mezzanine surveys disagree on the number of floors. Both bear the same signature.", 5.0))
	lights.add_anchor(Vector3(49.5, upper + 1.7, 27.0), Color(0.95, 0.81, 0.52), 0.55, 8.0, 0.0, group)


func _features(k: GeoKit, node: Node3D, cx: int, cz: int, sec: String, u: float, r: RandomNumberGenerator, pillars: Array, avoid: Array, meta: Dictionary) -> void:
	var ox := cx * CS
	var oz := cz * CS
	var spots: Array = []
	for b in 4:
		for a in 4:
			var p := Vector3(ox + a * BAY + 4.0 + r.randf_range(-1.6, 1.6), 0.0, oz + b * BAY + 4.0 + r.randf_range(-1.6, 1.6))
			if _ok(p, avoid):
				spots.append(p)
	for i in range(spots.size() - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = spots[i]
		spots[i] = spots[j]
		spots[j] = tmp
	if sec == "gild" and spots.size() > 2:   # warehouse racks: "hosts more crates"
		for q in 2:
			var p: Vector3 = spots.pop_back()
			var along := r.randf() < 0.5
			var a0 := p - (Vector3(3.0, 0, 0) if along else Vector3(0, 0, 3.0))
			var shelves: Array = Kit.rack(k, a0, 6.0, 3.0, along)
			for s in 2:
				var y: float = shelves[s + 1] if r.randf() < 0.5 else shelves[s]
				var off := r.randf_range(0.6, 5.4)
				sys.make_crate(node, "c%d_%d_r%d%d" % [cx, cz, q, s], a0 + (Vector3(off, y, 0) if along else Vector3(0, y, off)), r.randf_range(-0.2, 0.2), Vector3(0.7, 0.5, 0.6))
			meta["lm"].append(p + Vector3.UP * 2.0)
	for i in 1 + r.randi() % 2 + (2 if sec == "gild" else 0):
		if spots.is_empty():
			break
		var p: Vector3 = spots.pop_back()
		sys.make_crate(node, "c%d_%d_%d" % [cx, cz, i], p, r.randf() * TAU, Vector3(r.randf_range(0.7, 1.0), r.randf_range(0.55, 0.8), r.randf_range(0.6, 0.8)))
		if r.randf() < 0.4:
			sys.make_crate(node, "c%d_%d_%db" % [cx, cz, i], p + Vector3(r.randf_range(-0.2, 0.2), 0.8, 0.0), r.randf() * TAU, Vector3(0.6, 0.45, 0.55))
	if not spots.is_empty() and r.randf() < 0.55:
		Kit.debris(k, spots.pop_back(), r)
	if not spots.is_empty() and r.randf() < 0.14:
		var p: Vector3 = spots.pop_back()
		Kit.table(k, p, r.randf() * TAU, 1.6, 0.8, 0.76, "l1_wood")
		Kit.chair(k, p + Vector3(0.0, 0, 0.9), r.randf() * TAU)
		meta["lm"].append(p + Vector3.UP * 0.8)
	if sec == "aquila" and u < 0.3:   # parking-stall lines ("more reminiscent of a parking lot")
		for b in 4:
			if r.randf() < 0.5:
				for a in 4:
					for q in 3:
						var lp := Vector3(ox + a * BAY + 1.4 + q * 2.6, 0.004, oz + b * BAY + 4.0)
						if _ok(lp, avoid):
							k.quad(lp, Vector3.UP, Vector3(0.06, 0, 0), Vector3(0, 0, 2.3), "l1_line")
	for p in pillars:   # landmarks: electrical panels; dials and valves toward Level 2
		var face: Vector3 = [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD][r.randi() % 4]
		var at: Vector3 = p + face * (_pw(sec) + 0.01)
		if r.randf() < 0.08 and _ok(at, avoid):
			k.box_xf(Transform3D(Basis(Vector3.UP.cross(face).normalized(), Vector3.UP, face), at + Vector3.UP * 1.5 + face * 0.08), Vector3(0.6, 0.8, 0.16), "l1_fixture")
			meta["lm"].append(at + Vector3.UP * 1.5)
		if u > 0.0 and r.randf() < u * 0.9:
			Kit.dial(k, at + Vector3.UP * r.randf_range(1.4, 1.9), face)
			Kit.pipe(k, at + Vector3(0, 0.3, 0) + face * 0.1, at + Vector3(0, HH - 0.3, 0) + face * 0.1, 0.05, "l1_pipe", 6)
			if r.randf() < u * 0.6:
				var vp := at + Vector3.UP * 1.05 + face * 0.1
				Kit.valve(k, vp, face)
				if not meta.has("dev18_valve"):
					_utility_valve(node, vp, cx, cz, meta)
			meta["lm"].append(at + Vector3.UP * 1.6)


## An optional utility valve: local pipe pressure and its indicator, not a
## mandatory exit lock. It never overrides the wiki's unpredictable Flickering
## sequence. Scoped to the streamed chunk so no ghost collider survives unload.
func _utility_valve(owner: Node3D, at: Vector3, cx: int, cz: int, meta: Dictionary) -> void:
	var id := "%d,%d" % [cx, cz]
	meta["dev18_valve"] = id
	var lamp := OmniLight3D.new()
	lamp.name = "PipePressureIndicator"
	lamp.position = at + Vector3(0.0, 0.45, 0.0)
	lamp.light_color = Color(0.25, 0.82, 0.47)
	lamp.omni_range = 4.0
	lamp.light_energy = 1.0 if _valve_states.get(id, false) else 0.0
	owner.add_child(lamp)
	make_interactable(at, Vector3(1.0, 1.0, 1.0), "Turn the pressure valve", func(_p):
		var now: bool = not bool(_valve_states.get(id, false))
		_valve_states[id] = now
		SaveService.record_discovery(stable_id, "pressure_valve", "A service valve responds, but its pressure indicator offers no reliable control over the Flickering.")
		lamp.light_energy = 1.0 if now else 0.0
		Overlay.toast("[metal groans] The pipe pressure %s. Nothing else in this place responds." % ("rises" if now else "falls"), 4.0), owner)



## "Going into an open ventilation duct will lead to Level 800": a floor-level duct
## (riser box outside the corridor wall) with its grille off; only a crouch fits.
func _vent(k: GeoKit, node: Node3D, x0: float, zs: float) -> void:
	k.box_mm(Vector3(x0 - 1.6, 1.15, zs - 0.5), Vector3(x0, HH, zs + 0.5), "l1_metal")
	k.box_mm(Vector3(x0 - 1.6, 0.0, zs - 0.5), Vector3(x0, 1.21, zs - 0.45), "l1_metal")
	k.box_mm(Vector3(x0 - 1.6, 0.0, zs + 0.45), Vector3(x0, 1.21, zs + 0.5), "l1_metal")
	k.box_mm(Vector3(x0 - 1.65, 0.0, zs - 0.5), Vector3(x0 - 1.6, 1.21, zs + 0.5), "l1_void")
	k.box_mm(Vector3(x0 - 1.6, 0.0, zs - 0.45), Vector3(x0, 0.02, zs + 0.45), "l1_void", GeoKit.PY)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.25), Vector3(x0 + 1.0, 0.02, zs + 0.45)), Vector3(0.9, 0.03, 1.1), "l1_fixture", GeoKit.ALL, false)
	make_exit("L001>L800#14", "walk_in", Vector3(x0 - 0.5, 0.55, zs), Vector3(1.4, 1.0, 0.8), "", node)


## "Climbing up into holes into the ceiling can lead to Level 19": a ragged hole in
## the hall ceiling, a dark shaft capped by the underside of floorboards, a ladder.
func _ceiling_hole(k: GeoKit, node: Node3D, foot: Vector3, out: Vector3, meta: Dictionary, authored: bool) -> void:
	var c := foot + out * 0.7
	var y1 := HH + 1.9
	k.box_mm(Vector3(c.x - 0.8, HH, c.z - 0.8), Vector3(c.x - 0.7, y1, c.z + 0.8), "l1_void", GeoKit.PX)
	k.box_mm(Vector3(c.x + 0.7, HH, c.z - 0.8), Vector3(c.x + 0.8, y1, c.z + 0.8), "l1_void", GeoKit.NX)
	k.box_mm(Vector3(c.x - 0.8, HH, c.z - 0.8), Vector3(c.x + 0.8, y1, c.z - 0.7), "l1_void", GeoKit.PZ)
	k.box_mm(Vector3(c.x - 0.8, HH, c.z + 0.7), Vector3(c.x + 0.8, y1, c.z + 0.8), "l1_void", GeoKit.NZ)
	k.slab(c.x - 0.8, c.z - 0.8, c.x + 0.8, c.z + 0.8, y1 + 0.05, 0.05, "l1_boards", GeoKit.NY)
	for i in 3:   # ragged broken edge
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.3 * (i - 1)).rotated(Vector3.UP, i * 1.9), Vector3(c.x - 0.5 + i * 0.5, HH - 0.05, c.z + (0.68 if i % 2 else -0.68))), Vector3(0.35, 0.12, 0.2), "l1_ceiling", GeoKit.ALL, false)
	Kit.ladder(k, foot, out, HH + 1.3, "l1_ladder")
	var side := Vector3.UP.cross(out).normalized()
	var p0 := foot + out * 0.05 - side * 0.45
	var p1 := foot + out * 0.75 + side * 0.45
	var lv := LadderVolume.new()
	lv.name = "CeilingHoleLadder"
	node.add_child(lv)
	lv.setup(Vector3(minf(p0.x, p1.x), 0.0, minf(p0.z, p1.z)), Vector3(maxf(p0.x, p1.x), HH + 1.5, maxf(p0.z, p1.z)))
	var tr := make_exit("L001>L019#10", "condition", foot + out * 0.45 + Vector3.UP * 2.6, Vector3(1.6, 5.2, 1.3), "Ladder: hold forward to climb up into the hole in the ceiling", node)
	if tr:
		tr.condition = func(): return player != null and player.global_position.y > 3.3
		tr.fired.connect(_guard_fired.bind(tr))
	meta["lm"].append(c + Vector3.UP * (HH - 0.2))
	var dr := RandomNumberGenerator.new()
	dr.seed = hash([level_seed, int(foot.x), int(foot.z)])
	Kit.debris(k, foot + out * 1.9 + side * 1.1, dr)   # fallen ceiling chunks and planks


## A fired climb exit stays quiet until the climber is back down (no repeated
## release-boundary prompts while hanging on the ladder).
func _guard_fired(_edge: String, t: ExitTrigger) -> void:
	t.enabled = false
	_guarded.append(t)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	sys.base_fov = player.camera.fov
	if SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[silence after the buzzing] [a pipe clanks far away]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L001>L019#10", "target": Vector3(6.0, 0.05, 39.55), "note": "authored ceiling hole just off Base Alpha's north exit; the bot climbs its ladder"})


func level_process(delta: float) -> void:
	if player == null:
		return
	for t in _guarded.duplicate():
		if not is_instance_valid(t):
			_guarded.erase(t)
		elif player.global_position.y < 1.0:
			(t as ExitTrigger).enabled = true
			_guarded.erase(t)
	sys.step(delta)


# ---------------------------------------------------------------- QA stills

func qa_capture_plan() -> Array:
	var plan: Array = []
	for sh in qa_shots:
		var d: Dictionary = sh.duplicate()
		d["prepare"] = _prep.bind(false, SPAWN)
		plan.append(d)
	if OS.get_cmdline_user_args().has("--allshots"):
		plan.append({"name": "corridor", "pos": Vector3(3.0, 1.62, 48.0), "target": Vector3(20.0, 1.4, 48.0), "prepare": _prep.bind(false, SPAWN)})
		plan.append({"name": "flicker", "pos": Vector3(15.0, 1.62, 26.0), "target": Vector3(11.5, 1.5, 40.0), "prepare": _prep.bind(true, SPAWN)})
		for sec in ["gild", "gothic"]:
			var key := _find(sec)
			if key.x != 999:
				var o := world.chunk_origin(key)
				plan.append({"name": sec, "pos": o + Vector3(6.0, 1.62, 6.0), "target": o + Vector3(22.0, 1.6, 20.0), "prepare": _prep.bind(false, o + Vector3(16, 0, 16))})
		var uo := world.chunk_origin(Vector2i(_udir.x * 6, _udir.y * 6))
		plan.append({"name": "utility", "pos": uo + Vector3(4.0, 1.62, 4.0), "target": uo + Vector3(20.0, 1.8, 18.0), "prepare": _prep.bind(false, uo + Vector3(16, 0, 16))})
	return plan


func _prep(dark: bool, around: Vector3) -> void:
	world.build_around(around, 1)
	sys.fl = "dark" if dark else "calm"
	sys.fl_t = 9999.0
	sys.set_lit(0.0 if dark else 1.0)


func _find(sec: String) -> Vector2i:
	for rr in range(3, 12):
		for dz in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dz)) == rr and sector_of(dx, dz) == sec and util_of(dx, dz) < 0.2:
					return Vector2i(dx, dz)
	return Vector2i(999, 999)
