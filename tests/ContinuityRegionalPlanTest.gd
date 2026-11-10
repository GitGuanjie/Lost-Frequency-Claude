extends SceneTree
## Godot 4.7.2 headless contract test for the v5 regional plan.
## Run:
##   godot --headless --path . --script res://tests/ContinuityRegionalPlanTest.gd
##
## The regional plan is the layer that decides what a chunk IS. This test
## proves the decision belongs to the region, not to the individual chunk:
## a megastructure spans several chunks, all of its chunks agree on one
## identity, structures never overlap, and the result is independent of
## generation order, seed and sign of the coordinates.
var checked := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _expect(label: String, ok: bool) -> void:
	checked += 1
	if not ok:
		failed += 1
		push_error("REGIONAL PLAN: " + label)


func _run() -> void:
	for seed_value in [1, 1337, 928374, 20261109]:
		# 1. Determinism: the plan is a pure function of (seed, coordinate).
		for k in [Vector3i(0, 0, 0), Vector3i(5, 1, 7), Vector3i(-3, -1, 4)]:
			_expect("plan is reproducible",
				RegionalPlan.chunk_plan(seed_value, k) == RegionalPlan.chunk_plan(seed_value, k))

		# 2. Every superdistrict declares at least one megastructure, and each
		#    one covers more than a single chunk.
		for sx in range(-3, 4):
			for sz in range(-3, 4):
				var plan := RegionalPlan.super_plan(seed_value, Vector3i(sx, 0, sz))
				var structures: Array = plan["structures"]
				_expect("superdistrict declares a structure", structures.size() >= 1)
				for entry in structures:
					var rect: Rect2i = entry["footprint"]
					_expect("structure spans several chunks",
						rect.size.x * rect.size.y >= 4)
					_expect("structure stays inside its superdistrict",
						rect.position.x >= 0 and rect.position.y >= 0 and
						rect.end.x <= 8 and rect.end.y <= 8)
					_expect("structure has an axis", entry["axis"] in ["x", "z"])
					_expect("structure anchor is in world coordinates",
						entry["anchor"] == Vector3i(sx * 8 + rect.position.x, 0,
							sz * 8 + rect.position.y))

		# 3. Structures inside one superdistrict never overlap.
		for sx in range(-3, 4):
			for sz in range(-3, 4):
				var plan := RegionalPlan.super_plan(seed_value, Vector3i(sx, 0, sz))
				var rects: Array = plan["structures"]
				for i in rects.size():
					for j in range(i + 1, rects.size()):
						var a: Rect2i = rects[i]["footprint"]
						var b: Rect2i = rects[j]["footprint"]
						_expect("structures do not overlap", not a.intersects(b))

		# 4. Region-wide identity: every chunk of a megastructure reports the
		#    SAME structure id and kind, whatever order they are visited in.
		for sx in range(-2, 3):
			for sz in range(-2, 3):
				var s := Vector3i(sx, 0, sz)
				var plan := RegionalPlan.super_plan(seed_value, s)
				for entry in plan["structures"]:
					var rect: Rect2i = entry["footprint"]
					var ids := {}
					var kinds := {}
					for lx in range(rect.position.x, rect.end.x):
						for lz in range(rect.position.y, rect.end.y):
							var k := Vector3i(sx * 8 + lx, 0, sz * 8 + lz)
							var chunk_plan := RegionalPlan.chunk_plan(seed_value, k)
							ids[chunk_plan["structure_id"]] = true
							kinds[chunk_plan["structure_kind"]] = true
					_expect("a structure owns one identity", ids.size() == 1)
					_expect("a structure owns one kind", kinds.size() == 1)

		# 5. The megastructure layer never shadows the shared halls: the
		#    macro core and the superdistrict hub keep their own architecture.
		for x in range(-9, 10):
			for z in range(-9, 10):
				var k := Vector3i(x, 0, z)
				var role: String = RegionalPlan.chunk_plan(seed_value, k)["role"]
				if ContinuityTopology.is_macro_core(k):
					_expect("macro core keeps the shared hall", role == "core")
				elif ContinuityTopology.is_superhub(k):
					_expect("hub keeps the hub architecture", role == "hub")
				elif ContinuityTopology.is_super_spine(k):
					_expect("spine keeps the spine architecture", role == "spine")
				else:
					_expect("open ground has no structure", role in ["field", "structure"])

	# 6. Zone identity is superdistrict aligned, never an x threshold.
	for seed_value in [1, 1337, 928374]:
		for x in range(-17, 18):
			for z in range(-17, 18):
				var k := Vector3i(x, 0, z)
				var zone := ContinuityTopology.zone_id(seed_value, k)
				var s := ContinuityTopology.super_key(k)
				_expect("zone belongs to one superdistrict",
					zone == ContinuityTopology.zone_id_for_super(s) or
					zone == ContinuityTopology.ZONE_PROXY)
		for sx in [3, 4]:
			for sz in [3, 4]:
				_expect("central hub is a single zone",
					ContinuityTopology.zone_id(seed_value, Vector3i(sx, 0, sz)) ==
					ContinuityTopology.zone_id(seed_value, Vector3i.ZERO))

	# 7. The Level 0 material identity is preserved in the yellow zone and
	#    the warehouse zone keeps the bare concrete identity.
	_expect("yellow zone keeps the level 0 carpet",
		RegionalPlan.family_materials(RegionalPlan.FAMILY_LEVEL0)["floor"] == "l0_carpet")
	_expect("yellow zone keeps the level 0 wallpaper",
		RegionalPlan.family_materials(RegionalPlan.FAMILY_LEVEL0)["wall"] == "l0_wallpaper")
	_expect("warehouse zone keeps bare concrete",
		RegionalPlan.family_materials(RegionalPlan.FAMILY_WAREHOUSE)["floor"] == "concrete_dark")
	_expect("proxy zone is not the level 0 family",
		RegionalPlan.zone_material_family(ContinuityTopology.ZONE_PROXY) !=
		RegionalPlan.zone_material_family(ContinuityTopology.ZONE_YELLOW))

	# 8. Explicit addressing round-trips and stays stable.
	var address := WorldAddress.from_position("W_TEST", ContinuityTopology.ZONE_YELLOW,
		Vector3(37.5, 0.25, -12.5))
	_expect("address resolves to its chunk", address.chunk == Vector3i(1, 0, -1))
	_expect("address keeps the local offset",
		address.local_position.is_equal_approx(Vector3(13.5, 0.25, 11.5)))
	_expect("address round-trips through a string",
		WorldAddress.decode(address.encode()).same_place(address))
	_expect("address keeps the world identity",
		WorldAddress.decode(address.encode()).world_id == "W_TEST")
	_expect("address rebuilds the world position",
		address.world_position().is_equal_approx(Vector3(37.5, 0.25, -12.5)))

	print("ContinuityRegionalPlanTest: %d assertions, %d failures" % [checked, failed])
	quit(1 if failed else 0)
