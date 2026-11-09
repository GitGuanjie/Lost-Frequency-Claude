extends RefCounted
## Level 108 structures: Old Hereth (the restored Church of Rosmerta at the town
## centre and the overgrown footings of the rest of the village), New Hereth
## (the B.N.T.G. compound dug partly underground beside it: a sunken court,
## filtered halls, intake stacks, a watch platform and the perimeter fence) and
## the trail guides (teal toward the outpost, purple toward a known exit).

const LAND := preload("res://levels/L108/L108_land.gd")

var lv
var land
var k: GeoKit
var props: Node3D
var r := RandomNumberGenerator.new()
var spots := {}
var lamp_spots: Array = []       # [pos, color, energy, range, group]
var fy := 0.0                    # church floor


func _init(level, l, kit: GeoKit, prop_parent: Node3D) -> void:
	lv = level
	land = l
	k = kit
	props = prop_parent
	r.seed = 108030


static func materials() -> void:
	MatLib.define("l108_stone", {"albedo_a": Color(0.2, 0.19, 0.17), "albedo_b": Color(0.14, 0.135, 0.12), "pattern": 4,
		"pattern_scale": Vector2(0.6, 0.32), "grout_width": 0.035, "grout_color": Color(0.07, 0.07, 0.06), "bump_strength": 1.6,
		"stain_amount": 0.55, "stain_color": Color(0.05, 0.08, 0.03), "stain_scale": 0.8, "grime_height": 1.2, "grime_color": Color(0.04, 0.06, 0.025)}, "brick")
	MatLib.define("l108_slate", {"albedo_a": Color(0.07, 0.075, 0.08), "albedo_b": Color(0.05, 0.055, 0.06), "pattern": 14,
		"pattern_scale": Vector2(0.45, 0.22), "grout_width": 0.012, "grout_color": Color(0.02, 0.025, 0.02), "stain_amount": 0.5,
		"stain_color": Color(0.04, 0.07, 0.025), "roughness_a": 0.75}, "concrete")
	MatLib.define("l108_oak", {"albedo_a": Color(0.16, 0.1, 0.055), "albedo_b": Color(0.11, 0.07, 0.04), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.16), "grout_color": Color(0.04, 0.025, 0.015), "roughness_a": 0.7}, "wood_floor")
	MatLib.define("l108_flags", {"albedo_a": Color(0.17, 0.165, 0.15), "albedo_b": Color(0.12, 0.115, 0.1), "pattern": 14,
		"pattern_scale": Vector2(0.9, 0.7), "grout_width": 0.02, "grout_color": Color(0.05, 0.05, 0.045), "stain_amount": 0.4,
		"stain_color": Color(0.07, 0.07, 0.06)}, "concrete")
	MatLib.define("l108_plaster", {"albedo_a": Color(0.42, 0.39, 0.33), "albedo_b": Color(0.34, 0.31, 0.26), "stain_amount": 0.5,
		"stain_color": Color(0.2, 0.19, 0.14), "stain_scale": 1.4, "grime_height": 0.8, "grime_color": Color(0.12, 0.11, 0.08)}, "plaster")
	MatLib.define("l108_concrete", {"albedo_a": Color(0.2, 0.2, 0.19), "albedo_b": Color(0.15, 0.15, 0.145), "stain_amount": 0.65,
		"stain_color": Color(0.06, 0.08, 0.04), "stain_scale": 0.7, "grime_height": 1.4, "grime_color": Color(0.05, 0.07, 0.03), "wetness": 0.3}, "concrete")
	MatLib.define("l108_floor", {"albedo_a": Color(0.22, 0.22, 0.21), "albedo_b": Color(0.18, 0.18, 0.17), "pattern": 1,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.1, 0.1, 0.1), "stain_amount": 0.3,
		"stain_color": Color(0.1, 0.1, 0.09)}, "concrete")
	MatLib.define("l108_steel", {"albedo_a": Color(0.16, 0.17, 0.16), "albedo_b": Color(0.12, 0.13, 0.12), "metallic_value": 0.55,
		"stain_amount": 0.5, "stain_color": Color(0.1, 0.06, 0.03)}, "metal")
	MatLib.define("l108_teal", {"albedo_a": Color(0.0, 0.32, 0.3), "albedo_b": Color(0.0, 0.27, 0.26), "roughness_a": 0.6,
		"emission_color": Color(0.0, 0.08, 0.075), "emission_energy": 0.6}, "plaster")
	MatLib.define("l108_purple", {"albedo_a": Color(0.25, 0.03, 0.34), "albedo_b": Color(0.2, 0.02, 0.28), "roughness_a": 0.6,
		"emission_color": Color(0.06, 0.0, 0.09), "emission_energy": 0.6}, "plaster")
	MatLib.define("l108_post", {"albedo_a": Color(0.12, 0.09, 0.06), "albedo_b": Color(0.09, 0.07, 0.05), "pattern": 3,
		"pattern_scale": Vector2(0.2, 1.0)}, "wood_floor")
	MatLib.register("l108_lamp", MatLib.panel(Color(1.0, 0.85, 0.6), 2.2))
	MatLib.define("l108_sandbag", {"albedo_a": Color(0.3, 0.27, 0.18), "albedo_b": Color(0.25, 0.22, 0.14), "noise_scale": 3.0, "bump_strength": 1.2}, "plaster")
	var msh := Shader.new()
	msh.code = "shader_type spatial;\nrender_mode cull_disabled, depth_draw_opaque;\nvarying vec3 wp;\nvoid vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }\nvoid fragment() {\n\tvec2 u = vec2(wp.x + wp.z, wp.y) * 16.0;\n\tvec2 a = abs(fract(vec2(u.x + u.y, u.x - u.y) * 0.5) - 0.5);\n\tfloat w = 1.0 - smoothstep(0.06, 0.12, min(a.x, a.y));\n\tALBEDO = vec3(0.22, 0.23, 0.22);\n\tMETALLIC = 0.6;\n\tROUGHNESS = 0.5;\n\tALPHA = w * 0.9;\n\tALPHA_SCISSOR_THRESHOLD = 0.5;\n}\n"
	var mm := ShaderMaterial.new()
	mm.shader = msh
	MatLib.register("l108_mesh", mm)
	MatLib.register("l108_tube", MatLib.panel(Color(0.85, 0.95, 1.0), 2.6))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.5, 0.36, 0.12, 0.45)
	g.emission_enabled = true
	g.emission = Color(0.25, 0.15, 0.04)
	g.roughness = 0.2
	MatLib.register("l108_leaded", g)


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, col := false) -> Node3D:
	return Props.place(lv, props, id, pos, yaw, h, col)


func gy(x: float, z: float) -> float:
	return land.h(x, z)


# ------------------------------------------------------------------ church

## The Church of Rosmerta: a small stone nave (altar east), a west tower over
## the door, a timber gallery at the west end, records shelved along the north
## wall by the I.M.B.H. restorers.
func church() -> void:
	var x0 := -9.0
	var x1 := 7.0
	var hw := 4.0
	var wh := 5.2
	fy = 0.0
	for x in [x0 - 4.0, x0, 0.0, x1]:
		for z in [-hw, hw]:
			fy = maxf(fy, gy(x, z))
	fy += 0.45
	spots["church_floor"] = fy
	k.box_mm(Vector3(x0 - 4.2, fy - 2.0, -hw - 0.2), Vector3(x1 + 0.2, fy, hw + 0.2), "l108_stone")
	k.box_mm(Vector3(x0 + 0.3, fy - 0.02, -hw + 0.3), Vector3(x1 - 0.3, fy + 0.02, hw - 0.3), "l108_flags", GeoKit.PY)
	var win := func(at: float) -> Dictionary: return {"at": at, "w": 0.7, "h": 2.2, "sill": 1.8}
	k.wall(Vector3(x0, fy, -hw), Vector3(x1, fy, -hw), wh, 0.6, "l108_stone", [win.call(4.0), win.call(8.0), win.call(12.0)])
	k.wall(Vector3(x1, fy, hw), Vector3(x0, fy, hw), wh, 0.6, "l108_stone", [win.call(4.0), win.call(8.0), win.call(12.0)])
	k.wall(Vector3(x1, fy, -hw), Vector3(x1, fy, hw), wh, 0.6, "l108_stone", [{"at": 4.0, "w": 1.0, "h": 2.6, "sill": 2.2}])
	k.wall(Vector3(x0, fy, hw), Vector3(x0, fy, -hw), wh, 0.6, "l108_stone", [{"at": 4.0, "w": 1.6, "h": 2.6}])
	for zz in [-hw, hw]:
		for xx in [x1 - 4.0, x1 - 8.0, x1 - 12.0]:
			k.box(Vector3(xx, fy + 2.9, zz), Vector3(0.7, 2.2, 0.06), "l108_leaded", GeoKit.ALL, false)
	k.box(Vector3(x1, fy + 3.3, 0), Vector3(0.06, 2.6, 1.0), "l108_leaded", GeoKit.ALL, false)
	# gable ends and roof
	var rise := 3.0
	var run := hw + 0.5
	var ang := atan2(rise, run)
	var ln := sqrt(run * run + rise * rise)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), s * ang), Vector3((x0 + x1) * 0.5, fy + wh + rise * 0.5 + 0.12, s * run * 0.5)),
			Vector3(x1 - x0 + 0.9, 0.18, ln + 0.1), "l108_slate")
	for xx in [x1]:
		for i in 6:
			var t := float(i) / 6.0
			k.box(Vector3(xx, fy + wh + rise * (t + 1.0 / 12.0), 0), Vector3(0.6, rise / 6.0 + 0.01, (1.0 - t) * hw * 2.0), "l108_stone", GeoKit.ALL, false)
	for i in 4:
		var t := float(i) / 4.0
		k.box(Vector3((x0 + x1) * 0.5, fy + wh - 0.1, x0 + 1.0 + t * 0.0), Vector3(0.01, 0.01, 0.01), "l108_oak", GeoKit.ALL, false)
	for xx in [x0 + 2.0, x0 + 6.0, x0 + 10.0, x0 + 14.0]:
		k.box(Vector3(xx, fy + wh - 0.15, 0), Vector3(0.25, 0.3, hw * 2.0), "l108_oak", GeoKit.ALL, false)
	k.box(Vector3((x0 + x1) * 0.5, fy + wh + rise - 0.2, 0), Vector3(x1 - x0, 0.25, 0.25), "l108_oak", GeoKit.ALL, false)
	# west tower with the door through its base, a pyramid spire and a belfry
	var tx0 := x0 - 4.0
	var th := 12.5
	k.wall(Vector3(tx0, fy, -2.0), Vector3(x0, fy, -2.0), th, 0.5, "l108_stone", [{"at": 2.0, "w": 0.8, "h": 1.4, "sill": th - 2.6}])
	k.wall(Vector3(x0, fy, 2.0), Vector3(tx0, fy, 2.0), th, 0.5, "l108_stone", [{"at": 2.0, "w": 0.8, "h": 1.4, "sill": th - 2.6}])
	k.wall(Vector3(tx0, fy, 2.0), Vector3(tx0, fy, -2.0), th, 0.5, "l108_stone", [{"at": 2.0, "w": 1.5, "h": 2.5}])
	k.box_mm(Vector3(x0 - 0.3, fy + wh, -2.0), Vector3(x0 + 0.3, fy + th, 2.0), "l108_stone")
	k.box_mm(Vector3(tx0, fy - 0.02, -2.0), Vector3(x0, fy + 0.02, 2.0), "l108_flags", GeoKit.PY)
	for i in 7:
		var t := float(i) / 7.0
		var s := 2.4 * (1.0 - t) + 0.05
		k.box(Vector3(tx0 + 2.0, fy + th + 0.4 + t * 5.0, 0), Vector3(s * 2.0, 5.0 / 7.0 + 0.02, s * 2.0), "l108_slate", GeoKit.ALL, false)
	k.box(Vector3(tx0 + 2.0, fy + th + 5.9, 0), Vector3(0.08, 1.2, 0.08), "l108_steel", GeoKit.ALL, false)
	k.box(Vector3(tx0 + 2.0, fy + th + 6.1, 0), Vector3(0.08, 0.08, 0.6), "l108_steel", GeoKit.ALL, false)
	# entrance steps
	k.stairs(Vector3(tx0 - 2.2, gy(tx0 - 2.2, 0), 0), Vector3(1, 0, 0), 2.4, fy - gy(tx0 - 2.2, 0), 3, "l108_stone", 0.7)
	# gallery at the west end, reached by a stair along the south wall
	var gh := 2.9
	k.box_mm(Vector3(x0 + 0.3, fy + gh - 0.18, -hw + 0.3), Vector3(x0 + 3.4, fy + gh, hw - 0.3), "l108_oak")
	k.box(Vector3(x0 + 3.4, fy + gh + 0.5, -0.6), Vector3(0.08, 0.9, hw * 2.0 - 2.0), "l108_oak", GeoKit.ALL, true)
	for zz in range(-3, 3):
		k.box(Vector3(x0 + 3.4, fy + gh + 0.45, zz + 0.4), Vector3(0.06, 0.9, 0.06), "l108_oak", GeoKit.ALL, false)
	k.stairs(Vector3(x0 + 9.2, fy, hw - 1.0), Vector3(-1, 0, 0), 1.2, gh, 14, "l108_oak", 0.4)
	for xx in [x0 + 3.4, x0 + 1.0]:
		k.box(Vector3(xx, fy + gh * 0.5, -hw + 0.6), Vector3(0.22, gh, 0.22), "l108_oak", GeoKit.ALL, true)
	# pews, altar, rail
	for i in 6:
		var xx := x0 + 4.6 + i * 1.3
		if xx > x1 - 3.5:
			break
		for s in [-1.0, 1.0]:
			var zc: float = s * 2.1
			if s > 0.0 and xx > x0 + 4.2 and xx < x0 + 9.4:
				zc = 1.7
			k.box(Vector3(xx, fy + 0.45, zc), Vector3(0.4, 0.06, 2.2 if s < 0 else 1.6), "l108_oak", GeoKit.ALL, false)
			k.box(Vector3(xx - 0.22, fy + 0.75, zc), Vector3(0.06, 0.65, 2.2 if s < 0 else 1.6), "l108_oak", GeoKit.ALL, false)
			k.box(Vector3(xx, fy + 0.22, zc), Vector3(0.36, 0.44, 0.06), "l108_oak", 0, true)
	k.box(Vector3(x1 - 1.4, fy + 0.5, 0), Vector3(1.0, 1.0, 2.4), "l108_stone")
	k.box(Vector3(x1 - 1.4, fy + 1.03, 0), Vector3(1.1, 0.06, 2.5), "l108_flags", GeoKit.ALL, false)
	k.box(Vector3(x1 - 3.0, fy + 0.5, -1.6), Vector3(0.1, 1.0, 1.6), "l108_oak", GeoKit.ALL, false)
	k.box(Vector3(x1 - 3.0, fy + 0.5, 1.6), Vector3(0.1, 1.0, 1.6), "l108_oak", GeoKit.ALL, false)
	# the All-Mother's niche: a carved panel of interlocking circles above the altar
	k.box(Vector3(x1 - 0.32, fy + 3.0, 0), Vector3(0.06, 1.8, 1.4), "l108_plaster", GeoKit.ALL, false)
	for i in 5:
		var a := TAU * i / 5.0
		k.cylinder(Vector3(x1 - 0.36, fy + 3.0 + sin(a) * 0.38, cos(a) * 0.38), 0.24, 0.02, "l108_stone", 10, false)
	p("ph/lantern_chandelier_01", Vector3(x1 - 1.4, fy + 1.06, -0.8), 0.0, 0.45)
	p("ph/lantern_chandelier_01", Vector3(x1 - 1.4, fy + 1.06, 0.8), 0.0, 0.45)
	# the restorers: shelved records, crates, a work table, lamps
	for i in 4:
		p("ph/wooden_bookshelf_worn", Vector3(x0 + 5.0 + i * 1.45, fy, -hw + 0.62), 0.0, 0.0, true)
	p("ph/metal_office_desk", Vector3(x0 + 11.2, fy, hw - 1.2), 180.0, 0.0, true)
	p("ph/binder_notebook", Vector3(x0 + 11.0, fy + 0.8, hw - 1.25), 12.0)
	p("ph/clipboard", Vector3(x0 + 11.6, fy + 0.8, hw - 1.1), -20.0)
	p("ph/vintage_flashlight", Vector3(x0 + 10.6, fy + 0.8, hw - 1.4), 70.0)
	p("ph/old_military_crate", Vector3(x0 + 1.6, fy, -hw + 1.0), 90.0, 0.0, true)
	p("ph/cardboard_box_01", Vector3(x0 + 1.4, fy, -hw + 2.3), 15.0)
	p("ph/cardboard_box_01", Vector3(x0 + 1.5, fy + 0.34, -hw + 2.2), 40.0)
	p("ph/caged_hanging_light", Vector3(x0 + 6.0, fy + wh - 0.9, 0), 90.0)
	p("ph/caged_hanging_light", Vector3(x0 + 11.0, fy + wh - 0.9, 0), 90.0)
	lamp_spots.append([Vector3(x0 + 6.0, fy + wh - 1.2, 0), Color(1.0, 0.8, 0.55), 2.6, 9.0, "church"])
	lamp_spots.append([Vector3(x0 + 11.5, fy + wh - 1.2, 0), Color(1.0, 0.8, 0.55), 2.6, 9.0, "church"])
	lamp_spots.append([Vector3(x1 - 1.6, fy + 1.6, 0), Color(1.0, 0.65, 0.3), 1.6, 5.0, "church"])
	spots["diary"] = Vector3(x0 + 11.3, fy + 0.82, hw - 1.0)
	spots["records"] = Vector3(x0 + 7.0, fy + 1.2, -hw + 0.9)
	spots["altar"] = Vector3(x1 - 1.4, fy + 1.1, 0)
	spots["gallery"] = Vector3(x0 + 1.8, fy + gh, 0)
	spots["church_door"] = Vector3(tx0 - 3.0, gy(tx0 - 3.0, 0), 0)


## Overgrown footings of the vanished village around the church.
func ruins() -> void:
	var list := [[Vector2(-26, -22), 0.3], [Vector2(-34, 8), 1.4], [Vector2(-22, 30), -0.5], [Vector2(4, 32), 0.15],
		[Vector2(8, -30), -0.25], [Vector2(-8, -40), 0.6], [Vector2(18, 26), 0.9]]
	for e in list:
		var c: Vector2 = e[0]
		var yaw: float = e[1]
		var bas := Basis(Vector3.UP, yaw)
		var y0: float = gy(c.x, c.y) - 0.1
		var o := Vector3(c.x, y0, c.y)
		var w := r.randf_range(5.0, 7.0)
		var d := r.randf_range(4.0, 5.5)
		var corners := [Vector3(-w, 0, -d) * 0.5, Vector3(w, 0, -d) * 0.5, Vector3(w, 0, d) * 0.5, Vector3(-w, 0, d) * 0.5]
		for i in 4:
			var a: Vector3 = o + bas * corners[i]
			var b: Vector3 = o + bas * corners[(i + 1) % 4]
			var segs := 3
			for sgi in segs:
				var t0 := float(sgi) / segs
				var t1 := float(sgi + 1) / segs
				var hh := r.randf_range(0.3, 2.2) if r.randf() < 0.8 else 0.0
				if hh <= 0.0:
					continue
				var pa := a.lerp(b, t0)
				var pb := a.lerp(b, t1)
				k.wall(pa, pb, hh, 0.45, "l108_stone")
		# rubble and the forest taking it back
		for j in 3:
			p(["kenney/graveyard-kit/debris", "kenney/graveyard-kit/debris-wood"][j % 2], o + bas * Vector3(r.randf_range(-w, w) * 0.4, 0.0, r.randf_range(-d, d) * 0.4),
				r.randf_range(0, 360), r.randf_range(0.25, 0.45))
	spots["ruin"] = Vector3(-26, gy(-26, -22), -22)


# ------------------------------------------------------------------ New Hereth

func compound() -> void:
	var px: float = LAND.PIT.position.x
	var pz: float = LAND.PIT.position.y
	var pw: float = LAND.PIT.size.x
	var pd: float = LAND.PIT.size.y
	var fl: float = LAND.PIT_FLOOR
	var top := 3.6
	# retaining walls round the sunken court (gap on the west for the ramp)
	k.box_mm(Vector3(px - 0.5, fl - 0.3, pz - 0.5), Vector3(px + pw + 0.5, top, pz), "l108_concrete")
	k.box_mm(Vector3(px - 0.5, fl - 0.3, pz + pd), Vector3(px + pw + 0.5, top, pz + pd + 0.5), "l108_concrete")
	k.box_mm(Vector3(px - 0.5, fl - 0.3, pz), Vector3(px, top, pz + 7.0), "l108_concrete")
	k.box_mm(Vector3(px - 0.5, fl - 0.3, pz + 13.0), Vector3(px, top, pz + pd), "l108_concrete")
	# east wall: the blast door into the halls
	k.wall(Vector3(px + pw, fl, pz + pd), Vector3(px + pw, fl, pz), top - fl, 0.6, "l108_concrete", [{"at": 11.0, "w": 2.4, "h": 2.6}])
	k.box_mm(Vector3(px, fl - 0.2, pz), Vector3(px + pw, fl, pz + pd), "l108_floor", GeoKit.PY)
	# ramp side walls
	for zz in [pz + 7.0, pz + 13.0]:
		for i in 6:
			var x := px - 18.0 + i * 3.0
			var g0: float = gy(x + 1.5, zz)
			k.box_mm(Vector3(x, g0 - 1.0, zz - 0.25), Vector3(x + 3.0, maxf(g0 + 0.9, fl + 1.0), zz + 0.25), "l108_concrete")
	# the halls under the turf
	var hx0 := px + pw + 0.3
	var hx1 := hx0 + 22.0
	var hz0 := pz + 2.0
	var hz1 := pz + pd - 2.0
	var ch := fl + 3.2
	k.box_mm(Vector3(hx0, fl - 0.3, hz0), Vector3(hx1, fl, hz1), "l108_floor")
	k.box_mm(Vector3(hx0, ch, hz0), Vector3(hx1, ch + 0.4, hz1), "l108_concrete")
	k.wall(Vector3(hx0, fl, hz0), Vector3(hx1, fl, hz0), 3.2, 0.4, "l108_concrete")
	k.wall(Vector3(hx1, fl, hz1), Vector3(hx0, fl, hz1), 3.2, 0.4, "l108_concrete")
	k.wall(Vector3(hx1, fl, hz0), Vector3(hx1, fl, hz1), 3.2, 0.4, "l108_concrete")
	# partition: corridor along the south, rooms to the north
	var mz := hz0 + 7.0
	k.wall(Vector3(hx0, fl, mz), Vector3(hx1, fl, mz), 3.2, 0.2, "l108_plaster", [{"at": 4.5, "w": 1.2, "h": 2.2}, {"at": 12.0, "w": 1.2, "h": 2.2}, {"at": 18.5, "w": 1.2, "h": 2.2}])
	k.wall(Vector3(hx0 + 8.5, fl, hz0), Vector3(hx0 + 8.5, fl, mz), 3.2, 0.2, "l108_plaster")
	k.wall(Vector3(hx0 + 15.5, fl, hz0), Vector3(hx0 + 15.5, fl, mz), 3.2, 0.2, "l108_plaster")
	for i in 5:
		var x := hx0 + 2.0 + i * 4.5
		k.box(Vector3(x, ch - 0.03, (mz + hz1) * 0.5), Vector3(1.2, 0.04, 0.3), "l108_tube", GeoKit.NY, false)
		lv.lights.add_anchor(Vector3(x, ch - 0.5, (mz + hz1) * 0.5), Color(0.85, 0.95, 1.0), 1.6, 6.0, 0.0, "halls")
	for x in [hx0 + 4.2, hx0 + 12.0, hx0 + 18.8]:
		k.box(Vector3(x, ch - 0.03, (hz0 + mz) * 0.5), Vector3(1.2, 0.04, 0.3), "l108_tube", GeoKit.NY, false)
		lv.lights.add_anchor(Vector3(x, ch - 0.5, (hz0 + mz) * 0.5), Color(0.85, 0.95, 1.0), 1.4, 5.5, 0.0, "halls")
	p("ph/modular_airduct_rectangular_01", Vector3((hx0 + hx1) * 0.5, ch - 1.3, hz1 - 1.6), 0.0, 1.0)
	# B.N.T.G. medicinal research room (west), U.E.C. watch room (middle), I.M.B.H. archive (east)
	var lab := Vector3(hx0 + 4.2, fl, (hz0 + mz) * 0.5)
	p("ph/metal_office_desk", lab + Vector3(0, 0, -1.8), 0.0, 0.0, true)
	p("ph/steel_frame_shelves_02", lab + Vector3(-3.4, 0, -2.6), 90.0, 0.0, true)
	p("ph/steel_frame_shelves_02", lab + Vector3(-3.4, 0, -1.9), 90.0, 0.0, true)
	for i in 6:
		p(["ph/plastic_crate_01", "ph/medical_box", "ph/plastic_bottle_gallon"][i % 3], lab + Vector3(-0.8 + i * 0.32, 0.79, -1.85), r.randf_range(-30, 30))
	p("ph/SchoolChair_01", lab + Vector3(0.2, 0, -0.9), 180.0)
	var watch := Vector3(hx0 + 12.0, fl, (hz0 + mz) * 0.5)
	p("ph/metal_office_desk", watch + Vector3(0, 0, -1.8), 0.0, 0.0, true)
	p("ph/Television_01", watch + Vector3(-0.5, 0.79, -1.9), 0.0)
	p("ph/Television_01", watch + Vector3(0.3, 0.79, -1.9), -8.0)
	p("ph/vintage_radio_transceiver", watch + Vector3(0.75, 0.79, -1.8), -20.0)
	p("ph/korean_fire_extinguisher_01", watch + Vector3(3.0, 0, 2.6), 180.0)
	var arch := Vector3(hx0 + 18.8, fl, (hz0 + mz) * 0.5)
	for i in 3:
		p("ph/steel_frame_shelves_02", arch + Vector3(-2.0 + i * 0.7, 0, -2.7), 0.0, 0.0, true)
	p("ph/old_military_crate", arch + Vector3(0.5, 0, 1.2), 90.0, 0.0, true)
	p("ph/binder_notebook", arch + Vector3(0.5, 0.31, 1.2), 30.0)
	# corridor: respirator rack and filter boxes by the blast door
	var rack := Vector3(hx0 + 2.0, fl, hz1 - 0.5)
	k.box(rack + Vector3(0, 1.4, 0), Vector3(1.8, 1.0, 0.08), "l108_steel", GeoKit.ALL, false)
	for i in 5:
		p("ph/medical_box", rack + Vector3(-0.7 + i * 0.35, 0.9, -0.1), 0.0)
	p("ph/portable_generator", Vector3(hx1 - 1.2, fl, hz1 - 1.0), 90.0, 0.0, true)
	spots["rack"] = rack + Vector3(0, 1.3, -0.35)
	spots["lab"] = lab + Vector3(0, 0.82, -1.7)
	spots["watch"] = watch + Vector3(0, 0.82, -1.7)
	spots["archive"] = arch + Vector3(0.5, 0.35, 1.2)
	spots["hall_in"] = Vector3(hx0 + 4.0, fl, hz1 - 2.0)
	# the court: lights, crates, the door frame and the board
	p("ph/rollershutter_door", Vector3(px + pw - 0.35, fl, pz + 11.0), -90.0)
	p("ph/security_light", Vector3(px + pw - 0.3, fl + 3.2, pz + 8.6), -90.0)
	lamp_spots.append([Vector3(px + pw - 1.2, fl + 2.8, pz + 11.0), Color(1.0, 0.9, 0.7), 2.4, 12.0, "court"])
	for i in 5:
		p(["ph/wooden_crate_01", "ph/barrel_03", "ph/old_military_crate"][i % 3], Vector3(px + 2.0 + i * 1.3, fl, pz + 1.2), r.randf_range(-20, 20), 0.0, true)
	p("ph/hand_truck", Vector3(px + 9.0, fl, pz + 2.0), 30.0)
	# the court as the outpost's yard: tables, sample crates, sandbags, lamps
	p("ph/wooden_picnic_table", Vector3(px + 8.0, fl, pz + 17.0), 90.0, 0.0, true)
	p("ph/wooden_picnic_table", Vector3(px + 13.0, fl, pz + 17.5), 80.0, 0.0, true)
	p("ph/plastic_monobloc_chair_01", Vector3(px + 10.5, fl, pz + 19.5), 160.0)
	p("ph/portable_generator", Vector3(px + pw - 2.0, fl, pz + 3.0), 0.0, 0.0, true)
	p("ph/propane_tank", Vector3(px + pw - 3.2, fl, pz + 2.4), 0.0)
	for i in 6:
		p("ph/plastic_crate_01", Vector3(px + 18.0 + (i % 3) * 0.45, fl + int(i / 3) * 0.27, pz + 19.8), 0.0)
	for i in 7:
		k.box(Vector3(px + pw - 1.0, fl + 0.2 + (i % 2) * 0.32, pz + 4.5 + i * 0.9), Vector3(0.55, 0.3, 0.85), "l108_sandbag", GeoKit.ALL, false)
	for xx in [px + 6.0, px + 16.0]:
		p("ph/industrial_wall_lamp", Vector3(xx, fl + 2.6, pz + pd - 0.15), 180.0)
		lamp_spots.append([Vector3(xx, fl + 2.3, pz + pd - 1.0), Color(1.0, 0.85, 0.6), 1.6, 8.0, "court"])
	p("ph/WetFloorSign_01", Vector3(px + pw - 3.0, fl, pz + 9.0), 30.0)
	p("ph/korean_fire_extinguisher_01", Vector3(px + pw - 0.5, fl, pz + 13.6), -90.0)
	var sign := Label3D.new()
	sign.text = "FILTERED ZONE\nDOOR SHUT AT ALL TIMES"
	sign.font_size = 36
	sign.pixel_size = 0.006
	sign.modulate = Color(0.9, 0.75, 0.2)
	sign.shaded = true
	sign.position = Vector3(px + pw - 0.32, fl + 3.0, pz + 11.0)
	sign.rotation.y = -PI * 0.5
	props.add_child(sign)
	spots["court"] = Vector3(px + 10.0, fl, pz + 10.0)
	spots["gate"] = Vector3(px - 20.0, gy(px - 20.0, pz + 10.0), pz + 10.0)
	# surface: intake stacks over the halls, units, a watch platform, cameras, fence
	for i in 3:
		var sx := hx0 + 5.0 + i * 6.0
		var sz := hz0 + 3.0
		var g0: float = gy(sx, sz)
		k.box(Vector3(sx, g0 + 1.6, sz), Vector3(1.4, 3.6, 1.4), "l108_concrete")
		k.box(Vector3(sx, g0 + 3.6, sz), Vector3(1.8, 0.5, 1.8), "l108_steel", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(Vector3(sx + s * 0.71, g0 + 2.6, sz), Vector3(0.04, 0.9, 1.0), "l108_steel", GeoKit.ALL, false)
	p("ph/exterior_aircon_unit", Vector3(hx0 + 6.0, gy(hx0 + 6.0, hz1 - 1.0), hz1 - 1.0), 0.0, 0.0, true)
	p("ph/exterior_aircon_unit", Vector3(hx0 + 10.0, gy(hx0 + 10.0, hz1 - 1.0), hz1 - 1.0), 0.0, 0.0, true)
	p("ph/modular_industrial_pipes_01", Vector3(hx0 + 14.0, gy(hx0 + 14.0, hz1 - 0.8), hz1 - 0.8), 0.0)
	var tw := Vector3(px + pw + 8.0, 0, pz - 8.0)
	tw.y = gy(tw.x, tw.z)
	var ph := 4.6
	for dx in [-1.4, 1.4]:
		for dz in [-1.4, 1.4]:
			k.box(tw + Vector3(dx, ph * 0.5 + 0.2, dz), Vector3(0.2, ph + 1.4, 0.2), "l108_steel")
	k.box_mm(tw + Vector3(-1.8, ph - 0.15, -1.8), tw + Vector3(1.8, ph, 1.8), "l108_steel")
	for s in [-1.0, 1.0]:
		k.box(tw + Vector3(s * 1.75, ph + 0.55, 0), Vector3(0.06, 1.0, 3.5), "l108_steel", GeoKit.ALL, true)
	k.box(tw + Vector3(0, ph + 0.55, -1.75), Vector3(3.5, 1.0, 0.06), "l108_steel", GeoKit.ALL, true)
	k.stairs(tw + Vector3(-0.6, 0.0, 1.8 + ph / 0.3 * 0.3 * 0.0 + 6.4), Vector3(0, 0, -1), 1.1, ph, 18, "l108_steel", 0.36)
	k.box_mm(tw + Vector3(-1.2, 0.0, 1.6), tw + Vector3(0.0, ph, 1.9), "l108_steel", GeoKit.ALL, false)
	p("ph/security_light", tw + Vector3(1.6, ph + 1.1, -1.6), 135.0)
	p("ph/security_camera_01", tw + Vector3(-1.6, ph + 1.1, -1.6), -135.0)
	lamp_spots.append([tw + Vector3(0, ph + 1.8, 0), Color(1.0, 0.92, 0.75), 3.0, 18.0, "court"])
	spots["tower_top"] = tw + Vector3(0, ph, 0)
	# perimeter fence (gate gap on the ramp)
	var fx0 := px - 22.0
	var fx1 := hx1 + 6.0
	var fz0 := pz - 14.0
	var fz1 := pz + pd + 10.0
	var runs := [[Vector2(fx0, fz0), Vector2(fx1, fz0)], [Vector2(fx1, fz0), Vector2(fx1, fz1)], [Vector2(fx1, fz1), Vector2(fx0, fz1)],
		[Vector2(fx0, fz1), Vector2(fx0, pz + 13.5)], [Vector2(fx0, pz + 6.5), Vector2(fx0, fz0)]]
	for run2 in runs:
		var a: Vector2 = run2[0]
		var b: Vector2 = run2[1]
		var n := maxi(1, int(a.distance_to(b) / 3.0))
		for i in n + 1:
			var c := a.lerp(b, float(i) / n)
			var g0: float = gy(c.x, c.y)
			k.box(Vector3(c.x, g0 + 1.1, c.y), Vector3(0.09, 2.6, 0.09), "l108_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.5), Vector3(c.x, g0 + 2.45, c.y)), Vector3(0.05, 0.5, 0.05), "l108_steel", GeoKit.ALL, false)
		var mid := (a + b) * 0.5
		var ln := a.distance_to(b)
		var yaw := atan2(-(b.y - a.y), b.x - a.x)
		var g1: float = gy(mid.x, mid.y)
		var bas := Basis(Vector3.UP, yaw)
		k.box_xf(Transform3D(bas, Vector3(mid.x, g1 + 1.15, mid.y)), Vector3(ln, 2.2, 0.03), "l108_mesh", GeoKit.ALL, true)
		k.box_xf(Transform3D(bas, Vector3(mid.x, g1 + 2.3, mid.y)), Vector3(ln, 0.05, 0.05), "l108_steel", GeoKit.ALL, false)
		for wy in [2.5, 2.62]:
			k.box_xf(Transform3D(bas, Vector3(mid.x, g1 + wy, mid.y + 0.12)), Vector3(ln, 0.015, 0.015), "l108_steel", GeoKit.ALL, false)
	var gp := Vector3(fx0, 0, pz + 10.0)
	gp.y = gy(gp.x, gp.z)
	for s in [-1.0, 1.0]:
		k.box(gp + Vector3(0, 1.3, s * 3.6), Vector3(0.4, 2.6, 0.4), "l108_concrete")
	p("ph/security_camera_01", gp + Vector3(0, 2.6, 3.6), -90.0)
	var board := Label3D.new()
	board.text = "NEW HERETH\nB.N.T.G.  -  U.E.C.  -  I.M.B.H.\nFILTERS ON PAST THIS POINT"
	board.font_size = 40
	board.pixel_size = 0.006
	board.modulate = Color(0.85, 0.85, 0.8)
	board.position = gp + Vector3(-0.25, 2.2, -3.6)
	board.rotation.y = -PI * 0.5
	board.shaded = true
	props.add_child(board)
	k.box(gp + Vector3(-0.2, 2.2, -3.6), Vector3(0.06, 0.8, 2.2), "l108_steel", GeoKit.ALL, false)
	spots["gate_out"] = gp + Vector3(-4.0, 0, 0)


# ------------------------------------------------------------------ trail guides

## A guide post: a stake with a painted band and a strip of cloth.
func guide(pos: Vector3, mat: String, yaw: float) -> void:
	k.box(pos + Vector3(0, 0.65, 0), Vector3(0.1, 1.3, 0.1), "l108_post", GeoKit.ALL, false)
	k.box(pos + Vector3(0, 1.15, 0), Vector3(0.115, 0.22, 0.115), mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3(0, 0, 1), 0.25), pos + Vector3(0.12, 1.0, 0)), Vector3(0.05, 0.42, 0.06), mat, GeoKit.ALL, false)


func trail(pts: Array, mat: String, spacing: float) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var n := maxi(1, int(Vector2(b.x - a.x, b.z - a.z).length() / spacing))
		for j in n:
			var c := a.lerp(b, float(j) / n) + Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-0.6, 0.6))
			c.y = gy(c.x, c.z) - 0.05
			guide(c, mat, atan2(b.x - a.x, b.z - a.z))


## The known exit the purple guides end at: two marked posts between fallen boles.
func exit_gate(c: Vector3, dir: Vector3) -> void:
	var side := Vector3(-dir.z, 0, dir.x)
	for s in [-1.0, 1.0]:
		var q: Vector3 = c + side * 1.6 * s
		q.y = gy(q.x, q.z)
		k.box(q + Vector3(0, 1.1, 0), Vector3(0.16, 2.2, 0.16), "l108_post")
		for j in 3:
			k.box_xf(Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z) + j) * Basis(Vector3(0, 0, 1), 0.2 * (j - 1)), q + Vector3(0, 1.9 - j * 0.25, 0)),
				Vector3(0.08, 0.5, 0.05), "l108_purple", GeoKit.ALL, false)
		var lg: Vector3 = c + side * 4.2 * s - dir * 1.5
		lg.y = gy(lg.x, lg.z) + 0.2
		p("ph/dead_tree_trunk", lg, rad_to_deg(atan2(dir.x, dir.z)) + 90.0 + s * 12.0, 0.9, true)
