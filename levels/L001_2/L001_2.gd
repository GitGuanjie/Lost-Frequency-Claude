extends LevelBase
## Level 1.2 — "Concrete Garden" (Backrooms Wikidot rev 33, accessed 2026-11-04;
## cite: Praetor3005, CC BY-SA 3.0). Dossier: docs/canon/levels/L001_2.md.
## Content note: body horror (a person slowly turned into plants), memory loss.
##
## PLAN (v2.0 rebuild)
## SOURCE (article): a sub-sector of Scene 01.3 with the same layout as the rest of
##   Level 1 apart from heavy vegetation: the floor carpeted with tall grass and
##   flowers of many colours, pillars and walls infested with vines that sometimes
##   stretch across the ceiling; origin unknown; no entities (they avoid it);
##   settlers who tried to live here were never heard from again; staying even an
##   hour starts turning you into a plant. TESTIMONY (story/log): concrete warehouse
##   floor giving way to crunchy grass; fresh air; Frontrooms and Backrooms plants of
##   contradicting climates with no sun or soil; ruins of settlements deeper in, some
##   far too ancient for wanderers; fragile stone fences; bluebonnet pollen carrying
##   other people's memories (togas, birds; a Leaders operative rooted to the ground);
##   the level taking your own memories (a partner forgotten for an hour; the
##   sunflowers as an anchor); a rose through the leg; a labyrinthine complex.
## SPACE: Level 1's grammar (8 m bays, 1.4 m square pillars with faded two-tone
##   paint, 4.6 m ceiling, pipe runs, hanging tubes, crates, leaks). A 24 m concrete
##   hall from the rest of Level 1 (arrival, exit) opens onto a 64 x 80 m garden:
##   meadow, the sunflower batch under a live tube, an ancient stone terrace (+1.2 m)
##   with broken columns, an arch and low stone fences, the wanderers' settlement with
##   a lookout (+2.4 m), a sunken bay (-1.2 m) of ferns and cacti, and the deep garden
##   where the vines hang in curtains and most tubes are dead. Partition walls with
##   seeded openings make it labyrinthine (procedural: seed changes wall openings and
##   rubble). No visible edge: walls, the hall back into Level 1, fog.
## SIGNATURE MECHANIC (stateful): Bloom. After a compressed "hour" in the garden
##   (4 min) the level starts to take you: Bloom rises; pollen from bluebonnets adds
##   to it and plays someone else's memory; the fragile fence gives way and drops you
##   into a patch; the botanist's notebook loses words as Bloom grows; at 60 % a rose
##   opens through your leg, at 85 % your muscles stop answering (slow), at 100 % you
##   become part of the garden (death). Walking back out through the concrete hall is
##   the only exit (L001_2>L001#1, walk_in).
## ABSENT: entities, birds, edible plants, safe camps, any other exit.

const Geo := preload("res://levels/L001_2/L001_2_geo.gd")
const Flora := preload("res://levels/L001_2/L001_2_flora.gd")
const Dress := preload("res://levels/L001_2/L001_2_dress.gd")
const Story := preload("res://levels/L001_2/L001_2_story.gd")
const SPAWN := Vector3(0.0, 0.05, -2.0)
const EXIT_ID := "L001_2>L001#1"
const ONSET := 240.0
const RATE := 1.0 / 420.0

var geo
var flora
var dress
var bloom := 0.0
var garden_t := 0.0
var memories := 0
var told := {}
var cooldown := [0.0, 0.0, 0.0]
var motes: CPUParticles3D
var _base_walk := 3.1
var _base_sprint := 5.3


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 110.0
	rules["reverb_room"] = 0.7
	rules["reverb_wet"] = 0.22
	var fog := Color(0.07, 0.085, 0.07)
	indoor_env(Color(0.6, 0.68, 0.6), 0.09, fog, 0.024)
	environment.background_color = fog
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.35
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	environment.adjustment_contrast = 1.08
	Geo.materials()
	var ks := kit("Warehouse")
	var kf := kit("Tubes")
	kf.shadows = false
	var kd := kit("Growth")
	kd.shadows = false
	geo = Geo.new(self, ks, kf)
	geo.shell(rng)
	geo.terrace(rng)
	geo.fences(rng)
	geo.settlement(rng)
	geo.pit()
	flora = Flora.new()
	dress = Dress.new(self, geo, flora, kd)
	var plants := Node3D.new()
	plants.name = "Plants"
	add_child(plants)
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "l12_growth"])
	dress.carpet(plants, r)
	dress.specials(plants, r)
	dress.vines(r)
	dress.commit_leaves(plants)
	dress.objects(props, r)
	ks.commit()
	kf.commit()
	kd.commit()
	Story.lights(self)
	Story.sounds(self)
	Story.notes(self)
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L001", SPAWN, 0.0)
	add_exit(EXIT_ID, "walk_in", Vector3(0, 1.4, 14.0), Vector3(23.4, 2.8, 2.0), "Back into the concrete halls (Level 1)")
	add_landmark("Concrete hall from Level 1", Vector3(0, 0, 6))
	add_landmark("Sunflowers", Dress.SUNFLOWERS)
	add_landmark("Ancient stone terrace", Vector3(-22, 1.2, -60))
	add_landmark("Settlers' lookout", Vector3(24, 2.4, -48))
	add_landmark("Sunken bay", Vector3(0, -1.2, -62))
	_shots()


func on_player_ready() -> void:
	_base_walk = player.walk_speed
	_base_sprint = player.sprint_speed
	motes = Dress.motes(self)
	if not SessionState.is_qa():
		Overlay.subtitle("[ahead, between the pillars: grass. Flowers. A smell of wilderness.]", 4.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	if motes:
		motes.global_position = pp + Vector3(0, 0.6, 0)
	for i in cooldown.size():
		cooldown[i] = maxf(0.0, cooldown[i] - delta)
	if pp.z < Geo.ZG:
		if not told.has("in"):
			told["in"] = true
			if not SessionState.is_qa():
				Overlay.subtitle("[the hard concrete gives way to the soft crunch of grass. The air is fresh.]", 4.0)
		if not SessionState.is_qa():
			step_bloom(delta)
	# pollen: walking through a bluebonnet patch releases it
	var spd := Vector2(player.velocity.x, player.velocity.z).length()
	for i in Dress.PATCHES.size():
		var pc: Vector3 = Dress.PATCHES[i]
		if cooldown[i] <= 0.0 and Vector2(pp.x - pc.x, pp.z - pc.z).length() < 2.6 and spd > 1.0:
			memory(i)
	if bloom > 0.3 and not told.has("sun") and pp.distance_to(Dress.SUNFLOWERS) < 7.0:
		told["sun"] = true
		Overlay.subtitle("[sunflowers. They remind you of someone. A dinner? You can't hold on to it.]", 4.5)


## Bloom: the garden taking you, a little at a time.
func step_bloom(delta: float) -> void:
	garden_t += delta
	if garden_t > ONSET:
		bloom = minf(1.0, bloom + delta * RATE)
	Story.bloom_stages(self)


func add_bloom(v: float) -> void:
	bloom = minf(1.0, bloom + v)
	Story.bloom_stages(self)


## Someone else's memory, carried by pollen (0: togas and birds, 1: the rooted
## operative, 2: your own, slipping).
func memory(i: int) -> void:
	cooldown[i] = 25.0
	memories += 1
	Dress.puff(self, Dress.PATCHES[i])
	add_bloom(0.05)
	if SessionState.is_qa():
		return
	sound.play_at("whisper", {"seconds": 2.0}, Dress.PATCHES[i] + Vector3(0, 1.0, 0), -10.0)
	Overlay.glitch(0.3)
	var lines := [
		"[pollen fills your throat. Then a memory that isn't yours: people in togas running. Birds. A child. Fear.]",
		"[a memory surfaces from the flowers: an operative of the Leaders, standing, rooted to the ground.]",
		"[you reach for something important. A name. It isn't there.]"]
	Overlay.subtitle(lines[i], 6.0)
	if i < 2:
		get_tree().create_timer(6.5).timeout.connect(func(): Overlay.subtitle("[it fades as fast as it came. You can barely recall it now.]", 3.5))


func rest_on_fence() -> void:
	if not geo.fence_node.visible:
		return
	geo.collapse_fence()
	if player:
		player.velocity += Vector3(0, -1.5, 1.2)
	sound.play_at("knock", {"hits": 3}, Vector3(-28.2, 0.4, -45.5), -6.0, "[the stones shift and the wall gives way]")
	memory(0)


func _shots() -> void:
	add_shot("threshold", Vector3(-2.2, 1.62, 8.0), Vector3(0.5, 1.0, -40.0))
	add_shot("sunflowers", Vector3(-15.8, 1.7, -19.0), Vector3(-20.5, 1.3, -25.0))
	add_shot("terrace", Vector3(-16.4, 2.85, -53.2), Vector3(-26.0, 2.0, -67.0))
	add_shot("settlement", Vector3(25.5, 1.62, -38.4), Vector3(23.0, 1.8, -50.0))
	add_shot("deep_garden", Vector3(-6.0, 1.62, -74.5), Vector3(8.0, 1.6, -88.0))
	add_shot("sunken_bay", Vector3(0.5, 1.62, -49.0), Vector3(0.0, -0.8, -66.0))


func qa_self_test() -> Array:
	return await Story.self_test(self)
