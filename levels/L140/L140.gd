extends LevelBase
## Level 140 "Honey" (Backrooms Wikidot rev 43, accessed 2026-11-04; cite:
## Stixiiee, CC BY-SA 3.0). Dossier: docs/canon/levels/L140.md.
## The page is epistolary: everything below is TESTIMONY from Mary's letters
## to her wife and the couple's field notes.
##
## PLAN (v2.0 rebuild)
## SOURCE: a beautiful field stretching to the horizon; a normal day-night
##   cycle (sunsets around 6 pm, sunrises around 5 am), stars at night; a
##   distant voice giggles; a lobby with many bottles of honey; a backyard
##   with flowers and a little one that looks sad and tired; many sunflowers;
##   buzzing and wind; a beehive near the first sunflower field; honey made
##   there (sunflower honey tastes faintly of sunflower oil), the last comb
##   jarred and named after the queen; a second field of weeds left of the
##   sunflowers with a tiny tree in front of a weird hydrangea-like flower that
##   buzzes in a human-made way; bees visit it; a peculiar blue flower whose
##   petal turns to sparkly dust, and where the dust flew flowers bloom fast
##   into a path south toward an infinite wheat field, where it stops; chilly
##   mornings and a jacket in the closet; the camp the two set up first.
## SPACE (ADAPTATION): the camp cottage on a low rise (ground-floor lobby,
##   sleeping loft at +2.75 m by a stair, porch), the fenced backyard, the
##   beehive, a 96 x 74 m sunflower field taller than you east of the camp,
##   the weed field north of it with the tiny tree and the weird flower, the
##   blue flower south of the camp and the wheat from 150 m south to the
##   horizon. Rolling grass to the horizon on every side (far mesh, haze).
## SIGNATURE MECHANIC (stateful): a running day-night clock (1 hour = 75 s;
##   sunrise 5:00, sunset 18:00, stars at night, chilly mornings) and the
##   blue petal: take one and its dust drifts south; over the next minute a
##   path of flowers blooms toward the wheat and stops at its edge. Honey:
##   lift a comb from the hive and strain it into a new bottle in the lobby;
##   water the little one and it lifts its head; smile and wave at the
##   buzzing flower; take the jacket on a cold morning.
## EXITS: none on the page (see level.json no_exit_reason).
## ABSENT: hostile entities, horror, darkness by default, Level 139/141 exits.

const T := preload("res://levels/L140/L140_terrain.gd")
const Flora := preload("res://levels/L140/L140_flora.gd")
const House := preload("res://levels/L140/L140_house.gd")
const HOUR := 75.0
const SOFT_R := 250.0
const HOLD := 7.0

var ter
var flora
var house
var clock_h := 15.5
var sky_mat: ShaderMaterial
var moon: DirectionalLight3D
var path_mm: MultiMesh
var path_t := -1.0
var petal_taken := false
var combs := 0
var jars_made := 0
var watered := false
var wearing_jacket := false
var giggle_t := 90.0
var said := {}
var beds := {}
var _base_walk := 3.1
var _tick := 0.0
var dust: CPUParticles3D

const SKY := """shader_type sky;
uniform vec3 sun_dir = vec3(0.0, 0.5, 0.8);
uniform float day = 1.0;
uniform vec3 zen_day : source_color = vec3(0.25, 0.45, 0.8);
uniform vec3 hor_day : source_color = vec3(0.78, 0.82, 0.86);
uniform vec3 zen_night : source_color = vec3(0.004, 0.008, 0.025);
uniform vec3 hor_night : source_color = vec3(0.02, 0.03, 0.06);
uniform vec3 glow : source_color = vec3(1.0, 0.5, 0.18);
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float stars(vec3 d, float sc, float th, float sz) {
	vec3 p = d * sc; vec3 c = floor(p); vec3 f = fract(p); float h = h1(c);
	if (h < th) return 0.0;
	vec3 o = vec3(h1(c + 3.1), h1(c + 7.7), h1(c + 1.9)) * 0.6 + 0.2;
	return smoothstep(sz, 0.0, length(f - o)) * (0.3 + 0.7 * (h - th) / (1.0 - th));
}
void sky() {
	vec3 d = EYEDIR;
	vec3 s = normalize(sun_dir);
	float up = max(d.y, 0.0);
	float hz = pow(1.0 - up, 5.0);
	vec3 col = mix(mix(zen_night, hor_night, hz), mix(zen_day, hor_day, hz), day);
	float sd = max(dot(d, s), 0.0);
	float low = 1.0 - smoothstep(0.02, 0.4, s.y);
	float above = smoothstep(-0.18, 0.02, s.y);
	col += glow * low * above * (pow(sd, 3.0) * 0.9 + hz * 0.35 * (0.4 + 0.6 * sd));
	col += vec3(1.0, 0.85, 0.6) * pow(sd, 400.0) * 3.0 * above;
	col += vec3(1.0, 0.8, 0.5) * pow(sd, 18.0) * 0.25 * above;
	if (!AT_CUBEMAP_PASS) {
		float st = stars(d, 90.0, 0.972, 0.2) * 2.2 + stars(d, 190.0, 0.96, 0.18) * 1.0;
		col += vec3(st) * (1.0 - day) * smoothstep(0.0, 0.12, d.y);
	}
	if (d.y < 0.0) {
		col = mix(col, mix(vec3(0.01, 0.012, 0.01), vec3(0.18, 0.2, 0.12), day), smoothstep(0.0, -0.08, d.y));
	}
	COLOR = col;
}"""


func build() -> void:
	ter = T.new()
	rules["view_distance"] = 4500.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.03
	rules["flashlight"] = "allowed"
	_environment()
	House.materials()
	lights.setup(4, 0)
	var land := Node3D.new()
	land.name = "Land"
	add_child(land)
	var shell := StandardMaterial3D.new()
	var gp := "res://assets/external/sparse_grass/sparse_grass_diff_1k.jpg"
	if ResourceLoader.exists(gp):
		shell.albedo_texture = load(gp)
	shell.albedo_color = Color(1.6, 1.15, 0.42)
	shell.uv1_triplanar = true
	shell.uv1_scale = Vector3(0.5, 0.08, 0.5)
	shell.roughness = 1.0
	ter.build_meshes(land, ter.make_material(false), shell)
	ter.build_collision(land)
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var k := kit("Camp")
	house = House.new(self, ter, k, props)
	house.build()
	k.commit()
	_plants(land)
	_special_flowers()
	_bees()
	_notes()
	_sounds()
	var s: Vector3 = house.porch
	add_arrival("start", Vector3(s.x + 4.2, ter.h(s.x + 4.2, s.z) + 0.05, s.z), -95.0)
	add_arrival("from_L019", Vector3(-70.0, ter.h(-70.0, 24.0) + 0.05, 24.0), -80.0)
	add_arrival("from_L149", Vector3(34.0, ter.h(34.0, -58.0) + 0.05, -58.0), -150.0)
	add_landmark("The lobby cottage on the rise", T.COTTAGE)
	add_landmark("The first sunflower field", Vector3(66.0, 1.0, 0.0))
	add_landmark("The beehive", T.HIVES)
	add_landmark("The weird flower in the weeds", T.WEIRD)
	add_landmark("The peculiar blue flower", T.BLUE_FLOWER)
	add_landmark("Edge of the wheat", T.PATH_END)
	_shots()
	_apply_time()


# ------------------------------------------------------------- sky and time

func _environment() -> void:
	sky_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY
	sky_mat.shader = sh
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_density = 0.0011
	environment.fog_sky_affect = 0.15
	environment.fog_aerial_perspective = 0.4
	environment.tonemap_exposure = 1.0
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.name = "NightSky"
	moon.light_color = Color(0.55, 0.62, 0.9)
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-55.0, 140.0, 0.0)
	add_child(moon)


func _sun_vec(hour: float) -> Vector3:
	# sunrise 5:00 in the east, sunset 18:00 in the west, low arc to the south
	var t := (hour - 5.0) / 13.0
	var a := PI * t
	var elev := sin(a) * 0.95 - (0.0 if t >= 0.0 and t <= 1.0 else 0.0)
	if t < 0.0 or t > 1.0:
		var nt := fposmod(hour - 18.0, 24.0) / 11.0
		elev = -sin(PI * clampf(nt, 0.0, 1.0)) * 0.7
		a = PI + PI * nt
	return Vector3(cos(a), elev, 0.45 * sin(a) + 0.35).normalized()


func _apply_time() -> void:
	var s := _sun_vec(clock_h)
	var day := smoothstep(-0.12, 0.12, s.y)
	var low := 1.0 - smoothstep(0.05, 0.45, s.y)
	sky_mat.set_shader_parameter("sun_dir", s)
	sky_mat.set_shader_parameter("day", day)
	if s.y > -0.05:
		sun.visible = true
		sun.look_at_from_position(Vector3.ZERO, -s, Vector3.UP)
		sun.light_color = Color(1.0, 0.95, 0.88).lerp(Color(1.0, 0.6, 0.3), low)
		sun.light_energy = 1.25 * smoothstep(-0.05, 0.12, s.y)
	else:
		sun.visible = false
	moon.light_energy = 0.12 * (1.0 - day)
	environment.ambient_light_color = Color(0.1, 0.12, 0.2).lerp(Color(0.62, 0.62, 0.6).lerp(Color(0.7, 0.55, 0.45), low), day)
	environment.ambient_light_energy = lerpf(0.55, 0.8, day)
	environment.fog_light_color = Color(0.04, 0.05, 0.09).lerp(Color(0.8, 0.82, 0.84).lerp(Color(0.95, 0.65, 0.42), low), day)
	if house:
		for id in house.light_ids:
			if id >= 0 and id < lights.anchors.size():
				lights.anchors[id]["energy"] = lerpf(1.4, 0.25, day)


# ------------------------------------------------------------- plants

func _plants(parent: Node3D) -> void:
	flora = Flora.new()
	var r := RandomNumberGenerator.new()
	r.seed = 14100
	# the first sunflower field: rows along x with walkable furrows between
	var f: Rect2 = T.SUN_FIELD
	var z := f.position.y + 1.0
	var row := 0
	while z < f.end.y - 0.5:
		var x := f.position.x + 1.4
		while x < f.end.x - 1.2:
			if absf(z - 0.0) < 1.4:
				x += 2.4
				continue
			var p := Vector3(x + r.randf_range(-0.2, 0.2), 0, z + r.randf_range(-0.1, 0.1))
			p.y = ter.h(p.x, p.z) - 0.05
			flora.add_sunflower(Transform3D(Basis(Vector3.UP, r.randf_range(-0.15, 0.15)).scaled(Vector3.ONE * r.randf_range(0.9, 1.1)), p))
			x += 2.4
		z += 2.6 if row % 3 != 2 else 3.4
		row += 1
	# the weed field
	var wf: Rect2 = T.WEED_FIELD
	for i in 1700:
		var p := Vector3(r.randf_range(wf.position.x, wf.end.x), 0, r.randf_range(wf.position.y, wf.end.y))
		if Vector2(p.x - T.WEIRD.x, p.z - T.WEIRD.z).length() < 4.0:
			continue
		p.y = ter.h(p.x, p.z)
		flora.add("weeds", Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.3)), p))
	# planted wheat at the near edge of the infinite field
	var wn: Rect2 = T.WHEAT_NEAR
	var zz := wn.position.y + 1.0
	while zz < wn.end.y:
		var xx := wn.position.x
		while xx < wn.end.x:
			var p := Vector3(xx + r.randf_range(-0.4, 0.4), 0, zz + r.randf_range(-0.4, 0.4))
			if absf(p.x - T.PATH_END.x) < 1.6 and p.z < T.PATH_END.z + 3.0:
				xx += 1.25
				continue
			p.y = ter.h(p.x, p.z)
			flora.add("wheat", Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(1, r.randf_range(0.9, 1.15), 1)), p))
			xx += 1.25
		zz += 1.25
	# meadow grass and wild flowers around the camp and along the walks
	var n := 0
	for i in 9000:
		if n > 3200:
			break
		var p := Vector3(r.randf_range(-130.0, 130.0), 0, r.randf_range(-140.0, 148.0))
		if f.grow(1.0).has_point(Vector2(p.x, p.z)) or wf.grow(1.0).has_point(Vector2(p.x, p.z)):
			continue
		if ter.path_d(p.x, p.z) < 1.4 or (p.x > -15.0 and p.x < 0.0 and absf(p.z) < 8.0) or (p.x > -31.0 and p.x < -11.0 and absf(p.z) < 8.0):
			continue
		var dd := Vector2(p.x, p.z).length()
		if r.randf() > 1.0 - smoothstep(30.0, 140.0, dd) * 0.7:
			continue
		p.y = ter.h(p.x, p.z)
		var kind := "grass" if r.randf() < 0.7 else "wild%d" % r.randi_range(0, 4)
		flora.add(kind, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.8, 1.25)), p))
		n += 1
	# the backyard beds
	for i in 3:
		for zc in [-2.5, 3.5]:
			var c := Vector3(-26.5 + i * 5.0, 0, zc)
			for j in 2:
				var p := c + Vector3(-0.9 + j * 1.8, 0, 0)
				p.y = ter.h(p.x, p.z) + 0.3
				flora.add("wild%d" % posmod(i + j + int(zc), 5), Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(0.75, 1.0, 0.5)), p))
	flora.commit(parent)
	# the path the dust will seed (hidden until the petal is taken)
	var xfs: Array = []
	var a: Vector3 = T.BLUE_FLOWER + Vector3(0, 0, 2.0)
	var b: Vector3 = T.PATH_END
	var steps := int(a.distance_to(b) / 0.9)
	for i in steps:
		var t := float(i) / steps
		var p := a.lerp(b, t) + Vector3(2.2 * sin(t * 9.0), 0, 0)
		for side in [-0.8, 0.8]:
			var q := p + Vector3(side + r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
			q.y = ter.h(q.x, q.z)
			xfs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.6, 0.9)), q))
	path_mm = flora.path_mesh(parent, xfs)


func _special_flowers() -> void:
	# the tiny tree in front of the weird flower
	var w: Vector3 = T.WEIRD
	w.y = ter.h(w.x, w.z)
	var tree := MeshInstance3D.new()
	tree.mesh = Flora.sapling()
	tree.material_override = flora.mat
	tree.position = w + Vector3(0, 0, 2.2)
	add_child(tree)
	var stem := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.03
	cm.height = 0.7
	stem.mesh = cm
	stem.material_override = MatLib.standard(Color(0.16, 0.34, 0.1), 0.8)
	stem.position = w + Vector3(0, 0.35, 0)
	add_child(stem)
	var ball := MeshInstance3D.new()
	ball.mesh = Flora.hydrangea(Color(0.42, 0.45, 0.95), 0.32, 160, 1405)
	ball.material_override = flora.mat
	ball.position = w + Vector3(0, 0.95, 0)
	add_child(ball)
	add_interactable(w + Vector3(0, 0.9, 0), Vector3(1.4, 1.6, 1.4), "Smile and wave at the flower", func():
		Overlay.subtitle("[you smile and wave. The flower keeps buzzing, steady as a machine.]", 4.5))
	# the peculiar blue flower
	var bfp: Vector3 = T.BLUE_FLOWER
	bfp.y = ter.h(bfp.x, bfp.z)
	var bstem := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.012
	bc.bottom_radius = 0.02
	bc.height = 0.6
	bstem.mesh = bc
	bstem.material_override = MatLib.standard(Color(0.16, 0.34, 0.1), 0.8)
	bstem.position = bfp + Vector3(0, 0.3, 0)
	add_child(bstem)
	var bloom := MeshInstance3D.new()
	bloom.name = "BlueFlower"
	bloom.mesh = Flora.hydrangea(Color(0.15, 0.4, 1.0), 0.12, 26, 1406)
	var bm := flora.mat.duplicate() as StandardMaterial3D
	bm.emission_enabled = true
	bm.emission = Color(0.1, 0.25, 0.7)
	bm.emission_energy_multiplier = 0.8
	bloom.material_override = bm
	bloom.position = bfp + Vector3(0, 0.62, 0)
	add_child(bloom)
	add_interactable(bfp + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 1.0), "Take a petal from the blue flower", _take_petal)
	dust = CPUParticles3D.new()
	dust.emitting = false
	dust.one_shot = true
	dust.amount = 90
	dust.lifetime = 9.0
	dust.explosiveness = 0.2
	dust.position = bfp + Vector3(0, 0.8, 0)
	dust.direction = Vector3(0.1, 0.25, 1.0)
	dust.spread = 18.0
	dust.initial_velocity_min = 1.5
	dust.initial_velocity_max = 3.0
	dust.gravity = Vector3(0, -0.05, 0.6)
	dust.scale_amount_min = 0.03
	dust.scale_amount_max = 0.07
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	dm.albedo_color = Color(0.6, 0.8, 1.0)
	dm.emission_enabled = true
	qm.material = dm
	dust.mesh = qm
	add_child(dust)


func _bees() -> void:
	var qm := QuadMesh.new()
	qm.size = Vector2(0.025, 0.018)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	bm.albedo_color = Color(0.12, 0.09, 0.02)
	qm.material = bm
	var spots: Array = house.hive_spots.duplicate()
	spots.append(T.WEIRD + Vector3(0, ter.h(T.WEIRD.x, T.WEIRD.z) + 0.9, 0))
	for i in 5:
		var x := T.SUN_FIELD.position.x + 6.0 + i * 16.0
		spots.append(Vector3(x, ter.h(x, 10.0 - i * 6.0) + 2.0, 10.0 - i * 6.0))
	for s in spots:
		var p := CPUParticles3D.new()
		p.mesh = qm
		p.amount = 26
		p.lifetime = 3.0
		p.position = s
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.6
		p.direction = Vector3(0, 0.3, 0)
		p.spread = 180.0
		p.initial_velocity_min = 0.6
		p.initial_velocity_max = 1.4
		p.gravity = Vector3.ZERO
		p.orbit_velocity_min = 0.3
		p.orbit_velocity_max = 0.8
		p.damping_min = 0.4
		p.damping_max = 0.8
		add_child(p)


# ------------------------------------------------------------- interactions

func _take_petal() -> void:
	if petal_taken:
		Overlay.subtitle("[the blue flower has one petal fewer. The dust has already gone south.]", 4.0)
		return
	petal_taken = true
	path_t = 0.0
	if is_instance_valid(dust):
		dust.restart()
		dust.emitting = true
	Overlay.subtitle("[the petal comes away and turns to sparkly dust, slipping through your fingers and drifting south]", 6.0)


func _lift_comb() -> void:
	combs += 1
	Overlay.subtitle("[you lift the lid: warm wax, bees everywhere, the buzzing swells. You take one comb.]", 4.5)


func _strain() -> void:
	if combs <= 0:
		Overlay.subtitle("[the strainer is clean. A comb from the hive would go here.]", 3.5)
		return
	combs -= 1
	jars_made += 1
	if house.jar_spots.size() > 0:
		var spot: Vector3 = house.jar_spots.pop_front()
		var j := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.07
		cm.bottom_radius = 0.07
		cm.height = 0.17
		j.mesh = cm
		j.material_override = MatLib.get_mat("l140_honey")
		j.position = spot + Vector3(0, 0.085, 0)
		add_child(j)
	Overlay.subtitle("[you strain the wax out and pour the honey into another bottle. It smells faintly of sunflower oil.]", 4.5)


func _water() -> void:
	if watered:
		Overlay.subtitle("[the little one is still holding its head up.]", 3.0)
		return
	watered = true
	Overlay.subtitle("[you water the little one. It still looks tired... but a little less.]", 4.0)
	var head: Node3D = house.little_one.get_node_or_null("Head")
	if head:
		create_tween().tween_property(head, "rotation", Vector3(0, 0, -0.25), 20.0)
		create_tween().tween_property(head, "position", Vector3(0.03, 0.33, 0), 20.0)


func _jacket() -> void:
	wearing_jacket = not wearing_jacket
	Overlay.subtitle("[you take the jacket from the closet and put it on]" if wearing_jacket else "[you hang the jacket back in the closet]", 3.0)


# ------------------------------------------------------------- notes

func _notes() -> void:
	var fy: float = house.fy
	var ly: float = house.loft_y
	add_note("l140_letter1", "Letter: \"Honey,\"", "Honey,\n\nYou are far away, I know, but come back soon: the wax still needs straining out of the honey and into all those bottles in the lobby.\n\nI watered the backyard today. I hope the little one makes it; it looks a bit sad and tired.\n\nI took a picture of the field this afternoon. So many sunflowers. That view never gets old.\n\nI love you,\nMary", Vector3(-8.2, fy + 0.9, 0.2))
	add_note("l140_letter2", "Letter: twenty sunsets", "Honey,\n\nThe last comb is in a jar and sealed. I named it after the queen.\n\nTwenty sunsets now. I wish you were here to see them.\n\nKnuckle kisses,\nMary", Vector3(-9.0, fy + 0.9, 0.8))
	add_note("l140_letter3", "Letter: the weird flower", "Honey,\n\nI walked into the second field, the weeds to the left of the sunflowers, and found a tiny tree in front of a weird flower. I thought it was a hydrangea, but it buzzes. Not like the bees: like something someone built.\n\nIf anyone is watching me through it, they must be very bored. If someone planted it to keep it safe, I hope they get my smile and my wave.\n\nCome home soon. It is a little less warm here without you.\n\nMary", Vector3(T.WEIRD.x - 1.2, ter.h(T.WEIRD.x - 1.2, T.WEIRD.z + 2.4) + 0.5, T.WEIRD.z + 2.4), Vector3(0.4, 0.3, 0.4))
	add_note("l140_letter4", "Letter: the twenty-eighth afternoon", "Honey,\n\nThe twenty-eighth afternoon without you. I miss you, Gina.\n\nDo you remember the coffee shop? You frowning at that terrible black coffee. Everything went quiet around you. Five months since we met, and since they asked us to look into this level.\n\nThe sun was very comfortable today. It reminded me of you.\n\nWarm hugs,\nMary", Vector3(T.COTTAGE.x - 3.5, ly + 0.72, -0.6))
	add_note("l140_fieldnote1", "Field note (the hive)", "Georgia and I found a beehive not far from the first sunflower field. As far as we can tell, everything here works the way it should: flowers, bees, honey. We can cultivate honey now, and that makes this place feel like ours.\n\nShould we call it \"Mary and Georgia's\"? We did set up camp first.", T.HIVES + Vector3(-3.4, ter.h(T.HIVES.x - 3.4, T.HIVES.z) + 0.9, 0.6), Vector3(0.4, 0.3, 0.4))
	add_note("l140_fieldnote2", "Field note (the honey)", "Bees go into that weird flower and come out happy with its pollen. Maybe it will end up in the honey.\n\nSunflower honey tastes a little like sunflower oil, and still sweet. If you like honey and you like your parents, give them a jar of ours.", Vector3(house.porch.x, house.fy + 0.6, -2.3), Vector3(0.4, 0.3, 0.4))
	add_note("l140_wheat", "Pencil on a slip of paper, at the edge of the wheat", "This morning was chilly; I took a jacket from the closet for the first time in a while. You had been gone thirty days.\n\nI took a petal from the peculiar blue flower and it turned to dust. Hours later, flowers had bloomed where the dust went, like a path. I followed it south into the golden afternoon, to the wheat, and it stopped. And there you were, standing in the field. Tired. Smiling.\n\n\"Mostly walking in endless terrain,\" you said.", T.PATH_END + Vector3(1.6, ter.h(T.PATH_END.x + 1.6, T.PATH_END.z - 2.0) + 0.5, -2.0), Vector3(0.4, 0.3, 0.4))
	# interactions in the camp
	add_interactable(T.HIVES + Vector3(0, ter.h(T.HIVES.x, T.HIVES.z) + 0.8, 0.5), Vector3(5.8, 1.2, 1.2), "Lift a hive lid and take a comb", _lift_comb)
	add_interactable(Vector3(-8.5, fy + 1.0, 0.5), Vector3(0.8, 0.5, 0.8), "Strain the wax into a bottle", _strain)
	add_interactable(house.little_one.position + Vector3(0, 0.25, 0), Vector3(0.6, 0.6, 0.6), "Water the little one", _water)
	add_interactable(Vector3(-4.6, fy + 1.0, -1.6), Vector3(0.6, 1.8, 1.2), "Open the closet", _jacket)


# ------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -26.0)
	beds["bees"] = sound.bed("fluorescent_hum", {"seconds": 3.0, "base": 118.0, "rasp": 0.7}, -40.0)
	beds["night"] = sound.bed("crickets", {"seconds": 6.0}, -70.0)
	for s in house.hive_spots:
		sound.emitter("fluorescent_hum", s, {"seconds": 2.0, "base": 112.0 + randf() * 14.0, "rasp": 0.8}, -14.0, 14.0)
	sound.emitter("transformer", T.WEIRD + Vector3(0, ter.h(T.WEIRD.x, T.WEIRD.z) + 0.9, 0), {"base": 50.0}, -16.0, 16.0)
	sound.emitter("fluorescent_hum", Vector3(60.0, 3.0, 0.0), {"seconds": 3.0, "base": 124.0, "rasp": 0.6}, -12.0, 60.0)


# ------------------------------------------------------------- shots

func _shots() -> void:
	var s: Vector3 = house.porch
	add_shot("afternoon_sunflowers", Vector3(T.SUN_FIELD.position.x + 3.0, ter.h(T.SUN_FIELD.position.x + 3.0, 0.4) + 1.65, 0.4), Vector3(80.0, 2.0, -6.0), {"flashlight": false, "prepare": func(): _set_time(16.9)})
	add_shot("lobby_honey", Vector3(-5.0, house.fy + 1.6, 3.6), Vector3(-11.8, house.fy + 1.0, -1.5), {"flashlight": false, "prepare": func(): _set_time(17.2)})
	var bf: Vector3 = T.BLUE_FLOWER
	add_shot("petal_path_to_wheat", Vector3(T.PATH_END.x - 3.0, ter.h(T.PATH_END.x - 3.0, T.PATH_END.z - 26.0) + 1.7, T.PATH_END.z - 26.0), T.PATH_END + Vector3(4.0, 1.0, 40.0), {"flashlight": false, "prepare": _prep_path})
	add_shot("night_stars_cottage", Vector3(16.0, ter.h(16.0, 18.0) + 1.6, 18.0), Vector3(-10.0, 10.0, -6.0), {"flashlight": false, "prepare": func(): _set_time(23.3)})
	add_shot("hive_and_weeds", T.HIVES + Vector3(4.0, ter.h(T.HIVES.x + 4.0, T.HIVES.z + 6.0) + 1.6, 6.0), T.WEIRD + Vector3(0, 2.0, 0), {"flashlight": false, "prepare": func(): _set_time(10.0)})


func _set_time(h: float) -> void:
	clock_h = h
	_apply_time()


func _prep_path() -> void:
	_set_time(17.4)
	petal_taken = true
	path_t = 999.0
	if path_mm:
		path_mm.visible_instance_count = path_mm.instance_count


# ------------------------------------------------------------- update

func on_player_ready() -> void:
	_base_walk = player.walk_speed


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var qa := SessionState.is_qa()
	if not qa:
		clock_h = fposmod(clock_h + delta / HOUR, 24.0)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_apply_time()
		_captions()
	if path_t >= 0.0 and path_mm and path_mm.visible_instance_count < path_mm.instance_count:
		path_t += delta
		path_mm.visible_instance_count = mini(path_mm.instance_count, int(path_t / 50.0 * path_mm.instance_count))
	var p := player.global_position
	if not qa:
		giggle_t -= delta
		if giggle_t <= 0.0:
			giggle_t = rng.randf_range(360.0, 600.0)
			sound.play_at("whisper", {"seconds": 1.6}, p + Vector3(rng.randf_range(-60.0, 60.0), 2.0, rng.randf_range(-60.0, 60.0)), -14.0, "[a distant voice giggles]")
		_soft_limit(p)
	if petal_taken and Vector2(p.x - T.PATH_END.x, p.z - T.PATH_END.z).length() < 4.0:
		_say("path_end", "[the flowers stop here, abruptly, at the edge of the wheat. It goes on to the horizon.]", 6.0)
	_mix(p, delta)


func _captions() -> void:
	var h := clock_h
	if h > 5.0 and h < 8.0:
		_say("morning", "[a chilly morning. There is a jacket in the closet.]" if not wearing_jacket else "[a chilly morning; the jacket helps]")
	if h > 17.6 and h < 18.4:
		_say("sunset", "[around six: the sun goes down over the field]")
	if h > 22.0 or h < 4.0:
		_say("stars", "[night. More stars than you remember there being.]")


func _soft_limit(p: Vector3) -> void:
	var d := Vector2(p.x, p.z).length() - SOFT_R
	if d > 0.0:
		player.walk_speed = _base_walk * clampf(1.0 - d / HOLD, 0.25, 1.0)
		_say("soft", "[the field goes on like this, the same, for days. Gina walked it for thirty of them.]", 5.0)
		if d > HOLD:
			var dir := Vector2(p.x, p.z).normalized() * (SOFT_R + HOLD)
			player.global_position = Vector3(dir.x, p.y, dir.y)
	elif player.walk_speed != _base_walk:
		player.walk_speed = _base_walk


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func _mix(p: Vector3, delta: float) -> void:
	var k := minf(delta * 1.5, 1.0)
	var s := _sun_vec(clock_h)
	var day := smoothstep(-0.1, 0.1, s.y)
	var near_field := 1.0 - clampf(Vector2(p.x - 66.0, p.z).length() / 120.0, 0.0, 1.0)
	_vol("bees", lerpf(-60.0, lerpf(-34.0, -20.0, near_field), day), k)
	_vol("night", lerpf(-22.0, -70.0, day), k)
	_vol("wind", -26.0, k)


func _vol(key: String, db: float, k: float) -> void:
	var a: AudioStreamPlayer = beds.get(key)
	if a:
		a.volume_db = lerpf(a.volume_db, db, k)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "no exit triggers (the page documents none)", "ok": exits.is_empty()})
	out.append({"what": "spawn on the porch steps above the field", "ok": is_instance_valid(player) and player.global_position.y > 0.5, "detail": player.global_position if is_instance_valid(player) else null})
	out.append({"what": "sleeping loft is a second walkable level", "ok": house.loft_y - house.fy > 2.5})
	var s6 := _sun_vec(18.0)
	var s5 := _sun_vec(5.0)
	var s12 := _sun_vec(11.5)
	out.append({"what": "sunset ~18:00 and sunrise ~5:00 sit on the horizon, noon high", "ok": absf(s6.y) < 0.05 and absf(s5.y) < 0.05 and s12.y > 0.7, "detail": [s5.y, s12.y, s6.y]})
	out.append({"what": "night sky (23:00) has the sun below the horizon", "ok": _sun_vec(23.0).y < -0.2})
	out.append({"what": "petal path hidden until a petal is taken", "ok": path_mm != null and path_mm.visible_instance_count == 0 and path_mm.instance_count > 100})
	out.append({"what": "sunflowers planted", "ok": flora.count > 2000, "detail": flora.count})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
