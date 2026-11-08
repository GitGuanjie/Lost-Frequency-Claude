extends RefCounted
## Level 10.1 dressing: the barbed-wire Exclusion Zone fence with its warning
## signs and gate, the M.E.G. notice board, the dump point with the empty
## waste barrels, the lake's central dark "heart", algae mats, Level 10 tree
## lines, and the streamed vegetation (bank grass, waterline reeds, the wheat
## fringe). Prototype meshes are built once; instances go into MultiMeshes.

var lvl
var land
var tuft: ArrayMesh
var reed: ArrayMesh
var stalk: ArrayMesh
var crown: ArrayMesh
var trunk: ArrayMesh
var gate_pos := Vector3.ZERO
var board_pos := Vector3.ZERO
var breach_pos := Vector3.ZERO
var sign_mat: StandardMaterial3D
var sign_posts: Array = []


func _init(level, land_model) -> void:
	lvl = level
	land = land_model
	tuft = _clump(0)
	reed = _clump(1)
	stalk = _clump(2)
	crown = _blob(2, 77)
	trunk = _trunk()


# ---------------------------------------------------------------- materials

static func define_materials() -> void:
	MatLib.define("l10l_post", {"albedo_a": Color(0.20, 0.22, 0.17), "albedo_b": Color(0.14, 0.15, 0.12),
		"metallic_value": 0.5, "roughness_a": 0.55, "roughness_b": 0.8, "noise_scale": 3.0,
		"stain_amount": 0.35, "stain_color": Color(0.32, 0.17, 0.08)}, "metal")
	MatLib.define("l10l_wire", {"albedo_a": Color(0.42, 0.42, 0.41), "albedo_b": Color(0.30, 0.30, 0.29),
		"metallic_value": 0.8, "roughness_a": 0.4, "roughness_b": 0.6}, "metal")
	MatLib.define("l10l_wood", {"albedo_a": Color(0.34, 0.27, 0.19), "albedo_b": Color(0.24, 0.19, 0.13),
		"pattern": 3, "pattern_scale": Vector2(0.5, 0.06), "grout_width": 0.002, "grout_color": Color(0.14, 0.1, 0.07),
		"roughness_a": 0.8, "roughness_b": 0.95, "stain_amount": 0.4, "stain_color": Color(0.2, 0.17, 0.12)}, "wood_floor")
	MatLib.define("l10l_ply", {"albedo_a": Color(0.55, 0.46, 0.33), "albedo_b": Color(0.47, 0.39, 0.27),
		"noise_scale": 2.0, "roughness_a": 0.85, "roughness_b": 0.95, "stain_amount": 0.45,
		"stain_color": Color(0.33, 0.27, 0.18), "grime_height": 0.3, "grime_color": Color(0.25, 0.2, 0.13)}, "plaster")
	MatLib.define("l10l_drum", {"albedo_a": Color(0.62, 0.48, 0.08), "albedo_b": Color(0.5, 0.36, 0.06),
		"metallic_value": 0.35, "roughness_a": 0.5, "roughness_b": 0.85, "noise_scale": 2.5,
		"stain_amount": 0.55, "stain_color": Color(0.3, 0.12, 0.05), "grime_height": 0.35, "grime_color": Color(0.2, 0.08, 0.05),
		"bump_strength": 0.8}, "metal")
	MatLib.define("l10l_galv", {"albedo_a": Color(0.6, 0.61, 0.6), "albedo_b": Color(0.48, 0.49, 0.48),
		"metallic_value": 0.85, "roughness_a": 0.35, "roughness_b": 0.55}, "metal")
	_shader_mat("l10l_veg", VEG)
	_shader_mat("l10l_crown", CROWN)
	_shader_mat("l10l_algae", ALGAE)
	_shader_mat("l10l_heart", HEART)
	_shader_mat("l10l_bulge", BULGE)
	_shader_mat("l10l_ripple", RIPPLE)


static func _shader_mat(name: String, code: String) -> void:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	MatLib.register(name, m)


const VEG := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform float gust = 0.2;
varying float hgt;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	hgt = VERTEX.y;
	float ph = dot(w.xz, vec2(0.8, 0.6)) * 0.15 - TIME * 1.6;
	float sway = (0.5 + 0.5 * sin(ph)) * (0.15 + gust) + 0.05 * sin(TIME * 3.1 + w.x * 1.7);
	VERTEX.xz += vec2(0.8, 0.6) * sway * VERTEX.y * VERTEX.y * 0.12;
}
void fragment() {
	ALBEDO = COLOR.rgb * (0.55 + 0.45 * clamp(hgt * 1.4, 0.0, 1.0));
	ROUGHNESS = 0.9;
	BACKLIGHT = COLOR.rgb * 0.35;
}
"""

const CROWN := """
shader_type spatial;
render_mode diffuse_burley;
float hsh(vec3 p) { p = fract(p * 0.3183 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = hsh(floor(wp * 2.3));
	vec3 c = mix(vec3(0.07, 0.10, 0.04), vec3(0.16, 0.2, 0.08), n);
	ALBEDO = c * (0.8 + 0.3 * COLOR.r);
	ROUGHNESS = 0.95;
}
"""

const ALGAE := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float n = vn(wp.xz * 0.9) * 0.55 + vn(wp.xz * 3.7) * 0.3 + vn(wp.xz * 11.0) * 0.15;
	if (n - r * 0.55 < 0.22) { discard; }
	float k = vn(wp.xz * 1.6);
	// green algae and rust-brown trichodesmium rafts
	vec3 c = mix(vec3(0.09, 0.13, 0.04), vec3(0.24, 0.12, 0.05), smoothstep(0.35, 0.7, k));
	ALBEDO = c * (0.7 + 0.5 * vn(wp.xz * 19.0));
	ROUGHNESS = 0.92;
	SPECULAR = 0.15;
}
"""

const HEART := """
shader_type spatial;
render_mode unshaded, cull_disabled;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void fragment() {
	vec2 p = UV - 0.5;
	float a = atan(p.y, p.x);
	float edge = 0.36 + 0.08 * vn(vec2(a * 3.0, TIME * 0.05)) + 0.04 * vn(vec2(a * 11.0, 2.0));
	if (length(p) > edge) { discard; }
	ALBEDO = vec3(0.0);
}
"""

const BULGE := """
shader_type spatial;
render_mode diffuse_burley;
void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(vec3(0.16, 0.014, 0.016), vec3(0.3, 0.05, 0.05), fres);
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
}
"""

const RIPPLE := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform float strength = 0.0;
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float ring = 0.5 + 0.5 * sin(r * 34.0 - TIME * 2.2);
	float a = smoothstep(1.0, 0.6, r) * smoothstep(0.1, 0.3, r) * ring * strength;
	ALBEDO = vec3(0.3, 0.05, 0.05);
	ALPHA = a * 0.55;
}
"""


# ---------------------------------------------------------------- fence

## The barbed-wire Exclusion Zone fence, one ring on the rim. Warning signs
## face outwards every ten posts; the gate opens where the track crosses; a
## second, cut section lies flattened on the north-west side.
func fence(k: GeoKit, parent: Node3D) -> void:
	sign_mat = _sign_material()
	var a := 0.0
	var posts: Array = []
	var gz: float = land.shore_s + land.FENCE_D
	gate_pos = Vector3(land.track_x(gz), 0.0, gz)
	gate_pos.y = land.h(gate_pos.x, gate_pos.z)
	var breach_a := PI * 0.5 + 1.05
	var bdir := Vector3(cos(breach_a), 0, sin(breach_a))
	breach_pos = bdir * (land.shore_r(breach_a) + land.FENCE_D)
	breach_pos.y = land.h(breach_pos.x, breach_pos.z)
	while a < TAU - 0.0001:
		var r: float = land.shore_r(a) + land.FENCE_D
		var p := Vector3(cos(a) * r, 0.0, sin(a) * r)
		p.y = land.h(p.x, p.z)
		posts.append(p)
		a += 3.7 / r
	var n := posts.size()
	for i in n:
		var p: Vector3 = posts[i]
		var q: Vector3 = posts[(i + 1) % n]
		var mid := (p + q) * 0.5
		var in_gate := Vector2(mid.x - gate_pos.x, mid.z - gate_pos.z).length() < 3.0
		var in_breach := Vector2(mid.x - breach_pos.x, mid.z - breach_pos.z).length() < 4.0
		var tall := i % 10 == 0
		# posts: steel T-posts, a heavier timber post at every sign
		if tall:
			k.box(p + Vector3(0, 1.0, 0), Vector3(0.13, 2.25, 0.13), "l10l_wood", GeoKit.ALL, true)
			_sign(parent, p, p + Vector3(p.x, 0, p.z).normalized() * 0.09)
			sign_posts.append(p)
		elif not in_gate:
			k.box(p + Vector3(0, 0.78, 0), Vector3(0.055, 1.7, 0.055), "l10l_post", GeoKit.ALL, false)
		if in_gate:
			continue
		var bas := _span_basis(p, q)
		var length := Vector2(q.x - p.x, q.z - p.z).length()
		if in_breach:
			# cut strands hanging down and coiled in the grass
			for s in 4:
				var y0 := 0.08 + 0.05 * s
				k.box_xf(Transform3D(bas.rotated(bas.z, 0.12 * (s - 1.5)), mid + Vector3(0, y0, 0)), Vector3(length * 0.42, 0.012, 0.012), "l10l_wire", GeoKit.ALL, false)
			continue
		for s in 4:
			var hy := 0.36 + 0.36 * s
			k.box_xf(Transform3D(bas, mid + Vector3(0, hy - 0.025, 0)), Vector3(length, 0.011, 0.011), "l10l_wire", GeoKit.ALL, false)
		# barbs on the top strand where the player can see them up close
		if mid.distance_to(gate_pos) < 70.0:
			var m := int(length / 0.32)
			for b in m:
				var c := p.lerp(q, (b + 0.5) / m) + Vector3(0, 1.415, 0)
				k.box_xf(Transform3D(bas.rotated(bas.x, 0.7), c), Vector3(0.012, 0.07, 0.012), "l10l_wire", GeoKit.ALL, false)
		# one collider per span: the wire itself is the barrier
		var yb := (p.y + q.y) * 0.5
		k.add_box_shape(Transform3D(bas, Vector3(mid.x, yb + 0.85, mid.z)), Vector3(length, 1.7, 0.1), "metal")
	_gate(k, parent)


func _span_basis(p: Vector3, q: Vector3) -> Basis:
	var d := Vector3(q.x - p.x, 0, q.z - p.z).normalized()
	var nz := d.cross(Vector3.UP).normalized()
	return Basis(d, Vector3.UP, nz)


func _sign_material() -> StandardMaterial3D:
	var img := Image.create(256, 192, false, Image.FORMAT_RGB8)
	img.fill(Color(0.93, 0.76, 0.1))
	for y in 192:
		for x in 256:
			if x < 7 or x > 248 or y < 7 or y > 184:
				img.set_pixel(x, y, Color(0.05, 0.05, 0.04))
	# radiation trefoil on the upper half
	var c := Vector2(128, 62)
	for y in range(8, 120):
		for x in range(60, 196):
			var v := Vector2(x, y) - c
			var r := v.length() / 52.0
			var ang := fposmod(atan2(v.y, v.x) + PI * 0.5, TAU / 3.0)
			if r < 0.2 or (r > 0.3 and r < 1.0 and ang < PI / 3.0):
				img.set_pixel(x, y, Color(0.05, 0.05, 0.04))
	# weathering
	var rr := RandomNumberGenerator.new()
	rr.seed = 101
	for i in 900:
		var x := rr.randi_range(0, 255)
		var y := rr.randi_range(0, 191)
		img.set_pixel(x, y, img.get_pixel(x, y).darkened(rr.randf_range(0.05, 0.3)))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.6
	return m


func _sign(parent: Node3D, post: Vector3, at: Vector3) -> void:
	var outward := Vector3(post.x, 0, post.z).normalized()
	var node := Node3D.new()
	node.name = "WarningSign"
	parent.add_child(node)
	node.position = at + Vector3(0, 1.45, 0)
	node.rotation.y = atan2(outward.x, outward.z)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.64, 0.48)
	q.mesh = qm
	q.material_override = sign_mat
	node.add_child(q)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.66, 0.5, 0.012)
	back.mesh = bm
	back.position.z = -0.008
	back.material_override = MatLib.get_mat("l10l_galv")
	node.add_child(back)
	var lab := Label3D.new()
	lab.text = "DANGER - RADIATION\nCORPSE LAKE EXCLUSION ZONE\nNO ENTRY BEYOND THIS FENCE"
	lab.font_size = 22
	lab.pixel_size = 0.0021
	lab.modulate = Color(0.04, 0.04, 0.03)
	lab.outline_size = 0
	lab.shaded = true
	lab.double_sided = false
	lab.position = Vector3(0, -0.15, 0.004)
	lab.visibility_range_end = 30.0
	node.add_child(lab)
	for b in [-1.0, 1.0]:
		var bolt := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.02, 0.02, 0.02)
		bolt.mesh = sm
		bolt.position = Vector3(0.27 * b, 0.19, 0.01)
		bolt.material_override = MatLib.get_mat("l10l_galv")
		node.add_child(bolt)


func _gate(k: GeoKit, parent: Node3D) -> void:
	var g := gate_pos
	var y := g.y
	for s in [-1.0, 1.0]:
		k.box(Vector3(g.x + 2.7 * s, y + 1.05, g.z), Vector3(0.14, 2.3, 0.14), "l10l_galv")
		k.box(Vector3(g.x + 2.7 * s, y + 2.22, g.z), Vector3(0.18, 0.05, 0.18), "l10l_galv", GeoKit.ALL, false)
	# two tubular leaves swung open inwards (towards the lake)
	for s in [-1.0, 1.0]:
		var hinge: Vector3 = Vector3(g.x + 2.62 * s, y, g.z)
		var ang: float = deg_to_rad(78.0) * s
		var dir: Vector3 = Vector3(-s * cos(ang), 0, -absf(sin(ang)))
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
		for hy in [0.25, 0.75, 1.25]:
			k.box_xf(Transform3D(bas, hinge + dir * 1.25 + Vector3(0, hy, 0)), Vector3(2.5, 0.045, 0.045), "l10l_galv", GeoKit.ALL, false)
		for e in [0.03, 2.47]:
			k.box_xf(Transform3D(bas, hinge + dir * e + Vector3(0, 0.75, 0)), Vector3(0.05, 1.1, 0.05), "l10l_galv", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(bas, hinge + dir * 1.25 + Vector3(0, 0.7, 0)), Vector3(2.5, 1.2, 0.08), "metal")
		if s > 0.0:
			_sign(parent, hinge + dir * 1.25, hinge + dir * 1.25 + dir.cross(Vector3.UP) * -0.05 + Vector3(0, -0.55, 0))
	# the board the M.E.G. checks are posted on, outside the gate
	board_pos = Vector3(g.x + 4.6, 0.0, g.z + 3.2)
	board_pos.y = land.h(board_pos.x, board_pos.z)
	var bp := board_pos
	for s in [-1.0, 1.0]:
		k.box(bp + Vector3(0.85 * s, 1.1, 0), Vector3(0.1, 2.2, 0.1), "l10l_wood")
	k.box(bp + Vector3(0, 1.55, 0), Vector3(1.9, 1.05, 0.04), "l10l_ply")
	k.box(bp + Vector3(0, 2.2, -0.12), Vector3(2.1, 0.04, 0.42), "l10l_wood", GeoKit.ALL, false)
	k.box(bp + Vector3(0, 0.98, 0.1), Vector3(1.8, 0.03, 0.18), "l10l_wood", GeoKit.ALL, false)
	var r := RandomNumberGenerator.new()
	r.seed = 1011
	for i in 6:
		var paper := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.21, 0.29, 0.004)
		paper.mesh = pm
		paper.material_override = MatLib.get_mat("paper")
		paper.position = bp + Vector3(-0.66 + 0.27 * i + r.randf_range(-0.03, 0.03), 1.62 + r.randf_range(-0.22, 0.2), 0.025)
		paper.rotation.z = r.randf_range(-0.08, 0.08)
		paper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(paper)
	var head := Label3D.new()
	head.text = "M.E.G. - LEVEL 10.1 EXCLUSION ZONE"
	head.font_size = 30
	head.pixel_size = 0.0024
	head.modulate = Color(0.12, 0.1, 0.08)
	head.shaded = true
	head.double_sided = false
	head.position = bp + Vector3(0, 2.0, 0.025)
	parent.add_child(head)
	# concrete blocks and plastic barriers narrowing the track at the gate
	Props.place(lvl, parent, "ph/concrete_road_barrier", Vector3(g.x - 3.6, land.h(g.x - 3.6, g.z + 2.0), g.z + 2.0), 8.0, 0.0, true)
	Props.place(lvl, parent, "ph/concrete_road_barrier", Vector3(g.x + 3.9, land.h(g.x + 3.9, g.z + 1.6), g.z + 1.6), -6.0, 0.0, true)


# ---------------------------------------------------------------- dump point

## Where the M.E.G. emptied the waste barrels (timeline: 21:20, Dec 2020).
## The barrels were left where they were tipped; nobody came back for them.
func dump_site(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var c: Vector3 = land.dump
	var spots := [Vector3(-6.5, 0, 6.0), Vector3(-5.6, 0, 7.1), Vector3(-7.4, 0, 7.4), Vector3(-6.2, 0, 8.4),
		Vector3(5.8, 0, 9.5), Vector3(6.9, 0, 8.6)]
	var ids := ["ph/barrel_03", "ph/Barrel_01"]
	for i in spots.size():
		var p: Vector3 = c + spots[i]
		_drum(Props.place(lvl, parent, ids[i % 2], Vector3(p.x, land.h(p.x, p.z), p.z), rng.randf_range(0, 360), 0.0, true))
	# tipped ones rolling towards the waterline, two already half in the liquid
	for i in 7:
		var p := c + Vector3(rng.randf_range(-7.0, 7.0), 0, rng.randf_range(-5.5, 3.0))
		var y: float = land.h(p.x, p.z)
		var hold := Props.place(lvl, parent, ids[rng.randi() % 2], Vector3(p.x, y + 0.27, p.z), rng.randf_range(0, 360), 0.0, false)
		_drum(hold)
		if hold:
			hold.rotation.x = PI * 0.5
			hold.rotation.y = rng.randf_range(0, TAU)
	for p in [c + Vector3(-2.5, -0.35, -5.5), c + Vector3(3.0, -0.45, -7.0)]:
		var hold := Props.place(lvl, parent, "ph/barrel_03", p, 0.0, 0.0, false)
		_drum(hold)
		if hold:
			hold.rotation = Vector3(PI * 0.5 + 0.3, rng.randf_range(0, TAU), 0.2)
	var pc := c + Vector3(7.5, 0, 6.2)
	Props.place(lvl, parent, "ph/hand_truck", Vector3(pc.x, land.h(pc.x, pc.z), pc.z), 200.0, 0.0, false)
	pc = c + Vector3(-9.0, 0, 9.5)
	Props.place(lvl, parent, "ph/old_military_crate", Vector3(pc.x, land.h(pc.x, pc.z), pc.z), 70.0, 0.0, true)
	pc = c + Vector3(8.4, 0, 10.6)
	Props.place(lvl, parent, "ph/plastic_crate_01", Vector3(pc.x, land.h(pc.x, pc.z), pc.z), 15.0, 0.0, false)
	pc = c + Vector3(-8.2, 0, 11.4)
	Props.place(lvl, parent, "ph/old_tyre", Vector3(pc.x, land.h(pc.x, pc.z) + 0.08, pc.z), 0.0, 0.0, false)


## Repaint a barrel model as a yellow, rust-streaked waste drum.
func _drum(n: Node) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = MatLib.get_mat("l10l_drum")
	for c in n.get_children():
		_drum(c)


# ---------------------------------------------------------------- the lake

func lake_surface_features(parent: Node3D, rng: RandomNumberGenerator) -> void:
	# The central black area "darker than Vantablack" (likened to a heart).
	var heart := MeshInstance3D.new()
	heart.name = "Heart"
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	heart.mesh = pm
	heart.material_override = MatLib.get_mat("l10l_heart")
	heart.position = Vector3(-8.0, 0.05, -14.0)
	heart.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(heart)
	# floating algae and trichodesmium rafts along the shore
	var xfs := PackedFloat32Array()
	var n := 0
	var tries := 0
	while n < 170 and tries < 2000:
		tries += 1
		var a := rng.randf() * TAU
		if n < 50:
			a = PI * 0.5 + rng.randf_range(-0.55, 0.55)
		var r: float = land.shore_r(a) - rng.randf_range(1.0, 26.0)
		var s := rng.randf_range(2.5, 9.0)
		var yaw := rng.randf() * TAU
		xfs.append_array([cos(yaw) * s, 0.0, sin(yaw) * s, cos(a) * r, 0.0, 1.0, 0.0, 0.035, -sin(yaw) * s, 0.0, cos(yaw) * s, sin(a) * r])
		n += 1
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.orientation = PlaneMesh.FACE_Y
	_mm(parent, q, "l10l_algae", xfs, false, 0.0)


# ---------------------------------------------------------------- trees

## Level 10 tree lines along the plot boundaries, beyond the zone edge.
func tree_lines(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var crowns := PackedFloat32Array()
	var trunks := PackedFloat32Array()
	var lines: Array = []
	for kx in range(-4, 4):
		lines.append([true, 54.0 + 230.0 * kx])
	for kz in range(-4, 4):
		lines.append([false, 113.0 + 260.0 * kz])
	for ln in lines:
		var t := -950.0
		while t < 950.0:
			t += rng.randf_range(9.0, 16.0)
			if rng.randf() < 0.18:
				t += rng.randf_range(10.0, 40.0)
			var x: float = ln[1] if ln[0] else t
			var z: float = t if ln[0] else ln[1]
			x += rng.randf_range(-1.2, 1.2)
			z += rng.randf_range(-1.2, 1.2)
			var d: float = land.dist(x, z)
			if d < land.EXIT_D + 30.0 or Vector2(x, z).length() > 1100.0:
				continue
			if land.track_w(x, z) > 0.0:
				continue
			var y: float = land.h(x, z)
			var th := rng.randf_range(2.8, 4.2)
			var tw := rng.randf_range(0.22, 0.34)
			trunks.append_array([tw, 0, 0, x, 0, th, 0, y - 0.2, 0, 0, tw, z])
			var cr := rng.randf_range(2.6, 4.2)
			for b in 3:
				var off := Vector3(rng.randf_range(-1.6, 1.6), rng.randf_range(-0.4, 0.9), rng.randf_range(-1.6, 1.6))
				var s := cr * rng.randf_range(0.6, 0.95)
				var yaw := rng.randf() * TAU
				crowns.append_array([cos(yaw) * s, 0, sin(yaw) * s, x + off.x, 0, s * 0.8, 0, y + th + cr * 0.45 + off.y, -sin(yaw) * s, 0, cos(yaw) * s, z + off.z])
	_mm(parent, crown, "l10l_crown", crowns, true, 0.0)
	_mm(parent, trunk, "l10l_wood", trunks, false, 0.0)


# ---------------------------------------------------------------- vegetation (streamed)

## Bank grass, waterline reeds and the wheat fringe for one 16 m tile.
func veg_tile(parent: Node3D, x0: float, z0: float, size: float, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var bt := PackedFloat32Array()
	var br := PackedFloat32Array()
	var bs := PackedFloat32Array()
	var cx := x0 + size * 0.5
	var cz := z0 + size * 0.5
	var dc: float = land.dist(cx, cz)
	if dc < -size or dc > land.CROP_D + 14.0 + size:
		return
	var n := int(size / 0.8)
	for j in n:
		for i in n:
			var x := x0 + (i + r.randf()) * 0.8
			var z := z0 + (j + r.randf()) * 0.8
			var d: float = land.dist(x, z)
			if d < -0.3 or d > land.CROP_D + 12.0:
				continue
			var tw: float = land.track_w(x, z)
			var y: float = land.h(x, z)
			var yaw := r.randf() * TAU
			if d < 2.6:
				# reeds and rank grass thrive right at the liquid's edge
				if tw > 0.2 or land.apron_w(x, z) > 0.3 or land.n_fine.get_noise_2d(x * 0.4, z * 0.4) < -0.15:
					continue
				var s := r.randf_range(0.8, 1.35)
				br.append_array([cos(yaw) * s, 0, sin(yaw) * s, x, 0, s, 0, y - 0.05, -sin(yaw) * s, 0, cos(yaw) * s, z])
				continue
			var cw: float = land.crop_w(x, z)
			if cw > 0.25:
				if cw < 0.97 or r.randf() < 0.18:
					var s := r.randf_range(0.85, 1.12)
					bs.append_array([cos(yaw) * s, 0, sin(yaw) * s, x, 0, s, 0, y - 0.03, -sin(yaw) * s, 0, cos(yaw) * s, z])
				continue
			if tw > 0.5 and absf(x - land.track_x(z)) > 0.5:
				continue
			if land.n_fine.get_noise_2d(x * 1.3, z * 1.3) < -0.35 + 0.002 * d:
				continue
			var s := r.randf_range(0.6, 1.3)
			bt.append_array([cos(yaw) * s, 0, sin(yaw) * s, x, 0, s, 0, y - 0.02, -sin(yaw) * s, 0, cos(yaw) * s, z])
	# shrubs: plants are never harmed here, so the banks are overgrown
	if dc > 8.0 and dc < land.FENCE_D - 4.0 and r.randf() < 0.3:
		var x := cx + r.randf_range(-6.0, 6.0)
		var z := cz + r.randf_range(-6.0, 6.0)
		if land.track_w(x, z) == 0.0 and land.apron_w(x, z) == 0.0 and land.dist(x, z) > 6.0:
			# a patch of rank grass and weeds: plants are never harmed here
			for i in r.randi_range(8, 16):
				var px := x + r.randf_range(-1.6, 1.6)
				var pz := z + r.randf_range(-1.6, 1.6)
				var s := r.randf_range(0.45, 0.8)
				var yaw := r.randf() * TAU
				br.append_array([cos(yaw) * s, 0, sin(yaw) * s, px, 0, s, 0, land.h(px, pz) - 0.03, -sin(yaw) * s, 0, cos(yaw) * s, pz])
	_mm(parent, tuft, "l10l_veg", bt, false, 48.0)
	_mm(parent, reed, "l10l_veg", br, false, 70.0)
	_mm(parent, stalk, "l10l_veg", bs, false, 60.0)


func _mm(parent: Node3D, mesh: Mesh, mat: String, buf: PackedFloat32Array, shadow: bool, vis: float) -> void:
	if buf.is_empty() or mesh == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = buf.size() / 12
	mm.buffer = buf
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MatLib.get_mat(mat)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis > 0.0:
		mi.visibility_range_end = vis
		mi.visibility_range_end_margin = vis * 0.15
	parent.add_child(mi)


# ---------------------------------------------------------------- prototype meshes

func _blade(st: SurfaceTool, a: Vector3, b: Vector3, hw: float, side: Vector3, col: Color, tip: float) -> void:
	var nrm := side.cross(b - a).normalized()
	st.set_normal(nrm)
	st.set_color(col * 0.8)
	st.add_vertex(a - side * hw)
	st.set_color(col * 0.8)
	st.add_vertex(a + side * hw)
	st.set_color(col)
	st.add_vertex(b + side * hw * tip)
	st.set_color(col * 0.8)
	st.add_vertex(a - side * hw)
	st.set_color(col)
	st.add_vertex(b + side * hw * tip)
	st.set_color(col)
	st.add_vertex(b - side * hw * tip)


## kind 0 = bank grass tuft, 1 = reeds, 2 = wheat stalks with ears.
func _clump(kind: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 4100 + kind
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = [22, 14, 9][kind]
	for s in n:
		var a := r.randf() * TAU
		var rad: float = sqrt(r.randf()) * float([0.12, 0.2, 0.24][kind])
		var base := Vector3(cos(a) * rad, 0, sin(a) * rad)
		var yaw := r.randf() * PI
		var side := Vector3(cos(yaw), 0, sin(yaw))
		var v := r.randf_range(0.85, 1.15)
		match kind:
			0:
				var lean := Vector3(cos(a), 0, sin(a)) * r.randf_range(0.04, 0.2)
				var top := base + lean + Vector3(0, r.randf_range(0.16, 0.42), 0)
				var col := Color(0.16, 0.24, 0.07).lerp(Color(0.36, 0.36, 0.18), r.randf() * r.randf()) * v
				_blade(st, base, top, 0.009, side, col, 0.1)
			1:
				var lean := Vector3(cos(a), 0, sin(a)) * r.randf_range(0.02, 0.25)
				var top := base + lean + Vector3(0, r.randf_range(0.8, 1.6), 0)
				var col := Color(0.14, 0.2, 0.07).lerp(Color(0.3, 0.3, 0.13), r.randf() * r.randf()) * v
				_blade(st, base, top, 0.011, side, col, 0.12)
			2:
				var lean := Vector3(r.randf_range(-0.07, 0.07), 0, r.randf_range(-0.07, 0.07))
				var top := base + lean + Vector3(0, r.randf_range(0.82, 1.02), 0)
				_blade(st, base, top, 0.008, side, Color(0.56, 0.46, 0.27) * v, 1.0)
				var e := top + (top - base).normalized() * 0.11
				_blade(st, top, e, 0.019, side, Color(0.8, 0.64, 0.35) * v, 0.6)
				_blade(st, top, e, 0.019, Vector3(-side.z, 0, side.x), Color(0.74, 0.58, 0.31) * v, 0.6)
	return st.commit()


func _blob(sub: int, sd: int) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6 + sub * 3
	sm.rings = 4 + sub * 2
	var arr := sm.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var noise := FastNoiseLite.new()
	noise.seed = sd
	noise.frequency = 1.3
	var cols := PackedColorArray()
	cols.resize(vs.size())
	for i in vs.size():
		var p := vs[i]
		var f := 0.85 + 0.3 * noise.get_noise_3dv(p)
		if p.y < 0.0:
			f *= 0.85
		vs[i] = p * f
		cols[i] = Color(clampf(0.5 + p.y * 0.5, 0.0, 1.0), 0, 0)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


func _trunk() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		for v in [[p0, 0.0], [p1, 0.0], [p1 * 0.55, 1.0], [p0, 0.0], [p1 * 0.55, 1.0], [p0 * 0.55, 1.0]]:
			var pp: Vector3 = v[0]
			st.set_normal(Vector3(pp.x, 0, pp.z).normalized())
			st.add_vertex(pp + Vector3.UP * float(v[1]))
	return st.commit()
