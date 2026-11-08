extends Node3D
## DEV24: observed signals enable an OPTIONAL bridge, not a canonical exit.
## When retracted, physical rails seal its endpoints. Dynamic collision and
## visual meshes change together. This state belongs to its level and is freed
## on level unload. No timers or global persistent runtime nodes are added.

var owner_level: LevelBase
var rec: Dictionary = {}
var surveyed := [false,false,false]
var panels: Array = []
var lamps: Array = []
var ambient_lamps: Array = []
var bridge: StaticBody3D
var floor_shape: CollisionShape3D
var floor_mesh: MeshInstance3D
var barriers: Array = []
var bridge_active := false
var bridge_center := Vector3.ZERO

func setup(level: LevelBase, record: Dictionary) -> void:
    owner_level = level
    rec = record
    panels.resize(3)
    lamps.resize(3)

func _color() -> Color:
    match str(rec.get("style", "")):
        "keep_forge": return Color(.39,.65,1.0)
        "canopy": return Color(.87,.83,.64)
        "highway": return Color(1.0,.77,.38)
        "red_keep": return Color(1.0,.25,.31)
        "fog_trail": return Color(.66,.82,.92)
        "shelter": return Color(.51,.95,.76)
        "toy_town": return Color(1.0,.54,.85)
        "roots": return Color(.46,.82,.58)
        "attraction": return Color(1.0,.85,.39)
        "neon": return Color(.91,.33,1.0)
    return Color.WHITE

func _physical_box(name: String, p: Vector3, size: Vector3, mat: Material) -> Dictionary:
    var body := StaticBody3D.new()
    body.name = name
    body.position = p
    add_child(body)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    body.add_child(collider)
    var mesh := MeshInstance3D.new()
    var model := BoxMesh.new()
    model.size = size
    mesh.mesh = model
    mesh.material_override = mat
    body.add_child(mesh)
    return {"body":body,"shape":collider,"mesh":mesh}

func add_survey(at: Vector3, idx: int) -> void:
    assert(idx>=0 and idx<3)
    var mesh := MeshInstance3D.new()
    mesh.name = "ExpeditionSurveyPanel_%d" % idx
    var box := BoxMesh.new()
    box.size = Vector3(.35,.62,.13)
    mesh.mesh = box
    mesh.position = at
    mesh.material_override = MatLib.panel(_color(),.11)
    add_child(mesh)
    panels[idx] = mesh
    var lamp := OmniLight3D.new()
    lamp.name = "ExpeditionSurveyLight_%d" % idx
    lamp.position = at+Vector3(0,.4,0)
    lamp.light_color = _color()
    lamp.light_energy = .08
    lamp.omni_range = 7.5
    lamp.shadow_enabled = false
    add_child(lamp)
    lamps[idx] = lamp

func add_local_light(at: Vector3) -> int:
    var lamp := OmniLight3D.new()
    lamp.name = "ExpeditionSwitchableLight_%d" % ambient_lamps.size()
    lamp.position = at
    lamp.light_color = _color()
    lamp.light_energy = .12
    lamp.omni_range = 12.0
    lamp.shadow_enabled = false
    add_child(lamp)
    ambient_lamps.append(lamp)
    return ambient_lamps.size()-1

func configure_optional(pa: Vector3, pb: Vector3, mat: Material, accent: Material) -> void:
    bridge_center = (pa+pb)*.5
    var along_x := absf(pa.x-pb.x)>1.0
    var floor_size := Vector3(14.0,.28,3.0) if along_x else Vector3(3.0,.28,14.0)
    var floor := _physical_box("ExpeditionOptionalPhysicalDeck",bridge_center-Vector3(0,.14,0),floor_size,mat)
    bridge = floor["body"]
    floor_shape = floor["shape"]
    floor_mesh = floor["mesh"]
    floor_shape.disabled = true
    floor_mesh.visible = false
    # A closed handrail prevents the player stepping into the 4m gap.
    for endpoint in [pa,pb]:
        var inward: Vector3 = pb-pa if endpoint==pa else pa-pb
        inward = inward.normalized()
        var at := endpoint + inward*4.95 + Vector3.UP*.58
        var size := Vector3(.15,1.16,3.2) if along_x else Vector3(3.2,1.16,.15)
        barriers.append(_physical_box("ExpeditionRetractableSafetyRail",at,size,accent))
    bridge_active = false

func _set_bridge(value: bool) -> void:
    bridge_active = value
    floor_mesh.visible = value
    floor_shape.set_deferred("disabled",not value)
    for barrier in barriers:
        (barrier["mesh"] as MeshInstance3D).visible = not value
        (barrier["shape"] as CollisionShape3D).set_deferred("disabled",value)

func _record(label: String, note: String) -> void:
    SaveService.record_discovery(str(rec["id"]),"dev24:expedition:"+label,note,"ADAPTATION")

func survey(_player: Player, idx: int) -> void:
    if surveyed[idx]:
        Overlay.subtitle("This expedition marker is already mapped.",2.6)
        return
    surveyed[idx] = true
    (lamps[idx] as OmniLight3D).light_energy = 1.8
    (panels[idx] as MeshInstance3D).material_override = MatLib.panel(_color(),2.1)
    var count := 0
    for hit in surveyed:
        if hit: count+=1
    _record("survey:%d"%idx,"%s — marker %d"%[str(rec["title"]),idx+1])
    Overlay.subtitle("%s: %d of 3 landmarks mapped."%[str(rec["title"]),count],3.0)
    if str(rec.get("sound",""))!="" and owner_level!=null:
        owner_level.sound.play_at(str(rec["sound"]),{},lamps[idx].position,-23.0)
    if count==3:
        _set_bridge(true)
        _record("bridge",str(rec["observation"]))
        Overlay.subtitle("An optional crossing extends; the original paths remain open.",4.0)

func operate_bridge(_player: Player) -> void:
    if surveyed.has(false):
        Overlay.subtitle("Find the three observation markers to power the crossing.",3.0)
        return
    if bridge_active and owner_level!=null and owner_level.player!=null:
        var p := owner_level.player.global_position
        if absf(p.y-bridge_center.y)<1.8 and p.distance_to(bridge_center)<9.0:
            Overlay.subtitle("Crossing occupied. Stand clear before retracting.",3.0)
            return
    _set_bridge(not bridge_active)
    Overlay.subtitle("Crossing extended." if bridge_active else "Crossing retracted; the safety rails return.",2.6)

func toggle_light(_player: Player, idx: int) -> void:
    var lamp: OmniLight3D = ambient_lamps[idx]
    var bright := lamp.light_energy < .5
    lamp.light_energy = 1.9 if bright else .12
    Overlay.subtitle("The local illumination strengthens." if bright else "The local illumination fades.",2.8)

func inspect(_player: Player) -> void:
    var message := str(rec["observation"])
    Overlay.subtitle(message,4.0)
    _record("observation",message)
