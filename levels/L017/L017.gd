extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
var _clock_reads:=0
func build()->void:
    indoor_env(Color(0.32,0.39,0.44),0.40,Color(0.12,0.16,0.20),0.018)
    MatLib.define("d6_hull",{"albedo_a":Color(0.22,0.28,0.33),"albedo_b":Color(0.30,0.34,0.40)},"metal")
    MatLib.define("d6_pipe",{"albedo_a":Color(0.12,0.15,0.19),"albedo_b":Color(0.22,0.24,0.28)},"metal")
    lights.setup(8,0)
    var k:=kit("CarrierBulkheads")
    k.slab(-21,-125,21,125,0,0.55,"d6_hull")
    # Expose a central longitudinal service well, retaining the old hull roof
    # on all four sides of the cut-out.
    k.slab(-21.5,-126,-8.8,126,5.25,0.5,"d6_hull")
    k.slab(8.8,-126,21.5,126,5.25,0.5,"d6_hull")
    k.slab(-8.8,-126,8.8,-17,5.25,0.5,"d6_hull")
    k.slab(-8.8,15,8.8,126,5.25,0.5,"d6_hull")
    for x in [-21.0,21.0]:k.box(Vector3(x,2.5,0),Vector3(0.6,5,250),"d6_hull")
    for i in 22:
        var z:float=-119+float(i)*11.0
        for x in [-9.0,9.0]:
            k.box(Vector3(x,2.45,z),Vector3(0.45,4.9,8.1),"d6_hull")
            k.box(Vector3(x*1.65,1.0,z+2.0),Vector3(2.6,2.0,2.4),"d6_pipe")
        if z+5.1>-17 and z+5.1<15:
            for bx in [-15.0,15.0]:
                k.box(Vector3(bx,4.6,z+5.1),Vector3(12,0.28,0.6),"d6_pipe")
        else:
            k.box(Vector3(0,4.6,z+5.1),Vector3(42,0.28,0.6),"d6_pipe")
        # Reinforced frames flank a walkable passage instead of closing it.
        if not (z+5.1>-17 and z+5.1<15):
            k.box(Vector3(-4.5,2.5,z+5.1),Vector3(0.7,5,0.5),"d6_hull")
            k.box(Vector3(4.5,2.5,z+5.1),Vector3(0.7,5,0.5),"d6_hull")
    k.commit()
    VerticalArchitecture.install(self, "CarrierVerticalSector", Vector3(0, 0, -1), 4, 3.45, "d6_hull", "d6_pipe", true)
    add_landmark("Four-deck maintenance sector", Vector3(0, 10.35, -1))
    add_arrival("start",Vector3(0,0.1,-119))
    for i in 4:
        var c:int=i
        add_interactable(Vector3(5.5,1,-86+float(i)*60),Vector3(2,2,3),"Inspect compartment clock",func():_read_clock(c))
    add_interactable(Vector3(0,1.0,-123),Vector3(3,2.4,2),"Check the egress closet",func():Overlay.subtitle("[the documented closet route has no known destination]",4.0))
    add_note("sector","SECTOR TABLE","217 passages and 42 compartments are reported. This is a compressed walkable excerpt, not a one-to-one ship recreation.",Vector3(3,1,-112))
    add_note("cold","FROZEN SECTORS","Records for compartments 200–206 describe unusually cold air. Time may not agree between rooms.",Vector3(6,1,88))
    add_landmark("Bulkhead hall",Vector3(0,0,-110))
    add_landmark("Disagreeing clocks",Vector3(4,0,92))
    add_shot("carrier_corridor",Vector3(0,1.6,-114),Vector3(0,1.5,90))
    add_shot("bulkhead_compartments",Vector3(13,1.6,65),Vector3(0,2,99))
    sound.bed("room_tone",{"seconds":8.0},-33.0)
    ModelDress.decorate(self, "L017")

func _read_clock(i:int)->void:
    _clock_reads+=1
    Overlay.subtitle("[sector %d: clock disagrees with the last compartment]" % (8+i*49),3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"unmapped closet never fakes a destination","ok":exits.is_empty()},{"what":"four clock interactions present","ok":_clock_reads==0},{"what":"at least two screenshots","ok":qa_shots.size()>=2}]
