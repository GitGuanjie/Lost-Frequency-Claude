extends LevelBase
func build()->void:
    rules["view_distance"]=600.0
    outdoor_env(Color(0.54,0.56,0.57),Color(0.72,0.72,0.71),Color(0.36,0.37,0.36),Vector2(36,114),Color(0.82,0.82,0.80),0.62,Color(0.63,0.63,0.64),0.004)
    MatLib.define("d6_flat",{"albedo_a":Color(0.49,0.51,0.50),"albedo_b":Color(0.55,0.55,0.54)},"grass")
    MatLib.define("d6_turbine",{"albedo_a":Color(0.64,0.66,0.67),"albedo_b":Color(0.73,0.74,0.73)},"metal")
    lights.setup(1,0)
    var k:=kit("ColorfulColorlessPlain")
    k.slab(-150,-155,150,155,0,0.6,"d6_flat")
    for i in 9:
        var x:float=-112+float(i%3)*112
        var z:float=-106+float(int(i/3))*112
        k.cylinder(Vector3(x,16,z),1.2,32,"d6_turbine",12)
        k.box(Vector3(x,32,z),Vector3(18,1.2,1.2),"d6_turbine",GeoKit.ALL,false)
        k.box(Vector3(x,32,z),Vector3(1.2,18,1.2),"d6_turbine",GeoKit.ALL,false)
    for i in 4:
        k.box(Vector3(-90+float(i)*60,1.1,0),Vector3(2,2.2,178),"d6_turbine")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-144))
    add_note("plain","STATIC WEATHER","The class block says exit guaranteed, but gives no method. There is no fabricated travel destination in this prototype.",Vector3(5,1,-135))
    add_landmark("Silent turbine field",Vector3(0,0,0))
    add_landmark("Concrete flood barriers",Vector3(0,0,60))
    add_shot("turbine_plain",Vector3(0,1.6,-137),Vector3(0,14,25))
    add_shot("flood_barrier",Vector3(54,1.6,25),Vector3(-110,4,5))
    sound.bed("wind",{"seconds":9.0},-43.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"source gives no actual exit method","ok":exits.is_empty()},{"what":"curated shots","ok":qa_shots.size()==2}]
