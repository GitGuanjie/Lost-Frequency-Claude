extends RefCounted
## Level 49 dressing: what the page says is scattered in the trenches
## (half-empty Almond Water, canned food, used medical kits, worn uniforms,
## empty rifles, notes and books), bunker furnishings (beds, tables, chairs,
## tattered uniforms, ammunition crates, ration packs) and the in-world
## documents, paraphrased and labelled as testimony.

const TR := preload("res://levels/L049/L049_trench.gd")
const U := preload("res://levels/L049/L049_under.gd")
const KS := 2.05

const LETTERS := [
	["Letter: General Douglas to his soldiers", "To every soldier of ours:\n\nHagsten is cunning and has no mercy. They want our land and they will stop at nothing. We cannot read their next move, and our intelligence says they have built new weapons we must be ready for.\n\nStay alert. Defend the homeland at any cost. \"Failure is not an option.\"\n\n- General Douglas\n\n(In-universe letter found in the trenches; Nuvaria and Hagsten are unconfirmed.)"],
	["Letter: to the next soul", "To whoever wanders these trenches next:\n\nThe gunfire has turned into a lullaby. I see my comrades' faces when I close my eyes. We are ghosts of ourselves, caught in a war that does not end.\n\nMaybe we will never see its end. \"Remember us.\"\n\n(Unsigned letter, testimony.)"],
	["Letter: Sgt. Theodore Phillips to the General", "General,\n\nWe need reinforcements. The enemy keeps advancing and our supplies are almost gone - no shipments, no rations, no medical aid for a month. We hold, but we lose men faster than we can replace them.\n\n\"This trench has become a graveyard.\" Send men. Send anything.\n\n- Sgt. Theodore Phillips\n\n(In-universe letter, testimony.)"],
	["L.E.A.D.S. card (nailed to a post)", "IN A BOMBING:\nL - Locate shelter immediately.\nE - Enter it without delay.\nA - Avoid open areas.\nD - Duck and cover your head.\nS - Shield your head with your hands or gear.\n\n(Survival protocol as given on the Level 49 page.)"],
	["Scrawled on a board", "DON'T stick your head over. They never miss.\nDON'T run. DON'T shine a light out in the open.\nDO keep low. Keep quiet. Keep to cover.\nAnd don't fight it. Whatever you do.\n\n(Wanderer's advice, matching the page's dos and don'ts.)"],
]

var lvl


func _init(level) -> void:
	lvl = level


func _kn(node: Node3D, name: String, p: Vector3, yaw: float, collide: bool = false, mult: float = 1.0) -> Node3D:
	var id := "kenney/furniture-kit/" + name
	return Props.place(lvl, node, id, p, yaw, maxf(Props.bounds(id).size.y * KS * mult, 0.01), collide)


## Supplies against the trench walls. Returns interactable specs.
func supplies(k: GeoKit, node: Node3D, info: Dictionary, r: RandomNumberGenerator, count: int) -> void:
	var walls: Array = info["walls"]
	if walls.is_empty():
		return
	for i in count:
		var w: Array = walls[r.randi() % walls.size()]
		var c: Vector2i = w[0]
		var dv: Vector2i = TR.DIRS[w[1]]
		var n := Vector3(dv.x, 0, dv.y)
		var lat := Vector3(-n.z, 0, n.x)
		var p := TR.cpos(c, TR.FLOOR + 0.08) + n * 0.68 + lat * r.randf_range(-0.6, 0.6)
		var yaw := r.randf() * 360.0
		match r.randi() % 8:
			0, 1:
				Props.place(lvl, node, "kenney/food-kit/soda-bottle", p, yaw, 0.3)
				Props.place(lvl, node, "kenney/food-kit/soda-bottle", p + lat * 0.18, yaw, 0.3)
				lvl.make_interactable(p + Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6), "Take the half-empty bottle of Almond Water", lvl._almond, node)
			2:
				for j in 3:
					Props.place(lvl, node, "kenney/food-kit/can", p + lat * (j * 0.13) + Vector3(0, 0, 0), yaw + j * 40.0, 0.12)
				lvl.make_interactable(p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7), "Open a can of food", lvl._can, node)
			3:
				Props.place(lvl, node, "ph/medical_box", p, yaw)
				lvl.make_interactable(p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 0.7), "Use the medical kit", lvl._medkit, node)
			4, 5:
				U.rifle(k, p - n * 0.05, n, r)
			6:
				k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, 0.06, 0)), Vector3(0.7, 0.12, 0.5), "l49_uniform", GeoKit.ALL, false)
				k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0.15, 0.15, 0.05)), Vector3(0.5, 0.08, 0.35), "l49_uniform", GeoKit.ALL, false)
			_:
				Props.place(lvl, node, "ph/wooden_crate_01", p - n * 0.05, rad_to_deg(atan2(lat.x, lat.z)), 0.0, false)
				if r.randf() < 0.5:
					Props.place(lvl, node, "kenney/furniture-kit/books", p + Vector3(0, 0.35, 0), yaw, 0.12)


## A chunk-owned paper with a document from the pool (or a given one).
func note(node: Node3D, p: Vector3, which: int) -> void:
	var doc: Array = LETTERS[which % LETTERS.size()]
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.21, 0.003, 0.29)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("paper")
	mi.position = p
	mi.rotation.y = randf_range(-0.6, 0.6)
	node.add_child(mi)
	lvl.make_interactable(p + Vector3(0, 0.15, 0), Vector3(0.5, 0.35, 0.5), "Read", func(): Overlay.show_note(doc[0], doc[1]), node)


## A chunk-owned document with its own title and text.
func doc(node: Node3D, title: String, text: String, p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.21, 0.003, 0.29)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("paper")
	mi.position = p
	node.add_child(mi)
	lvl.make_interactable(p + Vector3(0, 0.15, 0), Vector3(0.5, 0.35, 0.5), "Read", func(): Overlay.show_note(title, text), node)


## Furnish a bunker room. Returns a lantern light position.
func bunker_room(k: GeoKit, node: Node3D, b: Dictionary, r: RandomNumberGenerator) -> Vector3:
	var d: Vector2i = b["d"]
	var dv := Vector3(d.x, 0, d.y)
	var lat: Vector2i = b["lat"]
	var lv := Vector3(lat.x, 0, lat.y)
	var ca: Vector3 = b["corner_a"]
	var cb: Vector3 = b["corner_b"]
	var na: Vector3 = b["near_a"]
	var yaw := rad_to_deg(atan2(lv.x, lv.z))
	Props.place(lvl, node, "ph/old_bed_frame", ca - lv * 0.25 + dv * 0.0, yaw, 0.0, true)
	k.box(ca - lv * 0.25 + Vector3(0, 0.5, 0), U._o(dv, Vector3(1.9, 0.12, 0.8)), "l49_uniform", GeoKit.ALL, false)
	var tb := Basis(Vector3.UP, deg_to_rad(yaw))
	k.box_xf(Transform3D(tb, cb + Vector3(0, 0.76, 0)), Vector3(1.2, 0.05, 0.7), "l49_board", GeoKit.ALL, false)
	for sx: float in [-0.52, 0.52]:
		for sz: float in [-0.28, 0.28]:
			k.box_xf(Transform3D(tb, cb + tb * Vector3(sx, 0.37, sz)), Vector3(0.07, 0.74, 0.07), "l49_post", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(tb, cb + Vector3(0, 0.39, 0)), Vector3(1.2, 0.78, 0.7), "wood")
	_kn(node, "chair", cb - lv * 0.7, yaw + 90.0, true)
	Props.place(lvl, node, "ph/old_military_crate", na - lv * 0.2 + dv * 0.3, yaw, 0.0, true)
	Props.place(lvl, node, "ph/cardboard_box_01", na + dv * 0.6 + lv * 0.5, r.randf() * 90.0)
	Props.place(lvl, node, "kenney/graveyard-kit/lantern-glass", cb + Vector3(0, 0.78, 0), 0.0, 0.32)
	Props.place(lvl, node, "kenney/food-kit/can", cb + Vector3(0.25, 0.78, 0.1), 0.0, 0.12)
	k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), (b["centre"] as Vector3) + Vector3(r.randf_range(-0.8, 0.8), 0.05, 0)), Vector3(0.8, 0.1, 0.5), "l49_uniform", GeoKit.ALL, false)
	return cb + Vector3(0, 1.3, 0)


## The rusted iron door set in a bunker wall (visual).
static func iron_door(k: GeoKit, base: Vector3, n: Vector3) -> void:
	var lv := Vector3(-n.z, 0, n.x)
	k.box(base + Vector3(0, 1.0, 0) - n * 0.02, U._o(lv, Vector3(0.95, 2.0, 0.08)), "l49_door_rust", GeoKit.ALL, false)
	for y: float in [0.35, 1.65]:
		k.box(base + Vector3(0, y, 0) - n * 0.07, U._o(lv, Vector3(0.95, 0.08, 0.04)), "l49_rust", GeoKit.ALL, false)
	k.box(base + Vector3(0, 1.0, 0) - n * 0.08 + lv * 0.35, Vector3(0.06, 0.18, 0.06), "l49_steel", GeoKit.ALL, false)
	for s: float in [-0.55, 0.55]:
		k.box(base + lv * s + Vector3(0, 1.08, 0) - n * 0.03, Vector3(0.14, 2.16, 0.14), "l49_post", GeoKit.ALL, false)
	k.box(base + Vector3(0, 2.12, 0) - n * 0.03, U._o(lv, Vector3(1.25, 0.14, 0.16)), "l49_post", GeoKit.ALL, false)


## The M.E.G. outpost: a radio, a map table, crates; the reports.
func gutter_extras(k: GeoKit, node: Node3D, bunks: Array) -> void:
	if bunks.size() < 3:
		return
	var b0: Dictionary = bunks[1]
	var c: Vector3 = b0["centre"]
	Props.place(lvl, node, "ph/vintage_radio_transceiver", (b0["corner_b"] as Vector3) + Vector3(0, 0.78, 0) + Vector3(-0.2, 0, 0), 180.0)
	Props.place(lvl, node, "ph/clipboard", (b0["corner_b"] as Vector3) + Vector3(0.25, 0.78, 0.1), 20.0)
	doc(node, "M.E.G. exit test log (Gutter Bunkers)", "Seven attempts to cross the parapet, all logged:\n1. a doll on a pole - \"No response. The doll remained untouched\"\n2. a remote rover - destroyed\n3. armour - no protection\n4. a tank - destroyed\n5. a jamming APC - destroyed\n6. camouflage - shot\n7. a cloaked drone - shot down\n\nOnly the doll survived.\n\n(Summary of the page's test log; testimony.)", c + Vector3(0.3, 0.8, 0.0))
	doc(node, "Incident report: the mortar offensive", "An offensive with captured mortars drew counter-fire, a bomber and a missile. Four M.E.G. and two B.F.G. personnel died.\n\n\"A full moratorium is hereby enacted\" on exit tests and offensive operations.\n\n(Paraphrase of the page's report; testimony.)", (bunks[2]["centre"] as Vector3) + Vector3(0, 0.05, 0))
	doc(node, "Field log: Lancaster, 2015/04/14", "Three of the machines. They moved together - one drove us, two waited. Two of my team are dead. I'm hiding in a dugout and I can hear it outside.\n\n\"I swear they're working together.\"\n\n[the log ends in gunfire]\n\n(Testimony. The B.F.G.'s Falcon claims there is only one Trenchcleaner; the accounts conflict.)", (bunks[0]["centre"] as Vector3) + Vector3(0, 0.05, 0))
	doc(node, "Interview transcript, B.F.G. (excerpt)", "Falcon, of the B.F.G. - the only independent community down here - says their machines can read body heat out to fifteen miles, and insists: \"There is only one Trenchcleaner.\"\n\n(Testimony; contradicts Lancaster's log.)", (bunks[1]["corner_a"] as Vector3) + Vector3(0, 0.56, 0))
	for bb in bunks:
		Props.place(lvl, node, "ph/old_military_crate", (bb["near_a"] as Vector3) + Vector3(0, 0.3, 0) - (Vector3((bb["lat"] as Vector2i).x, 0, (bb["lat"] as Vector2i).y)) * 0.2, 0.0)
	Props.place(lvl, node, "ph/vintage_flashlight", c + Vector3(0.8, 0.0, 0.3), 40.0)
	Props.place(lvl, node, "ph/medical_box", c + Vector3(-0.8, 0.0, 0.2), 10.0)


## The surface between trenches: shell craters, dark stains, dead stumps.
func no_mans_land(k: GeoKit, node: Node3D, lay: Dictionary, r: RandomNumberGenerator) -> void:
	var cells: Dictionary = lay["cells"]
	for i in 7:
		var c := Vector2i(r.randi() % TR.NC, r.randi() % TR.NC)
		if cells.has(c):
			continue
		var p := TR.cpos(c, 0.0) + Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-0.6, 0.6))
		var rad := r.randf_range(0.6, 1.4)
		k.cylinder(p + Vector3(0, 0.07, 0), rad + 0.35, 0.14, "l49_mud_floor", 12, false, true)
		k.cylinder(p + Vector3(0, 0.08, 0), rad, 0.14, "l49_crater" if i % 3 != 2 else "l49_stain", 12, false, true)
		if i % 2 == 0:
			k.cylinder(p + Vector3(0, 0.1, 0), rad * 0.55, 0.14, "l49_puddle", 12, false, true)
	for i in 2:
		var c := Vector2i(r.randi() % TR.NC, r.randi() % TR.NC)
		if cells.has(c):
			continue
		var p := TR.cpos(c, 0.0)
		if r.randf() < 0.5:
			Props.place(lvl, node, "ph/dead_tree_trunk", p, r.randf() * 360.0)
		else:
			k.cylinder(p + Vector3(0, 0.6, 0), 0.16, 1.2, "l49_post", 6, false, true)
