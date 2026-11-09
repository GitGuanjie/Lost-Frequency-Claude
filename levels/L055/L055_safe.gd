extends RefCounted
## Level 55 Safe Room: chunk (0,0), the one and only entry point. A diner
## room like the rest, made into a temporary shelter: a bedroll of booth
## cushions, an M.E.G. supply crate (phones, a first-aid box, a torch, the
## pamphlet), a meal on a table, jugs of plain water, and the table the
## light falls across.

const R := preload("res://levels/L055/L055_room.gd")
const D := preload("res://levels/L055/L055_dress.gd")
const DESIGN := {"id": -1, "arch": 0, "kside": 3, "paper": "l55_paper0", "low": "l55_panel", "bath": true, "dais": false,
	"beam_x": false, "beams": 2, "stacked": false, "seed": 55055}
const NARRATOR := Vector3(10.6, 0.0, 12.4)
const MEAL := Vector3(14.0, 0.0, 11.4)
const CRATE := Vector3(6.4, 0.0, 20.3)

var lvl


func _init(level) -> void:
	lvl = level


func beam_targets() -> Array:
	return [NARRATOR + Vector3(0.1, 0.74, 0.1), Vector3(17.2, 0.0, 13.2)]


func furnish(k: GeoKit, node: Node3D) -> Array:
	var tops: Array = []
	# the narrator's table: two chairs, one pushed back as if just left
	D.table(k, NARRATOR, Vector2(0.9, 0.9), 0.0)
	D.chair(k, NARRATOR + Vector3(0, 0, -0.7), 0.0)
	D.chair(k, NARRATOR + Vector3(0.15, 0, 0.95), PI + 0.4)
	tops.append(NARRATOR + Vector3(0, 0.78, 0))
	D.table(k, MEAL, Vector2(1.6, 0.9), 0.0, "l55_table", true)
	for sx in [-0.4, 0.4]:
		D.chair(k, MEAL + Vector3(sx, 0, -0.68), 0.0)
		D.chair(k, MEAL + Vector3(sx, 0, 0.68), PI)
	tops.append(MEAL + Vector3(0, 0.78, 0))
	for p in [Vector3(18.6, 0, 11.6), Vector3(18.6, 0, 19.2), Vector3(11.0, 0, 19.2), Vector3(7.4, 0, 12.4)]:
		D.table(k, p, Vector2(0.9, 0.9), 0.0)
		for s in [[Vector3(0, 0, -0.68), 0.0], [Vector3(0, 0, 0.68), PI], [Vector3(-0.68, 0, 0), PI * 0.5], [Vector3(0.68, 0, 0), -PI * 0.5]]:
			D.chair(k, p + (s[0] as Vector3), float(s[1]))
		tops.append(p + Vector3(0, 0.78, 0))
	for z in [12.5, 15.0]:
		D.booth(k, Vector3(3.95, 0, z), 0.0)
		tops.append(Vector3(3.95, 0.78, z))
	# a bedroll of booth cushions in the far corner
	for i in 3:
		k.box(Vector3(3.9 + i * 0.62, 0.07, 19.6), Vector3(0.6, 0.14, 0.62), "l55_booth", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.15), Vector3(4.6, 0.17, 19.55)), Vector3(1.6, 0.06, 0.9), "l55_blanket", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, -0.1), Vector3(5.6, 0.2, 19.3)), Vector3(0.5, 0.06, 0.6), "l55_blanket", GeoKit.ALL, false)
	k.box(Vector3(3.45, 0.2, 19.6), Vector3(0.3, 0.14, 0.5), "l55_cloth", GeoKit.ALL, false)
	# M.E.G. phones on the crate
	for i in 2:
		k.box_xf(Transform3D(Basis(Vector3.UP, 0.3 * i), CRATE + Vector3(-0.55 + i * 0.2, 0.31, 0.15)), Vector3(0.07, 0.015, 0.14), "l55_phone", GeoKit.ALL, false)
	_props(node)
	return tops


func _props(node: Node3D) -> void:
	Props.place(lvl, node, "ph/old_military_crate", CRATE, 0.0, 0.0, true)
	Props.place(lvl, node, "ph/medical_box", CRATE + Vector3(0.35, 0.3, 0.0), 20.0)
	Props.place(lvl, node, "ph/vintage_flashlight", CRATE + Vector3(0.0, 0.3, -0.2), 70.0)
	Props.place(lvl, node, "ph/plastic_bottle_gallon", Vector3(7.6, 0.0, 20.5), 0.0)
	Props.place(lvl, node, "ph/plastic_bottle_gallon", Vector3(7.85, 0.0, 20.4), 40.0)
	Props.place(lvl, node, "ph/vintage_suitcase", Vector3(3.4, 0.0, 17.4), 90.0)
	Props.place(lvl, node, "ph/wall_clock", Vector3(R.C.x - R.H + 0.04, 2.6, 17.5), 90.0)
	Props.place(lvl, node, "kenney/furniture-kit/coatrackstanding", Vector3(3.5, 0.0, 6.9), 0.0, 1.9)
	# the meal: ordinary Frontrooms food
	var f := [["burger", Vector3(-0.4, 0, -0.1), 0.11], ["fries-empty", Vector3(-0.15, 0, 0.1), 0.12], ["soda-bottle", Vector3(0.2, 0, -0.2), 0.26],
		["plate-dinner", Vector3(0.45, 0, 0.1), 0.03], ["sandwich", Vector3(0.45, 0.03, 0.1), 0.07], ["glass", Vector3(0.65, 0, -0.2), 0.13]]
	for it in f:
		Props.place(lvl, node, "kenney/food-kit/" + str(it[0]), MEAL + Vector3(0, 0.78, 0) + (it[1] as Vector3), 20.0, float(it[2]))
	Props.place(lvl, node, "kenney/food-kit/mug", NARRATOR + Vector3(0.15, 0.78, -0.12), 30.0, 0.1)
	Props.place(lvl, node, "kenney/food-kit/pizza-box", Vector3(17.0, 1.06, 7.95), 10.0, 0.05)
	# a vibrant yellow apple on the counter
	var ap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.085
	ap.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.78, 0.12)
	m.roughness = 0.35
	ap.material_override = m
	ap.position = Vector3(15.2, 1.1, 7.9)
	node.add_child(ap)
	_notes()


func _notes() -> void:
	lvl.add_note("l55_meg_pamphlet", "M.E.G. pamphlet (on the supply crate)", "LEVEL 55 - \"PIT STOP\"\n\nYou are in the Safe Room. Everyone arrives here; it is the only way in. Rest here. It is safe.\n\nThe rooms beyond (\"the outskirts\") look the same, but they move when nobody is in them. Your route back may not exist.\n\nThe food is ordinary food. The water is plain water. There is no Almond Water here.\n\nYou cannot leave by any door. After a while - minutes or months - the level sends you back where you came from. You will probably feel it coming.\n\nPhones and contact details are in the crate.\n\n(Paraphrase of the M.E.G. information pamphlets the page says are left here.)", CRATE + Vector3(-0.2, 0.32, -0.1))
	lvl.add_note("l55_backnet", "BackNET printout (tucked under a phone)", "THREAD: Level 55 journeys\n\n> 404 entries recorded 2015-2025. 64 of them came through a door in Level 5.\n> shortest stay about 53 minutes. longest four months and fifteen days. average a bit over three days.\n> nobody has ever got back in.\n> almost everyone says they knew their time was running out.\n\n(Figures as given in the Level 55 article; the forum is the research team's.)", CRATE + Vector3(-0.75, 0.32, 0.1))
	lvl.add_note("l55_page", "A page, left on the table in the light (testimony)", "\"I sat back down in the light and it took me home. The cafe, the rain on the glass, my dad across the table asking me to promise.\"\n\n\"I have to fulfill my promise.\"\n\n\"So thank you, little pit stop.\"\n\n(First-person account, unnamed, unverified. Narrative from the Level 55 page, paraphrased.)", NARRATOR + Vector3(-0.2, 0.79, 0.15))
