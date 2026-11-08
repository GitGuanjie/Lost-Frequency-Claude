extends LevelBase
## Frozen Level 0 variant; strips of peeling wallpaper, frozen carpeting and unstable ducts.
var _ice_blocks := 0
var _cold_t := 8.0

func build() -> void:
    rules["view_distance"] = 140.0
    indoor_env(Color(0.58,0.74,0.91),0.36,Color(0.58,0.76,0.91),0.009)
    MatLib.define("l03_ice",{"albedo_a":Color(0.61,0.81,0.92),"albedo_b":Color(0.79,0.88,0.97),"roughness_a":0.11},"tile")
    MatLib.define("l03_wall",{"albedo_a":Color(0.65,0.68,0.57),"albedo_b":Color(0.79,0.84,0.84)},"plaster")
    MatLib.define("l03_carpet",{"albedo_a":Color(0.64,0.68,0.62),"albedo_b":Color(0.72,0.76,0.72)},"carpet")
    MatLib.define("l03_rust",{"albedo_a":Color(0.43,0.35,0.31),"albedo_b":Color(0.58,0.44,0.35),"metallic_value":0.55},"metal")
    MatLib.register("l03_frost",MatLib.panel(Color(0.67,0.94,1),0.22))
    lights.setup(12,1)
    _rooms()
    _ducts()
    add_arrival("start",Vector3(0,0.08,-51))
    add_landmark("Frozen carpet corridors",Vector3(0,0,-30))
    add_landmark("Oversized ice cubes",Vector3(16,0,36))
    add_landmark("Rusting old ventilation",Vector3(-17,3,68))
    add_shot("ice_fog",Vector3(0,1.62,-49),Vector3(0,2,25))
    add_shot("blowtorch_crew",Vector3(-18,1.62,38),Vector3(15,2,62))
    sound.bed("room_tone",{"seconds":6.0,"cutoff":190.0},-27.0)
    sound.bed("fluorescent_hum",{"seconds":4.0,"base":65.0},-35.0)

func _rooms() -> void:
    var k := kit("FrostedLiminalRooms")
    k.slab(-35,-60,35,115,0,0.38,"l03_carpet")
    for x in [-35.0,35.0]:
        k.box(Vector3(x,2.5,27.5),Vector3(0.45,5.0,175.0),"l03_wall")
    k.box(Vector3(0,5.1,27.5),Vector3(70,0.4,175),"l03_wall")
    for i in 14:
        var z := -54.0+float(i)*12.0
        # Room dividers leave different alternating open passages.
        if i % 2 == 0:
            k.box(Vector3(-19,2.4,z),Vector3(30,4.8,0.35),"l03_wall")
        else:
            k.box(Vector3(19,2.4,z),Vector3(30,4.8,0.35),"l03_wall")
        if i % 3 == 1:
            var x := -15.0 if i%2==0 else 15.0
            k.box(Vector3(x,1.2,z+3.5),Vector3(4.0,2.4,4.0),"l03_ice")
            _ice_blocks += 1
        k.box(Vector3(0,4.9,z+2),Vector3(2.8,0.09,1.4),"l03_frost",GeoKit.ALL,false)
        if i%2==0:
            lights.add_anchor(Vector3(0,4.6,z+2),Color(0.65,0.86,1.0),0.68,12,0.84,"l03_flicker")
    k.commit()
    add_note("crew", "SECTOR A891-01", "The carpet has been replaced again. The old ducts still pump ice fog. We cannot find the last crew.", Vector3(-24,0.83,-11))
    add_note("final", "UNSENT EMAIL", "The ice cubes were removed. Our blowtorches have stopped working. Where is everyone?",Vector3(15,0.85,87))

func _ducts() -> void:
    var k := kit("UnstableFrozenVentilation")
    for i in 20:
        var x := -28.0 if i%2==0 else 28.0
        var z := -50.0+float(i)*8.0
        k.box(Vector3(x,4.1,z),Vector3(1.1,0.55,6.0),"l03_rust",GeoKit.ALL,false)
        k.box(Vector3(x,3.85,z+1.5),Vector3(1.4,0.06,1.1),"l03_frost",GeoKit.ALL,false)
    k.commit()

func level_process(delta:float) -> void:
    _cold_t-=delta
    if _cold_t<=0.0 and not SessionState.is_qa():
        _cold_t=rng.randf_range(14.0,38.0)
        Overlay.subtitle("[cold air hisses from a vent; frost gathers on the carpet]",3.5)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"frost-block decor", "ok":_ice_blocks>=4}, {"what":"no fabricated exits", "ok":exits.is_empty()}, {"what":"frozen area landmarks", "ok":landmarks.size()==3}]
