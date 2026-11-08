extends LevelBase
var _brochures:=0
func build()->void:
    outdoor_env(Color(0.20,0.12,0.33),Color(0.52,0.26,0.43),Color(0.09,0.08,0.14),Vector2(26,-85),Color(0.74,0.72,0.88),0.57,Color(0.18,0.13,0.25),0.023)
    MatLib.define("d7_island",{"albedo_a":Color(0.35,0.42,0.28),"albedo_b":Color(0.48,0.54,0.34)},"grass")
    MatLib.define("d7_hut",{"albedo_a":Color(0.49,0.37,0.26),"albedo_b":Color(0.62,0.48,0.35)},"wood_floor")
    MatLib.define("d7_mushroom",{"albedo_a":Color(0.65,0.45,0.71),"albedo_b":Color(0.87,0.64,0.86)},"concrete")
    MatLib.register("d7_spring",MatLib.water({"shallow_color":Color(0.30,0.64,0.67),"deep_color":Color(0.11,0.33,0.43),"wave_height":0.05}))
    var k:=kit("IslandOfYonder")
    k.slab(-82,-83,82,-13,0,1.2,"d7_island")
    k.slab(-82,15,82,83,0,1.2,"d7_island")
    k.slab(-82,-13,-16,15,0,1.2,"d7_island")
    k.slab(16,-13,82,15,0,1.2,"d7_island")
    # Lake kept below the surrounding path, no solid slab across the water.
    k.slab(-15,-12,15,14,-2.1,0.3,"d7_island")
    for i in 8:
        var x:float=-60+float(i%4)*39
        var z:float=-58+float(int(i/4))*115
        k.box(Vector3(x,2.2,z),Vector3(11,4.4,10),"d7_hut")
        k.box(Vector3(x,4.7,z),Vector3(12,0.4,11),"d7_mushroom",GeoKit.ALL,false)
    for i in 75:
        var x:float=rng.randf_range(-73,73)
        var z:float=rng.randf_range(-76,76)
        if absf(x)<20 and absf(z)<19:continue
        k.cylinder(Vector3(x,0.85,z),0.3,1.7,"d7_hut",7,false)
        k.cylinder(Vector3(x,1.8,z),0.95,0.45,"d7_mushroom",10,false)
    k.commit()
    var spring:=WaterVolume.new();add_child(spring)
    spring.setup(Vector3(-15,-2,-12),Vector3(15,-0.4,14),"d7_spring",true)
    add_arrival("start",Vector3(0,0.1,-71))
    add_note("brochure","YONDER'S END","The brochures promise a home with no departure date. The documented escorted return does not identify its destination.",Vector3(3,0.8,-61))
    for i in 4:
        var n:int=i
        add_interactable(Vector3(-56+float(i)*36,1.0,42),Vector3(3,2,3),"Read a resident brochure",func():_read(n))
    add_landmark("Spring-fed island lake",Vector3(0,0,0))
    add_landmark("Mushroom plots",Vector3(60,0,50))
    add_shot("violet_island",Vector3(0,1.6,-68),Vector3(0,2,67))
    add_shot("settlement_huts",Vector3(-30,1.6,18),Vector3(60,5,54))
    sound.bed("wind",{"seconds":8.0},-36.0)
func _read(n:int)->void:
    _brochures+=1
    Overlay.subtitle("[brochure %d: return escort requires an agreement]"%(n+1),3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no guessed escorted destination","ok":exits.is_empty()},{"what":"island shots planned","ok":qa_shots.size()==2}]
