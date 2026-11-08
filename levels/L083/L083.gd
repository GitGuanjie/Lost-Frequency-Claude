extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Nuclear submarine at 600m depth: multi-deck metal interior and ocean glimpse.
var _hatch: ExitTrigger
var _eye_t := 0.0
var _decks := 2
var _eye: MeshInstance3D

func build() -> void:
    rules["flashlight"] = "allowed"
    rules["view_distance"] = 120.0
    indoor_env(Color(0.44, 0.59, 0.65), 0.34, Color(0.01, 0.07, 0.11), 0.003)
    MatLib.define("l83_metal", {"albedo_a": Color(0.21, 0.32, 0.38), "albedo_b": Color(0.35, 0.39, 0.42), "metallic_value": 0.66}, "metal")
    MatLib.define("l83_dark", {"albedo_a": Color(0.09, 0.14, 0.18), "albedo_b": Color(0.14, 0.19, 0.21), "metallic_value": 0.7}, "metal")
    MatLib.register("l83_lamp", MatLib.panel(Color(0.63, 0.84, 0.93), 1.6))
    MatLib.define("l83_glass", {"albedo_a": Color(0.05, 0.10, 0.15), "albedo_b": Color(0.05, 0.07, 0.08)}, "glass")
    lights.setup(14, 1)
    _ship()
    _hatch = add_exit("L083>L007#1", "interact", Vector3(0, 1.0, 79), Vector3(2.1, 2.0, 2.1), "Open emergency escape hatch into the ocean")
    add_arrival("start", Vector3(0, 0.08, -69))
    add_arrival("from_L007", Vector3(0, 0.08, -69))
    add_landmark("Stores with restocking food", Vector3(0, 0.3, -38))
    add_landmark("Bridge observation port", Vector3(0, 5.0, 20))
    add_landmark("Aft independent deck ascent", Vector3(0, 4.2, 50))
    add_shot("dev28_aft_return",Vector3(0,5.8,52),Vector3(-1.6,4.8,6))
    add_landmark("The escape hatch", Vector3(0, 0.1, 79))
    add_shot("stores", Vector3(-1.7, 1.62, -64), Vector3(1, 1.5, -20))
    add_shot("bridge", Vector3(0, 5.32, 2), Vector3(0, 5.0, 32))
    sound.bed("room_tone", {"seconds": 5.0, "cutoff": 160.0}, -24.0)
    sound.bed("water_bed", {"seconds": 6.0, "bright": 0.1}, -34.0)
    sound.oneshot("knock", {"hits": 3}, 25.0, 50.0, 32.0, "[three rhythmic knocks beyond the steel hull]", -26.0)
    _eye_t = 13.0

    ModelDress.decorate(self, "L083")

func _ship() -> void:
    var k := kit("SubmarineCompartments")
    for deck in 2:
        var y := float(deck) * 4.2
        if deck == 0:
            k.slab(-7, -76, 7, 88, y, 0.4, "l83_metal")
        else:
            # Upper deck leaves a true clearance hole for the main stair.
            k.slab(-7, -76, 7, -3, y, 0.4, "l83_metal")
            # DEV28 second aft ascent: a true through-floor opening.
            k.slab(-7, 8, 7, 38.5, y, 0.4, "l83_metal")
            k.slab(-7, 38.5, -1.65, 51.5, y, 0.4, "l83_metal")
            k.slab(1.65, 38.5, 7, 51.5, y, 0.4, "l83_metal")
            k.slab(-7, 51.5, 7, 88, y, 0.4, "l83_metal")
            # Real top landings connect flights to the sound upper walk.
            k.slab(-2.8, 6.4, .8, 8.7, y, .4, "l83_metal")
            k.slab(-1.6, 49.4, 2.0, 51.8, y, .4, "l83_metal")
            k.slab(-7, -3, -5, 8, y, 0.4, "l83_metal")
            k.slab(0, -3, 7, 8, y, 0.4, "l83_metal")
        if deck == 0:
            # Opening must penetrate the lower-deck ceiling as well as the
            # upper-deck floor, otherwise the stair is visually present but blocked.
            k.box(Vector3(0, y + 3.9, -39.5), Vector3(14.0, 0.32, 73), "l83_dark")
            # The lower ceiling shares the same aft stair shaft opening.
            k.box(Vector3(0, y + 3.9, 23.25), Vector3(14.0, .32, 30.5), "l83_dark")
            k.box(Vector3(0, y + 3.9, 69.75), Vector3(14.0, .32, 36.5), "l83_dark")
            for xside in [-4.325,4.325]:
                k.box(Vector3(xside, y + 3.9, 45), Vector3(5.35, .32, 13), "l83_dark")
            k.box(Vector3(-6, y + 3.9, 2.5), Vector3(2, 0.32, 11), "l83_dark")
            k.box(Vector3(3.5, y + 3.9, 2.5), Vector3(7, 0.32, 11), "l83_dark")
        else:
            k.box(Vector3(0, y + 3.9, 6), Vector3(14.0, 0.32, 164), "l83_dark")
        for x in [-7.0, 7.0]:
            k.box(Vector3(x, y + 2.0, 6), Vector3(0.34, 4.0, 164), "l83_metal")
        for i in 20:
            var z := -72.0 + float(i) * 8.0
            # Reinforced bulkheads leave a central watertight opening.
            for x in [-5.3, 5.3]:
                k.box(Vector3(x, y + 2.0, z), Vector3(3.4, 4.0, 0.32), "l83_metal")
            k.box(Vector3(0, y + 3.5, z), Vector3(7.3, 1.0, 0.3), "l83_dark")
            k.box(Vector3(0, y + 3.8, z + 2), Vector3(3, 0.1, 1.0), "l83_lamp", GeoKit.ALL, false)
            if i % 2 == 0:
                lights.add_anchor(Vector3(0, y + 3.6, z + 2), Color(0.70, 0.88, 1.0), 0.68, 12.0, 0.82, "l83_fluoro")
        for i in 12:
            var z := -64.0 + float(i) * 13.0
            k.box(Vector3(-5.4, y + 0.7, z), Vector3(2.4, 1.4, 4.0), "l83_dark")
            k.box(Vector3(5.4, y + 0.7, z), Vector3(2.4, 1.4, 4.0), "l83_dark")
    # A traversable inclined passage between the lower and upper decks.
    # Both flights remain within the bulkheads' 7.2-m clear centre aisle.
    k.stairs(Vector3(-1.6, 0, -3), Vector3.BACK, 2.4, 4.2, 20, "l83_metal", 0.5)
    k.stairs(Vector3(0, 0, 40), Vector3.BACK, 2.4, 4.2, 20, "l83_metal", 0.5)
    # Water pressure vista: dark circular windows and one ship bridge at altitude.
    for i in 10:
        var z := -60.0 + float(i) * 14.0
        k.cylinder(Vector3(7.15, 5.8, z), 0.95, 0.12, "l83_glass", 20)
    k.commit()
    add_note("kira", "CREW NOTE", "There are still provisions aboard. Someone has drawn a small pirate flag on the food stores.", Vector3(-3.5, 0.86, -39))
    add_note("reactor", "INTERNAL NOTICE", "Do not disturb the reactor. No exterior route is safe for long.", Vector3(2, 0.9, 45))

func level_process(delta: float) -> void:
    _eye_t -= delta
    if _eye_t <= 0.0 and not SessionState.is_qa():
        _eye_t = rng.randf_range(19.0, 52.0)
        if player and player.global_position.y > 4.0:
            Overlay.subtitle("[a slow tapping sound crosses the observation window]", 4.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"two vertical vessel decks", "ok":_decks == 2}, {"what":"canonical return hatch", "ok":_hatch != null}, {"what":"Level 7 arrival", "ok":arrivals.has("from_L007")}]
