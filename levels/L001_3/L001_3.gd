extends LevelBase
var _detox:=0
func build()->void:
    indoor_env(Color(0.93,0.96,1.0),0.91,Color(0.9,0.96,1.0),0.002)
    MatLib.define("d6_clinic",{"albedo_a":Color(0.93,0.94,0.94),"albedo_b":Color(0.99,0.99,0.98)},"tile")
    MatLib.define("d6_medicine",{"albedo_a":Color(0.65,0.77,0.80),"albedo_b":Color(0.82,0.90,0.91)},"plaster")
    lights.setup(10,0)
    var k:=kit("WhiteHalls")
    k.slab(-25,-88,25,88,0,0.4,"d6_clinic")
    k.box(Vector3(0,5.3,0),Vector3(51,0.3,176),"d6_clinic")
    for x in [-24.5,24.5]:k.box(Vector3(x,2.6,0),Vector3(0.5,5.2,176),"d6_clinic")
    for i in 16:
        var z:float=-72+float(i)*9.5
        var x:float=-15.0 if i%2==0 else 15.0
        var gate_x:float=-6.0 if i%2==0 else 6.0
        # Each side room has a doorway opening in its corridor wall, plus
        # two partition walls. The 16 rooms do not block the axial hallway.
        k.box(Vector3(gate_x,2.4,z-3.3),Vector3(0.35,4.8,2.8),"d6_clinic")
        k.box(Vector3(gate_x,2.4,z+3.3),Vector3(0.35,4.8,2.8),"d6_clinic")
        for side in [-4.65,4.65]:
            k.box(Vector3(x,2.4,z+side),Vector3(18,4.8,0.32),"d6_clinic")
        k.box(Vector3(x,0.62,z),Vector3(3.0,1.2,2.3),"d6_medicine")
        k.box(Vector3(x,4.96,z),Vector3(5.5,0.10,2),"d6_clinic",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-80))
    add_arrival("from_L001",Vector3(0,0.1,-80))
    add_exit("L001_3>L001#1","noclip",Vector3(0,1.2,84),Vector3(6,2.8,3),"Pass through the end wall")
    for i in 4:
        add_interactable(Vector3(-9 if i%2==0 else 9,1,-60+float(i)*39),Vector3(3,2,3),"Rest in an unoccupied detox room",func():_rest())
    add_note("medical","DETOX REPORT","Detox rooms restore slowly, with a painful sensation. The corrupted version is much less safe.",Vector3(3,1,-70))
    add_landmark("Sixteen treatment-room corridor",Vector3(0,0,0))
    add_landmark("White end wall",Vector3(0,0,84))
    add_shot("blinding_medical_hall",Vector3(0,1.7,-79),Vector3(0,2,78))
    add_shot("detox_cubicles",Vector3(12,1.6,10),Vector3(-10,1,50))
    sound.bed("room_tone",{"seconds":9.0},-42.0)
func _rest()->void:
    _detox+=1
    Overlay.subtitle("[the ache softens; no instant recovery is guaranteed]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"one sourced noclip exit","ok":exits.size()==1},{"what":"detox action starts unused","ok":_detox==0}]
