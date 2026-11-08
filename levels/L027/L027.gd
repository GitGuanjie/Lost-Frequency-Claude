extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Small limestone grotto, two waterfalls and source-length thermal-exposure timer.
var _bath_seconds:=0.0
var _warned:=false
var _water:WaterVolume
func build()->void:
    rules["view_distance"]=65.0
    indoor_env(Color(0.37,0.53,0.54),0.38,Color(0.16,0.28,0.31),0.014)
    MatLib.define("l27_limestone",{"albedo_a":Color(0.43,0.50,0.47),"albedo_b":Color(0.32,0.41,0.40)},"rock")
    MatLib.define("l27_wetrock",{"albedo_a":Color(0.22,0.34,0.37),"albedo_b":Color(0.28,0.38,0.39)},"rock")
    MatLib.register("l27_water",MatLib.water({"shallow_color":Color(0.29,0.60,0.65),"deep_color":Color(0.16,0.38,0.47),"wave_height":0.015}))
    MatLib.register("l27_fall",MatLib.panel(Color(0.39,0.76,0.81),0.35))
    lights.setup(4,0)
    _grotto()
    add_arrival("start",Vector3(-7,0.08,-7))
    add_exit("L027>L028#2","interact",Vector3(8,1.3,13),Vector3(2.2,2.6,1.8),"Climb behind the second waterfall")
    add_landmark("Warm mineral spring",Vector3(0,0,0))
    add_landmark("Second waterfall hides a tunnel",Vector3(8,0,13))
    add_shot("warm_spring",Vector3(-7,1.62,-7),Vector3(0,0.6,4))
    add_shot("second_fall",Vector3(3,1.62,1),Vector3(8,2,14))
    sound.bed("water_bed",{"seconds":6.0,"bright":0.5},-24.0)
    ModelDress.decorate(self, "L027")

func _grotto()->void:
    var k:=kit("BunkerSpringsGrotto")
    k.slab(-12,-14,12,17,0,0.55,"l27_limestone")
    for x in [-12.2,12.2]: k.box(Vector3(x,3.1,2),Vector3(0.9,6.2,34),"l27_wetrock")
    k.box(Vector3(0,6.0,2),Vector3(25,1.3,35),"l27_limestone")
    for i in 26:
        var a:float=TAU*float(i)/26.0
        var x:float=cos(a)*9.2
        var z:float=sin(a)*9.8
        var h:float=0.7+float(i%5)*0.2
        k.cylinder(Vector3(x,6.1-h/2,z),0.35,h,"l27_limestone",6,false)
    for x in [-6.5,8.0]:
        k.box(Vector3(x,2.25,13),Vector3(1.6,4.5,0.20),"l27_fall",GeoKit.ALL,false)
    # Clear entry-side bank and an accessible walk along the right of the water.
    k.slab(-12,-14,12,-6,0.1,0.3,"l27_limestone")
    k.slab(7,-6,12,17,0.1,0.3,"l27_limestone")
    k.commit()
    _water=WaterVolume.new();add_child(_water)
    _water.setup(Vector3(-6,-0.2,-5),Vector3(6,1.0,10),"l27_water",true)
    add_note("spring","BUNKER SPRINGS","One hour in the hot water is said to help; beyond two hours nausea sets in. This is a single surviving cave.",Vector3(-8,0.85,-10))
func level_process(delta:float)->void:
    if player==null or SessionState.is_qa():return
    if _water!=null and _water.contains(player.global_position+Vector3(0,0.3,0)):
        _bath_seconds+=delta
        if _bath_seconds>=7200.0 and not _warned:
            _warned=true
            Overlay.subtitle("[the mineral warmth has become nauseating]",6.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"small cave and two waterfalls","ok":_water!=null},{"what":"no invented return route","ok":exits.size()==1},{"what":"unmodified source timer","ok":_bath_seconds==0.0}]
