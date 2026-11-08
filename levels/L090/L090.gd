extends LevelBase
## Level 90 — "Newly Renovated Home" (Backrooms Wikidot rev 36, accessed
## 2026-11-04; cite: ratscrapz, CC BY-SA 3.0). Dossier: docs/canon/levels/L090.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: the whole page is a cheerful sales pitch from an unnamed renovation
## team: "a newly renovated house" with two floors, a "pretty big attic", two
## bedrooms and two bathrooms; it "used to be real bad" (a "torture labyrinth")
## and had a Death Rat infestation the "exterminator guy" removed; nobody lives
## here yet, it is hard to sell because of its reputation; an air conditioner
## was installed but is "in shambles"; anyone who means well may stay; the exit
## is near the old oak tree in the backyard and you can come back any time.
## ADAPTATION: an ordinary staged family house for sale (hall with stair; living
## room, open kitchen and dining; laundry, bathroom 1, a den still mid-paint;
## upstairs bedroom 1, bathroom 2, bedroom 2 and a bonus room with a steep stair
## to a walkable attic) on a fenced lot with a chained front gate, woods all
## round fading into late-afternoon haze, and a huge old oak in the back garden.
## The voice is unreliable, so the house is fresh paint over small wrongness:
## a door under the stair painted shut that breathes cold stone air, snap traps
## and bait boxes along the attic eaves, scratching in the walls that might be
## the house settling. No labyrinth is walkable and no rat appears (canon trap).
## Stateful mechanic (from "in shambles"): the hall thermostat starts the AC;
## it rattles, coughs and trips the house breaker; the lights die until you
## reset the panel in the laundry; it fails the same way every time.
## Exit: walk past the old oak (walk_in) on the worn path round its far side.
## Verticality: ground floor, first floor, attic, porch and deck.
## Helpers: L090_house.gd (the house), L090_yard.gd (lot, oak, woods).

const HOUSE := preload("res://levels/L090/L090_house.gd")
const YARD := preload("res://levels/L090/L090_yard.gd")
const SUN := Vector2(17.0, 212.0)

var house
var yard
var power := true
var ac_state := "idle"           # idle | starting
var ac_t := 0.0
var ac_tries := 0
var house_lights: Array = []     # anchor indices
var house_energy: Array = []
var power_k := 1.0
var beds := {}
var ac_hum: AudioStreamPlayer3D
var ac_out: AudioStreamPlayer3D
var attic_t := 6.0
var scratch_t := 40.0
var said := {}
var oak_exit: ExitTrigger
var thermo_mat: StandardMaterial3D


func build() -> void:
	house = HOUSE.new(self)
	yard = YARD.new(self)
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.25
	rules["reverb_wet"] = 0.1
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.38, 0.5, 0.68), Color(0.86, 0.74, 0.6), Color(0.3, 0.28, 0.22), SUN, Color(1.0, 0.8, 0.58), 1.55, Color(0.74, 0.68, 0.58), 0.011)
	environment.ambient_light_sky_contribution = 0.7
	environment.ambient_light_energy = 0.65
	environment.fog_sky_affect = 0.35
	environment.fog_aerial_perspective = 0.5
	environment.tonemap_exposure = 1.05
	environment.ssao_enabled = true
	environment.glow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_blur = 1.4
	_materials()
	lights.setup(9, 0)
	var home := Node3D.new()
	home.name = "Home"
	add_child(home)
	house.build(home)
	var lot := Node3D.new()
	lot.name = "Lot"
	add_child(lot)
	yard.build(lot)
	for l in house.lights:
		house_lights.append(lights.add_anchor(l[0], l[1], l[2], l[3], 0.0, "house"))
		house_energy.append(l[2])
	for l in yard.lights:
		lights.add_anchor(l[0], l[1], l[2], l[3], 0.0, "yard")
	_fixtures()
	_notes()
	_exits()
	_sounds()
	add_arrival("start", Vector3(-0.22, HOUSE.F0 + 0.05, 1.5), 180.0)
	add_arrival("from_L025", Vector3(4.1, 0.05, -11.8), 180.0)
	add_landmark("Front hall and stair", Vector3(-0.2, HOUSE.F0, 3.0))
	add_landmark("The attic (broken air conditioner)", Vector3(-2.6, HOUSE.A, 5.6))
	add_landmark("The old oak tree", YARD.OAK)
	_shots()


# ---------------------------------------------------------------- materials

func _photo(name: String, asset: String, tint: Color, repeat_m: float, rough: float = -1.0) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint, "albedo_b": tint.darkened(0.08)}, "plaster")
		return
	var m := ORMMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	if ResourceLoader.exists(base % "arm"):
		m.orm_texture = load(base % "arm")
	if rough >= 0.0:
		m.orm_texture = null
		m.roughness = rough
	m.uv1_scale = Vector3(1.0 / repeat_m, 1.0 / repeat_m, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	MatLib.register(name, m)


func _materials() -> void:
	_photo("l90_stucco", "painted_plaster_wall", Color(0.93, 0.87, 0.76), 2.4)
	MatLib.define("l90_paint", {"albedo_a": Color(0.9, 0.88, 0.83), "albedo_b": Color(0.87, 0.85, 0.8), "noise_scale": 1.3,
		"roughness_a": 0.8, "roughness_b": 0.9, "bump_strength": 0.25, "stain_amount": 0.0}, "plaster")
	MatLib.define("l90_paint2", {"albedo_a": Color(0.8, 0.85, 0.83), "albedo_b": Color(0.77, 0.82, 0.8), "noise_scale": 1.3,
		"roughness_a": 0.8, "roughness_b": 0.9, "bump_strength": 0.25, "stain_amount": 0.0}, "plaster")
	MatLib.define("l90_ceiling", {"albedo_a": Color(0.93, 0.92, 0.89), "albedo_b": Color(0.91, 0.9, 0.87), "noise_scale": 0.8,
		"roughness_a": 0.9, "roughness_b": 0.95, "bump_strength": 0.15, "stain_amount": 0.0}, "plaster")
	_photo("l90_wood", "old_wood_floor", Color(1.0, 1.0, 1.0), 2.0)
	_photo("l90_stair", "old_wood_floor", Color(0.82, 0.66, 0.5), 1.6)
	_photo("l90_deck", "old_wood_floor", Color(0.78, 0.7, 0.6), 1.8)
	_photo("l90_deck_frame", "old_wood_floor", Color(0.5, 0.44, 0.38), 1.8)
	_photo("l90_attic_floor", "old_wood_floor", Color(0.74, 0.62, 0.48), 1.6)
	_photo("l90_attic_wood", "old_wood_floor", Color(0.86, 0.72, 0.54), 1.2)
	_photo("l90_plywood", "old_wood_floor", Color(0.92, 0.8, 0.62), 2.6, 0.9)
	_photo("l90_fence", "old_wood_floor", Color(0.72, 0.62, 0.52), 1.4)
	_photo("l90_fence_post", "old_wood_floor", Color(0.55, 0.47, 0.4), 1.2)
	_photo("l90_brick", "brick_4", Color(0.86, 0.78, 0.74), 1.8)
	_photo("l90_drive", "concrete", Color(0.92, 0.9, 0.86), 3.0)
	_photo("l90_paver", "concrete", Color(0.84, 0.8, 0.74), 1.4)
	_photo("l90_stone", "concrete", Color(0.66, 0.64, 0.6), 0.9)
	MatLib.define("l90_tile_floor", {"albedo_a": Color(0.86, 0.85, 0.82), "albedo_b": Color(0.8, 0.79, 0.76), "pattern": 1,
		"pattern_scale": Vector2(0.4, 0.4), "grout_width": 0.008, "grout_color": Color(0.55, 0.54, 0.52), "roughness_a": 0.25, "roughness_b": 0.4}, "pool_tile")
	MatLib.define("l90_tile_wall", {"albedo_a": Color(0.9, 0.93, 0.92), "albedo_b": Color(0.86, 0.9, 0.89), "pattern": 14,
		"pattern_scale": Vector2(0.3, 0.15), "grout_width": 0.006, "grout_color": Color(0.7, 0.72, 0.7)}, "pool_tile")
	MatLib.define("l90_roof", {"albedo_a": Color(0.24, 0.24, 0.26), "albedo_b": Color(0.18, 0.18, 0.2), "pattern": 14,
		"pattern_scale": Vector2(0.34, 0.2), "grout_width": 0.012, "grout_color": Color(0.08, 0.08, 0.09), "roughness_a": 0.85,
		"roughness_b": 0.95, "noise_scale": 2.5, "bump_strength": 0.8}, "concrete")
	MatLib.define("l90_insul", {"albedo_a": Color(0.86, 0.6, 0.58), "albedo_b": Color(0.74, 0.5, 0.48), "noise_scale": 6.0,
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.6}, "plaster")
	MatLib.define("l90_accent", {"albedo_a": Color(0.36, 0.48, 0.47), "albedo_b": Color(0.33, 0.45, 0.44), "noise_scale": 1.4,
		"stain_amount": 0.0}, "plaster")
	MatLib.register("l90_trim", MatLib.standard(Color(0.94, 0.93, 0.89), 0.45))
	MatLib.register("l90_frame", MatLib.standard(Color(0.96, 0.96, 0.94), 0.4))
	MatLib.register("l90_door", MatLib.standard(Color(0.92, 0.91, 0.87), 0.5))
	MatLib.register("l90_door_front", MatLib.standard(Color(0.18, 0.24, 0.3), 0.45))
	MatLib.register("l90_shutter", MatLib.standard(Color(0.2, 0.27, 0.3), 0.6))
	MatLib.register("l90_gutter", MatLib.standard(Color(0.85, 0.85, 0.82), 0.4, 0.3))
	MatLib.register("l90_brass", MatLib.standard(Color(0.75, 0.6, 0.3), 0.3, 0.9))
	MatLib.register("l90_chain", MatLib.standard(Color(0.45, 0.45, 0.46), 0.35, 0.9))
	MatLib.register("l90_tape", MatLib.standard(Color(0.25, 0.45, 0.85), 0.7))
	MatLib.register("l90_ac_metal", MatLib.standard(Color(0.7, 0.71, 0.7), 0.5, 0.6))
	MatLib.register("l90_ac_dark", MatLib.standard(Color(0.12, 0.12, 0.12), 0.7, 0.3))
	MatLib.register("l90_ac_fan", MatLib.standard(Color(0.3, 0.3, 0.32), 0.5, 0.6))
	MatLib.register("l90_wire0", MatLib.standard(Color(0.7, 0.1, 0.1), 0.5))
	MatLib.register("l90_wire1", MatLib.standard(Color(0.1, 0.2, 0.7), 0.5))
	MatLib.register("l90_wire2", MatLib.standard(Color(0.1, 0.1, 0.1), 0.5))
	MatLib.register("l90_bait", MatLib.standard(Color(0.08, 0.08, 0.08), 0.6))
	MatLib.register("l90_trap_wood", MatLib.standard(Color(0.7, 0.55, 0.35), 0.8))
	MatLib.register("l90_trap_metal", MatLib.standard(Color(0.6, 0.6, 0.6), 0.3, 0.9))
	MatLib.register("l90_sign", MatLib.standard(Color(0.95, 0.94, 0.9), 0.6))
	MatLib.register("l90_sign2", MatLib.standard(Color(0.75, 0.18, 0.16), 0.6))
	MatLib.register("l90_bark_col", MatLib.standard(Color(0.3, 0.26, 0.22), 1.0))
	var gl := StandardMaterial3D.new()
	gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl.albedo_color = Color(0.72, 0.8, 0.84, 0.16)
	gl.roughness = 0.04
	gl.metallic_specular = 0.9
	MatLib.register("l90_glass", gl)
	YARD.materials()
	# the bark cylinder is only a collider; hide it under the grown trunk
	var inv := StandardMaterial3D.new()
	inv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inv.albedo_color = Color(0, 0, 0, 0)
	MatLib.register("l90_bark_col", inv)


# ---------------------------------------------------------------- fixtures and notes

func _fixtures() -> void:
	var a: Dictionary = house.anchors
	# thermostat: a small box with a lit display
	var tp: Vector3 = a["thermostat"]
	var k := kit("Thermostat")
	k.box(tp, Vector3(0.03, 0.12, 0.09), "l90_trim", GeoKit.ALL, false)
	k.commit()
	var disp := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.03)
	disp.mesh = qm
	thermo_mat = StandardMaterial3D.new()
	thermo_mat.albedo_color = Color(0.1, 0.2, 0.15)
	thermo_mat.emission_enabled = true
	thermo_mat.emission = Color(0.35, 0.9, 0.55)
	thermo_mat.emission_energy_multiplier = 1.4
	disp.material_override = thermo_mat
	disp.position = tp + Vector3(0.017, 0.02, 0)
	disp.rotation.y = PI * 0.5
	add_child(disp)
	add_interactable(tp, Vector3(0.4, 0.4, 0.4), "Turn on the air conditioning", _thermostat)
	add_interactable(a["breaker"], Vector3(0.6, 0.7, 0.5), "Open the breaker panel", _breaker)
	add_interactable(a["cupboard"], Vector3(0.6, 1.8, 1.0), "Try the door under the stairs", func():
		Overlay.subtitle("[painted shut - several fresh coats. Cold air comes through the gap under it, and a smell of old wet stone that goes further down than any cupboard should.]", 7.0)
		_mark("cupboard"))
	add_interactable(a["ac"] + Vector3(0, 0.8, 0.6), Vector3(1.8, 1.6, 1.2), "Look at the air handler", func():
		Overlay.subtitle("[the front panel is off and lying on the boards. Loose wires, a fan with a bent blade, a duct that stops short of anything. 'In shambles' is generous.]", 7.0)
		_mark("ac"))
	add_interactable(Vector3(7.75, 0.6, 7.2), Vector3(0.8, 1.2, 2.0), "Look at the outdoor unit", func():
		Overlay.subtitle("[the condenser's grille is dented in and the fan doesn't turn. Someone has taped a sticky note to it: 'working on it!!' with a smiley.]", 6.0))
	add_interactable(yard.anchors["gate"], Vector3(3.4, 2.0, 1.0), "Try the gate", func():
		Overlay.subtitle("[chained and padlocked, the chain new and shiny. The lane beyond goes off between the trees into the haze. Not that way, then.]", 6.0)
		_mark("gate"))
	add_interactable(yard.anchors["sign"], Vector3(1.6, 1.6, 0.6), "Read the sign", func():
		Overlay.subtitle("[FOR SALE - NEWLY RENOVATED! - MOVE-IN READY. No agent's name, no phone number. Just a hand-drawn heart in the corner.]", 6.0))


func _notes() -> void:
	var a: Dictionary = house.anchors
	add_note("l90_flyer", "Welcome flyer (on the hall table)", "Heyyy, welcome home!\n\nIt's a newly renovated house, and \"we made it just for you!\"\n\nFeatures:\n - TWO floors\n - a pretty big attic\n - TWO bedrooms, TWO bathrooms\n - tons of space to safely put all your things\n\nSure, the place used to be real bad. Don't worry about that. Our team got straight to work!\n\n(The flyer is unsigned: \"the team\". The voice of the house, not a survey.)", a["flyer"] + Vector3(0, 0.03, 0))
	add_note("l90_brochure", "Glossy brochure (kitchen counter)", "WHY HAVEN'T WE SOLD YET?\n\nHonestly? Reputation. Folks still remember the old torture labyrinth. But it's not that bad anymore, we promise!\n\nBring friends. Bring family. As long as you mean well, we don't care that much who stays here.\n\n(Sales copy from the renovation team. Treat its claims as testimony.)", a["brochure"] + Vector3(0, 0.03, 0))
	add_note("l90_invoice", "Invoice, folded (on the washing machine)", "PEST CONTROL - FINAL INVOICE\nJob: Death Rat infestation, whole house.\nStatus: COMPLETE. Guaranteed!\n\nNote from the team, pencilled on the back: \"Our amazing exterminator guy got the job done. You'd never be able to tell they were here!\"\n\n(No company name, no date. The traps upstairs are still set.)", a["invoice"] + Vector3(0, 0.03, 0))
	add_note("l90_sticky", "Sticky note (stuck to the air handler)", "AC!!\nIt's... in shambles currently.\nBut we're working on it!\n:)\n\n(Handwriting matches the flyer's.)", a["ac"] + Vector3(0.6, 1.52, 0.1), Vector3(0.4, 0.05, 0.3))
	var dk := Vector3(-4.6, HOUSE.F0 + 0.03, HOUSE.Z1 + 1.4)
	add_note("l90_back_door", "Note pinned under a deck chair", "Ah, well. We tried.\n\nWe won't stop you if you really don't want the place. There's an exit near the old oak tree in the backyard.\n\nYou can come back any time you like, though! We know you'll come around.\n\n(Paraphrase of the team's own words; where the exit leads is never said.)", dk)


# ---------------------------------------------------------------- exits

func _exits() -> void:
	var p: Vector3 = yard.anchors["oak_back"]
	oak_exit = add_exit("L090>EXT#1", "walk_in", p + Vector3(0, 1.2, 0), Vector3(2.8, 2.4, 2.2), "")
	if oak_exit:
		oak_exit.fired.connect(func(_id): Overlay.glitch(0.6))


# ---------------------------------------------------------------- the air conditioner

func _thermostat() -> void:
	if not power:
		Overlay.subtitle("[the thermostat's display is dead. The power's out.]", 3.5)
		return
	if ac_state != "idle":
		return
	ac_state = "starting"
	ac_t = 0.0
	ac_tries += 1
	Overlay.subtitle("[click. Somewhere above the ceiling, something heavy shudders awake.]", 4.0)
	_mark("thermostat")


func _breaker() -> void:
	if power:
		Overlay.subtitle("[a row of new breakers, all on. One is labelled in marker: AC (don't).]", 4.5)
		return
	power = true
	ac_state = "idle"
	sound.play_at("pipe_clank", {"f": 320.0}, house.anchors["breaker"], -10.0)
	Overlay.subtitle("[you push the tripped breaker back. The house hums and the lights come back on, as if nothing happened.]", 5.0)
	_mark("breaker")


func _ac_process(delta: float) -> void:
	if ac_state == "starting":
		ac_t += delta
		var att: Vector3 = house.anchors["ac"]
		ac_hum.volume_db = lerpf(ac_hum.volume_db, -6.0, minf(delta * 2.0, 1.0))
		ac_out.volume_db = lerpf(ac_out.volume_db, -10.0, minf(delta * 2.0, 1.0))
		if int(ac_t * 3.0) != int((ac_t - delta) * 3.0) and ac_t > 1.5:
			sound.play_at("pipe_clank", {"f": 140.0 + 40.0 * sin(ac_t * 7.0)}, att + Vector3(0, 1.0, 0), -8.0 + ac_t)
		if ac_t > 6.0:
			ac_state = "idle"
			power = false
			sound.play_at("distant_boom", {}, att, 0.0)
			sound.play_at("crackle", {"seconds": 1.2}, house.anchors["breaker"], -6.0)
			var lines := ["[a bang overhead, a smell of hot dust - and every light in the house goes out.]",
				"[same as last time: the rattle, the bang, the dark.]",
				"[it does exactly the same thing again. 'We're working on it.']"]
			Overlay.subtitle(lines[mini(ac_tries - 1, 2)], 5.5)
	else:
		var idle := -40.0 if power else -80.0
		ac_hum.volume_db = lerpf(ac_hum.volume_db, idle, minf(delta * 1.5, 1.0))
		ac_out.volume_db = lerpf(ac_out.volume_db, -80.0, minf(delta * 1.5, 1.0))
	var want := 1.0 if power else 0.0
	power_k = move_toward(power_k, want, delta * (6.0 if want < power_k else 1.5))
	for i in house_lights.size():
		lights.anchors[house_lights[i]]["energy"] = house_energy[i] * power_k
	thermo_mat.emission_energy_multiplier = 1.4 * power_k


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -26.0)
	beds["birds"] = sound.bed("crickets", {"seconds": 6.0}, -34.0)
	beds["room"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 260.0, "rumble": 0.1}, -60.0)
	var att: Vector3 = house.anchors["ac"]
	ac_hum = sound.emitter("transformer", att + Vector3(0, 0.8, 0), {"base": 46.0}, -40.0, 14.0)
	ac_out = sound.emitter("transformer", Vector3(7.75, 0.6, 7.2), {"base": 61.0}, -80.0, 16.0)
	sound.emitter("transformer", house.anchors["breaker"], {"base": 120.0}, -36.0, 3.0)


func _inside(p: Vector3) -> bool:
	return p.x > HOUSE.X0 and p.x < HOUSE.X1 and p.z > HOUSE.Z0 and p.z < HOUSE.Z1 and p.y > HOUSE.F0 - 0.3


func _mix(delta: float, p: Vector3) -> void:
	var inside := _inside(p)
	var attic := inside and p.y > HOUSE.A - 0.3
	var k := minf(delta * 2.0, 1.0)
	_vol("wind", -36.0 if inside else -24.0, k)
	_vol("birds", -48.0 if inside else -32.0, k)
	_vol("room", (-30.0 if attic else -36.0) if inside else -70.0, k)
	if attic and power:
		attic_t -= delta
		if attic_t <= 0.0:
			attic_t = randf_range(5.0, 12.0)
			sound.play_at("pipe_clank", {"f": 90.0 + randf() * 60.0}, house.anchors["ac"] + Vector3(0, 1.0, 0), -22.0)
			_say("rattle", "[the air handler ticks and rattles on its own now and then, without ever starting]", 5.0)
	if inside:
		scratch_t -= delta
		if scratch_t <= 0.0:
			scratch_t = randf_range(70.0, 150.0)
			var at := Vector3(clampf(p.x + randf_range(-3, 3), HOUSE.X0 + 0.2, HOUSE.X1 - 0.2), p.y + 0.6, HOUSE.Z1 - 0.1 if randf() < 0.5 else HOUSE.Z0 + 0.1)
			sound.play_at("scratch", {}, at, -20.0, "[a faint scratching inside the wall - or the new house settling]")


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key) or SessionState.is_qa():
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func _mark(key: String) -> void:
	SaveService.record_discovery(stable_id, "l90:" + key, "Level 90: checked the sales pitch against the house (%s)." % key, "SOURCE")


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	_say("arrive", "[a clean hallway that smells of fresh paint. On the table by the stairs, a flyer: 'Heyyy! Welcome home!']", 6.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	_ac_process(delta)
	_mix(delta, p)
	if p.z > 20.0:
		_say("oak", "[the old oak is huge - older than the house, older than anything here. The grass is worn into a path that goes round behind it.]", 6.0)


# ---------------------------------------------------------------- QA

func _shots() -> void:
	var F0 := HOUSE.F0
	add_shot("front_for_sale", Vector3(-9.5, 1.65, -11.5), Vector3(0.0, 3.6, 3.0), {"flashlight": false})
	add_shot("living_kitchen", Vector3(-1.6, F0 + 1.6, 0.9), Vector3(-5.6, F0 + 0.9, 8.6), {"flashlight": false})
	add_shot("attic_ac", Vector3(4.6, HOUSE.A + 1.65, 4.6), Vector3(-2.6, HOUSE.A + 0.8, 5.6), {"flashlight": false})
	add_shot("backyard_oak", Vector3(-3.2, F0 + 1.7, 13.4), Vector3(5.0, 5.5, 28.0), {"flashlight": false})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	var mz: float = (HOUSE.SZ0 + HOUSE.stair_top_z()) * 0.5
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(1.0, HOUSE.F1 + 0.5, mz), Vector3(1.0, -1.0, mz), 1))
	out.append({"what": "main stair collision halfway between the floors", "ok": not hit.is_empty() and absf(float(hit["position"].y) - (HOUSE.F0 + HOUSE.F1) * 0.5) < 0.35, "detail": hit.get("position", null)})
	var hit2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-4.0, HOUSE.A + 1.0, 3.5), Vector3(-4.0, HOUSE.F1, 3.5), 1))
	out.append({"what": "attic floor walkable at attic height", "ok": not hit2.is_empty() and absf(float(hit2["position"].y) - HOUSE.A) < 0.15, "detail": hit2.get("position", null)})
	var ax: float = (HOUSE.AX0 + HOUSE.attic_top_x()) * 0.5
	var hit3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(ax, HOUSE.A + 0.5, 6.08), Vector3(ax, HOUSE.F1 - 0.5, 6.08), 1))
	out.append({"what": "attic stair ramp between first floor and attic", "ok": not hit3.is_empty() and absf(float(hit3["position"].y) - (HOUSE.F1 + HOUSE.A) * 0.5) < 0.35, "detail": hit3.get("position", null)})
	out.append({"what": "one oak exit", "ok": exits.size() == 1 and oak_exit != null})
	_thermostat()
	ac_t = 6.5
	_ac_process(0.016)
	var tripped := not power
	_breaker()
	out.append({"what": "AC trips the breaker; the panel restores power", "ok": tripped and power, "detail": [tripped, power]})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
