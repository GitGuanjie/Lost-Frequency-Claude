extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
var _storms:=0
func build()->void:
    outdoor_env(Color(0.49,0.57,0.64),Color(0.72,0.76,0.78),Color(0.56,0.58,0.59),Vector2(73,-48),Color(0.85,0.87,0.92),0.41,Color(0.43,0.48,0.52),0.029)
    MatLib.define("d7_whitecloud",{"albedo_a":Color(0.87,0.89,0.92),"albedo_b":Color(0.96,0.96,0.97)},"carpet")
    MatLib.define("d7_greycloud",{"albedo_a":Color(0.44,0.47,0.50),"albedo_b":Color(0.59,0.60,0.63)},"carpet")
    MatLib.define("d7_blackcloud",{"albedo_a":Color(0.10,0.13,0.19),"albedo_b":Color(0.20,0.22,0.27)},"carpet")
    MatLib.define("d7_office",{"albedo_a":Color(0.49,0.49,0.47),"albedo_b":Color(0.66,0.66,0.64)},"concrete")
    var k:=kit("StormsAtWorldEdge")
    k.slab(-110,-160,110,-45,0,0.5,"d7_whitecloud")
    k.slab(-110,-45,110,60,0,0.5,"d7_greycloud")
    k.slab(-110,60,110,160,0,0.5,"d7_blackcloud")
    for i in 16:
        var x:float=-98+float(i)*13
        k.box(Vector3(x,0.18,80+float(i%5)*12),Vector3(9,0.3,7),"d7_greycloud",GeoKit.ALL,false)
    # A small concrete stairwell at the safe white-cloud entrance.
    k.box(Vector3(-5,2,-139),Vector3(13,4,13),"d7_office")
    k.stairs(Vector3(-5,0,-124),Vector3(0,0,1),3.1,3.2,16,"d7_office",0.44)
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "ThunderCloudStrata", Vector3(71, 0, 79), 5, 3.5, "d7_greycloud", "d7_office", false)
    add_arrival("start",Vector3(5,0.1,-125))
    add_arrival("from_L002",Vector3(5,0.1,-125))
    add_arrival("from_L011",Vector3(5,0.1,-125))
    add_arrival("from_L737",Vector3(5,0.1,-125))
    add_note("zones","THREE CLOUD ZONES","White gives way to grey, and grey to a black storm. Nobody knows what lies beyond the true edges.",Vector3(10,0.8,-114))
    for i in 3:
        var n:int=i
        add_interactable(Vector3(3,1.0,-27+float(i)*73),Vector3(3,2.0,4),"Check the storm horizon",func():_measure(n))
    add_landmark("Concrete entrance stair",Vector3(-5,0,-139))
    add_landmark("Black cloud front",Vector3(0,0,120))
    add_shot("white_to_grey",Vector3(10,1.6,-110),Vector3(0,1,134))
    add_shot("black_storm",Vector3(5,1.6,70),Vector3(0,5,160))
    sound.bed("wind",{"seconds":7.5},-30.0)
func _measure(n:int)->void:
    _storms+=1
    Overlay.subtitle("[storm sector %d: pressure changes without warning]"%(n+1),3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unknown cloud edge is not teleport","ok":exits.is_empty()},{"what":"inbound from dunes exists","ok":arrivals.has("from_L737")}]
