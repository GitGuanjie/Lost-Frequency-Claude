class_name Interactable
extends StaticBody3D
## Something the player can look at and press Interact on: notes, switches,
## doors, items. Behaviour is a Callable supplied by the level script so that
## each level keeps its own sourced logic.

signal used(by: Player)

var prompt := "Examine"
var action: Callable
var once := false
var _used := false
var note_id := ""
var note_title := ""
var note_text := ""


func setup(center: Vector3, box_size: Vector3, p: String, cb: Callable = Callable()) -> void:
	position = center
	prompt = p
	action = cb
	collision_layer = 4   # interactables layer
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = box_size
	cs.shape = sh
	add_child(cs)
	add_to_group("interactable")


## A readable document. The text must be in-world, never a raw spoiler.
func as_note(id: String, title: String, text: String) -> void:
	note_id = id
	note_title = title
	note_text = text
	prompt = "Read: " + title


func get_prompt() -> String:
	return "" if (once and _used) else prompt


func interact(p: Player) -> void:
	if once and _used:
		return
	_used = true
	if note_id != "":
		SaveService.read_note(note_id)
		Overlay.show_note(note_title, note_text)
	if action.is_valid():
		action.call(p)
	used.emit(p)
