extends Node3D
## Front end: a live, slowly drifting Level 0 tableau behind the menu.
## Continue / New Expedition / Developer browser / Settings / Credits / Quit.

var cam: Camera3D
var ui: CanvasLayer
var _t := 0.0
var _continue_btn: Button


func _ready() -> void:
	SessionState.in_gameplay = false
	SessionState.current_level = ""
	SessionState.set_mode(SessionState.Mode.STORY)
	SessionState.release_mouse()
	get_tree().paused = false
	Overlay.reset_screen_effects()
	_backdrop()
	_menu()


func _backdrop() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color.BLACK
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.95, 0.85, 0.6)
	e.ambient_light_energy = 0.4
	e.fog_enabled = true
	e.fog_light_color = Color(0.7, 0.62, 0.4)
	e.fog_density = 0.05
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.3
	env.environment = e
	add_child(env)
	MatLib.register("menu_panel", MatLib.panel(Color(1.0, 0.96, 0.82), 2.6))
	var k := GeoKit.new(self, "Backdrop")
	k.slab(-12, -30, 12, 6, 0.0, 0.3, "l0_carpet", GeoKit.PY)
	k.slab(-12, -30, 12, 6, 3.05, 0.3, "l0_ceiling", GeoKit.NY)
	for z in range(-30, 6, 3):
		for x in range(-12, 12, 3):
			k.panel(Vector3(x + 1.5, 2.746, z + 1.5), 1.2, 0.6, "menu_panel", float(x * 7 + z), 0.6 if (x + z) % 11 == 0 else 0.0)
	k.wall(Vector3(-3, 0, 6), Vector3(-3, 0, -30), 2.75, 0.16, "l0_wallpaper", [{"at": 9.0, "w": 1.3, "h": 2.2}, {"at": 21.0, "w": 2.8, "h": 2.75}])
	k.wall(Vector3(3, 0, 6), Vector3(3, 0, -30), 2.75, 0.16, "l0_wallpaper", [{"at": 15.0, "w": 1.3, "h": 2.2}])
	k.wall(Vector3(-12, 0, -18), Vector3(-3, 0, -18), 2.75, 0.16, "l0_wallpaper", [{"at": 4.0, "w": 1.2, "h": 2.2}])
	k.wall(Vector3(3, 0, -9), Vector3(12, 0, -9), 2.75, 0.16, "l0_wallpaper", [])
	k.wall(Vector3(-12, 0, -30), Vector3(12, 0, -30), 2.75, 0.16, "l0_wallpaper", [])
	k.commit()
	for z in [-2.0, -10.0, -18.0, -26.0]:
		var l := OmniLight3D.new()
		l.position = Vector3(0, 2.4, z)
		l.light_color = Color(1.0, 0.93, 0.74)
		l.light_energy = 1.4
		l.omni_range = 8.0
		add_child(l)
	cam = Camera3D.new()
	cam.position = Vector3(0.0, 1.62, 4.0)
	cam.fov = 70.0
	add_child(cam)
	cam.current = true
	var hum := AudioStreamPlayer.new()
	hum.stream = AudioSynth.get_stream("fluorescent_hum", {"base": 60.0, "rasp": 0.4})
	hum.bus = "Ambience"
	hum.volume_db = -18.0
	add_child(hum)
	hum.play()


func _menu() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var rootc := Control.new()
	rootc.set_anchors_preset(Control.PRESET_FULL_RECT)
	rootc.theme = Overlay.theme_res
	ui.add_child(rootc)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rootc.add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 90)
	m.add_theme_constant_override("margin_top", 90)
	m.add_theme_constant_override("margin_bottom", 60)
	rootc.add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	m.add_child(vb)
	var title := UITheme.label("LOST FREQUENCY", 64, Color(0.98, 0.93, 0.74))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 10)
	vb.add_child(title)
	vb.add_child(UITheme.label("A source-locked expedition through the Backrooms Wiki (English Wikidot continuity)", 18, Color(0.88, 0.84, 0.72)))
	var c := LevelRegistry.counters()
	vb.add_child(UITheme.label("Roster: %d requested · %d source-audited · %d spawnable · %d playable (engine-verified) · %d fully accepted" % [
		c["requested"], c["source_audited"], c["spawnable"], c["playable"], c["accepted"]], 15, UITheme.MUTED))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	vb.add_child(spacer)
	_continue_btn = UITheme.button("Continue expedition", func(): TransitionService.continue_expedition())
	_continue_btn.disabled = not SaveService.has_story()
	vb.add_child(_continue_btn)
	vb.add_child(UITheme.button("New expedition", _new))
	vb.add_child(UITheme.button("Developer · 100-Level Browser", func(): Overlay.push(Overlay.dev_browser)))
	vb.add_child(UITheme.button("Experimental · Infinite Backrooms · Continuity Lab v5", _open_world_lab))
	vb.add_child(UITheme.button("Settings", func(): Overlay.push(Overlay.settings_panel)))
	vb.add_child(UITheme.button("Credits & attribution", func(): Overlay.push(Overlay.credits_panel)))
	vb.add_child(UITheme.button("Quit", func(): get_tree().quit()))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(fill)
	var foot := UITheme.label("v%s · Godot %s · Unofficial fan adaptation. Level texts CC BY-SA 3.0 by their Backrooms Wiki authors (see Credits)." % [
		ProjectSettings.get_setting("application/config/version"), Engine.get_version_info()["string"]], 13, UITheme.MUTED)
	vb.add_child(foot)
	(_continue_btn if not _continue_btn.disabled else vb.get_child(5)).grab_focus()
	# Command line entry point for QA and for players who want the procedural
	# world straight away:  LostFrequency.exe --lab
	for arg in OS.get_cmdline_user_args():
		if arg == "--lab":
			_open_world_lab()
			return


func _open_world_lab() -> void:
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	get_tree().change_scene_to_file("res://labs/Level0ContinuityLab.tscn")


func _new() -> void:
	if SaveService.has_story():
		Overlay.confirm("Start a new expedition? This replaces your story save (the previous file is kept as a .bak backup).", func(): TransitionService.new_expedition())
	else:
		TransitionService.new_expedition()


func _process(delta: float) -> void:
	_t += delta
	if cam:
		cam.position = Vector3(sin(_t * 0.07) * 0.8, 1.62 + sin(_t * 0.5) * 0.01, 4.0 - fmod(_t * 0.35, 22.0))
		cam.rotation = Vector3(sin(_t * 0.11) * 0.03, sin(_t * 0.05) * 0.25, 0)
