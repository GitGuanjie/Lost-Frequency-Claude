extends RefCounted
## Level 11.3 city kit: materials, streets, lots graded from the low outskirts
## to the tower core, patterned facades with crimson lit windows, the
## waterfront quay with its two bridges into the fog, the Embassy, and the
## gutted three-storey building beside the arrival alley. The layout is
## authored (fixed seed); only runtime events use the level seed.

const AVE := 10.0                       # main avenue half-width (x = 0)
const XS := [[-162.0, -118.0], [-106.0, -62.0], [-50.0, -10.0], [10.0, 50.0], [62.0, 106.0], [118.0, 162.0]]
const ZS := [[86.0, 124.0], [36.0, 74.0], [-14.0, 24.0], [-64.0, -26.0], [-114.0, -76.0], [-164.0, -126.0], [-220.0, -176.0]]
const QUAY := 150.0
const DECK_Y := 3.0
const DECK_END := 1000.0
const BRIDGES := [[0.0, 8.0], [-112.0, 5.5]]      # [axis x, half width]
const EMBASSY := Vector3(0.0, 0.0, -300.0)
const POD := 4.35                        # Embassy podium top
const GX0 := -24.5                       # gutted building lot
const GX1 := -10.0
const GZ0 := 90.0
const GZ1 := 122.0
const BASE := 0.15                       # sidewalk / ground-floor level
const ST := 3.6                          # storey height in the gutted building
const ALLEY := Vector2(-29.5, -24.5)     # arrival alley x-range

## facade grids: [sx, sy, grout]
const GRID := {"l113_fac_glass": [1.6, 3.6, 0.07], "l113_fac_bronze": [1.6, 3.6, 0.07], "l113_fac_resi": [3.0, 2.9, 0.72],
	"l113_fac_brick": [2.8, 3.0, 0.78], "l113_fac_stone": [2.0, 3.4, 0.45]}

var lvl
var r := RandomNumberGenerator.new()
var lamps: Array = []          # [pos, yaw, working]
var beacons: Array = []        # rooftop aircraft lights (blink)
var lit_windows := 0


func _init(level) -> void:
	lvl = level
	r.seed = 113011


static func materials() -> void:
	MatLib.define("l113_asphalt", {"albedo_a": Color(0.075, 0.072, 0.075), "albedo_b": Color(0.12, 0.115, 0.115), "noise_scale": 0.35,
		"wetness": 0.85, "roughness_a": 0.25, "roughness_b": 0.6, "stain_amount": 0.25, "stain_color": Color(0.03, 0.03, 0.03)}, "asphalt")
	MatLib.define("l113_pave", {"albedo_a": Color(0.22, 0.21, 0.2), "albedo_b": Color(0.27, 0.26, 0.25), "pattern": 1,
		"pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.03, "grout_color": Color(0.1, 0.1, 0.1), "wetness": 0.6, "roughness_a": 0.4,
		"stain_amount": 0.35, "stain_color": Color(0.1, 0.09, 0.08)}, "concrete")
	MatLib.define("l113_paint", {"albedo_a": Color(0.5, 0.47, 0.4), "albedo_b": Color(0.32, 0.3, 0.27), "noise_scale": 2.5, "wetness": 0.5}, "concrete")
	MatLib.define("l113_conc", {"albedo_a": Color(0.27, 0.26, 0.25), "albedo_b": Color(0.33, 0.32, 0.3), "stain_amount": 0.45,
		"stain_color": Color(0.12, 0.1, 0.09), "grime_height": 2.0, "grime_color": Color(0.1, 0.09, 0.08)}, "concrete")
	MatLib.define("l113_conc_dark", {"albedo_a": Color(0.13, 0.125, 0.125), "albedo_b": Color(0.17, 0.16, 0.16), "stain_amount": 0.3}, "concrete")
	MatLib.define("l113_conc_raw", {"albedo_a": Color(0.36, 0.35, 0.33), "albedo_b": Color(0.29, 0.28, 0.27), "pattern": 1,
		"pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.012, "grout_color": Color(0.2, 0.19, 0.18), "stain_amount": 0.55,
		"stain_color": Color(0.16, 0.12, 0.1), "grime_height": 1.2, "grime_color": Color(0.14, 0.12, 0.1)}, "concrete")
	MatLib.define("l113_gut_floor", {"albedo_a": Color(0.25, 0.24, 0.23), "albedo_b": Color(0.31, 0.3, 0.28), "stain_amount": 0.6,
		"stain_color": Color(0.11, 0.1, 0.09), "noise_scale": 0.8}, "concrete")
	MatLib.define("l113_fac_glass", {"albedo_a": Color(0.03, 0.035, 0.045), "albedo_b": Color(0.05, 0.05, 0.065), "pattern": 1,
		"pattern_scale": Vector2(1.6, 3.6), "grout_width": 0.07, "grout_color": Color(0.14, 0.14, 0.15), "tile_variation": 0.04,
		"roughness_a": 0.08, "roughness_b": 0.45, "metallic_value": 0.65, "noise_scale": 0.05, "bump_strength": 0.05}, "concrete")
	MatLib.define("l113_fac_bronze", {"albedo_a": Color(0.06, 0.04, 0.035), "albedo_b": Color(0.08, 0.055, 0.045), "pattern": 1,
		"pattern_scale": Vector2(1.6, 3.6), "grout_width": 0.07, "grout_color": Color(0.12, 0.1, 0.08), "tile_variation": 0.05,
		"roughness_a": 0.1, "roughness_b": 0.45, "metallic_value": 0.6, "noise_scale": 0.05, "bump_strength": 0.05}, "concrete")
	MatLib.define("l113_fac_resi", {"albedo_a": Color(0.02, 0.02, 0.025), "albedo_b": Color(0.045, 0.04, 0.045), "pattern": 1,
		"pattern_scale": Vector2(3.0, 2.9), "grout_width": 0.72, "grout_color": Color(0.3, 0.29, 0.27), "tile_variation": 0.04,
		"roughness_a": 0.2, "roughness_b": 0.9, "stain_amount": 0.3, "stain_color": Color(0.12, 0.1, 0.09)}, "concrete")
	MatLib.define("l113_fac_brick", {"albedo_a": Color(0.02, 0.018, 0.02), "albedo_b": Color(0.04, 0.035, 0.035), "pattern": 1,
		"pattern_scale": Vector2(2.8, 3.0), "grout_width": 0.78, "grout_color": Color(0.27, 0.12, 0.085), "tile_variation": 0.03,
		"roughness_a": 0.2, "roughness_b": 0.95, "stain_amount": 0.35, "stain_color": Color(0.1, 0.06, 0.05)}, "concrete")
	MatLib.define("l113_fac_stone", {"albedo_a": Color(0.03, 0.03, 0.035), "albedo_b": Color(0.05, 0.05, 0.055), "pattern": 1,
		"pattern_scale": Vector2(2.0, 3.4), "grout_width": 0.45, "grout_color": Color(0.38, 0.35, 0.32), "tile_variation": 0.03,
		"roughness_a": 0.15, "roughness_b": 0.85, "stain_amount": 0.3, "stain_color": Color(0.15, 0.12, 0.1)}, "concrete")
	MatLib.define("l113_shop", {"albedo_a": Color(0.02, 0.02, 0.022), "albedo_b": Color(0.035, 0.033, 0.035), "pattern": 1,
		"pattern_scale": Vector2(3.2, 4.0), "grout_width": 0.16, "grout_color": Color(0.08, 0.08, 0.085), "roughness_a": 0.1,
		"roughness_b": 0.5, "metallic_value": 0.4}, "concrete")
	MatLib.define("l113_corrug", {"albedo_a": Color(0.2, 0.21, 0.22), "albedo_b": Color(0.15, 0.15, 0.16), "pattern": 2,
		"pattern_scale": Vector2(0.16, 1.0), "pattern_color": Color(0.1, 0.1, 0.11), "pattern_strength": 0.5, "metallic_value": 0.45,
		"stain_amount": 0.5, "stain_color": Color(0.22, 0.11, 0.06), "grime_height": 1.5}, "metal")
	MatLib.define("l113_shutter", {"albedo_a": Color(0.24, 0.24, 0.25), "albedo_b": Color(0.18, 0.18, 0.19), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.09), "uv_rotate": 1.5708, "pattern_color": Color(0.1, 0.1, 0.1), "pattern_strength": 0.5,
		"metallic_value": 0.5, "stain_amount": 0.5, "stain_color": Color(0.25, 0.12, 0.06)}, "metal")
	MatLib.define("l113_steel", {"albedo_a": Color(0.1, 0.1, 0.11), "albedo_b": Color(0.14, 0.14, 0.15), "metallic_value": 0.7,
		"roughness_a": 0.35, "roughness_b": 0.6, "stain_amount": 0.3, "stain_color": Color(0.2, 0.09, 0.05)}, "metal")
	MatLib.define("l113_stone", {"albedo_a": Color(0.6, 0.56, 0.52), "albedo_b": Color(0.52, 0.48, 0.45), "pattern": 1,
		"pattern_scale": Vector2(1.6, 0.8), "grout_width": 0.02, "grout_color": Color(0.36, 0.33, 0.3), "stain_amount": 0.25,
		"stain_color": Color(0.3, 0.25, 0.22), "emission_color": Color(1.0, 0.18, 0.1), "emission_energy": 0.12}, "concrete")
	MatLib.define("l113_dome", {"albedo_a": Color(0.5, 0.48, 0.46), "albedo_b": Color(0.42, 0.4, 0.38), "pattern": 1,
		"pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.05, "grout_color": Color(0.22, 0.2, 0.19), "roughness_a": 0.5, "emission_color": Color(1.0, 0.2, 0.12), "emission_energy": 0.3}, "concrete")
	MatLib.define("l113_rubble", {"albedo_a": Color(0.3, 0.29, 0.27), "albedo_b": Color(0.2, 0.19, 0.18), "noise_scale": 3.0}, "rock")
	MatLib.register("l113_win_red", MatLib.panel(Color(1.0, 0.09, 0.05), 2.4))
	MatLib.register("l113_win_red2", MatLib.panel(Color(0.8, 0.04, 0.07), 1.3))
	MatLib.register("l113_win_pulse", MatLib.panel(Color(1.0, 0.12, 0.06), 2.0, 0.35, 3.0))
	MatLib.register("l113_lamp", MatLib.panel(Color(1.0, 0.34, 0.2), 9.0))
	MatLib.register("l113_flood", MatLib.panel(Color(1.0, 0.16, 0.1), 7.0))
	MatLib.register("l113_beacon", MatLib.panel(Color(1.0, 0.02, 0.02), 6.0))
	MatLib.register("l113_water", MatLib.water({"shallow_color": Color(0.05, 0.015, 0.015), "deep_color": Color(0.008, 0.003, 0.004),
		"absorption": 0.9, "clarity": 0.15, "wave_height": 0.06, "wave_scale": 0.25, "foam_amount": 0.0, "dark_surface": 0.85,
		"roughness_value": 0.03}))


# ------------------------------------------------------------------ ground

func ground(k: GeoKit) -> void:
	k.slab(-270, -445, 270, QUAY, 0.0, 0.6, "l113_asphalt")
	k.slab(-900, QUAY - 2.0, 900, 1400, -9.0, 1.0, "l113_conc_dark")
	# quay wall face and coping
	k.box_mm(Vector3(-174, -9.0, QUAY - 0.6), Vector3(174, -0.01, QUAY), "l113_conc_dark")
	# sidewalk plinths for every block
	for xs in XS:
		for zs in ZS:
			k.box_mm(Vector3(xs[0], 0.0, zs[0]), Vector3(xs[1], BASE, zs[1]), "l113_pave", GeoKit.PY | GeoKit.SIDES)
	# promenade along the quay, broken where the bridges begin
	var cuts := [[-174.0, -117.5], [-106.5, -8.5], [8.5, 174.0]]
	for c in cuts:
		k.box_mm(Vector3(c[0], 0.0, 136.0), Vector3(c[1], BASE, QUAY - 0.6), "l113_pave", GeoKit.PY | GeoKit.SIDES)
	# plaza before the Embassy
	k.box_mm(Vector3(-60, 0.0, -345), Vector3(60, BASE, -226), "l113_pave", GeoKit.PY | GeoKit.SIDES)
	# lane markings: avenue centre line and the waterfront road
	var z := 120.0
	while z > -220.0:
		k.box(Vector3(-0.15, 0.012, z), Vector3(0.14, 0.02, 3.0), "l113_paint", GeoKit.PY, false)
		k.box(Vector3(0.15, 0.012, z), Vector3(0.14, 0.02, 3.0), "l113_paint", GeoKit.PY, false)
		z -= 6.0
	var x := -170.0
	while x < 170.0:
		k.box(Vector3(x, 0.012, 130.0), Vector3(3.0, 0.02, 0.14), "l113_paint", GeoKit.PY, false)
		x += 7.0
	# zebra crossings where the alley meets the cross street and at the quay
	for i in 9:
		k.box(Vector3(-8.0 + i * 2.0, 0.012, 79.5), Vector3(1.0, 0.02, 4.0), "l113_paint", GeoKit.PY, false)
		k.box(Vector3(-8.0 + i * 2.0, 0.012, 130.0), Vector3(1.0, 0.02, 4.5), "l113_paint", GeoKit.PY, false)
	# quay railing with gaps at the two bridge heads
	for c in cuts:
		var a: float = c[0]
		var b: float = c[1]
		k.box(Vector3((a + b) * 0.5, BASE + 1.05, QUAY - 0.8), Vector3(b - a, 0.08, 0.08), "l113_steel", GeoKit.ALL, false)
		k.box(Vector3((a + b) * 0.5, BASE + 0.55, QUAY - 0.8), Vector3(b - a, 1.1, 0.06), "l113_steel", GeoKit.PY, true)
		var px := a + 1.0
		while px < b:
			k.box(Vector3(px, BASE + 0.55, QUAY - 0.8), Vector3(0.07, 1.1, 0.07), "l113_steel", GeoKit.SIDES, false)
			px += 2.2


# --------------------------------------------------------------- buildings

func city(k: GeoKit, lit: GeoKit) -> void:
	for i in XS.size():
		for j in ZS.size():
			var xs: Array = XS[i]
			var zs: Array = ZS[j]
			if i == 2 and j == 0:
				_start_block(k, lit)
				continue
			if j <= 1:
				_outskirts(k, lit, xs[0] + 1.5, zs[0] + 1.5, xs[1] - 1.5, zs[1] - 1.5, j)
			elif j <= 3:
				_middle(k, lit, xs[0] + 1.5, zs[0] + 1.5, xs[1] - 1.5, zs[1] - 1.5, j)
			else:
				_core(k, lit, xs[0] + 2.0, zs[0] + 2.0, xs[1] - 2.0, zs[1] - 2.0)
	# blocks flanking the Embassy plaza and the tower wall behind it
	for xs in [[-162.0, -118.0], [-106.0, -64.0], [64.0, 106.0], [118.0, 162.0]]:
		for zs in [[-290.0, -238.0], [-350.0, -302.0]]:
			k.box_mm(Vector3(xs[0], 0.0, zs[0]), Vector3(xs[1], BASE, zs[1]), "l113_pave", GeoKit.PY | GeoKit.SIDES)
			_core(k, lit, xs[0] + 2.0, zs[0] + 2.0, xs[1] - 2.0, zs[1] - 2.0)
	var x := -262.0
	while x < 262.0:
		var w := r.randf_range(38.0, 60.0)
		var x1 := minf(x + w, 262.0)
		_tower(k, lit, x, -440.0, x1, -356.0, r.randf_range(70.0, 140.0), "l113_fac_glass" if r.randf() < 0.6 else "l113_fac_resi", 0.07)
		x = x1
	# the outer ring: a continuous wall of buildings; every street ends against it
	for side in [-1.0, 1.0]:
		var z := -440.0
		while z < 176.0:
			var d := r.randf_range(34.0, 62.0)
			var z1 := minf(z + d, 176.0)
			var h := r.randf_range(18.0, 46.0) if z > 0.0 else r.randf_range(40.0, 95.0)
			var a: float = 174.0 * side
			var b: float = 262.0 * side
			var st: String = ["l113_fac_resi", "l113_fac_brick", "l113_fac_stone", "l113_fac_glass"][r.randi() % 4]
			_tower(k, lit, minf(a, b), z, maxf(a, b), z1, h, st, 0.04 if z > 0.0 else 0.07)
			if z1 > QUAY:
				k.box_mm(Vector3(minf(a, b), -9.0, maxf(z, QUAY - 0.6)), Vector3(maxf(a, b), BASE, z1), "l113_conc_dark")
			z = z1


func _outskirts(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float, j: int) -> void:
	var n := 2 if r.randf() < 0.5 else 3
	var alley := 4.5
	var w := (x1 - x0 - alley * (n - 1)) / n
	for li in n:
		var a := x0 + li * (w + alley)
		var b := a + w
		var kind := r.randi() % 3
		if r.randf() < 0.55:
			_low(k, lit, a, z0, b, z1, kind, j)
		else:
			var zm := lerpf(z0, z1, r.randf_range(0.4, 0.6))
			_low(k, lit, a, z0, b, zm, kind, j)
			_low(k, lit, a, zm, b, z1, r.randi() % 3, j)
		# some alleys are blind: a wall closes the far end (dead ends)
		if li < n - 1 and r.randf() < 0.45:
			var zc := z0 + 0.6 if r.randf() < 0.5 else z1 - 0.6
			k.box(Vector3(b + alley * 0.5, BASE + 2.5, zc), Vector3(alley, 5.0, 0.5), "l113_conc")


## Low/medium outskirts structures: 0 warehouse, 1 walk-up apartments, 2 commercial.
func _low(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float, kind: int, j: int) -> void:
	match kind:
		0:
			var h := r.randf_range(7.0, 10.0)
			k.box_mm(Vector3(x0, BASE, z0), Vector3(x1, h, z1), "l113_corrug")
			k.box_mm(Vector3(x0 - 0.15, h, z0 - 0.15), Vector3(x1 + 0.15, h + 0.5, z1 + 0.15), "l113_conc_dark", GeoKit.ALL, false)
			# roller shutters on the long street faces, a red clerestory now and then
			for zf in [z0, z1]:
				var s := 1.0 if zf == z1 else -1.0
				var x := x0 + 3.0
				while x < x1 - 3.0:
					k.box(Vector3(x, BASE + 1.7, zf + s * 0.06), Vector3(3.2, 3.4, 0.12), "l113_shutter", GeoKit.ALL, false)
					x += r.randf_range(6.0, 11.0)
				if r.randf() < 0.35:
					_lit_strip(lit, Vector3((x0 + x1) * 0.5, h - 1.6, zf + s * 0.05), Vector3(x1 - x0 - 4.0, 0.7, 0.04))
		1:
			var floors := r.randi_range(3, 5)
			var h := BASE + floors * 3.0 + 0.4
			_body(k, lit, x0, z0, x1, z1, h, "l113_fac_brick", 0.04 + j * 0.01)
			_band(k, x0, z0, x1, z1, BASE, BASE + 3.2, "l113_conc_dark")
			_roof(k, x0, z0, x1, z1, h)
		_:
			var h := BASE + r.randf_range(4.5, 8.5)
			_body(k, lit, x0, z0, x1, z1, h, "l113_fac_stone", 0.03)
			_band(k, x0, z0, x1, z1, BASE, BASE + 4.0, "l113_shop")
			k.box_mm(Vector3(x0 - 0.6, BASE + 4.0, z0 - 0.6), Vector3(x1 + 0.6, BASE + 4.3, z1 + 0.6), "l113_conc_dark", GeoKit.ALL, false)
			_roof(k, x0, z0, x1, z1, h)


func _middle(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float, j: int) -> void:
	var parts: Array = [[x0, x1]]
	if r.randf() < 0.6:
		var xm := lerpf(x0, x1, r.randf_range(0.4, 0.6))
		parts = [[x0, xm], [xm, x1]]
	for p in parts:
		var h := r.randf_range(16.0, 30.0) + (j - 2) * 8.0
		var st: String = ["l113_fac_resi", "l113_fac_brick", "l113_fac_stone", "l113_fac_bronze"][r.randi() % 4]
		_body(k, lit, p[0], z0, p[1], z1, h, st, 0.05)
		_band(k, p[0], z0, p[1], z1, BASE, BASE + 4.0, "l113_shop" if r.randf() < 0.6 else "l113_conc_dark")
		_roof(k, p[0], z0, p[1], z1, h)


func _core(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float) -> void:
	# a podium with one or two towers on it
	var ph := r.randf_range(7.0, 12.0)
	k.box_mm(Vector3(x0, BASE, z0), Vector3(x1, ph, z1), "l113_fac_stone")
	_band(k, x0, z0, x1, z1, BASE, BASE + 4.5, "l113_shop")
	var st: String = ["l113_fac_glass", "l113_fac_bronze", "l113_fac_resi", "l113_fac_glass"][r.randi() % 4]
	if r.randf() < 0.65:
		_tower(k, lit, x0 + 3.0, z0 + 3.0, x1 - 3.0, z1 - 3.0, r.randf_range(50.0, 120.0), st, 0.08)
	else:
		var zm := (z0 + z1) * 0.5
		_tower(k, lit, x0 + 3.0, z0 + 3.0, x1 - 3.0, zm - 1.5, r.randf_range(45.0, 95.0), st, 0.08)
		_tower(k, lit, x0 + 3.0, zm + 1.5, x1 - 3.0, z1 - 3.0, r.randf_range(35.0, 80.0), "l113_fac_resi", 0.06)


func _tower(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float, h: float, st: String, frac: float) -> void:
	_body(k, lit, x0, z0, x1, z1, h, st, frac)
	k.box_mm(Vector3(x0 - 0.3, h, z0 - 0.3), Vector3(x1 + 0.3, h + 1.2, z1 + 0.3), "l113_conc_dark", GeoKit.ALL, false)
	var c := Vector3((x0 + x1) * 0.5, h + 1.2, (z0 + z1) * 0.5)
	k.box(c + Vector3(0, 2.0, 0), Vector3((x1 - x0) * 0.4, 4.0, (z1 - z0) * 0.4), "l113_conc_dark", GeoKit.ALL, false)
	if h > 60.0 and r.randf() < 0.7:
		var mh := r.randf_range(8.0, 22.0)
		k.cylinder(c + Vector3(0, 4.0 + mh * 0.5, 0), 0.25, mh, "l113_steel", 6, false)
		beacons.append(c + Vector3(0, 4.0 + mh + 0.3, 0))
		lit.box(c + Vector3(0, 4.0 + mh + 0.3, 0), Vector3(0.6, 0.6, 0.6), "l113_beacon", GeoKit.ALL, false)


## A building mass with its facade grid, plus crimson lit windows on the grid.
func _body(k: GeoKit, lit: GeoKit, x0: float, z0: float, x1: float, z1: float, h: float, st: String, frac: float) -> void:
	k.box_mm(Vector3(x0, BASE, z0), Vector3(x1, h, z1), st)
	if not GRID.has(st):
		return
	var g: Array = GRID[st]
	var sx: float = g[0]
	var sy: float = g[1]
	var gw: float = g[2]
	var ww := (sx - gw * 2.0) * 0.92
	var wh := (sy - gw * 2.0) * 0.92
	var row0 := int(ceil((BASE + 4.2) / sy))
	var row1 := int(floor(h / sy)) - 1
	for f in 4:
		var along_x := f < 2
		var lo := x0 if along_x else z0
		var hi := x1 if along_x else z1
		var plane: float = [z0, z1, x0, x1][f]
		var s: float = [-1.0, 1.0, -1.0, 1.0][f]
		var c0 := int(ceil(lo / sx))
		var c1 := int(floor(hi / sx)) - 1
		for row in range(row0, row1 + 1):
			var row_lit := r.randf() < frac * 0.5
			for c in range(c0, c1 + 1):
				var on := r.randf() < (0.6 if row_lit else frac)
				if not on:
					continue
				var u := (c + 0.5) * sx
				var y := (row + 0.5) * sy
				var p := Vector3(u, y, plane + s * 0.04) if along_x else Vector3(plane + s * 0.04, y, u)
				var sz := Vector3(ww, wh, 0.02) if along_x else Vector3(0.02, wh, ww)
				var face := (GeoKit.PZ if s > 0.0 else GeoKit.NZ) if along_x else (GeoKit.PX if s > 0.0 else GeoKit.NX)
				lit.box(p, sz, "l113_win_red" if r.randf() < 0.7 else ("l113_win_red2" if r.randf() < 0.8 else "l113_win_pulse"), face, false)
				lit_windows += 1


func _lit_strip(lit: GeoKit, c: Vector3, sz: Vector3) -> void:
	lit.box(c, sz, "l113_win_red2", GeoKit.ALL, false)
	lit_windows += 1


func _band(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y0: float, y1: float, mat: String) -> void:
	k.box_mm(Vector3(x0 - 0.08, y0, z0 - 0.08), Vector3(x1 + 0.08, y1, z1 + 0.08), mat, GeoKit.SIDES, false)


func _roof(k: GeoKit, x0: float, z0: float, x1: float, z1: float, h: float) -> void:
	k.box_mm(Vector3(x0 - 0.2, h, z0 - 0.2), Vector3(x1 + 0.2, h + 0.7, z1 + 0.2), "l113_conc_dark", GeoKit.ALL, false)
	if r.randf() < 0.6:
		var c := Vector3(lerpf(x0, x1, r.randf_range(0.3, 0.7)), h, lerpf(z0, z1, r.randf_range(0.3, 0.7)))
		k.box(c + Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 2.2), "l113_steel", GeoKit.ALL, false)


# ------------------------------------------------------- the arrival block

func _start_block(k: GeoKit, lit: GeoKit) -> void:
	# west: a five-storey walk-up whose blank flank forms the alley's west wall
	_body(k, lit, -48.5, 88.0, ALLEY.x, 122.5, BASE + 15.4, "l113_fac_brick", 0.06)
	_band(k, -48.5, 88.0, ALLEY.x, 122.5, BASE, BASE + 3.2, "l113_conc_dark")
	_roof(k, -48.5, 88.0, ALLEY.x, 122.5, BASE + 15.4)
	gutted(k)


## The gutted building: three bare storeys, window holes, a dog-leg stair.
func gutted(k: GeoKit) -> void:
	var m := "l113_conc_raw"
	var wx0 := GX0 + 0.15
	var wx1 := GX1 - 0.15
	var wz0 := GZ0 + 0.15
	var wz1 := GZ1 - 0.15
	for f in 3:
		var y := BASE + f * ST
		var w_alley: Array = []
		var w_ave: Array = []
		var w_south: Array = []
		var w_north: Array = []
		if f == 0:
			w_alley = [{"at": 28.0, "w": 1.6, "h": 2.4}]
			for at in [5.0, 13.0, 21.0, 28.0]:
				w_ave.append({"at": at, "w": 4.2, "h": 3.0})
			w_south = [{"at": 4.0, "w": 2.0, "h": 1.6, "sill": 1.0}, {"at": 10.5, "w": 2.0, "h": 1.6, "sill": 1.0}]
		else:
			for at in [4.0, 10.0, 16.0, 22.0]:
				w_alley.append({"at": at, "w": 1.3, "h": 1.5, "sill": 1.0})
			for at in [3.0, 8.5, 14.0, 19.5, 25.0, 29.5]:
				w_ave.append({"at": at, "w": 2.4, "h": 1.9, "sill": 0.9})
			w_south = [{"at": 4.0, "w": 2.4, "h": 1.9, "sill": 0.9}, {"at": 10.5, "w": 2.4, "h": 1.9, "sill": 0.9}]
			w_north = [{"at": 7.0, "w": 2.4, "h": 1.9, "sill": 0.9}]
		k.wall(Vector3(wx0, y, GZ0), Vector3(wx0, y, GZ1), ST, 0.3, m, w_alley)
		k.wall(Vector3(wx1, y, GZ0), Vector3(wx1, y, GZ1), ST, 0.3, m, w_ave)
		k.wall(Vector3(GX0, y, wz1), Vector3(GX1, y, wz1), ST, 0.3, m, w_south)
		k.wall(Vector3(GX0, y, wz0), Vector3(GX1, y, wz0), ST, 0.3, m, w_north)
	# floor slabs with the two stair holes (flight 1 x[-23.55,-21.75], flight 2 x[-21.65,-19.85], z[92,97.6])
	_slab_with_hole(k, BASE + ST, -23.55, -21.75)
	_slab_with_hole(k, BASE + 2.0 * ST, -21.65, -19.85)
	k.slab(GX0, GZ0, GX1, GZ1, BASE + 3.0 * ST, 0.3, m)
	k.box_mm(Vector3(GX0 - 0.15, BASE + 3.0 * ST, GZ0 - 0.15), Vector3(GX1 + 0.15, BASE + 3.0 * ST + 0.9, GZ1 + 0.15), "l113_conc_dark", GeoKit.ALL, false)
	k.slab(GX0 + 0.3, GZ0 + 0.3, GX1 - 0.3, GZ1 - 0.3, BASE + 0.02, 0.02, "l113_gut_floor", GeoKit.PY)
	k.stairs(Vector3(-22.65, BASE, 92.0), Vector3(0, 0, 1), 1.8, ST, 20, "l113_conc_raw", 0.28)
	k.stairs(Vector3(-20.75, BASE + ST, 97.6), Vector3(0, 0, -1), 1.8, ST, 20, "l113_conc_raw", 0.28)
	# rails around the holes
	for f in [1, 2]:
		var y: float = BASE + f * ST
		var hx0 := -23.55 if f == 1 else -21.65
		var hx1 := -21.75 if f == 1 else -19.85
		k.box(Vector3(hx1 + 0.05, y + 0.5, 94.8), Vector3(0.06, 1.0, 5.6), "l113_steel")
		k.box(Vector3(hx0 - 0.05, y + 0.5, 94.8), Vector3(0.06, 1.0, 5.6), "l113_steel")
		k.box(Vector3((hx0 + hx1) * 0.5, y + 0.5, 92.0 if f == 1 else 97.65), Vector3(1.8, 1.0, 0.06), "l113_steel")
	# columns
	for z in [98.0, 106.0, 114.0]:
		k.box(Vector3(-17.25, BASE + 1.5 * ST, z), Vector3(0.5, 3.0 * ST, 0.5), m)
	# stripped partition: steel studs where the drywall used to be
	for f in 2:
		var y := BASE + f * ST
		k.box(Vector3(-17.25, y + 0.03, 110.0), Vector3(0.1, 0.06, 7.6), "l113_steel", GeoKit.ALL, false)
		k.box(Vector3(-17.25, y + ST - 0.35, 110.0), Vector3(0.1, 0.06, 7.6), "l113_steel", GeoKit.ALL, false)
		var z := 106.6
		var si := 0
		while z < 113.8:
			if si % 3 != 1 or f == 1:
				k.box(Vector3(-17.25, y + ST * 0.5 - 0.15, z), Vector3(0.09, ST - 0.36, 0.04), "l113_steel", GeoKit.ALL, false)
			z += 1.2
			si += 1
	# rubble heaps and fallen ceiling pieces
	var rr := RandomNumberGenerator.new()
	rr.seed = 1132
	for f in 3:
		var y := BASE + f * ST + 0.02
		for i in 7:
			var p := Vector3(rr.randf_range(-19.0, -11.0), y, rr.randf_range(99.0, 121.0))
			var s := Vector3(rr.randf_range(0.3, 1.4), rr.randf_range(0.08, 0.35), rr.randf_range(0.3, 1.2))
			k.box_xf(Transform3D(Basis(Vector3.UP, rr.randf() * PI), p + Vector3(0, s.y * 0.5, 0)), s, "l113_rubble", GeoKit.ALL, false)


func _slab_with_hole(k: GeoKit, y: float, hx0: float, hx1: float) -> void:
	var m := "l113_conc_raw"
	k.slab(GX0, GZ0, GX1, 92.0, y, 0.3, m)
	k.slab(GX0, 97.6, GX1, GZ1, y, 0.3, m)
	k.slab(GX0, 92.0, hx0, 97.6, y, 0.3, m)
	k.slab(hx1, 92.0, GX1, 97.6, y, 0.3, m)
	k.slab(GX0 + 0.3, 97.6, GX1 - 0.3, GZ1 - 0.3, y + 0.01, 0.01, "l113_gut_floor", GeoKit.PY)


# -------------------------------------------------------------- bridges

func bridges(k: GeoKit, lit: GeoKit) -> void:
	for bd in BRIDGES:
		var bx: float = bd[0]
		var hw: float = bd[1]
		var ramp_end := QUAY + 46.0
		k.ramp(Vector3(bx, 0.0, QUAY - 0.6), Vector3(bx, DECK_Y, ramp_end), hw * 2.0, 0.9, "l113_asphalt")
		k.slab(bx - hw, ramp_end, bx + hw, DECK_END, DECK_Y, 1.0, "l113_asphalt")
		var slope := atan2(DECK_Y, ramp_end - QUAY + 0.6)
		for s in [-1.0, 1.0]:
			var px: float = bx + s * (hw - 0.25)
			# walkway kerb and parapet on the ramp (tilted) and along the deck
			var mid := Vector3(px, DECK_Y * 0.5 + 0.55, (QUAY - 0.6 + ramp_end) * 0.5)
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, -slope), mid), Vector3(0.5, 1.1, (ramp_end - QUAY + 0.6) / cos(slope)), "l113_conc")
			k.box(Vector3(px, DECK_Y + 0.55, (ramp_end + DECK_END) * 0.5), Vector3(0.5, 1.1, DECK_END - ramp_end), "l113_conc")
			k.box(Vector3(px, DECK_Y + 1.15, (ramp_end + DECK_END) * 0.5), Vector3(0.12, 0.1, DECK_END - ramp_end), "l113_steel", GeoKit.ALL, false)
			k.box(Vector3(bx + s * (hw - 1.2), DECK_Y - 1.8, (ramp_end + DECK_END) * 0.5), Vector3(0.7, 1.6, DECK_END - ramp_end), "l113_steel", GeoKit.ALL, false)
		var z := ramp_end + 12.0
		while z < DECK_END:
			k.box(Vector3(bx, (DECK_Y - 1.0 - 9.0) * 0.5, z), Vector3(hw * 1.4, DECK_Y - 1.0 + 9.0, 3.0), "l113_conc_dark", GeoKit.ALL, false)
			z += 48.0
		# steel through-truss along both parapets: chords, posts and diagonals
		var tz := ramp_end
		while tz < DECK_END - 6.0:
			for s2 in [-1.0, 1.0]:
				var tx: float = bx + s2 * (hw + 0.15)
				k.box(Vector3(tx, DECK_Y + 3.75, tz), Vector3(0.3, 7.5, 0.3), "l113_steel", GeoKit.ALL, false)
				var dg := Basis(Vector3.RIGHT, atan2(6.0, 7.2) * (1.0 if int(tz) % 12 < 6 else -1.0))
				k.box_xf(Transform3D(dg, Vector3(tx, DECK_Y + 3.75, tz + 3.0)), Vector3(0.18, 9.3, 0.18), "l113_steel", GeoKit.ALL, false)
			tz += 6.0
		for s2 in [-1.0, 1.0]:
			k.box(Vector3(bx + s2 * (hw + 0.15), DECK_Y + 7.6, (ramp_end + DECK_END) * 0.5), Vector3(0.4, 0.4, DECK_END - ramp_end), "l113_steel", GeoKit.ALL, false)
		var cz := ramp_end + 3.0
		while cz < DECK_END:
			k.box(Vector3(bx, DECK_Y + 7.6, cz), Vector3(hw * 2.0 + 0.3, 0.25, 0.25), "l113_steel", GeoKit.ALL, false)
			cz += 12.0
		# lamp standards both sides, staggered, receding into the fog
		var lz := QUAY + 10.0
		var side := 1.0
		while lz < DECK_END:
			var y0 := DECK_Y if lz > ramp_end else DECK_Y * (lz - QUAY + 0.6) / (ramp_end - QUAY + 0.6)
			var px := bx + side * (hw - 0.25)
			k.cylinder(Vector3(px, y0 + 3.6, lz), 0.09, 6.0, "l113_steel", 6, false)
			k.box(Vector3(px - side * 0.7, y0 + 6.5, lz), Vector3(1.5, 0.1, 0.12), "l113_steel", GeoKit.ALL, false)
			var working := r.randf() < 0.8
			lit.box(Vector3(px - side * 1.35, y0 + 6.38, lz), Vector3(0.8, 0.16, 0.4), "l113_lamp" if working else "l113_steel", GeoKit.ALL, false)
			if working and lz < QUAY + 190.0:
				lamps.append([Vector3(px - side * 1.35, y0 + 6.0, lz), 0.0, true, true])
			lz += 22.0
			side = -side


# -------------------------------------------------------------- Embassy

func embassy(k: GeoKit, lit: GeoKit) -> void:
	var c := EMBASSY
	var m := "l113_stone"
	# podium with a broad flight of steps on the plaza side
	k.box_mm(Vector3(c.x - 40, BASE, c.z - 30), Vector3(c.x + 40, POD, c.z + 22), m)
	k.stairs(Vector3(c.x, BASE, c.z + 32.0), Vector3(0, 0, -1), 34.0, POD - BASE, 14, m, 0.7)
	# main hall with tall window bays
	var hy := POD + 14.0
	k.box_mm(Vector3(c.x - 32, POD, c.z - 26), Vector3(c.x + 32, hy, c.z + 12), m)
	k.box_mm(Vector3(c.x - 32.6, hy, c.z - 26.6), Vector3(c.x + 32.6, hy + 1.6, c.z + 12.6), "l113_dome", GeoKit.ALL, false)
	for i in 12:
		var x := c.x - 29.0 + i * 5.27
		if absf(x - c.x) < 14.5:
			continue
		lit.box(Vector3(x, POD + 6.5, c.z + 12.06), Vector3(1.7, 7.0, 0.04), "l113_win_red2", GeoKit.PZ, false)
	for s in [-1.0, 1.0]:
		for i in 6:
			lit.box(Vector3(c.x + s * 32.06, POD + 6.5, c.z - 22.0 + i * 6.0), Vector3(0.04, 7.0, 1.7), "l113_win_red2", GeoKit.PX if s > 0 else GeoKit.NX, false)
	# portico: eight columns, entablature and a stepped pediment
	for i in 8:
		var x := c.x - 14.0 + i * 4.0
		k.cylinder(Vector3(x, POD + 6.5, c.z + 18.5), 0.9, 13.0, m, 14)
		k.box(Vector3(x, POD + 0.3, c.z + 18.5), Vector3(2.3, 0.6, 2.3), m, GeoKit.ALL, false)
	k.box_mm(Vector3(c.x - 16, POD + 13.0, c.z + 12), Vector3(c.x + 16, POD + 15.2, c.z + 20.5), m, GeoKit.ALL, false)
	for i in 6:
		var w := 32.0 - i * 5.2
		k.box(Vector3(c.x, POD + 15.6 + i * 0.75, c.z + 19.6), Vector3(w, 0.75, 1.6), m, GeoKit.ALL, false)
	lit.box(Vector3(c.x, POD + 5.5, c.z + 12.06), Vector3(4.0, 9.0, 0.04), "l113_win_pulse", GeoKit.PZ, false)
	# drum with a ring of columns, the dome and its lantern
	var dc := Vector3(c.x, hy + 1.6, c.z - 7.0)
	k.cylinder(dc + Vector3(0, 5.0, 0), 12.0, 10.0, m, 28, false)
	for i in 20:
		var a := TAU * i / 20.0
		k.cylinder(dc + Vector3(cos(a) * 13.2, 4.5, sin(a) * 13.2), 0.45, 9.0, m, 8, false)
		lit.box(dc + Vector3(cos(a) * 12.04, 5.0, sin(a) * 12.04), Vector3(0.9, 4.2, 0.9), "l113_win_red", GeoKit.ALL, false)
	k.cylinder(dc + Vector3(0, 10.3, 0), 14.0, 0.6, m, 28, false)
	var rings := 9
	for i in rings:
		var a0 := (PI * 0.5) * i / rings
		var a1 := (PI * 0.5) * (i + 1) / rings
		var rad := 12.5 * cos((a0 + a1) * 0.5)
		var y0 := 10.6 + 12.5 * sin(a0)
		var y1 := 10.6 + 12.5 * sin(a1)
		k.cylinder(dc + Vector3(0, (y0 + y1) * 0.5, 0), rad, y1 - y0 + 0.05, "l113_dome", 28, false)
	k.cylinder(dc + Vector3(0, 25.0, 0), 2.2, 4.0, m, 12, false)
	lit.cylinder(dc + Vector3(0, 25.0, 0), 1.9, 3.2, "l113_win_red", 12, false)
	k.cylinder(dc + Vector3(0, 27.6, 0), 2.6, 0.5, "l113_dome", 12, false)
	k.cylinder(dc + Vector3(0, 29.0, 0), 0.25, 2.4, "l113_steel", 6, false)
	# floodlights at the foot of the podium washing the facade red
	for i in 6:
		var x := c.x - 30.0 + i * 12.0
		k.box(Vector3(x, BASE + 0.35, c.z + 36.0), Vector3(1.1, 0.7, 0.8), "l113_steel", GeoKit.ALL, false)
		lit.box(Vector3(x, BASE + 0.55, c.z + 35.55), Vector3(0.9, 0.4, 0.04), "l113_flood", GeoKit.ALL, false)
