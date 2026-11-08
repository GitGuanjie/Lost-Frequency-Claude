extends Node3D
## Player-visible state changes for a single DEV20 generated annex.
## No level exits, progression keys, teleports or fabricated canonical lore.

var level: LevelBase
var tag: String = ""
var theme: String = ""
var lamps: Array = [[], [], []]
var circuit_on := [false, false, false]
var shutter_body: StaticBody3D
var shutter_shape: CollisionShape3D
var shutter_visual: MeshInstance3D
var shutter_pos := Vector3.ZERO
var shutter_open := false

func setup(owner: LevelBase, wing_tag: String, wing_theme: String) -> void:
    level = owner
    tag = wing_tag
    theme = wing_theme

func add_lamp(tier: int, pos: Vector3, shade: Color) -> void:
    var light := OmniLight3D.new()
    light.name = "Tier%d_Lamp%d" % [tier, lamps[tier].size()]
    light.position = pos
    light.light_color = shade
    light.light_energy = 0.14
    light.omni_range = 9.0
    light.shadow_enabled = false
    add_child(light)
    lamps[tier].append(light)

func toggle_circuit(_p: Player, tier: int) -> void:
    circuit_on[tier] = not circuit_on[tier]
    for lamp in lamps[tier]:
        lamp.light_energy = 1.4 if circuit_on[tier] else 0.14
    var lit_message := "Some passages become visible in the strange glow." if theme in ["forest", "garden"] else "A different route becomes visible in the light."
    var dark_message := "The glow recedes into the foliage." if theme in ["forest", "garden"] else "The corridor falls back into dimness."
    Overlay.subtitle(lit_message if circuit_on[tier] else dark_message, 3.0)
    var finding := "An intermittent natural glow alters the route markers." if theme in ["forest", "garden"] else "An old lighting circuit changes how the passages read."
    SaveService.record_discovery(level.stable_id, "dev20:" + tag + ":circuit:%d" % tier,
        finding, "ADAPTATION")

func configure_shutter(pos: Vector3, size: Vector3, material: Material) -> void:
    shutter_pos = pos
    shutter_body = StaticBody3D.new()
    shutter_body.name = "OptionalShortcutGate"
    shutter_body.position = pos
    add_child(shutter_body)
    shutter_shape = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    shutter_shape.shape = shape
    shutter_body.add_child(shutter_shape)
    shutter_visual = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    shutter_visual.mesh = mesh
    shutter_visual.material_override = material
    shutter_body.add_child(shutter_visual)

func toggle_shutter(_p: Player) -> void:
    if shutter_open and level.player != null and level.player.global_position.distance_to(shutter_pos) < 2.7:
        Overlay.subtitle("Move away from the gate before closing it.", 2.5)
        return
    shutter_open = not shutter_open
    shutter_shape.set_deferred("disabled", shutter_open)
    shutter_visual.visible = not shutter_open
    var movable := "A hanging root screen shifts away." if theme in ["forest", "garden"] else "A short route is now open."
    Overlay.subtitle(movable if shutter_open else "The side passage closes again.", 3.0)
    SaveService.record_discovery(level.stable_id, "dev20:" + tag + ":shutter",
        "A movable obstruction concealed a secondary loop; the main route remained open.", "ADAPTATION")

func observe(_p: Player, tier: int) -> void:
    var descriptions := [
        "The lower corridor returns beneath the structure, but its proportions disagree with the view above.",
        "Several passages loop around an inaccessible-looking central void.",
        "A second route leads back to the same viewpoint from a different height."
    ]
    if theme in ["forest", "garden"]:
        descriptions = [
            "Branches form a sheltered path underneath a canopy that never stops rustling.",
            "The walkway doubles back through trunks that appear identical from above.",
            "The upper trail overlooks a route that seemed to lead away from here."
        ]
    elif theme == "desert":
        descriptions = [
            "A deserted service track vanishes behind the roadside structure.",
            "The raised path is clear, but the road below seems unchanged.",
            "Rusty panels frame an uninterrupted expanse of empty land."
        ]
    elif theme == "leisure":
        descriptions = [
            "A silent attraction blocks the lower path, but there is room to go around.",
            "From above, the disused park forms an unexpectedly regular maze.",
            "A higher terrace looks onto the rides without making them move."
        ]
    elif theme == "ruin":
        descriptions = [
            "Stone supports keep a lower corridor just visible through the gaps.",
            "The atrium seems far deeper than it did from the entrance.",
            "A second stone passage returns toward the same ancient silhouette."
        ]
    Overlay.subtitle(descriptions[tier], 4.5)
    SaveService.record_discovery(level.stable_id, "dev20:" + tag + ":observation:%d" % tier,
        descriptions[tier], "ADAPTATION")


# DEV21 exploration markers. Three independent stateful visual beacons, one per
# floor. They illuminate an orientation route after actual interaction; they
# do not invent exits or force a story or combat objective.
var marker_found := [false, false, false]
var marker_lights: Array = [null, null, null]
var marker_visuals: Array = [null, null, null]
var marker_reports: Array = []

func set_marker_reports(lines: Array) -> void:
    marker_reports = lines.duplicate()

func _marker_color() -> Color:
    if theme in ["forest", "garden"]:
        return Color(0.49, 0.90, 0.64)
    if theme == "ruin":
        return Color(0.48, 0.64, 0.96)
    if theme == "desert":
        return Color(1.0, 0.67, 0.29)
    if theme == "surreal":
        return Color(0.89, 0.33, 1.0)
    if theme == "leisure":
        return Color(1.0, 0.71, 0.46)
    return Color(0.87, 0.89, 1.0)

func add_marker(tier: int, pos: Vector3) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = "Dev21SurveyMarker_%d" % tier
    var shape := BoxMesh.new()
    shape.size = Vector3(0.48, 0.80, 0.27)
    mesh.mesh = shape
    mesh.position = pos
    mesh.material_override = MatLib.panel(_marker_color(), 0.08)
    add_child(mesh)
    marker_visuals[tier] = mesh
    var light := OmniLight3D.new()
    light.name = "Dev21MarkerLight_%d" % tier
    light.position = pos + Vector3(0, 0.45, 0)
    light.light_color = _marker_color()
    light.light_energy = 0.02
    light.omni_range = 12.0
    light.shadow_enabled = false
    add_child(light)
    marker_lights[tier] = light

func activate_marker(_p: Player, tier: int) -> void:
    if marker_found[tier]:
        Overlay.subtitle("This marker is still glowing. The route has not changed.", 2.5)
        return
    marker_found[tier] = true
    marker_lights[tier].light_energy = 2.0
    marker_visuals[tier].material_override = MatLib.panel(_marker_color(), 2.5)
    var text_line := str(marker_reports[tier]) if tier < marker_reports.size() else "A second route becomes easier to recognize."
    var count := 0
    for found in marker_found:
        if found:
            count += 1
    Overlay.subtitle(text_line + "  [%d/3 markers observed]" % count, 4.0)
    SaveService.record_discovery(level.stable_id, "dev21:" + tag + ":marker:%d" % tier,
        text_line, "ADAPTATION")
    if count == 3:
        Overlay.subtitle("The three lights reveal an alternative way back through the structure.", 4.0)
        SaveService.record_discovery(level.stable_id, "dev21:" + tag + ":all_markers",
            "All three elevations of this side structure have been investigated.", "ADAPTATION")
