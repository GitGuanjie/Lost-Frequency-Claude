class_name WorldAddress
extends RefCounted
## Explicit address of one physical place inside a generated world.
##
##   world_id       which generated world owns the place (seed + generator version)
##   zone_id        the architectural zone the place belongs to
##   chunk_x/y/z    the chunk coordinates inside that world
##   local_position position in metres relative to the chunk origin
##
## Canonical Backrooms identity (L000, L001, ...) is deliberately NOT part of
## the address. A canonical level is a story destination with its own rules and
## visual language; a physical coordinate is an address in a generated space.
## Keeping the two apart is what allows a district to keep the Level 0 look
## without every other region collapsing into the same architecture.
##
## The address is stable: the same world_id and the same coordinates always
## produce the same zone and the same local offset, whatever order the chunks
## were visited or rebuilt in.

var world_id: String = ""
var zone_id: String = ""
var chunk: Vector3i = Vector3i.ZERO
var local_position: Vector3 = Vector3.ZERO


static func make(world_id_value: String, zone_id_value: String,
		chunk_key: Vector3i, local: Vector3) -> WorldAddress:
	var address := WorldAddress.new()
	address.world_id = world_id_value
	address.zone_id = zone_id_value
	address.chunk = chunk_key
	address.local_position = local
	return address


## Build an address from a world-space position. The zone is supplied by the
## caller because only the generator knows the zone map for a given world.
static func from_position(world_id_value: String, zone_id_value: String,
		world_position: Vector3) -> WorldAddress:
	var key := ContinuityTopology.key_for(world_position)
	return make(world_id_value, zone_id_value, key,
		world_position - ContinuityTopology.origin(key))


func world_position() -> Vector3:
	return ContinuityTopology.origin(chunk) + local_position


func chunk_origin() -> Vector3:
	return ContinuityTopology.origin(chunk)


## Compact, stable string used in save files and QA reports.
func encode() -> String:
	return "%s|%s|%d:%d:%d|%.3f,%.3f,%.3f" % [
		world_id, zone_id, chunk.x, chunk.y, chunk.z,
		local_position.x, local_position.y, local_position.z]


static func decode(text: String) -> WorldAddress:
	var parts := text.split("|")
	if parts.size() < 4:
		return null
	var coords := parts[2].split(":")
	if coords.size() != 3:
		return null
	var local := Vector3.ZERO
	if parts.size() >= 5:
		var nums := parts[4].split(",")
		if nums.size() == 3:
			local = Vector3(float(nums[0]), float(nums[1]), float(nums[2]))
	var address := WorldAddress.new()
	address.world_id = parts[0]
	address.zone_id = parts[1]
	address.chunk = Vector3i(int(coords[0]), int(coords[1]), int(coords[2]))
	address.local_position = local
	return address


func same_place(other: WorldAddress) -> bool:
	if other == null:
		return false
	return world_id == other.world_id and zone_id == other.zone_id and chunk == other.chunk


func _to_string() -> String:
	return encode()
