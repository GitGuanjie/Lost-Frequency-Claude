extends Node
## Native DEV25 acceptance: enter through the same developer jump as F3, then
## raycast the actual collision bodies. Run each level in a fresh Godot process.
## Offline static tests CANNOT substitute for this probe.
const DATA := "res://data/dev25_immersive_networks.json"
const ISLES := "res://data/dev25_coconut_island_variants.json"
const REPORT_DIR := "res://reports/qa/dev25_physical/levels"
const WAIT_MS := 90000
var sid := ""
var loaded := false
var error := ""
var findings: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_probe")

func _loaded(next_id: String) -> void:
    if next_id == sid: loaded = true

func _failed(next_id: String, reason: String) -> void:
    if next_id == sid: error = reason

func _check(ok: bool, label: String) -> void:
    findings.append({"check":label,"pass":ok})

func _floor_at(pos: Vector3, expected_top: float, world: World3D) -> bool:
    var from := Vector3(pos.x, expected_top + 1.5, pos.z)
    var to := Vector3(pos.x, expected_top - 2.0, pos.z)
    var query := PhysicsRayQueryParameters3D.create(from,to)
    query.collision_mask = 1
    var hit := world.direct_space_state.intersect_ray(query)
    return not hit.is_empty() and absf(float(hit["position"].y) - expected_top) < .42

func _probe() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--level="): sid = arg.trim_prefix("--level=")
    if not sid in ["L041","L048","L100","L140","L149","L201"]:
        _exit("FAIL","unsupported or missing --level")
        return
    get_tree().current_scene = null
    TransitionService.level_loaded.connect(_loaded)
    TransitionService.load_failed.connect(_failed)
    TransitionService.dev_jump(sid,"start")
    var deadline := Time.get_ticks_msec() + WAIT_MS
    while Time.get_ticks_msec() < deadline and error == "" and not (loaded and not TransitionService.loading):
        await get_tree().process_frame
    if error != "" or not loaded or TransitionService.loading:
        _exit("FAIL","load failed or timed out: " + error)
        return
    var level := get_tree().current_scene as LevelBase
    _check(level != null and level.built and level.stable_id == sid,"native F3 level load")
    if level == null:
        _exit("FAIL","current scene not LevelBase")
        return
    _check(is_instance_valid(level.player),"player instantiated")
    _check(bool(level.spawn_report.get("spawn_ok",false)),"safe start spawn")
    for tick in 3:
        await get_tree().physics_frame
    if sid in ["L041","L048","L140","L201"]:
        var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
        for site in raw.get("sites",[]):
            if str(site["id"]) != sid: continue
            var state: Node = level.get_node_or_null("DEV25_ObservationState_"+sid)
            _check(state != null,"immersive interactive state exists")
            _check(level.get_node_or_null("DEV25_ExistingGLB_"+sid) != null,"GLB prop root created")
            var nodes: Dictionary = site["nodes"]
            var misses := 0
            for key in nodes:
                var xyz: Array = nodes[key]
                if not _floor_at(Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2])),float(xyz[1]),level.get_world_3d()):
                    misses += 1
            _check(misses == 0,"all %d planned platforms physically raycast (%d missing)"%[nodes.size(),misses])
            if state != null:
                var panel_count := 0
                for child in state.get_children():
                    if str(child.name).begins_with("DEV25_SignalPanel_"): panel_count += 1
                _check(panel_count == 3,"three clickable survey panels")
                var bridges := state.get_node_or_null("DEV25_Optional_Physical_Deck")
                _check(bridges != null,"optional bridge has a collision body")
                if bridges != null:
                    var shape := bridges.get_node_or_null("CollisionShape3D") as CollisionShape3D
                    # This can be a child whose name includes an automatic suffix;
                    # use type search if the default name was changed by Godot.
                    if shape == null:
                        for child in bridges.get_children():
                            if child is CollisionShape3D:
                                shape = child
                                break
                    _check(shape != null and shape.disabled,"bridge initially closed")
                # Exercise the actual Interactable.interact() chain behind E:
                # body -> Callable with Player + bound index -> physics state.
                for index in range(3):
                    var point := level.get_node_or_null("DEV25_Survey_%d"%index) as Interactable
                    _check(point != null,"E-interactable survey %d exists"%index)
                    if point != null:
                        point.interact(level.player)
                var light_point := level.get_node_or_null("DEV25_GuideSwitch_0") as Interactable
                _check(light_point != null,"E-interactable light switch exists")
                if light_point != null:
                    light_point.interact(level.player)
                    _check(state.guide_lights[0].light_energy > .5,"E press changes real OmniLight3D energy")
                for tick in 2:
                    await get_tree().physics_frame
                _check(state.bridge_active,"three observations activate crossing")
                var lever := level.get_node_or_null("DEV25_OptionalLever") as Interactable
                _check(lever != null,"E-interactable bridge lever exists")
                if lever != null:
                    lever.interact(level.player)
                for tick in 2:
                    await get_tree().physics_frame
                _check(not state.bridge_active,"crossing can be closed again")
    elif sid == "L149":
        var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ISLES))
        _check(level.get_node_or_null("DEV25_WindObservation") != null,"island observation node")
        var misses := 0
        for rec in raw.get("islands",[]):
            var xyz: Array = rec["pos"]
            var pt := Vector3(float(xyz[0]),float(xyz[1]),float(xyz[2]))
            if not _floor_at(pt,pt.y,level.get_world_3d()): misses += 1
        _check(misses == 0,"all 13 natural islands carry floor collision (%d missing)"%misses)
    else:
        _check(level.exits.size() == 1,"sandbar original lone exit unchanged")
    var failures := 0
    for item in findings:
        if not item["pass"]: failures += 1
    _exit("PASS" if failures == 0 else "FAIL",("%d checks; %d failures"%[findings.size(),failures]))

func _exit(status: String,reason: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
    var f := FileAccess.open(ProjectSettings.globalize_path(REPORT_DIR+"/"+sid+".json"),FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify({"level":sid,"status":status,"reason":reason,"native":true,"checks":findings},"  ")+"\n")
        f.close()
    print("DEV25_PHYSICAL "+sid+" "+status+" "+reason)
    get_tree().quit(0 if status == "PASS" else 1)
