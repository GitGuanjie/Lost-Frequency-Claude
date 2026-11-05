extends StaticBody3D
## Level 5 hotel door leaf: a real hinged body (collision swings with it). The
## level script owns the rules (locked / unlocks over time / opens on its own),
## this node only animates and forwards the player's interaction.

var level: Node = null
var number := ""
var state := "locked"        # locked | unlocks | unlocked | random
var unlock_at := -1.0        # level seconds when an "unlocks" door gives way
var next_event := 0.0        # "random" doors: next spontaneous swing
var beverly := false         # a Beverly Room entrance
var open_amount := 0.0
var target := 0.0
var swing := 1.0
var base_basis := Basis()


func _ready() -> void:
	set_process(false)


func get_prompt() -> String:
	return level.door_prompt(self) if level else ""


func interact(p: Node) -> void:
	if level:
		level.door_use(self, p)


func swing_to(v: float, instant: bool = false) -> void:
	target = clampf(v, 0.0, 1.0)
	if instant:
		open_amount = target
		_apply()
	else:
		set_process(true)


func _apply() -> void:
	transform.basis = base_basis * Basis(Vector3.UP, swing * open_amount * deg_to_rad(96.0))


func _process(delta: float) -> void:
	open_amount = move_toward(open_amount, target, delta * 0.85)
	_apply()
	if is_equal_approx(open_amount, target):
		set_process(false)
