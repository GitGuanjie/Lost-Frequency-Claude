extends RefCounted
## DEV19 secondary karst networks: three physical SDF tubes that branch from
## existing DEV17 cave-braid nodes and rejoin a different existing node.
## The ecological labels are adaptations, not names claimed by the Wiki.
const SOURCE := "res://data/dev19_cave_ecologies.json"

static func spec() -> Dictionary:
	var obj = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not obj is Dictionary:
		push_error("DEV19 cave ecologies JSON missing or invalid")
		return {"routes": []}
	return obj

static func observation_sites() -> Array:
	var out: Array = []
	for route in spec().get("routes", []):
		var nodes: Array = route["floor_nodes"]
		var p: Array = nodes[int(route["observation_index"])]
		out.append({"id": str(route["id"]), "at": Vector3(float(p[0]), float(p[1]), float(p[2])),
			"text": str(route["observation"])})
	return out

static func carve_features() -> Array:
	var out: Array = []
	for route in spec().get("routes", []):
		var nodes: Array = route["floor_nodes"]
		var rad := float(route["radius_m"])
		for i in range(nodes.size() - 1):
			var ap: Array = nodes[i]
			var bp: Array = nodes[i + 1]
			var a := Vector3(float(ap[0]), float(ap[1]), float(ap[2]))
			var b := Vector3(float(bp[0]), float(bp[1]), float(bp[2]))
			out.append({"t": "tube", "a": a + Vector3.UP * 1.65,
				"b": b + Vector3.UP * 1.65, "ra": rad, "rb": rad,
				"sq": 0.96, "fa": a.y, "fb": b.y, "amp": 0.32})
		# Real mid-route chambers overlap the tubes (not disconnected bubbles).
		var at: Vector3 = observation_sites_for(route)
		out.append({"t": "room", "c": at + Vector3.UP * 2.4,
			"r": Vector3(rad * 2.6, 4.2, rad * 2.5), "f": at.y, "amp": 0.5})
	return out

static func observation_sites_for(route: Dictionary) -> Vector3:
	var item: Array = route["floor_nodes"][int(route["observation_index"])]
	return Vector3(float(item[0]), float(item[1]), float(item[2]))
