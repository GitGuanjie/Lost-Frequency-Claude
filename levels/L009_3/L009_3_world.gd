extends RefCounted
## Level 9.3 world model. The whole terrain is periodic with period P in x and z:
## ground height, the one warping highway, the brick wall under its steel net, the
## forest band, the hills and the wheat maze are all functions of (x mod P, z mod P),
## so walking straight through the forest brings you back to the same fields (the
## page's Möbius terrain, ADAPTATION as a torus). Chunks are 48 m; the playable world
## is a finite streaming window that repeats.

const P := 384.0
const CS := 48.0
const CELL := 8.0
const NC := 48                 # maze cells per period side
const CORR := 1.35             # half width of a wheat corridor
const ROAD_HW := 3.6
const FOREST_E := 34.0         # forest band: u in [P - 50, P) U [0, FOREST_E)
const FOREST_W := 334.0
# hill centres (u, v, height, sigma)
const HILLS := [[156.0, 112.0, 9.0, 17.0], [272.0, 262.0, 12.0, 20.0], [206.0, 334.0, 7.0, 15.0]]
const MEADOWS := [[128.0, 132.0, 16.0], [246.0, 236.0, 14.0], [40.0, 150.0, 6.0]]

var seed_v := 0
var links := PackedByteArray()      # per cell: bit0 +x, bit1 +z (link to neighbour)
var cell_h := PackedFloat32Array()


func _init(sd: int) -> void:
	seed_v = sd
	_maze()


static func wrapf_p(x: float) -> float:
	return fposmod(x, P)


static func dwrap(a: float, b: float) -> float:
	var d := fposmod(a - b + P * 0.5, P) - P * 0.5
	return d


static func road_u(v: float) -> float:
	return 66.0 + 9.0 * sin(TAU * v / P) + 4.0 * sin(TAU * 2.0 * v / P + 1.3)


static func base_h(u: float, v: float) -> float:
	var k := TAU / P
	var h := 2.2 * sin(k * 2.0 * u + 0.7) * cos(k * v) + 1.3 * sin(k * (3.0 * u + 2.0 * v) + 2.1)
	h += 0.6 * sin(k * (5.0 * u - 3.0 * v) + 0.3) + 0.28 * sin(k * (11.0 * u + 7.0 * v)) + 0.22 * cos(k * (9.0 * u - 13.0 * v) + 1.0)
	return h


static func forest_w(u: float) -> float:
	# 1 inside the forest band, 0 in the fields; soft 12 m edges
	var e := u if u < 200.0 else u - P
	return smoothstep(FOREST_E + 6.0, FOREST_E - 6.0, e) * smoothstep(FOREST_W - P - 6.0, FOREST_W - P + 6.0, e)


static func road_h(v: float) -> float:
	return base_h(road_u(v), v)


static func h_at(x: float, z: float) -> float:
	var u := wrapf_p(x)
	var v := wrapf_p(z)
	var h := base_h(u, v)
	for hl in HILLS:
		var du := dwrap(u, hl[0])
		var dv := dwrap(v, hl[1])
		var d2 := du * du + dv * dv
		var s: float = hl[3]
		var top: float = hl[2]
		h += top * exp(-d2 / (2.0 * s * s))
		# a level pad for the house on the summit
		var pad := 1.0 - smoothstep(9.5, 13.5, sqrt(d2))
		h = lerpf(h, base_h(hl[0], hl[1]) + top, pad)
	var fw := forest_w(u)
	h += fw * (5.0 + 3.0 * sin(TAU * 3.0 * v / P + 0.4) + 2.0 * sin(TAU * 7.0 * v / P))
	var dr := absf(dwrap(u, road_u(v)))
	var w := 1.0 - smoothstep(ROAD_HW + 2.0, ROAD_HW + 11.0, dr)
	return lerpf(h, road_h(v), w)


## Frame of house i (period-local): origin at the front centre at floor-pad height,
## local -z is the front (facing the meadow below), local +z the back.
static func house_xf(i: int) -> Transform3D:
	var hl: Array = HILLS[i]
	var to: Vector2 = Vector2(MEADOWS[i][0], MEADOWS[i][1]) if i < 2 else Vector2(road_u(hl[1]), hl[1])
	var d := Vector2(dwrap(to.x, hl[0]), dwrap(to.y, hl[1])).normalized()
	var yaw := atan2(-d.x, -d.y)
	var bas := Basis(Vector3.UP, yaw)
	var summit := Vector3(hl[0], 0.0, hl[1])
	summit.y = h_at(summit.x, summit.z)
	return Transform3D(bas, summit - bas * Vector3(0, 0, 5.5))


func on_road(x: float, z: float) -> bool:
	return absf(dwrap(wrapf_p(x), road_u(wrapf_p(z)))) < ROAD_HW


# ------------------------------------------------------------------ the maze

func _maze() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "maze"])
	var n := NC * NC
	links.resize(n)
	links.fill(0)
	cell_h.resize(n)
	for i in n:
		cell_h[i] = r.randf_range(2.6, 3.5)
	var seen := PackedByteArray()
	seen.resize(n)
	var stack: Array = [0]
	seen[0] = 1
	while not stack.is_empty():
		var c: int = stack[stack.size() - 1]
		var cx := c % NC
		var cz := c / NC
		var opts: Array = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx := posmod(cx + d.x, NC)
			var nz := posmod(cz + d.y, NC)
			if seen[nz * NC + nx] == 0:
				opts.append(d)
		if opts.is_empty():
			stack.pop_back()
			continue
		var d2: Vector2i = opts[r.randi() % opts.size()]
		var nx2 := posmod(cx + d2.x, NC)
		var nz2 := posmod(cz + d2.y, NC)
		_link(cx, cz, nx2, nz2, d2)
		seen[nz2 * NC + nx2] = 1
		stack.append(nz2 * NC + nx2)
	# a few extra openings make loops (labyrinth, not a tree)
	for i in n / 9:
		var c3 := r.randi() % n
		if r.randf() < 0.5:
			links[c3] |= 1
		else:
			links[c3] |= 2


func _link(ax: int, az: int, bx: int, bz: int, d: Vector2i) -> void:
	if d == Vector2i(1, 0):
		links[az * NC + ax] |= 1
	elif d == Vector2i(-1, 0):
		links[bz * NC + bx] |= 1
	elif d == Vector2i(0, 1):
		links[az * NC + ax] |= 2
	else:
		links[bz * NC + bx] |= 2


func linked(cx: int, cz: int, dir: int) -> bool:
	# dir 0 +x, 1 -x, 2 +z, 3 -z
	cx = posmod(cx, NC)
	cz = posmod(cz, NC)
	match dir:
		0: return links[cz * NC + cx] & 1 != 0
		1: return links[cz * NC + posmod(cx - 1, NC)] & 1 != 0
		2: return links[cz * NC + cx] & 2 != 0
	return links[posmod(cz - 1, NC) * NC + cx] & 2 != 0


## Is this maze cell grown with wheat? (not road, forest, hill summits or meadows)
static func is_wheat(cx: int, cz: int) -> bool:
	var u := (posmod(cx, NC) + 0.5) * CELL
	var v := (posmod(cz, NC) + 0.5) * CELL
	if forest_w(u) > 0.05:
		return false
	if absf(dwrap(u, road_u(v))) < ROAD_HW + 9.0:
		return false
	for hl in HILLS:
		var d := Vector2(dwrap(u, hl[0]), dwrap(v, hl[1])).length()
		if d < float(hl[3]) * 1.15:
			return false
	for m in MEADOWS:
		if Vector2(dwrap(u, m[0]), dwrap(v, m[1])).length() < float(m[2]):
			return false
	# patchy margins: some cells left as grass
	return fposmod(sin(cx * 12.9898 + cz * 78.233) * 43758.5453, 1.0) > 0.06


## Wheat blocks of one cell: [min, max] corners (world), heights from the terrain.
func wheat_blocks(cx: int, cz: int) -> Array:
	var out: Array = []
	var x0 := cx * CELL
	var z0 := cz * CELL
	var t := CELL * 0.5 - CORR
	var top := h_at(x0 + CELL * 0.5, z0 + CELL * 0.5) + cell_h[posmod(cz, NC) * NC + posmod(cx, NC)]
	var add := func(a: Vector2, b: Vector2) -> void:
		var lo := minf(minf(h_at(a.x, a.y), h_at(b.x, b.y)), minf(h_at(a.x, b.y), h_at(b.x, a.y))) - 0.4
		out.append([Vector3(a.x, lo, a.y), Vector3(b.x, top, b.y)])
	# north/south strips run the full cell width (corners included), split by a link
	for side in [0, 1]:
		var zz := z0 if side == 0 else z0 + CELL - t
		var open := linked(cx, cz, 3 if side == 0 else 2)
		if open:
			add.call(Vector2(x0, zz), Vector2(x0 + t, zz + t))
			add.call(Vector2(x0 + CELL - t, zz), Vector2(x0 + CELL, zz + t))
		else:
			add.call(Vector2(x0, zz), Vector2(x0 + CELL, zz + t))
	# west/east middle pieces only where there is no link
	for side in [0, 1]:
		var xx := x0 if side == 0 else x0 + CELL - t
		if not linked(cx, cz, 1 if side == 0 else 0):
			add.call(Vector2(xx, z0 + t), Vector2(xx + t, z0 + CELL - t))
	return out


# ----------------------------------------------------------------- materials

const WHEAT := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
varying vec3 wp;
varying vec3 wn;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment() {
	vec3 base = mix(vec3(0.66, 0.56, 0.33), vec3(0.78, 0.68, 0.42), vn(wp.xz * 0.15));
	base *= 0.82 + 0.3 * vn(wp.xz * 3.0);
	vec3 c = base;
	if (abs(wn.y) < 0.5) {
		float e = abs(wn.x) > 0.5 ? wp.z : wp.x;
		float lay = COLOR.r;
		float top = UV.y;
		float s = e * 30.0 + lay * 0.37;
		float r1 = hsh(vec2(floor(s), lay * 7.0 + 1.0));
		float ht = top - 0.05 - r1 * 0.35;
		float y = wp.y;
		if (y > ht) { discard; }
		float ear = smoothstep(ht - 0.2, ht - 0.14, y);
		float fw = fwidth(s);
		float wid = mix(0.12, 0.32, ear) + fw * 0.5;
		if (lay < 0.6 && abs(fract(s) - 0.5) > wid && fw < 0.6) { discard; }
		float foot = smoothstep(top - 3.6, top - 2.2, y);
		vec3 stem = base * mix(0.45, 0.82, foot) * (0.85 + 0.3 * r1);
		c = mix(stem, base * (0.95 + 0.3 * r1), ear);
		c *= mix(1.0, 0.62, lay);
	} else {
		c *= 0.8 + 0.4 * vn(wp.xz * 9.0);
	}
	ALBEDO = c * c;
	ROUGHNESS = 0.9;
	BACKLIGHT = ALBEDO * 0.45;
}
"""

const GRASS := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void fragment() {
	float s = UV.x * 16.0;
	float r1 = hsh(vec2(floor(s), 3.7));
	float ht = 0.35 + 0.65 * r1;
	if (UV.y > ht) { discard; }
	float wid = mix(0.45, 0.12, UV.y / ht);
	if (abs(fract(s) - 0.5) > wid) { discard; }
	vec3 c = mix(vec3(0.05, 0.06, 0.025), vec3(0.13, 0.15, 0.06), UV.y / ht) * (0.8 + 0.4 * r1);
	ALBEDO = c;
	ROUGHNESS = 0.9;
	BACKLIGHT = c * 0.15;
}
"""

const NET := """
shader_type spatial;
render_mode cull_disabled;
void fragment() {
	vec2 g = UV * 6.0;
	vec2 d = vec2(fract(g.x + g.y), fract(g.x - g.y));
	float w = min(min(d.x, 1.0 - d.x), min(d.y, 1.0 - d.y));
	if (w > 0.06) { discard; }
	ALBEDO = vec3(0.32, 0.3, 0.28);
	METALLIC = 0.7;
	ROUGHNESS = 0.45;
}
"""

const SKYIMG := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, depth_draw_never, shadows_disabled;
uniform float alpha = 0.10;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz / 384.0 * 6.2831;
	float fields = vn(wp.xz * 0.012) * 0.6 + vn(wp.xz * 0.04) * 0.4;
	float road = 1.0 - smoothstep(0.0, 0.012, abs(sin(p.y * 0.5 + sin(p.x) * 0.3)));
	vec3 c = mix(vec3(0.42, 0.45, 0.33), vec3(0.6, 0.55, 0.38), smoothstep(0.4, 0.6, fields));
	c = mix(c, vec3(0.2, 0.2, 0.2), road);
	float edge = 1.0 - smoothstep(0.25, 0.5, length(UV - vec2(0.5)));
	ALBEDO = c;
	ALPHA = alpha * edge * (0.7 + 0.3 * vn(wp.xz * 0.02));
}
"""


static func _shader(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


static func _orm(name: String, tex: String, tint: Color, scale: float) -> void:
	var m := ORMMaterial3D.new()
	var base := "res://assets/external/%s/%s_%s_1k.jpg"
	m.albedo_texture = load(base % [tex, tex, "diff"])
	m.normal_enabled = true
	m.normal_texture = load(base % [tex, tex, "nor_gl"])
	m.orm_texture = load(base % [tex, tex, "arm"])
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	MatLib.register(name, m)


static func materials() -> void:
	_orm("l93_grass", "sparse_grass", Color(0.78, 0.92, 0.6), 0.28)
	_orm("l93_asphalt", "asphalt_02", Color(0.62, 0.62, 0.63), 0.22)
	_orm("l93_mud", "dirt_floor", Color(0.55, 0.5, 0.42), 0.3)
	MatLib.register("l93_wheat", _shader(WHEAT))
	MatLib.register("l93_net", _shader(NET))
	MatLib.register("l93_tuft", _shader(GRASS))
	MatLib.register("l93_skyimg", _shader(SKYIMG))
	MatLib.define("l93_wall", {"albedo_a": Color(0.38, 0.3, 0.25), "albedo_b": Color(0.3, 0.27, 0.22), "pattern": 4,
		"pattern_scale": Vector2(0.24, 0.08), "grout_width": 0.016, "grout_color": Color(0.22, 0.24, 0.17),
		"stain_amount": 0.75, "stain_color": Color(0.16, 0.24, 0.09), "stain_scale": 1.6, "wetness": 0.75,
		"grime_height": 0.6, "grime_color": Color(0.12, 0.17, 0.07), "bump_strength": 1.6}, "brick")
	MatLib.define("l93_cobble", {"albedo_a": Color(0.36, 0.35, 0.32), "albedo_b": Color(0.28, 0.28, 0.25), "pattern": 14,
		"pattern_scale": Vector2(0.22, 0.17), "grout_width": 0.03, "grout_color": Color(0.14, 0.2, 0.08), "stain_amount": 0.7,
		"stain_color": Color(0.17, 0.25, 0.1), "wetness": 0.8, "bump_strength": 2.0}, "concrete")
	MatLib.define("l93_line", {"albedo_a": Color(0.68, 0.66, 0.58), "albedo_b": Color(0.6, 0.58, 0.5), "stain_amount": 0.5,
		"stain_color": Color(0.3, 0.3, 0.27), "roughness_a": 0.7}, "plaster")
	MatLib.register("l93_bark", MatLib.standard(Color(0.16, 0.14, 0.11), 0.95))
	var leaf := MatLib.standard(Color(0.1, 0.15, 0.08), 0.9)
	MatLib.register("l93_leaf", leaf)
	MatLib.register("l93_leaf_dark", MatLib.standard(Color(0.07, 0.1, 0.06), 0.95))
	MatLib.register("l93_bush", MatLib.standard(Color(0.12, 0.17, 0.08), 0.95))
