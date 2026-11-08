extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## One permitted route: stay below the parapet. Bunkers, changing weather and source-bound exits.
var _storm:=false
var _flood:=false
var _weather_time:=0.0
var _bunkers:=0
func build()->void:
    rules["view_distance"]=320.0
    outdoor_env(Color(0.17,0.21,0.22),Color(0.35,0.35,0.31),Color(0.17,0.13,0.12),Vector2(32,-70),Color(0.72,0.76,0.73),0.40,Color(0.27,0.29,0.28),0.010)
    MatLib.define("l49_mud",{"albedo_a":Color(0.25,0.19,0.15),"albedo_b":Color(0.14,0.12,0.11),"wetness":0.80},"dirt")
    MatLib.define("l49_wood",{"albedo_a":Color(0.28,0.19,0.14),"albedo_b":Color(0.20,0.13,0.10)},"wood_floor")
    MatLib.define("l49_bag",{"albedo_a":Color(0.43,0.40,0.31),"albedo_b":Color(0.35,0.33,0.25)},"concrete")
    MatLib.define("l49_steel",{"albedo_a":Color(0.24,0.24,0.22),"albedo_b":Color(0.17,0.17,0.16)},"metal")
    MatLib.register("l49_alarm",MatLib.panel(Color(0.21,0.39,0.64),0.8))
    lights.setup(4,0)
    _network()
    add_arrival("start",Vector3(0,-2.92,-100))
    add_arrival("from_L011",Vector3(0,-2.92,-100))
    add_arrival("from_L048",Vector3(0,-2.92,-100))
    add_exit("L049>L014#1","interact",Vector3(21,-1.6,18),Vector3(2.2,2.6,1.0),"Rusted bunker door 14")
    add_exit("L049>L050#3","interact",Vector3(-21,-1.6,90),Vector3(2.2,2.6,1.0),"Rusted bunker door 50")
    var lightning:=add_exit("L049>L003#4","condition",Vector3(0,-1.6,107),Vector3(4,2.8,3),"A nearby lightning strike")
    lightning.condition=func():return _storm
    var flood_gate:=add_exit("L049>L007#5","interact",Vector3(0,-1.7,-104),Vector3(3.2,2.7,2.0),"Flooded escape tunnel")
    flood_gate.condition=func():return _flood
    add_landmark("Northern ruined bunker",Vector3(21,-3,18))
    add_landmark("Southern bunker wall",Vector3(-21,-3,90))
    add_landmark("Flood tunnel at the entrance",Vector3(0,-3,-104))
    add_shot("trench_route",Vector3(0,-1.4,-99),Vector3(0,-1.1,45))
    add_shot("bunkers",Vector3(0,-1.4,12),Vector3(21,-1,18))
    sound.bed("wind",{"seconds":8.0},-29.0)
    sound.oneshot("knock",{"freq":64.0},22.0,38.0,14.0,"[distant gunfire beyond the parapet]",-30.0)
    ModelDress.decorate(self, "L049")

func _network()->void:
    var k:=kit("MudTrenchSystem")
    k.slab(-12,-115,12,117,-3.0,0.5,"l49_mud")
    for x in [-8.0,8.0]:
        # Omit the wall at the correct bunker's mouth; the connecting corridor
        # must be physically traversable, not a door floating outside solid soil.
        var cuts:Array = [[-115.0,8.0],[28.0,117.0]] if x>0 else [[-115.0,80.0],[100.0,117.0]]
        for segment in cuts:
            var a:float=segment[0]
            var b:float=segment[1]
            k.box(Vector3(x,-0.5,(a+b)*0.5),Vector3(1.7,6,b-a),"l49_mud")
        for i in 19:
            var z:float=-105+float(i)*12
            if (x>0 and absf(z-18)<12) or (x<0 and absf(z-90)<12):continue
            k.box(Vector3(x,-0.2,z),Vector3(2.6,0.75,2.0),"l49_bag")
    for i in 31:
        var z:float=-108+float(i)*7.0
        k.box(Vector3(0,-2.84,z),Vector3(13,0.10,0.27),"l49_wood",GeoKit.ALL,false)
    # Two L-shaped side dugouts; leave three-metre walkable routes from trench.
    for s in [-1.0,1.0]:
        var z:float=18 if s>0 else 90
        k.slab(5 if s>0 else -29,z-8,29 if s>0 else -5,z+8,-3.0,0.5,"l49_mud")
        k.box(Vector3(22*s,-0.5,z-8),Vector3(15,6,0.8),"l49_mud")
        k.box(Vector3(22*s,-0.5,z+8),Vector3(15,6,0.8),"l49_mud")
        k.box(Vector3(29*s,-0.5,z),Vector3(0.8,6,16),"l49_mud")
        for j in 5:
            k.box(Vector3(15*s,-2.25,z-5+float(j)*2.5),Vector3(2.3,1.4,0.6),"l49_bag")
        _bunkers+=1
    # Weathered pillars above the parapet are distant atmosphere, not paths.
    for i in 22:
        var x:float=17.0+float(i%2)*9.0
        var z:float=-95+float(int(i/2))*20.0
        k.box(Vector3(x,0.1,z),Vector3(0.20,1.2,0.22),"l49_steel",GeoKit.ALL,false)
    k.commit()
    add_note("trenches","STAY BELOW THE PARAPET","The air above the trench is unsafe. Bunker doors change between stretches of earth.",Vector3(-2,-2.1,-88))
    add_note("storm","WEATHER RECORD","Rain can flood underground passages; lightning is another kind of exit. Neither is reliable.",Vector3(2,-2.1,56))
func level_process(delta:float)->void:
    _weather_time+=delta
    if _weather_time>=135.0:
        _weather_time=0.0
        _storm=not _storm
        _flood=_storm
        if not SessionState.is_qa():Overlay.subtitle("[storm water begins to rise between the sandbags]" if _storm else "[the rain has stopped without warning]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"two rusted bunker access points","ok":_bunkers==2},{"what":"four sourced exits","ok":exits.size()==4},{"what":"storm and flood gates start closed","ok":not _storm and not _flood}]
