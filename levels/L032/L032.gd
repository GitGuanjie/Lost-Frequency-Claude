extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
var _bells:=0
func build()->void:
    outdoor_env(Color(0.01,0.018,0.035),Color(0.045,0.06,0.09),Color(0.06,0.08,0.11),Vector2(18,-130),Color(0.58,0.62,0.81),0.28,Color(0.05,0.07,0.08),0.052)
    MatLib.define("d7_forestfloor",{"albedo_a":Color(0.12,0.14,0.16),"albedo_b":Color(0.18,0.20,0.21)},"dirt")
    MatLib.define("d7_bone",{"albedo_a":Color(0.72,0.72,0.64),"albedo_b":Color(0.85,0.84,0.75)},"concrete")
    MatLib.define("d7_trunk",{"albedo_a":Color(0.13,0.12,0.10),"albedo_b":Color(0.23,0.21,0.17)},"wood_floor")
    var k:=kit("SkeletonForest")
    k.slab(-155,-155,155,155,0,0.5,"d7_forestfloor")
    for i in 150:
        var x:float=rng.randf_range(-148,148)
        var z:float=rng.randf_range(-148,148)
        if absf(x)<8.0 or absf(z)<5.0:continue
        if absf(x-80.0)<20.0 and absf(z-40.0)<28.0:continue
        var h:float=rng.randf_range(6,14)
        k.cylinder(Vector3(x,h*0.5,z),0.44,h,"d7_trunk",7)
        if i%3==0:
            k.box(Vector3(x+0.8,h-1.5,z),Vector3(0.18,1.4,0.22),"d7_bone",GeoKit.ALL,false)
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "NightCanopyBranchedWalk", Vector3(80, 0, 40), 5, 3.4, "d7_trunk", "d7_bone", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "NightCanopyBranchedWalk")
    add_arrival("start",Vector3(0,0.1,-130))
    add_note("queen","NO PROMISE OF AN EXIT","A figure in the forest may grant release. No predictable destination is recorded.",Vector3(2,0.8,-120))
    for i in 3:
        var n:int=i
        add_interactable(Vector3(3,1,-60+float(i)*55),Vector3(2,2,2),"Listen to the clattering branches",func():_listen(n))
    add_landmark("Bone-like tree line",Vector3(0,0,0))
    add_shot("moon_path",Vector3(0,1.6,-125),Vector3(0,2,110))
    add_shot("bone_hangings",Vector3(8,1.6,12),Vector3(65,9,53))
    sound.bed("wind",{"seconds":9.0},-39.0)
func _listen(n:int)->void:
    _bells+=1
    Overlay.subtitle("[something rattles in the tree canopy %d]"%(n+1),3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no fabricated Queen teleport","ok":exits.is_empty()},{"what":"two viewpoints","ok":qa_shots.size()==2}]
