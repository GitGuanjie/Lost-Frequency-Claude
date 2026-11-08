extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
var _distance:=0.0
var _vehicle_safe:=true
func build()->void:
    rules["view_distance"]=180.0
    outdoor_env(Color(0.015,0.018,0.024),Color(0.045,0.048,0.055),Color(0.015,0.018,0.02),Vector2(6,90),Color(0.17,0.20,0.22),0.2,Color(0.06,0.07,0.09),0.052)
    MatLib.define("d6_asphalt",{"albedo_a":Color(0.12,0.13,0.14),"albedo_b":Color(0.17,0.18,0.20)},"concrete")
    MatLib.define("d6_barrier",{"albedo_a":Color(0.29,0.30,0.32),"albedo_b":Color(0.40,0.41,0.43)},"concrete")
    MatLib.define("d6_car",{"albedo_a":Color(0.30,0.34,0.42),"albedo_b":Color(0.48,0.51,0.56)},"metal")
    lights.setup(3,0)
    var k:=kit("RoadTrip")
    k.slab(-12,-250,12,250,0,0.6,"d6_asphalt")
    for x in [-12.0,12.0]:k.box(Vector3(x,7,0),Vector3(1.4,14,500),"d6_barrier")
    for i in 40:
        k.box(Vector3(0,0.02,-236+float(i)*12),Vector3(0.18,0.02,4),"d6_barrier",GeoKit.ALL,false)
    k.box(Vector3(0,0.8,-214),Vector3(4.5,1.6,9),"d6_car")
    k.box(Vector3(0,1.9,-217.0),Vector3(4.4,0.9,2.3),"d6_car")
    for x in [-1.6,1.6]:
        k.cylinder(Vector3(x,0.52,-211),0.7,1.05,"d6_asphalt",8)
        k.cylinder(Vector3(x,0.52,-217),0.7,1.05,"d6_asphalt",8)
    k.commit()
    add_arrival("start",Vector3(6,0.1,-219))
    add_arrival("from_L003",Vector3(6,0.1,-219))
    add_arrival("from_L008",Vector3(6,0.1,-219))
    add_arrival("from_L022",Vector3(6,0.1,-219))
    # The 17-hour drive has not been implemented: reaching a short tunnel is not sufficient.
    var e:=add_exit("L069>L011#1","condition",Vector3(0,1.3,242),Vector3(7,3.0,12),"Tunnel beyond the long drive")
    e.condition=func()->bool:return _distance>=1000.0 and _vehicle_safe
    add_exit("L069>L022#2","noclip",Vector3(10.0,1.4,-12),Vector3(3,2.7,5),"Roadside wall")
    add_interactable(Vector3(5,1,-214),Vector3(2,2,3),"Inspect the stationary vehicle",func():Overlay.subtitle("[this prototype cannot simulate the full drive; tunnel remains locked]",4.0))
    add_note("route","ROAD WARNING","The car is the reported refuge; the full driving model and off-road threat are not yet implemented.",Vector3(7,1,-205))
    add_landmark("Vehicle at roadside",Vector3(0,0,-214))
    add_landmark("Roadside wall seam",Vector3(10,0,-12))
    add_shot("vehicle_in_dark",Vector3(6,1.6,-236),Vector3(0,1,-213))
    add_shot("empty_highway",Vector3(0,1.6,-160),Vector3(0,1.4,230))
    sound.bed("wind",{"seconds":9.0},-36.0)
    ModelDress.decorate(self, "L069")

func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"car simulation not falsely completed","ok":_distance==0.0},{"what":"two source routes exist","ok":exits.size()==2}]
