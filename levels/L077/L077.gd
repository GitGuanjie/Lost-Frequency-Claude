extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
var _distance_noted:=0
func build()->void:
    outdoor_env(Color(0.53,0.69,0.83),Color(0.84,0.87,0.82),Color(0.38,0.48,0.32),Vector2(28,-80),Color(0.96,0.94,0.82),0.85,Color(0.60,0.69,0.65),0.009)
    MatLib.define("d7_pasture",{"albedo_a":Color(0.38,0.53,0.31),"albedo_b":Color(0.50,0.61,0.33)},"grass")
    MatLib.define("d7_nightwood",{"albedo_a":Color(0.09,0.13,0.10),"albedo_b":Color(0.15,0.20,0.14)},"wood_floor")
    MatLib.define("d7_farm",{"albedo_a":Color(0.54,0.47,0.32),"albedo_b":Color(0.67,0.56,0.40)},"wood_floor")
    var k:=kit("ShenandoahPasture")
    k.slab(-185,-180,185,180,0,0.5,"d7_pasture")
    for i in 110:
        var x:float=rng.randf_range(-180,180)
        var z:float=rng.randf_range(-174,174)
        if absf(x)<95 and absf(z)<90:continue
        # DEV27: keep the upper meadow spur free of solid tree trunks.
        if x>-86 and x<6 and z>35 and z<130:continue
        if absf(x-127.0)<20.0 and absf(z+12.0)<28.0:continue
        k.cylinder(Vector3(x,8.5,z),rng.randf_range(0.5,1.0),17,"d7_nightwood",6)
    for i in 5:
        var x:float=-75+float(i)*32
        k.box(Vector3(x,1.2,-45),Vector3(12,2.4,15),"d7_farm")
    for i in 12:
        var x:float=-70+float(i%6)*28
        var z:float=15+float(int(i/6))*23
        k.box(Vector3(x,0.65,z),Vector3(1.2,1.3,2.2),"d7_farm",GeoKit.ALL,false)
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "ShepherdNightOutlook", Vector3(127, 0, -12), 5, 3.5, "d7_farm", "d7_nightwood", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "ShepherdNightOutlook")
    add_arrival("start",Vector3(0,0.1,-95))
    add_note("farm","SHEEP COUNTRY","These central hills are comparatively open; the surrounding forest is darker even in daylight. The source's kilometres are intentionally compressed.",Vector3(6,0.8,-87))
    for i in 3:
        var n:int=i
        add_interactable(Vector3(-62+float(i)*54,1.0,72),Vector3(3,2,3),"Read an old farm marker",func():_read(n))
    add_landmark("Pasture ridge",Vector3(0,0,20))
    add_landmark("Distant night forest",Vector3(168,0,35))
    add_shot("daylight_hills",Vector3(0,1.6,-90),Vector3(12,6,97))
    add_shot("forest_boundary",Vector3(85,1.6,15),Vector3(168,7,48))
    sound.bed("wind",{"seconds":9.0},-34.0)
func _read(n:int)->void:
    _distance_noted+=1
    Overlay.subtitle("[marker %d: night begins beneath the trees]"%(n+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unverifiable long-distance noclip remains unlinked","ok":exits.is_empty()},{"what":"forest views exist","ok":qa_shots.size()>=2}]
