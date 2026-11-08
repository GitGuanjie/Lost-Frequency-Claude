extends LevelBase
var _doors_examined:=0
func build()->void:
    outdoor_env(Color(0.01,0.02,0.04),Color(0.10,0.09,0.11),Color(0.13,0.14,0.17),Vector2(82,-30),Color(0.88,0.59,0.25),0.08,Color(0.16,0.16,0.17),0.018)
    MatLib.define("d7_snowroad",{"albedo_a":Color(0.73,0.77,0.79),"albedo_b":Color(0.89,0.89,0.90)},"snow")
    MatLib.define("d7_block",{"albedo_a":Color(0.91,0.54,0.26),"albedo_b":Color(0.98,0.87,0.72)},"concrete")
    MatLib.define("d7_glass",{"albedo_a":Color(0.09,0.15,0.20),"albedo_b":Color(0.19,0.26,0.32)},"metal")
    lights.setup(12,0)
    var k:=kit("WinterRefuge")
    k.slab(-115,-128,115,128,0,0.65,"d7_snowroad")
    for i in 12:
        var x:float=-75+float(i%4)*47
        var z:float=-80+float(int(i/4))*75
        k.box(Vector3(x,8.2,z),Vector3(25,16.4,30),"d7_block")
        for h in 3:
            k.box(Vector3(x,3.0+float(h)*4,z-15.2),Vector3(19,1.0,0.25),"d7_glass",GeoKit.ALL,false)
    for z in [-105.0,-10.0,89.0]:
        for x in [-45.0,0.0,45.0]:
            k.cylinder(Vector3(x,4.0,z),0.17,8.0,"d7_glass",8)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-118))
    add_arrival("from_L011",Vector3(0,0.1,-118))
    add_exit("L011_2>L011#1","walk_in",Vector3(0,1.5,-123),Vector3(9,3.0,4),"Leave the silent winter refuge")
    add_exit("L011_2>L036#6","interact",Vector3(48,1.4,70),Vector3(4,2.8,4),"Unmarked apartment door to the airport")
    for i in 6:
        var n:int=i
        add_interactable(Vector3(-65+float(i%3)*65,1.2,-46+float(int(i/3))*75),Vector3(4.5,2.4,3),"Inspect a sealed apartment",func():_inspect(n))
    add_note("leaders","THE LEADERS","Apartment signs suggest a former refuge. The snow falls under a permanently dark sky.",Vector3(5,0.8,-101))
    add_landmark("Black-sky street",Vector3(0,0,-70))
    add_landmark("Airport threshold apartment",Vector3(48,0,70))
    add_shot("snow_complex",Vector3(0,1.7,-113),Vector3(45,12,55))
    add_shot("night_street",Vector3(60,1.7,39),Vector3(-66,9,-80))
    sound.bed("wind",{"seconds":10.0},-35.0)
func _inspect(n:int)->void:
    _doors_examined+=1
    Overlay.subtitle("[apartment %d has no reply]"%(n+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"two built destinations correctly linked","ok":exits.size()==2},{"what":"other destinations remain unbuilt","ok":_doors_examined==0}]
