extends RefCounted
## DEV23 physically traversable landmark expeditions, derived from DEV22
## layout data. One continuous ground walk, two INDEPENDENT 21m ascents,
## two upper galleries, an optional crossbridge and six themed lower courts.
## The existing GLB library is used for off-route environmental dressing.
## This module never creates a level exit. Godot physics QA is still required.

const DATA := "res://data/dev23_landmark_spurs.json"
const SpurState = preload("res://core/world/LandmarkSpurState.gd")
const Dress = preload("res://core/world/ModelDress.gd")
const Ambient = preload("res://core/world/AmbientDiscovery.gd")
const Expeditions = preload("res://core/world/ExpeditionBiomes.gd")

static func _bar(k: GeoKit, at: Vector3, size: Vector3, accent: String) -> void:
    k.box(at,size,accent)

static func _upper_rails(k: GeoKit, at: Vector3, accent: String, open_air: bool) -> void:
    # Each gallery is 12x12; its inner (facing the cross-bridge) side is split
    # to preserve a 4.0m real doorway. Both galleries have independent stairs.
    var sign := 1.0 if at.x > 0.0 else -1.0
    # The inner side is assigned relative to the common spur centre by caller.
    # North/south edges are clear from prop placement and protect drops.
    for zz in [-6.06,6.06]:
        _bar(k,at+Vector3(0,0.59,zz),Vector3(12.1,1.18,0.13),accent)
    # Inner and outer side rails are emitted in install() so bridge portals align.

static func _architecture(k: GeoKit, c: Vector3, style: String, mat: String, accent: String, upper: bool, hub: bool = false) -> int:
    # Ten genuinely different silhouettes. The court's north edge must remain
    # completely clear for BOTH stair feet at x=+/-4.5, z=-5 relative to court.
    var n := 0
    if hub:
        # Signature details on the SOUTH half, safely away from the dual ascents.
        # These are REAL beams/pillars in the level's own material palette.
        var pillar_radius := .19 if style in ["canopy","roots","fog_trail"] else .28
        var post_height := 3.4 if style in ["red_keep","keep_forge","shelter"] else 2.9
        for sign in [-1.0,1.0]:
            k.cylinder(c+Vector3(float(sign)*5.45,post_height*.5,2.2),
                pillar_radius,post_height,accent,6 if pillar_radius<.2 else 8)
            n += 1
        if style in ["keep_forge","shelter","highway","attraction","neon"]:
            k.box(c+Vector3(0,post_height+.12,2.2),
                Vector3(10.9,.20,.28),mat,GeoKit.ALL,false)
            n += 1
        return n
    match style:
        "keep_forge":
            k.arch_wall(c+Vector3(-5.55,0,-5.65),c+Vector3(5.55,0,-5.65),3.75,0.35,
                accent,[{"at":5.55,"w":3.4,"spring":2.05}]); n+=1
            for s in [-1.0,1.0]:
                k.cylinder(c+Vector3(float(s)*5.15,2.1,4.6),0.42,4.2,mat,8); n+=1
        "canopy":
            for s in [-1.0,1.0]:
                k.cylinder(c+Vector3(float(s)*5.32,2.3,-4.80),0.43,4.6,mat,7)
                k.box(c+Vector3(float(s)*3.75,4.28,-4.8),Vector3(3.1,0.20,0.34),accent,GeoKit.ALL,false);n+=2
        "highway":
            for s in [-1.0,1.0]:
                k.box(c+Vector3(float(s)*5.12,2.15,-4.95),Vector3(.25,4.3,.25),accent);n+=1
            k.box(c+Vector3(0,4.28,-4.95),Vector3(10.4,.36,.25),mat);n+=1
        "red_keep":
            for s in [-1.0,1.0]:
                k.box(c+Vector3(float(s)*4.9,1.18,-5.45),Vector3(1.0,2.36,1.0),mat)
                k.box(c+Vector3(float(s)*4.9,2.53,-5.45),Vector3(1.25,.37,1.25),accent);n+=2
            k.box(c+Vector3(0,3.04,-5.50),Vector3(9.2,.28,.26),accent,GeoKit.ALL,false);n+=1
        "fog_trail":
            for s in [-1.0,1.0]:
                k.cylinder(c+Vector3(float(s)*5.18,1.45,-4.6),.19,2.9,accent,6)
                k.box(c+Vector3(float(s)*4.7,2.70,-4.6),Vector3(.96,.19,.25),mat,GeoKit.ALL,false);n+=2
        "shelter":
            for s in [-1.0,1.0]:
                k.box(c+Vector3(float(s)*5.10,1.82,-4.8),Vector3(.28,3.64,.28),accent);n+=1
            k.box(c+Vector3(0,3.66,-4.8),Vector3(10.3,.25,.34),mat);n+=1
            k.box(c+Vector3(0,3.66,3.8),Vector3(10.3,.25,.34),mat,GeoKit.ALL,false);n+=1
        "toy_town":
            for s in [-1.0,1.0]:
                k.box_xf(Transform3D(Basis(Vector3.UP,float(s)*.14),c+Vector3(float(s)*5.1,1.9,-4.7)),
                    Vector3(.35,3.8,.3),accent,GeoKit.ALL,false);n+=1
            k.box(c+Vector3(0,3.65,-4.8),Vector3(9.8,.18,.2),mat,GeoKit.ALL,false);n+=1
        "roots":
            for s in [-1.0,1.0]:
                k.cylinder(c+Vector3(float(s)*5.16,2.38,-4.4),.50,4.76,mat,6)
                k.box(c+Vector3(float(s)*3.7,4.24,-4.4),Vector3(3.0,.37,.52),accent,GeoKit.ALL,false);n+=2
        "attraction":
            for s in [-1.0,1.0]:
                k.box(c+Vector3(float(s)*5.22,1.8,-4.70),Vector3(.21,3.6,.21),accent);n+=1
            k.box(c+Vector3(0,3.56,-4.70),Vector3(10.6,.28,.32),mat);n+=1
            k.box(c+Vector3(0,3.26,4.6),Vector3(10.2,.18,.16),accent,GeoKit.ALL,false);n+=1
        "neon":
            for s in [-1.0,1.0]:
                k.box(c+Vector3(float(s)*5.26,1.95,-4.65),Vector3(.18,3.90,.18),accent);n+=1
            k.box(c+Vector3(0,3.92,-4.65),Vector3(10.6,.15,.18),accent,GeoKit.ALL,false);n+=1
            k.box(c+Vector3(0,2.64,4.7),Vector3(9.5,.14,.14),mat,GeoKit.ALL,false);n+=1
    return n

static func _guard_flight(k: GeoKit, x: float, z_top: float, y: float, rise: float, accent: String) -> void:
    for seg in range(7):
        var z := z_top + (float(seg)+.5)*3.0
        var center_y := y + rise*(1.0-(float(seg)+.5)/7.0)+.57
        for flank in [-1.0,1.0]:
            k.box(Vector3(x+float(flank)*1.54,center_y,z),Vector3(.12,1.14,3.0),accent)

static func install(owner: LevelBase, old: Dictionary, vista_x: float, z0: float, ybase: float, rise: float) -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not parsed is Dictionary:
        push_error("DEV23 landmark manifest unreadable")
        return {}
    var rec: Dictionary = {}
    for entry in parsed.get("sites",[]):
        if str(entry.get("id","")) == owner.stable_id:
            rec = entry
            break
    if rec.is_empty():
        push_error("DEV23 missing landmark spur: "+owner.stable_id)
        return {}
    assert(str(old["style"])==str(rec["style"]))
    assert(absf(float(rec["origin"][0])+10.5-vista_x)<.001)
    assert(absf(float(rec["origin"][2])-z0)<.001)
    assert(absf(float(rec["origin"][1])-ybase)<.001)
    assert(absf(float(rec["rise"])-rise)<.001)
    var style := str(rec["style"])
    var mat := str(rec["mat"])
    var accent := str(rec["accent"])
    var lower := bool(rec["lower"])
    var k := owner.kit("DEV23_LandmarkSpurs_"+owner.stable_id)
    var state := SpurState.new()
    state.name = "DEV23_InteractiveRouteState_"+owner.stable_id
    owner.add_child(state)
    state.setup(owner,rec)
    var upper_y := ybase+rise
    var upper_z := z0-45.0
    # Connected court starts against DEV22's formerly closed northern vista.
    # A 3.6m gap was opened in that existing physical guard.
    k.slab(vista_x-6.0,z0-27.0,vista_x+6.0,z0-10.9,ybase,.30,mat)
    for flank in [-1.0,1.0]:
        if flank < 0.0 and lower:
            # The lower stair crosses the WEST court perimeter at z0-21.
            # Cut a 3.2m opening, otherwise a full-height guard makes the
            # ostensibly reachable third altitude physically inaccessible.
            k.box(Vector3(vista_x-6.06,ybase+.57,z0-24.85),
                Vector3(.13,1.14,4.50),accent)
            k.box(Vector3(vista_x-6.06,ybase+.57,z0-15.15),
                Vector3(.13,1.14,8.50),accent)
        else:
            k.box(Vector3(vista_x+float(flank)*6.06,ybase+.57,z0-19.0),
                Vector3(.13,1.14,16.2),accent)
        # Split south parapet: matched to the exact DEV22 new doorway.
        k.box(Vector3(vista_x+float(flank)*4.04,ybase+.57,z0-10.93),
            Vector3(4.0,1.14,.13),accent)
    k.box(Vector3(vista_x,ybase+.57,z0-27.07),Vector3(4.6,1.14,.13),accent)
    # Independent west/east stairs (rise 3.4/3.5m over 21m horizontal).
    for flank in [-1.0,1.0]:
        var sx := vista_x+float(flank)*4.50
        k.stairs(Vector3(sx,ybase+.01,z0-24.0),Vector3(0,0,-1),2.72,rise,30,mat,.7,false)
        _guard_flight(k,sx,upper_z,ybase,rise,accent)
        var upper_x := vista_x+float(flank)*14.5
        k.slab(upper_x-6.0,upper_z-6.0,upper_x+6.0,upper_z+6.0,upper_y,.3,mat)
        k.slab(minf(sx,upper_x),upper_z-1.48,maxf(sx,upper_x),upper_z+1.48,upper_y,.28,mat)
        # Two outer guard lines and the outer long edge; inner rail is split
        # with a real opening for the stateful optional cross-gallery.
        for zedge in [-6.08,6.08]:
            k.box(Vector3(upper_x,upper_y+.58,upper_z+zedge),Vector3(12.1,1.16,.13),accent)
        var outer_x := upper_x+float(flank)*6.08
        # DEV24: the EAST gallery now has a centred 3m portal to the new
        # heterogeneous expedition. Keep full rails on the west gallery.
        if flank>0.0:
            for sg in [-1.0,1.0]:
                k.box(Vector3(outer_x,upper_y+.58,upper_z+float(sg)*3.80),
                    Vector3(.13,1.16,4.55),accent)
        else:
            k.box(Vector3(outer_x,upper_y+.58,upper_z),Vector3(.13,1.16,12.15),accent)
        var inner_x := upper_x-float(flank)*6.08
        for zz in [-4.15,4.15]:
            k.box(Vector3(inner_x,upper_y+.58,upper_z+float(zz)),
                Vector3(.13,1.16,3.80),accent)
        _architecture(k,Vector3(upper_x,upper_y,upper_z),style,mat,accent,true)
        var sample := Vector3(upper_x+float(flank)*2.3,upper_y+1.0,upper_z+2.0)
        state.add_beacon(sample,1 if flank<0 else 2)
        owner.add_interactable(sample,Vector3(1.55,1.6,1.55),
            "Survey the %s elevated gallery"%style.replace("_"," "),Callable(state,"activate").bind(1 if flank<0 else 2))
    # Optional underground or underslung gallery creates a THIRD distinct
    # altitude for six settings; other four use only elevated terrain.
    if lower:
        var low_y := ybase-rise
        var low_x := vista_x-31.5
        var low_z := z0-21.0
        k.slab(low_x-6.0,low_z-6.0,low_x+6.0,low_z+6.0,low_y,.30,mat)
        k.stairs(Vector3(vista_x-25.5,low_y+.01,low_z),Vector3(1,0,0),2.72,rise,30,mat,.7,false)
        for s in [-1.0,1.0]:
            var zz := low_z+float(s)*1.53
            for seg in range(7):
                var xx := vista_x-25.5+(float(seg)+.5)*3.0
                var yy := low_y+rise*(float(seg)+.5)/7.0+.57
                k.box(Vector3(xx,yy,zz),Vector3(3.0,1.14,.12),accent)
        # Guarded lower platform: side stair entry remains wide open.
        k.box(Vector3(low_x-6.07,low_y+.57,low_z),Vector3(.14,1.14,12.1),accent)
        for ss in [-1.0,1.0]:
            k.box(Vector3(low_x,low_y+.57,low_z+float(ss)*6.07),Vector3(12.1,1.14,.14),accent)
            k.box(Vector3(low_x+6.08,low_y+.57,low_z+float(ss)*4.2),Vector3(.14,1.14,3.65),accent)
        _architecture(k,Vector3(low_x,low_y,low_z),style,mat,accent,false)
        var lower_at := Vector3(low_x,low_y+1.0,low_z)
        owner.add_interactable(lower_at,Vector3(1.75,1.6,1.75),
            "Investigate the lower landmark",Callable(state,"inspect_lower"))
        owner.add_landmark("%s: lower route" % str(rec["title"]),lower_at)
    _architecture(k,Vector3(vista_x,ybase,z0-19),style,mat,accent,false,true)
    k.commit()
    # Third survey beacon starts on the accessible base court.
    var hub_marker := Vector3(vista_x,ybase+1.0,z0-19.0)
    # Add beacons in order 0,1,2? 1/2 were constructed before this marker:
    # state will register them by explicit index, not append order.
    state.add_beacon(hub_marker,0)
    owner.add_interactable(hub_marker,Vector3(1.65,1.6,1.65),
        "Survey the approach landmark",Callable(state,"activate").bind(0))
    # Real bridge collision is initially disabled. Visible/collidable only
    # AFTER mapping the three independently reachable survey markers.
    var bridge_y := upper_y-.15
    state.configure_bridge(Vector3(vista_x,bridge_y,upper_z),Vector3(17.1,.30,2.92),MatLib.get_mat(accent))
    var switch_pos := Vector3(vista_x+1.9,ybase+1.0,z0-16.2)
    owner.add_interactable(switch_pos,Vector3(1.65,1.6,1.65),
        "Operate the optional return crossing",Callable(state,"toggle_bridge"))
    var dressing := Node3D.new()
    dressing.name = "DEV23_ExistingModels_"+owner.stable_id
    owner.add_child(dressing)
    var models := 0
    var positions := {
        "hub":Vector3(vista_x,ybase,z0-19),
        "west":Vector3(vista_x-14.5,upper_y,upper_z),
        "east":Vector3(vista_x+14.5,upper_y,upper_z),
        "lower":Vector3(vista_x-31.5,ybase-rise,z0-21)}
    for prop in rec["props"]:
        var site := str(prop["site"])
        if site == "lower" and not lower:
            continue
        var at: Vector3 = positions[site]+Vector3(float(prop["dx"]),0,float(prop["dz"]))
        var item := {"pack":str(prop["pack"]),"model":str(prop["model"]),
            "pos":[at.x,at.y,at.z],"height":float(prop["height"]),
            "yaw":float(prop["yaw"]),"solid":false}
        if Dress._place(owner,dressing,item):
            models += 1
    var cues: Array = []
    for key in ["hub","west","east"]:
        var at: Vector3 = positions[key]
        cues.append({"id":"dev23:%s:%s"%[owner.stable_id,key],
            "pos":[at.x,at.y+1.2,at.z],"height":2.0,"radius":4.0,
            "caption":str(rec["ambient_caption"]),"sound":str(rec["sound"]),
            "source":"ADAPTATION"})
    var ambient := Ambient.new()
    ambient.name = "DEV23_RegionalAcoustics_"+owner.stable_id
    dressing.add_child(ambient)
    ambient.setup(owner,cues)
    owner.add_landmark("%s: approach court"%str(rec["title"]),hub_marker)
    owner.add_landmark("%s: upper traverse"%str(rec["title"]),Vector3(vista_x,upper_y+1.0,upper_z))
    var expedition: Dictionary = Expeditions.install(owner,rec)
    return {"expedition":expedition,"id":owner.stable_id,"upper_rooms":2,"base_courts":1,"lower_courts":1 if lower else 0,
        "stairs":3 if lower else 2,"models":models,"recipe_models":rec["props"].size(),
        "beacons":3,"optional_physical_bridge":1,"ambient_zones":3,"status":"NATIVE_QA_PENDING"}
