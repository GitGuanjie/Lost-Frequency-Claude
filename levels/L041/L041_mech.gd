extends Node3D
## Level 41 stateful hazards: fume intoxication (only builds; fainting at the
## top), hot sand while standing still, tar contact (burns at once, fatal past
## about a second), and the Collagen Leviathan: passive dolphin dives out in
## the fog, and a hunt that senses you at an island edge or on a walkway,
## bulges the tar beside you, then leaps for where you stood.
## In QA mode nothing hurts or kills; the states still run.

const DRESS := preload("res://levels/L041/L041_dress.gd")
const SEG := 22
const SPACING := 0.26

var lvl
var land
var bld
var dress
var fume := 0.0
var heat := 0.0
var burn := 0.0
var faint_t := -1.0
var said := {}
var dead := false
# leviathan
var body: Node3D
var segs: Array = []
var dive := {}               # {s, e, h, t, dur, kind}
var dive_wait := 14.0
var awake_t := 0.0
var awake_wait := 70.0
var sense := 0.0
var bulge: MeshInstance3D
var bulge_t := -1.0
var bulge_pos := Vector3.ZERO
var lock := Vector3.ZERO
var _last_pos := Vector3.ZERO
var _heart: AudioStreamPlayer
var _creak_t := 6.0


func _init(level, land_model, build, dressing) -> void:
	lvl = level
	land = land_model
	bld = build
	dress = dressing
	name = "Hazards"


func _ready() -> void:
	_make_body()
	bulge = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 20
	sm.rings = 8
	bulge.mesh = sm
	bulge.material_override = lvl.tar_mat
	bulge.visible = false
	bulge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bulge)
	_heart = lvl.sound.bed("heartbeat", {}, -80.0)
	dive_wait = lvl.rng.randf_range(8.0, 20.0)
	awake_wait = lvl.rng.randf_range(55.0, 110.0)


func on_ready() -> void:
	if lvl.spawn_report.get("used_arrival", "") == "from_L008":
		Overlay.subtitle("[you drag yourself out of the tar onto scorching black sand. It is still clinging to your sleeves.]", 5.0)
		Overlay.set_screen_effect("red_tint", 0.25)
		fume = 0.25
	if lvl.player:
		_last_pos = lvl.player.global_position


func _make_body() -> void:
	body = Node3D.new()
	body.name = "CollagenLeviathan"
	add_child(body)
	var bone: Material = MatLib.get_mat("l41_bone")
	var vm := DRESS.vertebra_mesh(true)
	var tm := DRESS.vertebra_mesh(false)
	var skull := MeshInstance3D.new()
	skull.mesh = DRESS.skull_mesh()
	skull.material_override = bone
	body.add_child(skull)
	segs.append(skull)
	for i in SEG:
		var mi := MeshInstance3D.new()
		mi.mesh = vm if i < SEG * 0.6 else tm
		mi.material_override = bone
		var sc := lerpf(1.25, 0.45, float(i) / SEG)
		mi.scale = Vector3.ONE * sc
		mi.set_meta("sc", sc)
		body.add_child(mi)
		segs.append(mi)
	body.visible = false


# ---------------------------------------------------------------- queries

func in_tar(p: Vector3) -> bool:
	return p.y < land.TAR_Y - 0.02 and land.h(p.x, p.z) < land.TAR_Y - 0.02


func _on_sand(p: Vector3) -> bool:
	var g: float = land.h(p.x, p.z)
	return g > 0.04 and p.y - g < 0.3


func _on_pier(p: Vector3) -> bool:
	return lvl.player.is_on_floor() and p.y - maxf(land.h(p.x, p.z), 0.0) > 1.4


func _at_edge(p: Vector3) -> bool:
	return _on_sand(p) and land.shore_dist(p.x, p.z, 2.4) <= 2.4


# ---------------------------------------------------------------- per frame

func step(delta: float) -> void:
	var pl: Player = lvl.player
	if pl == null or not is_instance_valid(pl) or pl.dead:
		return
	var p := pl.global_position
	var qa: bool = SessionState.is_qa()
	var speed := Vector2(p.x - _last_pos.x, p.z - _last_pos.z).length() / maxf(delta, 0.0001)
	_last_pos = p
	# --- tar contact
	if in_tar(p + Vector3.UP * 0.05):
		burn += delta
		_say("tar", "[the tar takes your boot and the heat goes straight through - GET OUT]", 3.0)
		if not qa:
			pl.hurt(28.0 * delta, "Level 41: burned in the tar")
		if burn > 1.15 and not dead and not qa:
			dead = true
			pl.hurt(1000.0, "Level 41: held in the tar longer than a second; it fused to you")
	else:
		burn = maxf(0.0, burn - delta * 0.6)
	# --- fumes: they only build here
	var above: float = p.y - land.TAR_Y
	var near := 1.0 - clampf((above - 0.5) / 6.0, 0.0, 1.0)
	fume = minf(1.0, fume + delta * (0.0022 + 0.0055 * near))
	if fume > 0.3:
		_say("f1", "[the fumes coat your throat; your eyes stream]", 4.0)
	if fume > 0.6:
		_say("f2", "[nausea. The fog swims at the edges]", 4.0)
	if fume > 0.85:
		_say("f3", "[you retch. Your knees want to fold]", 4.0)
	if fume >= 1.0 and faint_t < 0.0:
		faint_t = 0.0
		Overlay.subtitle("[you faint]", 3.0)
		if not qa:
			pl.hurt(20.0, "Level 41: fainted from the tar fumes")
	if faint_t >= 0.0:
		faint_t += delta
		Overlay.set_screen_effect("blackout", clampf(1.0 - absf(faint_t - 1.6) / 1.6, 0.0, 1.0))
		if faint_t > 3.2:
			faint_t = -1.0
			fume = 0.62
			said.erase("f3")
			Overlay.set_screen_effect("blackout", 0.0)
	# --- hot sand when you stop
	if _on_sand(p) and speed < 0.4:
		heat += delta
		if heat > 2.5:
			_say("sand", "[the sand is cooking through your soles - keep moving]", 4.0)
		if heat > 4.0 and not qa:
			pl.hurt(5.0 * delta, "Level 41: stood still on the burning sand")
	else:
		heat = maxf(0.0, heat - delta * 1.5)
	_effects(pl, delta)
	_leviathan(delta, p, qa)
	_audio(delta, p)


func _effects(pl: Player, _delta: float) -> void:
	var red := clampf(burn * 0.6, 0.0, 0.7) + clampf((heat - 3.0) * 0.06, 0.0, 0.2)
	Overlay.set_screen_effect("red_tint", red)
	Overlay.set_screen_effect("vignette", 0.28 + fume * 0.32)
	Overlay.set_screen_effect("desaturate", fume * 0.25)
	if pl.camera:
		var t := Time.get_ticks_msec() * 0.001
		pl.camera.rotation.z = smoothstep(0.4, 1.0, fume) * 0.03 * sin(t * 0.8)


# ---------------------------------------------------------------- leviathan

func _leviathan(delta: float, p: Vector3, qa: bool) -> void:
	if not dive.is_empty():
		_run_dive(delta, p, qa)
	# passive dives out in the fog
	dive_wait -= delta
	if dive_wait <= 0.0 and dive.is_empty():
		dive_wait = lvl.rng.randf_range(16.0, 40.0)
		var s: Vector3 = dress.tar_spot(lvl.rng, 6.0, 0.0, 190.0)
		if s.distance_to(p) > 25.0 and s.distance_to(p) < 110.0:
			var a: float = lvl.rng.randf_range(0, TAU)
			var e: Vector3 = s + Vector3(cos(a), 0, sin(a)) * lvl.rng.randf_range(14.0, 22.0)
			if land.h(e.x, e.z) < -0.5:
				_start(s, e, lvl.rng.randf_range(3.0, 4.5), 3.4, "pass")
				_say("dive", "[out in the fog something long and pale arcs out of the tar and back in]", 5.0)
	# the hunt: a waking period during which it senses edges and walkways
	awake_wait -= delta
	if awake_wait <= 0.0 and awake_t <= 0.0:
		awake_t = 26.0
		awake_wait = lvl.rng.randf_range(60.0, 130.0)
	if awake_t > 0.0:
		awake_t -= delta
		var exposed: bool = _at_edge(p) or _on_pier(p)
		sense = sense + delta if exposed else maxf(0.0, sense - delta * 0.5)
		if sense > 6.0 and bulge_t < 0.0 and dive.is_empty():
			var sp := _tar_beside(p)
			if sp != Vector3.INF:
				bulge_t = 0.0
				bulge_pos = sp
				_say("bulge%d" % int(awake_wait), "[the tar beside you bulges and slides. Something under it has noticed you - MOVE]", 3.0)
				lvl.sound.play_at("drip", {"freq": 50.0}, sp, 0.0, "")
	else:
		sense = maxf(0.0, sense - delta)
	if bulge_t >= 0.0:
		bulge_t += delta
		bulge.visible = true
		bulge.position = bulge_pos
		var k := smoothstep(0.0, 1.6, bulge_t)
		bulge.scale = Vector3(2.6, 0.05 + 0.55 * k, 2.6)
		if bulge_t > 1.6:
			bulge_t = -1.0
			bulge.visible = false
			lock = p
			var through := Vector3(lock.x, 0, lock.z) - Vector3(bulge_pos.x, 0, bulge_pos.z)
			var e := lock + through.normalized() * 7.0
			e.y = 0.0
			_start(bulge_pos, e, maxf(2.2, lock.y + 1.2), 2.0, "strike")
			sense = 0.0
			awake_t = 0.0


## A tar point 4-7 m from p (prefers the direction away from the island).
func _tar_beside(p: Vector3) -> Vector3:
	for r in [4.5, 6.0, 7.5]:
		for j in 12:
			var a := TAU * j / 12.0 + 0.3
			var q: Vector3 = p + Vector3(cos(a), 0, sin(a)) * r
			if land.h(q.x, q.z) < -0.5:
				return Vector3(q.x, 0.0, q.z)
	return Vector3.INF


func _start(s: Vector3, e: Vector3, h: float, dur: float, kind: String) -> void:
	dive = {"s": Vector3(s.x, 0, s.z), "e": Vector3(e.x, 0, e.z), "h": h, "t": 0.0, "dur": dur, "kind": kind, "hit": false, "splash": 0}
	body.visible = true
	lvl.sound.play_at("splash", {}, s, -2.0, "[a heavy, wet breach]")


## Pose the body along its arc. u_head runs 0 -> 1 + body length.
func _pose(u_head: float) -> void:
	var s: Vector3 = dive["s"]
	var e: Vector3 = dive["e"]
	var h: float = dive["h"]
	var ln := maxf(s.distance_to(e), 1.0)
	for i in segs.size():
		var back := 0.0 if i == 0 else 0.55 + float(i - 1) * SPACING
		var u := u_head - back / ln
		var pos := s.lerp(e, u) + Vector3.UP * (h * 4.0 * u * (1.0 - u) - 0.6)
		var u2 := u + 0.01
		var nxt := s.lerp(e, u2) + Vector3.UP * (h * 4.0 * u2 * (1.0 - u2) - 0.6)
		var mi: Node3D = segs[i]
		mi.visible = pos.y > -1.2
		var fw := (nxt - pos).normalized()
		if absf(fw.y) < 0.97:
			mi.global_transform = Transform3D(Basis.looking_at(-fw, Vector3.UP), pos)
			if mi.has_meta("sc"):
				var sc: float = mi.get_meta("sc")
				mi.scale = Vector3.ONE * sc


func _run_dive(delta: float, p: Vector3, qa: bool) -> void:
	dive["t"] += delta
	var t: float = dive["t"] / dive["dur"]
	var ln := maxf((dive["s"] as Vector3).distance_to(dive["e"]), 1.0)
	var u_head := lerpf(-0.05, 1.0 + (SEG * SPACING + 1.0) / ln, t)
	_pose(u_head)
	if int(dive["splash"]) == 0 and u_head > 1.0:
		dive["splash"] = 1
		lvl.sound.play_at("splash", {}, dive["e"], -2.0, "")
	if dive["kind"] == "strike" and not dive["hit"] and t > 0.42:
		dive["hit"] = true
		var gap := Vector2(p.x - lock.x, p.z - lock.z).length()
		if gap < 2.2 and (_at_edge(p) or _on_pier(p)):
			Overlay.glitch(0.6)
			Overlay.subtitle("[jaws of old bone close around you, and the tar closes over both of you]", 5.0)
			if not qa and not dead:
				dead = true
				lvl.player.hurt(1000.0, "Level 41: taken under by a Collagen Leviathan")
		else:
			Overlay.subtitle("[it crashes down where you stood. Burning tar rains across the sand]", 4.0)
			if gap < 5.0 and not qa:
				lvl.player.hurt(14.0, "Level 41: showered with burning tar")
				burn = maxf(burn, 0.4)
	if t >= 1.0:
		dive = {}
		body.visible = false


## Freeze a dive mid-arc for a curated still.
func stage_dive(s: Vector3, e: Vector3, t: float) -> void:
	dive = {"s": s, "e": e, "h": 4.0, "t": 0.0, "dur": 1.0, "kind": "pass", "hit": true, "splash": 1}
	body.visible = true
	var ln := maxf(s.distance_to(e), 1.0)
	_pose(lerpf(-0.05, 1.0 + (SEG * SPACING + 1.0) / ln, t))
	dive = {}
	dive_wait = 9999.0


# ---------------------------------------------------------------- audio

func _audio(delta: float, p: Vector3) -> void:
	if is_instance_valid(_heart):
		_heart.volume_db = lerpf(_heart.volume_db, -14.0 if (fume > 0.7 or burn > 0.2 or bulge_t >= 0.0) else -80.0, minf(delta * 1.5, 1.0))
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = lvl.rng.randf_range(4.0, 9.0)
		if _on_pier(p):
			lvl.sound.play_at("creak", {"freq": 140.0}, p + Vector3.DOWN * 0.4, -10.0, "[the walkway creaks under you]")


func _say(key: String, text: String, secs: float) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)
