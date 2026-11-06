extends RefCounted
## Level 906 rooms: Blanche's office (the entry point), the Tea Room and the
## guest room she gives you, plus the figures (Blanche, the plush of Captain).
## Contents follow the page's lists; layouts, finishes and props that the page
## does not list are ADAPTATION.

const K := preload("res://levels/L906/L906_kit.gd")
const TEA := Vector3(15.4, 0.0, 15.6)        # tea table centre
const ROOM_C := Vector3(16.4, 4.5, 16.4)     # player's guest room centre (SE, gallery level)
const LIGHT := Color(1.0, 0.7, 0.4)

var L: Node3D
var room_node: Node3D
var room_style := ""
var flicker_book: MeshInstance3D


func _init(level: Node3D) -> void:
	L = level


static func prim(parent: Node3D, mesh: Mesh, pos: Vector3, mat: String, scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.scale = scl
	m.rotation = rot
	m.material_override = MatLib.get_mat(mat)
	parent.add_child(m)
	return m


static func sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


static func cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 18
	return c


static func cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	return c


## Blanche (page: short, pale, long blonde hair, light blue eyes, an intricate
## tea gown). Built from primitives; faces local -Z.
static func blanche(parent: Node3D) -> Node3D:
	var b := Node3D.new()
	b.name = "Blanche"
	parent.add_child(b)
	prim(b, cyl(0.16, 0.41, 0.86), Vector3(0, 0.43, 0), "l906_gown")
	prim(b, cyl(0.42, 0.44, 0.08), Vector3(0, 0.04, 0), "l906_lace")
	prim(b, cyl(0.19, 0.35, 0.46), Vector3(0, 0.64, 0.0), "l906_gown", Vector3(1.0, 1.0, 1.05))
	prim(b, cyl(0.36, 0.37, 0.05), Vector3(0, 0.42, 0), "l906_lace")
	prim(b, cyl(0.152, 0.152, 0.05), Vector3(0, 0.86, 0), "l906_velvet")
	prim(b, cyl(0.13, 0.12, 0.36), Vector3(0, 1.04, 0), "l906_gown")
	prim(b, sph(0.14), Vector3(0, 1.19, 0), "l906_gown", Vector3(1.12, 0.5, 0.8))
	prim(b, cyl(0.07, 0.1, 0.05), Vector3(0, 1.265, 0), "l906_lace")
	for s: float in [-1.0, 1.0]:
		prim(b, sph(0.066), Vector3(s * 0.165, 1.18, 0), "l906_gown")
		prim(b, cap(0.032, 0.44), Vector3(s * 0.19, 0.97, -0.05), "l906_gown", Vector3.ONE, Vector3(-0.25, 0, s * 0.12))
		prim(b, sph(0.033), Vector3(s * 0.17, 0.76, -0.12), "l906_skin")
		prim(b, sph(0.011), Vector3(s * 0.032, 1.426, -0.082), "l906_eye")
		prim(b, cap(0.024, 0.36), Vector3(s * 0.078, 1.3, -0.035), "l906_hair", Vector3.ONE, Vector3(0, 0, s * -0.08))
	prim(b, cyl(0.037, 0.037, 0.08), Vector3(0, 1.3, 0), "l906_skin")
	prim(b, sph(0.092), Vector3(0, 1.415, 0), "l906_skin", Vector3(0.92, 1.08, 0.98))
	prim(b, sph(0.1), Vector3(0, 1.445, 0.03), "l906_hair", Vector3(1.04, 1.0, 1.0))
	prim(b, cap(0.095, 0.74), Vector3(0, 1.12, 0.075), "l906_hair", Vector3(1.18, 1.0, 0.55))
	prim(b, sph(0.03), Vector3(0, 1.3, 0.06), "l906_velvet", Vector3(2.0, 1.0, 1.0))
	return b


func build_office() -> void:
	var k: GeoKit = L.kit("Office")
	var x0 := -4.5
	var x1 := 4.5
	var z0 := 2.5
	var z1 := 10.0
	K.shelves(k, Vector3(x0, 0, z0), Vector3(-1.15, 0, z0), 0.5, 8, Vector3(0, 0, 1), true)
	K.shelves(k, Vector3(1.15, 0, z0), Vector3(x1, 0, z0), 0.5, 8, Vector3(0, 0, 1), true)
	K.shelves(k, Vector3(x0, 0, z1), Vector3(x1, 0, z1), 0.5, 8, Vector3(0, 0, 1), true)
	K.shelves(k, Vector3(x0, 0, z0), Vector3(x0, 0, z1), 0.5, 8, Vector3(1, 0, 0), true)
	K.shelves(k, Vector3(x1, 0, z0), Vector3(x1, 0, 4.9), 0.5, 8, Vector3(1, 0, 0), true)
	K.shelves(k, Vector3(x1, 0, 7.1), Vector3(x1, 0, z1), 0.5, 8, Vector3(1, 0, 0), true)
	# arched openings (north towards the stair, east towards the tea room)
	for o in [[Vector3(0, 0, z0), Vector3(1, 0, 0), 1.15], [Vector3(x1, 0, 6.0), Vector3(0, 0, 1), 1.1]]:
		var c: Vector3 = o[0]
		var ax: Vector3 = o[1]
		var hw: float = o[2]
		for s: float in [-1.0, 1.0]:
			k.box(c + ax * (s * hw) + Vector3.UP * 1.5, ax.abs() * 0.22 + (Vector3.ONE - ax.abs() - Vector3.UP) * 0.62 + Vector3.UP * 3.0, "l906_wood")
		k.box(c + Vector3.UP * 2.85, ax.abs() * (hw * 2.0 + 0.22) + (Vector3.ONE - ax.abs() - Vector3.UP) * 0.62 + Vector3.UP * 0.3, "l906_wood", GeoKit.ALL, false)
		k.box(c + Vector3.UP * 3.18, ax.abs() * (hw * 2.0 + 0.5) + (Vector3.ONE - ax.abs() - Vector3.UP) * 0.7 + Vector3.UP * 0.36, "l906_gilt", GeoKit.ALL, false)
	# rug
	k.box_mm(Vector3(-3.9, 0, 3.1), Vector3(3.9, 0.014, 9.4), "l906_carpet_rug", GeoKit.PY, false)
	for e in [[Vector3(-4.0, 0, 3.0), Vector3(4.0, 0.016, 3.1)], [Vector3(-4.0, 0, 9.4), Vector3(4.0, 0.016, 9.5)],
			[Vector3(-4.0, 0, 3.0), Vector3(-3.9, 0.016, 9.5)], [Vector3(3.9, 0, 3.0), Vector3(4.0, 0.016, 9.5)]]:
		k.box_mm(e[0], e[1], "l906_carpet_edge", GeoKit.PY, false)
	# the desk: writing, reading, waiting for guests
	var d := Vector3(-2.3, 0, 4.25)
	k.box(d + Vector3(0, 0.765, 0), Vector3(1.9, 0.05, 0.95), "l906_wood")
	k.box(d + Vector3(0, 0.79, 0.475), Vector3(1.9, 0.012, 0.012), "l906_gilt", GeoKit.ALL, false)
	for s: float in [-1.0, 1.0]:
		k.box(d + Vector3(s * 0.62, 0.37, 0), Vector3(0.6, 0.74, 0.88), "l906_wood")
		for t in 3:
			k.box(d + Vector3(s * 0.62, 0.15 + t * 0.22, 0.445), Vector3(0.5, 0.18, 0.01), "l906_panel", GeoKit.PZ, false)
			k.box(d + Vector3(s * 0.62, 0.17 + t * 0.22, 0.455), Vector3(0.06, 0.02, 0.02), "l906_brass", GeoKit.ALL, false)
	K.chair(k, d + Vector3(0, 0, -0.85), Vector3(0, 0, 1))
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.2), d + Vector3(0.2, 0.795, 0.08)), Vector3(0.26, 0.012, 0.34), "paper", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.2), d + Vector3(0.46, 0.795, 0.14)), Vector3(0.26, 0.012, 0.34), "paper", GeoKit.ALL, false)
	k.cylinder(d + Vector3(0.75, 0.82, -0.2), 0.03, 0.06, "l906_iron", 8, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.7), d + Vector3(0.79, 0.9, -0.2)), Vector3(0.006, 0.2, 0.02), "l906_lace", GeoKit.ALL, false)
	K.candlestick(k, d + Vector3(-0.65, 0.79, -0.25), 3, 0.3)
	K.stack(k, d + Vector3(-0.3, 0.79, -0.25), L.rng, 5)
	L.lights.add_anchor(d + Vector3(-0.65, 1.3, -0.25), LIGHT, 1.1, 5.5, 0.08)
	L.add_note("l906_comfort", "An unfinished manuscript", "Blanche's Guide To Comfort Food, in her own hand, unfinished. A chapter on what to bake for an afternoon tea is half drafted; the last line stops mid-sentence and the ink beside it is still wet.", d + Vector3(0.3, 0.83, 0.1), Vector3(0.6, 0.1, 0.4), false)
	# Colombina mask on a stand at the end of the desk
	var mp := d + Vector3(0.82, 0.79, 0.25)
	k.cylinder(mp + Vector3.UP * 0.12, 0.012, 0.24, "l906_brass", 6, false)
	var mn := Node3D.new()
	mn.position = mp + Vector3.UP * 0.3
	mn.rotation.y = 0.5
	L.add_child(mn)
	for s: float in [-1.0, 1.0]:
		prim(mn, sph(0.06), Vector3(s * 0.05, 0, 0), "l906_gilt", Vector3(1.0, 0.62, 0.35))
		prim(mn, sph(0.018), Vector3(s * 0.045, 0.004, -0.02), "unlit_black", Vector3(1.4, 0.7, 0.5))
	prim(mn, sph(0.035), Vector3(0, 0.05, 0), "l906_lace", Vector3(2.6, 0.6, 0.3))
	L.add_note("l906_mask", "A Colombina mask", "A Colombina mask: a gilded half-mask for the eyes, set on a little brass stand at the end of her desk.", mp + Vector3.UP * 0.3, Vector3(0.3, 0.3, 0.3), false)
	# portrait on an easel, signed A.River
	var ep := Vector3(-3.75, 0, 7.2)
	for t in [[-0.3, -0.12], [0.3, -0.12], [0.0, 0.3]]:
		k.box(ep + Vector3(t[1], 0.85, t[0]), Vector3(0.04, 1.7, 0.04), "l906_wood", GeoKit.ALL, false)
	k.box(ep + Vector3(0.0, 0.88, 0), Vector3(0.08, 0.04, 0.9), "l906_wood", GeoKit.ALL, false)
	K.painting(k, ep + Vector3(0.02, 1.55, 0), Vector3(1, 0, 0), 0.72, 0.98, "l906_portrait")
	L.add_note("l906_portrait", "A portrait of Blanche", "A portrait of Blanche, drawn and signed by A.River. Pale face, long blonde hair, light blue eyes, the lace of a tea gown at the collar.", ep + Vector3(0.1, 1.5, 0), Vector3(0.2, 1.1, 0.9), false)
	# armchair with the life-sized plush of Captain
	var ap := Vector3(-3.3, 0, 9.0)
	var f := Vector3(1, 0, -1).normalized()
	K.chair(k, ap, f, "l906_velvet")
	var pl := Node3D.new()
	pl.position = ap + Vector3.UP * 0.5
	pl.rotation.y = atan2(-f.x, -f.z)
	L.add_child(pl)
	prim(pl, sph(0.3), Vector3(0, 0.28, 0.02), "l906_plush", Vector3(1.0, 1.1, 0.85))
	prim(pl, sph(0.21), Vector3(0, 0.74, 0.0), "l906_plush")
	for s: float in [-1.0, 1.0]:
		prim(pl, sph(0.1), Vector3(s * 0.3, 0.3, -0.06), "l906_plush", Vector3(0.8, 1.4, 0.8))
		prim(pl, sph(0.11), Vector3(s * 0.16, 0.0, -0.28), "l906_plush", Vector3(0.9, 0.8, 1.4))
		prim(pl, sph(0.06), Vector3(s * 0.15, 0.92, 0.0), "l906_plush")
	var sign := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.36, 0.2, 0.01)
	sign.mesh = sm
	sign.position = Vector3(0, 0.42, -0.27)
	sign.material_override = MatLib.get_mat("paper")
	pl.add_child(sign)
	var lab := Label3D.new()
	lab.text = "Free hugs."
	lab.font_size = 36
	lab.pixel_size = 0.0018
	lab.modulate = Color(0.15, 0.1, 0.08)
	lab.outline_size = 0
	lab.position = Vector3(0, 0.42, -0.282)
	lab.rotation.y = PI
	pl.add_child(lab)
	L.add_note("l906_captain", "A plush in the armchair", "A life-sized plushie of Captain sits in the armchair. A card hangs around its neck: \"Free hugs.\"", ap + Vector3.UP * 0.8, Vector3(0.7, 1.0, 0.7), false)
	# reading table: music sheets, botany, the two ancient scrolls
	var tp := Vector3(1.6, 0, 8.3)
	K.table(k, tp, 1.7, 0.85)
	K.chair(k, tp + Vector3(-0.4, 0, -0.75), Vector3(0, 0, 1))
	K.chair(k, tp + Vector3(0.45, 0, 0.72), Vector3(0, 0, -1))
	k.box(tp + Vector3(-0.45, 0.79, 0.05), Vector3(0.36, 0.05, 0.27), "l906_damask")
	for s: float in [0.0, 1.0]:
		var sp := tp + Vector3(0.25 + s * 0.12, 0.81, -0.1 + s * 0.18)
		k.box_xf(Transform3D(Basis(Vector3.UP, 0.3 + s * 0.5).rotated(Vector3.UP, 0.0), sp), Vector3(0.42, 0.055, 0.055), "paper", GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.UP, 0.3 + s * 0.5), sp), Vector3(0.48, 0.03, 0.03), "l906_wood", GeoKit.ALL, false)
	K.stack(k, tp + Vector3(0.62, 0.79, 0.2), L.rng, 4)
	L.add_note("l906_scrolls", "Two ancient scrolls", "Two scrolls on old rods: \"The Book Of The Moon - Verse 1\" and \"The Scroll of Azkhari\". The script inside is in no alphabet you know.", tp + Vector3(0.3, 0.86, 0.0), Vector3(0.6, 0.2, 0.4), false)
	L.add_note("l906_music", "A folder of music sheets", "Music sheets from the 14th century to the 1950s, most of them written for harpsichord, organ and piano. Nothing here is playing them.", tp + Vector3(-0.45, 0.86, 0.05), Vector3(0.4, 0.2, 0.3), false)
	L.add_note("l906_favourites", "Her favourite shelves", "Blanche's favourite books and her unfinished works: human philosophy, religious books in several languages, a great many books on botany. Every one is signed.", Vector3(-4.1, 1.4, 5.6), Vector3(0.3, 1.0, 1.4), false)
	# the "To-read list" shelf on the south wall
	var tr := Vector3(2.7, 0, 9.72)
	k.box(tr + Vector3(0, 1.93, -0.02), Vector3(0.62, 0.1, 0.02), "l906_brass", GeoKit.ALL, false)
	var tl := Label3D.new()
	tl.text = "To-read list"
	tl.font_size = 30
	tl.pixel_size = 0.0016
	tl.modulate = Color(0.12, 0.08, 0.04)
	tl.position = tr + Vector3(0, 1.93, -0.035)
	tl.rotation.y = PI
	L.add_child(tl)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.24, 0.17)
	flicker_book = prim(L, bm, tr + Vector3(-0.15, 1.65, -0.08), "l906_velvet")
	L.add_note("l906_toread", "A shelf labelled \"To-read list\"", "Books guests gave her or told her to read, in more languages than there are guests. One thin novel on the shelf will not hold still: it flickers, as if it cannot decide whether it is here.", tr + Vector3(0, 1.6, -0.1), Vector3(1.2, 0.6, 0.3), false)
	# standing candelabrum
	K.candlestick(k, Vector3(3.7, 0, 3.4), 5, 1.4)
	L.lights.add_anchor(Vector3(3.7, 1.8, 3.4), LIGHT, 1.6, 7.0, 0.05)
	k.commit()


func build_tea_room() -> void:
	var k: GeoKit = L.kit("TeaRoom")
	var a := 11.5
	var b := 18.95
	for w in [[Vector3(19.0, 0, 11.2), Vector3(19.3, 4.2, 19.3)], [Vector3(11.2, 0, 19.0), Vector3(19.3, 4.2, 19.3)]]:
		k.box_mm(w[0], w[1], "l906_panel")
	k.box_mm(Vector3(13.6, 0, 11.2), Vector3(19.0, 0.012, 19.0), "l906_tea_tile", GeoKit.PY, false)
	k.box_mm(Vector3(11.2, 0, 13.6), Vector3(13.6, 0.012, 19.0), "l906_tea_tile", GeoKit.PY, false)
	k.quad(Vector3(16.3, 4.19, 15.1), Vector3.DOWN, Vector3(2.7, 0, 0), Vector3(0, 0, 3.9), "l906_tin")
	k.quad(Vector3(12.4, 4.19, 16.3), Vector3.DOWN, Vector3(1.2, 0, 0), Vector3(0, 0, 2.7), "l906_tin")
	# wallpaper over a wooden dado
	for ln in [[Vector3(a, 0, 13.6), Vector3(a, 0, b)], [Vector3(13.6, 0, a), Vector3(b, 0, a)], [Vector3(b, 0, a), Vector3(b, 0, b)], [Vector3(a, 0, b), Vector3(b, 0, b)]]:
		k.wall(ln[0] + Vector3.UP * 1.0, ln[1] + Vector3.UP * 1.0, 3.2, 0.02, "l906_tea_wall")
		k.wall(ln[0], ln[1], 1.0, 0.04, "l906_wood")
	var ca := Vector3(11.2, 0, 13.6) + Vector3(0.115, 0, 0.115)
	var cb := Vector3(13.6, 0, 11.2) + Vector3(0.115, 0, 0.115)
	k.wall(ca, cb, 4.2, 0.02, "l906_tea_wall", [{"at": ca.distance_to(cb) * 0.5, "w": 1.3, "h": 2.5}])
	# the range: working oven and stove, flue to the ceiling
	var rp := Vector3(18.35, 0, 15.0)
	k.box(rp + Vector3(0, 0.45, 0), Vector3(0.75, 0.9, 1.6), "l906_iron")
	k.box(rp + Vector3(-0.38, 0.42, 0.35), Vector3(0.02, 0.5, 0.55), "l906_iron", GeoKit.ALL, false)
	k.box(rp + Vector3(-0.39, 0.25, -0.35), Vector3(0.02, 0.05, 0.4), "l906_flame", GeoKit.ALL, false)
	k.box(rp + Vector3(-0.43, 0.8, 0), Vector3(0.03, 0.03, 1.5), "l906_brass", GeoKit.ALL, false)
	for s: float in [-0.4, 0.4]:
		k.cylinder(rp + Vector3(-0.05, 0.915, s), 0.17, 0.03, "l906_iron", 10, false)
	k.cylinder(rp + Vector3(0.12, 2.55, 0.0), 0.11, 3.3, "l906_iron", 10, false)
	k.cylinder(rp + Vector3(-0.05, 1.0, 0.4), 0.11, 0.17, "l906_silver", 10, false)
	L.lights.add_anchor(rp + Vector3(-0.8, 0.45, -0.35), Color(1.0, 0.45, 0.15), 0.6, 3.0, 0.2)
	# base cabinets, marble worktop, tea cabinets of tins above
	k.box_mm(Vector3(12.4, 0, 18.3), Vector3(17.6, 0.88, 18.95), "l906_wood")
	k.box_mm(Vector3(12.35, 0.88, 18.25), Vector3(17.65, 0.92, 18.95), "l906_marble")
	var tins := ["l906_gilt", "l906_damask", "l906_tea_wall", "l906_velvet", "l906_iron", "l906_porcelain"]
	for row in 2:
		var y := 1.5 + row * 0.5
		k.box_mm(Vector3(12.6, y - 0.03, 18.55), Vector3(17.4, y, 18.95), "l906_wood")
		for t in 22:
			k.cylinder(Vector3(12.75 + t * 0.21, y + 0.1, 18.73), 0.065, 0.2, tins[(t * 7 + row * 3) % tins.size()], 8, false)
	k.box_mm(Vector3(12.6, 2.47, 18.5), Vector3(17.4, 2.55, 18.95), "l906_wood")
	# cupboard of porcelain and silver (north wall)
	k.box_mm(Vector3(14.4, 0, 11.5), Vector3(18.6, 0.9, 12.0), "l906_wood")
	k.box_mm(Vector3(14.4, 0.9, 11.5), Vector3(18.6, 2.5, 11.6), "l906_wood")
	for row in 3:
		var y := 1.25 + row * 0.42
		k.box_mm(Vector3(14.45, y - 0.02, 11.55), Vector3(18.55, y, 11.85), "l906_wood")
		for t in 16:
			var px := 14.62 + t * 0.245
			if row == 1 and t % 2 == 1:
				k.cylinder(Vector3(px, y + 0.05, 11.72), 0.045, 0.09, "l906_porcelain", 8, false)
			else:
				k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(px, y + 0.12, 11.7)), Vector3(0.22, 0.22, 0.015), "l906_porcelain", GeoKit.ALL, false)
	k.box_mm(Vector3(14.4, 2.5, 11.5), Vector3(18.6, 2.62, 12.05), "l906_wood")
	# cooking books
	K.shelves(k, Vector3(11.75, 0, 15.6), Vector3(11.75, 0, 18.7), 0.45, 6, Vector3(1, 0, 0))
	# the tea table, set
	k.cylinder(TEA + Vector3.UP * 0.37, 0.06, 0.74, "l906_wood", 10)
	k.cylinder(TEA + Vector3.UP * 0.74, 0.66, 0.04, "l906_wood", 20)
	k.cylinder(TEA + Vector3.UP * 0.765, 0.7, 0.012, "l906_cloth", 20, false)
	k.cylinder(TEA + Vector3(0, 0.85, 0), 0.085, 0.15, "l906_porcelain", 12, false)
	k.box(TEA + Vector3(0.11, 0.88, 0), Vector3(0.1, 0.025, 0.025), "l906_porcelain", GeoKit.ALL, false)
	k.cylinder(TEA + Vector3(0, 0.94, 0), 0.03, 0.03, "l906_porcelain", 8, false)
	for c: Vector3 in [Vector3(0, 0, 0.38), Vector3(0, 0, -0.38), Vector3(0.38, 0, 0)]:
		k.cylinder(TEA + c + Vector3.UP * 0.776, 0.075, 0.01, "l906_porcelain", 12, false)
		k.cylinder(TEA + c + Vector3.UP * 0.81, 0.04, 0.06, "l906_porcelain", 10, false)
		k.box(TEA + c * 1.25 + Vector3(0.0, 0.775, 0.0) + Vector3(c.z, 0, c.x) * 0.3, Vector3(0.02, 0.006, 0.16) if absf(c.z) > 0.0 else Vector3(0.16, 0.006, 0.02), "l906_silver", GeoKit.ALL, false)
	k.cylinder(TEA + Vector3(-0.3, 0.78, 0.12), 0.13, 0.015, "l906_porcelain", 12, false)
	for t in 6:
		k.cylinder(TEA + Vector3(-0.3 + cos(t) * 0.07, 0.795, 0.12 + sin(t) * 0.07), 0.03, 0.012, "l906_cloth", 8, false)
	K.candlestick(k, TEA + Vector3(-0.15, 0.77, -0.2), 1, 0.18)
	K.chair(k, TEA + Vector3(0, 0, 0.95), Vector3(0, 0, -1), "l906_damask")
	K.chair(k, TEA + Vector3(0, 0, -0.95), Vector3(0, 0, 1), "l906_damask")
	K.chair(k, TEA + Vector3(0.95, 0, 0), Vector3(-1, 0, 0), "l906_damask")
	var lp := K.candelabra(k, TEA + Vector3.UP * 3.55, 0.45, 6, 1, 4.2)
	L.lights.add_anchor(lp + Vector3.DOWN * 0.6, LIGHT, 2.2, 5.2, 0.05)
	k.commit()
	L.add_interactable(TEA + Vector3(0, 0.95, 0), Vector3(1.3, 0.3, 1.3), "Sit down to tea", func(_p): L.hosts.tea_table())
	L.add_note("l906_tea", "The Tea Room", "A working oven and stove, cabinets of tea in tins, a cupboard full of porcelain cups and plates and silver tableware, and shelves of cooking books. This is where she makes the tea and the biscuits.", Vector3(15.0, 1.6, 18.5), Vector3(2.0, 1.2, 0.4), false)


## The guest room Blanche gives you, shaped to suit you (page: she can change
## and manipulate these rooms to accommodate guests). Rebuilt when the style changes.
func build_guest_room(style: String) -> void:
	if room_node and is_instance_valid(room_node):
		room_node.queue_free()
	room_style = style
	room_node = Node3D.new()
	room_node.name = "GuestRoom_" + style
	L.add_child(room_node)
	var k := GeoKit.new(room_node, "Room")
	var c := ROOM_C
	var lo := 13.92
	var hi := 18.88
	var wall_mat: String = {"study": "l906_damask", "rest": "l906_velvet", "tea": "l906_tin"}.get(style, "l906_tea_wall")
	for ln in [[Vector3(hi, c.y, lo), Vector3(hi, c.y, hi)], [Vector3(lo, c.y, hi), Vector3(hi, c.y, hi)], [Vector3(lo, c.y, lo), Vector3(lo, c.y, hi)]]:
		k.wall(ln[0], ln[1], 3.9, 0.02, wall_mat)
	k.wall(Vector3(lo, c.y, lo), Vector3(hi, c.y, lo), 3.9, 0.02, wall_mat, [{"at": 2.48, "w": 1.05, "h": 2.2}])
	k.box_mm(Vector3(lo + 0.5, c.y, lo + 0.9), Vector3(hi - 0.5, c.y + 0.014, hi - 0.5), "l906_carpet_rug", GeoKit.PY, false)
	var bed := Vector3(17.7, c.y, 17.2)
	var big := style == "rest"
	var bw := 1.7 if big else 1.2
	k.box(bed + Vector3(0, 0.3, 0), Vector3(2.1, 0.3, bw), "l906_wood")
	k.box(bed + Vector3(0, 0.53, 0), Vector3(2.0, 0.16, bw - 0.08), "l906_linen")
	k.box(bed + Vector3(-0.2, 0.62, 0), Vector3(1.4, 0.05, bw - 0.02), "l906_velvet", GeoKit.ALL, false)
	k.box(bed + Vector3(0.82, 0.66, 0), Vector3(0.36, 0.12, bw * 0.8), "l906_linen", GeoKit.ALL, false)
	k.box(bed + Vector3(1.08, 0.7, 0), Vector3(0.08, 1.4, bw + 0.1), "l906_wood")
	if big:
		for p: Vector3 in [Vector3(-1.02, 0, -0.9), Vector3(-1.02, 0, 0.9), Vector3(1.02, 0, -0.9), Vector3(1.02, 0, 0.9)]:
			k.box(bed + p + Vector3.UP * 1.2, Vector3(0.07, 2.4, 0.07), "l906_wood", GeoKit.ALL, false)
		k.box(bed + Vector3(0, 2.42, 0), Vector3(2.15, 0.12, 1.9), "l906_velvet", GeoKit.ALL, false)
		k.box(bed + Vector3(0.0, 1.5, 0.93), Vector3(2.1, 1.7, 0.02), "l906_velvet", GeoKit.ALL, false)
	K.candlestick(k, bed + Vector3(0.9, 0.0, -bw * 0.5 - 0.45) + Vector3.UP * 0.62, 1, 0.16)
	k.box(bed + Vector3(0.9, 0.3, -bw * 0.5 - 0.45), Vector3(0.45, 0.6, 0.45), "l906_wood")
	match style:
		"study":
			K.table(k, Vector3(14.8, c.y, 17.4), 0.8, 1.4)
			K.chair(k, Vector3(15.55, c.y, 17.4), Vector3(-1, 0, 0))
			K.candlestick(k, Vector3(14.7, c.y + 0.76, 17.9), 2, 0.25)
			K.stack(k, Vector3(14.8, c.y + 0.76, 16.95), L.rng, 6)
			K.shelves(k, Vector3(14.2, c.y, 14.6), Vector3(14.2, c.y, 16.3), 0.4, 7, Vector3(1, 0, 0))
		"tea":
			k.cylinder(Vector3(15.0, c.y + 0.35, 17.6), 0.05, 0.7, "l906_wood", 8)
			k.cylinder(Vector3(15.0, c.y + 0.7, 17.6), 0.4, 0.03, "l906_wood", 16)
			k.cylinder(Vector3(15.0, c.y + 0.79, 17.6), 0.07, 0.14, "l906_porcelain", 10, false)
			K.chair(k, Vector3(15.0, c.y, 16.75), Vector3(0, 0, 1), "l906_velvet")
			K.chair(k, Vector3(14.3, c.y, 18.2), Vector3(1, 0, -1), "l906_velvet")
		"rest":
			k.box(Vector3(17.3, c.y + 0.03, 15.9), Vector3(0.14, 0.06, 0.28), "l906_velvet", GeoKit.ALL, false)
			k.box(Vector3(17.5, c.y + 0.03, 15.85), Vector3(0.14, 0.06, 0.28), "l906_velvet", GeoKit.ALL, false)
		_:
			k.box_mm(Vector3(14.1, c.y, 18.2), Vector3(15.4, c.y + 2.1, 18.85), "l906_wood")
			k.box(Vector3(14.75, c.y + 1.05, 18.19), Vector3(0.02, 1.8, 0.02), "l906_brass", GeoKit.ALL, false)
			K.table(k, Vector3(14.5, c.y, 15.5), 0.6, 0.5, 0.8)
			k.cylinder(Vector3(14.5, c.y + 0.85, 15.5), 0.2, 0.08, "l906_porcelain", 12, false)
	k.commit()
	if not L.lights.anchors.any(func(x): return x.get("group", "") == "guest_room"):
		L.lights.add_anchor(Vector3(16.4, 7.2, 16.0), LIGHT, 0.55, 4.6, 0.04, "guest_room")
	var it := Interactable.new()
	room_node.add_child(it)
	it.setup(bed + Vector3(0, 0.8, 0), Vector3(2.0, 0.5, bw), "Rest in the bed", func(_p): L.hosts.rest())
