extends RefCounted
## DEV24: heterogeneous expedition topology, built from generated JSON.
## More shapes alone do NOT prove a route is walkable. Run DEV24 native QA.
## Every new area is grafted physically to the east elevated DEV23 gallery.
const DATA := "res://data/dev24_expeditions.json"
const State = preload("res://core/world/ExpeditionState.gd")
const Dress = preload("res://core/world/ModelDress.gd")
const Ambient = preload("res://core/world/AmbientDiscovery.gd")

static func _v(a: Array) -> Vector3:
    return Vector3(float(a[0]),float(a[1]),float(a[2]))

static func _side(pa: Vector3,pb: Vector3) -> String:
    var d := pb-pa
    if d.x>1.0:return "east"
    if d.x< -1.0:return "west"
    if d.z>1.0:return "south"
    return "north"

static func _guard(k: GeoKit, at: Vector3, side: String, open: bool, accent: String) -> void:
    var y := at.y+.59
    if side in ["west","east"]:
        var x := at.x+(-5.06 if side=="west" else 5.06)
        if open:
            for s in [-1.0,1.0]:
                k.box(Vector3(x,y,at.z+float(s)*3.25),Vector3(.13,1.18,3.5),accent)
        else:
            k.box(Vector3(x,y,at.z),Vector3(.13,1.18,10.05),accent)
    else:
        var z := at.z+(-5.06 if side=="north" else 5.06)
        if open:
            for s in [-1.0,1.0]:
                k.box(Vector3(at.x+float(s)*3.25,y,z),Vector3(3.5,1.18,.13),accent)
        else:
            k.box(Vector3(at.x,y,z),Vector3(10.05,1.18,.13),accent)

static func _walk(k: GeoKit, a: Vector3, b: Vector3, mat: String, accent: String) -> void:
    var p := (a+b)*.5
    if absf(a.x-b.x)>1.0:
        k.slab(minf(a.x,b.x),p.z-1.5,maxf(a.x,b.x),p.z+1.5,a.y,.26,mat)
        for s in [-1.0,1.0]:
            k.box(Vector3(p.x,a.y+.55,p.z+float(s)*1.60),Vector3(4.0,1.10,.13),accent)
    else:
        k.slab(p.x-1.5,minf(a.z,b.z),p.x+1.5,maxf(a.z,b.z),a.y,.26,mat)
        for s in [-1.0,1.0]:
            k.box(Vector3(p.x+float(s)*1.60,a.y+.55,p.z),Vector3(.13,1.10,4.0),accent)

static func _stair(k: GeoKit, a: Vector3, b: Vector3, mat: String, accent: String) -> void:
    # Exactly 21m horizontal distance from a.x+3 to b.x-5, i.e. the
    # entrance EDGE of the higher platform, not under its solid floor.
    # The 30 visible treads share one smooth physical collision ramp.
    assert(absf((b.x-a.x)-29.0)<.01)
    assert(absf(b.z-a.z)<.01)
    var rise := b.y-a.y
    k.stairs(a+Vector3(3.0,.015,0),Vector3.RIGHT,2.7,rise,30,mat,.7,false)
    for i in range(7):
        var xx := a.x+3.0+(float(i)+.5)*3.0
        var yy := a.y+rise*(float(i)+.5)/7.0+.57
        for s in [-1.0,1.0]:
            k.box(Vector3(xx,yy,a.z+float(s)*1.48),Vector3(3.0,1.14,.12),accent)

static func _identity(k: GeoKit, p: Vector3, style: String, mat: String, accent: String, index: int) -> void:
    # Landmark silhouettes occupy outside corners and overhead volumes.
    # This keeps all four 3m central exits and the center walk clear.
    match style:
        "keep_forge":
            for s in [-1.0,1.0]:
                k.cylinder(p+Vector3(float(s)*4.22,1.65,3.90),.33,3.3,mat,8)
            k.box(p+Vector3(0,3.48,3.90),Vector3(8.8,.26,.30),accent,GeoKit.ALL,false)
        "canopy":
            for s in [-1.0,1.0]:
                k.cylinder(p+Vector3(float(s)*4.26,2.0,-3.95),.34,4.0,mat,6)
                k.box(p+Vector3(float(s)*3.3,3.55,-3.95),Vector3(2.0,.25,.3),accent,GeoKit.ALL,false)
        "highway":
            for s in [-1.0,1.0]:
                k.box(p+Vector3(float(s)*4.40,1.38,3.65),Vector3(.18,2.76,.20),accent)
            k.box(p+Vector3(0,2.77,3.65),Vector3(8.9,.19,.22),mat,GeoKit.ALL,false)
        "red_keep":
            for s in [-1.0,1.0]:
                k.box(p+Vector3(float(s)*4.20,.75,-4.15),Vector3(.80,1.5,.80),mat)
                k.box(p+Vector3(float(s)*4.20,1.57,-4.15),Vector3(1.05,.28,1.05),accent)
        "fog_trail":
            for s in [-1.0,1.0]:
                k.cylinder(p+Vector3(float(s)*4.27,1.38,-3.91),.16,2.76,accent,6)
            k.box(p+Vector3(0,2.75,-3.91),Vector3(8.8,.14,.15),mat,GeoKit.ALL,false)
        "shelter":
            for s in [-1.0,1.0]:
                k.box(p+Vector3(float(s)*4.29,1.74,3.8),Vector3(.20,3.48,.27),accent)
            k.box(p+Vector3(0,3.40,3.8),Vector3(8.8,.22,.32),mat,GeoKit.ALL,false)
        "toy_town":
            for s in [-1.0,1.0]:
                k.box_xf(Transform3D(Basis(Vector3.UP,float(s)*.20),p+Vector3(float(s)*4.26,1.55,3.94)),Vector3(.24,3.10,.25),accent,GeoKit.ALL,false)
        "roots":
            for s in [-1.0,1.0]:
                k.cylinder(p+Vector3(float(s)*4.22,2.05,3.96),.43,4.10,mat,6)
                k.box(p+Vector3(float(s)*3.30,3.72,3.96),Vector3(2.1,.32,.4),accent,GeoKit.ALL,false)
        "attraction":
            for s in [-1.0,1.0]:
                k.box(p+Vector3(float(s)*4.24,1.80,-3.91),Vector3(.23,3.6,.23),accent)
            k.box(p+Vector3(0,3.54,-3.91),Vector3(8.8,.29,.35),mat,GeoKit.ALL,false)
        "neon":
            for s in [-1.0,1.0]:
                k.box(p+Vector3(float(s)*4.27,1.91,3.93),Vector3(.15,3.82,.15),accent)
            k.box(p+Vector3(0,3.79,3.93),Vector3(8.7,.13,.18),accent,GeoKit.ALL,false)
    # Every fifth site gains a framed skylight / overhead reference beam.
    if index%5==0:
        k.box(p+Vector3(0,3.95,0),Vector3(6.25,.13,.15),accent,GeoKit.ALL,false)

static func install(owner: LevelBase, old: Dictionary) -> Dictionary:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not raw is Dictionary:
        push_error("DEV24 invalid expedition blueprint")
        return {}
    var site: Dictionary = {}
    for candidate in raw.get("sites",[]):
        if str(candidate.get("id",""))==owner.stable_id:
            site=candidate
            break
    if site.is_empty():
        push_error("DEV24 expedition missing: "+owner.stable_id)
        return {}
    assert(str(site["style"])==str(old["style"]))
    assert(absf(float(site["entry_gallery"][0])-float(old["node_positions"]["east"][0]))<.01)
    assert(absf(float(site["entry_gallery"][2])-float(old["node_positions"]["east"][2]))<.01)
    var mat := str(site["mat"])
    var accent := str(site["accent"])
    var style := str(site["style"])
    var nodes: Dictionary = {}
    for key in site["nodes"]:
        nodes[str(key)]=_v(site["nodes"][key])
    var opens: Dictionary = {}
    for key in nodes:
        opens[key]={}
    opens["b0"]["west"]=true
    # Stair and same-altitude links all use geometrically actual portals.
    for link in site["links"]:
        var a := str(link["a"])
        var b := str(link["b"])
        var kind := str(link["kind"])
        if kind=="stair":
            opens[a]["east"]=true
            opens[b]["west"]=true
        else:
            var forward := _side(nodes[a],nodes[b])
            var back := _side(nodes[b],nodes[a])
            opens[a][forward]=true
            opens[b][back]=true
    var k := owner.kit("DEV24_HeterogeneousExpedition_"+owner.stable_id)
    var gallery := _v(site["entry_gallery"])
    var hub: Vector3 = nodes["b0"]
    # Existing east gallery outer guard receives an actual 3m doorway.
    k.slab(gallery.x+5.65,gallery.z-1.53,hub.x-3.5,gallery.z+1.53,hub.y,.28,mat)
    var start := gallery.x+6.1
    var finish := hub.x-5.0
    for s in [-1.0,1.0]:
        k.box(Vector3((start+finish)*.5,hub.y+.57,hub.z+float(s)*1.62),
            Vector3(finish-start,1.14,.12),accent)
    for node_name in nodes:
        var p: Vector3 = nodes[node_name]
        k.slab(p.x-5.0,p.z-5.0,p.x+5.0,p.z+5.0,p.y,.30,mat)
        for side in ["north","south","west","east"]:
            _guard(k,p,side,opens[node_name].has(side),accent)
        var idx := int(node_name.substr(1))+ (0 if node_name.begins_with("b") else 6)
        _identity(k,p,style,mat,accent,idx)
    for link in site["links"]:
        var a: Vector3 = nodes[str(link["a"])]
        var b: Vector3 = nodes[str(link["b"])]
        match str(link["kind"]):
            "walk": _walk(k,a,b,mat,accent)
            "stair": _stair(k,a,b,mat,accent)
            "unlockable": pass # Stateful physical platform installed below.
    k.commit()
    var state := State.new()
    state.name = "DEV24_ExpeditionState_"+owner.stable_id
    owner.add_child(state)
    state.setup(owner,site)
    var optional: Array = site["optional_edge"]
    state.configure_optional(nodes[str(optional[0])],nodes[str(optional[1])],MatLib.get_mat(mat),MatLib.get_mat(accent))
    for idx in range(3):
        var name := str(site["survey"][idx])
        var p: Vector3 = nodes[name]+Vector3(1.93,1.18,2.43)
        state.add_survey(p,idx)
        owner.add_interactable(p,Vector3(1.5,1.5,1.5),"Map the local expedition marker",Callable(state,"survey").bind(idx))
    for name in ["b1","u1"]:
        var p: Vector3 = nodes[name]+Vector3(-2.15,1.85,-2.15)
        var idx := state.add_local_light(p)
        owner.add_interactable(p-Vector3(0,.6,0),Vector3(1.55,1.65,1.55),"Toggle local observation lights",Callable(state,"toggle_light").bind(idx))
    var optional_a: Vector3 = nodes[str(optional[0])]
    owner.add_interactable(optional_a+Vector3(-1.3,1.12,-1.85),Vector3(1.5,1.5,1.5),
        "Operate the alternate physical crossing",Callable(state,"operate_bridge"))
    owner.add_interactable(nodes["u0"]+Vector3(1.45,1.15,1.25),Vector3(1.45,1.5,1.45),
        "Investigate the expedition's unusual architecture",Callable(state,"inspect"))
    var dressing := Node3D.new()
    dressing.name = "DEV24_ExistingGLB_"+owner.stable_id
    owner.add_child(dressing)
    var placed := 0
    for item in site["props"]:
        var p: Vector3 = nodes[str(item["node"])]
        var place := {"pack":str(item["pack"]),"model":str(item["model"]),
            "pos":[p.x+float(item["dx"]),p.y,p.z+float(item["dz"])],
            "height":float(item["height"]),"yaw":float(item["yaw"]),"solid":false}
        if Dress._place(owner,dressing,place):
            placed+=1
    var cues: Array = []
    for node_name in ["b0","b4","u0"]:
        var p: Vector3 = nodes[node_name]
        cues.append({"id":"dev24:%s:%s"%[owner.stable_id,node_name],
            "pos":[p.x,p.y+1.2,p.z],"height":2.0,"radius":4.0,
            "caption":str(site["observation"]),"sound":str(site["sound"]),"source":"ADAPTATION"})
    var ambient := Ambient.new()
    ambient.name = "DEV24_ExpeditionAcoustics"
    dressing.add_child(ambient)
    ambient.setup(owner,cues)
    owner.add_landmark("%s — lower traverse"%str(site["title"]),nodes["b0"]+Vector3.UP)
    owner.add_landmark("%s — upper traverse"%str(site["title"]),nodes["u0"]+Vector3.UP)
    return {"id":owner.stable_id,"cells":nodes.size(),"links":site["links"].size(),"stairs":1,
        "models":placed,"model_recipes":site["props"].size(),"surveys":3,"light_switches":2,
        "optional_safe_bridge":1,"status":"NATIVE_QA_PENDING"}
