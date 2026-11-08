extends RefCounted
## Site 737-2, the Great Pyramid of Ilios (SOURCE: colossal Egyptian-Greek
## pyramid, carvings and reliefs, watchtowers instead of corners; upper halls up
## to 60 m high and 10 m wide; lower funerary sections of ~7,373 tombs, each a
## single name; at the core a floorless chamber into an abyss with one raised
## platform lined at intervals by walls bearing reliefs of a blindfolded figure,
## ending in a weathered tombstone with withered flowers; Entity 737/1 hangs
## beyond its end; SCARF-λ built into the lower pyramid, Sector C "Spine" holding
## the primary facility entrance).
## ADAPTATION: a stepped, hollow pyramid (7 tiers of 12 m, base 120 m, 84 m high);
## the great hall is 10 m wide and 48 m high; the tombs are sampled (one gallery
## of named niches); the Spine is an exterior blast portal with an extraction bay.

const C := Vector3(0, 0, -100)
const TIERS := 7
const TH := 12.0
const HALF0 := 60.0
const STEP := 7.0
const GY := -8.0

var L: LevelBase
var props: Node3D
var k: GeoKit
var lamps: Array = []          # [{pos, col, e}]
var names: Array = []
var bay_doors: Array = []      # [{pos, edge, label}]
var tombstone := Vector3.ZERO
var entity: Node3D
var interior_aabbs: Array = []  # AABBs counted as "inside" (refuge, dim ambient)


func _init(level: LevelBase, props_root: Node3D) -> void:
	L = level
	props = props_root


static func materials() -> void:
	MatLib.define("l737_stone", {"albedo_a": Color(0.72, 0.58, 0.38), "albedo_b": Color(0.64, 0.50, 0.32), "pattern": 4,
		"pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.02, "grout_color": Color(0.45, 0.35, 0.22), "tile_variation": 0.08,
		"roughness_a": 0.85, "roughness_b": 0.95, "stain_amount": 0.25, "stain_color": Color(0.55, 0.40, 0.18), "bump_strength": 1.0})
	MatLib.define("l737_marble", {"albedo_a": Color(0.70, 0.66, 0.60), "albedo_b": Color(0.62, 0.58, 0.52), "pattern": 1,
		"pattern_scale": Vector2(2.0, 2.0), "grout_width": 0.006, "grout_color": Color(0.6, 0.56, 0.5), "roughness_a": 0.3,
		"roughness_b": 0.45, "noise_scale": 1.2, "stain_amount": 0.2, "stain_color": Color(0.7, 0.6, 0.45)})
	MatLib.define("l737_relief", {"albedo_a": Color(0.66, 0.54, 0.36), "albedo_b": Color(0.56, 0.45, 0.29), "pattern": 10,
		"pattern_scale": Vector2(1.1, 1.1), "pattern_color": Color(0.42, 0.33, 0.2), "pattern_strength": 0.7, "roughness_a": 0.85,
		"roughness_b": 0.95, "bump_strength": 1.6})
	MatLib.define("l737_gold", {"albedo_a": Color(0.95, 0.72, 0.28), "albedo_b": Color(0.85, 0.62, 0.2), "metallic_value": 0.95,
		"roughness_a": 0.22, "roughness_b": 0.35, "noise_scale": 2.0}, "metal")
	MatLib.define("l737_pyrite", {"albedo_a": Color(0.7, 0.62, 0.38), "albedo_b": Color(0.55, 0.48, 0.28), "metallic_value": 0.7,
		"roughness_a": 0.35, "roughness_b": 0.5, "pattern": 15, "pattern_color": Color(0.4, 0.34, 0.2), "pattern_strength": 0.5}, "metal")
	MatLib.define("l737_dark", {"albedo_a": Color(0.16, 0.13, 0.10), "albedo_b": Color(0.12, 0.10, 0.08), "pattern": 4,
		"pattern_scale": Vector2(2.0, 1.0), "grout_width": 0.02, "grout_color": Color(0.06, 0.05, 0.04), "roughness_a": 0.9,
		"roughness_b": 1.0, "bump_strength": 1.0})
	MatLib.define("l737_steel", {"albedo_a": Color(0.36, 0.38, 0.40), "albedo_b": Color(0.30, 0.32, 0.34), "metallic_value": 0.8,
		"roughness_a": 0.35, "roughness_b": 0.5, "stain_amount": 0.15, "stain_color": Color(0.5, 0.4, 0.25)}, "metal")
	MatLib.define("l737_concrete", {"albedo_a": Color(0.58, 0.55, 0.50), "albedo_b": Color(0.50, 0.47, 0.42), "noise_scale": 1.6,
		"stain_amount": 0.3, "stain_color": Color(0.6, 0.48, 0.28), "bump_strength": 0.8}, "concrete")
	MatLib.define("l737_flower", {"albedo_a": Color(0.32, 0.22, 0.12), "albedo_b": Color(0.42, 0.30, 0.16), "noise_scale": 8.0,
		"noise_mix": 1.0, "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.register("l737_lamp", MatLib.panel(Color(1.0, 0.93, 0.8), 3.0))
	MatLib.register("l737_eden", MatLib.panel(Color(0.3, 0.6, 1.0), 2.2))
	MatLib.register("l737_screen", MatLib.panel(Color(0.35, 0.65, 1.0), 1.2))
	MatLib.register("l737_warn", MatLib.panel(Color(1.0, 0.55, 0.12), 1.8))


func build() -> void:
	k = L.kit("Pyramid")
	_exterior()
	_watchtowers()
	_portico()
	_hall()
	_stair()
	_gallery()
	_chamber()
	_spine()
	k.commit()


func _wall_box(mn: Vector3, mx: Vector3, mat: String, collide := true) -> void:
	k.box_mm(mn, mx, mat, GeoKit.ALL, collide)


func _exterior() -> void:
	for i in TIERS:
		var h0 := HALF0 - STEP * i
		var y0 := TH * i
		var y1 := y0 + TH
		var ops_s: Array = []
		if i == 0:
			ops_s = [{"at": h0, "w": 10.0, "h": TH}, {"at": h0 + 35.0, "w": 4.6, "h": 4.4}]
		elif i == 1:
			ops_s = [{"at": h0, "w": 10.0, "h": 4.0}]
		# south (+z) face carries the doorways; walls 3 m thick along the outer edge
		k.wall(Vector3(C.x - h0, y0, C.z + h0 - 1.5), Vector3(C.x + h0, y0, C.z + h0 - 1.5), TH, 3.0, "l737_stone", ops_s)
		k.wall(Vector3(C.x - h0, y0, C.z - h0 + 1.5), Vector3(C.x + h0, y0, C.z - h0 + 1.5), TH, 3.0, "l737_stone")
		k.wall(Vector3(C.x - h0 + 1.5, y0, C.z - h0 + 3.0), Vector3(C.x - h0 + 1.5, y0, C.z + h0 - 3.0), TH, 3.0, "l737_stone")
		k.wall(Vector3(C.x + h0 - 1.5, y0, C.z - h0 + 3.0), Vector3(C.x + h0 - 1.5, y0, C.z + h0 - 3.0), TH, 3.0, "l737_stone")
		# carved frieze band near the top of each tier, gold on the upper tiers
		var fm := "l737_gold" if i >= 4 else "l737_relief"
		for s in [-1.0, 1.0]:
			k.box(Vector3(C.x, y1 - 1.6, C.z + s * (h0 + 0.05)), Vector3(h0 * 2.0 + 0.2, 1.8, 0.2), fm, GeoKit.ALL, false)
			k.box(Vector3(C.x + s * (h0 + 0.05), y1 - 1.6, C.z), Vector3(0.2, 1.8, h0 * 2.0 + 0.2), fm, GeoKit.ALL, false)
		# terrace on top of the tier (ring between this edge and the next tier's)
		var h1 := h0 - STEP
		if i < TIERS - 1:
			for s in [-1.0, 1.0]:
				k.box_mm(Vector3(C.x - h0, y1 - 0.5, C.z + (h1 - 3.0 if s > 0 else -h0)), Vector3(C.x + h0, y1, C.z + (h0 if s > 0 else -h1 + 3.0)), "l737_stone", GeoKit.PY | GeoKit.SIDES, false)
				k.box_mm(Vector3(C.x + (h1 - 3.0 if s > 0 else -h0), y1 - 0.5, C.z - h1 + 3.0), Vector3(C.x + (h0 if s > 0 else -h1 + 3.0), y1, C.z + h1 - 3.0), "l737_stone", GeoKit.PY | GeoKit.SIDES, false)
	# the summit: a gilded pyramidion
	var top := TH * TIERS
	var hs := HALF0 - STEP * (TIERS - 1)
	k.box_mm(Vector3(C.x - hs, top - 0.5, C.z - hs), Vector3(C.x + hs, top, C.z + hs), "l737_stone", GeoKit.ALL, false)
	for j in 6:
		var w := 14.0 - j * 2.4
		k.box(Vector3(C.x, top + 1.0 + j * 2.0, C.z), Vector3(w, 2.0, w), "l737_gold", GeoKit.ALL, false)


func _watchtowers() -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(C.x + sx * HALF0, 0, C.z + sz * HALF0)
			k.cylinder(c + Vector3(0, 38.0, 0), 7.0, 76.0, "l737_stone", 20, true)
			for b in [20.0, 44.0, 68.0]:
				k.cylinder(c + Vector3(0, b, 0), 7.6, 1.6, "l737_relief", 20, false)
			k.cylinder(c + Vector3(0, 76.8, 0), 8.2, 1.6, "l737_stone", 20, false)
			for m in 12:
				var a := TAU * m / 12.0
				k.box(c + Vector3(cos(a) * 7.7, 78.6, sin(a) * 7.7), Vector3(1.6, 2.0, 1.6), "l737_stone", GeoKit.ALL, false)
			k.cylinder(c + Vector3(0, 82.0, 0), 1.2, 8.0, "l737_gold", 10, false)
			for w in 4:
				var a2 := TAU * w / 4.0 + 0.4
				k.box(c + Vector3(cos(a2) * 7.05, 56.0, sin(a2) * 7.05), Vector3(1.2, 3.2, 1.2), "unlit_black", GeoKit.ALL, false)


func _portico() -> void:
	var z := C.z + HALF0 + 6.0
	k.box_mm(Vector3(-13, 0, C.z + HALF0 - 0.5), Vector3(13, 0.6, z + 2.5), "l737_marble")
	k.stairs(Vector3(-13 + 13, 0, z + 5.5), Vector3(0, 0, -1), 26.0, 0.6, 3, "l737_marble", 1.0)
	for i in 6:
		var x := -10.0 + i * 4.0
		k.cylinder(Vector3(x, 0.6 + 8.0, z + 1.2), 0.95, 16.0, "l737_marble", 16, true)
		k.box(Vector3(x, 1.0, z + 1.2), Vector3(2.4, 0.8, 2.4), "l737_marble", GeoKit.ALL, false)
		k.box(Vector3(x, 16.3, z + 1.2), Vector3(2.4, 0.8, 2.4), "l737_marble", GeoKit.ALL, false)
	k.box_mm(Vector3(-13, 16.6, C.z + HALF0 - 1.0), Vector3(13, 19.0, z + 2.6), "l737_marble", GeoKit.ALL, false)
	k.box(Vector3(0, 18.0, z + 2.65), Vector3(25.6, 1.0, 0.1), "l737_gold", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(Basis(Vector3.BACK, s * 0.36), Vector3(s * 6.4, 21.0, z + 0.8)), Vector3(14.4, 1.0, 3.6), "l737_marble", GeoKit.ALL, false)
	k.box(Vector3(0, 20.2, z + 2.55), Vector3(16.0, 2.0, 0.12), "l737_relief", GeoKit.ALL, false)
	# side walls of the portico porch
	k.box_mm(Vector3(-13, 0.6, C.z + HALF0 - 0.5), Vector3(-12, 16.6, z - 1.0), "l737_marble")
	k.box_mm(Vector3(12, 0.6, C.z + HALF0 - 0.5), Vector3(13, 16.6, z - 1.0), "l737_marble")


func _hall() -> void:
	var z0 := C.z + HALF0           # -40, outer face
	var z1 := C.z + HALF0 - 14.0    # tunnel end
	var z2 := C.z + 32.0            # low/high split
	var z3 := C.z + 10.0            # hall end, stair head
	k.box_mm(Vector3(-5.5, -0.4, z3), Vector3(5.5, 0.0, z0), "l737_marble")
	# tunnel (through tiers 0 and 1)
	_wall_box(Vector3(-6.0, 0, z1), Vector3(-5.0, 16.0, z0 - 1.2), "l737_stone")
	_wall_box(Vector3(5.0, 0, z1), Vector3(6.0, 16.0, z0 - 1.2), "l737_stone")
	k.box_mm(Vector3(-6, 16.0, z1), Vector3(6, 17.0, z0), "l737_stone", GeoKit.NY, true)
	# great hall: 10 m wide, 30 m then 48 m high
	_wall_box(Vector3(-6.0, 0, z3), Vector3(-5.0, 48.0, z1), "l737_relief")
	_wall_box(Vector3(5.0, 0, z3), Vector3(6.0, 48.0, z1), "l737_relief")
	k.box_mm(Vector3(-6, 30.0, z2), Vector3(6, 31.0, z1), "l737_stone", GeoKit.NY, true)
	k.box_mm(Vector3(-6, 16.0, z1 - 0.5), Vector3(6, 30.0, z1), "l737_stone", GeoKit.NZ, false)
	k.box_mm(Vector3(-6, 48.0, z3), Vector3(6, 49.0, z2), "l737_stone", GeoKit.NY, true)
	k.box_mm(Vector3(-6, 30.0, z2 - 0.5), Vector3(6, 48.0, z2), "l737_stone", GeoKit.NZ, false)
	k.wall(Vector3(-6, 0, z3 - 0.5), Vector3(6, 0, z3 - 0.5), 48.0, 1.0, "l737_relief", [{"at": 6.0, "w": 10.0, "h": 12.0}])
	# engaged columns and gold frieze bands
	var z := z1 - 2.0
	while z > z3 + 1.0:
		for s in [-1.0, 1.0]:
			var hh := 30.0 if z > z2 else 48.0
			k.cylinder(Vector3(s * 4.6, hh * 0.5, z), 0.55, hh, "l737_marble", 12, true)
		z -= 4.5
	for y in [8.0, 20.0, 40.0]:
		for s in [-1.0, 1.0]:
			k.box(Vector3(s * 4.98, y, (z1 + z3) * 0.5), Vector3(0.05, 0.9, z1 - z3), "l737_gold", GeoKit.ALL, false)
	# Repository work lights left behind by the survey
	for zz in [z1 - 4.0, z2 - 4.0, z3 + 6.0]:
		for s in [-1.0, 1.0]:
			_work_light(Vector3(s * 3.6, 0, zz), -s * 70.0)
	interior_aabbs.append(AABB(Vector3(-6, -1, z3), Vector3(12, 50, z0 - z3)))


func _work_light(c: Vector3, yaw: float) -> void:
	k.cylinder(c + Vector3(0, 1.1, 0), 0.04, 2.2, "l737_steel", 6, false)
	for a in [0.0, 2.1, 4.2]:
		k.box_xf(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.5), c + Vector3(sin(a) * 0.3, 0.5, cos(a) * 0.3)), Vector3(0.03, 1.1, 0.03), "l737_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c + Vector3(0, 2.3, 0)), Vector3(0.5, 0.35, 0.25), "l737_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c + Vector3(0, 2.3, 0) + Vector3(sin(deg_to_rad(yaw)), 0, cos(deg_to_rad(yaw))) * 0.13), Vector3(0.42, 0.28, 0.02), "l737_lamp", GeoKit.ALL, false)
	lamps.append({"pos": c + Vector3(0, 3.0, 0), "col": Color(1.0, 0.9, 0.75), "e": 1.3})


func _stair() -> void:
	var zt := C.z + 10.0
	var zb := C.z - 15.0
	k.stairs(Vector3(0, GY, zb), Vector3(0, 0, 1), 10.0, -GY, 25, "l737_marble", (zt - zb) / 25.0)
	_wall_box(Vector3(-6.0, GY, zb), Vector3(-5.0, 12.0, zt), "l737_relief")
	_wall_box(Vector3(5.0, GY, zb), Vector3(6.0, 12.0, zt), "l737_relief")
	k.ramp(Vector3(0, 12.6, zt), Vector3(0, 4.6, zb), 12.0, 0.6, "l737_stone")
	k.box_mm(Vector3(-6, GY - 0.4, zb - 0.2), Vector3(6, GY, zb + 0.2), "l737_marble")
	lamps.append({"pos": Vector3(0, -2.0, zb + 10.0), "col": Color(1.0, 0.82, 0.55), "e": 1.0})
	interior_aabbs.append(AABB(Vector3(-6, GY - 1, zb), Vector3(12, 22, zt - zb)))


## The lower, funerary sections: a gallery of named tombs.
const NAMES := ["Blathyllos, son of Athenodoros", "Aegiolea, daughter of Demodocus", "Theagenes, son of Philon", "Myrrhine, daughter of Kallias",
	"Archelaos, son of Nikias", "Eurydike, daughter of Lykon", "Damon, son of Sostratos", "Phaidra, daughter of Hippias", "Kleon, son of Menippos",
	"Timaia, daughter of Ariston", "Polemon, son of Theron", "Agathe, daughter of Glaukos", "Lysandros, son of Kritias", "Xanthippe, daughter of Euphron",
	"Hermogenes, son of Diodoros", "Kallisto, daughter of Mnesikles", "Philemon, son of Antiochos", "Hegeso, daughter of Proxenos",
	"Androkles, son of Eumelos", "Thaleia, daughter of Pausanias", "Sostratos, son of Demetrios", "Melitta, daughter of Chares",
	"Euthymos, son of Hagnon", "Nikarete, daughter of Lysias", "Kephalos, son of Ktesias", "Philinna, daughter of Arkesilas",
	"Menandros, son of Aristokles", "Chrysis, daughter of Telesias"]


func _gallery() -> void:
	var z0 := C.z - 15.0
	var z1 := C.z - 23.0
	k.box_mm(Vector3(-30, GY - 0.4, z1), Vector3(30, GY, z0), "l737_dark")
	k.box_mm(Vector3(-30, GY + 6.0, z1), Vector3(30, GY + 6.6, z0), "l737_dark", GeoKit.NY, true)
	k.wall(Vector3(-30, GY, z0 + 0.4), Vector3(30, GY, z0 + 0.4), 6.0, 0.8, "l737_dark", [{"at": 30.0, "w": 10.0, "h": 6.0}])
	k.wall(Vector3(-30, GY, z1 - 0.4), Vector3(30, GY, z1 - 0.4), 6.0, 0.8, "l737_dark", [{"at": 30.0, "w": 5.0, "h": 4.2}])
	_wall_box(Vector3(-31, GY, z1 - 0.8), Vector3(-30, GY + 6.0, z0 + 0.8), "l737_dark")
	_wall_box(Vector3(30, GY, z1 - 0.8), Vector3(31, GY + 6.0, z0 + 0.8), "l737_dark")
	# niches with name stones, two rows on each long wall (skipping the openings)
	var ni := 0
	for s in [-1.0, 1.0]:
		var wz := z0 if s < 0 else z1
		var face := 1.0 if s < 0 else -1.0
		for x in range(-28, 29, 2):
			if absf(x) < (6 if s < 0 else 4):
				continue
			for row in 2:
				var y := GY + 0.9 + row * 2.2
				k.box(Vector3(x, y + 0.6, wz - face * 0.02), Vector3(1.5, 1.6, 0.04), "unlit_black", GeoKit.ALL, false)
				k.box(Vector3(x, y - 0.35, wz - face * 0.04), Vector3(1.4, 0.3, 0.06), "l737_marble", GeoKit.ALL, false)
				if (ni % 3) == 0 or absf(x) < 14:
					var nm: String = NAMES[ni % NAMES.size()]
					var lb := Label3D.new()
					lb.text = nm
					lb.font_size = 18
					lb.pixel_size = 0.004
					lb.modulate = Color(0.25, 0.2, 0.15)
					lb.position = Vector3(x, y - 0.35, wz - face * 0.08)
					lb.rotation.y = 0.0 if face < 0 else PI
					props.add_child(lb)
					names.append(nm)
				ni += 1
	for x in [-24.0, -12.0, 12.0, 24.0]:
		lamps.append({"pos": Vector3(x, GY + 4.6, (z0 + z1) * 0.5), "col": Color(1.0, 0.7, 0.42), "e": 0.75})
		k.cylinder(Vector3(x, GY + 0.5, (z0 + z1) * 0.5 - 2.4), 0.35, 1.0, "l737_stone", 10, true)
		k.cylinder(Vector3(x, GY + 1.05, (z0 + z1) * 0.5 - 2.4), 0.3, 0.1, "l737_warn", 10, false)
	interior_aabbs.append(AABB(Vector3(-31, GY - 1, z1 - 1), Vector3(62, 8, 10)))


## The core: floorless chamber over the abyss, the platform, reliefs, tombstone.
func _chamber() -> void:
	var z0 := C.z - 23.8
	var z1 := C.z - 56.0
	var top := 4.0
	_wall_box(Vector3(-17, -70, z1 - 1.0), Vector3(17, top, z1), "l737_dark")
	_wall_box(Vector3(-17, -70, z1), Vector3(-16, top, z0), "l737_dark")
	_wall_box(Vector3(16, -70, z1), Vector3(17, top, z0), "l737_dark")
	k.wall(Vector3(-16, -70, z0 + 0.4), Vector3(16, -70, z0 + 0.4), top + 70.0, 0.8, "l737_dark", [{"at": 16.0, "w": 5.0, "h": 4.2, "sill": 62.0}])
	k.box_mm(Vector3(-17, top, z1 - 1), Vector3(17, top + 1.0, z0 + 1), "l737_dark", GeoKit.NY, true)
	# the platform: 4 m wide from the entrance, widening at its end; one column into the dark
	var pend := C.z - 45.0
	var tip := C.z - 51.0
	k.box_mm(Vector3(-2, GY - 1.5, pend), Vector3(2, GY, z0 + 0.8), "l737_stone")
	k.box_mm(Vector3(-5, GY - 1.5, tip), Vector3(5, GY, pend), "l737_stone")
	k.box_mm(Vector3(-2.5, -70, pend - 2.5), Vector3(2.5, GY - 1.5, pend + 2.5), "l737_dark", GeoKit.SIDES, false)
	# walls at regular intervals along both edges, reliefs ever more intricate
	var i := 0
	var z := z0 - 3.0
	while z > pend + 1.0:
		for s in [-1.0, 1.0]:
			k.box(Vector3(s * 1.7, GY + 1.6, z), Vector3(0.5, 3.2, 1.6), "l737_relief", GeoKit.ALL, true)
			_relief(Vector3(s * 1.43, GY, z), -s, i)
		z -= 5.5
		i += 1
	# the tombstone, withered flowers
	tombstone = Vector3(0, GY, tip + 1.2)
	k.box(tombstone + Vector3(0, 1.8, 0), Vector3(2.6, 3.6, 0.8), "l737_stone", GeoKit.ALL, true)
	k.box(tombstone + Vector3(0, 3.75, 0), Vector3(2.2, 0.3, 0.7), "l737_stone", GeoKit.ALL, false)
	var lb := Label3D.new()
	lb.text = "HERE  LIES  KING\n· · · · · · · ·\nOF  EPHYRA"
	lb.font_size = 44
	lb.pixel_size = 0.005
	lb.modulate = Color(0.3, 0.24, 0.16)
	lb.position = tombstone + Vector3(0, 2.3, 0.42)
	props.add_child(lb)
	for f in 22:
		var a := L.rng.randf() * TAU
		var r := L.rng.randf_range(0.6, 1.8)
		var fp := tombstone + Vector3(cos(a) * r, 0.0, 0.7 + absf(sin(a)) * r * 0.6)
		k.cylinder(fp + Vector3(0, 0.2, 0), 0.015, 0.4, "l737_flower", 4, false)
		k.box(fp + Vector3(0, 0.42, 0), Vector3(0.12, 0.08, 0.12), "l737_flower", GeoKit.ALL, false)
	for f2 in 5:
		k.box(tombstone + Vector3(-1.2 + f2 * 0.6, 0.15, 0.9), Vector3(0.5, 0.3, 0.35), "l737_flower", GeoKit.ALL, false)
	_entity(Vector3(0, GY - 2.0, z1 + 3.5))
	# Sector B: an observation deck window high in the east wall (blue screens)
	k.box(Vector3(15.95, 0.5, C.z - 38.0), Vector3(0.1, 2.0, 8.0), "l737_screen", GeoKit.ALL, false)
	k.box(Vector3(15.9, 1.6, C.z - 38.0), Vector3(0.2, 0.2, 8.4), "l737_steel", GeoKit.ALL, false)
	k.box(Vector3(15.9, -0.6, C.z - 38.0), Vector3(0.2, 0.2, 8.4), "l737_steel", GeoKit.ALL, false)
	lamps.append({"pos": Vector3(0, GY + 3.0, z0 - 4.0), "col": Color(1.0, 0.75, 0.45), "e": 0.8})
	lamps.append({"pos": Vector3(0, GY + 3.5, tip + 3.0), "col": Color(0.45, 0.65, 1.0), "e": 1.1})
	lamps.append({"pos": Vector3(12.0, 0.5, C.z - 38.0), "col": Color(0.35, 0.6, 1.0), "e": 0.8})
	# EDEN status lights far down the chamber walls give the dark a depth
	for j in 10:
		var zz := z0 - 2.0 - j * 3.0
		for sx in [-15.9, 15.9]:
			k.box(Vector3(sx, -2.0 - (j % 4) * 5.0, zz), Vector3(0.06, 0.12, 0.5), "l737_eden", GeoKit.ALL, false)
	interior_aabbs.append(AABB(Vector3(-16, -70, z1), Vector3(32, 75, z0 - z1)))


## A relief panel of the recurring figure: large, muscular, long dreadlocks,
## blindfolded with a gold-streaked band. Detail grows with each panel.
func _relief(c: Vector3, face: float, i: int) -> void:
	var xf := Transform3D(Basis(Vector3.UP, PI * 0.5 * face), c)
	var add := func(p: Vector3, s: Vector3, m: String) -> void:
		k.box_xf(xf * Transform3D(Basis(), p), s, m, GeoKit.ALL, false)
	add.call(Vector3(0, 1.3, 0.02), Vector3(0.9, 1.3, 0.06), "l737_dark")
	add.call(Vector3(0, 2.25, 0.02), Vector3(0.36, 0.42, 0.07), "l737_dark")
	add.call(Vector3(0, 2.3, 0.06), Vector3(0.4, 0.07, 0.04), "l737_gold")
	for j in mini(2 + i, 8):
		add.call(Vector3(-0.2 + j * 0.06, 1.95, 0.05), Vector3(0.03, 0.5 + 0.03 * j, 0.03), "l737_dark")
	add.call(Vector3(-0.6, 1.5, 0.02), Vector3(0.22, 1.0, 0.06), "l737_dark")
	add.call(Vector3(0.6, 1.5, 0.02), Vector3(0.22, 1.0, 0.06), "l737_dark")
	if i >= 2:
		add.call(Vector3(0.0, 0.4, 0.04), Vector3(1.0, 0.5, 0.05), "l737_dark")
	if i >= 3:
		add.call(Vector3(-0.85, 2.6, 0.04), Vector3(0.5, 0.5, 0.05), "l737_gold")


## Entity 737/1: hung beyond the platform's end. Shown as a vast, headless
## figure in chains and EDEN cabling, half lost in darkness (non-graphic).
func _entity(c: Vector3) -> void:
	entity = Node3D.new()
	entity.name = "Entity737_1"
	entity.position = c
	props.add_child(entity)
	var skin := MatLib.standard(Color(0.16, 0.1, 0.07), 0.65)
	var parts := [["capsule", Vector3(0, 0, 0), Vector3(1.5, 3.2, 1.0)], ["capsule", Vector3(-1.1, 1.9, 0), Vector3(0.5, 2.6, 0.5)],
		["capsule", Vector3(1.1, 1.9, 0), Vector3(0.5, 2.6, 0.5)], ["capsule", Vector3(-0.4, -2.6, 0), Vector3(0.6, 2.8, 0.6)],
		["capsule", Vector3(0.4, -2.6, 0), Vector3(0.6, 2.8, 0.6)]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = (p[2] as Vector3).x * 0.5
		cm.height = (p[2] as Vector3).y
		mi.mesh = cm
		mi.material_override = skin
		mi.position = p[1]
		mi.scale.z = (p[2] as Vector3).z / (p[2] as Vector3).x
		if absf((p[1] as Vector3).x) > 0.8:
			mi.rotation.z = -0.25 * signf((p[1] as Vector3).x)
		entity.add_child(mi)
	for s in [-1.0, 1.0]:
		k.cylinder(c + Vector3(s * 1.5, 7.5, 0), 0.07, 10.0, "l737_steel", 6, false)
	for j in 3:
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.2 + j * 0.15), c + Vector3(-0.8 + j * 0.8, 1.0, -2.5)), Vector3(0.18, 0.18, 5.0), "l737_steel", GeoKit.ALL, false)
		k.box(c + Vector3(-0.8 + j * 0.8, 0.6 + j * 0.3, -0.6), Vector3(0.12, 0.12, 0.12), "l737_eden", GeoKit.ALL, false)


## SCARF-λ Sector C "Spine": the primary facility entrance, a blast portal in the
## pyramid's base with an extraction bay behind (ADAPTATION: the page lists the
## extraction levels but not how they are reached).
func _spine() -> void:
	var x := 35.0
	var z0 := C.z + HALF0
	k.box_mm(Vector3(x - 3.6, 0, z0 - 0.2), Vector3(x - 2.3, 5.6, z0 + 2.4), "l737_concrete")
	k.box_mm(Vector3(x + 2.3, 0, z0 - 0.2), Vector3(x + 3.6, 5.6, z0 + 2.4), "l737_concrete")
	k.box_mm(Vector3(x - 3.6, 4.4, z0 - 0.2), Vector3(x + 3.6, 5.6, z0 + 2.4), "l737_concrete")
	k.box_mm(Vector3(x - 2.4, -0.3, z0 - 16.0), Vector3(x + 2.4, 0.0, z0 + 2.6), "l737_concrete")
	_wall_box(Vector3(x - 2.6, 0, z0 - 16.0), Vector3(x - 2.3, 4.4, z0 - 1.5), "l737_steel")
	_wall_box(Vector3(x + 2.3, 0, z0 - 16.0), Vector3(x + 2.6, 4.4, z0 - 1.5), "l737_steel")
	k.box_mm(Vector3(x - 2.6, 4.0, z0 - 16.0), Vector3(x + 2.6, 4.4, z0 + 2.5), "l737_steel", GeoKit.NY, true)
	# the blast door, rolled half aside
	k.box(Vector3(x - 3.4, 2.2, z0 + 1.6), Vector3(2.4, 4.4, 0.5), "l737_steel", GeoKit.ALL, true)
	for j in 6:
		k.box(Vector3(x - 3.4 + (j - 2.5) * 0.4, 2.2, z0 + 1.88), Vector3(0.12, 4.0, 0.06), "l737_warn" if j % 2 == 0 else "l737_steel", GeoKit.ALL, false)
	# the bay: x-6..x+6, z0-16..z0-24
	var bz0 := z0 - 16.0
	var bz1 := z0 - 24.0
	k.box_mm(Vector3(x - 6.3, -0.3, bz1 - 0.3), Vector3(x + 6.3, 0.0, bz0), "l737_concrete")
	k.box_mm(Vector3(x - 6.3, 4.0, bz1 - 0.3), Vector3(x + 6.3, 4.4, bz0), "l737_steel", GeoKit.NY, true)
	k.wall(Vector3(x - 6.15, 0, bz0 + 0.15), Vector3(x + 6.15, 0, bz0 + 0.15), 4.4, 0.3, "l737_steel", [{"at": 6.15, "w": 4.6, "h": 4.0}])
	k.wall(Vector3(x - 6.15, 0, bz1 - 0.15), Vector3(x + 6.15, 0, bz1 - 0.15), 4.4, 0.3, "l737_steel")
	k.wall(Vector3(x - 6.15, 0, bz0), Vector3(x - 6.15, 0, bz1), 4.4, 0.3, "l737_steel")
	k.wall(Vector3(x + 6.15, 0, bz0), Vector3(x + 6.15, 0, bz1), 4.4, 0.3, "l737_steel")
	var spots := [[Vector3(x - 3.5, 0, bz1 + 0.05), 0.0, "L737>L046#1", "LEVEL 46"], [Vector3(x, 0, bz1 + 0.05), 0.0, "L737>L739#3", "LEVEL 739"],
		[Vector3(x + 3.5, 0, bz1 + 0.05), 0.0, "L737>L998#4", "LEVEL 998"]]
	for s in spots:
		var p: Vector3 = s[0]
		k.box(p + Vector3(0, 1.15, 0.05), Vector3(1.6, 2.3, 0.1), "l737_steel", GeoKit.ALL, false)
		k.box(p + Vector3(0, 2.45, 0.12), Vector3(1.8, 0.12, 0.06), "l737_warn", GeoKit.ALL, false)
		k.box(p + Vector3(0.6, 1.2, 0.12), Vector3(0.12, 0.2, 0.04), "l737_screen", GeoKit.ALL, false)
		var lb := Label3D.new()
		lb.text = "EXTRACTION\n" + str(s[3])
		lb.font_size = 40
		lb.pixel_size = 0.004
		lb.modulate = Color(0.95, 0.9, 0.8)
		lb.position = p + Vector3(0, 2.0, 0.16)
		props.add_child(lb)
		bay_doors.append({"pos": p + Vector3(0, 1.1, 0.8), "edge": s[2], "label": s[3]})
	var sign := Label3D.new()
	sign.text = "SCARF-λ  ·  SECTOR C  SPINE\nPRIMARY FACILITY ENTRANCE\nBACKROOMS ROBOTICS SECURITY"
	sign.font_size = 56
	sign.pixel_size = 0.004
	sign.modulate = Color(0.95, 0.75, 0.3)
	sign.outline_size = 8
	sign.position = Vector3(x, 5.0, z0 + 2.45)
	props.add_child(sign)
	for zz in [z0 - 4.0, z0 - 11.0]:
		k.box(Vector3(x, 3.98, zz), Vector3(0.3, 0.04, 2.4), "l737_lamp", GeoKit.ALL, false)
		lamps.append({"pos": Vector3(x, 3.4, zz), "col": Color(0.95, 0.97, 1.0), "e": 1.0})
	lamps.append({"pos": Vector3(x, 3.4, bz0 - 4.0), "col": Color(1.0, 0.7, 0.35), "e": 1.1})
	interior_aabbs.append(AABB(Vector3(x - 6.3, -1, bz1 - 0.3), Vector3(12.6, 6, z0 - bz1)))
