extends RefCounted
## DEV17 Poolrooms: two different-height tiled mezzanine networks AND two
## independent dry-to-deep ramps for genuinely looped underwater navigation.
## Uses tile geometry and physical ramp/stair collision only; never teleports.
const WALK := -0.18

static func spec(second: bool) -> Dictionary:
    var obj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev17_pool_annexes.json"))
    var key := "annex_b" if second else "annex_a"
    var d: Dictionary = obj["annexes"][key]
    return {"tiers": int(d["tiers"]), "rise": float(d["rise_m"]),
        "pool_floor": float(d["basin_floor_m"]),
        "stair_x": [5.5, 28.5], "lower_z": 4.5, "upper_z": 18.5,
        "run": 14.0, "stair_width": 2.0}

static func _deck(k: GeoKit, o: Vector3, x0: float, z0: float,
        x1: float, z1: float, y: float) -> void:
    k.slab(o.x + x0, o.z + z0, o.x + x1, o.z + z1, y, 0.22, "l37_tile")

static func install(k: GeoKit, o: Vector3, second: bool) -> Dictionary:
    var p := spec(second)
    var tiers: int = p["tiers"]
    var rise: float = p["rise"]
    var lanterns: Array = []
    # Two long opposing parallel stairs on the perimeter. Their landing
    # positions alternate north/south, creating a genuine stacked ladder;
    # full-width connecting decks close an independent circuit on each tier.
    for f in range(tiers - 1):
        var lower_y := WALK + float(f) * rise
        var northbound := f % 2 == 0
        var z0 := 4.5 if northbound else 18.5
        var forward := Vector3(0, 0, 1 if northbound else -1)
        for x in p["stair_x"]:
            k.stairs(o + Vector3(x, lower_y + 0.015, z0), forward, 2.0,
                rise, 28, "l37_tile", 0.5, false)
    # Broad landings only at stair endpoints. The underwater pool is visible
    # directly between the two opposed stairs on every tier.
    for f in range(1, tiers):
        var y := WALK + float(f) * rise
        var zc := 18.5 if f % 2 == 1 else 4.5
        _deck(k, o, 4.1, zc - 1.6, 29.9, zc + 1.6, y)
        # Central observation island has two independent bridge approaches;
        # its topology is a closed loop, not an unreachable display platform.
        var island_z := 10.8 if f % 2 == 1 else 12.0
        _deck(k, o, 13.0, island_z - 1.7, 22.0, island_z + 1.7, y)
        var za := minf(zc, island_z)
        var zb := maxf(zc, island_z)
        for xx in [15.3, 20.8]:
            _deck(k, o, xx - 1.0, za, xx + 1.0, zb, y)
        for xx in [13.0, 22.0]:
            # edge protection; gaps to bridge approaches remain open.
            k.box(o + Vector3(xx, y + 0.6, island_z),
                Vector3(0.12, 1.2, 2.5), "l37_tile")
        lanterns.append([o.x + 17.5, y + 0.7, o.z + island_z])
    # Two bathymetric ramps, one descending and another surfacing on the
    # opposite bank. Neither requires a scripted swim or a hidden teleport.
    var bot: float = p["pool_floor"]
    var chain_a: Array = [Vector3(9.0, WALK, 9.0), Vector3(13.0, -2.0, 12.0),
        Vector3(18.0, -4.1, 12.0), Vector3(22.0, -6.1, 15.0),
        Vector3(21.0, bot, 21.0)]
    var chain_b: Array = [Vector3(21.0, bot, 21.0), Vector3(25.0, -6.25, 19.0),
        Vector3(23.0, -4.25, 14.0), Vector3(17.0, -2.25, 11.0),
        Vector3(12.0, WALK, 15.0), Vector3(9.0, WALK, 15.0)]
    for chain in [chain_a, chain_b]:
        for i in range(chain.size() - 1):
            var a: Vector3 = chain[i]
            var b: Vector3 = chain[i + 1]
            k.ramp(o + a, o + b, 1.6, 0.18, "l37_tile")
    # Lighted deep observation posts, excluding collision from the walkway.
    lanterns.append([o.x + 20.0, bot + 1.6, o.z + 19.0])
    return {"tiers": tiers, "rise_m": rise, "stair_runs": 2 * (tiers - 1),
        "island_loops": tiers - 1, "deep_ramp_segments": 9,
        "basin_floor": bot, "lanterns": lanterns}
