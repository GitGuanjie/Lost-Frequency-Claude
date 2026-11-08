extends Logger
## Counts GDScript runtime errors while armed. QA uses it so that a self-test
## which crashes (e.g. calls into a freed object) fails instead of silently
## returning fewer checks. Thread-safe: _log_error may run on any thread.

var _mutex := Mutex.new()
var armed := false
var script_errors: Array[String] = []

func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type != ERROR_TYPE_SCRIPT:
		return
	_mutex.lock()
	if armed:
		script_errors.append("%s:%d %s %s %s" % [file, line, function, code, rationale])
	_mutex.unlock()

func _log_message(_message: String, _error: bool) -> void:
	pass

func arm() -> void:
	_mutex.lock()
	script_errors.clear()
	armed = true
	_mutex.unlock()

func disarm() -> Array[String]:
	_mutex.lock()
	armed = false
	var out := script_errors.duplicate()
	_mutex.unlock()
	return out
