extends RefCounted
## Level 5 "The Boiler Room": large, cluttered and claustrophobic. Vintage boilers
## and furnaces, intertwined pipes with exhaust valves, Almond Water leaking
## under pressure, hot and steam-filled yet dry. It runs south under the hotel
## and gets hotter the deeper you go; the far end drops to Level 6 (extreme heat).
## Also: M.E.G. "Housekeeping" post, maintenance elevator (not advised), and the
## arcade cabinet that leads to Level 40.

const T := 0.3
var L: Node3D
var P: RefCounted
var W: RefCounted
var k: GeoKit
var node: Node3D
var lights: LightPool
var sporadic: Array = []     # [{pos, recipe, params, min, max, caption, vol, dist, t}]
var steam: Array = []


func _init(level: Node3D, props: RefCounted, hotel: RefCounted) -> void:
	L = level
	P = props
	W = hotel


## Heat 0..1 by depth along the complex (z grows southward, deeper).
static func heat_at(p: Vector3) -> float:
	if p.y > -1.6 or p.x < 2.0 or p.x > 36.0 or p.z < 3.0:
		return 0.0
	return clampf(0.22 + maxf(0.0, p.z - 20.0) * 0.0108, 0.22, 1.0)


func _room(x0: float, z0: float, x1: float, z1: float, yf: float, yc: float, ops: Dictionary, mat := "l5_boiler_brick") -> void:
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	k.box_mm(Vector3(x0, yf - 0.3, z0), Vector3(x1, yf, z1), "l5_boiler_floor", GeoKit.PY)
	k.box_mm(Vector3(x0, yc, z0), Vector3(x1, yc + 0.3, z1), "l5_boiler_ceiling", GeoKit.NY, false)
	var sides := {"n": [Vector3(x0, 0, z0 - T * 0.5), Vector3(x1, 0, z0 - T * 0.5)], "e": [Vector3(x1 + T * 0.5, 0, z0), Vector3(x1 + T * 0.5, 0, z1)],
		"s": [Vector3(x1, 0, z1 + T * 0.5), Vector3(x0, 0, z1 + T * 0.5)], "w": [Vector3(x0 - T * 0.5, 0, z1), Vector3(x0 - T * 0.5, 0, z0)]}
	for sd in sides.keys():
		if ops.get(sd, []) is String:
			continue
		var o: Array = []
		for op in ops.get(sd, []):
			var at: float = op[0]
			match sd:
				"n": at = op[0] - x0
				"e": at = op[0] - z0
				"s": at = x1 - op[0]
				"w": at = z1 - op[0]
			o.append({"at": at, "w": op[1], "h": op[2]})
		o.sort_custom(func(p, q): return p["at"] < q["at"])
		W.wall(k, sides[sd][0], sides[sd][1], yf, yc, T, mat, o, f, true)


func _bulb(p: Vector3, energy := 1.15, rng := 8.5, col := Color(1.0, 0.72, 0.42), flick := 0.0) -> void:
	k.cylinder(p + Vector3.UP * 0.25, 0.012, 0.5, "l5_rail", 4, false)
	k.cylinder(p, 0.07, 0.14, "l5_bulb", 8, false)
	for q in 4:
		var a := q * PI * 0.5
		k.box(p + Vector3(cos(a) * 0.1, -0.02, sin(a) * 0.1), Vector3(0.012, 0.22, 0.012), "l5_rail", GeoKit.ALL, false)
	lights.add_anchor(p + Vector3.DOWN * 0.15, col, energy, rng, flick)


func _pipe_run(a: Vector3, b: Vector3, r: float, mat: String) -> void:
	P.tube(k, a, b, r, mat, 8)
	var d := (b - a)
	var length := d.length()
	var steps := int(length / 2.4)
	for q in range(1, steps):
		var c := a + d * (float(q) / steps)
		P.tube(k, c - d.normalized() * 0.05, c + d.normalized() * 0.05, r * 1.35, "l5_pipe_rust", 8)


func _vboiler(c: Vector3, r: float, h: float) -> void:
	k.cylinder(c + Vector3.UP * (h * 0.5), r, h, "l5_boiler_iron", 18, true)
	k.cylinder(c + Vector3.UP * (h + 0.2), r * 0.72, 0.4, "l5_boiler_iron", 16, false)
	for y in [0.35, h * 0.5, h - 0.3]:
		k.cylinder(c + Vector3.UP * y, r + 0.03, 0.08, "l5_pipe_rust", 18, false)
	P.tube(k, c + Vector3.UP * (h + 0.35), c + Vector3.UP * (h + 1.7), 0.16, "l5_pipe_brass", 8)
	var gauge := c + Vector3(0, 1.5, r + 0.04)
	P.tube(k, gauge, gauge + Vector3(0, 0, 0.05), 0.12, "l5_trim_gold", 12)
	P.tube(k, gauge + Vector3(0, 0, 0.05), gauge + Vector3(0, 0, 0.056), 0.1, "l5_gauge", 12)
	_add_sound(c + Vector3.UP * 1.5, "transformer", {"base": 38.0}, -17.0, 11.0)


func _hboiler(x: float, z0: float, z1: float, y: float, r: float) -> void:
	P.tube(k, Vector3(x, y, z0), Vector3(x, y, z1), r, "l5_boiler_iron", 18, true)
	for z in [z0, z1]:
		_disc(Vector3(x, y, z), Vector3(0, 0, signf(z - (z0 + z1) * 0.5)), r, "l5_boiler_iron")
	var zz := z0 + 1.0
	while zz < z1:
		P.tube(k, Vector3(x, y, zz), Vector3(x, y, zz + 0.08), r + 0.03, "l5_pipe_rust", 18)
		zz += 2.2
	for z in [z0 + 1.2, (z0 + z1) * 0.5, z1 - 1.2]:
		k.box(Vector3(x, y - r * 0.75, z), Vector3(r * 1.6, r * 0.6, 0.35), "l5_boiler_iron", GeoKit.ALL, false)
	P.tube(k, Vector3(x, y + r, (z0 + z1) * 0.5), Vector3(x, y + r + 1.4, (z0 + z1) * 0.5), 0.22, "l5_pipe_brass", 8)
	_add_sound(Vector3(x, y, (z0 + z1) * 0.5), "transformer", {"base": 33.0}, -16.0, 12.0)


func _disc(c: Vector3, n: Vector3, r: float, mat: String, sides := 18) -> void:
	var u := n.cross(Vector3.UP).normalized()
	var v := n.cross(u).normalized()
	for q in sides:
		var a0 := TAU * q / sides
		var a1 := TAU * (q + 1) / sides
		k._tri_fan(c, c + (u * cos(a0) + v * sin(a0)) * r, c + (u * cos(a1) + v * sin(a1)) * r, n, mat)


func _wheel(c: Vector3, n: Vector3) -> void:
	P.tube(k, c, c + n * 0.03, 0.17, "l5_valve_red", 10)
	P.tube(k, c - n * 0.12, c, 0.03, "l5_pipe_rust", 6)


func _add_sound(pos: Vector3, recipe: String, params: Dictionary, db: float, dist: float) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = db
	p.max_distance = dist
	p.unit_size = 2.5
	p.bus = "Ambience"
	p.position = pos
	p.autoplay = true
	node.add_child(p)


func _sporadic(pos: Vector3, recipe: String, params: Dictionary, mn: float, mx: float, caption: String, db: float, dist: float) -> void:
	sporadic.append({"pos": pos, "recipe": recipe, "params": params, "min": mn, "max": mx, "caption": caption, "vol": db, "dist": dist, "t": mn * 0.5})


static var _steam_mat: ShaderMaterial = null


## Soft round billboard puffs (no textures): radial alpha falloff in-shader.
static func steam_mat() -> ShaderMaterial:
	if _steam_mat == null:
		var sh := Shader.new()
		sh.code = "shader_type spatial;\nrender_mode unshaded, depth_draw_never, cull_disabled;\nuniform vec4 tint : source_color = vec4(0.7, 0.66, 0.6, 0.22);\nvoid vertex() {\n\tMODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz), INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz), INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);\n}\nvoid fragment() {\n\tfloat d = length(UV - 0.5) * 2.0;\n\tALBEDO = tint.rgb * COLOR.rgb;\n\tALPHA = tint.a * COLOR.a * smoothstep(1.0, 0.0, d) * smoothstep(1.0, 0.0, d);\n}\n"
		_steam_mat = ShaderMaterial.new()
		_steam_mat.shader = sh
	return _steam_mat


func _steam(pos: Vector3, dir: Vector3, amount: int) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 2.6
	p.direction = dir
	p.spread = 22.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.4
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.9)
	qm.material = steam_mat()
	p.mesh = qm
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
	p.color_ramp = g
	node.add_child(p)
	steam.append(p)


func build(parent: Node3D) -> void:
	node = Node3D.new()
	node.name = "BoilerRoom"
	parent.add_child(node)
	lights = LightPool.new()
	lights.name = "BoilerLights"
	node.add_child(lights)
	lights.setup(10, 1)
	lights.max_distance = 28.0
	k = GeoKit.new(node, "Boiler")
	# the sourced way down to Level 6 is created first (QA walker target)
	L.make_exit("L005>L006#3", "walk_in", Vector3(16.0, -9.0, 98.7), Vector3(3.0, 2.2, 2.4), "", node)
	var bh := -1.6
	# ---------------------------------------------------------------- B1
	_room(3.2, 9.6, 28.8, 22.4, -5.0, bh,
		{"s": "skip", "w": [[15.0, 2.2, -2.55], [19.5, 2.2, -2.55]]})
	W.wall(k, Vector3(28.8, 0, 22.55), Vector3(19.2, 0, 22.55), -5.0, bh, T, "l5_boiler_brick", [{"at": 4.8, "w": 2.8, "h": -2.5}], GeoKit.PZ | GeoKit.PX | GeoKit.NX, true)
	_vboiler(Vector3(11.0, -5.0, 14.2), 1.35, 3.0)
	_vboiler(Vector3(18.6, -5.0, 14.2), 1.35, 3.0)
	for y in [-1.9, -2.25, -2.6]:
		_pipe_run(Vector3(6.3, y, 9.95 + (y + 2.2) * 0.3), Vector3(28.6, y, 9.95 + (y + 2.2) * 0.3), 0.11 if y < -2.0 else 0.15, "l5_pipe_green" if y > -2.0 else "l5_pipe_rust")
	for y in [-1.9, -2.3]:
		_pipe_run(Vector3(28.4, y, 9.8), Vector3(28.4, y, 22.2), 0.13, "l5_pipe_brass")
	_pipe_run(Vector3(11.0, -1.85, 9.8), Vector3(11.0, -1.85, 22.2), 0.17, "l5_pipe_rust")
	for z in [17.4, 20.1]:
		_pipe_run(Vector3(4.7, -2.6, z), Vector3(28.6, -2.6, z), 0.12, "l5_pipe_rust" if z < 18.0 else "l5_pipe_green")
		_pipe_run(Vector3(4.7, -2.25, z + 0.35), Vector3(28.6, -2.25, z + 0.35), 0.09, "l5_pipe_brass")
	for rp in [Vector3(9.0, 0, 17.2), Vector3(15.5, 0, 17.2), Vector3(21.5, 0, 17.2), Vector3(13.0, 0, 21.95), Vector3(17.6, 0, 21.95)]:
		_pipe_run(Vector3(rp.x, -5.0, rp.z), Vector3(rp.x, bh, rp.z), 0.14, "l5_pipe_rust")
		P.tube(k, Vector3(rp.x, -3.7, rp.z), Vector3(rp.x, -3.6, rp.z), 0.2, "l5_pipe_rust", 8)
	_wheel(Vector3(9.0, -3.6, 17.2) + Vector3(0, 0, 0.22), Vector3(0, 0, 1))
	_wheel(Vector3(21.5, -3.3, 17.2) + Vector3(0, 0, 0.22), Vector3(0, 0, 1))
	_wheel(Vector3(28.15, -3.2, 12.0), Vector3(-1, 0, 0))
	_steam(Vector3(18.6, -1.9, 14.2), Vector3(0, -0.2, 1), 10)
	_steam(Vector3(15.5, -2.6, 17.4), Vector3(0, 0.3, 1), 7)
	for z in [13.1, 13.8, 21.2, 21.9]:
		_pipe_run(Vector3(3.45, -5.0, z), Vector3(3.45, bh, z), 0.12, "l5_pipe_rust" if z < 15.0 else "l5_pipe_green")
	for y in [-4.3, -3.5]:
		_pipe_run(Vector3(7.8, y, 22.15), Vector3(19.0, y, 22.15), 0.12, "l5_pipe_brass" if y < -4.0 else "l5_pipe_rust")
	for z in [10.4, 13.2, 20.6]:
		_pipe_run(Vector3(28.55, -5.0, z), Vector3(28.55, bh, z), 0.1, "l5_pipe_green")
	P.tube(k, Vector3(25.2, -4.0, 10.3), Vector3(25.2, -4.0, 15.3), 0.9, "l5_boiler_iron", 16, true)
	_disc(Vector3(25.2, -4.0, 10.3), Vector3(0, 0, -1), 0.9, "l5_boiler_iron")
	_disc(Vector3(25.2, -4.0, 15.3), Vector3(0, 0, 1), 0.9, "l5_boiler_iron")
	for z in [11.0, 14.6]:
		k.box(Vector3(25.2, -4.72, z), Vector3(1.4, 0.56, 0.3), "l5_boiler_iron", GeoKit.ALL, false)
	P.tube(k, Vector3(25.2, -3.1, 12.8), Vector3(25.2, bh, 12.8), 0.14, "l5_pipe_brass", 8)
	k.box(Vector3(15.0, -3.2, 9.65), Vector3(2.4, 1.2, 0.08), "l5_boiler_iron", GeoKit.ALL, false)
	for q in 4:
		var gp := Vector3(14.1 + q * 0.6, -3.05 - (q % 2) * 0.32, 9.7)
		P.tube(k, gp, gp + Vector3(0, 0, 0.05), 0.15, "l5_trim_gold", 12)
		P.tube(k, gp + Vector3(0, 0, 0.05), gp + Vector3(0, 0, 0.056), 0.125, "l5_gauge", 12)
	k.box(Vector3(27.9, -4.55, 20.6), Vector3(1.4, 0.06, 0.7), "l5_wood", GeoKit.ALL, true)
	for sz in [-0.3, 0.3]:
		k.box(Vector3(27.9, -4.8, 20.6 + sz), Vector3(1.3, 0.45, 0.05), "l5_wood", GeoKit.ALL, false)
	k.box(Vector3(27.7, -4.45, 20.5), Vector3(0.4, 0.15, 0.25), "l5_boiler_iron", GeoKit.ALL, false)
	_meg_post()
	_maintenance_lift()
	_arcade(Vector3(28.6, -5.0, 17.0))
	_deep_inspection_annex()
	for p in [Vector3(6.5, -2.1, 19.0), Vector3(14.0, -2.1, 19.4), Vector3(22.5, -2.1, 19.0), Vector3(15.0, -2.1, 11.6), Vector3(26.6, -2.1, 12.4)]:
		_bulb(p, 1.05, 7.5, Color(1.0, 0.72, 0.42), 0.05)
	_sporadic(Vector3(11.0, -1.85, 17.0), "drip", {"freq": 900.0}, 4.0, 11.0, "", -12.0, 12.0)
	_sporadic(Vector3(26.0, -2.0, 12.0), "pipe_clank", {"f": 180.0}, 9.0, 26.0, "[pipes knock somewhere in the walls]", -10.0, 26.0)
	# ---------------------------------------------------------------- P1
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	k.box_mm(Vector3(22.6, -5.3, 22.4), Vector3(25.4, -5.0, 38.3), "l5_boiler_floor", GeoKit.PY)
	k.box_mm(Vector3(22.6, -2.4, 22.4), Vector3(25.4, -2.1, 39.2), "l5_boiler_ceiling", GeoKit.NY, false)
	W.wall(k, Vector3(22.45, 0, 39.2), Vector3(22.45, 0, 22.4), -5.6, -2.4, T, "l5_boiler_brick", [], f, true)
	W.wall(k, Vector3(25.55, 0, 22.4), Vector3(25.55, 0, 39.2), -5.6, -2.4, T, "l5_boiler_brick", [], f, true)
	for i in 3:
		var y := -4.4 + i * 0.75
		_pipe_run(Vector3(22.8, y, 22.6), Vector3(22.8, y, 38.6), 0.1 + i * 0.02, ["l5_pipe_green", "l5_pipe_rust", "l5_pipe_brass"][i])
		_pipe_run(Vector3(25.2, y + 0.3, 22.6), Vector3(25.2, y + 0.3, 38.6), 0.09, ["l5_pipe_rust", "l5_pipe_brass", "l5_pipe_green"][i])
	_wheel(Vector3(25.0, -3.3, 31.0), Vector3(-1, 0, 0))
	_steam(Vector3(25.0, -2.9, 33.6), Vector3(-1, 0.4, 0), 8)
	k.stairs(Vector3(24.0, -5.6, 39.2), Vector3(0, 0, -1), 2.8, 0.6, 3, "l5_boiler_floor", 0.3, true)
	for p in [Vector3(24.0, -2.65, 27.0), Vector3(24.0, -2.65, 35.0)]:
		_bulb(p, 0.9, 7.0, Color(1.0, 0.7, 0.4), 0.15)
	_sporadic(Vector3(23.0, -2.9, 30.5), "drip", {"freq": 1250.0}, 2.5, 7.0, "[Almond Water drips from a leaking joint]", -9.0, 10.0)
	_sporadic(Vector3(25.0, -3.0, 34.0), "drip", {"freq": 1000.0}, 3.0, 8.0, "", -10.0, 10.0)
	_add_sound(Vector3(25.0, -2.9, 33.6), "static", {"seconds": 2.2}, -27.0, 7.0)
	# ---------------------------------------------------------------- B2
	_room(10.0, 39.2, 35.0, 57.6, -5.6, -1.4, {"n": [[24.0, 2.8, -2.4]], "s": [[20.0, 2.8, -2.6]]})
	_hboiler(13.9, 41.6, 55.4, -3.9, 1.45)
	_hboiler(31.1, 41.6, 55.4, -3.9, 1.45)
	_vboiler(Vector3(18.8, -5.6, 46.6), 1.2, 3.1)
	_vboiler(Vector3(26.6, -5.6, 51.2), 1.2, 3.1)
	k.box(Vector3(28.6, -4.9, 42.2), Vector3(1.8, 1.4, 1.1), "l5_boiler_iron", GeoKit.ALL, true)
	P.tube(k, Vector3(27.65, -4.4, 42.2), Vector3(27.45, -4.4, 42.2), 0.7, "l5_pipe_rust", 14)
	_disc(Vector3(27.45, -4.4, 42.2), Vector3(-1, 0, 0), 0.7, "l5_pipe_rust", 14)
	_add_sound(Vector3(28.6, -4.6, 42.2), "transformer", {"base": 47.0}, -15.0, 12.0)
	for z in [44.0, 49.0, 54.0]:
		_pipe_run(Vector3(10.2, -2.0, z), Vector3(34.8, -2.0, z), 0.16, "l5_pipe_rust")
		_pipe_run(Vector3(10.2, -1.7, z + 0.45), Vector3(34.8, -1.7, z + 0.45), 0.1, "l5_pipe_green")
	_wheel(Vector3(22.0, -2.0, 44.2), Vector3(0, 0, 1))
	_steam(Vector3(18.8, -2.2, 46.6), Vector3(0, 1, 0), 10)
	_steam(Vector3(31.1, -2.2, 48.5), Vector3(0, 1, 0), 10)
	for p in [Vector3(17.0, -2.3, 41.8), Vector3(27.0, -2.3, 46.0), Vector3(21.0, -2.3, 52.5), Vector3(30.0, -2.3, 56.0)]:
		_bulb(p, 1.05, 8.0, Color(1.0, 0.68, 0.38), 0.08)
	_sporadic(Vector3(22.0, -2.0, 49.0), "pipe_clank", {"f": 240.0}, 6.0, 18.0, "[a pipe bangs under pressure]", -8.0, 22.0)
	_sporadic(Vector3(30.0, -2.1, 54.0), "drip", {"freq": 1400.0}, 3.0, 9.0, "", -10.0, 10.0)
	# ---------------------------------------------------------------- P2
	k.ramp(Vector3(20.0, -5.6, 57.6), Vector3(20.0, -6.2, 61.6), 2.8, 0.3, "l5_boiler_floor")
	k.box_mm(Vector3(18.6, -2.4, 57.6), Vector3(21.4, -2.1, 61.6), "l5_boiler_ceiling", GeoKit.NY, false)
	W.wall(k, Vector3(18.45, 0, 61.6), Vector3(18.45, 0, 57.6), -6.4, -2.4, T, "l5_boiler_brick", [], f, true)
	W.wall(k, Vector3(21.55, 0, 57.6), Vector3(21.55, 0, 61.6), -6.4, -2.4, T, "l5_boiler_brick", [], f, true)
	# ---------------------------------------------------------------- B3
	_room(6.0, 61.6, 32.0, 76.0, -6.2, -1.8, {"n": [[20.0, 2.8, -3.2]], "s": [[16.0, 3.2, -3.6]]}, "l5_furnace_brick")
	for fz in [64.6, 70.4]:
		_furnace(Vector3(6.0, -6.2, fz), Vector3(1, 0, 0))
	for fz in [64.6, 70.4]:
		_furnace(Vector3(32.0, -6.2, fz), Vector3(-1, 0, 0))
	_furnace(Vector3(9.4, -6.2, 76.0), Vector3(0, 0, -1))
	_furnace(Vector3(26.6, -6.2, 76.0), Vector3(0, 0, -1))
	k.box(Vector3(25.0, -4.9, 67.6), Vector3(2.6, 2.6, 2.6), "l5_boiler_iron", GeoKit.ALL, true)
	k.box(Vector3(25.0, -3.3, 67.6), Vector3(3.2, 0.6, 3.2), "l5_boiler_iron", GeoKit.ALL, false)
	P.tube(k, Vector3(25.0, -3.0, 67.6), Vector3(25.0, -1.8, 67.6), 0.5, "l5_pipe_rust", 10)
	for q in 5:
		k.box(Vector3(23.2 - q * 0.2, -6.05 + q * 0.04, 67.0 + q * 0.3), Vector3(0.7, 0.3, 0.6), "l5_coal", GeoKit.ALL, false)
	_pipe_run(Vector3(7.4, -2.0, 63.0), Vector3(7.4, -2.0, 75.0), 0.45, "l5_boiler_iron")
	_pipe_run(Vector3(30.6, -2.0, 63.0), Vector3(30.6, -2.0, 75.0), 0.45, "l5_boiler_iron")
	for p in [Vector3(12.4, -6.2, 71.6), Vector3(21.8, -6.2, 73.0)]:
		for q in 6:
			k.box(p + Vector3((q % 3) * 0.5 - 0.5, 0.15 + (q / 3) * 0.22, (q % 2) * 0.4), Vector3(0.7 - q * 0.06, 0.3, 0.6), "l5_coal", GeoKit.ALL, q == 0)
	for z in [64.0, 69.0, 73.5]:
		_pipe_run(Vector3(6.2, -2.3, z), Vector3(31.8, -2.3, z), 0.2, "l5_pipe_rust")
	_bulb(Vector3(20.0, -2.4, 66.0), 0.8, 7.0, Color(1.0, 0.62, 0.32), 0.25)
	_bulb(Vector3(14.0, -2.4, 71.0), 0.7, 7.0, Color(1.0, 0.62, 0.32), 0.2)
	# ---------------------------------------------------------------- D + descent
	k.ramp(Vector3(16.0, -6.2, 76.0), Vector3(16.0, -8.0, 90.8), 3.2, 0.3, "l5_boiler_floor")
	var cd := Vector3(0, -1.8, 14.8).normalized()
	var cu := Vector3(1, 0, 0).cross(cd).normalized()
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), -cu, cd), Vector3(16.0, -4.5, 83.4) - cu * 0.15), Vector3(3.6, 0.3, 14.95), "l5_boiler_ceiling", GeoKit.ALL, false)
	W.wall(k, Vector3(14.25, 0, 100.0), Vector3(14.25, 0, 76.0), -10.3, -3.4, T, "l5_furnace_brick", [], f, true)
	W.wall(k, Vector3(17.75, 0, 76.0), Vector3(17.75, 0, 100.0), -10.3, -3.4, T, "l5_furnace_brick", [], f, true)
	k.box_mm(Vector3(14.1, -10.3, 100.0), Vector3(17.9, -3.4, 100.3), "void_black", GeoKit.NZ, true)
	k.box_mm(Vector3(14.4, -5.6, 90.8), Vector3(17.6, -5.3, 100.0), "void_black", GeoKit.NY, false)
	k.box_mm(Vector3(14.1, -10.3, 92.0), Vector3(14.42, -5.4, 100.0), "void_black", GeoKit.PX, false)
	k.box_mm(Vector3(17.58, -10.3, 92.0), Vector3(17.9, -5.4, 100.0), "void_black", GeoKit.NX, false)
	k.stairs(Vector3(16.0, -10.0, 97.4), Vector3(0, 0, -1), 3.2, 2.0, 10, "l5_boiler_floor", 0.66, true)
	k.box_mm(Vector3(14.4, -10.3, 97.4), Vector3(17.6, -10.0, 100.0), "void_black", GeoKit.PY)
	for i in 2:
		var x := 14.75 if i == 0 else 17.25
		_pipe_run(Vector3(x, -6.0, 76.2), Vector3(x, -7.8, 90.4), 0.26, "l5_pipe_hot")
		_pipe_run(Vector3(x, -4.6, 76.2), Vector3(x, -6.4, 90.4), 0.14, "l5_pipe_rust")
	for z in [80.0, 85.0, 89.0]:
		var y: float = -6.2 - (z - 76.0) / 14.8 * 1.8
		for x in [14.5, 17.5]:
			k.box(Vector3(x, y + 0.1, z), Vector3(0.06, 0.12, 0.8), "l5_vent_glow", GeoKit.ALL, false)
		lights.add_anchor(Vector3(16.0, y + 1.6, z), Color(1.0, 0.42, 0.14), 0.4, 3.4, 0.3)
	_steam(Vector3(16.0, -6.6, 80.5), Vector3(0, 1, 0.3), 16)
	_steam(Vector3(16.0, -7.3, 86.5), Vector3(0, 1, 0.4), 16)
	P.label(node, "TURN BACK - HEAT", Vector3(17.58, -6.0, 84.0), Vector3(-1, 0, 0), 0.0034, Color(0.85, 0.82, 0.72), 14.0)
	_sporadic(Vector3(16.0, -7.0, 85.0), "static", {"seconds": 1.6}, 3.0, 7.0, "[steam hisses from the vents]", -13.0, 10.0)
	k.commit()



## DEV13: optional Boiler Room inspection annex, geometrically below and west
## of B1. Two doorways from the existing source-defined boiler corridor lead
## down distinct switchback routes to a -8.1 m inspection deck. No new canonical
## exit, elevator shortcut or permanent heat immunity is introduced.
func _deep_inspection_annex() -> void:
	var bottom := -8.1
	var top := -5.0
	# Existing B1 west wall supplies the east wall of the annex. Its two
	# real 2.2-m openings are cut in the B1 construction above.
	_room(-13.2, 10.4, 3.2, 29.0, bottom, -1.6, {"e": "skip"})
	# Entry catwalks: both tops align with the old B1 (-5.0) floor.
	k.slab(-3.2, 14.24, 3.6, 15.76, top, 0.20, "l5_steel")
	k.slab(-1.3, 18.74, 3.6, 20.26, top, 0.20, "l5_steel")
	# Two separated stair-like ramps, not a teleport or QA-only geometry.
	# A: upper west door -> central lowering ramp -> north end of deep deck.
	var a0 := Vector3(-3.0, top, 15.0)
	var a1 := Vector3(-3.0, -6.5, 22.0)
	var a2 := Vector3(-10.0, bottom, 22.0)
	k.ramp(a0, a1, 1.4, 0.18, "l5_steel")
	k.ramp(a1, a2, 1.4, 0.18, "l5_steel")
	# B: other west door -> southwards lowering ramp -> south end of deck.
	# Ramp A and B are on different tracks and never intersect overhead.
	var b0 := Vector3(-1.0, top, 19.5)
	var b1 := Vector3(-1.0, -6.5, 27.0)
	var b2 := Vector3(-10.0, bottom, 27.0)
	k.ramp(b0, b1, 1.4, 0.18, "l5_steel")
	k.ramp(b1, b2, 1.4, 0.18, "l5_steel")
	# A deep horizontal return connects both ramp exits at floor elevation.
	k.slab(-11.0, 22.0, -8.9, 27.0, bottom + 0.025, 0.08, "l5_steel")
	for at in [Vector3(-11.45, -6.45, 23.0), Vector3(-11.45, -6.45, 26.0)]:
		k.box(at, Vector3(0.12, 2.9, 0.12), "l5_pipe_rust", GeoKit.ALL, false)
	for at in [Vector3(-3.2, -2.3, 15.0), Vector3(-1.1, -2.3, 19.5), Vector3(-10.3, -2.2, 24.5)]:
		_bulb(at, 0.6, 7.0, Color(1.0, 0.63, 0.36), 0.05)
	# A diagram is an atmospheric clue, not an unlock condition.
	L.add_interactable(Vector3(-10.1, -7.1, 24.5), Vector3(1.15, 1.15, 1.1),
		"Inspect the lower boiler inspection diagram", func(_p):
			Overlay.toast("Two identical maintenance paths terminate at the same numbered shaft.", 4.0))
	L.add_landmark("B1 service door A, inspection annex", Vector3(3.05, top, 15.0))
	L.add_landmark("B1 service door B, inspection annex", Vector3(3.05, top, 19.5))
	L.add_landmark("Sub-floor boiler inspection deck", Vector3(-10.0, bottom, 24.5))

func _furnace(wall_p: Vector3, n: Vector3) -> void:
	var b := Basis(Vector3.UP.cross(n), Vector3.UP, n)
	var c := wall_p + n * 1.1
	k.box_xf(Transform3D(b, c + Vector3.UP * 1.5), Vector3(2.8, 3.0, 2.2), "l5_furnace_brick", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, c + Vector3.UP * 1.25 + n * 1.11), Vector3(1.5, 1.5, 0.04), "l5_boiler_iron", GeoKit.ALL, false)
	var mouth := c + Vector3.UP * 1.05 + n * 1.135
	k.quad(mouth, n, b.x * 0.42, Vector3.UP * 0.28, "l5_furnace_glow")
	for q in 5:
		k.box_xf(Transform3D(b, mouth + b.x * (q - 2) * 0.17 + n * 0.01), Vector3(0.03, 0.58, 0.03), "l5_boiler_iron", GeoKit.ALL, false)
	P.tube(k, c + Vector3.UP * 3.0 - n * 0.3, c + Vector3.UP * 4.6 - n * 0.3, 0.38, "l5_boiler_iron", 10)
	for q in 3:
		k.box(c + n * (1.7 + q * 0.2) + Vector3(q * 0.3 - 0.3, 0.12, 0.0) + Vector3.DOWN * 0.0, Vector3(0.5, 0.24 - q * 0.05, 0.45), "l5_coal", GeoKit.ALL, false)
	lights.add_anchor(mouth + n * 0.9, Color(1.0, 0.42, 0.12), 2.2, 7.5, 0.35)
	_steam(mouth + Vector3.UP * 0.5 + n * 0.1, n * 0.4 + Vector3.UP, 7)
	_sporadic(mouth, "whisper", {}, 14.0, 34.0, "[faint whispering from the furnace]", -15.0, 7.0)
	_sporadic(mouth, "crackle", {"seconds": 1.4}, 2.0, 5.0, "", -12.0, 9.0)
	_add_sound(mouth, "room_tone", {"cutoff": 420.0, "rumble": 0.3}, -14.0, 9.0)


func _meg_post() -> void:
	var c := Vector3(3.65, -5.0, 17.4)
	k.box(c + Vector3(0.05, 0.74, 0), Vector3(0.75, 0.05, 1.5), "l5_wood", GeoKit.ALL, true)
	for sz in [-0.68, 0.68]:
		k.box(c + Vector3(0.05, 0.36, sz), Vector3(0.7, 0.72, 0.05), "l5_wood", GeoKit.ALL, false)
	k.box(c + Vector3(1.0, 0.45, 0.1), Vector3(0.45, 0.06, 0.45), "l5_wood", GeoKit.ALL, true)
	k.box(c + Vector3(1.2, 0.75, 0.1), Vector3(0.05, 0.6, 0.45), "l5_wood", GeoKit.ALL, false)
	k.cylinder(c + Vector3(0.05, 0.86, -0.45), 0.06, 0.2, "l5_trim_gold", 8, false)
	k.box(c + Vector3(0.05, 1.0, -0.45), Vector3(0.18, 0.08, 0.32), "l5_lampshade_green", GeoKit.ALL, false)
	k.box(c + Vector3(0.1, 0.775, 0.2), Vector3(0.3, 0.01, 0.4), "l5_paper", GeoKit.ALL, false)
	lights.add_anchor(c + Vector3(0.2, 0.9, -0.45), Color(0.9, 1.0, 0.85), 0.7, 4.0)
	var board := Vector3(3.22, -3.4, 17.4)
	k.box(board, Vector3(0.04, 1.1, 1.6), "l5_cork", GeoKit.ALL, false)
	for q in 5:
		k.box(board + Vector3(0.03, (q % 2) * 0.35 - 0.15, -0.6 + q * 0.3), Vector3(0.01, 0.28, 0.22), "l5_paper", GeoKit.ALL, false)
	for q in 3:
		k.box(c + Vector3(0.2, 0.25 + q * 0.5, 3.2), Vector3(0.9 - q * 0.1, 0.5, 0.7), "l5_crate", GeoKit.ALL, q == 0)
	P.label(node, "HOUSEKEEPING - M.E.G.", Vector3(3.26, -2.6, 17.4), Vector3(1, 0, 0), 0.0022, Color(0.85, 0.82, 0.72), 12.0)
	var n1 := Interactable.new()
	node.add_child(n1)
	n1.setup(board + Vector3(0.1, 0.0, -0.35), Vector3(0.2, 0.9, 0.7), "Read")
	n1.as_note("l5_boiler_route", "Housekeeping: the way through",
		"M.E.G. outpost \"Housekeeping\" - Boiler Room route.\n\nPipes leak Almond Water under pressure; the steam is hot but the floors stay dry. Keep to the lit aisles between the boilers and you will come out past the furnaces.\n\nWhispers near the furnaces are being looked into. Do not wait for them to make sense.\n\nPast the furnaces the passage runs down to Level 6. We do not advise it: the heat at the far end is extreme. If you go, go quickly and do not stop.")
	var n2 := Interactable.new()
	node.add_child(n2)
	n2.setup(board + Vector3(0.1, 0.0, 0.4), Vector3(0.2, 0.9, 0.6), "Read")
	n2.as_note("l5_l6_map", "A hand-drawn map (pinned)",
		"A pencil map of the dark level below, drawn from memory; whoever made it is not around to ask. Most of it is crossings-out.\n\nOne line is underlined twice: \"Nothing works down there. No light. Keep a hand on the wall.\"\n\nIn the margin someone has added: \"waves = stairs\".")


func _maintenance_lift() -> void:
	var x0 := 3.4
	var z0 := 9.8
	k.box_mm(Vector3(x0, -5.0, z0), Vector3(x0 + 2.6, -4.95, z0 + 2.6), "l5_boiler_iron", GeoKit.ALL, false)
	for side in [[Vector3(x0 + 1.3, -3.3, z0), Vector3(2.6, 3.4, 0.04)], [Vector3(x0, -3.3, z0 + 1.3), Vector3(0.04, 3.4, 2.6)], [Vector3(x0 + 2.6, -3.3, z0 + 1.3), Vector3(0.04, 3.4, 2.6)]]:
		k.box(side[0], side[1], "l5_lattice", GeoKit.ALL, true)
	var gate := MeshInstance3D.new()
	gate.mesh = P.gate_mesh()
	gate.position = Vector3(x0 + 0.5, -5.0, z0 + 2.62)
	node.add_child(gate)
	k.box(Vector3(x0 + 1.3, -5.0 + 0.1 + 1.2, z0 + 2.64), Vector3(2.6, 2.4, 0.03), "l5_shaft_dark", 0, true)
	for q in 9:
		var t := q / 8.0
		var p := Vector3(x0 + 0.6, -3.6, z0 + 2.68).lerp(Vector3(x0 + 2.0, -3.9, z0 + 2.68), t) + Vector3(0, -sin(t * PI) * 0.18, 0)
		k.box_xf(Transform3D(Basis(Vector3.BACK, q * 0.7), p), Vector3(0.09, 0.05, 0.02), "l5_rail", GeoKit.ALL, false)
	k.box(Vector3(x0 + 1.3, -2.55, z0 + 2.69), Vector3(0.9, 0.28, 0.01), "l5_notice", GeoKit.ALL, false)
	P.label(node, "MAINTENANCE - NOT ADVISED", Vector3(x0 + 1.3, -2.55, z0 + 2.7), Vector3(0, 0, 1), 0.0012, Color(0.5, 0.06, 0.04))
	var it := Interactable.new()
	node.add_child(it)
	it.setup(Vector3(x0 + 1.3, -3.8, z0 + 2.75), Vector3(2.4, 2.2, 0.2), "Try the maintenance elevator", Callable(L, "maintenance_lift"))


func _arcade(p: Vector3) -> void:
	var n := Vector3(-1, 0, 0)
	var b := Basis(Vector3.UP.cross(n), Vector3.UP, n)
	var c := p + n * 0.45
	k.box_xf(Transform3D(b, c + Vector3.UP * 0.9), Vector3(0.72, 1.8, 0.82), "l5_arcade_body", GeoKit.ALL, true)
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + b.x * sx * 0.365 + Vector3.UP * 0.95), Vector3(0.012, 1.7, 0.78), "l5_arcade_side", GeoKit.ALL, false)
	var screen := c + Vector3.UP * 1.36 + n * 0.3
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.22), screen), Vector3(0.56, 0.44, 0.02), "l5_arcade_screen", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + Vector3.UP * 1.86 + n * 0.37), Vector3(0.7, 0.16, 0.04), "l5_arcade_marquee", GeoKit.ALL, false)
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, 0.35), c + Vector3.UP * 0.98 + n * 0.5), Vector3(0.7, 0.04, 0.3), "l5_arcade_body", GeoKit.ALL, false)
	for q in 3:
		k.box_xf(Transform3D(b, c + Vector3.UP * 1.02 + n * 0.5 + b.x * (0.06 + q * 0.09)), Vector3(0.05, 0.03, 0.05), "l5_arcade_button", GeoKit.ALL, false)
	k.cylinder(c + Vector3.UP * 1.05 + n * 0.52 - b.x * 0.18, 0.012, 0.1, "l5_rail", 6, false)
	lights.add_anchor(screen + n * 0.5, Color(0.5, 0.75, 1.0), 0.6, 3.5, 0.15)
	_add_sound(screen, "chiptune", {"bpm": 112.0, "root": 196.0}, -21.0, 8.0)
	L.make_exit("L005>L040#8", "interact", c + n * 0.85 + Vector3.UP * 1.0, Vector3(1.3, 2.0, 1.3), "Play the arcade cabinet", node)
