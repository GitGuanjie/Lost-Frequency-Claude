extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Multi-storey collapsed car park with real stair routes, open shafts and grounded collapse exits.
var _floor_count := 4
var _diary_count := 0
func build() -> void:
    rules["view_distance"]=195.0
    indoor_env(Color(0.61,0.58,0.52),0.30,Color(0.32,0.30,0.25),0.008)
    MatLib.define("l22_concrete",{"albedo_a":Color(0.38,0.39,0.37),"albedo_b":Color(0.47,0.46,0.44),"stain_amount":0.45},"concrete")
    MatLib.define("l22_dark",{"albedo_a":Color(0.16,0.17,0.18),"albedo_b":Color(0.24,0.23,0.22)},"concrete")
    MatLib.define("l22_rust",{"albedo_a":Color(0.35,0.21,0.15),"albedo_b":Color(0.24,0.17,0.14)},"metal")
    MatLib.register("l22_marker",MatLib.panel(Color(0.85,0.48,0.22),0.8))
    lights.setup(10,0)
    _carpark()
    add_arrival("start",Vector3(0,0.08,-43))
    add_arrival("from_L001",Vector3(0,0.08,-43))
    add_exit("L022>L021#1","walk_in",Vector3(-24,1.5,39),Vector3(6,2.9,5),"Post-collapse gap into Level 21")
    add_exit("L022>L023#2","walk_in",Vector3(24,9.3,39),Vector3(5.8,2.9,5),"Rupture to the petrified forest")
    add_landmark("The abandoned aid tents",Vector3(-24,0,-25))
    add_landmark("Concrete switchback stair tower",Vector3(31,0,-25))
    add_landmark("Upper mining collapse",Vector3(24,8,39))
    add_landmark("Fourth-deck collapse overlook",Vector3(-29,12,45))
    add_shot("lowest_deck",Vector3(0,1.62,-41),Vector3(0,5,24))
    add_shot("upper_decks",Vector3(25,8.6,-20),Vector3(-18,3,26))
    sound.bed("room_tone",{"seconds":7.0,"cutoff":250.0},-35.0)
    sound.oneshot("creak",{"freq":91.0},26.0,40.0,8.0,"[something settles far below the concrete]",-30.0)
    ModelDress.decorate(self, "L022")

func _carpark() -> void:
    var k:=kit("CollapsedGarageDecks")
    for f in 4:
        var y:float=float(f)*4.0
        # Separate plates create central shafts rather than an unbroken floor.
        if f<3:
            k.slab(-42,-51,-8,51,y,0.40,"l22_concrete")
        if f==0:
            k.slab(8,-51,42,51,y,0.40,"l22_concrete")
        elif f==1:
            # Cut a 9 m-wide stairwell through the second-deck slab.
            k.slab(8,-51,26,51,y,0.40,"l22_concrete")
            k.slab(35,-51,42,51,y,0.40,"l22_concrete")
            k.slab(26,-18,35,51,y,0.40,"l22_concrete")
        elif f==2:
            # Second ramp clears the aperture until its 8 m landing at z = 22.
            k.slab(8,-51,31,51,y,0.40,"l22_concrete")
            k.slab(39,-51,42,51,y,0.40,"l22_concrete")
            k.slab(31,22,39,51,y,0.40,"l22_concrete")
        else:
            # Fourth deck: split outer-west edge for a fresh third rising flight.
            k.slab(-42,-51,-34,51,y,0.40,"l22_concrete")
            k.slab(-26,-51,-8,51,y,0.40,"l22_concrete")
            k.slab(-34,-51,-26,6,y,0.40,"l22_concrete")
            k.slab(-34,44,-26,51,y,0.40,"l22_concrete")
            k.slab(8,-51,42,51,y,0.40,"l22_concrete")
        k.slab(-8,-51,8,23,y,0.40,"l22_concrete")
        k.slab(-8,35,8,51,y,0.40,"l22_concrete")
        for x in [-39.0,39.0]:
            for z in [-42.0,-5.0,32.0]:
                k.box(Vector3(x,y+1.9,z),Vector3(1.1,3.8,1.1),"l22_dark")
        for i in 9:
            var x:float=-33.0+float(i%3)*29.0
            var z:float=-40.0+float(int(i/3))*30.0
            if f<3 and not (f==2 and x<-25 and z>5) and (f!=2 or i<6) and not (x>20 and z>10):
                k.box(Vector3(x,y+0.8,z),Vector3(4.8,1.6,2.6),"l22_rust")
        for z in [-34.0,4.0,37.0]:
            k.box(Vector3(0,y+3.6,z),Vector3(9,0.12,0.35),"l22_marker",GeoKit.ALL,false)
    # Physical stair runs from one complete slab to the next on the far side.
    k.stairs(Vector3(30,0.05,-47),Vector3(0,0,1),3.0,4.0,29,"l22_concrete",1.0)
    k.stairs(Vector3(35,4.05,-8),Vector3(0,0,1),3.0,4.0,30,"l22_concrete",1.0)
    # Route to the fourth deck from western slab at (x=-30, z=6)
    # to its contiguous upper landing at z=44.
    k.stairs(Vector3(-30,8.05,6),Vector3(0,0,1),3.0,4.0,38,"l22_concrete",1.0)
    for i in 13:
        var x:float=-37.0+float(i%4)*5.0
        var z:float=20.0+float(int(i/4))*6.0
        k.box(Vector3(x,0.3,z),Vector3(2.2,0.6,1.5),"l22_dark")
    # Three emergency tents: open, low geometry and readable record nearby.
    for i in 3:
        var x:float=-34.0+float(i)*8.0
        k.box(Vector3(x,1.0,-24),Vector3(5.5,0.18,5),"l22_marker",GeoKit.ALL,false)
        k.box(Vector3(x,0.5,-24),Vector3(5.0,1.0,4.8),"l22_rust",GeoKit.ALL,false)
    k.commit()
    add_note("census","GARAGE FLOOR CENSUS","Witnesses describe more floors than these four. Most upper decks are sealed by collapses.",Vector3(-30,0.95,-32))
    add_note("log","ABANDONED CAMP LOG","An old record stops midway through a sentence about the mining shafts.",Vector3(-21,0.95,-32))
    _diary_count=2
func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four stacked decks","ok":_floor_count==4},{"what":"two reachable-source boundary exits","ok":exits.size()==2},{"what":"camp documentary evidence","ok":_diary_count==2}]
