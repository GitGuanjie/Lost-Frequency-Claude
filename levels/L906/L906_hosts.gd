extends RefCounted
## Level 906 host: Blanche and the etiquette that decides how you leave.
## SOURCE (page, Entities / Exits): she controls the library, welcomes visitors and
## invites them to tea; an impolite visitor is first warned, then called out on
## their lack of manners, then lectured in proper etiquette; a hostile visitor is
## immobilised by telekinetic force, and if the hostility continues is teleported
## back to the level they came from (if safe; otherwise to a safe level). Asked
## politely, she guides a guest to an exit to the level of their choosing,
## provided it is safe. Injured guests are tended in a guest room; one guest room
## is kept by her butler and protege, Tom Von Haderach.
## ADAPTATION: dialogue (our own words, in her register), the escalation counters,
## the 6 s hold, which acts count as rude, and how "safe" is read (a destination
## whose own page header calls it Safe, or survival class 0-1, and that is built).

const Rooms := preload("res://levels/L906/L906_rooms.gd")
const SPOT := {"office": [Vector3(-0.95, 0, 4.55), -60.0], "tea": [Vector3(15.4, 0, 14.65), 180.0],
	"door": [Vector3(-11.55, 0, -10.45), 45.0]}
const EXCLUDE := ["L906", "L974"]   # L974 is entered only on its own page's terms

var L: Node3D
var blanche: Node3D
var where := "office"
var impolite := 0
var hostile := 0
var lectured := false
var greeted := false
var room_given := false
var tea_count := 0
var nights := 0
var read_count := 0
var expelled := false
var guide_to := ""
var guiding := false
var busy := false
var in_tea := false
var _tea_idle := 0.0
var held := 0.0
var events: Array = []        # etiquette / route log (QA evidence)
var said: Array = []          # every panel text (QA evidence when no UI is shown)
var _ui: Control
var _vb: VBoxContainer
var _path: Array = []
var _yaw := 0.0
var _hold_pos := Vector3.ZERO
var _tea_topics := 0


func _init(level: Node3D) -> void:
	L = level


func setup() -> void:
	blanche = Rooms.blanche(L)
	var it := Interactable.new()
	blanche.add_child(it)
	it.setup(Vector3(0, 0.8, 0), Vector3(0.7, 1.6, 0.7), "Speak with Blanche", func(_p): talk())
	var body := StaticBody3D.new()
	blanche.add_child(body)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.32
	sh.height = 1.5
	cs.shape = sh
	cs.position = Vector3(0, 0.75, 0)
	body.add_child(cs)
	place("office")


func place(spot: String) -> void:
	where = spot
	var s: Array = SPOT[spot]
	blanche.global_position = s[0]
	_yaw = deg_to_rad(float(s[1]))
	blanche.rotation.y = _yaw
	_path.clear()


# ---------------------------------------------------------------- dialogue UI

func ui(title: String, text: String, options: Array) -> void:
	said.append(text)
	if SessionState.is_qa():
		return
	if _ui == null or not is_instance_valid(_ui):
		var r: Array = Overlay._panel(Vector2(660, 0))
		_ui = r[0]
		_vb = r[1]
	for c in _vb.get_children():
		c.queue_free()
	var t := UITheme.label(title, 22, Color(0.95, 0.85, 0.6))
	_vb.add_child(t)
	var body := UITheme.label(text, 18)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(620, 0)
	_vb.add_child(body)
	for o in options:
		var cb: Callable = o[1]
		var b := UITheme.button(str(o[0]), _choose.bind(cb))
		b.custom_minimum_size = Vector2(620, 40)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_vb.add_child(b)
	Overlay.push(_ui)


func _choose(cb: Callable) -> void:
	Overlay.pop()
	cb.call()


func free_ui() -> void:
	if _ui and is_instance_valid(_ui):
		_ui.queue_free()


func reply(text: String) -> void:
	if in_tea:
		ui("Blanche", text, [["...", func(): _tea_menu("Blanche waits for you to go on.")]])
		return
	ui("Blanche", text, [["...", func(): talk(true)], ["Take your leave of her for now.", func(): pass]])


func talk(again := false) -> void:
	if expelled or held > 0.0 or busy:
		return
	var text := "Blanche folds her hands and waits, perfectly patient. \"Yes, dear?\""
	if not greeted:
		greeted = true
		text = "\"Oh! A guest.\" The small woman in the pale blue tea gown sets down her pen and looks up with light blue eyes. \"It is a pleasure to meet you. Welcome to my library. You will stay for tea, won't you? Everyone stays for tea.\""
	elif again:
		text = "\"Was there something else?\""
	var opts: Array = []
	if impolite > 0:
		opts.append(["Apologise for your manners.", apologise])
	if where != "tea":
		opts.append(["Accept her invitation to tea.", func(): go_tea()])
	opts.append(["Ask her where you are.", ask_where])
	if not room_given:
		opts.append(["Ask whether there is somewhere you could rest.", ask_room])
	opts.append(["Ask, politely, whether you might leave.", ask_leave])
	opts.append(["\"Skip the tea. Where's the way out of this dusty heap?\"", func(): impolite_act("rude words")])
	opts.append(["Raise your fists and threaten her.", func(): hostile_act("threat")])
	opts.append(["Say you'll come back to her later.", func(): pass])
	ui("Blanche", text, opts)


func ask_where() -> void:
	reply("\"This is my library. Some of your people call it the Cygnus Archive, which I rather like. Every book in it is mine, and every one is signed; I expect that is how you came in, with a finger drawn across my name.\" She glances at the recorder you carry. \"Do put that away, dear. Nothing will record in here, it never has.\"")


func ask_room() -> void:
	room_given = true
	events.append("room_given")
	L.life.reshape_room(true)
	reply("\"Of course. Up the marble stair and round the gallery to the far corner on your right, the south-east one. The door is open and the bed is made. Don't be alarmed if it looks different each time you come back. Rooms here like to fit whoever is in them.\"")


# ---------------------------------------------------------------- leaving

## Levels Blanche will open a door onto: built, and safe by their own page header.
func safe_levels() -> Array:
	var out: Array = []
	var re := RegEx.new()
	re.compile("difficulty class [01](?![0-9])")
	for e in LevelRegistry.entries:
		var sid: String = e["stable_id"]
		if sid in EXCLUDE:
			continue
		var ok := LevelRegistry.is_playable(sid) if SessionState.is_story() else LevelRegistry.is_spawnable(sid)
		if not ok:
			continue
		var cls := str(e.get("survival_class", "")).to_lower().strip_edges()
		if cls.begins_with("safe") or re.search(cls) != null:
			out.append(sid)
	var o := origin()
	if out.has(o):
		out.erase(o)
		out.push_front(o)
	return out


func origin() -> String:
	var o := str(TransitionService.arrived_via.get("from", ""))
	if o == "" or o == L.stable_id:
		o = TransitionService.previous_level()
	return o


func ask_leave() -> void:
	if guiding:
		reply("\"The door is open, dear. Just through there.\"")
		return
	var opts: Array = []
	var o := origin()
	for sid in safe_levels():
		var label := LevelRegistry.display_name(sid) + ("   (where you came from)" if sid == o else "")
		opts.append([label, func(): guide(sid)])
	if opts.is_empty():
		reply("\"Hm. I'm afraid I cannot think of a safe place to send you just now. Stay a little longer?\"")
		return
	opts.append(["\"On second thought, I'd like to stay a while.\"", func(): pass])
	ui("Blanche", "\"Of course you may. I would never keep a guest who wishes to go.\" She tilts her head. \"Where would you like to go? I only open my doors onto safe places, I'm afraid.\"", opts)


## Point the leave edge at the chosen level and walk the guest to the door.
func guide(sid: String) -> void:
	guide_to = sid
	guiding = true
	events.append("guide:" + sid)
	route("L906>EXT#1", sid)
	L.core.set_door(true, glow_for(sid))
	if L.exit_leave:
		L.exit_leave.enabled = true
	if where == "office":
		_path = [Vector3(-0.3, 0, 3.1), Vector3(-0.2, 0, 1.4), Vector3(-6.4, 0, -3.8), SPOT["door"][0]]
	else:
		place("door")
	if not SessionState.is_qa():
		Overlay.subtitle("Blanche: \"This way, then. Follow me, and mind the rugs.\"", 4.0)
		L.sound.play_at("creak", {"freq": 70.0}, L.core.door_node.global_position + Vector3.UP, -10.0, "[a tall door in the north-west corner swings open; beyond it, a different light]")


static func glow_for(sid: String) -> Color:
	return {"L000": Color(1.0, 0.9, 0.5), "L001": Color(0.85, 0.9, 0.95), "L010": Color(1.0, 0.86, 0.55),
		"L011": Color(0.45, 0.55, 0.85), "L037": Color(0.75, 0.95, 1.0)}.get(sid, Color(0.95, 0.9, 0.8))


func route(edge_id: String, to: String) -> void:
	# Level-local workaround: the documented edge has no fixed destination
	# (to: null in transitions.json), so the chosen safe level is written into
	# the cached edge right before it fires. See the level notes.
	var e := TransitionService.get_edge(edge_id)
	if not e.is_empty():
		e["to"] = to
		e["to_label"] = LevelRegistry.display_name(to)


func door_examined() -> void:
	if guiding:
		Overlay.toast("The door stands open onto a short passage. At its end: the light of %s." % LevelRegistry.display_name(guide_to), 4.0)
	else:
		Overlay.toast("A tall door with no handle on this side. It is not yours to open; your host opens it for guests who ask her nicely.", 4.5)


# --------------------------------------------------------------- etiquette

func impolite_act(kind: String) -> void:
	impolite += 1
	events.append("impolite:%d:%s" % [impolite, kind])
	match impolite:
		1:
			_line("Her smile does not move. \"Manners, please. You are a guest in this library.\"")
		2:
			_line("\"That is twice now.\" She sets down what she was holding. \"I don't know how things are done where you come from, but here we say please, and we say thank you.\"")
		3:
			lectured = true
			events.append("lecture")
			ui("A lesson in etiquette", "Blanche draws herself up to her full, small height. \"Then let us have a lesson. A guest greets their host. A guest asks, and says please, and says thank you. A guest keeps their voice low in a library, their hands clean on the pages, and their opinion of the furniture to themselves. And a guest never, ever threatens anyone. It is not difficult. Shall we begin again?\"",
				[["\"I understand. I'm sorry.\"", apologise], ["Roll your eyes at her.", func(): impolite_act("eye-roll")]])
		_:
			hostile_act("excessive rudeness")


func apologise() -> void:
	impolite = 0
	events.append("apology")
	_line("\"Apology accepted.\" And it is: her smile comes back as if it had never left. \"There. That wasn't so hard.\"")


func hostile_act(kind: String) -> void:
	hostile += 1
	events.append("hostile:%d:%s" % [hostile, kind])
	if in_tea:
		_stand_up()
	if hostile == 1:
		immobilise(6.0)
		_line("An invisible pressure closes around you from every side, and you cannot move so much as a finger. Blanche does not raise her voice. \"We will have none of that.\"", false)
	else:
		immobilise(2.5)
		expelled = true
		var to := expel_destination()
		route("L906>EXT#2", to)
		events.append("expel:" + to)
		_line("The pressure closes in again. Blanche sighs, and sounds genuinely sorry. \"Then I'm afraid our visit is over.\"", false)


## Back to where you were when you entered, if that level is safe; else a safe level.
func expel_destination() -> String:
	var safe := safe_levels()
	var o := origin()
	if safe.has(o):
		return o
	return safe[0] if not safe.is_empty() else "EXT"


func immobilise(sec: float) -> void:
	held = sec
	var p: Player = L.player
	p.frozen = true
	p.velocity = Vector3.ZERO
	_hold_pos = p.global_position
	if not SessionState.is_qa():
		Overlay.set_screen_effect("desaturate", 0.45)
		Overlay.set_screen_effect("vignette", 0.7)
		Overlay.subtitle("[a pressure like deep water closes around you]", 4.0)


func _release() -> void:
	var p: Player = L.player
	p.global_position = _hold_pos
	if not expelled:
		p.frozen = false
	Overlay.set_screen_effect("desaturate", 0.0)
	Overlay.set_screen_effect("vignette", 0.25)
	if not expelled and not SessionState.is_qa():
		Overlay.toast("The pressure lets go all at once. \"Better,\" says Blanche. \"Shall we try that again, politely?\"", 5.0)


## A line from Blanche: a panel when you are talking to her, a toast otherwise.
func _line(text: String, menu := true) -> void:
	if menu and blanche.global_position.distance_to(L.player.global_position) < 6.0:
		reply(text)
	else:
		said.append(text)
		if not SessionState.is_qa():
			Overlay.toast(("Blanche, from somewhere among the shelves: " if blanche.global_position.distance_to(L.player.global_position) > 8.0 else "") + text, 6.0)


# --------------------------------------------------------------------- tea

func tea_table() -> void:
	if where == "tea" or blanche.global_position.distance_to(L.player.global_position) < 12.0:
		go_tea()
	else:
		Overlay.toast("The table is laid for two, or three. It would be rude to start without your host.", 4.0)


func go_tea() -> void:
	if busy or expelled:
		return
	busy = true
	events.append("tea")
	if not SessionState.is_qa():
		await Overlay.fade_to(1.0, 0.7)
	place("tea")
	var p: Player = L.player
	p.frozen = true
	p.velocity = Vector3.ZERO
	p.global_position = Rooms.TEA + Vector3(0, 0.05, 0.98)
	p.rotation.y = 0.0
	p.head.position.y = 1.12
	p.look_pitch = -0.18
	p.head.rotation.x = -0.18
	_tea_topics = 0
	in_tea = true
	busy = false
	if not SessionState.is_qa():
		await Overlay.fade_to(0.0, 0.7)
		_tea_menu("Blanche pours from a porcelain pot and slides a plate of biscuits towards you. \"There. Now, tell me everything. I so rarely get to hear about anywhere else.\"")


func _tea_menu(text: String) -> void:
	var opts: Array = [
		["Tell her about your life before the Backrooms.", func(): _topic("She listens with her chin on her hand, asking after the smallest things: what the weather was like, what you ate, whether you had a garden. She remembers every name you mention.")],
		["Tell her what you're good at.", func(): _topic("\"How wonderful.\" She asks question after question about it, sharp and genuinely curious, and twice gets up to fetch a book on the subject from a shelf that you are fairly sure was not there before.")],
		["Ask about her books.", func(): _topic("\"All of them are mine, and all of them are signed. Some I wrote. Some I only keep. They wander, you know: you'll see them come and go.\" She refills your cup without looking at it.")],
		["\"This tea is terrible.\"", _tea_rude],
		["Thank her, and finish your tea.", end_tea]]
	ui("Tea with Blanche", text, opts)


func _tea_rude() -> void:
	impolite_act("insulted the tea")


func _topic(text: String) -> void:
	_tea_topics += 1
	if _tea_topics >= 3:
		_tea_menu(text + "\n\nThe pot has been refilled twice now.")
	else:
		_tea_menu(text)


func end_tea() -> void:
	in_tea = false
	tea_count += 1
	var mins: int = L.rng.randi_range(60, 120)
	var p: Player = L.player
	p.health = 100.0
	p.stamina = p.stamina_max
	if not SessionState.is_qa():
		await Overlay.fade_to(1.0, 0.6)
	_stand_up()
	L.checkpoint("tea_room")
	if not SessionState.is_qa():
		await Overlay.fade_to(0.0, 0.8)
		Overlay.toast("The candles have burned down by a finger's width. It has been about %d minutes; it did not feel like it. You are rested and fed." % mins, 6.0)


func _stand_up() -> void:
	var p: Player = L.player
	p.global_position = Rooms.TEA + Vector3(0, 0.05, 1.7)
	p.head.position.y = Player.EYE_STAND
	p.frozen = false
	in_tea = false
	busy = false


# ------------------------------------------------------------- rooms, doors

func rest() -> void:
	if not room_given:
		Overlay.toast("The bed is made, but nobody has offered it to you. It would be polite to ask your host first.", 4.5)
		return
	if busy:
		return
	busy = true
	nights += 1
	events.append("rest:%d" % nights)
	if not SessionState.is_qa():
		await Overlay.fade_to(1.0, 0.8)
	L.player.health = 100.0
	L.player.stamina = L.player.stamina_max
	L.checkpoint("guest_room")
	busy = false
	if not SessionState.is_qa():
		await Overlay.fade_to(0.0, 1.0)
		Overlay.toast("You sleep, deeply, for the first time in a long while (night %d). Some guests stay like this for weeks, or months." % nights, 6.0)


func door_knock(tom: bool) -> void:
	L.sound.play_at("knock", {"hits": 3}, L.player.global_position + Vector3.UP, -8.0, "[you knock]")
	if tom:
		Overlay.toast("A card in the brass frame: T. Von Haderach. Nobody answers, but there is light under the door. This room is kept, not empty: Blanche's butler and protege lives here.", 6.0)
	else:
		empty_guest_room()


func empty_guest_room() -> void:
	Overlay.toast("Locked. Through the keyhole: a made bed, a cold candle, nobody. One of the library's empty guest rooms, waiting for a guest.", 4.5)


## A loose book, folder, scroll or note (they all carry Blanche's signature).
func read_item(item: Dictionary) -> void:
	read_count += 1
	var node: Node3D = item["node"]
	ui(str(item["title"]), str(item["text"]), [
		["Trace the signature with your finger, left to right.", func(): Overlay.toast("The ink is faintly warm. Nothing happens: you are already where it leads.", 4.0)],
		["Tear out a page.", _tear.bind(node)],
		["Leave it be.", func(): pass]])


func _tear(node: Node3D) -> void:
	L.life.tear(node)
	impolite_act("tore a page")


# ------------------------------------------------------------------ process

func process(delta: float) -> void:
	if in_tea and not SessionState.is_qa():
		_tea_idle = _tea_idle + delta if not Overlay.is_menu_open() else 0.0
		if _tea_idle > 0.6:
			_tea_idle = 0.0
			_tea_menu("Blanche waits for you to go on.")
	if held > 0.0:
		held -= delta
		L.player.global_position = _hold_pos + Vector3.UP * (0.25 * minf(1.0, 3.0 - held))
		if held <= 0.0:
			_release()
	var p: Player = L.player
	if not _path.is_empty():
		var tgt: Vector3 = _path[0]
		var to := tgt - blanche.global_position
		to.y = 0.0
		if to.length() < 0.15:
			_path.pop_front()
			if _path.is_empty():
				where = "door"
		else:
			blanche.global_position += to.normalized() * minf(to.length(), 1.25 * delta)
			_yaw = atan2(-to.x, -to.z)
	elif p and blanche.global_position.distance_to(p.global_position) < 8.0:
		var d := p.global_position - blanche.global_position
		_yaw = atan2(-d.x, -d.z)
	blanche.rotation.y = lerp_angle(blanche.rotation.y, _yaw, minf(1.0, delta * 3.0))
	blanche.position.y = 0.0 if _path.is_empty() else 0.012 * sin(Time.get_ticks_msec() * 0.008)
