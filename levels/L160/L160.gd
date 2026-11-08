extends LevelBase
var _statements:=0
func build()->void:
    indoor_env(Color(0.28,0.24,0.32),0.22,Color(0.04,0.04,0.07),0.043)
    MatLib.define("d7_pact",{"albedo_a":Color(0.16,0.13,0.19),"albedo_b":Color(0.28,0.22,0.31)},"concrete")
    MatLib.define("d7_echo",{"albedo_a":Color(0.43,0.34,0.48),"albedo_b":Color(0.59,0.46,0.62)},"plaster")
    MatLib.register("d7_light",MatLib.panel(Color(0.58,0.35,0.77),1.2))
    lights.setup(4,0)
    var k:=kit("TheUnspecifiedPactThreshold")
    # Source does not describe a literal city. This is an abstract staging space.
    k.slab(-18,-72,18,72,0,0.5,"d7_pact")
    for i in 10:
        var z:float=-60+float(i)*13
        k.box(Vector3(-10,4,z),Vector3(1.1,8,2.1),"d7_echo")
        k.box(Vector3(10,4,z),Vector3(1.1,8,2.1),"d7_echo")
        k.box(Vector3(0,7.7,z),Vector3(20,0.5,2.0),"d7_pact")
        k.box(Vector3(0,7.1,z),Vector3(5.0,0.18,0.4),"d7_light",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-65))
    add_note("uncertain","SCENE INTERPRETATION","The article gives no reliable physical city layout. These arcades are a non-canonical visualization of the second-person voice, not an invented city.",Vector3(3,0.8,-58))
    for i in 4:
        var n:int=i
        add_interactable(Vector3(2,1.0,-45+float(i)*28),Vector3(3,2,3),"Listen to the voice's promise",func():_promise(n))
    add_landmark("Unseen city threshold",Vector3(0,0,48))
    add_shot("unspoken_pact",Vector3(0,1.7,-63),Vector3(0,4.3,59))
    add_shot("no_city_claim",Vector3(8,1.7,22),Vector3(0,5,66))
    sound.bed("pad",{"root":45,"bright":0.12},-39.0)
func _promise(n:int)->void:
    _statements+=1
    Overlay.subtitle("[the voice promises something it cannot prove: %d]"%(n+1),4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no destination fabricated from monologue","ok":exits.is_empty()},{"what":"pact statements available","ok":_statements==0}]
