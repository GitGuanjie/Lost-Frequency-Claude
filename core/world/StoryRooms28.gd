extends Node3D
## DEV28: theme-specific investigations in nine pre-existing environments.
## Source-authored text and GLB instances are decorative, not a route gate.
## Interaction has three different consequences: one-time journal evidence,
## a repeatable real-light switch, and directional positional acoustics.
## This node is owned by the level and has no exit or arrival controls.
const Dress = preload("res://core/world/ModelDress.gd")
const Ambient = preload("res://core/world/AmbientDiscovery.gd")
var level: LevelBase
var site: Dictionary = {}
var found: Dictionary = {}
var lamps: Array = []
var panels: Array = []
var sounds: Array = []
var actual_props := 0

static func _v(a: Array) -> Vector3:
    return Vector3(float(a[0]),float(a[1]),float(a[2]))

func setup(owner: LevelBase, record: Dictionary) -> void:
    level = owner
    site = record
    var tint_array: Array = site["tint"]
    var tint := Color(float(tint_array[0]),float(tint_array[1]),float(tint_array[2]))
    var ambient: Array = []
    var cues: Array = site["cues"]
    for i in cues.size():
        var cue: Dictionary = cues[i]
        var pos := _v(cue["pos"])
        var panel := MeshInstance3D.new()
        panel.name = "DEV28_StoryIndicator_%02d" % i
        var mesh := BoxMesh.new()
        mesh.size = Vector3(.28,.37,.10)
        panel.mesh = mesh
        panel.position = pos + Vector3(0,1.35,0)
        panel.material_override = MatLib.panel(tint,.08)
        panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(panel)
        panels.append(panel)
        var lamp := OmniLight3D.new()
        lamp.name = "DEV28_StoryLamp_%02d" % i
        lamp.position = pos + Vector3(0,1.9,0)
        lamp.light_color = tint
        lamp.light_energy = .07
        lamp.omni_range = 7.0
        lamp.shadow_enabled = false
        add_child(lamp)
        lamps.append(lamp)
        for prop in cue.get("props", []):
            if Dress._place(owner,self,prop):
                actual_props += 1
        # Make the interaction part of the same node's lifecycle as its props.
        var hit := owner.make_interactable(pos+Vector3(0,1,0),Vector3(1.8,2.0,2.0),
            str(cue["prompt"]),Callable(self,"investigate").bind(i),self)
        if hit == null:
            push_warning("DEV28 story interaction missing for %s" % str(cue["id"]))
        # A distant audio cue can be encountered independently of inspection.
        # It is height-gated and QA-inert by AmbientDiscovery.
        ambient.append({"id":"dev28:approach:%s" % str(cue["id"]),
            "pos":[pos.x,pos.y+1,pos.z],"height":2.4,"radius":4.2,
            "caption":"[a detail of this place draws your attention]",
            "sound":str(site["sound"]),"source":"ADAPTATION"})
    var listener := Ambient.new()
    listener.name = "DEV28_HeightGatedAtmosphere"
    add_child(listener)
    listener.setup(owner,ambient)
    owner.add_landmark(str(site["title"]),_v(cues[0]["pos"])+Vector3.UP)

func investigate(_player: Player,index: int) -> void:
    var cue: Dictionary = site["cues"][index]
    var key := str(cue["id"])
    var kind := str(cue["kind"])
    var light := lamps[index] as OmniLight3D
    if kind == "switch":
        # Switches change the world on each press; not just UI text.
        light.light_energy = 1.65 if light.light_energy < .5 else .07
        var enabled := light.light_energy > .5
        var raw: Array = site["tint"]
        var tint := Color(float(raw[0]),float(raw[1]),float(raw[2]))
        (panels[index] as MeshInstance3D).material_override = MatLib.panel(tint,1.6 if enabled else .08)
        Overlay.subtitle(str(cue["description"]),3.4)
    elif kind == "listen":
        light.light_energy = .58
        Overlay.subtitle(str(cue["description"]),4.0)
        if not SessionState.is_qa():
            level.sound.play_at(str(site["sound"]),{},_v(cue["pos"])+Vector3.UP,-23.0)
    else:
        light.light_energy = .85
        Overlay.subtitle(str(cue["description"]),4.2)
    if not found.has(key):
        found[key]=true
        SaveService.record_discovery(level.stable_id,"dev28:"+key,
            str(cue["description"]),"ADAPTATION")
        if found.size()==(site["cues"] as Array).size():
            SaveService.record_discovery(level.stable_id,"dev28:all_"+level.stable_id,
                "A complete set of local environmental observations was recorded.","ADAPTATION")

func inspected_count() -> int:
    return found.size()
