extends LevelBase
var _drawings:=0
func build()->void:
    indoor_env(Color(0.24,0.25,0.28),0.35,Color(0.09,0.12,0.15),0.035)
    MatLib.define("d7_limestone",{"albedo_a":Color(0.29,0.29,0.25),"albedo_b":Color(0.45,0.44,0.39)},"rock")
    MatLib.define("d7_char",{"albedo_a":Color(0.09,0.09,0.08),"albedo_b":Color(0.18,0.17,0.14)},"dirt")
    lights.setup(5,0)
    var k:=kit("CavernOfMessages")
    k.slab(-25,-65,25,65,0,0.6,"d7_limestone")
    for x in [-25.0,25.0]:k.box(Vector3(x,6.8,0),Vector3(1.0,13.6,130),"d7_limestone")
    k.box(Vector3(0,12.5,0),Vector3(51,0.9,130),"d7_limestone")
    for i in 60:
        var x:float=rng.randf_range(-23,23)
        var z:float=rng.randf_range(-58,58)
        if absf(x)<4.5:continue
        var h:float=rng.randf_range(1,6)
        k.cylinder(Vector3(x,12-h*0.5,z),rng.randf_range(0.5,1.4),h,"d7_limestone",6,false)
    k.box(Vector3(0,0.3,20),Vector3(3,0.6,3),"d7_char")
    for i in 6:
        k.box(Vector3(-21,2.4,-50+float(i)*18),Vector3(0.12,1.7,2.4),"d7_char",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-57))
    add_note("camp","THE CAMPFIRE IS COLD","There are signs that someone waited here, but there is no evidence of a safe exit.",Vector3(3,0.8,20))
    for i in 5:
        var n:int=i
        add_interactable(Vector3(-21.1,2.4,-50+float(i)*18),Vector3(1.6,2,2),"Examine the old cave marking",func():_read(n))
    add_landmark("Choked entrance",Vector3(0,0,-57))
    add_landmark("Cold campfire",Vector3(0,0,20))
    add_shot("low_crawl",Vector3(0,1.5,-57),Vector3(0,2,45))
    add_shot("cave_drawings",Vector3(-15,1.7,3),Vector3(-23,2.2,-11))
    sound.bed("room_tone",{"seconds":9.0},-37.0)
func _read(n:int)->void:
    _drawings+=1
    Overlay.subtitle("[the handprints are older than the nearby scratches: %d]"%(n+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"cave does not fake an exit","ok":exits.is_empty()},{"what":"artifacts exist","ok":qa_shots.size()>=2}]
