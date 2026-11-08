extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
## Plastic lunar surface, normal gravity; industrial mining gate is the only documented exit.
var _alarms:=0
var _storm_clock:=0.0
func build()->void:
    rules["view_distance"]=600.0
    outdoor_env(Color(0.045,0.05,0.08),Color(0.17,0.17,0.20),Color(0.08,0.08,0.09),Vector2(19,48),Color(0.82,0.83,0.80),0.7,Color(0.30,0.30,0.34),0.002)
    MatLib.define("l24_paint",{"albedo_a":Color(0.70,0.72,0.72),"albedo_b":Color(0.61,0.63,0.65)},"concrete")
    MatLib.define("l24_plastic",{"albedo_a":Color(0.39,0.64,0.79),"albedo_b":Color(0.26,0.49,0.62)},"concrete")
    MatLib.define("l24_steel",{"albedo_a":Color(0.20,0.23,0.28),"albedo_b":Color(0.32,0.37,0.41)},"metal")
    MatLib.register("l24_alarm",MatLib.panel(Color(0.95,0.50,0.20),1.8))
    lights.setup(6,0)
    var k:=kit("PlasticMoonMine")
    k.slab(-95,-110,95,115,0,0.5,"l24_paint")
    for i in 22:
        var x:float=rng.randf_range(-88,88)
        var z:float=rng.randf_range(-95,95)
        if absf(x)<12:continue
        if x>-48 and x<-26 and z>-33 and z<3:continue
        var h:float=rng.randf_range(0.4,2.4)
        k.box(Vector3(x,h*0.5,z),Vector3(h*3,h,h*2),"l24_plastic",GeoKit.ALL,false)
    for i in 7:
        var x:float=-28+float(i)*9
        k.box(Vector3(x,2.0,52),Vector3(1.0,4,1.0),"l24_steel")
    for z in [45.0,68.0]:
        k.box(Vector3(0,0.09,z),Vector3(33,0.15,2.0),"l24_steel",GeoKit.ALL,false)
    for x in [-15.0,15.0]:k.box(Vector3(x,3,98),Vector3(1.3,6,1.3),"l24_steel")
    k.box(Vector3(0,6,98),Vector3(32,1.0,1.5),"l24_steel")
    for i in 9:
        var x:float=-57.0+float(i%3)*9.0
        var z:float=52+float(int(i/3))*8
        k.box(Vector3(x,1.0,z),Vector3(7.0,2.0,5.0),"l24_plastic")
    k.commit()
    VerticalArchitecture.install(self, "PlasticMineElevatedProcess", Vector3(-37, 0, -15), 5, 3.4, "l24_steel", "l24_plastic")
    add_landmark("Five-tier plastic processing tower", Vector3(-37, 13.6, -15))
    add_arrival("start",Vector3(0,0.08,-94))
    add_arrival("from_L001",Vector3(0,0.08,-94))
    add_arrival("from_L020",Vector3(0,0.08,-94))
    add_arrival("from_L025",Vector3(0,0.08,-94))
    add_exit("L024>EXT#1","interact",Vector3(0,1.5,98),Vector3(5,3,3),"PlasticWorks main gate — release boundary")
    add_landmark("Abandoned Bluehole workings",Vector3(-45,0,63))
    add_landmark("PlasticWorks processing gate",Vector3(0,0,98))
    add_shot("grey_moon",Vector3(0,1.6,-92),Vector3(-30,4,54))
    add_shot("plastic_works",Vector3(0,1.6,45),Vector3(0,3,99))
    add_note("survey","PLASTICWORKS SAFETY","This is painted plastic, not lunar rock. Gravity is normal. The lemon-smelling mist is hazardous.",Vector3(6,1,-76))
    sound.bed("wind",{"seconds":8.0},-35.0)
func level_process(delta:float)->void:
    _storm_clock+=delta
    if _storm_clock>=105.0:
        _storm_clock=0.0
        _alarms+=1
        if not SessionState.is_qa():Overlay.subtitle("[industrial sirens; something enormous approaches the model]",4.0)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"one PlasticWorks gate","ok":exits.size()==1},{"what":"normal gravity despite moon","ok":rules["gravity"]==9.8},{"what":"source-linked arrivals","ok":arrivals.has("from_L020") and arrivals.has("from_L025")}]
