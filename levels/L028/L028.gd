extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
## Stormstone Keep, six distinct standing stones and a protected central valley.
var _stones:Dictionary={}
var _storm_clock:=0.0
var _lightning:=false
func build()->void:
    rules["view_distance"]=490.0
    outdoor_env(Color(0.10,0.16,0.23),Color(0.18,0.23,0.31),Color(0.08,0.14,0.18),Vector2(20,45),Color(0.44,0.54,0.86),0.37,Color(0.28,0.34,0.46),0.006)
    MatLib.define("l28_blue",{"albedo_a":Color(0.17,0.25,0.37),"albedo_b":Color(0.24,0.34,0.46)},"rock")
    MatLib.define("l28_iron",{"albedo_a":Color(0.21,0.25,0.29),"albedo_b":Color(0.35,0.34,0.34)},"metal")
    MatLib.define("l28_grass",{"albedo_a":Color(0.23,0.30,0.28),"albedo_b":Color(0.28,0.38,0.33)},"grass")
    MatLib.register("l28_lamp",MatLib.panel(Color(0.86,0.83,0.69),0.9))
    lights.setup(8,1)
    _castle_and_stones()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "StormstoneUpperShelves", Vector3(60, 0, -35), 4, 3.5, "l28_blue", "l28_iron", false, 0, true)
    # DEV20: seeded multi-tier rooms; source topology and collision geometry share one JSON.
    AtriumWeave.install(self, "StormstoneUpperShelves")
    add_arrival("start",Vector3(0,0.08,-71))
    add_arrival("from_L027",Vector3(0,0.08,-71))
    add_exit("L028>L004#2","noclip",Vector3(2.5,1.6,32),Vector3(2,3,1.7),"Noclip the lamp in the keep")
    var lightning:=add_exit("L028>L073#3","condition",Vector3(-27,1.4,11),Vector3(5,3,5),"Stand near the stormstones during a strike")
    lightning.condition=func():return _lightning
    add_exit("L028>L009_3#5","walk_in",Vector3(0,1.5,-83),Vector3(8,3,3),"Follow the darkening forest")
    add_note("keep","KEEP JOURNAL","The central valley has no rain. Beyond its safety the Living Abyss grows more watchful.",Vector3(6,1.2,17))
    add_note("circle","SIX RUNES","Prudence, Hope, Faith, Fortitude, Justice and Charity stand in the stormstone circle.",Vector3(-28,1.0,-1))
    add_landmark("Six-stone circle",Vector3(-27,0,11))
    add_landmark("Stormstone Keep",Vector3(0,0,30))
    add_landmark("Forest threshold",Vector3(0,0,-83))
    add_shot("circle",Vector3(-32,1.6,-10),Vector3(-27,2,11))
    add_shot("keep",Vector3(0,1.6,0),Vector3(0,5,33))
    sound.bed("wind",{"seconds":8.0},-29.0)
    ModelDress.decorate(self, "L028")

func _castle_and_stones()->void:
    var k:=kit("StormstoneValley")
    k.slab(-89,-90,89,92,0,0.5,"l28_grass")
    for i in 6:
        var a:float=TAU*float(i)/6.0
        var x:float=-27+cos(a)*13.0
        var z:float=11+sin(a)*13.0
        k.box(Vector3(x,2.3,z),Vector3(2.0,4.6,1.9),"l28_blue")
        var index:int=i
        add_interactable(Vector3(x,1.3,z),Vector3(2.5,2.7,2.5),"Read standing stone",func():_read_stone(index))
    # Keep is traversable: walls have two entry gaps; upper walk is supported.
    k.slab(-15,15,15,51,0.1,0.6,"l28_blue")
    for x in [-14.8,14.8]:k.box(Vector3(x,3.1,33),Vector3(0.7,6.2,36),"l28_blue")
    k.box(Vector3(-8,3,15),Vector3(14,6,0.8),"l28_blue")
    k.box(Vector3(8,3,15),Vector3(14,6,0.8),"l28_blue")
    k.box(Vector3(0,3,51),Vector3(30,6,0.8),"l28_blue")
    k.slab(-15,15,-5,51,5.8,0.5,"l28_blue")
    k.slab(5,15,15,51,5.8,0.5,"l28_blue")
    k.stairs(Vector3(10,0.1,17),Vector3(0,0,1),3.0,5.7,24,"l28_blue",0.8)
    for i in 8:
        var x:float=-10.0+float(i%4)*6.0
        var z:float=29+float(int(i/4))*7
        k.box(Vector3(x,0.6,z),Vector3(3,1.2,1.5),"l28_iron")
    k.box(Vector3(2.5,2.7,32),Vector3(0.5,1.3,0.55),"l28_lamp",GeoKit.ALL,false)
    for i in 27:
        var x:float=rng.randf_range(-85,85)
        var z:float=rng.randf_range(-86,86)
        if absf(x)<19 and z>9 and z<56:continue
        k.box(Vector3(x,0.3,z),Vector3(1,0.6,1.0),"l28_blue",GeoKit.ALL,false)
    k.commit()
func _read_stone(index:int)->void:
    _stones[index]=true
    Overlay.subtitle("[the %s stone hums softly]"%["Prudence","Hope","Faith","Fortitude","Justice","Charity"][index],3.0)
func level_process(delta:float)->void:
    _storm_clock+=delta
    _lightning=(_storm_clock>84.0 and _storm_clock<94.0)
    if _storm_clock>100.0:_storm_clock=0.0
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"three source-bound boundaries","ok":exits.size()==3},{"what":"six unread stormstones","ok":_stones.size()==0},{"what":"lightning begins inactive","ok":not _lightning}]
