extends Node3D
## DEV22: mechanically meaningful district interaction state.
## Each floor's signal and ambient lights have independent physical energy.
## The optional gate is behind a four/five-signal investigation; its edge is
## explicitly NON-TREE, so the main route stays connected with the gate shut.
## No exits or teleportation are affected.

var level: LevelBase
var district_id := ""
var style := ""
var district_name := ""
var signals: Array = []
var signal_lights: Array = []
var signal_panels: Array = []
var ambient_lights: Array = []
var floor_brightness: Array = []
var signal_reports: Array = []
var observations: Array = []
var gate_body: StaticBody3D
var gate_shape: CollisionShape3D
var gate_visual: MeshInstance3D
var gate_position := Vector3.ZERO
var gate_open := false

func setup(owner: LevelBase, rec: Dictionary) -> void:
    level = owner
    district_id = str(rec["id"])
    district_name = str(rec["title"])
    style = str(rec["style"])
    signal_reports = rec["signals"].duplicate()
    observations = rec["observations"].duplicate()
    for _tier in int(rec["tiers"]):
        signals.append(false)
        signal_lights.append(null)
        signal_panels.append(null)
        ambient_lights.append(null)
        floor_brightness.append(false)

func _color() -> Color:
    match style:
        "keep_forge": return Color(0.39, 0.63, 1.0)
        "canopy": return Color(0.65, 0.87, 0.66)
        "highway": return Color(1.0, 0.70, 0.34)
        "red_keep": return Color(0.93, 0.31, 0.25)
        "fog_trail": return Color(0.79, 0.86, 0.94)
        "shelter": return Color(0.53, 0.95, 0.83)
        "toy_town": return Color(1.0, 0.67, 0.87)
        "roots": return Color(0.51, 0.87, 0.53)
        "attraction": return Color(1.0, 0.83, 0.35)
        "neon": return Color(0.89, 0.35, 1.0)
    return Color.WHITE

func add_signal(tier: int, pos: Vector3) -> void:
    var panel := MeshInstance3D.new()
    panel.name = "RouteSignal_%d" % tier
    var box := BoxMesh.new()
    box.size = Vector3(0.42, 0.62, 0.20)
    panel.mesh = box
    panel.position = pos
    panel.material_override = MatLib.panel(_color(), 0.06)
    add_child(panel)
    signal_panels[tier] = panel
    var light := OmniLight3D.new()
    light.name = "RouteSignalGlow_%d" % tier
    light.position = pos + Vector3.UP * 0.25
    light.light_color = _color()
    light.light_energy = 0.02
    light.omni_range = 10.0
    light.shadow_enabled = false
    add_child(light)
    signal_lights[tier] = light
    var ambient := OmniLight3D.new()
    ambient.name = "LocalEnvironmentalLight_%d" % tier
    ambient.position = pos + Vector3(16.0, 1.45, -0.7)
    ambient.light_color = _color()
    ambient.light_energy = 0.08
    ambient.omni_range = 12.0
    ambient.shadow_enabled = false
    add_child(ambient)
    ambient_lights[tier] = ambient

func activate_signal(_p: Player, tier: int) -> void:
    if signals[tier]:
        Overlay.subtitle("This landmark is already mapped; it still points toward the return route.", 2.5)
        return
    signals[tier] = true
    signal_lights[tier].light_energy = 2.0
    signal_panels[tier].material_override = MatLib.panel(_color(), 2.0)
    var count := 0
    for found in signals:
        if found:
            count += 1
    var note := str(signal_reports[tier])
    Overlay.subtitle("%s  [%d/%d elevations recorded]" % [note, count, signals.size()], 4.0)
    SaveService.record_discovery(level.stable_id,
        "dev22:%s:signal:%d" % [district_id, tier], note, "ADAPTATION")
    if count == signals.size():
        Overlay.subtitle("All elevation markers are visible. The optional return hatch can now be released.", 4.0)

func toggle_ambient(_p: Player, tier: int) -> void:
    floor_brightness[tier] = not floor_brightness[tier]
    ambient_lights[tier].light_energy = 2.4 if floor_brightness[tier] else 0.08
    var caption := "This floor's environmental illumination changes, revealing its connections." if floor_brightness[tier] else "The local glow recedes, but the route markers remain."
    Overlay.subtitle(caption, 3.0)
    SaveService.record_discovery(level.stable_id,
        "dev22:%s:light:%d" % [district_id, tier],
        "The environmental lights of this elevation can be controlled independently.", "ADAPTATION")

func investigate(_p: Player, index: int) -> void:
    var message := str(observations[index])
    Overlay.subtitle(message, 4.0)
    SaveService.record_discovery(level.stable_id,
        "dev22:%s:detail:%d" % [district_id, index], message, "ADAPTATION")

func configure_gate(pos: Vector3, size: Vector3, material: Material) -> void:
    gate_position = pos
    gate_body = StaticBody3D.new()
    gate_body.name = "OptionalReturnHatch"
    gate_body.position = pos
    add_child(gate_body)
    gate_shape = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    gate_shape.shape = shape
    gate_body.add_child(gate_shape)
    gate_visual = MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    gate_visual.mesh = mesh
    gate_visual.material_override = material
    gate_body.add_child(gate_visual)

func toggle_gate(_p: Player) -> void:
    if signals.has(false):
        Overlay.subtitle("The optional route hatch remains locked. Trace all elevations first.", 3.5)
        return
    if gate_open and level.player != null and level.player.global_position.distance_to(gate_position) < 3.0:
        Overlay.subtitle("Stand away from the hatch before closing it.", 2.5)
        return
    gate_open = not gate_open
    gate_shape.set_deferred("disabled", gate_open)
    gate_visual.visible = not gate_open
    Overlay.subtitle("A short return connection opens between two familiar rooms." if gate_open else "The return hatch closes; the main stair routes remain open.", 3.5)
    SaveService.record_discovery(level.stable_id,
        "dev22:%s:gate" % district_id,
        "An optional cross-connection was found after mapping every elevation.", "ADAPTATION")
