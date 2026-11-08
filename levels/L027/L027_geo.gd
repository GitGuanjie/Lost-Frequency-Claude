extends RefCounted
## Level 27 geometry helpers: organic cave shells, heightfield floors, tunnels and
## falling-water ribbons written straight into a GeoKit (one mesh per material),
## with trimesh collision collected into PackedVector3Arrays.

const FALL_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(0.82, 0.92, 0.92);
uniform float speed = 1.0;
uniform float opacity = 0.85;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	float t = TIME * speed;
	float s = n2(vec2(UV.x * 11.0, UV.y * 3.0 - t * 3.2)) * 0.6 + n2(vec2(UV.x * 37.0, UV.y * 9.0 - t * 6.0)) * 0.4;
	float edge = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	ALBEDO = tint * (0.75 + 0.35 * s);
	ROUGHNESS = 0.08;
	SPECULAR = 0.7;
	EMISSION = tint * 0.05;
	ALPHA = clamp((0.25 + 0.75 * s) * edge, 0.0, 1.0) * opacity;
}
"""

static func poly(k: GeoKit, mat: String, pts: Array, n: Vector3) -> void:
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	var tu: Vector3 = (pts[1] - pts[0]).normalized()
	var tv: Vector3 = n.cross(tu).normalized()
	for q in pts:
		s["v"].append(q)
		s["n"].append(n)
		s["uv"].append(k._uv_for(q, n, tu, tv))
		s["uv2"].append(Vector2.ZERO)
	var flip: bool = (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(n) > 0.0
	for i in range(1, pts.size() - 1):
		if flip:
			s["i"].append_array([base, base + i + 1, base + i])
		else:
			s["i"].append_array([base, base + i, base + i + 1])
	k.stats["tris"] += pts.size() - 2


## Triangle facing `toward` (a direction or a point offset), also into the collision soup.
static func tri(k: GeoKit, mat: String, a: Vector3, b: Vector3, c: Vector3, toward: Vector3, faces: Variant) -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 1e-6:
		return
	n = n.normalized()
	if n.dot(toward) < 0.0:
		n = -n
	poly(k, mat, [a, b, c], n)
	if faces is Array:
		(faces as Array).append_array([a, b, c])


static func quad(k: GeoKit, mat: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, toward: Vector3, faces: Variant) -> void:
	tri(k, mat, a, b, c, toward, faces)
	tri(k, mat, a, c, d, toward, faces)


## Domed cave shell. Rows at fixed heights from y0 (step ystep) up to the apex; prof(y)
## scales the plan radius (1 at the walls, 0 at the apex). holes: [{a0, a1, y0, y1}]
## in radians / metres; quads inside a hole are skipped (tunnel mouths, sky hole).
static func shell(k: GeoKit, mat: String, c: Vector3, rx: float, rz: float, y0: float, rows: int, ystep: float,
		cols: int, prof: Callable, nz: FastNoiseLite, amp: float, holes: Array, faces: Array, mat_fn: Callable = Callable()) -> void:
	var grid: Array = []
	for j in rows + 1:
		var y := y0 + float(j) * ystep
		var f: float = prof.call(y)
		var row: Array = []
		for i in cols:
			var a := TAU * float(i) / cols
			var bx := cos(a) * rx
			var bz := sin(a) * rz
			var n := nz.get_noise_3d(bx * 0.6, y * 0.9, bz * 0.6) + 0.35 * nz.get_noise_3d(bx * 2.3, y * 2.1, bz * 2.3)
			var r := f * (1.0 + amp * n)
			row.append(c + Vector3(bx * r, y + amp * 0.6 * n * f, bz * r))
		grid.append(row)
	for j in rows:
		var ym := y0 + (float(j) + 0.5) * ystep
		for i in cols:
			var am := TAU * (float(i) + 0.5) / cols
			var skip := false
			for h in holes:
				var lo: float = h["a0"]
				var hi: float = h["a1"]
				var inside: bool = (am >= lo and am <= hi) or (am + TAU >= lo and am + TAU <= hi)
				if inside and ym >= float(h["y0"]) and ym <= float(h["y1"]):
					skip = true
			if skip:
				continue
			var i2 := (i + 1) % cols
			var p00: Vector3 = grid[j][i]
			var p10: Vector3 = grid[j][i2]
			var p01: Vector3 = grid[j + 1][i]
			var p11: Vector3 = grid[j + 1][i2]
			var axis := Vector3(c.x, ym, c.z)
			var m: String = mat if not mat_fn.is_valid() else str(mat_fn.call(ym))
			var cen := (p00 + p11) * 0.5
			quad(k, m, p00, p10, p11, p01, axis - cen, faces)


## Heightfield floor over [x0,x1]x[z0,z1]. h(x,z) -> y. mat_fn(y) -> material name.
## keep(x,z) -> false skips a cell (outside the walls).
static func heightfield(k: GeoKit, x0: float, z0: float, x1: float, z1: float, step: float, h: Callable,
		mat_fn: Callable, keep: Callable, faces: Array) -> void:
	var nx := int(ceil((x1 - x0) / step))
	var nzc := int(ceil((z1 - z0) / step))
	var ys: Array = []
	for j in nzc + 1:
		var row := PackedFloat32Array()
		for i in nx + 1:
			row.append(float(h.call(x0 + i * step, z0 + j * step)))
		ys.append(row)
	for j in nzc:
		for i in nx:
			var xa := x0 + i * step
			var za := z0 + j * step
			if keep.is_valid() and not keep.call(xa + step * 0.5, za + step * 0.5):
				continue
			var a := Vector3(xa, ys[j][i], za)
			var b := Vector3(xa + step, ys[j][i + 1], za)
			var cc := Vector3(xa + step, ys[j + 1][i + 1], za + step)
			var d := Vector3(xa, ys[j + 1][i], za + step)
			var m: String = mat_fn.call((a.y + b.y + cc.y + d.y) * 0.25)
			tri(k, m, a, b, cc, Vector3.UP, faces)
			tri(k, m, a, cc, d, Vector3.UP, faces)


## Tunnel along floor-centre points. Arched rough section (w x h per point); open ends.
## floor_mat paves the bottom; the arch uses mat. Returns nothing; collision into faces.
static func tube(k: GeoKit, mat: String, floor_mat: String, pts: Array, ws: Array, hs: Array, nz: FastNoiseLite,
		amp: float, faces: Array, segs: int = 9) -> void:
	var rings: Array = []
	for p in pts.size():
		var f: Vector3
		if p == 0:
			f = pts[1] - pts[0]
		elif p == pts.size() - 1:
			f = pts[p] - pts[p - 1]
		else:
			f = (pts[p + 1] - pts[p - 1])
		f.y = 0.0
		f = f.normalized()
		var r := f.cross(Vector3.UP).normalized()
		var w: float = ws[p]
		var hh: float = hs[p]
		var ring: Array = []
		for s in segs + 1:
			var al := PI * (1.0 - float(s) / segs)
			var lx := cos(al) * w * 0.5
			var ly := pow(maxf(sin(al), 0.0), 0.55) * hh
			var base: Vector3 = pts[p] + r * lx + Vector3.UP * ly
			var n := 0.0
			if s > 0 and s < segs:
				n = nz.get_noise_3d(base.x * 1.3, base.y * 1.3, base.z * 1.3) * amp
			var out := (r * lx + Vector3.UP * (ly - hh * 0.35)).normalized()
			ring.append(base + out * n)
		rings.append(ring)
	for p in pts.size() - 1:
		var A: Array = rings[p]
		var B: Array = rings[p + 1]
		var mid: Vector3 = (pts[p] + pts[p + 1]) * 0.5 + Vector3.UP * ((float(hs[p]) + float(hs[p + 1])) * 0.25)
		for s in segs:
			var cen: Vector3 = (A[s] + B[s + 1]) * 0.5
			quad(k, mat, A[s], A[s + 1], B[s + 1], B[s], mid - cen, faces)
		quad(k, floor_mat, A[0], A[segs], B[segs], B[0], Vector3.UP, faces)


## Falling water: a curved strip from lip, thrown out along `out`, dropping `drop` metres.
static func ribbon(parent: Node3D, top: Vector3, out: Vector3, drop: float, width: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := out.cross(Vector3.UP).normalized()
	var n := 10
	var pts: Array = []
	for i in n + 1:
		var t := float(i) / n
		pts.append(top + out.normalized() * (0.45 * sqrt(t)) + Vector3.DOWN * (drop * t))
	for i in n:
		var w0 := width * (1.0 + 0.25 * float(i) / n)
		var w1 := width * (1.0 + 0.25 * float(i + 1) / n)
		var a: Vector3 = pts[i] - side * w0 * 0.5
		var b: Vector3 = pts[i] + side * w0 * 0.5
		var c: Vector3 = pts[i + 1] + side * w1 * 0.5
		var d: Vector3 = pts[i + 1] - side * w1 * 0.5
		var v0 := float(i) / n
		var v1 := float(i + 1) / n
		for q in [[a, Vector2(0, v0)], [b, Vector2(1, v0)], [c, Vector2(1, v1)], [a, Vector2(0, v0)], [c, Vector2(1, v1)], [d, Vector2(0, v1)]]:
			st.set_uv(q[1])
			st.set_normal(out.normalized())
			st.add_vertex(q[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func fall_material(tint: Color, speed: float, opacity: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = FALL_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("speed", speed)
	m.set_shader_parameter("opacity", opacity)
	return m


## Slow steam wisps over warm water (billboards with soft radial alpha).
static func mist(parent: Node3D, center: Vector3, extent: Vector3, amount: int, alpha: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extent
	p.direction = Vector3.UP
	p.spread = 25.0
	p.gravity = Vector3(0, 0.03, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.18
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.6
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0))
	g.add_point(0.3, Color(1, 1, 1, 1))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = gr
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.albedo_color = Color(0.9, 0.93, 0.92, alpha)
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	q.material = m
	p.mesh = q
	p.position = center
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


static func shell_damped(nz: FastNoiseLite, k: GeoKit, mat: String, c: Vector3, rx: float, rz: float, y0: float, rows: int, ystep: float, cols: int,
		prof: Callable, amp: float, holes: Array, col: Array, damp: Callable) -> void:
	# Geo.shell with per-vertex noise attenuation: we pre-bake amplitude into the profile call
	var grid: Array = []
	for j in rows + 1:
		var y := y0 + float(j) * ystep
		var f: float = prof.call(y)
		var row: Array = []
		for i in cols:
			var a := TAU * float(i) / cols
			var bx := cos(a) * rx
			var bz := sin(a) * rz
			var n := nz.get_noise_3d(bx * 0.6, y * 0.9, bz * 0.6) + 0.55 * nz.get_noise_3d(bx * 2.3, y * 2.1, bz * 2.3) + 0.25 * nz.get_noise_3d(bx * 6.0, y * 5.0, bz * 6.0)
			var am: float = amp * (float(damp.call(a, y)) if damp.is_valid() else 1.0)
			row.append(c + Vector3(bx * f * (1.0 + am * n), y + am * 0.6 * n * f, bz * f * (1.0 + am * n)))
		grid.append(row)
	for j in rows:
		var ym := y0 + (float(j) + 0.5) * ystep
		for i in cols:
			var am := TAU * (float(i) + 0.5) / cols
			var skip := false
			for h in holes:
				if am >= float(h["a0"]) and am <= float(h["a1"]) and ym >= float(h["y0"]) and ym <= float(h["y1"]):
					skip = true
					if h.get("arch", false):
						var u := (am - (float(h["a0"]) + float(h["a1"])) * 0.5) / ((float(h["a1"]) - float(h["a0"])) * 0.5)
						var top := float(h["y0"]) + (float(h["y1"]) - float(h["y0"])) * pow(maxf(0.0, 1.0 - u * u), 0.3)
						skip = ym <= top
			if skip:
				continue
			var i2 := (i + 1) % cols
			var cen: Vector3 = (grid[j][i] + grid[j + 1][i2]) * 0.5
			quad(k, mat, grid[j][i], grid[j][i2], grid[j + 1][i2], grid[j + 1][i], Vector3(c.x, ym, c.z) - cen, col)


static func materials(WATER_Y: float) -> void:
	MatLib.define("l27_limestone", {"albedo_a": Color(0.64, 0.60, 0.52), "albedo_b": Color(0.50, 0.47, 0.40),
		"pattern": 11, "pattern_color": Color(0.72, 0.68, 0.60), "pattern_strength": 0.45, "pattern_scale": Vector2(0.9, 0.9),
		"noise_scale": 0.7, "bump_strength": 1.8, "wetness": 0.45, "stain_amount": 0.35, "stain_color": Color(0.42, 0.40, 0.33),
		"roughness_a": 0.55, "roughness_b": 0.85, "caustics": 0.7, "water_y": WATER_Y}, "rock")
	MatLib.define("l27_flowstone", {"albedo_a": Color(0.70, 0.66, 0.57), "albedo_b": Color(0.58, 0.55, 0.47),
		"pattern": 11, "pattern_color": Color(0.76, 0.72, 0.64), "pattern_strength": 0.3, "pattern_scale": Vector2(1.6, 1.6),
		"noise_scale": 1.1, "bump_strength": 1.1, "wetness": 0.7, "roughness_a": 0.35, "roughness_b": 0.7}, "rock")
	MatLib.define("l27_poolrock", {"albedo_a": Color(0.36, 0.40, 0.37), "albedo_b": Color(0.28, 0.31, 0.29),
		"pattern": 11, "pattern_strength": 0.25, "noise_scale": 1.3, "bump_strength": 0.9, "wetness": 1.0,
		"roughness_a": 0.2, "roughness_b": 0.4, "caustics": 1.0, "water_y": WATER_Y}, "rock")
	MatLib.define("l27_tunnel_rock", {"albedo_a": Color(0.46, 0.43, 0.37), "albedo_b": Color(0.34, 0.32, 0.27),
		"pattern": 11, "pattern_strength": 0.4, "noise_scale": 0.9, "bump_strength": 1.8, "wetness": 0.7,
		"roughness_a": 0.4, "roughness_b": 0.8}, "rock")
	MatLib.define("l27_cavern_rock", {"albedo_a": Color(0.17, 0.17, 0.18), "albedo_b": Color(0.10, 0.10, 0.11),
		"pattern": 11, "pattern_strength": 0.35, "noise_scale": 0.5, "bump_strength": 2.0, "wetness": 0.6}, "rock")
	MatLib.define("l27_stormstone_rock", {"albedo_a": Color(0.022, 0.022, 0.028), "albedo_b": Color(0.045, 0.043, 0.055),
		"pattern": 15, "pattern_color": Color(0.16, 0.15, 0.22), "pattern_strength": 0.3, "pattern_scale": Vector2(0.5, 0.5),
		"noise_scale": 0.3, "bump_strength": 0.5, "roughness_a": 0.55, "roughness_b": 0.8}, "")
	MatLib.register("l27_spring", MatLib.water({"shallow_color": Color(0.36, 0.66, 0.64), "deep_color": Color(0.10, 0.32, 0.36),
		"absorption": 0.35, "clarity": 0.9, "wave_height": 0.004, "wave_scale": 0.9, "foam_amount": 0.15}))
	MatLib.register("l27_lake", MatLib.water({"shallow_color": Color(0.05, 0.07, 0.12), "deep_color": Color(0.01, 0.01, 0.03),
		"absorption": 0.6, "clarity": 0.5, "wave_height": 0.01, "wave_scale": 0.6, "foam_amount": 0.0, "dark_surface": 0.6}))
