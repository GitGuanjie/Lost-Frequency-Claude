extends LevelBase
## Level 0 — "Threshold" (Backrooms Wikidot rev 50, accessed 2026-11-04; cite:
## DivineAtlas, DrAkimoto, RobertGoerman, CC BY-SA 3.0). Dossier:
## docs/canon/levels/L000.md. Every mechanic below maps to a SOURCE FACT row.
##
## Grammar: seeded 24 m chunks of 3 m cells streamed around the player.
##  normal   – randomly segmented rooms, halls, doorways, occasional sunken
##             room with stairs ("rooms, hallways, and stairs")
##  pillars  – lattice of pillars spanning regions, drier carpet; shifts
##  arches   – pale walls with archways, deep wet carpet; STABLE (never shifts),
##             resting there sets a checkpoint; flickering walls favour arches
##  holes    – grid of pitch-black pits; falling in is fatal (no survivors)
##  blackout – no light, rough walls, silence, recessed floor with ankle-deep
##             fluid; the buzz you follow does not stay in one place
##  red      – Red Rooms: fringe chunks peel to crimson with sticky carpet; a
##             fully entered red section seals into a closed loop (fail state)
## Peripheral Shift: unobserved chunks re-randomise (ChunkWorld.shift_enabled).
## Exit (SOURCE): "find a flickering wall to throw yourself through" -> Level 1.
## Entities: none spawned (page: existence unknown). Isolation: no NPCs.

const CS := 24.0
const CELL := 3.0
const N := 8
const H := 2.75
const T := 0.16

var world: ChunkWorld
var hum: AudioStreamPlayer
var _hum_db := -13.0
var _surge_t := 45.0
var _surge := 0.0
var _kind_here := "normal"
var _blackout_buzz: AudioStreamPlayer3D
var _heart: AudioStreamPlayer
var _red_sealed_key := Vector2i(999999, 999999)
var _red_timer := 0.0
var _rest_t := 0.0
var _rest_cooldown := 0.0
var _exits_built: Dictionary = {}
var qa_fixture := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.32
	rules["reverb_wet"] = 0.10
	rules["view_distance"] = 120.0
	indoor_env(Color(0.96, 0.86, 0.58), 0.30, Color(0.52, 0.46, 0.28), 0.011)
	environment.fog_light_energy = 1.0
	environment.tonemap_exposure = 0.92
	environment.glow_intensity = 0.16
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.06
	_materials()
	lights.setup(12, 1)
	lights.max_distance = 26.0
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	world.can_shift = _can_shift
	world.shift_enabled = true
	world.shift_after = 8.0
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", Vector3(10.5, 0.05, 10.5), -90.0)
	world.build_around(Vector3(10.5, 0, 10.5), 2)
	# --- audio: ballast buzz with random severe swells; rare sounds in the walls
	hum = sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.4}, _hum_db)
	sound.bed("room_tone", {"cutoff": 260.0}, -26.0)
	sound.oneshot("scratch", {}, 55.0, 150.0, 5.0, "[scratching behind the wall]", -16.0)
	sound.oneshot("whisper", {}, 120.0, 320.0, 8.0, "[indistinct whispering]", -20.0)
	_heart = AudioStreamPlayer.new()
	_heart.stream = AudioSynth.get_stream("heartbeat", {})
	_heart.bus = "SFX"
	_heart.volume_db = -60.0
	add_child(_heart)
	_heart.play()
	_blackout_buzz = sound.emitter("fluorescent_hum", Vector3.ZERO, {"base": 60.0, "rasp": 0.5}, -60.0, 14.0)
	# ADAPTATION: an in-world clue paraphrasing the page's own exit advice ("find a
	# flickering wall to throw yourself through"); no other wanderer is ever met.
	add_note("L000_wanderer_note", "Damp note",
		"[i]The handwriting runs where the carpet soaked it.[/i]\n\nDon't trust the halls behind you, they move when you stop looking.\n\nIf a wall ever flickers like a dying tube, don't stop to think. Run at it. Throw yourself through.\n\nThe archway rooms stay put. Rest there if you have to.",
		Vector3(11.7, 0.03, 9.6))
	add_shot("spawn", Vector3(10.5, 1.62, 10.5), Vector3(0.5, 1.45, 10.5))
	add_landmark("Wake-up point", Vector3(10.5, 0, 10.5))


func _materials() -> void:
	MatLib.define("l0_wall_flicker", {"emission_color": Color(1.0, 0.93, 0.62), "emission_energy": 0.55, "emission_flicker": 1.0}, "l0_wallpaper")
	MatLib.define("l0_wallpaper_rough", {"albedo_a": Color(0.55, 0.48, 0.27), "albedo_b": Color(0.45, 0.38, 0.2), "bump_strength": 2.4, "noise_scale": 3.0, "stain_amount": 0.6}, "l0_wallpaper")
	MatLib.define("l0_wallpaper_fringe", {"peel_amount": 0.55}, "l0_wallpaper")
	MatLib.define("l0_carpet_dry", {"wetness": 0.08, "stain_amount": 0.15}, "l0_carpet")
	MatLib.define("l0_carpet_sticky", {"albedo_a": Color(0.42, 0.20, 0.12), "albedo_b": Color(0.34, 0.12, 0.08), "wetness": 0.95, "roughness_a": 0.55}, "l0_carpet")
	MatLib.define("l0_carpet_fluid", {"wetness": 1.0, "albedo_a": Color(0.36, 0.30, 0.17), "albedo_b": Color(0.30, 0.25, 0.13)}, "l0_carpet")
	MatLib.register("l0_panel", MatLib.panel(Color(1.0, 0.96, 0.82), 2.6))
	MatLib.register("l0_panel_red", MatLib.panel(Color(1.0, 0.38, 0.32), 1.4))
	MatLib.register("l0_fluid", MatLib.water({"shallow_color": Color(0.45, 0.40, 0.22), "deep_color": Color(0.16, 0.13, 0.07),
		"absorption": 2.5, "clarity": 0.5, "wave_height": 0.004, "foam_amount": 0.0, "roughness_value": 0.12}))


# ------------------------------------------------------------- chunk kinds

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func _vnoise(x: float, z: float) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := _h01(ix, iz, 7)
	var b := _h01(ix + 1, iz, 7)
	var c := _h01(ix, iz + 1, 7)
	var d := _h01(ix + 1, iz + 1, 7)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)


func kind_of(cx: int, cz: int) -> String:
	var d := maxi(absi(cx), absi(cz))
	if d <= 1:
		return "normal"
	var h := _h01(cx, cz, 11)
	if d >= 5 and h < 0.025:
		return "red"
	if _vnoise(cx * 0.31 + 0.5, cz * 0.31 + 0.5) > 0.70:
		return "pillars"
	if d >= 3 and h > 0.94:
		return "holes"
	if d >= 2 and h > 0.86 and h <= 0.94:
		return "blackout"
	if h > 0.74 and h <= 0.86:
		return "arches"
	if d >= 2 and h > 0.62 and h <= 0.74:
		return "atrium"
	return "normal"


func _red_fringe(cx: int, cz: int) -> bool:
	if kind_of(cx, cz) == "red":
		return false
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if kind_of(cx + dx, cz + dz) == "red":
				return true
	return false


func _wall_mat(kind: String, cx: int, cz: int) -> String:
	match kind:
		"arches": return "l0_wallpaper_pale"
		"blackout": return "l0_wallpaper_rough"
		"red": return "l0_red_wall"
	return "l0_wallpaper_fringe" if _red_fringe(cx, cz) else "l0_wallpaper"


func _carpet_mat(kind: String, cx: int, cz: int) -> String:
	match kind:
		"pillars": return "l0_carpet_dry"
		"arches": return "l0_carpet_deep"
		"blackout": return "l0_carpet_fluid"
		"red": return "l0_red_carpet"
	return "l0_carpet_sticky" if _red_fringe(cx, cz) else "l0_carpet"


func _can_shift(_k: Vector2i, meta: Dictionary) -> bool:
	return meta.get("kind", "") in ["normal", "pillars", "holes", "blackout", "atrium"] and not meta.get("qa_locked", false)


# -------------------------------------------------------------- borders

## Openings on the border shared by chunk (ax,az) and its +X (axis "x") or +Z
## (axis "z") neighbour. Depends only on the border identity and the (stable)
## kinds of both sides, so a shifted chunk always reconnects.
func _border(ax: int, az: int, axis: String) -> Array:
	var bx := ax + (1 if axis == "x" else 0)
	var bz := az + (1 if axis == "z" else 0)
	var ka := kind_of(ax, az)
	var kb := kind_of(bx, bz)
	if ka in ["pillars", "holes"] and kb in ["pillars", "holes"]:
		return ["all"]
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "border", axis, ax, az])
	var count := 1 if (ka == "red" or kb == "red") else 1 + r.randi() % 3
	var cells := []
	while cells.size() < count:
		var c := r.randi() % N
		if not cells.has(c):
			cells.append(c)
	var out := []
	for c in cells:
		out.append({"cell": c, "full": r.randf() < 0.5 and ka != "red" and kb != "red"})
	return out


# ---------------------------------------------------------------- builder

func _build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, version if kind != "arches" else 0])
	var k := GeoKit.new(node, "K")
	var ox := cx * CS
	var oz := cz * CS
	var wall := _wall_mat(kind, cx, cz)
	var carpet := _carpet_mat(kind, cx, cz)
	var group := "%d,%d" % [cx, cz]
	var meta := {"kind": kind, "version": version, "exit": false, "fringe": _red_fringe(cx, cz)}
	var floor_y := -0.14 if kind == "blackout" else 0.0
	var sunken := Rect2i()
	if kind == "normal" and not (cx == 0 and cz == 0) and r.randf() < 0.3:
		var w := 2 + r.randi() % 2
		var d := 2
		sunken = Rect2i(1 + r.randi() % (N - w - 1), 1 + r.randi() % (N - d - 1), w, d)
		meta["sunken"] = true
	# ---- floor
	if kind == "holes":
		_holes_floor(k, ox, oz, r, carpet)
	elif sunken.size != Vector2i.ZERO:
		_floor_around(k, ox, oz, sunken, carpet)
	else:
		k.slab(ox, oz, ox + CS, oz + CS, floor_y, 0.3, carpet, GeoKit.PY, "water" if kind == "blackout" else "")
	if kind == "blackout":
		_blackout_extras(node, k, ox, oz)
	# ---- ceiling + fixtures
	if kind == "atrium":
		_atrium(k, ox, oz, r, wall, group, meta)
		_border_walls(k, cx, cz, "x", 0.0)
		_border_walls(k, cx, cz, "z", 0.0)
		k.commit()
		meta["boxes"] = k.stats["boxes"]
		return meta
	k.slab(ox, oz, ox + CS, oz + CS, H + 0.3, 0.3, "l0_ceiling", GeoKit.NY)
	for j in N:
		for i in N:
			var c := Vector3(ox + (i + 0.5) * CELL, H - 0.004, oz + (j + 0.5) * CELL)
			if kind == "blackout":
				k.panel(c, 1.2, 0.6, "l0_panel", 100.0 + i)
				continue
			var dead := r.randf() < 0.03
			var fl := 0.85 if r.randf() < 0.05 else 0.0
			var rotate := (i + j + cx + cz) % 2 == 0
			var sx := 1.2 if rotate else 0.6
			var sz := 0.6 if rotate else 1.2
			k.panel(c, sx, sz, "l0_panel_red" if kind == "red" else "l0_panel", (100.0 + i) if dead else float(i * 13 + j * 7 + cx), fl)
			if not dead and (i + j) % 2 == 0:
				var col := Color(1.0, 0.42, 0.36) if kind == "red" else Color(1.0, 0.93, 0.74)
				lights.add_anchor(c + Vector3.DOWN * 0.25, col, 1.2 if kind != "red" else 0.8, 6.5, fl, group)
	# ---- interior grammar
	match kind:
		"pillars":
			_pillars(k, ox, oz, r, version, wall)
		"holes":
			pass
		"arches":
			_arches(k, ox, oz, r, wall, meta)
		_:
			_maze(k, ox, oz, r, wall, sunken, meta, floor_y)
	if sunken.size != Vector2i.ZERO:
		_sunken_room(k, ox, oz, sunken, r, carpet)
	# ---- borders this chunk owns (+X, +Z)
	_border_walls(k, cx, cz, "x", floor_y)
	_border_walls(k, cx, cz, "z", floor_y)
	# ---- flickering wall (exit) placement
	var want_exit := false
	if qa_fixture and cx == 1 and cz == 0:
		want_exit = true
		meta["qa_locked"] = true
	elif not qa_fixture:
		var d := maxi(absi(cx), absi(cz))
		if kind == "arches" and r.randf() < 0.5:
			want_exit = true
		elif kind == "normal" and d >= 4 and r.randf() < 0.07:
			want_exit = true
	if want_exit:
		_flicker_wall(node, k, ox, oz, r, cx, cz, meta)
	k.commit()
	meta["boxes"] = k.stats["boxes"]
	return meta


## "Randomly segmented rooms, hallways, and stairs": a two-storey yellow hall.
## A 12 m void rises through both floors; an upper gallery (railing-edged)
## rings it, reached by a stair run; upper rooms sit along two sides.
func _atrium(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, wall: String, group: String, meta: Dictionary) -> void:
	var up := H + 0.25            # upper floor top
	var top := up + H             # upper ceiling
	var v0 := Vector2(ox + 6.0, oz + 6.0)
	var v1 := Vector2(ox + 18.0, oz + 18.0)
	# upper floor slab around the void (4 pieces), with a carpet top and tile underside
	for rect in [[ox, oz, ox + CS, v0.y], [ox, v1.y, ox + CS, oz + CS], [ox, v0.y, v0.x, v1.y], [v1.x, v0.y, ox + CS, v1.y]]:
		k.slab(rect[0], rect[1], rect[2], rect[3], up, 0.25, "l0_carpet", GeoKit.PY)
		k.box_mm(Vector3(rect[0], up - 0.25, rect[1]), Vector3(rect[2], up - 0.22, rect[3]), "l0_ceiling", GeoKit.NY, false)
	k.slab(ox, oz, ox + CS, oz + CS, top + 0.3, 0.3, "l0_ceiling", GeoKit.NY)
	# railings (solid wallpapered parapets, 1.0 m); the stair arrives through a gap at the NW corner
	var rh := 1.0
	k.box_mm(Vector3(v0.x + 1.9, up, v0.y - 0.12), Vector3(v1.x, up + rh, v0.y), wall)
	k.box_mm(Vector3(v0.x, up, v1.y), Vector3(v1.x, up + rh, v1.y + 0.12), wall)
	k.box_mm(Vector3(v1.x, up, v0.y), Vector3(v1.x + 0.12, up + rh, v1.y), wall)
	k.box_mm(Vector3(v0.x - 0.12, up, v0.y), Vector3(v0.x, up + rh, v1.y), wall)
	# stair run along the void's west edge, rising north onto the gallery
	var steps := 16
	var run := 0.32
	k.stairs(Vector3(v0.x + 0.9, 0.0, v0.y + steps * run), Vector3(0, 0, -1), 1.6, up, steps, "l0_carpet", run, false)
	# upper-storey shell on the chunk perimeter so nothing beyond the chunk is ever visible
	for e in [[Vector3(ox, H, oz), Vector3(ox + CS, top, oz + 0.1)], [Vector3(ox, H, oz + CS - 0.1), Vector3(ox + CS, top, oz + CS)],
			[Vector3(ox, H, oz), Vector3(ox + 0.1, top, oz + CS)], [Vector3(ox + CS - 0.1, H, oz), Vector3(ox + CS, top, oz + CS)]]:
		k.box_mm(e[0], e[1], wall)
	# perimeter partition walls on both storeys (segmented rooms with doorways)
	for storey in [0.0, up]:
		for side in 4:
			var a: Vector3
			var b: Vector3
			match side:
				0: a = Vector3(ox + 3.0, storey, oz + 3.0); b = Vector3(ox + CS - 3.0, storey, oz + 3.0)
				1: a = Vector3(ox + 3.0, storey, oz + CS - 3.0); b = Vector3(ox + CS - 3.0, storey, oz + CS - 3.0)
				2: a = Vector3(ox + 3.0, storey, oz + 3.0); b = Vector3(ox + 3.0, storey, oz + CS - 3.0)
				_: a = Vector3(ox + CS - 3.0, storey, oz + 3.0); b = Vector3(ox + CS - 3.0, storey, oz + CS - 3.0)
			var ops := [{"at": r.randf_range(2.0, 5.0), "w": 1.3, "h": 2.2}, {"at": r.randf_range(9.0, 15.0), "w": 1.3, "h": 2.2}]
			k.wall(a, b, H, T, wall, ops, GeoKit.SIDES)
	# fixtures on both storeys; tall panels over the void
	for j in N:
		for i in N:
			var c := Vector3(ox + (i + 0.5) * CELL, 0, oz + (j + 0.5) * CELL)
			var in_void := c.x > v0.x and c.x < v1.x and c.z > v0.y and c.z < v1.y
			if not in_void:
				k.panel(Vector3(c.x, H - 0.004 + 0.0, c.z), 1.2, 0.6, "l0_panel", float(i * 13 + j), 0.0)
				k.panel(Vector3(c.x, up - 0.255, c.z), 1.2, 0.6, "l0_panel", float(i * 7 + j), 0.0)
			k.panel(Vector3(c.x, top - 0.004, c.z), 1.2, 0.6, "l0_panel", float(i + j * 5), 0.03 if r.randf() < 0.06 else 0.0)
			if (i + j) % 2 == 0:
				lights.add_anchor(Vector3(c.x, (top if in_void else H) - 0.3, c.z), Color(1.0, 0.93, 0.74), 1.3, 7.5, 0.0, group)
				if not in_void:
					lights.add_anchor(Vector3(c.x, top - 0.3, c.z), Color(1.0, 0.93, 0.74), 1.1, 6.5, 0.0, group)
	meta["storeys"] = 2


func _floor_around(k: GeoKit, ox: float, oz: float, hole: Rect2i, mat: String) -> void:
	var x0 := ox + hole.position.x * CELL
	var x1 := ox + hole.end.x * CELL
	var z0 := oz + hole.position.y * CELL
	var z1 := oz + hole.end.y * CELL
	k.slab(ox, oz, x0, oz + CS, 0.0, 0.3, mat, GeoKit.PY)
	k.slab(x1, oz, ox + CS, oz + CS, 0.0, 0.3, mat, GeoKit.PY)
	k.slab(x0, oz, x1, z0, 0.0, 0.3, mat, GeoKit.PY)
	k.slab(x0, z1, x1, oz + CS, 0.0, 0.3, mat, GeoKit.PY)


func _sunken_room(k: GeoKit, ox: float, oz: float, rect: Rect2i, r: RandomNumberGenerator, mat: String) -> void:
	var depth := 1.08
	var x0 := ox + rect.position.x * CELL
	var x1 := ox + rect.end.x * CELL
	var z0 := oz + rect.position.y * CELL
	var z1 := oz + rect.end.y * CELL
	k.slab(x0, z0, x1, z1, -depth, 0.3, mat, GeoKit.PY)
	# retaining walls (wallpapered drop faces)
	k.box_mm(Vector3(x0 - 0.2, -depth, z0), Vector3(x0, 0.0, z1), "l0_wallpaper", GeoKit.PX)
	k.box_mm(Vector3(x1, -depth, z0), Vector3(x1 + 0.2, 0.0, z1), "l0_wallpaper", GeoKit.NX)
	k.box_mm(Vector3(x0 - 0.2, -depth, z0 - 0.2), Vector3(x1 + 0.2, 0.0, z0), "l0_wallpaper", GeoKit.PZ)
	k.box_mm(Vector3(x0 - 0.2, -depth, z1), Vector3(x1 + 0.2, 0.0, z1 + 0.2), "l0_wallpaper", GeoKit.NZ)
	# stairs up to the -Z edge, centred on a random cell column
	var col := rect.position.x + r.randi() % rect.size.x
	var sx := ox + (col + 0.5) * CELL
	var run := 0.28
	var steps := 6
	var start := Vector3(sx, -depth, z0 + steps * run)
	k.stairs(start, Vector3(0, 0, -1), 1.5, depth, steps, "l0_carpet", run, true)


func _holes_floor(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, mat: String) -> void:
	var hs := 1.6
	for j in N:
		for i in N:
			var x0 := ox + i * CELL
			var z0 := oz + j * CELL
			var border := i == 0 or j == 0 or i == N - 1 or j == N - 1
			var hole := not border and (i + j) % 2 == 0 and r.randf() < 0.8
			if not hole:
				k.slab(x0, z0, x0 + CELL, z0 + CELL, 0.0, 0.3, mat, GeoKit.PY)
				continue
			var m := (CELL - hs) * 0.5
			k.slab(x0, z0, x0 + m, z0 + CELL, 0.0, 0.3, mat, GeoKit.PY)
			k.slab(x0 + CELL - m, z0, x0 + CELL, z0 + CELL, 0.0, 0.3, mat, GeoKit.PY)
			k.slab(x0 + m, z0, x0 + CELL - m, z0 + m, 0.0, 0.3, mat, GeoKit.PY)
			k.slab(x0 + m, z0 + CELL - m, x0 + CELL - m, z0 + CELL, 0.0, 0.3, mat, GeoKit.PY)
			# pitch-black shaft (light does not penetrate more than a few feet)
			var cxw := x0 + CELL * 0.5
			var czw := z0 + CELL * 0.5
			k.box(Vector3(cxw - hs * 0.5 - 0.1, -6.0, czw), Vector3(0.2, 12.0, hs), "void_black", GeoKit.PX, true)
			k.box(Vector3(cxw + hs * 0.5 + 0.1, -6.0, czw), Vector3(0.2, 12.0, hs), "void_black", GeoKit.NX, true)
			k.box(Vector3(cxw, -6.0, czw - hs * 0.5 - 0.1), Vector3(hs, 12.0, 0.2), "void_black", GeoKit.PZ, true)
			k.box(Vector3(cxw, -6.0, czw + hs * 0.5 + 0.1), Vector3(hs, 12.0, 0.2), "void_black", GeoKit.NZ, true)


func _blackout_extras(node: Node3D, k: GeoKit, ox: float, oz: float) -> void:
	# ankle-deep fluid over a recessed floor; small risers at the chunk edges
	var wv := WaterVolume.new()
	node.add_child(wv)
	wv.setup(Vector3(ox, -0.14, oz), Vector3(ox + CS, -0.025, oz + CS), "l0_fluid", true)
	wv.tint = Color(0.35, 0.3, 0.15)
	for e in [[Vector3(ox, -0.14, oz), Vector3(ox + 0.04, 0.0, oz + CS)], [Vector3(ox + CS - 0.04, -0.14, oz), Vector3(ox + CS, 0.0, oz + CS)],
			[Vector3(ox, -0.14, oz), Vector3(ox + CS, 0.0, oz + 0.04)], [Vector3(ox, -0.14, oz + CS - 0.04), Vector3(ox + CS, 0.0, oz + CS)]]:
		k.box_mm(e[0], e[1], "l0_wallpaper_rough")


func _maze(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, wall: String, sunken: Rect2i, meta: Dictionary, floor_y: float) -> void:
	# edges: "h" between (i,j)-(i+1,j); "v" between (i,j)-(i,j+1)
	var edges: Array = []
	for j in N:
		for i in N - 1:
			edges.append(["h", i, j])
	for j in N - 1:
		for i in N:
			edges.append(["v", i, j])
	var parent: Array = []
	for c in N * N:
		parent.append(c)
	var find := func(x: int) -> int:
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x
	# deterministic shuffle
	for i in range(edges.size() - 1, 0, -1):
		var j := r.randi() % (i + 1)
		var tmp = edges[i]
		edges[i] = edges[j]
		edges[j] = tmp
	var state: Dictionary = {}
	for e in edges:
		var a: int = e[2] * N + e[1]
		var b: int = a + 1 if e[0] == "h" else a + N
		var ra: int = find.call(a)
		var rb: int = find.call(b)
		var key := "%s:%d:%d" % [e[0], e[1], e[2]]
		if ra != rb:
			parent[ra] = rb
			state[key] = "door" if r.randf() < 0.45 else "full"
		elif r.randf() < 0.24:
			state[key] = "door" if r.randf() < 0.6 else "full"
		else:
			state[key] = "wall"
	# carve 1-2 larger rooms
	for n in 1 + r.randi() % 2:
		var w := 2 + r.randi() % 3
		var d := 2 + r.randi() % 2
		var px := r.randi() % (N - w + 1)
		var pz := r.randi() % (N - d + 1)
		for jj in range(pz, pz + d):
			for ii in range(px, px + w):
				if ii < px + w - 1:
					state["h:%d:%d" % [ii, jj]] = "full"
				if jj < pz + d - 1:
					state["v:%d:%d" % [ii, jj]] = "full"
	# sunken room: fully open inside and around its rim
	if sunken.size != Vector2i.ZERO:
		for jj in range(sunken.position.y - 1, sunken.end.y + 1):
			for ii in range(sunken.position.x - 1, sunken.end.x + 1):
				state["h:%d:%d" % [ii, jj]] = "full"
				state["v:%d:%d" % [ii, jj]] = "full"
	var walls: Array = []
	for key in state.keys():
		var st: String = state[key]
		if st == "full":
			continue
		var p: PackedStringArray = str(key).split(":")
		var i := int(p[1])
		var j := int(p[2])
		var a: Vector3
		var b: Vector3
		if p[0] == "h":
			var x := ox + (i + 1) * CELL
			a = Vector3(x, floor_y, oz + j * CELL - T * 0.5)
			b = Vector3(x, floor_y, oz + (j + 1) * CELL + T * 0.5)
		else:
			var z := oz + (j + 1) * CELL
			a = Vector3(ox + i * CELL - T * 0.5, floor_y, z)
			b = Vector3(ox + (i + 1) * CELL + T * 0.5, floor_y, z)
		var ops: Array = []
		if st == "door":
			ops.append({"at": (CELL + T) * 0.5 + r.randf_range(-0.4, 0.4), "w": r.randf_range(1.0, 1.5), "h": r.randf_range(2.05, 2.3)})
		k.wall(a, b, H - floor_y, T, wall, ops, GeoKit.SIDES)
		if st == "wall":
			walls.append([a, b, p[0]])
	meta["walls"] = walls


func _pillars(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, version: int, wall: String) -> void:
	for j in range(0, N + 1):
		for i in range(0, N + 1):
			if (i + j) % 1 != 0:
				continue
			var p := Vector3(ox + i * CELL, H * 0.5, oz + j * CELL)
			if i == 0 or j == 0:
				continue  # neighbour/own border lines get pillars from owner side
			if version > 0:
				# shifted lattices drift asymmetrically ("asymmetrically placed pillars")
				if r.randf() < 0.18:
					continue
				p += Vector3(r.randf_range(-0.7, 0.7), 0, r.randf_range(-0.7, 0.7))
			k.box(p, Vector3(0.62, H, 0.62), wall, GeoKit.SIDES)


func _arches(k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, wall: String, meta: Dictionary) -> void:
	# two or three long arcaded walls across the chunk (stable transition rooms)
	var lines := 2 + r.randi() % 2
	var used := []
	for n in lines:
		var along_x := r.randf() < 0.5
		var idx := 2 + r.randi() % (N - 3)
		if used.has([along_x, idx]):
			continue
		used.append([along_x, idx])
		var arches := []
		for c in N:
			arches.append({"at": c * CELL + CELL * 0.5 + T * 0.5, "w": 1.7, "spring": 1.45})
		if along_x:
			var z := oz + idx * CELL
			k.arch_wall(Vector3(ox - T * 0.5, 0, z), Vector3(ox + CS + T * 0.5, 0, z), H, 0.28, wall, arches)
		else:
			var x := ox + idx * CELL
			k.arch_wall(Vector3(x, 0, oz - T * 0.5), Vector3(x, 0, oz + CS + T * 0.5), H, 0.28, wall, arches)
	meta["arch_lines"] = used.size()


func _border_walls(k: GeoKit, cx: int, cz: int, axis: String, floor_y: float) -> void:
	var b := _border(cx, cz, axis)
	if b.size() == 1 and str(b[0]) == "all":
		return
	var ox := cx * CS
	var oz := cz * CS
	var nx := cx + (1 if axis == "x" else 0)
	var nz := cz + (1 if axis == "z" else 0)
	var mat_here := _wall_mat(kind_of(cx, cz), cx, cz)
	var mat_there := _wall_mat(kind_of(nx, nz), nx, nz)
	var ops: Array = []
	for o in b:
		var at := float(o["cell"]) * CELL + CELL * 0.5 + T * 0.5
		ops.append({"at": at, "w": CELL - 0.1 if o["full"] else 1.3, "h": H + 1.0 if o["full"] else 2.2})
	var fy := minf(floor_y, -0.14 if kind_of(nx, nz) == "blackout" else 0.0)
	var hh := H - fy
	if axis == "x":
		var x := ox + CS
		k.wall(Vector3(x - T * 0.25, fy, oz - T * 0.5), Vector3(x - T * 0.25, fy, oz + CS + T * 0.5), hh, T * 0.5, mat_here, ops, GeoKit.SIDES)
		k.wall(Vector3(x + T * 0.25, fy, oz - T * 0.5), Vector3(x + T * 0.25, fy, oz + CS + T * 0.5), hh, T * 0.5, mat_there, ops, GeoKit.SIDES)
	else:
		var z := oz + CS
		k.wall(Vector3(ox - T * 0.5, fy, z - T * 0.25), Vector3(ox + CS + T * 0.5, fy, z - T * 0.25), hh, T * 0.5, mat_here, ops, GeoKit.SIDES)
		k.wall(Vector3(ox - T * 0.5, fy, z + T * 0.25), Vector3(ox + CS + T * 0.5, fy, z + T * 0.25), hh, T * 0.5, mat_there, ops, GeoKit.SIDES)


## The sourced exit: a wall section whose surface and light flicker. Throwing
## yourself through it (pressing into it, ideally sprinting) no-clips you out.
func _flicker_wall(node: Node3D, k: GeoKit, ox: float, oz: float, r: RandomNumberGenerator, cx: int, cz: int, meta: Dictionary) -> void:
	var ci := 1 + r.randi() % (N - 2)
	var cj := 1 + r.randi() % (N - 2)
	if qa_fixture:
		ci = 1
		cj = 3
	var along_z := r.randf() < 0.5 if not qa_fixture else true
	var c := Vector3(ox + (ci + 0.5) * CELL, 0, oz + (cj + 0.5) * CELL)
	var len := 2.4
	var a: Vector3
	var b: Vector3
	var trig_size: Vector3
	if along_z:
		a = c + Vector3(0, 0, -len * 0.5)
		b = c + Vector3(0, 0, len * 0.5)
		trig_size = Vector3(1.5, 2.3, len + 0.2)
	else:
		a = c + Vector3(-len * 0.5, 0, 0)
		b = c + Vector3(len * 0.5, 0, 0)
		trig_size = Vector3(len + 0.2, 2.3, 1.5)
	k.wall(a, b, H, 0.2, "l0_wall_flicker", [], GeoKit.ALL)
	lights.add_anchor(c + Vector3(0, 2.2, 0), Color(1.0, 0.95, 0.75), 1.8, 5.0, 0.9, "%d,%d" % [cx, cz])
	var hum3d := AudioStreamPlayer3D.new()
	hum3d.stream = AudioSynth.get_stream("static", {"seconds": 2.0})
	hum3d.volume_db = -14.0
	hum3d.max_distance = 12.0
	hum3d.bus = "Ambience"
	hum3d.position = c + Vector3.UP * 1.2
	hum3d.autoplay = true
	node.add_child(hum3d)
	var t := make_exit("L000>L001#1", "noclip", c + Vector3.UP * 1.1, trig_size, "Throw yourself through the flickering wall (push / sprint into it)", node)
	if t:
		t.hold_seconds = 1.2
	meta["exit"] = true
	meta["exit_pos"] = c


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story() and SaveService.flag(stable_id, "woke", false) == false:
		SaveService.set_flag(stable_id, "woke", true)
		Overlay.subtitle("[buzzing fluorescent lights] [the smell of soggy carpet]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L000>L001#1", "target": Vector3(CS + 1.5 * CELL, 0.05, 3.5 * CELL), "note": "QA fixture places a flickering wall in chunk (1,0)"})


func level_process(delta: float) -> void:
	if player == null:
		return
	var key := world.key_at(player.global_position)
	var meta := world.meta_of(key)
	_kind_here = meta.get("kind", "normal")
	var fringe: bool = meta.get("fringe", false)
	# --- hum: random severe swells; silence in blackout zones
	_surge_t -= delta
	if _surge_t <= 0.0:
		_surge_t = rng.randf_range(35.0, 95.0)
		_surge = rng.randf_range(2.0, 4.0)
		if _kind_here != "blackout":
			Overlay.subtitle("[the buzzing swells painfully]", 2.5)
	_surge = maxf(0.0, _surge - delta)
	var target_db := _hum_db + (7.0 if _surge > 0.0 else 0.0)
	if _kind_here == "blackout":
		target_db = -70.0
	hum.volume_db = lerpf(hum.volume_db, target_db, clampf(delta * 2.5, 0.0, 1.0))
	# --- blackout: the buzz you follow keeps moving
	if _kind_here == "blackout":
		var t := Time.get_ticks_msec() * 0.00025
		_blackout_buzz.global_position = player.global_position + Vector3(cos(t * 3.1) * 9.0, 2.0, sin(t * 2.3) * 9.0)
		_blackout_buzz.volume_db = lerpf(_blackout_buzz.volume_db, -10.0, delta)
	else:
		_blackout_buzz.volume_db = lerpf(_blackout_buzz.volume_db, -60.0, delta * 2.0)
	var amb_target := 0.30
	var fog_target := 1.0
	if _kind_here == "blackout":
		amb_target = 0.012
		fog_target = 0.0
	elif _kind_here == "red":
		amb_target = 0.12
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, amb_target, clampf(delta * 1.5, 0.0, 1.0))
	environment.fog_light_energy = lerpf(environment.fog_light_energy, fog_target, clampf(delta * 1.5, 0.0, 1.0))
	# --- red rooms: proximity effects, then a closed loop once fully entered
	var red_level := 0.0
	if _kind_here == "red":
		red_level = 1.0
	elif fringe:
		red_level = 0.35
	Overlay.set_screen_effect("red_tint", lerpf(0.0, 0.22, red_level))
	_heart.volume_db = lerpf(_heart.volume_db, -60.0 + 52.0 * red_level, clampf(delta * 2.0, 0.0, 1.0))
	player.walk_speed = 3.1 * (0.78 if (fringe or _kind_here == "red") else 1.0)
	player.sprint_speed = 5.3 * (0.78 if (fringe or _kind_here == "red") else 1.0)
	if _kind_here == "red":
		var o := world.chunk_origin(key)
		var lp := player.global_position - o
		var inside := lp.x > 4.0 and lp.z > 4.0 and lp.x < CS - 4.0 and lp.z < CS - 4.0
		if inside and _red_sealed_key != key:
			_seal_red(key)
		if _red_sealed_key == key:
			_red_timer += delta
			if _red_timer > 75.0 and not player.dead:
				player.hurt(1000.0, "You never found a way out of the Red Rooms")
	# --- holes: no one has reported surviving the fall
	if player.global_position.y < -2.2 and not player.dead:
		player.hurt(1000.0, "You fell into one of the holes. None have reported surviving")
	# --- arch rooms are stable; resting there is a checkpoint
	_rest_cooldown = maxf(0.0, _rest_cooldown - delta)
	if _kind_here == "arches" and player.velocity.length() < 0.2:
		_rest_t += delta
		if _rest_t > 4.0 and _rest_cooldown <= 0.0:
			_rest_cooldown = 90.0
			checkpoint("arches")
			Overlay.toast("You rest a moment in the archway rooms. They do not shift behind you. (Checkpoint)", 4.0)
	else:
		_rest_t = 0.0


func _seal_red(key: Vector2i) -> void:
	_red_sealed_key = key
	_red_timer = 0.0
	var c: Dictionary = world.chunks.get(key, {})
	if c.is_empty():
		return
	var k := GeoKit.new(c["node"], "Seal")
	var o := world.chunk_origin(key)
	k.box_mm(o + Vector3(-0.3, 0, -0.3), o + Vector3(0.0, H, CS + 0.3), "l0_red_wall")
	k.box_mm(o + Vector3(CS, 0, -0.3), o + Vector3(CS + 0.3, H, CS + 0.3), "l0_red_wall")
	k.box_mm(o + Vector3(-0.3, 0, -0.3), o + Vector3(CS + 0.3, H, 0.0), "l0_red_wall")
	k.box_mm(o + Vector3(-0.3, 0, CS), o + Vector3(CS + 0.3, H, CS + 0.3), "l0_red_wall")
	k.commit()
	Overlay.subtitle("[the way you came is gone]", 4.0)


## QA: nearest chunk of a kind (for curated captures), searching outward.
func find_chunk_of(kind: String, max_r: int = 14) -> Vector2i:
	for rr in range(0, max_r + 1):
		for dz in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dz)) != rr:
					continue
				if kind_of(dx, dz) == kind:
					return Vector2i(dx, dz)
	return Vector2i(999999, 999999)


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	for kind in ["atrium", "pillars", "arches", "holes", "blackout", "red"]:
		var k := find_chunk_of(kind)
		if k.x == 999999:
			continue
		var o := world.chunk_origin(k)
		var pos := o + Vector3(CELL * 0.5, 1.62, CELL * 0.5)
		var tgt := o + Vector3(CS * 0.55, 1.3, CS * 0.45)
		var shot := {"name": kind, "pos": pos, "target": tgt,
			"prepare": func(): world.build_around(o + Vector3(CS * 0.5, 0, CS * 0.5), 1)}
		if kind == "blackout":
			shot["flashlight"] = true
		if kind == "atrium":
			shot["pos"] = o + Vector3(13.5, 1.62, 16.5)
			shot["target"] = o + Vector3(13.0, 4.8, 5.0)
			plan.append(shot)
			plan.append({"name": "atrium_gallery", "pos": o + Vector3(16.5, H + 0.25 + 1.62, 4.6),
				"target": o + Vector3(10.0, 0.6, 14.0), "prepare": shot["prepare"]})
			continue
		plan.append(shot)
	return plan


## Engine assertions for this level's sourced mechanics (run by the QA harness).
func qa_self_test() -> Array:
	var out: Array = []
	var before := world.shift_count
	var pk := world.key_at(player.global_position)
	var v_player := int(world.versions.get(pk, 0))
	player.rotation.y = -PI * 0.5   # face +X: chunks on the -X side leave the frustum
	for i in 660:
		await get_tree().process_frame
	out.append({"what": "peripheral shift re-randomised unobserved chunks", "ok": world.shift_count > before, "detail": world.shift_count - before})
	out.append({"what": "the player's own chunk never shifts", "ok": int(world.versions.get(pk, 0)) == v_player})
	var arch_shift := false
	for k in world.versions.keys():
		if kind_of(k.x, k.y) == "arches" and int(world.versions[k]) > 0:
			arch_shift = true
	out.append({"what": "arch rooms stay stable (never shift)", "ok": not arch_shift})
	var hole := find_chunk_of("holes")
	out.append({"what": "hole zones exist in the streamed world", "ok": hole.x != 999999, "detail": hole})
	return out
