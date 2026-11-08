extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
## Open amusement-park plaza with source-labelled arches back to four playable destinations.
var _rides:=0
var _activated:Dictionary={}
func build()->void:
    rules["view_distance"]=440.0
    outdoor_env(Color(0.41,0.63,0.78),Color(0.89,0.78,0.66),Color(0.23,0.32,0.22),Vector2(43,20),Color(0.99,0.88,0.71),0.80,Color(0.46,0.59,0.52),0.0012)
    MatLib.define("l320_path",{"albedo_a":Color(0.64,0.63,0.59),"albedo_b":Color(0.57,0.56,0.51)},"concrete")
    MatLib.define("l320_paint",{"albedo_a":Color(0.73,0.27,0.34),"albedo_b":Color(0.91,0.46,0.39)},"metal")
    MatLib.define("l320_green",{"albedo_a":Color(0.30,0.52,0.32),"albedo_b":Color(0.19,0.41,0.25)},"grass")
    MatLib.register("l320_glow",MatLib.panel(Color(1.0,0.75,0.40),0.9))
    lights.setup(9,0)
    _park()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "SilentRideWestTransit", Vector3(-60, 0, -50), 5, 3.5, "l320_path", "l320_paint", false, 1, true)
    AtriumWeave.install(self, "SilentRideWestTransit")
    SpatialBranchworks.install(self, "SilentRideEastTransit", Vector3(65, 0, -50), 5, 3.5, "l320_path", "l320_paint", false, -1)
    SpatialBranchworks.link_sites(self, "L320_DualPortal", Vector3(-60, 0, -50), Vector3(65, 0, -50), 5, 3.5, "l320_path", "l320_paint")
    add_arrival("start",Vector3(0,0.08,-117))
    add_exit("L320>L001#1","interact",Vector3(-26,1.4,-110),Vector3(3.2,2.8,2),"Archway: Level 1")
    add_exit("L320>L009#2","interact",Vector3(-13,1.4,-110),Vector3(3.2,2.8,2),"Archway: Level 9")
    add_exit("L320>L011#3","interact",Vector3(0,1.4,-110),Vector3(3.2,2.8,2),"Archway: Level 11")
    add_exit("L320>L048#5","interact",Vector3(13,1.4,-110),Vector3(3.2,2.8,2),"Archway: Level 48")
    add_landmark("The numbered archway plaza",Vector3(0,0,-110))
    add_landmark("Suspended wheel of lights",Vector3(0,2,38))
    add_landmark("Closed carousel and food kiosks",Vector3(-66,0,44))
    add_landmark("Quiet water rides",Vector3(69,0,50))
    add_shot("gates",Vector3(0,1.62,-116),Vector3(-11,3,-75))
    add_shot("park_core",Vector3(0,1.62,-57),Vector3(0,21,35))
    sound.bed("wind",{"seconds":7.0},-34.0)
    ModelDress.decorate(self, "L320")

func _park()->void:
    var k:=kit("NewEntertainland")
    k.slab(-125,-130,125,130,0,0.45,"l320_green")
    k.slab(-34,-129,34,120,0.08,0.24,"l320_path")
    k.slab(-115,15,115,69,0.09,0.23,"l320_path")
    # Row of source-labelled arches; only four with actual playable destinations.
    for i in 11:
        var x:float=-65.0+float(i)*13.0
        var z:float=-110.0
        for side in [-2.1,2.1]:
            k.box(Vector3(x+side,2.1,z),Vector3(0.4,4.2,0.9),"l320_paint")
        k.box(Vector3(x,4.3,z),Vector3(5,0.5,1.0),"l320_glow",GeoKit.ALL,false)
    # Ferris wheel is a visual silhouette with 24 noncolliding cabins; no fake physics ride.
    for i in 24:
        var a:float=TAU*float(i)/24.0
        var x:float=cos(a)*20.0
        var y:float=23.0+sin(a)*20.0
        k.box(Vector3(x,y,40),Vector3(2.3,1.6,1.2),"l320_paint",GeoKit.ALL,false)
    for x in [-13.0,13.0]:
        k.box(Vector3(x,12,40),Vector3(1,24,1),"l320_paint")
    for i in 12:
        var a:float=TAU*float(i)/12.0
        var x:float=-67+cos(a)*16.0
        var z:float=46+sin(a)*16.0
        k.box(Vector3(x,1.2,z),Vector3(2.2,2.4,1.8),"l320_paint")
        k.box(Vector3(x,3.0,z),Vector3(3.5,0.2,2.5),"l320_glow",GeoKit.ALL,false)
    for i in 10:
        var x:float=57+float(i%5)*7.2
        var z:float=35+float(int(i/5))*18.0
        k.box(Vector3(x,0.7,z),Vector3(4.0,1.4,3.4),"l320_path")
    for i in 16:
        var x:float=-109+float(i%4)*12.0
        var z:float=-15+float(int(i/4))*12.0
        k.box(Vector3(x,1.2,z),Vector3(6,2.4,4.0),"l320_paint")
        k.box(Vector3(x,2.6,z),Vector3(6.5,0.2,4.4),"l320_glow",GeoKit.ALL,false)
    k.commit()
    for i in 4:
        var ride:int=i
        add_interactable(Vector3(-72+float(i)*18,1.1,22),Vector3(2,2,2),"Inspect silent ride %d"%(i+1),func():_ride(ride))
    add_note("arch","ARCHWAY PLAZA","The labelled arches were advertised as return paths. Many destinations remain inaccessible.",Vector3(4,0.9,-104))
    add_note("park","ENTERTAINLAND OPERATING LOG","This resort has been re-opened and renamed. The rides are strangely quiet.",Vector3(-28,0.9,-37))
func _ride(index:int)->void:
    _activated[index]=true
    _rides=_activated.size()
    Overlay.subtitle("[ride %d hums for a moment, then stops]"%(index+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"four source-verified archways","ok":exits.size()==4},{"what":"park explorations start unvisited","ok":_rides==0},{"what":"four landmark zones","ok":landmarks.size()==4}]
