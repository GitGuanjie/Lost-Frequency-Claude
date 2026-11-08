extends RefCounted
## DEV22 deterministic, physically built second district for each DEV20 wing.
## Curated layouts and props share one JSON data source with offline graph QA.
## Ten styles, 42 actual elevations, external double stair shafts, per-storey
## lights, optional nonessential route gate, real themed GLB models and audio.
## Godot player collision and FPS MUST be independently certified.

const DATA := "res://data/dev22_narrative_districts.json"
const State = preload("res://core/world/NarrativeDistrictState.gd")
const Dress = preload("res://core/world/ModelDress.gd")
const Ambient = preload("res://core/world/AmbientDiscovery.gd")
const LandmarkSpurs = preload("res://core/world/LandmarkSpurs.gd")
const CELL := 7.0
const SIDE := 4
const WIDTH := 28.0

static func _key(c: int, r: int) -> String:
    return "%d:%d" % [c, r]

static func _edge(c: int, r: int, d: int, s: int) -> String:
    if c > d or (c == d and r > s):
        return "%d:%d-%d:%d" % [d, s, c, r]
    return "%d:%d-%d:%d" % [c, r, d, s]

static func _center(x0: float, z0: float, c: int, r: int, y: float) -> Vector3:
    return Vector3(x0 + (float(c) + 0.5) * CELL, y, z0 + (float(r) + 0.5) * CELL)

static func _portal(side: String, tier: int, row: int, tiers: int) -> bool:
    if side == "east":
        return (tier < tiers - 1 and row == 0) or (tier > 0 and row == 3)
    return (tier < tiers - 1 and row == 3) or (tier > 0 and row == 0)

static func _opening(enabled: bool) -> Array:
    return [{"at": CELL * 0.5, "w": 2.85, "h": 2.85}] if enabled else []

static func _guard(k: GeoKit, center: Vector3, side: String, has_passage: bool, accent: String) -> void:
    var at := center + Vector3.UP * 0.58
    var horiz := side == "north" or side == "south"
    if side == "north": at.z -= 2.61
    elif side == "south": at.z += 2.61
    elif side == "west": at.x -= 2.61
    else: at.x += 2.61
    if has_passage:
        for sign in [-1.0, 1.0]:
            var end := at + (Vector3(float(sign)*2.04,0,0) if horiz else Vector3(0,0,float(sign)*2.04))
            k.box(end, Vector3(1.12,1.16,0.13) if horiz else Vector3(0.13,1.16,1.12), accent)
    else:
        k.box(at, Vector3(5.22,1.16,0.13) if horiz else Vector3(0.13,1.16,5.22), accent)

static func _themed_detail(k: GeoKit, pos: Vector3, style: String, mat: String, accent: String, seed: int) -> int:
    # Geometry is wall/railing adjacent, and never occupies central 3m lane.
    var p := pos + Vector3(-2.75, 0, -2.75)
    match style:
        "keep_forge", "red_keep":
            if seed % 3 == 0:
                k.cylinder(p + Vector3(0,1.42,0),0.27,2.84,accent,8)
                k.box(p+Vector3(0,2.82,0),Vector3(0.92,0.16,0.92),mat)
                return 2
        "canopy", "roots", "fog_trail":
            if seed % 3 != 0:
                k.cylinder(p+Vector3(0,1.25,0),0.19,2.5,accent,5)
                k.box(p+Vector3(0.36,2.38,0),Vector3(0.86,0.13,0.23),mat,GeoKit.ALL,false)
                return 2
        "highway", "attraction":
            if seed % 3 == 0:
                k.box(p+Vector3(0,1.15,0),Vector3(0.34,2.3,0.34),accent)
                k.box(p+Vector3(0.6,2.25,0),Vector3(1.2,0.22,0.18),mat,GeoKit.ALL,false)
                return 2
        "shelter", "toy_town":
            if seed % 4 < 2:
                k.box(p+Vector3(0,0.85,0),Vector3(0.52,1.7,0.42),accent)
                k.box(p+Vector3(0,1.7,0),Vector3(0.86,0.14,0.48),mat,GeoKit.ALL,false)
                return 2
        "neon":
            if seed % 3 != 1:
                k.box(p+Vector3(0,1.2,0),Vector3(0.16,2.4,0.16),accent)
                k.box(p+Vector3(0,2.42,0),Vector3(1.24,0.13,0.14),mat,GeoKit.ALL,false)
                return 2
    return 0

static func _landmark(k: GeoKit, x: float, z: float, y: float, style: String, mat: String, accent: String) -> int:
    # A distinct elevated environmental set-piece on the walkable northern
    # terrace. Pylons stay at its outer edges; the 3m centre remains clear.
    var n := 0
    match style:
        "keep_forge":
            for s in [-1.0,1.0]:
                k.cylinder(Vector3(x+float(s)*3.75,y+1.72,z),0.40,3.44,accent,10)
                n+=1
            k.box(Vector3(x,y+3.46,z),Vector3(7.6,0.36,0.78),mat)
            n+=1
        "canopy":
            for s in [-1.0,1.0]:
                k.cylinder(Vector3(x+float(s)*3.72,y+2.05,z),0.38,4.1,accent,7)
                k.box(Vector3(x+float(s)*2.88,y+3.45,z),Vector3(1.6,0.24,0.26),mat,GeoKit.ALL,false)
                n+=2
        "highway":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.68,y+1.80,z),Vector3(0.30,3.6,0.30),accent)
                n+=1
            k.box(Vector3(x,y+3.55,z),Vector3(7.7,0.45,0.45),mat)
            n+=1
        "red_keep":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.65,y+1.05,z),Vector3(1.1,2.1,1.1),accent)
                k.box(Vector3(x+float(s)*3.65,y+2.42,z),Vector3(1.38,0.42,1.20),mat)
                n+=2
        "fog_trail":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.60,y+1.65,z),Vector3(0.28,3.30,0.28),accent)
                k.box(Vector3(x+float(s)*3.60,y+3.36,z),Vector3(0.72,0.16,0.72),mat,GeoKit.ALL,false)
                n+=2
        "shelter":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.70,y+1.55,z),Vector3(0.42,3.10,0.45),accent)
                n+=1
            k.box(Vector3(x,y+3.18,z),Vector3(7.78,0.24,0.48),mat,GeoKit.ALL,false)
            n+=1
        "toy_town":
            k.box(Vector3(x-3.62,y+1.15,z),Vector3(0.68,2.3,0.68),mat)
            k.box(Vector3(x+3.62,y+2.32,z),Vector3(0.90,4.64,0.64),accent)
            k.box(Vector3(x,y+3.20,z),Vector3(7.6,0.16,0.28),mat,GeoKit.ALL,false)
            n+=3
        "roots":
            for s in [-1.0,1.0]:
                k.cylinder(Vector3(x+float(s)*3.60,y+1.68,z),0.46,3.36,accent,6)
                k.box(Vector3(x+float(s)*2.75,y+3.28,z),Vector3(1.75,0.25,0.38),mat,GeoKit.ALL,false)
                n+=2
        "attraction":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.68,y+1.60,z),Vector3(0.30,3.2,0.30),accent)
                n+=1
            k.box(Vector3(x,y+3.34,z),Vector3(7.65,0.34,0.30),mat)
            n+=1
        "neon":
            for s in [-1.0,1.0]:
                k.box(Vector3(x+float(s)*3.72,y+1.86,z),Vector3(0.17,3.72,0.17),accent)
                n+=1
            k.box(Vector3(x,y+3.74,z),Vector3(7.5,0.13,0.17),mat,GeoKit.ALL,false)
            n+=1
    return n


static func install(owner: LevelBase, tag: String, wing_x0: float, wing_z0: float, wing_ybase: float, rise: float) -> Dictionary:
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not raw is Dictionary:
        push_error("DEV22 district dataset invalid")
        return {}
    var rec: Dictionary = {}
    for entry in raw.get("districts", []):
        if str(entry.get("id", "")) == owner.stable_id and str(entry.get("anchor", "")) == tag:
            rec = entry
            break
    if rec.is_empty():
        push_error("DEV22 district missing: " + owner.stable_id + ":" + tag)
        return {}
    var loc: Array = rec["origin"]
    var x0 := float(loc[0])
    var z0 := float(loc[2])
    var ybase := float(loc[1])
    var tiers := int(rec["tiers"])
    var mat := str(rec["mat"])
    var accent := str(rec["accent"])
    var style := str(rec["style"])
    var open_air := bool(rec["open_air"])
    # Fatal mismatches would otherwise generate free-floating disconnected sites.
    assert(absf(rise - float(rec["rise"])) < 0.001)
    assert(absf(x0 - wing_x0) < 0.001)
    assert(absf(z0 - (wing_z0 - 43.0)) < 0.001)
    assert(absf(ybase - (wing_ybase + rise)) < 0.001)
    var k := owner.kit("DEV22_NarrativeDistrict_" + tag)
    var state := State.new()
    state.name = "DEV22_DistrictState_" + tag
    owner.add_child(state)
    state.setup(owner, rec)
    var rooms := 0
    var passes := 0
    var decorative := 0
    for tier in tiers:
        var y := ybase + float(tier) * rise
        var plan: Dictionary = rec["floors"][tier]
        var cells := {}
        var edges := {}
        for cell in plan["cells"]:
            cells[_key(int(cell[0]),int(cell[1]))] = true
        for e in plan["doors"]:
            edges[_edge(int(e[0]),int(e[1]),int(e[2]),int(e[3]))] = true
        passes += plan["doors"].size()
        for r in SIDE:
            for c in SIDE:
                if not cells.has(_key(c,r)):
                    continue
                rooms += 1
                var p := _center(x0,z0,c,r,y)
                var cx := x0 + float(c)*CELL
                var cz := z0 + float(r)*CELL
                if open_air:
                    k.slab(p.x-2.60,p.z-2.60,p.x+2.60,p.z+2.60,y,0.28,mat)
                else:
                    k.slab(cx,cz,cx+CELL,cz+CELL,y,0.30,mat)
                decorative += _themed_detail(k,p,style,mat,accent,c*19+r*11+tier*7)
                if not open_air:
                    if c+1 < SIDE:
                        if cells.has(_key(c+1,r)):
                            k.wall(Vector3(cx+CELL,y,cz),Vector3(cx+CELL,y,cz+CELL),rise-0.34,0.19,accent,
                                _opening(edges.has(_edge(c,r,c+1,r))))
                        else:
                            _guard(k,p,"east",false,accent)
                    if r+1 < SIDE:
                        if cells.has(_key(c,r+1)):
                            k.wall(Vector3(cx,y,cz+CELL),Vector3(cx+CELL,y,cz+CELL),rise-0.34,0.19,accent,
                                _opening(edges.has(_edge(c,r,c,r+1))))
                        else:
                            _guard(k,p,"south",false,accent)
                    if c>0 and not cells.has(_key(c-1,r)):
                        _guard(k,p,"west",false,accent)
                    if r>0 and not cells.has(_key(c,r-1)):
                        _guard(k,p,"north",false,accent)
                    if c==0:
                        k.wall(Vector3(cx,y,cz),Vector3(cx,y,cz+CELL),rise-0.34,0.19,accent,
                            _opening(_portal("west",tier,r,tiers)))
                    if c==SIDE-1:
                        k.wall(Vector3(cx+CELL,y,cz),Vector3(cx+CELL,y,cz+CELL),rise-0.34,0.19,accent,
                            _opening(_portal("east",tier,r,tiers)))
                    if r==0:
                        k.wall(Vector3(cx,y,cz),Vector3(cx+CELL,y,cz),rise-0.34,0.19,accent,
                            _opening(tier==0 and c==1))
                    if r==SIDE-1:
                        k.wall(Vector3(cx,y,cz+CELL),Vector3(cx+CELL,y,cz+CELL),rise-0.34,0.19,accent,
                            _opening(tier==0 and c==2))
        if open_air:
            # Open air: cells are isolated platforms until these edges get real
            # 2.7m bridges. Every non-edge retains a physical gap and guard.
            for door in plan["doors"]:
                var c := int(door[0])
                var r := int(door[1])
                var d := int(door[2])
                var s := int(door[3])
                var a := _center(x0,z0,c,r,y)
                var b := _center(x0,z0,d,s,y)
                if c!=d:
                    k.slab(a.x,a.z-1.38,b.x,b.z+1.38,y,0.24,mat)
                else:
                    k.slab(a.x-1.38,a.z,b.x+1.38,b.z,y,0.24,mat)
            for raw_cell in plan["cells"]:
                var c := int(raw_cell[0])
                var r := int(raw_cell[1])
                var p := _center(x0,z0,c,r,y)
                for side in ["west","east","north","south"]:
                    var d := c
                    var s := r
                    if side=="west": d-=1
                    elif side=="east": d+=1
                    elif side=="north": s-=1
                    else: s+=1
                    var link := cells.has(_key(d,s)) and edges.has(_edge(c,r,d,s))
                    var stair: bool = ((side=="west" or side=="east") and
                        (c==0 if side=="west" else c==3) and _portal(side,tier,r,tiers))
                    var entrance: bool = side=="south" and tier==0 and c==2 and r==3
                    var landmark: bool = side=="north" and tier==0 and c==1 and r==0
                    _guard(k,p,side,link or stair or entrance or landmark,accent)
        # Stair landings extend outwards exactly to the real east/west treads.
        for side in ["west","east"]:
            for row in [0,3]:
                if not _portal(side,tier,row,tiers):
                    continue
                var sx := x0-3.1 if side=="west" else x0+WIDTH+3.1
                var z := z0+(float(row)+0.5)*CELL
                var edge_x := x0 if side=="west" else x0+WIDTH
                k.slab(minf(sx,edge_x),z-1.32,maxf(sx,edge_x),z+1.32,y,0.28,mat)
        # Thematic overhead accents are visual-only; they do not create a fake
        # traversable surface across the deliberately absent atrium cells.
        if style in ["neon","attraction","keep_forge"]:
            k.box(Vector3(x0+14.0,y+rise-0.40,z0+14.0),
                Vector3(10.0,0.13,0.26),accent,GeoKit.ALL,false)
        var sig := _center(x0,z0,0,1,y)+Vector3(-1.78,0.97,1.64)
        state.add_signal(tier,sig)
        owner.add_interactable(sig,Vector3(1.4,1.55,1.4),
            "Record the %s elevation signal" % style.replace("_"," "),Callable(state,"activate_signal").bind(tier))
        var ctl := _center(x0,z0,3,1,y)+Vector3(1.74,1.0,-1.64)
        k.box(ctl-Vector3(0,0.48,0),Vector3(0.43,0.96,0.32),accent)
        owner.add_interactable(ctl,Vector3(1.45,1.6,1.45),
            "Adjust local environmental lighting",Callable(state,"toggle_ambient").bind(tier))
        if tier==0 or tier==tiers-1:
            var obs_i := 0 if tier==0 else 1
            var site := _center(x0,z0,1,3,y)+Vector3(1.5,1.02,1.54)
            owner.add_interactable(site,Vector3(1.5,1.55,1.5),
                "Investigate the unusual surroundings",Callable(state,"investigate").bind(obs_i))
        if tier==0 or tier==tiers-1:
            owner.add_landmark("%s: %s level %d" % [owner.stable_id,str(rec["title"]),tier+1],sig)
    # A real north terrace connects via room (1,0) on district tier 0;
    # unlike a distant scenery mesh, it is a physical branch players can visit.
    var vista_x := x0 + 1.5 * CELL
    var vista_z := z0 - 7.0
    k.slab(vista_x-5.10,z0-11.0,vista_x+5.10,z0+0.35,ybase,0.28,mat)
    for side in [-1.0,1.0]:
        k.box(Vector3(vista_x+float(side)*5.16,ybase+0.59,z0-5.5),
            Vector3(0.13,1.18,11.0),accent)
    # DEV23: make a real 3.6m entry through the old northern terrace guard;
    # otherwise the new playable expedition would be visually adjacent yet blocked.
    for flank in [-1.0,1.0]:
        k.box(Vector3(vista_x+float(flank)*3.465,ybase+0.59,z0-11.05),
            Vector3(3.33,1.18,0.13),accent)
    decorative += _landmark(k,vista_x,vista_z,ybase,style,mat,accent)
    owner.add_interactable(Vector3(vista_x,ybase+1.12,vista_z+2.8),
        Vector3(1.6,1.6,1.6),"Investigate this district's landmark",
        Callable(state,"investigate").bind(2))
    # Two genuinely traversable, opposite-direction external stair sequences
    # connect *each* adjacent floor; no teleport or fake route in the model.
    for tier in range(tiers-1):
        var low := ybase+float(tier)*rise
        k.stairs(Vector3(x0+WIDTH+3.1,low+0.015,z0+3.5),Vector3(0,0,1),2.5,rise,30,mat,0.7,false)
        k.stairs(Vector3(x0-3.1,low+0.015,z0+24.5),Vector3(0,0,-1),2.5,rise,30,mat,0.7,false)
        # Intermittent protective exterior balustrades outside walking width.
        for i in 7:
            var z_delta := float(i)*3.5
            for flank in [-1.0,1.0]:
                var offset := float(flank)*1.42
                var yy := low+rise*z_delta/21.0+0.56
                k.box(Vector3(x0+WIDTH+3.1+offset,yy,z0+3.5+z_delta),
                    Vector3(0.12,1.12,3.4),accent)
                k.box(Vector3(x0-3.1+offset,yy,z0+24.5-z_delta),
                    Vector3(0.12,1.12,3.4),accent)
    # Southern physical connector from DEV20 middle floor (tier1) to the
    # DEV22 base floor. It spans a true 15m gap, with side rails and door.
    var bridge_x := wing_x0+17.5
    var wing_north_z := wing_z0
    var district_south_z := z0+WIDTH
    k.slab(bridge_x-1.42,district_south_z-0.35,
        bridge_x+1.42,wing_north_z+0.35,ybase,0.27,mat)
    for side in [-1.0,1.0]:
        k.box(Vector3(bridge_x+float(side)*1.47,ybase+0.60,
            (district_south_z+wing_north_z)*0.5),
            Vector3(0.12,1.2,wing_north_z-district_south_z),accent)
    # Root supports live outside the critical floor/bridge circulation path.
    var foundation_y := wing_ybase-rise
    for x in [x0+0.55,x0+WIDTH-0.55]:
        for z in [z0+0.55,z0+WIDTH-0.55]:
            var hh := ybase-foundation_y
            k.box(Vector3(x,foundation_y+hh*0.5,z),Vector3(0.48,hh,0.48),accent)
    if not open_air:
        var roof_y := ybase+float(tiers)*rise
        for c in range(SIDE):
            for r in range(SIDE):
                # The top has windows to the sky directly above the atrium.
                if [c,r] in rec["floors"][tiers-1]["voids"]:
                    continue
                k.slab(x0+float(c)*CELL,z0+float(r)*CELL,
                    x0+float(c+1)*CELL,z0+float(r+1)*CELL,roof_y,0.22,accent)
    k.commit()
    var e: Array = rec["shutter_edge"]
    var a := _center(x0,z0,int(e[0]),int(e[1]),ybase+rise)
    var b := _center(x0,z0,int(e[2]),int(e[3]),ybase+rise)
    var gate_pos := (a+b)*0.5+Vector3.UP*1.33
    var gate_size := Vector3(0.15,2.62,2.60) if int(e[0])!=int(e[2]) else Vector3(2.60,2.62,0.15)
    state.configure_gate(gate_pos,gate_size,MatLib.get_mat(accent))
    owner.add_interactable(a+Vector3.UP*1.0,Vector3(1.5,1.6,1.5),
        "Release the optional return hatch",Callable(state,"toggle_gate"))
    var dressing := Node3D.new()
    dressing.name = "DEV22_ExistingGLBDetails_" + tag
    owner.add_child(dressing)
    var placed := 0
    for prop in rec["models"]:
        var cell: Array = prop["cell"]
        var tier := int(prop["tier"])
        var p: Array = prop["offset"]
        var ctr := _center(x0,z0,int(cell[0]),int(cell[1]),ybase+float(tier)*rise)
        ctr+=Vector3(float(p[0]),0,float(p[1]))
        var item := {"pack":str(prop["pack"]),"model":str(prop["model"]),
            "pos":[ctr.x,ctr.y,ctr.z],"height":float(prop["height"]),
            "yaw":float(prop["yaw"]),"solid":false}
        if Dress._place(owner,dressing,item):
            placed += 1
    # Two curated existing GLBs complete the distinctive setpiece without
    # obstructing the centre of its playable terrace.
    for prop in rec["landmark_models"]:
        var spot := Vector3(vista_x+float(prop["offset_x"]),ybase,vista_z+2.35)
        var item := {"pack":str(prop["pack"]),"model":str(prop["model"]),
            "pos":[spot.x,spot.y,spot.z],"height":float(prop["height"]),
            "yaw":float(prop["yaw"]),"solid":false}
        if Dress._place(owner,dressing,item):
            placed += 1
    var ambient := Ambient.new()
    ambient.name = "DEV22_ThemeSounds_" + tag
    dressing.add_child(ambient)
    ambient.setup(owner,rec["ambience"])
    var spur: Dictionary = LandmarkSpurs.install(owner,rec,vista_x,z0,ybase,float(rec["rise"]))
    return {"tiers":tiers,"cells":rooms,"doors":passes,"stairs":2*(tiers-1),
        "models":placed,"model_recipes":rec["models"].size(),"signals":tiers,
        "light_controls":tiers,"observations":3,"optional_gate":1,
        "landmark_terrace":1,"landmark_spur":spur,
        "detail_geometry":decorative,"id":str(rec["id"]),"status":"NATIVE_QA_PENDING"}
