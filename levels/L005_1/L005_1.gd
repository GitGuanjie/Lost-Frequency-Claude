extends LevelBase
var _chips:=0
var _plays:=0
func build()->void:
    indoor_env(Color(0.69,0.42,0.32),0.58,Color(0.27,0.13,0.17),0.018)
    MatLib.define("d6_rug",{"albedo_a":Color(0.34,0.08,0.22),"albedo_b":Color(0.44,0.11,0.30)},"carpet")
    MatLib.define("d6_slots",{"albedo_a":Color(0.27,0.24,0.33),"albedo_b":Color(0.38,0.37,0.45)},"metal")
    MatLib.define("d6_gold",{"albedo_a":Color(0.70,0.51,0.21),"albedo_b":Color(0.89,0.69,0.28)},"metal")
    lights.setup(10,0)
    var k:=kit("GrandCasino")
    k.slab(-46,-72,46,72,0,0.6,"d6_rug")
    k.box(Vector3(0,8.1,0),Vector3(94,0.4,146),"d6_slots")
    for x in [-46.0,46.0]:k.box(Vector3(x,4,0),Vector3(0.5,8,144),"d6_slots")
    for z in [-72.0,72.0]:k.box(Vector3(0,4,z),Vector3(92,8,0.5),"d6_slots")
    for i in 70:
        var x:float=-38+float(i%10)*8.5
        var z:float=-49+float(int(i/10))*12
        if absf(x)<7:continue
        k.box(Vector3(x,1.15,z),Vector3(1.2,2.3,1.5),"d6_slots")
        k.box(Vector3(x,2.1,z+0.8),Vector3(0.8,0.65,0.12),"d6_gold",GeoKit.ALL,false)
    for i in 7:
        k.cylinder(Vector3(-27+float(i)*9,0.75,53),3.0,1.5,"d6_gold",12)
    k.commit()
    add_arrival("start",Vector3(0,0.1,-65))
    add_arrival("from_L005",Vector3(0,0.1,-65))
    add_exit("L005_1>L005#1","interact",Vector3(0,1.3,-69),Vector3(6,3.0,3),"Return through the casino entrance")
    for i in 8:
        var station:int=i
        add_interactable(Vector3(-33+float(i%4)*18,1.3,-47+float(int(i/4))*24),Vector3(2.5,3,2.5),"Play a slot machine",func():_play(station))
    add_interactable(Vector3(0,1.2,60),Vector3(4,2,3),"Count casino chips",func():Overlay.subtitle("[chips: %d; trade rates need inventory integration]" % _chips,3.0))
    add_note("gambling","HOUSE RULES","The rumor that all machines are rigged is not proven. The permanent casino staff encounter is not implemented.",Vector3(7,1,-60))
    add_landmark("Slot-machine banks",Vector3(0,0,-8))
    add_landmark("Gaming tables and service counter",Vector3(0,0,55))
    add_shot("casino_slots",Vector3(0,1.6,-63),Vector3(-15,2,35))
    add_shot("card_tables",Vector3(22,1.6,42),Vector3(-18,1.4,55))
    sound.bed("room_tone",{"seconds":7.0},-29.0)
func _play(_station:int)->void:
    _plays+=1
    if rng.randi_range(0,3)==0:
        _chips+=1
        Overlay.subtitle("[a colored chip drops into your hand]",2.8)
    else:
        Overlay.subtitle("[the machine plays a short losing chime]",2.8)
func qa_self_test()->Array:
    await get_tree().process_frame
    return [{"what":"chip count starts zero","ok":_chips==0},{"what":"lobby exit exists","ok":exits.size()==1}]
