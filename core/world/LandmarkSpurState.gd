extends Node3D
## DEV23: three independent survey beacons, real 3D lights, one optional
## physical cross-gallery (not an exit or required progress route).
## The two ascents remain accessible when the bridge is OFF.

var level: LevelBase
var sid := ""
var title := ""
var discovery := ""
var ambient_sound := ""
var style := ""
var marked := [false, false, false]
var lights: Array = []
var panels: Array = []
var bridge_body: StaticBody3D
var bridge_collision: CollisionShape3D
var bridge_mesh: MeshInstance3D
var bridge_center := Vector3.ZERO
var bridge_live := false

func setup(owner: LevelBase, rec: Dictionary) -> void:
    level = owner
    sid = str(rec["id"])
    title = str(rec["title"])
    discovery = str(rec["discovery"])
    ambient_sound = str(rec["sound"])
    style = str(rec["style"])
    lights.resize(3)
    panels.resize(3)

func _glow() -> Color:
    match style:
        "keep_forge": return Color(0.43,0.65,1.0)
        "canopy": return Color(0.79,0.86,0.62)
        "highway": return Color(1.0,0.74,0.31)
        "red_keep": return Color(0.95,0.28,0.31)
        "fog_trail": return Color(0.71,0.81,0.95)
        "shelter": return Color(0.66,0.96,0.86)
        "toy_town": return Color(0.99,0.58,0.84)
        "roots": return Color(0.51,0.90,0.59)
        "attraction": return Color(1.0,0.84,0.30)
        "neon": return Color(0.84,0.31,1.0)
    return Color.WHITE

func add_beacon(at: Vector3, number: int) -> void:
    assert(number >= 0 and number < 3 and lights[number] == null)
    var mesh := MeshInstance3D.new()
    mesh.name = "SurveyPanel_%d" % number
    var primitive := BoxMesh.new()
    primitive.size = Vector3(0.46,0.72,0.18)
    mesh.mesh = primitive
    mesh.position = at
    mesh.material_override = MatLib.panel(_glow(),0.11)
    add_child(mesh)
    panels[number] = mesh
    var lamp := OmniLight3D.new()
    lamp.name = "SurveyLamp_%d" % number
    lamp.position = at + Vector3(0.0,0.26,0.0)
    lamp.light_color = _glow()
    lamp.light_energy = 0.08
    lamp.omni_range = 11.0
    lamp.shadow_enabled = false
    add_child(lamp)
    lights[number] = lamp

func configure_bridge(at: Vector3, size: Vector3, mat: Material) -> void:
    bridge_center = at
    bridge_body = StaticBody3D.new()
    bridge_body.name = "OptionalCrossGalleryPhysics"
    bridge_body.position = at
    add_child(bridge_body)
    bridge_collision = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    bridge_collision.shape = shape
    bridge_collision.disabled = true
    bridge_body.add_child(bridge_collision)
    bridge_mesh = MeshInstance3D.new()
    bridge_mesh.name = "OptionalCrossGalleryVisible"
    var box := BoxMesh.new()
    box.size = size
    bridge_mesh.mesh = box
    bridge_mesh.material_override = mat
    bridge_mesh.visible = false
    bridge_body.add_child(bridge_mesh)

func _enable_bridge(active: bool) -> void:
    bridge_live = active
    bridge_collision.set_deferred("disabled",not active)
    bridge_mesh.visible = active

func activate(_p: Player, number: int) -> void:
    if marked[number]:
        Overlay.subtitle("This survey marker is already recorded. The path remains visible.",2.6)
        return
    marked[number] = true
    lights[number].light_energy = 2.2
    panels[number].material_override = MatLib.panel(_glow(),2.0)
    var count := 0
    for found in marked:
        if found:
            count += 1
    Overlay.subtitle("%s: route marker %d/3 mapped." % [title,count],3.2)
    SaveService.record_discovery(sid,"dev23:spur:marker:%d"%number,
        "%s — survey point %d"%[title,number+1],"ADAPTATION")
    if ambient_sound != "" and level != null:
        level.sound.play_at(ambient_sound,{},lights[number].position,-20.0)
    if not marked.has(false):
        _enable_bridge(true)
        Overlay.subtitle("A cross-gallery becomes solid. Both separate stairs are still usable.",4.0)
        SaveService.record_discovery(sid,"dev23:spur:bridge",discovery,"ADAPTATION")

func toggle_bridge(_p: Player) -> void:
    if marked.has(false):
        Overlay.subtitle("Survey the lower court and both upper galleries before operating this crossing.",3.4)
        return
    if bridge_live and level != null and level.player != null:
        var p: Vector3 = level.player.global_position
        if absf(p.y-bridge_center.y)<2.0 and p.distance_to(bridge_center)<10.0:
            Overlay.subtitle("Crossing occupied. Move away before retracting it.",2.9)
            return
    _enable_bridge(not bridge_live)
    Overlay.subtitle("The optional upper crossing extends." if bridge_live else "The crossing retracts; both stair routes remain open.",3.1)

func inspect_lower(_p: Player) -> void:
    Overlay.subtitle(discovery,4.0)
    SaveService.record_discovery(sid,"dev23:spur:lower",discovery,"ADAPTATION")
