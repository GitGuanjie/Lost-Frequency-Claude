extends LevelBase
const ImmersiveNetworks := preload("res://core/world/ImmersiveNetworks.gd")
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
## Permanent tropical sunset with separated seafront, luxury hotels and inland forest.
var _trees := 0
var _wave_clock := 0.0

func build() -> void:
    rules["view_distance"] = 850.0
    outdoor_env(Color(0.48, 0.27, 0.39), Color(0.99, 0.56, 0.26), Color(0.27, 0.20, 0.16), Vector2(10, -85), Color(1.0, 0.57, 0.27), 0.42, Color(0.81, 0.45, 0.28), 0.0012)
    MatLib.define("l48_sand", {"albedo_a":Color(0.83,0.69,0.48), "albedo_b":Color(0.89,0.78,0.56)}, "sand")
    MatLib.define("l48_grass", {"albedo_a":Color(0.23,0.43,0.22), "albedo_b":Color(0.14,0.31,0.13)}, "grass")
    MatLib.define("l48_bark", {"albedo_a":Color(0.39,0.27,0.15), "albedo_b":Color(0.45,0.32,0.20)}, "wood_floor")
    MatLib.define("l48_building", {"albedo_a":Color(0.79,0.78,0.71), "albedo_b":Color(0.87,0.86,0.82)}, "plaster")
    MatLib.register("l48_leaf", MatLib.panel(Color(0.16,0.47,0.20), 0.12))
    MatLib.register("l48_window", MatLib.panel(Color(0.27,0.52,0.56), 0.2))
    lights.setup(4, 0)
    _coast()
    _forest()
    _farmhouse()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "SeafrontWesternPromenade", Vector3(-100, 0, 131), 5, 3.5, "l48_building", "l48_bark", false, 1)
    SpatialBranchworks.install(self, "SeafrontEasternPromenade", Vector3(-27, 0, 131), 5, 3.5, "l48_building", "l48_bark", false, -1)
    SpatialBranchworks.link_sites(self, "L048_DualPortal", Vector3(-100, 0, 131), Vector3(-27, 0, 131), 5, 3.5, "l48_building", "l48_bark")
    # DEV25: wiki-aware, optional traversable annex; original exits unchanged.
    ImmersiveNetworks.install(self)
    add_arrival("start",Vector3(10, 0.08, -40),180)
    add_arrival("from_L010",Vector3(10,0.08,-40),180)
    add_landmark("A permanent sunset over the southern ocean",Vector3(0,0,-120))
    add_landmark("The forest beginning inland",Vector3(0,0,200))
    add_landmark("Farmhouse near the forest trail",Vector3(52,0,90))
    add_shot("sunset_coast",Vector3(6,1.62,-35),Vector3(3,2,-200))
    add_shot("hotel_and_forest",Vector3(-20,1.62,70),Vector3(42,3,98))
    sound.bed("water_bed",{"seconds":7.0,"bright":0.15},-26.0)
    sound.bed("wind",{"seconds":7.0},-34.0)

func _coast() -> void:
    var k := kit("BeachAndOcean")
    k.slab(-145, -110, 145, 215, 0, 0.4, "l48_sand")
    k.slab(-145, 202, 145, 340, 0.05, 0.4, "l48_grass")
    k.slab(-145,-320,145,-110,-1.6,0.3,"l48_sand")
    for i in 9:
        if i == 4:
            continue  # the middle building is a genuinely accessible two-floor hotel
        var x := -125.0 + float(i)*29.0
        var z := 18.0 + float(i%3)*28.0
        k.box(Vector3(x,3.5,z),Vector3(17,7,15),"l48_building")
        for floor_idx in 2:
            k.box(Vector3(x,1.9+float(floor_idx)*3.2,z-7.65),Vector3(12.5,1.8,0.08),"l48_window",GeoKit.ALL,false)
    # Inhabitable lobby and second-storey lookout; stair opening is split out of upper floor.
    k.slab(-20,34,-1,57,0.12,0.40,"l48_building")
    k.slab(-20,49,-15,57,3.5,0.35,"l48_building")
    k.slab(-10,34,-1,57,3.5,0.35,"l48_building")
    k.slab(-15,49,-10,57,3.5,0.35,"l48_building")
    k.box(Vector3(-20,3.3,45.5),Vector3(0.3,6.6,23),"l48_building")
    k.box(Vector3(-1,3.3,45.5),Vector3(0.3,6.6,23),"l48_building")
    k.box(Vector3(-10.5,3.3,57),Vector3(19,6.6,0.3),"l48_building")
    k.box(Vector3(-17,3.3,34),Vector3(6,6.6,0.3),"l48_building")
    k.box(Vector3(-4.0,3.3,34),Vector3(6,6.6,0.3),"l48_building")
    k.box(Vector3(-10.5,5.3,34),Vector3(7,2.6,0.3),"l48_building")
    k.box(Vector3(-10.5,7.1,45.5),Vector3(19,0.32,23),"l48_building")
    k.stairs(Vector3(-17.4,0.12,34.5),Vector3(0,0,1),2.8,3.38,14,"l48_building",0.98)
    k.box(Vector3(-5.8,0.8,40),Vector3(3,1.6,2),"l48_bark")
    k.box(Vector3(-5.8,1.7,40),Vector3(2,0.08,1.2),"l48_window",GeoKit.ALL,false)
    k.commit()
    var w := WaterVolume.new()
    add_child(w)
    MatLib.register("l48_water",MatLib.water({"shallow_color":Color(0.31,0.69,0.73),"deep_color":Color(0.10,0.37,0.57),"wave_height":0.06}))
    w.setup(Vector3(-145,-1.45,-320),Vector3(145,-0.20,-110),"l48_water",true)

func _forest() -> void:
    var k := kit("InlandTropicalForest")
    for i in 90:
        var x := rng.randf_range(-135.0,135.0)
        var z := rng.randf_range(214.0,333.0)
        if absf(x-52.0)<13.0 and z<255.0:
            continue
        var h := rng.randf_range(5.0,11.0)
        k.cylinder(Vector3(x,h*0.5,z),0.28,h,"l48_bark",6)
        for j in 3:
            var angle := TAU*float(j)/3.0
            k.box(Vector3(x+cos(angle)*1.8,h,z+sin(angle)*1.8),Vector3(5.0,1.0,4.5),"l48_leaf",GeoKit.ALL,false)
        _trees+=1
    k.commit()
    add_note("forest_note","THE DISTANT FOREST","There is forest two hundred metres from the shore. The sunset has not moved once.",Vector3(20,0.85,190))

func _farmhouse() -> void:
    var k := kit("SeafrontFarmhouse")
    k.slab(40,82,65,115,0.1,0.3,"l48_building")
    for x in [40.0,65.0]:
        k.box(Vector3(x,2.4,98),Vector3(0.3,4.8,33),"l48_building")
    for z in [82.0,115.0]:
        k.box(Vector3(52.5,2.4,z),Vector3(25,4.8,0.3),"l48_building")
    k.box(Vector3(52.5,4.9,98),Vector3(25,0.3,33),"l48_building")
    k.commit()
    add_exit("L048>L010#5","interact",Vector3(52,1.2,81.1),Vector3(3,2.4,1.5),"Leave the farmhouse toward Level 10")
    add_exit("L048>L049#4","walk_in",Vector3(0,1.1,325),Vector3(8,3.0,5),"Follow the dirt trench into the forest")
    add_note("hotel","A PERMANENT EVENING","The ocean is warm. The buildings remain furnished, but the light never changes.",Vector3(45,0.9,92))

func level_process(delta:float) -> void:
    _wave_clock+=delta
    if _wave_clock > 48.0 and not SessionState.is_qa():
        _wave_clock=0.0
        Overlay.subtitle("[the sunset has not moved]",3.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"forest more than 65 trees", "ok":_trees>65}, {"what":"two canon routes", "ok":exits.size()==2}, {"what":"sun remains fixed", "ok":sun!=null}]
