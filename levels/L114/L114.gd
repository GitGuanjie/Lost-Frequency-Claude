extends LevelBase
## One childhood bedroom, the same blue floral bed and a door to a downward void.
var _bed_examined:=false
var _light_on:=true
func build()->void:
    indoor_env(Color(0.53,0.58,0.62),0.41,Color(0.10,0.12,0.16),0.003)
    MatLib.define("l114_wall",{"albedo_a":Color(0.76,0.75,0.70),"albedo_b":Color(0.63,0.66,0.67)},"plaster")
    MatLib.define("l114_wood",{"albedo_a":Color(0.45,0.30,0.26),"albedo_b":Color(0.56,0.39,0.34)},"wood_floor")
    MatLib.define("l114_blue",{"albedo_a":Color(0.35,0.50,0.70),"albedo_b":Color(0.66,0.72,0.91)},"fabric")
    lights.setup(3,0)
    var k:=kit("AloneChildhoodBedroom")
    # Room occupies z[-8,8]; the back door at z=8 opens onto uncolliding abyss.
    k.slab(-7,-8,7,6,0,0.45,"l114_wood")
    for x in [-7.0,7.0]:k.box(Vector3(x,2.7,-1),Vector3(0.3,5.4,14),"l114_wall")
    k.box(Vector3(0,2.7,-8),Vector3(14,5.4,0.3),"l114_wall")
    k.box(Vector3(0,5.3,-1),Vector3(14,0.3,14),"l114_wall")
    k.box(Vector3(-3.0,0.58,-2),Vector3(2.2,1.15,4.1),"l114_blue")
    k.box(Vector3(-3.0,1.22,-2),Vector3(2.3,0.1,4.2),"l114_blue",GeoKit.ALL,false)
    k.box(Vector3(4,1.0,-5),Vector3(1.9,2.0,1.6),"l114_wood")
    k.box(Vector3(3,0.65,2),Vector3(1.7,1.3,1.7),"l114_wood")
    # The opening in the floor beyond the threshold is deliberate and uncolliding.
    k.box(Vector3(0,-7,11),Vector3(16,0.1,20),"l114_wall",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.08,4.0))
    add_arrival("from_L029",Vector3(0,0.08,4.0))
    add_arrival("from_L013",Vector3(0,0.08,4.0))
    var bed:=add_exit("L114>L009#1","interact",Vector3(-3,1.3,-2),Vector3(2.8,2.4,4.4),"Doze off on the floral bed")
    bed.condition=func():return _bed_examined
    add_exit("L114>L025#2","interact",Vector3(3,1.3,2),Vector3(2.4,2.4,2.5),"Say: I'm so bored...")
    var void_exit:=add_exit("L114>EXT#3","fall",Vector3(0,-10,11),Vector3(18,24,22),"Falling indefinitely into the void")
    void_exit.fall_y=-5.0
    add_interactable(Vector3(-3,1.2,-2),Vector3(2.4,2.0,4),"Inspect the blue floral bed",func():_ready_for_sleep())
    add_note("bed","OLD BED","The same small blue floral bed appears for every visitor. Do not turn out the light.",Vector3(3.0,1.2,-5))
    add_note("void","ROPE RECORD","The void behind the doorway has breathable air but no apparent floor or bottom.",Vector3(-5,1.2,1))
    add_landmark("Shared floral bed",Vector3(-3,0,-2))
    add_landmark("Doorway to dark falling space",Vector3(0,0,8))
    add_shot("bedroom",Vector3(1,1.6,3),Vector3(-3,1,-2))
    add_shot("void",Vector3(0,1.6,5),Vector3(0,-9,12))
    sound.bed("room_tone",{"seconds":7.0},-37.0)
func _ready_for_sleep()->void:
    _bed_examined=true
    Overlay.subtitle("[the floral sheets smell stale; sleep might take you elsewhere]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"three source exits","ok":exits.size()==3},{"what":"bed not pre-inspected","ok":not _bed_examined},{"what":"light starts on","ok":_light_on}]
