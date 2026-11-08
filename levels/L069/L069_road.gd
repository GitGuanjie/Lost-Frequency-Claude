extends RefCounted
## Level 69 road: the highway between tall weathered concrete walls (streamed in
## 40 m chunks along z), the out-of-place perpendicular tunnel (static, along -x)
## and the tunnel's end piece, where the car has died and you walk out.
## SOURCE: "an infinite highway with tall, weathered, concrete walls at its sides";
## "completely devoid of vehicles or any sign of civilization except for the fact
## that it is a highway"; the exit is "an out-of-place tunnel perpendicular to the
## highway", "a 1 lane road", whose roof lights turn on as the fog thins.
## ADAPTATION: cross-section (four lanes, 20 m between walls, 9 m walls), wall
## panelling, the tunnel's walkway and the end piece's stair are ours.

const CS := 40.0              # chunk length along z
const WALL_X := 10.0          # inner face of the side walls
const WALL_H := 9.0
const TW := 3.0               # tunnel half width (z)
const T_ROOF := 5.0
const T_LEN := 620.0
const WALK_Y := 0.6

var lvl: LevelBase
var seed_i := 0
var tz := -900.0              # tunnel centreline z
var spots: Array = []         # noclip wall spots [{z, side}]


func _init(level: LevelBase, level_seed: int, tunnel_z: float, spot_list: Array) -> void:
	lvl = level
	seed_i = absi(level_seed)
	tz = tunnel_z
	spots = spot_list


static func materials() -> void:
	MatLib.define("l69_asphalt", {"albedo_a": Color(0.13, 0.13, 0.135), "albedo_b": Color(0.09, 0.09, 0.095), "pattern": 15,
		"pattern_color": Color(0.24, 0.24, 0.24), "pattern_strength": 0.35, "stain_amount": 0.45, "stain_color": Color(0.06, 0.06, 0.06),
		"stain_scale": 0.12, "roughness_a": 0.82, "roughness_b": 0.96, "wetness": 0.12, "bump_strength": 1.0}, "asphalt")
	MatLib.define("l69_patch", {"albedo_a": Color(0.07, 0.07, 0.075), "albedo_b": Color(0.05, 0.05, 0.055), "roughness_a": 0.7}, "asphalt")
	MatLib.define("l69_wall", {"albedo_a": Color(0.5, 0.49, 0.46), "albedo_b": Color(0.4, 0.39, 0.37), "pattern": 2,
		"pattern_scale": Vector2(0.9, 1.0), "pattern_color": Color(0.33, 0.32, 0.3), "pattern_strength": 0.25, "noise_scale": 1.3,
		"stain_amount": 0.55, "stain_color": Color(0.26, 0.24, 0.21), "stain_scale": 0.22, "grime_height": 1.8,
		"grime_color": Color(0.2, 0.19, 0.17), "bump_strength": 1.3, "roughness_a": 0.9}, "concrete")
	MatLib.define("l69_wall_odd", {"albedo_a": Color(0.47, 0.47, 0.46), "albedo_b": Color(0.42, 0.42, 0.41), "pattern": 11,
		"pattern_scale": Vector2(0.6, 0.6), "pattern_color": Color(0.3, 0.3, 0.3), "pattern_strength": 0.3,
		"stain_amount": 0.3, "grime_height": 1.4, "grime_color": Color(0.22, 0.21, 0.2), "bump_strength": 0.5}, "concrete")
	MatLib.define("l69_patch_wall", {"albedo_a": Color(0.36, 0.35, 0.33), "albedo_b": Color(0.3, 0.29, 0.27), "noise_scale": 4.0,
		"bump_strength": 2.0, "stain_amount": 0.4, "stain_color": Color(0.22, 0.2, 0.18)}, "concrete")
	MatLib.define("l69_joint", {"albedo_a": Color(0.08, 0.08, 0.08), "albedo_b": Color(0.05, 0.05, 0.05)}, "concrete_dark")
	MatLib.define("l69_curb", {"albedo_a": Color(0.42, 0.41, 0.39), "albedo_b": Color(0.34, 0.33, 0.31), "grime_height": 0.4,
		"grime_color": Color(0.15, 0.14, 0.13)}, "concrete")
	MatLib.define("l69_line_w", {"albedo_a": Color(0.72, 0.71, 0.66), "albedo_b": Color(0.5, 0.49, 0.45), "noise_scale": 3.0,
		"stain_amount": 0.6, "stain_color": Color(0.2, 0.2, 0.2), "stain_scale": 2.0, "roughness_a": 0.6}, "plaster")
	MatLib.define("l69_line_y", {"albedo_a": Color(0.72, 0.56, 0.16), "albedo_b": Color(0.5, 0.39, 0.12), "noise_scale": 3.0,
		"stain_amount": 0.55, "stain_color": Color(0.2, 0.18, 0.12), "stain_scale": 2.0, "roughness_a": 0.6}, "plaster")
	MatLib.register("l69_reflector", MatLib.standard(Color(0.95, 0.9, 0.75), 0.05, 0.6))
	MatLib.define("l69_tile", {"albedo_a": Color(0.72, 0.7, 0.62), "albedo_b": Color(0.66, 0.64, 0.56), "pattern": 1,
		"pattern_scale": Vector2(0.3, 0.15), "grout_width": 0.008, "grout_color": Color(0.36, 0.35, 0.3), "tile_variation": 0.06,
		"stain_amount": 0.5, "stain_color": Color(0.32, 0.3, 0.24), "grime_height": 1.2, "grime_color": Color(0.2, 0.19, 0.16),
		"roughness_a": 0.35, "roughness_b": 0.7}, "pool_tile")
	MatLib.define("l69_troof", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.14, 0.14, 0.14), "stain_amount": 0.5}, "concrete_dark")
	MatLib.define("l69_steel", {"albedo_a": Color(0.4, 0.41, 0.42), "albedo_b": Color(0.3, 0.31, 0.32), "stain_amount": 0.4}, "metal")
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color(0.85, 0.82, 0.7)
	lamp.emission_enabled = true
	lamp.emission = Color(1.0, 0.86, 0.6)
	lamp.emission_energy_multiplier = 0.0
	MatLib.register("l69_lamp", lamp)
	var day := StandardMaterial3D.new()
	day.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	day.albedo_color = Color(1.0, 0.95, 0.85)
	MatLib.register("l69_daylight", day)


func _h(a: int, b: int) -> float:
	var n := (a * 374761393 + b * 668265263 + seed_i * 1442695041) & 0xFFFFFFFF
	n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


# ------------------------------------------------------------------ highway

## ChunkWorld builder. Only the cx == 0 column carries the road; the others are
## empty darkness (the walls close the world on both sides).
func build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	if cx != 0:
		return {}
	var z0 := float(cz) * CS
	var z1 := z0 + CS
	var k := GeoKit.new(node, "Road")
	k.box_mm(Vector3(-WALL_X, -0.5, z0), Vector3(WALL_X, 0.0, z1), "l69_asphalt", GeoKit.PY)
	# markings: faded edge lines, lane dashes, centre double line, reflectors
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 8.4, 0.004, z0 + CS * 0.5), Vector3(0.16, 0.008, CS), "l69_line_w", GeoKit.PY, false)
		k.box(Vector3(s * 0.14, 0.004, z0 + CS * 0.5), Vector3(0.1, 0.008, CS), "l69_line_y", GeoKit.PY, false)
		for i in 4:
			var zz := z0 + 4.0 + float(i) * 10.0
			if _h(cz, i + int(s * 7.0)) > 0.12:
				k.box(Vector3(s * 4.3, 0.004, zz), Vector3(0.13, 0.008, 3.0), "l69_line_w", GeoKit.PY, false)
	for i in 4:
		var zz := z0 + 2.0 + float(i) * 10.0
		if _h(cz, 40 + i) > 0.25:
			k.box(Vector3(0.0, 0.02, zz), Vector3(0.12, 0.04, 0.1), "l69_reflector", GeoKit.PY | GeoKit.SIDES, false)
	# repairs and cracks in the asphalt
	for i in 3:
		if _h(cz, 60 + i) < 0.55:
			var px := lerpf(-8.0, 8.0, _h(cz, 70 + i))
			var pz := z0 + _h(cz, 80 + i) * CS
			k.box(Vector3(px, 0.003, pz), Vector3(1.0 + _h(cz, 90 + i) * 3.0, 0.006, 0.8 + _h(cz, 95 + i) * 2.5), "l69_patch", GeoKit.PY, false)
	for i in 4:
		var px := lerpf(-9.0, 9.0, _h(cz, 100 + i))
		var pz := z0 + _h(cz, 110 + i) * CS
		var yaw := _h(cz, 120 + i) * PI
		k.box_xf(Transform3D(Basis(Vector3.UP, yaw), Vector3(px, 0.003, pz)), Vector3(0.025, 0.006, 1.5 + _h(cz, 130 + i) * 4.0), "l69_joint", GeoKit.PY, false)
	k.box(Vector3(0, 0.002, z0), Vector3(WALL_X * 2.0, 0.004, 0.05), "l69_joint", GeoKit.PY, false)
	# walls (the tunnel portal cuts the left wall), curbs, joints, drains
	for s in [-1.0, 1.0]:
		var spot := _spot_in(z0, z1, s)
		var ops: Array = []
		if s < 0.0 and tz >= z0 - 4.0 and tz < z1 + 4.0:
			ops.append({"at": tz - z0, "w": TW * 2.0 + 0.8, "h": T_ROOF + 0.9})
		k.wall(Vector3(s * (WALL_X + 0.4), -0.5, z0), Vector3(s * (WALL_X + 0.4), -0.5, z1), WALL_H + 0.5, 0.8, "l69_wall", _shift_ops(ops))
		if ops.is_empty():
			k.box(Vector3(s * (WALL_X - 0.2), 0.11, z0 + CS * 0.5), Vector3(0.4, 0.22, CS), "l69_curb", GeoKit.ALL, false)
		else:
			var za := clampf(tz - TW - 0.4, z0, z1)
			var zb := clampf(tz + TW + 0.4, z0, z1)
			if za > z0:
				k.box_mm(Vector3(s * WALL_X, 0.0, z0), Vector3(s * (WALL_X - 0.4), 0.22, za), "l69_curb", GeoKit.ALL, false)
			if zb < z1:
				k.box_mm(Vector3(s * WALL_X, 0.0, zb), Vector3(s * (WALL_X - 0.4), 0.22, z1), "l69_curb", GeoKit.ALL, false)
		for j in 8:
			var jz := z0 + 2.5 + float(j) * 5.0
			if absf(jz - tz) < TW + 0.6 and s < 0.0:
				continue
			k.box(Vector3(s * (WALL_X - 0.005), WALL_H * 0.5, jz), Vector3(0.02, WALL_H, 0.05), "l69_joint", GeoKit.SIDES, false)
			if j % 2 == 0:
				k.box(Vector3(s * (WALL_X - 0.005), 0.32, jz + 2.5), Vector3(0.02, 0.12, 0.6), "l69_joint", GeoKit.SIDES, false)
		for yy in [3.0, 6.0]:
			k.box(Vector3(s * (WALL_X - 0.004), yy, z0 + CS * 0.5), Vector3(0.012, 0.03, CS), "l69_joint", GeoKit.SIDES, false)
		# a broken, uneven top edge against the dark
		for j in 5:
			var bz := z0 + 4.0 + float(j) * 8.0
			var hh := 0.2 + _h(cz, 200 + j + int(s * 11.0)) * 0.7
			k.box(Vector3(s * (WALL_X + 0.4), WALL_H + hh * 0.5, bz), Vector3(0.8, hh, 2.0 + _h(cz, 210 + j) * 4.0), "l69_wall", GeoKit.ALL, false)
		# relief: buttress ribs, spalled patches, rebar at the broken top, fallen chunks
		for j in 4:
			var rz := z0 + 5.0 + float(j) * 10.0
			if s < 0.0 and absf(rz - tz) < TW + 1.2:
				continue
			k.box(Vector3(s * (WALL_X - 0.12), WALL_H * 0.5 - 0.25, rz), Vector3(0.24, WALL_H + 0.5, 0.7), "l69_wall", GeoKit.ALL ^ (GeoKit.PX if s > 0.0 else GeoKit.NX), true)
		for j in 3:
			var hz := z0 + _h(cz, 300 + j + int(s * 5.0)) * CS
			if s < 0.0 and absf(hz - tz) < TW + 1.5:
				continue
			var hy := 0.6 + _h(cz, 310 + j) * 7.0
			k.box(Vector3(s * (WALL_X - 0.008), hy, hz), Vector3(0.016, 0.4 + _h(cz, 320 + j) * 1.4, 0.6 + _h(cz, 330 + j) * 2.0), "l69_patch_wall", GeoKit.SIDES, false)
		for j in 3:
			var bz := z0 + 6.0 + float(j) * 12.0 + _h(cz, 340 + j) * 4.0
			k.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.3 * s), Vector3(s * (WALL_X + 0.1), WALL_H + 0.45, bz)), Vector3(0.025, 0.9, 0.025), "l69_steel", GeoKit.SIDES, false)
		if _h(cz, 350 + int(s * 3.0)) < 0.6:
			var dz := z0 + _h(cz, 360 + int(s * 3.0)) * CS
			if not (s < 0.0 and absf(dz - tz) < TW + 2.0):
				for j in 3:
					var c := Vector3(s * (WALL_X - 0.6 - _h(cz, 370 + j) * 0.9), 0.12, dz + float(j) * 0.7)
					k.box_xf(Transform3D(Basis(Vector3.UP, _h(cz, 380 + j) * 3.0), c), Vector3(0.3 + _h(cz, 390 + j) * 0.4, 0.24, 0.3), "l69_wall", GeoKit.ALL, false)
		k.box(Vector3(s * (WALL_X - 0.55), 0.004, z0 + 20.0), Vector3(0.45, 0.01, 0.9), "l69_steel", GeoKit.PY, false)
		if not spot.is_empty():
			_noclip_spot(k, node, spot)
	k.commit()
	return {"cz": cz}


func _shift_ops(ops: Array) -> Array:
	return ops


func _spot_in(z0: float, z1: float, side: float) -> Dictionary:
	for sp in spots:
		if float(sp["z"]) >= z0 + 3.0 and float(sp["z"]) < z1 - 3.0 and float(sp["side"]) == side:
			return sp
	return {}


## The right place in the wall: a panel that is not quite like the others, and
## a faint crackle. Pressing the car into it is the no-clip to Level 22.
func _noclip_spot(k: GeoKit, node: Node3D, sp: Dictionary) -> void:
	var s: float = sp["side"]
	var z: float = sp["z"]
	k.box(Vector3(s * (WALL_X - 0.01), 3.2, z), Vector3(0.03, 6.4, 4.6), "l69_wall_odd", GeoKit.SIDES, false)
	var hum := AudioStreamPlayer3D.new()
	hum.stream = AudioSynth.get_stream("crackle", {})
	hum.volume_db = -14.0
	hum.max_distance = 14.0
	hum.unit_size = 2.0
	hum.bus = "Ambience"
	hum.autoplay = true
	hum.position = Vector3(s * (WALL_X - 0.3), 1.2, z)
	node.add_child(hum)
	var ex := lvl.make_exit("L069>L022#2", "condition", Vector3(s * (WALL_X - 1.6), 1.2, z), Vector3(3.2, 3.0, 5.0), "", node)
	if ex:
		ex.condition = lvl._noclip_ready.bind(z, s)


# ------------------------------------------------------------------ tunnel

func tunnel(k: GeoKit) -> void:
	var x0 := -(WALL_X + 0.8)
	var x1 := -T_LEN
	k.box_mm(Vector3(x1, -0.5, tz - TW), Vector3(-WALL_X, 0.0, tz + 1.6), "l69_asphalt", GeoKit.PY)
	k.box_mm(Vector3(x1, -0.5, tz + 1.6), Vector3(-WALL_X, WALK_Y, tz + TW), "l69_curb", GeoKit.PY | GeoKit.NZ | GeoKit.PX)
	k.box_mm(Vector3(x1, 0.0, tz - TW - 0.4), Vector3(x0, T_ROOF, tz - TW), "l69_tile", GeoKit.PZ)
	k.box_mm(Vector3(x1, WALK_Y, tz + TW), Vector3(x0, T_ROOF, tz + TW + 0.4), "l69_tile", GeoKit.NZ)
	k.box_mm(Vector3(x1, T_ROOF, tz - TW - 0.4), Vector3(x0, T_ROOF + 0.4, tz + TW + 0.4), "l69_troof", GeoKit.NY)
	k.box_mm(Vector3(x1 - 0.4, -0.5, tz - TW - 0.4), Vector3(x1, T_ROOF, tz + TW + 0.4), "l69_troof", GeoKit.PX)
	# portal surround on the highway side
	k.box(Vector3(-WALL_X + 0.02, T_ROOF + 0.35, tz), Vector3(0.06, 0.3, TW * 2.0 + 0.8), "l69_curb", GeoKit.PX, false)
	k.box(Vector3(-WALL_X + 0.02, 0.15, tz + TW + 0.2), Vector3(0.06, 0.3, 0.4), "l69_curb", GeoKit.PX, false)
	# lane line, walkway rail, cable tray, lamps every 10 m
	var x := x0 - 2.0
	while x > x1 + 2.0:
		k.box(Vector3(x, 0.004, tz - 0.7), Vector3(3.0, 0.008, 0.12), "l69_line_w", GeoKit.PY, false)
		k.box(Vector3(x, T_ROOF - 0.08, tz - 0.7), Vector3(1.3, 0.12, 0.34), "l69_steel", GeoKit.ALL, false)
		k.box(Vector3(x, T_ROOF - 0.15, tz - 0.7), Vector3(1.15, 0.02, 0.24), "l69_lamp", GeoKit.NY, false)
		k.box(Vector3(x - 5.0, 0.3, tz - TW + 0.02), Vector3(0.5, 0.18, 0.04), "l69_joint", GeoKit.PZ, false)
		x -= 10.0
	k.box(Vector3((x0 + x1) * 0.5, WALK_Y + 1.0, tz + 1.62), Vector3(absf(x1 - x0), 0.05, 0.05), "l69_steel", GeoKit.ALL, false)
	k.box(Vector3((x0 + x1) * 0.5, 4.3, tz + TW - 0.12), Vector3(absf(x1 - x0), 0.08, 0.22), "l69_steel", GeoKit.ALL, false)
	var px := x0 - 1.0
	while px > x1:
		k.box(Vector3(px, WALK_Y + 0.5, tz + 1.62), Vector3(0.05, 1.0, 0.05), "l69_steel", GeoKit.ALL, false)
		px -= 2.5


func lamp_positions() -> Array:
	var out: Array = []
	var x := -(WALL_X + 0.8) - 2.0
	while x > -T_LEN + 2.0:
		out.append(Vector3(x, T_ROOF - 0.4, tz - 0.7))
		x -= 10.0
	return out


## The end of the drive: a stair over the lane to a raised landing and the way
## out (light beyond). Built when the seventeen hours are done (or in QA).
func end_piece(node: Node3D, xe: float) -> void:
	var k := GeoKit.new(node, "TunnelEnd")
	var landing := 1.26
	# stair across the whole tunnel width, from the lane and from the walkway
	k.stairs(Vector3(xe, 0.0, tz - 0.7), Vector3(-1, 0, 0), TW * 2.0 - 1.2, landing, 7, "l69_curb", 0.3)
	k.stairs(Vector3(xe - 0.9, WALK_Y, tz + 2.3), Vector3(-1, 0, 0), 1.4, landing - WALK_Y, 4, "l69_curb", 0.3)
	k.box_mm(Vector3(xe - 26.0, -0.5, tz - TW), Vector3(xe - 2.1, landing, tz + TW), "l69_curb", GeoKit.PY | GeoKit.PX)
	# end wall with the doorway out, and the light beyond it
	k.wall(Vector3(xe - 26.0, landing, tz - TW), Vector3(xe - 26.0, landing, tz + TW), T_ROOF - landing, 0.5, "l69_tile",
		[{"at": TW, "w": 2.2, "h": 2.4}])
	k.box_mm(Vector3(xe - 26.6, -0.5, tz - TW - 0.4), Vector3(xe - 26.25, T_ROOF, tz + TW + 0.4), "l69_troof", GeoKit.ALL)
	k.box(Vector3(xe - 26.5, landing + 1.2, tz), Vector3(0.05, 2.4, 2.2), "l69_daylight", GeoKit.PX, false)
	k.box(Vector3(xe - 25.74, landing + 2.55, tz), Vector3(0.04, 0.2, 2.6), "l69_steel", GeoKit.PX, false)
	# landing railing along the drop to the lane
	k.box(Vector3(xe - 2.2, landing + 0.5, tz - 0.6), Vector3(0.05, 1.0, 4.6), "l69_steel", GeoKit.ALL, false)
	k.commit()
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.9, 0.75)
	glow.light_energy = 6.0
	glow.omni_range = 16.0
	glow.position = Vector3(xe - 25.4, landing + 1.4, tz)
	node.add_child(glow)
	Props.place(lvl, node, "ph/concrete_road_barrier", Vector3(xe + 1.6, 0.0, tz - 2.1), 90.0, 0.0, true)
	Props.place(lvl, node, "ph/fire_alarm", Vector3(xe - 20.0, landing + 1.4, tz + TW - 0.02), 180.0)
	Props.place(lvl, node, "ph/korean_fire_extinguisher_01", Vector3(xe - 18.0, landing, tz + TW - 0.3), 180.0)
