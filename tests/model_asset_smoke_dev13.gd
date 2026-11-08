extends Node3D
## Execute AFTER native Godot import:
## godot --headless --path . --scene res://tests/ModelAssetSmoke.tscn
const ModelDress := preload("res://core/world/ModelDress.gd")
const CATALOG := "res://assets/packs/catalog.json"
const OUTPUT := "res://reports/qa/v150_dev13/model_assets_smoke.json"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var bad: Array = []
	var ok := 0
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if not (catalog is Dictionary):
		get_tree().quit(2)
		return
	var models: Dictionary = catalog.get("models", {})
	var entries: Array = models.keys()
	entries.sort()
	for path_var in entries:
		var path: String = "res://" + str(path_var)
		if not ResourceLoader.exists(path):
			bad.append({"path": path, "reason": "not imported"})
			continue
		var scene := load(path) as PackedScene
		if scene == null:
			bad.append({"path": path, "reason": "not a PackedScene"})
			continue
		var root := scene.instantiate()
		if not (root is Node3D):
			bad.append({"path": path, "reason": "invalid 3D root"})
			if root != null:
				root.free()
			continue
		root.free()
		ok += 1
	# Exercise all 466 actual placement records, not just raw GLB imports.
	var dressings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/model_dressings.json"))
	var plans: Dictionary = dressings.get("levels", {})
	var placements_expected := 0
	var placements_tested := 0
	for key_var in plans.keys():
		var key: String = str(key_var)
		var recipe: Array = plans[key]
		placements_expected += recipe.size()
		var holder := Node3D.new()
		add_child(holder)
		placements_tested += ModelDress.decorate(holder, key)
		var coords: Dictionary = {}
		for item_var in recipe:
			var item: Dictionary = item_var
			if item.get("scope", "static") == "chunk":
				var pair := Vector2i(int(item.get("cx", 0)), int(item.get("cz", 0)))
				coords[pair] = true
		for pair_var in coords.keys():
			var pair: Vector2i = pair_var
			placements_tested += ModelDress.decorate_chunk(holder, holder, key, pair.x, pair.y)
		holder.free()
	var report: Dictionary = {"version": "1.5.0-dev13", "expected": 414, "tested": entries.size(), "passed": ok, "failed": bad.size(), "placements_expected": placements_expected, "placements_tested": placements_tested, "failures": bad}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	var f := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write fresh asset QA evidence: " + OUTPUT)
		get_tree().quit(3)
		return
	f.store_string(JSON.stringify(report, "\t") + "\n")
	f.close()
	print("MODEL_ASSET_SMOKE: %d / %d assets; %d / %d placements" % [ok, entries.size(), placements_tested, placements_expected])
	get_tree().quit(0 if bad.is_empty() and ok == 414 and placements_expected == 466 and placements_tested == placements_expected else 1)
