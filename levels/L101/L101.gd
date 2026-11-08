extends LevelBase
var _discrepancies:=0
func build()->void:
    indoor_env(Color(0.89,0.80,0.69),0.66,Color(0.61,0.54,0.45),0.002)
    MatLib.define("d7_home",{"albedo_a":Color(0.92,0.85,0.74),"albedo_b":Color(0.97,0.92,0.84)},"plaster")
    MatLib.define("d7_furniture",{"albedo_a":Color(0.43,0.29,0.21),"albedo_b":Color(0.56,0.39,0.28)},"wood_floor")
    MatLib.define("d7_curtain",{"albedo_a":Color(0.46,0.51,0.55),"albedo_b":Color(0.64,0.68,0.70)},"carpet")
    lights.setup(6,0)
    var k:=kit("TheNearlyFamiliarHome")
    k.slab(-24,-38,24,38,0,0.55,"d7_furniture")
    k.box(Vector3(0,4.8,0),Vector3(49,0.35,77),"d7_home")
    for x in [-24.0,24.0]:k.box(Vector3(x,2.3,0),Vector3(0.35,4.6,76),"d7_home")
    k.box(Vector3(0,2.3,-38),Vector3(48,4.6,0.35),"d7_home")
    # Rooms interconnect around the central corridor instead of being sealed boxes.
    for z in [-19.0,8.0,28.0]:
        k.box(Vector3(-15,2.3,z),Vector3(18,4.6,0.35),"d7_home")
        k.box(Vector3(15,2.3,z),Vector3(18,4.6,0.35),"d7_home")
    for i in 14:
        var x:float=-17 if i%2==0 else 17
        var z:float=-29+float(int(i/2))*9
        k.box(Vector3(x,0.55,z),Vector3(4,1.1,2.6),"d7_furniture")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-32))
    add_arrival("from_L002",Vector3(0,0.1,-32))
    var back:=add_exit("L101>L000#1","interact",Vector3(0,1.25,34),Vector3(4.0,2.5,4),"Say: I'm ready to go back")
    back.condition=func()->bool:return _discrepancies>=3
    for i in 5:
        var n:int=i
        add_interactable(Vector3(0,1.1,-22+float(i)*12),Vector3(3,2.2,2.5),"Examine a familiar but wrong detail",func():_notice(n))
    add_note("difference","THE HOUSE IS ALMOST RIGHT","You remember this room. There is one impossible detail. You cannot leave without facing the differences.",Vector3(3,0.8,-30))
    add_landmark("Unfamiliar home",Vector3(0,0,-20))
    add_landmark("The spoken return",Vector3(0,0,34))
    add_shot("remembered_hallway",Vector3(0,1.6,-29),Vector3(0,1.3,32))
    add_shot("wrong_room",Vector3(-9,1.6,17),Vector3(14,1.3,-14))
func _notice(n:int)->void:
    _discrepancies+=1
    Overlay.subtitle("[memory %d: something that should be here is missing]"%(n+1),3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"return gated on observing inconsistencies","ok":exits.size()==1 and _discrepancies==0},{"what":"five interactive clues","ok":qa_shots.size()==2}]
