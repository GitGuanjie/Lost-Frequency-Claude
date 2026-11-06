extends LevelBase
## Level 200 — "Home" (Backrooms Wikidot rev 35, last edited 2026-05-17,
## accessed 2026-11-04; cite: J Dune, CC BY-SA 3.0). Dossier: docs/canon/levels/L200.md.
##
## The whole page is spoken by the town in the second person, so the level is
## built as two layers that disagree: what the narrator insists (a nice little
## town, your home, stay) and what the space shows (rot, residents coming
## apart, a house that never quite takes shape, no way out). Systems, each
## mapped to the page (NARRATOR facts; see the dossier):
##   Remembering   three memories the town asks for (walks with Mother, your
##                 birthday, a childhood without fear of dying) give the house
##                 its colour, light and wholeness, room group by room group
##   Rot           grows while you look at it AND while you are away from it
##                 (the page says both); remembering pushes it back, never out
##   Joe Vee       has held the same soup bowl for 30 days; it falls apart
##   Ms. Garcia    look too hard and she comes apart down the middle
##   The school    its cold, dark basement ("Below, below, below"); remember the
##                 dare and Sarah Palmer comes home with you
##   Stay          the street ends in townspeople; asking about exits gets
##                 "Why would you care about that?"; once the house is whole,
##                 "Look behind you. Everyone's here."
## NO ENTITY PER SOURCE: residents are static figures, never movers or attackers.
## No exit: the Entrances and Exits section is a deflection (L200>EXT#1 UNKNOWN).

const House := preload("res://levels/L200/L200_house.gd")
const Town := preload("res://levels/L200/L200_town.gd")
const FX := preload("res://levels/L200/L200_fx.gd")
const WARM := Color(1.0, 0.8, 0.58)
const COLD := Color(0.72, 0.78, 0.86)
const SEEN_RATE := 0.06
const AWAY_RATE := 0.0025
const AMB := {"town": 0.36, "house": 0.13, "spare": 0.13, "basement": 0.02, "diner": 0.2}
const GROUP_NAMES := ["the walks with your mother", "your birthday", "being small and unafraid"]

var forms := [0.12, 0.08, 0.1]
var targets := [0.12, 0.08, 0.1]
var remembered := [false, false, false]
var gmats: Array = []
var glights := [[], [], []]       # [anchor index, full energy]
var rot: Array = []               # {mi, mat, grow, zone, c, n, seen_t, last_visit}
var zone := "town"
var _last_zone := ""
var _visit_grow := {}
var garcia: Node3D
var garcia_look := 0.0
var garcia_split := false
var _garcia_t := 0.0
var joe: Node3D
var bowl: Node3D
var bowl_integrity := 1.0
var _shards: Array = []
var sarah: Node3D
var sarah_home := false
var visited := {}
var everyone := false
var _crowd_root: Node3D
var _lines: Array = []
var _line_t := 0.0
var _said := {}
var _cool := {}
var _sky_t := 25.0
var _smell_t := 40.0
var _creak_t := 30.0
var _finale_t := -1.0
var _blackout := 0.0
var _candles: Node3D


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["reverb_room"] = 0.22
	rules["reverb_wet"] = 0.08
	rules["view_distance"] = 170.0
	outdoor_env(Color(0.24, 0.34, 0.5), Color(0.56, 0.6, 0.65), Color(0.25, 0.26, 0.25), Vector2(24.0, 28.0), Color(0.86, 0.9, 0.98), 0.75, Color(0.56, 0.6, 0.65), 0.0)
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.56, 0.6, 0.65)
	environment.fog_density = 1.0
	environment.fog_depth_begin = 16.0
	environment.fog_depth_end = 95.0
	environment.fog_depth_curve = 1.6
	environment.fog_sky_affect = 0.0
	environment.ambient_light_energy = AMB["town"]
	environment.ambient_light_sky_contribution = 0.7
	environment.ambient_light_color = Color(0.5, 0.53, 0.58)
	environment.tonemap_exposure = 0.9
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	environment.adjustment_contrast = 1.08
	sun.light_energy = 0.75
	sun.directional_shadow_max_distance = 60.0
	FX.materials()
	gmats = FX.group_materials()
	lights.setup(8, 1)
	lights.max_distance = 26.0
	var hk := kit("Home")
	House.shell(hk)
	House.porch(hk)
	House.furnish(hk)
	_fixtures(hk)
	hk.commit()
	var tk := kit("Town")
	Town.ground(tk)
	for i in Town.NORTH_LOTS.size():
		Town.nhouse(tk, Town.NORTH_LOTS[i], i)
	Town.storefronts(tk)
	Town.diner(tk)
	Town.school(tk)
	Town.basement(tk)
	Town.fences(tk)
	Town.street_props(tk)
	tk.commit()
	var ck := kit("Crowd")
	ck.shadows = false
	Town.crowd(ck)
	ck.commit()
	_town_lights()
	_rot_patches()
	_residents()
	_interactions()
	_sounds()
	for g in 3:
		FX.set_form(gmats[g], forms[g])
	add_arrival("start", Vector3(-0.4, 0.1, 13.6), 0.0)
	add_shot("home", Vector3(-5.2, 1.62, 17.6), Vector3(0.8, 3.3, 1.5))
	add_shot("hall", Vector3(-0.55, House.G + 1.6, 3.05), Vector3(0.15, House.G + 2.2, -3.0), {"prepare": _pose_hall})
	add_landmark("Home (the house)", Vector3(0, House.G, 2.0))
	add_landmark("Joe Vee's breakfast place", Vector3(-6.5, Town.DINER_Y, 26.0))
	add_landmark("The school basement", Vector3(23.0, -2.4, 31.0))


func _fixtures(k: GeoKit) -> void:
	var G: float = House.G
	var C1: float = House.C1
	var U: float = House.U
	var C2: float = House.C2
	# [pos, group, energy, range]
	var L := [[Vector3(-0.5, C1 - 0.12, 3.5), 0, 1.0, 5.0], [Vector3(-4.6, G + 1.45, 3.85), 0, 0.9, 5.0], [Vector3(0.5, C2 - 1.1, 1.0), 0, 1.0, 6.5],
		[Vector3(4.55, G + 1.15, 1.35), 0, 0.7, 4.5], [Vector3(-3.0, C1 - 0.85, -2.1), 1, 1.2, 5.5], [Vector3(3.0, C1 - 0.2, -2.0), 1, 1.0, 5.0],
		[Vector3(-3.0, C2 - 0.2, 2.4), 2, 0.9, 5.0], [Vector3(-3.0, C2 - 0.2, -2.0), 2, 0.8, 5.0], [Vector3(3.0, C2 - 0.2, -2.0), 2, 0.8, 4.5],
		[Vector3(-0.5, C2 - 0.2, -2.6), 2, 0.7, 4.5]]
	for l in L:
		var idx := lights.add_anchor(l[0], COLD, float(l[2]) * 0.2, float(l[3]))
		glights[l[1]].append([idx, float(l[2])])
	for p in [Vector3(-3.0, C2 - 0.04, 2.4), Vector3(-3.0, C2 - 0.04, -2.0), Vector3(3.0, C2 - 0.04, -2.0), Vector3(-0.5, C1 - 0.04, 3.5)]:
		k.cylinder(p, 0.19, 0.06, "l200_lamp", 14, false)
	lights.add_anchor(Vector3(3.0, C2 - 0.7, 2.4), Color(1.0, 0.75, 0.5), 0.6, 4.5, 0.25)
	k.box_mm(Vector3(4.45, G + 0.98, 1.3), Vector3(4.65, G + 1.25, 1.45), "l200_lamp", GeoKit.ALL, false)
	# birthday candles (lit when remembered)
	_candles = Node3D.new()
	_candles.name = "Candles"
	add_child(_candles)
	for i in 5:
		var a := TAU * i / 5.0
		var c := Vector3(-3.0 + cos(a) * 0.09, G + 0.96, -2.1 + sin(a) * 0.09)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.006
		cm.bottom_radius = 0.006
		cm.height = 0.07
		mi.mesh = cm
		mi.material_override = FX.std(Color(0.85, 0.75, 0.9))
		mi.position = c
		add_child(mi)
		var fl := MeshInstance3D.new()
		var fm := SphereMesh.new()
		fm.radius = 0.008
		fm.height = 0.022
		fl.mesh = fm
		fl.material_override = MatLib.get_mat("l200_bulb")
		fl.position = c + Vector3(0, 0.048, 0)
		_candles.add_child(fl)
	_candles.visible = false


func _town_lights() -> void:
	for x in [-9.5, -5.5, -2.2]:
		lights.add_anchor(Vector3(x, Town.DINER_Y + 2.9, 26.0), Color(0.95, 0.93, 0.85), 0.7, 6.0)
	lights.add_anchor(Vector3(23.0, -0.8, 31.0), Color(1.0, 0.72, 0.45), 0.55, 4.5, 0.55)
	lights.add_anchor(Vector3(0.0, 2.8, 5.4), WARM, 0.5, 4.0)


func _rot_patches() -> void:
	var G: float = House.G
	var C1: float = House.C1
	var U: float = House.U
	var C2: float = House.C2
	var D := Vector3.DOWN
	var defs := [[Vector3(-4.3, C1, 0.6), D, 1.4, "g0"], [Vector3(1.035, 4.7, 0.4), Vector3.LEFT, 1.2, "g0"],
		[Vector3(-4.3, G + 1.7, -4.335), Vector3.BACK, 1.1, "g1"], [Vector3(3.9, C1, -1.0), D, 1.2, "g1"],
		[Vector3(-3.9, U + 1.95, 0.465), Vector3.BACK, 1.0, "g2"], [Vector3(-3.6, C2, -2.0), D, 1.3, "g2"], [Vector3(3.2, C2, -1.4), D, 1.1, "g2"],
		[Vector3(4.82, U + 1.2, 3.5), Vector3.LEFT, 1.8, "spare"], [Vector3(2.0, C2, 1.4), D, 1.6, "spare"],
		[Vector3(-9.0, Town.DINER_Y + 2.3, 31.59), Vector3.FORWARD, 1.2, "town"], [Vector3(13.6, 2.6, 4.012), Vector3.BACK, 1.3, "town"],
		[Vector3(23.8, 4.2, 27.99), Vector3.FORWARD, 1.6, "town"], [Vector3(26.79, -1.3, 31.6), Vector3.LEFT, 1.4, "basement"],
		[Vector3(4.4, 1.7, 4.505), Vector3.BACK, 1.1, "town"]]
	for i in defs.size():
		var d: Array = defs[i]
		var mi := FX.rot_patch(self, d[0], d[1], d[2], float(i) * 1.37)
		var g := 0.36 + float(i % 3) * 0.07
		(mi.material_override as ShaderMaterial).set_shader_parameter("grow", g)
		rot.append({"mi": mi, "mat": mi.material_override, "grow": g, "zone": d[3], "c": d[0], "n": d[1], "size": d[2], "seen_t": 0.0})


func _residents() -> void:
	# Ms. Garcia on her front walk, facing the street (and you)
	var gp := Vector3(16.0, 0.03, 9.6)
	var to := Vector3(-0.4, 0, 13.6) - gp
	garcia = FX.figure(self, gp, atan2(-to.x, -to.z), 1.62, Color(0.36, 0.33, 0.42), Color(0.2, 0.19, 0.22), Color(0.64, 0.55, 0.5), Color(0.72, 0.72, 0.74), "", true)
	garcia.name = "MsGarcia"
	# Joe Vee behind the counter, holding the bowl out
	joe = FX.figure(self, Vector3(-6.6, Town.DINER_Y, 29.0), 0.0, 1.72, Color(0.42, 0.48, 0.56), Color(0.2, 0.2, 0.22), Color(0.6, 0.5, 0.44), Color(0.78, 0.78, 0.78), "bowl")
	joe.name = "JoeVee"
	bowl = Node3D.new()
	bowl.name = "SoupBowl"
	add_child(bowl)
	bowl.position = Vector3(-6.6, Town.DINER_Y + 1.27, 28.6)
	var bm := CylinderMesh.new()
	bm.top_radius = 0.1
	bm.bottom_radius = 0.055
	bm.height = 0.07
	FX._part(bowl, bm, Vector3.ZERO, FX.std(Color(0.86, 0.83, 0.74), 0.35))
	var sm := CylinderMesh.new()
	sm.top_radius = 0.085
	sm.bottom_radius = 0.085
	sm.height = 0.01
	FX._part(bowl, sm, Vector3(0, 0.025, 0), FX.std(Color(0.48, 0.32, 0.18), 0.2))
	var sh := BoxMesh.new()
	sh.size = Vector3(0.05, 0.035, 0.012)
	for i in 6:
		var a := TAU * i / 6.0
		_shards.append(FX._part(bowl, sh, Vector3(cos(a) * 0.098, 0.022, sin(a) * 0.098), FX.std(Color(0.86, 0.83, 0.74), 0.35), Vector3(0, -a + PI * 0.5, 0)))
	# Sarah Palmer, only once you bring her with you: at the landing window
	sarah = FX.figure(self, Vector3(-0.45, House.U, 3.95), PI, 1.36, Color(0.55, 0.22, 0.24), Color(0.2, 0.22, 0.32), Color(0.66, 0.56, 0.5), Color(0.3, 0.2, 0.12))
	sarah.name = "SarahPalmer"
	sarah.visible = false
	# a few of the 4,000, standing where people stand, watching the visitor
	for d in [[Vector3(-16.8, 0.54, 5.2), PI, Color(0.3, 0.33, 0.3)], [Vector3(30.0, 0.0, 23.6), 0.0, Color(0.4, 0.34, 0.28)],
			[Vector3(10.6, 0.1, 21.9), 0.15, Color(0.26, 0.28, 0.34)], [Vector3(-30.5, 0.1, 21.8), -0.2, Color(0.45, 0.4, 0.36)]]:
		FX.figure(self, d[0], d[1], 1.7, d[2], Color(0.15, 0.15, 0.16), Color(0.6, 0.51, 0.45), Color(0.32, 0.3, 0.28)).name = "Resident"
	_crowd_root = Node3D.new()
	_crowd_root.name = "EveryoneBehindYou"
	add_child(_crowd_root)


func _interactions() -> void:
	var G: float = House.G
	var U: float = House.U
	add_interactable(Vector3(-0.95, G + 1.2, 3.75), Vector3(0.35, 1.3, 1.1), "Remember the walks with your mother", func(_p: Player) -> void: _remember(0))
	add_interactable(Vector3(-3.0, G + 0.9, -2.1), Vector3(0.5, 0.3, 0.5), "Remember your birthday", func(_p: Player) -> void: _remember(1))
	add_interactable(Vector3(-4.37, U + 0.5, 3.4), Vector3(1.0, 0.45, 1.7), "Lie on your old bed and remember", func(_p: Player) -> void: _remember(2))
	add_interactable(Vector3(-6.6, Town.DINER_Y + 1.27, 28.45), Vector3(0.6, 0.5, 0.6), "Look at the soup bowl", func(_p: Player) -> void:
		_drop_shard()
		_toast("Joe Vee holds the bowl out to you, the way he has for thirty days. It is coming apart in his hands.", 4.5)
		_say("bowl", "That man poured his whole life into that food. His flesh and blood."))
	add_interactable(Vector3(20.5, -1.4, 33.4), Vector3(0.8, 1.6, 0.8), "Remember the dare", func(_p: Player) -> void: _remember_sarah())
	add_interactable(Vector3(16.0, 1.0, 9.6), Vector3(0.6, 1.8, 0.6), "Say hello to Ms. Garcia", func(_p: Player) -> void:
		_toast("Ms. Garcia doesn't answer. She is very still, and very old." if not garcia_split else "Ms. Garcia stands in two halves, not quite touching.", 3.5))
	add_note("l200_card", "A birthday card", "Inside, in a careful grown-up hand: a wish for the happiest day, and a promise that the house will always be here. The name it is addressed to has been left blank.", Vector3(-4.6, G + 0.95, -1.6))
	add_note("l200_report", "School report card", "A report card for a ten-year-old. Science: excellent, 'especially at space camp'. A note in the margin says the basement is out of bounds. The pupil's name has been rubbed away.", Vector3(-2.7, U + 0.78, 4.05))


func _sounds() -> void:
	sound.bed("wind", {"seconds": 8.0}, -30.0)
	sound.bed("pad", {"root": 98.0, "chord": [0, 3, 7, 10], "bright": 0.05, "seconds": 10.0}, -31.0, "Music")
	sound.bed("room_tone", {"cutoff": 260.0, "rumble": 0.2}, -34.0)
	sound.emitter("fluorescent_hum", Vector3(-6.0, Town.DINER_Y + 3.0, 26.0), {"base": 60.0, "rasp": 0.2}, -22.0, 9.0)
	sound.emitter("room_tone", Vector3(23.0, -1.4, 31.0), {"cutoff": 140.0, "rumble": 0.8}, -14.0, 7.0)


# --------------------------------------------------------------- narrator

## Overlay.toast() spins forever if a fifth toast arrives while four are still
## alive (its trim loop re-queues the same child), so toasts are capped here
## and overflow falls back to the subtitle line. Framework bug reported.
func _toast(text: String, secs := 3.0) -> void:
	if Overlay.toast_box.get_child_count() <= 2:
		Overlay.toast(text, secs)
	else:
		Overlay.subtitle(text, secs)


func _say(key: String, text: String, secs := 4.5, cooldown := -1.0) -> void:
	var now := Time.get_ticks_msec() * 0.001
	if cooldown < 0.0 and _said.has(key):
		return
	if cooldown >= 0.0 and now < float(_cool.get(key, -1000.0)) + cooldown:
		return
	_said[key] = true
	_cool[key] = now
	_lines.append([text, secs])


func _narrate(delta: float) -> void:
	_line_t -= delta
	if _line_t <= 0.0 and not _lines.is_empty():
		var l: Array = _lines.pop_front()
		Overlay.subtitle("“%s”" % l[0], l[1])
		_line_t = float(l[1]) + 0.6


# ----------------------------------------------------------------- systems

func zone_of(p: Vector3) -> String:
	if p.y < -1.0 and p.x > 19.0 and p.x < 27.5 and p.z > 26.0:
		return "basement"
	if absf(p.x) > 5.0 or absf(p.z) > 4.5 or p.y < 0.3:
		return "town"
	var up := p.y > House.U - 0.3
	if absf(p.x) <= 1.1:
		return "g0"
	if p.x < 0.0:
		return ("g2" if up else ("g0" if p.z > 0.0 else "g1"))
	if up:
		return "g2" if p.z < 0.4 else "spare"
	return "g0" if p.z > 0.3 else "g1"


## One rot step. seen: patch index -> true. Grows while noticed, and while
## the player is away from the patch's zone; never shrinks on its own.
func rot_step(delta: float, seen: Dictionary, at_zone: String) -> void:
	for i in rot.size():
		var r: Dictionary = rot[i]
		var g: float = r["grow"]
		if seen.has(i):
			g += SEEN_RATE * delta
			r["seen_t"] = float(r["seen_t"]) + delta
		if r["zone"] != at_zone:
			g += AWAY_RATE * delta
		r["grow"] = minf(g, 1.05)
		(r["mat"] as ShaderMaterial).set_shader_parameter("grow", r["grow"])


func _rot_seen() -> Dictionary:
	var out := {}
	var cam := player.camera
	var eye := cam.global_position
	var fwd := -cam.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	for i in rot.size():
		var c: Vector3 = rot[i]["c"]
		var d := c - eye
		var dist := d.length()
		if dist > 11.0 or fwd.dot(d / dist) < 0.965:
			continue
		var q := PhysicsRayQueryParameters3D.create(eye, c + (rot[i]["n"] as Vector3) * 0.08, 1)
		q.exclude = [player.get_rid()]
		if space.intersect_ray(q).is_empty():
			out[i] = true
	return out


func _group_rot(g: int) -> float:
	var s := 0.0
	var n := 0
	for r in rot:
		if r["zone"] == "g%d" % g:
			s += maxf(float(r["grow"]) - 0.3, 0.0) / 0.7
			n += 1
	return s / maxf(n, 1)


func visible_form(g: int) -> float:
	return clampf(forms[g] * (1.0 - 0.55 * _group_rot(g)), 0.0, 1.0)


func _remember(g: int) -> void:
	if remembered[g]:
		_toast("You remember it already. The town remembers it with you.", 3.0)
		return
	remembered[g] = true
	targets[g] = 1.0
	for r in rot:
		if r["zone"] == "g%d" % g:
			r["grow"] = maxf(0.12, float(r["grow"]) * 0.3)
	_blackout = 1.0
	if g == 1:
		_candles.visible = true
	Overlay.subtitle("[you remember %s]" % GROUP_NAMES[g], 3.5)
	var said := ["Yes. Summer afternoons, her hand in yours. See how it comes back?", "The pure joy of it. Doesn't it look just like it did?",
		"Back when you didn't have to think about living, or dying, or breaking into a million pieces."]
	_say("mem%d" % g, said[g], 5.0)
	if remembered.count(true) == 3:
		_finale_t = 6.0


func _remember_sarah() -> void:
	if sarah_home:
		return
	sarah_home = true
	sarah.visible = true
	_blackout = 0.8
	Overlay.subtitle("[you remember Sarah Palmer, and the dare]", 3.5)
	_say("sarah", "Wonder what Sarah Palmer is doing with herself now? There. You brought her with you.", 5.0)


func garcia_step(delta: float, looking: bool) -> void:
	if garcia_split:
		_garcia_t = minf(_garcia_t + delta / 1.6, 1.0)
		var e := 1.0 - pow(1.0 - _garcia_t, 3.0)
		(garcia.get_node("L") as Node3D).rotation = Vector3(0, 0, 0.11 * e)
		(garcia.get_node("L") as Node3D).position = Vector3(-0.05 * e, 0, 0)
		(garcia.get_node("R") as Node3D).rotation = Vector3(0, 0, -0.11 * e)
		(garcia.get_node("R") as Node3D).position = Vector3(0.05 * e, 0, 0)
		return
	garcia_look = garcia_look + delta if looking else maxf(0.0, garcia_look - delta * 0.25)
	if garcia_look > 2.5:
		_say("garcia_warn", "That's Ms. Garcia. Don't look too hard.", 3.5)
	if garcia_look > 6.0:
		garcia_split = true
		sound.play_at("scratch", {"seconds": 1.4}, garcia.global_position + Vector3(0, 1.2, 0), -8.0, "[a slow, soft tearing]")
		_say("garcia_split", "We did warn you. We're getting so old. It's hard to keep ourselves in one piece.", 5.0)


func _looking_at(p: Vector3, max_d: float, cos_lim: float) -> bool:
	var cam := player.camera
	var d := p - cam.global_position
	var l := d.length()
	if l > max_d or (-cam.global_transform.basis.z).dot(d / l) < cos_lim:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, p, 1)
	q.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _drop_shard() -> void:
	bowl_integrity = maxf(0.0, bowl_integrity - 1.0 / 6.0)
	_update_bowl()


func _update_bowl() -> void:
	var keep := int(ceil(bowl_integrity * 6.0 - 0.001))
	for i in _shards.size():
		var s: MeshInstance3D = _shards[i]
		if i >= keep and s.get_parent() == bowl:
			var gp := s.global_position
			s.reparent(self)
			s.global_position = gp
			var tw := create_tween()
			tw.tween_property(s, "global_position", Vector3(gp.x + randf_range(-0.2, 0.2), Town.DINER_Y + 0.01, gp.z + randf_range(0.0, 0.3)), 0.45).set_ease(Tween.EASE_IN)
			sound.play_at("crackle", {"seconds": 0.3}, gp, -18.0, "[a piece of the bowl breaks away]" if i == keep else "")
	bowl.rotation.z = (1.0 - bowl_integrity) * 0.25


func _everyone() -> void:
	everyone = true
	var eye := player.camera.global_position
	var back := player.camera.global_transform.basis.z
	back.y = 0.0
	back = back.normalized()
	var space := get_world_3d().direct_space_state
	var placed := 0
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "everyone"])
	var cols := [Color(0.24, 0.26, 0.3), Color(0.4, 0.33, 0.27), Color(0.32, 0.34, 0.31), Color(0.45, 0.38, 0.36), Color(0.5, 0.48, 0.44)]
	for t in 60:
		if placed >= 9:
			break
		var a := r.randf_range(-1.0, 1.0)
		var dist := r.randf_range(1.6, 6.0)
		var dir := back.rotated(Vector3.UP, a)
		var p := player.global_position + dir * dist
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.DOWN * 1.5, 1))
		if hit.is_empty() or absf(hit["position"].y - player.global_position.y) > 0.5:
			continue
		var feet: Vector3 = hit["position"]
		var los := PhysicsRayQueryParameters3D.create(eye, feet + Vector3.UP * 1.5, 1)
		los.exclude = [player.get_rid()]
		if not space.intersect_ray(los).is_empty():
			continue
		var crowded := false
		for c in _crowd_root.get_children():
			if (c as Node3D).global_position.distance_to(feet) < 0.6:
				crowded = true
		if crowded:
			continue
		var to := player.global_position - feet
		FX.figure(_crowd_root, feet, atan2(-to.x, -to.z), r.randf_range(1.5, 1.85), cols[r.randi() % cols.size()], Color(0.14, 0.14, 0.15), Color(0.62, 0.53, 0.47), Color(0.3, 0.28, 0.26))
		placed += 1
	Overlay.subtitle("[everyone is here]", 4.0)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	_say("intro", "It's been a while, hasn't it? You've been travelling. Sit down, there's so much to talk about.", 5.5)
	_say("walk", "Let's take a walk.", 3.0)
	_toast("Your clothes are torn. You can't remember the last time you ate. There is a smell of burning rust, and somehow you smell it in your ears.", 6.5)


func _exit_tree() -> void:
	Overlay.set_screen_effect("vignette", 0.25)
	Overlay.set_screen_effect("desaturate", 0.0)
	Overlay.set_screen_effect("blackout", 0.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	_narrate(delta)
	var p := player.global_position
	zone = zone_of(p)
	if zone != _last_zone:
		_enter_zone(zone)
		_last_zone = zone
	var seen := _rot_seen()
	rot_step(delta, seen, zone)
	for i in seen.keys():
		if float(rot[i]["seen_t"]) > 1.5:
			_say("rot1", "There's rot here. Ignore it.", 3.5)
		if float(rot[i]["seen_t"]) > 6.0:
			_say("rot2", "It only grows when you notice it.", 3.5)
	# forms ease toward their targets; materials and lights follow the visible form
	for g in 3:
		forms[g] = move_toward(forms[g], targets[g], delta * 0.25)
		var f := visible_form(g)
		FX.set_form(gmats[g], f)
		for l in glights[g]:
			var a: Dictionary = lights.anchors[l[0]]
			a["energy"] = float(l[1]) * (0.2 + 0.8 * f)
			a["color"] = COLD.lerp(WARM, f)
	garcia_step(delta, _looking_at(garcia.global_position + Vector3(0, 1.35, 0), 24.0, 0.993))
	bowl_integrity = maxf(0.0, bowl_integrity - delta / 300.0)
	_update_bowl()
	# the street ends in people: slow, then a deflection
	var ex := absf(p.x) - 38.0
	var mult := clampf(1.0 - ex / 13.0, 0.12, 1.0)
	player.walk_speed = float(rules["walk_speed"]) * mult
	player.sprint_speed = float(rules["sprint_speed"]) * mult
	if ex > 8.0:
		_say("leave", "Why would you care about that?", 3.5, 40.0)
		_say("leave2", "Stay.", 2.5, 40.0)
	# interiors are darker than the street (sky light only through windows)
	var az := "house" if zone.begins_with("g") or zone == "spare" else zone
	if zone == "town" and p.x > Town.DINER[0] and p.x < Town.DINER[1] and p.z > Town.SW_S + 0.2:
		az = "diner"
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, AMB[az], clampf(delta * 2.5, 0.0, 1.0))
	environment.tonemap_exposure = lerpf(environment.tonemap_exposure, 0.9 if az == "town" else 1.15, clampf(delta * 2.5, 0.0, 1.0))
	# basement: dark, cold; you might believe you were falling apart
	var low := 1.0 if zone == "basement" else 0.0
	Overlay.set_screen_effect("desaturate", lerpf(0.0, 0.45, low))
	_blackout = maxf(0.0, _blackout - delta * 0.7)
	Overlay.set_screen_effect("blackout", 0.85 * clampf(_blackout, 0.0, 1.0))
	Overlay.set_screen_effect("vignette", 0.25 + 0.25 * low + 0.15 * float(everyone))
	if low > 0.0 and randf() < delta * 0.08:
		Overlay.glitch(0.25)
	# finale: the house is whole
	if _finale_t > 0.0:
		_finale_t -= delta
		if _finale_t <= 0.0:
			_say("fin1", "There. Just how you remember it.", 3.5)
			_say("fin2", "So stay with us.", 3.0)
			_say("fin3", "Stay.", 2.5)
			_say("fin4", "Look behind you.", 3.0)
			_finale_t = -2.0
	elif _finale_t < -1.0 and _lines.is_empty() and not everyone:
		_everyone()
	_ambient_events(delta)


func _enter_zone(z: String) -> void:
	if z.begins_with("g") or z == "spare":
		if not visited.has("house"):
			visited["house"] = true
			var line := "One more stop. It's a house. You can tell it used to be beautiful." if visited.has("diner") and visited.has("school") else "Home. You remember it, don't you? It used to be beautiful."
			_say("house", line, 5.0)
			_say("house2", "It hasn't taken shape yet. Please remember how it used to look.", 5.0)
		var grown := false
		for r in rot:
			if r["zone"] == z and float(r["grow"]) - float(_visit_grow.get(r["c"], r["grow"])) > 0.12:
				grown = true
		if grown:
			_say("away", "It grew while you were gone. It only grows when you're not around.", 4.5, 90.0)
		for r in rot:
			if r["zone"] == z:
				_visit_grow[r["c"]] = r["grow"]
	elif z == "basement":
		_say("base", "Below, below, below. Dark and cold, just how you remember.", 4.5)
		_toast("It is very cold down here. For a moment you could believe you were falling apart.", 4.5)
	if _last_zone.begins_with("g") or _last_zone == "spare":
		for r in rot:
			if r["zone"] == _last_zone:
				_visit_grow[r["c"]] = r["grow"]


func _ambient_events(delta: float) -> void:
	var p := player.global_position
	if not visited.has("diner") and p.z > 19.5 and p.x < 0.0 and p.x > -13.0:
		_enter_zone_town("diner")
	if not visited.has("school") and p.z > 19.5 and p.x > 18.0 and p.x < 46.0:
		_enter_zone_town("school")
	_sky_t -= delta
	if _sky_t <= 0.0:
		_sky_t = randf_range(45.0, 95.0)
		sound.play_at("crackle", {"seconds": 0.9}, p + Vector3(randf_range(-6, 6), 22.0, randf_range(-6, 6)), -16.0 if zone == "town" else -24.0, "[high above, faintly: the sound of skin breaking]")
	_smell_t -= delta
	if _smell_t <= 0.0:
		_smell_t = randf_range(130.0, 200.0)
		Overlay.subtitle("[burning rust; you smell it in your ears]", 3.5)
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = randf_range(25.0, 50.0)
		if zone != "town":
			sound.play_at("creak", {"freq": 110.0}, p + Vector3(randf_range(-3, 3), 1.5, randf_range(-3, 3)), -20.0, "[the thin walls creak]")


func _enter_zone_town(which: String) -> void:
	visited[which] = true
	if which == "diner":
		_say("diner", "There's old Joe Vee, still running the breakfast place. Sixty years, the same people, day in and day out.", 5.5)
		_say("diner2", "He's been holding that soup bowl for thirty days.", 4.0)
	else:
		_say("school", "There's the school. Give it time and it could be your school, just the way you remember it.", 5.5)


## Level self-tests (QA): the page's rules, checked on the live level.
func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "no physical exit: the page answers exits with a deflection", "ok": exits.is_empty() and (manifest.get("exits", []) as Array).is_empty()})
	var g0: float = rot[0]["grow"]
	rot_step(1.0, {0: true}, "g0")
	var seen_d: float = float(rot[0]["grow"]) - g0
	var g1: float = rot[2]["grow"]
	rot_step(10.0, {}, "town")
	var away_d: float = float(rot[2]["grow"]) - g1
	var g2: float = rot[2]["grow"]
	rot_step(10.0, {}, "g1")
	out.append({"what": "rot grows while you notice it", "ok": seen_d > 0.04, "detail": seen_d})
	out.append({"what": "rot grows while you are away", "ok": away_d > 0.01, "detail": away_d})
	out.append({"what": "rot is still when you are present and not looking", "ok": is_equal_approx(float(rot[2]["grow"]), g2)})
	_remember(1)
	out.append({"what": "remembering gives a room group shape and pushes its rot back", "ok": targets[1] == 1.0 and float(rot[2]["grow"]) <= maxf(0.12, g2 * 0.3) + 0.001})
	var gpos := garcia.global_position
	for i in 70:
		garcia_step(0.1, true)
	out.append({"what": "Ms. Garcia comes apart under a long look and never moves", "ok": garcia_split and garcia.global_position.distance_to(gpos) < 0.001})
	var b0 := bowl_integrity
	_drop_shard()
	out.append({"what": "Joe Vee's soup bowl falls apart", "ok": bowl_integrity < b0})
	var space := get_world_3d().direct_space_state
	var ys: Array = []
	var mid := (House.G + House.U) * 0.5
	for pr in [[House.STAIR_Z0 + 0.3, House.G], [(House.STAIR_Z0 + House.STAIR_TOP) * 0.5, mid], [House.STAIR_TOP - 0.4, House.U]]:
		var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.53, pr[1] + 1.2, pr[0]), Vector3(0.53, pr[1] - 1.0, pr[0]), 1))
		ys.append(h["position"].y if not h.is_empty() else -99.0)
	out.append({"what": "a real stair joins the two storeys", "ok": absf(ys[0] - House.G) < 0.1 and absf(ys[1] - mid) < 0.35 and absf(ys[2] - House.U) < 0.1, "detail": ys})
	var edges := 0
	var probes := [[Vector3(-3.0, 1.9, 4.2), Vector3(0, 0, 1)], [Vector3(-3.0, 1.9, -4.2), Vector3(0, 0, -1)], [Vector3(-4.8, 1.9, 2.2), Vector3(-1, 0, 0)],
		[Vector3(4.8, 1.9, 2.4), Vector3(1, 0, 0)], [Vector3(-2.6, 5.0, 4.2), Vector3(0, 0, 1)], [Vector3(-3.0, 5.0, -4.2), Vector3(0, 0, -1)], [Vector3(0, 1.2, 17.5), Vector3(1, 0, 0)], [Vector3(0, 1.2, 17.5), Vector3(-1, 0, 0)]]
	for pr in probes:
		var q := PhysicsRayQueryParameters3D.create(pr[0] + pr[1] * 0.6, pr[0] + pr[1] * 120.0, 1)
		q.exclude = [player.get_rid()]
		if space.intersect_ray(q).is_empty():
			edges += 1
	out.append({"what": "every window and both street ends look onto real geometry (no world edge)", "ok": edges == 0, "detail": edges})
	var movers := 0
	for n in find_children("*", "CharacterBody3D", true, false):
		if n != player:
			movers += 1
	out.append({"what": "no entity: residents are static figures", "ok": movers == 0})
	return out


func _pose_hall() -> void:
	targets[0] = 1.0
	forms[0] = 1.0
	remembered[0] = true
	for g in 3:
		FX.set_form(gmats[g], visible_form(g))
	await get_tree().process_frame
