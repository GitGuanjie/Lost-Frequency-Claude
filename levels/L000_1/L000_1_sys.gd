extends RefCounted
## Level 0.1 runtime systems:
##  - automatic sliding doors (SOURCE: "some of which are perfectly
##    functional"): auto, jammed shut, stuck half open, stuttering
##  - climate (SOURCE: damaged sections show "extreme cold or heat to the point
##    of unsurvivability"): exposure builds inside a hot/cold wing and kills
##  - hallucinations (SOURCE: "visual/auditory hallucinations", as in Level 0)
##  - automatons (SOURCE: "many automatons of various designs"; working ones
##    clean and cook): props only, never hostile, they pause for the player
##  - the radial lift (ADAPTATION) between the Outer Ring and the Inner Gallery
##  - zone environments (gallery haze vs. Level 0 murk at the hull)

const D := preload("res://levels/L000_1/L000_1_dims.gd")

var lvl
var rng := RandomNumberGenerator.new()
var doors: Array = []
var climates: Array = []
var cooks: Array = []
var cleaners: Array = []
var cars: Array = []
var lift := {"state": "idle", "t": 0.0, "from": 0, "to": 1, "moved": false, "phase": 0.0, "rides": 0}
var exposure := 0.0
var climate_here := ""
var zone := ""
var halluc_t := 70.0
var halluc_count := 0
var bleed := 0.0
var _warned := {}
var _hum: AudioStreamPlayer
var _ride: AudioStreamPlayer


func _init(level) -> void:
	lvl = level
	rng.seed = level.level_seed + 41


# ------------------------------------------------------------------ doors

func add_door(parent: Node3D, c: Vector3, ax: Vector3, w: float, h: float, mode: String, _m = null) -> Dictionary:
	var d := {"c": c, "cw": parent.global_transform * c, "ax": ax, "w": w, "mode": mode, "open": 0.0, "target": 0.0, "t": 0.0, "panels": []}
	for s: float in [-1.0, 1.0]:
		var node := Node3D.new()
		node.name = "DoorPanel"
		parent.add_child(node)
		node.basis = Basis(ax, Vector3.UP, ax.cross(Vector3.UP))
		var k := GeoKit.new(node, "Panel")
		k.box(Vector3(0, h * 0.5, 0), Vector3(w * 0.5, h, 0.07), "l01_door")
		k.box(Vector3(-s * (w * 0.25 - 0.03), h * 0.5, 0), Vector3(0.05, h - 0.06, 0.08), "l01_trim", GeoKit.ALL, false)
		k.box(Vector3(0, h * 0.62, 0), Vector3(w * 0.3, 0.06, 0.08), "l01_mullion", GeoKit.ALL, false)
		k.commit()
		d["panels"].append({"node": node, "s": s})
	if mode == "stuck":
		d["open"] = 0.55
		d["target"] = 0.55
	_place(d)
	doors.append(d)
	return d


func _place(d: Dictionary) -> void:
	var ax: Vector3 = d["ax"]
	var w: float = d["w"]
	for p in d["panels"]:
		(p["node"] as Node3D).position = d["c"] + ax * float(p["s"]) * (w * 0.25 + w * 0.5 * float(d["open"]))


func _tick_doors(delta: float, pp: Vector3) -> void:
	for d in doors:
		var mode: String = d["mode"]
		if mode == "jammed" or mode == "stuck":
			continue
		var cw: Vector3 = d["cw"]
		var near := Vector2(pp.x - cw.x, pp.z - cw.z).length() < 2.7 and absf(pp.y - cw.y) < 2.4
		var was: float = d["target"]
		if mode == "auto":
			d["target"] = 1.0 if near else 0.0
		elif mode == "stutter":
			d["t"] = float(d["t"]) - delta
			if not near:
				d["target"] = 0.0
			elif float(d["t"]) <= 0.0:
				d["t"] = rng.randf_range(0.3, 1.3)
				d["target"] = 1.0 if float(d["target"]) < 0.5 else rng.randf_range(0.0, 0.3)
		if mode != "lift" and was < 0.5 and float(d["target"]) >= 0.5 and lvl.player.global_position.distance_to(cw) < 12.0:
			lvl.sound.play_at("wind", {"seconds": 0.7}, cw + Vector3.UP * 2.0, -20.0)
		var sp := 4.5 if mode == "stutter" else 2.4
		var o := move_toward(float(d["open"]), float(d["target"]), delta * sp)
		if o != float(d["open"]):
			d["open"] = o
			_place(d)


# ----------------------------------------------------------------- climate

func add_climate(box: AABB, state: String, center: Vector3) -> void:
	climates.append({"box": box, "state": state})
	if state == "cold":
		lvl.sound.emitter("wind", center, {"seconds": 6.0}, -16.0, 11.0)
	else:
		lvl.sound.emitter("transformer", center, {"base": 48.0}, -18.0, 11.0)
		lvl.sound.emitter("crackle", center + Vector3(3.0, 0.5, 2.0), {}, -22.0, 8.0)


func climate_at(p: Vector3) -> String:
	for c in climates:
		if (c["box"] as AABB).has_point(p + Vector3.UP * 0.9):
			return c["state"]
	return ""


func _tick_climate(delta: float, p: Vector3) -> void:
	climate_here = climate_at(p)
	if climate_here != "":
		exposure = minf(1.0, exposure + delta * 0.12)
		if not _warned.has(climate_here):
			_warned[climate_here] = true
			Overlay.subtitle("[the air bites; frost on every surface]" if climate_here == "cold" else "[heat pours off the walls; the air ripples]", 3.5)
	else:
		exposure = maxf(0.0, exposure - delta * 0.18)
	var hot := climate_here == "hot" or (climate_here == "" and _last_kind == "hot")
	if climate_here != "":
		_last_kind = climate_here
	Overlay.set_screen_effect("red_tint", exposure * 0.32 if hot else 0.0)
	Overlay.set_screen_effect("desaturate", 0.0 if hot else exposure * 0.75)
	Overlay.set_screen_effect("vignette", 0.25 + exposure * 0.55)
	if exposure > 0.35 and climate_here != "" and not lvl.player.dead:
		lvl.player.hurt(delta * 15.0 * (exposure - 0.35) / 0.65, "The cold in that wing was beyond surviving" if climate_here == "cold" else "The heat in that wing was beyond surviving")


var _last_kind := ""


# ---------------------------------------------------------- hallucinations

## kind: 0 footsteps behind, 1 a door that never moved, 2 Level 0 bleeds
## through (buzz + yellow light), 3 a calm automated voice far away.
func hallucinate(kind: int) -> void:
	halluc_count += 1
	var p: Vector3 = lvl.player.global_position
	var back: Vector3 = lvl.player.global_transform.basis.z
	match kind:
		0:
			lvl.sound.play_at("footstep", {"surface": "metal", "variant": 1}, p + back * 3.5, -10.0, "[footsteps close behind you; no one is there]")
			for i in 2:
				lvl.get_tree().create_timer(0.5 * (i + 1)).timeout.connect(_echo_step.bind(i + 2, back))
		1:
			lvl.sound.play_at("wind", {"seconds": 0.7}, p + back.rotated(Vector3.UP, 1.2) * 6.0, -12.0, "[a door hisses open nearby; none has moved]")
		2:
			bleed = 1.8
			Overlay.subtitle("[for a moment: buzzing tubes and the smell of damp carpet]", 2.5)
		3:
			lvl.sound.play_at("pad", {"root": 196.0, "chord": [0, 4, 7], "bright": 0.3, "seconds": 2.0}, p + back * 9.0, -16.0, "[a calm automated voice, too faint to make out]")


func _echo_step(v: int, back: Vector3) -> void:
	if is_instance_valid(lvl.player):
		lvl.sound.play_at("footstep", {"surface": "metal", "variant": v}, lvl.player.global_position + back * 3.2, -11.0)


func _tick_halluc(delta: float) -> void:
	halluc_t -= delta
	if halluc_t <= 0.0:
		halluc_t = rng.randf_range(55.0, 130.0)
		hallucinate(rng.randi() % 4)
	if bleed > 0.0:
		bleed = maxf(0.0, bleed - delta)
	if _hum:
		_hum.volume_db = -60.0 + 46.0 * clampf(bleed, 0.0, 1.0)


# ------------------------------------------------------------- environment

func setup_audio() -> void:
	_hum = lvl.sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.4}, -60.0)
	_ride = lvl.sound.bed("transformer", {"base": 38.0}, -80.0)


func apply_zone(z: String) -> void:
	zone = z
	var env: Environment = lvl.environment
	if z == "gallery":
		env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		env.fog_density = 0.0006
		env.fog_light_color = Color(0.006, 0.007, 0.01)
		env.fog_light_energy = 1.0
		env.fog_height_density = 0.0
		env.ambient_light_color = Color(0.62, 0.68, 0.78)
		env.ambient_light_energy = 0.32
		env.background_color = Color(0.006, 0.007, 0.01)
	else:
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_density = 1.0
		env.fog_depth_begin = 25.0
		env.fog_depth_end = 220.0
		env.fog_depth_curve = 1.3
		env.fog_light_color = Color(0.03, 0.024, 0.01)
		env.fog_light_energy = 1.0
		env.ambient_light_color = Color(0.8, 0.74, 0.55)
		env.ambient_light_energy = 0.08
		env.background_color = Color(0.03, 0.024, 0.01)
	env.fog_enabled = true


func _tick_env() -> void:
	var z := "hull" if lvl.player.global_position.y > 400.0 else "gallery"
	if z != zone:
		apply_zone(z)
		lvl.stream_exits(z)
	if bleed > 0.0 or _bleeding:
		var k := clampf(bleed, 0.0, 1.0)
		var env: Environment = lvl.environment
		var base := Color(0.62, 0.68, 0.78) if zone == "gallery" else Color(0.8, 0.74, 0.55)
		env.ambient_light_color = base.lerp(Color(1.0, 0.86, 0.42), k)
		env.ambient_light_energy = (0.32 if zone == "gallery" else 0.08) + 0.5 * k
		_bleeding = bleed > 0.0


var _bleeding := false


# ------------------------------------------------------------------- lift

## The car's frame: door plane at local z=0, cabin toward local -z.
func build_car(parent: Node3D, xf: Transform3D) -> void:
	var node := Node3D.new()
	node.name = "LiftCar%d" % cars.size()
	node.transform = xf
	parent.add_child(node)
	var k := GeoKit.new(node, "Car")
	k.slab(-1.3, -2.6, 1.3, 0.0, 0.0, 0.25, "l01_floor_dark")
	k.wall(Vector3(-1.3, 0, 0), Vector3(-1.3, 0, -2.6), 2.6, 0.1, "l01_car")
	k.wall(Vector3(1.3, 0, -2.6), Vector3(1.3, 0, 0), 2.6, 0.1, "l01_car")
	k.wall(Vector3(-1.3, 0, -2.6), Vector3(1.3, 0, -2.6), 2.6, 0.1, "l01_car", [{"at": 1.3, "w": 0.5, "h": 1.7, "sill": 0.55}])
	k.slab(-1.35, -2.65, 1.35, 0.05, 2.85, 0.25, "l01_slab_metal")
	k.panel(Vector3(0, 2.59, -1.3), 1.6, 1.6, "l01_panel", 7.0)
	k.box(Vector3(1.24, 1.2, -0.7), Vector3(0.04, 0.5, 0.3), "l01_screen", GeoKit.ALL, false)
	k.box(Vector3(1.22, 1.05, -0.7), Vector3(0.03, 0.06, 0.06), "l01_led_amber", GeoKit.ALL, false)
	k.box(Vector3(0, 0.0, -2.9), Vector3(1.4, 6.0, 0.05), "l01_slab_metal", GeoKit.ALL, false)
	k.commit()
	var g := D.Quads.new()
	g.q(Vector3(-0.25, 0.55, -2.6), Vector3(0.25, 0.55, -2.6), Vector3(0.25, 2.25, -2.6), Vector3(-0.25, 2.25, -2.6), Vector3.BACK, "l01_glass")
	g.commit(node, "Slit")
	var bands := Node3D.new()
	bands.name = "Bands"
	bands.position = Vector3(0, 0, -2.84)
	node.add_child(bands)
	for i in 7:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.2, 0.07, 0.02)
		mi.mesh = bm
		mi.material_override = MatLib.get_mat("l01_panel")
		mi.position = Vector3(0, 0.6 * i - 0.6, 0)
		bands.add_child(mi)
	var door := add_door(node, Vector3(0, 0, 0.05), Vector3.RIGHT, 1.3, 2.3, "lift")
	var idx := cars.size()
	cars.append({"node": node, "door": door, "bands": bands})
	lvl.add_interactable(node.global_transform * Vector3(1.2, 1.2, -0.7), Vector3(0.3, 0.6, 0.5), "Press the lift call plate", func(_p): ride_from(idx))


func in_car(i: int, p: Vector3) -> bool:
	var lp: Vector3 = (cars[i]["node"] as Node3D).global_transform.affine_inverse() * p
	return absf(lp.x) < 1.25 and lp.z < -0.15 and lp.z > -2.55 and absf(lp.y) < 1.0


func ride_from(i: int) -> void:
	if lift["state"] != "idle":
		return
	if not in_car(i, lvl.player.global_position):
		Overlay.toast("The plate lights up, then waits. Step into the car first.", 3.0)
		return
	lift["state"] = "closing"
	lift["t"] = 0.0
	lift["from"] = i
	lift["to"] = 1 - i
	lift["moved"] = false
	lvl.sound.play_at("ui", {}, lvl.player.global_position + Vector3.UP, -12.0)


func _tick_lift(delta: float, pp: Vector3) -> void:
	var st: String = lift["state"]
	lift["t"] = float(lift["t"]) + delta
	var t: float = lift["t"]
	for i in cars.size():
		var d: Dictionary = cars[i]["door"]
		if st == "idle":
			d["target"] = 1.0 if (d["cw"] as Vector3).distance_to(pp) < 3.4 else 0.0
		elif st == "arriving" and i == int(lift["to"]):
			d["target"] = 1.0
		else:
			d["target"] = 0.0
	match st:
		"closing":
			if t > 1.0:
				lift["state"] = "moving"
				lift["t"] = 0.0
				if not lvl.player.dead:
					Overlay.subtitle("[the radial lift hums into motion; deck lights stream past the slit]", 3.5)
		"moving":
			var sp := sin(clampf(t / 7.0, 0.0, 1.0) * PI)
			lift["phase"] = float(lift["phase"]) + delta * sp * 14.0
			_ride.volume_db = -40.0 + 26.0 * sp
			if t > 3.5 and not lift["moved"]:
				_teleport(int(lift["from"]), int(lift["to"]))
			if t > 7.0:
				lift["state"] = "arriving"
				lift["t"] = 0.0
				_ride.volume_db = -80.0
		"arriving":
			if t > 1.2:
				lift["state"] = "idle"
				lift["rides"] = int(lift["rides"]) + 1
				lvl.on_lift_arrived(int(lift["to"]))
	for c in cars:
		var ph := fposmod(float(lift["phase"]), 0.6)
		(c["bands"] as Node3D).position.y = -ph


func _teleport(a: int, b: int) -> void:
	lift["moved"] = true
	var xa: Transform3D = (cars[a]["node"] as Node3D).global_transform
	var xb: Transform3D = (cars[b]["node"] as Node3D).global_transform
	var m := xb * xa.affine_inverse()
	var p: Player = lvl.player
	p.global_transform = m * p.global_transform
	p.velocity = m.basis * p.velocity
	_tick_env()


# -------------------------------------------------------------- automatons

func _mesh(parent: Node3D, mesh: Mesh, mat: String, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = MatLib.get_mat(mat)
	mi.position = pos
	parent.add_child(mi)
	return mi


## The heptapedal cleaning bot of the vignette: a low dome on seven legs.
func add_cleaner(route: Array) -> void:
	var root := Node3D.new()
	root.name = "CleaningBot"
	lvl.add_child(root)
	var dome := CylinderMesh.new()
	dome.top_radius = 0.26
	dome.bottom_radius = 0.42
	dome.height = 0.26
	_mesh(root, dome, "l01_bot", Vector3(0, 0.42, 0))
	var ring := CylinderMesh.new()
	ring.top_radius = 0.27
	ring.bottom_radius = 0.27
	ring.height = 0.04
	_mesh(root, ring, "l01_led_cyan", Vector3(0, 0.52, 0))
	var brush := CylinderMesh.new()
	brush.top_radius = 0.3
	brush.bottom_radius = 0.3
	brush.height = 0.05
	var br := _mesh(root, brush, "l01_fabric", Vector3(0, 0.05, 0))
	var legs: Array = []
	for i in 7:
		var piv := Node3D.new()
		piv.rotation.y = TAU * i / 7.0
		piv.position = Vector3(0, 0.36, 0)
		root.add_child(piv)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.045, 0.045, 0.5)
		var leg := _mesh(piv, bm, "l01_slab_metal", Vector3(0, -0.12, -0.42))
		leg.rotation.x = 0.55
		legs.append(piv)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.5
	cyl.height = 0.55
	cs.shape = cyl
	cs.position.y = 0.28
	body.add_child(cs)
	root.add_child(body)
	var motor := AudioStreamPlayer3D.new()
	motor.stream = AudioSynth.get_stream("transformer", {"base": 90.0})
	motor.volume_db = -24.0
	motor.max_distance = 8.0
	motor.bus = "Ambience"
	motor.autoplay = true
	root.add_child(motor)
	root.position = route[0]
	cleaners.append({"root": root, "legs": legs, "brush": br, "route": route, "i": 1, "t": 0.0, "paused": false})


func _tick_cleaners(delta: float, pp: Vector3) -> void:
	for c in cleaners:
		var root: Node3D = c["root"]
		var pos := root.position
		var goal: Vector3 = c["route"][int(c["i"])]
		var near := Vector2(pp.x - pos.x, pp.z - pos.z).length() < 1.7 and absf(pp.y - pos.y) < 1.5
		c["paused"] = near
		if near:
			var tp := pp - pos
			root.rotation.y = lerp_angle(root.rotation.y, atan2(-tp.x, -tp.z), delta * 3.0)
			continue
		var to := goal - pos
		to.y = 0.0
		if to.length() < 0.15:
			c["i"] = (int(c["i"]) + 1) % (c["route"] as Array).size()
			continue
		root.position = pos + to.normalized() * minf(to.length(), delta * 0.45)
		root.rotation.y = lerp_angle(root.rotation.y, atan2(-to.x, -to.z), delta * 2.5)
		c["t"] = float(c["t"]) + delta * 6.0
		var legs: Array = c["legs"]
		for i in legs.size():
			(legs[i] as Node3D).position.y = 0.36 + 0.03 * maxf(0.0, sin(float(c["t"]) + i * TAU / 7.0 * 3.0))
		(c["brush"] as Node3D).rotation.y += delta * 9.0


## A ceiling cooking arm over a kitchen island; it only moves where it works.
func add_cook_bot(ceiling: Vector3, working: bool) -> void:
	var root := Node3D.new()
	root.name = "CookArm"
	lvl.add_child(root)
	root.position = ceiling
	var col := CylinderMesh.new()
	col.top_radius = 0.07
	col.bottom_radius = 0.07
	col.height = 1.3
	_mesh(root, col, "l01_bot", Vector3(0, -0.65, 0))
	var arm := Node3D.new()
	arm.position = Vector3(0, -1.3, 0)
	root.add_child(arm)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 0.9)
	_mesh(arm, bm, "l01_bot", Vector3(0, 0, -0.45))
	var pan := CylinderMesh.new()
	pan.top_radius = 0.17
	pan.bottom_radius = 0.14
	pan.height = 0.05
	var pm := _mesh(arm, pan, "l01_slab_metal", Vector3(0, -0.12, -0.9))
	var eye := SphereMesh.new()
	eye.radius = 0.06
	eye.height = 0.12
	_mesh(arm, eye, "l01_led_cyan" if working else "l01_plenum", Vector3(0, 0.0, -0.1))
	if not working:
		arm.rotation = Vector3(-0.9, 0.6, 0.2)
	else:
		lvl.sound.emitter("crackle", ceiling + Vector3(0, -2.6, 0), {}, -24.0, 7.0)
	cooks.append({"arm": arm, "pan": pm, "working": working, "t": rng.randf() * 10.0})


func _tick_cooks(delta: float) -> void:
	for c in cooks:
		if not c["working"]:
			continue
		c["t"] = float(c["t"]) + delta
		var t: float = c["t"]
		(c["arm"] as Node3D).rotation.y = sin(t * 0.7) * 0.9
		(c["pan"] as Node3D).rotation.x = maxf(0.0, sin(t * 2.3)) * 0.5


## A dead automaton slumped where it stopped.
func add_broken_bot(pos: Vector3, yaw: float, parent: Node3D = null) -> void:
	var node := Node3D.new()
	node.name = "DeadAutomaton"
	(parent if parent else lvl).add_child(node)
	node.position = pos
	node.rotation.y = yaw
	var k := GeoKit.new(node, "Bot")
	k.box(Vector3(0, 0.35, 0), Vector3(0.55, 0.7, 0.4), "l01_bot")
	var lean := Basis(Vector3.RIGHT, 0.7)
	k.box_xf(Transform3D(lean, Vector3(0, 0.82, 0.18)), Vector3(0.3, 0.26, 0.3), "l01_bot", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, 1.2), Vector3(0.45, 0.25, 0.1)), Vector3(0.12, 0.6, 0.12), "l01_slab_metal", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, -1.4), Vector3(-0.5, 0.12, 0.0)), Vector3(0.12, 0.6, 0.12), "l01_slab_metal", GeoKit.ALL, false)
	k.box(Vector3(0, 0.84, 0.36), Vector3(0.16, 0.05, 0.02), "l01_plenum", GeoKit.ALL, false)
	_wire_tuft(k, Vector3(0.2, 0.7, -0.1))
	k.commit()


func _wire_tuft(k: GeoKit, p: Vector3) -> void:
	for i in 3:
		var b := Basis(Vector3.UP, i * 2.1) * Basis(Vector3.RIGHT, 0.6 + 0.2 * i)
		k.box_xf(Transform3D(b, p + b.y * 0.15), Vector3(0.02, 0.3, 0.02), "l01_wire_red" if i == 1 else "l01_wire", GeoKit.ALL, false)


func spark(pos: Vector3) -> void:
	lvl.sound.emitter("crackle", pos, {}, -20.0, 9.0)


# ------------------------------------------------------------------- tick

func tick(delta: float) -> void:
	var p: Player = lvl.player
	if p == null:
		return
	var pp := p.global_position
	_tick_env()
	_tick_doors(delta, pp)
	_tick_lift(delta, pp)
	_tick_climate(delta, pp)
	_tick_halluc(delta)
	_tick_cleaners(delta, pp)
	_tick_cooks(delta)
