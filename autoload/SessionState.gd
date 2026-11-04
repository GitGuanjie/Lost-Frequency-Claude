extends Node
## Story vs developer vs QA session scope. Developer actions never write the
## story save; QA mode intercepts transitions for deterministic tests.

signal mode_changed(mode: String)

enum Mode { STORY, DEVELOPER, QA }

var mode: Mode = Mode.STORY
var current_level := ""          # stable id of the loaded level ("" in menus)
var dev_seed := 1337
var qa_seed_override := -1       # >=0 forces level seeds in QA
var in_gameplay := false         # a level with a player is active
var hints_overlay := true
var debug_hint_mode := false     # shows SOURCE/ADAPTATION/DEBUG route tags
var qa_run := false              # launched by the QA harness: saves go to a sandbox dir
var qa_fixtures := false         # story-mode QA playthrough: keep deterministic QA exit fixtures


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_user_args().has("--qa"):
		mode = Mode.QA
		qa_run = true


func is_story() -> bool:
	return mode == Mode.STORY


func is_developer() -> bool:
	return mode == Mode.DEVELOPER


func is_qa() -> bool:
	return mode == Mode.QA or qa_fixtures


func mode_name() -> String:
	return ["STORY", "DEVELOPER", "QA"][mode]


func set_mode(m: Mode) -> void:
	if m == mode:
		return
	mode = m
	mode_changed.emit(mode_name())


## Deterministic per-level seed. Story uses the save's world seed so a
## playthrough stays stable; developer/QA can override.
func seed_for(sid: String) -> int:
	if mode == Mode.QA and qa_seed_override >= 0:
		return qa_seed_override
	var base := dev_seed
	if mode == Mode.STORY:
		base = int(SaveService.story.get("seed", 1))
	return absi(hash("%d:%s" % [base, sid])) % 2147483647


func capture_mouse() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
