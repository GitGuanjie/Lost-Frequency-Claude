class_name GeoKit
extends RefCounted
## Batched architectural geometry: boxes, walls with openings/arches, ramps,
## stairs, cylinders, slabs and emissive panels. Meshes are merged per material
## (one draw call per material per kit); collision uses one StaticBody3D with
## box/convex shapes tagged by footstep surface. UVs are world-projected metres,
## so patterns continue seamlessly across adjacent pieces.

const PX := 1
const NX := 2
const PY := 4
const NY := 8
const PZ := 16
const NZ := 32
const ALL := 63
const SIDES := PX | NX | PZ | NZ

var root: Node3D
var body: StaticBody3D
var _surf: Dictionary = {}
var signature: int = 17
var stats := {"boxes": 0, "tris": 0, "shapes": 0}
var shadows := true


func _init(parent: Node3D, kit_name: String = "Geo") -> void:
	root = Node3D.new()
	root.name = kit_name
	parent.add_child(root)
	body = StaticBody3D.new()
	body.name = "Collision"
	root.add_child(body)


static func surface_for(mat: String) -> String:
	var m := mat.to_lower()
	for pair in [["carpet", "carpet"], ["plush", "plush"], ["tile", "tile"], ["wood", "wood"],
			["metal", "metal"], ["rust", "metal"], ["grate", "metal"], ["grass", "grass"],
			["dirt", "dirt"], ["mud", "dirt"], ["sand", "sand"], ["snow", "snow"], ["ice", "tile"],
			["water", "water"], ["rock", "concrete"], ["marble", "tile"]]:
		if m.contains(pair[0]):
			return pair[1]
	return "concrete"


## Footstep surface under a ray hit (shape metadata), default concrete.
static func surface_at(hit: Dictionary) -> String:
	if hit.is_empty():
		return "concrete"
	var col: Object = hit.get("collider")
	if col == null:
		return "concrete"
	if col.has_meta("surface"):
		return col.get_meta("surface")
	if col is CollisionObject3D:
		var co := col as CollisionObject3D
		var owner_id := co.shape_find_owner(int(hit.get("shape", 0)))
		var owner := co.shape_owner_get_owner(owner_id)
		if owner and owner.has_meta("surface"):
			return owner.get_meta("surface")
	return "concrete"


func _s(mat: String) -> Dictionary:
	if not _surf.has(mat):
		_surf[mat] = {"v": PackedVector3Array(), "n": PackedVector3Array(),
			"uv": PackedVector2Array(), "uv2": PackedVector2Array(), "i": PackedInt32Array()}
	return _surf[mat]


func _uv_for(p: Vector3, n: Vector3, tu: Vector3, tv: Vector3) -> Vector2:
	if absf(n.y) > 0.92:
		return Vector2(p.x, p.z)
	if absf(n.y) < 0.08:
		var t := Vector3(-n.z, 0.0, n.x).normalized()
		return Vector2(p.dot(t), -p.y)
	return Vector2(p.dot(tu.normalized()), p.dot(tv.normalized()))


## Quad from centre c, normal n and half-axis vectors hu, hv (in world space).
func quad(c: Vector3, n: Vector3, hu: Vector3, hv: Vector3, mat: String, uv2 := Vector2.ZERO, local_uv := false) -> void:
	var s := _s(mat)
	var base: int = s["v"].size()
	var corners := [c - hu - hv, c + hu - hv, c + hu + hv, c - hu + hv]
	var luv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for k in 4:
		s["v"].append(corners[k])
		s["n"].append(n)
		s["uv"].append(luv[k] if local_uv else _uv_for(corners[k], n, hu, hv))
		s["uv2"].append(uv2)
	# Godot treats clockwise triangles as front faces
	var flip: bool = (corners[1] - corners[0]).cross(corners[2] - corners[0]).dot(n) > 0.0
	if flip:
		s["i"].append_array([base, base + 2, base + 1, base, base + 3, base + 2])
	else:
		s["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	stats["tris"] += 2


func box_xf(xf: Transform3D, size: Vector3, mat: String, faces: int = ALL, collide: bool = true, surface: String = "") -> void:
	var b := xf.basis
	var h := size * 0.5
	var c := xf.origin
	var ax := b.x.normalized()
	var ay := b.y.normalized()
	var az := b.z.normalized()
	if faces & PX:
		quad(c + ax * h.x, ax, az * h.z, ay * h.y, mat)
	if faces & NX:
		quad(c - ax * h.x, -ax, az * h.z, ay * h.y, mat)
	if faces & PY:
		quad(c + ay * h.y, ay, ax * h.x, az * h.z, mat)
	if faces & NY:
		quad(c - ay * h.y, -ay, ax * h.x, az * h.z, mat)
	if faces & PZ:
		quad(c + az * h.z, az, ax * h.x, ay * h.y, mat)
	if faces & NZ:
		quad(c - az * h.z, -az, ax * h.x, ay * h.y, mat)
	if collide:
		add_box_shape(xf, size, surface if surface != "" else surface_for(mat))
	stats["boxes"] += 1
	signature = hash([signature, c.snapped(Vector3.ONE * 0.01), size.snapped(Vector3.ONE * 0.01), mat])


func box(center: Vector3, size: Vector3, mat: String, faces: int = ALL, collide: bool = true, surface: String = "") -> void:
	box_xf(Transform3D(Basis(), center), size, mat, faces, collide, surface)


## Axis-aligned box from min corner to max corner.
func box_mm(mn: Vector3, mx: Vector3, mat: String, faces: int = ALL, collide: bool = true, surface: String = "") -> void:
	box((mn + mx) * 0.5, (mx - mn).abs(), mat, faces, collide, surface)


func add_box_shape(xf: Transform3D, size: Vector3, surface: String) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf
	cs.set_meta("surface", surface)
	body.add_child(cs)
	stats["shapes"] += 1
	return cs


## Horizontal slab with its top surface at y_top.
func slab(x0: float, z0: float, x1: float, z1: float, y_top: float, thick: float, mat: String, faces: int = ALL, surface: String = "") -> void:
	box_mm(Vector3(minf(x0, x1), y_top - thick, minf(z0, z1)), Vector3(maxf(x0, x1), y_top, maxf(z0, z1)), mat, faces, true, surface)


func _wall_basis(a: Vector3, b: Vector3) -> Basis:
	var dir := (b - a)
	dir.y = 0.0
	dir = dir.normalized()
	var up := Vector3.UP
	var nz := dir.cross(up).normalized()
	return Basis(dir, up, nz)


## Straight wall from a to b (floor points), with rectangular openings.
## openings: [{"at": dist_from_a_centre, "w": width, "h": height, "sill": 0.0}]
func wall(a: Vector3, b: Vector3, height: float, thick: float, mat: String, openings: Array = [], faces: int = ALL, top_mat: String = "") -> void:
	var bas := _wall_basis(a, b)
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length := flat.length()
	if length < 0.01:
		return
	var ops := openings.duplicate()
	ops.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
	var cursor := 0.0
	for op in ops:
		var w: float = op.get("w", 1.0)
		var oh: float = op.get("h", 2.1)
		var sill: float = op.get("sill", 0.0)
		var s0 := clampf(float(op["at"]) - w * 0.5, 0.0, length)
		var s1 := clampf(float(op["at"]) + w * 0.5, 0.0, length)
		if s0 > cursor + 0.001:
			_wall_piece(a, bas, cursor, s0, 0.0, height, thick, mat, faces)
		if sill > 0.001:
			_wall_piece(a, bas, s0, s1, 0.0, sill, thick, mat, faces)
		if sill + oh < height - 0.001:
			_wall_piece(a, bas, s0, s1, sill + oh, height, thick, mat, faces)
		cursor = maxf(cursor, s1)
	if cursor < length - 0.001:
		_wall_piece(a, bas, cursor, length, 0.0, height, thick, mat, faces)


func _wall_piece(a: Vector3, bas: Basis, s0: float, s1: float, y0: float, y1: float, thick: float, mat: String, faces: int) -> void:
	var len := s1 - s0
	var c := a + bas.x * ((s0 + s1) * 0.5) + Vector3.UP * ((y0 + y1) * 0.5)
	box_xf(Transform3D(bas, c), Vector3(len, y1 - y0, thick), mat, faces)


## Wall with round-headed arches. arches: [{"at", "w", "spring"}] where spring is
## the height where the semicircle starts. Arc approximated by vertical slices.
func arch_wall(a: Vector3, b: Vector3, height: float, thick: float, mat: String, arches: Array, slices: int = 14) -> void:
	var bas := _wall_basis(a, b)
	var length := Vector3(b.x - a.x, 0.0, b.z - a.z).length()
	var ops := arches.duplicate()
	ops.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
	var cursor := 0.0
	for op in ops:
		var w: float = op.get("w", 1.4)
		var spring: float = op.get("spring", 1.6)
		var r := w * 0.5
		var s0: float = float(op["at"]) - r
		var s1: float = float(op["at"]) + r
		if s0 > cursor + 0.001:
			_wall_piece(a, bas, cursor, s0, 0.0, height, thick, mat, ALL)
		for k in slices:
			var u0 := s0 + w * float(k) / slices
			var u1 := s0 + w * float(k + 1) / slices
			var um := (u0 + u1) * 0.5 - float(op["at"])
			var arc_y := spring + sqrt(maxf(r * r - um * um, 0.0))
			if arc_y < height - 0.001:
				_wall_piece(a, bas, u0, u1, minf(arc_y, height), height, thick, mat, ALL)
		cursor = s1
	if cursor < length - 0.001:
		_wall_piece(a, bas, cursor, length, 0.0, height, thick, mat, ALL)


## Sloped walkable slab whose top surface runs from a to b.
func ramp(a: Vector3, b: Vector3, width: float, thick: float, mat: String, surface: String = "") -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z).normalized()
	if x.length() < 0.1:
		x = Vector3.RIGHT
	var y := z.cross(x).normalized()
	var c := (a + b) * 0.5 - y * (thick * 0.5)
	box_xf(Transform3D(Basis(x, y, z), c), Vector3(width, thick, d.length()), mat, ALL, true, surface)


## Straight stair. start = floor point at the first riser's centre, dir horizontal.
## Visual treads/risers; smooth ramp collision so the controller never snags.
func stairs(start: Vector3, dir: Vector3, width: float, rise: float, steps: int, mat: String, run: float = 0.28, solid: bool = true) -> void:
	dir.y = 0.0
	dir = dir.normalized()
	var bas := Basis(dir.cross(Vector3.UP).normalized() * -1.0, Vector3.UP, dir)
	# orthonormal check: x = up × dir
	bas = Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir)
	var step_h := rise / steps
	for i in steps:
		var top := step_h * (i + 1)
		var h := top if solid else minf(step_h * 2.0, top)
		var c := start + dir * (run * (i + 0.5)) + Vector3.UP * (top - h * 0.5)
		box_xf(Transform3D(bas, c), Vector3(width, h, run), mat, ALL, false)
	var a := start + Vector3.UP * 0.02
	var b := start + dir * (run * steps) + Vector3.UP * rise
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	add_box_shape(Transform3D(Basis(x, y, z), (a + b) * 0.5 - y * 0.05), Vector3(width, 0.1, (b - a).length()), surface_for(mat))


func cylinder(center: Vector3, radius: float, height: float, mat: String, sides: int = 12, collide: bool = true, caps: bool = true) -> void:
	var s := _s(mat)
	var y0 := center.y - height * 0.5
	var y1 := center.y + height * 0.5
	for k in sides:
		var a0 := TAU * float(k) / sides
		var a1 := TAU * float(k + 1) / sides
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		var base: int = s["v"].size()
		var verts := [center + p0 * radius + Vector3(0, y0 - center.y, 0), center + p1 * radius + Vector3(0, y0 - center.y, 0),
			center + p1 * radius + Vector3(0, y1 - center.y, 0), center + p0 * radius + Vector3(0, y1 - center.y, 0)]
		var norms := [p0, p1, p1, p0]
		var u0 := a0 * radius
		var u1 := a1 * radius
		var uvs := [Vector2(u0, -y0), Vector2(u1, -y0), Vector2(u1, -y1), Vector2(u0, -y1)]
		for q in 4:
			s["v"].append(verts[q])
			s["n"].append(norms[q])
			s["uv"].append(uvs[q])
			s["uv2"].append(Vector2.ZERO)
		var nrm := (p0 + p1).normalized()
		if (verts[1] - verts[0]).cross(verts[2] - verts[0]).dot(nrm) > 0.0:
			s["i"].append_array([base, base + 2, base + 1, base, base + 3, base + 2])
		else:
			s["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])
		if caps:
			_tri_fan(Vector3(center.x, y1, center.z), Vector3(center.x, y1, center.z) + p0 * radius, Vector3(center.x, y1, center.z) + p1 * radius, Vector3.UP, mat)
			_tri_fan(Vector3(center.x, y0, center.z), Vector3(center.x, y0, center.z) + p1 * radius, Vector3(center.x, y0, center.z) + p0 * radius, Vector3.DOWN, mat)
	stats["tris"] += sides * 2
	if collide:
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = radius
		sh.height = height
		cs.shape = sh
		cs.position = center
		cs.set_meta("surface", surface_for(mat))
		body.add_child(cs)
		stats["shapes"] += 1
	signature = hash([signature, center.snapped(Vector3.ONE * 0.01), radius, height, mat])


func _tri_fan(c: Vector3, p: Vector3, q: Vector3, n: Vector3, mat: String) -> void:
	var s := _s(mat)
	var base: int = s["v"].size()
	for v in [c, p, q]:
		s["v"].append(v)
		s["n"].append(n)
		s["uv"].append(Vector2(v.x, v.z))
		s["uv2"].append(Vector2.ZERO)
	if (p - c).cross(q - c).dot(n) > 0.0:
		s["i"].append_array([base, base + 2, base + 1])
	else:
		s["i"].append_array([base, base + 1, base + 2])


## Ceiling light panel (emissive quad facing down). seed>=100 = dead tube.
func panel(center: Vector3, size_x: float, size_z: float, mat: String = "panel", seed_value: float = 0.0, flicker: float = 0.0) -> void:
	quad(center, Vector3.DOWN, Vector3(size_x * 0.5, 0, 0), Vector3(0, 0, size_z * 0.5), mat, Vector2(seed_value, flicker), true)


## Build MeshInstance3D nodes (one per material). Safe to call once per kit.
func commit() -> void:
	for mat in _surf.keys():
		var s: Dictionary = _surf[mat]
		if s["v"].size() == 0:
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s["v"]
		arrays[Mesh.ARRAY_NORMAL] = s["n"]
		arrays[Mesh.ARRAY_TEX_UV] = s["uv"]
		arrays[Mesh.ARRAY_TEX_UV2] = s["uv2"]
		arrays[Mesh.ARRAY_INDEX] = s["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "Mesh_" + str(mat)
		mi.mesh = am
		mi.material_override = MatLib.get_mat(mat)
		if not shadows or str(mat).begins_with("panel") or mat.contains("_panel"):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	_surf.clear()
