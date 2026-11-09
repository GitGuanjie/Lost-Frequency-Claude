extends RefCounted
## Level 108 land model (one height function for meshes, collision and props).
## Frame: +X is east. Old Hereth's church stands at the origin on a low knoll;
## New Hereth is dug into the ground just east of it; the Hauntwood border
## wanders north-south at x ~ HB; a flooded fissure from the crater runs
## roughly north-south at x ~ FX, and the Craterwood deepens westward.
## ADAPTATION (scale): the page's "about two kilometres" from New Hereth to the
## Hauntwood border is read at 1 m = 12 m (~170 m here).

const HB := 168.0           # Hauntwood border (x)
const FX := -112.0          # fissure centre line (x)
const FLOOD_W := 15.0       # flooded margin each side of the crack
const CRACK_W := 2.6        # half width of the open crack
const WATER_Y := -0.35
const NEAR := 360.0
const STEP := 3.0
const TILE := 120.0
const FAR := 1800.0
const FAR_STEP := 36.0
const PIT := Rect2(40.0, -6.0, 26.0, 22.0)  # New Hereth sunken court (x, z, w, d)
const PIT_FLOOR := -4.2

var n_a := FastNoiseLite.new()
var n_b := FastNoiseLite.new()
var n_f := FastNoiseLite.new()
var n_w := FastNoiseLite.new()


func _init() -> void:
	n_a.seed = 10801
	n_a.frequency = 0.008
	n_a.fractal_octaves = 3
	n_b.seed = 10802
	n_b.frequency = 0.035
	n_f.seed = 10803
	n_f.frequency = 0.12
	n_w.seed = 10804
	n_w.frequency = 0.006
	n_w.fractal_octaves = 2


func hb_x(z: float) -> float:
	return HB + 26.0 * n_w.get_noise_1d(z + 500.0)


func fx(z: float) -> float:
	return FX + 22.0 * n_w.get_noise_1d(z * 1.3) + 5.0 * n_b.get_noise_1d(z * 0.6)


## Signed distance into the Hauntwood (positive east of the border).
func haunt_d(x: float, z: float) -> float:
	return x - hb_x(z)


func fissure_off(x: float, z: float) -> float:
	return absf(x - fx(z))


func in_flood(x: float, z: float) -> bool:
	return fissure_off(x, z) < FLOOD_W and absf(z) < 900.0


func base(x: float, z: float) -> float:
	var y := 1.8 + 3.2 * n_a.get_noise_2d(x, z) + 0.6 * n_b.get_noise_2d(x, z)
	y = 0.6 + log(1.0 + exp((y - 0.6) / 1.2)) * 1.2 + 0.12 * n_f.get_noise_2d(x, z)
	# the village knoll: Old Hereth sits a little proud of the forest floor
	var r := Vector2(x - 4.0, z).length()
	y = lerpf(y, 2.6 + 0.4 * n_b.get_noise_2d(x, z), 1.0 - smoothstep(30.0, 62.0, r))
	return y


func h(x: float, z: float) -> float:
	var y := base(x, z)
	# the flooded fissure: a broad sunken margin under shallow water, then the crack
	var o := fissure_off(x, z)
	if o < FLOOD_W + 8.0:
		var bed := WATER_Y - 0.55 - 0.3 * n_f.get_noise_2d(x, z)
		y = lerpf(bed, y, smoothstep(FLOOD_W - 4.0, FLOOD_W + 8.0, o))
		if o < CRACK_W + 1.2:
			y = lerpf(-60.0, y, smoothstep(CRACK_W - 0.4, CRACK_W + 1.2, o))
	# New Hereth: the sunken court with its ramp from the west
	var p := Vector2(x, z)
	var pit := PIT.grow(0.0)
	if pit.has_point(p):
		y = PIT_FLOOR
	else:
		var rp := Rect2(PIT.position.x - 18.0, PIT.position.y + 7.0, 18.0, 6.0)
		if rp.has_point(p):
			var t := (x - rp.position.x) / rp.size.x
			y = lerpf(base(rp.position.x, z), PIT_FLOOR, t)
	return y


## Ground used by the render mesh and placement (the court walls are boxes).
func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


const SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float hb = 168.0;
varying vec3 wp;
varying float up;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; up = NORMAL.y; }
void fragment() {
	vec2 uv = wp.xz / 2.4;
	vec3 tex = texture(grass_alb, uv).rgb;
	vec3 dirt = texture(dirt_alb, wp.xz / 2.6).rgb;
	float a = vn(wp.xz * 0.06); float b = vn(wp.xz * 0.7);
	// verdant floor: deep moss and fern-dark loam, brighter in the clearing
	vec3 moss = mix(vec3(0.035, 0.075, 0.02), vec3(0.07, 0.12, 0.03), a) * (0.65 + 0.7 * dot(tex, vec3(0.33)));
	vec3 litter = mix(vec3(0.06, 0.045, 0.025), vec3(0.1, 0.07, 0.035), b) * (0.6 + 0.7 * dot(dirt, vec3(0.33)));
	vec3 c = mix(moss, litter, smoothstep(0.35, 0.75, vn(wp.xz * 0.15)) * 0.7);
	vec3 clear = mix(vec3(0.07, 0.11, 0.035), vec3(0.1, 0.12, 0.05), b) * (0.6 + 0.8 * dot(tex, vec3(0.33)));
	c = mix(c, clear, COLOR.g);
	// the Hauntwood: grey, dormant, decaying
	float hw = smoothstep(hb - 25.0, hb + 15.0, wp.x + 26.0 * (vn(vec2(wp.z * 0.006, 3.0)) - 0.5) * 2.0);
	vec3 dead = mix(vec3(0.06, 0.055, 0.05), vec3(0.1, 0.095, 0.085), b) * (0.6 + 0.7 * dot(dirt, vec3(0.33)));
	c = mix(c, dead, hw);
	// mud and slick algae at the flood margins; the cut stone of the court
	vec3 mud = dirt * vec3(0.22, 0.2, 0.14) + vec3(0.0, 0.012, 0.0);
	c = mix(c, mud, COLOR.r);
	c = mix(c, vec3(0.16, 0.16, 0.15) * (0.7 + 0.5 * dot(dirt, vec3(0.33))), COLOR.b);
	c = mix(c, litter * 0.7, smoothstep(0.7, 0.4, up));
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.35, COLOR.r * 0.8);
	NORMAL_MAP = mix(texture(grass_nrm, uv).rgb, vec3(0.5, 0.5, 1.0), COLOR.b);
	NORMAL_MAP_DEPTH = 0.8;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("hb", HB)
	var g := "res://assets/external/sparse_grass/sparse_grass_%s_1k.jpg"
	var dt := "res://assets/external/dirt_floor/dirt_floor_%s_1k.jpg"
	if ResourceLoader.exists(g % "diff"):
		m.set_shader_parameter("grass_alb", load(g % "diff"))
		m.set_shader_parameter("grass_nrm", load(g % "nor_gl"))
	if ResourceLoader.exists(dt % "diff"):
		m.set_shader_parameter("dirt_alb", load(dt % "diff"))
	return m


func build_meshes(parent: Node3D, mat: Material) -> void:
	var n := int(NEAR * 2.0 / TILE)
	for tz in n:
		for tx in n:
			var mn := Vector2(-NEAR + tx * TILE, -NEAR + tz * TILE)
			var mi := MeshInstance3D.new()
			mi.name = "Land_%d_%d" % [tx, tz]
			var fine := Rect2(mn, Vector2(TILE, TILE)).intersects(PIT.grow(22.0))
			mi.mesh = _grid(mn, mn + Vector2(TILE, TILE), 1.0 if fine else STEP, Rect2())
			mi.material_override = mat
			parent.add_child(mi)
	var hole := Rect2(Vector2(-NEAR, -NEAR), Vector2(NEAR * 2.0, NEAR * 2.0))
	var mf := MeshInstance3D.new()
	mf.name = "FarFloor"
	mf.mesh = _grid(Vector2(-FAR, -FAR), Vector2(FAR, FAR), FAR_STEP, hole)
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	var cols := PackedColorArray()
	cols.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := h(x, z)
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 1.5
			hs[iz * nx + ix] = y
			var o := fissure_off(x, z)
			var mud := 1.0 - smoothstep(FLOOD_W - 1.0, FLOOD_W + 5.0, o)
			var clear := 1.0 - smoothstep(26.0, 50.0, Vector2(x - 4.0, z).length())
			var court := 1.0 if PIT.grow(0.5).has_point(Vector2(x, z)) else 0.0
			cols[iz * nx + ix] = Color(mud, clear, court)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var idx := iz * nx + ix
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_color(cols[idx])
			st.add_vertex(Vector3(mn.x + ix * step, hs[idx], mn.y + iz * step))
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


func collision_tile(node: Node3D, ox: float, oz: float, size: int) -> void:
	var md := PackedFloat32Array()
	md.resize((size + 1) * (size + 1))
	for j in size + 1:
		for i in size + 1:
			md[j * (size + 1) + i] = h(ox + i, oz + j)
	var body := StaticBody3D.new()
	body.name = "Ground"
	node.add_child(body)
	var sh := HeightMapShape3D.new()
	sh.map_width = size + 1
	sh.map_depth = size + 1
	sh.map_data = md
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + size * 0.5, 0.0, oz + size * 0.5)
	cs.set_meta("surface", "dirt")
	body.add_child(cs)
