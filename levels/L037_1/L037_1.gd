extends LevelBase
var _water_darken:=0.0
func build()->void:
    indoor_env(Color(0.29,0.09,0.12),0.31,Color(0.17,0.028,0.04),0.038)
    MatLib.define("d6_redtile",{"albedo_a":Color(0.29,0.19,0.22),"albedo_b":Color(0.39,0.24,0.28)},"tile")
    MatLib.define("d6_redpool",{"albedo_a":Color(0.39,0.045,0.08),"albedo_b":Color(0.58,0.08,0.12)},"water")
    lights.setup(6,0)
    var k:=kit("SanguineReservoir")
    k.slab(-58,-65,58,65,0,0.4,"d6_redtile")
    for x in [-58.0,58.0]:k.box(Vector3(x,4,0),Vector3(0.6,8,130),"d6_redtile")
    for z in [-65.0,65.0]:k.box(Vector3(0,4,z),Vector3(116,8,0.6),"d6_redtile")
    for i in 15:
        var x:float=-43+float(i%5)*21
        var z:float=-40+float(int(i/5))*40
        if absf(x)<10 and z<0:continue
        k.box(Vector3(x,1.2,z),Vector3(5,2.4,5),"d6_redtile")
    k.commit()
    var water:=WaterVolume.new()
    add_child(water)
    water.setup(Vector3(-55,-5,-60),Vector3(55,0.3,60),"d6_redpool",true)
    add_arrival("start",Vector3(0,0.11,-56))
    add_arrival("from_L037",Vector3(0,0.11,-56))
    add_note("camera","FOUND CAMERA","A damaged camera was reportedly recovered here. Its transcript is testimony, not a guarantee of safety.",Vector3(-9,0.7,-49))
    add_note("ambassadors","SHADOWS ABOVE","The reported floating figures appear to ignore visitors. This prototype does not add a hostile pursuer.",Vector3(11,0.7,32))
    add_landmark("Red-tinted basin",Vector3(0,0,0))
    add_landmark("Dark passage",Vector3(0,0,55))
    add_shot("red_pool_threshold",Vector3(0,1.7,-52),Vector3(0,1,45))
    add_shot("sanguine_tiles",Vector3(29,1.7,25),Vector3(-25,1.5,-13))
    sound.bed("room_tone",{"seconds":9.0},-39.0)
func level_process(delta:float)->void:
    _water_darken=minf(1.0,_water_darken+delta/300.0)
    environment.ambient_light_energy=0.31-0.16*_water_darken
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no invented crossing back","ok":exits.is_empty()},{"what":"ambient starts bright","ok":_water_darken<0.01}]
