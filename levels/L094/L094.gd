extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
## Motion: a stop-motion town, safe in daylight, floating castle and abnormal night.
var _night:=false
var _time:=0.0
var _visited:Dictionary={}
func build()->void:
    rules["view_distance"]=490.0
    outdoor_env(Color(0.55,0.69,0.82),Color(0.86,0.81,0.63),Color(0.36,0.48,0.33),Vector2(45,15),Color(1,0.92,0.73),0.73,Color(0.58,0.61,0.54),0.003)
    MatLib.define("l94_grass",{"albedo_a":Color(0.39,0.59,0.35),"albedo_b":Color(0.26,0.45,0.28)},"grass")
    MatLib.define("l94_house",{"albedo_a":Color(0.83,0.70,0.55),"albedo_b":Color(0.69,0.63,0.52)},"plaster")
    MatLib.define("l94_roof",{"albedo_a":Color(0.46,0.23,0.24),"albedo_b":Color(0.65,0.32,0.28)},"plaster")
    MatLib.define("l94_water",{"albedo_a":Color(0.33,0.72,0.88),"albedo_b":Color(0.51,0.82,0.93)},"concrete")
    lights.setup(6,0)
    _town()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "ImpossibleTownArcades", Vector3(70, 0, 60), 5, 3.5, "l94_house", "l94_roof", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "ImpossibleTownArcades")
    add_arrival("start",Vector3(0,0.08,-66))
    add_exit("L094>L007#2","interact",Vector3(-32,1.5,8),Vector3(3,2.8,2),"Door back to Level 7")
    add_exit("L094>L009#3","interact",Vector3(0,1.5,8),Vector3(3,2.8,2),"Door back to Level 9")
    add_exit("L094>L053#4","interact",Vector3(32,1.5,8),Vector3(3,2.8,2),"Door back to Level 53")
    add_note("city","MOTION","A handcrafted town. At night the music stops, and the streets are no longer safe.",Vector3(4,1,-50))
    add_landmark("Almond-water fountain",Vector3(0,0,-10))
    add_landmark("Transparent hill and floating castle",Vector3(0,9,69))
    add_landmark("Three houses with documented return doors",Vector3(0,0,8))
    add_shot("market",Vector3(0,1.6,-58),Vector3(0,2,-10))
    add_shot("hill_castle",Vector3(0,1.6,19),Vector3(0,12,70))
    sound.bed("room_tone",{"seconds":6.0},-35.0)
func _town()->void:
    var k:=kit("MotionTownAndCastle")
    k.slab(-105,-80,105,100,0,0.5,"l94_grass")
    k.slab(-52,-56,52,26,0.08,0.2,"l94_house")
    for i in 18:
        var x:float=-82+float(i%6)*32
        var z:float=-40+float(int(i/6))*29
        if absf(x)<9 and z<0:continue
        k.box(Vector3(x,1.4,z),Vector3(9,2.8,8),"l94_house")
        k.box(Vector3(x,3.0,z),Vector3(10.5,0.5,9),"l94_roof")
    k.cylinder(Vector3(0,0.35,-10),6.0,0.6,"l94_house",24)
    k.cylinder(Vector3(0,0.72,-10),4.2,0.14,"l94_water",24,false)
    for x in [-32.0,0.0,32.0]:
        k.box(Vector3(x,1.7,10.5),Vector3(6,3.4,0.5),"l94_house")
        k.box(Vector3(x,1.6,12),Vector3(4,2.8,0.4),"l94_roof",GeoKit.ALL,false)
    # A traversable hill and castle terrace; the elevated castle is reached by steps.
    for i in 4:
        var y:float=float(i)*2.0
        var z:float=32+float(i)*13.0
        k.slab(-15,z,15,z+13,y,0.65,"l94_grass")
    k.stairs(Vector3(0,0.1,31),Vector3(0,0,1),6.0,8.0,40,"l94_house",1.35)
    k.slab(-21,79,21,99,8,0.6,"l94_house")
    for x in [-20.0,20.0]:k.box(Vector3(x,10.3,90),Vector3(1.8,4.6,20),"l94_roof")
    for i in 6:
        var x:float=-16+float(i)*6.0
        k.box(Vector3(x,8.6,94),Vector3(2.2,1.2,1.2),"l94_roof",GeoKit.ALL,false)
    k.commit()
    for i in 3:
        var idx:int=i
        add_interactable(Vector3(-21+float(i)*21,1.1,-22),Vector3(2,2,2),"Examine old-fashioned house",func():_visited[idx]=true)
func level_process(delta:float)->void:
    _time+=delta
    if _time>120.0:
        _time=0.0
        _night=not _night
        environment.ambient_light_energy=0.09 if _night else 0.6
        if not SessionState.is_qa():Overlay.subtitle("[the cartoon music abruptly stops]" if _night else "[the cheerful day returns]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"three source houses","ok":exits.size()==3},{"what":"day begins safe","ok":not _night},{"what":"town not pre-explored","ok":_visited.size()==0}]
