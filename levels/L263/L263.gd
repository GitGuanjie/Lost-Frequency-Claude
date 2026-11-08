extends LevelBase
var _window_reads:=0
func build()->void:
    indoor_env(Color(1.0,0.68,0.81),0.58,Color(0.31,0.12,0.20),0.009)
    MatLib.define("d7_pink",{"albedo_a":Color(0.96,0.56,0.73),"albedo_b":Color(0.98,0.71,0.80)},"plaster")
    MatLib.define("d7_pinkcarpet",{"albedo_a":Color(0.68,0.29,0.50),"albedo_b":Color(0.79,0.36,0.58)},"carpet")
    MatLib.define("d7_static",{"albedo_a":Color(0.40,0.40,0.43),"albedo_b":Color(0.79,0.73,0.77)},"metal")
    lights.setup(10,0)
    var k:=kit("PrettyPinkIntervals")
    k.slab(-12,-170,12,170,0,0.5,"d7_pinkcarpet")
    k.box(Vector3(0,17,0),Vector3(25,0.5,341),"d7_static")
    for x in [-12.0,12.0]:
        k.box(Vector3(x,8.5,0),Vector3(0.5,17,340),"d7_pink")
        for i in 31:
            var z:float=-163+float(i)*10.7
            k.box(Vector3(x*-0.98,5,z),Vector3(0.15,5.4,5.5),"d7_static",GeoKit.ALL,false)
    for i in 24:
        var z:float=-165+float(i)*14
        k.box(Vector3(0,15.6,z),Vector3(7,0.1,0.3),"d7_pink",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-155))
    add_note("pink","TURN AROUND","The source allows departure by simply turning around, but specifies no destination. The game therefore does not assign a false level.",Vector3(2,0.8,-147))
    for i in 6:
        var n:int=i
        add_interactable(Vector3(-11.5,5,-105+float(i)*42),Vector3(2,3,4),"Look through static",func():_screen(n))
    add_landmark("Pink static windows",Vector3(0,0,0))
    add_shot("long_pink_hall",Vector3(0,1.6,-149),Vector3(0,8,155))
    add_shot("window_static",Vector3(-4,1.6,17),Vector3(-12,5,37))
    sound.bed("room_tone",{"seconds":8.0},-40.0)
func _screen(n:int)->void:
    _window_reads+=1
    Overlay.subtitle("[window %d: nothing is broadcasting]"%(n+1),3.3)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no invented turning destination","ok":exits.is_empty()},{"what":"corridor static interactions","ok":_window_reads==0}]
