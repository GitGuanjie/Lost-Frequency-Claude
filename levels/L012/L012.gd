extends LevelBase
## Level 12 — "Matrix" (Backrooms Wikidot rev 110, accessed 2026-11-04; cite:
## Stretchsterz and Liryn, CC BY-SA 3.0). Dossier: docs/canon/levels/L012.md.
##
## SOURCE (article): the level censors itself (white image / static; uploaded
## footage becomes a colourless SMPTE screen; filenames censored); a small,
## brightly lit, white-painted room with a table, a chair and an adjacent
## locked door; no entities.
## SOURCE (Addendum I, testimony): beyond the room an infinite white abyss;
## things break down further from the table and chair; old beaten lamps,
## chairs, tables, drawers, some halfway through the floor; foggy memory
## that wears off; a hole under the immovable table; copycat doors that bring
## you back to the main room; the exit ritual (chair ~15 min, try the door,
## centre, nook, copycat door, wait exactly one hour, try again).
## SOURCE (Exits): the door may lead to Levels 1, 4, 10, 19, 23, 25, 34 or 287.
## ADAPTATION: level time runs compressed (x12, x60 seated) and is read off
## the wanderer's wristwatch; the transcript on the table is a clue device;
## the abyss is a finite streaming window of 32 m chunks in white fog.

const Props := preload("res://levels/L012/L012_props.gd")
const Censor := preload("res://levels/L012/L012_censor.gd")

const RI := 2.2          # room interior half-size
const RO := 2.5          # room shell outer half-size
const WT := 0.3
const H := 2.7
const PAD := 3.9         # room-owned floor pad (nooks and door recess)
const CS := 32.0
const NW := 1.4          # nook width / depth / height
const ND := 1.2
const NH := 2.25
const DOOR_X := 0.95
const CHAIR := Vector3(0.0, 0.0, -0.95)
const ARRIVE_IN := Vector3(DOOR_X, 0.03, 1.55)
const RATE := 12.0
const RATE_SEATED := 60.0
const SEAT_NEED := 13.5 * 60.0
const WAIT := 3600.0
const WINDOW := 150.0
const EDGES := ["L012>L001#1", "L012>L004#2", "L012>L010#3", "L012>L019#4",
	"L012>L023#5", "L012>L025#6", "L012>L034#7", "L012>L287#8"]
enum { R_IDLE, R_SAT, R_TRIED, R_CENTRED, R_OUT, R_WAIT, R_OPEN }

const NOTE_TEXT := "[i]A typed transcript, soft at the edges from handling.[/i]\n\nThis isn't only a room any more. Past the nooks it's white, all the way out, and the further you get from the table and chair the worse things get. Old furniture out there, some of it sunk into the floor. Your memory goes foggy. It comes back once you're here again.\n\nThe doors you find out in the white are copies. Go through one and you're standing in this room.\n\nWhat worked for us, after a lot of trial and error:\n1. Sit in this chair. Stay about a quarter of an hour.\n2. Get up, go to the door, try the handle. It should be locked. Try it anyway.\n3. Back to the middle of the room, then out through one of the nooks. Find a copy door.\n4. Go through it. You'll be back here.\n5. Wait one hour, as exact as you can manage, then try the door again. Still locked? Start over.\n\nIt let us out onto one of the early levels. Don't count on remembering how."

var world: ChunkWorld
var censor: Censor
var qa_fixture := false
var clock := 0.0                 # level time of day, seconds
var step := R_IDLE
var t0 := 0.0
var tries := 0
var lucky_chance := 0.02
var seated := false
var seat_t := 0.0
var fog := 0.0
var table_tries := 0
var _open_edge := ""
var _seat_real := 0.0
var _seat_mark := false
var _saved_speed: Array = []
var _main_pivot: Node3D
var _main_it: Interactable
var _note: Interactable
var _doors: Array = []           # copycat door records
var _watch: Label
var _watch_t := 0.0
var _fog_bucket := -1
var _fog_said := 0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 150.0
	rules["reverb_room"] = 0.2
	rules["reverb_wet"] = 0.05
	indoor_env(Color(0.96, 0.96, 0.98), 0.85, Color(0.97, 0.97, 0.98), 0.026)
	environment.background_color = Color(1.0, 1.0, 1.0)
	environment.background_energy_multiplier = 1.15
	environment.fog_light_color = Color(1.0, 1.0, 1.0)
	environment.fog_light_energy = 1.1
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.12
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	var top := DirectionalLight3D.new()   # light from nowhere: soft pools under objects
	top.rotation_degrees = Vector3(-76.0, 32.0, 0.0)
	top.light_energy = 0.55
	top.shadow_enabled = true
	top.shadow_blur = 2.5
	top.directional_shadow_max_distance = 45.0
	add_child(top)
	Props.materials()
	lights.setup(1, 1)
	lights.add_anchor(Vector3(0, H - 0.3, 0), Color(1.0, 0.99, 0.96), 2.8, 8.0, 0.0, "room")
	clock = 14.0 * 3600.0 + float(rng.randi() % 3600)
	_room()
	_abyss_anchors()
	world = ChunkWorld.new()
	world.name = "Abyss"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(key): _doors = _doors.filter(func(d): return d["key"] != key))
	world.build_around(Vector3.ZERO, 2)
	for e in EDGES:
		var t := add_exit(e, "condition", Vector3(DOOR_X, 1.0, RO + 0.35), Vector3(0.8, 2.0, 0.9), "")
		if t:
			t.condition = func(): return _open_edge == e
			t.fired.connect(_on_door_exit)
	add_arrival("start", Vector3(-1.3, 0.05, -1.4), -149.0)
	add_arrival("from_L011", Vector3(-1.6, 0.05, -0.4), -90.0)
	add_arrival("from_L019", ARRIVE_IN, 0.0)
	censor = Censor.new()
	censor.name = "Censor"
	add_child(censor)
	censor.setup(hash([level_seed, "censor"]))
	var hl := CanvasLayer.new()
	hl.layer = 52
	add_child(hl)
	_watch = UITheme.label("", 17, Color(0.96, 0.96, 0.93, 0.9))
	_watch.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_watch.position = Vector2(28, -116)
	_watch.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_watch.add_theme_constant_override("outline_size", 5)
	hl.add_child(_watch)
	sound.bed("room_tone", {"cutoff": 190.0}, -31.0)
	if qa_fixture:
		# QA fixture: the ritual is already complete and the door stands open on
		# Gab's documented route (Level 1), so the walker bot can use it.
		step = R_OPEN
		_open_edge = EDGES[0]
		_main_pivot.rotation.y = deg_to_rad(-95.0)
		_main_it.prompt = ""
	add_landmark("White room (table and chair)", Vector3.ZERO)


# ------------------------------------------------------------- main room

## Box in a wall-side frame: tt along the wall, nn outward from the centre.
func _sb(k: GeoKit, nrm: Vector3, tt0: float, tt1: float, nn0: float, nn1: float, y0: float, y1: float, mat: String, collide := true) -> void:
	var tg := Vector3(absf(nrm.z), 0.0, absf(nrm.x))
	var a := tg * tt0 + nrm * nn0 + Vector3.UP * y0
	var b := tg * tt1 + nrm * nn1 + Vector3.UP * y1
	k.box_mm(Vector3(minf(a.x, b.x), y0, minf(a.z, b.z)), Vector3(maxf(a.x, b.x), y1, maxf(a.z, b.z)), mat, GeoKit.ALL, collide)


func _room() -> void:
	var k := kit("Room")
	k.slab(-RI, -RI, RI, RI, 0.0, 0.3, "l12_room_floor", GeoKit.PY)
	for r in [[-PAD, -PAD, PAD, -RI], [-PAD, RI, PAD, PAD], [-PAD, -RI, -RI, RI], [RI, -RI, PAD, RI]]:
		k.slab(r[0], r[1], r[2], r[3], 0.0, 0.3, "l12_floor", GeoKit.PY)
	k.box_mm(Vector3(-RO, H, -RO), Vector3(RO, H + 0.2, RO), "l12_ceiling", GeoKit.NY)
	k.box_mm(Vector3(-RO, H, -RO), Vector3(RO, H + 0.2, RO), "l12_wall", GeoKit.PY | GeoKit.SIDES, false)
	k.panel(Vector3(0, H - 0.004, 0), 1.2, 1.2, "l12_panel")
	var cz := RI + WT * 0.5
	k.wall(Vector3(-RO, 0, -cz), Vector3(RO, 0, -cz), H, WT, "l12_wall", [{"at": -0.6 + RO, "w": NW, "h": NH}])
	k.wall(Vector3(-RO, 0, cz), Vector3(RO, 0, cz), H, WT, "l12_wall", [{"at": DOOR_X + RO, "w": Props.DOOR_W, "h": Props.DOOR_H}])
	k.wall(Vector3(-cz, 0, -RI), Vector3(-cz, 0, RI), H, WT, "l12_wall", [{"at": -0.4 + RI, "w": NW, "h": NH}])
	k.wall(Vector3(cz, 0, -RI), Vector3(cz, 0, RI), H, WT, "l12_wall", [{"at": 0.7 + RI, "w": NW, "h": NH}])
	for bb in [[Vector3(-RI, 0, -RI + 0.01), Vector3(RI, 0, -RI + 0.01), -0.6 + RI, NW], [Vector3(-RI, 0, RI - 0.01), Vector3(RI, 0, RI - 0.01), DOOR_X + RI, Props.DOOR_W + 0.14],
			[Vector3(-RI + 0.01, 0, -RI), Vector3(-RI + 0.01, 0, RI), -0.4 + RI, NW], [Vector3(RI - 0.01, 0, -RI), Vector3(RI - 0.01, 0, RI), 0.7 + RI, NW]]:
		k.wall(bb[0], bb[1], 0.09, 0.02, "l12_trim", [{"at": bb[2], "w": bb[3], "h": 1.0}], GeoKit.SIDES | GeoKit.PY)
	# nooks: alcoves past the wall whose back is half open onto the white
	for nk in [[Vector3(0, 0, -1), -0.6], [Vector3(-1, 0, 0), -0.4], [Vector3(1, 0, 0), 0.7]]:
		var n: Vector3 = nk[0]
		var s: float = nk[1]
		_sb(k, n, s - NW * 0.5 - 0.15, s - NW * 0.5, RO, RO + ND + 0.15, 0.0, H, "l12_wall")
		_sb(k, n, s + NW * 0.5, s + NW * 0.5 + 0.15, RO, RO + ND + 0.15, 0.0, H, "l12_wall")
		_sb(k, n, s - NW * 0.5 - 0.15, s + NW * 0.5 + 0.15, RO, RO + ND + 0.15, NH, H, "l12_wall")
		_sb(k, n, s - NW * 0.5, s - NW * 0.5 + 0.6, RO + ND, RO + ND + 0.15, 0.0, NH, "l12_wall")
	# the door: frame, a recess that is dark beyond, and a hinged leaf
	var sn := Vector3(0, 0, 1)
	_sb(k, sn, DOOR_X - 0.6, DOOR_X - 0.45, RO, RO + 1.05, 0.0, H, "l12_wall")
	_sb(k, sn, DOOR_X + 0.45, DOOR_X + 0.6, RO, RO + 1.05, 0.0, H, "l12_wall")
	_sb(k, sn, DOOR_X - 0.62, DOOR_X + 0.62, RO + 0.9, RO + 1.05, 0.0, H, "l12_wall")
	_sb(k, sn, DOOR_X - 0.62, DOOR_X + 0.62, RO, RO + 1.05, 2.1, H, "l12_wall")
	var lz := cz + 0.03
	for b in [[-0.45, -0.44, lz, RO + 0.9, 0.0, 2.1], [0.44, 0.45, lz, RO + 0.9, 0.0, 2.1], [-0.45, 0.45, RO + 0.89, RO + 0.9, 0.0, 2.1],
			[-0.45, 0.45, lz, RO + 0.9, 2.04, 2.05], [-0.45, 0.45, lz, RO + 0.9, 0.0, 0.006]]:
		_sb(k, sn, DOOR_X + b[0], DOOR_X + b[1], b[2], b[3], b[4], b[5], "unlit_black", false)
	Props.frame(k, Transform3D(Basis(), Vector3(DOOR_X, 0, cz)), WT, "l12_trim")
	_main_pivot = _door_leaf(self, Vector3(DOOR_X + Props.DOOR_W * 0.5, 0, cz), 0.0)
	_main_it = add_interactable(Vector3(DOOR_X, 1.0, cz), Vector3(0.95, 2.05, 0.42), "Try the handle", func(_p): _try_handle())
	# table over the hole (the table will not move), and the chair
	Props.table(k, Transform3D(), "l12_table", "l12_table", 1.2, 0.8, 0.76)
	k.quad(Vector3(0, 0.004, 0), Vector3.UP, Vector3(0.3, 0, 0), Vector3(0, 0, 0.22), "unlit_black")
	Props.chair(k, Transform3D(Basis(), CHAIR), "l12_table", "l12_table")
	k.commit()
	add_interactable(Vector3(0, 0.39, 0), Vector3(1.26, 0.78, 0.86), "Move the table", _table_interact)
	add_interactable(CHAIR + Vector3(0, 0.5, 0), Vector3(0.62, 1.0, 0.6), "Sit on the chair", func(_p): _sit())
	_note = add_note("L012_transcript", "Typed transcript", NOTE_TEXT, Vector3(0.3, 0.785, 0.12), Vector3(0.4, 0.05, 0.3))
	add_shot("room", Vector3(-1.85, 1.55, -1.85), Vector3(1.05, 0.72, 1.9))


func _door_leaf(parent: Node, hinge: Vector3, yaw: float) -> Node3D:
	var pv := Node3D.new()
	pv.position = hinge
	pv.rotation.y = yaw
	parent.add_child(pv)
	var kl := GeoKit.new(pv, "Leaf")
	Props.leaf(kl, "l12_door", "l12_door_panel", "l12_knob")
	kl.commit()
	return pv


# ----------------------------------------------------------------- abyss

## Hand-placed anchors near the room: the first copycat door and sunken pieces.
func _abyss_anchors() -> void:
	var k := kit("Anchors")
	_copycat(self, k, Vector3(-6.5, 0, 10.5), deg_to_rad(20.0), Vector2i(999, 999))
	_copycat(self, k, Vector3(13.0, 0, -8.0), deg_to_rad(-65.0), Vector2i(999, 999))
	_place(k, 1, Vector3(-9.3, 0, 12.8), 0.8, deg_to_rad(16.0), Vector3(1, 0, 0.4), 0.45, 0)
	_place(k, 3, Vector3(-3.0, 0, 14.6), 2.6, deg_to_rad(9.0), Vector3(0.3, 0, 1), 0.42, 1)
	_place(k, 2, Vector3(-11.2, 0, 7.4), 0.0, deg_to_rad(21.0), Vector3(0.2, 0, -1), 0.0, 0)
	_place(k, 0, Vector3(-3.9, 0, 12.9), 0.5, deg_to_rad(13.0), Vector3(1, 0, 0.2), 0.55, 1)
	_place(k, 1, Vector3(4.5, 0, -14.0), 2.0, deg_to_rad(4.0), Vector3(0, 0, 1), 0.0, 0)
	_place(k, 3, Vector3(16.0, 0, 9.0), 4.0, deg_to_rad(28.0), Vector3(1, 0, 0), 0.5, 0)
	k.commit()
	add_shot("abyss", Vector3(-8.3, 1.45, 16.4), Vector3(-5.6, 1.1, 9.6), {"style": {"noise": 0.05, "band": 0.07, "desat": 0.3, "haze": 0.04}})


## One piece of old furniture: kind 0 table, 1 chair, 2 lamp, 3 drawers.
func _place(k: GeoKit, kind: int, p: Vector3, yaw: float, tilt: float, axis: Vector3, sink: float, broken: int) -> void:
	var hgt: float = [0.74, 0.96, 1.64, 0.9][kind]
	var bas := Basis(axis.normalized(), tilt) * Basis(Vector3.UP, yaw)
	var xf := Transform3D(bas, p + Vector3.DOWN * sink * hgt)
	match kind:
		0: Props.table(k, xf, "l12_wood_old", "l12_wood_old", 1.0, 0.65, 0.74, broken)
		1: Props.chair(k, xf, "l12_wood_old" if broken == 0 else "l12_wood_pale", "l12_seat_old")
		2: Props.lamp(k, xf, "l12_metal_old", "l12_shade")
		_: Props.drawers(k, xf, "l12_paint_old" if broken == 0 else "l12_wood_old", "l12_wood_pale", "l12_metal_old")


func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "abyss", cx, cz])
	var k := GeoKit.new(node, "K")
	var ox := cx * CS
	var oz := cz * CS
	var d := Vector2(ox + CS * 0.5, oz + CS * 0.5).length()
	var b := clampf((d - 24.0) / 220.0, 0.0, 1.0)       # breakdown with distance
	var fm := "l12_floor" if b < 0.3 else ("l12_floor_worn" if b < 0.6 else "l12_floor_broken")
	var plates := {}
	if b > 0.55:
		# far out the floor itself breaks into shifted plates (<= 0.26 m steps)
		var ps := CS / 4.0
		for j in 4:
			for i in 4:
				var dy := r.randf_range(-0.26, 0.26) if r.randf() < (b - 0.55) * 0.9 else 0.0
				plates[Vector2i(i, j)] = dy
				k.box_mm(Vector3(ox + i * ps, -1.0, oz + j * ps), Vector3(ox + (i + 1) * ps, dy, oz + (j + 1) * ps), fm, GeoKit.SIDES | GeoKit.PY)
	else:
		_floor_minus_pad(k, ox, oz, fm)
	var avoid: Array = []
	if d > 40.0 and r.randf() < 0.32:
		var dp := Vector3(ox + r.randf_range(5.0, CS - 5.0), 0, oz + r.randf_range(5.0, CS - 5.0))
		dp.y = _plate_y(plates, dp, ox, oz)
		_copycat(node, k, dp, r.randf() * TAU, Vector2i(cx, cz))
		avoid.append(dp)
	var n := int(round(lerpf(1.0, 6.0, b))) + r.randi() % 2
	for i in n:
		var p := Vector3(ox + r.randf_range(1.5, CS - 1.5), 0, oz + r.randf_range(1.5, CS - 1.5))
		if Vector2(p.x, p.z).length() < 18.0 or avoid.any(func(a): return a.distance_to(Vector3(p.x, a.y, p.z)) < 3.2):
			continue
		p.y = _plate_y(plates, p, ox, oz)
		_random_piece(k, r, p, b)
		if r.randf() < b * 0.45:   # pieces clipping through each other
			_random_piece(k, r, p + Vector3(r.randf_range(-0.5, 0.5), 0, r.randf_range(-0.5, 0.5)), b)
	k.commit()
	return {"b": b, "doors": avoid.size()}


func _plate_y(plates: Dictionary, p: Vector3, ox: float, oz: float) -> float:
	if plates.is_empty():
		return 0.0
	var ps := CS / 4.0
	return plates.get(Vector2i(clampi(int((p.x - ox) / ps), 0, 3), clampi(int((p.z - oz) / ps), 0, 3)), 0.0)


func _random_piece(k: GeoKit, r: RandomNumberGenerator, p: Vector3, b: float) -> void:
	var kind := r.randi() % 5
	kind = 1 if kind == 4 else kind
	var sink := 0.0
	if r.randf() < lerpf(0.3, 0.85, b):
		sink = r.randf_range(0.12, lerpf(0.35, 0.75, b))
	var tilt := deg_to_rad(r.randf_range(0.0, lerpf(5.0, 38.0, b)))
	if kind == 2 and r.randf() < 0.3:
		tilt = deg_to_rad(84.0)   # a lamp lying on its side
		sink = 0.0
	var ang := r.randf() * TAU
	_place(k, kind, p, r.randf() * TAU, tilt, Vector3(cos(ang), 0, sin(ang)), sink, (r.randi() % 3) if b > 0.4 else 0)


func _floor_minus_pad(k: GeoKit, ox: float, oz: float, fm: String) -> void:
	var x0 := ox
	var x1 := ox + CS
	var z0 := oz
	var z1 := oz + CS
	if x1 <= -PAD or x0 >= PAD or z1 <= -PAD or z0 >= PAD:
		k.slab(x0, z0, x1, z1, 0.0, 0.3, fm, GeoKit.PY)
		return
	if x0 < -PAD:
		k.slab(x0, z0, -PAD, z1, 0.0, 0.3, fm, GeoKit.PY)
	if x1 > PAD:
		k.slab(PAD, z0, x1, z1, 0.0, 0.3, fm, GeoKit.PY)
	var mx0 := maxf(x0, -PAD)
	var mx1 := minf(x1, PAD)
	if z0 < -PAD:
		k.slab(mx0, z0, mx1, -PAD, 0.0, 0.3, fm, GeoKit.PY)
	if z1 > PAD:
		k.slab(mx0, PAD, mx1, z1, 0.0, 0.3, fm, GeoKit.PY)


## A copycat door: the main door and a stretch of its white wall, standing
## alone in the abyss. Opening it and walking through returns you to the room.
func _copycat(parent: Node3D, k: GeoKit, p: Vector3, yaw: float, key: Vector2i) -> void:
	var bas := Basis(Vector3.UP, yaw)
	k.wall(p - bas.x * 1.45, p + bas.x * 1.45, H, WT, "l12_wall", [{"at": 1.45, "w": Props.DOOR_W, "h": Props.DOOR_H}])
	Props.frame(k, Transform3D(bas, p), WT, "l12_trim")
	var rec := {"key": key, "open": false, "busy": false, "yaw": yaw, "pos": p}
	rec["pivot"] = _door_leaf(parent, p + bas.x * (Props.DOOR_W * 0.5), yaw)
	var it := Interactable.new()
	parent.add_child(it)
	it.setup(p + Vector3.UP * 1.0, Vector3(0.95, 2.05, 0.42), "Open the door", func(_pl): _open_copycat(rec))
	it.rotation.y = yaw
	rec["it"] = it
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.position = p + Vector3.UP * 1.0
	area.rotation.y = yaw
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.8, 2.0, 0.5)
	cs.shape = sh
	area.add_child(cs)
	parent.add_child(area)
	area.body_entered.connect(func(bd):
		if bd is Player and rec["open"]:
			_copycat_enter(rec))
	_doors.append(rec)


func _swing(pivot: Node3D, yaw: float, open: bool) -> void:
	if not is_instance_valid(pivot):
		return
	var old: Variant = pivot.get_meta("tw") if pivot.has_meta("tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var tw := create_tween()
	pivot.set_meta("tw", tw)
	tw.tween_property(pivot, "rotation:y", yaw + (deg_to_rad(-95.0) if open else 0.0), 0.7).set_trans(Tween.TRANS_SINE)


func _open_copycat(rec: Dictionary) -> void:
	if rec["open"]:
		return
	rec["open"] = true
	(rec["it"] as Interactable).prompt = ""
	_swing(rec["pivot"], rec["yaw"], true)
	sound.play_at("creak", {"freq": 120.0}, rec["pos"] + Vector3.UP, -10.0, "[the door creaks open]")


func _close_copycat(rec: Dictionary) -> void:
	rec["open"] = false
	rec["busy"] = false
	if is_instance_valid(rec["it"]):
		(rec["it"] as Interactable).prompt = "Open the door"
	_swing(rec["pivot"], rec["yaw"], false)


## SOURCE: copycat doors bring you back to the main room.
func _copycat_enter(rec: Dictionary) -> void:
	if rec["busy"] or player == null:
		return
	rec["busy"] = true
	player.global_position = ARRIVE_IN
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	Overlay.glitch(0.7)
	censor.flash(0.35)
	if step == R_OUT or step == R_WAIT:
		step = R_WAIT
		t0 = clock
	Overlay.subtitle("[the white room again. Your watch reads %s]" % _fmt(clock), 4.0)
	get_tree().create_timer(0.8).timeout.connect(func(): _close_copycat(rec))


# --------------------------------------------------------------- ritual

func _in_room(p: Vector3) -> bool:
	return absf(p.x) < RI and absf(p.z) < RI


func _outside(p: Vector3) -> bool:
	return maxf(absf(p.x), absf(p.z)) > PAD


func _ritual_track(p: Vector3) -> void:
	if step == R_TRIED and Vector2(p.x, p.z).length() < 1.4:
		step = R_CENTRED
	elif (step == R_SAT or step == R_TRIED) and _outside(p):
		step = R_IDLE    # the door must be tried, even knowing it is locked
	elif step == R_CENTRED and _outside(p):
		step = R_OUT


func _sit() -> void:
	if seated or player == null:
		return
	seated = true
	seat_t = 0.0
	_seat_real = 0.0
	_seat_mark = false
	_saved_speed = [player.walk_speed, player.sprint_speed, player.jump_velocity, player.crouch_speed]
	player.walk_speed = 0.0
	player.sprint_speed = 0.0
	player.jump_velocity = 0.0
	player.crouch_speed = 0.0
	player.velocity = Vector3.ZERO
	player.global_position = CHAIR + Vector3(0, 0.47, 0)
	player.rotation.y = PI
	Overlay.toast("You sit down at the table. (Move to stand up.)", 3.5)


func _stand() -> void:
	if not seated:
		return
	seated = false
	player.walk_speed = _saved_speed[0]
	player.sprint_speed = _saved_speed[1]
	player.jump_velocity = _saved_speed[2]
	player.crouch_speed = _saved_speed[3]
	player.global_position = CHAIR + Vector3(-0.72, 0.03, 0.15)
	if seat_t >= SEAT_NEED and step < R_WAIT:
		step = R_SAT
	checkpoint("chair")


## The main door handle. Returns true when the door opens.
func _try_handle() -> bool:
	if step == R_OPEN:
		return true
	tries += 1
	var opened := false
	if step == R_WAIT:
		opened = absf((clock - t0) - WAIT) <= WINDOW
		if not opened:
			step = R_IDLE
	elif step == R_SAT:
		opened = rng.randf() < lucky_chance    # "If it opens, lucky you"
		if not opened:
			step = R_TRIED
	if opened:
		_open_main(EDGES[rng.randi() % EDGES.size()])
	else:
		sound.play_at("knock", {"hits": 2}, Vector3(DOOR_X, 1.0, RI), -12.0, "[the handle turns a little and stops: locked]")
	return opened


func _open_main(edge: String) -> void:
	step = R_OPEN
	_open_edge = edge
	_main_it.prompt = ""
	_swing(_main_pivot, 0.0, true)
	sound.play_at("creak", {"freq": 95.0}, Vector3(DOOR_X, 1.0, RI), -8.0, "[the latch gives. The door swings open onto darkness]")


func _on_door_exit(_edge: String) -> void:
	step = R_IDLE
	_open_edge = ""
	get_tree().create_timer(2.0).timeout.connect(func():
		if step != R_OPEN and is_instance_valid(_main_pivot):
			_swing(_main_pivot, 0.0, false)
			_main_it.prompt = "Try the handle")


func _table_interact(_p) -> void:
	table_tries += 1   # SOURCE: "the table won't move" (it is static geometry)
	Overlay.subtitle("[the table won't budge. Something dark under it, out of reach]", 3.0)


func _fmt(t: float) -> String:
	return "%02d:%02d" % [int(t / 3600.0) % 24, int(t / 60.0) % 60]


# --------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story() and SaveService.flag(stable_id, "arrived", false) == false:
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[silence. White paint, a table, a chair, a door]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": EDGES[0], "target": Vector3(DOOR_X, 0.05, RO + 0.35),
			"note": "QA fixture: ritual pre-completed, main door open on Gab's Level 1 route"})


func _input(event: InputEvent) -> void:
	if built and event.is_action_pressed("screenshot"):
		censor.censored_screenshot()
		get_viewport().set_input_as_handled()


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	var dist := Vector2(p.x, p.z).length()
	clock += delta * (RATE_SEATED if seated else RATE)
	if seated:
		seat_t += delta * RATE_SEATED
		_seat_real += delta
		player.head.position.y = 0.74
		player.velocity = Vector3(0, player.velocity.y, 0)
		if seat_t >= 900.0 and not _seat_mark:
			_seat_mark = true
			sound.play_at("creak", {"freq": 160.0}, CHAIR + Vector3.UP * 0.5, -14.0, "[the chair creaks]")
		if _seat_real > 0.6 and player._wish_dir.length() > 0.4:
			_stand()
	_ritual_track(p)
	_update_fog(delta, dist, p)
	var cap := censor.tick(delta, Censor.censor_level(dist, fog), fog)
	if cap != "":
		Overlay.subtitle(cap, 1.6)
	censor.censor_rec(Time.get_ticks_msec())
	_watch_t -= delta
	if _watch_t <= 0.0:
		_watch_t = 0.5
		_watch.text = "wristwatch  " + _fogged_digits(_fmt(clock))
	_watch.visible = Overlay.hud.visible and Overlay.hud.modulate.a > 0.5


## SOURCE: memories grow foggy out in the white; the effect is not permanent.
func _update_fog(delta: float, dist: float, p: Vector3) -> void:
	if _in_room(p):
		fog = maxf(0.0, fog - delta * (0.06 if seated else 0.03))
	elif not _outside(p):
		fog = maxf(0.0, fog - delta * 0.01)
	else:
		fog = minf(1.0, fog + delta * (0.002 + clampf(dist / 60.0, 0.0, 1.5) * 0.01))
	environment.fog_density = 0.026 + fog * 0.035
	# the room is lit by its ceiling light; the white outside by nothing at all
	var amb := 0.3 if not _outside(p) else 0.85
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, amb, clampf(delta * 3.0, 0.0, 1.0))
	if fog > 0.35 and _fog_said < 1:
		_fog_said = 1
		Overlay.subtitle("[your memories feel foggy]", 3.0)
	elif fog > 0.7 and _fog_said < 2:
		_fog_said = 2
		Overlay.subtitle("[you can't quite remember the way back]", 3.0)
	elif fog < 0.2:
		_fog_said = 0
	var bucket := int(fog * 10.0)
	if bucket != _fog_bucket and _note:
		_fog_bucket = bucket
		_note.note_text = fogged_text(NOTE_TEXT, fog)


## The transcript reads worse while your memory is fogged.
static func fogged_text(text: String, f: float) -> String:
	if f < 0.12:
		return text
	var prob := (f - 0.1) * 0.9
	var lines := text.split("\n")
	var out: PackedStringArray = []
	var idx := 0
	for line in lines:
		var words := line.split(" ")
		for i in words.size():
			idx += 1
			var w: String = words[i]
			if w.contains("[") or w.length() < 3:
				continue
			if float(absi(hash([idx, "fog"])) % 1000) / 1000.0 < prob:
				words[i] = "▒".repeat(w.length())
		out.append(" ".join(words))
	return "\n".join(out)


func _fogged_digits(s: String) -> String:
	if fog < 0.45:
		return s
	var o := ""
	for ch in s:
		o += "?" if (ch != ":" and randf() < (fog - 0.45) * 1.6) else ch
	return o


# -------------------------------------------------------------------- QA

func qa_capture_plan() -> Array:
	var plan: Array = []
	for s in qa_shots:
		var shot: Dictionary = s.duplicate()
		var style: Dictionary = s.get("style", {"noise": 0.03})
		var pos: Vector3 = s["pos"]
		shot["prepare"] = func():
			censor.capture_style = style
			_main_pivot.rotation.y = 0.0
			world.build_around(pos, 2)
		plan.append(shot)
	return plan


func qa_self_test() -> Array:
	var out: Array = []
	await get_tree().process_frame
	var keep_lucky := lucky_chance
	lucky_chance = 0.0
	step = R_IDLE
	_open_edge = ""
	var early := false
	for i in 4:
		early = _try_handle() or early
	out.append({"what": "main door stays locked without the procedure", "ok": not early and step == R_IDLE})
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(0.0, 0.3, 0.0)
	q.collision_mask = 1
	var blocked := not get_world_3d().direct_space_state.intersect_point(q, 1).is_empty()
	_table_interact(null)
	out.append({"what": "hole under the table is inaccessible and the table won't move", "ok": blocked and table_tries > 0})
	var runs: Array = []
	for wait in [1800.0, WAIT + 40.0]:
		_sit()
		clock += 900.0
		seat_t += 900.0
		_stand()
		var s1 := step
		_try_handle()
		var s2 := step
		_ritual_track(Vector3(0.9, 0.05, -0.9))
		_ritual_track(Vector3(-6.0, 0.05, -8.0))
		var s3 := step
		_doors[0]["busy"] = false
		_copycat_enter(_doors[0])
		var back := _in_room(player.global_position)
		var s4 := step
		clock += wait
		var opened := _try_handle()
		runs.append({"wait_s": wait, "steps": [s1, s2, s3, s4], "back_in_room": back, "opened": opened, "edge": _open_edge, "after": step})
	var good: bool = runs[0]["steps"] == [R_SAT, R_TRIED, R_OUT, R_WAIT] and not runs[0]["opened"] and runs[0]["after"] == R_IDLE \
		and runs[1]["steps"] == [R_SAT, R_TRIED, R_OUT, R_WAIT] and runs[1]["opened"] and runs[1]["edge"] in EDGES
	out.append({"what": "timed ritual: early retry resets, one-hour retry opens onto a listed level", "ok": good, "detail": runs})
	out.append({"what": "copycat doors return you to the main room", "ok": runs[0]["back_in_room"] and runs[1]["back_in_room"]})
	var cond_ok := false
	for t in exits:
		if is_instance_valid(t) and t.edge_id == _open_edge:
			cond_ok = t.condition.call()
	out.append({"what": "eight sourced destinations wired to the door", "ok": exits.size() == 8 and cond_ok, "detail": exits.size()})
	_sit()
	for i in 10:
		await get_tree().physics_frame
	var on_seat := player.global_position.y > 0.38 and Vector2(player.global_position.x - CHAIR.x, player.global_position.z - CHAIR.z).length() < 0.25
	_stand()
	out.append({"what": "the wanderer can sit on the main-room chair", "ok": on_seat})
	var d0: Dictionary = _doors[0]
	_close_copycat(d0)
	_open_copycat(d0)
	player.global_position = d0["pos"] + Vector3.UP * 0.05
	for i in 6:
		await get_tree().physics_frame
	out.append({"what": "walking through an open copycat door lands in the main room", "ok": _in_room(player.global_position), "detail": player.global_position})
	step = R_IDLE
	_open_edge = ""
	_swing(_main_pivot, 0.0, false)
	_main_it.prompt = "Try the handle"
	lucky_chance = keep_lucky
	# censorship grows with distance from the table and chair
	var counts: Array = []
	for dd in [1.0, 150.0]:
		censor.events = {"white": 0, "static": 0}
		for i in 3000:
			censor.tick(0.1, Censor.censor_level(dd, 0.0), 0.0)
		counts.append(censor.events["white"] + censor.events["static"])
	out.append({"what": "self-censoring events grow further from the table and chair", "ok": counts[1] > counts[0] * 2 and counts[0] > 0, "detail": counts})
	var shot := censor.censored_screenshot(true)
	var img: Image = shot["image"]
	var grey := true
	for pt in [Vector2i(100, 100), Vector2i(500, 200), Vector2i(800, 500), Vector2i(1200, 700), Vector2i(640, 520)]:
		var c := img.get_pixelv(pt)
		grey = grey and absf(c.r - c.g) < 0.01 and absf(c.g - c.b) < 0.01
	out.append({"what": "screenshots save a colourless SMPTE screen under a censored name", "ok": grey and str(shot["path"]).contains("█") and not str(shot["path"]).contains("L012")})
	Overlay.rec_label.text = "● REC   12:00:00   LEVEL 12"
	censor.censor_rec(0)
	out.append({"what": "REC timestamp and label are censored", "ok": not Overlay.rec_label.text.contains("12:00")})
	fog = 0.0
	for i in 60:
		_update_fog(1.0, 60.0, Vector3(0, 0, 60))
	var high := fog
	var masked := _note.note_text != NOTE_TEXT
	for i in 60:
		_update_fog(1.0, 0.0, Vector3.ZERO)
	out.append({"what": "memory fog rises in the abyss, blurs the transcript, fades in the room", "ok": high > 0.5 and masked and fog < 0.1 and _note.note_text == NOTE_TEXT, "detail": [high, fog]})
	world.target = null
	world.build_around(Vector3(200, 0, 200), 1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(201, 2.0, 203), Vector3(201, -2.0, 203), 1)
	var floor_far := not get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	world.target = player
	out.append({"what": "white abyss streams floor far from the room (no edge)", "ok": floor_far and _doors.size() >= 2, "detail": _doors.size()})
	return out
