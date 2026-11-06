extends RefCounted
## Level 13 apartment interiors. Built in a canonical frame g (door near the
## local origin corner): main room with a joint kitchen and living room at
## v 0..Dm, bedroom (u 0..Wb) and bathroom (u Wb..W) behind it at v Dm..D.
## No windows (the interview describes windowless rooms). Furniture is old
## and plain; the fridge, TV and bed are interactive (see L013.gd).

const P := preload("res://levels/L013/L013_parts.gd")
const CH := P.CH
const TI := P.TI

var lvl: Node3D


func _init(level: Node3D) -> void:
	lvl = level


func build(k: GeoKit, node: Node3D, g: Dictionary, W: float, D: float, r: RandomNumberGenerator, id: String, group: String, chess: bool, anchor: bool) -> Dictionary:
	var st := int(round(float(g["o"].y) / P.FH))
	var Dm := clampf(D * 0.55, 3.4, 5.0)
	if D - Dm < 2.6:
		Dm = D - 2.6
	var Wb := clampf(W - r.randf_range(1.9, 2.3), 2.4, W - 1.8)
	var wall: String = "l13_wall_beige" if r.randf() < 0.6 else "l13_wall_white"
	# partitions
	P.fwall(k, g, 0.0, Dm, W, Dm, 0.0, CH, wall, [{"at": 0.75, "w": 0.8, "h": P.DH, "sill": 0.0}, {"at": Wb + 0.55, "w": 0.75, "h": P.DH, "sill": 0.0}])
	P.fwall(k, g, Wb, Dm, Wb, D, 0.0, CH, wall)
	for at in [0.75, Wb + 0.55]:
		var w: float = 0.8 if at < 1.0 else 0.75
		for side in [-1.0, 1.0]:
			P.fb(k, g, at - w * 0.5 - 0.06, 0.0, Dm + side * 0.06 - 0.012, at - w * 0.5, P.DH + 0.06, Dm + side * 0.06 + 0.012, "l13_trim")
			P.fb(k, g, at + w * 0.5, 0.0, Dm + side * 0.06 - 0.012, at + w * 0.5 + 0.06, P.DH + 0.06, Dm + side * 0.06 + 0.012, "l13_trim")
			P.fb(k, g, at - w * 0.5 - 0.06, P.DH, Dm + side * 0.06 - 0.012, at + w * 0.5 + 0.06, P.DH + 0.06, Dm + side * 0.06 + 0.012, "l13_trim")
	# floor finishes
	var L := clampf(W * 0.55, 2.4, 3.4)
	P.fb(k, g, W - L - 0.2, 0.004, 0.0, W, 0.012, 1.7, "l13_lino_tile")
	P.fb(k, g, 0.0, 0.004, Dm + 0.05, Wb - 0.05, 0.012, D, "l13_carpet")
	P.fb(k, g, Wb + 0.05, 0.004, Dm + 0.05, W, 0.012, D, "l13_tile")
	# ---- kitchen along the front wall, fridge in the far corner
	var kf := P.fr(P.fp(g, W, 0.0, 0.0), -g["u"], g["v"])
	var kit: Dictionary = P.kitchen(k, kf, L)
	# ---- dining (or a generated chessboard) table with two chairs
	P.table2(k, g, W - 1.3, 1.6, chess)
	# ---- living: sofa on the side wall, CRT television opposite
	var vc := clampf(Dm * 0.62, 2.3, Dm - 1.05)
	var fabs := ["l13_fabric_a", "l13_fabric_b", "l13_fabric_c"]
	var sf := P.fr(P.fp(g, 0.0, 0.0, 0.0), g["v"], g["u"])
	P.sofa(k, sf, vc, fabs[r.randi() % 3])
	P.fb(k, g, 1.18, 0.0, vc - 0.45, 1.68, 0.4, vc + 0.45, "l13_wood")
	P.fb(k, g, 1.0, 0.004, vc - 1.0, minf(W - 0.75, 3.4), 0.014, vc + 1.0, ["l13_rug_a", "l13_rug_b"][r.randi() % 2])
	P.fb(k, g, 1.25, 0.4, vc - 0.3, 1.55, 0.415, vc + 0.05, "paper")                      # old magazine
	P.fb(k, kf, 1.9, 0.9, 0.1, 2.3, 1.02, 0.45, "l13_steel")                               # dish rack
	for i in 3:
		k.cylinder(P.fp(kf, 2.0 + i * 0.1, 0.96, 0.27), 0.012, 0.11, "l13_porcelain", 6, false)
	k.cylinder(P.fp(kf, 0.9, 0.95, 0.5), 0.045, 0.1, ["l13_fabric_c", "l13_porcelain"][r.randi() % 2], 8, false)   # mug
	# a faded print above the sofa, a clock, a kettle on the hob: old, generic, generated
	P.fb(k, sf, vc - 0.45, 1.25, 0.0, vc + 0.45, 1.85, 0.03, "l13_wood")
	P.fb(k, sf, vc - 0.39, 1.31, 0.03, vc + 0.39, 1.79, 0.035, ["l13_print_a", "l13_print_b"][r.randi() % 2])
	P.fb(k, g, W - 0.03, 1.8, vc - 0.15, W, 2.1, vc + 0.15, "l13_clock")
	P.fb(k, kf, L - 0.5, 0.92, 0.18, L - 0.32, 1.1, 0.36, "l13_steel")
	var tf := P.fr(P.fp(g, W, 0.0, 0.0), g["v"], -g["u"])
	var screen := P.tv(k, tf, vc)
	# floor lamp in the corner by the sofa
	var lamp := P.fp(g, 0.3, 0.0, minf(vc + 1.25, Dm - 0.3))
	k.box(lamp + Vector3.UP * 0.75, Vector3(0.03, 1.5, 0.03), "l13_rail", GeoKit.SIDES, false)
	k.box(lamp + Vector3.UP * 0.02, Vector3(0.28, 0.04, 0.28), "l13_rail", GeoKit.ALL, false)
	k.cylinder(lamp + Vector3.UP * 1.52, 0.18, 0.26, "l13_shade", 8, false)
	if r.randf() < 0.6:
		lvl.lamp(lamp + Vector3.UP * 1.45, Color(1.0, 0.78, 0.5), 0.5, 3.0, 0.0, group, st)
	if Wb >= 2.6:
		var shf := P.fr(P.fp(g, 0.0, 0.0, Dm - TI * 0.5), g["u"], -g["v"])
		P.shelf(k, shf, (1.25 + Wb) * 0.5)
	# main light
	var ml := P.fp(g, W * 0.5, CH, Dm * 0.5)
	k.cylinder(ml + Vector3.DOWN * 0.06, 0.2, 0.1, "l13_dome", 8, false)
	lvl.lamp(ml + Vector3.DOWN * 0.45, Color(1.0, 0.82, 0.58), 1.0, 4.6, 0.0, group, st)
	# ---- bedroom
	var bw := 1.4 if Wb >= 3.0 else 1.0
	var bf := P.fr(P.fp(g, 0.0, 0.0, D), g["u"], -g["v"])
	var bc := Wb - 0.12 - bw * 0.5
	var bedp := P.bed(k, bf, bc, bw, fabs[r.randi() % 3])
	if bc - bw * 0.5 > 0.6:
		P.fb(k, bf, bc - bw * 0.5 - 0.48, 0.0, 0.02, bc - bw * 0.5 - 0.04, 0.55, 0.42, "l13_wood")
		k.cylinder(P.fp(bf, bc - bw * 0.5 - 0.26, 0.68, 0.22), 0.1, 0.24, "l13_shade", 6, false)
	P.fb(k, bf, bc - 0.35, 1.25, 0.0, bc + 0.35, 1.7, 0.03, "l13_wood")
	P.fb(k, bf, bc - 0.3, 1.3, 0.03, bc + 0.3, 1.65, 0.035, "l13_print_b")
	if r.randf() < 0.5:
		P.fb(k, bf, bc - 0.3, 0.55, 1.1, bc + 0.25, 0.64, 1.55, fabs[r.randi() % 3])          # folded old clothes
	if D - Dm >= 3.3 and bc - bw * 0.5 >= 1.3:
		var wf := P.fr(P.fp(g, 0.0, 0.0, 0.0), g["v"], g["u"])
		P.wardrobe(k, wf, Dm + 1.6)
	var bl := P.fp(g, Wb * 0.5, CH, (Dm + D) * 0.5)
	k.cylinder(bl + Vector3.DOWN * 0.05, 0.16, 0.08, "l13_dome", 8, false)
	lvl.lamp(bl + Vector3.DOWN * 0.4, Color(1.0, 0.8, 0.55), 0.45, 3.2, 0.0, group, st)
	# ---- bathroom
	var tbf := P.fr(P.fp(g, 0.0, 0.0, D), g["u"], -g["v"])
	P.tub(k, tbf, Wb + 0.07, W - 0.04)
	var rw := P.fr(P.fp(g, W, 0.0, 0.0), g["v"], -g["u"])
	P.basin(k, rw, Dm + 0.45)
	if D - Dm >= 2.6:
		P.toilet(k, rw, Dm + 1.35)
	var tl := P.fp(g, (Wb + W) * 0.5, CH, Dm + 0.9)
	k.cylinder(tl + Vector3.DOWN * 0.04, 0.12, 0.06, "l13_bulk", 8, false)
	var info := {"fridge": kit["fridge"], "micro": kit["micro"], "tv": screen, "tv_n": -g["u"], "bed": bedp,
		"eye": P.fp(g, W - 0.75, 1.62, 0.95), "look": P.fp(g, 0.4, 0.9, Dm - 0.2), "anchor": anchor}
	if chess:
		info["chess"] = P.fp(g, W - 1.3, 0.8, 1.6)
	if anchor:
		info["note"] = P.fp(g, 1.43, 0.43, vc)
	lvl.add_apt_items(node, id, info)
	return info
