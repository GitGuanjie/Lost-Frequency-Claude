extends Node
## Compile guard: loads every GDScript in the project with autoloads registered and
## reports scripts that fail to parse/compile. Run:
##   godot --headless --path . res://tests/CompileAll.tscn
## Exit code = number of failing scripts (0 = all compile).

func _ready() -> void:
	var files: Array[String] = []
	_collect("res://", files)
	files.sort()
	var bad: Array[String] = []
	for f in files:
		var s: Script = ResourceLoader.load(f, "Script", ResourceLoader.CACHE_MODE_REUSE) as Script
		if s == null or not s.can_instantiate():
			bad.append(f)
	print("COMPILE_ALL scripts=%d failing=%d" % [files.size(), bad.size()])
	for b in bad:
		print("COMPILE_FAIL ", b)
	get_tree().quit(bad.size())

func _collect(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("."):
			n = d.get_next()
			continue
		var p := dir.path_join(n)
		if d.current_is_dir():
			if n != "addons" and n != "sources":
				_collect(p, out)
		elif n.ends_with(".gd"):
			out.append(p)
		n = d.get_next()
	d.list_dir_end()
