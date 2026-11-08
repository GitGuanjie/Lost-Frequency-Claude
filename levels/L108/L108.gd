extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
var _samples:=0
func build()->void:
    outdoor_env(Color(0.19,0.32,0.24),Color(0.43,0.58,0.39),Color(0.21,0.28,0.19),Vector2(45,-85),Color(0.77,0.87,0.69),0.53,Color(0.24,0.35,0.27),0.035)
    MatLib.define("d7_crater",{"albedo_a":Color(0.31,0.34,0.24),"albedo_b":Color(0.42,0.42,0.28)},"dirt")
    MatLib.define("d7_trunk",{"albedo_a":Color(0.18,0.21,0.16),"albedo_b":Color(0.24,0.30,0.22)},"wood_floor")
    MatLib.define("d7_mutant",{"albedo_a":Color(0.29,0.46,0.34),"albedo_b":Color(0.42,0.56,0.35)},"grass")
    MatLib.define("d7_purple",{"albedo_a":Color(0.49,0.29,0.62),"albedo_b":Color(0.71,0.47,0.81)},"concrete")
    var k:=kit("FertileGrounds")
    k.slab(-170,-190,170,190,0,0.6,"d7_crater")
    # Ring of crooked trees: open central avenues and a signed trail toward the crater.
    for i in 180:
        var x:float=rng.randf_range(-166,166)
        var z:float=rng.randf_range(-177,177)
        if absf(x)<12 or absf(z)<10 or Vector2(x,z).length()<43:continue
        if absf(x-108.0)<21.0 and absf(z-72.0)<29.0:continue
        var h:float=rng.randf_range(6,20)
        k.cylinder(Vector3(x,h*0.5,z),0.65,h,"d7_trunk",7)
        k.box(Vector3(x,h,z),Vector3(4,1.7,5),"d7_mutant",GeoKit.ALL,false)
    k.cylinder(Vector3(0,0.6,93),25,1.2,"d7_crater",24)
    for i in 13:
        k.box(Vector3(8,0.15,-160+float(i)*20),Vector3(0.38,0.3,3.8),"d7_purple",GeoKit.ALL,false)
    for i in 7:
        k.box(Vector3(-25+float(i)*7,2,-155),Vector3(4.5,4,5.2),"d7_trunk")
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "CraterwoodCanopyCircuit", Vector3(108, 0, 72), 5, 3.5, "d7_trunk", "d7_mutant", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "CraterwoodCanopyCircuit")
    add_arrival("start",Vector3(0,0.1,-165))
    add_arrival("from_L025",Vector3(0,0.1,-165))
    add_note("guides","PURPLE TRAIL","New Hereth keeps a marked path away from the crater. Do not follow fog off the route.",Vector3(6,0.8,-154))
    for i in 4:
        var n:int=i
        add_interactable(Vector3(5,1.0,-115+float(i)*42),Vector3(3,2,3),"Study a biological sample",func():_sample(n))
    add_landmark("New Hereth outpost",Vector3(-23,0,-155))
    add_landmark("Craterwood centre",Vector3(0,0,93))
    add_shot("marked_trail",Vector3(0,1.6,-158),Vector3(0,5,126))
    add_shot("mutated_wood",Vector3(15,1.6,12),Vector3(110,12,100))
    sound.bed("wind",{"seconds":9.0},-38.0)
func _sample(n:int)->void:
    _samples+=1
    Overlay.subtitle("[sample %d: spores recorded; no reliable external destination]"%(n+1),3.4)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unknown forest exits not fabricated","ok":exits.is_empty()},{"what":"crater scene has documentation","ok":qa_shots.size()==2}]
