extends LevelBase
var _silence:=0.0
func build()->void:
    indoor_env(Color(0.12,0.13,0.14),0.16,Color(0.07,0.09,0.12),0.012)
    MatLib.define("d6_inv",{"albedo_a":Color(0.89,0.89,0.92),"albedo_b":Color(0.96,0.96,0.98)},"plaster")
    MatLib.define("d6_shadow",{"albedo_a":Color(0.09,0.09,0.11),"albedo_b":Color(0.16,0.16,0.18)},"tile")
    lights.setup(2,0)
    var k:=kit("InvertedHalls")
    k.slab(-30,-55,30,55,0,0.4,"d6_shadow")
    for x in [-30.0,30.0]:k.box(Vector3(x,3,0),Vector3(0.6,6,110),"d6_inv")
    for z in [-55.0,55.0]:k.box(Vector3(0,3,z),Vector3(60,6,0.6),"d6_inv")
    for i in 6:
        var z:float=-42+float(i)*17
        k.box(Vector3(-16,3,z),Vector3(1,6,11),"d6_inv")
        k.box(Vector3(16,3,z+8),Vector3(1,6,11),"d6_inv")
        k.box(Vector3(0,6,z),Vector3(11,0.4,10),"d6_inv",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-48))
    add_arrival("from_L188",Vector3(0,0.1,-48))
    add_arrival("from_L021",Vector3(0,0.1,-48))
    add_arrival("from_L001",Vector3(0,0.1,-48))
    for i in 3:
        add_interactable(Vector3(0,1,-20+float(i)*27),Vector3(3,2.5,3),"Listen for the fading whispers",func():_listen())
    add_note("inverse","LUMINANCE ANOMALY","The brightest shapes become dark; the shadows appear to supply the light. No exit destination has been verified.",Vector3(2,1,-42))
    add_landmark("Inverse ceiling panels",Vector3(0,5,-17))
    add_landmark("Door without destination",Vector3(0,0,48))
    add_shot("inverse_hall",Vector3(0,1.6,-45),Vector3(0,2,44))
    add_shot("white_room",Vector3(20,1.6,8),Vector3(-10,2,28))
    sound.bed("room_tone",{"seconds":9.0},-45.0)
func _listen()->void:
    _silence+=1.0
    Overlay.subtitle("[the whisper moves farther away as you approach]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no arbitrary destinations for unspecified noclip","ok":exits.is_empty()},{"what":"whispers start unobserved","ok":_silence==0.0}]
