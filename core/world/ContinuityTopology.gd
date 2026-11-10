class_name ContinuityTopology
extends RefCounted
## Coordinate-only, deterministic rules shared by a 3-D world streamer and the
## experimental Level 0 continuity lab. No randomness is consumed globally.

const WIDTH := 24.0
const FLOOR_HEIGHT := 4.5
const MIN_FLOOR := -2
const MAX_FLOOR := 2


static func key_for(pos: Vector3) -> Vector3i:
	return Vector3i(floori(pos.x / WIDTH), floori(pos.y / FLOOR_HEIGHT), floori(pos.z / WIDTH))


static func origin(k: Vector3i) -> Vector3:
	return Vector3(k.x * WIDTH, k.y * FLOOR_HEIGHT, k.z * WIDTH)


static func encode(k: Vector3i) -> String:
	return "%d:%d:%d" % [k.x, k.y, k.z]


static func between_floors(k: Vector3i) -> bool:
	return k.y >= MIN_FLOOR and k.y <= MAX_FLOOR


static func stable_roll(seed_value: int, values: Array, modulo: int) -> int:
	return posmod(hash([seed_value, values]), maxi(modulo, 1))


## x+ face owned by k; its adjacent x- face reads the *same* owner.
## z+ face owned by k; its adjacent z- face reads the *same* owner.
static func border_slot(seed_value: int, k: Vector3i, axis: String) -> int:
	return 1 + stable_roll(seed_value, ["shared-edge", axis, k.x, k.y, k.z], 3)


## The lateral position of a face portal.
##
## The staircase occupies a band inside every chunk, so a door must not open
## onto it. The stairs run along z and stand in two narrow x bands, one per
## shaft, so:
##
##   * an east or west face has a lateral coordinate along z, and the stair
##     run occupies z in [STAIR_Z0, STAIR_Z0 + run];
##   * a north or south face has a lateral coordinate along x, and the two
##     shafts occupy two narrow x bands.
##
## A door that opened straight onto a stairwell put the player in front of an
## open well. The door width stays 4 m, so the OPENING, not just its centre,
## has to be clear of the stairs.
static func border_offset(seed_value: int, k: Vector3i, axis: String) -> float:
	var slot := border_slot(seed_value, k, axis)
	if axis == "x":
		# East and west faces: clear of the stair run, and on the same lanes
		# the shared circulation uses. The opening is 4 m wide, so the whole
		# opening has to stay clear of the stair band.
		return [3.0, 4.5, 21.0][slot - 1]
	# North and south faces: clear of both shaft bands, and in line with the
	# door of the room partitions so a partition never blocks a doorway.
	return [11.0, 12.0, 13.0][slot - 1]


# --------------------------- staircase geometry ---------------------------
# The hole in a floor and the ramp that fills it are ONE rectangle. A hole that
# is wider or longer than its ramp leaves an uncovered strip, and that strip
# is an unguarded drop to the storey below.
const STAIR_WIDTH := 2.4
const STAIR_RUN := 0.60
const STAIR_STEPS := 20
const STAIR_Z0 := 6.8


## The floor opening of the staircase in a shaft, and the footprint of the ramp
## that fills it. They are the same rectangle by construction, so the hole can
## never be wider or longer than the ramp.
static func stair_slot(shaft: int) -> Rect2:
	return Rect2(shaft_x(shaft) + 0.3, STAIR_Z0, STAIR_WIDTH, STAIR_RUN * STAIR_STEPS)


## True when a lateral opening of the given width would touch a stair slot.
## The door is 4 m wide, so the whole opening has to be clear, not only its
## centre.
static func opening_hits_stair(at: float, width: float, axis: String) -> bool:
	var lo := at - width * 0.5
	var hi := at + width * 0.5
	if axis == "x":
		# Lateral coordinate along z: the stair run occupies this band.
		return hi > STAIR_Z0 and lo < STAIR_Z0 + STAIR_RUN * STAIR_STEPS
	# Lateral coordinate along x: the two shafts occupy two narrow bands.
	for shaft in 2:
		var slot := stair_slot(shaft)
		if hi > slot.position.x and lo < slot.end.x:
			return true
	return false


## Outgoing stairs alternate between two disjoint shafts. The next floor cuts
## its *incoming* opening in the SAME shaft as the floor below used to ascend.
static func outgoing_shaft(storey: int) -> int:
	return posmod(storey, 2)


static func incoming_shaft(storey: int) -> int:
	return outgoing_shaft(storey - 1)


static func shaft_x(shaft_id: int) -> float:
	return 6.0 if shaft_id == 0 else 15.0


## ------------------------- World identity and zone addressing -------------
## A ZONE is an 8x8-chunk superdistrict (192 m square). Zone borders are
## therefore aligned with the superdistrict skeleton and can never cut a
## transit hub, a spine or a megastructure in half.
##
## The previous rule was a hard-coded x-threshold split into a yellow zone
## and a proxy zone. It was wrong twice: it intersected the central
## superdistrict hub (chunks x=3..4, z=3..4 fell in different zones) and it
## presented a non-canon warehouse as if it were the canonical Level 1. The
## proxy region is now one whole superdistrict with its own explicit,
## non-canon zone id.
const ZONE_YELLOW := "Z_L000_YELLOW"       # canonical Level 0 look-alike
const ZONE_PROXY := "Z_PROXY_WAREHOUSE"    # non-canon concrete warehouse
const ZONE_GENERIC := "Z_GENERIC"


## The proxy warehouse lives in one whole superdistrict, never in the spawn
## superdistrict, so the central hub can no longer be split across two
## architectural identities. Its position is stable for a given seed.
static func proxy_super_key(seed_value: int) -> Vector3i:
	var sx := 1 + stable_roll(seed_value, ["proxy-zone-x"], 4)
	var sz := stable_roll(seed_value, ["proxy-zone-z"], 3)
	return Vector3i(sx, 0, sz)


## The zone a chunk belongs to. Zones are superdistrict-aligned, so a whole
## 192 m district always shares one architectural identity.
static func zone_id(seed_value: int, k: Vector3i) -> String:
	var s := super_key(k)
	if s == Vector3i.ZERO:
		return ZONE_YELLOW
	if s == proxy_super_key(seed_value):
		return ZONE_PROXY
	return "Z_%d_%d" % [s.x, s.z]


## Zone of the superdistrict that owns chunk k, without needing a seed.
static func zone_id_for_super(s: Vector3i) -> String:
	if s == Vector3i.ZERO:
		return ZONE_YELLOW
	return "Z_%d_%d" % [s.x, s.z]


## True when the chunk sits in the non-canon concrete warehouse zone. The
## warehouse is an architectural adaptation, NOT the canonical Level 1.
static func is_proxy_zone(seed_value: int, k: Vector3i) -> bool:
	return zone_id(seed_value, k) == ZONE_PROXY


## Legacy helper kept for callers that only need a coarse label. It now
## reports the zone, never a canonical level number.
static func district(k: Vector3i) -> String:
	return zone_id_for_super(super_key(k))


## Every physical border is owned by a canonical shared-face key. Both
## adjacent cells cut the SAME opening, even if generated in reverse order.
## West/South use the neighbour's positive face; geometry may be doubled at
## loaded seams for safety while streaming, but collision openings coincide.
static func face_owner(k: Vector3i, face: String) -> Vector3i:
	match face:
		"west":
			return k + Vector3i(-1, 0, 0)
		"south":
			return k + Vector3i(0, 0, -1)
		_:
			return k


static func face_axis(face: String) -> String:
	return "x" if face == "east" or face == "west" else "z"


static func face_offset(seed_value: int, k: Vector3i, face: String) -> float:
	return border_offset(seed_value, face_owner(k, face), face_axis(face))


## A macro region spans 4x4 chunks; it has a persistent material / architectural
## identity. The local room class varies inside that region. Neither depends
## on load order, player movement or mutable chunk versions.
static func macro_key(k: Vector3i) -> Vector3i:
	return Vector3i(floori(float(k.x) / 4.0), 0, floori(float(k.z) / 4.0))


static func macro_theme(seed_value: int, k: Vector3i) -> String:
	var options := ["yellow_maze", "vaulted_offices", "service_annex",
		"abandoned_archive", "structural_gallery", "silent_quarters"]
	var zone := zone_id(seed_value, k)
	if zone == ZONE_PROXY:
		options = ["concrete_warehouse", "loading_bay", "pipeworks", "maintenance"]
	var m := macro_key(k)
	return options[stable_roll(seed_value, ["macro", m.x, m.z, zone], options.size())]


static func room_type(seed_value: int, k: Vector3i, version: int = 0) -> String:
	if k == Vector3i.ZERO:
		return "entry_hall"
	var options := ["crossroads", "archive", "machinery", "column_gallery",
		"shrine", "storage", "reading_room", "observation"]
	var roll := stable_roll(seed_value, ["room", k.x, k.y, k.z, version], options.size())
	return options[roll]


## A rare landmark to find. Every 4x4 macro-cell has at least its central
## anchor, which is stable and non-blocking; other rooms can also be special.
static func has_landmark(seed_value: int, k: Vector3i) -> bool:
	if k == Vector3i.ZERO:
		return true
	return (posmod(k.x, 4) == 2 and posmod(k.z, 4) == 2) or \
		stable_roll(seed_value, ["beacon", k.x, k.y, k.z], 19) == 0


static func discovery_label(seed_value: int, k: Vector3i) -> String:
	var names := ["A faded survey tape", "An abandoned field journal",
		"A maintenance badge", "A forgotten photograph", "An unmarked cassette",
		"A brittle map fragment", "A fluorescent inspection card"]
	return names[stable_roll(seed_value, ["discovery", k.x, k.y, k.z], names.size())]


# -------------------------- V3: region-scale architectural master plan -----
# All decisions are pure functions of the world seed and stable coordinates.
# The mutable per-room version is intentionally NEVER consulted here: pressing
# F4 cannot move a portal, floor well, bridge, macro landmark, or power relay.
static func macro_structure(seed_value: int, k: Vector3i) -> String:
	var m := macro_key(k)
	var zone := zone_id(seed_value, k)
	# The starting district always contains one showcase spanning 2x2 chunks.
	if m == Vector3i.ZERO and zone == ZONE_YELLOW:
		return "grand_atrium"
	var choices := ["grand_atrium", "hanging_archive", "riser_court", "solid_gallery"]
	if zone == ZONE_PROXY:
		choices = ["riser_court", "industrial_concourse", "grand_atrium", "solid_gallery"]
	return choices[stable_roll(seed_value, ["superstructure-v3", m.x, m.z, zone], choices.size())]


static func is_macro_core(k: Vector3i) -> bool:
	return posmod(k.x, 4) in [1, 2] and posmod(k.z, 4) in [1, 2]


static func has_atrium(seed_value: int, k: Vector3i) -> bool:
	return is_macro_core(k) and macro_structure(seed_value, k) != "solid_gallery"


static func neighbor_of(k: Vector3i, face: String) -> Vector3i:
	match face:
		"west":
			return k + Vector3i(-1, 0, 0)
		"east":
			return k + Vector3i(1, 0, 0)
		"north":
			return k + Vector3i(0, 0, 1)
		"south":
			return k + Vector3i(0, 0, -1)
	return k


static func is_core_edge(k: Vector3i, face: String) -> bool:
	var other := neighbor_of(k, face)
	return is_macro_core(k) and is_macro_core(other) and macro_key(k) == macro_key(other)


## Same openings on both faces, regardless of load order. A 11 m primary
## passage makes the four-chunk hall read as one space. A second, high opening
## at the atrium corner connects the 10x10m central vertical well and bridge.
static func face_openings(seed_value: int, k: Vector3i, face: String) -> Array:
	if is_core_edge(k, face):
		var result := [{"at": 12.0, "w": 11.0, "h": 3.65}]
		if has_atrium(seed_value, k):
			var toward_middle := posmod(k.z, 4) if face == "west" or face == "east" else posmod(k.x, 4)
			var at := 21.5 if toward_middle == 1 else 2.5
			result.append({"at": at, "w": 5.0, "h": 4.25})
		return result
	if is_superhub_edge(k, face):
		# The second aperture spans the suspended bridge at the inner corner.
		# Opposite faces use the same local x/z coordinate, including negatives.
		var lateral := posmod(k.z, 8) if face == "east" or face == "west" else posmod(k.x, 8)
		return [{"at": 12.0, "w": 12.0, "h": 3.7},
			{"at": 22.0 if lateral == 3 else 2.0, "w": 4.0, "h": 4.25}]
	if is_super_spine_edge(k, face):
		return [{"at": 12.0, "w": 16.0, "h": 3.7}]
	return [{"at": face_offset(seed_value, k, face), "w": 4.0, "h": 3.25}]


# ------------------------- V4: coherent 8x8 superdistrict network ----------
# Two orthogonal, two-chunk-wide spines connect four existing 4x4 macro cells.
# The 2x2 intersection has its own 8m-wide, multi-storey central lightwell.
# Values depend only on seed/coordinates, not on generation order or room edits.
static func super_key(k: Vector3i) -> Vector3i:
	return Vector3i(floori(float(k.x) / 8.0), 0, floori(float(k.z) / 8.0))


static func super_type(seed_value: int, k: Vector3i) -> String:
	var s := super_key(k)
	if s == Vector3i.ZERO:
		return "threshold_nexus"
	var choices := ["vertical_foundry", "deserted_transit_hub", "hanging_city",
		"great_archive", "service_cathedral", "silent_cistern"]
	return choices[stable_roll(seed_value, ["superdistrict-v4", s.x, s.z], choices.size())]


static func is_super_spine(k: Vector3i) -> bool:
	return posmod(k.x, 8) in [3, 4] or posmod(k.z, 8) in [3, 4]


static func is_superhub(k: Vector3i) -> bool:
	return posmod(k.x, 8) in [3, 4] and posmod(k.z, 8) in [3, 4]


static func super_anchor(k: Vector3i) -> Vector3i:
	var s := super_key(k)
	return Vector3i(8 * s.x + 3, 0, 8 * s.z + 3)


static func is_super_terminal(k: Vector3i) -> bool:
	return is_superhub(k) and k == super_anchor(k)


static func is_super_spine_edge(k: Vector3i, face: String) -> bool:
	return is_super_spine(k) and is_super_spine(neighbor_of(k, face))


static func is_superhub_edge(k: Vector3i, face: String) -> bool:
	var other := neighbor_of(k, face)
	return is_superhub(k) and is_superhub(other) and super_key(k) == super_key(other)


static func superhub_hole(k: Vector3i) -> Rect2:
	if not is_superhub(k) or k.y == MIN_FLOOR:
		return Rect2()
	var x := 20.0 if posmod(k.x, 8) == 3 else 0.0
	var z := 20.0 if posmod(k.z, 8) == 3 else 0.0
	return Rect2(x, z, 4.0, 4.0)


static func superhub_bridge(k: Vector3i) -> Rect2:
	var h := superhub_hole(k)
	if h.size == Vector2.ZERO:
		return Rect2()
	return Rect2(h.position.x, h.position.y + 0.8, 4.0, 2.4)


## Both old 4x4 atria and new 8x8 hubs use this shared floor contract.
static func continuity_hole(seed_value: int, k: Vector3i) -> Rect2:
	if is_superhub(k):
		return superhub_hole(k)
	return atrium_hole(seed_value, k)


static func continuity_bridge(seed_value: int, k: Vector3i) -> Rect2:
	if is_superhub(k):
		return superhub_bridge(k)
	return atrium_bridge(seed_value, k)


## One quadrant of a 10x10m well, in the inner corner of each of the four
## central chunks. No floor opening exists at MIN_FLOOR (solid base).
## It is disjoint from the existing staircase slots at x=5.4-9.6 / 14.4-18.6,
## z=5.4-18.6 and from guaranteed side portals at coordinates 8..16.
static func atrium_hole(seed_value: int, k: Vector3i) -> Rect2:
	if not has_atrium(seed_value, k) or k.y == MIN_FLOOR:
		return Rect2()
	var x := 19.0 if posmod(k.x, 4) == 1 else 0.0
	var z := 19.0 if posmod(k.z, 4) == 1 else 0.0
	return Rect2(x, z, 5.0, 5.0)


## Each north/south half of the atrium has a continuous east-west bridge.
## Its sections are identical along the x seam and never cross a stair slot.
static func atrium_bridge(seed_value: int, k: Vector3i) -> Rect2:
	var hole := atrium_hole(seed_value, k)
	if hole.size == Vector2.ZERO:
		return Rect2()
	var z := 20.0 if posmod(k.z, 4) == 1 else 1.0
	return Rect2(hole.position.x, z, 5.0, 3.0)


static func macro_anchor(k: Vector3i) -> Vector3i:
	var m := macro_key(k)
	return Vector3i(4 * m.x + 1, 0, 4 * m.z + 1)


static func is_power_anchor(seed_value: int, k: Vector3i) -> bool:
	return has_atrium(seed_value, k) and k == macro_anchor(k)
