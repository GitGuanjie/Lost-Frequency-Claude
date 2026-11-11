extends Node
## Cross-process persistence test for the continuity laboratory.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . res://tests/ContinuityPersistenceTest.tscn -- --phase=write
##   godot --headless --path . res://tests/ContinuityPersistenceTest.tscn -- --phase=read
##
## Requirement 7 of the brief asks for "test saving and reloading". The
## in-memory scope of SaveService would make such a test pass without the disk
## ever being touched: two worlds with the same world_id share one dictionary.
## So this test is deliberately split in two halves that run in TWO SEPARATE
## PROCESSES:
##
##   --phase=write  writes the exploration state to disk, proves the file on
##                  disk really contains it, and writes it a second time so
##                  that the rotating backup exists too.
##   --phase=read   starts with an empty process, and proves the state came
##                  back from the FILE and not from any in-memory scope.
##
## The two phases together are the "save, restart, reload" round trip. A
## single-process test cannot distinguish "the disk works" from "the dictionary
## was never cleared".

const SEED := 1337
const WORLD_ID := "QA_PERSISTENCE"
const OTHER_WORLD_ID := "QA_PERSISTENCE_OTHER"
const DISK_PATH := "user://continuity_lab/test_persistence.json"
const REPORT_PATH := "res://reports/qa/continuity_persistence.json"

const KEY_VISITED := Vector3i(0, 0, 0)
const KEY_DISCOVERED := Vector3i(1, 0, 0)
const KEY_VERSIONED := Vector3i(2, 0, 0)

var findings: Array = []
var failures := 0
var phase := "all"
var _deadline_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("PERSISTENCE: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("PERSISTENCE FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 120 * 1000
	# The scope of the story save must never be touched by a developer test.
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	if phase == "write":
		await _phase_write()
	elif phase == "read":
		await _phase_read()
	else:
		await _phase_write()
		await _phase_read()
	_report()


# ------------------------------------------------------------------ helpers

func _make_world(id: String, disk: String) -> ChunkWorld3D:
	var w := ChunkWorld3D.new()
	w.name = "PersistWorld"
	w.seed_value = SEED
	w.world_id = id
	w.disk_persistence_enabled = true
	w.disk_path = disk
	add_child(w)
	return w


func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return decoded if decoded is Dictionary else {}


func _phase_write() -> void:
	# A previous run must not be able to make this phase pass.
	var abs_path := _absolute(DISK_PATH)
	if FileAccess.file_exists(DISK_PATH):
		DirAccess.remove_absolute(abs_path)
	if FileAccess.file_exists(DISK_PATH + ".bak"):
		DirAccess.remove_absolute(abs_path + ".bak")

	var world := _make_world(WORLD_ID, DISK_PATH)
	world.set_change(KEY_VISITED, "visited", true)
	world.set_change(KEY_DISCOVERED, "discovered", true)
	world.set_change(KEY_DISCOVERED, "artifact", "a faded survey tape")
	# bump_version writes the layout version AND flushes to disk at once.
	world.bump_version(KEY_VERSIONED)

	var saved := world.save_to_disk()
	_check(saved, "the world reports a successful save", {"path": DISK_PATH})
	_check(FileAccess.file_exists(DISK_PATH), "the save file exists on disk",
		{"path": _absolute(DISK_PATH)})

	var payload := _read_json(DISK_PATH)
	_check(payload.size() > 0, "the save file is readable JSON", {"path": _absolute(DISK_PATH)})
	_check(payload.get("world_id", "") == WORLD_ID, "the save file names its world",
		{"world_id": payload.get("world_id", "")})
	_check(int(payload.get("seed", -1)) == SEED, "the save file records the seed",
		{"seed": payload.get("seed", -1)})
	var changes: Dictionary = payload.get("changes", {})
	var versions: Dictionary = payload.get("versions", {})
	_check(changes.has(ContinuityTopology.encode(KEY_VISITED)),
		"the visited chunk is in the saved changes", {"keys": changes.keys()})
	_check(bool(changes.get(ContinuityTopology.encode(KEY_VISITED), {}).get("visited", false)),
		"the visited flag is on disk, not only in memory")
	_check(changes.get(ContinuityTopology.encode(KEY_DISCOVERED), {}).get("artifact", "") == "a faded survey tape",
		"the discovery text is on disk")
	_check(int(versions.get(ContinuityTopology.encode(KEY_VERSIONED), 0)) == 1,
		"the layout version is on disk", {"versions": versions})

	# A second save must rotate the first one into the backup, and the backup
	# must still be a readable save. The second save ADDS a change, so the
	# current file and the backup differ in exactly one known way.
	world.set_change(KEY_VERSIONED, "reshaped", true)
	world.save_to_disk()
	_check(FileAccess.file_exists(DISK_PATH + ".bak"), "the previous save was rotated into the backup",
		{"path": _absolute(DISK_PATH + ".bak")})
	var backup := _read_json(DISK_PATH + ".bak")
	_check(bool(backup.get("changes", {}).get(ContinuityTopology.encode(KEY_VISITED), {}).get("visited", false)),
		"the backup still holds the state of the first save")
	_check(not backup.get("changes", {}).get(ContinuityTopology.encode(KEY_VERSIONED), {}).has("reshaped"),
		"the backup does not contain the change that was made after it")
	_check(bool(_read_json(DISK_PATH).get("changes", {})
			.get(ContinuityTopology.encode(KEY_VERSIONED), {}).get("reshaped", false)),
		"the current save holds the change that was made after the backup")

	world.queue_free()
	await get_tree().process_frame


func _phase_read() -> void:
	_check(FileAccess.file_exists(DISK_PATH), "a save file exists for the reload phase",
		{"path": _absolute(DISK_PATH)})
	if not FileAccess.file_exists(DISK_PATH):
		return

	# A fresh process, a fresh SaveService scope, and a world that knows
	# nothing except where the file is.
	var world := _make_world(WORLD_ID, DISK_PATH)
	_check(bool(world.change_of(KEY_VISITED, "visited", false)),
		"the visited chunk came back from the file after a restart",
		{"chunk": str(KEY_VISITED)})
	_check(bool(world.change_of(KEY_DISCOVERED, "discovered", false)),
		"the discovered chunk came back from the file after a restart",
		{"chunk": str(KEY_DISCOVERED)})
	_check(world.change_of(KEY_DISCOVERED, "artifact", "") == "a faded survey tape",
		"the discovery text came back from the file after a restart")
	_check(world.version_of(KEY_VERSIONED) == 1,
		"the layout version came back from the file after a restart",
		{"version": world.version_of(KEY_VERSIONED)})
	_check(bool(world.change_of(KEY_VERSIONED, "reshaped", false)),
		"the change that was made after the backup came back as well")

	# A world with a different identity must not read another world's save,
	# even when it points at the same file.
	var other := _make_world(OTHER_WORLD_ID, DISK_PATH)
	_check(not bool(other.change_of(KEY_VISITED, "visited", false)),
		"a different world id does not inherit the state of another world",
		{"world_id": OTHER_WORLD_ID})
	_check(other.version_of(KEY_VERSIONED) == 0,
		"a different world id does not inherit the layout versions of another world")
	other.queue_free()

	# The rotated backup is still loadable.
	var backup := _read_json(DISK_PATH + ".bak")
	_check(backup.get("world_id", "") == WORLD_ID, "the backup is a complete save of the same world",
		{"world_id": backup.get("world_id", "")})

	world.queue_free()
	await get_tree().process_frame


func _report() -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	# The two halves of the round trip run in two processes and must not
	# write to the same report: the second half would overwrite the
	# evidence of the first, and a report can only ever show the last thing
	# that happened. Each phase gets its own file.
	var name := "continuity_persistence.json"
	if phase == "write" or phase == "read":
		name = "continuity_persistence_%s.json" % phase
	var f := FileAccess.open(dir + "/" + name, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"phase": phase,
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"disk_path": _absolute(DISK_PATH),
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("PERSISTENCE phase=%s %d checks, %d failures" % [phase, findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
