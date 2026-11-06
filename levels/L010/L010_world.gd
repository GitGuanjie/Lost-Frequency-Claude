extends RefCounted
## Level 10 world model (pure, seeded, cached). Farmland as an irregular grid of
## plots bounded by hedge / tree lines; some boundary lines carry a dirt track
## on their + side; rolling heights with every hollow below one fixed water
## level flooded (SOURCE: "bodies of water ... below one consistent elevation");
## farmyards with barns, stables, sheds and cart sheds sit on levelled pads
## beside the tracks. Shared by near chunks, the far LOD ring and crop tiles.

const SX := 112.0
const SZ := 96.0
const WATER_Y := -2.6
const HEDGE_H := 1.55
const TOFF := 4.6
const THW := 2.1
const CELL := 2.0
const CANOPY := [0.0, 0.72, 0.6, 1.02]
const LAKE := Vector2(-74.0, -112.0)
const LAKE_R := 58.0
const HOME := Vector2i(0, -1)
const CANOLA_HOME := Vector2i(2, -3)
## [footprint x, footprint z] per structure kind
const DIMS := {"barn": Vector2(12.0, 26.0), "stable": Vector2(8.0, 21.0), "shed": Vector2(4.0, 5.0), "cart": Vector2(7.0, 11.0)}

var sd := 0
var qa := false
var n1 := FastNoiseLite.new()
var n2 := FastNoiseLite.new()
var _xl := {}
var _zl := {}
var _pl := {}
var pit := Vector2(17.0, -29.0)


func _init(seed_v: int, qa_mode: bool) -> void:
	sd = seed_v
	qa = qa_mode
	for n in [n1, n2]:
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
	n1.seed = seed_v
	n1.frequency = 1.0 / 300.0
	n2.seed = seed_v + 7
	n2.frequency = 1.0 / 110.0


func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([sd, a, b, salt])) % 100003) / 100003.0


# ----------------------------------------------------------------- grid

func xline(i: int) -> float:
	if not _xl.has(i):
		_xl[i] = 0.0 if i == 0 else i * SX + (h01(i, 0, 1) - 0.5) * 34.0
	return _xl[i]


func zline(j: int) -> float:
	if not _zl.has(j):
		_zl[j] = 0.0 if j == 0 else j * SZ + (h01(0, j, 2) - 0.5) * 30.0
	return _zl[j]


func xi(x: float) -> int:
	var i := floori(x / SX)
	while x < xline(i):
		i -= 1
	while x >= xline(i + 1):
		i += 1
	return i


func zi(z: float) -> int:
	var j := floori(z / SZ)
	while z < zline(j):
		j -= 1
	while z >= zline(j + 1):
		j += 1
	return j


## Does vertical line i (horizontal line j) carry a dirt track on its + side?
func xtrack(i: int) -> bool:
	return i == 0 or (i != -1 and i != 1 and h01(i, 0, 3) < 0.3)


func ztrack(j: int) -> bool:
	return j == -1 or (j != 0 and j != -2 and h01(0, j, 4) < 0.3)


## Boundary kind of vertical line i between zline(j) and zline(j+1):
## 0 open headland, 1 hedge, 2 hedge with trees, 3 row of trees.
func xseg(i: int, j: int) -> int:
	if i == 0 and (j == 0 or j == -1):
		return 0
	return _segk(h01(i, j, 10))


func zseg(i: int, j: int) -> int:
	if j == 0 and (i == 0 or i == -1):
		return 2
	return _segk(h01(i, j, 11))


func _segk(r: float) -> int:
	return 1 if r < 0.42 else (2 if r < 0.74 else (0 if r < 0.9 else 3))


## Gaps [a, b] (world coordinate along the line) in a boundary segment.
func gaps(vertical: bool, i: int, j: int) -> Array:
	var out: Array = []
	if vertical:
		if ztrack(j):
			out.append(Vector2(zline(j) + TOFF - THW - 0.8, zline(j) + TOFF + THW + 0.8))
		var r := h01(i, j, 12)
		if r < 0.55:
			var a := zline(j) + 14.0 + r / 0.55 * (zline(j + 1) - zline(j) - 30.0)
			out.append(Vector2(a, a + 4.5))
	else:
		if xtrack(i):
			out.append(Vector2(xline(i) + TOFF - THW - 0.8, xline(i) + TOFF + THW + 0.8))
		var r := h01(i, j, 13)
		if r < 0.55:
			var a := xline(i) + 14.0 + r / 0.55 * (xline(i + 1) - xline(i) - 30.0)
			out.append(Vector2(a, a + 4.5))
	return out


# ----------------------------------------------------------------- plots

func plot_at(x: float, z: float) -> Dictionary:
	return plot(xi(x), zi(z))


func plot(i: int, j: int) -> Dictionary:
	var k := Vector2i(i, j)
	if _pl.has(k):
		return _pl[k]
	var x0 := xline(i)
	var x1 := xline(i + 1)
	var z0 := zline(j)
	var z1 := zline(j + 1)
	var r := h01(i, j, 5)
	var crop := 1 if r < 0.5 else (2 if r < 0.87 else 0)
	match k:
		Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, -1):
			crop = 1
		Vector2i(0, -1), Vector2i(1, 0):
			crop = 2
		Vector2i(-1, -1), Vector2i(-1, -2):
			crop = 0
	var mx := TOFF + THW + 1.6 if xtrack(i) else 2.6
	var mz := TOFF + THW + 1.6 if ztrack(j) else 2.6
	var p := {"i": i, "j": j, "x0": x0, "x1": x1, "z0": z0, "z1": z1, "crop": crop,
		"rect": Rect2(x0 + mx, z0 + mz, x1 - x0 - mx - 2.6, z1 - z0 - mz - 2.6),
		"yard": Rect2(), "kind": "", "frame": Transform3D(), "pad": 0.0, "canola": Rect2(),
		"rows": h01(i, j, 6) < 0.5, "home": k == HOME}
	_yard(p, k)
	if k == CANOLA_HOME or (h01(i, j, 9) < 0.05 and Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5).length() > 330.0):
		var rc: Rect2 = p["rect"]
		var w := 14.0 + h01(i, j, 14) * 8.0
		var d := 12.0 + h01(i, j, 15) * 8.0
		p["canola"] = Rect2(rc.position.x + 12.0 + h01(i, j, 16) * (rc.size.x - w - 24.0), rc.position.y + 12.0 + h01(i, j, 17) * (rc.size.y - d - 24.0), w, d)
		if p["crop"] == 0:
			p["crop"] = 1
	if qa and k == Vector2i(0, 0):
		p["canola"] = Rect2(12.0, 44.0, 9.0, 8.0)
	_pl[k] = p
	return p


func _yard(p: Dictionary, k: Vector2i) -> void:
	var i: int = p["i"]
	var j: int = p["j"]
	var kind := ""
	if p["home"]:
		kind = "barn"
	elif h01(i, j, 7) < 0.27 and not (k in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1)]):
		var r := h01(i, j, 8)
		kind = "barn" if r < 0.3 else ("stable" if r < 0.5 else ("shed" if r < 0.78 else "cart"))
	if kind == "":
		return
	var dm: Vector2 = DIMS[kind]
	var x0: float = p["x0"]
	var z0: float = p["z0"]
	var bas := Basis()
	var org := Vector3.ZERO
	if p["home"]:
		org = Vector3(x0 + TOFF + THW + 3.6, 0, -58.0)
	elif xtrack(i) or not ztrack(j):
		var lo := x0 + (TOFF + THW + 3.6 if xtrack(i) else 10.0)
		org = Vector3(lo, 0, z0 + 12.0 + h01(i, j, 18) * maxf(1.0, float(p["z1"]) - z0 - dm.y - 26.0))
	else:
		# door faces the track on the z0 side: local x -> world +z, local z -> world -x
		bas = Basis(Vector3.UP, -PI * 0.5)
		var bx := x0 + 12.0 + h01(i, j, 18) * maxf(1.0, float(p["x1"]) - x0 - dm.y - 26.0)
		org = Vector3(bx + dm.y, 0, z0 + TOFF + THW + 3.6)
	var yard := Rect2(org.x - 3.0, org.z - 5.0, dm.x + 8.0, dm.y + 10.0)
	if bas != Basis():
		yard = Rect2(org.x - dm.y - 5.0, org.z - 3.0, dm.y + 10.0, dm.x + 8.0)
	var pad := base_h(yard.get_center().x, yard.get_center().y)
	if pad < WATER_Y + 1.8 and not p["home"]:
		return
	pad = snappedf(pad, 0.05)
	org.y = pad + 0.12
	p["yard"] = yard
	p["kind"] = kind
	p["pad"] = pad
	p["frame"] = Transform3D(bas, org)


# --------------------------------------------------------------- heights

func base_h(x: float, z: float) -> float:
	var h := n1.get_noise_2d(x, z) * 6.2 + n2.get_noise_2d(x, z) * 2.2 + 0.4
	# authored lake: a parabolic hollow blended in with a smooth minimum
	var d := Vector2(x - LAKE.x, z - LAKE.y).length() / LAKE_R
	if d < 2.4:
		var bowl := WATER_Y - 3.2 + 3.8 * d * d
		var k := 2.5
		var hh := clampf(0.5 + 0.5 * (bowl - h) / k, 0.0, 1.0)
		h = lerpf(bowl, h, hh) - k * hh * (1.0 - hh)
	# the spawn rise: the home fields always stand clear of the water
	var e := Vector2(x - 10.0, z + 10.0).length()
	if e < 90.0:
		h = lerpf(h, maxf(h, WATER_Y + 3.2), smoothstep(90.0, 40.0, e))
	return h


func h_at(x: float, z: float) -> float:
	var b := base_h(x, z)
	var p := plot_at(x, z)
	var y: Rect2 = p["yard"]
	if y.size.x > 0.0:
		var dx := maxf(maxf(y.position.x - x, x - y.end.x), 0.0)
		var dz := maxf(maxf(y.position.y - z, z - y.end.y), 0.0)
		var d := sqrt(dx * dx + dz * dz)
		if d < 6.5:
			b = lerpf(float(p["pad"]), b, smoothstep(0.0, 6.5, d))
	return b


## Crop in the 2 m cell centred at (x, z): 0 none, 1 wheat, 2 barley, 3 canola.
func crop_at(x: float, z: float, h: float) -> int:
	if h < WATER_Y + 1.5:
		return 0
	var p := plot_at(x, z)
	var v := Vector2(x, z)
	if not (p["rect"] as Rect2).has_point(v):
		return 0
	if (p["yard"] as Rect2).size.x > 0.0 and (p["yard"] as Rect2).grow(2.0).has_point(v):
		return 0
	if (p["canola"] as Rect2).has_point(v):
		return 3
	return p["crop"]


func cell_crop(cx: int, cz: int) -> int:
	var x := (cx + 0.5) * CELL
	var z := (cz + 0.5) * CELL
	return crop_at(x, z, h_at(x, z))


func is_hole(cx: int, cz: int) -> bool:
	return cx == floori(pit.x / CELL) and cz == floori(pit.y / CELL)


## Nearest track: [distance to centreline, axis (0 = runs along z, 1 = along x)].
func track_near(x: float, z: float) -> Array:
	var best := [1.0e9, 0]
	var i := xi(x)
	if xtrack(i):
		best = [absf(x - xline(i) - TOFF), 0]
	var j := zi(z)
	if ztrack(j) and absf(z - zline(j) - TOFF) < float(best[0]):
		best = [absf(z - zline(j) - TOFF), 1]
	return best
