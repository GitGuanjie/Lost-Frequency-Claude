class_name RegionalPlan
extends RefCounted
## Deterministic, multiscale structural plan for the continuity lab.
##
##   World          identified by world_id (seed + GENERATOR_VERSION)
##   District       16 x 16 chunks (384 m square)  - owns the zone identity
##   Superdistrict   8 x 8 chunks (192 m square)  - owns the megastructure
##   Megastructure   a rectangle of chunks inside one superdistrict
##   Macro cell      4 x 4 chunks  (96 m square)  - owns the hall type
##   Chunk           24 m square                  - owns the room motif
##
## Each layer owns a geometric constraint, and every value below is a pure
## function of (seed, coordinates). Load order, player movement and the
## mutable per-room version are never consulted: a chunk rebuilt months later
## is identical, and a region looks the same from every side.
##
## This replaces the old behaviour where each 24 m chunk picked its own
## architecture in isolation. A chunk no longer chooses; its superdistrict
## chooses for it.

const GENERATOR_VERSION := 5

const DISTRICT_SPAN := 16     # chunks per district edge
const SUPER_SPAN := 8         # chunks per superdistrict edge
const MACRO_SPAN := 4         # chunks per macro cell edge

const KIND_ARCADE := "arcade"
const KIND_MACHINE_HALL := "machine_hall"
const KIND_SHAFT_STACK := "shaft_stack"
const KIND_ARCHIVE_BLOCK := "archive_block"

const FAMILY_LEVEL0 := "level0"
const FAMILY_WAREHOUSE := "warehouse"
const FAMILY_CIVIC := "civic"

const DISTRICT_STYLES := ["civic_atrium", "service_belt", "monumental_arcade",
	"industrial_park", "quiet_residences", "flooded_basement"]


# ------------------------------------------------------------------ layers

static func district_key(k: Vector3i) -> Vector3i:
	return Vector3i(floori(float(k.x) / float(DISTRICT_SPAN)), 0,
		floori(float(k.z) / float(DISTRICT_SPAN)))


static func super_key(k: Vector3i) -> Vector3i:
	return Vector3i(floori(float(k.x) / float(SUPER_SPAN)), 0,
		floori(float(k.z) / float(SUPER_SPAN)))


static func macro_key(k: Vector3i) -> Vector3i:
	return Vector3i(floori(float(k.x) / float(MACRO_SPAN)), 0,
		floori(float(k.z) / float(MACRO_SPAN)))


## The 16x16 district that owns a chunk. Its style is the broadest identity
## in the world and is shared by four superdistricts.
static func district_plan(seed_value: int, k: Vector3i) -> Dictionary:
	var d := district_key(k)
	var style: String = DISTRICT_STYLES[ContinuityTopology.stable_roll(
		seed_value, ["district-v5", d.x, d.z], DISTRICT_STYLES.size())]
	return {
		"district": d,
		"style": style,
		"zone_id": ContinuityTopology.zone_id(seed_value, k),
		"family": zone_material_family(ContinuityTopology.zone_id(seed_value, k)),
	}


## The 8x8 superdistrict plan. This is where a megastructure is declared,
## so every chunk inside it agrees on one architecture instead of rolling its
## own. The plan is a pure function of the superdistrict coordinates.
static func super_plan(seed_value: int, s: Vector3i) -> Dictionary:
	var roll := ContinuityTopology.stable_roll(seed_value, ["super-plan-v5", s.x, s.z], 6)
	var footprints: Array = []
	match roll:
		0:
			footprints.append(Rect2i(0, 0, 8, 4))
		1:
			footprints.append(Rect2i(0, 4, 8, 4))
		2:
			footprints.append(Rect2i(0, 0, 4, 8))
		3:
			footprints.append(Rect2i(4, 0, 4, 8))
		4:
			footprints.append(Rect2i(4, 4, 4, 4))
		_:
			footprints.append(Rect2i(4, 4, 4, 4))
			footprints.append(Rect2i(0, 0, 8, 4))
	var kinds := [KIND_ARCADE, KIND_MACHINE_HALL, KIND_SHAFT_STACK, KIND_ARCHIVE_BLOCK]
	var structures: Array = []
	for i in footprints.size():
		var kind: String = kinds[ContinuityTopology.stable_roll(
			seed_value, ["super-kind-v5", s.x, s.z, i], kinds.size())]
		structures.append({
			"id": "S%d_%d_M%d" % [s.x, s.z, i],
			"kind": kind,
			"footprint": footprints[i],
			"axis": "x" if footprints[i].size.x >= footprints[i].size.y else "z",
			"anchor": _structure_anchor(footprints[i], s),
		})
	return {
		"super": s,
		"style": ContinuityTopology.super_type(seed_value,
			Vector3i(s.x * SUPER_SPAN, 0, s.z * SUPER_SPAN)),
		"structures": structures,
		"zone_id": ContinuityTopology.zone_id_for_super(s),
	}


## The chunk-level view of the plan. Every architectural decision in the
## generator comes from here, so a chunk never invents its own identity.
static func chunk_plan(seed_value: int, k: Vector3i) -> Dictionary:
	var s := super_key(k)
	var plan := super_plan(seed_value, s)
	var structure := _structure_at(plan["structures"], k)
	var role := "field"
	if ContinuityTopology.is_macro_core(k):
		role = "core"
	elif ContinuityTopology.is_superhub(k):
		role = "hub"
	elif ContinuityTopology.is_super_spine(k):
		role = "spine"
	elif not structure.is_empty():
		role = "structure"
	var zone := ContinuityTopology.zone_id(seed_value, k)
	return {
		"district": district_plan(seed_value, k),
		"zone_id": zone,
		"family": zone_material_family(zone),
		"super": s,
		"super_style": plan["style"],
		"role": role,
		"structure_id": structure.get("id", ""),
		"structure_kind": structure.get("kind", ""),
		"structure_axis": structure.get("axis", "x"),
		"structure_anchor": structure.get("anchor", Vector3i.ZERO),
		"macro_type": ContinuityTopology.macro_structure(seed_value, k),
		"room_type": ContinuityTopology.room_type(seed_value, k),
		"theme": ContinuityTopology.macro_theme(seed_value, k),
		"landmark": ContinuityTopology.has_landmark(seed_value, k),
	}


## The megastructure that owns a chunk, or an empty dictionary.
static func structure_of(seed_value: int, k: Vector3i) -> Dictionary:
	return _structure_at(super_plan(seed_value, super_key(k))["structures"], k)


# --------------------------------------------------------------- helpers

static func _structure_at(structures: Array, k: Vector3i) -> Dictionary:
	var s := super_key(k)
	var local := Vector2i(k.x - s.x * SUPER_SPAN, k.z - s.z * SUPER_SPAN)
	for entry in structures:
		var rect: Rect2i = entry["footprint"]
		if rect.has_point(local):
			return entry
	return {}


static func _structure_anchor(rect: Rect2i, s: Vector3i) -> Vector3i:
	# The anchor is the corner of the footprint nearest the superdistrict
	# origin, so it stays stable and reachable from the shared corridors.
	# It is returned in WORLD chunk coordinates.
	return Vector3i(s.x * SUPER_SPAN + rect.position.x, 0,
		s.z * SUPER_SPAN + rect.position.y)


## The base material family of a zone. The canonical Level 0 look (mono
## yellow wallpaper, damp carpet, buzzing ceiling) is preserved for the
## yellow zone; the warehouse zone is bare concrete. A megastructure changes
## the GEOMETRY of a region, never the identity of the canonical level it
## belongs to.
static func zone_material_family(zone: String) -> String:
	if zone == ContinuityTopology.ZONE_YELLOW:
		return FAMILY_LEVEL0
	if zone == ContinuityTopology.ZONE_PROXY:
		return FAMILY_WAREHOUSE
	return FAMILY_CIVIC


## Floor / wall / ceiling materials for a zone family.
static func family_materials(family: String) -> Dictionary:
	match family:
		FAMILY_LEVEL0:
			return {"floor": "l0_carpet", "wall": "l0_wallpaper", "ceiling": "l0_ceiling"}
		FAMILY_WAREHOUSE:
			return {"floor": "concrete_dark", "wall": "concrete", "ceiling": "metal"}
		_:
			return {"floor": "concrete", "wall": "l0_wallpaper_pale", "ceiling": "l0_ceiling"}


## The accent material a megastructure uses for its structure and trim.
static func structure_accent(kind: String, family: String) -> String:
	match kind:
		KIND_ARCADE:
			return "wood_floor" if family == FAMILY_LEVEL0 else "concrete"
		KIND_MACHINE_HALL:
			return "metal"
		KIND_SHAFT_STACK:
			return "metal"
		KIND_ARCHIVE_BLOCK:
			return "wood_floor" if family != FAMILY_WAREHOUSE else "metal"
	return "metal"
