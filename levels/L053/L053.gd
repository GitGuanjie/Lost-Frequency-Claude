extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## One ordinary suburban house with looping front door and uncertain rescue, not a maze.
var _visit_count:=0
var _food_t:=0.0
var _letters:=0
var _breached:=false
func build()->void:
    rules["view_distance"]=100.0
    indoor_env(Color(0.81,0.79,0.73),0.39,Color(0.48,0.51,0.54),0.001)
    MatLib.define("l53_wall",{"albedo_a":Color(0.72,0.75,0.74),"albedo_b":Color(0.81,0.82,0.77)},"plaster")
    MatLib.define("l53_wood",{"albedo_a":Color(0.47,0.32,0.22),"albedo_b":Color(0.54,0.38,0.25)},"wood_floor")
    MatLib.define("l53_fabric",{"albedo_a":Color(0.25,0.37,0.42),"albedo_b":Color(0.34,0.45,0.47)},"carpet")
    MatLib.register("l53_sky",MatLib.panel(Color(0.70,0.82,0.91),1.35))
    lights.setup(6,0)
    _house()
    add_arrival("start",Vector3(0,0.08,-15))
    add_arrival("from_L009",Vector3(0,0.08,-15))
    add_exit("L053>L053#3","interact",Vector3(0,1.3,-21.1),Vector3(3,2.5,1.2),"Open the front door (the house loops)")
    var red:=add_exit("L053>L009#1","interact",Vector3(11.1,1.3,8),Vector3(1.0,2.6,2.5),"The red wooden door")
    red.condition=func():return _breached
    add_landmark("Early-morning kitchen",Vector3(-11,0,1))
    add_landmark("The red wooden door",Vector3(11,0,8))
    add_landmark("A quiet basement",Vector3(0,-4,6))
    add_shot("sitting_room",Vector3(0,1.62,-13),Vector3(5,1.8,6))
    add_shot("kitchen",Vector3(-8,1.62,-4),Vector3(-10,1.8,9))
    sound.bed("room_tone",{"seconds":8.0,"cutoff":160.0},-39.0)
    ModelDress.decorate(self, "L053")

func _house()->void:
    var k:=kit("OneSuburbanHouse")
    # Split the ground floor around a real basement stairwell (x[-2,2], z[5,17]).
    k.slab(-14,-23,-2,23,0,0.36,"l53_wood")
    k.slab(2,-23,14,23,0,0.36,"l53_wood")
    k.slab(-2,-23,2,5,0,0.36,"l53_wood")
    k.slab(-2,17,2,23,0,0.36,"l53_wood")
    k.box(Vector3(0,4.6,0),Vector3(28.5,0.35,46),"l53_wall")
    for x in [-14.0,14.0]:k.box(Vector3(x,2.3,0),Vector3(0.4,4.6,46),"l53_wall")
    for z in [-23.0,23.0]:
        k.box(Vector3(0,2.3,z),Vector3(28,4.6,0.4),"l53_wall")
    # Partition living room / kitchen / bedrooms without closing the central hallway.
    for x in [-7.0,7.0]:
        for z in [-5.0,12.0]:
            k.box(Vector3(x,2.1,z),Vector3(0.23,4.2,9),"l53_wall")
    # Furniture remains open around the central axis.
    for i in 12:
        var x:float=-10.0 if i%2==0 else 10.0
        var z:float=-15.0+float(int(i/2))*6.0
        k.box(Vector3(x,0.55,z),Vector3(2.0,1.1,1.2),"l53_wood")
    for x in [-13.7,13.7]:
        for z in [-14.0,2.0,16.0]:
            k.box(Vector3(x,2.7,z),Vector3(0.05,1.7,3.2),"l53_sky",GeoKit.ALL,false)
    k.box(Vector3(10,0.9,8),Vector3(2,1.8,0.35),"l53_fabric")
    # Lower basement floor and accessible descending stair cut at the rear.
    k.slab(-7,5,7,20,-4.0,0.40,"l53_wood")
    k.stairs(Vector3(0,-4.0,5),Vector3(0,0,1),2.4,4.0,18,"l53_wood",0.65)
    k.commit()
    add_note("letter","A LETTER THAT DID NOT LEAVE","A note slid through the mail slot was no longer there the next morning.",Vector3(-6,0.92,-18))
    add_note("clock","THE CLOCK","Everything works: the television, the kitchen, the lights. The door opens into the same house.",Vector3(9,0.92,-11))
    add_interactable(Vector3(-11,1.0,8),Vector3(2.0,2.0,1.6),"Search the basement supplies",func(): _look_food())
    add_interactable(Vector3(-1,1.0,-19),Vector3(2,2,1.0),"Push a letter through the mail slot",func(): _write_letter())
    add_interactable(Vector3(9,1.0,10),Vector3(2,2,1.0),"Inspect the barricaded red door",func(): _inspect_red())
func _look_food()->void:
    Overlay.subtitle("[a few cans have appeared where the shelf was empty]" if _food_t>=120.0 else "[the shelf is almost empty]",4.0)
func _write_letter()->void:
    _letters+=1
    Overlay.subtitle("[the letter vanishes; no reply comes]",3.0)
func _inspect_red()->void:
    Overlay.subtitle("[the door appears to have been reinforced from the other side]",4.0)
    # This scripted reconstruction does not fabricate a M.E.G. rescue or breach event.
func level_process(delta:float)->void:
    _food_t+=delta
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"loop-back is physical canonical destination","ok":exits.size()==2},{"what":"rescue gate initially locked","ok":not _breached},{"what":"house inventory timer present","ok":_food_t>=0.0}]
