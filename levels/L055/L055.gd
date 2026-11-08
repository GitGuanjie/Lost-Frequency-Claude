extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Safe room / decaying restaurant with no fixed permanent exit.
## Sourced automatic ejection is approximated by a timed exit in an alcove.
var _time_left := 120.0
var _exit: ExitTrigger
var _sunbeams: Array = []
var _altered := false
var _ejection_sent := false

func build() -> void:
    rules["view_distance"] = 150.0
    indoor_env(Color(0.79, 0.67, 0.47), 0.34, Color(0.38, 0.28, 0.15), 0.003)
    environment.tonemap_exposure = 1.12
    MatLib.define("l55_brick", {"albedo_a": Color(0.43, 0.29, 0.20), "albedo_b": Color(0.35, 0.21, 0.15), "stain_amount": 0.45}, "brick")
    MatLib.define("l55_wall", {"albedo_a": Color(0.58, 0.46, 0.32), "albedo_b": Color(0.69, 0.59, 0.39), "stain_amount": 0.48}, "plaster")
    MatLib.define("l55_wood", {"albedo_a": Color(0.42, 0.25, 0.13), "albedo_b": Color(0.27, 0.17, 0.09), "roughness_a": 0.93}, "wood_floor")
    MatLib.register("l55_sun", MatLib.panel(Color(1.0, 0.81, 0.55), 2.3))
    lights.setup(9, 1)
    _restaurant()
    add_arrival("start", Vector3(0, 0.08, -40))
    add_arrival("from_L011", Vector3(0, 0.08, -40))
    _exit = add_exit("L055>EXT#1", "condition", Vector3(0, 1.4, 65), Vector3(4.0, 2.8, 4.0), "The room is changing around you")
    _exit.condition = func(): return SessionState.is_qa() and _time_left <= 0.0
    if SessionState.is_qa():
        _time_left = 0.0
    else:
        _time_left = rng.randf_range(100.0, 180.0)
    add_landmark("The Safe Room", Vector3(0, 0.2, -37))
    add_landmark("The unseen sunlight", Vector3(8, 2.0, 17))
    add_shot("safe_room", Vector3(0, 1.62, -38), Vector3(2, 1.4, -12))
    add_shot("sunlit_outskirts", Vector3(0, 1.62, 22), Vector3(0, 1.5, 64))
    sound.bed("room_tone", {"seconds": 7.0, "cutoff": 240.0}, -39.0)
    sound.oneshot("creak", {"freq": 105.0}, 15.0, 32.0, 12.0, "[old floorboards creak in another room]", -27.0)

    ModelDress.decorate(self, "L055")

func _restaurant() -> void:
    var k := kit("RusticSegmentedRestaurant")
    k.slab(-18, -52, 18, 80, 0, 0.36, "l55_wood")
    k.box(Vector3(0, 4.85, 14), Vector3(36, 0.4, 132), "l55_wall")
    for x in [-18.0, 18.0]:
        k.box(Vector3(x, 2.5, 14), Vector3(0.4, 5.0, 132), "l55_brick")
    for z in [-51.9, 79.9]:
        k.box(Vector3(0, 2.5, z), Vector3(36.0, 5.0, 0.35), "l55_wall")
    for z in [-16.0, 28.0]:
        for x0 in [-15.0, 15.0]:
            k.box(Vector3(x0, 2.4, z), Vector3(5.5, 4.8, 0.28), "l55_brick")
        k.box(Vector3(0, 3.8, z), Vector3(6.0, 0.25, 0.28), "l55_wall")
    for i in 34:
        var z := -40.0 + float(i / 2) * 6.6
        var x := -8.0 if i % 2 == 0 else 8.0
        k.box(Vector3(x, 0.73, z), Vector3(3.0, 1.46, 1.2), "l55_wood")
        for s in [-1.8, 1.8]:
            k.box(Vector3(x + s, 0.38, z), Vector3(0.55, 0.76, 0.55), "l55_wood")
    for j in 6:
        var z := -36.0 + float(j) * 19.0
        k.box(Vector3(0, 4.78, z), Vector3(4.5, 0.09, 2.2), "l55_sun", GeoKit.NY, false)
        lights.add_anchor(Vector3(0, 4.5, z), Color(1.0, 0.81, 0.59), 0.93, 16.0, 0.90, "l55_unseen_sun")
        _sunbeams.append(z)
    for z in [-43.0, 4.0, 47.0]:
        k.box(Vector3(14.0, 0.85, z), Vector3(4.5, 1.7, 1.4), "l55_wood")
    k.commit()
    add_note("food", "SAFE ROOM", "The meal left on the table is ordinary food. The water in the kitchen is ordinary water. No one is running the restaurant.", Vector3(1.3, 0.9, -45))
    add_note("evacuation", "DO NOT MAKE A HOME HERE", "Every route out seems to lead back to where the visitor came from. The waiting time is never the same.", Vector3(-2.5, 0.9, 36))

func level_process(delta: float) -> void:
    if not SessionState.is_qa():
        _time_left -= delta
        if _time_left <= 0.0 and not _altered:
            _altered = true
            Overlay.subtitle("[the furniture seems to have changed when you looked away]", 4.0)
        if _time_left <= 0.0 and not _ejection_sent:
            # This level ejects travellers automatically, not via a voluntary door.
            _ejection_sent = true
            TransitionService.request_exit("L055>EXT#1")

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"one random-return source boundary", "ok":_exit != null}, {"what":"safe room origin", "ok":arrivals.has("from_L011")}, {"what":"unseen sunlight anchors", "ok":_sunbeams.size() == 6}]
