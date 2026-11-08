extends LevelBase
## The Roller Rink: looping timber rink with east arcade, food court, blue skate rental.
var _green_card := false
var _played := 0
var _coach_spoken := false

func build() -> void:
    rules["view_distance"] = 240.0
    indoor_env(Color(0.47, 0.39, 0.64), 0.31, Color(0.12, 0.10, 0.22), 0.0018)
    MatLib.define("l31_wood", {"albedo_a": Color(0.58, 0.34, 0.18), "albedo_b": Color(0.72, 0.51, 0.28)}, "wood_floor")
    MatLib.define("l31_carpet", {"albedo_a": Color(0.06, 0.06, 0.11), "albedo_b": Color(0.14, 0.14, 0.21)}, "carpet")
    MatLib.define("l31_blue", {"albedo_a": Color(0.16, 0.30, 0.64), "albedo_b": Color(0.23, 0.44, 0.84)}, "plaster")
    MatLib.register("l31_pink", MatLib.panel(Color(0.94, 0.22, 0.56), 1.5))
    MatLib.register("l31_cyan", MatLib.panel(Color(0.19, 0.78, 0.91), 1.3))
    lights.setup(14, 1)
    _rink()
    _arcade()
    _food_and_rental()
    _mezzanine28()
    add_arrival("start", Vector3(-2, 0.08, -40))
    add_arrival("from_L002", Vector3(-2, 0.08, -40))
    add_arrival("from_L003", Vector3(-2, 0.08, -40))
    add_arrival("from_L201", Vector3(-2, 0.08, -40))
    add_landmark("The endless timber skating loop", Vector3(0, 0, 0))
    add_landmark("Arcade with green-card dispenser", Vector3(63, 0, -12))
    add_landmark("The Coach at the blue-walled rentals", Vector3(-51, 0, 30))
    add_shot("wooden_rink", Vector3(-4, 1.62, -41), Vector3(0, 5.5, 0))
    add_shot("east_arcade", Vector3(45, 1.62, -12), Vector3(80, 2, 7))
    sound.bed("fluorescent_hum", {"seconds": 5.0, "base": 66.0}, -29.0)
    sound.bed("room_tone", {"seconds": 6.0, "cutoff": 410.0}, -33.0)

func _rink() -> void:
    var k := kit("EndlessRink")
    k.slab(-44, -54, 44, 54, 0.0, 0.34, "l31_wood")
    # Black carpet ring, lower ceiling in food court; centre remains clear to skate.
    for z in [-51.0, 51.0]:
        k.box(Vector3(0, 0.03, z), Vector3(92, 0.08, 8), "l31_carpet", GeoKit.ALL, false)
    for x in [-42.0, 42.0]:
        k.box(Vector3(x, 0.03, 0), Vector3(8, 0.08, 100), "l31_carpet", GeoKit.ALL, false)
    for i in 24:
        var a := TAU * float(i) / 24.0
        var x := cos(a) * 35.0
        var z := sin(a) * 43.0
        k.box(Vector3(x, 6.7, z), Vector3(2.4, 0.14, 1.0), "l31_pink" if i % 2 == 0 else "l31_cyan", GeoKit.ALL, false)
        if i % 3 == 0:
            lights.add_anchor(Vector3(x, 6.4, z), Color(0.88, 0.51, 0.96), 0.65, 13.0, 0.85, "l31_rink")
    # Star light above the rink centre and south DJ platform.
    for i in 8:
        var a := TAU * float(i) / 8.0
        k.box(Vector3(cos(a)*2.0, 7.2, sin(a)*2.0), Vector3(1.8, 0.2, 0.6), "l31_cyan", GeoKit.ALL, false)
    k.box(Vector3(0, 0.85, -54), Vector3(11, 1.7, 5), "l31_blue")
    k.commit()

func _arcade() -> void:
    var k := kit("ArcadeLoop")
    k.slab(45, -40, 98, 45, 0.0, 0.36, "l31_carpet")
    k.box(Vector3(72, 6.0, -40), Vector3(54, 0.28, 0.36), "l31_blue")
    k.box(Vector3(72, 6.0, 45), Vector3(54, 0.28, 0.36), "l31_blue")
    for i in 20:
        var x := 53.0 + float(i % 4) * 11.0
        var z := -31.0 + float(int(i / 4)) * 15.5
        k.box(Vector3(x, 1.05, z), Vector3(2.2, 2.1, 2.0), "l31_blue")
        k.box(Vector3(x, 1.72, z + 1.04), Vector3(1.8, 0.7, 0.06), "l31_pink" if i % 2 else "l31_cyan", GeoKit.ALL, false)
    k.commit()
    add_interactable(Vector3(48, 1.25, -33), Vector3(2.0, 1.8, 1.0), "Take a green arcade card", func(): _claim_card())
    add_interactable(Vector3(64, 1.5, -31), Vector3(2.0, 2.0, 1.6), "Play working arcade cabinet", func(): _play_arcade())
    add_exit("L031>L040#1", "interact", Vector3(65, 1.4, 36), Vector3(2.5, 2.5, 2.2), "No-clip into a working arcade game")
    add_exit("L031>L070#2", "interact", Vector3(95, 1.3, 26), Vector3(2.0, 2.4, 2.0), "White door engraved 70")
    add_note("diary", "A SKATER'S JOURNAL", "The games are free. The rink keeps looping. The Coach says I should leave before I forget why I came.", Vector3(52, 0.84, 3))

func _food_and_rental() -> void:
    var k := kit("FoodCourtCinemaCoach")
    k.slab(-88, -26, -45, 53, 0, 0.35, "l31_carpet")
    k.slab(-35, 55, 35, 96, 0, 0.35, "l31_carpet")
    for i in 10:
        var x := -80.0 + float(i % 2)*20.0
        var z := -20.0 + float(int(i/2))*11.5
        k.box(Vector3(x, 0.65, z), Vector3(4.0, 1.3, 2.2), "l31_wood")
    for z in [20.0, 34.0]:
        k.box(Vector3(-80, 1.5, z), Vector3(6, 3, 3), "l31_blue")
    for i in 12:
        var x := -25.0 + float(i % 6)*10.0
        k.box(Vector3(x, 0.25 + float(int(i/6))*0.4, 76), Vector3(5.0, 0.5, 2.0), "l31_wood")
    k.commit()
    add_exit("L031>L232#3", "interact", Vector3(-86, 1.3, -2), Vector3(2.1, 2.4, 1.8), "Employees only!")
    add_interactable(Vector3(-62, 1.1, 32), Vector3(2.0, 2.1, 2.0), "Ask the Coach for skating advice", func(): _coach())
    add_interactable(Vector3(-76, 1.1, -16), Vector3(2.0, 2.0, 2.0), "Ask for free food at the food court", func(): Overlay.subtitle("[the attendant offers a warm meal and a drink]", 4.0))
    add_note("coach", "RENTAL BOARD", "The Coach offers free lessons. Take a break and remember to leave when you are ready.", Vector3(-53, 0.85, 25))

## DEV28 arcade overlook with two physical ascents, clear upper walking zone
## x = 45.6 .. 49.4, detached from the cabinet rows at x >= 51.9.
func _mezzanine28() -> void:
    var k := kit("DEV28_ArcadeMezzanine")
    # Fix the one-metre join gaps between originally separated subscenes.
    for z in [-24.0,0.0,24.0]:
        k.slab(43.75,z-2.3,45.25,z+2.3,0.0,.36,"l31_carpet")
        k.slab(-45.25,z-2.3,-43.75,z+2.3,0.0,.36,"l31_carpet")
    k.slab(45.7,-29.5,49.3,29.5,4.2,.32,"l31_wood")
    k.stairs(Vector3(47.5,.05,-44.0),Vector3.BACK,2.3,4.2,18,"l31_wood",.84)
    k.stairs(Vector3(47.5,.05,44.0),Vector3.FORWARD,2.3,4.2,18,"l31_wood",.84)
    # Outer-only gallery rails: leave both stair mouths fully open.
    for x in [45.6,49.4]:
        k.box(Vector3(x,4.76,0),Vector3(.12,1.12,58.0),"l31_blue")
    # Raised but non-colliding cinema-style projections, no new exit.
    for z in [-20.0,0.0,20.0]:
        k.box(Vector3(47.5,6.3,z),Vector3(1.2,.18,2.5),"l31_pink",GeoKit.ALL,false)
    k.commit()
    add_landmark("Arcade overlook and dual staircase",Vector3(47.5,4.2,0))
    add_shot("dev28_arcade_overlook",Vector3(47.5,5.8,-15),Vector3(73,2,-15))

func _claim_card() -> void:
    _green_card = true
    Overlay.subtitle("[a bright green card slides out of the dispenser]", 3.0)

func _play_arcade() -> void:
    if not _green_card:
        Overlay.subtitle("[the cabinet requests a green card]", 3.0)
        return
    _played += 1
    Overlay.subtitle("[the screen glows; somewhere, skates scrape the wooden floor]", 3.5)

func _coach() -> void:
    _coach_spoken = true
    Overlay.subtitle("[the Coach gestures toward the exits and encourages you to keep moving]", 5.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"four-surface rink complex", "ok": exits.size() == 3}, {"what":"green-card gate starts closed", "ok": not _green_card}, {"what":"Coach interactive state initialized", "ok": not _coach_spoken}]
