extends LevelBase
var _voices:=0
func build()->void:
    rules["view_distance"]=420.0
    outdoor_env(Color(0.28,0.56,0.76),Color(0.77,0.91,0.95),Color(0.08,0.13,0.16),Vector2(43,27),Color(1.0,0.98,0.91),0.90,Color(0.63,0.76,0.81),0.002)
    MatLib.define("d6_grass",{"albedo_a":Color(0.38,0.65,0.29),"albedo_b":Color(0.49,0.76,0.31)},"grass")
    MatLib.define("d6_stone",{"albedo_a":Color(0.30,0.36,0.38),"albedo_b":Color(0.42,0.44,0.48)},"rock")
    lights.setup(2,0)
    var k:=kit("ShiftedVoid")
    for i in 10:
        var row:int=int(i/5)
        var col:int=i%5
        var x:float=-66+float(col)*33
        var z:float=-25+float(row)*67
        k.slab(x-11,z-12,x+11,z+12,12.0,1.3,"d6_grass")
        k.box(Vector3(x,5,z),Vector3(19,13,20),"d6_stone",GeoKit.ALL,false)
        if i in [0,1,2,3]:
            k.box(Vector3(x+16.5,11.85,z),Vector3(13,0.3,2.2),"d6_stone")
    # DEV15 adaptation: pale traversable island shelves, not the reported
    # dark false bridges. They join two formerly disconnected island rows via
    # TWO inclined ascents and a high lateral loop; no unsourced exit added.
    _looping_island_circuits(k)
    k.commit()
    add_arrival("start",Vector3(-66,12.1,-25))
    for i in 3:
        add_interactable(Vector3(-66+float(i)*33,13,33),Vector3(3,3,3),"Listen to the faraway voice",func():_hear())
    add_note("false","FIELD NOTE","The dark bridges described in one account may be an induced false form. They are not treated as fixed geography.",Vector3(-62,12.6,-18))
    add_landmark("First floating island",Vector3(-66,12,-25))
    add_landmark("Discontinuous bright islands",Vector3(0,12,42))
    add_landmark("Upper shelf between two traversable ascents",Vector3(0,18,8.5))
    add_shot("islands_over_void",Vector3(-66,13.6,-23),Vector3(32,12,45))
    add_shot("edges_of_memory",Vector3(0,13.6,42),Vector3(65,12,45))
    sound.bed("wind",{"seconds":9.0},-36.0)
func _looping_island_circuits(k: GeoKit)->void:
    # Second row previously existed only as unreachably decorative islands.
    # Physical links have the same one-metre landing overlap as the first row.
    for i in 4:
        var x:float=-66.0+float(i)*33.0
        k.box(Vector3(x+16.5,11.85,42),Vector3(13,0.30,2.3),"d6_stone")
        for side in [-1.0,1.0]:
            k.box(Vector3(x+16.5,12.55,42.0+side*1.2),
                Vector3(12.6,1.1,0.12),"d6_stone")
    # Two widely separated ascent sites produce a real 3D cycle:
    # first-row island chain -> west climb -> high bridge -> east descent ->
    # second-row chain -> east climb, closing a second traversable loop.
    for x in [-33.0,66.0]:
        k.stairs(Vector3(x,12.01,-13.0),Vector3(0,0,1),3.4,6.0,30,"d6_stone",18.5/30.0,false)
        k.stairs(Vector3(x,12.01,30.0),Vector3(0,0,-1),3.4,6.0,30,"d6_stone",18.5/30.0,false)
        for z in [-2.0,20.0]:
            var y:float=12.0+(z+13.0)*6.0/18.5 if z<8.5 else 12.0+(30.0-z)*6.0/18.5
            for side in [-1.0,1.0]:
                k.box(Vector3(x+side*2.0,y+0.62,z),Vector3(0.13,1.2,0.13),"d6_stone")
    # Four top shelves have two real stairs feeding them and three lateral
    # bridges. These top nodes are not floating marker-only decorations.
    for j in 4:
        var x:float=-33.0+float(j)*33.0
        k.slab(x-11.0,5.5,x+11.0,11.5,18.0,0.42,"d6_grass")
        for z in [5.40,11.60]:
            # 4 m clear centre opening allows either uphill flight to land.
            for side in [-1.0,1.0]:
                k.box(Vector3(x+side*6.5,18.55,z),Vector3(9.0,1.1,0.15),"d6_stone")
        if j<3:
            k.box(Vector3(x+16.5,17.85,8.5),Vector3(13,0.3,3.1),"d6_stone")
            for z in [6.85,10.15]:
                k.box(Vector3(x+16.5,18.56,z),Vector3(13,1.12,0.14),"d6_stone")

func _hear()->void:
    _voices+=1
    Overlay.subtitle("[a familiar voice offers a path without showing where it goes]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unknown exits are not invented","ok":exits.is_empty()},{"what":"void islands have shots","ok":qa_shots.size()==2}]
