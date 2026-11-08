extends Node
## TRUE Godot 4.5.1 physics and F3-entry probe: one level in each fresh process.
## Runs only when Godot is available. No offline graph result is called PASS.
const SIDS := ["L016","L024","L029","L077","L140","L737","L899","L998"]
const REPORT := "res://reports/qa/dev27_native/levels"
var sid := ""
var arrived := false
var rejected := ""
var checks: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    call_deferred("_run")

func _loaded(next: String) -> void:
    if next == sid: arrived = true

func _failed(next: String, reason: String) -> void:
    if next == sid: rejected = reason

func _check(value: bool, name: String) -> void:
    checks.append({"test":name,"pass":value})

func _floor(world: World3D, x: float, y: float, z: float) -> bool:
    var query := PhysicsRayQueryParameters3D.create(Vector3(x,y+1.9,z),Vector3(x,y-.9,z))
    query.collision_mask = 1
    var hit := world.direct_space_state.intersect_ray(query)
    return not hit.is_empty() and absf(float(hit["position"].y)-y)<.32

func _run() -> void:
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--level="): sid=arg.trim_prefix("--level=")
    if not sid in SIDS:
        _finish("FAIL","--level missing or unsupported")
        return
    get_tree().current_scene = null
    TransitionService.level_loaded.connect(_loaded)
    TransitionService.load_failed.connect(_failed)
    TransitionService.dev_jump(sid,"start")
    var deadline := Time.get_ticks_msec() + 80000
    while Time.get_ticks_msec()<deadline and rejected=="" and not (arrived and not TransitionService.loading):
        await get_tree().process_frame
    if rejected!="" or not arrived or TransitionService.loading:
        _finish("FAIL","F3 entry failed: "+rejected)
        return
    var level := get_tree().current_scene as LevelBase
    _check(level!=null,"scene root is LevelBase")
    if level==null:
        _finish("FAIL","missing scene")
        return
    _check(level.built and level.stable_id==sid,"built via F3 path")
    _check(is_instance_valid(level.player),"player spawned")
    _check(bool(level.spawn_report.get("spawn_ok",false)),"safe spawn")
    var sector := level.get_node_or_null("DEV27_FieldSector")
    _check(sector!=null,"sector installed")
    if sector==null:
        _finish("FAIL","sector missing")
        return
    var info: Dictionary = sector.rec
    var anchor: Array = info["anchor"]
    var dims: Array = info["half"]
    var x := float(anchor[0])
    var z := float(anchor[1])
    var hx := float(dims[0])
    var hz := float(dims[1])
    for tick in 4:await get_tree().physics_frame
    var world := level.get_world_3d()
    for dx in [-hx,hx]:
        for dz in [-hz,hz]:
            _check(_floor(world,x+dx,3.6,z+dz),"physical raised plaza %.1f %.1f"%[dx,dz])
    for dx in [-hx,hx]:
        _check(_floor(world,x+dx,3.6,z),"continuous side passage at x %.1f"%dx)
    for dz in [-hz,hz]:
        _check(_floor(world,x,3.6,z+dz),"continuous cross passage at z %.1f"%dz)
    _check(_floor(world,x-hx,1.82,z-hz-12+4.32),"first stair has ramp collision")
    _check(_floor(world,x+hx,1.82,z+hz+12-4.32),"second stair has ramp collision")
    _check(not _floor(world,x,3.6,z),"optional crossing initially physically absent")
    var model_expected: int = (info["props"] as Array).size()
    _check(sector.model_count()==model_expected,"all %d GLB imports"%model_expected)
    for spur in info["spurs"]:
        var pos: Array = spur["pos"]
        _check(_floor(world,x+float(pos[0]),3.6,z+float(pos[2])),
            "physical branch terminal %s"%str(spur["id"]))
    var interacted := 0
    for child in sector.get_children():
        if child is Interactable and (child as Interactable).get_prompt()=="Investigate a local route marker":
            (child as Interactable).interact(level.player)
            interacted += 1
    for tick in 3: await get_tree().physics_frame
    _check(interacted==3,"three marker callbacks invoked by Interactable")
    _check(sector.survey_count()==3,"survey state persisted")
    _check(sector.bridge_open,"surveys deploy optional crossing")
    _check(_floor(world,x,3.6,z),"new crossing has physical collision")
    sector.toggle_bridge(level.player)
    for tick in 3: await get_tree().physics_frame
    _check(not sector.bridge_open,"optional crossing retracts")
    _check(not _floor(world,x,3.6,z),"retracted crossing removes physical collision")
    var nfail := 0
    for check in checks:
        if not bool(check["pass"]):nfail+=1
    _finish("PASS" if nfail==0 else "FAIL","%d checks, %d failed"%[checks.size(),nfail])

func _finish(status: String, note: String) -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT))
    var file := FileAccess.open(ProjectSettings.globalize_path(REPORT+"/"+sid+".json"),FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"level":sid,"status":status,"note":note,
            "native_engine":true,"checks":checks},"  ")+"\n")
        file.close()
    print("DEV27_NATIVE "+sid+" "+status+" "+note)
    get_tree().quit(0 if status=="PASS" else 1)
