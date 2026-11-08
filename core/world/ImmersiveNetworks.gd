extends RefCounted
## DEV25: optional, wiki-aware annexes. Read generated topology once and build real
## collision from the SAME node/link graph audited by the Python tests.
## No canonical exits, arrivals or status flags are modified.
const DATA := "res://data/dev25_immersive_networks.json"
const Dress := preload("res://core/world/ModelDress.gd")
const NetworkState := preload("res://core/world/ImmersiveNetworkState.gd")

static func _v(data: Array) -> Vector3:
    return Vector3(float(data[0]),float(data[1]),float(data[2]))

static func _direction(a: Vector3, b: Vector3) -> Vector3:
    var d := b-a
    d.y=0.0
    return d.normalized()

static func _edge_name(direction: Vector3) -> String:
    if direction.x > .5: return "east"
    if direction.x < -.5: return "west"
    if direction.z > .5: return "south"
    return "north"

static func _guard(k: GeoKit, p: Vector3, side: String, opened: bool, accent: String) -> void:
    # Split a protective rail for every actual portal. Rail cannot block a stair.
    var s := -1.0 if side in ["west","north"] else 1.0
    var across_x := side in ["north","south"]
    var edge := p+Vector3(0,.64,s*4.05) if across_x else p+Vector3(s*4.05,.64,0)
    if not opened:
        k.box(edge,Vector3(8.1,1.28,.14) if across_x else Vector3(.14,1.28,8.1),accent)
        return
    for pos in [-2.82,2.82]:
        var center: Vector3 = edge+Vector3(pos,0,0) if across_x else edge+Vector3(0,0,pos)
        k.box(center,Vector3(2.45,1.28,.14) if across_x else Vector3(.14,1.28,2.45),accent)

static func _deck(k: GeoKit, p: Vector3, mat: String, accent: String, opened: Dictionary) -> void:
    k.slab(p.x-4.0,p.z-4.0,p.x+4.0,p.z+4.0,p.y,.28,mat)
    for side in ["east","west","north","south"]:
        _guard(k,p,side,opened.has(side),accent)

static func _walk(k: GeoKit, a: Vector3, b: Vector3, mat: String, accent: String) -> void:
    var dir := _direction(a,b)
    var distance := a.distance_to(b)
    var start := a+dir*4.0
    var end := b-dir*4.0
    var mid := (start+end)*.5
    var across_z := absf(dir.x)>.5
    if across_z:
        k.slab(minf(start.x,end.x),mid.z-1.6,maxf(start.x,end.x),mid.z+1.6,a.y,.25,mat)
    else:
        k.slab(mid.x-1.6,minf(start.z,end.z),mid.x+1.6,maxf(start.z,end.z),a.y,.25,mat)
    var length := distance-8.0
    for sign in [-1.0,1.0]:
        var lateral: Vector3 = Vector3(-dir.z,0,dir.x)*1.68*sign
        k.box(mid+lateral+Vector3(0,.62,0),
            Vector3(length,1.24,.12) if across_z else Vector3(.12,1.24,length),accent)

static func _connector(k: GeoKit, entry: Vector3, first: Vector3, mat: String, accent: String) -> void:
    # Previous releases ended the connector 4m short of its source. This path
    # overlaps the old supporting floor by 2m and the new floor by 0.25m.
    var dir := _direction(entry,first)
    var begin := entry-dir*2.0
    var finish := first-dir*3.75
    var mid := (begin+finish)*.5
    var length := (finish-begin).length()
    var along_x := absf(dir.x)>.5
    if along_x:
        k.slab(minf(begin.x,finish.x),mid.z-1.6,maxf(begin.x,finish.x),mid.z+1.6,entry.y,.25,mat)
    else:
        k.slab(mid.x-1.6,minf(begin.z,finish.z),mid.x+1.6,maxf(begin.z,finish.z),entry.y,.25,mat)
    for sign in [-1.0,1.0]:
        var lateral: Vector3 = Vector3(-dir.z,0,dir.x)*1.7*sign
        k.box(mid+lateral+Vector3(0,.61,0),
            Vector3(length,1.22,.12) if along_x else Vector3(.12,1.22,length),accent)

static func _stair(k: GeoKit, low: Vector3, high: Vector3, mat: String, accent: String) -> void:
    var dir := _direction(low,high)
    var dxz := Vector2(high.x-low.x,high.z-low.z).length()
    assert(absf(dxz-28.0)<.05 and absf(high.y-low.y-3.5)<.05)
    var base := low+dir*4.0+Vector3(0,.015,0)
    var run := dxz-8.0
    k.stairs(base,dir,2.8,3.5,20,mat,run/20.0,false)
    for step in range(5):
        var t := (float(step)+.5)/5.0
        var mid := base+dir*(run*t)+Vector3(0,3.5*t+.65,0)
        for sign in [-1.0,1.0]:
            var lateral: Vector3 = Vector3(-dir.z,0,dir.x)*1.52*sign
            k.box_xf(Transform3D(Basis(Vector3.UP,0),mid+lateral),
                Vector3(3.9,1.3,.13) if absf(dir.x)>.5 else Vector3(.13,1.3,3.9),accent,GeoKit.ALL,false)

static func _identity(k: GeoKit, p: Vector3, site: Dictionary, index: int) -> void:
    var style := str(site["style"])
    var mat := str(site["mat"])
    var accent := str(site["accent"])
    # All large structures sit in the four corners or ABOVE the 2m player height.
    # Central walking corridors, portal openings and survey objects stay clear.
    match style:
        "tar_pier":
            for sign in [-1.0,1.0]:
                k.box(p+Vector3(3.45*sign,-1.35,3.45),Vector3(.34,2.7,.34),accent)
            if index%3==0:
                k.box(p+Vector3(0,4.35,3.5),Vector3(7.7,.22,.24),accent,GeoKit.ALL,false)
        "seafront":
            if index%2==0:
                for sign in [-1.0,1.0]:
                    k.cylinder(p+Vector3(3.45*sign,1.7,3.45),.17,3.4,mat,8)
                k.box(p+Vector3(0,3.65,3.45),Vector3(7.3,.19,1.25),accent,GeoKit.ALL,false)
        "roadside":
            if index%2==0:
                for sign in [-1.0,1.0]:
                    k.box(p+Vector3(sign*3.45,2.2,-3.45),Vector3(.22,4.4,.22),accent)
                k.box(p+Vector3(0,4.3,-3.45),Vector3(7.2,.20,.32),accent,GeoKit.ALL,false)
        "memorial":
            # Quiet weathered stone at the perimeter; no arcade, loud machinery or NPCs.
            if index%3==0:
                k.box(p+Vector3(3.35,.55,3.3),Vector3(.68,1.1,.37),accent)
        "sunflower":
            if index%2==0:
                for sign in [-1.0,1.0]:
                    k.box(p+Vector3(sign*3.45,1.8,3.45),Vector3(.25,3.6,.25),mat)
                k.box(p+Vector3(0,3.56,3.45),Vector3(7.25,.18,.30),accent,GeoKit.ALL,false)
        "vapor_temple":
            for sign in [-1.0,1.0]:
                k.cylinder(p+Vector3(sign*3.45,1.9,3.45),.25,3.8,mat,8)
            if index%3==0:
                k.box(p+Vector3(0,4.25,3.45),Vector3(7.3,.14,.24),accent,GeoKit.ALL,false)

static func install(owner: LevelBase) -> Dictionary:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not raw is Dictionary:
        push_error("DEV25 invalid immersive network blueprint")
        return {}
    var site: Dictionary = {}
    for record in raw.get("sites",[]):
        if str(record.get("id",""))==owner.stable_id:
            site=record
            break
    if site.is_empty():
        return {}
    var nodes: Dictionary = {}
    for key in site["nodes"]:
        nodes[str(key)]=_v(site["nodes"][key])
    var open_sides: Dictionary = {}
    for key in nodes: open_sides[key]={}
    var first := "b_16_0"
    var entry := _v(site["entry"])
    open_sides[first][_edge_name(_direction(nodes[first],entry))]=true
    for link in site["links"]:
        var a := str(link["a"])
        var b := str(link["b"])
        var dir := _direction(nodes[a],nodes[b])
        open_sides[a][_edge_name(dir)]=true
        open_sides[b][_edge_name(-dir)]=true
    var k := owner.kit("DEV25_DistinctImmersiveNetwork_"+owner.stable_id)
    # Connector begins INSIDE the existing support (no teleport to the new site).
    _connector(k,entry,nodes[first],str(site["mat"]),str(site["accent"]))
    var index := 0
    for key in nodes:
        var p: Vector3 = nodes[key]
        _deck(k,p,str(site["mat"]),str(site["accent"]),open_sides[key])
        _identity(k,p,site,index)
        index+=1
    for link in site["links"]:
        var a: Vector3 = nodes[str(link["a"])]
        var b: Vector3 = nodes[str(link["b"])]
        match str(link["kind"]):
            "walk": _walk(k,a,b,str(site["mat"]),str(site["accent"]))
            "stair": _stair(k,a,b,str(site["mat"]),str(site["accent"]))
            "optional": pass # Physics rail and crossing are owned by state.
    k.commit()
    var state := NetworkState.new()
    state.name = "DEV25_ObservationState_"+owner.stable_id
    owner.add_child(state)
    state.setup(owner,site)
    var optional: Array = site["optional_edge"]
    state.configure_bridge(nodes[str(optional[0])],nodes[str(optional[1])],
        MatLib.get_mat(str(site["mat"])),MatLib.get_mat(str(site["accent"])))
    for idx in range(3):
        var key := str(site["surveys"][idx])
        var p: Vector3 = nodes[key]+Vector3(-2.65,1.05,-2.55)
        state.add_survey(idx,p)
        var survey_point := owner.add_interactable(p,Vector3(1.55,1.55,1.55),
            "Study this location's unusual signal",Callable(state,"survey").bind(idx))
        survey_point.name = "DEV25_Survey_%d" % idx
    var light_idx := 0
    for key in ["b_32_0",str(site["surveys"][2])]:
        var p: Vector3 = nodes[key]+Vector3(2.35,2.75,2.30)
        state.add_light(p)
        var switch_point := owner.add_interactable(p-Vector3(0,1.65,0),Vector3(1.5,1.8,1.5),
            "Toggle the local guide light",Callable(state,"switch_light").bind(light_idx))
        switch_point.name = "DEV25_GuideSwitch_%d" % light_idx
        light_idx+=1
    var first_optional: Vector3 = nodes[str(optional[0])]
    var lever := owner.add_interactable(first_optional+Vector3(1.65,1.05,-1.35),Vector3(1.5,1.5,1.5),
        "Operate the optional crossing",Callable(state,"operate_bridge"))
    lever.name = "DEV25_OptionalLever"
    # Localized audio observations; 3D proximity AND floor height are checked,
    # so cues do not fire through a solid deck above the listener.
    state.add_ambient_cue(nodes[str(site["surveys"][1])]+Vector3(0,1.5,0),
        str(site["message"]))
    state.add_ambient_cue(nodes[str(optional[1])]+Vector3(0,1.5,0),
        "The passage doubles back on itself, but the light comes from another direction.")
    var visuals := Node3D.new()
    visuals.name = "DEV25_ExistingGLB_"+owner.stable_id
    owner.add_child(visuals)
    var dressed := 0
    for item in site["props"]:
        var p: Vector3 = nodes[str(item["node"])]
        var d := {"pack":str(item["pack"]),"model":str(item["model"]),
            "pos":[p.x+float(item["dx"]),p.y,p.z+float(item["dz"])],
            "height":float(item["height"]),"yaw":float(item["yaw"]),"solid":false}
        if Dress._place(owner,visuals,d): dressed+=1
    owner.add_landmark(str(site["title"]),nodes["b_32_0"])
    return {"id":owner.stable_id,"nodes":nodes.size(),"links":site["links"].size(),
        "props":dressed,"stair_pairs":2,"optional_not_required":true}
