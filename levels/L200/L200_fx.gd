extends RefCounted
## Level 200 "Home" — materials, the rot shader, triangle helper and resident
## figures (no image files; everything is shader- or primitive-generated).
## The page names residents (Joe Vee, Ms. Garcia, Sarah Palmer, "everyone") but
## never classifies them; they are static figures, never movers or attackers.

const ROT_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform float grow = 0.3;
uniform float seed = 0.0;
float h(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { s += a * n2(p); p = p * 2.07 + 11.3; a *= 0.5; } return s; }
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float n = fbm(UV * 5.0 + seed * 7.1);
	float r = length(p) * 0.92 + (n - 0.5) * 0.55;
	float body = smoothstep(grow, grow - 0.12, r);
	float halo = smoothstep(grow + 0.18, grow - 0.02, r) * 0.45;
	float spots = smoothstep(0.62, 0.7, fbm(UV * 16.0 + seed)) * smoothstep(grow + 0.35, grow, r);
	float a = clamp(max(body, max(halo, spots)), 0.0, 1.0);
	float d = fbm(UV * 14.0 - seed);
	vec3 core = mix(vec3(0.05, 0.045, 0.03), vec3(0.16, 0.14, 0.06), d);
	vec3 rim = vec3(0.32, 0.25, 0.12);
	ALBEDO = mix(rim, core, body);
	ROUGHNESS = mix(0.85, 0.35, body);
	SPECULAR = 0.6;
	ALPHA = a * 0.95;
}
"""

static var _std: Dictionary = {}
static var _rot_shader: Shader


static func materials() -> void:
	MatLib.define("l200_siding", {"albedo_a": Color(0.46, 0.53, 0.58), "albedo_b": Color(0.42, 0.49, 0.54), "pattern": 2, "uv_rotate": 1.5708,
		"pattern_scale": Vector2(0.2, 1.0), "pattern_color": Color(0.36, 0.4, 0.43), "pattern_strength": 0.75, "peel_amount": 0.28,
		"peel_color": Color(0.42, 0.4, 0.36), "stain_amount": 0.25, "stain_color": Color(0.4, 0.42, 0.4), "grime_height": 0.7,
		"grime_color": Color(0.3, 0.3, 0.27), "roughness_a": 0.75, "bump_strength": 0.4}, "plaster")
	var sid := [Color(0.62, 0.58, 0.48), Color(0.45, 0.5, 0.45), Color(0.66, 0.64, 0.6), Color(0.52, 0.44, 0.38), Color(0.42, 0.48, 0.56)]
	for i in sid.size():
		var c: Color = sid[i]
		MatLib.define("l200_sid%d" % i, {"albedo_a": c, "albedo_b": c * 0.94, "pattern": 2, "uv_rotate": 1.5708, "pattern_scale": Vector2(0.2, 1.0),
			"pattern_color": c * 0.62, "pattern_strength": 0.7, "grime_height": 0.6, "grime_color": c * 0.55, "stain_amount": 0.18,
			"stain_color": c * 0.7, "peel_amount": 0.12, "peel_color": c * 0.6}, "plaster")
	MatLib.define("l200_trim", {"albedo_a": Color(0.86, 0.85, 0.81), "albedo_b": Color(0.8, 0.79, 0.75), "stain_amount": 0.2,
		"stain_color": Color(0.6, 0.6, 0.55)}, "trim_white")
	MatLib.define("l200_roof", {"pattern": 14, "pattern_scale": Vector2(0.34, 0.16), "grout_width": 0.012, "grout_color": Color(0.08, 0.08, 0.09),
		"albedo_a": Color(0.2, 0.2, 0.22), "albedo_b": Color(0.16, 0.16, 0.18), "tile_variation": 0.1, "roughness_a": 0.85}, "concrete")
	MatLib.define("l200_roof_b", {"pattern": 14, "pattern_scale": Vector2(0.34, 0.16), "grout_width": 0.012, "grout_color": Color(0.1, 0.07, 0.06),
		"albedo_a": Color(0.3, 0.22, 0.19), "albedo_b": Color(0.25, 0.18, 0.16), "tile_variation": 0.1}, "concrete")
	MatLib.define("l200_brick", {"albedo_a": Color(0.47, 0.26, 0.2), "albedo_b": Color(0.4, 0.22, 0.17), "grime_height": 1.0,
		"grime_color": Color(0.22, 0.15, 0.12)}, "brick")
	MatLib.define("l200_brick_b", {"albedo_a": Color(0.56, 0.45, 0.36), "albedo_b": Color(0.5, 0.4, 0.32)}, "brick")
	MatLib.define("l200_concrete", {"albedo_a": Color(0.52, 0.52, 0.5), "albedo_b": Color(0.45, 0.45, 0.43)}, "concrete")
	MatLib.define("l200_sidewalk", {"pattern": 1, "pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.012, "grout_color": Color(0.3, 0.3, 0.29),
		"albedo_a": Color(0.6, 0.6, 0.58), "albedo_b": Color(0.53, 0.53, 0.51), "tile_variation": 0.08}, "concrete")
	MatLib.define("l200_asphalt", {"albedo_a": Color(0.2, 0.2, 0.21), "albedo_b": Color(0.15, 0.15, 0.16), "wetness": 0.15}, "asphalt")
	MatLib.define("l200_grass", {"albedo_a": Color(0.3, 0.33, 0.2), "albedo_b": Color(0.24, 0.27, 0.16), "pattern_color": Color(0.36, 0.38, 0.22)}, "grass")
	MatLib.define("l200_hedge", {"albedo_a": Color(0.17, 0.21, 0.12), "albedo_b": Color(0.12, 0.15, 0.08), "bump_strength": 2.4, "noise_scale": 4.0}, "dirt")
	MatLib.define("l200_fence_wood", {"albedo_a": Color(0.45, 0.4, 0.33), "albedo_b": Color(0.38, 0.33, 0.27), "uv_rotate": 1.5708,
		"pattern_scale": Vector2(1.8, 0.14)}, "wood_floor")
	MatLib.define("l200_oak", {"albedo_a": Color(0.5, 0.36, 0.22), "albedo_b": Color(0.43, 0.3, 0.18), "stain_amount": 0.2,
		"stain_color": Color(0.3, 0.22, 0.14)}, "wood_floor")
	MatLib.define("l200_wood_dark", {"albedo_a": Color(0.26, 0.17, 0.1), "albedo_b": Color(0.21, 0.13, 0.08)}, "wood_floor")
	MatLib.define("l200_stud_wood", {"albedo_a": Color(0.6, 0.5, 0.36), "albedo_b": Color(0.52, 0.43, 0.3), "uv_rotate": 1.5708,
		"stain_amount": 0.4, "stain_color": Color(0.3, 0.25, 0.18)}, "wood_floor")
	MatLib.define("l200_tile", {"pattern": 9, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.25, 0.27, 0.3), "pattern_strength": 0.5,
		"albedo_a": Color(0.8, 0.79, 0.74), "albedo_b": Color(0.75, 0.74, 0.7), "stain_amount": 0.25}, "pool_tile")
	MatLib.define("l200_tile_wall", {"albedo_a": Color(0.72, 0.8, 0.8), "albedo_b": Color(0.68, 0.76, 0.76), "pattern_scale": Vector2(0.15, 0.15)}, "pool_tile")
	MatLib.define("l200_carpet", {"albedo_a": Color(0.42, 0.36, 0.33), "albedo_b": Color(0.37, 0.31, 0.28), "wetness": 0.0, "stain_amount": 0.15}, "l0_carpet")
	MatLib.define("l200_ceiling", {"albedo_a": Color(0.8, 0.79, 0.75), "albedo_b": Color(0.75, 0.74, 0.7), "stain_amount": 0.3,
		"stain_color": Color(0.6, 0.55, 0.42)}, "plaster")
	MatLib.define("l200_porcelain", {"albedo_a": Color(0.9, 0.9, 0.88), "albedo_b": Color(0.86, 0.86, 0.84), "roughness_a": 0.12, "roughness_b": 0.2}, "trim_white")
	MatLib.define("l200_metal", {"albedo_a": Color(0.6, 0.6, 0.6), "albedo_b": Color(0.5, 0.5, 0.5)}, "metal")
	MatLib.define("l200_chainlink", {"albedo_a": Color(0.45, 0.46, 0.46), "albedo_b": Color(0.4, 0.4, 0.41), "pattern": 8,
		"pattern_scale": Vector2(0.06, 0.06), "pattern_color": Color(0.2, 0.2, 0.2), "pattern_strength": 0.6, "metallic_value": 0.5}, "metal")
	MatLib.define("l200_glass", {"albedo_a": Color(0.03, 0.04, 0.05), "albedo_b": Color(0.05, 0.06, 0.07), "roughness_a": 0.04, "roughness_b": 0.1,
		"metallic_value": 0.7, "bump_strength": 0.0, "noise_scale": 0.3}, "concrete")
	MatLib.define("l200_dark", {"albedo_a": Color(0.07, 0.07, 0.07), "albedo_b": Color(0.05, 0.05, 0.05), "roughness_a": 0.5}, "trim_white")
	MatLib.define("l200_basement", {"albedo_a": Color(0.36, 0.37, 0.36), "albedo_b": Color(0.28, 0.29, 0.28), "wetness": 0.5, "stain_amount": 0.5,
		"stain_color": Color(0.2, 0.22, 0.2)}, "concrete_dark")
	MatLib.define("l200_awning", {"albedo_a": Color(0.36, 0.13, 0.11), "albedo_b": Color(0.3, 0.1, 0.09), "pattern": 2, "pattern_scale": Vector2(0.3, 1.0),
		"pattern_color": Color(0.75, 0.72, 0.66), "pattern_strength": 0.8}, "plaster")
	MatLib.define("l200_diner_floor", {"pattern": 9, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.1, 0.1, 0.1), "pattern_strength": 0.8,
		"albedo_a": Color(0.82, 0.8, 0.74), "albedo_b": Color(0.78, 0.76, 0.7), "stain_amount": 0.35}, "pool_tile")
	MatLib.define("l200_vinyl_red", {"albedo_a": Color(0.5, 0.1, 0.09), "albedo_b": Color(0.44, 0.08, 0.07), "roughness_a": 0.35}, "trim_white")
	MatLib.define("l200_formica", {"albedo_a": Color(0.78, 0.74, 0.62), "albedo_b": Color(0.72, 0.68, 0.57), "pattern": 15,
		"pattern_color": Color(0.5, 0.45, 0.38), "pattern_strength": 0.4, "roughness_a": 0.3}, "trim_white")
	MatLib.define("l200_diner_wall", {"albedo_a": Color(0.6, 0.58, 0.46), "albedo_b": Color(0.55, 0.53, 0.42), "stain_amount": 0.35,
		"stain_color": Color(0.45, 0.4, 0.28), "grime_height": 1.0, "grime_color": Color(0.35, 0.32, 0.24)}, "plaster")
	MatLib.define("l200_pipe", {"albedo_a": Color(0.3, 0.2, 0.14), "albedo_b": Color(0.2, 0.14, 0.1), "metallic_value": 0.3}, "rust")
	MatLib.define("l200_chalk", {"albedo_a": Color(0.12, 0.17, 0.14), "albedo_b": Color(0.1, 0.14, 0.12), "stain_amount": 0.4,
		"stain_color": Color(0.35, 0.38, 0.36), "stain_scale": 2.0}, "plaster")
	var coats := [Color(0.22, 0.24, 0.28), Color(0.36, 0.3, 0.24), Color(0.3, 0.32, 0.3), Color(0.42, 0.36, 0.33)]
	for i in coats.size():
		MatLib.define("l200_coat%d" % i, {"albedo_a": coats[i], "albedo_b": (coats[i] as Color) * 0.85, "noise_scale": 3.0, "roughness_a": 1.0}, "plaster")
	MatLib.define("l200_pants0", {"albedo_a": Color(0.12, 0.12, 0.14), "albedo_b": Color(0.1, 0.1, 0.11)}, "plaster")
	MatLib.define("l200_pants1", {"albedo_a": Color(0.2, 0.18, 0.16), "albedo_b": Color(0.17, 0.15, 0.13)}, "plaster")
	MatLib.define("l200_skin", {"albedo_a": Color(0.62, 0.52, 0.46), "albedo_b": Color(0.58, 0.48, 0.42), "roughness_a": 0.7}, "plaster")
	MatLib.register("l200_lamp", MatLib.panel(Color(1.0, 0.86, 0.66), 2.2))
	MatLib.register("l200_tube", MatLib.panel(Color(0.92, 0.96, 1.0), 2.4))
	MatLib.register("l200_win_lit", MatLib.panel(Color(1.0, 0.78, 0.5), 1.4))
	MatLib.register("l200_bulb", MatLib.panel(Color(1.0, 0.8, 0.55), 3.0, 0.5))


## Memory-group materials: walls and fabrics whose look is lerped between
## "unformed" (chipped, stained, colourless) and "remembered" (whole, warm).
## Returns [{mat, a0, a1, b0, b1, ...}] the level animates each frame.
static func group_materials() -> Array:
	var out: Array = []
	var walls := [[Color(0.82, 0.74, 0.58), 2, Vector2(0.09, 1.0)], [Color(0.62, 0.3, 0.28), 10, Vector2(0.32, 0.42)],
		[Color(0.66, 0.76, 0.86), 5, Vector2(0.14, 0.14)]]
	var fabs := [Color(0.42, 0.5, 0.36), Color(0.82, 0.78, 0.66), Color(0.25, 0.38, 0.62)]
	for g in 3:
		var w: Color = walls[g][0]
		var m := MatLib.define("l200_wall_g%d" % g, {"albedo_a": w, "albedo_b": w * 0.95, "pattern": walls[g][1], "pattern_scale": walls[g][2],
			"pattern_color": w * 0.78, "pattern_strength": 0.5, "peel_color": Color(0.36, 0.33, 0.29), "noise_scale": 1.0, "bump_strength": 0.4}, "plaster")
		var f := MatLib.define("l200_fab_g%d" % g, {"albedo_a": fabs[g], "albedo_b": (fabs[g] as Color) * 0.85, "noise_scale": 4.0,
			"bump_strength": 0.8, "roughness_a": 1.0}, "plaster")
		out.append({"wall": m, "fab": f, "w": w, "f": fabs[g]})
	return out


static func set_form(gm: Dictionary, form: float) -> void:
	var grey := Color(0.5, 0.49, 0.47)
	var w: Color = (gm["w"] as Color).lerp(grey, 1.0 - form)
	var m: ShaderMaterial = gm["wall"]
	m.set_shader_parameter("albedo_a", Vector3(w.r, w.g, w.b))
	m.set_shader_parameter("albedo_b", Vector3(w.r, w.g, w.b) * 0.94)
	m.set_shader_parameter("pattern_strength", lerpf(0.04, 0.5, form))
	m.set_shader_parameter("peel_amount", lerpf(0.62, 0.0, form))
	m.set_shader_parameter("stain_amount", lerpf(0.55, 0.05, form))
	m.set_shader_parameter("stain_color", Vector3(0.36, 0.33, 0.26))
	m.set_shader_parameter("grime_height", lerpf(0.9, 0.1, form))
	m.set_shader_parameter("grime_color", Vector3(0.3, 0.27, 0.22))
	var f: Color = (gm["f"] as Color).lerp(Color(0.46, 0.45, 0.44), 1.0 - form)
	(gm["fab"] as ShaderMaterial).set_shader_parameter("albedo_a", Vector3(f.r, f.g, f.b))
	(gm["fab"] as ShaderMaterial).set_shader_parameter("albedo_b", Vector3(f.r, f.g, f.b) * 0.85)


static func rot_material(seed_value: float) -> ShaderMaterial:
	if _rot_shader == null:
		_rot_shader = Shader.new()
		_rot_shader.code = ROT_SHADER
	var m := ShaderMaterial.new()
	m.shader = _rot_shader
	m.set_shader_parameter("seed", seed_value)
	return m


## A rot patch: a quad laid on a surface (centre, normal, size). Returns the
## MeshInstance3D; its material's "grow" uniform is driven by the level.
static func rot_patch(parent: Node3D, c: Vector3, n: Vector3, size: float, seed_value: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	mi.mesh = qm
	mi.material_override = rot_material(seed_value)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var up := Vector3.UP if absf(n.y) < 0.9 else Vector3.FORWARD
	mi.global_transform = Transform3D(Basis.looking_at(-n, up), c + n * 0.012)
	return mi


## Filled triangle with world-projected UVs (gable ends).
static func tri(k: GeoKit, a: Vector3, b: Vector3, c: Vector3, n: Vector3, mat: String) -> void:
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	var t := Vector3(-n.z, 0.0, n.x).normalized()
	for v in [a, b, c]:
		s["v"].append(v)
		s["n"].append(n)
		s["uv"].append(Vector2(v.dot(t), -v.y))
		s["uv2"].append(Vector2.ZERO)
	if (b - a).cross(c - a).dot(n) > 0.0:
		s["i"].append_array([base, base + 2, base + 1])
	else:
		s["i"].append_array([base, base + 1, base + 2])


static func std(c: Color, rough := 0.85) -> StandardMaterial3D:
	var key := "%s|%.2f" % [c.to_html(), rough]
	if not _std.has(key):
		_std[key] = MatLib.standard(c, rough)
	return _std[key]


static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


## A standing resident built in two halves ("L"/"R" children) so a figure can
## come apart down the middle. Faces local -Z. pose: "", "bowl", "arms".
static func figure(parent: Node3D, pos: Vector3, yaw: float, h: float, coat: Color, pants: Color, skin: Color, hair: Color, pose := "", seam := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Figure"
	parent.add_child(root)
	root.position = pos
	root.rotation.y = yaw
	var s := h / 1.75
	root.scale = Vector3.ONE * s
	var cap := CapsuleMesh.new()
	cap.radius = 0.075
	cap.height = 0.86
	var arm := CapsuleMesh.new()
	arm.radius = 0.055
	arm.height = 0.66
	var torso := BoxMesh.new()
	torso.size = Vector3(0.205, 0.62, 0.24)
	var skirt := BoxMesh.new()
	skirt.size = Vector3(0.215, 0.26, 0.26)
	var head := SphereMesh.new()
	head.radius = 0.11
	head.height = 0.25
	var neck := CylinderMesh.new()
	neck.top_radius = 0.045
	neck.bottom_radius = 0.05
	neck.height = 0.1
	var shoe := BoxMesh.new()
	shoe.size = Vector3(0.1, 0.07, 0.24)
	for side in [-1.0, 1.0]:
		var half := Node3D.new()
		half.name = "L" if side < 0.0 else "R"
		root.add_child(half)
		_part(half, cap, Vector3(side * 0.09, 0.47, 0), std(pants))
		_part(half, shoe, Vector3(side * 0.09, 0.035, -0.04), std(Color(0.08, 0.07, 0.06), 0.5))
		_part(half, torso, Vector3(side * 0.1025, 1.17, 0), std(coat))
		_part(half, skirt, Vector3(side * 0.1075, 0.88, 0), std(coat))
		var arot := Vector3(0, 0, side * 0.06)
		var apos := Vector3(side * 0.265, 1.12, 0)
		if pose == "bowl":
			arot = Vector3(1.25, 0, -side * 0.25)
			apos = Vector3(side * 0.2, 1.22, -0.2)
		_part(half, arm, apos, std(coat), arot)
		_part(half, neck, Vector3(side * 0.024, 1.52, 0), std(skin), Vector3.ZERO, Vector3(0.5, 1, 1))
		_part(half, head, Vector3(side * 0.055, 1.66, 0), std(skin, 0.6), Vector3.ZERO, Vector3(0.5, 1, 1))
		_part(half, head, Vector3(side * 0.057, 1.70, 0.012), std(hair), Vector3.ZERO, Vector3(0.53, 0.72, 1.04))
		if seam:
			var cut := BoxMesh.new()
			cut.size = Vector3(0.004, 1.2, 0.2)
			_part(half, cut, Vector3(side * 0.003, 1.2, 0), std(Color(0.09, 0.03, 0.03), 0.4))
	return root


## Cheap merged silhouette for distant crowds (GeoKit, one mesh per material).
static func kfig(k: GeoKit, p: Vector3, yaw: float, h: float, coat: String, pants: String, collide := false) -> void:
	var s := h / 1.75
	var b := Basis(Vector3.UP, yaw)
	for side in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, p + b * Vector3(side * 0.09, 0.44 * s, 0)), Vector3(0.13, 0.88, 0.15) * s, pants, GeoKit.ALL, false)
		k.box_xf(Transform3D(b, p + b * Vector3(side * 0.27, 1.12 * s, 0)), Vector3(0.1, 0.64, 0.11) * s, coat, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + b * Vector3(0, 1.05 * s, 0)), Vector3(0.43, 0.88, 0.25) * s, coat, GeoKit.ALL, false)
	k.cylinder(p + Vector3(0, 1.64 * s, 0), 0.1 * s, 0.24 * s, "l200_skin", 10, false)
	if collide:
		k.add_box_shape(Transform3D(b, p + Vector3(0, 0.9 * s, 0)), Vector3(0.5, 1.8, 0.35) * s, "concrete")
