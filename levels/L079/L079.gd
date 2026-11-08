extends LevelBase
## Seven ordered research rooms and one unsafe original door. No fabricated destination.
var _machine_clock:=0.0
var _tremors:=0
var _rooms:=7
var _clock_lights: Array = []
var _clock_meshes: Array = []
var _clock_phase := 0
func build()->void:
    rules["view_distance"]=120.0
    indoor_env(Color(0.63,0.75,0.76),0.28,Color(0.17,0.24,0.26),0.004)
    MatLib.define("l79_tile",{"albedo_a":Color(0.74,0.83,0.81),"albedo_b":Color(0.61,0.72,0.70)},"pool_tile")
    MatLib.define("l79_wall",{"albedo_a":Color(0.77,0.82,0.79),"albedo_b":Color(0.65,0.72,0.70)},"plaster")
    MatLib.define("l79_metal",{"albedo_a":Color(0.28,0.43,0.45),"albedo_b":Color(0.18,0.26,0.28)},"metal")
    MatLib.register("l79_lamp",MatLib.panel(Color(0.57,0.95,0.92),1.2))
    lights.setup(10,0)
    _clinic()
    _clock_bank28()
    add_arrival("start",Vector3(0,0.08,-48))
    add_landmark("Entry and the only known door",Vector3(0,0,-51))
    add_landmark("Machine at the end of the corridor",Vector3(0,0,49))
    add_shot("clinic_corridor",Vector3(0,1.62,-47),Vector3(0,1.6,43))
    add_shot("machine_room",Vector3(0,1.62,34),Vector3(0,2,51))
    sound.bed("fluorescent_hum",{"seconds":7.0,"base":48.0},-31.0)
    sound.oneshot("knock",{"freq":97.0},32.0,48.0,11.0,"[something knocks behind the medical machine]",-29.0)
func _clinic()->void:
    var k:=kit("SevenRoomClinic")
    k.slab(-23,-54,23,57,0,0.38,"l79_tile")
    k.box(Vector3(0,5.2,1),Vector3(46,0.3,112),"l79_wall")
    for x in [-23.0,23.0]:k.box(Vector3(x,2.6,1),Vector3(0.35,5.2,112),"l79_wall")
    for z in [-54.0,57.0]:k.box(Vector3(0,2.6,z),Vector3(46,5.2,0.35),"l79_wall")
    # Corridor is six metres wide; each side room has an open threshold.
    for n in 6:
        var z:float=-37.0+float(n)*16.0
        var side:float=-1.0 if n%2==0 else 1.0
        var x:float=side*14.0
        for dz in [-6.5,6.5]:k.box(Vector3(x,2.55,z+dz),Vector3(18,5.1,0.3),"l79_wall")
        k.box(Vector3(side*5.5,3.75,z),Vector3(0.25,2.3,12),"l79_wall")
        for j in 3:
            k.box(Vector3(x+(float(j)-1.0)*3.6,0.9,z+2),Vector3(2.2,1.8,1.4),"l79_metal")
    for i in 8:
        var z:float=-46+float(i)*13.0
        k.box(Vector3(0,5.03,z),Vector3(2.4,0.07,1.2),"l79_lamp",GeoKit.ALL,false)
        lights.add_anchor(Vector3(0,4.8,z),Color(0.71,0.91,0.87),0.65,13,0.9,"l79_panel")
    k.box(Vector3(0,1.6,49),Vector3(7,3.2,4),"l79_metal")
    k.commit()
    add_note("chronicle","STAFF CHRONICLE","A person walked through the door, then returned to find the corridor somehow different.",Vector3(-10,0.91,-30))
    add_note("warning","MACHINE LOG","The central machine convulses every thirty minutes. The measured time inside cannot be trusted.",Vector3(4,0.91,42))
## DEV28: 16 separately visible dials in a 4x4 bank near the end machine.
## A single optional interaction shifts their indicated times; it never
## teleports the player or changes the one-source-exit interpretation.
func _clock_bank28() -> void:
    var k := kit("DEV28_16Clocks")
    for i in 16:
        var c := Vector3(-2.7+float(i%4)*1.8,.64+float(int(i/4))*.80,46.87)
        k.box(c,Vector3(1.32,.70,.15),"l79_metal",GeoKit.ALL,false)
        k.box(c+Vector3(0,0,-.09),Vector3(.88,.48,.04),"l79_lamp",GeoKit.ALL,false)
        var needle := MeshInstance3D.new()
        needle.name="DEV28_ClockHand_%02d"%i
        var bm := BoxMesh.new()
        bm.size=Vector3(.045,.26,.03)
        needle.mesh=bm
        needle.position=c+Vector3(0,0,-.14)
        needle.rotation.z=float(i)*.42
        needle.material_override=MatLib.get_mat("l79_metal")
        add_child(needle)
        _clock_meshes.append(needle)
    k.commit()
    add_interactable(Vector3(0,1.1,43.4),Vector3(2.1,2.0,1.8),
        "Observe the sixteen disagreeing clocks",func(_p):_retime28())
    add_landmark("Sixteen incompatible clocks",Vector3(0,2.4,45.4))

func _retime28() -> void:
    _clock_phase+=1
    for i in _clock_meshes.size():
        (_clock_meshes[i] as MeshInstance3D).rotation.z=float(i)*.42+float(_clock_phase)*.68
    Overlay.subtitle("[the sixteen clocks disagree again; the corridor stays put]",3.8)
    SaveService.record_discovery(stable_id,"dev28:sixteen_clocks",
        "Sixteen clocks display conflicting times in the final clinic chamber.","ADAPTATION")

func level_process(delta:float)->void:
    _machine_clock+=delta
    if _machine_clock>=1800.0:
        _machine_clock=0.0
        _tremors+=1
        if not SessionState.is_qa():Overlay.subtitle("[the machine shudders; sobbing echoes through seven rooms]",6.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"seven ordered clinical rooms","ok":_rooms==7},{"what":"no invented exit target","ok":exits.is_empty()},{"what":"thirty-minute machine event","ok":_machine_clock>=0.0}]
