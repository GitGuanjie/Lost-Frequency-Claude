extends LevelBase
## Level 58 — "Water Wonder" (Backrooms Wikidot rev 38, accessed 2026-11-04;
## cite: BlockHead42, CC BY-SA 3.0). Dossier: docs/canon/levels/L058.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: an infinite indoor waterpark in four room types. Everyone no-clips
## into the same main Waterpark: faded plastic slides on white-chipped,
## rusting beams that groan; dry, grimy pools no deeper than 0.5 m with a row
## of blue tiles, beige concrete and dry red leaves; windows onto a bright
## white void where Window entities sometimes appear; a plastic landscape of
## blue grass, blue-leaved trees with uniquely painted dark brown trunks and
## boulders; Tegan Trees with their fruit; smooth concrete walkways; spectator
## areas of picnic benches on blue plastic behind filthy, cracked glass.
## The Corridors: dark, scarce lights, rough grey concrete, white MDF ceiling
## tiles, noisy metal plate floors that attract entities (Smilers, Dullers),
## crates, lamps on tables, stepladders, boards, pallets, pipes, B.N.T.G.
## borders. A Cafe: brown wooden door with two grimy panes and a faded bell,
## broken furniture, a counter, an unlocked till of Frontrooms money, free
## vending machines (10 of each item, inconsistent restock). A Storeroom: grey
## concrete, loud fluorescents that black out, racks, unsealed supply crates,
## chlorine tanks, toilet bowls, mattresses, tyres, suitcases, football kits,
## and once a crate with a red "1" that pulled people through to Level 1.
## Exits: open the red "1" crate (Level 1); no-clip into the black waterslide
## (Level 58.1, class 5); no-clip into exposed piping in the Corridors.
## Layout (finite, authored): the main Waterpark hall (60 x 44 x 14 m) with
## two dry pools, a two-deck slide tower (4.2 m and 8 m), four slides, five
## landscaped mounds and the spectator area; a door east into the Corridors;
## a side corridor north to the Cafe, one south to the Storeroom; the main
## corridor runs past a white window and a B.N.T.G. border to a wall broken
## open onto pipes.
## Mechanics: corridor noise (metal floors) builds an alert that brings a
## Smiler out of the dark; Storeroom blackouts; vending stock that empties and
## restocks on its own clock; the Tegan Fruit stage on a 30-day cycle; lamps
## you can switch on; rare Window entities in the high windows.
## Helpers: L058_park.gd (hall), L058_rooms.gd (corridors, cafe, storeroom).

const PK := preload("res://levels/L058/L058_park.gd")
const RM := preload("res://levels/L058/L058_rooms.gd")
const START := Vector3(-6.0, 0.05, 17.5)
const ITEMS := ["Almond Water", "unbranded crisps", "Greasy Marshmallows", "Warpberries"]

var park
var rooms
var region := "hall"
var alert := 0.0
var smiler: MeshInstance3D
var smiler_on := false
var store_ai: Array = []
var blackout := false
var blk_t := 40.0
var window_fig: Node3D
var window_t := 90.0
var window_show := 0.0
var lamp_ai := -1
var lamp_on := false
var said := {}
var creak_t := 12.0


func build() -> void:
	park = PK.new(self)
	rooms = RM.new(self)
	rules["view_distance"] = 160.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.18
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.62, 0.66, 0.68), 0.55, Color(0.78, 0.8, 0.8), 0.0018)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.05)
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_hdr_threshold = 1.0
	PK.materials()
	RM.materials()
	lights.setup(16, 0)
	lights.max_distance = 45.0
	var k := kit("Waterpark")
	var lit := kit("Lit")
	park.hall(k, lit)
	park.tower(k)
	park.landscape(k)
	park.leaves(k)
	rooms.corridors(k, lit)
	rooms.cafe(k, lit)
	rooms.storeroom(k, lit)
	k.commit()
	lit.commit()
	var d := Node3D.new()
	d.name = "Dressing"
	add_child(d)
	_dress(d)
	_lights()
	_presences()
	_sounds()
	_notes()
	_interactions()
	_exits_and_arrivals()
	add_landmark("Main Waterpark (everyone arrives here)", START)
	add_landmark("Slide tower top deck", Vector3(13.0, PK.P2, -14.0))
	add_landmark("Black waterslide (to Level 58.1)", park.black_mouth)
	add_landmark("Cafe", Vector3(50, 0, -24))
	add_landmark("Storeroom with the red 1 crate", RM.RED_CRATE)
	add_landmark("Exposed piping", RM.PIPES)
	add_shot("main_waterpark", START + Vector3(0, 1.62, 0), Vector3(6.0, 4.5, -12.0), {"flashlight": false})
	add_shot("from_the_slide_tower", Vector3(11.6, PK.P2 + 1.62, -17.8), Vector3(-8.0, -1.0, 8.0), {"flashlight": false})
	add_shot("corridor_metal_floor", Vector3(64.0, 1.6, -0.4), Vector3(92.0, 1.2, 0.2), {"flashlight": true, "prepare": _prep_dark})
	add_shot("storeroom_red_one", Vector3(78.8, 1.65, 36.2), Vector3(86.6, 0.6, 37.6), {"flashlight": false})
	add_shot("cafe", Vector3(51.5, 1.6, -18.8), Vector3(46.5, 0.9, -28.5), {"flashlight": true, "prepare": _prep_dark})


# ------------------------------------------------------------------ dressing

func _dress(d: Node3D) -> void:
	var rr := RandomNumberGenerator.new()
	rr.seed = 5858
	# waterpark: picnic benches, boulders, deck clutter, lifebuoys, lamps
	for p in [Vector3(-27.0, 0.04, 16.5), Vector3(-23.5, 0.04, 19.0), Vector3(-27.0, 0.04, 20.4)]:
		Props.place(self, d, "ph/wooden_picnic_table", p, rr.randf_range(80, 100), 0.0, true)
	for p in [Vector3(-24.0, 0.66, -12.0), Vector3(-6.0, 0.66, -14.5), Vector3(24.0, 0.66, -6.0), Vector3(23.0, 0.44, 17.0), Vector3(-10.0, 0.44, 18.0), Vector3(25.5, 0.66, -16.0)]:
		Props.place(self, d, "ph/boulder_01", p, rr.randf_range(0, 360), rr.randf_range(0.7, 1.3), true)
	for p in [Vector3(4.0, 0, 13.5), Vector3(-21.5, 0, 6.0), Vector3(19.5, 0, 9.0)]:
		Props.place(self, d, "ph/lifebuoy", p + Vector3(0, 0.0, 0), rr.randf_range(0, 360))
	Props.place(self, d, "ph/WetFloorSign_01", Vector3(3.2, 0, 1.0), 30.0)
	Props.place(self, d, "ph/metal_trash_can", Vector3(-1.0, 0, 21.4), 0.0, 0.0, true)
	Props.place(self, d, "ph/plastic_monobloc_chair_01", Vector3(1.5, 0, 15.0), 200.0)
	Props.place(self, d, "ph/plastic_monobloc_chair_01", Vector3(2.4, 0, 16.0), 160.0)
	Props.place(self, d, "ph/rubber_duck_toy", Vector3(-9.0, -PK.LD, 3.0), 40.0)
	for x in [-18.0, -3.0, 12.0, 24.0]:
		Props.place(self, d, "ph/hanging_industrial_lamp", Vector3(x, PK.HH - 2.6, 4.0), 0.0, 1.6)
	# corridors: crates on a trolley, a stepladder, pallets, boards, pipes, a lamp on a table
	Props.place(self, d, "ph/hand_truck", Vector3(39.0, 0, -0.85), 90.0)
	for i in 3:
		Props.place(self, d, "ph/cardboard_box_01", Vector3(39.3, 0.18 + i * 0.34, -0.85), rr.randf_range(-10, 10))
	Props.place(self, d, "ph/wooden_ladder", Vector3(54.0, 0, 0.95), 0.0, 1.9)
	Props.place(self, d, "ph/metal_office_desk", Vector3(44.0, 0, -0.75), 0.0, 0.0, true)
	Props.place(self, d, "kenney/furniture-kit/lamproundfloor", Vector3(44.6, 0.79, -0.8), 0.0, 0.62)
	rooms.lamp_pos = Vector3(44.6, 1.25, -0.8)
	for p in [Vector3(66.0, 0, -0.9), Vector3(86.0, 0, 0.9), Vector3(50.0, 0, -15.0)]:
		Props.place(self, d, "ph/wooden_crate_01", p, rr.randf_range(0, 360), 0.0, true)
		Props.place(self, d, "ph/wooden_crate_01", p + Vector3(0, 0.35, 0), rr.randf_range(0, 360))
	Props.place(self, d, "ph/modular_industrial_pipes_01", Vector3(73.0, 0, -1.2), 0.0)
	Props.place(self, d, "ph/modular_pipes", Vector3(93.3, 0.02, 0.0), 90.0, 2.3)
	Props.place(self, d, "ph/security_camera_01", Vector3(80.5, 2.45, -1.2), 160.0)
	# cafe: chairs, some toppled; the till
	Props.place(self, d, "ph/CashRegister_01", rooms.till, 180.0)
	for e in [[Vector3(44.2, 0, -22.4), 30.0, 0.0], [Vector3(45.8, 0, -23.9), 200.0, 1.45], [Vector3(51.4, 0, -21.4), 120.0, 0.0],
			[Vector3(55.3, 0, -23.6), 260.0, 0.0], [Vector3(53.8, 0, -25.4), 10.0, -1.5], [Vector3(48.5, 0, -19.6), 80.0, 1.5]]:
		var h := Props.place(self, d, "ph/dining_chair_02", e[0], e[1])
		if h and absf(float(e[2])) > 0.1:
			h.rotation.z = e[2]
			h.position.y += 0.22
	# storeroom: racks of stock and the junk the tribe uses
	for z in [21.5, 27.5, 33.5]:
		var x := 63.0
		while x < 85.0:
			_rack(Vector3(x, 0, z))
			for lv in [0.05, 1.12, 2.2]:
				if rr.randf() < 0.5:
					Props.place(self, d, "ph/cardboard_box_01", Vector3(x + rr.randf_range(-0.5, 0.5), lv + 0.04, z), rr.randf_range(-20, 20))
				elif rr.randf() < 0.4:
					_rk.box(Vector3(x + rr.randf_range(-0.4, 0.4), lv + 0.04 + 0.3, z), Vector3(0.6, 0.6, 0.6), "l58_crate", GeoKit.ALL, false)
			x += 1.8
	for p in [Vector3(59.0, 0, 30.0), Vector3(59.0, 0, 31.0), Vector3(59.8, 0, 30.5), Vector3(59.0, 0, 32.0)]:
		Props.place(self, d, "ph/barrel_03", p, rr.randf_range(0, 360), 0.0, true)
	for p in [Vector3(66.0, 0, 38.8), Vector3(67.2, 0, 38.8), Vector3(68.4, 0, 38.9)]:
		Props.place(self, d, "kenney/furniture-kit/toilet", p, 180.0, 0.75)
	for i in 5:
		var t := Props.place(self, d, "ph/old_tyre", Vector3(75.0, 0.08 + i * 0.16, 38.6), 0.0)
		if t:
			t.rotation.x = PI * 0.5
			t.position.y += 0.3
	Props.place(self, d, "ph/vintage_suitcase", Vector3(72.0, 0, 38.7), 180.0)
	Props.place(self, d, "ph/vintage_suitcase", Vector3(72.2, 0.24, 38.7), 172.0)
	for p in [Vector3(79.0, 0, 38.5), Vector3(80.0, 0, 38.4)]:
		Props.place(self, d, "ph/SchoolChair_01", p, rr.randf_range(150, 210))
	Props.place(self, d, "ph/SchoolDesk_01", Vector3(82.0, 0, 38.6), 180.0, 0.0, true)
	if _rk:
		_rk.commit()
	var jk := kit("Junk")
	for i in 4:
		jk.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.25), Vector3(59.5, 1.0, 20.0 + i * 1.0)), Vector3(0.9, 1.9, 0.2), "l58_fabric", GeoKit.ALL, false)
	jk.box(Vector3(89.0, 0.95, 26.0), Vector3(0.8, 1.9, 1.0), "l58_vend")
	for i in 6:
		jk.box(Vector3(82.0 + (i % 3) * 0.32, 0.88 + int(i / 3) * 0.06, 38.6), Vector3(0.3, 0.06, 0.25), "l58_kit_red" if i % 2 == 0 else "l58_kit_blue", GeoKit.ALL, false)
	jk.commit()
	var lab := Label3D.new()
	lab.text = "1"
	lab.font_size = 160
	lab.pixel_size = 0.004
	lab.modulate = Color(0.75, 0.04, 0.03)
	lab.outline_size = 0
	lab.position = RM.RED_CRATE + Vector3(-0.42, 0.42, 0)
	lab.rotation.y = -PI * 0.5
	add_child(lab)
	for e in [[Vector3(61.0, 2.0, 30.5), "CHLORINE"], [Vector3(30.1, 2.4, 0.0), "THE CORRIDORS"]]:
		var l := Label3D.new()
		l.text = e[1]
		l.font_size = 40
		l.pixel_size = 0.005
		l.modulate = Color(0.25, 0.25, 0.25)
		l.position = e[0]
		l.rotation.y = PI * 0.5 if e[1] == "CHLORINE" else -PI * 0.5
		add_child(l)


var _rk: GeoKit


## A pallet-rack bay (1.8 m): steel uprights, orange beams, board shelves.
func _rack(c: Vector3) -> void:
	if _rk == null:
		_rk = kit("Racks")
	for sx in [-0.88, 0.88]:
		for sz in [-0.38, 0.38]:
			_rk.box(c + Vector3(sx, 1.6, sz), Vector3(0.06, 3.2, 0.06), "l58_vend", GeoKit.ALL, false)
	for lv in [0.05, 1.12, 2.2, 3.1]:
		_rk.box(c + Vector3(0, lv, 0), Vector3(1.76, 0.04, 0.78), "l58_pallet", GeoKit.ALL, false)
		for sz in [-0.38, 0.38]:
			_rk.box(c + Vector3(0, lv - 0.06, sz), Vector3(1.8, 0.08, 0.05), "l58_kit_red", GeoKit.ALL, false)
	_rk.box(c + Vector3(0, 1.6, 0), Vector3(1.8, 3.2, 0.8), "l58_vend", 0)


func _lights() -> void:
	for w in park.windows:
		var c: Vector3 = w
		var inward := Vector3(0, 0, 1) if c.z < -20.0 else Vector3(1, 0, 0)
		lights.add_anchor(c + inward * 3.0 + Vector3(0, -1.5, 0), Color(0.97, 0.98, 1.0), 2.6, 18.0)
	for p in [Vector3(-12.0, 8.0, 6.0), Vector3(8.0, 8.0, 10.0), Vector3(20.0, 8.0, -4.0)]:
		lights.add_anchor(p, Color(0.95, 0.96, 1.0), 1.4, 20.0)
	for p in [Vector3(35.0, 2.4, 0.0), Vector3(76.0, 2.4, 0.0), Vector3(50.0, 2.4, -11.0), Vector3(70.0, 2.4, 8.0)]:
		lights.add_anchor(p, Color(1.0, 0.94, 0.82), 1.2, 7.0)
	lights.add_anchor(Vector3(58.0, 2.4, 0.0), Color(1.0, 0.94, 0.82), 1.0, 6.0, 0.6)
	lights.add_anchor(Vector3(60.0, 1.6, 1.0), Color(0.95, 0.97, 1.0), 1.0, 5.0)
	lights.add_anchor(Vector3(49.0, 2.7, -24.0), Color(1.0, 0.85, 0.6), 0.6, 7.0, 0.7)
	lamp_ai = lights.add_anchor(rooms.lamp_pos, Color(1.0, 0.8, 0.55), 0.0, 6.0)
	for p in rooms.store_panels:
		store_ai.append(lights.add_anchor(p, Color(0.93, 0.97, 1.0), 2.0, 12.0))


func _presences() -> void:
	# the Smiler: two eyes and a grin, nothing else, always facing you
	var img := Image.create(96, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for e in [Vector2(30, 20), Vector2(66, 20)]:
		for y in 12:
			for x in 18:
				if pow((x - 9.0) / 9.0, 2) + pow((y - 6.0) / 6.0, 2) < 1.0:
					img.set_pixel(int(e.x) + x - 9, int(e.y) + y - 6, Color(1, 1, 1, 1))
	for x in range(14, 82):
		var t := (x - 48.0) / 34.0
		var yc := 40.0 + 12.0 * (1.0 - t * t)
		for y in range(int(yc) - 3, int(yc) + 3):
			if y > 34 - int(4.0 * (1.0 - t * t)):
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = Color(1.4, 1.4, 1.35)
	m.no_depth_test = false
	smiler = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 0.6)
	smiler.mesh = qm
	smiler.material_override = m
	smiler.visible = false
	add_child(smiler)
	# a Window entity: a tall dark shape against the white void
	window_fig = Node3D.new()
	var wm := MatLib.standard(Color(0.02, 0.02, 0.025), 0.9)
	for part in [[Vector3(0, 1.3, 0), Vector3(0.5, 2.6, 0.1)], [Vector3(0, 2.85, 0), Vector3(0.36, 0.5, 0.1)], [Vector3(-0.42, 1.55, 0), Vector3(0.12, 2.1, 0.1)], [Vector3(0.42, 1.55, 0), Vector3(0.12, 2.1, 0.1)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = part[1]
		mi.mesh = bm
		mi.material_override = wm
		mi.position = part[0]
		window_fig.add_child(mi)
	window_fig.visible = false
	add_child(window_fig)


func _sounds() -> void:
	sound.bed("room_tone", {"seconds": 6.0, "cutoff": 260.0, "rumble": 0.15}, -28.0)
	sound.oneshot("creak", {"freq": 90.0}, 18.0, 45.0, 14.0, "[a faded slide tube groans]", -14.0)
	sound.emitter("creak", Vector3(10.0, 5.0, -14.0), {"freq": 70.0}, -20.0, 18.0)
	for p in [Vector3(35.0, 2.3, 0.0), Vector3(76.0, 2.3, 0.0), Vector3(50.0, 2.3, -11.0)]:
		sound.emitter("fluorescent_hum", p, {}, -20.0, 7.0)
	sound.emitter("drip", Vector3(55.0, 2.8, -27.0), {"freq": 900.0}, -16.0, 9.0)
	sound.emitter("pipe_clank", RM.PIPES, {"f": 210.0}, -20.0, 10.0)
	for p in [Vector3(67.0, 5.4, 23.0), Vector3(81.0, 5.4, 31.0)]:
		sound.emitter("fluorescent_hum", p, {"base": 120.0, "rasp": 0.6}, -8.0, 22.0)


func _notes() -> void:
	add_note("l58_bntg", "B.N.T.G. notice: Tegan Fruit Fairtrade", "THIS SEGMENT OF THE CORRIDORS IS SECURED BY THE B.N.T.G.\nBorders are built from boards, pallets and pipe. Past them the corridors are UNSAFE.\n\n- The floors are metal plate. Every step carries. Noise brings Smilers and Dullers.\n- If you find a lamp, switch it on.\n- Lockers are watched. Thieves are prosecuted.\n- Cafe Tegan and the Storage Facility are this way. The starting Waterpark is behind you.", Vector3(81.4, 1.45, -1.2), Vector3(0.6, 0.6, 0.15), false)
	add_note("l58_tegan", "Field card: Tegan Fruit (Research Team Newportal)", "Grows only on Tegan Trees, which shoot up out of flat blue plastic in the Waterparks. Lemon-sized, purple, plastic to the touch, soft as a banana inside, dull yellow. Tastes of mild, sour mint.\n\nStages, with no growth in between:\n1. Sprouting (about 6 days): a small green leaf. Inedible; can make you ill.\n2. Pink berries (11 days). Still not ready.\n3. Ripe, purple (7 days). Skin turns smooth and plasticky; ageing seems to stop.\n4. Elder: the effects reverse. Makes you old, ill, weak in the bones.", Vector3(-25.5, 0.82, 16.6))
	add_note("l58_store", "Scrawled on a crate lid", "STOREROOM LIGHTS GO OUT. Shortest anyone timed: about 4 seconds. Longest: about 5 hours 20 minutes. Keep a torch on you.\n\nLids aren't sealed. Almond Water, Lucky O Milk, Greasy Marshmallows, normal food.\n\nIf you see a crate with a red 1 painted on it: that's the one that took our lot. Opened it and got pulled in like a black hole. M.E.G. Base Alpha found them later, not a scratch on them.", Vector3(62.6, 0.86, 37.1))


func _interactions() -> void:
	for i in rooms.vending.size():
		add_interactable(rooms.vending[i], Vector3(1.0, 1.6, 1.2), "Type a number on the keypad", _vend.bind(i))
	add_interactable(rooms.till + Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.7), "Open the till", func():
		Overlay.show_note("Till", "Unlocked, the drawer jammed half open. Coins and notes from all over the Frontrooms: pounds, dollars, euros, yen, a few you don't recognise. None of it buys anything here."))
	for i in rooms.supply.size():
		add_interactable(rooms.supply[i], Vector3(0.9, 0.5, 0.9), "Lift the lid", _supply.bind(i))
	add_interactable(rooms.lamp_pos, Vector3(0.6, 0.8, 0.6), "Switch the lamp", _lamp)
	if not park.tegan.is_empty():
		var t: Vector3 = park.tegan[0]
		add_interactable(t + Vector3(0, -1.6, 0), Vector3(2.4, 1.6, 2.4), "Pick a Tegan Fruit", _fruit)


func _exits_and_arrivals() -> void:
	add_exit("L058>L001#2", "interact", RM.RED_CRATE + Vector3(-0.8, 0.9, 0), Vector3(1.4, 1.8, 1.6), "Open the crate with the red 1")
	var bm: Vector3 = park.black_mouth
	add_exit("L058>L058_1#1", "noclip", bm - park.black_dir * 0.6, Vector3(1.4, 1.4, 1.4), "Push into the black slide")
	add_exit("L058>EXT#3", "noclip", RM.PIPES, Vector3(1.2, 2.0, 1.6), "Push into the pipes")
	add_arrival("start", START, -19.0)


# ---------------------------------------------------------------- mechanics

func _prep_dark() -> void:
	await get_tree().process_frame


func _vend(i: int) -> void:
	var key := "vend%d" % i
	var stock: Array = SaveService.flag(stable_id, key, [10, 10, 10, 10])
	var empty_since: float = float(SaveService.flag(stable_id, key + "_empty", 0.0))
	var now := Time.get_unix_time_from_system()
	if empty_since > 0.0:
		var wait := 3600.0 * (3.0 + float(hash([i, int(empty_since)]) % 165))
		if now - empty_since > wait:
			stock = [10, 10, 10, 10]
			SaveService.set_flag(stable_id, key + "_empty", 0.0)
	var pick := -1
	for j in 4:
		if int(stock[j]) > 0 and (pick < 0 or int(stock[j]) > int(stock[pick])):
			pick = j
	if pick < 0:
		Overlay.show_note("Vending machine", "The keypad beeps. Nothing moves. Every coil is empty.\n\nThey restock when they feel like it: hours, sometimes a week.")
		return
	stock[pick] = int(stock[pick]) - 1
	SaveService.set_flag(stable_id, key, stock)
	if stock.all(func(v): return int(v) <= 0):
		SaveService.set_flag(stable_id, key + "_empty", now)
	SaveService.add_item(str(ITEMS[pick]).to_lower().replace(" ", "_"))
	if player:
		player.heal(10.0)
	Overlay.show_note("Vending machine", "The touchscreen is cracked and dead, but the keypad on the side still works. No price, no coin slot. Something drops: %s.\n\nLeft: %d Almond Water, %d crisps, %d Greasy Marshmallows, %d Warpberries." % [ITEMS[pick], stock[0], stock[1], stock[2], stock[3]])


func _supply(i: int) -> void:
	if SaveService.flag(stable_id, "crate%d" % i, false):
		Overlay.subtitle("[already emptied]", 2.0)
		return
	SaveService.set_flag(stable_id, "crate%d" % i, true)
	var got: String = ["a bottle of Almond Water", "a carton of Lucky O Milk", "a bag of Greasy Marshmallows"][i % 3]
	SaveService.add_item(["almond_water", "lucky_o_milk", "greasy_marshmallows"][i % 3])
	Overlay.subtitle("[the lid lifts straight off: %s]" % got, 3.0)


func _lamp() -> void:
	lamp_on = not lamp_on
	lights.anchors[lamp_ai]["energy"] = 1.1 if lamp_on else 0.0
	Overlay.subtitle("[click. Warm light.]" if lamp_on else "[click]", 2.0)


func fruit_stage(day: int) -> int:
	var dd := day % 30
	return 0 if dd < 6 else (1 if dd < 17 else (2 if dd < 24 else 3))


func _fruit() -> void:
	var st := fruit_stage(int(Time.get_unix_time_from_system() / 86400.0))
	match st:
		0:
			Overlay.subtitle("[only small green leaves hang among the blue. Not fruit yet.]", 3.5)
		1:
			Overlay.subtitle("[pink berries, hard and unripe. Not yet.]", 3.5)
		2:
			SaveService.add_item("tegan_fruit")
			if player:
				player.heal(20.0)
			Overlay.subtitle("[purple, plastic-skinned, soft inside. Sour mint. Your skin feels smoother.]", 4.0)
		_:
			if player:
				player.hurt(12.0, "Elder Tegan Fruit")
			Overlay.subtitle("[wrinkled elder berries. Your stomach turns; your joints ache.]", 4.0)


func _region(p: Vector3) -> String:
	if p.x < PK.HX + 0.2:
		return "hall"
	if RM.CAFE.grow(0.2).has_point(Vector2(p.x, p.z)):
		return "cafe"
	if RM.STORE.grow(0.1).has_point(Vector2(p.x, p.z)):
		return "store"
	return "corridor"


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var rg := _region(p)
	if rg != region:
		if rg == "cafe" and not said.has("bell"):
			said["bell"] = true
			sound.play_at("pipe_clank", {"f": 1700.0}, Vector3(50.0, 2.3, -17.8), -16.0, "[a faded bell above the door gives a dull clink]")
		region = rg
	var amb: float = {"hall": 0.55, "corridor": 0.05, "cafe": 0.04, "store": 0.0 if blackout else 0.28}[rg]
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, amb, minf(1.0, delta * 2.5))
	environment.fog_density = lerpf(environment.fog_density, 0.0018 if rg == "hall" else 0.03, minf(1.0, delta * 2.0))
	environment.fog_light_color = Color(0.78, 0.8, 0.8) if rg == "hall" else Color(0.02, 0.02, 0.02)
	if SessionState.is_qa():
		return
	_storeroom(delta)
	_noise(delta, p, rg)
	_windows(delta, p)
	if p.y > PK.P1 - 0.2 and p.x > 3.0 and p.x < 17.0 and p.z < -8.0:
		creak_t -= delta
		if creak_t <= 0.0:
			creak_t = rng.randf_range(10.0, 25.0)
			sound.play_at("creak", {"freq": 60.0}, p + Vector3(0, -1, 0), -6.0, "[the beams under the deck creak and settle]")


func _storeroom(delta: float) -> void:
	blk_t -= delta
	if blk_t > 0.0:
		return
	blackout = not blackout
	blk_t = rng.randf_range(4.0, 45.0) if blackout else rng.randf_range(30.0, 90.0)
	(MatLib.get_mat("l58_fluoro") as ShaderMaterial).set_shader_parameter("energy", 0.0 if blackout else 2.8)
	for ai in store_ai:
		lights.anchors[ai]["energy"] = 0.0 if blackout else 2.0
	if region == "store":
		Overlay.subtitle("[the fluorescents die. Total darkness.]" if blackout else "[the tubes stutter back on, loud]", 3.0)


func _noise(delta: float, p: Vector3, rg: String) -> void:
	var v := player.velocity
	v.y = 0.0
	var spd := v.length()
	if rg == "corridor" and spd > 0.3:
		alert += delta * 0.03 * (spd / 3.1) * (2.0 if spd > 4.0 else 1.0)
	else:
		alert = maxf(0.0, alert - delta * (0.06 if spd < 0.3 else 0.02))
	if alert > 0.5 and not said.has("clank"):
		said["clank"] = true
		Overlay.subtitle("[your steps ring off the metal plates, far down the corridor]", 3.5)
	if not smiler_on and alert >= 1.0 and rg == "corridor":
		var fwd := -player.global_transform.basis.z
		fwd.y = 0.0
		var axis := Vector3(1, 0, 0) if absf(fwd.x) > absf(fwd.z) else Vector3(0, 0, 1)
		axis *= signf(fwd.dot(axis))
		smiler.global_position = p + axis * 16.0 + Vector3(0, 1.6, 0)
		smiler.visible = true
		smiler_on = true
		Overlay.subtitle("[a wide white grin opens in the dark ahead]", 3.5)
	if smiler_on:
		if alert < 0.35 or rg != "corridor":
			smiler.visible = false
			smiler_on = false
			said.erase("clank")
			Overlay.subtitle("[the grin closes. It has lost you.]", 3.0)
			return
		smiler.global_position = smiler.global_position.move_toward(p + Vector3(0, 1.6, 0), delta * 1.9)
		if smiler.global_position.distance_to(p + Vector3(0, 1.6, 0)) < 1.3:
			player.hurt(30.0, "Smiler")
			Overlay.glitch(0.8)
			smiler.visible = false
			smiler_on = false
			alert = 0.2


func _windows(delta: float, p: Vector3) -> void:
	if window_show > 0.0:
		window_show -= delta
		if window_show <= 0.0:
			window_fig.visible = false
		return
	window_t -= delta
	if window_t > 0.0 or region != "hall":
		return
	window_t = rng.randf_range(70.0, 160.0)
	var w: Vector3 = park.windows[rng.randi() % park.windows.size()]
	var out := Vector3(0, 0, -1) if w.z < -20.0 else Vector3(-1, 0, 0)
	window_fig.global_position = w + out * 1.0 + Vector3(0, -2.0, 0)
	window_fig.look_at(window_fig.global_position - out, Vector3.UP)
	window_fig.visible = true
	window_show = 5.0
	Overlay.subtitle("[something stands in the white beyond a window. Keep your distance.]", 4.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "three sourced exits (red 1 crate, black slide, exposed pipes)", "ok": exits.size() == 3})
	var space := get_world_3d().direct_space_state
	var pool := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-8.0, 2.0, 5.0), Vector3(-8.0, -3.0, 5.0), 1))
	out.append({"what": "leisure pool is dry and no deeper than 0.5 m", "ok": not pool.is_empty() and float(pool["position"].y) >= -0.51 and get_tree().get_nodes_in_group("water").is_empty()})
	var deck := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(14.0, 10.0, -15.0), Vector3(14.0, 6.0, -15.0), 1))
	out.append({"what": "slide tower top deck is walkable (8 m)", "ok": not deck.is_empty() and absf(float(deck["position"].y) - PK.P2) < 0.1})
	out.append({"what": "Tegan Fruit stages follow 6/11/7-day cycle", "ok": fruit_stage(0) == 0 and fruit_stage(6) == 1 and fruit_stage(17) == 2 and fruit_stage(24) == 3})
	blk_t = 0.0
	_storeroom(0.0)
	var dark_ok: bool = blackout and float(lights.anchors[store_ai[0]]["energy"]) == 0.0
	blk_t = 0.0
	_storeroom(0.0)
	out.append({"what": "storeroom blackout switches its fluorescents off and on", "ok": dark_ok and not blackout})
	out.append({"what": "four slides including the black one", "ok": park.slides.size() == 4})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
