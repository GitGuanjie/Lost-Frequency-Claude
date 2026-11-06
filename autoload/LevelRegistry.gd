extends Node
## Canonical 100-entry roster (data/canon/levels.json, generated from the dated
## source audit) merged with per-level implementation manifests
## (levels/<stable_id>/level.json). The registry never invents a status: a level
## without a manifest is LOCKED / IN DEVELOPMENT.

const ROSTER_PATH := "res://data/canon/levels.json"
const STATUS_ORDER := ["NOT_STARTED", "IN_DEVELOPMENT", "PLAYABLE", "ACCEPTED"]

var entries: Array = []          # ordered by roster slot
var by_sid: Dictionary = {}      # stable_id -> entry
var by_level: Dictionary = {}    # "37" -> entry
var roster_meta: Dictionary = {}
var load_error := ""


func _ready() -> void:
	reload()


static func stable_id(level_id: String) -> String:
	var parts := level_id.split(".")
	var sid := "L%03d" % int(parts[0])
	if parts.size() > 1:
		sid += "_" + parts[1]
	return sid


func reload() -> void:
	entries.clear()
	by_sid.clear()
	by_level.clear()
	load_error = ""
	if not FileAccess.file_exists(ROSTER_PATH):
		load_error = "Roster missing: " + ROSTER_PATH
		push_error(load_error)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROSTER_PATH))
	if not (data is Dictionary) or not data.has("levels"):
		load_error = "Roster unreadable: " + ROSTER_PATH
		push_error(load_error)
		return
	roster_meta = data.duplicate()
	roster_meta.erase("levels")
	for raw in data["levels"]:
		var e: Dictionary = (raw as Dictionary).duplicate(true)
		var sid: String = e.get("stable_id", stable_id(str(e["level_id"])))
		e["stable_id"] = sid
		var impl := _read_manifest(sid)
		e["impl"] = impl
		e["status"] = impl.get("status", "NOT_STARTED")
		e["scene"] = impl.get("scene", "")
		entries.append(e)
		by_sid[sid] = e
		by_level[str(e["level_id"])] = e
	entries.sort_custom(func(a, b): return int(a["slot"]) < int(b["slot"]))


func _read_manifest(sid: String) -> Dictionary:
	var p := "res://levels/%s/level.json" % sid
	if not FileAccess.file_exists(p):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if d is Dictionary:
		var scene: String = d.get("scene", "")
		if scene != "" and not ResourceLoader.exists(scene):
			d["status"] = "IN_DEVELOPMENT"
			d["manifest_error"] = "scene missing: " + scene
		return d
	return {"status": "IN_DEVELOPMENT", "manifest_error": "unreadable level.json"}


func count() -> int:
	return entries.size()


func get_entry(sid: String) -> Dictionary:
	return by_sid.get(sid, {})


func has_level(sid: String) -> bool:
	return by_sid.has(sid)


## Spawnable in developer mode: scene exists and status at least IN_DEVELOPMENT.
func is_spawnable(sid: String) -> bool:
	var e := get_entry(sid)
	return not e.is_empty() and e["scene"] != "" and ResourceLoader.exists(e["scene"]) \
		and e["status"] in ["IN_DEVELOPMENT", "PLAYABLE", "ACCEPTED"]


## Story-eligible: passed engine gates.
func is_playable(sid: String) -> bool:
	var e := get_entry(sid)
	return not e.is_empty() and e["status"] in ["PLAYABLE", "ACCEPTED"] and is_spawnable(sid)


func scene_path(sid: String) -> String:
	return get_entry(sid).get("scene", "")


func display_name(sid: String) -> String:
	var e := get_entry(sid)
	if e.is_empty():
		return sid
	var t: String = e.get("title", "")
	if t == "":
		return "Level %s" % e["level_id"]
	return "Level %s — %s" % [e["level_id"], t]


func status_label(sid: String) -> String:
	match get_entry(sid).get("status", "NOT_STARTED"):
		"ACCEPTED":
			return "ACCEPTED"
		"PLAYABLE":
			return "PLAYABLE · engine-verified"
		"IN_DEVELOPMENT":
			return "IN DEVELOPMENT"
		_:
			return "LOCKED / IN DEVELOPMENT"


func spawnable_ids() -> Array:
	var out := []
	for e in entries:
		if is_spawnable(e["stable_id"]):
			out.append(e["stable_id"])
	return out


## Developer-only catalog stepping (F4 / Shift+F4). Skips unbuilt entries.
func next_in_catalog(sid: String, step: int) -> String:
	var ids := spawnable_ids()
	if ids.is_empty():
		return ""
	var i := ids.find(sid)
	if i == -1:
		return ids[0] if step > 0 else ids[ids.size() - 1]
	return ids[posmod(i + step, ids.size())]


func counters() -> Dictionary:
	var c := {"requested": entries.size(), "source_audited": 0, "spawnable": 0,
		"playable": 0, "accepted": 0, "blocked_source": 0}
	for e in entries:
		if e.get("source_status", "") in ["RESOLVED", "RESOLVED_TITLE_DIFFERS"]:
			c["source_audited"] += 1
		if e.get("source_status", "") == "BLOCKED_SOURCE":
			c["blocked_source"] += 1
		if is_spawnable(e["stable_id"]):
			c["spawnable"] += 1
		if is_playable(e["stable_id"]):
			c["playable"] += 1
		if e["status"] == "ACCEPTED":
			c["accepted"] += 1
	return c
