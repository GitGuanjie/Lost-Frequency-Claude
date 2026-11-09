extends RefCounted
## Level 6.1 snack bars and restaurants behind the facades. Each slot has a
## shop frame: origin on the hall wall line, +Z into the shop, +X along it.
##   Clippers   - SOURCE: the 1950s bar with red walls and wooden paneled floor
##                the discoverer fell into from Level 6 (now an active bar).
##   Liquorette - SOURCE: one of the many bars (named on the page).
##   tavern     - SOURCE: bars "as early as the 1600's"; some nameless.
##   snack/diner/kiosks - modern to 1980s snack joints; fridges, shelves.
##   vending room - SOURCE: rooms of vending machines, "in order, or entirely
##                random" (the arrangement is seeded).
##   restroom   - SOURCE: bathrooms that restock toilet paper.
##   Track Mappers office - SOURCE: maps given to any wanderer who asks.
##   M.E.G. outpost - SOURCE: 4+ armed guards at the rusty steel door to Level 6.
##   blocked room - SOURCE: rooms unenterable for vending machines piled up.

const SLOTS := {
	"NL0": {"type": "open", "name": "Clippers", "kind": "clippers", "col": "red"},
	"NL1": {"type": "closed", "name": "DONUTS", "col": "pink"},
	"NL2": {"type": "kiosk", "name": "COFFEE", "kind": "coffee", "col": "amber"},
	"NL3": {"type": "wall", "kind": "vending"},
	"NL4": {"type": "office", "name": "M.E.G. TRACK MAPPERS", "kind": "mappers", "col": "white"},
	"NL5": {"type": "closed", "name": "", "col": "white"},
	"NR0": {"type": "open", "name": "Liquorette", "kind": "liquorette", "col": "pink"},
	"NR1": {"type": "kiosk", "name": "PIZZA", "kind": "pizza", "col": "red"},
	"NR2": {"type": "closed", "name": "HOT DOGS", "col": "amber"},
	"NR3": {"type": "wall"},
	"NR4": {"type": "closed", "name": "WAFFLES", "col": "amber"},
	"NR5": {"type": "wall", "kind": "vent"},
	"SL0": {"type": "open", "name": "BURGERS", "kind": "snack", "col": "red"},
	"SL1": {"type": "kiosk", "name": "SODA FOUNTAIN", "kind": "soda", "col": "teal"},
	"SL2": {"type": "open", "name": "", "kind": "vending", "col": "white"},
	"SL3": {"type": "closed", "name": "CANDY", "col": "pink"},
	"SL4": {"type": "wall"},
	"SR0": {"type": "open", "name": "", "kind": "tavern", "col": "amber"},
	"SR1": {"type": "closed", "name": "TACOS", "col": "green"},
	"SR2": {"type": "office", "name": "RESTROOMS", "kind": "restroom", "col": "blue"},
	"SR3": {"type": "kiosk", "name": "NOODLES", "kind": "noodles", "col": "teal"},
	"SR4": {"type": "wall", "kind": "vending"},
	"EL0": {"type": "open", "name": "DINER", "kind": "diner", "col": "teal"},
	"EL1": {"type": "closed", "name": "BAKERY", "col": "amber"},
	"EL2": {"type": "wall", "kind": "vent"},
	"EL3": {"type": "kiosk", "name": "PRETZELS", "kind": "pretzel", "col": "amber"},
	"EL4": {"type": "closed", "name": "", "col": "white"},
	"ER0": {"type": "kiosk", "name": "ICE CREAM", "kind": "icecream", "col": "pink"},
	"ER1": {"type": "wall", "kind": "vending"},
	"ER2": {"type": "closed", "name": "CHICKEN", "col": "red"},
	"ER3": {"type": "wall"},
	"ER4": {"type": "closed", "name": "BBQ", "col": "red"},
	"WL0": {"type": "closed", "name": "JUICE", "col": "green"},
	"WL1": {"type": "wall", "kind": "vent"},
	"WL2": {"type": "kiosk", "name": "SANDWICHES", "kind": "sandwich", "col": "green"},
	"WL3": {"type": "closed", "name": "", "col": "white"},
	"WL4": {"type": "wall", "kind": "vending"},
	"WR0": {"type": "kiosk", "name": "FRIES", "kind": "fries", "col": "amber"},
	"WR1": {"type": "closed", "name": "SUSHI", "col": "teal"},
	"WR2": {"type": "wall", "kind": "bent"},
	"WR3": {"type": "closed", "name": "SALADS", "col": "green"},
	"WR4": {"type": "wall"},
}

var L: LevelBase
var props: Node3D
var k: GeoKit
var K
var counters: Array = []     # [{pos, slot, stock, shutter, name}]
var shutters: Array = []
var backdoors: Array = []    # [{zone (world), inside (world spawn), yaw, slot}]
var lamps: Array = []        # [{pos, col, e}]
var clippers_table := Vector3.ZERO
var clippers_yaw := 0.0
var map_desk := Vector3.ZERO
var guard_post := Vector3.ZERO
var steel_door := Vector3(0, 0, -64)
var music_spots: Array = []  # [{pos, kind}]
var _xf: Transform3D
var _yaw := 0.0


func _init(level: LevelBase, props_root: Node3D, kit: GeoKit, furniture) -> void:
	L = level
	props = props_root
	k = kit
	K = furniture


static func materials() -> void:
	MatLib.define("l61_redwall", {"albedo_a": Color(0.45, 0.05, 0.04), "albedo_b": Color(0.38, 0.04, 0.03), "pattern": 2,
		"pattern_scale": Vector2(0.3, 1.0), "pattern_color": Color(0.36, 0.03, 0.03), "pattern_strength": 0.3, "roughness_a": 0.5,
		"roughness_b": 0.7})
	MatLib.define("l61_panel_wood", {"albedo_a": Color(0.36, 0.20, 0.10), "albedo_b": Color(0.30, 0.16, 0.08), "pattern": 3,
		"pattern_scale": Vector2(0.18, 2.0), "grout_width": 0.004, "grout_color": Color(0.15, 0.08, 0.04), "roughness_a": 0.35,
		"roughness_b": 0.5}, "wood_floor")
	MatLib.define("l61_lounge", {"albedo_a": Color(0.10, 0.04, 0.09), "albedo_b": Color(0.08, 0.03, 0.07), "pattern": 10,
		"pattern_scale": Vector2(0.4, 0.4), "pattern_color": Color(0.22, 0.06, 0.18), "pattern_strength": 0.5, "roughness_a": 0.8,
		"roughness_b": 0.9})
	MatLib.define("l61_plaster_old", {"albedo_a": Color(0.82, 0.78, 0.68), "albedo_b": Color(0.74, 0.70, 0.60), "noise_scale": 2.0,
		"stain_amount": 0.35, "stain_color": Color(0.55, 0.48, 0.36), "bump_strength": 1.0}, "plaster")
	MatLib.define("l61_beam", {"albedo_a": Color(0.22, 0.13, 0.07), "albedo_b": Color(0.17, 0.10, 0.05), "pattern": 3,
		"pattern_scale": Vector2(3.0, 0.3), "grout_width": 0.0, "roughness_a": 0.7, "roughness_b": 0.9, "bump_strength": 1.2}, "wood_floor")
	MatLib.define("l61_flagstone", {"albedo_a": Color(0.42, 0.40, 0.36), "albedo_b": Color(0.34, 0.32, 0.29), "pattern": 14,
		"pattern_scale": Vector2(0.7, 0.5), "grout_width": 0.03, "grout_color": Color(0.2, 0.19, 0.17), "roughness_a": 0.8,
		"roughness_b": 0.95, "bump_strength": 1.0})
	MatLib.define("l61_checker", {"albedo_a": Color(0.9, 0.9, 0.88), "albedo_b": Color(0.08, 0.08, 0.09), "pattern": 9,
		"pattern_scale": Vector2(0.4, 0.4), "grout_width": 0.004, "roughness_a": 0.2, "roughness_b": 0.3})
	MatLib.define("l61_vinyl", {"albedo_a": Color(0.62, 0.06, 0.06), "albedo_b": Color(0.55, 0.05, 0.05), "roughness_a": 0.3,
		"roughness_b": 0.4})
	MatLib.define("l61_counter", {"albedo_a": Color(0.85, 0.82, 0.76), "albedo_b": Color(0.8, 0.77, 0.7), "pattern": 15,
		"pattern_color": Color(0.5, 0.45, 0.4), "pattern_strength": 0.3, "roughness_a": 0.25, "roughness_b": 0.35})
	MatLib.define("l61_tile_white", {"albedo_a": Color(0.9, 0.91, 0.9), "albedo_b": Color(0.86, 0.87, 0.86), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.006, "grout_color": Color(0.7, 0.72, 0.72), "roughness_a": 0.1,
		"roughness_b": 0.2}, "pool_tile")
	MatLib.define("l61_rust", {"albedo_a": Color(0.42, 0.22, 0.11), "albedo_b": Color(0.30, 0.16, 0.09), "metallic_value": 0.45,
		"roughness_a": 0.75, "roughness_b": 0.95, "noise_scale": 3.5, "bump_strength": 1.4}, "rust")
	MatLib.register("l61_menu", MatLib.panel(Color(1.0, 0.92, 0.75), 1.1))
	MatLib.register("l61_neon_pink", MatLib.panel(Color(1.0, 0.25, 0.65), 3.0))
	MatLib.register("l61_jukebox", MatLib.panel(Color(1.0, 0.6, 0.2), 1.6))
	MatLib.register("l61_candle", MatLib.panel(Color(1.0, 0.65, 0.3), 2.0))


func _p(id: String, lp: Vector3, yaw: float = 0.0, h: float = 0.0, collide := false) -> Node3D:
	return Props.place(L, props, id, _xf * lp, _yaw + yaw, h, collide)


func _b(c: Vector3, size: Vector3, mat: String, collide := true, faces := GeoKit.ALL) -> void:
	k.box_xf(_xf * Transform3D(Basis(), c), size, mat, faces, collide)


func _w(lp: Vector3) -> Vector3:
	return _xf * lp


func build(slots: Array) -> void:
	for s in slots:
		_xf = s["xf"]
		_yaw = rad_to_deg(atan2(_xf.basis.z.x, _xf.basis.z.z))
		match s["type"]:
			"closed":
				_shutter(s, true)
			"kiosk":
				_kiosk(s)
			"open", "office":
				_interior(s)
	_outpost()
	_blocked_room()


func _shell(depth: float, h: float, floor: String, wall: String, ceil: String) -> void:
	_b(Vector3(0, -0.15, depth * 0.5 + 0.075), Vector3(8.0, 0.3, depth + 0.15), floor)
	_b(Vector3(-3.85, h * 0.5, depth * 0.5 + 0.15), Vector3(0.3, h + 0.3, depth), wall)
	_b(Vector3(3.85, h * 0.5, depth * 0.5 + 0.15), Vector3(0.3, h + 0.3, depth), wall)
	_b(Vector3(0, h * 0.5, depth + 0.3), Vector3(8.0, h + 0.3, 0.3), wall)
	_b(Vector3(0, h + 0.15, depth * 0.5 + 0.15), Vector3(8.0, 0.3, depth + 0.3), ceil, true, GeoKit.NY | GeoKit.PY)


func _shutter(s: Dictionary, down: bool) -> MeshInstance3D:
	var w := 3.8 if s["type"] != "kiosk" else 5.2
	var h := 2.9 if s["type"] != "kiosk" else 2.6
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, 0.06)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("l61_shutter")
	props.add_child(mi)
	mi.global_transform = Transform3D(_xf.basis, _w(Vector3(0, h * 0.5 if down else h - 0.05, -0.02)))
	if not down:
		mi.scale.y = 0.04
	var placard: Label3D = K.label("CLOSED UNTIL RESTOCK\nThe Snackrooms Staff", _w(Vector3(0, 1.5, -0.06)), _yaw + 180.0, 30, Color(0.1, 0.1, 0.12))
	placard.visible = down
	if down:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = bm.size
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
	shutters.append({"mi": mi, "placard": placard, "h": h, "down": down})
	return mi


func _kiosk(s: Dictionary) -> void:
	_shell(4.2, 3.2, "l61_tile", "l61_wall", "l61_ceiling")
	_b(Vector3(0, 0.525, 0.65), Vector3(5.0, 1.05, 0.6), "l61_counter")
	_b(Vector3(0, 1.07, 0.6), Vector3(5.1, 0.04, 0.75), "l61_chrome", false)
	_b(Vector3(0, 2.3, 4.12), Vector3(5.0, 0.9, 0.04), "l61_menu", false)
	K.label("M E N U", _w(Vector3(0, 2.62, 4.08)), _yaw + 180.0, 48, Color(0.25, 0.1, 0.05))
	K.fridge(_w(Vector3(-3.1, 0, 3.6)), _yaw + 180.0)
	K.fridge(_w(Vector3(3.1, 0, 3.6)), _yaw + 180.0)
	_p("ph/Shelf_01", Vector3(-1.4, 0, 3.95), 180.0, 1.6)
	var foods := {"coffee": "kenney/food-kit/cup-coffee", "pizza": "kenney/food-kit/pizza-box", "soda": "kenney/food-kit/soda-can",
		"noodles": "kenney/food-kit/bowl", "pretzel": "kenney/food-kit/plate", "icecream": "kenney/food-kit/cup", "sandwich": "kenney/food-kit/sandwich",
		"fries": "kenney/food-kit/fries-empty"}
	var fid: String = foods.get(s["kind"], "kenney/food-kit/burger")
	for j in 3:
		_p(fid, Vector3(-1.2 + j * 1.1, 1.09, 0.6), j * 40.0, 0.12 if fid != "kenney/food-kit/pizza-box" else 0.08)
	_p("ph/CashRegister_01", Vector3(1.9, 1.09, 0.7), 180.0)
	lamps.append({"pos": _w(Vector3(0, 2.8, 2.0)), "col": Color(1.0, 0.9, 0.75), "e": 0.9})
	var sh := _shutter(s, false)
	if L.rng.randf() < 0.6:
		K.figure(_w(Vector3(0.4, 0, 1.6)), _yaw + 180.0, "server" if s["kind"] != "pizza" else "cook")
	counters.append({"pos": _w(Vector3(0, 1.2, -0.1)), "slot": s, "stock": 2 + L.rng.randi() % 3, "shutter": shutters.size() - 1, "name": s["name"]})


func _interior(s: Dictionary) -> void:
	match s["kind"]:
		"clippers":
			_shell(10.0, 3.4, "l61_wood", "l61_redwall", "l61_ceiling")
			_clippers()
		"liquorette":
			_shell(10.0, 3.4, "l61_lounge", "l61_lounge", "l61_black")
			_liquorette()
		"tavern":
			_shell(10.0, 3.8, "l61_flagstone", "l61_plaster_old", "l61_beam")
			_tavern()
		"snack":
			_shell(10.0, 3.4, "l61_tile", "l61_wall", "l61_ceiling")
			_snack()
		"diner":
			_shell(10.0, 3.4, "l61_checker", "l61_wall", "l61_ceiling")
			_diner()
		"vending":
			_shell(10.0, 3.4, "l61_terrazzo", "l61_wall", "l61_ceiling")
			_vending_room()
		"restroom":
			_shell(6.0, 3.0, "l61_tile_white", "l61_tile_white", "l61_ceiling")
			_restroom()
		"mappers":
			_shell(5.0, 3.2, "l61_tile", "l61_wall", "l61_ceiling")
			_mappers()
	if s["kind"] in ["clippers", "liquorette", "tavern", "snack", "diner"]:
		_backdoor(s)


## A plain door in the back wall onto a short service passage. Walking down it
## brings you out through the back door of a different restaurant (SOURCE).
func _backdoor(s: Dictionary) -> void:
	var x := 2.6
	_b(Vector3(x, 1.1, 10.3), Vector3(1.0, 2.2, 0.32), "l61_black", false)
	_b(Vector3(x, 2.25, 10.15), Vector3(1.2, 0.1, 0.05), "l61_chrome", false)
	K.label("EXIT", _w(Vector3(x, 2.45, 10.1)), _yaw + 180.0, 36, Color(0.4, 1.0, 0.5), 4)
	backdoors.append({"zone": _w(Vector3(x, 1.0, 10.1)), "inside": _w(Vector3(x, 0.05, 8.9)), "yaw": _yaw, "slot": s})


func _clippers() -> void:
	# 1950s red bar, wood paneled floor: counter along the left wall with stools,
	# booths on the right, a jukebox, and the wooden table the discoverer fell on.
	_b(Vector3(-2.9, 0.55, 5.4), Vector3(0.7, 1.1, 7.0), "l61_panel_wood")
	_b(Vector3(-2.85, 1.12, 5.4), Vector3(0.9, 0.05, 7.2), "l61_vinyl", false)
	_b(Vector3(-3.6, 1.6, 5.4), Vector3(0.12, 0.05, 6.0), "l61_panel_wood", false)
	for j in 6:
		_p("ph/bar_chair_round_01", Vector3(-2.1, 0, 2.6 + j * 1.1), 0.0)
	for j in 3:
		var z := 2.6 + j * 2.6
		_b(Vector3(3.4, 0.55, z - 0.75), Vector3(0.9, 1.1, 0.15), "l61_vinyl")
		_b(Vector3(3.4, 0.25, z - 0.45), Vector3(0.9, 0.45, 0.5), "l61_vinyl")
		_b(Vector3(3.4, 0.55, z + 0.75), Vector3(0.9, 1.1, 0.15), "l61_vinyl")
		_b(Vector3(3.4, 0.25, z + 0.45), Vector3(0.9, 0.45, 0.5), "l61_vinyl")
		_b(Vector3(3.3, 0.74, z), Vector3(0.7, 0.05, 0.6), "l61_panel_wood")
		_b(Vector3(3.3, 0.36, z), Vector3(0.08, 0.72, 0.08), "l61_chrome", false)
	# the table: wooden, square, in the middle of the floor
	clippers_table = _w(Vector3(0.6, 0, 4.6))
	_b(Vector3(0.6, 0.73, 4.6), Vector3(1.1, 0.06, 1.1), "l61_panel_wood")
	_b(Vector3(0.6, 0.35, 4.6), Vector3(0.12, 0.7, 0.12), "l61_panel_wood", false)
	for a in [0.0, 90.0, 180.0, 270.0]:
		_p("ph/dining_chair_02", Vector3(0.6, 0, 4.6) + Vector3(sin(deg_to_rad(a)), 0, cos(deg_to_rad(a))) * 0.8, a + 180.0)
	clippers_yaw = _yaw
	_b(Vector3(1.8, 0.8, 9.85), Vector3(0.9, 1.6, 0.6), "l61_panel_wood")
	_b(Vector3(1.8, 1.25, 9.54), Vector3(0.7, 0.5, 0.02), "l61_jukebox", false)
	_p("ph/CashRegister_01", Vector3(-2.9, 1.15, 8.4), 90.0)
	_p("ph/vintage_telephone_wall_clock", Vector3(0.0, 2.3, 10.12), 180.0)
	K.label("Clippers", _w(Vector3(-3.68, 2.4, 5.4)), _yaw + 90.0, 90, Color(1.0, 0.85, 0.5), 8)
	lamps.append({"pos": _w(Vector3(0.0, 3.0, 3.0)), "col": Color(1.0, 0.7, 0.5), "e": 1.1})
	lamps.append({"pos": _w(Vector3(0.0, 3.0, 8.0)), "col": Color(1.0, 0.65, 0.45), "e": 0.9})
	K.figure(_w(Vector3(-3.4, 0, 6.0)), _yaw + 90.0, "server")
	music_spots.append({"pos": _w(Vector3(1.8, 1.0, 9.5)), "kind": "jukebox"})


func _liquorette() -> void:
	_b(Vector3(0.5, 0.55, 8.6), Vector3(5.5, 1.1, 0.7), "l61_black")
	_b(Vector3(0.5, 1.12, 8.6), Vector3(5.7, 0.05, 0.9), "l61_chrome", false)
	for j in 3:
		_b(Vector3(0.5, 1.5 + j * 0.45, 10.05), Vector3(5.0, 0.04, 0.3), "l61_chrome", false)
		for b in 12:
			_b(Vector3(-1.6 + b * 0.38, 1.66 + j * 0.45, 10.0), Vector3(0.08, 0.28, 0.08), ["l61_bottle_a", "l61_bottle_b", "l61_bottle_c"][(b + j) % 3], false)
	for j in 4:
		_p("ph/bar_chair_round_01", Vector3(-1.5 + j * 1.3, 0, 7.7), 0.0)
	for c in [Vector3(-2.3, 0, 3.0), Vector3(1.6, 0, 2.6), Vector3(-1.0, 0, 5.4), Vector3(2.4, 0, 5.2)]:
		k.cylinder(_w(c + Vector3(0, 0.72, 0)), 0.36, 0.04, "l61_black", 14, true)
		k.cylinder(_w(c + Vector3(0, 0.36, 0)), 0.04, 0.72, "l61_chrome", 8, false)
		K.chair(_w(c + Vector3(0.6, 0, 0)), _yaw - 90.0)
		K.chair(_w(c + Vector3(-0.6, 0, 0)), _yaw + 90.0)
	K.label("Liquorette", _w(Vector3(0.5, 2.6, 10.12)), _yaw + 180.0, 120, Color(1.0, 0.35, 0.7), 12)
	_b(Vector3(0.5, 3.3, 5.0), Vector3(6.0, 0.03, 0.03), "l61_neon_pink", false)
	_b(Vector3(-3.65, 2.9, 5.0), Vector3(0.03, 0.03, 8.0), "l61_neon_pink", false)
	lamps.append({"pos": _w(Vector3(0.5, 2.6, 7.6)), "col": Color(1.0, 0.3, 0.65), "e": 1.2})
	lamps.append({"pos": _w(Vector3(0.0, 2.8, 3.0)), "col": Color(0.6, 0.35, 1.0), "e": 0.7})
	K.figure(_w(Vector3(0.6, 0, 9.4)), _yaw + 180.0, "server")
	music_spots.append({"pos": _w(Vector3(0, 2.0, 6.0)), "kind": "lounge"})


func _tavern() -> void:
	# nameless, centuries old: timber beams, flagstones, long tables, barrels
	for z in [2.0, 4.5, 7.0, 9.5]:
		_b(Vector3(0, 3.6, z), Vector3(7.4, 0.25, 0.25), "l61_beam", false)
	for x in [-3.4, 3.4]:
		for z in [3.2, 7.6]:
			_b(Vector3(x, 1.9, z), Vector3(0.25, 3.8, 0.25), "l61_beam", false)
	for z in [3.5, 6.8]:
		_b(Vector3(-0.8, 0.76, z), Vector3(3.6, 0.08, 0.9), "l61_beam")
		for x in [-2.3, 0.7]:
			_b(Vector3(x, 0.37, z), Vector3(0.12, 0.74, 0.7), "l61_beam", false)
		for sz in [-0.75, 0.75]:
			_b(Vector3(-0.8, 0.44, z + sz), Vector3(3.4, 0.06, 0.3), "l61_beam")
	for c in [Vector3(2.9, 0, 9.4), Vector3(3.2, 0, 8.6), Vector3(2.4, 0, 9.6)]:
		_p("ph/Barrel_01" if c.x > 2.6 else "ph/barrel_03", c, L.rng.randf_range(0, 360), 0.0, true)
	_p("ph/lantern_chandelier_01", Vector3(-0.8, 2.6, 5.1), 0.0)
	_p("ph/wooden_crate_01", Vector3(-3.2, 0, 9.4), 15.0)
	# a hearth in the back wall
	_b(Vector3(-1.4, 0.6, 9.95), Vector3(1.8, 1.2, 0.4), "l61_flagstone", false)
	_b(Vector3(-1.4, 0.35, 9.8), Vector3(1.2, 0.5, 0.05), "l61_candle", false)
	# a blank hanging sign over the door (SOURCE: some appear to be nameless)
	_b(Vector3(0, 3.0, -0.45), Vector3(1.4, 0.7, 0.06), "l61_beam", false)
	lamps.append({"pos": _w(Vector3(-0.8, 2.4, 5.1)), "col": Color(1.0, 0.62, 0.3), "e": 1.1})
	lamps.append({"pos": _w(Vector3(-1.4, 0.8, 9.3)), "col": Color(1.0, 0.5, 0.2), "e": 0.8})
	music_spots.append({"pos": _w(Vector3(0, 1.5, 6.0)), "kind": "old"})


func _snack() -> void:
	_b(Vector3(0, 0.525, 7.2), Vector3(6.4, 1.05, 0.7), "l61_counter")
	_b(Vector3(0, 1.07, 7.2), Vector3(6.5, 0.04, 0.85), "l61_chrome", false)
	_b(Vector3(0, 2.4, 10.12), Vector3(6.0, 1.0, 0.04), "l61_menu", false)
	K.label("BURGERS  FRIES  SHAKES", _w(Vector3(0, 2.6, 10.08)), _yaw + 180.0, 60, Color(0.6, 0.08, 0.05))
	for j in 3:
		_p(["kenney/food-kit/burger", "kenney/food-kit/fries-empty", "kenney/food-kit/soda-can"][j], Vector3(-1.5 + j * 1.5, 1.09, 7.15), j * 30.0, 0.12)
	K.fridge(_w(Vector3(-3.1, 0, 9.5)), _yaw + 180.0)
	_p("kenney/furniture-kit/kitchenstove", Vector3(1.0, 0, 9.6), 180.0, 0.9)
	_p("kenney/food-kit/frying-pan", Vector3(1.0, 0.9, 9.6), 0.0, 0.05)
	for c in [Vector3(-2.0, 0, 2.6), Vector3(1.6, 0, 2.6), Vector3(-2.0, 0, 5.0), Vector3(1.6, 0, 5.0)]:
		K.table_set(_w(c), _yaw, 2, true)
	K.figure(_w(Vector3(1.0, 0, 8.6)), _yaw + 180.0, "cook")
	lamps.append({"pos": _w(Vector3(0, 3.0, 3.5)), "col": Color(1.0, 0.95, 0.85), "e": 1.1})
	lamps.append({"pos": _w(Vector3(0, 3.0, 8.0)), "col": Color(1.0, 0.95, 0.85), "e": 1.0})
	counters.append({"pos": _w(Vector3(0, 1.2, 6.7)), "slot": {}, "stock": 4 + L.rng.randi() % 3, "shutter": -1, "name": "BURGERS"})


func _diner() -> void:
	_b(Vector3(-2.6, 0.55, 5.6), Vector3(0.7, 1.1, 7.0), "l61_counter")
	_b(Vector3(-2.55, 1.12, 5.6), Vector3(0.9, 0.05, 7.2), "l61_chrome", false)
	for j in 6:
		k.cylinder(_w(Vector3(-1.85, 0.38, 2.6 + j * 1.15)), 0.2, 0.06, "l61_vinyl", 12, false)
		k.cylinder(_w(Vector3(-1.85, 0.18, 2.6 + j * 1.15)), 0.04, 0.36, "l61_chrome", 6, false)
	for j in 3:
		var z := 2.4 + j * 2.6
		for sz in [-0.75, 0.75]:
			_b(Vector3(3.2, 0.55, z + sz * 1.0), Vector3(1.1, 1.1, 0.15), "l61_trim_teal")
			_b(Vector3(3.2, 0.25, z + sz * 0.6), Vector3(1.1, 0.45, 0.5), "l61_vinyl")
		_b(Vector3(3.1, 0.74, z), Vector3(0.9, 0.05, 0.7), "l61_counter")
		_p("kenney/food-kit/cup-coffee", Vector3(3.0, 0.77, z - 0.1), 30.0 * j, 0.1)
	_p("kenney/furniture-kit/kitchencoffeemachine", Vector3(-3.3, 1.14, 4.0), 90.0, 0.4)
	_p("kenney/food-kit/plate", Vector3(-2.6, 1.15, 6.0), 0.0, 0.03)
	_p("ph/wall_clock", Vector3(0.0, 2.5, 10.12), 180.0)
	lamps.append({"pos": _w(Vector3(0, 3.0, 3.0)), "col": Color(0.95, 1.0, 0.95), "e": 1.0})
	lamps.append({"pos": _w(Vector3(0, 3.0, 7.5)), "col": Color(0.95, 1.0, 0.95), "e": 0.9})
	K.figure(_w(Vector3(-3.3, 0, 7.4)), _yaw + 90.0, "server")
	counters.append({"pos": _w(Vector3(-2.0, 1.2, 5.6)), "slot": {}, "stock": 3 + L.rng.randi() % 3, "shutter": -1, "name": "DINER"})
	music_spots.append({"pos": _w(Vector3(0, 2.0, 5.0)), "kind": "diner"})


func _vending_room() -> void:
	# SOURCE: "Some arrangements are in order, or entirely random" -> seeded
	var bodies := ["l61_vend_red", "l61_vend_blue", "l61_vend_white", "l61_vend_green"]
	if L.rng.randf() < 0.5:
		for j in 5:
			K.vending_machine(_w(Vector3(-3.2, 0, 2.0 + j * 1.6)), _yaw + 90.0, bodies[j % 4], "vend")
			K.vending_machine(_w(Vector3(3.2, 0, 2.0 + j * 1.6)), _yaw - 90.0, bodies[(j + 1) % 4], "vend")
	else:
		for j in 9:
			var c := Vector3(L.rng.randf_range(-2.6, 2.6), 0, L.rng.randf_range(2.6, 9.2))
			K.vending_machine(_w(c), _yaw + L.rng.randf_range(0, 360), bodies[j % 4], "vend")
	lamps.append({"pos": _w(Vector3(0, 3.0, 5.0)), "col": Color(1.0, 0.96, 0.88), "e": 1.0})
	K.figure(_w(Vector3(0.4, 0, 9.0)), _yaw + 200.0, "staff")


func _restroom() -> void:
	for j in 3:
		var x := -3.0 + j * 1.25
		_b(Vector3(x + 0.62, 1.0, 4.6), Vector3(0.04, 2.0, 2.2), "l61_vend_white")
		_p("kenney/furniture-kit/toilet", Vector3(x, 0, 5.5), 180.0, 0.75)
	_b(Vector3(0.75, 1.0, 3.5), Vector3(0.04, 2.0, 0.6), "l61_vend_white", false)
	for j in 3:
		_p("kenney/furniture-kit/bathroomsink", Vector3(3.5, 0, 1.4 + j * 1.2), -90.0, 0.9)
	_b(Vector3(3.83, 1.6, 2.6), Vector3(0.02, 0.8, 3.4), "l61_skyglass", false)
	_p("ph/WetFloorSign_01", Vector3(1.5, 0, 2.0), 30.0)
	lamps.append({"pos": _w(Vector3(0, 2.7, 3.0)), "col": Color(0.92, 0.97, 1.0), "e": 1.0})


func _mappers() -> void:
	_p("ph/metal_office_desk", Vector3(0, 0, 2.2), 180.0, 0.0, true)
	_p("ph/SchoolChair_01", Vector3(0.2, 0, 3.0), 180.0)
	_p("ph/office_notepads", Vector3(-0.5, 0.79, 2.2), 0.0)
	_p("ph/vintage_radio_transceiver", Vector3(0.6, 0.79, 2.3), 200.0)
	_p("ph/drawer_cabinet", Vector3(-3.1, 0, 4.5), 180.0)
	# a hand-drawn map of the controlled area on the back wall
	_b(Vector3(0.6, 1.8, 5.12), Vector3(3.6, 1.6, 0.03), "paper", false)
	for seg in [[Vector3(-0.6, 1.8, 5.1), Vector3(1.6, 0.06, 0.01)], [Vector3(0.6, 1.8, 5.1), Vector3(0.06, 1.3, 0.01)],
			[Vector3(0.6, 1.8, 5.1), Vector3(0.45, 0.45, 0.01)], [Vector3(1.8, 1.8, 5.1), Vector3(1.6, 0.06, 0.01)]]:
		_b(seg[0], seg[1], "l61_navy", false)
	map_desk = _w(Vector3(0, 1.0, 1.2))
	K.figure(_w(Vector3(-0.4, 0, 3.0)), _yaw + 180.0, "mapper")
	lamps.append({"pos": _w(Vector3(0, 2.8, 2.5)), "col": Color(1.0, 0.95, 0.85), "e": 1.0})


## SOURCE: The M.E.G. Level 6 Access Outpost: at an exit, a rusty steel door,
## 4+ armed guards (M.E.G. Division Secure Security) at all times.
func _outpost() -> void:
	var dz := -64.0
	k.box(Vector3(0, 1.15, dz + 0.02), Vector3(1.28, 2.3, 0.08), "l61_rust", GeoKit.ALL, true)
	k.box(Vector3(0.45, 1.05, dz + 0.1), Vector3(0.08, 0.3, 0.08), "l61_rust", GeoKit.ALL, false)
	k.box(Vector3(0, 2.35, dz + 0.12), Vector3(1.5, 0.12, 0.2), "l61_rust", GeoKit.ALL, false)
	for x in [-3.0, -1.6, 1.6, 3.0]:
		Props.place(L, props, "ph/concrete_road_barrier", Vector3(x, 0, dz + 6.5), 0.0, 0.0, true)
	Props.place(L, props, "ph/metal_office_desk", Vector3(-2.6, 0, dz + 2.4), 90.0, 0.0, true)
	Props.place(L, props, "ph/vintage_radio_transceiver", Vector3(-2.6, 0.79, dz + 2.8), 60.0)
	Props.place(L, props, "ph/clipboard", Vector3(-2.5, 0.79, dz + 2.0), 80.0)
	Props.place(L, props, "ph/security_light", Vector3(2.6, 3.4, dz + 0.2), 180.0)
	Props.place(L, props, "ph/old_military_crate", Vector3(3.0, 0, dz + 1.4), 90.0, 0.0, true)
	for g in [[Vector3(-1.2, 0, dz + 1.6), 160.0], [Vector3(1.2, 0, dz + 1.7), 200.0], [Vector3(-2.2, 0, dz + 5.4), 180.0], [Vector3(2.3, 0, dz + 5.5), 180.0]]:
		K.figure(g[0], g[1], "guard")
	guard_post = Vector3(-2.2, 1.2, dz + 5.4)
	K.label("LEVEL 6 ACCESS\nAUTHORIZED PERSONNEL ONLY\nM.E.G. Division Secure Security", Vector3(0, 3.2, dz + 0.17), 0.0, 46, Color(0.95, 0.9, 0.7), 6)
	lamps.append({"pos": Vector3(2.4, 3.0, dz + 1.0), "col": Color(1.0, 0.92, 0.75), "e": 1.3})


## SOURCE: "Some rooms are even unenterable due to the sheer amount of vending
## machines piled on top of each other which can block the entrance".
func _blocked_room() -> void:
	k.box_mm(Vector3(56, -0.3, -6), Vector3(66, 0, 6), "l61_terrazzo")
	k.box_mm(Vector3(56, 4.0, -6), Vector3(66, 4.3, 6), "l61_ceiling", GeoKit.NY, true)
	k.box_mm(Vector3(66, -0.3, -6), Vector3(66.3, 4.3, 6), "l61_wall")
	k.box_mm(Vector3(56, -0.3, -6.3), Vector3(66.3, 4.3, -6), "l61_wall")
	k.box_mm(Vector3(56, -0.3, 6), Vector3(66.3, 4.3, 6.3), "l61_wall")
	var bodies := ["l61_vend_red", "l61_vend_blue", "l61_vend_white", "l61_vend_green"]
	var stack := [[Vector3(56.6, 0, -1.6), 80.0], [Vector3(56.7, 0, -0.5), 95.0], [Vector3(56.5, 0, 0.6), 70.0], [Vector3(56.8, 0, 1.7), 100.0],
		[Vector3(57.6, 0, -1.0), 10.0], [Vector3(57.8, 0, 1.0), -20.0], [Vector3(58.5, 0, 0.0), 45.0]]
	for i in stack.size():
		K.vending_machine(stack[i][0], stack[i][1], bodies[i % 4], "", true)
	for i in 4:
		var c := Vector3(56.9 + i * 0.4, 1.95, -1.4 + i * 0.95)
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(80.0 + i * 25.0)) * Basis(Vector3.BACK, deg_to_rad(80.0 + i * 6.0)), c)
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0, 0)), Vector3(0.95, 1.9, 0.8), bodies[(i + 1) % 4], GeoKit.ALL, true)
		k.box_xf(xf * Transform3D(Basis(), Vector3(-0.1, 0.2, 0.402)), Vector3(0.62, 1.3, 0.01), "l61_vend_glow", GeoKit.ALL, false)
	lamps.append({"pos": Vector3(61.0, 3.2, 0.0), "col": Color(1.0, 0.95, 0.85), "e": 0.8})
