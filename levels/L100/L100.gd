extends LevelBase
## A quiet sandbar, graves and a motionless turquoise sea. Testimony, not a combat level.
var _read_count:=0
var _read_set:=[false,false,false,false]
var _sea:WaterVolume
func build()->void:
    rules["view_distance"]=590.0
    outdoor_env(Color(0.38,0.70,0.90),Color(0.82,0.88,0.91),Color(0.58,0.66,0.60),Vector2(62,25),Color(1.0,0.93,0.81),0.94,Color(0.55,0.78,0.84),0.001)
    MatLib.define("l100_sand",{"albedo_a":Color(0.91,0.82,0.68),"albedo_b":Color(0.98,0.89,0.71)},"sand")
    MatLib.define("l100_stone",{"albedo_a":Color(0.49,0.49,0.48),"albedo_b":Color(0.63,0.62,0.59)},"rock")
    MatLib.register("l100_sea",MatLib.water({}))
    lights.setup(2,0)
    var k:=kit("BriefPeaceSandbar")
    # The central straight ribbon of land is narrow; the ocean remains static.
    k.slab(-9,-151,9,151,0.05,0.48,"l100_sand")
    for i in 12:
        var z:float=-117+float(i)*21
        var x:float=-4.0 if i%2==0 else 4.0
        k.box(Vector3(x,0.9,z),Vector3(1.0,1.8,0.28),"l100_stone")
        k.box(Vector3(x,1.93,z),Vector3(1.2,0.17,0.4),"l100_stone")
    k.commit()
    _sea=WaterVolume.new()
    add_child(_sea)
    _sea.setup(Vector3(-125,-18,-170),Vector3(125,0.0,170),"l100_sea",true)
    # The sea should never produce a floor collision; only the sandbar supports walkers.
    add_arrival("start",Vector3(0,0.12,-142))
    add_arrival("from_L048",Vector3(0,0.12,-142))
    var end:=add_exit("L100>L004#1","dwell",Vector3(18,-0.2,130),Vector3(18,2.7,17),"Swim away into the static water")
    end.hold_seconds=15.0
    for i in 4:
        var index:int=i
        add_interactable(Vector3(-4 if i%2==0 else 4,1.2,-117+float(i)*63),Vector3(1.8,2.2,1.7),"Read unnamed gravestone",func():_read(index))
    add_note("sand","A BRIEF PEACE","There are no waves beyond the strip. The sand seems to go on in both directions.",Vector3(1.5,0.6,-137))
    add_landmark("First lonely grave",Vector3(-4,0,-117))
    add_landmark("Distant headstone trail",Vector3(4,0,112))
    add_shot("still_ocean",Vector3(0,1.62,-139),Vector3(0,1.6,66))
    add_shot("headstones",Vector3(0,1.62,20),Vector3(4,1.1,110))
    sound.bed("wind",{"seconds":8.0},-38.0)
func _read(_i:int)->void:
    _read_count+=1
    if _i>=0 and _i<_read_set.size() and not _read_set[_i]:
        _read_set[_i]=true
        SaveService.record_discovery("L100","dev25:grave:%d"%_i,
            "A weathered inscription beside the still water. No names are invented.","ADAPTATION")
        Overlay.subtitle("[one forgotten grave has been added to your notes]",3.0)
    else:
        Overlay.subtitle("[the waves are still; there is nothing new to read]",3.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"source testimony exit","ok":exits.size()==1},{"what":"swimmable water defined","ok":_sea!=null},{"what":"headstones initially unread","ok":_read_count==0}]
