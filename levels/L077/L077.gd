extends LevelBase
## Level 77 - "Oh, Shenandoah" (Backrooms Wikidot rev 25, accessed 2026-11-04;
## cite: DrAkimoto, CC BY-SA 3.0). Dossier: docs/canon/levels/L077.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: steep, undulating hills and valleys (under 1 m to ~80 m, median
## ~25 m) of zoysia grass, bluegrass and moss on loam, in constant daylight;
## one constant condition, fog, densest in the valleys and crevices; no
## standing fresh water; ~15,000 Shenandoah Sheep that drink the fog through
## their lungs; a dense deciduous forest all round that appears nightbound,
## home to a Nguithr'xurh super-colony (sub-clusters, a possible hatchery,
## highest concentration within 1 km of the border, never in the hills; 95%
## of unaligned travelers do not survive it); all entrances arrive in that
## forest ~4 km from the border; the only exit is beyond 6 km in the forest,
## a 65% chance to no-clip through the detritus; Samuel Murphy's 1938 diary
## names the hills New Shenandoah.
## ADAPTATION: hills scaled to ~0.45 km2 (border radius ~380 m), forest depth
## read at 1 m = 40 m (4 km = 100 m in, 6 km = 150 m in); the estate is not
## built (page: its inner workings are unknown); the silk sheets and egg sacs
## of the sub-clusters follow the page's hatchery caption; one stone cairn on
## the highest crest holds the diary page (a direction aid, page: exploring
## is ill-advised without one).
## Mechanic: a bisected day: the light, sky and fog follow how deep into the
## forest you are (hills seen from the trees still glow with daylight);
## Nguithr'xurh threat builds while you linger beside a sub-cluster; beyond
## 6 km each detritus heap rolls its 65% once when you first reach it, and an
## open heap lets you push through. Sheep graze and drift in loose flocks.
## Verticality: the hills themselves (valley floors to ~70 m crests).
## Helpers: L077_land.gd (terrain), L077_life.gd (trees, sheep, silk, litter).

const LAND := preload("res://levels/L077/L077_land.gd")
const LIFE := preload("res://levels/L077/L077_life.gd")
const EXIT_ID := "L077>EXT#1"
const CS := 64.0
const TREE_REACH := 120.0
const A_IN := PI * 0.5 + 0.3        # bearing of the entrance ring used for arrivals

var land
var life
var world: ChunkWorld
var land_mat: ShaderMaterial
var sky_mat: ShaderMaterial
var start := Vector3.ZERO
var face_in := 0.0
var qa_pile := Vector3.ZERO
var flocks: Array = []
var clusters: Dictionary = {}        # Vector2i -> [{pos, glints}]
var piles: Array = []                # [{pos, open, rolled, trig}]
var night := 1.0
var threat := 0.0
var said := {}
var bleats: Array = []
var bleat_t := 5.0
var bleat_pl: AudioStreamPlayer3D
var beds := {}
var cairn := Vector3.ZERO
var _flock_t := 0.0
var _blink_t := 0.0
var _scratch_t := 3.0
var freeze_light := -1.0
var fog_mats: Array = []


func build() -> void:
	land = LAND.new()
	life = LIFE.new()
	rules["view_distance"] = 2800.0
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -60.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.05
	outdoor_env(Color(0.45, 0.55, 0.66), Color(0.78, 0.8, 0.8), Color(0.3, 0.32, 0.3), Vector2(52.0, 35.0),
		Color(1.0, 0.96, 0.88), 1.1, Color(0.74, 0.76, 0.76), 0.0024)
	var sh := Shader.new()
	sh.code = SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	environment.sky.sky_material = sky_mat
	environment.ambient_light_sky_contribution = 0.7
	environment.fog_sky_affect = 0.22
	environment.fog_height = 11.0
	environment.fog_height_density = 0.09
	environment.fog_aerial_perspective = 0.2
	environment.tonemap_exposure = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 90.0
	land_mat = land.make_material()
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	land.build_meshes(geo, land_mat, TREE_REACH)
	_fog_banks()
	var a := A_IN
	var rr: float = land.border_r(a) + land.ARRIVE_D
	start = Vector3(cos(a) * rr, 0.0, sin(a) * rr)
	start.y = land.h(start.x, start.z) + 0.05
	face_in = rad_to_deg(atan2(start.x, start.z))
	var pr: float = land.border_r(a + 0.02) + land.EXIT_D + 16.0
	qa_pile = Vector3(cos(a + 0.02) * pr, 0.0, sin(a + 0.02) * pr)
	qa_pile.y = land.h(qa_pile.x, qa_pile.z)
	_pile(self, qa_pile, rng, true)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	world.chunk_unloaded.connect(func(k): clusters.erase(k))
	add_child(world)
	world.build_around(start, 2)
	_flocks()
	_cairn()
	_sounds()
	add_arrival("start", start, face_in)
	add_landmark("Highest crest and the cairn", cairn)
	add_landmark("Forest border (nightbound)", Vector3(cos(a), 0, sin(a)) * land.border_r(a))
	add_landmark("Detritus heap beyond 6 km", qa_pile)
	_shots()


const SKY := """
shader_type sky;
uniform float night = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec3 day = mix(vec3(0.8, 0.82, 0.82), vec3(0.46, 0.58, 0.72), smoothstep(0.0, 0.7, y));
	float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
	day += vec3(1.0, 0.96, 0.86) * (pow(s, 900.0) * 6.0 + pow(s, 12.0) * 0.22);
	vec3 nt = mix(vec3(0.012, 0.014, 0.022), vec3(0.002, 0.003, 0.008), smoothstep(0.0, 0.6, y));
	vec2 g = floor(vec2(atan(d.x, d.z) * 180.0, d.y * 260.0));
	float st = step(0.9965, hsh(g)) * smoothstep(0.05, 0.3, y) * (0.4 + 0.6 * hsh(g + 3.1));
	nt += vec3(st) * 0.7;
	vec3 col = mix(day, nt, night);
	if (d.y < 0.0) { col = mix(vec3(0.62, 0.64, 0.64), vec3(0.005), night); }
	COLOR = col;
}
"""


## Valley fog: two soft horizontal banks across the hills. Crests stand out of
## them; inside a valley you are in the bank (page: fog is densest in the
## valleys and crevices).
func _fog_banks() -> void:
	var sh := Shader.new()
	sh.code = FOG
	for spec in [[9.5, 0.75, 0.016], [16.5, 0.4, 0.009]]:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("strength", spec[1])
		m.set_shader_parameter("scale", spec[2])
		m.set_shader_parameter("rb", land.RB)
		fog_mats.append(m)
		var mi := MeshInstance3D.new()
		mi.name = "FogBank_%d" % int(spec[0])
		var pm := PlaneMesh.new()
		pm.size = Vector2(900, 900)
		mi.mesh = pm
		mi.material_override = m
		mi.position = Vector3(0, spec[0], 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


const FOG := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform float strength = 0.6;
uniform float scale = 0.015;
uniform float rb = 380.0;
uniform float lum = 1.0;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p = p * 2.03 + vec2(4.1, 1.7); a *= 0.5; } return s; }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = fbm(wp.xz * scale + vec2(TIME * 0.004, TIME * 0.002));
	float a = smoothstep(0.3, 0.75, n) * strength;
	a *= 1.0 - smoothstep(rb - 60.0, rb + 10.0, length(wp.xz));
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float scene_z = -v.z / v.w;
	float frag_z = -VERTEX.z;
	a *= clamp((scene_z - frag_z) / 9.0, 0.0, 1.0);
	a *= smoothstep(3.0, 40.0, frag_z);
	if (CAMERA_POSITION_WORLD.y < wp.y) { a *= 0.45; }
	ALBEDO = vec3(0.86, 0.88, 0.88) * lum;
	ALPHA = clamp(a, 0.0, 0.95);
}
"""


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var cc := Vector2(ox + CS * 0.5, oz + CS * 0.5)
	var dc: float = land.dist(cc.x, cc.y)
	land.collision_tile(node, ox, oz, int(CS), "dirt" if dc > 0.0 else "grass")
	var r := RandomNumberGenerator.new()
	r.seed = hash([cx, cz, level_seed, 77])
	if dc < 30.0:
		var tufts: Array = []
		var org := Vector3(cc.x, land.h(cc.x, cc.y), cc.y)
		for i in 650:
			var x := ox + r.randf() * CS
			var z := oz + r.randf() * CS
			if land.dist(x, z) > 2.0:
				continue
			var s := r.randf_range(0.7, 1.5)
			tufts.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, land.h(x, z) - 0.03, z) - org))
		if not tufts.is_empty():
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = life.tuft
			mm.instance_count = tufts.size()
			for i in tufts.size():
				mm.set_instance_transform(i, tufts[i])
			var mi := MultiMeshInstance3D.new()
			mi.multimesh = mm
			mi.position = org
			mi.material_override = life.tuft_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = 70.0
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			node.add_child(mi)
	if dc < -60.0:
		return {"d": dc}
	var by_kind := {}
	var trunks: Array = []
	var body := StaticBody3D.new()
	body.name = "Boles"
	node.add_child(body)
	var step := 5.8
	var n := int(CS / step)
	for j in n:
		for i in n:
			var x := ox + (i + r.randf_range(0.1, 0.9)) * step
			var z := oz + (j + r.randf_range(0.1, 0.9)) * step
			var d: float = land.dist(x, z)
			var pw := smoothstep(-4.0, 9.0, d) * 0.82
			if r.randf() > pw:
				continue
			var p := Vector3(x, 0, z)
			if _keep_clear(p):
				continue
			p.y = land.h(x, z)
			var kind := r.randi() % 5
			var s := r.randf_range(0.85, 1.3)
			var xf := Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * r.randf_range(0.95, 1.15), s)), p + Vector3(0, -0.2, 0))
			if not by_kind.has(kind):
				by_kind[kind] = []
			by_kind[kind].append(xf)
			trunks.append(p)
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = (0.32 + kind * 0.05) * s * 1.2
			cyl.height = 6.0
			cs.shape = cyl
			cs.position = p + Vector3(0, 2.6, 0)
			cs.set_meta("surface", "wood")
			body.add_child(cs)
	life.commit_trees(node, by_kind, TREE_REACH, Vector3(cc.x, land.h(cc.x, cc.y), cc.y))
	if trunks.is_empty():
		return {"d": dc}
	# deadfall
	for k in r.randi_range(1, 3):
		var tp: Vector3 = trunks[r.randi() % trunks.size()] + Vector3(r.randf_range(-3, 3), 0, r.randf_range(-3, 3))
		if _keep_clear(tp):
			continue
		tp.y = land.h(tp.x, tp.z) + 0.05
		Props.place(self, node, "ph/dead_tree_trunk", tp, r.randf_range(0, 360), r.randf_range(0.45, 0.7), false, false)
	# Nguithr'xurh sub-clusters: thickest within "1 km" (25 m) of the border
	var cl: Array = []
	var want := 0
	if dc > -10.0 and dc < 45.0:
		want = r.randi_range(1, 3)
	elif dc >= 45.0 and r.randf() < 0.3:
		want = 1
	for k in want:
		var c: Vector3 = trunks[r.randi() % trunks.size()]
		if c.distance_to(start) < 30.0 or _near_route(c, 14.0):
			continue
		var near: Array = []
		for t in trunks:
			if (t as Vector3).distance_to(c) < 8.0:
				near.append(t)
		var dense: bool = land.dist(c.x, c.z) < 28.0 and r.randf() < 0.6
		var gl: Array = life.cluster(node, c, near, r, dense)
		cl.append({"pos": c, "glints": gl})
	if not cl.is_empty():
		clusters[Vector2i(cx, cz)] = cl
	# beyond 6 km: detritus heaps that may let you through (not in QA: the
	# nav check would demand every streamed heap be reachable)
	if not SessionState.is_qa() and dc > land.EXIT_D + 10.0 and r.randf() < 0.45:
		var hp: Vector3 = trunks[r.randi() % trunks.size()] + Vector3(r.randf_range(2.5, 3.5), 0, r.randf_range(-1, 1))
		hp.y = land.h(hp.x, hp.z)
		_pile(node, hp, r, false)
	return {"d": dc}


func _keep_clear(p: Vector3) -> bool:
	return Vector2(p.x - start.x, p.z - start.z).length() < 4.0 or Vector2(p.x - qa_pile.x, p.z - qa_pile.z).length() < 4.5


## The straight line from the arrival out to the authored heap.
func _near_route(p: Vector3, w: float) -> bool:
	var a := Vector2(start.x, start.z)
	var b := Vector2(qa_pile.x, qa_pile.z)
	var q := Vector2(p.x, p.z)
	var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	return q.distance_to(a.lerp(b, t)) < w


func _pile(parent: Node3D, p: Vector3, r: RandomNumberGenerator, authored: bool) -> void:
	var sz: Vector3 = life.detritus(self, parent, p, r)
	var rec := {"pos": p, "open": false, "rolled": false, "authored": authored}
	var t := make_exit(EXIT_ID, "noclip", p + Vector3(0, 1.0, 0), Vector3(sz.x + 2.2, 2.4, sz.z + 2.2), "Push on into the detritus", parent)
	if t:
		t.hold_seconds = 2.5
		t.condition = func() -> bool: return bool(rec["open"]) and land.depth_km(p.x, p.z) > 6.0
		rec["trig"] = t
	piles.append(rec)


# ---------------------------------------------------------------- the flocks

func _flocks() -> void:
	var root := Node3D.new()
	root.name = "Flocks"
	add_child(root)
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 7707
	var tries := 0
	while flocks.size() < 15 and tries < 400:
		tries += 1
		var c := Vector3(r.randf_range(-320, 320), 0, r.randf_range(-320, 320))
		if land.dist(c.x, c.z) > -45.0:
			continue
		var ok := true
		for f in flocks:
			if (f["c"] as Vector3).distance_to(c) < 70.0:
				ok = false
		if not ok:
			continue
		_flock(root, c, r.randi_range(12, 30), r)
	# one flock guaranteed in view where the forest opens onto the hills
	var a := A_IN
	var edge: float = land.border_r(a) - 55.0
	_flock(root, Vector3(cos(a) * edge, 0, sin(a) * edge), 18, r)


func _flock(root: Node3D, c: Vector3, n: int, r: RandomNumberGenerator) -> void:
	var sheep: Array = []
	for i in n:
		var p := c + Vector3(r.randf_range(-14, 14), 0, r.randf_range(-14, 14))
		sheep.append({"p": p, "yaw": r.randf() * TAU, "tgt": p, "t": r.randf_range(0, 8), "graze": r.randf() < 0.6})
	var mms: Array = []
	for variant in 2:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = life.sheep_up if variant == 0 else life.sheep_down
		mm.instance_count = n
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = life.wool_mat
		mi.visibility_range_end = 260.0
		mi.position = c
		root.add_child(mi)
		mms.append(mm)
	var f := {"c": c, "sheep": sheep, "mm": mms}
	flocks.append(f)
	_pose_flock(f)


func _pose_flock(f: Dictionary) -> void:
	var sheep: Array = f["sheep"]
	for i in sheep.size():
		var s: Dictionary = sheep[i]
		var p: Vector3 = s["p"]
		var nrm: Vector3 = land.normal_at(p.x, p.z, 0.8)
		var fwd := Vector3(sin(s["yaw"]), 0, cos(s["yaw"]))
		var right := nrm.cross(fwd).normalized()
		fwd = right.cross(nrm).normalized()
		var c: Vector3 = f["c"]
		var xf := Transform3D(Basis(right, nrm, fwd), Vector3(p.x - c.x, land.h(p.x, p.z) - 0.04 - c.y, p.z - c.z))
		var zero := Transform3D(Basis().scaled(Vector3.ZERO), xf.origin)
		(f["mm"][0] as MultiMesh).set_instance_transform(i, zero if s["graze"] else xf)
		(f["mm"][1] as MultiMesh).set_instance_transform(i, xf if s["graze"] else zero)


func _update_flocks(delta: float, pp: Vector3) -> void:
	for f in flocks:
		if (f["c"] as Vector3).distance_to(pp) > 180.0:
			continue
		var c: Vector3 = f["c"]
		for s in f["sheep"]:
			s["t"] -= delta
			var p: Vector3 = s["p"]
			if s["t"] <= 0.0:
				s["t"] = rng.randf_range(4.0, 12.0)
				s["graze"] = rng.randf() < 0.55
				if not s["graze"]:
					s["tgt"] = c + Vector3(rng.randf_range(-16, 16), 0, rng.randf_range(-16, 16))
			var tgt: Vector3 = s["tgt"]
			var to := Vector3(tgt.x - p.x, 0, tgt.z - p.z)
			# keep a little distance from a walker
			var away := Vector3(p.x - pp.x, 0, p.z - pp.z)
			if away.length() < 6.0:
				to += away.normalized() * 6.0
				s["graze"] = false
			if not s["graze"] and to.length() > 0.4:
				var want := atan2(to.x, to.z)
				s["yaw"] = lerp_angle(s["yaw"], want, minf(delta * 1.5, 1.0))
				p += Vector3(sin(s["yaw"]), 0, cos(s["yaw"])) * delta * (0.5 if away.length() > 6.0 else 1.3)
				if land.dist(p.x, p.z) < -20.0:
					s["p"] = p
		_pose_flock(f)


# ---------------------------------------------------------------- dressing

func _cairn() -> void:
	var best := Vector3.ZERO
	var bh := -INF
	for gz in range(-28, 29):
		for gx in range(-28, 29):
			var x := gx * 10.0
			var z := gz * 10.0
			if land.dist(x, z) > -90.0:
				continue
			var y: float = land.h(x, z)
			if y > bh:
				bh = y
				best = Vector3(x, y, z)
	cairn = best
	var root := Node3D.new()
	root.name = "Cairn"
	add_child(root)
	var r := RandomNumberGenerator.new()
	r.seed = 7799
	var ids := ["kenney/nature-kit/rock-talld", "kenney/nature-kit/rock-tallc", "kenney/nature-kit/rock-smalld", "kenney/nature-kit/rock-smalla"]
	for i in 9:
		var a := TAU * i / 9.0
		var rr := 0.75 - (i / 9) * 0.3
		var p := best + Vector3(cos(a) * rr, -0.1 + float(i) / 9.0 * 0.6, sin(a) * rr)
		Props.place(self, root, ids[i % ids.size()], p, r.randf_range(0, 360), r.randf_range(0.35, 0.6))
	Props.place(self, root, "kenney/nature-kit/rock-tallc", best + Vector3(0, 0.45, 0), 20.0, 0.9, true)
	add_note("l77_diary", "A diary page in an oilcloth wrap, wedged in the cairn",
		"Samuel Murphy, 15 February 1938 (paraphrased; the hand is shaky).\n\nHe is old and, he admits, wistful for no reason. The flock is plentiful, the homestead comfortable, his trading left him wanting nothing.\n\nHis son Jacob has promised not to over-cull and to keep count of the flock. He is proud of Jacob, his siblings and the grandchildren.\n\nThey never named the place. So, in his last hours: \"we call these hills, New Shenandoah.\"",
		best + Vector3(0.9, 0.55, 0.2), Vector3(0.45, 0.2, 0.4))
	add_note("l77_survey", "Wanderer's survey card (laminated)",
		"Level 77 - the 'Sheephole' to B.N.T.G. traders.\n\n- About 25 km2 of steep hills, valleys to ~80 m crests. Constant daylight here; the forest round it is always night.\n- Fog never lifts. It is worst in the valleys. Take a bearing on high ground or do not move.\n- No standing fresh water anywhere. The sheep drink the fog.\n- NEVER camp in the trees. Nguithr'xurh, 60 cm and bigger, millions. Densest within 1 km of the edge.\n- Out past 6 km in the forest the litter sometimes gives way under you. About two times in three.",
		best + Vector3(-0.7, 0.5, 0.6), Vector3(0.4, 0.2, 0.35))
	# a note where the trees open onto the hills, for anyone arriving
	var a := A_IN
	var er: float = land.border_r(a) - 6.0
	var ep := Vector3(cos(a) * er, 0, sin(a) * er)
	ep.y = land.h(ep.x, ep.z)
	Props.place(self, root, "kenney/nature-kit/rock-talle", ep + Vector3(1.2, -0.05, 0.3), 40.0, 0.7, true)
	add_note("l77_edge", "Scratched into a flat stone at the treeline",
		"OUT OF THE TREES = SAFE FROM THEM.\nThey have never come onto the grass. Not once.\nDo not go back in unless you mean to leave.",
		ep + Vector3(1.2, 0.72, 0.3), Vector3(0.5, 0.15, 0.4), false)
	var fl: Vector3 = flocks[flocks.size() - 1]["c"]
	add_interactable(Vector3(fl.x, land.h(fl.x, fl.z) + 0.8, fl.z), Vector3(5.0, 1.6, 5.0), "Look closely at the sheep", func():
		Overlay.subtitle("[their fleeces are beaded with fog. There is no water to drink anywhere here; they breathe it in]", 5.5)
		SaveService.record_discovery(stable_id, "l77:sheep", "Shenandoah Sheep take their water from the fog.", "SOURCE"))


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -26.0)
	beds["night"] = sound.bed("crickets", {"seconds": 6.0}, -60.0)
	beds["tone"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0, "rumble": 0.3}, -60.0)
	for k in 3:
		bleats.append(_bleat_stream(250.0 + k * 55.0, 0.75 + k * 0.12))
	bleat_pl = AudioStreamPlayer3D.new()
	bleat_pl.bus = "Ambience"
	bleat_pl.max_distance = 140.0
	bleat_pl.unit_size = 12.0
	add_child(bleat_pl)


## A synthesised sheep bleat: a buzzy, falling glottal tone with the fast
## tremolo of a "baa", shaped by two vowel formants.
func _bleat_stream(f0: float, dur: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var ph := 0.0
	for i in n:
		var t := float(i) / rate
		var env := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(dur * 0.55, dur, t))
		var f := f0 * (1.08 - 0.16 * t / dur) * (1.0 + 0.035 * sin(TAU * 21.0 * t))
		ph += TAU * f / rate
		var v := 0.0
		for k in range(1, 13):
			var fk := f * k
			var g := exp(-pow((fk - 720.0) / 260.0, 2.0)) + 0.55 * exp(-pow((fk - 1250.0) / 320.0, 2.0)) + 0.25 * exp(-pow((fk - 2600.0) / 500.0, 2.0)) + 0.05 / k
			v += sin(ph * k) * g
		v *= env * (0.65 + 0.35 * sin(TAU * 21.0 * t)) * 0.32
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	world.target = player


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	var d: float = land.dist(pp.x, pp.z)
	var qa := SessionState.is_qa()
	var want := smoothstep(-12.0, 22.0, d) if freeze_light < 0.0 else freeze_light
	night = move_toward(night, want, delta * 0.6) if freeze_light < 0.0 else want
	_apply_light()
	_flock_t -= delta
	if _flock_t <= 0.0:
		_flock_t = 0.1
		_update_flocks(0.1, pp)
	_colony(delta, pp, qa)
	_heaps(pp, qa)
	_audio(delta, pp, d)
	if not said.has("hills") and d < -25.0 and not qa:
		said["hills"] = true
		Overlay.subtitle("[daylight, and fog lying in the valleys. Somewhere a sheep calls.]", 4.5)
	if not said.has("trees") and d > 12.0 and not qa and said.has("hills"):
		said["trees"] = true
		Overlay.subtitle("[under the trees it is night again]", 3.5)


func _apply_light() -> void:
	var n := night
	sun.light_energy = lerpf(1.1, 0.07, n)
	sun.light_color = Color(1.0, 0.96, 0.88).lerp(Color(0.55, 0.65, 0.9), n)
	sun.shadow_enabled = n < 0.9
	sky_mat.set_shader_parameter("night", n)
	environment.ambient_light_energy = lerpf(0.75, 0.25, n)
	environment.fog_light_color = Color(0.74, 0.76, 0.76).lerp(Color(0.006, 0.007, 0.011), n)
	environment.fog_density = lerpf(0.0024, 0.0075, n)
	environment.fog_height_density = lerpf(0.09, 0.02, n)
	for m in fog_mats:
		(m as ShaderMaterial).set_shader_parameter("lum", 1.0 - 0.9 * n)
	var fk := lerpf(0.28, 1.0, n)
	land_mat.set_shader_parameter("forest_k", fk)
	fk = lerpf(0.14, 1.0, n)
	land_mat.set_shader_parameter("day_glow", n * 0.3)
	life.set_dark(fk)


func _colony(delta: float, pp: Vector3, qa: bool) -> void:
	var nearest := INF
	var k := world.key_at(pp)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for c in clusters.get(k + Vector2i(dx, dz), []):
				nearest = minf(nearest, (c["pos"] as Vector3).distance_to(pp))
	if nearest < 11.0:
		threat += delta
	else:
		threat = maxf(0.0, threat - delta * 0.5)
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = rng.randf_range(0.6, 2.0)
		for key in clusters.keys():
			for c in clusters[key]:
				for g in c["glints"]:
					if is_instance_valid(g):
						(g as Node3D).visible = rng.randf() < 0.55
	if qa:
		return
	if threat > 4.0 and not said.has("chitter"):
		said["chitter"] = true
		Overlay.subtitle("[a dry clicking in the silk, close by, then many more answering it]", 4.5)
	if threat > 12.0 and not said.has("move"):
		said["move"] = true
		Overlay.subtitle("[something heavy shifts in the web above you. Move.]", 3.5)
	Overlay.set_screen_effect("vignette", 0.25 + clampf(threat / 18.0, 0.0, 1.0) * 0.4)
	if threat > 18.0 and player.has_method("hurt"):
		threat = 0.0
		player.hurt(1000.0, "Level 77: lingered beside a Nguithr'xurh sub-cluster")


func _heaps(pp: Vector3, qa: bool) -> void:
	for rec in piles:
		var p: Vector3 = rec["pos"]
		if not rec["rolled"] and p.distance_to(pp) < 14.0 and land.depth_km(p.x, p.z) > 6.0:
			rec["rolled"] = true
			rec["open"] = true if qa and rec["authored"] else rng.randf() < 0.65
			if not qa and not said.has("heap"):
				said["heap"] = true
				Overlay.subtitle("[more than 6 km in. The litter here is deep enough to sink into]", 4.0)
		var t = rec.get("trig")
		if t != null and is_instance_valid(t) and rec["rolled"] and not rec["open"] and not qa:
			if (t as ExitTrigger)._inside != null and not said.has("solid_" + str(p)):
				said["solid_" + str(p)] = true
				Overlay.subtitle("[only leaves and rotten wood. It does not give.]", 3.0)


func _audio(delta: float, pp: Vector3, d: float) -> void:
	var k := minf(delta * 1.2, 1.0)
	_vol("wind", lerpf(-24.0, -40.0, night), k)
	_vol("night", lerpf(-60.0, -24.0, night), k)
	_vol("tone", lerpf(-60.0, -30.0, night), k)
	bleat_t -= delta
	if bleat_t <= 0.0:
		bleat_t = rng.randf_range(5.0, 13.0)
		var best: Dictionary = {}
		var bd := 150.0
		for f in flocks:
			var dd := (f["c"] as Vector3).distance_to(pp)
			if dd < bd:
				bd = dd
				best = f
		if not best.is_empty() and d < 40.0:
			var c: Vector3 = best["c"]
			bleat_pl.global_position = Vector3(c.x, land.h(c.x, c.z) + 1.0, c.z)
			bleat_pl.stream = bleats[rng.randi() % bleats.size()]
			bleat_pl.pitch_scale = rng.randf_range(0.9, 1.15)
			bleat_pl.volume_db = -6.0
			bleat_pl.play()
			if not SessionState.is_qa():
				Overlay.subtitle("[a sheep bleats, somewhere in the fog]", 2.0)
	_scratch_t -= delta
	if _scratch_t <= 0.0:
		_scratch_t = rng.randf_range(3.0, 8.0)
		if threat > 1.0 or (d > 0.0 and d < 40.0 and rng.randf() < 0.4):
			var a := rng.randf() * TAU
			sound.play_at("scratch", {}, pp + Vector3(cos(a) * 6.0, 2.0, sin(a) * 6.0), -14.0, "[clicking in the trees]")


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)


# ---------------------------------------------------------------- QA stills

func _shots() -> void:
	var a := A_IN
	add_shot("night_forest_arrival", start + Vector3(0, 1.62, 0), start + Vector3(-cos(a) * 30.0, 2.5, -sin(a) * 30.0),
		{"flashlight": true, "prepare": _prep.bind(start, 1.0)})
	# the flock nearest the hills' centre, seen from the higher ground beside it
	var fl: Vector3 = flocks[0]["c"]
	for f in flocks:
		if (f["c"] as Vector3).length() < fl.length():
			fl = f["c"]
	fl.y = land.h(fl.x, fl.z)
	var ec := fl
	for k in 12:
		var q: Vector3 = fl + Vector3(cos(TAU * k / 12.0), 0, sin(TAU * k / 12.0)) * 30.0
		q.y = land.h(q.x, q.z)
		if q.y > ec.y:
			ec = q
	ec.y += 1.7
	add_shot("flock_in_valley_fog", ec, fl + (fl - ec).normalized() * 25.0 + Vector3(0, -1.0, 0),
		{"flashlight": false, "prepare": _prep.bind(ec, 0.0)})
	var cp := cairn + Vector3(-3.0, 1.65, -3.0)
	add_shot("crest_over_fog", cp, cairn + Vector3(-120.0, -30.0, -150.0), {"flashlight": false, "prepare": _prep.bind(cp, 0.0)})
	var wp: Vector3 = Vector3(cos(a), 0, sin(a)) * (land.border_r(a) - 70.0)
	wp.y = land.h(wp.x, wp.z) + 1.65
	add_shot("forest_wall_from_hills", wp, Vector3(cos(a), 0, sin(a)) * (land.border_r(a) + 30.0) + Vector3(0, wp.y + 4.0, 0),
		{"flashlight": false, "prepare": _prep.bind(wp, 0.0)})


func _prep(p: Vector3, n: float) -> void:
	freeze_light = n
	night = n
	_apply_light()
	world.build_around(p, 2)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "one sourced exit kind (no-clip through detritus)", "ok": exits.size() >= 1 and (exits[0] as ExitTrigger).kind == "noclip"})
	out.append({"what": "arrival is in the forest ~4 km from the border", "ok": absf(land.depth_km(start.x, start.z) - 4.0) < 0.3, "detail": land.depth_km(start.x, start.z)})
	out.append({"what": "authored detritus heap lies beyond 6 km", "ok": land.depth_km(qa_pile.x, qa_pile.z) > 6.0, "detail": land.depth_km(qa_pile.x, qa_pile.z)})
	var none_in_hills := true
	for key in clusters.keys():
		for c in clusters[key]:
			if land.dist((c["pos"] as Vector3).x, (c["pos"] as Vector3).z) < -6.0:
				none_in_hills = false
	out.append({"what": "no Nguithr'xurh sub-cluster in the central hills", "ok": none_in_hills})
	var crest: float = land.h(cairn.x, cairn.z)
	out.append({"what": "hills rise to tens of metres (crest height)", "ok": crest > 40.0 and crest < 90.0, "detail": crest})
	out.append({"what": "flocks of sheep present", "ok": flocks.size() >= 10})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
