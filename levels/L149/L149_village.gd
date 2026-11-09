extends RefCounted
## Level 149: the settlement of the Lost Suns of the Coconut Isles on the largest isle:
## Iroquois-style bark longhouses (barrel roofs, sleeping platforms, hearths and smoke holes),
## two tree houses up in the palms, coconut-wood huts and a single public house with the
## paper drawings of Coconut Snares, the hunters' palm-bark bows and palm spears and the
## shared heap of ripe coconuts. Everything sits on the main isle's local frame (= world).

const Isle := preload("res://levels/L149/L149_isle.gd")
const FLAME := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float t = TIME * 3.0;
	float w = 0.55 * (1.0 - UV.y * 0.0) * (0.85 + 0.15 * sin(t * 3.1 + UV.y * 9.0));
	float shape = smoothstep(w, w * 0.2, abs(p.x + sin(t + UV.y * 6.0) * 0.12 * (1.0 - UV.y))) * smoothstep(-1.0, -0.2, -p.y * 0.9 - 0.1) ;
	shape *= smoothstep(0.0, 0.25, 1.0 - UV.y);
	vec3 c = mix(vec3(1.0, 0.85, 0.35), vec3(1.0, 0.3, 0.05), UV.y);
	ALBEDO = c * shape * 1.6;
}
"""

var L: LevelBase
var IS: Isle
var spec: Dictionary
var k: GeoKit
var d: GeoKit
var props: Node3D
var rng: RandomNumberGenerator
var fires: Array = []          # world positions of hearths and fire pits
var avoid: Array = []          # Vector3(x, z, r) kept free of grove palms
var coconut_piles: Array = []
var notes: Array = []          # [id, title, text, pos]
var treehouse_tops: Array = []
var longhouse_in: Array = []   # interior centres
var flame_mat: ShaderMaterial


func _init(level: LevelBase, isle_kit, main_spec: Dictionary, r: RandomNumberGenerator) -> void:
	L = level
	IS = isle_kit
	spec = main_spec
	rng = r
	k = GeoKit.new(spec["body"], "Village")
	d = GeoKit.new(spec["body"], "VillageDress")
	d.shadows = true
	props = Node3D.new()
	props.name = "VillageProps"
	(spec["body"] as Node3D).add_child(props)
	var sh := Shader.new()
	sh.code = FLAME
	flame_mat = ShaderMaterial.new()
	flame_mat.shader = sh


static func materials() -> void:
	MatLib.define("l149_bark", {"albedo_a": Color(0.25, 0.18, 0.12), "albedo_b": Color(0.18, 0.13, 0.09), "pattern": 3,
		"pattern_scale": Vector2(0.9, 2.6), "grout_width": 0.03, "grout_color": Color(0.08, 0.06, 0.04), "roughness_a": 0.95,
		"bump_strength": 1.2, "uv_rotate": 1.5708}, "")
	MatLib.define("l149_pole", {"albedo_a": Color(0.42, 0.33, 0.22), "albedo_b": Color(0.34, 0.26, 0.17), "roughness_a": 0.85,
		"noise_scale": 2.0}, "")
	MatLib.define("l149_thatch", {"albedo_a": Color(0.52, 0.42, 0.24), "albedo_b": Color(0.4, 0.31, 0.17), "pattern": 2,
		"pattern_scale": Vector2(14.0, 14.0), "pattern_color": Color(0.3, 0.22, 0.12), "pattern_strength": 0.5, "roughness_a": 1.0,
		"bump_strength": 1.0}, "")
	MatLib.define("l149_plank", {"albedo_a": Color(0.45, 0.35, 0.23), "albedo_b": Color(0.37, 0.28, 0.18), "pattern": 3,
		"pattern_scale": Vector2(1.4, 0.2), "grout_width": 0.02, "grout_color": Color(0.12, 0.09, 0.06), "roughness_a": 0.85}, "")
	MatLib.define("l149_mat", {"albedo_a": Color(0.6, 0.48, 0.3), "albedo_b": Color(0.5, 0.38, 0.22), "pattern": 9,
		"pattern_scale": Vector2(12.0, 12.0), "roughness_a": 1.0}, "")
	MatLib.define("l149_earth", {"albedo_a": Color(0.3, 0.22, 0.15), "albedo_b": Color(0.24, 0.18, 0.12), "noise_scale": 1.2,
		"roughness_a": 1.0, "bump_strength": 0.8}, "")
	MatLib.define("l149_stone", {"albedo_a": Color(0.36, 0.33, 0.3), "albedo_b": Color(0.26, 0.24, 0.22), "noise_scale": 2.0,
		"roughness_a": 0.9, "bump_strength": 1.5}, "")
	MatLib.register("l149_ember", MatLib.panel(Color(1.0, 0.35, 0.08), 2.6, 0.3))
	MatLib.register("l149_paper", MatLib.standard(Color(0.82, 0.76, 0.6), 0.95))
	MatLib.register("l149_ink", MatLib.standard(Color(0.18, 0.12, 0.08), 0.95))
	MatLib.register("l149_husk", MatLib.standard(Color(0.3, 0.2, 0.09), 0.7))
	MatLib.register("l149_green_nut", MatLib.standard(Color(0.32, 0.4, 0.12), 0.6))


## Ground height (main isle, world = local) ignoring nothing: buildings sit on flats.
func gy(x: float, z: float) -> float:
	return IS.h_local(spec, x, z)


## Flats and keep-out discs must be registered before the isle mesh is built.
static func site_plan() -> Array:
	# [kind, x, z, size, yaw_deg]
	return [["longhouse", -36.0, -8.0, 22.0, 0.0], ["longhouse", -14.0, 36.0, 20.0, 90.0], ["longhouse", 16.0, -38.0, 22.0, 90.0],
		["public", 34.0, 14.0, 16.0, 0.0], ["treehouse", 6.0, 31.0, 0.0, 200.0], ["treehouse", 33.0, -16.0, 0.0, 110.0],
		["hut", -50.0, 18.0, 0.0, 70.0], ["hut", -46.0, -32.0, 0.0, 20.0], ["hut", 48.0, -6.0, 0.0, 270.0],
		["hut", 44.0, 36.0, 0.0, 230.0], ["hut", -4.0, 52.0, 0.0, 180.0], ["hut", -10.0, -50.0, 0.0, 0.0],
		["fire", -20.0, 12.0, 0.0, 0.0], ["fire", 22.0, 2.0, 0.0, 0.0], ["fire", -4.0, -30.0, 0.0, 0.0]]


func build() -> void:
	for s in site_plan():
		var x: float = s[1]
		var z: float = s[2]
		var p := Vector3(x, gy(x, z), z)
		match s[0]:
			"longhouse":
				longhouse(p, s[3], s[4])
			"public":
				public_house(p, s[3])
			"treehouse":
				treehouse(p, s[4])
			"hut":
				hut(p, s[4])
			"fire":
				fire_pit(p)
	k.commit()
	d.commit()


func _frame(c: Vector3, yaw_deg: float) -> Array:
	var b := Basis(Vector3.UP, deg_to_rad(yaw_deg))
	return [b * Vector3(1, 0, 0), Vector3.UP, b * Vector3(0, 0, 1), b]


## Bark longhouse along its local Z: barrel roof on a pole frame, doors at both ends.
func longhouse(c: Vector3, length: float, yaw: float) -> void:
	var f := _frame(c, yaw)
	var u: Vector3 = f[0]
	var w: Vector3 = f[2]
	var W := 6.6
	var H := 5.6
	var n := 12
	var prof: Array = []
	for i in n + 1:
		var a := PI * i / n
		prof.append(Vector2(cos(a) * W * 0.5, sin(a) * H))
	for i in n:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var sd := (p1 - p0)
		var S := (u * sd.x + Vector3.UP * sd.y).normalized()
		var N := S.cross(w).normalized()
		var mid := c + u * ((p0.x + p1.x) * 0.5) + Vector3.UP * ((p0.y + p1.y) * 0.5)
		var smoke := i == n / 2 or i == n / 2 - 1
		if smoke:
			# roof crest with smoke holes over each hearth
			var seg_z := -length * 0.5
			for hz: float in [-length * 0.27, 0.0, length * 0.27, length * 0.5 + 0.6]:
				var z0 := seg_z
				var z1 := hz - 0.6
				if z1 > z0 + 0.1:
					k.box_xf(Transform3D(Basis(N, S, w), mid + w * ((z0 + z1) * 0.5)), Vector3(0.2, sd.length() + 0.04, z1 - z0), "l149_bark")
				seg_z = hz + 0.6
		else:
			k.box_xf(Transform3D(Basis(N, S, w), mid), Vector3(0.2, sd.length() + 0.04, length), "l149_bark")
	# arched poles of the frame (inside) every 2 m
	var zz := -length * 0.5 + 0.4
	while zz < length * 0.5:
		for i in n:
			var p0: Vector2 = prof[i] * 0.96
			var p1: Vector2 = prof[i + 1] * 0.96
			var sd := p1 - p0
			var S := (u * sd.x + Vector3.UP * sd.y).normalized()
			var N := S.cross(w).normalized()
			d.box_xf(Transform3D(Basis(N, S, w), c + u * ((p0.x + p1.x) * 0.5) + Vector3.UP * ((p0.y + p1.y) * 0.5) + w * zz), Vector3(0.1, sd.length() + 0.05, 0.1), "l149_pole", GeoKit.ALL, false)
		zz += 2.0
	# end walls of vertical bark slats with a door in the middle
	for e: float in [-1.0, 1.0]:
		var x := -W * 0.5 + 0.25
		while x < W * 0.5 - 0.1:
			var hh := H * sqrt(maxf(0.0, 1.0 - pow(2.0 * x / W, 2.0))) - 0.05
			var base := c + u * x + w * (e * length * 0.5)
			if absf(x) < 0.75:
				if hh > 2.3:
					k.box_xf(Transform3D(f[3], base + Vector3.UP * ((2.2 + hh) * 0.5)), Vector3(0.5, hh - 2.2, 0.15), "l149_bark")
			else:
				k.box_xf(Transform3D(f[3], base + Vector3.UP * (hh * 0.5)), Vector3(0.5, hh, 0.15), "l149_bark")
			x += 0.5
		# hide cover: a hanging hide half drawn across the door
		d.box_xf(Transform3D(f[3], c + w * (e * (length * 0.5 + 0.12)) + u * 0.45 + Vector3.UP * 1.1), Vector3(0.6, 2.1, 0.03), "l149_mat", GeoKit.ALL, false)
	# earth floor, sleeping platforms both sides (two tiers), hearths down the centre
	d.box_xf(Transform3D(f[3], c + Vector3.UP * 0.02), Vector3(W - 0.3, 0.04, length - 0.3), "l149_earth", GeoKit.ALL, false)
	for sx: float in [-1.0, 1.0]:
		var pc := c + u * (sx * (W * 0.5 - 0.95))
		k.box_xf(Transform3D(f[3], pc + Vector3.UP * 0.28), Vector3(1.4, 0.56, length - 2.6), "l149_plank")
		d.box_xf(Transform3D(f[3], pc + Vector3.UP * 0.6 + u * (-sx * 0.1)), Vector3(1.1, 0.06, length - 3.0), "l149_mat", GeoKit.ALL, false)
		d.box_xf(Transform3D(f[3], pc + Vector3.UP * 2.25 + u * (sx * 0.25)), Vector3(0.9, 0.08, length - 2.6), "l149_plank", GeoKit.ALL, false)
		var bz := -length * 0.5 + 1.8
		while bz < length * 0.5 - 1.5:
			d.box_xf(Transform3D(f[3], pc + w * bz + Vector3.UP * 1.3 + u * (-sx * 0.68)), Vector3(0.1, 2.6, 0.1), "l149_pole", GeoKit.ALL, false)
			if rng.randf() < 0.5:
				Props.place(L, props, "kenney/mini-dungeon/pot", (pc + w * (bz + 0.8) + Vector3.UP * 2.29) - (spec["body"] as Node3D).position, rad_to_deg(rng.randf() * TAU), 0.35)
			bz += 3.4
	for hz: float in [-length * 0.27, 0.0, length * 0.27]:
		var hp := c + w * hz
		_hearth(hp)
	longhouse_in.append(c)


func _hearth(p: Vector3) -> void:
	for i in 9:
		var a := TAU * i / 9.0
		d.box(p + Vector3(cos(a) * 0.55, 0.1, sin(a) * 0.55), Vector3(0.24, 0.2, 0.2), "l149_stone", GeoKit.ALL, false)
	d.quad(p + Vector3(0, 0.07, 0), Vector3.UP, Vector3(0.38, 0, 0), Vector3(0, 0, 0.38), "l149_ember", Vector2(rng.randf() * 10.0, 0.4), true)
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		d.box_xf(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3(1, 0, 0), 0.35), p + Vector3(cos(a) * 0.15, 0.16, sin(a) * 0.15)), Vector3(0.09, 0.09, 0.6), "l149_husk", GeoKit.ALL, false)
	_flame(p + Vector3(0, 0.1, 0), 0.6)
	fires.append(p + Vector3(0, 0.6, 0))


func _flame(p: Vector3, h: float) -> void:
	for a: float in [0.0, PI * 0.5]:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(h * 0.7, h)
		mi.mesh = qm
		mi.material_override = flame_mat
		mi.position = p + Vector3(0, h * 0.5, 0) - (spec["body"] as Node3D).position
		mi.rotation.y = a
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(spec["body"] as Node3D).add_child(mi)


## The single public house: an open-sided hall under a steep thatched gable roof.
func public_house(c: Vector3, length: float) -> void:
	var W := 11.0
	var eave := 2.6
	var ridge := 6.4
	# floor deck raised a step off the sand
	k.box(c + Vector3(0, 0.15, 0), Vector3(W, 0.3, length), "l149_plank")
	var z := -length * 0.5
	while z <= length * 0.5 + 0.01:
		for sx: float in [-1.0, 1.0]:
			k.box(c + Vector3(sx * (W * 0.5 - 0.2), 0.3 + eave * 0.5, z), Vector3(0.3, eave, 0.3), "l149_pole")
		z += 4.0
	# low log half-walls along the sides with wide openings
	for sx: float in [-1.0, 1.0]:
		for zz: float in [-length * 0.375, length * 0.375]:
			k.box(c + Vector3(sx * (W * 0.5 - 0.2), 0.75, zz), Vector3(0.24, 0.9, length * 0.2), "l149_bark")
	# gable roof
	var half := W * 0.5 + 0.8
	var rise := ridge - eave
	var slope := atan2(rise, half)
	var slen := sqrt(half * half + rise * rise)
	for sx: float in [-1.0, 1.0]:
		var b := Basis(Vector3(0, 0, 1), -sx * slope)
		k.box_xf(Transform3D(b, c + Vector3(sx * half * 0.5, 0.3 + eave + rise * 0.5 - 0.3, 0)), Vector3(slen, 0.3, length + 1.4), "l149_thatch")
	for e: float in [-1.0, 1.0]:
		d.box(c + Vector3(0, 0.3 + ridge - 0.9, e * (length * 0.5)), Vector3(3.0, 1.6, 0.2), "l149_bark", GeoKit.ALL, false)
	d.box(c + Vector3(0, 0.3 + ridge - 0.1, 0), Vector3(0.4, 0.3, length + 1.6), "l149_pole", GeoKit.ALL, false)
	# long tables and benches, a hearth at the far end
	for tz: float in [-3.5, 2.5]:
		k.box(c + Vector3(0, 1.05, tz), Vector3(1.2, 0.08, 4.4), "l149_plank")
		for lx: float in [-0.45, 0.45]:
			d.box(c + Vector3(lx, 0.68, tz), Vector3(0.1, 0.72, 4.0), "l149_pole", GeoKit.ALL, false)
		for bx: float in [-1.05, 1.05]:
			k.box(c + Vector3(bx, 0.72, tz), Vector3(0.4, 0.08, 4.2), "l149_plank")
		for q in 4:
			Props.place(L, props, "kenney/mini-dungeon/pot" if q % 2 == 0 else "kenney/food-kit/bowl", c + Vector3(rng.randf_range(-0.3, 0.3), 1.09, tz + rng.randf_range(-1.8, 1.8)) - (spec["body"] as Node3D).position, rng.randf() * 360.0, 0.18)
	_hearth(c + Vector3(0, 0.3, length * 0.5 - 2.0))
	# board of paper drawings of Coconut Snares, some of them centuries old
	var bp := c + Vector3(-W * 0.5 + 0.45, 1.75, -length * 0.5 + 3.2)
	d.box(bp, Vector3(0.08, 1.3, 2.4), "l149_plank", GeoKit.ALL, false)
	for i in 6:
		var pp := bp + Vector3(0.06, rng.randf_range(-0.38, 0.38), -0.9 + i * 0.36)
		d.quad(pp, Vector3(1, 0, 0), Vector3(0, 0, 0.13), Vector3(0, 0.17, 0), "l149_paper", Vector2.ZERO, true)
		d.quad(pp + Vector3(0.004, 0.02, 0), Vector3(1, 0, 0), Vector3(0, 0, 0.06), Vector3(0, 0.07, 0), "l149_ink", Vector2.ZERO, true)
	notes.append(["l149_snares", "Drawings of Coconut Snares", "Pinned sheets of palm paper, the oldest brown and brittle: drawings of the Coconut Snares the hunters track on the palms of the small, far isles. The Lost Suns have drawn them since the fifteenth century. Their meat is a delicacy here.", bp + Vector3(0.4, -0.6, 0)])
	notes.append(["l149_welcome", "Carved board by the public house", "THE LOST SUNS OF THE COCONUT ISLES. We have lived on this isle some six hundred years. We are neutral to wanderers. We take in only those who truly wish to be one of us; to newcomers we usually offer a house.", c + Vector3(W * 0.5 + 0.6, 1.2, -length * 0.5)])
	d.box(c + Vector3(W * 0.5 + 0.6, 0.8, -length * 0.5), Vector3(0.12, 1.6, 0.9), "l149_plank", GeoKit.ALL, true)
	# the hunters' rack: palm-bark bows and palm spears
	var rk := c + Vector3(W * 0.5 - 0.5, 0.3, length * 0.5 - 4.6)
	d.box(rk + Vector3(0, 1.6, 0), Vector3(0.1, 0.1, 2.2), "l149_pole", GeoKit.ALL, false)
	for i in 5:
		var sp := rk + Vector3(-0.15, 0.0, -0.9 + i * 0.42)
		d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.12), sp + Vector3(0, 1.15, 0)), Vector3(0.04, 2.3, 0.04), "l149_pole", GeoKit.ALL, false)
		d.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.12), sp + Vector3(-0.27, 2.32, 0)), Vector3(0.05, 0.14, 0.05), "l149_stone", GeoKit.ALL, false)
	for i in 3:
		var bw := rk + Vector3(-0.05, 1.3, -0.6 + i * 0.6)
		for sgm in 5:
			var a := -0.9 + sgm * 0.45
			d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), a), bw + Vector3(0, sin(a) * 0.55, -cos(a) * 0.12 + 0.1)), Vector3(0.03, 0.26, 0.03), "l149_bark", GeoKit.ALL, false)
	notes.append(["l149_hunt", "The hunters' rack", "Bows made of thin coconut palm bark, spears cut from the insides of the palms. The hunters go out after Coconut Snares; the ripe coconuts they bring back are shared among the whole community.", rk + Vector3(-0.4, 1.2, 0)])
	# the shared coconut heap
	_coconuts(c + Vector3(-W * 0.5 + 1.4, 0.3, length * 0.5 - 1.6), 40)


func _coconuts(p: Vector3, n: int) -> void:
	for i in n:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.75
		var layer := 0.0 if r > 0.45 else (0.18 if r > 0.2 else 0.34)
		d.cylinder(p + Vector3(cos(a) * r, 0.1 + layer, sin(a) * r), 0.11, 0.2, "l149_husk" if rng.randf() < 0.7 else "l149_green_nut", 6, false)
	coconut_piles.append(p)


## A tree house: a deck in the palms reached by a long timber stair, a small hut on top.
func treehouse(c: Vector3, yaw: float) -> void:
	var f := _frame(c, yaw)
	var u: Vector3 = f[0]
	var w: Vector3 = f[2]
	var b: Basis = f[3]
	var top := 6.2
	var deck := c + Vector3.UP * top
	k.box_xf(Transform3D(b, deck - Vector3(0, 0.12, 0)), Vector3(5.0, 0.24, 5.0), "l149_plank")
	for sx: float in [-2.2, 2.2]:
		for sz: float in [-2.2, 2.2]:
			k.box_xf(Transform3D(b, c + u * sx + w * sz + Vector3.UP * (top * 0.5)), Vector3(0.3, top, 0.3), "l149_pole")
	# railing on three sides, open where the stair arrives (+w side)
	for e: Array in [[u, 2.45, w], [-u, 2.45, w], [-w, 2.45, u]]:
		var nrm: Vector3 = e[0]
		var along: Vector3 = e[2]
		var rp := deck + nrm * float(e[1]) + Vector3.UP * 0.5
		var rb := Basis(Vector3.UP.cross(along), Vector3.UP, along).orthonormalized()
		k.box_xf(Transform3D(rb, rp), Vector3(0.08, 1.0, 5.0), "l149_pole", 0)
		d.box_xf(Transform3D(rb, rp + Vector3.UP * 0.5), Vector3(0.1, 0.1, 5.0), "l149_pole", GeoKit.ALL, false)
		for q in 5:
			d.box(rp + along * (-2.0 + q), Vector3(0.08, 1.0, 0.08), "l149_pole", GeoKit.ALL, false)
	# stair: from the ground along -w up to the deck's +w edge
	var foot := c + w * (2.5 + 8.1) + u * 1.2
	foot.y = IS.h_local(spec, foot.x, foot.z) + 0.02
	var rise := deck.y - foot.y
	var steps := int(round(rise / 0.2))
	var run := 8.1 / steps
	k.stairs(foot, -w, 1.2, rise, steps, "l149_plank", run, false)
	for sx: float in [-0.65, 0.65]:
		var a := foot + u * sx
		var bb := foot - w * 8.1 + Vector3.UP * rise + u * sx
		var dir := (bb - a).normalized()
		var bx := Vector3.UP.cross(dir).normalized()
		d.box_xf(Transform3D(Basis(bx, dir.cross(bx), dir), (a + bb) * 0.5 + Vector3.UP * 0.9), Vector3(0.07, 0.07, a.distance_to(bb)), "l149_pole", GeoKit.ALL, false)
		for q in 5:
			d.box(a.lerp(bb, (q + 0.5) / 5.0) + Vector3.UP * 0.45, Vector3(0.07, 0.9, 0.07), "l149_pole", GeoKit.ALL, false)
	# hut on the deck
	var hc := deck - w * 0.6
	_hut_body(hc, b, 3.0, 2.2, -w)
	treehouse_tops.append(deck + w * 1.6)
	avoid.append(Vector3(c.x, c.z, 4.0))


func hut(c: Vector3, yaw: float) -> void:
	var f := _frame(c, yaw)
	_hut_body(c, f[3], 3.6, 2.3, f[2])


## A coconut-wood hut: log walls, a door facing `door_dir`, a thatched hipped roof.
func _hut_body(c: Vector3, b: Basis, s: float, h: float, door_dir: Vector3) -> void:
	var u := b * Vector3(1, 0, 0)
	var w := b * Vector3(0, 0, 1)
	var sides := [[w, u], [-w, -u], [u, -w], [-u, w]]
	for sd in sides:
		var nrm: Vector3 = sd[0]
		var along: Vector3 = sd[1]
		var a := c + nrm * (s * 0.5) - along * (s * 0.5)
		var bb := c + nrm * (s * 0.5) + along * (s * 0.5)
		var ops := []
		if nrm.dot(door_dir) > 0.9:
			ops = [{"at": s * 0.5, "w": 0.9, "h": 1.9}]
		elif rng.randf() < 0.6:
			ops = [{"at": s * 0.5, "w": 0.6, "h": 0.5, "sill": 1.1}]
		k.wall(a, bb, h, 0.18, "l149_bark", ops)
	# hipped roof: four sloped thatch panels meeting at a ridge point
	var over := 0.6
	var rh := 1.6
	for sd in sides:
		var nrm: Vector3 = sd[0]
		var along: Vector3 = sd[1]
		var half := s * 0.5 + over
		var sl := sqrt(half * half + rh * rh)
		var tilt := atan2(rh, half)
		var bs := Basis(along, Vector3.UP, along.cross(Vector3.UP)).orthonormalized()
		var rot := Basis(along, tilt if bs.z.dot(nrm) > 0.0 else -tilt)
		d.box_xf(Transform3D(rot * bs, c + Vector3.UP * (h + rh * 0.5 - 0.1) + nrm * (half * 0.5)), Vector3(s + over * 2.0 - (0.0), 0.18, sl), "l149_thatch", GeoKit.ALL, false)
	k.box(c + Vector3.UP * (h + 0.05), Vector3(s, 0.1, s), "l149_thatch", 0)
	d.box(c + Vector3.UP * 0.03, Vector3(s - 0.3, 0.04, s - 0.3), "l149_mat", GeoKit.ALL, false)
	avoid.append(Vector3(c.x, c.z, s))


func fire_pit(p: Vector3) -> void:
	for i in 11:
		var a := TAU * i / 11.0
		d.box(p + Vector3(cos(a) * 0.85, 0.12, sin(a) * 0.85), Vector3(0.3, 0.24, 0.26), "l149_stone", GeoKit.ALL, false)
	d.quad(p + Vector3(0, 0.08, 0), Vector3.UP, Vector3(0.6, 0, 0), Vector3(0, 0, 0.6), "l149_ember", Vector2(rng.randf() * 10.0, 0.4), true)
	for i in 4:
		var a := TAU * i / 4.0 + 0.3
		d.box_xf(Transform3D(Basis(Vector3.UP, a) * Basis(Vector3(1, 0, 0), 0.4), p + Vector3(cos(a) * 0.25, 0.2, sin(a) * 0.25)), Vector3(0.12, 0.12, 0.9), "l149_husk", GeoKit.ALL, false)
	_flame(p + Vector3(0, 0.12, 0), 1.0)
	fires.append(p + Vector3(0, 0.9, 0))
	# logs to sit on
	for i in 3:
		var a := TAU * i / 3.0 + rng.randf()
		k.box_xf(Transform3D(Basis(Vector3.UP, a + PI * 0.5), p + Vector3(cos(a) * 2.2, 0.22, sin(a) * 2.2)), Vector3(0.4, 0.4, 1.8), "l149_pole")
	avoid.append(Vector3(p.x, p.z, 3.5))
