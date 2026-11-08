extends Node3D
## DEV25: interactive observation, real lighting and reversible physical bridge.
## Every state is parented to its LevelBase, and vanishes on level transition.
var level: LevelBase
var site: Dictionary = {}
var marks := [false,false,false]
var mark_lights: Array = []
var mark_panels: Array = []
var guide_lights: Array = []
var bridge_visual: MeshInstance3D
var bridge_shape: CollisionShape3D
var stop_rails: Array = []
var bridge_active := false
var bridge_mid := Vector3.ZERO
var ambient_cues: Array = []
var _ambient_poll := 0.0

func setup(owner: LevelBase, rec: Dictionary) -> void:
    level = owner
    site = rec
    mark_lights.resize(3)
    mark_panels.resize(3)

func _tint() -> Color:
    match str(site.get("style","")):
        "tar_pier": return Color(.95,.43,.19)
        "seafront": return Color(.47,.80,.89)
        "roadside": return Color(.98,.67,.31)
        "memorial": return Color(.67,.72,.84)
        "sunflower": return Color(.97,.84,.36)
        "vapor_temple": return Color(.34,1.0,.92)
    return Color.WHITE

func _solid_box(label: String, pos: Vector3, size: Vector3, material: Material) -> Dictionary:
    var body := StaticBody3D.new()
    body.name = label
    body.position=pos
    add_child(body)
    var shape := CollisionShape3D.new()
    var spec := BoxShape3D.new()
    spec.size=size
    shape.shape=spec
    body.add_child(shape)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size=size
    mesh.mesh=box
    mesh.material_override=material
    body.add_child(mesh)
    return {"body":body,"shape":shape,"mesh":mesh}

func add_survey(index: int, pos: Vector3) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name="DEV25_SignalPanel_%d"%index
    var box := BoxMesh.new()
    box.size=Vector3(.38,.65,.12)
    mesh.mesh=box
    mesh.material_override=MatLib.panel(_tint(),.12)
    mesh.position=pos
    add_child(mesh)
    mark_panels[index]=mesh
    var lamp := OmniLight3D.new()
    lamp.position=pos+Vector3(0,.4,0)
    lamp.omni_range=7.0
    lamp.light_color=_tint()
    lamp.light_energy=.05
    lamp.shadow_enabled=false
    add_child(lamp)
    mark_lights[index]=lamp

func add_light(pos: Vector3) -> void:
    var lamp := OmniLight3D.new()
    lamp.name="DEV25_GuideLight_%d"%guide_lights.size()
    lamp.position=pos
    lamp.omni_range=11.0
    lamp.light_energy=.16
    lamp.light_color=_tint()
    lamp.shadow_enabled=false
    add_child(lamp)
    guide_lights.append(lamp)

func configure_bridge(a: Vector3,b: Vector3, mat: Material, trim: Material) -> void:
    bridge_mid=(a+b)*.5
    var dir := (b-a).normalized()
    var along_x := absf(dir.x)>.5
    var length := Vector2(b.x-a.x,b.z-a.z).length()-8.0+.3
    var size := Vector3(length,.27,3.2) if along_x else Vector3(3.2,.27,length)
    var deck := _solid_box("DEV25_Optional_Physical_Deck",bridge_mid-Vector3(0,.135,0),size,mat)
    bridge_visual=deck["mesh"]
    bridge_shape=deck["shape"]
    bridge_visual.visible=false
    bridge_shape.disabled=true
    for side in [a,b]:
        var toward := dir if side==a else -dir
        var pos := side+toward*4.03+Vector3(0,.64,0)
        var rail_size := Vector3(.15,1.28,3.25) if along_x else Vector3(3.25,1.28,.15)
        stop_rails.append(_solid_box("DEV25_Closed_Gap_Rail",pos,rail_size,trim))

func _bridge_set(active: bool) -> void:
    bridge_active=active
    bridge_visual.visible=active
    bridge_shape.set_deferred("disabled",not active)
    for rail in stop_rails:
        (rail["mesh"] as MeshInstance3D).visible=not active
        (rail["shape"] as CollisionShape3D).set_deferred("disabled",active)

func _save(id: String, text: String) -> void:
    SaveService.record_discovery(str(site["id"]),"dev25:environment:"+id,text,"ADAPTATION")

func survey(_player: Player, index: int) -> void:
    if marks[index]:
        Overlay.subtitle("This detail is already in your exploration notes.",2.4)
        return
    marks[index]=true
    (mark_lights[index] as OmniLight3D).light_energy=1.35
    (mark_panels[index] as MeshInstance3D).material_override=MatLib.panel(_tint(),1.4)
    var total := 0
    for value in marks:
        if value: total+=1
    _save("marker_%d"%index,str(site["message"]))
    Overlay.subtitle("%s — %d of 3 observations"%[str(site["title"]),total],3.0)
    if level!=null and level.sound!=null:
        level.sound.play_at(str(site["cue"]),{},mark_lights[index].global_position,-36.0)
    if total==3:
        _bridge_set(true)
        _save("return_crossing","An optional return loop opens; the original routes remain available.")
        Overlay.subtitle("A secondary crossing opens. Both original routes remain available.",3.4)

func switch_light(_player: Player,index: int) -> void:
    var lamp: OmniLight3D=guide_lights[index]
    lamp.light_energy=1.35 if lamp.light_energy<.5 else .10
    Overlay.subtitle("The path lighting changes, revealing the edge of the walkway.",2.7)

func operate_bridge(_player: Player) -> void:
    if marks.has(false):
        Overlay.subtitle("Three different observations are needed before this crossing operates.",3.2)
        return
    if bridge_active and level!=null and level.player!=null:
        var pos := level.player.global_position
        if absf(pos.y-bridge_mid.y)<2.0 and pos.distance_to(bridge_mid)<8.5:
            Overlay.subtitle("Leave the bridge before retracting it.",2.8)
            return
    _bridge_set(not bridge_active)
    Overlay.subtitle("The alternative walkway opens." if bridge_active else "The safety rail closes the walkway.",2.8)

func add_ambient_cue(at: Vector3, caption: String) -> void:
    ambient_cues.append({"pos":at,"caption":caption,"played":false})

func _process(delta: float) -> void:
    if level==null or level.player==null or SessionState.is_qa():
        return
    _ambient_poll-=delta
    if _ambient_poll>0.0:
        return
    _ambient_poll=.65
    var p := level.player.global_position
    for index in range(ambient_cues.size()):
        var cue: Dictionary = ambient_cues[index]
        if cue["played"]:
            continue
        var at: Vector3 = cue["pos"]
        if absf(at.y-p.y)<2.2 and Vector2(at.x-p.x,at.z-p.z).length()<6.0:
            cue["played"]=true
            level.sound.play_at(str(site["cue"]),{},at,-38.0)
            Overlay.subtitle(str(cue["caption"]),3.0)
