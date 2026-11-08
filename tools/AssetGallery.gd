extends Node3D
## Developer-only, paged scene preview. Never added to the story registry.
## Run: godot --path . --editor --import; godot --path . --scene res://tools/AssetGallery.tscn

const ModelDress := preload("res://core/world/ModelDress.gd")
const PAGE_SIZE := 20
var _paths: Array = []
var _page := 0
var _grid: Node3D
var _status: Label

func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/packs/catalog.json"))
	if not (raw is Dictionary):
		push_error("AssetGallery: model catalog is missing or malformed")
		return
	_paths = (raw.get("models", {}) as Dictionary).keys()
	_paths.sort()
	_grid = Node3D.new()
	_grid.name = "CurrentPage"
	add_child(_grid)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 28.0, -18.0)
	sun.light_energy = 2.1
	add_child(sun)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.12, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.75, 0.83)
	env.ambient_light_energy = 0.9
	world.environment = env
	add_child(world)
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 62.0
	camera.position = Vector3(0.0, 22.0, 32.0)
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	var layer := CanvasLayer.new()
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(24, 20)
	_status.add_theme_font_size_override("font_size", 20)
	layer.add_child(_status)
	_show_page()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT or event.keycode == KEY_PAGEUP:
			_page = mini(_page + 1, int((_paths.size() - 1) / PAGE_SIZE))
			_show_page()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_PAGEDOWN:
			_page = maxi(0, _page - 1)
			_show_page()
		elif event.keycode == KEY_HOME:
			_page = 0
			_show_page()

func _show_page() -> void:
	if _grid == null:
		return
	for ch in _grid.get_children():
		_grid.remove_child(ch)
		ch.queue_free()
	var begin: int = _page * PAGE_SIZE
	var last: int = mini(_paths.size(), begin + PAGE_SIZE)
	for i in range(begin, last):
		var path: String = str(_paths[i])
		var pair: PackedStringArray = path.trim_prefix("assets/packs/").trim_suffix(".glb").split("/")
		if pair.size() != 2:
			continue
		var pos: Vector3 = Vector3(float((i - begin) % 5 - 2) * 4.6, 0.0, float(int((i - begin) / 5) - 1) * 4.8)
		var obj: Dictionary = {"pack": pair[0], "model": pair[1], "pos": [pos.x, pos.y, pos.z], "height": 1.9}
		ModelDress._place(self, _grid, obj)
		var lab := Label3D.new()
		lab.text = pair[1]
		lab.font_size = 26
		lab.pixel_size = 0.003
		lab.position = pos + Vector3(0, 2.65, 0)
		_grid.add_child(lab)
	_status.text = "Lost Frequency | 414 GLB ASSET REVIEW  |  Page %d / %d  |  RIGHT / LEFT: next / previous  |  %d–%d of %d" % [_page + 1, int(ceil(float(_paths.size()) / PAGE_SIZE)), begin + 1, last, _paths.size()]
