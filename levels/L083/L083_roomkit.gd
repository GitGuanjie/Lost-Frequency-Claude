extends RefCounted
## Level 83: dressing kit (helpers, wall clutter, frames) for the compartment dressing (berthing, crew's mess, galley, control room, radio, sonar,
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


func rail(a: Vector3, b: Vector3) -> void:
	H.rail(a, b)


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
