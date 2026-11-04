class_name Soundscape
extends Node3D
## Level ambience: looping beds, positional emitters and sparse one-shots with
## optional subtitles. Everything is synthesised by AudioSynth.

var _oneshots: Array = []   # {recipe, params, min_s, max_s, radius, caption, t}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func bed(recipe: String, params: Dictionary = {}, volume_db: float = -10.0, bus: String = "Ambience") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = volume_db
	p.bus = bus
	p.autoplay = true
	add_child(p)
	if p.is_inside_tree():
		p.play()
	return p


func emitter(recipe: String, pos: Vector3, params: Dictionary = {}, volume_db: float = -6.0, max_dist: float = 18.0, bus: String = "Ambience") -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = volume_db
	p.max_distance = max_dist
	p.unit_size = 3.0
	p.bus = bus
	p.position = pos
	p.autoplay = true
	add_child(p)
	p.play()
	return p


## Random sparse event around the listener (e.g. a distant drip).
func oneshot(recipe: String, params: Dictionary, min_s: float, max_s: float, radius: float = 12.0, caption: String = "", volume_db: float = -8.0) -> void:
	_oneshots.append({"recipe": recipe, "params": params, "min": min_s, "max": max_s,
		"radius": radius, "caption": caption, "vol": volume_db, "t": _rng.randf_range(min_s, max_s)})


func play_at(recipe: String, params: Dictionary, pos: Vector3, volume_db: float = -4.0, caption: String = "") -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = volume_db
	p.bus = "SFX"
	p.max_distance = 30.0
	add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)
	if caption != "":
		Overlay.subtitle(caption, 2.5)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for o in _oneshots:
		o["t"] -= delta
		if o["t"] <= 0.0:
			o["t"] = _rng.randf_range(o["min"], o["max"])
			var ang := _rng.randf() * TAU
			var r: float = _rng.randf_range(o["radius"] * 0.4, o["radius"])
			var pos := cam.global_position + Vector3(cos(ang) * r, _rng.randf_range(-1.0, 2.0), sin(ang) * r)
			play_at(o["recipe"], o["params"], pos, o["vol"], o["caption"])
