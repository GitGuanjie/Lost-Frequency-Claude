extends LevelBase
## Level 96 — "Solace" (Backrooms Wikidot rev 17, accessed 2026-11-04;
## cite: Anonymous User, CC BY-SA 3.0). Dossier: docs/canon/levels/L096.md.
## CONTENT NOTE: the page describes war, violence and the deaths of children.
## None of it is depicted here; the level is the refuge the page ends on.
##
## PLAN (v2.0 rebuild)
## SOURCE: "This is a house. It overlooks the vast ranges of mountains."
## Porcelain pitchers sit filled; doorways stand with their paint crumbling yet
## steadfast; the windows are etched with intricate patterns; the dust here is
## not from fallen buildings, "it only asks to be swept"; the carpet under your
## feet, coffee on a warm midsummer night, the dinner table; silence and
## stillness; "Stay here a while". No entities, no entrances, no exits.
## Space: one stone house on a garden ledge above a deep valley, the mountain
## ranges filling every horizon (heightfield + far ridge rings, no world edge).
## A central hall with a triple-arched front of etched glass; sitting room,
## kitchen, dining room and bedroom off it; a front terrace; an outside stone
## stair to the roof terrace (+3.6 m); seven steps down to a lower overlook
## (-1.8 m). Garden loop around the house; parapets on the drop, a retaining
## wall against the hillside. Evening light: low sun through the arches, lamps lit.
## Signature mechanic (stateful): the dust. Patches lie in the rooms; take the
## broom from beside the back door and sweep them. Sweeping is quiet and never
## scored; when the last patch is gone the house settles (the lamps warm, a
## soft chord, the page's last line). Sitting a while is always possible.
## No exit exists (none is sourced): you leave only by your own choice
## (pause menu). Helpers: L096_house.gd (house, garden, dressing), L096_land.gd.

const Land := preload("res://levels/L096/L096_land.gd")
const House := preload("res://levels/L096/L096_house.gd")
const DUST_COUNT := 7
const ETCHED_SHADER := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_schlick_ggx;
uniform vec3 tint : source_color = vec3(0.78, 0.84, 0.86);
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = abs((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float lines(vec2 p) {
	vec2 g = fract(p) - 0.5;
	float a = abs(abs(g.x) + abs(g.y) - 0.36);
	float b = abs(max(abs(g.x), abs(g.y)) - 0.26);
	vec2 r = vec2(g.x + g.y, g.x - g.y) * 0.7071;
	float c = abs(max(abs(r.x), abs(r.y)) - 0.26);
	float d = abs(length(g) - 0.12);
	float l = min(min(a, b), min(c, d));
	return 1.0 - smoothstep(0.006, 0.02, l);
}
void fragment() {
	vec2 p = (wn.x > wn.z ? wp.zy : wp.xy) * 4.0;
	float e = lines(p);
	float frost = 0.12 + 0.05 * sin(wp.y * 9.0);
	ALBEDO = mix(tint * 0.5, vec3(0.93, 0.93, 0.9), e);
	ALPHA = clamp(mix(frost, 0.78, e), 0.0, 1.0);
	ROUGHNESS = mix(0.04, 0.55, e);
	SPECULAR = 0.7;
}
"""

var land
var house
var has_broom := false
var dust: Array = []          # [{node, mat, it, pos, swept}]
var swept := 0
var settled := false
var _broom: Node3D
var _sit_left := 0.0
var _pad: AudioStreamPlayer
var _lamp_ids: Array = []
var qa_fixture := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 9000.0
	rules["reverb_room"] = 0.22
	rules["reverb_wet"] = 0.08
	rules["walk_speed"] = 2.8
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.2, 0.34, 0.62), Color(0.93, 0.74, 0.56), Color(0.2, 0.18, 0.16), Vector2(9.0, 210.0),
		Color(1.0, 0.72, 0.48), 1.7, Color(0.62, 0.6, 0.62), 0.00016)
	environment.fog_aerial_perspective = 0.3
	environment.fog_sky_affect = 0.15
	environment.ambient_light_sky_contribution = 0.55
	environment.ambient_light_color = Color(0.62, 0.55, 0.48)
	environment.ambient_light_energy = 0.8
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	sun.directional_shadow_max_distance = 90.0
	_materials()
	land = Land.new(self, level_seed)
	house = House.new(self, land)
	lights.setup(8, 1)
	lights.max_distance = 30.0
	var k := kit("House")
	house.shell(k)
	house.garden(k)
	house.rooms(k)
	k.commit()
	_no_glass_shadows()
	land.build_terrain()
	land.build_far_ridges()
	land.scatter_slopes()
	house.trees()
	_lamps()
	_broom_and_dust()
	_interactions()
	_sounds()
	add_arrival("start", Vector3(0.0, 0.02, 6.4), 0.0)
	add_landmark("Central hall and the triple arch", Vector3(0, 0, 5))
	add_landmark("Roof terrace", Vector3(5.5, 3.6, 5))
	add_landmark("Lower overlook", Vector3(0, -1.8, -16))
	add_shot("hall_arches", Vector3(0.0, 1.62, 8.7), Vector3(0.0, 1.2, -40.0), {"flashlight": false})
	add_shot("house_exterior", Vector3(-10.5, -0.45 + 1.62, -11.0), Vector3(1.0, 2.2, 4.0), {"flashlight": false})
	add_shot("dining_room", Vector3(7.1, 1.6, 4.55), Vector3(4.4, 0.75, 1.5), {"flashlight": false})
	add_shot("roof_terrace_view", Vector3(6.6, 3.6 + 1.62, 8.8), Vector3(-120.0, -40.0, -700.0), {"flashlight": false})


func _materials() -> void:
	MatLib.define("l96_stone", {"albedo_a": Color(0.74, 0.62, 0.46), "albedo_b": Color(0.64, 0.53, 0.38), "pattern": 4,
		"pattern_scale": Vector2(0.62, 0.31), "grout_width": 0.012, "grout_color": Color(0.8, 0.74, 0.62), "tile_variation": 0.12,
		"bump_strength": 1.1, "stain_amount": 0.3, "stain_color": Color(0.5, 0.42, 0.32), "noise_scale": 1.4, "roughness_a": 0.9}, "brick")
	MatLib.define("l96_rubble", {"albedo_a": Color(0.6, 0.53, 0.43), "albedo_b": Color(0.48, 0.42, 0.34), "pattern": 4,
		"pattern_scale": Vector2(0.45, 0.24), "grout_width": 0.02, "grout_color": Color(0.55, 0.5, 0.42), "tile_variation": 0.18,
		"bump_strength": 1.6, "stain_amount": 0.4, "stain_color": Color(0.36, 0.33, 0.26)}, "brick")
	MatLib.define("l96_paving", {"albedo_a": Color(0.78, 0.68, 0.54), "albedo_b": Color(0.69, 0.59, 0.46), "pattern": 1,
		"pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.42, 0.38, 0.32), "tile_variation": 0.1,
		"stain_amount": 0.3, "stain_color": Color(0.5, 0.45, 0.36), "roughness_a": 0.85}, "concrete")
	MatLib.define("l96_tile", {"albedo_a": Color(0.86, 0.8, 0.68), "albedo_b": Color(0.8, 0.73, 0.6), "pattern": 14,
		"pattern_scale": Vector2(0.22, 0.22), "grout_width": 0.008, "grout_color": Color(0.55, 0.3, 0.2), "tile_variation": 0.08,
		"pattern_color": Color(0.6, 0.32, 0.22), "pattern_strength": 0.35, "roughness_a": 0.35, "roughness_b": 0.6, "stain_amount": 0.15}, "pool_tile")
	MatLib.define("l96_plaster", {"albedo_a": Color(0.88, 0.85, 0.78), "albedo_b": Color(0.83, 0.79, 0.71), "peel_color": Color(0.5, 0.64, 0.68),
		"peel_amount": 0.12, "grime_height": 0.3, "grime_color": Color(0.62, 0.56, 0.46), "stain_amount": 0.18}, "plaster")
	MatLib.define("l96_ceiling", {"albedo_a": Color(0.36, 0.24, 0.15), "albedo_b": Color(0.3, 0.2, 0.12), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.16)}, "wood_floor")
	MatLib.define("l96_wood", {"albedo_a": Color(0.3, 0.2, 0.12), "albedo_b": Color(0.24, 0.15, 0.09)}, "wood_floor")
	MatLib.define("l96_cabinet", {"albedo_a": Color(0.42, 0.55, 0.52), "albedo_b": Color(0.36, 0.48, 0.46), "pattern": 3,
		"pattern_scale": Vector2(0.5, 0.25), "peel_color": Color(0.5, 0.36, 0.24), "peel_amount": 0.3}, "wood_floor")
	MatLib.define("l96_frame", {"albedo_a": Color(0.3, 0.47, 0.48), "albedo_b": Color(0.26, 0.41, 0.42), "peel_color": Color(0.83, 0.78, 0.68),
		"peel_amount": 0.42, "roughness_a": 0.6, "roughness_b": 0.85, "bump_strength": 0.9}, "plaster")
	MatLib.define("l96_door", {"albedo_a": Color(0.32, 0.46, 0.47), "albedo_b": Color(0.28, 0.4, 0.41), "pattern": 3,
		"pattern_scale": Vector2(0.18, 2.2), "grout_color": Color(0.18, 0.24, 0.24), "peel_color": Color(0.46, 0.33, 0.22), "peel_amount": 0.35}, "wood_floor")
	MatLib.define("l96_shutter", {"albedo_a": Color(0.24, 0.38, 0.3), "albedo_b": Color(0.2, 0.33, 0.26), "pattern": 2,
		"pattern_scale": Vector2(0.08, 1.0), "pattern_color": Color(0.12, 0.2, 0.16), "pattern_strength": 0.6,
		"peel_color": Color(0.5, 0.4, 0.3), "peel_amount": 0.3}, "wood_floor")
	MatLib.define("l96_marble", {"albedo_a": Color(0.9, 0.88, 0.84), "albedo_b": Color(0.82, 0.8, 0.76), "noise_scale": 2.2,
		"roughness_a": 0.25, "roughness_b": 0.4, "stain_amount": 0.2, "stain_color": Color(0.7, 0.66, 0.6)}, "plaster")
	MatLib.define("l96_roof", {"albedo_a": Color(0.64, 0.28, 0.17), "albedo_b": Color(0.54, 0.23, 0.14), "pattern": 14,
		"pattern_scale": Vector2(0.28, 0.2), "grout_width": 0.02, "grout_color": Color(0.32, 0.14, 0.08), "tile_variation": 0.15,
		"stain_amount": 0.35, "stain_color": Color(0.4, 0.3, 0.22)}, "brick")
	MatLib.define("l96_garden", {"albedo_a": Color(0.3, 0.3, 0.17), "albedo_b": Color(0.36, 0.32, 0.2), "pattern": 12,
		"pattern_color": Color(0.24, 0.3, 0.12), "pattern_strength": 0.6, "noise_scale": 0.25, "stain_amount": 0.4,
		"stain_color": Color(0.42, 0.36, 0.24), "stain_scale": 0.15}, "grass")
	MatLib.define("l96_rug_a", {"albedo_a": Color(0.45, 0.1, 0.08), "albedo_b": Color(0.36, 0.07, 0.06), "pattern": 10,
		"pattern_scale": Vector2(0.45, 0.45), "pattern_color": Color(0.1, 0.12, 0.26), "pattern_strength": 0.6, "roughness_a": 1.0, "wetness": 0.0, "stain_amount": 0.12}, "l0_carpet")
	MatLib.define("l96_rug_b", {"albedo_a": Color(0.15, 0.17, 0.3), "albedo_b": Color(0.12, 0.13, 0.24), "pattern": 10,
		"pattern_scale": Vector2(0.38, 0.38), "pattern_color": Color(0.6, 0.45, 0.25), "pattern_strength": 0.55, "roughness_a": 1.0, "wetness": 0.0, "stain_amount": 0.12}, "l0_carpet")
	MatLib.define("l96_rug_fringe", {"albedo_a": Color(0.82, 0.78, 0.66), "albedo_b": Color(0.76, 0.72, 0.6), "pattern": 2,
		"pattern_scale": Vector2(0.02, 1.0)}, "plaster")
	MatLib.define("l96_cushion", {"albedo_a": Color(0.55, 0.38, 0.22), "albedo_b": Color(0.48, 0.32, 0.18), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.38, 0.1, 0.08), "pattern_strength": 0.5, "roughness_a": 1.0}, "plaster")
	MatLib.define("l96_linen", {"albedo_a": Color(0.9, 0.88, 0.82), "albedo_b": Color(0.85, 0.83, 0.77)}, "plaster")
	MatLib.define("l96_blanket", {"albedo_a": Color(0.5, 0.16, 0.12), "albedo_b": Color(0.42, 0.12, 0.1), "pattern": 9,
		"pattern_scale": Vector2(0.2, 0.2), "pattern_color": Color(0.82, 0.74, 0.58), "pattern_strength": 0.4}, "plaster")
	MatLib.define("l96_porcelain", {"albedo_a": Color(0.94, 0.94, 0.92), "albedo_b": Color(0.9, 0.91, 0.9), "pattern": 10,
		"pattern_scale": Vector2(0.06, 0.06), "pattern_color": Color(0.2, 0.3, 0.6), "pattern_strength": 0.45,
		"roughness_a": 0.08, "roughness_b": 0.14, "bump_strength": 0.0}, "plaster")
	MatLib.define("l96_brass", {"albedo_a": Color(0.62, 0.46, 0.2), "albedo_b": Color(0.52, 0.38, 0.16), "metallic_value": 0.9,
		"roughness_a": 0.3, "roughness_b": 0.45}, "metal")
	MatLib.define("l96_clay", {"albedo_a": Color(0.7, 0.42, 0.28), "albedo_b": Color(0.62, 0.36, 0.24)}, "plaster")
	MatLib.define("l96_iron", {"albedo_a": Color(0.16, 0.16, 0.16), "albedo_b": Color(0.12, 0.12, 0.12), "roughness_a": 0.5}, "metal")
	MatLib.define("l96_straw", {"albedo_a": Color(0.72, 0.6, 0.34), "albedo_b": Color(0.6, 0.48, 0.26), "pattern": 2,
		"pattern_scale": Vector2(0.01, 1.0)}, "plaster")
	var sh := Shader.new()
	sh.code = ETCHED_SHADER
	var em := ShaderMaterial.new()
	em.shader = sh
	MatLib.register("l96_etched", em)


func _no_glass_shadows() -> void:
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.material_override == MatLib.get_mat("l96_etched") or (m.mesh and m.mesh.get_surface_count() > 0 and m.mesh.surface_get_material(0) == MatLib.get_mat("l96_etched")):
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _lamps() -> void:
	var warm := Color(1.0, 0.76, 0.5)
	_lamp_ids.append(lights.add_anchor(Vector3(0, 3.55, 5.0), warm, 1.5, 7.5))
	_lamp_ids.append(lights.add_anchor(Vector3(5.3, 2.45, 2.7), warm, 1.25, 5.5))
	_lamp_ids.append(lights.add_anchor(Vector3(-7.1, 1.45, 4.4), warm, 0.9, 4.5))
	_lamp_ids.append(lights.add_anchor(Vector3(-5.3, 3.0, 7.3), Color(1.0, 0.85, 0.65), 0.7, 4.5))
	_lamp_ids.append(lights.add_anchor(Vector3(5.5, 2.9, 7.5), warm, 0.65, 4.2))
	_lamp_ids.append(lights.add_anchor(Vector3(0, 2.75, -0.55), warm, 1.0, 6.0))
	# the terrace lantern beside the door
	var k := kit("Lantern")
	k.box(Vector3(0, 2.95, -0.08), Vector3(0.08, 0.08, 0.16), "l96_iron", GeoKit.ALL, false)
	k.commit()
	Props.place(self, house.dress, "ph/lantern_chandelier_01", Vector3(0, 2.25, -0.32), 0.0, 0.7)


# ------------------------------------------------------------------ dust

func _broom_and_dust() -> void:
	# the broom leans beside the hall's back door
	_broom = Node3D.new()
	_broom.name = "Broom"
	_broom.position = Vector3(1.22, 0.0, 9.42)
	_broom.rotation = Vector3(deg_to_rad(-8.0), 0.0, deg_to_rad(6.0))
	add_child(_broom)
	var handle := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.014
	cm.bottom_radius = 0.016
	cm.height = 1.25
	handle.mesh = cm
	handle.material_override = MatLib.get_mat("l96_wood")
	handle.position = Vector3(0, 0.82, 0)
	_broom.add_child(handle)
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.05
	hm.bottom_radius = 0.16
	hm.height = 0.3
	hm.radial_segments = 10
	head.mesh = hm
	head.material_override = MatLib.get_mat("l96_straw")
	head.scale = Vector3(1.0, 1.0, 0.35)
	head.position = Vector3(0, 0.16, 0)
	_broom.add_child(head)
	add_interactable(Vector3(1.24, 0.75, 9.36), Vector3(0.45, 1.5, 0.35), "Take the broom", _take_broom)
	# dust patches: seven of the candidate places, chosen by the seed
	var spots: Array = house.dust_spots.duplicate()
	for i in range(spots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = spots[i]
		spots[i] = spots[j]
		spots[j] = tmp
	# dust texture, generated synchronously (no worker thread)
	var noise := FastNoiseLite.new()
	noise.seed = 96
	noise.frequency = 0.04
	noise.fractal_octaves = 4
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	for y in 96:
		for x in 96:
			var d := Vector2(x - 47.5, y - 47.5).length() / 48.0
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			img.set_pixel(x, y, Color(n * 0.3 + 0.7, n * 0.3 + 0.7, n * 0.3 + 0.7, clampf((n - 0.25) * 1.6 * (1.0 - d * d), 0.0, 1.0)))
	var tex := ImageTexture.create_from_image(img)
	for i in mini(DUST_COUNT, spots.size()):
		var p: Vector3 = spots[i]
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.66, 0.62, 0.54, 0.75)
		mat.albedo_texture = tex
		mat.roughness = 1.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1.2, 0.95)
		mi.mesh = pm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = p + Vector3(0, 0.016, 0)
		mi.rotation.y = rng.randf() * TAU
		add_child(mi)
		var it := add_interactable(p + Vector3(0, 0.2, 0), Vector3(1.1, 0.4, 0.9), "Sweep the dust", _sweep.bind(i))
		dust.append({"node": mi, "mat": mat, "it": it, "pos": p, "swept": false})


func _take_broom() -> void:
	if has_broom:
		return
	has_broom = true
	_broom.visible = false
	Overlay.subtitle("[you take the broom; its bristles are worn but sound]", 3.5)


func _sweep(i: int) -> void:
	var d: Dictionary = dust[i]
	if d["swept"]:
		return
	if not has_broom:
		Overlay.subtitle("[you brush at the dust with your hand; it only smears. A broom stands by the back door]", 4.0)
		return
	d["swept"] = true
	swept += 1
	var it: Interactable = d["it"]
	it.prompt = ""
	it.collision_layer = 0
	sound.play_at("scratch", {"seconds": 1.6}, d["pos"] + Vector3(0, 0.3, 0), -16.0, "[the broom whispers over the floor]")
	var tw := create_tween()
	tw.tween_property(d["mat"], "albedo_color:a", 0.0, 1.8)
	tw.tween_callback(func() -> void: (d["node"] as Node3D).visible = false)
	if swept >= dust.size():
		_settle()


## Every patch swept: the house settles. Nothing is scored or counted aloud.
func _settle() -> void:
	if settled:
		return
	settled = true
	for id in _lamp_ids:
		lights.anchors[id]["energy"] = float(lights.anchors[id]["energy"]) * 1.25
	if _pad:
		var tw := create_tween()
		tw.tween_property(_pad, "volume_db", -22.0, 6.0)
	Overlay.subtitle("[the last of the dust settles out of the light. The house is quiet]", 5.0)
	Overlay.toast("\"It only asks for your solace.\" (Level 96)", 7.0)


# ------------------------------------------------------------- interactions

func _interactions() -> void:
	add_note("l96_house", "A sheet of paper on the hall table",
		"This is a house. It looks out over wide ranges of mountains.\n\nThe porcelain pitchers are full. The paint in the doorways crumbles, but the frames still stand. Fine patterns are etched into the windows.\n\nThe dust here does not come from fallen buildings or from weapons. It only wants sweeping.\n\n(paraphrase of the Level 96 page)",
		Vector3(-0.3, 0.45, 4.75))
	add_note("l96_table", "A folded note on the dinner table",
		"Hold on to the familiar moments. Keep the dinner table where you talk with the people you love, and keep your culture.\n\nStay here a while. Nothing here will ask anything of your fear.\n\n(paraphrase of the Level 96 page)",
		Vector3(5.3, 0.9, 2.45))
	add_note("l96_memory", "Pencilled lines on the nightstand",
		"The carpet against bare feet. Coffee on a warm midsummer night. The drive home through the mountains, fighting sleep, the ravines under the overpasses.\n\nNothing else will feel like that.\n\n(paraphrase of the Level 96 page)",
		Vector3(5.85, 0.72, 9.1))
	for p in [Vector3(0.12, 0.43, 5.05), Vector3(4.95, 0.89, 2.7), Vector3(-5.5, 0.76, 7.25)]:
		add_interactable(p + Vector3(0, 0.13, 0), Vector3(0.24, 0.3, 0.24), "Look into the porcelain pitcher", func() -> void:
			Overlay.subtitle("[the porcelain pitcher is filled to the brim with still, clear water]", 3.5))
	add_interactable(Vector3(-7.1, 0.95, 6.0), Vector3(0.8, 0.3, 0.8), "Touch the stove", func() -> void:
		Overlay.subtitle("[the stove is cold. You remember the smell of coffee on a warm midsummer night]", 4.5))
	for d in [Vector3(-3.0, 1.1, 2.5), Vector3(3.0, 1.1, 7.5), Vector3(0.0, 1.2, 0.25)]:
		add_interactable(d, Vector3(0.6, 2.0, 0.6) if d.z > 0.3 else Vector3(1.5, 2.0, 0.7), "Touch the doorframe", func() -> void:
			Overlay.subtitle("[old paint flakes under your fingers; the frame beneath stands firm]", 3.5))
	for w in [Vector3(-1.55, 1.6, 0.25), Vector3(1.55, 1.6, 0.25)]:
		add_interactable(w, Vector3(1.0, 1.6, 0.6), "Look at the etched glass", func() -> void:
			Overlay.subtitle("[fine patterns are etched into the glass; the mountains blur behind them]", 3.5))
	add_interactable(Vector3(0, -1.8 + 1.1, -19.7), Vector3(15.0, 0.8, 0.6), "Look out over the mountains", func() -> void:
		Overlay.subtitle("[range after range of mountains, fading into the evening haze. Nothing moves]", 4.5))
	for s in [Vector3(-2.48, 0.6, 5.0), Vector3(2.48, 0.6, 5.0), Vector3(-4.0, -1.35, -19.45), Vector3(5.2, 4.0, 1.2)]:
		add_interactable(s, Vector3(0.7, 0.5, 2.0) if absf(s.x) > 2.0 and s.y > 0.0 and s.y < 1.0 else Vector3(1.4, 0.6, 0.8), "Sit a while", _sit)


func _sit() -> void:
	if _sit_left > 0.0 or player == null:
		return
	_sit_left = 8.0
	player.frozen = true
	Overlay.subtitle("[you sit. The stillness asks nothing of you]", 6.0)


func level_process(delta: float) -> void:
	if _sit_left > 0.0:
		_sit_left -= delta
		if _sit_left <= 0.0 and player:
			player.frozen = false


func _sounds() -> void:
	sound.bed("wind", {"seconds": 12.0}, -36.0)
	sound.bed("crickets", {"seconds": 8.0}, -33.0)
	sound.bed("room_tone", {"cutoff": 260.0, "rumble": 0.1}, -42.0)
	_pad = sound.bed("pad", {"root": 146.83, "chord": [0, 7, 12, 16], "bright": 0.05, "seconds": 12.0}, -40.0, "Music")
	sound.oneshot("creak", {"freq": 0.6}, 50.0, 110.0, 10.0, "[a shutter creaks softly in the evening air]", -26.0)


func on_player_ready() -> void:
	if not qa_fixture:
		Overlay.toast("Content note: this level's source page describes war, violence and the deaths of children. None of it is shown here.", 8.0)


# ------------------------------------------------------------------ QA

func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


func qa_self_test() -> Array:
	await get_tree().physics_frame
	var out: Array = []
	out.append({"what": "no invented exit (page documents none)", "ok": exits.is_empty()})
	out.append({"what": "dust patches placed", "ok": dust.size() == DUST_COUNT, "detail": dust.size()})
	var roof := _ray(Vector3(5.5, 6.0, 6.0), Vector3(5.5, 2.0, 6.0))
	out.append({"what": "roof terrace floor collides at +3.6 m", "ok": not roof.is_empty() and absf(roof["position"].y - 3.6) < 0.05, "detail": roof.get("position")})
	var mid := _ray(Vector3(8.7, 4.0, 7.6), Vector3(8.7, -2.0, 7.6))
	out.append({"what": "roof stair has ramp collision", "ok": not mid.is_empty() and mid["position"].y > 1.0 and mid["position"].y < 2.6, "detail": mid.get("position")})
	var low := _ray(Vector3(4.0, 1.0, -16.0), Vector3(4.0, -4.0, -16.0))
	out.append({"what": "lower overlook floor collides at -1.8 m", "ok": not low.is_empty() and absf(low["position"].y + 1.8) < 0.05, "detail": low.get("position")})
	var edge := _ray(Vector3(0.0, -1.0, -19.0), Vector3(0.0, -1.0, -21.0))
	out.append({"what": "overlook parapet blocks the drop", "ok": not edge.is_empty()})
	# the dust mechanic: hand only smears, broom sweeps, the house settles
	_sweep(0)
	out.append({"what": "dust stays without the broom", "ok": swept == 0 and not dust[0]["swept"]})
	_take_broom()
	for i in dust.size():
		_sweep(i)
	out.append({"what": "broom sweeps every patch and the house settles", "ok": swept == DUST_COUNT and settled, "detail": swept})
	return out
