extends LevelBase
var _warnings:=0
func build()->void:
    outdoor_env(Color(0.45,0.47,0.45),Color(0.63,0.66,0.62),Color(0.26,0.35,0.26),Vector2(65,-20),Color(0.77,0.78,0.76),0.33,Color(0.51,0.56,0.50),0.031)
    MatLib.define("d7_wheat",{"albedo_a":Color(0.56,0.51,0.28),"albedo_b":Color(0.68,0.61,0.32)},"grass")
    MatLib.define("d7_path",{"albedo_a":Color(0.31,0.33,0.32),"albedo_b":Color(0.42,0.42,0.39)},"dirt")
    MatLib.define("d7_cottage",{"albedo_a":Color(0.36,0.24,0.18),"albedo_b":Color(0.48,0.34,0.22)},"wood_floor")
    var k:=kit("WheatMazes")
    k.slab(-130,-145,130,145,0,0.6,"d7_path")
    # Cross-aisles remain wide enough for physics navigation.
    for i in 20:
        var z:float=-120+float(i)*12
        for j in 13:
            if j%4==0 or i%5==0:continue
            var x:float=-112+float(j)*17
            k.box(Vector3(x,1.7,z),Vector3(6,3.4,3.9),"d7_wheat",GeoKit.ALL,false)
    for i in 3:
        var x:float=-64+float(i)*56
        k.box(Vector3(x,2.3,105),Vector3(10,4.6,9),"d7_cottage")
        k.box(Vector3(x,5.0,105),Vector3(11.2,0.45,10),"d7_cottage")
    k.box(Vector3(-114,2,0),Vector3(2,4,285),"d7_path")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-120))
    add_arrival("from_L028",Vector3(0,0.1,-120))
    add_note("sky","GREY WEATHER","The cloud layer does not move. Keep the mossy roadside wall in sight when the fields repeat.",Vector3(4,0.8,-108))
    for i in 3:
        var n:int=i
        add_interactable(Vector3(-64+float(i)*56,1.2,99),Vector3(4,2.4,2),"Inspect the back door",func():_look(n))
    add_landmark("Mossy highway wall",Vector3(-114,0,0))
    add_landmark("Houses atop the hill",Vector3(0,0,105))
    add_shot("gray_fields",Vector3(0,1.6,-115),Vector3(15,2,103))
    add_shot("brick_wall",Vector3(-107,1.6,4),Vector3(-114,3,100))
    sound.bed("wind",{"seconds":9.0},-39.0)
func _look(n:int)->void:
    _warnings+=1
    Overlay.subtitle("[house %d: the back door opens only into more fields]"%(n+1),4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unmapped exit remains unmapped","ok":exits.is_empty()},{"what":"weather evidence views","ok":qa_shots.size()==2}]
