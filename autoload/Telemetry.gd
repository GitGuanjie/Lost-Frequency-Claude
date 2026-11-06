extends Node
## Optional local performance sampling for QA (never uploads anything).
## Collects frame times while `sampling` is true; QA scripts read summary().

var sampling := false
var _frames: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func start() -> void:
	_frames.clear()
	sampling = true


func stop() -> Dictionary:
	sampling = false
	return summary()


func _process(delta: float) -> void:
	if sampling:
		_frames.append(delta * 1000.0)


func summary() -> Dictionary:
	if _frames.is_empty():
		return {"frames": 0}
	var arr := Array(_frames)
	arr.sort()
	var n := arr.size()
	var total := 0.0
	for v in arr:
		total += v
	var p99: float = arr[mini(n - 1, int(n * 0.99))]
	return {"frames": n, "mean_ms": total / n, "median_ms": arr[n / 2], "p99_ms": p99,
		"worst_ms": arr[n - 1], "fps_mean": 1000.0 / (total / n), "fps_1pct_low": 1000.0 / p99,
		"static_mem_mb": OS.get_static_memory_usage() / 1048576.0}
