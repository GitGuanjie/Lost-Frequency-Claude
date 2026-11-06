extends CanvasLayer
## Level 404's interface is the page's voice. The article is written in lower
## case, in the second person, by a narrator who might be you ("where are
## these words coming from?"). Here that voice is not a subtitle bar: lines
## type themselves into the frame at loose positions, like thoughts, and the
## letters slip into hexadecimal as the wanderer becomes aware. A memory is a
## larger block in the middle of the frame. The screen itself datamoshes with
## awareness, clouds over (milky, pink) with stillness, and goes white when
## the consciousness is cut out. ADAPTATION throughout; every line is our own
## paraphrase in the page's register (short echoes of a few words at most).

const Shaders := preload("res://levels/L404/L404_shaders.gd")
const HEX := "0123456789abcdef"

var mat: ShaderMaterial
var rect: ColorRect
var glitch := 0.0
var haze := 0.0
var flash := 0.0
var font: SystemFont
var rng := RandomNumberGenerator.new()
var _queue: Array = []        # {text, at, hold}
var _lines: Array = []        # {label, full, t, hold}
var _last_at := -99.0
var _clock := 0.0
var _slot := 0
var _mem: Label
var _mem_full := ""
var _mem_t := -1.0
var _mem_hold := 0.0
var said: Array = []          # every line shown (QA / evidence)
var frozen_style := false     # evidence stills: fixed look, no typing


func setup(seed_value: int) -> void:
	layer = 44
	rng.seed = seed_value
	var sh := Shader.new()
	sh.code = Shaders.MIND
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	add_child(rect)
	font = SystemFont.new()
	font.font_names = PackedStringArray(["DejaVu Serif", "Liberation Serif", "Georgia", "Times New Roman", "serif"])
	font.font_italic = true
	_mem = _make_label(31)
	_mem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mem.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_mem)


func _make_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	var ts: float = float(Settings.get_value("text_scale")) if Settings.get_value("text_scale") != null else 1.0
	l.add_theme_font_size_override("font_size", int(size * ts))
	l.add_theme_color_override("font_color", Color(1.0, 0.98, 1.0, 1.0))
	l.add_theme_color_override("font_shadow_color", Color(0.62, 0.25, 0.55, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_color_override("font_outline_color", Color(0.35, 0.2, 0.45, 0.35))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Queue a line in the voice. delay is from now; lines never overlap in time.
func say(text: String, hold := 5.0, delay := 0.0) -> void:
	var at := maxf(_clock + delay, _last_at + 1.6)
	_last_at = at
	_queue.append({"text": text, "at": at, "hold": hold})


func busy() -> bool:
	return not _queue.is_empty() or _lines.size() > 1


## A remembered fragment: a larger block, centred, typed slowly.
func memory(text: String, hold := 11.0) -> void:
	_mem_full = text
	_mem_t = 0.0
	_mem_hold = hold
	said.append(text)


## Fixed frame for evidence stills.
func pose_line(text: String, pos_frac: Vector2) -> void:
	var l := _make_label(30)
	l.text = text
	add_child(l)
	var vs := get_viewport().get_visible_rect().size
	l.position = vs * pos_frac
	_lines.append({"label": l, "full": text, "t": 0.0, "hold": 9999.0})


func _spawn(item: Dictionary) -> void:
	var l := _make_label(29)
	l.text = item["text"]
	l.visible_characters = 0
	add_child(l)
	var vs := get_viewport().get_visible_rect().size
	_slot = (_slot + 1) % 4
	l.position = Vector2(vs.x * rng.randf_range(0.07, 0.22), vs.y * (0.24 + 0.115 * _slot))
	_lines.append({"label": l, "full": item["text"], "t": 0.0, "hold": item["hold"]})
	said.append(item["text"])


func _corrupt(full: String, amount: float) -> String:
	if amount <= 0.02 or Settings.get_value("reduce_motion"):
		return full
	var out := ""
	for ch in full:
		if ch != " " and rng.randf() < amount * 0.12:
			out += HEX[rng.randi() % 16]
		else:
			out += ch
	return out


func _process(delta: float) -> void:
	_clock += delta
	var soft: bool = Settings.get_value("reduce_motion")
	flash = maxf(0.0, flash - delta * 0.55)
	var g := glitch * (0.45 if soft else 1.0)
	mat.set_shader_parameter("glitch", clampf(g, 0.0, 1.0))
	mat.set_shader_parameter("haze", clampf(haze, 0.0, 1.0))
	mat.set_shader_parameter("flash", clampf(flash, 0.0, 1.0))
	rect.visible = SessionState.in_gameplay and (g + haze + flash) > 0.004
	while not _queue.is_empty() and (_queue[0]["at"] as float) <= _clock:
		_spawn(_queue.pop_front())
	for ln in _lines.duplicate():
		var l: Label = ln["label"]
		ln["t"] += delta
		var t: float = ln["t"]
		var n := (ln["full"] as String).length()
		if frozen_style:
			l.visible_characters = -1
			l.modulate.a = 1.0
			continue
		l.visible_characters = mini(n, int(t * 24.0)) if t * 24.0 < n else -1
		if int(t * 10.0) % 3 == 0:
			l.text = _corrupt(ln["full"], glitch)
		var hold: float = ln["hold"]
		l.modulate.a = clampf(1.0 - (t - hold) / 1.6, 0.0, 1.0) * clampf(t * 3.0, 0.0, 1.0)
		if t > hold + 1.7:
			l.queue_free()
			_lines.erase(ln)
	if _mem_t >= 0.0:
		_mem_t += delta
		var vs := get_viewport().get_visible_rect().size
		_mem.size = Vector2(vs.x * 0.56, 0)
		_mem.position = Vector2(vs.x * 0.22, vs.y * 0.36)
		_mem.text = _corrupt(_mem_full, glitch * 0.6) if int(_mem_t * 8.0) % 4 == 0 else _mem_full
		_mem.visible_characters = mini(_mem_full.length(), int(_mem_t * 30.0)) if _mem_t * 30.0 < _mem_full.length() else -1
		_mem.modulate.a = clampf(1.0 - (_mem_t - _mem_hold) / 2.0, 0.0, 1.0) * clampf(_mem_t * 2.0, 0.0, 1.0)
		if _mem_t > _mem_hold + 2.1:
			_mem_t = -1.0
			_mem.text = ""


func clear_lines() -> void:
	for ln in _lines:
		(ln["label"] as Label).queue_free()
	_lines.clear()
	_queue.clear()


## Close the current memory early (walking away from it).
func release_memory() -> void:
	if _mem_t >= 0.0 and _mem_t < _mem_hold:
		_mem_hold = _mem_t
