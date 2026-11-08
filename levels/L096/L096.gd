extends LevelBase
var _swept:=0
func build()->void:
    outdoor_env(Color(0.39,0.51,0.64),Color(0.73,0.80,0.83),Color(0.27,0.33,0.30),Vector2(33,28),Color(0.95,0.90,0.81),0.65,Color(0.56,0.60,0.63),0.015)
    MatLib.define("d6_house",{"albedo_a":Color(0.72,0.68,0.62),"albedo_b":Color(0.82,0.77,0.69)},"plaster")
    MatLib.define("d6_carpet",{"albedo_a":Color(0.57,0.52,0.43),"albedo_b":Color(0.68,0.60,0.49)},"carpet")
    MatLib.define("d6_porcelain",{"albedo_a":Color(0.83,0.85,0.82),"albedo_b":Color(0.93,0.94,0.91)},"tile")
    lights.setup(3,0)
    var k:=kit("SolaceHouse")
    k.slab(-24,-30,24,30,6,2,"d6_house")
    k.slab(-11,-11,11,11,6.1,0.1,"d6_carpet")
    # Split the front wall to form a real walk-through opening to the ledge.
    k.box(Vector3(-7.6,10.2,-11),Vector3(6.8,8,0.4),"d6_house")
    k.box(Vector3(7.6,10.2,-11),Vector3(6.8,8,0.4),"d6_house")
    k.box(Vector3(0,13.1,-11),Vector3(8.4,2.2,0.4),"d6_house")
    k.box(Vector3(0,10.2,11),Vector3(22,8,0.4),"d6_house")
    for x in [-11.0,11.0]:k.box(Vector3(x,10.2,0),Vector3(0.4,8,22),"d6_house")
    k.box(Vector3(0,14.25,0),Vector3(23,0.5,23),"d6_house")
    for i in 9:
        k.box(Vector3(-23+float(i)*5.5,3,-32),Vector3(4,5.5,4),"d6_house",GeoKit.ALL,false)
    for i in 4:
        k.cylinder(Vector3(-7+float(i)*4.5,6.7,6),0.35,1.4,"d6_porcelain",12)
    k.commit()
    add_arrival("start",Vector3(0,6.2,0))
    add_interactable(Vector3(-6,7,0),Vector3(3,2.5,3),"Sweep the dust",func():_sweep())
    add_note("solace","SOLACE","A quiet place for reflection. Nothing forces you to leave, and there is no sourced passage out.",Vector3(3,7,3))
    add_landmark("Mountain-view house",Vector3(0,6,0))
    add_landmark("Porcelain pitchers",Vector3(0,6,6))
    add_shot("silent_house",Vector3(0,7.6,-6),Vector3(0,7,7))
    add_shot("mountain_outlook",Vector3(8,7.6,3),Vector3(23,5,-29))
    sound.bed("room_tone",{"seconds":10.0},-46.0)
func _sweep()->void:
    _swept+=1
    Overlay.subtitle("[a fine layer of dust lifts, then slowly settles]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no invented escape","ok":exits.is_empty()},{"what":"dust untouched","ok":_swept==0}]
