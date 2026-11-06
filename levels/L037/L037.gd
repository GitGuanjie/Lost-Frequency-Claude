extends LevelBase
## Level 37 — "Sublimity" (Backrooms Wikidot rev 52, accessed 2026-11-04; cite:
## egglord, CC BY-SA 3.0). Dossier: docs/canon/levels/L037.md. Every mechanic
## maps to a dossier SOURCE FACT row or is labelled ADAPTATION in level.json.
##
## An expansive complex of white-tiled rooms and corridors submerged in
## lukewarm blue-green water. The playable world is a finite streaming window of
## 32 m chunks (ChunkWorld); the page's "immense size" is never simulated.
## Hub (hand-authored, chunks (0,0) and (1,0)):
##   Grand Pool Hall — dry spawn alcove, a pillar lattice standing in a two-depth
##     pool, light wells and a high slit at irregular angles, underwater lamps,
##     a lightless west corner whose enclosed tunnel may lead to Level 43.
##   Stair Pit — a grand staircase descending straight into a 7 m pit of water.
## Procedural grammar (2 m cells, L037_cells.gd / L037_kinds.gd): hall, corridor
##   (some are ledgeless swim lanes), pit, flooded pillar forest, open
##   (abnormally shaped, terraced basins), dark (low rooms + enclosed tunnels).
## Stateful systems: Epsom-salt relaxation (soaking heals and restores stamina),
##   wading drag from true water depth, altered acoustics (no reverberation,
##   noises cut off, a water bed that is calm or — rarely — obtrusive), and an
##   immersion roll that may resurface you in Level 130.
## Entities: none ("entirely devoid of life"). No NPCs, notes or outposts.

const Cells := preload("res://levels/L037/L037_cells.gd")
const Kinds := preload("res://levels/L037/L037_kinds.gd")
const Water := preload("res://levels/L037/L037_water.gd")
const CS := 32.0
const WALK := -0.18
const DRY := 0.35
const AMB := 0.12
const SKY_COL := Color(0.93, 0.99, 1.0)
const UW_COL := Color(0.45, 0.92, 1.0)
const IMMERSE_S := 7.0
const HUB := {Vector2i(0, 0): "hub_hall", Vector2i(1, 0): "hub_pit"}
## Fixed openings around the authored hub: "ax,az,axis" -> [[t0, width, ceiling]].
const HUB_BORDERS := {
	"-1,0,x": [], "0,-1,z": [[8, 2, 3.6]], "0,0,z": [[10, 2, 3.6]], "0,0,x": [[6, 3, 4.4]],
	"1,-1,z": [[4, 2, 3.4]], "1,0,x": [[9, 2, 3.6]], "1,0,z": [[11, 2, 3.4]],
}

var world: ChunkWorld
var qa_fixture := false
var _arng := RandomNumberGenerator.new()    # runtime audio/roll stream (seeded)
var _bed: AudioStreamPlayer
var _deep_bed: AudioStreamPlayer
var _obtrusive := false
var _swell := 0.0
var _swell_hold := 0.0
var _swell_t := 50.0
var _drop := 0.0
var _drop_t := 35.0
var _feet_was := false
var _feet_cut := -1.0
var _soak := 0.0
var _relax_msg := 0
var _under_t := 0.0
var _rolled := false
var _held_msg := false
var _cab_trigger: ExitTrigger
var _saved_aa: Array = []


func build() -> void:
	qa_fixture = SessionState.is_qa()
	# Workaround (framework need): with the project's 2x MSAA, hint_depth_texture
	# reads empty under transparent materials, so water absorption saturates and
	# every pool renders opaque. While Level 37 is loaded: no MSAA, FXAA instead.
	var vp := get_viewport()
	_saved_aa = [vp.msaa_3d, vp.screen_space_aa]
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_arng.seed = hash([level_seed, "acoustics"])
	_obtrusive = _arng.randf() < 0.15          # rarer explorations: obtrusive water
	rules["flashlight"] = "allowed"
	rules["reverb_room"] = 0.9                 # a vast tiled hall...
	rules["reverb_wet"] = 0.02                 # ...that does not reverberate as it should
	rules["view_distance"] = 160.0
	indoor_env(Color(0.80, 0.92, 0.95), AMB, Color(0.62, 0.74, 0.77), 0.0045)
	environment.background_color = Color(0.92, 0.97, 1.0)
	environment.background_energy_multiplier = 2.6
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.32
	environment.glow_bloom = 0.03
	environment.glow_hdr_threshold = 1.15
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.06
	environment.adjustment_contrast = 1.1
	# Light from irregular angles: a steep, oblique key light that only reaches
	# the rooms through open wells; every unopened room relies on fill light.
	sun = DirectionalLight3D.new()
	sun.name = "WellLight"
	sun.rotation_degrees = Vector3(-63.0, 28.0, 0.0)
	sun.light_color = Color(1.0, 0.99, 0.96)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.ssr_enabled = Settings.quality() >= 2
	environment.ssr_max_steps = 48
	environment.ssr_fade_in = 0.1
	environment.ssr_fade_out = 2.5
	_materials()
	lights.setup(14, 0)
	lights.max_distance = 38.0
	# QA fixture first so the walker bot targets it: the hub tunnel always
	# leads in QA; in a story/developer run it leads only on some seeds ("may").
	if qa_fixture or _h01(0, 0, 4301) < 0.6:
		add_exit("L037>L043#2", "walk_in", Vector3(3.0, 0.95, 5.1), Vector3(1.9, 2.3, 2.0), "")
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", Vector3(8.0, DRY + 0.05, 27.0), -45.0)
	add_arrival("from_L025", Vector3(28.6, WALK + 0.05, 4.8), 135.0)
	world.build_around(Vector3(8.0, 0, 27.0), 2)
	if TransitionService.pending_arrival == "from_L025":
		_arcade_return()
	# --- sound: muffled water, near-silence; no sound lingers or reverberates
	_bed = sound.bed("water_bed", {"bright": 620.0}, -21.0)
	sound.bed("room_tone", {"cutoff": 140.0}, -33.0)
	_deep_bed = sound.bed("water_bed", {"bright": 240.0, "seconds": 7.0}, -60.0)
	add_shot("hall", Vector3(7.2, DRY + 1.62, 28.4), Vector3(22.0, 1.6, 10.0))
	add_shot("pit", Vector3(40.9, Kinds.LEDGE + 1.62, 14.2), Vector3(53.0, -4.4, 15.8))
	add_landmark("Spawn alcove, Grand Pool Hall", Vector3(8.0, DRY, 27.0))
	add_landmark("The Stair Pit", Vector3(48.0, WALK, 16.0))


func _materials() -> void:
	# Identical, pristine, shiny white ceramic tiles (no variation, no grime);
	# animated caustics on every surface below the water line.
	MatLib.define("l37_tile", {"albedo_a": Color(0.95, 0.965, 0.965), "albedo_b": Color(0.93, 0.95, 0.95),
		"pattern": 1, "pattern_scale": Vector2(0.24, 0.24), "grout_width": 0.008, "grout_color": Color(0.80, 0.85, 0.86),
		"roughness_a": 0.05, "roughness_b": 0.09, "tile_variation": 0.0, "noise_scale": 0.15, "bump_strength": 0.3,
		"caustics": 0.6, "water_y": 0.0}, "pool_tile")
	MatLib.define("l37_tile_ceil", {"albedo_a": Color(0.93, 0.95, 0.95), "albedo_b": Color(0.91, 0.93, 0.93),
		"pattern": 1, "pattern_scale": Vector2(0.24, 0.24), "grout_width": 0.008, "grout_color": Color(0.80, 0.85, 0.86),
		"roughness_a": 0.34, "roughness_b": 0.46, "tile_variation": 0.0, "noise_scale": 0.15, "bump_strength": 0.3}, "pool_tile")
	MatLib.register("l37_water", Water.material())
	if OS.get_environment("L37_WDEBUG") != "":
		(MatLib.get_mat("l37_water") as ShaderMaterial).set_shader_parameter("debug_mode", int(OS.get_environment("L37_WDEBUG")))
	MatLib.register("l37_panel_sky", MatLib.standard(Color(1, 1, 1), 1.0, 0.0, SKY_COL, 7.0))
	MatLib.register("l37_panel_uw", MatLib.standard(Color(0.8, 1, 1), 1.0, 0.0, UW_COL, 4.0))


# ------------------------------------------------------------ layout rules

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func _vnoise(x: float, z: float) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	return lerpf(lerpf(_h01(ix, iz, 7), _h01(ix + 1, iz, 7), fx), lerpf(_h01(ix, iz + 1, 7), _h01(ix + 1, iz + 1, 7), fx), fz)


func kind_of(cx: int, cz: int) -> String:
	var key := Vector2i(cx, cz)
	if HUB.has(key):
		return HUB[key]
	var h := _h01(cx, cz, 11)
	if _vnoise(cx * 0.41 + 0.3, cz * 0.41 + 0.7) > 0.70:
		return "pillars"
	if h < 0.20:
		return "corridor"
	if h < 0.32:
		return "pit"
	if h < 0.44:
		return "dark"
	if h < 0.60:
		return "open"
	return "hall"


func _axis_of(cx: int, cz: int) -> String:
	return "x" if _h01(cx, cz, 13) < 0.5 else "z"


## Openings on the border between chunk (ax,az) and its +X ("x") or +Z ("z")
## neighbour, as [[first cell, width, passage ceiling]]. Depends only on the
## border identity and both kinds, so either side computes the same answer.
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
		var t0 := 2 + r.randi() % (Cells.N - 3 - w)
		var ok := true
		for o in out:
			if t0 <= int(o[0]) + int(o[1]) and int(o[0]) <= t0 + w:
				ok = false
		if ok:
			out.append([t0, w, pc])
	return out


## Carve every border passage (perimeter cell) and its landing (next cell in),
## lock them, and return the opening list for painters.
func _openings(g, cx: int, cz: int) -> Array:
	var ops: Array = []
	var n := Cells.N
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
							c = Vector2i(n - 1 - depth, t)
						"n":
							c = Vector2i(t, depth)
						_:
							c = Vector2i(t, n - 1 - depth)
					g.setc(c.x, c.y, WALK, float(o[2]), true)
					g.lock_cell(c.x, c.y)
			ops.append({"side": side, "t0": int(o[0]), "w": int(o[1]), "ceil": float(o[2])})
	return ops


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, 37])
	var g = Cells.new()
	var ops := _openings(g, cx, cz)
	var meta := {"kind": kind}
	match kind:
		"hub_hall":
			Kinds.hub_hall(g, meta)
		"hub_pit":
			Kinds.hub_pit(g, meta)
		"corridor":
			Kinds.corridor(g, r, ops, _axis_of(cx, cz), meta, not qa_fixture and _h01(cx, cz, 233) < 0.12)
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
	var ox := cx * CS
	var oz := cz * CS
	var group := "%d,%d" % [cx, cz]
	var k := GeoKit.new(node, "K")
	g.emit(k, ox, oz, "l37_tile", "l37_tile_ceil")
	g.emit_stairs(k, ox, oz, "l37_tile")
	g.emit_pillars(k, ox, oz, "l37_tile")
	_emit_lights(g, k, ox, oz, group)
	k.commit()
	var wv := WaterVolume.new()
	wv.name = "Water"
	node.add_child(wv)
	wv.setup(Vector3(ox, Cells.BASE, oz), Vector3(ox + CS, 0.0, oz + CS), "l37_water", true)
	wv.tint = Color(0.10, 0.52, 0.54)
	meta["min_floor"] = g.min_floor()
	_chunk_exits(kind, cx, cz, node, meta)
	meta["boxes"] = k.stats["boxes"]
	return meta


func _emit_lights(g, k: GeoKit, ox: float, oz: float, group: String) -> void:
	var o := Vector3(ox, 0, oz)
	for L in g.lights:
		var t: String = L["t"]
		if t == "sky":
			var x0: float = L["x0"]
			var x1: float = L["x1"]
			var z0: float = L["z0"]
			var z1: float = L["z1"]
			var low: float = L["low"]
			var c := o + Vector3((x0 + x1) * 0.5, float(L["y"]) - 0.02, (z0 + z1) * 0.5)
			lights.add_anchor(Vector3(c.x, low - 1.0, c.z), SKY_COL, float(L["e"]) * 1.4, low * 1.5 + 3.0, 0.0, group)
		elif t == "slit":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			var along := Vector3(-n.z, 0, n.x)
			k.quad(p, n, along * float(L["len"]) * 0.5, Vector3(0, float(L["h"]) * 0.5, 0), "l37_panel_sky", Vector2.ZERO, true)
			lights.add_anchor(p + n * 2.2, SKY_COL, float(L["e"]) * 1.3, 13.0, 0.0, group)
		elif t == "uw":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			var along := Vector3(-n.z, 0, n.x)
			k.quad(p, n, along * 0.32, Vector3(0, 0.2, 0), "l37_panel_uw", Vector2.ZERO, true)
			lights.add_anchor(p + n * 0.9, UW_COL, float(L["e"]), 8.5, 0.0, group)
		elif t == "panel":
			var c := o + Vector3(float(L["x"]), float(L["y"]) - 0.02, float(L["z"]))
			if not L.get("dead", false):
				k.quad(c, Vector3.DOWN, Vector3(0.55, 0, 0), Vector3(0, 0, 0.55), "l37_panel_sky", Vector2.ZERO, true)
			if float(L["e"]) > 0.0:
				lights.add_anchor(c + Vector3.DOWN * 0.7, SKY_COL, float(L["e"]), 9.0, 0.0, group)
		elif t == "tilt":
			var p: Vector3 = o + L["p"]
			var n: Vector3 = L["n"]
			k.quad(p, n, L["hu"], L["hv"], "l37_panel_sky", Vector2.ZERO, true)
			lights.add_anchor(p + n * 2.5, SKY_COL, float(L["e"]), 20.0, 0.0, group)


## Sourced exits inside streamed chunks. QA mode keeps only the deterministic
## hub (pit immersion); procedural exits exist in story/developer runs.
func _chunk_exits(kind: String, cx: int, cz: int, node: Node3D, meta: Dictionary) -> void:
	var o := Vector3(cx * CS, 0, cz * CS)
	var deep: bool = float(meta.get("min_floor", 0.0)) <= -1.2
	if (kind == "hub_pit") or (not qa_fixture and deep):
		var t := make_exit("L037>L130#1", "condition", o + Vector3(CS * 0.5, Cells.BASE * 0.5, CS * 0.5),
			Vector3(CS - 0.2, -Cells.BASE, CS - 0.2), "", node)
		if t:
			t.condition = _immersion_ready
	if qa_fixture:
		return
	var tun: Array = meta.get("tunnel_ends", [])
	for i in tun.size():
		if _h01(cx, cz, 43 + i) < 0.45:
			var e: Vector3 = o + tun[i]
			make_exit("L037>L043#2", "walk_in", e + Vector3(0, 1.1, 0), Vector3(1.8, 2.0, 1.8), "", node)
			# ADAPTATION affordance: a faint draft breathes from tunnels that lead on
			var draft := AudioStreamPlayer3D.new()
			draft.stream = AudioSynth.get_stream("wind", {"seconds": 6.0})
			draft.volume_db = -22.0
			draft.max_distance = 10.0
			draft.bus = "Ambience"
			draft.autoplay = true
			draft.position = e + Vector3(0, 1.2, 0)
			node.add_child(draft)
	if meta.has("branch_end"):
		var b: Vector3 = o + meta["branch_end"]
		make_exit("L037>L233#3", "walk_in", b + Vector3(0, 1.1, 0), Vector3(1.8, 2.2, 1.8), "", node)


func _immersion_ready() -> bool:
	if player == null or not player.head_under or _under_t < IMMERSE_S or _rolled:
		return false
	_rolled = true
	return _arng.randf() < 0.45


## ADAPTATION (cross-page): Level 25's page says a tethered arcade trip is
## two-way, with another machine behind the arriving wanderer or within ~100 ft.
## Built only for arcade arrivals; needs a quarter, like every Level 25 cabinet.
func _arcade_return() -> void:
	MatLib.define("l37_cab", {"albedo_a": Color(0.16, 0.06, 0.07), "albedo_b": Color(0.10, 0.04, 0.05),
		"stain_amount": 0.6, "stain_color": Color(0.30, 0.24, 0.2), "roughness_a": 0.6, "roughness_b": 0.9, "caustics": 0.0}, "concrete")
	MatLib.register("l37_cab_panel_screen", MatLib.standard(Color(0.1, 0.2, 0.25), 0.4, 0.0, Color(0.35, 0.8, 1.0), 1.4))
	var k := kit("ArcadeCabinet")
	var b := Vector3(29.2, WALK, 2.45)
	k.box(b + Vector3(0, 0.95, 0), Vector3(0.74, 1.9, 0.8), "l37_cab")
	k.box(b + Vector3(0, 2.0, 0.06), Vector3(0.76, 0.22, 0.7), "l37_cab")
	k.box(b + Vector3(0, 1.0, 0.5), Vector3(0.7, 0.1, 0.32), "l37_cab")
	k.quad(b + Vector3(0, 1.45, 0.405), Vector3(0, 0, 1), Vector3(0.27, 0, 0), Vector3(0, 0.2, 0), "l37_cab_panel_screen", Vector2.ZERO, true)
	k.commit()
	_cab_trigger = add_exit("L037>L025#A1", "interact", b + Vector3(0, 1.0, 0.9), Vector3(1.4, 2.0, 1.2), "")
	if _cab_trigger:
		_cab_trigger.condition = func() -> bool: return SaveService.item_count("quarter") > 0
		_cab_trigger.fired.connect(func(_e: String) -> void: SaveService.add_item("quarter", -1))
		add_interactable(b + Vector3(0, 1.3, 0.42), Vector3(0.75, 1.0, 0.12), "Insert a quarter and play", _use_cabinet)


func _use_cabinet(p: Player) -> void:
	if SaveService.item_count("quarter") <= 0:
		Overlay.toast("The cabinet behind you still hums, but you have no quarter to put in it.", 3.5)
		return
	_cab_trigger.interact(p)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	Settings.set_reverb(0.9, 0.02, 1.0)
	player.feet_audio.volume_db = -14.0
	player.feet_audio.max_distance = 7.0
	Overlay.subtitle("[You feel a calming sensation.]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L037>L043#2", "target": Vector3(3.0, -0.2, 5.0),
			"note": "QA fixture: the enclosed dark tunnel in the hall's west wall always leads"})


func _exit_tree() -> void:
	Overlay.set_screen_effect("vignette", 0.25)
	if _saved_aa.size() == 2:
		var vp := get_viewport()
		vp.msaa_3d = _saved_aa[0]
		vp.screen_space_aa = _saved_aa[1]


func _in_hub_tunnel(p: Vector3) -> bool:
	return p.x > 1.9 and p.x < 6.1 and p.z > 3.9 and p.z < 24.1 and (p.x < 4.0 or p.z > 22.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var meta := world.meta_of(world.key_at(p))
	var dark: bool = meta.get("dark", false) or _in_hub_tunnel(p)
	var lerp_k := clampf(delta * 1.2, 0.0, 1.0)
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, 0.025 if dark else AMB, lerp_k)
	environment.fog_light_energy = lerpf(environment.fog_light_energy, 0.05 if dark else 1.0, lerp_k)
	# --- true water depth at the body: the surface is y = 0 everywhere here
	var depth := maxf(0.0, -p.y)
	if not player.swimming:
		var drag := clampf(1.0 - depth * 0.6, 0.55, 1.0)
		player.walk_speed = 3.1 * drag
		player.sprint_speed = 5.3 * drag
	# --- Epsom salt: extended soaking relieves muscles and bodily pain
	if depth > 0.7 or player.swimming:
		_soak = minf(_soak + delta, 120.0)
	else:
		_soak = maxf(0.0, _soak - delta * 0.2)
	var relax := smoothstep(8.0, 45.0, _soak)
	if relax > 0.0:
		player.heal(delta * 2.0 * relax)
		player.stamina = minf(player.stamina_max, player.stamina + delta * 0.6 * relax)
	Overlay.set_screen_effect("vignette", lerpf(0.25, 0.08, relax))
	if relax > 0.3 and _relax_msg == 0:
		_relax_msg = 1
		Overlay.subtitle("[the lukewarm water loosens every aching muscle]", 4.0)
	elif relax > 0.95 and _relax_msg == 1:
		_relax_msg = 2
		Overlay.subtitle("[a deep, weightless calm]", 4.0)
	# --- immersion: stay fully under long enough and you may resurface elsewhere
	if player.head_under:
		_under_t += delta
		if _under_t > 4.0 and not _held_msg:
			_held_msg = true
			Overlay.subtitle("[the warm water holds you in total silence]", 3.0)
	else:
		_under_t = 0.0
		_rolled = false
		_held_msg = false
	_acoustics(delta, depth)


## Altered sound: no reverberation (bus reverb near dry), noises that suddenly
## drop off, and a water bed that is usually quiet but on rarer explorations
## swells until it drowns out everything else.
func _acoustics(delta: float, depth: float) -> void:
	var fa := player.feet_audio
	if fa.playing and not _feet_was:
		_feet_cut = _arng.randf_range(0.04, 0.11) if _arng.randf() < 0.5 else -1.0
	_feet_was = fa.playing
	if _feet_cut > 0.0:
		_feet_cut -= delta
		if _feet_cut <= 0.0:
			fa.stop()
	if _obtrusive:
		_swell_t -= delta
		if _swell_t <= 0.0:
			_swell_t = _arng.randf_range(50.0, 100.0)
			_swell_hold = _arng.randf_range(12.0, 24.0)
			Overlay.subtitle("[the sound of the water swells until it drowns out everything]", 4.5)
		_swell_hold = maxf(0.0, _swell_hold - delta)
		_swell = move_toward(_swell, 1.0 if _swell_hold > 0.0 else 0.0, delta * 0.12)
	_drop_t -= delta
	if _drop_t <= 0.0:
		_drop_t = _arng.randf_range(45.0, 110.0)
		_drop = _arng.randf_range(0.8, 2.2)
		Overlay.subtitle("[every sound drops away]", 2.0)
	_drop = maxf(0.0, _drop - delta)
	if _drop > 0.0:
		_bed.volume_db = -80.0
		_deep_bed.volume_db = -80.0
	else:
		_bed.volume_db = lerpf(_bed.volume_db, -21.0 + 19.0 * _swell, clampf(delta * 3.0, 0.0, 1.0))
		var deep_db := -60.0 + 34.0 * clampf((depth - 0.6) / 1.5, 0.0, 1.0)
		_deep_bed.volume_db = lerpf(_deep_bed.volume_db, deep_db, clampf(delta * 2.0, 0.0, 1.0))
	fa.volume_db = -14.0 - 18.0 * _swell


const ITER_SHOTS := true   # TEMP iteration views; removed before commit


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	if not ITER_SHOTS:
		return plan
	plan.append({"name": "corner", "pos": Vector3(13.0, -0.18 + 1.62, 16.0), "target": Vector3(3.0, 0.8, 21.0)})
	plan.append({"name": "wells", "pos": Vector3(13.0, -0.18 + 1.62, 24.0), "target": Vector3(22.0, 8.5, 9.0)})
	for kind in ["hall", "pit", "pillars", "open", "corridor"]:
		for dz in range(-2, 3):
			for dx in range(-2, 3):
				if kind_of(dx, dz) == kind and not plan.any(func(s): return s["name"] == kind):
					var o := Vector3(dx * CS, 0, dz * CS)
					plan.append({"name": kind, "pos": o + Vector3(5.0, 3.0, 5.0), "target": o + Vector3(20.0, -0.5, 18.0)})
	return plan
