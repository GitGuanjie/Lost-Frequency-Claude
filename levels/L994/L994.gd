extends LevelBase
var _tide_clock:=0.0
var _water_warning:=false
func build()->void:
    rules["view_distance"]=230.0
    outdoor_env(Color(0.40,0.49,0.59),Color(0.69,0.67,0.64),Color(0.45,0.43,0.40),Vector2(32,-75),Color(0.91,0.90,0.85),0.65,Color(0.63,0.66,0.68),0.008)
    MatLib.define("d7_sand",{"albedo_a":Color(0.72,0.69,0.63),"albedo_b":Color(0.83,0.79,0.71)},"sand")
    MatLib.define("d7_mountain",{"albedo_a":Color(0.32,0.37,0.39),"albedo_b":Color(0.48,0.48,0.47)},"rock")
    MatLib.register("d7_ocean",MatLib.water({"shallow_color":Color(0.23,0.39,0.47),"deep_color":Color(0.07,0.15,0.21),"wave_height":0.12}))
    var k:=kit("EmptyEastBeach")
    k.slab(-88,-86,52,86,0,0.55,"d7_sand")
    for i in 16:
        var z:float=-78.0+float(i)*10.1
        k.box(Vector3(-88,16.0+float(i%3)*4,z),Vector3(12,32.0+float(i%3)*8,13),"d7_mountain")
        k.box(Vector3(0,19,-92),Vector3(165,38,12),"d7_mountain")
        k.box(Vector3(0,21,92),Vector3(165,42,12),"d7_mountain")
    k.commit()
    var sea:=WaterVolume.new();add_child(sea)
    sea.setup(Vector3(52,-2,-87),Vector3(160,-0.2,87),"d7_ocean",true)
    add_arrival("start",Vector3(-33,0.1,0),90)
    add_note("tide","A NOTE IN THE SAND","The tide is irregular. The water sounds as if it is calling, but the beach is otherwise empty.",Vector3(-19,0.8,-5))
    add_interactable(Vector3(-36,1.0,2),Vector3(3,2,3),"Look back to the mountain gap",func():Overlay.subtitle("[the only reliable return is the way you arrived]",4.0))
    add_landmark("Mountain passage",Vector3(-75,0,0))
    add_landmark("East-facing tidal water",Vector3(50,0,0))
    add_shot("tide_from_beach",Vector3(-31,1.6,2),Vector3(100,1,4))
    add_shot("mountain_ring",Vector3(16,1.6,-15),Vector3(-78,22,4))
    sound.bed("wind",{"seconds":7.0},-33.0)
func level_process(delta:float)->void:
    _tide_clock+=delta
    if not _water_warning and _tide_clock>105.0:
        _water_warning=true
        Overlay.subtitle("[the sea grows louder; the tide is not following a schedule]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no imaginary linked destination","ok":exits.is_empty()},{"what":"arrival grounded in sand","ok":arrivals.has("start")},{"what":"two camera views","ok":qa_shots.size()>=2}]
