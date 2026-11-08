extends RefCounted
## Level 965 geometry: rolling grey plain (streamed 96 m chunks), the long
## disused flood channel (runs east-west, z = ZC +/- 30), the flood barrier
## (five hooded piers across the channel at x = BX), defunct wind turbines on a
## jittered 170 m lattice, stray flood-wall segments, and the barrier control
## house ("the cleanest establishment"). Everything is grey; colour exists only
## in the rainbow built by L965.gd.

const CS := 96.0
const ZC := -48.0          # channel centreline
const CH := 30.0           # channel half width (inner wall faces at +/- 28.6)
const FLOOR_Y := -4.0
const BX := -60.0          # barrier pier line (piers run along x, flow direction)
const HOUSE := Vector3(-30.0, 0.0, 7.0)
const LATTICE := 170.0

var lvl
var n1 := FastNoiseLite.new()
var n2 := FastNoiseLite.new()
var tuft_mesh: ArrayMesh
var _grey_cache: Dictionary = {}
var grey_shader: Shader


func _init(level) -> void:
	lvl = level
	n1.seed = 965
	n1.frequency = 0.006
	n1.fractal_octaves = 3
	n2.seed = 9651
	n2.frequency = 0.035
	grey_shader = Shader.new()
	grey_shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec3 tint = vec3(1.0);
uniform bool has_tex = false;
uniform float rough = 0.8;
uniform float metal = 0.0;
void fragment() {
	vec3 c = tint;
	if (has_tex) { c *= texture(tex, UV).rgb; }
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	ALBEDO = vec3(l);
	ROUGHNESS = rough;
	METALLIC = metal;
}
"""
	tuft_mesh = _make_tuft()


func h(x: float, z: float) -> float:
	var dz := absf(z - ZC)
	if dz < CH:
		return FLOOR_Y - 0.3
	var y := 1.5 * n1.get_noise_2d(x, z) + 0.35 * n2.get_noise_2d(x, z)
	y *= smoothstep(CH + 4.0, CH + 40.0, dz)
	# the hub around the control house stays level
	y *= smoothstep(14.0, 40.0, Vector2(x - HOUSE.x, z - HOUSE.z).length()) * 0.6 + 0.4 * smoothstep(CH + 4.0, CH + 40.0, dz)
	return y


func hash01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([lvl.level_seed, a, b, salt])) % 100003) / 100003.0


# ------------------------------------------------------------------ chunks

func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var meta := {"turbines": 0, "walls": 0}
	_terrain(ox, oz, node)
	var k := GeoKit.new(node, "Struct")
	if oz < ZC + CH + 2.0 and oz + CS > ZC - CH - 2.0:
		_channel(k, ox, oz, node)
	if cx == -1 and cz == -1:
		_barrier(k)
	if Rect2(ox, oz, CS, CS).has_point(Vector2(HOUSE.x, HOUSE.z)):
		_house(k, node)
	# turbines on a jittered lattice; each one belongs to the chunk holding its base
	var i0 := floori(ox / LATTICE) - 1
	var j0 := floori(oz / LATTICE) - 1
	for j in range(j0, j0 + 3):
		for i in range(i0, i0 + 3):
			var p := Vector2(i * LATTICE + (hash01(i, j, 1) - 0.5) * 90.0, j * LATTICE + (hash01(i, j, 2) - 0.5) * 90.0)
			if not Rect2(ox, oz, CS, CS).has_point(p):
				continue
			if absf(p.y - ZC) < CH + 22.0 or p.distance_to(Vector2(20, 0)) < 70.0 or p.distance_to(Vector2(BX, ZC)) < 80.0 or p.distance_to(Vector2(HOUSE.x, HOUSE.z)) < 60.0:
				continue
			if hash01(i, j, 3) < 0.18:
				continue
			_turbine(k, node, Vector3(p.x, h(p.x, p.y), p.y), hash01(i, j, 4), hash01(i, j, 5))
			meta["turbines"] += 1
	# stray flood-wall segments (structures of unknown purpose)
	if hash01(cx, cz, 7) < 0.42 and Vector2(ox + 48 - 20, oz + 48).length() > 90.0:
		var c := Vector2(ox + 20.0 + hash01(cx, cz, 8) * 56.0, oz + 20.0 + hash01(cx, cz, 9) * 56.0)
		if absf(c.y - ZC) > CH + 14.0:
			_flood_wall(k, node, c, hash01(cx, cz, 10), hash01(cx, cz, 11))
			meta["walls"] += 1
	k.commit()
	_tufts(ox, oz, node)
	return meta


func _terrain(ox: float, oz: float, node: Node3D) -> void:
	var step := 3.0
	var n := 33
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for gz in n:
		for gx in n:
			var x := ox + gx * step
			var z := oz + gz * step
			var nrm := Vector3(h(x - 1, z) - h(x + 1, z), 2.0, h(x, z - 1) - h(x, z + 1)).normalized()
			st.set_normal(nrm)
			st.set_uv(Vector2(x, z))
			st.add_vertex(Vector3(x, h(x, z), z))
	for gz in n - 1:
		for gx in n - 1:
			var z0 := oz + gz * step
			if z0 + step > ZC - CH and z0 < ZC + CH:
				continue
			var a := gz * n + gx
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + n)
			st.add_index(a + 1)
			st.add_index(a + n + 1)
			st.add_index(a + n)
	var mi := MeshInstance3D.new()
	mi.name = "Plain"
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l965_grass")
	node.add_child(mi)
	var md := PackedFloat32Array()
	md.resize(97 * 97)
	for j in 97:
		for i in 97:
			md[j * 97 + i] = h(ox + i, oz + j)
	var sh := HeightMapShape3D.new()
	sh.map_width = 97
	sh.map_depth = 97
	sh.map_data = md
	var body := StaticBody3D.new()
	body.name = "Ground"
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + 48.0, 0.0, oz + 48.0)
	cs.set_meta("surface", "grass")
	body.add_child(cs)
	node.add_child(body)


func _make_tuft() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := RandomNumberGenerator.new()
	r.seed = 965
	for b in 7:
		var a := r.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * 0.018
		var base := d * r.randf_range(0.0, 0.06)
		var tip := base + d * r.randf_range(0.05, 0.16) + Vector3.UP * r.randf_range(0.22, 0.42)
		var nrm := Vector3(d.x, 0.6, d.z).normalized()
		for v in [base - side, base + side, tip]:
			st.set_normal(nrm)
			st.set_color(Color(0.0, 0, 0) if v.y < 0.01 else Color(1, 1, 1))
			st.add_vertex(v)
	return st.commit()


func _tufts(ox: float, oz: float, node: Node3D) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tuft_mesh
	var pts: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, ox, oz, 33])
	for i in 4200:
		var x := ox + r.randf() * CS
		var z := oz + r.randf() * CS
		if absf(z - ZC) < CH + 1.5:
			continue
		if Vector2(x - HOUSE.x, z - HOUSE.z).length() < 7.0:
			continue
		var s := r.randf_range(0.8, 1.7)
		pts.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.7, 1.3), s)), Vector3(x, h(x, z) - 0.02, z)))
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, pts[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "Tufts"
	mi.multimesh = mm
	mi.material_override = MatLib.get_mat("l965_tuft")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 42.0
	mi.visibility_range_end_margin = 10.0
	node.add_child(mi)


# ------------------------------------------------------------------ channel

func _channel(k: GeoKit, ox: float, oz: float, node: Node3D) -> void:
	var x0 := ox
	var x1 := ox + CS
	var zs := ZC - CH
	var zn := ZC + CH
	k.slab(x0, zs + 1.0, x1, zn - 1.0, FLOOR_Y, 0.5, "l965_bed")
	# revetment walls: inner face at +/- 28.6, top flush with the plain plus a kerb
	for side in [-1.0, 1.0]:
		var zw: float = ZC + side * (CH - 0.7)
		k.box(Vector3((x0 + x1) * 0.5, (FLOOR_Y + 0.05) * 0.5, zw), Vector3(CS, -FLOOR_Y + 0.05, 1.4), "l965_concrete")
		k.box(Vector3((x0 + x1) * 0.5, 0.15, ZC + side * (CH - 0.15)), Vector3(CS, 0.3, 0.3), "l965_concrete_dark", GeoKit.ALL, false)
		# expansion joints and drain outlets every 12 m
		var x := x0 + 6.0
		while x < x1:
			k.box(Vector3(x, FLOOR_Y * 0.5, ZC + side * (CH - 1.42)), Vector3(0.12, -FLOOR_Y, 0.06), "l965_concrete_dark", GeoKit.ALL, false)
			x += 12.0
		x = x0 + 9.0 + (0.0 if side < 0 else 24.0)
		while x < x1:
			k.box(Vector3(x, FLOOR_Y + 1.1, ZC + side * (CH - 1.5)), Vector3(0.9, 0.9, 0.2), "l965_steel_dark", GeoKit.ALL, false)
			x += 48.0
	# low concrete bollards along both banks
	for side in [-1.0, 1.0]:
		var bxp := x0 + 3.0
		while bxp < x1:
			k.box(Vector3(bxp, 0.45, ZC + side * (CH + 1.3)), Vector3(0.35, 0.9, 0.35), "l965_concrete", GeoKit.ALL, false)
			bxp += 9.0
	# stairs down into the channel along the south wall, landing at plain level
	var sx := ox + 24.0
	var szw := ZC + CH - 1.4 - 0.9
	k.stairs(Vector3(sx, FLOOR_Y, szw), Vector3(-1, 0, 0), 1.6, -FLOOR_Y, 22, "l965_concrete", 0.28, true)
	k.box(Vector3(sx - 22 * 0.28 - 0.9, -0.15, szw), Vector3(1.8, 0.3, 1.6), "l965_concrete")
	# mirrored on the north wall
	var nx := ox + 70.0
	var nzw := ZC - CH + 1.4 + 0.9
	k.stairs(Vector3(nx, FLOOR_Y, nzw), Vector3(1, 0, 0), 1.6, -FLOOR_Y, 22, "l965_concrete", 0.28, true)
	k.box(Vector3(nx + 22 * 0.28 + 0.9, -0.15, nzw), Vector3(1.8, 0.3, 1.6), "l965_concrete")
	# lifebuoy posts on the banks
	for p in [Vector3(sx - 9.0, 0.0, ZC + CH + 1.2), Vector3(nx + 9.0, 0.0, ZC - CH - 1.2)]:
		k.box(p + Vector3(0, 0.75, 0), Vector3(0.12, 1.5, 0.12), "l965_steel_dark", GeoKit.ALL, false)
		var lb = Props.place(lvl, node, "ph/lifebuoy", p + Vector3(0, 0.55, 0.0 if p.z < ZC else 0.0), 0.0 if p.z > ZC else 180.0)
		grey(lb)
	# a still, shallow grey stream in the middle of the bed
	var w := WaterVolume.new()
	node.add_child(w)
	w.setup(Vector3(x0, FLOOR_Y - 0.4, ZC - 7.0), Vector3(x1, FLOOR_Y + 0.22, ZC + 7.0), "l965_water", true)
	# silt and a little debris in the bed
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, ox, 77])
	for i in 3:
		var id: String = ["ph/old_tyre", "ph/barrel_03", "ph/concrete_road_barrier", "ph/wooden_crate_01"][r.randi() % 4]
		var pz := ZC + r.randf_range(-24.0, 24.0)
		if absf(pz - ZC) < 8.0:
			pz += 9.0 * signf(pz - ZC + 0.01)
		grey(Props.place(lvl, node, id, Vector3(x0 + r.randf() * CS, FLOOR_Y, pz), r.randf() * 360.0))


func _barrier(k: GeoKit) -> void:
	# five hooded piers across the channel; sector gates lie on the bed between
	var pz := [-68.0, -58.0, -48.0, -38.0, -28.0]
	for z in pz:
		k.box(Vector3(BX, FLOOR_Y + 5.0, z), Vector3(18.0, 10.0, 4.0), "l965_concrete")
		k.box(Vector3(BX - 9.6, FLOOR_Y + 3.0, z), Vector3(1.4, 6.0, 2.6), "l965_concrete")
		k.box(Vector3(BX + 9.6, FLOOR_Y + 3.0, z), Vector3(1.4, 6.0, 2.6), "l965_concrete")
		_hood(k, Vector3(BX - 1.0, FLOOR_Y + 10.0, z))
	for i in pz.size() - 1:
		var gz: float = (pz[i] + pz[i + 1]) * 0.5
		k.box(Vector3(BX - 2.0, FLOOR_Y + 0.35, gz), Vector3(3.2, 0.7, 6.0), "l965_steel_dark")
		k.box(Vector3(BX - 0.2, FLOOR_Y + 0.9, gz), Vector3(0.5, 1.8, 6.0), "l965_steel")
	# service walkway on the pier tops (third height), reached by a stair tower
	var wx := BX + 7.8
	var top := FLOOR_Y + 10.0
	k.box(Vector3(wx, top + 0.1, -45.0), Vector3(2.2, 0.2, 60.0), "l965_steel_grate")
	for side in [-1.0, 1.0]:
		k.box(Vector3(wx + side * 1.05, top + 1.15, -45.0), Vector3(0.06, 0.06, 60.0), "l965_steel", GeoKit.ALL, true)
		k.box(Vector3(wx + side * 1.05, top + 0.7, -45.0), Vector3(0.05, 0.05, 60.0), "l965_rail_ghost", GeoKit.ALL, true)
		var z := -75.0
		while z <= -15.0:
			k.box(Vector3(wx + side * 1.05, top + 0.6, z), Vector3(0.07, 1.1, 0.07), "l965_steel", GeoKit.ALL, false)
			z += 2.5
	# stair from the south bank (plain level) up to the walkway
	var rise := top + 0.2
	var steps := int(round(rise / 0.18))
	k.stairs(Vector3(wx, 0.0, 3.0), Vector3(0, 0, -1), 1.8, rise, steps, "l965_concrete", 0.27, true)
	var stair_end := 3.0 - steps * 0.27
	k.box(Vector3(wx, top + 0.1, (stair_end + -15.0) * 0.5), Vector3(2.2, 0.2, absf(stair_end + 15.0)), "l965_steel_grate")
	for side in [-1.0, 1.0]:
		k.box(Vector3(wx + side * 1.0, rise * 0.5 + 0.55, (3.0 + stair_end) * 0.5), Vector3(0.06, 0.06, steps * 0.27), "l965_steel", GeoKit.ALL, false)
	# columns carrying the access deck from the stair head to the first pier
	for cz in [-8.0, -16.0]:
		k.box(Vector3(wx, top * 0.5, cz), Vector3(1.0, top, 1.0), "l965_concrete")
	k.box(Vector3(wx, (FLOOR_Y + top) * 0.5, -23.0), Vector3(1.0, top - FLOOR_Y, 1.0), "l965_concrete")
	k.box(Vector3(wx, top - 0.35, -16.0), Vector3(1.6, 0.5, 20.0), "l965_concrete_dark", GeoKit.ALL, false)
	# headwalls of the barrier on both banks
	for side in [-1.0, 1.0]:
		k.box(Vector3(BX, 1.6, ZC + side * (CH + 3.0)), Vector3(22.0, 3.2, 6.0), "l965_concrete")
		k.box(Vector3(BX - 4.0, 4.4, ZC + side * (CH + 3.0)), Vector3(9.0, 2.6, 5.0), "l965_concrete_dark")


func _hood(k: GeoKit, base: Vector3) -> void:
	# curved steel shell over a pier: a stepped arc along the flow axis
	var n := 16
	var length := 14.0
	var hgt := 5.5
	var prev := Vector3(base.x - length * 0.5, base.y, base.z)
	for i in range(1, n + 1):
		var t := float(i) / n
		var x := base.x - length * 0.5 + length * t
		var y := base.y + hgt * pow(sin(PI * pow(t, 0.8)), 0.9)
		var cur := Vector3(x, y, base.z)
		var mid := (prev + cur) * 0.5
		var dir := (cur - prev)
		var ang := atan2(dir.y, dir.x)
		var xf := Transform3D(Basis(Vector3.BACK, ang), mid)
		k.box_xf(xf, Vector3(dir.length() + 0.08, 0.3, 4.6), "l965_steel", GeoKit.ALL, false)
		prev = cur
	for side in [-1.0, 1.0]:
		k.box(Vector3(base.x, base.y + 0.9, base.z + side * 2.2), Vector3(length * 0.9, 1.8, 0.2), "l965_steel_dark", GeoKit.ALL, false)
	for rx in [-3.5, 0.0, 3.5]:
		var t: float = (rx + length * 0.5) / length
		var ry: float = hgt * pow(sin(PI * pow(t, 0.8)), 0.9)
		k.box(Vector3(base.x + rx, base.y + ry * 0.5, base.z), Vector3(0.25, ry, 4.4), "l965_steel_dark", GeoKit.ALL, false)
	k.box(Vector3(base.x + 0.4, base.y + hgt + 0.6, base.z), Vector3(0.4, 1.2, 0.3), "l965_steel_dark", GeoKit.ALL, false)


# ------------------------------------------------------------------ turbines

func _turbine(k: GeoKit, node: Node3D, base: Vector3, a: float, b: float) -> void:
	var tower := 58.0 + a * 16.0
	k.cylinder(base + Vector3(0, 0.6, 0), 6.0, 1.6, "l965_concrete", 16)
	k.stairs(base + Vector3(0, 0.0, 9.6), Vector3(0, 0, -1), 1.6, 1.4, 8, "l965_concrete", 0.45, true)
	k.box(base + Vector3(0, 1.45, 7.0), Vector3(1.8, 0.1, 1.6), "l965_concrete_dark", GeoKit.ALL, false)
	var segs := 6
	for s in segs:
		var t0 := float(s) / segs
		var r := lerpf(2.1, 1.35, t0)
		var hseg := tower / segs
		k.cylinder(base + Vector3(0, 1.4 + hseg * (s + 0.5), 0), r, hseg + 0.02, "l965_tower", 14, s == 0)
	k.box(base + Vector3(0, 2.6, 2.1), Vector3(1.0, 2.2, 0.16), "l965_steel_dark", GeoKit.ALL, false)
	var yaw := a * TAU
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	var top := base + Vector3(0, 1.4 + tower, 0)
	var nac := Transform3D(Basis(Vector3.UP, yaw), top + Vector3(0, 1.6, 0) - fwd * 1.5)
	k.box_xf(nac, Vector3(3.4, 3.4, 10.0), "l965_tower", GeoKit.ALL, false)
	var hub := top + Vector3(0, 1.6, 0) + fwd * 4.2
	k.box_xf(Transform3D(Basis(Vector3.UP, yaw), hub), Vector3(2.6, 2.6, 2.4), "l965_tower", GeoKit.ALL, false)
	var phase := b * TAU
	var missing := 0 if b < 0.22 else -1
	for bl in 3:
		if bl == missing:
			continue
		var ang := phase + bl * TAU / 3.0
		_blade(k, hub + fwd * 0.6, yaw, ang, 30.0)
	if missing >= 0:
		# the lost blade lies in the grass, half sunk, beside the pad
		var gx := base + Vector3(cos(yaw + 1.2) * 22.0, 0, sin(yaw + 1.2) * 22.0)
		gx.y = h(gx.x, gx.z) + 0.6
		var bas := Basis(Vector3.UP, yaw + 0.7) * Basis(Vector3.FORWARD, 0.06)
		for i in 6:
			var t := float(i) / 6.0
			var c := gx + bas.x * (t * 28.0 - 14.0)
			k.box_xf(Transform3D(bas, c), Vector3(4.8, lerpf(0.9, 0.35, t), lerpf(2.6, 0.9, t)), "l965_tower", GeoKit.ALL, i < 3)


func _blade(k: GeoKit, hub: Vector3, yaw: float, ang: float, length: float) -> void:
	var rot_basis := Basis(Vector3.UP, yaw)
	var axis := rot_basis.z
	var radial := (rot_basis * Basis(Vector3.BACK, ang)).x
	var n := 6
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var chord := lerpf(2.6, 0.7, t0) * (0.75 if i == 0 else 1.0)
		var c := hub + radial * (1.2 + length * (t0 + t1) * 0.5)
		var bas := Basis(radial, axis.cross(radial).normalized(), axis).orthonormalized()
		bas = bas * Basis(Vector3.RIGHT, 0.25 * (1.0 - t0))
		k.box_xf(Transform3D(bas, c), Vector3(length / n + 0.05, chord, 0.32 * (1.0 - t0 * 0.6)), "l965_tower", GeoKit.ALL, false)


# ------------------------------------------------------------------ walls

func _flood_wall(k: GeoKit, node: Node3D, c: Vector2, a: float, b: float) -> void:
	var length := 30.0 + a * 50.0
	var hgt := 2.2 + b * 1.4
	var along_x := a < 0.5
	var dir := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
	var p0 := Vector3(c.x, 0, c.y) - dir * length * 0.5
	var p1 := Vector3(c.x, 0, c.y) + dir * length * 0.5
	var y0 := minf(h(p0.x, p0.z), h(p1.x, p1.z)) - 0.6
	var g := length * (0.3 + b * 0.4)
	var openings := [{"at": g, "w": 4.2, "h": 2.0, "sill": 0.6}]
	k.wall(p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0), hgt + 0.6, 0.8, "l965_concrete", openings)
	# a buttress every 8 m and a coping strip
	var t := 4.0
	while t < length:
		if absf(t - g) > 3.0:
			var p := p0 + dir * t
			var off := Vector3(dir.z, 0, dir.x) * 0.75
			k.box(p + off + Vector3(0, y0 + hgt * 0.4, 0), Vector3(0.5 if along_x else 0.9, hgt * 0.8, 0.9 if along_x else 0.5), "l965_concrete")
		t += 8.0
	k.box((p0 + p1) * 0.5 + Vector3(0, y0 + hgt + 0.65, 0), Vector3(length if along_x else 1.0, 0.1, 1.0 if along_x else length), "l965_concrete_dark", GeoKit.ALL, false)
	# a rusted stop-log frame in the opening
	var gp := p0 + dir * g + Vector3(0, y0, 0)
	for s in [-1.0, 1.0]:
		k.box(gp + dir * (2.15 * s) + Vector3(0, 1.6, 0), Vector3(0.25, 2.2, 0.25) if along_x else Vector3(0.25, 2.2, 0.25), "l965_steel_dark", GeoKit.ALL, false)
	k.box(gp + Vector3(0, 2.65, 0), Vector3(4.5, 0.25, 0.25) if along_x else Vector3(0.25, 0.25, 4.5), "l965_steel_dark", GeoKit.ALL, false)
	grey(Props.place(lvl, node, "ph/concrete_road_barrier", Vector3(c.x, 0, c.y) + Vector3(dir.z, 0, dir.x) * 3.0 + dir * 7.0 + Vector3(0, h(c.x, c.y) - 0.05, 0), 90.0 if along_x else 0.0, 0.0, true))


# ------------------------------------------------------------------ house

func _house(k: GeoKit, node: Node3D) -> void:
	var c := HOUSE
	var w := 9.0
	var d := 7.0
	var hh := 3.2
	k.slab(c.x - w * 0.5 - 1.2, c.z - d * 0.5 - 1.2, c.x + w * 0.5 + 1.2, c.z + d * 0.5 + 1.2, 0.3, 0.9, "l965_concrete")
	k.slab(c.x - w * 0.5 + 0.2, c.z - d * 0.5 + 0.2, c.x + w * 0.5 - 0.2, c.z + d * 0.5 - 0.2, 0.32, 0.05, "l965_floor")
	var y := 0.3
	var a := Vector3(c.x - w * 0.5, y, c.z - d * 0.5)
	var b := Vector3(c.x + w * 0.5, y, c.z - d * 0.5)
	var cc := Vector3(c.x + w * 0.5, y, c.z + d * 0.5)
	var dd := Vector3(c.x - w * 0.5, y, c.z + d * 0.5)
	k.wall(a, b, hh, 0.25, "l965_render", [{"at": 3.0, "w": 2.4, "h": 1.3, "sill": 1.0}, {"at": 6.4, "w": 2.4, "h": 1.3, "sill": 1.0}])
	k.wall(b, cc, hh, 0.25, "l965_render", [{"at": 3.5, "w": 1.0, "h": 2.1, "sill": 0.0}])
	k.wall(cc, dd, hh, 0.25, "l965_render", [{"at": 4.5, "w": 1.6, "h": 1.1, "sill": 1.2}])
	k.wall(dd, a, hh, 0.25, "l965_render")
	k.slab(c.x - w * 0.5 - 0.4, c.z - d * 0.5 - 0.4, c.x + w * 0.5 + 0.4, c.z + d * 0.5 + 0.4, y + hh + 0.3, 0.3, "l965_concrete")
	k.slab(c.x - w * 0.5 + 0.13, c.z - d * 0.5 + 0.13, c.x + w * 0.5 - 0.13, c.z + d * 0.5 - 0.13, y + hh + 0.01, 0.02, "l965_ceiling", GeoKit.NY)
	# glazing (non-colliding thin panes) and a door left ajar
	for wp in [Vector3(c.x - w * 0.5 + 3.0, y + 1.65, c.z - d * 0.5), Vector3(c.x - w * 0.5 + 6.4, y + 1.65, c.z - d * 0.5)]:
		k.box(wp, Vector3(2.4, 1.3, 0.03), "l965_glass", GeoKit.ALL, false)
	k.box(Vector3(c.x + w * 0.5 - 0.6, y + 1.05, c.z + 0.53), Vector3(0.95, 2.1, 0.05), "l965_steel_dark", GeoKit.ALL, true)
	# outside: step, a security light, a power box, a utility cabinet
	k.box(Vector3(c.x + w * 0.5 + 1.75, 0.075, c.z), Vector3(1.0, 0.15, 1.8), "l965_concrete")
	grey(Props.place(lvl, node, "ph/security_light", Vector3(c.x + w * 0.5 + 0.2, y + 2.6, c.z - d * 0.5 + 2.2), 90.0))
	grey(Props.place(lvl, node, "ph/power_box_01", Vector3(c.x + w * 0.5 + 0.25, y + 1.2, c.z + 2.4), 90.0))
	grey(Props.place(lvl, node, "ph/utility_box_01", Vector3(c.x + w * 0.5 + 1.6, 0.0, c.z + 2.8), 90.0, 0.0, true))
	grey(Props.place(lvl, node, "ph/exterior_aircon_unit", Vector3(c.x - w * 0.5 - 0.35, 0.35, c.z + 0.5), -90.0))
	# inside: clean, unused
	var fy := y + 0.02
	grey(Props.place(lvl, node, "ph/metal_office_desk", Vector3(c.x - 1.5, fy, c.z - d * 0.5 + 1.0), 180.0, 0.0, true))
	grey(Props.place(lvl, node, "ph/SchoolChair_01", Vector3(c.x - 1.4, fy, c.z - d * 0.5 + 2.0), 170.0))
	grey(Props.place(lvl, node, "ph/vintage_radio_transceiver", Vector3(c.x - 0.8, fy + 0.79, c.z - d * 0.5 + 0.8), 180.0))
	grey(Props.place(lvl, node, "ph/steel_frame_shelves_02", Vector3(c.x - w * 0.5 + 0.5, fy, c.z + 1.6), 90.0, 0.0, true))
	grey(Props.place(lvl, node, "ph/steel_frame_shelves_02", Vector3(c.x - w * 0.5 + 0.5, fy, c.z + 2.3), 90.0, 0.0, true))
	grey(Props.place(lvl, node, "ph/binder_notebook", Vector3(c.x - w * 0.5 + 0.5, fy + 1.1, c.z + 1.6), 90.0))
	grey(Props.place(lvl, node, "ph/plastic_crate_01", Vector3(c.x - w * 0.5 + 0.5, fy + 0.02, c.z + 2.3), 90.0))
	grey(Props.place(lvl, node, "ph/drawer_cabinet", Vector3(c.x + 2.6, fy, c.z + d * 0.5 - 0.45), 0.0, 0.0, true))
	grey(Props.place(lvl, node, "ph/korean_fire_extinguisher_01", Vector3(c.x + w * 0.5 - 0.35, fy, c.z - d * 0.5 + 2.5), -90.0))
	var clock = Props.place(lvl, node, "ph/wall_clock", Vector3(c.x - 1.5, y + 2.3, c.z - d * 0.5 + 0.16), 0.0)
	grey(clock)
	grey(Props.place(lvl, node, "ph/mounted_fluorescent_lights", Vector3(c.x, y + hh - 0.05, c.z), 0.0))
	grey(Props.place(lvl, node, "ph/clipboard", Vector3(c.x - 2.1, fy + 0.79, c.z - d * 0.5 + 1.1), 170.0))


# ------------------------------------------------------------------ grey props

## Desaturate an imported model (Poly Haven textures carry colour; this level
## has none outside the rainbow).
func grey(n: Node) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh:
			for s in mi.mesh.get_surface_count():
				var src := mi.get_active_material(s)
				mi.set_surface_override_material(s, _grey_of(src))
	for ch in n.get_children():
		grey(ch)


func _grey_of(src: Material) -> Material:
	var key := src.get_instance_id() if src else 0
	if _grey_cache.has(key):
		return _grey_cache[key]
	var m := ShaderMaterial.new()
	m.shader = grey_shader
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		m.set_shader_parameter("tint", Vector3(b.albedo_color.r, b.albedo_color.g, b.albedo_color.b))
		if b.albedo_texture:
			m.set_shader_parameter("tex", b.albedo_texture)
			m.set_shader_parameter("has_tex", true)
		m.set_shader_parameter("rough", b.roughness)
		m.set_shader_parameter("metal", b.metallic)
	else:
		m.set_shader_parameter("tint", Vector3(0.5, 0.5, 0.5))
	_grey_cache[key] = m
	return m
