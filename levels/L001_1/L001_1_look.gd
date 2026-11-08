extends RefCounted
## Level 1.1 look: materials and the scripted presences (Smilers, Sector 4
## entities, the Sector 5 beacon). No combat; see the entity policy in level.json.

static func materials(HUE_COL: Array) -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	var block := {"albedo_a": Color(0.8, 0.8, 0.78), "albedo_b": Color(0.75, 0.75, 0.73), "pattern": 4, "pattern_scale": Vector2(0.4, 0.2),
		"grout_width": 0.012, "grout_color": Color(0.62, 0.62, 0.6), "pattern_strength": 0.0, "bump_strength": 1.1, "noise_scale": 1.4,
		"stain_amount": 0.2, "stain_color": Color(0.62, 0.6, 0.55), "grime_height": 0.35, "grime_color": Color(0.55, 0.55, 0.52), "roughness_a": 0.85}
	var floor := {"albedo_a": Color(0.1, 0.22, 0.48), "albedo_b": Color(0.09, 0.2, 0.44), "pattern": 1, "pattern_scale": Vector2(0.3, 0.3),
		"grout_width": 0.03, "grout_color": Color(0.55, 0.6, 0.66), "roughness_a": 0.3, "roughness_b": 0.45, "tile_variation": 0.05, "stain_amount": 0.15,
		"stain_color": Color(0.08, 0.14, 0.26), "bump_strength": 0.4}
	var ceil := {"albedo_a": Color(0.78, 0.78, 0.76), "albedo_b": Color(0.72, 0.72, 0.7), "stain_amount": 0.25, "stain_color": Color(0.55, 0.52, 0.45), "noise_scale": 1.2}
	m.call("l11_block", "brick", block)
	m.call("l11_floor", "pool_tile", floor)
	m.call("l11_ceil", "plaster", ceil)
	for h in range(1, 5):
		var tint: Color = HUE_COL[h]
		var b2: Dictionary = block.duplicate()
		b2["albedo_a"] = Color(0.8, 0.8, 0.78) * tint
		b2["albedo_b"] = Color(0.75, 0.75, 0.73) * tint
		b2["grout_color"] = Color(0.6, 0.6, 0.58) * tint
		m.call("l11_block_h%d" % h, "brick", b2)
		var f2: Dictionary = floor.duplicate()
		f2["albedo_a"] = Color(0.1, 0.22, 0.48).lerp(tint * 0.4, 0.55)
		f2["albedo_b"] = Color(0.09, 0.2, 0.44).lerp(tint * 0.35, 0.55)
		m.call("l11_floor_h%d" % h, "pool_tile", f2)
		var c2: Dictionary = ceil.duplicate()
		c2["albedo_a"] = Color(0.78, 0.78, 0.76) * tint
		c2["albedo_b"] = Color(0.72, 0.72, 0.7) * tint
		m.call("l11_ceil_h%d" % h, "plaster", c2)
		MatLib.register("l11_tube_h%d" % h, MatLib.panel(tint, 2.4, 0.25))
	var bw: Dictionary = block.duplicate()
	bw["albedo_a"] = Color(0.85, 0.85, 0.85)
	bw["albedo_b"] = Color(0.8, 0.8, 0.8)
	bw["grout_color"] = Color(0.1, 0.1, 0.1)
	bw["grout_width"] = 0.03
	m.call("l11_bw_block", "brick", bw)
	m.call("l11_bw_floor", "pool_tile", {"albedo_a": Color(0.06, 0.06, 0.06), "albedo_b": Color(0.04, 0.04, 0.04), "pattern": 9, "pattern_scale": Vector2(1.0, 1.0),
		"pattern_color": Color(0.85, 0.85, 0.85), "pattern_strength": 1.0, "roughness_a": 0.3})
	m.call("l11_bw_ceil", "plaster", {"albedo_a": Color(0.9, 0.9, 0.9), "albedo_b": Color(0.85, 0.85, 0.85)})
	m.call("l11_block_raw", "brick", {"albedo_a": Color(0.47, 0.46, 0.44), "albedo_b": Color(0.4, 0.39, 0.37), "pattern_scale": Vector2(0.4, 0.2),
		"grout_color": Color(0.33, 0.32, 0.3), "bump_strength": 1.4})
	m.call("l11_plank", "wood_floor", {"albedo_a": Color(0.42, 0.3, 0.19), "albedo_b": Color(0.34, 0.24, 0.15), "pattern_scale": Vector2(1.8, 0.2)})
	m.call("l11_wood", "wood_floor", {"albedo_a": Color(0.5, 0.38, 0.24), "albedo_b": Color(0.4, 0.3, 0.18)})
	m.call("l11_crate", "wood_floor", {"albedo_a": Color(0.58, 0.45, 0.28), "albedo_b": Color(0.48, 0.36, 0.21), "pattern_scale": Vector2(1.2, 0.15), "stain_amount": 0.3})
	m.call("l11_crate_dark", "wood_floor", {"albedo_a": Color(0.35, 0.26, 0.16), "albedo_b": Color(0.28, 0.2, 0.12)})
	m.call("l11_metal", "metal", {"albedo_a": Color(0.5, 0.52, 0.54), "albedo_b": Color(0.42, 0.44, 0.46), "metallic_value": 0.5})
	m.call("l11_pipe", "metal", {"albedo_a": Color(0.42, 0.45, 0.42), "albedo_b": Color(0.34, 0.36, 0.33), "metallic_value": 0.5, "stain_amount": 0.4})
	m.call("l11_rust", "rust", {})
	m.call("l11_duct", "metal", {"albedo_a": Color(0.64, 0.66, 0.67), "albedo_b": Color(0.54, 0.56, 0.57), "metallic_value": 0.7, "roughness_a": 0.4})
	m.call("l11_cavity", "concrete_dark", {"albedo_a": Color(0.2, 0.19, 0.18), "albedo_b": Color(0.13, 0.12, 0.12), "stain_amount": 0.6, "stain_color": Color(0.25, 0.18, 0.1)})
	m.call("l11_mattress", "plaster", {"albedo_a": Color(0.78, 0.8, 0.84), "albedo_b": Color(0.72, 0.74, 0.78), "pattern": 2, "pattern_scale": Vector2(0.08, 1.0), "pattern_color": Color(0.3, 0.4, 0.62), "pattern_strength": 0.6, "noise_scale": 3.0, "bump_strength": 0.8})
	m.call("l11_cooler", "plaster", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.8, 0.8, 0.78), "roughness_a": 0.4})
	m.call("l11_cooler_lid", "plaster", {"albedo_a": Color(0.15, 0.3, 0.62), "albedo_b": Color(0.12, 0.26, 0.55), "roughness_a": 0.4})
	m.call("l11_cardboard", "plaster", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.47, 0.35, 0.21), "noise_scale": 4.0})
	m.call("l11_wtile", "pool_tile", {"pattern_scale": Vector2(0.2, 0.2), "albedo_a": Color(0.86, 0.87, 0.86), "albedo_b": Color(0.82, 0.83, 0.82)})
	m.call("l11_wtile_floor", "pool_tile", {"pattern_scale": Vector2(0.3, 0.3), "albedo_a": Color(0.8, 0.8, 0.79), "albedo_b": Color(0.74, 0.74, 0.73),
		"grout_color": Color(0.55, 0.55, 0.53), "stain_amount": 0.2, "stain_color": Color(0.6, 0.58, 0.52)})
	m.call("l11_counter", "plaster", {"albedo_a": Color(0.7, 0.7, 0.68), "albedo_b": Color(0.64, 0.64, 0.62), "roughness_a": 0.4})
	m.call("l11_bottle", "plaster", {"albedo_a": Color(0.85, 0.82, 0.68), "albedo_b": Color(0.8, 0.77, 0.62), "roughness_a": 0.15})
	m.call("l11_can", "metal", {"albedo_a": Color(0.7, 0.2, 0.15), "albedo_b": Color(0.6, 0.6, 0.6), "metallic_value": 0.6})
	m.call("l11_canvas", "plaster", {"albedo_a": Color(0.45, 0.43, 0.32), "albedo_b": Color(0.4, 0.38, 0.28), "noise_scale": 5.0})
	m.call("l11_stick", "wood_floor", {"albedo_a": Color(0.45, 0.35, 0.22), "albedo_b": Color(0.36, 0.27, 0.16), "pattern": 0})
	for c in [["r", Color(0.55, 0.12, 0.1)], ["g", Color(0.2, 0.36, 0.2)], ["b", Color(0.15, 0.2, 0.42)], ["y", Color(0.7, 0.58, 0.25)]]:
		m.call("l11_cloth_" + c[0], "plaster", {"albedo_a": c[1], "albedo_b": (c[1] as Color).darkened(0.25), "noise_scale": 6.0, "bump_strength": 1.2, "roughness_a": 1.0})
	m.call("l11_glyph", "plaster", {"albedo_a": Color(0.05, 0.04, 0.04), "albedo_b": Color(0.12, 0.03, 0.03), "roughness_a": 0.6})
	m.call("l11_sign_white", "plaster", {"albedo_a": Color(0.9, 0.9, 0.88), "albedo_b": Color(0.86, 0.86, 0.84), "roughness_a": 0.4})
	m.call("l11_sign_yellow", "plaster", {"albedo_a": Color(0.9, 0.72, 0.1), "albedo_b": Color(0.86, 0.68, 0.08), "roughness_a": 0.4})
	m.call("l11_tape", "plaster", {"albedo_a": Color(0.9, 0.75, 0.1), "albedo_b": Color(0.9, 0.75, 0.1), "pattern": 2, "pattern_scale": Vector2(0.2, 1.0),
		"pattern_color": Color(0.05, 0.05, 0.05), "pattern_strength": 1.0})
	m.call("l11_l1_floor", "concrete", {"albedo_a": Color(0.4, 0.4, 0.39), "albedo_b": Color(0.33, 0.33, 0.32), "wetness": 0.4})
	m.call("l11_l1_wall", "concrete", {"albedo_a": Color(0.45, 0.45, 0.44), "albedo_b": Color(0.38, 0.38, 0.37)})
	m.call("l11_glitch", "brick", {"albedo_a": Color(0.8, 0.8, 0.8), "albedo_b": Color(0.7, 0.7, 0.75), "emission_color": Color(0.55, 0.75, 1.0),
		"emission_energy": 0.7, "emission_flicker": 1.0, "pattern_scale": Vector2(0.4, 0.2)})
	MatLib.register("l11_tube", MatLib.panel(Color(0.92, 0.96, 1.0), 2.6))
	MatLib.register("l11_tube_l1", MatLib.panel(Color(0.85, 0.9, 0.95), 1.8, 0.4))
	MatLib.register("l11_tube_o2", MatLib.panel(Color(0.95, 0.97, 1.0), 2.6))
	MatLib.register("l11_tube_dead", MatLib.panel(Color(0.1, 0.1, 0.1), 0.0, 0.0, 100.0))
	MatLib.register("l11_tube_flick", MatLib.panel(Color(0.92, 0.96, 1.0), 2.4, 1.0))
	MatLib.register("l11_tube_bw", MatLib.panel(Color(1, 1, 1), 3.2, 0.6))
	var lantern := MatLib.panel(Color(1.0, 0.75, 0.4), 2.4)
	MatLib.register("l11_lantern", lantern)


## A Smiler: a grin and two eyes in the dark that are gone when you get close.
static func smiler(node: Node3D, pos: Vector3) -> Node3D:
	var s := Node3D.new()
	s.position = pos
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 0.96)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for e in [-0.11, 0.11]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.045)
		q.material = mat
		mi.mesh = q
		mi.position = Vector3(e, 0.12, 0)
		s.add_child(mi)
	var grin := MeshInstance3D.new()
	var gq := QuadMesh.new()
	gq.size = Vector2(0.38, 0.07)
	gq.material = mat
	grin.mesh = gq
	grin.position = Vector3(0, -0.08, 0)
	s.add_child(grin)
	node.add_child(s)
	return s


## A glitched, mutated entity hanging in the air of Sector 4 (no attack).
static func floater(node: Node3D, pos: Vector3, r: RandomNumberGenerator) -> Node3D:
	var f := Node3D.new()
	f.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.02)
	mat.roughness = 1.0
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.7
	cap.material = mat
	body.mesh = cap
	body.rotation.z = r.randf_range(-0.9, 0.9)
	f.add_child(body)
	for a in r.randi_range(2, 5):
		var arm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.07, r.randf_range(0.7, 1.3), 0.07)
		bm.material = mat
		arm.mesh = bm
		arm.position = Vector3(r.randf_range(-0.3, 0.3), r.randf_range(-0.4, 0.5), 0)
		arm.rotation = Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1.4, 1.4))
		f.add_child(arm)
	if r.randf() < 0.3:
		for wsd in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var wq := QuadMesh.new()
			wq.size = Vector2(1.3, 0.8)
			var wm := StandardMaterial3D.new()
			wm.albedo_color = Color(0.5, 0.5, 0.5)
			wm.cull_mode = BaseMaterial3D.CULL_DISABLED
			wq.material = wm
			wing.mesh = wq
			wing.position = Vector3(wsd * 0.75, 0.35, 0)
			wing.rotation.y = wsd * 0.4
			f.add_child(wing)
	node.add_child(f)
	return f


static func beacon_node(pos: Vector3) -> Node3D:
	var beacon := Node3D.new()
	beacon.name = "Beacon"
	beacon.position = pos
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.2
	sm.height = 4.4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 1.0, 0.95)
	mat.disable_fog = true
	sm.material = mat
	mi.mesh = sm
	beacon.add_child(mi)
	beacon.visible = false
	return beacon


