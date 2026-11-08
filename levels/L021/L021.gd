extends LevelBase
## Level 21 "Numbered Doors" (Backrooms Wikidot rev 101, accessed 2026-11-04;
## Stretchsterz, CC BY-SA 3.0). Dossier: docs/canon/levels/L021.md.
##
## PLAN (read -> design):
## - SOURCE: four very long hallways (~26 miles each) meeting at a small open square with
##   chairs and a desk; entities never appear in the square. -> a central square with the
##   front desk; four hallways streamed by ChunkWorld (a finite window, never 26 miles).
## - SOURCE: doors repeat on both sides of every hallway; the halls shift and can become
##   blocked. -> doors every 1.5 m (alternating sides); unseen segments re-roll their doors
##   and sometimes end in a wall (peripheral shift).
## - SOURCE door table: 105 -> Level 0, 356 -> Level 356, sandstone -> can lead to Level 46,
##   34 -> Level 669, smiley -> a party, 8-20 -> their levels, unlabelled -> Level 1.5;
##   other doors: usually somewhere else in Level 21 or onto a wall, rarely random places.
## - SOURCE: Clickers are common in the hallways (heard, never fought); Almond Water, Level
##   Keys and Firesalt lie in the halls; anyone met here is not to be trusted.
## - SOURCE: the neon red "Exit" door in the hallway to the right of the front desk opens
##   onto three dark, non-shifting hallways with more resources, organised entities heard in
##   droves, and repeating doors that lead only to sub-sections. ADAPTATION: those halls lie
##   one storey down a stair behind the door (the page gives no geometry).
## - Lighting and sound are not stated: condo-style ceiling lights (page image: "Hallway at
##   Meridian Condo"), a quiet hum, and clicks.

const Halls := preload("res://levels/L021/L021_halls.gd")
const CS := 24.0
const C := Vector3(12.0, 0.0, 12.0)
const WARM := Color(1.0, 0.86, 0.66)

var H
var world: ChunkWorld
var qa_fixture := false
var exit_open := false
var items := {"Almond Water": 0, "Level Key": 0, "Firesalt": 0}
var _taken := {}
var _exit_leaf: Node3D
var _exit_body: StaticBody3D
var _click_t := 6.0
var _dark_t := 0.0
var _march_t := 0.0
var _warps := 0
var _walls := 0
var _hum: AudioStreamPlayer
var _march: AudioStreamPlayer
var _was_in_hall := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.22
	rules["kill_y"] = -40.0
	indoor_env(Color(0.70, 0.62, 0.52), 0.07, Color(0.02, 0.018, 0.015), 0.045)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	Halls.materials()
	H = Halls.new(self)
	lights.setup(12, 1)
	lights.max_distance = 30.0
	var k := kit("Square")
	H.square(k)
	H.exit_well(k)
	var mouths := Node3D.new()
	mouths.name = "Mouths"
	add_child(mouths)
	# QA fixture: the first door in the south mouth is a "105" door (always reachable)
	_doors(k, mouths, "z", C.x, C.z + Halls.SQ, CS, 0.0, Vector2i(0, 0), 0, false)
	_doors(k, mouths, "z", C.x, 0.0, C.z - Halls.SQ, 0.0, Vector2i(0, 0), 0, false)
	_doors(k, mouths, "x", C.z, C.x + Halls.SQ, CS, 0.0, Vector2i(0, 0), 0, false)
	_doors(k, mouths, "x", C.z, 0.0, C.x - Halls.SQ, 0.0, Vector2i(0, 0), 0, false)
	k.commit()
	_square_dressing()
	_exit_door()
	world = ChunkWorld.new()
	world.name = "Hallways"
	add_child(world)
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	world.can_shift = _can_shift
	world.shift_enabled = true
	world.shift_after = 12.0
	world.chunk_unloaded.connect(func(key: Vector2i) -> void: lights.remove_group("c%d_%d" % [key.x, key.y]))
	world.build_around(C, 2)
	_sounds()
	add_arrival("start", Vector3(C.x, 0.02, C.z + 3.6), 0.0)
	add_arrival("from_L022", Vector3(C.x - 3.2, 0.02, C.z - 3.0), -90.0)
	add_landmark("The front desk in the square", C)
	add_landmark("Neon Exit door (hallway right of the desk)", Vector3(Halls.EXIT_X, 0, C.z - 1.3))
	add_note("ledger", "LEDGER ON THE FRONT DESK",
		"Survey notes, many hands. Doors marked 105 open on Level 0; 356 on Level 356; 34 on Level 669; 8 to 20 on those levels; blank doors on Level 1.5; sandstone doors sometimes on Level 46; a smiley face means a party. Every other door: expect a wall, or to come out somewhere else in these halls.",
		Vector3(C.x + 0.6, 1.17, C.z - 0.65))
	add_note("warning", "CARD PINNED UNDER THE BELL",
		"Nothing comes into the square. The halls are another matter: if you hear clicking, move. If you meet anyone out there, do not trust them. Avoid them.",
		Vector3(C.x - 0.8, 1.17, C.z - 0.6))
	add_shot("square", Vector3(C.x - 3.8, 1.65, C.z + 4.4), Vector3(C.x + 1.0, 1.0, C.z - 1.0))
	add_shot("hallway", Vector3(C.x, 1.62, C.z + 7.0), Vector3(C.x, 1.4, C.z + 40.0))
	add_shot("doors", Vector3(C.x + 0.9, 1.62, 30.0), Vector3(C.x - 0.6, 1.3, 36.0))
	add_shot("exit_door", Vector3(Halls.EXIT_X - 2.4, 1.6, C.z + 1.0), Vector3(Halls.EXIT_X + 0.2, 1.7, C.z - 1.3), {"prepare": _prep_build.bind(Vector3(Halls.EXIT_X, 0, C.z))})
	add_shot("dark_halls", Vector3(Halls.EXIT_X, Halls.DY + 1.6, Halls.JZ1 - 1.0), Vector3(Halls.EXIT_X, Halls.DY + 1.3, -24.0), {"prepare": _prep_dark, "flashlight": true})


# ------------------------------------------------------------------ doors

func _h(key: Vector2i, version: int, idx: int, salt: String) -> float:
	return float(absi(hash([level_seed, key.x, key.y, version, idx, salt])) % 100003) / 100003.0


## What a door is: {label, kind ("exit"|"warp"|"wall"|"random"), edge, mat, to}
func _door_spec(key: Vector2i, version: int, idx: int, dark: bool) -> Dictionary:
	if dark:
		return {"label": "", "kind": "exit", "edge": "L021>EXT#10", "mat": "l21_dark_door"}
	var r := _h(key, version, idx, "kind")
	var num := 21 + int(_h(key, version, idx, "num") * 4900.0)
	if num == 105 or num == 356:
		num += 7
	var outcome := _h(key, version, idx, "out")
	var plain := {"label": str(num), "kind": "warp" if outcome < 0.6 else ("wall" if outcome < 0.95 else "random"), "mat": "l21_door"}
	if plain["kind"] == "random":
		plain["edge"] = "L021>EXT#8"
		plain["kind"] = "exit"
	if r < 0.022:
		return {"label": "105", "kind": "exit", "edge": "L021>L000#1", "mat": "l21_door"}
	if r < 0.04:
		return {"label": "356", "kind": "exit", "edge": "L021>L356#2", "mat": "l21_door"}
	if r < 0.058:
		return {"label": "34", "kind": "exit", "edge": "L021>L669#4", "mat": "l21_door"}
	if r < 0.074:
		return {"label": ":)", "kind": "exit", "edge": "L021>EXT#5", "mat": "l21_door_pale"}
	if r < 0.11:
		var n := 8 + int(_h(key, version, idx, "lvl") * 13.0)
		return {"label": str(n), "kind": "exit", "edge": "L021>EXT#6", "mat": "l21_door", "to": "L%03d" % n}
	if r < 0.145:
		return {"label": "", "kind": "exit", "edge": "L021>L001_5#7", "mat": "l21_door_pale"}
	if r < 0.17:
		var s := plain.duplicate()
		s["mat"] = "l21_sandstone"
		s["label"] = ""
		if _h(key, version, idx, "sand") < 0.6:
			s["kind"] = "exit"
			s["edge"] = "L021>L046#3"
		return s
	return plain


func _doors(k: GeoKit, parent: Node3D, axis: String, line: float, u0: float, u1: float, y0: float, key: Vector2i, version: int, dark: bool, blocked_at: float = INF) -> void:
	var idx := 0
	var placed := 0
	var u := floorf(u0 / 1.5) * 1.5 + 0.75
	while u < u1 - 0.6:
		if u > u0 + 0.6 and absf(u - blocked_at) > 0.8:
			var side := -1.0 if int(floorf(u / 1.5)) % 2 == 0 else 1.0
			var is_exit_door: bool = not dark and axis == "x" and side < 0.0 and absf(u - Halls.EXIT_X) < 1.0
			if not is_exit_door:
				var spec := _door_spec(key, version, idx, dark)
				if qa_fixture and key == Vector2i(0, 0) and axis == "z" and u0 > C.z and placed == 0:
					spec = {"label": "105", "kind": "exit", "edge": "L021>L000#1", "mat": "l21_door"}
				var d: Dictionary = H.door(k, parent, axis, line, u, side, y0, spec["mat"], spec["label"], dark)
				_wire_door(parent, spec, d)
				placed += 1
		u += 1.5
		idx += 1


func _wire_door(parent: Node3D, spec: Dictionary, d: Dictionary) -> void:
	var front: Vector3 = d["front"]
	var n: Vector3 = d["normal"]
	var face := front - n * 0.53
	var name: String = ("door " + str(spec["label"])) if spec["label"] != "" else ("the sandstone door" if spec["mat"] == "l21_sandstone" else "the unlabelled door")
	if spec["kind"] == "exit":
		var t := make_exit(spec["edge"], "interact", front + Vector3(0, 0.0, 0), Vector3(1.0, 2.2, 0.9), "Open " + name, parent)
		if t and spec.has("to"):
			var to: String = spec["to"]
			var id: String = spec["edge"]
			t.fired.connect(func(_e: String) -> void:
				var e := TransitionService.get_edge(id)
				if not e.is_empty():
					e["to"] = to)
		if t:
			t.fired.connect(func(_e: String) -> void: sound.play_at("creak", {"freq": 110.0}, face, -10.0, "[the door swings open]"))
	else:
		make_interactable(face + n * 0.04, Vector3(0.9, 2.0, 0.08) if absf(n.z) > 0.5 else Vector3(0.08, 2.0, 0.9), "Open " + name, _use_door.bind(spec["kind"], face, n), parent)


func _use_door(p: Player, kind: String, face: Vector3, n: Vector3) -> void:
	if kind == "wall":
		_walls += 1
		_brick_flash(face, n)
		sound.play_at("knock", {"hits": 1}, face, -8.0, "[the door opens onto solid brick]")
		return
	_warps += 1
	Overlay.glitch(0.7)
	sound.play_at("creak", {"freq": 95.0}, face, -8.0, "[you step through ... into another stretch of the same halls]")
	var to := _warp_target()
	world.build_around(to[0], 1)
	p.global_position = to[0]
	p.rotation.y = to[1]
	p.velocity = Vector3.ZERO


## A random door front in a random hallway, 3-30 segments out.
func _warp_target() -> Array:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var dir: Vector2i = dirs[rng.randi() % 4]
	var dist := rng.randi_range(3, 30)
	var key := dir * dist
	var u := (float(key.x) if dir.x != 0 else float(key.y)) * CS + 0.75 + 1.5 * float(rng.randi_range(1, 14))
	var axis := "x" if dir.x != 0 else "z"
	var line := C.z if axis == "x" else C.x
	var pos := Halls.W(axis, u, 0.05, 0.0, line)
	var yaw := atan2(-float(dir.x), -float(dir.y)) if rng.randf() < 0.5 else atan2(float(dir.x), float(dir.y))
	return [pos, yaw]


func _brick_flash(face: Vector3, n: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 2.04, 0.02) if absf(n.z) > 0.5 else Vector3(0.02, 2.04, 0.9)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("l21_brick")
	mi.position = face + n * 0.03 + Vector3(0, -0.07, 0)
	add_child(mi)
	get_tree().create_timer(5.0).timeout.connect(mi.queue_free)


# ------------------------------------------------------------------ streaming

func _chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var key := Vector2i(cx, cz)
	var meta := {"main": false}
	var k := GeoKit.new(node, "Seg")
	var any := false
	if key != Vector2i.ZERO and (cz == 0 or cx == 0):
		var axis := "x" if cz == 0 else "z"
		var u0 := float(cx if cz == 0 else cz) * CS
		var line := C.z if axis == "x" else C.x
		var blocked := INF
		if version > 0 and _h(key, version, 0, "block") < 0.14:
			blocked = u0 + CS * 0.5
		H.segment(k, axis, line, u0, u0 + CS, 0.0, false, blocked, [[Halls.EXIT_X, -1.0]] if key == Vector2i(2, 0) else [])
		_doors(k, node, axis, line, u0, u0 + CS, 0.0, key, version, false, blocked)
		for j in 4:
			var u := u0 + 3.0 + 6.0 * float(j)
			var p := Halls.W(axis, u, Halls.HH - 0.02, 0.0, line)
			k.panel(p, 0.5 if axis == "z" else 1.1, 1.1 if axis == "z" else 0.5, "l21_light_panel")
			lights.add_anchor(p - Vector3(0, 0.3, 0), WARM, 0.9, 6.5, 0.04 if _h(key, version, j, "flk") < 0.15 else 0.0, "c%d_%d" % [cx, cz])
		_pickup(node, key, axis, line, u0, 0.0, 0.4)
		meta["main"] = true
		any = true
	if exit_open and cz == -1:
		var a0 := float(cx) * CS
		var a1 := a0 + CS
		if a0 < Halls.JX0:
			_dark(k, node, key, "x", Halls.DARK_Z, a0, minf(a1, Halls.JX0))
			any = true
		if a1 > Halls.JX1:
			_dark(k, node, key + Vector2i(0, 50), "x", Halls.DARK_Z, maxf(a0, Halls.JX1), a1)
			any = true
	if exit_open and cx == 2 and cz <= -1:
		_dark(k, node, key + Vector2i(0, 90), "z", Halls.EXIT_X, float(cz) * CS, minf(float(cz) * CS + CS, Halls.JZ0))
		any = true
	if any:
		k.commit()
	return meta


func _dark(k: GeoKit, node: Node3D, key: Vector2i, axis: String, line: float, u0: float, u1: float) -> void:
	if u1 - u0 < 0.5:
		return
	H.segment(k, axis, line, u0, u1, Halls.DY, true)
	_doors(k, node, axis, line, u0, u1, Halls.DY, key, 0, true)
	_pickup(node, key + Vector2i(31, 17), axis, line, u0, Halls.DY, 0.9)


func _can_shift(key: Vector2i, meta: Dictionary) -> bool:
	if not meta.get("main", false) or key == Vector2i(2, 0):
		return false
	return absi(key.x) + absi(key.y) >= 2 and not (key.y == -1 and exit_open)


# ------------------------------------------------------------------ items

func _pickup(node: Node3D, key: Vector2i, axis: String, line: float, u0: float, y0: float, chance: float) -> void:
	if _h(key, 0, 0, "item") > chance:
		return
	var id := "%d_%d_%d" % [key.x, key.y, int(y0)]
	if _taken.has(id):
		return
	var kinds := ["Almond Water", "Level Key", "Firesalt"]
	var kind: String = kinds[int(_h(key, 0, 1, "ik") * 3.0) % 3]
	var u := u0 + 2.0 + _h(key, 0, 2, "iu") * (CS - 4.0)
	var side := -1.0 if _h(key, 0, 3, "is") < 0.5 else 1.0
	var p := Halls.W(axis, u, y0, side * (Halls.HW * 0.5 - 0.25), line)
	var holder := Node3D.new()
	holder.name = "Item_" + kind.replace(" ", "")
	holder.position = p
	node.add_child(holder)
	var ik := GeoKit.new(holder, "ItemMesh")
	match kind:
		"Almond Water":
			ik.cylinder(Vector3(0, 0.12, 0), 0.04, 0.24, "paper", 10, false)
			ik.cylinder(Vector3(0, 0.255, 0), 0.016, 0.03, "l21_trim", 8, false)
		"Level Key":
			ik.box(Vector3(0, 0.006, 0), Vector3(0.09, 0.012, 0.03), "l21_brass", GeoKit.ALL, false)
			ik.cylinder(Vector3(-0.06, 0.006, 0), 0.025, 0.012, "l21_brass", 10, false)
		_:
			ik.cylinder(Vector3(0, 0.05, 0), 0.05, 0.1, "glass", 10, false)
			ik.cylinder(Vector3(0, 0.035, 0), 0.042, 0.06, "l21_neon", 10, false)
	ik.commit()
	make_interactable(p + Vector3(0, 0.15, 0), Vector3(0.4, 0.35, 0.4), "Pick up the " + kind, func(_p: Player) -> void:
		items[kind] += 1
		_taken[id] = true
		Overlay.subtitle("[you take the %s (%d carried)]" % [kind, items[kind]], 2.5)
		holder.queue_free(), node)


# ------------------------------------------------------------------ the square and the Exit door

func _square_dressing() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "chairs"])
	var parent := Node3D.new()
	parent.name = "SquareDressing"
	add_child(parent)
	var desk_z := C.z - 0.6
	Props.place(self, parent, "kenney/furniture-kit/chairdesk", Vector3(C.x + 0.3, 0, desk_z - 1.25), 180.0 + r.randf_range(-20, 20), 1.05)
	Props.place(self, parent, "ph/office_notepads", Vector3(C.x - 0.4, 1.16, desk_z - 0.08), 0.0)
	Props.place(self, parent, "ph/stationery_supplies", Vector3(C.x + 1.1, 1.16, desk_z - 0.1), 10.0)
	Props.place(self, parent, "ph/vintage_telephone_wall_clock", Vector3(C.x - 3.0, 1.5, C.z - Halls.SQ + 0.02), 0.0)
	Props.place(self, parent, "ph/Chandelier_01", Vector3(C.x, 2.6, C.z), 0.0)
	# waiting chairs along the walls (seeded arrangement), solid
	var spots := [[Vector3(C.x - 4.6, 0, C.z - 4.6), 45.0], [Vector3(C.x + 4.6, 0, C.z - 4.6), -45.0], [Vector3(C.x - 4.6, 0, C.z + 4.6), 135.0],
		[Vector3(C.x + 4.6, 0, C.z + 4.6), -135.0], [Vector3(C.x - 4.7, 0, C.z - 2.6), 90.0], [Vector3(C.x + 4.7, 0, C.z + 2.6), -90.0]]
	for i in spots.size():
		if r.randf() < 0.75:
			var id := "ph/GreenChair_01" if i % 2 == 0 else "ph/ArmChair_01"
			Props.place(self, parent, id, (spots[i][0] as Vector3) + Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)), float(spots[i][1]) + r.randf_range(-15, 15), 0.0, true)
	Props.place(self, parent, "ph/coffee_table_round_01", Vector3(C.x - 3.6, 0, C.z + 3.8), 0.0, 0.0, true)
	Props.place(self, parent, "ph/WetFloorSign_01", Vector3(C.x + 2.3, 0, C.z + 4.2), r.randf_range(0, 360))
	lights.add_anchor(Vector3(C.x, 2.4, C.z), Color(1.0, 0.84, 0.62), 1.6, 9.0, 0.0, "square")
	lights.add_anchor(Vector3(C.x, 1.6, C.z - 0.6), Color(1.0, 0.8, 0.55), 0.6, 3.0, 0.0, "square")


## The neon red "Exit" door in the east hallway (to the right of the desk as you face it).
func _exit_door() -> void:
	var x := Halls.EXIT_X
	var z := C.z - Halls.HW * 0.5
	var k := kit("ExitDoor")
	# frame, neon sign box and tube
	for e in [-0.56, 0.56]:
		k.box(Vector3(x + e, 1.06, z + 0.03), Vector3(0.1, 2.12, 0.06), "l21_dark", GeoKit.ALL, false)
	k.box(Vector3(x, 2.17, z + 0.03), Vector3(1.22, 0.1, 0.06), "l21_dark", GeoKit.ALL, false)
	k.box(Vector3(x, 2.42, z + 0.05), Vector3(1.0, 0.32, 0.1), "l21_dark", GeoKit.ALL, false)
	k.box(Vector3(x, 2.42, z + 0.105), Vector3(0.9, 0.24, 0.01), "l21_neon", GeoKit.ALL, false)
	k.commit()
	var sign := Label3D.new()
	sign.text = "EXIT"
	sign.font_size = 96
	sign.pixel_size = 0.0024
	sign.modulate = Color(1.0, 0.85, 0.8)
	sign.outline_modulate = Color(1.0, 0.1, 0.05)
	sign.outline_size = 18
	sign.position = Vector3(x, 2.42, z + 0.115)
	add_child(sign)
	lights.add_anchor(Vector3(x, 2.3, z + 0.6), Color(1.0, 0.12, 0.06), 1.3, 5.0, 0.03, "exit")
	_exit_leaf = Node3D.new()
	_exit_leaf.name = "ExitLeaf"
	_exit_leaf.position = Vector3(x + 0.48, 0, z - 0.01)
	add_child(_exit_leaf)
	var lk := GeoKit.new(_exit_leaf, "Leaf")
	lk.box(Vector3(-0.48, 1.03, 0), Vector3(0.94, 2.06, 0.05), "l21_dark_door")
	lk.cylinder(Vector3(-0.84, 1.0, 0.06), 0.028, 0.06, "l21_brass", 8, false)
	lk.commit()
	_exit_body = lk.body
	add_interactable(Vector3(x, 1.05, z + 0.08), Vector3(1.0, 2.0, 0.1), "Open the door under the neon Exit sign", _open_exit)


func _open_exit(_p: Player) -> void:
	if exit_open:
		return
	exit_open = true
	_exit_leaf.rotation.y = deg_to_rad(-100.0)
	_exit_body.collision_layer = 0
	for c in _exit_body.get_children():
		(c as CollisionShape3D).disabled = true
	sound.play_at("creak", {"freq": 80.0}, _exit_leaf.global_position + Vector3(0, 1, 0), -6.0, "[the Exit door opens on a stair going down into the dark]")
	for key in world.chunks.keys():
		if (key as Vector2i).y <= -1:
			world.rebuild(key, false)


func _prep_build(at: Vector3) -> void:
	world.build_around(at, 1)
	await get_tree().process_frame


func _prep_dark() -> void:
	if not exit_open:
		_open_exit(player)
	world.build_around(Vector3(Halls.EXIT_X, 0, -12.0), 1)
	await get_tree().process_frame


# ------------------------------------------------------------------ sound and presence

func _sounds() -> void:
	_hum = sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.08, "seconds": 3.0}, -38.0)
	sound.bed("room_tone", {"cutoff": 320.0, "rumble": 0.15, "seconds": 6.0}, -32.0)
	_march = sound.bed("knock", {"hits": 8}, -80.0)


func on_player_ready() -> void:
	world.target = player
	if not qa_fixture:
		Overlay.subtitle("[a small square, four hallways, and doors as far as you can see]", 4.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var in_square := absf(p.x - C.x) < Halls.SQ and absf(p.z - C.z) < Halls.SQ and p.y > -1.0
	var in_dark := p.y < Halls.DY + 2.0 and p.z < Halls.JZ1 + 0.5
	# Clickers: common in the hallways, never in the square
	if not in_square and not in_dark:
		_click_t -= delta
		if _click_t <= 0.0:
			_click_t = rng.randf_range(9.0, 22.0)
			var dir := -player.global_transform.basis.z if rng.randf() < 0.5 else player.global_transform.basis.z
			var at := p + dir * rng.randf_range(8.0, 16.0) + Vector3(0, 1.2, 0)
			if not qa_fixture:
				sound.play_at("ui", {"kind": "click"}, at, -6.0, "[clicking, somewhere down the hall]")
				get_tree().create_timer(0.35).timeout.connect(func() -> void: sound.play_at("ui", {"kind": "click"}, at, -8.0))
	# the Exit halls: organised entities heard in droves; the deeper, the closer
	if in_dark:
		var depth := maxf(maxf(Halls.JZ0 - p.z, absf(p.x - Halls.EXIT_X) - 3.0), 0.0)
		_march.volume_db = lerpf(-30.0, -6.0, clampf(depth / 50.0, 0.0, 1.0))
		_dark_t += delta
		if depth > 55.0 and not qa_fixture:
			_march_t -= delta
			if _march_t <= 0.0:
				_march_t = 4.0
				Overlay.glitch(0.4)
				Overlay.subtitle("[the clicking arrives all at once, in step. Get back to the stair.]", 3.0)
				player.hurt(15.0, "organised entities in the dark Exit halls of Level 21")
	else:
		_march.volume_db = move_toward(_march.volume_db, -80.0, delta * 30.0)
	_hum.volume_db = -44.0 if in_square else -38.0


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	var segs := 0
	for key in world.chunks.keys():
		if world.meta_of(key).get("main", false):
			segs += 1
	out.append({"what": "streamed hallway segments around the square", "ok": segs >= 8, "detail": segs})
	out.append({"what": "QA fixture door 105 near the square", "ok": exits.any(func(t): return is_instance_valid(t) and t.edge_id == "L021>L000#1")})
	var d := _door_spec(Vector2i(3, 0), 0, 5, false)
	var d2 := _door_spec(Vector2i(3, 0), 0, 5, false)
	out.append({"what": "door labels deterministic per seed", "ok": d == d2})
	var kinds := {}
	for i in 400:
		kinds[_door_spec(Vector2i(5, 0), 0, i, false)["kind"]] = true
	out.append({"what": "most doors warp or are walls; some exit", "ok": kinds.has("warp") and kinds.has("wall") and kinds.has("exit")})
	out.append({"what": "Exit door closed until opened", "ok": not exit_open})
	_open_exit(player)
	world.build_around(Vector3(Halls.EXIT_X, 0, -12.0), 1)
	var dark_exits := exits.filter(func(t): return is_instance_valid(t) and t.edge_id == "L021>EXT#10").size()
	out.append({"what": "opening the Exit door streams the dark halls with repeating doors", "ok": exit_open and dark_exits > 0, "detail": dark_exits})
	var before := player.global_position
	_use_door(player, "warp", before, Vector3.FORWARD)
	out.append({"what": "an ordinary door can put you elsewhere in Level 21", "ok": player.global_position.distance_to(before) > 60.0 and world.chunks.has(world.key_at(player.global_position)), "detail": [before, player.global_position]})
	player.global_position = before
	world.build_around(before, 1)
	return out
