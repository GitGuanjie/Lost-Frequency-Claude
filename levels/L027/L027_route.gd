extends RefCounted
## Level 27, the testimony route (M.E.G. Expedition Log No.1): the dark cavern behind the
## second waterfall, its L.lake, the rock spire ramp to the sky hole, and the Stormstone plain.

const Geo := preload("res://levels/L027/L027_geo.gd")
const CAV := Vector3(-3.0, 0.0, -37.0)
const CAV_R := 16.0
const PLAIN_Y := 18.0
const HOLE_R := 5.1


## Walking line used by the QA self-test: causeway, mound, spire ramp, plain.
static func route_points() -> Array:
	var pts: Array = [CAV + Vector3(0, 4.4, CAV_R - 2.0), CAV + Vector3(0, 3.6, 9.0), CAV + Vector3(0, 4.5, 5.5)]
	for i in 45:
		var t := float(i) / 44.0
		var a := PI * 0.5 + t * TAU * 1.5
		var rad := lerpf(2.7, 4.7, t)
		pts.append(CAV + Vector3(cos(a) * rad, lerpf(5.75, PLAIN_Y - 0.05, t), sin(a) * rad))
	pts.append(CAV + Vector3(HOLE_R + 1.0, PLAIN_Y, 0))
	return pts


static func build_cavern(L) -> void:
	var k: GeoKit = L.kit("Cavern")
	var col := []
	var holes := [{"a0": deg_to_rad(84.0), "a1": deg_to_rad(96.0), "y0": 4.4, "y1": 7.1}, {"a0": 0.0, "a1": TAU, "y0": 17.0, "y1": 99.0}]
	var prof := func(y: float) -> float: return sqrt(maxf(0.0, 1.0 - pow((y - 0.8) / 17.1, 2.0)))
	var damp := func(a: float, y: float) -> float:
		return smoothstep(0.08, 0.2, absf(wrapf(a - PI * 0.5, -PI, PI))) if y < 8.0 else (smoothstep(16.0, 15.0, y))
	var crock: String = L._wall_mat("l27_rock_cavern_photo", Color(0.3, 0.3, 0.34), "l27_cavern_rock")
	Geo.shell_damped(L.nz, k, crock, CAV, CAV_R, CAV_R, 0.8, 19, 0.9, 48, prof, 0.07, holes, col, damp)
	# collar from the top ring to the plain
	for s in 48:
		var a0 := TAU * s / 48.0
		var a1 := TAU * (s + 1) / 48.0
		var p0 := CAV + Vector3(cos(a0) * HOLE_R, 17.0, sin(a0) * HOLE_R)
		var p1 := CAV + Vector3(cos(a1) * HOLE_R, 17.0, sin(a1) * HOLE_R)
		Geo.quad(k, "l27_stormstone_rock", p0, p1, p1 + Vector3.UP * (PLAIN_Y - 17.0), p0 + Vector3.UP * (PLAIN_Y - 17.0), CAV + Vector3(0, 17.5, 0) - (p0 + p1) * 0.5, col)
	var shelf := Vector2(CAV.x, CAV.z + CAV_R - 1.6)
	var cav_h := func(x: float, z: float) -> float:
		var p := Vector2(x, z)
		var r := p.distance_to(Vector2(CAV.x, CAV.z))
		var h: float = 0.8 + 0.3 * L.nz.get_noise_2d(x * 0.4, z * 0.4)
		h = maxf(h, 4.4 - maxf(0.0, p.distance_to(shelf) - 2.2) * 0.9)
		if absf(x - CAV.x) < 0.9 and z < shelf.y and z > CAV.z + 5.0:
			h = maxf(h, 3.55 + 0.05 * L.nz.get_noise_2d(x * 3.0, z * 3.0))
		if r < 7.0:
			h = maxf(h, 3.55 + 3.45 * (1.0 - r / 7.0))
		return h
	Geo.heightfield(k, CAV.x - CAV_R - 1.0, CAV.z - CAV_R - 1.0, CAV.x + CAV_R + 1.0, CAV.z + CAV_R + 1.0, 1.0, cav_h,
		func(_y: float) -> String: return crock,
		func(x: float, z: float) -> bool: return Vector2(x, z).distance_to(Vector2(CAV.x, CAV.z)) < CAV_R + 0.8, col)
	# the rock spire and the ramp of piled rock wound round it, up to the sky hole
	k.cylinder(CAV + Vector3(0, 11.0, 0), 1.9, 9.0, "l27_cavern_rock", 9)
	var n := 22
	var prev := Vector3.ZERO
	for i in n + 1:
		var t := float(i) / n
		var a := PI * 0.5 + t * TAU * 1.5
		var rad := lerpf(2.7, 4.7, t)
		var p := CAV + Vector3(cos(a) * rad, lerpf(5.75, PLAIN_Y - 0.05, t), sin(a) * rad)
		if i > 0:
			var mid := (prev + p) * 0.5
			k.ramp(prev - (p - prev).normalized() * 0.25, p + (p - prev).normalized() * 0.25, 1.9, 0.6, "l27_cavern_rock")
			k.box(mid - Vector3(0, 0.9, 0), Vector3(1.6, 1.4, 1.4), "l27_cavern_rock", GeoKit.ALL, false)
		prev = p
	L._trimesh(k, col)
	k.commit()
	L.lake = WaterVolume.new()
	L.lake.name = "CavernLake"
	L.add_child(L.lake)
	L.lake.setup(Vector3(CAV.x - CAV_R - 1.0, 0.0, CAV.z - CAV_R - 1.0), Vector3(CAV.x + CAV_R + 1.0, 3.9, CAV.z + CAV_R - 0.4), "l27_lake", true)
	L.lake.fog_color = Color(0.01, 0.01, 0.03)
	L.lake.fog_density = 0.3
	L.lake.tint = Color(0.05, 0.06, 0.12)
	var d := Node3D.new()
	d.name = "Rockpile"
	L.add_child(d)
	var r := RandomNumberGenerator.new()
	r.seed = 2828
	for i in 4:
		var a := r.randf() * TAU
		var rr := r.randf_range(2.0, 6.5)
		var p := CAV + Vector3(cos(a) * rr, 0, sin(a) * rr)
		var hgt := r.randf_range(1.2, 3.2)
		Props.place(L, d, "ph/boulder_01", Vector3(p.x, cav_h.call(p.x, p.z) - hgt * 0.3, p.z), r.randf_range(0, 360), hgt, false)


static func build_plain(L) -> void:
	var k: GeoKit = L.kit("StormstonePlain")
	var col := []
	var outer := 1400.0
	for s in 48:
		var a0 := TAU * s / 48.0
		var a1 := TAU * (s + 1) / 48.0
		var i0 := CAV + Vector3(cos(a0) * HOLE_R, PLAIN_Y, sin(a0) * HOLE_R)
		var i1 := CAV + Vector3(cos(a1) * HOLE_R, PLAIN_Y, sin(a1) * HOLE_R)
		var mid0 := CAV + Vector3(cos(a0) * 60.0, PLAIN_Y, sin(a0) * 60.0)
		var mid1 := CAV + Vector3(cos(a1) * 60.0, PLAIN_Y, sin(a1) * 60.0)
		Geo.quad(k, "l27_stormstone_rock", i0, i1, mid1, mid0, Vector3.UP, col)
		Geo.quad(k, "l27_stormstone_rock", mid0, mid1, CAV + Vector3(cos(a1) * outer, PLAIN_Y, sin(a1) * outer),
			CAV + Vector3(cos(a0) * outer, PLAIN_Y, sin(a0) * outer), Vector3.UP, col)
	L._trimesh(k, col)
	k.shadows = false
	k.commit()
	L.night = DirectionalLight3D.new()
	L.night.name = "IndigoSky"
	L.night.rotation_degrees = Vector3(-62, 30, 0)
	L.night.light_color = Color(0.45, 0.45, 0.9)
	L.night.light_energy = 0.35
	L.night.shadow_enabled = false
	L.night.visible = false
	L.add_child(L.night)


