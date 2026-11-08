extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
var _volumes_read:=0
func build()->void:
    indoor_env(Color(0.74,0.68,0.62),0.63,Color(0.38,0.30,0.27),0.006)
    MatLib.define("d7_marble",{"albedo_a":Color(0.76,0.73,0.66),"albedo_b":Color(0.86,0.82,0.74)},"concrete")
    MatLib.define("d7_bookcase",{"albedo_a":Color(0.24,0.16,0.12),"albedo_b":Color(0.39,0.25,0.18)},"wood_floor")
    MatLib.define("d7_burgundy",{"albedo_a":Color(0.42,0.12,0.17),"albedo_b":Color(0.57,0.17,0.17)},"carpet")
    lights.setup(9,0)
    var k:=kit("PrometheanReadingHall")
    k.slab(-25,-56,25,56,0,0.55,"d7_marble")
    k.box(Vector3(0,11.4,0),Vector3(51,0.6,113),"d7_marble")
    for x in [-24.0,24.0]:k.box(Vector3(x,5.5,0),Vector3(0.7,11,111),"d7_marble")
    for z in [-55.0,55.0]:k.box(Vector3(0,5.5,z),Vector3(50,11,0.6),"d7_marble")
    for i in 11:
        var z:float=-45.0+float(i)*9
        for x in [-15.0,15.0]:
            k.box(Vector3(x,3.1,z),Vector3(3.3,6.2,1.2),"d7_bookcase")
            k.cylinder(Vector3(x*1.38,4.8,z),0.65,9.6,"d7_marble",10)
    for i in 6:
        k.box(Vector3(0,0.07,-38.0+float(i)*15),Vector3(5.8,0.05,6.4),"d7_burgundy",GeoKit.ALL,false)
    # Upper reading gallery with a separate continuous ramp; floor cut at southwest.
    k.slab(-16,-52,22,-25,5.5,0.35,"d7_marble")
    k.slab(-22,-27,-16,-22,5.5,0.35,"d7_marble")
    k.slab(-22,-22,22,52,5.5,0.35,"d7_marble")
    k.ramp(Vector3(-19,0,-51),Vector3(-19,5.5,-27),3.5,0.3,"d7_marble")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-48))
    add_arrival("from_L005_3",Vector3(0,0.1,-48))
    add_arrival("from_L005",Vector3(0,0.1,-48))
    add_exit("L005_3>L005#2","interact",Vector3(0,1.2,-53),Vector3(4.5,2.5,2.3),"Exit toward the Terror Hotel")
    var loop_door:=add_exit("L005_3>L005_3#1","condition",Vector3(0,1.3,52),Vector3(4,2.6,2.7),"Wooden door at the end of the aisle")
    loop_door.condition=func()->bool:return _volumes_read>=2
    for i in 4:
        var n:int=i
        add_interactable(Vector3(-8+float(i%2)*16,1.1,-23+float(int(i/2))*31),Vector3(2.1,2.0,2.0),"Read a strange catalogue",func():_catalogue(n))
    add_note("mind","LIBRARY MIND","The library seems to remember every book you open, though no librarian has appeared.",Vector3(3,0.8,-40))
    add_landmark("Marble reading hall",Vector3(0,0,-22))
    add_landmark("Wooden end door",Vector3(0,0,52))
    add_shot("marble_vault",Vector3(0,1.6,-48),Vector3(0,4.1,26))
    add_shot("upper_gallery",Vector3(14,5.9,-30),Vector3(0,3.9,29))
    ModelDress.decorate(self, "L005_3")

func _catalogue(n:int)->void:
    _volumes_read+=1
    Overlay.subtitle("[a catalogue entry moves while you read volume %d]"%(n+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"library routes sourced","ok":exits.size()==2},{"what":"loop door starts locked","ok":_volumes_read==0}]
