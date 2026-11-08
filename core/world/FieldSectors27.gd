extends Node3D
## DEV27: optional, physical, thematically authored high/low exploration sectors.
## Spawn and exits are owned by LevelBase and are NEVER replaced. Existing level
## materials and Kenney GLBs are reused. One owner node per level; freed on exit.
const Dress = preload("res://core/world/ModelDress.gd")
const Ambient = preload("res://core/world/AmbientDiscovery.gd")

var level: LevelBase
var rec: Dictionary = {}
var investigated := [false, false, false]
var marker_lights: Array = []
var marker_meshes: Array = []
var lamps: Array = []
var optional_bridge: StaticBody3D
var optional_floor_shape: CollisionShape3D
var optional_floor_mesh: MeshInstance3D
var optional_sides: Array = []
var closure_rails: Array = []
var bridge_open := false
var _height := 3.6
var _hx := 12.0
var _hz := 12.0
var _placed := 0

func setup(owner: LevelBase, record: Dictionary) -> void:
    level = owner
    rec = record
    var anchor: Array = rec["anchor"]
    position = Vector3(float(anchor[0]), 0.0, float(anchor[1]))
    var dims: Array = rec["half"]
    _hx = float(dims[0])
    _hz = float(dims[1])
    _build_static_geometry()
    _build_switchable_crossing()
    _build_dressing_and_story()
    level.add_landmark(str(rec["title"]), position + Vector3(0.0, _height, 0.0))

func _point(x: float, y: float, z: float) -> Vector3:
    return Vector3(x, y, z)

func _geometry(k: GeoKit, c: Vector3, side: String, opening: bool, rail: String) -> void:
    # A 3.3-m opening centred on an accessible stair or connecting bridge.
    # Openings are calculated from the same geometry as the walkable edges.
    var y := c.y + 0.60
    if side == "north" or side == "south":
        var z := c.z + (3.58 if side == "north" else -3.58)
        if opening:
            for dx in [-2.55, 2.55]:
                k.box(Vector3(c.x + dx, y, z), Vector3(1.90, 1.20, .13), rail)
        else:
            k.box(Vector3(c.x, y, z), Vector3(7.10, 1.20, .13), rail)
    else:
        var x := c.x + (3.58 if side == "east" else -3.58)
        if opening:
            for dz in [-2.55, 2.55]:
                k.box(Vector3(x, y, c.z + dz), Vector3(.13, 1.20, 1.90), rail)
        else:
            k.box(Vector3(x, y, c.z), Vector3(.13, 1.20, 7.10), rail)

func _edge_guard(k: GeoKit, a: Vector3, b: Vector3, material: String) -> void:
    var mid := (a + b) * 0.5 + Vector3.UP * .58
    var along_x := absf(b.x-a.x) > 1.0
    if along_x:
        var edge_length: float = absf(b.x-a.x)
        # The north and south inner rails otherwise seal the retractable
        # crossing even after it opens. Leave a 3.3 m physical portal, guarded
        # by the CLOSED-only barriers added in _build_switchable_crossing().
        var inner_side: float = -1.0 if mid.z > 0.0 else 1.0
        var bridge_mouth: bool = absf(mid.x) < 0.1 and absf(absf(mid.z)-_hz) < 0.1
        for s in [-1.0,1.0]:
            if bridge_mouth and absf(float(s)-inner_side)<0.1:
                var remaining: float = (edge_length-3.30)*0.5
                if remaining > 0.0:
                    for half in [-1.0,1.0]:
                        var dx: float = float(half)*(1.65+remaining*0.5)
                        k.box(mid+Vector3(dx,0,float(s)*1.61),
                            Vector3(remaining,1.16,.12),material)
            else:
                k.box(mid + Vector3(0,0,float(s)*1.61),
                    Vector3(edge_length,1.16,.12), material)
    else:
        for s in [-1.0,1.0]:
            k.box(mid + Vector3(s*1.61,0,0), Vector3(.12,1.16,absf(b.z-a.z)), material)

func _build_static_geometry() -> void:
    var floor_mat := str(rec["floor"])
    var accent := str(rec["accent"])
    var k := GeoKit.new(self, "DEV27_Physical_%s" % level.stable_id)
    var corners := [Vector3(-_hx,_height,-_hz),Vector3(_hx,_height,-_hz),
        Vector3(_hx,_height,_hz),Vector3(-_hx,_height,_hz)]
    # Distinct corner plazas, an open central void, real perimeter walks.
    for i in 4:
        var c: Vector3 = corners[i]
        k.slab(c.x-3.55,c.z-3.55,c.x+3.55,c.z+3.55,_height,.32,floor_mat)
        var opening: Dictionary = {
            "south":i==0 or i==2, "north":i==0 or i==2,
            "east":i==0 or i==3, "west":i==1 or i==2}
        # Actual perimeter edges: SW-NW, SW-SE, SE-NE, NE-NW.
        if i == 0: opening = {"south":true,"north":true,"east":true,"west":false}
        if i == 1: opening = {"south":false,"north":true,"east":false,"west":true}
        if i == 2: opening = {"south":true,"north":true,"east":false,"west":true}
        if i == 3: opening = {"south":true,"north":false,"east":true,"west":false}
        var node_id: String = ["sw","se","ne","nw"][i]
        for spur in rec.get("spurs", []):
            if str(spur["from"]) == node_id:
                opening[str(spur["direction"])] = true
        for side in ["north","south","east","west"]:
            _geometry(k,c,side,bool(opening[side]),accent)
    # All four walk edges are physically generated. An optional middle chord
    # (dynamic geometry) is NOT needed to reach any of the four platforms.
    var a: Vector3 = corners[0]
    var b: Vector3 = corners[1]
    var c: Vector3 = corners[2]
    var d: Vector3 = corners[3]
    k.slab(a.x+3.55,a.z-1.48,b.x-3.55,b.z+1.48,_height,.32,floor_mat)
    k.slab(b.x-1.48,b.z+3.55,c.x+1.48,c.z-3.55,_height,.32,floor_mat)
    k.slab(d.x+3.55,d.z-1.48,c.x-3.55,c.z+1.48,_height,.32,floor_mat)
    k.slab(a.x-1.48,a.z+3.55,d.x+1.48,d.z-3.55,_height,.32,floor_mat)
    _edge_guard(k,Vector3(a.x+3.55,_height,a.z),Vector3(b.x-3.55,_height,b.z),accent)
    _edge_guard(k,Vector3(b.x,_height,b.z+3.55),Vector3(c.x,_height,c.z-3.55),accent)
    _edge_guard(k,Vector3(d.x+3.55,_height,d.z),Vector3(c.x-3.55,_height,c.z),accent)
    _edge_guard(k,Vector3(a.x,_height,a.z+3.55),Vector3(d.x,_height,d.z-3.55),accent)
    # Two independent 3.6 m ascents, actual smooth physics ramp under visible steps.
    # The final stair tread lands 0.14 m INSIDE its top plaza, with no solid
    # upper slab over the flight. Stair angle ~=22.6 degrees.
    k.stairs(Vector3(-_hx,.02,-_hz-12.0),Vector3.BACK,2.65,_height,18,floor_mat,.48)
    k.stairs(Vector3(_hx,.02,_hz+12.0),Vector3.FORWARD,2.65,_height,18,floor_mat,.48)
    # Physically supported lower periphery (no roof over existing walkways).
    for px in [-_hx,_hx]:
        for pz in [-_hz,_hz]:
            k.cylinder(Vector3(px,1.62,pz),.26,3.24,accent,8)
    _build_spurs(k,floor_mat,accent)
    _theme_geometry(k,corners,floor_mat,accent)
    k.commit()

func _build_spurs(k: GeoKit, floor_mat: String, accent: String) -> void:
    var corner_nodes := {"sw":Vector3(-_hx,_height,-_hz),
        "se":Vector3(_hx,_height,-_hz),"ne":Vector3(_hx,_height,_hz),
        "nw":Vector3(-_hx,_height,_hz)}
    var dirs := {"north":Vector3(0,0,1),"south":Vector3(0,0,-1),
        "east":Vector3(1,0,0),"west":Vector3(-1,0,0)}
    for rec_spur in rec.get("spurs", []):
        var src: Vector3 = corner_nodes[str(rec_spur["from"])]
        var direction := str(rec_spur["direction"])
        var heading: Vector3 = dirs[direction]
        var raw: Array = rec_spur["pos"]
        var dst := Vector3(float(raw[0]),_height,float(raw[2]))
        # The span starts at the primary plaza's outer edge and terminates
        # inside the new square's own physical slab. No unsupported 0.1m gap.
        var start := src + heading*3.53
        var finish := dst - heading*2.73
        var mid := (start+finish)*.5
        var distance := (finish-start).length()
        if absf(heading.x)>0.5:
            k.slab(minf(start.x,finish.x),mid.z-1.44,maxf(start.x,finish.x),
                mid.z+1.44,_height,.32,floor_mat)
            for side in [-1.0,1.0]:
                k.box(mid+Vector3(0,.58,side*1.55),
                    Vector3(distance,1.16,.12),accent)
        else:
            k.slab(mid.x-1.44,minf(start.z,finish.z),mid.x+1.44,
                maxf(start.z,finish.z),_height,.32,floor_mat)
            for side in [-1.0,1.0]:
                k.box(mid+Vector3(side*1.55,.58,0),
                    Vector3(.12,1.16,distance),accent)
        k.slab(dst.x-2.78,dst.z-2.78,dst.x+2.78,dst.z+2.78,
            _height,.32,floor_mat)
        k.cylinder(dst-Vector3(0,1.8,0),.25,3.60,accent,8)
        var reverse_direction: Dictionary = {"north":"south","south":"north",
            "east":"west","west":"east"}
        var entry: String = str(reverse_direction[direction])
        # Terminal island safely guards the other three sides and leaves
        # a 3-m-wide central portal on the approach from its parent plaza.
        for side in ["north","south","west","east"]:
            var is_open: bool = side == entry
            if side=="north" or side=="south":
                var z := dst.z+(2.82 if side=="north" else -2.82)
                if is_open:
                    for dx in [-2.14,2.14]:
                        k.box(Vector3(dst.x+dx,_height+.57,z),
                            Vector3(1.29,1.14,.12),accent)
                else:
                    k.box(Vector3(dst.x,_height+.57,z),
                        Vector3(5.64,1.14,.12),accent)
            else:
                var x := dst.x+(2.82 if side=="east" else -2.82)
                if is_open:
                    for dz in [-2.14,2.14]:
                        k.box(Vector3(x,_height+.57,dst.z+dz),
                            Vector3(.12,1.14,1.29),accent)
                else:
                    k.box(Vector3(x,_height+.57,dst.z),
                        Vector3(.12,1.14,5.64),accent)

func _theme_geometry(k: GeoKit, corners: Array, floor_mat: String, accent: String) -> void:
    # Distinct architectural grammar per theme; all decorative structural
    # additions are off the walk centreline, with sufficient headroom.
    var style := str(rec["style"])
    for i in 4:
        var c: Vector3 = corners[i]
        match style:
            "canopy":
                for sx in [-2.7,2.7]:
                    k.cylinder(c+Vector3(sx,1.65,-2.65),.12,3.30,accent,7,false)
                k.box(c+Vector3(0,3.36,-2.65),Vector3(5.65,.12,.22),floor_mat,GeoKit.ALL,false)
            "mine":
                for sx in [-2.9,2.9]:
                    k.box(c+Vector3(sx,1.46,2.6),Vector3(.25,2.92,.25),accent,GeoKit.ALL,false)
                k.box(c+Vector3(0,3.01,2.6),Vector3(6.05,.20,.32),accent,GeoKit.ALL,false)
            "harbor":
                for sx in [-2.7,2.7]:
                    k.cylinder(c+Vector3(sx,1.1,2.75),.16,2.20,floor_mat,6,false)
                k.box(c+Vector3(0,2.65,2.75),Vector3(6.1,.14,.35),accent,GeoKit.ALL,false)
            "pasture":
                for j in 3:
                    k.box(c+Vector3(-2.5+float(j)*2.5,1.56,2.78),Vector3(.11,3.10,.12),accent,GeoKit.ALL,false)
                k.box(c+Vector3(0,2.6,2.78),Vector3(5.2,.12,.12),floor_mat,GeoKit.ALL,false)
            "sunflower":
                for sx in [-2.8,2.8]:
                    k.box(c+Vector3(sx,1.40,-2.8),Vector3(.17,2.80,.17),floor_mat,GeoKit.ALL,false)
                k.box(c+Vector3(0,2.86,-2.8),Vector3(5.9,.14,.30),accent,GeoKit.ALL,false)
            "ruins":
                for sx in [-2.67,2.67]:
                    var cap := 1.9 if (i+int(sx))%2==0 else 2.65
                    k.cylinder(c+Vector3(sx,cap*.5,-2.65),.25,cap,accent,9,false)
                k.box(c+Vector3(0,3.0,-2.7),Vector3(6,.20,.24),floor_mat,GeoKit.ALL,false)
            "settlement":
                for sx in [-2.65,2.65]:
                    k.cylinder(c+Vector3(sx,1.33,2.65),.16,2.65,floor_mat,8,false)
                k.cylinder(c+Vector3(0,2.85,2.65),1.75,.23,accent,12,false)
            "stormfront":
                k.box(c+Vector3(2.8,1.86,2.7),Vector3(.19,3.72,.19),accent,GeoKit.ALL,false)
                k.box(c+Vector3(2.8,3.76,2.7),Vector3(2.8,.11,.15),floor_mat,GeoKit.ALL,false)

func _physics_box(label: String, at: Vector3, size: Vector3, material: Material) -> Dictionary:
    var body := StaticBody3D.new()
    body.name = label
    body.position = at
    body.collision_layer = 1
    add_child(body)
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)
    var mesh := MeshInstance3D.new()
    var cube := BoxMesh.new()
    cube.size = size
    mesh.mesh = cube
    mesh.material_override = material
    body.add_child(mesh)
    return {"body":body,"collider":col,"mesh":mesh}

func _build_switchable_crossing() -> void:
    var floor_mat: Material = MatLib.get_mat(str(rec["floor"]))
    var trim_mat: Material = MatLib.get_mat(str(rec["accent"]))
    var length := 2.0*_hz-3.0
    var deck := _physics_box("DEV27_OptionalCrossing",Vector3(0,_height-.16,0),
        Vector3(3.0,.32,length),floor_mat)
    optional_bridge = deck["body"]
    optional_floor_shape = deck["collider"]
    optional_floor_mesh = deck["mesh"]
    # Side rails deploy with the crossing; closed barriers block just the
    # inward edge of the existing ring, not the main lateral passage.
    for sx in [-1.60,1.60]:
        optional_sides.append(_physics_box("DEV27_CrossingSideRail",
            Vector3(sx,_height+.55,0),Vector3(.13,1.10,length),trim_mat))
    for sz in [-1.0,1.0]:
        closure_rails.append(_physics_box("DEV27_ClosedCrossingRail",
            Vector3(0,_height+.55,sz*(_hz-1.52)),Vector3(3.18,1.10,.13),trim_mat))
    _set_bridge(false)

func _set_bridge(opened: bool) -> void:
    bridge_open = opened
    optional_floor_mesh.visible = opened
    optional_floor_shape.set_deferred("disabled",not opened)
    for part in optional_sides:
        (part["mesh"] as MeshInstance3D).visible = opened
        (part["collider"] as CollisionShape3D).set_deferred("disabled",not opened)
    for part in closure_rails:
        (part["mesh"] as MeshInstance3D).visible = not opened
        (part["collider"] as CollisionShape3D).set_deferred("disabled",opened)

func _tint() -> Color:
    var raw: Array = rec["tint"]
    return Color(float(raw[0]),float(raw[1]),float(raw[2]))

func _trigger(local: Vector3, label: String, cb: Callable) -> void:
    var hit := level.add_interactable(position+local,Vector3(1.6,1.9,1.7),label,cb)
    if hit != null: hit.reparent(self)

func _build_dressing_and_story() -> void:
    var col := _tint()
    var spur0: Array = rec["spurs"][0]["pos"]
    var stations := [Vector3(-_hx,_height,-_hz),Vector3(_hx,_height,_hz),
        Vector3(float(spur0[0]),_height,float(spur0[2]))]
    for i in stations.size():
        var at: Vector3 = (stations[i] as Vector3)+Vector3(1.8,1.14,1.85)
        var panel := MeshInstance3D.new()
        panel.name = "DEV27_ObservationMarker_%d" % i
        var box := BoxMesh.new()
        box.size = Vector3(.29,.42,.12)
        panel.mesh = box
        panel.material_override = MatLib.panel(col,.12)
        panel.position = at
        add_child(panel)
        marker_meshes.append(panel)
        var lamp := OmniLight3D.new()
        lamp.name = "DEV27_ObservationLamp_%d" % i
        lamp.position = at+Vector3(0,.27,0)
        lamp.light_color = col
        lamp.light_energy = .06
        lamp.omni_range = 7.0
        lamp.shadow_enabled = false
        add_child(lamp)
        marker_lights.append(lamp)
        _trigger(at,"Investigate a local route marker",Callable(self,"survey").bind(i))
    for i in 2:
        var at := Vector3(_hx if i==0 else -_hx,_height+1.7,-_hz if i==0 else _hz)
        var lamp := OmniLight3D.new()
        lamp.name = "DEV27_ControllableLight_%d" % i
        lamp.position = at
        lamp.light_color = col
        lamp.light_energy = .11
        lamp.omni_range = 12.0
        lamp.shadow_enabled = false
        add_child(lamp)
        lamps.append(lamp)
        _trigger(at-Vector3(0,.6,0),"Adjust the local observation lamps",Callable(self,"toggle_light").bind(i))
    _trigger(Vector3(0,_height+1.12,_hz),"Operate the optional sky crossing",
        Callable(self,"toggle_bridge"))
    # Imported GLBs have no extra physics, and stand around the periphery of
    # stations rather than in the 3-m route centre or its two stair mouths.
    for placement in rec["props"]:
        var item: Dictionary = placement.duplicate(true)
        var p: Array = item["pos"]
        item["pos"] = [float(p[0])+position.x,float(p[1]),float(p[2])+position.z]
        item["solid"] = false
        if Dress._place(level,level,item): _placed+=1
    var ambient := Ambient.new()
    ambient.name = "DEV27_SectorAcoustics"
    add_child(ambient)
    var cues: Array = []
    for i in stations.size():
        var p: Vector3 = (stations[i] as Vector3)+position
        cues.append({"id":"dev27:%s:%d"%[level.stable_id,i],
            "pos":[p.x,p.y+1,p.z],"radius":4.5,"height":2.0,
            "caption":str(rec["observation"]),"sound":str(rec["sound"]),"source":"ADAPTATION"})
    ambient.setup(level,cues)

func survey(_player: Player, index: int) -> void:
    if investigated[index]:
        Overlay.subtitle("This observation was already recorded.",2.6)
        return
    investigated[index] = true
    (marker_lights[index] as OmniLight3D).light_energy = 1.3
    (marker_meshes[index] as MeshInstance3D).material_override = MatLib.panel(_tint(),1.5)
    SaveService.record_discovery(level.stable_id,"dev27:marker:%d"%index,
        "%s: surveyed marker %d"%[str(rec["title"]),index+1],"ADAPTATION")
    var done := 0
    for marker in investigated:
        if marker:done+=1
    if done==3:
        _set_bridge(true)
        Overlay.subtitle("A secondary crossing extends. Both original ascents remain open.",3.6)
        SaveService.record_discovery(level.stable_id,"dev27:crossing",
            str(rec["observation"]),"ADAPTATION")
    else:
        Overlay.subtitle("Observation markers surveyed: %d / 3"%done,2.8)

func toggle_light(_player: Player, index: int) -> void:
    var lamp: OmniLight3D = lamps[index]
    lamp.light_energy = 1.6 if lamp.light_energy<.5 else .11
    Overlay.subtitle("The lantern signal changes, altering the visible route.",2.8)

func toggle_bridge(_player: Player) -> void:
    if investigated.has(false):
        Overlay.subtitle("Inspect all three markers before controlling this crossing.",2.8)
        return
    if bridge_open and level.player != null:
        var lp := level.player.global_position-position
        if absf(lp.y-_height)<2.2 and absf(lp.x)<3.0 and absf(lp.z)<_hz:
            Overlay.subtitle("The crossing is occupied. Move clear before retracting.",2.8)
            return
    _set_bridge(not bridge_open)
    Overlay.subtitle("The optional crossing extends." if bridge_open else "The crossing retracts; safety gates close.",2.8)

func model_count() -> int:
    return _placed

func survey_count() -> int:
    var n := 0
    for value in investigated:
        if value:n+=1
    return n
