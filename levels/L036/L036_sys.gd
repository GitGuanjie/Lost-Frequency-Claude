extends Node
## Level 36 systems: the unitless flight countdown shared by every screen, the
## boarding window that opens gate C31, PA announcements, luggage riding the
## active carousels (rerouted to Lost and Found after 10 rounds), the belts and
## the one-way travelator carrying you, Concourse M's seam, afterimages, and the
## hot/cold concourse.

const S := preload("res://levels/L036/L036_strip.gd")
const C := preload("res://levels/L036/L036_core.gd")
const RATE := 7.0            # countdown units per second (unitless by design)
const OURS := "C31"

var lvl
var flights: Array = []      # {num, gate, cd, delay}
var units := 0.0
var bags: Array = []         # {node, x, s, rounds}
var rerouted := 0
var ghosts: Array = []
var told := {}
var _scr_t := 0.0
var _pa_t := 30.0
var _r := RandomNumberGenerator.new()
var boarding_was := false
var departed := 0


func setup(level, seed_value: int) -> void:
	lvl = level
	_r.seed = seed_value
	flights.append({"num": "1784XBA8JLP", "gate": "C32", "cd": 94612753.0, "delay": 0.0})
	flights.append({"num": flight_number(), "gate": OURS, "cd": 990.0 if SessionState.is_qa() else 1240.0, "delay": 0.0})
	for i in 9:
		flights.append({"num": flight_number(), "gate": gate_name(), "cd": _r.randf_range(60.0, 420000.0), "delay": 0.0})


func flight_number() -> String:
	var a := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var s := "%04d" % _r.randi_range(1000, 9999)
	for i in 3:
		s += a[_r.randi() % 26]
	s += str(_r.randi() % 10)
	for i in 3:
		s += a[_r.randi() % 26]
	return s


func gate_name() -> String:
	var g := "%s%d" % [String.chr(65 + _r.randi() % 26), _r.randi_range(1, 900)]
	return "D%d" % _r.randi_range(1, 99) if g.begins_with("C3") else g


func ours() -> Dictionary:
	for f in flights:
		if f["gate"] == OURS:
			return f
	return {}


func boarding() -> bool:
	var f := ours()
	return not f.is_empty() and f["cd"] > 0.0 and f["cd"] <= 1000.0


func status(f: Dictionary) -> String:
	if f["delay"] > 0.0:
		return "DELAYED"
	if f["cd"] <= 1000.0:
		return "BOARDING"
	return "ON TIME" if f["cd"] < 8000.0 else "SCHEDULED"


func board_text(rows: int) -> String:
	var list := flights.duplicate()
	list.sort_custom(func(a, b): return a["cd"] < b["cd"])
	var out := "TIME        FLIGHT        GATE   STATUS\n"
	var shown := 0
	for f in list:
		if f["gate"] == "C32":
			continue
		if shown >= rows:
			break
		out += "%-10d  %s  %-5s  %s\n" % [int(f["cd"]), f["num"], f["gate"], status(f)]
		shown += 1
	out += "   ...\n"
	var c32: Dictionary = list.filter(func(x): return x["gate"] == "C32")[0]
	out += "%-10d  %s  %-5s  %s" % [int(c32["cd"]), c32["num"], c32["gate"], status(c32)]
	return out


## Advance the shared countdown; departures vanish, new flights take their place.
func tick(delta: float) -> void:
	units += delta * RATE
	for f in flights:
		if f["delay"] > 0.0:
			f["delay"] = maxf(0.0, f["delay"] - delta)
			continue
		f["cd"] -= delta * RATE
	var keep: Array = []
	for f in flights:
		if f["cd"] > 0.0:
			keep.append(f)
			continue
		departed += 1
		if f["gate"] == OURS:
			keep.append({"num": flight_number(), "gate": OURS, "cd": _r.randf_range(2400.0, 4200.0), "delay": 0.0})
			pa("Flight %s has departed. Gate C31 is now closed." % f["num"])
		else:
			keep.append({"num": flight_number(), "gate": gate_name(), "cd": _r.randf_range(3000.0, 600000.0), "delay": 0.0})
	flights = keep
	var b := boarding()
	if b and not boarding_was:
		pa("Attention all passengers, flight %s is now boarding at gate C31." % ours()["num"])
	boarding_was = b


func pa(text: String) -> void:
	if lvl == null or lvl.player == null or SessionState.is_qa():
		return
	lvl.sound.play_at("music_box", {"notes": [7, 4, 0], "root": 523.0}, lvl.player.global_position + Vector3(0, 3, 0), -12.0)
	Overlay.subtitle("[PA, a monotone, androgynous voice] " + text, 6.0)


func random_pa() -> void:
	var list := flights.filter(func(f): return f["gate"] != "C32" and f["gate"] != OURS)
	if list.is_empty():
		return
	var f: Dictionary = list[_r.randi() % list.size()]
	match _r.randi() % 4:
		0:
			f["delay"] = _r.randf_range(15.0, 40.0)
			pa("Flight %s is delayed." % f["num"])
		1:
			f["gate"] = gate_name()
			pa("Flight %s has changed gate. Please proceed to gate %s." % [f["num"], f["gate"]])
		2:
			pa("Flight %s, gate %s: %d." % [f["num"], f["gate"], int(f["cd"])])
		3:
			pa("Attention all passengers, flight QAHF13Y7479 is now boarding at gate L67.")


# ------------------------------------------------------------------ luggage

func spawn_bags(parent: Node3D) -> void:
	var mats := ["l36_bag_a", "l36_bag_b", "l36_bag_c", "l36_bag_d", "l36_bag_e"]
	for i in S.ACTIVE:
		var xc := float(i) * 16.0 + 8.0
		var n := 3 + absi(hash([i, "bags"])) % 3
		for j in n:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(_r.randf_range(0.42, 0.55), _r.randf_range(0.22, 0.3), _r.randf_range(0.6, 0.75))
			mi.mesh = bm
			mi.material_override = MatLib.get_mat(mats[_r.randi() % mats.size()])
			parent.add_child(mi)
			var s := S.path_length() * float(j) / float(n) + _r.randf() * 2.0
			bags.append({"node": mi, "x": xc, "s": s, "rounds": _r.randi_range(0, 7), "h": bm.size.y})


func bags_step(delta: float) -> void:
	var total := S.path_length()
	var gone: Array = []
	for b in bags:
		var s0: float = b["s"]
		b["s"] = s0 + delta * 0.5
		if floor(b["s"] / total) > floor(s0 / total):
			b["rounds"] += 1
			if b["rounds"] >= 10:
				gone.append(b)
				continue
		var p := S.path_point(b["x"], b["s"])
		var p2 := S.path_point(b["x"], b["s"] + 0.2)
		var n: MeshInstance3D = b["node"]
		n.position = p + Vector3(0, b["h"] * 0.5, 0)
		var dv := p2 - p
		if dv.length() > 0.01:
			n.rotation.y = atan2(dv.x, dv.z)
	for b in gone:
		(b["node"] as Node).queue_free()
		bags.erase(b)
		rerouted += 1
		if is_instance_valid(lvl.core.laf_label):
			lvl.core.laf_label.text = "REROUTED: %d" % rerouted


# ------------------------------------------------------------------ the rest

func make_ghosts(parent: Node3D) -> void:
	for p in [Vector3(0.6, 0, -104.0), Vector3(9.0, 0, -146.0), Vector3(-4.5, 0, -32.0), Vector3(-26.0, 0, -76.0)]:
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.24
		cm.height = 1.72
		mi.mesh = cm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(0.55, 0.58, 0.62, 0.0)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = p + Vector3(0, 0.86, 0)
		parent.add_child(mi)
		ghosts.append(mi)


## Belts and the travelator carry you; the seam in Concourse M returns you.
func carry(delta: float) -> void:
	var p: Player = lvl.player
	if p == null:
		return
	var pp := p.global_position
	var t := C.TRAV
	if pp.y < 0.5 and t.has_point(Vector2(pp.x, pp.z)):
		p.global_position.z -= 1.3 * delta
	if pp.y > 0.1 and pp.y < 0.7 and pp.z < S.RUN_Z0 and pp.z > S.RUN_Z1:
		var rm := (S.R_IN + S.R_OUT) * 0.5
		var i := int(floor((pp.x - 8.0 + 8.0) / 16.0))
		for j in [i - 1, i, i + 1]:
			if not S.ACTIVE.has(j):
				continue
			var xc := float(j) * 16.0 + 8.0
			if absf(pp.x - (xc + rm)) < 0.55:
				p.global_position.z -= 0.5 * delta
			elif absf(pp.x - (xc - rm)) < 0.55:
				p.global_position.z += 0.5 * delta
	if pp.x > C.LOOP_SEAM and absf(pp.z - C.LOOP_Z) < 3.0:
		p.global_position.x -= C.LOOP_PERIOD
		if not told.has("loop"):
			told["loop"] = true
			if not SessionState.is_qa():
				Overlay.subtitle("[the same bench, the same sign: CONCOURSE M, ahead. You have walked this stretch before.]", 4.5)


func ambience(delta: float) -> void:
	var p: Player = lvl.player
	if p == null:
		return
	var pp := p.global_position
	for g in ghosts:
		var dist := (g as Node3D).global_position.distance_to(pp)
		var a := clampf((dist - 10.0) / 18.0, 0.0, 1.0) * clampf((60.0 - dist) / 20.0, 0.0, 1.0) * 0.16
		((g as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.a = a
	if SessionState.is_qa():
		return
	if absf(pp.x) < 6.0:
		if pp.z < -46.0 and pp.z > -66.0 and not told.has("cold"):
			told["cold"] = true
			Overlay.subtitle("[the air turns cold, a chilling cold]", 3.0)
		elif pp.z < -66.0 and pp.z > -72.0 and not told.has("both"):
			told["both"] = true
			Overlay.subtitle("[hot and cold at the same time: two concourses overlapping]", 3.5)
		elif pp.z < -72.0 and pp.z > -90.0 and not told.has("warm"):
			told["warm"] = true
			Overlay.subtitle("[stuffy, close warmth]", 3.0)
	if pp.z < -112.0 and not told.has("chat"):
		told["chat"] = true
		Overlay.subtitle("[from somewhere past gate C32: the sound of people talking, friendly, unhurried]", 4.5)
	_pa_t -= delta
	if _pa_t <= 0.0:
		_pa_t = _r.randf_range(45.0, 90.0)
		random_pa()


func _process(delta: float) -> void:
	if lvl == null:
		return
	tick(delta)
	bags_step(delta)
	carry(delta)
	ambience(delta)
	_scr_t -= delta
	if _scr_t <= 0.0:
		_scr_t = 0.5
		lvl.refresh_screens()
