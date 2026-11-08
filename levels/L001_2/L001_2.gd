extends LevelBase
## Concrete Garden; the apparent flowers are memories, not enemy encounters.
var _visions:Dictionary={}
var _garden_time:=0.0
func build()->void:
    indoor_env(Color(0.55,0.65,0.52),0.53,Color(0.38,0.50,0.31),0.010)
    MatLib.define("g12_concrete",{"albedo_a":Color(0.41,0.42,0.39),"albedo_b":Color(0.53,0.53,0.47)},"concrete")
    MatLib.define("g12_grass",{"albedo_a":Color(0.27,0.43,0.23),"albedo_b":Color(0.36,0.49,0.23)},"grass")
    MatLib.define("g12_leaf",{"albedo_a":Color(0.19,0.43,0.29),"albedo_b":Color(0.37,0.57,0.35)},"plaster")
    MatLib.define("g12_rose",{"albedo_a":Color(0.67,0.22,0.46),"albedo_b":Color(0.34,0.37,0.76)},"plaster")
    lights.setup(7,0)
    _garden()
    add_arrival("start",Vector3(0,0.08,-43))
    add_arrival("from_L001",Vector3(0,0.08,-43))
    add_exit("L001_2>L001#1","walk_in",Vector3(0,1.4,-45),Vector3(5,2.8,2),"Retreat into the concrete aisle")
    add_landmark("Concrete entrance",Vector3(0,0,-45))
    add_landmark("Old settlement ruins",Vector3(-21,0,18))
    add_landmark("Blue flowers and borrowed memories",Vector3(23,0,26))
    add_shot("garden_threshold",Vector3(0,1.62,-40),Vector3(0,1,9))
    add_shot("buried_settlement",Vector3(-15,1.62,5),Vector3(-22,1.6,28))
    sound.bed("room_tone",{"seconds":8.0},-34.0)
func _garden()->void:
    var k:=kit("ConcreteGarden")
    # Interconnected concrete warehouse aisles, with vegetation overtaking them.
    k.slab(-49,-51,49,51,0,0.45,"g12_grass")
    for x in [-47.0,47.0]: k.box(Vector3(x,3,0),Vector3(0.7,6,102),"g12_concrete")
    for z in [-50.0,50.0]: k.box(Vector3(0,3,z),Vector3(98,6,0.7),"g12_concrete")
    for x in [-30.0,-10.0,10.0,30.0]:
        for z in [-30.0,-10.0,10.0,30.0]:
            if absf(x)<14 and z<0:continue
            k.box(Vector3(x,2.8,z),Vector3(1.35,5.6,1.35),"g12_concrete")
            for j in 5:
                k.box(Vector3(x+1.1,1.0+float(j)*0.85,z),Vector3(0.15,1.0,0.38),"g12_leaf",GeoKit.ALL,false)
    for i in 165:
        var x:float=rng.randf_range(-43,43)
        var z:float=rng.randf_range(-42,42)
        if x>-4 and x<4 and z<3:continue
        var h:float=rng.randf_range(0.4,1.2)
        k.box(Vector3(x,h*0.5,z),Vector3(0.10,h,0.12),"g12_leaf",GeoKit.ALL,false)
        k.box(Vector3(x,h+0.08,z),Vector3(0.30,0.16,0.30),"g12_rose",GeoKit.ALL,false)
    for i in 8:
        k.box(Vector3(-33+float(i%4)*3,0.8,17+float(int(i/4))*4),Vector3(2.4,1.6,1.0),"g12_concrete")
    k.commit()
    for i in 3:
        var idx:int=i
        add_interactable(Vector3(12+float(i)*6,0.8,17),Vector3(1.8,1.5,2),"Study the flowers",func():_vision(idx))
    add_note("garden","GARDEN SECTOR","The vegetation grows without sunlight or soil. Past mapping teams never returned.",Vector3(2,1,-35))
    add_note("memory","UNFINISHED INQUIRY","Some plants seem to store memories. The longer the visit, the less familiar things feel.",Vector3(-22,1,19))
func _vision(idx:int)->void:
    _visions[idx]=true
    Overlay.subtitle("[a memory that does not belong to you]",3.0)
func level_process(delta:float)->void:
    _garden_time+=delta
    if _garden_time>95.0 and not SessionState.is_qa():
        _garden_time=0.0
        Overlay.subtitle("[it is difficult to recall why you came here]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"garden has a real return exit","ok":exits.size()==1},{"what":"memories not pre-discovered","ok":_visions.is_empty()},{"what":"source-backed entry","ok":arrivals.has("from_L001")}]
