class_name LadderVolume
extends Node3D
## Climbable volume (ladders, shafts, ceiling holes, rope). While the player's
## body is inside, forward/back input climbs instead of walking; Jump lets go.

var aabb := AABB()
var top_exit := Vector3.ZERO     # optional: where the player steps off at the top


func setup(min_corner: Vector3, max_corner: Vector3) -> void:
	aabb = AABB(min_corner, max_corner - min_corner)
	add_to_group("ladder")


func contains(p: Vector3) -> bool:
	return aabb.grow(0.05).has_point(p)
