extends LevelBase
## Level 3.5 — "Electropolis" (Backrooms Wiki rev 42, accessed 2026-11-04;
## cite: exotichive, CC BY-SA 3.0). Dossier: docs/canon/levels/L003_5.md.
##
## DESIGN PLAN
## Space: a "hypothetically endless" monochrome mid-20th-century brutalist city
##   (page) as seeded 48 m blocks streamed around the player (a finite streaming
##   window): concrete towers with dark window bands and fins, slab blocks with
##   ribbon balconies, plazas of transmission pylons, exoskeletal floodlight towers
##   whose lamps pulse. The sky is a starless void. Everything is grey.
## Anchor: you arrive through a steel door inside the spired skyscraper of the dead
##   M.E.G. outpost "Antenna to Heaven" (page: door from Level 3 into a skyscraper;
##   outpost of 16 researchers, 5 guards, a director, all expired, inactive). Four
##   reachable storeys by a switchback stair: lobby and guard room, laboratories,
##   living quarters, utility room and the director's office; window bands look out
##   on the storm. Every other building has one open lobby: shelter.
## Signature mechanic (SOURCE): a constant storm. Discharges fall from the void at
##   unpredictable intervals on pylons, masts, rooftops and people. Each one is a
##   blinding flash, then thunder delayed by distance; near you its concussion
##   muffles hearing (low-pass), rocks the camera and hurts; a direct hit kills.
##   Indoors you are safe. Outdoors, exposure builds: strikes find you more often
##   and land closer until one lands on you ("prolonged exposure outdoors will
##   invariably result in expiration"). The Windows show in skyscraper glass only,
##   in the flashes.
## Exit (SOURCE, DANGEROUS+CONDITIONAL): a strike on a pylon leaves a grounded
##   discharge crawling down it for a few seconds; walk into it ("no-clipping
##   directly into an electrostatic discharge may transport you to Level 3"). It
##   "may": each discharge either takes you or strikes you down.
## Second heights: the outpost tower's four storeys. No Throne of Zeus (it has
##   disappeared), no living people, no other entity.

const City := preload("res://levels/L003_5/L003_5_city.gd")
const Tower := preload("res://levels/L003_5/L003_5_tower.gd")
const SPAWN := Vector3(23.3, 0.05, 31.0)
const EXIT_ID := "L003_5>L003#1"
const ANCHOR := Vector3(68.0, 0.0, 24.0)
const AMB := 0.07

var city
var tower
var world: ChunkWorld
var metas: Dictionary = {}
var pylons: Array = []        # {base, top, node, arc_t, ok, hurt, bolt, light, persist}
var exposure := 0.0
var indoors := true
var strikes := 0
var notes_staged := 0
var _strike_t := 3.0
var _t := 0.0
var _in_t := 0.0
var _deaf := 0.0
var _wobble := 0.0
var _flash := 0.0
var _lpf: AudioEffectLowPassFilter
var _told: Dictionary = {}
var _figs: Array = []
var _pending: Dictionary = {}


func build() -> void:
	rules["reverb_room"] = 0.75
	rules["reverb_wet"] = 0.16
	rules["view_distance"] = 260.0
	rules["kill_y"] = -30.0
	indoor_env(Color(0.85, 0.87, 0.9), AMB, Color(0.035, 0.036, 0.04), 0.0085)
	environment.background_color = Color(0, 0, 0)
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 0.9
	environment.glow_bloom = 0.04
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.05
	environment.adjustment_contrast = 1.12
	_materials()
	lights.setup(16, 1)
	lights.max_distance = 80.0
	city = City.new(self)
	tower = Tower.new(self)
	var tn := Node3D.new()
	tn.name = "Outpost"
	add_child(tn)
	tower.build(tn, rng)
	_tower_floods(tn)
	world = ChunkWorld.new()
	world.name = "City"
	world.chunk_size = City.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", SPAWN, -90.0)
	add_arrival("from_L003", SPAWN, -90.0)
	world.build_around(SPAWN, 2)
	_documents()
	sound.bed("room_tone", {"cutoff": 120.0, "rumble": 0.8}, -20.0)
	sound.bed("thunder", {"seconds": 9.0, "low": 0.9}, -30.0)
	sound.oneshot("distant_boom", {}, 4.0, 11.0, 30.0, "", -18.0)
	add_landmark("Outpost 'Antenna to Heaven' (lobby)", SPAWN)
	add_landmark("Pylon plaza east of the outpost", ANCHOR)
	_shots()


func _materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	m.call("l35_pavement", "concrete", {"albedo_a": Color(0.42, 0.42, 0.42), "albedo_b": Color(0.36, 0.36, 0.36), "pattern": 1,
		"pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.01, "grout_color": Color(0.24, 0.24, 0.24), "wetness": 0.35})
	m.call("l35_paint", "plaster", {"albedo_a": Color(0.6, 0.6, 0.6), "albedo_b": Color(0.45, 0.45, 0.45), "noise_scale": 4.0})
	m.call("l35_floor_concrete", "concrete", {"albedo_a": Color(0.4, 0.4, 0.4), "albedo_b": Color(0.34, 0.34, 0.34), "roughness_a": 0.6})
	m.call("l35_stair_concrete", "concrete", {"albedo_a": Color(0.45, 0.45, 0.45), "albedo_b": Color(0.4, 0.4, 0.4)})
	m.call("l35_lobby_floor", "pool_tile", {"albedo_a": Color(0.3, 0.3, 0.3), "albedo_b": Color(0.26, 0.26, 0.26), "pattern_scale": Vector2(0.6, 0.6),
		"grout_color": Color(0.18, 0.18, 0.18), "roughness_a": 0.4, "stain_amount": 0.4, "stain_color": Color(0.15, 0.15, 0.15)})
	m.call("l35_plaster", "plaster", {"albedo_a": Color(0.62, 0.62, 0.62), "albedo_b": Color(0.56, 0.56, 0.56), "stain_amount": 0.35, "stain_color": Color(0.4, 0.4, 0.4)})
	m.call("l35_seal", "concrete", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.42, 0.42, 0.42), "bump_strength": 1.6})
	m.call("l35_steel", "metal", {"albedo_a": Color(0.35, 0.36, 0.37), "albedo_b": Color(0.28, 0.29, 0.3), "metallic_value": 0.7, "roughness_a": 0.45})
	m.call("l35_insulator", "metal", {"albedo_a": Color(0.7, 0.7, 0.7), "albedo_b": Color(0.62, 0.62, 0.62), "metallic_value": 0.1, "roughness_a": 0.2})
	m.call("l35_fixture", "metal", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.45, 0.45, 0.45)})
	m.call("l35_counter", "metal", {"albedo_a": Color(0.42, 0.43, 0.44), "albedo_b": Color(0.38, 0.39, 0.4), "metallic_value": 0.4})
	m.call("l35_locker", "metal", {"albedo_a": Color(0.4, 0.42, 0.44), "albedo_b": Color(0.36, 0.38, 0.4), "pattern": 1, "pattern_scale": Vector2(0.6, 1.9),
		"grout_width": 0.01, "grout_color": Color(0.2, 0.2, 0.2), "metallic_value": 0.5})
	m.call("l35_door", "metal", {"albedo_a": Color(0.3, 0.31, 0.32), "albedo_b": Color(0.26, 0.27, 0.28), "metallic_value": 0.6, "stain_amount": 0.3})
	m.call("l35_board", "plaster", {"albedo_a": Color(0.85, 0.85, 0.85), "albedo_b": Color(0.8, 0.8, 0.8), "roughness_a": 0.2, "stain_amount": 0.3, "stain_color": Color(0.5, 0.5, 0.5)})
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.03, 0.035, 0.04)
	glass.metallic = 0.9
	glass.roughness = 0.06
	glass.metallic_specular = 1.0
	MatLib.register("l35_glass", glass)
	var pane := StandardMaterial3D.new()
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane.albedo_color = Color(0.5, 0.55, 0.6, 0.12)
	pane.roughness = 0.05
	pane.metallic_specular = 0.9
	MatLib.register("l35_window_pane", pane)
	MatLib.register("l35_flood", MatLib.panel(Color(0.95, 0.97, 1.0), 6.0))
	MatLib.register("l35_tube", MatLib.panel(Color(0.9, 0.92, 0.95), 1.6))
	MatLib.register("l35_bolt", MatLib.panel(Color(0.85, 0.9, 1.0), 14.0))
	var fig := StandardMaterial3D.new()
	fig.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fig.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fig.albedo_color = Color(0.62, 0.64, 0.66, 0.55)
	MatLib.register("l35_figure", fig)


## Floodlights on the outpost's crown and an exoskeletal rig up its east face.
func _tower_floods(tn: Node3D) -> void:
	var k := GeoKit.new(tn, "Floods")
	var meta := {"floods": []}
	var c := Vector3(Tower.F.get_center().x, 0, Tower.F.get_center().y)
	var half := Tower.F.size.x * 0.5 + 1.6
	for n: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		city._flood_head(k, c + n * half + Vector3(0, Tower.TOP - 8.6, 0), n, meta)
	for y: float in [24.0, 44.0, 64.0]:
		city._flood_head(k, Vector3(Tower.F.end.x + 1.6, y, c.z + (y - 44.0) * 0.2), Vector3(1, 0, 0), meta)
		k.box(Vector3(Tower.F.end.x + 1.0, y, c.z), Vector3(1.2, 0.3, 8.0), "l35_steel", GeoKit.ALL, false)
	k.box(Vector3(Tower.F.end.x + 1.2, (Tower.SH * 4.0 + Tower.TOP) * 0.5, c.z - 4.0), Vector3(0.4, Tower.TOP - Tower.SH * 4.0, 0.4), "l35_steel", GeoKit.ALL, false)
	k.box(Vector3(Tower.F.end.x + 1.2, (Tower.SH * 4.0 + Tower.TOP) * 0.5, c.z + 4.0), Vector3(0.4, Tower.TOP - Tower.SH * 4.0, 0.4), "l35_steel", GeoKit.ALL, false)
	k.commit()
	for f in meta["floods"]:
		var i := lights.add_anchor(f["pos"], Color(0.92, 0.95, 1.0), 4.0, 45.0, 0.0, "tower_floods")
		lights.anchors[i]["e0"] = 4.0
		lights.anchors[i]["ph"] = float(i % 7)


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = city.build_chunk(cx, cz, node)
	var grp := "c%d_%d" % [cx, cz]
	if cx == 0 and cz == 0:
		meta["targets"].append_array(tower.targets)
	for f in meta["floods"]:
		var i := lights.add_anchor(f["pos"], Color(0.92, 0.95, 1.0), 3.4, 40.0, 0.0, grp)
		lights.anchors[i]["e0"] = 3.4
		lights.anchors[i]["ph"] = float(absi(hash([cx, cz, i])) % 628) / 100.0
	for pl in meta["pylons"]:
		var rec := {"base": pl["base"], "top": pl["top"], "node": node, "arc_t": 0.0, "ok": false, "hurt": false, "bolt": null, "light": null, "persist": false}
		pylons.append(rec)
		# QA: only the plaza pylon by the outpost carries the exit (deterministic fixture)
		if SessionState.is_qa() and (pl["base"] as Vector3).distance_to(ANCHOR) >= 0.5:
			continue
		var t := make_exit(EXIT_ID, "walk_in", (pl["base"] as Vector3) + Vector3(0, 1.5, 0), Vector3(3.0, 3.0, 3.0), "", node)
		if t:
			t.condition = _arc_takes_you.bind(rec)
		if SessionState.is_qa() and (pl["base"] as Vector3).distance_to(ANCHOR) < 0.5:
			_arc(rec, 1.0e9, true)
			rec["persist"] = true
	metas[Vector2i(cx, cz)] = meta
	return meta


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("c%d_%d" % [k.x, k.y])
	metas.erase(k)
	for p in pylons:
		if not is_instance_valid(p["node"]) or (p["node"] as Node).is_queued_for_deletion():
			var b: Node = p["bolt"]
			if b and is_instance_valid(b):
				b.queue_free()
	pylons = pylons.filter(func(p): return is_instance_valid(p["node"]) and not (p["node"] as Node).is_queued_for_deletion())
	exits = exits.filter(func(t): return is_instance_valid(t) and not t.is_queued_for_deletion())


func _arc_takes_you(rec: Dictionary) -> bool:
	return rec["arc_t"] > 0.0 and rec["ok"]


# ------------------------------------------------------------------ documents

func _documents() -> void:
	add_note("L003_5_register", "Outpost register (clipboard)",
		"[i]The reception clipboard of the M.E.G. provisional outpost. Paraphrased.[/i]\n\nPROVISIONAL OUTPOST \"ANTENNA TO HEAVEN\". Jurisdiction: the Trial Testers Division. Purpose: infrastructure for short-term field research of Level 3.5. Rooms found in the tower repurposed as laboratories, utility rooms and living quarters for sixteen permanent field researchers, five security guards and one outpost director.\n\nStatus, added in another hand: all stationed personnel expired, abruptly and of natural causes. Outpost functionally inactive. No plans to assemble another.",
		tower.notes_at["register"])
	add_note("L003_5_field", "Field notes (laboratory)",
		"[i]A researcher's summary pinned under a coffee ring. Paraphrased.[/i]\n\nAn endless monochrome industrial city, brutalist, mid-twentieth-century. No stars: the sky is a void. The floodlights on the steel towers pulse.\n\nDischarges fall from the void at intervals we cannot measure. They hit pylons, towers and people, in no pattern. Each strike's shockwave disorients and deafens for a while; people describe pressure in the chest and skull.\n\nEarly reports called this place habitable. They were wrong. The furthest anyone has walked is 3.5 km from where they came in, before a discharge struck them.\n\nThe only thing living here besides us shows up in the reflective glass of the skyscrapers. It never shows indoors. Stay inside.",
		tower.notes_at["field"])
	add_note("L003_5_log", "Printed log (utility room)",
		"[i]A printout from the Electrostatic Discharge Power Plant, paraphrased. Timestamps 19:42:13 to 19:42:14.[/i]\n\nCRITICAL: power threshold exceeded.\nERROR: core overload, irreversible.\nALERT: structural failure in about 1.2 seconds.\nINFO: no personnel signatures detected.\nSYSTEM: emergency shutdown started.\nFATAL: facility operations terminated.\n\n[i]Nobody here knows where the plant was.[/i]",
		tower.notes_at["log"])
	add_note("L003_5_memo", "Director's memo",
		"[i]Typed, unsigned, on the director's desk. Paraphrased.[/i]\n\nRe: the Throne of Zeus. A fortified skyscraper with every pane deliberately smashed and either filled with concrete or fitted with dummy gun emplacements. It drew the storm into itself, apparently to power some mass-destructive paraweapon. It is gone: the structure simply disappeared. The UEC denies it ever existed.\n\nRe: leaving. Getting in is easy. Getting out is highly improbable. The only way out anyone lists is to no-clip straight into a discharge, which may put you in Level 3. Watch the pylons: when one is struck, the discharge crawls down it for a few seconds.",
		tower.notes_at["memo"])
	notes_staged = 4


# ------------------------------------------------------------------ storm

func on_player_ready() -> void:
	world.target = player
	if not SessionState.is_qa():
		Overlay.subtitle("[a steel door shuts behind you. Outside, the sky is black and the thunder never stops.]", 5.0)


func _exit_tree() -> void:
	_drop_lpf()


func _indoors_at(p: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.9, 0), p + Vector3(0, 40.0, 0), 1))
	return not hit.is_empty()


func level_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var pp := player.global_position
	_in_t -= delta
	if _in_t <= 0.0:
		_in_t = 0.2
		indoors = _indoors_at(pp)
	if indoors:
		exposure = maxf(0.0, exposure - delta * 3.0)
		_told.erase("pressure")
	else:
		exposure += delta
		if exposure > 10.0 and not _told.has("pressure") and not SessionState.is_qa():
			_told["pressure"] = true
			Overlay.subtitle("[pressure builds in your sternum and skull. You are exposed out here.]", 4.0)
	# floodlights pulse steadily
	var pulse := 0.72 + 0.28 * sin(_t * 1.4)
	for a in lights.anchors:
		if a.has("e0"):
			a["energy"] = a["e0"] * (0.7 + 0.3 * sin(_t * 1.4 + float(a["ph"])))
	(MatLib.get_mat("l35_flood") as ShaderMaterial).set_shader_parameter("energy", 6.0 * pulse)
	# the storm (no random strikes in QA)
	if not SessionState.is_qa():
		_strike_t -= delta
		if _strike_t <= 0.0:
			_strike_t = rng.randf_range(3.0, 9.0)
			_storm_event(pp)
	_arcs(delta, pp)
	# aftermath: hearing, balance, the flash
	if _deaf > 0.0:
		_deaf = maxf(0.0, _deaf - delta / 6.0)
		if _lpf:
			_lpf.cutoff_hz = lerpf(20000.0, 260.0, pow(_deaf, 0.6))
		if _deaf <= 0.0:
			_drop_lpf()
	if _wobble > 0.0:
		_wobble = maxf(0.0, _wobble - delta / 3.0)
		player.head.rotation.z = sin(_t * 7.0) * 0.07 * _wobble
		if _wobble <= 0.0:
			player.head.rotation.z = 0.0
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.5)
		environment.ambient_light_energy = AMB + _flash * 1.2
		environment.background_color = Color(1, 1, 1) * (_flash * 0.35)
		if _flash <= 0.0:
			for f in _figs:
				if is_instance_valid(f):
					f.queue_free()
			_figs.clear()


## One storm event: a strike on the player (more likely the longer you stay
## out), on the nearest pylon (it then holds a discharge), or anywhere else.
func _storm_event(pp: Vector3) -> void:
	strikes += 1
	var p_player := 0.0 if indoors else clampf(0.1 + exposure / 55.0, 0.1, 1.0)
	var roll := rng.randf()
	if roll < p_player:
		var off := lerpf(16.0, 0.0, clampf(exposure / 70.0, 0.0, 1.0))
		var ang := rng.randf() * TAU
		var tgt := Vector3(pp.x + cos(ang) * off, 0.0, pp.z + sin(ang) * off)
		_flash = maxf(_flash, 0.25)
		get_tree().create_timer(0.45).timeout.connect(_strike.bind(tgt, null, false))
		return
	if roll < p_player + 0.35:
		var best: Dictionary = {}
		var bd := 1.0e9
		for pl in pylons:
			var d: float = (pl["base"] as Vector3).distance_to(pp)
			if d < bd and pl["arc_t"] <= 0.0:
				bd = d
				best = pl
		if not best.is_empty() and bd < 160.0:
			_strike(best["top"], best, false)
			return
	var cands: Array = []
	for k in metas.keys():
		for t in metas[k]["targets"]:
			cands.append(t)
	if not cands.is_empty():
		_strike(cands[rng.randi() % cands.size()], null, false)


## A discharge from the void onto `tgt`. pylon (Dictionary or null) then holds a
## grounded discharge. hold keeps the bolt for rendered stills.
func _strike(tgt: Vector3, pylon, hold: bool) -> void:
	var bolt := _bolt_node(Vector3(tgt.x + rng.randf_range(-25, 25), 240.0, tgt.z + rng.randf_range(-25, 25)), tgt, 0.3, true)
	var fl := OmniLight3D.new()
	fl.light_color = Color(0.85, 0.9, 1.0)
	fl.light_energy = 14.0
	fl.omni_range = 110.0
	fl.position = tgt + Vector3(0, 25.0, 0)
	add_child(fl)
	_flash = 1.0
	_windows()
	if not hold:
		var tw := create_tween()
		tw.tween_property(fl, "light_energy", 1.0, 0.08)
		tw.tween_property(fl, "light_energy", 10.0, 0.05)
		tw.tween_property(fl, "light_energy", 0.0, 0.3)
		tw.tween_callback(fl.queue_free)
		get_tree().create_timer(0.38).timeout.connect(bolt.queue_free)
	var pp := player.global_position if player else SPAWN
	var d := Vector2(tgt.x - pp.x, tgt.z - pp.z).length()
	var delay := minf(d / 343.0, 4.0)
	get_tree().create_timer(maxf(delay, 0.05)).timeout.connect(_thunder.bind(tgt, d))
	if pylon != null:
		_arc(pylon, 2.6, rng.randf() < 0.6)
	if not indoors and player and not hold:
		_concuss(d, true)


func _thunder(at: Vector3, d: float) -> void:
	var db := lerpf(2.0, -16.0, clampf(d / 250.0, 0.0, 1.0)) - (12.0 if indoors else 0.0)
	sound.play_at("thunder", {"seconds": 4.0, "low": 0.7}, at.lerp(player.global_position if player else at, 0.85), db,
		"" if SessionState.is_qa() else ("[a headsplitting crack of thunder]" if d < 60.0 else "[thunder rolls between the towers]"))


## Concussion by distance from a strike (outdoors). Returns damage dealt.
func _concuss(d: float, apply: bool) -> float:
	var dmg := 0.0
	if d < 2.4:
		dmg = 1000.0
	elif d < 8.0:
		dmg = lerpf(55.0, 22.0, (d - 2.4) / 5.6)
	if not apply:
		return dmg
	if d < 45.0:
		_deafen(clampf(1.2 - d / 45.0, 0.3, 1.0))
		_wobble = maxf(_wobble, clampf(1.0 - d / 40.0, 0.2, 1.0))
		if not _told.has("deaf") and not SessionState.is_qa():
			_told["deaf"] = true
			Overlay.subtitle("[the concussion slams through you; your ears ring and the city goes muffled]", 4.0)
	if dmg > 0.0 and player and not player.dead:
		player.hurt(dmg, "struck by an electrostatic discharge")
		Overlay.glitch(0.4)
	return dmg


func _deafen(amount: float) -> void:
	_deaf = maxf(_deaf, amount)
	if _lpf == null:
		_lpf = AudioEffectLowPassFilter.new()
		_lpf.cutoff_hz = 400.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), _lpf)


func _drop_lpf() -> void:
	if _lpf == null:
		return
	var idx := AudioServer.get_bus_index("Master")
	for i in range(AudioServer.get_bus_effect_count(idx) - 1, -1, -1):
		if AudioServer.get_bus_effect(idx, i) == _lpf:
			AudioServer.remove_bus_effect(idx, i)
	_lpf = null


## Jagged bolt from a to b with a few branches, as emissive boxes.
func _bolt_node(a: Vector3, b: Vector3, thick: float, branches: bool, jit: float = 9.0) -> Node3D:
	var n := Node3D.new()
	n.name = "Bolt"
	add_child(n)
	var k := GeoKit.new(n, "B")
	k.shadows = false
	var segs := 16
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / segs
		var q := a.lerp(b, t)
		if i < segs:
			var j := (1.0 - t) * jit + jit * 0.11
			q += Vector3(rng.randf_range(-j, j), rng.randf_range(-2.0, 2.0) * minf(1.0, jit / 9.0), rng.randf_range(-j, j))
		_seg(k, prev, q, thick)
		if branches and i < segs - 2 and rng.randf() < 0.25:
			var bp := q
			for s in 4:
				var nq := bp + Vector3(rng.randf_range(-6, 6), -rng.randf_range(4, 10), rng.randf_range(-6, 6))
				_seg(k, bp, nq, thick * 0.4)
				bp = nq
		prev = q
	k.commit()
	return n


static func _seg(k: GeoKit, a: Vector3, b: Vector3, th: float) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var z := d.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(th, th, d.length()), "l35_bolt", GeoKit.ALL, false)


## The Windows: in a flash, pale figures stand inside nearby skyscraper glass.
func _windows() -> void:
	if player == null:
		return
	var pp := player.global_position
	var near: Array = []
	for k in metas.keys():
		for gl in metas[k]["glass"]:
			if (gl["pos"] as Vector3).distance_to(pp) < 80.0:
				near.append(gl)
	for i in mini(3, near.size()):
		var gl: Dictionary = near[rng.randi() % near.size()]
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.6, 1.7)
		mi.mesh = qm
		mi.material_override = MatLib.get_mat("l35_figure")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var n: Vector3 = gl["n"]
		mi.global_transform = Transform3D(Basis.looking_at(-n, Vector3.UP), (gl["pos"] as Vector3) + Vector3(0, -0.05, 0))
		_figs.append(mi)


# ------------------------------------------------------------------ discharge exit

## A grounded discharge crawling down pylon `rec` for `secs`. ok: whether this
## one takes you to Level 3 ("may") or strikes you down.
func _arc(rec: Dictionary, secs: float, ok: bool) -> void:
	rec["arc_t"] = secs
	rec["ok"] = ok
	rec["hurt"] = false
	if rec["light"] == null or not is_instance_valid(rec["light"]):
		var l := OmniLight3D.new()
		l.light_color = Color(0.8, 0.88, 1.0)
		l.light_energy = 6.0
		l.omni_range = 26.0
		l.position = (rec["base"] as Vector3) + Vector3(0, 6.0, 0)
		(rec["node"] as Node3D).add_child(l)
		rec["light"] = l
	var snd := sound.emitter("crackle", (rec["base"] as Vector3) + Vector3(0, 3.0, 0), {}, -4.0, 40.0)
	snd.reparent(rec["node"])
	rec["snd"] = snd


func _arcs(delta: float, pp: Vector3) -> void:
	for rec in pylons:
		if rec["arc_t"] <= 0.0:
			continue
		if not rec["persist"]:
			rec["arc_t"] -= delta
		var b: Node3D = rec["bolt"]
		if b and is_instance_valid(b):
			b.queue_free()
		if rec["arc_t"] > 0.0:
			var base: Vector3 = rec["base"]
			rec["bolt"] = _bolt_node(rec["top"], base + Vector3(rng.randf_range(-0.6, 0.6), 0.05, rng.randf_range(-0.6, 0.6)), 0.16, false, 1.4)
			var l: OmniLight3D = rec["light"]
			if l and is_instance_valid(l):
				l.light_energy = rng.randf_range(3.0, 8.0)
			# a discharge that does not take you strikes you down instead
			var d := Vector2(base.x - pp.x, base.z - pp.z).length()
			if d < 1.6 and not rec["ok"] and not rec["hurt"] and player and not player.dead:
				rec["hurt"] = true
				_concuss(3.0, true)
				if not SessionState.is_qa():
					Overlay.subtitle("[the discharge throws you down. It did not take you anywhere.]", 3.5)
		else:
			rec["bolt"] = null
			var l2: OmniLight3D = rec["light"]
			if l2 and is_instance_valid(l2):
				l2.queue_free()
			rec["light"] = null
			var s: Node = rec.get("snd", null)
			if s and is_instance_valid(s):
				s.queue_free()


# ------------------------------------------------------------------ QA

func _shots() -> void:
	add_shot("lobby", Vector3(23.6, 1.62, 33.5), Vector3(40.0, 2.4, 22.0))
	add_shot("laboratories", Vector3(18.6, Tower.SH + 1.62, 14.0), Vector3(33.0, Tower.SH + 0.8, 31.0))
	add_shot("window_view", Vector3(34.6, Tower.SH + 1.62, 24.2), Vector3(110.0, 14.0, 8.0),
		{"prepare": func(): await _prep_strike(Vector3(110.0, 0, -30.0), Vector3(80, 0, 20))})
	add_shot("director", Vector3(29.0, Tower.SH * 3.0 + 1.62, 35.6), Vector3(36.0, Tower.SH * 3.0 + 1.0, 29.0))


func _prep_strike(tgt: Vector3, at: Vector3) -> void:
	world.build_around(at, 1)
	_flash = 0.0
	for f in _figs:
		if is_instance_valid(f):
			f.queue_free()
	_figs.clear()
	for c in get_children():
		if c.name.begins_with("Bolt") or c is OmniLight3D:
			c.queue_free()
	_strike(tgt, null, true)
	_flash = 0.35
	environment.ambient_light_energy = AMB + 0.25
	await get_tree().process_frame


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	plan.append({"name": "street", "pos": Vector3(47.5, 1.62, 30.0), "target": Vector3(47.0, 22.0, -70.0),
		"prepare": func(): await _prep_strike(Vector3(60.0, 0, -60.0), Vector3(48, 0, -20))})
	plan.append({"name": "pylon_discharge", "pos": Vector3(52.0, 1.62, 34.0), "target": Vector3(68.0, 12.0, 24.0),
		"prepare": func(): world.build_around(ANCHOR, 1)})
	plan.append({"name": "outpost_tower", "pos": Vector3(50.0, 1.62, 44.0), "target": Vector3(26.0, 48.0, 26.0),
		"prepare": func(): await _prep_strike(Vector3(24.0, 134.0, 24.0), Vector3(60, 0, 50))})
	return plan


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "four outpost documents staged", "ok": notes_staged == 4})
	out.append({"what": "outpost tower dressed with placed models", "ok": tower.props >= 50, "detail": tower.props})
	var space := get_world_3d().direct_space_state
	var f1 := Vector3(30.0, Tower.SH + 1.0, 24.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(f1, f1 + Vector3(0, -2.0, 0), 1))
	out.append({"what": "outpost upper storeys are walkable (F1 floor)", "ok": not hit.is_empty() and absf(hit["position"].y - Tower.SH) < 0.05, "detail": hit.get("position", null)})
	out.append({"what": "inside the outpost counts as shelter", "ok": _indoors_at(SPAWN)})
	out.append({"what": "the open street does not", "ok": not _indoors_at(Vector3(48.0, -0.15, 24.0))})
	var lob_ok := false
	for k in metas.keys():
		for lob in metas[k]["lobbies"]:
			var lr: Rect2 = lob
			if _indoors_at(Vector3(lr.get_center().x, 0.0, lr.get_center().y)):
				lob_ok = true
	out.append({"what": "other buildings have sheltering lobbies", "ok": lob_ok})
	out.append({"what": "a strike near you outdoors hurts; a direct hit kills", "ok": _concuss(5.0, false) > 0.0 and _concuss(1.0, false) >= 1000.0 and _concuss(30.0, false) == 0.0})
	var tg := 0
	var gl := 0
	for k in metas.keys():
		tg += (metas[k]["targets"] as Array).size()
		gl += (metas[k]["glass"] as Array).size()
	out.append({"what": "strike targets (pylons, masts, roofs) and glass for the Windows", "ok": tg >= 10 and gl >= 10, "detail": [tg, gl]})
	# a struck pylon holds a discharge, then lets go
	var other: Dictionary = {}
	for pl in pylons:
		if not pl["persist"]:
			other = pl
	if other.is_empty() and not pylons.is_empty():
		other = pylons[0]
	if not other.is_empty():
		var was_persist: bool = other["persist"]
		other["persist"] = false
		_strike(other["top"], other, false)
		var held: bool = other["arc_t"] > 0.0
		for n in 4:
			_arcs(1.0, Vector3(9999, 0, 9999))
		out.append({"what": "a struck pylon holds a discharge for seconds, then it ends", "ok": held and other["arc_t"] <= 0.0})
		if was_persist:
			_arc(other, 1.0e9, true)
			other["persist"] = true
	var e0 := 0.0
	for a in lights.anchors:
		if a.has("e0"):
			e0 = a["energy"]
			break
	_t += 1.1
	level_process(0.0)
	var e1 := 0.0
	for a in lights.anchors:
		if a.has("e0"):
			e1 = a["energy"]
			break
	out.append({"what": "floodlights pulse", "ok": absf(e1 - e0) > 0.01, "detail": [e0, e1]})
	_flash = 0.0
	_deaf = 0.0
	_drop_lpf()
	return out
