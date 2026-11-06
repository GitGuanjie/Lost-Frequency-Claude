extends Node
## Versioned, atomic story saves. Developer and QA sessions never write the
## story file. Corrupted files fall back to the backup; unknown data is kept
## aside, never silently overwritten. Legacy V52/V60/V62 saves can be imported.

signal saved(reason: String)

const SCHEMA := 100
const LEGACY_FILE := "lost_frequency_unified_v52.json"

var story: Dictionary = {}
var dev: Dictionary = {}
var last_error := ""
var last_load_source := ""   # "primary" | "backup" | "temp" | "fresh"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	story = fresh_story(1)
	dev = fresh_story(SessionState.dev_seed)


func save_dir() -> String:
	return "user://qa_saves/" if SessionState.qa_run else "user://saves/"


func story_path() -> String:
	return save_dir() + "story.json"


func fresh_story(seed_value: int) -> Dictionary:
	var now := Time.get_datetime_string_from_system(true)
	return {
		"schema": SCHEMA, "game": "LOST FREQUENCY", "created_utc": now, "updated_utc": now,
		"seed": seed_value, "current_level": "L000",
		"checkpoint": {"level": "L000", "arrival": "start", "pos": null, "yaw": 0.0, "pitch": 0.0},
		"journal": {"edges": [], "notes": [], "levels_visited": []},
		"flags": {}, "inventory": {}, "playtime_s": 0.0, "save_count": 0, "migrated_from": null,
	}


func has_story() -> bool:
	var p := story_path()
	return FileAccess.file_exists(p) or FileAccess.file_exists(p + ".bak") or FileAccess.file_exists(p + ".tmp")


func new_story(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = int(Time.get_unix_time_from_system()) % 1000000 + 1
	story = fresh_story(seed_value)
	var legacy := find_legacy_save()
	if not legacy.is_empty():
		migrate_legacy_into(story, legacy["data"], legacy["path"])


## Active scope dictionary: story data in story mode, sandbox data otherwise.
func scope() -> Dictionary:
	return story if SessionState.is_story() else dev


func _validate(d: Variant) -> bool:
	return d is Dictionary and int(d.get("schema", -1)) == SCHEMA and d.has("checkpoint") \
		and d.has("journal") and d.has("seed")


func _read_json(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var txt := FileAccess.get_file_as_string(p)
	if txt.is_empty():
		return null
	return JSON.parse_string(txt)


func load_story() -> bool:
	last_error = ""
	var p := story_path()
	for pair in [[p, "primary"], [p + ".tmp", "temp"], [p + ".bak", "backup"]]:
		var d: Variant = _read_json(pair[0])
		if d == null:
			if FileAccess.file_exists(pair[0]) and pair[1] == "primary":
				_quarantine(pair[0])
			continue
		if d is Dictionary and int(d.get("schema", -1)) < SCHEMA and d.has("missions"):
			# a legacy file placed where the new save belongs
			var s := fresh_story(int(d.get("seed", 1)))
			migrate_legacy_into(s, d, pair[0])
			story = s
			last_load_source = pair[1] + "+migrated"
			return true
		if _validate(d):
			story = _upgrade(d)
			last_load_source = pair[1]
			return true
		if pair[1] == "primary":
			_quarantine(pair[0])
	last_error = "No readable story save; started fresh."
	last_load_source = "fresh"
	return false


func _upgrade(d: Dictionary) -> Dictionary:
	var base := fresh_story(int(d.get("seed", 1)))
	for k in base.keys():
		if not d.has(k):
			d[k] = base[k]
	return d


func _quarantine(p: String) -> void:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "-")
	var target := p + ".corrupt-" + stamp
	DirAccess.rename_absolute(ProjectSettings.globalize_path(p), ProjectSettings.globalize_path(target))
	last_error = "Corrupted save moved to " + target.get_file()
	push_warning(last_error)


## Atomic write: tmp -> verify -> keep previous as .bak -> rename.
func save_story(reason: String = "manual") -> bool:
	if not SessionState.is_story():
		return false  # developer / QA sessions never touch the story file
	return _write_story_file(reason)


func _write_story_file(reason: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_dir()))
	story["updated_utc"] = Time.get_datetime_string_from_system(true)
	story["save_count"] = int(story.get("save_count", 0)) + 1
	var p := story_path()
	var text := JSON.stringify(story, "  ")
	var f := FileAccess.open(p + ".tmp", FileAccess.WRITE)
	if f == null:
		last_error = "Cannot write save: %s" % error_string(FileAccess.get_open_error())
		return false
	f.store_string(text)
	f.flush()
	f.close()
	var check: Variant = _read_json(p + ".tmp")
	if not _validate(check):
		last_error = "Save verification failed"
		return false
	var gp := ProjectSettings.globalize_path(p)
	if FileAccess.file_exists(p):
		DirAccess.copy_absolute(gp, gp + ".bak")
		DirAccess.remove_absolute(gp)
	var err := DirAccess.rename_absolute(gp + ".tmp", gp)
	if err != OK:
		last_error = "Save rename failed: " + error_string(err)
		return false
	saved.emit(reason)
	return true


# --------------------------------------------------------------- progress API

func set_checkpoint(level_sid: String, arrival: String, pos: Variant = null, yaw := 0.0, pitch := 0.0) -> void:
	var s := scope()
	s["current_level"] = level_sid
	s["checkpoint"] = {"level": level_sid, "arrival": arrival,
		"pos": ([pos.x, pos.y, pos.z] if pos is Vector3 else null), "yaw": yaw, "pitch": pitch}


func mark_visited(level_sid: String) -> void:
	var lv: Array = scope()["journal"]["levels_visited"]
	if not lv.has(level_sid):
		lv.append(level_sid)


func record_edge(edge: Dictionary) -> void:
	var edges: Array = scope()["journal"]["edges"]
	for e in edges:
		if e.get("edge", "") == edge.get("id", ""):
			e["count"] = int(e.get("count", 1)) + 1
			return
	edges.append({"edge": edge.get("id", ""), "from": edge.get("from", ""), "to": edge.get("to", ""),
		"t": int(Time.get_unix_time_from_system()), "count": 1})


func has_witnessed(edge_id: String) -> bool:
	for e in scope()["journal"]["edges"]:
		if e.get("edge", "") == edge_id:
			return true
	return false


func read_note(note_id: String) -> bool:
	var notes: Array = scope()["journal"]["notes"]
	if notes.has(note_id):
		return false
	notes.append(note_id)
	return true


func flag(level_sid: String, key: String, default: Variant = null) -> Variant:
	return scope()["flags"].get(level_sid, {}).get(key, default)


func set_flag(level_sid: String, key: String, value: Variant) -> void:
	var f: Dictionary = scope()["flags"]
	if not f.has(level_sid):
		f[level_sid] = {}
	f[level_sid][key] = value


func item_count(item: String) -> int:
	return int(scope()["inventory"].get(item, 0))


func add_item(item: String, n: int = 1) -> void:
	var inv: Dictionary = scope()["inventory"]
	inv[item] = maxi(0, int(inv.get(item, 0)) + n)
	if inv[item] == 0:
		inv.erase(item)


# ------------------------------------------------------------- legacy import

func find_legacy_save() -> Dictionary:
	var roots := [OS.get_data_dir().path_join("godot/app_userdata"),
		OS.get_data_dir().path_join("Godot/app_userdata")]
	for r in roots:
		var d := DirAccess.open(r)
		if d == null:
			continue
		for sub in d.get_directories():
			if sub.to_upper().begins_with("LOST FREQUENCY"):
				var p: String = r.path_join(sub).path_join(LEGACY_FILE)
				if FileAccess.file_exists(p):
					var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
					if data is Dictionary:
						return {"path": p, "data": data}
	return {}


## V52/V60/V62 used invented world identities and coordinates that do not map
## onto the canon rebuild. Only the seed and the visit history are imported,
## and they are labelled as legacy, unverified notes.
func migrate_legacy_into(target: Dictionary, legacy: Dictionary, src_path: String) -> void:
	var version := int(legacy.get("version", -1))
	if version not in [52, 60, 62]:
		target["migrated_from"] = {"path": src_path, "version": version, "imported": false,
			"reason": "unknown legacy version"}
		return
	target["seed"] = int(legacy.get("seed", target["seed"]))
	var visited := []
	var missions: Dictionary = legacy.get("missions", {})
	for k in missions.keys():
		var sid := LevelRegistry.stable_id(str(k))
		if LevelRegistry.has_level(sid):
			visited.append(sid)
	target["migrated_from"] = {"path": src_path, "version": version, "imported": true,
		"legacy_levels_listed": visited, "legacy_last_level": legacy.get("level", null),
		"note": "Legacy coordinates, missions and checkpoints are incompatible with the canon rebuild and were not imported."}
