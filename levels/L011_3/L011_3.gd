extends LevelBase
var _exposure:=0.0
var _masked:=false
func build()->void:
    rules["view_distance"]=180.0
    outdoor_env(Color(0.08,0.016,0.017),Color(0.18,0.035,0.033),Color(0.03,0.012,0.016),Vector2(9,72),Color(0.43,0.12,0.11),0.32,Color(0.20,0.04,0.045),0.047)
    MatLib.define("d6_city",{"albedo_a":Color(0.20,0.20,0.22),"albedo_b":Color(0.27,0.26,0.28)},"concrete")
    MatLib.define("d6_glow",{"albedo_a":Color(0.63,0.09,0.10),"albedo_b":Color(0.88,0.15,0.15)},"plaster")
    lights.setup(7,0)
    var k:=kit("RedLightDistrict")
    k.slab(-108,-128,108,128,0,0.55,"d6_city")
    for i in 48:
        var x:float=-92+float(i%8)*26
        var z:float=-103+float(int(i/8))*39
        if absf(x)<13 or absf(z)<11:continue
        var h:float=7+float(i%7)*5
        k.box(Vector3(x,h/2,z),Vector3(13,h,17),"d6_city")
        for j in 3:
            k.box(Vector3(x+6.6,2+float(j)*3,z),Vector3(0.13,1.1,3.0),"d6_glow",GeoKit.ALL,false)
    k.slab(-10,112,10,153,0.1,0.5,"d6_city")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-121))
    add_arrival("from_L011",Vector3(0,0.1,-121))
    add_exit("L011_3>L011#1","walk_in",Vector3(0,1.4,144),Vector3(8,3,7),"Bridge over the outskirts")
    add_interactable(Vector3(7,1,-108),Vector3(2,2,2),"Adjust improvised breathing mask",func():_mask())
    add_note("red","RED AIR INCIDENT","The red air causes hallucinations; masks may mitigate the effect. The Servants and their combat behavior are not simulated.",Vector3(-5,1,-110))
    add_landmark("Red-light buildings",Vector3(0,0,0))
    add_landmark("Outskirts bridge",Vector3(0,0,135))
    add_shot("red_city",Vector3(0,1.7,-115),Vector3(39,12,40))
    add_shot("bridge_escape",Vector3(0,1.7,93),Vector3(0,2,148))
    sound.bed("wind",{"seconds":7.0},-37.0)
func _mask()->void:
    _masked=not _masked
    Overlay.subtitle("[mask %s]" % ("on" if _masked else "off"),2.6)
func level_process(delta:float)->void:
    if not _masked:_exposure+=delta
    if _exposure>50.0 and int(_exposure)%25==0 and not SessionState.is_qa():
        if randf()<0.002:Overlay.subtitle("[there seems to be someone at the end of the street]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"perimeter bridge is sourced","ok":exits.size()==1},{"what":"mask starts unused","ok":not _masked}]
