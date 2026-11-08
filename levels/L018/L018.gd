extends LevelBase
## Level 18 "Memories" (Backrooms Wikidot rev 65, accessed 2026-11-04; original by
## u/Liam4Fingarz, rewritten by 1000dumplings and yoyoflux; CC BY-SA 3.0).
## Dossier: docs/canon/levels/L018.md.
##
## PLAN (read -> design):
## - SOURCE: a childhood memory of age 2-5, different for every viewer; most often a
##   preschool or daycare, otherwise a bedroom, classroom or playground. -> one seeded
##   daycare (wall colours, one "other memory" room: bedroom / classroom / washroom) with a
##   fenced playground, all at a child's scale (~1.4x: 3.9 m ceilings, toddler tables at
##   adult height). Multi-height: a raised book nook and a playground climbing tower + slide.
## - SOURCE: voices whisper your biggest regrets and mistakes, nearly impossible to
##   suppress. -> positional whispers that grow over time, captioned with player-neutral lines.
## - SOURCE: forgotten memories resurface, e.g. dead childhood animals. -> a goldfish bowl
##   with the fish floating at the top, in the remembered room.
## - SOURCE: no threats; provides all materials for survival; addictive; it enjoys company.
##   -> a snack table with water and food; the longer you stay the warmer it gets, and the
##   door feels harder to want.
## - SOURCE: The Plush Dino, rare, sentient, wanders, guides, brings food and water; follow
##   him for an extended period to reach the Level you desire. -> he appears after a while,
##   waddles a loop through the rooms, leaves a juice box and a sandwich by you, and if you
##   keep near him long enough he leads you out to the playground gate, asks where you
##   want to go (picker) and the gate opens onto it (L018>EXT#2, destination set at runtime).
## - SOURCE: simplest exit: turn around and leave -> Level 19. -> the doorway you arrived
##   through stays behind you, glowing; walking back out of it is L018>L019#1.
## - Lighting and sound are not stated: soft afternoon light and room tone are ADAPTATION.

const B := preload("res://levels/L018/L018_build.gd")
const Art := preload("res://levels/L018/L018_art.gd")
const FOLLOW_NEED := 150.0

var qa_fixture := false
var bld
var yard: Dictionary = {}
var dino: Node3D
var dino_on := false
var dino_t := 90.0
var route: Array = []
var ri := 0
var leading := false
var follow := 0.0
var gifted := false
var stay := 0.0
var gate_pivot: Node3D
var gate_open := false
var desire_exit: ExitTrigger
var chosen := ""
var whispers: Array = []
var whisper_t := 25.0
var _wi := 0
var _said: Dictionary = {}
var _step := 0.0
const LINES := ["you never said you were sorry", "you could have called them back", "you knew, and you said nothing",
	"they waited for you, and you didn't come", "you let it go on for far too long", "it was your fault, wasn't it",
	"you promised", "you were the one who left"]
const LOOP := [Vector3(-2, 0, 2), Vector3(4, 0, 1.2), Vector3(8, 0, -2), Vector3(8, 0, -7.2), Vector3(8, 0, -10.6), Vector3(8, 0, -7.2),
	Vector3(0, 0, -7.0), Vector3(0, 0, -10.2), Vector3(0, 0, -7.0), Vector3(-8, 0, -7.2), Vector3(-8, 0, -10.4), Vector3(-8, 0, -7.2),
	Vector3(-6, 0, -3.0), Vector3(-5, 0, 2.5)]
const TO_GATE := [Vector3(8, 0, -3.5), Vector3(11, 0, -5.5), Vector3(14, 0, -5.0), Vector3(18, 0, -2.2), Vector3(30, 0, -2.0), Vector3(34.8, 0, -2.0)]


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 160.0
	rules["reverb_room"] = 0.32
	rules["reverb_wet"] = 0.12
	outdoor_env(Color(0.62, 0.72, 0.85), Color(0.98, 0.9, 0.78), Color(0.5, 0.5, 0.45), Vector2(26.0, -72.0), Color(1.0, 0.86, 0.66), 1.5, Color(1.0, 0.95, 0.88), 0.0045)
	environment.ambient_light_energy = 0.38
	environment.fog_sky_affect = 0.9
	environment.tonemap_exposure = 0.92
	environment.glow_enabled = true
	environment.glow_intensity = 0.3
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	environment.adjustment_contrast = 0.95
	sun.shadow_blur = 2.0
	lights.setup(5, 1)
	bld = B.new(self, rng)
	yard = bld.build()
	_gate()
	_pets_and_snacks()
	_drawings()
	_dino()
	_exits_and_arrivals()
	_sounds()
	_notes()
	add_landmark("The doorway you came in by (turn round to leave)", Vector3(0, 0, 8))
	add_landmark("Book nook", Vector3(-9.5, 1.7, 1.0))
	add_landmark("Playground gate", yard["gate"])
	add_shot("playroom", Vector3(1.0, 1.62, 6.2), Vector3(-1.5, 0.3, -6.0), {"prepare": _prep_dino.bind(Vector3(3.0, 0, 2.6), 200.0)})
	add_shot("nook", Vector3(-10.6, 3.35, 3.2), Vector3(5.0, 0.4, -3.5))
	add_shot("dino", Vector3(-1.2, 1.3, -8.9), Vector3(0.6, 0.35, -11.4), {"prepare": _prep_dino.bind(Vector3(0.6, 0, -11.0), 210.0)})
	add_shot("playground", Vector3(15.0, 1.62, 5.0), Vector3(25.0, 1.5, -6.0))
	add_shot("memory", Vector3(6.0, 1.62, -8.6), Vector3(9.5, 0.6, -14.0))
	add_shot("doorway", Vector3(0.0, 1.62, 3.0), Vector3(0.0, 1.5, 9.0))


func _gate() -> void:
	gate_pivot = Node3D.new()
	gate_pivot.name = "GateLeaf"
	gate_pivot.position = Vector3(36.0, 0, -2.95)
	add_child(gate_pivot)
	var gk := GeoKit.new(gate_pivot, "Gate")
	for i in 6:
		gk.box(Vector3(0, 0.75, 0.15 + i * 0.32), Vector3(0.08, 1.5, 0.09), "l18_fence", GeoKit.ALL, false)
	gk.box(Vector3(0, 1.1, 0.95), Vector3(0.06, 0.08, 1.9), "l18_fence", GeoKit.ALL, false)
	gk.box(Vector3(0, 0.4, 0.95), Vector3(0.06, 0.08, 1.9), "l18_fence", GeoKit.ALL, false)
	gk.box(Vector3(0, 0.8, 0.95), Vector3(0.1, 1.6, 1.9), "l18_fence", GeoKit.PY, true)
	gk.box(Vector3(0.05, 1.45, 1.75), Vector3(0.12, 0.08, 0.08), "metal", GeoKit.ALL, false)
	gk.commit()
	add_interactable(Vector3(35.5, 1.0, -2.0), Vector3(1.0, 2.0, 2.2), "Try the gate", func(_p: Player) -> void:
		if gate_open:
			return
		Overlay.subtitle("[the latch is up high, where grown-ups put latches. You can't reach it. Not like this.]", 4.0))


func set_gate(open: bool) -> void:
	gate_open = open
	var tw := create_tween()
	tw.tween_property(gate_pivot, "rotation:y", deg_to_rad(-100.0) if open else 0.0, 1.2)


func _pets_and_snacks() -> void:
	var bowl := Art.goldfish_bowl(self, Vector3(5.0, 1.0, -11.0))
	add_interactable(bowl.position + Vector3(0, 0.2, 0), Vector3(0.6, 0.6, 0.6), "Look at the fish bowl", func(_p: Player) -> void:
		Overlay.subtitle("[a goldfish, floating on its side at the top. You don't remember ever having a goldfish. Your throat closes anyway.]", 5.5))
	add_interactable(Vector3(-3.0, 1.2, 6.5), Vector3(1.4, 0.8, 1.0), "Have a drink and something to eat", func(_p: Player) -> void:
		Overlay.subtitle("[apple juice and a soft sandwich, cut into triangles. There is always more.]", 4.0))
	add_interactable(Vector3(-3.2, 1.5, 7.6), Vector3(1.4, 1.2, 0.6), "Look in the cubbies", func(_p: Player) -> void:
		Overlay.subtitle("[one of the cubbies has your name on it, in a grown-up's careful handwriting]", 4.0))


func _drawings() -> void:
	var holder := Node3D.new()
	holder.name = "Drawings"
	add_child(holder)
	var kinds := ["family", "house", "sun", "rainbow", "dino", "flower"]
	var spots := [[Vector3(-5.5, 1.6, -7.89), Vector3(0, 0, 1)], [Vector3(-1.5, 1.7, -7.89), Vector3(0, 0, 1)], [Vector3(2.5, 1.55, -7.89), Vector3(0, 0, 1)],
		[Vector3(5.0, 1.75, -7.89), Vector3(0, 0, 1)], [Vector3(11.89, 1.5, -2.8), Vector3(-1, 0, 0)], [Vector3(-3.0, 2.0, 7.89), Vector3(0, 0, -1)],
		[Vector3(-1.5, 1.6, -15.89), Vector3(0, 0, 1)], [Vector3(1.6, 1.7, -15.89), Vector3(0, 0, 1)], [Vector3(-3.89, 1.6, -11.5), Vector3(1, 0, 0)],
		[Vector3(3.89, 1.5, -13.0), Vector3(-1, 0, 0)], [Vector3(-4.11, 1.6, -13.5), Vector3(-1, 0, 0)], [Vector3(-11.89, 1.4, -6.0), Vector3(1, 0, 0)]]
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "drawings"])
	for i in spots.size():
		Art.pin(holder, spots[i][0], spots[i][1], r.randf_range(0.6, 0.85), Art.drawing(kinds[(i + r.randi()) % kinds.size()], r.randi() % 3))
	add_interactable(Vector3(-1.5, 1.6, -7.7), Vector3(9.0, 1.2, 0.5), "Look at the drawings", func(_p: Player) -> void:
		Overlay.subtitle("[crayon on sugar paper. One of them is yours. You'd know it anywhere, and you have never seen it before.]", 4.5))


func _dino() -> void:
	dino = Art.plush_dino(self)
	dino.position = Vector3(-8, 0, -10.4)
	dino.visible = qa_fixture
	dino_on = qa_fixture
	route = LOOP.duplicate()
	ri = 0
	dino_t = rng.randf_range(60.0, 140.0)
	var it := add_interactable(Vector3.ZERO, Vector3(1.2, 1.2, 1.2), "Pat the plush dinosaur", func(_p: Player) -> void:
		if dino_on:
			Overlay.subtitle("[he is soft and warm and smells faintly of somebody's house. He turns, as if to say: this way.]", 4.5))
	it.reparent(dino, false)
	it.position = Vector3(0, 0.4, 0)


func _exits_and_arrivals() -> void:
	add_arrival("start", Vector3(0, 0.05, 5.8), 0.0)
	add_arrival("from_L019", Vector3(0, 0.05, 5.8), 0.0)
	add_exit("L018>L019#1", "walk_in", Vector3(0, 1.4, 9.9), Vector3(3.0, 2.8, 1.2), "")


func _notes() -> void:
	add_note("wanderer_note", "NOTE TUCKED IN A CUBBY",
		"It looks different for everyone. Mine is my old daycare. The whispering doesn't stop; it knows what you did. Nothing here hurts you, and there's always food and water. Some people never leave. If you want out, just turn round and walk back out the way you came. If the little green dinosaur finds you, follow him. It takes a long time, but he takes you where you want to go.",
		Vector3(-4.45, 1.3, 7.6))


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 420.0, "rumble": 0.05, "seconds": 6.0}, -32.0)
	for p in [Vector3(-10, 0.6, 1.0), Vector3(-8, 0.8, -13.5), Vector3(9.5, 0.8, -14.0), Vector3(27.0, 1.0, -6.0)]:
		var e := sound.emitter("whisper", p, {"seconds": 3.0}, -34.0, 9.0)
		whispers.append(e)


func _prep_dino(at: Vector3, yaw_deg: float) -> void:
	dino.visible = true
	dino.position = at
	dino.rotation.y = deg_to_rad(yaw_deg)
	await get_tree().process_frame


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	if not qa_fixture:
		Overlay.subtitle("[you know this place. You were small here. Somewhere, very quietly, someone is whispering.]", 5.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	stay += delta
	_whispers(delta)
	_dino_tick(delta, p)
	if not qa_fixture:
		var warm := clampf(stay / 400.0, 0.0, 1.0)
		environment.adjustment_saturation = 1.05 + warm * 0.15
		environment.adjustment_brightness = 1.0 + warm * 0.05
		if stay > 300.0 and p.z > 6.5 and absf(p.x) < 2.0 and not _said.has("stay"):
			_said["stay"] = true
			Overlay.subtitle("[you don't really want to go. Not yet. It's nice here.]", 4.0)


func _whispers(delta: float) -> void:
	var lvl := clampf(stay / 240.0, 0.0, 1.0)
	for e in whispers:
		(e as AudioStreamPlayer3D).volume_db = lerpf(-30.0, -15.0, lvl)
	whisper_t -= delta
	if whisper_t <= 0.0:
		whisper_t = rng.randf_range(16.0, 32.0) * (1.0 - lvl * 0.4)
		if not qa_fixture:
			Overlay.subtitle("[a whisper, right by your ear: \"%s\"]" % LINES[_wi % LINES.size()], 3.5)
		_wi += 1


func _dino_tick(delta: float, p: Vector3) -> void:
	if not dino_on:
		dino_t -= delta
		if dino_t <= 0.0:
			dino_on = true
			dino.visible = true
			ri = 0
			dino.position = route[0]
			if not qa_fixture:
				Overlay.subtitle("[something small and green pads across the floor: a plush dinosaur, walking by itself]", 4.5)
		return
	var d := dino.position.distance_to(Vector3(p.x, 0, p.z))
	if d < 5.0 and not gifted:
		gifted = true
		_gift(p)
	var wait := d > 9.0 and (leading or follow > 0.0)
	if not wait and ri < route.size():
		var goal: Vector3 = route[ri]
		var to := goal - dino.position
		to.y = 0.0
		if to.length() < 0.2:
			ri += 1
			if ri >= route.size():
				if leading:
					_at_gate()
				else:
					ri = 0
		else:
			var stepv := to.normalized() * minf(to.length(), delta * (0.85 if leading else 0.6))
			dino.position += stepv
			dino.rotation.y = lerp_angle(dino.rotation.y, atan2(-to.x, -to.z), delta * 4.0)
			_step += delta * 9.0
			var body := dino.get_node("Body") as Node3D
			body.position.y = absf(sin(_step)) * 0.03
			body.rotation.z = sin(_step) * 0.08
	if d < 7.0 and dino_on and not gate_open:
		follow += delta
		if follow >= (6.0 if qa_fixture else FOLLOW_NEED) and not leading:
			leading = true
			route = TO_GATE.duplicate()
			ri = 0
			if not qa_fixture:
				Overlay.subtitle("[the dinosaur stops, looks back at you, and sets off with purpose toward the playground]", 4.5)


func _gift(p: Vector3) -> void:
	var at := Vector3(p.x, 0, p.z) + (dino.position - Vector3(p.x, 0, p.z)).normalized() * 1.0
	var g := Node3D.new()
	g.name = "DinoGift"
	add_child(g)
	Props.place(self, g, "kenney/food-kit/carton", at + Vector3(0.1, 0, 0), 20.0, 0.22)
	Props.place(self, g, "kenney/food-kit/sandwich", at + Vector3(-0.15, 0, 0.1), 60.0, 0.08)
	add_interactable(at + Vector3(0, 0.2, 0), Vector3(0.7, 0.5, 0.7), "Take the juice and sandwich", func(_p: Player) -> void:
		Overlay.subtitle("[he brought them for you. You feel, for a moment, completely looked after.]", 4.0)
		g.queue_free())
	if not qa_fixture:
		Overlay.subtitle("[the plush dinosaur sets down a juice box and a sandwich by your feet]", 4.0)


## At the gate: ask where the wanderer wants to go, route the edge there and open up.
func _at_gate() -> void:
	ri = route.size()
	var opts: Array = _desired_levels()
	if qa_fixture:
		if not opts.is_empty():
			_choose(opts[0])
		return
	var panel: Array = Overlay._panel(Vector2(560, 0))
	var vb: VBoxContainer = panel[1]
	vb.add_child(UITheme.label("Where do you want to go?", 22, Color(0.95, 0.9, 0.7)))
	var body := UITheme.label("The plush dinosaur waits by the gate, looking up at you. He will take you wherever you want to be.", 17)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(520, 0)
	vb.add_child(body)
	for sid in opts:
		var b := UITheme.button(LevelRegistry.display_name(sid), func() -> void:
			Overlay.pop()
			_choose(sid))
		b.custom_minimum_size = Vector2(520, 38)
		vb.add_child(b)
	var stay_b := UITheme.button("Nowhere. I want to stay.", func() -> void:
		Overlay.pop()
		leading = false
		follow = 0.0
		route = LOOP.duplicate()
		ri = 0)
	stay_b.custom_minimum_size = Vector2(520, 38)
	vb.add_child(stay_b)
	Overlay.push(panel[0])


func _desired_levels() -> Array:
	var out: Array = []
	var seen: Array = SaveService.scope()["journal"]["levels_visited"]
	for sid in seen:
		if sid != stable_id and not out.has(sid) and (LevelRegistry.is_playable(sid) if SessionState.is_story() else LevelRegistry.is_spawnable(sid)):
			out.append(sid)
	for sid in LevelRegistry.spawnable_ids():
		if out.size() >= 10:
			break
		if sid != stable_id and not out.has(sid) and (LevelRegistry.is_playable(sid) or not SessionState.is_story()):
			out.append(sid)
	return out


func _choose(sid: String) -> void:
	chosen = sid
	# transitions.json gives this edge no fixed destination (to: null); it is the Level
	# you desire, so the chosen level is written into the cached edge (see L906).
	var e := TransitionService.get_edge("L018>EXT#2")
	if not e.is_empty():
		e["to"] = sid
		e["to_label"] = LevelRegistry.display_name(sid)
	set_gate(true)
	if desire_exit == null:
		desire_exit = add_exit("L018>EXT#2", "condition", Vector3(37.0, 1.4, -2.0), Vector3(1.4, 2.8, 2.6), "")
		if desire_exit:
			desire_exit.condition = func() -> bool: return gate_open and chosen != ""
	if not qa_fixture:
		Overlay.subtitle("[the latch clicks up by itself. Beyond the gate, the light is the light of %s.]" % LevelRegistry.display_name(sid), 4.5)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "turning round to leave is right behind the arrival", "ok": exits.size() >= 1 and (exits[0] as ExitTrigger).global_position.distance_to(arrivals["start"].origin) < 5.0})
	out.append({"what": "the remembered room is seeded per viewer", "ok": bld.memory_kind in ["bedroom", "classroom", "washroom"], "detail": bld.memory_kind})
	out.append({"what": "whispers are placed round the rooms", "ok": whispers.size() == 4})
	# the dino: walk him, follow him long enough, and he leads to the gate and opens it
	dino_on = true
	dino.visible = true
	var start_pos := dino.position
	for i in 120:
		_dino_tick(0.1, dino.position + Vector3(1.5, 0, 0))
	out.append({"what": "the Plush Dino wanders and leaves food by you", "ok": dino.position.distance_to(start_pos) > 1.0 and gifted})
	for i in 1200:
		_dino_tick(0.1, dino.position + Vector3(1.5, 0, 0))
		if gate_open:
			break
	out.append({"what": "following him long enough opens the playground gate onto a chosen level", "ok": gate_open and chosen != "" and desire_exit != null, "detail": chosen})
	return out
