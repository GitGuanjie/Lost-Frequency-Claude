extends Node3D
## The bedroom computer (SOURCE): an old Windows-95-like machine with profiles
## "Owner" (password unknown) and "Guest" (no password); apps Mail (messaging
## between houses; a first-boot email from an unknown sender), Internet (old
## browser, redacted / vague / cryptic answers) and DreamSleep (bright pretty
## loading screen for about a minute, then "Your dreams are ready, sleep to
## start"). The screen is a live SubViewport on the CRT. The email's text is
## blank in the dated snapshot, so it is shown as unreadable, never invented.

signal dreams_ready

const LOAD_S := 60.0
var state := "off"          # off, boot, login, desktop, mail, internet, dream
var dream_progress := 0.0
var dream_running := false
var ready_flag := false
var _t := 0.0
var _vp: SubViewport
var _bg: ColorRect
var _title: Label
var _body: Label
var _bar: ProgressBar
var _icons: Array = []      # Interactables over the desktop icons
var screen_it: Interactable


func build(screen_center: Vector3, normal: Vector3, level: LevelBase) -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(320, 240)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_bg = ColorRect.new()
	_bg.size = Vector2(320, 240)
	_vp.add_child(_bg)
	_title = Label.new()
	_title.position = Vector2(10, 6)
	_title.size = Vector2(300, 24)
	_title.add_theme_font_size_override("font_size", 16)
	_vp.add_child(_title)
	_body = Label.new()
	_body.position = Vector2(12, 34)
	_body.size = Vector2(296, 170)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 13)
	_vp.add_child(_body)
	_bar = ProgressBar.new()
	_bar.position = Vector2(30, 200)
	_bar.size = Vector2(260, 16)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_vp.add_child(_bar)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vp.get_texture()
	var screen := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.3, 0.225)
	screen.mesh = qm
	screen.material_override = mat
	add_child(screen)
	screen.global_position = screen_center
	screen.look_at(screen_center - normal, Vector3.UP)
	screen_it = level.add_interactable(screen_center, Vector3(0.12, 0.28, 0.36), "Turn on the computer", _press)
	var along := Vector3(-normal.z, 0, normal.x)
	var names := ["Open Mail", "Open Internet", "Open DreamSleep"]
	for i in 3:
		var c := screen_center + normal * 0.075 + Vector3.UP * (0.055 - i * 0.055) - along * 0.09
		var it := level.add_interactable(c, Vector3(0.05, 0.045, 0.05), names[i], _open.bind(["mail", "internet", "dream"][i]))
		it.collision_layer = 0
		_icons.append(it)
	_render()


func _press(_p: Player) -> void:
	match state:
		"off":
			state = "boot"
			_t = 2.2
		"login":
			state = "desktop"
		"mail", "internet", "dream":
			state = "desktop"
	_render()


func _open(_p: Player, app: String) -> void:
	state = app
	if app == "dream" and not dream_running and not ready_flag:
		dream_running = true
	_render()


func _process(delta: float) -> void:
	if state == "boot":
		_t -= delta
		if _t <= 0.0:
			state = "login"
			_render()
	if dream_running and not ready_flag:
		dream_progress = minf(1.0, dream_progress + delta / LOAD_S)
		if dream_progress >= 1.0:
			ready_flag = true
			dream_running = false
			dreams_ready.emit()
			_render()
	if state == "dream":
		_bar.value = dream_progress
		var h := fmod(Time.get_ticks_msec() * 0.00012, 1.0)
		_bg.color = Color.from_hsv(h, 0.32, 1.0)


func _render() -> void:
	_bar.visible = state == "dream" or state == "boot"
	for it in _icons:
		(it as Interactable).collision_layer = 4 if state == "desktop" else 0
	var dark := Color(0.1, 0.1, 0.12)
	_title.add_theme_color_override("font_color", dark)
	_body.add_theme_color_override("font_color", dark)
	match state:
		"off":
			_bg.color = Color(0.05, 0.06, 0.06)
			_title.text = ""
			_body.text = ""
			screen_it.prompt = "Turn on the computer"
		"boot":
			_bg.color = Color(0.0, 0.5, 0.55)
			_title.text = "Starting up..."
			_body.text = ""
			_bar.value = 0.5
			screen_it.prompt = "Wait for it to start"
		"login":
			_bg.color = Color(0.0, 0.5, 0.55)
			_title.text = "Welcome - choose a user"
			_body.text = "[ Owner ]   password: ????????\n\n[ Guest ]   no password"
			screen_it.prompt = "Log in as Guest (the Owner account is locked)"
		"desktop":
			_bg.color = Color(0.98, 0.78, 0.86)
			_title.text = "Guest"
			_body.text = "   Mail\n\n   Internet\n\n   DreamSleep" + ("   (ready)" if ready_flag else "")
			screen_it.prompt = "Click an icon (Mail, Internet, DreamSleep)"
		"mail":
			_bg.color = Color(0.95, 0.95, 0.97)
			_title.text = "Mail - Inbox (1)"
			_body.text = "From: (unknown sender)\nReceived: first start-up\n\nAbout this house and its resident, 'Kitty'.\n\n[ The message body will not display. ]\n\nOther houses online: none"
			screen_it.prompt = "Close Mail"
		"internet":
			_bg.color = Color(0.93, 0.95, 1.0)
			_title.text = "Internet"
			_body.text = "Search: where am I\n  > This search is not available.\nSearch: how do I get home\n  > [REDACTED]\nSearch: who is Kitty\n  > ᚲᛁ⟟⊑ ⋏⍜ ᛟᚱ ⌇⟒⟒"
			screen_it.prompt = "Close Internet"
		"dream":
			_title.text = "DreamSleep"
			if ready_flag:
				_bg.color = Color(1.0, 0.88, 0.95)
				_body.text = "\n\n      Your dreams are ready, sleep to start"
			else:
				_body.text = "\n\n      loading your dreams..."
			screen_it.prompt = "Close DreamSleep" + ("" if ready_flag else " (it keeps loading)")
