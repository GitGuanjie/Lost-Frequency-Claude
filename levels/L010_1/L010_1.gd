extends LevelBase
var _exposure:=0.0
var _warning_stage:=0
func build()->void:
    rules["view_distance"]=360.0
    outdoor_env(Color(0.39,0.51,0.53),Color(0.64,0.68,0.65),Color(0.20,0.25,0.21),Vector2(44,72),Color(0.89,0.84,0.73),0.65,Color(0.47,0.48,0.45),0.012)
    MatLib.define("d6_pond",{"albedo_a":Color(0.30,0.035,0.043),"albedo_b":Color(0.46,0.056,0.064)},"water")
    MatLib.define("d6_shore",{"albedo_a":Color(0.32,0.41,0.31),"albedo_b":Color(0.45,0.48,0.34)},"grass")
    MatLib.define("d6_fence",{"albedo_a":Color(0.32,0.34,0.31),"albedo_b":Color(0.47,0.49,0.46)},"metal")
    lights.setup(2,0)
    var k:=kit("ContaminatedLake")
    k.slab(-112,-110,112,110,0,0.65,"d6_shore")
    k.slab(-65,-65,65,65,0.07,0.02,"d6_pond")
    for x in [-89.0,89.0]:
        for i in 18:k.box(Vector3(x,1.25,-90+float(i)*10),Vector3(0.14,2.5,0.14),"d6_fence")
    for z in [-89.0,89.0]:
        for i in 18:k.box(Vector3(-90+float(i)*10,1.25,z),Vector3(0.14,2.5,0.14),"d6_fence")
    k.commit()
    add_arrival("start",Vector3(0,0.1,-101))
    add_arrival("from_L010",Vector3(0,0.1,-101))
    # Exclusion-zone escape is conditional and cannot be honestly represented as a free teleporter.
    add_interactable(Vector3(5,1,-92),Vector3(3,2,3),"Read the radiation warning",func():Overlay.subtitle("[7 Sv/h reported in the exclusion zone. Leave the perimeter immediately.]",4.2))
    add_note("radiation","EXCLUSION ZONE","The original depression route is sealed or one-way. This prototype does not offer a fictitious safe return.",Vector3(-5,1,-92))
    add_landmark("Barbed-wire perimeter",Vector3(0,0,-90))
    add_landmark("Crimson lake",Vector3(0,0,0))
    add_shot("contaminated_basin",Vector3(0,1.6,-98),Vector3(0,1.3,-12))
    add_shot("perimeter",Vector3(93,1.8,-78),Vector3(0,1,0))
    sound.bed("wind",{"seconds":7.0},-33.0)
func level_process(delta:float)->void:
    if player!=null and not SessionState.is_qa():
        var p:Vector3=player.global_position
        var dist:float=Vector2(p.x,p.z).length()
        if dist<90.0:
            _exposure+=delta
            if _exposure>20.0:
                player.hurt(0.11*delta,"Radiation exposure at the lake")
            if absf(p.x)<65.0 and absf(p.z)<65.0:
                player.hurt(3.0*delta,"Contact with contaminated lake")
    if _exposure>120.0 and _warning_stage==0:
        _warning_stage=1
        if not SessionState.is_qa():Overlay.subtitle("[radiation exposure is continuing]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unknown escape not invented","ok":exits.is_empty()},{"what":"exposure starts clear","ok":_warning_stage==0}]
