extends LevelBase
var _strike_clock:=0.0
var _strikes:=0
var _discharge_active:=false
func build()->void:
    rules["view_distance"]=310.0
    outdoor_env(Color(0.015,0.015,0.020),Color(0.045,0.045,0.055),Color(0.02,0.02,0.02),Vector2(26,144),Color(0.36,0.38,0.42),0.32,Color(0.17,0.18,0.19),0.022)
    MatLib.define("d6_elec",{"albedo_a":Color(0.27,0.27,0.28),"albedo_b":Color(0.35,0.36,0.38)},"concrete")
    MatLib.define("d6_spark",{"albedo_a":Color(0.55,0.67,0.76),"albedo_b":Color(0.78,0.83,0.88)},"metal")
    lights.setup(6,0)
    var k:=kit("ElectropolisBrutalism")
    k.slab(-80,-94,80,94,0,1.0,"d6_elec")
    for i in 20:
        var x:float=-67+float(i%5)*33
        var z:float=-72+float(int(i/5))*42
        if absf(x)<15 and z<0:continue
        var h:float=17+float(i%4)*9
        k.box(Vector3(x,h*0.5,z),Vector3(18,h,18),"d6_elec")
        for j in 4:
            k.box(Vector3(x-7+float(j)*4.6,h+1.8,z),Vector3(0.25,3.6,0.35),"d6_spark")
    k.box(Vector3(29,3,40),Vector3(19,6,16),"d6_elec")
    k.box(Vector3(29,8.7,40),Vector3(20,0.4,17),"d6_elec")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-86))
    add_arrival("from_L003",Vector3(0,0.1,-86))
    var shock:=add_exit("L003_5>L003#1","condition",Vector3(0,1.4,77),Vector3(9,3.1,6),"Unstable discharge field")
    shock.condition=func()->bool:return _discharge_active
    add_interactable(Vector3(22,1,34),Vector3(3,2.2,3),"Inspect repurposed tower outpost",func():Overlay.subtitle("[the buildings shield the strongest flashes]",4.0))
    add_note("storm","ELECTROPOLIS","Exposed rooftops attract unpredictable discharge. Returning to Level 3 is tied to dangerous contact, not a normal door.",Vector3(-6,1,-74))
    add_landmark("Sheltered tower outpost",Vector3(0,0,40))
    add_landmark("Active discharge basin",Vector3(0,0,77))
    add_shot("silent_towers",Vector3(0,1.65,-83),Vector3(23,26,30))
    add_shot("discharge_ground",Vector3(0,1.65,40),Vector3(0,4,80))
    sound.bed("room_tone",{"seconds":7.0},-38.0)
func level_process(delta:float)->void:
    _strike_clock+=delta
    _discharge_active=fmod(_strike_clock,22.0)>19.0
    if _strike_clock>22.0:
        _strike_clock=0.0
        _strikes+=1
        if not SessionState.is_qa():Overlay.subtitle("[electrostatic discharge ripples through the city]",3.3)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"conditional discharge inactive at start","ok":not _discharge_active},{"what":"one dangerous documented extraction","ok":exits.size()==1}]
