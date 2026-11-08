extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
var _static_heard:=0
func build()->void:
    outdoor_env(Color(0.24,0.23,0.25),Color(0.51,0.46,0.41),Color(0.28,0.30,0.22),Vector2(60,-40),Color(0.83,0.65,0.48),0.44,Color(0.29,0.27,0.23),0.045)
    MatLib.define("d7_plastic",{"albedo_a":Color(0.21,0.35,0.24),"albedo_b":Color(0.38,0.46,0.26)},"grass")
    MatLib.define("d7_road",{"albedo_a":Color(0.15,0.16,0.16),"albedo_b":Color(0.25,0.25,0.24)},"concrete")
    MatLib.define("d7_luxury",{"albedo_a":Color(0.74,0.67,0.54),"albedo_b":Color(0.88,0.83,0.72)},"concrete")
    var k:=kit("BrilliantEvermoreSuburb")
    k.slab(-130,-160,130,160,0,0.5,"d7_plastic")
    k.box(Vector3(0,0.08,0),Vector3(17,0.12,320),"d7_road")
    for i in 14:
        var x:float= -55.0 if i%2==0 else 55.0
        var z:float=-134+float(int(i/2))*43
        k.box(Vector3(x,3.0,z),Vector3(23,6,19),"d7_luxury")
        k.box(Vector3(x,6.8,z),Vector3(26,1.0,22),"d7_road")
        k.box(Vector3(x,1.0,z+12),Vector3(6,2.0,7),"d7_road")
    # A dedicated, open library alcove near the road; its threshold remains walkable.
    k.slab(9,62,37,98,0.1,0.3,"d7_luxury")
    for x in [13.0,33.0]:
        for z in [70.0,80.0,90.0]:k.box(Vector3(x,1.4,z),Vector3(2.5,2.8,5),"d7_road")
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "AbandonedSunsetTerraces", Vector3(93, 0, -51), 4, 3.5, "d7_luxury", "d7_road", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "AbandonedSunsetTerraces")
    add_arrival("start",Vector3(0,0.15,-145))
    add_exit("L085>L601#2","noclip",Vector3(24,1.25,96),Vector3(7,2.6,3),"Anomalous library threshold")
    # Vehicle passage to L064 is documented but L064 is not built: do not pretend driving works.
    add_interactable(Vector3(-5,1.1,118),Vector3(3,2.2,2),"Tune the endlessly looping radio",func():_radio())
    add_note("smog","BRILLIANT EVERMORE","No natural grass grows here. The sea is acidic. A spontaneous library noclip has been recorded; driving is not implemented.",Vector3(4,0.8,-131))
    add_landmark("Smog boulevard",Vector3(0,0,0))
    add_landmark("Library alcove",Vector3(25,0,82))
    add_shot("plastic_road",Vector3(0,1.6,-140),Vector3(0,5,120))
    add_shot("raised_houses",Vector3(12,1.6,-24),Vector3(55,6,20))
    sound.bed("wind",{"seconds":9.0},-33.0)
    ModelDress.decorate(self, "L085")

func _radio()->void:
    _static_heard+=1
    Overlay.subtitle("[the same advertisement begins again, without a station identifier]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"one built documented destination","ok":exits.size()==1},{"what":"drive not falsely simulated","ok":_static_heard==0}]
