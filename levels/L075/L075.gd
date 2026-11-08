extends LevelBase
## Level 75 "Liminality" / the Sandrooms (Backrooms Wikidot rev 26, accessed 2026-11-04;
## Br Miller, CC BY-SA 3.0). Dossier: docs/canon/levels/L075.md.
##
## PLAN (read -> design):
## - SOURCE: a complex of corridors and rooms, most of the floor under a thick layer of
##   yellow sand; walls painted blue, cream and (rarer) red, cracked and peeling to
##   plaster or corroded steel; ceiling fixtures all dead; beams of a sunlight-like glow
##   from arbitrary spots in the ceiling and walls light most rooms.
##   -> a seeded 6 x 5 complex of 9 m cells (rooms, and corridors with lower ceilings),
##   spanning tree plus short loops; floors split 0.54 m apart with three sand-covered
##   steps at the doorways (natural variation; the page states no storeys); windows
##   between rooms that are not joined; outer doorways choked to the lintel with sand.
## - SOURCE: dry, 15 C, perpetual soothing rain heard from the ceiling with no water
##   anywhere; breaking into the ceiling reveals impenetrable voidstone -> a rain bed,
##   one place where someone broke the plaster to a black glassy layer.
## - SOURCE: devoid of entities, peaceful; toys embedded in the sand (shovels, buckets,
##   toy cars, dolls); occasional deteriorated furniture; nothing else.
## - SOURCE (signature): with no wind or water, marks in the sand stay for decades;
##   footprints mostly children's, hand patterns, dug holes, sandcastle attempts, toy-car
##   tracks -> old marks everywhere, and YOUR prints are added as you walk and stay for the
##   visit (bounded ring). Digging where something pokes out finds a toy; the hole stays.
## - SOURCE exit: a door in a room with no sand on the floor, or a window, sends you to the
##   level you were trying to reach -> one sand-free room on the far side with an ordinary
##   door and a window (EXT release boundary: the intended level is not specified).
## - Arrivals: start in a sandy dead-end corridor (testimony: "some sandy corridor");
##   from_L008 from the same corridor (L008>L075#4, tight passages).
## - ABSENT: entities, hazards, food, water, electric light, bases, regeneration in-session.

const Plan := preload("res://levels/L075/L075_plan.gd")
const Dress := preload("res://levels/L075/L075_dress.gd")
const MAX_PRINTS := 1200

var P
var D
var info: Dictionary = {}
var dig_spots: Array = []         # [{pos, found, node}]
var toys_found := 0
var player_prints: MultiMesh
var _print_i := 0
var _print_n := 0
var _last_step := Vector3(1e6, 0, 1e6)
var _left := false
var _said := {}
var _rain: AudioStreamPlayer


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.42
	rules["reverb_wet"] = 0.1
	indoor_env(Color(0.96, 0.86, 0.68), 0.32, Color(0.7, 0.62, 0.48), 0.012)
	environment.tonemap_exposure = 1.05
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	environment.adjustment_contrast = 1.04
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 0.85
	_materials()
	P = Plan.new(rng)
	P.plan()
	var k := kit("Sandrooms")
	var sandk := kit("Sand")
	info = P.build(k, sandk)
	D = Dress.new(self, P)
	lights.setup(12, 1)
	lights.max_distance = 30.0
	_stairs(k)
	_choked(sandk)
	_windows(k)
	_trim(k)
	_rooms(k, sandk)
	_exit_room(k)
	k.commit()
	sandk.commit()
	var n := D.commit_prints()
	_player_print_layer()
	_sounds()
	var sc: Vector3 = P.centre(P.start)
	add_arrival("start", Vector3(P.start.x * P.S + 1.4, P.floor_y(P.start) + 0.06, sc.z), -90.0)
	add_arrival("from_L008", Vector3(P.start.x * P.S + 2.6, P.floor_y(P.start) + 0.06, sc.z + 0.4), -90.0)
	add_landmark("Sandy dead-end corridor", sc)
	add_landmark("The room with no sand", P.centre(P.exit_cell))
	set_meta("old_prints", n)
	_shots()


func _materials() -> void:
	MatLib.define("l75_sand", {"albedo_a": Color(0.88, 0.74, 0.44), "albedo_b": Color(0.8, 0.66, 0.38), "pattern": 13,
		"pattern_scale": Vector2(0.6, 0.6), "pattern_strength": 0.35, "pattern_color": Color(0.72, 0.58, 0.32), "noise_scale": 0.45,
		"roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 0.9}, "")
	MatLib.define("l75_sand_dark", {"albedo_a": Color(0.66, 0.53, 0.3), "albedo_b": Color(0.6, 0.48, 0.27), "roughness_a": 1.0}, "")
	MatLib.define("l75_sand_pit", {"albedo_a": Color(0.42, 0.33, 0.18), "albedo_b": Color(0.36, 0.28, 0.15), "noise_scale": 3.0, "roughness_a": 1.0}, "")
	MatLib.define("l75_sand_castle", {"albedo_a": Color(0.84, 0.7, 0.42), "albedo_b": Color(0.76, 0.62, 0.36), "noise_scale": 5.0,
		"bump_strength": 1.6, "roughness_a": 1.0}, "")
	var paints := {"blue": [Color(0.42, 0.6, 0.72), Color(0.36, 0.54, 0.66)], "cream": [Color(0.86, 0.82, 0.68), Color(0.8, 0.76, 0.62)],
		"red": [Color(0.66, 0.24, 0.2), Color(0.58, 0.2, 0.17)]}
	var under := {"p": Color(0.82, 0.8, 0.74), "s": Color(0.38, 0.22, 0.13)}
	for key in paints.keys():
		for u in under.keys():
			MatLib.define("l75_%s_%s" % [key, u], {"albedo_a": paints[key][0], "albedo_b": paints[key][1], "noise_scale": 0.8,
				"peel_amount": 0.5 if u == "p" else 0.42, "peel_color": under[u], "stain_amount": 0.4, "stain_color": Color(0.52, 0.45, 0.34),
				"stain_scale": 0.25, "grime_height": 0.4, "grime_color": Color(0.6, 0.5, 0.32), "roughness_a": 0.7, "roughness_b": 0.92,
				"bump_strength": 0.7}, "")
	MatLib.define("l75_ceiling", {"albedo_a": Color(0.8, 0.78, 0.72), "albedo_b": Color(0.72, 0.7, 0.64), "noise_scale": 0.6,
		"stain_amount": 0.45, "stain_color": Color(0.6, 0.52, 0.38), "peel_amount": 0.15, "peel_color": Color(0.55, 0.53, 0.5)}, "")
	MatLib.define("l75_ceiling_low", {"albedo_a": Color(0.76, 0.74, 0.68), "albedo_b": Color(0.7, 0.68, 0.62), "pattern": 7,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.55, 0.53, 0.48), "stain_amount": 0.4,
		"stain_color": Color(0.58, 0.5, 0.36)}, "")
	MatLib.define("l75_floor", {"albedo_a": Color(0.55, 0.5, 0.42), "albedo_b": Color(0.48, 0.44, 0.37), "pattern": 15,
		"pattern_color": Color(0.7, 0.66, 0.58), "pattern_strength": 0.4, "noise_scale": 1.5, "roughness_a": 0.6, "roughness_b": 0.85}, "")
	MatLib.define("l75_clean", {"albedo_a": Color(0.72, 0.7, 0.64), "albedo_b": Color(0.66, 0.64, 0.58), "pattern": 15,
		"pattern_color": Color(0.5, 0.47, 0.42), "pattern_strength": 0.45, "noise_scale": 1.2, "roughness_a": 0.35, "roughness_b": 0.6,
		"stain_amount": 0.15}, "")
	MatLib.define("l75_trim", {"albedo_a": Color(0.5, 0.42, 0.32), "albedo_b": Color(0.44, 0.36, 0.27), "roughness_a": 0.6,
		"stain_amount": 0.3, "peel_amount": 0.3, "peel_color": Color(0.7, 0.66, 0.58)}, "")
	MatLib.define("l75_frame", {"albedo_a": Color(0.84, 0.82, 0.76), "albedo_b": Color(0.78, 0.76, 0.7), "roughness_a": 0.55,
		"peel_amount": 0.35, "peel_color": Color(0.5, 0.42, 0.32), "stain_amount": 0.3}, "")
	MatLib.define("l75_door", {"albedo_a": Color(0.5, 0.62, 0.7), "albedo_b": Color(0.45, 0.56, 0.64), "pattern": 3,
		"pattern_scale": Vector2(2.1, 0.5), "grout_width": 0.004, "grout_color": Color(0.3, 0.36, 0.4), "peel_amount": 0.3,
		"peel_color": Color(0.55, 0.45, 0.32), "roughness_a": 0.6}, "")
	MatLib.define("l75_voidstone", {"albedo_a": Color(0.02, 0.02, 0.025), "albedo_b": Color(0.05, 0.05, 0.06), "noise_scale": 3.0,
		"roughness_a": 0.08, "roughness_b": 0.25, "metallic_value": 0.3, "bump_strength": 1.8}, "")
	MatLib.define("l75_rust", {"albedo_a": Color(0.4, 0.24, 0.14), "albedo_b": Color(0.3, 0.18, 0.1), "metallic_value": 0.4,
		"noise_scale": 3.0, "roughness_a": 0.8, "bump_strength": 1.2}, "")
	MatLib.define("l75_fixture", {"albedo_a": Color(0.78, 0.76, 0.7), "albedo_b": Color(0.7, 0.68, 0.62), "roughness_a": 0.5,
		"stain_amount": 0.5, "stain_color": Color(0.5, 0.42, 0.26)}, "")
	MatLib.register("l75_tube_dead", MatLib.panel(Color(0.6, 0.6, 0.56), 0.04))
	MatLib.register("l75_glare", MatLib.panel(Color(1.0, 0.9, 0.7), 5.0))
	MatLib.register("l75_window_light", MatLib.panel(Color(1.0, 0.93, 0.8), 2.4))
	for t in [["red", Color(0.78, 0.12, 0.1)], ["blue", Color(0.12, 0.35, 0.78)], ["yellow", Color(0.95, 0.75, 0.1)], ["green", Color(0.15, 0.6, 0.25)]]:
		MatLib.define("l75_toy_" + str(t[0]), {"albedo_a": t[1], "albedo_b": (t[1] as Color).darkened(0.12), "roughness_a": 0.4,
			"roughness_b": 0.55, "stain_amount": 0.45, "stain_color": Color(0.75, 0.62, 0.38), "noise_scale": 4.0}, "")
	MatLib.define("l75_toy_glass", {"albedo_a": Color(0.25, 0.32, 0.4), "albedo_b": Color(0.2, 0.26, 0.32), "roughness_a": 0.2}, "")
	MatLib.define("l75_toy_tyre", {"albedo_a": Color(0.08, 0.08, 0.08), "albedo_b": Color(0.1, 0.1, 0.1)}, "")
	MatLib.define("l75_toy_skin", {"albedo_a": Color(0.86, 0.7, 0.6), "albedo_b": Color(0.8, 0.64, 0.55), "stain_amount": 0.4,
		"stain_color": Color(0.7, 0.58, 0.4)}, "")
	MatLib.define("l75_toy_dress", {"albedo_a": Color(0.62, 0.4, 0.62), "albedo_b": Color(0.55, 0.34, 0.55), "pattern": 5,
		"pattern_scale": Vector2(0.02, 0.02), "pattern_color": Color(0.9, 0.85, 0.8), "pattern_strength": 0.5}, "")


# ------------------------------------------------------------------ geometry

func _stairs(k: GeoKit) -> void:
	for s in info["stairs"]:
		k.stairs(s["start"], s["dir"], float(s["w"]) - 0.05, float(s["rise"]), 3, "l75_sand", 0.3)


## Outer doorways choked to the lintel with sand: the complex goes on, buried.
func _choked(sandk: GeoKit) -> void:
	for c in info["choked"]:
		var p: Vector3 = c["pos"]
		var n: Vector3 = c["n"]
		var w: float = c["w"]
		var side := Vector3(-n.z, 0, n.x)
		sandk.box_xf(Transform3D(Basis(side, Vector3.UP, side.cross(Vector3.UP)), p + n * 0.6 + Vector3.UP * 1.3), Vector3(w + 0.1, 2.7, 1.0), "l75_sand", GeoKit.ALL, true)
		# a slope of sand spilling into the room, steep near the doorway
		var foot := p - n * 2.6
		foot.y = p.y + 0.02
		var head := p - n * 0.05 + Vector3.UP * 1.5
		sandk.ramp(foot, head, w + 0.9, 1.4, "l75_sand", "sand")


func _windows(k: GeoKit) -> void:
	for w in info["windows"]:
		var p: Vector3 = w["pos"]
		var n: Vector3 = w["n"]
		var side := Vector3(-n.z, 0, n.x)
		var b := Basis(side, Vector3.UP, side.cross(Vector3.UP))
		# a plain painted frame and a cracked sill
		k.box_xf(Transform3D(b, p + Vector3.UP * 0.02), Vector3(1.9, 0.05, 0.32), "l75_frame", GeoKit.ALL, false)


func _trim(k: GeoKit) -> void:
	# skirting along room walls, door frames on every doorway
	for dr in info["doors"]:
		var p: Vector3 = dr["pos"]
		var n: Vector3 = dr["n"]
		var w: float = dr["w"]
		if w > 2.4:
			continue
		var side := Vector3(-n.z, 0, n.x)
		var b := Basis(side, Vector3.UP, side.cross(Vector3.UP))
		for s in [-1.0, 1.0]:
			k.box_xf(Transform3D(b, p + side * s * (w * 0.5 + 0.05) + Vector3.UP * 1.12), Vector3(0.1, 2.25, 0.3), "l75_frame", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, p + Vector3.UP * 2.3), Vector3(w + 0.2, 0.1, 0.3), "l75_frame", GeoKit.ALL, false)


func _rooms(k: GeoKit, sandk: GeoKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "rooms"])
	var void_cell := Vector2i(-1, -1)
	var cand: Array = []
	for c in P.cells.keys():
		if P.cells[c]["kind"] == "room" and c != P.exit_cell and c != P.start:
			cand.append(c)
	cand.sort()
	if not cand.is_empty():
		void_cell = cand[r.randi() % cand.size()]
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	for c in P.cells.keys():
		var cell: Dictionary = P.cells[c]
		var y: float = P.floor_y(c)
		var rect: Rect2 = P.walk_rect(c)
		var cc: Vector3 = P.centre(c)
		var corridor: bool = cell["kind"] == "corridor"
		var clean: bool = cell.get("clean", false)
		var top: float = P.ceil_y(c)
		# dead ceiling fixtures
		if corridor:
			for t in [-2.5, 2.5]:
				var fp := cc + (Vector3(t, 0, 0) if cell["axis"] == "x" else Vector3(0, 0, t))
				_dead_tube(k, Vector3(fp.x, top, fp.z), cell["axis"] == "x")
		else:
			_dead_tube(k, Vector3(cc.x - 1.6, top, cc.z), false)
			_dead_tube(k, Vector3(cc.x + 1.6, top, cc.z), false)
		# beams of sunlight-like glow from arbitrary ceiling or wall spots (most rooms)
		var nb := 0 if r.randf() < (0.25 if corridor else 0.12) else (1 if corridor or r.randf() < 0.55 else 2)
		if clean:
			nb = 1
		for i in nb:
			var dst := Vector3(r.randf_range(rect.position.x + 0.6, rect.end.x - 0.6), y + 0.05, r.randf_range(rect.position.y + 0.6, rect.end.y - 0.6))
			var src: Vector3
			var sn: Vector3
			if corridor or r.randf() < 0.6:
				src = dst + Vector3(r.randf_range(-1.6, 1.6), 0, r.randf_range(-1.6, 1.6))
				src.x = clampf(src.x, rect.position.x + 0.3, rect.end.x - 0.3)
				src.z = clampf(src.z, rect.position.y + 0.3, rect.end.y - 0.3)
				src.y = top - 0.01
				sn = Vector3.DOWN
			else:
				var wall := r.randi() % 4
				var wx := [c.x * P.S + 0.11, (c.x + 1) * P.S - 0.11]
				var wz := [c.y * P.S + 0.11, (c.y + 1) * P.S - 0.11]
				var hy := minf(top - 0.6, y + r.randf_range(2.6, 3.4))
				match wall:
					0: src = Vector3(wx[0], hy, dst.z); sn = Vector3.RIGHT
					1: src = Vector3(wx[1], hy, dst.z); sn = Vector3.LEFT
					2: src = Vector3(dst.x, hy, wz[0]); sn = Vector3.BACK
					_: src = Vector3(dst.x, hy, wz[1]); sn = Vector3.FORWARD
			D.beam(src, dst, r.randf_range(0.22, 0.38), sn)
			lights.add_anchor(dst + Vector3(0, 0.7, 0), Color(1.0, 0.85, 0.62), 1.5, 6.5, 0.0)
			lights.add_anchor(src + sn * 0.6, Color(1.0, 0.88, 0.7), 0.5, 3.5, 0.0)
		if clean:
			continue
		# children's footprints criss-crossing between the doorways, older adult ones fewer
		var doors: Array = []
		for dr in info["doors"]:
			if dr["a"] == c or dr["b"] == c:
				doors.append(dr["pos"])
		for i in doors.size():
			for j in range(i + 1, doors.size()):
				D.trail(doors[i], doors[j], r, true)
		if doors.size() == 1:
			D.trail(doors[0], Vector3(cc.x + r.randf_range(-2, 2), y, cc.z + r.randf_range(-2, 2)), r, true)
		if r.randf() < 0.35 and doors.size() >= 2:
			D.trail(doors[0], doors[doors.size() - 1], r, false)
		if corridor:
			continue
		# play: patterns of small hands, holes, castles, car tracks, toys
		var play := r.randf() < 0.65
		if play:
			for i in 1 + r.randi() % 3:
				var hp := _spot(rect, y, r)
				D.hand_pattern(hp, r)
			if r.randf() < 0.55:
				D.castle(_spot(rect, y, r), r)
			if r.randf() < 0.5:
				D.hole(_spot(rect, y, r), r.randf_range(0.18, 0.3))
			if r.randf() < 0.45:
				D.car_tracks(sandk, _spot(rect, y, r), r)
			for i in r.randi() % 3:
				var kinds := ["bucket", "shovel", "car", "doll"]
				D.toy(kinds[r.randi() % 4], _spot(rect, y, r), r.randf() * TAU, r, r.randf_range(0.02, 0.07))
			if dig_spots.size() < 9 and r.randf() < 0.6:
				_dig_spot(_spot(rect, y, r), r)
		# sand drifts in corners against the walls
		for i in r.randi() % 3:
			var corner := Vector3(rect.position.x if r.randf() < 0.5 else rect.end.x, y, rect.position.y if r.randf() < 0.5 else rect.end.y)
			var into := (Vector3(cc.x, y, cc.z) - corner).normalized()
			var head := corner - into * 0.5 + Vector3.UP * r.randf_range(0.35, 0.7)
			var foot := corner + into * r.randf_range(1.4, 2.4)
			foot.y = y + 0.03
			sandk.ramp(foot, head, r.randf_range(1.6, 2.6), 0.8, "l75_sand", "sand")
		# occasional deteriorated furniture, half sunk
		if r.randf() < 0.32:
			var fid: String = ["ph/SchoolChair_01", "ph/wooden_bookshelf_worn", "ph/GreenChair_01", "ph/dining_chair_02", "ph/Sofa_01", "ph/SchoolDesk_01"][r.randi() % 6]
			var fp2 := Vector3(rect.position.x + 0.7, y - 0.06, r.randf_range(rect.position.y + 1.0, rect.end.y - 1.0))
			Props.place(self, props, fid, fp2, 90.0 + r.randf_range(-25, 25), 0.0, fid == "ph/wooden_bookshelf_worn" or fid == "ph/Sofa_01")
		if c == void_cell:
			_voidstone(k, Vector3(cc.x + 1.2, top, cc.z - 1.4))
	# a photograph half-buried in one room near the start
	var near := P.start + Vector2i(1, 0)
	var pc: Vector3 = P.centre(near)
	add_note("l75_photo", "A photograph, half in the sand",
		"A print of a sandy corridor: sky-blue and white paint, cracked, a beam of light on the floor. Someone has written on the back: 'Playlist for Exploring Liminality'. It feels like a place you went to as a child.",
		pc + Vector3(1.0, 0.1, 0.6), Vector3(0.5, 0.2, 0.5))


func _spot(rect: Rect2, y: float, r: RandomNumberGenerator) -> Vector3:
	return Vector3(r.randf_range(rect.position.x + 0.8, rect.end.x - 0.8), y, r.randf_range(rect.position.y + 0.8, rect.end.y - 0.8))


func _dead_tube(k: GeoKit, p: Vector3, along_x: bool) -> void:
	var sz := Vector3(1.25, 0.09, 0.3) if along_x else Vector3(0.3, 0.09, 1.25)
	k.box(p + Vector3(0, -0.05, 0), sz, "l75_fixture", GeoKit.ALL, false)
	k.panel(p + Vector3(0, -0.097, 0), sz.x - 0.12, sz.z - 0.12, "l75_tube_dead")


## Someone broke into the ceiling here: torn plaster and lath, and behind it voidstone.
func _voidstone(k: GeoKit, p: Vector3) -> void:
	k.box(p + Vector3(0, 0.02, 0), Vector3(1.1, 0.03, 0.8), "l75_voidstone", GeoKit.ALL, false)
	for i in 5:
		k.box(p + Vector3(-0.5 + i * 0.25, -0.03, 0.0), Vector3(0.04, 0.03, 0.9), "l75_trim", GeoKit.ALL, false)
	k.box(p + Vector3(0, -0.05, 0.47), Vector3(1.2, 0.06, 0.12), "l75_ceiling", GeoKit.ALL, false)
	# plaster rubble on the sand below
	var y: float = P.floor_y(P.cell_at(p)) + 0.06
	for i in 7:
		k.box_xf(Transform3D(Basis(Vector3.UP, i * 0.9), Vector3(p.x - 0.5 + i * 0.17, y, p.z + sin(i * 2.0) * 0.4)), Vector3(0.14, 0.04, 0.1), "l75_ceiling", GeoKit.ALL, false)
	add_note("l75_void", "A hole in the ceiling",
		"Someone broke through the plaster here. Behind it is a black, glassy stone that takes no mark at all. The rain sound seems to come from just above it.",
		Vector3(p.x, y + 0.4, p.z), Vector3(1.4, 1.2, 1.4), false)


func _dig_spot(p: Vector3, r: RandomNumberGenerator) -> void:
	var kinds := ["car", "bucket", "shovel", "doll"]
	var kind: String = kinds[dig_spots.size() % 4]
	# a small mound with a corner of plastic showing
	var mound := D.mi(Dress.cyl(0.12, 0.3, 0.09, 14), "l75_sand", p + Vector3(0, 0.09, 0))
	var peek := D.mi(Dress.boxm(Vector3(0.05, 0.05, 0.03)), Dress.PLASTIC[dig_spots.size() % 4], p + Vector3(0.06, 0.16, 0.02),
		Basis(Vector3(1, 0, 1).normalized(), 0.6))
	var spot := {"pos": p, "found": false, "kind": kind, "mound": mound, "peek": peek, "seed": r.randi()}
	dig_spots.append(spot)
	add_interactable(p + Vector3(0, 0.4, 0), Vector3(1.0, 0.8, 1.0), "Dig in the sand", _dig.bind(dig_spots.size() - 1))


func _dig(_p: Player, idx: int) -> void:
	var s: Dictionary = dig_spots[idx]
	if s["found"]:
		Overlay.toast("Only the hole you dug. It will be here a long time.", 2.5)
		return
	s["found"] = true
	toys_found += 1
	(s["mound"] as Node3D).visible = false
	(s["peek"] as Node3D).visible = false
	var p: Vector3 = s["pos"]
	D.hole(p, 0.24)
	var r := RandomNumberGenerator.new()
	r.seed = int(s["seed"])
	D.toy(s["kind"], p + Vector3(0.42, 0.0, 0.1), r.randf() * TAU, r, 0.0)
	sound.play_at("footstep", {"surface": "sand"}, p, -6.0, "[sand, scooped away]")
	var text := {"car": "a small die-cast car, its paint worn pale by small hands",
		"bucket": "a little sand bucket, its handle still on",
		"shovel": "a plastic spade, the blade chewed at one corner",
		"doll": "a doll in a faded dress, sand in its hair"}
	Overlay.toast("You dig and find %s. (%d found)" % [text[s["kind"]], toys_found], 4.0)


func _exit_room(k: GeoKit) -> void:
	var dp: Vector3 = info["exit_door"]
	var wp: Vector3 = info["exit_window"]
	var n: Vector3 = info["exit_n"]
	var side := Vector3(-n.z, 0, n.x)
	var b := Basis(side, Vector3.UP, side.cross(Vector3.UP))
	# an ordinary door, closed, in a plain frame
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, dp + side * s * 0.55 - n * 0.05 + Vector3.UP * 1.06), Vector3(0.1, 2.12, 0.28), "l75_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, dp - n * 0.05 + Vector3.UP * 2.15), Vector3(1.2, 0.1, 0.28), "l75_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, dp + n * 0.05 + Vector3.UP * 1.04), Vector3(0.98, 2.08, 0.05), "l75_door", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, dp - n * 0.0 + side * 0.36 + Vector3.UP * 1.0), Vector3(0.06, 0.06, 0.08), "l75_rust", GeoKit.ALL, false)
	# the window: daylight-like glow behind old glass
	k.box_xf(Transform3D(b, wp + n * 0.08 + Vector3.UP * 0.65), Vector3(1.5, 1.3, 0.02), "l75_window_light", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, wp - n * 0.02 + Vector3.UP * 0.65), Vector3(0.05, 1.3, 0.06), "l75_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, wp - n * 0.02 + Vector3.UP * 0.65), Vector3(1.5, 0.05, 0.06), "l75_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, wp - n * 0.1 + Vector3.UP * 0.0), Vector3(1.7, 0.06, 0.3), "l75_frame", GeoKit.ALL, false)
	lights.add_anchor(wp - n * 0.9 + Vector3.UP * 0.6, Color(1.0, 0.92, 0.78), 1.2, 6.0, 0.0)
	# sand spills a little way in through the doorway from the rest of the complex
	var hint := "A room with no sand on the floor. The door, or the window, should take you where you were going."
	var t := add_exit("L075>EXT#1", "interact", dp - n * 0.65 + Vector3.UP * 1.0, Vector3(1.6, 2.0, 1.3) if absf(n.z) > 0.5 else Vector3(1.3, 2.0, 1.6),
		"Open the door (the room has no sand: it should lead where you were going)")
	if t:
		t.fired.connect(func(_e: String) -> void: sound.play_at("creak", {"freq": 150.0}, dp, -8.0, "[the door opens onto somewhere familiar]"))
	add_exit("L075>EXT#1", "interact", wp - n * 0.65 + Vector3.UP * 0.4, Vector3(1.8, 1.8, 1.3) if absf(n.z) > 0.5 else Vector3(1.3, 1.8, 1.8),
		"Climb through the window")
	set_meta("exit_hint", hint)


func _player_print_layer() -> void:
	player_prints = MultiMesh.new()
	player_prints.transform_format = MultiMesh.TRANSFORM_3D
	var pl := PlaneMesh.new()
	pl.size = Vector2(0.11, 0.26)
	player_prints.mesh = pl
	player_prints.instance_count = MAX_PRINTS
	player_prints.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "YourFootprints"
	mmi.multimesh = player_prints
	mmi.material_override = D.print_mats[1]
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-10, -5, -10), Vector3(P.NX * P.S + 20, 20, P.NZ * P.S + 20))
	add_child(mmi)


## Your prints stay: there is no wind or water to take them. Bounded ring of instances.
func stamp(pos: Vector3, yaw: float) -> void:
	var c: Vector2i = P.cell_at(pos)
	if P.cells[c].get("clean", false):
		return
	var y: float = P.floor_y(c) + 0.054
	_left = not _left
	var side := Vector3(cos(yaw), 0, -sin(yaw)) * (0.1 if _left else -0.1)
	var b := Basis(Vector3.UP, yaw + PI)
	player_prints.set_instance_transform(_print_i, Transform3D(b, Vector3(pos.x, y, pos.z) + side))
	_print_i = (_print_i + 1) % MAX_PRINTS
	_print_n = mini(_print_n + 1, MAX_PRINTS)
	player_prints.visible_instance_count = _print_n


func _sounds() -> void:
	_rain = sound.bed("rain", {"seconds": 6.0}, -17.0)
	sound.bed("room_tone", {"cutoff": 140.0, "rumble": 0.1, "seconds": 5.0}, -36.0)
	sound.bed("pad", {"root": 98.0, "chord": [0, 7, 16], "bright": 0.08, "seconds": 12.0}, -40.0)
	sound.oneshot("creak", {"freq": 220.0}, 40.0, 80.0, 14.0, "[old paint cracks somewhere]", -28.0)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[rain, steady and soft, on a roof you cannot see; nothing here is wet]", 4.5)


func level_process(_delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	if player.is_on_floor() and Vector2(p.x - _last_step.x, p.z - _last_step.z).length() > 0.62:
		_last_step = p
		stamp(p, player.rotation.y)
	var c: Vector2i = P.cell_at(p)
	if c == P.exit_cell and not _said.has("clean") and not SessionState.is_qa():
		_said["clean"] = true
		Overlay.subtitle("[no sand here: your steps ring on bare floor]", 3.0)


func _shots() -> void:
	var sc: Vector3 = P.centre(P.start)
	add_shot("sand_corridor", Vector3(P.start.x * P.S + 1.2, P.floor_y(P.start) + 1.62, sc.z), Vector3(P.S * 2.0, P.floor_y(P.start) + 1.0, sc.z), {"flashlight": false})
	# the room with the most going on: a play room with a beam, seen from a doorway
	var best_c: Vector2i = P.start + Vector2i(1, 0)
	var best := -1.0
	for c in P.cells.keys():
		if P.cells[c]["kind"] == "room" and c != P.exit_cell:
			var score: float = float(P.cells[c]["links"].size()) + (1.5 if P.cells[c]["paint"] == "red" else 0.0) + float(c.x) * 0.1
			if score > best:
				best = score
				best_c = c
	var bc: Vector3 = P.centre(best_c)
	add_shot("sand_room", bc + Vector3(-3.6, 1.62, -3.5), bc + Vector3(2.0, 0.4, 2.2), {"flashlight": false})
	var ec: Vector3 = P.centre(P.exit_cell)
	var dp: Vector3 = info["exit_door"]
	add_shot("no_sand_room", ec - (dp - ec).normalized() * 2.8 + Vector3(0.4, 1.62, 0.4), dp + Vector3(0, 1.1, 0), {"flashlight": false})
	# looking through a doorway with steps into a room at another height
	if not info["stairs"].is_empty():
		var s: Dictionary = info["stairs"][0]
		var st: Vector3 = s["start"]
		var dir: Vector3 = s["dir"]
		add_shot("steps", st - dir * 3.2 + Vector3(0.5, 1.62, 0.5), st + dir * 3.0 + Vector3(0, 1.0, 0), {"flashlight": false})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "the sand-free exit room exists on the boundary", "ok": P.cells[P.exit_cell].get("clean", false) and info.has("exit_door")})
	out.append({"what": "old marks are laid in the sand (footprints and hand patterns)", "ok": int(get_meta("old_prints", 0)) > 100, "detail": get_meta("old_prints", 0)})
	var before := _print_n
	var p: Vector3 = P.centre(P.start) + Vector3(0, 0.06, 0)
	stamp(p, 0.0)
	stamp(p + Vector3(0.7, 0, 0), 0.0)
	out.append({"what": "your footprints are added and kept", "ok": _print_n == before + 2})
	var ok_dig := false
	if not dig_spots.is_empty():
		var f0 := toys_found
		_dig(player, 0)
		_dig(player, 0)
		ok_dig = toys_found == f0 + 1 and dig_spots[0]["found"]
	out.append({"what": "digging finds a toy once and leaves the hole", "ok": ok_dig or dig_spots.is_empty(), "detail": dig_spots.size()})
	var levels := {}
	for c in P.cells.keys():
		levels[P.cells[c]["level"]] = true
	out.append({"what": "rooms sit at more than one floor height", "ok": levels.size() >= 2, "detail": levels.keys()})
	out.append({"what": "the rain plays with no water anywhere", "ok": _rain != null and _rain.playing and get_tree().get_nodes_in_group("water").is_empty()})
	return out
