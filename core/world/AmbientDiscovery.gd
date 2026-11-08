extends Node
## DEV18 small proximity events with source-tagged atmospheric cues.
## This system has NO exits, loot, entity spawning, navigation changes or
## teleports. One cue fires at a time, with a cooldown, only for a real player.
## It is deliberately inert during QA so arrival/route tests stay deterministic.

var level: LevelBase
var cues: Array = []
var heard: Dictionary = {}
var cooldown := 0.0
var polling := 0.4


func setup(parent_level: LevelBase, records: Array) -> void:
	level = parent_level
	cues = records
	set_process(not cues.is_empty())


func _process(delta: float) -> void:
	if level == null or not is_instance_valid(level) or level.player == null or SessionState.is_qa():
		return
	cooldown = maxf(0.0, cooldown - delta)
	polling -= delta
	if polling > 0.0 or cooldown > 0.0:
		return
	polling = 0.25
	var p := level.player.global_position
	var nearest: Dictionary = {}
	var nearest_d := 1.0e8
	for item in cues:
		var key: String = str(item["id"])
		if heard.has(key):
			continue
		var raw: Array = item["pos"]
		var at := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
		var radius := float(item.get("radius", 5.0))
		# Never trigger through a floor or from another altitude in multi-storey
		# structures: vertical gating is separate from the radial distance.
		if absf(p.y - at.y) > float(item.get("height", 2.75)):
			continue
		var d := p.distance_to(at)
		if d <= radius and d < nearest_d:
			nearest = item
			nearest_d = d
	if nearest.is_empty():
		return
	heard[str(nearest["id"])] = true
	SaveService.record_discovery(level.stable_id, "ambient:" + str(nearest["id"]),
		str(nearest["caption"]), str(nearest.get("source", "ADAPTATION")))
	cooldown = 12.0
	Overlay.subtitle(str(nearest["caption"]), 4.0)
	var recipe := str(nearest.get("sound", ""))
	if recipe != "":
		var raw: Array = nearest["pos"]
		level.sound.play_at(recipe, {}, Vector3(float(raw[0]), float(raw[1]), float(raw[2])), -19.0)
