extends LevelBase
const SpatialBranchworks := preload("res://core/world/SpatialBranchworks.gd")
const AtriumWeave := preload("res://core/world/AtriumWeave.gd")
## Synthwave World: grid terrain, sky-stuck sunset, art hall, city, seaboard, data windows.
var _grid_lines:=0
var _phase:=0.0
var _night:=false

func build() -> void:
    rules["view_distance"]=1300.0
    outdoor_env(Color(0.24,0.13,0.43),Color(0.93,0.35,0.57),Color(0.12,0.07,0.27),Vector2(12,-40),Color(1,0.49,0.62),0.75,Color(0.39,0.20,0.53),0.0008)
    MatLib.define("l808_floor",{"albedo_a":Color(0.10,0.10,0.19),"albedo_b":Color(0.16,0.13,0.25)},"concrete")
    MatLib.define("l808_city",{"albedo_a":Color(0.13,0.13,0.30),"albedo_b":Color(0.19,0.12,0.33)},"concrete")
    MatLib.register("l808_magenta",MatLib.panel(Color(1,0.12,0.70),1.3))
    MatLib.register("l808_cyan",MatLib.panel(Color(0.16,0.88,1),1.2))
    MatLib.register("l808_darkgreen",MatLib.panel(Color(0.09,0.62,0.35),0.8))
    lights.setup(8,0)
    _grid()
    _formations()
    # DEV16: physically constructed independent stair loops; no added level exits.
    SpatialBranchworks.install(self, "NeonOuterCityOverpass", Vector3(48, 0, -66), 6, 3.5, "l808_city", "l808_magenta", false, 1, true)
    AtriumWeave.install(self, "NeonOuterCityOverpass")
    SpatialBranchworks.install(self, "NeonDistantReefOverpass", Vector3(153, 0, -66), 6, 3.5, "l808_city", "l808_cyan", false, -1)
    SpatialBranchworks.link_sites(self, "L808_DualPortal", Vector3(48, 0, -66), Vector3(153, 0, -66), 6, 3.5, "l808_city", "l808_magenta")
    add_arrival("start",Vector3(0,0.08,0))
    add_arrival("from_L011",Vector3(0,0.08,0))
    add_landmark("Retro-seaboard to the southeast",Vector3(110,0,110))
    add_landmark("Art Hall to the north",Vector3(0,0,-160))
    add_landmark("Infofield to the southwest",Vector3(-115,0,115))
    add_landmark("Sunset City transit to the west",Vector3(-130,0,-5))
    add_shot("neon_plain",Vector3(3,1.62,0),Vector3(-140,15,-5))
    add_shot("retroseaboard",Vector3(65,1.62,60),Vector3(130,0,136))
    sound.bed("pad",{"root":48,"bright":0.28},-30.0)

func _grid() -> void:
    var k:=kit("NeonGridPlain")
    k.slab(-250,-250,250,250,0,0.5,"l808_floor")
    for i in 61:
        var v:float=-240.0+float(i)*8.0
        k.box(Vector3(v,0.04,0),Vector3(0.08,0.08,480),"l808_magenta",GeoKit.ALL,false)
        k.box(Vector3(0,0.045,v),Vector3(480,0.08,0.08),"l808_cyan",GeoKit.ALL,false)
        _grid_lines+=2
    k.commit()

func _formations() -> void:
    var k:=kit("PolygonFormations")
    # Sunset City: deliberately stylized untextured low-poly buildings.
    for i in 55:
        var x:float=-190+float(i%5)*13
        var z:float=-92+float(int(i/5))*16
        var h:float=rng.randf_range(8,46)
        k.box(Vector3(x,h*0.5,z),Vector3(9,h,11),"l808_city")
        k.box(Vector3(x,h+0.10,z),Vector3(9,0.12,11),"l808_magenta" if i%2==0 else "l808_cyan",GeoKit.ALL,false)
    # Infofield: fake screen windows (no physical volume).
    for i in 16:
        var x:float=-145.0+float(i%4)*8.0
        var z:float=100.0+float(int(i/4))*9.0
        k.box(Vector3(x,3.0,z),Vector3(5,3,0.06),"l808_cyan",GeoKit.ALL,false)
    # Art Hall: colonnade, open floor, ceiling slab.
    k.slab(-24,-195,24,-145,0.15,0.3,"l808_city")
    for i in 10:
        var x:float=-21.0+float(i%5)*10.5
        var z:float=-190.0+float(int(i/5))*42.0
        k.cylinder(Vector3(x,4.8,z),0.9,9.6,"l808_city",8)
    k.box(Vector3(0,10,-169),Vector3(49,0.3,52),"l808_city")
    # Neon coconut-forms at the retro-seaboard.
    for i in 14:
        var x:float=90.0+float(i%7)*16.0
        var z:float=108.0+float(int(i/7))*18.0
        k.cylinder(Vector3(x,4,z),0.22,8,"l808_cyan",5,false)
        k.box(Vector3(x,8.3,z),Vector3(5.4,0.3,5.4),"l808_magenta",GeoKit.ALL,false)
    k.commit()
    add_exit("L808>L185#1","interact",Vector3(-190,1.2,-66),Vector3(3,2.5,2.5),"TRANSIT subway station to Level 185")
    add_note("posters","SUNSET CITY", "Neon reaches the skyline. The station is marked TRANSIT, but the city never sees a sunrise.",Vector3(-128,0.9,-15))
    add_note("infofield","INFOFIELD", "The code in these windows does not correspond to any known system. They are flat as light.",Vector3(-110,0.9,112))

func level_process(delta:float) -> void:
    _phase+=delta
    if _phase>120.0:
        _phase=0.0
        _night=not _night
        if not SessionState.is_qa():
            Overlay.subtitle("[the grid dims; the sun remains on the horizon]",4.0)
    if sun!=null:
        sun.light_energy=0.34 if _night else 0.75

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"122 batched grid lines", "ok":_grid_lines==122}, {"what":"the only sourced TRANSIT destination", "ok":exits.size()==1}, {"what":"four different named formations", "ok":landmarks.size()==4}]
