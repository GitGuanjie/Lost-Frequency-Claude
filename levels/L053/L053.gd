extends LevelBase
## Level 53 "Alone" (Backrooms Wikidot rev 22, accessed 2026-11-04; Stretchsterz, CC BY-SA
## 3.0; original by u/Fox"Foxtrot"Carmen and u/208.87.77). Dossier: docs/canon/levels/L053.md.
## Nearly every level fact is TESTIMONY (Allen Grady's letter "Attempt 53"); the closing
## M.E.G. Report 8734 is the article's in-universe report.
##
## PLAN (v2.0 rebuild: read -> design). Authored, not seeded (procedural: false).
## - TESTIMONY: his own ordinary house (bedrooms, bathroom, kitchen, devices, basement),
##   December 2008 with the Christmas decorations still up; the house "fell": glass shards
##   and objects on the floor -> a two-storey suburban house plus basement (three walkable
##   heights, two real stairs), a decorated tree, garland, wreath, shards, a fallen chair.
## - TESTIMONY: the outside world is visible through the windows: a nice neighbourhood,
##   people walking, nobody responds; once a group stood staring -> a built street with
##   houses, trees and walkers; a staring group appears if you watch the street too long.
##   The sky never gets dark: always about 7 AM (a low morning sun); the clock reads 4:23.
## - TESTIMONY: the front door leads back into the house; a window that finally broke led
##   back in again -> seamless in-level loops (you step out and are stepping back in).
## - TESTIMONY: food appears in a pile on the basement's concrete floor, middle of the room,
##   at random times (once not for weeks); carry it up to the fridge; water only from the
##   fridge with a filter pitcher; utensils work (cooking); TV works but no cable; Wi-Fi
##   barely works; Louie the mouse lives in an old hamster cage upstairs.
## - TESTIMONY: tall, slender, faceless visitors wander in: sit at the table, on the couch,
##   look out of windows, sit beside you at the TV. Harmless. They move when unobserved.
## - Signature mechanic (stateful): the mail slot. Things pushed through never appear on the
##   other side. Write a letter at the desk and post it: this is Attempt 53 (Allen sent 52).
##   ARTICLE (M.E.G. Report 8734): an operative found "Attempt 53" in front of the red-painted
##   door of a small house on Level 9, and the team breached the door (locked on one side
##   only) and rescued him -> after a wait, knocks, voices, the door bursts in; walk out onto
##   Level 9 (exit L053>L009#1, the walker's target; the QA fixture starts with it breached).
## - ABSENT: hostility, a way out without rescue, a reachable outdoors, a darkening sky.

const House := preload("res://levels/L053/L053_house.gd")
const INSIDE_DOOR := Vector3(0.3, 0.02, 4.3)
const START := Vector3(-5.1, 0.02, 0.1)
const SPOTS := [[Vector3(-2.0, 0.0, 1.75), 90.0, true], [Vector3(-4.5, 0.0, -2.05), 0.0, true], [Vector3(-3.5, 0.0, 4.45), 180.0, false],
	[Vector3(2.5, 0.0, -3.95), 0.0, false], [Vector3(-3.5, 2.9, 4.45), 180.0, false], [Vector3(-2.7, 0.0, -2.05), 0.0, true],
	[Vector3(3.6, 0.0, 4.45), 180.0, false], [Vector3(-2.0, 0.0, 2.65), 90.0, true]]

static var attempts := 52

var H
var qa_fixture := false
var spots: Dictionary = {}
var door: Node3D
var door_angle := 0.0
var door_target := 0.0
var breached := false
var rescue_t := -1.0
var letter := false
var carrying := false
var stored := 3
var pile_on := true
var food_t := 0.0
var tv_on := false
var _tv_near := 0.0
var _said := {}
var pile: Node3D
var louie: MeshInstance3D
var visitors: Array = []      # [{node, spot}]
var walkers: Array = []       # [{node, dir}]
var starers: Array = []
var _stare_t := 0.0
var _stare_on := -1.0
var _shuffle_t := 30.0
var operative: Node3D
var _loop_door: Area3D
var _loop_window: Area3D
var _static: AudioStreamPlayer3D
var _knocked := 0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.18
	rules["reverb_wet"] = 0.06
	outdoor_env(Color(0.40, 0.56, 0.82), Color(0.96, 0.80, 0.64), Color(0.32, 0.30, 0.26), Vector2(13.0, 45.0),
		Color(1.0, 0.84, 0.64), 1.7, Color(0.86, 0.84, 0.82), 0.0035)
	environment.ambient_light_energy = 0.3
	environment.tonemap_exposure = 1.05
	sun.directional_shadow_max_distance = 60.0
	House.materials()
	var root := Node3D.new()
	root.name = "Furnishings"
	add_child(root)
	H = House.new(self, root)
	H.shell()
	door = H.front_door()
	spots = H.interior()
	var out: Dictionary = H.outside()
	_people(float(out["street_z"]))
	_food()
	_lights()
	_sounds()
	_loops()
	_interactions()
	_notes()
	var exit := add_exit("L053>L009#1", "walk_in", Vector3(0.1, 1.0, 6.0), Vector3(1.4, 2.0, 1.0))
	if exit:
		exit.condition = func() -> bool: return breached
	add_arrival("start", START, -112.0)
	for tag in ["from_L009", "from_L094", "from_L053"]:
		add_arrival(tag, INSIDE_DOOR, 0.0)
	if qa_fixture:
		_breach(true)
	add_landmark("Front door (red outside), with the mail slot", House.DOOR)
	add_landmark("Living room and the Christmas tree", Vector3(-4.0, 0, 3.0))
	add_landmark("Basement food pile", spots["pile"])
	add_landmark("Louie's cage", spots["cage"])
	add_shot("living_room", Vector3(-1.6, 1.6, 0.2), Vector3(-5.2, 1.0, 4.2), {"flashlight": false, "prepare": _prep_people})
	add_shot("kitchen", Vector3(-1.0, 1.65, -1.2), Vector3(4.5, 1.0, -4.6), {"flashlight": false, "prepare": _prep_people})
	add_shot("front_window", Vector3(-3.0, 1.6, 3.2), Vector3(-1.0, 1.2, 30.0), {"flashlight": false, "prepare": _prep_stare})
	add_shot("basement", Vector3(-4.6, -1.05, 3.9), Vector3(0.3, -2.4, -1.4), {"flashlight": false})
	add_shot("upstairs", Vector3(0.6, UP_EYE, -3.6), Vector3(0.6, 3.6, 4.5), {"flashlight": false})
	add_shot("breached_door", Vector3(0.7, 1.6, 2.0), Vector3(0.1, 1.2, 8.0), {"flashlight": false})

const UP_EYE := 4.5


# ---------------------------------------------------------------- people

func _figure(pos: Vector3, yaw: float, kind: String, sit := false) -> Node3D:
	var root := Node3D.new()
	root.name = "Figure_" + kind
	root.position = pos
	root.rotation.y = deg_to_rad(yaw)
	add_child(root)
	var tall := 1.18 if kind == "visitor" else 1.0
	var thin := 0.72 if kind == "visitor" else 1.0
	var cloth: Color = {"visitor": Color(0.30, 0.30, 0.32), "meg": Color(0.12, 0.14, 0.12), "a": Color(0.25, 0.32, 0.5),
		"b": Color(0.5, 0.3, 0.2), "c": Color(0.3, 0.4, 0.3), "d": Color(0.55, 0.52, 0.48)}.get(kind, Color(0.3, 0.3, 0.3))
	var skin := MatLib.standard(Color(0.78, 0.76, 0.74) if kind == "visitor" else Color(0.72, 0.56, 0.44), 0.6)
	var mat := MatLib.standard(cloth, 0.8)
	var hip := (0.45 if sit else 0.9) * (1.0 if sit else tall)
	for x in [-0.1 * thin, 0.1 * thin]:
		if sit:
			var th := _part(root, "capsule", Vector3(x, 0.48, -0.2), Vector3(0.13 * thin, 0.5, 0.13), mat)
			th.rotation.x = PI * 0.5
			_part(root, "capsule", Vector3(x, 0.24, -0.42), Vector3(0.11 * thin, 0.48 * tall, 0.11), mat)
		else:
			_part(root, "capsule", Vector3(x, 0.46 * tall, 0), Vector3(0.13 * thin, 0.92 * tall, 0.13), mat)
	_part(root, "capsule", Vector3(0, hip + 0.35 * tall, 0), Vector3(0.40 * thin, 0.74 * tall, 0.24), mat)
	for s in [-1.0, 1.0]:
		var arm := _part(root, "capsule", Vector3(s * 0.25 * thin, hip + 0.22 * tall, 0), Vector3(0.09 * thin, 0.74 * tall, 0.09), mat if kind != "visitor" else skin)
		arm.rotation.z = s * 0.06
	_part(root, "sphere", Vector3(0, hip + 0.86 * tall, 0), Vector3(0.18 if kind == "visitor" else 0.21, 0.25, 0.2), skin)
	if kind == "meg":
		_part(root, "sphere", Vector3(0, hip + 0.95, 0), Vector3(0.26, 0.18, 0.27), MatLib.standard(Color(0.18, 0.2, 0.18), 0.5))
		_part(root, "box", Vector3(0, hip + 0.38, -0.13), Vector3(0.36, 0.42, 0.06), MatLib.standard(Color(0.2, 0.22, 0.2), 0.7))
		var arm := _part(root, "capsule", Vector3(0.28, hip + 0.5, -0.15), Vector3(0.09, 0.7, 0.09), mat)
		arm.rotation.x = -1.2
	return root


func _part(root: Node3D, mesh_type: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m: Mesh
	if mesh_type == "capsule":
		var cm := CapsuleMesh.new()
		cm.radius = size.x * 0.5
		cm.height = maxf(size.y, size.x + 0.01)
		cm.radial_segments = 10
		cm.rings = 4
		m = cm
	elif mesh_type == "sphere":
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 14
		sm.rings = 7
		m = sm
		mi.scale = size
	else:
		var bx := BoxMesh.new()
		bx.size = size
		m = bx
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


func _people(street_z: float) -> void:
	var order := [0, 3, 4]
	for i in 3:
		var sp: Array = SPOTS[order[i]]
		var v := _figure(sp[0], sp[1], "visitor", sp[2])
		visitors.append({"node": v, "spot": order[i]})
	var kinds := ["a", "b", "c", "d"]
	for i in 4:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var z := street_z if i < 2 else 14.6
		var w := _figure(Vector3(-40.0 + i * 23.0, -0.35, z), -90.0 * dir, kinds[i])
		walkers.append({"node": w, "dir": dir})
	for i in 5:
		var s := _figure(Vector3(-2.5 + i * 1.3, -0.35, street_z + 0.3 + (i % 2) * 0.7), 0.0, kinds[i % 4])
		s.visible = false
		starers.append(s)
	operative = _figure(Vector3(0.6, -0.02, 6.4), 0.0, "meg")
	operative.visible = false


# ---------------------------------------------------------------- systems

func _food() -> void:
	pile = Node3D.new()
	pile.name = "FoodPile"
	pile.position = spots["pile"]
	add_child(pile)
	var items := ["kenney/food-kit/carton", "kenney/food-kit/can-open", "kenney/food-kit/bag", "kenney/food-kit/soda-bottle",
		"kenney/food-kit/sandwich", "kenney/food-kit/can-open", "kenney/food-kit/carton", "kenney/food-kit/bag", "kenney/food-kit/pizza-box"]
	var r := RandomNumberGenerator.new()
	r.seed = 5301
	for i in items.size():
		var a := r.randf() * TAU
		var d := r.randf_range(0.0, 0.55)
		Props.place(self, pile, items[i], Vector3(cos(a) * d, 0.0, sin(a) * d), r.randf_range(0, 360), 0.28 if i % 3 != 2 else 0.4)
	make_interactable(Vector3(0, 0.3, 0), Vector3(1.4, 0.6, 1.4), "Gather up the food from the floor", _gather, pile)
	food_t = rng.randf_range(60.0, 200.0)


var _floor := -9
var _was_below := false


## Pooled lights leak through slabs, so the pool is fed one storey at a time.
func _lights() -> void:
	lights.setup(6, 1)
	_feed_lights(0)


func _feed_lights(f: int) -> void:
	if f == _floor:
		return
	_floor = f
	lights.clear_anchors()
	if f == -1:
		lights.add_anchor(spots["bulb"], Color(1.0, 0.78, 0.5), 1.3, 7.5, 0.03, "basement")
		return
	var y := 2.35 if f == 0 else 5.2
	var xs := [Vector3(-3.5, y, 2.2), Vector3(-3.5, y, -2.8), Vector3(3.0, y, -2.8), Vector3(3.6, y, 3.2), Vector3(0.6, y, 2.0)] if f == 0 \
		else [Vector3(-3.5, y, 2.6), Vector3(-3.5, y, -2.4), Vector3(3.6, y, 2.8), Vector3(3.5, y, -2.2), Vector3(0.6, y, -2.0)]
	for c in xs:
		lights.add_anchor(c, Color(1.0, 0.86, 0.66), 0.55, 4.5, 0.0, "rooms")
	if f == 0:
		lights.add_anchor(spots["tree"], Color(1.0, 0.5, 0.3), 0.5, 3.0, 0.2, "tree")


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 220.0, "rumble": 0.15, "seconds": 6.0}, -32.0)
	sound.emitter("fluorescent_hum", Vector3(5.2, 1.0, -3.55), {"base": 58.0, "seconds": 3.0}, -30.0, 6.0)
	sound.emitter("transformer", Vector3(-4.2, -1.8, 4.5), {"base": 50.0, "seconds": 4.0}, -26.0, 8.0)
	_static = sound.emitter("static", Vector3(-5.4, 0.8, 2.2), {"seconds": 3.0}, -80.0, 9.0)
	sound.oneshot("creak", {"freq": 90.0}, 25.0, 60.0, 10.0, "[the house settles]", -24.0)


func _loops() -> void:
	_loop_door = _loop_area(Vector3(0.1, 1.0, 5.6), Vector3(1.1, 2.0, 0.6), _loop_out_door)
	_loop_window = _loop_area(H.broken + Vector3(0, 1.0, -0.55), Vector3(1.2, 2.0, 0.6), _loop_out_window)


func _loop_area(c: Vector3, s: Vector3, cb: Callable) -> Area3D:
	var a := Area3D.new()
	a.name = "HouseLoop"
	a.position = c
	a.collision_layer = 0
	a.collision_mask = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s
	cs.shape = bs
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(_on_loop.bind(cb))
	return a


func _on_loop(b: Node3D, cb: Callable) -> void:
	if b is Player:
		cb.call(b as Player)


func _loop_out_door(p: Player) -> void:
	if breached:
		return
	_teleport(p, INSIDE_DOOR, 0.0)
	Overlay.subtitle("[you step out of the front door... and you are stepping in through your front door]" if not _said.has("door") else "[back inside. Again.]", 3.5)
	_said["door"] = true
	door_target = 0.0


func _loop_out_window(p: Player) -> void:
	_teleport(p, H.broken + Vector3(0, 0.02, 0.75), 180.0)
	Overlay.subtitle("[you climb out through the broken window... and climb in through it. It just leads back to your house.]", 4.0)


func _teleport(p: Player, pos: Vector3, yaw: float) -> void:
	Overlay.glitch(0.5)
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	p.global_position = pos
	p.rotation.y = deg_to_rad(yaw)
	p.velocity = p.global_transform.basis * Vector3(0, 0, -speed * 0.5)


func _interactions() -> void:
	make_interactable(Vector3(0.48, 1.35, 0.0), Vector3(0.9, 0.5, 0.2), "Open the front door", _door_use, door)
	make_interactable(Vector3(0.48, 1.0, -0.04), Vector3(0.36, 0.12, 0.08), "Push something through the mail slot", _mail, door)
	add_interactable(spots["desk"], Vector3(0.9, 0.3, 0.6), "Write a letter", _write)
	add_interactable(spots["fridge"], Vector3(0.5, 1.6, 0.9), "Open the fridge", _fridge)
	add_interactable(spots["stove"], Vector3(0.8, 0.4, 0.6), "Cook something", _cook)
	add_interactable(spots["sink"], Vector3(0.8, 0.4, 0.5), "Turn on the tap", func(_p: Player) -> void: Overlay.subtitle("[the tap runs. You let it go; the only water you trust is the filter pitcher in the fridge.]", 3.5))
	add_interactable(spots["tv"], Vector3(0.4, 0.5, 0.7), "Turn the TV on or off", _tv)
	add_interactable(spots["laptop"], Vector3(0.5, 0.3, 0.4), "Check the laptop", func(_p: Player) -> void: Overlay.subtitle("[one bar of Wi-Fi. The page has been loading for a long, long time.]", 3.5))
	add_interactable(spots["clock"], Vector3(0.15, 0.4, 0.4), "Look at the clock", func(_p: Player) -> void: Overlay.subtitle("[4:23 AM. Outside it looks like seven in the morning. It always does.]", 3.5))
	add_interactable(spots["cage"] + Vector3(0, 0.15, 0), Vector3(0.55, 0.35, 0.4), "Feed Louie", func(_p: Player) -> void: Overlay.subtitle("[Louie scurries over for a crumb. Still alone, but a little less.]", 3.5))
	for pn in H.panes:
		add_interactable(pn["c"], pn["size"], "Try to open the window", func(_p: Player) -> void: Overlay.subtitle("[it will not budge. Outside, someone walks past without looking up.]", 3.0))
	louie = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.05
	louie.mesh = sm
	louie.material_override = MatLib.standard(Color(0.45, 0.42, 0.40), 0.9)
	louie.position = spots["cage"] + Vector3(0, 0.07, 0)
	add_child(louie)


func _notes() -> void:
	add_note("l53_attempt52", "Letter (draft, Allen Grady)",
		"My name is Allen Grady. I'm trapped in my own home and I don't know how to get out. December 2008, nearly Christmas, alone in the house, and the whole house fell. The front door just leads back inside. If you find this: please help me.",
		spots["desk"] + Vector3(-0.4, -0.04, 0.05))
	add_note("l53_fridge", "Note stuck to the fridge",
		"WATER: fridge only. Use the filter pitcher.\nFOOD: check the basement. It turns up on the concrete, middle of the floor, whenever it feels like it. Get it all up here fast and wash it.",
		spots["fridge"] + Vector3(-0.32, 0.4, 0.0), Vector3(0.05, 0.25, 0.2), false)
	add_note("l53_visitors", "Scrap of paper by the couch",
		"They come and go. Tall, thin, no faces. One at the table, one on the couch, one at the window looking out. Sometimes one sits next to me while the TV plays. They've never done anything to me.",
		Vector3(-3.6, 0.44, 2.4))
	add_note("l53_cookbook", "Allen's cookbook",
		"Cooking is what I do now. Everything in the kitchen still works. I make a really good steak, if you ever want some. It's here for you any time you come by.",
		spots["cookbook"])


func _door_use(_p: Player) -> void:
	if breached:
		Overlay.subtitle("[the lock is splintered. The door hangs open.]", 2.5)
		return
	door_target = 95.0 if door_target < 45.0 else 0.0
	sound.play_at("creak", {"freq": 140.0}, House.DOOR + Vector3(0, 1.2, 0), -12.0, "[the front door opens onto a bright, quiet morning]" if door_target > 45.0 else "")


func _write(_p: Player) -> void:
	if letter:
		Overlay.subtitle("[the letter is written. It needs to go through the mail slot.]", 2.5)
		return
	letter = true
	Overlay.subtitle("[you write it all down: who you are, what happened, please help. At the top: Attempt %d.]" % (attempts + 1), 4.0)


func _mail(_p: Player) -> void:
	if breached:
		return
	if not letter:
		Overlay.subtitle("[only a letter fits through the slot. Something to write on is on the desk in the study.]", 3.5)
		return
	letter = false
	attempts += 1
	sound.play_at("scratch", {}, House.DOOR + Vector3(0.1, 1.0, 0), -14.0, "[paper scrapes through the slot]")
	Overlay.subtitle("[Attempt %d slips through. You open the door: nothing on the mat. It never appears on the other side.]" % attempts, 4.5)
	if attempts >= 53 and rescue_t < 0.0:
		rescue_t = rng.randf_range(70.0, 150.0)


func _gather(_p: Player) -> void:
	if not pile_on:
		Overlay.subtitle("[just a clean patch of concrete where the food turns up]", 2.5)
		return
	pile_on = false
	pile.visible = false
	carrying = true
	food_t = rng.randf_range(60.0, 240.0) if rng.randf() > 0.12 else 700.0
	Overlay.subtitle("[you scoop the whole pile into your arms. Up to the kitchen, quick, before any of it turns.]", 3.5)


func _fridge(_p: Player) -> void:
	if carrying:
		carrying = false
		stored += 3
		Overlay.subtitle("[you wash it off and pack it into the fridge and the cupboards]", 3.0)
		return
	player.heal(6.0)
	Overlay.subtitle("[a cold glass from the filter pitcher. The only water here worth drinking.]", 3.0)


func _cook(_p: Player) -> void:
	if stored <= 0:
		Overlay.subtitle("[nothing left to cook. The basement might have restocked.]", 3.0)
		return
	stored -= 1
	player.heal(20.0)
	Overlay.subtitle("[the burner clicks on. A steak, the way you've learned to do it. It's really good.]", 3.5)


func _tv(_p: Player) -> void:
	tv_on = not tv_on
	(MatLib.get_mat("l53_tv") as ShaderMaterial).set_shader_parameter("energy", 1.4 if tv_on else 0.0)
	_static.volume_db = -20.0 if tv_on else -80.0
	if tv_on:
		Overlay.subtitle("[the TV still works. No cable, so mostly snow and one fuzzy channel.]", 3.0)


func _breach(instant := false) -> void:
	breached = true
	door_target = 100.0
	if instant:
		door_angle = 100.0
		door.rotation.y = deg_to_rad(door_angle)
	operative.visible = true
	if not instant:
		Overlay.glitch(0.8)
		sound.play_at("distant_boom", {}, House.DOOR + Vector3(0, 1.2, 0.5), -2.0, "[CRACK. The lock splinters and the front door bursts inward.]")
		Overlay.subtitle("[a figure in M.E.G. gear in the doorway: \"Allen Grady? We found your letter. Come on, out this way.\"]", 6.0)


# ---------------------------------------------------------------- loop

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	if absf(door_angle - door_target) > 0.05:
		door_angle = move_toward(door_angle, door_target, delta * 160.0)
		door.rotation.y = deg_to_rad(door_angle)
	var below := pp.y < -1.0
	_feed_lights(-1 if below else (1 if pp.y > 2.0 else 0))
	if below != _was_below:
		# the sky light reaches everywhere; under the slab the basement gets its own dim fill
		_was_below = below
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if below else Environment.AMBIENT_SOURCE_SKY
		environment.ambient_light_color = Color(0.30, 0.28, 0.25)
		environment.ambient_light_energy = 0.12 if below else 0.3
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED if below else Environment.REFLECTION_SOURCE_BG
		environment.fog_enabled = not below
		sun.visible = not below
	_rescue(delta)
	_food_cycle(delta)
	_visitor_cycle(delta, pp)
	_street(delta, pp)
	if louie:
		var t := Time.get_ticks_msec() * 0.001
		louie.position = spots["cage"] + Vector3(sin(t * 0.7) * 0.17, 0.07, sin(t * 1.3) * 0.1)


func _rescue(delta: float) -> void:
	if rescue_t < 0.0 or breached:
		return
	rescue_t -= delta
	if rescue_t < 14.0 and _knocked == 0:
		_knocked = 1
		sound.play_at("knock", {"hits": 3}, House.DOOR + Vector3(0, 1.3, 0.3), -4.0, "[three hard knocks at the front door]")
	if rescue_t < 7.0 and _knocked == 1:
		_knocked = 2
		Overlay.subtitle("[muffled voices outside: \"M.E.G.! Anyone in there? Stand back from the door!\"]", 4.5)
	if rescue_t <= 0.0:
		_breach()


func _food_cycle(delta: float) -> void:
	if pile_on:
		return
	food_t -= delta
	if food_t <= 0.0:
		pile_on = true
		pile.visible = true
		if player.global_position.y < -1.0:
			Overlay.subtitle("[you didn't see it arrive. The pile of food is just there, on the floor.]", 3.5)


func _visible_to_player(p: Vector3) -> bool:
	var cam := player.camera
	var to := p + Vector3(0, 1.2, 0) - cam.global_position
	if to.length() > 14.0:
		return false
	return to.normalized().dot(-cam.global_transform.basis.z) > 0.3


func _visitor_cycle(delta: float, pp: Vector3) -> void:
	_shuffle_t -= delta
	var couch: Vector3 = SPOTS[7][0]
	if tv_on and pp.distance_to(Vector3(-2.2, 0, 2.2)) < 1.6:
		_tv_near += delta
	else:
		_tv_near = 0.0
	for v in visitors:
		var node := v["node"] as Node3D
		if _tv_near > 5.0 and int(v["spot"]) != 7 and not _visible_to_player(couch) and not _said.has("tvsit"):
			_said["tvsit"] = true
			_move_visitor(v, 7)
			Overlay.subtitle("[someone sits down beside you on the couch. You don't need to look to know it has no face.]", 4.0)
			continue
		if _shuffle_t <= 0.0 and not _visible_to_player(node.global_position):
			var taken := visitors.map(func(o): return int(o["spot"]))
			var choice := rng.randi() % SPOTS.size()
			if not taken.has(choice):
				_move_visitor(v, choice)
		if not bool(SPOTS[int(v["spot"])][2]) and node.global_position.distance_to(pp) < 4.0:
			var to := pp - node.global_position
			node.rotation.y = lerp_angle(node.rotation.y, atan2(-to.x, -to.z), delta * 0.6)
	if _shuffle_t <= 0.0:
		_shuffle_t = rng.randf_range(35.0, 80.0)


func _move_visitor(v: Dictionary, spot: int) -> void:
	var old := v["node"] as Node3D
	var sp: Array = SPOTS[spot]
	var n := _figure(sp[0], sp[1], "visitor", sp[2])
	old.queue_free()
	v["node"] = n
	v["spot"] = spot


func _street(delta: float, pp: Vector3) -> void:
	for w in walkers:
		var n := w["node"] as Node3D
		n.position.x += float(w["dir"]) * 1.15 * delta
		if absf(n.position.x) > 60.0:
			n.position.x = -60.0 * float(w["dir"])
		n.rotation.z = 0.03 * sin(n.position.x * 3.0)
	# watching the street through a front window for too long draws a staring crowd
	var at_window := pp.z > 3.4 and absf(pp.x) > 1.5 and (-player.camera.global_transform.basis.z).z > 0.6
	if _stare_on > 0.0:
		_stare_on -= delta
		if _stare_on <= 0.0:
			for s in starers:
				(s as Node3D).visible = false
		return
	_stare_t = _stare_t + delta if at_window else maxf(0.0, _stare_t - delta)
	if _stare_t > 7.0 and not _said.has("stare"):
		_said["stare"] = true
		_stare_on = 25.0
		for s in starers:
			(s as Node3D).visible = true
		if not qa_fixture:
			Overlay.subtitle("[across the street a whole group of people has stopped. They are all staring at you.]", 5.0)


func _prep_people() -> void:
	for s in starers:
		(s as Node3D).visible = false
	await get_tree().process_frame


func _prep_stare() -> void:
	for s in starers:
		(s as Node3D).visible = true
	_stare_on = 30.0
	await get_tree().process_frame


func on_player_ready() -> void:
	if not qa_fixture:
		Overlay.subtitle("[you come to on the living-room floor. Glass on the carpet. Outside, a bright, ordinary morning.]", 5.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "three walkable heights (basement, ground, upstairs)", "ok": _floor_at(Vector3(0, -2.0, -2.0)) and _floor_at(Vector3(-3.5, 0.6, 2.5)) and _floor_at(Vector3(-3.5, 3.5, -2.5))})
	out.append({"what": "QA fixture: the door is breached and the Level 9 exit is armed", "ok": breached and door_angle > 90.0})
	var p0 := pile_on
	_gather(player)
	out.append({"what": "gathering empties the basement pile and you carry the food", "ok": p0 and not pile_on and carrying})
	var s0 := stored
	_fridge(player)
	out.append({"what": "food carried to the fridge is stored", "ok": stored == s0 + 3 and not carrying})
	_mail(player)
	out.append({"what": "nothing goes through the slot without a letter", "ok": not letter})
	out.append({"what": "faceless visitors present, none hostile", "ok": visitors.size() == 3})
	return out


func _floor_at(p: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 1.0, 1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()
