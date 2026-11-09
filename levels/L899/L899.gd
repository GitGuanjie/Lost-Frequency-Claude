extends LevelBase
## Level 899 "Yonder's End" (Backrooms Wikidot rev 14, accessed 2026-11-04;
## InspectingCritters, CC BY-SA 3.0). Dossier: docs/canon/levels/L899.md.
##
## PLAN (read -> design):
## - BROCHURE (unreliable advert): a floating island over a breathtaking view; colours
##   dance across an endless void and light the sky day and night, so no electricity;
##   water from a spring-fed lake; a sustainable mushroom crop and inventive chefs;
##   staff with fangs "for show", extra eyes and arms. -> one authored island (~230 x
##   170 m) over an aurora void: meadow, a spring and its lake (west), mushroom beds
##   and log stacks (east), the dining hall with its kitchen on a terrace behind a
##   retaining wall (north, second walkable height), a lookout hill (north-west),
##   residents' cottages, a timber rail round the rim; the rock hangs into the void
##   below. No lamp anywhere: the aurora is the light (sky shader, cold key light).
## - TESTIMONY (Jameson's diary): the representative Karl, a human-shaped,
##   gargoyle-like caretaker with wings; mostly a lot of walking to get there; people,
##   "not too many but enough"; grass and sky; anything longer than a few days is a
##   lifetime reservation; stay forever, lose your youth, never worry again; Mike ages;
##   the auroras; Karl shows the way back and it feels shorter. "It is 9AM."
## - Stateful signature: the stay. The light never changes; days pass when you sleep
##   in the guest cottage, lie in the grass and watch the sky, or simply linger
##   (about seven minutes each). Each new day begins "It is 9AM." On day 3 Karl warns
##   you; on day 4 the reservation becomes a lifetime one: colour drains from the
##   world and L899>EXT#2 (permanent residence, one-way) fires. Before that, walking
##   back into the passage with Karl is L899>EXT#1 (escorted return, destination
##   Base Omega, not built).
## - ADAPTATION: the island's layout and size, the passage in the rock as "the way
##   back", the cottages, hall and beds as built forms, the day timing. Entity policy:
##   Karl, residents and staff are idle presences; no hostile entity (the brochure's
##   "creatures of the night" live elsewhere); the diary's banging pipes stay at Base
##   Omega and are not here.

const I := preload("res://levels/L899/L899_island.gd")
const B := preload("res://levels/L899/L899_build.gd")
const People := preload("res://levels/L899/L899_people.gd")
const DAY_SECONDS := 420.0
const SKY := """
shader_type sky;
uniform vec3 top_col : source_color = vec3(0.01, 0.012, 0.04);
uniform vec3 hor_col : source_color = vec3(0.045, 0.055, 0.11);
uniform vec3 void_col : source_color = vec3(0.004, 0.003, 0.012);
uniform float fade = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float a = 0.5; float s = 0.0; for (int i = 0; i < 4; i++) { s += a * noise(p); p *= 2.03; a *= 0.5; } return s; }
vec3 aurora(vec3 d, float t) {
	vec3 acc = vec3(0.0);
	vec2 n2 = normalize(d.xz + vec2(1e-4));
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float wav = fbm(n2 * (1.4 + fi * 0.5) + vec2(fi * 3.1 + t * 0.02, -t * 0.015));
		float base = 0.2 + 0.14 * fi + 0.22 * (wav - 0.5) + 0.05 * sin(n2.x * 3.0 + n2.y * 2.0 + t * 0.04 + fi);
		float e = d.y - base;
		float curtain = smoothstep(-0.02, 0.0, e) * exp(-max(e, 0.0) * (7.0 - 1.5 * fi));
		float streak = 0.25 + 0.75 * fbm(n2 * 34.0 + vec2(fi * 7.0, t * 0.1 + fi));
		float pres = smoothstep(0.35, 0.65, fbm(n2 * 2.2 + vec2(t * 0.01 + fi * 5.0, fi)));
		vec3 c = i == 0 ? vec3(0.12, 1.0, 0.5) : (i == 1 ? vec3(0.65, 0.2, 0.95) : vec3(0.18, 0.55, 1.0));
		acc += c * (curtain * streak * pres + 0.05 * exp(-abs(e) * 5.0)) * (1.0 - 0.25 * fi);
	}
	return acc;
}
void sky() {
	vec3 d = EYEDIR;
	float t = TIME;
	vec3 col = d.y >= 0.0 ? mix(hor_col, top_col, pow(d.y, 0.45)) : mix(hor_col * 0.8, void_col, pow(-d.y, 0.35));
	col += aurora(d, t) * 0.55 * fade;
	col += aurora(vec3(d.z, -d.y + 0.1, d.x), t * 1.1 + 5.0) * 0.1 * smoothstep(0.0, -0.2, d.y) * fade;
	vec2 sp = d.xz / (abs(d.y) + 0.3) * 140.0;
	float h = hash(floor(sp));
	col += vec3(step(0.9965, h) * (0.55 + 0.45 * sin(t * 1.7 + h * 50.0))) * 0.7 * smoothstep(0.05, 0.3, abs(d.y));
	COLOR = col;
}
"""

var isl
var bld
var sky_mat: ShaderMaterial
var karl: Node3D
var karl_lines := 0
var people: Array = []
var day := 1
var day_t := 0.0
var reserved := false
var reserved_t := 0.0
var warned := false
var said := {}
var ex_back: ExitTrigger
var ex_stay: ExitTrigger
var START := Vector3(6.0, I.H0 + 0.05, 49.0)


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 3000.0
	rules["kill_y"] = -70.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.05
	outdoor_env(Color(0.02, 0.02, 0.05), Color(0.08, 0.06, 0.14), Color(0.01, 0.01, 0.02), Vector2(58.0, 150.0), Color(0.55, 0.95, 0.8), 0.5, Color(0.05, 0.045, 0.09), 0.0035)
	var sh := Shader.new()
	sh.code = SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	environment.sky.sky_material = sky_mat
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.5, 0.72)
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_sky_affect = 0.0
	environment.tonemap_exposure = 1.15
	environment.glow_intensity = 0.5
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	sun.directional_shadow_max_distance = 90.0
	B.materials()
	People.materials()
	isl = I.new()
	var ground := Node3D.new()
	ground.name = "Island"
	add_child(ground)
	var tm: ShaderMaterial = isl.make_material()
	isl.build_top(ground, tm)
	isl.build_underside(ground, tm)
	isl.build_collision(ground)
	isl.build_grass(ground, rng, 16000)
	bld = B.new(self, isl, rng)
	bld.build_all()
	_people()
	_exits()
	_interactions()
	_sounds()
	add_arrival("start", START, 0.0)
	add_note("l899_brochure", "The brochure (in your pocket)",
		"Why live in fear? Yonder's End is open to all: a floating island over a breathtaking view, colours dancing across an endless void day and night, a spring-fed lake, mushrooms for life. \"We don't bite!\" Send a letter; a representative will collect you.",
		START + Vector3(1.2, 0.8, 1.6), Vector3(0.5, 0.5, 0.5))
	add_landmark("The passage in the rock (the way back)", bld.spots["mouth"])
	add_landmark("Dining hall on the terrace", bld.spots["hall"])
	add_landmark("The spring and the lake", bld.spots["spring"])
	add_landmark("Mushroom beds", bld.spots["beds"])
	add_landmark("Lookout over the void", bld.spots["lookout"])
	_shots()


func _people() -> void:
	karl = People.person("karl", "stand", 0)
	add_child(karl)
	karl.position = START + Vector3(1.6, -0.05, 1.2)
	karl.rotation.y = PI
	_body(karl, 0.5, 1.8)
	var spots: Dictionary = bld.spots
	var lake: Vector3 = spots["lake"]
	var list := [
		["resident", "lie", Vector3(lake.x + 6.0, 0, lake.z - 12.5), 20.0],
		["resident", "lie", Vector3(lake.x - 4.0, 0, lake.z + 13.5), 200.0],
		["resident", "sit", (spots["bench"] as Vector3) + Vector3(0.0, 0.0, 0.0), 45.0 + 180.0],
		["resident", "sit", spots["table_a"] - Vector3(0, 0.45, 0), 90.0],
		["resident", "sit", spots["table_b"] - Vector3(0, 0.45, 3.0), -90.0],
		["resident", "stand", Vector3(-30.0, 0, 32.0), 150.0],
		["resident", "lie", Vector3(30.0, 0, 18.0), -40.0],
		["resident", "sit", Vector3(lake.x + 14.0, 0, lake.z + 6.0), -60.0],
		["staff", "stand", spots["chef"], 180.0],
		["staff", "stand", Vector3(50.0, 0, -4.0), 90.0],
		["staff", "stand", Vector3(58.0, 0, 9.0), -90.0],
	]
	for i in list.size():
		var e: Array = list[i]
		var p: Vector3 = e[2]
		if not i in [2, 3, 4, 8]:
			p.y = isl.h(p.x, p.z)
		if i == 7:
			p.y -= 0.42
		var n := People.person(e[0], e[1], i % 5)
		add_child(n)
		n.position = p
		n.rotation.y = deg_to_rad(float(e[3]))
		if e[1] == "stand":
			_body(n, 0.45, 1.8)
		people.append({"node": n, "kind": e[0], "pose": e[1]})
		var line := "[an old resident lies in the grass, watching the sky. Their face is slack and happy]"
		if e[0] == "staff":
			line = "[one of the staff. Four arms; more eyes than you. It smiles; the fangs are just for show, the brochure said]"
		elif e[1] == "sit":
			line = "[an elderly resident. They nod at you, and look back up at the colours]"
		elif e[1] == "stand":
			line = "[a resident, older than they probably are. \"You'll stay, won't you?\" they ask, without needing an answer]"
		var msg := line
		make_interactable(p + Vector3(0, 0.8, 0), Vector3(1.4, 1.8, 1.4), "Speak to them", func() -> void: Overlay.subtitle(msg, 4.0), self)


func _body(n: Node3D, w: float, h: float) -> void:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(w, h, w)
	cs.shape = s
	cs.position.y = h * 0.5
	b.add_child(cs)
	n.add_child(b)


func _exits() -> void:
	var te: Vector3 = bld.spots["tunnel_end"]
	ex_back = add_exit("L899>EXT#1", "walk_in", te, Vector3(3.0, 3.0, 3.0), "")
	if ex_back:
		ex_back.condition = func() -> bool: return not reserved
		ex_back.fired.connect(func(_e: String) -> void:
			Overlay.subtitle("[Karl walks you back into the dark. It feels shorter than the way there. Too short]", 4.0))
	ex_stay = add_exit("L899>EXT#2", "condition", START + Vector3(0, 10.0, 0), Vector3(420.0, 90.0, 420.0), "")
	if ex_stay:
		ex_stay.condition = func() -> bool: return reserved and reserved_t > 9.0


func _interactions() -> void:
	make_interactable(karl.position + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 1.2), "Talk to Karl", _talk_karl, karl)
	var s: Dictionary = bld.spots
	add_interactable(s["bed"], Vector3(2.0, 1.0, 1.0), "Sleep in the guest bed", func() -> void: advance_day("[you sleep, dreamlessly]"))
	for p in [Vector3(s["lake"].x + 8.0, 0, s["lake"].z - 14.0), s["lookout"] + Vector3(3.0, 0, 3.0), Vector3(26.0, 0, 16.0)]:
		var q: Vector3 = p
		q.y = isl.h(q.x, q.z) + 0.4
		add_interactable(q, Vector3(2.0, 1.0, 2.0), "Lie in the grass and watch the sky", func() -> void:
			advance_day("[you lie in the grass and watch the colours move. You lose track of how long]"))
	add_interactable(s["table_a"] + Vector3(0.75, 0.4, 2.0), Vector3(1.2, 0.6, 1.4), "Eat a bowl of the day's mushrooms",
		func() -> void: Overlay.subtitle("[mushrooms again, cooked some new way. It's starting to taste like coffee]", 4.0))
	add_note("l899_diary", "A torn diary page (on the guest table)",
		"\"It is 9AM. More mushrooms.\" ... \"The faculty made it clear: anything longer than a few days is a lifetime reservation.\" ... \"Mike's staying. He seemed happy. Maybe he wasn't.\" (Jameson, Base Omega; testimony)",
		s["guest_in"] + Vector3(0, 0.8, 0), Vector3(0.6, 0.5, 0.6))


func _talk_karl() -> void:
	var lines := [
		"[Karl] \"My name is Karl. I'm a caretaker.\"",
		"[Karl] \"Stay a few days, if you like. Any longer and the reservation is for life.\"",
		"[Karl] \"We are what we are. And I am a caretaker.\"",
		"[Karl] \"When you want to go back, walk into the passage. I'll show you the way.\"",
		"[you ask whether the wings work. She looks at you] \"If that's the case, is there a difference?\"",
	]
	if day >= 3 and not reserved:
		Overlay.subtitle("[Karl] \"Tomorrow, it becomes a lifetime reservation. Go back today, or don't. No shame either way.\"", 5.0)
		return
	Overlay.subtitle(lines[karl_lines % lines.size()], 4.5)
	karl_lines += 1


func advance_day(caption: String) -> void:
	if reserved:
		return
	day += 1
	day_t = 0.0
	Overlay.glitch(0.3)
	Overlay.subtitle("%s It is 9AM." % caption, 4.0)
	Overlay.toast("Day %d at Yonder's End" % day, 3.0)
	if day == 3 and not warned:
		warned = true
		Overlay.subtitle("[Karl, from somewhere near] \"Day three. One more and you stay.\" It is 9AM.", 5.0)
	if day >= 4:
		reserved = true
		reserved_t = 0.0
		Overlay.subtitle("[you stay. You will always stay. The years settle on you and you do not mind. It is 9AM]", 6.0)


func _sounds() -> void:
	sound.bed("wind", {"seconds": 8.0}, -27.0)
	sound.bed("pad", {"root": 98.0, "chord": [0, 7, 12, 16, 19], "bright": 0.12, "seconds": 12.0}, -30.0)
	sound.emitter("water_bed", bld.spots["spring"], {"bright": 0.6, "seconds": 6.0}, -12.0, 26.0)
	sound.emitter("water_bed", bld.spots["lake"], {"bright": 0.2, "seconds": 7.0}, -20.0, 30.0)
	sound.emitter("crackle", bld.spots["fire"], {"seconds": 3.0}, -14.0, 16.0)
	sound.emitter("whisper", bld.spots["hall"] + Vector3(0, 1.0, 0), {"seconds": 3.0}, -24.0, 18.0)
	var f := OmniLight3D.new()
	f.light_color = Color(1.0, 0.55, 0.25)
	f.omni_range = 7.0
	f.light_energy = 1.2
	f.shadow_enabled = false
	add_child(f)
	f.position = bld.spots["fire"] + Vector3(0, 0.3, 0.6)
	set_meta("fire_light", f)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[after a lot of walking, Karl leads you out of the rock. Grass, a lake, and the sky] It is 9AM.", 5.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	var fl: Variant = get_meta("fire_light", null)
	if fl is OmniLight3D:
		(fl as OmniLight3D).light_energy = 1.1 + 0.25 * sin(Time.get_ticks_msec() * 0.011) + 0.1 * sin(Time.get_ticks_msec() * 0.037)
	if not SessionState.is_qa() and not reserved:
		day_t += delta
		if day_t > DAY_SECONDS:
			advance_day("[time passes here without your noticing.]")
	if reserved:
		reserved_t += delta
		var k := clampf(reserved_t / 9.0, 0.0, 1.0)
		environment.adjustment_saturation = lerpf(1.05, 0.2, k)
		environment.adjustment_brightness = lerpf(1.0, 0.85, k)
	# Karl: watches you; walks with you when you head into the passage
	if is_instance_valid(karl):
		var mouth: Vector3 = bld.spots["mouth"]
		var to := pp - karl.position
		var want_yaw := atan2(to.x, to.z)
		if pp.distance_to(mouth) < 7.0 or pp.z > mouth.z:
			var goal := Vector3(mouth.x + 1.0, I.H0, clampf(pp.z - 0.6, mouth.z - 3.0, 66.0))
			karl.position = karl.position.move_toward(goal, delta * 2.6)
			if not said.has("karl_walk") and not SessionState.is_qa() and pp.z > mouth.z + 1.0:
				said["karl_walk"] = true
				Overlay.subtitle("[Karl falls in beside you. \"This way.\"]", 3.0)
		if to.length() < 12.0:
			karl.rotation.y = lerp_angle(karl.rotation.y, want_yaw, minf(1.0, delta * 2.0))
	if not said.has("void") and not SessionState.is_qa() and isl.d_of(pp.x, pp.z) > 0.82:
		said["void"] = true
		Overlay.subtitle("[beyond the rail, nothing: colours moving over an endless void, above and below]", 4.0)


func _shots() -> void:
	var s: Dictionary = bld.spots
	add_shot("arrival_meadow", START + Vector3(-0.8, 1.62, 1.0), Vector3(20.0, 9.0, -30.0), {"flashlight": false})
	var lk: Vector3 = s["lake"]
	add_shot("lake_and_spring", Vector3(lk.x + 16.0, isl.h(lk.x + 16.0, lk.z + 10.0) + 1.7, lk.z + 10.0), s["spring"] + Vector3(0, 0.5, 0), {"flashlight": false})
	add_shot("dining_hall", Vector3(22.8, I.TERRACE_Y + 1.75, -23.5), Vector3(21.6, I.TERRACE_Y + 0.9, -41.0), {"flashlight": false})
	add_shot("island_from_the_void", Vector3(175.0, 26.0, 115.0), Vector3(-10.0, -12.0, -5.0), {"flashlight": false})
	add_shot("mushroom_beds", Vector3(41.0, isl.h(41.0, -15.0) + 1.7, -15.0), Vector3(58.0, isl.h(58.0, 8.0), 8.0), {"flashlight": false})
	var lo: Vector3 = s["lookout"]
	add_shot("lookout_rim", lo + Vector3(4.0, 1.7, 6.0), lo + Vector3(-40.0, -14.0, -40.0), {"flashlight": false})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "aurora sky shader drives the light (no electric fixtures)", "ok": environment.sky.sky_material == sky_mat})
	out.append({"what": "spring-fed lake has a water volume", "ok": get_node_or_null("Lake") is WaterVolume})
	out.append({"what": "Karl and residents are present", "ok": is_instance_valid(karl) and people.size() >= 8, "detail": people.size()})
	out.append({"what": "two exits: escorted return and lifetime stay", "ok": ex_back != null and ex_stay != null})
	var back_open: bool = ex_back.condition.call()
	var stay_closed: bool = not ex_stay.condition.call()
	# simulate the stay without letting a frame pass, then restore it
	var d0 := day
	day = 3
	warned = true
	reserved = true
	reserved_t = 10.0
	var back_closed: bool = not ex_back.condition.call()
	var stay_open: bool = ex_stay.condition.call()
	day = d0
	reserved = false
	reserved_t = 0.0
	warned = false
	out.append({"what": "before day 4 the way back is open and the stay is not", "ok": back_open and stay_closed})
	out.append({"what": "on day 4 the reservation is for life (back closed, stay open)", "ok": back_closed and stay_open})
	return out
