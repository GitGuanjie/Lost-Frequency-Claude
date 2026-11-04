class_name LevelBase
extends Node3D
## Contract for every level scene. Subclasses override build() and may override
## level_process(). The base handles deterministic seeding, environment, the
## player, safe spawning, manifest-declared exits, QA metadata and checkpoints.
## Exits are only created through add_exit(), which refuses edges that the
## level manifest (levels/<SID>/level.json) does not declare.

@export var stable_id := ""

var rng := RandomNumberGenerator.new()
var level_seed := 0
var player: Player
var world_env: WorldEnvironment
var environment: Environment
var sun: DirectionalLight3D
var lights: LightPool
var sound: Soundscape
var manifest: Dictionary = {}
var arrivals: Dictionary = {}          # tag -> Transform3D
var exits: Array = []
var qa_shots: Array = []               # [{name, pos, target}] curated camera stills
var qa_routes: Array = []              # [{edge, waypoints:[Vector3], note}] bot traversal fixtures
var landmarks: Array = []              # [{name, pos}]
var rules := {
	"gravity": 9.8, "flashlight": "allowed", "walk_speed": 3.1, "sprint_speed": 5.3,
	"jump_velocity": 4.3, "oxygen_seconds": 40.0, "view_distance": 400.0,
	"reverb_room": 0.45, "reverb_wet": 0.18,
}
var built := false
var build_ms := 0
var spawn_report: Dictionary = {}


func _ready() -> void:
	if stable_id == "":
		stable_id = SessionState.current_level
	SessionState.current_level = stable_id
	manifest = LevelRegistry.get_entry(stable_id).get("impl", {})
	level_seed = SessionState.seed_for(stable_id)
	rng.seed = level_seed
	var t0 := Time.get_ticks_msec()
	Overlay.reset_screen_effects()
	_make_env_defaults()
	lights = LightPool.new()
	lights.name = "LightPool"
	add_child(lights)
	sound = Soundscape.new()
	sound.name = "Soundscape"
	add_child(sound)
	build()
	build_ms = Time.get_ticks_msec() - t0
	Settings.set_reverb(rules["reverb_room"], rules["reverb_wet"])
	_spawn_player()
	# let physics register the static world before validating the spawn
	await get_tree().physics_frame
	await get_tree().physics_frame
	_validate_spawn()
	built = true
	SessionState.in_gameplay = true
	on_player_ready()
	if not SessionState.is_qa():
		SessionState.capture_mouse()
		var e := LevelRegistry.get_entry(stable_id)
		Overlay.level_title(LevelRegistry.display_name(stable_id), str(e.get("survival_class", "")))
	TransitionService.notify_level_ready(stable_id)


## Override: create geometry, lights, audio, exits, arrivals, notes.
func build() -> void:
	pass


## Override: called once the player is placed.
func on_player_ready() -> void:
	pass


## Override for per-frame level mechanics.
func level_process(_delta: float) -> void:
	pass


func _process(delta: float) -> void:
	if built:
		level_process(delta)


# --------------------------------------------------------------- environment

func _make_env_defaults() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = Settings.quality() >= 1
	environment.glow_intensity = 0.35
	environment.glow_bloom = 0.05
	environment.glow_hdr_threshold = 1.1
	environment.ssao_enabled = Settings.quality() >= 2
	environment.ssao_radius = 1.2
	environment.ssao_intensity = 1.6
	environment.fog_enabled = false
	world_env.environment = environment
	add_child(world_env)


## Convenience: indoor fog + ambient.
func indoor_env(ambient: Color, ambient_energy: float, fog_color: Color, fog_density: float) -> void:
	environment.ambient_light_color = ambient
	environment.ambient_light_energy = ambient_energy
	environment.fog_enabled = fog_density > 0.0
	environment.fog_light_color = fog_color
	environment.fog_density = fog_density
	environment.fog_sky_affect = 0.0


## Convenience: sky + sun/moon for exterior levels.
func outdoor_env(sky_top: Color, sky_horizon: Color, ground: Color, sun_dir_deg: Vector2, sun_color: Color, sun_energy: float, fog_color: Color, fog_density: float) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = sky_top
	sky_mat.sky_horizon_color = sky_horizon
	sky_mat.ground_horizon_color = sky_horizon
	sky_mat.ground_bottom_color = ground
	sky_mat.sun_angle_max = 8.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.6
	environment.fog_enabled = fog_density > 0.0
	environment.fog_light_color = fog_color
	environment.fog_density = fog_density
	environment.fog_sky_affect = 0.6
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-sun_dir_deg.x, sun_dir_deg.y, 0)
	sun.light_color = sun_color
	sun.light_energy = sun_energy
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)


func kit(kit_name: String = "Geo") -> GeoKit:
	return GeoKit.new(self, kit_name)


# --------------------------------------------------------------- arrivals

func add_arrival(tag: String, pos: Vector3, yaw_deg: float = 0.0) -> void:
	arrivals[tag] = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), pos)


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.apply_rules(rules)
	var tag := TransitionService.pending_arrival
	var xf: Transform3D = arrivals.get(tag, arrivals.get("start", Transform3D(Basis(), Vector3(0, 0.1, 0))))
	spawn_report = {"requested_arrival": tag, "used_arrival": tag if arrivals.has(tag) else "start"}
	var cp: Dictionary = TransitionService.pending_restore
	if cp.get("level", "") == stable_id and cp.get("pos") is Array and (cp["pos"] as Array).size() == 3:
		var p: Array = cp["pos"]
		xf = Transform3D(Basis(Vector3.UP, float(cp.get("yaw", 0.0))), Vector3(p[0], p[1], p[2]))
		spawn_report["used_arrival"] = "checkpoint_position"
	player.global_transform = Transform3D(Basis(Vector3.UP, xf.basis.get_euler().y), xf.origin)


## Ensure the player stands on a floor in free space; search nearby otherwise.
func _validate_spawn() -> void:
	var space := get_world_3d().direct_space_state
	var origin := player.global_position
	var candidates: Array = [Vector3.ZERO]
	for r in [0.6, 1.2, 2.0, 3.0, 4.5]:
		for k in 8:
			var a := TAU * k / 8.0
			candidates.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for off in candidates:
		var p: Vector3 = origin + off
		var down := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 3.0, 1)
		var hit := space.intersect_ray(down)
		var in_water := false
		for w in get_tree().get_nodes_in_group("water"):
			if (w as WaterVolume).contains(p + Vector3.UP * 0.5):
				in_water = true
		if hit.is_empty() and not in_water:
			continue
		var feet: Vector3 = (hit["position"] + Vector3.UP * 0.03) if not hit.is_empty() else p
		var q := PhysicsShapeQueryParameters3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = Player.RADIUS
		cap.height = Player.HEIGHT_STAND
		q.shape = cap
		q.transform = Transform3D(Basis(), feet + Vector3.UP * (Player.HEIGHT_STAND * 0.5 + 0.02))
		q.collision_mask = 1
		if space.intersect_shape(q, 1).is_empty():
			player.global_position = feet
			spawn_report["spawn_ok"] = true
			spawn_report["offset"] = off.length()
			spawn_report["floor_hit"] = not hit.is_empty()
			return
	spawn_report["spawn_ok"] = false
	push_warning("%s: no clear spawn near %s" % [stable_id, origin])


# ------------------------------------------------------------------ exits

## Create a physical exit. The edge must exist in the manifest's "exits".
func add_exit(edge_id: String, kind: String, center: Vector3, size: Vector3, prompt: String = "") -> ExitTrigger:
	return make_exit(edge_id, kind, center, size, prompt, self)


## Same as add_exit but parented elsewhere (e.g. inside a streamed chunk).
func make_exit(edge_id: String, kind: String, center: Vector3, size: Vector3, prompt: String, parent: Node) -> ExitTrigger:
	var declared := false
	var tag := "SOURCE"
	for x in manifest.get("exits", []):
		if x.get("id", "") == edge_id:
			declared = true
			tag = x.get("basis", "SOURCE")
	if not declared:
		push_error("%s: exit %s is not declared in level.json — refusing to create it" % [stable_id, edge_id])
		return null
	var t := ExitTrigger.new()
	t.name = "Exit_" + edge_id.replace(">", "_to_").replace(":", "_").replace("#", "_")
	parent.add_child(t)
	t.setup(edge_id, kind, center, size, prompt)
	t.tag_label = tag
	exits.append(t)
	return t


func add_note(id: String, title: String, text: String, center: Vector3, size: Vector3 = Vector3(0.4, 0.05, 0.3)) -> Interactable:
	var it := Interactable.new()
	add_child(it)
	it.setup(center, size, "Read")
	it.as_note(id, title, text)
	return it


func add_interactable(center: Vector3, size: Vector3, prompt: String, cb: Callable) -> Interactable:
	var it := Interactable.new()
	add_child(it)
	it.setup(center, size, prompt, cb)
	return it


func add_shot(shot_name: String, pos: Vector3, target: Vector3, extra: Dictionary = {}) -> void:
	var d := {"name": shot_name, "pos": pos, "target": target}
	d.merge(extra)
	qa_shots.append(d)


## Curated camera stills for rendered evidence. Levels may override to prepare
## streamed regions (e.g. Level 0 variant zones) before each still.
func qa_capture_plan() -> Array:
	return qa_shots


func add_landmark(lm_name: String, pos: Vector3) -> void:
	landmarks.append({"name": lm_name, "pos": pos})


## Persist a story checkpoint at the player's current position.
func checkpoint(tag: String = "") -> void:
	if player == null:
		return
	SaveService.set_checkpoint(stable_id, tag if tag != "" else "start", player.global_position, player.rotation.y, player.look_pitch)
	if SessionState.is_story():
		SaveService.save_story("checkpoint")


## QA description consumed by tests/qa_runner.gd.
func qa_describe() -> Dictionary:
	var ex: Array = []
	exits = exits.filter(func(t): return is_instance_valid(t))
	for t in exits:
		ex.append({"edge": t.edge_id, "kind": t.kind, "pos": t.global_position, "size": t.size})
	return {"stable_id": stable_id, "seed": level_seed, "build_ms": build_ms, "exits": ex,
		"arrivals": arrivals.keys(), "spawn": spawn_report, "shots": qa_shots, "routes": qa_routes,
		"landmarks": landmarks}
