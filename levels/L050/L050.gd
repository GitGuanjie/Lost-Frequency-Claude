extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
## Roadside desert at a one-way threshold. Vehicles frozen between traffic lanes.
var _vehicles:=0
var _inspect_count:=0
func build()->void:
    rules["view_distance"]=480.0
    outdoor_env(Color(0.49,0.47,0.41),Color(0.73,0.64,0.48),Color(0.36,0.31,0.22),Vector2(15,25),Color(0.91,0.81,0.65),0.71,Color(0.61,0.54,0.40),0.006)
    MatLib.define("l50_sand",{"albedo_a":Color(0.47,0.40,0.29),"albedo_b":Color(0.59,0.50,0.37)},"sand")
    MatLib.define("l50_road",{"albedo_a":Color(0.20,0.20,0.19),"albedo_b":Color(0.29,0.28,0.26)},"asphalt")
    MatLib.define("l50_vehicle",{"albedo_a":Color(0.42,0.40,0.37),"albedo_b":Color(0.31,0.31,0.32)},"metal")
    lights.setup(3,0)
    var k:=kit("MoribundRoad")
    k.slab(-95,-160,95,160,0,0.5,"l50_sand")
    k.slab(-19,-160,19,160,0.05,0.12,"l50_road")
    for i in 39:
        var z:float=-151.0+float(i)*8.0
        k.box(Vector3(0,0.14,z),Vector3(0.28,0.08,3.4),"l50_sand",GeoKit.ALL,false)
    for i in 17:
        var x:float=-10.0 if i%2==0 else 10.0
        var z:float=-135+float(i)*16.0
        k.box(Vector3(x,0.90,z),Vector3(3.8,1.5,7.0),"l50_vehicle")
        k.box(Vector3(x,1.8,z-1.3),Vector3(3.0,0.5,3.1),"l50_vehicle",GeoKit.ALL,false)
        _vehicles+=1
    for i in 30:
        var x:float=rng.randf_range(27,83)*(1 if i%2==0 else -1)
        var z:float=rng.randf_range(-142,142)
        if absf(x-67.0)<22.0 and absf(z-65.0)<27.0:continue
        k.box(Vector3(x,0.25,z),Vector3(3.0,0.5,2.5),"l50_sand")
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "DesertRoadSignalDeck", Vector3(67, 0, 65), 4, 3.5, "l50_sand", "l50_vehicle", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "DesertRoadSignalDeck")
    add_arrival("start",Vector3(0,0.08,-145))
    add_arrival("from_L025",Vector3(0,0.08,-145))
    add_arrival("from_L049",Vector3(0,0.08,-145))
    # No deterministic named destination in this narrative: do not create one.
    for i in 3:
        add_interactable(Vector3(-10.0 if i%2==0 else 10.0,1.1,-110+float(i)*42),Vector3(4,2,7),"Inspect motionless car",func():_inspect())
    add_note("road","ROAD RECORD","Vehicles stand mid-movement on a silent highway. The description offers no reliable mapped exit.",Vector3(21,1,-135))
    add_shot("silent_lanes",Vector3(0,1.62,-144),Vector3(0,1.6,60))
    add_shot("stalled_traffic",Vector3(25,1.62,-20),Vector3(-4,1.3,37))
    add_landmark("Traffic frozen between lanes",Vector3(0,0,0))
    sound.bed("wind",{"seconds":8.0},-35.0)
    ModelDress.decorate(self, "L050")

func _inspect()->void:
    _inspect_count+=1
    Overlay.subtitle("[the engine is cold, but the wheels seem poised to turn]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"stationary vehicles","ok":_vehicles==17},{"what":"no fabricated destination","ok":exits.is_empty()},{"what":"vehicles initially unexamined","ok":_inspect_count==0}]
