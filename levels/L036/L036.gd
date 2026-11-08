extends LevelBase
const VerticalArchitecture := preload("res://core/world/VerticalArchitecture.gd")
## Level 36 — Timeless Airport. Canon: docs/canon/levels/L036.md.
## 26 distinct A-Z terminals, checked-luggage carousels, dormant check-in
## counters, units-only flight clock and contradictory navigational signs.
## This is an IN_DEVELOPMENT authored slice, NOT a claim of an infinite airport.

const H := 8.4
const TERMINALS := 26
const GATE_SPACING := 15.0

var gate: ExitTrigger
var flight_display: Label3D
var countdown := 1020
var _unit_timer := 0.0
var _arrivals_count := 0
var _terminal_signs: Array = []


func build() -> void:
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.75
	rules["reverb_wet"] = 0.16
	rules["flashlight"] = "none"
	indoor_env(Color(0.79, 0.84, 0.88), 0.29, Color(0.42, 0.44, 0.48), 0.001)
	environment.tonemap_exposure = 1.15
	_materials()
	lights.setup(18, 1)
	_baggage_and_checkin()
	VerticalArchitecture.install(self, "AirportOverlook", Vector3(0, 0, -35), 4, 3.45, "l36_metal", "l36_wall", true)
	add_landmark("Four-storey baggage overlook", Vector3(0, 10.35, -35))
	_concourse()
	_gate()
	if SessionState.is_qa():
		# Isolated fixture begins during a legitimate boarding window.
		countdown = 995
	add_arrival("start", Vector3(0, 0.08, -76), 0.0)
	add_arrival("from_L011", Vector3(0, 0.08, -76), 0.0)
	add_arrival("from_L009", Vector3(0, 0.08, -76), 0.0)  # sourced L009 airport transfer
	add_landmark("Conveyor-belt baggage claim", Vector3(0, 0.2, -75))
	add_landmark("Unstaffed check-in hall", Vector3(0, 0.5, 2))
	add_landmark("Terminal A-Z concourse", Vector3(0, 0.5, 65))
	add_landmark("Gate to the unbuilt Airplane", Vector3(39, 0.5, 78))
	add_shot("airport_arrival", Vector3(5, 1.62, -70), Vector3(0, 1.3, -20))
	add_shot("terminal_disorientation", Vector3(8, 1.62, 38), Vector3(36, 2.2, 90))
	sound.bed("fluorescent_hum", {"seconds": 4.0, "base": 60.0, "rasp": 0.12}, -35.0)
	sound.bed("room_tone", {"seconds": 5.0, "cutoff": 250.0}, -25.0)
	# No hostile inhabitants; the article explicitly classifies hostile entity risk 0.


func _materials() -> void:
	MatLib.define("l36_tile", {"albedo_a": Color(0.54, 0.60, 0.64), "albedo_b": Color(0.61, 0.64, 0.67), "noise_scale": 3.0, "roughness_a": 0.36}, "tile")
	MatLib.define("l36_ceiling", {"albedo_a": Color(0.70, 0.73, 0.74), "albedo_b": Color(0.62, 0.65, 0.65)}, "plaster")
	MatLib.define("l36_wall", {"albedo_a": Color(0.45, 0.49, 0.51), "albedo_b": Color(0.55, 0.58, 0.59), "roughness_a": 0.80}, "concrete")
	MatLib.define("l36_metal", {"albedo_a": Color(0.36, 0.37, 0.40), "albedo_b": Color(0.46, 0.48, 0.5), "metallic_value": 0.83}, "metal")
	MatLib.define("l36_belt", {"albedo_a": Color(0.10, 0.13, 0.15), "albedo_b": Color(0.18, 0.20, 0.23), "roughness_a": 0.82}, "rubber")
	MatLib.define("l36_glass", {"albedo_a": Color(0.13, 0.18, 0.23), "albedo_b": Color(0.18, 0.23, 0.27), "metallic_value": 0.25}, "glass")
	MatLib.register("l36_screen", MatLib.panel(Color(0.23, 0.69, 0.82), 1.45))
	MatLib.register("l36_light", MatLib.panel(Color(0.94, 0.94, 0.89), 1.2))


func _label(text: String, p: Vector3, sz: float = 0.8, tint: Color = Color(0.72, 0.88, 0.92)) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 30
	l.pixel_size = 0.01 * sz
	l.modulate = tint
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.position = p
	add_child(l)
	return l


func _baggage_and_checkin() -> void:
	var k := kit("BaggageClaimAndCheckIn")
	k.slab(-36, -100, 36, 36, 0, 0.4, "l36_tile")
	# Center baggage observation shaft; ceiling strips retain the rest.
	k.slab(-36,-101,-8.8,35,H+0.6,0.6,"l36_ceiling")
	k.slab(8.8,-101,36,35,H+0.6,0.6,"l36_ceiling")
	k.slab(-8.8,-101,8.8,-51,H+0.6,0.6,"l36_ceiling")
	k.slab(-8.8,-19,8.8,35,H+0.6,0.6,"l36_ceiling")
	# One bounded wall at luggage-claim, and open extension toward terminals.
	k.box(Vector3(0, H * 0.5, -101), Vector3(72, H, 0.5), "l36_wall")
	for x in [-35.8, 35.8]:
		k.box(Vector3(x, 4.0, -33), Vector3(0.42, H, 136), "l36_wall")
	for i in 8:
		var x := -24.0 + float(i % 4) * 16.0
		var z := -82.0 + float(i / 4) * 21.0
		# Disconnected, oblong baggage belts: no crates are player items.
		k.box(Vector3(x, 0.47, z), Vector3(11, 0.86, 4.5), "l36_metal")
		k.box(Vector3(x, 0.92, z), Vector3(10.2, 0.09, 3.7), "l36_belt", GeoKit.ALL, false)
		for b in 6:
			if (b + i) % 3 != 0:
				continue
			k.box(Vector3(x - 4 + float(b) * 1.45, 1.14, z), Vector3(0.75, 0.42, 0.45), "l36_metal", GeoKit.ALL, false)
		_label("BELT %d" % (9 + i * 19), Vector3(x, 2.9, z + 4.6), 0.78)
	for i in 18:
		var x := -29.0 + float(i % 9) * 7.2
		var z := -6.0 + float(i / 9) * 12.0
		k.box(Vector3(x, 0.54, z), Vector3(5.0, 1.08, 1.9), "l36_metal")
		k.box(Vector3(x, 1.18, z - 0.56), Vector3(1.35, 0.64, 0.14), "l36_screen", GeoKit.ALL, false)
	for i in 20:
		var x := -31.0 + float(i % 10) * 7.0
		var z := -91.0 + float(i / 10) * 92.0
		k.box(Vector3(x, H + 0.02, z), Vector3(2.4, 0.08, 3.6), "l36_light", GeoKit.NY, false)
		if i % 3 == 1:
			lights.add_anchor(Vector3(x, H - 0.28, z), Color(0.86, 0.95, 1), 0.7, 15.0, 0.75, "l36_coldpanel")
	k.commit()
	_label("BAGGAGE CLAIM  /  CHECK-IN", Vector3(0, 5.7, -22), 1.2)
	_label("FLIGHTS: BOARDING UNKNOWN | TIMES UNRELIABLE", Vector3(0, 5.3, 21), 0.8)


func _concourse() -> void:
	var k := kit("AtoZGateConcourse")
	k.slab(-40, 36, 47, 240, 0, 0.4, "l36_tile")
	k.box(Vector3(3.5, H + 0.3, 138), Vector3(87, 0.6, 204), "l36_ceiling")
	for side in [-40.0, 47.0]:
		k.box(Vector3(side, H * 0.5, 138), Vector3(0.35, H, 204), "l36_wall")
	# Two banks of 13 terminals, each with an independent gate alcove.
	for i in TERMINALS:
		var bank := -1.0 if i < 13 else 1.0
		var row := i if i < 13 else i - 13
		var z := 47.0 + float(row) * GATE_SPACING
		var x := -25.0 if bank < 0.0 else 32.0
		var alpha := String.chr(65 + i)
		k.box(Vector3(x, 0.52, z), Vector3(11.5, 1.04, 5.8), "l36_tile")
		k.box(Vector3(x, 4.0, z + 3.1), Vector3(11.5, 8.0, 0.24), "l36_glass", GeoKit.ALL, false)
		k.box(Vector3(x, 4.7, z), Vector3(4.0, 0.1, 0.38), "l36_screen", GeoKit.ALL, false)
		k.box(Vector3(x, 1.15, z), Vector3(1.6, 2.2, 0.10), "l36_metal")
		_terminal_signs.append(_label("TERMINAL %s  |  GATE %03d" % [alpha, row + 1], Vector3(x, 5.7, z), 0.55))
		if i % 3 == 0:
			lights.add_anchor(Vector3(x, 7.25, z), Color(0.89, 0.91, 1), 0.65, 10.0, 0.7, "l36_gate")
	# Contradictory, in-universe sign maze: signs are deliberately NOT exits.
	for i in 7:
		var z := 50.0 + float(i) * 25.0
		k.box(Vector3(0.0, 7.3, z), Vector3(7.5, 0.85, 0.13), "l36_metal", GeoKit.ALL, false)
		_label("A-C  ←   /  →  X-Z    [FOLLOW LATEST]", Vector3(0, 6.7, z + 0.3), 0.65)
	k.commit()


func _gate() -> void:
	# A boarding gate leads only to Sublevel 36.1 (not yet built here).
	# No fake direct arrival at the airport's unknown flight destination.
	gate = add_exit("L036>L036_1#1", "interact", Vector3(32, 1.3, 77), Vector3(3.0, 2.6, 2.2), "Board flight to the Airplane (36.1)")
	gate.condition = func(): return countdown <= 1000 and countdown > 0
	flight_display = _label("GATE 36.1  BOARDING IN --", Vector3(25.5, 5.2, 77), 0.7)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[the announcements have no recognizable time scale]", 5.0)


func level_process(delta: float) -> void:
	if SessionState.is_qa():
		return
	_unit_timer += delta
	if _unit_timer > 0.25:
		_unit_timer = 0.0
		countdown -= 1
		if countdown <= 0:
			countdown = 1600
	if flight_display != null:
		flight_display.text = "GATE 36.1  %d  %s" % [countdown, "BOARDING" if countdown <= 1000 else "CLOSED"]


func qa_self_test() -> Array:
	return [
		{"ok": _terminal_signs.size() == TERMINALS, "what": "all 26 terminal bank labels authored"},
		{"ok": gate != null, "what": "single sourced boarding gate to the unbuilt Airplane"},
		{"ok": arrivals.has("from_L011"), "what": "arrival from documented city connection"},
		{"ok": flight_display != null, "what": "unitless boarding clock display available"},
	]
