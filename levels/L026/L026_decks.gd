extends RefCounted
## Level 26 lower decks: "infinite" corridors and party rooms reached by elevator, as a
## ChunkWorld window (24 m chunks) far from the hull. Every chunk is a crossing of two
## corridors branching to all four compass points, with a room in each quadrant. Along
## the hub hallway (chunk row 0) the same birthday room repeats: Liminal Echo's clones.
## Unwatched chunks may be rebuilt with new contents (spontaneous generation of items).

const CS := 24.0
const IX := 125                # hub chunk x key: interior lies at x ~ 3000 m
const DY := -100.0             # interior floor height
const H := 2.8
const A := 10.5                # corridor edges
const B := 13.5
const THEMES := ["birthday", "movie", "xmas", "halloween", "plain", "trap", "dark", "closed", "closed"]
const BALLOON_COLORS := [Color(0.9, 0.12, 0.15), Color(0.15, 0.4, 0.95), Color(0.98, 0.8, 0.1), Color(0.2, 0.75, 0.3),
	Color(0.85, 0.3, 0.8), Color(1.0, 0.5, 0.1), Color(0.95, 0.95, 0.95)]

var L
var seed_base := 0
var balloon_mesh: SphereMesh
var hat_mesh: CylinderMesh
var confetti_mesh: PlaneMesh
var cmat: StandardMaterial3D
var grin_mat: ShaderMaterial

const GRIN := """
shader_type spatial;
render_mode cull_back;
uniform vec3 base : source_color = vec3(0.8, 0.1, 0.1);
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float mouth = 1.0 - smoothstep(0.02, 0.05, abs(length(p * vec2(1.0, 1.6) - vec2(0.0, -0.05)) - 0.32));
	mouth *= step(p.y, 0.0) * step(0.25, UV.x) * step(UV.x, 0.75) * step(0.45, UV.y) * step(UV.y, 0.62);
	float teeth = step(0.5, fract(UV.x * 40.0)) * mouth;
	ALBEDO = mix(base, vec3(0.95, 0.93, 0.85), teeth);
	ALBEDO = mix(ALBEDO, vec3(0.05, 0.0, 0.0), mouth * (1.0 - teeth));
	ROUGHNESS = 0.25;
}
"""


func _init(level, s: int) -> void:
	L = level
	seed_base = s
	balloon_mesh = SphereMesh.new()
	balloon_mesh.radius = 0.15
	balloon_mesh.height = 0.38
	balloon_mesh.radial_segments = 10
	balloon_mesh.rings = 6
	hat_mesh = CylinderMesh.new()
	hat_mesh.top_radius = 0.0
	hat_mesh.bottom_radius = 0.07
	hat_mesh.height = 0.2
	hat_mesh.radial_segments = 8
	hat_mesh.rings = 1
	confetti_mesh = PlaneMesh.new()
	confetti_mesh.size = Vector2(0.025, 0.035)
	cmat = StandardMaterial3D.new()
	cmat.vertex_color_use_as_albedo = true
	cmat.roughness = 0.4
	var sh := Shader.new()
	sh.code = GRIN
	grin_mat = ShaderMaterial.new()
	grin_mat.shader = sh


static func materials() -> void:
	MatLib.define("l26_corr_wall", {"albedo_a": Color(0.74, 0.68, 0.56), "albedo_b": Color(0.68, 0.62, 0.5), "pattern": 2,
		"pattern_scale": Vector2(1.2, 1.0), "pattern_color": Color(0.6, 0.54, 0.42), "pattern_strength": 0.35, "stain_amount": 0.5,
		"stain_color": Color(0.4, 0.28, 0.18), "grime_height": 0.5, "grime_color": Color(0.35, 0.25, 0.16), "floor_y": -100.0}, "")
	MatLib.define("l26_corr_floor", {"albedo_a": Color(0.2, 0.22, 0.42), "albedo_b": Color(0.16, 0.18, 0.36), "pattern": 6,
		"pattern_strength": 0.5, "pattern_color": Color(0.7, 0.5, 0.2), "stain_amount": 0.5, "stain_color": Color(0.1, 0.08, 0.08),
		"roughness_a": 0.95, "roughness_b": 1.0}, "")
	MatLib.define("l26_room_floor", {"albedo_a": Color(0.62, 0.6, 0.55), "albedo_b": Color(0.56, 0.54, 0.5), "pattern": 9,
		"pattern_scale": Vector2(0.4, 0.4), "pattern_color": Color(0.3, 0.3, 0.32), "pattern_strength": 0.6, "grout_width": 0.0,
		"stain_amount": 0.45, "stain_color": Color(0.3, 0.2, 0.15), "roughness_a": 0.4}, "")
	for c in [["pink", Color(0.86, 0.55, 0.62)], ["teal", Color(0.36, 0.66, 0.66)], ["yellow", Color(0.9, 0.78, 0.4)],
			["purple", Color(0.5, 0.36, 0.62)], ["dark", Color(0.22, 0.2, 0.2)]]:
		MatLib.define("l26_room_" + str(c[0]), {"albedo_a": c[1], "albedo_b": (c[1] as Color).darkened(0.08), "pattern": 5,
			"pattern_scale": Vector2(0.2, 0.2), "pattern_color": (c[1] as Color).lightened(0.3), "pattern_strength": 0.4,
			"stain_amount": 0.45, "stain_color": Color(0.35, 0.22, 0.15), "grime_height": 0.4, "floor_y": -100.0}, "")
	for c in [["a", Color(0.95, 0.2, 0.4)], ["b", Color(0.2, 0.6, 0.95)], ["c", Color(1.0, 0.85, 0.15)], ["d", Color(0.2, 0.8, 0.35)]]:
		MatLib.define("l26_streamer_" + str(c[0]), {"albedo_a": c[1], "albedo_b": (c[1] as Color).darkened(0.1), "roughness_a": 0.5,
			"emission_color": c[1], "emission_energy": 0.15}, "")
	MatLib.define("l26_tablecloth", {"albedo_a": Color(0.92, 0.9, 0.88), "albedo_b": Color(0.86, 0.84, 0.8), "pattern": 9,
		"pattern_scale": Vector2(0.2, 0.2), "pattern_color": Color(0.9, 0.4, 0.5), "pattern_strength": 0.5, "stain_amount": 0.5,
		"stain_color": Color(0.5, 0.15, 0.12)}, "")
	MatLib.define("l26_cake", {"albedo_a": Color(0.95, 0.88, 0.86), "albedo_b": Color(0.92, 0.75, 0.8), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.9, 0.5, 0.65), "pattern_strength": 0.6}, "")
	MatLib.define("l26_gift", {"albedo_a": Color(0.2, 0.45, 0.85), "albedo_b": Color(0.85, 0.2, 0.3), "pattern": 9,
		"pattern_scale": Vector2(0.08, 0.08), "pattern_color": Color(0.95, 0.85, 0.2), "pattern_strength": 0.5, "roughness_a": 0.35}, "")
	MatLib.define("l26_pumpkin", {"albedo_a": Color(0.92, 0.45, 0.08), "albedo_b": Color(0.85, 0.38, 0.06), "pattern": 2,
		"pattern_scale": Vector2(0.06, 1.0), "pattern_color": Color(0.7, 0.3, 0.04), "pattern_strength": 0.5}, "")
	MatLib.define("l26_tree", {"albedo_a": Color(0.1, 0.32, 0.14), "albedo_b": Color(0.07, 0.25, 0.1), "noise_scale": 6.0, "bump_strength": 1.5}, "")
	MatLib.define("l26_chair", {"albedo_a": Color(0.25, 0.25, 0.27), "albedo_b": Color(0.2, 0.2, 0.22), "metallic_value": 0.5, "roughness_a": 0.4}, "")
	MatLib.register("l26_screen", MatLib.panel(Color(0.55, 0.65, 0.9), 1.4, 0.3))
	MatLib.register("l26_party_lamp", MatLib.panel(Color(1.0, 0.75, 0.5), 1.8))


static func origin(cx: int, cz: int) -> Vector3:
	return Vector3(cx * CS, DY, cz * CS)


static func hub_arrival() -> Vector3:
	return origin(IX, 0) + Vector3(12.0, 0.05, 14.4)


func build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	node.position = origin(cx, cz)
	var group := "deck_%d_%d" % [cx, cz]
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_base, cx, cz, version])
	var k := GeoKit.new(node, "Deck")
	var meta := {"group": group, "balloons": [], "figure": null, "rooms": []}
	var hub: bool = cx == IX and cz == 0
	k.slab(0, 0, CS, CS, 0.0, 0.3, "l26_room_floor")
	k.box_mm(Vector3(A, 0, 0), Vector3(B, 0.015, CS), "l26_corr_floor", GeoKit.PY, false)
	k.box_mm(Vector3(0, 0, A), Vector3(CS, 0.015, B), "l26_corr_floor", GeoKit.PY, false)
	k.slab(0, 0, CS, CS, H + 0.15, 0.15, "l26_ceiling")
	# quadrant rooms
	var quads := [Vector2(0, 0), Vector2(B, 0), Vector2(0, B), Vector2(B, B)]
	var doors := {}
	for qi in 4:
		var q: Vector2 = quads[qi]
		var theme: String = THEMES[r.randi() % THEMES.size()]
		var rr := r
		if cz == 0 and qi == 1:
			theme = "birthday"     # the cloned room, identical along the hub hallway
			rr = RandomNumberGenerator.new()
			rr.seed = 3838
		if hub and qi >= 2:
			theme = "closed"
		# its door: on the E-W corridor for the clone, else on either corridor side
		var on_ew: bool = (cz == 0 and qi == 1) or r.randf() < 0.5
		var at := rr.randf_range(2.0, 8.5)
		doors[qi] = {"ew": on_ew, "at": at, "theme": theme}
		_room(k, node, q, qi, theme, on_ew, at, rr, meta, cx, cz)
	# corridor walls with door openings (closed rooms keep their doors shut)
	_corr_walls(k, doors)
	# chunk-edge walls (each chunk owns its low x and low z edges)
	for seg in [[Vector3(0, 0, 0), Vector3(0, 0, A)], [Vector3(0, 0, B), Vector3(0, 0, CS)]]:
		k.wall(seg[0], seg[1], H, 0.16, "l26_room_teal")
	for seg in [[Vector3(0, 0, 0), Vector3(A, 0, 0)], [Vector3(B, 0, 0), Vector3(CS, 0, 0)]]:
		k.wall(seg[0], seg[1], H, 0.16, "l26_room_pink")
	# corridor fixtures
	for t: float in [3.0, 21.0]:
		_corr_lamp(k, Vector3(12.0, H, t), group)
		_corr_lamp(k, Vector3(t, H, 12.0), group)
	if hub:
		k.wall(Vector3(A, 0, 15.0), Vector3(B, 0, 15.0), H, 0.2, "l26_corr_wall")
		L.S.elevator_doors_into(k, Vector3(12.0, 0, 14.88), Vector3(0, 0, -1), 1.6)
		L.lights.add_anchor(node.position + Vector3(12, 2.3, 13.6), Color(1.0, 0.85, 0.6), 1.1, 6.0, 0.0, group)
	# a figure in yellow at the end of a corridor, sometimes
	if not hub and r.randf() < 0.22:
		var fp := Vector3(12.0 + r.randf_range(-0.6, 0.6), 0, 1.2) if r.randf() < 0.5 else Vector3(22.8, 0, 12.0 + r.randf_range(-0.6, 0.6))
		meta["figure"] = node.position + fp
	k.commit()
	_confetti(node, r)
	return meta


func _corr_lamp(k: GeoKit, p: Vector3, group: String) -> void:
	k.box(p + Vector3(0, -0.05, 0), Vector3(0.6, 0.08, 0.6), "l26_white", GeoKit.ALL, false)
	k.panel(p + Vector3(0, -0.095, 0), 0.5, 0.5, "l26_fixture")
	L.lights.add_anchor(k.root.get_parent().position + p + Vector3(0, -0.4, 0), Color(1.0, 0.9, 0.75), 0.7, 5.5, 0.0, group)


func _corr_walls(k: GeoKit, doors: Dictionary) -> void:
	# quadrant 0 (low x, low z), 1 (high x, low z), 2 (low x, high z), 3 (high x, high z)
	# E-W corridor walls: z = A (rooms 0,1) and z = B (rooms 2,3)
	# N-S corridor walls: x = A (rooms 0,2) and x = B (rooms 1,3)
	var specs := [
		[Vector3(0, 0, A), Vector3(A, 0, A), 0, true], [Vector3(B, 0, A), Vector3(CS, 0, A), 1, true],
		[Vector3(0, 0, B), Vector3(A, 0, B), 2, true], [Vector3(B, 0, B), Vector3(CS, 0, B), 3, true],
		[Vector3(A, 0, 0), Vector3(A, 0, A), 0, false], [Vector3(B, 0, 0), Vector3(B, 0, A), 1, false],
		[Vector3(A, 0, B), Vector3(A, 0, CS), 2, false], [Vector3(B, 0, B), Vector3(B, 0, CS), 3, false]]
	for sp in specs:
		var qi: int = sp[2]
		var dd: Dictionary = doors[qi]
		var ops: Array = []
		var closed: bool = dd["theme"] == "closed"
		if dd["ew"] == sp[3]:
			ops.append({"at": float(dd["at"]), "w": 1.0, "h": 2.1})
		k.wall(sp[0], sp[1], H, 0.16, "l26_corr_wall", ops)
		if not ops.is_empty():
			var a: Vector3 = sp[0]
			var b: Vector3 = sp[1]
			var dp := a + (b - a).normalized() * float(dd["at"])
			var along := (b - a).normalized()
			var bas := Basis(along, Vector3.UP, along.cross(Vector3.UP))
			k.box_xf(Transform3D(bas, dp + Vector3.UP * 2.15), Vector3(1.2, 0.1, 0.22), "l26_brass", GeoKit.ALL, false)
			if closed:
				k.box_xf(Transform3D(bas, dp + Vector3.UP * 1.05), Vector3(0.98, 2.08, 0.06), "l26_cabin_door", GeoKit.ALL, true)


func _room(k: GeoKit, node: Node3D, q: Vector2, qi: int, theme: String, on_ew: bool, at: float, r: RandomNumberGenerator, meta: Dictionary, cx: int, cz: int) -> void:
	var x0 := q.x + 0.2
	var z0 := q.y + 0.2
	var x1 := q.x + A - 0.2
	var z1 := q.y + A - 0.2
	var c := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	var group: String = meta["group"]
	var npos: Vector3 = node.position
	if theme == "closed":
		if r.randf() < 0.4:
			meta["rooms"].append({"music": npos + c + Vector3(0, 1.2, 0)})
		return
	var wall_mat: String = ["l26_room_pink", "l26_room_teal", "l26_room_yellow", "l26_room_purple"][r.randi() % 4]
	if theme == "dark":
		wall_mat = "l26_room_dark"
	# inner wall skins in the room's own colour
	k.box_mm(Vector3(x0 - 0.02, 0, z0 - 0.02), Vector3(x1 + 0.02, H - 0.01, z0), wall_mat, GeoKit.PZ, false)
	k.box_mm(Vector3(x0 - 0.02, 0, z1), Vector3(x1 + 0.02, H - 0.01, z1 + 0.02), wall_mat, GeoKit.NZ, false)
	k.box_mm(Vector3(x0 - 0.02, 0, z0), Vector3(x0, H - 0.01, z1), wall_mat, GeoKit.PX, false)
	k.box_mm(Vector3(x1, 0, z0), Vector3(x1 + 0.02, H - 0.01, z1), wall_mat, GeoKit.NX, false)
	meta["rooms"].append({"theme": theme, "c": npos + c})
	if theme == "dark":
		_balloon_cluster(node, Vector3(x0 + 0.7, 1.6, z0 + 0.7) if r.randf() < 0.5 else Vector3(x1 - 0.7, 1.6, z1 - 0.7), r, meta)
		return
	# party lamp and streamers
	k.panel(c + Vector3(0, H - 0.01, 0), 0.8, 0.8, "l26_party_lamp")
	var col: Color = [Color(1.0, 0.55, 0.7), Color(0.6, 0.8, 1.0), Color(1.0, 0.85, 0.5), Color(0.8, 1.0, 0.7)][r.randi() % 4]
	L.lights.add_anchor(npos + c + Vector3(0, 2.2, 0), col, 1.0, 7.0, 0.1 if r.randf() < 0.3 else 0.0, group)
	for i in 4:
		var a := Vector3(r.randf_range(x0, x1), H - 0.05, z0)
		var b := Vector3(r.randf_range(x0, x1), H - 0.05, z1)
		_streamer(k, a, b, r)
	var balloons: Array = []
	match theme:
		"birthday", "plain", "trap":
			_table(k, c + Vector3(r.randf_range(-1.0, 1.0), 0, r.randf_range(-1.0, 1.0)), r, theme == "birthday")
			for i in 12 + r.randi() % 10:
				balloons.append([Vector3(r.randf_range(x0 + 0.3, x1 - 0.3), r.randf_range(2.35, 2.6), r.randf_range(z0 + 0.3, z1 - 0.3)), BALLOON_COLORS[r.randi() % BALLOON_COLORS.size()]])
			for i in 5:
				balloons.append([Vector3(r.randf_range(x0 + 0.3, x1 - 0.3), 0.15, r.randf_range(z0 + 0.3, z1 - 0.3)), BALLOON_COLORS[r.randi() % BALLOON_COLORS.size()]])
			if theme == "birthday":
				var bp := Vector3(c.x, 2.1, z0 + 0.03)
				L.S.label("HAPPY BIRTHDAY", bp, Vector3(0, 0, 1), 0.006, Color(0.9, 0.2, 0.35), 64, node)
			for i in 3 + r.randi() % 3:
				var gp := Vector3(r.randf_range(x0 + 0.5, x1 - 0.5), 0, r.randf_range(z0 + 0.5, z1 - 0.5))
				var sz := r.randf_range(0.25, 0.5)
				k.box(gp + Vector3(0, sz * 0.5, 0), Vector3(sz, sz, sz * 0.8), "l26_gift", GeoKit.ALL, false)
				if theme == "trap" and i == 0:
					L.make_interactable(gp + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8), "Open the party favour", L._trap_favor.bind(npos + gp), node)
		"movie":
			k.box(Vector3(c.x, 1.5, z0 + 0.06), Vector3(4.4, 2.0, 0.04), "l26_screen", GeoKit.ALL, false)
			L.lights.add_anchor(npos + Vector3(c.x, 1.4, z0 + 1.2), Color(0.55, 0.65, 1.0), 0.9, 5.0, 0.4, group)
			for row in 3:
				for i in 5:
					_chair(k, Vector3(c.x - 2.0 + i * 1.0, 0, z0 + 3.2 + row * 1.4), PI + r.randf_range(-0.2, 0.2))
			for i in 8:
				balloons.append([Vector3(r.randf_range(x0, x1), r.randf_range(2.35, 2.6), r.randf_range(z0 + 2, z1)), BALLOON_COLORS[r.randi() % 3]])
		"xmas":
			var tp := Vector3(x0 + 1.4, 0, z0 + 1.4)
			for j in 3:
				var cone := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 1.0 - j * 0.26
				cm.height = 1.0
				cm.radial_segments = 12
				cone.mesh = cm
				cone.material_override = MatLib.get_mat("l26_tree")
				cone.position = tp + Vector3(0, 0.75 + j * 0.55, 0)
				node.add_child(cone)
			for i in 14:
				var a2 := r.randf() * TAU
				var hh := r.randf_range(0.4, 2.0)
				balloons.append([tp + Vector3(cos(a2) * (1.0 - hh * 0.4), hh, sin(a2) * (1.0 - hh * 0.4)), BALLOON_COLORS[r.randi() % 4]])
			for i in 5:
				var gp2 := tp + Vector3(r.randf_range(-1.2, 1.2), 0, r.randf_range(0.8, 1.6))
				k.box(gp2 + Vector3(0, 0.15, 0), Vector3(0.35, 0.3, 0.3), "l26_gift", GeoKit.ALL, false)
			_table(k, c + Vector3(1.0, 0, 1.0), r, false)
		"halloween":
			for i in 6:
				var pp := Vector3(r.randf_range(x0 + 0.4, x1 - 0.4), 0.0, r.randf_range(z0 + 0.4, z1 - 0.4))
				var pm := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.22
				sm.height = 0.34
				pm.mesh = sm
				pm.material_override = MatLib.get_mat("l26_pumpkin")
				pm.position = pp + Vector3(0, 0.17, 0)
				node.add_child(pm)
			_table(k, c, r, false)
			L.lights.add_anchor(npos + c + Vector3(0, 0.6, 0), Color(1.0, 0.45, 0.1), 0.8, 4.0, 0.5, group)
	# chairs around, hats and cups strewn, a little blood on the floor
	for i in 4:
		_chair(k, Vector3(r.randf_range(x0 + 0.6, x1 - 0.6), 0, r.randf_range(z0 + 0.6, z1 - 0.6)), r.randf() * TAU, r.randf() < 0.3)
	_balloons(node, balloons)
	_hats(node, r, x0, z0, x1, z1)
	if r.randf() < 0.35:
		L.add_splat(npos + Vector3(r.randf_range(x0 + 1, x1 - 1), 0.02, r.randf_range(z0 + 1, z1 - 1)), r.randf_range(0.5, 1.0), node)


func _streamer(k: GeoKit, a: Vector3, b: Vector3, r: RandomNumberGenerator) -> void:
	var mat: String = ["l26_streamer_a", "l26_streamer_b", "l26_streamer_c", "l26_streamer_d"][r.randi() % 4]
	var n := 6
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var p0 := a.lerp(b, t0) - Vector3(0, sin(t0 * PI) * 0.35, 0)
		var p1 := a.lerp(b, t1) - Vector3(0, sin(t1 * PI) * 0.35, 0)
		var dir := p1 - p0
		var z := dir.normalized()
		var x := Vector3.UP.cross(z).normalized()
		var y := z.cross(x).normalized()
		k.box_xf(Transform3D(Basis(x, y, z), (p0 + p1) * 0.5), Vector3(0.06, 0.005, dir.length()), mat, GeoKit.ALL, false)


func _table(k: GeoKit, p: Vector3, r: RandomNumberGenerator, cake: bool) -> void:
	k.box(p + Vector3(0, 0.74, 0), Vector3(1.8, 0.04, 0.9), "l26_tablecloth", GeoKit.ALL, true)
	k.box(p + Vector3(0, 0.6, 0.46), Vector3(1.8, 0.28, 0.01), "l26_tablecloth", GeoKit.ALL, false)
	k.box(p + Vector3(0, 0.6, -0.46), Vector3(1.8, 0.28, 0.01), "l26_tablecloth", GeoKit.ALL, false)
	for sx: float in [-0.8, 0.8]:
		for sz: float in [-0.38, 0.38]:
			k.box(p + Vector3(sx, 0.37, sz), Vector3(0.04, 0.72, 0.04), "l26_chair", GeoKit.ALL, false)
	if cake:
		k.cylinder(p + Vector3(0, 0.88, 0), 0.22, 0.24, "l26_cake", 16, false)
		k.cylinder(p + Vector3(0, 1.05, 0), 0.15, 0.12, "l26_cake", 16, false)
		for i in 5:
			var a := TAU * i / 5.0
			k.box(p + Vector3(cos(a) * 0.09, 1.16, sin(a) * 0.09), Vector3(0.012, 0.08, 0.012), "l26_streamer_c", GeoKit.ALL, false)
	for i in 4:
		k.cylinder(p + Vector3(r.randf_range(-0.8, 0.8), 0.8, r.randf_range(-0.35, 0.35)), 0.04, 0.1, "l26_streamer_" + ["a", "b", "c", "d"][r.randi() % 4], 8, false)


func _chair(k: GeoKit, p: Vector3, yaw: float, fallen := false) -> void:
	var b := Basis(Vector3.UP, yaw)
	if fallen:
		b = b * Basis(Vector3(1, 0, 0), PI * 0.5)
		p.y += 0.22
	k.box_xf(Transform3D(b, p + b * Vector3(0, 0.45, 0)), Vector3(0.42, 0.04, 0.42), "l26_chair", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + b * Vector3(0, 0.7, -0.2)), Vector3(0.42, 0.45, 0.03), "l26_chair", GeoKit.ALL, false)
	for sx: float in [-0.19, 0.19]:
		for sz: float in [-0.19, 0.19]:
			k.box_xf(Transform3D(b, p + b * Vector3(sx, 0.22, sz)), Vector3(0.025, 0.45, 0.025), "l26_chair", GeoKit.ALL, false)


func _balloons(node: Node3D, list: Array) -> void:
	if list.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = balloon_mesh
	mm.instance_count = list.size()
	for i in list.size():
		mm.set_instance_transform(i, Transform3D(Basis(), list[i][0]))
		mm.set_instance_color(i, list[i][1])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = cmat
	node.add_child(mmi)


func _hats(node: Node3D, r: RandomNumberGenerator, x0: float, z0: float, x1: float, z1: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = hat_mesh
	mm.instance_count = 6
	for i in 6:
		var b := Basis(Vector3(1, 0, 0), PI * 0.5 if r.randf() < 0.6 else 0.0).rotated(Vector3.UP, r.randf() * TAU)
		mm.set_instance_transform(i, Transform3D(b, Vector3(r.randf_range(x0 + 0.3, x1 - 0.3), 0.08, r.randf_range(z0 + 0.3, z1 - 0.3))))
		mm.set_instance_color(i, BALLOON_COLORS[r.randi() % BALLOON_COLORS.size()])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = cmat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mmi)


func _confetti(node: Node3D, r: RandomNumberGenerator) -> void:
	var n := 420
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = confetti_mesh
	mm.instance_count = n
	for i in n:
		var p := Vector3(r.randf_range(A + 0.2, B - 0.2), 0.02, r.randf_range(0, CS)) if i % 2 == 0 else Vector3(r.randf_range(0, CS), 0.02, r.randf_range(A + 0.2, B - 0.2))
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, r.randf() * TAU), p))
		mm.set_instance_color(i, BALLOON_COLORS[r.randi() % BALLOON_COLORS.size()])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = cmat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mmi)


## Carnivorous Balloons huddled in the darkest corner; the level animates them.
func _balloon_cluster(node: Node3D, corner: Vector3, r: RandomNumberGenerator, meta: Dictionary) -> void:
	for i in 4 + r.randi() % 4:
		var b := MeshInstance3D.new()
		b.mesh = balloon_mesh
		var m: ShaderMaterial = grin_mat.duplicate()
		m.set_shader_parameter("base", BALLOON_COLORS[r.randi() % 5])
		b.material_override = m
		var home := corner + Vector3(r.randf_range(-0.6, 0.6), r.randf_range(-0.5, 0.6), r.randf_range(-0.6, 0.6))
		b.position = home
		b.scale = Vector3.ONE * r.randf_range(1.0, 1.5)
		node.add_child(b)
		meta["balloons"].append({"node": b, "home": node.position + home, "phase": r.randf() * TAU})
