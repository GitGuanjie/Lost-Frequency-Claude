class_name WaterVolume
extends Node3D
## Axis-aligned swimmable water body. The player queries volumes in group
## "water" each physics tick (cheap: a few boxes per level). Optionally builds
## the visible surface. Underwater fog/tint parameters are per volume.

var aabb := AABB()
var surface_y := 0.0
var current := Vector3.ZERO            # gentle drift (m/s)
var fog_color := Color(0.05, 0.25, 0.3)
var fog_density := 0.08
var tint := Color(0.1, 0.45, 0.5)
var surface_mesh: MeshInstance3D


func setup(min_corner: Vector3, max_corner: Vector3, material_name: String = "water_pool", build_surface: bool = true) -> void:
	aabb = AABB(min_corner, max_corner - min_corner)
	surface_y = max_corner.y
	add_to_group("water")
	if build_surface:
		var pm := PlaneMesh.new()
		pm.size = Vector2(aabb.size.x, aabb.size.z)
		var sub := int(clampf(maxf(aabb.size.x, aabb.size.z) / 1.5, 2, 64))
		pm.subdivide_width = sub
		pm.subdivide_depth = sub
		surface_mesh = MeshInstance3D.new()
		surface_mesh.mesh = pm
		surface_mesh.material_override = MatLib.get_mat(material_name)
		surface_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surface_mesh.position = Vector3(aabb.position.x + aabb.size.x * 0.5, surface_y, aabb.position.z + aabb.size.z * 0.5)
		add_child(surface_mesh)


func contains(p: Vector3) -> bool:
	return p.x >= aabb.position.x and p.x <= aabb.end.x and p.z >= aabb.position.z \
		and p.z <= aabb.end.z and p.y >= aabb.position.y and p.y <= surface_y


func depth_at(p: Vector3) -> float:
	return surface_y - p.y
