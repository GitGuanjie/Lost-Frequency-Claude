extends RefCounted
## Level 0.1 shared dimensions and a tiny visual-only quad mesh builder.
##
## World layout (ADAPTATION; the page gives no map, only "an extremely large,
## spherical shell" around "an enormous hollowed-out section"):
##  - The cavity (the old "central vacuole" of the vignette) is a sphere of
##    radius R centred at CC. The Inner Gallery stands on its inner face at
##    latitude 25 degrees, so the face overhangs: every deck juts out over the
##    one below, exactly as a sphere's upper half does.
##  - The Outer Ring threshold sits ~1.9 km further out along the same radius
##    (the page: "the width of dozens of city blocks"), where the hull meets
##    Level 0. (It sits above y=0: the framework kills the player below -400.)
##    A radial lift joins the two; the shell in between is not walkable.

const R := 1400.0                 # cavity radius (m)
const LAT := 25.0                 # gallery latitude on the cavity wall (deg)
const DY := 4.5                   # deck pitch
const SLAB := 0.6                 # deck slab thickness (ceiling plenum included)
const DECKS := 4                  # walkable decks in the gallery
const GX := 30.0                  # gallery half width (x)
const ZW := -8.0                  # corridor wall (module fronts)
const ZB := -20.0                 # module back wall
const ATR := 7.0                  # atrium half width
const ATZ := -3.0                 # atrium back edge on decks 1..3
const STA := 9.0                  # stair column inner x (|x|)
const STW := 2.2                  # stair width
const ST_LO := -5.5               # stair foot (z) on the lower deck
const ST_HI := 1.0                # stair head (z) on the upper deck
const TH := Vector3(0.0, 800.0, -1720.0)    # Outer Ring origin: ~1.9 km out along the gallery radius
const L0H := 3.4                  # Level 0 floor pitch seen from the hull (2.75 m rooms)
const L0Y := -0.54                # Level 0 floor top at the bridge (local to TH)
const L0Z := -60.0                # Level 0 cliff face (local z), across the gulf
const HULLZ := -6.0               # outer hull inner face (local z)


static func cc() -> Vector3:
	var a := deg_to_rad(LAT)
	return Vector3(0.0, -R * sin(a), 2.0 + R * cos(a))


## z of the cavity wall at (x, y): the glass line of a deck at height y.
static func z_edge(x: float, y: float) -> float:
	var c := cc()
	var dy := y - c.y
	return c.z - sqrt(maxf(R * R - x * x - dy * dy, 1.0))


static func deck_y(k: int) -> float:
	return DY * k


static func edge(k: int) -> float:
	return z_edge(0.0, deck_y(k))


static func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([a, b, salt])) % 100000) / 100000.0


# ---------------------------------------------------------------- quads

## Visual-only batched quads with arbitrary corners (one surface per material).
class Quads:
	var surf: Dictionary = {}

	func _s(mat: String) -> Dictionary:
		if not surf.has(mat):
			surf[mat] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "uv2": PackedVector2Array(), "i": PackedInt32Array()}
		return surf[mat]

	## Corners in order around the face; n is the wanted facing.
	func q(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, mat: String, uv2 := Vector2.ZERO, local_uv := false) -> void:
		var s := _s(mat)
		var base: int = s["v"].size()
		var t := (b - a).normalized()
		var luv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		var k := 0
		for p in [a, b, c, d]:
			s["v"].append(p)
			s["n"].append(n)
			if local_uv:
				s["uv"].append(luv[k])
			elif absf(n.y) > 0.9:
				s["uv"].append(Vector2(p.x, p.z))
			else:
				s["uv"].append(Vector2(p.dot(t), -p.y))
			s["uv2"].append(uv2)
			k += 1
		if (b - a).cross(c - a).dot(n) > 0.0:
			s["i"].append_array([base, base + 2, base + 1, base, base + 3, base + 2])
		else:
			s["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])

	## Axis box (visual only), faces chosen by GeoKit flags.
	func box(mn: Vector3, mx: Vector3, mat: String, faces: int = 63) -> void:
		var x0 := mn.x
		var y0 := mn.y
		var z0 := mn.z
		var x1 := mx.x
		var y1 := mx.y
		var z1 := mx.z
		if faces & 1:
			q(Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3.RIGHT, mat)
		if faces & 2:
			q(Vector3(x0, y0, z1), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3.LEFT, mat)
		if faces & 4:
			q(Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.UP, mat)
		if faces & 8:
			q(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3.DOWN, mat)
		if faces & 16:
			q(Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK, mat)
		if faces & 32:
			q(Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD, mat)

	func mesh_for(mat: String) -> ArrayMesh:
		var s: Dictionary = surf[mat]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s["v"]
		arrays[Mesh.ARRAY_NORMAL] = s["n"]
		arrays[Mesh.ARRAY_TEX_UV] = s["uv"]
		arrays[Mesh.ARRAY_TEX_UV2] = s["uv2"]
		arrays[Mesh.ARRAY_INDEX] = s["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return am

	## One MeshInstance3D per material under parent (no collision).
	func commit(parent: Node3D, prefix: String, shadows := false) -> void:
		for mat in surf.keys():
			if (surf[mat]["v"] as PackedVector3Array).is_empty():
				continue
			var mi := MeshInstance3D.new()
			mi.name = prefix + "_" + str(mat)
			mi.mesh = mesh_for(mat)
			mi.material_override = MatLib.get_mat(mat)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mi)
		surf.clear()

	## Same meshes, instanced at many transforms (MultiMesh per material).
	func commit_multi(parent: Node3D, prefix: String, xforms: Array) -> void:
		for mat in surf.keys():
			if (surf[mat]["v"] as PackedVector3Array).is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh_for(mat)
			mm.instance_count = xforms.size()
			for i in xforms.size():
				mm.set_instance_transform(i, xforms[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = prefix + "_" + str(mat)
			mmi.multimesh = mm
			mmi.material_override = MatLib.get_mat(mat)
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mmi)
		surf.clear()
