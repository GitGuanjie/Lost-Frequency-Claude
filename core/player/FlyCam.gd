extends Camera3D
## Developer-only inspection camera. No collision, no effect on player state.

var speed := 6.0
var pitch := 0.0
var yaw := 0.0


func _ready() -> void:
	yaw = global_rotation.y
	pitch = global_rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.get_value("mouse_sensitivity")
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.55, 1.55)
		global_rotation = Vector3(pitch, yaw, 0)


func _process(delta: float) -> void:
	var v := Vector3.ZERO
	v += -global_transform.basis.z * Input.get_axis("move_back", "move_forward")
	v += global_transform.basis.x * Input.get_axis("move_left", "move_right")
	if Input.is_action_pressed("jump"):
		v += Vector3.UP
	if Input.is_action_pressed("crouch"):
		v += Vector3.DOWN
	var s := speed * (4.0 if Input.is_action_pressed("sprint") else 1.0)
	global_position += v.normalized() * s * delta if v.length() > 0.01 else Vector3.ZERO
