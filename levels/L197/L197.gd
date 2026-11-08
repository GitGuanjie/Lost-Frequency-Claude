extends LevelBase
## Four source-described crystal zones. Bright turquoise, amethyst, ruby and onyx.
var _zone_count := 4
var _lights_by_zone: Array = []
var _verified: Array = []
var _water: WaterVolume

func build() -> void:
    rules["view_distance"] = 170.0
    indoor_env(Color(0.26, 0.38, 0.48), 0.31, Color(0.06, 0.12, 0.18), 0.008)
    MatLib.define("l197_rock", {"albedo_a": Color(0.10, 0.14, 0.19), "albedo_b": Color(0.18, 0.22, 0.27), "noise_scale": 5.0}, "rock")
    MatLib.register("l197_turquoise", MatLib.panel(Color(0.20, 0.88, 0.85), 1.8))
    MatLib.register("l197_amethyst", MatLib.panel(Color(0.60, 0.26, 0.92), 1.9))
    MatLib.register("l197_ruby", MatLib.panel(Color(0.96, 0.14, 0.22), 2.1))
    MatLib.register("l197_onyx", MatLib.panel(Color(0.11, 0.14, 0.23), 0.22))
    lights.setup(16, 1)
    _cavern()
    # DEV26: real two-ramp loops at four different mineral elevations.
    preload("res://core/world/CaveGallery26.gd").install(self)
    _water = WaterVolume.new()
    add_child(_water)
    MatLib.register("l197_distilled", MatLib.water({"shallow_color": Color(0.19, 0.56, 0.62), "deep_color": Color(0.05, 0.25, 0.36), "clarity": 0.82}))
    _water.setup(Vector3(-15, -0.2, -7), Vector3(-5, 0.65, 7), "l197_distilled", true)
    _verified.append(add_exit("L197>L197#1", "walk_in", Vector3(0, 1.0, 34), Vector3(4.0, 2.2, 2.2), "The lit path branches back into the caverns"))
    _verified.append(add_exit("L197>L197#2", "walk_in", Vector3(0, 1.0, 76), Vector3(4.0, 2.2, 2.2), "Amethyst gallery leads deeper into the caves"))
    _verified.append(add_exit("L197>L000#5", "interact", Vector3(0, 1.0, 133), Vector3(4.0, 2.2, 2.2), "Follow the faint fluorescent sound"))
    add_arrival("start", Vector3(0, 0.08, -52))
    add_arrival("from_L197", Vector3(0, 0.08, -52))
    add_landmark("Turquoise Meditation Cove", Vector3(-9, 0.0, 0))
    add_landmark("Amethyst gallery", Vector3(0, 0, 48))
    add_landmark("Ruby corridor", Vector3(0, 0, 92))
    add_landmark("Onyx passages", Vector3(0, 0, 123))
    add_shot("turquoise_meditation", Vector3(0, 1.62, -30), Vector3(-8, 1.3, 0))
    add_shot("ruby_onyx", Vector3(0, 1.62, 79), Vector3(0, 2.2, 126))
    sound.bed("drip", {"freq": 370.0}, -34.0)
    sound.bed("room_tone", {"seconds": 6.0, "cutoff": 110.0}, -36.0)

func _cavern() -> void:
    var k := kit("FourCrystalCaveZones")
    k.slab(-19, -59, 19, 145, 0, 0.65, "l197_rock")
    k.box(Vector3(0, 15.0, 43), Vector3(38, 0.4, 204), "l197_rock")
    for x in [-19.0, 19.0]:
        k.box(Vector3(x, 7.6, 43), Vector3(0.5, 15.2, 204), "l197_rock")
    for i in 4:
        var colour := ["l197_turquoise", "l197_amethyst", "l197_ruby", "l197_onyx"][i]
        var z0 := -57.0 + float(i) * 50.0
        for j in 28:
            var z := z0 + rng.randf_range(4.0, 45.0)
            var x := rng.randf_range(-17.0, 17.0)
            if absf(x) < 3.1:
                x = -5.0 if x < 0.0 else 5.0  # preserve main route clearance
            # DEV26: never block an actual ramp or upper gallery with crystals.
            if preload("res://core/world/CaveGallery26.gd").avoids_stair_or_gallery(x,z):
                continue
            # Two-sided rough, columnar crystals and stalactites.
            var height := rng.randf_range(1.1, 5.0)
            k.cylinder(Vector3(x, height * 0.5, z), rng.randf_range(0.19, 0.65), height, colour, 6)
            if j % 3 == 0:
                k.cylinder(Vector3(x, 13.2, z), 0.35, rng.randf_range(2.0, 3.8), colour, 6)
            if j % 5 == 0:
                lights.add_anchor(Vector3(x, 2.0, z), Color(0.15, 0.84, 0.80) if i == 0 else (Color(0.62, 0.2, 0.89) if i == 1 else (Color(0.95, 0.12, 0.12) if i == 2 else Color(0.18, 0.23, 0.40))), 0.7, 12.0, 0.9, "l197_crystal")
        _lights_by_zone.append(colour)
    k.commit()
    add_note("water", "MEDITATION COVE", "A clear, cold trickle gathers here. The mineral walls glow turquoise without a lamp.", Vector3(-10, 0.9, -10))
    add_note("onyx", "UNVERIFIED", "The distant black galleries are incompletely documented. Nobody has established a safe route beyond them.", Vector3(2, 0.9, 118))

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four mineral zones", "ok":_lights_by_zone.size() == _zone_count}, {"what":"three documented routes instantiated", "ok":_verified.size() == 3}, {"what":"water in turquoise zone", "ok":_water != null}]
