extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
## Two archived topographies; environmental change signaled, not a teleport to an invented level.
var _state:=0
var _switch_clock:=0.0
var _switch_count:=0
func build()->void:
    rules["gravity"]=4.6
    rules["view_distance"]=280.0
    outdoor_env(Color(0.23,0.45,0.49),Color(0.65,0.73,0.59),Color(0.13,0.27,0.19),Vector2(22,75),Color(0.83,0.92,0.78),0.66,Color(0.36,0.48,0.43),0.015)
    MatLib.define("l16_moss",{"albedo_a":Color(0.21,0.38,0.22),"albedo_b":Color(0.32,0.51,0.25)},"grass")
    MatLib.define("l16_ice",{"albedo_a":Color(0.63,0.81,0.87),"albedo_b":Color(0.79,0.88,0.92)},"concrete")
    MatLib.define("l16_wood",{"albedo_a":Color(0.29,0.23,0.18),"albedo_b":Color(0.38,0.29,0.20)},"wood_floor")
    MatLib.define("l16_leaf",{"albedo_a":Color(0.18,0.44,0.25),"albedo_b":Color(0.25,0.58,0.29)},"grass")
    lights.setup(4,0)
    var k:=kit("TwoWeatherTerrains")
    k.slab(-62,-80,62,80,0,0.65,"l16_moss")
    # The separate arctic tract appears beyond a narrow low-gravity forest.
    k.slab(-62,26,62,80,0.08,0.15,"l16_ice")
    for i in 65:
        var x:float=rng.randf_range(-56,56)
        var z:float=rng.randf_range(-72,18)
        if absf(x)<7 and z>-65:continue
        # Tree trunks cannot pierce the new upper canopy walks / open stair shafts.
        if x>15 and x<37 and z>-40 and z<-5:continue
        # DEV27: keep both ascent mouths and the hanging side piers clear.
        if x>-59 and x<13 and z>-58 and z<25:continue
        var h:float=rng.randf_range(7,13)
        k.cylinder(Vector3(x,h*0.5,z),0.35,h,"l16_wood",7)
        k.box(Vector3(x,h,z),Vector3(2.8,1.3,3.0),"l16_leaf",GeoKit.ALL,false)
    for i in 35:
        var x:float=rng.randf_range(-56,56)
        var z:float=rng.randf_range(35,75)
        if absf(x)<6:continue
        k.box(Vector3(x,1.2,z),Vector3(1.8,2.4,2.2),"l16_ice")
    k.commit()
    VerticalArchitecture.install(self, "RainforestCanopy", Vector3(26, 0, -22), 4, 3.4, "l16_wood", "l16_wood")
    add_landmark("Four-tier low-gravity canopy circuit", Vector3(26, 10.2, -22))
    add_arrival("start",Vector3(0,0.08,-70))
    add_exit("L016>L046#1","interact",Vector3(0,1.3,68),Vector3(4,2.8,3),"Sand-covered ice sheet")
    add_note("weather","ARCHIVED WEATHER FILES","Two incompatible records survive: rainforest at dawn; Arctic ice beneath a rapid day/night cycle.",Vector3(-5,1,-63))
    add_landmark("Rainforest low gravity",Vector3(0,0,-38))
    add_landmark("Reflective glacial tract",Vector3(0,0,42))
    add_shot("forest",Vector3(0,1.6,-69),Vector3(-12,3,5))
    add_shot("ice",Vector3(0,1.6,29),Vector3(0,1,67))
    sound.bed("wind",{"seconds":7.0},-32.0)
func level_process(delta:float)->void:
    _switch_clock+=delta
    if _switch_clock>140.0:
        _switch_clock=0.0
        _state=1-_state
        _switch_count+=1
        rules["gravity"]=9.8 if _state==1 else 4.6
        if player!=null:player.apply_rules(rules)
        if not SessionState.is_qa():Overlay.subtitle("[the air shifts; a second archived climate asserts itself]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"arctic exit from source","ok":exits.size()==1},{"what":"rainforest starts low gravity","ok":rules["gravity"]<9.8},{"what":"weather clock resets","ok":_switch_count==0}]
