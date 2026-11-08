extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
## Machinery spans fogged halls; an uncertain original-door claim is not made a working route.
var _terminals:=0
var _power:=0
func build()->void:
    rules["view_distance"]=220.0
    indoor_env(Color(0.49,0.62,0.69),0.29,Color(0.11,0.19,0.27),0.009)
    MatLib.define("l15_concrete",{"albedo_a":Color(0.53,0.59,0.61),"albedo_b":Color(0.42,0.49,0.53)},"concrete")
    MatLib.define("l15_steel",{"albedo_a":Color(0.31,0.41,0.50),"albedo_b":Color(0.22,0.30,0.35)},"metal")
    MatLib.register("l15_light",MatLib.panel(Color(0.63,0.93,1.0),1.7))
    lights.setup(8,0)
    _engine_halls()
    VerticalArchitecture.install(self, "MachineInspection", Vector3(19, 0, 97), 4, 3.5, "l15_steel", "l15_concrete", true)
    add_landmark("Tiered machine inspection shaft", Vector3(19, 10.5, 97))
    add_arrival("start",Vector3(0,0.08,-94))
    add_landmark("Silent control desk",Vector3(0,0,-46))
    add_landmark("A disused engine gallery",Vector3(0,0,24))
    add_landmark("Glowing empty doorframe beyond the machines",Vector3(0,0,106))
    add_shot("machine_halls",Vector3(0,1.62,-89),Vector3(0,3,26))
    add_shot("doorframe",Vector3(0,1.62,78),Vector3(0,3,109))
    sound.bed("fluorescent_hum",{"seconds":6.0,"base":47.0},-32.0)
    sound.oneshot("knock",{"freq":66.0},25.0,47.0,17.0,"[far-off engines turn without power]",-28.0)
func _engine_halls()->void:
    var k:=kit("AbandonedMachineCity")
    k.slab(-38,-109,38,120,0,0.4,"l15_concrete")
    # Roof cut out above the 16x28 m service well; the tower has its own cap.
    # No invisible roof intersects the third/fourth flights.
    k.slab(-38.5,-109.5,10.2,120.0,8.5,0.4,"l15_steel")
    k.slab(27.8,-109.5,38.5,120.0,8.5,0.4,"l15_steel")
    k.slab(10.2,-109.5,27.8,81.5,8.5,0.4,"l15_steel")
    k.slab(10.2,112.5,27.8,120.0,8.5,0.4,"l15_steel")
    for x in [-38.0,38.0]:k.box(Vector3(x,4.2,5),Vector3(0.5,8.4,229),"l15_concrete")
    for z in [-109.0,120.0]:k.box(Vector3(0,4.2,z),Vector3(76,8.4,0.5),"l15_concrete")
    for i in 30:
        var x:float=-27.0+float(i%5)*13.5
        var z:float=-67.0+float(int(i/5))*29.0
        k.box(Vector3(x,2.0,z),Vector3(6.8,4.0,7.4),"l15_steel")
        k.box(Vector3(x,4.5,z),Vector3(3.4,1.0,1.4),"l15_light",GeoKit.ALL,false)
    for i in 15:
        var z:float=-98.0+float(i)*14.0
        k.box(Vector3(0,8.1,z),Vector3(4.8,0.12,1.4),"l15_light",GeoKit.ALL,false)
        if i%2==0:lights.add_anchor(Vector3(0,7.7,z),Color(0.72,0.91,1.0),0.7,18,0.9,"l15_light")
    # Empty, brilliant frame with no live exit until canon conditions are resolved.
    for x in [-2.4,2.4]:k.box(Vector3(x,3,109),Vector3(0.3,6.0,0.4),"l15_light",GeoKit.ALL,false)
    k.box(Vector3(0,6,109),Vector3(5.1,0.3,0.5),"l15_light",GeoKit.ALL,false)
    k.commit()
    for i in 3:
        var index:int=i
        add_interactable(Vector3(-24+float(i)*23,1.2,-46),Vector3(2,2,2),"Inspect control terminal",func():_terminal(index))
        _terminals+=1
    add_note("dossier","THE EMPTY FRAME","The doorframe shines into a sky of stars, but its destination is unknown.",Vector3(1,0.92,91))
func _terminal(index:int)->void:
    _power+=1
    Overlay.subtitle("[terminal %d displays an incomplete machinery record]"%(index+1),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"three inspectable terminals","ok":_terminals==3},{"what":"no unsourced route to L010","ok":exits.is_empty()},{"what":"safe original start","ok":arrivals.has("start")}]
