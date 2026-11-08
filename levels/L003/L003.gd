extends LevelBase
## Level 3 "Electrical Station" (Backrooms Wiki rev 18, 2026-11-04; Natedagreat563,
## CC BY-SA 3.0). Dossier docs/canon/levels/L003.md; SOURCE vs ADAPTATION in level.json.
## A finite authored slice: most of the level is behind bars (page), so every
## unexplored branch ends in bars with the hall visibly running on.

const U := Vector3(0, 1, 0)
const K := preload("res://levels/L003/L003_kit.gd")
const R := preload("res://levels/L003/L003_rooms.gd")
const GB := preload("res://levels/L003/L003_gamma.gd")
const Sys := preload("res://levels/L003/L003_sys.gd")
const SPAWN := Vector3(1.2, 0.0, 0.0)
const LIFT_POS := Vector3(110.0, -5.0, -13.9)
const WALLS := ["l3_brick_red", "l3_brick_buff", "l3_brick_grey", "l3_brick_dark"]

var sys: Node
var tubes: GeoKit
var qa_fixture := false
var bar_views: Array = []        # [{c, n, beyond}] barred openings (dread mechanic)
var hotspots: Array = []         # AABBs of paranoia hotspots
var sludge: Array = []           # [{c, r}] black sludge pools
var wires: Array = []            # live fallen wire tips
var fragile: Array = []          # [{mi, pos}] tubes that can shatter
var zones: Array = []            # [{name, box}]


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["reverb_room"] = 0.5
	rules["reverb_wet"] = 0.22
	rules["view_distance"] = 420.0
	indoor_env(Color("9e8f7a"), 0.028, Color("0f0d0b"), 0.0065)
	environment.background_color = Color("040303")
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 0.95
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.88
	environment.adjustment_contrast = 1.1
	_materials()
	lights.setup(14, 1)
	lights.max_distance = 32.0
	tubes = kit("Tubes")
	tubes.shadows = false
	var k := kit("Halls")
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "halls"])
	sys = Sys.new()
	sys.name = "Systems"
	add_child(sys)
	sys.setup(self)
	R.car_room(self, kit("CarRoom"))   # first exit: QA target
	_halls(k, r)
	R.generator_room(self, k, r)
	R.assembly(self, k, r)
	R.boiler_room(self, k, r)
	R.sanctum(self, k, r)
	GB.build(self, k, r)
	k.commit()
	tubes.commit()
	add_arrival("start", SPAWN, -90.0)
	add_arrival("from_L004", LIFT_POS + Vector3(0, 0.05, -0.4), 180.0)
	add_arrival("from_L005", LIFT_POS + Vector3(0, 0.05, -0.4), 180.0)
	sys.beds()
	add_shot("hall", Vector3(17.2, 1.6, 0.9), Vector3(18.5, 1.3, -14.0))
	add_shot("gamma", Vector3(84.0, -3.38, -1.5), Vector3(110.0, 8.0, -10.0))
	add_landmark("Arrival hall (door from Level 2)", SPAWN)
	add_landmark("Generator Room", Vector3(43, 0, 0))
	add_landmark("Base Gamma transfer hall", Vector3(111, -5, -4))


func _m(n: String, base: String, a: Color, b: Color, x: Dictionary = {}) -> void:
	x["albedo_a"] = a
	x["albedo_b"] = b
	MatLib.define(n, x, base)


func _materials() -> void:
	var br := {"pattern": 4, "pattern_scale": Vector2(0.23, 0.075), "grout_width": 0.012, "tile_variation": 0.18, "stain_amount": 0.75,
		"stain_color": Color("291f17"), "stain_scale": 0.4, "grime_height": 1.1, "grime_color": Color("1f1a14"), "bump_strength": 1.2, "roughness_a": 0.95}
	var g := br.duplicate()
	g["grout_color"] = Color("6b6357")
	var gp := g.duplicate()
	gp["peel_amount"] = 0.35
	gp["peel_color"] = Color("663626")
	var gb := g.duplicate()
	gb["floor_y"] = -5.0
	gb["grime_height"] = 3.0
	var fl := {"noise_scale": 0.9, "stain_amount": 0.8, "stain_color": Color("332e26"), "stain_scale": 0.35, "roughness_a": 0.93, "roughness_b": 1.0, "bump_strength": 0.8}
	var mt := {"metallic_value": 0.4, "roughness_a": 0.55, "stain_amount": 0.5, "stain_color": Color("4c331f")}
	for d in [
		["l3_brick_red", "brick", "733826", "54291c", g],
		["l3_brick_buff", "brick", "8f7352", "70573d", g],
		["l3_brick_grey", "brick", "8c8c80", "78786e", gp],
		["l3_brick_dark", "brick", "4c2b21", "38211a", g],
		["l3_bg_wall", "brick", "663626", "4c291c", gb],
		["l3_floor", "concrete", "57524a", "403d38", fl],
		["l3_bg_floor", "concrete", "615c54", "4c4a45", fl],
		["l3_ceiling", "concrete", "42403b", "302e2b", {"stain_amount": 0.8, "stain_color": Color("1a1714")}],
		["l3_concrete_plinth", "concrete", "75736b", "615e59", {"stain_amount": 0.6}],
		["l3_facade", "concrete", "706b63", "59544f", {"pattern": 1, "pattern_scale": Vector2(3.0, 1.5), "grout_width": 0.01, "grout_color": Color("595752"), "stain_amount": 0.5, "floor_y": -5.0}],
		["l3_stone", "concrete", "807a70", "6b665e", {"pattern": 14, "pattern_scale": Vector2(1.2, 0.6), "grout_width": 0.008, "grout_color": Color("4c4742"), "roughness_a": 0.5, "stain_amount": 0.4}],
		["l3_makeshift", "brick", "806b5c", "5c5457", {"pattern": 4, "pattern_scale": Vector2(0.42, 0.16), "grout_width": 0.01, "grout_color": Color("4c4742"), "tile_variation": 0.35, "noise_scale": 4.0, "stain_amount": 0.5, "floor_y": -5.0, "grime_height": 1.5}],
		["l3_wood", "wood_floor", "6b4c30", "523824", {"pattern_scale": Vector2(0.18, 2.4), "stain_amount": 0.5}],
		["l3_marble", "plaster", "dbd9cf", "bdbab2", {"noise_scale": 2.5, "roughness_a": 0.35, "roughness_b": 0.55, "stain_amount": 0.45, "stain_color": Color("8c8575")}],
		["l3_glyphs", "plaster", "b2ad9e", "9e998c", {"pattern": 8, "pattern_scale": Vector2(0.05, 0.07), "pattern_color": Color("4c4740"), "pattern_strength": 0.9}],
		["l3_canvas", "plaster", "d1ccbd", "66544c", {"noise_scale": 0.7, "noise_mix": 0.8, "stain_amount": 0.7, "stain_color": Color("401a14"), "stain_scale": 1.6}],
		["l3_bars", "metal", "333336", "262629", {"metallic_value": 0.7, "roughness_a": 0.45, "stain_amount": 0.4, "stain_color": Color("4c2e1a")}],
		["l3_lockbox", "metal", "4c4740", "38332e", mt],
		["l3_steel", "metal", "6b6b69", "52524f", mt],
		["l3_fixture", "metal", "99998f", "7a7a73", {"metallic_value": 0.2}],
		["l3_cable", "plaster", "0d0d0d", "0a0a0a", {"roughness_a": 0.6}],
		["l3_conduit", "metal", "80807a", "666661", mt],
		["l3_conduit_grey", "metal", "5c6161", "474c4c", mt],
		["l3_pipe_black", "plaster", "0d0d0d", "14120f", {"roughness_a": 0.25, "roughness_b": 0.5, "stain_amount": 0.4, "stain_color": Color("402914")}],
		["l3_flange", "rust", "4c3321", "2e1f14"],
		["l3_pipe_rust", "rust", "6b4024", "45291a"],
		["l3_ebox", "metal", "8c8c80", "737369", mt],
		["l3_ebox_grey", "metal", "575c5e", "45474a", mt],
		["l3_ebox_green", "metal", "475c4c", "38473d", mt],
		["l3_cabinet", "metal", "6b736b", "545c54", {"metallic_value": 0.3, "stain_amount": 0.55, "peel_amount": 0.2, "peel_color": Color("59381f")}],
		["l3_louvre", "metal", "1f1f1f", "1a1a1a", {"pattern": 2, "pattern_scale": Vector2(1.0, 0.04), "pattern_color": Color("61615c"), "pattern_strength": 0.8}],
		["l3_dial", "plaster", "e0dbc7", "ccc7b2", {"roughness_a": 0.3}],
		["l3_outlet", "plaster", "c7bd9e", "a8997a", {"stain_amount": 0.8, "stain_color": Color("261a0f")}],
		["l3_rail", "metal", "b8941f", "94731a", {"metallic_value": 0.2, "stain_amount": 0.5, "stain_color": Color("403326")}],
		["l3_grate", "metal", "575754", "3d3d3b", {"metallic_value": 0.55, "pattern": 1, "pattern_scale": Vector2(0.04, 0.04), "grout_width": 0.24, "grout_color": Color("0d0d0d"), "roughness_a": 0.6}],
		["l3_gen_body", "metal", "4c6154", "3d4c42", {"metallic_value": 0.3, "stain_amount": 0.6, "peel_amount": 0.25, "peel_color": Color("4c2e1a")}],
		["l3_gen_drum", "metal", "546b5e", "42544a", {"metallic_value": 0.35, "stain_amount": 0.55}],
		["l3_gen_band", "metal", "333333", "292929", {"metallic_value": 0.6}],
		["l3_boiler", "rust", "4c3324", "2b1f17", {"stain_amount": 0.7, "stain_color": Color("0a0a0a")}],
		["l3_car_paint", "metal", "5c211a", "4c1c17", {"metallic_value": 0.5, "roughness_a": 0.35, "stain_amount": 0.35, "stain_color": Color("594c40")}],
		["l3_car_glass", "plaster", "0f1214", "0d0f12", {"roughness_a": 0.05, "roughness_b": 0.1}],
		["l3_tyre", "plaster", "0f0f0f", "0d0d0d"],
		["l3_chrome", "metal", "bfbfbd", "999999", {"metallic_value": 0.95, "roughness_a": 0.15}],
		["l3_belt", "plaster", "141414", "0f0f0f", {"pattern": 2, "pattern_scale": Vector2(1.0, 0.12), "pattern_color": Color("242424"), "pattern_strength": 0.6}],
		["l3_sign_yellow", "plaster", "dbb229", "c2991f", {"stain_amount": 0.5}],
		["l3_sign_white", "plaster", "dbd9cc", "c7c4b8", {"stain_amount": 0.45}],
		["l3_sludge", "plaster", "040403", "080605", {"roughness_a": 0.05, "roughness_b": 0.12, "wetness": 1.0}],
		["l3_purple", "brick", "6b1f9e", "4c127a", {"pattern": 4, "pattern_scale": Vector2(0.23, 0.075), "grout_color": Color("8040b2"), "emission_color": Color("8026d9"), "emission_energy": 0.35}],
		["l3_purple_flesh", "plaster", "732499", "471466", {"bump_strength": 1.6, "emission_color": Color("8026d9"), "emission_energy": 0.4}],
		["l3_cardboard", "plaster", "8c6b42", "785936", {"stain_amount": 0.4}],
		["l3_bottle", "plaster", "e0dbb8", "ccc799", {"roughness_a": 0.1, "roughness_b": 0.2}],
		["l3_drum_blue", "metal", "1f3d73", "1a2e57", {"metallic_value": 0.3, "stain_amount": 0.6}],
		["l3_crate", "wood_floor", "80613d", "664a2b", {"pattern_scale": Vector2(0.14, 1.0)}],
		["l3_door", "metal", "5c615c", "474c47", {"metallic_value": 0.35, "stain_amount": 0.6, "stain_color": Color("4c331f"), "grime_height": 0.5}],
		["l3_lift", "metal", "9e9e99", "858580", {"metallic_value": 0.6, "roughness_a": 0.3, "pattern": 2, "pattern_scale": Vector2(0.01, 1.0), "pattern_color": Color("8f8f8a"), "pattern_strength": 0.3}],
		["l3_glass_dark", "plaster", "0d0f12", "0a0d0f", {"roughness_a": 0.04, "roughness_b": 0.08, "metallic_value": 0.6}],
		["l3_oil", "plaster", "1a1612", "29211a", {"roughness_a": 0.2, "roughness_b": 0.6, "noise_scale": 3.0}],
		["l3_rubber", "plaster", "1a1a1a", "141414"]]:
		_m(d[0], d[1], Color(d[2]), Color(d[3]), (d[4] as Dictionary).duplicate() if d.size() > 4 else {})
	MatLib.register("l3_tube", MatLib.panel(Color("ebf2e0"), 2.4))
	MatLib.register("l3_tube_warm", MatLib.panel(Color("ffdb9e"), 2.2))
	MatLib.register("l3_tube_dead", MatLib.panel(Color("1a1a1a"), 0.0, 0.0, 100.0))
	MatLib.register("l3_fireglow", MatLib.panel(Color("ff6b1f"), 2.6, 0.25))
	MatLib.register("l3_headlamp", MatLib.panel(Color("d9d1b2"), 0.6))
	MatLib.register("l3_taillamp", MatLib.panel(Color("99140d"), 0.8))
	MatLib.register("l3_red_led", MatLib.panel(Color("ff1f14"), 3.5))
	MatLib.register("l3_green_led", MatLib.panel(Color("4cff66"), 3.0))
	MatLib.register("l3_sun", MatLib.panel(Color("fff0cc"), 9.0))
	MatLib.register("l3_sun_dim", MatLib.panel(Color("ffebc2"), 1.3))
	MatLib.register("l3_win_warm", MatLib.panel(Color("ff9e4c"), 0.6))
	MatLib.register("l3_win_cool", MatLib.panel(Color("c7e0ff"), 0.45))
	MatLib.register("l3_win_shop", MatLib.panel(Color("ffcc80"), 0.75))
	MatLib.register("l3_sign_red", MatLib.panel(Color("ff402e"), 1.6))
	MatLib.register("l3_sign_blue", MatLib.panel(Color("4c8cff"), 1.6))
	MatLib.register("l3_sign_green", MatLib.panel(Color("59ff80"), 1.4))
	MatLib.register("l3_screen", MatLib.panel(Color("73bfff"), 1.4, 0.2))


# --------------------------------------------------------------- lighting

## Ceiling batten + pooled light. state: "on" | "dead" | "flicker" | "warm"
func lamp(k: GeoKit, pos: Vector3, along: Vector3, hang: float = 0.0, state: String = "on", rng_e: float = 7.0, energy: float = 1.0) -> void:
	var mat: String = {"dead": "l3_tube_dead", "warm": "l3_tube_warm"}.get(state, "l3_tube")
	var fl := 0.9 if state == "flicker" else 0.0
	var at := K.batten(k, tubes, pos, along, mat, pos.x * 0.37 + pos.z, fl, hang)
	if state != "dead":
		var col := Color("ffd699") if state == "warm" else Color("ebf2db")
		lights.add_anchor(at, col, energy * (1.0 if state != "flicker" else 0.8), rng_e, fl)


## A tube that can shatter (own mesh so it can go dark alone).
func fragile_lamp(k: GeoKit, pos: Vector3, along: Vector3) -> void:
	var fk := kit("Fragile%d" % fragile.size())
	fk.shadows = false
	var at := K.batten(k, fk, pos, along, "l3_tube", 3.0, 0.3, 0.0)
	fk.commit()
	var idx := lights.add_anchor(at, Color("ebf2db"), 1.0, 7.0, 0.3)
	fragile.append({"kit": fk, "pos": at, "anchor": idx, "broken": false})


# ------------------------------------------------------------------ halls

func _halls(k: GeoKit, r: RandomNumberGenerator) -> void:
	var w1: String = WALLS[r.randi() % 4]
	var w2: String = WALLS[(WALLS.find(w1) + 1 + r.randi() % 3) % 4]
	# --- arrival hall, narrow part (x -0.5..12) and wide part (x 12..30)
	K.hall(k, Vector3(-0.5, 0, 0), Vector3(12, 0, 0), 2.8, 3.2, w1, [{"at": 8.5, "w": 2.6, "h": 2.6}], [])
	K.hall(k, Vector3(12, 0, 0), Vector3(30, 0, 0), 4.4, 4.0, w2,
		[{"at": 6.0, "w": 2.2, "h": 2.8}, {"at": 15.2, "w": 0.9, "h": 2.0}], [{"at": 3.0, "w": 1.6, "h": 2.3}, {"at": 13.0, "w": 2.0, "h": 2.6}])
	k.wall(Vector3(12, 0, -1.7), Vector3(12, 0, 1.7), 4.0, 0.3, w2, [{"at": 1.7, "w": 2.8, "h": 3.2}])
	sys.car_plug(w1)
	for s: float in [-1.0, 1.0]:
		k.box_mm(Vector3(11.85, 0, 1.55 * s if s > 0 else -2.5), Vector3(12.15, 4.0, 2.5 if s > 0 else -1.55), w2)
	# the door you came through (Level 2 side) behind the arrival point
	k.wall(Vector3(-0.5, 0, -1.55), Vector3(-0.5, 0, 1.55), 3.2, 0.3, w1, [{"at": 1.55, "w": 1.0, "h": 2.1}])
	k.box(Vector3(-0.44, 1.05, 0), Vector3(0.06, 2.1, 1.0), "l3_door")
	K.obox(k, Vector3(-0.38, 1.0, 0.36), Vector3(1, 0, 0), Vector3(0.1, 0.05, 0.05), "l3_steel")
	add_interactable(Vector3(-0.3, 1.1, 0), Vector3(0.3, 2.0, 1.0), "Try the door", func(_p): Overlay.toast("It will not open from this side. Whatever brought you through it is gone.", 3.5))
	# dressing along both walls of the arrival hall
	for wd in [[-0.3, -1.4, 7.0, 3.2, 1.0], [-0.3, 1.4, 11.8, 3.2, 1.0], [10.0, -1.4, 11.8, 3.2, 1.0], [12.3, -2.2, 16.8, 4.0, 1.4],
			[19.2, -2.2, 26.6, 4.0, 1.4], [12.3, 2.2, 14.1, 4.0, 1.0], [15.9, 2.2, 23.9, 4.0, 1.4], [26.1, 2.2, 29.8, 4.0, 1.0]]:
		K.wall_dress(k, r, Vector3(wd[0], 0, wd[1]), Vector3(wd[2], 0, wd[1]), Vector3(0, 0, -signf(wd[1])), wd[3], true, wd[4])
	var others: Array = WALLS.filter(func(m): return m != w2)
	K.patches(k, r, Vector3(12.0, 0, -2.2), Vector3(30.0, 0, -2.2), Vector3(0, 0, 1), 4.0, others, [[4.8, 7.2], [14.6, 15.8]])
	K.patches(k, r, Vector3(12.0, 0, 2.2), Vector3(30.0, 0, 2.2), Vector3(0, 0, -1), 4.0, others, [[2.1, 3.9], [11.9, 14.1]])
	K.patches(k, r, Vector3(-0.5, 0, 1.4), Vector3(12.0, 0, 1.4), Vector3(0, 0, -1), 3.2, WALLS.filter(func(m): return m != w1))
	for x: float in [3.0, 7.4, 11.0]:
		lamp(k, Vector3(x, 3.2, 0), Vector3(1, 0, 0), 0.0, "dead" if x == 7.4 else "on")
	lamp(k, Vector3(15.5, 4.0, 0.6), Vector3(1, 0, 0), 0.6)
	fragile_lamp(k, Vector3(21.0, 3.4, 0.6), Vector3(1, 0, 0))
	lamp(k, Vector3(26.5, 4.0, 0.6), Vector3(1, 0, 0), 0.6, "flicker")
	# overhead cable trays and the main black-liquid trunk in the wide hall
	for z: float in [-1.7, 1.7]:
		k.box_mm(Vector3(12.2, 3.55, z - 0.25), Vector3(29.9, 3.6, z + 0.25), "l3_steel", GeoKit.ALL, false)
		for i in 5:
			K.pipe(k, Vector3(12.2, 3.63, z - 0.15 + i * 0.07), Vector3(29.9, 3.63, z - 0.15 + i * 0.07), 0.025, "l3_cable", 5)
	K.pipe(k, Vector3(12.0, 3.25, 1.75), Vector3(30.2, 3.25, 1.75), 0.2, "l3_pipe_black", 12)
	for i in 3:
		K.pipe(k, Vector3(-0.3, 3.05 - i * 0.02, -0.9 + i * 0.22), Vector3(12.0, 3.05 - i * 0.02, -0.9 + i * 0.22), 0.05 + 0.03 * (i % 2), ["l3_pipe_black", "l3_conduit", "l3_pipe_rust"][i], 8)
	K.pipe(k, Vector3(12.0, 3.75, -0.6), Vector3(30.2, 3.75, -0.6), 0.14, "l3_pipe_rust", 10)
	# M.E.G. guidance (page: signs within a wide radius to help wanderers find Base Gamma)
	K.sign(k, "M.E.G.\nBASE GAMMA  →\nfollow the arrows", Vector3(4.5, 1.7, 1.38), Vector3(0, 0, -1), 0.7, 0.45)
	K.sign(k, "BASE GAMMA  →", Vector3(28.4, 2.2, -2.18), Vector3(0, 0, 1), 0.8, 0.22)
	for i in 3:
		var p := Vector3(13.5 + i * 5.5 + r.randf_range(-0.6, 0.6), 0, r.randf_range(1.0, 1.7) * (1.0 if i % 2 == 0 else -1.0))
		if absf(p.x - 15.0) < 1.2 or absf(p.x - 25.0) < 1.4 or absf(p.x - 18.0) < 1.4:
			p.x += 2.2
		K.crate(k, p, Vector3(0.8, 0.6, 0.6), r.randf_range(-0.3, 0.3), "l3_crate")
	K.drum(k, Vector3(29.0, 0, -1.6), "l3_drum_blue")
	sys.live_wire(k, Vector3(20.6, 3.55, 1.7), Vector3(20.1, 0.02, 1.3))
	sys.outlet(k, Vector3(10.4, 0.42, -1.38), Vector3(0, 0, 1))
	# barred branch north (x 18): the hallway continues beyond, out of reach
	_barred(k, r, Vector3(18, 0, -2.2), Vector3(18, 0, -16), 2.2, 2.8, w1, false)
	# barred branch south (x 25) with a rare lock-pickable gate
	_barred(k, r, Vector3(25, 0, 2.2), Vector3(25, 0, 15), 2.0, 2.6, w1, true)
	# boiler corridor (x 15, south) and paranoia-hotspot crawl to the Sanctum (x 27.2, north)
	K.hall(k, Vector3(15, 0, 2.2), Vector3(15, 0, 9.0), 1.6, 2.4, w2)
	lamp(k, Vector3(15, 2.4, 5.5), Vector3(0, 0, 1), 0.0, "flicker")
	K.wall_dress(k, r, Vector3(14.2, 0, 2.6), Vector3(14.2, 0, 8.6), Vector3(1, 0, 0), 2.4, true, 0.4)
	_hotspot_passage(k, w1)


## A side branch: bars just inside the mouth; the hallway runs on beyond with a
## far, dim light and a turn, so the maze is visible but unreachable.
func _barred(k: GeoKit, r: RandomNumberGenerator, a: Vector3, b: Vector3, w: float, h: float, wall: String, gate: bool) -> void:
	K.hall(k, a, b, w, h, wall, [{"at": (b - a).length() - 1.6, "w": w, "h": h}], [])
	var f := (b - a).normalized()
	var side := U.cross(f).normalized()
	k.wall(b - side * (w * 0.5 + 0.3), b + side * (w * 0.5 + 0.3), h, 0.3, wall)
	var sa := b - f * 1.6 + side * (w * 0.5)
	K.hall(k, sa, sa + side * 3.2, w, h, wall)
	k.wall(sa + side * 3.35 - f * (w * 0.5 + 0.3), sa + side * 3.35 + f * (w * 0.5 + 0.3), h, 0.3, wall)
	var bp := a + f * 0.7
	if not gate:
		K.bars(k, bp - side * (w * 0.5 + 0.1), bp + side * (w * 0.5 + 0.1), h, false)
	bar_views.append({"c": bp + U * 1.5, "n": f})
	var ln := (b - a).length()
	K.wall_dress(k, r, a - side * (w * 0.5) + f * 1.2, b - side * (w * 0.5) - f * 0.3, side, h, true, 0.5)
	K.wall_dress(k, r, a + side * (w * 0.5) + f * 1.2, b + side * (w * 0.5) - f * 2.5, -side, h, true, 0.5)
	lamp(k, a + f * 2.6 + U * h, f, 0.0, "on", 7.0, 1.1)
	lamp(k, a + f * (ln * 0.55) + U * h, f, 0.0, "dead")
	lamp(k, b - f * 1.2 + U * h, f, 0.0, "flicker", 5.0)
	if gate:
		var gp := a + f * 6.2
		K.bars(k, gp - side * (w * 0.5 + 0.1), gp + side * (w * 0.5 + 0.1), h, false)
		sys.gate_pocket(k, bp, f, side, w, h)
	else:
		K.crate(k, a + f * (ln * 0.7) + side * 0.4, Vector3(0.9, 0.7, 0.7), 0.3, "l3_crate")


func _hotspot_passage(k: GeoKit, wall: String) -> void:
	var x := 27.2
	K.hall(k, Vector3(x, 0, -2.2), Vector3(x, 0, -8), 0.85, 2.1, wall)
	K.hall(k, Vector3(x, 0, -8), Vector3(x, 0, -12.5), 0.85, 1.45, wall)
	K.hall(k, Vector3(x, 0, -12.5), Vector3(x, 0, -21.0), 1.1, 2.4, wall)
	k.wall(Vector3(x - 0.6, 1.45, -8), Vector3(x + 0.6, 1.45, -8), 1.0, 0.3, wall)
	k.wall(Vector3(x - 0.7, 1.45, -12.5), Vector3(x + 0.7, 1.45, -12.5), 1.3, 0.3, wall)
	k.box_mm(Vector3(x - 0.75, 0, -12.65), Vector3(x - 0.42, 1.45, -12.35), wall)
	k.box_mm(Vector3(x + 0.42, 0, -12.65), Vector3(x + 0.75, 1.45, -12.35), wall)
	for i in 6:
		K.pipe(k, Vector3(x - 0.36, 0.25 + i * 0.22, -2.4), Vector3(x - 0.36, 0.25 + i * 0.22, -20.8), 0.02 + 0.01 * (i % 2), ["l3_cable", "l3_conduit"][i % 2], 5)
	lamp(k, Vector3(x, 2.4, -17.0), Vector3(0, 0, 1), 0.0, "flicker", 4.0)
	hotspots.append(AABB(Vector3(x - 0.7, -0.5, -21.0), Vector3(1.4, 3.0, 18.8)))
	K.sign(k, "M.E.G. NOTICE\nPARANOIA HOTSPOT\nDo not linger.\nYour camera will not record\nwhat you hear in here.", Vector3(x + 0.85, 1.55, -2.21), Vector3(0, 0, 1), 0.62, 0.55, "l3_sign_white", Color("800d08"), 34)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	sys.on_ready()


func level_process(delta: float) -> void:
	if player != null:
		sys.tick(delta)


func qa_capture_plan() -> Array:
	return sys.capture_plan()


func qa_self_test() -> Array:
	var checks: Array = await sys.self_test()
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var upper := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(59.0, 7.2, 21.0), Vector3(59.0, 5.7, 21.0), 1))
	checks.append({"what": "assembly hall third-level grated cross-bridge is collidable", "ok": not upper.is_empty() and absf(float(upper.get("position", Vector3.ZERO).y) - 6.2) < 0.14, "detail": upper.get("position", Vector3.ZERO)})
	var ramp := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(48.0, 6.5, 37.0), Vector3(48.0, 3.3, 37.0), 1))
	checks.append({"what": "assembly upper stair is physically sloped between 3.6m and 6.2m", "ok": not ramp.is_empty() and float(ramp.get("position", Vector3.ZERO).y) > 4.4 and float(ramp.get("position", Vector3.ZERO).y) < 5.6, "detail": ramp.get("position", Vector3.ZERO)})
	return checks
