extends Node
## Procedural material presets. All surfaces are shader-generated in-project
## (see core/graphics/shaders); no third-party textures are shipped.

const SURFACE := preload("res://core/graphics/shaders/surface.gdshader")
const WATER := preload("res://core/graphics/shaders/water.gdshader")
const PANEL := preload("res://core/graphics/shaders/emissive_panel.gdshader")

var _cache: Dictionary = {}

## name -> parameters for surface.gdshader (missing keys use shader defaults)
var PRESETS: Dictionary = {
	# ---- Level 0 "Threshold": mono-yellow wallpaper, damp carpet, acoustic tiles
	"l0_wallpaper": {"albedo_a": Color(0.74, 0.65, 0.36), "albedo_b": Color(0.66, 0.57, 0.29),
		"pattern": 8, "pattern_scale": Vector2(0.16, 0.11), "pattern_color": Color(0.58, 0.49, 0.23),
		"pattern_strength": 0.55, "stain_amount": 0.35, "stain_color": Color(0.52, 0.42, 0.20),
		"grime_height": 0.32, "grime_color": Color(0.42, 0.34, 0.16), "roughness_a": 0.82,
		"roughness_b": 0.95, "noise_scale": 0.9, "bump_strength": 0.4},
	"l0_wallpaper_pale": {"albedo_a": Color(0.87, 0.82, 0.62), "albedo_b": Color(0.82, 0.76, 0.55),
		"pattern": 2, "pattern_scale": Vector2(0.09, 1.0), "pattern_color": Color(0.80, 0.74, 0.52),
		"pattern_strength": 0.25, "stain_amount": 0.2, "grime_height": 0.25, "noise_scale": 0.8},
	"l0_carpet": {"albedo_a": Color(0.47, 0.38, 0.21), "albedo_b": Color(0.38, 0.30, 0.16),
		"pattern": 6, "pattern_scale": Vector2(1, 1), "pattern_strength": 0.0, "wetness": 0.6,
		"stain_amount": 0.3, "stain_color": Color(0.33, 0.27, 0.13), "roughness_a": 0.95,
		"roughness_b": 1.0, "noise_scale": 0.5, "bump_strength": 0.5},
	"l0_carpet_deep": {"albedo_a": Color(0.47, 0.39, 0.21), "albedo_b": Color(0.40, 0.33, 0.17),
		"pattern": 6, "wetness": 0.85, "stain_amount": 0.45, "stain_color": Color(0.28, 0.22, 0.1),
		"noise_scale": 0.6},
	"l0_ceiling": {"albedo_a": Color(0.85, 0.83, 0.72), "albedo_b": Color(0.79, 0.76, 0.64),
		"pattern": 7, "pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.014,
		"grout_color": Color(0.70, 0.68, 0.58), "stain_amount": 0.32,
		"stain_color": Color(0.62, 0.52, 0.30), "roughness_a": 0.9, "roughness_b": 1.0,
		"noise_scale": 0.7, "tile_variation": 0.03},
	"l0_red_wall": {"albedo_a": Color(0.40, 0.035, 0.03), "albedo_b": Color(0.30, 0.02, 0.02),
		"pattern": 8, "pattern_scale": Vector2(0.16, 0.11), "pattern_color": Color(0.36, 0.03, 0.03),
		"pattern_strength": 0.4, "stain_amount": 0.4, "stain_color": Color(0.25, 0.02, 0.02)},
	"l0_red_carpet": {"albedo_a": Color(0.36, 0.05, 0.04), "albedo_b": Color(0.25, 0.03, 0.03),
		"pattern": 6, "wetness": 0.95, "roughness_a": 0.6, "roughness_b": 0.8},
	"void_black": {"albedo_a": Color(0.0, 0.0, 0.0), "albedo_b": Color(0.0, 0.0, 0.0),
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 0.0},
	# ---- generic families
	"concrete": {"albedo_a": Color(0.55, 0.55, 0.53), "albedo_b": Color(0.46, 0.46, 0.44),
		"noise_scale": 1.6, "stain_amount": 0.25, "stain_color": Color(0.34, 0.33, 0.30),
		"roughness_a": 0.85, "roughness_b": 0.98, "bump_strength": 0.9},
	"concrete_dark": {"albedo_a": Color(0.32, 0.32, 0.31), "albedo_b": Color(0.24, 0.24, 0.23),
		"noise_scale": 1.6, "stain_amount": 0.3, "wetness": 0.3, "bump_strength": 1.0},
	"pool_tile": {"albedo_a": Color(0.93, 0.94, 0.93), "albedo_b": Color(0.90, 0.91, 0.90),
		"pattern": 1, "pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.006,
		"grout_color": Color(0.80, 0.82, 0.82), "roughness_a": 0.08, "roughness_b": 0.14,
		"tile_variation": 0.015, "noise_scale": 0.3, "bump_strength": 0.5},
	"plaster": {"albedo_a": Color(0.82, 0.80, 0.76), "albedo_b": Color(0.76, 0.74, 0.70),
		"noise_scale": 1.1, "roughness_a": 0.9, "roughness_b": 0.98, "bump_strength": 0.5},
	"metal": {"albedo_a": Color(0.55, 0.56, 0.58), "albedo_b": Color(0.42, 0.43, 0.45),
		"metallic_value": 0.85, "roughness_a": 0.35, "roughness_b": 0.6, "noise_scale": 2.0,
		"stain_amount": 0.2, "stain_color": Color(0.35, 0.22, 0.12)},
	"rust": {"albedo_a": Color(0.45, 0.25, 0.13), "albedo_b": Color(0.3, 0.17, 0.1),
		"metallic_value": 0.4, "roughness_a": 0.7, "roughness_b": 0.95, "noise_scale": 3.0,
		"bump_strength": 1.2},
	"wood_floor": {"albedo_a": Color(0.45, 0.30, 0.18), "albedo_b": Color(0.38, 0.25, 0.15),
		"pattern": 3, "pattern_scale": Vector2(1.2, 0.14), "grout_width": 0.004,
		"grout_color": Color(0.16, 0.10, 0.06), "roughness_a": 0.45, "roughness_b": 0.7},
	"brick": {"albedo_a": Color(0.52, 0.27, 0.20), "albedo_b": Color(0.45, 0.22, 0.17),
		"pattern": 4, "pattern_scale": Vector2(0.24, 0.075), "grout_width": 0.012,
		"grout_color": Color(0.62, 0.60, 0.55)},
	"asphalt": {"albedo_a": Color(0.16, 0.16, 0.17), "albedo_b": Color(0.11, 0.11, 0.12),
		"pattern": 15, "pattern_color": Color(0.3, 0.3, 0.3), "pattern_strength": 0.4,
		"noise_scale": 2.0, "roughness_a": 0.8, "roughness_b": 0.95, "wetness": 0.2},
	"grass": {"albedo_a": Color(0.20, 0.32, 0.12), "albedo_b": Color(0.14, 0.24, 0.09),
		"pattern": 12, "pattern_color": Color(0.30, 0.42, 0.16), "pattern_strength": 0.6,
		"noise_scale": 0.35, "roughness_a": 0.9, "roughness_b": 1.0},
	"dirt": {"albedo_a": Color(0.33, 0.25, 0.17), "albedo_b": Color(0.26, 0.19, 0.13),
		"noise_scale": 0.9, "roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 1.2},
	"sand": {"albedo_a": Color(0.82, 0.71, 0.52), "albedo_b": Color(0.74, 0.62, 0.44),
		"pattern": 13, "noise_scale": 0.4, "roughness_a": 0.92, "roughness_b": 1.0},
	"rock": {"albedo_a": Color(0.36, 0.34, 0.31), "albedo_b": Color(0.24, 0.23, 0.21),
		"pattern": 11, "pattern_color": Color(0.43, 0.40, 0.36), "pattern_strength": 0.5,
		"noise_scale": 0.8, "roughness_a": 0.8, "roughness_b": 0.97, "bump_strength": 2.0,
		"wetness": 0.25},
	"trim_white": {"albedo_a": Color(0.88, 0.87, 0.83), "albedo_b": Color(0.84, 0.83, 0.79),
		"roughness_a": 0.4, "roughness_b": 0.55, "noise_scale": 0.5},
}


func get_mat(name: String) -> Material:
	if _cache.has(name):
		return _cache[name]
	var m: Material
	if PRESETS.has(name):
		m = surface(PRESETS[name])
	else:
		match name:
			"panel":
				m = panel(Color(1.0, 0.97, 0.86), 2.4)
			"water_pool":
				m = water({})
			"glass":
				var g := StandardMaterial3D.new()
				g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				g.albedo_color = Color(0.7, 0.8, 0.85, 0.18)
				g.roughness = 0.05
				g.metallic_specular = 0.8
				m = g
			"unlit_black":
				var u := StandardMaterial3D.new()
				u.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				u.albedo_color = Color.BLACK
				m = u
			_:
				push_warning("MatLib: unknown material " + name + "; using concrete")
				m = surface(PRESETS["concrete"])
	_cache[name] = m
	return m


## Register a level-specific preset (kept in the cache under that name).
func define(name: String, params: Dictionary, base: String = "") -> Material:
	var p: Dictionary = {}
	if base != "" and PRESETS.has(base):
		p = PRESETS[base].duplicate()
	p.merge(params, true)
	var m := surface(p)
	_cache[name] = m
	return m


## Register an arbitrary material under a name usable by GeoKit.
func register(name: String, m: Material) -> Material:
	_cache[name] = m
	return m


func has_mat(name: String) -> bool:
	return _cache.has(name) or PRESETS.has(name)


func surface(params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE
	for k in params.keys():
		var v: Variant = params[k]
		if v is Color:
			v = Vector3(v.r, v.g, v.b)
		m.set_shader_parameter(k, v)
	return m


func water(params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = WATER
	for k in params.keys():
		var v: Variant = params[k]
		if v is Color:
			v = Vector3(v.r, v.g, v.b)
		m.set_shader_parameter(k, v)
	return m


func panel(color: Color, energy: float, flicker: float = 0.0, seed_value: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PANEL
	m.set_shader_parameter("color", Vector3(color.r, color.g, color.b))
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("flicker", flicker)
	m.set_shader_parameter("seed", seed_value)
	return m


func standard(color: Color, rough := 0.8, metal := 0.0, emission := Color(0, 0, 0), emission_energy := 0.0) -> StandardMaterial3D:
	var s := StandardMaterial3D.new()
	s.albedo_color = color
	s.roughness = rough
	s.metallic = metal
	if emission_energy > 0.0:
		s.emission_enabled = true
		s.emission = emission
		s.emission_energy_multiplier = emission_energy
	return s
