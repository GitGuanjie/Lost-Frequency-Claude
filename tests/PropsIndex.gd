extends Node
## Writes assets/external/models/INDEX.md: every Poly Haven model id with measured size (m)
## so level authors can choose props without guessing. Run:
##   godot --headless --path . res://tests/PropsIndex.tscn
func _ready() -> void:
	var lock: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/external/lock.json"))
	var lines: Array[String] = ["# Poly Haven CC0 models (place with Props.place(level, parent, \"ph/<id>\", pos, yaw, height, collide))", "",
		"Sizes are measured in-engine at authored scale (metres, X x Y(height) x Z). Height 0 keeps this scale.", "",
		"| id | name | size m (x × y × z) | categories |", "|---|---|---|---|"]
	var bad := 0
	var ids: Array = []
	for k in lock:
		if str(k).begins_with("model:"):
			ids.append(str(k).substr(6))
	ids.sort()
	for id in ids:
		var b := Props.bounds("ph/" + id)
		if b.size == Vector3.ZERO:
			bad += 1
		var e: Dictionary = lock["model:" + id]
		lines.append("| `ph/%s` | %s | %.2f × %.2f × %.2f | %s |" % [id, e.get("name", ""), b.size.x, b.size.y, b.size.z, ""])
	var f := FileAccess.open("res://assets/external/models/INDEX.md", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("PROPS_INDEX models=%d unmeasured=%d" % [ids.size(), bad])
	get_tree().quit(bad)
