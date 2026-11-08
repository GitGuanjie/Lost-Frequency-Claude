extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Two-storey renovated house, large attic, old oak tree. Narrator is unreliable.
var _ac_timer := 8.0
var _oak_exit: ExitTrigger
var _stairs := 0

func build() -> void:
    indoor_env(Color(0.88, 0.80, 0.69), 0.40, Color(0.65, 0.60, 0.51), 0.001)
    rules["view_distance"] = 160.0
    MatLib.define("l90_white", {"albedo_a": Color(0.85, 0.82, 0.76), "albedo_b": Color(0.88, 0.84, 0.81)}, "plaster")
    MatLib.define("l90_floor", {"albedo_a": Color(0.48, 0.34, 0.22), "albedo_b": Color(0.54, 0.39, 0.26)}, "wood_floor")
    MatLib.define("l90_shingle", {"albedo_a": Color(0.25, 0.32, 0.34), "albedo_b": Color(0.34, 0.36, 0.39)}, "concrete")
    MatLib.define("l90_bark", {"albedo_a": Color(0.26, 0.19, 0.13), "albedo_b": Color(0.40, 0.29, 0.18)}, "wood_floor")
    MatLib.define("l90_leaf", {"albedo_a": Color(0.18, 0.25, 0.14), "albedo_b": Color(0.29, 0.32, 0.16)}, "grass")
    lights.setup(9, 1)
    _home()
    _oak_exit = add_exit("L090>EXT#1", "walk_in", Vector3(2, 1.0, 58), Vector3(5.0, 2.2, 4.5), "The old oak tree beyond the renovated home")
    add_arrival("start", Vector3(0, 0.08, -21))
    add_arrival("from_L025", Vector3(0, 0.08, -21))
    add_landmark("The newly renovated foyer", Vector3(0, 0.4, -14))
    add_landmark("Two-floor stairwell", Vector3(8, 1.9, 0))
    add_landmark("The attic", Vector3(0, 7.0, 5))
    add_landmark("The old oak tree", Vector3(2, 0, 55))
    add_shot("foyer", Vector3(1, 1.62, -18), Vector3(0, 2, 12))
    add_shot("oak", Vector3(3, 1.62, 33), Vector3(2, 4.0, 57))
    sound.bed("room_tone", {"seconds": 5.0, "cutoff": 320.0}, -34.0)
    sound.oneshot("creak", {"freq": 95.0}, 35.0, 85.0, 12.0, "[the air conditioner clicks without turning on]", -27.0)

    ModelDress.decorate(self, "L090")

func _home() -> void:
    var k := kit("RenovatedHouse")
    k.slab(-14, -26, 14, 30, 0.0, 0.36, "l90_floor")
    # Subtract stair openings from the two upper floor plates; never clip
    # a full collision slab through a staircase.
    k.slab(-14, -26, 14, -11, 4.0, 0.36, "l90_floor")
    k.slab(-14, 2, 14, 30, 4.0, 0.36, "l90_floor")
    k.slab(-14, -11, 5, 2, 4.0, 0.36, "l90_floor")
    k.slab(10, -11, 14, 2, 4.0, 0.36, "l90_floor")
    k.slab(-14, -26, 14, -1, 8.0, 0.40, "l90_shingle")
    k.slab(-14, 12, 14, 30, 8.0, 0.40, "l90_shingle")
    k.slab(-14, -1, -10, 12, 8.0, 0.40, "l90_shingle")
    k.slab(-5, -1, 14, 12, 8.0, 0.40, "l90_shingle")
    for x in [-14.0, 14.0]:
        k.box(Vector3(x, 4.0, 2), Vector3(0.40, 8.0, 56), "l90_white")
    k.box(Vector3(0, 4.0, -26), Vector3(28, 8.0, 0.4), "l90_white")
    k.box(Vector3(-9.0, 4.0, 30), Vector3(10, 8.0, 0.35), "l90_white")
    k.box(Vector3(9.0, 4.0, 30), Vector3(10, 8.0, 0.35), "l90_white")
    k.box(Vector3(0, 6.4, 30), Vector3(8, 3.2, 0.35), "l90_white")
    # No collision ceiling crosses the actual stairs.
    k.stairs(Vector3(7.5, 0, -10.0), Vector3(0, 0, 1), 2.1, 4.0, 20, "l90_floor", 0.54)
    k.stairs(Vector3(-7.5, 4.0, 0), Vector3(0, 0, 1), 2.1, 4.0, 20, "l90_floor", 0.54)
    _stairs = 2
    for y in [0.0, 4.0]:
        for z in [-15.0, 9.0]:
            k.box(Vector3(0, y + 0.55, z), Vector3(4.2, 1.1, 1.5), "l90_floor")
        for x in [-11.0, 11.0]:
            k.box(Vector3(x, y + 0.8, 14.0), Vector3(3.3, 1.6, 6.0), "l90_white")
    # Loft is low but accessible from the second stair.
    # A high roof leaves the attic traversable and preserves its low eaves.
    k.box(Vector3(0, 11.4, 2), Vector3(27.5, 0.30, 55), "l90_shingle")
    for z in [-12.0, 13.0, 27.0]:
        k.box(Vector3(0, 9.6, z), Vector3(4.0, 0.1, 1.5), "l90_white")
    # Yard with defining old oak. Natural scale and rough bough silhouette.
    k.slab(-27, 30, 27, 88, -0.07, 0.2, "l90_leaf")
    k.cylinder(Vector3(2, 3.75, 55), 1.3, 7.5, "l90_bark", 12)
    for i in 7:
        var a := float(i) * TAU / 7.0
        k.box(Vector3(2 + cos(a) * 3.7, 8.0, 55 + sin(a) * 3.7), Vector3(5.0, 2.3, 5.0), "l90_leaf", GeoKit.ALL, false)
    k.commit()
    for z in [-17.0, 6.0, 22.0]:
        lights.add_anchor(Vector3(0, 3.5, z), Color(1, 0.89, 0.73), 0.8, 12.0, 0.75, "l90_light")
    add_note("estate", "A HOUSE FOR YOU", "They say the renovation is finished. The air conditioner does not seem to agree.", Vector3(2, 0.9, -16))
    add_note("attic", "UPSTAIRS", "Both bedrooms have been cleaned. The attic still smells like old plaster.", Vector3(-2, 4.9, 12))

func level_process(delta: float) -> void:
    _ac_timer -= delta
    if _ac_timer <= 0.0:
        _ac_timer = rng.randf_range(16, 48)
        if not SessionState.is_qa():
            Overlay.subtitle("[the broken air conditioner tries to start]", 3.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"two flight house staircase", "ok":_stairs == 2}, {"what":"exit near old oak", "ok":_oak_exit != null}, {"what":"arrival from L025", "ok":arrivals.has("from_L025")}]
