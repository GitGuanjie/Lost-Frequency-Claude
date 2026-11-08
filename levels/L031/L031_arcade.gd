extends RefCounted
## Level 31 arcade (SOURCE: east of the rink; it loops back round to its north
## entrance; free with a green card from a metal dispenser at the entrance;
## Ski-Ball, big game wheels, air hockey, pinball and modern machines, a few
## 1980s box cabinets "few and far between"), and the back area of the arcade
## (diary, TESTIMONY: machines turned off or covered with cloth; the white door
## engraved 70). The loop is a solid island of machines you walk around.

const Rink := preload("res://levels/L031/L031_rink.gd")
const BACK_Y := -0.72

var L: LevelBase
var props: Node3D
var k: GeoKit
var playable: Array = []      # [{pos (interact centre), size, kind}]
var noclip_cabs: Array = []   # cabinet centres facing east into the west aisle
var wheel: Node3D
var dispenser := Vector3.ZERO
var white_door := Vector3(65.82, BACK_Y, -16.0)
var _gi := 0


func _init(level: LevelBase, props_root: Node3D) -> void:
	L = level
	props = props_root


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


func _bx(xf: Transform3D, c: Vector3, size: Vector3, mat: String, collide := false, rot := Basis()) -> void:
	k.box_xf(xf * Transform3D(rot, c), size, mat, GeoKit.ALL, collide)


func _screen(xf: Transform3D, c: Vector3, n: Vector3, hu: Vector3, hv: Vector3, mat: String) -> void:
	k.quad(xf * c, (xf.basis * n).normalized(), xf.basis * hu, xf.basis * hv, mat, Vector2.ZERO, true)


func _game() -> String:
	_gi += 1
	return "l31_game%d" % (_gi % 6)


func build() -> void:
	k = L.kit("Arcade")
	k.slab(28, -34, 54, 12, 0.0, 0.8, "l31_arcade_carpet")
	k.slab(27.85, -34.15, 54.15, 12.15, 4.1, 0.3, "l31_ceiling")
	k.wall(Vector3(28, 0, -34), Vector3(54, 0, -34), 3.8, Rink.T, "l31_wall")
	k.wall(Vector3(28, 0, 12), Vector3(54, 0, 12), 3.8, Rink.T, "l31_wall")
	k.wall(Vector3(54, 0, -34), Vector3(54, 0, 12), 3.8, Rink.T, "l31_wall", [{"at": 18.0, "w": 2.4, "h": 2.2}])
	k.box_mm(Vector3(36, 0, -26), Vector3(46, 3.8, 4), "l31_paint")
	for y in [2.55, 2.7]:
		k.box(Vector3(41, y, -26.02), Vector3(10.0, 0.04, 0.04), "l31_neon_cyan" if y < 2.6 else "l31_neon_pink", GeoKit.ALL, false)
		k.box(Vector3(41, y, 4.02), Vector3(10.0, 0.04, 0.04), "l31_neon_cyan" if y < 2.6 else "l31_neon_pink", GeoKit.ALL, false)
		k.box(Vector3(35.98, y, -11), Vector3(0.04, 0.04, 30.0), "l31_neon_cyan" if y < 2.6 else "l31_neon_pink", GeoKit.ALL, false)
		k.box(Vector3(46.02, y, -11), Vector3(0.04, 0.04, 30.0), "l31_neon_cyan" if y < 2.6 else "l31_neon_pink", GeoKit.ALL, false)
	# ceiling neon runs following the loop
	for z in [-30.0, 8.0]:
		Rink.new(L, props).neon_line(k, Vector3(30, 3.7, z), Vector3(52, 3.7, z), "l31_neon_violet", 0.05)
	for x in [32.0, 50.0]:
		Rink.new(L, props).neon_line(k, Vector3(x, 3.7, -30), Vector3(x, 3.7, 8), "l31_neon_blue", 0.05)
	Rink.label(L, "ARCADE", Vector3(27.8, 3.6, 0.0), -90.0, 110, Color(0.3, 1.0, 0.9), 8)
	Rink.label(L, "ARCADE", Vector3(28.2, 3.45, 0.0), 90.0, 80, Color(0.3, 1.0, 0.9), 6)
	_dispenser()
	# west aisle: video cabinets on the wall and on the island
	for z in [-24.4, -23.5, -22.6, -21.7, -15.0, -14.1, -13.2, -12.3, -7.0, -6.1, -5.2, 5.0, 5.9, 6.8, 7.7, 9.5, 10.4]:
		cabinet(Vector3(28.6, 0, z), -90.0, z == -5.2 or z == 5.0)
	for z in [-24.0, -23.1, -22.2, -18.0, -17.1, -16.2, -12.0, -11.1, -10.2, -5.0, -4.1, -3.2, 1.0, 1.9]:
		cabinet(Vector3(35.57, 0, z), 90.0, false)
	# north band: ski-ball lanes facing the island, the big wheel on the island
	for x in [37.4, 38.5, 39.6, 40.7, 42.6, 43.7, 44.8]:
		skiball(Vector3(x, 0, -33.85))
	wheel = big_wheel(Vector3(41.0, 2.4, -26.04))
	for x in [37.0, 37.9, 44.1, 45.0]:
		cabinet(Vector3(x, 0, -26.43), 0.0, false)
	# east aisle: pinball along the island, air hockey, more cabinets on the wall
	for z in [-23.0, -21.9, -20.8, -19.7, -12.0, -10.9, -9.8, -8.7, 0.5, 1.6]:
		pinball(Vector3(46.85, 0, z), -90.0)
	for z in [-22.5, -6.5]:
		air_hockey(Vector3(50.6, 0, z))
	for z in [-32.0, -31.1, -30.2, -29.3, -11.5, -10.6, -9.7, 6.0, 6.9, 7.8, 8.7]:
		cabinet(Vector3(53.42, 0, z), 90.0, false)
	# south band: three 1980s box cabinets far apart; big sit-down machines on the wall
	for x in [38.4, 41.2, 43.9]:
		old_cabinet(Vector3(x, 0, 4.42), 180.0)
	for x in [32.6, 34.2, 47.6, 49.2]:
		sitdown(Vector3(x, 0, 10.9), 0.0)
	_back_area()
	k.commit()
	p("ph/security_camera_01", Vector3(53.6, 3.3, -33.6), 135.0)
	p("ph/fire_alarm", Vector3(28.17, 1.5, -18.0), -90.0)
	p("kenney/furniture-kit/trashcan", Vector3(29.0, 0, -9.0), 0.0, 0.9, true)
	p("kenney/furniture-kit/trashcan", Vector3(52.8, 0, -1.0), 0.0, 0.9, true)
	p("kenney/food-kit/soda-can-crushed", Vector3(33.0, 0, -18.5), 30.0, 0.06)


func _dispenser() -> void:
	# SOURCE: a simple rectangular metal box with printed graphics, a large blue
	# button in the centre and a card catcher below.
	var c := Vector3(28.4, 0, -30.4)
	dispenser = c + Vector3(0.3, 1.25, 0)
	k.box(c + Vector3(0.12, 0.5, 0), Vector3(0.3, 1.0, 0.3), "l31_steel", GeoKit.ALL, true)
	k.box(c + Vector3(0.22, 1.3, 0), Vector3(0.36, 0.7, 0.55), "l31_steel", GeoKit.ALL, true)
	k.box(c + Vector3(0.405, 1.45, 0), Vector3(0.01, 0.32, 0.5), "l31_game4", GeoKit.ALL, false)
	k.cylinder(c + Vector3(0.42, 1.25, 0), 0.085, 0.04, "l31_neon_blue", 16, false)
	k.box(c + Vector3(0.43, 1.05, 0), Vector3(0.06, 0.1, 0.22), "l31_black", GeoKit.ALL, false)
	Rink.label(L, "Please press the button\nto get a card", c + Vector3(0.412, 1.58, 0), 90.0, 16, Color(1, 1, 1))


func cabinet(c: Vector3, yaw: float, working_exit: bool) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	var side: String = ["l31_black", "l31_paint", "l31_red", "l31_locker"][int(absf(c.x * 3.0 + c.z * 7.0)) % 4]
	_bx(xf, Vector3(0, 0.95, 0.04), Vector3(0.78, 1.9, 0.78), side, true)
	_bx(xf, Vector3(0, 0.55, -0.38), Vector3(0.7, 0.9, 0.06), "l31_black")
	_bx(xf, Vector3(0, 0.98, -0.5), Vector3(0.74, 0.1, 0.3), "l31_black", false, Basis(Vector3.RIGHT, deg_to_rad(-12.0)))
	_bx(xf, Vector3(-0.15, 1.05, -0.55), Vector3(0.05, 0.08, 0.05), "l31_neon_red")
	_bx(xf, Vector3(0.12, 1.05, -0.55), Vector3(0.06, 0.03, 0.06), "l31_neon_yellow")
	_bx(xf, Vector3(0, 1.88, -0.4), Vector3(0.78, 0.26, 0.1), ["l31_neon_pink", "l31_neon_cyan", "l31_neon_yellow", "l31_neon_violet"][int(absf(c.z * 5.0)) % 4])
	_bx(xf, Vector3(0, 1.4, -0.39), Vector3(0.7, 0.6, 0.06), "l31_black")
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(12.0))
	_screen(xf, Vector3(0, 1.42, -0.425), tilt * Vector3(0, 0, -1), Vector3(0.29, 0, 0), tilt * Vector3(0, 0.23, 0), _game())
	_bx(xf, Vector3(0, 0.45, -0.42), Vector3(0.18, 0.22, 0.02), "l31_neon_red")
	var front := xf * Vector3(0, 1.3, -0.55)
	playable.append({"pos": front, "size": Vector3(0.7, 0.8, 0.7), "kind": "video"})
	if working_exit:
		noclip_cabs.append({"pos": c + Vector3(0, 0.95, 0), "yaw": yaw})


func old_cabinet(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	_bx(xf, Vector3(0, 0.88, 0.04), Vector3(0.68, 1.76, 0.78), "l31_woodgrain", true)
	_bx(xf, Vector3(0, 1.72, -0.38), Vector3(0.66, 0.22, 0.06), "l31_neon_yellow")
	_bx(xf, Vector3(0, 0.95, -0.47), Vector3(0.66, 0.1, 0.24), "l31_black", false, Basis(Vector3.RIGHT, deg_to_rad(-10.0)))
	_bx(xf, Vector3(-0.12, 1.02, -0.5), Vector3(0.04, 0.08, 0.04), "l31_neon_red")
	_screen(xf, Vector3(0, 1.36, -0.39), Vector3(0, 0, -1), Vector3(0.22, 0, 0), Vector3(0, 0.18, 0), _game())
	playable.append({"pos": xf * Vector3(0, 1.25, -0.55), "size": Vector3(0.6, 0.8, 0.6), "kind": "old"})


func sitdown(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	_bx(xf, Vector3(0, 1.1, 0.25), Vector3(1.3, 2.2, 0.9), "l31_black", true)
	_bx(xf, Vector3(0, 2.1, -0.25), Vector3(1.3, 0.3, 0.2), "l31_neon_cyan" if c.x < 40.0 else "l31_neon_pink")
	_screen(xf, Vector3(0, 1.45, -0.21), Vector3(0, 0, -1), Vector3(0.5, 0, 0), Vector3(0, 0.36, 0), _game())
	_bx(xf, Vector3(0, 0.95, -0.4), Vector3(1.1, 0.2, 0.4), "l31_black")
	k.cylinder(xf * Vector3(0, 1.08, -0.45), 0.15, 0.04, "l31_steel", 14, false)
	_bx(xf, Vector3(0, 0.25, -1.15), Vector3(0.6, 0.5, 0.6), "l31_red")
	_bx(xf, Vector3(0, 0.75, -1.4), Vector3(0.6, 0.6, 0.1), "l31_red")
	playable.append({"pos": xf * Vector3(0, 1.0, -0.9), "size": Vector3(0.8, 1.0, 0.8), "kind": "drive"})


func pinball(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-6.0))
	_bx(xf, Vector3(0, 0.9, 0), Vector3(0.7, 0.3, 1.35), "l31_red" if int(c.z) % 2 == 0 else "l31_locker", true, tilt)
	for lx in [-0.3, 0.3]:
		for lz in [-0.6, 0.6]:
			_bx(xf, Vector3(lx, 0.38, lz), Vector3(0.05, 0.76, 0.05), "l31_steel")
	_screen(xf, Vector3(0, 1.06, 0.0), tilt * Vector3.UP, Vector3(0.32, 0, 0), tilt * Vector3(0, 0, 0.64), _game())
	_bx(xf, Vector3(0, 1.45, 0.66), Vector3(0.7, 0.8, 0.16), "l31_black")
	_screen(xf, Vector3(0, 1.5, 0.575), Vector3(0, 0, -1), Vector3(0.31, 0, 0), Vector3(0, 0.3, 0), _game())
	playable.append({"pos": xf * Vector3(0, 1.1, -0.9), "size": Vector3(0.8, 0.8, 0.6), "kind": "pinball"})


func skiball(c: Vector3) -> void:
	var xf := Transform3D(Basis(), c)
	_bx(xf, Vector3(0, 0.4, 2.0), Vector3(0.95, 0.8, 1.4), "l31_woodgrain", true)
	_bx(xf, Vector3(0, 0.82, 1.9), Vector3(0.75, 0.06, 1.4), "l31_rinkwood", false, Basis(Vector3.RIGHT, deg_to_rad(8.0)))
	_bx(xf, Vector3(0, 1.0, 0.6), Vector3(0.95, 2.0, 1.2), "l31_black", true)
	for i in 3:
		_bx(xf, Vector3(0, 1.45, 1.205 - i * 0.005), Vector3(0.6 - i * 0.18, 0.6 - i * 0.18, 0.01), ["l31_neon_yellow", "l31_neon_pink", "l31_neon_cyan"][i])
	for s in [-0.47, 0.47]:
		_bx(xf, Vector3(s, 1.7, 1.6), Vector3(0.02, 1.2, 2.0), "l31_glass")
	_bx(xf, Vector3(0, 2.15, 1.22), Vector3(0.8, 0.3, 0.04), "l31_game5")
	playable.append({"pos": xf * Vector3(0, 1.0, 3.0), "size": Vector3(0.9, 0.9, 0.7), "kind": "skiball"})


func air_hockey(c: Vector3) -> void:
	var xf := Transform3D(Basis(), c)
	_bx(xf, Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 2.2), "l31_black", true)
	_screen(xf, Vector3(0, 0.81, 0), Vector3.UP, Vector3(0.55, 0, 0), Vector3(0, 0, 1.05), "l31_neon_white")
	for s in [-0.6, 0.6]:
		_bx(xf, Vector3(s, 0.86, 0), Vector3(0.04, 0.1, 2.2), "l31_neon_blue")
	k.cylinder(xf * Vector3(0, 0.83, 0.3), 0.04, 0.01, "l31_red", 12, false)
	for z in [-0.8, 0.8]:
		k.cylinder(xf * Vector3(0.1, 0.86, z), 0.07, 0.08, "l31_red", 12, false)
	playable.append({"pos": xf * Vector3(0, 1.0, 1.4), "size": Vector3(1.0, 0.8, 0.5), "kind": "hockey"})


func big_wheel(c: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "GameWheel"
	root.position = c
	L.add_child(root)
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var wk := GeoKit.new(spin, "Wheel")
	var cols := ["l31_neon_red", "l31_neon_yellow", "l31_neon_blue", "l31_neon_green", "l31_neon_pink", "l31_neon_violet"]
	var n := 18
	for i in n:
		var a := TAU * float(i) / n
		var b := TAU * float(i + 1) / n
		wk._tri_fan(Vector3(0, 0, -0.03), Vector3(cos(a) * 1.25, sin(a) * 1.25, -0.03), Vector3(cos(b) * 1.25, sin(b) * 1.25, -0.03), Vector3(0, 0, -1), cols[i % cols.size()])
		wk.box_xf(Transform3D(Basis(Vector3(0, 0, 1), a), Vector3(cos(a) * 0.65, sin(a) * 0.65, -0.05)), Vector3(1.2, 0.02, 0.02), "l31_steel", GeoKit.ALL, false)
	wk.cylinder(Vector3(0, 0, -0.06), 0.12, 0.05, "l31_steel", 12, false)
	wk.commit()
	var fk := GeoKit.new(root, "WheelFrame")
	fk.box(Vector3(0, 1.38, -0.04), Vector3(0.12, 0.25, 0.06), "l31_neon_white", GeoKit.ALL, false)
	fk.commit()
	# the wheel spins about the axis pointing north; a counter below it
	k.box(c + Vector3(0, -1.85, -0.25), Vector3(2.4, 1.05, 0.5), "l31_red", GeoKit.ALL, true)
	playable.append({"pos": c + Vector3(0, -0.9, -0.7), "size": Vector3(1.6, 0.8, 0.6), "kind": "wheel"})
	return spin


func _back_area() -> void:
	var y := BACK_Y
	k.slab(54, -24, 66, -8, y, 0.3, "l31_carpet")
	k.box_mm(Vector3(54, y, -24), Vector3(54.15, 0.0, -8), "l31_wall")
	k.box_mm(Vector3(54, y, -17.2), Vector3(56, 0, -14.8), "l31_arcade_carpet")
	k.stairs(Vector3(57.36, y, -16.0), Vector3(-1, 0, 0), 2.4, -y, 4, "l31_arcade_carpet", 0.34)
	for z in [-17.2, -14.8]:
		k.wall(Vector3(54.15, 0, z), Vector3(56.0, 0, z), 0.95, 0.05, "l31_steel")
	k.slab(53.85, -24.15, 66.15, -7.85, 2.6, 0.3, "l31_ceiling")
	k.wall(Vector3(54, y, -24), Vector3(66, y, -24), 3.32, Rink.T, "l31_paint")
	k.wall(Vector3(54, y, -8), Vector3(66, y, -8), 3.32, Rink.T, "l31_paint")
	k.wall(Vector3(66, y, -24), Vector3(66, y, -8), 3.32, Rink.T, "l31_paint")
	# the white door engraved with 70
	k.box(Vector3(65.82, y + 1.06, -16.0), Vector3(0.06, 2.12, 0.96), "l31_white_door", GeoKit.ALL, false)
	for dz in [-0.53, 0.53]:
		k.box(Vector3(65.8, y + 1.1, -16.0 + dz), Vector3(0.08, 2.2, 0.09), "l31_white_door", GeoKit.ALL, false)
	k.box(Vector3(65.8, y + 2.22, -16.0), Vector3(0.08, 0.1, 1.15), "l31_white_door", GeoKit.ALL, false)
	k.box(Vector3(65.76, y + 1.0, -16.35), Vector3(0.06, 0.06, 0.14), "l31_steel", GeoKit.ALL, false)
	Rink.label(L, "70", Vector3(65.78, y + 1.6, -16.0), -90.0, 70, Color(0.42, 0.42, 0.42))
	# machines switched off or under cloth
	var spots := [[Vector3(56.5, y, -23.2), 0.0], [Vector3(57.5, y, -23.25), 0.0], [Vector3(59.5, y, -23.1), 4.0], [Vector3(62.8, y, -23.2), -3.0],
		[Vector3(64.0, y, -23.3), 0.0], [Vector3(57.0, y, -8.8), 180.0], [Vector3(59.2, y, -8.75), 176.0], [Vector3(61.0, y, -8.8), 180.0],
		[Vector3(64.2, y, -8.9), 183.0], [Vector3(60.5, y, -13.0), 25.0], [Vector3(62.4, y, -19.5), -15.0]]
	for i in spots.size():
		var c: Vector3 = spots[i][0]
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(float(spots[i][1]) + 180.0)), c)
		if i % 4 == 3:
			# switched off: dark glass, no cloth
			_bx(xf, Vector3(0, 0.95, 0), Vector3(0.78, 1.9, 0.8), "l31_black", true)
			_bx(xf, Vector3(0, 1.4, -0.41), Vector3(0.6, 0.45, 0.02), "l31_glass")
		else:
			# a cabinet under a dust sheet: the marquee juts forward, the sheet flares at the floor
			_bx(xf, Vector3(0, 0.9, 0.04), Vector3(0.8, 1.8, 0.8), "l31_cloth", true)
			_bx(xf, Vector3(0, 1.82, -0.12), Vector3(0.86, 0.32, 0.62), "l31_cloth", false, Basis(Vector3.RIGHT, -0.08))
			_bx(xf, Vector3(0, 1.05, -0.43), Vector3(0.84, 0.5, 0.2), "l31_cloth", false, Basis(Vector3.RIGHT, 0.35))
			for sx in [-1.0, 1.0]:
				_bx(xf, Vector3(sx * 0.42, 0.45, 0.0), Vector3(0.06, 0.9, 0.86), "l31_cloth", false, Basis(Vector3.FORWARD, sx * 0.1))
			_bx(xf, Vector3(0, 0.3, -0.45), Vector3(0.84, 0.6, 0.06), "l31_cloth", false, Basis(Vector3.RIGHT, -0.18))
			_bx(xf, Vector3(0.1, 0.02, -0.62), Vector3(0.5, 0.04, 0.2), "l31_cloth", false, Basis(Vector3.UP, 0.4))
	p("ph/hand_truck", Vector3(64.6, y, -12.0), -70.0)
	p("ph/cardboard_box_01", Vector3(55.4, y, -10.2), 15.0, 0.0, true)
	p("ph/cardboard_box_01", Vector3(55.5, y + 0.34, -10.3), 50.0)
	p("ph/cardboard_box_01", Vector3(56.1, y, -9.4), -20.0, 0.0, true)
	p("ph/plastic_crate_01", Vector3(63.5, y, -14.0), 30.0)
	p("ph/caged_hanging_light", Vector3(60.0, 1.55, -16.0), 0.0)
