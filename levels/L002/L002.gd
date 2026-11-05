extends LevelBase
## Level 2 — "Abandoned Utility Halls" (Backrooms Wiki rev 93, accessed 2026-11-04;
## cite: Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L002.md.
##
## A streamed network of tight concrete maintenance tunnels. Junctions are
## octagons, so every turn is a multiple of 45 degrees, and junctions sit on a
## 20 m lattice (hallways of roughly 5 m multiples). Corridors carry floor-to-
## ceiling pipes and machines that whir but do nothing together; flatbeds, drums,
## boxes and tools litter them; doors of many colours line the walls, most locked.
## ADAPTATION (page gives no section): two decks on a service lattice (stacked
## two-storey corridors with grating mid-floors, maintenance stairs, catwalks over
## double-height pipe galleries, drops through torn grating). Geometry lives in
## L002_geo.gd / L002_props.gd; runtime systems (series circuits, heat, void
## rooms, chalk, Smilers) in L002_sys.gd.

const G := preload("res://levels/L002/L002_geo.gd")
const P := preload("res://levels/L002/L002_props.gd")
const Sys := preload("res://levels/L002/L002_sys.gd")
const S := 20.0
const DY := 4.2
const HU := 2.8
const HO := 3.0
const SPAWN := Vector3(8.2, 0.05, 11.6)

var world: ChunkWorld
var sys: Node
var qa_fixture := false
var circ_meshes: Dictionary = {}     # circuit id -> [MeshInstance3D]
var _ecache: Dictionary = {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.38
	rules["reverb_wet"] = 0.24
	rules["view_distance"] = 90.0
	indoor_env(Color(0.62, 0.6, 0.55), 0.045, Color(0.045, 0.043, 0.04), 0.05)
	environment.background_color = Color(0.02, 0.02, 0.02)
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.4
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.86
	environment.adjustment_contrast = 1.12
	_materials()
	lights.setup(16, 1)
	lights.max_distance = 30.0
	sys = Sys.new()
	sys.name = "Systems"
	add_child(sys)
	sys.setup(self)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = S
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", SPAWN, -90.0)
	add_arrival("from_L001", SPAWN, -90.0)
	world.build_around(Vector3(50.0, 0.0, 10.0), 0)   # the first gallery first: its elevator is the QA route
	world.build_around(SPAWN, 2)
	sys.beds()
	add_note("L002_chalk_note", "Chalk on the wall",
		"[i]Scrawled in chalk beside the old tram buffer, several hands, several years.[/i]\n\nDOORS WITH SIGNS = BACK TO 1. Easiest way out.\nBlue and pink doors go somewhere else. So do the tall ones.\nBLACK WINDOW = DON'T. If one opens, don't go in. There's no walls in there.\nIf the lights die, the whole block dies with them. Keep moving.\nIt gets HOT near some boilers. People vanish there.\nTracks go west to the EL3A offices. They don't want visitors.",
		Vector3(6.6, 1.25, 7.4), Vector3(0.6, 0.6, 0.3), false)
	add_shot("arrival", SPAWN + Vector3(-0.6, 1.62, 0.3), Vector3(30.0, 1.5, 9.0))
	add_landmark("Arrival vestibule (tram buffer)", Vector3(10, 0, 10))
	add_landmark("Pipe gallery", Vector3(50, 0, 10))


func _materials() -> void:
	var cc := {"albedo_a": Color(0.44, 0.42, 0.38), "albedo_b": Color(0.33, 0.31, 0.28), "noise_scale": 1.3, "stain_amount": 0.9,
		"stain_color": Color(0.22, 0.19, 0.14), "stain_scale": 0.45, "grime_height": 1.3, "grime_color": Color(0.14, 0.12, 0.1),
		"roughness_a": 0.96, "roughness_b": 1.0, "bump_strength": 1.3, "pattern": 1, "pattern_scale": Vector2(5.0, 1.25),
		"grout_width": 0.004, "grout_color": Color(0.38, 0.36, 0.33), "tile_variation": 0.07}
	MatLib.define("l2_wall", cc, "concrete")
	MatLib.define("l2_block", {"albedo_a": Color(0.46, 0.45, 0.41), "albedo_b": Color(0.38, 0.37, 0.33), "pattern": 4, "pattern_scale": Vector2(0.4, 0.2),
		"grout_width": 0.01, "grout_color": Color(0.3, 0.29, 0.26), "stain_amount": 0.9, "stain_color": Color(0.22, 0.19, 0.14), "grime_height": 1.2,
		"grime_color": Color(0.24, 0.22, 0.18), "roughness_a": 0.97, "bump_strength": 0.9}, "concrete")
	MatLib.define("l2_brick", {"albedo_a": Color(0.3, 0.2, 0.15), "albedo_b": Color(0.17, 0.13, 0.1), "grout_color": Color(0.36, 0.33, 0.29),
		"stain_amount": 0.6, "stain_color": Color(0.12, 0.1, 0.08), "grime_height": 0.9, "grime_color": Color(0.1, 0.08, 0.06), "roughness_a": 0.98}, "brick")
	MatLib.define("l2_floor", {"albedo_a": Color(0.33, 0.32, 0.3), "albedo_b": Color(0.25, 0.24, 0.22), "stain_amount": 0.85, "stain_color": Color(0.12, 0.11, 0.09),
		"stain_scale": 0.3, "wetness": 0.35, "noise_scale": 1.0, "roughness_a": 0.8, "roughness_b": 0.97}, "concrete")
	MatLib.define("l2_ceiling", {"albedo_a": Color(0.3, 0.29, 0.27), "albedo_b": Color(0.22, 0.21, 0.2), "stain_amount": 0.8, "stain_color": Color(0.1, 0.09, 0.07)}, "concrete")
	MatLib.define("l2_stair", {"albedo_a": Color(0.36, 0.36, 0.35), "albedo_b": Color(0.27, 0.27, 0.26), "metallic_value": 0.5, "pattern": 1, "pattern_scale": Vector2(0.05, 0.05),
		"grout_width": 0.18, "grout_color": Color(0.16, 0.16, 0.15), "stain_amount": 0.5}, "metal")
	MatLib.define("l2_grate", {"albedo_a": Color(0.34, 0.34, 0.33), "albedo_b": Color(0.24, 0.24, 0.23), "metallic_value": 0.55, "pattern": 1, "pattern_scale": Vector2(0.04, 0.04),
		"grout_width": 0.24, "grout_color": Color(0.05, 0.05, 0.05), "stain_amount": 0.5, "stain_color": Color(0.32, 0.2, 0.1), "roughness_a": 0.6}, "metal")
	var m := func(n: String, base: String, a: Color, b: Color, x: Dictionary = {}) -> void:
		x["albedo_a"] = a
		x["albedo_b"] = b
		MatLib.define(n, x, base)
	m.call("l2_steel", "metal", Color(0.5, 0.5, 0.49), Color(0.36, 0.36, 0.35), {"metallic_value": 0.3, "roughness_a": 0.55, "stain_amount": 0.5})
	m.call("l2_pipe_rust", "rust", Color(0.44, 0.27, 0.15), Color(0.28, 0.18, 0.11))
	m.call("l2_pipe_green", "metal", Color(0.24, 0.33, 0.27), Color(0.18, 0.24, 0.2), {"metallic_value": 0.3, "stain_amount": 0.6, "stain_color": Color(0.35, 0.22, 0.12)})
	m.call("l2_pipe_yellow", "metal", Color(0.62, 0.5, 0.14), Color(0.48, 0.38, 0.1), {"metallic_value": 0.25, "stain_amount": 0.5})
	m.call("l2_copper", "metal", Color(0.55, 0.33, 0.2), Color(0.32, 0.36, 0.3), {"metallic_value": 0.35})
	m.call("l2_insul", "plaster", Color(0.7, 0.68, 0.62), Color(0.55, 0.52, 0.46), {"stain_amount": 0.7, "stain_color": Color(0.4, 0.33, 0.22), "pattern": 2, "pattern_scale": Vector2(1.0, 0.35), "pattern_color": Color(0.5, 0.48, 0.43), "pattern_strength": 0.4})
	m.call("l2_machine", "metal", Color(0.36, 0.42, 0.38), Color(0.28, 0.32, 0.29), {"metallic_value": 0.3, "stain_amount": 0.55, "peel_amount": 0.2, "peel_color": Color(0.35, 0.22, 0.12)})
	m.call("l2_machine_dark", "metal", Color(0.2, 0.21, 0.22), Color(0.14, 0.15, 0.15), {"metallic_value": 0.5})
	m.call("l2_cabinet", "metal", Color(0.62, 0.6, 0.52), Color(0.52, 0.5, 0.43), {"metallic_value": 0.2, "stain_amount": 0.5})
	m.call("l2_louvre", "metal", Color(0.12, 0.12, 0.12), Color(0.1, 0.1, 0.1), {"pattern": 2, "pattern_scale": Vector2(1.0, 0.04), "pattern_color": Color(0.4, 0.4, 0.38), "pattern_strength": 0.8})
	m.call("l2_fixture", "metal", Color(0.62, 0.62, 0.58), Color(0.5, 0.5, 0.47), {"metallic_value": 0.2})
	m.call("l2_cord", "plaster", Color(0.05, 0.05, 0.05), Color(0.04, 0.04, 0.04))
	m.call("l2_cord_orange", "plaster", Color(0.85, 0.4, 0.08), Color(0.7, 0.32, 0.06), {"roughness_a": 0.5})
	m.call("l2_red", "metal", Color(0.6, 0.1, 0.07), Color(0.48, 0.08, 0.05), {"metallic_value": 0.2})
	m.call("l2_dialface", "plaster", Color(0.9, 0.88, 0.8), Color(0.82, 0.8, 0.72), {"roughness_a": 0.3})
	m.call("l2_rubber", "plaster", Color(0.06, 0.06, 0.06), Color(0.05, 0.05, 0.05))
	m.call("l2_cardboard", "plaster", Color(0.55, 0.42, 0.26), Color(0.47, 0.35, 0.21), {"stain_amount": 0.4})
	m.call("l2_woodbox", "wood_floor", Color(0.5, 0.38, 0.24), Color(0.4, 0.29, 0.17))
	m.call("l2_alu", "metal", Color(0.7, 0.7, 0.68), Color(0.58, 0.58, 0.56))
	m.call("l2_glass_bits", "plaster", Color(0.8, 0.85, 0.85), Color(0.7, 0.75, 0.75), {"roughness_a": 0.05, "roughness_b": 0.1})
	m.call("l2_drum_blue", "metal", Color(0.12, 0.24, 0.45), Color(0.1, 0.18, 0.34), {"metallic_value": 0.3, "stain_amount": 0.6, "stain_color": Color(0.35, 0.22, 0.12)})
	m.call("l2_drum_red", "metal", Color(0.5, 0.12, 0.08), Color(0.38, 0.1, 0.07), {"metallic_value": 0.3, "stain_amount": 0.6, "stain_color": Color(0.3, 0.18, 0.1)})
	m.call("l2_drum_rust", "rust", Color(0.4, 0.24, 0.13), Color(0.26, 0.15, 0.09))
	m.call("l2_rail_yellow", "metal", Color(0.75, 0.6, 0.12), Color(0.6, 0.45, 0.1), {"metallic_value": 0.2, "stain_amount": 0.5, "stain_color": Color(0.25, 0.2, 0.15)})
	m.call("l2_railsteel", "metal", Color(0.42, 0.36, 0.3), Color(0.3, 0.22, 0.16), {"metallic_value": 0.7})
	m.call("l2_sleeper", "wood_floor", Color(0.25, 0.19, 0.13), Color(0.18, 0.13, 0.09))
	m.call("l2_frame", "metal", Color(0.4, 0.4, 0.38), Color(0.32, 0.32, 0.3), {"metallic_value": 0.3})
	m.call("l2_brass", "metal", Color(0.62, 0.5, 0.25), Color(0.5, 0.4, 0.2), {"metallic_value": 0.9})
	var door := {"metallic_value": 0.35, "stain_amount": 0.45, "stain_color": Color(0.35, 0.3, 0.22), "grime_height": 0.5, "grime_color": Color(0.3, 0.27, 0.22), "roughness_a": 0.55}
	m.call("l2_door_white", "metal", Color(0.8, 0.8, 0.77), Color(0.72, 0.72, 0.69), door.duplicate())
	m.call("l2_door_grey", "metal", Color(0.5, 0.51, 0.5), Color(0.43, 0.44, 0.43), door.duplicate())
	m.call("l2_door_cream", "metal", Color(0.78, 0.73, 0.6), Color(0.7, 0.65, 0.53), door.duplicate())
	m.call("l2_door_dark", "metal", Color(0.3, 0.3, 0.3), Color(0.24, 0.24, 0.24), door.duplicate())
	m.call("l2_door_blue", "metal", Color(0.12, 0.28, 0.62), Color(0.1, 0.23, 0.52), door.duplicate())
	m.call("l2_door_pink", "metal", Color(0.85, 0.45, 0.62), Color(0.76, 0.38, 0.54), door.duplicate())
	m.call("l2_metal_bare", "metal", Color(0.5, 0.5, 0.52), Color(0.38, 0.38, 0.4), {"metallic_value": 0.4, "roughness_a": 0.45, "stain_amount": 0.4})
	m.call("l2_elevator", "metal", Color(0.66, 0.66, 0.64), Color(0.56, 0.56, 0.55), {"metallic_value": 0.45, "roughness_a": 0.3, "pattern": 2, "pattern_scale": Vector2(0.01, 1.0), "pattern_color": Color(0.6, 0.6, 0.58), "pattern_strength": 0.3})
	m.call("l2_plywood", "wood_floor", Color(0.72, 0.58, 0.38), Color(0.62, 0.48, 0.3), {"pattern": 0, "noise_scale": 6.0, "roughness_a": 0.9})
	m.call("l2_wood_aged", "wood_floor", Color(0.32, 0.22, 0.13), Color(0.22, 0.15, 0.09), {"stain_amount": 0.6, "stain_color": Color(0.12, 0.1, 0.07), "pattern_scale": Vector2(0.14, 2.0)})
	for c in [["r", Color(0.75, 0.14, 0.12)], ["o", Color(0.85, 0.45, 0.1)], ["y", Color(0.88, 0.78, 0.18)], ["g", Color(0.2, 0.6, 0.25)], ["b", Color(0.15, 0.32, 0.75)], ["v", Color(0.45, 0.2, 0.62)]]:
		m.call("l2_rb_" + c[0], "metal", c[1], (c[1] as Color).darkened(0.15), {"metallic_value": 0.2, "stain_amount": 0.35, "roughness_a": 0.6})
	m.call("l2_blade", "metal", Color(0.75, 0.76, 0.78), Color(0.6, 0.6, 0.62), {"metallic_value": 1.0, "roughness_a": 0.2})
	m.call("l2_wallpaper", "plaster", Color(0.62, 0.5, 0.42), Color(0.55, 0.43, 0.36), {"pattern": 10, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.48, 0.36, 0.3), "pattern_strength": 0.5})
	m.call("l2_carpet", "plaster", Color(0.42, 0.18, 0.15), Color(0.34, 0.14, 0.12), {"pattern": 6, "bump_strength": 0.6, "roughness_a": 1.0})
	m.call("l2_sofa", "plaster", Color(0.32, 0.38, 0.3), Color(0.26, 0.31, 0.24), {"bump_strength": 1.0})
	m.call("l2_painting", "plaster", Color(0.3, 0.42, 0.5), Color(0.62, 0.55, 0.35), {"noise_scale": 3.0})
	m.call("l2_lampshade", "plaster", Color(0.9, 0.82, 0.6), Color(0.85, 0.75, 0.55), {"emission_color": Color(1.0, 0.8, 0.5), "emission_energy": 1.2})
	m.call("l2_beige", "plaster", Color(0.74, 0.7, 0.6), Color(0.66, 0.62, 0.52), {"roughness_a": 0.5})
	m.call("l2_screen", "plaster", Color(0.04, 0.06, 0.05), Color(0.03, 0.04, 0.04), {"roughness_a": 0.1})
	m.call("l2_dirt", "dirt", Color(0.33, 0.25, 0.17), Color(0.24, 0.18, 0.12))
	m.call("l2_boiler", "rust", Color(0.35, 0.2, 0.12), Color(0.2, 0.12, 0.08), {"emission_color": Color(0.6, 0.12, 0.02), "emission_energy": 0.25})
	m.call("l2_sludge", "plaster", Color(0.12, 0.1, 0.06), Color(0.08, 0.07, 0.04), {"wetness": 1.0, "roughness_a": 0.2})
	m.call("l2_voidfloor", "void_black", Color(0.01, 0.01, 0.01), Color(0.0, 0.0, 0.0))
	m.call("l2_sign", "plaster", Color(0.78, 0.74, 0.62), Color(0.7, 0.66, 0.55), {"stain_amount": 0.6})
	m.call("l2_bulb", "plaster", Color(1, 1, 1), Color(1, 1, 1), {"emission_color": Color(1.0, 0.8, 0.5), "emission_energy": 4.0})
	MatLib.register("l2_tube_white", MatLib.panel(Color(0.9, 0.97, 1.0), 3.0))
	MatLib.register("l2_tube_amber", MatLib.panel(Color(1.0, 0.72, 0.38), 2.8))
	MatLib.register("l2_tube_dead", MatLib.panel(Color(0.1, 0.1, 0.1), 0.0, 0.0, 100.0))
	MatLib.register("l2_violet", MatLib.panel(Color(0.62, 0.3, 1.0), 1.6))
	MatLib.register("l2_amber", MatLib.panel(Color(1.0, 0.6, 0.2), 2.0))
	MatLib.register("l2_bluepulse", MatLib.panel(Color(0.25, 0.5, 1.0), 3.0, 1.0))
	MatLib.register("l2_fireglow", MatLib.panel(Color(1.0, 0.42, 0.1), 3.2, 0.3))
	MatLib.register("l2_doorway_glow", MatLib.panel(Color(1.0, 0.85, 0.6), 1.6))


# ------------------------------------------------------------------ lattice

static func pm(a: int, n: int) -> int:
	return ((a % n) + n) % n


func h01(a: int, b: int, salt: String) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func is_gallery(i: int, j: int) -> bool:
	return pm(i, 4) == 2 and pm(j, 3) == 0


## Junction kind: start | gallery | room | boiler | small.
func node_kind(i: int, j: int) -> String:
	if i == 0 and j == 0:
		return "start"
	if is_gallery(i, j):
		return "gallery"
	if (pm(i, 4) == 1 and pm(j, 3) == 1) or (pm(i, 4) == 3 and pm(j, 3) == 2) or (i == 1 and j == 0):
		return "small"   # low end of a maintenance stair (or kept small near the start)
	var h := h01(i, j, "kind")
	if h < 0.24:
		return "boiler" if (h01(i, j, "boil") < 0.3 and maxi(absi(i), absi(j)) >= 2) else "room"
	return "small"


func apothem(i: int, j: int) -> float:
	match node_kind(i, j):
		"gallery": return 7.5
		"start": return 5.0
		"room", "boiler": return 4.6
	return 3.2


func diag(bi: int, bj: int) -> int:
	if bi >= -1 and bi <= 2 and bj >= -1 and bj <= 0:
		return 0
	var h := h01(bi, bj, "diag")
	if h > 0.28:
		return 0
	var dv := 1 if h01(bi, bj, "dd") < 0.5 else -1
	if dv == 1 and is_gallery(bi, bj):
		return 0
	return dv


## Canonical slot from node (i,j) in direction k = 0 (+x), 1 (+x+z), 2 (+z), 3 (-x+z).
func edge_info(i: int, j: int, k: int) -> Dictionary:
	var key := Vector3i(i, j, k)
	if _ecache.has(key):
		return _ecache[key]
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "edge", i, j, k])
	var e := {"lo": false, "up": false, "stair": 0, "drop": 0, "tram": false, "seed": r.seed}
	match k:
		0:
			if pm(i + 1, 4) == 2 and pm(j, 3) == 1:
				e["stair"] = 1
			elif pm(i, 4) == 2 and pm(j, 3) == 2:
				e["stair"] = 2
			else:
				e["lo"] = pm(j, 3) == 0 or r.randf() < 0.45
				var east := pm(i, 4) == 2 and r.randf() < 0.5
				var west := pm(i + 1, 4) == 2 and r.randf() < 0.5
				e["up"] = pm(j, 3) == 0 and (east or west)
			e["tram"] = j == 0 and i < 0
		2:
			e["lo"] = pm(i, 4) == 0 or pm(j, 3) != 1 or r.randf() < 0.35
			e["up"] = pm(i, 4) == 2
		1:
			e["lo"] = diag(i, j) == 1
		3:
			e["lo"] = diag(i - 1, j) == -1
	var wr := r.randf()
	var w := 1.3 if wr < 0.22 else (1.7 if wr < 0.62 else (2.1 if wr < 0.87 else 2.5))
	if k % 2 == 1 or (e["up"] and not e["lo"]):
		w = minf(w, 2.1)
	if e["tram"]:
		w = 2.5
	e["w"] = w
	e["hl"] = [2.6, 2.8, 3.0][r.randi() % 3]
	if e["lo"] and e["up"] and r.randf() < 0.35:
		e["drop"] = 1 + r.randi() % 2
	var wr2 := r.randf()
	e["wall"] = "l2_wall" if wr2 < 0.66 else ("l2_block" if wr2 < 0.85 else "l2_brick")
	# pipe bundles per wall, shared by both halves so runs stay continuous
	e["spec_l"] = _spec(r, w, e["tram"], 3.7)
	e["spec_r"] = _spec(r, w, e["tram"], 3.7)
	e["spec_u"] = _spec(r, w, false, HU)
	_ecache[key] = e
	return e


func _spec(r: RandomNumberGenerator, w: float, tram: bool, top: float) -> Array:
	var mats := ["l2_pipe_rust", "l2_pipe_green", "l2_steel", "l2_insul", "l2_copper", "l2_pipe_yellow"]
	var n := 1 if tram else (2 + r.randi() % 2 if w < 1.5 else 3 + r.randi() % 4)
	var out: Array = []
	var y := r.randf_range(0.4, 0.9)
	for i in n:
		var rad := r.randf_range(0.03, 0.08) if w < 1.5 else r.randf_range(0.04, 0.2)
		y += rad
		if y + rad > top - 0.2:
			break
		out.append([y, rad, mats[r.randi() % mats.size()]])
		y += rad + r.randf_range(0.08, 0.5)
	return out


## The half of the corridor leaving node (i,j) in direction k (0..7).
func half_info(i: int, j: int, k: int) -> Dictionary:
	var dv := G.dvec(k)
	var e: Dictionary
	var me := 1
	if k < 4:
		e = edge_info(i, j, k)
	else:
		e = edge_info(i + roundi(dv.x), j + roundi(dv.z), k - 4)
		me = 2
	var mode := ""
	if int(e["stair"]) != 0:
		mode = "stair" if int(e["stair"]) == me else "up"
	elif e["lo"] and e["up"]:
		mode = "stack"
	elif e["lo"]:
		mode = "lo"
	elif e["up"]:
		mode = "up"
	var h := e.duplicate()
	h["mode"] = mode
	h["drop"] = int(e["drop"]) == me
	h["len"] = S * 0.5 * (sqrt(2.0) if k % 2 == 1 else 1.0)
	return h


# ---------------------------------------------------------------- lighting

func circuit_of(p: Vector3, deck: int) -> String:
	return "%d,%d,%d" % [floori(p.x / 35.0), floori(p.z / 35.0), deck]


## Base character of a series circuit: white | amber | brown (brownout).
func circuit_base(cid: String) -> String:
	var parts := cid.split(",")
	var a := int(parts[0])
	var b := int(parts[1])
	var h := h01(a * 7 + int(parts[2]), b, "circ")
	if h < 0.14 and absi(a) + absi(b) > 1:
		return "brown"
	return "amber" if h > 0.62 else "white"


## A ceiling fixture on its series circuit (kit per circuit per chunk so a
## whole circuit can go dark at once).
func fixture(ctx: Dictionary, pos: Vector3, d: Vector3, deck: int, hang: float) -> void:
	var k: GeoKit = ctx["k"]
	var cid := circuit_of(pos, deck)
	var base := circuit_base(cid)
	var hp := float(absi(hash([level_seed, pos.snapped(Vector3.ONE * 0.1)])) % 1000) / 1000.0
	if base == "brown" and hp > 0.25:
		P.batten(k, k, pos, d, "l2_tube_dead", 0.0, 0.0, hang)
		return
	if not ctx["lk"].has(cid):
		ctx["lk"][cid] = GeoKit.new(ctx["node"], "L_" + cid.replace(",", "_"))
		(ctx["lk"][cid] as GeoKit).shadows = false
	var on: bool = sys.circuit_on(cid)
	var amber := base == "amber"
	var fl := 0.8 if hp < 0.07 else 0.0
	P.batten(k, ctx["lk"][cid], pos, d, ("l2_tube_amber" if amber else "l2_tube_white") if on else "l2_tube_dead", hp * 50.0, fl, hang)
	var col := Color(1.0, 0.74, 0.45) if amber else Color(0.86, 0.93, 1.0)
	var e0 := 1.25 if base != "brown" else 0.9
	var idx := lights.add_anchor(pos + Vector3.DOWN * 0.35, col, e0 if on else 0.0, 7.5, fl, ctx["g"])
	lights.anchors[idx]["cid"] = cid
	lights.anchors[idx]["e0"] = e0
	ctx["meta"]["fixtures"].append(pos)


## Violet emergency lamp (appeared during the blackout; brownout areas).
func violet(ctx: Dictionary, pos: Vector3, out: Vector3) -> void:
	var k: GeoKit = ctx["k"]
	P.obox(k, pos, out, Vector3(0.3, 0.14, 0.1), "l2_fixture")
	k.quad(pos + out * 0.051, out, Vector3.UP.cross(out).normalized() * 0.12, Vector3.UP * 0.05, "l2_violet")
	lights.add_anchor(pos + out * 0.4, Color(0.55, 0.32, 0.95), 0.35, 6.0, 0.0, ctx["g"])


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, "l2"])
	var k := GeoKit.new(node, "K")
	var meta := {"kind": node_kind(cx, cz), "fixtures": [], "drops": [], "tight": [], "heat": [], "doors": 0, "has_up": false}
	var ctx := {"k": k, "r": r, "node": node, "g": "%d,%d" % [cx, cz], "lk": {}, "meta": meta}
	var C := Vector3(cx * S + S * 0.5, 0.0, cz * S + S * 0.5)
	var a := apothem(cx, cz)
	var kind: String = meta["kind"]
	var halves: Array = []
	for d in 8:
		halves.append(half_info(cx, cz, d))
	var plan: Dictionary = sys.plan_chunk(cx, cz, C, a, halves, r)
	# --- junction faces (stacked openings), then the junction itself
	var has_up := false
	for d in 8:
		if halves[d]["mode"] in ["up", "stack"]:
			has_up = true
	if plan["up_face_doors"].size() > 0:
		has_up = true
	meta["has_up"] = has_up
	var faces: Array = []
	var gallery := kind == "gallery"
	for d in 8:
		var h: Dictionary = halves[d]
		var md: String = h["mode"]
		var ops: Array = []
		if md in ["lo", "stack", "stair"]:
			var lh := (3.4 if md != "lo" else float(h["hl"]) - 0.1) if gallery else minf(float(h["hl"]) if md == "lo" else HO, HO) - 0.15
			ops.append({"w": h["w"], "sill": 0.0, "h": lh})
		if md in ["up", "stack"]:
			ops.append({"w": h["w"], "sill": DY, "h": HU - 0.15})
		for fd in plan["face_doors"]:
			if int(fd["dir"]) == d:
				ops.append({"w": fd["w"], "sill": DY if fd["deck"] == "up" else 0.0, "h": fd["h"]})
		var top := G.GH if gallery else (DY + HU if (has_up or md in ["stack", "stair"]) else HO)
		faces.append({"ops": ops, "top": top})
	var wall_mat := "l2_brick" if h01(cx, cz, "jw") < 0.15 else "l2_wall"
	G.junction(ctx, C, a, faces, gallery, has_up, wall_mat)
	# --- corridor halves
	for d in 8:
		var h: Dictionary = halves[d]
		if h["mode"] == "":
			continue
		G.tube(self, ctx, C, d, a, float(h["len"]), h, plan["tube_doors"][d])
		if float(h["w"]) <= 1.35 and h["mode"] != "up":
			meta["tight"].append([C + G.dvec(d) * a, C + G.dvec(d) * float(h["len"]), float(h["w"])])
		sys.dress_tube(ctx, C, d, a, h, plan["tube_doors"][d])
	# --- junction dressing and lights
	if gallery:
		var ups: Array = []
		var los: Array = []
		for d in 8:
			if halves[d]["mode"] in ["up", "stack"]:
				ups.append(d)
			if halves[d]["mode"] in ["lo", "stack", "stair"]:
				los.append(d)
		for fd in plan["face_doors"]:
			if fd["deck"] == "up" and not ups.has(int(fd["dir"])):
				ups.append(int(fd["dir"]))
		G.gallery_interior(self, ctx, C, a, ups, los)
	else:
		fixture(ctx, C + Vector3.UP * (HO - 0.1), Vector3(1, 0, 0), 0, 0.0)
		for d in 8:   # service pipes cross the junction ceiling between its corridors
			if halves[d]["mode"] in ["lo", "stack"] and halves[(d + 4) % 8]["mode"] in ["lo", "stack"] and d < 4:
				var dv := G.dvec(d)
				var sd: Vector3 = P.frame(dv).x
				for i in 2:
					var y := HO - 0.22 - i * 0.24
					P.pipe(k, C - dv * a + sd * (0.7 + i * 0.3) + Vector3.UP * y, C + dv * a + sd * (0.7 + i * 0.3) + Vector3.UP * y, 0.06 + i * 0.04, ["l2_pipe_rust", "l2_insul"][i], 10)
		if has_up:
			fixture(ctx, C + Vector3.UP * (DY + HU - 0.1), Vector3(0, 0, 1), 1, 0.0)
		match kind:
			"room":
				G.centre_machine(ctx, C)
			"boiler":
				G.boiler(ctx, C)
				meta["heat"].append(C)
			"start":
				sys.dress_start(ctx, C, a)
	if circuit_base(circuit_of(C, 0)) == "brown":
		violet(ctx, C + G.dvec(plan["violet_dir"]) * (a - 0.06) + Vector3.UP * 2.3, -G.dvec(plan["violet_dir"]))
	sys.build_doors(ctx, C, a, halves, plan)
	k.commit()
	for cid in ctx["lk"].keys():
		var kl: GeoKit = ctx["lk"][cid]
		kl.commit()
		if not circ_meshes.has(cid):
			circ_meshes[cid] = []
		for ch in kl.root.get_children():
			if ch is MeshInstance3D:
				circ_meshes[cid].append(ch)
	meta["boxes"] = k.stats["boxes"]
	return meta


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	sys.on_ready()


func level_process(delta: float) -> void:
	if player != null:
		sys.tick(delta)


func qa_capture_plan() -> Array:
	return sys.capture_plan()


func qa_self_test() -> Array:
	return await sys.self_test()
