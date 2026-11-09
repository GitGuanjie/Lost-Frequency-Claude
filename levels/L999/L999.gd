extends LevelBase
## Level 999 (Backrooms Wikidot rev 30, accessed 2026-11-04; cite: Greggita
## Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L999.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: a floating tropical island deep in a starry, space-like void; a
##   desaturating aura makes all matter greyscale; cold (13-16 C). Smoke-grey
##   fine sand at the beaches drifts outward and holds in the void past the
##   perimeter, with rocks floating motionless beyond reach. Grey palms and much
##   darker rocks jut from the sand: tips of the island's unseen underside, a
##   huge irregular upturned rocky pyramid, so they cannot be moved. Inland the
##   sand turns to coarse, still dirt with no grass; a thick forest of the oldest
##   trees towers toward the stars, hopelessly flat, never swaying despite the
##   constant ethereal wind; a constant semi-illuminant aura keeps the brightness
##   the same under the canopy. Near the epicentre, sparse dormant houses of
##   concrete, glass, wood and stone rest in the ground, unconnected by paths;
##   their insides are dark, dank and rectangular: empty beds, closed blinds,
##   sparse furniture. Nothing ever changes. The only exit: a single trapdoor
##   among the benches at the epicentre, back to the echoing halls.
## SPACE: one island ~240 m across (radius 104-142 m), flat at y 0; beach band
##   ~20 m; forest of ~600 procedural old trees and ~70 palms (no sway, no
##   shadows: the canopy never dims the aura); four houses 34-57 m from the
##   centre (two walkable heights: the wooden house's upper storey, the glass
##   house's raised sleeping platform); the underside visible from the rim; a
##   ring of benches and the trapdoor at the exact centre.
## SIGNATURE MECHANIC (stateful): "the ultimate constant". On arrival the
##   aura drains all colour; time spent here accumulates as bleaching (saved),
##   and after ten minutes in total the colour never comes back on arrival.
##   Every attempt to change the island (push a rock, shake a tree, open the
##   blinds, sit on a bed, scoop the sand, move a bench) does nothing and is
##   counted; when all have failed the island gives you nothing. Walking past
##   the rim, the void holds you as it holds the sand (soft limit, ADAPTATION).
## ABSENT (canon traps): entities, items, notes, colour, hills, sway, change.

const World := preload("res://levels/L999/L999_world.gd")
const Flora := preload("res://levels/L999/L999_flora.gd")
const Houses := preload("res://levels/L999/L999_houses.gd")
const EXIT_ID := "L999>EXT#1"
const START_A := 3.05
const BLEACH_LIMIT := 600.0
const HOLD := 6.0

var world
var flora
var houses
var start := Vector3.ZERO
var tried := {}
var told := {}
var drain_t := -1.0
var bleach := 0.0
var bleach_t := 0.0
var trunk_spots: Array = []
var trapdoor: ExitTrigger
var _base_walk := 3.1


func build() -> void:
	rules["view_distance"] = 1200.0
	rules["reverb_room"] = 0.05
	rules["reverb_wet"] = 0.03
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -600.0
	_environment()
	World.materials()
	Houses.materials()
	world = World.new(self)
	lights.setup(2, 0)
	var land := Node3D.new()
	land.name = "Island"
	add_child(land)
	world.top(land)
	world.underside(land)
	var col := kit("IslandCollision")
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 175.0
	cyl.height = 2.0
	cs.shape = cyl
	cs.position = Vector3(0, -1.0, 0)
	cs.set_meta("surface", "sand")
	col.body.add_child(cs)
	world.beach_crags(land, col)
	world.void_drift(land)
	var hk := kit("Houses")
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	houses = Houses.new(self, hk, props)
	houses.build_all()
	var benches: Array = houses.epicentre()
	hk.commit()
	_plant(land, col)
	world.soil_stones(land, func(p: Vector3) -> bool: return _blocked(p, 0.5))
	_beach_rocks(props)
	col.commit()
	var a := START_A
	start = Vector3(cos(a), 0, sin(a)) * (World.rad(a) - 9.0) + Vector3(0, 0.05, 0)
	var to_c := -start.normalized()
	var yaw := rad_to_deg(atan2(-to_c.x, -to_c.z)) - 38.0
	add_arrival("start", start, yaw)
	add_arrival("from_EXT", start, yaw)
	trapdoor = add_exit(EXIT_ID, "interact", Vector3(0, 0.9, 0), Vector3(2.2, 1.8, 2.2), "Open the trapdoor among the benches")
	_attempts(benches)
	_sounds()
	add_landmark("The grey coast and the void", start)
	add_landmark("Dormant houses near the epicentre", Houses.HOUSES[0][1])
	add_landmark("Benches and the single trapdoor (epicentre)", Vector3.ZERO)
	_shots()


func _environment() -> void:
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = World.sky_material()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.62)
	environment.ambient_light_energy = 0.42
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.012, 0.012, 0.012)
	environment.fog_density = 0.0016
	environment.fog_sky_affect = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = false
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.0
	environment.adjustment_contrast = 1.06
	# the aura: one constant, shadowless-under-trees light from above (no sun disc)
	sun = DirectionalLight3D.new()
	sun.name = "Aura"
	sun.rotation_degrees = Vector3(-68.0, 30.0, 0)
	sun.light_color = Color(0.92, 0.92, 0.92)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.light_angular_distance = 6.0
	add_child(sun)


# -------------------------------------------------------------- planting

func _blocked(p: Vector3, margin: float) -> bool:
	if Vector2(p.x, p.z).length() < 11.0 + margin:
		return true
	for f in houses.footprints:
		if Vector2(p.x - f[0].x, p.z - f[0].z).length() < float(f[1]) + margin:
			return true
	return false


func _plant(parent: Node3D, col: GeoKit) -> void:
	flora = Flora.new()
	var r := RandomNumberGenerator.new()
	r.seed = 99940
	var cell := 6.2
	var n := int(150.0 / cell)
	for ix in range(-n, n + 1):
		for iz in range(-n, n + 1):
			var p := Vector3((ix + r.randf_range(0.1, 0.9)) * cell, 0.0, (iz + r.randf_range(0.1, 0.9)) * cell)
			var rd := World.rim_dist(p)
			if rd > -23.0 or _blocked(p, 1.6) or r.randf() > 0.8:
				continue
			if p.distance_to(start) < 5.0:
				continue
			var kind := r.randi_range(0, 3)
			var s := r.randf_range(0.85, 1.22)
			flora.add("old%d" % kind, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.8, 1.45), s)), p))
			_trunk_shape(col, p, (0.42 + kind * 0.07) * s * 1.05)
			if Vector2(p.x, p.z).distance_to(Vector2(start.x, start.z)) < 40.0:
				trunk_spots.append(p)
	# grey palms on the beach, mostly in loose groups
	for g in 34:
		var ga := r.randf() * TAU
		if g == 0:
			ga = START_A + 0.06
		for j in r.randi_range(2, 5):
			var a := ga + r.randf_range(-0.035, 0.035)
			var p := Vector3(cos(a), 0, sin(a)) * (World.rad(a) - r.randf_range(4.0, 20.0))
			if p.distance_to(start) < 4.5:
				continue
			var kind := r.randi_range(0, 2)
			var yaw := atan2(p.z, -p.x) + r.randf_range(-0.9, 0.9)
			var s := r.randf_range(0.85, 1.2)
			flora.add("palm%d" % kind, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p))
			_trunk_shape(col, p, 0.24)
	flora.commit(parent)


func _trunk_shape(col: GeoKit, p: Vector3, radius: float) -> void:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = 6.0
	cs.shape = sh
	cs.position = p + Vector3(0, 3.0, 0)
	cs.set_meta("surface", "wood")
	col.body.add_child(cs)


## A few Poly Haven boulders on the sand and fallen trunks on the dirt, all
## darkened toward the page's "much darker hued rocks".
func _beach_rocks(props: Node3D) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 99950
	var dark := {}
	for i in 9:
		var a := r.randf() * TAU
		var p := Vector3(cos(a), 0, sin(a)) * (World.rad(a) - r.randf_range(3.0, 14.0))
		if p.distance_to(start) < 6.0:
			continue
		var h: Node3D = Props.place(self, props, "ph/boulder_01", p - Vector3(0, 0.25, 0), r.randf() * 360.0, r.randf_range(0.8, 2.0), true)
		_darken(h, dark, 0.45)
	# one close to the arrival, so the first look reads "dark rock, grey sand"
	var nb: Node3D = Props.place(self, props, "ph/boulder_01", start + Vector3(-1.5, -0.3, -5.5), 40.0, 1.6, true)
	_darken(nb, dark, 0.45)
	for i in 7:
		var a := r.randf() * TAU
		var d := r.randf_range(24.0, 80.0)
		var p := Vector3(cos(a) * d, 0.0, sin(a) * d)
		if _blocked(p, 2.0):
			continue
		Props.place(self, props, "ph/dead_tree_trunk", p, r.randf() * 360.0, 0.0, false)


func _darken(n: Node, cache: Dictionary, f: float) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(si)
			if m is BaseMaterial3D:
				if not cache.has(m):
					var d := (m as BaseMaterial3D).duplicate() as BaseMaterial3D
					d.albedo_color = d.albedo_color * Color(f, f, f, 1.0)
					cache[m] = d
				mi.set_surface_override_material(si, cache[m])
	for c in n.get_children():
		_darken(c, cache, f)


# ------------------------------------------------- unchanging interactions

const LINES := {
	"rock": "[the dark rock does not move. It is the tip of something far larger underneath the island.]",
	"tree": "[you push the trunk. Not a leaf stirs, though the wind never stops.]",
	"blinds": "[the blinds will not open. They are closed, and will always be.]",
	"bed": "[the bed is made, and empty. Nobody has slept in it. Nobody will.]",
	"sand": "[the sand slips through your fingers and settles back into exactly the same shape.]",
	"bench": "[the bench will not shift, not even a little.]",
}


func _attempts(benches: Array) -> void:
	var near_crag := Vector3.ZERO
	var best := INF
	for c in world.crags:
		var d := (c[0] as Vector3).distance_to(start)
		if d < best and float(c[1]) > 1.2:
			best = d
			near_crag = c[0]
	add_interactable(near_crag + Vector3(0, 1.0, 0), Vector3(2.4, 2.0, 2.4), "Push the dark rock", _try.bind("rock"))
	if not trunk_spots.is_empty():
		trunk_spots.sort_custom(func(p, q): return (p as Vector3).distance_to(start) < (q as Vector3).distance_to(start))
		add_interactable(trunk_spots[0] + Vector3(0, 1.2, 0), Vector3(1.8, 2.0, 1.8), "Shake the tree", _try.bind("tree"))
	for i in mini(houses.blind_spots.size(), 6):
		add_interactable(houses.blind_spots[i], Vector3(1.2, 1.2, 1.2), "Open the blinds", _try.bind("blinds"))
	for b in houses.bed_spots:
		add_interactable(b, Vector3(1.0, 0.8, 2.0), "Sit on the bed", _try.bind("bed"))
	add_interactable(start + Vector3(2.0, 0.3, 1.0), Vector3(2.0, 0.6, 2.0), "Scoop up the sand", _try.bind("sand"))
	for i in mini(benches.size(), 4):
		add_interactable(benches[i] + Vector3(0, 0.5, 0), Vector3(1.9, 1.0, 1.0), "Move the bench", _try.bind("bench"))


func _try(what: String) -> void:
	tried[what] = int(tried.get(what, 0)) + 1
	SaveService.set_flag(stable_id, "tried_" + what, true)
	Overlay.subtitle(LINES[what], 4.0)
	if tried.size() == LINES.size() and not told.has("nothing"):
		told["nothing"] = true
		await get_tree().create_timer(4.5).timeout
		if is_instance_valid(self):
			Overlay.subtitle("[nothing new learned, nothing to take away, nothing of value. Just the island.]", 5.0)


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	sound.bed("wind", {"seconds": 11.0}, -15.0)
	sound.bed("wind", {"seconds": 7.0}, -24.0)
	sound.bed("pad", {"root": 55.0, "chord": [0, 7, 12, 19, 24], "bright": 0.12, "seconds": 14.0}, -30.0)


# ---------------------------------------------------------------- shots

func _shots() -> void:
	var a := START_A
	var out := Vector3(cos(a), 0, sin(a))
	var tan := Vector3(-sin(a), 0, cos(a))
	var rim := out * World.rad(a)
	var cam := rim - out * 15.0 - tan * 4.0 + Vector3(0, 1.65, 0)
	add_shot("coast_void", cam, cam + tan * 40.0 + out * 30.0 + Vector3(0, -3.5, 0), {"flashlight": false})
	var f := Vector3(-30.0, 0, -62.0)
	add_shot("forest_to_stars", f + Vector3(0, 1.6, 0), f + Vector3(16.0, 9.0, 22.0), {"flashlight": false})
	var hb: Basis = Basis(Vector3.UP, deg_to_rad(Houses.HOUSES[0][2]))
	var ho: Vector3 = Houses.HOUSES[0][1]
	add_shot("house_interior", ho + hb * Vector3(1.0, 1.6, -2.9), ho + hb * Vector3(2.9, 1.0, 2.6), {"flashlight": true})
	add_shot("benches_trapdoor", Vector3(-6.2, 1.7, -3.2), Vector3(1.5, 0.0, 0.8), {"flashlight": false})


# ---------------------------------------------------------------- runtime

func on_player_ready() -> void:
	_base_walk = player.walk_speed
	bleach = float(SaveService.flag(stable_id, "bleach_seconds", 0.0))
	if SessionState.is_qa():
		return
	if bleach < BLEACH_LIMIT:
		environment.adjustment_saturation = 1.0
		drain_t = 0.0
		Overlay.subtitle("[the colour runs out of everything, slowly, like a held breath let go]", 5.0)
	else:
		Overlay.subtitle("[there is no colour left to lose. It did not come back the last time.]", 5.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if drain_t >= 0.0:
		drain_t += delta
		environment.adjustment_saturation = clampf(1.0 - drain_t / 9.0, 0.0, 1.0)
		if drain_t > 9.0:
			drain_t = -1.0
	if SessionState.is_qa():
		return
	bleach += delta
	bleach_t += delta
	if bleach_t > 10.0:
		bleach_t = 0.0
		SaveService.set_flag(stable_id, "bleach_seconds", bleach)
	# past the rim the void holds you, as it holds the sand
	var p := player.global_position
	var d: float = World.rim_dist(p)
	if d > 0.5:
		player.walk_speed = _base_walk * clampf(1.0 - d / HOLD, 0.2, 1.0)
		if not told.has("hold"):
			told["hold"] = true
			Overlay.subtitle("[the void takes your weight the way it takes the sand: gently, and it does not let you drift any further]", 5.0)
		if d > HOLD:
			var a := atan2(p.z, p.x)
			var rr := World.rad(a) + HOLD
			player.global_position = Vector3(cos(a) * rr, p.y, sin(a) * rr)
	elif player.walk_speed != _base_walk:
		player.walk_speed = _base_walk
	if not told.has("centre") and Vector2(p.x, p.z).length() < 9.0:
		told["centre"] = true
		Overlay.subtitle("[benches, facing nothing. Among them, one trapdoor.]", 4.0)


# ---------------------------------------------------------------- QA

func _snapshot() -> Array:
	var out: Array = []
	for n in find_children("*", "Node3D", true, false):
		if n is Player or (player and player.is_ancestor_of(n)) or n is Camera3D or n is Light3D or n is AudioStreamPlayer3D:
			continue
		out.append((n as Node3D).global_transform)
	return out


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	out.append({"what": "one exit: the trapdoor at the epicentre", "ok": exits.size() == 1 and is_instance_valid(trapdoor) and Vector2(trapdoor.global_position.x, trapdoor.global_position.z).length() < 0.1})
	out.append({"what": "greyscale aura (saturation 0)", "ok": environment.adjustment_saturation == 0.0})
	# flat: floor height identical across the island
	var flat := true
	for q in [Vector3(3, 0, 26), Vector3(-80, 0, 10), Vector3(60, 0, -60), Vector3(20, 0, 95), start]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3(0, 0.5, 0), q + Vector3(0, -2, 0), 1))
		flat = flat and not hit.is_empty() and absf(float(hit["position"].y)) < 0.06
	out.append({"what": "hopelessly flat island ground", "ok": flat})
	# second walkable height: wooden house's upper storey
	var hb := Basis(Vector3.UP, deg_to_rad(Houses.HOUSES[1][2]))
	var up: Vector3 = Houses.HOUSES[1][1] + hb * Vector3(-1.5, 0, 0.6)
	var uh := space.intersect_ray(PhysicsRayQueryParameters3D.create(up + Vector3(0, 4.8, 0), up + Vector3(0, 2.0, 0), 1))
	out.append({"what": "upper storey floor in the wooden house", "ok": not uh.is_empty() and float(uh["position"].y) > 3.0, "detail": uh.get("position", null)})
	out.append({"what": "forest planted (hundreds of old trees, palms)", "ok": flora.count > 400, "detail": flora.count})
	out.append({"what": "four dormant houses, empty beds, closed blinds", "ok": houses.footprints.size() == 4 and houses.bed_spots.size() == 4 and houses.blind_spots.size() >= 10})
	# unchanging: nothing in the world moves over a second of frames
	var a := _snapshot()
	for i in 45:
		await get_tree().process_frame
	var b := _snapshot()
	var same := a.size() == b.size()
	if same:
		for i in a.size():
			if not (a[i] as Transform3D).is_equal_approx(b[i]):
				same = false
				break
	out.append({"what": "nothing moves (unchanging world)", "ok": same, "detail": a.size()})
	_try("rock")
	out.append({"what": "an attempt to change the island is counted and changes nothing", "ok": tried.has("rock")})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
