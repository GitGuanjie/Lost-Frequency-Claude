extends LevelBase
## Level 999 — The Unchanging Island.
## Canon: docs/canon/levels/L999.md (Greggita Mahayfaio, CC BY-SA 3.0).
## A finite, motionless, greyscale island in a starry void, with an inverted
## rocky pyramid underneath and one trapdoor exit among benches at its heart.
## IN_DEVELOPMENT: engine QA / review required before PLAYABLE.

const RIM := 72.0
const INNER := 52.0
const START := Vector3(-43.0, 0.05, 6.0)

var door: ExitTrigger
var trees := 0
var houses := 0
var stars: MultiMeshInstance3D


func build() -> void:
	rules["view_distance"] = 1600.0
	rules["reverb_room"] = 0.0
	rules["reverb_wet"] = 0.0
	indoor_env(Color(0.77, 0.78, 0.81), 0.72, Color(0.2, 0.2, 0.22), 0.0)
	environment.background_color = Color(0.003, 0.004, 0.009)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.0
	environment.tonemap_exposure = 0.88
	environment.glow_enabled = false
	_materials()
	lights.setup(4, 1)
	_ground()
	_starfield()
	_forest_and_houses()
	_trapdoor()
	add_arrival("start", START, -45.0)
	add_arrival("from_EXT", START, -45.0)
	sound.bed("wind", {"seconds": 6.0}, -26.0)
	add_landmark("The pale shoreline", START)
	add_landmark("Motionless houses", Vector3(0, 0, 14.0))
	add_landmark("The central trapdoor", Vector3.ZERO)
	add_shot("stars_and_sand", Vector3(-55, 1.62, 9), Vector3(-10, 1.4, 9))
	add_shot("central_benches", Vector3(-13, 1.62, -10), Vector3(0, 0.4, 0))


func _materials() -> void:
	MatLib.define("l999_ash", {"albedo_a": Color(0.49, 0.49, 0.49), "albedo_b": Color(0.60, 0.60, 0.60), "noise_scale": 3.0, "roughness_a": 1.0}, "sand")
	MatLib.define("l999_soil", {"albedo_a": Color(0.28, 0.28, 0.28), "albedo_b": Color(0.35, 0.35, 0.35), "roughness_a": 1.0}, "dirt")
	MatLib.define("l999_rock", {"albedo_a": Color(0.23, 0.23, 0.25), "albedo_b": Color(0.35, 0.35, 0.36), "noise_scale": 4.0, "bump_strength": 2.0}, "rock")
	MatLib.define("l999_bark", {"albedo_a": Color(0.32, 0.32, 0.32), "albedo_b": Color(0.43, 0.43, 0.43), "roughness_a": 0.95}, "wood_floor")
	MatLib.define("l999_leaf", {"albedo_a": Color(0.44, 0.44, 0.44), "albedo_b": Color(0.53, 0.53, 0.53), "roughness_a": 0.98}, "plaster")
	MatLib.define("l999_house", {"albedo_a": Color(0.54, 0.54, 0.54), "albedo_b": Color(0.46, 0.46, 0.46), "stain_amount": 0.7, "roughness_a": 0.85}, "concrete")
	MatLib.define("l999_wood", {"albedo_a": Color(0.36, 0.36, 0.36), "albedo_b": Color(0.32, 0.32, 0.32)}, "wood_floor")
	MatLib.define("l999_iron", {"albedo_a": Color(0.22, 0.22, 0.22), "albedo_b": Color(0.28, 0.28, 0.28), "metallic_value": 0.64}, "metal")


func _ground() -> void:
	var k := kit("ImmutableIsland")
	k.cylinder(Vector3(0, -0.26, 0), RIM, 0.55, "l999_ash", 96)
	k.cylinder(Vector3(0, 0.00, 0), INNER, 0.10, "l999_soil", 80)
	# The flat playable surface is above an enormous inverted stony cone.
	var underside := MeshInstance3D.new()
	underside.name = "InvertedRockMass"
	var cone := CylinderMesh.new()
	cone.top_radius = RIM
	cone.bottom_radius = 0.0
	cone.height = 90.0
	cone.radial_segments = 72
	underside.mesh = cone
	underside.position = Vector3(0, -45.5, 0)
	underside.material_override = MatLib.get_mat("l999_rock")
	add_child(underside)
	# A few rocks and sand fragments hang motionless outside the island.
	for i in 35:
		var a := rng.randf_range(0, TAU)
		var d := rng.randf_range(74.0, 115.0)
		var pos := Vector3(cos(a) * d, rng.randf_range(-9.0, 3.0), sin(a) * d)
		k.box(pos, Vector3(rng.randf_range(0.4, 2.4), rng.randf_range(0.3, 1.7), rng.randf_range(0.4, 2.1)), "l999_rock", GeoKit.ALL, false)
	k.commit()


func _starfield() -> void:
	stars = MultiMeshInstance3D.new()
	stars.name = "UnchangingStarfield"
	var mesh := SphereMesh.new()
	mesh.radius = 0.36
	mesh.height = 0.72
	mesh.radial_segments = 6
	mesh.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.73, 0.73, 0.76)
	mat.emission_enabled = true
	mat.emission = Color(0.77, 0.78, 0.82)
	mat.emission_energy_multiplier = 1.4
	mesh.material = mat
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = 220
	for i in multi.instance_count:
		var az := rng.randf_range(-PI, PI)
		var h := rng.randf_range(-0.12, 0.98)
		var r := sqrt(1.0 - h * h)
		var p := Vector3(cos(az) * r, h, sin(az) * r) * rng.randf_range(370.0, 470.0)
		var scale := rng.randf_range(0.3, 1.3)
		multi.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * scale), p))
	stars.multimesh = multi
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stars)


func _forest_and_houses() -> void:
	var k := kit("StillForest")
	for i in 95:
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf()) * (INNER - 6.0)
		var p := Vector3(cos(angle) * radius, 0.05, sin(angle) * radius)
		if p.length() < 13.0 or p.distance_to(START) < 7.0:
			continue
		_tree(k, p)
		# no swaying animation: trees, wind and houses never change
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.23
		var p := Vector3(cos(angle) * 17.0, 0.06, sin(angle) * 17.0)
		_house(k, p, i)
	k.commit()


func _tree(k: GeoKit, p: Vector3) -> void:
	var h := rng.randf_range(7.0, 13.0)
	k.cylinder(p + Vector3.UP * (h * 0.5), 0.26, h, "l999_bark", 7)
	for j in 6:
		var a := TAU * float(j) / 6.0
		var leaf := p + Vector3(cos(a) * 1.9, h - 0.10, sin(a) * 1.9)
		k.box_xf(Transform3D(Basis(Vector3.UP, a), leaf), Vector3(0.55, 0.11, 4.7), "l999_leaf", GeoKit.ALL, false)
	trees += 1


func _house(k: GeoKit, p: Vector3, index: int) -> void:
	var half := Vector3(3.8, 0, 3.3)
	var x0 := p.x - half.x
	var x1 := p.x + half.x
	var z0 := p.z - half.z
	var z1 := p.z + half.z
	k.slab(x0, z0, x1, z1, 0.07, 0.30, "l999_house")
	k.box_mm(Vector3(x0, 0, z0), Vector3(x0+0.25, 3.0, z1), "l999_house")
	k.box_mm(Vector3(x1-0.25, 0, z0), Vector3(x1, 3.0, z1), "l999_house")
	k.box_mm(Vector3(x0, 0, z0), Vector3(x1, 3.0, z0+0.25), "l999_house")
	k.box_mm(Vector3(x0, 0, z1-0.25), Vector3(p.x-1.1, 3.0, z1), "l999_house")
	k.box_mm(Vector3(p.x+1.1, 0, z1-0.25), Vector3(x1, 3.0, z1), "l999_house")
	k.box_mm(Vector3(p.x-1.1, 2.45, z1-0.25), Vector3(p.x+1.1, 3.0, z1), "l999_house")
	k.box_mm(Vector3(x0, 3.0, z0), Vector3(x1, 3.4, z1), "l999_wood")
	# Sparse, abandoned beds and immovable furniture, not resources.
	k.box(p + Vector3(-1.7, 0.37, 0.8), Vector3(1.7, 0.57, 2.5), "l999_wood")
	k.box(p + Vector3(1.7, 0.45, -1.2), Vector3(1.0, 0.88, 1.0), "l999_house")
	houses += 1


func _trapdoor() -> void:
	var k := kit("UnchangingEpicenter")
	for i in 5:
		var ang := TAU * float(i) / 5.0
		var p := Vector3(sin(ang) * 5.5, 0.07, cos(ang) * 5.5)
		k.box(p + Vector3.UP * 0.45, Vector3(2.3, 0.10, 0.54), "l999_wood")
		for xoff in [-0.8, 0.8]:
			k.box(p + Vector3(xoff, 0.22, 0), Vector3(0.16, 0.44, 0.5), "l999_iron")
	k.box(Vector3(0, 0.09, 0), Vector3(2.4, 0.14, 2.1), "l999_wood", GeoKit.ALL, false)
	k.box(Vector3(0, 0.17, 0), Vector3(2.05, 0.025, 1.8), "l999_iron", GeoKit.ALL, false)
	k.commit()
	door = add_exit("L999>EXT#1", "interact", Vector3(0, 1.0, 0), Vector3(2.6, 1.8, 2.5), "Open the trapdoor between the benches")


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[wind that moves nothing] [the island remains still]", 5.0)


func level_process(_delta: float) -> void:
	if player == null:
		return
	# Release-boundary safety only: the source gives no rule for walking into
	# the void. Do not invent a death, a portal, an entity or a collectible.
	var p := player.global_position
	var d := Vector2(p.x, p.z)
	if d.length() > RIM - 0.6 and p.y >= -0.5:
		var clamped := d.normalized() * (RIM - 0.6)
		player.global_position = Vector3(clamped.x, p.y, clamped.y)


func qa_self_test() -> Array:
	return [
		{"ok": trees > 30, "what": "motionless grey forest populated"},
		{"ok": houses == 4, "what": "four sparse houses near epicenter"},
		{"ok": door != null, "what": "only documented trapdoor exit exists"},
		{"ok": stars != null, "what": "fixed starfield generated"},
	]
