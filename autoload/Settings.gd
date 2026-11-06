extends Node
## User settings, input map (rebindable), audio buses, quality presets and
## accessibility options. Persisted in user://settings.cfg (never in a save).

signal changed(key: String)

const PATH := "user://settings.cfg"
const QUALITY_NAMES := ["Low", "Medium", "High", "Ultra"]

var values: Dictionary = {
	"mouse_sensitivity": 0.0025,
	"invert_y": false,
	"fov": 75.0,
	"head_bob": true,
	"reduce_motion": false,
	"subtitles": true,
	"hints": true,
	"brightness": 1.0,
	"contrast": 1.0,
	"text_scale": 1.0,
	"quality": 2,
	"vol_master": 0.9,
	"vol_music": 0.7,
	"vol_sfx": 0.9,
	"vol_ambience": 0.85,
	"vol_ui": 0.8,
	"show_fps": false,
	"camcorder": true,
	"seamless": true,
	"photo_materials": true,
}

## action -> [default keycodes...]; gamepad bindings are added separately.
const DEFAULT_KEYS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE],
	"sprint": [KEY_SHIFT],
	"crouch": [KEY_CTRL, KEY_C],
	"interact": [KEY_E],
	"flashlight": [KEY_F],
	"journal": [KEY_J, KEY_TAB],
	"pause": [KEY_ESCAPE],
	"dev_browser": [KEY_F3],
	"dev_next": [KEY_F4],
	"dev_flycam": [KEY_F7],
	"screenshot": [KEY_F12],
	"toggle_hints": [KEY_F1],
}
const REBINDABLE := ["move_forward", "move_back", "move_left", "move_right", "jump",
	"sprint", "crouch", "interact", "flashlight", "journal"]
const ACTION_LABELS := {
	"move_forward": "Move forward", "move_back": "Move back", "move_left": "Strafe left",
	"move_right": "Strafe right", "jump": "Jump / swim up", "sprint": "Sprint",
	"crouch": "Crouch / swim down", "interact": "Interact", "flashlight": "Flashlight",
	"journal": "Journal",
}

var custom_keys: Dictionary = {}  # action -> keycode (first binding override)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_register_inputs()
	_setup_buses()
	apply_audio()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k in values.keys():
		if cfg.has_section_key("settings", k):
			var v: Variant = cfg.get_value("settings", k)
			if typeof(v) == typeof(values[k]) or (typeof(values[k]) == TYPE_FLOAT and typeof(v) == TYPE_INT):
				values[k] = v
	if cfg.has_section("keys"):
		for a in cfg.get_section_keys("keys"):
			if a in REBINDABLE:
				custom_keys[a] = int(cfg.get_value("keys", a))


func save() -> void:
	var cfg := ConfigFile.new()
	for k in values.keys():
		cfg.set_value("settings", k, values[k])
	for a in custom_keys.keys():
		cfg.set_value("keys", a, custom_keys[a])
	cfg.save(PATH)


func get_value(key: String) -> Variant:
	return values.get(key)


func set_value(key: String, v: Variant) -> void:
	values[key] = v
	if key.begins_with("vol_"):
		apply_audio()
	save()
	changed.emit(key)


func _key_event(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code as Key
	return ev


func _register_inputs() -> void:
	for action in DEFAULT_KEYS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		InputMap.action_erase_events(action)
		var keys: Array = DEFAULT_KEYS[action].duplicate()
		if custom_keys.has(action):
			keys[0] = custom_keys[action]
		for code in keys:
			InputMap.action_add_event(action, _key_event(int(code)))
	# Gamepad (standard layout)
	_pad_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_pad_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_pad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_pad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_pad_button("jump", JOY_BUTTON_A)
	_pad_button("crouch", JOY_BUTTON_B)
	_pad_button("interact", JOY_BUTTON_X)
	_pad_button("flashlight", JOY_BUTTON_Y)
	_pad_button("sprint", JOY_BUTTON_LEFT_STICK)
	_pad_button("pause", JOY_BUTTON_START)
	_pad_button("journal", JOY_BUTTON_BACK)
	for a in ["look_left", "look_right", "look_up", "look_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a, 0.15)
	_pad_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_pad_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_pad_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_pad_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _pad_axis(action: String, axis: JoyAxis, dir: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = dir
	InputMap.action_add_event(action, ev)


func _pad_button(action: String, b: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	InputMap.action_add_event(action, ev)


func rebind(action: String, keycode: int) -> void:
	if action not in REBINDABLE:
		return
	custom_keys[action] = keycode
	_register_inputs()
	save()
	changed.emit("keys")


func reset_bindings() -> void:
	custom_keys.clear()
	_register_inputs()
	save()
	changed.emit("keys")


func binding_text(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string((ev as InputEventKey).physical_keycode)
	return "—"


func _setup_buses() -> void:
	for bus in ["Music", "SFX", "Ambience", "UI"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus)
			AudioServer.set_bus_send(idx, "Master")
	# Ambience and SFX get a reverb whose room size each level can tune.
	for bus in ["Ambience", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		if AudioServer.get_bus_effect_count(idx) == 0:
			var rv := AudioEffectReverb.new()
			rv.room_size = 0.4
			rv.wet = 0.15
			rv.dry = 1.0
			AudioServer.add_bus_effect(idx, rv)


## Levels call this to set their acoustic character (0..1 room, wet mix).
func set_reverb(room_size: float, wet: float, damping: float = 0.5) -> void:
	for bus in ["Ambience", "SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0 and AudioServer.get_bus_effect_count(idx) > 0:
			var rv := AudioServer.get_bus_effect(idx, 0) as AudioEffectReverb
			if rv:
				rv.room_size = clampf(room_size, 0.0, 1.0)
				rv.wet = clampf(wet, 0.0, 1.0)
				rv.damping = clampf(damping, 0.0, 1.0)


func apply_audio() -> void:
	var pairs := {"Master": "vol_master", "Music": "vol_music", "SFX": "vol_sfx",
		"Ambience": "vol_ambience", "UI": "vol_ui"}
	for bus in pairs.keys():
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			var lin: float = float(values[pairs[bus]])
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(lin, 0.0001)))
			AudioServer.set_bus_mute(idx, lin <= 0.001)


func quality() -> int:
	return int(values["quality"])
