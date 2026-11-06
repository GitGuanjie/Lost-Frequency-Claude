extends CanvasLayer
## The M.E.G. Mobile Terminal AE4 in the volunteer's hand: the article being
## drafted, typed line by line into a small terminal at the bottom left of the
## frame. SOURCE: the page is a terminal log of four documents by isle4, an
## unfinished template, then two drafts each overwritten by lower-case notes,
## then a failed upload ("User isle4 does not exist"). Here those drafts are
## written by what you do. The lines are our paraphrase in the page's register
## (a few short echoes of the page only). ADAPTATION: the panel itself.

## What each discovery writes into each draft: [draft 1, draft 2, draft 3].
## "A:" is the article's own voice, "N:" the volunteer's note, "T:" the
## terminal. Paraphrase in the page's register; quotes are a few words only.
const TEXT := {
	"arrive": [["N:was in level 4 and i clipped through. so that's a way in. no one else here."], ["N:clipped in from level 4. am i just unlucky?"], []],
	"dark": [["N:way too dark in here. some kind of tech demo center?", "N:i feel like i've been here before."],
		["A:It is entirely indoors, modern throughout. Neon blue lighting and artistic fixtures are common."],
		["N:it's just so dark here. everything is too still."]],
	"windows": [["N:big windows. nothing outside. just dark."], ["A:Windows are present, but the exterior is featureless and dark."],
		["N:big windows everywhere and every time i look out i feel lost. is it even night?"]],
	"stare": [[], [], ["N:it's like staring into something's mouth. so heavy. like it's watching me"]],
	"door": [["N:doors are locked."], ["A:All doors are locked."], ["N:locked. every one of them."]],
	"kick": [["N:kicked one down. just more wall behind it."], ["N:tried to kick one in. more wall behind it. probably not supposed to do that"],
		["N:more wall. it's all wall."]],
	"static": [["N:screens everywhere. mostly static."],
		["A:Terminals in the rooms carry the branding of well-known game franchises. None show matching content.", "A:Program: faint static. The most common display."], []],
	"viewer": [["N:one of the screens is filming me??"], ["A:Program: a recording of the viewer, distorted: inverted colours, infrared, coloured outlines."], ["N:it's me on there. i look wrong."]],
	"demo": [["N:old 3d demo stuff running on a loop."], ["A:Program: low-definition recordings of early 3D demonstrations."], []],
	"game": [["N:a little game. jump, jump, jump."], ["A:Program: simple games imitating popular media. Banal, repetitive, often with no ending."], ["N:it never ends. it just doesn't end"]],
	"scare": [["N:jesus f- that scared the hell out of me"], ["N:jesus f- that scared the hell out of me"], ["N:don't play them. don't"]],
	"tone": [["N:black screen, then a horribly loud tone."], ["A:Program: extremely loud, distorted electronic tones over a blank black screen.", "N:it's too dark. just like outside"],
		["N:can't even sleep because of the sound of"]],
	"clocks": [["N:the clocks don't tick."], ["N:clocks still stopped."], []],
	"clock_jump": [[], [], ["N:the clocks don't tick and when i look away they're on a completely different time"]],
	"zero": [[], [], ["N:they all say 00:00 now", "N:no. it went back to normal."]],
	"wake": [[], [], ["N:they turn on on their own now. i can't see anything moving.", "N:nothing moves here but the screens"]],
	"still": [[], [], ["N:the air doesn't even move when i breathe."]],
	"safe": [[], [], ["N:no. i have to stay calm. this is a safe place. i have water and food. i'm safe."]],
	"sorry": [[], [], ["N:sorry for cluttering up the database. i don't know what else to do"]],
}
const HEADERS := [
	["A:Level n is the (n+1)'nd Level of the Backrooms. It [fill this in later]"],
	["A:Level 256 is the 257th Level: an abandoned technological demonstration and exhibition center.", "A:Bases, Outposts and Communities: none.", "N:there's no one here. no one's responding."],
	["A:Level 256: an abandoned technological exhibition center.", "N:i gave it class 5 so it shows up higher. if anyone can see these please talk to me"],
]
const EXITS := [["A:Exits:", "N:haven't found any. keep looking."], ["A:Exits:", "N:there has to be something"], ["N:its too dark"]]

var draft := 1
var lines: Array = []            # every line written, in order (QA / reading)
var _shown: Array = []           # {label, full, t}
var _queue: Array = []
var _box: PanelContainer
var _head: Label
var _body: VBoxContainer
var _font: SystemFont
var _clock := 0.0
var _last_at := -99.0
var corrupt := 0.0               # deterioration of the typing (0..1)
var dead := false
var frozen_style := false
var rng := RandomNumberGenerator.new()


func setup(seed_value: int) -> void:
	layer = 43
	rng.seed = seed_value
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"])
	_box = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.02, 0.05, 0.74)
	sb.border_color = Color(0.25, 0.5, 1.0, 0.55)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10)
	_box.add_theme_stylebox_override("panel", sb)
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = 84
	_box.offset_top = -300
	_box.offset_bottom = -110
	_box.offset_right = 640
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_box.add_child(v)
	_head = _label(13, Color(0.45, 0.7, 1.0))
	v.add_child(_head)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 1)
	v.add_child(_body)
	_set_head()


func _label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", _font)
	var ts: float = float(Settings.get_value("text_scale")) if Settings.get_value("text_scale") != null else 1.0
	l.add_theme_font_size_override("font_size", int(size * ts))
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(520, 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _set_head() -> void:
	_head.text = "M.E.G. MOBILE TERMINAL AE4   isle4   DRAFT %d/3" % draft if not dead else "M.E.G. MOBILE TERMINAL AE4"


## Write a line into the current draft. voice: "article" (the draft's own
## sentences) or "note" (the volunteer, in lower case), or "term" (system).
func write(text: String, voice := "note", delay := 0.0) -> void:
	var at := maxf(_clock + delay, _last_at + 0.9)
	_last_at = at + text.length() * 0.025
	_queue.append({"text": text, "voice": voice, "at": at})
	lines.append(text)


func new_draft(n: int, header: String) -> void:
	draft = n
	_queue.append({"text": "", "voice": "clear", "at": maxf(_clock, _last_at + 1.2)})
	_last_at += 1.4
	if header != "":
		write(header, "article")
	_set_head()


func kill() -> void:
	dead = true
	_set_head()


func _process(delta: float) -> void:
	_clock += delta
	while not _queue.is_empty() and _queue[0]["at"] <= _clock:
		var q: Dictionary = _queue.pop_front()
		if q["voice"] == "clear":
			for s in _shown:
				(s["label"] as Label).queue_free()
			_shown.clear()
			continue
		var col := Color(0.86, 0.9, 1.0) if q["voice"] == "article" else Color(0.62, 0.95, 0.7)
		if q["voice"] == "term":
			col = Color(1.0, 0.45, 0.4)
		var l := _label(15 if q["voice"] != "term" else 14, col)
		_body.add_child(l)
		_shown.append({"label": l, "full": q["text"], "t": 0.0})
		while _shown.size() > 6:
			var old: Dictionary = _shown.pop_front()
			(old["label"] as Label).queue_free()
	for s in _shown:
		s["t"] += delta
		var full: String = s["full"]
		var n := full.length() if frozen_style else int(s["t"] * 40.0)
		var txt := full.substr(0, mini(n, full.length()))
		if corrupt > 0.3 and n < full.length() + 6 and txt.length() > 0 and rng.randf() < corrupt * 0.3:
			var i := rng.randi() % txt.length()
			txt = txt.substr(0, i) + char(97 + rng.randi() % 26) + txt.substr(i + 1)
		(s["label"] as Label).text = txt + ("_" if n < full.length() and not frozen_style else "")
	_box.modulate.a = 1.0 if not dead else 0.55 + 0.2 * sin(_clock * 3.0)


func busy() -> bool:
	return not _queue.is_empty()


## Evidence stills: show these lines at once, fully typed.
func pose(n: int, shown_lines: Array) -> void:
	frozen_style = true
	_queue.clear()
	for s in _shown:
		(s["label"] as Label).queue_free()
	_shown.clear()
	draft = n
	_set_head()
	for t in shown_lines:
		var art: bool = t[0] == "A"
		var l := _label(15, Color(0.86, 0.9, 1.0) if art else Color(0.62, 0.95, 0.7))
		l.text = t.substr(2)
		_body.add_child(l)
		_shown.append({"label": l, "full": t.substr(2), "t": 999.0})
