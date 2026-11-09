extends LevelBase
## Level 17 "The Carrier" / Plane #17 (Backrooms Wikidot rev 9, accessed 2026-11-04;
## DrAkimoto, CC BY-SA 3.0). Dossier: docs/canon/levels/L017.md.
##
## PLAN (read -> design):
## - SOURCE: 217 athwartship passages of early-to-mid twentieth-century naval design,
##   identical but for sanitation, upkeep and occupancy; each passageway separated by a
##   reinforced bulkhead door; compartments with naval furnishings: barracks, kitchens,
##   communication centres, engineering stations. -> 217 streamed sectors in a row
##   (12 m x 22 m each, two decks): an athwartship passage joining port and starboard
##   side passages, four compartments (berthing, galley, radio room, storeroom), two
##   ladder trunks down to an engineering flat (boilers, pumps or a generator) that
##   loops between the two inclined ladders. Every sector has its own aft bulkhead with
##   two watertight doors that you open by hand and that swing shut behind you.
##   Upkeep (paint, grime, dead bulbs) varies per sector; the seed varies the fill.
## - SOURCE stateful signature: compartments keep independent time -> every
##   compartment has its own clock running at its own rate (stopped, backwards,
##   racing); reading them compares the last compartment's time.
## - SOURCE anchors at their stated sector numbers (ordered from the entrance):
##   1 oily writing by the first bulkhead door; 8 depth-charge blast holed through to
##   the lower deck; 12 the uniformed man ("civilians are not allowed", cannot leave);
##   33 charts and harbor registries; 47 whispered Lord's Prayer from a storage closet,
##   empty when opened; 67 etched mathematics on every surface; 104 infirmary with its
##   door stuck ajar (sheeted dead, implied); 156 Project RAINBOW title page (schematic
##   sheets on every sector's notice board); 165 skinless man barring the barracks;
##   185 the shut bridge door (infants, heard); 200-206 cold (-6 to 10 C); 217 the only
##   active machine (blue light, high tone, knocking) and 216 fused, living crew (shapes
##   under the plating that breathe).
## - SOURCE exit: the inconspicuous closet is both entrance and egress -> the start sits
##   by the open stores closet in sector 1's aft bulkhead; step back in to leave
##   (L017>EXT#1, destination the Storage Zone 1 antechamber, not built).
## - ADAPTATION: deck plan, dimensions, two-deck section, compartment labels, door
##   handling, clock rates, lighting and sound (the page describes none). No hangar:
##   the page describes only passages and compartments, so none is built.
## - Entity policy: occupants and remains as still presences, never combat.

const S := preload("res://levels/L017/L017_sector.gd")
const Rooms := preload("res://levels/L017/L017_rooms.gd")
const Anchors := preload("res://levels/L017/L017_anchors.gd")
const FX := preload("res://levels/L017/L017_fx.gd")
const START := Vector3(-10.1, 0.05, -2.3)

var world: Node3D
var sectors := {}            # n -> {node, meta}
var doors := {}              # key -> {pivot, open, ang, it, pos, sector}
var clocks: Array = []
var figures: Array = []
var fxs: Array = []
var cur := 1
var deck := 0                # 0 upper, 1 lower
var _fed := ""
var elapsed := 0.0
var clock_reads := 0
var last_clock := ""
var said := {}
var fx
var cold_k := 0.0
var _hull_bed: AudioStreamPlayer
var _wind_bed: AudioStreamPlayer


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 80.0
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.24
	indoor_env(Color(0.55, 0.55, 0.5), 0.07, Color(0.018, 0.019, 0.018), 0.05)
	environment.tonemap_exposure = 1.1
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.06
	Rooms.materials()
	fx = FX.new(self)
	lights.setup(12, 1)
	lights.max_distance = 26.0
	world = Node3D.new()
	world.name = "Ship"
	add_child(world)
	_stream_to(1, true)
	add_arrival("start", START, 0.0)
	var ex := add_exit("L017>EXT#1", "interact", Vector3(-10.1, 1.0, -0.15), Vector3(1.0, 2.0, 1.1),
		"Step back into the stores closet (the only known way in or out)")
	if ex:
		ex.fired.connect(func(_e: String) -> void: Overlay.glitch(0.8))
	add_note("l17_survey", "Survey sheet: Plane #17",
		"Plane #17. Reported in its current form since November 1943; once a short cut between busier planes, now leads nowhere. 217 passages, one after another, each behind a reinforced bulkhead door. Residents vary in hostility and wits: do not engage. The only way in or out is the closet behind you.",
		Vector3(-9.45, 1.0, -1.2), Vector3(0.5, 0.6, 0.6))
	_sounds()
	add_landmark("Entrance closet, sector 1", Vector3(-10.1, 0, -0.6))
	add_landmark("First bulkhead door (sector 1/2)", Vector3(-10.1, 0, S.z_of(2)))
	add_landmark("Sector 12", Vector3(-7.6, 0, S.z_of(12) - 6.0))
	add_landmark("Sector 217, the machine", Vector3(0, 0, S.z_of(217) - 9.4))
	_shots()


func _sounds() -> void:
	_hull_bed = sound.bed("room_tone", {"cutoff": 150.0, "rumble": 0.55, "seconds": 7.0}, -24.0)
	sound.bed("pad", {"root": 41.2, "chord": [0, 7, 12], "bright": 0.03, "seconds": 10.0}, -34.0)
	_wind_bed = sound.bed("wind", {"seconds": 7.0}, -80.0)
	sound.oneshot("creak", {"freq": 55.0}, 16.0, 40.0, 14.0, "[the hull groans]", -18.0)
	sound.oneshot("pipe_clank", {"f": 180.0}, 20.0, 50.0, 10.0, "[a pipe knocks somewhere overhead]", -20.0)


# --------------------------------------------------------------- streaming

## Keep sectors n-1 .. n+2 built; the doors keep sightlines short.
func _stream_to(n: int, force := false) -> void:
	cur = n
	var want := {}
	for i in range(n - 1, n + 3):
		if i >= 1 and i <= S.N:
			want[i] = true
	for k in sectors.keys():
		if not want.has(k):
			_unload(k)
	var built_one := false
	for i in range(n, n + 3) + [n - 1]:
		if want.has(i) and not sectors.has(i):
			if built_one and not force:
				break
			_load(i)
			built_one = true
	_feed()


func _load(n: int) -> void:
	var sb = S.new(self, n, level_seed)
	var meta: Dictionary = sb.build(world)
	sectors[n] = {"node": sb.node, "meta": meta}
	for d in meta["doors"]:
		_make_door(d, sb.node)
	for c in meta["clocks"]:
		c["sector"] = n
		clocks.append(c)
		var cn: Node3D = c["node"]
		make_interactable(cn.global_position + cn.basis.z * 0.2, Vector3(0.6, 0.6, 0.5), "Read the compartment clock", _read_clock.bind(c), sb.node)
	for f in meta["figures"]:
		figures.append(fx.figure(f, sb.node, n))
	for e in meta["fx"]:
		fxs.append(fx.setup(e, sb.node, n))
	_fed = ""


func _unload(n: int) -> void:
	var s: Dictionary = sectors[n]
	for key in doors.keys():
		if doors[key]["sector"] == n:
			doors.erase(key)
	clocks = clocks.filter(func(c): return c["sector"] != n)
	figures = figures.filter(func(f): return f["sector"] != n)
	fxs = fxs.filter(func(f): return f["sector"] != n)
	if is_instance_valid(s["node"]):
		s["node"].queue_free()
	sectors.erase(n)
	_fed = ""


## Pooled lights leak through decks: feed only the current deck's fixtures.
func _feed() -> void:
	var key := "%d:%s" % [deck, str(sectors.keys())]
	if key == _fed:
		return
	_fed = key
	lights.clear_anchors()
	for n in sectors.keys():
		for a in sectors[n]["meta"]["lights_low" if deck == 1 else "lights_up"]:
			lights.add_anchor(a[0], a[1], a[2], a[3], a[4], "s%d" % n)


# --------------------------------------------------------------- doors

func _make_door(d: Dictionary, parent: Node3D) -> void:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.global_position = d["hinge"]
	var s: float = d["side"]
	var k := GeoKit.new(pivot, "Leaf")
	k.box(Vector3(s * 0.43, 0.96, 0), Vector3(0.84, 1.9, 0.07), "l17_door")
	for i in 6:
		var y := 0.25 + (i % 3) * 0.7
		var x := s * (0.06 if i < 3 else 0.8)
		k.box(Vector3(x, y, -0.06), Vector3(0.06, 0.12, 0.06), "l17_steel", GeoKit.ALL, false)
		k.box(Vector3(x, y, 0.06), Vector3(0.06, 0.12, 0.06), "l17_steel", GeoKit.ALL, false)
	k.box(Vector3(s * 0.43, 1.0, -0.07), Vector3(0.5, 0.04, 0.04), "l17_brass", GeoKit.ALL, false)
	k.box(Vector3(s * 0.43, 1.0, 0.07), Vector3(0.5, 0.04, 0.04), "l17_brass", GeoKit.ALL, false)
	k.commit()
	var it := make_interactable(d["hinge"] + Vector3(s * 0.43, 1.0, 0), Vector3(1.0, 2.0, 1.4), "Knock off the dogs and open the bulkhead door", Callable(), parent)
	var rec := {"pivot": pivot, "open": false, "ang": 0.0, "it": it, "pos": d["hinge"] + Vector3(s * 0.43, 0, 0), "sector": d["sector"], "side": s}
	it.action = _toggle_door.bind(rec)
	doors[d["key"]] = rec


func _toggle_door(rec: Dictionary) -> void:
	rec["open"] = not rec["open"]
	var it: Interactable = rec["it"]
	if is_instance_valid(it):
		it.prompt = "Swing the bulkhead door shut" if rec["open"] else "Knock off the dogs and open the bulkhead door"
	sound.play_at("pipe_clank", {"f": 120.0}, rec["pos"] + Vector3.UP, -6.0, "[steel dogs clank free; the door swings on stiff hinges]" if rec["open"] else "[the door slams home; the dogs bite]")


func _update_doors(delta: float, pp: Vector3) -> void:
	for key in doors.keys():
		var rec: Dictionary = doors[key]
		var pv: Node3D = rec["pivot"]
		if not is_instance_valid(pv):
			continue
		if rec["open"] and pp.distance_to(rec["pos"]) > 15.0:
			rec["open"] = false
			var it: Interactable = rec["it"]
			if is_instance_valid(it):
				it.prompt = "Knock off the dogs and open the bulkhead door"
			sound.play_at("pipe_clank", {"f": 95.0}, rec["pos"] + Vector3.UP, -4.0, "" if said.has("door_shut") else "[somewhere behind you, a bulkhead door swings shut on its own]")
			said["door_shut"] = true
		var target: float = (95.0 if rec["open"] else 0.0) * float(rec["side"])
		rec["ang"] = move_toward(rec["ang"], target, delta * 120.0)
		pv.rotation_degrees.y = rec["ang"]


# --------------------------------------------------------------- clocks

func _clock_time(c: Dictionary) -> float:
	return fposmod(float(c["off"]) + float(c["rate"]) * elapsed, 43200.0)


func _read_clock(c: Dictionary) -> void:
	clock_reads += 1
	var t := _clock_time(c)
	var txt := "%02d:%02d" % [int(t / 3600.0) if int(t / 3600.0) > 0 else 12, int(fmod(t, 3600.0) / 60.0)]
	var extra := ""
	if float(c["rate"]) == 0.0:
		extra = " The hands are not moving."
	elif float(c["rate"]) < 0.0:
		extra = " The second hand is running backwards."
	elif float(c["rate"]) > 2.0:
		extra = " The minute hand is crawling round as you watch."
	var cmp := "" if last_clock == "" else " The last compartment's clock said %s." % last_clock
	Overlay.subtitle("[compartment %s: the clock reads %s.%s%s]" % [c["id"], txt, cmp, extra], 4.5)
	last_clock = txt


func _update_clocks(pp: Vector3) -> void:
	for c in clocks:
		var cn: Node3D = c["node"]
		if not is_instance_valid(cn) or cn.global_position.distance_squared_to(pp) > 400.0:
			continue
		var t := _clock_time(c)
		(c["m"] as Node3D).rotation.z = -fmod(t, 3600.0) / 3600.0 * TAU
		(c["h"] as Node3D).rotation.z = -t / 43200.0 * TAU


# --------------------------------------------------------------- frame

func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[steel all round. The closet you came through stands open behind you]", 4.0)


func level_process(delta: float) -> void:
	elapsed += delta
	if player == null:
		return
	var pp := player.global_position
	var n := S.sector_at(pp.z)
	if n != cur:
		_stream_to(n)
	elif sectors.size() < 4 and not (n == 1 and sectors.size() >= 3) and not (n >= S.N - 1):
		_stream_to(n)
	var d := 1 if pp.y < -1.6 else 0
	if d != deck:
		deck = d
	_feed()
	_update_doors(delta, pp)
	_update_clocks(pp)
	fx.update(delta, pp)
	_cold(delta, n)


func _cold(delta: float, n: int) -> void:
	var want := 1.0 if n >= 200 and n <= 206 else 0.0
	cold_k = move_toward(cold_k, want, delta * 0.25)
	environment.fog_light_color = Color(0.018, 0.019, 0.018).lerp(Color(0.05, 0.065, 0.085), cold_k)
	environment.fog_density = lerpf(0.05, 0.075, cold_k)
	if _wind_bed:
		_wind_bed.volume_db = lerpf(-80.0, -24.0, sqrt(cold_k))
	if want > 0.5 and not said.has("cold") and not SessionState.is_qa():
		said["cold"] = true
		Overlay.subtitle("[the air turns bitterly cold. Your breath fogs]", 4.0)


# --------------------------------------------------------------- QA

func _shots() -> void:
	var z2 := S.z_of(2)
	add_shot("closet_passage", Vector3(-10.4, 1.62, -1.6), Vector3(-9.7, 1.3, -11.6), {"flashlight": false, "prepare": _prep.bind(1, 0)})
	add_shot("athwartship_passage", Vector3(-9.6, 1.62, z2 - 6.0), Vector3(8.0, 1.2, z2 - 6.1), {"flashlight": false, "prepare": _prep.bind(2, 0)})
	add_shot("engine_flat", Vector3(3.1, S.LOW + 1.62, z2 - 2.6), Vector3(5.6, S.LOW + 0.9, z2 - 10.5), {"flashlight": false, "prepare": _prep.bind(2, 1)})
	var z12 := S.z_of(12)
	add_shot("sector12_sailor", Vector3(-2.2, 1.62, z12 - 6.1), Vector3(-7.6, 1.45, z12 - 6.0), {"flashlight": false, "prepare": _prep.bind(12, 0)})
	var z67 := S.z_of(67)
	add_shot("sector67_mathematics", Vector3(-10.5, 1.62, z67 - 9.0), Vector3(-9.3, 1.3, z67 - 6.0), {"flashlight": false, "prepare": _prep.bind(67, 0)})
	var z217 := S.z_of(217)
	add_shot("sector217_machine", Vector3(-1.4, 1.62, z217 - 5.4), Vector3(0.0, 1.2, z217 - 11.0), {"flashlight": false, "prepare": _prep.bind(217, 0)})


func _prep(n: int, d: int) -> void:
	deck = d
	_stream_to(n, true)
	for i in 3:
		await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "sectors 1-3 are built around the start", "ok": sectors.has(1) and sectors.has(2) and sectors.has(3), "detail": sectors.keys()})
	out.append({"what": "the closet exit is the only exit", "ok": exits.size() == 1, "detail": exits.size()})
	var rates := {}
	for c in clocks:
		rates[c["rate"]] = true
	out.append({"what": "compartment clocks keep independent rates", "ok": rates.size() >= 2, "detail": rates.keys()})
	var door_ok := false
	for key in doors.keys():
		var rec: Dictionary = doors[key]
		_toggle_door(rec)
		door_ok = rec["open"]
		_toggle_door(rec)
		break
	out.append({"what": "bulkhead doors open and close", "ok": door_ok})
	var c0 := clock_reads
	if not clocks.is_empty():
		_read_clock(clocks[0])
	out.append({"what": "a compartment clock can be read", "ok": clock_reads == c0 + 1})
	_stream_to(217, true)
	var m_ok := sectors.has(217) and fxs.any(func(f): return f.get("kind", "") == "machine")
	out.append({"what": "sector 217 streams in with the active machine", "ok": m_ok, "detail": sectors.keys()})
	_stream_to(12, true)
	out.append({"what": "sector 12 holds the uniformed man", "ok": figures.any(func(f): return f.get("kind", "") == "sailor")})
	_stream_to(1, true)
	await get_tree().physics_frame
	out.append({"what": "streaming back restores the entrance sectors", "ok": sectors.has(1) and not sectors.has(217)})
	return out
