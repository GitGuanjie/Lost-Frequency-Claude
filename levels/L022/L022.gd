extends LevelBase
## Level 22 "Ruins Left Behind" (Backrooms Wikidot rev 50, accessed 2026-11-04;
## Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L022.md.
##
## PLAN (read -> design):
## - SOURCE: once an infinite, average-looking 20th-century multi-storey car park full of
##   cars and shopping trolleys; then Emstable, a micronation of "families" each working a
##   floor and passing a fraction up; mining and scavenging of the concrete weakened walls,
##   pillars and floors until it collapsed; now abandoned and destroyed. -> an authored slice
##   of three decks (3.0 m floor to floor, 8 m grid, downstand beams) under a broken roof,
##   joined by the car ramp, a concrete switchback stair core and a deck that fell into a
##   debris ramp; the decks run on past collapse rubble into the dark.
## - SOURCE: rubble and girder poles everywhere, unsafe footing; rusty, dusty 50s cars torn
##   to husks; tents (some still holding the dead, more on the lower floors); shacks of wood
##   or mined concrete, a few cookers on the middle floors; people below sleeping in the
##   open. -> deck A (Floor 8 on the census) sleeping bags and occupied tents, deck B (Floor 9,
##   concrete miners) shacks, tents and a cooker, deck C (Floor 10) crushed cars and fallen
##   roof. Painted floor labels use the census material designations.
## - SOURCE: countless large, deep mining holes; climbing them heavily unadvised; exits by
##   the post-collapse holes to Level 21 (above) and Level 23 (below); noclipping through
##   cars or debris leads to Level 817. -> the deep shaft on deck A (fall: L022>L023#2, the
##   walker-bot target), a rope up through the roof hole above deck C (L022>L021#1), and a
##   car husk on deck B you can push through (noclip: L022>L817#3).
## - Stateful mechanic: unstable ground. Sprinting over rubble can trip you on rebar; bits
##   of slab drop from the ceiling near you; the slab groans.
## - Arrivals: Level 1 glass doors (a stair-core lobby on deck B) and Level 69's exit ramp
##   ("your car parked in a parking space") beside an intact car on deck A.
## - Entity policy: none.

const S := preload("res://levels/L022/L022_struct.gd")
const DressKit := preload("res://levels/L022/L022_dress.gd")
const Layout := preload("res://levels/L022/L022_layout.gd")

var props_root: Node3D
var columns: Array = []
var debris_ramp: Array = []
var glass_door_at := Vector3.ZERO
var dress
var rough_zones: Array = []
var qa := false
var _trip_t := 2.0
var _drop_t := 20.0
var _said := {}
var drops := 0
var _flash := 0.0


func build() -> void:
	qa = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 120.0
	rules["reverb_room"] = 0.7
	rules["reverb_wet"] = 0.26
	rules["kill_y"] = -60.0
	indoor_env(Color(0.62, 0.58, 0.5), 0.34, Color(0.09, 0.085, 0.072), 0.026)
	environment.tonemap_exposure = 1.45
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.8
	environment.adjustment_contrast = 1.08
	_materials()
	lights.setup(12, 0)
	props_root = Node3D.new()
	props_root.name = "Props"
	add_child(props_root)
	var kc := kit("CarPark")
	var kv := kit("Dressing")
	dress = DressKit.new(self, kc, kv)
	S.build(self, kc)
	Layout.place(self, dress)
	dress.commit_tents()
	kc.commit()
	kv.commit()
	Layout.exits_and_arrivals(self)
	_sounds()
	add_shot("deck_b_arrival", glass_door_at + Vector3(2.2, 1.65, 0.6), Vector3(4.0, 3.6, 6.0), {"flashlight": false})
	add_shot("lower_deck_shaft", Vector3(4.0, 1.6, -13.0), Vector3(-11.5, 0.2, 6.0), {"flashlight": false})
	add_shot("debris_ramp", Vector3(9.0, 4.65, -3.0), Vector3(7.0, 5.0, -18.0), {"flashlight": false})
	add_shot("roof_hole", Vector3(17.5, 7.4, -8.5), Vector3(22.0, 10.5, -4.0), {"flashlight": false})
	add_shot("car_husks", Vector3(17.0, 1.5, 5.0), Vector3(22.0, 0.5, 12.0), {"flashlight": false})
	add_shot("stair_core", Vector3(-27.2, 4.65, -23.4), Vector3(-30.0, 3.4, -19.0), {"flashlight": true})
	add_shot("tents_shacks", Vector3(2.5, 4.65, 2.0), Vector3(-10.0, 3.8, 14.0), {"flashlight": false})


func _photo(name: String, tex: String, tint: Color, scale: float, nrm: float = 1.0) -> void:
	var m := ORMMaterial3D.new()
	var base := "res://assets/external/%s/%s_%s_1k.jpg"
	m.albedo_texture = load(base % [tex, tex, "diff"])
	m.normal_enabled = true
	m.normal_texture = load(base % [tex, tex, "nor_gl"])
	m.orm_texture = load(base % [tex, tex, "arm"])
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.normal_scale = nrm
	MatLib.register(name, m)


func _materials() -> void:
	_photo("l22_deck", "dirty_concrete", Color(0.7, 0.68, 0.64), 0.25, 1.2)
	_photo("l22_concrete", "concrete", Color(0.66, 0.65, 0.62), 0.3)
	_photo("l22_soffit", "concrete", Color(0.5, 0.5, 0.48), 0.22)
	_photo("l22_rubble", "dirty_concrete", Color(0.62, 0.6, 0.56), 0.9, 1.5)
	_photo("l22_shaftwall", "aerial_rocks_02", Color(0.42, 0.4, 0.38), 0.3, 1.5)
	_photo("l22_rust", "rusty_metal", Color(0.42, 0.33, 0.28), 0.8)
	_photo("l22_carrust", "rusty_metal", Color(0.42, 0.36, 0.32), 0.35, 1.6)
	_photo("l22_plank", "old_wood_floor", Color(0.75, 0.68, 0.6), 0.5)
	_photo("l22_sheet", "metal_plate", Color(0.55, 0.45, 0.38), 0.6)
	MatLib.define("l22_core", {"albedo_a": Color(0.4, 0.4, 0.38), "albedo_b": Color(0.34, 0.34, 0.32), "stain_amount": 0.45,
		"stain_color": Color(0.38, 0.35, 0.3), "grime_height": 0.6, "grime_color": Color(0.32, 0.3, 0.26)}, "concrete")
	MatLib.define("l22_minedblock", {"albedo_a": Color(0.55, 0.54, 0.5), "albedo_b": Color(0.44, 0.43, 0.4), "pattern": 4,
		"pattern_scale": Vector2(0.55, 0.3), "grout_width": 0.03, "grout_color": Color(0.25, 0.24, 0.22), "tile_variation": 0.25, "bump_strength": 1.6}, "concrete")
	MatLib.register("l22_dark", MatLib.standard(Color(0.05, 0.05, 0.05), 0.9))
	MatLib.register("l22_tyre", MatLib.standard(Color(0.06, 0.06, 0.06), 0.85))
	MatLib.register("l22_carpaint", MatLib.standard(Color(0.18, 0.3, 0.42), 0.35, 0.4))
	MatLib.register("l22_chrome", MatLib.standard(Color(0.62, 0.62, 0.6), 0.35, 0.8))
	MatLib.register("l22_red", MatLib.standard(Color(0.55, 0.08, 0.06), 0.6))
	MatLib.register("l22_alu", MatLib.standard(Color(0.6, 0.6, 0.6), 0.45, 0.6))
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.6, 0.7, 0.72, 0.28)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.1
	g.metallic_specular = 0.9
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l22_glass", g)
	MatLib.register("l22_bag", MatLib.standard(Color(0.24, 0.27, 0.22), 0.95))
	MatLib.register("l22_bag2", MatLib.standard(Color(0.35, 0.18, 0.12), 0.95))
	MatLib.register("l22_rug", MatLib.standard(Color(0.3, 0.22, 0.16), 1.0))
	MatLib.register("l22_cloth", MatLib.standard(Color(0.5, 0.46, 0.4), 1.0))
	MatLib.register("l22_tube_off", MatLib.standard(Color(0.7, 0.7, 0.68), 0.4))
	MatLib.register("l22_tube_on", MatLib.panel(Color(1.0, 0.85, 0.65), 2.4, 0.3))
	MatLib.register("l22_daylight", MatLib.panel(Color(0.75, 0.78, 0.8), 1.6))
	MatLib.register("l22_paint", MatLib.standard(Color(0.62, 0.6, 0.5), 0.8))


func label(text: String, p: Vector3, n: Vector3, px: float, col: Color, size: int = 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	add_child(l)
	l.global_position = p
	l.basis = Basis.looking_at(-n, Vector3.UP)
	return l


func rubble_pile(base: Vector3, size: Vector3, collide: bool) -> void:
	dress.rubble(base, size, collide)
	rough_zones.append(AABB(base - Vector3(size.x * 0.5, 0.2, size.z * 0.5), Vector3(size.x, size.y + 0.4, size.z)))


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 160.0, "rumble": 0.35, "seconds": 7.0}, -27.0)
	sound.bed("wind", {}, -30.0)
	sound.oneshot("creak", {"freq": 62.0}, 14.0, 32.0, 14.0, "[the slab overhead groans under its own weight]", -14.0)
	sound.oneshot("crackle", {}, 20.0, 45.0, 10.0, "[grit and small stones patter down somewhere nearby]", -18.0)
	sound.oneshot("distant_boom", {}, 60.0, 140.0, 30.0, "[far off, something heavy gives way and falls through several floors]", -16.0)
	sound.oneshot("drip", {"freq": 760.0}, 9.0, 22.0, 10.0, "", -20.0)
	sound.emitter("wind", Vector3(S.SHAFT.get_center().x, -2.0, S.SHAFT.get_center().y), {}, -8.0, 14.0)


# ------------------------------------------------------------------ runtime

func on_player_ready() -> void:
	if not qa:
		Overlay.subtitle("[a car park, gutted. Dust hangs in the air and the concrete creaks.]", 5.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or qa:
		return
	var p := player.global_position
	# unstable footing: sprinting across rubble can trip you on rebar and slab edges
	_trip_t -= delta
	if _trip_t <= 0.0:
		_trip_t = 1.2
		var fast := player.velocity.length() > 4.2
		for z in rough_zones:
			if (z as AABB).has_point(p + Vector3(0, 0.3, 0)) and fast and randf() < 0.35:
				player.hurt(4.0, "tripped on rebar in the rubble")
				player.velocity *= 0.2
				player.stamina = 0.0
				_flash = 0.3
				Overlay.subtitle("[your foot catches on rebar - you go down hard on the broken concrete]", 3.0)
				_trip_t = 4.0
				break
	_flash = maxf(0.0, _flash - delta * 0.5)
	Overlay.set_screen_effect("red_tint", _flash)
	# stray debris drops from the ceiling now and then
	_drop_t -= delta
	if _drop_t <= 0.0:
		_drop_t = randf_range(25.0, 60.0)
		_drop_chunk(p - player.global_transform.basis.z * 2.5 + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)))
	# the mining shaft's edge
	if Vector2(p.x, p.z).distance_to(S.SHAFT.get_center()) < 6.5 and p.y > -0.5 and p.y < 1.5 and not _said.has("shaft"):
		_said["shaft"] = true
		Overlay.subtitle("[a mining hole. Your light does not reach the bottom. Climbing down is heavily unadvised.]", 4.5)


func _drop_chunk(at: Vector3) -> void:
	var y := 0.0
	for d in S.DECKS:
		if at.y >= float(d) - 0.5:
			y = float(d)
	var top := y + S.FLOOR - S.SLAB - 0.5
	var b := RigidBody3D.new()
	b.collision_layer = 1
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.22, 0.12, 0.18)
	cs.shape = bs
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = bs.size
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("l22_rubble")
	b.add_child(mi)
	add_child(b)
	b.global_position = Vector3(at.x, top, at.z)
	b.angular_velocity = Vector3(randf(), randf(), randf()) * 3.0
	drops += 1
	sound.play_at("crackle", {}, Vector3(at.x, top, at.z), -4.0, "[a lump of concrete breaks off the ceiling and smacks down beside you]")
	get_tree().create_timer(25.0).timeout.connect(b.queue_free)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "three exits through holes and a car (L023 shaft, L021 roof rope, L817 noclip)", "ok": exits.size() == 3, "detail": exits.size()})
	var space := get_world_3d().direct_space_state
	var ok_decks := 0
	for y in [0.0, 3.0, 6.0]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(20.0, y + 1.0, 4.0), Vector3(20.0, y - 0.6, 4.0), 1))
		if not hit.is_empty() and absf((hit["position"] as Vector3).y - y) < 0.1:
			ok_decks += 1
	out.append({"what": "three walkable decks (A, B, C)", "ok": ok_decks == 3, "detail": ok_decks})
	var c := S.SHAFT.get_center()
	var deep := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(c.x, 1.0, c.y), Vector3(c.x, -30.0, c.y), 1))
	out.append({"what": "the mining shaft is open and deep", "ok": deep.is_empty()})
	out.append({"what": "rubble and girder zones make unsafe footing", "ok": rough_zones.size() >= 8, "detail": rough_zones.size()})
	var n0 := drops
	if is_inside_tree():
		_drop_chunk(Vector3(4.0, 3.2, 0.0))
	out.append({"what": "stray debris falls from the ceiling", "ok": drops == n0 + 1})
	return out


## Route checkpoints for navigation debugging: arrival, deck A core door, shaft lip.
func qa_debug_points() -> Array:
	return [glass_door_at + Vector3(1.6, 0.1, 0.2), Vector3(-28.0, 3.1, -21.0), Vector3(-29.0, 1.6, -19.2), Vector3(-30.0, 0.1, -23.2), Vector3(-24.0, 0.1, -23.0), Vector3(-11.5, 0.1, 2.0)]
