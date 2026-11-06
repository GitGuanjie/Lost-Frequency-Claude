extends RefCounted
## Level 0.1 far field (visual only, no collision):
##  - the cavity: an inverted sphere drawn by a shader as the station's inner
##    face (white plating, deck after deck of windows, dark damaged districts,
##    structural ribs that make the spherical shell readable across 2.8 km)
##  - the near facade: real quads for ~260 m around the Inner Gallery, every
##    deck stepping out over the one below along the sphere
##  - Level 0 seen from the Outer Ring: "a series of nearly identical floors
##    stacked vertically", instanced 121 times, plus the hull's own face.

const D := preload("res://levels/L000_1/L000_1_dims.gd")

const CAVITY_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform float radius = 1404.0;
uniform vec3 gal_dir = vec3(0.0, 0.42, -0.9);
uniform float hole = 245.0;
varying vec3 lp;
float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex() { lp = VERTEX; }
void fragment() {
	vec3 d = normalize(lp);
	if (distance(d, gal_dir) * radius < hole) { discard; }
	float lat = asin(clamp(d.y, -1.0, 1.0));
	float lon = atan(d.x, d.z);
	float cl = max(cos(lat), 0.02);
	float v = lat * radius;
	float u = lon * radius * cl;
	float row = v / 4.5;
	float fw = fwidth(row);
	float fr = fract(row);
	float band = smoothstep(0.2, 0.2 + fw + 0.001, fr) * (1.0 - smoothstep(0.62 - fw - 0.001, 0.62, fr));
	float aa = smoothstep(0.3, 0.8, fw);
	band = mix(band, 0.42, aa);
	float dn = vn(vec2(u, v) / 160.0) * 0.6 + vn(vec2(u, v) / 45.0 + 11.0) * 0.4;
	float alive = mix(0.25, 1.0, smoothstep(0.76, 0.64, dn));
	float dens = (0.035 + 0.09 * vn(vec2(u, v) / 120.0 + 5.0)) * alive;
	vec2 cell = vec2(floor(u / 8.0), floor(row));
	float fc = max(smoothstep(0.3, 0.8, fwidth(u / 8.0)), aa);
	float lit = mix(step(1.0 - dens, h21(cell)), dens, fc);
	float tn = vn(vec2(u, v) / 350.0 + 23.0);
	vec3 wc = mix(vec3(0.78, 0.87, 1.0), vec3(1.0, 0.8, 0.55), clamp(0.2 + 0.6 * tn + 0.6 * (h21(cell + 3.1) - 0.5) * (1.0 - fc), 0.0, 1.0));
	float hz = vn(vec2(u, v) / 300.0 + 41.0);
	wc = mix(wc, vec3(1.0, 0.3, 0.06), smoothstep(0.84, 0.9, hz));
	wc = mix(wc, vec3(0.28, 0.5, 1.0), smoothstep(0.16, 0.1, hz));
	vec3 plating = vec3(0.6, 0.63, 0.68) * (0.006 + 0.006 * h21(floor(vec2(u / 30.0, v / 13.5))));
	vec3 col = plating + wc * 1.2 * lit * band;
	float px = fwidth(v) + 0.001;
	float dl = abs(fract(v / 13.5 + 0.5) - 0.5) * 13.5;
	float cor = clamp(1.0 - (dl - 0.3) / px, 0.0, 1.0) * min(1.0, 0.6 / px);
	col += vec3(0.85, 0.9, 1.0) * 0.14 * cor * alive;
	float eq = abs(v);
	float ring = clamp(1.0 - (eq - 2.0) / px, 0.0, 1.0) * min(1.0, 4.0 / px);
	col += vec3(1.0, 0.92, 0.78) * (1.6 * ring + 0.05 * (1.0 - smoothstep(20.0, 60.0, eq)));
	float mer = abs(fract(lon / radians(15.0) + 0.5) - 0.5) * radians(15.0) * radius * cl;
	float pm = fwidth(mer) + 0.001;
	float rib = clamp(1.0 - (mer - 6.0) / pm, 0.0, 1.0) * min(1.0, 12.0 / pm) * smoothstep(0.2, 0.45, cl);
	float spine = clamp(1.0 - (mer - 0.6) / pm, 0.0, 1.0) * min(1.0, 1.2 / pm) * smoothstep(0.2, 0.45, cl);
	col = mix(col, vec3(0.004), rib * 0.9) + vec3(1.0, 0.85, 0.6) * spine * 0.8;
	col *= mix(0.25, 1.0, smoothstep(0.1, 0.4, cl));
	ALBEDO = col;
}
"""

const WINDOW_SHADER := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 color : source_color = vec3(0.85, 0.92, 1.0);
uniform float energy = 1.0;
float h11(float p) { p = fract(p * 0.1031); p *= p + 33.33; p *= p + p; return fract(p); }
void fragment() {
	float s = UV2.x;
	float y = 1.0 - UV.y;
	float g = mix(0.45, 1.0, smoothstep(0.1, 0.95, y));
	float rail = 1.0 - 0.75 * (smoothstep(0.26, 0.27, y) - smoothstep(0.29, 0.3, y));
	float part = 1.0 - 0.6 * step(0.7, h11(s * 3.7)) * step(abs(UV.x - h11(s * 1.3)), 0.06) * step(y, 0.62);
	float fl = (UV2.y > 0.0 && h11(floor(TIME * 9.0) + s) < 0.3) ? 0.25 : 1.0;
	ALBEDO = color * energy * g * rail * part * fl * (0.75 + 0.5 * h11(s));
}
"""


static func materials() -> void:
	var cav := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CAVITY_SHADER
	cav.shader = sh
	var c := D.cc()
	var g0 := Vector3(0.0, 0.0, 2.0)
	cav.set_shader_parameter("radius", D.R + 4.0)
	cav.set_shader_parameter("gal_dir", (g0 - c).normalized())
	MatLib.register("l01_cavity", cav)
	var wsh := Shader.new()
	wsh.code = WINDOW_SHADER
	for spec in [["l01_win_cool", Color(0.8, 0.9, 1.0), 0.8], ["l01_win_warm", Color(1.0, 0.86, 0.64), 0.75],
			["l01_win_dim", Color(0.55, 0.6, 0.68), 0.12], ["l01_win_hot", Color(1.0, 0.42, 0.15), 1.3],
			["l01_win_cold", Color(0.45, 0.66, 1.0), 0.9]]:
		var w := ShaderMaterial.new()
		w.shader = wsh
		w.set_shader_parameter("color", Vector3(spec[1].r, spec[1].g, spec[1].b))
		w.set_shader_parameter("energy", spec[2])
		MatLib.register(spec[0], w)
	MatLib.register("l01_win_dark", MatLib.standard(Color(0.015, 0.018, 0.022), 0.12, 0.7))


## The cavity sphere (seen from inside only).
static func cavity(parent: Node3D) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = D.R + 4.0
	sm.height = (D.R + 4.0) * 2.0
	sm.radial_segments = 160
	sm.rings = 80
	sm.flip_faces = true
	var mi := MeshInstance3D.new()
	mi.name = "Cavity"
	mi.mesh = sm
	mi.material_override = MatLib.get_mat("l01_cavity")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = D.cc()
	mi.extra_cull_margin = 10.0
	parent.add_child(mi)
	return mi


static func _win_mat(x: float, j: int, k: int) -> String:
	var dist := D.h01(int(floor(x / 40.0)), int(floor(j / 5.0)), 31)
	var r := D.h01(int(floor(x * 4.0)) + k, j, 7)
	if dist > 0.82:
		return "l01_win_dark" if r < 0.8 else "l01_win_dim"
	if dist < 0.05:
		return "l01_win_hot" if r < 0.6 else "l01_win_dark"
	if dist > 0.77:
		return "l01_win_cold" if r < 0.6 else "l01_win_dark"
	if r < 0.74:
		return "l01_win_dark"
	if r < 0.86:
		return "l01_win_dim"
	return "l01_win_warm" if r > 0.82 else "l01_win_cool"


## Near facade: the cavity wall's decks for ~260 m around the gallery.
static func facade(parent: Node3D) -> int:
	var q := D.Quads.new()
	var c := D.cc()
	var n := 0
	for j in range(-46, 58):
		var y0 := D.DY * j
		var y1 := y0 + D.DY
		for xi in range(-26, 26):
			var x0 := 10.0 * xi
			var x1 := x0 + 10.0
			var xm := (x0 + x1) * 0.5
			var zm := D.z_edge(xm, y0)
			if Vector3(xm, y0 + 2.0, zm - 2.0).length() > 262.0:
				continue
			var gal := x0 >= -D.GX - 0.1 and x1 <= D.GX + 0.1
			if gal and j >= 0 and j <= 3:
				continue
			n += 1
			var nn := (c - Vector3(xm, y0 + 2.0, zm)).normalized()
			var za := D.z_edge(x0, y0)
			var zb := D.z_edge(x1, y0)
			var la := D.z_edge(x0, y1) + 0.4
			var lb := D.z_edge(x1, y1) + 0.4
			# slab lip band of this deck (gallery roof draws its own above deck 3)
			if not (gal and j == 4):
				var sa := D.z_edge(x0, y0) + 0.4
				var sb := D.z_edge(x1, y0) + 0.4
				q.q(Vector3(x0, y0 - D.SLAB, sa), Vector3(x1, y0 - D.SLAB, sb), Vector3(x1, y0, sb), Vector3(x0, y0, sa), nn, "l01_fac_slab")
			# soffit: underside of the deck above, jutting out past this glass line
			if not (gal and j == -1):
				q.q(Vector3(x0, y1 - D.SLAB, za), Vector3(x1, y1 - D.SLAB, zb), Vector3(x1, y1 - D.SLAB, lb), Vector3(x0, y1 - D.SLAB, la), Vector3.DOWN, "l01_fac_soffit")
				if D.h01(xi, j, 12) < 0.35:
					var sz := (za + la) * 0.5
					q.q(Vector3(xm - 1.5, y1 - D.SLAB - 0.01, sz - 0.12), Vector3(xm + 1.5, y1 - D.SLAB - 0.01, sz - 0.12), Vector3(xm + 1.5, y1 - D.SLAB - 0.01, sz + 0.12), Vector3(xm - 1.5, y1 - D.SLAB - 0.01, sz + 0.12), Vector3.DOWN, "l01_panel", Vector2(D.h01(xi, j, 13) * 40.0, 0.0), true)
			# mullion backing and four panes
			var h := D.DY - D.SLAB
			q.q(Vector3(x0, y0, za), Vector3(x1, y0, zb), Vector3(x1, y0 + h, zb), Vector3(x0, y0 + h, za), nn, "l01_mullion")
			for k in 4:
				var u0 := x0 + 2.5 * k + 0.07
				var u1 := x0 + 2.5 * (k + 1) - 0.07
				var w0 := D.z_edge(u0, y0) + 0.05
				var w1 := D.z_edge(u1, y0) + 0.05
				var mat := _win_mat(u0, j, k)
				var seed := D.h01(int(u0 * 10.0), j, 3) * 50.0
				var fl := 1.0 if D.h01(int(u0 * 10.0), j, 4) < 0.03 else 0.0
				q.q(Vector3(u0, y0 + 0.08, w0), Vector3(u1, y0 + 0.08, w1), Vector3(u1, y0 + h - 0.08, w1), Vector3(u0, y0 + h - 0.08, w0), nn, mat, Vector2(seed, fl), true)
	q.commit(parent, "Facade")
	return n


## Level 0 as seen from the Outer Ring: identical floors stacked vertically.
## Built in the Outer Ring's local frame (parent sits at D.TH).
static func level0_stack(parent: Node3D) -> int:
	var xf0: Array = []
	var xf1: Array = []
	for f in range(-60, 61):
		if f == 0:
			continue
		var t := Transform3D(Basis(), Vector3(0.0, D.L0Y + D.L0H * f, 0.0))
		if D.h01(f, 0, 77) < 0.7:
			xf0.append(t)
		else:
			xf1.append(t)
	var q := D.Quads.new()
	_l0_floor(q, 0, false)
	q.commit_multi(parent, "L0StackA", xf0)
	_l0_floor(q, 1, false)
	q.commit_multi(parent, "L0StackB", xf1)
	# floor 0 itself: same strip with a gap where the real hallway and room stand
	_l0_floor(q, 0, true)
	var holder := Node3D.new()
	holder.name = "L0Floor0"
	holder.position = Vector3(0.0, D.L0Y, 0.0)
	parent.add_child(holder)
	q.commit(holder, "L0F0")
	return xf0.size() + xf1.size() + 1


## One Level 0 floor strip (floor top at y=0). variant shifts the partitions.
static func _l0_floor(q, variant: int, gap: bool) -> void:
	var z0 := D.L0Z
	var zb := D.L0Z - 12.0
	var h := 2.75
	var xa := -100.0
	var xb := 100.0
	var spans: Array = [[xa, xb]] if not gap else [[xa, -6.0], [6.0, xb]]
	for sp in spans:
		var a: float = sp[0]
		var b: float = sp[1]
		q.q(Vector3(a, 0, zb), Vector3(b, 0, zb), Vector3(b, 0, z0), Vector3(a, 0, z0), Vector3.UP, "l01_l0carpet_far")
		q.q(Vector3(a, h, zb), Vector3(b, h, zb), Vector3(b, h, z0), Vector3(a, h, z0), Vector3.DOWN, "l01_l0ceiling_far")
		# the slab between this floor and the next: a dark band on the cut face
		q.q(Vector3(a, h, z0), Vector3(b, h, z0), Vector3(b, D.L0H, z0), Vector3(a, D.L0H, z0), Vector3.BACK, "l01_l0slab")
		q.q(Vector3(a, 2.15, z0 - 0.05), Vector3(b, 2.15, z0 - 0.05), Vector3(b, h, z0 - 0.05), Vector3(a, h, z0 - 0.05), Vector3.BACK, "l01_l0wall_far")
	q.q(Vector3(xa, 0, zb), Vector3(xb, 0, zb), Vector3(xb, h, zb), Vector3(xa, h, zb), Vector3.BACK, "l01_l0wall_far")
	var off := 0.0 if variant == 0 else 3.75
	var x := xa + off
	var i := 0
	while x < xb:
		i += 1
		var skip := gap and absf(x) < 6.5
		if not skip:
			# partition walls with a doorway, and a stretch of cut wall on the face
			q.box(Vector3(x - 0.08, 0, zb), Vector3(x + 0.08, h, z0 - 6.6), "l01_l0wall_far", 1 | 2 | 16)
			q.box(Vector3(x - 0.08, 0, z0 - 5.4), Vector3(x + 0.08, h, z0 - 2.2), "l01_l0wall_far", 1 | 2 | 16 | 32)
			q.box(Vector3(x - 0.08, 2.1, z0 - 6.6), Vector3(x + 0.08, h, z0 - 5.4), "l01_l0wall_far", 1 | 2 | 8)
			q.box(Vector3(x + 1.8 + variant * 1.1, 0, z0 - 0.2), Vector3(x + 5.7 + variant * 1.1, 2.15, z0 - 0.05), "l01_l0wall_far", 1 | 2 | 16 | 32)
			if variant == 1 and i % 3 == 0:
				q.box(Vector3(x, 0, z0 - 8.1), Vector3(x + 7.5, h, z0 - 7.95), "l01_l0wall_far", 16 | 32)
		for pz: float in [z0 - 2.6, z0 - 8.4]:
			var px := x + 3.75
			if gap and absf(px) < 6.5:
				continue
			var dead := D.h01(int(px * 3.0), int(pz), variant + 5) < 0.12
			q.q(Vector3(px - 0.3, h - 0.01, pz - 0.6), Vector3(px + 0.3, h - 0.01, pz - 0.6), Vector3(px + 0.3, h - 0.01, pz + 0.6), Vector3(px - 0.3, h - 0.01, pz + 0.6),
				Vector3.DOWN, "l01_l0panel", Vector2(150.0 if dead else px, 0.0), true)
		x += 7.5


## The hull's own outer face around the Outer Ring (local frame), with the
## concourse window opening left clear.
static func hull_face(parent: Node3D) -> void:
	var q := D.Quads.new()
	var z := D.HULLZ - 0.62
	var rects := [[-180.0, -14.0, -200.0, 200.0], [14.0, 180.0, -200.0, 200.0], [-14.0, 14.0, 5.2, 200.0], [-14.0, 14.0, -200.0, -0.9]]
	for r in rects:
		q.q(Vector3(r[0], r[2], z), Vector3(r[1], r[2], z), Vector3(r[1], r[3], z), Vector3(r[0], r[3], z), Vector3.FORWARD, "l01_hull")
	# rows of the hull's other windows: mostly dark, a few still lit
	for j in range(-40, 42):
		var y := 4.5 * j + 1.4
		for i in range(-16, 16):
			var x := 11.0 * i + 3.0
			if absf(x) < 18.0 and y > -3.0 and y < 7.0:
				continue
			var r := D.h01(i, j, 91)
			var mat := "l01_win_dark" if r < 0.8 else ("l01_win_dim" if r < 0.95 else "l01_win_warm")
			q.q(Vector3(x, y, z - 0.03), Vector3(x + 6.0, y, z - 0.03), Vector3(x + 6.0, y + 2.2, z - 0.03), Vector3(x, y + 2.2, z - 0.03), Vector3.FORWARD, mat, Vector2(r * 40.0, 0.0), true)
	q.commit(parent, "HullFace")
