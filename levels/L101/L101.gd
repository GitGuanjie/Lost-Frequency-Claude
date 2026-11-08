extends LevelBase
## Level 101 — "Your Dream Shall Never Dawn Again" (Backrooms Wikidot rev 24,
## accessed 2026-11-04; cite: BetterMyButter (user deleted), CC BY-SA 3.0).
## Dossier: docs/canon/levels/L101.md. Content note (page): grief and loss.
##
## PLAN (v2.0 rebuild)
## SOURCE: a nigh-perfect replica of Earth; you awaken inside your home from
## before the Backrooms; "inconsistencies" grow more visible and intense with
## time: lamp posts seem too tall, sound lags behind its cause, some animals
## seen from ~100 m briefly lack or have excess skin, almond water does not
## exist (no vendor, no search engine), New Zealand is on no map; no outposts;
## entered only through unlocked doors in Level 2; stating "I'm ready to go
## back" makes you fall unconscious and wake in Level 0. The narrative frame
## (TESTIMONY) is a windy, cold beach with sand and shells, "so quiet" despite
## the sea, waves that don't match their sound, the sun a little too far left,
## clouds a fraction too fast, and someone calling from the dunes to head in.
## ADAPTATION: "your home" is an ordinary two-storey seaside house on a street
## of houses whose gardens run down to a dune and that beach (the page names
## no layout; the beach comes from the narrative). No family or other people
## are shown (canon trap). The street streams along X in 48 m chunks (a finite
## window on an Earth replica). Wrongness rises over ~15 minutes: street lamps
## stretch taller, the wave sound falls behind the breaking swash, the sun
## drifts left and the clouds speed up, and a gull far out briefly looks wrong.
## The spoken return is offered at the bed, on the back deck and at the shore.
## Verticality: two storeys with a stair, porch and deck steps, a dune ridge.
## Helpers: L101_house.gd (the home), L101_coast.gd (street, houses, beach).

const HOUSE := preload("res://levels/L101/L101_house.gd")
const COAST := preload("res://levels/L101/L101_coast.gd")
const WRONG_SECONDS := 900.0
const SUN := Vector2(28.0, 20.0)

var house
var coast
var world: ChunkWorld
var sea: WaterVolume
var sea_cx := 0.0
var lamps: Dictionary = {}       # chunk key -> [Node3D]
var lamp_k: Dictionary = {}      # node -> personal factor
var sky_mat: ShaderMaterial
var clock := 0.0
var wrong := 0.0
var said := {}
var swash: MeshInstance3D
var swash_t := 0.0
var crash_q: Array = []
var gulls: Array = []
var gull_mesh: ArrayMesh
var gull_wrong: ArrayMesh
var gull_t := 50.0
var bad_gull: MeshInstance3D
var bad_t := 0.0
var beds := {}
var start := Vector3.ZERO
var cloud_t := 0.0


func build() -> void:
	house = HOUSE.new(self)
	coast = COAST.new(self)
	rules["view_distance"] = 1400.0
	rules["reverb_room"] = 0.12
	rules["reverb_wet"] = 0.05
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.36, 0.52, 0.72), Color(0.74, 0.8, 0.84), Color(0.5, 0.5, 0.48), SUN, Color(1.0, 0.95, 0.86), 1.35, Color(0.74, 0.78, 0.82), 0.0016)
	var sh := Shader.new()
	sh.code = SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	environment.sky.sky_material = sky_mat
	environment.ambient_light_sky_contribution = 0.75
	environment.ambient_light_energy = 0.75
	environment.fog_sky_affect = 0.15
	environment.fog_aerial_perspective = 0.4
	environment.tonemap_exposure = 1.0
	environment.ssao_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_blur = 1.5
	COAST.define_materials()
	lights.setup(8, 0)
	var home := Node3D.new()
	home.name = "Home"
	add_child(home)
	house.build(home)
	for l in house.lights:
		lights.add_anchor(l[0], l[1], l[2], l[3], 0.0, "home")
	world = ChunkWorld.new()
	world.name = "Coast"
	world.chunk_size = COAST.CHUNK
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	world.chunk_unloaded.connect(func(k): lamps.erase(k))
	add_child(world)
	start = Vector3(-2.35, HOUSE.F1 + 0.05, 1.35)
	world.build_around(start, 2)
	world.build_around(Vector3(0, 0, 60), 2)
	sea = WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-1500.0, -30.0, COAST.SHORE - 12.0), Vector3(1500.0, 0.0, 2400.0), "l101_sea", true)
	sea.fog_color = Color(0.1, 0.22, 0.26)
	sea.fog_density = 0.12
	sea.tint = Color(0.3, 0.5, 0.55)
	_boardwalk()
	_swash()
	_gulls()
	_things()
	_sounds()
	add_arrival("start", start, 60.0)
	add_arrival("from_L002", Vector3(-0.55, HOUSE.F1 + 0.05, 1.95), 90.0)
	add_landmark("Home (two storeys, bedroom upstairs)", Vector3(0, 0, 5))
	add_landmark("Boardwalk over the dune", Vector3(0.6, 2.0, 30))
	add_landmark("The shore", Vector3(0.6, 0, COAST.SHORE - 8.0))
	_shots()


const SKY := """
shader_type sky;
uniform vec3 top : source_color = vec3(0.36, 0.52, 0.72);
uniform vec3 hor : source_color = vec3(0.74, 0.8, 0.84);
uniform float cloud_speed = 1.0;
uniform float cloud_t = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { s += a * vn(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; } return s; }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec3 col = mix(hor, top, pow(smoothstep(0.0, 0.7, y), 0.7));
	vec2 uv = d.xz / (d.y + 0.15) * 1.1 + vec2(cloud_t * 0.03, cloud_t * 0.012);
	float c = fbm(uv * 0.7);
	float cov = smoothstep(0.48, 0.78, c) * smoothstep(0.0, 0.12, y);
	vec3 cloud = mix(vec3(0.62, 0.65, 0.7), vec3(1.0), smoothstep(0.5, 0.9, fbm(uv * 1.6 + 3.0)));
	col = mix(col, cloud, cov * 0.92);
	float sd = dot(d, LIGHT0_DIRECTION);
	col += LIGHT0_COLOR * (pow(max(sd, 0.0), 900.0) * 30.0 + pow(max(sd, 0.0), 12.0) * 0.18) * (1.0 - cov * 0.8);
	if (d.y < 0.0) { col = hor * 0.9; }
	COLOR = col;
}
"""


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if cz != 0:
		return {}
	var meta: Dictionary = coast.chunk(node, cx, hash([cx, level_seed]))
	var ls: Array = meta.get("lamps", [])
	lamps[Vector2i(cx, cz)] = ls
	for l in ls:
		lamp_k[l] = 0.8 + 0.4 * fposmod(sin(float(cx) * 12.9898 + (l as Node3D).position.x) * 43758.5453, 1.0)
		_apply_lamp(l)
	return meta


func _apply_lamp(l: Node3D) -> void:
	if is_instance_valid(l):
		l.scale.y = 1.0 + 0.85 * wrong * float(lamp_k.get(l, 1.0))


## Planks over the dune saddle behind the home, then steps onto the beach.
func _boardwalk() -> void:
	var k := kit("Boardwalk")
	var z := COAST.DUNE0 - 0.5
	while z < COAST.BEACH0 + 2.0:
		var y: float = coast.h(0.6, z)
		k.box(Vector3(0.6, y + 0.06, z + 0.5), Vector3(1.6, 0.06, 0.95), "l101_deck", GeoKit.ALL, false)
		z += 1.0
	for s in [-1.0, 1.0]:
		for i in 14:
			var zz := COAST.DUNE0 + 2.0 * i
			k.box(Vector3(0.6 + s * 1.3, coast.h(0.6 + s * 1.3, zz) + 0.4, zz), Vector3(0.08, 0.9, 0.08), "l101_deck", GeoKit.ALL, false)
	k.commit()


# ---------------------------------------------------------------- the sea

func _swash() -> void:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley;
uniform float fade = 1.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = vn(wp.xz * vec2(0.35, 1.2)) * 0.6 + vn(wp.xz * 2.7) * 0.4;
	float edge = 1.0 - UV.y;
	float front = smoothstep(0.0, 0.08, edge) * (1.0 - smoothstep(0.08 + n * 0.08, 0.3 + n * 0.1, edge));
	float body = smoothstep(0.1, 0.5, edge) * (1.0 - smoothstep(0.5, 1.0, edge)) * 0.18;
	ALBEDO = mix(vec3(0.5, 0.6, 0.58), vec3(0.97, 0.98, 0.97), front);
	ALPHA = clamp(front * (0.6 + 0.4 * n) + body * n, 0.0, 0.9) * fade;
	ROUGHNESS = 0.2;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	swash = MeshInstance3D.new()
	swash.name = "Swash"
	var pm := PlaneMesh.new()
	pm.size = Vector2(320.0, 9.0)
	pm.subdivide_width = 32
	swash.mesh = pm
	swash.material_override = m
	swash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(swash)


func _update_swash(delta: float, p: Vector3) -> void:
	swash_t += delta
	var period := 9.0
	var ph := fposmod(swash_t, period) / period
	var sz: float = coast.shore_z(p.x)
	var run := pow(sin(PI * clampf(ph * 1.25, 0.0, 1.0)), 0.8)
	var front := sz - 0.6 - 6.0 * run
	var slope := 1.9 / (sz - COAST.BEACH0)
	swash.position = Vector3(p.x, coast.h(p.x, front) * 0.5 + 0.02, front + 4.5)
	swash.rotation.x = atan(slope)
	(swash.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0 - smoothstep(0.75, 1.0, ph) * 0.8)
	# the break: the sound arrives later and later
	if fposmod(swash_t - delta, period) > fposmod(swash_t, period):
		crash_q.append([clock + 0.05 + 1.7 * wrong, Vector3(p.x, 0.3, sz - 1.0)])
	while not crash_q.is_empty() and clock >= float(crash_q[0][0]):
		var c: Array = crash_q.pop_front()
		sound.play_at("distant_boom", {}, c[1], -10.0 + _near_sea(p) * 8.0)
		sound.play_at("splash", {}, c[1] + Vector3(0, 0, -2.0), -12.0 + _near_sea(p) * 8.0)


func _near_sea(p: Vector3) -> float:
	return 1.0 - clampf((coast.shore_z(p.x) - p.z) / 60.0, 0.0, 1.0)


func _gulls() -> void:
	gull_mesh = _gull_mesh(false)
	gull_wrong = _gull_mesh(true)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float rate = 5.0;
void vertex() {
	float s = sin(TIME * rate + float(INSTANCE_ID) * 1.7 + NODE_POSITION_WORLD.x);
	VERTEX.y += abs(VERTEX.x) * s * 0.45;
}
void fragment() { ALBEDO = mix(vec3(0.92), vec3(0.45, 0.47, 0.5), step(0.5, COLOR.r)); ROUGHNESS = 0.8; }
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	MatLib.register("l101_gull", m)
	for i in 7:
		var g := MeshInstance3D.new()
		g.name = "Gull%d" % i
		g.mesh = gull_mesh
		g.material_override = m
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.set_meta("r", rng.randf_range(12.0, 30.0))
		g.set_meta("c", Vector3(rng.randf_range(-60.0, 60.0), rng.randf_range(10.0, 22.0), COAST.SHORE + rng.randf_range(25.0, 110.0)))
		g.set_meta("w", rng.randf_range(0.18, 0.32) * (1.0 if rng.randf() < 0.5 else -1.0))
		g.set_meta("a", rng.randf() * TAU)
		g.scale = Vector3.ONE * 1.6
		add_child(g)
		gulls.append(g)


func _gull_mesh(baggy: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := [[Vector3(0, 0, -0.3), Vector3(0, 0, 0.25), Vector3(-0.85, 0.12, 0.0)],
		[Vector3(0, 0, -0.3), Vector3(0, 0, 0.25), Vector3(0.85, 0.12, 0.0)],
		[Vector3(-0.06, 0, -0.35), Vector3(0.06, 0, -0.35), Vector3(0, 0.05, 0.4)]]
	if baggy:
		# loose folds of skin hanging from the wings
		for s in [-1.0, 1.0]:
			tris.append([Vector3(0.1 * s, 0, -0.2), Vector3(0.75 * s, 0.1, 0.0), Vector3(0.45 * s, -0.55, 0.05)])
			tris.append([Vector3(0.05 * s, 0, 0.2), Vector3(0.4 * s, 0.05, 0.1), Vector3(0.2 * s, -0.7, 0.3)])
	for t in tris:
		for v in t:
			st.set_color(Color(1.0 if absf(v.x) > 0.6 else 0.0, 0, 0))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


func _update_gulls(delta: float, p: Vector3) -> void:
	for g in gulls:
		var a: float = float(g.get_meta("a")) + float(g.get_meta("w")) * delta
		g.set_meta("a", a)
		var c: Vector3 = g.get_meta("c")
		var rr: float = g.get_meta("r")
		var pos := Vector3(p.x + c.x + cos(a) * rr, c.y + sin(a * 2.0) * 1.5, c.z + sin(a) * rr)
		g.global_position = pos
		g.rotation.y = -a + (PI if float(g.get_meta("w")) < 0.0 else 0.0)
	if bad_gull != null:
		bad_t -= delta
		if bad_t <= 0.0:
			bad_gull.mesh = gull_mesh
			bad_gull = null
	gull_t -= delta
	if gull_t <= 0.0 and wrong > 0.2 and not SessionState.is_qa():
		gull_t = rng.randf_range(35.0, 80.0) * (1.2 - wrong)
		var cam := player.camera.global_transform
		for g in gulls:
			var to: Vector3 = (g as Node3D).global_position - cam.origin
			if to.length() > 70.0 and to.length() < 150.0 and (-cam.basis.z).dot(to.normalized()) > 0.85:
				bad_gull = g
				bad_gull.mesh = gull_wrong
				bad_t = 0.35
				_say("gull", "[for a moment the gull out over the water looks wrong - too much skin, hanging loose. Then it's only a gull.]", 5.0)
				break


# ---------------------------------------------------------------- things to find

func _things() -> void:
	var F0 := HOUSE.F0
	var F1 := HOUSE.F1
	# the spoken return, wherever you are ready
	var bed: Vector3 = house.anchors["bed"]
	var e1 := add_exit("L101>L000#1", "interact", bed + Vector3(1.2, 0.6, -1.0), Vector3(1.6, 1.4, 2.2), "Say: \"I'm ready to go back.\"")
	var deck: Vector3 = house.anchors["deck"]
	var e2 := add_exit("L101>L000#1", "interact", deck + Vector3(0, 0.8, 0), Vector3(2.2, 1.6, 2.0), "Say: \"I'm ready to go back.\"")
	var sz: float = coast.shore_z(0.6)
	var bz := sz - 9.0
	var e3 := add_exit("L101>L000#1", "interact", Vector3(0.6, coast.h(0.6, bz) + 0.9, bz), Vector3(4.0, 1.8, 4.0), "Say: \"I'm ready to go back.\"")
	for e in [e1, e2, e3]:
		if e:
			e.fired.connect(func(_id): Overlay.glitch(0.8))
	var ph: Vector3 = house.anchors["photo"]
	_photo_frame(ph)
	add_note("l101_photo", "Recovered photograph (Level 101)", "A beach on a windy day, the horizon tilted. Someone in a long coat and a scarf stands at the water's edge with their back to the camera.\n\nOn the back, in pencil:\n\"How was it so quiet? The wind and the sea rushed and howled, and still it was serene.\"\n\n(Photograph recovered from Level 101. The account it belongs to is first-person and unverified.)", ph + Vector3(0, 0.08, 0), Vector3(0.4, 0.2, 0.4), false)
	var fr: Vector3 = house.anchors["fridge"]
	add_interactable(fr, Vector3(1.0, 1.8, 1.0), "Look for almond water", func():
		Overlay.subtitle("[milk, juice, a jar of pickles. No almond water - and no shop you can think of has ever sold it. The word means nothing here.]", 6.0)
		_mark("almond"))
	var pc: Vector3 = house.anchors["computer"]
	add_interactable(pc, Vector3(1.2, 0.8, 1.4), "Search the web for \"almond water\"", func():
		Overlay.show_note("Search results", "almond water\n\nNo results found for \"almond water\".\nDid you mean: almond milk?\n\n(Every engine you try says the same. None of them has heard of it.)")
		_mark("search"))
	var mp: Vector3 = house.anchors["map"]
	_world_map(mp)
	add_interactable(mp, Vector3(1.6, 1.0, 0.5), "Look at the world map", func():
		Overlay.subtitle("[a world map, pinned up years ago. Australia... and east of it, only open sea. You can't remember what used to be there. Nobody else would notice.]", 7.0)
		_mark("map"))
	var shell := Vector3(1.8, 0.0, sz - 6.5)
	shell.y = coast.h(shell.x, shell.z) + 0.02
	_shell(shell)
	add_interactable(shell + Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 1.0), "Pick up the shell", func():
		Overlay.subtitle("[a large shell, smooth, purple and white. You turn it over with your thumbs. It is beautiful.]", 5.0)
		_mark("shell"))
	var dk: Vector3 = house.anchors["deck"] + Vector3(-1.6, 0.5, 0.6)
	add_note("l101_page", "A page, folded small (found on the deck)", "\"There it is again. That creeping feeling. The waves don't sound the way they move. The sun is a little too far to the left. The clouds go a fraction too fast.\n\nIt fades in a moment.\n\nSomeone calls from the house: ready to head in?\"\n\n(Unsigned. Testimony, not a report.)", dk, Vector3(0.4, 0.2, 0.4), true)


func _photo_frame(p: Vector3) -> void:
	var k := kit("Photo")
	k.box(p + Vector3(0, 0.1, 0), Vector3(0.03, 0.2, 0.15), "l101_door", GeoKit.ALL, false)
	k.box(p + Vector3(0.016, 0.1, 0), Vector3(0.004, 0.16, 0.11), "l101_stripe", GeoKit.ALL, false)
	k.commit()


func _shell(p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.06
	mi.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.74, 0.86)
	m.roughness = 0.3
	mi.material_override = m
	mi.position = p
	add_child(mi)


## A world map drawn from rough continent shapes. New Zealand is not on it.
func _world_map(p: Vector3) -> void:
	var img := Image.create(256, 128, false, Image.FORMAT_RGB8)
	img.fill(Color(0.55, 0.68, 0.74))
	var land := [[45, 38, 26, 18], [70, 30, 12, 8], [80, 78, 11, 22], [128, 36, 11, 9], [134, 70, 16, 22], [175, 38, 40, 18],
		[195, 62, 12, 10], [218, 92, 14, 9], [150, 82, 3, 7], [113, 31, 3, 4], [214, 40, 3, 6], [205, 72, 9, 3], [128, 120, 128, 6]]
	for e in land:
		for y in range(maxi(int(e[1]) - int(e[3]), 0), mini(int(e[1]) + int(e[3]) + 1, 128)):
			for x in range(maxi(int(e[0]) - int(e[2]), 0), mini(int(e[0]) + int(e[2]) + 1, 256)):
				var dx := float(x - int(e[0])) / float(e[2])
				var dy := float(y - int(e[1])) / float(e[3])
				if dx * dx + dy * dy < 1.0:
					img.set_pixel(x, y, Color(0.78, 0.72, 0.52))
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.3, 0.65)
	q.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.7
	q.material_override = m
	q.position = p
	q.rotation.y = PI
	add_child(q)
	var k := kit("MapFrame")
	k.box(p + Vector3(0, 0, 0.012), Vector3(1.38, 0.73, 0.02), "l101_door", GeoKit.ALL, false)
	k.commit()


func _mark(key: String) -> void:
	SaveService.record_discovery(stable_id, "l101:" + key, "Noticed an inconsistency in Level 101 (%s)." % key, "SOURCE")


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -20.0)
	beds["surf"] = sound.bed("water_bed", {"seconds": 8.0, "bright": 1600.0}, -30.0)
	beds["room"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 220.0, "rumble": 0.15}, -60.0)
	sound.emitter("transformer", house.anchors["fridge"], {"base": 58.0}, -24.0, 5.0)


func _mix(delta: float, p: Vector3) -> void:
	var inside: bool = p.x > HOUSE.X0 and p.x < HOUSE.X1 and p.z > HOUSE.Z0 and p.z < HOUSE.Z1
	var k := minf(delta * 2.0, 1.0)
	var ns := _near_sea(p)
	_vol("wind", (-34.0 if inside else -19.0) + ns * 3.0, k)
	_vol("surf", lerpf(-34.0, -14.0, ns) - (10.0 if inside else 0.0), k)
	_vol("room", -34.0 if inside else -70.0, k)


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	_rehome_dev26()
	if not SessionState.is_qa():
		_say("wake", "[you wake in your own bedroom. The light is right. The smell is right. Almost everything is right.]", 6.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	clock += delta
	var p := player.global_position
	if not SessionState.is_qa():
		wrong = clampf(pow(clock / WRONG_SECONDS, 1.15), 0.0, 1.0)
	_apply_wrong(delta)
	if absf(p.x - sea_cx) > 300.0:
		sea_cx = p.x
		sea.aabb.position.x = p.x - 1500.0
		if sea.surface_mesh:
			sea.surface_mesh.position.x = p.x
	_update_swash(delta, p)
	_update_gulls(delta, p)
	_mix(delta, p)
	if wrong > 0.22:
		_say("lamps", "[the street lamps look taller than you remember. Just a little.]", 5.0)
	if wrong > 0.45 and _near_sea(p) > 0.5:
		_say("lag", "[the crash of each wave reaches you a beat after it breaks]", 5.0)
	if wrong > 0.7:
		_say("sun", "[the sun is a little too far to the left. The clouds move a fraction too fast.]", 6.0)


func _apply_wrong(dt: float) -> void:
	cloud_t += dt * (1.0 + 3.0 * wrong)
	sky_mat.set_shader_parameter("cloud_t", cloud_t)
	sun.rotation_degrees = Vector3(-SUN.x, SUN.y - 16.0 * wrong, 0.0)
	if int(clock * 2.0) != int((clock - dt) * 2.0):
		for key in lamps.keys():
			for l in lamps[key]:
				_apply_lamp(l)


## The DEV26 overlay (data/dev26_curated_vignettes.json) drops three cues at
## fixed points that land outside this house. Move them onto the matching
## furniture and hide its marker glow and its oversized stand-in models; the
## interactions themselves are kept (core change requested in the report).
func _rehome_dev26() -> void:
	var ov := get_node_or_null("DEV26_CuratedAtmospheres")
	if ov == null:
		return
	var cues: Array = ov.get("site").get("cues", [])
	var targets: Array = [house.anchors["books"], house.anchors["coatrack"] + Vector3(0.3, 0, 0.35), house.anchors["cup"] - Vector3(0, 0.75, 0)]
	var orig: Array = []
	for c in cues:
		orig.append(Vector3(float(c["pos"][0]), float(c["pos"][1]), float(c["pos"][2])))
	for child in ov.get_children():
		if not (child is Node3D):
			continue
		var n := child as Node3D
		var best := -1
		var bd := 3.2
		for i in mini(orig.size(), targets.size()):
			var o: Vector3 = orig[i]
			var dd := Vector2(n.global_position.x - o.x, n.global_position.z - o.z).length()
			if dd < bd:
				bd = dd
				best = i
		if best < 0:
			continue
		n.global_position += (targets[best] as Vector3) - (orig[best] as Vector3)
		if str(n.name).begins_with("DEV26_Signal_") or str(n.name).begins_with("GLB_"):
			n.visible = false
	var amb := ov.get_node_or_null("DEV26_ProximityAmbience")
	if amb:
		for i in mini((amb.get("cues") as Array).size(), targets.size()):
			var t: Vector3 = targets[i]
			amb.get("cues")[i]["pos"] = [t.x, t.y, t.z]


# ---------------------------------------------------------------- QA stills

func _shots() -> void:
	var F0 := HOUSE.F0
	var F1 := HOUSE.F1
	add_shot("bedroom_waking", Vector3(-1.6, F1 + 1.6, 0.75), Vector3(-4.6, F1 + 0.7, 3.6), {"flashlight": false})
	add_shot("street_lamps", Vector3(-20.0, 1.7, -3.2), Vector3(40.0, 3.4, -5.6), {"flashlight": false, "prepare": _prep_lamps})
	add_shot("living_room", Vector3(-1.5, F0 + 1.6, 5.6), Vector3(-4.6, F0 + 0.8, 0.8), {"flashlight": false})
	add_shot("dune_to_sea", Vector3(0.9, coast.h(0.6, 34.0) + 1.7, 34.0), Vector3(-12.0, 0.0, 110.0), {"flashlight": false})
	var sz: float = coast.shore_z(8.0)
	add_shot("shore", Vector3(8.0, coast.h(8.0, sz - 7.0) + 1.65, sz - 7.0), Vector3(-30.0, 0.4, sz + 22.0), {"flashlight": false})


func _prep_lamps() -> void:
	wrong = 0.55
	for key in lamps.keys():
		for l in lamps[key]:
			_apply_lamp(l)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "three places to say the words (one edge)", "ok": exits.size() == 3})
	out.append({"what": "wake upstairs, inside the home", "ok": (arrivals["start"] as Transform3D).origin.y > HOUSE.F1 - 0.1})
	var space := get_world_3d().direct_space_state
	var mz: float = (HOUSE.STAIR_Z0 + house.stair_top_z()) * 0.5
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.575, HOUSE.F1 + 0.5, mz), Vector3(0.575, -1.0, mz), 1))
	var mid_y: float = (HOUSE.F0 + HOUSE.F1) * 0.5
	out.append({"what": "stair collision ramp halfway between the floors", "ok": not hit.is_empty() and absf(float(hit["position"].y) - mid_y) < 0.35, "detail": hit.get("position", null)})
	var hit2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-0.5, HOUSE.F1 + 1.0, 8.5), Vector3(-0.5, HOUSE.F0, 8.5), 1))
	out.append({"what": "landing floor at first-floor height", "ok": not hit2.is_empty() and absf(float(hit2["position"].y) - HOUSE.F1) < 0.1, "detail": hit2.get("position", null)})
	out.append({"what": "wrongness starts at zero", "ok": wrong == 0.0})
	out.append({"what": "street lamps placed", "ok": not lamps.is_empty()})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
