extends RefCounted
## Level 201: the land. North is -Z: the Web Sea (surface y 0) with the Digital Trenches under it,
## the Sunset Coast, the Cool Desert of yellow and violet sand (temple, oasis below sea level,
## Base Zeta), barren mountain ranges on both flanks, and the Neon City to the south (+Z).
## One height function feeds the render meshes, the HeightMapShape3D collision and placement.

const SHORE_Z := -88.0
const CITY_Z := 96.0
const TRENCH := Rect2(-34.0, -158.0, 68.0, 42.0)
const TRENCH_FLOOR := -9.0
const OASIS := Vector3(-40.0, -2.6, 36.0)
const TEMPLE := Vector3(24.0, 1.3, -6.0)
const NEAR_MIN := Vector2(-132.0, -344.0)
const NEAR_MAX := Vector2(132.0, 252.0)

const SKY := """
shader_type sky;
uniform vec3 sun_dir = vec3(0.0, 0.07, -1.0);
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void sky() {
	vec3 d = EYEDIR;
	vec3 sd = normalize(sun_dir);
	float north = clamp(-d.z * 0.5 + 0.5, 0.0, 1.0);
	// bright orange near the sun to deep purple over the city
	vec3 hor = mix(vec3(0.22, 0.04, 0.32), vec3(1.0, 0.42, 0.28), pow(north, 2.2));
	vec3 top = mix(vec3(0.05, 0.01, 0.12), vec3(0.42, 0.1, 0.42), pow(north, 3.0));
	vec3 col = d.y > 0.0 ? mix(hor, top, pow(clamp(d.y, 0.0, 1.0), 0.5)) : mix(hor, vec3(0.08, 0.02, 0.14), clamp(-d.y * 4.0, 0.0, 1.0));
	// the white line grid
	float az = atan(d.x, -d.z);
	float el = asin(clamp(d.y, -1.0, 1.0));
	float gx = abs(fract(az * 18.0 / 6.2831853) - 0.5);
	float gy = abs(fract(el * 30.0 / 3.14159) - 0.5);
	float line = max(smoothstep(0.47, 0.5, gx * (1.0 + d.y * 0.0)), smoothstep(0.46, 0.5, gy));
	col = mix(col, vec3(1.0, 0.92, 1.0), line * 0.45 * smoothstep(0.0, 0.03, d.y));
	// stars over the city side
	vec2 sp = floor(vec2(az, el) * 300.0);
	float star = step(0.9965, h2(sp)) * smoothstep(0.5, 0.0, north) * smoothstep(0.05, 0.3, d.y);
	col += vec3(star);
	// the sun: six times our sun, orange-pink, fragmented in straight horizontal lines
	float sdist = acos(clamp(dot(d, sd), -1.0, 1.0));
	float rad = 0.16;
	if (sdist < rad) {
		float v = (d.y - sd.y) / rad;
		float band = fract(v * 6.0 + 0.3);
		float gap = step(1.0 - clamp(0.42 - v * 0.38, 0.06, 0.8), band) * step(v, 0.45);
		vec3 sc = mix(vec3(1.0, 0.85, 0.3), vec3(1.0, 0.28, 0.55), clamp(0.5 - v * 0.8, 0.0, 1.0));
		col = mix(col, sc * 1.6, (1.0 - gap) * smoothstep(rad, rad - 0.004, sdist));
	}
	col += vec3(1.0, 0.4, 0.4) * 0.35 * exp(-sdist * 4.0);
	COLOR = col;
}
"""

const SEA := """
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_always, diffuse_burley;
uniform vec3 blue : source_color = vec3(0.04, 0.1, 0.42);
uniform vec3 purple : source_color = vec3(0.3, 0.1, 0.45);
uniform float shift = 0.0;
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(wp.x * 0.15 + TIME * 0.4) * sin(wp.z * 0.12 + TIME * 0.3) * 0.03;
}
void fragment() {
	vec2 g = abs(fract(wp.xz / 4.0) - 0.5);
	float net = smoothstep(0.47, 0.5, max(g.x, g.y));
	float dist = length(VERTEX);
	net *= 1.0 - smoothstep(30.0, 160.0, dist);
	vec3 c = mix(blue, purple, shift);
	ALBEDO = c * 0.6 + vec3(0.6, 0.85, 1.0) * net * 0.5;
	EMISSION = vec3(0.4, 0.8, 1.0) * net * 0.35;
	ROUGHNESS = 0.08;
	SPECULAR = 0.8;
	ALPHA = FRONT_FACING ? 0.82 : 0.55;
}
"""

const GROUND := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 wp;
varying vec3 wn;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) { vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = NORMAL; }
void fragment() {
	float n = n3(wp * 0.035) * 0.6 + n3(wp * 0.11) * 0.3 + n3(wp * 0.6) * 0.1;
	vec3 yellow = vec3(0.86, 0.62, 0.26);
	vec3 violet = vec3(0.5, 0.24, 0.62);
	vec3 sand = mix(yellow, violet, smoothstep(0.42, 0.62, n));
	float rip = sin(dot(wp.xz, vec2(1.7, 0.6)) * 2.0 + n * 9.0);
	sand *= 0.9 + 0.08 * rip;
	vec3 rock = mix(vec3(0.2, 0.13, 0.24), vec3(0.32, 0.22, 0.3), n3(wp * vec3(0.3, 2.0, 0.3)));
	float steep = smoothstep(0.82, 0.62, wn.y);
	vec3 col = mix(sand, rock, steep);
	col = mix(col, col * vec3(0.5, 0.55, 0.9), smoothstep(-0.3, -2.5, wp.y));
	float city = smoothstep(90.0, 98.0, wp.z);
	col = mix(col, vec3(0.08, 0.06, 0.12) + vec3(0.02) * n, city);
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.6, city);
}
"""

var n_dune := FastNoiseLite.new()
var n_ridge := FastNoiseLite.new()
var n_small := FastNoiseLite.new()


func _init() -> void:
	n_dune.seed = 201
	n_dune.frequency = 0.012
	n_dune.fractal_octaves = 3
	n_ridge.seed = 2011
	n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_ridge.fractal_octaves = 4
	n_ridge.frequency = 0.006
	n_small.seed = 2012
	n_small.frequency = 0.05


func h(x: float, z: float) -> float:
	var y := 1.3 + 1.7 * n_dune.get_noise_2d(x, z) + 0.25 * n_small.get_noise_2d(x, z)
	# Sunset Coast: soft beach down to the waterline
	var beach := lerpf(1.0, -0.5, smoothstep(-68.0, SHORE_Z - 2.0, z)) + 0.15 * n_small.get_noise_2d(x * 0.5, z)
	y = lerpf(y, beach, smoothstep(-52.0, -72.0, z))
	if z < SHORE_Z + 4.0:
		var sea := lerpf(-0.5, -3.4, smoothstep(SHORE_Z, -118.0, z)) + 0.3 * n_small.get_noise_2d(x, z)
		y = lerpf(y, sea, smoothstep(SHORE_Z + 4.0, SHORE_Z - 2.0, z))
		var tw := smoothstep(TRENCH.end.x, TRENCH.end.x - 7.0, absf(x)) * smoothstep(TRENCH.end.y + 4.0, TRENCH.end.y - 4.0, z) * smoothstep(TRENCH.position.y - 4.0, TRENCH.position.y + 4.0, z)
		y = lerpf(y, TRENCH_FLOOR + 0.4 * n_small.get_noise_2d(x * 2.0, z * 2.0), tw)
		# the far end of the explorable sea: an unclimbable submerged cliff up to a shelf
		y += smoothstep(-326.0, -334.0, z) * 8.0
	# the oasis bowl, below sea level
	var od := Vector2(x - OASIS.x, z - OASIS.z).length()
	y = lerpf(y, OASIS.y + od * 0.04, 1.0 - smoothstep(8.0, 16.0, od))
	# temple ground: flattened, the ruin is half buried around it
	var td := Vector2((x - TEMPLE.x) / 18.0, (z - TEMPLE.z) / 22.0).length()
	y = lerpf(y, TEMPLE.y, 1.0 - smoothstep(0.85, 1.25, td))
	# Neon City ground
	y = lerpf(y, 0.55, smoothstep(CITY_Z - 14.0, CITY_Z, z))
	# barren mountain ranges on both flanks
	var foot := 76.0 + 9.0 * n_dune.get_noise_1d(z * 0.7 + 400.0)
	var m := absf(x) - foot
	if m > -6.0:
		var mm := maxf(m, 0.0)
		var ridge := 0.5 + 0.5 * n_ridge.get_noise_2d(x, z)
		var fade := smoothstep(-100.0, -45.0, z)
		y += (pow(maxf(m + 6.0, 0.0), 2.0) * 0.03 + mm * 1.3 + ridge * 160.0 * smoothstep(0.0, 90.0, mm)) * fade
	# the explorable sea is bounded east and west by submerged walls too
	if z < SHORE_Z + 10.0:
		var side := smoothstep(98.0, 104.0, absf(x)) * smoothstep(SHORE_Z + 10.0, SHORE_Z - 4.0, z)
		y = lerpf(y, maxf(y, -1.6), side)
	return y


func make_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func build_meshes(parent: Node3D) -> void:
	var mat := make_mat(GROUND)
	var near := _grid(NEAR_MIN, NEAR_MAX, 2.0, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "Sand"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(NEAR_MIN + Vector2(16, 16), NEAR_MAX - NEAR_MIN - Vector2(32, 32))
	var far := _grid(Vector2(-1100, -1500), Vector2(1100, 900), 16.0, hole)
	var mf := MeshInstance3D.new()
	mf.name = "SandFar"
	mf.mesh = far
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := h(x, z)
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 1.0
			hs[iz * nx + ix] = y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var y := hs[iz * nx + ix]
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_uv(Vector2(mn.x + ix * step, mn.y + iz * step))
			st.add_vertex(Vector3(mn.x + ix * step, y, mn.y + iz * step))
	for iz in nz - 1:
		for ix in nx - 1:
			if hole.size.x > 0.0 and hole.has_point(Vector2(mn.x + (ix + 0.5) * step, mn.y + (iz + 0.5) * step)):
				continue
			var a := iz * nx + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


func build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "SandCollision"
	parent.add_child(body)
	var cells := 64
	var sp := 2.0
	var span := cells * sp
	var nx := int(ceil((NEAR_MAX.x - NEAR_MIN.x) / span))
	var nz := int(ceil((NEAR_MAX.y - NEAR_MIN.y) / span))
	for tz in nz:
		for tx in nx:
			var ox := NEAR_MIN.x + tx * span
			var oz := NEAR_MIN.y + tz * span
			var md := PackedFloat32Array()
			md.resize((cells + 1) * (cells + 1))
			for j in cells + 1:
				for i in cells + 1:
					md[j * (cells + 1) + i] = h(ox + i * sp, oz + j * sp)
			var shape := HeightMapShape3D.new()
			shape.map_width = cells + 1
			shape.map_depth = cells + 1
			shape.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.scale = Vector3(sp, 1.0, sp)
			cs.position = Vector3(ox + span * 0.5, 0.0, oz + span * 0.5)
			cs.set_meta("surface", "sand" if oz < CITY_Z else "concrete")
			body.add_child(cs)


func build_water(parent: Node3D) -> ShaderMaterial:
	var mat := make_mat(SEA)
	var sea := MeshInstance3D.new()
	sea.name = "WebSea"
	var pm := PlaneMesh.new()
	pm.size = Vector2(2600, 1500)
	pm.subdivide_width = 80
	pm.subdivide_depth = 50
	sea.mesh = pm
	sea.position = Vector3(0, 0.0, SHORE_Z - 750.0 + 6.0)
	sea.material_override = mat
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sea)
	var oasis := MeshInstance3D.new()
	oasis.name = "OasisWater"
	var om := PlaneMesh.new()
	om.size = Vector2(26, 26)
	oasis.mesh = om
	oasis.position = Vector3(OASIS.x, -1.2, OASIS.z)
	oasis.material_override = mat
	oasis.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(oasis)
	return mat
