extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
## Hyperian island settlement. The two boat exits remain unsafe release boundaries.
var _harbor_count:=0
var _surveyed:Dictionary={}
func build()->void:
    rules["view_distance"]=500.0
    outdoor_env(Color(0.53,0.44,0.63),Color(0.88,0.66,0.76),Color(0.20,0.28,0.34),Vector2(17,40),Color(1,0.82,0.85),0.8,Color(0.56,0.60,0.65),0.002)
    MatLib.define("l29_rock",{"albedo_a":Color(0.37,0.33,0.38),"albedo_b":Color(0.27,0.27,0.32)},"rock")
    MatLib.define("l29_grass",{"albedo_a":Color(0.29,0.46,0.28),"albedo_b":Color(0.37,0.52,0.33)},"grass")
    MatLib.define("l29_wood",{"albedo_a":Color(0.45,0.26,0.21),"albedo_b":Color(0.53,0.35,0.26)},"wood_floor")
    MatLib.define("l29_leaf",{"albedo_a":Color(0.88,0.88,0.82),"albedo_b":Color(0.67,0.70,0.64)},"plaster")
    lights.setup(7,0)
    var k:=kit("HyperianHarbor")
    k.slab(-94,-99,94,94,0,0.6,"l29_grass")
    for x in [-87.0,87.0]:k.box(Vector3(x,2,0),Vector3(8,4,178),"l29_rock")
    for z in [-89.0,89.0]:k.box(Vector3(0,2,z),Vector3(180,4,8),"l29_rock")
    # Inner trading square and watchtowers, no fake simulated population.
    k.slab(-27,-31,27,34,0.08,0.22,"l29_wood")
    for i in 14:
        var x:float=-62+float(i%7)*20
        var z:float=8+float(int(i/7))*22
        if absf(x)<29:continue
        k.box(Vector3(x,2,z),Vector3(10,4,8),"l29_wood")
        k.box(Vector3(x,4.2,z),Vector3(11,0.35,9),"l29_rock")
    for i in 30:
        var x:float=rng.randf_range(-76,76)
        var z:float=rng.randf_range(-70,70)
        if absf(x)<29 or absf(z)<15:continue
        if x>36 and x<56 and z>-56 and z<-24:continue
        # DEV27: exclude solid tree trunks from the optional harbour pier network.
        if x>-86 and x<-26 and z>-83 and z<-7:continue
        var h:float=rng.randf_range(6,12)
        k.cylinder(Vector3(x,h*0.5,z),0.45,h,"l29_wood",7)
        k.box(Vector3(x,h+0.6,z),Vector3(3.3,1.0,3.1),"l29_leaf",GeoKit.ALL,false)
    for i in 7:
        var x:float=-24.0+float(i)*8.0
        k.box(Vector3(x,0.75,-75),Vector3(5.4,1.5,7.5),"l29_wood",GeoKit.ALL,false)
        _harbor_count+=1
    k.commit()
    VerticalArchitecture.install(self, "HarborWatchtower", Vector3(46, 0, -40), 4, 3.45, "l29_wood", "l29_rock")
    add_landmark("Hyperia watchtower, upper observation ring", Vector3(46, 10.35, -40))
    add_arrival("start",Vector3(0,0.08,-79))
    add_arrival("from_L025",Vector3(0,0.08,-79))
    add_exit("L029>L114#1","interact",Vector3(-24,1.4,-76),Vector3(3,2.6,2),"Unsafe outbound vessel — Level 114")
    add_exit("L029>L284#2","interact",Vector3(24,1.4,-76),Vector3(3,2.6,2),"Unsafe outbound vessel — unbuilt level")
    add_note("sea","HARBOR WARNING","The surrounding ocean has been known to break vessels. These departures are not safe.",Vector3(0,1,-72))
    add_note("city","HYPERIA","The trading hub is not a capital. The trees here have red trunks and white leaves.",Vector3(0,1,10))
    add_shot("harbor",Vector3(0,1.62,-78),Vector3(0,2,8))
    add_shot("inner_city",Vector3(0,1.62,10),Vector3(33,4,34))
    add_landmark("Harbor departure",Vector3(0,0,-75))
    add_landmark("Hyperia inner market",Vector3(0,0,10))
    sound.bed("wind",{"seconds":7.0},-32.0)
    ModelDress.decorate(self, "L029")

func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"two documented sea departures","ok":exits.size()==2},{"what":"harbor platforms","ok":_harbor_count==7},{"what":"market unexplored","ok":_surveyed.is_empty()}]
