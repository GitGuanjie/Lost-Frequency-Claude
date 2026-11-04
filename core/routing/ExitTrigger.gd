class_name ExitTrigger
extends Area3D
## A physical, source-backed exit. The edge it fires must be declared in the
## level's manifest (levels/<SID>/level.json) with a source quote or an
## ADAPTATION label. Trigger kinds:
##   walk_in  - entering the volume fires immediately
##   interact - player presses Interact while looking at / inside it
##   noclip   - player must press into the volume (moving against it) for
##              `hold_seconds` while the condition holds (sourced no-clip)
##   fall     - fires when the player's feet drop below `fall_y` inside volume
##   dwell    - fires after standing inside for `hold_seconds`
##   condition- fires when `condition` Callable returns true while inside

signal fired(edge_id: String)

@export var edge_id := ""
@export var kind := "walk_in"
@export var prompt := ""
@export var hold_seconds := 2.0
var fall_y := -1000.0
var condition: Callable
var enabled := true
var size := Vector3.ONE
var _inside: Node3D = null
var _hold := 0.0
var _fired := false
var tag_label := "SOURCE"     # SOURCE | ADAPTATION | DEBUG ONLY (dev hint mode)


func setup(id: String, trigger_kind: String, center: Vector3, box_size: Vector3, p: String = "") -> void:
	edge_id = id
	kind = trigger_kind
	prompt = p
	size = box_size
	position = center
	collision_layer = 0
	collision_mask = 2   # player layer
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box_size
	cs.shape = sh
	add_child(cs)
	add_to_group("exit_trigger")
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(b: Node3D) -> void:
	if b is Player:
		_inside = b
		_hold = 0.0
		if kind == "walk_in":
			fire()
		elif prompt != "":
			(b as Player).set_zone_prompt(self, prompt)


func _on_exit(b: Node3D) -> void:
	if b == _inside:
		if b is Player:
			(b as Player).set_zone_prompt(self, "")
		_inside = null
		_hold = 0.0


func _physics_process(delta: float) -> void:
	if _inside == null or not enabled or _fired:
		return
	var p := _inside as Player
	match kind:
		"noclip":
			if p.pushing_into(global_position, size) and (not condition.is_valid() or condition.call()):
				_hold += delta
				p.noclip_progress(_hold / hold_seconds)
				if _hold >= hold_seconds:
					fire()
			else:
				_hold = maxf(0.0, _hold - delta * 2.0)
				p.noclip_progress(_hold / hold_seconds)
		"fall":
			if p.global_position.y < fall_y:
				fire()
		"dwell":
			_hold += delta
			if _hold >= hold_seconds:
				fire()
		"condition":
			if condition.is_valid() and condition.call():
				fire()


## Interact-kind exits are fired by the player's interact action.
func interact(_p: Player) -> void:
	if kind == "interact" and enabled and (not condition.is_valid() or condition.call()):
		fire()


func get_prompt() -> String:
	return prompt


func fire() -> void:
	if _fired or not enabled:
		return
	_fired = true
	fired.emit(edge_id)
	TransitionService.request_exit(edge_id)
	# allow re-firing after a short delay in QA intercept mode or after refusal
	await get_tree().create_timer(1.5).timeout
	_fired = false
	_hold = 0.0
