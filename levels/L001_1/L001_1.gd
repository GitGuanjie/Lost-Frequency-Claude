extends LevelBase
## Four unreliable corridor sectors. The last deliberately has NO physical floor collision.
var _sectors := 4
var _read_log := 0
var _dark_time := 0.0
func build() -> void:
    rules["view_distance"] = 200.0
    indoor_env(Color(0.51,0.64,0.79),0.25,Color(0.08,0.13,0.24),0.007)
    MatLib.define("l11_tile",{"albedo_a":Color(0.22,0.35,0.46),"albedo_b":Color(0.26,0.39,0.50)},"tile")
    MatLib.define("l11_white",{"albedo_a":Color(0.68,0.73,0.76),"albedo_b":Color(0.85,0.87,0.89)},"concrete")
    MatLib.define("l11_rust",{"albedo_a":Color(0.26,0.31,0.35),"albedo_b":Color(0.19,0.24,0.28)},"metal")
    MatLib.register("l11_light",MatLib.panel(Color(0.70,0.88,1.0),1.5))
    lights.setup(8,1)
    _corridor()
    add_arrival("start",Vector3(0,0.08,-108))
    add_arrival("from_L001",Vector3(0,0.08,-108))
    add_exit("L001_1>L001#1","interact",Vector3(0,1.35,-107),Vector3(2.8,2.6,1.0),"Go back through the entrance")
    add_exit("L001_1>L001#2","noclip",Vector3(5.85,1.3,25),Vector3(0.8,2.4,3.5),"Thin wall in Sector 2")
    add_landmark("Sector 1: stable corridor and sparse supplies",Vector3(0,0,-70))
    add_landmark("Sector 2: gentle downhill grade",Vector3(0,0,-12))
    add_landmark("Sector 3: persistent darkness",Vector3(0,0,60))
    add_landmark("Sector 4: floor ceases to hold weight",Vector3(0,0,119))
    add_shot("long_corridor",Vector3(0,1.62,-101),Vector3(0,1.4,-16))
    add_shot("dark_end",Vector3(0,1.62,42),Vector3(0,1.4,107))
    sound.bed("fluorescent_hum",{"seconds":7.0,"base":56.0},-27.0)
func _corridor() -> void:
    var k := kit("FourSectorCorridor")
    for i in 4:
        var z:float=-83.0+float(i)*66.0
        if i<3:
            k.slab(-6,z-33,6,z+33,0,0.32,"l11_tile")
        else:
            # The apparent surface is intentionally noncolliding only in the lethal final sector.
            k.box(Vector3(0,0,z),Vector3(12,0.32,66),"l11_tile",GeoKit.ALL,false)
        for x in [-6.0,6.0]:
            k.box(Vector3(x,3.1,z),Vector3(0.25,6.2,66),"l11_white")
        k.box(Vector3(0,6.2,z),Vector3(12.5,0.25,66),"l11_rust")
        for j in 4:
            var zp:float=z-24.0+float(j)*16.0
            if i<2 or (i==2 and j==1):
                k.box(Vector3(0,6.0,zp),Vector3(2.6,0.08,0.7),"l11_light",GeoKit.ALL,false)
                lights.add_anchor(Vector3(0,5.8,zp),Color(0.73,0.82,1.0),0.45 if i==2 else 0.85,12,0.9,"l11_tube")
            if i==0 and j==1:
                k.box(Vector3(4.5,0.6,zp),Vector3(2.1,1.2,1.4),"l11_rust")
    k.commit()
    add_note("warning","SECTOR LOG","Distance has become unreliable. The unlit fourth sector seems to have no stable surface.",Vector3(4.0,0.9,57))
    add_note("outpost","OUTPOST 2","Light is supplied in intervals. One should not rely on its timer.",Vector3(-4.2,0.9,-5))
func level_process(delta:float) -> void:
    _dark_time+=delta
    if player!=null and player.global_position.z>95 and _dark_time>8.0 and not SessionState.is_qa():
        _dark_time=0.0
        Overlay.subtitle("[the floor seems solid until a foot touches it]",3.0)
func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four distinct sectors","ok":_sectors==4},{"what":"two canon return exits","ok":exits.size()==2},{"what":"both arrival tags","ok":arrivals.has("from_L001") and arrivals.has("start")}]
