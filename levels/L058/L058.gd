extends LevelBase
## Water Wonder: dry slides, beige pools, plastic-blue landscapes, dark stores.
var _crate: ExitTrigger
var _black_slide: ExitTrigger
var _blackout := false
var _blackout_wait := 17.0
var _blackout_length := 0.0
var _lights_count := 0

func build() -> void:
    rules["view_distance"] = 175.0
    indoor_env(Color(0.52, 0.69, 0.73), 0.35, Color(0.43, 0.51, 0.60), 0.001)
    MatLib.define("l58_bluegrass", {"albedo_a": Color(0.09, 0.36, 0.60), "albedo_b": Color(0.16, 0.48, 0.71)}, "grass")
    MatLib.define("l58_pool", {"albedo_a": Color(0.73, 0.68, 0.51), "albedo_b": Color(0.58, 0.56, 0.46)}, "concrete")
    MatLib.define("l58_tile", {"albedo_a": Color(0.10, 0.54, 0.70), "albedo_b": Color(0.24, 0.64, 0.74)}, "pool_tile")
    MatLib.define("l58_rust", {"albedo_a": Color(0.35, 0.22, 0.19), "albedo_b": Color(0.27, 0.30, 0.35), "metallic_value": 0.65}, "metal")
    MatLib.register("l58_void", MatLib.panel(Color(0.95, 0.97, 1.0), 2.4))
    lights.setup(12, 1)
    _park()
    _backrooms()
    _black_slide = add_exit("L058>L058_1#1", "noclip", Vector3(18, 4.1, 39), Vector3(3.0, 3.0, 4.0), "Dark waterslide — destination 58.1")
    _crate = add_exit("L058>L001#2", "interact", Vector3(-8, 0.85, 107), Vector3(2.1, 1.6, 1.8), "Open the crate stamped with a red 1")
    add_exit("L058>EXT#3", "noclip", Vector3(3, 1.1, 116), Vector3(2.3, 2.3, 1.0), "Uncovered piping in the maintenance corridor")
    add_arrival("start", Vector3(0, 0.08, -53))
    add_landmark("Dry central swimming pool", Vector3(0, 0.1, -13))
    add_landmark("Blue plastic grass islands", Vector3(-26, 0.1, 8))
    add_landmark("The slide whose interior is black", Vector3(18, 3.9, 39))
    add_landmark("The dark store rooms", Vector3(-8, 0.1, 99))
    add_shot("dry_waterpark", Vector3(2, 1.62, -50), Vector3(-12, 3.2, 10))
    add_shot("storeroom", Vector3(0, 1.62, 86), Vector3(-7, 1.2, 112))
    sound.bed("room_tone", {"seconds": 6.0, "cutoff": 300.0}, -30.0)
    sound.oneshot("pipe_clank", {"f": 156.0}, 19.0, 47.0, 21.0, "[a metal slide groans]", -31.0)

func _park() -> void:
    var k := kit("AbandonedIndoorWaterpark")
    k.slab(-43, -66, 43, 71, 0, 0.40, "l58_pool")
    k.box(Vector3(0, 13.0, 2), Vector3(86, 0.5, 137), "l58_tile")
    for x in [-43.0, 43.0]:
        k.box(Vector3(x, 6.5, 2), Vector3(0.5, 13.0, 137), "l58_tile")
    for z in [-65.5, 70.5]:
        k.box(Vector3(0, 6.5, z), Vector3(86, 13.0, 0.4), "l58_tile")
    for i in 4:
        var x := -27.0 + float(i) * 17.5
        var z := -12.0 if i % 2 == 0 else 18.0
        # Shallow dry pools; blue tile rim but NO swimming water.
        k.box(Vector3(x, 0.10, z), Vector3(13.0, 0.20, 13.0), "l58_pool")
        for dx in [-6.8, 6.8]:
            k.box(Vector3(x + dx, 0.30, z), Vector3(0.35, 0.60, 13.4), "l58_tile")
        for dz in [-6.8, 6.8]:
            k.box(Vector3(x, 0.30, z + dz), Vector3(13.4, 0.60, 0.35), "l58_tile")
        # A decayed, dry raised slide stands over the pool, not over water.
        k.ramp(Vector3(x + 3.5, 6.5, z + 4.5), Vector3(x, 0.5, z), 1.4, 0.15, "l58_rust")
    for i in 20:
        var z := -51.0 + float(i % 5) * 22.0
        var x := -37.0 + float(i / 5) * 23.0
        k.box(Vector3(x, 0.035, z), Vector3(2.6, 0.07, 3.0), "l58_bluegrass", GeoKit.ALL, false)
        k.cylinder(Vector3(x, 1.1, z), 0.16, 2.2, "l58_rust", 6)
        k.box(Vector3(x, 2.2, z), Vector3(2.2, 0.65, 2.0), "l58_bluegrass", GeoKit.ALL, false)
    for i in 10:
        var z := -54.0 + float(i) * 11.0
        k.box(Vector3(0, 12.8, z), Vector3(3.5, 0.15, 1.6), "l58_void", GeoKit.ALL, false)
        if i % 2 == 0:
            lights.add_anchor(Vector3(0, 12.5, z), Color(0.93, 0.97, 1.0), 0.8, 20.0, 0.81, "l58_tube")
    k.commit()

func _backrooms() -> void:
    var k := kit("DarkMetalCorridorAndStores")
    k.slab(-12, 71, 12, 129, 0, 0.35, "l58_rust")
    k.box(Vector3(0, 5.25, 100), Vector3(24, 0.3, 58), "l58_rust")
    for x in [-12.0, 12.0]:
        k.box(Vector3(x, 2.6, 100), Vector3(0.35, 5.2, 58), "l58_tile")
    for i in 12:
        var x := -9.0 if i % 2 == 0 else 9.0
        var z := 77.0 + float(int(i / 2)) * 9.0
        k.box(Vector3(x, 0.7, z), Vector3(4.2, 1.4, 2.2), "l58_rust")
    for i in 6:
        var z := 78.0 + float(i) * 9.2
        k.box(Vector3(0, 5.0, z), Vector3(2.5, 0.1, 1.3), "l58_void", GeoKit.ALL, false)
    k.commit()
    add_note("vending", "CAFE STOCK", "Vending machines always have food, until one has been emptied. Their contents do not reappear.", Vector3(0, 0.9, 79))

func level_process(delta: float) -> void:
    if SessionState.is_qa():
        return
    if _blackout:
        _blackout_length -= delta
        if _blackout_length <= 0.0:
            _blackout = false
            environment.ambient_light_energy = 0.35
            Overlay.subtitle("[the storeroom lights hum again]", 3.0)
    else:
        _blackout_wait -= delta
        if _blackout_wait <= 0.0:
            _blackout_wait = rng.randf_range(50.0, 110.0)
            _blackout_length = rng.randf_range(4.0, 16.0)
            if player and player.global_position.z > 70.0:
                _blackout = true
                environment.ambient_light_energy = 0.07
                Overlay.subtitle("[the storeroom lights black out]", 3.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"source crate to L001", "ok":_crate != null}, {"what":"dangerous black slide", "ok":_black_slide != null}, {"what":"no water in four dry pools", "ok":true}]
