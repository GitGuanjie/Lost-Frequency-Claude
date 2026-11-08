extends Control
## In-game, data-backed directed map. A story expedition only reveals places
## actually visited and routes actually witnessed. Developer mode shows every
## built scene and every declared built-to-built route (not a canon guarantee).
## This is a schematic graph, not physical navigation or a teleport interface.

signal node_selected(sid: String)

const BOX := Vector2(114.0, 44.0)
const STEP_X := 188.0
const STEP_Y := 81.0

var positions: Dictionary = {}
var links: Array = []
var preview_nodes: Array = []
var preview_edges: Array = []
var current_sid := ""
var selected_sid := ""
var developer := false
var zoom := 1.0
var pan := Vector2.ZERO
var _dragging := false
var _drag_start := Vector2.ZERO
var _drag_moved := false


func rebuild(is_developer: bool, current: String, visited: Array, witnessed: Array) -> void:
	developer = is_developer
	current_sid = current
	var allowed := {}
	if developer:
		for sid in LevelRegistry.spawnable_ids():
			allowed[sid] = true
	else:
		for sid in visited:
			if LevelRegistry.has_level(str(sid)):
				allowed[str(sid)] = true
		if LevelRegistry.has_level(current):
			allowed[current] = true
		for w in witnessed:
			var source := str(w.get("from", ""))
			var dest := str(w.get("to", ""))
			if LevelRegistry.has_level(source):
				allowed[source] = true
			if LevelRegistry.has_level(dest):
				allowed[dest] = true
	links.clear()
	var unique := {}
	if developer:
		for sid in allowed.keys():
			for e in TransitionService.exits_of(str(sid)):
				var dest := str(e.get("to", ""))
				if not allowed.has(dest) or dest == str(sid):
					continue
				var eid := str(e.get("id", ""))
				if unique.has(eid):
					continue
				unique[eid] = true
				links.append({"from": str(sid), "to": dest, "basis": str(e.get("basis", "SOURCE"))})
	else:
		for w in witnessed:
			var source := str(w.get("from", ""))
			var dest := str(w.get("to", ""))
			var eid := str(w.get("edge", ""))
			if allowed.has(source) and allowed.has(dest) and not unique.has(eid):
				unique[eid] = true
				links.append({"from": source, "to": dest, "basis": "WITNESSED"})
	_layout(allowed)
	selected_sid = current if allowed.has(current) else (str(positions.keys()[0]) if not positions.is_empty() else "")
	zoom = 1.0
	pan = Vector2.ZERO
	_fit()
	queue_redraw()
	if selected_sid != "":
		preview_route_to(selected_sid)
		node_selected.emit(selected_sid)


func _layout(allowed: Dictionary) -> void:
	positions.clear()
	if allowed.is_empty():
		return
	# Breadth-first layers follow the *direction* of each exit. Islands are shown
	# separately, rather than silently treated as reachable from Level 0.
	var distance := {}
	var root := "L000" if allowed.has("L000") else (current_sid if allowed.has(current_sid) else str(allowed.keys()[0]))
	var queue := [root]
	distance[root] = 0
	while not queue.is_empty():
		var source: String = queue.pop_front()
		for edge in links:
			var dest := str(edge["to"])
			if str(edge["from"]) == source and allowed.has(dest) and not distance.has(dest):
				distance[dest] = int(distance[source]) + 1
				queue.append(dest)
	var layers := {}
	for sid in distance.keys():
		var depth: int = int(distance[sid])
		if not layers.has(depth):
			layers[depth] = []
		layers[depth].append(sid)
	for depth in layers.keys():
		var names: Array = layers[depth]
		names.sort()
		for i in names.size():
			positions[names[i]] = Vector2(float(depth) * STEP_X, (float(i) - float(names.size() - 1) * 0.5) * STEP_Y)
	var islands: Array = []
	for sid in allowed.keys():
		if not distance.has(sid):
			islands.append(sid)
	islands.sort()
	var lowest_y := -90.0
	for point in positions.values():
		var map_pos: Vector2 = point
		lowest_y = maxf(lowest_y, map_pos.y)
	var island_y := lowest_y + STEP_Y * 2.5
	for i in islands.size():
		positions[islands[i]] = Vector2(float(i % 5) * STEP_X, island_y + float(i / 5) * STEP_Y)
	# The separation of islands is deliberate; these positions are not joined
	# through a fictitious level-to-level route.


func _fit() -> void:
	if positions.is_empty() or size.x < 10.0 or size.y < 10.0:
		return
	var mn := Vector2(1.0e7, 1.0e7)
	var mx := Vector2(-1.0e7, -1.0e7)
	for p in positions.values():
		mn = mn.min(p)
		mx = mx.max(p)
	var extent := mx - mn + Vector2(BOX.x + 90.0, BOX.y + 110.0)
	zoom = clampf(minf(size.x / maxf(1.0, extent.x), size.y / maxf(1.0, extent.y)), 0.18, 1.4)
	pan = size * 0.5 - (mn + mx) * (zoom * 0.5)


## Return the shortest *declared directed path* from current_sid to a selected
## level. In developer mode this is only a hypothetical route, NOT proof that
## any physical trigger exists or that the player can actually traverse it.
## Story mode only includes routes recorded in the expedition journal.
func preview_route_to(target: String) -> Array:
	preview_nodes.clear()
	preview_edges.clear()
	if not positions.has(target) or not positions.has(current_sid):
		queue_redraw()
		return []
	var parent := {}
	var queue: Array = [current_sid]
	parent[current_sid] = ""
	while not queue.is_empty():
		var source: String = queue.pop_front()
		if source == target:
			break
		for edge in links:
			var dest: String = str(edge.get("to", ""))
			if str(edge.get("from", "")) == source and positions.has(dest) and not parent.has(dest):
				parent[dest] = source
				queue.append(dest)
	if not parent.has(target):
		queue_redraw()
		return []
	var reversed: Array = []
	var cursor: String = target
	while cursor != "":
		reversed.append(cursor)
		cursor = str(parent.get(cursor, ""))
	reversed.reverse()
	preview_nodes = reversed
	for i in range(preview_nodes.size() - 1):
		preview_edges.append(str(preview_nodes[i]) + ">" + str(preview_nodes[i+1]))
	queue_redraw()
	return reversed.duplicate()


func reset_view() -> void:
	_fit()
	queue_redraw()


func _screen(p: Vector2) -> Vector2:
	return p * zoom + pan


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.03, 0.95))
	if positions.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(20, 35), "No discovered levels yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.82, 0.78))
		return
	var font := ThemeDB.fallback_font
	for edge in links:
		var a: String = edge["from"]
		var b: String = edge["to"]
		if not positions.has(a) or not positions.has(b):
			continue
		var p: Vector2 = _screen(positions[a])
		var q: Vector2 = _screen(positions[b])
		var is_route: bool = preview_edges.has(a + ">" + b)
		var line: Color = Color(0.58, 0.91, 0.90, 1.0) if is_route else (Color(0.25, 0.58, 0.58, 0.76) if edge["basis"] != "ADAPTATION" else Color(0.87, 0.56, 0.24, 0.86))
		if developer:
			# All developer connections are manifest-only, never proof of traversal.
			var dash_count := clampi(int(ceil(p.distance_to(q) / maxf(5.0, 14.0 * zoom))), 1, 120)
			for dash in dash_count:
				if dash % 2 == 0:
					draw_line(p.lerp(q, float(dash) / float(dash_count)), p.lerp(q, float(dash + 1) / float(dash_count)), line, maxf(1.0, 2.0 * zoom), true)
		else:
			draw_line(p, q, line, maxf(1.0, 2.0 * zoom), true)
		var delta := q - p
		if delta.length_squared() > 1.0:
			var dir := delta.normalized()
			var mid := p.lerp(q, 0.66)
			var side := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([mid + dir * 7.0 * zoom, mid - dir * 4.0 * zoom + side * 4.0 * zoom, mid - dir * 4.0 * zoom - side * 4.0 * zoom]), line)
	for sid in positions.keys():
		var p: Vector2 = _screen(positions[sid])
		var h := BOX * zoom * 0.5
		var rect := Rect2(p - h, BOX * zoom)
		var selected: bool = str(sid) == selected_sid
		var route_node: bool = preview_nodes.has(str(sid))
		var active: bool = str(sid) == current_sid
		var pending: bool = developer and not LevelRegistry.is_playable(str(sid))
		var fill := Color(0.19, 0.36, 0.38) if active else (Color(0.14, 0.25, 0.30) if selected else (Color(0.18, 0.14, 0.10) if pending else Color(0.075, 0.11, 0.14)))
		draw_rect(rect, fill, true)
		draw_rect(rect, Color(0.77, 0.90, 0.77) if active else (Color(0.64, 0.91, 0.91) if route_node else (Color(0.40, 0.73, 0.75) if selected else (Color(0.74, 0.53, 0.33) if pending else Color(0.23, 0.38, 0.39)))), false, maxf(1.0, zoom * 2.0))
		if zoom >= 0.32:
			var name := str(sid).trim_prefix("L").replace("_", ".")
			draw_string(font, p + Vector2(-47, 6) * zoom, "Level " + name, HORIZONTAL_ALIGNMENT_LEFT, 104.0 * zoom, maxi(9, int(15.0 * zoom)), Color(0.92, 0.94, 0.91))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var prior: float = zoom
			zoom = clampf(zoom * (1.15 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15), 0.22, 2.8)
			pan = mb.position - (mb.position - pan) * (zoom / prior)
			accept_event()
			queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_start = mb.position
				_drag_moved = false
			else:
				if _dragging and not _drag_moved:
					_pick(mb.position)
				_dragging = false
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		pan += mm.relative
		if mm.position.distance_to(_drag_start) > 5.0:
			_drag_moved = true
		queue_redraw()
		accept_event()


func _pick(cursor: Vector2) -> void:
	for sid in positions.keys():
		var p: Vector2 = _screen(positions[sid])
		if Rect2(p - BOX * zoom * 0.5, BOX * zoom).has_point(cursor):
			selected_sid = str(sid)
			preview_route_to(selected_sid)
			queue_redraw()
			node_selected.emit(selected_sid)
			return
