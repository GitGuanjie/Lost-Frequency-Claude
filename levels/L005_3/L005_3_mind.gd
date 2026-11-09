extends Node
## Level 5.3: the Library Mind (bodiless, never shown). Stateful:
## - time inside (compressed: an hour here is about six minutes); after the
##   seeded 1-2 "hours" it starts taking memories: headaches that grow, and
##   notebooks that turn up on a shelf near you holding what was taken. It is
##   never announced (page: victims do not notice without outside help).
## - the exchange: knowledge requested at the lectern is paid for in memory
##   (the extraction comes sooner); asking for knowledge to dominate angers it:
##   books fall, the pulled-out bookcase collapses, heavy loss at once.
## - guidance: now and then a book slides off a shelf near you.

const S := preload("res://levels/L005_3/L005_3_stacks.gd")
const HOUR := 360.0

var lvl
var t_in := 0.0
var extract_at := 600.0
var taken := 0                # memories consigned so far
var next_take := 0.0
var ache := 0.0
var anger := 0.0
var asked := {}
var noticed := false
var notice_t := -1.0
var book_t := 90.0
var books: Array = []
var notebooks: Array = []
var _tinnitus: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _collapsed := false


func _init(level) -> void:
	lvl = level
	name = "LibraryMind"


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = lvl.level_seed + 77
	extract_at = r.randf_range(1.0, 2.0) * HOUR
	book_t = r.randf_range(50.0, 90.0)
	_tinnitus = lvl.sound.bed("fluorescent_hum", {"seconds": 4.0}, -80.0)
	if is_instance_valid(_tinnitus):
		_tinnitus.pitch_scale = 3.2
	_heart = lvl.sound.bed("heartbeat", {}, -80.0)


func on_ready() -> void:
	if lvl.spawn_report.get("used_arrival", "") == "from_L005":
		Overlay.subtitle("[the old wooden door from the hotel corridor swings shut behind you]", 4.0)


func step(delta: float) -> void:
	var pl: Player = lvl.player
	if pl == null or not is_instance_valid(pl):
		return
	t_in += delta
	if notice_t >= 0.0:
		notice_t -= delta
		if notice_t < 0.0 and not noticed:
			noticed = true
			Overlay.subtitle("[you feel, quite plainly, that something has noticed you]", 4.5)
	# extraction: headaches that build, and memories put into books
	if t_in >= extract_at:
		ache = minf(1.0, ache + delta / 300.0)
		if t_in >= next_take:
			next_take = t_in + 150.0
			_consign(1)
	anger = maxf(0.0, anger - delta * 0.05)
	var pulse := 0.5 + 0.5 * sin(t_in * 4.4)
	var a := clampf(ache + anger, 0.0, 1.0)
	Overlay.set_screen_effect("vignette", 0.25 + a * (0.18 + 0.14 * pulse))
	Overlay.set_screen_effect("desaturate", a * 0.18)
	if pl.camera:
		pl.camera.rotation.z = a * 0.008 * sin(t_in * 1.7)
	if is_instance_valid(_tinnitus):
		_tinnitus.volume_db = lerpf(_tinnitus.volume_db, -80.0 if a < 0.05 else lerpf(-40.0, -22.0, a), minf(delta, 1.0))
	if is_instance_valid(_heart):
		_heart.volume_db = lerpf(_heart.volume_db, -80.0 if a < 0.4 else -18.0, minf(delta, 1.0))
	# guidance: a book slides off a shelf near you
	book_t -= delta
	if book_t <= 0.0:
		book_t = randf_range(70.0, 140.0)
		_drop_book(pl, false)


# ---------------------------------------------------------------- memory

## What the library would take first: the newest places, then what you read.
func _memories() -> Array:
	var m: Array = []
	var s: Dictionary = SaveService.scope()
	var lv: Array = s.get("journal", {}).get("levels_visited", [])
	for i in range(lv.size() - 1, -1, -1):
		var sid := str(lv[i])
		if sid == lvl.stable_id:
			continue
		m.append("- %s. How you got there, and what it looked like." % LevelRegistry.display_name(sid))
	m.push_front("- A hotel corridor near Housekeeping; the wallpaper peeled and old; an old wooden door at the end of it.")
	m.append("- A card pinned beside a door, in a careful hand: seven floors, an hour at most.")
	m.append("- Faces. Names that went with them.")
	return m


func _consign(n: int) -> void:
	var mem := _memories()
	var lines: Array = []
	for i in n:
		if taken < mem.size():
			lines.append(mem[taken])
		taken += 1
	if lines.is_empty():
		lines.append("- (pages and pages, closely written)")
	var hit := _shelf_spot(lvl.player.global_position)
	if hit.is_empty():
		return
	var p: Vector3 = hit["pos"]
	var holder := Props.place(lvl, lvl, "ph/binder_notebook", p, randf_range(0, 360), 0.0, false)
	if holder:
		notebooks.append(holder)
	var text := "A small notebook, newer than the books around it. The handwriting looks like yours.\n\n" + "\n".join(lines)
	if notebooks.size() > 1:
		text += "\n\n(It goes on, in the same hand. There are other notebooks like it.)"
	var it: Interactable = lvl.add_note("l53_memory_%d" % taken, "A small notebook on the shelf", text, p + Vector3(0, 0.08, 0), Vector3(0.45, 0.2, 0.45), false)
	it.name = "MemoryNotebook"


## A point on the nearest shelf face at chest height, or a free floor point.
func _shelf_spot(from: Vector3) -> Dictionary:
	var space: PhysicsDirectSpaceState3D = lvl.get_world_3d().direct_space_state
	var best := {}
	var best_d := INF
	for j in 12:
		var a := TAU * j / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 1.3, from + Vector3.UP * 1.3 + d * 3.5, 1)
		var h := q
		var hit := space.intersect_ray(h)
		if hit.is_empty():
			continue
		var dd: float = (hit["position"] as Vector3).distance_to(from + Vector3.UP * 1.3)
		if dd < best_d and dd > 0.6:
			best_d = dd
			best = {"pos": hit["position"] - d * 0.12 + Vector3.DOWN * 0.2, "dir": d}
	return best


# ---------------------------------------------------------------- books

const PAGES := [
	"A thick volume in a script you have never seen. Gilded initials, no pictures. The pages are perfect under their dust.",
	"An Italian encyclopedia of the arts. Not a crease in it, though the dust on the top edge is a finger deep.",
	"A French treatise on manual labour - joinery, masonry. Its spine has never been opened.",
	"English, at last: a gazetteer of places in the Backrooms. It falls open at an entry on a city called Hoofstaad; the next line slips into another language.",
	"A bestiary. The page it landed on is headed 'Ambassadors'. Everything below the heading is in an alphabet you cannot follow.",
	"A history, closely written, that mentions the Macchina by name - and then turns into a cipher.",
	"Fiction, by the look of it: chapters, dialogue, a dedication. You cannot read a word of it.",
]


func _drop_book(pl: Player, angry: bool) -> void:
	var hit := _shelf_spot(pl.global_position)
	if hit.is_empty():
		return
	var from: Vector3 = hit["pos"] + Vector3.UP * 0.5
	var to: Vector3 = from - (hit["dir"] as Vector3) * 0.6
	to.y = S.floor_y(S.floor_of(pl.global_position.y)) + 0.02
	var b := Props.place(lvl, lvl, "ph/binder_notebook", from, randf_range(0, 360), 0.0, false)
	if b == null:
		return
	books.append(b)
	var tw: Tween = lvl.create_tween()
	tw.tween_property(b, "position", to, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(b, "rotation", Vector3(0, b.rotation.y + 1.2, 0), 0.45)
	lvl.sound.play_at("knock", {"hits": 1}, to, -6.0, "" if angry else "[a book slides off a shelf and lands open on the floor]")
	if not angry:
		var txt: String = PAGES[randi() % PAGES.size()]
		var it: Interactable = lvl.make_interactable(Vector3(0, 0.1, 0), Vector3(0.5, 0.25, 0.5), "Pick up the fallen book", func(): Overlay.show_note("A fallen book", txt), b)
		it.name = "FallenBook"
	while books.size() > 6:
		var old = books.pop_front()
		if is_instance_valid(old):
			old.queue_free()


# ---------------------------------------------------------------- the lectern

func request(kind: String) -> void:
	if asked.has(kind):
		Overlay.subtitle("[nothing more comes. It has already answered that]", 3.0)
		return
	asked[kind] = true
	if notice_t < 0.0 and not noticed:
		notice_t = 2.0
	match kind:
		"lost_hall":
			extract_at -= 0.25 * HOUR
			Overlay.subtitle("[warmth at the back of your mind, like approval. A slim book is lying open on the lectern that was not there before]", 6.0)
			_show("A slim book, translated in the margins", "THE LOST HALL SOCIETY\n\nCenturies ago they roamed the Terror Hotel and the rest of the Backrooms gathering what they could learn: the history of levels, the nature of entities, objects and phenomena, the state of the groups of their day.\n\nThey were collectors and historians, and peaceful. They used this place to set down what they found - quickly, completely - and they kept using it until about the seventeenth century.\n\nWhether they built it, or only found it, the book does not say. Not every book here is theirs.")
		"isolation":
			extract_at -= 0.25 * HOUR
			Overlay.subtitle("[a cold distaste, not yours, at the thought of the hotel's staff]", 5.0)
			_show("Loose papers tucked into a ledger", "The papers do not say it outright, but they come close: it was the hotel's staff who cut this place off from the rest of the hotel.\n\nThe library has not forgotten. Neither, it seems, has whoever runs the staff.")
		"dominate":
			_anger()


func _show(title: String, text: String) -> void:
	if not SessionState.is_qa():
		Overlay.show_note(title, text)


func _anger() -> void:
	anger = 1.0
	extract_at = minf(extract_at, t_in)
	next_take = t_in + 150.0
	_consign(3)
	Overlay.subtitle("[a cold, pressing anger fills the corridor. It is not yours. Somewhere close, wood groans]", 5.0)
	var pl: Player = lvl.player
	for i in 3:
		_drop_book(pl, true)
	if not _collapsed and is_instance_valid(lvl.shelf):
		_collapsed = true
		var sh: Node3D = lvl.shelf
		var tw: Tween = lvl.create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(sh, "rotation", Vector3(-1.42, sh.rotation.y, 0), 0.9).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func(): lvl.sound.play_at("distant_boom", {}, sh.global_position, 0.0, "[the bookcase crashes down across the corridor]"))
		for i in 6:
			var bp: Vector3 = sh.global_position + Vector3(randf_range(-0.9, 0.9), 0.03, randf_range(-1.8, -0.2))
			var b := Props.place(lvl, lvl, "ph/binder_notebook", bp, randf_range(0, 360), 0.0, false)
			if b:
				b.visible = false
				tw.parallel().tween_callback(func(): b.visible = true).set_delay(1.5)


# ---------------------------------------------------------------- QA

func qa_check() -> Array:
	var out: Array = []
	var t0 := t_in
	var ea := extract_at
	out.append({"what": "memory extraction starts between one and two compressed hours", "ok": ea >= HOUR and ea <= 2.0 * HOUR, "detail": ea})
	# fast-forward: a notebook is consigned near you, without announcing a loss
	t_in = extract_at + 0.1
	next_take = 0.0
	var before := notebooks.size()
	step(0.016)
	out.append({"what": "after the delay a notebook of your memories appears on a nearby shelf", "ok": notebooks.size() == before + 1})
	# the exchange: knowledge brings the extraction closer; domination angers it
	t_in = t0
	extract_at = ea
	request("lost_hall")
	out.append({"what": "knowledge is paid for in memory (extraction comes sooner)", "ok": extract_at < ea})
	request("dominate")
	await lvl.get_tree().create_timer(0.1).timeout
	out.append({"what": "asking for power angers it (anger, heavy loss, the bookcase falls)", "ok": anger > 0.5 and taken >= 4 and _collapsed})
	return out
