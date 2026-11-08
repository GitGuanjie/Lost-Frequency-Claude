extends LevelBase
## The SS Fun =) ship. Navigation is physical; no graphic violence is portrayed.
var _cabins:=0
var _posters:=0
var _fog_time:=0.0
func build()->void:
    rules["view_distance"]=240.0
    indoor_env(Color(0.58,0.66,0.53),0.47,Color(0.13,0.36,0.28),0.008)
    MatLib.define("l26_steel",{"albedo_a":Color(0.32,0.39,0.40),"albedo_b":Color(0.42,0.46,0.44)},"metal")
    MatLib.define("l26_wood",{"albedo_a":Color(0.46,0.28,0.22),"albedo_b":Color(0.53,0.34,0.25)},"wood_floor")
    MatLib.define("l26_party",{"albedo_a":Color(0.72,0.30,0.38),"albedo_b":Color(0.86,0.56,0.32)},"plaster")
    MatLib.register("l26_sign",MatLib.panel(Color(0.63,1.0,0.57),1.6))
    lights.setup(10,1)
    _ship()
    add_arrival("start",Vector3(0,0.08,-45))
    add_exit("L026>L004#1","interact",Vector3(-4,1.5,52),Vector3(2.2,2.6,1.5),"Touch the reversed and blurred poster")
    var overboard:=add_exit("L026>EXT#2","fall",Vector3(22,-10,38),Vector3(18,24,16),"Fall overboard")
    overboard.fall_y=-4.0
    add_note("deck","SS FUN =)","The liner is much larger below deck than its hull can contain. Its electricity has no visible generator.",Vector3(3,1.0,-61))
    add_landmark("Stern ascent and return catwalk",Vector3(0,4,63))
    add_shot("stern_upper_loop",Vector3(-7,5.6,65),Vector3(7,5.2,51))
    add_landmark("Open air pool deck",Vector3(0,4,20))
    add_landmark("Repetitious cabins",Vector3(0,0,0))
    add_landmark("Unfocused poster",Vector3(-4,0,52))
    add_shot("lower_corridor",Vector3(0,1.62,-65),Vector3(0,2,40))
    add_shot("upper_deck",Vector3(-7,4.6,0),Vector3(0,4.4,58))
    sound.bed("room_tone",{"seconds":7.0},-29.0)
func _ship()->void:
    var k:=kit("EndlessLiner")
    # Two occupied elevations connected at the bow by a stair run.
    k.slab(-11,-75,11,78,0,0.5,"l26_steel")
    k.slab(-11,-75,-3,78,4,0.4,"l26_wood")
    k.slab(3,-75,11,78,4,0.4,"l26_wood")
    for x in [-11.0,11.0]:k.box(Vector3(x,1.65,0),Vector3(0.5,3.3,153),"l26_steel")
    for z in [-72.0,77.0]:k.box(Vector3(0,1.6,z),Vector3(22,3.2,0.5),"l26_steel")
    for i in 18:
        var z:float=-63.0+float(i)*7.1
        k.box(Vector3(-6.7,1.6,z),Vector3(0.3,3.2,4.5),"l26_wood")
        k.box(Vector3(6.7,1.6,z),Vector3(0.3,3.2,4.5),"l26_wood")
        if i%3==0:k.box(Vector3(-9,0.52,z),Vector3(2,0.9,1.3),"l26_party")
        _cabins+=2
    # A supported bridge from the stair top to both upper port/starboard walkways.
    k.slab(-3.1,-57,3.1,-49,4,0.4,"l26_wood")
    # An actual broad stair flight from one deck to the other.
    k.stairs(Vector3(0,0.05,-72),Vector3(0,0,1),4.2,4.0,20,"l26_steel",0.85)
    for i in 16:
        var z:float=-57+float(i)*8.0
        k.box(Vector3(-9.0,6.0,z),Vector3(1.8,1.2,2.1),"l26_party",GeoKit.ALL,false)
    # DEV28: a second, independent way up near the stern. The original bow
    # staircase is retained; the transverse upper deck completes a real loop.
    # Start +Z and land at z=60.4, under neither upper flank slab.
    k.stairs(Vector3(0,0.05,40.0), Vector3.BACK, 3.2, 4.0, 20, "l26_steel", 1.02)
    k.slab(-3.2,59.6,3.2,67.6,4.0,0.4,"l26_wood")
    # The transverse section deliberately overlaps both existing catwalks
    # at x=-3 and x=3, eliminating separate upper-deck dead ends.
    for x in [-2.9,2.9]:
        k.box(Vector3(x,4.65,65.5),Vector3(.15,1.25,.16),"l26_steel",GeoKit.ALL,false)
    # A blurry green signage row and cinema/themed party rooms.
    for i in 10:
        var z:float=-60+float(i)*12
        k.box(Vector3(8,2.8,z),Vector3(0.3,0.7,2.0),"l26_sign",GeoKit.ALL,false)
    k.commit()
    for i in 6:
        add_interactable(Vector3(-7.0,1.1,-45+float(i)*15),Vector3(2,2,3),"Inspect deserted party room",func():_posters+=1)
func level_process(delta:float)->void:
    _fog_time+=delta
    if _fog_time>83:
        _fog_time=0.0
        if not SessionState.is_qa():Overlay.subtitle("[green fog swallows the horizon, then dissipates]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"cruise cabin modules","ok":_cabins==36},{"what":"sourced poster and overboard exits","ok":exits.size()==2},{"what":"ship not pre-explored","ok":_posters==0}]
