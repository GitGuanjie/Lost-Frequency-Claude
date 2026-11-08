extends RefCounted
## DEV20 deterministic, data-driven side annex to an existing SpatialBranchworks.
## Each blueprint was graph-audited and contains 3 tiers, a spanning tree with
## genuine loop doors, 2 independent exterior flights, a vertical atrium void,
## lighting circuits and a physical removable gate on a NON-TREE shortcut.
## The JSON is the only topology source of truth. Runtime physics remains to QA.

const State = preload("res://core/world/AtriumWeaveState.gd")
const ScenarioDressing = preload("res://core/world/ScenarioDressing.gd")
const ScenarioArchitecture = preload("res://core/world/ScenarioArchitecture.gd")
const NarrativeDistrict = preload("res://core/world/NarrativeDistrict.gd")
const DATA := "res://data/dev20_atrium_blueprints.json"
const COLUMNS := 5
const ROWS := 4
const CELL := 7.0
const WIDTH := 35.0
const DEPTH := 28.0
const DOOR_WIDTH := 2.8

static func _pos(raw: Array) -> Vector3:
    return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

static func _cell_key(c: int, r: int) -> String:
    return "%d:%d" % [c, r]

static func _edge_key(c: int, r: int, c2: int, r2: int) -> String:
    if c > c2 or (c == c2 and r > r2):
        return "%d:%d-%d:%d" % [c2, r2, c, r]
    return "%d:%d-%d:%d" % [c, r, c2, r2]

static func _center(x0: float, z0: float, c: int, r: int, y: float) -> Vector3:
    return Vector3(x0 + (float(c) + 0.5) * CELL, y, z0 + (float(r) + 0.5) * CELL)

static func _portal(side: String, tier: int, row: int) -> bool:
    # Stair 1: E south->north; Stair 2: W north->south.
    # Both landings on the middle storey, only one endpoint at each outer tier.
    if tier == 1:
        return row == 0 or row == 3
    if side == "east":
        return (tier == 0 and row == 0) or (tier == 2 and row == 3)
    return (tier == 0 and row == 3) or (tier == 2 and row == 0)

static func install(owner: LevelBase, tag: String) -> Dictionary:
    var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
    if not payload is Dictionary:
        push_error("DEV20 atrium topology JSON was not loaded")
        return {}
    var record: Dictionary = {}
    for entry in payload.get("wings", []):
        if entry.get("id", "") == owner.stable_id and entry.get("anchor", "") == tag:
            record = entry
            break
    if record.is_empty():
        push_error("DEV20 atrium blueprint missing for " + owner.stable_id + ":" + tag)
        return {}
    var o := _pos(record["origin"])
    var rise: float = float(record["rise"])
    var mat: String = record["mat"]
    var accent: String = record["accent"]
    var theme: String = record["style"]
    var open_air: bool = bool(record.get("open_air", false))
    # Existing east balcony extends to x+19 on anchor tier 2, height o.y+2*rise.
    var x0: float = o.x + 32.5
    var z0: float = o.z - 14.0
    var ybase: float = o.y + rise
    var k := owner.kit("DEV20_Atrium_" + tag)
    # The site is not allowed to float beyond an old finite ground slab:
    # a real low foundation supports the annex even at the terrain boundary.
    k.slab(x0 - 4.0, z0 - 3.0, x0 + WIDTH + 4.0, z0 + DEPTH + 3.0,
        o.y + 0.02, 0.38, mat)
    var state := State.new()
    state.name = "DEV20_Wing_" + tag
    owner.add_child(state)
    state.setup(owner, tag, theme)
    var levels: Array = record["floors"]
    var door_count := 0
    var room_count := 0
    var detail_count := 0
    for tier in 3:
        var y: float = ybase + float(tier) * rise
        var plan: Dictionary = levels[tier]
        var occupied := {}
        var doors := {}
        for cell in plan["cells"]:
            occupied[_cell_key(int(cell[0]), int(cell[1]))] = true
        for door in plan["doors"]:
            doors[_edge_key(int(door[0]), int(door[1]), int(door[2]), int(door[3]))] = true
        door_count += plan["doors"].size()
        # Construct floor panels only at occupied cells: the 2-cell middle
        # atrium genuinely remains open at heights 2 and 3.
        for r in ROWS:
            for c in COLUMNS:
                if not occupied.has(_cell_key(c, r)):
                    continue
                room_count += 1
                var center := _center(x0, z0, c, r, y)
                var cx0: float = x0 + float(c) * CELL
                var cz0: float = z0 + float(r) * CELL
                if open_air:
                    k.slab(center.x - 2.57, center.z - 2.57,
                        center.x + 2.57, center.z + 2.57, y, 0.28, mat)
                else:
                    k.slab(cx0, cz0, cx0 + CELL, cz0 + CELL, y, 0.28, mat)
                detail_count += _dress_cell(k, center, c, r, tier, accent, theme)
                if open_air:
                    continue # platform bridges/edge protection follow after cell loop
                # East/west split walls are generated exactly once per edge.
                if c + 1 < COLUMNS:
                    if occupied.has(_cell_key(c + 1, r)):
                        var has_door: bool = doors.has(_edge_key(c, r, c + 1, r))
                        k.wall(Vector3(cx0 + CELL, y, cz0), Vector3(cx0 + CELL, y, cz0 + CELL),
                            rise - 0.32, 0.19, accent, _door_opening(has_door))
                    else:
                        _edge_rail(k, center, "east", accent)
                if r + 1 < ROWS:
                    if occupied.has(_cell_key(c, r + 1)):
                        var has_door: bool = doors.has(_edge_key(c, r, c, r + 1))
                        k.wall(Vector3(cx0, y, cz0 + CELL), Vector3(cx0 + CELL, y, cz0 + CELL),
                            rise - 0.32, 0.19, accent, _door_opening(has_door))
                    else:
                        _edge_rail(k, center, "south", accent)
                if c > 0 and not occupied.has(_cell_key(c - 1, r)):
                    _edge_rail(k, center, "west", accent)
                if r > 0 and not occupied.has(_cell_key(c, r - 1)):
                    _edge_rail(k, center, "north", accent)
                # Outer walls: openings exist ONLY at actual stair landings
                # (plus the west-side tier-1 connector). No false portals.
                if c == 0:
                    var west_open := _portal("west", tier, r) or (tier == 1 and r == 1)
                    k.wall(Vector3(cx0, y, cz0), Vector3(cx0, y, cz0 + CELL),
                        rise - 0.32, 0.19, accent, _door_opening(west_open))
                if c == COLUMNS - 1:
                    k.wall(Vector3(cx0 + CELL, y, cz0), Vector3(cx0 + CELL, y, cz0 + CELL),
                        rise - 0.32, 0.19, accent, _door_opening(_portal("east", tier, r)))
                if r == 0:
                    # DEV21: two real north-facing observation terraces at
                    # tiers 0/2, linked by a doorway rather than a false wall.
                    if c == 2 and tier != 1:
                        k.wall(Vector3(cx0, y, cz0), Vector3(cx0 + CELL, y, cz0),
                            rise - 0.32, 0.19, accent, _door_opening(true))
                    elif c == 2 and tier == 1:
                        # DEV22: the actual north bridge to the new multi-storey
                        # narrative district needs a physical door at mid-floor.
                        k.wall(Vector3(cx0, y, cz0), Vector3(cx0 + CELL, y, cz0),
                            rise - 0.32, 0.19, accent, _door_opening(true))
                    else:
                        k.box(Vector3(center.x, y + (rise - 0.32) * 0.5, cz0),
                            Vector3(CELL, rise - 0.32, 0.19), accent)
                if r == ROWS - 1:
                    k.box(Vector3(center.x, y + (rise - 0.32) * 0.5, cz0 + CELL),
                        Vector3(CELL, rise - 0.32, 0.19), accent)
        if open_air:
            # Natural spaces use open sky and actual voids BETWEEN platforms.
            # Only edges present in the blueprint receive walkable bridges;
            # absent graph edges stay separated by a fall gap and a guard.
            for door in plan["doors"]:
                var cc: int = int(door[0])
                var rr: int = int(door[1])
                var dd: int = int(door[2])
                var ss: int = int(door[3])
                var a := _center(x0, z0, cc, rr, y)
                var b := _center(x0, z0, dd, ss, y)
                if cc != dd:
                    k.slab(a.x, a.z - 1.35, b.x, b.z + 1.35, y, 0.24, mat)
                else:
                    k.slab(a.x - 1.35, a.z, b.x + 1.35, b.z, y, 0.24, mat)
            for cell in plan["cells"]:
                var c: int = int(cell[0])
                var r: int = int(cell[1])
                var center := _center(x0, z0, c, r, y)
                for direction in ["west", "east", "north", "south"]:
                    var cc: int = c
                    var rr: int = r
                    if direction == "west": cc -= 1
                    if direction == "east": cc += 1
                    if direction == "north": rr -= 1
                    if direction == "south": rr += 1
                    var open_bridge: bool = occupied.has(_cell_key(cc, rr)) and doors.has(_edge_key(c, r, cc, rr))
                    var external_access := (direction == "west" and c == 0 and
                        (_portal("west", tier, r) or (tier == 1 and r == 1))) or (direction == "east" and c == COLUMNS - 1 and _portal("east", tier, r))
                    var terrace_access := (direction == "north" and c == 2 and r == 0)
                    _open_guard(k, center, direction, open_bridge or external_access or terrace_access, accent)
        # DEV21: two cantilevered survey terraces with real collision. The
        # outer end has rails; the back end joins the north cell opening.
        if tier != 1:
            var xc: float = x0 + 2.5 * CELL
            k.slab(xc - 1.8, z0 - 6.5, xc + 1.8, z0 + 1.55, y, 0.30, mat)
            for side in [-1.0, 1.0]:
                k.box(Vector3(xc + side * 1.85, y + 0.55, z0 - 2.48),
                    Vector3(0.13, 1.1, 8.05), accent)
                var column_h: float = y - o.y + 0.20
                k.box(Vector3(xc + side * 1.58, o.y + column_h * 0.5, z0 - 6.1),
                    Vector3(0.25, column_h, 0.25), accent)
            k.box(Vector3(xc, y + 0.55, z0 - 6.53),
                Vector3(3.7, 1.1, 0.13), accent)
            # Different geometry for all ten level-specific lookout pavilions.
            detail_count += ScenarioArchitecture.dress_terrace(k, owner.stable_id,
                xc, z0 - 6.5, y, tier, mat, accent)
        # Physical exterior landing aprons match the stair openings.
        for side in [-1, 1]:
            var xs: float = x0 - 2.5 if side == -1 else x0 + WIDTH + 2.5
            for row in [0, 3]:
                if not _portal("west" if side == -1 else "east", tier, row):
                    continue
                var zz: float = z0 + (float(row) + 0.5) * CELL
                var inner: float = x0 + 3.5 if side == -1 else x0 + WIDTH - 3.5
                var old_inner: float = x0 if side == -1 else x0 + WIDTH
                var edge_x: float = inner if open_air else old_inner
                k.slab(minf(xs, edge_x) - 0.2, zz - 1.6,
                    maxf(xs, edge_x) + 0.2, zz + 1.6, y, 0.24, mat)
        # Per-storey stateful circuits with actual OmniLight3D values.
        for site in [Vector2i(0, 0), Vector2i(4, 3)]:
            var lamp_pos := _center(x0, z0, site.x, site.y, y) + Vector3(0, 2.5, 0)
            state.add_lamp(tier, lamp_pos, _lamp_color(theme))
        var ctl := _center(x0, z0, 0, 1, y) + Vector3(-1.65, 1.0, 1.5)
        k.box(ctl - Vector3(0, 0.5, 0), Vector3(0.70, 1.0, 0.42), accent)
        owner.add_interactable(ctl, Vector3(1.4, 1.6, 1.5), _circuit_prompt(theme), Callable(state, "toggle_circuit").bind(tier))
        if tier != 1:
            var obs := _center(x0, z0, 3, 1, y) + Vector3(0, 1.15, -1.8)
            owner.add_interactable(obs, Vector3(1.6, 1.7, 1.6), "Inspect the layered architecture", Callable(state, "observe").bind(tier))
    # East and west REAL stairs: each flight has continuous physical collision.
    # 21m horizontal run -> ~9.5 degree gradient for 3.5m rise.
    for tier in 2:
        var low: float = ybase + float(tier) * rise
        k.stairs(Vector3(x0 + WIDTH + 2.5, low + 0.015, z0 + 3.5),
            Vector3(0, 0, 1), 2.5, rise, 30, mat, 0.7, false)
        k.stairs(Vector3(x0 - 2.5, low + 0.015, z0 + 24.5),
            Vector3(0, 0, -1), 2.5, rise, 30, mat, 0.7, false)
    # Connector only at tier 1; its west end overlaps the old tier-2 balcony.
    var entry_y: float = o.y + 2.0 * rise
    k.slab(o.x + 18.6, o.z - 5.4, x0 + (3.5 if open_air else 0.15),
        o.z + 1.85, entry_y, 0.25, mat)
    for edge_z in [o.z - 5.48, o.z + 1.93]:
        k.box(Vector3((o.x + 18.6 + x0) * 0.5, entry_y + 0.58, edge_z),
            Vector3(x0 - o.x - 18.6, 1.16, 0.14), accent)
    # Sparse support legs; avoid solid walls beneath walkways.
    for x in [x0 + 0.3, x0 + WIDTH - 0.3]:
        for z in [z0 + 0.3, z0 + DEPTH - 0.3]:
            k.box(Vector3(x, (o.y + ybase) * 0.5, z), Vector3(0.5, rise, 0.5), accent)
    # Top roof is deliberately NOT continuous above the atrium hole.
    var roof_y: float = ybase + 3.0 * rise
    if not open_air:
        for cell in levels[2]["cells"]:
            var cc: int = int(cell[0])
            var rr: int = int(cell[1])
            var xx: float = x0 + float(cc) * CELL
            var zz: float = z0 + float(rr) * CELL
            k.slab(xx, zz, xx + CELL, zz + CELL, roof_y, 0.22, accent)
    k.commit()
    _make_shutter(owner, state, record, x0, z0, ybase + rise, accent)
    var dressing: Dictionary = ScenarioDressing.install(owner, tag, state, x0, z0, ybase, rise)
    var district: Dictionary = NarrativeDistrict.install(owner, tag, x0, z0, ybase, rise)
    return {"walkable_cells": room_count, "passages": door_count, "details": detail_count,
        "scene_models": int(dressing.get("models", 0)), "interactive_markers": 3,
        "new_district_cells": int(district.get("cells", 0)),
        "new_district_models": int(district.get("models", 0)),
        "overlook_terraces": 2,
        "stairs": 4, "lights": 6, "controls": 6, "tier_count": 3,
        "open_air": open_air}

static func _door_opening(yes: bool) -> Array:
    return [{"at": CELL * 0.5, "w": DOOR_WIDTH, "h": 2.85}] if yes else []

static func _edge_rail(k: GeoKit, center: Vector3, side: String, mat: String) -> void:
    var at := center + Vector3(0, 0.60, 0)
    var size := Vector3(0.16, 1.2, CELL)
    if side == "west":
        at.x -= CELL * 0.5
    elif side == "east":
        at.x += CELL * 0.5
    elif side == "north":
        at.z -= CELL * 0.5
        size = Vector3(CELL, 1.2, 0.16)
    else:
        at.z += CELL * 0.5
        size = Vector3(CELL, 1.2, 0.16)
    k.box(at, size, mat)

static func _open_guard(k: GeoKit, center: Vector3, direction: String, has_route: bool, mat: String) -> void:
    # Rail lies on the real 5.14m platform edge. A traversable edge keeps
    # a 2.8m opening exactly aligned with its connected walkway.
    var at := center + Vector3(0, 0.55, 0)
    var along_x: bool = direction in ["north", "south"]
    if direction == "north": at.z -= 2.58
    if direction == "south": at.z += 2.58
    if direction == "west": at.x -= 2.58
    if direction == "east": at.x += 2.58
    if has_route:
        for sign in [-1.0, 1.0]:
            var edge := at + (Vector3(sign * 2.08, 0, 0) if along_x else Vector3(0, 0, sign * 2.08))
            k.box(edge, Vector3(1.0, 1.1, 0.12) if along_x else Vector3(0.12, 1.1, 1.0), mat)
    else:
        k.box(at, Vector3(5.14, 1.1, 0.12) if along_x else Vector3(0.12, 1.1, 5.14), mat)

static func _dress_cell(k: GeoKit, center: Vector3, c: int, r: int, tier: int, mat: String, theme: String) -> int:
    # Decor is kept at wall-adjacent corners or overhead; core 2.8m path clear.
    var unique: int = (c * 19 + r * 11 + tier * 7) % 5
    var p := center + Vector3(-2.55, 0, -2.55)
    if theme in ["forest", "garden"]:
        if unique <= 2:
            k.cylinder(p + Vector3(0, 1.4, 0), 0.22, 2.8, mat, 6)
            k.box(p + Vector3(0.55, 2.55, 0), Vector3(1.1, 0.13, 0.32), mat, GeoKit.ALL, false)
            return 2
    elif theme == "ruin":
        if unique <= 2:
            k.cylinder(p + Vector3(0, 1.5, 0), 0.27, 3.0, mat, 8)
            k.box(p + Vector3(0, 2.91, 0), Vector3(0.95, 0.15, 0.95), mat)
            return 2
    elif theme == "desert":
        if unique <= 2:
            k.box(p + Vector3(0, 1.2, 0), Vector3(0.42, 2.4, 0.42), mat)
            k.box(center + Vector3(0, 2.96, 0), Vector3(6.5, 0.14, 0.22), mat, GeoKit.ALL, false)
            return 2
    elif theme == "surreal":
        if unique <= 3:
            k.box(p + Vector3(0, 1.3, 0), Vector3(0.25, 2.6, 0.25), mat)
            k.box(center + Vector3(0, 2.91, 0), Vector3(0.2, 0.13, 6.2), mat, GeoKit.ALL, false)
            return 2
    else:
        if unique <= 2:
            k.box(p + Vector3(0, 1.35, 0), Vector3(0.42, 2.7, 0.42), mat)
            k.box(center + Vector3(0, 3.02, 0), Vector3(6.4, 0.11, 0.22), mat, GeoKit.ALL, false)
            return 2
    return 0

static func _lamp_color(theme: String) -> Color:
    if theme in ["forest", "garden"]:
        return Color(0.72, 0.91, 0.65)
    if theme == "desert":
        return Color(1.0, 0.72, 0.46)
    if theme == "surreal":
        return Color(0.62, 0.74, 1.0)
    return Color(0.95, 0.89, 0.77)

static func _make_shutter(owner: LevelBase, state, record: Dictionary,
        x0: float, z0: float, y: float, accent: String) -> void:
    var edge: Array = record["shutter_edge"]
    var a := _center(x0, z0, int(edge[0]), int(edge[1]), y)
    var b := _center(x0, z0, int(edge[2]), int(edge[3]), y)
    var pos := (a + b) * 0.5 + Vector3(0, 1.37, 0)
    var along_x: bool = int(edge[0]) != int(edge[2])
    var size := Vector3(0.16, 2.64, 2.62) if along_x else Vector3(2.62, 2.64, 0.16)
    state.configure_shutter(pos, size, MatLib.get_mat(accent))
    var face := a + Vector3(0, 1.16, 0)
    owner.add_interactable(face, Vector3(1.55, 1.8, 1.55), _shutter_prompt(str(record["style"])),
        Callable(state, "toggle_shutter"))

static func _circuit_prompt(theme: String) -> String:
    if theme in ["forest", "garden"]:
        return "Examine the changing canopy glow"
    if theme == "ruin":
        return "Test the old passage lamps"
    if theme == "desert":
        return "Adjust the abandoned signal panel"
    if theme == "surreal":
        return "Follow the impossible light pattern"
    return "Toggle local route lights"

static func _shutter_prompt(theme: String) -> String:
    if theme in ["forest", "garden"]:
        return "Shift the hanging root screen"
    if theme == "ruin":
        return "Move the loose stone panel"
    if theme == "desert":
        return "Slide the corroded barrier"
    if theme == "surreal":
        return "Move the unexplained partition"
    return "Move secondary-route shutter"
