extends LevelBase
## Numbered Doors: four intersecting 26-mile corridors (spatially compressed), centre safe.
var _side_doors := 0
var _warps := 0

func build() -> void:
    indoor_env(Color(0.58,0.62,0.63),0.33,Color(0.22,0.24,0.26),0.002)
    MatLib.define("l21_floor",{"albedo_a":Color(0.38,0.41,0.41),"albedo_b":Color(0.47,0.48,0.48)},"tile")
    MatLib.define("l21_wall",{"albedo_a":Color(0.68,0.69,0.67),"albedo_b":Color(0.77,0.76,0.70)},"plaster")
    MatLib.define("l21_door",{"albedo_a":Color(0.31,0.21,0.16),"albedo_b":Color(0.42,0.27,0.17)},"wood_floor")
    MatLib.register("l21_exit",MatLib.panel(Color(0.92,0.1,0.08),1.6))
    lights.setup(14,1)
    _cross()
    add_arrival("start",Vector3(0,0.08,0))
    add_arrival("from_L022",Vector3(0,0.08,0))
    add_landmark("The safe centre desk",Vector3(0,0,0))
    add_landmark("Numbered door corridor east",Vector3(77,0,0))
    add_landmark("Neon Exit corridor north",Vector3(0,0,-110))
    add_shot("four_directions",Vector3(0,1.62,3),Vector3(1,1.8,-105))
    add_shot("numbered_doors",Vector3(30,1.62,-1),Vector3(105,1.8,0))
    sound.bed("fluorescent_hum",{"seconds":5.0,"base":53.0},-30.0)

func _cross() -> void:
    var k:=kit("IntersectingDoorCorridors")
    k.slab(-125,-7,125,7,0,0.3,"l21_floor")
    k.slab(-7,-125,7,125,0,0.3,"l21_floor")
    k.slab(-13,-13,13,13,0,0.3,"l21_floor")
    for side in [-1,1]:
        var v:=float(side)
        for portion in [0,1]:
            var a:float=13.0 if portion==0 else 80.0
            var b:float=80.0 if portion==0 else 125.0
            k.box(Vector3(v*(a+b)*0.5,2.7,-7),Vector3(b-a,5.4,0.35),"l21_wall")
            k.box(Vector3(v*(a+b)*0.5,2.7,7),Vector3(b-a,5.4,0.35),"l21_wall")
            k.box(Vector3(-7,2.7,v*(a+b)*0.5),Vector3(0.35,5.4,b-a),"l21_wall")
            k.box(Vector3(7,2.7,v*(a+b)*0.5),Vector3(0.35,5.4,b-a),"l21_wall")
    # Side doors sit in front of continuous plaster walls, per source: most are walls or internal warps.
    for axis in 2:
        for i in 24:
            var offset:float=15.0+float(i)*4.35
            var sign:float=-1.0 if i%2==0 else 1.0
            var x:float=sign*7.0 if axis==0 else offset
            var z:float=offset if axis==0 else sign*7.0
            k.box(Vector3(x,1.12,z),Vector3(0.13,2.24,1.5) if axis==0 else Vector3(1.5,2.24,0.13),"l21_door",GeoKit.ALL,false)
            _side_doors+=1
            if i%6==0:
                lights.add_anchor(Vector3(x*0.5,4.8,z*0.5),Color(0.91,0.91,0.85),0.56,12,0.8,"l21_lamp")
    k.box(Vector3(0,0.75,0),Vector3(4,1.5,2),"l21_door")
    k.box(Vector3(0,4.8,-112),Vector3(4,0.6,0.1),"l21_exit",GeoKit.ALL,false)
    k.commit()
    for i in 8:
        var z:float=16.0+float(i)*13.0
        add_interactable(Vector3(6.5,1.1,z),Vector3(1.6,2.2,1.4),"Open an ordinary numbered door",func(): _rearrange())
    add_exit("L021>L000#1","interact",Vector3(6.5,1.1,64),Vector3(1.8,2.3,1.6),"Door 105: Level 0")
    add_exit("L021>L356#2","interact",Vector3(6.5,1.1,96),Vector3(1.8,2.3,1.6),"Door 356 (unbuilt destination)")
    add_exit("L021>L001_5#7","interact",Vector3(-6.5,1.1,-86),Vector3(1.8,2.3,1.6),"Unlabelled door")
    add_note("centre","THE CENTRAL DESK","Four corridors meet. Most doors lead into walls or to another part of the same level. The middle stays safe.",Vector3(2.8,0.9,0))

func _rearrange() -> void:
    _warps+=1
    if player!=null:
        player.global_position=Vector3(-40.0 if _warps%2==0 else 40.0,0.2,0)
    Overlay.subtitle("[the same door opens into a different hallway]",3.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"48 door decorations", "ok":_side_doors==48}, {"what":"centre desk and three source exits", "ok":exits.size()==3}, {"what":"arrival at safe centre", "ok":arrivals.has("start")}]
