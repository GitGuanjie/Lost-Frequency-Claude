extends RefCounted
## DEV19: two distinct, physically connected Poolrooms signatures.
## Canon motifs: purposeless tiled colonnades, inexplicable light angles,
## staircases descending into deep water, ledgeless dark recesses.
## Game adaptations: a high crossing of the water and paired underwater return.
## No creatures, human artefacts, mandatory switches or new canonical exits.
const Kinds := preload("res://levels/L037/L037_kinds.gd")
const WALK := -0.18


static func paint(g, meta: Dictionary, twilight: bool) -> void:
	# Two individually designed floor plans; border openings are locked by
	# L037._openings(), so existing and future chunks can really connect.
	g.rect(1, 1, 15, 15, WALK, 10.4 if not twilight else 9.6)
	g.reserve(1, 8, 15, 11)  # main east-west border connection remains clear
	if not twilight:
		g.rect(5, 4, 12, 12, -2.35, 10.4)
		g.rect(7, 6, 10, 10, -5.75, 10.4)
		g.stair(Vector3(10, WALK, 14), Vector3.RIGHT, 3.8, -2.35)
		g.stair(Vector3(24, WALK, 18), Vector3.LEFT, 3.8, -2.35)
		for cell in [[3, 3], [12, 3], [3, 12], [12, 12], [3, 7], [12, 7]]:
			Kinds.pillar(g, cell[0], cell[1], 1.0, true)
		Kinds.well(g, 6, 3, 11, 4, 10.4, 3.0, 3.5)
		g.lights.append({"t": "slit", "p": Vector3(27.9, 6.8, 17), "n": Vector3(-1, 0, 0), "len": 9.0, "h": 0.7, "e": 1.8})
		meta["signature_layout"] = "arch_colonnade_over_double_basin"
	else:
		g.rect(4, 4, 13, 12, -5.8, 9.6)
		g.rect(8, 6, 11, 10, -7.4, 9.6)
		
		g.stair(Vector3(8, WALK, 15), Vector3.RIGHT, 3.8, -5.8)
		g.stair(Vector3(26, WALK, 20), Vector3.LEFT, 3.8, -5.8)
		
		Kinds.well(g, 4, 4, 6, 6, 9.6, 2.3, 1.6)
		g.lights.append({"t": "uw", "p": Vector3(19, -5.0, 15), "n": Vector3(0, 0, -1), "e": 1.0})
		meta["signature_layout"] = "twilight_tiered_basin_two_way_descent"


static func install(k: GeoKit, o: Vector3, twilight: bool) -> Dictionary:
	var lamps: Array = []
	if not twilight:
		# A second, non-Euclidean-looking passage over the central basin.
		# Every high segment joins a real ramp on the dry rim; no floating start.
		var high := 2.80
		var nodes: Array = [
			Vector3(4, WALK, 4), Vector3(12, high, 4),
			Vector3(12, high, 15), Vector3(24, high, 15),
			Vector3(24, high, 28), Vector3(30, WALK, 28)]
		for i in range(nodes.size() - 1):
			k.ramp(o + nodes[i], o + nodes[i + 1], 2.25, 0.24, "l37_tile")
		# Real arches along a perimeter, with 3m-wide voids for sightlines.
		# They do not bisect the corridor joining adjacent chunks at z~19.
		for zz in [7.0, 25.0]:
			var arches: Array = []
			for x in [4.5, 11.5, 18.5, 25.5]:
				arches.append({"at": x, "w": 4.1, "spring": 3.4})
			k.arch_wall(o + Vector3(0, 0, zz), o + Vector3(32, 0, zz),
				6.5, 0.22, "l37_tile", arches, 12)
		for z_guard in [13.82, 16.18]:
			k.box(o + Vector3(18, high + 0.5, z_guard), Vector3(9.8, 1.0, 0.11), "l37_tile")
		lamps = [o + Vector3(12, high + 0.8, 5),
			o + Vector3(18, high + 0.8, 15),
			o + Vector3(24, high + 0.8, 26),
			o + Vector3(18, -4.5, 15)]
		return {"type": "colonnade", "levels": [WALK, high, -2.35, -5.75],
			"physical_ramps": 5, "cross_pool_route": true, "lanterns": lamps}
	# A two-way submerged return with distinct depths, not a duplicate
	# mezzanine template. Both routes terminate on above-water pool rims.
	var a: Array = [Vector3(8, WALK, 23.8), Vector3(10, -2.25, 21),
		Vector3(16, -4.5, 20), Vector3(18, -4.5, 12),
		Vector3(25.8, WALK, 9), Vector3(28, WALK, 5)]
	var b: Array = [Vector3(8, WALK, 23.8), Vector3(9, -1.3, 18),
		Vector3(12, -3.8, 12), Vector3(21, -3.8, 9),
		Vector3(25.8, WALK, 9), Vector3(28, WALK, 5)]
	# Both entrances attach to a dry bank rather than beginning in mid-water.
	k.ramp(o + Vector3(8, WALK, 25.0), o + Vector3(8, WALK, 23.8), 1.8, 0.20, "l37_tile")
	for chain in [a, b]:
		for i in range(chain.size() - 1):
			k.ramp(o + chain[i], o + chain[i + 1], 1.65, 0.20, "l37_tile")
	for x in [4.5, 27.5]:
		for z in [4.5, 26.0]:
			k.cylinder(o + Vector3(x, 2.5, z), 0.35, 5.0, "l37_tile", 14)
	lamps = [o + Vector3(10, -1.3, 21),
		o + Vector3(16, -3.7, 20),
		o + Vector3(22, -3.7, 12),
		o + Vector3(28, 1.0, 5)]
	return {"type": "twilight", "levels": [WALK, -2.25, -5.8, -7.4],
		"physical_ramps": 11, "underwater_returns": 2, "lanterns": lamps}
