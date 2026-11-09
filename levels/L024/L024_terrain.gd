extends RefCounted
## Level 24 terrain: the painted plastic Moon of the model. One height function
## (craters, road, two sites) feeds the render meshes, the collision and the props.
## Layout is authored: the B.N.T.G. PlasticWorks site round x = +320 and the ruined
## Bluehole 1.3 km down the road at x = -1000 (the page: about 1 km apart).
## Vertex colour R = exposed plastic under the paint, G = road, B = blue-dyed plastic.

const PW := Rect2(170.0, -190.0, 300.0, 380.0)
const BH := Vector2(-1000.0, 0.0)
const BH_R := 10.0
const BH_FLOOR := -12.0
const POOL_Y := -10.4
const GATE := Vector3(300.0, 0.0, 0.0)
const COLUMNS := [Vector2(330.0, -110.0), Vector2(400.0, -95.0), Vector2(345.0, 110.0)]
const COL_HALF := 8.0
const COL_FLOOR := -8.0
const ROAD := [Vector2(-1000, 18), Vector2(-760, 40), Vector2(-480, -26), Vector2(-180, 20), Vector2(60, -12), Vector2(220, 0), Vector2(300, 0)]
const AREA := Rect2(-1150.0, -260.0, 1620.0, 520.0)

var n_base := FastNoiseLite.new()
var n_fine := FastNoiseLite.new()
var craters: Array = []        # [Vector2 c, float R]
var grid := {}                 # crater spatial hash: Vector2i -> [indices]


func _init() -> void:
	n_base.seed = 24
	n_base.frequency = 0.004
	n_base.fractal_octaves = 3
	n_fine.seed = 241
	n_fine.frequency = 0.08
	var r := RandomNumberGenerator.new()
	r.seed = 2424
	for i in 260:
		var c := Vector2(r.randf_range(-1400.0, 700.0), r.randf_range(-500.0, 500.0))
		var R := pow(r.randf(), 2.6) * 70.0 + 5.0
		if _road_d(c) < R + 8.0 or PW.grow(R + 10.0).has_point(c) or c.distance_to(BH) < 70.0 + R:
			continue
		craters.append([c, R])
	for i in craters.size():
		var c: Vector2 = craters[i][0]
		var R: float = craters[i][1]
		for gx in range(int(floor((c.x - R * 1.6) / 64.0)), int(floor((c.x + R * 1.6) / 64.0)) + 1):
			for gz in range(int(floor((c.y - R * 1.6) / 64.0)), int(floor((c.y + R * 1.6) / 64.0)) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				grid[key].append(i)


func _road_d(p: Vector2) -> float:
	var best := 1e9
	for i in ROAD.size() - 1:
		var a: Vector2 = ROAD[i]
		var b: Vector2 = ROAD[i + 1]
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + (b - a) * t))
	return best


func road_w(x: float, z: float) -> float:
	return 1.0 - smoothstep(3.2, 4.6, _road_d(Vector2(x, z)))


func _craters(x: float, z: float) -> float:
	var key := Vector2i(int(floor(x / 64.0)), int(floor(z / 64.0)))
	var y := 0.0
	for i in grid.get(key, []):
		var c: Vector2 = craters[i][0]
		var R: float = craters[i][1]
		var r := Vector2(x, z).distance_to(c) / R
		if r < 1.6:
			if r < 1.0:
				y -= R * 0.17 * (1.0 - r * r)
			y += R * 0.055 * exp(-pow((r - 1.0) / 0.22, 2.0))
	return y


## The benched mining columns at PlasticWorks: a square shaft with a ramp cut.
func _column(x: float, z: float) -> float:
	var y := 100.0
	for i in COLUMNS.size():
		var c: Vector2 = COLUMNS[i]
		var dx := absf(x - c.x) - COL_HALF
		var dz := absf(z - c.y) - COL_HALF
		var out := maxf(dx, dz)
		var pit := COL_FLOOR + maxf(out, 0.0) * 3.0
		# ramp cut descending westward (towards -x) along the north wall
		var along := c.x - COL_HALF - x
		var across := absf(z - (c.y - COL_HALF + 2.2))
		if along > -COL_HALF * 2.0 and along < 34.0 and across < 2.2:
			var ry := COL_FLOOR + maxf(along, 0.0) * 0.25 + maxf(across - 1.6, 0.0) * 3.0
			pit = minf(pit, ry)
		y = minf(y, pit)
	return y


func _bluehole(x: float, z: float, n: float) -> float:
	var d := Vector2(x, z).distance_to(BH)
	var wall := BH_R + 1.6 * n
	var pit := BH_FLOOR + maxf(d - wall, 0.0) * 2.4
	# miners' ramp from the west rim down to the shaft floor
	var along := BH.x - BH_R - x
	var across := absf(z - BH.y)
	if along > -BH_R and along < 32.0 and across < 2.4:
		pit = minf(pit, BH_FLOOR + maxf(along, 0.0) * 0.38 + maxf(across - 1.8, 0.0) * 3.0)
	return pit


func h(x: float, z: float) -> float:
	var y := 3.0 * n_base.get_noise_2d(x, z) + 0.18 * n_fine.get_noise_2d(x, z)
	var cr := _craters(x, z)
	var rw := road_w(x, z)
	var p := Vector2(x, z)
	# site pads: PlasticWorks and Bluehole are graded flat
	var pad := 0.0
	var dpw := maxf(maxf(PW.position.x - x, x - PW.end.x), maxf(PW.position.y - z, z - PW.end.y))
	pad = maxf(pad, 1.0 - smoothstep(-10.0, 30.0, dpw))
	pad = maxf(pad, 1.0 - smoothstep(60.0, 110.0, p.distance_to(BH)))
	y = lerpf(y + cr, 0.0, pad)
	y = lerpf(y, 3.0 * n_base.get_noise_2d(x, z) * (1.0 - pad), rw * 0.9)
	if x > 150.0 and x < 480.0:
		y = minf(y, _column(x, z))
	if p.distance_to(BH) < 60.0:
		y = minf(y, _bluehole(x, z, n_fine.get_noise_2d(x * 2.0, z * 2.0)))
	return y


## Colour channels for the shader.
func tint(x: float, z: float, y: float) -> Color:
	var plastic := smoothstep(-1.5, -4.0, y)
	var blue := 0.0
	if Vector2(x, z).distance_to(BH) < 40.0:
		blue = smoothstep(-6.0, -10.0, y)
	return Color(plastic, road_w(x, z), blue)


# ------------------------------------------------------------------ meshes

static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D grain : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grain_n : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float g = texture(grain, wpos.xz / 3.0).r * 0.6 + texture(grain, wpos.xz / 23.0).g * 0.4;
	float macro = texture(grain, wpos.xz / 190.0).b;
	vec3 paint = vec3(0.42, 0.42, 0.41) * (0.78 + 0.32 * g) * (0.85 + 0.25 * macro);
	vec3 plastic = vec3(0.66, 0.62, 0.58) * (0.9 + 0.12 * g);
	vec3 blue = vec3(0.12, 0.3, 0.62) * (0.85 + 0.2 * g);
	vec3 road = vec3(0.3, 0.3, 0.3) * (0.8 + 0.3 * g);
	vec3 alb = mix(paint, road, COLOR.g * 0.8);
	alb = mix(alb, plastic, COLOR.r);
	alb = mix(alb, blue, COLOR.b);
	ALBEDO = alb;
	ROUGHNESS = mix(0.62, 0.32, max(COLOR.r, COLOR.b));
	SPECULAR = 0.45;
	NORMAL_MAP = texture(grain_n, wpos.xz / 3.0).rgb;
	NORMAL_MAP_DEPTH = 0.5;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	var a := "res://assets/external/concrete/concrete_%s_1k.jpg"
	if ResourceLoader.exists(a % "diff"):
		m.set_shader_parameter("grain", load(a % "diff"))
	if ResourceLoader.exists(a % "nor_gl"):
		m.set_shader_parameter("grain_n", load(a % "nor_gl"))
	return m


## Grid mesh over a rect at a given step, skipping cells inside any hole rect.
func grid_mesh(r: Rect2, step: float, holes: Array, far := false) -> ArrayMesh:
	var nx := int(round(r.size.x / step)) + 1
	var nz := int(round(r.size.y / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := r.position.x + ix * step
			var z := r.position.y + iz * step
			hs[iz * nx + ix] = (h(x, z) if not far or AREA.has_point(Vector2(x, z)) else _far_h(x, z)) - (0.25 if far else 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var x := r.position.x + ix * step
			var z := r.position.y + iz * step
			var y := hs[iz * nx + ix]
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_color(tint(x, z, y) if not far else Color(0, 0, 0))
			st.add_vertex(Vector3(x, y, z))
	for iz in nz - 1:
		for ix in nx - 1:
			var cx := r.position.x + (ix + 0.5) * step
			var cz := r.position.y + (iz + 0.5) * step
			var skip := false
			for hole in holes:
				if (hole as Rect2).has_point(Vector2(cx, cz)):
					skip = true
					break
			if skip:
				continue
			var a := iz * nx + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


func _far_h(x: float, z: float) -> float:
	return 3.0 * n_base.get_noise_2d(x, z) + _craters(x, z) + 14.0 * n_base.get_noise_2d(x * 0.15 + 900.0, z * 0.15)


func build_meshes(parent: Node3D, mat: Material) -> void:
	var fine_pw := Rect2(PW.position - Vector2(20, 20), PW.size + Vector2(40, 40))
	var fine_bh := Rect2(BH - Vector2(80, 80), Vector2(160, 160))
	var specs := [[AREA, 4.0, [fine_pw, fine_bh], false, "Plain"], [fine_pw, 1.5, [], false, "PlasticWorksGround"],
		[fine_bh, 1.25, [], false, "BlueholeGround"], [Rect2(-7000, -6000, 13000, 12000), 96.0, [AREA.grow(-8.0)], true, "FarSurface"]]
	for s in specs:
		var mi := MeshInstance3D.new()
		mi.name = s[4]
		mi.mesh = grid_mesh(s[0], s[1], s[2], s[3])
		mi.material_override = mat
		if s[3]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)


## 1 m HeightMapShape3D tiles over the walkable area, sampled from a 2 m height cache.
func build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "MoonGround"
	parent.add_child(body)
	var t := 64
	var x0 := AREA.position.x + 8.0
	var z0 := AREA.position.y + 8.0
	var ntx := int((AREA.size.x - 16.0) / t)
	var ntz := int((AREA.size.y - 16.0) / t)
	for tz in ntz:
		for tx in ntx:
			var ox := x0 + tx * t
			var oz := z0 + tz * t
			var fine := PW.grow(30.0).intersects(Rect2(ox, oz, t, t)) or Rect2(BH - Vector2(70, 70), Vector2(140, 140)).intersects(Rect2(ox, oz, t, t))
			var md := PackedFloat32Array()
			md.resize((t + 1) * (t + 1))
			var st := 1 if fine else 2
			var coarse := {}
			for j in range(0, t + 1, st):
				for i in range(0, t + 1, st):
					coarse[Vector2i(i, j)] = h(ox + i, oz + j)
			for j in t + 1:
				for i in t + 1:
					if st == 1:
						md[j * (t + 1) + i] = coarse[Vector2i(i, j)]
					else:
						var i0 := (i / 2) * 2
						var j0 := (j / 2) * 2
						var i1 := mini(i0 + 2, t)
						var j1 := mini(j0 + 2, t)
						var fx := float(i - i0) / 2.0
						var fz := float(j - j0) / 2.0
						var a: float = coarse[Vector2i(i0, j0)]
						var b: float = coarse[Vector2i(i1, j0)]
						var c: float = coarse[Vector2i(i0, j1)]
						var d: float = coarse[Vector2i(i1, j1)]
						md[j * (t + 1) + i] = lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)
			var sh := HeightMapShape3D.new()
			sh.map_width = t + 1
			sh.map_depth = t + 1
			sh.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = sh
			cs.position = Vector3(ox + t * 0.5, 0.0, oz + t * 0.5)
			cs.set_meta("surface", "concrete")
			body.add_child(cs)


## Points along the road (for marker poles), every `every` metres.
func road_points(every: float) -> Array:
	var out: Array = []
	for i in ROAD.size() - 1:
		var a: Vector2 = ROAD[i]
		var b: Vector2 = ROAD[i + 1]
		var n := int((b - a).length() / every)
		for k in n:
			var p := a.lerp(b, float(k) / n)
			var dir := (b - a).normalized()
			out.append([p, dir])
	return out
