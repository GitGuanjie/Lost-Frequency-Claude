extends RefCounted
## DEV21: level-specific GLB dressing and interactive wayfinding markers for
## DEV20's real, collidable tier blueprints. Scene recipes are audited offline.
## Each physical model uses existing /assets/packs catalog and ModelDress.
## Models are NONBLOCKING by intent; all navigation is made by GeoKit.

const ModelDress = preload("res://core/world/ModelDress.gd")
const AmbientDiscovery = preload("res://core/world/AmbientDiscovery.gd")
const DATA := "res://data/dev21_wing_scenarios.json"
const CELL := 7.0

static func install(owner: LevelBase, tag: String, state,
        x0: float, z0: float, ybase: float, rise: float) -> Dictionary:
    var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not payload is Dictionary:
        push_error("DEV21 invalid scene dressing data")
        return {}
    var recipe: Dictionary = {}
    for raw in payload.get("wings", []):
        if raw.get("id", "") == owner.stable_id and raw.get("anchor", "") == tag:
            recipe = raw
            break
    if recipe.is_empty():
        push_error("DEV21 missing dressing for " + owner.stable_id + ":" + tag)
        return {}
    var group := Node3D.new()
    group.name = "DEV21_DressedRooms_" + tag
    owner.add_child(group)
    var placed := 0
    for prop in recipe["models"]:
        var cell: Array = prop["cell"]
        var c: int = int(cell[0])
        var r: int = int(cell[1])
        var tier: int = int(prop["tier"])
        var p: Array = prop["offset"]
        var center := Vector3(x0 + (float(c) + 0.5) * CELL + float(p[0]),
            ybase + float(tier) * rise, z0 + (float(r) + 0.5) * CELL + float(p[1]))
        var item := {"pack": str(prop["pack"]), "model": str(prop["model"]),
            "pos": [center.x, center.y, center.z], "height": float(prop["height"]),
            "yaw": float(prop.get("yaw", 0)), "solid": false}
        if prop.has("inspect"):
            item["inspect"] = str(prop["inspect"])
            item["prompt"] = str(prop.get("prompt", "Inspect"))
        if ModelDress._place(owner, group, item):
            placed += 1
    for tier in 3:
        # This is near the wall, not in the central walking lane.  A real
        # emissive mesh and positional OmniLight react to interacting with it.
        var y := ybase + float(tier) * rise
        var station := Vector3(x0 + 4.5 * CELL + 1.90, y + 0.85,
            z0 + 2.5 * CELL + 1.90)
        state.add_marker(tier, station)
        owner.make_interactable(station, Vector3(1.5, 1.5, 1.5),
            str(recipe["station_prompts"][tier]), Callable(state, "activate_marker").bind(tier), group)
        owner.add_landmark("%s survey marker %d" % [owner.stable_id, tier + 1], station)
    state.set_marker_reports(recipe["station_reports"])
    # Real positional audio from existing AudioSynth recipes; discovery cues
    # are limited to a 2m vertical gate so they never fire across storeys.
    var ambient := AmbientDiscovery.new()
    ambient.name = "DEV21_Ambience_" + tag
    group.add_child(ambient)
    ambient.setup(owner, recipe["ambience"])
    return {"models": placed, "markers": 3, "inspectable_models": 3,
        "proximity_sound_cues": recipe["ambience"].size(),
        "theme": str(recipe["title"])}
