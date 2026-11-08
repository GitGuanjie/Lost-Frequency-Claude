extends RefCounted
## The Crimson Fortress (Zone 3). SOURCE: an enormous room; four obsidian bridge
## formations, about 4 ft wide and 1 inch thin, run to a large square platform
## supported by seemingly nothing; ~700 ft high; the crystal formation on it does not
## look like a fortress; four gates; inside it is cold; staircases and rooms; a few
## rooms hold ruby chests (cooling cloths, freezing almond water).
## ADAPTATION: the bridges are 90 m, not ~1000 ft, and the platform is 44 m square
## (not ~100,000 sq ft) so the walk stays playable; only one gate hall is enterable.

const C := preload("res://levels/L197/L197_cave.gd")
const Plan := preload("res://levels/L197/L197_plan.gd")

const BRIDGE_LEN := 90.0
const PLAT := 44.0
const Y := 7.0
const LEDGE_Z0 := -74.4
const LEDGE_Z1 := -77.4
const HALL := 16.0
const HALL_H := 9.0
const GALLERY_Y := 4.2

static func centre() -> Vector3:
	return Vector3(Plan.MOUTH.x, Y, LEDGE_Z1 - BRIDGE_LEN - PLAT * 0.5)


static func build(L, root: Node3D) -> void:
	var pc := centre()
	var k: GeoKit = L.kit("CrimsonFortress")
	var mx: float = Plan.MOUTH.x
	# the chamber wall the upper bore opens through, with a ledge
	var wz := LEDGE_Z0 - 0.6
	k.box_mm(Vector3(mx - 60.0, -60.0, wz - 1.2), Vector3(mx - 1.6, 80.0, wz), "l197_fort_rock", GeoKit.ALL, false)
	k.box_mm(Vector3(mx + 1.6, -60.0, wz - 1.2), Vector3(mx + 60.0, 80.0, wz), "l197_fort_rock", GeoKit.ALL, false)
	k.box_mm(Vector3(mx - 1.6, Y + 3.1, wz - 1.2), Vector3(mx + 1.6, 80.0, wz), "l197_fort_rock", GeoKit.ALL, false)
	k.box_mm(Vector3(mx - 1.6, -60.0, wz - 1.2), Vector3(mx + 1.6, Y - 0.05, wz), "l197_fort_rock", GeoKit.ALL, false)
	k.box_mm(Vector3(mx - 2.4, Y - 2.2, LEDGE_Z1), Vector3(mx + 2.4, Y, LEDGE_Z0), "l197_obsidian", GeoKit.ALL, true, "concrete")
	# a rough skirt of rock under the ledge so it does not read as a slab
	var acc: C.Acc = L.acc("l197_ruby")
	var r: RandomNumberGenerator = L.drng
	for i in 9:
		C.prism(acc, Vector3(mx + r.randf_range(-2.0, 2.0), Y - 0.4, r.randf_range(LEDGE_Z1, LEDGE_Z0)), Vector3(r.randf_range(-0.5, 0.5), -1, r.randf_range(-0.6, 0.2)), r.randf_range(1.5, 4.5), r.randf_range(0.2, 0.5), r.randf() * TAU)
	# four bridges: 4 ft wide, 1 inch thin
	var w := 1.22
	var t := 0.05
	k.box_mm(Vector3(mx - w * 0.5, Y - t, LEDGE_Z1 - BRIDGE_LEN - 0.2), Vector3(mx + w * 0.5, Y, LEDGE_Z1 + 0.1), "l197_obsidian", GeoKit.ALL, true, "concrete")
	k.box_mm(Vector3(mx - w * 0.5, Y - t, pc.z - PLAT * 0.5 - BRIDGE_LEN), Vector3(mx + w * 0.5, Y, pc.z - PLAT * 0.5 + 0.2), "l197_obsidian", GeoKit.ALL, true, "concrete")
	k.box_mm(Vector3(pc.x + PLAT * 0.5 - 0.2, Y - t, pc.z - w * 0.5), Vector3(pc.x + PLAT * 0.5 + BRIDGE_LEN, Y, pc.z + w * 0.5), "l197_obsidian", GeoKit.ALL, true, "concrete")
	k.box_mm(Vector3(pc.x - PLAT * 0.5 - BRIDGE_LEN, Y - t, pc.z - w * 0.5), Vector3(pc.x - PLAT * 0.5 + 0.2, Y, pc.z + w * 0.5), "l197_obsidian", GeoKit.ALL, true, "concrete")
	# the platform, on nothing
	var p0 := Vector3(pc.x - PLAT * 0.5, Y - 3.5, pc.z - PLAT * 0.5)
	k.box_mm(p0, Vector3(pc.x + PLAT * 0.5, Y, pc.z + PLAT * 0.5), "l197_obsidian", GeoKit.ALL, true, "concrete")
	for i in 30:
		var e := r.randi() % 4
		var u := r.randf_range(-0.48, 0.48) * PLAT
		var bp := pc + (Vector3(u, -3.3, PLAT * 0.48 * (1 if e == 0 else -1)) if e < 2 else Vector3(PLAT * 0.48 * (1 if e == 2 else -1), -3.3, u))
		C.prism(acc, bp, Vector3(r.randf_range(-0.4, 0.4), -1, r.randf_range(-0.4, 0.4)), r.randf_range(2.0, 9.0), r.randf_range(0.4, 1.2), r.randf() * TAU)
	_hall(L, k, pc)
	# the formation: huge rubies heaped round the hall, leaving the four gates clear
	for i in 46:
		var ang := r.randf() * TAU
		var gate := false
		for g in 4:
			if absf(wrapf(ang - TAU * g / 4.0, -PI, PI)) < 0.33:
				gate = true
		if gate:
			continue
		var rr := r.randf_range(HALL * 0.42, HALL * 0.75)
		var base := pc + Vector3(cos(ang) * rr, -0.2, sin(ang) * rr)
		var out := Vector3(cos(ang) * r.randf_range(0.05, 0.6), 1.0, sin(ang) * r.randf_range(0.05, 0.6)).normalized()
		C.prism(acc, base, out, r.randf_range(9.0, 30.0), r.randf_range(1.3, 3.2), r.randf() * TAU, 0.22)
	for i in 10:
		var ang := r.randf() * TAU
		C.prism(acc, pc + Vector3(cos(ang) * 2.0, HALL_H - 0.5, sin(ang) * 2.0), Vector3(cos(ang) * 0.3, 1, sin(ang) * 0.3), r.randf_range(14.0, 34.0), r.randf_range(2.0, 3.6), r.randf() * TAU, 0.2)
	k.commit()
	# light: the formation glows; the chamber is lost in red haze
	L.lights.add_anchor(pc + Vector3(0, 14.0, HALL * 0.6), Color(1.0, 0.18, 0.1), 4.0, 30.0, 0.0, "fortress")
	L.lights.add_anchor(Vector3(mx, Y + 3.0, LEDGE_Z1 - 4.0), Color(1.0, 0.2, 0.12), 1.4, 12.0, 0.0, "fortress")
	for i in 4:
		L.lights.add_anchor(Vector3(mx + (3.0 if i % 2 == 0 else -3.0), Y - 4.0, LEDGE_Z1 - BRIDGE_LEN * (0.15 + 0.23 * i)), Color(1.0, 0.16, 0.1), 2.2, 16.0, 0.0, "fortress")


## One enterable gate hall: cold inside, a stair to a gallery, doors to dark rooms, a chest.
static func _hall(L, k: GeoKit, pc: Vector3) -> void:
	var h := HALL * 0.5
	var y0 := Y
	var mat := "l197_fort_wall"
	# four walls with a gate each (north gate faces the bridge from the ledge)
	for side in 4:
		var a: Vector3
		var b: Vector3
		match side:
			0: a = Vector3(-h, 0, h); b = Vector3(h, 0, h)
			1: a = Vector3(h, 0, -h); b = Vector3(-h, 0, -h)
			2: a = Vector3(h, 0, h); b = Vector3(h, 0, -h)
			_: a = Vector3(-h, 0, -h); b = Vector3(-h, 0, h)
		k.wall(pc + a, pc + b, HALL_H, 0.8, mat, [{"at": HALL * 0.5, "w": 3.2, "h": 3.6, "sill": 0.0}])
	k.box_mm(pc + Vector3(-h - 0.4, HALL_H, -h - 0.4), pc + Vector3(h + 0.4, HALL_H + 0.8, h + 0.4), mat)
	# gallery along the south wall at +4.2 m, reached by a stair along the west wall
	k.box_mm(pc + Vector3(-h + 0.4, GALLERY_Y - 0.35, -h + 0.4), pc + Vector3(h - 0.4, GALLERY_Y, -h + 3.4), "l197_obsidian", GeoKit.ALL, true, "concrete")
	k.box_mm(pc + Vector3(-h + 0.4, GALLERY_Y, -h + 3.3), pc + Vector3(1.4, GALLERY_Y + 1.0, -h + 3.45), "l197_obsidian")
	k.box_mm(pc + Vector3(3.6, GALLERY_Y, -h + 3.3), pc + Vector3(h - 0.4, GALLERY_Y + 1.0, -h + 3.45), "l197_obsidian")
	# a free-standing stair up the middle of the hall to the gallery
	k.stairs(pc + Vector3(2.5, 0.0, -h + 3.4 + 0.28 * 23), Vector3(0, 0, -1), 1.6, GALLERY_Y, 23, "l197_obsidian", 0.28)
	# doorways to rooms beyond (dark; something waits in them)
	for dz in [-4.6, 4.6]:
		k.box_mm(pc + Vector3(h - 0.45, 0.0, dz - 0.75), pc + Vector3(h - 0.4, 2.4, dz + 0.75), "unlit_black", GeoKit.NX, false)
		L.room_doors.append(pc + Vector3(h - 0.8, 1.2, dz))
	# the ruby chest on the gallery
	var cp: Vector3 = pc + Vector3(2.0, GALLERY_Y, -h + 1.4)
	k.box(cp + Vector3(0, 0.3, 0), Vector3(1.1, 0.6, 0.65), "l197_ruby_solid", GeoKit.ALL, true)
	k.box(cp + Vector3(0, 0.66, 0), Vector3(1.16, 0.12, 0.7), "l197_obsidian", GeoKit.ALL, false)
	L.chest_at = cp
	L.lights.add_anchor(pc + Vector3(0, 6.5, 0), Color(0.65, 0.78, 1.0), 1.6, 14.0, 0.0, "fortress")
	L.lights.add_anchor(pc + Vector3(0, GALLERY_Y + 2.2, -h + 2.0), Color(0.7, 0.8, 1.0), 0.9, 7.0, 0.0, "fortress")
	L.fortress_hall = AABB(pc + Vector3(-h, -0.5, -h), Vector3(HALL, HALL_H, HALL))
