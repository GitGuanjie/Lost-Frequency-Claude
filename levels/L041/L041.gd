extends LevelBase
const ImmersiveNetworks := preload("res://core/world/ImmersiveNetworks.gd")
## Burning tar lake, a narrow boardwalk and doomed outlying islands.
var _islands:=0
var _tar_clock:=0.0
func build()->void:
    rules["view_distance"]=350.0
    outdoor_env(Color(0.25,0.25,0.26),Color(0.43,0.42,0.38),Color(0.19,0.16,0.13),Vector2(26,15),Color(0.74,0.67,0.59),0.34,Color(0.32,0.33,0.35),0.015)
    MatLib.define("l41_tar",{"albedo_a":Color(0.08,0.08,0.09),"albedo_b":Color(0.17,0.13,0.12)},"asphalt")
    MatLib.define("l41_plank",{"albedo_a":Color(0.38,0.26,0.19),"albedo_b":Color(0.30,0.22,0.18)},"wood_floor")
    MatLib.define("l41_sand",{"albedo_a":Color(0.24,0.22,0.18),"albedo_b":Color(0.34,0.28,0.21)},"sand")
    MatLib.define("l41_steel",{"albedo_a":Color(0.30,0.34,0.35),"albedo_b":Color(0.39,0.40,0.40)},"metal")
    lights.setup(4,0)
    var k:=kit("BurningAsphaltLake")
    # Tar visual is noncolliding; supported walkways and islands alone carry travelers.
    k.box(Vector3(0,-2.2,0),Vector3(240,0.16,230),"l41_tar",GeoKit.ALL,false)
    k.slab(-8,-89,8,-70,0,0.55,"l41_sand")
    k.slab(-8,-71,8,18,0,0.48,"l41_plank")
    k.slab(-28,17,32,24,0,0.48,"l41_plank")
    k.slab(22,23,32,81,0,0.48,"l41_plank")
    for i in 16:
        var z:float=-62+float(i)*8
        k.box(Vector3(27,-1.0,z),Vector3(0.7,2,0.8),"l41_steel")
    for i in 11:
        var x:float=rng.randf_range(-70,70)
        var z:float=rng.randf_range(-63,70)
        if absf(x)<35:continue
        k.slab(x-2,z-3,x+2,z+3,-0.2,0.45,"l41_sand")
        _islands+=1
    for i in 10:
        var x:float=-65+float(i%5)*28
        var z:float=44+float(int(i/5))*24
        if x>10 and x<40:continue
        k.box(Vector3(x,0.8,z),Vector3(2.0,1.6,1.8),"l41_steel",GeoKit.ALL,false)
    k.commit()
    # DEV25: wiki-aware, optional traversable annex; original exits unchanged.
    ImmersiveNetworks.install(self)
    add_arrival("start",Vector3(0,0.08,-82))
    add_arrival("from_L008",Vector3(0,0.08,-82))
    add_exit("L041>L612#3","interact",Vector3(-21,1.5,20),Vector3(4,2.6,2.2),"Barn door on the raised walkway")
    add_exit("L041>L626#4","interact",Vector3(27,1.5,75),Vector3(4,2.6,3),"Tamper with the lighthouse beacon")
    add_note("lake","BLACK LAKE","Asphalt boils constantly. Sand islands are unstable; only wooden and concrete structures allow traversal.",Vector3(2,1,-78))
    add_landmark("Single supported boardwalk",Vector3(0,0,-35))
    add_landmark("Unstable islands beyond walkway",Vector3(-56,0,32))
    add_landmark("Beacon at far pier",Vector3(27,0,75))
    add_shot("tar_pier",Vector3(0,1.6,-79),Vector3(0,1.6,19))
    add_shot("beacon",Vector3(26,1.6,27),Vector3(27,2,74))
    sound.bed("wind",{"seconds":7.0},-38.0)
func level_process(delta:float)->void:
    _tar_clock+=delta
    if _tar_clock>69.0:
        _tar_clock=0.0
        if not SessionState.is_qa():Overlay.subtitle("[a bubble of black pitch bursts beneath the planks]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"two documentable destinations","ok":exits.size()==2},{"what":"unreliable tar islands","ok":_islands==11},{"what":"source entry from Level 8","ok":arrivals.has("from_L008")}]
