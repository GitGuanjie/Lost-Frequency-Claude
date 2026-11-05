extends LevelBase
## Level 6 — "Lights Out" (Backrooms Wikidot rev 65, accessed 2026-11-04; cite:
## "Level 6 - "Lights Out"" by Bart0nius, CC BY-SA 3.0; page flagged outdated).
## Dossier: docs/canon/levels/L006.md.
##
## Total darkness: no light permeates, light sources brought in have no function
## (rules.flashlight = "none"; nothing in the level is lit or emissive). You feel
## your way: surfaces within arm's reach are remembered for seconds (touch map,
## L006_touch.gd). Seemingly endless tight concrete hallways (streamed maze of
## 1.3 m halls, long straight runs). Eerie, soundproof silence; after a few
## minutes dread rises and the hallucinated scuttling / breathing / whispering
## begins. No entities. The stairwell to Level 7 is found by the faint sound of
## waves, which follows the corridors (BFS over the loaded halls). A wrong turn
## far out blocks off both Level 7 and the way back to Level 5. Rare: a large
## metal door that feels extremely cold (Level 129); a wire you trip on (6.1).

const Touch := preload("res://levels/L006/L006_touch.gd")
const CS := 24.0
const P := 2.4
const NN := 10
const HH := 2.35
const RISE := 2.4
const D4 := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const COLD := Color(0.62, 0.84, 1.0)
const WARM := Color(1.0, 0.66, 0.4)
const GREY := Color(0.66, 0.68, 0.72)

var world: ChunkWorld
var touch: RefCounted
var qa_fixture := false
var stair_key := Vector2i(1, 0)
var stair_row := 4
var lost := false
var lost_radius := 5
var dread := 0.0
var t_level := 0.0
var found_stair := false
var _entrance: ExitTrigger
var _waves: AudioStreamPlayer3D
var _waves_near: AudioStreamPlayer3D
var _breath: AudioStreamPlayer3D
var _breath_t := 0.0
var _wave_t := 0.0
var _hallu_t := 0.0
var _only_t := 200.0
var _feet_acc := 0.0
var _last_feet := Vector3.ZERO
var _walk_t := 0.0
var _mimic_cd := 60.0
var _mimic_q: Array = []
var _probe_t := 0.0
var _special_pts: Array = []   # [{pos, col, r}]


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "none"
	rules["reverb_room"] = 0.04
	rules["reverb_wet"] = 0.0
	rules["view_distance"] = 60.0
	rules["walk_speed"] = 2.6
	rules["sprint_speed"] = 4.2
	indoor_env(Color(0, 0, 0), 0.0, Color(0, 0, 0), 0.0)
	environment.glow_enabled = false
	environment.ssao_enabled = false
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	lights.setup(1, 0)
	touch = Touch.new()
	touch.make_material("l6_concrete", Color(1, 1, 1), 0.5)
	touch.make_material("l6_cold_metal", Color(1.2, 1.3, 1.45), 0.75)
	touch.make_material("l6_wire", Color(1, 1, 1), 0.9)
	if not qa_fixture:
		var r := RandomNumberGenerator.new()
		r.seed = hash([level_seed, "stair6"])
		var ring := []
		for dz in range(-3, 4):
			for dx in range(-3, 4):
				if maxi(absi(dx), absi(dz)) == 3 and dx >= -1:
					ring.append(Vector2i(dx, dz))
		stair_key = ring[r.randi() % ring.size()]
		stair_row = 2 + r.randi() % 6
		lost_radius = 5 + r.randi() % 2
	world = ChunkWorld.new()
	world.name = "Halls"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	# the stairwell chunk first so the sourced Level 7 exit is the QA walker's target
	if qa_fixture:
		world.build_around(_center(stair_key), 0)
	world.build_around(Vector3(1.5, 0, 13.2), 2)
	add_arrival("start", Vector3(1.5, RISE + 0.05, 13.2), -90.0)
	add_arrival("from_L005", Vector3(1.5, RISE + 0.05, 13.2), -90.0)
	_waves = _p3d(AudioSynth.get_stream("water_bed", {"bright": 380.0, "seconds": 7.0}), -80.0, 60.0)
	_waves_near = _p3d(AudioSynth.get_stream("water_bed", {"bright": 700.0}), -80.0, 14.0)
	_breath = _p3d(AudioSynth.get_stream("room_tone", {"cutoff": 1300.0, "seconds": 3.0}), -80.0, 6.0)
	_hallu_t = 170.0
	add_landmark("Stairs up to the Boiler Room (Level 5)", Vector3(1.2, RISE, 13.2))


func _p3d(st: AudioStream, db: float, dist: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = st
	p.volume_db = db
	p.max_distance = dist
	p.unit_size = 2.0
	p.bus = "Ambience"
	p.autoplay = true
	add_child(p)
	return p


func _center(k: Vector2i) -> Vector3:
	return Vector3(k.x * CS + CS * 0.5, 0, k.y * CS + CS * 0.5)


func kind_of(cx: int, cz: int) -> String:
	if lost:
		return "maze"
	if cx == 0 and cz == 0:
		return "entrance"
	if Vector2i(cx, cz) == stair_key:
		return "stair"
	return "maze"


## Openings on the border between (ax,az) and its +x / +z neighbour (stable).
func border(ax: int, az: int, axis: String) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "b6", axis, ax, az])
	var out := [r.randi() % NN]
	if r.randf() < 0.45:
		out.append(r.randi() % NN)
	if axis == "x":
		if ax == -1 and az == 0:
			out.erase(5)
		if Vector2i(ax, az) == stair_key:
			out.erase(stair_row)
	if out.is_empty():
		out.append(1)
	return out


func maze(cx: int, cz: int) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "m6", cx, cz, kind])
	var oh := PackedByteArray()
	oh.resize((NN - 1) * NN)
	var ov := PackedByteArray()
	ov.resize(NN * (NN - 1))
	var blocked := {}
	if kind == "entrance":
		for i in 3:
			blocked[Vector2i(i, 5)] = true
	elif kind == "stair":
		for i in [7, 8, 9]:
			blocked[Vector2i(i, stair_row)] = true
	var seen := {}
	var start := Vector2i(4 + r.randi() % 2, 4 + r.randi() % 2)
	var stack: Array = [start]
	seen[start] = true
	var last := -1
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var opts := []
		for d in 4:
			var nb: Vector2i = c + D4[d]
			if nb.x >= 0 and nb.y >= 0 and nb.x < NN and nb.y < NN and not seen.has(nb) and not blocked.has(nb):
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
			last = -1
			continue
		var d: int = opts[r.randi() % opts.size()]
		if opts.has(last) and r.randf() < 0.66:
			d = last
		_set_edge(oh, ov, c, d)
		var n2: Vector2i = c + D4[d]
		seen[n2] = true
		stack.push_back(n2)
		last = d
	for j in NN:
		for i in NN:
			var c := Vector2i(i, j)
			if blocked.has(c):
				continue
			for d in [1, 2]:
				var nb: Vector2i = c + D4[d]
				if nb.x < NN and nb.y < NN and not blocked.has(nb) and r.randf() < 0.06:
					_set_edge(oh, ov, c, d)
	if kind == "entrance":
		for i in 3:
			_set_edge(oh, ov, Vector2i(i, 5), 1)
	elif kind == "stair":
		for i in [6, 7, 8]:
			_set_edge(oh, ov, Vector2i(i, stair_row), 1)
	return {"kind": kind, "oh": oh, "ov": ov, "E": {0: border(cx, cz - 1, "z"), 1: border(cx, cz, "x"), 2: border(cx, cz, "z"), 3: border(cx - 1, cz, "x")}}


func _set_edge(oh: PackedByteArray, ov: PackedByteArray, c: Vector2i, d: int) -> void:
	match d:
		0: ov[(c.y - 1) * NN + c.x] = 1
		1: oh[c.y * (NN - 1) + c.x] = 1
		2: ov[c.y * NN + c.x] = 1
		3: oh[c.y * (NN - 1) + c.x - 1] = 1


func edge_open(m: Dictionary, i: int, j: int, d: int) -> bool:
	match d:
		0:
			return (m["ov"][(j - 1) * NN + i] == 1) if j > 0 else (i in m["E"][0])
		1:
			return (m["oh"][j * (NN - 1) + i] == 1) if i < NN - 1 else (j in m["E"][1])
		2:
			return (m["ov"][j * NN + i] == 1) if j < NN - 1 else (i in m["E"][2])
	return (m["oh"][j * (NN - 1) + i - 1] == 1) if i > 0 else (j in m["E"][3])


func band(b: int) -> Vector2:
	if b == 0:
		return Vector2(0.0, 0.55)
	if b == 2 * NN:
		return Vector2(CS - 0.55, CS)
	if b % 2 == 1:
		var k := (b - 1) / 2
		return Vector2(k * P + 0.55, k * P + 1.85)
	var k2 := b / 2
	return Vector2((k2 - 1) * P + 1.85, k2 * P + 0.55)


func _open_cell(m: Dictionary, bx: int, bz: int) -> bool:
	var ox := bx % 2 == 1
	var oz := bz % 2 == 1
	if ox and oz:
		return true
	if not ox and not oz:
		return false
	if not ox:
		var j := (bz - 1) / 2
		if bx == 0:
			return edge_open(m, 0, j, 3)
		return edge_open(m, bx / 2 - 1, j, 1)
	var i := (bx - 1) / 2
	if bz == 0:
		return edge_open(m, i, 0, 0)
	return edge_open(m, i, bz / 2 - 1, 2)


func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var m := maze(cx, cz)
	var kind: String = m["kind"]
	var k := GeoKit.new(node, "K")
	var o := Vector3(cx * CS, 0, cz * CS)
	# solid concrete: greedy rectangles over the 21x21 band grid
	var active := {}
	for bz in 2 * NN + 2:
		var runs := []
		if bz <= 2 * NN:
			var bx := 0
			while bx <= 2 * NN:
				if _open_cell(m, bx, bz):
					bx += 1
					continue
				var s := bx
				while bx <= 2 * NN and not _open_cell(m, bx, bz):
					bx += 1
				runs.append(Vector2i(s, bx - 1))
		for key in active.keys():
			if not runs.has(key):
				var z0 := band(active[key]).x
				var z1 := band(bz - 1).y
				k.box_mm(o + Vector3(band(key.x).x, 0, z0), o + Vector3(band(key.y).y, HH, z1), "l6_concrete", GeoKit.SIDES)
				active.erase(key)
		for run in runs:
			if not active.has(run):
				active[run] = bz
	var hole := Rect2()
	if kind == "entrance":
		hole = _entrance_geo(k, node, o)
	elif kind == "stair":
		hole = _stair_geo(k, node, o)
	_slab(k, o, hole if kind == "stair" else Rect2(), 0.0, true)
	_slab(k, o, hole if kind == "entrance" else Rect2(), HH, false)
	var meta := {"kind": kind, "m": m}
	if kind == "maze" and not qa_fixture:
		var d := maxi(absi(cx), absi(cz))
		var h := float(absi(hash([level_seed, "rare", cx, cz])) % 1000) / 1000.0
		if d >= 3 and h < 0.05:
			_cold_door(k, node, o, m, meta)
		elif d >= 2 and h > 0.955:
			_wire(k, node, o, m, meta)
	k.commit()
	return meta


func _slab(k: GeoKit, o: Vector3, hole: Rect2, y: float, floor_: bool) -> void:
	var rects: Array = [Rect2(0, 0, CS, CS)]
	if hole.size != Vector2.ZERO:
		rects = [Rect2(0, 0, CS, hole.position.y), Rect2(0, hole.end.y, CS, CS - hole.end.y),
			Rect2(0, hole.position.y, hole.position.x, hole.size.y), Rect2(hole.end.x, hole.position.y, CS - hole.end.x, hole.size.y)]
	for rc in rects:
		if rc.size.x < 0.01 or rc.size.y < 0.01:
			continue
		var a := o + Vector3(rc.position.x, y - 0.3 if floor_ else y, rc.position.y)
		var b := o + Vector3(rc.end.x, y if floor_ else y + 0.3, rc.end.y)
		k.box_mm(a, b, "l6_concrete", GeoKit.PY if floor_ else GeoKit.NY, floor_)


## Way back up: a straight flight climbing west to the landing you arrived on.
func _entrance_geo(k: GeoKit, node: Node3D, o: Vector3) -> Rect2:
	var zb := band(11)
	var x_bot := band(7).x
	var hb := HH + RISE + 0.05
	k.box_mm(o + Vector3(band(1).x, 0, zb.x), o + Vector3(band(1).y, RISE, zb.y), "l6_concrete", GeoKit.PY | GeoKit.PX)
	k.stairs(o + Vector3(x_bot, 0, (zb.x + zb.y) * 0.5), Vector3(-1, 0, 0), zb.y - zb.x, RISE, 16, "l6_concrete", (x_bot - band(1).y) / 16.0, true)
	for zz in [band(10), band(12)]:
		k.box_mm(o + Vector3(0, HH, zz.x), o + Vector3(x_bot, hb, zz.y), "l6_concrete", GeoKit.SIDES)
	k.box_mm(o + Vector3(0, 0, zb.x), o + Vector3(band(0).y, hb, zb.y), "l6_concrete", GeoKit.PX)
	k.box_mm(o + Vector3(0, hb, zb.x), o + Vector3(x_bot, hb + 0.3, zb.y), "l6_concrete", GeoKit.NY, false)
	var zc := (zb.x + zb.y) * 0.5
	_entrance = make_exit("L006>L005#4", "walk_in", o + Vector3(0.78, RISE + 1.1, zc), Vector3(0.5, 2.0, 1.3), "", node)
	_special_pts.append({"pos": o + Vector3(2.5, RISE * 0.6, zc), "col": WARM, "r": 7.0})
	return Rect2(0, zb.x, x_bot, zb.y - zb.x)


## Stairwell down to Level 7: a flight dropping east to a landing; waves below.
func _stair_geo(k: GeoKit, node: Node3D, o: Vector3) -> Rect2:
	var zb := band(2 * stair_row + 1)
	var x_top := band(15).x
	var x_bot := band(19).x
	var x_end := band(19).y
	k.stairs(o + Vector3(x_bot, -RISE, (zb.x + zb.y) * 0.5), Vector3(-1, 0, 0), zb.y - zb.x, RISE, 13, "l6_concrete", (x_bot - x_top) / 13.0, true)
	k.box_mm(o + Vector3(x_bot, -RISE - 0.3, zb.x), o + Vector3(x_end, -RISE, zb.y), "l6_concrete", GeoKit.PY)
	for zz in [band(2 * stair_row), band(2 * stair_row + 2)]:
		k.box_mm(o + Vector3(x_top, -RISE - 0.3, zz.x), o + Vector3(CS, 0, zz.y), "l6_concrete", GeoKit.SIDES)
	k.box_mm(o + Vector3(x_end, -RISE - 0.3, zb.x), o + Vector3(CS, 0, zb.y), "l6_concrete", GeoKit.NX)
	var zc := (zb.x + zb.y) * 0.5
	make_exit("L006>L007#1", "walk_in", o + Vector3((x_bot + x_end) * 0.5, -RISE + 1.1, zc), Vector3(1.1, 2.2, 1.2), "", node)
	_special_pts.append({"pos": o + Vector3((x_top + x_end) * 0.5, -1.2, zc), "col": Color(0.52, 0.7, 0.78), "r": 4.0})
	return Rect2(x_top, zb.x, CS - x_top, zb.y - zb.x)


func stair_bottom() -> Vector3:
	var zb := band(2 * stair_row + 1)
	return Vector3(stair_key.x * CS + band(19).x + 0.6, -RISE + 0.8, stair_key.y * CS + (zb.x + zb.y) * 0.5)


## A rare large metal door, extremely cold to the touch (Level 129).
func _cold_door(k: GeoKit, node: Node3D, o: Vector3, m: Dictionary, meta: Dictionary) -> void:
	for j in range(1, NN - 1):
		for i in range(1, NN - 1):
			if not edge_open(m, i, j, 0) and edge_open(m, i, j, 2):
				var p := o + Vector3(i * P + 1.2, 0, j * P + 0.55)
				k.box_mm(p + Vector3(-0.62, 0, -0.05), p + Vector3(0.62, 2.25, 0.04), "l6_cold_metal", GeoKit.ALL, true)
				make_exit("L006>L129#2", "interact", p + Vector3(0, 1.1, 0.6), Vector3(1.2, 2.0, 1.0), "Push the freezing metal door", node)
				_special_pts.append({"pos": p + Vector3(0, 1.1, 0.1), "col": COLD, "r": 1.6})
				meta["cold"] = p
				return


## A wire strung low across a hall: walking into it trips you (Level 6.1).
func _wire(k: GeoKit, node: Node3D, o: Vector3, m: Dictionary, meta: Dictionary) -> void:
	for j in range(2, NN - 2):
		for i in range(2, NN - 2):
			if edge_open(m, i, j, 1) and edge_open(m, i - 1, j, 1) and not edge_open(m, i, j, 0) and not edge_open(m, i, j, 2):
				var p := o + Vector3(i * P + 1.2, 0.14, j * P + 1.2)
				k.box(p, Vector3(0.012, 0.012, 1.3), "l6_wire", GeoKit.ALL, false)
				var t := make_exit("L006>L006_1#3", "condition", p + Vector3(0, 0.8, 0), Vector3(0.5, 1.6, 1.3), "", node)
				if t:
					t.condition = _tripping
				_special_pts.append({"pos": p, "col": GREY, "r": 0.6})
				meta["wire"] = p
				return


func _tripping() -> bool:
	var v := player.velocity
	v.y = 0.0
	if v.length() > 1.6 and not player.crouching:
		Overlay.subtitle("[your foot catches on a wire]", 2.5)
		return true
	return false


# ------------------------------------------------------------------ runtime

func on_player_ready() -> void:
	world.target = player
	player.feet_audio.volume_db = -15.0
	if SessionState.is_story():
		checkpoint("entrance")
	if not SaveService.flag(stable_id, "intro", false) and not SessionState.is_qa():
		SaveService.set_flag(stable_id, "intro", true)
		Overlay.toast("Nothing gives light here. Keep a hand on the wall: what you touch stays with you for a few seconds.", 6.0)
	Overlay.subtitle("[total darkness] [total silence]", 4.0)
	if qa_fixture:
		qa_routes.append({"edge": "L006>L007#1", "target": stair_bottom(), "note": "QA fixture places the stairwell in chunk (1,0), row 4"})


func level_process(delta: float) -> void:
	if player == null:
		return
	t_level += delta
	var p := player.global_position
	if Input.is_action_just_pressed("flashlight"):
		Overlay.subtitle("[the switch clicks; nothing happens]", 2.0)
	_feel(delta, p)
	touch.fade = lerpf(8.5, 3.5, dread)
	touch.upload(t_level)
	_dread(delta, p)
	_wave_t -= delta
	if _wave_t <= 0.0:
		_wave_t = 0.4
		_waves_tick(p)
	_hallucinate(delta, p)
	_mimicry(delta, p)
	if not lost and not qa_fixture:
		_check_lost(p)


## Hands out at arm's length and feet on the floor: that is all there is.
func _feel(delta: float, p: Vector3) -> void:
	_probe_t -= delta
	if _probe_t > 0.0:
		return
	_probe_t = 0.06
	var space := get_world_3d().direct_space_state
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	for h in [[1.25, [-80.0, -45.0, -15.0, 15.0, 45.0, 80.0]], [0.75, [-60.0, 0.0, 60.0]], [1.75, [-30.0, 30.0]]]:
		for a in h[1]:
			var dir := fwd.rotated(Vector3.UP, deg_to_rad(a))
			var from: Vector3 = p + Vector3.UP * h[0]
			var q := PhysicsRayQueryParameters3D.create(from, from + dir * 0.95, 1)
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				_touch_at(hit["position"], 1.0)
	_feet_acc += Vector2(p.x - _last_feet.x, p.z - _last_feet.z).length()
	_last_feet = p
	if _feet_acc > 0.55 and player.is_on_floor():
		_feet_acc = 0.0
		_touch_at(p + Vector3.UP * 0.02, 0.55)


func _touch_at(hp: Vector3, s: float) -> void:
	var c := GREY
	for sp in _special_pts:
		var d: float = (sp["pos"] as Vector3).distance_to(hp)
		if d < sp["r"]:
			c = c.lerp(sp["col"], clampf(1.2 - d / sp["r"], 0.0, 1.0))
	touch.add(hp, c, s, t_level)


func _dread(delta: float, p: Vector3) -> void:
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.4
	var rate := 0.0
	if t_level > 150.0:
		rate = (1.0 / 540.0) * (0.7 if moving else 1.3) * (1.6 if lost else 1.0)
	if p.distance_to(Vector3(4.0, 1.0, 13.2)) < 8.0:
		rate = -1.0 / 50.0
	dread = clampf(dread + rate * delta, 0.0, 1.0)
	player.walk_speed = lerpf(2.6, 2.1, dread)
	_only_t -= delta
	if dread > 0.6 and _only_t <= 0.0:
		_only_t = 240.0
		Overlay.subtitle("[you feel as if you are the only one here who cannot see]", 4.0)


## Paranoia: hallucinated scuttling, breathing and whispering. No source exists.
func _hallucinate(delta: float, p: Vector3) -> void:
	if _breath_t > 0.0:
		_breath_t -= delta
		_breath.volume_db = -20.0 + 9.0 * sin(t_level * TAU * 0.27)
		if _breath_t <= 0.0:
			_breath.volume_db = -80.0
	if t_level < 150.0:
		return
	_hallu_t -= delta
	if _hallu_t > 0.0:
		return
	_hallu_t = lerpf(130.0, 20.0, dread) * rng.randf_range(0.7, 1.3)
	var ang := rng.randf() * TAU
	var pos := p + Vector3(cos(ang), 0.0, sin(ang)) * rng.randf_range(2.0, 6.0) + Vector3.UP * rng.randf_range(0.2, 1.6)
	match rng.randi() % 3:
		0:
			sound.play_at("scratch", {"seconds": 1.4}, pos, -13.0, "[scuttling, somewhere close]")
		1:
			_breath.global_position = p + Vector3(cos(ang), 1.5, sin(ang)) * 1.6
			_breath_t = 7.0
			Overlay.subtitle("[breathing, close by. Not yours?]", 3.0)
		_:
			sound.play_at("whisper", {}, pos, -16.0, "[whispering in the dark]")


## Mimicry: a community that copies any sound perfectly. Stop walking, and
## sometimes your own footsteps go on without you. (Audio only; never seen.)
func _mimicry(delta: float, p: Vector3) -> void:
	for e in _mimic_q:
		e["t"] -= delta
	while not _mimic_q.is_empty() and _mimic_q[0]["t"] <= 0.0:
		var e: Dictionary = _mimic_q.pop_front()
		sound.play_at("footstep", {"surface": "concrete", "variant": e["v"]}, e["pos"], -17.0, e["cap"])
	_mimic_cd -= delta
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.8
	if moving:
		_walk_t += delta
		return
	if _walk_t > 5.0 and _mimic_cd <= 0.0 and t_level > 120.0 and _mimic_q.is_empty() and Vector2(p.x, p.z).length() > 40.0 and rng.randf() < 0.35:
		_mimic_cd = rng.randf_range(100.0, 200.0)
		var ang := rng.randf() * TAU
		var from := p + Vector3(cos(ang), 0.1, sin(ang)) * 9.0
		var to := p + Vector3(cos(ang), 0.1, sin(ang)) * 6.0
		for s in 6:
			_mimic_q.append({"t": 0.4 + s * 0.46, "v": s % 4, "pos": from.lerp(to, s / 5.0), "cap": "[footsteps nearby, matching yours exactly]" if s == 0 else ""})
	_walk_t = 0.0


func _check_lost(p: Vector3) -> void:
	var k := world.key_at(p)
	var de := maxi(absi(k.x), absi(k.y))
	var ds := maxi(absi(k.x - stair_key.x), absi(k.y - stair_key.y))
	var late := t_level > 720.0 and not found_stair and de >= 2 and ds >= 2
	if (de >= lost_radius and ds >= 3) or late:
		lost = true
		Overlay.subtitle("[you are no longer sure which way you came]", 4.0)
		for key in world.chunks.keys():
			var kd: String = world.chunks[key]["meta"].get("kind", "maze")
			if kd != "maze":
				world.rebuild(key, true)


## Faint waves carried along the halls: the source is placed a few hallways
## ahead on the shortest corridor route to the stairwell, so it is heard
## "around corners" and can be followed.
func _waves_tick(p: Vector3) -> void:
	if lost or not world.chunks.has(stair_key):
		_waves.volume_db = lerpf(_waves.volume_db, -80.0, 0.5)
		_waves_near.volume_db = -80.0
		return
	var path := bfs(_node_of(p), _node_of(stair_bottom() + Vector3(-5.0, RISE, 0)))
	var found := not path.is_empty()
	var sb := stair_bottom()
	_waves_near.global_position = sb
	_waves_near.volume_db = -14.0
	if not found:
		_waves.volume_db = lerpf(_waves.volume_db, -80.0, 0.3)
		return
	var steps := path.size()
	if steps < 4:
		found_stair = true
	var ahead: Vector2i = path[mini(3, steps - 1)]
	var target := Vector3(ahead.x * P + 1.2, 1.0, ahead.y * P + 1.2)
	_waves.global_position = _waves.global_position.lerp(target, 0.5) if _waves.volume_db > -70.0 else target
	_waves.volume_db = lerpf(_waves.volume_db, clampf(-7.0 - steps * 0.55, -42.0, -8.0), 0.5)


## Shortest route through the loaded halls (node grid), [] if none.
func bfs(start: Vector2i, goal: Vector2i) -> Array:
	var prev := {start: start}
	var queue: Array = [start]
	var head := 0
	while head < queue.size() and head < 4000:
		var c: Vector2i = queue[head]
		head += 1
		if c == goal:
			var path: Array = [goal]
			while path.back() != start:
				path.append(prev[path.back()])
			path.reverse()
			return path
		for d in 4:
			if _g_open(c, d):
				var nb: Vector2i = c + D4[d]
				if not prev.has(nb) and world.chunks.has(Vector2i(floori(nb.x / float(NN)), floori(nb.y / float(NN)))):
					prev[nb] = c
					queue.append(nb)
	return []


func _node_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / P), floori(p.z / P))


func _g_open(g: Vector2i, d: int) -> bool:
	var key := Vector2i(floori(g.x / float(NN)), floori(g.y / float(NN)))
	var ch: Dictionary = world.chunks.get(key, {})
	if ch.is_empty():
		return false
	return edge_open(ch["meta"]["m"], g.x - key.x * NN, g.y - key.y * NN, d)


# ------------------------------------------------------------------- QA

## Stills need a remembered path: replay a short walk of touches first.
func qa_capture_plan() -> Array:
	var plan: Array = []
	var land := Vector3(1.5, RISE + 1.62, 13.2)
	plan.append({"name": "stairs", "pos": land, "target": Vector3(9.0, 0.6, 13.2), "prepare": func(): _fake_walk([Vector3(1.4, RISE, 13.2), Vector3(4.5, RISE * 0.5, 13.2), Vector3(8.4, 0, 13.2)], 0.0)})
	var sb := stair_bottom()
	var top := Vector3(stair_key.x * CS + band(13).x + 0.65, 0.0, sb.z)
	var route := bfs(_node_of(Vector3(8.4, 0, 13.2)), _node_of(top))
	if route.size() > 6:
		var tail: Array = route.slice(route.size() - 7)
		var pts: Array = []
		for nd in tail:
			pts.append(Vector3(nd.x * P + 1.2, 0.0, nd.y * P + 1.2))
		var cam: Vector3 = pts[pts.size() - 1]
		var look: Vector3 = pts[maxi(0, pts.size() - 4)]
		plan.append({"name": "dark", "pos": cam + Vector3(0, 1.62, 0), "target": look + Vector3(0, 1.3, 0), "prepare": func(): _fake_walk(pts, 0.0)})
	plan.append({"name": "waves", "pos": top + Vector3(0.0, 1.62, 0), "target": sb + Vector3(0, -0.2, 0), "prepare": func(): _fake_walk([top, top + Vector3(2.5, -1.2, 0), sb + Vector3(-0.4, -0.8, 0)], 0.0)})
	return plan


func _fake_walk(pts: Array, t_off: float) -> void:
	touch.clear()
	var space := get_world_3d().direct_space_state
	var total := 0
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n := int(a.distance_to(b) / 0.5) + 1
		for s in n:
			var p := a.lerp(b, float(s) / n)
			var dir := (b - a)
			dir.y = 0.0
			dir = dir.normalized()
			for ang in [-80.0, -30.0, 30.0, 80.0, 0.0]:
				var d := dir.rotated(Vector3.UP, deg_to_rad(ang))
				var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.UP * 1.2 + d * 1.0, 1)
				var hit := space.intersect_ray(q)
				if not hit.is_empty():
					_touch_at(hit["position"], 1.0)
			total += 1
	touch.upload(t_level + t_off)
