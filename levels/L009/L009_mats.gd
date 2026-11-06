extends RefCounted
## Level 9 material presets (surface.gdshader / emissive panels), split out of
## levels/L009/L009.gd for the script size budget. Night-time suburb palette:
## wet unpainted asphalt, flagstone sidewalks, lap siding, shingles, interiors.


static func define_all() -> void:
	var asp := {"albedo_a": Color(0.085, 0.085, 0.09), "albedo_b": Color(0.055, 0.055, 0.06), "wetness": 0.9, "roughness_a": 0.5, "roughness_b": 0.85, "pattern_strength": 0.2}
	MatLib.define("l9_asphalt", asp, "asphalt")
	var lv := asp.duplicate()
	lv.merge({"stain_amount": 1.0, "stain_color": Color(0.17, 0.09, 0.04), "stain_scale": 1.9, "pattern_color": Color(0.3, 0.15, 0.05), "pattern_strength": 0.9, "wetness": 0.6}, true)
	MatLib.define("l9_asphalt_leaves", lv, "asphalt")
	MatLib.define("l9_sidewalk", {"pattern": 1, "pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.014, "grout_color": Color(0.13, 0.13, 0.12), "albedo_a": Color(0.34, 0.34, 0.32), "albedo_b": Color(0.28, 0.28, 0.27), "tile_variation": 0.12, "wetness": 0.6}, "concrete")
	MatLib.define("l9_grass", {"albedo_a": Color(0.09, 0.11, 0.05), "albedo_b": Color(0.07, 0.08, 0.04), "pattern_color": Color(0.15, 0.16, 0.08), "wetness": 0.3}, "grass")
	MatLib.define("l9_field_grass", {"albedo_a": Color(0.15, 0.15, 0.08), "albedo_b": Color(0.11, 0.11, 0.06), "pattern_color": Color(0.24, 0.22, 0.11), "pattern_strength": 0.9, "noise_scale": 0.2}, "grass")
	MatLib.define("l9_sand", {"albedo_a": Color(0.42, 0.38, 0.3), "albedo_b": Color(0.36, 0.32, 0.25), "wetness": 0.4}, "sand")
	MatLib.define("l9_paver", {"pattern": 14, "pattern_scale": Vector2(0.6, 0.3), "grout_width": 0.012, "grout_color": Color(0.2, 0.19, 0.17), "albedo_a": Color(0.5, 0.48, 0.44), "albedo_b": Color(0.43, 0.41, 0.37), "wetness": 0.35}, "concrete")
	MatLib.define("l9_driveway", {"pattern": 1, "pattern_scale": Vector2(3.0, 3.0), "grout_width": 0.012, "grout_color": Color(0.2, 0.2, 0.2), "albedo_a": Color(0.4, 0.4, 0.38), "albedo_b": Color(0.35, 0.35, 0.33), "wetness": 0.45}, "concrete")
	MatLib.define("l9_foundation", {"albedo_a": Color(0.3, 0.3, 0.29), "albedo_b": Color(0.25, 0.25, 0.24)}, "concrete")
	MatLib.define("l9_bark", {"albedo_a": Color(0.15, 0.13, 0.11), "albedo_b": Color(0.09, 0.08, 0.07), "pattern": 2, "pattern_scale": Vector2(0.07, 1.0), "pattern_color": Color(0.05, 0.04, 0.04), "pattern_strength": 0.7, "bump_strength": 2.0}, "dirt")
	MatLib.define("l9_hedge", {"albedo_a": Color(0.16, 0.14, 0.08), "albedo_b": Color(0.1, 0.09, 0.05), "bump_strength": 2.6, "noise_scale": 4.0}, "dirt")
	var sid := [Color(0.47, 0.53, 0.58), Color(0.5, 0.55, 0.46), Color(0.7, 0.66, 0.56), Color(0.56, 0.56, 0.55), Color(0.58, 0.49, 0.37), Color(0.78, 0.78, 0.74), Color(0.3, 0.37, 0.31)]
	for i in sid.size():
		var c: Color = sid[i]
		MatLib.define("l9_sid_%d" % i, {"albedo_a": c, "albedo_b": c * 0.93, "pattern": 2, "uv_rotate": 1.5708, "pattern_scale": Vector2(0.2, 1.0), "pattern_color": c * 0.6, "pattern_strength": 0.75, "roughness_a": 0.7, "roughness_b": 0.85, "noise_scale": 0.6, "grime_height": 0.5, "grime_color": c * 0.5, "stain_amount": 0.12, "stain_color": c * 0.7, "bump_strength": 0.3}, "plaster")
	for i in 3:
		var b: Color = [Color(0.45, 0.22, 0.17), Color(0.36, 0.27, 0.21), Color(0.68, 0.66, 0.62)][i]
		MatLib.define("l9_brick_%d" % i, {"albedo_a": b, "albedo_b": b * 0.85, "wetness": 0.2}, "brick")
	MatLib.define("l9_stucco_0", {"albedo_a": Color(0.72, 0.68, 0.6), "albedo_b": Color(0.65, 0.61, 0.54), "bump_strength": 1.6, "noise_scale": 3.0}, "plaster")
	MatLib.define("l9_stucco_1", {"albedo_a": Color(0.58, 0.58, 0.56), "albedo_b": Color(0.52, 0.52, 0.5), "bump_strength": 1.6, "noise_scale": 3.0}, "plaster")
	for i in 4:
		var rc: Color = [Color(0.15, 0.15, 0.16), Color(0.22, 0.17, 0.13), Color(0.09, 0.09, 0.1), Color(0.18, 0.21, 0.19)][i]
		MatLib.define("l9_roof_%d" % i, {"pattern": 14, "pattern_scale": Vector2(0.34, 0.16), "grout_width": 0.012, "grout_color": rc * 0.4, "albedo_a": rc, "albedo_b": rc * 0.85, "tile_variation": 0.1, "roughness_a": 0.85, "roughness_b": 0.95, "wetness": 0.4}, "concrete")
	for i in 5:
		var dc: Color = [Color(0.15, 0.085, 0.045), Color(0.42, 0.08, 0.07), Color(0.1, 0.13, 0.24), Color(0.05, 0.05, 0.05), Color(0.12, 0.22, 0.15)][i]
		MatLib.define("l9_door_%d" % i, {"albedo_a": dc, "albedo_b": dc * 0.9, "uv_rotate": 1.5708, "pattern_scale": Vector2(1.2, 0.18)}, "wood_floor")
	MatLib.define("l9_trim", {"albedo_a": Color(0.66, 0.66, 0.63), "albedo_b": Color(0.62, 0.62, 0.6)}, "trim_white")
	MatLib.define("l9_trim_dark", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.17, 0.17, 0.17)}, "trim_white")
	MatLib.define("l9_soffit", {"albedo_a": Color(0.32, 0.32, 0.31), "albedo_b": Color(0.29, 0.29, 0.28)}, "trim_white")
	MatLib.define("l9_glass", {"albedo_a": Color(0.012, 0.016, 0.024), "albedo_b": Color(0.018, 0.022, 0.03), "roughness_a": 0.03, "roughness_b": 0.08, "metallic_value": 0.75, "bump_strength": 0.0, "noise_scale": 0.3}, "concrete")
	MatLib.define("l9_porch_wood", {"albedo_a": Color(0.36, 0.3, 0.24), "albedo_b": Color(0.3, 0.25, 0.2), "wetness": 0.3}, "wood_floor")
	MatLib.define("l9_garage", {"albedo_a": Color(0.7, 0.7, 0.67), "albedo_b": Color(0.66, 0.66, 0.63), "pattern": 2, "uv_rotate": 1.5708, "pattern_scale": Vector2(0.53, 1.0), "pattern_color": Color(0.42, 0.42, 0.4), "pattern_strength": 0.9}, "trim_white")
	MatLib.define("l9_fence_wood", {"albedo_a": Color(0.29, 0.24, 0.18), "albedo_b": Color(0.24, 0.2, 0.15), "uv_rotate": 1.5708, "pattern_scale": Vector2(1.8, 0.14), "wetness": 0.35}, "wood_floor")
	MatLib.define("l9_metal_dark", {"albedo_a": Color(0.16, 0.17, 0.18), "albedo_b": Color(0.12, 0.12, 0.13), "metallic_value": 0.6}, "metal")
	MatLib.define("l9_pole_wood", {"albedo_a": Color(0.21, 0.16, 0.11), "albedo_b": Color(0.16, 0.12, 0.08), "pattern": 0}, "wood_floor")
	MatLib.define("l9_wire", {"albedo_a": Color(0.02, 0.02, 0.02), "albedo_b": Color(0.02, 0.02, 0.02)}, "void_black")
	MatLib.define("l9_puddle_water", {"albedo_a": Color(0.008, 0.01, 0.014), "albedo_b": Color(0.012, 0.014, 0.018), "roughness_a": 0.02, "roughness_b": 0.05, "metallic_value": 0.5, "bump_strength": 0.0}, "concrete")
	MatLib.define("l9_sign_white", {"albedo_a": Color(0.86, 0.86, 0.82), "albedo_b": Color(0.82, 0.82, 0.78), "roughness_a": 0.22, "roughness_b": 0.3}, "trim_white")
	MatLib.define("l9_sign_black", {"albedo_a": Color(0.025, 0.025, 0.025), "albedo_b": Color(0.025, 0.025, 0.025), "roughness_a": 0.5, "roughness_b": 0.6}, "void_black")
	MatLib.register("l9_lamp", MatLib.panel(Color(1.0, 0.7, 0.4), 3.4))
	MatLib.register("l9_lamp_on", MatLib.panel(Color(1.0, 0.7, 0.4), 3.4))
	MatLib.register("l9_lamp_off", MatLib.panel(Color(0.05, 0.05, 0.05), 1.0))
	MatLib.register("l9_tube_window", MatLib.panel(Color(0.95, 0.97, 1.0), 2.8))
	MatLib.register("l9_taxi", MatLib.panel(Color(0.25, 0.45, 1.0), 2.2))
	MatLib.register("l9_win_lit", MatLib.panel(Color(1.0, 0.8, 0.5), 2.2))
	MatLib.register("l9_win_cold", MatLib.panel(Color(0.7, 0.82, 1.0), 1.8))
	MatLib.define("l9_tower", {"albedo_a": Color(0.03, 0.035, 0.045), "albedo_b": Color(0.025, 0.03, 0.04)}, "concrete_dark")
	MatLib.define("l9_terminal", {"albedo_a": Color(0.5, 0.5, 0.48), "albedo_b": Color(0.44, 0.44, 0.42)}, "concrete")
	MatLib.define("l9_apart", {"albedo_a": Color(0.33, 0.3, 0.27), "albedo_b": Color(0.28, 0.26, 0.23)}, "concrete")
	for i in 3:
		MatLib.define("l9_plastic_%d" % i, {"albedo_a": [Color(0.45, 0.1, 0.08), Color(0.6, 0.48, 0.1), Color(0.12, 0.22, 0.45)][i], "roughness_a": 0.45, "roughness_b": 0.55}, "trim_white")
	# interiors
	MatLib.define("l9_wood", {"albedo_a": Color(0.42, 0.28, 0.16), "albedo_b": Color(0.36, 0.23, 0.13)}, "wood_floor")
	MatLib.define("l9_wood_dark", {"albedo_a": Color(0.24, 0.14, 0.08), "albedo_b": Color(0.19, 0.11, 0.06)}, "wood_floor")
	MatLib.define("l9_carpet_0", {"albedo_a": Color(0.5, 0.45, 0.36), "albedo_b": Color(0.44, 0.4, 0.32), "wetness": 0.0, "stain_amount": 0.05}, "l0_carpet")
	MatLib.define("l9_carpet_1", {"albedo_a": Color(0.32, 0.36, 0.41), "albedo_b": Color(0.28, 0.31, 0.36), "wetness": 0.0, "stain_amount": 0.05}, "l0_carpet")
	MatLib.define("l9_rug", {"albedo_a": Color(0.42, 0.16, 0.12), "albedo_b": Color(0.36, 0.13, 0.1), "pattern_strength": 0.6, "pattern_scale": Vector2(0.5, 0.5), "pattern_color": Color(0.7, 0.6, 0.4), "wetness": 0.0}, "l0_carpet")
	MatLib.define("l9_tile_floor", {"pattern": 9, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.2, 0.2, 0.2), "pattern_strength": 0.45, "albedo_a": Color(0.8, 0.8, 0.76), "albedo_b": Color(0.76, 0.76, 0.72)}, "pool_tile")
	MatLib.define("l9_ceiling", {"albedo_a": Color(0.78, 0.77, 0.73), "albedo_b": Color(0.75, 0.74, 0.7)}, "plaster")
	var paints := [Color(0.8, 0.78, 0.7), Color(0.74, 0.7, 0.52), Color(0.62, 0.7, 0.62), Color(0.6, 0.68, 0.76), Color(0.76, 0.66, 0.6), Color(0.6, 0.55, 0.45)]
	for i in 6:
		var p: Color = paints[i]
		MatLib.define("l9_paint_%d" % i, {"albedo_a": p, "albedo_b": p * 0.96, "pattern": 10 if i == 5 else 0, "pattern_scale": Vector2(0.32, 0.42), "pattern_color": p * 0.78, "pattern_strength": 0.6}, "plaster")
	var fabs := [Color(0.3, 0.2, 0.14), Color(0.2, 0.27, 0.4), Color(0.3, 0.36, 0.25), Color(0.55, 0.5, 0.42), Color(0.45, 0.18, 0.16), Color(0.35, 0.35, 0.37)]
	for i in 6:
		MatLib.define("l9_fab_%d" % i, {"albedo_a": fabs[i], "albedo_b": (fabs[i] as Color) * 0.85, "noise_scale": 4.0, "bump_strength": 0.8, "roughness_a": 1.0}, "plaster")
	MatLib.define("l9_sheet", {"albedo_a": Color(0.8, 0.8, 0.78), "albedo_b": Color(0.74, 0.74, 0.72), "noise_scale": 5.0}, "plaster")
	MatLib.define("l9_shade", {"albedo_a": Color(0.72, 0.66, 0.52), "albedo_b": Color(0.68, 0.62, 0.5)}, "plaster")
	MatLib.define("l9_art", {"albedo_a": Color(0.25, 0.32, 0.5), "albedo_b": Color(0.62, 0.42, 0.28), "noise_scale": 2.5, "noise_mix": 0.7}, "plaster")
	MatLib.define("l9_books", {"pattern": 2, "pattern_scale": Vector2(0.045, 1.0), "pattern_color": Color(0.32, 0.1, 0.1), "pattern_strength": 0.9, "albedo_a": Color(0.2, 0.25, 0.36), "albedo_b": Color(0.42, 0.32, 0.2), "noise_scale": 9.0}, "plaster")
	MatLib.define("l9_cabinet", {"albedo_a": Color(0.6, 0.58, 0.53), "albedo_b": Color(0.56, 0.54, 0.5)}, "trim_white")
	MatLib.define("l9_counter", {"albedo_a": Color(0.2, 0.2, 0.22), "albedo_b": Color(0.16, 0.16, 0.18), "pattern": 15, "roughness_a": 0.3, "roughness_b": 0.4}, "concrete")
	MatLib.define("l9_appliance", {"albedo_a": Color(0.84, 0.84, 0.82), "albedo_b": Color(0.8, 0.8, 0.78), "roughness_a": 0.25, "roughness_b": 0.3}, "trim_white")
	MatLib.define("l9_steel", {"albedo_a": Color(0.6, 0.6, 0.62), "albedo_b": Color(0.55, 0.55, 0.57), "roughness_a": 0.3}, "metal")
	MatLib.define("l9_screen", {"albedo_a": Color(0.01, 0.01, 0.012), "albedo_b": Color(0.01, 0.01, 0.012), "roughness_a": 0.05, "roughness_b": 0.1, "metallic_value": 0.3}, "void_black")
	MatLib.define("l9_arcade", {"albedo_a": Color(0.62, 0.5, 0.08), "albedo_b": Color(0.56, 0.45, 0.07)}, "trim_white")
