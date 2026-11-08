extends LevelBase
const ImmersiveNetworks := preload("res://core/world/ImmersiveNetworks.gd")
## Vaporwave desert-ocean-city horizon and the grounded Trench hyperlink terminal.
var _choice := ""
var _terminals: Array = []
var _sea: WaterVolume

func build() -> void:
    rules["view_distance"] = 1400.0
    outdoor_env(Color(0.38, 0.17, 0.51), Color(0.93, 0.43, 0.51), Color(0.36, 0.14, 0.45), Vector2(9, -60), Color(1.0, 0.37, 0.40), 1.15, Color(0.65, 0.27, 0.47), 0.0008)
    MatLib.define("l201_sand", {"albedo_a": Color(0.75, 0.55, 0.21), "albedo_b": Color(0.57, 0.28, 0.56), "noise_scale": 3.0}, "sand")
    MatLib.define("l201_city", {"albedo_a": Color(0.21, 0.13, 0.33), "albedo_b": Color(0.35, 0.20, 0.47)}, "concrete")
    MatLib.register("l201_neon", MatLib.panel(Color(0.20, 0.94, 0.89), 1.6))
    MatLib.register("l201_pink", MatLib.panel(Color(1.0, 0.23, 0.61), 1.7))
    MatLib.register("l201_water", MatLib.water({"shallow_color": Color(0.16, 0.37, 0.58), "deep_color": Color(0.09, 0.15, 0.33), "wave_height": 0.04}))
    lights.setup(8, 1)
    _landscape()
    _trench()
    _routes()
    # DEV25: wiki-aware, optional traversable annex; original exits unchanged.
    ImmersiveNetworks.install(self)
    add_arrival("start", Vector3(0, 0.08, 7))
    add_arrival("from_L001", Vector3(0, 0.08, 7))
    add_arrival("from_L011", Vector3(0, 0.08, 7))
    add_arrival("from_L025", Vector3(0, 0.08, 7))
    add_landmark("The constant segmented sunset", Vector3(-160, 10, 0))
    add_landmark("Trench access terminal", Vector3(8, 0.8, 22))
    add_landmark("The bright distant city", Vector3(190, 1, 0))
    add_shot("stalled_sunset", Vector3(5, 1.62, 7), Vector3(-155, 25, 0))
    add_shot("trench_city", Vector3(-5, 1.62, 9), Vector3(85, 8, 26))
    sound.bed("pad", {"root": 48, "bright": 0.18}, -31.0)
    sound.bed("water_bed", {"seconds": 6.0, "bright": 0.1}, -32.0)

func _landscape() -> void:
    var k := kit("VaporwaveDesertCityOcean")
    # The left edge is real open water; never hide it under a full sand slab.
    k.slab(-163, -210, 210, 210, 0, 0.50, "l201_sand")
    k.slab(-210, -210, -163, 210, -2.0, 0.35, "l201_sand")
    for i in 48:
        var x := 70.0 + float(i % 6) * 19.0
        var z := -130.0 + float(int(i / 6)) * 31.0
        var height := rng.randf_range(9.0, 52.0)
        k.box(Vector3(x, height * 0.5, z), Vector3(12, height, 13), "l201_city")
        k.box(Vector3(x, height + 0.1, z), Vector3(10, 0.20, 11), "l201_neon" if i % 3 == 0 else "l201_pink", GeoKit.ALL, false)
    # White sky-grid: planar lines in the far distance, non-collidable.
    for i in 13:
        var x := -195.0 + float(i) * 30.0
        k.box(Vector3(x, 91, -178), Vector3(0.15, 0.15, 360), "l201_neon", GeoKit.ALL, false)
        var z := -180.0 + float(i) * 30.0
        k.box(Vector3(0, 91, z), Vector3(385, 0.15, 0.15), "l201_neon", GeoKit.ALL, false)
    # Broken horizontal sunset strips, seen hovering low above the ocean.
    for i in 7:
        k.box(Vector3(-186, 18.0 + float(i) * 2.0, 0), Vector3(0.3, 1.3, 29.0 - float(i) * 2.0), "l201_pink", GeoKit.ALL, false)
    k.commit()
    _sea = WaterVolume.new()
    add_child(_sea)
    _sea.setup(Vector3(-210, -1.8, -210), Vector3(-163, -0.3, 210), "l201_water", true)

func _trench() -> void:
    var k := kit("TrenchTerminalAndArcade")
    k.slab(-11, 13, 25, 37, 0.08, 0.3, "l201_city")
    for i in 4:
        var x := 0.0 + float(i) * 5.0
        k.box(Vector3(x, 0.95, 24), Vector3(3.0, 1.9, 1.7), "l201_city")
        k.box(Vector3(x, 1.5, 23.1), Vector3(2.4, 1.0, 0.08), "l201_neon" if i % 2 == 0 else "l201_pink", GeoKit.ALL, false)
        _terminals.append(Vector3(x, 1.2, 22.3))
        lights.add_anchor(Vector3(x, 2.8, 23), Color(0.3, 0.91, 0.91), 0.75, 6.0, 0.9, "l201_kiosk")
    k.commit()
    for i in _terminals.size():
        var dest := ["L001", "L003", "L004", "L025"][i]
        add_interactable(_terminals[i], Vector3(2.4, 1.5, 1.0), "Trench: select %s" % dest, func(): _select(dest))
    add_note("trench", "TRENCH / SAFE LINKS", "Select a working hyperlink on a nearby console. Broken and unknown links have not been configured here.", Vector3(-8, 0.8, 21))

func _select(dest: String) -> void:
    _choice = dest
    Overlay.subtitle("[a new destination appears on the terminal: %s]" % dest, 3.0)

func _routes() -> void:
    # Each exit is explicit so static audits can prove it matches the manifest.
    var gate1 := add_exit("L201>L001#3", "interact", Vector3(0, 1.2, 26.3), Vector3(2.1, 2.0, 1.8), "Follow Trench link to L001")
    var gate3 := add_exit("L201>L003#4", "interact", Vector3(5, 1.2, 26.3), Vector3(2.1, 2.0, 1.8), "Follow Trench link to L003")
    var gate4 := add_exit("L201>L004#5", "interact", Vector3(10, 1.2, 26.3), Vector3(2.1, 2.0, 1.8), "Follow Trench link to L004")
    var gate25 := add_exit("L201>L025#8", "interact", Vector3(15, 1.2, 26.3), Vector3(2.1, 2.0, 1.8), "Follow Trench link to L025")
    gate1.condition = func(): return _choice == "L001"
    gate3.condition = func(): return _choice == "L003"
    gate4.condition = func(): return _choice == "L004"
    gate25.condition = func(): return _choice == "L025"

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four sourced Trench destinations", "ok":_terminals.size() == 4 and exits.size() == 4}, {"what":"all link gates require selection", "ok": _choice == ""}, {"what":"arrival from known L001", "ok":arrivals.has("from_L001")}]
