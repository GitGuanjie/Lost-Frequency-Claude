extends RefCounted
## Level 11.2 materials (shader presets, emissive panels, glass).


static func define_all() -> void:
	MatLib.define("l112_snow", {"albedo_a": Color(0.86, 0.88, 0.92), "albedo_b": Color(0.78, 0.80, 0.85), "pattern": 13,
		"pattern_color": Color(0.70, 0.72, 0.78), "pattern_strength": 0.25, "noise_scale": 0.3, "roughness_a": 0.55,
		"roughness_b": 0.75, "bump_strength": 0.6}, "sand")
	MatLib.define("l112_road", {"albedo_a": Color(0.42, 0.42, 0.44), "albedo_b": Color(0.60, 0.61, 0.64), "pattern": 2,
		"pattern_scale": Vector2(0.55, 1.0), "pattern_color": Color(0.30, 0.30, 0.32), "pattern_strength": 0.35,
		"noise_scale": 0.5, "wetness": 0.4, "roughness_a": 0.5}, "asphalt")
	MatLib.define("l112_white", {"albedo_a": Color(0.80, 0.78, 0.73), "albedo_b": Color(0.72, 0.70, 0.66), "pattern": 1,
		"pattern_scale": Vector2(3.2, 2.9), "grout_width": 0.025, "grout_color": Color(0.55, 0.53, 0.50), "tile_variation": 0.04,
		"stain_amount": 0.35, "stain_color": Color(0.55, 0.50, 0.42), "grime_height": 1.6, "grime_color": Color(0.42, 0.38, 0.32)}, "concrete")
	MatLib.define("l112_white_trim", {"albedo_a": Color(0.84, 0.83, 0.80), "albedo_b": Color(0.8, 0.79, 0.76)}, "trim_white")
	MatLib.define("l112_orange", {"albedo_a": Color(0.86, 0.36, 0.10), "albedo_b": Color(0.74, 0.29, 0.08), "pattern": 1,
		"pattern_scale": Vector2(3.0, 2.9), "grout_width": 0.02, "grout_color": Color(0.45, 0.2, 0.08),
		"stain_amount": 0.3, "stain_color": Color(0.5, 0.25, 0.1)}, "concrete")
	MatLib.define("l112_concrete", {"albedo_a": Color(0.5, 0.49, 0.47), "albedo_b": Color(0.42, 0.41, 0.39)}, "concrete")
	MatLib.define("l112_blackmetal", {"albedo_a": Color(0.05, 0.05, 0.055), "albedo_b": Color(0.09, 0.085, 0.08),
		"metallic_value": 0.6, "roughness_a": 0.5, "roughness_b": 0.8, "stain_amount": 0.4, "stain_color": Color(0.2, 0.1, 0.05)}, "metal")
	MatLib.define("l112_dent", {"albedo_a": Color(0.45, 0.43, 0.4), "albedo_b": Color(0.3, 0.29, 0.27), "metallic_value": 0.8}, "metal")
	MatLib.define("l112_steel", {"albedo_a": Color(0.45, 0.45, 0.46), "albedo_b": Color(0.35, 0.35, 0.36)}, "metal")
	MatLib.define("l112_door", {"albedo_a": Color(0.25, 0.16, 0.1), "albedo_b": Color(0.2, 0.13, 0.08)}, "wood_floor")
	MatLib.define("l112_door_wood", {"albedo_a": Color(0.42, 0.27, 0.15), "albedo_b": Color(0.36, 0.22, 0.12), "pattern": 3,
		"pattern_scale": Vector2(0.9, 0.1)}, "wood_floor")
	MatLib.define("l112_board", {"albedo_a": Color(0.62, 0.48, 0.32), "albedo_b": Color(0.52, 0.39, 0.25), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.08)}, "wood_floor")
	MatLib.define("l112_wood", {"albedo_a": Color(0.42, 0.28, 0.17), "albedo_b": Color(0.36, 0.23, 0.14)}, "wood_floor")
	MatLib.define("l112_lino", {"albedo_a": Color(0.42, 0.36, 0.30), "albedo_b": Color(0.38, 0.32, 0.27), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.30, 0.25, 0.21), "pattern_strength": 0.4,
		"roughness_a": 0.45, "roughness_b": 0.6, "stain_amount": 0.3}, "concrete")
	MatLib.define("l112_tile", {"albedo_a": Color(0.78, 0.80, 0.78), "albedo_b": Color(0.72, 0.74, 0.72), "pattern": 1,
		"pattern_scale": Vector2(0.2, 0.2), "grout_width": 0.008, "grout_color": Color(0.5, 0.5, 0.48), "roughness_a": 0.3}, "pool_tile")
	MatLib.define("l112_wall", {"albedo_a": Color(0.82, 0.80, 0.72), "albedo_b": Color(0.76, 0.74, 0.66), "stain_amount": 0.3,
		"stain_color": Color(0.62, 0.55, 0.42), "grime_height": 0.3, "grime_color": Color(0.5, 0.45, 0.35)}, "plaster")
	MatLib.define("l112_wall_dark", {"albedo_a": Color(0.18, 0.17, 0.16), "albedo_b": Color(0.14, 0.13, 0.12)}, "plaster")
	MatLib.define("l112_dado", {"albedo_a": Color(0.18, 0.38, 0.36), "albedo_b": Color(0.15, 0.33, 0.31), "roughness_a": 0.35,
		"stain_amount": 0.3, "stain_color": Color(0.1, 0.2, 0.18)}, "plaster")
	MatLib.define("l112_ceiling", {"albedo_a": Color(0.86, 0.85, 0.80), "albedo_b": Color(0.82, 0.81, 0.76)}, "plaster")
	MatLib.define("l112_chalkboard", {"albedo_a": Color(0.08, 0.16, 0.12), "albedo_b": Color(0.1, 0.18, 0.14), "noise_scale": 3.0}, "plaster")
	MatLib.define("l112_cork", {"albedo_a": Color(0.55, 0.40, 0.25), "albedo_b": Color(0.48, 0.34, 0.2), "noise_scale": 6.0}, "plaster")
	MatLib.define("l112_fridge", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80), "roughness_a": 0.3}, "trim_white")
	MatLib.define("l112_counter", {"albedo_a": Color(0.55, 0.48, 0.36), "albedo_b": Color(0.5, 0.43, 0.32)}, "wood_floor")
	MatLib.define("l112_worktop", {"albedo_a": Color(0.7, 0.68, 0.62), "albedo_b": Color(0.66, 0.64, 0.58), "roughness_a": 0.3}, "plaster")
	MatLib.define("l112_tent", {"albedo_a": Color(0.28, 0.32, 0.22), "albedo_b": Color(0.24, 0.28, 0.19), "noise_scale": 2.0,
		"roughness_a": 0.9}, "plaster")
	MatLib.define("l112_l11_grey", {"albedo_a": Color(0.36, 0.36, 0.37), "albedo_b": Color(0.3, 0.3, 0.31), "pattern": 1,
		"pattern_scale": Vector2(1.5, 3.2), "grout_width": 0.02, "grout_color": Color(0.22, 0.22, 0.23)}, "concrete")
	MatLib.define("l112_l11_brick", {"albedo_a": Color(0.40, 0.24, 0.18), "albedo_b": Color(0.34, 0.2, 0.15)}, "brick")
	MatLib.define("l112_banner_base", {"albedo_a": Color(0.86, 0.84, 0.78), "albedo_b": Color(0.8, 0.78, 0.72), "stain_amount": 0.2}, "plaster")
	for pair in [["l112_bb_red", Color(0.78, 0.12, 0.10)], ["l112_bb_yellow", Color(0.92, 0.72, 0.12)], ["l112_bb_teal", Color(0.08, 0.55, 0.55)],
			["l112_bb_navy", Color(0.10, 0.14, 0.38)], ["l112_bb_green", Color(0.18, 0.55, 0.22)], ["l112_bb_pink", Color(0.86, 0.38, 0.58)]]:
		MatLib.define(pair[0], {"albedo_a": pair[1], "albedo_b": (pair[1] as Color).darkened(0.12), "roughness_a": 0.7, "stain_amount": 0.15}, "plaster")
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.25, 0.3, 0.35, 0.3)
	g.roughness = 0.05
	g.metallic_specular = 0.9
	MatLib.register("l112_glass", g)
	MatLib.register("l112_win_dark", MatLib.standard(Color(0.03, 0.035, 0.045), 0.15, 0.3))
	MatLib.register("l112_win_lit", MatLib.panel(Color(1.0, 0.72, 0.42), 1.6))
	MatLib.register("l112_win_stair", MatLib.panel(Color(0.7, 0.8, 0.75), 0.5))
	MatLib.register("l112_bb_hall", MatLib.panel(Color(1.0, 0.88, 0.66), 1.5))
	MatLib.register("l112_tube", MatLib.panel(Color(0.95, 0.97, 1.0), 2.6))
	MatLib.register("l112_sodium", MatLib.panel(Color(1.0, 0.6, 0.22), 6.0))
