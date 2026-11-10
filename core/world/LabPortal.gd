class_name LabPortal
extends ExitTrigger
## A portal in the procedural laboratory.
##
## The story exits call `TransitionService.request_exit()` directly, which
## loads the destination and spawns a NEW player there. A laboratory portal
## hands the edge to the persistent `WorldCoordinator` instead, so the
## wanderer, the light, the inventory and the body state cross the fold
## instead of being thrown away and rebuilt.
##
## The physics are inherited unchanged from `ExitTrigger`: a `noclip` portal
## still requires the player to push into the volume, still reports the
## progress on the HUD, and still refuses to fire while its condition is false.

## The connection kind of this portal. NOCLIP is a non-Euclidean fold; the
## coordinator refuses any other kind for a laboratory edge.
var transfer_kind := WorldCoordinator.KIND_NOCLIP


func setup_portal(edge: String, center: Vector3, box_size: Vector3, p: String = "",
		kind: String = "noclip") -> void:
	setup(edge, kind, center, box_size, p)
	hold_seconds = 1.2


func fire() -> void:
	if _fired or not enabled:
		return
	# A caller must not bypass the portal's own condition.
	if condition.is_valid() and not condition.call():
		return
	_fired = true
	fired.emit(edge_id)
	var coordinator := WorldCoordinator.ensure(get_tree())
	if coordinator == null:
		push_error("LabPortal: no WorldCoordinator available for edge " + edge_id)
		_fired = false
		return
	# The portal stays latched until the fold has actually completed. The
	# destination takes seconds to load, and a trigger that re-fires in the
	# meantime would start a second, competing transfer.
	#
	# The latch is released by the coordinator's own signals, not by a loop
	# in this function: the fold releases the place this portal lives in, so
	# this node may be gone long before the fold ends. A connection to a
	# freed node is dropped by the engine, which is the right behaviour.
	if not coordinator.transfer_completed.is_connected(_on_transfer_completed):
		coordinator.transfer_completed.connect(_on_transfer_completed, Object.CONNECT_ONE_SHOT)
	if not coordinator.transfer_failed.is_connected(_on_transfer_failed):
		coordinator.transfer_failed.connect(_on_transfer_failed, Object.CONNECT_ONE_SHOT)
	# The transfer is NOT awaited here, and that is deliberate.
	#
	# The coordinator owns the fold and outlives this portal, so the fold
	# must not depend on a node that the fold itself frees. The upstream
	# story exits already rely on exactly this: TransitionService.request_exit()
	# calls the coroutine load_level() without awaiting it, and the engine
	# keeps such a coroutine alive until it finishes.
	coordinator.transfer(edge_id, transfer_kind)


func _on_transfer_completed(_edge: Dictionary, _kind: String) -> void:
	if not is_instance_valid(self):
		return
	_fired = false
	_hold = 0.0


func _on_transfer_failed(edge: Dictionary, reason: String) -> void:
	if not is_instance_valid(self):
		return
	_fired = false
	_hold = 0.0
	push_warning("LabPortal: the fold for edge %s did not complete: %s"
		% [str(edge.get("id", edge_id)), reason])
