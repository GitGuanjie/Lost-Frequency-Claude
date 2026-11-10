extends SceneTree
## Godot 4.5.1: --headless --path . --script res://tests/ContinuityMacroStructureTest.gd
## This is a native deterministic plan test; it is NOT a physical walkthrough.
var failed := 0
var checked := 0

func _initialize() -> void:
	call_deferred("_go")

func _ok(name: String, ok: bool) -> void:
	checked += 1
	if not ok:
		failed += 1
		push_error("MACRO-STRUCTURE: " + name)

func _go() -> void:
	for seed_value in [1, 1337, 928374]:
		for mx in range(-3, 4):
			for mz in range(-3, 4):
				for floor in range(-2, 3):
					for ix in range(4):
						for iz in range(4):
							var k := Vector3i(4 * mx + ix, floor, 4 * mz + iz)
							for face in ["east", "west", "north", "south"]:
								var other := ContinuityTopology.neighbor_of(k, face)
								var inverse := "west" if face == "east" else ("east" if face == "west" else ("south" if face == "north" else "north"))
								_ok("matched border openings", ContinuityTopology.face_openings(seed_value, k, face) ==
									ContinuityTopology.face_openings(seed_value, other, inverse))
							var h := ContinuityTopology.atrium_hole(seed_value, k)
							var b := ContinuityTopology.atrium_bridge(seed_value, k)
							_ok("bridge iff atrium hole", (b.size == Vector2.ZERO) == (h.size == Vector2.ZERO))
							if h.size != Vector2.ZERO:
								_ok("bridge inside well", h.encloses(b))
								var a := ContinuityTopology.shaft_x(ContinuityTopology.incoming_shaft(floor)) - 0.6
								var stair := Rect2(a, 5.4, 4.2, 13.2)
								_ok("stair and void disjoint", not h.intersects(stair))
							_ok("stable macro type", ContinuityTopology.macro_structure(seed_value, k) ==
								ContinuityTopology.macro_structure(seed_value, k))
	_ok("starting macro is atrium", ContinuityTopology.macro_structure(1337, Vector3i.ZERO) == "grand_atrium")
	print("ContinuityMacroStructureTest: %d assertions, %d failures" % [checked, failed])
	quit(1 if failed else 0)
