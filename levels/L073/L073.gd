extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
var _gate_attempts:=0
var _stillness:=0.0
func build()->void:
    rules["flashlight"]="forbidden"
    rules["view_distance"]=300.0
    outdoor_env(Color(0.08,0.025,0.035),Color(0.18,0.045,0.055),Color(0.03,0.01,0.015),Vector2(28,137),Color(0.68,0.60,0.63),0.48,Color(0.12,0.032,0.045),0.018)
    MatLib.define("d6_redsoil",{"albedo_a":Color(0.23,0.055,0.061),"albedo_b":Color(0.32,0.080,0.073)},"dirt")
    MatLib.define("d6_darkstone",{"albedo_a":Color(0.16,0.15,0.16),"albedo_b":Color(0.28,0.24,0.25)},"rock")
    MatLib.define("d6_redwood",{"albedo_a":Color(0.34,0.18,0.15),"albedo_b":Color(0.43,0.26,0.19)},"wood_floor")
    lights.setup(4,0)
    var k:=kit("MoonlitRedlands")
    k.slab(-50,-76,50,82,0,1.1,"d6_redsoil")
    # Three-storey keep on a raised approach: the hall is walkable even though upper floors remain blocked.
    k.slab(-20,25,20,70,3.5,3.5,"d6_darkstone")
    for x in [-19.0,19.0]:k.box(Vector3(x,11,49),Vector3(1.6,15,46),"d6_darkstone")
    k.box(Vector3(0,11,70),Vector3(40,15,1.6),"d6_darkstone")
    for x in [-15.0,15.0]:k.box(Vector3(x,11,25),Vector3(9,15,1.4),"d6_darkstone")
    k.box(Vector3(0,16,47),Vector3(40,0.6,46),"d6_darkstone")
    for z in [-48.0,-27.0,-6.0,15.0]:
        k.box(Vector3(0,0.13,z),Vector3(6,0.22,12),"d6_darkstone")
    k.ramp(Vector3(0,0,19),Vector3(0,3.5,28),6,0.4,"d6_darkstone")
    for i in 4:
        k.box(Vector3(-13+float(i)*8,4.1,49),Vector3(3.4,1.1,2.4),"d6_redwood")
    k.commit()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "CrimsonKeepBoundary", Vector3(32, 0, -39), 4, 3.5, "d6_darkstone", "d6_redwood", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "CrimsonKeepBoundary")
    add_arrival("start",Vector3(0,0.1,-69))
    add_arrival("from_L028",Vector3(0,0.1,-69))
    add_interactable(Vector3(0,5,27),Vector3(5,4,3),"Bang on the castle door",func():_knock())
    add_note("warning","DO NOT LOOK BACK","Accounts warn against standing still or using artificial light outside. The full chase simulation is pending.",Vector3(3,0.7,-57))
    add_landmark("Castle gate",Vector3(0,3.5,27))
    add_landmark("Crimson island shoreline",Vector3(0,0,-69))
    add_shot("moonlit_castle",Vector3(0,1.6,-62),Vector3(0,8,52))
    add_shot("castle_interior",Vector3(0,5.2,36),Vector3(0,5,67))
    sound.bed("wind",{"seconds":9.0},-35.0)
    ModelDress.decorate(self, "L073")

func level_process(delta:float)->void:
    if player==null or SessionState.is_qa():return
    if player.global_position.z<18.0 and player.velocity.length()<1.1:
        _stillness+=delta
    else:
        _stillness=maxf(0.0,_stillness-delta*2.0)
    if _stillness>9.0:
        player.hurt(0.14*delta,"Unseen dangers outside the castle")
func _knock()->void:
    _gate_attempts+=1
    Overlay.subtitle("[something answers from the other side of the gate]",3.5)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"flashlight forbidden outdoors","ok":rules["flashlight"]=="forbidden"},{"what":"no invented castle exit","ok":exits.is_empty()}]
