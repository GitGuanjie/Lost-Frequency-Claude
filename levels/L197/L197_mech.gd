extends RefCounted
## Level 197 systems: the amethyst wall and the sealed way back (signature), Zone 2
## disease, Zone 3 heat and searing rubies, the enraged roamer and the turquoise,
## ropes, notes, per-zone mood (fog, ambient, sound) and QA self-tests.

const C := preload("res://levels/L197/L197_cave.gd")
const Plan := preload("res://levels/L197/L197_plan.gd")
const Fort := preload("res://levels/L197/L197_fortress.gd")

var L
var qa := false
var wall_root: Node3D
var wall_lo: Node3D
var wall_hi: Node3D
var wall_shape: CollisionShape3D
var wall_dir := Vector3.ZERO
var wall_g := 0.0
var shattered := false
var plug: Node3D
var plug_end := Vector3.ZERO
var infection := 0.0
var heat := 0.0
var cool_t := 0.0
var has_mask := false
var turquoise := 0
var picked := {}
var zone_now := 1
var visited := {}
var roamer_state := 0
var roamer_t := 0.0
var chest_open := false
var chem_taken := false
var chem_light: OmniLight3D
var _said := {}
var _burn_cd := 0.0
var _amb_t := 3.0
var _beds := {}
var _rng := RandomNumberGenerator.new()
var ladders := {}


func _init(level) -> void:
	L = level
	qa = SessionState.is_qa()
	_rng.seed = 1977


func build() -> void:
	_amethyst_wall()
	_ropes()
	_notes()
	_interactables()
	_sounds()


# ------------------------------------------------------------------ amethyst wall

func _amethyst_wall() -> void:
	wall_dir = (Vector3(68.2, -0.7, -8.0) - Vector3(65.5, -0.5, -2.2))
	wall_dir.y = 0.0
	wall_dir = wall_dir.normalized()
	var side := Vector3(-wall_dir.z, 0, wall_dir.x)
	var fs: Array = L.fs_near(Plan.THRESH)
	var mid: Vector3 = Plan.THRESH + Vector3(0, 1.3, 0)
	var up := C.march(fs, mid, Vector3.UP, 8.0, L.noise)
	var ceil_y: float = (up["p"] as Vector3).y if not up.is_empty() else Plan.THRESH.y + 3.4
	var hw := 1.9
	var sw := C.march(fs, mid, side, 6.0, L.noise)
	if not sw.is_empty():
		hw = maxf(hw, (sw["p"] as Vector3).distance_to(mid) + 0.3)
	var floor_y: float = Plan.THRESH.y
	var span := ceil_y - floor_y
	wall_root = Node3D.new()
	wall_root.name = "AmethystWall"
	L.add_child(wall_root)
	wall_root.global_transform = Transform3D(Basis(side, Vector3.UP, -wall_dir), Plan.THRESH)
	wall_lo = Node3D.new()
	wall_hi = Node3D.new()
	wall_root.add_child(wall_lo)
	wall_root.add_child(wall_hi)
	wall_hi.position = Vector3(0, span, 0)
	var a := C.Acc.new()
	var b := C.Acc.new()
	var r := RandomNumberGenerator.new()
	r.seed = 197197
	for i in 90:
		var x := r.randf_range(-hw, hw)
		var z := r.randf_range(-0.3, 0.3)
		C.prism(a, Vector3(x, -0.1, z), Vector3(r.randf_range(-0.15, 0.15), 1, r.randf_range(-0.2, 0.2)), r.randf_range(0.45, 0.62) * span, r.randf_range(0.05, 0.13), r.randf() * TAU, 0.3)
		C.prism(b, Vector3(x * 0.9, 0.1, z), Vector3(r.randf_range(-0.15, 0.15), -1, r.randf_range(-0.2, 0.2)), r.randf_range(0.42, 0.6) * span, r.randf_range(0.05, 0.12), r.randf() * TAU, 0.3)
	C.commit(wall_lo, a, "l197_ame", false, "concrete")
	C.commit(wall_hi, b, "l197_ame", false, "concrete")
	var body := StaticBody3D.new()
	wall_root.add_child(body)
	wall_shape = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(hw * 2.0 + 0.6, span + 0.4, 0.8)
	wall_shape.shape = bs
	wall_shape.position = Vector3(0, span * 0.5, 0)
	wall_shape.disabled = true
	body.add_child(wall_shape)
	_set_wall(0.0)


func _set_wall(g: float) -> void:
	wall_g = clampf(g, 0.0, 1.0)
	var s := maxf(0.001, wall_g)
	wall_lo.scale = Vector3(1, s, 1)
	wall_hi.scale = Vector3(1, s, 1)
	wall_lo.visible = wall_g > 0.002
	wall_hi.visible = wall_g > 0.002
	wall_shape.set_deferred("disabled", wall_g < 0.92)


func _side_of_wall(p: Vector3) -> float:
	return (p - Plan.THRESH).dot(wall_dir)


## The way back shatters: the wall closes for good and the tunnel behind becomes an
## amethyst tunnel that tightens and ends.
func shatter() -> void:
	if shattered:
		return
	shattered = true
	_set_wall(1.0)
	var path: Array = [Plan.KNEE, Vector3(69.0, -1.0, -18.0), Vector3(70.6, -0.8, -13.0), Vector3(68.6, -0.72, -9.0)]
	plug_end = path[path.size() - 1]
	var total := 0.0
	for i in path.size() - 1:
		total += (path[i] as Vector3).distance_to(path[i + 1])
	var prof := func(t: float) -> Vector2:
		var k := pow(t, 1.2)
		var w := lerpf(0.95, 0.16, k)
		var h := lerpf(2.25, 0.3, k)
		var e := 1.0 - clampf(t * total / 1.2, 0.0, 1.0)
		return Vector2(lerpf(w, 1.6, e * e), lerpf(h, 3.0, e * e))
	plug = Node3D.new()
	plug.name = "SealedWayBack"
	L.add_child(plug)
	var a := C.Acc.new()
	var fl := C.Acc.new()
	C.loft(a, fl, path, prof, L.noise)
	C.commit(plug, a, "l197_z2_rock", true, "concrete")
	C.commit(plug, fl, "l197_z2_floor", true, "concrete")
	var cr := C.Acc.new()
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 60:
		var t := r.randf()
		var seg := mini(int(t * (path.size() - 1)), path.size() - 2)
		var lt := t * (path.size() - 1) - seg
		var c: Vector3 = (path[seg] as Vector3).lerp(path[seg + 1], lt)
		var pr: Vector2 = prof.call(t)
		var d := ((path[seg + 1] as Vector3) - (path[seg] as Vector3)).normalized()
		var sd := Vector3(-d.z, 0, d.x)
		var ang := r.randf_range(0.1, PI - 0.1)
		var p := c + sd * cos(ang) * pr.x * 0.92 + Vector3.UP * sin(ang) * pr.y * 0.92
		var n := (c + Vector3.UP * pr.y * 0.3 - p).normalized()
		C.cluster(cr, p, n, r.randf_range(0.12, 0.35) * (1.0 + t), r.randi_range(2, 5), r)
	C.cluster(cr, plug_end + Vector3(0, 0.1, 0), -((path[path.size() - 1] as Vector3) - (path[path.size() - 2] as Vector3)).normalized(), 0.6, 8, r)
	C.commit(plug, cr, "l197_ame", false, "concrete")
	if L.player:
		var behind: Vector3 = L.player.global_position - Vector3(0, 0, -6.0)
		L.sound.play_at("crackle", {}, behind, 2.0, "[behind you: rock and crystal shattering]")
		L.sound.play_at("distant_boom", {}, behind, -2.0)


# ------------------------------------------------------------------ ropes

func _rope(top: Vector3, bottom: Vector3, name: String, vol_min: Vector3, vol_max: Vector3, step_off: Vector3) -> void:
	var lv := LadderVolume.new()
	lv.name = name
	L.add_child(lv)
	lv.setup(vol_min, vol_max)
	ladders[name] = {"vol": lv, "step": step_off, "top": vol_max.y}
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.022
	cm.height = top.distance_to(bottom)
	cm.radial_segments = 6
	mi.mesh = cm
	mi.material_override = MatLib.standard(Color(0.5, 0.42, 0.28), 0.95)
	L.add_child(mi)
	mi.global_position = (top + bottom) * 0.5
	var k: GeoKit = L.kit(name + "Stake")
	k.box(top + Vector3(0, 0.1, 0), Vector3(0.06, 0.35, 0.06), "metal", GeoKit.ALL, false)
	k.commit()


func _ropes() -> void:
	var b: Vector3 = Plan.BREACH
	_rope(b + Vector3(0.75, 0.0, 0.0), Vector3(b.x + 0.75, Plan.GRAPHITE_Y, b.z), "BreachRope",
		Vector3(b.x - 0.9, Plan.GRAPHITE_Y - 0.2, b.z - 0.9), Vector3(b.x + 0.9, b.y - 0.15, b.z + 0.9), b + Vector3(-1.9, 0.05, -0.6))
	var c: Vector3 = Plan.CHIMNEY
	_rope(c + Vector3(0.3, Plan.UPPER_Y, -0.9), c + Vector3(0.3, 0.0, -0.6), "ChimneyRope",
		Vector3(c.x - 1.0, 0.0, c.z - 1.0), Vector3(c.x + 1.0, Plan.UPPER_Y - 0.3, c.z + 1.0), Vector3(c.x + 0.7, Plan.UPPER_Y + 0.05, c.z - 3.0))


# ------------------------------------------------------------------ notes, interactions

func _notes() -> void:
	var o: Vector3 = Plan.OUTPOST
	L.add_note("l197_orders", "M.E.G. Outpost \"Good Feels\" - standing orders (clipboard)",
		"Level 197, Zone 1 (the Turquoise Zone). About 53 operatives on station.\n\nWe excavate turquoise for Level 11, The Hub and Level 901. The crystals come away easily and keep their calming effect once removed. The rock itself cannot be broken: every tool has failed on it.\n\nIssue a gas mask to anyone heading into Zone 2. If none are left, they may wait at or near the outpost until the next delivery.\n\nZone 1 is structurally sound. Report ANY crack in its surface to the duty officer at once.\n\nThe lit path leads to Zone 2. An unlit path is rumoured to reach Level 108. Unconfirmed: do not send anyone down it.",
		o + Vector3(0.2, 0.83, -0.45), Vector3(0.4, 0.08, 0.4))
	L.add_note("l197_zone2", "Briefing card pinned to the gas-mask crate",
		"ZONE 2 - THE AMETHYST ZONE\nThe lavender smell soothes. The crystals also carry fast-acting diseases (smallpox-, flu-, even plague-like). Mask on. Almond Water if you have it.\n\nAs you go in, a wall of amethyst grows from floor and ceiling behind you. It is slow: turn back early and you get out unharmed.\nIf you carry on, you will hear rock and crystal shatter behind you. After that, do not go back. The tunnel behind you narrows and ends in air that breaks masks.\n\nPitch-black grooves along the way hold swarms of Deathmoths. Pass them slowly.",
		o + Vector3(4.9, 0.36, 1.9), Vector3(0.5, 0.1, 0.5))
	L.add_note("l197_zone3", "M.E.G. advisory: Zone 3 (folded into the duty log)",
		"ZONE 3 - THE RUBY ZONE: red light everywhere and unbearable heat. Some rubies sear on contact; do not touch or break them (the cooled ones leak Cashew Water, which is not drinkable).\nInclines reach 83 degrees. Check what you climb.\nRoaming entities chase on sight. Show one a turquoise crystal from Zone 1: if it slows and looks dazed, run past it. The crystal will start to shake - drop it and get clear before it detonates.\nLooking through turquoise calmed Wretches and Crawlers only.\nExits: reports contradict. Some reached Level 8. Others followed a fluorescent buzz down an unlit tunnel and woke in Level 0.",
		o + Vector3(0.55, 0.83, -0.7), Vector3(0.6, 0.08, 0.3), false)
	L.add_note("l197_zone4", "Unsigned note left at the outpost (UNVERIFIED)",
		"Delivered by no one we know. It warns of a fourth zone of onyx, nearly pitch-black, where the writer says no light works.\n- Touch the walls only lightly, with something on your hands: the crystals cut.\n- Listen to the echo to judge how close each wall is.\n- Keep moving. Something they called the Dark Sovereign comes near.\n\"when you kneel, bow, or show a sign of respect, it will dismiss you\"\nThe writer says nobody else in their party of seven survived.\n\n[M.E.G.: Zone 4 is unconfirmed. Nothing here can be verified.]",
		o + Vector3(-0.8, 0.83, -0.35), Vector3(0.4, 0.08, 0.4))
	L.add_note("l197_rope", "Tag on the rope stake", "M.E.G. RESCUE LINE. Below: the second layer of Zone 2, broken into by wanderers mining the floor. The walls down there are graphite; crystals are rare, rooms are bigger and the entities are more aggressive. They cannot climb this rope. Two operatives were lost bringing the injured up. Do not go down without weapons and a sizeable party.",
		Plan.BREACH + Vector3(0.95, 0.35, 0.25), Vector3(0.35, 0.4, 0.35), false)


func _interactables() -> void:
	L.add_interactable(Plan.OUTPOST + Vector3(4.9, 0.5, 1.9), Vector3(1.0, 0.9, 1.9), "Take a gas mask", func(_p = null) -> void:
		if has_mask:
			Overlay.subtitle("[you already have one on]", 2.0)
			return
		has_mask = true
		Overlay.subtitle("[an M.E.G. gas mask from the crate. The rubber smells of the outpost.]", 3.5))
	# turquoise you can break off, at waist height along the lit path
	var spots := [Vector3(10.0, 0, -1.6), Vector3(27.0, 0, -2.4), Vector3(44.5, 0, 2.6), Vector3(58.0, -0.1, 2.6), Vector3(-3.0, 0, 3.6)]
	var r := RandomNumberGenerator.new()
	r.seed = 1971
	var a: C.Acc = L.acc("l197_turq")
	for i in spots.size():
		var p: Vector3 = spots[i]
		var fs: Array = L.fs_near(p)
		var d := Vector3(0, 0, 1) if i % 2 == 0 else Vector3(0, 0, -1)
		var hit := C.march(fs, p + Vector3(0, 0.9, 0), d, 6.0, L.noise)
		if hit.is_empty():
			continue
		var hp: Vector3 = hit["p"]
		var hn: Vector3 = hit["n"]
		C.cluster(a, hp - hn * 0.05, (hn + Vector3(0, 0.3, 0)).normalized(), 0.45, 6, r)
		var key := i
		var leaks := i == 2
		L.add_interactable(hp + hn * 0.35, Vector3(0.9, 0.9, 0.9), "Break off a turquoise crystal", func(_p = null) -> void:
			if picked.has(key):
				Overlay.subtitle("[only stubs left here]", 2.0)
				return
			picked[key] = true
			turquoise += 1
			infection = maxf(0.0, infection - 0.1)
			if leaks:
				Overlay.subtitle("[it comes away easily - and clear water drips from where it broke. You drink. It is cold and clean.]", 4.5)
				L.player.heal(10.0)
				heat = 0.0
			else:
				Overlay.subtitle("[it comes away easily. Holding it, your shoulders drop, as if you had just got home after a long day.]", 4.5))
	L.add_interactable(Plan.COVE + Vector3(3.3, 0.7, 0.0), Vector3(1.2, 1.0, 2.4), "Drink the distilled water", func(_p = null) -> void:
		L.player.heal(15.0)
		heat = 0.0
		Overlay.subtitle("[pure, cold, tasteless water. It will not leave this level with you - drink it here.]", 4.0))
	L.add_interactable(Plan.COVE + Vector3(-1.5, 1.4, 3.6), Vector3(1.4, 2.0, 1.4), "Touch the great crystal", func(_p = null) -> void:
		Overlay.subtitle("[the hum of the water runs into your hand. You want to stay. You want to stay a long time.]", 4.5))
	var groove := Vector3(81.2, -1.0, -24.6)
	L.add_interactable(groove + Vector3(0.6, 0.3, 0.4), Vector3(0.8, 0.6, 0.8), "Take the chem-light from the small green pouch", func(_p = null) -> void:
		if chem_taken:
			return
		chem_taken = true
		chem_light = OmniLight3D.new()
		chem_light.light_color = Color(0.4, 1.0, 0.45)
		chem_light.light_energy = 0.9
		chem_light.omni_range = 7.0
		L.player.add_child(chem_light)
		chem_light.position = Vector3(0.25, 1.1, -0.3)
		infection = minf(1.0, infection + 0.15)
		L.sound.play_at("scratch", {}, groove + Vector3(1.5, 1.2, 0), 2.0, "[the dark above you stirs: wings, hundreds of them]"))
	var pouch := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.12, 0.16)
	pouch.mesh = bm
	pouch.material_override = MatLib.standard(Color(0.16, 0.24, 0.1), 0.9)
	L.add_child(pouch)
	pouch.global_position = groove + Vector3(0.6, 0.06, 0.4)
	L.add_interactable(L.chest_at + Vector3(0, 0.7, 0), Vector3(1.4, 1.0, 1.0), "Open the ruby chest", func(_p = null) -> void:
		if chest_open:
			Overlay.subtitle("[empty now]", 2.0)
			return
		chest_open = true
		heat = 0.0
		cool_t = 240.0
		L.player.heal(25.0)
		Overlay.subtitle("[inside: cooling cloths and a bottle of almond water so cold it hurts your teeth. You wrap a cloth round your neck.]", 5.0))
	for d in L.room_doors:
		L.add_interactable(d, Vector3(1.2, 2.2, 1.6), "Listen at the doorway", func(_p = null) -> void:
			L.sound.play_at("scratch", {}, (d as Vector3) + Vector3(1.5, 0, 0), -2.0, "[in the room beyond, something waits and breathes. You step back.]"))


# ------------------------------------------------------------------ sound

func _sounds() -> void:
	L.sound.bed("room_tone", {"cutoff": 120.0, "rumble": 0.25, "seconds": 6.0}, -30.0)
	_beds[1] = L.sound.bed("pad", {"root": 196.0, "chord": [0, 4, 7, 11], "bright": 0.25}, -30.0)
	_beds[2] = L.sound.bed("wind", {}, -60.0)
	_beds[3] = L.sound.bed("transformer", {"base": 48.0}, -60.0)
	_beds[5] = L.sound.bed("wind", {}, -60.0)
	L.sound.emitter("water_bed", Plan.COVE + Vector3(0, 1.0, 0), {"bright": 0.7}, -6.0, 28.0)
	L.sound.emitter("whisper", Vector3(19.0, 0.2, 26.4), {}, -20.0, 14.0)
	L.sound.emitter("fluorescent_hum", Plan.FLUO_END + Vector3(0, 1.6, 0), {}, -6.0, 26.0)
	L.sound.emitter("crackle", Plan.R1 + Vector3(0, 1.0, 0), {}, -18.0, 12.0)
	L.sound.emitter("scratch", Vector3(81.2, 0.0, -24.6), {}, -22.0, 9.0)
	L.sound.emitter("scratch", Vector3(60.2, 0.0, -28.4), {}, -22.0, 9.0)


# ------------------------------------------------------------------ runtime

func on_ready() -> void:
	if not qa:
		Overlay.subtitle("[a deep, sudden calm. Blue light in a smooth stone tunnel, and voices at a camp]", 5.0)


func _zone(p: Vector3) -> int:
	if p.z < Plan.VOID_Z and p.y > 2.0:
		return 5
	var z := Plan.zone_of(p)
	return z if z > 0 else 3


const MOOD := {
	1: [Color(0.03, 0.1, 0.11), 0.012, Color(0.4, 0.66, 0.66), 0.22],
	2: [Color(0.02, 0.012, 0.03), 0.025, Color(0.5, 0.4, 0.6), 0.09],
	3: [Color(0.1, 0.025, 0.016), 0.022, Color(0.75, 0.5, 0.42), 0.1],
	4: [Color(0.004, 0.004, 0.005), 0.04, Color(0.5, 0.5, 0.55), 0.02],
	5: [Color(0.42, 0.04, 0.025), 0.014, Color(0.95, 0.35, 0.28), 0.35],
}


func process(delta: float) -> void:
	var pl: Player = L.player
	if pl == null or not is_instance_valid(pl):
		return
	var p := pl.global_position
	zone_now = _zone(p)
	if L.fortress_hall.has_point(p):
		zone_now = 6
	var m: Array = MOOD[mini(zone_now, 5)]
	var k := 1.0 if qa else clampf(delta * 1.2, 0.0, 1.0)
	var env: Environment = L.environment
	env.fog_light_color = env.fog_light_color.lerp(m[0], k)
	env.background_color = env.fog_light_color
	env.fog_density = lerpf(env.fog_density, float(m[1]), k)
	env.ambient_light_color = env.ambient_light_color.lerp(m[2], k)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, float(m[3]), k)
	for key in _beds.keys():
		var want := -60.0
		if key == zone_now or (key == 5 and zone_now == 6):
			want = {1: -24.0, 2: -26.0, 3: -22.0, 5: -22.0}[key]
		var bed: AudioStreamPlayer = _beds[key]
		bed.volume_db = lerpf(bed.volume_db, want, k)
	if not visited.has(zone_now):
		visited[zone_now] = true
		if not qa:
			if zone_now == 2:
				SaveService.record_edge(TransitionService.get_edge("L197>L197#1"))
			elif zone_now == 3:
				SaveService.record_edge(TransitionService.get_edge("L197>L197#2"))
				Overlay.subtitle("[heat like an open oven. Everything is red.]", 3.5)
	_wall_logic(p, delta)
	_ladder_tops(pl)
	_disease(pl, p, delta)
	_heat(pl, p, delta)
	_roamer(pl, p, delta)
	_ambience(p, delta)


func _wall_logic(p: Vector3, delta: float) -> void:
	if shattered:
		return
	var s := _side_of_wall(p)
	var near := p.distance_to(Plan.THRESH) < 30.0
	if s > 2.5 and near:
		if wall_g == 0.0 and not qa:
			Overlay.subtitle("[behind you, crystal grinds against stone: purple spikes rise from the floor and reach down from the ceiling]", 4.5)
		_set_wall(wall_g + delta / 45.0)
	elif s < -6.0:
		if wall_g > 0.0:
			_set_wall(wall_g - delta / 12.0)
			if infection > 0.0:
				infection = 0.0
				if not qa:
					Overlay.subtitle("[back in the blue light, the itch in your chest is gone]", 3.0)
	if p.z < Plan.KNEE.z - 1.5 and p.x > 60.0 and p.y > -3.0:
		shatter()


func _ladder_tops(pl: Player) -> void:
	if not pl.on_ladder or pl.velocity.y < 0.5:
		return
	for key in ladders.keys():
		var d: Dictionary = ladders[key]
		var lv: LadderVolume = d["vol"]
		if lv.contains(pl.global_position + Vector3.UP * 0.9) and pl.global_position.y > float(d["top"]) - 1.4:
			pl.global_position = d["step"]
			pl.velocity = Vector3.ZERO


func _disease(pl: Player, p: Vector3, delta: float) -> void:
	var rate := 0.0
	if zone_now == 2 or zone_now == 4:
		rate = 1.0 / 260.0
		if shattered and p.distance_to(plug_end) < 8.0:
			rate = 1.0 / 25.0
		if p.distance_to(Vector3(81.2, -1.0, -24.6)) < 4.0 or p.distance_to(Vector3(60.2, -1.4, -28.4)) < 4.0:
			rate *= 3.0
		if has_mask and rate < 0.02:
			rate *= 0.35
	infection = clampf(infection + rate * delta - (0.004 * delta if zone_now == 1 else 0.0), 0.0, 1.0)
	if qa:
		return
	var marks := {0.15: "[a dry cough you can't clear. The lavender smell is in your throat.]",
		0.45: "[fever. Your skin crawls and your joints ache already.]",
		0.8: "[you are badly sick. Get out of Zone 2.]"}
	for mk in marks.keys():
		if infection >= float(mk) and not _said.has("i%s" % mk):
			_said["i%s" % mk] = true
			Overlay.subtitle(marks[mk], 4.0)
	if infection >= 1.0:
		pl.hurt(delta * 2.0, "a fast-incubating disease from the Amethyst Zone")


func _heat(pl: Player, p: Vector3, delta: float) -> void:
	if zone_now == 3:
		heat += delta / (420.0 if cool_t > 0.0 else 170.0)
	elif zone_now == 6:
		heat -= delta / 15.0
	else:
		heat -= delta / 40.0
	cool_t = maxf(0.0, cool_t - delta)
	heat = clampf(heat, 0.0, 1.0)
	_burn_cd -= delta
	if zone_now == 3 and _burn_cd <= 0.0 and not qa:
		for hs in L.hot_spots:
			if int(hs[1]) == 3 and (hs[0] as Vector3).distance_to(p + Vector3(0, 0.9, 0)) < 0.85:
				_burn_cd = 2.5
				pl.hurt(6.0, "searing rubies")
				heat = minf(1.0, heat + 0.05)
				Overlay.subtitle("[you brush a glowing ruby - it sears like a stove plate]", 2.5)
				break
	if qa:
		return
	pl.stamina = maxf(0.0, pl.stamina - delta * heat * 0.4)
	Overlay.set_screen_effect("red_tint", heat * 0.3)
	Overlay.set_screen_effect("desaturate", infection * 0.45)
	Overlay.set_screen_effect("vignette", 0.25 + infection * 0.3 + heat * 0.2)
	if heat >= 1.0:
		pl.hurt(delta * 1.5, "heatstroke in the Ruby Zone")


## An enraged roamer in Zone 3: only sound and subtitles. A turquoise crystal dazes it.
func _roamer(pl: Player, p: Vector3, delta: float) -> void:
	if qa:
		return
	if roamer_state == 0 and p.distance_to(Vector3(31.0, -1.0, -46.8)) < 3.5:
		roamer_state = 1
		roamer_t = 0.0
		L.sound.play_at("knock", {"hits": 6}, p + Vector3(-9.0, 0.5, -1.0), 4.0, "[something roaming the bore has seen you. It comes on fast, enraged]")
		L.sound.play_at("heartbeat", {}, p, -2.0)
	if roamer_state == 1:
		roamer_t += delta
		if roamer_t > 2.6:
			if turquoise > 0:
				roamer_state = 2
				roamer_t = 0.0
				Overlay.subtitle("[you hold up the turquoise. The footsteps falter. It sways, dazed - run past it]", 4.0)
			else:
				roamer_state = 4
				pl.hurt(30.0, "an enraged entity in the Ruby Zone")
				Overlay.subtitle("[you have nothing from Zone 1 to show it. It tears past you and is gone into the red]", 4.0)
	elif roamer_state == 2:
		roamer_t += delta
		if roamer_t > 4.0:
			roamer_state = 3
			roamer_t = 0.0
			Overlay.subtitle("[the crystal shakes and rattles in your hand. You drop it and run]", 3.0)
	elif roamer_state == 3:
		roamer_t += delta
		if roamer_t > 3.0:
			roamer_state = 4
			turquoise -= 1
			L.sound.play_at("distant_boom", {}, p + Vector3(6, 0, 0), 2.0, "[behind you the crystal detonates, shards ringing off the walls]")


func _ambience(p: Vector3, delta: float) -> void:
	_amb_t -= delta
	if _amb_t > 0.0 or qa:
		return
	_amb_t = _rng.randf_range(9.0, 20.0)
	var off := Vector3(_rng.randf_range(-8, 8), 1.0, _rng.randf_range(-8, 8))
	match zone_now:
		1:
			L.sound.play_at("drip", {"freq": _rng.randf_range(900.0, 1300.0)}, p + off, -10.0, "[a slow drip from a stalactite]")
		2:
			L.sound.play_at("scratch", {}, p + off, -12.0, "[a flutter of wings in some groove ahead]")
		3:
			L.sound.play_at("creak", {"freq": 70.0}, p + off, -8.0, "[far down a side bore, something heavy moves]")
		5:
			L.sound.play_at("wind", {}, p + off * 3.0, -10.0, "[air moving through a space too big to see]")


# ------------------------------------------------------------------ QA

func self_test() -> Array:
	var out := []
	out.append({"what": "four mineral zones meshed (turquoise, amethyst, ruby, graphite)", "ok": L.zone_meshes.size() == 4, "detail": L.zone_meshes})
	out.append({"what": "the documented Level 0 exit exists (fluorescent tunnel)", "ok": L.exits.size() == 1})
	out.append({"what": "crystals were found on real walls", "ok": L.hot_spots.size() > 80, "detail": L.hot_spots.size()})
	if not (is_instance_valid(wall_lo) and is_instance_valid(wall_hi) and is_instance_valid(wall_shape)):
		out.append({"what": "amethyst wall nodes exist", "ok": false})
		return out
	var g0 := wall_g
	_set_wall(0.95)
	await L.get_tree().physics_frame
	await L.get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Plan.THRESH + Vector3(0, 1.0, 0) - wall_dir * 2.0, Plan.THRESH + Vector3(0, 1.0, 0) + wall_dir * 2.0, 1)
	var blocked := not space.intersect_ray(q).is_empty()
	out.append({"what": "a grown amethyst wall blocks the way back to Zone 1", "ok": blocked})
	_set_wall(0.3)
	await L.get_tree().physics_frame
	await L.get_tree().physics_frame
	var open := space.intersect_ray(q).is_empty()
	out.append({"what": "a half-grown wall can still be passed (going back early is safe)", "ok": open})
	_set_wall(g0)
	shatter()
	out.append({"what": "walking on seals the way back with a tightening amethyst tunnel", "ok": plug != null and shattered and wall_g >= 1.0})
	return out
