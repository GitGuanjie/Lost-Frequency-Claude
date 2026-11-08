extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Void Basement. The source documents NO reliable escape, so this is an expedition dead end.
var _data_errors:=0
var _fade_seconds:=0.0
func build()->void:
    indoor_env(Color(0.24,0.27,0.31),0.17,Color(0.10,0.12,0.14),0.018)
    MatLib.define("l71_block",{"albedo_a":Color(0.24,0.27,0.29),"albedo_b":Color(0.32,0.32,0.33)},"concrete")
    MatLib.define("l71_pipe",{"albedo_a":Color(0.20,0.22,0.22),"albedo_b":Color(0.30,0.34,0.34)},"metal")
    MatLib.register("l71_error",MatLib.panel(Color(0.60,0.70,0.79),0.4))
    lights.setup(4,0)
    var k:=kit("Error0071Basement")
    k.slab(-62,-95,62,95,-0.1,0.5,"l71_block")
    k.box(Vector3(0,6,-0.0),Vector3(126,0.4,190),"l71_block")
    for x in [-61.0,61.0]:k.box(Vector3(x,3,0),Vector3(0.5,6,190),"l71_block")
    for z in [-94.0,94.0]:k.box(Vector3(0,3,z),Vector3(124,6,0.5),"l71_block")
    for i in 27:
        var x:float=-48+float(i%9)*12
        var z:float=-72+float(int(i/9))*56
        if absf(x)<8 and z<0:continue
        k.box(Vector3(x,3,z),Vector3(1.8,6,1.8),"l71_block")
        if i%3==0:k.box(Vector3(x,5.5,z),Vector3(2.8,0.25,0.32),"l71_pipe")
    for i in 12:
        var z:float=-68+float(i)*12
        if i%4!=3:k.box(Vector3(0,5.78,z),Vector3(2,0.1,0.7),"l71_error",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,-0.02,-84))
    add_arrival("from_L004",Vector3(0,-0.02,-84))
    add_note("entry","ERROR 0071","Description and entry data cannot be loaded. The entrance has closed behind you.",Vector3(6,1,-79))
    add_note("shade","CORRUPTED RECORD","The exit file cannot be read. The walls seem to forget their previous shape.",Vector3(-12,1,44))
    for i in 3:
        add_interactable(Vector3(-33+float(i)*24,1,-10),Vector3(2,2,2),"Search basement record",func():_look())
    add_landmark("Sealed basement entrance",Vector3(0,0,-84))
    add_landmark("Corrupted storage rows",Vector3(0,0,55))
    add_shot("dark_basement",Vector3(0,1.6,-80),Vector3(0,1.6,35))
    add_shot("corrupted_storage",Vector3(21,1.6,20),Vector3(-31,2,59))
    sound.bed("room_tone",{"seconds":8.0},-36.0)
    ModelDress.decorate(self, "L071")

func _look()->void:
    _data_errors+=1
    Overlay.subtitle("[entry could not be loaded: ERROR 0071]",3.0)
func level_process(delta:float)->void:
    _fade_seconds+=delta
    if _fade_seconds>70.0:
        _fade_seconds=0.0
        if not SessionState.is_qa():Overlay.subtitle("[you can still walk, although the room seems less real]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"no fabricated escape","ok":exits.is_empty()},{"what":"actual source entrance","ok":arrivals.has("from_L004")},{"what":"records not yet inspected","ok":_data_errors==0}]
