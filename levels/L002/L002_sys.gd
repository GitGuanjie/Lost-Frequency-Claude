extends Node
## Level 2 runtime systems and door/exit planning.
## SOURCE: series-wired lights (one break kills a 3x3..6x6 block), brownout parts
## with violet emergency lights, most doors locked, coloured/material doors as
## exits, void rooms (infinite, lightless, soundless; only the doorway lit),
## unreasonably hot areas as Level 127 noclip hotspots, chalky walls that mark
## clothes in tight corridors, Smilers drawn to darkness, rotting-meat smell from
## burst pipes, whirring machines that do nothing together.

const G := preload("res://levels/L002/L002_geo.gd")
const P := preload("res://levels/L002/L002_props.gd")
const DY := 4.2
const QA := preload("res://levels/L002/L002_qa.gd")

var lvl
var circ_off: Dictionary = {}
var _trip_t := 90.0
var _dark_t := 0.0
var _smiler: Node3D = null
var _smiler_cd := 30.0
var heat := 0.0
var _hot_said := false
var _tight_said := 0.0
var _bruise_t := 0.0
var _smell_t := 0.0
var in_void := false
var _void_node: Node3D = null
var _void_at := Vector3.ZERO
var _void_ret: Transform3D
var _void_lost := 0.0
var _beds: Array = []
var _env_saved := {}

const EXITS := {"sign": "L002>L001#1", "plywood": "L002>L031#2", "aged_wood": "L002>L137#3", "tall70": "L002>L070#4",
	"rainbow": "L002>L283#5", "l101": "L002>L101#6", "piano": "L002>L126#7", "metal": "L002>L141#8", "blue": "L002>L175#9",
	"pink": "L002>L997#10", "blade": "L002>L811#11", "broken_knob": "L002>L916#12", "elevator": "L002>L998#13",
	"house": "L002>L064#17", "boiler": "L002>L127#18", "long": "L002>L158#19", "dugout": "L002>L902#20"}
const PROMPTS := {"sign": "Open the door with the chalked sign", "plywood": "Open the plywood door", "aged_wood": "Open the old wooden door",
	"tall70": "Push the tall engraved door", "rainbow": "Push the tall painted door", "l101": "Try the door", "piano": "Open the door (piano behind it)",
	"metal": "Open the metal door and step in", "blue": "Open the blue door", "pink": "Open the pink door", "blade": "Pull the blade from the door",
	"broken_knob": "Push the wooden doors (the knob is broken)", "elevator": "Press the call button and step in"}
const WEIGHTS := [["steel_white", 18.0], ["steel_grey", 18.0], ["steel_cream", 14.0], ["void_window", 8.0], ["void_open", 2.5],
	["sign", 4.0], ["plywood", 2.5], ["aged_wood", 2.5], ["tall70", 1.2], ["rainbow", 1.2], ["l101", 2.5], ["piano", 1.4],
	["metal", 2.0], ["blue", 2.5], ["pink", 2.5], ["elevator", 3.0], ["broken_knob", 1.5]]


func setup(level) -> void:
	lvl = level


func circuit_on(cid: String) -> bool:
	return not circ_off.has(cid)


## One break kills the whole series circuit (fixtures and their real lights).
func trip(cid: String, caption: bool = true) -> int:
	if circ_off.has(cid):
		return 0
	circ_off[cid] = true
	var dead: Material = MatLib.get_mat("l2_tube_dead")
	var n := 0
	var arr: Array = lvl.circ_meshes.get(cid, [])
	for mi in arr:
		if is_instance_valid(mi):
			(mi as MeshInstance3D).material_override = dead
			n += 1
	for a in lvl.lights.anchors:
		if a.get("cid", "") == cid:
			a["energy"] = 0.0
	if caption:
		Overlay.subtitle("[a tube pops; the whole run of lights dies with it]", 3.5)
		if lvl.player:
			lvl.sound.play_at("crackle", {"seconds": 0.6}, lvl.player.global_position + Vector3.UP * 2.0, -8.0)
	return n


# ------------------------------------------------------------------ planning

func _kind(r: RandomNumberGenerator, allow_exit: bool) -> String:
	var tot := 0.0
	for w in WEIGHTS:
		tot += float(w[1])
	var x := r.randf() * tot
	var pick := "steel_grey"
	for w in WEIGHTS:
		x -= float(w[1])
		if x <= 0.0:
			pick = w[0]
			break
	if pick == "broken_knob" and (lvl.player == null or lvl.player.stats["distance"] < 700.0):
		pick = "aged_wood"   # "after wandering a significant amount of time"
	if EXITS.has(pick) and not allow_exit:
		return "steel_cream"
	return pick


func _dims(kind: String, deck: String, h: Dictionary) -> Vector2:
	var clear: float = (float(h["hl"]) if h["mode"] == "lo" else DY - 0.3) if deck == "lo" else 2.8
	match kind:
		"elevator": return Vector2(1.5, 2.2)
		"tall70", "rainbow": return Vector2(1.3, clear - 0.03)
		"dugout": return Vector2(0.95, 1.9)
	return Vector2(0.95, 2.1)


func plan_chunk(cx: int, cz: int, C: Vector3, a: float, halves: Array, r: RandomNumberGenerator) -> Dictionary:
	var allow: bool = not lvl.qa_fixture
	var td: Array = [[], [], [], [], [], [], [], []]
	var fds: Array = []
	var plan := {"tube_doors": td, "face_doors": fds, "up_face_doors": [], "violet_dir": 0, "room": {}, "long": -1, "blade": -1}
	var kind: String = lvl.node_kind(cx, cz)
	var has_up := false
	for d in 8:
		if halves[d]["mode"] in ["up", "stack"]:
			has_up = true
		if halves[d]["mode"] == "":
			plan["violet_dir"] = d
	if cx == 0 and cz == 0:   # authored arrival vestibule
		td[0].append({"kind": "blue", "r": 7.6, "s": 1.0, "deck": "lo", "w": 0.95, "h": 2.1})
		fds.append({"dir": 3, "kind": "sign", "deck": "lo", "w": 0.95, "h": 2.1})
		return plan
	if cx == 2 and cz == 0:   # authored elevator landing off the gallery catwalk
		fds.append({"dir": 5, "kind": "elevator", "deck": "up", "w": 1.6, "h": 2.2})
		plan["up_face_doors"].append(5)
		return plan
	var far := maxi(absi(cx), absi(cz))
	# a room behind an unlocked door, in a quadrant beside an axis corridor
	if kind == "small" and r.randf() < 0.4:
		var d: int = [0, 2, 4, 6][r.randi() % 4]
		var h: Dictionary = halves[d]
		var s := 1.0 if r.randf() < 0.5 else -1.0
		var out := P.frame(G.dvec(d)).x * s
		var qd := -1
		for kk: int in [1, 3, 5, 7]:
			if G.dvec(kk).dot((G.dvec(d) + out).normalized()) > 0.99:
				qd = kk
		if h["mode"] in ["lo", "stack"] and qd >= 0 and halves[qd]["mode"] == "":
			var rk := r.randf()
			var rkind := "bare" if rk < 0.42 else ("pcs" if rk < 0.64 else ("house" if rk < 0.84 else "dugout"))
			if not allow and rkind in ["house", "dugout"]:
				rkind = "bare"
			var dm := _dims("dugout" if rkind == "dugout" else "room", "lo", h)
			td[d].append({"kind": "room", "room": rkind, "r": a + 3.0, "s": s, "deck": "lo", "w": dm.x, "h": dm.y})
	# doors along the corridors
	for d in 8:
		var h: Dictionary = halves[d]
		if not (h["mode"] in ["lo", "stack", "up"]):
			continue
		var n := 0
		var x := r.randf()
		if x > 0.45:
			n = 1 if x < 0.85 else 2
		var used: Array = []
		for dr in td[d]:
			used.append(float(dr["r"]))
		for i in n:
			var rr := r.randf_range(a + 1.3, float(h["len"]) - 1.1)
			var ok := true
			for u in used:
				if absf(rr - float(u)) < 2.2:
					ok = false
			if not ok:
				continue
			used.append(rr)
			var deck := "lo" if h["mode"] == "lo" else ("up" if h["mode"] == "up" else ("lo" if r.randf() < 0.6 else "up"))
			var dk := _kind(r, allow)
			var dm := _dims(dk, deck, h)
			td[d].append({"kind": dk, "r": rr, "s": 1.0 if r.randf() < 0.5 else -1.0, "deck": deck, "w": dm.x, "h": dm.y})
	# doors on closed junction faces
	if kind != "gallery":
		for d in 8:
			if halves[d]["mode"] != "" or d == plan["violet_dir"]:
				continue
			if r.randf() < 0.24:
				var dk := _kind(r, allow)
				var dm := _dims(dk, "lo", {"mode": "lo", "hl": 3.0})
				fds.append({"dir": d, "kind": dk, "deck": "lo", "w": dm.x, "h": minf(dm.y, 2.8)})
			elif has_up and r.randf() < 0.18:
				var dk2 := _kind(r, allow)
				fds.append({"dir": d, "kind": dk2, "deck": "up", "w": 0.95, "h": 2.1 if dk2 != "elevator" else 2.2})
	if allow:
		# Macchina blade door at the end of a run of blue-pulsing pipe lights
		if r.randf() < 0.06:
			for d: int in [0, 2, 4, 6]:
				if halves[d]["mode"] == "lo" and td[d].is_empty():
					td[d].append({"kind": "blade", "r": float(halves[d]["len"]) - 1.4, "s": 1.0, "deck": "lo", "w": 0.95, "h": 2.1})
					plan["blade"] = d
					break
		if far >= 7:   # "by traversing the halls for long enough"
			for d: int in [0, 2, 4, 6]:
				if halves[d]["mode"] in ["lo", "stack"]:
					plan["long"] = d
					break
	return plan


# --------------------------------------------------------------- dressing

func dress_tube(ctx: Dictionary, C: Vector3, d: int, a: float, h: Dictionary, doors: Array) -> void:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	var md: String = h["mode"]
	if md == "stair" or md == "":
		return
	var dv := G.dvec(d)
	var side := P.frame(dv).x
	var w: float = h["w"]
	var r1: float = h["len"]
	var so := 1.0 if r.randf() < 0.5 else -1.0   # the side that takes floor-standing kit
	var decks: Array = []
	if md != "up":
		decks.append(["lo", 0.0, float(h["hl"]) if md == "lo" else DY - 0.3])
	if md != "lo":
		decks.append(["up", DY, 2.8])
	for dk in decks:
		var y0: float = dk[1]
		var clear: float = dk[2]
		var busy: Array = []
		for dr in doors:
			if dr["deck"] == dk[0]:
				busy.append([float(dr["r"]), float(dr["s"])])
		var free := func(rr: float, s: float, span: float) -> bool:
			for b in busy:
				if float(b[1]) == s and absf(float(b[0]) - rr) < span:
					return false
			return true
		var base := C + Vector3.UP * y0
		if w >= 1.6 and not h["tram"]:
			var rr := a + 0.9
			while rr < r1 - 0.8:
				var span := r.randf_range(0.9, 2.0)
				if r.randf() < 0.45 and free.call(rr + span * 0.5, so, span * 0.5 + 0.7):
					var foot := base + dv * (rr + span * 0.5) + side * (so * w * 0.5)
					P.machine(k, foot, side * -so, dv, minf(0.58, w - 1.08), minf(clear - 0.05, 2.6), r.randi() % 5, r)
					rr += span + 0.4
				else:
					rr += 1.2
		elif w >= 1.6 and h["tram"] and dk[0] == "lo":
			pass
		var lat := so * (w * 0.5 - 0.36)
		if w >= 2.0 and r.randf() < 0.3:
			var rr2 := r.randf_range(a + 1.2, r1 - 1.0)
			if free.call(rr2, so, 1.2):
				P.trolley(k, base + dv * rr2 + side * lat, dv, r)
		elif w >= 1.7 and r.randf() < 0.3:
			var rr3 := r.randf_range(a + 0.8, r1 - 0.6)
			if free.call(rr3, so, 1.0):
				P.drum(k, base + dv * rr3 + side * lat, r, true)
		for i in r.randi() % 3:
			var rr4 := r.randf_range(a + 0.5, r1 - 0.4)
			P.small_clutter(k, base + dv * rr4 + side * (-so * (w * 0.5 - 0.3)), dv, r)
	# burst pipe: a dark sludge puddle under a split pipe, with the smell
	if md != "up" and r.randf() < 0.09:
		var rr5 := r.randf_range(a + 1.0, r1 - 0.5)
		var pc := C + dv * rr5
		for i in 3:
			P.disk(k, pc + Vector3(r.randf_range(-0.3, 0.3), 0.006 + i * 0.001, r.randf_range(-0.3, 0.3)), Vector3.UP, r.randf_range(0.3, 0.6), "l2_sludge", 12)
		if not ctx["meta"].has("smell"):
			ctx["meta"]["smell"] = []
		ctx["meta"]["smell"].append(pc)
	# blue pulsing lights along a pipe, leading to the blade door
	for dr in doors:
		if dr["kind"] == "blade":
			var s: float = dr["s"]
			var y := 2.35
			var p0 := C + dv * a + side * (s * (w * 0.5 - 0.12)) + Vector3.UP * y
			var p1 := C + dv * (float(dr["r"]) - 0.7) + side * (s * (w * 0.5 - 0.12)) + Vector3.UP * y
			P.pipe(k, p0, p1, 0.06, "l2_steel", 8)
			var t := 0.4
			while t < p0.distance_to(p1):
				P.pipe(k, p0 + dv * t, p0 + dv * (t + 0.12), 0.068, "l2_bluepulse", 8)
				t += 1.1
	# exposed wiring hanging from a fixture: tugging it breaks the series circuit
	if md != "up" and a < 5.5 and r1 > 6.0 and r.randf() < 0.14:
		var fp := C + dv * 5.5 + Vector3.UP * ((float(h["hl"]) if md == "lo" else DY - 0.25) - 0.15)
		for i in 4:
			P.pipe(k, fp + Vector3(0, -i * 0.3, 0) + side * (0.05 * (i % 2)), fp + Vector3(0, -(i + 1) * 0.3, 0) + side * (0.05 * ((i + 1) % 2)), 0.012, "l2_copper", 4)
		var cid: String = lvl.circuit_of(fp + Vector3.UP * 0.1, 0)
		_inter(ctx["node"], fp + Vector3.DOWN * 0.8, Vector3(0.4, 1.0, 0.4), "Tug the exposed wiring", func(_p): trip(cid))


func _inter(node: Node3D, center: Vector3, size: Vector3, prompt: String, cb: Callable) -> Interactable:
	var it := Interactable.new()
	node.add_child(it)
	it.setup(center, size, prompt, cb)
	return it


func build_doors(ctx: Dictionary, C: Vector3, a: float, halves: Array, plan: Dictionary) -> void:
	var k: GeoKit = ctx["k"]
	var node: Node3D = ctx["node"]
	var r: RandomNumberGenerator = ctx["r"]
	var entries: Array = []
	for d in 8:
		var h: Dictionary = halves[d]
		var dv := G.dvec(d)
		var side := P.frame(dv).x
		for dr in plan["tube_doors"][d]:
			var s: float = dr["s"]
			var y: float = DY if dr["deck"] == "up" else 0.0
			entries.append([dr, C + dv * float(dr["r"]) + side * (s * float(h["w"]) * 0.5) + Vector3.UP * y, side * -s, h])
	for fd in plan["face_doors"]:
		var n := G.dvec(int(fd["dir"]))
		entries.append([fd, C + n * a + Vector3.UP * (DY if fd["deck"] == "up" else 0.0), -n, {}])
	ctx["meta"]["doors"] = entries.size()
	for e in entries:
		var dr: Dictionary = e[0]
		var c: Vector3 = e[1]
		var out: Vector3 = e[2]
		var kind: String = dr["kind"]
		if kind == "room":
			var along := Vector3.UP.cross(out).normalized()
			var rk: String = dr["room"]
			var inside := G.side_room(lvl, ctx, c, -out, along, 5.0 if rk != "dugout" else 5.5, 3.6, rk)
			if rk != "dugout":
				P.obox(k, c - out * 0.6 + along * 0.42 + Vector3.UP * 1.05, out.rotated(Vector3.UP, 1.35), Vector3(0.9, 2.05, 0.05), "l2_door_cream")
			if rk == "house":
				lvl.make_exit(EXITS["house"], "walk_in", inside + Vector3.UP * 1.1, Vector3(2.4, 2.2, 2.0), "", node)
			elif rk == "dugout":
				lvl.make_exit(EXITS["dugout"], "walk_in", c - out * 4.8 + Vector3.UP * 1.0, Vector3(1.2, 2.0, 1.2), "", node)
			continue
		var leaf := P.door(k, lvl, c, out, float(dr["w"]), float(dr["h"]), kind, r)
		if EXITS.has(kind):
			var t: ExitTrigger = lvl.make_exit(EXITS[kind], "interact", c + out * 0.55 + Vector3.UP * 1.0, Vector3(1.2, 2.0, 1.1), PROMPTS.get(kind, "Open the door"), node)
			if t and kind in ["piano", "blade"]:
				var cid: String = lvl.circuit_of(c + Vector3.UP * 2.0, 1 if c.y > 2.0 else 0)
				t.condition = func() -> bool: return circuit_on(cid)
			if kind == "piano":
				var pl := AudioStreamPlayer3D.new()
				pl.stream = AudioSynth.get_stream("music_box", {"notes": [0, 4, 7, 12, 7, 4, 2, 5], "root": 196.0})
				pl.volume_db = -14.0
				pl.max_distance = 10.0
				pl.bus = "Ambience"
				pl.position = c - out * 0.6 + Vector3.UP * 1.2
				pl.autoplay = true
				node.add_child(pl)
			continue
		match kind:
			"void_open":
				_inter(node, leaf, Vector3(float(dr["w"]), float(dr["h"]), 0.2), "Open the door (black window)", func(_p): enter_void(c, out))
				P.obox(k, leaf + out * 0.04 + Vector3.UP * 0.45, out, Vector3(0.3, 0.44, 0.004), "void_black")
			"void_window":
				_inter(node, leaf, Vector3(float(dr["w"]), float(dr["h"]), 0.2), "Try the door", func(_p): Overlay.toast("Locked. Through the little window there is nothing at all.", 3.0))
			_:
				var msg: String = ["Locked.", "Locked. The handle does not even turn.", "Locked tight.", "It rattles in the frame but holds. Locked."][r.randi() % 4]
				_inter(node, leaf, Vector3(float(dr["w"]), float(dr["h"]), 0.2), "Try the door", func(_p): Overlay.toast(msg, 2.0))
	if plan["long"] >= 0:
		var h2: Dictionary = halves[plan["long"]]
		var dv2 := G.dvec(plan["long"])
		var t2: ExitTrigger = lvl.make_exit(EXITS["long"], "condition", C + dv2 * ((a + float(h2["len"])) * 0.5) + Vector3.UP * 1.2, Vector3(2.0, 2.4, 2.0), "", node)
		if t2:
			t2.condition = func() -> bool: return lvl.player != null and lvl.player.stats["distance"] > 1500.0
	if lvl.node_kind(int(floor(C.x / 20.0)), int(floor(C.z / 20.0))) == "boiler" and not lvl.qa_fixture:
		var t3: ExitTrigger = lvl.make_exit(EXITS["boiler"], "noclip", C + Vector3.UP * 1.1, Vector3(3.3, 2.2, 3.3), "Press against the scorching boiler", node)
		if t3:
			t3.hold_seconds = 2.0
			var cid2: String = lvl.circuit_of(C + Vector3.UP * 2.0, 0)
			t3.condition = func() -> bool: return heat > 0.7 and circuit_on(cid2)
		var hum := AudioStreamPlayer3D.new()
		hum.stream = AudioSynth.get_stream("transformer", {"base": 38.0})
		hum.volume_db = -6.0
		hum.max_distance = 16.0
		hum.bus = "Ambience"
		hum.position = C + Vector3.UP * 1.3
		hum.autoplay = true
		node.add_child(hum)


## Authored arrival vestibule: the tram buffer, signposts, dials, the chalk note.
func dress_start(ctx: Dictionary, C: Vector3, a: float) -> void:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	G.rails(k, C + Vector3(-a - 0.2, 0, 0), C + Vector3(-1.6, 0, 0))
	P.obox(k, C + Vector3(-1.6, 0.55, 0), Vector3(1, 0, 0), Vector3(1.2, 0.18, 0.25), "l2_rail_yellow", true)
	for s: float in [-0.45, 0.45]:
		P.obox(k, C + Vector3(-1.75, 0.35, s), Vector3(1, 0, 0), Vector3(0.12, 0.7, 0.4), "l2_machine_dark")
	# derailed flatbed wagon left in the tram tunnel, cable drum still aboard
	var wc := C + Vector3(-7.4, 0.42, 0.55)
	P.obox(k, wc, Vector3(1, 0, 0).rotated(Vector3.UP, 0.06), Vector3(0.95, 0.12, 2.3), "l2_machine", true)
	for sx: float in [-0.8, 0.8]:
		P.obox(k, wc + Vector3(sx, -0.25, 0), Vector3(1, 0, 0), Vector3(0.12, 0.3, 0.8), "l2_machine_dark")
	k.cylinder(wc + Vector3(0.2, 0.42, 0), 0.38, 0.6, "l2_woodbox", 12, false)
	var sb := C + Vector3(-a - 1.0, 1.75, -1.24)
	P.obox(k, sb, Vector3(0, 0, 1), Vector3(1.5, 0.5, 0.03), "l2_sign")
	var lb := Label3D.new()
	lb.text = "<-  OFFICE SPACE EL3A\nB.N.T.G. TRAMWAY - NO SERVICE"
	lb.font_size = 40
	lb.pixel_size = 0.0028
	lb.modulate = Color(0.12, 0.12, 0.12)
	lb.outline_size = 0
	lb.position = sb + Vector3(0, 0, 0.02)
	k.root.add_child(lb)
	# pipes-and-dials wall (the arrival from Level 1 keeps its gauges)
	var n7 := G.dvec(7)
	var f7 := C + n7 * (a - 0.02)
	var t7 := Vector3.UP.cross(-n7).normalized()
	for i in 5:
		P.dial(k, f7 + t7 * (-0.9 + i * 0.45) + Vector3.UP * (1.3 + 0.25 * (i % 2)), -n7, 0.11)
	P.valve(k, f7 + Vector3.UP * 0.9, -n7)
	for i in 4:
		P.pipe(k, f7 + t7 * (-1.4 + i * 0.9) - n7 * 0.15, f7 + t7 * (-1.4 + i * 0.9) - n7 * 0.15 + Vector3.UP * 3.0, 0.07 + 0.03 * i, ["l2_pipe_rust", "l2_pipe_green", "l2_steel", "l2_insul"][i], 9)
	var n1 := G.dvec(1)
	P.machine(k, C + n1 * a, -n1, Vector3.UP.cross(-n1).normalized(), 0.55, 2.4, 0, r)
	P.trolley(k, C + n1 * (a - 1.5) + Vector3(-0.8, 0, 0.6), Vector3(0, 0, 1).rotated(Vector3.UP, 0.5), r)
	var n5 := G.dvec(5)
	P.chalk_sign(k, C + n5 * (a - 0.02) + Vector3.UP * 1.9, -n5, "1 = SIGNS\nBLACK WINDOW = NO\nLIGHTS DIE IN BLOCKS")
	P.small_clutter(k, C + n5 * (a - 0.7) + Vector3(0.6, 0, -0.3), Vector3(1, 0, 0), r)
	var n3 := G.dvec(3)
	for i in 3:
		P.pipe(k, C + n3 * (a - 0.1) + Vector3.UP.cross(n3) * (0.9 + i * 0.12) + Vector3.UP * 2.4, C + n3 * (a - 0.1) + Vector3.UP.cross(n3) * (0.9 + i * 0.12) + Vector3.UP * 3.0, 0.03, "l2_cord", 4)
	lvl.fixture(ctx, C + Vector3(-2.2, 2.85, 0.0), Vector3(1, 0, 0), 0, 0.0)
	lvl.fixture(ctx, C + Vector3(2.4, 2.85, 0.0), Vector3(1, 0, 0), 0, 0.0)


# ------------------------------------------------------------------ runtime

func beds() -> void:
	_beds.append(lvl.sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.55}, -17.0))
	_beds.append(lvl.sound.bed("room_tone", {"cutoff": 180.0, "rumble": 0.7}, -18.0))
	_beds.append(lvl.sound.bed("transformer", {"base": 47.0}, -25.0))
	lvl.sound.oneshot("pipe_clank", {"f": 140.0}, 14.0, 40.0, 10.0, "[a pipe knocks somewhere in the walls]", -14.0)
	lvl.sound.oneshot("creak", {"freq": 90.0}, 30.0, 80.0, 10.0, "[a machine whirs, stutters, whirs]", -16.0)
	lvl.sound.oneshot("scratch", {}, 70.0, 180.0, 6.0, "[concrete grinds somewhere inside the wall]", -16.0)
	lvl.sound.oneshot("knock", {"hits": 2}, 90.0, 220.0, 9.0, "[something heavy shifts just around a corner]", -15.0)


func on_ready() -> void:
	if SessionState.is_story() and not SaveService.flag("L002", "arrived", false):
		SaveService.set_flag("L002", "arrived", true)
		Overlay.subtitle("[buzzing tubes] [machines whirring, going nowhere] [warm, chalky air]", 5.0)
	if lvl.qa_fixture:
		lvl.qa_routes.append({"edge": EXITS["elevator"], "note": "authored elevator doors off the gallery catwalk (chunk 2,0), up the gallery stair"})


func _meta_here() -> Dictionary:
	return lvl.world.meta_of(lvl.world.key_at(lvl.player.global_position))


func tick(delta: float) -> void:
	var p: Player = lvl.player
	if in_void:
		_void_tick(delta)
		return
	var pos := p.global_position
	var deck := 1 if pos.y > DY - 1.0 else 0
	var cid: String = lvl.circuit_of(pos + Vector3.UP * 1.0, deck)
	var dark: bool = not circuit_on(cid) or lvl.circuit_base(cid) == "brown"
	# --- series circuits: something, somewhere, breaks a light now and then
	if not lvl.qa_fixture:
		_trip_t -= delta
		if _trip_t <= 0.0:
			_trip_t = randf_range(80.0, 200.0)
			if randf() < 0.6 and circuit_on(cid) and lvl.circuit_base(cid) != "brown":
				trip(cid)
	# --- Smilers: drawn to the dark; they close in while you stay in it
	_smiler_cd = maxf(0.0, _smiler_cd - delta)
	_dark_t = _dark_t + delta if dark else 0.0
	if not lvl.qa_fixture:
		_smiler_tick(delta, dark)
	# --- heat near boilers
	var best := 99.0
	for key in lvl.world.chunks.keys():
		for hc in lvl.world.chunks[key]["meta"].get("heat", []):
			best = minf(best, Vector2(pos.x - hc.x, pos.z - hc.z).length() + absf(pos.y - hc.y) * 2.0)
	heat = lerpf(heat, clampf(1.0 - (best - 1.6) / 7.0, 0.0, 1.0), clampf(delta * 1.5, 0.0, 1.0))
	Overlay.set_screen_effect("red_tint", heat * 0.14)
	if heat > 0.6 and not _hot_said:
		_hot_said = true
		Overlay.subtitle("[the air here is unreasonably hot; it wavers]", 3.5)
	elif heat < 0.2:
		_hot_said = false
	# --- chalky walls: tight corridors smear dust on you, and bruise if you run
	var tight := false
	for seg in _meta_here().get("tight", []):
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var ap := Vector2(pos.x - a.x, pos.z - a.z)
		var t := clampf(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (ap - ab * t).length() < 0.9 and pos.y < 3.5:
			tight = true
	_tight_said = maxf(0.0, _tight_said - delta)
	p.walk_speed = lvl.rules["walk_speed"] * (0.8 if tight else 1.0)
	p.sprint_speed = lvl.rules["sprint_speed"] * (0.75 if tight else 1.0)
	if tight and _tight_said <= 0.0 and p.velocity.length() > 0.5:
		_tight_said = 45.0
		Overlay.subtitle("[your shoulders scrape the walls; chalky dust smears your sleeves]", 3.0)
	_bruise_t = maxf(0.0, _bruise_t - delta)
	if tight and p.velocity.length() > 4.0 and _bruise_t <= 0.0:
		_bruise_t = 3.0
		p.hurt(2.0, "Scraped raw against the walls")
	# --- burst pipes
	_smell_t = maxf(0.0, _smell_t - delta)
	for sp in _meta_here().get("smell", []):
		if _smell_t <= 0.0 and pos.distance_to(sp) < 4.0:
			_smell_t = 60.0
			Overlay.subtitle("[a thick smell, like rotting meat, from a split pipe]", 3.5)


func _smiler_tick(delta: float, dark: bool) -> void:
	var p: Player = lvl.player
	if _smiler == null and dark and _dark_t > 14.0 and _smiler_cd <= 0.0:
		var fw := -p.global_transform.basis.z
		fw.y = 0.0
		fw = fw.normalized()
		var from := p.global_position + Vector3.UP * 1.5
		var hit: Dictionary = lvl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + fw * 16.0, 1))
		var dist := 16.0 if hit.is_empty() else from.distance_to(hit["position"]) - 0.8
		if dist > 6.0:
			_smiler = _make_smiler()
			lvl.add_child(_smiler)
			_smiler.global_position = from + fw * dist + Vector3.UP * 0.2
			Overlay.subtitle("[in the dark ahead, a wide white grin]", 3.0)
	if _smiler == null:
		return
	var to := p.global_position + Vector3.UP * 1.6 - _smiler.global_position
	_smiler.look_at(p.global_position + Vector3.UP * 1.6, Vector3.UP)
	if dark:
		_smiler.global_position += to.normalized() * 1.15 * delta
		if to.length() < 1.6 and not p.dead:
			p.hurt(1000.0, "A Smiler found you in the dark")
	if not dark or to.length() > 30.0:
		_smiler.queue_free()
		_smiler = null
		_smiler_cd = 40.0


func _make_smiler() -> Node3D:
	var n := Node3D.new()
	n.name = "Smiler"
	var k := GeoKit.new(n, "Face")
	for s: float in [-0.16, 0.16]:
		k.quad(Vector3(s, 0.1, 0), Vector3(0, 0, -1), Vector3(0.05, 0, 0), Vector3(0, 0.03, 0), "l2_doorway_glow")
	for i in 9:
		var x := -0.3 + i * 0.075
		k.quad(Vector3(x, -0.12 + 0.002 * (i - 4) * (i - 4), 0), Vector3(0, 0, -1), Vector3(0.03, 0, 0), Vector3(0, 0.045, 0), "l2_doorway_glow")
	k.shadows = false
	k.commit()
	return n


# ------------------------------------------------------------------- void

## Stepping through an unlocked void door: an infinite, lightless, soundless
## floor; the doorway is the only light and the only way back.
func enter_void(door_c: Vector3, out: Vector3) -> void:
	var p: Player = lvl.player
	if in_void or p == null:
		return
	_void_ret = Transform3D(Basis(Vector3.UP, atan2(-out.x, -out.z) + PI), door_c + out * 0.8 + Vector3.UP * 0.05)
	_void_at = Vector3(door_c.x, -300.0, door_c.z)
	if _void_node == null:
		_void_node = G.void_arena(lvl, Vector3.ZERO)
		_inter(_void_node, Vector3(0, 1.1, 0), Vector3(1.2, 2.2, 0.5), "Step back through the doorway", func(_p): leave_void())
	_void_node.position = _void_at
	_void_node.visible = true
	in_void = true
	_void_lost = 0.0
	_env_saved = {"amb": lvl.environment.ambient_light_energy, "fog": lvl.environment.fog_density}
	lvl.environment.ambient_light_energy = 0.0
	lvl.environment.fog_density = 0.12
	for b in _beds:
		(b as AudioStreamPlayer).volume_db -= 60.0
	p.flashlight.visible = false
	p.flashlight_policy = "none"
	p.global_position = _void_at + Vector3(0, 0.05, -1.4)
	p.rotation.y = 0.0
	Overlay.subtitle("[silence]", 3.0)


func leave_void() -> void:
	if not in_void:
		return
	in_void = false
	lvl.environment.ambient_light_energy = _env_saved.get("amb", 0.045)
	lvl.environment.fog_density = _env_saved.get("fog", 0.05)
	for b in _beds:
		(b as AudioStreamPlayer).volume_db += 60.0
	lvl.player.flashlight_policy = lvl.rules["flashlight"]
	lvl.player.global_position = _void_ret.origin
	lvl.player.rotation.y = _void_ret.basis.get_euler().y


func _void_tick(delta: float) -> void:
	var p: Player = lvl.player
	var d := Vector2(p.global_position.x - _void_at.x, p.global_position.z - _void_at.z).length()
	var l: OmniLight3D = _void_node.get_meta("light")
	l.light_energy = lerpf(1.2, 0.0, clampf((d - 18.0) / 20.0, 0.0, 1.0))
	if d > 40.0:
		_void_lost += delta
		if _void_lost > 30.0 and not p.dead:
			p.hurt(1000.0, "Lost in a void room; the doorway never came back into view")
	else:
		_void_lost = 0.0


# ---------------------------------------------------------------------- QA

func capture_plan() -> Array:
	return QA.capture_plan(lvl)


func self_test() -> Array:
	return await QA.self_test(lvl, self)
