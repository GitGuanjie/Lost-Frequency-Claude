extends LevelBase
var _heat:=0.0
var _shade:=0
func build()->void:
    rules["view_distance"]=600.0
    outdoor_env(Color(0.83,0.65,0.28),Color(0.96,0.78,0.30),Color(0.71,0.51,0.22),Vector2(10,-25),Color(1.0,0.94,0.47),1.4,Color(0.72,0.54,0.22),0.009)
    MatLib.define("d7_dune",{"albedo_a":Color(0.80,0.62,0.26),"albedo_b":Color(0.94,0.79,0.40)},"sand")
    MatLib.define("d7_ruin",{"albedo_a":Color(0.47,0.40,0.27),"albedo_b":Color(0.65,0.53,0.34)},"rock")
    var k:=kit("SevenHundredThirtySeven")
    k.slab(-210,-210,210,210,0,0.6,"d7_dune")
    for i in 14:
        var sz:float=65.0-float(i)*4.0
        k.box(Vector3(80,1+float(i)*2.6,78),Vector3(sz,2.6,sz),"d7_ruin")
    for i in 55:
        var x:float=rng.randf_range(-190,190)
        var z:float=rng.randf_range(-190,190)
        if absf(x)<9 or absf(z)<9:continue
        # DEV27: old ruin blocks must not occupy the new two stair ascents.
        if x>-135 and x<-51 and z>-62 and z<28:continue
        var h:float=rng.randf_range(0.5,5)
        k.box(Vector3(x,h*0.5,z),Vector3(rng.randf_range(2,5),h,4),"d7_ruin")
    for i in 16:
        k.box(Vector3(-30+float(i)*4,0.14,-160+float(i)*10),Vector3(1.2,0.25,2.5),"d7_ruin",GeoKit.ALL,false)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-166))
    add_exit("L737>L998#4","interact",Vector3(0,1.1,161),Vector3(6,2.2,5),"Take the recorded path toward L998")
    add_note("heat","EXTRACTION REPORT","The account describes a temperature far beyond human survival. The gameplay model uses a warning and prototype accumulation, not a faithful thermodynamic simulation.",Vector3(3,0.8,-156))
    for i in 4:
        var n:int=i
        add_interactable(Vector3(7,1,-128+float(i)*73),Vector3(4,2,4),"Record the desert heat",func():_sample(n))
    add_landmark("Distant pyramid",Vector3(80,0,78))
    add_landmark("L998 extraction trace",Vector3(0,0,161))
    add_shot("shifting_dunes",Vector3(0,1.6,-162),Vector3(80,39,78))
    add_shot("ruin_path",Vector3(9,1.6,42),Vector3(0,1,165))
    sound.bed("wind",{"seconds":9.0},-28.0)
func level_process(delta:float)->void:
    _heat+=delta
    if _heat>38.0 and _shade==0:
        _shade=1
        Overlay.subtitle("[unbearable simulated heat: seek an exit]",4.0)
func _sample(n:int)->void:
    Overlay.subtitle("[Midas log %d: the sand is not cooling]"%(n+1),3.2)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"documented L998 link only","ok":exits.size()==1},{"what":"heat starts below warning","ok":_heat<38.0}]
