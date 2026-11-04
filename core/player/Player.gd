class_name Player
extends CharacterBody3D
## First-person wanderer: walk / sprint / crouch / jump, swimming with buoyancy
## and oxygen, ladders, flashlight with a per-level policy, interaction, surface
## footsteps, sourced no-clip pressure, and a developer-only flycam (F7) that is
## separate from player physics and rolls back to the player's safe position.

signal died(cause: String)

const EYE_STAND := 1.62
const EYE_CROUCH := 0.95
const HEIGHT_STAND := 1.78
const HEIGHT_CROUCH := 1.05
const RADIUS := 0.32

var walk_speed := 3.1
var sprint_speed := 5.3
var crouch_speed := 1.6
var swim_speed := 2.4
var jump_velocity := 4.3
var gravity := 9.8
var accel := 11.0
var air_accel := 2.5
var step_height := 0.36
var flashlight_policy := "allowed"   # allowed | weak | fails | none
var oxygen_seconds := 40.0
var stamina_max := 6.0

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var shape: CollisionShape3D
var capsule: CapsuleShape3D
var feet_audio: AudioStreamPlayer3D
var ray: RayCast3D

var crouching := false
var swimming := false
var head_under := false
var on_ladder := false
var stamina := 6.0
var oxygen := 40.0
var health := 100.0
var frozen := false        # cutscenes / flycam
var dead := false
var look_pitch := 0.0
var _bob := 0.0
var _step_acc := 0.0
var _step_variant := 0
var _zone_prompts: Dictionary = {}
var _focus: Object = null
var _water: WaterVolume = null
var _noclip_p := 0.0
var _flashlight_timer := 0.0
var _wish_dir := Vector3.ZERO
var _push_dir := Vector3.ZERO
var flycam: Camera3D = null
var stats := {"distance": 0.0, "jumps": 0}
var qa_input := Vector2.ZERO        # QA bot movement override (x strafe, y forward)
var qa_sprint := false
var qa_active := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(46.0)
	floor_snap_length = 0.35
	floor_constant_speed = true
	safe_margin = 0.02
	shape = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT_STAND
	shape.shape = capsule
	shape.position.y = HEIGHT_STAND * 0.5
	add_child(shape)
	head = Node3D.new()
	head.name = "Head"
	head.position.y = EYE_STAND
	add_child(head)
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.04
	camera.far = 600.0
	camera.fov = float(Settings.get_value("fov"))
	camera.current = true
	head.add_child(camera)
	flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.spot_range = 22.0
	flashlight.spot_angle = 26.0
	flashlight.spot_attenuation = 1.2
	flashlight.light_energy = 2.2
	flashlight.light_color = Color(1.0, 0.95, 0.85)
	flashlight.shadow_enabled = true
	flashlight.visible = false
	flashlight.position = Vector3(0.18, -0.12, -0.1)
	camera.add_child(flashlight)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.6)
	ray.collision_mask = 1 | 4
	ray.collide_with_areas = true
	ray.enabled = true
	camera.add_child(ray)
	feet_audio = AudioStreamPlayer3D.new()
	feet_audio.bus = "SFX"
	feet_audio.volume_db = -9.0
	feet_audio.max_distance = 20.0
	add_child(feet_audio)
	stamina = stamina_max
	oxygen = oxygen_seconds
	Settings.changed.connect(_on_setting)
	add_to_group("player")


func _on_setting(key: String) -> void:
	if key == "fov" and camera:
		camera.fov = float(Settings.get_value("fov"))


func apply_rules(rules: Dictionary) -> void:
	gravity = rules.get("gravity", gravity)
	walk_speed = rules.get("walk_speed", walk_speed)
	sprint_speed = rules.get("sprint_speed", sprint_speed)
	jump_velocity = rules.get("jump_velocity", jump_velocity)
	flashlight_policy = rules.get("flashlight", flashlight_policy)
	oxygen_seconds = rules.get("oxygen_seconds", oxygen_seconds)
	oxygen = oxygen_seconds
	camera.far = rules.get("view_distance", camera.far)
	if flashlight_policy == "weak":
		flashlight.light_energy = 0.8
		flashlight.spot_range = 9.0


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if frozen or dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.get_value("mouse_sensitivity")
		var inv := -1.0 if Settings.get_value("invert_y") else 1.0
		rotate_y(-event.relative.x * sens)
		look_pitch = clampf(look_pitch - event.relative.y * sens * inv, deg_to_rad(-88), deg_to_rad(88))
		head.rotation.x = look_pitch
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if not Overlay.is_menu_open() and not get_tree().paused:
			SessionState.capture_mouse()
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()


func toggle_flashlight() -> void:
	match flashlight_policy:
		"none":
			Overlay.toast("You have no working light source here.", 2.5)
			return
		"fails":
			flashlight.visible = not flashlight.visible
			_flashlight_timer = randf_range(2.0, 4.0)
			Overlay.subtitle("[flashlight clicks]", 1.2)
		_:
			flashlight.visible = not flashlight.visible
			Overlay.subtitle("[flashlight clicks]", 1.0)


func _try_interact() -> void:
	if _focus and is_instance_valid(_focus) and _focus.has_method("interact"):
		_focus.interact(self)
		return
	for z in _zone_prompts.keys():
		if is_instance_valid(z) and z.has_method("interact"):
			z.interact(self)
			return


func set_zone_prompt(zone: Object, text: String) -> void:
	if text == "":
		_zone_prompts.erase(zone)
	else:
		_zone_prompts[zone] = text


# ---------------------------------------------------------------- physics

func _physics_process(delta: float) -> void:
	if frozen or dead:
		return
	_update_water()
	_update_ladder()
	var input := _move_input()
	var basis_flat := global_transform.basis
	var dir := (basis_flat.x * input.x + -basis_flat.z * input.y)
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()
	_wish_dir = dir
	_push_dir = dir
	_handle_crouch(delta)
	if swimming:
		_swim(delta, input)
	elif on_ladder:
		_climb(delta, input)
	else:
		_walk(delta, dir)
	_update_focus()
	_update_hud(delta)
	_flashlight_rules(delta)
	if global_position.y < -400.0:
		hurt(1000.0, "fell out of the world")


func _move_input() -> Vector2:
	if qa_active:
		return qa_input.limit_length(1.0)
	var v := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_back", "move_forward"))
	# gamepad look
	var lx := Input.get_axis("look_left", "look_right")
	var ly := Input.get_axis("look_up", "look_down")
	if absf(lx) > 0.01 or absf(ly) > 0.01:
		rotate_y(-lx * 0.045)
		look_pitch = clampf(look_pitch - ly * 0.035, deg_to_rad(-88), deg_to_rad(88))
		head.rotation.x = look_pitch
	return v


func _walk(delta: float, dir: Vector3) -> void:
	var sprinting := (Input.is_action_pressed("sprint") or qa_sprint) and not crouching and dir.length() > 0.1 and stamina > 0.2
	var speed := crouch_speed if crouching else (sprint_speed if sprinting else walk_speed)
	if sprinting:
		stamina = maxf(0.0, stamina - delta)
	else:
		stamina = minf(stamina_max, stamina + delta * 0.7)
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump") and not crouching and not qa_active:
		velocity.y = jump_velocity
		stats["jumps"] += 1
	var target := dir * speed
	var a := accel if is_on_floor() else air_accel
	velocity.x = lerpf(velocity.x, target.x, clampf(a * delta, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target.z, clampf(a * delta, 0.0, 1.0))
	var before := global_position
	move_and_slide()
	_try_step_up(dir, speed, delta)
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	stats["distance"] += moved
	if is_on_floor() and moved > 0.0005:
		_step_acc += moved
		var stride := 0.95 if sprinting else (0.55 if crouching else 0.72)
		if _step_acc >= stride:
			_step_acc = 0.0
			_footstep()
		if Settings.get_value("head_bob") and not Settings.get_value("reduce_motion"):
			_bob += moved * (7.5 if sprinting else 8.5)
			head.position.y = lerpf(head.position.y, _eye() + sin(_bob) * 0.035, 0.5)
	else:
		head.position.y = lerpf(head.position.y, _eye(), clampf(delta * 10.0, 0.0, 1.0))


func _eye() -> float:
	return EYE_CROUCH if crouching else EYE_STAND


## Small ledges/curbs: try to lift over obstacles up to step_height.
func _try_step_up(dir: Vector3, speed: float, delta: float) -> void:
	if not is_on_floor() or dir.length() < 0.1 or not is_on_wall():
		return
	var motion := dir.normalized() * maxf(speed * delta, 0.05)
	var up := Vector3.UP * step_height
	var xf := global_transform
	if test_move(xf, up):
		return
	xf.origin += up
	if test_move(xf, motion):
		return
	xf.origin += motion
	var col := KinematicCollision3D.new()
	if test_move(xf, -up, col):
		var n := col.get_normal()
		if n.y > 0.7:
			global_position = xf.origin - up + Vector3.UP * (up.length() - col.get_travel().length()) * 0.0
			global_position = xf.origin + col.get_travel()


func _handle_crouch(_delta: float) -> void:
	var want := Input.is_action_pressed("crouch") and not swimming
	if want and not crouching:
		crouching = true
		capsule.height = HEIGHT_CROUCH
		shape.position.y = HEIGHT_CROUCH * 0.5
	elif not want and crouching:
		# stand only if there is headroom
		var xf := global_transform
		var q := PhysicsShapeQueryParameters3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = RADIUS * 0.95
		cap.height = HEIGHT_STAND
		q.shape = cap
		q.transform = Transform3D(Basis(), xf.origin + Vector3.UP * (HEIGHT_STAND * 0.5 + 0.02))
		q.collision_mask = 1
		if get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty():
			crouching = false
			capsule.height = HEIGHT_STAND
			shape.position.y = HEIGHT_STAND * 0.5


func _update_ladder() -> void:
	var probe := global_position + Vector3.UP * 0.9
	var was := on_ladder
	on_ladder = false
	for l in get_tree().get_nodes_in_group("ladder"):
		if (l as LadderVolume).contains(probe):
			on_ladder = true
			break
	if on_ladder and not was:
		velocity = Vector3.ZERO


func _update_water() -> void:
	var feet := global_position + Vector3.UP * 0.9
	var eye := camera.global_position
	_water = null
	for w in get_tree().get_nodes_in_group("water"):
		var wv := w as WaterVolume
		if wv and wv.contains(feet):
			_water = wv
			break
	swimming = _water != null
	var under := false
	if _water:
		under = _water.contains(eye)
	if under != head_under:
		head_under = under
		Overlay.set_underwater(under, _water)
		if under:
			Overlay.subtitle("[muffled water]", 1.5)
	if not head_under:
		oxygen = minf(oxygen_seconds, oxygen + get_physics_process_delta_time() * 6.0)


func _swim(delta: float, input: Vector2) -> void:
	var look := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var wish := (look * input.y + right * input.x)
	if Input.is_action_pressed("jump"):
		wish += Vector3.UP
	if Input.is_action_pressed("crouch"):
		wish += Vector3.DOWN
	if wish.length() > 1.0:
		wish = wish.normalized()
	var speed := swim_speed * (1.35 if Input.is_action_pressed("sprint") else 1.0)
	velocity = velocity.lerp(wish * speed + _water.current, clampf(delta * 3.0, 0.0, 1.0))
	# buoyancy: drift toward floating with the eyes just above the surface
	var depth := _water.surface_y - (global_position.y + 1.45)
	if wish.y == 0.0 and input.length() < 0.1:
		velocity.y = lerpf(velocity.y, clampf(depth * 1.5, -0.6, 0.8), clampf(delta * 2.0, 0.0, 1.0))
	if depth < -0.3 and velocity.y > 0.0:
		velocity.y = minf(velocity.y, 0.5)
	move_and_slide()
	if head_under:
		oxygen -= delta
		if oxygen <= 0.0:
			hurt(delta * 12.0, "drowned")
	_step_acc += velocity.length() * delta
	if _step_acc > 1.6:
		_step_acc = 0.0
		feet_audio.stream = AudioSynth.get_stream("footstep", {"surface": "water", "variant": _step_variant % 3})
		_step_variant += 1
		feet_audio.play()


func _climb(_delta: float, input: Vector2) -> void:
	# forward/back climbs; strafing still allowed so the top can be stepped off
	var right := global_transform.basis.x
	velocity = Vector3(0, input.y * 2.2, 0) + right * input.x * 1.2
	if input.y > 0.1:
		velocity += -global_transform.basis.z * 0.35
	if Input.is_action_just_pressed("jump") and not qa_active:
		velocity += global_transform.basis.z * 2.0 + Vector3.UP * 1.0
		on_ladder = false
	move_and_slide()


func _footstep() -> void:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var surf := GeoKit.surface_at(hit)
	feet_audio.stream = AudioSynth.get_stream("footstep", {"surface": surf, "variant": _step_variant % 4})
	feet_audio.pitch_scale = randf_range(0.92, 1.08)
	_step_variant += 1
	feet_audio.play()


func _update_focus() -> void:
	var f: Object = null
	if ray.is_colliding():
		var c := ray.get_collider()
		if c and c.has_method("get_prompt") and c.get_prompt() != "":
			f = c
	_focus = f


func _update_hud(_delta: float) -> void:
	var prompt := ""
	if _focus:
		prompt = _focus.get_prompt()
	elif not _zone_prompts.is_empty():
		prompt = _zone_prompts.values()[0]
	if prompt != "":
		prompt = "[%s] %s" % [Settings.binding_text("interact"), prompt]
	Overlay.set_prompt(prompt)
	Overlay.set_bars(stamina / stamina_max, oxygen / oxygen_seconds if head_under or oxygen < oxygen_seconds - 0.1 else -1.0, _noclip_p)
	_noclip_p = maxf(0.0, _noclip_p - 0.02)


func _flashlight_rules(delta: float) -> void:
	if flashlight_policy == "fails" and flashlight.visible:
		_flashlight_timer -= delta
		flashlight.light_energy = 2.2 * (0.4 + 0.6 * absf(sin(Time.get_ticks_msec() * 0.02)))
		if _flashlight_timer <= 0.0:
			flashlight.visible = false
			Overlay.subtitle("[the light dies]", 2.0)


## Sourced no-clip: is the player actively pushing into the given volume?
func pushing_into(center: Vector3, box_size: Vector3) -> bool:
	if _push_dir.length() < 0.5:
		return false
	var to_c := center - global_position
	to_c.y = 0.0
	var toward := to_c.normalized().dot(_push_dir.normalized()) > 0.55
	return toward and (is_on_wall() or to_c.length() < maxf(box_size.x, box_size.z) * 0.6)


func noclip_progress(p: float) -> void:
	_noclip_p = clampf(p, 0.0, 1.0)


func hurt(amount: float, cause: String) -> void:
	if dead:
		return
	health -= amount
	if health <= 0.0:
		dead = true
		died.emit(cause)
		Overlay.on_player_died(cause)


func heal(amount: float) -> void:
	health = minf(100.0, health + amount)


# ------------------------------------------------------- developer flycam

func toggle_flycam() -> void:
	if not SessionState.is_developer():
		Overlay.toast("F7 flycam is developer-only. Open the F3 browser to enter developer mode.", 3.5)
		return
	if flycam == null:
		flycam = Camera3D.new()
		flycam.set_script(load("res://core/player/FlyCam.gd"))
		get_parent().add_child(flycam)
		flycam.global_transform = camera.global_transform
		flycam.fov = camera.fov
		flycam.far = camera.far
		flycam.current = true
		frozen = true
		velocity = Vector3.ZERO
		Overlay.toast("FLYCAM (developer): WASD + mouse, Space/Ctrl up/down, Shift fast. F7 returns to the player's safe position.", 4.0)
	else:
		flycam.queue_free()
		flycam = null
		camera.current = true
		frozen = false
		Overlay.toast("Returned to the player's last safe position.", 2.0)


func facing_yaw() -> float:
	return rotation.y
