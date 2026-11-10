extends SceneTree
## Godot 4.5.1: --headless --path . --script res://tests/ContinuityTopologyTest.gd
## Structural tests for the non-canon continuity lab. No real save is written.
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("WORLD-LAB FAIL: " + label)

func _run() -> void:
	var rooms := {}
	var themes := {}
	for seed_value in [1, 1337, 628478]:
		for y in range(ContinuityTopology.MIN_FLOOR, ContinuityTopology.MAX_FLOOR + 1):
			for x in range(-4, 5):
				for z in range(-4, 5):
					var k := Vector3i(x, y, z)
					var org := ContinuityTopology.origin(k)
					_check("coordinate roundtrip", ContinuityTopology.key_for(org + Vector3(2, 1, 2)) == k)
					_check("west/east face aligned", ContinuityTopology.face_offset(seed_value, k, "east") ==
						ContinuityTopology.face_offset(seed_value, k + Vector3i(1, 0, 0), "west"))
					_check("south/north face aligned", ContinuityTopology.face_offset(seed_value, k, "north") ==
						ContinuityTopology.face_offset(seed_value, k + Vector3i(0, 0, 1), "south"))
					for f in ["west", "east", "south", "north"]:
						var off := ContinuityTopology.face_offset(seed_value, k, f)
						_check("door safely within wall", off >= 1.0 and off <= 23.0)
						# The invariant that actually matters is not "the door
						# sits in the middle of the wall" but "the door does not
						# open onto a stairwell". The old proxy check let a door
						# land on the stair band, which dropped the player into
						# an open well.
						var axis := ContinuityTopology.face_axis(f)
						_check("door clear of every stair slot",
							not ContinuityTopology.opening_hits_stair(off, 4.0, axis))
					# The floor opening and the ramp that fills it are the same
					# rectangle, so the hole can never leave an uncovered strip.
					#
					# The comparison MUST be approximate. Godot stores Rect2 and
					# Vector2 as 32-bit floats in a standard build, so the slot
					# that comes back from `stair_slot()` is 2.40000009536743,
					# not 2.4, and `== 2.4` is FALSE. An exact comparison here
					# reported 2430 false failures against a correct geometry.
					for shaft in 2:
						var slot := ContinuityTopology.stair_slot(shaft)
						var ramp_centre := ContinuityTopology.shaft_x(shaft) + 1.5
						_check("stair slot has no uncovered strip",
							is_equal_approx(slot.size.x, ContinuityTopology.STAIR_WIDTH) and
							is_equal_approx(slot.size.y, ContinuityTopology.STAIR_RUN * ContinuityTopology.STAIR_STEPS))
						# The slot is not merely the right size: it is the ramp
						# footprint, centred on the ramp and starting where the
						# first riser starts.
						_check("stair slot is exactly the ramp footprint",
							is_equal_approx(slot.position.x, ramp_centre - ContinuityTopology.STAIR_WIDTH * 0.5) and
							is_equal_approx(slot.position.y, ContinuityTopology.STAIR_Z0))
					_check("coordinate serialization", ContinuityTopology.encode(k) == "%d:%d:%d" % [x, y, z])
					_check("theme reproducibility", ContinuityTopology.macro_theme(seed_value, k) ==
						ContinuityTopology.macro_theme(seed_value, k))
					_check("room reproducibility", ContinuityTopology.room_type(seed_value, k) ==
						ContinuityTopology.room_type(seed_value, k))
					_check("landmark reproducibility", ContinuityTopology.has_landmark(seed_value, k) ==
						ContinuityTopology.has_landmark(seed_value, k))
					_check("discovery reproducibility", ContinuityTopology.discovery_label(seed_value, k) ==
						ContinuityTopology.discovery_label(seed_value, k))
					rooms[ContinuityTopology.room_type(seed_value, k)] = true
					themes[ContinuityTopology.macro_theme(seed_value, k)] = true
					if y < ContinuityTopology.MAX_FLOOR:
						_check("stair shaft alignment", ContinuityTopology.outgoing_shaft(y) ==
							ContinuityTopology.incoming_shaft(y + 1))
	_check("negative macro coordinate", ContinuityTopology.macro_key(Vector3i(-1, 0, -1)) == Vector3i(-1, 0, -1))
	_check("eight room motifs represented", rooms.size() >= 8)
	_check("multiple macro themes represented", themes.size() >= 6)
	_check("spawn remains explicit entry room", ContinuityTopology.room_type(1337, Vector3i.ZERO) == "entry_hall")
	# --- World identity: zones are superdistrict-aligned, never an x cut ---
	var proxy := ContinuityTopology.proxy_super_key(1337)
	_check("proxy zone is not the spawn district", proxy != Vector3i.ZERO)
	_check("proxy zone covers a whole superdistrict",
		ContinuityTopology.zone_id(1337, Vector3i(proxy.x * 8, 0, proxy.z * 8)) == ContinuityTopology.ZONE_PROXY)
	_check("spawn district keeps the level 0 identity",
		ContinuityTopology.zone_id(1337, Vector3i.ZERO) == ContinuityTopology.ZONE_YELLOW)
	for sx in [3, 4]:
		for sz in [3, 4]:
			_check("central hub is never split across zones",
				ContinuityTopology.zone_id(1337, Vector3i(sx, 0, sz)) ==
				ContinuityTopology.zone_id(1337, Vector3i.ZERO))
	for seed_value in [1, 1337, 628478, 928374]:
		var p := ContinuityTopology.proxy_super_key(seed_value)
		_check("proxy zone stays off the spawn district", p != Vector3i.ZERO)
		for sx in [3, 4]:
			for sz in [3, 4]:
				_check("hub stays in one zone for every seed",
					ContinuityTopology.zone_id(seed_value, Vector3i(sx, 0, sz)) ==
					ContinuityTopology.zone_id(seed_value, Vector3i(0, 0, 0)))
		_check("zone is stable for the same coordinate",
			ContinuityTopology.zone_id(seed_value, Vector3i(5, 0, 5)) ==
			ContinuityTopology.zone_id(seed_value, Vector3i(5, 0, 5)))
	var streamer := ChunkWorld3D.new()
	streamer.world_id = "QA_WORLD_LAB_V2"
	streamer.seed_value = 1337
	streamer.disk_persistence_enabled = false
	streamer.builder = func(_x: int, _y: int, _z: int, _v: int, _node: Node3D) -> Dictionary:
		return {"ok": true}
	get_root().add_child(streamer)
	streamer.build_around(Vector3(1, 1, 1), 1, 1)
	_check("streamer loads 3x3x3", streamer.chunks.size() == 27)
	var center := Vector3i.ZERO
	streamer.set_change(center, "marked", true)
	streamer.set_change(center, "discovered", true)
	streamer.refresh_chunk(center)
	_check("refresh does not shift version", streamer.version_of(center) == 0)
	streamer.bump_version(center)
	_check("shift increments version", streamer.version_of(center) == 1)
	_check("marker survives shift", bool(streamer.change_of(center, "marked", false)))
	_check("discovery survives shift", bool(streamer.change_of(center, "discovered", false)))
	streamer._unload(center)
	streamer._build(center)
	_check("markers survive unload", bool(streamer.change_of(center, "marked", false)))
	streamer.queue_free()
	print("ContinuityTopologyTest v2: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
