extends LevelBase
const IslandBiomes25 := preload("res://core/world/IslandBiomes25.gd")
## Coconut Isles: low gravity floating archipelago and barrier; not a connected bridge course.
var _island_count:=0
var _palms:=0
var _barrier_t:=0.0
var _barrier_trials:=0
var _barrier_destination:=""

func build() -> void:
    rules["gravity"]=1.47
    rules["jump_velocity"]=6.0
    rules["view_distance"]=1000.0
    outdoor_env(Color(0.29,0.32,0.62),Color(0.98,0.54,0.38),Color(0.39,0.25,0.18),Vector2(14,-55),Color(1,0.67,0.46),0.8,Color(0.64,0.46,0.46),0.0009)
    MatLib.define("l149_sand",{"albedo_a":Color(0.75,0.62,0.39),"albedo_b":Color(0.87,0.73,0.48)},"sand")
    MatLib.define("l149_wood",{"albedo_a":Color(0.39,0.29,0.20),"albedo_b":Color(0.50,0.37,0.22)},"wood_floor")
    MatLib.register("l149_palm",MatLib.panel(Color(0.20,0.44,0.19),0.15))
    lights.setup(2,0)
    _archipelago()
    # DEV25 natural extension; no fabricated structures or exit changes.
    IslandBiomes25.install(self)
    add_arrival("start",Vector3(0,0.08,0))
    add_arrival("from_L046",Vector3(0,0.08,0))
    add_landmark("Main island and Lost Suns village",Vector3(0,0,0))
    add_landmark("Low-gravity outer islands",Vector3(70,5,0))
    add_landmark("The stronger-gravity Barrier",Vector3(170,0,0))
    add_shot("floating_isles",Vector3(0,1.62,-22),Vector3(65,8,0))
    add_shot("sunset_village",Vector3(-15,1.62,5),Vector3(12,2,0))
    sound.bed("wind",{"seconds":8.0},-29.0)
    sound.bed("crickets",{"seconds":7.0},-38.0)

func _archipelago() -> void:
    var k:=kit("FloatingSandIsles")
    # A compressed representative section; per-level dossier documents 400 km source extent.
    k.slab(-30,-30,30,30,0.0,2.0,"l149_sand")
    _island_count+=1
    for i in 14:
        var x:float=35.0+float(i)*9.1
        var z:float=sin(float(i)*1.55)*12.0
        var y:float=sin(float(i)*0.7)*2.4
        var radius:float=8.2+float(i%3)*2.0
        k.slab(x-radius,z-radius,x+radius,z+radius,y,2.0,"l149_sand")
        k.box(Vector3(x,y-1.5,z),Vector3(radius*1.4,1.0,radius*1.4),"l149_sand",GeoKit.ALL,false)
        _island_count+=1
        for j in 7:
            var a:float=TAU*float(j)/7.0
            var tx:float=x+cos(a)*radius*0.45
            var tz:float=z+sin(a)*radius*0.45
            var h:float=3.0+float(j%3)
            k.cylinder(Vector3(tx,y+h*0.5,tz),0.18,h,"l149_wood",5,false)
            k.box(Vector3(tx,y+h,tz),Vector3(3,0.3,3),"l149_palm",GeoKit.ALL,false)
            _palms+=1
    for i in 30:
        var a:float=TAU*float(i)/30.0
        var r:float=15.0+float(i%4)*2.0
        var tx:float=cos(a)*r
        var tz:float=sin(a)*r
        k.cylinder(Vector3(tx,2.3,tz),0.2,4.6,"l149_wood",6,false)
        k.box(Vector3(tx,4.6,tz),Vector3(3.4,0.22,3.4),"l149_palm",GeoKit.ALL,false)
        _palms+=1
    # Settlement only on the largest isle, no invented hostile populations.
    for i in 5:
        var x:float=-14.0+float(i)*7.0
        k.box(Vector3(x,1.0,-11),Vector3(5,2.0,5),"l149_wood")
        k.box(Vector3(x,2.2,-11),Vector3(6,0.35,6),"l149_palm",GeoKit.ALL,false)
    k.commit()
    add_note("isles","LOST SUNS SETTLEMENT","The islands drift slowly. The winds near the boundary are stronger and the low gravity does not last forever.",Vector3(-8,0.9,-6))
    # Canon barriers are not guaranteed exits. Only controlled low chance near edge.
    var exit37:=add_exit("L149>L037#1","interact",Vector3(162,1.4,-6),Vector3(3.0,2.7,3.0),"Unstable barrier: rare chance of Level 37")
    var exit140:=add_exit("L149>L140#2","interact",Vector3(162,1.4,6),Vector3(3.0,2.7,3.0),"Unstable barrier: rare chance of Level 140")
    if exit37!=null:
        exit37.condition=func(): return _barrier_destination=="L037"
    if exit140!=null:
        exit140.condition=func(): return _barrier_destination=="L140"
    add_interactable(Vector3(153,1.0,0),Vector3(6,3,5),"Observe the unstable Barrier",func(): _test_barrier())

func _test_barrier() -> void:
    _barrier_trials+=1
    _barrier_destination=""
    # Deep barrier passages are exceptionally rare. A rolled event unlocks only one edge.
    if rng.randf()<0.002:
        _barrier_destination="L037" if rng.randf()<0.5 else "L140"
    Overlay.subtitle("[the force at the edge grows stronger; nothing certain happens]",3.0)

func level_process(delta:float) -> void:
    _barrier_t=maxf(0.0,_barrier_t-delta)
    if player!=null and player.global_position.y < -45.0 and _barrier_t <= 0.0:
        _barrier_t=2.0
        player.global_position=Vector3(0,0.25,0)
        if not SessionState.is_qa():
            Overlay.subtitle("[you wake where the island's sand is still warm]",4.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"fifteen floating islands", "ok":_island_count==15}, {"what":"more than a hundred palms", "ok":_palms>100}, {"what":"two source-limited barrier edges", "ok":exits.size()==2}]
