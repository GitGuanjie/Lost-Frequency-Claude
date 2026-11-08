extends Node3D
## Rendered smoke test for imported models (needs a display / xvfb + vulkan).
func _ready() -> void:
	var ids := ["ph/metal_office_desk", "ph/SchoolChair_01", "ph/drawer_cabinet", "ph/WetFloorSign_01",
		"ph/Barrel_01", "ph/fire_hydrant", "ph/Sofa_01", "ph/old_bed_frame", "ph/Chandelier_01",
		"ph/rubber_duck_toy", "ph/portable_generator", "ph/steel_frame_shelves_01", "ph/Television_01",
		"ph/street_lamp_01", "ph/wooden_crate_01", "ph/boulder_01"]
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.2, 0.22)
	e.ambient_light_color = Color(0.6, 0.6, 0.6)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 30)
	floor.mesh = pm
	add_child(floor)
	for i in ids.size():
		Props.place(self, self, ids[i], Vector3((i % 4) * 2.2 - 3.3, 0, int(i / 4) * 2.2 - 3.3), 20.0, 0.0 if ids[i] != "ph/street_lamp_01" else 2.0)
	var cam := Camera3D.new()
	add_child(cam)
	cam.look_at_from_position(Vector3(0, 5.5, 8.5), Vector3(0, 0.3, -0.5))
	for i in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_jpg(ProjectSettings.globalize_path("res://.work/props_gallery.jpg"), 0.85)
	get_tree().quit()
