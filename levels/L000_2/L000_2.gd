extends LevelBase
var _elapsed:=0.0
var _collapsed:=false
func build()->void:
    indoor_env(Color(0.86,0.80,0.77),0.73,Color(0.73,0.64,0.61),0.005)
    MatLib.define("d6_white",{"albedo_a":Color(0.89,0.88,0.85),"albedo_b":Color(0.96,0.94,0.91)},"plaster")
    MatLib.define("d6_redcarpet",{"albedo_a":Color(0.49,0.10,0.10),"albedo_b":Color(0.66,0.15,0.14)},"carpet")
    MatLib.define("d6_stud",{"albedo_a":Color(0.47,0.36,0.28),"albedo_b":Color(0.59,0.44,0.33)},"wood_floor")
    lights.setup(6,0)
    var k:=kit("RemodeledCollapse")
    k.slab(-13,-40,13,40,0,0.45,"d6_redcarpet")
    for x in [-13.0,13.0]:k.box(Vector3(x,2.6,0),Vector3(0.4,5.2,80),"d6_white")
    for z in [-40.0,40.0]:k.box(Vector3(0,2.6,z),Vector3(26,5.2,0.4),"d6_white")
    k.box(Vector3(0,5.3,0),Vector3(26,0.3,80),"d6_white")
    for i in 17:
        var z:float=-35+float(i)*4.2
        for x in [-10.5,10.5]:k.box(Vector3(x,2.1,z),Vector3(0.2,4.2,0.22),"d6_stud")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-35))
    add_arrival("from_L000",Vector3(0,0.1,-35))
    add_exit("L000_2>L000#1","walk_in",Vector3(0,1.3,36.6),Vector3(5,2.6,3),"The way back")
    add_note("doc1","DOCUMENT ONE","The house has been repaired too perfectly, as if no previous room had existed.",Vector3(5,0.9,-22))
    add_note("doc2","DOCUMENT TWO","Behind the painted wall are unfinished studs, bare nails, and drifting dust.",Vector3(-5,0.9,0))
    add_note("doc3","DOCUMENT THREE","I heard the ceiling give way and then I—",Vector3(5,0.9,23))
    add_landmark("Red-carpeted room",Vector3(0,0,-31))
    add_landmark("Unfinished wall studs",Vector3(-10,0,9))
    add_shot("pristine_stretch",Vector3(0,1.6,-34),Vector3(0,1.5,30))
    add_shot("studs",Vector3(8,1.6,7),Vector3(-11,2,19))
    sound.bed("room_tone",{"seconds":7.0},-31.0)
func level_process(delta:float)->void:
    _elapsed+=delta
    if not _collapsed and _elapsed>25.0:
        _collapsed=true
        var rubble:=kit("CollapseDebris")
        for i in 13:
            var z:float=-30+float(i)*5.2
            var x:float=-9.0 if i%2==0 else 9.0
            rubble.box(Vector3(x,0.28,z),Vector3(3.4,0.55,2.2),"d6_stud")
            rubble.box(Vector3(x,1.4,z),Vector3(0.24,2.8,0.32),"d6_stud",GeoKit.ALL,false)
        rubble.commit()
        environment.fog_density=0.032
        if not SessionState.is_qa():Overlay.subtitle("[the new plaster begins to crack]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"real return to Level 0","ok":exits.size()==1},{"what":"collapse begins intact","ok":not _collapsed},{"what":"three documents staged","ok":qa_shots.size()>=2}]
