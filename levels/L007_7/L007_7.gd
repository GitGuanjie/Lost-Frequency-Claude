extends LevelBase
var _pressure:=0.0
func build()->void:
    outdoor_env(Color(0.33,0.39,0.43),Color(0.58,0.65,0.69),Color(0.11,0.13,0.15),Vector2(35,50),Color(0.78,0.82,0.84),0.53,Color(0.31,0.39,0.41),0.015)
    MatLib.define("d6_rock",{"albedo_a":Color(0.30,0.33,0.32),"albedo_b":Color(0.42,0.43,0.40)},"rock")
    MatLib.define("d6_tower",{"albedo_a":Color(0.74,0.72,0.66),"albedo_b":Color(0.85,0.82,0.73)},"concrete")
    MatLib.define("d6_rust",{"albedo_a":Color(0.38,0.23,0.17),"albedo_b":Color(0.55,0.30,0.18)},"metal")
    lights.setup(4,0)
    var k:=kit("CarrierLighthouse")
    k.cylinder(Vector3(0,-4,0),22,8,"d6_rock",16)
    # Rectangular lighthouse hull with an actual ground-floor doorway. The
    # walkable exterior stair-ramp alternates direction, joining each landing.
    k.box(Vector3(-7,22,0),Vector3(0.8,44,14),"d6_tower")
    k.box(Vector3(7,22,0),Vector3(0.8,44,14),"d6_tower")
    k.box(Vector3(0,22,7),Vector3(14,44,0.8),"d6_tower")
    k.box(Vector3(-5.3,22,-7),Vector3(3.4,44,0.8),"d6_tower")
    k.box(Vector3(5.3,22,-7),Vector3(3.4,44,0.8),"d6_tower")
    k.box(Vector3(0,24,-7),Vector3(7.2,40,0.8),"d6_tower")
    for i in 11:
        var y:float=float(i)*4.0
        var z0:float=-7.0 if i%2==0 else 7.0
        var z1:float=7.0 if i%2==0 else -7.0
        k.ramp(Vector3(10,y,z0),Vector3(10,y+4.0,z1),2.4,0.25,"d6_rust")
        k.slab(8.7,z1-1.6,11.3,z1+1.6,y+4.0,0.28,"d6_rust")
    k.slab(6.0,-8,13.0,8,44.0,0.45,"d6_tower")
    k.box(Vector3(0,44.5,0),Vector3(14,0.4,14),"d6_tower")
    k.cylinder(Vector3(0,47,0),5.1,4,"d6_rust",14)
    k.commit()
    var sea:=WaterVolume.new()
    add_child(sea)
    sea.setup(Vector3(-180,-22,-180),Vector3(180,-0.2,180),"water",true)
    add_arrival("start",Vector3(13,0.1,-7))
    add_arrival("from_L007",Vector3(13,0.1,-7))
    var e:=add_exit("L007_7>L007#1","fall",Vector3(27,-5,0),Vector3(18,16,24),"Jump into the ocean")
    e.fall_y=-1.8
    add_interactable(Vector3(6,0.9,0),Vector3(2.2,2.2,3),"Inspect pressure valve",func():_pressure+=1.0)
    add_note("gas","LIGHTHOUSE LOG","Upper pipes and lamp equipment are poorly maintained. The cause of the final explosion remains uncertain.",Vector3(1,1,-8))
    add_landmark("Narrow rock landing",Vector3(13,0,0))
    add_landmark("Lighthouse lamp zone",Vector3(0,45,0))
    add_shot("rock_and_lighthouse",Vector3(13,1.6,-13),Vector3(0,27,0))
    add_shot("lighthouse_rust",Vector3(10,34,10),Vector3(0,44,0))
    sound.bed("wind",{"seconds":8.0},-27.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"single documented fall route","ok":exits.size()==1},{"what":"pressure valve unturned","ok":_pressure==0}]
