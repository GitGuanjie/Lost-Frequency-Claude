extends RefCounted
## Level 83: compartment dressing (berthing, crew's mess, galley, control room, radio, sonar,
## auxiliary machinery, torpedo room, reactor tunnel, engine room). Geometry comes from
## L083_hull.gd (H). Everything here sits inside the hull's deck bands.

const Hull := preload("res://levels/L083/L083_hull.gd")
const POSTIT := [Color(1.0, 0.85, 0.1), Color(1.0, 0.35, 0.6), Color(0.35, 0.9, 0.45), Color(0.3, 0.7, 1.0), Color(1.0, 0.55, 0.15)]

var H
var L: LevelBase
var k: GeoKit
var d: GeoKit
var rng: RandomNumberGenerator
var fridges: Array = []      # {kit_root: Node3D, pos: Vector3, full: bool, t: float}
var postit_pts: Array = []   # [pos, normal, color]
var drawing_pts: Array = []  # [pos, normal]
var notes: Array = []        # [id, title, text, pos]
var bunks: Array = []        # bed positions (spawn / arrival candidates)
var helm_pos := Vector3.ZERO
var scope_pos := Vector3.ZERO


func _init(hull, level: LevelBase, r: RandomNumberGenerator) -> void:
	H = hull
	L = level
	k = hull.k
	d = hull.d
	rng = r


static func materials() -> void:
	for i in POSTIT.size():
		MatLib.register("l83_postit_%d" % i, MatLib.standard(POSTIT[i], 0.85))
	MatLib.register("l83_paper", MatLib.standard(Color(0.86, 0.84, 0.78), 0.9))
	MatLib.register("l83_cork", MatLib.standard(Color(0.42, 0.29, 0.16), 0.95))
	MatLib.register("l83_bottle", MatLib.standard(Color(0.55, 0.7, 0.85), 0.15))
	MatLib.register("l83_food", MatLib.standard(Color(0.75, 0.55, 0.32), 0.8))
	MatLib.register("l83_food_g", MatLib.standard(Color(0.25, 0.5, 0.18), 0.7))
	MatLib.register("l83_food_r", MatLib.standard(Color(0.62, 0.1, 0.08), 0.6))
	MatLib.register("l83_fridge_in", MatLib.panel(Color(0.9, 0.95, 1.0), 0.9))


func build() -> void:
	_vestibule()
	_berth()
	_mess()
	_galley()
	_ladder_room()
	_upper_aft()
	_control_room()
	_radio_and_stateroom()
	_sonar()
	_aux_machinery()
	_torpedo_room()
	_tunnel_dress()
	_engine_dress()
	_overheads()
	_frames()
	_walls()


# ------------------------------------------------------------------ small helpers

func label(text: String, pos: Vector3, normal: Vector3, px: float = 0.004, col := Color(0.08, 0.08, 0.08), size := 48) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.position = pos + normal * 0.012
	H.labels.add_child(l)
	if absf(normal.y) > 0.9:
		l.rotation = Vector3(-PI * 0.5 * signf(normal.y), 0, 0)
	else:
		l.look_at(l.global_position - normal, Vector3.UP)
	return l


## A plate sign (backing + text) on a wall with outward normal n.
func plate(text: String, pos: Vector3, n: Vector3, w: float, h: float, mat := "l83_paper", col := Color(0.08, 0.08, 0.08), px := 0.0035) -> void:
	if absf(n.y) > 0.9:
		d.quad(pos + n * 0.006, n, Vector3(w * 0.5, 0, 0), Vector3(0, 0, h * 0.5), mat, Vector2.ZERO, true)
	else:
		var side := Vector3.UP.cross(n).normalized()
		d.quad(pos + n * 0.006, n, side * (w * 0.5), Vector3.UP * (h * 0.5), mat, Vector2.ZERO, true)
	label(text, pos + n * 0.004, n, px, col)


func postits(pos: Vector3, n: Vector3, count: int, spread := 0.35) -> void:
	var side := Vector3.UP.cross(n).normalized() if absf(n.y) < 0.9 else Vector3.RIGHT
	var up := n.cross(side).normalized() * -1.0 if absf(n.y) < 0.9 else Vector3.FORWARD
	for i in count:
		var p := pos + side * rng.randf_range(-spread, spread) + up * rng.randf_range(-spread * 0.4, spread * 0.4)
		postit_pts.append([p, n, i % POSTIT.size()])


func drawing(pos: Vector3, n: Vector3) -> void:
	drawing_pts.append([pos, n])


## Instrument console: angled face with dead screens, dials and indicator LEDs.
func console(c: Vector3, yaw: float, w: float = 1.4, h: float = 1.5, lit := 0.3) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var fwd := b * Vector3(0, 0, 1)
	var side := b * Vector3(1, 0, 0)
	k.box_xf(Transform3D(b, c + Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.7), "l83_console")
	d.box_xf(Transform3D(b * Basis(Vector3(1, 0, 0), -0.5), c + Vector3(0, h + 0.05, 0) + fwd * 0.25), Vector3(w, 0.06, 0.45), "l83_console", GeoKit.ALL, false)
	var cols := maxi(1, int(w / 0.55))
	for i in cols:
		var x := (float(i) - (cols - 1) * 0.5) * (w / cols)
		var sp := c + side * x + Vector3(0, h * 0.72, 0) + fwd * 0.352
		d.quad(sp, fwd, side * 0.2, Vector3.UP * 0.15, "l83_screen" if rng.randf() < 0.6 else "l83_black", Vector2.ZERO, true)
		for j in 3:
			var dp := c + side * (x + (j - 1) * 0.14) + Vector3(0, h * 0.38, 0) + fwd * 0.352
			d.box_xf(Transform3D(b, dp + fwd * 0.012), Vector3(0.09, 0.09, 0.025), "l83_steel", GeoKit.ALL, false)
			d.quad(dp + fwd * 0.026, fwd, side * 0.035, Vector3.UP * 0.035, "l83_paper", Vector2.ZERO, true)
			if rng.randf() < lit:
				d.quad(dp + Vector3(0, 0.1, 0) + fwd * 0.004, fwd, side * 0.012, Vector3.UP * 0.012, "l83_led_g" if rng.randf() < 0.7 else "l83_led_r", Vector2.ZERO, true)
	postits(c + Vector3(0, h * 0.55, 0) + fwd * 0.36, fwd, 2 + rng.randi() % 3, w * 0.35)


func cabinet(c: Vector3, size: Vector3, mat := "l83_console", collide := true) -> void:
	k.box(c + Vector3(0, size.y * 0.5, 0), size, mat, GeoKit.ALL, collide)


func pipe_run(a: Vector3, b: Vector3, r: float, mat := "l83_steel") -> void:
	var len := a.distance_to(b)
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	if absf(dir.y) > 0.9:
		d.cylinder(mid, r, len, mat, 8, false)
		return
	# horizontal pipe as an 8-sided prism (boxes are cheaper than rotated cylinders here)
	var bas := Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir)
	d.box_xf(Transform3D(bas, mid), Vector3(r * 2.0, r * 2.0, len), mat, GeoKit.ALL, false)
	d.box_xf(Transform3D(bas * Basis(Vector3(0, 0, 1), PI * 0.25), mid), Vector3(r * 2.0, r * 2.0, len), mat, GeoKit.ALL, false)


# ------------------------------------------------------------------ middle deck

func _vestibule() -> void:
	var y := Hull.Y1
	plate("REACTOR COMPARTMENT\nTUNNEL - KEEP MOVING", Vector3(-1.2, y + 1.7, 0.07), Vector3(0, 0, 1), 0.9, 0.36, "l83_yellow", Color(0.05, 0.05, 0.05))
	plate("Leaving us?  ESCAPE TRUNK\nupper level, aft - up this ladder\nthen aft. Ask any of us.\n- The Crew", Vector3(3.3, y + 1.5, 6.25), Vector3(0, 0, 1), 0.62, 0.4)
	cabinet(Vector3(3.9, y, 1.4), Vector3(0.9, 1.9, 2.4), "l83_liner")
	Props.place(L, H.props, "ph/korean_fire_extinguisher_01", Vector3(-1.2, y, 0.25), 0.0)
	Props.place(L, H.props, "ph/fire_alarm", Vector3(1.6, y + 1.55, 0.1), 0.0)
	pipe_run(Vector3(-4.0, y + 2.15, 0.2), Vector3(-4.0, y + 2.15, 40.0), 0.07)
	pipe_run(Vector3(-3.7, y + 2.2, 0.2), Vector3(-3.7, y + 2.2, 40.0), 0.05, "l83_green")
	pipe_run(Vector3(3.8, y + 2.18, 0.2), Vector3(3.8, y + 2.18, 40.0), 0.08, "l83_red_paint")
	H.lamp(Vector3(0, y + 2.3, 2.2), 1, "l83_lamp", true, 0.6, 6.0)
	H.lamp(Vector3(0, y + 2.3, 5.4), 1, "l83_lamp", true, 0.5, 5.0)


## Berthing: curtained three-high racks along two narrow aisles; empty mattresses free to use.
func _berth() -> void:
	var y := Hull.Y1
	var z0 := 7.4
	var rows := [[-3.95, 1.0], [-1.65, -1.0], [1.65, 1.0], [3.95, -1.0]]   # x centre, opening side (+x/-x)
	for row in rows:
		var xc: float = row[0]
		var op: float = row[1]
		k.box(Vector3(xc - op * 0.05, y + 1.15, z0 + 5.2), Vector3(0.8, 2.3, 10.4), "l83_liner", 0, true)
		d.box(Vector3(xc - op * 0.42, y + 1.15, z0 + 5.2), Vector3(0.04, 2.3, 10.4), "l83_liner", GeoKit.ALL, false)
		for r in 5:
			var zc := z0 + 1.04 + r * 2.08
			for t in 3:
				var by := y + 0.32 + t * 0.68
				d.box(Vector3(xc, by - 0.04, zc), Vector3(0.86, 0.05, 1.98), "l83_steel", GeoKit.PY | GeoKit.NY | GeoKit.SIDES, false)
				d.box(Vector3(xc, by + 0.06, zc), Vector3(0.78, 0.13, 1.9), "l83_mattress", GeoKit.ALL, false)
				var made := rng.randf()
				if made < 0.3:
					d.box(Vector3(xc + rng.randf_range(-0.05, 0.05), by + 0.15, zc + 0.25), Vector3(0.74, 0.06, 1.25), "l83_blanket", GeoKit.ALL, false)
					d.box(Vector3(xc, by + 0.17, zc - 0.72), Vector3(0.5, 0.09, 0.32), "l83_paper", GeoKit.ALL, false)
				elif t == 0 and made > 0.82:
					Props.place(L, H.props, "ph/vintage_suitcase", Vector3(xc, by + 0.12, zc), 90.0, 0.2, false, false)
				# curtain on the aisle side, some drawn
				var cx := xc + op * 0.43
				var drawn := rng.randf()
				if drawn < 0.35:
					d.box(Vector3(cx, by + 0.29, zc), Vector3(0.02, 0.52, 1.9), "l83_curtain", GeoKit.ALL, false)
				else:
					var w := rng.randf_range(0.25, 0.5)
					d.box(Vector3(cx, by + 0.29, zc - 0.95 + w * 0.5), Vector3(0.03, 0.52, w), "l83_curtain", GeoKit.ALL, false)
					bunks.append(Vector3(cx + op * 0.45, y, zc))
				# reading lamp
				if rng.randf() < 0.25:
					d.quad(Vector3(xc - op * 0.38, by + 0.5, zc - 0.7), Vector3(op, 0, 0), Vector3(0, 0, 0.05), Vector3(0, 0.03, 0), "l83_lamp_warm", Vector2.ZERO, true)
			d.box(Vector3(xc, y + 1.15, zc + 1.04), Vector3(0.86, 2.3, 0.04), "l83_liner", GeoKit.ALL, false)
		d.box(Vector3(xc, y + 2.28, z0 + 5.2), Vector3(0.88, 0.06, 10.4), "l83_liner", GeoKit.ALL, false)
	for z: float in [9.0, 12.6, 16.2]:
		H.lamp(Vector3(-2.8, y + 2.32, z), 1, "l83_lamp_warm", true, 0.4, 4.5)
		H.lamp(Vector3(2.8, y + 2.32, z), 1, "l83_lamp_warm", true, 0.4, 4.5)
		H.lamp(Vector3(0.0, y + 2.32, z), 1, "l83_lamp", true, 0.35, 4.0)
	notes.append(["l83_berth", "Card tucked in a rack frame", "BERTHING. Empty racks are free to use - take any bare mattress. Crew racks have blankets; leave those be. The boat holds about 140. If you are not staying, please use the hatch so the Crew has room.", Vector3(-1.21, y + 1.3, 8.0)])
	plate("BERTHING\nbare racks: help yourself", Vector3(0.0, y + 1.9, 7.25), Vector3(0, 0, -1), 0.5, 0.22)


## Crew's mess, the canteen: a leather couch, a few small metal tables, a few chairs.
func _mess() -> void:
	var y := Hull.Y1
	# the leather couch along the port side, under the windows
	var cz := 24.9
	k.box(Vector3(-3.85, y + 0.22, cz), Vector3(0.85, 0.44, 3.0), "l83_leather")
	d.box(Vector3(-4.2, y + 0.62, cz), Vector3(0.22, 0.75, 3.0), "l83_leather", GeoKit.ALL, false)
	for s: float in [-1.0, 1.0]:
		d.box(Vector3(-3.85, y + 0.55, cz + s * 1.42), Vector3(0.85, 0.26, 0.2), "l83_leather", GeoKit.ALL, false)
	for i in 3:
		d.box(Vector3(-3.78, y + 0.5, cz - 0.95 + i * 0.95), Vector3(0.66, 0.12, 0.9), "l83_leather", GeoKit.ALL, false)
	# small metal tables on single pedestals, bolted down
	var tables := [Vector3(-1.2, y, 21.3), Vector3(1.8, y, 21.6), Vector3(1.8, y, 25.0), Vector3(-1.0, y, 28.4), Vector3(2.2, y, 28.5)]
	var chair_n := 0
	for i in tables.size():
		var t: Vector3 = tables[i]
		k.box(t + Vector3(0, 0.74, 0), Vector3(0.78, 0.04, 0.78), "l83_steel")
		d.cylinder(t + Vector3(0, 0.36, 0), 0.05, 0.72, "l83_steel", 8, false)
		d.cylinder(t + Vector3(0, 0.01, 0), 0.22, 0.02, "l83_steel", 12, false)
		var nchairs := 1 + (i % 2)
		for c in nchairs:
			var a := PI * 0.5 + c * PI + rng.randf_range(-0.3, 0.3)
			var cp := t + Vector3(cos(a), 0, sin(a)) * 0.6
			Props.place(L, H.props, "ph/SchoolChair_01", cp, rad_to_deg(-a) - 90.0 + rng.randf_range(-15, 15), 0.0, false)
			chair_n += 1
	# what is on the tables: coffee, a plate, cans - the Crew eats here
	var food := [["kenney/food-kit/mug", 0.1], ["kenney/food-kit/plate", 0.03], ["kenney/food-kit/soda-can", 0.12], ["kenney/food-kit/cup-coffee", 0.1], ["kenney/food-kit/sandwich", 0.06]]
	for i in tables.size():
		for j in 2:
			var f: Array = food[(i * 2 + j) % food.size()]
			Props.place(L, H.props, f[0], tables[i] + Vector3(rng.randf_range(-0.25, 0.25), 0.76, rng.randf_range(-0.25, 0.25)), rng.randf() * 360.0, f[1], false, false)
	# trading table: one table holds offered goods
	var tt: Vector3 = tables[2]
	Props.place(L, H.props, "ph/plastic_bottle_gallon", tt + Vector3(-0.2, 0.76, 0.1), 20.0)
	Props.place(L, H.props, "ph/cardboard_box_01", tt + Vector3(0.15, 0.76, -0.1), 80.0, 0.22)
	Props.place(L, H.props, "ph/vintage_flashlight", tt + Vector3(0.18, 0.76, 0.24), 140.0)
	plate("TRADE TABLE\nleave something, take something", tt + Vector3(0.0, 0.77, 0.37), Vector3(0, 1, 0), 0.34, 0.1, "l83_paper", Color(0.1, 0.1, 0.4), 0.0018)
	# crew notice board on the aft wall
	var nb := Vector3(-2.6, y + 1.45, 19.08)
	d.box(nb, Vector3(1.3, 0.85, 0.03), "l83_cork", GeoKit.ALL, false)
	for i in 6:
		var p := nb + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.28, 0.28), 0.02)
		d.quad(p, Vector3(0, 0, 1), Vector3(0.09, 0, 0), Vector3(0, 0.12, 0), "l83_paper" if i % 3 != 0 else "l83_postit_%d" % (i % 5), Vector2.ZERO, true)
	label("THE CREW OF THE\nACE OF SPADES", nb + Vector3(0, 0.33, 0.03), Vector3(0, 0, 1), 0.0032, Color(0.05, 0.05, 0.05))
	notes.append(["l83_crew", "The Crew's notice board", "THE CREW OF THE USS ACE OF SPADES (SSN 744). We live aboard: anywhere from twenty of us to a hundred. New members welcome. We trade - see the table. Food and water for up to 100, so portions are shared. Not staying? Ask anyone and we'll show you the hatch.", nb + Vector3(0, 0, 0.12)])
	# coffee and bug-juice at the forward wall beside the serving hatch
	cabinet(Vector3(-3.4, y, 30.55), Vector3(1.6, 0.9, 0.7), "l83_steel")
	Props.place(L, H.props, "kenney/furniture-kit/kitchencoffeemachine", Vector3(-3.7, y + 0.9, 30.55), 180.0, 0.38)
	Props.place(L, H.props, "kenney/food-kit/cup", Vector3(-3.2, y + 0.9, 30.5), 0.0, 0.1)
	Props.place(L, H.props, "ph/wall_clock", Vector3(0.0, y + 2.0, 30.92), 180.0)
	Props.place(L, H.props, "ph/korean_fire_extinguisher_01", Vector3(4.15, y, 19.4), 270.0)
	for z: float in [21.5, 25.0, 28.5]:
		H.lamp(Vector3(-1.6, y + 2.32, z), 1, "l83_lamp_warm", true, 0.55, 5.5)
		H.lamp(Vector3(1.8, y + 2.32, z), 1, "l83_lamp_warm", true, 0.55, 5.5)
	H.lamp(Vector3(0.0, y + 2.32, 18.0), 1, "l83_lamp", false, 0.45, 5.0)
	# Kira's outside note: stuck to the outer glass of the starboard window at z 25
	var w: Dictionary = {}
	for ww in H.windows:
		if absf((ww["pos"] as Vector3).z - 25.0) < 0.1 and (ww["n"] as Vector3).x > 0.0 and ww["deck"] == 1:
			w = ww
	if not w.is_empty():
		var gp: Vector3 = w["pos"]
		d.quad(gp + Vector3(0.025, -0.05, 0.12), Vector3(-1, 0, 0), Vector3(0, 0, 0.1), Vector3(0, 0.13, 0), "l83_paper", Vector2.ZERO, true)
		notes.append(["l83_kira_outside", "A note stuck to the OUTSIDE of the glass", "Undamaged by the water, in a child's hand: playing pirate got boring, she is off to make a jungle or something, might come back - \"just take the sub; I'm not gonna use it anymore.\" P.S. don't handle it too roughly or you might blow yourself up. - Kira", (w["inner"] as Vector3) + Vector3(-0.35, 0, 0)])


## Galley: working ovens, kettles, sinks and the refrigerators that never stay empty.
func _galley() -> void:
	var y := Hull.Y1
	# outboard counter with sink, ovens and a steam kettle
	k.box(Vector3(-4.0, y + 0.45, 35.5), Vector3(0.7, 0.9, 8.6), "l83_steel")
	d.box(Vector3(-4.0, y + 0.92, 35.5), Vector3(0.74, 0.04, 8.64), "l83_steel", GeoKit.ALL, false)
	Props.place(L, H.props, "kenney/furniture-kit/kitchenstove", Vector3(-3.95, y, 33.0), 90.0, 0.92, false)
	Props.place(L, H.props, "kenney/furniture-kit/kitchenstove", Vector3(-3.95, y, 33.9), 90.0, 0.92, false)
	Props.place(L, H.props, "kenney/furniture-kit/kitchensink", Vector3(-3.95, y, 36.6), 90.0, 0.92, false)
	Props.place(L, H.props, "kenney/furniture-kit/kitchenmicrowave", Vector3(-4.05, y + 0.94, 35.2), 90.0, 0.3, false)
	Props.place(L, H.props, "kenney/food-kit/pot-stew", Vector3(-3.95, y + 0.94, 33.0), 0.0, 0.2)
	Props.place(L, H.props, "kenney/food-kit/pan", Vector3(-3.95, y + 0.94, 33.9), 40.0, 0.06)
	Props.place(L, H.props, "kenney/food-kit/cutting-board", Vector3(-4.0, y + 0.94, 37.6), 90.0, 0.03)
	d.cylinder(Vector3(-3.9, y + 0.55, 38.6), 0.35, 1.1, "l83_steel", 14, false)
	# serving line under the hatch
	k.box(Vector3(-1.6, y + 0.48, 31.45), Vector3(1.6, 0.96, 0.6), "l83_steel")
	Props.place(L, H.props, "kenney/food-kit/plate-deep", Vector3(-2.0, y + 0.98, 31.4), 0.0, 0.05)
	Props.place(L, H.props, "kenney/food-kit/bowl", Vector3(-1.3, y + 0.98, 31.5), 0.0, 0.07)
	# three reach-in refrigerators along the forward bulkhead (glass doors, lit inside)
	for i in 3:
		var fx := -3.6 + i * 1.0
		var fp := Vector3(fx, y, 39.5)
		k.box(fp + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 0.8), "l83_steel", GeoKit.PX | GeoKit.NX | GeoKit.PY | GeoKit.PZ)
		k.box(fp + Vector3(0, 1.0, -0.38), Vector3(0.84, 1.9, 0.02), "l83_glass", GeoKit.NZ, false)
		d.quad(fp + Vector3(0, 1.0, 0.36), Vector3(0, 0, -1), Vector3(0.4, 0, 0), Vector3(0, 0.92, 0), "l83_fridge_in", Vector2.ZERO, true)
		for sh in 4:
			d.box(fp + Vector3(0, 0.35 + sh * 0.42, 0.0), Vector3(0.82, 0.02, 0.7), "l83_steel", GeoKit.PY, false)
		d.box(fp + Vector3(0.36, 1.0, -0.42), Vector3(0.04, 0.6, 0.04), "l83_steel", GeoKit.ALL, false)
		# the contents get their own kit so they can vanish and restock
		var ck := GeoKit.new(H.props, "FridgeContents%d" % i)
		ck.shadows = false
		for sh in 4:
			var sy := y + 0.36 + sh * 0.42
			if sh % 2 == 0:
				for b in 6:
					ck.cylinder(Vector3(fx - 0.3 + b * 0.12, sy + 0.12, 39.4 + (b % 2) * 0.12), 0.035, 0.24, "l83_bottle", 7, false)
			else:
				for b in 4:
					var m: String = ["l83_food", "l83_food_g", "l83_food_r", "l83_paper"][(b + sh + i) % 4]
					ck.box(Vector3(fx - 0.27 + b * 0.18, sy + 0.06, 39.45), Vector3(0.15, 0.11, 0.2), m, GeoKit.ALL, false)
		ck.commit()
		fridges.append({"root": ck.root, "pos": fp + Vector3(0, 1.0, -0.6), "full": true, "t": 0.0, "taken": 0})
		drawing(fp + Vector3(rng.randf_range(-0.2, 0.2), 1.62, -0.42), Vector3(0, 0, -1))
	drawing(Vector3(-3.6, y + 1.3, 33.4), Vector3(1, 0, 0))
	postits(Vector3(-3.62, y + 1.2, 34.6), Vector3(1, 0, 0), 3, 0.3)
	notes.append(["l83_stove_postit", "Pink post-it on the stove", "HOW TO MAKE THE STOVE GO: knob all the way left, push in, count to three, turn. Cook stuff. Turn it back. Easy. - Kira", Vector3(-3.55, y + 1.2, 34.6)])
	for z: float in [33.0, 36.5]:
		H.lamp(Vector3(-2.4, y + 2.32, z), 1, "l83_lamp", true, 0.6, 5.0)


func _ladder_room() -> void:
	var y := Hull.Y1
	for i in 4:
		cabinet(Vector3(0.8 + i * 0.55, y, 39.6), Vector3(0.5, 2.0, 0.6), "l83_liner")
	cabinet(Vector3(-0.2, y, 37.2), Vector3(0.6, 1.2, 1.2), "l83_steel")
	Props.place(L, H.props, "ph/steel_frame_shelves_02", Vector3(4.05, y, 32.2), 270.0)
	Props.place(L, H.props, "ph/cardboard_box_01", Vector3(4.05, y + 1.05, 32.2), 260.0)
	Props.place(L, H.props, "ph/plastic_crate_01", Vector3(0.3, y, 32.0), 10.0)
	Props.place(L, H.props, "ph/plastic_crate_01", Vector3(0.3, y + 0.26, 32.05), 25.0)
	plate("UP: CONTROL / SONAR\nDOWN: TORPEDO ROOM", Vector3(3.5, y + 1.95, 33.3), Vector3(0, 0, -1), 0.6, 0.2, "l83_yellow", Color(0.05, 0.05, 0.05))
	H.lamp(Vector3(1.0, y + 2.32, 32.4), 1, "l83_lamp", false, 0.5, 5.0)
	H.lamp(Vector3(2.4, y + 2.32, 38.4), 1, "l83_lamp", false, 0.4, 4.0)


# ------------------------------------------------------------------ upper deck

func _upper_aft() -> void:
	var y := Hull.Y2
	cabinet(Vector3(-3.4, y, 3.0), Vector3(0.9, 1.9, 4.0), "l83_liner")
	plate("ESCAPE TRUNK\nequalize before opening", Vector3(0.0, Hull.UPC + 0.45, 6.11), Vector3(0, 0, 1), 0.6, 0.22, "l83_yellow", Color(0.05, 0.05, 0.05))
	plate("Going out?  It is cold and black\nand a long way up. Take a breath,\nthen undo the hatch. - The Crew", Vector3(0.84, Hull.TRUNK_FLOOR + 1.3, 1.9), Vector3(-1, 0, 0), 0.6, 0.3)
	Props.place(L, H.props, "ph/lifebuoy", Vector3(-3.2, y + 1.9, 1.0), 90.0, 0.6)
	Props.place(L, H.props, "ph/medical_box", Vector3(-3.4, y + 1.9, 4.2), 90.0)
	H.lamp(Vector3(-1.4, Hull.UPC - 0.05, 2.0), 2, "l83_lamp", true, 0.5, 5.0)
	H.lamp(Vector3(1.2, Hull.UPC - 0.05, 9.6), 2, "l83_lamp", true, 0.35, 4.0)


## Control room: periscope stand, ship control and ballast panels, fire control, plot tables.
## Rigged for red. The controls are dead; Kira's post-it instructions cover them.
func _control_room() -> void:
	var y := Hull.Y2
	# periscope stand: a raised platform with two masts
	k.box(Vector3(0, y + 0.12, 22.8), Vector3(2.4, 0.24, 3.2), "l83_deck_metal")
	rail(Vector3(-1.2, y + 0.24, 21.2), Vector3(-1.2, y + 0.24, 24.4))
	scope_pos = Vector3(-0.4, y + 0.24, 22.2)
	for sp: Vector3 in [Vector3(-0.4, y + 0.24, 22.2), Vector3(0.45, y + 0.24, 23.5)]:
		d.cylinder(sp + Vector3(0, (Hull.UPC - sp.y) * 0.5, 0), 0.17, Hull.UPC - sp.y, "l83_steel", 14, false)
		k.box(sp + Vector3(0, 1.45, 0.25), Vector3(0.36, 0.34, 0.3), "l83_black", GeoKit.ALL, false)
		for s: float in [-1.0, 1.0]:
			d.box(sp + Vector3(s * 0.32, 1.35, 0.18), Vector3(0.3, 0.06, 0.06), "l83_black", GeoKit.ALL, false)
	drawing(Vector3(-0.4, y + 1.95, 22.03), Vector3(0, 0, -1))
	# ship control panel (helm and planes) forward-port, two seats with yokes
	console(Vector3(-2.0, y, 30.4), 180.0, 3.0, 1.55, 0.5)
	helm_pos = Vector3(-2.0, y, 29.2)
	for sx: float in [-2.7, -1.3]:
		k.box(Vector3(sx, y + 0.25, 29.1), Vector3(0.55, 0.5, 0.55), "l83_black")
		d.box(Vector3(sx, y + 0.8, 29.38), Vector3(0.55, 0.6, 0.1), "l83_black", GeoKit.ALL, false)
		d.box(Vector3(sx, y + 0.95, 29.75), Vector3(0.42, 0.06, 0.06), "l83_steel", GeoKit.ALL, false)
		d.cylinder(Vector3(sx, y + 0.95, 29.95), 0.03, 0.4, "l83_steel", 6, false)
	# ballast control panel forward-starboard with its "Christmas tree" of hull-opening lights
	console(Vector3(2.3, y, 30.4), 180.0, 2.2, 1.6, 0.6)
	d.box(Vector3(2.3, y + 1.95, 30.6), Vector3(1.6, 0.42, 0.08), "l83_black", GeoKit.ALL, false)
	for r in 3:
		for c in 10:
			var lp := Vector3(1.66 + c * 0.14, y + 1.82 + r * 0.12, 30.55)
			d.quad(lp, Vector3(0, 0, -1), Vector3(0.025, 0, 0), Vector3(0, 0.025, 0), "l83_led_g" if (r * 7 + c) % 5 != 0 else "l83_led_r", Vector2.ZERO, true)
	# depth gauges over the helm
	for i in 3:
		var gp := Vector3(-2.9 + i * 0.9, y + 2.0, 30.62)
		d.box(gp, Vector3(0.42, 0.42, 0.06), "l83_black", GeoKit.ALL, false)
		d.quad(gp + Vector3(0, 0, -0.035), Vector3(0, 0, -1), Vector3(0.17, 0, 0), Vector3(0, 0.17, 0), "l83_paper", Vector2.ZERO, true)
		d.quad(gp + Vector3(0.04, 0.03, -0.04), Vector3(0, 0, -1), Vector3(0.1, 0.06, 0), Vector3(-0.006, 0.01, 0), "l83_black", Vector2.ZERO, true)
	label("DEPTH  600 m", Vector3(-2.0, y + 2.28, 30.58), Vector3(0, 0, -1), 0.0028, Color(0.85, 0.85, 0.8))
	# fire control consoles along starboard
	for z: float in [16.0, 18.0, 26.5]:
		console(Vector3(3.45, y, z), 270.0, 1.7, 1.45, 0.3)
	# plotting tables aft, with charts
	for p: Vector3 in [Vector3(-1.9, y, 16.2), Vector3(1.0, y, 16.0)]:
		k.box(p + Vector3(0, 0.47, 0), Vector3(1.3, 0.94, 0.9), "l83_console")
		d.box(p + Vector3(0, 0.95, 0), Vector3(1.18, 0.01, 0.8), "l83_paper", GeoKit.PY, false)
		Props.place(L, H.props, "ph/clipboard", p + Vector3(0.35, 0.96, 0.1), 15.0)
	Props.place(L, H.props, "ph/binder_notebook", Vector3(-1.6, y + 0.96, 16.0), 70.0)
	# port-side consoles between the windows
	console(Vector3(-3.45, y, 22.0), 90.0, 1.6, 1.4, 0.2)
	console(Vector3(-3.45, y, 27.5), 90.0, 1.4, 1.4, 0.2)
	notes.append(["l83_helm_postit", "Yellow post-its all over the helm", "HOW TO DRIVE (by Kira): pull = up, push = down, turn = turn. Don't push it too far. It does nothing anyway now, but that's how. - Kira", Vector3(-2.0, y + 1.0, 30.0)])
	notes.append(["l83_depth", "Pencilled log on the plot table", "Bathometer: about 600 m (1970 ft). Rock valley on both beams. Controls dead; lights, galley and reactor fine. Fish through the windows: salmon, ragfish, Atka mackerel. Something big taps the hull sometimes. Stay calm, hold on.", Vector3(1.0, y + 1.0, 16.0)])
	for z: float in [15.6, 19.5, 23.0, 27.0, 30.0]:
		H.lamp(Vector3(-1.6, Hull.UPC - 0.04, z), 2, "l83_lamp_red", true, 0.4, 5.0)
		H.lamp(Vector3(1.8, Hull.UPC - 0.04, z), 2, "l83_lamp_red" if z < 26.0 else "l83_lamp", true, 0.38, 5.0)
	plate("CONTROL", Vector3(0.0, y + 1.95, 13.6), Vector3(0, 0, 1), 0.5, 0.14, "l83_paper")


func rail(a: Vector3, b: Vector3) -> void:
	H.rail(a, b)


func _radio_and_stateroom() -> void:
	var y := Hull.Y2
	# radio room (starboard)
	Props.place(L, H.props, "ph/metal_office_desk", Vector3(3.1, y, 10.0), 90.0, 0.0, true)
	Props.place(L, H.props, "ph/vintage_radio_transceiver", Vector3(3.2, y + 0.79, 9.6), 270.0)
	Props.place(L, H.props, "ph/office_notepads", Vector3(3.0, y + 0.79, 10.5), 80.0)
	Props.place(L, H.props, "ph/dining_chair_02", Vector3(2.1, y, 10.0), 90.0)
	for z: float in [7.2, 8.0, 12.8]:
		cabinet(Vector3(3.55, y, z), Vector3(0.6, 1.85, 0.7), "l83_console")
	console(Vector3(1.5, y, 7.1), 0.0, 0.9, 1.5, 0.6)
	postits(Vector3(3.2, y + 1.2, 12.42), Vector3(0, 0, -1), 3, 0.2)
	H.lamp(Vector3(2.5, Hull.UPC - 0.05, 10.0), 2, "l83_lamp", false, 0.4, 4.0)
	# commanding officer's stateroom (port): bunk, desk, wash basin
	k.box(Vector3(-3.4, y + 0.4, 10.0), Vector3(0.95, 0.8, 2.0), "l83_wood")
	d.box(Vector3(-3.4, y + 0.86, 10.0), Vector3(0.85, 0.12, 1.9), "l83_mattress", GeoKit.ALL, false)
	d.box(Vector3(-3.4, y + 0.93, 10.2), Vector3(0.82, 0.05, 1.3), "l83_blanket", GeoKit.ALL, false)
	k.box(Vector3(-1.6, y + 0.38, 7.1), Vector3(1.0, 0.76, 0.6), "l83_wood")
	Props.place(L, H.props, "ph/dining_chair_02", Vector3(-1.6, y, 7.7), 180.0)
	Props.place(L, H.props, "kenney/furniture-kit/bathroomsink", Vector3(-1.4, y, 13.1), 180.0, 0.9)
	Props.place(L, H.props, "ph/ornate_mirror_01", Vector3(-1.4, y + 1.2, 13.42), 180.0)
	drawing(Vector3(-1.6, y + 1.3, 6.62), Vector3(0, 0, 1))
	notes.append(["l83_drawing", "A crumpled drawing", "Crayon: a girl in a dark blue suit, purple pirate hat and eye-patch, waving a big sabre. \"Arrr!\" and \"Avast ye, mateys!\" written all round it. Signed: Kira.", Vector3(-1.6, y + 0.85, 7.1)])
	H.lamp(Vector3(-2.5, Hull.UPC - 0.05, 10.0), 2, "l83_lamp_warm", false, 0.4, 4.0)


func _sonar() -> void:
	var y := Hull.Y2
	for z: float in [32.2, 34.0, 35.8, 37.6]:
		console(Vector3(-3.4, y, z), 90.0, 1.5, 1.45, 0.4)
		Props.place(L, H.props, "ph/dining_chair_02", Vector3(-2.4, y, z), 270.0)
	console(Vector3(-2.0, y, 39.55), 180.0, 2.2, 1.6, 0.4)
	H.lamp(Vector3(-2.2, Hull.UPC - 0.05, 33.6), 2, "l83_lamp_red", true, 0.45, 4.5)
	H.lamp(Vector3(-2.2, Hull.UPC - 0.05, 37.6), 2, "l83_lamp_red", true, 0.45, 4.5)
	H.lamp(Vector3(2.0, Hull.UPC - 0.05, 38.6), 2, "l83_lamp", false, 0.4, 4.0)
	plate("SONAR", Vector3(-2.3, y + 1.95, 30.94), Vector3(0, 0, -1), 0.4, 0.14)


# ------------------------------------------------------------------ lower deck

func _aux_machinery() -> void:
	var y := Hull.Y0
	# air compressors and pumps (green), an emergency diesel, switchboards along the sides
	for p: Vector3 in [Vector3(1.6, y, 2.2), Vector3(1.6, y, 5.6)]:
		k.box(p + Vector3(0, 0.55, 0), Vector3(1.3, 1.1, 2.0), "l83_green")
		d.cylinder(p + Vector3(0, 1.3, -0.3), 0.32, 0.5, "l83_green", 12, false)
		pipe_run(p + Vector3(0.4, 1.1, 0.8), p + Vector3(0.4, 2.3, 0.8), 0.06)
	k.box(Vector3(-0.3, 0.6, 8.5), Vector3(1.8, 1.2, 1.4), "l83_green")
	plate("EMERGENCY DIESEL", Vector3(-0.3, 0.9, 7.78), Vector3(0, 0, -1), 0.5, 0.12, "l83_paper")
	for z: float in [1.0, 2.0, 3.0, 8.8]:
		cabinet(Vector3(3.0, y, z), Vector3(0.55, 1.95, 0.9), "l83_console")
	Props.place(L, H.props, "ph/metal_tool_chest", Vector3(-3.0, y, 8.6), 90.0)
	Props.place(L, H.props, "ph/power_box_01", Vector3(-3.2, y + 1.1, 1.2), 90.0)
	Props.place(L, H.props, "ph/hand_truck", Vector3(-1.2, y, 1.0), 20.0)
	postits(Vector3(1.6, 0.9, 1.18), Vector3(0, 0, -1), 2, 0.4)
	H.lamp(Vector3(0.0, 2.3, 3.0), 0, "l83_lamp", true, 0.5, 5.0)
	H.lamp(Vector3(0.0, 2.3, 7.5), 0, "l83_lamp", true, 0.45, 5.0)


## Torpedo room: weapons racks on both sides; some racks carry mattresses (hot-racking for the
## overflow when the boat is full); four tube breech doors on the forward bulkhead.
func _torpedo_room() -> void:
	var y := Hull.Y0
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 2.45, 1.05, 22.0), Vector3(1.6, 2.1, 21.6), "l83_steel", 0)
		for z0: float in [11.6, 18.8, 26.0]:
			for t in 3:
				var ty := y + 0.45 + t * 0.62
				for c in 2:
					var cx := sx * (1.95 + c * 0.62)
					var tz := z0 + 3.2
					_torpedo(Vector3(cx, ty, tz))
				d.box(Vector3(sx * 2.45, ty - 0.3, z0 + 3.2), Vector3(1.5, 0.05, 6.2), "l83_steel", GeoKit.ALL, false)
				# a mattress on top of some upper racks
				if t == 2 and rng.randf() < 0.6:
					d.box(Vector3(sx * 2.45, ty + 0.33, z0 + 3.2), Vector3(1.0, 0.12, 1.9), "l83_mattress", GeoKit.ALL, false)
			for zz in [z0, z0 + 6.4]:
				d.box(Vector3(sx * 2.45, 1.05, zz), Vector3(1.6, 2.1, 0.08), "l83_yellow", GeoKit.ALL, false)
	# breech doors
	for p: Vector3 in [Vector3(-0.9, 0.75, 39.85), Vector3(0.9, 0.75, 39.85), Vector3(-0.9, 1.75, 39.85), Vector3(0.9, 1.75, 39.85)]:
		d.box(p, Vector3(0.8, 0.8, 0.2), "l83_steel", GeoKit.ALL, false)
		d.box(p + Vector3(0, 0, -0.12), Vector3(0.62, 0.62, 0.06), "l83_bulkhead", GeoKit.ALL, false)
		d.box(p + Vector3(0, 0, -0.18), Vector3(0.36, 0.05, 0.05), "l83_red_paint", GeoKit.ALL, false)
		d.box(p + Vector3(0, 0, -0.18), Vector3(0.05, 0.36, 0.05), "l83_red_paint", GeoKit.ALL, false)
	label("1", Vector3(-0.9, 1.22, 39.7), Vector3(0, 0, -1), 0.006, Color(0.9, 0.9, 0.85))
	label("2", Vector3(0.9, 1.22, 39.7), Vector3(0, 0, -1), 0.006, Color(0.9, 0.9, 0.85))
	label("3", Vector3(-0.9, 2.22, 39.7), Vector3(0, 0, -1), 0.006, Color(0.9, 0.9, 0.85))
	label("4", Vector3(0.9, 2.22, 39.7), Vector3(0, 0, -1), 0.006, Color(0.9, 0.9, 0.85))
	drawing(Vector3(-0.9, 1.0, 39.68), Vector3(0, 0, -1))
	postits(Vector3(0.9, 0.85, 39.68), Vector3(0, 0, -1), 3, 0.2)
	# loading tray down the centre
	d.box(Vector3(0, 0.35, 25.0), Vector3(0.5, 0.06, 20.0), "l83_steel", GeoKit.ALL, false)
	for z: float in [16.0, 22.0, 28.0, 34.0]:
		d.box(Vector3(0, 0.17, z), Vector3(0.3, 0.34, 0.3), "l83_yellow", GeoKit.ALL, false)
	for z: float in [12.0, 17.0, 22.0, 27.0, 32.0, 37.5]:
		H.lamp(Vector3(0.0, 2.3, z), 0, "l83_lamp", true, 0.45, 5.0)
	plate("TORPEDO ROOM", Vector3(1.0, 1.9, 10.08), Vector3(0, 0, 1), 0.5, 0.14, "l83_paper")


func _torpedo(c: Vector3) -> void:
	d.box(c, Vector3(0.46, 0.46, 5.4), "l83_torpedo", GeoKit.SIDES, false)
	d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), PI * 0.25), c), Vector3(0.46, 0.46, 5.4), "l83_torpedo", GeoKit.SIDES, false)
	for q in 3:
		var sz := 0.42 - q * 0.12
		d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), PI * 0.125 * q), c + Vector3(0, 0, 2.75 + q * 0.12)), Vector3(sz, sz, 0.12), "l83_torpedo", GeoKit.ALL, false)
	d.box(c + Vector3(0, 0, -2.75), Vector3(0.34, 0.34, 0.12), "l83_steel", GeoKit.ALL, false)
	for zz: float in [-1.8, 0.0, 1.8]:
		d.box(c + Vector3(0, -0.22, zz), Vector3(0.54, 0.05, 0.12), "l83_yellow", GeoKit.ALL, false)
		d.box(c + Vector3(0, 0.0, zz), Vector3(0.5, 0.5, 0.05), "l83_steel", GeoKit.SIDES, false)


# ------------------------------------------------------------------ reactor / engine room

func _tunnel_dress() -> void:
	var y := Hull.Y1
	for z: float in [-2.0, -12.0]:
		plate("CAUTION\nRADIATION AREA", Vector3(0.74, y + 1.7, z), Vector3(-1, 0, 0), 0.4, 0.3, "l83_yellow", Color(0.35, 0.0, 0.3))
	plate("DO NOT LOITER IN TUNNEL", Vector3(-0.74, y + 1.9, -7.0), Vector3(1, 0, 0), 0.6, 0.12, "l83_yellow", Color(0.05, 0.05, 0.05))
	for i in 5:
		d.box(Vector3(-0.68, y + 1.1, -3.0 - i * 0.18), Vector3(0.05, 0.12, 0.05), "l83_yellow", GeoKit.ALL, false)
	pipe_run(Vector3(0.5, y + 2.3, -0.2), Vector3(0.5, y + 2.3, -13.8), 0.05)
	pipe_run(Vector3(-0.5, y + 2.32, -0.2), Vector3(-0.5, y + 2.32, -13.8), 0.04, "l83_green")


func _engine_dress() -> void:
	# lower flats: two main propulsion turbines, reduction gear, shaft; turbine generators fwd
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * 2.4, 0.5, -29.0), Vector3(1.5, 1.0, 8.4), "l83_green")
		for i in 3:
			d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), PI * i / 3.0), Vector3(sx * 2.4, 1.35, -29.0)), Vector3(1.55, 1.55, 7.6), "l83_green", GeoKit.SIDES, false)
		d.box(Vector3(sx * 2.4, 1.35, -29.0), Vector3(1.0, 1.0, 8.2), "l83_steel", GeoKit.PZ | GeoKit.NZ, false)
		k.box(Vector3(sx * 2.4, 0.8, -17.0), Vector3(1.4, 1.6, 3.6), "l83_green")
		k.box(Vector3(sx * 2.85, 0.95, -21.6), Vector3(0.7, 1.9, 2.4), "l83_console")
		pipe_run(Vector3(sx * 2.4, 2.1, -24.0), Vector3(sx * 2.4, 2.1, -34.0), 0.12)
	k.box(Vector3(0, 1.05, -37.0), Vector3(3.4, 2.1, 4.0), "l83_green")
	d.box(Vector3(0, 2.2, -37.0), Vector3(3.0, 0.2, 3.6), "l83_steel", GeoKit.ALL, false)
	pipe_run(Vector3(0, 1.0, -39.0), Vector3(0, 1.0, -43.9), 0.26)
	k.box(Vector3(0, 0.55, -41.5), Vector3(1.0, 1.1, 1.0), "l83_steel")
	# upper level: manoeuvring room panels on the platform, throttle wheels
	var y := Hull.Y1
	console(Vector3(-3.8, y, -16.5), 90.0, 3.6, 1.7, 0.7)
	console(Vector3(3.8, y, -16.5), 270.0, 3.6, 1.7, 0.5)
	for sx: float in [-0.9, 0.9]:
		d.cylinder(Vector3(sx, y + 1.1, -14.5), 0.38, 0.06, "l83_red_paint", 18, false)
		d.box(Vector3(sx, y + 0.55, -14.4), Vector3(0.12, 1.1, 0.12), "l83_steel", GeoKit.ALL, false)
	notes.append(["l83_throttle", "Green post-it on the throttle", "BIG WHEELS = GO FAST. Left one forward, right one back. I took the boat down here with these. Leave the reactor buttons alone, they're the grumpy ones. - Kira", Vector3(-0.9, y + 1.1, -14.7)])
	postits(Vector3(-3.42, y + 1.0, -16.5), Vector3(1, 0, 0), 4, 0.8)
	drawing(Vector3(3.42, y + 1.25, -15.6), Vector3(-1, 0, 0))
	plate("MANEUVERING", Vector3(0.0, y + 2.1, -14.2), Vector3(0, 0, -1), 0.6, 0.14)
	# catwalk dressing: lockers, tool chests, overhead pipe runs along the hull
	for sx: float in [-1.0, 1.0]:
		for z: float in [-24.0, -31.0, -36.5]:
			cabinet(Vector3(sx * 4.2, y, z), Vector3(0.6, 1.8, 1.2), "l83_console")
		pipe_run(Vector3(sx * 4.0, y + 2.3, -14.5), Vector3(sx * 4.0, y + 2.3, -43.5), 0.1)
		pipe_run(Vector3(sx * 3.6, y + 3.4, -14.5), Vector3(sx * 3.6, y + 3.4, -43.5), 0.07, "l83_green")
		pipe_run(Vector3(sx * 2.9, y + 4.3, -14.5), Vector3(sx * 2.9, y + 4.3, -43.5), 0.12, "l83_red_paint")
	Props.place(L, H.props, "ph/metal_tool_chest", Vector3(3.6, y, -27.5), 270.0)
	Props.place(L, H.props, "ph/WetFloorSign_01", Vector3(-1.0, 0.0, -24.5), 30.0)
	Props.place(L, H.props, "ph/Barrel_01", Vector3(2.9, 0.0, -40.6), 0.0)
	Props.place(L, H.props, "ph/Barrel_01", Vector3(2.5, 0.0, -42.4), 60.0)
	plate("MAIN ENGINE ROOM", Vector3(-1.4, y + 1.85, -14.16), Vector3(0, 0, -1), 0.6, 0.14)


func _overheads() -> void:
	# lower deck cable trays; middle deck ventilation duct down the centre passage
	for z0: float in [0.5, 20.5]:
		pipe_run(Vector3(-2.6, 2.3, z0), Vector3(-2.6, 2.3, z0 + 19.0), 0.06)
		pipe_run(Vector3(2.6, 2.32, z0), Vector3(2.6, 2.32, z0 + 19.0), 0.05, "l83_red_paint")
	d.box(Vector3(0, Hull.Y1 + 2.27, 11.75), Vector3(0.5, 0.14, 10.5), "l83_steel", GeoKit.ALL, false)
	for z: float in [8.0, 15.5]:
		d.quad(Vector3(0, Hull.Y1 + 2.199, z), Vector3.DOWN, Vector3(0.18, 0, 0), Vector3(0, 0, 0.12), "l83_black", Vector2.ZERO, true)
	for z: float in [16.0, 24.0, 32.0]:
		pipe_run(Vector3(-2.4, Hull.UPC - 0.12, z - 3.5), Vector3(-2.4, Hull.UPC - 0.12, z + 3.5), 0.05)
		pipe_run(Vector3(2.4, Hull.UPC - 0.14, z - 3.5), Vector3(2.4, Hull.UPC - 0.14, z + 3.5), 0.06, "l83_green")


## Post-it notes and Kira's crayon drawings, taped wherever she could reach.
func finalize() -> void:
	for p in postit_pts:
		var pos: Vector3 = p[0]
		var n: Vector3 = p[1]
		var side := Vector3.UP.cross(n).normalized() if absf(n.y) < 0.9 else Vector3.RIGHT
		var up := n.cross(side).normalized()
		var rot := rng.randf_range(-0.35, 0.35)
		var s2 := side.rotated(n, rot)
		var u2 := up.rotated(n, rot)
		d.quad(pos + n * 0.004, n, s2 * 0.037, u2 * 0.037, "l83_postit_%d" % int(p[2]), Vector2.ZERO, true)
	MatLib.register("l83_drawing", _drawing_material())
	for p in drawing_pts:
		var pos: Vector3 = p[0]
		var n: Vector3 = p[1]
		var side := Vector3.UP.cross(n).normalized()
		var rot := rng.randf_range(-0.2, 0.2)
		d.quad(pos + n * 0.005, n, side.rotated(n, rot) * -0.105, Vector3.UP.rotated(n, rot) * 0.14, "l83_drawing", Vector2.ZERO, true)


## A crude crayon pirate on crumpled paper: dark blue suit, purple hat and eye-patch, a sabre.
func _drawing_material() -> StandardMaterial3D:
	var w := 48
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var r := RandomNumberGenerator.new()
	r.seed = 83
	for y in h:
		for x in w:
			var c := 0.84 + r.randf_range(-0.05, 0.03) - (0.06 if (x + y * 3) % 17 == 0 else 0.0)
			img.set_pixel(x, y, Color(c, c * 0.98, c * 0.9))
	var blue := Color(0.1, 0.12, 0.45)
	var purple := Color(0.45, 0.12, 0.55)
	var skin := Color(0.85, 0.62, 0.45)
	var grey := Color(0.4, 0.4, 0.45)
	_disc(img, 24, 22, 6, skin)
	_rect(img, 17, 13, 31, 16, purple)
	_rect(img, 20, 8, 28, 13, purple)
	_rect(img, 20, 20, 23, 22, Color(0.05, 0.05, 0.05))
	_rect(img, 18, 29, 30, 46, blue)
	_line(img, 18, 31, 9, 40, blue)
	_line(img, 30, 31, 38, 24, blue)
	_line(img, 38, 24, 44, 8, grey)
	_line(img, 39, 24, 45, 9, grey)
	_line(img, 21, 46, 18, 58, blue)
	_line(img, 27, 46, 30, 58, blue)
	for i in 5:
		_line(img, 4 + i * 2, 52 + (i % 2), 6 + i * 2, 56, Color(0.7, 0.1, 0.1))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			img.set_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1), c)


func _disc(img: Image, cx: int, cy: int, rr: int, c: Color) -> void:
	for y in range(cy - rr, cy + rr + 1):
		for x in range(cx - rr, cx + rr + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= rr * rr:
				img.set_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1), c)


func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		var t := float(i) / maxf(1.0, n)
		var x := int(round(lerpf(x0, x1, t)))
		var y := int(round(lerpf(y0, y1, t)))
		_rect(img, x, y, x + 2, y + 2, c)


## Transverse overhead frames and cable trays: the boat's ribs showing through the overhead.
func _frames() -> void:
	# [ceiling y, half width, z from, z to, tray xs, tray z0, tray z1]
	var bands := [[Hull.Y1 - Hull.TH, 3.3, 6.8, 33.2, [-1.5, 1.5], 10.2, 39.6],
		[Hull.Y2 - Hull.TH, 4.4, 6.6, 33.4, [-3.45, 3.45], 17.2, 31.0],
		[Hull.UPC, 3.0, 6.3, 39.7, [-2.6, 2.6], 6.6, 39.6]]
	for bd in bands:
		var yc: float = bd[0]
		var hw: float = bd[1]
		var z: float = bd[2]
		while z < float(bd[3]):
			d.box(Vector3(0, yc - 0.06, z), Vector3(hw * 2.0, 0.12, 0.09), "l83_overhead", GeoKit.ALL, false)
			z += 1.2
		for x: float in bd[4]:
			var zm := (float(bd[5]) + float(bd[6])) * 0.5
			var zl := float(bd[6]) - float(bd[5])
			d.box(Vector3(x, yc - 0.2, zm), Vector3(0.34, 0.03, zl), "l83_steel", GeoKit.ALL, false)
			d.box(Vector3(x, yc - 0.15, zm), Vector3(0.28, 0.07, zl), "l83_black", GeoKit.PY | GeoKit.SIDES, false)
			var zz := float(bd[5]) + 0.6
			while zz < float(bd[6]):
				d.box(Vector3(x, yc - 0.12, zz), Vector3(0.03, 0.2, 0.03), "l83_steel", GeoKit.ALL, false)
				zz += 1.2


## Wall clutter along a wall line a->b (floor points), facing n: junction boxes, gauges,
## valve handwheels, vertical pipes, sound-powered phones and label plates.
func clutter(a: Vector3, b: Vector3, n: Vector3, step: float = 1.0) -> void:
	var t := (b - a).normalized()
	var bas := Basis(t, Vector3.UP, t.cross(Vector3.UP))
	var len := a.distance_to(b)
	var u := 0.3
	while u < len - 0.2:
		var p := a + t * u + n * 0.07
		var kind := rng.randi() % 7
		match kind:
			0:
				d.box_xf(Transform3D(bas, p + Vector3(0, rng.randf_range(1.55, 1.95), 0)), Vector3(0.28, 0.34, 0.12), "l83_console", GeoKit.ALL, false)
			1:
				var gp := p + Vector3(0, rng.randf_range(1.4, 1.8), 0)
				d.box_xf(Transform3D(bas, gp), Vector3(0.17, 0.17, 0.05), "l83_steel", GeoKit.ALL, false)
				d.quad(gp + n * 0.028, n, t * 0.065, Vector3.UP * 0.065, "l83_paper", Vector2.ZERO, true)
				d.quad(gp + n * 0.03 + t * 0.02 + Vector3(0, 0.015, 0), n, t * 0.04, Vector3.UP * 0.004, "l83_black", Vector2.ZERO, true)
			2:
				var vp := p + Vector3(0, rng.randf_range(0.9, 1.6), 0)
				for q in 4:
					var ang := q * PI * 0.5
					var off := t * cos(ang) * 0.14 + Vector3.UP * sin(ang) * 0.14
					d.box_xf(Transform3D(bas * Basis(n.normalized(), ang), vp + off + n * 0.04), Vector3(0.04, 0.2, 0.04), "l83_red_paint", GeoKit.ALL, false)
				d.box_xf(Transform3D(bas, vp + n * 0.04), Vector3(0.3, 0.03, 0.03), "l83_red_paint", GeoKit.ALL, false)
				d.box_xf(Transform3D(bas, vp), Vector3(0.08, 0.08, 0.1), "l83_steel", GeoKit.ALL, false)
			3:
				d.cylinder(p + Vector3(0, 1.15, 0), 0.045, 2.3, "l83_steel" if rng.randf() < 0.6 else "l83_green", 8, false)
			4:
				var pp := p + Vector3(0, 1.45, 0)
				d.box_xf(Transform3D(bas, pp), Vector3(0.22, 0.32, 0.12), "l83_console", GeoKit.ALL, false)
				d.box_xf(Transform3D(bas, pp + n * 0.08 + Vector3(0, 0.05, 0)), Vector3(0.05, 0.2, 0.05), "l83_black", GeoKit.ALL, false)
			5:
				plate(["VENT", "FRAME %d" % (40 + rng.randi() % 60), "EAB", "FIRE MAIN", "ELEC", "LOW PRESS AIR"][rng.randi() % 6],
					p + Vector3(0, rng.randf_range(1.75, 2.0), 0) - n * 0.065, n, 0.3, 0.07, "l83_yellow" if rng.randf() < 0.5 else "l83_paper", Color(0.05, 0.05, 0.05), 0.0018)
			_:
				pass
		u += step * rng.randf_range(0.6, 1.3)


func _walls() -> void:
	var y1 := Hull.Y1
	var y2 := Hull.Y2
	# middle deck: pipe runs over the windows the whole length; clutter on partitions and bulkheads
	for sx: float in [-1.0, 1.0]:
		pipe_run(Vector3(sx * 4.3, y1 + 2.02, 0.3), Vector3(sx * 4.3, y1 + 2.02, 39.7), 0.045, "l83_steel")
		pipe_run(Vector3(sx * 4.25, y1 + 2.14, 0.3), Vector3(sx * 4.25, y1 + 2.14, 39.7), 0.035, "l83_green")
		clutter(Vector3(sx * 4.33, y1, 0.3), Vector3(sx * 4.33, y1, 2.6), Vector3(-sx, 0, 0))
		clutter(Vector3(sx * 1.1, y1, 7.6), Vector3(sx * 1.1, y1, 17.6), Vector3(-sx, 0, 0), 1.4)
	clutter(Vector3(-4.3, y1, 0.08), Vector3(-0.8, y1, 0.08), Vector3(0, 0, 1))
	clutter(Vector3(0.8, y1, 0.08), Vector3(2.0, y1, 0.08), Vector3(0, 0, 1))
	clutter(Vector3(0.8, y1, 19.08), Vector3(4.3, y1, 19.08), Vector3(0, 0, 1))
	clutter(Vector3(2.4, y1, 30.92), Vector3(4.3, y1, 30.92), Vector3(0, 0, -1))
	clutter(Vector3(-0.62, y1, 31.4), Vector3(-0.62, y1, 39.4), Vector3(-1, 0, 0), 0.9)
	clutter(Vector3(-0.48, y1, 33.0), Vector3(-0.48, y1, 39.0), Vector3(1, 0, 0))
	# upper deck: corridor walls, aft area, control room gaps between consoles
	for sx: float in [-1.0, 1.0]:
		clutter(Vector3(sx * 1.06, y2, 6.7), Vector3(sx * 1.06, y2, 10.4), Vector3(-sx, 0, 0), 0.8)
		clutter(Vector3(sx * 1.06, y2, 11.4), Vector3(sx * 1.06, y2, 13.4), Vector3(-sx, 0, 0), 0.8)
		clutter(Vector3(sx * 3.88, y2, 19.4), Vector3(sx * 3.88, y2, 21.0), Vector3(-sx, 0, 0), 0.6)
		pipe_run(Vector3(sx * 3.75, y2 + 1.3, 0.3), Vector3(sx * 3.75, y2 + 1.3, 39.7), 0.04, "l83_red_paint" if sx > 0 else "l83_steel")
	clutter(Vector3(3.88, y2, 0.3), Vector3(3.88, y2, 6.3), Vector3(-1, 0, 0), 0.8)
	clutter(Vector3(-3.9, y2, 13.62), Vector3(-1.0, y2, 13.62), Vector3(0, 0, 1), 0.7)
	clutter(Vector3(1.0, y2, 13.62), Vector3(3.9, y2, 13.62), Vector3(0, 0, 1), 0.7)
	# lower deck: auxiliary machinery room sides, torpedo room bulkhead
	clutter(Vector3(-3.28, Hull.Y0, 0.3), Vector3(-3.28, Hull.Y0, 9.6), Vector3(1, 0, 0), 0.8)
	clutter(Vector3(3.28, Hull.Y0, 3.6), Vector3(3.28, Hull.Y0, 8.2), Vector3(-1, 0, 0), 0.8)
	clutter(Vector3(-3.2, Hull.Y0, 10.08), Vector3(-0.8, Hull.Y0, 10.08), Vector3(0, 0, 1), 0.7)
	clutter(Vector3(0.8, Hull.Y0, 10.08), Vector3(3.2, Hull.Y0, 10.08), Vector3(0, 0, 1), 0.7)
	# engine room: hull-side fittings along both catwalks
	for sx: float in [-1.0, 1.0]:
		clutter(Vector3(sx * 4.62, y1, -19.5), Vector3(sx * 4.62, y1, -40.5), Vector3(-sx, 0, 0), 1.3)
