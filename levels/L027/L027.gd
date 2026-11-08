extends LevelBase
## Level 27 "The Bunker Springs" (Backrooms Wikidot rev 62, accessed 2026-11-04; Kitty Rika,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L027.md. Page flagged outdated; the second half
## is an M.E.G. expedition log (TESTIMONY).
##
## PLAN (read -> design):
## - SOURCE: one small limestone cave round a ~18.6 m2 hot spring, humid, no life at all;
##   two small waterfalls from two openings in the wall feed it; it drains by a tunnel near
##   a corner too small to crawl through -> a 13 x 11 m domed limestone grotto (organic shell
##   and heightfield floor), a superellipse pool of 18.6 m2 at the back wall with a submerged
##   bench ring, a runnel to a fist-sized drain hole in the west corner, steam and drips.
## - SOURCE: the M.E.G. built a stairway near a corner by one waterfall up to the tunnel that
##   waterfall flows out of; the tunnel is wide enough to walk beside the stream and leads
##   back where you came from; Level 11 arrivals land at that tunnel entrance -> concrete
##   stair (18 x 0.178 m) to a platform at +3.2 m in the tunnel mouth; arrival there facing
##   the cave; the tunnel bends away into the dark with the stream: exit L027>EXT#1 (@origin).
## - SOURCE: water ~32 C, potable, clear-headedness; an hour's soak calms and heals minor
##   ailments; over two hours brings dizziness and nausea -> signature mechanic: a soak
##   clock (ADAPTATION: one spring hour = 60 s of play) with calm/heal at 1 h and a growing
##   head sway past 2 h; drinking from the stream refills stamina.
## - SOURCE: "Don't climb the other waterfall tunnel. It leads to nowhere." + the log
##   (TESTIMONY): smooth wall climbed above the water, crawl against warm current, a vast
##   dark cavern with a hole showing an indigo sky, a rock pile out of the water, a flat
##   black Stormstone plain; the cave is gone behind; one step and she wakes in Stormstone
##   Keep -> optional climb (smooth wall, auto-crouch crawl), cavern with lake and a rock
##   spire ramp to the sky hole, the plain; the hole closes behind you; stepping on fires
##   L027>L028#2 (created only out there, so it is never presented as part of the spring).
## - ADAPTATION: light sources are not stated -> M.E.G. work lamps on the stairway they built
##   and a soft glow in the pool; cave layout grammar is ours (the page gives no map).

const Geo := preload("res://levels/L027/L027_geo.gd")
const Route := preload("res://levels/L027/L027_route.gd")
const WATER_Y := -0.12
const POOL_C := Vector2(-0.9, -3.4)
const POOL_A := 2.9
const POOL_B := 1.82
const HOUR := 60.0
const CAV := Route.CAV
const CAV_R := Route.CAV_R
const PLAIN_Y := Route.PLAIN_Y
const HOLE_R := Route.HOLE_R

var nz := FastNoiseLite.new()
var soak := 0.0
var dry_t := 0.0
var calmed := false
var dizzy := 0.0
var drinks := 0
var cave_gone := false
var stand_point := Vector3.ZERO
var blast_t := -1.0
var fired_ok := false
var on_plain := false
var tube_a: Array = []
var tube_b: Array = []
var pool_water: WaterVolume
var lake: WaterVolume
var night: DirectionalLight3D
var _beds := {}
var _said := {}
var _crouch_forced := false
var _sway_t := 0.0
var _haul_t := 0.0
var _ladder_t := 99.0


func build() -> void:
	nz.seed = 2727
	nz.frequency = 0.35
	rules["view_distance"] = 900.0
	rules["reverb_room"] = 0.72
	rules["reverb_wet"] = 0.32
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.55, 0.66, 0.66), 0.16, Color(0.22, 0.25, 0.25), 0.025)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.015, 0.012, 0.11)
	sky_mat.sky_horizon_color = Color(0.06, 0.05, 0.24)
	sky_mat.ground_horizon_color = Color(0.03, 0.025, 0.1)
	sky_mat.ground_bottom_color = Color(0.0, 0.0, 0.0)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0)
	environment.sky = sky
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.4
	Geo.materials(WATER_Y)
	tube_a = [Vector3(1.76, 2.9, -4.84), Vector3(2.26, 2.9, -6.78), Vector3(2.8, 2.9, -9.2), Vector3(4.0, 2.9, -11.6),
		Vector3(6.1, 2.9, -13.3), Vector3(8.8, 2.9, -14.1), Vector3(11.4, 2.9, -14.4)]
	tube_b = [Vector3(-2.54, 4.4, -4.77), Vector3(-3.24, 4.4, -6.65), Vector3(-3.94, 4.4, -8.53), Vector3(-4.2, 4.4, -12.5),
		Vector3(-3.4, 4.4, -16.0), Vector3(-3.0, 4.4, -19.2), Vector3(-3.0, 4.4, -21.6)]
	_grotto()
	_tunnels()
	_meg_stair()
	_waters()
	_dressing()
	Route.build_cavern(self)
	Route.build_plain(self)
	_lights()
	_sounds()
	var start: Vector3 = tube_a[1] + Vector3(0.97, 0.0, 0.25) * 0.45 + Vector3(0, 0.33, 0)
	add_arrival("start", start, 165.0)
	# the way back: follow the stream up the tunnel (SOURCE, walk_in after the first bend)
	var fwd: Vector3 = (tube_a[4] - tube_a[3]).normalized()
	var ex: Vector3 = (tube_a[3] + tube_a[4]) * 0.5 + fwd.cross(Vector3.UP).normalized() * 0.42 + Vector3(0, 1.5, 0)
	add_exit("L027>EXT#1", "walk_in", ex, Vector3(2.6, 2.6, 2.6), "Follow the stream back up the tunnel")
	add_landmark("M.E.G. stairway and tunnel mouth", Vector3(2.6, 3.2, -4.2))
	add_landmark("Hot spring", Vector3(POOL_C.x, 0, POOL_C.y))
	add_landmark("The other waterfall (do not climb)", Vector3(-2.6, 4.4, -4.9))
	add_note("l27_meg_notice", "M.E.G. notice on the stair rail", "LEVEL 27 - THE BUNKER SPRINGS\n\nThe water is clean, warm (about 32 C) and safe to drink.\nAn hour's soak eases stress and small hurts. Do not stay in past two hours: dizziness and nausea follow.\nIf thirty or so people are already bathing, wait. Leave promptly when done.\nThe drain in the far corner is too small to crawl into. Leave it alone.\n\nThe stairs and the tunnel beside the stream take you back the way you came.",
		Vector3(2.35, 4.05, -3.55), Vector3(0.4, 0.5, 0.2))
	add_note("l27_warning", "Scratched into the rock by the second fall", "\"Don't climb the other waterfall tunnel. It leads to nowhere.\"\n(Level 27 article, Entrances And Exits.)",
		Vector3(-4.2, 0.65, -3.9), Vector3(0.6, 0.6, 0.6), false)
	add_interactable(tube_a[0] + Vector3(-0.85, 0.5, -0.3), Vector3(1.0, 0.8, 1.2), "Drink from the stream", func(_p = null): _drink())
	add_interactable(Vector3(-5.75, 0.1, -1.95), Vector3(0.9, 0.7, 0.9), "Look into the drain", func(_p = null):
		Overlay.toast("A hole no wider than a forearm. Warm water slides into it and is gone. Nobody could crawl through, and nobody knows where it goes.", 5.0))
	add_shot("tunnel_mouth", start + Vector3(0.0, 1.62, 0.4), Vector3(-1.4, 0.2, -1.5), {"flashlight": false})
	add_shot("spring_falls", Vector3(0.9, 1.55, 3.6), Vector3(-1.0, 1.6, -5.0), {"flashlight": false})
	add_shot("meg_stair", Vector3(-4.6, 1.6, 1.2), Vector3(3.0, 2.0, -2.4), {"flashlight": false})
	add_shot("cavern_sky_hole", CAV + Vector3(1.4, 5.4, 9.5), CAV + Vector3(0.0, 15.5, 0.0), {"flashlight": false})
	add_shot("stormstone_plain", CAV + Vector3(7.0, PLAIN_Y + 1.62, 3.0), CAV + Vector3(160.0, PLAIN_Y, 90.0), {"flashlight": false, "prepare": _prep_plain})


func _wall_mat(name: String = "l27_rock_limestone_photo", tint: Color = Color(0.92, 0.95, 0.98), fallback: String = "l27_limestone") -> String:
	var base := MatLib.get_mat("rock")
	if base is BaseMaterial3D:
		var m := (base as BaseMaterial3D).duplicate() as BaseMaterial3D
		m.albedo_color = tint
		m.uv1_scale = Vector3(0.4, 0.4, 1.0)
		MatLib.register(name, m)
		return name
	return fallback


# --------------------------------------------------------------------- the grotto

func _pool_e(x: float, z: float) -> float:
	return pow(absf((x - POOL_C.x) / POOL_A), 3.0) + pow(absf((z - POOL_C.y) / POOL_B), 3.0)


func _floor_h(x: float, z: float) -> float:
	var q := sqrt(pow(x / 6.4, 2.0) + pow(z / 5.4, 2.0))
	var base := 0.05 * nz.get_noise_2d(x * 1.7, z * 1.7) - 0.03 * (1.0 - clampf(q, 0.0, 1.0))
	if q > 0.8:
		base += pow((q - 0.8) / 0.25, 2.0) * 1.1
	var e := _pool_e(x, z)
	if e < 1.0:
		var y := lerpf(-1.25, -0.6, smoothstep(0.3, 0.5, e))
		y = lerpf(y, -0.25, smoothstep(0.82, 0.98, e))
		return y + 0.03 * nz.get_noise_2d(x * 3.0, z * 3.0)
	var rim := lerpf(-0.25, 0.08, smoothstep(1.0, 1.08, e))
	var h := lerpf(rim, base, smoothstep(1.1, 1.35, e))
	# the drain runnel from the west end of the pool to the corner
	var a := Vector2(-3.7, -3.3)
	var b := Vector2(-5.95, -1.9)
	var p := Vector2(x, z)
	var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	if p.distance_to(a + (b - a) * t) < 0.24:
		h = minf(h, -0.2)
	return h


func _grotto_damp(a: float, y: float) -> float:
	# smooth (noise-free) wall round the two openings and below the second fall
	var d := 1.0
	for w in [[deg_to_rad(287.0), deg_to_rad(20.0), 2.4, 6.2], [deg_to_rad(246.0), deg_to_rad(13.0), -2.0, 6.2]]:
		var da := absf(wrapf(a - float(w[0]), -PI, PI))
		if da < float(w[1]) and y > float(w[2]) and y < float(w[3]):
			d = minf(d, smoothstep(float(w[1]) * 0.55, float(w[1]), da))
	return d


func _grotto() -> void:
	var k := kit("Grotto")
	var deck := _wall_mat("l27_rock_deck_photo", Color(0.82, 0.85, 0.88), "l27_flowstone")
	var col := []
	var holes := [{"a0": deg_to_rad(274.0), "a1": deg_to_rad(300.0), "y0": 3.2, "y1": 5.6, "arch": true},
		{"a0": deg_to_rad(241.5), "a1": deg_to_rad(250.5), "y0": 4.4, "y1": 5.6, "arch": true}]
	var prof := func(y: float) -> float: return 1.0 if y < 3.6 else sqrt(maxf(0.0, 1.0 - pow((y - 3.6) / 4.8, 2.0)))
	Geo.shell_damped(nz, k, _wall_mat(), Vector3.ZERO, 6.4, 5.4, -1.6, 25, 0.4, 96, prof, 0.07, holes, col, _grotto_damp)
	Geo.heightfield(k, -7.0, -6.0, 7.0, 6.0, 0.3, _floor_h,
		func(y: float) -> String: return "l27_poolrock" if y < -0.3 else deck,
		func(x: float, z: float) -> bool: return pow(x / 6.7, 2.0) + pow(z / 5.7, 2.0) < 1.0, col)
	# stalactites from the dome, stalagmites at the foot of the walls (limestone, no life)
	var r := RandomNumberGenerator.new()
	r.seed = 27
	for i in 46:
		var a := r.randf() * TAU
		var q := r.randf_range(0.25, 0.86)
		var p := Vector3(cos(a) * 6.4 * q, 0.0, sin(a) * 5.4 * q)
		var ceil_y := 3.6 + 4.8 * sqrt(maxf(0.0, 1.0 - q * q)) - 0.25
		_cone(k, deck, Vector3(p.x, ceil_y + 0.3, p.z), r.randf_range(0.05, 0.16), -r.randf_range(0.35, 1.3), null)
	_trimesh(k, col)
	k.commit()


func _cone(k: GeoKit, mat: String, base: Vector3, r: float, length: float, col: Variant) -> void:
	var tip := base + Vector3.UP * length
	for s in 6:
		var a0 := TAU * s / 6.0
		var a1 := TAU * (s + 1) / 6.0
		var p0 := base + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := base + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var out := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		Geo.tri(k, mat, p0, p1, tip, out, col)


func _trimesh(k: GeoKit, faces: Array, surface: String = "concrete") -> void:
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(PackedVector3Array(faces))
	sh.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.set_meta("surface", surface)
	k.body.add_child(cs)
	k.stats["shapes"] += 1


# --------------------------------------------------------------------- tunnels

func _tunnels() -> void:
	var k := kit("Tunnels")
	var trock := _wall_mat("l27_rock_tunnel_photo", Color(0.7, 0.72, 0.74), "l27_tunnel_rock")
	var col := []
	Geo.tube(k, trock, trock, tube_a, [3.7, 3.4, 3.1, 3.0, 2.9, 2.9, 2.9], [2.85, 2.7, 2.55, 2.5, 2.45, 2.4, 2.4], nz, 0.18, col)
	# walkway ledge beside the stream (right-hand side going in)
	for i in tube_a.size() - 1:
		var a: Vector3 = tube_a[i]
		var b: Vector3 = tube_a[i + 1]
		var f := (b - a).normalized()
		var r := f.cross(Vector3.UP).normalized()
		var w: float = [3.7, 3.4, 3.1, 3.0, 2.9, 2.9, 2.9][i]
		var lo: float = -w * 0.5 + 0.95
		var hi: float = w * 0.5 - 0.12
		var c: Vector3 = (a + b) * 0.5 + r * ((lo + hi) * 0.5) + Vector3.UP * 0.15
		k.box_xf(Transform3D(Basis(Vector3.UP.cross(f).normalized(), Vector3.UP, f), c), Vector3(hi - lo, 0.3, (b - a).length() + 0.7), trock, GeoKit.ALL, true, "concrete")
	# the end of the walked tunnel turns away into darkness
	var e: Vector3 = tube_a[tube_a.size() - 1]
	k.box(e + Vector3(0.4, 1.3, 0.0), Vector3(0.2, 2.8, 3.2), "unlit_black", GeoKit.NX, true)
	# the crawl behind the second fall: low, then widening into the cavern
	Geo.tube(k, trock, trock, tube_b, [1.45, 1.4, 1.35, 1.4, 1.5, 2.2, 3.1], [1.2, 1.18, 1.15, 1.15, 1.2, 2.0, 2.8], nz, 0.1, col)
	_trimesh(k, col)
	k.commit()


func _meg_stair() -> void:
	var k := kit("MEGStair")
	k.stairs(Vector3(3.1, 0.0, 1.85), Vector3(0, 0, -1), 1.3, 3.2, 18, "concrete", 0.29)
	k.box_mm(Vector3(0.95, 2.8, -5.15), Vector3(3.75, 3.2, -3.36), "concrete")
	for p in [Vector3(1.2, 0.0, -3.6), Vector3(3.5, 0.0, -3.6)]:
		k.box(Vector3(p.x, 0.9, p.z), Vector3(0.3, 3.8, 0.3), "concrete")
	# steel rail on the pool side of the flight and round the platform edge
	var rail := [[Vector3(2.45, 0.0, 1.85), Vector3(2.45, 3.2, -3.37)], [Vector3(2.45, 3.2, -3.4), Vector3(0.98, 3.2, -3.4)],
		[Vector3(0.98, 3.2, -3.4), Vector3(0.98, 3.2, -5.0)]]
	for seg in rail:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var n := int(ceil(Vector2(b.x - a.x, b.z - a.z).length() / 1.3))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			k.box(p + Vector3(0, 0.5, 0), Vector3(0.05, 1.0, 0.05), "metal", GeoKit.ALL, false)
		for hgt in [1.0, 0.5]:
			var ta: Vector3 = a + Vector3.UP * hgt
			var tb: Vector3 = b + Vector3.UP * hgt
			var z := (tb - ta).normalized()
			var x := Vector3.UP.cross(z).normalized()
			k.box_xf(Transform3D(Basis(x, z.cross(x), z), (ta + tb) * 0.5), Vector3(0.05, 0.05, (tb - ta).length()), "metal", GeoKit.ALL, false)
		# one collision board per run so nobody steps off the edge by accident
		var mid := (a + b) * 0.5 + Vector3.UP * 0.55
		var zz := (b - a).normalized()
		var xx := Vector3.UP.cross(zz).normalized()
		k.add_box_shape(Transform3D(Basis(xx, zz.cross(xx), zz), mid), Vector3(0.08, 1.1, (b - a).length()), "metal")
	k.commit()


# --------------------------------------------------------------------- water

func _waters() -> void:
	pool_water = WaterVolume.new()
	pool_water.name = "Spring"
	add_child(pool_water)
	pool_water.setup(Vector3(POOL_C.x - POOL_A - 0.4, -1.4, POOL_C.y - POOL_B - 0.5), Vector3(POOL_C.x + POOL_A + 0.4, WATER_Y, POOL_C.y + POOL_B + 0.4), "l27_spring", true)
	pool_water.fog_color = Color(0.14, 0.32, 0.32)
	pool_water.fog_density = 0.12
	pool_water.tint = Color(0.35, 0.6, 0.58)
	var fm := Geo.fall_material(Color(0.84, 0.93, 0.92), 1.0, 0.85)
	var fx := Node3D.new()
	fx.name = "Falls"
	add_child(fx)
	Geo.ribbon(fx, Vector3(0.55, 3.24, -5.22), Vector3(0.05, 0, 1), 3.36, 0.55, fm)
	Geo.ribbon(fx, Vector3(-2.62, 4.44, -4.95), Vector3(0.35, 0, 0.94), 4.56, 0.42, fm)
	# streams: thin running water over the channel beds
	var sm := Geo.fall_material(Color(0.42, 0.62, 0.62), 0.35, 0.5)
	var kk := kit("Streams")
	for i in tube_a.size() - 1:
		var a: Vector3 = tube_a[i]
		var b: Vector3 = tube_a[i + 1]
		var r := (b - a).normalized().cross(Vector3.UP).normalized()
		var w: float = [3.7, 3.4, 3.1, 3.0, 2.9, 2.9, 2.9][i]
		var o: float = -w * 0.5 + 0.48
		Geo.poly(kk, "l27_stream", [a + r * (o - 0.42) + Vector3.UP * 0.2, a + r * (o + 0.42) + Vector3.UP * 0.2,
			b + r * (o + 0.42) + Vector3.UP * 0.2, b + r * (o - 0.42) + Vector3.UP * 0.2], Vector3.UP)
	for i in tube_b.size() - 2:
		var a: Vector3 = tube_b[i]
		var b: Vector3 = tube_b[i + 1]
		var r := (b - a).normalized().cross(Vector3.UP).normalized()
		Geo.poly(kk, "l27_stream", [a - r * 0.55 + Vector3.UP * 0.08, a + r * 0.55 + Vector3.UP * 0.08,
			b + r * 0.55 + Vector3.UP * 0.08, b - r * 0.55 + Vector3.UP * 0.08], Vector3.UP)
	Geo.poly(kk, "l27_stream", [Vector3(-3.7, -0.14, -3.55), Vector3(-3.55, -0.14, -3.1), Vector3(-5.9, -0.14, -1.7), Vector3(-6.0, -0.14, -2.1)], Vector3.UP)
	MatLib.register("l27_stream", sm)
	kk.shadows = false
	kk.commit()
	Geo.mist(fx, Vector3(POOL_C.x, 0.25, POOL_C.y), Vector3(2.4, 0.15, 1.4), 26, 0.07)
	Geo.mist(fx, Vector3(0.55, 0.1, -4.75), Vector3(0.3, 0.1, 0.3), 10, 0.12)
	Geo.mist(fx, Vector3(-2.45, 0.1, -4.5), Vector3(0.3, 0.1, 0.3), 10, 0.12)
	# the smooth wall under the second fall: climbable (with care), as in the log
	var lad := LadderVolume.new()
	lad.name = "SmoothWallClimb"
	add_child(lad)
	lad.setup(Vector3(-3.5, -1.0, -5.2), Vector3(-1.9, 5.45, -4.0))
	# the drain: a dark hole at the end of the runnel, too small to enter
	var kd := kit("Drain")
	kd.box(Vector3(-6.02, -0.02, -1.92), Vector3(0.36, 0.3, 0.36), "unlit_black", GeoKit.ALL, false)
	kd.commit()


func _dressing() -> void:
	var d := Node3D.new()
	d.name = "Dressing"
	add_child(d)
	var r := RandomNumberGenerator.new()
	r.seed = 2711
	for p in [Vector3(-5.2, 0, 1.6), Vector3(-1.8, 0, 4.9), Vector3(5.4, 0, -0.6), Vector3(-5.7, 0, -1.3), Vector3(1.4, 0, 5.0)]:
		var hgt := r.randf_range(0.3, 0.75)
		Props.place(self, d, "ph/boulder_01", Vector3(p.x, _floor_h(p.x, p.z) - hgt * 0.25, p.z), r.randf_range(0, 360), hgt, hgt > 0.5)
	for i in 14:
		var a := r.randf() * TAU
		var q := r.randf_range(0.55, 0.8)
		var p := Vector3(cos(a) * 6.4 * q, 0, sin(a) * 5.4 * q)
		if _pool_e(p.x, p.z) < 1.3 or (p.x > 2.0 and p.z < 2.4):
			continue
		Props.place(self, d, ["kenney/nature-kit/rock-smalla", "kenney/nature-kit/rock-smallb", "kenney/nature-kit/rock-smalld"][i % 3], Vector3(p.x, _floor_h(p.x, p.z) - 0.02, p.z), r.randf_range(0, 360), r.randf_range(0.1, 0.25), false, false)
	# M.E.G. fittings: two caged work lamps, cable, a lamp post at the foot of the stair
	Props.place(self, d, "ph/caged_hanging_light", Vector3(2.5, 4.95, -4.55), 15.0)
	Props.place(self, d, "ph/caged_hanging_light", tube_a[3] + Vector3(0.2, 2.0, 0.0), 60.0)
	Props.place(self, d, "ph/modular_electric_cables", Vector3(3.8, 2.2, -3.0), 90.0)
	var kp := kit("LampPost")
	kp.box(Vector3(4.05, 1.1, 2.0), Vector3(0.08, 2.2, 0.08), "metal")
	kp.box(Vector3(4.05, 0.03, 2.0), Vector3(0.4, 0.06, 0.4), "concrete")
	kp.commit()
	Props.place(self, d, "ph/industrial_wall_lamp", Vector3(3.95, 2.0, 2.0), -90.0)
	Props.place(self, d, "ph/power_box_01", Vector3(3.85, 3.2, -4.9), 200.0)


# ---------------------------------------------------------------- testimony route

func _close_cave() -> void:
	cave_gone = true
	var k := kit("CaveGone")
	var col := []
	for s in 48:
		var a0 := TAU * s / 48.0
		var a1 := TAU * (s + 1) / 48.0
		Geo.tri(k, "l27_stormstone_rock", CAV + Vector3(0, PLAIN_Y, 0), CAV + Vector3(cos(a0) * (HOLE_R + 0.1), PLAIN_Y, sin(a0) * (HOLE_R + 0.1)),
			CAV + Vector3(cos(a1) * (HOLE_R + 0.1), PLAIN_Y, sin(a1) * (HOLE_R + 0.1)), Vector3.UP, col)
	_trimesh(k, col)
	k.commit()
	stand_point = player.global_position
	if not SessionState.is_qa():
		Overlay.subtitle("[TESTIMONY, M.E.G. log No.1: \"I turned back around to flee into the cave, only to find that it was gone.\"]", 7.0)
	var t := make_exit("L027>L028#2", "condition", stand_point + Vector3(0, 1.0, 0), Vector3(40.0, 4.0, 40.0), "", self)
	if t:
		t.condition = func() -> bool: return blast_t >= 0.0 and blast_t > 0.9


# ------------------------------------------------------------------ light & sound

func _lights() -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(2.5, 4.7, -4.4)
	lamp.light_color = Color(1.0, 0.8, 0.58)
	lamp.light_energy = 2.4
	lamp.omni_range = 11.0
	lamp.omni_attenuation = 1.3
	lamp.shadow_enabled = false
	add_child(lamp)
	for spec in [[Vector3(3.75, 2.05, 2.0), Color(1.0, 0.82, 0.62), 1.5, 8.0], [tube_a[3] + Vector3(0.2, 1.8, 0.0), Color(1.0, 0.8, 0.58), 1.0, 7.0],
			[Vector3(POOL_C.x, -0.75, POOL_C.y), Color(0.32, 0.82, 0.8), 1.6, 5.5], [Vector3(POOL_C.x, 0.6, POOL_C.y - 0.4), Color(0.4, 0.75, 0.72), 0.55, 7.5]]:
		var o := OmniLight3D.new()
		o.position = spec[0]
		o.light_color = spec[1]
		o.light_energy = spec[2]
		o.omni_range = spec[3]
		add_child(o)
	var sky_spot := SpotLight3D.new()
	sky_spot.position = CAV + Vector3(0, PLAIN_Y + 2.0, 0)
	sky_spot.rotation_degrees = Vector3(-90, 0, 0)
	sky_spot.light_color = Color(0.3, 0.32, 0.8)
	sky_spot.light_energy = 11.0
	sky_spot.spot_range = 30.0
	sky_spot.spot_angle = 24.0
	sky_spot.shadow_enabled = true
	add_child(sky_spot)


func _sounds() -> void:
	sound.emitter("water_bed", Vector3(0.55, 1.0, -4.8), {"seconds": 6.0, "bright": 1800.0}, -3.0, 18.0)
	sound.emitter("water_bed", Vector3(-2.45, 1.5, -4.5), {"seconds": 7.0, "bright": 1500.0}, -5.0, 18.0)
	sound.emitter("water_bed", tube_a[2] + Vector3(-0.6, 0.4, 0), {"seconds": 5.0, "bright": 900.0}, -9.0, 12.0)
	_beds["room"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0, "rumble": 0.25}, -30.0)
	_beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -80.0)
	sound.oneshot("drip", {"freq": 1300.0}, 3.0, 8.0, 7.0, "[water drips from the limestone]", -12.0)


# ------------------------------------------------------------------ mechanics

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var in_spring := pool_water != null and pool_water.contains(p + Vector3(0, 0.3, 0)) and _pool_e(p.x, p.z) < 1.05
	_soak(delta, in_spring)
	_auto_crouch(p)
	_haul(delta, p)
	_region(delta, p)
	if blast_t >= 0.0:
		blast_t += delta
		environment.tonemap_exposure = lerpf(environment.tonemap_exposure, 9.0, minf(delta * 4.0, 1.0))
	elif cave_gone and Vector2(p.x - stand_point.x, p.z - stand_point.z).length() > 1.0:
		blast_t = 0.0
		Overlay.glitch(1.0)
		sound.play_at("distant_boom", {}, p + Vector3(0, -0.5, 1.0), 2.0, "[the Stormstone under your foot goes off]")
		Overlay.subtitle("[TESTIMONY: \"I took a deep breath and stepped forth, preparing to die. I closed my eyes.\"]", 4.0)


func _soak(delta: float, in_spring: bool) -> void:
	if player.frozen:
		return
	if in_spring:
		soak += delta
		dry_t = 0.0
	else:
		dry_t += delta
		if dry_t > 20.0:
			soak = maxf(0.0, soak - delta * 4.0)
	if in_spring and soak > HOUR * 0.25:
		_say("warm", "[the warm mineral water works into your shoulders]", 4.0)
	if in_spring and soak >= HOUR and not calmed:
		calmed = true
		player.heal(40.0)
		player.stamina = player.stamina_max
		Overlay.subtitle("[an hour in the spring: calmer, lighter, the small aches gone]", 5.0)
	var target := clampf((soak - 2.0 * HOUR) / HOUR, 0.0, 1.0) if in_spring or dry_t < 20.0 else 0.0
	dizzy = lerpf(dizzy, target, minf(delta * 0.6, 1.0))
	if dizzy > 0.05:
		_say("dizzy", "[two hours in the heat: dizzy, a little sick. Get out and cool off.]", 5.0)
	_sway_t += delta
	player.head.rotation.z = sin(_sway_t * 0.9) * 0.07 * dizzy
	Overlay.set_screen_effect("desaturate", dizzy * 0.25)


func _auto_crouch(p: Vector3) -> void:
	# the crawl behind the second fall is lower than a standing body: you go through on
	# hands and knees, as the log says ("my back bumping against the ceiling")
	var low := false
	if p.y > 2.4 and p.y < 6.0 and p.x < -1.6 and p.x > -5.2 and p.z < -4.3 and p.z > -19.6:
		low = true
	if low and not _crouch_forced:
		_crouch_forced = true
		Input.action_press("crouch")
	elif not low and _crouch_forced:
		_crouch_forced = false
		Input.action_release("crouch")


## Top of the smooth wall: "latch onto the edge of the opening and haul myself up".
func _haul(delta: float, p: Vector3) -> void:
	_ladder_t = 0.0 if player.on_ladder else _ladder_t + delta
	if _ladder_t < 1.5 and p.x > -3.4 and p.x < -1.9 and p.y > 3.9 and p.y < 5.3 and p.z > -4.95 and p.z < -3.9:
		_haul_t += delta
		if _haul_t > 0.5:
			_haul_t = 0.0
			var inside: Vector3 = tube_b[0] + (tube_b[1] - tube_b[0]).normalized() * 0.9 + Vector3(0, 0.03, 0)
			player.velocity = Vector3.ZERO
			player.global_position = inside
			if not SessionState.is_qa():
				Overlay.subtitle("[you get a hand over the lip of the opening and haul yourself in; warm water runs past your knees]", 4.5)
	else:
		_haul_t = 0.0


func _region(delta: float, p: Vector3) -> void:
	var deep := p.z < -19.0
	var up := p.y > PLAIN_Y - 1.2 and deep
	if deep:
		_say("log", "[TESTIMONY, M.E.G. Expedition Log No.1: the tunnel widens into a vast cavern; a hole in the ceiling shows a deep indigo sky]", 7.0)
	if up and not on_plain:
		on_plain = true
		night.visible = true
		if not SessionState.is_qa():
			Overlay.subtitle("[TESTIMONY: a barren plain of black rock, flatter than paper. No trees, no entities, no life. Stormstone.]", 7.0)
	var k := minf(delta * 0.8, 1.0)
	environment.fog_light_color = environment.fog_light_color.lerp(Color(0.03, 0.03, 0.09) if deep else Color(0.22, 0.25, 0.25), k)
	environment.fog_density = lerpf(environment.fog_density, (0.0045 if up else 0.02) if deep else 0.025, k)
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, (0.5 if up else 0.14) if deep else 0.16, k)
	environment.ambient_light_color = environment.ambient_light_color.lerp(Color(0.3, 0.3, 0.75) if deep else Color(0.55, 0.66, 0.66), k)
	environment.fog_sky_affect = 0.35 if up else 0.0
	environment.background_mode = Environment.BG_SKY if deep else Environment.BG_COLOR
	_vol("room", -80.0 if deep else -30.0, k)
	_vol("wind", -36.0 if up else -80.0, k)
	if up and not cave_gone and Vector2(p.x - CAV.x, p.z - CAV.z).length() > HOLE_R + 1.6 and p.y > PLAIN_Y - 0.3:
		_close_cave()


func _vol(key: String, db: float, k: float) -> void:
	var a: AudioStreamPlayer = _beds.get(key)
	if a:
		a.volume_db = lerpf(a.volume_db, db, k)


func _drink() -> void:
	drinks += 1
	player.stamina = player.stamina_max
	Overlay.toast("You cup your hands under the stream. Warm, clean, faintly mineral. Your head clears; you feel awake.", 4.5)


func _say(key: String, text: String, secs: float) -> void:
	if _said.has(key) or SessionState.is_qa():
		return
	_said[key] = true
	Overlay.subtitle(text, secs)


func _prep_plain() -> void:
	player.global_position = CAV + Vector3(7.0, PLAIN_Y, 3.0)
	on_plain = false
	for i in 40:
		_region(0.25, player.global_position)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "only the @origin tunnel exit exists at the spring", "ok": exits.size() == 1})
	out.append({"what": "arrival at the tunnel entrance above the stair", "ok": player.global_position.y > 3.0, "detail": player.global_position})
	var area := 4.0 * POOL_A * POOL_B * pow(gamma_third(), 2.0) / 0.9028
	out.append({"what": "spring is about 18.6 m2", "ok": absf(area - 18.6) < 0.8, "detail": area})
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(3.1, 2.5, -0.5), Vector3(3.1, -1.0, -0.5), 1))
	out.append({"what": "stair has collision half way up", "ok": not hit.is_empty() and (hit["position"] as Vector3).y > 1.0, "detail": hit.get("position")})
	# soak clock: one hour calms, past two hours dizzy
	soak = HOUR * 2.0 + 30.0
	_soak(1.0, true)
	var ok_dizzy := dizzy > 0.0 and calmed
	soak = 0.0
	dizzy = 0.0
	calmed = false
	player.head.rotation.z = 0.0
	Overlay.set_screen_effect("desaturate", 0.0)
	out.append({"what": "soak clock: calm at 1 h, dizziness past 2 h", "ok": ok_dizzy})
	# the climb: from the water at the smooth wall, up and into the crawl behind the second fall
	var keep := player.global_position
	player.global_position = Vector3(-2.75, -0.55, -4.15)
	player.rotation.y = atan2(0.35, 0.94)
	player.qa_active = true
	player.qa_input = Vector2(0, 1)
	var reached := false
	var trace: Array = []
	for i in 60 * 14:
		await get_tree().physics_frame
		_auto_crouch(player.global_position)
		if i % 60 == 0:
			trace.append([snapped(player.global_position, Vector3.ONE * 0.01), player.on_ladder, player.swimming, player.crouching])
		if player.global_position.y > 4.2 and player.global_position.z < -5.6:
			reached = true
			break
	var climb_end := player.global_position
	player.qa_input = Vector2.ZERO
	player.qa_active = false
	_auto_crouch(Vector3.ZERO)
	player.velocity = Vector3.ZERO
	player.global_position = keep
	out.append({"what": "smooth wall climb leads into the crawl tunnel", "ok": reached, "detail": [climb_end, trace]})
	# the crawl itself: floor all the way and room for a crouched body
	var cbad: Array = []
	var cap := CapsuleShape3D.new()
	cap.radius = Player.RADIUS
	cap.height = Player.HEIGHT_CROUCH
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = 1
	for i in tube_b.size() - 1:
		for t in [0.25, 0.75]:
			var c: Vector3 = (tube_b[i] as Vector3).lerp(tube_b[i + 1], t)
			var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(c + Vector3.UP * 0.8, c + Vector3.DOWN * 1.0, 1))
			if h.is_empty() or absf((h["position"] as Vector3).y - c.y) > 0.25:
				cbad.append(["floor", i, t])
				continue
			q.transform = Transform3D(Basis(), (h["position"] as Vector3) + Vector3.UP * (Player.HEIGHT_CROUCH * 0.5 + 0.04))
			if not space.intersect_shape(q, 1).is_empty():
				cbad.append(["head", i, t])
	out.append({"what": "crawl tunnel: floor and crouched headroom to the cavern", "ok": cbad.is_empty(), "detail": cbad})
	# the testimony route: causeway, mound and the spire ramp up to the sky hole
	var rbad: Array = []
	var pts: Array = Route.route_points()
	cap.height = Player.HEIGHT_STAND
	for c in pts:
		var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(c + Vector3.UP * 1.5, c + Vector3.DOWN * 2.5, 1))
		if h.is_empty():
			rbad.append(["floor", snapped(c, Vector3.ONE * 0.1)])
			continue
		q.transform = Transform3D(Basis(), (h["position"] as Vector3) + Vector3.UP * (Player.HEIGHT_STAND * 0.5 + 0.06))
		if not space.intersect_shape(q, 1).is_empty():
			rbad.append(["head", snapped(c, Vector3.ONE * 0.1)])
	out.append({"what": "cavern route: causeway, rock spire ramp and the plain above have floor and headroom", "ok": rbad.is_empty(), "detail": rbad})
	out.append({"what": "Level 28 exit is not present before the plain", "ok": not exits.any(func(t): return is_instance_valid(t) and t.edge_id == "L027>L028#2")})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out


func gamma_third() -> float:
	return 0.8929795
