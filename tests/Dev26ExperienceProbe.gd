extends Node
## Real Godot QA. Enters through TransitionService.dev_jump (the F3 route),
## then checks imported GLBs, physical floors and Interactable.interact(Player).
const REPORT_DIR := "res://reports/qa/dev26_native/levels"
const WAIT_MS := 90000
const TARGETS := ["L052","L053","L058","L060","L079","L083","L090","L096","L101","L114","L160","L197","L071"]
var sid := ""
var loaded := false
var failed := ""
var checks: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_probe")

func _loaded(next: String) -> void:
    if next == sid: loaded = true

func _failed(next: String, why: String) -> void:
    if next == sid: failed = why

func _check(ok: bool, label: String) -> void:
    checks.append({"name":label,"ok":ok})

func _ray_floor(world: World3D, at: Vector3, expected_y: float) -> bool:
    var origin := Vector3(at.x, expected_y + 2.1, at.z)
    var target := Vector3(at.x, expected_y - 1.5, at.z)
    var query := PhysicsRayQueryParameters3D.create(origin,target)
    query.collision_mask = 1
    var hit := world.direct_space_state.intersect_ray(query)
    return not hit.is_empty() and absf(float(hit["position"].y) - expected_y) < 0.45

func _probe() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--level="): sid = arg.trim_prefix("--level=")
    if not sid in TARGETS:
        _finish("FAIL","unsupported or missing --level")
        return
    get_tree().current_scene = null
    TransitionService.level_loaded.connect(_loaded)
    TransitionService.load_failed.connect(_failed)
    TransitionService.dev_jump(sid,"start")
    var deadline := Time.get_ticks_msec() + WAIT_MS
    while Time.get_ticks_msec() < deadline and failed == "" and not (loaded and not TransitionService.loading):
        await get_tree().process_frame
    if failed != "" or not loaded or TransitionService.loading:
        _finish("FAIL","F3 transition failed or timed out: " + failed)
        return
    var level := get_tree().current_scene as LevelBase
    _check(level != null,"scene root is LevelBase")
    if level == null:
        _finish("FAIL","missing level root")
        return
    _check(level.built and level.stable_id == sid,"native level built via F3")
    _check(is_instance_valid(level.player),"player spawned")
    _check(bool(level.spawn_report.get("spawn_ok",false)),"safe spawn")
    for tick in 4:
        await get_tree().physics_frame
    var state := level.get_node_or_null("DEV26_CuratedAtmospheres")
    _check(state != null,"curated scene exists")
    if state != null:
        var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
            "res://data/dev26_curated_vignettes.json"))
        var expected := 0
        for site in raw.get("sites",[]):
            if str(site["id"]) == sid:
                expected = site["cues"].size()
                break
        var cues := 0
        var imported := 0
        for child in state.get_children():
            if child is Interactable: cues += 1
            if str(child.name).begins_with("GLB_"): imported += 1
        _check(cues == expected,"all %d interactive cues created"%expected)
        _check(imported == expected*2,"all %d GLBs imported"%(expected*2))
        var active_lamps: Array = state.lamps
        _check(active_lamps.size() == expected,"one signal lamp per cue")
        for child in state.get_children():
            if child is Interactable:
                # Full action dispatch: Interactable -> Callable(Player,index) -> light/log.
                (child as Interactable).interact(level.player)
                break
        _check(state.inspection_count() == 1,"E dispatch records one observation")
        _check(not active_lamps.is_empty() and active_lamps[0].light_energy >= .7,
            "E dispatch changes real OmniLight3D intensity")
    if sid == "L197":
        for record in [
            [-12.8,-46.0,-23.0,4.2], [12.8,13.0,36.0,4.7],
            [-12.8,62.0,85.0,5.1], [12.8,109.0,132.0,4.5]]:
            var x := float(record[0])
            var z0 := float(record[1])
            var z1 := float(record[2])
            var top := float(record[3])
            _check(_ray_floor(level.get_world_3d(),Vector3(x,top,(z0+z1)*.5),top),
                "physical upper gallery at z=%0.1f"%z0)
            _check(_ray_floor(level.get_world_3d(),Vector3(x,top*.5,z0-5),top*.5),
                "physical first ramp at z=%0.1f"%z0)
            _check(_ray_floor(level.get_world_3d(),Vector3(x,top*.5,z1+5),top*.5),
                "physical return ramp at z=%0.1f"%z1)
    var count := 0
    for check in checks:
        if not check["ok"]: count+=1
    _finish("PASS" if count==0 else "FAIL","%d checks, %d failed"%[checks.size(),count])

func _finish(status: String, why: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
    var file := FileAccess.open(ProjectSettings.globalize_path(REPORT_DIR+"/"+sid+".json"),FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"sid":sid,"status":status,"reason":why,
            "native":true,"checks":checks},"  ")+"\n")
        file.close()
    print("DEV26_NATIVE "+sid+" "+status+" "+why)
    get_tree().quit(0 if status=="PASS" else 1)
