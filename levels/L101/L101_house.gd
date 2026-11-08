extends RefCounted
## Level 101 home: a two-storey seaside house on the home lot (x -5.5..5.5,
## z 0..10). Ground floor (F0): hall with the stair, living room and kitchen
## (west), study and dining room (east). First floor (F1): bedroom and
## bathroom (west), a spare room full of boxes (east), landing over the stair.
## Front porch to the street (-Z), back deck to the garden and the dune (+Z).

const X0 := -5.5
const X1 := 5.5
const Z0 := 0.0
const Z1 := 10.0
const F0 := 0.45
const F1 := 3.4
const C1 := 6.0
const STAIR_Z0 := 2.4
const STAIR_STEPS := 16
const STAIR_RUN := 0.28
const KS := 2.05               # Kenney furniture-kit scale to real size

var lvl
var anchors := {}               # name -> Vector3 (furniture spots the level uses)
var lights: Array = []          # [pos, color, energy, range]


func _init(level) -> void:
	lvl = level


func stair_top_z() -> float:
	return STAIR_Z0 + STAIR_STEPS * STAIR_RUN


func build(node: Node3D) -> void:
	var k := GeoKit.new(node, "Home")
	var g := GeoKit.new(node, "HomeGlass")
	_floors(k)
	_exterior(k, g)
	_interior_walls(k)
	_stair(k)
	_porches(k)
	_roof(k, node)
	k.commit()
	g.commit()
	for c in node.get_children():
		if c is MeshInstance3D and str(c.name).contains("Glass"):
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_furnish(node)


func _floors(k: GeoKit) -> void:
	k.box_mm(Vector3(X0 - 0.1, 0.0, Z0 - 0.1), Vector3(X1 + 0.1, F0 - 0.02, Z1 + 0.1), "l101_brick")
	k.slab(X0, Z0, X1, Z1, F0, 0.03, "l101_wood")
	k.slab(X0 + 0.05, 6.05, -1.15, Z1 - 0.05, F0 + 0.005, 0.01, "l101_tile", GeoKit.PY)
	# first floor slab with the stair void (x 0.05..1.1, z 2.4..stair top)
	var tz := stair_top_z()
	k.box_mm(Vector3(X0, F1 - 0.2, Z0), Vector3(0.05, F1, Z1), "l101_wood")
	k.box_mm(Vector3(0.05, F1 - 0.2, Z0), Vector3(X1, F1, STAIR_Z0), "l101_wood")
	k.box_mm(Vector3(0.05, F1 - 0.2, tz), Vector3(X1, F1, Z1), "l101_wood")
	k.box_mm(Vector3(1.1, F1 - 0.2, STAIR_Z0), Vector3(X1, F1, tz), "l101_wood")
	k.slab(X0 + 0.05, 6.05, -1.15, Z1 - 0.05, F1 + 0.005, 0.01, "l101_tile", GeoKit.PY)
	k.box_mm(Vector3(X0, C1, Z0), Vector3(X1, C1 + 0.12, Z1), "l101_paint")


## Exterior walls: siding outside, painted plaster inside (two leaves).
func _ext_wall(k: GeoKit, a: Vector3, b: Vector3, hh: float, ops: Array, inward: Vector3) -> void:
	k.wall(a - inward * 0.05, b - inward * 0.05, hh, 0.1, "l101_sid1", ops)
	k.wall(a + inward * 0.05, b + inward * 0.05, hh, 0.1, "l101_paint", ops)


func _exterior(k: GeoKit, g: GeoKit) -> void:
	var h0 := F1 - F0
	var h1 := C1 - F1 + 0.12
	# ground floor
	_ext_wall(k, Vector3(X0, F0, Z0), Vector3(X1, F0, Z0), h0, [
		{"at": 0.9, "w": 1.1, "h": 1.4, "sill": 0.9}, {"at": 3.5, "w": 1.1, "h": 1.4, "sill": 0.9},
		{"at": 5.5, "w": 1.0, "h": 2.15, "sill": 0.0}, {"at": 8.8, "w": 1.5, "h": 1.4, "sill": 0.9}], Vector3(0, 0, 1))
	_ext_wall(k, Vector3(X0, F0, Z1), Vector3(X1, F0, Z1), h0, [
		{"at": 1.9, "w": 1.6, "h": 1.0, "sill": 1.15}, {"at": 5.0, "w": 0.95, "h": 2.15, "sill": 0.0},
		{"at": 8.8, "w": 1.8, "h": 2.2, "sill": 0.0}], Vector3(0, 0, -1))
	_ext_wall(k, Vector3(X0, F0, Z0), Vector3(X0, F0, Z1), h0, [
		{"at": 3.0, "w": 1.2, "h": 1.4, "sill": 0.9}, {"at": 8.2, "w": 0.9, "h": 1.0, "sill": 1.15}], Vector3(1, 0, 0))
	_ext_wall(k, Vector3(X1, F0, Z0), Vector3(X1, F0, Z1), h0, [
		{"at": 2.7, "w": 1.2, "h": 1.4, "sill": 0.9}, {"at": 7.8, "w": 1.2, "h": 1.4, "sill": 0.9}], Vector3(-1, 0, 0))
	# first floor
	_ext_wall(k, Vector3(X0, F1, Z0), Vector3(X1, F1, Z0), h1, [
		{"at": 0.9, "w": 1.1, "h": 1.3, "sill": 0.9}, {"at": 3.5, "w": 1.1, "h": 1.3, "sill": 0.9},
		{"at": 5.5, "w": 0.8, "h": 1.0, "sill": 1.1}, {"at": 7.9, "w": 1.1, "h": 1.3, "sill": 0.9}, {"at": 9.9, "w": 1.1, "h": 1.3, "sill": 0.9}], Vector3(0, 0, 1))
	_ext_wall(k, Vector3(X0, F1, Z1), Vector3(X1, F1, Z1), h1, [
		{"at": 2.2, "w": 0.8, "h": 0.8, "sill": 1.4}, {"at": 5.5, "w": 0.9, "h": 1.3, "sill": 0.9},
		{"at": 8.8, "w": 1.2, "h": 1.3, "sill": 0.9}], Vector3(0, 0, -1))
	_ext_wall(k, Vector3(X0, F1, Z0), Vector3(X0, F1, Z1), h1, [{"at": 3.0, "w": 1.1, "h": 1.3, "sill": 0.9}], Vector3(1, 0, 0))
	_ext_wall(k, Vector3(X1, F1, Z0), Vector3(X1, F1, Z1), h1, [{"at": 5.0, "w": 1.1, "h": 1.3, "sill": 0.9}], Vector3(-1, 0, 0))
	# glazing and frames (front/back: along X; sides: along Z)
	for w in [[-4.6, F0, 1.1, 1.4, 0.9], [-2.0, F0, 1.1, 1.4, 0.9], [3.3, F0, 1.5, 1.4, 0.9],
			[-4.6, F1, 1.1, 1.3, 0.9], [-2.0, F1, 1.1, 1.3, 0.9], [0.0, F1, 0.8, 1.0, 1.1], [2.4, F1, 1.1, 1.3, 0.9], [4.4, F1, 1.1, 1.3, 0.9]]:
		_pane(k, g, Vector3(w[0], w[1] + w[4] + w[3] * 0.5, Z0), w[2], w[3], true)
	for w in [[-3.6, F0, 1.6, 1.0, 1.15], [-3.3, F1, 0.8, 0.8, 1.4], [0.0, F1, 0.9, 1.3, 0.9], [3.3, F1, 1.2, 1.3, 0.9]]:
		_pane(k, g, Vector3(w[0], w[1] + w[4] + w[3] * 0.5, Z1), w[2], w[3], true)
	for w in [[X0, F0, 3.0, 1.2, 1.4, 0.9], [X0, F0, 8.2, 0.9, 1.0, 1.15], [X1, F0, 2.7, 1.2, 1.4, 0.9], [X1, F0, 7.8, 1.2, 1.4, 0.9],
			[X0, F1, 3.0, 1.1, 1.3, 0.9], [X1, F1, 5.0, 1.1, 1.3, 0.9]]:
		_pane(k, g, Vector3(w[0], w[1] + w[5] + w[4] * 0.5, w[2]), w[3], w[4], false)
	# door leaves standing open
	_leaf(k, Vector3(0.48, F0, 0.12), true, 1.0)
	_leaf(k, Vector3(-0.5 + 0.45, F0, 9.88), true, 0.95)


func _pane(k: GeoKit, g: GeoKit, c: Vector3, w: float, hh: float, along_x: bool) -> void:
	if along_x:
		g.box(c, Vector3(w, hh, 0.02), "l101_clear")
		k.box(c, Vector3(0.04, hh, 0.06), "l101_trim", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(s * w * 0.5, 0, 0), Vector3(0.07, hh, 0.24), "l101_trim", GeoKit.ALL, false)
			k.box(c + Vector3(0, s * hh * 0.5, 0), Vector3(w, 0.07, 0.24), "l101_trim", GeoKit.ALL, false)
	else:
		g.box(c, Vector3(0.02, hh, w), "l101_clear")
		k.box(c, Vector3(0.06, hh, 0.04), "l101_trim", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(0, 0, s * w * 0.5), Vector3(0.24, hh, 0.07), "l101_trim", GeoKit.ALL, false)
			k.box(c + Vector3(0, s * hh * 0.5, 0), Vector3(0.24, 0.07, w), "l101_trim", GeoKit.ALL, false)


## An open door leaf, swung back against the wall beside its opening.
func _leaf(k: GeoKit, hinge: Vector3, along_z: bool, w: float) -> void:
	var sz := Vector3(0.04, 2.08, w * 0.95) if along_z else Vector3(w * 0.95, 2.08, 0.04)
	var off := Vector3(0, 0, w * 0.48) if along_z else Vector3(w * 0.48, 0, 0)
	k.box(hinge + off + Vector3(0, 1.04, 0), sz, "l101_door", GeoKit.ALL, false)


func _interior_walls(k: GeoKit) -> void:
	var h0 := F1 - F0 - 0.2
	var h1 := C1 - F1
	k.wall(Vector3(-1.1, F0, Z0 + 0.1), Vector3(-1.1, F0, Z1 - 0.1), h0, 0.12, "l101_paint", [
		{"at": 2.9, "w": 1.6, "h": 2.2, "sill": 0.0}, {"at": 7.9, "w": 0.9, "h": 2.1, "sill": 0.0}])
	k.wall(Vector3(1.1, F0, Z0 + 0.1), Vector3(1.1, F0, Z1 - 0.1), h0, 0.12, "l101_paint", [
		{"at": 1.2, "w": 0.85, "h": 2.1, "sill": 0.0}, {"at": 8.5, "w": 0.9, "h": 2.1, "sill": 0.0}])
	k.wall(Vector3(X0 + 0.1, F0, 6.0), Vector3(-1.16, F0, 6.0), h0, 0.12, "l101_paint", [{"at": 3.5, "w": 1.4, "h": 2.2, "sill": 0.0}])
	k.wall(Vector3(1.16, F0, 5.5), Vector3(X1 - 0.1, F0, 5.5), h0, 0.12, "l101_paint", [{"at": 3.2, "w": 0.85, "h": 2.1, "sill": 0.0}])
	k.wall(Vector3(-1.1, F1, Z0 + 0.1), Vector3(-1.1, F1, Z1 - 0.1), h1, 0.12, "l101_paint", [
		{"at": 1.9, "w": 0.85, "h": 2.1, "sill": 0.0}, {"at": 7.9, "w": 0.8, "h": 2.1, "sill": 0.0}])
	k.wall(Vector3(1.1, F1, Z0 + 0.1), Vector3(1.1, F1, Z1 - 0.1), h1, 0.12, "l101_paint", [{"at": 8.5, "w": 0.85, "h": 2.1, "sill": 0.0}])
	k.wall(Vector3(X0 + 0.1, F1, 6.0), Vector3(-1.16, F1, 6.0), h1, 0.12, "l101_paint")
	_leaf(k, Vector3(-1.04, F1, 1.0), true, 0.85)
	_leaf(k, Vector3(-1.04, F1, 8.3), true, 0.8)
	_leaf(k, Vector3(1.04, F0, 0.32), true, 0.85)
	# baseboards in the hall
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 1.03, F0 + 0.06, 5.0), Vector3(0.02, 0.12, 9.8), "l101_trim", GeoKit.ALL, false)


func _stair(k: GeoKit) -> void:
	k.stairs(Vector3(0.575, F0, STAIR_Z0), Vector3(0, 0, 1), 0.95, F1 - F0, STAIR_STEPS, "l101_wood", STAIR_RUN, true)
	# stringer on the open side and a handrail
	var tz := stair_top_z()
	var a := Vector3(0.08, F0 + 0.9, STAIR_Z0)
	var b := Vector3(0.08, F1 + 0.9, tz)
	var dir := (b - a).normalized()
	k.box_xf(Transform3D(Basis.looking_at(dir, Vector3.UP), (a + b) * 0.5), Vector3(0.06, 0.06, (b - a).length()), "l101_trim", GeoKit.ALL, false)
	for i in 9:
		var t := (i + 0.5) / 9.0
		var p := a.lerp(b, t)
		k.box(Vector3(p.x, p.y - 0.45, p.z), Vector3(0.04, 0.9, 0.04), "l101_trim", GeoKit.ALL, false)
	# landing guard rail around the void
	_rail(k, Vector3(0.08, F1, STAIR_Z0), Vector3(0.08, F1, tz - 0.9))
	_rail(k, Vector3(0.08, F1, STAIR_Z0), Vector3(1.04, F1, STAIR_Z0))


func _rail(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var c := (a + b) * 0.5
	var l := a.distance_to(b)
	var along_z := absf(b.z - a.z) > absf(b.x - a.x)
	var sz := Vector3(0.06, 0.06, l) if along_z else Vector3(l, 0.06, 0.06)
	k.box(c + Vector3(0, 0.95, 0), sz, "l101_trim", GeoKit.ALL, false)
	var n := int(l / 0.14)
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		k.box(p + Vector3(0, 0.47, 0), Vector3(0.03, 0.94, 0.03), "l101_trim", GeoKit.ALL, false)
	var col := Vector3(0.1, 1.0, l) if along_z else Vector3(l, 1.0, 0.1)
	k.add_box_shape(Transform3D(Basis(), c + Vector3(0, 0.5, 0)), col, "wood")


func _porches(k: GeoKit) -> void:
	# front porch with a small roof on two posts, three steps to the path
	k.box_mm(Vector3(-2.4, 0.0, -2.0), Vector3(2.4, F0, 0.0), "l101_deck")
	for i in 3:
		var y := F0 * (2 - i) / 3.0
		k.box_mm(Vector3(-1.0, 0.0, -2.0 - 0.3 * (i + 1)), Vector3(1.0, y + 0.0001 if y > 0.0 else 0.05, -2.0 - 0.3 * i), "l101_deck")
	k.box(Vector3(0, F0 + 2.75, -1.05), Vector3(5.2, 0.12, 2.3), "l101_trim", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 2.25, F0 + 1.37, -1.95), Vector3(0.14, 2.75, 0.14), "l101_trim")
	k.box_mm(Vector3(-0.6, 0.0, -4.0), Vector3(0.6, 0.06, -2.9), "l101_walk", GeoKit.PY, false)
	# back deck facing the dune, with a rail and steps down to the lawn
	k.box_mm(Vector3(-2.2, 0.0, Z1), Vector3(5.2, F0, Z1 + 3.0), "l101_deck")
	for i in 3:
		var y := F0 * (2 - i) / 3.0
		k.box_mm(Vector3(0.0, 0.0, Z1 + 3.0 + 0.3 * i), Vector3(1.6, maxf(y, 0.05), Z1 + 3.3 + 0.3 * i), "l101_deck")
	_rail(k, Vector3(-2.15, F0, Z1 + 0.1), Vector3(-2.15, F0, Z1 + 2.95))
	_rail(k, Vector3(-2.15, F0, Z1 + 2.95), Vector3(-0.05, F0, Z1 + 2.95))
	_rail(k, Vector3(1.65, F0, Z1 + 2.95), Vector3(5.15, F0, Z1 + 2.95))
	_rail(k, Vector3(5.15, F0, Z1 + 0.1), Vector3(5.15, F0, Z1 + 2.95))
	# the garden path to the dune boardwalk
	k.box_mm(Vector3(0.1, 0.0, Z1 + 3.9), Vector3(1.3, 0.05, 14.6), "l101_walk", GeoKit.PY, false)


## Gable roof along X plus the gable triangles (siding).
func _roof(k: GeoKit, node: Node3D) -> void:
	var pitch := deg_to_rad(32.0)
	var d := Z1 - Z0
	var rise := d * 0.5 * tan(pitch)
	var over := 0.5
	var half := d * 0.5 + over
	var sl := half / cos(pitch)
	var zm := (Z0 + Z1) * 0.5
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.RIGHT, s * pitch)
		var mid := Vector3(0, C1 + 0.12 + rise - half * tan(pitch) * 0.5 + 0.08 + 0.45, zm + s * half * 0.5)
		k.box_xf(Transform3D(b, mid), Vector3(X1 - X0 + over * 2.0, 0.16, sl), "l101_roof2", GeoKit.ALL, false)
	k.box(Vector3(3.2, C1 + rise + 1.3, zm - 1.4), Vector3(0.8, 2.4, 0.8), "l101_brick", GeoKit.ALL, false)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-1.0, 1.0]:
		var x: float = X0 if sx < 0.0 else X1
		var a := Vector3(x, C1 + 0.12, Z0)
		var b2 := Vector3(x, C1 + 0.12, Z1)
		var c := Vector3(x, C1 + 0.12 + rise + 0.45, zm)
		for v in ([a, c, b2] if sx > 0.0 else [a, b2, c]):
			st.set_normal(Vector3(sx, 0, 0))
			st.set_uv(Vector2(v.z, v.y) / 2.2)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l101_sid1")
	node.add_child(mi)


# ---------------------------------------------------------------- furniture

func _ph(node: Node3D, id: String, p: Vector3, yaw: float, collide: bool = false) -> Node3D:
	return Props.place(lvl, node, "ph/" + id, p, yaw, 0.0, collide)


func _kn(node: Node3D, name: String, p: Vector3, yaw: float, collide: bool = false, mult: float = 1.0) -> Node3D:
	var id := "kenney/furniture-kit/" + name
	var hh := Props.bounds(id).size.y * KS * mult
	return Props.place(lvl, node, id, p, yaw, maxf(hh, 0.01), collide)


func _furnish(n: Node3D) -> void:
	# hall: doormat, coat rack, a console with the photograph, a clock
	_kn(n, "rugdoormat", Vector3(0, F0 + 0.005, 0.45), 0.0)
	_kn(n, "coatrackstanding", Vector3(-0.72, F0, 0.5), 0.0, false, 1.15)
	_ph(n, "ClassicNightstand_01", Vector3(-0.82, F0, 1.7), 90.0, true)
	anchors["photo"] = Vector3(-0.82, F0 + 0.72, 1.7)
	anchors["coatrack"] = Vector3(-0.72, F0, 0.5)
	_ph(n, "vintage_telephone_wall_clock", Vector3(-1.02, F0 + 1.55, 4.4), 90.0)
	# living room
	_kn(n, "rugrectangle", Vector3(-3.3, F0 + 0.005, 3.2), 0.0)
	_ph(n, "Sofa_01", Vector3(-3.5, F0, 5.35), 180.0, true)
	_ph(n, "coffee_table_round_01", Vector3(-3.4, F0, 3.4), 0.0, true)
	_ph(n, "ArmChair_01", Vector3(-4.75, F0, 2.4), 125.0, true)
	_kn(n, "cabinettelevision", Vector3(-3.3, F0, 0.32), 0.0, true)
	_ph(n, "Television_01", Vector3(-3.3, F0 + 0.62, 0.32), 0.0)
	_ph(n, "wooden_bookshelf_worn", Vector3(-5.1, F0, 1.0), 90.0, true)
	anchors["books"] = Vector3(-4.8, F0, 1.0)
	_kn(n, "lamproundfloor", Vector3(-5.05, F0, 5.55), 0.0, false, 1.0)
	_kn(n, "pottedplant", Vector3(-1.5, F0, 0.5), 0.0, false, 1.0)
	# kitchen: counter run under the window, fridge, a small table
	var cz := Z1 - 0.1 - 0.46
	var xs := [-5.0, -4.12, -3.24, -2.36]
	var parts := ["kitchencabinetdrawer", "kitchensink", "kitchenstove", "kitchencabinet"]
	for i in 4:
		_kn(n, parts[i], Vector3(xs[i], F0, cz), 180.0, true)
	for i in [0, 2, 3]:
		_kn(n, "kitchencabinetupper", Vector3(xs[i], F0 + 1.45, Z1 - 0.1 - 0.23), 180.0)
	_kn(n, "kitchenfridgelarge", Vector3(-4.95, F0, 6.75), 90.0, true)
	anchors["fridge"] = Vector3(-4.6, F0 + 1.0, 6.75)
	_kn(n, "kitchenmicrowave", Vector3(-2.36, F0 + 0.92, cz - 0.05), 180.0)
	_kn(n, "kitchencoffeemachine", Vector3(-5.05, F0 + 0.92, cz), 180.0)
	_kn(n, "table", Vector3(-3.0, F0, 7.7), 0.0, true, 1.1)
	_kn(n, "chair", Vector3(-3.0, F0, 7.0), 0.0, true)
	_kn(n, "chair", Vector3(-3.0, F0, 8.4), 180.0, true)
	anchors["cup"] = Vector3(-3.0, F0 + 0.75, 7.7)
	# study: desk with the computer, the world map, a bookcase
	_kn(n, "desk", Vector3(4.95, F0, 2.7), -90.0, true)
	_kn(n, "computerscreen", Vector3(5.15, F0 + 0.78, 2.7), -90.0)
	_kn(n, "computerkeyboard", Vector3(4.8, F0 + 0.78, 2.7), -90.0)
	_kn(n, "chairdesk", Vector3(4.15, F0, 2.6), 90.0, true)
	anchors["computer"] = Vector3(4.8, F0 + 1.0, 2.7)
	_kn(n, "bookcaseclosedwide", Vector3(1.85, F0, 4.95), 180.0, true)
	anchors["map"] = Vector3(3.6, F0 + 1.6, 5.42)
	_ph(n, "GreenChair_01", Vector3(1.8, F0, 0.9), 45.0, true)
	# dining room
	_ph(n, "dining_table", Vector3(3.3, F0, 7.7), 0.0, true)
	for c in [[2.6, 6.75, 0.0], [4.0, 6.75, 0.0], [2.6, 8.65, 180.0], [4.0, 8.65, 180.0]]:
		_ph(n, "dining_chair_02", Vector3(c[0], F0, c[1]), c[2], true)
	_ph(n, "drawer_cabinet", Vector3(5.2, F0, 7.0), -90.0, true)
	_ph(n, "wall_clock", Vector3(1.18, F0 + 1.9, 7.6), 90.0)
	# bedroom (first floor, west front)
	_kn(n, "beddouble", Vector3(-4.3, F1, 3.0), 90.0, true)
	anchors["bed"] = Vector3(-4.3, F1, 3.0)
	_ph(n, "ClassicNightstand_01", Vector3(-5.18, F1, 1.55), 90.0, true)
	_ph(n, "ClassicNightstand_01", Vector3(-5.18, F1, 4.45), 90.0, true)
	_kn(n, "lamproundfloor", Vector3(-5.18, F1 + 0.7, 1.55), 0.0, false, 0.35)
	_kn(n, "bookcasecloseddoors", Vector3(-2.3, F1, 5.68), 180.0, true, 1.15)
	_kn(n, "bookcasecloseddoors", Vector3(-3.15, F1, 5.68), 180.0, true, 1.15)
	_ph(n, "drawer_cabinet", Vector3(-1.45, F1, 4.4), -90.0, true)
	_kn(n, "ruground", Vector3(-2.7, F1 + 0.005, 2.6), 0.0)
	# bathroom
	_kn(n, "bathtub", Vector3(-4.3, F1, 9.35), 0.0, true, 0.8)
	_kn(n, "toilet", Vector3(-5.1, F1, 6.75), 90.0, true)
	_kn(n, "bathroomsink", Vector3(-2.3, F1, 6.35), 0.0, true)
	_kn(n, "bathroommirror", Vector3(-2.3, F1 + 1.35, 6.08), 0.0)
	# spare room: boxes nobody unpacked
	_kn(n, "bedsingle", Vector3(4.6, F1, 1.6), -90.0, true)
	var r := RandomNumberGenerator.new()
	r.seed = 1017
	for i in 9:
		var p := Vector3(r.randf_range(2.0, 4.6), F1, r.randf_range(5.6, 9.3))
		_ph(n, "cardboard_box_01", p, r.randf_range(0, 90), i % 3 == 0)
		if i % 3 == 0:
			_ph(n, "cardboard_box_01", p + Vector3(0, 0.34, 0), r.randf_range(0, 90))
	_kn(n, "bookcaseopen", Vector3(1.45, F1, 4.0), 90.0, true)
	_ph(n, "vintage_radio_transceiver", Vector3(4.6, F1 + 0.0, 4.0), -90.0)
	# back deck and garden
	_kn(n, "loungechair", Vector3(3.6, F0, Z1 + 1.6), 180.0, true)
	anchors["deck"] = Vector3(3.6, F0, Z1 + 1.6)
	_ph(n, "wooden_picnic_table", Vector3(-3.4, 0.0, 13.6), 90.0, true)
	# framed pictures and curtains: a lived-in house
	var pics := [[Vector3(-5.37, F0 + 1.6, 4.6), 90.0, Vector2(0.9, 0.6)], [Vector3(-1.17, F0 + 1.55, 5.0), -90.0, Vector2(0.5, 0.7)],
		[Vector3(-3.2, F1 + 1.6, 5.9), 180.0, Vector2(0.8, 0.55)], [Vector3(1.17, F0 + 1.6, 3.6), 90.0, Vector2(0.45, 0.6)],
		[Vector3(-0.8, F1 + 1.6, 9.9), 180.0, Vector2(0.6, 0.45)], [Vector3(3.3, F0 + 1.6, 5.56), 0.0, Vector2(0.7, 0.5)]]
	var pk := GeoKit.new(n, "Pictures")
	for i in pics.size():
		var pc: Array = pics[i]
		var c: Vector3 = pc[0]
		var sz: Vector2 = pc[2]
		var yaw := deg_to_rad(float(pc[1]))
		var bas := Basis(Vector3.UP, yaw)
		pk.box_xf(Transform3D(bas, c), Vector3(sz.x + 0.08, sz.y + 0.08, 0.03), "l101_door", GeoKit.ALL, false)
		pk.box_xf(Transform3D(bas, c + bas.z * 0.016), Vector3(sz.x, sz.y, 0.004), "l101_pic%d" % (i % 3), GeoKit.ALL, false)
	for w in [[-4.6, Z0 + 0.16], [-2.0, Z0 + 0.16]]:
		for s2 in [-1.0, 1.0]:
			pk.box(Vector3(w[0] + s2 * 0.68, F0 + 1.55, w[1]), Vector3(0.32, 1.9, 0.05), "l101_drape", GeoKit.ALL, false)
			pk.box(Vector3(w[0] + s2 * 0.68, F1 + 1.5, w[1]), Vector3(0.32, 1.8, 0.05), "l101_drape", GeoKit.ALL, false)
	pk.commit()
	# ceiling lights (motivated warm pools; pooled lights stay short)
	for l in [[Vector3(-3.3, F1 - 0.25, 3.0), 0.9], [Vector3(-3.3, F1 - 0.25, 8.0), 1.0], [Vector3(0.0, F1 - 0.25, 1.0), 0.7],
			[Vector3(3.3, F1 - 0.25, 2.7), 0.8], [Vector3(3.3, F1 - 0.25, 7.7), 0.9], [Vector3(-3.3, C1 - 0.25, 3.0), 0.8],
			[Vector3(-3.3, C1 - 0.25, 8.0), 0.7], [Vector3(3.3, C1 - 0.25, 5.0), 0.6], [Vector3(-0.5, C1 - 0.25, 8.5), 0.6]]:
		_kn(n, "lampsquareceiling", (l[0] as Vector3) + Vector3(0, -0.2, 0), 0.0)
		lights.append([(l[0] as Vector3) + Vector3(0, -0.35, 0), Color(1.0, 0.86, 0.68), l[1], 4.6])
