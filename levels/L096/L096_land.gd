extends RefCounted
## Level 96 land: the ledge the house stands on, the valley below it and the
## "vast ranges of mountains" it overlooks (SOURCE fact 11). Everything here is
## an in-project mesh: a stretched heightfield (fine near the house, coarse at
## the horizon), two far ridge rings fading into the evening haze, cypress and
## stone-pine silhouettes, and scattered scrub trees on the slopes.
## ADAPTATION: the page gives no map; the ledge, valley and ridge layout are ours.
## No buildings, roads or people are placed in the landscape (the page shows none).

const PLATEAU := Rect2(-19.0, -12.0, 38.0, 29.0)   # garden ledge (x, z), top y = GARDEN_Y
const GARDEN_Y := -0.45
const N := 181
const EXTENT := 2600.0
const STRETCH := 4.4
const TERRAIN_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wp;
varying vec3 wn;
float hh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hh(i), hh(i + vec2(1, 0)), f.x), mix(hh(i + vec2(0, 1)), hh(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { s += a * vn(p); p = p * 2.03 + 7.1; a *= 0.5; } return s; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float steep = 1.0 - wn.y;
	float n = vn(wp.xz * 0.05);
	vec3 valley = mix(vec3(0.17, 0.2, 0.1), vec3(0.24, 0.24, 0.13), n);
	vec3 scrub = mix(vec3(0.22, 0.22, 0.13), vec3(0.16, 0.19, 0.09), n);
	vec3 rock = mix(vec3(0.5, 0.45, 0.37), vec3(0.42, 0.38, 0.31), n);
	vec3 c = mix(valley, scrub, smoothstep(-120.0, 40.0, wp.y));
	c = mix(c, rock, clamp(smoothstep(0.4, 0.85, steep) + smoothstep(250.0, 600.0, wp.y) * 0.6, 0.0, 1.0));
	c = mix(c, vec3(0.7, 0.67, 0.6), smoothstep(650.0, 1000.0, wp.y) * 0.8);
	float dist = length(wp - CAMERA_POSITION_WORLD);
	float veg = smoothstep(0.4, 0.6, fbm(wp.xz * 0.035 + 3.0)) * (1.0 - smoothstep(0.35, 0.7, steep)) * (1.0 - smoothstep(350.0, 700.0, wp.y));
	c = mix(c, vec3(0.09, 0.12, 0.05), veg * 0.75);
	float strata = 0.5 + 0.5 * sin(wp.y * 0.6 + fbm(wp.xz * 0.02) * 8.0);
	c *= mix(1.0, 0.8 + 0.28 * strata, smoothstep(0.45, 0.8, steep));
	c *= 0.7 + 0.6 * fbm(wp.xz * 0.012 + 1.7);
	c *= 0.82 + 0.36 * fbm(wp.xz * 0.25) * (1.0 - smoothstep(40.0, 260.0, dist));
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	ROUGHNESS = 1.0;
}
"""

var seed_i := 0
var lvl: Node3D


func _init(level: Node3D, level_seed: int) -> void:
	lvl = level
	seed_i = absi(level_seed) & 0x7FFFFF


func _hh(ix: int, iz: int, s: int) -> float:
	var n := (ix * 374761393 + iz * 668265263 + (s * 1442695041)) & 0xFFFFFFFF
	n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
	n = n ^ (n >> 16)
	return float(n & 0xFFFFFF) / 16777215.0


func vn(x: float, z: float, s: int) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	return lerpf(lerpf(_hh(ix, iz, s), _hh(ix + 1, iz, s), fx), lerpf(_hh(ix, iz + 1, s), _hh(ix + 1, iz + 1, s), fx), fz)


func ridged(x: float, z: float, s: int) -> float:
	var sum := 0.0
	var amp := 0.55
	var f := 1.0
	for o in 5:
		var v := 1.0 - absf(vn(x * f, z * f, s + o) * 2.0 - 1.0)
		sum += v * v * amp
		f *= 2.07
		amp *= 0.48
	return sum


## Ground height outside the built ledge. The world is fixed (the page describes
## one house and one view), so the landform does not depend on the seed.
func height(x: float, z: float) -> float:
	var dx := maxf(absf(x) - 19.5, 0.0)
	var dzf := maxf(-12.5 - z, 0.0)
	var dzb := maxf(z - 17.5, 0.0)
	var d := Vector2(dx, maxf(dzf, dzb)).length()
	var behind := smoothstep(-8.0, 70.0, z)
	# in front and to the sides: a steep scrub slope falling into the valley
	var drop := -1.2 - minf(d * 1.15 + d * d * 0.004, 170.0)
	# behind: the hillside the house is built against
	var rise := -1.2 + minf(d * 0.55 + d * d * 0.0012, 110.0)
	var base := lerpf(drop, rise, behind)
	var r := Vector2(x, z).length()
	var m := ridged(x * 0.0011 + 3.7, z * 0.0011 - 1.3, 11) * 1.0 + vn(x * 0.0004, z * 0.0004, 31) * 0.6
	var amp := smoothstep(380.0, 1500.0, r) * 760.0
	var hill := (vn(x * 0.02, z * 0.02, 41) - 0.5) * 6.0 * smoothstep(20.0, 60.0, d)
	return base + m * amp - smoothstep(300.0, 900.0, r) * 40.0 + hill


func _coord(i: int) -> float:
	var u := float(i) / float(N - 1) * 2.0 - 1.0
	return EXTENT * sinh(STRETCH * u) / sinh(STRETCH)


func _ground_color(h: float, slope: float, x: float, z: float) -> Color:
	var n := vn(x * 0.05, z * 0.05, 51)
	var valley := Color(0.17, 0.2, 0.1).lerp(Color(0.24, 0.24, 0.13), n)
	var scrub := Color(0.22, 0.22, 0.13).lerp(Color(0.16, 0.19, 0.09), n)
	var rock := Color(0.55, 0.49, 0.4).lerp(Color(0.46, 0.41, 0.34), n)
	var lime := Color(0.72, 0.68, 0.6)
	var c := valley.lerp(scrub, smoothstep(-120.0, 40.0, h))
	c = c.lerp(rock, clampf(smoothstep(0.45, 0.9, slope) + smoothstep(250.0, 600.0, h) * 0.6, 0.0, 1.0))
	c = c.lerp(lime, smoothstep(650.0, 1000.0, h) * 0.8)
	return c


func build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := PackedFloat32Array()
	hs.resize(N * N)
	var xs := PackedFloat32Array()
	xs.resize(N)
	for i in N:
		xs[i] = _coord(i)
	for j in N:
		for i in N:
			var x := xs[i]
			var z := xs[j]
			var h := height(x, z)
			if absf(x) < 19.6 and z > -12.6 and z < 17.6:
				h = GARDEN_Y - 0.8
			elif absf(x) < 8.6 and z > -20.6 and z <= -12.0:
				h = minf(h, -2.6)
			hs[j * N + i] = h
	for j in N:
		for i in N:
			var x := xs[i]
			var z := xs[j]
			var h := hs[j * N + i]
			var hx := hs[j * N + mini(i + 1, N - 1)] - hs[j * N + maxi(i - 1, 0)]
			var hz := hs[mini(j + 1, N - 1) * N + i] - hs[maxi(j - 1, 0) * N + i]
			var dxs := xs[mini(i + 1, N - 1)] - xs[maxi(i - 1, 0)]
			var dzs := xs[mini(j + 1, N - 1)] - xs[maxi(j - 1, 0)]
			var nrm := Vector3(-hx / dxs, 1.0, -hz / dzs).normalized()
			st.set_normal(nrm)
			st.set_color(_ground_color(h, 1.0 - nrm.y, x, z))
			st.set_uv(Vector2(x, z) * 0.1)
			st.add_vertex(Vector3(x, h, z))
	for j in N - 1:
		for i in N - 1:
			var a := j * N + i
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + N)
			st.add_index(a + 1)
			st.add_index(a + N + 1)
			st.add_index(a + N)
	var sh := Shader.new()
	sh.code = TERRAIN_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	var mi := MeshInstance3D.new()
	mi.name = "Valley"
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lvl.add_child(mi)


## Two far ridge rings close the horizon behind the heightfield.
func build_far_ridges() -> void:
	for ring in [[3600.0, 520.0, 1250.0, 61, Color(0.36, 0.33, 0.36)], [5400.0, 900.0, 1900.0, 71, Color(0.42, 0.40, 0.46)]]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segs := 220
		var rad: float = ring[0]
		for k in segs + 1:
			var a := TAU * float(k) / float(segs)
			var p := Vector3(cos(a), 0, sin(a)) * rad
			var top: float = lerpf(ring[1], ring[2], ridged(cos(a) * 3.0 + 10.0, sin(a) * 3.0, ring[3]))
			# the ridges behind the house (south, +z) stay lower so the hillside reads
			top *= lerpf(1.0, 0.55, smoothstep(0.2, 0.9, sin(a)))
			var nrm := -Vector3(cos(a), 0.0, sin(a))
			st.set_normal(nrm)
			st.set_color(ring[4] * 0.8)
			st.add_vertex(p + Vector3(0, -300.0, 0))
			st.set_normal(nrm)
			st.set_color(ring[4])
			st.add_vertex(p + Vector3(0, top, 0))
		for k in segs:
			var b := k * 2
			st.add_index(b)
			st.add_index(b + 1)
			st.add_index(b + 2)
			st.add_index(b + 1)
			st.add_index(b + 3)
			st.add_index(b + 2)
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 1.0
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := MeshInstance3D.new()
		mi.name = "FarRidge"
		mi.mesh = st.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lvl.add_child(mi)


## Lathe mesh from a (radius, y) profile. Used for cypresses, pines and pitchers.
static func lathe(profile: Array, sides: int, color: Color = Color.WHITE) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in profile.size() - 1:
		var r0: float = profile[p].x
		var y0: float = profile[p].y
		var r1: float = profile[p + 1].x
		var y1: float = profile[p + 1].y
		var slope := Vector2(y1 - y0, -(r1 - r0)).normalized()
		for k in sides:
			var a0 := TAU * float(k) / sides
			var a1 := TAU * float(k + 1) / sides
			var c0 := Vector3(cos(a0), 0, sin(a0))
			var c1 := Vector3(cos(a1), 0, sin(a1))
			var v := [c0 * r0 + Vector3.UP * y0, c1 * r0 + Vector3.UP * y0, c1 * r1 + Vector3.UP * y1, c0 * r1 + Vector3.UP * y1]
			var n := [(c0 * slope.x + Vector3.UP * slope.y).normalized(), (c1 * slope.x + Vector3.UP * slope.y).normalized()]
			var uv := [Vector2(a0 * 0.3, y0), Vector2(a1 * 0.3, y0), Vector2(a1 * 0.3, y1), Vector2(a0 * 0.3, y1)]
			for q in [0, 1, 2, 0, 2, 3]:
				st.set_color(color)
				st.set_normal(n[0] if q in [0, 3] else n[1])
				st.set_uv(uv[q])
				st.add_vertex(v[q])
	return st.commit()


var _cypress: ArrayMesh
var _pine_top: ArrayMesh
var _trunk: ArrayMesh
var _foliage: StandardMaterial3D
var _bark: StandardMaterial3D


func _tree_assets() -> void:
	if _cypress:
		return
	_cypress = lathe([Vector2(0.0, 0.0), Vector2(0.55, 0.5), Vector2(0.75, 2.5), Vector2(0.62, 5.0), Vector2(0.38, 7.2), Vector2(0.12, 8.6), Vector2(0.0, 9.0)], 10)
	_pine_top = lathe([Vector2(0.0, 0.2), Vector2(1.5, 0.0), Vector2(2.1, 0.35), Vector2(1.9, 0.8), Vector2(1.0, 1.15), Vector2(0.0, 1.25)], 9)
	_trunk = lathe([Vector2(0.2, 0.0), Vector2(0.14, 1.0), Vector2(0.1, 1.0)], 7)
	_foliage = StandardMaterial3D.new()
	_foliage.albedo_color = Color(0.15, 0.21, 0.09)
	_foliage.roughness = 1.0
	_bark = StandardMaterial3D.new()
	_bark.albedo_color = Color(0.25, 0.18, 0.12)
	_bark.roughness = 1.0


func cypress(pos: Vector3, h: float) -> void:
	_tree_assets()
	var mi := MeshInstance3D.new()
	mi.mesh = _cypress
	mi.material_override = _foliage
	mi.position = pos
	mi.scale = Vector3(h / 9.0 * 1.1, h / 9.0, h / 9.0 * 1.1)
	lvl.add_child(mi)


## Umbrella (stone) pine: a leaning trunk and a flat dark crown.
func stone_pine(pos: Vector3, h: float, lean: float, yaw: float) -> void:
	_tree_assets()
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = yaw
	lvl.add_child(root)
	var tr := MeshInstance3D.new()
	tr.mesh = _trunk
	tr.material_override = _bark
	tr.scale = Vector3(1.0, h, 1.0)
	tr.rotation.z = lean
	root.add_child(tr)
	var tip := Vector3(-sin(lean) * h, cos(lean) * h - 0.4, 0)
	# the crown: several flat, overlapping clumps on short branches
	var clumps := [[Vector3(0, 0, 0), 1.0], [Vector3(1.6, -0.5, 0.8), 0.7], [Vector3(-1.4, -0.4, -1.0), 0.75],
		[Vector3(0.4, -0.3, -1.8), 0.6], [Vector3(-0.9, 0.2, 1.5), 0.6], [Vector3(2.4, -0.8, -0.9), 0.5]]
	var k := 0
	for c in clumps:
		var s: float = c[1] * h / 7.5
		var top := MeshInstance3D.new()
		top.mesh = _pine_top
		top.material_override = _foliage
		top.position = tip + (c[0] as Vector3) * h / 7.5
		top.scale = Vector3(s * 1.15, s * 0.9, s)
		top.rotation.y = float(k) * 1.3
		root.add_child(top)
		if k > 0:
			var br := MeshInstance3D.new()
			br.mesh = _trunk
			br.material_override = _bark
			br.position = tip + Vector3(0, -0.6, 0)
			var dv: Vector3 = (c[0] as Vector3) * h / 7.5 + Vector3(0, 0.6, 0)
			br.scale = Vector3(0.45, dv.length(), 0.45)
			br.basis = Basis(Quaternion(Vector3.UP, dv.normalized())) * Basis.from_scale(Vector3(0.45, dv.length(), 0.45))
			root.add_child(br)
		k += 1


## Scrub and pines on the valley slopes, one MultiMesh (cheap distant cones).
func scatter_slopes() -> void:
	_tree_assets()
	var cone := SphereMesh.new()
	cone.radius = 1.8
	cone.height = 4.6
	cone.radial_segments = 7
	cone.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	var xfs: Array = []
	var near: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 9696
	var tries := 0
	while xfs.size() < 900 and tries < 9000:
		tries += 1
		var a := r.randf() * TAU
		var dist := lerpf(30.0, 700.0, pow(r.randf(), 1.6))
		var x := cos(a) * dist
		var z := sin(a) * dist
		if absf(x) < 24.0 and z > -16.0 and z < 22.0:
			continue
		var h := height(x, z)
		var hx := height(x + 2.0, z) - h
		var hz := height(x, z + 2.0) - h
		if Vector2(hx, hz).length() > 2.4 or h > 260.0:
			continue
		var cluster := vn(x * 0.03, z * 0.03, 71)
		if cluster < 0.45:
			continue
		var s := r.randf_range(0.6, 1.5) * (1.0 + dist / 500.0)
		if dist < 140.0:
			if near.size() < 70:
				near.append([Vector3(x, h - 0.6, z), s, r.randf() < 0.8])
			continue
		xfs.append(Transform3D(Basis.from_scale(Vector3(s, s * r.randf_range(0.8, 1.3), s)), Vector3(x, h + 0.7 * s, z)))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "SlopeScrub"
	mmi.multimesh = mm
	mmi.material_override = _foliage
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lvl.add_child(mmi)
	# nearer slopes: real cypress and pine silhouettes instead of blobs
	for t in near:
		if t[2]:
			cypress(t[0], 6.0 + float(t[1]) * 2.5)
		else:
			stone_pine(t[0], 5.5 + float(t[1]) * 2.0, (float(t[1]) - 1.0) * 0.2, float(t[1]) * 5.0)


## Garden shrubs: clusters of low dark-green bushes along walls and the house.
func shrubs(points: Array) -> void:
	_tree_assets()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 0.8
	sm.radial_segments = 8
	sm.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sm
	var r := RandomNumberGenerator.new()
	r.seed = 9601
	var xfs: Array = []
	for p in points:
		for i in 4:
			var s := r.randf_range(0.6, 1.3)
			var o := Vector3(r.randf_range(-0.7, 0.7), 0, r.randf_range(-0.7, 0.7))
			xfs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s * 1.2, s, s)), (p as Vector3) + o + Vector3(0, 0.22 * s, 0)))
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.17, 0.24, 0.1)
	mat.roughness = 1.0
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Shrubs"
	mmi.multimesh = mm
	mmi.material_override = mat
	lvl.add_child(mmi)
