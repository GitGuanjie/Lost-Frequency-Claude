extends RefCounted
## Level 58 rooms off the main Waterpark: the Corridors (rough grey concrete,
## white MDF ceiling tiles on plastic supports, noisy metal plate floors,
## scarce lights, crates, stepladders, pallets, boards and pipes, a B.N.T.G.
## border, a glowing white window, the exposed piping), one Cafe (brown wooden
## door with two grimy panes and a faded bell, broken furniture, a counter,
## an unlocked till, two vending machines with cracked touchscreens) and one
## Storeroom (grey concrete, loud fluorescents, racks, supply crates, junk and
## the crate with a red "1").

const CH := 2.7
const C1 := Rect2(30.2, -1.3, 62.0, 2.6)      # main corridor (x, z, w, d)
const C2 := Rect2(48.7, -18.0, 2.6, 16.7)     # to the Cafe
const C4 := Rect2(68.7, 1.3, 2.6, 12.7)       # to the Storeroom
const CAFE := Rect2(42.0, -30.0, 16.0, 12.0)
const STORE := Rect2(58.0, 14.0, 32.0, 26.0)
const SH := 6.0
const PIPES := Vector3(92.75, 1.1, 0.0)
const RED_CRATE := Vector3(86.6, 0.0, 37.4)

var lvl
var r := RandomNumberGenerator.new()
var store_panels: Array = []
var vending: Array = []         # front positions
var supply: Array = []          # crate positions
var till := Vector3.ZERO
var lamp_pos := Vector3.ZERO


func _init(level) -> void:
	lvl = level
	r.seed = 58158


static func materials() -> void:
	MatLib.define("l58_metal_floor", {"albedo_a": Color(0.3, 0.3, 0.31), "albedo_b": Color(0.24, 0.24, 0.25), "pattern": 1,
		"pattern_scale": Vector2(1.2, 2.4), "grout_width": 0.015, "grout_color": Color(0.1, 0.1, 0.1), "metallic_value": 0.7,
		"roughness_a": 0.45, "stain_amount": 0.5, "stain_color": Color(0.3, 0.17, 0.08)}, "metal")
	MatLib.define("l58_cwall", {"albedo_a": Color(0.36, 0.36, 0.35), "albedo_b": Color(0.28, 0.28, 0.27), "noise_scale": 3.0,
		"bump_strength": 1.2, "stain_amount": 0.4, "stain_color": Color(0.2, 0.19, 0.17), "grime_height": 0.6}, "concrete")
	MatLib.define("l58_mdf", {"albedo_a": Color(0.86, 0.85, 0.82), "albedo_b": Color(0.8, 0.79, 0.76), "pattern": 7,
		"pattern_scale": Vector2(0.6, 1.2), "grout_width": 0.02, "grout_color": Color(0.78, 0.78, 0.76), "stain_amount": 0.35,
		"stain_color": Color(0.55, 0.48, 0.35)}, "plaster")
	MatLib.define("l58_wallpaper", {"albedo_a": Color(0.36, 0.42, 0.5), "albedo_b": Color(0.34, 0.4, 0.48), "pattern": 2,
		"pattern_scale": Vector2(0.24, 1.0), "pattern_color": Color(0.72, 0.73, 0.74), "pattern_strength": 0.5, "peel_amount": 0.3,
		"peel_color": Color(0.4, 0.38, 0.33), "stain_amount": 0.5, "stain_color": Color(0.25, 0.25, 0.2)}, "plaster")
	MatLib.define("l58_checker", {"albedo_a": Color(0.85, 0.84, 0.8), "albedo_b": Color(0.8, 0.79, 0.75), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.05, 0.05, 0.05), "pattern_strength": 0.5, "grout_width": 0.005,
		"stain_amount": 0.55, "stain_color": Color(0.3, 0.27, 0.2), "wetness": 0.4}, "pool_tile")
	MatLib.define("l58_door", {"albedo_a": Color(0.2, 0.11, 0.06), "albedo_b": Color(0.16, 0.09, 0.05), "pattern": 3,
		"pattern_scale": Vector2(0.9, 0.12), "roughness_a": 0.6}, "wood_floor")
	MatLib.define("l58_counter", {"albedo_a": Color(0.32, 0.22, 0.14), "albedo_b": Color(0.26, 0.17, 0.1), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.14), "stain_amount": 0.4}, "wood_floor")
	MatLib.define("l58_crate", {"albedo_a": Color(0.55, 0.42, 0.26), "albedo_b": Color(0.48, 0.36, 0.22), "pattern": 3,
		"pattern_scale": Vector2(1.0, 0.15), "pattern_color": Color(0.3, 0.22, 0.12), "stain_amount": 0.3}, "wood_floor")
	MatLib.define("l58_vend", {"albedo_a": Color(0.2, 0.21, 0.23), "albedo_b": Color(0.17, 0.18, 0.2), "metallic_value": 0.5,
		"stain_amount": 0.4, "stain_color": Color(0.3, 0.2, 0.12)}, "metal")
	MatLib.define("l58_screen", {"albedo_a": Color(0.02, 0.025, 0.03), "albedo_b": Color(0.03, 0.035, 0.04), "roughness_a": 0.05,
		"metallic_value": 0.3}, "concrete")
	MatLib.define("l58_storefloor", {"albedo_a": Color(0.42, 0.42, 0.41), "albedo_b": Color(0.36, 0.36, 0.35), "stain_amount": 0.5,
		"stain_color": Color(0.25, 0.24, 0.22), "noise_scale": 0.5}, "concrete")
	MatLib.define("l58_fabric", {"albedo_a": Color(0.68, 0.66, 0.6), "albedo_b": Color(0.6, 0.58, 0.52), "pattern": 2,
		"pattern_scale": Vector2(0.2, 1.0), "pattern_color": Color(0.5, 0.55, 0.62), "pattern_strength": 0.3, "stain_amount": 0.5}, "plaster")
	MatLib.define("l58_pallet", {"albedo_a": Color(0.6, 0.5, 0.36), "albedo_b": Color(0.52, 0.42, 0.3)}, "wood_floor")
	MatLib.register("l58_fluoro", MatLib.panel(Color(0.95, 0.98, 1.0), 2.8))
	MatLib.register("l58_cpanel", MatLib.panel(Color(1.0, 0.96, 0.88), 2.2, 0.4, 7.0))
	MatLib.register("l58_kit_red", MatLib.standard(Color(0.7, 0.1, 0.1), 0.8))
	MatLib.register("l58_kit_blue", MatLib.standard(Color(0.1, 0.2, 0.6), 0.8))
	MatLib.register("l58_brass", MatLib.standard(Color(0.45, 0.38, 0.22), 0.6, 0.6))


func _box_room(k: GeoKit, rc: Rect2, h: float, wall: String, floor_m: String, ceil_m: String) -> void:
	k.slab(rc.position.x, rc.position.y, rc.end.x, rc.end.y, 0.0, 0.5, floor_m)
	k.slab(rc.position.x - 0.3, rc.position.y - 0.3, rc.end.x + 0.3, rc.end.y + 0.3, h + 0.3, 0.3, ceil_m)


# --------------------------------------------------------------- corridors

func corridors(k: GeoKit, lit: GeoKit) -> void:
	for rc in [C1, C2, C4]:
		_box_room(k, rc, CH, "l58_cwall", "l58_metal_floor", "l58_mdf")
	k.slab(29.6, -1.0, 30.6, 1.0, 0.0, 0.5, "l58_metal_floor")
	var z0 := C1.position.y - 0.15
	var z1 := C1.end.y + 0.15
	k.wall(Vector3(C1.position.x, 0, z0), Vector3(C1.end.x + 0.3, 0, z0), CH, 0.3, "l58_cwall", [{"at": 50.0 - C1.position.x, "w": 2.6, "h": CH}])
	k.wall(Vector3(C1.position.x, 0, z1), Vector3(C1.end.x + 0.3, 0, z1), CH, 0.3, "l58_cwall",
		[{"at": 70.0 - C1.position.x, "w": 2.6, "h": CH}, {"at": 60.0 - C1.position.x, "w": 1.2, "h": 1.0, "sill": 1.1}])
	lit.box(Vector3(60.0, 1.6, z1 + 0.5), Vector3(1.6, 1.4, 0.1), "l58_void", GeoKit.ALL, false)
	k.box(Vector3(60.0, 1.6, z1 + 0.6), Vector3(2.0, 2.0, 0.1), "l58_cwall", GeoKit.NZ, false)
	# the east end: the wall is broken open onto a nest of exposed pipes
	k.wall(Vector3(C1.end.x + 0.15, 0, z0), Vector3(C1.end.x + 0.15, 0, z1), CH, 0.3, "l58_cwall", [{"at": 1.45, "w": 1.8, "h": 2.3}])
	k.box_mm(Vector3(C1.end.x + 0.3, 0.0, -1.0), Vector3(C1.end.x + 1.6, 0.02, 1.0), "l58_metal_floor")
	k.box_mm(Vector3(C1.end.x + 1.6, 0.0, -1.2), Vector3(C1.end.x + 1.9, CH, 1.2), "l58_cwall")
	k.box_mm(Vector3(C1.end.x + 0.3, CH - 0.3, -1.2), Vector3(C1.end.x + 1.9, CH, 1.2), "l58_cwall", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(C1.end.x + 0.3, 0.0, s * 1.0 - (0.2 if s > 0 else 0.0)), Vector3(C1.end.x + 1.6, CH, s * 1.0 + (0.2 if s < 0 else 0.0)), "l58_cwall")
	for i in 5:
		k.cylinder(Vector3(C1.end.x + 1.4, CH * 0.5, -0.6 + i * 0.3), 0.06 + 0.03 * (i % 2), CH, "l58_grate", 8, false)
	for y in [0.55, 1.35, 2.15]:
		k.box(Vector3(C1.end.x + 1.1, y, 0.0), Vector3(0.14, 0.14, 1.6), "l58_grate", GeoKit.ALL, false)
	# side corridors
	k.wall(Vector3(C2.position.x - 0.15, 0, C2.position.y), Vector3(C2.position.x - 0.15, 0, C1.position.y - 0.3), CH, 0.3, "l58_cwall")
	k.wall(Vector3(C2.end.x + 0.15, 0, C2.position.y), Vector3(C2.end.x + 0.15, 0, C1.position.y - 0.3), CH, 0.3, "l58_cwall")
	k.wall(Vector3(C4.position.x - 0.15, 0, C1.end.y + 0.3), Vector3(C4.position.x - 0.15, 0, C4.end.y), CH, 0.3, "l58_cwall")
	k.wall(Vector3(C4.end.x + 0.15, 0, C1.end.y + 0.3), Vector3(C4.end.x + 0.15, 0, C4.end.y), CH, 0.3, "l58_cwall")
	# a few ceiling lights only
	for p in [Vector3(35.0, CH - 0.02, 0.0), Vector3(58.0, CH - 0.02, 0.0), Vector3(76.0, CH - 0.02, 0.0), Vector3(50.0, CH - 0.02, -11.0), Vector3(70.0, CH - 0.02, 8.0)]:
		lit.panel(p, 0.6, 1.2, "l58_cpanel", p.x, 0.5 if p.x == 58.0 else 0.0)
	# B.N.T.G. border across the corridor: pallets, boards and pipe, a gap to pass
	var bx := 82.0
	for i in 3:
		k.box(Vector3(bx, 0.07 + i * 0.15, -0.78), Vector3(0.9, 0.14, 1.05), "l58_pallet")
		k.box(Vector3(bx + 0.25, 0.85 + i * 0.5, -0.8), Vector3(0.04, 0.45, 1.0), "l58_pallet", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.22), Vector3(bx - 0.3, 1.25, -0.8)), Vector3(0.05, 2.5, 0.25), "l58_pallet", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, -0.18), Vector3(bx + 0.1, 1.2, -0.45)), Vector3(0.05, 2.4, 0.22), "l58_pallet", GeoKit.ALL, false)
	k.box(Vector3(bx, 1.0, 1.15), Vector3(0.9, 2.0, 0.3), "l58_pallet")
	k.cylinder(Vector3(bx, 1.9, 0.2), 0.05, 2.6, "l58_grate", 8, false)


# ------------------------------------------------------------------- cafe

func cafe(k: GeoKit, lit: GeoKit) -> void:
	var rc := CAFE
	_box_room(k, rc, 3.0, "l58_wallpaper", "l58_checker", "l58_mdf")
	k.wall(Vector3(rc.position.x, 0, rc.end.y + 0.15), Vector3(rc.end.x, 0, rc.end.y + 0.15), 3.0, 0.3, "l58_cwall", [{"at": 8.0, "w": 1.0, "h": 2.1}])
	k.wall(Vector3(rc.position.x, 0, rc.position.y - 0.15), Vector3(rc.end.x, 0, rc.position.y - 0.15), 3.0, 0.3, "l58_wallpaper")
	k.wall(Vector3(rc.position.x - 0.15, 0, rc.position.y), Vector3(rc.position.x - 0.15, 0, rc.end.y), 3.0, 0.3, "l58_wallpaper")
	k.wall(Vector3(rc.end.x + 0.15, 0, rc.position.y), Vector3(rc.end.x + 0.15, 0, rc.end.y), 3.0, 0.3, "l58_wallpaper")
	# the door, swung in: deep brown wood, two grimy panes, a faded bell above
	var hinge := Vector3(49.5, 0, rc.end.y - 0.05)
	var a := deg_to_rad(78.0)
	var dd := Vector3(cos(a), 0, -sin(a))
	var bas := Basis(Vector3.UP, a)
	k.box_xf(Transform3D(bas, hinge + dd * 0.5 + Vector3(0, 1.05, 0)), Vector3(1.0, 2.08, 0.05), "l58_door")
	for s in [-0.22, 0.22]:
		k.box_xf(Transform3D(bas, hinge + dd * (0.5 + s) + Vector3(0, 1.55, 0)), Vector3(0.34, 0.6, 0.06), "l58_dirtyglass", GeoKit.ALL, false)
	k.cylinder(Vector3(50.0, 2.3, rc.end.y + 0.2), 0.07, 0.12, "l58_brass", 10, false)
	k.box(Vector3(50.0, 2.38, rc.end.y + 0.24), Vector3(0.04, 0.04, 0.12), "l58_brass", GeoKit.ALL, false)
	# counter, till, vending machines behind it
	k.box_mm(Vector3(44.0, 0.0, -28.6), Vector3(54.0, 1.0, -27.7), "l58_counter")
	k.box_mm(Vector3(43.9, 1.0, -28.7), Vector3(54.1, 1.06, -27.6), "l58_counter", GeoKit.ALL, false)
	till = Vector3(47.0, 1.06, -28.15)
	for x in [46.0, 49.2]:
		var c := Vector3(x, 0.95, -29.45)
		k.box(c, Vector3(1.0, 1.9, 0.85), "l58_vend")
		k.box(c + Vector3(-0.08, 0.2, 0.43), Vector3(0.62, 0.85, 0.02), "l58_screen", GeoKit.PZ, false)
		k.box(c + Vector3(0.38, 0.1, 0.43), Vector3(0.16, 0.24, 0.03), "l58_pallet", GeoKit.PZ, false)
		for i in 4:
			k.box_xf(Transform3D(Basis(Vector3.BACK, r.randf() * PI), c + Vector3(-0.08 + r.randf_range(-0.2, 0.2), 0.2 + r.randf_range(-0.3, 0.3), 0.445)), Vector3(r.randf_range(0.15, 0.4), 0.008, 0.005), "l58_coping", GeoKit.PZ, false)
		vending.append(c + Vector3(0, 0, 1.3))
	# broken tables
	for e in [[Vector3(45.0, 0, -23.0), 0.0], [Vector3(50.5, 0, -22.0), 0.35], [Vector3(54.5, 0, -24.5), 0.0], [Vector3(47.5, 0, -20.5), 1.35]]:
		var p: Vector3 = e[0]
		var tilt: float = e[1]
		var bt := Basis(Vector3.RIGHT, tilt)
		k.box_xf(Transform3D(bt, p + bt * Vector3(0, 0.36, 0)), Vector3(0.08, 0.72, 0.08), "l58_vend", GeoKit.ALL, false)
		k.box_xf(Transform3D(bt, p + bt * Vector3(0, 0.74, 0)), Vector3(0.9, 0.04, 0.9), "l58_counter", GeoKit.ALL, tilt < 0.5)
	lit.panel(Vector3(49.0, 2.98, -24.0), 0.3, 0.3, "l58_cpanel", 3.0, 0.8)


# --------------------------------------------------------------- storeroom

func storeroom(k: GeoKit, lit: GeoKit) -> void:
	var rc := STORE
	_box_room(k, rc, SH, "l58_cwall", "l58_storefloor", "l58_cwall")
	k.wall(Vector3(rc.position.x, 0, rc.position.y - 0.15), Vector3(rc.end.x, 0, rc.position.y - 0.15), SH, 0.3, "l58_cwall", [{"at": 12.0, "w": 2.2, "h": 2.5}])
	k.wall(Vector3(rc.position.x, 0, rc.end.y + 0.15), Vector3(rc.end.x, 0, rc.end.y + 0.15), SH, 0.3, "l58_cwall")
	k.wall(Vector3(rc.position.x - 0.15, 0, rc.position.y), Vector3(rc.position.x - 0.15, 0, rc.end.y), SH, 0.3, "l58_cwall")
	k.wall(Vector3(rc.end.x + 0.15, 0, rc.position.y), Vector3(rc.end.x + 0.15, 0, rc.end.y), SH, 0.3, "l58_cwall")
	for z in [19.0, 27.0, 35.0]:
		for x in [63.0, 71.0, 79.0, 87.0]:
			lit.panel(Vector3(x, SH - 0.05, z), 0.6, 2.4, "l58_fluoro", x + z)
			store_panels.append(Vector3(x, SH - 0.4, z))
	# supply crates, the Level 1 kind, and the one with a red 1
	for p in [Vector3(61.5, 0, 37.5), Vector3(62.6, 0, 37.6), Vector3(61.9, 0.8, 37.5), Vector3(88.2, 0, 17.0), Vector3(88.2, 0, 18.0)]:
		_crate(k, p)
	supply = [Vector3(61.5, 0.8, 36.6), Vector3(62.6, 0.8, 36.6), Vector3(88.2, 0.8, 19.0)]
	_crate(k, RED_CRATE)


func _crate(k: GeoKit, p: Vector3) -> void:
	k.box(p + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), "l58_crate")
	k.box(p + Vector3(0, 0.81, 0), Vector3(0.84, 0.03, 0.84), "l58_crate", GeoKit.ALL, false)
	for s in [-0.38, 0.38]:
		k.box(p + Vector3(s, 0.4, 0), Vector3(0.06, 0.82, 0.82), "l58_pallet", GeoKit.ALL, false)
