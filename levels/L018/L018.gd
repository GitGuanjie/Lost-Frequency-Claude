extends LevelBase
var _memories:=0
func build()->void:
    indoor_env(Color(0.84,0.75,0.73),0.72,Color(0.78,0.69,0.65),0.002)
    MatLib.define("d6_coral",{"albedo_a":Color(0.97,0.72,0.68),"albedo_b":Color(0.87,0.60,0.57)},"plaster")
    MatLib.define("d6_cream",{"albedo_a":Color(0.91,0.87,0.75),"albedo_b":Color(0.98,0.94,0.87)},"plaster")
    MatLib.define("d6_soft",{"albedo_a":Color(0.66,0.70,0.81),"albedo_b":Color(0.79,0.81,0.91)},"carpet")
    MatLib.define("d6_wood",{"albedo_a":Color(0.48,0.35,0.27),"albedo_b":Color(0.63,0.49,0.33)},"wood_floor")
    lights.setup(6,0)
    var k:=kit("MemoriesPreschool")
    k.slab(-26,-37,26,37,0,0.5,"d6_soft")
    k.box(Vector3(0,4.6,0),Vector3(53,0.3,75),"d6_cream")
    for x in [-26.0,26.0]:k.box(Vector3(x,2.3,0),Vector3(0.4,4.6,74),"d6_cream")
    for z in [-37.0,37.0]:k.box(Vector3(0,2.3,z),Vector3(52,4.6,0.4),"d6_coral")
    for x in [-15.0,15.0]:
        k.box(Vector3(x,2.2,13),Vector3(0.4,4.4,41),"d6_cream")
    for i in 18:
        var x:float=-20+float(i%6)*7.3
        var z:float=-18+float(int(i/6))*9
        k.box(Vector3(x,0.48,z),Vector3(2.6,0.36,1.6),"d6_wood")
        for dx in [-0.9,0.9]:k.box(Vector3(x+dx,0.22,z),Vector3(0.13,0.45,0.15),"d6_wood")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-31))
    add_arrival("from_L019",Vector3(0,0.1,-31))
    add_exit("L018>L019#1","walk_in",Vector3(0,1.3,-34),Vector3(4,2.7,3),"Turn around and leave")
    for i in 3:
        var index:int=i
        add_interactable(Vector3(-21+float(i)*18,1,20),Vector3(2.4,2,2.2),"Examine familiar toy",func():_remember(index))
    add_note("regret","UNSENT LETTER","The whispers seem to recall small things never said aloud. There is no hostile presence in this room.",Vector3(0,0.8,11))
    add_landmark("Preschool entrance",Vector3(0,0,-31))
    add_landmark("Toy shelves",Vector3(0,0,22))
    add_shot("daycare_entrance",Vector3(0,1.45,-28),Vector3(0,1.1,20))
    add_shot("small_desks",Vector3(18,1.45,6),Vector3(-13,1.0,-9))
    sound.bed("room_tone",{"seconds":9.0},-39.0)
func _remember(_i:int)->void:
    _memories+=1
    Overlay.subtitle("[something from a childhood you cannot quite place]",3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"return is source-backed","ok":exits.size()==1},{"what":"player starts with zero memories","ok":_memories==0}]
