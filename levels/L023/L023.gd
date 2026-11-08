extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
## Dark root forest above a bioluminescent cavern and the Heart of Water. Source destinations only.
var _tree_count:=0
var _glow_count:=0
var _water:WaterVolume
func build()->void:
    rules["view_distance"]=285.0
    outdoor_env(Color(0.06,0.10,0.11),Color(0.13,0.19,0.19),Color(0.02,0.04,0.05),Vector2(20,-20),Color(0.30,0.49,0.42),0.18,Color(0.08,0.15,0.12),0.005)
    MatLib.define("l23_root",{"albedo_a":Color(0.22,0.18,0.16),"albedo_b":Color(0.12,0.17,0.14)},"wood_floor")
    MatLib.define("l23_moss",{"albedo_a":Color(0.12,0.26,0.18),"albedo_b":Color(0.21,0.31,0.19)},"grass")
    MatLib.define("l23_cavern",{"albedo_a":Color(0.22,0.28,0.29),"albedo_b":Color(0.16,0.21,0.25)},"rock")
    MatLib.register("l23_blue",MatLib.panel(Color(0.22,0.84,0.95),1.0))
    MatLib.register("l23_green",MatLib.panel(Color(0.33,0.98,0.56),0.9))
    MatLib.register("l23_water",MatLib.water({"shallow_color":Color(0.19,0.61,0.68),"deep_color":Color(0.04,0.17,0.31),"wave_height":0.02}))
    lights.setup(6,0)
    _roots()
    _heart()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "RootsDeepSubstrata", Vector3(55, -6, 0), 5, 3.45, "l23_cavern", "l23_root", true)
    add_arrival("start",Vector3(0,0.08,-70))
    add_arrival("from_L012",Vector3(0,0.08,-70))
    add_arrival("from_L022",Vector3(0,0.08,-70))
    add_exit("L023>L007#1","noclip",Vector3(0,-4.8,28),Vector3(6,2.0,6),"The Heart of Water")
    add_landmark("Giants of petrified wood",Vector3(-50,0,0))
    add_landmark("Root stair into the hollow interior",Vector3(8,0,-16))
    add_landmark("Bioluminescent Heart of Water",Vector3(0,-5,28))
    add_shot("forest",Vector3(0,1.62,-68),Vector3(-38,9,0))
    add_shot("root_hollow",Vector3(7,-4.2,-13),Vector3(0,-3,27))
    sound.bed("wind",{"seconds":8.0},-36.0)
    sound.bed("water_bed",{"seconds":7.0,"bright":0.12},-33.0)
func _roots()->void:
    var k:=kit("PetrifiedSurface")
    # The opening is a genuine two-sided hole, not covered by a full surface slab.
    k.slab(-100,-100,4,100,0,0.5,"l23_moss")
    k.slab(13,-100,100,100,0,0.5,"l23_moss")
    k.slab(4,-100,13,-26,0,0.5,"l23_moss")
    k.slab(4,18,13,100,0,0.5,"l23_moss")
    for i in 72:
        var x:float=rng.randf_range(-93,93)
        var z:float=rng.randf_range(-95,95)
        if absf(x)<18 and z>-40 and z<40: continue
        var h:float=rng.randf_range(8,22)
        k.cylinder(Vector3(x,h*0.5,z),rng.randf_range(0.5,1.1),h,"l23_root",8)
        for j in 3:
            var a:float=TAU*float(j)/3.0
            k.box(Vector3(x+cos(a)*3,h*0.7,z+sin(a)*3),Vector3(6,0.8,3),"l23_moss",GeoKit.ALL,false)
        _tree_count+=1
    k.stairs(Vector3(8,-6.0,-19),Vector3(0,0,1),3.3,6.0,25,"l23_root",1.0)
    k.commit()
func _heart()->void:
    var k:=kit("RootHeartCave")
    k.slab(-30,-32,30,52,-6.0,0.55,"l23_cavern")
    for x in [-31.0,31.0]:
        if x < 0.0:
            k.box(Vector3(x,-1.0,10),Vector3(1.8,10,84),"l23_cavern")
        else:
            # Open a 5.6m portal exactly on the existing y=-6 cave floor.
            # The upper ground layer at y=0 is left intact above this chamber.
            k.box(Vector3(x,-1.0,-18.75),Vector3(1.8,10,26.5),"l23_cavern")
            k.box(Vector3(x,-1.0,28.75),Vector3(1.8,10,46.5),"l23_cavern")
    for i in 36:
        var x:float=-26.0+float(i%6)*9.2
        var z:float=-26.0+float(int(i/6))*14.0
        k.box(Vector3(x,-1.4,z),Vector3(0.9,2.2,0.8),"l23_blue" if i%2==0 else "l23_green",GeoKit.ALL,false)
        _glow_count+=1
    # Narrow supported underground approach from cave through the cut portal.
    k.slab(28.7,-1.8,46.2,1.8,-6.0,0.32,"l23_cavern")
    k.commit()
    _water=WaterVolume.new();add_child(_water)
    _water.setup(Vector3(-10,-5.4,18),Vector3(10,-4.55,39),"l23_water",true)
    for i in 4:
        lights.add_anchor(Vector3(-18+float(i)*12,-1,25),Color(0.27,0.90,0.77),0.75,15,0.0,"l23_heart")
    add_note("root","HOLLOW ROOT","The trees continue underground. The water chamber is much larger than its opening suggests.",Vector3(11,-5.1,2))
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"forest trees populated","ok":_tree_count>45},{"what":"cavern lights","ok":_glow_count==36},{"what":"sourced water exit","ok":exits.size()==1}]
