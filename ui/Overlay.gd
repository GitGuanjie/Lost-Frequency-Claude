extends CanvasLayer
## Global UI layer (autoload): HUD, pause menu (Esc), developer 100-level browser
## (F3), settings, journal, credits, note viewer, loading/fade, death screen.
## Owns pause + mouse-capture policy: any open menu pauses gameplay and frees
## the mouse; closing the last one resumes and recaptures. Out-of-story UI is
## never diegetic and never changes canon state except through explicit,
## labelled developer actions.

var theme_res: Theme
var root: Control
var fx: ColorRect
var fx_mat: ShaderMaterial
var hud: Control
var prompt_label: Label
var subtitle_label: Label
var toast_box: VBoxContainer
var stamina_bar: ProgressBar
var oxygen_bar: ProgressBar
var noclip_bar: ProgressBar
var crosshair: ColorRect
var title_card: VBoxContainer
var mode_badge: Label
var fps_label: Label
var hint_label: Label

var pause_menu: Control
var dev_browser: Control
var settings_panel: Control
var journal_panel: Control
var credits_panel: Control
var note_panel: Control
var death_panel: Control
var confirm_panel: Control
var loading_panel: Control
var loading_title: Label
var loading_bar: ProgressBar
var fade: ColorRect

var _stack: Array = []
var _sub_t := 0.0
var _title_t := 0.0
var _rebind_action := ""
var _rebind_button: Button = null
var _confirm_yes: Callable
var _dev_list: ItemList
var _dev_search: LineEdit
var _dev_filter: OptionButton
var _dev_details: RichTextLabel
var _dev_arrival: OptionButton
var _dev_spawn: Button
var _dev_counters: Label
var _dev_ids: Array = []
var _journal_text: RichTextLabel
var _note_title: Label
var _note_text: RichTextLabel
var _death_label: Label
var _confirm_label: Label
var _pause_save_btn: Button
var _pause_mode_label: Label
var _underwater := 0.0
var _underwater_target := 0.0
var _hints_on := true


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme_res = UITheme.build(float(Settings.get_value("text_scale")))
	root = Control.new()
	root.name = "OverlayRoot"
	root.theme = theme_res
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_fx()
	_build_hud()
	pause_menu = _build_pause()
	dev_browser = _build_dev_browser()
	settings_panel = _build_settings()
	journal_panel = _build_journal()
	credits_panel = _build_credits()
	note_panel = _build_note()
	death_panel = _build_death()
	confirm_panel = _build_confirm()
	_build_loading()
	Settings.changed.connect(_on_setting_changed)
	SessionState.mode_changed.connect(func(_m): _refresh_mode_badge())
	_refresh_mode_badge()


# ================================================================== builders

func _full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c


func _build_fx() -> void:
	fx = ColorRect.new()
	_full(fx)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_mat = ShaderMaterial.new()
	fx_mat.shader = load("res://core/graphics/shaders/screen_fx.gdshader")
	fx.material = fx_mat
	fx.visible = false
	root.add_child(fx)
	_apply_fx_settings()


func _apply_fx_settings() -> void:
	fx_mat.set_shader_parameter("brightness", float(Settings.get_value("brightness")))
	fx_mat.set_shader_parameter("contrast", float(Settings.get_value("contrast")))
	fx_mat.set_shader_parameter("grain", 0.0 if Settings.get_value("reduce_motion") else 0.025)


func _build_hud() -> void:
	hud = Control.new()
	_full(hud)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	root.add_child(hud)
	crosshair = ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.55)
	crosshair.size = Vector2(4, 4)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-2, -2)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(crosshair)
	noclip_bar = ProgressBar.new()
	noclip_bar.show_percentage = false
	noclip_bar.custom_minimum_size = Vector2(160, 6)
	noclip_bar.set_anchors_preset(Control.PRESET_CENTER)
	noclip_bar.position = Vector2(-80, 26)
	noclip_bar.max_value = 1.0
	noclip_bar.visible = false
	hud.add_child(noclip_bar)
	prompt_label = UITheme.label("", 20)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-400, -150)
	prompt_label.size = Vector2(800, 30)
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(prompt_label)
	subtitle_label = UITheme.label("", 19, Color(0.95, 0.95, 0.9))
	subtitle_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.position = Vector2(-500, -110)
	subtitle_label.size = Vector2(1000, 30)
	subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	subtitle_label.add_theme_constant_override("outline_size", 7)
	hud.add_child(subtitle_label)
	toast_box = VBoxContainer.new()
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.position = Vector2(-430, 24)
	toast_box.size = Vector2(860, 10)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_box)
	var bars := VBoxContainer.new()
	bars.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bars.position = Vector2(28, -80)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bars)
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(180, 6)
	stamina_bar.show_percentage = false
	stamina_bar.max_value = 1.0
	bars.add_child(stamina_bar)
	oxygen_bar = ProgressBar.new()
	oxygen_bar.custom_minimum_size = Vector2(180, 8)
	oxygen_bar.show_percentage = false
	oxygen_bar.max_value = 1.0
	oxygen_bar.add_theme_stylebox_override("fill", UITheme.box(Color(0.45, 0.8, 0.95), Color(0, 0, 0, 0), 0, 2, 0))
	bars.add_child(oxygen_bar)
	title_card = VBoxContainer.new()
	title_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_card.position = Vector2(-500, 160)
	title_card.size = Vector2(1000, 100)
	title_card.alignment = BoxContainer.ALIGNMENT_CENTER
	title_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_card.modulate.a = 0.0
	hud.add_child(title_card)
	var t1 := UITheme.label("", 40, Color(0.97, 0.93, 0.8))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t1.add_theme_constant_override("outline_size", 8)
	title_card.add_child(t1)
	var t2 := UITheme.label("", 18, UITheme.MUTED)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t2.add_theme_constant_override("outline_size", 6)
	title_card.add_child(t2)
	mode_badge = UITheme.label("", 15, UITheme.WARN)
	mode_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mode_badge.position = Vector2(-420, 14)
	mode_badge.size = Vector2(400, 24)
	mode_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(mode_badge)
	fps_label = UITheme.label("", 14, UITheme.MUTED)
	fps_label.position = Vector2(14, 10)
	root.add_child(fps_label)
	hint_label = UITheme.label("", 14, Color(0.8, 0.78, 0.7, 0.75))
	hint_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint_label.position = Vector2(-720, -34)
	hint_label.size = Vector2(700, 24)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(hint_label)


func _panel(min_size: Vector2) -> Array:
	var holder := Control.new()
	_full(holder)
	holder.visible = false
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	_full(dim)
	dim.color = Color(0, 0, 0, 0.55)
	holder.add_child(dim)
	var center := CenterContainer.new()
	_full(center)
	holder.add_child(center)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = min_size
	center.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	root.add_child(holder)
	return [holder, vb]


func _build_pause() -> Control:
	var r := _panel(Vector2(420, 0))
	var vb: VBoxContainer = r[1]
	var title := UITheme.label("PAUSED", 30, UITheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	_pause_mode_label = UITheme.label("", 14, UITheme.MUTED)
	_pause_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_mode_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pause_mode_label.custom_minimum_size = Vector2(380, 0)
	vb.add_child(_pause_mode_label)
	vb.add_child(UITheme.button("Resume", func(): close_all()))
	vb.add_child(UITheme.button("Journal", func(): push(journal_panel)))
	vb.add_child(UITheme.button("Settings", func(): push(settings_panel)))
	_pause_save_btn = UITheme.button("Save expedition", func(): _save_now())
	vb.add_child(_pause_save_btn)
	vb.add_child(UITheme.button("Restart from checkpoint", func(): _restart_checkpoint()))
	vb.add_child(UITheme.button("Developer · 100-Level Browser (F3)", func(): push(dev_browser)))
	vb.add_child(UITheme.button("Main menu", func(): TransitionService.goto_main_menu()))
	vb.add_child(UITheme.button("Quit to desktop", func(): _quit()))
	return r[0]


func _build_dev_browser() -> Control:
	var holder := Control.new()
	_full(holder)
	holder.visible = false
	var bg := ColorRect.new()
	_full(bg)
	bg.color = Color(0.02, 0.02, 0.018, 0.96)
	holder.add_child(bg)
	var m := MarginContainer.new()
	_full(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 28)
	holder.add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	head.add_child(UITheme.label("DEVELOPER · 100-LEVEL BROWSER", 26, UITheme.ACCENT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(UITheme.button("Close (Esc)", func(): pop()))
	_dev_counters = UITheme.label("", 15, UITheme.MUTED)
	vb.add_child(_dev_counters)
	var note := UITheme.label("Developer mode is a separate sandbox: it never writes the story save. Entries without a built scene are LOCKED / IN DEVELOPMENT and cannot be spawned. Source data captured from the live Backrooms Wikidot pages on 2026-11-04.", 14, UITheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(note)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	vb.add_child(body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.9
	body.add_child(left)
	var row := HBoxContainer.new()
	left.add_child(row)
	_dev_search = LineEdit.new()
	_dev_search.placeholder_text = "Search id, title, author, mechanic…"
	_dev_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_search.text_changed.connect(func(_t): _dev_refresh())
	row.add_child(_dev_search)
	_dev_filter = OptionButton.new()
	for f in ["All 100", "Spawnable", "Playable", "Locked", "Group A", "Group B", "Group C", "Group D"]:
		_dev_filter.add_item(f)
	_dev_filter.item_selected.connect(func(_i): _dev_refresh())
	row.add_child(_dev_filter)
	_dev_list = ItemList.new()
	_dev_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dev_list.item_selected.connect(_dev_select)
	_dev_list.item_activated.connect(func(_i): _dev_spawn_selected())
	left.add_child(_dev_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_dev_details = RichTextLabel.new()
	_dev_details.bbcode_enabled = true
	_dev_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dev_details.focus_mode = Control.FOCUS_ALL
	_dev_details.selection_enabled = true
	right.add_child(_dev_details)
	var brow := HBoxContainer.new()
	right.add_child(brow)
	brow.add_child(UITheme.label("Arrival:", 16))
	_dev_arrival = OptionButton.new()
	_dev_arrival.custom_minimum_size = Vector2(220, 0)
	brow.add_child(_dev_arrival)
	_dev_spawn = UITheme.button("Spawn in developer mode", func(): _dev_spawn_selected())
	brow.add_child(_dev_spawn)
	root.add_child(holder)
	return holder


func _build_settings() -> Control:
	var r := _panel(Vector2(760, 560))
	var vb: VBoxContainer = r[1]
	vb.add_child(UITheme.label("SETTINGS", 26, UITheme.ACCENT))
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size = Vector2(720, 440)
	vb.add_child(tabs)
	# Controls
	var c := _tab(tabs, "Controls")
	_slider_row(c, "Mouse sensitivity", "mouse_sensitivity", 0.0005, 0.008, 0.0001)
	_check_row(c, "Invert vertical look", "invert_y")
	c.add_child(UITheme.label("Key bindings (click, then press a key):", 15, UITheme.MUTED))
	for a in Settings.REBINDABLE:
		var hb := HBoxContainer.new()
		var l := UITheme.label(Settings.ACTION_LABELS.get(a, a), 16)
		l.custom_minimum_size = Vector2(260, 0)
		hb.add_child(l)
		var b := Button.new()
		b.text = Settings.binding_text(a)
		b.custom_minimum_size = Vector2(180, 34)
		b.pressed.connect(func(): _begin_rebind(a, b))
		hb.add_child(b)
		c.add_child(hb)
	c.add_child(UITheme.button("Reset bindings", func(): Settings.reset_bindings(); _refresh_bind_buttons(c)))
	# Video
	var v := _tab(tabs, "Video")
	var q := OptionButton.new()
	for n in Settings.QUALITY_NAMES:
		q.add_item(n)
	q.select(Settings.quality())
	q.item_selected.connect(func(i): Settings.set_value("quality", i))
	_row(v, "Quality preset (applies on next level load)", q)
	_slider_row(v, "Field of view", "fov", 60.0, 100.0, 1.0)
	_slider_row(v, "Brightness", "brightness", 0.6, 1.6, 0.05)
	_slider_row(v, "Contrast", "contrast", 0.7, 1.4, 0.05)
	_check_row(v, "Show frame time / FPS", "show_fps")
	var fsb := CheckBox.new()
	fsb.text = "Fullscreen"
	fsb.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fsb.toggled.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	v.add_child(fsb)
	# Audio
	var au := _tab(tabs, "Audio")
	for pair in [["Master", "vol_master"], ["Music", "vol_music"], ["Effects", "vol_sfx"], ["Ambience", "vol_ambience"], ["Interface", "vol_ui"]]:
		_slider_row(au, pair[0], pair[1], 0.0, 1.0, 0.05)
	# Accessibility
	var ac := _tab(tabs, "Accessibility")
	_check_row(ac, "Subtitles and sound captions", "subtitles")
	_check_row(ac, "Head bob", "head_bob")
	_check_row(ac, "Reduce motion (no bob, no grain, softer effects)", "reduce_motion")
	_check_row(ac, "Show control hints", "hints")
	_slider_row(ac, "Text scale (applies after restart)", "text_scale", 0.8, 1.6, 0.05)
	vb.add_child(UITheme.button("Back (Esc)", func(): pop()))
	return r[0]


func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.name = title
	tabs.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	sc.add_child(vb)
	return vb


func _row(parent: Control, text: String, ctrl: Control) -> void:
	var hb := HBoxContainer.new()
	var l := UITheme.label(text, 16)
	l.custom_minimum_size = Vector2(330, 0)
	hb.add_child(l)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(ctrl)
	parent.add_child(hb)


func _slider_row(parent: Control, text: String, key: String, mn: float, mx: float, step: float) -> void:
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = step
	s.value = float(Settings.get_value(key))
	s.custom_minimum_size = Vector2(300, 24)
	s.value_changed.connect(func(val): Settings.set_value(key, val))
	_row(parent, text, s)


func _check_row(parent: Control, text: String, key: String) -> void:
	var cb := CheckBox.new()
	cb.text = text
	cb.button_pressed = bool(Settings.get_value(key))
	cb.toggled.connect(func(on): Settings.set_value(key, on))
	parent.add_child(cb)


func _begin_rebind(action: String, b: Button) -> void:
	_rebind_action = action
	_rebind_button = b
	b.text = "Press a key…"


func _refresh_bind_buttons(_c: Control) -> void:
	pass


func _build_journal() -> Control:
	var r := _panel(Vector2(820, 560))
	var vb: VBoxContainer = r[1]
	vb.add_child(UITheme.label("JOURNAL", 26, UITheme.ACCENT))
	_journal_text = RichTextLabel.new()
	_journal_text.bbcode_enabled = true
	_journal_text.custom_minimum_size = Vector2(780, 440)
	_journal_text.focus_mode = Control.FOCUS_ALL
	vb.add_child(_journal_text)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	var hint := CheckBox.new()
	hint.text = "Developer route hints for this level (SOURCE / ADAPTATION / DEBUG ONLY)"
	hint.toggled.connect(func(on): SessionState.debug_hint_mode = on; _refresh_journal())
	hb.add_child(hint)
	vb.add_child(UITheme.button("Back (Esc)", func(): pop()))
	return r[0]


func _build_credits() -> Control:
	var r := _panel(Vector2(900, 600))
	var vb: VBoxContainer = r[1]
	vb.add_child(UITheme.label("CREDITS & ATTRIBUTION", 26, UITheme.ACCENT))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.custom_minimum_size = Vector2(860, 480)
	rt.focus_mode = Control.FOCUS_ALL
	rt.name = "CreditsText"
	vb.add_child(rt)
	vb.add_child(UITheme.button("Back (Esc)", func(): pop()))
	return r[0]


func _credits_bbcode() -> String:
	var s := "[b]LOST FREQUENCY[/b] — an unofficial, non-commercial adaptation of the [b]Backrooms Wiki[/b] (English Wikidot continuity, https://backrooms-wiki.wikidot.com/).\n"
	s += "Content relating to the Backrooms is licensed under Creative Commons Sharealike 3.0 and all concepts originate from http://backrooms-wiki.wikidot.com/ and its authors. LOST FREQUENCY, being derived from this content, is hereby also released under [b]Creative Commons Sharealike 3.0[/b] (code included; see LICENSE.md).\n"
	s += "All textures, materials and sounds in this build are generated procedurally in-project; no third-party images, models or audio are shipped.\n"
	s += "Built with Godot Engine (MIT). Physics: Jolt (MIT).\n\n[b]Source pages (accessed 2026-11-04)[/b]\n"
	for e in LevelRegistry.entries:
		s += "• %s — by %s — %s\n" % [e.get("page_title", ""), e.get("cite_authors", "?"), e.get("url", "")]
	return s


func _build_note() -> Control:
	var r := _panel(Vector2(700, 420))
	var vb: VBoxContainer = r[1]
	_note_title = UITheme.label("", 24, UITheme.ACCENT)
	vb.add_child(_note_title)
	_note_text = RichTextLabel.new()
	_note_text.bbcode_enabled = true
	_note_text.custom_minimum_size = Vector2(660, 300)
	vb.add_child(_note_text)
	vb.add_child(UITheme.button("Close (Esc)", func(): pop()))
	return r[0]


func _build_death() -> Control:
	var r := _panel(Vector2(520, 0))
	var vb: VBoxContainer = r[1]
	_death_label = UITheme.label("", 22, UITheme.DANGER)
	_death_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_death_label.custom_minimum_size = Vector2(480, 0)
	vb.add_child(_death_label)
	vb.add_child(UITheme.button("Wake at last checkpoint", func(): _restart_checkpoint()))
	vb.add_child(UITheme.button("Main menu", func(): TransitionService.goto_main_menu()))
	return r[0]


func _build_confirm() -> Control:
	var r := _panel(Vector2(560, 0))
	var vb: VBoxContainer = r[1]
	_confirm_label = UITheme.label("", 18)
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.custom_minimum_size = Vector2(520, 0)
	vb.add_child(_confirm_label)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	hb.add_child(UITheme.button("Continue", func(): pop(); if _confirm_yes.is_valid(): _confirm_yes.call()))
	hb.add_child(UITheme.button("Cancel", func(): pop()))
	return r[0]


func _build_loading() -> void:
	loading_panel = Control.new()
	_full(loading_panel)
	loading_panel.visible = false
	var bg := ColorRect.new()
	_full(bg)
	bg.color = Color(0, 0, 0, 1)
	loading_panel.add_child(bg)
	var c := CenterContainer.new()
	_full(c)
	loading_panel.add_child(c)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	c.add_child(vb)
	loading_title = UITheme.label("", 28, Color(0.95, 0.9, 0.75))
	loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(loading_title)
	loading_bar = ProgressBar.new()
	loading_bar.custom_minimum_size = Vector2(520, 8)
	loading_bar.show_percentage = false
	loading_bar.max_value = 1.0
	vb.add_child(loading_bar)
	root.add_child(loading_panel)
	fade = ColorRect.new()
	_full(fade)
	fade.color = Color(0, 0, 0, 1)
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)


# ============================================================= menu stack

func is_menu_open() -> bool:
	return not _stack.is_empty()


func push(panel: Control) -> void:
	if panel == null:
		return
	if _stack.has(panel):
		_stack.erase(panel)
	for p in _stack:
		p.visible = false
	_stack.append(panel)
	panel.visible = true
	if panel == dev_browser:
		_dev_refresh()
		_dev_search.grab_focus()
	elif panel == journal_panel:
		_refresh_journal()
	elif panel == credits_panel:
		var rt := credits_panel.find_child("CreditsText", true, false) as RichTextLabel
		if rt and rt.text == "":
			rt.text = _credits_bbcode()
	elif panel == pause_menu:
		_refresh_pause()
	_focus_first(panel)
	if SessionState.in_gameplay:
		get_tree().paused = true
	SessionState.release_mouse()
	_ui_sound("open")


func pop() -> void:
	if _stack.is_empty():
		return
	var top: Control = _stack.pop_back()
	top.visible = false
	if not _stack.is_empty():
		var p: Control = _stack.back()
		p.visible = true
		_focus_first(p)
	else:
		_resume_gameplay()
	_ui_sound("close")


func close_all() -> void:
	for p in _stack:
		p.visible = false
	_stack.clear()
	_resume_gameplay()


func _resume_gameplay() -> void:
	if SessionState.in_gameplay and not TransitionService.loading:
		get_tree().paused = false
		SessionState.capture_mouse()


func _focus_first(panel: Control) -> void:
	var stack: Array = [panel]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Button and (n as Button).visible and not (n as Button).disabled:
			(n as Button).grab_focus()
			return
		for ch in n.get_children():
			stack.append(ch)


func open_pause() -> void:
	if SessionState.in_gameplay and _stack.is_empty():
		push(pause_menu)


func _refresh_pause() -> void:
	var mode := SessionState.mode_name()
	var txt := "Story expedition — progress saves at arrivals and checkpoints."
	if SessionState.is_developer():
		txt = "DEVELOPER MODE — sandbox session. Your story save is untouched."
	_pause_mode_label.text = "%s\n%s" % [LevelRegistry.display_name(SessionState.current_level), txt]
	_pause_save_btn.disabled = mode != "STORY"


# ================================================================== input

func _input(event: InputEvent) -> void:
	if _rebind_action != "" and event is InputEventKey and event.pressed:
		var code: int = (event as InputEventKey).physical_keycode
		if code != KEY_ESCAPE:
			Settings.rebind(_rebind_action, code)
		if _rebind_button:
			_rebind_button.text = Settings.binding_text(_rebind_action)
		_rebind_action = ""
		_rebind_button = null
		get_viewport().set_input_as_handled()
		return
	if TransitionService.loading:
		return
	var typing := get_viewport().gui_get_focus_owner() is LineEdit
	if event.is_action_pressed("pause"):
		if not _stack.is_empty():
			if _stack.back() == death_panel:
				return
			pop()
		elif SessionState.in_gameplay:
			open_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dev_browser"):
		if not _stack.is_empty() and _stack.back() == dev_browser:
			pop()
		else:
			push(dev_browser)
		get_viewport().set_input_as_handled()
	elif typing:
		return
	elif event.is_action_pressed("journal") and SessionState.in_gameplay:
		if not _stack.is_empty() and _stack.back() == journal_panel:
			pop()
		elif _stack.is_empty():
			push(journal_panel)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dev_next") and _stack.is_empty() and SessionState.in_gameplay:
		if SessionState.is_developer():
			var step := -1 if Input.is_key_pressed(KEY_SHIFT) else 1
			var nxt := LevelRegistry.next_in_catalog(SessionState.current_level, step)
			if nxt != "":
				TransitionService.dev_jump(nxt)
		else:
			toast("F4 is a developer-only catalog key and never a story exit. Open F3 to enter developer mode.", 4.0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("dev_flycam") and _stack.is_empty() and SessionState.in_gameplay:
		var p := _player()
		if p:
			p.toggle_flycam()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_hints"):
		Settings.set_value("hints", not bool(Settings.get_value("hints")))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("screenshot"):
		_screenshot()
		get_viewport().set_input_as_handled()


func _player() -> Player:
	var ps := get_tree().get_nodes_in_group("player")
	return ps[0] as Player if not ps.is_empty() else null


# =================================================================== HUD

func _process(delta: float) -> void:
	var gameplay := SessionState.in_gameplay
	hud.visible = gameplay and not TransitionService.loading
	fx.visible = gameplay
	if _sub_t > 0.0:
		_sub_t -= delta
		if _sub_t <= 0.0:
			subtitle_label.text = ""
	if _title_t > 0.0:
		_title_t -= delta
		var a := 1.0
		if _title_t < 1.5:
			a = _title_t / 1.5
		elif _title_t > 5.0:
			a = (6.0 - _title_t)
		title_card.modulate.a = clampf(a, 0.0, 1.0)
	_underwater = move_toward(_underwater, _underwater_target, delta * 3.0)
	fx_mat.set_shader_parameter("underwater", _underwater)
	if Settings.get_value("show_fps"):
		fps_label.text = "%d FPS · %.1f ms" % [Engine.get_frames_per_second(), 1000.0 / maxf(1.0, Engine.get_frames_per_second())]
	else:
		fps_label.text = ""
	if Settings.get_value("hints") and gameplay:
		hint_label.text = "Esc pause · %s journal · %s light · F3 developer browser · F1 hide hints" % [Settings.binding_text("journal"), Settings.binding_text("flashlight")]
	else:
		hint_label.text = ""


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_bars(stamina: float, oxygen: float, noclip: float) -> void:
	stamina_bar.value = stamina
	stamina_bar.visible = stamina < 0.99
	oxygen_bar.visible = oxygen >= 0.0
	if oxygen >= 0.0:
		oxygen_bar.value = oxygen
	noclip_bar.visible = noclip > 0.01
	noclip_bar.value = noclip


func subtitle(text: String, seconds: float = 2.5) -> void:
	if not Settings.get_value("subtitles"):
		return
	subtitle_label.text = text
	_sub_t = seconds


func toast(text: String, seconds: float = 3.0) -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UITheme.box(Color(0.05, 0.05, 0.04, 0.9), Color(0.55, 0.49, 0.3, 0.6), 1, 4, 12))
	var l := UITheme.label(text, 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(800, 0)
	pc.add_child(l)
	toast_box.add_child(pc)
	while toast_box.get_child_count() > 4:
		toast_box.get_child(0).queue_free()
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func():
		if is_instance_valid(pc):
			pc.queue_free())


func level_title(title: String, cls: String) -> void:
	(title_card.get_child(0) as Label).text = title
	(title_card.get_child(1) as Label).text = cls
	_title_t = 6.0


func set_underwater(on: bool, volume: Variant = null) -> void:
	_underwater_target = 1.0 if on else 0.0
	if on and volume is WaterVolume:
		var t: Color = (volume as WaterVolume).tint
		fx_mat.set_shader_parameter("water_tint", Vector3(t.r, t.g, t.b))
	var idx := AudioServer.get_bus_index("Master")
	var has_lp := AudioServer.get_bus_effect_count(idx) > 0
	if on and not has_lp:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 700.0
		AudioServer.add_bus_effect(idx, lp)
	elif not on and has_lp:
		AudioServer.remove_bus_effect(idx, 0)


## Evidence captures show the rendered world plus screen effects only.
func set_capture_mode(on: bool) -> void:
	toast_box.visible = not on
	mode_badge.visible = not on
	fps_label.visible = not on
	hud.modulate.a = 0.0 if on else 1.0


func reset_screen_effects() -> void:
	for k in ["red_tint", "desaturate", "blackout"]:
		fx_mat.set_shader_parameter(k, 0.0)
	_underwater = 0.0
	_underwater_target = 0.0
	fx_mat.set_shader_parameter("underwater", 0.0)
	var idx := AudioServer.get_bus_index("Master")
	while AudioServer.get_bus_effect_count(idx) > 0:
		AudioServer.remove_bus_effect(idx, 0)


func set_screen_effect(param: String, value: float) -> void:
	fx_mat.set_shader_parameter(param, value)


func show_note(title: String, text: String) -> void:
	_note_title.text = title
	_note_text.text = text
	push(note_panel)


func on_player_died(cause: String) -> void:
	_death_label.text = "You lost consciousness.\n(%s)" % cause
	push(death_panel)


func confirm(message: String, on_yes: Callable) -> void:
	_confirm_label.text = message
	_confirm_yes = on_yes
	push(confirm_panel)


func show_loading(title: String, _reason: String) -> void:
	loading_title.text = title
	loading_bar.value = 0.0
	loading_panel.visible = true


func set_loading_progress(p: float) -> void:
	loading_bar.value = p


func hide_loading() -> void:
	loading_panel.visible = false


func fade_to(alpha: float, seconds: float) -> Signal:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(fade, "modulate:a", alpha, seconds)
	return tw.finished


func _refresh_mode_badge() -> void:
	match SessionState.mode_name():
		"DEVELOPER":
			mode_badge.text = "DEVELOPER MODE · sandbox (story save untouched)"
		"QA":
			mode_badge.text = "QA MODE"
		_:
			mode_badge.text = ""


func _on_setting_changed(key: String) -> void:
	if key in ["brightness", "contrast", "reduce_motion"]:
		_apply_fx_settings()


func _ui_sound(kind: String) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = AudioSynth.get_stream("ui", {"kind": "click" if kind == "open" else "close"})
	p.bus = "UI"
	p.volume_db = -14.0
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


# ============================================================== actions

func _save_now() -> void:
	var lvl := get_tree().current_scene as LevelBase
	if lvl:
		lvl.checkpoint("manual")
	toast("Expedition saved." if SaveService.last_error == "" else "Save failed: " + SaveService.last_error, 2.5)


func _restart_checkpoint() -> void:
	close_all()
	TransitionService.reload_checkpoint()


func _quit() -> void:
	if SessionState.is_story() and SessionState.in_gameplay:
		SaveService.save_story("quit")
	get_tree().quit()


func _screenshot() -> void:
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://screenshots"))
	var p := "user://screenshots/LF_%s_%d.png" % [SessionState.current_level, Time.get_unix_time_from_system()]
	img.save_png(p)
	toast("Screenshot saved: " + ProjectSettings.globalize_path(p), 3.0)


# ======================================================= developer browser

func _dev_refresh() -> void:
	var c := LevelRegistry.counters()
	_dev_counters.text = "%d requested · %d source-audited · %d spawnable · %d playable (engine-verified) · %d fully accepted · mode: %s" % [
		c["requested"], c["source_audited"], c["spawnable"], c["playable"], c["accepted"], SessionState.mode_name()]
	var q := _dev_search.text.strip_edges().to_lower()
	var f := _dev_filter.selected
	_dev_list.clear()
	_dev_ids.clear()
	for e in LevelRegistry.entries:
		var sid: String = e["stable_id"]
		var spawnable := LevelRegistry.is_spawnable(sid)
		var playable := LevelRegistry.is_playable(sid)
		match f:
			1:
				if not spawnable: continue
			2:
				if not playable: continue
			3:
				if spawnable: continue
			4, 5, 6, 7:
				if not str(e.get("group", "")).begins_with(["A", "B", "C", "D"][f - 4]): continue
		var hay := ("%s %s %s %s %s %s" % [sid, e.get("level_id", ""), e.get("title", ""), e.get("cite_authors", ""),
			e.get("signature_mechanic", ""), e.get("summary", "")]).to_lower()
		if q != "" and not hay.contains(q):
			continue
		var label := "%03d  Level %-6s  %s   [%s]" % [int(e["slot"]), e["level_id"], e.get("title", ""), LevelRegistry.status_label(sid)]
		var idx := _dev_list.add_item(label)
		_dev_list.set_item_custom_fg_color(idx, UITheme.OK if playable else (UITheme.WARN if spawnable else UITheme.LOCKED))
		_dev_ids.append(sid)
	if _dev_list.item_count > 0:
		var keep := _dev_ids.find(SessionState.current_level)
		_dev_list.select(maxi(keep, 0))
		_dev_select(maxi(keep, 0))
	else:
		_dev_details.text = "No entries match."


func _dev_select(i: int) -> void:
	if i < 0 or i >= _dev_ids.size():
		return
	var sid: String = _dev_ids[i]
	var e := LevelRegistry.get_entry(sid)
	var impl: Dictionary = e.get("impl", {})
	var s := "[font_size=24][b]%s[/b][/font_size]\n" % LevelRegistry.display_name(sid)
	s += "[color=#c9c3b0]%s · slot %03d · %s[/color]\n\n" % [sid, int(e["slot"]), e.get("group", "")]
	s += "[b]Status:[/b] %s\n" % LevelRegistry.status_label(sid)
	if impl.has("qa_status"):
		s += "[b]QA:[/b] %s\n" % impl["qa_status"]
	s += "[b]Source:[/b] %s\n" % e.get("url", "")
	s += "[b]Cite as:[/b] \"%s\" by %s (CC BY-SA 3.0)\n" % [e.get("page_title", ""), e.get("cite_authors", "?")]
	s += "[b]Revision:[/b] %s · last edited %s UTC · accessed %s\n" % [e.get("revision", "?"), e.get("last_edited_utc", "?"), str(e.get("accessed_utc", "?")).substr(0, 10)]
	s += "[b]Survival class (as stated):[/b] %s\n" % e.get("survival_class", "not stated")
	s += "[b]Source completeness:[/b] %s\n\n" % e.get("source_completeness", "")
	if str(e.get("summary", "")) != "":
		s += "[b]Identity:[/b] %s\n\n" % e["summary"]
	if str(e.get("signature_mechanic", "")) != "":
		s += "[b]Signature mechanic:[/b] %s\n\n" % e["signature_mechanic"]
	if str(e.get("entity_policy", "")) != "":
		s += "[b]Entity policy:[/b] %s\n\n" % e["entity_policy"]
	var ex: Array = impl.get("exits", [])
	if not ex.is_empty():
		s += "[b]Implemented exits:[/b]\n"
		for x in ex:
			s += "  • → %s  (%s, %s) [%s]\n" % [LevelRegistry.display_name(x.get("to", "")) if LevelRegistry.has_level(x.get("to", "")) else str(x.get("to_label", x.get("to", ""))), x.get("trigger", ""), x.get("confidence", ""), x.get("basis", "SOURCE")]
	if impl.has("notes"):
		s += "\n[b]Implementation notes:[/b] %s\n" % impl["notes"]
	_dev_details.text = s
	_dev_arrival.clear()
	_dev_arrival.add_item("start")
	for a in impl.get("arrivals", []):
		if a != "start":
			_dev_arrival.add_item(a)
	_dev_spawn.disabled = not LevelRegistry.is_spawnable(sid)
	_dev_spawn.text = "Spawn in developer mode" if not _dev_spawn.disabled else "LOCKED / IN DEVELOPMENT"


func _dev_spawn_selected() -> void:
	var i := _dev_list.get_selected_items()
	if i.is_empty():
		return
	var sid: String = _dev_ids[i[0]]
	if not LevelRegistry.is_spawnable(sid):
		toast("%s is LOCKED / IN DEVELOPMENT." % LevelRegistry.display_name(sid), 3.0)
		return
	var arrival := _dev_arrival.get_item_text(_dev_arrival.selected) if _dev_arrival.item_count > 0 else "start"
	if SessionState.is_story() and SessionState.in_gameplay:
		confirm("Enter DEVELOPER MODE and spawn %s?\nYour story expedition is saved now and will not be modified by anything you do in developer mode. Return via Main menu → Continue." % LevelRegistry.display_name(sid),
			func(): TransitionService.dev_jump(sid, arrival))
	else:
		TransitionService.dev_jump(sid, arrival)


# ================================================================ journal

func _refresh_journal() -> void:
	var sc := SaveService.scope()
	var j: Dictionary = sc.get("journal", {})
	var s := ""
	if SessionState.is_developer():
		s += "[color=#f0ad4e]Developer sandbox journal (not your story).[/color]\n\n"
	s += "[b]Current location:[/b] %s\n\n" % LevelRegistry.display_name(SessionState.current_level)
	s += "[b]Levels visited[/b]\n"
	for sid in j.get("levels_visited", []):
		s += "  • %s\n" % LevelRegistry.display_name(sid)
	s += "\n[b]Routes you have witnessed[/b] (only exits you actually used)\n"
	var edges: Array = j.get("edges", [])
	if edges.is_empty():
		s += "  (none yet)\n"
	for e in edges:
		var edge := TransitionService.get_edge(e.get("edge", ""))
		s += "  • %s → %s — %s ×%d\n" % [LevelRegistry.display_name(e.get("from", "")),
			LevelRegistry.display_name(e.get("to", "")) if LevelRegistry.has_level(e.get("to", "")) else str(e.get("to", "")),
			edge.get("label", edge.get("trigger", "")), int(e.get("count", 1))]
	var notes: Array = j.get("notes", [])
	s += "\n[b]Documents read:[/b] %d\n" % notes.size()
	var mig: Variant = sc.get("migrated_from")
	if mig is Dictionary and mig.get("imported", false):
		s += "\n[color=#9a968a]Legacy V%s save imported (seed and visit list only; legacy coordinates were incompatible).[/color]\n" % str(mig.get("version", "?"))
	if SessionState.debug_hint_mode:
		s += "\n[b]Route hints for this level[/b] [color=#9a968a](developer hint mode)[/color]\n"
		for x in TransitionService.exits_of(SessionState.current_level):
			s += "  • [%s] → %s: %s\n" % [x.get("basis", "SOURCE"), x.get("to", ""), x.get("hint", x.get("label", ""))]
	_journal_text.text = s
