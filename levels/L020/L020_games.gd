extends RefCounted
## Level 20 games in the Electric (SOURCE: "activities within rooms, which
## require physical movement to win"; win -> supplies, lose -> a hostile
## manifestation or a teleport). Four of the five documented games are built:
##   Viridis Red (common): throw foam balls at hexagons that glow green; red ones
##     take points away. Win -> a bottle of soft drink. Lose -> nothing (N/A).
##   Rock Climbing (common): climb the green glowing plastic platforms to the end
##     of the room; touching a red one loses. Win -> hot chocolate and winter
##     clothing. Lose -> the room floods with Liquid Pain.
##   Asteroid Blasters (uncommon): hit the screens showing asteroids with foam
##     balls; fewer than ten destroyed loses. Win -> space-themed bottles. Lose ->
##     teleport to Level 6 (the Wrangler outcome is not built).
##   Lasers (uncommon): dodge lasers while pressing the glowing buttons. Win -> a
##     Memory Jar with food and Almond Water. Lose -> sent to Level 7 (or 154).
## Mole Holes (rare) is not built. ADAPTATION: a game starts when you step on the
## lit start pad inside its door; aiming is where you look when you throw.

const LIQUID_PAIN_RISE := 3.0

var L: LevelBase
var props: Node3D
var E   # electric helper (rooms, doors)
var st := {}          # per game: state, t, score
var hexes: Array = []          # [{mi, z, y, state, t}]
var screens: Array = []        # [{c, rock, alive, t, vx}]
var platforms: Array = []      # [{mi, min, max, state, t}]
var beams: Array = []          # [{mi, kind, h, x, dir, speed, gap}]
var buttons: Array = []        # [{mi, pos, pressed, it}]
var balls: Array = []
var pain: WaterVolume
var ast_lost := false
var las_lost := false
var _vr_spawn := 0.0
var _as_spawn := 0.0
var _red_t := 4.0
var mats := {}


func _init(level: LevelBase, props_root: Node3D, electric) -> void:
	L = level
	props = props_root
	E = electric
	for n in ["off", "green", "red", "amber"]:
		mats[n] = MatLib.get_mat("l20_game_" + n)
	mats["rock"] = MatLib.get_mat("rock")
	for g in ["viridis", "climb", "asteroids", "lasers"]:
		st[g] = {"state": "idle", "t": 0.0, "score": 0}


func _r(name: String) -> Dictionary:
	return E.rooms[name]


func _mi(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	(parent if parent else props).add_child(mi)
	return mi


func build(k: GeoKit) -> void:
	_viridis(k)
	_asteroids(k)
	_lasers(k)
	_climb(k)


func _start_pad(k: GeoKit, c: Vector3) -> void:
	k.box(c + Vector3(0, 0.005, 0), Vector3(1.4, 0.01, 1.4), "l20_neon_amber", GeoKit.PY, false)
	k.box(c + Vector3(0, 0.006, 0), Vector3(1.2, 0.01, 1.2), "l20_black", GeoKit.PY, false)


func _sign(text: String, pos: Vector3, yaw: float, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 72
	l.pixel_size = 0.004
	l.modulate = col
	l.outline_size = 10
	l.outline_modulate = Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 0.9)
	l.position = pos
	l.rotation.y = deg_to_rad(yaw)
	props.add_child(l)


# ------------------------------------------------------------ Viridis Red

func _viridis(k: GeoKit) -> void:
	var r := _r("viridis")
	var y: float = r["floor_y"]
	var cm := CylinderMesh.new()
	cm.top_radius = 0.42
	cm.bottom_radius = 0.42
	cm.height = 0.06
	cm.radial_segments = 6
	for row in 4:
		for col in 7:
			var z := -62.0 + col * 1.0 + (0.5 if row % 2 == 1 else 0.0)
			if z > -55.6:
				continue
			var hy := y + 0.85 + row * 0.7
			var mi := _mi(cm, mats["off"], Vector3(-3.96, hy, z))
			mi.rotation = Vector3(0, 0, PI * 0.5)
			mi.rotation.x = PI / 6.0
			hexes.append({"mi": mi, "z": z, "y": hy, "state": "off", "t": 0.0})
	k.box(Vector3(-3.98, y + 1.9, -59.0), Vector3(0.04, 3.2, 7.6), "l20_black", GeoKit.PX, false)
	k.box(Vector3(2.0, y + 0.004, -59.0), Vector3(0.1, 0.01, 11.0), "l20_neon_green", GeoKit.PY, false)
	_start_pad(k, Vector3(5.6, y, -59.0))
	for zz in [-63.6, -54.4]:
		k.box(Vector3(5.2, y + 0.35, zz), Vector3(1.0, 0.7, 0.7), "l20_frame", GeoKit.ALL, true)
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		for i in 9:
			_mi(sm, MatLib.get_mat("l20_foam"), Vector3(4.85 + (i % 3) * 0.3, y + 0.74 + (i / 3) * 0.02, zz - 0.2 + (i / 3) * 0.2))
	_sign("VIRIDIS RED", Vector3(-3.9, y + 3.3, -59.0), 90.0, Color(0.3, 1.0, 0.4))
	for z2 in [-63.0, -55.0]:
		E.neon_spots.append({"pos": Vector3(0.0, y + 3.0, z2), "col": "green", "e": 0.7})


func throw_target(cam: Camera3D) -> String:
	var pp := L.player.global_position
	if _in("viridis", pp):
		return "viridis"
	if _in("asteroids", pp):
		return "asteroids"
	return ""


func _in(name: String, p: Vector3) -> bool:
	var r := _r(name)
	var mn: Vector3 = r["min"]
	var mx: Vector3 = r["max"]
	return p.x > mn.x and p.x < mx.x and p.z > mn.z and p.z < mx.z and p.y > mn.y - 0.6 and p.y < mx.y


func throw(cam: Camera3D) -> void:
	var o := cam.global_position
	var d := -cam.global_basis.z
	var game := throw_target(cam)
	var hit_p := o + d * 6.0
	var result := ""
	if game == "viridis" and d.x < -0.05:
		var t := (-3.95 - o.x) / d.x
		hit_p = o + d * t
		for h in hexes:
			if Vector2(hit_p.z - h["z"], hit_p.y - h["y"]).length() < 0.44:
				result = h["state"]
				if st["viridis"]["state"] == "play":
					if h["state"] == "green":
						st["viridis"]["score"] += 1
					elif h["state"] == "red":
						st["viridis"]["score"] = maxi(0, st["viridis"]["score"] - 1)
					h["state"] = "off"
					h["mi"].material_override = mats["off"]
				break
	elif game == "asteroids" and d.z > 0.05:
		var t2 := (-82.06 - o.z) / d.z
		hit_p = o + d * t2
		for s in screens:
			if s["alive"] and (s["rock"] as Node3D).global_position.distance_to(hit_p) < 0.6:
				s["alive"] = false
				(s["rock"] as Node3D).visible = false
				st["asteroids"]["score"] += 1
				result = "rock"
				L.sound.play_at("crackle", {"seconds": 0.4}, hit_p, -12.0, "")
				break
	_ball(o + d * 0.4 + Vector3(0, -0.15, 0), hit_p)
	if game == "viridis" and st["viridis"]["state"] == "play":
		Overlay.subtitle("[foam ball: %s]  score %d / 10" % ["hit" if result == "green" else ("minus one" if result == "red" else "miss"), st["viridis"]["score"]], 1.2)
	elif game == "asteroids" and st["asteroids"]["state"] == "play":
		Overlay.subtitle("[%s]  asteroids %d / 10" % ["the asteroid bursts" if result == "rock" else "miss", st["asteroids"]["score"]], 1.2)


func _ball(a: Vector3, b: Vector3) -> void:
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.18
	var mi := _mi(sm, MatLib.get_mat("l20_foam"), a)
	balls.append({"mi": mi, "a": a, "b": b, "t": 0.0})
	if balls.size() > 8:
		var old: Dictionary = balls.pop_front()
		(old["mi"] as Node).queue_free()


# ------------------------------------------------------------ Asteroid Blasters

func _asteroids(k: GeoKit) -> void:
	var r := _r("asteroids")
	var y: float = r["floor_y"]
	for row in 2:
		for col in 3:
			var c := Vector3(33.6 + col * 4.4, y + 1.35 + row * 1.6, -82.03)
			k.quad(c, Vector3(0, 0, -1), Vector3(1.9, 0, 0), Vector3(0, 0.68, 0), "l20_void")
			k.box(c + Vector3(0, 0.74, 0.0), Vector3(3.95, 0.08, 0.1), "l20_frame", GeoKit.ALL, false)
			k.box(c + Vector3(0, -0.74, 0.0), Vector3(3.95, 0.08, 0.1), "l20_frame", GeoKit.ALL, false)
			var sm := SphereMesh.new()
			sm.radius = 0.32
			sm.height = 0.52
			sm.radial_segments = 9
			sm.rings = 5
			var rock := _mi(sm, mats["rock"], c + Vector3(0, 0, -0.08))
			rock.visible = false
			screens.append({"c": c, "rock": rock, "alive": false, "t": 0.0, "vx": 0.0})
	k.box(Vector3(38.0, y + 0.004, -88.0), Vector3(12.0, 0.01, 0.1), "l20_neon_cyan", GeoKit.PY, false)
	_start_pad(k, Vector3(38.0, y, -93.6))
	k.box(Vector3(43.4, y + 0.35, -93.0), Vector3(1.0, 0.7, 0.7), "l20_frame", GeoKit.ALL, true)
	k.box(Vector3(32.6, y + 0.35, -93.0), Vector3(1.0, 0.7, 0.7), "l20_frame", GeoKit.ALL, true)
	_sign("ASTEROID BLASTERS", Vector3(38.0, y + 3.7, -82.1), 180.0, Color(0.4, 0.8, 1.0))
	for x in [33.0, 43.0]:
		E.neon_spots.append({"pos": Vector3(x, y + 3.4, -86.0), "col": "blue", "e": 0.6})


# ------------------------------------------------------------ Lasers

func _lasers(k: GeoKit) -> void:
	var r := _r("lasers")
	var y: float = r["floor_y"]
	var spots := [Vector3(16.0, y, -76.0), Vector3(23.5, y, -75.5), Vector3(23.5, y, -84.5), Vector3(16.5, y, -84.0)]
	for sp in spots:
		k.box(sp + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.5), "l20_frame", GeoKit.ALL, true)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.13
		cm.bottom_radius = 0.13
		cm.height = 0.06
		var mi := _mi(cm, mats["amber"], sp + Vector3(0, 1.03, 0))
		var it := L.make_interactable(sp + Vector3(0, 1.1, 0), Vector3(0.5, 0.3, 0.5), "Press the glowing button", _press.bind(buttons.size()), props)
		buttons.append({"mi": mi, "pos": sp, "pressed": false, "it": it})
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, 13.6)
	beams.append({"mi": _mi(bm, MatLib.get_mat("l20_neon_red"), Vector3(14.0, y + 0.32, -80.0)), "h": 0.32, "x": 14.0, "dir": 1.0, "speed": 1.3, "gap": -1.0})
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(0.035, 0.035, 5.6)
	var hi_a := _mi(bm2, MatLib.get_mat("l20_neon_red"), Vector3(24.0, y + 1.2, -76.1))
	var hi_b := _mi(bm2, MatLib.get_mat("l20_neon_red"), Vector3(24.0, y + 1.2, -83.9))
	beams.append({"mi": hi_a, "mi2": hi_b, "h": 1.2, "x": 24.0, "dir": -1.0, "speed": 0.9, "gap": -80.0})
	for b in beams:
		(b["mi"] as Node3D).visible = false
		if b.has("mi2"):
			(b["mi2"] as Node3D).visible = false
	for x in [12.5, 25.8]:
		for z in [-73.3, -86.7]:
			k.box(Vector3(x, y + 0.6, z), Vector3(0.18, 1.2, 0.18), "l20_frame", GeoKit.ALL, false)
	_start_pad(k, Vector3(13.6, y, -80.0))
	_sign("LASERS", Vector3(25.95, y + 3.1, -80.0), -90.0, Color(1.0, 0.25, 0.2))
	E.neon_spots.append({"pos": Vector3(19.0, y + 3.2, -80.0), "col": "red", "e": 0.6})


func _press(i: int) -> void:
	if st["lasers"]["state"] != "play":
		Overlay.subtitle("[the button is cold and does nothing; the game has not started]", 2.0)
		return
	var b: Dictionary = buttons[i]
	if b["pressed"]:
		return
	b["pressed"] = true
	(b["mi"] as MeshInstance3D).material_override = mats["green"]
	var n := 0
	for bb in buttons:
		if bb["pressed"]:
			n += 1
	Overlay.subtitle("[click: button %d of 4]" % n, 1.5)
	if n == 4:
		_end("lasers", true)


# ------------------------------------------------------------ Rock Climbing

func _climb(k: GeoKit) -> void:
	var r := _r("climb")
	var y: float = r["floor_y"]
	var pts: Array = []
	for i in 7:
		pts.append(Vector3(29.4, y + 0.5 + i * 0.55, -103.2 - i * 1.7))
	for i in 5:
		pts.append(Vector3(27.5 - i * 1.7, y + 0.5 + (7 + i) * 0.55, -114.6))
	for i in pts.size():
		var c: Vector3 = pts[i]
		var bm := BoxMesh.new()
		bm.size = Vector3(1.15, 0.22, 1.15)
		var mi := _mi(bm, mats["green"], c)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = bm.size
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
		# a bracket into the padded wall
		var nearest_wall := Vector3(30.9, c.y - 0.2, c.z) if i < 7 else Vector3(c.x, c.y - 0.2, -115.9)
		k.box((c + nearest_wall) * 0.5 - Vector3(0, 0.2, 0), (nearest_wall - c).abs() + Vector3(0.12, 0.12, 0.12), "l20_frame", GeoKit.ALL, false)
		platforms.append({"mi": mi, "c": c, "state": "green", "t": 0.0})
	# the end of the room: a ledge across the west end with a rail
	var top: float = y + 0.5 + 11 * 0.55 + 0.11
	k.box_mm(Vector3(17.0, top - 0.3, -116.0), Vector3(19.8, top, -108.0), "l20_frame")
	k.box(Vector3(19.75, top + 0.5, -112.0), Vector3(0.06, 0.06, 8.0), "l20_steel", GeoKit.ALL, false)
	k.box(Vector3(19.75, top + 0.5, -112.0), Vector3(0.05, 1.0, 0.05), "l20_steel", GeoKit.ALL, true)
	k.box(Vector3(18.4, top + 0.005, -108.05), Vector3(2.8, 0.01, 0.08), "l20_neon_green", GeoKit.PY, false)
	E.rooms["climb"]["ledge_top"] = top
	_start_pad(k, Vector3(24.0, y, -102.2))
	_sign("ROCK CLIMBING", Vector3(24.0, y + 8.6, -115.95), 0.0, Color(0.3, 1.0, 0.45))
	for c2 in [Vector3(21.0, y + 8.6, -105.0), Vector3(27.5, y + 8.6, -110.0), Vector3(19.0, y + 7.6, -113.5)]:
		E.neon_spots.append({"pos": c2, "col": "green", "e": 0.9})
	for c3 in [Vector3(24.0, y + 2.6, -104.0), Vector3(27.0, y + 3.4, -112.0), Vector3(22.0, y + 3.0, -110.0)]:
		E.neon_spots.append({"pos": c3, "col": "dim", "e": 1.4})
	# floodlights on the ceiling and a grid of guide strips on the padded walls
	for x in [20.0, 24.0, 28.0]:
		k.box(Vector3(x, y + 9.97, -108.0), Vector3(0.3, 0.05, 6.0), "l20_neon_dim", GeoKit.NY, false)
	for i in 4:
		k.box(Vector3(30.97, y + 1.5 + i * 2.0, -108.0), Vector3(0.04, 0.04, 15.0), "l20_game_off", GeoKit.ALL, false)
		k.box(Vector3(24.0, y + 1.5 + i * 2.0, -115.97), Vector3(13.8, 0.04, 0.04), "l20_game_off", GeoKit.ALL, false)
	var lp := MatLib.water({"shallow_color": Color(0.85, 0.12, 0.05), "deep_color": Color(0.35, 0.02, 0.01), "absorption": 2.5,
		"clarity": 0.15, "wave_height": 0.02, "wave_scale": 3.0, "foam_amount": 0.4, "dark_surface": 0.2})
	MatLib.register("l20_liquid_pain", lp)


# ------------------------------------------------------------ state

func process(delta: float, pp: Vector3) -> void:
	for b in balls:
		b["t"] += delta
		var t: float = minf(b["t"] / 0.35, 1.0)
		var p: Vector3 = (b["a"] as Vector3).lerp(b["b"], t) + Vector3(0, sin(t * PI) * 0.25, 0)
		if b["t"] > 0.35:
			p = (b["b"] as Vector3) + Vector3(0, -minf((b["t"] - 0.35) * 2.5, 1.2), 0)
		(b["mi"] as Node3D).global_position = p
	_check_pads(pp)
	_vr(delta)
	_as(delta)
	_la(delta, pp)
	_cl(delta, pp)


func _check_pads(pp: Vector3) -> void:
	var pads := {"viridis": Vector3(5.6, 0, -59.0), "asteroids": Vector3(38.0, 0, -93.6), "lasers": Vector3(13.6, 0, -80.0), "climb": Vector3(24.0, 0, -102.2)}
	for g in pads.keys():
		var c: Vector3 = pads[g]
		if st[g]["state"] == "idle" and Vector2(pp.x - c.x, pp.z - c.z).length() < 0.7 and absf(pp.y - float(_r(g)["floor_y"])) < 0.4:
			_begin(g)


func _begin(g: String) -> void:
	st[g]["state"] = "play"
	st[g]["t"] = 0.0
	st[g]["score"] = 0
	L.sound.play_at("chiptune", {"bpm": 200.0, "root": 523.0, "scale": [0, 4, 7, 12], "seconds": 1.2}, L.player.global_position, -10.0, "")
	var msg := {"viridis": "[a chime; the hexagons wake. Hit the green ones, ten points, one minute]",
		"asteroids": "[a chime; the screens fill with space. Ten asteroids before it ends]",
		"lasers": "[a chime; red beams sweep the floor. Press all four glowing buttons]",
		"climb": "[a chime; reach the end of the room on the green platforms. Never touch a red one]"}
	Overlay.subtitle(msg[g], 4.0)
	if g == "lasers":
		for b in beams:
			(b["mi"] as Node3D).visible = true
			if b.has("mi2"):
				(b["mi2"] as Node3D).visible = true


func _end(g: String, won: bool) -> void:
	st[g]["state"] = "won" if won else "lost"
	L.call("on_game_end", g, won)


func _vr(delta: float) -> void:
	var s: Dictionary = st["viridis"]
	if s["state"] != "play":
		return
	s["t"] += delta
	_vr_spawn -= delta
	for h in hexes:
		if h["state"] != "off":
			h["t"] -= delta
			if h["t"] <= 0.0:
				h["state"] = "off"
				h["mi"].material_override = mats["off"]
	if _vr_spawn <= 0.0:
		_vr_spawn = 1.1
		var h2: Dictionary = hexes[L.rng.randi() % hexes.size()]
		var red: bool = s["t"] > 18.0 and L.rng.randf() < 0.35
		h2["state"] = "red" if red else "green"
		h2["t"] = 2.4
		h2["mi"].material_override = mats[h2["state"]]
	if s["score"] >= 10:
		_end("viridis", true)
	elif s["t"] > 60.0:
		s["state"] = "idle"
		for h in hexes:
			h["state"] = "off"
			h["mi"].material_override = mats["off"]
		Overlay.subtitle("[the hexagons go dark. Nothing else happens. The pad is lit again]", 3.0)


func _as(delta: float) -> void:
	var s: Dictionary = st["asteroids"]
	if s["state"] != "play":
		return
	s["t"] += delta
	_as_spawn -= delta
	for sc in screens:
		if sc["alive"]:
			sc["t"] -= delta
			(sc["rock"] as Node3D).position.x += sc["vx"] * delta
			(sc["rock"] as Node3D).rotate_y(delta * 1.3)
			if sc["t"] <= 0.0:
				sc["alive"] = false
				(sc["rock"] as Node3D).visible = false
	if _as_spawn <= 0.0 and s["t"] < 72.0:
		_as_spawn = 2.5
		var free: Array = screens.filter(func(x): return not x["alive"])
		if not free.is_empty():
			var sc2: Dictionary = free[L.rng.randi() % free.size()]
			sc2["alive"] = true
			sc2["t"] = 3.2
			sc2["vx"] = L.rng.randf_range(-0.5, 0.5)
			var rock := sc2["rock"] as Node3D
			rock.position = (sc2["c"] as Vector3) + Vector3(-sc2["vx"] * 1.6, L.rng.randf_range(-0.3, 0.3), -0.1)
			rock.visible = true
	if s["score"] >= 10:
		_end("asteroids", true)
	elif s["t"] > 75.0:
		ast_lost = true
		_end("asteroids", false)


func _la(delta: float, pp: Vector3) -> void:
	var s: Dictionary = st["lasers"]
	if s["state"] != "play":
		return
	s["t"] += delta
	var y: float = _r("lasers")["floor_y"]
	for b in beams:
		b["x"] += b["dir"] * b["speed"] * delta
		if b["x"] > 25.2 or b["x"] < 13.2:
			b["dir"] *= -1.0
		(b["mi"] as Node3D).position.x = b["x"]
		if b.has("mi2"):
			b["gap"] = -80.0 + sin(s["t"] * 0.5) * 3.0
			var ga: float = b["gap"] + 1.2
			var gb: float = b["gap"] - 1.2
			var ma := b["mi"] as Node3D
			ma.position = Vector3(b["x"], y + b["h"], (ga - 73.0) * 0.5)
			ma.scale.z = maxf(0.05, (-73.0 - ga) / 5.6)
			var mb := b["mi2"] as Node3D
			mb.position = Vector3(b["x"], y + b["h"], (gb - 87.0) * 0.5)
			mb.scale.z = maxf(0.05, (gb + 87.0) / 5.6)
		# hit test against the player's body
		var feet := pp.y
		var body_h := 1.0 if L.player.crouching else 1.7
		var by: float = y + b["h"]
		if feet < by + 0.02 and feet + body_h > by and absf(pp.x - b["x"]) < 0.32:
			var in_gap: bool = b.has("mi2") and absf(pp.z - b["gap"]) < 1.2
			if not in_gap and pp.z < -73.0 and pp.z > -87.0:
				las_lost = true
				Overlay.subtitle("[the beam touches you. The room goes white]", 2.0)
				_end("lasers", false)
				return


func _cl(delta: float, pp: Vector3) -> void:
	var s: Dictionary = st["climb"]
	if pain and s["state"] == "lost":
		var y0: float = _r("climb")["floor_y"]
		pain.surface_y = minf(pain.surface_y + delta * LIQUID_PAIN_RISE / 40.0, y0 + LIQUID_PAIN_RISE)
		pain.surface_mesh.position.y = pain.surface_y
		if pain.contains(pp + Vector3(0, 0.1, 0)):
			L.player.hurt(delta * 3.0, "Liquid Pain")
	if s["state"] != "play":
		return
	s["t"] += delta
	_red_t -= delta
	if _red_t <= 0.0:
		_red_t = L.rng.randf_range(4.0, 7.0)
		var i := 1 + L.rng.randi() % (platforms.size() - 2)
		platforms[i]["state"] = "amber"
		platforms[i]["t"] = 1.3
		platforms[i]["mi"].material_override = mats["amber"]
	for pl in platforms:
		if pl["state"] == "amber" or pl["state"] == "red":
			pl["t"] -= delta
			if pl["t"] <= 0.0:
				if pl["state"] == "amber":
					pl["state"] = "red"
					pl["t"] = 3.0
				else:
					pl["state"] = "green"
				pl["mi"].material_override = mats[pl["state"]]
		var c: Vector3 = pl["c"]
		if pl["state"] == "red" and absf(pp.x - c.x) < 0.7 and absf(pp.z - c.z) < 0.7 and absf(pp.y - (c.y + 0.11)) < 0.2:
			_lose_climb()
			return
	var top: float = _r("climb")["ledge_top"]
	if pp.x < 19.8 and pp.z < -108.0 and absf(pp.y - top) < 0.3:
		_end("climb", true)


func _lose_climb() -> void:
	var r := _r("climb")
	var y0: float = r["floor_y"]
	for pl in platforms:
		pl["state"] = "red"
		pl["mi"].material_override = mats["red"]
	pain = WaterVolume.new()
	pain.name = "LiquidPain"
	L.add_child(pain)
	pain.setup(Vector3(17.0, y0 - 0.2, -116.0), Vector3(31.0, y0 + 0.02, -100.3), "l20_liquid_pain", true)
	pain.fog_color = Color(0.4, 0.03, 0.01)
	pain.tint = Color(0.8, 0.15, 0.05)
	pain.fog_density = 0.5
	L.sound.emitter("water_bed", Vector3(24.0, y0 + 0.5, -108.0), {"bright": 300.0}, -12.0, 16.0)
	Overlay.subtitle("[a red platform. Something thick and red starts welling up from the floor]", 3.5)
	_end("climb", false)
