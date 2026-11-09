extends RefCounted
## Level 201: the Neon City (south, +Z, always night). An avenue and a cross street between
## untouched towers covered in neon; a two-storey mall (marble tiles, glass roof, neon rings round
## the columns, closed shops, an open arcade on free play with a ball pit, vending machines, a
## snack bar, televisions); a temple-styled hotel front; traffic lights holding back the Light
## Traffic; Static Ghosts on every sidewalk.

const Land := preload("res://levels/L201/L201_land.gd")
const FX := preload("res://levels/L201/L201_fx.gd")
const G := 0.55
const WALK := 0.7
const AVE := Rect2(-7.0, 98.0, 14.0, 152.0)
const CROSS_Z0 := 150.0
const CROSS_Z1 := 162.0
const MALL := Rect2(11.0, 100.0, 35.0, 46.0)
const UP2 := 5.7
const SIGNS := ["ARCADE", "KARAOKE", "SAKURA", "RAMEN 24H", "CYBER CAFE", "MANGA", "ANIME CLUB", "NEO PLAZA", "SYNTH FM", "DREAM TV"]

var L: LevelBase
var k: GeoKit
var d: GeoKit
var root: Node3D
var rng: RandomNumberGenerator
var lamp_pts: Array = []
var ghosts: Array = []
var streaks: Array = []        # {node, axis(0=x,1=z), dir, lane(float), t(pos along), stop}
var lights_red: Array = []     # [MeshInstance3D red, MeshInstance3D green, group]
var tv_pos := Vector3.ZERO
var cabinet_pos := Vector3.ZERO
var arcade_pos := Vector3.ZERO
var ball_pit := Rect2()
var signal_t := 0.0
var towers := 0


func _init(level: LevelBase, r: RandomNumberGenerator) -> void:
	L = level
	rng = r
	k = GeoKit.new(level, "City")
	d = GeoKit.new(level, "CityDress")
	root = Node3D.new()
	root.name = "CityProps"
	level.add_child(root)
	for i in 3:
		var m := FX.mat(FX.FACADE)
		m.set_shader_parameter("seed", float(i) * 13.7)
		if i == 1:
			m.set_shader_parameter("lit_a", Vector3(1.0, 0.35, 0.7))
		if i == 2:
			m.set_shader_parameter("wall", Vector3(0.1, 0.06, 0.14))
		MatLib.register("l201_facade_%d" % i, m)


func build() -> void:
	_streets()
	_blocks()
	_mall()
	_hotel()
	_traffic()
	_people()
	k.commit()
	d.commit()


func _streets() -> void:
	k.box(Vector3(0, G + 0.02, (AVE.position.y + AVE.end.y) * 0.5), Vector3(AVE.size.x, 0.04, AVE.size.y), "l201_asphalt")
	k.box(Vector3(0, G + 0.02, (CROSS_Z0 + CROSS_Z1) * 0.5), Vector3(150.0, 0.04, CROSS_Z1 - CROSS_Z0), "l201_asphalt")
	for sx: float in [-1.0, 1.0]:
		for zr in [[98.0, CROSS_Z0], [CROSS_Z1, 250.0]]:
			var z0: float = zr[0]
			var z1: float = zr[1]
			k.box(Vector3(sx * 9.0, (G + WALK) * 0.5, (z0 + z1) * 0.5), Vector3(4.0, WALK - G + 0.1, z1 - z0), "l201_curb")
		for xr in [[9.0, 76.0]]:
			for zz: float in [CROSS_Z0 - 2.0, CROSS_Z1 + 2.0]:
				k.box(Vector3(sx * (xr[0] + xr[1]) * 0.5 + sx * 2.0, (G + WALK) * 0.5, zz), Vector3(xr[1] - xr[0], WALK - G + 0.1, 4.0), "l201_curb")
	# lane markings and crosswalks
	var z := 100.0
	while z < 248.0:
		if z < CROSS_Z0 - 4.0 or z > CROSS_Z1 + 4.0:
			d.box(Vector3(0, G + 0.045, z), Vector3(0.15, 0.01, 2.2), "l201_yellow", GeoKit.PY, false)
		z += 5.0
	for zc: float in [CROSS_Z0 - 2.5, CROSS_Z1 + 2.5]:
		for i in 9:
			d.box(Vector3(-6.0 + i * 1.5, G + 0.045, zc), Vector3(0.7, 0.01, 3.0), "l201_marble_tile", GeoKit.PY, false)
	# street lamps along the avenue, pink pools of light
	z = 104.0
	while z < 248.0:
		for sx: float in [-1.0, 1.0]:
			if z > CROSS_Z0 - 6.0 and z < CROSS_Z1 + 6.0:
				continue
			Props.place(L, root, "ph/street_lamp_01", Vector3(sx * 7.6, WALK, z), 90.0 if sx < 0 else 270.0, 5.2)
			lamp_pts.append([Vector3(sx * 6.4, 5.0, z), Color(1.0, 0.5, 0.85), 1.2, 9.0])
		z += 18.0


func _tower(x0: float, z0: float, x1: float, z1: float, h: float, face_x: float) -> void:
	var m := "l201_facade_%d" % (towers % 3)
	towers += 1
	k.box(Vector3((x0 + x1) * 0.5, G + h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0), m)
	# glowing roof edge and a ground-floor shop band
	var col := "l201_pink" if towers % 2 == 0 else "l201_cyan"
	d.box(Vector3((x0 + x1) * 0.5, G + h + 0.1, z0), Vector3(x1 - x0, 0.2, 0.2), col, GeoKit.ALL, false)
	d.box(Vector3((x0 + x1) * 0.5, G + h + 0.1, z1), Vector3(x1 - x0, 0.2, 0.2), col, GeoKit.ALL, false)
	if face_x != 0.0:
		var fx := x0 if face_x > 0.0 else x1
		var n := Vector3(-face_x, 0, 0)
		d.box(Vector3(fx - n.x * -0.05, G + 3.4, (z0 + z1) * 0.5), Vector3(0.1, 0.25, z1 - z0 - 2.0), col, GeoKit.ALL, false)
		# vertical neon sign
		var sign_t: String = SIGNS[towers % SIGNS.size()]
		var sz := z0 + rng.randf_range(3.0, z1 - z0 - 3.0)
		var sp := Vector3(fx + n.x * 0.8, G + 9.0 + rng.randf_range(0.0, 8.0), sz)
		d.box(sp, Vector3(1.2, 1.2 * sign_t.length() * 0.75 + 0.6, 0.5), "l201_cabinet", GeoKit.ALL, false)
		var vert := ""
		for ch in sign_t:
			vert += ch + "\n"
		var c: Color = [Color(1.0, 0.3, 0.7), Color(0.3, 0.95, 1.0), Color(1.0, 0.85, 0.3)][towers % 3]
		var l1 := FX.neon_text(root, vert.strip_edges(), sp + Vector3(n.x * 0.62, 0, 0), n, 0.85, c)
		l1.line_spacing = -18.0
		var l2 := FX.neon_text(root, vert.strip_edges(), sp + Vector3(0, 0, 0.27), Vector3(0, 0, 1), 0.85, c)
		l2.line_spacing = -18.0
		lamp_pts.append([sp + Vector3(n.x * 2.0, -3.0, 0), c, 1.0, 10.0])


func _blocks() -> void:
	var zb := [[100.0, 146.0], [166.0, 206.0], [210.0, 250.0]]
	for sx: float in [-1.0, 1.0]:
		for bi in zb.size():
			var z0: float = zb[bi][0]
			var z1: float = zb[bi][1]
			if bi == 0 and sx < 0.0:
				_tower(-44.0, z0, -28.0, z1, rng.randf_range(40.0, 70.0), 0.0)
			elif bi > 0:
				var mid := (z0 + z1) * 0.5 + rng.randf_range(-4.0, 4.0)
				for zr in [[z0, mid - 1.5], [mid + 1.5, z1]]:
					_tower(minf(sx * 11.0, sx * 40.0), zr[0], maxf(sx * 11.0, sx * 40.0), zr[1], rng.randf_range(28.0, 110.0), sx)
			_tower(minf(sx * 46.0, sx * 74.0), z0, maxf(sx * 46.0, sx * 74.0), z1, rng.randf_range(40.0, 140.0), 0.0)
	# the avenue ends in a great tower with a billboard screen
	_tower(-40.0, 254.0, 40.0, 284.0, 150.0, 0.0)
	var bb := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(36, 20)
	bb.mesh = qm
	var m := FX.mat(FX.SHAPE)
	m.set_shader_parameter("a", Vector3(1.0, 0.3, 0.6))
	m.set_shader_parameter("b", Vector3(0.3, 0.6, 1.0))
	bb.material_override = m
	bb.position = Vector3(0, 40.0, 253.9)
	bb.rotation.y = PI
	root.add_child(bb)
	FX.neon_text(root, "DREAMS 2001", Vector3(0, 54.0, 253.8), Vector3(0, 0, -1), 6.0, Color(0.4, 0.95, 1.0))


# ------------------------------------------------------------------ the mall

func _slab_holes(x0: float, z0: float, x1: float, z1: float, y: float, mat: String, hole: Rect2) -> void:
	k.slab(x0, z0, hole.position.x, z1, y, 0.3, mat)
	k.slab(hole.end.x, z0, x1, z1, y, 0.3, mat)
	k.slab(hole.position.x, z0, hole.end.x, hole.position.y, y, 0.3, mat)
	k.slab(hole.position.x, hole.end.y, hole.end.x, z1, y, 0.3, mat)


func _mall() -> void:
	var r := MALL
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	var atr := Rect2(20.5, 110.0, 16.0, 26.0)
	var hole2 := Rect2(17.4, 112.0, 2.2, 8.0)
	k.slab(x0, z0, x1, z1, WALK + 0.05, 0.4, "l201_marble_tile")
	# second floor around the atrium, minus the stair well
	k.slab(x0, z0, atr.position.x, hole2.position.y, UP2, 0.3, "l201_marble_tile")
	k.slab(x0, hole2.end.y, atr.position.x, z1, UP2, 0.3, "l201_marble_tile")
	k.slab(x0, hole2.position.y, hole2.position.x, hole2.end.y, UP2, 0.3, "l201_marble_tile")
	k.slab(atr.end.x, z0, x1, z1, UP2, 0.3, "l201_marble_tile")
	k.slab(atr.position.x, z0, atr.end.x, atr.position.y, UP2, 0.3, "l201_marble_tile")
	k.slab(atr.position.x, atr.end.y, atr.end.x, z1, UP2, 0.3, "l201_marble_tile")
	# roof with a glass atrium skylight
	var roof := 11.2
	_slab_holes(x0, z0, x1, z1, roof, "l201_curb", atr)
	k.box(Vector3(atr.get_center().x, roof - 0.1, atr.get_center().y), Vector3(atr.size.x, 0.05, atr.size.y), "l201_glass", GeoKit.PY | GeoKit.NY, false)
	var gz := atr.position.y
	while gz <= atr.end.y:
		d.box(Vector3(atr.get_center().x, roof - 0.1, gz), Vector3(atr.size.x, 0.12, 0.12), "l201_metal", GeoKit.ALL, false)
		gz += 2.6
	# walls: glass storefront on the avenue side with the entrance, solid elsewhere
	var front_ops := [{"at": 23.0, "w": 4.0, "h": 3.4}]
	k.wall(Vector3(x0, WALK, z0), Vector3(x0, WALK, z1), UP2 - WALK, 0.15, "l201_glass", front_ops)
	k.wall(Vector3(x0, UP2, z0), Vector3(x0, UP2, z1), roof - UP2, 0.15, "l201_glass")
	for zz: float in [z0 + 3.0, z0 + 11.0, z0 + 17.5, z0 + 28.5, z0 + 35.0, z0 + 43.0]:
		d.box(Vector3(x0, (WALK + roof) * 0.5, zz), Vector3(0.3, roof - WALK, 0.3), "l201_metal", GeoKit.ALL, false)
	k.wall(Vector3(x0, WALK, z0), Vector3(x1, WALK, z0), roof - WALK, 0.4, "l201_facade_2")
	k.wall(Vector3(x0, WALK, z1), Vector3(x1, WALK, z1), roof - WALK, 0.4, "l201_facade_2")
	k.wall(Vector3(x1, WALK, z0), Vector3(x1, WALK, z1), roof - WALK, 0.4, "l201_facade_2")
	FX.neon_text(root, "PLAZA 2001", Vector3(x0 - 0.2, 8.4, 123.0), Vector3(-1, 0, 0), 2.2, Color(1.0, 0.35, 0.75))
	# atrium columns with neon rings (borrowed from the temples), glass balustrade
	for cx: float in [atr.position.x, atr.end.x]:
		var cz := atr.position.y
		while cz <= atr.end.y + 0.01:
			k.cylinder(Vector3(cx, (WALK + roof) * 0.5, cz), 0.4, roof - WALK, "l201_marble", 14)
			if int(cz) % 2 == 0:
				FX.neon_ring(root, Vector3(cx, 3.2, cz), 0.75, "l201_cyan" if cx < 30.0 else "l201_pink")
			cz += 6.5
	for e in [[Vector3(atr.position.x, UP2, atr.position.y), Vector3(atr.position.x, UP2, atr.end.y)], [Vector3(atr.end.x, UP2, atr.position.y), Vector3(atr.end.x, UP2, atr.end.y)],
			[Vector3(atr.position.x, UP2, atr.position.y), Vector3(atr.end.x, UP2, atr.position.y)], [Vector3(atr.position.x, UP2, atr.end.y), Vector3(atr.end.x, UP2, atr.end.y)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		k.box((a + b) * 0.5 + Vector3(0, 0.55, 0), (b - a).abs() + Vector3(0.06, 1.1, 0.06), "l201_glass", GeoKit.ALL, true)
		d.box((a + b) * 0.5 + Vector3(0, 1.12, 0), (b - a).abs() + Vector3(0.1, 0.06, 0.1), "l201_metal", GeoKit.ALL, false)
	# stairs to the gallery (west side of the atrium), rising toward +z
	k.stairs(Vector3(18.5, WALK + 0.05, 112.0), Vector3(0, 0, 1), 2.0, UP2 - WALK - 0.05, 25, "l201_marble", 0.3, false)
	k.box(Vector3(19.55, UP2 + 0.55, 116.0), Vector3(0.06, 1.1, 8.0), "l201_glass")
	# closed shops: rolled-down shutters along the north and east walls, on both floors
	for fl: float in [WALK + 0.05, UP2]:
		var sx := x0 + 4.0
		while sx < x1 - 3.0:
			Props.place(L, root, "ph/rollershutter_door", Vector3(sx, fl, z0 + 0.3), 0.0, 2.6)
			FX.neon_text(root, SIGNS[int(sx) % SIGNS.size()], Vector3(sx, fl + 3.3, z0 + 0.25), Vector3(0, 0, 1), 0.45, [Color(1, 0.4, 0.8), Color(0.4, 0.9, 1)][int(sx) % 2])
			sx += 5.5
		var szz := z0 + 8.0
		while szz < z1 - 12.0:
			Props.place(L, root, "ph/rollershutter_door", Vector3(x1 - 0.3, fl, szz), 90.0, 2.6)
			szz += 6.0
	# snack bar (open) in the north-west corner
	k.box(Vector3(14.0, WALK + 0.55, 106.0), Vector3(4.0, 1.1, 0.7), "l201_marble")
	Props.place(L, root, "kenney/food-kit/cup", Vector3(13.2, WALK + 1.12, 106.0), 0.0, 0.12)
	Props.place(L, root, "kenney/food-kit/fries-empty", Vector3(14.6, WALK + 1.12, 106.1), 0.0, 0.14)
	FX.neon_text(root, "SNACKS", Vector3(14.0, WALK + 3.2, 101.0), Vector3(0, 0, 1), 0.6, Color(1.0, 0.85, 0.3))
	# vending machines
	for vp: Vector3 in [Vector3(12.0, WALK, 138.0), Vector3(12.0, WALK, 139.2), Vector3(12.0, UP2, 104.0)]:
		k.box(vp + Vector3(0.45, 0.95, 0), Vector3(0.9, 1.9, 1.0), "l201_cabinet")
		d.quad(vp + Vector3(0.91, 1.15, 0), Vector3(1, 0, 0), Vector3(0, 0, 0.38), Vector3(0, 0.6, 0), "l201_cyan", Vector2.ZERO, true)
	# the arcade: open, everything on free play; a ball pit at its back
	arcade_pos = Vector3(37.0, WALK + 0.05, 132.0)
	for row in 3:
		for i in 5:
			var cp := Vector3(31.0 + i * 2.6, WALK + 0.05, 127.0 + row * 4.0)
			_cabinet(cp, row * 5 + i)
	cabinet_pos = Vector3(31.0, WALK + 1.0, 127.0)
	for i in 2:
		var pp := Vector3(30.0 + i * 3.0, WALK + 0.05, 143.0)
		k.box(pp + Vector3(0, 0.5, 0), Vector3(0.8, 1.0, 1.6), "l201_cabinet")
		d.quad(pp + Vector3(0, 1.01, 0), Vector3.UP, Vector3(0.36, 0, 0), Vector3(0, 0, 0.75), "l201_screen", Vector2.ZERO, true)
	ball_pit = Rect2(39.5, 139.0, 5.0, 5.0)
	for e in [[0.0, 0.0, 5.0, 0.2], [0.0, 4.8, 5.0, 0.2], [0.0, 0.0, 0.2, 5.0], [4.8, 0.0, 0.2, 5.0]]:
		k.box(Vector3(ball_pit.position.x + e[0] + e[2] * 0.5, WALK + 0.35, ball_pit.position.y + e[1] + e[3] * 0.5), Vector3(e[2], 0.6, e[3]), "l201_pink")
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	sm.radial_segments = 6
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = 900
	for i in 900:
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(ball_pit.position.x + 0.3 + rng.randf() * 4.4, WALK + 0.15 + rng.randf() * 0.45, ball_pit.position.y + 0.3 + rng.randf() * 4.4)))
		mm.set_instance_color(i, [Color(1, 0.2, 0.3), Color(0.2, 0.5, 1), Color(1, 0.9, 0.2), Color(0.3, 1, 0.4)][i % 4])
	var bmi := MultiMeshInstance3D.new()
	bmi.multimesh = mm
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.roughness = 0.3
	bmi.material_override = bm
	root.add_child(bmi)
	FX.neon_text(root, "FREE PLAY", Vector3(37.0, WALK + 3.6, 145.7), Vector3(0, 0, -1), 1.0, Color(0.3, 1.0, 0.5))
	# televisions: a wall of them in an electronics window on the gallery, others on columns
	tv_pos = Vector3(30.0, UP2 + 1.3, z1 - 0.6)
	for i in 6:
		var tp := Vector3(26.0 + (i % 3) * 3.0, UP2 + 0.9 + (i / 3) * 1.0, z1 - 0.5)
		Props.place(L, root, "ph/Television_01", tp - Vector3(0, 0.23, 0), 180.0, 0.55)
		d.quad(tp + Vector3(0, 0.05, -0.27), Vector3(0, 0, -1), Vector3(0.22, 0, 0), Vector3(0, 0.16, 0), "l201_screen", Vector2(float(i), 0.3), true)
	k.box(Vector3(30.0, UP2 + 0.35, z1 - 0.5), Vector3(9.0, 0.7, 0.8), "l201_cabinet")
	# ceiling light panels and anchors
	for lx: float in [15.0, 41.0]:
		var lz := z0 + 5.0
		while lz < z1:
			d.panel(Vector3(lx, UP2 - 0.32, lz), 1.2, 2.4, "l201_yellow")
			d.panel(Vector3(lx, roof - 0.22, lz), 1.2, 2.4, "l201_yellow")
			lz += 9.0
	for lp in [Vector3(15.0, 4.6, 112.0), Vector3(15.0, 4.6, 132.0), Vector3(38.0, 4.6, 130.0), Vector3(40.0, 4.6, 106.0), Vector3(28.0, 9.5, 123.0), Vector3(15.0, 10.0, 120.0), Vector3(40.0, 10.0, 140.0)]:
		lamp_pts.append([lp, Color(1.0, 0.75, 0.9), 1.2, 11.0])


func _cabinet(p: Vector3, i: int) -> void:
	k.box(p + Vector3(0, 0.9, 0), Vector3(0.8, 1.8, 0.8), "l201_cabinet")
	d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), -0.3), p + Vector3(0, 1.35, -0.41)), Vector3(0.62, 0.5, 0.05), "l201_cabinet", GeoKit.ALL, false)
	d.quad(p + Vector3(0, 1.36, -0.445), Vector3(0, 0.29, -0.96).normalized(), Vector3(0.27, 0, 0), Vector3(0, 0.21, 0.07), ["l201_screen", "l201_cyan", "l201_pink", "l201_green"][i % 4], Vector2(float(i), 0.2), true)
	d.box(p + Vector3(0, 0.95, -0.5), Vector3(0.7, 0.06, 0.25), "l201_metal", GeoKit.ALL, false)
	d.box(p + Vector3(0, 1.88, -0.38), Vector3(0.78, 0.18, 0.06), ["l201_pink", "l201_cyan", "l201_yellow"][i % 3], GeoKit.ALL, false)


func _hotel() -> void:
	# a hotel front in the temples' style: marble colonnade, potted palms in the lobby
	var x0 := -26.0
	var x1 := -11.0
	k.box(Vector3((x0 + x1) * 0.5, G + 30.0, 123.0), Vector3(x1 - x0, 60.0, 44.0), "l201_marble")
	for zz: float in [106.0, 112.0, 118.0, 128.0, 134.0, 140.0]:
		k.cylinder(Vector3(x1 + 0.9, WALK + 3.5, zz), 0.45, 7.0, "l201_marble", 14)
		FX.neon_ring(root, Vector3(x1 + 0.9, WALK + 4.5, zz), 0.8, "l201_cyan")
	d.box(Vector3(x1 + 0.9, WALK + 7.2, 123.0), Vector3(1.6, 0.5, 38.0), "l201_marble", GeoKit.ALL, false)
	FX.neon_text(root, "HOTEL VAPOR", Vector3(x1 + 0.05, 12.0, 123.0), Vector3(1, 0, 0), 2.0, Color(0.4, 0.95, 1.0))
	d.box(Vector3(x1 + 0.02, WALK + 1.6, 123.0), Vector3(0.05, 3.0, 6.0), "l201_yellow", GeoKit.PX, false)
	for zz: float in [118.5, 127.5]:
		Props.place(L, root, "kenney/furniture-kit/pottedplant", Vector3(x1 + 1.8, WALK, zz), 0.0, 1.6)


# ------------------------------------------------------------------ Light Traffic and people

func _traffic() -> void:
	# traffic light heads on the four corners of the crossing
	for c in [[-9.0, CROSS_Z0 - 2.0, 0], [9.0, CROSS_Z1 + 2.0, 0], [9.0, CROSS_Z0 - 2.0, 1], [-9.0, CROSS_Z1 + 2.0, 1]]:
		var base := Vector3(c[0], WALK, c[1])
		k.box(base + Vector3(0, 2.6, 0), Vector3(0.18, 5.2, 0.18), "l201_metal")
		var head := base + Vector3(0, 5.0, 0)
		d.box(head, Vector3(0.45, 1.2, 0.45), "l201_cabinet", GeoKit.ALL, false)
		var red := _lamp_mesh(head + Vector3(0, 0.3, 0), "l201_red")
		var green := _lamp_mesh(head + Vector3(0, -0.3, 0), "l201_green")
		lights_red.append([red, green, int(c[2])])
	var lanes := [[0, 1.0, 153.0], [0, -1.0, 159.0], [1, 1.0, -3.5], [1, -1.0, 3.5]]
	for ln in lanes:
		for i in 6:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.35, 0.25, 5.0) if ln[0] == 1 else Vector3(5.0, 0.25, 0.35)
			mi.mesh = bm
			mi.material_override = MatLib.get_mat("l201_red")
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
			var span := 150.0
			streaks.append({"node": mi, "axis": ln[0], "dir": ln[1], "lane": ln[2], "t": float(i) * span / 6.0 + rng.randf() * 8.0})


func _lamp_mesh(p: Vector3, m: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	mi.mesh = sm
	mi.material_override = MatLib.get_mat(m)
	mi.position = p
	root.add_child(mi)
	return mi


## Green for the avenue (group 1) or for the cross street (group 0).
func green_group() -> int:
	var t := fmod(signal_t, 20.0)
	if t < 9.0:
		return 1
	if t >= 10.0 and t < 19.0:
		return 0
	return -1


func update_traffic(delta: float) -> void:
	signal_t += delta
	var g := green_group()
	for lr in lights_red:
		var go: bool = lr[2] == g
		(lr[0] as MeshInstance3D).visible = not go
		(lr[1] as MeshInstance3D).visible = go
	for s in streaks:
		var axis: int = s["axis"]
		var dirv: float = s["dir"]
		var t: float = s["t"]
		var span := 150.0 if axis == 0 else 150.0
		var start := -75.0 if axis == 0 else 100.0
		var pos_along := start + t if dirv > 0.0 else start + span - t
		var green: bool = (g == 0 and axis == 0) or (g == 1 and axis == 1)
		var stop_line := (-10.0 if dirv > 0.0 else 10.0) if axis == 0 else (CROSS_Z0 - 3.0 if dirv > 0.0 else CROSS_Z1 + 3.0)
		var before_stop := (pos_along < stop_line - 1.0) if dirv > 0.0 else (pos_along > stop_line + 1.0)
		var near_stop := absf(pos_along - stop_line) < 3.0
		if green or not (before_stop and near_stop):
			t += delta * 28.0
		if t > span:
			t -= span
		s["t"] = t
		var node: MeshInstance3D = s["node"]
		node.position = Vector3(pos_along, G + 0.5, s["lane"]) if axis == 0 else Vector3(s["lane"], G + 0.5, pos_along)


## True when a streak of Light Traffic overlaps p (feet).
func traffic_hits(p: Vector3) -> bool:
	if p.y > G + 2.0:
		return false
	for s in streaks:
		var n: Node3D = s["node"]
		var dd: Vector3 = (n.position - p).abs()
		if s["axis"] == 0 and dd.x < 2.7 and dd.z < 0.8:
			return true
		if s["axis"] == 1 and dd.z < 2.7 and dd.x < 0.8:
			return true
	return false


func _people() -> void:
	for i in 16:
		var sx := -1.0 if i % 2 == 0 else 1.0
		var z := rng.randf_range(100.0, 246.0)
		if z > CROSS_Z0 - 4.0 and z < CROSS_Z1 + 4.0:
			z += 20.0
		var pose := "wave" if i % 5 == 0 else "stand"
		ghosts.append(FX.ghost(root, Vector3(sx * rng.randf_range(8.0, 10.5), WALK, z), rng.randf() * TAU, pose, 70.0 + i))
	ghosts.append(FX.ghost(root, Vector3(24.0, WALK + 0.05, 118.0), 1.2, "stand", 99.0))
	ghosts.append(FX.ghost(root, Vector3(33.0, WALK + 0.05, 135.5), 0.0, "stand", 98.0))
