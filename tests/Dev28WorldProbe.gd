extends Node
## DEV28 native acceptance. Run one level per fresh Godot process.
## Calls the same TransitionService.dev_jump as the F3 browser, then tests
## imported GLBs, actual Interactable callbacks and physical deck geometry.
const IDS := ["L015","L018","L026","L031","L049","L055","L079","L083","L090"]
const REPORT := "res://reports/qa/dev28_native/levels"
var sid := ""
var arrived := false
var error := ""
var checks: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _loaded(value: String) -> void:
    if value == sid: arrived = true

func _failed(value: String, reason: String) -> void:
    if value == sid: error = reason

func _check(ok: bool, what: String) -> void:
    checks.append({"check":what,"pass":ok})

func _floor(world: World3D, point: Vector3, tolerance := .37) -> bool:
    var q := PhysicsRayQueryParameters3D.create(point+Vector3.UP*2.0,point-Vector3.UP*.9)
    q.collision_mask = 1
    var hit := world.direct_space_state.intersect_ray(q)
    return not hit.is_empty() and absf(float(hit["position"].y)-point.y)<tolerance

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--level="):
            sid = arg.trim_prefix("--level=")
    if not sid in IDS:
        _finish("FAIL","unknown or missing --level")
        return
    get_tree().current_scene = null
    TransitionService.level_loaded.connect(_loaded)
    TransitionService.load_failed.connect(_failed)
    TransitionService.dev_jump(sid,"start")
    var deadline := Time.get_ticks_msec()+90000
    while Time.get_ticks_msec() < deadline and error=="" and not (arrived and not TransitionService.loading):
        await get_tree().process_frame
    if error!="" or not arrived or TransitionService.loading:
        _finish("FAIL","native F3 entry failure: "+error)
        return
    var level := get_tree().current_scene as LevelBase
    _check(level!=null,"scene is LevelBase")
    if level==null:
        _finish("FAIL","non-LevelBase root")
        return
    _check(level.built and level.stable_id==sid,"level build finished")
    _check(is_instance_valid(level.player),"player spawned")
    _check(bool(level.spawn_report.get("spawn_ok",false)),"safe spawn")
    var story := level.get_node_or_null("DEV28_InteractiveStoryRooms")
    _check(story!=null,"three-theme story director installed")
    if story==null:
        _finish("FAIL","missing story room director")
        return
    _check(int(story.actual_props)==9,"nine real imported GLB instances")
    var count := 0
    for child in story.get_children():
        if child is Interactable:
            (child as Interactable).interact(level.player)
            count+=1
    _check(count==3,"three actual E-key interactable callbacks")
    _check(story.inspected_count()==3,"three recorded observations")
    _check((story.lamps[1] as OmniLight3D).light_energy>1.0,"real switch light brightens")
    for tick in 5: await get_tree().physics_frame
    var world := level.get_world_3d()
    if sid=="L026":
        _check(_floor(world,Vector3(0,4.0,63.0)),"stern return bridge has floor collision")
        _check(_floor(world,Vector3(0,2.0,50.2)),"stern staircase has ramp collision")
        _check(_floor(world,Vector3(-7.0,4.0,63.0)),"port upper walk exists")
        _check(_floor(world,Vector3(7.0,4.0,63.0)),"starboard upper walk exists")
    if sid=="L031":
        _check(_floor(world,Vector3(44.5,0.0,0.0)),"rink/arcade 1m gap bridged")
        _check(_floor(world,Vector3(47.5,4.2,0.0)),"raised overlook floor exists")
        _check(_floor(world,Vector3(47.5,2.1,-36.5)),"first real stair ramp")
        _check(_floor(world,Vector3(47.5,2.1,36.5)),"second real stair ramp")
    if sid=="L083":
        _check(_floor(world,Vector3(-1.6,2.1,2.0)),"forward submarine stair collision")
        _check(_floor(world,Vector3(0,2.1,45.0)),"aft submarine stair collision")
        _check(_floor(world,Vector3(-1.6,4.2,7.0)),"forward upper landing")
        _check(_floor(world,Vector3(0,4.2,50.0)),"aft upper landing")
    if sid=="L079":
        var hands: Array = []
        for child in level.get_children():
            if child.name.begins_with("DEV28_ClockHand_"):
                hands.append(child)
        _check(hands.size()==16,"sixteen separate clock hands exist")
        var dial: Interactable = null
        for child in level.get_children():
            if child is Interactable and (child as Interactable).get_prompt()=="Observe the sixteen disagreeing clocks":
                dial=child
                break
        _check(dial!=null,"clock console interaction exists")
        if dial!=null:
            dial.interact(level.player)
            _check(int(level.get("_clock_phase"))==1,"clock console changes 16 dial poses")
    var fail := 0
    for item in checks:
        if not bool(item["pass"]):fail+=1
    _finish("PASS" if fail==0 else "FAIL","%d checks; %d failures"%[checks.size(),fail])

func _finish(status: String, note: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT))
    var f := FileAccess.open(ProjectSettings.globalize_path(REPORT+"/"+sid+".json"),FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"level":sid,"status":status,"note":note,
            "native_engine":true,"checks":checks},"  ")+"\n")
        f.close()
    print("DEV28_NATIVE "+sid+" "+status+" "+note)
    get_tree().quit(0 if status=="PASS" else 1)
