extends LevelBase
## Level 25 - "The Quarter Hub" (Backrooms Wikidot rev 50, accessed 2026-11-04;
## cite: Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L025.md.
## A long-abandoned, ransacked 1980s arcade: echoey maroon play rooms full of
## wrecked cabinets, dusty shelves nailed to tall walls, a dripping polystyrene
## ceiling, cold back halls with boxes and boilers. About 1 in 1500 machines
## works: insert a quarter, try to play, and it sends you to its tethered level
## (a return machine waits behind you on arrival). The Level 10 machine is dead.
## Authored 52 m hub (notes by the Level 4 closet door, two play rooms, back
## halls, the marked working machines) inside a finite streaming window of
## seeded 26 m blocks bounded at the page's 9.2 x 8.5 mile estimate.
## Entities: none (the page records none). Props/cabinets: L025_props.gd.

const P := preload("res://levels/L025/L025_props.gd")
const CS := 26.0
const HP := 5.6
const BX := 284
const BZ := 263
const SLOTS := [3.2, 7.6, 18.4, 22.8]
const CORE_WORK := [
	["L025>L000#1", Vector3(14.58, 0, 3.2), Vector3(1, 0, 0)],
	["L025>L011#5", Vector3(51.42, 0, 10.0), Vector3(-1, 0, 0)],
	["L025>L037#9", Vector3(31.16, 0, 20.08), Vector3(0, 0, -1)],
	["L025>L005#2", Vector3(14.58, 0, 34.0), Vector3(1, 0, 0)],
	["L025>L009#3", Vector3(30.0, 0, 38.92), Vector3(0, 0, 1)],
	["L025>L019#6", Vector3(24.0, 0, 51.42), Vector3(0, 0, -1)],
	["L025>L188#17", Vector3(51.42, 0, 48.0), Vector3(-1, 0, 0)]]
const FAR := ["L025>L024#7", "L025>L029#8", "L025>L050#10", "L025>L090#11", "L025>L108#12", "L025>L120#13",
	"L025>L141#14", "L025>L150#15", "L025>L165#16", "L025>L201#18", "L025>L790#19", "L025>L888#20", "L025>L040#21"]
## Openings in the hub's outer walls (world coordinate along the side, width, height).
const CORE_OPS := {"W": [[10.0, 1.6, 2.4], [24.0, 1.2, 2.2], [48.0, 1.2, 2.2]],
	"E": [[6.0, 2.0, 2.6], [22.0, 2.4, 3.0], [36.0, 2.4, 3.0]],
	"N": [[20.0, 2.4, 3.0], [33.0, 2.4, 3.0]], "S": [[7.0, 2.0, 2.4], [30.0, 3.0, 3.2]]}
const CORE_SEGS := [["W", 0.0, 14.0, "l25_wall"], ["W", 14.0, 26.0, "l25_back"], ["W", 26.0, 52.0, "l25_back"],
	["E", 0.0, 26.0, "l25_wall"], ["E", 26.0, 44.0, "l25_wall"], ["E", 44.0, 52.0, "l25_wall_d"],
	["N", 0.0, 26.0, "l25_wall"], ["N", 26.0, 52.0, "l25_wall"],
	["S", 0.0, 14.0, "l25_back"], ["S", 14.0, 26.0, "l25_wall"], ["S", 26.0, 44.0, "l25_wall"], ["S", 44.0, 52.0, "l25_wall_d"]]
## Interior hub walls: a, b, height, paint on the +normal side, paint on the other, openings.
const CORE_WALLS := [
	[Vector2(14, 0), Vector2(14, 14), 5.8, "l25_wall", "l25_wall", [[7.0, 2.6, 3.0]]],
	[Vector2(14, 14), Vector2(14, 28), 5.8, "l25_back", "l25_wall", []],
	[Vector2(14, 28), Vector2(14, 52), 5.8, "l25_back", "l25_wall", [[13.2, 2.2, 2.5]]],
	[Vector2(0, 14), Vector2(14, 14), 4.2, "l25_back", "l25_wall", [[7.0, 1.4, 2.3]]],
	[Vector2(14, 28), Vector2(52, 28), 5.8, "l25_wall", "l25_wall", [[7.0, 3.2, 3.4], [28.0, 2.2, 2.6]]],
	[Vector2(5.8, 14), Vector2(5.8, 52), 3.0, "l25_back", "l25_back", [[8.0, 1.1, 2.2], [22.0, 1.1, 2.2], [34.0, 1.1, 2.2]]],
	[Vector2(8.2, 14), Vector2(8.2, 52), 3.0, "l25_back", "l25_back", [[7.0, 1.1, 2.2], [19.0, 1.1, 2.2], [27.2, 2.4, 2.6], [33.0, 1.1, 2.2]]],
	[Vector2(0, 29), Vector2(5.8, 29), 3.0, "l25_back", "l25_back", []],
	[Vector2(0, 43), Vector2(5.8, 43), 3.0, "l25_back", "l25_back", []],
	[Vector2(8.2, 26), Vector2(14, 26), 3.0, "l25_back", "l25_back", []],
	[Vector2(8.2, 40), Vector2(14, 40), 3.0, "l25_back", "l25_back", []],
	[Vector2(8.2, 42.4), Vector2(14, 42.4), 3.0, "l25_back", "l25_back", []],
	[Vector2(44, 44), Vector2(44, 52), 5.4, "l25_wall_d", "l25_wall", [[3.0, 1.2, 2.2]]],
	[Vector2(44, 44), Vector2(52, 44), 5.4, "l25_wall_d", "l25_wall", []]]
const NOTES := "If you're reading this, you found the place I've been calling the Quarter Hub.\n\nOn the surface it's a busted old arcade. Dust on everything, the paint fading off the walls and the machines, a little mould, outlets that spit sparks, and water dripping from pipes somewhere above the foam ceiling tiles. Most of the cabinets were wrecked on purpose: burn marks, bat dents, even a few bullet holes.\n\nA few still work. I've found maybe twenty. Drop a quarter in, try to play, and you're somewhere else: whatever level that machine is tied to. Every time, there's been another machine right behind me for the trip back. There's a second, bigger slot under the quarter slot. No idea what money that one takes.\n\nQuarters turn up in boxes and in the corners. People have been marking the working machines with numbers, sometimes a word about what's on the other side. Read the words.\n\nI came through a door in Level 4 that looked like a janitor's closet, and I'm leaving these right where I came out. My guess is somebody built all this long ago as a paid way of getting around. I don't know who. Maybe you'll figure it out."

var world: ChunkWorld
var cabs: Dictionary = {}      # edge -> machine state (see P.working)
var leaks: Array = []          # {p, g}
var sparks: Array = []         # {p, t, l}
var far_at: Dictionary = {}    # Vector2i block -> edge placed there
var qa := false
var _tick := 0.0
var _drop: MeshInstance3D
var _drop_t := 0.0
var _drip_cap := 0.0
var _motes: GPUParticles3D


func build() -> void:
	qa = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.82
	rules["reverb_wet"] = 0.32
	rules["view_distance"] = 150.0
	indoor_env(Color(0.62, 0.44, 0.42), 0.1, Color(0.1, 0.075, 0.07), 0.022)
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.85
	environment.glow_bloom = 0.12
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	environment.adjustment_contrast = 1.12
	P.materials()
	lights.setup(12, 1)
	lights.max_distance = 32.0
	_place_far()
	var k := kit("Hub")
	_core(k, k.root)
	k.commit()
	world = ChunkWorld.new()
	world.name = "Blocks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.chunk_unloaded.connect(_unloaded)
	world.build_around(Vector3(26, 0, 26), 2)
	add_arrival("start", Vector3(4.0, 0.05, 1.8), _yaw(Vector3(4, 0, 1.8), Vector3(14, 0, 7)))
	for w in CORE_WORK:
		var f: Vector3 = w[2]
		var p: Vector3 = w[1] + f * 1.35
		add_arrival("from_" + str(w[0]).substr(5, 4), p + Vector3.UP * 0.05, _yaw(p, p + f))
	sound.bed("room_tone", {"cutoff": 210.0, "rumble": 0.25}, -22.0)
	sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.12}, -38.0)
	sound.oneshot("creak", {"freq": 85.0}, 35.0, 100.0, 16.0, "[the old building creaks]", -20.0)
	sound.oneshot("drip", {"freq": 1050.0}, 7.0, 20.0, 15.0, "", -24.0)
	_drop = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.014
	sm.height = 0.04
	_drop.mesh = sm
	_drop.material_override = MatLib.get_mat("glass")
	_drop.visible = false
	add_child(_drop)
	_motes = P.dust_motes()
	add_child(_motes)
	add_shot("hub", Vector3(46.5, 1.65, 18.3), Vector3(16.0, 1.15, 17.6))
	add_shot("cabinet", Vector3(49.75, 1.62, 46.75), Vector3(51.4, 1.15, 48.05))
	add_shot("zstart", Vector3(4.0, 1.62, 1.8), Vector3(14, 1.3, 7))
	add_shot("zrow", Vector3(33.4, 1.6, 17.2), Vector3(31.0, 1.15, 20.1))
	add_shot("zback", Vector3(7.0, 1.62, 36.0), Vector3(6.6, 1.0, 47.0))
	add_shot("zblock", Vector3(60.0, 1.62, 13.0), Vector3(75.0, 1.2, 13.0))
	add_landmark("Notes by the janitor's-closet door", Vector3(5.6, 0, 0.8))
	add_landmark("Big play room", Vector3(33, 0, 14))


func _yaw(from: Vector3, to: Vector3) -> float:
	return rad_to_deg(atan2(-(to.x - from.x), -(to.z - from.z)))


func _h(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


## Unbuilt-route machines and the Level 40 window: seeded blocks 4-9 out.
func _place_far() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "far"])
	for e in FAR:
		while true:
			var a := r.randf() * TAU
			var d := r.randf_range(4.0, 9.0)
			var key := Vector2i(roundi(0.5 + cos(a) * d), roundi(0.5 + sin(a) * d))
			if maxi(absi(key.x * 2 - 1), absi(key.y * 2 - 1)) < 7 or far_at.has(key):
				continue
			far_at[key] = e
			break


# ------------------------------------------------------------------ hub

func _core(k: GeoKit, node: Node3D) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2517   # the authored hub is identical in every expedition
	k.slab(0, 0, 52, 14, 0.0, 0.3, "l25_carpet", GeoKit.PY)
	k.slab(14, 14, 52, 52, 0.0, 0.3, "l25_carpet", GeoKit.PY)
	k.slab(0, 14, 14, 52, 0.0, 0.3, "l25_concrete", GeoKit.PY)
	_ceil(k, Rect2(0, 0, 14, 14), 4.2, r, "hub", [])
	_ceil(k, Rect2(14, 0, 38, 28), 5.8, r, "hub", [Vector2(24.0, 8.0), Vector2(44.0, 12.9), Vector2(35.5, 18.0), Vector2(22.7, 24.6), Vector2(47.2, 25.0)])
	_ceil(k, Rect2(14, 28, 30, 24), 5.4, r, "hub", [Vector2(38.5, 34.0), Vector2(20.5, 45.5)])
	_ceil(k, Rect2(44, 28, 8, 16), 5.4, r, "hub", [])
	_ceil(k, Rect2(44, 44, 8, 8), 5.4, r, "hub", [], false)
	_ceil(k, Rect2(0, 14, 14, 38), 3.0, r, "hub", [Vector2(6.6, 46.5)], false)
	for s in CORE_SEGS:
		_core_side(k, s)
	for w in CORE_WALLS:
		var ops := []
		for o in w[5]:
			ops.append({"at": o[0], "w": o[1], "h": o[2]})
		var a: Vector2 = w[0]
		var b: Vector2 = w[1]
		P.wall2(k, Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), w[2], w[3], w[4], ops)
	# --- notes room: the Level 4 closet door, Fletcher's notes, quarters
	k.box(Vector3(4.0, 1.06, 0.18), Vector3(0.96, 2.12, 0.05), "l25_door")
	k.box(Vector3(4.0, 2.17, 0.18), Vector3(1.16, 0.09, 0.07), "l25_metal")
	for s in [-1.0, 1.0]:
		k.box(Vector3(4.0 + s * 0.54, 1.08, 0.18), Vector3(0.08, 2.16, 0.07), "l25_metal")
	k.box(Vector3(4.36, 1.0, 0.23), Vector3(0.05, 0.05, 0.06), "l25_metal")
	add_interactable(Vector3(4.0, 1.06, 0.3), Vector3(1.0, 2.1, 0.2), "Janitor's-closet door", func(_p):
		Overlay.toast("It won't open from this side. Whoever left the notes came through it from Level 4.", 3.5))
	k.box(Vector3(5.7, 0.25, 0.78), Vector3(0.7, 0.5, 0.55), "l25_wood")
	k.box(Vector3(5.62, 0.506, 0.74), Vector3(0.24, 0.012, 0.32), "l25_paper")
	add_note("l25_notes", "Notes left by the closet door", NOTES, Vector3(5.62, 0.56, 0.74), Vector3(0.42, 0.12, 0.42))
	P.box(self, k, node, Vector3(12.6, 0, 1.0), "b_nr", 2)
	P.quarter(self, node, Vector3(0.45, 0, 13.5), "q_nr")
	for z in [4.5, 5.22, 5.94, 11.9, 12.62]:
		P.dead(k, Vector3(0.58, 0, z), PI * 0.5, r, 0.15, false)
	for x in [9.6, 10.32, 11.04, 12.5]:
		P.dead(k, Vector3(x, 0, 13.42), PI, r, 0.15, false)
	P.cab(k, Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(8.6, 0.4, 8.0)), 2, "smash", r)
	P.examine(self, Vector3(8.6, 0.4, 7.2), "smash")
	# --- big play room: aisles of back-to-back rows, wall rows, shelves
	for zr in [5.5, 10.5, 15.5, 20.5]:
		for x0 in [19.0, 29.0, 39.0]:
			for i in 8:
				for s in [-1.0, 1.0]:
					var p := Vector3(x0 + i * 0.72, 0, zr + s * 0.42)
					if p.distance_to(Vector3(31.16, 0, 20.08)) < 0.1 or r.randf() < 0.09:
						continue
					P.dead(k, p, 0.0 if s > 0 else PI, r, 0.14, false)
	for i in 7:
		P.dead(k, Vector3(22.6 + i * 0.72, 0, 0.58), 0.0, r, 0.1, false)
		P.dead(k, Vector3(36.2 + i * 0.72, 0, 0.58), 0.0, r, 0.1, false)
	for i in 8:
		P.dead(k, Vector3(51.42, 0, 12.6 + i * 0.72), -PI * 0.5, r, 0.1, false)
	for q in [Vector3(26.4, 0, 8.0), Vector3(43.5, 0, 13.0), Vector3(22.0, 0, 18.1), Vector3(40.5, 0, 24.5)]:
		P.dead(k, q, r.randf() * TAU, r, 1.0, true)
	P.cab(k, Transform3D(Basis(Vector3.UP, PI), Vector3(24.76, 0, 10.08)), 0, "bullets", r)
	P.examine(self, Vector3(24.76, 1.0, 9.5), "bullets")
	P.litter(k, Rect2(14.5, 0.5, 37, 27), r, 70)
	P.litter(k, Rect2(0.5, 0.5, 13, 13), r, 14)
	P.litter(k, Rect2(14.5, 28.5, 29, 23), r, 50)
	for y in [3.4, 4.5]:
		P.shelf(k, Vector3(14.4, y, 0.15), Vector3(51.6, y, 0.15), Vector3(0, 0, 1), r)
	P.shelf(k, Vector3(51.85, 3.6, 0.6), Vector3(51.85, 3.6, 27.4), Vector3(-1, 0, 0), r)
	P.outlet(self, k, Vector3(37.0, 0.32, 27.84), Vector3(0, 0, -1), true)
	P.quarter(self, node, Vector3(51.55, 0, 0.45), "q_mpr1")
	P.quarter(self, node, Vector3(14.45, 0, 27.55), "q_mpr2")
	# --- second play room: looser, burnt corner, the Level 188 alcove
	for zr in [33.0, 38.5]:
		var x0 := 20.0 if zr == 33.0 else 26.4
		for i in (8 if zr == 33.0 else 10):
			for s in [-1.0, 1.0]:
				var p := Vector3(x0 + i * 0.72, 0, zr + s * 0.42)
				if p.distance_to(Vector3(30.0, 0, 38.92)) < 0.2 or r.randf() < 0.14:
					continue
				P.dead(k, p, 0.0 if s > 0 else PI, r, 0.25, false)
	for i in 10:
		P.dead(k, Vector3(15.0 + i * 0.72, 0, 51.42), PI, r, 0.1, false)
	for i in 5:
		P.dead(k, Vector3(32.4 + i * 0.72, 0, 51.42), PI, r, 0.1, false)
	for z in [29.2, 29.92, 30.64, 31.36, 36.2, 36.92, 37.64, 38.36, 43.4, 44.12, 44.84, 46.6, 47.32, 48.8, 49.52, 50.24]:
		P.dead(k, Vector3(14.58, 0, z), PI * 0.5, r, 0.1, false)
	for z in [29.0, 29.72, 30.44, 31.16, 31.88, 39.0, 39.72, 40.44, 41.16]:
		P.dead(k, Vector3(51.42, 0, z), -PI * 0.5, r, 0.1, false)
	for i in 7:
		var bp := Vector3(36.4 + r.randf() * 5.0, 0, 45.6 + r.randf() * 4.0)
		P.cab(k, Transform3D(Basis(Vector3.UP, r.randf() * TAU), bp), r.randi() % 5, "burnt", r)
	P.patch(k, Vector3(38.8, 0, 47.8), 3.4, "l25_scorch")
	P.examine(self, Vector3(36.6, 1.0, 45.0), "burnt")
	for q in [Vector3(38.0, 0, 31.4), Vector3(42.5, 0, 36.9), Vector3(19.2, 0, 46.2), Vector3(27.5, 0, 45.0)]:
		P.dead(k, q, r.randf() * TAU, r, 1.0, true)
	P.shelf(k, Vector3(14.4, 3.3, 51.85), Vector3(43.6, 3.3, 51.85), Vector3(0, 0, -1), r)
	P.quarter(self, node, Vector3(43.6, 0, 51.55), "q_spr")
	# --- back halls: boilers, boxes, pipes, the dead Level 10 machine
	P.boiler(self, k, node, Vector3(1.7, 0, 17.6), Vector3(1, 0, 0), "boil_a", "almond_water")
	P.boiler(self, k, node, Vector3(1.7, 0, 20.6), Vector3(1, 0, 0), "boil_b", "snacks")
	P.box(self, k, node, Vector3(4.6, 0, 27.6), "b_w1", 1)
	P.box(self, k, node, Vector3(0.9, 0, 30.6), "b_w2a", 2)
	P.box(self, k, node, Vector3(0.9, 0, 41.6), "b_w2b", 0)
	P.box(self, k, node, Vector3(4.7, 0, 41.6), "b_w2c", 1)
	P.box(self, k, node, Vector3(13.2, 0, 16.9), "b_e1a", 1)
	P.box(self, k, node, Vector3(13.2, 0, 25.0), "b_e1b", -1)
	P.box(self, k, node, Vector3(13.1, 0, 51.0), "b_e3", 1)
	for z in [27.0, 28.2, 31.5, 34.2, 37.6, 38.7]:
		P.stack(k, Vector3(12.9, 0, z), r)
	P.quarter(self, node, Vector3(7.85, 0, 51.6), "q_c1")
	P.pipe(k, Vector3(6.3, 2.7, 14.2), Vector3(6.3, 2.7, 51.8), 0.06, "l25_pipe")
	P.pipe(k, Vector3(7.7, 2.78, 14.2), Vector3(7.7, 2.78, 51.8), 0.09, "l25_pipe")
	for i in 6:
		var on := i in [0, 2, 3, 5]
		var bp := Vector3(7.0, 2.996, 17.0 + i * 6.0)
		k.panel(bp, 0.22, 0.22, "l25_panel_bulb", float(i) if on else 120.0, 0.5 if i == 3 else 0.0)
		if on:
			lights.add_anchor(bp - Vector3(0, 0.3, 0), Color(1.0, 0.76, 0.5), 0.75, 7.0, 0.5 if i == 3 else 0.0, "hub")
	P.outlet(self, k, Vector3(5.96, 0.32, 31.0), Vector3(1, 0, 0), true)
	var x10 := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(6.22, 0, 46.5))
	P.cab(k, x10, 4, "dead", r)
	P.marks(k, node, x10, "10", "DEAD. WATER GOT IN")
	P.patch(k, Vector3(6.9, 0, 46.6), 0.9, "l25_puddle")
	add_interactable(Vector3(6.68, 0.62, 46.5), Vector3(0.3, 0.6, 0.62), "Coin slot", func(_p):
		Overlay.toast("The slot is rusted solid. Water has run through this one for years: dead screen, swollen wood. Whatever it was tied to, it isn't any more.", 4.0))
	# --- the marked working machines
	for w in CORE_WORK:
		P.working(self, k, node, w[1], w[2], w[0], "hub")


## One stretch of the hub's outer wall; the outer face takes the neighbouring block's paint.
func _core_side(k: GeoKit, s: Array) -> void:
	var side: String = s[0]
	var t0: float = s[1]
	var t1: float = s[2]
	var mid := (t0 + t1) * 0.5
	var nb: Vector2i
	var a: Vector3
	var b: Vector3
	match side:
		"W":
			a = Vector3(0, 0, t0); b = Vector3(0, 0, t1); nb = Vector2i(-1, int(mid / CS))
		"E":
			a = Vector3(52, 0, t0); b = Vector3(52, 0, t1); nb = Vector2i(2, int(mid / CS))
		"N":
			a = Vector3(t0, 0, 0); b = Vector3(t1, 0, 0); nb = Vector2i(int(mid / CS), -1)
		_:
			a = Vector3(t0, 0, 52); b = Vector3(t1, 0, 52); nb = Vector2i(int(mid / CS), 2)
	var ops := []
	for o in CORE_OPS[side]:
		if o[0] > t0 and o[0] < t1:
			ops.append({"at": o[0] - t0, "w": o[1], "h": o[2]})
	var inner: String = s[3]
	var outer := _paint(nb.x, nb.y)
	# +normal side is outside for W and S, inside for E and N
	if side in ["W", "S"]:
		P.wall2(k, a, b, 5.8, outer, inner, ops)
	else:
		P.wall2(k, a, b, 5.8, inner, outer, ops)


## Drop ceiling of 2.6 m panels; listed points become missing-tile holes with a leak.
func _ceil(k: GeoKit, R: Rect2, y: float, r: RandomNumberGenerator, g: String, holes: Array, lamps := true) -> void:
	var nx := maxi(1, roundi(R.size.x / 2.6))
	var nz := maxi(1, roundi(R.size.y / 2.6))
	var sx := R.size.x / nx
	var sz := R.size.y / nz
	var skip := {}
	for h in holes:
		skip[Vector2i(int((h.x - R.position.x) / sx), int((h.y - R.position.y) / sz))] = true
	for j in nz:
		for i in nx:
			var c := Vector3(R.position.x + (i + 0.5) * sx, y, R.position.y + (j + 0.5) * sz)
			if skip.has(Vector2i(i, j)):
				P.hole(k, c, sx, sz)
				leaks.append({"p": c + Vector3.UP * 0.45, "g": g})
				continue
			k.box(c + Vector3.UP * 0.05, Vector3(sx, 0.1, sz), "l25_ceiling", GeoKit.NY, false)
			if lamps and i % 3 == 1 and j % 2 == 1:
				var on := r.randf() < 0.3
				var fl := 0.7 if on and r.randf() < 0.3 else 0.0
				k.panel(c - Vector3(0, 0.004, 0), 1.2, 0.6, "l25_panel_troffer", float(i * 7 + j) if on else 130.0, fl)
				if on:
					lights.add_anchor(c - Vector3(0, 1.3, 0), Color(1.0, 0.84, 0.64), 1.3, 10.5, fl, g)


# --------------------------------------------------------------- blocks

func _core_key(cx: int, cz: int) -> bool:
	return cx >= 0 and cx <= 1 and cz >= 0 and cz <= 1


func _out(cx: int, cz: int) -> bool:
	return cx < -BX or cx > BX or cz < -BZ or cz > BZ


func _kind(cx: int, cz: int) -> String:
	var e: String = far_at.get(Vector2i(cx, cz), "")
	if e != "":
		return "back" if e.ends_with("#21") else "play"
	var h := _h(cx, cz, 3)
	return "play" if h < 0.56 else ("split" if h < 0.8 else "back")


func _paint(cx: int, cz: int) -> String:
	if _core_key(cx, cz):
		return "l25_wall"
	if _kind(cx, cz) == "back":
		return "l25_back"
	var h := _h(cx, cz, 5)
	return "l25_wall" if h < 0.68 else ("l25_wall_b" if h < 0.84 else "l25_wall_c")


## Openings on the border between block (ax,az) and its +axis neighbour.
func _border(ax: int, az: int, axis: String) -> Array:
	var bx := ax + int(axis == "x")
	var bz := az + int(axis == "z")
	if _out(ax, az) or _out(bx, bz):
		return []
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "b", axis, ax, az])
	var wide := _kind(ax, az) == "play" and _kind(bx, bz) == "play"
	var slots: Array = SLOTS.duplicate()
	var out := []
	for i in 1 + r.randi() % 3:
		var s: float = slots.pop_at(r.randi() % slots.size())
		out.append({"at": s, "w": r.randf_range(2.4, 3.4) if wide else r.randf_range(1.2, 1.6), "h": 3.2 if wide else 2.3})
	return out


func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if _core_key(cx, cz) or _out(cx, cz):
		return {"kind": "hub" if _core_key(cx, cz) else "void"}
	var kind := _kind(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz])
	var k := GeoKit.new(node, "K")
	var o := Vector3(cx * CS, 0, cz * CS)
	var g := "%d,%d" % [cx, cz]
	var pm := _paint(cx, cz)
	for ax in ["x", "z"]:
		var nx := cx + int(ax == "x")
		var nz := cz + int(ax == "z")
		if _core_key(nx, nz):
			continue
		var a := o + (Vector3(CS, 0, 0) if ax == "x" else Vector3(0, 0, CS))
		var theirs := _paint(nx, nz)
		P.wall2(k, a, o + Vector3(CS, 0, CS), 5.8, pm if ax == "x" else theirs, theirs if ax == "x" else pm, _border(cx, cz, ax))
	if cx == -BX:
		P.wall2(k, o, o + Vector3(0, 0, CS), 5.8, pm, pm, [])
	if cz == -BZ:
		P.wall2(k, o, o + Vector3(CS, 0, 0), 5.8, pm, pm, [])
	var e: String = far_at.get(Vector2i(cx, cz), "")
	match kind:
		"play":
			_play(k, node, o, Rect2(0, 0, CS, CS), r, g, e)
		"split":
			_split(k, node, o, r, g, pm)
		_:
			_back(k, node, o, r, g, e)
	k.commit()
	return {"kind": kind, "machine": e}


## A play room over rect R (block-local): carpet, drop ceiling, islands of dead cabinets.
func _play(k: GeoKit, node: Node3D, o: Vector3, R: Rect2, r: RandomNumberGenerator, g: String, e: String) -> void:
	var w := Rect2(o.x + R.position.x, o.z + R.position.y, R.size.x, R.size.y)
	k.slab(w.position.x, w.position.y, w.end.x, w.end.y, 0.0, 0.3, "l25_carpet", GeoKit.PY)
	var holes := []
	for i in r.randi() % 3:
		holes.append(Vector2(r.randf_range(w.position.x + 2.0, w.end.x - 2.0), r.randf_range(w.position.y + 2.0, w.end.y - 2.0)))
	_ceil(k, w, HP, r, g, holes)
	var along_x := R.size.x > R.size.y or (R.size.x == R.size.y and r.randf() < 0.5)
	var la := R.size.x if along_x else R.size.y
	var lp := R.size.y if along_x else R.size.x
	var center := Vector3(w.get_center().x, 0, w.get_center().y)
	var rows := []
	var p := 3.8 + r.randf() * 1.2
	while p < lp - 3.6:
		rows.append(p)
		p += r.randf_range(6.0, 7.6)
	for rp in rows:
		var a := 3.4 + r.randf() * 1.5
		while a < la - 4.0:
			var n := mini(4 + r.randi() % 5, int((la - 3.4 - a) / 0.72))
			for i in n:
				for s in [-1.0, 1.0]:
					var t: float = a + i * 0.72
					var u: float = rp + s * 0.42
					var q := o + (Vector3(R.position.x + t, 0, R.position.y + u) if along_x else Vector3(R.position.x + u, 0, R.position.y + t))
					if (e != "" and q.distance_to(center) < 4.0) or r.randf() < 0.1:
						continue
					var yaw: float = (0.0 if s > 0 else PI) if along_x else (PI * 0.5 if s > 0 else -PI * 0.5)
					P.dead(k, q, yaw, r, 0.15, false)
			a += n * 0.72 + r.randf_range(1.8, 3.4)
	for i in rows.size() - 1:
		if r.randf() < 0.5:
			var m: float = (rows[i] + rows[i + 1]) * 0.5
			var t2 := r.randf_range(5.0, la - 5.0)
			var q2 := o + (Vector3(R.position.x + t2, 0, R.position.y + m) if along_x else Vector3(R.position.x + m, 0, R.position.y + t2))
			if e == "" or q2.distance_to(center) > 4.0:
				P.dead(k, q2, r.randf() * TAU, r, 1.0, true)
	P.litter(k, w, r, int(w.size.x * w.size.y / 16.0))
	var corners := [Vector2(0.45, 0.45), Vector2(R.size.x - 0.45, 0.45), Vector2(0.45, R.size.y - 0.45), Vector2(R.size.x - 0.45, R.size.y - 0.45)]
	for i in 4:
		if r.randf() < 0.22:
			var c: Vector2 = corners[i]
			P.quarter(self, node, o + Vector3(R.position.x + c.x, 0, R.position.y + c.y), "q%s_%d_%d" % [g, int(R.position.x + R.position.y), i])
	if r.randf() < 0.6:
		var y := 3.4 + r.randf() * 0.7
		var x0 := w.position.x + 0.15
		var x1 := w.end.x - 0.15
		var z0 := w.position.y + 0.15
		var z1 := w.end.y - 0.15
		match r.randi() % 4:
			0: P.shelf(k, Vector3(x0 + 0.4, y, z0), Vector3(x1 - 0.4, y, z0), Vector3(0, 0, 1), r)
			1: P.shelf(k, Vector3(x0 + 0.4, y, z1), Vector3(x1 - 0.4, y, z1), Vector3(0, 0, -1), r)
			2: P.shelf(k, Vector3(x0, y, z0 + 0.4), Vector3(x0, y, z1 - 0.4), Vector3(1, 0, 0), r)
			_: P.shelf(k, Vector3(x1, y, z0 + 0.4), Vector3(x1, y, z1 - 0.4), Vector3(-1, 0, 0), r)
	if e != "":
		var f: Vector3 = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT][r.randi() % 4]
		P.working(self, k, node, center, f, e, g)


## Two play rooms either side of a narrow back hallway with doors into both.
func _split(k: GeoKit, node: Node3D, o: Vector3, r: RandomNumberGenerator, g: String, pm: String) -> void:
	var ax := r.randf() < 0.5
	_play(k, node, o, Rect2(0, 0, CS, 11.8) if ax else Rect2(0, 0, 11.8, CS), r, g, "")
	_play(k, node, o, Rect2(0, 14.2, CS, 11.8) if ax else Rect2(14.2, 0, 11.8, CS), r, g, "")
	var H := Rect2(o.x, o.z + 11.8, CS, 2.4) if ax else Rect2(o.x + 11.8, o.z, 2.4, CS)
	k.slab(H.position.x, H.position.y, H.end.x, H.end.y, 0.0, 0.3, "l25_concrete", GeoKit.PY)
	k.slab(H.position.x, H.position.y, H.end.x, H.end.y, 3.2, 0.2, "l25_concrete", GeoKit.NY)
	for s in [11.8, 14.2]:
		var ops := []
		var sl: Array = [4.0, 9.0, 17.0, 22.0]
		for i in 2:
			ops.append({"at": sl.pop_at(r.randi() % sl.size()), "w": 1.2, "h": 2.3})
		var a := o + (Vector3(0, 0, s) if ax else Vector3(s, 0, 0))
		var b := a + (Vector3(CS, 0, 0) if ax else Vector3(0, 0, CS))
		var back_pos: bool = ax == (s < 13.0)
		P.wall2(k, a, b, HP, "l25_back" if back_pos else pm, pm if back_pos else "l25_back", ops)
	for i in 4:
		var t := 3.2 + i * 6.5
		var on := r.randf() < 0.45
		var bp := o + (Vector3(t, 3.196, 13.0) if ax else Vector3(13.0, 3.196, t))
		k.panel(bp, 0.22, 0.22, "l25_panel_bulb", t if on else 120.0, 0.0)
		if on:
			lights.add_anchor(bp - Vector3(0, 0.3, 0), Color(1.0, 0.76, 0.5), 0.7, 6.5, 0.0, g)
	if r.randf() < 0.45:
		var t := 1.6 if r.randf() < 0.5 else CS - 1.6
		var side := 1.0 if r.randf() < 0.5 else -1.0
		var q := o + (Vector3(t, 0, 13.0 + side * 0.78) if ax else Vector3(13.0 + side * 0.78, 0, t))
		var f := (Vector3(0, 0, -side) if ax else Vector3(-side, 0, 0))
		P.dead(k, q, atan2(f.x, f.z), r, 0.0, false)


## Back-scene block: a 2.4 m ring corridor along the borders around four storerooms.
func _back(k: GeoKit, node: Node3D, o: Vector3, r: RandomNumberGenerator, g: String, e: String) -> void:
	k.slab(o.x, o.z, o.x + CS, o.z + CS, 0.0, 0.3, "l25_concrete", GeoKit.PY)
	k.slab(o.x, o.z, o.x + CS, o.z + CS, 3.0, 0.2, "l25_concrete", GeoKit.NY)
	var lo := 2.4
	var hi := CS - 2.4
	var win := e != ""
	var sides := [[Vector3(lo, 0, lo), Vector3(hi, 0, lo), 5.3], [Vector3(hi, 0, lo), Vector3(hi, 0, hi), 5.3],
		[Vector3(lo, 0, hi), Vector3(hi, 0, hi), 15.9], [Vector3(lo, 0, lo), Vector3(lo, 0, hi), 15.9]]
	for i in 4:
		var sd: Array = sides[i]
		var ops := []
		if not (win and i == 3):
			ops.append({"at": sd[2], "w": 1.1, "h": 2.2})
		if win and i == 2:
			ops.append({"at": 5.3, "w": 1.3, "h": 1.3, "sill": 0.9})
		P.wall2(k, o + sd[0], o + sd[1], 3.0, "l25_back", "l25_back", ops)
	P.wall2(k, o + Vector3(13, 0, lo), o + Vector3(13, 0, hi), 3.0, "l25_back", "l25_back", [])
	P.wall2(k, o + Vector3(lo, 0, 13), o + Vector3(hi, 0, 13), 3.0, "l25_back", "l25_back", [])
	var rooms := [Vector2(7.7, 7.7), Vector2(18.3, 7.7), Vector2(7.7, 18.3), Vector2(18.3, 18.3)]
	for i in 4:
		var c := o + Vector3(rooms[i].x, 0, rooms[i].y)
		if win and i == 2:
			k.box_mm(o + Vector3(2.6, 0.02, 13.2), o + Vector3(12.8, 2.95, 23.4), "unlit_black", GeoKit.ALL, false)
			continue
		for j in 1 + r.randi() % 3:
			var x := r.randf()
			P.box(self, k, node, c + Vector3(r.randf_range(-3.4, 3.4), 0, r.randf_range(-3.4, 3.4)), "b%s_%d_%d" % [g, i, j],
				(1 + int(r.randf() < 0.3)) if x < 0.35 else (0 if x < 0.75 else -1), r.randf() * TAU)
		if r.randf() < 0.3:
			P.boiler(self, k, node, c + Vector3(-2.6, 0, -2.6), Vector3(1, 0, 0), "boil%s_%d" % [g, i], ["almond_water", "snacks", ""][r.randi() % 3])
		if r.randf() < 0.3:
			var on := r.randf() < 0.5
			k.panel(c + Vector3(0, 2.996, 0), 0.22, 0.22, "l25_panel_bulb", float(i) if on else 120.0, 0.0)
			if on:
				lights.add_anchor(c + Vector3(0, 2.6, 0), Color(1.0, 0.74, 0.48), 0.6, 6.0, 0.0, g)
	for i in 12:
		var t := 3.0 + (i % 3) * 10.0
		var bp: Vector3 = [Vector3(t, 0, 1.2), Vector3(CS - 1.2, 0, t), Vector3(t, 0, CS - 1.2), Vector3(1.2, 0, t)][floori(i / 3.0)]
		var on := r.randf() < 0.42
		k.panel(o + bp + Vector3.UP * 2.996, 0.22, 0.22, "l25_panel_bulb", float(i) if on else 120.0, 0.6 if on and r.randf() < 0.2 else 0.0)
		if on:
			lights.add_anchor(o + bp + Vector3.UP * 2.6, Color(1.0, 0.74, 0.48), 0.65, 6.5, 0.0, g)
	for i in r.randi() % 3:
		var q := [Vector3(lo + 1.0, 0, lo - 0.42), Vector3(hi + 0.42, 0, hi - 1.0), Vector3(hi - 1.0, 0, hi + 0.42), Vector3(lo - 0.42, 0, lo + 1.0)][r.randi() % 4] as Vector3
		var f := Vector3(signf(q.x - 13.0) if absf(q.x - 13.0) > 11.0 else 0.0, 0, signf(q.z - 13.0) if absf(q.z - 13.0) > 11.0 else 0.0)
		P.dead(k, o + q, atan2(f.x, f.z), r, 0.0, false)
	if win:
		var wp := o + Vector3(lo + 5.3, 1.55, hi)
		for i in 6:
			k.box(o + Vector3(lo + 5.3 + r.randf_range(-0.8, 0.8), 0.01, hi + r.randf_range(0.3, 1.2)), Vector3(0.08, 0.008, 0.05), "glass", GeoKit.PY, false)
		k.quad(wp + Vector3(-0.45, 0.4, 0.1), Vector3(0, 0, 1), Vector3(0.2, 0, 0), Vector3(0, 0.25, 0), "glass")
		P.emit(node, "wind", wp, {}, -12.0, 10.0)
		make_exit(e, "interact", wp + Vector3(0, -0.55, 0.9), Vector3(1.6, 2.0, 1.2), "Climb out through the broken window", node)


func _unloaded(key: Vector2i) -> void:
	var g := "%d,%d" % [key.x, key.y]
	lights.remove_group(g)
	leaks = leaks.filter(func(l): return l["g"] != g)


# -------------------------------------------------------------- machines

## Player (or QA bot via the ExitTrigger condition) operates a working machine.
func use_machine(_p: Variant, e: String) -> void:
	var c: Dictionary = cabs.get(e, {})
	if c.is_empty() or not is_instance_valid(c["it"]):
		return
	var at: Vector3 = c["pos"] + Vector3.UP * 0.7
	if c["st"] == "idle":
		if SaveService.item_count("quarter") <= 0:
			Overlay.toast("The coin slot takes a quarter. You don't have one; they turn up in boxes and corners.", 3.0)
			return
		sound.play_at("pipe_clank", {"f": 2300.0}, at, -9.0, "[a quarter rattles into the slot]")
		if rng.randf() < 0.2:
			Overlay.subtitle("[the coin drops straight through to the return cup]", 2.5)
			return
		SaveService.add_item("quarter", -1)
		c["st"] = "credit"
	elif c["st"] == "credit":
		sound.play_at("ui", {"kind": "click"}, at, -6.0)
		P.jingle(self, c["pos"] + Vector3.UP * 1.3)
		Overlay.subtitle("[you press START and the screen floods with light]", 2.0)
		c["st"] = "launch"
		c["t"] = 1.7
	refresh(c)


func machine_ready(e: String) -> bool:
	var c: Dictionary = cabs.get(e, {})
	if c.is_empty():
		return false
	if c["st"] == "ready":
		return true
	if c["st"] != "launch":
		use_machine(null, e)
	return false


func refresh(c: Dictionary) -> void:
	if not is_instance_valid(c["it"]):
		return
	var q := SaveService.item_count("quarter")
	var st: String = c["st"]
	(c["it"] as Interactable).prompt = {"idle": ("Insert a quarter (you have %d)" % q) if q > 0 else "Coin slot (no quarters)",
		"credit": "Press START", "launch": "", "ready": ""}[st]
	(c["txt"] as Label3D).text = {"idle": "INSERT COIN", "credit": "CREDIT 1\nPRESS START", "launch": "", "ready": ""}[st]
	(c["mat"] as ShaderMaterial).set_shader_parameter("mode", {"idle": 0.0, "credit": 1.0, "launch": 2.0, "ready": 2.0}[st])


func _reset(e: String) -> void:
	var c: Dictionary = cabs.get(e, {})
	if not c.is_empty() and c["st"] == "ready":
		c["st"] = "idle"
		refresh(c)


# ---------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if qa:
		SaveService.scope()["inventory"]["quarter"] = 1
		qa_routes.append({"edge": "L025>L000#1", "target": Vector3(15.5, 0, 3.2), "note": "QA fixture: the wanderer carries one quarter; nearest marked machine"})
	elif SessionState.is_story():
		if spawn_report.get("used_arrival", "") != "checkpoint_position":
			checkpoint(str(spawn_report.get("used_arrival", "start")))
		if not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
			Overlay.subtitle("[dust, old carpet, water dripping somewhere above the ceiling]", 5.0)
	for e in cabs.keys():
		refresh(cabs[e])


func level_process(delta: float) -> void:
	if player == null:
		return
	_tick -= delta
	var blink := fmod(Time.get_ticks_msec() * 0.001, 1.1) < 0.7
	for e in cabs.keys():
		var c: Dictionary = cabs[e]
		if not is_instance_valid(c["it"]):
			cabs.erase(e)
			continue
		if c["st"] == "idle":
			(c["txt"] as Label3D).visible = blink
		elif c["st"] == "launch":
			c["t"] = float(c["t"]) - delta
			if c["t"] <= 0.0:
				c["st"] = "ready"
				var t: ExitTrigger = c["trig"]
				if is_instance_valid(t):
					t.fire()
				get_tree().create_timer(3.0).timeout.connect(_reset.bind(e))
		if _tick <= 0.0:
			refresh(c)
	if _tick <= 0.0:
		_tick = 0.5
	_motes.global_position = player.global_position + Vector3.UP * 1.2
	_leaks(delta)
	for s in sparks:
		s["t"] = float(s["t"]) - delta
		var l: OmniLight3D = s["l"]
		l.light_energy = maxf(0.0, l.light_energy - delta * 10.0)
		if s["t"] <= 0.0:
			s["t"] = randf_range(4.0, 14.0)
			if player.global_position.distance_to(s["p"]) < 14.0:
				l.light_energy = 2.6
				sound.play_at("crackle", {"seconds": 0.5}, s["p"], -10.0, "[a faulty outlet crackles and spits sparks]")


## The nearest leak drips: a falling droplet and a plip on the floor.
func _leaks(delta: float) -> void:
	var pp := player.global_position
	var best: Dictionary = {}
	var bd := 169.0
	for l in leaks:
		var d := pp.distance_squared_to(l["p"])
		if d < bd:
			bd = d
			best = l
	_drip_cap = maxf(0.0, _drip_cap - delta)
	if best.is_empty():
		_drop.visible = false
		return
	var top: Vector3 = best["p"]
	_drop_t += delta
	var f := _drop_t / 0.9
	if f >= 1.0:
		_drop_t = -randf_range(0.5, 2.5)
		sound.play_at("drip", {"freq": 1100.0}, Vector3(top.x, 0.05, top.z), -12.0)
		if _drip_cap <= 0.0 and bd < 36.0:
			_drip_cap = 45.0
			Overlay.subtitle("[water drips through a gap in the ceiling tiles]", 2.5)
	_drop.visible = _drop_t >= 0.0
	var ff := clampf(f, 0.0, 1.0)
	_drop.global_position = Vector3(top.x, lerpf(top.y, 0.03, ff * ff), top.z)
