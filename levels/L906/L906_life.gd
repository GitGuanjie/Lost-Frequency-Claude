extends RefCounted
## Level 906 living systems.
##  - Receding ceiling (SOURCE: "the closer one gets, the farther it seems to be"):
##    the stained-glass and painted ceiling sits about 44 m over your eyes and moves
##    away faster than you climb (2.4 m per metre of height gained).
##  - Books, folders, scrolls and notes spawn in and clip out (SOURCE), every one
##    carrying Blanche's signature; they can be read, traced, or (rudely) torn.
##  - Light Guides (SOURCE: float through the level, flicker, vanish spontaneously,
##    move in seemingly random patterns). Their look is not described on this page:
##    shown as small drifting lights (ADAPTATION). Harmless.
##  - Recording equipment malfunctions (SOURCE): the camcorder overlay shows an
##    error instead of a timecode, the picture tears now and then, and the
##    screenshot key captures nothing.
##  - The guest room reshapes itself to suit you (SOURCE: Blanche changes the rooms
##    to accommodate guests); the rule that picks the shape is ADAPTATION.

const S := preload("res://levels/L906/L906_shaders.gd")
const Rooms := preload("res://levels/L906/L906_rooms.gd")
const CEIL_BASE := 46.0
const RECEDE := 2.4
const MAX_ITEMS := 10
const SCRIPTS := ["a hooked, looping script you have never seen", "an alphabet of tiny knotted marks, forgotten long ago",
	"Latin letters arranged into no language you know", "columns of angular signs, read from the bottom up",
	"three different alphabets on facing pages", "a cramped, beautiful hand in a language nobody speaks"]
const SYL := ["vel", "ost", "qa", "mir", "eth", "un", "sor", "ka", "dra", "lyn", "obh", "tsa", "ir", "nem", "aul", "fey", "zor", "ith"]

var L: Node3D
var ceiling: MeshInstance3D
var ceil_y := CEIL_BASE + 1.62
var guides: Array = []
var items: Array = []
var spots: Dictionary = {}        # group -> Array[Vector3]
var rng := RandomNumberGenerator.new()
var spawn_t := 3.0
var spawned := 0
var clipped := 0
var rec_t := 6.0
var screenshots_blocked := 0
var _room_notice := false
var _scratch_t := 3.0
var _glow_mat: ShaderMaterial


func _init(level: Node3D) -> void:
	L = level


func setup() -> void:
	rng.seed = hash([L.level_seed, "life"])
	ceiling = MeshInstance3D.new()
	ceiling.name = "RecedingCeiling"
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	pm.flip_faces = true
	ceiling.mesh = pm
	ceiling.material_override = MatLib.get_mat("l906_ceiling")
	ceiling.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	L.add_child(ceiling)
	ceiling.position = Vector3(0, ceil_y, 0)
	_glow_mat = S.mat(S.GLOW, {"tint": Color(0.85, 0.92, 1.0), "energy": 0.8})
	for i in 4:
		guides.append(_make_guide())


func add_spots(group: String, list: Array) -> void:
	spots[group] = list


func drop_spots(group: String) -> void:
	spots.erase(group)


# ---------------------------------------------------------------- ceiling

func ceiling_target(eye_y: float) -> float:
	return eye_y + CEIL_BASE + RECEDE * maxf(0.0, eye_y - 1.62)


func _tick_ceiling(delta: float, cam: Vector3) -> void:
	ceil_y = lerpf(ceil_y, ceiling_target(cam.y), minf(1.0, delta * 2.5))
	ceiling.global_position = Vector3(cam.x, ceil_y, cam.z)


# ------------------------------------------------------------ light guides

func _make_guide() -> Dictionary:
	var n := Node3D.new()
	n.name = "LightGuide"
	L.add_child(n)
	var core := MeshInstance3D.new()
	core.mesh = Rooms.sph(0.06)
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(1.0, 1.05, 1.1)
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(core)
	var halo := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.6, 0.6)
	halo.mesh = qm
	halo.material_override = _glow_mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(halo)
	var l := OmniLight3D.new()
	l.light_color = Color(0.8, 0.9, 1.0)
	l.omni_range = 3.2
	l.light_energy = 0.7
	l.shadow_enabled = false
	n.add_child(l)
	var g := {"node": n, "light": l, "vel": Vector3.ZERO, "target": Vector3.ZERO, "t": 0.0, "gone": 0.0, "phase": rng.randf() * 10.0}
	_reposition(g, Vector3(2.0, 0.0, 6.0))
	return g


func _reposition(g: Dictionary, around: Vector3) -> void:
	var a := rng.randf() * TAU
	var d := rng.randf_range(5.0, 15.0)
	var p := around + Vector3(cos(a) * d, 0, sin(a) * d)
	p.y = rng.randf_range(1.4, 7.5)
	(g["node"] as Node3D).global_position = p
	g["target"] = p
	g["t"] = 0.0


func _tick_guides(delta: float, pp: Vector3) -> void:
	var now := Time.get_ticks_msec() * 0.001
	for g in guides:
		var n: Node3D = g["node"]
		if float(g["gone"]) > 0.0:
			g["gone"] = float(g["gone"]) - delta
			if float(g["gone"]) <= 0.0:
				_reposition(g, pp)
				n.visible = true
			continue
		if rng.randf() < delta * 0.025 or n.global_position.distance_to(pp) > 28.0:
			n.visible = false
			g["gone"] = rng.randf_range(2.0, 9.0)
			continue
		g["t"] = float(g["t"]) - delta
		if float(g["t"]) <= 0.0:
			var tgt: Vector3 = n.global_position + Vector3(rng.randf_range(-4, 4), rng.randf_range(-1.5, 1.5), rng.randf_range(-4, 4))
			tgt.y = clampf(tgt.y, 1.0, 9.0)
			g["target"] = tgt
			g["t"] = rng.randf_range(0.4, 2.6)
		var to: Vector3 = (g["target"] as Vector3) - n.global_position
		var v: Vector3 = (g["vel"] as Vector3).lerp(to.limit_length(1.4), minf(1.0, delta * 2.0))
		g["vel"] = v
		n.global_position += v * delta
		var ph: float = g["phase"]
		var f := 1.0 if sin(now * 13.0 + ph) * sin(now * 3.7 + ph * 2.0) < 0.82 else 0.08
		(g["light"] as OmniLight3D).light_energy = 0.7 * f
		n.scale = Vector3.ONE * (0.4 + 0.6 * f)


# --------------------------------------------------- books that come and go

func _all_spots() -> Array:
	var out: Array = []
	for k in spots:
		out.append_array(spots[k])
	return out


func spawn_item(force_at: Variant = null) -> Dictionary:
	var pp: Vector3 = L.player.global_position
	var cand: Array = []
	if force_at is Vector3:
		cand = [force_at]
	else:
		var cam: Camera3D = L.player.camera
		var hidden: Array = []
		for s in _all_spots():
			var d: float = (s as Vector3).distance_to(pp)
			if d > 3.0 and d < 17.0:
				cand.append(s)
				if not cam.is_position_in_frustum(s):
					hidden.append(s)
		if not hidden.is_empty() and rng.randf() < 0.7:
			cand = hidden
	if cand.is_empty():
		return {}
	var at: Vector3 = cand[rng.randi_range(0, cand.size() - 1)]
	at += Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))
	var kind: String = ["book", "book", "folder", "scroll", "note"][rng.randi_range(0, 4)]
	var n := Node3D.new()
	n.name = "Loose_" + kind
	L.add_child(n)
	n.global_position = at
	n.rotation.y = rng.randf() * TAU
	var mi := MeshInstance3D.new()
	match kind:
		"book":
			var b := BoxMesh.new()
			b.size = Vector3(0.17, 0.045, 0.24)
			mi.mesh = b
			mi.position.y = 0.0225
			mi.material_override = MatLib.get_mat(["l906_velvet", "l906_damask", "l906_tea_wall", "l906_wood", "l906_plush"][rng.randi_range(0, 4)])
		"folder":
			var b := BoxMesh.new()
			b.size = Vector3(0.25, 0.02, 0.32)
			mi.mesh = b
			mi.position.y = 0.01
			mi.material_override = MatLib.get_mat("l906_carpet_edge")
		"scroll":
			var c := Rooms.cyl(0.03, 0.03, 0.34)
			mi.mesh = c
			mi.rotation.z = PI * 0.5
			mi.position.y = 0.03
			mi.material_override = MatLib.get_mat("paper")
		_:
			var b := BoxMesh.new()
			b.size = Vector3(0.21, 0.003, 0.29)
			mi.mesh = b
			mi.position.y = 0.002
			mi.material_override = MatLib.get_mat("paper")
	n.add_child(mi)
	var item := {"node": n, "kind": kind, "signed": true, "title": "A loose %s" % kind, "text": _text(kind)}
	var it := Interactable.new()
	n.add_child(it)
	it.setup(Vector3(0, 0.08, 0), Vector3(0.45, 0.2, 0.45), "Read the %s" % kind, func(_p): L.hosts.read_item(item))
	n.scale = Vector3.ONE * 0.05
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK)
	items.append(item)
	spawned += 1
	if at.distance_to(pp) < 9.0 and not SessionState.is_qa():
		L.sound.play_at("whisper", {"seconds": 0.5}, at, -20.0, "[paper settles somewhere close by]")
	return item


func _text(kind: String) -> String:
	var words: Array = []
	for i in rng.randi_range(14, 24):
		var w := ""
		for j in rng.randi_range(1, 3):
			w += SYL[rng.randi_range(0, SYL.size() - 1)]
		words.append(w)
	var line := " ".join(words)
	var what: String = {"book": "Bound in worn leather", "folder": "A folder of loose leaves", "scroll": "A brittle scroll", "note": "A single folded note"}[kind]
	return "%s, written in %s:\n\n\"%s...\"\n\nAt the end, in a neat looping hand, as on everything here: Blanche." % [what, SCRIPTS[rng.randi_range(0, SCRIPTS.size() - 1)], line.capitalize().substr(0, 150)]


func clip_item(item: Dictionary) -> void:
	items.erase(item)
	clipped += 1
	var n: Node3D = item["node"]
	if not is_instance_valid(n):
		return
	var pp: Vector3 = L.player.global_position
	if n.global_position.distance_to(pp) < 7.0 and not SessionState.is_qa():
		Overlay.subtitle("[something slides out of the world with a whisper of paper]", 2.5)
	var tw := n.create_tween()
	tw.tween_property(n, "position", n.position + Vector3.DOWN * 0.3, 0.8)
	tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.02, 0.8)
	tw.tween_callback(n.queue_free)


func tear(node: Node3D) -> void:
	for it in items:
		if it["node"] == node:
			it["text"] = str(it["text"]) + "\n\n(A page is missing. You tore it out.)"


func _tick_items(delta: float) -> void:
	spawn_t -= delta
	if spawn_t > 0.0:
		return
	spawn_t = rng.randf_range(6.0, 12.0)
	items = items.filter(func(i): return is_instance_valid(i["node"]))
	var pp: Vector3 = L.player.global_position
	if items.size() > 3 and rng.randf() < 0.45:
		var far: Array = items.filter(func(i): return (i["node"] as Node3D).global_position.distance_to(pp) > 2.5)
		if not far.is_empty():
			clip_item(far[0])
	if items.size() < MAX_ITEMS:
		spawn_item()


# ------------------------------------------------------------ recorder

func recorder_text() -> String:
	return "■ REC ERR   --:--:--   NO SIGNAL" if int(Time.get_ticks_msec() / 900) % 3 != 0 else "▯ TAPE STOPPED   CANNOT RECORD"


func _tick_recorder(delta: float) -> void:
	if SessionState.is_qa():
		return
	if Settings.get_value("camcorder") and SessionState.in_gameplay:
		Overlay.rec_label.text = recorder_text()
	rec_t -= delta
	if rec_t <= 0.0:
		rec_t = rng.randf_range(7.0, 18.0)
		Overlay.glitch(rng.randf_range(0.12, 0.3))


func block_screenshot() -> void:
	screenshots_blocked += 1
	Overlay.toast("The shot comes out blank. Nothing here will hold a picture.", 3.0)


# ---------------------------------------------------------- guest room

func desired_style() -> String:
	if L.hosts.read_count >= 3:
		return "study"
	if L.hosts.tea_count >= 1:
		return "tea"
	if L.player.stats["distance"] > 500.0 or L.hosts.nights >= 1:
		return "rest"
	return "plain"


func reshape_room(force := false) -> bool:
	var want := desired_style()
	if want == L.rooms.room_style:
		return false
	var pp: Vector3 = L.player.global_position
	if not force and (pp.distance_to(Rooms.ROOM_C) < 9.0 and pp.y > 3.5):
		return false
	L.rooms.build_guest_room(want)
	_room_notice = L.hosts.room_given
	return true


# ------------------------------------------------------------------ tick

func process(delta: float) -> void:
	var p: Player = L.player
	if p == null or p.camera == null:
		return
	var cam := p.camera.global_position
	_tick_ceiling(delta, cam)
	_tick_guides(delta, p.global_position)
	_tick_items(delta)
	_tick_recorder(delta)
	var fb: MeshInstance3D = L.rooms.flicker_book
	if fb:
		fb.visible = sin(Time.get_ticks_msec() * 0.011) * sin(Time.get_ticks_msec() * 0.0037) < 0.7
		fb.position.x = 2.55 + (0.01 * sin(Time.get_ticks_msec() * 0.05) if not fb.visible else 0.0)
	if L.hosts.room_given and rng.randf() < delta:
		reshape_room()
	if _room_notice and p.global_position.distance_to(Rooms.ROOM_C) < 2.8 and p.global_position.y > 3.5:
		_room_notice = false
		Overlay.subtitle("[the room is not quite as you left it; it fits you better now]", 4.0)
	_scratch_t -= delta
	if _scratch_t <= 0.0:
		_scratch_t = rng.randf_range(4.0, 9.0)
		if L.hosts.where == "office" and not SessionState.is_qa() and p.global_position.distance_to(L.hosts.blanche.global_position) < 14.0:
			L.sound.play_at("scratch", {"seconds": 0.9}, L.hosts.blanche.global_position + Vector3(-0.6, 0.85, 0), -24.0, "")
