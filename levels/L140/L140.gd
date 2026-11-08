extends LevelBase
const ImmersiveNetworks := preload("res://core/world/ImmersiveNetworks.gd")
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
## Honey: field, sunflowers, small house, and changing day. No invented exits.
var _flower_count := 480
var _time_of_day := 15.0
var _sunflower_heads: MultiMeshInstance3D
var _sunflower_stems: MultiMeshInstance3D

func build() -> void:
    rules["view_distance"] = 900.0
    outdoor_env(Color(0.38, 0.60, 0.80), Color(0.97, 0.70, 0.47), Color(0.35, 0.40, 0.16), Vector2(24, -25), Color(1.0, 0.80, 0.58), 1.3, Color(0.68, 0.57, 0.44), 0.002)
    MatLib.define("l140_grass", {"albedo_a": Color(0.36, 0.46, 0.18), "albedo_b": Color(0.45, 0.52, 0.20)}, "grass")
    MatLib.define("l140_stem", {"albedo_a": Color(0.20, 0.38, 0.12), "albedo_b": Color(0.24, 0.36, 0.10)}, "grass")
    MatLib.register("l140_flower", MatLib.panel(Color(1.0, 0.79, 0.13), 0.4))
    MatLib.define("l140_house", {"albedo_a": Color(0.65, 0.57, 0.40), "albedo_b": Color(0.75, 0.67, 0.54)}, "wood_floor")
    lights.setup(3, 0)
    _field()
    _sunflowers()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "SunflowerObservationMaze", Vector3(100, 0, 83), 4, 3.5, "l140_house", "l140_stem", false)
    # DEV25: wiki-aware, optional traversable annex; original exits unchanged.
    ImmersiveNetworks.install(self)
    add_arrival("start", Vector3(-22, 0.08, 0), 90)
    add_arrival("from_L019", Vector3(-22, 0.08, 0), 90)
    add_arrival("from_L149", Vector3(-22, 0.08, 0), 90)
    add_landmark("Lobby stocked with honey bottles", Vector3(-22, 0, 0))
    add_landmark("The first sunflower field", Vector3(18, 0, 20))
    add_shot("honey_lobby", Vector3(-23, 1.62, -12), Vector3(15, 1.0, 10))
    add_shot("flowers_at_sunset", Vector3(6, 1.62, 6), Vector3(65, 2.0, 0))
    sound.bed("wind", {"seconds": 7.0}, -31.0)
    sound.bed("crickets", {"seconds": 7.0}, -37.0)

func _field() -> void:
    var k := kit("HoneySunflowerField")
    k.slab(-260, -260, 260, 260, 0, 0.45, "l140_grass")
    # A modest residence / lobby, explicitly presented as testimony.
    k.slab(-40, -19, -17, 18, 0.04, 0.3, "l140_house")
    for z in [-18.9, 17.9]:
        k.box(Vector3(-28.5, 2.4, z), Vector3(23, 4.8, 0.3), "l140_house")
    for x in [-40.0, -17.0]:
        k.box(Vector3(x, 2.4, -8), Vector3(0.3, 4.8, 22), "l140_house")
    k.box(Vector3(-28, 4.8, -1), Vector3(25.0, 0.3, 38.0), "l140_house")
    for i in 12:
        var x := -38.0 + float(i % 4) * 5.0
        var z := -14.0 + float(int(i / 4)) * 5.0
        k.box(Vector3(x, 0.6, z), Vector3(1.0, 1.2, 1.0), "l140_house")
        k.box(Vector3(x, 1.5, z), Vector3(0.4, 0.5, 0.4), "l140_flower", GeoKit.ALL, false)
    k.commit()
    add_note("letters", "A NOTE LEFT IN THE LOBBY", "The field looks endless from the windows. The bees return at dusk. No one knows whether these letters arrived.", Vector3(-26, 0.85, -10))

func _sunflowers() -> void:
    # Two MultiMeshes; hundreds of blooms at negligible scene-tree/collision cost.
    var stem_mesh := CylinderMesh.new()
    stem_mesh.top_radius = 0.045
    stem_mesh.bottom_radius = 0.075
    stem_mesh.height = 2.0
    stem_mesh.radial_segments = 5
    stem_mesh.material = MatLib.get_mat("l140_stem")
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.45
    head_mesh.height = 0.18
    head_mesh.radial_segments = 8
    head_mesh.rings = 3
    head_mesh.material = MatLib.get_mat("l140_flower")
    var stems := MultiMesh.new()
    var heads := MultiMesh.new()
    stems.transform_format = MultiMesh.TRANSFORM_3D
    heads.transform_format = MultiMesh.TRANSFORM_3D
    stems.mesh = stem_mesh
    heads.mesh = head_mesh
    stems.instance_count = _flower_count
    heads.instance_count = _flower_count
    for i in _flower_count:
        var x := rng.randf_range(3.0, 234.0)
        var z := rng.randf_range(-230.0, 230.0)
        # Keep 480 stems, but avoid intersecting the accessible tiered pavilion.
        # DEV27: preserve the original flower count while rerolling positions
        # away from the new optional pergola and its two stair approaches.
        while (absf(x-100.0) < 21.0 and absf(z-83.0) < 28.0) or (absf(x-130.0) < 33.0 and absf(z+130.0) < 43.0):
            x = rng.randf_range(3.0, 234.0)
            z = rng.randf_range(-230.0, 230.0)
        var height := rng.randf_range(1.3, 2.5)
        stems.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, height / 2.0, 1)), Vector3(x, height * 0.5, z)))
        heads.set_instance_transform(i, Transform3D(Basis(), Vector3(x, height, z)))
    _sunflower_stems = MultiMeshInstance3D.new()
    _sunflower_stems.multimesh = stems
    _sunflower_stems.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_sunflower_stems)
    _sunflower_heads = MultiMeshInstance3D.new()
    _sunflower_heads.multimesh = heads
    _sunflower_heads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_sunflower_heads)

func level_process(delta: float) -> void:
    if SessionState.is_qa():
        return
    _time_of_day = fmod(_time_of_day + delta / 150.0, 24.0)
    var elevation := sin((_time_of_day - 6.0) * PI / 12.0)
    sun.rotation_degrees.x = -maxf(3.0, 72.0 * elevation)
    sun.light_energy = maxf(0.02, elevation * 1.2)
    environment.ambient_light_energy = 0.1 + 0.5 * maxf(0.0, elevation)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"480 flower stems", "ok":_sunflower_stems != null and _sunflower_stems.multimesh.instance_count == 480}, {"what":"no fabricated exits", "ok":exits.is_empty()}, {"what":"arrival from Level 19", "ok":arrivals.has("from_L019")}]
