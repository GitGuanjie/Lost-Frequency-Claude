extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Snackrooms: historic and contemporary mall restaurant corridors, free replenishing vending machines.
var _vendors := 0
var _restocks := 0
var _rearranges := 0

func build() -> void:
    indoor_env(Color(0.90,0.78,0.65),0.48,Color(0.36,0.30,0.30),0.0010)
    rules["view_distance"] = 270.0
    MatLib.define("l61_tile",{"albedo_a":Color(0.70,0.69,0.66),"albedo_b":Color(0.80,0.77,0.72)},"tile")
    MatLib.define("l61_navy",{"albedo_a":Color(0.08,0.16,0.37),"albedo_b":Color(0.14,0.24,0.44)},"metal")
    MatLib.define("l61_wood",{"albedo_a":Color(0.38,0.25,0.17),"albedo_b":Color(0.52,0.35,0.24)},"wood_floor")
    MatLib.define("l61_wall",{"albedo_a":Color(0.80,0.68,0.57),"albedo_b":Color(0.90,0.78,0.65)},"plaster")
    MatLib.register("l61_screen",MatLib.panel(Color(0.98,0.71,0.42),0.8))
    lights.setup(12,1)
    _cafeterias()
    _side_areas()
    add_exit("L006_1>L006#1","interact",Vector3(0,1.3,-83),Vector3(2.5,2.4,2.0),"Rusty steel door back to Level 6")
    add_exit("L006_1>L011#2","interact",Vector3(29,1.3,123),Vector3(3,2.4,1.8),"Sliding glass door to Level 11")
    add_exit("L006_1>L003#3","interact",Vector3(-28,2.3,99),Vector3(2.1,2.2,2.0),"Enter the open ventilation duct")
    add_arrival("start",Vector3(0,0.08,-75))
    add_arrival("from_L006",Vector3(0,0.08,-75))
    add_landmark("Open central food court",Vector3(0,0,-10))
    add_landmark("Mixed-era restaurants",Vector3(0,0,60))
    add_landmark("Slightly luminous windows",Vector3(25,3,98))
    add_shot("mall_dining",Vector3(1,1.62,-74),Vector3(0,2,29))
    add_shot("long_restaurants",Vector3(-7,1.62,40),Vector3(21,1.8,98))
    sound.bed("room_tone",{"seconds":7.0,"cutoff":500.0},-28.0)

    ModelDress.decorate(self, "L006_1")

func _cafeterias() -> void:
    var k:=kit("PeriodRestaurantMall")
    k.slab(-34,-87,34,130,0,0.33,"l61_tile")
    k.box(Vector3(0,7.7,21.5),Vector3(68,0.3,217),"l61_wall")
    for x in [-34.0,34.0]:
        k.box(Vector3(x,3.85,21.5),Vector3(0.5,7.7,217),"l61_wall")
    for i in 17:
        var z:float=-73.0+float(i)*11.8
        for side in [-1,1]:
            var x:float=float(side)*22.5
            k.box(Vector3(x,0.7,z),Vector3(4.0,1.4,2.0),"l61_navy")
            for t in [-3.1,3.1]:
                k.box(Vector3(x+t,0.45,z),Vector3(1.0,0.9,1.0),"l61_navy")
        k.box(Vector3(0,7.5,z),Vector3(2.5,0.08,2.4),"l61_screen",GeoKit.ALL,false)
        if i%3==0:
            lights.add_anchor(Vector3(0,6.9,z),Color(1,0.82,0.63),0.7,12,0.9,"l61_amber")
    k.commit()

func _side_areas() -> void:
    var k:=kit("HistoricSnackBarAndVending")
    for i in 12:
        var z:float=-67.0+float(i)*16.5
        var x:float=-30.5 if i%2==0 else 30.5
        k.box(Vector3(x,1.15,z),Vector3(2.8,2.3,1.4),"l61_wood" if i%3==0 else "l61_navy")
        k.box(Vector3(x,1.8,z+0.75),Vector3(2.2,0.7,0.07),"l61_screen",GeoKit.ALL,false)
    k.commit()
    for i in 8:
        var z:float=-67.0+float(i)*24.0
        var x:float=-29.0 if i%2==0 else 29.0
        _vendors+=1
        add_interactable(Vector3(x,1.5,z+1),Vector3(2.0,2.2,1.7),"Take a free snack or water",func(): _vending())
    add_interactable(Vector3(-4,1.0,18),Vector3(2,1.6,2),"Read a Track Mapper's layout map",func(): Overlay.subtitle("[a hand-drawn map marks the currently safe dining corridor]",4.0))
    add_interactable(Vector3(5,1.0,61),Vector3(2,1.6,2),"Enter a neighbouring restaurant",func(): _switch_restaurant())
    add_note("history","RESTOCKING NOTICE","Food machines replenish on a weekly rhythm. Restaurant doors sometimes return to a different café.",Vector3(-11,0.83,-5))

func _vending() -> void:
    _restocks += 1
    Overlay.subtitle("[a wrapped snack and clean bottle are dispensed without payment]",3.5)

func _switch_restaurant() -> void:
    _rearranges+=1
    if player!=null:
        player.global_position=Vector3(0,0.25,91)
    Overlay.subtitle("[the restaurant door opens into an unexpected section of the mall]",3.5)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"eight interactive vendors", "ok":_vendors==8}, {"what":"three sourced exits", "ok":exits.size()==3}, {"what":"Level 6 return arrival", "ok":arrivals.has("from_L006")}]
