extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
const ModelDress := preload("res://core/world/ModelDress.gd")
## Source-led waiting halls and Electric arcade; never general-purpose amusement park.
var _score := 0
var _lamps: Array = []
var _game_exit: ExitTrigger
var _seconds := 0.0

func build() -> void:
    rules["view_distance"] = 160.0
    indoor_env(Color(0.68, 0.66, 0.60), 0.38, Color(0.40, 0.34, 0.29), 0.001)
    MatLib.define("l20_wall", {"albedo_a": Color(0.79, 0.78, 0.74), "albedo_b": Color(0.66, 0.65, 0.62)}, "plaster")
    MatLib.define("l20_carpet", {"albedo_a": Color(0.36, 0.25, 0.18), "albedo_b": Color(0.42, 0.32, 0.24), "roughness_a": 0.96}, "carpet")
    MatLib.define("l20_game", {"albedo_a": Color(0.08, 0.12, 0.21), "albedo_b": Color(0.17, 0.16, 0.29), "metallic_value": 0.42}, "metal")
    MatLib.register("l20_blue", MatLib.panel(Color(0.19, 0.63, 0.92), 1.8))
    MatLib.register("l20_orange", MatLib.panel(Color(1.0, 0.42, 0.17), 2.0))
    lights.setup(12, 1)
    _rooms()
    _games()
    VerticalArchitecture.install(self, "ElectricServiceLoop", Vector3(0, 0, 59.5), 4, 3.45, "l20_game", "l20_wall", true)
    add_landmark("Electric's overhead switchback galleries", Vector3(0, 10.35, 59.5))
    add_arrival("start", Vector3(0, 0.08, -47))
    add_arrival("from_L011", Vector3(0, 0.08, -47))
    add_arrival("from_L019", Vector3(0, 0.08, -47))
    add_exit("L020>L002#1", "interact", Vector3(-18, 1.2, -8), Vector3(2.3, 2.4, 1.0), "Staff only — Level 2")
    add_exit("L020>L024#2", "noclip", Vector3(19, 1.2, 70), Vector3(2.3, 2.5, 0.6), "Unstable window")
    _game_exit = add_exit("L020>L004#3", "interact", Vector3(12, 1.2, 106), Vector3(2.4, 2.4, 0.7), "EXIT over the game room")
    _game_exit.condition = func(): return _count_bits() >= 3
    add_landmark("Waiting halls with fountains", Vector3(0, 0.2, -22))
    add_landmark("The Electric, bright gaming section", Vector3(0, 0.2, 63))
    add_shot("waiting_halls", Vector3(3, 1.62, -44), Vector3(0, 1.8, 10))
    add_shot("electric", Vector3(0, 1.62, 48), Vector3(11, 1.6, 96))
    sound.bed("room_tone", {"seconds": 5.0, "cutoff": 310.0}, -25.0)
    sound.bed("fluorescent_hum", {"seconds": 4.0, "base": 71.0}, -31.0)
    sound.oneshot("wind", {"seconds": 4.0}, 32.0, 59.0, 15.0, "[wind seems to blow from an empty corridor]", -31.0)

    ModelDress.decorate(self, "L020")

func _rooms() -> void:
    var k := kit("WaitingHalls")
    k.slab(-23, -58, 23, 36, 0, 0.34, "l20_carpet")
    k.box(Vector3(0, 5.1, -11), Vector3(46, 0.4, 94), "l20_wall")
    for x in [-23.0, 23.0]:
        k.box(Vector3(x, 2.6, -11), Vector3(0.45, 5.2, 94), "l20_wall")
    for i in 9:
        var z := -50.0 + float(i) * 9.3
        for x in [-17.0, 17.0]:
            k.box(Vector3(x, 0.55, z), Vector3(2.5, 1.1, 0.75), "l20_game")
            k.box(Vector3(x, 2.0, z), Vector3(0.20, 2.8, 0.2), "l20_wall")
        k.box(Vector3(0, 5.02, z), Vector3(3.0, 0.07, 1.1), "l20_blue", GeoKit.ALL, false)
        if i % 2 == 0:
            lights.add_anchor(Vector3(0, 4.6, z), Color(0.93, 0.91, 0.79), 0.7, 12.0, 0.82, "l20_cold")
        if i % 3 == 0:
            k.box(Vector3(11, 0.55, z + 2.0), Vector3(3.2, 1.1, 2.3), "l20_game")
    k.commit()

func _games() -> void:
    var k := kit("ElectricHall")
    k.slab(-24, 36, 24, 122, 0, 0.35, "l20_game")
    # Cut a full-height shaft in the Electric roof; preserve the remainder.
    k.slab(-24,36,-8.8,122,6.25,0.5,"l20_wall")
    k.slab(8.8,36,24,122,6.25,0.5,"l20_wall")
    k.slab(-8.8,36,8.8,44.0,6.25,0.5,"l20_wall")
    k.slab(-8.8,75.0,8.8,122,6.25,0.5,"l20_wall")
    for x in [-24.0, 24.0]:
        k.box(Vector3(x, 3.1, 79), Vector3(0.5, 6.2, 86), "l20_wall")
    for i in 24:
        var side := -1.0 if i % 2 == 0 else 1.0
        var z := 40.0 + float(int(i / 2)) * 6.3
        var x := side * 15.0
        k.box(Vector3(x, 1.0, z), Vector3(2.5, 2.0, 1.5), "l20_game")
        k.box(Vector3(x, 1.65, z + 0.8), Vector3(1.65, 0.8, 0.06), "l20_blue" if i % 3 != 0 else "l20_orange", GeoKit.ALL, false)
    for j in 3:
        var p := Vector3(-5.0 + float(j) * 5.5, 1.05, 82)
        k.box(p, Vector3(1.8, 2.1, 1.7), "l20_game")
        _lamps.append(p)
    k.commit()
    for j in 3:
        var index := j
        add_interactable(_lamps[j] + Vector3(0, 0.5, 0.9), Vector3(1.2, 1.7, 0.7), "Play console %d" % (j+1), func(): _play(index))
    add_note("machine_rules", "THE ELECTRIC", "Three working consoles accept a single input each. They should not be powered, but they are.", Vector3(0, 0.95, 38))

func _play(index: int) -> void:
    if (_score & (1 << index)) != 0:
        Overlay.subtitle("[the console does not respond again]", 2.0)
        return
    _score |= 1 << index
    Overlay.subtitle("[a machine clicks — %d / 3 consoles]" % _count_bits(), 3.0)

func _count_bits() -> int:
    var n := 0
    for i in 3:
        if (_score & (1 << i)) != 0:
            n += 1
    return n

func level_process(delta: float) -> void:
    _seconds += delta
    if _seconds > 20.0 and player and player.global_position.z > 40 and not SessionState.is_qa():
        _seconds = 0.0
        Overlay.subtitle("[the air vibrates with arcade noise from a dark room]", 3.0)

func qa_self_test() -> Array:
    await get_tree().process_frame
    return [{"what":"three playable consoles", "ok":_lamps.size() == 3}, {"what":"canonical staff door present", "ok": exits.size() >= 3}, {"what":"game gate locked before console inputs", "ok": _score == 0 and not _game_exit.condition.call()}]
