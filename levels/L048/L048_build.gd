extends RefCounted
## Level 48 architecture. SOURCE: "many luxury houses and hotels" on the
## beach, varying in size, modern and luxurious, fitted with contemporary
## furniture, appliances and air conditioning; the Veroka Farmers' shops.
## Kit: villa(), hotel() (closed towers with balconies), lobby_hotel() (an
## enterable lobby with a first-floor sea terrace), kiosk(), farmhouse().

var lvl
var ter
var k: GeoKit
var props: Node3D
var lit_windows := 0
var ac_units: Array = []


func _init(level, terrain, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	ter = terrain
	k = kit
	props = prop_parent


static func materials() -> void:
	MatLib.define("l48_render", {"albedo_a": Color(0.86, 0.84, 0.8), "albedo_b": Color(0.8, 0.78, 0.74), "noise_scale": 0.8,
		"roughness_a": 0.85, "roughness_b": 0.95, "stain_amount": 0.12, "stain_color": Color(0.7, 0.62, 0.55), "bump_strength": 0.3}, "plaster")
	MatLib.define("l48_render_warm", {"albedo_a": Color(0.82, 0.72, 0.6), "albedo_b": Color(0.78, 0.68, 0.56), "noise_scale": 0.8,
		"roughness_a": 0.85, "roughness_b": 0.95, "bump_strength": 0.3}, "plaster")
	MatLib.define("l48_paver", {"albedo_a": Color(0.62, 0.56, 0.5), "albedo_b": Color(0.55, 0.5, 0.45), "pattern": 1,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.4, 0.36, 0.32), "tile_variation": 0.08,
		"noise_scale": 1.0, "roughness_a": 0.8, "roughness_b": 0.9}, "concrete")
	MatLib.define("l48_marble_tile", {"albedo_a": Color(0.84, 0.82, 0.78), "albedo_b": Color(0.78, 0.76, 0.72), "pattern": 1,
		"pattern_scale": Vector2(0.9, 0.9), "grout_width": 0.004, "grout_color": Color(0.6, 0.58, 0.55), "tile_variation": 0.05,
		"roughness_a": 0.12, "roughness_b": 0.25, "noise_scale": 0.6}, "concrete")
	MatLib.define("l48_pool_tile", {"albedo_a": Color(0.42, 0.68, 0.74), "albedo_b": Color(0.36, 0.62, 0.7), "pattern": 1,
		"pattern_scale": Vector2(0.2, 0.2), "grout_width": 0.01, "grout_color": Color(0.8, 0.85, 0.85), "roughness_a": 0.1, "roughness_b": 0.2}, "concrete")
	MatLib.define("l48_steel", {"albedo_a": Color(0.3, 0.3, 0.31), "albedo_b": Color(0.24, 0.24, 0.25), "metallic_value": 0.8,
		"roughness_a": 0.35, "roughness_b": 0.5, "noise_scale": 2.0}, "metal")
	MatLib.define("l48_awning", {"albedo_a": Color(0.85, 0.82, 0.74), "albedo_b": Color(0.62, 0.2, 0.12), "pattern": 2,
		"pattern_scale": Vector2(0.5, 1.0), "pattern_color": Color(0.62, 0.2, 0.12), "pattern_strength": 1.0, "noise_scale": 2.0,
		"roughness_a": 0.95, "roughness_b": 1.0}, "plaster")
	MatLib.define("l48_tin", {"albedo_a": Color(0.42, 0.42, 0.4), "albedo_b": Color(0.3, 0.28, 0.25), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.25, 0.22, 0.2), "pattern_strength": 0.5, "metallic_value": 0.5,
		"stain_amount": 0.4, "stain_color": Color(0.4, 0.22, 0.1)}, "rust")
	_tex("l48_deck", "old_wood_floor", Color(0.95, 0.75, 0.6), 2.0)
	_tex("l48_cladding", "old_wood_floor", Color(0.75, 0.5, 0.36), 1.6)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.05, 0.07, 0.09)
	glass.metallic = 0.6
	glass.roughness = 0.04
	glass.metallic_specular = 1.0
	MatLib.register("l48_glass", glass)
	var rail := StandardMaterial3D.new()
	rail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rail.albedo_color = Color(0.6, 0.75, 0.8, 0.22)
	rail.roughness = 0.05
	rail.metallic_specular = 0.9
	MatLib.register("l48_glassrail", rail)
	MatLib.register("l48_window_lit", MatLib.panel(Color(1.0, 0.72, 0.42), 1.6))
	MatLib.register("l48_fruit", MatLib.standard(Color(0.48, 0.48, 0.46), 0.6))


static func _tex(name: String, asset: String, tint: Color, rep: float) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint * 0.5, "albedo_b": tint * 0.4}, "wood_floor")
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	m.roughness = 0.8
	m.uv1_scale = Vector3(1.0 / rep, 1.0 / rep, 1.0)
	MatLib.register(name, m)


func _bx(o: Vector3, b: Basis, local: Vector3, size: Vector3, mat: String, collide: bool = false) -> void:
	k.box_xf(Transform3D(b, o + b * local), size, mat, GeoKit.ALL, collide)


func ground(o: Vector3, b: Basis, w: float, d: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for sx in [-0.5, 0.0, 0.5]:
		for sz in [-0.5, 0.0, 0.5]:
			var p: Vector3 = o + b * Vector3(w * sx, 0, d * sz)
			var y: float = ter.h(p.x, p.z)
			lo = minf(lo, y)
			hi = maxf(hi, y)
	return Vector2(lo, hi)


## A glazed front: dark glass with mullions; some panes lit from inside.
func glazing(o: Vector3, b: Basis, x0: float, x1: float, y0: float, y1: float, z: float, lit_chance: float) -> void:
	var w := x1 - x0
	_bx(o, b, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z), Vector3(w, y1 - y0, 0.06), "l48_glass")
	var n := maxi(1, int(w / 2.2))
	for i in n + 1:
		var x := x0 + w * float(i) / n
		_bx(o, b, Vector3(x, (y0 + y1) * 0.5, z + 0.05), Vector3(0.08, y1 - y0, 0.08), "l48_steel")
	for i in n:
		if lvl.rng.randf() < lit_chance:
			var x := x0 + w * (float(i) + 0.5) / n
			_bx(o, b, Vector3(x, (y0 + y1) * 0.5, z - 0.45), Vector3(w / n - 0.3, (y1 - y0) * 0.8, 0.04), "l48_window_lit")
			lit_windows += 1


func glass_rail(a: Vector3, c: Vector3) -> void:
	var d := c - a
	var bas := Basis.looking_at(d.normalized(), Vector3.UP)
	k.box_xf(Transform3D(bas, (a + c) * 0.5 + Vector3(0, 0.5, 0)), Vector3(0.03, 0.95, d.length()), "l48_glassrail", GeoKit.ALL, true)
	k.box_xf(Transform3D(bas, (a + c) * 0.5 + Vector3(0, 1.0, 0)), Vector3(0.07, 0.05, d.length()), "l48_steel", GeoKit.ALL, false)


## Two-storey modern villa facing local +z (the sea), with a deck.
func villa(o: Vector3, yaw: float, w: float, d: float, ac: bool) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var g := ground(o, b, w + 6.0, d + 6.0)
	var fy := g.y + 0.3
	var oo := Vector3(o.x, 0, o.z)
	_bx(oo, b, Vector3(0, (fy + g.x - 0.6) * 0.5, 0), Vector3(w + 0.4, fy - g.x + 0.6, d + 0.4), "l48_render_warm", true)
	# ground storey (white) and a cantilevered upper storey (timber), offset
	_bx(oo, b, Vector3(0, fy + 1.6, -0.5), Vector3(w, 3.2, d - 1.0), "l48_render", true)
	var off := w * 0.12 * (1.0 if int(o.x) % 2 == 0 else -1.0)
	_bx(oo, b, Vector3(off, fy + 4.75, 0.6), Vector3(w * 0.78, 3.1, d), "l48_cladding", true)
	_bx(oo, b, Vector3(off, fy + 6.4, 0.6), Vector3(w * 0.78 + 0.8, 0.22, d + 0.8), "l48_render")
	_bx(oo, b, Vector3(0, fy + 3.25, -0.5), Vector3(w + 0.6, 0.18, d - 0.4), "l48_render")
	glazing(oo, b, -w * 0.45, w * 0.3, fy + 0.15, fy + 3.0, d * 0.5 - 0.98, 0.5)
	glazing(oo, b, off - w * 0.33, off + w * 0.33, fy + 3.5, fy + 6.1, d * 0.5 + 0.63, 0.35)
	# deck with glass rail, loungers and an umbrella
	var dz := d * 0.5 + 2.6
	_bx(oo, b, Vector3(0, fy - 0.08, dz - 0.4), Vector3(w + 0.4, 0.2, 5.2), "l48_deck", true)
	var dy: float = fy + 0.02
	var p0: Vector3 = oo + b * Vector3(-w * 0.5 - 0.2, dy, dz + 2.2)
	var p1: Vector3 = oo + b * Vector3(-1.2, dy, dz + 2.2)
	var p2: Vector3 = oo + b * Vector3(1.2, dy, dz + 2.2)
	var p3: Vector3 = oo + b * Vector3(w * 0.5 + 0.2, dy, dz + 2.2)
	glass_rail(p0, p1)
	glass_rail(p2, p3)
	if fy - ter.h((p1.x + p2.x) * 0.5, (p1.z + p2.z) * 0.5 + 1.0) > 0.25:
		var gy: float = ter.h((p1.x + p2.x) * 0.5, (p1.z + p2.z) * 0.5)
		var n := maxi(1, int(ceil((fy - gy) / 0.17)))
		k.stairs(oo + b * Vector3(0, 0, dz + 2.2 + n * 0.3) + Vector3(0, gy - 0.3, 0), b * Vector3(0, 0, -1), 2.2, fy - gy + 0.3, n, "l48_deck", 0.3)
	for sx in [-0.3, 0.1]:
		var lp: Vector3 = oo + b * Vector3(w * sx, fy, dz)
		Props.place(lvl, props, "kenney/furniture-kit/loungechairrelax", lp, yaw + 180.0, 0.9)
	var up: Vector3 = oo + b * Vector3(w * 0.32, fy, dz - 0.5)
	k.cylinder(up + Vector3(0, 1.2, 0), 0.04, 2.4, "l48_steel", 6, false, false)
	k.cylinder(up + Vector3(0, 2.35, 0), 1.4, 0.06, "l48_awning", 12, false, true)
	if ac:
		var ap: Vector3 = oo + b * Vector3(w * 0.5 + 0.25, fy, -d * 0.2)
		Props.place(lvl, props, "ph/exterior_aircon_unit", ap, yaw - 90.0, 0.0, false)
	else:
		var ap2: Vector3 = oo + b * Vector3(w * 0.5 + 0.4, fy, -d * 0.2)
		_ac_box(ap2, yaw - 90.0)
	# lit house number plate and a planter
	_bx(oo, b, Vector3(-w * 0.5 + 0.8, fy + 0.4, d * 0.5 + 0.2), Vector3(1.2, 0.8, 0.6), "l48_render_warm")
	Props.place(lvl, props, "kenney/furniture-kit/pottedplant", oo + b * Vector3(-w * 0.5 + 0.8, fy + 0.8, d * 0.5 + 0.2), 0.0, 1.0)


func _ac_box(p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	k.box_xf(Transform3D(b, p + Vector3(0, 0.45, 0)), Vector3(1.0, 0.8, 0.4), "l48_render", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + b * Vector3(0.18, 0.45, 0.21)), Vector3(0.5, 0.5, 0.02), "l48_steel", GeoKit.ALL, false)
	ac_units.append(p)


## A closed hotel tower: floors with balconies and glass, roof plant.
func hotel(o: Vector3, w: float, d: float, floors: int, name_text: String) -> void:
	var b := Basis()
	var g := ground(o, b, w + 4.0, d + 4.0)
	var fy := g.y + 0.2
	var fh := 3.3
	var top := fy + 4.2 + fh * (floors - 1)
	_bx(o, b, Vector3(0, (g.x - 0.6 + top) * 0.5, 0), Vector3(w, top - g.x + 0.6, d), "l48_render", true)
	glazing(o, b, -w * 0.48, w * 0.48, fy + 0.2, fy + 3.8, d * 0.5 + 0.05, 0.7)
	for f in floors - 1:
		var y := fy + 4.2 + f * fh
		_bx(o, b, Vector3(0, y - 0.05, d * 0.5 + 0.9), Vector3(w + 0.2, 0.2, 1.8), "l48_render")
		glazing(o, b, -w * 0.47, w * 0.47, y + 0.1, y + fh - 0.35, d * 0.5 + 0.05, 0.25)
		var bas := Basis.looking_at(Vector3.RIGHT, Vector3.UP)
		k.box_xf(Transform3D(bas, o + Vector3(0, y + 0.55, d * 0.5 + 1.78)), Vector3(0.03, 1.0, w), "l48_glassrail", GeoKit.ALL, false)
		for i in int(w / 4.5) + 1:
			var x := -w * 0.5 + i * w / int(w / 4.5)
			_bx(o, b, Vector3(x, y + fh * 0.5, d * 0.5 + 0.9), Vector3(0.18, fh, 1.8), "l48_render")
		# side windows
		for s in [-1.0, 1.0]:
			for i in int(d / 3.0):
				var z := -d * 0.5 + (i + 0.5) * d / int(d / 3.0)
				_bx(o, b, Vector3(s * (w * 0.5 + 0.03), y + 1.5, z), Vector3(0.06, 1.6, 1.6), "l48_glass")
	_bx(o, b, Vector3(0, top + 0.5, 0), Vector3(w + 0.3, 1.0, d + 0.3), "l48_render")
	for i in 3:
		_ac_box(o + Vector3(-w * 0.3 + i * w * 0.3, top + 1.0, -d * 0.2), 0.0)
	var lab := Label3D.new()
	lab.text = name_text
	lab.font_size = 96
	lab.pixel_size = 0.012
	lab.modulate = Color(1.0, 0.85, 0.6)
	lab.outline_size = 0
	lab.position = o + Vector3(0, top - 0.8, d * 0.5 + 0.08)
	lvl.add_child(lab)


## The enterable hotel: a lobby (ground) and a sea terrace (first floor).
## Returns {"floor": y, "terrace": y, "noclip": Vector3 wall point}.
func lobby_hotel(o: Vector3, w: float, d: float, floors: int) -> Dictionary:
	var b := Basis()
	var g := ground(o, b, w + 12.0, d + 14.0)
	var fy := g.y + 0.15
	var lh := 4.4
	var z0 := o.z - d * 0.5
	var z1 := o.z + d * 0.5
	var x0 := o.x - w * 0.5
	var x1 := o.x + w * 0.5
	k.slab(x0 - 0.3, z0 - 0.3, x1 + 0.3, z1 + 0.3, fy, fy - g.x + 0.6, "l48_marble_tile")
	# lobby walls: solid back and sides, glazed front with a 3 m entrance
	k.wall(Vector3(x0, fy, z0), Vector3(x1, fy, z0), lh, 0.3, "l48_render")
	k.wall(Vector3(x0, fy, z0), Vector3(x0, fy, z1), lh, 0.3, "l48_render")
	k.wall(Vector3(x1, fy, z0), Vector3(x1, fy, z1), lh, 0.3, "l48_render")
	k.box(Vector3(o.x - (w * 0.25 + 0.75), fy + lh * 0.5, z1), Vector3(w * 0.5 - 1.5, lh, 0.12), "l48_glass")
	k.box(Vector3(o.x + (w * 0.25 + 0.75), fy + lh * 0.5, z1), Vector3(w * 0.5 - 1.5, lh, 0.12), "l48_glass")
	for i in 9:
		var x := x0 + w * i / 8.0
		if absf(x - o.x) < 1.6:
			continue
		k.box(Vector3(x, fy + lh * 0.5, z1 + 0.05), Vector3(0.12, lh, 0.14), "l48_steel", GeoKit.ALL, false)
	k.box(Vector3(o.x, fy + lh - 0.3, z1), Vector3(3.2, 0.6, 0.3), "l48_render")
	# entrance ramp from the forecourt up to the lobby floor
	var ey: float = ter.h(o.x, z1 + 3.6)
	if fy - ey > 0.05:
		k.ramp(Vector3(o.x, ey - 0.02, z1 + 3.6), Vector3(o.x, fy, z1 + 0.3), 3.6, 0.3, "l48_marble_tile")
	# ceiling and the closed tower above
	var top := fy + lh + 3.3 * (floors - 1)
	k.box(Vector3(o.x, fy + lh + 0.1, o.z), Vector3(w, 0.2, d), "l48_render_warm", GeoKit.NY, false)
	k.box(Vector3(o.x, (fy + lh + top) * 0.5 + 0.1, o.z), Vector3(w, top - fy - lh, d), "l48_render", GeoKit.ALL & ~GeoKit.NY, true)
	for f in floors - 1:
		var y := fy + lh + f * 3.3
		glazing(o, b, -w * 0.47, w * 0.47, y + 0.25, y + 2.95, d * 0.5 + 0.05, 0.3)
		if f > 0:
			_bx(o, b, Vector3(0, y + 0.1, d * 0.5 + 0.8), Vector3(w + 0.2, 0.2, 1.6), "l48_render")
	_bx(o, b, Vector3(0, top + 0.5, 0), Vector3(w + 0.3, 1.0, d + 0.3), "l48_render")
	# the sea terrace over the entrance canopy, reached by a side stair
	var ty := fy + lh + 0.25
	var tz0 := z1
	var tz1 := z1 + 7.0
	k.slab(x0, tz0, x1, tz1, ty, 0.35, "l48_deck")
	for x in [x0 + 0.4, o.x - 6.0, o.x + 6.0, x1 - 0.4]:
		k.box(Vector3(x, (fy + ty) * 0.5, tz1 - 0.4), Vector3(0.45, ty - fy, 0.45), "l48_render")
	glass_rail(Vector3(x0, ty, tz1), Vector3(x1, ty, tz1))
	glass_rail(Vector3(x0, ty, tz0), Vector3(x0, ty, tz1))
	glass_rail(Vector3(x1, ty, tz0 + 2.4), Vector3(x1, ty, tz1))
	# side stair along the terrace's east edge, climbing north to a landing
	var sx := x1 + 1.25
	var steps := int(ceil((ty - fy) / 0.18))
	var run := 0.28
	var top_z := tz0 + 2.3
	k.stairs(Vector3(sx, fy, top_z + steps * run), Vector3(0, 0, -1), 2.0, ty - fy, steps, "l48_render", run)
	k.slab(x1 - 0.2, tz0 - 0.1, x1 + 2.4, top_z, ty, 0.3, "l48_deck")
	glass_rail(Vector3(x1 + 2.4, ty, tz0 - 0.1), Vector3(x1 + 2.4, ty, top_z))
	glass_rail(Vector3(x1 - 0.2, ty, tz0 - 0.1), Vector3(x1 + 2.4, ty, tz0 - 0.1))
	# terrace bar furniture and umbrellas
	for i in 4:
		var p := Vector3(x0 + 4.0 + i * (w - 8.0) / 3.0, ty, z1 + 3.8)
		Props.place(lvl, props, "ph/coffee_table_round_01", p, 0.0, 0.0, true)
		Props.place(lvl, props, "kenney/furniture-kit/chairmoderncushion", p + Vector3(0, 0, 1.0), 180.0, 0.85)
		Props.place(lvl, props, "kenney/furniture-kit/chairmoderncushion", p + Vector3(0, 0, -1.0), 0.0, 0.85)
		k.cylinder(p + Vector3(0, 1.3, 0), 0.04, 2.6, "l48_steel", 6, false, false)
		k.cylinder(p + Vector3(0, 2.55, 0), 1.6, 0.06, "l48_awning", 12, false, true)
	var lab := Label3D.new()
	lab.text = "HOTEL"
	lab.font_size = 96
	lab.pixel_size = 0.014
	lab.modulate = Color(1.0, 0.85, 0.6)
	lab.position = Vector3(o.x, top - 0.6, z1 + 0.08)
	lvl.add_child(lab)
	_lobby_furniture(o, w, d, fy)
	return {"floor": fy, "terrace": ty, "noclip": Vector3(x1 - 0.15, fy, o.z - 2.0), "z1": z1, "stair_x": sx}


func _lobby_furniture(o: Vector3, w: float, d: float, fy: float) -> void:
	var zb := o.z - d * 0.5
	# reception desk with a counter and the key wall
	k.box(Vector3(o.x, fy + 0.55, zb + 3.2), Vector3(6.0, 1.1, 0.9), "l48_cladding")
	k.box(Vector3(o.x, fy + 1.13, zb + 3.2), Vector3(6.3, 0.06, 1.1), "l48_marble_tile", GeoKit.ALL, false)
	k.box(Vector3(o.x, fy + 2.0, zb + 0.2), Vector3(5.0, 2.4, 0.06), "l48_cladding", GeoKit.ALL, false)
	Props.place(lvl, props, "ph/classic_laptop", Vector3(o.x - 1.4, fy + 1.16, zb + 3.2), 180.0)
	Props.place(lvl, props, "ph/vintage_telephone_wall_clock", Vector3(o.x + 1.8, fy + 2.3, zb + 0.28), 0.0)
	Props.place(lvl, props, "kenney/furniture-kit/chairdesk", Vector3(o.x + 1.0, fy, zb + 2.2), 0.0, 1.0)
	# lounge groups
	for gx in [-w * 0.3, w * 0.28]:
		var c := Vector3(o.x + gx, fy, o.z + 1.5)
		Props.place(lvl, props, "kenney/furniture-kit/rugrectangle", c, 0.0, 0.03)
		Props.place(lvl, props, "ph/Sofa_01", c + Vector3(0, 0, -1.6), 0.0, 0.0, true)
		Props.place(lvl, props, "ph/ArmChair_01", c + Vector3(-1.8, 0, 0.2), 90.0)
		Props.place(lvl, props, "ph/ArmChair_01", c + Vector3(1.8, 0, 0.2), -90.0)
		Props.place(lvl, props, "ph/coffee_table_round_01", c + Vector3(0, 0, 0.1), 0.0)
		Props.place(lvl, props, "ph/ceiling_fan", c + Vector3(0, 3.8, 0), 0.0)
	for p in [Vector3(-w * 0.45, 0, -d * 0.4), Vector3(w * 0.45, 0, -d * 0.4), Vector3(-2.2, 0, d * 0.42), Vector3(2.2, 0, d * 0.42), Vector3(-w * 0.45, 0, d * 0.4)]:
		Props.place(lvl, props, "kenney/furniture-kit/pottedplant", o + p + Vector3(0, fy - o.y, 0), 0.0, 1.5)
	Props.place(lvl, props, "ph/vintage_suitcase", Vector3(o.x + 4.0, fy, zb + 4.6), 30.0)
	Props.place(lvl, props, "ph/WetFloorSign_01", Vector3(o.x - 4.5, fy, o.z + 4.0), 20.0)
	for x in [-w * 0.3, 0.0, w * 0.3]:
		Props.place(lvl, props, "ph/modern_ceiling_lamp_01", Vector3(o.x + x, fy + 3.45, o.z - 3.0), 0.0)
		lvl.lights.add_anchor(Vector3(o.x + x, fy + 3.2, o.z - 2.0), Color(1.0, 0.78, 0.55), 1.6, 9.0, 0.0, "lobby")


## The Veroka Farmers' juice and fruit kiosk on the promenade.
func kiosk(o: Vector3) -> void:
	o.y = ter.h(o.x, o.z)
	k.box(o + Vector3(0, 0.55, 0), Vector3(3.6, 1.1, 1.6), "l48_cladding")
	k.box(o + Vector3(0, 1.13, 0.2), Vector3(3.8, 0.06, 1.2), "l48_deck", GeoKit.ALL, false)
	k.box(o + Vector3(0, 1.6, -0.75), Vector3(3.6, 3.2, 0.12), "l48_cladding")
	for sx in [-1.75, 1.75]:
		k.box(o + Vector3(sx, 1.4, 0.75), Vector3(0.1, 2.8, 0.1), "l48_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.3), o + Vector3(0, 2.9, 0.3)), Vector3(4.2, 0.05, 2.4), "l48_awning", GeoKit.ALL, false)
	var lab := Label3D.new()
	lab.text = "VEROKA  JUICE  ·  FRUIT"
	lab.font_size = 64
	lab.pixel_size = 0.006
	lab.modulate = Color(0.95, 0.9, 0.8)
	lab.outline_size = 8
	lab.outline_modulate = Color(0.2, 0.12, 0.08)
	lab.position = o + Vector3(0, 2.75, -0.66)
	lvl.add_child(lab)
	# grey egg-like fruit in trays and bottled juice
	for t in 3:
		var tp := o + Vector3(-1.2 + t * 1.2, 1.16, 0.35)
		k.box(tp + Vector3(0, 0.04, 0), Vector3(0.9, 0.08, 0.6), "l48_deck", GeoKit.ALL, false)
		for q in 9:
			var fp := tp + Vector3(-0.3 + (q % 3) * 0.3, 0.12, -0.18 + int(q / 3) * 0.18)
			_fruit(fp)
	for q in 6:
		Props.place(lvl, props, "kenney/food-kit/soda-bottle", o + Vector3(-1.5 + q * 0.18, 1.16, -0.25), 0.0, 0.3)
	Props.place(lvl, props, "ph/plastic_crate_01", o + Vector3(2.4, 0, 0.2), 15.0)
	Props.place(lvl, props, "ph/plastic_crate_01", o + Vector3(2.4, 0.26, 0.2), 40.0)


func _fruit(p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.06
	sm.height = 0.15
	sm.radial_segments = 8
	sm.rings = 4
	mi.mesh = sm
	mi.material_override = MatLib.get_mat("l48_fruit")
	mi.position = p
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lvl.add_child(mi)


## A farm shed with a tin roof and trellis rows (the Veroka farm).
func farm_shed(o: Vector3) -> void:
	o.y = ter.h(o.x, o.z)
	k.box(o + Vector3(0, 1.4, 0), Vector3(6.0, 2.8, 4.0), "l48_cladding")
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.12), o + Vector3(0, 3.0, 0.3)), Vector3(6.8, 0.06, 5.0), "l48_tin", GeoKit.ALL, false)
	k.box(o + Vector3(0, 1.05, 2.02), Vector3(1.0, 2.1, 0.05), "l48_steel", GeoKit.ALL, false)
	for i in 4:
		Props.place(lvl, props, "ph/plastic_crate_01", o + Vector3(-2.5 + i * 0.6, 0, 2.6), lvl.rng.randf_range(0, 40))
	Props.place(lvl, props, "ph/hand_truck", o + Vector3(2.4, 0, 2.6), 200.0)


## A wooden farmhouse with an enterable ground-floor room and a porch.
## Returns the door point and the interior centre.
func farmhouse(o: Vector3, yaw: float) -> Dictionary:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var w := 8.0
	var d := 6.0
	var g := ground(o, b, w + 3.0, d + 3.0)
	var fy := g.y + 0.35
	var oo := Vector3(o.x, 0, o.z)
	_bx(oo, b, Vector3(0, (fy + g.x - 0.6) * 0.5, 0), Vector3(w + 0.3, fy - g.x + 0.6, d + 0.3), "l48_render_warm", true)
	var c := [Vector3(-w * 0.5, fy, d * 0.5), Vector3(w * 0.5, fy, d * 0.5), Vector3(w * 0.5, fy, -d * 0.5), Vector3(-w * 0.5, fy, -d * 0.5)]
	var wc: Array = []
	for p in c:
		wc.append(oo + b * (p as Vector3))
	var win := {"w": 1.0, "h": 1.1, "sill": 0.95}
	k.wall(wc[0], wc[1], 2.9, 0.18, "l48_cladding", [{"at": w * 0.5, "w": 1.1, "h": 2.1, "sill": 0.0}, win.merged({"at": 1.6}), win.merged({"at": w - 1.6})])
	k.wall(wc[1], wc[2], 2.9, 0.18, "l48_cladding", [win.merged({"at": d * 0.5})])
	k.wall(wc[2], wc[3], 2.9, 0.18, "l48_cladding", [win.merged({"at": w * 0.5})])
	k.wall(wc[3], wc[0], 2.9, 0.18, "l48_cladding", [win.merged({"at": d * 0.5})])
	_bx(oo, b, Vector3(0, fy + 2.95, 0), Vector3(w, 0.1, d), "l48_deck")
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, s * 0.6), oo + b * Vector3(0, fy + 3.85, s * d * 0.27)), Vector3(w + 1.0, 0.1, d * 0.68), "l48_tin", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		var t: Vector3 = oo + b * Vector3(sx * w * 0.5, fy + 4.95, 0)
		k._tri_fan(t, oo + b * Vector3(sx * w * 0.5, fy + 2.9, -d * 0.5), oo + b * Vector3(sx * w * 0.5, fy + 2.9, d * 0.5), b * Vector3(sx, 0, 0), "l48_cladding")
	# porch
	_bx(oo, b, Vector3(0, fy - 0.1, d * 0.5 + 1.2), Vector3(w, 0.2, 2.4), "l48_deck", true)
	for sx in [-0.48, 0.48]:
		_bx(oo, b, Vector3(w * sx, fy + 1.3, d * 0.5 + 2.3), Vector3(0.15, 2.6, 0.15), "l48_cladding")
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, 0.2), oo + b * Vector3(0, fy + 2.75, d * 0.5 + 1.3)), Vector3(w + 0.4, 0.06, 2.8), "l48_tin", GeoKit.ALL, false)
	var gy: float = ter.h((oo + b * Vector3(0, 0, d * 0.5 + 2.6)).x, (oo + b * Vector3(0, 0, d * 0.5 + 2.6)).z)
	if fy - gy > 0.2:
		var n := maxi(1, int(ceil((fy - gy) / 0.17)))
		k.stairs(oo + b * Vector3(0, 0, d * 0.5 + 2.4 + n * 0.3) + Vector3(0, gy, 0), b * Vector3(0, 0, -1), 1.6, fy - gy, n, "l48_deck", 0.3)
	# inside: an old kitchen table, chairs, a stove, a shelf
	Props.place(lvl, props, "ph/dining_table", oo + b * Vector3(-1.0, 0, -0.6) + Vector3(0, fy, 0), yaw)
	Props.place(lvl, props, "ph/dining_chair_02", oo + b * Vector3(-1.0, 0, 0.5) + Vector3(0, fy, 0), yaw + 180.0)
	Props.place(lvl, props, "ph/wooden_bookshelf_worn", oo + b * Vector3(2.6, 0, -2.6) + Vector3(0, fy, 0), yaw)
	Props.place(lvl, props, "kenney/furniture-kit/kitchenstove", oo + b * Vector3(3.2, 0, 0.6) + Vector3(0, fy, 0), yaw - 90.0, 0.9)
	return {"door": oo + b * Vector3(0, fy, d * 0.5), "inside": oo + b * Vector3(0, fy, -0.5), "out": oo + b * Vector3(0, fy, d * 0.5 + 1.4), "floor": fy, "basis": b}
