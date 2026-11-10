extends SceneTree
## Godot 4.5.1 headless deterministic invariant sweep (no rendered collision QA).
var checked := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_test")

func _expect(label: String, ok: bool) -> void:
    checked += 1
    if not ok:
        failed += 1
        push_error("CONTINUITY V4: " + label)

func _test() -> void:
    var opposites := {"east": "west", "west": "east", "north": "south", "south": "north"}
    for seed_value in [1, 1337, 928374]:
        for x in range(-17, 18):
            for z in range(-17, 18):
                for floor in range(-2, 3):
                    var k := Vector3i(x, floor, z)
                    for face in ["east", "west", "north", "south"]:
                        var neighbor := ContinuityTopology.neighbor_of(k, face)
                        var a := ContinuityTopology.face_openings(seed_value, k, face)
                        var reverse_openings := ContinuityTopology.face_openings(seed_value, neighbor, opposites[face])
                        _expect("mirrored face", a == reverse_openings)
                    var h := ContinuityTopology.continuity_hole(seed_value, k)
                    var bridge := ContinuityTopology.continuity_bridge(seed_value, k)
                    _expect("hole/bridge pair", (h.size == Vector2.ZERO) == (bridge.size == Vector2.ZERO))
                    if h.size != Vector2.ZERO:
                        _expect("bridge in hole", h.encloses(bridge))
                        var a0 := ContinuityTopology.shaft_x(ContinuityTopology.incoming_shaft(floor)) - 0.6
                        var shaft := Rect2(a0, 5.4, 4.2, 13.2)
                        _expect("stair clear", not h.intersects(shaft))
                    if ContinuityTopology.is_superhub(k):
                        _expect("hub belongs to spine", ContinuityTopology.is_super_spine(k))
                        if floor > -2:
                            _expect("hub has void", h.size == Vector2(4.0, 4.0))
    _expect("initial region fixed", ContinuityTopology.super_type(1337, Vector3i.ZERO) == "threshold_nexus")
    _expect("negative super key", ContinuityTopology.super_key(Vector3i(-1,0,-1)) == Vector3i(-1,0,-1))
    print("ContinuitySuperDistrictTest: %d assertions, %d failures" % [checked,failed])
    quit(1 if failed else 0)
