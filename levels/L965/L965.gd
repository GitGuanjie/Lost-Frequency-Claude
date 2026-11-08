extends LevelBase
## Level 965 — "Colorful Colorless" (Backrooms Wikidot rev 9, accessed
## 2026-11-04; cite: Schulzenreich, CC BY-SA 3.0). Dossier: docs/canon/levels/L965.md.
##
## PLAN (v2.0 rebuild)
## SOURCE (accepted entry): a monochrome landscape dotted with defunct wind
## turbines and structures of unknown purpose, presumably flood barriers long
## since disused; grey plains over the horizon; a motionless pale blue sky with
## barely-clouds; "There is nothing else of note"; a rainbow "seemingly of no
## inherent effect" (photo caption: rainbow over the barrier). DRAFT (unreliable,
## contradicted): living spaces nobody claims, settlers leave within a day, an
## "impossible barrier" west of the initial view, visible only in colour.
## Build: a streamed 96 m-chunk grey plain (finite window, haze to the horizon);
## a disused flood channel running east-west with revetment walls, stairs into
## the bed and a still grey stream; a five-pier hooded flood barrier across it
## west of the arrival, with a stair tower and a walkway on the pier tops
## (plain / channel bed / walkway = three walkable heights); defunct turbines
## on a seeded lattice (some missing a blade, fallen into the grass); stray
## flood-wall segments; the barrier control house, clean and unused.
## Colour exists only in the rainbow, which always stands to the west.
## Signature mechanic: the two documents. The desk in the control house holds
## Darrion Jent's draft. Look at the rainbow long enough and nothing happens —
## and the draft is gone: the desk now holds the accepted entry, which says
## there is nothing else of note. The draft's blinding claims are never applied.
## No exits: the page names no method or destination (see level.json).
## Helper: L965_build.gd.

const B := preload("res://levels/L965/L965_build.gd")
const START := Vector3(26.0, 0.1, -3.0)

var bld
var world: ChunkWorld
var rainbow: MeshInstance3D
var clouds: MeshInstance3D
var gaze := 0.0
var doc_state := "draft"        # draft | accepted
var said := {}
var _creak_t := 9.0


func build() -> void:
	bld = B.new(self)
	rules["view_distance"] = 2400.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.03
	outdoor_env(Color(0.50, 0.62, 0.78), Color(0.78, 0.80, 0.82), Color(0.44, 0.44, 0.44), Vector2(48.0, 150.0), Color(0.96, 0.96, 0.95), 0.9, Color(0.66, 0.68, 0.70), 0.0032)
	environment.ambient_light_energy = 0.55
	environment.tonemap_exposure = 0.82
	environment.fog_sky_affect = 0.25
	environment.fog_aerial_perspective = 0.3
	sun.directional_shadow_max_distance = 140.0
	_materials()
	lights.setup(3, 0)
	lights.add_anchor(B.HOUSE + Vector3(0.0, 2.6, -1.2), Color(0.86, 0.87, 0.88), 0.55, 7.0)
	world = ChunkWorld.new()
	world.name = "Plain"
	world.chunk_size = B.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = func(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary: return bld.build_chunk(cx, cz, node)
	add_child(world)
	world.build_around(START, 2)
	_sky_objects()
	_documents()
	_sounds()
	add_arrival("start", START, 17.0)
	add_landmark("Flood barrier, five hooded piers (west)", Vector3(B.BX, 6.0, B.ZC))
	add_landmark("Barrier control house", B.HOUSE)
	add_landmark("Disused flood channel", Vector3(0, -4, B.ZC))
	add_shot("initial_view", START + Vector3(0, 1.62, 0), Vector3(-30.0, 6.0, -190.0), {"flashlight": false})
	add_shot("rainbow_over_the_barrier", Vector3(-8.0, 1.7, -8.0), Vector3(-200.0, 38.0, -44.0), {"flashlight": false})
	add_shot("channel_bed_to_barrier", Vector3(-22.0, -2.3, -36.0), Vector3(B.BX, 1.0, -48.0), {"flashlight": false})
	add_shot("barrier_hoods_from_bank", Vector3(-40.0, 1.7, -6.0), Vector3(-62.0, 7.0, -44.0), {"flashlight": false})
	add_shot("pier_walkway", Vector3(B.BX + 7.8, 7.85, -66.0), Vector3(40.0, -2.0, -190.0), {"flashlight": false})
	add_shot("control_house", Vector3(B.HOUSE.x + 3.2, 1.95, B.HOUSE.z + 2.2), Vector3(B.HOUSE.x - 2.0, 1.0, B.HOUSE.z - 3.4), {"flashlight": false})


func on_player_ready() -> void:
	world.target = player


func _materials() -> void:
	MatLib.define("l965_grass", {"albedo_a": Color(0.22, 0.22, 0.215), "albedo_b": Color(0.15, 0.15, 0.148),
		"pattern_color": Color(0.31, 0.31, 0.30), "pattern_strength": 0.7, "noise_scale": 0.12, "bump_strength": 1.2}, "grass")
	var tuft := StandardMaterial3D.new()
	tuft.albedo_color = Color(0.34, 0.34, 0.33)
	tuft.vertex_color_use_as_albedo = true
	tuft.roughness = 1.0
	tuft.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l965_tuft", tuft)
	MatLib.define("l965_concrete", {"albedo_a": Color(0.44, 0.44, 0.43), "albedo_b": Color(0.36, 0.36, 0.355),
		"stain_amount": 0.45, "stain_color": Color(0.36, 0.36, 0.35), "grime_height": 1.2, "grime_color": Color(0.33, 0.33, 0.32)}, "concrete")
	MatLib.define("l965_bed", {"albedo_a": Color(0.27, 0.27, 0.265), "albedo_b": Color(0.19, 0.19, 0.188), "noise_scale": 0.35,
		"stain_amount": 0.6, "stain_color": Color(0.14, 0.14, 0.14), "stain_scale": 0.08, "wetness": 0.35}, "concrete")
	MatLib.define("l965_concrete_dark", {"albedo_a": Color(0.36, 0.36, 0.36), "albedo_b": Color(0.29, 0.29, 0.29)}, "concrete_dark")
	MatLib.define("l965_floor", {"albedo_a": Color(0.52, 0.52, 0.51), "albedo_b": Color(0.49, 0.49, 0.48), "pattern": 1,
		"pattern_scale": Vector2(0.5, 0.5), "grout_width": 0.01, "grout_color": Color(0.38, 0.38, 0.38), "roughness_a": 0.5}, "concrete")
	MatLib.define("l965_render", {"albedo_a": Color(0.58, 0.58, 0.57), "albedo_b": Color(0.52, 0.52, 0.51),
		"stain_amount": 0.3, "stain_color": Color(0.5, 0.5, 0.49), "grime_height": 0.6, "grime_color": Color(0.45, 0.45, 0.44)}, "plaster")
	MatLib.define("l965_ceiling", {"albedo_a": Color(0.78, 0.78, 0.77), "albedo_b": Color(0.74, 0.74, 0.73)}, "plaster")
	MatLib.define("l965_steel", {"albedo_a": Color(0.62, 0.62, 0.62), "albedo_b": Color(0.50, 0.50, 0.50), "metallic_value": 0.6,
		"stain_amount": 0.35, "stain_color": Color(0.38, 0.38, 0.38)}, "metal")
	MatLib.define("l965_steel_dark", {"albedo_a": Color(0.26, 0.26, 0.26), "albedo_b": Color(0.2, 0.2, 0.2), "metallic_value": 0.5,
		"stain_color": Color(0.32, 0.32, 0.32)}, "metal")
	MatLib.define("l965_steel_grate", {"albedo_a": Color(0.4, 0.4, 0.4), "albedo_b": Color(0.33, 0.33, 0.33), "pattern": 9,
		"pattern_scale": Vector2(0.05, 0.05), "pattern_color": Color(0.14, 0.14, 0.14), "pattern_strength": 0.6, "metallic_value": 0.5}, "metal")
	MatLib.define("l965_rail_ghost", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.45, 0.45, 0.45), "metallic_value": 0.5}, "metal")
	MatLib.define("l965_tower", {"albedo_a": Color(0.80, 0.80, 0.79), "albedo_b": Color(0.72, 0.72, 0.71), "roughness_a": 0.55,
		"roughness_b": 0.7, "stain_amount": 0.35, "stain_color": Color(0.55, 0.55, 0.54), "stain_scale": 0.12, "bump_strength": 0.2}, "plaster")
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.62, 0.64, 0.66, 0.22)
	g.roughness = 0.05
	g.metallic_specular = 0.8
	MatLib.register("l965_glass", g)
	MatLib.register("l965_water", MatLib.water({"shallow_color": Color(0.46, 0.47, 0.47), "deep_color": Color(0.24, 0.25, 0.25),
		"absorption": 0.6, "clarity": 0.55, "wave_height": 0.0, "wave_speed": 0.02, "foam_amount": 0.0, "normal_strength": 0.08}))


# ----------------------------------------------------------- sky and rainbow

func _sky_objects() -> void:
	# The rainbow: seven bands, the only colour in the level. It keeps its
	# bearing (west) as you move, the way a rainbow does.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := [Color(0.95, 0.12, 0.10), Color(1.0, 0.5, 0.05), Color(1.0, 0.92, 0.15), Color(0.2, 0.85, 0.25),
		Color(0.15, 0.45, 1.0), Color(0.3, 0.15, 0.8), Color(0.55, 0.2, 0.85)]
	var r_out := 520.0
	var band := 7.5
	var seg := 64
	for bi in cols.size():
		var r1 := r_out - bi * band
		var r0 := r1 - band
		for i in seg:
			var a0 := PI * float(i) / seg
			var a1 := PI * float(i + 1) / seg
			var pts := [Vector3(0, sin(a0) * r0, cos(a0) * r0), Vector3(0, sin(a0) * r1, cos(a0) * r1), Vector3(0, sin(a1) * r1, cos(a1) * r1), Vector3(0, sin(a1) * r0, cos(a1) * r0)]
			var edge_in := 1.0 if bi > 0 else 0.35
			var edge_out := 1.0 if bi < cols.size() - 1 else 0.3
			var c: Color = cols[bi]
			var cc := [Color(c, 0.5 * edge_out), Color(c, 0.5 * edge_in), Color(c, 0.5 * edge_in), Color(c, 0.5 * edge_out)]
			for q in [0, 1, 2, 0, 2, 3]:
				st.set_color(cc[q])
				st.add_vertex(pts[q])
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled, blend_mix;
varying float hy;
void vertex() { hy = VERTEX.y; }
void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * smoothstep(-40.0, 120.0, hy) * 0.85;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	rainbow = MeshInstance3D.new()
	rainbow.name = "Rainbow"
	rainbow.mesh = st.commit()
	rainbow.material_override = m
	rainbow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rainbow.extra_cull_margin = 2000.0
	add_child(rainbow)
	# motionless wisps that can barely be called clouds
	var cs := Shader.new()
	cs.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D n : repeat_enable, filter_linear;
void fragment() {
	float a = texture(n, UV * 1.4).r;
	a = smoothstep(0.58, 0.85, a) * (1.0 - smoothstep(0.25, 0.5, length(UV - vec2(0.5))));
	ALBEDO = vec3(0.92, 0.93, 0.95);
	ALPHA = a * 0.55;
}
"""
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var fn := FastNoiseLite.new()
	fn.seed = 9650
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	nt.noise = fn
	var cm := ShaderMaterial.new()
	cm.shader = cs
	cm.set_shader_parameter("n", nt)
	var pm := PlaneMesh.new()
	pm.size = Vector2(5200, 5200)
	clouds = MeshInstance3D.new()
	clouds.name = "Wisps"
	clouds.mesh = pm
	clouds.material_override = cm
	clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	clouds.extra_cull_margin = 3000.0
	clouds.position = Vector3(0, 700, 0)
	add_child(clouds)
	_follow(START)


func _follow(p: Vector3) -> void:
	rainbow.global_position = Vector3(p.x - 880.0, -170.0, p.z - 40.0)
	clouds.global_position = Vector3(p.x, 700.0, p.z)


# ----------------------------------------------------------- documents

func _documents() -> void:
	var h := B.HOUSE
	add_interactable(Vector3(h.x - 1.5, 1.15, h.z - 2.5), Vector3(1.6, 0.4, 0.9), "Read the papers on the desk", _read_desk)
	add_note("l965_dedication", "Card pinned by the door", "Posted in memory of Researcher Darrion S. Jent, who died in search of meaning. May he rest in peace.", Vector3(h.x + 3.9, 1.6, h.z + 1.4), Vector3(0.12, 0.4, 0.4))


func _read_desk() -> void:
	if doc_state == "draft":
		Overlay.show_note("Draft, pending acceptance (Base Omega Drafts Committee)",
			"LEVEL 965. Survival class 0: guaranteed exit, no environmental risks, no hostile entities.\n\n" +
			"A monochrome landscape dotted with defunct wind turbines and structures of unknown purpose, presumably flood barriers long since disused. Grey plains over the horizon. A motionless pale blue sky.\n\n" +
			"Nobody has claimed even the cleanest building here. Settlers call it 'simply boring' and leave within a day.\n\n" +
			"The author, D. Jent, adds a second interest west of the first view: an 'impossible barrier of time', visible only in colour, which he claims stays in your eyes and blinds whoever keeps looking. He writes that he will go west to see what it means.\n\n" +
			"Across the margin, in another hand: a long, furious rebuke. It calls the search for meaning here a folly.")
		_say("draft_read", "[the draft is not accepted. Nobody has checked its claims.]")
	else:
		Overlay.show_note("Accepted for submission to GPD",
			"LEVEL 965. Survival class 0: guaranteed exit, no environmental risks, no hostile entities.\n\n" +
			"Photograph: a rainbow in Level 965. Seemingly of no inherent effect.\n\n" +
			"A monochrome landscape dotted with defunct wind turbines and structures of unknown purpose, presumably flood barriers long since disused. Grey plains over the horizon are the only interest. The sky is a motionless pale blue.\n\n" +
			"There is nothing else of note.")


# ----------------------------------------------------------- sound

func _sounds() -> void:
	sound.bed("wind", {"seconds": 10.0}, -36.0)
	sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0}, -34.0)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ----------------------------------------------------------- mechanic

func rainbow_in_view() -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var fwd := -cam.global_transform.basis.z
	var to := (Vector3(rainbow.global_position.x, cam.global_position.y + 160.0, cam.global_position.z) - cam.global_position).normalized()
	return fwd.dot(to) > 0.8


func register_gaze(delta: float) -> void:
	gaze += delta
	if gaze > 1.5:
		_say("g1", "[a rainbow to the west, over the barrier: the only colour here]")
	if gaze > 7.0:
		_say("g2", "[you keep looking. Nothing happens.]")
	if gaze > 13.0 and doc_state == "draft":
		doc_state = "accepted"
		_say("g3", "[seemingly of no inherent effect]", 5.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_follow(player.global_position)
	if rainbow_in_view():
		register_gaze(delta)
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = rng.randf_range(14.0, 30.0)
		var p := player.global_position + Vector3(rng.randf_range(-60, 60), 30.0, rng.randf_range(-60, 60))
		sound.play_at("creak", {"freq": 90.0}, p, -14.0, "[a stopped turbine ticks somewhere, high up]" if not said.has("creak") else "")
		said["creak"] = true


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var turb := 0
	var walls := 0
	for k in world.chunks.keys():
		turb += int(world.meta_of(k).get("turbines", 0))
		walls += int(world.meta_of(k).get("walls", 0))
	out.append({"what": "defunct turbines in the loaded window", "ok": turb >= 2, "detail": turb})
	out.append({"what": "no physical exit (page gives no method)", "ok": exits.is_empty()})
	out.append({"what": "rainbow stands west of the player", "ok": rainbow.global_position.x < player.global_position.x - 500.0})
	var before := doc_state
	register_gaze(14.0)
	out.append({"what": "gaze turns the draft into the accepted entry, and nothing else", "ok": before == "draft" and doc_state == "accepted" and player.health >= 100.0})
	doc_state = "draft"
	gaze = 0.0
	said.clear()
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
