extends LevelBase
func build()->void:
    rules["view_distance"]=400.0
    outdoor_env(Color(0.34,0.48,0.56),Color(0.72,0.75,0.72),Color(0.14,0.22,0.27),Vector2(18,-55),Color(0.88,0.92,0.91),0.78,Color(0.52,0.66,0.70),0.012)
    MatLib.define("d7_stilt",{"albedo_a":Color(0.38,0.27,0.19),"albedo_b":Color(0.52,0.39,0.28)},"wood_floor")
    MatLib.define("d7_snow",{"albedo_a":Color(0.85,0.90,0.92),"albedo_b":Color(0.98,0.98,0.96)},"snow")
    MatLib.register("d7_sea",MatLib.water({"shallow_color":Color(0.25,0.52,0.59),"deep_color":Color(0.04,0.12,0.17),"wave_height":0.14}))
    var k:=kit("StiltVillage")
    k.slab(-115,-110,115,110,-8.0,0.45,"d7_stilt")
    for i in 7:
        var z:float=-83+float(i)*26
        k.slab(-6,z-9,6,z+9,1.5,0.5,"d7_stilt")
        for x in [-5.0,5.0]:k.cylinder(Vector3(x,-3.2,z),0.55,9.5,"d7_stilt",8)
        if i<6:k.slab(-2,z+8,2,z+19,1.5,0.4,"d7_stilt")
        if i%2==0:
            k.box(Vector3(-3.5,3.4,z),Vector3(0.35,3.4,7),"d7_stilt")
            k.box(Vector3(2.4,3.4,z),Vector3(0.35,3.4,7),"d7_stilt")
            k.box(Vector3(-0.6,3.4,z+3.5),Vector3(6,3.4,0.35),"d7_stilt")
            k.box(Vector3(-0.6,5.3,z),Vector3(7,0.4,7.7),"d7_snow",GeoKit.ALL,false)
    for i in 12:
        var z:float=-94+float(i)*17
        k.cylinder(Vector3(29,-3,z),1.5,11,"d7_stilt",9)
    k.commit()
    var ocean:=WaterVolume.new();add_child(ocean)
    ocean.setup(Vector3(-116,-1.5,-112),Vector3(116,0.1,112),"d7_sea",true)
    add_arrival("start",Vector3(0,1.6,-81))
    add_arrival("from_L007_7",Vector3(0,1.6,-81))
    add_exit("L007_8>L007_7#2","interact",Vector3(0,3.0,-81),Vector3(3.4,3.0,4),"Enter the snow-roofed house")
    add_exit("L007_8>L008#1","noclip",Vector3(0,1.6,72),Vector3(7,2.8,5),"Deep Eye threshold")
    add_note("eyes","DEEP EYE","The ocean below some platforms seems bottomless. Do not mistake an opening in the water for solid ground.",Vector3(2,2.25,24))
    add_landmark("Snow-roofed return house",Vector3(0,1.5,-81))
    add_landmark("Deep Eye",Vector3(0,1.5,72))
    add_shot("stilt_piers",Vector3(0,3,-77),Vector3(0,2.2,85))
    add_shot("unending_water",Vector3(3,3.5,49),Vector3(105,0,5))
    sound.bed("water_bed",{"seconds":8.0},-31.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"two documented connected exits","ok":exits.size()==2},{"what":"pier arrival above sea","ok":arrivals.has("start")}]
