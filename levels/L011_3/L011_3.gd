extends LevelBase
## Level 11.3 — "The Red Light District" (Backrooms Wikidot rev 21, accessed
## 2026-11-04; cite: Noctilucian (with VivamusLudio), CC BY-SA 3.0).
## Dossier: docs/canon/levels/L011_3.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: a corrupted city of steel and glass descended from the Endless City;
## a moonless night sky stained by crimson lights; psychoactive air (vivid,
## frightening hallucinations, suggestibility) mitigated by facial coverings;
## sweltering damp to icy drizzle, rain with red lightning; outskirts of
## apartments, warehouses and shops thickening into office towers and
## high-rises; electricity works in places, water systems do not; buildings
## bare and gutted; no humans (any human is a deception); Servants follow in
## groups from afar, herd into dead ends and buildings, capture on opportunity;
## the Embassy, a domed city-hall complex deep inside with Ambassadors, Servants
## patrolling and a sadistic hum; the Vortex is never seen directly; bridges
## at the outskirts stretch into infinity over a large body of water to Level 11
## and are usually guarded.
## Layout: the arrival alley on the outskirts (the page's dark-alley entrance),
## a gutted three-storey shell beside it (stairs, two upper floors), a grid of
## blocks rising from low outskirts (south) to towers (north) along a main
## avenue that ends at the Embassy plaza; the waterfront road, a quay and two
## guarded bridges whose lamps run out into red fog. A continuous ring of
## buildings closes every street; water and fog close the south.
## Mechanics: (1) contaminant exposure: unmasked, red tint, whispers, false
## humans and the voice grow; the cloth respirator by the arrival crate turns it
## back. (2) Servants: stalkers keep to the street ends behind you; resting or
## lingering in enclosed space builds pressure until they close in and take you.
## (3) The bridge guards turn and follow anyone who starts across; outpace them.
## (4) Weather swings between damp mist and icy drizzle with red lightning.
## Helper: L011_3_city.gd (materials, blocks, bridges, Embassy, gutted shell).

const CK := preload("res://levels/L011_3/L011_3_city.gd")
const FG := preload("res://levels/L011_3/L011_3_figures.gd")
const START := Vector3(-27.0, 0.15, 119.2)
const GUT := AABB(Vector3(-24.5, 0.0, 90.0), Vector3(14.5, 11.0, 32.0))
const ALLEY := AABB(Vector3(-29.5, 0.0, 86.0), Vector3(5.0, 8.0, 38.0))
const NODES_X := [-168.0, -112.0, -56.0, 0.0, 56.0, 112.0, 168.0]
const NODES_Z := [130.0, 80.0, 30.0, -20.0, -70.0, -120.0, -170.0]
const VOICE := ["Can you hear us? Is it time?", "The prophecy is finalized.", "Our forces are prepared.", "We are ready. We seek guidance.", "We shall begin, Mother."]

var city
var sky_mat: ProceduralSkyMaterial
var rain: CPUParticles3D
var rain_bed: AudioStreamPlayer
var whisper_bed: AudioStreamPlayer
var hum: AudioStreamPlayer3D
var masked := false
var exposure := 0.0
var pressure := 0.0
var idle_t := 0.0
var drizzle := true
var weather_t := 90.0
var bolt_t := 20.0
var flash := 0.0
var halluc_t := 30.0
var voice_i := 0
var stalkers: Array = []        # {node, tgt, retarget}
var guards: Array = []          # {node, home, bridge, active}
var patrol: Array = []          # {node, a, b, t, active}
var ambassadors: Array = []     # {node, base, phase}
var phantom: Node3D
var phantom_t := -1.0
var said := {}
var serv_mat: StandardMaterial3D


func build() -> void:
	city = CK.new(self)
	rules["view_distance"] = 520.0
	rules["reverb_room"] = 0.45
	rules["reverb_wet"] = 0.12
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.006, 0.0012, 0.0012), Color(0.12, 0.018, 0.014), Color(0.02, 0.006, 0.006), Vector2(35.0, 160.0),
		Color(0.9, 0.25, 0.2), 0.04, Color(0.17, 0.032, 0.024), 0.0042)
	sky_mat = environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sun_angle_max = 0.0
	sun.shadow_enabled = false
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.14, 0.085, 0.08)
	environment.ambient_light_energy = 0.2
	environment.tonemap_exposure = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 0.85
	environment.fog_sky_affect = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	CK.materials()
	lights.setup(18, 0)
	lights.max_distance = 75.0
	var k := kit("City")
	var lit := kit("CityLit")
	city.ground(k)
	city.city(k, lit)
	city.bridges(k, lit)
	city.embassy(k, lit)
	k.commit()
	lit.commit()
	var water := WaterVolume.new()
	water.name = "Harbour"
	add_child(water)
	water.setup(Vector3(-900, -9.0, CK.QUAY - 0.6), Vector3(900, -2.6, 1400), "l113_water")
	water.fog_color = Color(0.06, 0.01, 0.01)
	water.tint = Color(0.25, 0.04, 0.03)
	water.current = Vector3(0, 0, -0.25)
	var d := Node3D.new()
	d.name = "Dressing"
	add_child(d)
	_dress(d)
	_lamps(d)
	_presences()
	_rain()
	_sounds()
	_notes()
	_exits_and_arrivals()
	add_landmark("Arrival alley (outskirts)", START)
	add_landmark("Gutted building (three bare storeys)", Vector3(-17, 0, 106))
	add_landmark("Central bridge to Level 11", Vector3(0, CK.DECK_Y, 230))
	add_landmark("West bridge", Vector3(-112, CK.DECK_Y, 230))
	add_landmark("The Embassy", CK.EMBASSY)
	add_shot("alley_arrival", START + Vector3(0.2, 1.62, 1.2), Vector3(-27.6, 14.0, 40.0), {"flashlight": false, "prepare": _prep_shot})
	add_shot("guarded_bridge", Vector3(-2.5, 1.8, 131.5), Vector3(0.5, 5.0, 235.0), {"flashlight": false, "prepare": _prep_shot})
	add_shot("avenue_to_embassy", Vector3(-4.5, 1.8, -135.0), Vector3(0.0, 22.0, -300.0), {"flashlight": false, "prepare": _prep_shot})
	add_shot("gutted_upper_floor", Vector3(-15.0, CK.BASE + 2.0 * CK.ST + 1.62, 107.5), Vector3(30.0, CK.BASE + 2.0 * CK.ST + 16.0, 83.0), {"flashlight": false, "prepare": _prep_shot})
	add_shot("outskirts_street", Vector3(-48.0, 1.7, 77.0), Vector3(20.0, 9.0, 80.0), {"flashlight": false, "prepare": _prep_shot})


# ------------------------------------------------------------------ dressing

func _dress(d: Node3D) -> void:
	var rr := RandomNumberGenerator.new()
	rr.seed = 11303
	# the arrival alley: bins, bags, aircon boxes, cables, a crate with the mask
	Props.place(self, d, "kenney/city-kit-roads/dumpster", Vector3(-28.6, 0.15, 104.0), 90.0, 1.35, true)
	Props.place(self, d, "kenney/city-kit-roads/dumpster", Vector3(-28.6, 0.15, 96.5), 84.0, 1.35, true)
	for p in [Vector3(-28.4, 0.15, 101.5), Vector3(-25.4, 0.15, 108.0), Vector3(-28.9, 0.15, 99.6), Vector3(-25.2, 0.15, 92.0)]:
		Props.place(self, d, "ph/trashbag", p, rr.randf_range(0, 360))
	for z in [100.0, 110.0, 116.0]:
		Props.place(self, d, "ph/exterior_aircon_unit", Vector3(-29.3, 3.4 + rr.randf_range(0, 3), z), 90.0)
	Props.place(self, d, "ph/modular_electric_cables", Vector3(-27.0, 6.4, 107.0), 90.0, 0.0)
	Props.place(self, d, "ph/modular_pipes", Vector3(-24.35, 0.15, 101.0), -90.0)
	Props.place(self, d, "ph/utility_box_01", Vector3(-29.2, 0.15, 112.5), 90.0, 0.0, true)
	Props.place(self, d, "ph/wooden_crate_01", Vector3(-28.7, 0.15, 116.6), 90.0, 0.0, true)
	Props.place(self, d, "ph/wooden_crate_01", Vector3(-28.7, 0.5, 116.6), 84.0)
	Props.place(self, d, "ph/security_light", Vector3(-24.2, 2.9, 118.0), 90.0)
	Props.place(self, d, "ph/water_manhole_cover", Vector3(-27.0, 0.15, 109.0), 0.0)
	# gutted shell: stripped, nothing left worth carrying
	Props.place(self, d, "ph/modular_electric_cables", Vector3(-15.0, CK.BASE + CK.ST - 0.8, 104.0), 0.0)
	Props.place(self, d, "ph/modular_electric_cables", Vector3(-13.0, CK.BASE + 2.0 * CK.ST - 0.8, 116.0), 90.0)
	Props.place(self, d, "ph/modular_industrial_pipes_01", Vector3(-23.9, CK.BASE + CK.ST, 110.0), 90.0)
	Props.place(self, d, "ph/dead_tree_trunk", Vector3(-14.0, CK.BASE + 0.02, 118.0), 30.0)
	Props.place(self, d, "ph/cardboard_box_01", Vector3(-12.0, CK.BASE + 2.0 * CK.ST, 96.0), 40.0)
	# streets: barriers, hydrants (dry), utility boxes, a few shrouded cars
	for p in [Vector3(-11.4, 0.15, 60.0), Vector3(11.4, 0.15, 12.0), Vector3(-11.4, 0.15, -44.0), Vector3(11.4, 0.15, 100.0), Vector3(-55.0, 0.15, 125.0)]:
		Props.place(self, d, "ph/fire_hydrant", p, rr.randf_range(0, 360))
	for p in [Vector3(-11.0, 0.15, 84.5), Vector3(11.0, 0.15, 35.5), Vector3(-11.0, 0.15, -15.5), Vector3(11.0, 0.15, 121.0), Vector3(-30.0, 0.15, 87.0)]:
		Props.place(self, d, "ph/utility_box_01", p, rr.randf_range(0, 360), 0.0, true)
	for e in [[Vector3(-6.5, 0, 104.0), 2.0], [Vector3(6.6, 0, 66.0), 178.0], [Vector3(-6.4, 0, 18.0), 4.0], [Vector3(-40.0, 0, 82.4), 91.0],
			[Vector3(6.5, 0, -52.0), 182.0], [Vector3(-90.0, 0, 128.0), 88.0], [Vector3(30.0, 0, 77.6), 92.0]]:
		Props.place(self, d, "ph/covered_car", e[0], e[1] + rr.randf_range(-5, 5), 0.0, true)
	for i in 5:
		Props.place(self, d, "ph/concrete_road_barrier", Vector3(-58.0 + i * 1.6, 0, 74.5), rr.randf_range(-8, 8), 0.0, true)
	for p in [Vector3(8.0, 0, 82.0), Vector3(-8.5, 0, 31.0), Vector3(9.0, 0, -18.0)]:
		Props.place(self, d, "kenney/city-kit-roads/construction-barrier", p, rr.randf_range(0, 180), 1.0)
	for p in [Vector3(-11.0, 0.15, 74.0), Vector3(11.0, 0.15, 74.0), Vector3(-11.0, 0.15, 24.0), Vector3(11.0, 0.15, -26.0)]:
		Props.place(self, d, "kenney/city-kit-roads/traffic-light", p, 0.0 if p.x < 0 else 180.0, 5.2)
	for p in [Vector3(0.0, 0, 46.0), Vector3(-30.0, 0, 80.0), Vector3(0.0, 0, -60.0), Vector3(-112.0, 0, 100.0)]:
		Props.place(self, d, "ph/water_manhole_cover", p, rr.randf_range(0, 90))
	for i in 10:
		var p := Vector3(rr.randf_range(-160, 160), 0.15, rr.randf_range(-200, 120))
		if absf(p.x) < 12.0:
			p.x += 24.0
		Props.place(self, d, "ph/trashbag", p, rr.randf_range(0, 360))
	# the quay: a lifebuoy post with no buoy, bollards, a barrier at each bridgehead
	for x in [-60.0, -30.0, 30.0, 60.0, 90.0]:
		Props.place(self, d, "ph/Barrel_01", Vector3(x, 0.15, 147.5), rr.randf_range(0, 360), 0.0, true)
	for bx in [-12.5, 12.5, -119.5, -104.5]:
		Props.place(self, d, "ph/concrete_road_barrier", Vector3(bx, 0.15, 146.0), 90.0 + rr.randf_range(-6, 6), 0.0, true)


func _lamps(d: Node3D) -> void:
	var pts: Array = []
	var z := 116.0
	while z > -215.0:
		if _on_plinth(z):
			pts.append([Vector3(11.2, 0.15, z), -90.0])
		if _on_plinth(z - 15.0):
			pts.append([Vector3(-11.2, 0.15, z - 15.0), 90.0])
		z -= 30.0
	var x := -160.0
	while x < 165.0:
		if absf(x) > 12.0 and absf(x + 112.0) > 8.0:
			pts.append([Vector3(x, 0.15, 137.2), 180.0])
		x += 26.0
	for xx in [-44.0, -16.0, 18.0, 44.0]:
		pts.append([Vector3(xx, 0.15, 87.0 if xx < 0.0 else 73.0), 180.0 if xx < 0.0 else 0.0])
	pts.append([Vector3(-10.6, 0.15, 147.6), 90.0])
	pts.append([Vector3(10.6, 0.15, 147.6), -90.0])
	for zz in [-240.0, -262.0, -284.0]:
		pts.append([Vector3(-58.0, 0.15, zz), 90.0])
		pts.append([Vector3(58.0, 0.15, zz), -90.0])
	var rr := RandomNumberGenerator.new()
	rr.seed = 11307
	var hk := kit("LampHeads")
	for p in pts:
		var pos: Vector3 = p[0]
		Props.place(self, d, "ph/street_lamp_01", pos, p[1], 6.5, false)
		var working: bool = rr.randf() < 0.72 or pos.distance_to(START) < 40.0
		if working:
			var head := pos + Vector3(0, 6.35, 0)
			hk.panel(head, 0.35, 0.35, "l113_lamp")
			lights.add_anchor(head + Vector3(0, -0.4, 0), Color(1.0, 0.24, 0.13), 3.2, 20.0, 0.04 if rr.randf() < 0.2 else 0.0)
	hk.commit()
	for l in city.lamps:
		lights.add_anchor(l[0], Color(1.0, 0.24, 0.13), 3.0, 18.0)
	lights.add_anchor(Vector3(0.0, 6.0, 152.0), Color(1.0, 0.1, 0.07), 1.6, 15.0)
	# the alley's one red security light, red spill inside the shell
	lights.add_anchor(Vector3(-25.9, 2.6, 118.0), Color(1.0, 0.12, 0.08), 0.35, 6.0, 0.08)
	for f in 3:
		lights.add_anchor(Vector3(-8.6, CK.BASE + f * CK.ST + 2.0, 104.0), Color(0.9, 0.12, 0.08), 0.6, 8.0)
		lights.add_anchor(Vector3(-8.6, CK.BASE + f * CK.ST + 2.0, 116.0), Color(0.9, 0.12, 0.08), 0.5, 7.0)
	# the Embassy floodlights
	for i in 6:
		lights.add_anchor(Vector3(-30.0 + i * 12.0, 3.0, CK.EMBASSY.z + 33.0), Color(1.0, 0.14, 0.08), 6.0, 30.0)
	lights.add_anchor(Vector3(0, 10.0, CK.EMBASSY.z + 24.0), Color(1.0, 0.2, 0.1), 4.0, 26.0)
	# two fixed floods keep the Embassy readable from far down the avenue
	for e in [[Vector3(0, 8.0, CK.EMBASSY.z + 42.0), 70.0, 7.0], [Vector3(0, 52.0, CK.EMBASSY.z + 14.0), 60.0, 5.0]]:
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.16, 0.09)
		o.omni_range = e[1]
		o.light_energy = e[2]
		o.omni_attenuation = 0.8
		o.position = e[0]
		add_child(o)


func _on_plinth(z: float) -> bool:
	for zs in CK.ZS:
		if z > float(zs[0]) + 1.5 and z < float(zs[1]) - 1.5:
			return true
	return false


func _face(n: Node3D, at: Vector3) -> void:
	var to := at - n.global_position
	to.y = 0.0
	if to.length() > 0.05:
		n.look_at(n.global_position + to, Vector3.UP)


# ---------------------------------------------------------------- presences

func _humanoid(mat: Material) -> Node3D:
	return FG.humanoid(self, mat)


func _ambassador(pos: Vector3) -> Node3D:
	var n := FG.cube()
	n.position = pos
	add_child(n)
	ambassadors.append({"node": n, "base": pos, "phase": float(ambassadors.size()) * 1.7})
	return n


func _presences() -> void:
	serv_mat = MatLib.standard(Color(0.015, 0.012, 0.014), 0.35, 0.2)
	for i in 4:
		var n := _humanoid(serv_mat)
		n.visible = false
		stalkers.append({"node": n, "tgt": Vector3.ZERO, "retarget": 0.0})
	for bd in CK.BRIDGES:
		var bx: float = bd[0]
		var hw: float = bd[1]
		for s in [-1.0, 1.0]:
			var home := Vector3(bx + s * (hw + 1.6), 0.15, 146.4)
			var g := _humanoid(serv_mat)
			g.position = home
			guards.append({"node": g, "home": home, "bx": bx, "hw": hw, "active": false})
	for i in 4:
		var n := _humanoid(serv_mat)
		var a := Vector3(-30.0 + i * 15.0, 0.15, -258.0 + (i % 2) * 6.0)
		var b := a + Vector3(10.0 if i % 2 == 0 else -10.0, 0, 0)
		n.position = a
		patrol.append({"node": n, "a": a, "b": b, "t": float(i) * 0.25, "active": false})
	_ambassador(Vector3(0.0, 7.5, 155.0))
	_ambassador(Vector3(-9.0, CK.POD + 5.0, CK.EMBASSY.z + 25.0))
	_ambassador(Vector3(10.0, CK.POD + 6.5, CK.EMBASSY.z + 27.0))
	_ambassador(Vector3(-20.0, 16.0, -236.0))
	var pm := MatLib.standard(Color(0.42, 0.36, 0.32), 0.7)
	phantom = _humanoid(pm)
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.75, 0.55)
	warm.light_energy = 1.2
	warm.omni_range = 4.0
	warm.position = Vector3(0, 2.6, 0.6)
	phantom.add_child(warm)
	phantom.visible = false


func _rain() -> void:
	rain = FG.rain()
	rain.position = START + Vector3(0, 12, 0)
	add_child(rain)


func _sounds() -> void:
	rain_bed = sound.bed("rain", {"seconds": 5.0}, -22.0)
	sound.bed("wind", {"seconds": 9.0}, -30.0)
	sound.bed("room_tone", {"seconds": 6.0, "cutoff": 150.0, "rumble": 0.4}, -30.0)
	whisper_bed = sound.bed("whisper", {"seconds": 3.2}, -70.0)
	hum = sound.emitter("transformer", CK.EMBASSY + Vector3(0, 20, 0), {"base": 41.0}, 2.0, 260.0)
	sound.emitter("pad", CK.EMBASSY + Vector3(0, 10, 20), {"root": 55.0, "chord": [0, 1, 6, 13], "bright": 0.15, "seconds": 9.0}, -6.0, 170.0)
	sound.emitter("transformer", Vector3(-29.2, 0.8, 112.5), {"base": 60.0}, -20.0, 10.0)
	for x in [-80.0, 0.0, 80.0]:
		sound.emitter("water_bed", Vector3(x, -1.5, 152.0), {"bright": 380.0}, -16.0, 45.0)
	sound.oneshot("distant_boom", {}, 35.0, 90.0, 140.0, "[something heavy shifts deep in the city]", -18.0)
	sound.oneshot("creak", {"freq": 110.0}, 25.0, 70.0, 25.0, "[steel groans somewhere overhead]", -20.0)


func _notes() -> void:
	add_note("l113_meg", "M.E.G. expedition card (laminated)", "LEVEL 11.3, 'THE RED LIGHT DISTRICT'. Sanctioned expeditions only.\n\n- The air works on the mind: vivid, frightening sights and sounds, and you will believe what you are told. Masks or any facial covering cut it down. Wear one.\n- \"There are no humans in the Red Light District.\" If you meet one, it is a deception.\n- Servants follow in groups, from afar. They wait for a dead-end alley, a building, or for you to tire. Avoid enclosed spaces. Do not rest.\n- The bridges at the outskirts run out over the water to Level 11. They are usually guarded.\n- Do not go near the domed building.", Vector3(-28.7, 0.92, 116.2), Vector3(0.45, 0.06, 0.35))
	add_note("l113_tape", "Archivist summary: recording of 09/18/2017", "Phone recovered on the Level 11 outskirts. Hours of corrupted audio, then a boy, Yusuf, landing hard. Something greets him as 'another one that comes through the Vortex'. It speaks of The Daughter, of Mother, and calls itself a prophet; the boy calls it a floating cube.\n\nIt offers him two choices: \"you can pledge loyalty, and serve, or you can try to resist and be enslaved\".\n\nA humming is audible as they walk. The boy says everything is red. The recording ends there.\n\nArchivists now suspect a nest of Ambassadors and Servants, and link it to the Level 46 tablets showing cube worship.", Vector3(-14.0, CK.BASE + 2.0 * CK.ST + 0.05, 99.0))
	add_note("l113_bridge", "Scratched into the bridge parapet", "THE WATER GOES ON FOREVER BUT THE BRIDGE GETS YOU OUT.\nTHEY STAND AT THE START OF IT.\nDON'T STOP. DON'T LET THEM TAKE YOU.", Vector3(-7.6, 1.2, 158.0), Vector3(0.3, 0.5, 0.5), false)
	add_interactable(Vector3(-28.7, 0.9, 117.1), Vector3(0.7, 0.5, 0.6), "Tie on the cloth respirator", _take_mask)
	add_interactable(Vector3(-11.0, 1.0, 84.5), Vector3(0.8, 1.4, 0.8), "Open the utility box", func():
		Overlay.subtitle("[live wires hum inside. The power works; somewhere a pump does not.]", 4.0))


func _exits_and_arrivals() -> void:
	# central bridge first (the walker bot targets the first reachable exit)
	add_exit("L011_3>L011#1", "walk_in", Vector3(0.0, CK.DECK_Y + 2.0, 262.0), Vector3(16.0, 4.0, 6.0), "")
	add_exit("L011_3>L011#1", "walk_in", Vector3(-112.0, CK.DECK_Y + 2.0, 262.0), Vector3(11.0, 4.0, 6.0), "")
	add_arrival("start", START, 0.0)
	add_arrival("from_L011", START, 0.0)


# ---------------------------------------------------------------- mechanics

func on_player_ready() -> void:
	if SaveService.item_count("facial_covering") > 0:
		masked = true
		Overlay.set_screen_effect("vignette", 0.42)
	if not SessionState.is_qa():
		Overlay.subtitle("[the air tastes of metal. Everything is red.]", 4.0)


func _take_mask() -> void:
	if masked:
		Overlay.subtitle("[the respirator is already tied tight]", 2.5)
		return
	masked = true
	SaveService.add_item("facial_covering")
	Overlay.set_screen_effect("vignette", 0.42)
	Overlay.show_note("Cloth respirator", "A painter's respirator with the filters gone, stuffed with folded cloth. It smells of someone else.\n\nYou tie it on. The red in the edges of your sight begins, slowly, to settle.")


func _prep_shot() -> void:
	drizzle = true
	rain.emitting = true
	for s in stalkers:
		(s["node"] as Node3D).visible = false
	await get_tree().process_frame


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	rain.global_position = p + Vector3(0, 12, 0)
	var inside := GUT.has_point(p + Vector3(0, 0.5, 0))
	rain.emitting = drizzle and not inside
	_ambassadors(delta)
	_weather(delta, p, inside)
	if SessionState.is_qa():
		return
	_exposure(delta, p, inside)
	_stalk(delta, p, inside)
	_guards(delta, p)
	_patrol(delta, p)


func _ambassadors(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for a in ambassadors:
		var n: Node3D = a["node"]
		n.position = a["base"] + Vector3(0, sin(t * 0.7 + a["phase"]) * 0.35, 0)
		n.rotate_y(delta * 0.3)
		n.rotate_x(delta * 0.11)


func _weather(delta: float, p: Vector3, inside: bool) -> void:
	if not SessionState.is_qa():
		weather_t -= delta
		if weather_t <= 0.0:
			drizzle = not drizzle
			weather_t = rng.randf_range(70.0, 160.0)
			Overlay.subtitle("[an icy drizzle starts]" if drizzle else "[the rain stops; the air turns close and damp]", 3.0)
		if drizzle:
			bolt_t -= delta
			if bolt_t <= 0.0:
				bolt_t = rng.randf_range(14.0, 38.0)
				_bolt(p)
	var target_fog := 0.0042 if drizzle else 0.006
	environment.fog_density = lerpf(environment.fog_density, target_fog, delta * 0.3)
	rain_bed.volume_db = lerpf(rain_bed.volume_db, (-14.0 if not inside else -24.0) if drizzle else -60.0, delta * 0.8)
	flash = maxf(0.0, flash - delta * 3.0)
	sky_mat.sky_top_color = Color(0.006, 0.0012, 0.0012).lerp(Color(0.5, 0.05, 0.05), flash)
	sky_mat.sky_horizon_color = Color(0.12, 0.018, 0.014).lerp(Color(0.9, 0.15, 0.12), flash)
	environment.ambient_light_energy = 0.2 + flash * 1.6


func _bolt(p: Vector3) -> void:
	var ang := rng.randf() * TAU
	var dist := rng.randf_range(120.0, 320.0)
	var base := Vector3(p.x + cos(ang) * dist, rng.randf_range(20.0, 70.0), p.z + sin(ang) * dist)
	var top := base + Vector3(rng.randf_range(-40, 40), 230.0, rng.randf_range(-40, 40))
	var node := Node3D.new()
	add_child(node)
	var m := MatLib.get_mat("l113_flood")
	var prev := top
	for i in 9:
		var t := float(i + 1) / 9.0
		var nxt := top.lerp(base, t) + (Vector3(rng.randf_range(-9, 9), 0, rng.randf_range(-9, 9)) if i < 8 else Vector3.ZERO)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 0.9, prev.distance_to(nxt))
		mi.mesh = bm
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mi)
		mi.look_at_from_position((prev + nxt) * 0.5, nxt, Vector3.RIGHT)
		prev = nxt
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.15, 0.1)
	fl.light_energy = 12.0
	fl.omni_range = 260.0
	fl.position = base + Vector3(0, 40, 0)
	node.add_child(fl)
	flash = 1.0
	var tw := create_tween()
	tw.tween_property(fl, "light_energy", 2.0, 0.08)
	tw.tween_property(fl, "light_energy", 9.0, 0.05)
	tw.tween_property(fl, "light_energy", 0.0, 0.3)
	tw.tween_callback(node.queue_free)
	get_tree().create_timer(dist / 343.0).timeout.connect(func():
		sound.play_at("thunder", {"seconds": 4.0, "low": 0.8}, base.lerp(p, 0.8), -6.0, "[red lightning; thunder rolls between the towers]"))


func _exposure(delta: float, p: Vector3, inside: bool) -> void:
	if masked:
		exposure = maxf(0.0, exposure - delta / 120.0)
	else:
		exposure = minf(1.0, exposure + delta / (420.0 if inside else 210.0))
	Overlay.set_screen_effect("red_tint", 0.05 + exposure * 0.32)
	Overlay.set_screen_effect("desaturate", maxf(0.0, exposure - 0.6) * 0.5)
	whisper_bed.volume_db = lerpf(-70.0, -14.0, clampf((exposure - 0.2) / 0.8, 0.0, 1.0))
	if exposure > 0.8 and rng.randf() < delta * 0.05:
		Overlay.glitch(0.25)
	# the false human: shown ahead in the street, gone when approached
	if phantom_t >= 0.0:
		phantom_t += delta
		var dd := phantom.global_position.distance_to(p)
		if dd < 22.0 or phantom_t > 7.0:
			phantom.visible = false
			phantom_t = -1.0
			if dd < 22.0 and not said.has("phantom_gone"):
				said["phantom_gone"] = true
				Overlay.subtitle("[there is no one there. There never was.]", 3.0)
		return
	halluc_t -= delta
	if halluc_t > 0.0 or exposure < 0.3:
		return
	halluc_t = rng.randf_range(22.0, 55.0) * (1.4 - exposure)
	var roll := rng.randf()
	if exposure > 0.75 and roll < 0.35:
		Overlay.subtitle("[a chorus inside the hum: \"%s\"]" % VOICE[voice_i % VOICE.size()], 4.0)
		voice_i += 1
	elif roll < 0.7 and not inside:
		var fwd := -player.global_transform.basis.z
		fwd.y = 0.0
		var at := p + fwd.normalized() * rng.randf_range(38.0, 55.0)
		at.y = 0.15
		phantom.global_position = at
		_face(phantom, p)
		phantom.visible = true
		phantom_t = 0.0
		Overlay.subtitle("[someone stands under a light ahead, waving you closer]", 3.5)
	else:
		Overlay.subtitle(["[someone calls your name from a high window]", "[a child laughs in the next street]", "[a woman says she can take you home]"][rng.randi() % 3], 3.5)


func _looked_at(pos: Vector3) -> bool:
	var cam := player.camera.global_transform
	var to := (pos + Vector3(0, 1.2, 0) - cam.origin).normalized()
	return to.dot(-cam.basis.z) > 0.72


func _stalk(delta: float, p: Vector3, inside: bool) -> void:
	var v := player.velocity
	v.y = 0.0
	idle_t = idle_t + delta if v.length() < 0.4 else 0.0
	var enclosed := inside or ALLEY.has_point(p + Vector3(0, 0.5, 0))
	var gain := (1.0 / 150.0 if enclosed else 0.0) + (1.0 / 80.0 if idle_t > 15.0 else 0.0)
	pressure = clampf(pressure + (delta * gain if gain > 0.0 else -delta / 45.0), 0.0, 1.0)
	for th in [[0.45, "[footsteps somewhere behind you stop when yours do]"], [0.75, "[figures gather at the end of the street, waiting]"], [0.9, "[they are closing in. Move.]"]]:
		if pressure >= th[0] and not said.has(th[0]):
			said[th[0]] = true
			Overlay.subtitle(th[1], 4.0)
		elif pressure < th[0] - 0.2:
			said.erase(th[0])
	var near := lerpf(34.0, 9.0, clampf((pressure - 0.4) / 0.6, 0.0, 1.0))
	for s in stalkers:
		var n: Node3D = s["node"]
		s["retarget"] -= delta
		if s["retarget"] <= 0.0:
			s["retarget"] = rng.randf_range(6.0, 11.0)
			s["tgt"] = _stalk_point(p, near)
		var tgt: Vector3 = s["tgt"]
		if tgt == Vector3.ZERO:
			n.visible = false
			continue
		if not n.visible:
			if not _looked_at(tgt):
				n.position = tgt
				n.visible = true
			continue
		var closing := pressure >= 0.9
		var goal: Vector3 = Vector3(p.x, 0.15, p.z) if closing else tgt
		if closing or not _looked_at(n.position):
			n.position = n.position.move_toward(goal, delta * (1.8 if closing else 2.4))
		_face(n, p)
		var dd := n.position.distance_to(p)
		if not closing and dd < 13.0:
			n.visible = false
			s["retarget"] = 0.0
		if (closing and dd < 1.5) or pressure >= 1.0 and dd < 6.0:
			_taken("Taken by the Servants")
			return


func _stalk_point(p: Vector3, near: float) -> Vector3:
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var best := Vector3.ZERO
	var tries := 0
	while tries < 14:
		tries += 1
		var c := Vector3(NODES_X[rng.randi() % NODES_X.size()], 0.15, NODES_Z[rng.randi() % NODES_Z.size()])
		if rng.randf() < 0.5:
			c = Vector3(p.x, 0.15, c.z) if absf(p.x - c.x) < 60.0 else Vector3(c.x, 0.15, p.z)
		var to := c - p
		to.y = 0.0
		var dd := to.length()
		if dd < near or dd > near + 30.0:
			continue
		if to.normalized().dot(fwd) > 0.3 and pressure < 0.7:
			continue
		best = c + Vector3(rng.randf_range(-3, 3), 0, rng.randf_range(-3, 3))
		break
	return best


func _guards(delta: float, p: Vector3) -> void:
	for g in guards:
		var n: Node3D = g["node"]
		var bx: float = g["bx"]
		var on_bridge := p.z > CK.QUAY - 2.0 and absf(p.x - bx) < float(g["hw"]) + 2.0
		if on_bridge and not g["active"]:
			g["active"] = true
			if not said.has("guards"):
				said["guards"] = true
				Overlay.subtitle("[the figures at the bridgehead turn, and follow you out over the water]", 4.0)
		elif p.z < 138.0 and g["active"]:
			g["active"] = false
		var goal: Vector3 = Vector3(p.x, p.y, p.z) if g["active"] else g["home"]
		n.position = n.position.move_toward(goal, delta * (3.45 if g["active"] else 2.0))
		if g["active"]:
			n.position.y = p.y
		_face(n, p)
		if g["active"] and n.position.distance_to(p) < 1.4:
			_taken("Taken on the bridge")
			return


func _patrol(delta: float, p: Vector3) -> void:
	var alarm := p.z < -226.0 and absf(p.x) < 70.0
	if p.z < -205.0 and not said.has("embassy"):
		said["embassy"] = true
		Overlay.subtitle("[a low, sadistic hum swells from the domed hall]", 4.0)
	for pt in patrol:
		var n: Node3D = pt["node"]
		if alarm:
			n.position = n.position.move_toward(Vector3(p.x, 0.15, p.z), delta * 3.0)
			if n.position.distance_to(Vector3(p.x, 0.15, p.z)) < 1.4:
				_taken("Taken at the Embassy")
				return
		else:
			pt["t"] = fmod(float(pt["t"]) + delta * 0.05, 2.0)
			var u: float = pt["t"] if pt["t"] < 1.0 else 2.0 - pt["t"]
			n.position = (pt["a"] as Vector3).lerp(pt["b"], u)
		_face(n, p if alarm else (pt["b"] if pt["t"] < 1.0 else pt["a"]))


func _taken(cause: String) -> void:
	if player.dead:
		return
	Overlay.glitch(1.0)
	Overlay.subtitle("[hands everywhere. They do not let go.]", 4.0)
	player.hurt(1000.0, cause)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var n := 0
	for t in exits:
		if t.edge_id == "L011_3>L011#1":
			n += 1
	out.append({"what": "two guarded bridges lead to Level 11", "ok": n == 2, "detail": n})
	out.append({"what": "arrival from Level 11 in the dark alley", "ok": arrivals.has("from_L011")})
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 10, 400.0), Vector3(0, -5, 400.0), 1))
	out.append({"what": "bridge deck continues far beyond the exit (no visible end)", "ok": not hit.is_empty() and absf(float(hit["position"].y) - CK.DECK_Y) < 0.1})
	var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-15.0, 9.0, 108.0), Vector3(-15.0, 6.0, 108.0), 1))
	out.append({"what": "gutted building has a walkable top floor", "ok": not up.is_empty() and absf(float(up["position"].y) - (CK.BASE + 2.0 * CK.ST)) < 0.1})
	var e0 := exposure
	masked = false
	_exposure(10.0, START, false)
	var bare := exposure - e0
	exposure = 0.5
	masked = true
	_exposure(10.0, START, false)
	var after := exposure
	masked = false
	exposure = 0.0
	phantom.visible = false
	phantom_t = -1.0
	Overlay.reset_screen_effects()
	out.append({"what": "unmasked exposure rises, the mask brings it down", "ok": bare > 0.0 and after < 0.5, "detail": [bare, after]})
	out.append({"what": "crimson lit windows across the city", "ok": city.lit_windows > 800, "detail": city.lit_windows})
	out.append({"what": "no human NPCs: only Servant and Ambassador presences", "ok": stalkers.size() == 4 and ambassadors.size() == 4})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
